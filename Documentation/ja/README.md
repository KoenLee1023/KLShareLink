# KLShareLink

> <span lang="ja">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

共有された文章から、解析器のフィルターを通過するリンク候補を選びます。

KLShareLink は、実行時にサードパーティへ依存せず、共有シートから渡される URL や文章を同期的に解析する Swift パッケージです。明示 URL、文章中の複数リンク、プロバイダーごとのドメイン、旧形式の識別文字列を順番に確認し、scheme と host のフィルターを通過した HTTP(S) URL と任意のプロバイダー名を返します。

## 概要

- フィルターを通過した明示 URL を最優先
- 文章中の HTTP(S) URL を出現順に検出
- 設定したサービスのドメインに一致する URL を優先
- `localhost`、`.local`、`::1`、および文書化された直接指定の IPv4 範囲を拒否
- URL が見つからない場合も、旧形式の識別文字列からサービス名だけを返せる

## 要件

- Swift 6.0 以降
- iOS 17 以降
- macOS 14 以降
- 実行時のサードパーティ依存なし
- Foundation

## 導入

Xcode の「Add Package Dependencies」からリポジトリを追加するか、`Package.swift` に次のように記述します。

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

## はじめに

1. アプリ側で `ShareLinkProvider` の一覧を用意するか、JSON から読み込みます。
2. 明示 URL と共有テキストは結合せず、別々の引数で渡します。
3. URL とサービス名の有無に応じた4通りの結果をそれぞれ処理します。
4. 通信を始める直前に、DNS の解決結果とすべてのリダイレクト先を再確認します。

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

## 動作保証

- `ShareLinkResolution`：選んだ URL とサービス名を別々に保持します。
- `ShareLinkProvider`：サービス名、対象ドメイン、旧形式の識別パターンをまとめた Codable の設定値です。
- `ShareLinkResolver`：設定後に変更されないプロバイダー一覧を保持する Sendable な解析器です。同期的に動作し、通信は行いません。
- `resolve(explicitURL:sharedText:)`：明示 URL、プロバイダーに一致する URL、残りのフィルター済み URL、旧形式の識別文字列の順で確認します。
- `resolveLinkInput(_:)`：URL だけが必要な場合に使う簡易 API です。

## 責務の境界

このパッケージはリンクの選択だけを行います。通信、リダイレクト先の展開、トラッキングパラメータの削除、履歴保存は行いません。フィルターが拒否するのは、`localhost`、`.local` で終わる host、`::1`、および `0/8`、`10/8`、`127/8`、`169.254/16`、`172.16/12`、`192.168/16` に含まれる直接指定の IPv4 アドレスです。`::1` 以外のローカルまたはプライベートな IPv6 リテラルは通過します。通信前に、解決後のアドレスと各リダイレクト先をネットワーク層で検証してください。

## ドキュメント

- [はじめに](GettingStarted.md)
- [API リファレンス](API.md)
- [アーキテクチャ](Architecture.md)
- [移行](Migration.md)
- [デモアプリ](../../Examples/Documentation/ja/README.md)
- [セキュリティポリシー](SECURITY.md)
- [行動規範](CODE_OF_CONDUCT.md)
- [変更履歴](CHANGELOG.md)

## ステータス

現在の API は 1.0 未満です。wondays で実際に使用していますが、安定版にするまでは、マイナーアップデートで名前や設定方法を見直すことがあります。

## ライセンス

MIT. [LICENSE](../../LICENSE)
