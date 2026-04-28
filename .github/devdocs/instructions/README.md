# 개발 규칙 세부 문서

코어 인스트럭션(`.github/copilot-instructions.md`)에서 분리된 세부 개발 규칙 문서들이다. 코어 인스트럭션은 핵심 원칙 요약과 작업 수행 철학만 다루며, 구체적인 코드 패턴·규칙은 이 폴더의 문서를 참조한다.

> ⚠️ **패키지 버전 안전성**: 이 문서들의 코드 예제에서 특정 패키지(season 등)의 API를 사용하는 부분은 **일반적인 호출 패턴**을 보여주는 것이다. 패키지별 세부 API(메서드 시그니처, 파라미터, 반환값 등)는 버전마다 다를 수 있으므로, 반드시 해당 패키지의 `src/portal/{package}/README.md`를 기준으로 구현한다.

---

## 문서 목록

| 문서 | 내용 요약 | 참조 시점 |
|------|----------|----------|
| [development-principles.md](development-principles.md) | 계층 분리, Struct 설계, 네이밍, UI 스타일, wiz.response 패턴, Pug 규칙, exec() 제약 | 코드 작성 시 원칙/패턴 확인 |
| [development-workflow.md](development-workflow.md) | 개발 작업 순서 (데이터→로직→UI), 리팩토링 체크리스트, 기능 추가 실전 흐름 | 새 기능 개발 또는 리팩토링 시 |
| [mcp-tools-guide.md](mcp-tools-guide.md) | WIZ MCP 도구 전체 목록 및 사용법 (앱/파일/패키지/빌드 관리) | MCP 도구 호출 방법 확인 |
| [project-structure.md](project-structure.md) | WIZ 루트/소스 디렉토리 구조, App 필수 파일, 아키텍처 흐름 | 프로젝트 구조 파악 |
| [api-quick-reference.md](api-quick-reference.md) | wiz 백엔드 객체, 프론트엔드 Service 빠른 참조 | API 호출 방법 빠르게 찾을 때 |
| [api-testing-guide.md](api-testing-guide.md) | curl 테스트, 세션 쿠키 생성, SSE 스트리밍 패턴 | API 테스트/디버깅 시 |
| ~~troubleshooting.md~~ | **이동됨** → `devdocs/troubleshooting/` 폴더로 카테고리별 분리. [README.md](../troubleshooting/README.md) 참조 | 빌드 오류·런타임 이슈 발생 시 |
