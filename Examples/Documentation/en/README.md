# KLShareLink Demo Apps

The repository includes two independent SwiftUI applications. Each has its own manifest and local dependency on the package root; neither imports wondays code or assets.

## Link Inspector

Paste realistic share text and inspect the selected URL and provider. It demonstrates provider-aware selection, exact and subdomain matching, generic fallback, and explicit-URL precedence.

```bash
swift run \
  --package-path Examples/LinkInspector \
  --scratch-path /path/to/BuildArtifacts/NuanceryLabs/KLShareLink-LinkInspector \
  LinkInspectorApp
```

## Policy Playground

Compare ordinary destinations with `::1`, the blocked IPv4 ranges, `.local`, unsupported schemes, and look-alike domains. The resolver permits other local or private IPv6 literals. Use the demo when changing provider configuration or embedding the resolver before a networking layer.

```bash
swift run \
  --package-path Examples/PolicyPlayground \
  --scratch-path /path/to/BuildArtifacts/NuanceryLabs/KLShareLink-PolicyPlayground \
  PolicyPlaygroundApp
```

The demos visualize package output only. They make no web requests, so accepting a candidate does not validate downstream DNS or redirect policy.
