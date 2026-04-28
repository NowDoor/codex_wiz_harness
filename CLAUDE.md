# WIZ Framework — Agent Instructions

이 프로젝트는 **WIZ(Season) 프레임워크** 기반 웹 애플리케이션이다.

> **필독**: 작업 전 반드시 `.github/copilot-instructions.md`를 읽어라. 1400줄 분량의 완전한 개발 규칙·API 참조·트러블슈팅이 포함되어 있다.

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

이 프로젝트에 WIZ MCP 서버가 설정되어 있다. **앱 생성·파일 읽기/쓰기·빌드** 등은 반드시 MCP 도구를 우선 사용한다.

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

1. **wiz.response는 try 블록 바깥에서 호출** — `ResponseException`이 `except Exception`에 잡힘
2. **Pug `#ref=""`** — 반드시 빈 문자열 값 명시 (NG0301 방지)
3. **Tailwind 소수점/슬래시 클래스** — `class=""` 속성 방식 필수
4. **Pug 멀티라인 속성** — 첫 속성은 `(`와 같은 줄에
5. **`:host` 스타일 필수** — Page/Layout의 `view.scss`에 `:host { display: block; height: 100%; }`
6. **service.render() 호출 필수** — 상태 변경 후 UI 갱신
7. **빌드**: `wiz_project_build` MCP 도구 (새 API 함수 추가/삭제 시 `clean: true`)
8. **서버 재시작 금지** — hot-reload 지원
9. **현재 프로젝트만 수정** — 다른 프로젝트 접근 금지
10. **`bare except` 금지** — 반드시 `except Exception as e:` 사용
11. **wiz.request.query()는 항상 문자열** — 숫자 비교 전 `int()` 변환 필수

## API 참조 (빠른 참고)

```python
# 백엔드 (api.py, controller.py)
wiz.model("portal/{pkg}/{name}")        # Model 로딩
wiz.request.query("key", "default")     # 요청 파라미터 (항상 문자열)
wiz.request.query("key", True)          # 필수 파라미터 (없으면 400)
wiz.response.status(200, data=result)   # JSON 응답 (즉시 종료 — ResponseException)
wiz.session.get("key")                  # 세션 조회
wiz.controller("base")                  # Controller 상속
wiz.project.fs("data")                  # 파일시스템
```

```typescript
// 프론트엔드 (view.ts)
import { Service } from '@wiz/libs/portal/season/service';
constructor(public service: Service) { }
await this.service.init();
await wiz.call("functionName", { key: value }); // api.py 함수 호출
await this.service.render();  // UI 갱신 (필수)
```

## wiz.response 패턴 (중요)

```python
# ❌ 잘못된 패턴 — 200 응답이 except로 잡힘
def create():
    try:
        result = do_something()
        wiz.response.status(200, result)  # ResponseException → except
    except Exception as e:
        wiz.response.status(400, message=str(e))

# ✅ 올바른 패턴
def create():
    try:
        result = do_something()
    except Exception as e:
        wiz.response.status(400, message=str(e))
    wiz.response.status(200, result)
```

## 개발 순서

데이터 → 로직 → UI 순서:
1. DB Model(스키마) → Struct(비즈니스 로직)
2. Layout → Page 생성 → app.json 설정
3. view.ts/view.pug UI → api.py 백엔드
4. 빌드 (`wiz_project_build`)

## 커스텀 인스트럭션

`.github/custom/custom-instructions.md`가 있으면 추가 참조. 충돌 시 Custom 우선.

## Task 관리

`.github/task/todo.md`에 작업 항목 관리. `작업 수행해줘` 요청 시 순서대로 수행.
