# wiz.request.query()가 JSON Body를 파싱하지 않음

- **카테고리**: server-side / api
- **키워드**: `wiz.request.query()`, `application/json`, `FormData`, `URLSearchParams`, POST
- **심각도**: 런타임 (값이 기본값으로 반환됨, 무음 실패)

## 증상

프론트엔드에서 `Content-Type: application/json`으로 POST 요청을 보냈는데, `wiz.request.query()`가 값을 읽지 못하고 기본값만 반환한다.

```typescript
// 프론트엔드 — JSON 방식 (❌ 서버에서 파싱 실패)
await this.service.request.post('/api/endpoint', { key: 'value' });
```

## 원인

`wiz.request.query()`는 내부적으로 Flask의 `request.args`와 `request.form`만 조회한다. `request.json` (JSON body)은 파싱하지 않는다.

## 해결

프론트엔드에서 `application/x-www-form-urlencoded` 또는 `FormData` 방식으로 전송한다.

```typescript
// ✅ FormData 방식
const fd = new FormData();
fd.append('key', 'value');
await this.service.request.post('/api/endpoint', fd);

// ✅ URLSearchParams 방식
const params = new URLSearchParams();
params.append('key', 'value');
await fetch('/api/endpoint', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString()
});
```

## 백엔드 대안

JSON body를 반드시 받아야 하는 경우, `wiz.request.query()` 대신 Flask의 `request.get_json()`을 직접 사용한다.

```python
import flask
data = flask.request.get_json(silent=True) or {}
value = data.get('key', '')
```
