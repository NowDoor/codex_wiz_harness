# exec() 환경에서 함수 정의 순서 의존성

- **카테고리**: server-side / python-runtime
- **키워드**: `exec()`, `NameError`, 함수 정의 순서, `controller.py`, Route, 헬퍼 함수
- **심각도**: 런타임 오류 (NameError)

## 증상

Route `controller.py`나 `api.py`에서 하단에 정의된 함수를 상단에서 호출하면 `NameError: name 'myHelper' is not defined` 발생.

```python
# ❌ NameError — processData가 아직 정의되지 않음
segment = wiz.request.match("/api/data/<action>")
if segment.action == "list":
    result = processData(items)    # NameError!
    wiz.response.status(200, data=result)

def processData(items):
    return [transform(i) for i in items]
```

## 원인

WIZ는 모든 Python 파일을 `exec()`로 **순차 실행**한다. 일반 Python 모듈에서는 함수 정의 순서와 무관하게 호출할 수 있지만(`import` 시 전체 파일이 먼저 파싱됨), `exec()` 환경에서는 코드가 **위에서 아래로 한 줄씩** 실행되므로, 호출 시점에 해당 함수가 정의되어 있지 않으면 `NameError`가 발생한다.

이 문제는 특히 **Route `controller.py`**에서 자주 발생한다. Route는 함수 기반이 아닌 **스크립트 방식**으로 실행되므로, 최상위 코드(`wiz.request.match()` 분기)가 즉시 실행된다.

## 해결

**헬퍼 함수는 반드시 호출 코드보다 위에 정의**한다. Route `controller.py`에서는 `wiz.request.match()` 분기 전에 모든 헬퍼 함수를 정의한다.

```python
# ✅ 헬퍼 함수를 먼저 정의
def processData(items):
    return [transform(i) for i in items]

def transform(item):
    return {"id": item["id"], "name": item["name"]}

# 그 다음 라우팅 분기
segment = wiz.request.match("/api/data/<action>")
if segment.action == "list":
    result = processData(items)
    wiz.response.status(200, data=result)
```

## 적용 범위

| 파일 유형 | 실행 방식 | 영향 여부 |
|-----------|----------|----------|
| Route `controller.py` | 스크립트 (순차 실행) | ✅ 영향 받음 |
| App `api.py` | 함수 기반 (`def search():`) | ⚠️ 함수 내에서 다른 함수 호출 시 영향 |
| `socket.py` | Controller 클래스 메서드 | ⚠️ 클래스 외부 헬퍼 참조 시 영향 |

> **App `api.py`에서는** 개별 함수(`def search():`)가 호출 시점에 실행되므로, 같은 파일 내 다른 함수는 파일 로드 시점에 모두 정의된다. 단, **함수 외부의 최상위 코드**(모듈 레벨 초기화)에서 아래쪽 함수를 참조하면 동일 문제 발생.
