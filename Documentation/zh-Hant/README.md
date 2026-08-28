# KLShareLink

> <span lang="zh-TW">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

從實際收到的分享文字選出符合解析器過濾條件的連結候選。

KLShareLink 是不含第三方執行階段相依項目、同步且可預期的 Swift 套件。它處理明確 URL、文字中的多個候選連結、提供者網域與舊版來源標記，回傳通過 scheme 與 host 過濾的 HTTP(S) URL 與可選的提供者名稱。

## 概覽

- 通過過濾的明確 URL 優先
- 依文字出現順序偵測 HTTP(S) 候選
- 優先選擇符合設定提供者的候選
- 拒絕 `localhost`、`.local`、`::1` 與文件列出的直接 IPv4 範圍
- 無 URL 時可回報舊版提供者，但不會虛構目標

## 需求

- Swift 6.0 或更新版本
- iOS 17 或更新版本
- macOS 14 或更新版本
- 不含第三方執行階段相依項目
- Foundation

## 安裝

透過 Xcode 的 Add Package Dependencies 加入儲存庫，或在 `Package.swift` 中宣告：

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

## 快速開始

1. 在整合端應用程式定義有順序的 `ShareLinkProvider`，或從 JSON 解碼。
2. 分別傳入明確 URL 與分享文字，不要自行串接。
3. 分別處理 URL+提供者、僅 URL、僅提供者、全空四種結果。
4. 真正連線前再次驗證 DNS 結果與每個重新導向。

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

## 行為保證

- `ShareLinkResolution`：URL 與提供者歸屬彼此獨立的結果值。
- `ShareLinkProvider`：可 Codable 的網域與正規表示式策略。支援精確主機與子網域，不匹配偽後綴。
- `ShareLinkResolver`：不可變且 Sendable。同步執行，沒有網路 I/O。
- `resolve(explicitURL:sharedText:)`：依明確 URL、提供者候選、其餘過濾候選、舊版標記解析。
- `resolveLinkInput(_:)`：只需要 URL 時的便利入口。

## 職責邊界

只負責選擇輸入，不發出請求、不展開重新導向、不清除追蹤參數、不保存歷史，也不取代網路層的 SSRF 防護。過濾器只拒絕 `localhost`、以 `.local` 結尾的 host、`::1`，以及 `0/8`、`10/8`、`127/8`、`169.254/16`、`172.16/12`、`192.168/16` 中的直接 IPv4 位址。除 `::1` 外，其他本機或私有 IPv6 直接位址仍會通過。請求層必須驗證解析後的位址與每次重新導向目標。

## 文件

- [快速開始](GettingStarted.md)
- [API 參考](API.md)
- [架構](Architecture.md)
- [遷移](Migration.md)
- [示範 App](../../Examples/Documentation/zh-Hant/README.md)
- [參與貢獻](CONTRIBUTING.md)
- [安全政策](SECURITY.md)
- [行為準則](CODE_OF_CONDUCT.md)
- [變更記錄](CHANGELOG.md)

## 狀態

此 API 目前仍在 1.0 之前。功能已用於 wondays 的真實產品情境，但在宣告穩定前，小版本仍可能調整命名或策略介面。

## 授權

MIT. [LICENSE](../../LICENSE)
