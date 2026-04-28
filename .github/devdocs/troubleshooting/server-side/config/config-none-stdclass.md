# Config 키 누락 시 stdClass(None) TypeError

- **카테고리**: server-side / config
- **키워드**: `config/season.py`, `stdClass`, `NoneType`, `TypeError`, config 키 누락
- **심각도**: 런타임 오류

## 증상

패키지가 config에서 dict 값을 기대하는데, `config/season.py`에 해당 키가 없으면:

```
TypeError: 'NoneType' object is not iterable
```

또는 `stdClass(None)` 생성 시 유사한 TypeError 발생.

## 원인

패키지 Model이 `wiz.config("season")`에서 특정 키를 조회할 때, **존재하지 않는 키는 `None`을 반환**한다. 이 `None` 값을 `stdClass(None)`으로 감싸면 내부에서 iterable로 처리하려다 TypeError 발생.

```python
# 패키지 내부 코드 예시
config = wiz.config("season")
saml_config = config.saml              # season.py에 saml이 없으면 → None
info = stdClass(saml_config)            # stdClass(None) → TypeError!
```

## 해결

`config/season.py`에 패키지가 기대하는 **모든 필수 키를 정의**한다. dict 타입이 필요한 키는 빈 dict `{}`라도 정의해야 한다.

```python
# config/season.py
# ✅ 패키지가 기대하는 키를 빈 값이라도 정의
saml = {
    "sp": {},
    "idp": {}
}
```

## 방어적 코딩 패턴

패키지나 Struct에서 config 값을 사용할 때는 방어 코드를 추가한다:

```python
# ✅ 기본값으로 빈 dict 제공
config = wiz.config("season")
saml_config = getattr(config, 'saml', {}) or {}
```
