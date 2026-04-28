# wiz.response ResponseException — try/except 충돌

- **카테고리**: server-side / api
- **키워드**: `wiz.response.status()`, `ResponseException`, `try/except`, 정상 응답 catch
- **심각도**: 런타임 오류 (정상 응답이 에러로 처리됨)

## 증상

`wiz.response.status(200, result)`를 `try` 블록 안에서 호출하면, 성공 응답이 전송되지 않고 `except` 블록으로 빠져 400 에러가 반환된다.

```python
# ❌ 성공 응답(200)도 except로 빠짐
def create():
    try:
        result = struct.something.create(data)
        wiz.response.status(200, result)   # ResponseException raise → except로 이동
    except Exception as e:
        wiz.response.status(400, message=str(e))
```

## 원인

`wiz.response.status()`, `wiz.response.redirect()` 등은 내부적으로 **`ResponseException`을 raise**하여 현재 실행을 즉시 종료하고 응답을 반환한다. `ResponseException`은 `Exception`의 하위 클래스이므로, `except Exception`에 잡혀 정상 응답이 에러 핸들러로 들어간다.

## 해결

**`wiz.response` 호출을 `try` 블록 밖에 배치**한다.

```python
# ✅ wiz.response를 try 바깥에서 호출
def create():
    data = wiz.request.query("data", True)
    try:
        result = struct.something.create(data)
    except Exception as e:
        wiz.response.status(400, message=str(e))
    wiz.response.status(200, result)
```

```python
# ✅ 여러 단계가 있는 경우 — 변수에 저장 후 try 밖에서 응답
def update():
    try:
        item = struct.something.get(id)
        item.update(data)
        result = item.to_dict()
    except Exception as e:
        wiz.response.status(500, message=str(e))
    wiz.response.status(200, result)
```

## 핵심 원칙

- `wiz.response.status()` / `wiz.response.redirect()` = **즉시 종료** (return이 아닌 raise)
- **`try` 블록 안에서 절대 호출하지 않는다** (에러 핸들링용 except 안에서만 허용)
- `except` 안의 `wiz.response.status(400, ...)` — 이것은 에러 응답이므로 괜찮음 (어차피 종료)
