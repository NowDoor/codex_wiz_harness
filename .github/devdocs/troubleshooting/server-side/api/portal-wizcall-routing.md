# Portal App wiz.call() 라우팅 404

- **카테고리**: server-side / api
- **키워드**: `wiz.call`, `api.py`, Portal App, 404, 라우팅, `component`
- **심각도**: 런타임 오류 (API 404)

## 증상

Portal App(component)의 `view.ts`에서 `wiz.call("함수명")`을 호출하면 **404 에러**가 반환된다. 같은 함수명이 부모 Page의 `api.py`에 정의되어 있는데도 호출되지 않는다.

```typescript
// Portal App — src/portal/{package}/app/{component}/view.ts
let res = await wiz.call("user_list", { page: 1 });
// res.code === 404  ← 함수가 없다는 응답
```

**에러 로그 예시**: 특별한 에러 메시지 없이 404 반환. 서버 로그에도 별도 traceback이 남지 않을 수 있음.

## 원인

`wiz.call("함수명")`은 **현재 App 자신의 `api.py`**에서 함수를 찾는다. Portal App이 Page 안에 태그로 삽입되어 렌더링되더라도, `wiz.call()`은 **부모 Page의 `api.py`가 아니라 Portal App 자신의 `api.py`를 호출**한다.

**내부 라우팅 경로**:
```
wiz.call("함수명")
  → POST /wiz/api/{APP_ID}/{함수명}
  → APP_ID = 현재 컴포넌트의 id (예: portal.season.admin.user)
  → 해당 App 폴더의 api.py에서 함수 탐색
  → api.py 미존재 또는 함수 미정의 → 404
```

따라서 Portal App 폴더에 `api.py`가 없거나, 해당 함수가 정의되어 있지 않으면 404가 발생한다. 부모 Page의 `api.py`에 아무리 많은 함수를 정의해도 Portal App에서는 접근할 수 없다.

## 해결

### 방법 1: Portal App에 자체 api.py 생성 (권장)

Portal App이 `wiz.call()`을 사용해야 한다면, **해당 Portal App 폴더에 `api.py`를 생성**하고 필요한 함수를 정의한다.

```
src/portal/{package}/app/{component}/
├── app.json
├── view.ts
├── view.pug
└── api.py       ← 추가
```

```python
# src/portal/{package}/app/{component}/api.py

struct = wiz.model("portal/{package}/struct")

def user_list():
    page = int(wiz.request.query("page", 1))
    dump = int(wiz.request.query("dump", 20))
    try:
        rows = struct.user.search(page=page, dump=dump)
    except Exception as e:
        wiz.response.status(500, message=str(e))
    wiz.response.status(200, rows=rows)
```

### 방법 2: 부모 서비스/config 객체를 통한 API 위임

`wiz.call()`을 사용하지 않고, `@Input()`으로 전달받은 서비스 객체나 config 콜백을 통해 부모가 API를 대신 호출한다.

```typescript
// Portal App — view.ts
@Input() config: any;

async loadUsers() {
    // 부모가 주입한 API 호출 함수 사용
    const result = await this.config.api('user_list', { page: 1 });
}
```

### Controller 설정 (api.py 생성 시 필수)

Portal App에 `api.py`를 추가할 때, 인증/권한이 필요하면 **반드시 `app.json`에 controller를 설정**한다.

```json
{
    "controller": "admin"
}
```

해당 패키지의 `controller/` 폴더에 대응하는 controller 파일이 존재해야 한다:

```python
# src/portal/{package}/controller/admin.py
class Controller(wiz.controller("admin")):
    def __init__(self):
        super().__init__()
```

## 적용 범위

- **모든 Portal App**에 해당: `wiz.call()`은 항상 현재 App의 `api.py`만 참조
- **Source App(page, layout, component)**도 동일한 원칙: 각 App의 `wiz.call()`은 자신의 `api.py`만 호출
- Portal App을 Page 안에 삽입한 구조에서 특히 혼동하기 쉬움 — **부모-자식 관계와 무관하게 `api.py`는 App 단위로 독립**

## 체크리스트

Portal App 개발 시 `wiz.call()` 사용 여부를 먼저 확인:

- [ ] `view.ts`에서 `wiz.call()`을 사용하는가?
  - **Yes** → Portal App 폴더에 `api.py` 생성 필수
  - **No** → `api.py` 불필요 (부모 서비스를 통해 데이터 접근)
- [ ] `api.py`에 인증이 필요한가?
  - **Yes** → `app.json`에 `"controller"` 설정 + 패키지 `controller/` 폴더에 해당 파일 생성
  - **No** → `"controller": ""` (빈 문자열)
- [ ] 클린 빌드 수행했는가?
  - 새 `api.py` 추가 시 **클린 빌드 필수** (`clean: true`)
