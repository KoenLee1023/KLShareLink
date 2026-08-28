import Foundation
import KLShareLink
import SwiftUI

@main
struct PolicyPlaygroundApp: App {
    var body: some Scene {
        WindowGroup("Policy Playground") {
            PolicyPlaygroundView()
                .frame(minWidth: 620, minHeight: 460)
        }
    }
}

private struct PolicyPlaygroundView: View {
    private struct Probe: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    private let resolver = ShareLinkResolver(providers: [])
    private let probes = [
        Probe(label: "Public HTTPS", value: "https://example.com/article"),
        Probe(label: "Localhost", value: "http://localhost/private"),
        Probe(label: "Private IPv4", value: "http://192.168.1.1/admin"),
        Probe(label: "Loopback IPv6", value: "http://[::1]/private"),
        Probe(label: "File URL", value: "file:///private/note.txt"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Policy Playground")
                .font(.largeTitle.bold())
            Text("See which destinations survive KLShareLink's safe share boundary.")
                .foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                GridRow {
                    Text("Probe").bold()
                    Text("Destination").bold()
                    Text("Result").bold()
                }
                Divider().gridCellColumns(3)
                ForEach(probes) { probe in
                    let accepted = resolver.resolve(
                        explicitURL: URL(string: probe.value),
                        sharedText: nil
                    ).url != nil
                    GridRow {
                        Text(probe.label)
                        Text(probe.value).font(.caption.monospaced())
                        Label(
                            accepted ? "Accepted" : "Rejected",
                            systemImage: accepted ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundStyle(accepted ? .green : .red)
                    }
                }
            }
            .padding(18)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
            Spacer()
        }
        .padding(28)
    }
}
