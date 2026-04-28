# WIZ Project - Codex Agent Instructions

이 문서는 WIZ(Season) 프레임워크 프로젝트 루트에 두는 범용 `AGENTS.md`이다. 특정 서비스나 저장소 이름에 묶이지 않고, 새 WIZ 프로젝트를 만들거나 기존 WIZ 프로젝트를 수정할 때 공통으로 적용한다.

작업 전 반드시 현재 WIZ workspace와 활성 프로젝트를 확인한다. 실제 수정 대상은 `wiz_workspace_status`가 알려주는 `currentProject`이며, 다른 프로젝트 디렉토리는 사용자가 명시적으로 전환을 요청하기 전까지 수정하지 않는다.

---

## 작업 시작 규칙

1. `wiz_workspace_status`로 workspace root와 `currentProject`를 확인한다.
2. 프로젝트에 `.github/custom/custom-instructions.md`가 있으면 먼저 읽는다. 참조 파일이 있으면 함께 읽고, 충돌 시 custom 규칙을 우선한다.
3. 프로젝트에 `.github/copilot-instructions.md`, `.github/short-instructions.md`, `.github/devdocs/**`가 있으면 해당 프로젝트 문서를 우선한다.
4. 프로젝트 문서가 없거나 부족하면 설치된 범용 WIZ 문서인 `${CODEX_HOME:-~/.codex}/ecc-assets/github/**`를 기준으로 삼는다.
5. 앱 생성, 파일 읽기/쓰기, 빌드, 상태 확인은 WIZ MCP 도구를 우선 사용한다.

## 프로젝트 경계

- 현재 프로젝트 경로는 `project/{currentProject}/`이다.
- `project/{currentProject}/src/app/**`, `src/controller/**`, `src/model/**`, `src/route/**`는 Source 영역이다.
- `project/{currentProject}/src/portal/{package}/**`는 Package 영역이다.
- `project/{currentProject}/config/**`는 프로젝트 설정 영역이다.
- workspace 루트의 `config/`, `public/`, `ide/`, `plugin/` 등 프레임워크/IDE 영역은 사용자가 명시하지 않으면 수정하지 않는다.
- `project/{다른이름}/`은 읽기, 쓰기, 복사, 삭제 모두 금지한다.

## MCP 도구 선택

| 대상 | 사용할 도구 |
|------|-------------|
| workspace 상태, 프로젝트 목록 | `wiz_workspace_*` |
| `project/{currentProject}/config`, `src/angular`, `src/assets`, 빌드 | `wiz_project_*` |
| `src/app`, `src/controller`, `src/model`, `src/route` | `wiz_source_*` |
| `src/portal/{package}` | `wiz_package_*` |

`src/portal/**` 파일에 `wiz_source_*`를 쓰지 않고, Source 파일에 `wiz_package_*`를 쓰지 않는다.

## 개발 순서

데이터와 도메인 구조를 먼저 잡고 UI를 붙인다.

1. DB/config 필요 여부 확인
2. Model/Struct 설계
3. Controller/Route/API 설계
4. Layout/Page/Component 생성
5. view.ts/view.pug/view.scss 구현
6. 빌드 및 검증

공통 기능은 `src/portal/{package}/`로 분리하고, 프로젝트 고유 기능만 Source 영역에 둔다.

## 백엔드 규칙

- DB Model은 스키마와 ORM 연결만 담당한다.
- 비즈니스 로직은 Struct, api.py, route 계층에 둔다.
- `wiz.response.status()`와 redirect 계열은 성공 경로의 `try` 블록 안에서 호출하지 않는다.
- `wiz.request.query()`는 문자열을 반환하므로 숫자 비교 전 `int()` 등으로 변환한다.
- JSON body를 직접 받을 때는 `wiz.request.query()`가 파싱하지 못할 수 있으므로 요청 형식과 파싱 방식을 확인한다.
- `except:` 같은 bare except를 쓰지 않는다.
- 권한 검증에서 `role not in "admin"` 같은 문자열 포함 비교를 쓰지 않는다.
- config 파일에서 DB 쿼리나 무거운 런타임 작업을 하지 않는다.

## 프론트엔드 규칙

- 모든 Page/Layout/Component는 프로젝트 Service 패턴을 따른다.
- 초기화 시 `service.init()`과 `service.render()` 호출 필요 여부를 확인한다.
- 상태 변경 후 UI 갱신이 필요하면 `service.render()`를 호출한다.
- `wiz.call()`은 현재 App 자신의 `api.py` 함수만 호출한다.
- Portal App이 부모 Page의 `api.py`를 호출한다고 가정하지 않는다.
- Angular 라우팅 파라미터 변경 시 컴포넌트 재사용을 고려한다.
- Page/Layout의 `view.scss`에는 `:host` 레이아웃 규칙을 둔다.

## Pug와 스타일 규칙

- Angular 템플릿 참조 변수는 `#ref=""`처럼 빈 문자열 값을 명시한다.
- Tailwind 클래스에 소수점이나 슬래시가 있으면 Pug dot notation 대신 `class=""` 속성을 사용한다.
- Pug 멀티라인 속성은 첫 속성을 여는 괄호와 같은 줄에 둔다.
- flex column 안의 스크롤 영역에는 `min-h-0`을 고려한다.
- 패키지 스타일을 추가하면 `src/angular/styles/styles.scss` import 체인을 확인한다.

## Package 규칙

- `src/portal/{package}/README.md`가 있으면 generic devdocs보다 해당 README를 최종 권위로 본다.
- 패키지 API, libs, model, component, style을 바꾸면 README 갱신 필요 여부를 확인한다.
- `portal.json` metadata가 필요한 구성요소를 추가/삭제하면 함께 갱신한다.
- Package 파일은 `wiz_package_*`로 다룬다.

## 빌드 규칙

- 기본 빌드는 `wiz_project_build`의 normal build를 사용한다.
- 새 API 함수 추가, API 함수 삭제, API 함수 이름 변경은 clean build가 필요하다.
- `socket.py` 추가/수정은 WIZ 문서의 재시작 요구를 확인하되, 서버 재시작은 parent agent와 사용자 승인 없이 수행하지 않는다.
- `build/`, `bundle/` 등 산출물은 직접 편집하지 않는다.

## 트러블슈팅 우선순위

1. WIZ MCP 상태와 `currentProject` 확인
2. Source/Package 도구 경계 확인
3. Pug 문법, Tailwind class 표현, `#ref=""` 확인
4. `wiz.response.status()` 위치 확인
5. 새 API 함수 여부와 clean build 필요성 확인
6. package README와 styles import 확인
7. 로그와 빌드 에러의 실제 파일 경로 확인

## Task 처리

- 프로젝트에 `.github/task/todo.md`가 있고 사용자가 작업 수행을 요청하면 해당 파일의 작업을 순서대로 처리한다.
- 사용자가 명시하지 않은 별도 작업 파일이나 보고서를 만들지 않는다.
