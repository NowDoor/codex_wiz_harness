# SSE Generator 내 wiz 컨텍스트 접근 불가

- **카테고리**: server-side / python-runtime
- **키워드**: SSE, Generator, `wiz.request`, `wiz.session`, Request Context, `yield`
- **심각도**: 런타임 오류 (AttributeError / RuntimeError)

## 증상

SSE(Server-Sent Events) 응답을 위한 Generator 함수 내부에서 `wiz.request`, `wiz.session` 등에 접근하면 오류 발생.

```python
# ❌ Generator 내부에서 wiz.request 접근 → 오류
def stream():
    query = wiz.request.query("query", "")  # Request Context 이탈
    yield f"data: {query}\n\n"
```

## 원인

WIZ의 `wiz.request`, `wiz.session`은 Flask의 Request Context에 바인딩되어 있다. Generator는 지연 실행(lazy evaluation)되므로, 실제 `yield` 시점에는 이미 Request Context가 종료된 상태이다.

## 해결

**Generator 외부(Request Context 내)에서 필요한 값을 미리 추출**하여 Generator에 전달한다.

```python
# ✅ Request Context에서 미리 추출
query = wiz.request.query("query", "")
session_user = wiz.session.get("user", None)
config = wiz.model("config").load()

def stream():
    # 이미 추출된 변수 사용 — wiz 객체 접근 없음
    yield f"data: {json.dumps({'query': query})}\n\n"
    # ... 비즈니스 로직 ...
    yield "data: {\"type\": \"done\"}\n\n"

wiz.response.sse(stream())
```

## 핵심 원칙

Generator 함수 내부에서는 아래 객체에 **절대 접근하지 않는다**:
- `wiz.request` (query, form, files 등)
- `wiz.session` (get, set 등)
- `wiz.response` (status, redirect 등 — `yield`만 사용)
