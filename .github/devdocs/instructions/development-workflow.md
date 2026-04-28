# WIZ 개발 작업 순서 및 리팩토링 가이드

---

## 1. 개발 작업 순서

새 기능이나 페이지를 개발할 때는 데이터 → 로직 → UI 순서로 **바닥부터 위로** 쌓아올린다.

### Step 1. 데이터베이스 설정 (필요시)

DB를 사용하는데 아직 설정이 없는 경우:

1. **DB 접속 정보**: `config/database.py` 에 namespace별 접속 정보 추가
   ```python
   from season.util import stdClass
   base = stdClass(type="mysql", database="mydb", host="127.0.0.1",
                   port=3306, user="user", password="pass", charset="utf8")
   myapp = base  # namespace 이름으로 export
   ```
   > ⚠️ `season.util.stdClass`의 사용법은 프레임워크 버전에 따라 다를 수 있다.
2. **테이블 정의**: `src/portal/{package}/model/db/{table}.py` 에 Peewee Model 작성
   ```python
   import peewee as pw
   orm = wiz.model("portal/{package}/orm")
   base = orm.base("{namespace}")  # database.py의 namespace
   class Model(base):
       class Meta:
           db_table = "my_table"
       id = pw.CharField(max_length=32, primary_key=True)
       # ... 필드 정의
   ```
   > ⚠️ ORM 패키지의 `base()`, `use()` 등 API는 패키지 버전에 따라 다를 수 있다. 반드시 해당 패키지의 `src/portal/{package}/README.md`를 확인한다.

### Step 2. Model/Struct 구현

- DB Model 위에 비즈니스 로직을 Struct 패턴으로 구현한다.
- **반드시 `Model` 변수를 정의**하고, Aggregate Root → Sub-Struct 체계를 따른다.
- 기존 패키지의 model을 최대한 재사용한다. 패키지별 세부 API는 해당 패키지의 `src/portal/{package}/README.md`를 참조한다.

### Step 3. Layout 구조 (필요시)

1. `src/app/layout.{name}/` 폴더에 Layout App 생성 (MCP `wiz_source_create_app` 활용)
2. Layout의 `view.pug`에 반드시 `router-outlet` 포함
3. 프로젝트의 공통 `Service`를 필수 사용. Service의 세부 API는 해당 패키지의 `src/portal/{package}/README.md`를 참조한다.
   ```pug
   .flex.flex-row.w-full.h-screen.overflow-hidden
       wiz-component-nav-aside
       .flex-1.h-full.overflow-auto
           router-outlet
   wiz-portal-{package}-alert
   ```

### Step 4. URI 설계 및 Page 생성

1. URL 구조를 먼저 설계한다
2. `src/app/page.{name}/` 에 페이지 생성 (MCP `wiz_source_create_app` 활용)
3. **app.json**에서 `viewuri`, `layout`, `controller` 를 지정
4. 권한 관리가 필요하면 Controller를 생성/활용 (base → user → admin 상속 체인)

### Step 5. 기능 구현 및 모듈화

1. Page의 `view.ts`/`view.pug`에 UI 구현, `api.py`에 백엔드 API 함수 작성
2. REST API가 필요하면 `src/route/{name}/` 에 Route 생성
3. 여러 페이지에서 재사용되는 기능은 `src/portal/{package}/`로 패키지화

### Step 6. 빌드 및 기능 검토

1. MCP `wiz_project_build` 로 프로젝트 빌드. ⚠️ **반드시 `clean: false` (normal 빌드)를 기본으로 사용한다.**
2. 클린 빌드(`clean: true`)는 빌드 오류가 해결되지 않거나 사용자가 명시적으로 요청한 경우에만.
3. 기능 동작 확인 및 오류 수정

### 빌더 제약사항

- **`src/model/` 디렉토리는 반드시 존재해야 한다.** 삭제하면 빌드 실패.
- `build/`, `bundle/` 디렉토리는 빌드 산출물이므로 수동 편집하지 않는다.

---

## 2. 리팩토링 체크리스트

파일 이동/경로 변경 시 **참조 전수조사**를 반드시 수행한다.

### 참조 검색 범위 (필수)

| 검색 대상 | 경로 | 예시 |
|-----------|------|------|
| Controller | `src/controller/*.py` | `wiz.model("struct")` |
| App api.py | `src/app/page.*/api.py` | `wiz.model("struct")` |
| Portal App api.py | `src/portal/*/app/*/api.py` | `wiz.model("struct")` |
| Config | `config/*.py` | `orm.use("user")` |
| Struct 내부 참조 | `model/struct/*.py` | `wiz.model("struct/project/member")` |
| Struct 진입점 | `model/struct.py` | `wiz.model("struct/kubernetes")` |

### 참조 변경 패턴

```python
# Model 이동: src/model/ → src/portal/{pkg}/model/

# Struct 진입점
wiz.model("struct")                    → wiz.model("portal/{pkg}/struct")

# Struct 내부 참조
wiz.model("struct/project")            → wiz.model("portal/{pkg}/struct/project")

# ORM DB 접근
orm.use(name)                          → orm.use(name, module="{pkg}")
```

### 검색 명령 (grep 패턴)

```bash
grep -rn 'wiz.model("struct' src/
grep -rn 'orm.use(' src/ config/
grep -rn '이전경로' src/ config/
```

### portal.json 업데이트

패키지에 model 폴더를 추가하면 `portal.json`에 `"use_model": true`를 반영한다.

---

## 3. 기능 추가 실전 흐름 (예시: 필터/태그 기능)

기존 목록 페이지에 필터링 기능을 추가하는 전형적인 흐름:

### 1단계: Struct에 데이터 조회 메서드 추가
```python
def categories(self):
    rows = self.db.rows(fields="category", **user_where)
    return sorted(set(r['category'] for r in rows if r.get('category')))

def search(self, text=None, category=None, ...):
    if category is not None and len(category) > 0:
        where['category'] = category
```

### 2단계: api.py에 엔드포인트 추가
```python
def categories():
    cats = struct.project.categories()
    wiz.response.status(200, cats)

def search():
    category = wiz.request.query("category", "")
    rows, total = struct.project.search(text=text, category=category, ...)
```

### 3단계: view.ts에 상태·로직 추가
```typescript
public categories: string[] = [];
public selectedCategory: string = "";

public async selectCategory(cat: string) {
    this.selectedCategory = this.selectedCategory === cat ? "" : cat;
    await this.load();
}
```

### 4단계: view.pug에 태그 UI 추가
```pug
div(*ngIf="categories.length > 0", class="flex flex-wrap gap-2")
    button([ngClass]="selectedCategory === '' ? 'bg-indigo-600 text-white' : 'bg-gray-100'",
        (click)="selectCategory('')") All
    button(*ngFor="let cat of categories",
        [ngClass]="selectedCategory === cat ? 'bg-indigo-600 text-white' : 'bg-gray-100'",
        (click)="selectCategory(cat)") {{cat}}
```

> **핵심 원칙**: 비즈니스 로직은 Struct에, API는 파라미터 전달만, view.ts는 상태 관리만, view.pug는 렌더링만 담당한다.
