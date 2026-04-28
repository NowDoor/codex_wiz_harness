# WIZ 프레임워크 개발 요청 처리 규칙

이 문서는 GitHub Copilot Agent가 WIZ 프레임워크 기반 개발 요청을 처리할 때 따라야 할 규칙입니다.

---

## 🎯 요청 유형별 참조 문서

### 1. 페이지/화면 개발 요청

**키워드**: "페이지 만들어줘", "화면 추가", "뷰 생성", "새 페이지"

**참조 문서**:
- `.github/devdocs/web-development-guide/1-source/1.1-app-guide.md`
- `.github/devdocs/wiz-docs/examples.md` (기본 페이지 생성)

**생성할 파일**:
```
src/app/page.{name}/
├── app.json      # 필수
├── view.ts       # 필수
├── view.pug      # 필수
├── view.scss     # 선택
└── api.py        # API 필요 시
```

**app.json 템플릿**:
```json
{
    "mode": "page",
    "id": "page.{name}",
    "title": "/{name}",
    "namespace": "{name}",
    "viewuri": "/{url-path}",
    "layout": "layout.aside",
    "controller": "user",
    "template": "wiz-page-{name}()"
}
```

---

### 2. API/백엔드 개발 요청

**키워드**: "API 만들어줘", "백엔드 추가", "서버 로직", "데이터 처리"

**참조 문서**:
- `.github/devdocs/web-development-guide/1-source/1.4-route-guide.md`
- `.github/devdocs/wiz-docs/api-reference.md`
- `.github/devdocs/wiz-docs/api/wiz-request.md`
- `.github/devdocs/wiz-docs/api/wiz-response.md`

**App 내장 API (api.py)**:
```python
def get_data():
    data = wiz.request.query()
    result = wiz.model("db/example").find(data)
    wiz.response.status(200, result)

def save_data():
    params = wiz.request.query()
    wiz.model("db/example").create(params)
    wiz.response.status(200)
```

**독립 Route API**:
```
src/route/{name}/
├── app.json
└── controller.py
```

---

### 3. Model/비즈니스 로직 요청

**키워드**: "모델 만들어줘", "데이터베이스", "비즈니스 로직", "ORM"

**참조 문서**:
- `.github/devdocs/web-development-guide/1-source/1.3-model-guide.md`
- `.github/devdocs/wiz-docs/api/wiz-filesystem.md`

**Model 템플릿**:
```python
# src/model/{name}.py

class Example:
    def __init__(self):
        pass

    def list(self):
        # 데이터 조회 로직
        return []

    def create(self, data):
        # 데이터 생성 로직
        pass

    def update(self, id, data):
        # 데이터 수정 로직
        pass

    def delete(self, id):
        # 데이터 삭제 로직
        pass

# ⚠️ Model 변수 필수
Model = Example()
```

---

### 4. Controller/인증 요청

**키워드**: "인증", "로그인 체크", "권한", "컨트롤러", "전처리"

**참조 문서**:
- `.github/devdocs/web-development-guide/1-source/1.2-controller-guide.md`
- `.github/devdocs/wiz-docs/api/wiz-session.md`

**Controller 템플릿**:
```python
# src/controller/{name}.py

class Controller(wiz.controller("base")):
    def __init__(self):
        super().__init__()
        
        # 권한 체크 로직
        if not wiz.session.has("id"):
            wiz.response.status(401)
```

---

### 5. 재사용 컴포넌트 요청

**키워드**: "공통 컴포넌트", "재사용", "위젯", "패키지", "포털"

**참조 문서**:
- `.github/devdocs/web-development-guide/2-packages.md`
- `.github/devdocs/web-development-guide/2-packages/2.1-app-guide.md`
- `.github/devdocs/web-development-guide/2-packages/2.5-libs-guide.md`

**Portal App 생성**:
```
src/portal/{package}/app/{name}/
├── app.json
├── view.ts
├── view.pug
└── view.scss
```

---

### 6. 파일 처리 요청

**키워드**: "파일 업로드", "다운로드", "이미지 처리", "파일시스템"

**참조 문서**:
- `.github/devdocs/wiz-docs/examples.md` (파일 업로드/다운로드)
- `.github/devdocs/wiz-docs/api/wiz-filesystem.md`
- `.github/devdocs/wiz-docs/api-reference.md`

**파일 업로드 패턴**:
```python
# api.py
def upload():
    files = wiz.request.files()
    fs = wiz.project.fs("data", "uploads")
    
    for filename in files:
        file = files[filename]
        filepath = fs.abspath(file.filename)
        file.save(filepath)
    
    wiz.response.status(200)
```

---

### 7. WebSocket/실시간 통신 요청

**키워드**: "실시간", "웹소켓", "양방향 통신", "socket"

**참조 문서**:
- `.github/devdocs/wiz-docs/examples.md` (WebSocket 실시간 통신)
- `.github/devdocs/web-development-guide/1-source/1.1-app-guide.md`

**socket.py 템플릿**:
```python
def connect():
    pass

def disconnect():
    pass

def message(data):
    response = process(data)
    wiz.response.send(response)
```

---

### 8. 데이터베이스/ORM 요청

**키워드**: "데이터베이스", "테이블", "ORM", "CRUD"

**참조 문서**:
- `.github/devdocs/web-development-guide/1-source/1.3-model-guide.md` (ORM Model 섹션)
- `.github/devdocs/wiz-docs/examples.md` (데이터베이스 연동)

---

### 9. 프론트엔드 서비스 요청

**키워드**: "프론트엔드", "Angular", "Service", "TypeScript"

**참조 문서**:
- `.github/devdocs/wiz-docs/api/service-api.md`
- `.github/devdocs/web-development-guide/2-packages/2.5-libs-guide.md`

---

## 🔍 문서 조회 우선순위

### 구현 방법을 모를 때
1. `web-development-guide/` 관련 가이드 먼저 확인
2. `wiz-docs/examples.md`에서 유사 예제 검색
3. `wiz-docs/api/` 폴더에서 API 상세 확인

### API 사용법을 모를 때
1. `wiz-docs/api-reference.md` 확인
2. `wiz-docs/api/{object}.md` 상세 문서 확인

### 프로젝트 구조를 모를 때
1. `wiz-docs/architecture.md` 확인
2. `wiz-docs/usage-guide.md` 확인

---

## ⚠️ 필수 준수 규칙

### 1. Model 개발 시
- **반드시 `Model` 변수 정의**
- 클래스 또는 인스턴스 반환

### 2. App 개발 시
- **필수 파일**: `app.json`, `view.ts`, `view.pug`
- `app.json`의 `id`, `mode`, `namespace` 필수

### 3. Controller 개발 시
- 상속 시 `super().__init__()` 호출
- 인증 실패 시 `wiz.response.status(401)` 반환

### 4. Route 개발 시
- `app.json`에 `route` 필드 필수
- URL 패턴 매칭: `wiz.request.match()` 사용

### 5. 프론트엔드 개발 시
- `ngOnInit`에서 `await this.service.init()` 필수
- 데이터 변경 후 `await this.service.render()` 필수

---

## 📝 코드 생성 체크리스트

### Page 생성 시
- [ ] `app.json` 필드 완성 (mode, id, title, namespace, viewuri, layout)
- [ ] `view.ts`에 Service 주입 및 초기화
- [ ] `view.pug` 템플릿 작성
- [ ] 필요 시 `api.py` 함수 추가

### API 생성 시
- [ ] 요청 데이터 파싱 (`wiz.request.query()`)
- [ ] 응답 반환 (`wiz.response.status()`)
- [ ] 에러 처리 포함

### Model 생성 시
- [ ] `Model` 변수 정의 확인
- [ ] 필요한 메서드 구현
- [ ] wiz 객체 활용 (session, fs 등)

---

## 💡 컨텍스트 수집 가이드

개발 요청 처리 전 다음을 확인하세요:

1. **기존 프로젝트 구조**: `src/` 디렉토리 확인
2. **사용 중인 패키지**: `src/portal/` 디렉토리 확인
3. **Controller 체인**: `src/controller/` 파일 확인
4. **기존 Model**: `src/model/` 디렉토리 확인
5. **참조할 패턴**: 유사한 기존 코드 확인
