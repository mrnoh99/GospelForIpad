# 복음서 듣기 (아이패드용) · GospelForIpad

iPad용 가톨릭 4복음서 오디오 듣기 앱입니다. 오디오를 재생하면서 화면에
**동기화된 임베디드 텍스트**(장 소제목 + 현재 읽고 있는 절 위치)를 함께 보여 줍니다.

## 구성

- **베이스 앱**: iPhone용 `ListenToGospel`(SwiftUI) 프로젝트를 iPad용으로 확장했습니다.
- **오디오**: `listentogospel-android`의 `audioPack` 에셋에서 가져온 4복음서 m4a 파일
  (마태오 28장, 마르코 16장, 루카 24장, 요한 21장 — 총 89개)을 `GospelForIpad/AudioFiles`에 번들합니다.
- **임베디드 텍스트 데이터**:
  - `ChapterTitles.swift` — 장별 소제목 (← Android `ChapterTitles.kt`)
  - `VerseTimestamps.swift` — 절별 시작 시각(ms) 추정치 (← Android `VerseTimestamps.kt`)
  - `GospelText.json` — 4복음서 절 본문 (주교회의 「성경」) 3,779절
  - `GospelText200.json` — 4복음서 절 본문 (200주년 기념 성서) 3,778절
  - `GospelText.swift` — 두 번역본을 로드. `EmbeddedTextView` 상단의 세그먼트(탭)로 전환(선택은 `@AppStorage`로 유지).

## 임베디드 텍스트 동작

`EmbeddedTextView`가 재생 위치(`playbackElapsedSeconds`)와 `VerseTimestamps`로
현재 재생 중인 **절 번호**를 계산한 뒤, `GospelText`의 **절 본문**을 표시하면서
해당 절을 강조하고 자동으로 스크롤합니다. 화면 상단에는 `ChapterTitles`의
장 소제목이 표시됩니다. 즉 오디오 재생에 맞춰 성경 본문이 따라 움직이는
가라오케식 동기화 읽기 화면입니다.

## 레이아웃

`ContentView`는 가로 크기 클래스에 따라 적응합니다.

- **iPad (regular)**: 왼쪽에 기존 장 목록/재생 컨트롤, 오른쪽에 `EmbeddedTextView` 읽기 패널.
- **iPhone (compact)**: 기존 단일 컬럼 레이아웃을 그대로 유지.

## 빌드

`GospelForIpad.xcodeproj`를 Xcode 26 이상에서 엽니다. (Swift / SwiftUI, iOS 26,
`TARGETED_DEVICE_FAMILY = 1,2` 유니버설, iPad 최적화)
