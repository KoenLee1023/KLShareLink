# KLShareLink API Reference

This reference describes the complete public API in KLShareLink 0.1.0. All resolution is synchronous, deterministic for the same input and provider order, and free of network I/O.

## `ShareLinkResolution`

```swift
public struct ShareLinkResolution: Equatable, Sendable {
    public let url: URL?
    public let providerName: String?
    public init(url: URL?, providerName: String?)
}
```

An independently stored URL and provider attribution pair. Values returned by a
resolver follow the resolver contract below. The public initializer is also
available for direct construction and does not enforce that contract.

| Property | Meaning |
| --- | --- |
| `url` | The stored URL. A resolver supplies a URL that passed its syntactic filter; direct initialization can store any URL. |
| `providerName` | The configured display name whose domain or legacy token matched. It is `nil` for a URL that does not match a configured provider. |

The optionals are independent. A legacy token can produce `(url: nil, providerName: "…")`; callers must not treat a provider name as proof that a URL exists.

### `init(url:providerName:)`

Stores both arguments unchanged. It does not validate the URL scheme or host,
does not apply `ShareLinkResolver` filtering, and does not verify a relationship
between `url` and `providerName`. It never throws.

## `ShareLinkProvider`

```swift
public struct ShareLinkProvider: Codable, Equatable, Sendable {
    public let displayName: String
    public let domains: [String]
    public let legacyTokenPatterns: [String]
    public init(displayName: String, domains: [String], legacyTokenPatterns: [String])
}
```

- `displayName`: Attribution returned to the host. Localization belongs to the caller.
- `domains`: Case-insensitive exact hosts or parent hosts. `example.com` matches `example.com` and `m.example.com`, never `notexample.com`.
- `legacyTokenPatterns`: ICU-compatible regular expressions evaluated only when no URL passes the resolver filter. Invalid patterns are ignored.

The `Codable` keys are exactly `displayName`, `domains`, and `legacyTokenPatterns`.

## `ShareLinkResolver`

```swift
public struct ShareLinkResolver: Sendable
```

An immutable resolver configured with an ordered provider collection.

### `init(providers:)`

```swift
public init(providers: [ShareLinkProvider])
```

Provider order is preserved. If several providers claim the same host, the first provider wins. An empty catalog still resolves generic URLs that pass the resolver filter. The initializer stores rules without validating domains or regular expressions and never throws.

### `init(configurationData:)`

```swift
public init(configurationData: Data) throws
```

Decodes a top-level `{ "providers": [...] }` envelope with `JSONDecoder`. It throws the original decoding error for malformed data, missing required keys, or incorrect field types. Regular-expression syntax is checked lazily during resolution.

### `resolve(explicitURL:sharedText:)`

```swift
public func resolve(
    explicitURL: URL?,
    sharedText: String?
) -> ShareLinkResolution
```

Precedence:

1. Return an explicit URL immediately with `providerName == nil` when it passes the resolver filter.
2. Ignore missing or whitespace-only text.
3. Detect text links with `NSDataDetector` and remove candidates that fail the resolver filter.
4. Return the first candidate matching a configured provider.
5. Otherwise return the first remaining candidate.
6. Without a URL, return the first legacy provider-token match.
7. Otherwise return `(nil, nil)`.

Accepted schemes are `http` and `https`, and the host must be nonempty. The
resolver rejects the exact host `localhost`, hosts ending in `.local`, IPv6
loopback `::1`, and literal IPv4 addresses in `0.0.0.0/8`, `10.0.0.0/8`,
`127.0.0.0/8`, `169.254.0.0/16`, `172.16.0.0/12`, and `192.168.0.0/16`.
It permits other local or private IPv6 literals. It does not resolve hostnames or
inspect redirects, so passing the filter is not network authorization. Network
clients must validate resolved addresses and every redirect destination.

The method never throws. It returns `(nil, nil)` for missing, empty, or
whitespace-only text after an absent or rejected explicit URL, and when no URL or
legacy pattern matches.

### `resolveLinkInput(_:)`

```swift
public func resolveLinkInput(_ input: String) -> URL?
```

Convenience API equivalent to `resolve(explicitURL: nil, sharedText: input).url`.
The parameter is arbitrary text. It returns the selected URL or `nil`, discards
provider-only legacy matches, and never throws.

## Concurrency and performance

All public types are `Sendable`. Methods are synchronous; data detection and regular-expression matching execute on the caller's executor. Move unusually large inputs away from latency-sensitive UI work.

## Complete example

```swift
import KLShareLink

let resolver = ShareLinkResolver(providers: [
    .init(
        displayName: "Articles",
        domains: ["read.example"],
        legacyTokenPatterns: [#"(?i)shared\s+from\s+articles"#]
    )
])

let resolution = resolver.resolve(
    explicitURL: nil,
    sharedText: "Help: https://help.example Story: https://read.example/42"
)

if let url = resolution.url {
    print(url.absoluteString)
    print(resolution.providerName ?? "Unrecognized provider")
}
```
