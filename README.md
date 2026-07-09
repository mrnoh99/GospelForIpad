# 복음서 듣기 (아이패드용) · GospelForIpad

iPad용 가톨릭 4복음서 오디오 듣기 앱입니다. 오디오를 재생하면서 화면에
**동기화된 임베디드 텍스트**(장 소제목 + 현재 읽고 있는 절 위치)를 함께 보여 줍니다.

> ## ⚠️ 본문 저작권 (배포 전 필독)
> 탑재된 네 성경 본문은 **모두 저작권이 있으며 공유저작물이 아닙니다.** 앱(무료·유료 불문)에
> 본문을 담아 배포하려면 각 저작권자의 허가/라이선스가 필요합니다. 앱 내 본문 패널 하단에도
> 각 번역본의 저작권 안내가 표시됩니다(`BibleTranslation.licenseNote`).
>
> | 탭 | 번역본 | 저작권자 |
> |----|--------|----------|
> | 성경 | 한국 천주교 주교회의 「성경」 | 한국천주교주교회의·한국천주교중앙협의회(CBCK) |
> | 200주년 | 200주년 기념 신약성서 | 분도출판사 |
> | 공동번역 | 공동번역 성서 | 대한성서공회 |
> | NAB | New American Bible, revised edition | Confraternity of Christian Doctrine (USCCB) — 라이선스+허가비 필요 |
>
> 라이선스 없이 출시하려면 해당 탭을 제거하거나 공유저작물(예: Douay–Rheims, CPDV)로 대체하세요.

## 구성

- **베이스 앱**: iPhone용 `ListenToGospel`(SwiftUI) 프로젝트를 iPad용으로 확장했습니다.
- **오디오**: `listentogospel-android`의 `audioPack` 에셋에서 가져온 4복음서 m4a 파일
  (마태오 28장, 마르코 16장, 루카 24장, 요한 21장 — 총 89개)을 `GospelForIpad/AudioFiles`에 번들합니다.
- **임베디드 텍스트 데이터**:
  - `ChapterTitles.swift` — 장별 소제목 (← Android `ChapterTitles.kt`)
  - `VerseTimestamps.swift` — 절별 시작 시각(ms) 추정치 (← Android `VerseTimestamps.kt`)
  - `GospelText.json` — 4복음서 절 본문 (주교회의 「성경」) 3,779절
  - `GospelText200.json` — 4복음서 절 본문 (200주년 기념 성서) 3,778절
  - `GospelTextKCB.json` — 4복음서 절 본문 (공동번역 성서) 3,781절
  - `GospelTextNAB.json` — 4복음서 절 본문 (NAB/NABRE, 영어) 3,779절.
    ⚠️ NABRE는 CCD(USCCB) 저작권. 무료/유료 불문 앱 배포 시 **USCCB 라이선스+허가비 필요** — 라이선스 취득 후 배포할 것.
  - `GospelText.swift` — 네 번역본을 로드. `EmbeddedTextView` 상단의 세그먼트(탭)로 전환(선택은 `@AppStorage`로 유지).
    탭 라벨: 「성경」 · 「200주년」 · 「공동번역」 · 「NAB」.

## 임베디드 텍스트 동작

`EmbeddedTextView`가 재생 위치(`playbackElapsedSeconds`)와 `VerseTimestamps`로
현재 재생 중인 **절 번호**를 계산한 뒤, `GospelText`의 **절 본문**을 표시하면서
해당 절을 강조하고 자동으로 스크롤합니다. 화면 상단에는 `ChapterTitles`의
장 소제목이 표시됩니다. 즉 오디오 재생에 맞춰 성경 본문이 따라 움직이는
가라오케식 동기화 읽기 화면입니다.

## 오늘의 말씀 (오늘의 복음)

Android 앱의 "오늘의 복음" 기능을 이식했습니다.

- `LiturgicalCalendar.swift` — 부활절(Meeus 알고리즘)·대림 시작·전례 시기/주차·요일·주일 주기(가나다해)를
  계산하고 전례일 이름(한국 천주교)을 반환. (← `LiturgicalCalendar.kt`)
- `Lectionary.swift` — 3년 주기 미사 복음 독서표(주일/평일, 대림·성탄·연중·사순·부활)를
  4복음서 범위에서 (장, 시작 절)로 반환. (← `Lectionary.kt`)
- `TodayGospelView.swift` — 날짜·전례일 이름·복음 장/절을 보여 주는 카드.
  〈 / 오늘 / 〉 로 날짜 이동, 재생 버튼은 해당 복음을 **시작 절 위치부터** 재생
  (`BiblePlayerViewModel.playChapter(_:startVerse:)`). 카드를 탭하면 우측 본문 패널에서 미리 보기.

iPad 레이아웃에서는 좌측 컬럼 상단에 이 카드가 배치됩니다.

> ⭐️ 전례력·독서 데이터는 이 앱의 **1급 데이터**입니다. 출처·검증 이력·수정 절차는
> [`docs/LECTIONARY.md`](docs/LECTIONARY.md)를 따르세요. 수정 후에는 반드시
> `python3 scripts/validate_lectionary.py` 와 DEBUG 빌드 검증(LectionaryValidator)을 실행합니다.

## 레이아웃

`ContentView`는 가로 크기 클래스에 따라 적응합니다.

- **iPad (regular)**: 왼쪽에 기존 장 목록/재생 컨트롤, 오른쪽에 `EmbeddedTextView` 읽기 패널.
- **iPhone (compact)**: 기존 단일 컬럼 레이아웃을 그대로 유지.

## 빌드

`GospelForIpad.xcodeproj`를 Xcode 26 이상에서 엽니다. (Swift / SwiftUI, iOS 26,
`TARGETED_DEVICE_FAMILY = 1,2` 유니버설, iPad 최적화)
