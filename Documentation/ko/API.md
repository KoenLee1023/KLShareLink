# KLShareLink API 레퍼런스

> <span lang="ko">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLShareLink는 서드파티 런타임 의존성이 없는 Swift 패키지입니다. iOS 17 이상과 macOS 14 이상을 지원합니다. 모든 분석은 동기 방식으로 실행되며 입력, 제공자 순서, Foundation 동작이 같으면 같은 결과를 반환합니다. 패키지는 네트워크 요청을 보내지 않습니다.

## `ShareLinkResolution`

```swift
public struct ShareLinkResolution: Equatable, Sendable {
    public let url: URL?
    public let providerName: String?
    public init(url: URL?, providerName: String?)
}
```

URL과 제공자 정보를 각각 저장하는 값입니다.

- `url`: 저장된 URL입니다. `ShareLinkResolver`가 반환한 값에서는 scheme과 host 필터를 통과했습니다. 직접 초기화한 값에는 임의의 URL을 저장할 수 있습니다.
- `providerName`: 제공자 표시 이름입니다. 일반 URL이 제공자와 일치하지 않으면 `nil`입니다. 이전 형식의 식별 문자열만 일치한 경우에는 URL 없이 표시 이름만 저장할 수 있습니다.

### `init(url:providerName:)`

- `url`: 그대로 저장할 임의의 URL 또는 `nil`입니다.
- `providerName`: 그대로 저장할 임의의 제공자 이름 또는 `nil`입니다.
- 동작: URL scheme이나 host를 검증하지 않고 분석기 필터도 실행하지 않습니다. URL과 제공자 이름의 관계도 확인하지 않습니다.
- 오류: 오류를 던지지 않습니다.

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

- `displayName`: 일치할 때 통합 앱에 그대로 반환하는 이름입니다. 패키지는 이 값을 현지화하지 않습니다.
- `domains`: 제공자를 식별하는 host 목록입니다. 비교할 때 대소문자를 구분하지 않고 host와 설정값의 앞뒤 마침표를 제거합니다. `example.com`은 `example.com` 및 `m.example.com`과 일치하지만 `notexample.com`과는 일치하지 않습니다.
- `legacyTokenPatterns`: URL이 필터를 통과하지 못한 경우에만 확인하는 `NSRegularExpression` 패턴입니다. 잘못된 패턴은 분석 중 무시됩니다.

`init(displayName:domains:legacyTokenPatterns:)`는 세 인자를 그대로 저장합니다. 도메인이나 정규식을 검증하지 않으며 오류를 던지지 않습니다. 합성되는 `Codable` 키는 `displayName`, `domains`, `legacyTokenPatterns`입니다.

## `ShareLinkResolver`

```swift
public struct ShareLinkResolver: Sendable
```

설정 후 변경되지 않는 순서 있는 제공자 목록을 저장하는 분석기입니다. 공유 상태를 변경하지 않습니다.

### `init(providers:)`

```swift
public init(providers: [ShareLinkProvider])
```

- `providers`: 일치 우선순위대로 정렬한 제공자 규칙입니다. 여러 제공자가 같은 host 또는 이전 형식의 식별 문자열과 일치하면 목록에서 먼저 나오는 제공자를 선택합니다.
- 동작: 지정한 순서를 그대로 저장합니다. 빈 목록에서도 필터를 통과한 일반 URL을 반환할 수 있습니다.
- 오류: 오류를 던지지 않습니다.

### `init(configurationData:)`

```swift
public init(configurationData: Data) throws
```

- `configurationData`: 최상위 구조가 `{ "providers": [...] }`인 JSON 데이터입니다.
- 반환: 디코딩한 순서 있는 제공자 목록을 저장하는 분석기입니다.
- 오류: JSON 형식이 잘못되었거나 필수 키가 없거나 필드 형식이 다르면 `JSONDecoder`의 디코딩 오류를 던집니다. 정규식은 분석할 때 컴파일하므로 잘못된 패턴 때문에 이 초기화 메서드가 실패하지는 않습니다.

### `resolve(explicitURL:sharedText:)`

```swift
public func resolve(
    explicitURL: URL?,
    sharedText: String?
) -> ShareLinkResolution
```

- `explicitURL`: 가장 먼저 확인할 URL입니다. 필터를 통과하면 `providerName`을 `nil`로 두고 즉시 반환합니다. 값이 없거나 거부되면 `sharedText`를 처리합니다.
- `sharedText`: URL과 이전 형식의 식별 문자열을 찾을 선택적 텍스트입니다. 값이 없거나 비어 있거나 공백만 있으면 빈 결과를 반환합니다.
- 반환: 아래 우선순위에 따라 얻은 `ShareLinkResolution`입니다.
- 오류: 오류를 던지지 않습니다. 잘못된 정규식은 무시합니다.

분석 순서:

1. 필터를 통과한 명시적 URL을 제공자 이름 없이 반환합니다.
2. 텍스트가 없거나 공백뿐이면 `(nil, nil)`을 반환합니다.
3. `NSDataDetector`로 텍스트 등장 순서에 따라 URL을 찾고 필터를 통과하지 못한 후보를 제거합니다.
4. 설정된 제공자와 일치하는 첫 번째 후보를 반환합니다.
5. 제공자 후보가 없으면 남은 첫 번째 후보를 `providerName == nil`로 반환합니다.
6. URL이 없으면 이전 형식의 식별 문자열과 일치하는 첫 번째 제공자를 `url == nil`로 반환합니다.
7. 일치 항목이 없으면 `(nil, nil)`을 반환합니다.

필터는 `http`와 `https`만 허용하고 비어 있지 않은 host를 요구합니다. 분석기는 정확히 `localhost`인 host, `.local`로 끝나는 host, IPv6 루프백 `::1`, 그리고 `0.0.0.0/8`, `10.0.0.0/8`, `127.0.0.0/8`, `169.254.0.0/16`, `172.16.0.0/12`, `192.168.0.0/16` 범위에 속하는 직접 입력 IPv4 주소를 거부합니다.

`::1` 이외의 로컬 또는 사설 IPv6 리터럴은 이 필터에서 거부하지 않습니다. DNS를 해석하지 않고 리디렉션도 검사하지 않습니다. 필터 통과는 네트워크 접근 허가를 의미하지 않습니다. 네트워크 계층에서 해석된 주소와 모든 리디렉션 목적지를 검증해야 합니다.

### `resolveLinkInput(_:)`

```swift
public func resolveLinkInput(_ input: String) -> URL?
```

- `input`: 하나 이상의 링크를 포함할 수 있는 임의의 텍스트입니다.
- 반환: `resolve(explicitURL: nil, sharedText: input).url`과 같은 값입니다. URL이 필터를 통과하지 못하면 `nil`을 반환합니다. 이전 형식의 제공자만 일치한 경우에도 `nil`을 반환합니다.
- 오류: 오류를 던지지 않습니다.

## 동시성과 성능

모든 공개 타입은 `Sendable`입니다. 분석 메서드, 데이터 탐지, 정규식 일치는 호출자의 executor에서 동기 방식으로 실행됩니다. 매우 큰 입력을 처리할 때는 지연 시간에 민감한 UI 실행 경로에서 호출하지 않는 편이 좋습니다.
