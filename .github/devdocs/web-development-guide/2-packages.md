# 2장. Packages 구성요소 (`src/portal/`)

**Packages**는 재사용 가능한 모듈 패키지 시스템입니다. 디렉토리명은 `portal`이지만, 공식 명칭은 **Packages**입니다. 여러 프로젝트에서 공유할 수 있는 컴포넌트, 모델, 라우트, 라이브러리 등을 독립적인 패키지로 관리합니다.

> ⚠️ **패키지 버전 안전성 주의**: 이 문서의 코드 예제에서 `season`, `works` 등 특정 패키지명이 사용되지만, 이는 **구조와 패턴을 설명하기 위한 예시**입니다. 패키지별 세부 API(메서드 시그니처, 파라미터, 반환값, 컴포넌트 속성 등)는 버전에 따라 변경될 수 있으므로, 구현 시 반드시 해당 패키지의 `src/portal/{package}/README.md`를 최종 권위 문서로 참조하십시오.

---

## 목차

| 섹션 | 제목 | 상세 가이드 |
|------|------|------------|
| 2.1 | [App](#21-app-portalpackageapp) | [Portal App 개발 가이드](2-packages/2.1-app-guide.md) |
| 2.2 | [Controller](#22-controller-portalpackagecontroller) | [Portal Controller 개발 가이드](2-packages/2.2-controller-guide.md) |
| 2.3 | [Model](#23-model-portalpackagemodel) | [Portal Model 개발 가이드](2-packages/2.3-model-guide.md) |
| 2.4 | [Route](#24-route-portalpackageroute) | [Portal Route 개발 가이드](2-packages/2.4-route-guide.md) |
| 2.5 | [Libs](#25-libs-portalpackagelibs) | [Portal Libs 개발 가이드](2-packages/2.5-libs-guide.md) |
| 2.6 | [Styles](#26-styles-portalpackagestyles) | [Styles 가이드](2-packages/2.6-styles-guide.md) |
| 2.7 | [Assets](#27-assets-portalpackageassets) | [Portal Assets 개발 가이드](2-packages/2.7-assets-guide.md) |

---



## 패키지 전체 구조

```
src/portal/
├── season/                  # 기본 패키지 (공통 기능)
│   ├── portal.json          # 패키지 메타데이터
│   ├── README.md            # 패키지 문서
│   ├── app/                 # 패키지 컴포넌트
│   ├── controller/          # 패키지 컨트롤러
│   ├── model/               # 패키지 모델
│   ├── route/               # 패키지 라우트
│   ├── libs/                # 프론트엔드 라이브러리
│   ├── styles/              # 공통 스타일시트
│   └── assets/              # 패키지 자산
└── works/                   # 비즈니스 로직 패키지
    ├── portal.json
    ├── app/
    └── ...
```



## `portal.json` - 패키지 메타데이터

패키지의 설정과 사용할 기능을 정의합니다.

```json
{
    "package": "works",
    "title": "Season Works",
    "version": "1.0.0",
    "repo": "",
    "use_app": true,
    "use_route": true,
    "use_libs": true,
    "use_styles": true,
    "use_assets": true,
    "use_controller": true,
    "use_model": true
}
```

| 필드 | 설명 |
|-|-|
| `package` | 패키지 고유 식별자 |
| `title` | 패키지 표시 이름 |
| `version` | 패키지 버전 |
| `use_*` | 해당 구성요소 사용 여부 (`true`/`false`) |



## 2.1 App (`portal/{package}/app/`)

> 📖 상세 가이드: [2.1 Portal App 개발 가이드](2-packages/2.1-app-guide.md)

패키지 내에서 정의하는 재사용 가능한 Angular 컴포넌트입니다.

### Source App과의 차이

| 항목 | Source App (1.1) | Portal App (2.1) |
|------|----------------|------------------|
| **위치** | `src/app/` | `src/portal/{package}/app/` |
| **용도** | 페이지, 레이아웃, 컴포넌트 | 재사용 컴포넌트 전용 |
| **라우팅** | `viewuri` 라우팅 지원 | 라우팅 없음 (태그로 삽입) |
| **셀렉터** | `wiz-{mode}-{name}` | `wiz-portal-{package}-{namespace}` |

### 구조
```
portal/season/app/
├── loading.season/          # 로딩 컴포넌트
│   ├── app.json
│   ├── view.pug
│   └── view.ts
├── modal/                   # 모달 컴포넌트
├── pagination/              # 페이지네이션
└── tree/                    # 트리 컴포넌트
```

### `app.json` (패키지 App)
```json
{
    "type": "app",
    "mode": "portal",
    "title": "loading.season",
    "id": "loading.season",
    "namespace": "loading.season",
    "viewuri": "",
    "category": "",
    "controller": "",
    "template": "wiz-portal-season-loading-season([className]=\"\")"
}
```

### 사용 방법 (Pug 템플릿)
```pug
// 패키지 컴포넌트 호출: wiz-portal-{package}-{namespace}
wiz-portal-season-loading-season(className="w-[48px] h-[48px]")
wiz-portal-season-modal
wiz-portal-season-pagination([config]="pageConfig")
```

---

## 2.2 Controller (`portal/{package}/controller/`)

> 📖 상세 가이드: [2.2 Portal Controller 개발 가이드](2-packages/2.2-controller-guide.md)

패키지 내에서 사용하는 컨트롤러를 정의합니다.

### 구조
```
portal/season/controller/
└── base.py                  # 기본 컨트롤러
```

### 사용 방법
App의 `app.json`에서 지정:
```json
{
    "controller": "portal/season/base"
}
```

> **참고**: Portal App/Route의 `app.json`에서 `controller: "base"`로 지정하면, 빌드 시 자동으로 `portal/{package}/base`로 변환됩니다.

---

## 2.3 Model (`portal/{package}/model/`)

> 📖 상세 가이드: [2.3 Portal Model 개발 가이드](2-packages/2.3-model-guide.md)

패키지 내에서 사용하는 데이터 모델 및 비즈니스 로직입니다.

### 구조
```
portal/season/model/
├── config.py                # 설정 모델
├── session.py               # 세션 관리
├── smtp.py                  # 이메일 발송
├── orm.py                   # ORM 유틸리티
├── auth/                    # 인증 관련
└── dbbase/                  # DB 기본 클래스

portal/works/model/
├── config.py
├── project.py               # 프로젝트 모델
├── fs.py                    # 파일시스템 모델
├── db/                      # 데이터베이스 모델
└── struct/                  # 구조체 정의
```

### 호출 방법
```python
# portal/{package}/model/{name} 형식으로 호출
session = wiz.model("portal/season/session")
project = wiz.model("portal/works/project")
config = wiz.model("portal/dizest/struct")
```

### 역할 분담

```
Source Model (src/model/)
├── db/user.py           # 테이블 스키마 정의
└── db/project.py        # 테이블 스키마 정의

Portal Model (src/portal/{package}/model/)
├── session.py           # 세션 관리 로직
├── config.py            # 패키지 설정 래핑
└── struct/              # 비즈니스 로직 존재
```

---

## 2.4 Route (`portal/{package}/route/`)

> 📖 상세 가이드: [2.4 Portal Route 개발 가이드](2-packages/2.4-route-guide.md)

패키지 전용 API 라우트를 정의합니다.

### 구조
```
portal/season/route/
├── auth/                    # 인증 API
│   ├── app.json
│   └── controller.py
└── pwa.swjs/                # PWA 서비스 워커

portal/works/route/
├── project/                 # 프로젝트 API
└── file.workspace/          # 파일 워크스페이스 API
```

### URL 네이밍 컨벤션

```
Source Route:  /setting, /brand
Portal Route:  /api/season/auth, /api/works/project
```

---

## 2.5 Libs (`portal/{package}/libs/`)

> 📖 상세 가이드: [2.5 Portal Libs 개발 가이드](2-packages/2.5-libs-guide.md)

프론트엔드에서 사용하는 TypeScript/JavaScript 라이브러리입니다.

### 핵심 개념

- **자유로운 구조**: 디렉토리 구조나 파일 구성에 제한이 없음
- **Service 중심 아키텍처**: 진입점 역할을 하는 Service 클래스를 통해 하위 모듈 조합
- **패키지 단위 재사용**: 패키지별로 독립적인 라이브러리 구성

### 구조
```
portal/season/libs/
├── service.ts               # 메인 서비스 클래스
├── base/                    # 기본 유틸리티
├── ckeditor/                # CKEditor 통합
├── ngx-sortablejs/          # 정렬 라이브러리
├── src/                     # 서비스 소스
│   ├── auth.ts              # 인증 서비스
│   ├── event.ts             # 이벤트 버스
│   ├── lang.ts              # 다국어 처리
│   ├── modal.ts             # 모달 서비스
│   └── status.ts            # 상태 관리
└── util/                    # 유틸리티
    ├── crypto.ts            # 암호화
    ├── file.ts              # 파일 처리
    └── request.ts           # HTTP 요청

portal/works/libs/
├── project.ts               # 프로젝트 서비스
└── struct/                  # 데이터 구조체
```

### 서비스 클래스 예시 (`service.ts`)
```typescript
import { Injectable } from '@angular/core';
import Auth from './src/auth';
import Event from './src/event';
import Modal from './src/modal';
import Request from './util/request';

@Injectable({ providedIn: 'root' })
export class Service {
    public auth: Auth;
    public modal: Modal;
    public event: Event;
    public request: Request;

    public async init(app: any) {
        this.auth = new Auth(this);
        this.modal = new Modal(this);
        this.event = new Event(this);
        this.request = new Request();
    }
}
```

### 임포트 방법
```typescript
// @wiz/libs/portal/{package}/{path} 형식
import { Service } from '@wiz/libs/portal/season/service';
import { Project } from '@wiz/libs/portal/works/project';
```

---

## 2.6 Styles (`portal/{package}/styles/`)

> 📖 상세 가이드: [2.6 Styles 가이드](2-packages/2.6-styles-guide.md)

패키지 전용 공통 스타일시트입니다.

> **중요**: 현재 사내 표준 UI 프레임워크로 **Tailwind CSS**를 사용하고 있어, 특수한 경우가 아니면 Styles를 직접 작성하지 않습니다.

### 구조
```
portal/{package}/styles/
├── core.scss                # 핵심 스타일 (진입점)
├── content/                 # 콘텐츠 관련 (font, text, color)
├── layout/                  # 레이아웃 관련 (margin, padding, display)
├── form/                    # 폼 관련 (control, group)
└── component/               # 컴포넌트 (button, card)
```

### Angular 통합

```scss
// src/angular/styles/styles.scss
@import "portal/season/core";
@import "portal/works/core";
```

### 설정

`portal.json`에서 `use_styles: true` 설정 필요:

```json
{
    "use_styles": true
}
```

---
## 2.7 Assets (`portal/{package}/assets/`)

> 📖 상세 가이드: [2.7 Portal Assets 개발 가이드](2-packages/2.7-assets-guide.md)

패키지 전용 정적 자산 (이미지, 아이콘 등)입니다. 패키지와 함께 재사용되며, `/assets/portal/{package}/` 경로로 웹에서 접근됩니다.

### Source Assets vs Portal Assets

| 구분 | 위치 | 웹 URL | 용도 |
|------|------|--------|------|
| **Source Assets** | `src/assets/` | `/assets/{path}` | 프로젝트 전역 정적 파일 |
| **Portal Assets** | `src/portal/{pkg}/assets/` | `/assets/portal/{pkg}/{path}` | 패키지별 독립 정적 파일 |

### 정적 서빙 경로

| 소스 위치 | 웹 URL |
|----------|--------|
| `src/portal/season/assets/brand/icon.ico` | `/assets/portal/season/brand/icon.ico` |
| `src/portal/works/assets/work.svg` | `/assets/portal/works/work.svg` |

### 설정

`portal.json`에서 `use_assets: true` 설정 필요:

```json
{
    "use_assets": true
}
```



## 샘플 패키지 구성

### `season` 패키지 (main, works 프로젝트 공통)
공통 기능을 제공하는 기본 패키지:
- **app**: 로딩 스피너, 모달, 페이지네이션, 트리 컴포넌트
- **model**: 세션, 인증, ORM, SMTP
- **libs**: 서비스 클래스, 유틸리티
- **route**: 인증 API, PWA 서비스

### `works` 패키지 (works 프로젝트)
프로젝트 관리 비즈니스 로직:
- **app**: 프로젝트 정보, 드라이브, 이슈보드, 미팅, 위키
- **model**: 프로젝트, 파일시스템, DB 모델
- **libs**: 프로젝트 서비스
- **route**: 프로젝트 API, 파일 워크스페이스

### `dizest` 패키지 (main 프로젝트)
워크플로우 엔진 기능:
- **app**: 워크플로우 관련 컴포넌트
- **model**: 워크플로우 구조체
- **route**: 워크플로우 API

