# Getting Started

Use KLShareLink through its focused public API and keep product orchestration in
the host application.

For a resolution call, KLShareLink returns an accepted explicit URL first. If
that URL is absent or rejected, it prefers the first detected URL that matches a
configured provider, then the first remaining accepted URL. Only when no URL is
selected does it inspect legacy token patterns and return a provider name without
inventing a URL. The host filter rejects selected local-name and literal-address
forms, but it permits local or private IPv6 literals other than `::1`. The
resolver never performs networking; validate resolved addresses and every
redirect in the networking layer.

## Languages

- <doc:GettingStarted-zh-Hans>
- <doc:GettingStarted-zh-Hant>
- <doc:GettingStarted-ja>
- <doc:GettingStarted-ko>

For complete installation, API, architecture, migration, and demo instructions,
see the repository documentation.
