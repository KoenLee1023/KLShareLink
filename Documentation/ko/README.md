# KLShareLink

> <span lang="ko">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

공유된 글에서 분석기 필터를 통과하는 링크 후보를 선택합니다.

KLShareLink는 서드파티 런타임 의존성 없이 공유 시트에서 전달된 URL과 텍스트를 동기 방식으로 분석하는 Swift 패키지입니다. 명시적 URL, 본문의 여러 링크, 제공자별 도메인, 이전 형식의 식별 문자열을 차례로 확인해 scheme과 host 필터를 통과한 HTTP(S) URL과 선택적 제공자 이름을 반환합니다.

## 개요

- 필터를 통과한 명시적 URL을 가장 먼저 사용
- 본문의 HTTP(S) URL을 등장 순서대로 검색
- 설정한 서비스 도메인과 일치하는 URL을 우선 선택
- `localhost`, `.local`, `::1`, 문서에 명시된 직접 입력 IPv4 범위 거부
- URL이 없어도 이전 형식의 식별 문자열에서 서비스 이름을 확인 가능

## 요구 사항

- Swift 6.0 이상
- iOS 17 이상
- macOS 14 이상
- 서드파티 런타임 의존성 없음
- Foundation

## 설치

Xcode의 Add Package Dependencies에서 저장소를 추가하거나 `Package.swift`에 다음을 선언합니다.

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

## 시작하기

1. 앱에서 `ShareLinkProvider` 목록을 만들거나 JSON에서 읽어 옵니다.
2. 명시 URL과 공유 텍스트를 합치지 말고 별도 인자로 전달합니다.
3. URL과 서비스 이름의 유무에 따라 나오는 네 가지 결과를 각각 처리합니다.
4. 네트워크 요청 직전에 DNS 결과와 모든 리디렉션 목적지를 다시 확인합니다.

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

## 동작 보장

- `ShareLinkResolution`: 선택한 URL과 서비스 이름을 서로 독립적으로 보관합니다.
- `ShareLinkProvider`: 서비스 이름, 대상 도메인, 이전 형식의 식별 패턴을 담는 Codable 설정값입니다.
- `ShareLinkResolver`: 설정 후 변경되지 않는 제공자 목록을 저장하는 Sendable 분석기입니다. 동기 방식으로 동작하며 네트워크 요청을 보내지 않습니다.
- `resolve(explicitURL:sharedText:)`: 명시 URL, 제공자와 일치하는 URL, 나머지 필터링된 URL, 이전 형식의 식별 문자열 순으로 확인합니다.
- `resolveLinkInput(_:)`: URL만 필요한 경우에 사용하는 간편 API입니다.

## 책임 경계

이 패키지는 링크 선택만 담당합니다. 네트워크 요청, 리디렉션 추적, 추적 파라미터 제거, 방문 기록 저장은 수행하지 않습니다. 필터는 `localhost`, `.local`로 끝나는 host, `::1`, 그리고 `0/8`, `10/8`, `127/8`, `169.254/16`, `172.16/12`, `192.168/16`의 직접 입력 IPv4 주소만 거부합니다. `::1` 이외의 로컬 또는 사설 IPv6 리터럴은 통과합니다. 네트워크 계층에서 해석된 주소와 모든 리디렉션 목적지를 검증해야 합니다.

## 문서

- [시작하기](GettingStarted.md)
- [API 레퍼런스](API.md)
- [아키텍처](Architecture.md)
- [마이그레이션](Migration.md)
- [데모 앱](../../Examples/Documentation/ko/README.md)
- [기여](CONTRIBUTING.md)
- [보안 정책](SECURITY.md)
- [행동 강령](CODE_OF_CONDUCT.md)
- [변경 기록](CHANGELOG.md)

## 상태

현재 API 버전은 1.0 미만입니다. wondays에서 실제로 사용하고 있지만 안정 버전을 발표하기 전까지는 마이너 업데이트에서 이름이나 설정 방식을 변경할 수 있습니다.

## 라이선스

MIT. [LICENSE](../../LICENSE)
