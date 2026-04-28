# `not in 'string'` 권한 검증 보안 취약점

- **카테고리**: server-side / api
- **키워드**: `not in`, 문자열 비교, 권한 우회, `!=`, 보안, role
- **심각도**: 보안 취약점

## 증상

Controller나 api.py에서 권한 검증이 우회되어 비인가 사용자가 접근 가능해진다.

```python
# ❌ 보안 취약 — 부분 문자열 매칭
role = wiz.session.get("role")
if role not in 'admin':
    wiz.response.status(401)
```

## 원인

Python에서 `in` 연산자를 **문자열**에 사용하면 **부분 문자열 검사**가 수행된다. `'a' in 'admin'`은 `True`이므로, role이 `'a'`, `'d'`, `'m'`, `'i'`, `'n'`, `'ad'`, `'mi'` 등 한 글자~부분 문자열이면 **권한 체크를 통과**한다.

```python
'a' in 'admin'      # True — 우회!
'admin' in 'admin'  # True — 정상
'user' in 'admin'   # False — 정상 거부
'ad' in 'admin'     # True — 우회!
```

## 해결

**동등 비교(`!=`, `==`)** 또는 **리스트 `in`** 을 사용한다.

```python
# ✅ 정확한 동등 비교
if role != 'admin':
    wiz.response.status(401)

# ✅ 여러 역할 허용 시 리스트/튜플 사용
if role not in ['admin', 'superadmin']:
    wiz.response.status(401)
```

## 적용 범위

- `src/controller/*.py`의 모든 권한 검증 코드
- `api.py`의 역할 기반 접근 제어
- 모든 문자열 값에 대한 `in` 연산에 주의 (role, status, type 등)
