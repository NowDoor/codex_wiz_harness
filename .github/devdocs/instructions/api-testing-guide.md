# WIZ API 테스트 가이드 (curl)

WIZ App의 api.py 함수를 터미널에서 직접 테스트하는 방법이다. WIZ는 Flask 세션 기반 인증을 사용하므로, 올바른 쿠키를 구성해야 한다.

---

## 1. 필수 쿠키

| 쿠키 | 역할 | 예시 값 |
|------|------|---------|
| `session` | Flask 서명 세션 (사용자 인증 정보) | `.eJyr...` (아래 스크립트로 생성) |
| `season-wiz-project` | 대상 프로젝트 선택 (기본값: `main`) | `dev` |
| `season-wiz-devmode` | 개발 모드 (기본값: `false`, 비main 프로젝트는 자동 `true`) | `true` |

## 2. 세션 쿠키 생성

Flask 세션 쿠키는 `secret_key`로 서명되어야 한다. 아래 스크립트로 생성한다.

```bash
python3 -c "
from flask import Flask
app = Flask(__name__)
app.secret_key = 'season-wiz-secret'   # config/boot.py 확인
with app.test_request_context():
    from flask import session as sess
    sess['id'] = 'user_id_here'
    sess['email'] = 'user@example.com'
    sess['role'] = 'admin'
    sess['name'] = 'username'
    from flask.sessions import SecureCookieSessionInterface
    si = SecureCookieSessionInterface()
    s = si.get_signing_serializer(app)
    cookie_val = s.dumps(dict(sess))
    print(cookie_val)
"
```

## 3. API URL 패턴

**App api.py (함수 기반):**
```
http://localhost:{PORT}{BASEURI}/api/{APP_ID}/{FUNCTION_NAME}
```

- **PORT**: WIZ 서버 포트 (기본 3000, `config/boot.py`의 `port` 확인)
- **BASEURI**: IDE base URI (기본 `/wiz`, `config/boot.py`의 `baseuri` 확인)
- **APP_ID**: `app.json`의 `id` (예: `page.deploy`, `page.project`)
- **FUNCTION_NAME**: `api.py`에 정의된 함수명 (예: `search`, `sync`)

**Route controller.py (스크립트 방식):**
```
http://localhost:{PORT}/{ROUTE_PATH}
```

- **BASEURI 없음**: Route는 `/wiz` prefix 없이 직접 접근한다

## 4. curl 테스트 템플릿

```bash
# 세션 쿠키 변수 설정
SESSION="<위 스크립트로 생성한 쿠키 값>"

# 일반 API 호출 (GET)
curl -s -b "session=$SESSION; season-wiz-project=dev; season-wiz-devmode=true" \
  "http://localhost:3000/wiz/api/{app_id}/{function}"

# 파라미터 포함 (POST, form-urlencoded)
# ⚠️ wiz.request.query()는 JSON body를 파싱하지 않는다. 반드시 form-urlencoded 사용.
# 파싱 실패 상세: devdocs/troubleshooting/server-side/api/json-body-parsing.md
curl -s -b "session=$SESSION; season-wiz-project=dev; season-wiz-devmode=true" \
  -d "key=value&page=1" \
  "http://localhost:3000/wiz/api/{app_id}/{function}"

# ❌ 금지: JSON Content-Type → wiz.request.query()가 빈 dict 반환
# curl -H "Content-Type: application/json" -d '{"key": "value"}' ...
```

**Route 테스트:**
```bash
# Route는 BASEURI 없이 직접 접근 (main 프로젝트: 쿠키 불필요)
curl -s "http://localhost:3000/{route_path}"

# dev 등 프로젝트 지정 필요 시
curl -s -b "season-wiz-project=dev; season-wiz-devmode=true" \
  "http://localhost:3000/{route_path}"
```

## 5. 에러 로그 확인

```bash
cat /var/log/wiz/main

# 로그 초기화 후 재테스트
echo "" > /var/log/wiz/main
curl ... # API 호출
cat /var/log/wiz/main
```

## 6. SSE 스트리밍 시 주의사항

WIZ에서 SSE(Server-Sent Events)를 구현할 때, Flask Response의 **generator는 request context 밖에서 실행**된다.

> 📎 Generator 내 wiz 컨텍스트 접근 불가 상세: [troubleshooting/server-side/python-runtime/sse-generator-context.md](../troubleshooting/server-side/python-runtime/sse-generator-context.md)

### 서버 패턴

```python
def my_sse():
    flask = wiz.response._flask
    # ✅ request context 안에서 미리 추출
    user_id = wiz.session.user_id()
    
    def generate():
        # ❌ 여기서 wiz.session, wiz.request 접근 불가
        try:
            for item in process():
                yield f"data: {json.dumps(item)}\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'type':'error','message':str(e)})}\n\n"
    
    resp = flask.Response(generate(), mimetype='text/event-stream')
    resp.headers['Cache-Control'] = 'no-cache'
    resp.headers['X-Accel-Buffering'] = 'no'
    wiz.response.response(resp)
```

### 프론트엔드 SSE 수신 패턴

`wiz.call()`은 SSE 스트리밍을 지원하지 않는다. 직접 `fetch()` + `ReadableStream`을 사용한다.

**중요**: `wiz.request.query()`는 JSON body를 파싱하지 않으므로, fetch 시 `FormData` 또는 `URLSearchParams`를 사용한다.

```typescript
async streamAPI(functionName: string, params: any) {
    const formData = new FormData();
    for (const [k, v] of Object.entries(params)) {
        formData.append(k, String(v));
    }
    const response = await fetch(
        `/wiz/api/${APP_ID}/${functionName}`,
        { method: 'POST', body: formData }
    );
    const reader = response.body!.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n\n');
        buffer = lines.pop() || '';
        for (const line of lines) {
            if (line.startsWith('data: ')) {
                const event = JSON.parse(line.slice(6));
                this.handleEvent(event);
            }
        }
    }
}
```

### 취소(AbortController)

```typescript
this.abortController = new AbortController();
const response = await fetch(url, { ..., signal: this.abortController.signal });
// 취소 시:
this.abortController.abort();
```

### 장시간 프로세스 취소 패턴

**서버(Python)**: 모듈 레벨 dict로 활성 프로세스를 추적

```python
_active_processes = {}

def stream_method(self):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, ...)
    _active_processes[self.id] = proc
    try:
        for line in iter(proc.stdout.readline, ''):
            if self.id not in _active_processes:
                proc.kill()
                yield {"type": "error", "message": "Cancelled"}
                return
            yield {"type": "log", "message": line.rstrip()}
    finally:
        _active_processes.pop(self.id, None)

@staticmethod
def cancel_process(id):
    proc = _active_processes.pop(id, None)
    if proc:
        proc.kill()
        return True
    return False
```

**클라이언트(TypeScript)**: `AbortController`로 SSE fetch를 중단하고, 서버에 cancel API를 호출

```typescript
async cancel() {
    this.abortController?.abort();
    await wiz.call("cancel", { id });
}
```
