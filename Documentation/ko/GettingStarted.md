# KLShareLink 시작하기

> <span lang="ko">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

## 1. 패키지 추가

Xcode의 Add Package Dependencies에서 `https://github.com/KoenLee1023/KLShareLink.git`을 추가하거나 `Package.swift`에 `0.1.0` 이상의 의존성을 선언합니다. 공유 내용을 받는 앱 또는 확장 target에 `KLShareLink` 제품을 연결하세요.

## 2. 제공자 정책 설정

제공자가 적으면 `[ShareLinkProvider]`를 직접 만들 수 있습니다. 여러 target에서 규칙을 공유한다면 다음 JSON 봉투 구조를 앱 리소스에 저장하고 `ShareLinkResolver(configurationData:)`로 디코딩하세요.

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

제공자 규칙은 출처 식별 정보만 표현합니다. 화면 이동, UI, 분석 이벤트, 분석 이후 동작은 통합 앱에서 담당합니다.

## 3. 두 공유 입력을 구분해 분석

```swift
let resolution = resolver.resolve(
    explicitURL: itemURL,
    sharedText: itemText
)
```

명시적 URL을 공유 텍스트에 합치지 마세요. 분석기 필터를 통과한 명시적 URL이 가장 높은 우선순위를 갖습니다. 명시적 URL이 없거나 거부된 경우에만 공유 텍스트를 사용합니다.

## 4. 모든 결과 조합 처리

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

제공자 이름만 있는 결과는 이전 형식의 공유 표식을 식별했지만 목적지 URL은 만들지 않았다는 뜻입니다. 제공자 이름을 URL이 존재한다는 근거로 사용하지 마세요.

## 5. 네트워크 요청 전 재검증

KLShareLink는 `localhost`, `.local`로 끝나는 host, `::1`, API 레퍼런스에 명시된 직접 입력 IPv4 범위를 거부합니다. `::1` 이외의 로컬 또는 사설 IPv6 리터럴은 필터에서 거부하지 않습니다. 네트워크 클라이언트가 해석된 주소와 모든 리디렉션 목적지를 별도로 검증해야 합니다.

## 통합 테스트 체크리스트

- 필터를 통과한 명시적 URL과 무관한 텍스트가 함께 있는 경우
- 명시적 URL이 거부된 뒤 텍스트 후보를 선택하는 경우
- 일반 링크 뒤에 제공자와 일치하는 링크가 있는 경우
- 정확한 host, 하위 도메인, 유사 접미사 host
- URL 없이 이전 형식의 식별 문자열만 유효한 경우
- 문서에 명시된 직접 입력 IPv4 범위, `::1`, `.local`, HTTP(S) 이외의 scheme
- `::1` 이외의 로컬 또는 사설 IPv6 리터럴
- 빈 입력과 공백만 있는 입력

패키지 테스트는 일반 분석 계약을 다룹니다. 통합 앱에서는 자체 제공자 설정, 화면 이동, 어댑터도 테스트하세요.
