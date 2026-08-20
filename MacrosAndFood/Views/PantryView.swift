import SwiftUI

struct PantryView: View {
    @EnvironmentObject private var store: DataStore
    @State private var newItemName = ""
    @State private var newItemQuantity = ""

    private var stocked: [PantryItem] { store.pantry.filter { $0.haveEnough } }
    private var runningLow: [PantryItem] { store.pantry.filter { !$0.haveEnough } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Foods you have at home. Anything marked \"enough\" gets skipped automatically when it shows up on a shopping order.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("Add food you bought", text: $newItemName)
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
                }

                if !runningLow.isEmpty {
                    Section("Running low — need to buy") {
                        ForEach(runningLow) { item in
                            pantryRow(item)
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { runningLow[$0].id }
                            store.deletePantryItems(ids: ids)
                        }
                    }
                }

                if !stocked.isEmpty {
                    Section("Stocked — no need to buy") {
                        ForEach(stocked) { item in
                            pantryRow(item)
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { stocked[$0].id }
                            store.deletePantryItems(ids: ids)
                        }
                    }
                }
            }
            .navigationTitle("Pantry")
        }
    }

    private func pantryRow(_ item: PantryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                if !item.quantity.isEmpty {
                    Text(item.quantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                store.togglePantryHaveEnough(id: item.id)
            } label: {
                if item.haveEnough {
                    Label("Enough", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Low", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
    }

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        store.addPantryItem(PantryItem(name: name,
                                       quantity: newItemQuantity.trimmingCharacters(in: .whitespaces),
                                       haveEnough: true))
        newItemName = ""
        newItemQuantity = ""
    }
}
