# 1장. Source 구성요소 (`src/`)

프로젝트의 핵심 소스 코드를 구성하는 디렉토리들입니다.

> ⚠️ **패키지 버전 안전성 주의**: 이 문서의 코드 예제에서 특정 패키지(season 등)의 API를 사용하는 부분은 **일반적인 호출 패턴**을 보여주는 것입니다. 패키지별 세부 API는 버전에 따라 다를 수 있으므로, 구현 시 반드시 해당 패키지의 `src/portal/{package}/README.md`를 참조하십시오.

---

## 목차

| 섹션 | 제목 | 상세 가이드 |
|------|------|------------|
| 1.1 | [App](#11-app-srcapp) | [App 개발 가이드](1-source/1.1-app-guide.md) |
| 1.2 | [Controller](#12-controller-srccontroller) | [Controller 개발 가이드](1-source/1.2-controller-guide.md) |
| 1.3 | [Model](#13-model-srcmodel) | [Model 개발 가이드](1-source/1.3-model-guide.md) |
| 1.4 | [Route](#14-route-srcroute) | [Route 개발 가이드](1-source/1.4-route-guide.md) |
| 1.5 | [Angular](#15-angular-srcangular) | [Angular 개발 가이드](1-source/1.5-angular-guide.md) |
| 1.6 | [Assets](#16-assets-srcassets) | [Assets 개발 가이드](1-source/1.6-assets-guide.md) |

---



## 1.1 App (`src/app/`)

> 📖 상세 가이드: [1.1 App 개발 가이드](1-source/1.1-app-guide.md)

### 역할
Angular 기반의 프론트엔드 컴포넌트를 정의합니다. 페이지, 레이아웃, 위젯 등 UI 컴포넌트를 구성합니다.

### 디렉토리 구조
```
src/app/
├── layout.empty/            # 레이아웃 컴포넌트
│   ├── app.json             # 앱 메타데이터
│   ├── view.pug             # Pug 템플릿
│   ├── view.ts              # TypeScript 로직
│   └── view.scss            # 스타일시트
├── page.main/               # 페이지 컴포넌트
│   ├── app.json
│   ├── view.pug
│   ├── view.ts
│   ├── view.scss
│   ├── api.py               # 백엔드 API (선택)
│   └── socket.py            # WebSocket 핸들러 (선택)
└── component.nav/           # 위젯 컴포넌트
```

### 컴포넌트 유형

| 유형 | 접두사 | 설명 |
|-|-|-|
| Page | `page.*` | URL 라우팅이 가능한 페이지 |
| Layout | `layout.*` | 페이지를 감싸는 레이아웃 템플릿 |
| Component | `component.*` | 재사용 가능한 UI 컴포넌트 |

### 필수 파일

#### `app.json` - 앱 메타데이터
```json
{
    "title": "/workflow",
    "mode": "page",
    "namespace": "main",
    "id": "page.main",
    "viewuri": "/workflow/**",
    "layout": "layout.empty",
    "controller": "",
    "ng": {
        "selector": "wiz-page-main",
        "inputs": [],
        "outputs": []
    }
}
```

| 필드 | 설명 |
|-|-|
| `mode` | 유형: `page`, `layout`, `component` |
| `viewuri` | URL 패턴 (page의 경우) |
| `layout` | 사용할 레이아웃 ID |
| `controller` | 연결할 컨트롤러 |

#### `view.ts` - TypeScript 로직
```typescript
import { OnInit } from "@angular/core";
import { Service } from '@wiz/libs/portal/season/service';

export class Component implements OnInit {
    constructor(public service: Service) { }

    public async ngOnInit() {
        await this.service.init();
        await this.service.render();
    }
}
```

#### `view.pug` - Pug 템플릿
```pug
.container
    h1 Welcome
    p Hello, WIZ Framework!
```

#### `view.scss` - 스타일시트
```scss
.container {
    padding: 20px;
}
```

### 선택적 파일

#### `api.py` - 백엔드 API
컴포넌트별 전용 API 엔드포인트를 정의합니다.

```python
def load():
    data = {"message": "Hello"}
    wiz.response.status(200, data)

def save():
    data = wiz.request.query()
    wiz.response.status(200, {"result": "success"})
```

프론트엔드에서 호출:
```typescript
const { code, data } = await wiz.call("load");
```

#### `socket.py` - WebSocket 핸들러
```python
class Controller:
    def __init__(self, server):
        self.server = server

    def connect(self):
        pass

    def disconnect(self, flask, io):
        pass

    def join(self, data, io):
        io.join(data)

    def leave(self, data, io):
        io.leave(data)

    def custom_event(self, data, io):
        io.emit("response", {"message": "received"})
```

---

## 1.2 Controller (`src/controller/`)

> 📖 상세 가이드: [1.2 Controller 개발 가이드](1-source/1.2-controller-guide.md)

### 역할
백엔드의 공통 로직을 정의합니다. 세션 관리, 인증/인가, 요청 전처리 등을 담당합니다.

### 구조
```
src/controller/
├── base.py              # 기본 컨트롤러 (모든 요청에 적용)
├── user.py              # 사용자 인증 필요 컨트롤러
└── admin.py             # 관리자 권한 필요 컨트롤러
```

### 예시 (`base.py`)
```python
class Controller:
    def __init__(self):
        # 세션 초기화
        wiz.session = wiz.model("portal/season/session").use()
        sessiondata = wiz.session.get()
        wiz.response.data.set(session=sessiondata)

        # 다국어 처리
        lang = wiz.request.query("lang", None)
        if lang is not None:
            wiz.response.lang(lang)
            wiz.response.redirect(wiz.request.uri())
```

### 사용 방법
`app.json`에서 `controller` 필드로 지정:
```json
{
    "controller": "base"
}
```

### Controller 계층 구조

```
base.py (최상위)
    ↑
user.py (로그인 필수)
    ↑
admin.py (관리자 전용)
```

---

## 1.3 Model (`src/model/`)

> 📖 상세 가이드: [1.3 Model 개발 가이드](1-source/1.3-model-guide.md)

### 역할
데이터베이스 접근 및 비즈니스 로직을 캡슐화합니다.

### 구조
```
src/model/
├── test.py              # 테스트 모델
└── db/                  # 데이터베이스 관련 모델
```

### 호출 방법
```python
# 프로젝트 모델 불러오기
model = wiz.model("test")

# 하위 디렉토리 모델
db_user = wiz.model("db/user")
```

### Model 반환 패턴

| 패턴 | 반환값 | 사용 시점 |
|------|--------|----------|
| 클래스 패턴 | 클래스 자체 | `Model = UserClass` → 인스턴스 생성 필요 |
| 인스턴스 패턴 | 인스턴스 | `Model = UserClass()` → 바로 사용 |

---

## 1.4 Route (`src/route/`)

> 📖 상세 가이드: [1.4 Route 개발 가이드](1-source/1.4-route-guide.md)

### 역할
REST API 엔드포인트를 정의합니다. App의 `api.py`와 달리, 독립적인 API 라우트를 생성합니다.

### 구조
```
src/route/
├── brand/
│   ├── app.json         # 라우트 설정
│   └── controller.py    # 라우트 핸들러
└── setting/
    ├── app.json
    └── controller.py
```

### `app.json` 설정
```json
{
    "id": "brand",
    "title": "/brand/<path:path>",
    "route": "/brand/<path:path>",
    "controller": "base"
}
```

### `controller.py` 예시
```python
segment = wiz.request.match("/brand/<action>/<path:path>")
action = segment.action

if action == "logo":
    fs = wiz.project.fs("bundle", "src", "assets", "brand")
    wiz.response.download(fs.abspath("logo.png"), as_attachment=False)

if action == "icon":
    fs = wiz.project.fs("bundle", "src", "assets", "brand")
    wiz.response.download(fs.abspath("icon.ico"), as_attachment=False)

wiz.response.abort(404)
```

---

## 1.5 Angular (`src/angular/`)

> 📖 상세 가이드: [1.5 Angular 개발 가이드](1-source/1.5-angular-guide.md)

### 역할
Angular 빌드 및 설정 파일을 관리합니다.

### 구조
```
src/angular/
├── angular.json                 # Angular 프로젝트 설정
├── angular.build.options.json   # 빌드 옵션
├── main.ts                      # Angular 진입점
├── wiz.ts                       # WIZ 바인딩
├── index.pug                    # HTML 템플릿
├── package.json                 # Angular 의존성
├── tailwind.config.js           # Tailwind CSS 설정
├── app/                         # Angular 모듈
├── libs/                        # 공용 라이브러리
└── styles/                      # 전역 스타일
```

### 파일 접근 빈도별 분류

| 빈도 | 파일 |
|------|------|
| ⚡ 자주 수정 | `app-routing.module.ts`, `index.pug`, `tailwind.config.js`, `angular.build.options.json` |
| 🔧 특수한 경우 | `app.module.ts`, `package.json`, `styles/styles.scss` |
| 🔒 거의 수정 안함 | `main.ts`, `wiz.ts`, `angular.json`, `app.component.ts` |

---

## 1.6 Assets (`src/assets/`)

> 📖 상세 가이드: [1.6 Assets 개발 가이드](1-source/1.6-assets-guide.md)

### 역할
정적 자산 파일을 저장합니다.

### 구조
```
src/assets/
├── bg.jpg               # 배경 이미지
├── brand/               # 브랜드 자산 (로고, 아이콘)
├── font/                # 폰트 파일
└── lang/                # 다국어 파일
```

### 서빙 경로

| 소스 위치 | 웹 URL |
|----------|--------|
| `src/assets/brand/logo.png` | `/assets/brand/logo.png` |
| `src/assets/font/SUIT/...` | `/assets/font/SUIT/...` |

### 체계적인 자원 관리 원칙

1. **용도별 폴더 분리**: 브랜드, 폰트, 다국어, 이미지 등 용도에 따라 폴더 구분
2. **명확한 네이밍**: 파일명만으로 용도를 파악할 수 있도록 작명
3. **중복 방지**: 동일한 리소스를 여러 위치에 저장하지 않음
