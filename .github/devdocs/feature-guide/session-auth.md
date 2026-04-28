# 세션 기반 인증 시스템 가이드

## 1. 개요

WIZ 프레임워크에서 세션 기반 인증 시스템을 구현하는 완전한 가이드이다. 다음 기능을 포함한다:

- **로그인/로그아웃**: 이메일+비밀번호 로그인, 세션 생성/파기
- **세션 DB 관리**: 로그인 세션을 DB에 기록하여 다중 기기 관리
- **다중 기기 로그아웃**: 특정 세션 또는 전체 세션 원격 로그아웃 (Revoke)
- **접속 로그**: 로그인/로그아웃 이력을 DB에 기록
- **SSO 연동 (선택)**: SAML 기반 SSO 로그인 연동
- **Controller 체인**: base → user → admin 3단계 권한 검증

### 핵심 설계 원칙

1. **세션 + DB 이중 관리**: Flask 세션(쿠키)으로 인증 상태를 유지하면서, DB에 세션 레코드를 기록하여 원격 세션 관리(다른 기기 로그아웃)를 지원한다.
2. **session_token 패턴**: 로그인 시 UUID 기반 `session_token`을 생성하여 Flask 세션과 DB 양쪽에 저장한다. 매 요청마다 DB에서 해당 토큰의 `is_active` 상태를 확인하여, 원격 로그아웃(revoke)된 세션을 즉시 차단한다.
3. **Controller 체인 상속**: `base → user → admin` 순서로 Controller를 상속하여 계층적 권한을 검증한다.

---

## 2. 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────┐
│                        프론트엔드 (Angular)                       │
├─────────────────────────────────────────────────────────────────┤
│  page.access/         │  page.mypage/          │  layout.*/     │
│  - 로그인 폼           │  - 활성 세션 목록        │  - Service 초기화│
│  - api.py(login)      │  - 접속 로그            │  - auth.init() │
│                       │  - 세션 revoke          │                │
├───────────┬───────────┴───────────┬────────────┴────────────────┤
│           │                       │                              │
│     Controller 체인               │     Route (인증 API)          │
│  ┌────────────┐                   │  ┌───────────────────────┐   │
│  │  base.py   │ 세션 초기화        │  │ portal/season/route/  │   │
│  │     ↓      │                   │  │   auth/controller.py  │   │
│  │  user.py   │ 인증 + 세션 검증   │  │   - /auth/check       │   │
│  │     ↓      │                   │  │   - /auth/login       │   │
│  │  admin.py  │ 관리자 권한 검증   │  │   - /auth/logout      │   │
│  └────────────┘                   │  └───────────────────────┘   │
├───────────────────────────────────┴──────────────────────────────┤
│                         Model / Struct                           │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  portal/{pkg}/model/struct.py (Composite Struct)            │ │
│  │    ├── user          → struct/user.py                       │ │
│  │    ├── user_session  → struct/user_session.py               │ │
│  │    └── access_log    → struct/access_log.py                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  portal/{pkg}/model/db/ (DB Schema)                         │ │
│  │    ├── user.py            → user 테이블                     │ │
│  │    ├── user_session.py    → user_session 테이블              │ │
│  │    └── access_log.py      → access_log 테이블               │ │
│  └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                        Config / Session                          │
│  portal/season/model/session.py   → Flask 세션 래퍼             │
│  portal/season/model/config.py    → session_create 콜백 설정     │
│  config/season.py                 → session_create 구현         │
│  config/database.py               → DB 접속 정보                │
└─────────────────────────────────────────────────────────────────┘
```

### 인증 흐름 (로그인 → 요청 → 로그아웃)

```
[로그인]
1. 프론트엔드 → page.access/api.py login()
2. DB에서 사용자 조회 + 비밀번호 검증
3. wiz.session.create(user_id) 호출
   → config/season.py의 session_create() 콜백 실행
   → Flask 세션에 사용자 정보 저장
   → user_session 테이블에 세션 레코드 삽입 (session_token 생성)
   → Flask 세션에 session_token 저장
4. access_log 테이블에 로그인 기록

[인증된 요청]
1. Controller 체인: base.py → user.py
2. base.py: Flask 세션에서 사용자 데이터 로드
3. user.py:
   a. Flask 세션에 id 존재 확인 → 없으면 401
   b. session_token으로 DB 조회 → is_active=0이면 세션 클리어 + 401
   c. DB에서 사용자 존재 확인 → 없으면 세션 클리어 + 401
   d. last_active 갱신 (세션 활성 갱신)

[로그아웃]
1. /auth/logout 라우트 호출
2. session_token으로 DB의 user_session 레코드 비활성화 (is_active=0)
3. Flask 세션 클리어
4. 리다이렉트

[원격 로그아웃 (다른 기기)]
1. 마이페이지에서 활성 세션 목록 조회
2. 특정 세션의 session_token으로 revoke 호출
3. DB에서 해당 세션의 is_active=0으로 변경
4. 다음 요청 시 user.py 컨트롤러에서 자동 차단
```

---

## 3. DB 스키마

### 3.1 user 테이블

사용자 기본 정보를 저장한다.

```python
# portal/{pkg}/model/db/user.py
import peewee as pw
import datetime
orm = wiz.model("portal/{pkg}/orm")
base = orm.base()

class Model(base):
    class Meta:
        db_table = 'user'

    id = pw.CharField(max_length=32, primary_key=True)
    role = pw.CharField(max_length=16)              # 'admin' | 'user'
    name = pw.CharField(max_length=192)
    email = pw.CharField(max_length=192)
    mobile = pw.CharField(max_length=64)
    status = pw.CharField(max_length=8)             # 'active' | 'inactive' | 'pending' | 'block'
    onetimepass = pw.CharField(max_length=16)       # OTP (선택)
    onetimepass_time = pw.DateTimeField()
    password = base.PasswordField()                 # bcrypt 자동 해싱
    created = pw.DateTimeField()
    last_access = pw.DateTimeField()
    extra = base.JSONObject()                       # 확장 데이터 (JSON)
    profile_image = pw.TextField()
```

**핵심 필드 설명:**

| 필드 | 설명 |
|------|------|
| `id` | 사용자 고유 식별자. 이메일과 별도로 관리 (SSO uid 등) |
| `role` | 권한 레벨. Controller 체인에서 `admin` 역할 검증에 사용 |
| `status` | 계정 상태. `active`만 로그인 허용, `inactive`는 비활성화 |
| `password` | `base.PasswordField()`는 ORM 패키지가 제공하는 bcrypt 해싱 필드. 저장 시 자동 해싱, 비교 시 `user['password'](plain_text)` 호출 |
| `last_access` | 마지막 접속 시간. user.py Controller에서 매 요청마다 갱신 |

### 3.2 user_session 테이블

로그인 세션을 DB에 기록하여 다중 기기 관리를 지원한다.

```python
# portal/{pkg}/model/db/user_session.py
import peewee as pw
import datetime
orm = wiz.model("portal/{pkg}/orm")
base = orm.base()

class Model(base):
    class Meta:
        db_table = 'user_session'

    id = pw.CharField(max_length=64, primary_key=True)   # session_token (UUID)
    user_id = pw.CharField(max_length=32, index=True)     # user.id 참조
    ip = pw.CharField(max_length=64)                      # 로그인 IP
    user_agent = pw.TextField()                           # 브라우저 정보
    login_type = pw.CharField(max_length=32, default='login')  # 'login' | 'saml_login' 등
    created = pw.DateTimeField(default=datetime.datetime.now)  # 로그인 시각
    last_active = pw.DateTimeField(default=datetime.datetime.now)  # 마지막 활성 시각
    is_active = pw.IntegerField(default=1, index=True)    # 1=활성, 0=비활성(revoked)
```

**핵심 설계:**

- `id`는 UUID v4(`str(uuid.uuid4())`). Flask 세션에 `session_token`으로 저장됨
- `is_active`가 세션 유효성의 핵심. 0으로 변경하면 해당 세션의 다음 요청부터 자동 차단
- `last_active`는 매 인증 요청마다 갱신. 비활성 세션 정리(cleanup) 기준으로 활용 가능

### 3.3 access_log 테이블

로그인/로그아웃 이력을 기록하는 감사(audit) 로그이다.

```python
# portal/{pkg}/model/db/access_log.py
import peewee as pw
import datetime
orm = wiz.model("portal/{pkg}/orm")
base = orm.base()

class Model(base):
    class Meta:
        db_table = 'access_log'

    id = pw.CharField(max_length=32, primary_key=True)
    user_id = pw.CharField(max_length=32, index=True)
    ip = pw.CharField(max_length=64)
    user_agent = pw.TextField()
    action = pw.CharField(max_length=32, index=True)    # 'login' | 'logout' | 'saml_login' 등
    created = pw.DateTimeField(default=datetime.datetime.now, index=True)
```

---

## 4. 백엔드 구현

### 4.1 Struct 계층

비즈니스 로직은 Struct 패턴으로 캡슐화한다. DB Model은 스키마만 정의.

#### Composite Struct (진입점)

```python
# portal/{pkg}/model/struct.py
User = wiz.model("portal/{pkg}/struct/user")
UserSession = wiz.model("portal/{pkg}/struct/user_session")
AccessLog = wiz.model("portal/{pkg}/struct/access_log")

class Struct:
    def __init__(self):
        self.user = User(self)
        self.user_session = UserSession(self)
        self.access_log = AccessLog(self)
        # ... 기타 도메인 Struct

    def getUserId(self):
        return wiz.session.user_id()

    def isAdmin(self):
        role = wiz.session.get("role")
        return role == 'admin'

    def db(self, name):
        orm = wiz.model("portal/{pkg}/orm")
        return orm.use(name, module="{pkg}")

Model = Struct()
```

#### UserSession Struct (세션 관리 핵심)

```python
# portal/{pkg}/model/struct/user_session.py
import datetime
import uuid

class Model:
    def __init__(self, core):
        self.core = core
        self.db = self.core.db("user_session")

    @staticmethod
    def is_revoked(session_token):
        """세션 토큰이 비활성화(revoked)되었는지 DB에서 확인"""
        if not session_token:
            return False
        try:
            orm = wiz.model("portal/{pkg}/orm")
            db = orm.use("user_session", module="{pkg}")
            session = db.get(id=session_token)
            if session is None:
                return True           # DB에 없으면 revoked로 간주
            return session.get("is_active", 0) == 0
        except Exception:
            return False

    def register(self, user_id, ip="", user_agent="", login_type="login"):
        """로그인 시 세션 레코드 생성. session_token(UUID) 반환"""
        session_token = str(uuid.uuid4())
        data = dict(
            id=session_token,
            user_id=user_id,
            ip=ip if ip else "",
            user_agent=user_agent if user_agent else "",
            login_type=login_type,
            created=datetime.datetime.now(),
            last_active=datetime.datetime.now(),
            is_active=1
        )
        self.db.insert(data)
        return session_token

    def update_active(self, session_token):
        """매 요청마다 last_active 갱신"""
        if not session_token:
            return
        try:
            self.db.update(
                dict(last_active=datetime.datetime.now()),
                id=session_token
            )
        except Exception:
            pass

    def list_active(self, user_id):
        """사용자의 활성 세션 목록 조회"""
        rows = self.db.rows(
            user_id=user_id,
            is_active=1,
            orderby="last_active",
            order="DESC"
        )
        return rows

    def revoke(self, session_token, user_id):
        """특정 세션을 비활성화 (다른 기기 로그아웃)"""
        session = self.db.get(id=session_token)
        if session is None or session["user_id"] != user_id:
            return False
        self.db.update(dict(is_active=0), id=session_token)
        return True

    def revoke_all(self, user_id, except_token=None):
        """현재 세션 외 모든 세션 비활성화"""
        rows = self.db.rows(user_id=user_id, is_active=1)
        for row in rows:
            if except_token and row["id"] == except_token:
                continue
            self.db.update(dict(is_active=0), id=row["id"])

    def deactivate(self, session_token):
        """로그아웃 시 세션 비활성화"""
        if not session_token:
            return
        try:
            self.db.update(dict(is_active=0), id=session_token)
        except Exception:
            pass
```

#### AccessLog Struct (접속 로그)

```python
# portal/{pkg}/model/struct/access_log.py
import datetime

class Model:
    def __init__(self, core):
        self.core = core
        self.db = self.core.db("access_log")

    def record(self, user_id, ip="", user_agent="", action="login"):
        """접속 이력 기록"""
        data = dict(
            user_id=user_id,
            ip=ip if ip else "",
            user_agent=user_agent if user_agent else "",
            action=action,
            created=datetime.datetime.now()
        )
        self.db.insert(data)

    def recent(self, user_id, page=1, dump=20):
        """사용자의 최근 접속 이력 조회 (페이징)"""
        rows = self.db.rows(
            user_id=user_id,
            orderby="created",
            order="DESC",
            page=page,
            dump=dump
        )
        total = self.db.count(user_id=user_id)
        return rows, total
```

#### User Struct (사용자 관리)

```python
# portal/{pkg}/model/struct/user.py
import datetime

class Model:
    def __init__(self, core):
        self.id = None
        self.core = core
        self.db = self.core.db("user")

    def __call__(self, id):
        """id 바인딩된 인스턴스 생성"""
        mod = Model(self.core)
        mod.id = id
        return mod

    def search(self, text=None, page=None, dump=50, orderby="name", order="ASC", status=None, **where):
        """사용자 검색 (이름/이메일/ID)"""
        if status is not None:
            where['status'] = status

        def query(db, qs):
            if text is not None and len(text) > 0:
                qs = qs.where(db.name.contains(text) | db.email.contains(text) | db.id.contains(text))
            return qs

        if text is not None and len(text) > 0:
            where['query'] = query

        rows = self.db.rows(page=page, dump=dump, orderby=orderby, order=order, **where)
        total = self.db.count(**where)
        return rows, total

    def get(self):
        return self.db.get(id=self.id)

    def update(self, data):
        data['updated'] = datetime.datetime.now()
        self.db.update(data, id=self.id)
        return self

    def access(self):
        """마지막 접속 시간 갱신"""
        data = dict(id=self.id, last_access=datetime.datetime.now())
        return self.update(data)
```

### 4.2 Controller 체인

Controller는 `base → user → admin` 3단계로 상속하여 계층적 권한을 검증한다.

#### base.py (세션 초기화)

```python
# src/controller/base.py
import season
import datetime

class Controller:
    def __init__(self):
        wiz.session = wiz.model("portal/{pkg}/session").use()
        sessiondata = wiz.session.get()
        wiz.response.data.set(session=sessiondata)
```

- `wiz.session` 초기화: 패키지의 Session 모델을 로드하여 전역으로 설정
- `wiz.response.data.set(session=...)`: 프론트엔드에서 세션 데이터 접근 가능하게 함

#### user.py (인증 + 세션 검증)

```python
# src/controller/user.py
class Controller(wiz.controller("base")):
    def __init__(self):
        super().__init__()

        # 1. Flask 세션에 id 존재 확인
        if wiz.session.has("id") == False:
            wiz.response.status(401)

        # 2. DB에서 session_token의 is_active 확인 (원격 로그아웃 감지)
        session_token = wiz.session.get("session_token", None)
        if session_token:
            UserSession = wiz.model("portal/{pkg}/struct/user_session")
            if UserSession.is_revoked(session_token):
                wiz.session.clear()
                wiz.response.status(401)

        # 3. DB에서 사용자 존재/상태 확인
        try:
            struct = wiz.model("portal/{pkg}/struct")
            user = struct.user(wiz.session.get("id")).get()
            if user is None:
                wiz.session.clear()
                wiz.response.status(401)
            struct.user(wiz.session.get("id")).access()  # last_access 갱신
        except Exception:
            wiz.session.clear()
            wiz.response.status(401)

        # 4. 세션 활성 갱신 (last_active)
        try:
            if session_token:
                struct.user_session.update_active(session_token)
        except Exception:
            pass
```

**핵심 포인트:**

- `UserSession.is_revoked()`는 `@staticmethod`로 Struct 인스턴스 없이도 호출 가능. Controller에서 가벼운 DB 조회만 수행
- `wiz.response.status(401)`은 `ResponseException`을 raise하여 즉시 종료. `try/except` 밖에서 호출해야 한다
- `struct.user(...).access()`로 `last_access` 갱신 → 활성 사용자 추적

#### admin.py (관리자 권한)

```python
# src/controller/admin.py
class Controller(wiz.controller("user")):
    def __init__(self):
        super().__init__()
        if wiz.session.get("role") != 'admin':
            wiz.response.status(401)
```

### 4.3 Config: 세션 생성 콜백

`config/season.py`에서 `session_create` 함수를 정의하여 로그인 시 세션 생성 로직을 커스터마이징한다. 이 함수는 `wiz.session.create(user_id)` 호출 시 실행된다.

```python
# config/season.py
auth_login_uri = "/access"          # 로그인 페이지 URL
auth_saml_use = True                # SAML SSO 사용 여부

def session_create(wiz, key):
    """로그인 시 호출되는 세션 생성 콜백
    
    Args:
        wiz: WIZ 프레임워크 객체
        key: 사용자 식별자 (user_id 또는 email)
    """
    orm = wiz.model("portal/{pkg}/orm")
    db = orm.use("user", module="{pkg}")
    user = db.get(fields="id,email,role,name,mobile,status,created,last_access", id=key)
    if user is None:
        user = db.get(fields="id,email,role,name,mobile,status,created,last_access", email=key)
    if user is None:
        wiz.session.clear()
        wiz.response.status(401, "등록되지 않은 사용자입니다.")
    if user.get('status') == 'inactive':
        wiz.session.clear()
        wiz.response.status(403, "비활성화된 계정입니다.")

    # Flask 세션에 사용자 정보 저장
    wiz.session.set(**user)

    # DB에 세션 레코드 생성
    try:
        struct = wiz.model("portal/{pkg}/struct")
        ip = wiz.request.ip()
        user_agent = wiz.request.headers("User-Agent", "")
        login_type = wiz.session.get("_login_type", "login")
        session_token = struct.user_session.register(
            user['id'], ip=ip, user_agent=user_agent, login_type=login_type
        )
        wiz.session.set(session_token=session_token)
    except Exception:
        pass
```

**핵심 패턴:**

1. `session_create`는 `wiz.session.create(user_id)` → `config.session_create(wiz, key)` 형태로 콜백 호출됨
2. 로그인 유형(`login_type`)은 로그인 처리 코드에서 `wiz.session.set(_login_type="login")` 으로 미리 설정 후 `session_create`에서 읽음
3. `session_token`은 `struct.user_session.register()`가 반환하는 UUID. Flask 세션에 저장하여 이후 요청에서 DB 검증에 사용

### 4.4 인증 Route (로그인/로그아웃 API)

season 패키지의 `route/auth/controller.py`가 인증 엔드포인트를 제공한다.

```python
# portal/{pkg}/route/auth/controller.py
config = wiz.model("portal/{pkg}/config")
BASEURI = config.auth_baseuri        # 기본값: '/auth'
LOGOUT_URI = config.auth_logout_uri
LOGIN_URL = config.auth_login_uri

# GET /auth/check — 현재 인증 상태 확인 (프론트엔드 Service.auth.init()에서 호출)
if wiz.request.match(f"{BASEURI}/check") is not None:
    user_id = wiz.session.user_id()
    status = False if user_id is None else True

    # DB에서 사용자 존재/활성 확인
    if status:
        try:
            orm = wiz.model("portal/{pkg}/orm")
            db = orm.use("user", module="{pkg}")
            user = db.get(id=user_id)
            if user is None or user.get('status') == 'inactive':
                wiz.session.clear()
                status = False
        except Exception:
            wiz.session.clear()
            status = False

    data = wiz.session.get() if status else {}
    wiz.response.status(200, status=status, session=data)

# GET /auth/logout — 로그아웃
if wiz.request.match(f"{BASEURI}/logout") is not None:
    returnTo = wiz.request.query("returnTo", "/")

    # DB에서 세션 비활성화
    try:
        session_token = wiz.session.get("session_token", None)
        if session_token:
            struct = wiz.model("portal/{pkg}/struct")
            struct.user_session.deactivate(session_token)
    except Exception:
        pass

    wiz.session.clear()
    wiz.response.redirect(returnTo)

# GET /auth/login — 로그인 페이지로 리다이렉트
if wiz.request.match(f"{BASEURI}/login") is not None:
    if LOGIN_URL is not None and LOGIN_URL != f"{BASEURI}/login":
        wiz.response.redirect(LOGIN_URL)
```

### 4.5 로그인 App (page.access)

```python
# src/app/page.access/api.py
orm = wiz.model("portal/{pkg}/orm")
db = orm.use("user", module="{pkg}")

def login():
    email = wiz.request.query("email", True)
    password = wiz.request.query("password", None)

    # 1. 사용자 조회 (id 또는 email로)
    user = db.get(id=email)
    if user is None:
        user = db.get(email=email)
    if user is None:
        wiz.response.status(404, "가입되지 않은 계정입니다.")

    # 2. 계정 상태 확인
    if user['status'] == 'inactive':
        wiz.response.status(403, "비활성화된 계정입니다.")
    if user['status'] in ['pending', 'block']:
        wiz.response.status(404, "관리자의 승인을 기다리고 있습니다")

    # 3. 비밀번호 검증
    if password is None:
        wiz.response.status(201, "비밀번호를 입력해주세요")
    if user['password'](password) == False:
        wiz.response.status(401, "이메일 또는 비밀번호를 확인해주세요")

    # 4. 세션 생성 (session_create 콜백 → 세션 DB 등록)
    wiz.session.set(_login_type="login")
    wiz.session.create(user['id'])

    # 5. 접속 로그 기록
    try:
        struct = wiz.model("portal/{pkg}/struct")
        ip = wiz.request.ip()
        user_agent = wiz.request.headers("User-Agent", "")
        struct.access_log.record(user['id'], ip=ip, user_agent=user_agent, action="login")
    except Exception:
        pass

    wiz.response.status(200, True)
```

---

## 5. 프론트엔드 구현

### 5.1 Service.auth (인증 상태 관리)

패키지의 `libs/src/auth.ts`가 `/auth/check` API를 호출하여 인증 상태를 관리한다.

```typescript
// portal/{pkg}/libs/src/auth.ts (구조 참고)
export default class Auth {
    public status: boolean | null = null;
    public session: any = {};

    public async init() {
        let { code, data } = await this.request.post('/auth/check');
        this.status = data.status ? true : false;
        this.session = data.status ? data.session : {};
    }

    // 권한 체크 프록시
    public check.role('admin')    // 세션의 role 값 확인
    public allow(redirect?)       // 인증 안 되면 리다이렉트
    public allow.role('admin')    // admin이 아니면 리다이렉트
}
```

### 5.2 로그인 페이지 (page.access)

```typescript
// src/app/page.access/view.ts
export class Component implements OnInit {
    public email: string = '';
    public password: string = '';

    constructor(public service: Service) {}

    public async ngOnInit() {
        await this.service.init();
        // 이미 로그인된 경우 메인으로
        if (this.service.auth.status) {
            this.service.href('/');
        }
        await this.service.render();
    }

    public async login() {
        if (!this.email) return;
        const { code, data } = await wiz.call('login', {
            email: this.email,
            password: this.password
        });
        if (code == 200) {
            location.href = '/';    // 풀 리로드로 세션 반영
        } else {
            await this.service.modal.error(data);
        }
    }
}
```

### 5.3 마이페이지: 세션 관리 & 접속 로그

```typescript
// src/app/page.mypage/view.ts (세션 관리 부분)
export class Component implements OnInit {
    public sessions: any[] = [];
    public currentToken: string = '';
    public accessLogs: any[] = [];

    // 활성 세션 목록 로드
    public async loadSessions() {
        const { code, data } = await wiz.call('sessions');
        if (code == 200) {
            this.sessions = data.sessions;
            this.currentToken = data.current_token;
        }
    }

    // 특정 세션 강제 로그아웃
    public async revokeSession(sessionId: string) {
        const res = await this.service.modal.show({
            title: '세션 종료',
            message: '해당 기기의 세션을 종료하시겠습니까?',
            action: '종료',
            status: 'warning'
        });
        if (!res) return;
        await wiz.call('revoke_session', { session_token: sessionId });
        await this.loadSessions();
    }

    // 다른 모든 세션 로그아웃
    public async revokeAllSessions() {
        const res = await this.service.modal.show({
            title: '전체 세션 종료',
            message: '현재 세션을 제외한 모든 세션을 종료하시겠습니까?',
            action: '전체 종료',
            status: 'warning'
        });
        if (!res) return;
        await wiz.call('revoke_all_sessions');
        await this.loadSessions();
    }

    // 접속 로그 로드
    public async loadAccessLogs(page: number = 1) {
        const { code, data } = await wiz.call('access_logs', { page, dump: 10 });
        if (code == 200) {
            this.accessLogs = data.rows;
        }
    }
}
```

```python
# src/app/page.mypage/api.py (세션 관리 API)
struct = wiz.model("portal/{pkg}/struct")

def sessions():
    user_id = wiz.session.get("id")
    current_token = wiz.session.get("session_token", "")
    rows = struct.user_session.list_active(user_id)
    wiz.response.status(200, sessions=rows, current_token=current_token)

def revoke_session():
    user_id = wiz.session.get("id")
    session_token = wiz.request.query("session_token", "")
    if not session_token:
        wiz.response.status(400, "세션 토큰이 필요합니다.")
    result = struct.user_session.revoke(session_token, user_id)
    if not result:
        wiz.response.status(404, "세션을 찾을 수 없습니다.")
    wiz.response.status(200, "세션이 종료되었습니다.")

def revoke_all_sessions():
    user_id = wiz.session.get("id")
    current_token = wiz.session.get("session_token", "")
    struct.user_session.revoke_all(user_id, except_token=current_token)
    wiz.response.status(200, "다른 세션이 모두 종료되었습니다.")

def access_logs():
    user_id = wiz.session.get("id")
    page = int(wiz.request.query("page", 1))
    dump = int(wiz.request.query("dump", 10))
    rows, total = struct.access_log.recent(user_id, page=page, dump=dump)
    wiz.response.status(200, rows=rows, total=total)
```

---

## 6. SSO 연동 (SAML, 선택사항)

SAML SSO는 season 패키지의 `model/auth/saml.py`가 처리한다.

### Config 설정

```python
# config/season.py
auth_saml_use = True
auth_saml_entity = 'season'             # SAML 엔티티 이름
auth_saml_base_path = 'config/auth/saml' # SAML 메타데이터 경로

def auth_saml_acs(wiz, userinfo):
    """SAML ACS 콜백: 인증 성공 시 호출"""
    email = userinfo.get('email', [None])[0]
    name = userinfo.get('name', [''])[0]
    uid = userinfo.get('uid', [None])[0]

    orm = wiz.model("portal/{pkg}/orm")
    userdb = orm.use("user", module="{pkg}")
    user = userdb.get(email=email)

    # 자동 사용자 생성 (없으면)
    if user is None:
        userdb.insert(dict(id=uid, email=email, role="user", name=name, status="active", ...))
    
    # session_create 호출로 세션 등록
    wiz.session.set(_login_type="saml_login")
    session = wiz.model("portal/{pkg}/session")
    session.create(user_id)

    # 접속 로그 기록
    struct = wiz.model("portal/{pkg}/struct")
    struct.access_log.record(user_id, ip=..., user_agent=..., action="saml_login")

    return user
```

### SAML 메타데이터 위치

```
project/{name}/config/auth/saml/{entity}/
├── settings.json      # SP 설정
├── advanced_settings.json
└── certs/
    ├── sp.crt         # SP 인증서
    └── sp.key         # SP 개인키
```

### SAML 엔드포인트

| URL | 설명 |
|-----|------|
| `/auth/saml/login/{entity}/` | SAML 로그인 시작 (IdP로 리다이렉트) |
| `/auth/saml/acs/{entity}/` | SAML ACS (인증 응답 수신) |
| `/auth/saml/metadata/{entity}/` | SP 메타데이터 |

---

## 7. 구현 체크리스트

### Phase 1: DB + Model 설정

- [ ] `config/database.py`에 DB 접속 정보 설정
- [ ] `portal/{pkg}/model/db/user.py` 생성 (user 테이블)
- [ ] `portal/{pkg}/model/db/user_session.py` 생성 (user_session 테이블)
- [ ] `portal/{pkg}/model/db/access_log.py` 생성 (access_log 테이블)
- [ ] DB에 테이블 생성 (CREATE TABLE)

### Phase 2: Struct 구현

- [ ] `portal/{pkg}/model/struct/user.py` — 사용자 CRUD + access()
- [ ] `portal/{pkg}/model/struct/user_session.py` — 세션 등록, 검증, revoke
- [ ] `portal/{pkg}/model/struct/access_log.py` — 접속 로그 기록/조회
- [ ] `portal/{pkg}/model/struct.py` — Composite Struct 진입점

### Phase 3: 인증 체계

- [ ] `portal/{pkg}/model/session.py` — Flask 세션 래퍼 (패키지에 포함되어 있으면 확인만)
- [ ] `config/season.py`에 `session_create` 함수 구현
- [ ] `config/season.py`에 `auth_login_uri` 설정
- [ ] `portal/{pkg}/route/auth/` — 인증 라우트 (패키지에 포함되어 있으면 확인만)

### Phase 4: Controller 체인

- [ ] `src/controller/base.py` — 세션 초기화
- [ ] `src/controller/user.py` — 인증 + session_token 검증 + revoke 감지
- [ ] `src/controller/admin.py` — 관리자 권한 검증
- [ ] App의 `app.json`에 controller 지정 (page → `"user"`, admin page → `"admin"`)

### Phase 5: 프론트엔드

- [ ] `page.access/` — 로그인 페이지 (api.py + view.ts + view.pug)
- [ ] `layout.*/` — Service 초기화, `wiz-portal-{pkg}-modal` 컴포넌트 배치
- [ ] `page.mypage/` — 프로필, 비밀번호 변경, 활성 세션 관리, 접속 로그
- [ ] 빌드 확인

### Phase 6: (선택) SAML SSO

- [ ] `pip install python3-saml` 설치
- [ ] `config/season.py`에 SAML 설정 추가
- [ ] `config/auth/saml/{entity}/` 에 SAML 메타데이터 배치
- [ ] IdP에 SP 메타데이터 등록

---

## 8. 커스터마이징 포인트

| 항목 | 위치 | 설명 |
|------|------|------|
| 세션 생성 로직 | `config/season.py` → `session_create` | 세션에 저장할 필드, 추가 검증 로직 |
| 로그인 유형 | `_login_type` 세션 값 | `'login'`, `'saml_login'`, `'otp_login'` 등 확장 |
| 사용자 상태 | `user.status` | `'active'`, `'inactive'`, `'pending'`, `'block'` 등 |
| 권한 체계 | Controller 체인 + `user.role` | 더 세분화된 권한은 Controller 추가 상속 |
| 세션 만료 | `user_session.last_active` | 배치 잡으로 오래된 세션 자동 비활성화 가능 |
| 접속 로그 확장 | `access_log.action` | `'password_change'`, `'profile_update'` 등 추가 |
