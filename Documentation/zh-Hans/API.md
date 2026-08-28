# KLShareLink API 参考

> <span lang="zh-CN">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLShareLink 是一个不含第三方运行时依赖的 Swift 包，支持 iOS 17 及以上版本和 macOS 14 及以上版本。所有解析均同步执行。相同输入、提供方顺序与 Foundation 行为会得到相同结果。包本身不发起网络请求。

## `ShareLinkResolution`

```swift
public struct ShareLinkResolution: Equatable, Sendable {
    public let url: URL?
    public let providerName: String?
    public init(url: URL?, providerName: String?)
}
```

该值独立保存 URL 与提供方归属。

- `url`：保存的 URL。由 `ShareLinkResolver` 返回时，它已经通过解析器的 scheme 与 host 过滤。直接构造时可以是任意 URL。
- `providerName`：提供方显示名称。一般 URL 未匹配提供方时为 `nil`。仅命中旧版标记时，可以有提供方名称而没有 URL。

### `init(url:providerName:)`

- 参数 `url`：要原样保存的任意 URL，也可以为 `nil`。
- 参数 `providerName`：要原样保存的任意提供方名称，也可以为 `nil`。
- 行为：不验证 URL scheme 或 host，不运行解析器过滤，也不检查 URL 与提供方名称是否对应。
- 抛出：不抛出错误。

## `ShareLinkProvider`

```swift
public struct ShareLinkProvider: Codable, Equatable, Sendable {
    public let displayName: String
    public let domains: [String]
    public let legacyTokenPatterns: [String]
    public init(
        displayName: String,
        domains: [String],
        legacyTokenPatterns: [String]
    )
}
```

- `displayName`：匹配后原样返回给接入应用的名称。包不负责本地化。
- `domains`：提供方 host 列表。匹配时忽略大小写，并移除 host 与配置值首尾的句点。配置 `example.com` 会匹配 `example.com` 和 `m.example.com`，不会匹配 `notexample.com`。
- `legacyTokenPatterns`：仅在没有 URL 通过过滤时检查的 `NSRegularExpression` 模式。无效模式会在解析时被忽略。

`init(displayName:domains:legacyTokenPatterns:)` 原样保存三个参数，不验证域名或正则表达式，也不抛出错误。合成的 `Codable` 键正是 `displayName`、`domains` 与 `legacyTokenPatterns`。

## `ShareLinkResolver`

```swift
public struct ShareLinkResolver: Sendable
```

解析器保存一个不可变且有顺序的提供方列表。它不修改共享状态。

### `init(providers:)`

```swift
public init(providers: [ShareLinkProvider])
```

- 参数 `providers`：按匹配优先级排列的提供方规则。多个提供方匹配同一 host 或旧版标记时，列表中第一个匹配项优先。
- 行为：原样保存顺序。空列表仍可返回通过解析器过滤的一般 URL。
- 抛出：不抛出错误。

### `init(configurationData:)`

```swift
public init(configurationData: Data) throws
```

- 参数 `configurationData`：顶层结构为 `{ "providers": [...] }` 的 JSON 数据。
- 返回：使用解码后的有序提供方列表创建的解析器。
- 抛出：JSON 格式错误、缺少必填键或字段类型错误时，抛出 `JSONDecoder` 产生的解码错误。正则表达式到解析时才编译，因此无效模式不会让该初始化方法抛错。

### `resolve(explicitURL:sharedText:)`

```swift
public func resolve(
    explicitURL: URL?,
    sharedText: String?
) -> ShareLinkResolution
```

- 参数 `explicitURL`：优先处理的 URL。通过过滤时立即返回，并且 `providerName` 固定为 `nil`。缺失或被拒绝时继续处理 `sharedText`。
- 参数 `sharedText`：用于检测 URL 与旧版标记的可选文本。缺失、空字符串或仅含空白时返回空结果。
- 返回：按以下顺序得到的 `ShareLinkResolution`。
- 抛出：不抛出错误。无效正则表达式会被忽略。

解析顺序：

1. 返回通过过滤的显式 URL，不附带提供方名称。
2. 如果文本缺失或仅含空白，返回 `(nil, nil)`。
3. 使用 `NSDataDetector` 按文本出现顺序检测 URL，并移除未通过过滤的候选。
4. 返回第一个匹配已配置提供方的候选。
5. 如果没有提供方候选，返回第一个其余候选，并将 `providerName` 设为 `nil`。
6. 如果没有 URL，返回第一个命中旧版标记的提供方，并将 `url` 设为 `nil`。
7. 如果仍无匹配，返回 `(nil, nil)`。

过滤只接受 `http` 和 `https`，并要求 host 非空。解析器拒绝精确 host `localhost`、以 `.local` 结尾的 host、IPv6 回环地址 `::1`，以及位于 `0.0.0.0/8`、`10.0.0.0/8`、`127.0.0.0/8`、`169.254.0.0/16`、`172.16.0.0/12` 和 `192.168.0.0/16` 的直接 IPv4 地址。

除 `::1` 外，其他本地或私有 IPv6 直接地址不会被该过滤器拒绝。解析器不解析 DNS，也不检查重定向。通过过滤不代表获得网络访问授权。网络层必须验证解析后的地址和每次重定向的目标。

### `resolveLinkInput(_:)`

```swift
public func resolveLinkInput(_ input: String) -> URL?
```

- 参数 `input`：可能包含一个或多个链接的任意文本。
- 返回：与 `resolve(explicitURL: nil, sharedText: input).url` 相同。没有 URL 通过过滤时返回 `nil`。仅命中旧版提供方标记时也返回 `nil`。
- 抛出：不抛出错误。

## 并发与性能

所有公开类型都符合 `Sendable`。解析器方法在调用方的执行器上同步运行。数据检测与正则匹配也在同一调用中完成。对于异常大的输入，接入应用应避免在对延迟敏感的 UI 执行路径中调用。
