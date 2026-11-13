import SwiftUI

struct NodeDetailView: View {
    let nodeID: String
    let accountID: String?
    @EnvironmentObject private var model: LogicModel
    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false
    @State private var updateSucceeded = false
    @State private var showingUpdateAlert = false
    @State private var requestID: UUID?

    private var node: NodeModel? {
        model.nodes.first { $0.id == nodeID }
    }

    var body: some View {
        ScrollView {
            if let node = node {
                VStack(alignment: .leading, spacing: 12) {
                    if node.id != "sys" {
                        Text("NodeID").font(.headline)
                        Text(node.id).foregroundColor(.secondary)
                        Text("Version").font(.headline)
                        Text(node.version).foregroundColor(.secondary)
                    }
                    Text("Endpoint").font(.headline)
                    Text(node.endpoint).foregroundColor(.secondary)
                    if node.id != "sys" {
                        Button(action: updateNode) {
                            if isUpdating {
                                ProgressView().accessibilityLabel(Text("Updating"))
                            } else {
                                Text("Update")
                            }
                        }
                        .disabled(isUpdating)
                        Text("ManageNodesOnPhone")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(node?.name ?? "")
        .alert(isPresented: $showingUpdateAlert) {
            Alert(title: Text(updateSucceeded ? "Update node success" : "Update node failed"),
                  message: updateSucceeded ? nil : Text("UpdateNodeRetryHint"),
                  dismissButton: .default(Text("OK")))
        }
        .onChange(of: model.me?.uid) { _ in dismissIfInvalid() }
        .onChange(of: node == nil) { _ in dismissIfInvalid() }
        .onDisappear { requestID = nil; isUpdating = false }
    }

    private func dismissIfInvalid() {
        if model.me?.uid != accountID || node == nil {
            requestID = nil
            dismiss()
        }
    }

    private func updateNode() {
        guard !isUpdating, node != nil, model.me?.uid == accountID else { return }
        let request = UUID()
        requestID = request
        isUpdating = true
        CHLogic.shared.updateNodeInfo(nodeID) { code in
            DispatchQueue.main.async {
                guard requestID == request, CHLogic.shared.me?.uid == accountID else { return }
                isUpdating = false
                requestID = nil
                model.nodes = LogicModel.loadNodes()
                guard node != nil else { dismiss(); return }
                updateSucceeded = code == .OK
                showingUpdateAlert = true
            }
        }
    }
}
