# `__file__` 변수 사용 불가

- **카테고리**: server-side / python-runtime
- **키워드**: `__file__`, `NameError`, `exec()`, `wiz.project.fs()`, 경로
- **심각도**: 런타임 오류 (NameError)

## 증상

Python 파일에서 `__file__`을 사용하면 `NameError: name '__file__' is not defined` 발생.

```python
# ❌ NameError 발생
import os
current_dir = os.path.dirname(os.path.abspath(__file__))
```

## 원인

WIZ는 모든 Python 파일을 `exec()`로 실행한다. `exec()` 환경에서는 `__file__` 전역 변수가 정의되지 않는다 (일반 Python `import` / 직접 실행과 다름).

## 해결

`wiz.project.fs()`를 사용하여 프로젝트 기준 절대 경로를 획득한다.

```python
# ✅ WIZ API로 경로 획득
fs = wiz.project.fs()
base_path = fs.abspath()                    # 프로젝트 루트 절대 경로
model_path = fs.abspath("src/model")        # 하위 경로 지정 가능
```

## config에서 경로 설정

`season.py` 등 config 파일에서 데이터 경로를 설정할 때도 동일하게 적용:

```python
# config/season.py
# ❌ __file__ 사용 불가
# base = os.path.dirname(__file__)

# ✅ 상대 경로 또는 절대 경로 문자열 직접 지정
agent_tools_path = "data/tools"
```
