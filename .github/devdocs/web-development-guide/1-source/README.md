# 1장. Source 구성요소 (`src/`)

프로젝트의 핵심 소스 코드를 구성하는 개별 가이드 문서들이다.

---

## 문서 목록

| 파일 | 주제 | 내용 요약 |
|------|------|----------|
| [1.1-app-guide.md](1.1-app-guide.md) | App 개발 (Page/Layout/Component) | app.json 설정, view.ts/view.pug 작성, api.py 함수 정의 |
| [1.2-controller-guide.md](1.2-controller-guide.md) | Controller 개발 | base → user → admin 상속 체인, 인증/권한 전처리 |
| [1.3-model-guide.md](1.3-model-guide.md) | Model 개발 (ORM, Struct) | DB Model 스키마, Struct 패턴, ORM Wrapper 사용법 |
| [1.4-route-guide.md](1.4-route-guide.md) | Route (REST API) 개발 | controller.py 스크립트 방식, wiz.request.match() 패턴 |
| [1.5-angular-guide.md](1.5-angular-guide.md) | Angular 빌드 설정 | angular.json 설정, 의존성 관리 |
| [1.6-assets-guide.md](1.6-assets-guide.md) | 정적 자산 관리 | 이미지, 폰트 등 assets 디렉토리 사용법 |
| [1.7-routing-guide.md](1.7-routing-guide.md) | View Routing (Angular 라우팅) | URLPattern 매칭, 옵셔널 세그먼트, 탭 전환 패턴 |
| [1.8-socket-guide.md](1.8-socket-guide.md) | Socket.IO 실시간 통신 | socket.py 작성법, wiz.socket() 프론트엔드 연결 |

## 상위 문서

- [종합 문서 (1-source.md)](../1-source.md) — 위 가이드들의 핵심 내용을 통합한 종합 레퍼런스
- [전체 인덱스](../README.md) — 웹 개발 가이드 최상위 목차
