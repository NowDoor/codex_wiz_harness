# WIZ Framework 개발 인스트럭션

이 문서는 WIZ 프레임워크 기반 프로젝트를 개발할 때 GitHub Copilot Agent가 따라야 할 **핵심 원칙**, **코드 패턴**, **API 레퍼런스**, **트러블슈팅**을 정의한다. 모든 개발 규칙과 참조 정보를 이 문서에 인라인으로 포함하여, 외부 문서 참조 없이 즉시 개발할 수 있도록 한다.

> **Custom Instructions**: `.github/custom/custom-instructions.md`가 존재하면 추가로 참조한다. Custom 문서 내에서 다른 파일을 참조하도록 지시하면 해당 파일도 함께 읽는다. Custom 인스트럭션은 이 문서를 **보완·확장**하며, 충돌 시 Custom이 우선한다.

> **Task 기반 작업 관리**: 사용자가 **"작업 수행해줘"**, **"todo 작업 진행해줘"** 등으로 작업을 지시하면, `.github/task/todo.md`를 읽어 순서대로 수행한다. 상세 규칙은 섹션 9를 참조.

---

## 1. 프로젝트 구조

### 1.1 루트 디렉토리

```
{WIZ_ROOT}/
├── config/              # 프레임워크 config (boot.py, service.py — 수정 금지)
├── public/              # 앱 엔트리포인트 (app.py)
├── project/             # 프로젝트 디렉토리
│   ├── main/            # 운영 프로젝트
│   ├── dev/             # 개발 프로젝트
│   └── {name}/          # 추가 프로젝트
├── ide/                 # WIZ IDE 소스
├── plugin/              # 플러그인
└── .github/             # 개발 문서 및 인스트럭션
```

### 1.2 Source 디렉토리 (`project/{name}/src/`)

```
src/
├── app/                     # Angular App
│   ├── page.{name}/        # 페이지 (URL 라우팅 가능)
│   ├── layout.{name}/      # 레이아웃 (router-outlet 포함)
│   └── component.{name}/   # 재사용 UI 컴포넌트
├── controller/              # 백엔드 전처리 (인증/권한 체인)
├── model/                   # 프로젝트 고유 Model (db/, struct.py, struct/)
├── route/                   # REST API 라우트
├── portal/                  # Packages (재사용 모듈)
│   └── {package}/
│       ├── portal.json     # 패키지 메타데이터 (use_model 등 플래그)
│       ├── README.md       # 패키지 API 문서 (최종 권위 문서)
│       ├── app/            # 패키지 App (component)
│       ├── controller/     # 패키지 Controller
│       ├── model/          # 패키지 Model (db/, struct/)
│       │   ├── db/         # DB Model (Peewee 테이블 스키마)
│       │   └── struct/     # Struct (비즈니스 로직)
│       ├── route/          # 패키지 Route
│       ├── libs/           # TS/JS 라이브러리
│       ├── styles/         # SCSS 스타일
│       └── assets/         # 정적 자산
├── angular/                 # Angular 빌드 설정
└── assets/                  # 정적 자산
```

### 1.3 App 필수 파일

| 파일 | 역할 | 필수 |
|------|------|------|
| `app.json` | 메타데이터 (mode, id, viewuri, layout, controller) | ✅ |
| `view.ts` | TypeScript 로직 (Angular Component) | ✅ |
| `view.pug` | Pug 템플릿 (HTML 렌더링) | ✅ |
| `view.scss` | 스타일시트 | 선택 |
| `api.py` | 백엔드 API (wiz.call로 호출) | 선택 |
| `socket.py` | WebSocket 핸들러 | 선택 |

### 1.4 핵심 아키텍처 흐름

```
클라이언트 요청
    → Controller (인증/권한/전처리: base → user → admin 체인)
        → App (view.ts + view.pug ↔ api.py)
            → Struct (비즈니스 로직)
                → DB Model (ORM CRUD)
                    → Database
    ← wiz.response.status(200, data) 반환
```

---

## 2. 아키텍처 원칙

### 2.1 관심사 분리 (Separation of Concerns)

- **데이터 계층(Model/Struct)**, **전처리 계층(Controller)**, **API 계층(Route/api.py)**, **UI 계층(App)** 을 명확히 분리한다.
- 각 계층은 자신의 책임만 수행하며, `wiz.model()`, `wiz.controller()` 등의 인터페이스를 통해 연결한다.
- UI(view.ts/view.pug)에 비즈니스 로직을 넣지 않는다. 비즈니스 로직은 반드시 Model/Struct 또는 api.py에 위치한다.

### 2.2 단일 책임 원칙

- 하나의 파일/클래스는 하나의 명확한 역할만 담당한다.
- Model 파일이 300줄을 넘기면 Struct 패턴으로 하위 도메인을 분리한다.
- Controller는 인증/권한 검증만 담당하고, 데이터 처리 로직은 Model에 위임한다.

### 2.3 재사용성: Packages(Portal) 우선

- 여러 페이지에서 공통으로 사용하는 Model, Component, 라이브러리는 `src/portal/{package}/`에 패키지로 모듈화한다.
- 프로젝트 고유 로직만 `src/app/`에 직접 배치한다.
- 패키지 model 호출: `wiz.model("portal/{package}/{name}")`
- 패키지 lib 임포트: `import { Service } from '@wiz/libs/portal/{package}/{name}'`
- **패키지 README.md 참조 필수**: 패키지 라이브러리(libs, model, component 등)를 사용하기 전에 **반드시** 해당 패키지의 `src/portal/{package}/README.md`를 읽고 API 사용법·버전 호환성을 확인한다. devdocs 문서의 예제 코드는 특정 버전 기준이므로, **실제 프로젝트에 설치된 패키지의 README.md가 최종 권위 문서**이다.

### 2.4 개발 순서

데이터 → 로직 → UI 순서로 구현한다:

1. **DB 설정**: `config/database.py`에 namespace별 접속 정보 추가
2. **Model/Struct**: DB Model(테이블 스키마) → Struct(비즈니스 로직) 구현
3. **Layout 구조** (필요시): `src/app/layout.{name}/` 에 Layout App 생성, `router-outlet` 포함
4. **URI 설계 및 Page 생성**: URL 구조 설계 → `src/app/page.{name}/` 생성, app.json 설정
5. **기능 구현**: view.ts/view.pug UI 구현, api.py 백엔드 함수 작성, Route 생성
6. **빌드**: `wiz_project_build`로 빌드 (기본 `clean: false`)

---

## 3. Model 표준화: Struct 구조 설계

### 3.1 Struct 개념

Struct는 **DB Model(테이블 스키마)을 조합하여 비즈니스 로직을 캡슐화하는 계층**이다.

```
┌─ DB Model (portal/{pkg}/model/db/*.py)
│   └─ 테이블 스키마 정의 (Peewee ORM)
│   └─ ORM Wrapper (orm.use()) 로 CRUD 수행
│
├─ Struct (portal/{pkg}/model/struct/*.py)
│   └─ Aggregate Root: 도메인 엔터티의 진입점
│   └─ Sub-Struct: 하위 도메인
│   └─ Composite Struct: 여러 Sub-Struct를 조립
│
└─ 호출 흐름: api.py/route → Struct → DB Model → Database
```

### 3.2 Aggregate Root 패턴

```python
# portal/works/model/project.py - Aggregate Root
class Project:
    def __init__(self, data):
        self.id = data['id']
        self.data = data
        self.member = Member(self)      # Sub-Struct
        self.plan = Plan(self)          # Sub-Struct
    
    @staticmethod
    def get(namespace):
        data = projectdb.get(namespace=namespace)
        return Project(data)
    
    @staticmethod
    def create(): ...
    @staticmethod
    def search(): ...

Model = Project
```

### 3.3 Sub-Struct 패턴

```python
# portal/works/model/struct/member.py - Sub-Struct
class Member:
    def __init__(self, project):
        self.project = project
        self.project_id = project.data['id']
    
    def accessLevel(self, allowed):
        auth = self.auth()
        if auth in allowed: return True
        raise Exception("Not Allowed")

Model = Member
```

### 3.4 Composite Struct 패턴

```python
# portal/{pkg}/model/struct.py - Composite Struct (싱글톤)
class Struct:
    def __init__(self):
        self.orm = wiz.model("portal/{pkg}/orm")
        self.session = wiz.model("portal/{pkg}/session").use()
        self._Post = wiz.model("portal/{pkg}/struct/post")

    def db(self, name):
        return self.orm.use(name, module="{pkg}")

    @property
    def post(self):
        """Sub-Struct 접근 (호출마다 새 인스턴스)"""
        return self._Post(self)

Model = Struct()  # 싱글톤
```

### 3.5 src/model에서 패키지 Struct 호출

`src/model/struct.py`는 프로젝트 고유 Sub-Struct를 관리하면서, `__getattr__`를 통해 패키지 Struct에 동적으로 접근할 수 있다.

```python
# src/model/struct.py
class Struct:
    def __init__(self):
        self.orm = wiz.model("portal/{pkg}/orm")
        self._User = wiz.model("struct/user")
        self._packages = {}

    @property
    def user(self):
        return self._User(self)

    def __getattr__(self, name):
        if name.startswith('_'):
            raise AttributeError(name)
        if name not in self._packages:
            try:
                self._packages[name] = wiz.model(f"portal/{name}/struct")
            except Exception:
                raise AttributeError(f"Package '{name}' not found")
        return self._packages[name]

Model = Struct()
```

### 3.6 `Model` 변수 필수

모든 model 파일은 반드시 `Model` 변수를 정의한다:
- **클래스 반환**: `Model = ClassName` (호출 시마다 새 인스턴스 생성)
- **인스턴스 반환**: `Model = ClassName()` (싱글톤, Session·Config 등)

### 3.7 DB Model은 스키마만

```python
# portal/{pkg}/model/db/project.py
import peewee as pw
orm = wiz.model("portal/{pkg}/orm")
base = orm.base("{namespace}")

class Model(base):
    class Meta:
        db_table = "project"
    id = pw.CharField(max_length=32, primary_key=True)
    namespace = pw.CharField(max_length=32, unique=True)
    title = pw.CharField(max_length=64)
    status = pw.CharField(max_length=16, index=True)
```

### 3.8 ORM Wrapper 활용

```python
orm = wiz.model("portal/{pkg}/orm")
db = orm.use("project", module="{pkg}")   # module 파라미터 필수
db.get(id=id)                             # 단건 조회
db.rows(status="open", page=1)           # 목록 (페이징, 정렬, LIKE)
db.count(status="open")                  # 카운트
db.insert(data)                          # 삽입 (자동 ID 생성)
db.update(data, id=id)                   # 수정
db.delete(id=id)                         # 삭제
db.upsert(data, keys="id")               # Upsert
```

> ⚠️ ORM의 `base()`, `use()` 등 메서드 시그니처는 패키지 버전에 따라 다를 수 있다. 반드시 해당 패키지의 `README.md`를 확인한다.

---

## 4. 필수 규칙

### 4.1 MCP 도구 최우선

- 앱 생성·파일 읽기/쓰기·빌드 등은 반드시 WIZ MCP 도구를 먼저 사용한다.
- 파일시스템 직접 접근(`create_file`, `replace_string_in_file` 등)은 MCP로 처리할 수 없는 경우에만 사용한다.

### 4.2 Source vs Package MCP 구분

`src/portal/` 하위 파일은 **`wiz_package_*`** 도구를 사용하고, `src/app/`·`src/route/` 등은 **`wiz_source_*`** 도구를 사용한다. 혼용 금지.

| 대상 경로 | 사용할 도구 | 예시 |
|-----------|------------|------|
| `src/app/{appName}/` | `wiz_source_*` | `wiz_source_read_file`, `wiz_source_write_file` |
| `src/route/{routeName}/` | `wiz_source_*` | `wiz_source_read_file`, `wiz_source_create_route` |
| `src/portal/{package}/**` | `wiz_package_*` | `wiz_package_read_file`, `wiz_package_write_file` |
| `src/model/`, `src/controller/` | `wiz_source_*` | `wiz_source_list_controllers` |
| `src/angular/`, `src/assets/` | `wiz_project_*` | `wiz_project_read_file` |
| `config/`, 프로젝트 루트 파일 | `wiz_project_*` | `wiz_project_read_file` |

**판단 기준**: `appPath` 파라미터가 `portal/` 접두사로 시작하면 → Package 도구, 그 외 → Source 도구.

### 4.3 빌드 규칙

- `wiz_project_build`는 `clean: false`(normal)를 기본 사용.
- 클린 빌드(`clean: true`)는 사용자가 명시한 경우 또는 **새 API 함수 추가/삭제/이름 변경** 시에만.
- `src/model/` 디렉토리는 반드시 존재해야 한다. 삭제하면 빌드 실패.
- `build/`, `bundle/` 디렉토리는 빌드 산출물이므로 수동 편집하지 않는다.

| 변경 유형 | 필요한 빌드 |
|-----------|------------|
| 기존 함수 내용 수정 | 일반 빌드 (`clean: false`) |
| 새 함수 추가 | **클린 빌드** (`clean: true`) |
| 함수 삭제/이름 변경 | **클린 빌드** (`clean: true`) |
| socket.py 추가/수정 | **클린 빌드** + `wiz service restart` 필수 |

### 4.4 프로젝트 범위

- **현재 선택된 WIZ 프로젝트만 수정**한다. `wiz_workspace_status`로 확인.
- **다른 프로젝트 수정 금지**: `currentProject` 외의 프로젝트 디렉토리(`project/{다른이름}/`)는 **읽기·쓰기·복사·삭제 등 일체 금지**한다. 파일 동기화(cp, rsync 등)나 MCP 도구를 통한 다른 프로젝트 접근도 금지. 다른 프로젝트에 동일 변경이 필요하면 사용자에게 프로젝트 전환을 요청한다.
- **config 위치**: `database.py`, `season.py` 등은 `project/{name}/config/`에 작성. `{WIZ_ROOT}/config/`는 수정하지 않는다.
- **Git 작업**: `project/{name}/` 디렉토리에서 수행한다 (프로젝트별 독립 Git 저장소).

### 4.5 wiz.response 예외 기반 종료 패턴 (중요)

`wiz.response.status()`, `wiz.response.redirect()` 등은 **`ResponseException`을 raise하여 즉시 종료**한다. `try/except Exception` 안에서 호출하면 정상 응답까지 catch되므로, **`wiz.response`는 반드시 `try` 블록 바깥에서 호출**한다.

```python
# ❌ 성공 응답(200)도 except로 빠짐
def create():
    try:
        result = struct.something.create(data)
        wiz.response.status(200, result)   # ResponseException → except로 이동
    except Exception as e:
        wiz.response.status(400, message=str(e))

# ✅ wiz.response를 try 바깥에서 호출
def create():
    data = wiz.request.query("data", True)
    try:
        result = struct.something.create(data)
    except Exception as e:
        wiz.response.status(400, message=str(e))
    wiz.response.status(200, result)
```

- **`try` 블록 안에서 절대 호출하지 않는다** (에러 핸들링용 except 안에서만 허용)
- `except` 안의 `wiz.response.status(400, ...)` — 이것은 에러 응답이므로 괜찮음 (어차피 종료)

### 4.6 Pug 템플릿 규칙

#### #ref 빈 문자열 필수

Pug에서 Angular 템플릿 참조 변수는 반드시 `#ref=""` (빈 문자열 값) 형태로 선언한다. 값 없이 `#ref`만 쓰면 Pug가 `#ref="#ref"`로 변환하여 Angular NG0301 에러 발생.

```pug
//- ❌ Pug가 #monacoContainer="#monacoContainer"로 변환 → NG0301
div(#monacoContainer, class="w-full h-full")

//- ✅ 빈 문자열 값 명시 → 정상 참조
div(#monacoContainer="", class="w-full h-full")
ng-template(#treeNode="", let-item="item")
```

#### Tailwind 소수점/슬래시 클래스

소수점(`.`) 또는 슬래시(`/`)를 포함하는 Tailwind 클래스는 반드시 `class=""` 속성 방식으로 작성한다.

```pug
//- ❌ 빌드 실패 — Pug가 .gap-1 과 .5 를 별개 클래스로 파싱
div.gap-1.5.p-2

//- ✅ class 속성 방식
div(class="gap-1.5 p-2")
div.flex.items-center(class="gap-1.5 p-2.5")
```

| 클래스 패턴 | 예시 | 방식 |
|-------------|------|------|
| 소수점 포함 | `gap-1.5`, `p-2.5` | `class=""` 필수 |
| 슬래시 포함 | `bg-black/50`, `w-1/2` | `class=""` 필수 |
| 단순 하이픈 | `flex`, `items-center` | dot notation 가능 |

#### 멀티라인 속성 규칙

첫 속성은 반드시 여는 괄호 `(`와 같은 줄에 배치하고, 속성 사이는 콤마(`,`)로 구분한다.

```pug
//- ❌ 파싱 실패 — 첫 속성이 다음 줄
div(
  *ngIf="condition"
)

//- ✅ 첫 속성을 괄호와 같은 줄에
div(*ngIf="condition",
  class="flex items-center",
  (click)="onClick()")
```

### 4.7 wiz.request.query() 타입 안전성

- 항상 **문자열**을 반환한다. 숫자 비교 전에 **반드시 `int()` 로 변환**한다.
- `wiz.request.query()`는 **form-urlencoded와 query string만 파싱**한다. JSON body (`Content-Type: application/json`)는 파싱하지 않으므로, 직접 fetch() 호출 시 반드시 `FormData` 또는 `URLSearchParams`를 사용한다. `wiz.call()`은 내부적으로 form-urlencoded를 사용하므로 이 문제가 없다.

```python
page = int(wiz.request.query("page", 1))
dump = int(wiz.request.query("dump", 20))
```

### 4.8 서버 재시작 금지

개발·QA 과정에서 WIZ 서버를 절대 재시작하지 않는다. WIZ는 코드 변경 시 자동 반영(hot-reload)되므로 서버 재실행이 불필요하며, 재시작 시 운영 중인 서비스에 영향을 줄 수 있다.

### 4.9 Config 파일에 DB 쿼리 금지

`config/season.py`, `config/works.py`, `config/wiki.py` 등 config 파일은 **매 요청마다 로드**된다. config 파일 내에서 `wiz.model()`로 DB Model을 로드하거나 ORM 쿼리를 실행하면 요청마다 새 DB 커넥션이 생성되어 **커넥션 풀 고갈**(MySQL `Too many connections`)을 유발한다. Config override 등 DB 기반 설정은 반드시 API 레벨에서 처리한다.

### 4.10 예외 처리 규칙

- **`bare except` 금지**: `except:` (타입 없는 except)는 `SystemExit`, `KeyboardInterrupt`, `ResponseException` 등까지 잡으므로, 반드시 `except Exception as e:` 또는 더 구체적인 예외 타입을 사용한다.
- **권한 비교 시 `in` 문자열 연산 금지**: `role not in 'admin'`은 부분 문자열 검사이므로 `'a'`, `'d'` 등 한 글자 role로 우회 가능. 반드시 `!=`(동등 비교) 또는 리스트 `not in ['admin']`을 사용한다.

### 4.11 Config 함수명·키 네이밍 일치

`config/season.py`에 커스텀 함수/변수를 정의할 때, 해당 값을 소비하는 패키지 코드의 **DEFAULT_VALUES 키 네이밍과 정확히 일치**해야 한다. 키 불일치 시 `None`이 반환되며 에러 로그 없이 기능이 실패한다(무음 실패). `stdClass(None)` 생성 시 `TypeError` 발생 가능.

```python
# ❌ 키 불일치 — 패키지는 auth_saml_acs를 기대
def saml_acs(response): ...

# ✅ 정확한 키 네이밍
def auth_saml_acs(response): ...
```

---

## 5. 프론트엔드 개발 규칙

### 5.1 Service 필수 사용

모든 App(Page/Layout/Component)의 `view.ts`에서 프로젝트의 공통 `Service`를 주입하고 `ngOnInit`에서 초기화한다.

```typescript
import { OnInit } from '@angular/core';
import { Service } from '@wiz/libs/portal/{package}/service';

export class Component implements OnInit {
    constructor(public service: Service) { }
    public async ngOnInit() {
        await this.service.init();
        await this.service.render();
    }
}
```

> ⚠️ `{package}`는 프로젝트에서 사용하는 실제 패키지명으로 대체한다. Service의 세부 API는 패키지별로 다를 수 있으므로, 반드시 `src/portal/{package}/README.md`를 확인한다.

### 5.2 API 호출 (wiz.call)

App 내 api.py의 함수는 `wiz.call("함수명", data)` 로 호출한다 (view.ts 내 전역 `wiz` 객체 사용).

```typescript
let res = await wiz.call("search", { page: 1, text: "" });
// res.code: HTTP 상태코드, res.data: 응답 데이터
```

> ⚠️ **라우팅 스코프**: `wiz.call()`은 **현재 App 자신의 `api.py`** 에서만 함수를 찾는다. Portal App이 Page 안에 태그로 삽입되어 렌더링되더라도, 부모 Page의 `api.py`는 호출되지 않는다. Portal App에서 `wiz.call()`을 사용하려면 **해당 Portal App 폴더에 자체 `api.py`를 생성**해야 한다.

### 5.3 View Routing (Angular 라우팅) 규칙

WIZ는 Angular의 표준 `path` 매칭 대신 **`URLPattern` 기반 커스텀 matcher**를 사용한다.

- `viewuri`의 `:param` 세그먼트는 기본적으로 **필수**. 세그먼트가 URL에 없으면 매칭 안 됨.
- **옵셔널 세그먼트**: `:param?`(물음표 접미사)를 사용.
- 매칭된 세그먼트는 `WizRoute.segment` 객체로 접근.
- **리다이렉트 전용 앱은 만들지 않는다**. URLPattern 옵셔널 문법과 view.ts 내 기본값 처리로 대체.
- **`ngDoCheck` 사용 금지**: 매 Change Detection 사이클마다 실행되어 심각한 성능 저하 유발. 탭 전환 감지는 반드시 `Router.events`의 `NavigationEnd` 구독으로 처리한다.

```json
// app.json — :tab? 는 옵셔널
{ "viewuri": "/project/:id/:tab?" }
```

```typescript
// view.ts — tab 없으면 기본값으로 리다이렉트
if (!WizRoute.segment.tab) {
    this.service.href(`/project/${this.id}/info`);
    return;
}
```

#### Angular 컴포넌트 재사용과 탭 전환

Angular Router는 URL 파라미터만 변경될 때 같은 컴포넌트를 재사용한다 (ngOnInit 재호출 안 됨). `Router.events`의 `NavigationEnd`를 구독하여 탭 전환을 감지한다.

```typescript
import { Router, NavigationEnd } from '@angular/router';

this.routerSub = this.router.events.subscribe(async (event) => {
    if (event instanceof NavigationEnd) {
        const newTab = WizRoute.segment.tab || 'info';
        if (newTab !== this.tab) {
            this.tab = newTab;
            await this.service.render();
        }
    }
});
ngOnDestroy() { if (this.routerSub) this.routerSub.unsubscribe(); }
```

### 5.4 Flex 컨테이너 스크롤 영역 규칙

`flex` + `flex-col` 레이아웃에서 스크롤 가능한 자식에 반드시 **`min-h-0`** 을 명시한다.

```pug
div(class="flex-1 min-h-0 overflow-hidden")
    div(class="w-full h-full overflow-auto") ...
```

### 5.5 App 네이밍 규칙

폴더명은 `{appType}.{viewuri 세그먼트를 .으로 연결}` 형태:

```
viewuri: /admin/deploy       → page.admin.deploy
viewuri: /project/:id/:tab   → page.project.item
```

| 필드 | 규칙 | 예시 |
|------|------|------|
| `id` | 폴더명과 **동일** | `page.admin.deploy` |
| `namespace` | 폴더명에서 `{appType}.` 접두사 제거 | `admin.deploy` |
| `title` | **viewuri와 동일** | `/admin/deploy` |
| `mode` | 앱 타입 | `page`, `layout`, `component` |

### 5.6 UI 스타일 가이드 (Tailwind CSS)

| 용도 | Tailwind 클래스 |
|------|-----------------|
| 페이지 제목 (h1) | `text-lg font-semibold text-zinc-950` |
| 섹션 제목 | `text-[15px] font-semibold` |
| 본문/테이블/버튼/입력 | `text-[13px]` |
| 보조 텍스트/배지 | `text-xs` |
| 페이지 제목 옆 아이콘 | `size-6` |
| 사이드바/버튼 내 아이콘 | `size-4` |

### 5.8 Angular 컴포넌트 :host 스타일 필수

Angular 컴포넌트의 호스트 요소(`<wiz-page-xxx>`)는 기본적으로 `display: inline`이며 높이가 없다. 자식에 `h-full`을 써도 부모(호스트)에 높이가 없으므로 resolve 불가. 모든 **Page/Layout App**의 `view.scss`에 `:host` 블록을 필수 선언한다.

```scss
// Page — 기본 패턴
:host { display: block; height: 100%; }

// Layout — flex 패턴
:host { display: flex; flex-direction: column; height: 100%; }
```

### 5.9 styles.scss 패키지 @import 필수

패키지 스타일(`src/portal/{package}/styles/`)은 `src/angular/styles/styles.scss`에서 `@import`하지 않으면 **빌드 번들에 포함되지 않는다**. 새 패키지 스타일 추가 시 반드시 `styles.scss`의 import 체인을 확인한다.

```scss
// src/angular/styles/styles.scss
@import "portal/season/core";    // ✅ season 패키지 스타일 포함
@import "portal/works/core";     // ✅ works 패키지 스타일 포함
```

> 검증: `grep -c "셀렉터" project/{name}/bundle/www/main.css` — 0이면 import 누락.

### 5.10 Socket.IO 실시간 통신

App 폴더에 `socket.py`를 추가하면 해당 App 전용 Socket.IO 네임스페이스(`/wiz/app/{project}/{app_id}`)가 자동 등록된다. **`socket.py` 추가/수정 후에는 빌드 + `wiz service restart` 필수**.

```python
# socket.py — Controller 클래스 정의
class Controller:
    def __init__(self, server):
        self.server = server

    def connect(self): pass

    def disconnect(self, flask, io):
        sid = flask.request.sid

    def join(self, data, io):
        io.join(data)

    def leave(self, data, io):
        io.leave(data)

    def custom_event(self, data, io, wiz):
        io.emit("response", {"message": "received"})
```

**사용 가능한 파라미터**: `server`, `wiz`, `socketio`, `flask_socketio`, `flask`, `io` (SocketHandler), `data`

**io API**: `io.emit(event, data, to=, room=, broadcast=)`, `io.join(room)`, `io.leave(room)`, `io.clients(room)`, `io.rooms()`

**프론트엔드 연결**:
```typescript
this.socket = this.service.socket.create();
this.socket.on("response", (data) => { ... });
this.socket.emit("custom_event", { ... });
ngOnDestroy() { if (this.socket) this.socket.disconnect(); }
```

---

## 6. 백엔드 개발 규칙

### 6.1 Controller 체계

```
base.py (최상위) → 세션 초기화
    ↑
user.py (로그인 필수) → 인증 + 세션 검증
    ↑
admin.py (관리자 전용) → 권한 검증
```

```python
# src/controller/base.py
class Controller:
    def __init__(self):
        wiz.session = wiz.model("portal/{pkg}/session").use()
        sessiondata = wiz.session.get()
        wiz.response.data.set(session=sessiondata)

# src/controller/user.py
class Controller(wiz.controller("base")):
    def __init__(self):
        super().__init__()
        if wiz.session.has("id") == False:
            wiz.response.status(401)

# src/controller/admin.py
class Controller(wiz.controller("user")):
    def __init__(self):
        super().__init__()
        if wiz.session.get("role") != 'admin':
            wiz.response.status(401)
```

`app.json`에서 `"controller": "base"` / `"user"` / `"admin"` 으로 지정.

### 6.2 Route(REST API) 개발 규칙

Route는 App의 `api.py`와 달리 **특정 App에 종속되지 않는 독립적인 REST API 엔드포인트**이다.

| 구분 | App api.py | Route controller.py |
|------|-----------|--------------------|
| 실행 방식 | **함수 기반** (`def search():`) | **스크립트 방식** (최상위 코드 순차 실행) |
| 호출 방식 | `wiz.call("function")` | HTTP 직접 호출 |
| URL 패턴 | `{BASEURI}/api/{APP_ID}/{FUNCTION}` | `/{route}` (BASEURI 없음) |
| 분기 처리 | 함수명으로 자동 분기 | `wiz.request.match()` + `if` 분기 |

```python
# Route controller.py 작성 패턴
segment = wiz.request.match("/api/resource/<action>")
action = segment.action

if action == "list":
    wiz.response.status(200, data=result)

if action == "detail":
    wiz.response.status(200, data=item)

wiz.response.status(404)
```

**패키지 Route 생성 체크리스트**:
1. MCP `wiz_package_create_route`로 생성
2. `portal.json`에 `"use_route": true` 확인/추가
3. `controller` 필드: 인증 불필요 시 빈 문자열 `""`로 설정

### 6.3 SSE 스트리밍 패턴

SSE(Server-Sent Events) Generator 함수 내부에서 `wiz.request`, `wiz.session` 등에 접근하면 오류 발생. Generator 외부에서 필요한 값을 미리 추출한다.

```python
def my_sse():
    flask = wiz.response._flask
    # ✅ Request Context 안에서 미리 추출
    user_id = wiz.session.user_id()
    query = wiz.request.query("query", "")
    
    def generate():
        # ❌ 여기서 wiz.session, wiz.request 접근 불가
        try:
            for item in process(query):
                yield f"data: {json.dumps(item)}\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'type':'error','message':str(e)})}\n\n"
    
    resp = flask.Response(generate(), mimetype='text/event-stream')
    resp.headers['Cache-Control'] = 'no-cache'
    resp.headers['X-Accel-Buffering'] = 'no'
    wiz.response.response(resp)
```

**프론트엔드 SSE 수신**: `wiz.call()`은 SSE 미지원. `fetch()` + `ReadableStream` 사용. 반드시 `FormData` 또는 `URLSearchParams`로 전송 (JSON body 미파싱).

```typescript
async streamAPI(functionName: string, params: any) {
    const formData = new FormData();
    for (const [k, v] of Object.entries(params)) {
        formData.append(k, String(v));
    }
    const response = await fetch(
        `/wiz/api/${APP_ID}/${functionName}`,
        { method: 'POST', body: formData }
    );
    const reader = response.body!.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n\n');
        buffer = lines.pop() || '';
        for (const line of lines) {
            if (line.startsWith('data: ')) {
                const event = JSON.parse(line.slice(6));
                this.handleEvent(event);
            }
        }
    }
}
```

### 6.4 exec() 환경 제약

WIZ는 Python 파일을 `exec()`로 실행하므로:

- **`__file__` 사용 불가** → `wiz.project.fs().abspath()` 사용
- **커스텀 모듈 캐시** → `importlib.util`로 매번 새로 로드
- **외부 SDK 객체 직렬화** → plain dict로 변환 후 저장
- **함수 정의 순서 의존** → `exec()`는 코드를 위에서 아래로 순차 실행하므로, **헬퍼 함수는 호출 코드보다 위에 정의**해야 한다. 특히 Route `controller.py`에서 `wiz.request.match()` 분기 전에 모든 헬퍼 함수를 먼저 정의한다.

```python
# ❌ NameError
current_dir = os.path.dirname(os.path.abspath(__file__))

# ✅ WIZ API로 경로 획득
fs = wiz.project.fs()
base_path = fs.abspath()
```

```python
# ❌ Route에서 NameError — processData가 아직 미정의
segment = wiz.request.match("/api/data/<action>")
if segment.action == "list":
    result = processData(items)    # NameError!

def processData(items): ...

# ✅ 헬퍼 함수를 먼저 정의
def processData(items): ...

segment = wiz.request.match("/api/data/<action>")
if segment.action == "list":
    result = processData(items)    # OK
```

```python
# 모듈 캐시 우회
import importlib.util, sys

def load_module_fresh(module_name, module_path):
    if module_name in sys.modules:
        del sys.modules[module_name]
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module
```

---

## 7. wiz API 빠른 참조

### 7.1 wiz 객체 (백엔드 Python)

```python
# Model/Config 로딩
model = wiz.model("portal/{pkg}/{name}")    # Model 변수가 반환됨
config = wiz.config("database")             # config/ 디렉토리의 설정 파일

# 요청
data = wiz.request.query()                  # 전체 요청 데이터 (dict)
value = wiz.request.query("key", "default") # 개별 키 조회 (항상 문자열)
value = wiz.request.query("key", True)      # 필수 파라미터 (없으면 400)
segment = wiz.request.match("/api/<action>")# URL 패턴 매칭 → stdClass 또는 None
files = wiz.request.files()                 # 파일 업로드 (list)
file = wiz.request.file('avatar')           # 단일 파일
method = wiz.request.method()               # HTTP 메서드 (GET/POST/PUT/DELETE)
uri = wiz.request.uri()                     # 현재 요청 URI
ip = wiz.request.ip()                       # 클라이언트 IP
ua = wiz.request.headers("User-Agent", "")  # HTTP 헤더

# URL 패턴 타입
# <name>: 문자열   <int:name>: 정수   <float:name>: 실수   <path:name>: 경로(/포함)

# 응답 (모두 ResponseException으로 즉시 종료)
wiz.response.status(200, data=result)       # JSON 응답 (kwargs로 전달)
wiz.response.status(400, message="Error")   # 에러 응답
wiz.response.redirect("/path")              # 리다이렉트
wiz.response.download(filepath)             # 파일 다운로드
wiz.response.download(filepath, as_attachment=True, filename="name.pdf")
wiz.response.abort(404)                     # HTTP 에러
wiz.response.send("text")                   # 텍스트 응답
wiz.response.json(data)                     # JSON 응답
wiz.response.PIL(img, type="PNG")           # 이미지 응답
wiz.response.data.set(key=value)            # 템플릿 데이터 설정
wiz.response.lang("ko")                     # 언어 설정

# 세션 (Controller에서 초기화 후 사용)
wiz.session = wiz.model("portal/{package}/session").use()
wiz.session.get("key")                      # 조회
wiz.session.get()                           # 전체 세션 데이터
wiz.session.set(key="value")                # 설정
wiz.session.has("key")                      # 존재 확인
wiz.session.delete("key")                   # 삭제
wiz.session.clear()                         # 전체 삭제

# Controller/파일시스템
ctrl = wiz.controller("base")               # Controller 상속
fs = wiz.project.fs("data", "uploads")      # 프로젝트 파일시스템
path = wiz.project.path()                   # 프로젝트 루트 경로
project_name = wiz.project()                # 현재 프로젝트 이름

# 파일시스템 API
fs = wiz.fs()                               # 현재 컴포넌트 디렉토리
content = fs.read("file.txt")               # 파일 읽기
fs.write("file.txt", content)               # 파일 쓰기
fs.write("file.bin", content, mode="wb")    # 바이너리 쓰기
data = fs.read.json("data.json", default={})# JSON 읽기
fs.write.json("data.json", {"key": "val"})  # JSON 쓰기
exists = fs.exists("file.txt")              # 존재 확인
is_dir = fs.isdir("subdir")                 # 디렉토리 확인
abspath = fs.abspath("file.txt")            # 절대 경로
files = fs.files()                          # 파일 목록
fs.makedirs("subdir")                       # 디렉토리 생성
fs.delete("file.txt")                       # 파일 삭제

# 로거
logger = wiz.logger("myapp", "api")
logger.info("message")                      # [125ms] [myapp] [api] message
logger.debug() / .warning() / .error() / .critical()
```

### 7.2 프론트엔드 (view.ts)

```typescript
// 프로젝트 공통 Service (필수)
import { Service } from '@wiz/libs/portal/{package}/service';
constructor(public service: Service) { }
await this.service.init();                  // 초기화
await this.service.render();                // 화면 갱신 (detectChanges)

// API 호출 (api.py 함수)
let res = await wiz.call("search", { page: 1, text: "" });
// res.code: HTTP 상태코드, res.data: 응답 데이터

// Service 하위 모듈 (패키지별로 다를 수 있음 — README.md 확인)
this.service.alert.show({title, message, action});
this.service.loading.show() / .hide();
this.service.href("/path");
this.service.auth;
this.service.trigger.bind(key, value);
```

---

## 8. MCP 도구 전체 목록

### 8.1 Workspace (7)

| 도구 | 설명 |
|------|------|
| `wiz_workspace_status` | 워크스페이스 상태, 활성 프로젝트, 프로젝트 목록 |
| `wiz_workspace_list_dir` | 디렉토리 조회 (워크스페이스 루트 기준) |
| `wiz_workspace_read_file` | 파일 읽기 |
| `wiz_workspace_write_file` | 파일 쓰기 |
| `wiz_workspace_create_dir` | 디렉토리 생성 |
| `wiz_workspace_delete` | 파일/디렉토리 삭제 |
| `wiz_workspace_rename` | 이름 변경·이동 |

### 8.2 Project (19)

| 도구 | 설명 |
|------|------|
| `wiz_project_info` | 프로젝트 종합 정보 |
| `wiz_project_switch` | 활성 프로젝트 전환 |
| `wiz_project_build` | 프로젝트 빌드 (Normal/Clean) |
| `wiz_project_export` | `.wizproject` 아카이브 내보내기 |
| `wiz_project_import` | `.wizproject` 가져오기 |
| `wiz_project_structure` | `src/` 트리 구조 조회 |
| `wiz_project_list_dir` | 디렉토리 조회 |
| `wiz_project_read_file` | 파일 읽기 |
| `wiz_project_write_file` | 파일 쓰기 |
| `wiz_project_create_dir` | 디렉토리 생성 |
| `wiz_project_delete` | 파일/디렉토리 삭제 |
| `wiz_project_rename` | 이름 변경·이동 |
| `wiz_project_search_apps` | 앱 키워드 검색 |
| `wiz_project_pip_list/install/uninstall` | pip 패키지 관리 |
| `wiz_project_npm_list/install/uninstall` | npm 패키지 관리 |

### 8.3 Source (13)

| 도구 | 설명 |
|------|------|
| `wiz_source_list_apps` | Source 앱/라우트 목록 |
| `wiz_source_app_info` | 앱 상세 정보 및 파일 목록 |
| `wiz_source_create_app` | 앱 생성 (page, component, layout) |
| `wiz_source_create_route` | 라우트 생성 |
| `wiz_source_update_app` | app.json 수정 |
| `wiz_source_delete_app` | 앱/라우트 삭제 |
| `wiz_source_list_files` | 앱 폴더 내 파일 목록 |
| `wiz_source_read_file` | 앱 폴더 내 파일 읽기 |
| `wiz_source_write_file` | 앱 폴더 내 파일 쓰기 |
| `wiz_source_delete_file` | 앱 폴더 내 파일 삭제 |
| `wiz_source_rename_file` | 파일 이름 변경 |
| `wiz_source_list_controllers` | Python 컨트롤러 목록 |
| `wiz_source_list_layouts` | 레이아웃 앱 목록 |

### 8.4 Package (15)

| 도구 | 설명 |
|------|------|
| `wiz_package_list` | 포탈 패키지 목록 |
| `wiz_package_create` | 새 패키지 생성 |
| `wiz_package_export` | `.wizpkg` 내보내기 |
| `wiz_package_list_apps` | 패키지 내 앱/라우트 목록 |
| `wiz_package_app_info` | 패키지 앱 상세 정보 |
| `wiz_package_create_app` | 패키지 내 앱 생성 |
| `wiz_package_create_route` | 패키지 내 라우트 생성 |
| `wiz_package_update_app` | 패키지 앱 app.json 수정 |
| `wiz_package_delete_app` | 패키지 앱/라우트 삭제 |
| `wiz_package_list_files` | 패키지 앱 폴더 내 파일 목록 |
| `wiz_package_read_file` | 패키지 앱 폴더 내 파일 읽기 |
| `wiz_package_write_file` | 패키지 앱 폴더 내 파일 쓰기 |
| `wiz_package_delete_file` | 파일 삭제 |
| `wiz_package_rename_file` | 파일 이름 변경 |
| `wiz_package_list_controllers` | 패키지 내 컨트롤러 목록 |

### 8.5 MCP 사용 원칙

- **상대경로 자동 변환**: 각 카테고리 도구는 해당 루트 기준으로 상대경로를 자동 변환한다.
- **projectName 자동 감지**: VS Code Explorer와 동기화되므로 보통 생략한다.
- **앱 생성 후 파일 작성 순서**: `create_app` → `write_file`(view.ts) → `write_file`(view.pug) → `write_file`(api.py 등)

---

## 9. 트러블슈팅 가이드

### 9.1 Pug 소수점/슬래시 클래스 파싱 실패

- **심각도**: 빌드 실패
- **원인**: Pug는 `.`을 클래스 구분자로, `/`를 self-closing 태그 구분자로 사용
- **해결**: 소수점·슬래시 포함 Tailwind 클래스는 `class=""` 속성 방식으로 작성

### 9.2 Pug 멀티라인 속성 파싱 실패

- **심각도**: 빌드 실패
- **원인**: WIZ Pug 컴파일러는 여는 괄호 직후에 첫 속성이 같은 줄에 시작되어야 함
- **해결**: 첫 속성을 `(` 바로 뒤에, 속성 사이는 콤마로 구분

### 9.3 Pug `#ref=""` 빈 문자열 필수

- **심각도**: 런타임 오류 (NG0301)
- **원인**: Pug가 `#attr`을 `#attr="#attr"`로 자동 변환
- **해결**: 반드시 `#ref=""` 형태로 빈 문자열 값 명시

### 9.4 wiz.response.status() try/except 충돌

- **심각도**: 런타임 오류 (정상 응답이 에러로 처리됨)
- **원인**: `ResponseException`이 `except Exception`에 잡힘
- **해결**: `wiz.response` 호출을 `try` 블록 밖에 배치

### 9.5 wiz.request.query()가 JSON Body 미파싱

- **심각도**: 무음 실패 (값이 기본값으로 반환)
- **원인**: `wiz.request.query()`는 `request.args`와 `request.form`만 조회
- **해결**: 프론트에서 `FormData` 또는 `URLSearchParams` 사용. JSON body 필수 시 `flask.request.get_json(silent=True)` 직접 사용

### 9.6 API 함수 캐시 (Clean Build 필요)

- **심각도**: 새 API 엔드포인트 404
- **원인**: 일반 빌드에서 기존 API 함수 목록을 캐시
- **해결**: 새 함수 추가/삭제/이름 변경 시 클린 빌드 수행

### 9.7 exec() 모듈 캐시 문제

- **심각도**: 코드 수정 미반영
- **원인**: `import`로 로드된 모듈이 `sys.modules`에 캐시
- **해결**: `importlib.util`로 매번 새로 로드

### 9.8 `__file__` 변수 사용 불가

- **심각도**: NameError
- **원인**: `exec()` 환경에서 `__file__` 미정의
- **해결**: `wiz.project.fs().abspath()` 사용

### 9.9 SSE Generator wiz 컨텍스트 접근 불가

- **심각도**: 런타임 오류
- **원인**: Generator 지연 실행 시 Request Context 이탈
- **해결**: Generator 외부에서 `wiz.request`, `wiz.session` 값을 미리 추출

### 9.10 Portal App wiz.call() 라우팅 404

- **심각도**: 런타임 오류 (API 404)
- **원인**: `wiz.call()`은 **현재 App 자신의 `api.py`**에서만 함수를 찾음. Portal App이 Page 안에 삽입되어도 부모 Page의 `api.py`는 호출되지 않음.
- **해결**: Portal App 폴더에 자체 `api.py` 생성. `app.json`에 `controller` 설정 필수. 새 `api.py` 추가 시 클린 빌드(`clean: true`) 필수.

### 9.11 이벤트 핸들러에서 service.render() 누락 시 UI 미갱신

- **심각도**: UI 미반영 (다른 조작을 해야 지연 반영됨)
- **원인**: WIZ의 `service.render()`는 `ChangeDetectorRef.detectChanges()`를 호출한다. Angular는 기본적으로 Zone.js를 통해 변경 감지를 수행하지만, WIZ 프레임워크에서는 이벤트 핸들러가 상태를 변경한 뒤 **명시적으로 `service.render()`를 호출하지 않으면** Angular가 변경을 감지하지 못해 UI가 갱신되지 않는다.
- **해결**: **모든 상태 변경 이벤트 핸들러 끝에 `await this.service.render()` 호출 필수**. 비동기 작업(`wiz.call()` 등) 후에도 반드시 `service.render()`를 호출한다.

```typescript
// ❌ 상태만 변경하고 render 미호출 → UI 미반영
public startEdit(item: any) {
    this.editingId = item.id;
    this.editingName = item.name;
}

// ✅ render 호출 → 즉시 반영
public async startEdit(item: any) {
    this.editingId = item.id;
    this.editingName = item.name;
    await this.service.render();
}
```

### 9.12 exec() 환경 함수 정의 순서 의존성

- **심각도**: 런타임 오류 (NameError)
- **원인**: `exec()`는 코드를 위에서 아래로 순차 실행하므로, 호출 시점에 함수가 정의되어 있지 않으면 `NameError`
- **해결**: 헬퍼 함수는 반드시 호출 코드보다 **위에** 정의. Route `controller.py`에서 `wiz.request.match()` 분기 전에 모든 함수 정의.

### 9.13 `not in 'string'` 권한 검증 보안 취약

- **심각도**: 보안 취약점 (권한 우회)
- **원인**: Python `in`을 문자열에 사용하면 부분 문자열 검사. `'a' in 'admin'`은 `True`이므로 한 글자 role로 권한 우회 가능.
- **해결**: `!=`(동등 비교) 또는 리스트 `not in ['admin']` 사용.

### 9.14 Config 함수명과 패키지 DEFAULT_VALUES 키 불일치

- **심각도**: 무음 실패 (기능 미작동, 에러 로그 없음)
- **원인**: `config/season.py`의 함수명이 패키지 내부의 `DEFAULT_VALUES` 키와 불일치하면 `None` 반환
- **해결**: 패키지의 `DEFAULT_VALUES`를 검색하여 정확한 키 네이밍 확인. `grep -r "DEFAULT_VALUES" src/portal/{pkg}/model/`

### 9.15 Config 키 누락 시 stdClass(None) TypeError

- **심각도**: 런타임 오류 (TypeError)
- **원인**: `config/season.py`에 키가 정의되지 않으면 `None` 반환 → `stdClass(None)` 생성 시 TypeError
- **해결**: 패키지가 기대하는 모든 필수 키를 `season.py`에 정의. dict 타입은 빈 `{}`라도 설정.

### 9.16 Angular :host 스타일 미설정 시 레이아웃 깨짐

- **심각도**: 런타임 (레이아웃·스크롤 동작 안 함)
- **원인**: 호스트 요소가 `display: inline`, `height: auto`이므로 자식의 `h-full`, `flex-1`이 resolve되지 않음
- **해결**: Page/Layout의 `view.scss`에 `:host { display: block; height: 100%; }` 필수 선언.

### 9.17 styles.scss 패키지 @import 누락 시 스타일 미적용

- **심각도**: 무음 실패 (CSS 셀렉터가 번들에 누락)
- **원인**: `src/angular/styles/styles.scss`에서 패키지 스타일의 `@import`가 없으면 해당 패키지의 모든 CSS 셀렉터가 빌드 번들에서 제외됨
- **해결**: `styles.scss`에 `@import "portal/{package}/core"` 추가. 검증: `grep -c "셀렉터" bundle/www/main.css`

### 9.18 overflow 부모 내 드롭다운 클리핑

- **심각도**: 런타임 (드롭다운/팝오버가 잘림)
- **원인**: `overflow: auto/hidden/scroll` 부모가 CSS 클리핑 컨텍스트를 생성하여 `position: absolute` 자식이 밖으로 나가지 못함
- **해결**: 잘리는 요소를 `position: fixed` + `getBoundingClientRect()` 좌표 계산으로 변경.

> 새로운 트러블슈팅 이슈 발견 시 `devdocs/troubleshooting/` 폴더에 카테고리별로 등록한다.

---

## 10. 리팩토링 체크리스트

파일 이동/경로 변경 시 **참조 전수조사**를 반드시 수행한다.

### 검색 범위 (필수)

| 검색 대상 | 경로 |
|-----------|------|
| Controller | `src/controller/*.py` |
| App api.py | `src/app/page.*/api.py` |
| Portal App api.py | `src/portal/*/app/*/api.py` |
| Config | `config/*.py` |
| Struct 내부 참조 | `model/struct/*.py` |
| Struct 진입점 | `model/struct.py` |

### 참조 변경 패턴

```python
# Model 이동: src/model/ → src/portal/{pkg}/model/
wiz.model("struct")             → wiz.model("portal/{pkg}/struct")
wiz.model("struct/project")     → wiz.model("portal/{pkg}/struct/project")
orm.use(name)                   → orm.use(name, module="{pkg}")
```

### portal.json 업데이트

패키지에 model 폴더를 추가하면 `portal.json`에 `"use_model": true`를 반영한다.

---

## 11. Packages(Portal) 구성요소

### portal.json 메타데이터

```json
{
    "package": "works",
    "title": "Season Works",
    "version": "1.0.0",
    "use_app": true,
    "use_route": true,
    "use_libs": true,
    "use_styles": true,
    "use_assets": true,
    "use_controller": true,
    "use_model": true
}
```

### Portal App vs Source App

| 항목 | Source App | Portal App |
|------|-----------|------------|
| 위치 | `src/app/` | `src/portal/{package}/app/` |
| 용도 | 페이지, 레이아웃, 컴포넌트 | 재사용 컴포넌트 전용 |
| 라우팅 | `viewuri` 라우팅 지원 | 라우팅 없음 (태그로 삽입) |
| 셀렉터 | `wiz-{mode}-{name}` | `wiz-portal-{package}-{namespace}` |

### Portal App 사용

```pug
// 패키지 컴포넌트 호출
wiz-portal-season-loading-season(className="w-[48px] h-[48px]")
wiz-portal-season-modal
```

### Portal Controller 사용

App의 `app.json`에서 지정: `"controller": "portal/season/base"`. Portal App/Route에서 `"controller": "base"`로 지정하면, 빌드 시 자동으로 `portal/{package}/base`로 변환.

### Portal Libs 임포트

```typescript
import { Service } from '@wiz/libs/portal/season/service';
import { Project } from '@wiz/libs/portal/works/project';
```

---

## 12. API 테스트 가이드 (curl)

### 필수 쿠키

| 쿠키 | 역할 | 예시 값 |
|------|------|---------|
| `session` | Flask 서명 세션 | 아래 스크립트로 생성 |
| `season-wiz-project` | 대상 프로젝트 | `dev` |
| `season-wiz-devmode` | 개발 모드 | `true` |

### 세션 쿠키 생성

```bash
python3 -c "
from flask import Flask
app = Flask(__name__)
app.secret_key = 'season-wiz-secret'   # config/boot.py 확인
with app.test_request_context():
    from flask import session as sess
    sess['id'] = 'user_id_here'
    sess['email'] = 'user@example.com'
    sess['role'] = 'admin'
    from flask.sessions import SecureCookieSessionInterface
    si = SecureCookieSessionInterface()
    s = si.get_signing_serializer(app)
    print(s.dumps(dict(sess)))
"
```

### URL 패턴

- **App api.py**: `http://localhost:{PORT}{BASEURI}/api/{APP_ID}/{FUNCTION_NAME}`
- **Route**: `http://localhost:{PORT}/{ROUTE_PATH}` (BASEURI 없음)

### curl 템플릿

```bash
SESSION="<세션 쿠키 값>"

# App API 호출 (POST, form-urlencoded)
curl -s -b "session=$SESSION; season-wiz-project=dev; season-wiz-devmode=true" \
  -d "key=value&page=1" \
  "http://localhost:3000/wiz/api/{app_id}/{function}"

# Route 호출 (BASEURI 없음)
curl -s -b "season-wiz-project=dev; season-wiz-devmode=true" \
  "http://localhost:3000/{route_path}"

# ❌ 금지: JSON Content-Type → wiz.request.query()가 빈 dict 반환
```

### 에러 로그 확인

```bash
echo "" > /var/log/wiz/main && curl ... && cat /var/log/wiz/main
```

---

## 13. Custom Instructions 정책

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

## 14. Devlog (작업 이력 관리)

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

## 15. Task 기반 작업 관리

사용자가 **"작업 수행해줘"**, **"todo 작업 진행해줘"** 등으로 작업을 지시하면, `.github/task/todo.md`를 읽어 정의된 작업을 순서대로 수행한다.

> ⚠️ **TODO 파일 경로 고정**: `{WIZ_ROOT}/.github/task/todo.md`에 작성한다. 프로젝트 소스 내(`project/{name}/`)나 다른 위치에 생성하지 않는다.

> ⚠️ **"TODO 작성해줘" 명령**: 사용자의 요구사항·설계 문서를 분석하여 **todo.md에 신규 작업 항목만 등록**하고, 실제 개발 작업은 수행하지 않는다.

> ⚠️ **TODO 생성 원칙**: 요청 내용을 분석하여 **체계적이고 실행 순서가 효율적인 방향**으로 TODO를 구성한다. 의존 관계(데이터→로직→UI)를 고려하여 순서를 배치하고, 병렬 수행 가능한 항목은 그룹으로 묶는다.

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

```markdown
# FN-20260222-0001: Endpoint 설정 / Variables 탭 관련
- endpoint / variables 탭에서 api parameters 설정에서 actions는 고정된 값이니까 토글 형태로 선택하는 UI로 구현
```

### 작업 수행 흐름

1. **todo.md 읽기**: 작업 목록 파악
2. **기존 이력 확인**: 현재 작업과 유사하거나 관련된 기존 작업 이력을 `.github/task/worked/`, `.github/task/reviewed/`, `devlog/` 에서 검색·확인하여, 이전 작업과 **충돌·중복·회귀가 없도록** 맥락을 파악한 뒤 작업에 착수한다.
3. **작업 수행**: 번호 순서대로 (또는 사용자가 특정 번호 지정 시 해당 작업만) 수행.
4. **각 Task 완료 즉시 정리** (다음 Task로 넘어가기 전에 반드시 수행):
   1. **Devlog 작성**: 섹션 14 규칙에 따라 `devlog.md` 행 추가 + 상세 파일 생성
   2. **worked 아카이브 생성**: `.github/task/worked/{작업번호}.md`에 기록
   3. **todo.md 정리**: 완료된 작업 항목을 `todo.md`에서 삭제
   4. **더미 템플릿 유지**: 모든 항목 삭제 시, 마지막 번호의 다음 순번으로 더미 템플릿을 남긴다.

> ⚠️ **즉시 정리 원칙**: 하나의 Task(FN-번호) 완료 후, **반드시 위 4-1 ~ 4-4를 모두 수행한 뒤** 다음 Task로 넘어간다. 여러 Task를 먼저 수행하고 나중에 몰아서 정리하는 것은 **금지**한다.

### worked 아카이브 형식

```markdown
# {작업번호}: {작업 제목}

## 작업 지시 원문
{todo.md에 있던 원본 내용 그대로 복사}

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

1. **worked 폴더 스캔**: `.github/task/worked/` 내 모든 `.md` 파일 읽기
2. **`# Review` 섹션 확인**: 있는 파일만 처리
3. **TODO 항목 생성**: Review 내용 **전체를 종합적으로 분석**하여, 중복되는 내용은 병합하고 연관 정보는 하나의 작업 단위로 묶어 **체계적으로 구분된** TODO를 생성한다. 개별 Review를 그대로 1:1 변환하지 않고, 작업 효율을 고려한 논리적 그룹으로 재구성한다.
4. **reviewed 폴더로 이동**: Review 섹션이 있던 worked 파일을 `.github/task/reviewed/`로 이동
5. **결과 보고**: 처리된 파일 수, 생성된 TODO 항목 수, 스킵된 파일 수

---

## 16. 기능 단위 개발 가이드 참조

기능(Feature) 단위의 아키텍처 설계 및 구현 가이드는 `.github/devdocs/feature-guide/` 폴더에서 관리한다.

| 파일 | 기능 | 사용 시점 |
|------|------|----------|
| `session-auth.md` | 세션 기반 인증 | "로그인 기능 만들어줘", "인증 시스템 구현해줘" 등 |

가이드에 정의된 **아키텍처**(DB 스키마, 디렉토리 구조, 계층 분리)·**구현 체크리스트**를 따라 구현한다. 코드 세부 사항은 프로젝트에 설치된 패키지의 `README.md`를 기준으로 작성한다.

---

## 17. 트러블슈팅 정리 워크플로

사용자가 **"트러블슈팅 정리해줘"** 등으로 요청하면:

1. **전수조사**: 커스텀 인스트럭션·코어 인스트럭션·devdocs 전체·소스코드를 스캔
2. **계획 수립**: `devdocs/troubleshooting/plan.md`에 작업 계획 정리
3. **순차 실행**: `plan.md` 항목별로 수행
4. **인덱싱 갱신**: `troubleshooting/README.md` 및 관련 인덱스 문서 전체 확인·갱신
5. **plan.md 삭제**: 완료 후 삭제

---

## 18. 세부 문서 참조 안내

이 문서에 포함된 내용 외 더 상세한 정보는 `.github/devdocs/` 하위 문서를 참조한다:

| 폴더 | 내용 |
|------|------|
| `devdocs/instructions/` | 개발 원칙 세부, MCP 도구 가이드, 프로젝트 구조, API 빠른 참조, API 테스트, 워크플로 |
| `devdocs/wiz-docs/` | 프레임워크 공식 문서 (사용 가이드, 아키텍처, CLI 명령어, API 레퍼런스) |
| `devdocs/web-development-guide/` | 실무 웹 개발 가이드 (Source/Package 구성요소별 상세) |
| `devdocs/troubleshooting/` | 트러블슈팅 카테고리별 상세 문서 (증상-원인-해결 코드) |
| `devdocs/feature-guide/` | 기능 단위 아키텍처 설계 가이드 (session-auth 등) |
