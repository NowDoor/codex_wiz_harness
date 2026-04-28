# WIZ Framework 개발 인스트럭션

이 문서는 WIZ 프레임워크 기반 프로젝트를 개발할 때 GitHub Copilot Agent가 따라야 할 **핵심 원칙**, **작업 수행 규칙**, **참조 문서 안내**를 정의한다. 세부적인 개발 규칙·코드 패턴·API 레퍼런스는 `.github/devdocs/` 하위 문서에서 관리하며, 이 문서에서는 폴더 단위로 안내한다.

> **Custom Instructions**: `.github/custom/custom-instructions.md`가 존재하면 추가로 참조한다. Custom 문서 내에서 다른 파일을 참조하도록 지시하면 해당 파일도 함께 읽는다. Custom 인스트럭션은 이 문서를 **보완·확장**하며, 충돌 시 Custom이 우선한다.

> **Task 기반 작업 관리**: 사용자가 **"작업 수행해줘"**, **"todo 작업 진행해줘"** 등으로 작업을 지시하면, `.github/task/todo.md`를 읽어 순서대로 수행한다. 상세 규칙은 섹션 4를 참조.

---

## 1. WIZ 개발 프로세스 핵심

### 1.1 아키텍처 원칙

- **계층 분리**: 데이터(Model/Struct) → 전처리(Controller) → API(Route/api.py) → UI(App)를 명확히 분리한다.
- **Struct 패턴**: Model은 Aggregate Root → Sub-Struct 체계로 비즈니스 로직을 캡슐화한다. DB Model은 스키마만 정의.
- **재사용 우선**: 공통 기능은 `src/portal/{package}/`에 패키지로 모듈화한다. 프로젝트 고유 로직만 `src/app/`, `src/model/`에 배치.
- **Service 필수**: 모든 프론트엔드 App에서 `Service`를 주입하고 `ngOnInit`에서 `service.init()` + `service.render()` 호출.

### 1.2 개발 순서

데이터 → 로직 → UI 순서로 구현한다: **DB 설정 → Model/Struct → Layout → Page → 기능 구현 → 빌드**

### 1.3 필수 규칙

- **MCP 도구 최우선**: 앱 생성·파일 읽기/쓰기·빌드 등은 반드시 WIZ MCP 도구를 먼저 사용한다.
- **Source vs Package MCP 구분**: `src/portal/` 하위 파일은 **`wiz_package_*`** 도구를 사용하고, `src/app/`·`src/route/` 등은 **`wiz_source_*`** 도구를 사용한다. 혼용 금지.
- **빌드**: `wiz_project_build`는 `clean: false`(normal)를 기본 사용. 클린 빌드는 사용자가 명시한 경우에만.
- **프로젝트 범위**: 현재 선택된 WIZ 프로젝트만 수정한다. `wiz_workspace_status`로 확인.
- **다른 프로젝트 수정 금지**: `wiz_workspace_status`로 확인한 `currentProject` 외의 프로젝트 디렉토리(`project/{다른이름}/`)는 **읽기·쓰기·복사·삭제 등 일체 금지**한다. 파일 동기화(cp, rsync 등)나 MCP 도구를 통한 다른 프로젝트 접근도 금지. 다른 프로젝트에 동일 변경이 필요하면 사용자에게 프로젝트 전환을 요청한다.
- **config 위치**: `database.py`, `season.py` 등은 `project/{name}/config/`에 작성. `{WIZ_ROOT}/config/`는 수정하지 않는다.
- **Git 작업**: `project/{name}/` 디렉토리에서 수행한다 (프로젝트별 독립 Git 저장소).
- **wiz.response 패턴**: `wiz.response.status()`는 ResponseException으로 즉시 종료한다. `try/except` 안에서 호출하면 안 된다.
- **Pug #ref 규칙**: 템플릿 참조 변수는 반드시 `#ref=""` (빈 문자열 값) 형태로 선언한다.
- **Pug Tailwind 클래스 규칙**: 소수점(`.`)·슬래시(`/`) 포함 Tailwind 클래스(`gap-1.5`, `w-1/2` 등)는 반드시 `class=""` 속성 방식으로 작성한다. dot notation 금지.
- **Pug 멀티라인 속성 규칙**: 첫 속성은 여는 괄호 `(`와 같은 줄에 배치하고, 속성 사이는 콤마(`,`)로 구분한다.
- **wiz.request.query()**: 항상 문자열을 반환한다. 숫자 비교 전에 `int()` 변환 필수.
- **패키지 README.md 필수 참조**: 패키지 라이브러리(model, libs, component 등)를 사용하기 전에 **반드시** 해당 패키지의 `src/portal/{package}/README.md`를 읽고 API 사용법·버전 호환성을 확인한다. devdocs 문서의 예제 코드는 특정 버전 기준이므로, **실제 프로젝트에 설치된 패키지의 README.md가 최종 권위 문서**이다.
- **패키지 버전 안전성**: devdocs 가이드 문서(web-development-guide, wiz-docs)에 포함된 패키지 사용 예제(ORM, Session, Service 등)는 **일반적인 패턴과 구조**를 설명하는 참고 자료이다. 패키지별 세부 API(메서드 시그니처, 파라미터, 반환값 등)는 버전마다 다를 수 있으므로, 반드시 해당 패키지의 `src/portal/{package}/README.md`를 기준으로 구현한다.
- **서버 재시작 금지**: 개발·QA 과정에서 WIZ 서버를 절대 재시작하지 않는다. WIZ는 코드 변경 시 자동 반영(hot-reload)되므로 서버 재실행이 불필요하며, 재시작 시 운영 중인 서비스에 영향을 줄 수 있다.
- **트러블슈팅 참조**: WIZ 프레임워크 고유 이슈(Pug 파싱, `exec()` 환경, SSE Generator 등)는 `devdocs/troubleshooting/README.md`의 카테고리별 문서를 참조한다. 새로운 이슈 발견 시 동일 구조로 등록한다.

---

## 2. Custom Instructions 정책

프로젝트별·환경별 규칙은 `.github/custom/` 디렉토리에 관리한다 (`.gitignore`로 git 미추적).

### 구조

```
.github/custom/
├── custom-instructions.md  # 진입점 (필수)
└── {추가파일}.md            # 참조 파일 섹션에 나열
```

### 참조 규칙

1. 세션 시작 시 `custom-instructions.md` 존재 여부를 확인하고, 있으면 읽는다.
2. "참조 파일" 섹션에 나열된 추가 파일도 함께 읽는다.
3. Custom 규칙은 이 문서를 보완·확장하며, **충돌 시 Custom이 우선**한다.

### 인스트럭션 업데이트 정책

- **"인스트럭션 업데이트"** 요청 → 기본적으로 **커스텀 인스트럭션** 수정.
- **"코어/메인 인스트럭션"**을 명시한 경우에만 → `copilot-instructions.md` 수정.

---

## 3. Devlog (작업 이력 관리)

모든 개발 작업 완료 후 **반드시 devlog를 작성**하여 작업 이력을 남긴다.

### 디렉토리 구조

```
project/{name}/
├── devlog.md                              # 전체 작업 요약 (한 줄씩)
└── devlog/
    └── {YYYY-MM-DD}/                      # 날짜별 폴더
        └── {NNN}-{slug}.md                # 개별 작업 상세 (날짜별 순번)
```

### devlog.md (요약 파일)

```markdown
| 날짜 | ID | 작업 내용 | 상세 |
|------|-----|----------|------|
| 2026-02-19 | 001 | src/model → portal/infra 패키지로 model 이동 | [상세](devlog/2026-02-19/001-model-migration.md) |
```

### 상세 파일 형식

```markdown
# {작업 제목}

- **ID**: {NNN}
- **날짜**: {YYYY-MM-DD}
- **유형**: {리팩토링 | 기능 추가 | 버그 수정 | 문서 업데이트 | 설정 변경}

## 작업 요약
{2~3줄 요약}

## 변경 파일 목록
{카테고리별로 변경 파일과 변경 내용 정리}
```

### 작성 규칙

1. **작업 완료 후 즉시 작성**: devlog.md에 행 추가 + 상세 파일 생성
2. **한 작업 = 한 파일**: 하나의 논리적 작업 단위마다 하나의 상세 파일 생성
3. **순번 결정**: 해당 날짜 폴더 내 기존 파일 개수 + 1
4. **NNN**: 날짜별 3자리 제로패딩 순번 (001, 002, ...). 날짜가 바뀌면 001부터 시작.

---

## 4. Task 기반 작업 관리

사용자가 **"작업 수행해줘"**, **"todo 작업 진행해줘"** 등으로 작업을 지시하면, `.github/task/todo.md`를 읽어 정의된 작업을 순서대로 수행한다.

> ⚠️ **TODO 파일 경로 고정**: `{WIZ_ROOT}/.github/task/todo.md`에 작성한다. 프로젝트 소스 내(`project/{name}/`)나 다른 위치에 생성하지 않는다.

> ⚠️ **"TODO 작성해줘" 명령**: 사용자의 요구사항·설계 문서를 분석하여 **todo.md에 신규 작업 항목만 등록**하고, 실제 개발 작업은 수행하지 않는다.

### 디렉토리 구조

```
.github/task/
├── todo.md              # 작업 목록 (할 일)
├── worked/              # 완료된 작업 아카이브
│   └── FN-20260222-0001.md
└── reviewed/            # 리뷰 완료 후 이동된 아카이브
    └── FN-20260222-0001.md
```

### todo.md 형식

작업은 `#` 헤딩과 **작업 번호** `FN-{YYYYMMDD}-{NNNN}`으로 구분한다.

```markdown
# FN-20260222-0001: Endpoint 설정 / Variables 탭 관련
- endpoint / variables 탭에서 api parameters 설정에서 actions는 고정된 값이니까 토글 형태로 선택하는 UI로 구현

# FN-20260222-0002: API Spec & Test 탭 관련
- API Spec & Test 화면에서 실제 API로 연결해서 결과 확인하도록 구현
```

### 작업 수행 흐름

1. **todo.md 읽기**: 작업 목록 파악
2. **작업 수행**: 번호 순서대로 (또는 사용자가 특정 번호 지정 시 해당 작업만) 수행. 개발 원칙 준수.
3. **각 Task 완료 즉시 정리** (다음 Task로 넘어가기 전에 반드시 수행):
   1. **Devlog 작성**: 섹션 3 규칙에 따라 `devlog.md` 행 추가 + 상세 파일 생성
   2. **worked 아카이브 생성**: `.github/task/worked/{작업번호}.md`에 아래 형식으로 기록
   3. **todo.md 정리**: 완료된 작업 항목을 `todo.md`에서 삭제
   4. **더미 템플릿 유지**: 모든 항목 삭제 시, 마지막 번호의 다음 순번으로 더미 템플릿을 남긴다.

> ⚠️ **즉시 정리 원칙**: 하나의 Task(FN-번호) 완료 후, **반드시 위 3-1 ~ 3-4를 모두 수행한 뒤** 다음 Task로 넘어간다. 여러 Task를 먼저 수행하고 나중에 몰아서 정리하는 것은 **금지**한다. 이는 작업 이력 추적성과 리뷰 정확성을 보장하기 위함이다.

### worked 아카이브 형식

```markdown
# {작업번호}: {작업 제목}

## 작업 지시 원문
{todo.md에 있던 원본 내용 그대로 복사 — 요약·정리하지 않고 원문 보존}

## 수행 내역 요약
{무엇을 어떻게 구현했는지 간결하게 요약}

## 관련 Devlog
- **날짜**: {YYYY-MM-DD}
- **Devlog ID**: {NNN}
- **상세 파일**: `devlog/{YYYY-MM-DD}/{NNN}-{slug}.md`
```

### todo 항목 추가 규칙

1. 기존 작업 번호 확인
2. `FN-{YYYYMMDD}-{NNNN}` 형식으로 생성 (해당 날짜의 마지막 번호 + 1)
3. `# FN-{번호}: {제목}` 헤딩과 하위 항목으로 추가

### 특정 작업 지정 실행

- "FN-20260222-0001 작업 수행해줘" → 해당 번호만 수행
- "todo 1번 작업 진행해줘" → todo.md의 첫 번째 항목 수행
- 번호 미지정 시 → 첫 번째 항목부터 순서대로 (한 번에 하나씩)

### 리뷰 정리 및 TODO 생성

사용자가 **"리뷰 정리해줘"** 등으로 요청하면:

1. **worked 폴더 스캔**: `.github/task/worked/` 내 모든 `.md` 파일을 읽는다.
2. **`# Review` 섹션 확인**: 있는 파일만 처리, 없는 파일은 건드리지 않는다.
3. **TODO 항목 생성**: Review 내용을 정리하여 todo.md에 새 작업 항목으로 추가한다.
4. **reviewed 폴더로 이동**: Review 섹션이 있던 worked 파일을 `.github/task/reviewed/`로 이동한다.
5. **결과 보고**: 처리된 파일 수, 생성된 TODO 항목 수, 스킵된 파일 수를 알린다.

---

## 5. 세부 문서 안내

개발 관련 구체적인 규칙·패턴·API 레퍼런스는 `.github/devdocs/` 하위 폴더에서 관리한다. 각 폴더의 **README.md**를 진입점으로 사용한다.

### `.github/devdocs/instructions/` — 개발 규칙 세부

코어 인스트럭션에서 분리된 세부 개발 규칙. 코드 패턴, 도구 사용법, 프로젝트 구조 등.

- 개발 원칙 (계층분리, Struct 설계, 네이밍, UI 스타일, wiz.response 패턴, Pug 규칙, exec() 제약)
- 개발 워크플로 (작업 순서, 리팩토링 체크리스트, 기능 추가 실전 흐름)
- MCP 도구 사용 가이드 (전체 도구 목록 및 호출법)
- 프로젝트 구조 (디렉토리 트리, App 필수 파일, 아키텍처 흐름)
- API 빠른 참조 (wiz 백엔드 객체, 프론트엔드 Service)
- API 테스트 가이드 (curl, 세션 쿠키, SSE 스트리밍)

### `.github/devdocs/wiz-docs/` — 프레임워크 공식 문서

WIZ 프레임워크 자체에 대한 공식 문서. 아키텍처, 사용 가이드, CLI 명령어, API 레퍼런스.

- 사용 가이드 (설치~배포 전체)
- 아키텍처 (내부 구조, 설계 원칙)
- CLI 명령어 (wiz run, create, build 등)
- API 레퍼런스 (wiz.request, wiz.response, wiz.session, wiz.fs 등)
- 프론트엔드 Service API

> ⚠️ 이 문서들의 패키지 관련 예제(ORM, Session, Service 등)는 **일반적인 사용 패턴**만 참고한다. 실제 API 세부 사항은 해당 패키지의 `src/portal/{package}/README.md`를 기준으로 한다.

### `.github/devdocs/web-development-guide/` — 실무 웹 개발 가이드

Source 구성요소(App, Controller, Model, Route 등)와 Packages 구성요소의 실무 개발 가이드.

- **1-source/**: App, Controller, Model, Route, Angular, Assets, Routing, Socket 가이드
- **2-packages/**: 패키지 App, Controller, Model, Route, Libs, Styles, Assets 가이드

> ⚠️ 이 문서들의 패키지별 코드 예제는 **구조와 패턴 이해용**이다. 패키지 세부 API(메서드, 파라미터, 컴포넌트 속성 등)는 버전에 따라 변경될 수 있으므로, 반드시 해당 패키지의 `src/portal/{package}/README.md`를 먼저 확인한다.

### `.github/devdocs/troubleshooting/` — 트러블슈팅 가이드

WIZ 프레임워크 고유 이슈를 **시스템 아키텍처 레벨**로 분류하여 관리한다.

- **web-ui/**: 프론트엔드 빌드·렌더링 이슈 (`pug/`, `angular/`, `typescript/`)
- **server-side/**: 백엔드 런타임 이슈 (`python-runtime/`, `api/`, `build/`)

> 새로운 이슈 발견 시 README.md의 **작성 요령**(템플릿, 카테고리 분류, 등록 체크리스트)을 따라 등록한다.

#### 트러블슈팅 정리 워크플로

사용자가 **"트러블슈팅 정리해줘"** 등으로 요청하면 아래 순서로 수행한다:

1. **전수조사**: 커스텀 인스트럭션(`.github/custom/`)·코어 인스트럭션(`.github/copilot-instructions.md`)·devdocs 전체·소스코드를 스캔하여 트러블슈팅 관련 콘텐츠를 수집한다.
2. **계획 수립**: 발견된 이슈를 분류하고 `devdocs/troubleshooting/plan.md`에 작업 계획을 정리한다 (신규 등록·기존 중복 정리·참조 링크 추가 등).
3. **순차 실행**: `plan.md`를 읽어 항목별로 순서대로 수행한다.
4. **인덱싱 갱신**: 작업 완료 후 `troubleshooting/README.md` 및 관련 인덱스 문서(devdocs/README.md, instructions/README.md 등)를 **전체 확인·갱신**한다. 전수조사 과정에서 다른 문서에서 삭제·이동된 내용이 있을 수 있으므로 인덱스 정합성을 반드시 검증한다.
5. **plan.md 삭제**: 모든 항목 완료 후 `plan.md`를 삭제한다.

### `.github/devdocs/feature-guide/` — 기능 단위 개발 가이드

기능(Feature) 단위의 아키텍처 설계 및 구현 가이드. 사용자가 특정 기능 개발을 요청하면 해당 가이드를 참조하여 일관된 아키텍처로 구현한다.

- **session-auth.md**: 세션 기반 인증 (로그인/로그아웃, 세션 DB 관리, 다중 기기 로그아웃, 접속 로그, SAML SSO)

> **사용 시점**: 사용자가 "로그인 기능 만들어줘", "인증 시스템 구현해줘", "게시판 만들어줘" 등 **기능 단위** 개발을 요청할 때 해당 가이드의 아키텍처·DB 스키마·구현 체크리스트를 따른다.
