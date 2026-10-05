# Esel 조사 보고서: 미니 잡지형 SNS의 근거와 기능 제안

조사일 2026-10-03 · 저장소 파일은 건드리지 않았다.

## 핵심 요약

1. 게시물을 "호"로 다루는 소셜 앱은 찾은 범위에서 없었다. Flipboard는 끝없는 수집 묶음, Issuu는 제작 도구, Substack은 글 중심이다. "하루 한 장 = 한 호"는 비어 있는 자리다(추론).
2. 잡지 요소 중 옮길 가치가 높은 것은 제호, 호수·발행일, 표지 한 줄, 크레딧, 책등 다섯 개다. 목차·바코드·가격·보조 표지 문구는 1인 일간 발행에서 기능이 없다(추론).
3. 잡지는 "부활"한 것이 아니라 소수·고가·저빈도·소장형으로 재편됐다. 한국 잡지 매출은 2년 새 21.1% 줄었지만[58], 아이돌 표지 한 호는 해외 판매처 한 곳에서 5만 부가 팔린다[63]. 힘이 남은 것은 형식(표지, 호수, 소장)이다.
4. 하루 한 번 구조는 유입 장치이지 유지 장치가 아니다. BeReal은 외부 추정 DAU가 5개월 사이 약 61% 줄었고[22], Lapse는 2025년 말 소셜 기능을 접었다[25].
5. 근거가 가장 단단한 설계 원칙은 "쉬어도 되게 하면 장기 참여가 는다"이다(Lally 2010[83], Duolingo 실험[122], Silverman & Barasch 2023[121]). 가장 약한 근거는 자이가르닉 효과, 초기 enclothed cognition, Hook 모델이다.
6. Esel에서 해가 될 지점은 세 곳이다: 같은 색 잠금(통행료로 읽힘), 달력·호수·트윈(이름만 다른 스트릭), 오늘의 표지(소수 선정 + 외모 서열). 규제는 스트릭·푸시·반응 수를 부품 단위로 겨눈다[137].
7. 먼저 할 일(제안): 결호 없는 호수, 잠금 완화, 크레딧 면, 판권 줄, 묶음 알림. 모두 난이도가 낮고 위험을 줄이는 쪽이다.

**조사 방법과 한계**
- 질문 1~3은 병렬 조사 에이전트 3개가 웹 검색·페이지 열람으로 조사했고(열람 출처 약 200개), 4번 제안은 그 결과로 내가 썼다.
- 내가 원문을 직접 다시 열어 대조한 것은 6건이다: [25] [53] [58] [64] [115] [122]. 모두 에이전트 보고와 일치했다. 나머지는 에이전트 보고에 의존한다.
- 표기: **(약)** = 2차 인용·통계 모음·홍보성 등 출처 약함, **(스니펫)** = 검색 요약만 보고 원문은 못 엶, **추론/제안** = 사실이 아닌 해석.

---

## 1. 미니 잡지형 게시물에 필요한 특징

### 1-1. 잡지 한 호의 요소와 옮길 가치

"옮길 가치" 열은 모두 추론이다.

| 요소 | 실제 잡지에서의 역할 | 옮길 가치 | 출처 |
|---|---|---|---|
| 제호(nameplate) | 표지에서 가장 큰 글자. 매 호 같은 서체·위치로 브랜드를 식별시킨다 | **높음.** 피드에서 "누구의 잡지인지"가 사진보다 먼저 읽힌다 | [1][2] |
| 호수·발행일 | 시간순 정리와 수집을 가능하게 한다 | **높음.** 점수가 아닌 누적 표시라 순위표 느낌 없이 지속 동기를 준다 | [1][2] |
| 메인 표지 문구 | 그 호의 대표 기사를 알려 집어 들게 한다 | **높음.** "사진 한 장 + 한 줄"의 한 줄이 이 자리다 | [1][2] |
| 크레딧·착용 정보 | 화보 옆 작은 글씨로 의상·브랜드·제작자를 기록한다 | **높음.** 쇼핑몰 느낌 없이 "정보 좀요" 수요를 해결한다 | [3][9] |
| 책등(spine) | 꽂혀 있을 때 제호와 호 정보를 보여 준다 | **높음.** 색 띠 책등이 쌓이는 서가는 그리드 프로필의 대안이다 | [3][4] |
| 메인 이미지 | 전통 표지는 큰 얼굴과 시선 맞춤을 쓴다 | **높음.** 단, 얼굴 가린 표지에는 별도 조판 규칙이 필요하다 | [1][2] |
| 펼침면(spread) | 마주 보는 두 쪽을 한 단위로 디자인한다 | **중간~높음.** 표지 → 안쪽 지면 구조. 세로 화면에서 좌우 펼침을 그대로 흉내 내면 글자가 작아진다 | [3][5] |
| 특집·기념호 | 한 주제나 기념일에 한 호를 쓴다 | **중간~높음.** 100호·계절 첫 호는 순위 없이 이정표를 만든다 | [4][5] (스니펫) |
| 판권면(colophon) | 발행처·날짜·제작 사양을 적는 마무리 면 | **중간.** "발행일 · 오늘의 색 · 연출 방식" 한 줄로 형식이 닫힌다 | [5][6] |
| 폴리오·러닝헤드 | 쪽마다 잡지명·호 이름을 넣는다 | **중간.** 캡처되어 밖으로 나가도 출처가 남는다 | [4][5] |
| 태그라인 | 제호 아래에서 편집 방향을 알린다 | **중간.** 프로필 소개 한 줄을 대체한다 | [1] |
| 편집자의 말 | 그 호의 분위기를 잡는 서명 글 | **중간.** 매일은 무겁고 월간 합본·창간호에 맞다 | [5][10] |
| 복수 표지·한정판 | 수집가를 겨냥한다. 구독자 불만·비용이 단점. Perfect 창간호는 422종 | **중간.** 희소성 경쟁으로 흐르면 "점수 느낌 회피"와 충돌한다 | [7][8] |
| 목차 | 내용과 쪽수 안내 | **낮음**(게시물) / 중간(서가 색인) | [3][5] |
| 보조 표지 문구 | 다른 기사 예고 | **낮음.** 예고할 기사가 없다 | [1][2] |
| 발행인란·바이라인 | 제작진 목록, 글쓴이 표시 | **낮음.** 1인 발행이라 제호가 대신한다 | [3][4] |
| 바코드·가격 | 유통·구매 정보 | **낮음.** 가격은 등급처럼 읽힐 위험이 있다 | [1][2] |

### 1-2. 비슷한 디지털 서비스

| 서비스 | 현재 상태 | 발행·잡지 관련 특징 | 성공·실패 이유 | 핵심 수치 | 출처 |
|---|---|---|---|---|---|
| Flipboard | 운영 중 | 2013년 사용자 "매거진"(수집 묶음), 앱이 잡지풍 자동 배치 | 끝이 없는 묶음이라 방치된다. 매달 활성 매거진은 25~50% | 사용자 매거진 2,800만 개(2016) | [11][12][13] |
| Issuu | 운영 중 | PDF를 플립북으로 호스팅, 호 단위 업로드 | 발행 도구이지 소셜 피드가 아니다 | 문서 5천만+(자사 소개) | [14] |
| Substack | 운영 중 | 글 한 편이 구독자에게 발송되는 "호". 팔로우 = 구독 | 독자 소유권, 구독료 10% 모델 | 유료 구독 500만(2025-03) | [15] |
| Apple News+ | 운영 중 | 잡지 300종 이상 호 단위 제공. 사용자 발행 없음 | — | 구독자 수 확인 못 함 | Wikipedia Apple News |
| Glass | 운영 중 | 공개 좋아요·팔로워 수 없음, 시간순, 광고 없음 | 구독료 운영. 활동량이 적다는 평 | 회원 수 확인 못 함. 연 $39.99 | [16][17] |
| Lemon8 | 운영 중 | 텍스트 템플릿을 얹는 "잡지풍 게시물" | 제작 부담, 다운로드가 급등 위주 | 글로벌 MAU 1,600만+(2025-03) (약) | [18] |
| BeReal | 운영 중(2024-06 Voodoo 5억 유로 인수) | 하루 한 번 무작위 알림, 2분 촬영, 지각 표시 | 매일 알림 피로, 진정성의 단조로움. 뒤에 제약을 풀었다 | 외부 추정 DAU 1,500만(2022-10) → 600만 미만(2023-03). 회사는 2,000만 주장 | [19][20][21][22] |
| Lapse | **소셜 기능 종료**(2025-11-03 공지, 12월 초 시행) | 지연 "현상", 월별 묶음 | 초대 강제로 1위 뒤 급감. 저장 비용 부담 | 일 다운로드 21.8만(2023-10) → 4.5만(2023-11) | [24][25] |
| Locket | 운영 중, 2024년 흑자 | 친한 친구 20명, 홈 화면 위젯 | 매일 보이는 자리 + 구독 수익 | DAU 900만(2025-08) | [26] |
| Retro | 운영 중 | 주 단위 공유, 주·월·연 회고 | 광고 없는 구독 모델 | 누적 약 700만 다운로드(2026-08) | [27] |
| Pinterest Shuffles | 2023-09 본 앱에 통합 | 오려 붙이는 콜라주 | 독립 앱은 유행 뒤 하락, 본 앱에서 Z세대 유입 | 콜라주 저장률 일반 핀의 약 3배(2024) | [28] |
| Zinel | 초기 앱 | 여러 쪽 디지털 진 발행, PDF·인쇄 내보내기. Esel에 가장 가깝다 | 평가 불가 | 수치 없음 | [29] |
| Lookbook.nu | **종료**(2023-09 접속 불가) | 착장 사진 + hype 투표 점수 | 인스타그램으로 이동 (약) | — | [30] |
| 스타일쉐어 | **종료**(2022) | 착장 공유, "ㅈㅂㅈㅇ" 댓글 문화 → 커머스 | 무신사 인수 뒤 고객층 중복·경쟁 열세 | 거래액 2,000억(2020), MAU 45만 → 26만(2022) | [31][32][33][34] |
| 무신사 스냅 | 운영 중 | 착용 상품 태그 → 상품 페이지 | 커뮤니티가 스토어의 발견 경로로 붙어 있다 | 개편 1주 뒤 업로드 +725%(2022-02) | [35] |
| 에이블리·지그재그 | 운영 중 | 커머스에 착장 공유·커뮤니티 추가 | 체류 시간 확보용 | 에이블리 MAU 998만(2026-04) (스니펫) | [36][37] |
| 29CM | 운영 중 | 콘텐츠형 큐레이션 커머스, 사용자 발행 없음 | 취향 큐레이션, 고단가 | 거래액 1.3조(2025) | [41] |
| Whering·Acloset | 운영 중 | 옷장 디지털화, 착장 캘린더. 발행 개념 없음 | 개인용 도구에 머문다 | Whering 1,000만(2026-07), Acloset 800만+(자사) | [38][39] |

확인 못 함: VSCO·Tumblr·Cosmos의 신뢰할 이용자 수, W컨셉의 커뮤니티 기능, Lookbook.nu 종료 공식 사유.

### 1-3. 시사점 (추론)

- **"호"는 마감이 있어야 성립한다.** Flipboard 매거진은 끝이 없어 방치됐다. "오늘 발행 완료"라는 닫힌 단위가 차별점이다.
- **제작은 앱이 한다.** Lemon8·Zinel형은 만들기가 무겁다. 사용자는 사진·색·한 줄만 고르고 조판은 자동이어야 매일 발행이 된다.
- **크레딧은 처음부터 지면 요소로 넣는다.** 스타일쉐어가 보여 주듯 착장 사진에는 반드시 정보 수요가 따른다.
- **커머스는 서두르지 않는다.** 살아남은 패션 커뮤니티는 커머스의 부속이다. 독립 SNS로 가려면 구독 모델(Glass, Locket, Retro)이 더 가까운 선례다.
- **얼굴 가린 표지는 조판을 따로 설계한다.** 전통 표지 문법이 얼굴 중심이기 때문이다.

---

## 2. 실제 잡지가 자리를 지키는 이유

### 2-1. 규모와 추세

| 지표 | 수치 | 기준 | 출처 |
|---|---|---|---|
| 영국 ABC 잡지 평균 인쇄 부수 | 약 9% 감소. 131종 중 인쇄 판매가 늘어난 잡지 10종 | 2025 | [42] |
| 영국 Harper's Bazaar 유료 인쇄 부수 | 30,547부, 22% 증가 | 2025 | [42] |
| 미국 상위 50개 잡지 | 인쇄 5% 감소, 디지털 16% 증가, 합산 3.6% 감소 | 2024 하반기 | [44] |
| 세계 소비자 잡지 시장 | 590억 달러, 매출의 80%가 인쇄 | 2022 (약, PwC 2차 인용) | [46] |
| 영국 독립지 표지가 | 10~25파운드 이상(일반 평균 7파운드) | 2023 (2차) | [47] |
| 영국 인쇄 잡지 월 도달 | 성인 1,900만 명, 55세 이상에 치우침 | 2022~2024 | [48] |

확인 못 함: PwC 최신판의 잡지 부문 수치, Statista·Pew·AAM 2025년 집계.

### 2-2. 패션지의 디지털 전환

| 지표 | 수치·사실 | 기준 | 출처 |
|---|---|---|---|
| 콘데나스트 매출 | 약 20억 달러, 상위 7개 브랜드가 85% | 2025 (FT 2차 인용) | [50] |
| 부문별 성장 | 이벤트 +40%, 디지털 구독 +29%, 커머스 +13% | 2025 (CEO 메모 인용) | [49] |
| 콘데나스트 영국 매출 구성 | 인쇄 45%, 디지털 35%, 이벤트 20% | 2025-09 | [52] |
| 미국 보그 | 2026년부터 연 8호(위키백과), 두꺼운 종이의 "소장판" 방침 | 2025~2026 | [53][54] |
| 보그 9월호 쪽수 | 900쪽 이상(2012) → 376쪽(2025) | 2025 | [53] |
| Teen Vogue | 2017-12 인쇄 종료, 2025-11 Vogue.com 흡수 | — | [55] |
| Glamour 미국판 | 2019년 1월호로 정기 인쇄 종료 | — | [56] |
| 허스트 영국 | 매출 1억 1,010만 파운드(+5%), 유료 구독 100만 건. 10년 전 대비 매출 61% 감소 | 2025 | [57] |

확인 못 함: 콘데나스트·허스트의 부문별 매출 비중(비상장), 보그 공식 소셜·유튜브 규모.

### 2-3. 한국 잡지 시장

| 지표 | 수치 | 기준 | 출처 |
|---|---|---|---|
| 잡지 발행 사업체 | 1,796개 | 2023 | [58] |
| 총 매출 | 5,315억 원, 2021년 대비 21.1% 감소. 2012년은 1조 8,625억 | 2023 | [58][61] |
| 매출 구성 | 판매 39.3%, 광고 31.2%, 기타 29.5% | 2023 | [58] |
| 종사자 | 6,625명, 업체당 3.7명 | 2023 | [58] |
| 호당 평균 발행부수 | 6,544부(2021) → 3,947부(2023) | 2023 | [59] |
| 엘르 2026년 8월호(BTS 진) | 표지 6종, 예약판매로 YES24 실시간 1~7위 | 2026-07 (연예 매체) | [62] |
| 해외 팬 판매처 최다 판매 표지 | 보그 코리아 2022-10(BTS 뷔) 51,900부 | 2022 (약, 팬 매체) | [63] |
| 무신사의 매거진 B 인수 | 비미디어컴퍼니 지분 100% | 2026-04-20 | [64][65] |
| 휴간·파산 | 샘터 2026년 1월호 뒤 무기한 휴간. 컨셉진 발행인의 미션캠프 2025-12 파산 공지 | — | [66][67](약) |

- 추론: 평균 발행부수가 3,947부인데 아이돌 표지 한 호가 판매처 한 곳에서 5만 부 팔린다. 한국 패션지는 "읽는 매체"보다 "팬이 소장하는 굿즈"로 팔리는 비중이 크다.
- 무신사가 매거진 B를 산 것은 패션 커머스가 편집 자산을 사들이는 흐름이라 Esel과 직접 관련된다(추론).
- 확인 못 함: 부록·굿즈 품절 사례, 복수 표지의 공식 판매 통계, 두산매거진·허스트중앙 매출.

### 2-4. 독립 잡지와 Z세대

| 대상 | 수치·사실 | 기준 | 출처 |
|---|---|---|---|
| 킨포크 | 낱권 22달러, 연 4호. 향수·스킨케어·서울 부티크로 확장. 인쇄 구독 약 75,000명 (약) | 2026 | [68][69] |
| 모노클 | 숍·카페·라디오·행사. 부수 80,251부는 2016년 자료 (약) | — | [70] |
| 아파르타멘토 | 연 2회, 광고 최소화, 단행본·에이전시 병행 | 2018 | [71] |
| magCulture 숍 | 독립지 600종 이상 취급 | 2023 | [72] |
| 언리미티드 에디션 17 | 251팀 참가(역대 최다) | 2025-11 | [73] |
| 한국 독립서점 | 292곳(2016) → 887곳(2025). 신규 개점은 143곳(2018) → 36곳(2025) | 2025 | [74] |
| 인쇄 복간 | i-D(연 2회, 20파운드), Vice(연 4회), Saveur(연 2회) | 2024~2025 | [75][77][78] |
| The Onion 인쇄판 | 유료 구독 53,000명 이상 | 2025-08 (WSJ 2차 인용) | [76] |
| 한국 20대 | 독서율 74.5%(2023), 필사책 판매 692% 증가(2024). 텍스트힙은 정체성 전시라는 해석 | — | [80] |

"Z세대가 인쇄로 돌아왔다"를 뒷받침하는 전국 단위 통계는 확인 못 함. 인쇄 독자는 여전히 55세 이상에 치우쳐 있다[48]. 소수 취향층의 소장·정체성 소비로 읽는 편이 안전하다(추론).

### 2-5. 자리를 지키는 이유와 시사점

| 이유 | 근거 | Esel 시사점 (추론) |
|---|---|---|
| 희소한 "호"와 소장 가치 | 보그 소장판 방침[53], 복간지들의 연 2~4회[75][77][78] | 게시물을 번호 붙은 한 호로 다룬다 |
| 표지가 곧 상품 | 한국 패션지 복수 표지와 예약판매[62][63] | 표지 한 장이 공유·수집의 단위다 |
| 끝이 있는 편집 | 독립지의 선별과 펼침면[72] | 무한 스크롤 대신 끝이 있는 가판대 |
| 정체성 신호 | 텍스트힙 해석[80], 독립지의 높은 가격[47] | 무엇을 발행하고 구독하는지가 자기표현 |
| 느린 매체 | 인쇄 복간[76][77][78], 진 워크숍 확산[81] | 실시간 경쟁보다 넘겨 보는 경험 |
| 이름의 확장 | 콘데나스트 이벤트·커머스[49], 킨포크·모노클의 숍[68][70] | 광고 외 수익(구독, 인쇄, 협업 호) |
| 직접 관계 | 허스트 영국 유료 구독 100만[57] | 팔로우보다 강한 "구독" |
| **반대 근거** | 영국 부수 연 9% 감소[42], 한국 매출 21.1% 감소[58], 독립서점 신규 개점 급감[74] | "형식의 힘은 남고 대량 유통 모델은 무너졌다"로 써야 정확하다 |

---

## 3. 계속 쓰게 만드는 심리 작용

"Esel 위험 지점" 열은 모두 추론이다.

| 심리 작용 | 근거 | 한계·반론 | Esel 위험 지점 |
|---|---|---|---|
| **매일의 과제·의식** | 자동성 도달 중앙값 66일, 하루 빠져도 타격이 작다(Lally 외 2010)[83]. 메타분석도 59~66일(Singh 외 2024)[84] | 건강행동 대상 연구. BeReal은 같은 구조로 급감[22], Wordle도 53억(2024) → 42억(2025) 플레이로 감소 (스니펫) | 신선함이 빨리 닳는다. 오늘의 색 옷이 없으면 구매 압박이나 자기배제. 결석을 벌주는 설계는 근거가 약하다 |
| **수집·완성 욕구** | 미리 채운 쿠폰 완주율 34% vs 19%(Nunes & Drèze 2006)[88]. 목표에 가까울수록 가속, 보상 뒤 리셋(Kivetz 외 2006)[89] | 자이가르닉(미완성 기억 우위)은 메타분석에서 지지되지 않음. 끊긴 일을 재개하는 경향은 약 67%(Ghibellini & Meier 2025)[90] | 달력 빈칸은 재개 압력. 빈칸 복구를 유료로 팔면 압박을 수익화한다. 달을 채운 뒤 동기 리셋 |
| **IKEA·소유 효과** | 직접 만든 것을 더 높이 평가(Norton 외 2012)[91], 메타분석 d=0.57(Pelled 외 2026)[92]. 소유 효과(Kahneman 외 1990)[93] | IKEA 효과는 완성했을 때만 생긴다. 소유 효과는 Plott & Zeiler 2005의 반박으로 논쟁 중[94] | 서가가 쌓일수록 잠금 효과. 내보내기·삭제가 어렵다면 애착이 아니라 인질 |
| **자기표현·정체성** | 자아 연출(Goffman 1959), SNS는 지워지지 않는 "전시"(Hogan 2010)[95]. 정체성 영역에서는 다수와 달라지려 한다(Berger & Heath 2007)[96] | Enclothed cognition은 직접 재현 실패, 초기 연구 재현성 우려(Horton 외 2025)[97] | 모두 같은 색이면 구별 신호가 약해진다. 지난 호가 영구 평판이 된다. "색이 기분을 바꾼다"류 문구는 근거가 약하다 |
| **인정(표지에 실림)** | 좋아요 많은 사진에 청소년 보상 회로 반응(Sherman 외 2016)[98]. 게시 행동은 보상 학습을 따른다(Lindström 외 2021)[99]. 상징적 상이 위키백과 신규 기여자 유지 약 20% 상승(Gallus 2017)[100] | 예고된 상은 효과 없고, 사후 상이 이후 출석을 줄인 사례(Robinson 외 2021, N=15,329)[101] | 소수 선정 + 예측 불가 = 변동 보상. 뽑히지 않는 다수가 "부족하다"는 신호를 받는다. 기준이 외모로 기울면 서열 |
| **희소성·FOMO** | 넉넉하다 줄어들 때 가치 상승(Worchel 외 1975)[102], 희소성 메타분석(Barton 외 2022)[103]. FOMO와 SNS 사용 상관(Przybylski 외 2013)[104] | 쿠키 실험의 직접 재현은 확인 못 함. FOMO 연구는 상관·자기보고 중심 | "오늘 안 올리면 못 본다"는 FOMO를 직접 만든다. 인위적 한정은 공정위 가이드라인의 압박형 다크패턴과 닿을 수 있다[135] |
| **기다림** | 좋은 것은 기다리는 동안에도 효용(Loewenstein 1987)[105]. 경험의 기다림이 더 즐겁다(Kumar 외 2014)[106]. 묶음 알림이 스트레스를 줄인다(Fitz 외 2019, n=237 무작위 실험)[107] | "느린 SNS가 유지율을 높인다"는 실증은 확인 못 함 | 주간·월간 발행물과는 맞지만 매일 과제와 충돌한다 |
| **상호성(올려야 본다)** | 상호성 규범(Gouldner 1960)[108] | BeReal 청소년 29명 인터뷰에서 올리기 싫은 날의 압박을 보고(Kim 외 2024)[86]. 잠금 효과를 직접 검증한 실험은 확인 못 함 | 잠금은 규범이 아니라 통행료. 무성의한 잠금 해제용 게시, 색 옷이 없는 사람의 배제 |
| **사회적 비교·신체 이미지** | 상향 비교(Festinger 1954; Gerber 외 2018 메타분석)[109]. SNS 외모 비교와 신체 불만족(Fardouly 외 2015[110]; 메타분석 r=.156[111]). 미 공중보건서비스단장: 13~17세의 46%가 신체 이미지 악화 응답[113]. 한국 중고생 501명 연구도 같은 방향[118] | 효과 크기는 작다: 청소년 안녕감 변동의 최대 0.4%(Orben & Przybylski 2019)[112]. Meta는 내부 조사가 소표본 인식 조사라고 반박[114] | 패션 사진은 그 자체가 비교 재료. 목 아래 자르기는 시선을 몸으로 모아 체형 비교를 키울 수 있다. 얼굴 가리기의 효과를 직접 검증한 연구는 확인 못 함 |
| **스트릭** | 끊기면 참여가 떨어지고 복구 수단이 완충한다(Silverman & Barasch 2023)[121]. Duolingo: 주말 보호로 1주 뒤 복귀 +4%[122] | Duolingo도 프리즈 3개는 2개보다 낫지 않았다[123]. Snap 내부 문서는 스트릭이 불안을 만든다고 인정[125], 유타주 등이 소송[126] | 색 달력 + 호수는 이름만 다른 스트릭. 트윈이 이어지면 상대에 대한 의무. 복구를 유료화하면 Snap의 유료 복구[127]와 같은 비판 |
| **자기결정성** | 예고된 외적 보상이 내적 동기를 깎는다(Lepper 외 1973[129]; Deci 외 1999 메타분석, 128개 실험[128]). 배지·순위표 수업에서 동기 하락(Hanus & Fox 2015)[130] | 점수·순위표가 내적 동기에 영향 없었다는 결과도 있다(Mekler 외 2017)[131]. 예고 없는 보상과 칭찬은 깎지 않는 쪽 | "오늘 반드시"는 자율성을 깎는다. 보상을 예고하면 옷 입는 즐거움이 보상 받기로 바뀐다 |
| **Hook 모델** | 계기 → 행동 → 변동 보상 → 투자(Eyal 2014, 실무 프레임) | 통제된 검증이 없는 사후 설명[132](약) | 알림 → 발행 → 표지·잠금 해제 → 서가로 고리와 정확히 겹친다. 규제는 부품 단위로 본다 |

### 좋아요 수 숨기기 근거

- Project Daisy: 10대의 비교 스트레스는 줄었지만 매출이 약 1% 줄어 출시가 14개월 늦어졌고, 선택 사항으로 나왔다[115].
- 신체 불만족은 좋아요 수보다 이미지 종류가 좌우했다(Tiggemann 외 2018, 여대생 220명)[116].
- 추론: 숫자를 숨기는 것만으로는 부족하고, 무엇을 보여 주느냐가 더 크다.

### 규제 요약

| 지역 | 내용 | 출처 |
|---|---|---|
| 한국 | 개정 전자상거래법 2025-02-14 시행. 숨은 갱신, 취소·탈퇴 방해, 반복간섭 등 6개 유형 금지 | [133][134] (스니펫 포함) |
| 한국 | 공정위 다크패턴 자율관리 가이드라인(2023-07), 19개 유형, 구속력 없음 | [135] |
| 한국 | 청소년 SNS 규제 법안 8건 국회 계류, 통과된 것 없음(2026-09-25 기준) | [136] |
| EU | 미성년자 보호 지침(2025-07): 반응 수, 스트릭, 푸시 알림 등을 미성년자에게 기본 꺼짐 권고. 스트릭 문구는 원문 대조 필요 | [137] |
| EU | TikTok의 중독적 설계를 DSA 위반으로 예비 판단(2026-02) | [138] |
| EU | BeReal: 동의 거절 시 매일 다시 묻는 창이 다크 패턴으로 진정됨(2024-12) | [139] |
| 미국 | 뉴욕 SAFE for Kids Act 최종 규칙, 2027-01-25 시행 | [140] |

확인 못 함: 전자상거래법 다크패턴 조항이 무료 SNS 기능(알림·잠금)에 적용되는 범위. 법률 검토가 필요하다.

---

## 4. Esel에 대입할 제안

전부 **제안**이다. 근거 번호는 위 절의 출처다.

### 4-1. 우선순위

| 순위 | 기능 | 효과 | 난이도 | 한 줄 이유 |
|---|---|---|---|---|
| 1 | 결호 없는 호수 + 무료 빈칸 복구 | 상 | 하 | 스트릭 부작용을 정책만으로 막는다 |
| 2 | 같은 색 잠금 완화 | 상 | 하 | 가장 큰 강요 지점을 줄인다 |
| 3 | 크레딧 면 | 상 | 중하 | 착장 SNS의 필수 수요, 잡지 문법과 일치 |
| 4 | 판권 줄(러닝헤드) | 중 | 하 | 형식 완결 + 외부 공유 출처 |
| 5 | 묶음 알림, 시각은 사용자가 선택 | 중 | 하 | BeReal의 피로 요인 회피, 규제 대비 |
| 6 | 자동 조판 | 상 | 중 | 매일 발행의 전제 조건 |
| 7 | 얼굴 가린 표지 전용 조판 | 상 | 중 | 핵심 차별점이자 가장 큰 안전 쟁점 |
| 8 | 오늘의 표지: 순환 선정 + 사후 통지 | 상 | 중 | 인정 효과는 살리고 서열은 막는다 |
| 9 | 끝이 있는 가판대 | 중 | 중하 | 느린 매체 정체성, 규제 대비 |
| 10 | 숫자 없는 독자 반응 | 중 | 하 | 비교 재료 축소 |
| 11 | 이정표 호(특별호) | 중 | 하 | 순위 없는 장기 목표 |
| 12 | 월간 합본호 | 중상 | 중 | 발행 안 하는 날에도 열 이유 |
| 13 | 휴간 선언 | 중 | 하 | 자율성, 복귀율 |
| 14 | 의무 없는 트윈 호 | 중 | 하 | 관계성은 살리고 2인 스트릭은 막는다 |
| 15 | 합본 내보내기·실물 인쇄 | 중 | 상 | 인질 방지 + 수익 경로 |

### 4-2. 기능별 상세

| 기능 | (a) 기대는 심리 | (b) 화면·흐름 | (c) 참고 | (d) 위험과 안전장치 | (e) 성공 지표 |
|---|---|---|---|---|---|
| **1. 결호 없는 호수 + 무료 빈칸 복구** | 엔다우드 프로그레스[88], 끊긴 스트릭의 참여 하락과 복구의 완충[121] | Nº는 발행할 때만 1 오른다. 빠진 날은 서가에 빈 자리를 만들지 않는다. 달력 빈칸은 회색 경고가 아니라 종이 여백. 복구는 "지난 사진으로 뒤늦은 호 발행"이며 무료 | Duolingo Earn Back이 유료 복구보다 유지율이 좋았다[123] | 위험: Nº 숫자 비교. 장치: 타인 Nº를 정렬·순위에 쓰지 않는다. 복구는 유료·광고 조건 금지, 월 횟수 상한 | 결석 뒤 7일 내 복귀율, 복구 사용 뒤 30일 유지율 |
| **2. 같은 색 잠금 완화** | 상호성[108]은 살리고 강요감[86]은 줄인다 | 발행 전에도 같은 색 표지 3장은 보인다. 나머지는 흐린 책등으로. 자정이 지나면 전부 열린다. 잠금 문구는 "발행하면 함께 펼쳐집니다" | BeReal의 올려야 보는 구조와 이후 완화[19] | 위험: 해제용 무성의 게시, FOMO. 장치: "놓치면 끝" 문구 금지, 미성년자는 잠금 없이 열람 | 잠금 화면에서 발행 전환율, 10초 미만 촬영 게시 비율, 잠금 관련 불만 |
| **3. 크레딧 면** | 정보 수요 해결, 지면 완성의 IKEA 효과[91] | 안쪽 지면 하단에 화보 크레딧 형식의 한두 줄: "셔츠 — 엄마 옷장 / 양말 — 무인양품". 브랜드 대신 "빈티지", "물려받음", "오래 입은 것"을 고를 수 있다 | 무신사 스냅 상품 태그[35], 스타일쉐어 "정보 좀요"[31], 화보 크레딧[9] | 위험: 브랜드 과시, 쇼핑몰화. 장치: 가격 표기 없음, 구매 버튼 없음, 비브랜드 선택지를 앞에 둔다 | 크레딧 작성률, 크레딧 탭률, "정보 묻는" 독자 한 줄 감소 |
| **4. 판권 줄(러닝헤드)** | 형식 완결, 소유감[93] | 지면 하단 한 줄 자동 생성: "MINSANG · Nº 014 · 2026.10.03 · 올리브". 공유 이미지에도 들어간다 | 판권면[6], 폴리오[4] | 위험: 외부 공유 시 닉네임 노출. 장치: 공유할 때 제호 가리기 선택 | 외부 공유율, 공유 이미지 경유 유입 |
| **5. 묶음 알림** | 묶음 알림의 스트레스 감소[107], 자율성[128] | 하루 한 번 "오늘의 색 세 가지가 도착했습니다". 시각은 창간 때 사용자가 고른다. 저녁 독촉 알림 없음 | BeReal의 무작위 시각 피로[19], Duolingo 밤 10시 구조 알림은 따르지 않는다[123] | 위험: 알림 약화로 발행률 하락. 장치: 미성년자는 기본 꺼짐[137]. 거절한 권유를 반복하지 않는다[139] | 알림 해제율, 알림 열람 → 발행 전환율 |
| **6. 자동 조판** | 낮은 노력으로 완성 → IKEA 효과[91] | 사진·색·한 줄만 고르면 제호·호수·색 띠가 자동 배치된다. 조판안 2~3개 중 선택 | Flipboard 자동 배치[11], Lemon8의 제작 부담[18] | 위험: 다 비슷해 보임. 장치: 사진 구도에 따라 조판이 달라지게 | 촬영 → 발행 완료율, 발행 소요 시간 중앙값 |
| **7. 얼굴 가린 표지 전용 조판** | 얼굴 비교 축소[110][116], 참여 장벽 낮춤 | 가리기를 고르면 전신 구도와 색 면이 주인공인 조판이 기본. 목 아래 자르기는 상반신 클로즈업이 아니라 착장 전체가 들어오게 | 직접 선례 확인 못 함 | 위험: 몸으로 시선 집중·대상화, "자신 없어서 가린다"는 낙인. 장치: 체형 보정 도구 없음, 가린 표지도 오늘의 표지 대상, 가림 여부를 필터·분류에 쓰지 않는다 | 가린 호의 비율, 가리기 사용자의 30일 유지율, 외모 관련 신고율 |
| **8. 오늘의 표지: 순환 선정 + 사후 통지** | 상징적 인정[100], 예고 없는 보상은 동기를 덜 깎는다[128] | 선정 기준은 반응 수가 아니라 색·구도·다양성. 색별 표지 12장으로 실리는 사람을 늘린다. 실린 뒤 조용한 알림 한 번. 프로필에 표지 횟수를 쌓지 않는다. 사전 동의한 사람만 대상 | Glass의 무순위[16], 위키백과 상 실험[100], 출석상 역효과[101] | 위험: 외모 서열, 변동 보상. 장치: 같은 사람 재선정 간격, 선정 기준 공개, "표지 도전" 식 예고 금지 | 90일 안에 한 번 이상 실린 활성 사용자 비율, 선정자의 체형·연출 분포, 동의율 |
| **9. 끝이 있는 가판대** | 큐레이션, 느린 매체 | 가판대는 색별 표지 벽. 끝에 "오늘의 가판대는 여기까지". 자동 이어 보기 없음 | Glass 시간순[16], EU의 무한 스크롤 문제 제기[138] | 위험: 체류 시간 감소. 장치: 체류 시간이 아니라 재방문을 목표 지표로 | 하루 세션 수, 7일 유지율, 끝까지 본 비율 |
| **10. 숫자 없는 독자 반응** | 비교 재료 축소[115] | 공개되는 것은 독자 한 줄뿐. 구독자 수·반응 수는 발행인 본인만 본다 | Glass[16], Project Daisy[115] | 위험: 피드백이 줄어 발행 동기 하락, 좋은 호를 찾기 어려움[115]. 장치: 발행인에게는 "오늘 12명이 읽었습니다" | 발행 빈도, 독자 한 줄 수, 비교 관련 설문 |
| **11. 이정표 호** | 목표 기울기[89], 수집 | 창간호, Nº 010·050·100, 창간 1주년에 표지 질감이 달라진다(박·다른 종이). 내 서가에서만 강조 | 잡지 기념호[4], 복수 표지[8] | 위험: 숫자 집착, 달성 뒤 동기 리셋[89]. 장치: 공개 순위 없음, 다음 이정표 하나만 보여 준다 | 이정표 전후 2주 발행률 변화 |
| **12. 월간 합본호** | 기다림의 효용[105][106], 수집·IKEA[91] | 월말에 그달의 호가 책등 색 순서로 묶인다. 목차와 선택형 "편집자의 말" 한 줄. 세 호뿐이어도 얇은 합본이 된다 | Retro의 주·월 회고[27], Lapse의 월별 묶음[25] | 위험: 빈 달의 압박. 장치: 호 수를 채점하지 않는다, "개근" 표시 없음 | 월말 열람률, 합본 공유율, 다음 달 유지율 |
| **13. 휴간 선언** | 자율성[128], 쉬어도 복귀한다[83][122] | "이번 주 휴간"을 고르면 알림이 멈추고 서가에 얇은 휴간 띠가 남거나 아무것도 남지 않는다(선택) | Duolingo 주말 보호 +4% 복귀[122] | 위험: 유연성이 과하면 쉬는 습관[123]. 장치: 휴간 종료일에 알림 한 번만 | 휴간 뒤 복귀율, 휴간 사용자와 무단 이탈자의 30일 유지율 차이 |
| **14. 의무 없는 트윈 호** | 관계성[128], 상호성[108] | 트윈은 호 단위 초대. 두 표지가 펼침면으로 나란히. "트윈 연속 일수" 같은 누적은 없다 | Snap 스트릭의 불안 사례[125], 미성년자 스트릭 기본 꺼짐 권고[137] | 위험: 상대에 대한 의무, 거절의 어색함. 장치: 초대는 조용히 만료, 거절 알림 없음 | 초대 수락률, 트윈 사용자 유지율, 한 쌍의 반복 횟수 분포 |
| **15. 합본 내보내기·실물 인쇄** | 소유 효과[93], 소장 가치(2절) | 합본을 PDF로 무료 저장. 실물 진 인쇄는 유료 주문 | Zinel[29], 진 문화 확산[81], 인쇄가 잡지 매출 기반[46] | 위험: 제작·배송 비용. 장치: 내보내기와 삭제는 항상 무료(인질 방지) | 내보내기율, 인쇄 주문 전환율 |

### 4-3. 전 기능에 걸친 안전장치 (제안)

| 항목 | 내용 | 근거 |
|---|---|---|
| 미성년자 기본값 | 푸시, 반응 수, 잠금, 트윈 누적을 기본 꺼짐 | [137][140] |
| 유료화 금지선 | 빈칸 복구, 잠금 해제, 표지 선정은 팔지 않는다 | [127][133] |
| 반복 권유 금지 | 거절한 알림·구독 권유를 매일 다시 묻지 않는다 | [139] |
| 구매 압박 차단 | 오늘의 색은 소품·양말·배경으로도 인정. 색 옆에 상품 추천을 붙이지 않는다 | 추론 |
| 외모 평가 문구 금지 | 독자 한 줄 입력창의 예시 문구를 외모가 아닌 색·조합 중심으로 | [110][116] |
| 근거 약한 문구 금지 | "색이 기분을 바꾼다" 같은 효능 표현을 쓰지 않는다 | [97] |

---

## 출처 목록

### 잡지 요소
1. Design Your Way, Anatomy of a Magazine Cover — https://www.designyourway.net/blog/anatomy-of-a-magazine-cover/
2. ANZAAE, Magazine cover elements (PDF) — https://anzaae.nz/wp-content/uploads/2024/01/magazine-cover-design.pdf
3. Magcast, Parts of a Magazine — https://magcast.co/Digital-Magazine-Publishing/Parts-of-a-Magazine/
4. Picante Creative, Glossary of Magazine Design Terms — https://www.picantecreative.com/magazine-design-blog/magazine-design/glossary-of-magazine-design-jargon-terms-and-definitions-for-new-publishers/
5. FlipLink, Magazine Layouts — https://fliplink.me/blog/magazine-layouts
6. Wikipedia, Colophon (publishing) — https://en.wikipedia.org/wiki/Colophon_(publishing)
7. Hammock, Choosing Two Covers for One Magazine — https://hammock.com/design/and-the-cover-goes-to-choosing-two-covers-for-one-magazine/
8. STACK, A magazine with 422 different covers — https://stackmagazines.com/fashion-style/a-magazine-with-422-different-covers/
9. Artells Magazine, Submission Guidelines — https://artellsmagazine.com/fashion-magazine-submission-guidelines
10. Istituto Marangoni, What is behind an editor's letter — https://www.istitutomarangoni.com/en/maze35/research/what-is-behind-an-editors-letter

### 서비스 사례
11. AppleInsider, Flipboard 2.0 — https://appleinsider.com/articles/13/03/26/flipboard-update-adds-sharable-self-curated-magazines
12. Wikipedia, Flipboard — https://en.wikipedia.org/wiki/Flipboard
13. Flipboard press, 11,000 magazines — https://about.flipboard.com/press/flipboard-opens-11000-curated-magazines-to-the-fediverse/
14. Issuu About — https://issuu.com/about
15. Wikipedia, Substack — https://en.wikipedia.org/wiki/Substack
16. PetaPixel, Glass (2021) — https://petapixel.com/2021/08/12/glass-is-a-subscription-based-photo-sharing-app-for-photographers/
17. App Store, Glass — https://apps.apple.com/us/app/glass-photography-community/id1528446339
18. TechCrunch, Lemon8 (2023) — https://techcrunch.com/2023/11/03/lemon8-the-instagram-rival-from-tiktok-parent-bytedance-fails-to-gain-traction-in-u-s
19. Wikipedia, BeReal — https://en.wikipedia.org/wiki/BeReal
20. Sensor Tower, Getting real about BeReal — https://sensortower.com/blog/getting-real-about-bereal
21. TechCrunch, BeReal 인수 분석 (2024) — https://techcrunch.com/2024/06/15/deal-dive-bereal-got-its-best-case-scenario-exit
22. Techmeme, NYT·Apptopia BeReal 수치 — https://www.techmeme.com/230414/p6
23. Marketing Brew, BeReal 2025 — https://www.marketingbrew.com/stories/2025/07/16/bereal-comeback-strategy
24. TechCrunch, Lapse (2023) — https://techcrunch.com/2023/11/27/lapse-a-photo-app-that-forced-users-to-invite-friends-is-running-out-of-steam/
25. Wikipedia, Lapse — https://en.wikipedia.org/wiki/Lapse_(social_network)
26. TechCrunch, Locket (2025) — https://techcrunch.com/2025/08/06/photo-sharing-app-locket-is-banking-on-a-new-celebrity-focused-feature-to-fuel-its-growth
27. Net Influencer, Retro Series A — https://www.netinfluencer.com/photo-sharing-app-retro-founded-by-ex-instagram-engineers-raises-21m-usd-series-a/
28. TechCrunch, Pinterest collages (2024) — https://techcrunch.com/2024/05/01/pinterest-says-its-ai-powered-collages-are-now-more-engaging-than-pins
29. App Store, Zinel — https://apps.apple.com/us/app/zinel/id6760587635
30. Wikipedia, Lookbook.nu — https://en.wikipedia.org/wiki/Lookbook.nu
31. 바이라인네트워크, 스타일쉐어, 안녕 — https://byline.network/2022/09/28_1984/
32. 디지털데일리, 스타일쉐어 연내 종료 — https://www.ddaily.co.kr/page/view/2022092713073944427
33. 아시아경제, 스타일쉐어 29CM 인수 — https://www.asiae.co.kr/article/2018031509455162857
34. 어패럴뉴스, 무신사가 얻은 것 — https://www.apparelnews.co.kr/news/news_view/?idx=191511&cat=CAT100
35. 바이라인네트워크, 무신사 스냅 (2022) — https://byline.network/2022/02/4-123/
36. 한국금융신문, 에이블리 스타일 포털 — https://www.fntimes.com/html/view.php?ud=202311161446213683b5b890e35c_18
37. 헤럴드경제, 패션 플랫폼 커뮤니티·경매 (2026-09-22) — https://www.heraldk.com/article/2026092200021430110
38. Tech.eu, Whering — https://tech.eu/2026/07/07/whering-lands-7m-as-digital-wardrobe-platform-reaches-10m-users/
39. Acloset 공식 — https://www.acloset.app/about/
40. Fast Company SA, Cosmos — https://fastcompany.co.za/co-design/2026-01-21-have-you-heard-of-cosmos-an-alternative-to-pinterest-and-instagram/
41. 뉴데일리, 29CM 거래액 1.3조 — https://biz.newdaily.co.kr/site/data/html/2026/02/20/2026022000049.html

### 잡지 시장
42. Press Gazette, 2025년 영국 잡지 판매 — https://pressgazette.co.uk/media-audience-and-business-data/media_metrics/biggest-selling-magazines-in-uk-2025/
43. Press Gazette, 2025년 여성지 판매 — https://pressgazette.co.uk/media-audience-and-business-data/media_metrics/womens-interest-magazine-sales-2025-harpers-bazaar-grows-in-print-and-digital/
44. Press Gazette, 2024년 미국 잡지 부수 — https://pressgazette.co.uk/media-audience-and-business-data/media_metrics/us-magazine-circulations-2024/
45. Press Gazette, AAM 대표 인터뷰 — https://pressgazette.co.uk/north-america/alliance-for-audited-media-aam-digital-circulation-change/
46. FIPP, Mapping the world of print — https://www.fipp.com/news/mapping-the-world-of-print/
47. voices.media, How today's magazine market is different — https://voices.media/how-todays-magazine-market-is-different/
48. Magnetic, PAMCo 보고 — https://magnetic.media/news-views/news/the-stories-behind-the-numbers-latest-pamco-report
49. MediaPost, Condé Nast Digs In — https://www.mediapost.com/publications/article/413157/conde-nast-digs-in-ceo-roger-lynch-describes-grow.html
50. MediaPost, Condé Nast Chief To Head Mattel — https://www.mediapost.com/publications/article/418428/conde-nast-chief-to-head-mattel.html
51. Adweek, 콘데나스트 이벤트 매출 — https://www.adweek.com/media/conde-nast-events-revenue-2026/
52. Press Gazette, 콘데나스트 영국 — https://pressgazette.co.uk/marketing/conde-nast-uks-plan-to-reach-50-digital-revenue-within-a-year/
53. Poynter, 보그 인쇄 방침 — https://www.poynter.org/commentary/2025/vogue-names-chloe-malle-new-editor-moves-to-sporadic-print-more-digital/
54. Wikipedia, Vogue — https://en.wikipedia.org/wiki/Vogue_(magazine)
55. Wikipedia, Teen Vogue — https://en.wikipedia.org/wiki/Teen_Vogue
56. Wikipedia, Glamour — https://en.wikipedia.org/wiki/Glamour_(magazine)
57. Press Gazette, 허스트 영국 실적 — https://pressgazette.co.uk/publishers/magazines/mag-giant-hearst-uk-returns-to-revenue-growth-after-three-years-of-decline/
58. 한국언론진흥재단, 2024 잡지산업 실태조사 — https://www.kpf.or.kr/front/board/boardContentsView.do?board_id=246&contents_id=c01fcf8cf22a4e9199db665e8b67ba24
59. 한국기자협회보, 잡지산업 실태조사 — http://m.journalist.or.kr/m/m_article.html?no=57518
60. 미디어오늘 (2025) — https://www.mediatoday.co.kr/news/articleView.html?idxno=323469
61. 미디어오늘 (2021) — https://www.mediatoday.co.kr/news/articleView.html?idxno=211635
62. 스타뉴스, 진 엘르 표지 — https://www.starnewskorea.com/star/2026/07/11/2026071106445691915
63. Koreaboo, Ktown4u 판매 순위 — https://www.koreaboo.com/lists/kpop-artists-ktown4u-top-10-best-selling-magazine-covers-ever/
64. 파이낸셜뉴스, 무신사 매거진 B 인수 — https://www.fnnews.com/news/202604201844086119
65. 바이라인네트워크, 무신사 매거진 B — https://byline.network/2026/04/20_192883/
66. 경향신문, 샘터 휴간 — https://www.khan.co.kr/article/202512101713001
67. 브런치, 컨셉진·미션캠프 — https://brunch.co.kr/@fashionomic/149
68. Kinfolk Notes, How a magazine becomes a lifestyle brand — https://kinfolknotes.com/en/blogs/news/how-a-magazine-becomes-a-lifestyle-brand
69. Kinfolk 가격 — https://www.kinfolk.com/product-category/kinfolk-magazines/
70. Wikipedia, Monocle — https://en.wikipedia.org/wiki/Monocle_(brand)
71. It's Nice That, Apartamento at ten — https://www.itsnicethat.com/features/10-years-of-apartamento-publication-080118
72. MediaCat, Jeremy Leslie 인터뷰 — https://mediacat.uk/magcultures-jeremy-leslie-on-the-growing-trend-of-beautiful-print-magazines/
73. 경기일보, 언리미티드 에디션 17 — https://www.kyeonggi.com/article/20251113580493
74. 동네서점, 2025 트렌드 보고서 — https://blog.bookshopmap.com/trends25/
75. Tomorrow's Publisher, i-D 복간 — https://tomorrowspublisher.today/new-audiences/i-d-magazine-to-relaunch-after-vices-bankruptcy/
76. Nieman Lab, The Onion 인쇄판 — https://www.niemanlab.org/reading/the-onion-brought-back-its-print-edition-and-expects-to-be-profitable-next-year/
77. MediaPost, Vice 복간 — https://www.mediapost.com/publications/article/399744/vice-magazine-offers-photo-issue-in-return-to-pr.html
78. MediaPost, Saveur 복간 — https://www.mediapost.com/publications/article/391222/saveur-magazine-returns-to-print.html
79. Istituto Marangoni, Gen Z와 인쇄 잡지 — https://www.istitutomarangoni.com/en/maze35/design/why-gen-z-is-driving-the-comeback-of-print-magazines-in-2025
80. 경향신문, 텍스트힙 — https://www.khan.co.kr/article/202510040600001
81. 데일리안, 진 문화 — https://www.dailian.co.kr/news/view/1684104/
82. Roy Morgan, 호주 잡지 독자 — https://www.roymorgan.com/findings/10057-australian-magazine-print-readership-and-cross-platform-audiences-september-2025

### 심리 연구
83. Lally 외 2010 — https://www.researchgate.net/publication/32898894_How_are_habits_formed_Modeling_habit_formation_in_the_real_world
84. Singh 외 2024 — https://www.mdpi.com/2227-9032/12/23/2488
85. Wikipedia, Wordle — https://en.wikipedia.org/wiki/Wordle
86. Kim 외 2024, BeReal 청소년 연구 — https://arxiv.org/abs/2408.02883
87. Kaňková 외 2025 — https://journals.sagepub.com/doi/10.1177/14614448251317689
88. Nunes & Drèze 2006 — https://papers.ssrn.com/sol3/papers.cfm?abstract_id=991962
89. Kivetz, Urminsky, Zheng 2006 — https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2733214
90. Ghibellini & Meier 2025 — https://www.nature.com/articles/s41599-025-05000-w
91. Norton, Mochon, Ariely 2012 — https://scholars.duke.edu/display/pub861385
92. Pelled 외 2026, IKEA 효과 메타분석 — https://onlinelibrary.wiley.com/doi/10.1002/mar.70064
93. Kahneman, Knetsch, Thaler 1990 — https://econpapers.repec.org/RePEc:ucp:jpolec:v:98:y:1990:i:6:p:1325-48
94. Plott & Zeiler 2005 — https://www.aeaweb.org/articles?id=10.1257%2F0002828054201387
95. Hogan 2010 — https://www.researchgate.net/publication/254080299_The_Presentation_of_Self_in_the_Age_of_Social_Media_Distinguishing_Performances_and_Exhibitions_Online
96. Berger & Heath 2007 — https://www.gsb.stanford.edu/faculty-research/publications/where-consumers-diverge-others-identity-signaling-product-domains
97. Horton, Adam, Galinsky 2025 — https://journals.sagepub.com/doi/abs/10.1177/01461672231182478
98. Sherman 외 2016 — https://pmc.ncbi.nlm.nih.gov/articles/PMC5387999/
99. Lindström 외 2021 — https://www.nature.com/articles/s41467-020-19607-x
100. Gallus 2017 — https://escholarship.org/uc/item/7d91p8hf
101. Robinson, Gallus, Lee, Rogers 2021 — https://scholar.harvard.edu/files/todd_rogers/files/the_demotivating_effect_and_unintended_message_of_awards_vf.pdf
102. Worchel, Lee, Adewole 1975 — https://www.semanticscholar.org/paper/Effects-of-Supply-and-Demand-on-Ratings-of-Object-Worchel-Lee/e80a3b8c8b27fa69cc6f4fb4c4e497f705f07a89
103. Barton, Zlatevska, Oppewal 2022 — https://doi.org/10.1016/j.jretai.2022.06.003
104. Przybylski 외 2013 — https://centaur.reading.ac.uk/34846/
105. Loewenstein 1987 — https://academic.oup.com/ej/article-abstract/97/387/666/5190020
106. Kumar, Killingsworth, Gilovich 2014 (보도 요약) — https://sciencedaily.com/releases/2014/08/140825100051.htm
107. Fitz 외 2019 — https://scholars.duke.edu/publication/1402953
108. Gouldner 1960 — https://www.semanticscholar.org/paper/THE-NORM-OF-RECIPROCITY:-A-PRELIMINARY-STATEMENT-*-Gouldner/650da7d336bbf5c544ee3003b36fcbe606f9aa46
109. Gerber, Wheeler, Suls 2018 — https://www.psychologytoday.com/sites/default/files/gerberwheelersulsmeta_analysis.pdf
110. Fardouly 외 2015 — https://www.sciencedirect.com/science/article/abs/pii/S174014451400148X
111. Saiphoo & Vahedi 2019 — https://www.semanticscholar.org/paper/A-meta-analytic-review-of-the-relationship-between-Saiphoo-Vahedi/c2a14daccbb9fba8bf067185a5f161ff8654cf98
112. Orben & Przybylski 2019 — https://www.nature.com/articles/s41562-018-0506-1
113. 미 공중보건서비스단장 권고문 2023 — https://www.hhs.gov/sites/default/files/sg-youth-mental-health-social-media-advisory.pdf
114. Meta, 내부 연구 반박 — https://about.fb.com/news/2021/09/research-teen-well-being-and-instagram/
115. Shorenstein Center, Project Daisy 사례연구 — https://shorensteincenter.org/resource/case-study-online-youth-harms-project-daisy/
116. Tiggemann 외 2018 — https://doi.org/10.1016/j.bodyim.2018.07.002
117. Wallace & Buil 2021 — https://mural.maynoothuniversity.ie/17405/1/1-s2.0-S0191886920307005-main.pdf
118. 이상의·이숙정 2019 — https://kci.go.kr/kciportal/ci/sereArticleSearch/ciSereArtiView.kci?sereArticleSearchBean.artiId=ART002439155
119. 이시원·장경은 2023 — https://www.kci.go.kr/kciportal/ci/sereArticleSearch/ciSereArtiView.kci?sereArticleSearchBean.artiId=ART002951249
120. 박지혜·조재희 2026 — https://www.kci.go.kr/kciportal/ci/sereArticleSearch/ciSereArtiView.kci?sereArticleSearchBean.artiId=ART003301292
121. Silverman & Barasch 2023 — https://www.insead.edu/faculty-research/publications/journal-articles/or-track-how-broken-streaks-affect-consumer
122. Duolingo 블로그, 스트릭 실험 (2017) — https://blog.duolingo.com/how-streaks-keep-duolingo-learners-committed-to-their-language-goals/
123. Lenny's Podcast 전사본, Jackson Shuttleworth — https://github.com/ChatPRD/lennys-podcast-transcripts/blob/main/episodes/jackson-shuttleworth/transcript.md
124. van Essen & Van Ouytsel 2023 — https://www.sciencedirect.com/science/article/pii/S2772503023000476
125. Bureau of Investigative Journalism, Snap 내부 문서 — https://www.thebureauinvestigates.com/stories/2025-12-03/snapchat-ignored-staff-warnings-about-teens-mental-health
126. 유타주 대 Snap 소장 — https://commerce.utah.gov/wp-content/uploads/2025/06/2025.06.30-Public-UT-Snap-Complaint.pdf
127. Snap, 스트릭 복구 — https://newsroom.snap.com/keep-the-streak-with-restore
128. Deci, Koestner, Ryan 1999 — https://home.ubalt.edu/tmitch/642/articles%20syllabus/Deci%20Koestner%20Ryan%20meta%20IM%20psy%20bull%2099.pdf
129. Lepper, Greene, Nisbett 1973 — https://www.researchgate.net/publication/281453299_Undermining_children%27s_intrinsic_interest_with_extrinsic_reward_A_test_of_the_overjustification_hypothesis
130. Hanus & Fox 2015 — https://www.researchgate.net/publication/265644737
131. Mekler 외 2017 — https://bruehlmann.io/publication/mekler-towards-2017/
132. The Behavioral Scientist, Hooked 비판 — https://www.thebehavioralscientist.com/articles/hooked-how-to-build-habit-forming-products-is-wrong

### 규제
133. 법률신문, 전자상거래법 다크패턴 — https://www.lawtimes.co.kr/LawFirm-NewsLetter/205545
134. 김앤장, 개정 전자상거래법령 시행 — https://www.kimchang.com/ko/insights/detail.kc?sch_section=4&idx=31411
135. 공정위, 온라인 다크패턴 자율관리 가이드라인 — https://www.ftc.go.kr/www/selectBbsNttView.do?pageUnit=10&pageIndex=2&searchCnd=all&key=12&bordCd=3&searchViolt=11&nttSn=42957&rltnNttSn=45940
136. 서울신문, 청소년 SNS 규제 법안 (2026-09-25) — https://www.seoul.co.kr/news/economy/2026/09/24/20260924500008
137. EU 집행위, 미성년자 보호 지침 — https://digital-strategy.ec.europa.eu/en/library/commission-publishes-guidelines-protection-minors
138. EU 집행위, TikTok 예비 판단 — https://digital-strategy.ec.europa.eu/en/news/commission-preliminarily-finds-tiktoks-addictive-design-breach-digital-services-act
139. noyb, BeReal 진정 — https://noyb.eu/en/bereal-app-wont-take-no-answer
140. 뉴욕주 법무장관, SAFE for Kids Act 최종 규칙 — https://ag.ny.gov/press-release/2026/attorney-general-james-and-governor-hochul-release-final-safe-kids-act-rules

## 확인하지 못한 것

- PwC·Statista·AAM의 최신 잡지 시장 수치, 콘데나스트·허스트의 부문별 매출 비중.
- Apple News+ 구독자 수, Glass 회원 수, Retro MAU, BeReal의 2025~2026 독립 추정 이용자 수.
- 한국 잡지 부록·굿즈 품절 사례, 복수 표지 공식 판매 통계, 2023년 기준 이후의 잡지산업 실태조사.
- Z세대 인쇄 잡지 구매율의 전국 단위 조사.
- "올려야 볼 수 있다" 잠금의 효과, 얼굴 가리기가 외모 비교에 주는 영향을 직접 검증한 연구.
- 엔다우드 프로그레스·쿠키 실험의 사전등록 재현 여부.
- 전자상거래법 다크패턴 조항이 무료 SNS 기능에 적용되는 범위(법률 검토 필요).
- EU 미성년자 보호 지침 원문의 스트릭 문구(요약과 해설로만 확인).
