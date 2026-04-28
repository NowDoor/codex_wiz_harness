# WIZ 트러블슈팅 가이드

WIZ 프레임워크의 `exec()` 기반 런타임, Pug 템플릿 엔진, Angular 통합 환경에서 반복적으로 발생하는 **프레임워크 고유 이슈**와 **해결 패턴**을 카테고리별로 정리한다.

---

## 디렉토리 구조

```
devdocs/troubleshooting/
├── README.md                              ← 현재 문서 (목차 + 작성 요령)
├── web-ui/                                # 프론트엔드 (브라우저·빌드 타임)
│   ├── pug/                               #   Pug 템플릿 엔진
│   │   ├── decimal-slash-class.md         #     소수점/슬래시 클래스 파싱
│   │   ├── multiline-attributes.md        #     멀티라인 속성 파싱
│   │   └── template-ref-empty-value.md    #     #ref="" 빈 문자열 필수
│   ├── angular/                           #   Angular 컴포넌트·서비스
│   │   ├── host-element-styling.md        #     :host 스타일 필수
│   │   ├── styles-import-missing.md       #     styles.scss @import 누락
│   │   └── service-render-missing.md      #     service.render() 누락 시 UI 미갱신
│   └── css/                               #   CSS/레이아웃 패턴
│       └── overflow-clipping-dropdown.md  #     overflow 부모 드롭다운 클리핑
└── server-side/                           # 백엔드 (WIZ 런타임)
    ├── python-runtime/                    #   exec() 환경·모듈 시스템
    │   ├── exec-module-cache.md           #     모듈 캐시 문제
    │   ├── exec-function-order.md         #     exec() 함수 정의 순서 의존성
    │   ├── sse-generator-context.md       #     SSE Generator wiz 컨텍스트
    │   └── file-variable.md              #     __file__ 미정의
    ├── api/                               #   wiz.request·wiz.response 계층
    │   ├── json-body-parsing.md           #     JSON body 미파싱
    │   ├── portal-wizcall-routing.md      #     Portal App wiz.call() 라우팅 404
    │   ├── response-exception-pattern.md  #     ResponseException try/except 충돌
    │   └── string-membership-security.md  #     문자열 in 연산 권한 우회 보안
    ├── config/                            #   Config 파일 관련
    │   ├── config-key-mismatch.md         #     Config 함수명/키 불일치
    │   └── config-none-stdclass.md        #     Config 키 누락 시 NoneType 에러
    └── build/                             #   WIZ 빌드 시스템
        └── api-function-cache.md          #     API 함수 캐시 (Clean Build)
```

---

## 이슈 목차

### web-ui — 프론트엔드

| # | 이슈 | 파일 | 키워드 | 심각도 |
|---|------|------|--------|--------|
| 1 | Pug 소수점/슬래시 클래스 파싱 실패 | [decimal-slash-class.md](web-ui/pug/decimal-slash-class.md) | `gap-1.5`, `w-1/2`, dot notation | 빌드 실패 |
| 2 | Pug 멀티라인 속성 파싱 실패 | [multiline-attributes.md](web-ui/pug/multiline-attributes.md) | `*ngIf`, 콤마, 여는 괄호 | 빌드 실패 |
| 3 | Pug `#ref=""` 빈 문자열 필수 | [template-ref-empty-value.md](web-ui/pug/template-ref-empty-value.md) | `#ref`, `NG0301`, 템플릿 참조 | 런타임 오류 |
| 4 | Angular `:host` 스타일 필수 | [host-element-styling.md](web-ui/angular/host-element-styling.md) | `:host`, `display: block`, 레이아웃 깨짐 | 런타임 |
| 5 | `styles.scss` 패키지 @import 누락 | [styles-import-missing.md](web-ui/angular/styles-import-missing.md) | `@import`, 번들, CSS 미적용, 다크모드 | 런타임 (무음) |
| 6 | `service.render()` 누락 시 UI 미갱신 | [service-render-missing.md](web-ui/angular/service-render-missing.md) | `detectChanges()`, 이벤트 핸들러 | 런타임 |
| 7 | `overflow` 부모 드롭다운 클리핑 | [overflow-clipping-dropdown.md](web-ui/css/overflow-clipping-dropdown.md) | `overflow`, `fixed`, 드롭다운 잘림 | 런타임 |

### server-side — 백엔드

| # | 이슈 | 파일 | 키워드 | 심각도 |
|---|------|------|--------|--------|
| 8 | exec() 모듈 캐시 문제 | [exec-module-cache.md](server-side/python-runtime/exec-module-cache.md) | `sys.modules`, `importlib`, 변경 미반영 | 런타임 |
| 9 | exec() 함수 정의 순서 의존성 | [exec-function-order.md](server-side/python-runtime/exec-function-order.md) | `NameError`, 헬퍼 함수 순서, Route | 런타임 오류 |
| 10 | SSE Generator wiz 컨텍스트 접근 불가 | [sse-generator-context.md](server-side/python-runtime/sse-generator-context.md) | `wiz.request`, Generator, `yield` | 런타임 오류 |
| 11 | `__file__` 변수 사용 불가 | [file-variable.md](server-side/python-runtime/file-variable.md) | `NameError`, `exec()`, `wiz.project.fs()` | 런타임 오류 |
| 12 | JSON Body 미파싱 | [json-body-parsing.md](server-side/api/json-body-parsing.md) | `wiz.request.query()`, `FormData` | 런타임 (무음) |
| 13 | ResponseException try/except 충돌 | [response-exception-pattern.md](server-side/api/response-exception-pattern.md) | `wiz.response.status()`, `try/except` | 런타임 오류 |
| 14 | API 함수 캐시 (Clean Build) | [api-function-cache.md](server-side/build/api-function-cache.md) | 새 `def`, 404, `clean build` | 런타임 404 |
| 15 | Portal App wiz.call() 라우팅 404 | [portal-wizcall-routing.md](server-side/api/portal-wizcall-routing.md) | `wiz.call`, `api.py`, Portal App, 404 | 런타임 오류 |
| 16 | `not in 'string'` 권한 검증 보안 취약 | [string-membership-security.md](server-side/api/string-membership-security.md) | `not in`, 문자열 비교, 권한 우회 | 보안 취약점 |
| 17 | Config 함수명/키 불일치 | [config-key-mismatch.md](server-side/config/config-key-mismatch.md) | `DEFAULT_VALUES`, 함수명, 무음 실패 | 런타임 (무음) |
| 18 | Config 키 누락 시 NoneType 에러 | [config-none-stdclass.md](server-side/config/config-none-stdclass.md) | `stdClass(None)`, `TypeError` | 런타임 오류 |

---

## 트러블슈팅 문서 작성 요령

새로운 트러블슈팅 이슈를 등록할 때 아래 규칙을 따른다.

### 카테고리 분류 기준

| 대분류 | 기준 | 하위 카테고리 |
|--------|------|--------------|
| **web-ui** | 브라우저·빌드 타임에서 발생하는 이슈 | `pug/` · `angular/` · `typescript/` |
| **server-side** | WIZ 런타임(Python)에서 발생하는 이슈 | `python-runtime/` · `api/` · `build/` |

> 새로운 하위 카테고리가 필요하면 해당 대분류 아래에 폴더를 추가하고, 이 README의 디렉토리 구조와 목차를 갱신한다.

### 파일 경로 규칙

```
devdocs/troubleshooting/{대분류}/{하위카테고리}/{slug}.md
```

- **slug**: 이슈를 식별할 수 있는 kebab-case 이름 (예: `decimal-slash-class`, `exec-module-cache`)
- 하나의 파일 = 하나의 이슈 (복합 이슈는 분리)

### 문서 템플릿

```markdown
# {이슈 제목}

- **카테고리**: {대분류} / {하위카테고리}
- **키워드**: `keyword1`, `keyword2`, `keyword3`
- **심각도**: {빌드 실패 | 런타임 오류 | 런타임 (무음 실패) | 성능 저하}

## 증상
{사용자가 관찰하는 현상. 에러 메시지, 재현 코드 포함.}

## 원인
{WIZ 프레임워크의 어떤 메커니즘 때문에 발생하는지 설명.}

## 해결
{구체적인 수정 방법. ❌ 잘못된 코드 → ✅ 올바른 코드 대비 필수.}

## 적용 범위 (선택)
{이 이슈가 영향을 주는 범위나 추가 주의사항.}
```

### 필수 요소

1. **메타데이터 헤더**: 카테고리, 키워드, 심각도를 반드시 포함
2. **증상-원인-해결 3단 구조**: 빠른 진단과 해결이 목적
3. **코드 예시**: ❌/✅ 대비 코드 블록 필수
4. **키워드**: 검색 가능한 에러 메시지, 함수명, 패턴 포함

### 등록 후 체크리스트

- [ ] 이 README.md의 **디렉토리 구조**에 파일 경로 추가
- [ ] 이 README.md의 **이슈 목차** 테이블에 행 추가
- [ ] 새 카테고리 폴더 생성 시 디렉토리 구조 트리 갱신
