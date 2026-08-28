import KLShareLink
import SwiftUI

@main
struct LinkInspectorApp: App {
    var body: some Scene {
        WindowGroup("Link Inspector") {
            LinkInspectorView()
                .frame(minWidth: 560, minHeight: 420)
        }
    }
}

private struct LinkInspectorView: View {
    @State private var sharedText = "Read https://example.com/story then visit https://m.shop.example/item."
    @State private var resolution: ShareLinkResolution?

    private let resolver = ShareLinkResolver(providers: [
        ShareLinkProvider(
            displayName: "Demo Store",
            domains: ["shop.example"],
            legacyTokenPatterns: []
        ),
    ])

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Link Inspector")
                .font(.largeTitle.bold())
            Text("Inspect which safe candidate wins when shared text contains multiple links.")
                .foregroundStyle(.secondary)
            TextEditor(text: $sharedText)
                .font(.body.monospaced())
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            Button("Resolve shared text") {
                resolution = resolver.resolve(
                    explicitURL: nil,
                    sharedText: sharedText
                )
            }
            .buttonStyle(.borderedProminent)
            GroupBox("Resolution") {
                LabeledContent("URL", value: resolution?.url?.absoluteString ?? "None")
                LabeledContent("Provider", value: resolution?.providerName ?? "Unclassified")
            }
        }
        .padding(28)
    }
}
