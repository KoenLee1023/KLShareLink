# KLShareLink 快速开始

> <span lang="zh-CN">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

## 1. 添加软件包

通过 Xcode 的 Add Package Dependencies 添加 `https://github.com/KoenLee1023/KLShareLink.git`，也可以在 `Package.swift` 中声明从 `0.1.0` 开始的依赖。请把 `KLShareLink` 产品链接到接收分享内容的应用或扩展 target。

## 2. 配置提供方策略

提供方数量较少时，可以直接创建 `[ShareLinkProvider]`。如果多个 target 共用规则，可以把以下 JSON 外层结构放入应用资源，再通过 `ShareLinkResolver(configurationData:)` 解码。

```json
{
  "providers": [
    {
      "displayName": "Example Video",
      "domains": ["video.example"],
      "legacyTokenPatterns": ["(?i)example\\s+video"]
    }
  ]
}
```

提供方规则只描述来源身份。导航、界面、分析事件以及解析后的操作仍由接入应用负责。

## 3. 分别解析两个分享输入

```swift
let resolution = resolver.resolve(
    explicitURL: itemURL,
    sharedText: itemText
)
```

不要把显式 URL 拼接到分享文本中。通过解析器过滤的显式 URL 具有明确的最高优先级。只有显式 URL 缺失或被拒绝时，解析器才会使用分享文本。

## 4. 处理所有结果组合

```swift
switch (resolution.url, resolution.providerName) {
case let (url?, provider?):
    open(url, sourceLabel: provider)
case let (url?, nil):
    open(url, sourceLabel: nil)
case let (nil, provider?):
    showUnsupportedLegacyShare(from: provider)
case (nil, nil):
    showNoLinkFound()
}
```

仅提供方名称的结果表示解析器识别出了旧版分享标记，但没有虚构目标 URL。调用方不应把提供方名称当作 URL 存在的证明。

## 5. 发起网络请求前再次验证

KLShareLink 会拒绝 `localhost`、以 `.local` 结尾的 host、`::1`，以及 API 参考中列出的直接 IPv4 范围。除 `::1` 外，其他本地或私有 IPv6 直接地址不会被过滤器拒绝。网络客户端必须独立验证解析后的地址与每次重定向目标。

## 集成测试清单

- 通过过滤的显式 URL 与无关文本同时存在
- 显式 URL 被拒绝后，文本中仍有可接受候选
- 一般链接之后出现匹配提供方的链接
- 精确 host、子域名与伪后缀 host
- 没有 URL，但旧版标记有效
- 文档列出的直接 IPv4 范围、`::1`、`.local` 与非 HTTP(S) scheme
- 除 `::1` 外的本地或私有 IPv6 直接地址
- 空文本与仅含空白的文本

包测试覆盖通用解析契约。接入应用还应测试自己的提供方配置、导航与适配层。
