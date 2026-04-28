# WIZ Framework — Codex Agent Instructions

이 프로젝트는 **WIZ(Season) 프레임워크** 기반 웹 애플리케이션이다. 전체 개발 인스트럭션은 `.github/copilot-instructions.md`에 정의되어 있으며, 이 문서는 Codex 에이전트용 요약이다.

> **필독**: 작업 전 반드시 `.github/copilot-instructions.md`를 읽어라. 1400줄 분량의 완전한 개발 규칙·API 참조·트러블슈팅이 포함되어 있다.

---

## Codex 적용/배포

이 repo는 Codex CLI 재적용용 설정을 포함한다.

- `.codex/config.toml` — MCP와 multi-agent baseline
- `.codex/agents/` — Codex가 직접 로드하는 TOML child agent role 설정
- `.agents/skills/` — 설치된 non-system Codex skill 전체 스냅샷
- `.agents/ecc-agents/` — ECC upstream Markdown agent 템플릿
- `.agents/kiro-agents/` — Kiro agent 템플릿
- `agents/`, `skills/`, `commands/`, `rules/`, `hooks/`, `scripts/`, `contexts/`, `mcp-configs/` — ECC 원본 구조 호환용 snapshot
- `.codex-plugin/plugin.json` — Codex plugin manifest
- `.claude-plugin/plugin.json` — Claude plugin manifest 보존본
- `.agents/plugins/marketplace.json` — local marketplace catalog
- `scripts/sync-codex-config.sh` — 위 설정을 `~/.codex/`로 병합
- `scripts/wiz-mcp-launcher.sh` — VS Code WIZ 확장을 찾아 WIZ MCP 실행

새 환경에서 적용:

```bash
scripts/sync-codex-config.sh
```

MCP baseline을 강제로 갱신해야 하면:

```bash
scripts/sync-codex-config.sh --update-mcp
```

WIZ MCP는 `.vscode/mcp.json`의 WIZ 확장 설정과 같은 서버를 사용한다. Codex에서는 `scripts/wiz-mcp-launcher.sh`가 설치된 `season-framework.wiz-vscode` 확장을 자동 탐색한다.

주의: ECC upstream의 Markdown agent 템플릿은 Codex-native TOML role과 형식이 다르다. 그대로 배포는 하되, Codex child agent로 활성화하려면 `.codex/agents/*.toml` 형식으로 변환해야 한다.

주의: Claude식 `commands/`, `hooks/`, `rules/`는 Codex에서 동일하게 자동 실행되지 않는다. `scripts/sync-codex-config.sh`는 `commands/*.md`를 Codex prompt shim으로 변환하고, 나머지는 `~/.codex/ecc-assets/`에 보존한다.

---

## 프로젝트 구조

```
/opt/app/
├── config/              # 프레임워크 config (boot.py — 수정 주의)
├── public/              # 앱 엔트리포인트
├── project/main/        # 현재 활성 프로젝트
│   └── src/
│       ├── app/         # Angular 앱 (page.*/layout.*/component.*)
│       ├── controller/  # 백엔드 전처리 (인증/권한)
│       ├── model/       # DB/Struct 모델
│       ├── route/       # REST API 라우트
│       └── portal/      # 패키지 (재사용 모듈)
├── ide/                 # WIZ IDE 소스
├── plugin/              # 플러그인
├── data/                # 정적 데이터 (boot.py /data/ 라우트로 서빙)
└── .github/             # 인스트럭션·문서
```

## MCP 도구 사용 (필수)

이 프로젝트에는 WIZ MCP 서버가 연결되어 있다. **앱 생성·파일 읽기/쓰기·빌드** 등은 반드시 MCP 도구를 우선 사용한다.

### MCP 도구 카테고리

| 카테고리 | 대상 경로 | 도구 접두사 |
|---------|----------|------------|
| Workspace | 워크스페이스 루트 | `wiz_workspace_*` |
| Project | `project/{name}/` | `wiz_project_*` |
| Source | `src/app/`, `src/route/`, `src/controller/` | `wiz_source_*` |
| Package | `src/portal/{package}/` | `wiz_package_*` |

### Source vs Package 구분 (혼용 금지)

- `src/portal/` 하위 → **`wiz_package_*`** 도구
- `src/app/`, `src/route/` 등 → **`wiz_source_*`** 도구

## 핵심 규칙 요약

1. **wiz.response는 try 블록 바깥에서 호출** — `ResponseException`이 `except`에 잡힘
2. **Pug `#ref=""`** — 반드시 빈 문자열 값 명시 (NG0301 방지)
3. **Tailwind 소수점/슬래시 클래스** — `class=""` 속성 방식 필수
4. **Pug 멀티라인 속성** — 첫 속성은 `(`와 같은 줄에
5. **`:host` 스타일 필수** — Page/Layout의 `view.scss`에 `:host { display: block; height: 100%; }`
6. **service.render() 호출 필수** — 상태 변경 후 UI 갱신
7. **빌드**: `wiz_project_build` (새 API 함수 추가/삭제 시 `clean: true`)
8. **서버 재시작 금지** — hot-reload 지원
9. **현재 프로젝트만 수정** — 다른 프로젝트 접근 금지

## API 참조 (빠른 참고)

```python
# 백엔드 (api.py, controller.py)
wiz.model("portal/{pkg}/{name}")        # Model 로딩
wiz.request.query("key", "default")     # 요청 파라미터 (항상 문자열)
wiz.response.status(200, data=result)   # JSON 응답 (즉시 종료)
wiz.session.get("key")                  # 세션 조회
wiz.controller("base")                  # Controller 상속
wiz.project.fs("data")                  # 파일시스템
```

```typescript
// 프론트엔드 (view.ts)
import { Service } from '@wiz/libs/portal/season/service';
await wiz.call("functionName", { key: value }); // api.py 함수 호출
await this.service.render();  // UI 갱신 (필수)
```

## 커스텀 인스트럭션

`.github/custom/custom-instructions.md`가 있으면 추가 참조. 충돌 시 Custom 우선.

## Task 관리

`작업 수행해줘` 요청 시 `.github/task/todo.md`를 읽어 순서대로 수행.
