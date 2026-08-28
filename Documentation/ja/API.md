# KLShareLink API リファレンス

> <span lang="ja">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLShareLink は、実行時にサードパーティへ依存しない Swift パッケージです。iOS 17 以降と macOS 14 以降に対応します。解析はすべて同期的に実行され、入力、プロバイダーの順序、Foundation の動作が同じなら同じ結果を返します。パッケージ自身はネットワーク通信を行いません。

## `ShareLinkResolution`

```swift
public struct ShareLinkResolution: Equatable, Sendable {
    public let url: URL?
    public let providerName: String?
    public init(url: URL?, providerName: String?)
}
```

URL とプロバイダー情報をそれぞれ保持する値です。

- `url`：保持している URL です。`ShareLinkResolver` が返す値では scheme と host のフィルターを通過しています。直接初期化した値には任意の URL を保持できます。
- `providerName`：プロバイダーの表示名です。一般 URL がプロバイダーに一致しない場合は `nil` です。旧形式の識別文字列だけが一致した場合は、URL がなくても表示名を保持します。

### `init(url:providerName:)`

- `url`：そのまま保持する任意の URL、または `nil` です。
- `providerName`：そのまま保持する任意のプロバイダー名、または `nil` です。
- 動作：URL の scheme と host を検証せず、解析器のフィルターも実行しません。URL とプロバイダー名の対応関係も確認しません。
- エラー：スローしません。

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

- `displayName`：一致時に組み込み先アプリへそのまま返す名前です。パッケージはローカライズしません。
- `domains`：プロバイダーを識別する host の一覧です。比較時は大文字と小文字を区別せず、host と設定値の先頭および末尾にあるピリオドを除きます。`example.com` は `example.com` と `m.example.com` に一致し、`notexample.com` には一致しません。
- `legacyTokenPatterns`：URL がフィルターを通過しなかった場合にだけ調べる `NSRegularExpression` のパターンです。無効なパターンは解析時に無視されます。

`init(displayName:domains:legacyTokenPatterns:)` は3つの引数をそのまま保持します。ドメインや正規表現を検証せず、スローしません。合成される `Codable` のキーは `displayName`、`domains`、`legacyTokenPatterns` です。

## `ShareLinkResolver`

```swift
public struct ShareLinkResolver: Sendable
```

設定後に変更されない、順序付きのプロバイダー一覧を保持する解析器です。共有状態は変更しません。

### `init(providers:)`

```swift
public init(providers: [ShareLinkProvider])
```

- `providers`：一致の優先順に並べたプロバイダールールです。複数のプロバイダーが同じ host または旧形式の識別文字列に一致する場合は、一覧の先頭に近いものを選びます。
- 動作：指定された順序をそのまま保持します。空の一覧でも、フィルターを通過した一般 URL は返せます。
- エラー：スローしません。

### `init(configurationData:)`

```swift
public init(configurationData: Data) throws
```

- `configurationData`：最上位が `{ "providers": [...] }` である JSON データです。
- 戻り値：デコードした順序付きプロバイダー一覧を保持する解析器です。
- エラー：JSON が不正な場合、必須キーがない場合、フィールドの型が異なる場合に、`JSONDecoder` のデコードエラーをスローします。正規表現は解析時までコンパイルしないため、無効なパターンではこの初期化処理は失敗しません。

### `resolve(explicitURL:sharedText:)`

```swift
public func resolve(
    explicitURL: URL?,
    sharedText: String?
) -> ShareLinkResolution
```

- `explicitURL`：最優先で調べる URL です。フィルターを通過すると、`providerName` を `nil` にして直ちに返します。指定されていない場合や拒否された場合は `sharedText` を処理します。
- `sharedText`：URL と旧形式の識別文字列を検出するための任意のテキストです。未指定、空、または空白だけの場合は空の結果を返します。
- 戻り値：次の優先順で得られた `ShareLinkResolution` です。
- エラー：スローしません。無効な正規表現は無視します。

解析順：

1. フィルターを通過した明示 URL を、プロバイダー名なしで返します。
2. テキストがない、または空白だけなら `(nil, nil)` を返します。
3. `NSDataDetector` でテキストの出現順に URL を検出し、フィルターを通過しない候補を除きます。
4. 設定済みプロバイダーに一致する最初の候補を返します。
5. プロバイダー候補がなければ、残った最初の候補を `providerName == nil` で返します。
6. URL がなければ、旧形式の識別文字列に一致する最初のプロバイダーを `url == nil` で返します。
7. 一致がなければ `(nil, nil)` を返します。

フィルターは `http` と `https` だけを受け入れ、空でない host を要求します。解析器は、host が `localhost` と完全一致する場合、host が `.local` で終わる場合、IPv6 ループバック `::1`、および `0.0.0.0/8`、`10.0.0.0/8`、`127.0.0.0/8`、`169.254.0.0/16`、`172.16.0.0/12`、`192.168.0.0/16` に含まれる直接指定の IPv4 アドレスを拒否します。

`::1` 以外のローカルまたはプライベートな IPv6 リテラルは、このフィルターでは拒否しません。DNS を解決せず、リダイレクトも調べません。フィルターの通過はネットワークアクセスの許可を意味しません。ネットワーク層で、解決後のアドレスと各リダイレクト先を検証してください。

### `resolveLinkInput(_:)`

```swift
public func resolveLinkInput(_ input: String) -> URL?
```

- `input`：1つ以上のリンクを含む可能性がある任意のテキストです。
- 戻り値：`resolve(explicitURL: nil, sharedText: input).url` と同じ値です。URL がフィルターを通過しない場合は `nil` です。旧形式のプロバイダーだけが一致した場合も `nil` です。
- エラー：スローしません。

## 並行実行と性能

すべての公開型は `Sendable` です。解析メソッド、データ検出、正規表現の照合は、呼び出し元の executor 上で同期的に実行されます。非常に大きな入力を扱う場合は、遅延の影響を受けやすい UI の実行経路を避けて呼び出してください。
