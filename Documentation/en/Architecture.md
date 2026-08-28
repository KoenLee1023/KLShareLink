# KLShareLink Architecture

KLShareLink is a synchronous value-layer package between untrusted share input and host-owned navigation or networking.

## Pipeline

`ShareLinkResolver` owns an immutable provider catalog. Resolution validates an explicit URL, uses Foundation to detect text candidates, passes each candidate through a scheme-and-host gate, then performs provider matching. If no URL survives, legacy patterns may identify a source but cannot create a destination.

The pipeline returns data rather than side effects. It never opens a URL, performs a request, mutates global state, or reaches into an application environment.

## Why policy is data

Provider domains and legacy markers change independently from parsing mechanics. `ShareLinkProvider` makes them serializable and testable. The package owns only stable generic rules: precedence, host-boundary matching, and conservative literal-address rejection.

## Trust boundary

The resolver rejects non-HTTP(S) URLs, empty hosts, `localhost`, `.local`, `::1`, and the documented literal IPv4 ranges. It permits other local or private IPv6 literals. It does not resolve DNS, inspect redirects, evaluate certificates, or assert that a host is trustworthy. Treat output as syntactically filtered input, not network authorization.

## Determinism

For identical Foundation behavior, provider order, and input, output is stable. The first matching candidate wins. No clock, locale service, network state, or shared cache participates.

## Deliberate exclusions

- source-app SDKs
- redirect and canonical URL expansion
- tracking cleanup
- product navigation
- persistence, analytics, and localized error UI
