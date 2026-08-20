import SwiftUI

struct ShoppingView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showingNewOrderDialog = false

    var body: some View {
        NavigationStack {
            List {
                if store.orders.isEmpty {
                    Text("Create an order for this week's shopping. Each week gets its own list, and you can copy last week's order to start.")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.orders) { order in
                    NavigationLink(value: order.id) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.name)
                            Text(orderSubtitle(order))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    let ids = offsets.map { store.orders[$0].id }
                    store.deleteOrders(ids: ids)
                }
            }
            .navigationTitle("Shopping Orders")
            .navigationDestination(for: UUID.self) { orderID in
                OrderDetailView(orderID: orderID)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewOrderDialog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog("New Order", isPresented: $showingNewOrderDialog, titleVisibility: .visible) {
                Button("Start Empty") {
                    store.addOrder(name: defaultOrderName())
                }
                if let latest = store.orders.first {
                    Button("Copy \"\(latest.name)\"") {
                        store.addOrder(name: defaultOrderName(), copyFrom: latest.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Copying last week's order re-checks your pantry: anything you still have enough of is automatically marked as skip.")
            }
        }
    }

    private func orderSubtitle(_ order: ShoppingOrder) -> String {
        let toBuy = order.itemsToBuy.count
        let skipped = order.itemsSkipped.count
        let bought = order.itemsPurchased.count
        var parts = ["\(toBuy) to buy"]
        if skipped > 0 { parts.append("\(skipped) skipped") }
        if bought > 0 { parts.append("\(bought) purchased") }
        return parts.joined(separator: " · ")
    }

    private func defaultOrderName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let cal = Calendar.current
        let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return "Week of \(formatter.string(from: weekStart))"
    }
}

// MARK: - One week's order

struct OrderDetailView: View {
    @EnvironmentObject private var store: DataStore
    let orderID: UUID

    @State private var newItemName = ""
    @State private var newItemQuantity = ""
    @State private var showingRename = false
    @State private var renameText = ""

    private var order: ShoppingOrder? {
        store.order(id: orderID)
    }

    var body: some View {
        List {
            if let order {
                Section("Add item") {
                    HStack {
                        TextField("Item (e.g. Chicken breast)", text: $newItemName)
                        TextField("Qty", text: $newItemQuantity)
                            .frame(width: 70)
                        Button {
                            addItem()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if !newItemName.isEmpty && store.pantryHasEnough(named: newItemName.trimmingCharacters(in: .whitespaces)) {
                        Label("Your pantry says you still have enough of this — it will be added as skipped.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if !order.itemsToBuy.isEmpty {
                    Section("To buy") {
                        ForEach(order.itemsToBuy) { item in
                            itemRow(item)
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { order.itemsToBuy[$0].id }
                            store.removeShoppingItems(orderID: orderID, ids: ids)
                        }
                    }
                }

                if !order.itemsSkipped.isEmpty {
                    Section("Still have enough — skip") {
                        ForEach(order.itemsSkipped) { item in
                            itemRow(item)
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { order.itemsSkipped[$0].id }
                            store.removeShoppingItems(orderID: orderID, ids: ids)
                        }
                    }
                }

                if !order.itemsPurchased.isEmpty {
                    Section("Purchased") {
                        ForEach(order.itemsPurchased) { item in
                            itemRow(item)
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { order.itemsPurchased[$0].id }
                            store.removeShoppingItems(orderID: orderID, ids: ids)
                        }
                        Button {
                            store.addPurchasedToPantry(orderID: orderID)
                        } label: {
                            Label("Stock purchased items into Pantry", systemImage: "cabinet")
                        }
                    }
                }

                Section {
                    Button {
                        store.addLowStockToOrder(orderID: orderID)
                    } label: {
                        Label("Add pantry items that are running low", systemImage: "arrow.down.circle")
                    }
                }
            } else {
                Text("This order was deleted.").foregroundStyle(.secondary)
            }
        }
        .navigationTitle(order?.name ?? "Order")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Rename") {
                    renameText = order?.name ?? ""
                    showingRename = true
                }
            }
        }
        .alert("Rename Order", isPresented: $showingRename) {
            TextField("Name", text: $renameText)
            Button("Save") {
                let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    store.renameOrder(id: orderID, to: trimmed)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func itemRow(_ item: ShoppingItem) -> some View {
        HStack {
            Button {
                store.togglePurchased(orderID: orderID, itemID: item.id)
            } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPurchased ? .green : .secondary)
            }
            .buttonStyle(.borderless)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .strikethrough(item.stillHaveEnough)
                    .foregroundStyle(item.stillHaveEnough ? .secondary : .primary)
                if !item.quantity.isEmpty {
                    Text(item.quantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .swipeActions(edge: .leading) {
            Button {
                store.toggleStillHaveEnough(orderID: orderID, itemID: item.id)
            } label: {
                Label(item.stillHaveEnough ? "Need It" : "Have Enough",
                      systemImage: item.stillHaveEnough ? "cart" : "checkmark.seal")
            }
            .tint(item.stillHaveEnough ? .blue : .orange)
        }
    }

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        store.addShoppingItem(orderID: orderID,
                              name: name,
                              quantity: newItemQuantity.trimmingCharacters(in: .whitespaces))
        newItemName = ""
        newItemQuantity = ""
    }
}
