# 사내 웹 개발 가이드 문서

## 개요

WIZ는 Python Flask 기반의 풀스택 웹 개발 프레임워크로, Angular 프론트엔드와 Python 백엔드를 통합하여 관리합니다. 이 문서는 WIZ 프레임워크의 핵심 구성 요소와 디렉토리 구조를 설명하며, 사내 웹 프로젝트 개발의 표준 가이드라인을 제공합니다.

> ⚠️ **패키지 버전 안전성 주의**: 이 문서에 포함된 패키지 사용 예제(ORM, Session, Service, Component 등)는 **일반적인 패턴과 구조**를 설명하는 참고 자료입니다. 특정 패키지(season 등)의 코드 예시가 포함되어 있으나, 패키지별 세부 API(메서드 시그니처, 파라미터, 반환값, 컴포넌트 속성 등)는 **버전마다 다를 수 있습니다**. 구현 시 반드시 해당 패키지의 `src/portal/{package}/README.md`를 최종 권위 문서로 참조하십시오.

## 프로젝트 디렉토리 구조

```
project/
├── main/                    # 프로젝트 1 (예: 워크플로우 시스템)
│   ├── config/              # 프로젝트 설정
│   ├── src/                 # 소스 코드
│   ├── build/               # 빌드 결과물
│   ├── bundle/              # 번들 파일
│   ├── package.json         # npm 의존성
│   └── node_modules/        # npm 모듈
└── works/                   # 프로젝트 2 (예: 프로젝트 관리 시스템)
    ├── src/
    └── package.json
```

## `src/` 디렉토리 전체 구조

```
src/
├── app/                     # Angular 앱 컴포넌트
├── controller/              # 백엔드 컨트롤러
├── model/                   # 데이터 모델 및 비즈니스 로직
├── route/                   # API 라우트
├── angular/                 # Angular 빌드 설정
├── assets/                  # 정적 자산 (이미지, 폰트 등)
└── portal/                  # Packages (재사용 가능한 모듈 패키지)
```

## 문서 목차

### 1장. Source 구성요소 (`src/`)

프로젝트의 핵심 소스 코드를 구성하는 디렉토리들입니다.

| 섹션 | 디렉토리 | 역할 | 상세 가이드 |
|------|----------|------|------------|
| 1.1 | `src/app/{type}.{name}/` | Angular 컴포넌트 (Page/Layout/Component) | [App 개발 가이드](1-source/1.1-app-guide.md) |
| 1.2 | `src/controller/{name}.py` | 백엔드 컨트롤러, 요청 전처리 | [Controller 개발 가이드](1-source/1.2-controller-guide.md) |
| 1.3 | `src/model/{name}.py` | 데이터 모델, 비즈니스 로직 | [Model 개발 가이드](1-source/1.3-model-guide.md) |
| 1.4 | `src/route/{name}/` | REST API 라우트 | [Route 개발 가이드](1-source/1.4-route-guide.md) |
| 1.5 | `src/angular/` | Angular 빌드 설정 | [Angular 개발 가이드](1-source/1.5-angular-guide.md) |
| 1.6 | `src/assets/` | 정적 자산 (이미지, 폰트) | [Assets 개발 가이드](1-source/1.6-assets-guide.md) |

> 📄 종합 문서: [1장. Source 구성요소](1-source.md)

### 2장. Packages 구성요소 (`src/portal/`)

재사용 가능한 모듈 패키지 시스템입니다.

| 섹션 | 디렉토리 | 역할 | 상세 가이드 |
|------|----------|------|------------|
| 2.1 | `portal/{pkg}/app/` | 패키지 컴포넌트 (재사용 UI) | [App 개발 가이드](2-packages/2.1-app-guide.md) |
| 2.2 | `portal/{pkg}/controller/` | 패키지 컨트롤러 | [Controller 개발 가이드](2-packages/2.2-controller-guide.md) |
| 2.3 | `portal/{pkg}/model/` | 패키지 모델, 비즈니스 로직 | [Model 개발 가이드](2-packages/2.3-model-guide.md) |
| 2.4 | `portal/{pkg}/route/` | 패키지 전용 API 라우트 | [Route 개발 가이드](2-packages/2.4-route-guide.md) |
| 2.5 | `portal/{pkg}/libs/` | 프론트엔드 라이브러리 (TS/JS) | [Libs 개발 가이드](2-packages/2.5-libs-guide.md) |
| 2.6 | `portal/{pkg}/styles/` | 공통 SCSS 스타일시트 | [Styles 개발 가이드](2-packages/2.6-styles-guide.md) |
| 2.7 | `portal/{pkg}/assets/` | 패키지 자산 (이미지, 아이콘) | [Assets 개발 가이드](2-packages/2.7-assets-guide.md) |

> 📄 종합 문서: [2장. Packages 구성요소](2-packages.md)


## WIZ 핵심 API

### 요청/응답 처리

```python
# 쿼리 파라미터 가져오기
value = wiz.request.query("key", "default")

# URL 매칭
segment = wiz.request.match("/api/<action>/<id>")
action = segment.action
id = segment.id

# JSON 응답
wiz.response.status(200, data={"result": "success"})

# 파일 다운로드
wiz.response.download(filepath, as_attachment=False)

# 리다이렉트
wiz.response.redirect("/new-url")

# 에러 응답
wiz.response.abort(404)
```

### 파일시스템 접근

```python
# 프로젝트 파일시스템
fs = wiz.project.fs("bundle", "src", "assets")

# 파일 읽기
content = fs.read.json("config.json", {})

# 절대 경로 얻기
path = fs.abspath("logo.png")
```

### 세션 관리

```python
# 세션 모델 로드
wiz.session = wiz.model("portal/season/session").use()

# 세션 데이터 가져오기
user = wiz.session.get()
user_id = wiz.session.get("user_id")

# 세션 설정
wiz.session.set(user_id="123", role="admin")

# 세션 삭제
wiz.session.clear()
```

## 빌드 및 실행

### 개발 서버 실행
```bash
wiz run --port=3000
```

### 데몬 모드
```bash
wiz server start
wiz server stop
wiz server restart
```

### 프로젝트 빌드
```bash
wiz command workspace build main
```

### IDE 접속
```
http://127.0.0.1:3000/wiz
```


## 샘플 프로젝트 참고

### main 프로젝트 (워크플로우 시스템)
```
project/main/src/
├── app/
│   ├── layout.empty/         # 빈 레이아웃
│   ├── page.main/            # 메인 페이지 (워크플로우)
│   └── page.page.access/     # 접근 페이지
├── controller/base.py        # 기본 컨트롤러
├── model/test.py             # 테스트 모델
├── route/
│   ├── brand/                # 브랜드 API (로고, 아이콘)
│   └── setting/              # 설정 API
└── portal/                   # Packages
    ├── season/               # Season 패키지 (공통 기능)
    └── dizest/               # Dizest 패키지 (워크플로우)
```

### works 프로젝트 (프로젝트 관리 시스템)
```
project/works/src/
├── app/
│   ├── layout.aside/         # 사이드바 레이아웃
│   ├── layout.empty/         # 빈 레이아웃
│   ├── page.admin/           # 관리자 페이지
│   ├── page.explore.project/ # 프로젝트 탐색
│   ├── page.issues/          # 이슈 관리
│   ├── component.nav.aside/  # 네비게이션 컴포넌트
│   └── component.pagination/ # 페이지네이션 컴포넌트
├── controller/
│   ├── base.py               # 기본 컨트롤러
│   ├── user.py               # 사용자 컨트롤러
│   └── admin.py              # 관리자 컨트롤러
└── portal/                   # Packages
    ├── season/               # Season 패키지 (공통 기능)
    ├── works/                # Works 패키지 (프로젝트 관리)
    ├── wiki/                 # Wiki 패키지 (문서 관리)
    └── saml/                 # SAML 패키지 (SSO 인증)
```
