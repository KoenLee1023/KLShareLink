# Getting Started with KLShareLink

## 1. Add the package

Add `https://github.com/KoenLee1023/KLShareLink.git` through Xcode or declare a dependency from `0.1.0`. Link the `KLShareLink` product to the application or extension that receives shared content.

## 2. Place provider policy

For a small catalog, construct `[ShareLinkProvider]` directly. For rules shared across targets, store the JSON envelope in an app resource and decode it with `ShareLinkResolver(configurationData:)`.

Provider rules describe identity, not product behavior. Keep navigation, UI, analytics, and post-resolution actions in the host.

## 3. Resolve both share channels

```swift
let resolution = resolver.resolve(
    explicitURL: itemURL,
    sharedText: itemText
)
```

Do not concatenate an explicit URL into text. The API gives an explicit URL that passes the resolver filter deliberate precedence and uses text as fallback.

## 4. Handle every result shape

```swift
switch (resolution.url, resolution.providerName) {
case let (url?, provider?): open(url, sourceLabel: provider)
case let (url?, nil): open(url, sourceLabel: nil)
case let (nil, provider?): showUnsupportedLegacyShare(from: provider)
case (nil, nil): showNoLinkFound()
}
```

The legacy-provider case lets an interface explain what was recognized without inventing a destination.

## 5. Validate before networking

KLShareLink rejects selected host forms: `localhost`, `.local`, `::1`, and the documented literal IPv4 ranges. It permits other local or private IPv6 literals. A network client must independently validate resolved addresses and every redirect destination.

## Integration test checklist

- accepted explicit URL plus unrelated text
- rejected explicit URL plus accepted text fallback
- several links with a provider link after a generic link
- exact provider host, subdomain, and look-alike suffix
- no URL with a valid legacy token
- the exact blocked IPv4 ranges, `::1`, `.local`, and non-HTTP schemes
- local or private IPv6 literals other than `::1`, which the resolver permits
- empty and whitespace-only input

Package tests cover the generic contract; host tests should cover configuration and routing adapters.
