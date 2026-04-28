# WIZ 프레임워크 Copilot 프롬프트 인덱스

이 디렉토리는 GitHub Copilot Agent가 WIZ 프레임워크 개발 시 참조할 수 있는 프롬프트 파일들을 포함합니다.

---

## 📁 프롬프트 파일 목록

| 파일 | 설명 | 사용 시점 |
|------|------|----------|
| [development-rules.prompt.md](development-rules.prompt.md) | 요청 유형별 처리 규칙 | 개발 요청 처리 전 |
| [code-templates.prompt.md](code-templates.prompt.md) | 표준 코드 템플릿 | 새 파일 생성 시 |
| [api-reference.prompt.md](api-reference.prompt.md) | wiz API 빠른 참조 | API 사용 시 |
| [project-structure.prompt.md](project-structure.prompt.md) | 프로젝트 구조 참조 | 구조 파악 필요 시 |
| [context-gathering.prompt.md](context-gathering.prompt.md) | 컨텍스트 수집 가이드 | 작업 시작 전 |

---

## 🔗 관련 문서 경로

### 메인 인스트럭션
- `.github/copilot-instructions.md`

### 상세 개발 문서
- `.github/devdocs/wiz-docs/` - WIZ 프레임워크 공식 문서
- `.github/devdocs/web-development-guide/` - 웹 개발 가이드

---

## 🎯 프롬프트 사용 가이드

### 새 페이지 개발 시
1. `context-gathering.prompt.md` - 기존 패턴 확인
2. `development-rules.prompt.md` - 페이지 개발 규칙 확인
3. `code-templates.prompt.md` - Page 템플릿 사용

### API 개발 시
1. `context-gathering.prompt.md` - 기존 라우트 확인
2. `api-reference.prompt.md` - wiz API 참조
3. `code-templates.prompt.md` - Route 템플릿 사용

### Model 개발 시
1. `context-gathering.prompt.md` - 기존 모델 패턴 확인
2. `development-rules.prompt.md` - Model 규칙 확인
3. `code-templates.prompt.md` - Model 템플릿 사용

### 구조 파악 시
1. `project-structure.prompt.md` - 전체 구조 확인
2. `.github/devdocs/wiz-docs/architecture.md` - 아키텍처 이해

---

## 📖 문서 참조 우선순위

1. **인스트럭션**: `.github/copilot-instructions.md`
2. **프롬프트**: `.github/prompts/` (이 디렉토리)
3. **개발 가이드**: `.github/devdocs/web-development-guide/`
4. **API 문서**: `.github/devdocs/wiz-docs/api/`
5. **예제**: `.github/devdocs/wiz-docs/examples.md`
