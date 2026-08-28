# KLShareLink 데모 앱

> <span lang="ko">[English](../en/README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLShareLink는 서드파티 런타임 의존성이 없는 동기 방식의 Swift 패키지입니다. scheme과 host 필터를 통과한 HTTP(S) URL과 선택적 제공자 이름을 반환합니다.

## Link Inspector

필터를 통과한 명시적 URL을 가장 먼저 사용 · 본문의 HTTP(S) URL을 등장 순서대로 검색 · 설정한 제공자 도메인과 일치하는 URL을 우선 선택

## Policy Playground

설정한 제공자 도메인과 일치하는 URL을 우선 선택 · `localhost`, `.local`, `::1`, 문서에 명시된 직접 입력 IPv4 범위 거부 · URL이 없어도 이전 형식의 식별 문자열에서 제공자 이름만 확인 가능

두 데모 앱에는 각각 전용 `Package.swift`와 앱 진입점이 있습니다. 저장소 루트의 패키지만 사용하며 wondays 코드나 리소스를 가져오지 않습니다.

이 패키지는 링크 선택만 담당합니다. 네트워크 요청, 리디렉션 추적, 추적 파라미터 제거, 방문 기록 저장은 수행하지 않습니다. `::1` 이외의 로컬 또는 사설 IPv6 리터럴은 필터에서 거부하지 않습니다. 네트워크 계층에서 해석된 주소와 모든 리디렉션 목적지를 검증해야 합니다.
