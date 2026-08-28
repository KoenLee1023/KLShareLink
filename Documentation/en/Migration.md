# Migrating to KLShareLink

Treat migration as a behavioral replacement, not a text-parser cleanup.

## 1. Freeze current behavior

Capture representative explicit URLs, shared strings, provider attribution, destinations rejected by the existing parser, and empty inputs as tests before removing the existing parser.

## 2. Move provider knowledge into configuration

Translate domain lists and legacy markers into `ShareLinkProvider`. Preserve ordering when existing behavior has precedence.

## 3. Add a thin adapter

```swift
let packageResult = resolver.resolve(
    explicitURL: payload.url,
    sharedText: payload.text
)

return ExistingResult(
    destination: packageResult.url,
    sourceName: packageResult.providerName
)
```

Keep UI, routing, storage, and analytics unchanged while comparing old and new results.

## 4. Review intentional differences

KLShareLink rejects non-HTTP schemes, `localhost`, `.local`, `::1`, and the documented literal IPv4 ranges. It permits other local or private IPv6 literals. Compare these exact rules with the existing parser and decide whether a separate trusted path should handle intentional differences.

An explicit URL that passes the filter has precedence and no package provider attribution. Preserve any separately trusted source metadata in the host adapter.

## 5. Remove duplicated parsing

Delete the old detector only after package tests and the integrating application's regression tests pass. Keep configuration ownership in one place so rules cannot diverge.
