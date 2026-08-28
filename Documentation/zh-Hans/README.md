# KLShareLink

> <span lang="zh-CN">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

从实际收到的分享文本中选择符合解析器过滤条件的链接候选。

KLShareLink 是一个不含第三方运行时依赖、同步且确定性的 Swift 包。它处理显式 URL、文本中的多个候选链接、提供方域名与旧版来源标记，并返回通过 scheme 与 host 过滤的 HTTP(S) URL 及可选的提供方名称。

## 概览

- 通过过滤的显式 URL 优先
- 按文本出现顺序检测 HTTP(S) 候选
- 优先选择命中配置提供方的候选
- 拒绝 `localhost`、`.local`、`::1` 与文档列出的直接 IPv4 范围
- 无 URL 时可报告旧版提供方，但绝不虚构目标

## 要求

- Swift 6.0 或更高版本
- iOS 17 或更高版本
- macOS 14 或更高版本
- 无第三方运行时依赖
- Foundation

## 安装

通过 Xcode 的 Add Package Dependencies 添加仓库，或在 `Package.swift` 中声明：

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLShareLink.git",
        from: "0.1.0"
    )
]
```

```swift
import KLShareLink
```

## 快速开始

1. 在接入应用层定义有序的 `ShareLinkProvider`，或从 JSON 解码。
2. 把显式 URL 与分享文本分别传入，不要自行拼接。
3. 分别处理 URL+提供方、仅 URL、仅提供方、全空四种结果。
4. 真正联网前再次验证 DNS 结果与每个重定向。

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

```swift
let url = resolver.resolveLinkInput(
    "Notes first, then https://www.example.com/article"
)
```

## 行为保证

- `ShareLinkResolution`：URL 与提供方归属彼此独立的结果值。
- `ShareLinkProvider`：可 Codable 的域名与正则策略。域名匹配包含精确主机和子域，不匹配伪后缀。
- `ShareLinkResolver`：不可变且 Sendable。同步执行，无网络 I/O。
- `resolve(explicitURL:sharedText:)`：按显式 URL、提供方候选、其余过滤候选、旧版标记的顺序解析。
- `resolveLinkInput(_:)`：只关心 URL 时的便捷入口。

## 职责边界

只负责选择输入，不发起请求、不展开重定向、不清理跟踪参数、不持久化历史，也不替网络层完成 SSRF 防护。过滤器只拒绝 `localhost`、以 `.local` 结尾的 host、`::1`，以及 `0/8`、`10/8`、`127/8`、`169.254/16`、`172.16/12`、`192.168/16` 中的直接 IPv4 地址。除 `::1` 外，其他本地或私有 IPv6 直接地址仍会通过。请求层必须验证解析后的地址与每次重定向目标。

## 文档

- [快速开始](GettingStarted.md)
- [API 参考](API.md)
- [架构](Architecture.md)
- [迁移](Migration.md)
- [演示应用](../../Examples/Documentation/zh-Hans/README.md)
- [参与贡献](CONTRIBUTING.md)
- [安全策略](SECURITY.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [变更记录](CHANGELOG.md)

## 状态

该 API 目前处于 1.0 之前。功能已在 wondays 的真实产品场景中使用，但在声明稳定前，小版本仍可能调整命名或策略接口。

## 许可证

MIT. [LICENSE](../../LICENSE)
