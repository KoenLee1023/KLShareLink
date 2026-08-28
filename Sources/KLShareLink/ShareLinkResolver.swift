import Foundation

/// An independently stored URL and provider attribution pair.
///
/// Results produced by ``ShareLinkResolver`` can contain a URL without a provider
/// name when the selected URL does not match a configured provider. Conversely,
/// they can contain a provider name without a URL when only a legacy token
/// identifies the provider. Both values are `nil` when the resolver finds no
/// accepted URL or legacy token.
///
/// This type is also publicly constructible. Its initializer stores both values
/// unchanged and does not apply the resolver's scheme or host filters.
public struct ShareLinkResolution: Equatable, Sendable {
    /// The stored URL, or `nil` when the value has no URL.
    ///
    /// When a resolver creates the value, this URL has passed that resolver's
    /// scheme and host filters. Directly initialized values have no such guarantee.
    public let url: URL?

    /// The stored provider name, or `nil` when the value has no attribution.
    ///
    /// A resolver supplies a configured provider's display name after a match.
    /// Directly initialized values can contain any string.
    public let providerName: String?

    /// Creates a resolution by storing URL and provider values unchanged.
    ///
    /// This initializer performs no validation. In particular, it does not
    /// restrict URL schemes or hosts and does not verify that `providerName`
    /// corresponds to `url`.
    ///
    /// - Parameters:
    ///   - url: Any URL to store, or `nil`.
    ///   - providerName: Any provider name to store, or `nil`.
    public init(url: URL?, providerName: String?) {
        self.url = url
        self.providerName = providerName
    }
}

/// A serializable rule that attributes shared links to one provider.
///
/// Domain matching is case-insensitive and treats each domain as either an exact
/// host or a parent host for subdomains. Legacy token patterns are only evaluated
/// when resolution does not select an accepted URL.
public struct ShareLinkProvider: Codable, Equatable, Sendable {
    /// The host-defined name returned when this provider matches.
    ///
    /// The resolver returns this value unchanged and does not localize it.
    public let displayName: String

    /// Exact or parent host names that identify this provider.
    ///
    /// A configured `example.com` matches `example.com` and
    /// `store.example.com`, but not `notexample.com`.
    public let domains: [String]

    /// Regular-expression patterns that identify legacy shares without a URL.
    ///
    /// Patterns use `NSRegularExpression`. Invalid patterns are ignored when
    /// resolving instead of causing resolution to fail.
    public let legacyTokenPatterns: [String]

    /// Creates a provider attribution rule.
    ///
    /// - Parameters:
    ///   - displayName: The value reported as provider attribution after a match.
    ///   - domains: The exact or parent hosts that identify this provider.
    ///   - legacyTokenPatterns: The regular-expression patterns checked only when
    ///     no accepted URL is selected.
    public init(
        displayName: String,
        domains: [String],
        legacyTokenPatterns: [String]
    ) {
        self.displayName = displayName
        self.domains = domains
        self.legacyTokenPatterns = legacyTokenPatterns
    }
}

/// Selects a link candidate and optional provider attribution from shared input.
///
/// A resolver is an immutable, `Sendable` value. Its methods run synchronously
/// on the caller's executor and perform no network I/O, DNS resolution, redirect
/// handling, or persistent storage.
public struct ShareLinkResolver: Sendable {
    private struct Catalog: Decodable, Sendable {
        let providers: [ShareLinkProvider]
    }

    private static let allowedSchemes = Set(["http", "https"])
    private static let blockedIPv4FirstOctets = Set([0, 10, 127])
    private static let private172Range = 16...31

    private let providers: [ShareLinkProvider]

    /// Creates a resolver with an ordered provider catalog.
    ///
    /// Provider order is preserved. If more than one provider matches the same
    /// candidate URL or legacy token, the first matching provider is selected.
    /// An empty catalog still permits generic accepted URLs.
    ///
    /// - Parameter providers: The ordered provider attribution rules to apply.
    public init(providers: [ShareLinkProvider]) {
        self.providers = providers
    }

    /// Creates a resolver by decoding its provider catalog from JSON data.
    ///
    /// The data must contain a top-level object with a `providers` array. Each
    /// provider uses the synthesized `Codable` keys: `displayName`, `domains`,
    /// and `legacyTokenPatterns`. Regular-expression syntax is evaluated later,
    /// during resolution, so an invalid pattern does not make this initializer
    /// throw.
    ///
    /// - Parameter configurationData: JSON data containing the provider catalog.
    /// - Throws: The decoding error produced by `JSONDecoder` if the data is
    ///   malformed or does not match the required catalog structure.
    public init(configurationData: Data) throws {
        providers = try JSONDecoder().decode(
            Catalog.self,
            from: configurationData
        ).providers
    }

    /// Resolves an explicit URL and optional shared text into one result.
    ///
    /// Resolution first returns an accepted explicit URL without provider
    /// attribution. Otherwise, it scans the text in detector order, chooses the
    /// first accepted URL matching a configured provider, then the first remaining
    /// accepted URL. If no URL is selected, it returns the first provider whose
    /// legacy pattern matches the text. Missing or whitespace-only text produces
    /// an empty resolution.
    ///
    /// Accepted URLs use HTTP or HTTPS and have a nonempty host. The resolver
    /// rejects the exact host `localhost`, hosts ending in `.local`, IPv6 loopback
    /// `::1`, and literal IPv4 addresses in `0.0.0.0/8`, `10.0.0.0/8`,
    /// `127.0.0.0/8`, `169.254.0.0/16`, `172.16.0.0/12`, and `192.168.0.0/16`.
    /// It does not reject other local or private IPv6 literals, resolve hostnames,
    /// or validate DNS results and redirects. Passing this filter is not network
    /// authorization.
    ///
    /// - Parameters:
    ///   - explicitURL: A preferred URL. It is returned only when accepted;
    ///     otherwise, the resolver continues with `sharedText`.
    ///   - sharedText: Optional text whose detected links and legacy tokens are
    ///     considered after an explicit URL is rejected or absent.
    /// - Returns: A selected URL, optional provider attribution, or a legacy-only
    ///   provider attribution as described above. The two returned properties are
    ///   independent.
    public func resolve(
        explicitURL: URL?,
        sharedText: String?
    ) -> ShareLinkResolution {
        if let explicitURL, isAllowed(explicitURL) {
            return ShareLinkResolution(url: explicitURL, providerName: nil)
        }

        guard let sharedText,
              !sharedText.trimmingCharacters(
                  in: .whitespacesAndNewlines
              ).isEmpty else {
            return ShareLinkResolution(url: nil, providerName: nil)
        }

        let candidates = detectedURLs(in: sharedText)
        for candidate in candidates {
            if let provider = provider(for: candidate) {
                return ShareLinkResolution(
                    url: candidate,
                    providerName: provider.displayName
                )
            }
        }

        if let candidate = candidates.first {
            return ShareLinkResolution(url: candidate, providerName: nil)
        }

        if let provider = providers.first(where: {
            matchesLegacyToken(in: sharedText, provider: $0)
        }) {
            return ShareLinkResolution(
                url: nil,
                providerName: provider.displayName
            )
        }

        return ShareLinkResolution(url: nil, providerName: nil)
    }

    /// Resolves a text-only input when provider attribution is not needed.
    ///
    /// This is equivalent to calling
    /// `resolve(explicitURL: nil, sharedText: input).url`. It runs synchronously,
    /// performs no network I/O, and returns `nil` when the text contains no
    /// accepted URL.
    ///
    /// - Parameter input: Text containing one or more potential links.
    /// - Returns: The selected accepted URL, or `nil` when none is selected.
    public func resolveLinkInput(_ input: String) -> URL? {
        resolve(explicitURL: nil, sharedText: input).url
    }

    private func detectedURLs(in text: String) -> [URL] {
        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        ) else {
            return []
        }

        return detector
            .matches(
                in: text,
                range: NSRange(text.startIndex..., in: text)
            )
            .compactMap(\.url)
            .filter(isAllowed)
    }

    private func provider(for url: URL) -> ShareLinkProvider? {
        guard let host = url.host?.lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: ".")) else {
            return nil
        }

        return providers.first { provider in
            provider.domains.contains { domain in
                let normalized = domain.lowercased()
                    .trimmingCharacters(
                        in: CharacterSet(charactersIn: ".")
                    )
                return host == normalized || host.hasSuffix(".\(normalized)")
            }
        }
    }

    private func matchesLegacyToken(
        in text: String,
        provider: ShareLinkProvider
    ) -> Bool {
        let fullRange = NSRange(text.startIndex..., in: text)
        return provider.legacyTokenPatterns.contains { pattern in
            guard let expression = try? NSRegularExpression(pattern: pattern)
            else { return false }
            return expression.firstMatch(in: text, range: fullRange) != nil
        }
    }

    private func isAllowed(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              Self.allowedSchemes.contains(scheme) else {
            return false
        }

        let host = (url.host ?? "").lowercased()
        guard !host.isEmpty,
              host != "localhost",
              !host.hasSuffix(".local"),
              host != "::1" else {
            return false
        }

        let parts = host.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return true }
        if Self.blockedIPv4FirstOctets.contains(parts[0]) { return false }
        if parts[0] == 169 && parts[1] == 254 { return false }
        if parts[0] == 172 && Self.private172Range.contains(parts[1]) {
            return false
        }
        if parts[0] == 192 && parts[1] == 168 { return false }
        return true
    }
}
