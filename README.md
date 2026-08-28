# KLShareLink

> Language: [English](README.md) · [简体中文](Documentation/zh-Hans/README.md) · [繁體中文](Documentation/zh-Hant/README.md) · [日本語](Documentation/ja/README.md) · [한국어](Documentation/ko/README.md)

API Documentation: [DocC](https://labs.wondays.space/documentation/en/klsharelink)

Select a useful link candidate from real-world share text through a documented scheme-and-host filter.

KLShareLink is a small Swift package from Nuancery Labs with no third-party runtime dependencies. It was extracted from production behavior in wondays, where shared text may contain an explicit URL, several unrelated URLs, provider-specific text, or no usable link at all.

The package does one job: select an HTTP(S) URL that passes its syntactic filter and explain which configured provider matched it. It does not fetch the URL, expand redirects, render web content, persist history, or decide what your app should do next.

## Why it exists

Share extensions receive inconsistent inputs. A source app may provide a clean `URL`, bury a link inside localized prose, include tracking and help links together, or expose only a legacy marker. A naive “first URL wins” parser produces unstable results and can pass loopback or private-network destinations into code that expects a public webpage.

KLShareLink makes the decision explicit and deterministic:

1. Accept an explicit URL when it passes the resolver filter.
2. Detect HTTP(S) candidates in text in source order.
3. Prefer the first candidate matching a configured provider.
4. Otherwise return the first remaining filtered candidate.
5. If no URL exists, report a matching legacy provider token without inventing a URL.

## Requirements

- Swift 6.0 or newer
- iOS 17 or newer
- macOS 14 or newer
- Foundation only; no third-party runtime dependencies

## Installation

Add KLShareLink in Xcode through **File → Add Package Dependencies**, or add it to `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLShareLink.git",
        from: "0.1.0"
    )
]
```

Then add `KLShareLink` to the target and import it:

```swift
import KLShareLink
```

## Quick start

```swift
import KLShareLink

let resolver = ShareLinkResolver(providers: [
    ShareLinkProvider(
        displayName: "Example Video",
        domains: ["video.example"],
        legacyTokenPatterns: [#"(?i)example\s+video"#]
    )
])

let result = resolver.resolve(
    explicitURL: nil,
    sharedText: "Watch this: https://video.example/watch/42"
)

print(result.url)          // https://video.example/watch/42
print(result.providerName) // Example Video
```

For a plain text field where only the URL matters:

```swift
let url = resolver.resolveLinkInput(
    "Notes first, then https://www.example.com/article"
)
```

## Configuration from JSON

Provider policy can live outside application code:

```json
{
  "providers": [
    {
      "displayName": "Example Video",
      "domains": ["video.example", "v.example"],
      "legacyTokenPatterns": ["(?i)example\\s+video"]
    }
  ]
}
```

```swift
let resolver = try ShareLinkResolver(configurationData: data)
```

Invalid JSON or a missing `providers` collection throws the underlying `DecodingError`. Invalid regular expressions do not crash resolution; that pattern simply does not match.

## Filtering and network boundary

The resolver accepts only `http` and `https` with a nonempty host. It rejects the exact host `localhost`, hosts ending in `.local`, IPv6 loopback `::1`, and literal IPv4 addresses in `0.0.0.0/8`, `10.0.0.0/8`, `127.0.0.0/8`, `169.254.0.0/16`, `172.16.0.0/12`, and `192.168.0.0/16`. It does not reject other local or private IPv6 literals.

This is a syntactic input-selection boundary, not network authorization or a complete SSRF defense. DNS can change after selection, redirects can point elsewhere, and a hostname can resolve to a private address. Any code that performs requests must validate every resolved address and redirect destination at the network layer.

## Behavioral guarantees

- Resolution is synchronous and performs no network access.
- Candidate order follows `NSDataDetector` source order.
- Provider order matters only when several providers claim the same domain.
- Domain matching includes exact hosts and subdomains, never unrelated suffixes.
- An accepted explicit URL wins before shared-text analysis.
- An explicit URL that fails the filter is ignored; filtered text candidates may still resolve.
- `providerName` may be non-`nil` while `url` is `nil` for a legacy-token match.
- The resolver and value types are `Sendable`.

## Documentation

- [Getting Started](Documentation/en/GettingStarted.md) — integration patterns and configuration
- [API Reference](Documentation/en/API.md) — exact public declarations and semantics
- [Architecture](Documentation/en/Architecture.md) — pipeline, trust boundary, and exclusions
- [Migration](Documentation/en/Migration.md) — replacing an existing parser while preserving behavior
- [Demo Apps](Examples/Documentation/en/README.md) — two independent SwiftUI examples

## Project scope

Included: URL detection, provider attribution, deterministic precedence, configuration decoding, and a conservative local-network filter.

Not included: redirect expansion, canonical-link scraping, tracking-parameter removal, HTTP requests, UI, analytics, persistence, or product-specific routing.

## Status and versioning

The implementation is integrated into wondays and covered by package tests. The API is pre-1.0: minor releases may refine names or policy surface before stability is declared. Pin an exact version if a pre-1.0 integration requires strict source compatibility.

## License

KLShareLink is available under the MIT License. See [LICENSE](LICENSE).
