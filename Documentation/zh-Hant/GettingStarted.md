# KLShareLink 快速開始

> <span lang="zh-TW">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

## 1. 加入套件

透過 Xcode 的 Add Package Dependencies 加入 `https://github.com/KoenLee1023/KLShareLink.git`，也可以在 `Package.swift` 中宣告從 `0.1.0` 開始的相依項目。請把 `KLShareLink` 產品連結至接收分享內容的應用程式或擴充功能 target。

## 2. 設定提供者策略

提供者數量較少時，可以直接建立 `[ShareLinkProvider]`。如果多個 target 共用規則，可以把以下 JSON 外層結構放入應用程式資源，再透過 `ShareLinkResolver(configurationData:)` 解碼。

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

提供者規則只描述來源身分。導覽、介面、分析事件與解析後的操作仍由整合端應用程式負責。

## 3. 分別解析兩個分享輸入

```swift
let resolution = resolver.resolve(
    explicitURL: itemURL,
    sharedText: itemText
)
```

不要把明確 URL 串接至分享文字。通過解析器過濾的明確 URL 具有最高優先順序。只有明確 URL 缺少或被拒絕時，解析器才會使用分享文字。

## 4. 處理所有結果組合

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

只有提供者名稱的結果表示解析器辨識出舊版分享標記，但沒有虛構目標 URL。呼叫端不應把提供者名稱視為 URL 存在的證明。

## 5. 發出網路請求前再次驗證

KLShareLink 會拒絕 `localhost`、以 `.local` 結尾的 host、`::1`，以及 API 參考中列出的直接 IPv4 範圍。除 `::1` 外，其他本機或私有 IPv6 直接位址不會被過濾器拒絕。網路客戶端必須獨立驗證解析後的位址與每次重新導向目標。

## 整合測試檢查清單

- 通過過濾的明確 URL 與無關文字同時存在
- 明確 URL 被拒絕後，文字中仍有可接受候選
- 一般連結之後出現符合提供者的連結
- 精確 host、子網域與偽後綴 host
- 沒有 URL，但舊版標記有效
- 文件列出的直接 IPv4 範圍、`::1`、`.local` 與非 HTTP(S) scheme
- 除 `::1` 外的本機或私有 IPv6 直接位址
- 空白文字與只含空白字元的文字

套件測試涵蓋通用解析契約。整合端應用程式還應測試自己的提供者設定、導覽與轉接層。
