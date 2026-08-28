# KLShareLink API 參考

> <span lang="zh-TW">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLShareLink 是不含第三方執行階段相依項目的 Swift 套件，支援 iOS 17 以上版本與 macOS 14 以上版本。所有解析都同步執行。相同輸入、提供者順序與 Foundation 行為會得到相同結果。套件本身不發出網路請求。

## `ShareLinkResolution`

```swift
public struct ShareLinkResolution: Equatable, Sendable {
    public let url: URL?
    public let providerName: String?
    public init(url: URL?, providerName: String?)
}
```

此值分別保存 URL 與提供者歸屬。

- `url`：保存的 URL。由 `ShareLinkResolver` 回傳時，它已通過解析器的 scheme 與 host 過濾。直接建立時可以是任何 URL。
- `providerName`：提供者顯示名稱。一般 URL 未符合提供者時為 `nil`。只符合舊版標記時，可以有提供者名稱而沒有 URL。

### `init(url:providerName:)`

- 參數 `url`：要原樣保存的任何 URL，也可以是 `nil`。
- 參數 `providerName`：要原樣保存的任何提供者名稱，也可以是 `nil`。
- 行為：不驗證 URL scheme 或 host，不執行解析器過濾，也不檢查 URL 與提供者名稱是否相符。
- 擲出：不擲出錯誤。

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

- `displayName`：符合後原樣回傳給整合端應用程式的名稱。套件不負責本地化。
- `domains`：提供者 host 清單。比對時忽略大小寫，並移除 host 與設定值開頭及結尾的句點。設定 `example.com` 會符合 `example.com` 和 `m.example.com`，不會符合 `notexample.com`。
- `legacyTokenPatterns`：只在沒有 URL 通過過濾時檢查的 `NSRegularExpression` 模式。無效模式會在解析時忽略。

`init(displayName:domains:legacyTokenPatterns:)` 原樣保存三個參數，不驗證網域或正規表示式，也不擲出錯誤。合成的 `Codable` 鍵正是 `displayName`、`domains` 與 `legacyTokenPatterns`。

## `ShareLinkResolver`

```swift
public struct ShareLinkResolver: Sendable
```

解析器保存不可變且有順序的提供者清單。它不修改共享狀態。

### `init(providers:)`

```swift
public init(providers: [ShareLinkProvider])
```

- 參數 `providers`：依比對優先順序排列的提供者規則。多個提供者符合相同 host 或舊版標記時，清單中的第一個符合項目優先。
- 行為：原樣保存順序。空清單仍可回傳通過解析器過濾的一般 URL。
- 擲出：不擲出錯誤。

### `init(configurationData:)`

```swift
public init(configurationData: Data) throws
```

- 參數 `configurationData`：頂層結構為 `{ "providers": [...] }` 的 JSON 資料。
- 回傳：使用解碼後的有序提供者清單建立的解析器。
- 擲出：JSON 格式錯誤、缺少必要鍵或欄位型別錯誤時，擲出 `JSONDecoder` 產生的解碼錯誤。正規表示式會等到解析時才編譯，因此無效模式不會讓此初始化方法擲出錯誤。

### `resolve(explicitURL:sharedText:)`

```swift
public func resolve(
    explicitURL: URL?,
    sharedText: String?
) -> ShareLinkResolution
```

- 參數 `explicitURL`：優先處理的 URL。通過過濾時立即回傳，而且 `providerName` 固定為 `nil`。缺少或被拒絕時繼續處理 `sharedText`。
- 參數 `sharedText`：用於偵測 URL 與舊版標記的可選文字。缺少、空白或只含空白字元時回傳空結果。
- 回傳：依下列順序取得的 `ShareLinkResolution`。
- 擲出：不擲出錯誤。無效正規表示式會被忽略。

解析順序：

1. 回傳通過過濾的明確 URL，不附帶提供者名稱。
2. 如果文字缺少或只含空白，回傳 `(nil, nil)`。
3. 使用 `NSDataDetector` 依文字出現順序偵測 URL，並移除未通過過濾的候選。
4. 回傳第一個符合已設定提供者的候選。
5. 如果沒有提供者候選，回傳第一個其餘候選，並把 `providerName` 設為 `nil`。
6. 如果沒有 URL，回傳第一個符合舊版標記的提供者，並把 `url` 設為 `nil`。
7. 如果仍無符合項目，回傳 `(nil, nil)`。

過濾只接受 `http` 和 `https`，並要求 host 不為空。解析器拒絕精確 host `localhost`、以 `.local` 結尾的 host、IPv6 回環位址 `::1`，以及位於 `0.0.0.0/8`、`10.0.0.0/8`、`127.0.0.0/8`、`169.254.0.0/16`、`172.16.0.0/12` 與 `192.168.0.0/16` 的直接 IPv4 位址。

除 `::1` 外，其他本機或私有 IPv6 直接位址不會被此過濾器拒絕。解析器不解析 DNS，也不檢查重新導向。通過過濾不代表取得網路存取授權。網路層必須驗證解析後的位址與每次重新導向的目標。

### `resolveLinkInput(_:)`

```swift
public func resolveLinkInput(_ input: String) -> URL?
```

- 參數 `input`：可能包含一個或多個連結的任何文字。
- 回傳：與 `resolve(explicitURL: nil, sharedText: input).url` 相同。沒有 URL 通過過濾時回傳 `nil`。只符合舊版提供者標記時也回傳 `nil`。
- 擲出：不擲出錯誤。

## 並行與效能

所有公開型別都符合 `Sendable`。解析器方法在呼叫端的執行器上同步執行。資料偵測與正規表示式比對也在同一次呼叫中完成。處理異常大的輸入時，整合端應用程式應避免在對延遲敏感的 UI 執行路徑中呼叫。
