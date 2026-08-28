import Foundation
import Testing

@testable import KLShareLink

struct ShareLinkResolverTests {
    private let providers = [
        ShareLinkProvider(
            displayName: "Configured Store",
            domains: ["shop.example"],
            legacyTokenPatterns: [#"\$[A-Za-z0-9]+\$"#]
        ),
    ]

    @Test
    func `configured provider wins over an unrelated leading URL`() {
        let resolver = ShareLinkResolver(providers: providers)

        let result = resolver.resolve(
            explicitURL: nil,
            sharedText: "Download https://example.com then open https://m.shop.example/item"
        )

        #expect(result.url?.absoluteString == "https://m.shop.example/item")
        #expect(result.providerName == "Configured Store")
    }

    @Test
    func `explicit safe URL remains authoritative`() {
        let resolver = ShareLinkResolver(providers: providers)

        let result = resolver.resolve(
            explicitURL: URL(string: "https://example.com/original"),
            sharedText: "https://shop.example/replacement"
        )

        #expect(result.url?.absoluteString == "https://example.com/original")
        #expect(result.providerName == nil)
    }

    @Test(arguments: [
        "http://localhost/private",
        "https://device.local/private",
        "http://10.0.0.1/private",
        "http://127.0.0.1/private",
        "http://169.254.1.2/private",
        "http://172.16.0.1/private",
        "http://192.168.0.1/private",
        "http://[::1]/private",
        "file:///private/note.txt",
    ])
    func `unsafe destinations are rejected`(_ value: String) {
        let resolver = ShareLinkResolver(providers: providers)

        let result = resolver.resolve(
            explicitURL: URL(string: value),
            sharedText: value
        )

        #expect(result.url == nil)
    }

    @Test
    func `legacy token identifies provider without inventing URL`() {
        let resolver = ShareLinkResolver(providers: providers)

        let result = resolver.resolve(
            explicitURL: nil,
            sharedText: "Copy $AbC123$ into the configured app"
        )

        #expect(result.url == nil)
        #expect(result.providerName == "Configured Store")
    }

    @Test
    func `link input trims adjacent sentence punctuation`() {
        let resolver = ShareLinkResolver(providers: [])

        let url = resolver.resolveLinkInput(
            "Read https://example.com/article?id=42。"
        )

        #expect(url?.absoluteString == "https://example.com/article?id=42")
    }
}
