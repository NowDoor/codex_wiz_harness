# Config 함수명과 패키지 DEFAULT_VALUES 키 불일치

- **카테고리**: server-side / config
- **키워드**: `config/season.py`, `DEFAULT_VALUES`, 함수명, 키 불일치, `None`, 무음 실패
- **심각도**: 런타임 (무음 실패)

## 증상

`config/season.py`에 커스텀 함수를 정의했는데, 패키지 코드에서 해당 함수를 찾지 못하고 `None`을 반환한다. 에러 로그 없이 기능이 작동하지 않는다.

```python
# config/season.py
def saml_acs(saml_response):         # ← 함수명: saml_acs
    user_data = parse_response(saml_response)
    return user_data
```

```python
# portal/season/model/config.py (패키지 내부)
DEFAULT_VALUES = {
    "auth_saml_acs": None,           # ← 키: auth_saml_acs (접두사 auth_ 포함)
    ...
}
# config에서 "auth_saml_acs" 키로 조회 → season.py에는 "saml_acs"만 있음 → None 반환
```

## 원인

패키지의 config 로더(`wiz.config("season")`)는 `config/season.py`의 전역 변수와 함수를 **이름(키)으로** 조회한다. 패키지 코드의 `DEFAULT_VALUES`에 정의된 키 이름과 `season.py`의 함수/변수 이름이 **정확히 일치하지 않으면**, 기본값(`None`)이 반환된다. 에러가 발생하지 않으므로 디버깅이 어렵다.

## 해결

1. 패키지 코드의 `DEFAULT_VALUES` 또는 config 조회 키를 먼저 확인한다.
2. `config/season.py`의 함수/변수 이름을 **패키지가 기대하는 키 이름과 정확히 일치**시킨다.

```python
# ✅ 패키지가 기대하는 키: auth_saml_acs
def auth_saml_acs(saml_response):    # ← 정확한 키 이름
    user_data = parse_response(saml_response)
    return user_data
```

## 디버깅 방법

config 값이 `None`인지 의심되면, 패키지의 model 파일에서 `DEFAULT_VALUES` dict를 검색한다:

```bash
grep -r "DEFAULT_VALUES" src/portal/{package}/model/
```

## 적용 범위

- `config/season.py`의 모든 커스텀 함수/변수
- `config/works.py`, `config/wiki.py` 등 패키지별 config 파일에도 동일 적용
- 특히 **인증 관련 함수**(auth_login, auth_saml_acs 등)에서 빈번히 발생
