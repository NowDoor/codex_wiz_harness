# WIZ 개발 문서 인덱스

이 디렉토리는 WIZ 프레임워크 개발에 필요한 모든 참조 문서를 포함한다. 각 하위 폴더에는 README.md가 있어 해당 폴더의 문서 목록과 용도를 안내한다.

> ⚠️ **패키지 버전 안전성 (전체 문서 공통)**: 이 문서들에 포함된 패키지 사용 예제(ORM, Session, Service 등)는 **일반적인 패턴과 구조**를 설명하는 참고 자료이다. 패키지별 세부 API(메서드 시그니처, 파라미터, 반환값 등)는 버전마다 다를 수 있으므로, **반드시 해당 패키지의 `src/portal/{package}/README.md`를 최종 권위 문서로 참조**한다.

---

## 폴더 구조

| 폴더 | 용도 | 참조 시점 |
|------|------|----------|
| [instructions/](instructions/README.md) | 코어 인스트럭션에서 분리된 세부 개발 규칙 | 개발 원칙·MCP 도구·프로젝트 구조 등 세부사항 필요 시 |
| [wiz-docs/](wiz-docs/README.md) | WIZ 프레임워크 공식 문서 (아키텍처, API, 명령어) | 프레임워크 자체 이해가 필요할 때 |
| [web-development-guide/](web-development-guide/README.md) | 실무 웹 개발 가이드 (App, Controller, Model, Route 등) | 구체적인 구현 방법을 찾을 때 |
| [feature-guide/](feature-guide/README.md) | 기능 단위 아키텍처 및 구현 가이드 | 로그인, 게시판 등 **기능 단위** 개발 요청 시 |
| [troubleshooting/](troubleshooting/README.md) | WIZ 프레임워크 고유 트러블슈팅 (카테고리별 분류) | 빌드 오류·런타임 이슈 발생 시 |

## 문서 탐색 흐름

1. **처음 접할 때**: `wiz-docs/README.md` → 아키텍처/사용가이드
2. **개발 규칙 확인**: `instructions/README.md` → 원칙·워크플로·MCP 도구
3. **구현 방법 상세**: `web-development-guide/README.md` → App/Model/Route 등 실무 가이드
4. **기능 개발 요청**: `feature-guide/README.md` → 기능별 아키텍처·DB 스키마·체크리스트
5. **빌드/런타임 이슈**: `troubleshooting/README.md` → 카테고리별 증상·원인·해결
