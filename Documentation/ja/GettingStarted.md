# KLShareLink はじめに

> <span lang="ja">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

## 1. パッケージを追加する

Xcode の Add Package Dependencies から `https://github.com/KoenLee1023/KLShareLink.git` を追加するか、`Package.swift` に `0.1.0` 以降の依存関係を宣言します。共有された内容を受け取るアプリまたは機能拡張の target に `KLShareLink` プロダクトをリンクしてください。

## 2. プロバイダーのルールを設定する

プロバイダーが少数なら、`[ShareLinkProvider]` を直接作成できます。複数の target でルールを共有する場合は、次の JSON エンベロープをアプリのリソースに保存し、`ShareLinkResolver(configurationData:)` でデコードします。

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

プロバイダーのルールが表すのは提供元の識別情報だけです。画面遷移、UI、分析イベント、解析後の処理は組み込み先アプリが担当します。

## 3. 2種類の共有入力を分けて解析する

```swift
let resolution = resolver.resolve(
    explicitURL: itemURL,
    sharedText: itemText
)
```

明示 URL を共有テキストへ連結しないでください。解析器のフィルターを通過した明示 URL が最優先です。明示 URL がない、または拒否された場合にだけ共有テキストを使います。

## 4. すべての結果パターンを処理する

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

プロバイダー名だけを含む結果は、旧形式の共有マーカーを識別できたものの、目標 URL は作成していないことを示します。プロバイダー名を URL が存在する証拠として扱わないでください。

## 5. 通信前に改めて検証する

KLShareLink は、`localhost`、`.local` で終わる host、`::1`、および API リファレンスに記載した直接指定の IPv4 範囲を拒否します。`::1` 以外のローカルまたはプライベートな IPv6 リテラルはフィルターで拒否されません。ネットワーククライアントは、解決後のアドレスと各リダイレクト先を独立して検証する必要があります。

## 組み込みテストのチェックリスト

- フィルターを通過する明示 URL と無関係なテキスト
- 明示 URL が拒否された後に、テキスト内の候補を選べるケース
- 一般リンクの後にプロバイダーと一致するリンクがあるケース
- 完全一致する host、サブドメイン、偽の接尾辞を持つ host
- URL がなく、旧形式の識別文字列だけが有効なケース
- 文書化された直接指定の IPv4 範囲、`::1`、`.local`、HTTP(S) 以外の scheme
- `::1` 以外のローカルまたはプライベートな IPv6 リテラル
- 空の入力と空白文字だけの入力

パッケージテストは汎用的な解析契約を対象とします。組み込み先アプリでは、独自のプロバイダー設定、画面遷移、アダプターもテストしてください。
