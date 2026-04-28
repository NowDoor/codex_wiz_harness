# WIZ 프로젝트 구조 요약

---

## 1. 루트 디렉토리

```
{WIZ_ROOT}/
├── config/              # 서버 설정 (database.py 등)
├── public/              # 앱 엔트리포인트 (app.py)
├── project/             # 프로젝트 디렉토리
│   ├── main/            # 기본 프로젝트
│   ├── works/           # 프로젝트 관리 시스템
│   └── {name}/          # 추가 프로젝트
├── ide/                 # WIZ IDE 소스
├── plugin/              # 플러그인
└── .github/             # 개발 문서 및 인스트럭션
```

## 2. Source 디렉토리 (`project/{name}/src/`)

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

## 3. App 필수 파일

| 파일 | 역할 | 필수 |
|------|------|------|
| `app.json` | 메타데이터 (mode, id, viewuri, layout, controller) | ✅ |
| `view.ts` | TypeScript 로직 (Angular Component) | ✅ |
| `view.pug` | Pug 템플릿 (HTML 렌더링) | ✅ |
| `view.scss` | 스타일시트 | 선택 |
| `api.py` | 백엔드 API (wiz.call로 호출) | 선택 |
| `socket.py` | WebSocket 핸들러 | 선택 |

## 4. 핵심 아키텍처 흐름

```
클라이언트 요청
    → Controller (인증/권한/전처리: base → user → admin 체인)
        → App (view.ts + view.pug ↔ api.py)
            → Struct (비즈니스 로직)
                → DB Model (ORM CRUD)
                    → Database
    ← wiz.response.status(200, data) 반환
```

## 5. 현재 프로젝트 구조 참고

### 패키지 구성 예시

| 패키지 | 역할 | 주요 하위 폴더 |
|--------|------|----------------|
| `season` | 공통 기반 (ORM, 세션, 인증, Service) | model/, libs/, controller/, route/ |
| `infra` | 인프라 도메인 (프로젝트, 배포, K8s) | model/, app/, controller/ |
| `dizest` | Dizest 코어 | model/, app/, route/, libs/ |
| `chartjs` | 차트 컴포넌트 | app/ |

### 핵심 호출 패턴

```python
# api.py에서 Struct 사용
struct = wiz.model("portal/infra/struct")   # Struct() 싱글톤 반환
struct.project.search(text=text)            # 프로젝트 검색
project = struct.project(project_id)        # 인스턴스화
project.member.list()                       # Sub-Struct 접근
struct.k8s.request("status/usage")          # K8s API 호출
struct.db("project")                        # ORM DB 직접 접근
```
