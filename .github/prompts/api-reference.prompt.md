# WIZ API 빠른 참조

wiz 객체의 주요 API를 빠르게 참조할 수 있는 문서입니다.

---

## 📥 wiz.request (요청 처리)

```python
# 쿼리/폼 데이터 전체
data = wiz.request.query()

# 특정 키 조회 (기본값 지원)
value = wiz.request.query("key", "default")

# 필수 파라미터 (없으면 400 에러)
value = wiz.request.query("key", True)

# 파일 업로드
files = wiz.request.files()
for filename in files:
    file = files[filename]
    file.save("/path/to/save")

# URL 패턴 매칭
segment = wiz.request.match("/api/<resource>/<int:id>")
resource = segment.resource  # string
id = segment.id              # int

# 패턴 타입
# <name>         - 문자열
# <int:name>     - 정수
# <float:name>   - 실수
# <path:name>    - 경로 (/ 포함)

# 현재 URI
uri = wiz.request.uri()

# HTTP 메서드
method = wiz.request.method()  # GET, POST, PUT, DELETE

# Flask request 객체
req = wiz.request.request()
```

---

## 📤 wiz.response (응답 처리)

```python
# JSON 응답 (상태코드, 데이터)
wiz.response.status(200, {"result": "success"})
wiz.response.status(400, {"error": "Bad request"})
wiz.response.status(401)  # Unauthorized
wiz.response.status(404, {"error": "Not found"})

# 파일 다운로드
wiz.response.download(filepath, as_attachment=True)
wiz.response.download(filepath, filename="custom.pdf")

# 이미지 응답 (PIL)
from PIL import Image
img = Image.open("image.png")
wiz.response.PIL(img, type="PNG")

# 리다이렉트
wiz.response.redirect("/new-path")

# HTTP 에러
wiz.response.abort(404)
wiz.response.abort(403)

# 템플릿 변수 설정
wiz.response.data.set(key="value", user=userdata)

# 언어 설정
wiz.response.lang("ko")

# WebSocket 메시지 전송 (socket.py)
wiz.response.send({"message": "hello"})
wiz.response.send(data, broadcast=True)
```

---

## 👤 wiz.session (세션 관리)

```python
# Controller에서 초기화
wiz.session = wiz.model("portal/season/session").use()

# 값 조회
value = wiz.session.get("key", "default")
all_data = wiz.session.get()

# 값 설정
wiz.session.set(key="value")
wiz.session.set(id="user123", role="admin")

# 존재 확인
exists = wiz.session.has("id")

# 삭제
wiz.session.delete("key")

# 전체 삭제
wiz.session.clear()
```

---

## 📁 wiz.fs (파일시스템)

```python
# 현재 컴포넌트 파일시스템
fs = wiz.fs()

# 파일 읽기/쓰기
content = fs.read("file.txt")
fs.write("file.txt", content)

# 파일 목록
files = fs.files()
dirs = fs.dirs()

# 파일 존재 확인
exists = fs.exists("file.txt")

# 절대 경로
abspath = fs.abspath("file.txt")

# 삭제
fs.remove("file.txt")
fs.rmtree("folder")
```

---

## 📂 wiz.project.fs (프로젝트 파일시스템)

```python
# 프로젝트 내 특정 경로
fs = wiz.project.fs("data", "uploads")

# 파일 작업
fs.write("file.txt", content)
content = fs.read("file.txt")

# 디렉토리 생성
fs.makedirs("subfolder")

# 파일 목록
files = fs.files()

# 절대 경로
abspath = fs.abspath("file.txt")
```

---

## 🔧 wiz.model (모델 로드)

```python
# 프로젝트 모델
model = wiz.model("user")
model = wiz.model("db/user")

# 패키지 모델
session = wiz.model("portal/season/session")
config = wiz.model("portal/works/config")

# 모델 사용
result = model.list()
item = model.get(id)
model.create(data)
```

---

## 🎮 wiz.controller (컨트롤러 상속)

```python
# base 컨트롤러 상속
class Controller(wiz.controller("base")):
    def __init__(self):
        super().__init__()
        # 추가 로직

# 체인 상속
class Controller(wiz.controller("user")):
    def __init__(self):
        super().__init__()
        # admin 검증 등
```

---

## 📝 wiz.logger (로깅)

```python
# 로거 생성
logger = wiz.logger("module_name")

# 로그 출력
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
logger.debug("Debug message")
```

---

## ⚙️ wiz.config (설정)

```python
# 서버 설정 접근
config = wiz.config
# boot.py 설정 값 접근
```

---

## 🔌 wiz.server (서버 객체)

```python
# 서버 객체 접근
server = wiz.server

# Flask 앱
flask_app = wiz.server.package.flask

# 캐시
cache = wiz.server.cache
```

---

## 🌐 프론트엔드 Service API

```typescript
import { Service } from '@wiz/libs/portal/season/service';

// 초기화 (필수)
await this.service.init();
await this.service.render();

// API 호출
let res = await this.service.api.call("function_name", data);
// res.code, res.data

// 알림
await this.service.alert.success("성공");
await this.service.alert.error("에러");
await this.service.alert.warning("경고");
await this.service.alert.info("정보");

// 확인 대화상자
let confirmed = await this.service.alert.confirm("정말 삭제하시겠습니까?");

// 로딩
await this.service.loading.show();
await this.service.loading.hide();

// 네비게이션
await this.service.href("/path");
await this.service.back();

// 인증
await this.service.auth.init();
await this.service.auth.allow(true, "/login");  // 로그인 필수
await this.service.auth.allow(false, "/");      // 비로그인만

// 파일 선택
let files = await this.service.file.select("image/*");

// 렌더링
await this.service.render();
```

---

## 📎 상세 문서 참조

- `.github/devdocs/wiz-docs/api-reference.md`
- `.github/devdocs/wiz-docs/api/wiz-request.md`
- `.github/devdocs/wiz-docs/api/wiz-response.md`
- `.github/devdocs/wiz-docs/api/wiz-session.md`
- `.github/devdocs/wiz-docs/api/wiz-filesystem.md`
- `.github/devdocs/wiz-docs/api/wiz-project.md`
- `.github/devdocs/wiz-docs/api/service-api.md`
