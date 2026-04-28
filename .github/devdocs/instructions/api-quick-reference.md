# WIZ 핵심 API 빠른 참조

---

## 1. wiz 객체 (백엔드 Python)

```python
# Model/Config 로딩
model = wiz.model("portal/{pkg}/{name}")    # Model 변수가 반환됨
config = wiz.config("database")             # config/ 디렉토리의 설정 파일

# 요청
data = wiz.request.query()                  # 전체 요청 데이터 (dict)
value = wiz.request.query("key", "default") # 개별 키 조회
segment = wiz.request.match("/api/<action>")# URL 패턴 매칭
files = wiz.request.files()                 # 파일 업로드
# ⚠️ wiz.request.query()는 form-urlencoded와 query string만 파싱한다.
#    JSON body (Content-Type: application/json)는 파싱하지 않으므로,
#    직접 fetch() 호출 시 반드시 FormData 또는 URLSearchParams를 사용한다.
#    wiz.call()은 내부적으로 form-urlencoded를 사용하므로 이 문제가 없다.
#    상세: devdocs/troubleshooting/server-side/api/json-body-parsing.md

# 응답
wiz.response.status(200, data=result)       # JSON 응답 (kwargs로 전달)
wiz.response.status(400, message="Error")   # 에러 응답
wiz.response.redirect("/path")              # 리다이렉트
wiz.response.download(filepath)             # 파일 다운로드

# 세션 (Controller에서 초기화 후 사용)
wiz.session = wiz.model("portal/{package}/session").use()
wiz.session.get("key")                      # 조회
wiz.session.set(key="value")                # 설정
wiz.session.has("key")                      # 존재 확인

# Controller/파일시스템
ctrl = wiz.controller("base")               # Controller 상속
fs = wiz.project.fs("data", "uploads")      # 프로젝트 파일시스템
```

## 2. 프론트엔드 (view.ts)

```typescript
// 프로젝트 공통 Service (필수) — 패키지명은 프로젝트에 맞게 대체
import { Service } from '@wiz/libs/portal/{package}/service';
constructor(public service: Service) { }
await this.service.init();                  // 초기화 (ngOnInit에서 호출)
await this.service.render();                // 화면 갱신 (detectChanges)

// API 호출 (api.py 함수)
let res = await wiz.call("search", { page: 1, text: "" });
// res.code: HTTP 상태코드, res.data: 응답 데이터

// Service 하위 모듈
this.service.alert.show({title, message, action});  // 알림 다이얼로그
this.service.loading.show();                // 로딩 표시
this.service.loading.hide();                // 로딩 숨김
this.service.href("/path");                 // 라우팅
this.service.auth                           // 인증 상태
this.service.trigger.bind(key, value)       // 이벤트 바인딩
```

## 3. 상세 API 문서

- `.github/devdocs/wiz-docs/api/` 폴더의 README.md를 참조한다.

> ⚠️ 위 예제의 `{package}`는 프로젝트에서 사용하는 실제 패키지명으로 대체한다. Session, ORM, Service 등 패키지별 세부 API(메서드 시그니처, 파라미터, 반환값)는 버전에 따라 다를 수 있으므로, 반드시 해당 패키지의 `src/portal/{package}/README.md`를 기준으로 구현한다.
