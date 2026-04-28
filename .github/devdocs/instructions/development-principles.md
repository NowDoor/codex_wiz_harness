# WIZ 개발 원칙 세부 가이드

코어 인스트럭션의 개발 원칙을 상세히 설명하는 문서이다.

---

## 1. 관심사 분리 (Separation of Concerns)

- **데이터 계층(Model/Struct)**, **전처리 계층(Controller)**, **API 계층(Route/api.py)**, **UI 계층(App)** 을 명확히 분리한다.
- 각 계층은 자신의 책임만 수행하며, 직접적인 상호 참조 없이 `wiz.model()`, `wiz.controller()` 등의 인터페이스를 통해 연결한다.
- UI(view.ts/view.pug)에 비즈니스 로직을 넣지 않는다. 비즈니스 로직은 반드시 Model/Struct 또는 api.py에 위치한다.

## 2. 단일 책임 원칙 (Single Responsibility)

- 하나의 파일/클래스는 하나의 명확한 역할만 담당한다.
- Model 파일이 300줄을 넘기면 Struct 패턴으로 하위 도메인을 분리한다.
- Controller는 인증/권한 검증만 담당하고, 데이터 처리 로직은 Model에 위임한다.

## 3. Model 표준화: Struct 구조 설계 원칙

Model은 프로젝트 어디에서든 재사용 가능한 형태로 **규격화·표준화** 하여 작성한다.

### Struct 개념

Struct는 **DB Model(테이블 스키마)을 조합하여 비즈니스 로직을 캡슐화하는 계층**이다. DB Model이 단일 테이블의 CRUD를 담당한다면, Struct는 여러 DB Model을 엮어 도메인 로직(권한 검증, 상태 전이, 복합 조회 등)을 제공한다.

```
┌─ DB Model (portal/{pkg}/model/db/*.py)
│   └─ 테이블 스키마 정의 (Peewee ORM)
│   └─ ORM Wrapper (orm.use()) 로 CRUD 수행
│
├─ Struct (portal/{pkg}/model/struct/*.py 또는 portal/{pkg}/model/{name}.py)
│   └─ Aggregate Root: 도메인 엔터티의 진입점 (예: Project)
│   └─ Sub-Struct: 하위 도메인 (예: Member, Plan, Issueboard)
│   └─ Composite Struct: 여러 Sub-Struct를 조립
│
└─ 호출 흐름: api.py/route → Struct → DB Model → Database
```

### Struct 설계 규칙

1. **Aggregate Root 패턴**: 도메인의 최상위 진입점을 하나의 클래스로 정의하고, 하위 도메인은 Sub-Struct로 조립한다.
   ```python
   # portal/works/model/project.py - Aggregate Root
   class Project:
       def __init__(self, data):
           self.id = data['id']
           self.data = data
           self.member = Member(self)      # Sub-Struct
           self.plan = Plan(self)          # Sub-Struct
           self.issueboard = Issueboard(self)
       
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

2. **Sub-Struct 패턴**: 부모(Aggregate Root)를 생성자에서 참조받아 해당 컨텍스트 내에서 동작한다.
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
       
       def members(self): ...
       def create(self, email, role): ...
   
   Model = Member
   ```

3. **`Model` 변수 필수**: 모든 model 파일은 반드시 `Model` 변수를 정의한다.
   - **클래스 반환**: `Model = ClassName` (호출 시마다 새 인스턴스 생성)
   - **인스턴스 반환**: `Model = ClassName()` (싱글톤, Session·Config 등)

4. **Composite Struct 패턴**: 여러 Sub-Struct를 `@property`로 조립하는 진입점 클래스이다. 호출할 때마다 새 인스턴스를 반환한다.
   ```python
   # portal/{pkg}/model/struct.py - Composite Struct (싱글톤)
   class Struct:
       def __init__(self):
           self.orm = wiz.model("portal/{pkg}/orm")
           self.session = wiz.model("portal/{pkg}/session").use()
           self._Post = wiz.model("portal/{pkg}/struct/post")
           self._Comment = wiz.model("portal/{pkg}/struct/comment")

       def db(self, name):
           return self.orm.use(name, module="{pkg}")

       @property
       def post(self):
           """Sub-Struct 접근 (호출마다 새 인스턴스)"""
           return self._Post(self)

       @property
       def comment(self):
           return self._Comment(self)

   Model = Struct()  # 싱글톤
   ```

5. **src/model Struct에서 패키지 Struct 호출**: `src/model/struct.py`는 프로젝트 고유 Sub-Struct(user 등)를 관리하면서, `__getattr__`를 통해 패키지 Struct에 동적으로 접근할 수 있다.
   ```python
   # src/model/struct.py - 프로젝트 루트 Struct
   class Struct:
       def __init__(self):
           self.orm = wiz.model("portal/{pkg}/orm")
           self.session = wiz.model("portal/{pkg}/session").use()
           self._User = wiz.model("struct/user")
           self._packages = {}  # 패키지 Struct 캐시

       @property
       def user(self):
           return self._User(self)

       def __getattr__(self, name):
           """알 수 없는 속성 → 패키지 Struct 동적 로드"""
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
   ```python
   # 사용 예시 (api.py)
   struct = wiz.model("struct")        # src/model/struct.py 로드
   struct.user.list()                  # 로컬 User Sub-Struct
   struct.post.post.search()           # portal/post 패키지의 Struct → Post Sub-Struct
   ```

6. **DB Model은 스키마만**: DB Model 파일에는 테이블 정의(필드, 인덱스)만 작성하고 비즈니스 로직은 Struct에 위치한다.
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

7. **ORM Wrapper 활용**: 직접 Peewee 쿼리 대신 `orm.use()` 래퍼를 통해 CRUD를 수행한다.
   ```python
   orm = wiz.model("portal/{pkg}/orm")
   db = orm.use("project", module="{pkg}")
   db.get(id=id)                       # 단건 조회
   db.rows(status="open", page=1)     # 목록 (페이징, 정렬, LIKE)
   db.count(status="open")            # 카운트
   db.insert(data)                    # 삽입 (자동 ID 생성)
   db.update(data, id=id)             # 수정
   db.delete(id=id)                   # 삭제
   db.upsert(data, keys="id")         # Upsert
   ```

## 4. 재사용성: Packages(Portal) 우선

- 여러 페이지에서 공통으로 사용하는 Model, Component, 라이브러리는 `src/portal/{package}/` 에 패키지로 모듈화한다.
- 프로젝트 고유 로직만 `src/app/`에 직접 배치한다. `src/model/`에는 프로젝트 고유 DB Model(`db/`)과 Struct(`struct.py`, `struct/`)를 배치할 수 있다.
- 패키지 model 호출: `wiz.model("portal/{package}/{name}")`
- 패키지 lib 임포트: `import { Service } from '@wiz/libs/portal/{package}/{name}'`
- **패키지 README.md 참조 필수**: 패키지의 라이브러리(libs, model, component 등)를 사용할 때는 반드시 해당 패키지의 `src/portal/{package}/README.md`를 먼저 읽고 API 사용법을 확인한다.
- **ORM module 파라미터 필수**: 패키지 내 DB model을 사용할 때는 `module` 파라미터를 명시한다.
  ```python
  orm = wiz.model("portal/{pkg}/orm")
  db = orm.use("user", module="{pkg}")          # portal/{pkg}/model/db/user.py 로드
  db = orm.use("project/deploy", module="{pkg}") # portal/{pkg}/model/db/project/deploy.py 로드
  ```
  > ⚠️ ORM의 `base()`, `use()` 등 메서드 시그니처는 패키지 버전에 따라 다를 수 있다. 반드시 해당 패키지의 `README.md`를 확인한다.

## 5. 프론트엔드: Service 필수 사용

- 모든 App(Page/Layout/Component)의 `view.ts`에서 프로젝트의 공통 `Service`를 주입하고 `ngOnInit`에서 초기화한다.
- Service에 없는 기능이 필요하면 해당 패키지의 libs를 확장한다 (새로 만들지 않는다).
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
  > ⚠️ `{package}`는 프로젝트에서 사용하는 실제 패키지명으로 대체한다. Service의 세부 API(하위 모듈, 메서드, 파라미터)는 패키지 버전에 따라 다를 수 있으므로, 반드시 `src/portal/{package}/README.md`를 확인한다.
- **Service 일반적인 하위 모듈**: `auth` (인증), `modal` (모달), `event` (이벤트), `request` (HTTP), `lang` (다국어) 등의 하위 모듈을 제공할 수 있다. 사용 가능한 모듈과 상세 API는 패키지별로 다를 수 있다.
- **Service API 상세**: 각 모듈의 상세 사용법은 해당 패키지의 `src/portal/{package}/README.md`를 참조한다.
- **API 호출**: App 내 api.py의 함수는 `wiz.call("함수명", data)` 로 호출한다 (view.ts 내 전역 `wiz` 객체 사용).
- **Socket.IO 실시간 통신**: App 폴더에 `socket.py`를 추가하면 해당 App 전용 Socket.IO 네임스페이스가 자동 등록된다. 프론트엔드에서 `wiz.socket()`으로 연결한다. **`socket.py` 추가/수정 후에는 빌드 + `wiz service restart` 필수**. 상세 가이드: `.github/devdocs/web-development-guide/1-source/1.8-socket-guide.md`

## 6. 프로젝트 범위 원칙

- **현재 선택된 WIZ 프로젝트만 수정**한다. MCP `wiz_workspace_status`로 현재 프로젝트를 확인하고, 다른 프로젝트의 파일은 절대 수정하지 않는다.
- 여러 프로젝트가 동일한 코드를 공유하더라도, 사용자가 명시적으로 요청하지 않는 한 다른 프로젝트에 변경을 전파하지 않는다.
- MCP 도구 호출 시 `projectName` 파라미터를 현재 프로젝트로 명시하거나, 생략하여 자동 감지에 맡긴다.
- **config 파일은 프로젝트 config 디렉토리에 작성**한다. WIZ에는 프레임워크 레벨 config(`{WIZ_ROOT}/config/`)와 프로젝트 레벨 config(`project/{name}/config/`)가 있다. `database.py`, `season.py`, 프로젝트 고유 설정(`nrich.py` 등)은 **프로젝트 config(`project/{name}/config/`)에 작성**한다. 프레임워크 config(`{WIZ_ROOT}/config/boot.py`, `service.py` 등)는 서버 실행/IDE 설정 전용이므로 프로젝트 개발 시 수정하지 않는다.
  ```bash
  # ✅ 프로젝트 config (DB, 세션, 커스텀 설정)
  project/main/config/database.py
  project/main/config/season.py
  project/main/config/nrich.py
  
  # ❌ 프레임워크 config (건드리지 않음)
  config/boot.py      # 서버 포트, secret_key
  config/service.py   # 로그 레벨, 미들웨어
  ```
- **Git 작업은 프로젝트 루트에서 수행**한다. WIZ 프로젝트별로 독립된 Git 저장소를 사용하므로, `git add/commit/push` 등의 명령은 반드시 `project/{name}/` 디렉토리에서 실행한다.

## 7. View Routing (Angular 라우팅) 규칙

- WIZ는 Angular의 표준 `path` 매칭 대신 **`URLPattern` (`urlpattern-polyfill`) 기반 커스텀 matcher**를 사용한다.
- `viewuri`의 `:param` 세그먼트는 기본적으로 **필수(mandatory)**이다. 세그먼트가 URL에 없으면 매칭되지 않고 INDEX_PAGE로 리다이렉트된다.
- **옵셔널 세그먼트**: `:param?`(물음표 접미사)를 사용하면 해당 세그먼트가 없어도 매칭된다.
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
- 매칭된 세그먼트는 `WizRoute.segment` 객체로 접근: `WizRoute.segment.id`, `WizRoute.segment.tab`
- **리다이렉트 전용 앱은 만들지 않는다**. URLPattern 옵셔널 문법(`:param?`)과 view.ts 내 기본값 처리로 대체한다.

### Angular 컴포넌트 재사용과 탭 전환

- Angular Router는 URL 파라미터만 변경될 때 **같은 컴포넌트를 재사용**한다 (ngOnInit이 다시 호출되지 않음).
- **탭 전환 감지**: `Router.events`의 `NavigationEnd`를 구독하여 `WizRoute.segment` 변경을 감지하고 UI를 갱신한다.
  ```typescript
  import { Router, NavigationEnd } from '@angular/router';
  
  constructor(public service: Service, private router: Router) { }
  
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

### API 404 처리

- api.py에서 리소스가 없으면 `wiz.response.status(404)`를 반환하고, view.ts에서 `code !== 200`이면 목록 페이지로 리다이렉트한다.

- 상세 내용: `.github/devdocs/web-development-guide/1-source/1.7-routing-guide.md` 참조

## 8. Route(REST API) 개발 규칙

Route는 App의 `api.py`와 달리 **특정 App에 종속되지 않는 독립적인 REST API 엔드포인트**이다.

### App api.py vs Route 핵심 차이

| 구분 | App api.py | Route controller.py |
|------|-----------|--------------------|
| 위치 | `src/app/{type}.{name}/api.py` | `src/route/{name}/controller.py` |
| 실행 방식 | **함수 기반** (`def search():`) | **스크립트 방식** (최상위 코드 순차 실행) |
| 호출 방식 | `wiz.call("function")` (프론트) | HTTP 직접 호출 |
| URL 패턴 | `{BASEURI}/api/{APP_ID}/{FUNCTION}` | `/{route}` (BASEURI 없음) |
| 분기 처리 | 함수명으로 자동 분기 | `wiz.request.match()` + `if` 분기 |

### controller.py 작성 패턴

```python
# 1. 공통 초기화 (IP 제한, 인증 등)
remote_ip = wiz.request.ip()
if remote_ip not in ('127.0.0.1', '::1'):
    wiz.response.status(403, message="Forbidden")

# 2. URL 패턴 매칭
if wiz.request.match("/infra/health/check") is not None:
    wiz.response.status(200, data=result)

# 3. 매칭 안 되면 404
wiz.response.status(404)
```

### 패키지 Route 생성 체크리스트

1. MCP `wiz_package_create_route`로 생성
2. **`portal.json`에 `"use_route": true`** 확인/추가
3. `controller` 필드: 인증 불필요 시 빈 문자열 `""`로 설정
4. 빌드 후 route ID는 `portal.{pkg}.{id}` 형태로 변환됨

- 상세 내용: `.github/devdocs/web-development-guide/1-source/1.4-route-guide.md` 참조

## 9. App 네이밍 규칙

### 폴더명 규칙

폴더명은 `{appType}.{viewuri 세그먼트를 .으로 연결}` 형태:

```
viewuri: /admin/deploy       → page.admin.deploy
viewuri: /project/:id/:tab   → page.project.item
viewuri: /mypage             → page.mypage
```

- URL 세그먼트의 `/`를 `.`으로 치환
- `:param` 동적 세그먼트는 의미 있는 단어(item, detail 등)로 대체
- `page.page.*` 같은 중복 접두사 금지

### app.json 필드 규칙

| 필드 | 규칙 | 예시 |
|------|------|------|
| `id` | 폴더명과 **동일** | `page.admin.deploy` |
| `namespace` | 폴더명에서 `{appType}.` 접두사 제거 | `admin.deploy` |
| `title` | **viewuri와 동일** | `/admin/deploy` |
| `viewuri` | URL 패턴 | `/admin/deploy` |
| `mode` | 앱 타입 (`page`, `layout`, `component`) | `page` |

### Layout/Component 네이밍

- Layout: `layout.{용도}` (예: `layout.sidebar`, `layout.empty`)
- Component: `component.{기능}.{세부}` (예: `component.nav.sidebar`)

## 10. UI 스타일 가이드 (Tailwind CSS)

### 글꼴 크기 계층

| 용도 | Tailwind 클래스 | 실제 크기 |
|------|-----------------|----------|
| 페이지 제목 (h1) | `text-lg font-semibold text-zinc-950` | 18px |
| 섹션 제목 | `text-[15px] font-semibold` | 15px |
| 본문/테이블/버튼/입력 | `text-[13px]` | 13px |
| 보조 텍스트/배지 | `text-xs` | 12px |

### 아이콘 크기

| 용도 | 클래스 |
|------|--------|
| 페이지 제목 옆 아이콘 | `size-6` |
| 사이드바/버튼 내 아이콘 | `size-4` |

## 11. UI 일관성 및 표기 오류 방지

### HTML 요소 display 속성

- `a`, `span` 등 inline 요소에 margin/padding(상하)을 적용할 때는 반드시 `block` 또는 `inline-block`을 명시한다.

### Flex 컨테이너 스크롤 영역 규칙

- `flex` + `flex-col` 레이아웃에서 스크롤 가능한 자식에 반드시 **`min-h-0`** 을 명시한다.
  ```pug
  //- ✅ min-h-0 추가 → overflow 정상 작동
  div(class="flex-1 min-h-0 overflow-hidden")
      div(class="w-full h-full overflow-auto") ...
  ```

### API 파라미터 타입 안전성

- `wiz.request.query()`는 항상 **문자열**을 반환한다. 숫자 비교 전에 **반드시 `int()` 로 변환**한다.
  ```python
  page = int(wiz.request.query("page", 1))
  dump = int(wiz.request.query("dump", 20))
  ```

## 12. wiz.response 예외 기반 종료 패턴 (중요)

`wiz.response.status()`, `wiz.response.redirect()` 등은 **`ResponseException`을 raise하여 즉시 종료**한다. `try/except Exception` 안에서 호출하면 정상 응답까지 catch되므로, **`wiz.response`는 반드시 `try` 블록 바깥에서 호출**한다.

> 📎 상세 증상·원인·해결 코드: [troubleshooting/server-side/api/response-exception-pattern.md](../troubleshooting/server-side/api/response-exception-pattern.md)

## 13. Pug 템플릿 규칙 (Angular + Pug)

### 13.1 참조 변수 빈 문자열 필수

Pug에서 Angular 템플릿 참조 변수(`#ref`)는 반드시 `#ref=""` (빈 문자열 값) 형태로 선언한다. 값 없이 `#ref`만 쓰면 Pug가 `#ref="#ref"`로 변환하여 Angular NG0301 에러 발생.

> 📎 상세 증상·원인·해결 코드: [troubleshooting/web-ui/pug/template-ref-empty-value.md](../troubleshooting/web-ui/pug/template-ref-empty-value.md)

### 13.2 Tailwind 소수점/슬래시 클래스

소수점(`.`) 또는 슬래시(`/`)를 포함하는 Tailwind 클래스는 반드시 `class=""` 속성 방식으로 작성한다. dot notation 사용 시 Pug 파싱 실패.

> 📎 상세 증상·원인·해결 코드: [troubleshooting/web-ui/pug/decimal-slash-class.md](../troubleshooting/web-ui/pug/decimal-slash-class.md)

### 13.3 멀티라인 속성 작성 규칙

첫 속성은 반드시 여는 괄호 `(`와 같은 줄에 배치하고, 속성 사이는 콤마(`,`)로 구분한다.

> 📎 상세 증상·원인·해결 코드: [troubleshooting/web-ui/pug/multiline-attributes.md](../troubleshooting/web-ui/pug/multiline-attributes.md)

## 14. WIZ exec() 환경과 외부 Python 모듈 통합

WIZ는 Python 파일을 `exec()`로 실행하므로 일반 Python 환경과 다른 제약이 있다.

- **`__file__` 사용 불가** → `wiz.project.fs().abspath()` 사용. 📎 [상세](../troubleshooting/server-side/python-runtime/file-variable.md)
- **커스텀 모듈 캐시** → `importlib.util`로 매번 새로 로드. 📎 [상세](../troubleshooting/server-side/python-runtime/exec-module-cache.md)
- **커스텀 모듈 간 import** → `sys.path.insert(0, dir)` 후 import

### 외부 SDK 객체 직렬화

외부 SDK가 반환하는 커스텀 객체는 반드시 plain dict로 변환 후 저장한다.

```python
# ✅ dict로 변환 후 저장
def _serialize_block(block):
    if hasattr(block, 'text'):
        return {"type": "text", "text": block.text}
    elif hasattr(block, 'input'):
        return {"type": "tool_use", "id": block.id, "name": block.name, "input": block.input}
    return {"type": "text", "text": str(block)}
```
