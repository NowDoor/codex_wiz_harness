# WIZ 프레임워크 프로젝트 구조 참조

## 📁 전체 프로젝트 구조

```
{PROJECT_ROOT}/
├── config/                      # 서버 설정
│   ├── boot.py                  # 서버 부팅 설정
│   ├── ide.py                   # IDE 설정
│   ├── service.py               # 서비스 설정
│   └── plugin.json              # 플러그인 설정
│
├── public/                      # 공개 디렉토리
│   ├── app.py                   # 앱 엔트리포인트
│   └── app.wsgi                 # WSGI 설정
│
├── project/                     # 프로젝트 디렉토리
│   └── main/                    # 메인 프로젝트
│       ├── config/              # 프로젝트 설정
│       ├── src/                 # 소스 코드 ★
│       ├── build/               # 빌드 결과물
│       ├── bundle/              # 번들 파일
│       ├── package.json         # npm 패키지
│       └── node_modules/        # npm 모듈
│
├── ide/                         # WIZ IDE 소스
├── plugin/                      # 플러그인
└── .github/                     # Copilot 인스트럭션 및 문서
    ├── copilot-instructions.md
    ├── prompts/
    └── devdocs/
```

---

## 📁 Source 디렉토리 구조 (src/)

```
project/main/src/
│
├── app/                         # Angular 컴포넌트
│   ├── page.{name}/             # Page - URL 라우팅 가능
│   │   ├── app.json             # 메타데이터 (필수)
│   │   ├── view.ts              # TypeScript (필수)
│   │   ├── view.pug             # Pug 템플릿 (필수)
│   │   ├── view.scss            # 스타일 (선택)
│   │   ├── api.py               # 백엔드 API (선택)
│   │   └── socket.py            # WebSocket (선택)
│   │
│   ├── layout.{name}/           # Layout - 페이지 래퍼
│   │   ├── app.json
│   │   ├── view.ts
│   │   ├── view.pug             # router-outlet 포함
│   │   └── view.scss
│   │
│   └── component.{name}/        # Component - 재사용
│       ├── app.json
│       ├── view.ts
│       ├── view.pug
│       └── view.scss
│
├── controller/                  # 백엔드 컨트롤러
│   ├── base.py                  # 기본 (최상위)
│   ├── user.py                  # 로그인 필수
│   └── admin.py                 # 관리자 전용
│
├── model/                       # 데이터 모델
│   ├── {name}.py                # 단일 모델
│   └── db/                      # DB 모델 폴더
│       ├── user.py
│       └── project.py
│
├── route/                       # REST API 라우트
│   └── {name}/
│       ├── app.json             # 라우트 설정
│       └── controller.py        # 핸들러 로직
│
├── portal/                      # Packages (재사용 모듈)
│   ├── season/                  # 기본 패키지
│   │   ├── portal.json          # 패키지 메타데이터
│   │   ├── app/                 # 패키지 컴포넌트
│   │   ├── controller/          # 패키지 컨트롤러
│   │   ├── model/               # 패키지 모델
│   │   ├── route/               # 패키지 라우트
│   │   ├── libs/                # TS/JS 라이브러리
│   │   ├── styles/              # SCSS 스타일
│   │   └── assets/              # 정적 자산
│   │
│   └── {package}/               # 커스텀 패키지
│       └── ...
│
├── angular/                     # Angular 빌드 설정
│   ├── angular.build.options.json
│   ├── index.pug
│   ├── main.ts
│   └── app/
│
└── assets/                      # 정적 자산
    ├── images/
    ├── fonts/
    └── icons/
```

---

## 📄 파일별 역할

### App 디렉토리

| 파일 | 필수 | 역할 |
|------|:----:|------|
| `app.json` | ✓ | 앱 메타데이터, 라우팅, 레이아웃 설정 |
| `view.ts` | ✓ | Angular 컴포넌트 TypeScript 로직 |
| `view.pug` | ✓ | Pug 템플릿 (HTML 렌더링) |
| `view.scss` | | SCSS 스타일시트 |
| `api.py` | | 백엔드 API (wiz.call 호출용) |
| `socket.py` | | WebSocket 핸들러 |

### Route 디렉토리

| 파일 | 필수 | 역할 |
|------|:----:|------|
| `app.json` | ✓ | 라우트 설정 (URL 패턴, 컨트롤러) |
| `controller.py` | ✓ | 라우트 핸들러 로직 |
| `view.pug` | | HTML 응답용 (선택) |

### Controller 디렉토리

| 파일 | 역할 |
|------|------|
| `base.py` | 기본 컨트롤러 (세션 초기화, 공통 로직) |
| `user.py` | 로그인 필수 컨트롤러 (base 상속) |
| `admin.py` | 관리자 전용 컨트롤러 (user 상속) |

### Model 디렉토리

| 패턴 | 설명 |
|------|------|
| `{name}.py` | 단일 모델 파일 |
| `db/{table}.py` | 데이터베이스 ORM 모델 |
| `{category}/{name}.py` | 카테고리별 분류 |

### Portal 디렉토리

| 폴더 | 역할 |
|------|------|
| `app/` | 재사용 컴포넌트 |
| `controller/` | 패키지 전용 컨트롤러 |
| `model/` | 패키지 모델 (세션, 설정 등) |
| `route/` | 패키지 API 라우트 |
| `libs/` | TypeScript 라이브러리 |
| `styles/` | 공통 SCSS 스타일 |
| `assets/` | 패키지 정적 자산 |

---

## 🏷️ 명명 규칙

### App 폴더명
```
{mode}.{name}/

예시:
page.main/           → /main
page.explore.project/→ /explore/project
layout.aside/
layout.empty/
component.nav.sidebar/
component.modal/
```

### 파일 명명
```
Controller: {name}.py       (base.py, user.py, admin.py)
Model:      {name}.py       (user.py, session.py)
Model(DB):  db/{table}.py   (db/user.py, db/project.py)
Route:      {name}/         (auth/, api-users/, brand/)
```

### 셀렉터 규칙
```
Source App:  wiz-{mode}-{name}
             wiz-page-main
             wiz-layout-aside
             wiz-component-modal

Portal App:  wiz-portal-{package}-{namespace}
             wiz-portal-season-loading-season
             wiz-portal-works-project-card
```

---

## 🔗 참조 경로 규칙

### 프론트엔드 Import
```typescript
// 패키지 라이브러리
import { Service } from '@wiz/libs/portal/season/service';
import { Project } from '@wiz/libs/portal/works/project';

// 패키지 스타일
@use '@wiz/styles/portal/season/variables';
```

### 백엔드 Model 호출
```python
# 프로젝트 모델
wiz.model("user")
wiz.model("db/user")

# 패키지 모델
wiz.model("portal/season/session")
wiz.model("portal/works/project")
```

### Controller 호출
```python
# 프로젝트 컨트롤러
wiz.controller("base")
wiz.controller("user")

# 패키지 컨트롤러
wiz.controller("portal/season/base")
```

---

## 📎 상세 문서

- `.github/devdocs/wiz-docs/architecture.md`
- `.github/devdocs/wiz-docs/usage-guide.md`
- `.github/devdocs/web-development-guide/README.md`
