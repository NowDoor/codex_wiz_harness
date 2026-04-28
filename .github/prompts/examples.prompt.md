# WIZ 프레임워크 실전 예제 빠른 참조

자주 사용되는 개발 패턴의 실전 예제를 빠르게 참조할 수 있는 문서입니다.

---

## 1. 기본 CRUD 페이지

### 구조
```
src/app/page.users/
├── app.json
├── view.ts
├── view.pug
├── view.scss
└── api.py
```

### app.json
```json
{
    "mode": "page",
    "id": "page.users",
    "title": "/users",
    "namespace": "users",
    "viewuri": "/users",
    "layout": "layout.aside",
    "controller": "user"
}
```

### view.ts
```typescript
import { OnInit } from "@angular/core";
import { Service } from '@wiz/libs/portal/season/service';

export class Component implements OnInit {
    constructor(public service: Service) { }

    public list: any[] = [];
    public search = { page: 1, text: '' };
    public pageConfig: any = {};
    public loaded: boolean = false;

    public async ngOnInit() {
        await this.service.init();
        await this.service.auth.init();
        await this.service.auth.allow(true, "/login");
        await this.service.render();
        await this.load();
    }

    public async load(page: number = 1) {
        this.search.page = page;
        this.loaded = false;
        await this.service.render();

        const { code, data } = await wiz.call("list", this.search);
        if (code !== 200) return;

        this.list = data.rows;
        this.pageConfig = {
            current: data.page,
            total: data.total,
            size: data.limit,
            handler: (p: number) => this.load(p)
        };
        this.loaded = true;
        await this.service.render();
    }

    public async delete(item: any) {
        if (!await this.service.alert.confirm("삭제하시겠습니까?")) return;
        
        const { code } = await wiz.call("delete", { id: item.id });
        if (code === 200) {
            await this.service.alert.success("삭제되었습니다");
            await this.load();
        }
    }
}
```

### view.pug
```pug
.page-container.p-4
    .flex.justify-between.items-center.mb-4
        h1.text-2xl.font-bold 사용자 관리
        button.btn.btn-primary((click)="create()") 새 사용자

    // 검색
    .search-box.mb-4
        input.form-control(
            [(ngModel)]="search.text",
            (keyup.enter)="load()",
            placeholder="검색어 입력")

    // 로딩
    div(*ngIf="!loaded")
        wiz-portal-season-loading-season

    // 목록
    .table-container(*ngIf="loaded")
        table.table
            thead
                tr
                    th ID
                    th 이름
                    th 이메일
                    th 작업
            tbody
                tr(*ngFor="let item of list")
                    td {{ item.id }}
                    td {{ item.name }}
                    td {{ item.email }}
                    td
                        button.btn.btn-sm.btn-danger((click)="delete(item)") 삭제

    // 페이지네이션
    wiz-portal-season-pagination([config]="pageConfig", *ngIf="loaded")
```

### api.py
```python
def list():
    page = int(wiz.request.query("page", 1))
    limit = int(wiz.request.query("limit", 20))
    text = wiz.request.query("text", "")
    
    model = wiz.model("db/user")
    result = model.list(page=page, limit=limit, text=text)
    wiz.response.status(200, result)

def delete():
    id = wiz.request.query("id", True)
    wiz.model("db/user").delete(id)
    wiz.response.status(200)
```

---

## 2. 파일 업로드

### api.py
```python
def upload():
    files = wiz.request.files()
    if not files:
        wiz.response.status(400, {"error": "파일이 없습니다"})

    fs = wiz.project.fs("data", "uploads")
    uploaded = []

    for key in files:
        file = files[key]
        filename = file.filename
        filepath = fs.abspath(filename)
        file.save(filepath)
        uploaded.append(filename)

    wiz.response.status(200, {"files": uploaded})
```

### view.ts
```typescript
public async upload(event: any) {
    const files = event.target.files;
    if (!files.length) return;

    const formData = new FormData();
    for (let i = 0; i < files.length; i++) {
        formData.append('file' + i, files[i]);
    }

    await this.service.loading.show();
    const { code, data } = await wiz.call("upload", formData);
    await this.service.loading.hide();

    if (code === 200) {
        await this.service.alert.success("업로드 완료");
    } else {
        await this.service.alert.error("업로드 실패");
    }
}
```

### view.pug
```pug
input.hidden(
    type="file",
    #fileInput,
    multiple,
    (change)="upload($event)")
button.btn.btn-primary((click)="fileInput.click()") 파일 선택
```

---

## 3. 폼 처리

### view.ts
```typescript
public form: any = {
    name: '',
    email: '',
    content: ''
};

public async save() {
    if (!this.form.name) {
        await this.service.alert.warning("이름을 입력하세요");
        return;
    }

    await this.service.loading.show();
    const { code } = await wiz.call("save", this.form);
    await this.service.loading.hide();

    if (code === 200) {
        await this.service.alert.success("저장되었습니다");
        await this.service.href("/list");
    } else {
        await this.service.alert.error("저장에 실패했습니다");
    }
}
```

### api.py
```python
def save():
    data = wiz.request.query()
    
    # 유효성 검사
    if not data.get("name"):
        wiz.response.status(400, {"error": "이름 필수"})
    
    model = wiz.model("db/item")
    model.create(data)
    wiz.response.status(200)
```

### view.pug
```pug
.form-container
    .form-group
        label 이름
        input.form-control([(ngModel)]="form.name")
    
    .form-group
        label 이메일
        input.form-control([(ngModel)]="form.email", type="email")
    
    .form-group
        label 내용
        textarea.form-control([(ngModel)]="form.content", rows="5")
    
    .form-actions.mt-4
        button.btn.btn-primary((click)="save()") 저장
        button.btn.btn-secondary((click)="cancel()", class="ml-2") 취소
```

---

## 4. 로그인/인증

### Route: src/route/auth/

**app.json**
```json
{
    "id": "auth",
    "title": "/auth/<action>",
    "route": "/auth/<action>",
    "controller": "base"
}
```

**controller.py**
```python
segment = wiz.request.match("/auth/<action>")
action = segment.action

# 로그인
if action == "login":
    data = wiz.request.query()
    email = data.get("email")
    password = data.get("password")
    
    user = wiz.model("db/user").login(email, password)
    if not user:
        wiz.response.status(401, {"error": "인증 실패"})
    
    wiz.session.set(**user)
    wiz.response.status(200, user)

# 로그아웃
if action == "logout":
    wiz.session.clear()
    wiz.response.status(200)

# 현재 세션
if action == "session":
    data = wiz.session.get()
    wiz.response.status(200, data)
```

---

## 5. 세션 Model

### src/portal/season/model/session.py
```python
class Session:
    def __init__(self):
        self.flask = wiz.server.package.flask
    
    def get(self, key=None, default=None):
        if key is None:
            return dict(self.flask.session)
        return self.flask.session.get(key, default)
    
    def set(self, **kwargs):
        for key, value in kwargs.items():
            self.flask.session[key] = value
    
    def has(self, key):
        return key in self.flask.session
    
    def delete(self, key):
        if key in self.flask.session:
            del self.flask.session[key]
    
    def clear(self):
        self.flask.session.clear()
    
    @classmethod
    def use(cls):
        return cls()

Model = Session()
```

---

## 6. ORM Model (데이터베이스)

### src/model/db/user.py
```python
from sqlalchemy import Column, String, DateTime, func
import season

orm = wiz.model("portal/season/orm")
base = wiz.model("portal/season/dbbase")

class Table(orm.Model):
    __tablename__ = "users"
    
    id = Column(String(32), primary_key=True, default=lambda: season.util.string.random(32))
    name = Column(String(255))
    email = Column(String(255), unique=True)
    password = Column(String(255))
    created_at = Column(DateTime, default=func.now())

class User(base):
    table = Table

    def list(self, page=1, limit=20, text=""):
        query = self.session().query(self.table)
        if text:
            query = query.filter(self.table.name.like(f"%{text}%"))
        
        total = query.count()
        rows = query.offset((page-1)*limit).limit(limit).all()
        
        return {
            "rows": [self.to_dict(r) for r in rows],
            "total": total,
            "page": page,
            "limit": limit
        }

    def login(self, email, password):
        import hashlib
        hashed = hashlib.sha256(password.encode()).hexdigest()
        
        user = self.session().query(self.table)\
            .filter_by(email=email, password=hashed)\
            .first()
        
        if user:
            return self.to_dict(user)
        return None

Model = User()
```

---

## 📎 상세 예제 문서

더 많은 예제는 아래 문서를 참조하세요:
- `.github/devdocs/wiz-docs/examples.md`
