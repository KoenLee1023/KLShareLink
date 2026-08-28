# ``KLShareLink``

Select HTTP(S) link candidates from explicit URLs and shared text through
an explicit policy. KLShareLink does not normalize URLs, perform network I/O, or
make DNS and redirect validation decisions.

## What this package does

`ShareLinkResolver` turns untrusted share text into one deterministic
`ShareLinkResolution`. It first checks the explicit URL supplied by the host,
then scans the text in source order, and finally applies provider attribution
rules. A result can contain a URL, a provider name, both values, or neither.

This is useful at the boundary between a share extension and an app when the
same payload may contain a direct link, a copied paragraph, and a legacy source
marker. The resolver keeps selection policy separate from the later decision to
open, preview, or store the URL.

## Resolution rules

1. An explicit URL is accepted only when its scheme and host pass the resolver
   filters.
2. Text URLs are considered in their appearance order.
3. A URL whose host matches a configured ``ShareLinkProvider`` is preferred to
   an otherwise valid URL.
4. Legacy token patterns are inspected only when no URL was selected. They may
   provide a provider name, but never manufacture a URL.

The package rejects local host names and documented private IPv4 literals. It
does not perform DNS resolution, redirect validation, tracking-parameter
removal, or network requests. The networking layer must validate the resolved
address and every redirect before use.

## Choosing the API

Use ``ShareLinkResolver/resolve(explicitURL:sharedText:)`` when the host has a
separate URL field and copied text. Use
``ShareLinkResolver/resolveLinkInput(_:)`` when both arrive as one string. Use
``ShareLinkResolution`` as a data-transfer value; it is not a proof that the
URL is safe to fetch.

## Topics

### Essentials

- <doc:GettingStarted>
- ``ShareLinkResolver``

### Results and Provider Rules

- ``ShareLinkResolution``
- ``ShareLinkProvider``
