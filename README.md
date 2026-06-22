# 복음서 듣기 (아이패드용) · GospelForIpad

iPad용 가톨릭 4복음서 오디오 듣기 앱입니다. 오디오를 재생하면서 화면에
**동기화된 임베디드 텍스트**(장 소제목 + 현재 읽고 있는 절 위치)를 함께 보여 줍니다.

## 구성

- **베이스 앱**: iPhone용 `ListenToGospel`(SwiftUI) 프로젝트를 iPad용으로 확장했습니다.
- **오디오**: `listentogospel-android`의 `audioPack` 에셋에서 가져온 4복음서 m4a 파일
  (마태오 28장, 마르코 16장, 루카 24장, 요한 21장 — 총 89개)을 `GospelForIpad/AudioFiles`에 번들합니다.
- **임베디드 텍스트 데이터**: Android 앱에 들어 있던 성경 데이터 파일을 Swift로 이식했습니다.
  - `ChapterTitles.swift` — 장별 소제목 (← `ChapterTitles.kt`)
  - `VerseTimestamps.swift` — 절별 시작 시각(ms) 추정치 (← `VerseTimestamps.kt`)

## 임베디드 텍스트 동작

`EmbeddedTextView`가 재생 위치(`playbackElapsedSeconds`)와 `VerseTimestamps`를 이용해
현재 재생 중인 **절 번호**를 계산하고, 해당 절을 강조하며 자동으로 스크롤합니다.
화면 상단에는 `ChapterTitles`의 장 소제목이 표시됩니다.

> 참고: 원본 저장소들에는 절 본문 전체 텍스트가 포함되어 있지 않습니다. 따라서 현재
> 임베디드 텍스트는 **장 소제목 + 절 위치(절 번호·타임스탬프)**를 동기화해 보여 줍니다.
> 절 본문 전체를 추가하려면 본문 데이터 소스만 채우면 동일한 동기화 로직을 그대로
> 재사용할 수 있습니다.

## 레이아웃

`ContentView`는 가로 크기 클래스에 따라 적응합니다.

- **iPad (regular)**: 왼쪽에 기존 장 목록/재생 컨트롤, 오른쪽에 `EmbeddedTextView` 읽기 패널.
- **iPhone (compact)**: 기존 단일 컬럼 레이아웃을 그대로 유지.

## 빌드

`GospelForIpad.xcodeproj`를 Xcode 26 이상에서 엽니다. (Swift / SwiftUI, iOS 26,
`TARGETED_DEVICE_FAMILY = 1,2` 유니버설, iPad 최적화)
