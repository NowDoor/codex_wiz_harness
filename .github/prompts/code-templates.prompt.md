# WIZ 프레임워크 코드 템플릿

이 문서는 WIZ 프레임워크 개발 시 사용할 수 있는 표준 코드 템플릿입니다.

---

## 📄 Page 템플릿

### app.json
```json
{
    "mode": "page",
    "id": "page.{{NAME}}",
    "title": "/{{URL_PATH}}",
    "namespace": "{{NAME}}",
    "viewuri": "/{{URL_PATH}}",
    "category": "",
    "controller": "user",
    "layout": "layout.aside",
    "template": "wiz-page-{{NAME}}()"
}
```

### view.ts
```typescript
import { OnInit } from "@angular/core";
import { Service } from '@wiz/libs/portal/season/service';

export class Component implements OnInit {
    constructor(public service: Service) { }

    public loaded: boolean = false;
    public data: any = null;

    public async ngOnInit() {
        await this.service.init();
        await this.service.auth.init();
        await this.service.auth.allow(true, "/authenticate");
        await this.service.render();
        await this.load();
    }

    public async load() {
        this.loaded = false;
        await this.service.render();

        const { code, data } = await wiz.call("load");
        if (code !== 200) {
            await this.service.alert.error("데이터 로드 실패");
            return;
        }

        this.data = data;
        this.loaded = true;
        await this.service.render();
    }
}
```

### view.pug
```pug
.page-container.p-4
    // 로딩 상태
    div(*ngIf="!loaded")
        wiz-portal-season-loading-season

    // 콘텐츠 영역
    div(*ngIf="loaded")
        h1.text-2xl.font-bold 페이지 제목
        
        .content.mt-4
            // 콘텐츠 내용
```

### view.scss
```scss
.page-container {
    min-height: 100vh;
    
    .content {
        // 스타일
    }
}
```

### api.py
```python
def load():
    """데이터 로드"""
    # 데이터 조회 로직
    data = {}
    wiz.response.status(200, data)

def save():
    """데이터 저장"""
    params = wiz.request.query()
    # 저장 로직
    wiz.response.status(200)
```

---

## 📄 Layout 템플릿

### app.json
```json
{
    "mode": "layout",
    "id": "layout.{{NAME}}",
    "title": "{{NAME}}",
    "namespace": "{{NAME}}",
    "viewuri": "",
    "category": "",
    "controller": "base",
    "template": "wiz-layout-{{NAME}}()"
}
```

### view.ts
```typescript
import { OnInit } from '@angular/core';
import { Service } from '@wiz/libs/portal/season/service';

export class Component implements OnInit {
    constructor(public service: Service) { }

    public async ngOnInit() {
        await this.service.init();
    }
}
```

### view.pug
```pug
.layout-container.flex.h-screen
    // 사이드바 영역
    aside.sidebar
        // 네비게이션

    // 메인 콘텐츠 영역
    main.flex-1.overflow-auto
        router-outlet

// 공통 알림 컴포넌트
wiz-portal-season-alert
```

---

## 📄 Component 템플릿

### app.json
```json
{
    "mode": "component",
    "id": "component.{{NAME}}",
    "title": "{{NAME}}",
    "namespace": "{{NAME}}",
    "viewuri": "",
    "category": "",
    "controller": "",
    "ng": {
        "selector": "wiz-component-{{NAME}}",
        "inputs": ["config"],
        "outputs": []
    },
    "template": "wiz-component-{{NAME}}([config]=\"\")"
}
```

### view.ts
```typescript
import { OnInit, Input, Output, EventEmitter } from "@angular/core";
import { Service } from '@wiz/libs/portal/season/service';

export class Component implements OnInit {
    @Input() config: any = {};
    @Output() onEvent = new EventEmitter<any>();

    constructor(public service: Service) { }

    public async ngOnInit() {
        await this.service.init();
        await this.service.render();
    }

    public emit(data: any) {
        this.onEvent.emit(data);
    }
}
```

---

## 📄 Route 템플릿

### app.json
```json
{
    "id": "{{NAME}}",
    "title": "/api/{{ROUTE_PATH}}/<path:path>",
    "route": "/api/{{ROUTE_PATH}}/<path:path>",
    "viewuri": "",
    "category": "api",
    "controller": "user"
}
```

### controller.py
```python
import json
import datetime

# URL 패턴 매칭
segment = wiz.request.match("/api/{{ROUTE_PATH}}/<action>")
action = segment.action

# 공통 모델 로드
model = wiz.model("{{MODEL_PATH}}")

# 목록 조회
if action == "list":
    data = wiz.request.query()
    result = model.list(**data)
    wiz.response.status(200, result)

# 상세 조회
if action == "get":
    id = wiz.request.query("id", True)
    result = model.get(id)
    wiz.response.status(200, result)

# 생성
if action == "create":
    data = wiz.request.query()
    model.create(data)
    wiz.response.status(200)

# 수정
if action == "update":
    id = wiz.request.query("id", True)
    data = wiz.request.query()
    model.update(id, data)
    wiz.response.status(200)

# 삭제
if action == "delete":
    id = wiz.request.query("id", True)
    model.delete(id)
    wiz.response.status(200)

# 기본 응답
wiz.response.status(404, {"error": "Not found"})
```

---

## 📄 Controller 템플릿

### base.py (기본)
```python
import season
import datetime
import json

class Controller:
    def __init__(self):
        # 세션 초기화
        wiz.session = wiz.model("portal/season/session").use()
        sessiondata = wiz.session.get()
        wiz.response.data.set(session=sessiondata)

        # 다국어 처리
        lang = wiz.request.query("lang", None)
        if lang is not None:
            wiz.response.lang(lang)
            wiz.response.redirect(wiz.request.uri())

    def json_default(self, value):
        if isinstance(value, datetime.date):
            return value.strftime('%Y-%m-%d %H:%M:%S')
        return str(value)
```

### user.py (로그인 필수)
```python
import season

class Controller(wiz.controller("base")):
    def __init__(self):
        super().__init__()
        
        if wiz.session.has("id") == False:
            wiz.response.status(401)
```

### admin.py (관리자 전용)
```python
import season

class Controller(wiz.controller("user")):
    def __init__(self):
        super().__init__()
        
        membership = wiz.session.get("membership", "")
        if membership not in ["admin"]:
            wiz.response.status(401)
```

---

## 📄 Model 템플릿

### 기본 Model (인스턴스 반환)
```python
# src/model/{{NAME}}.py

class {{CLASS_NAME}}:
    def __init__(self):
        pass

    def list(self, page=1, limit=20, **kwargs):
        """목록 조회"""
        return {"rows": [], "total": 0}

    def get(self, id):
        """상세 조회"""
        return {}

    def create(self, data):
        """생성"""
        pass

    def update(self, id, data):
        """수정"""
        pass

    def delete(self, id):
        """삭제"""
        pass

Model = {{CLASS_NAME}}()
```

### ORM Model (데이터베이스)
```python
# src/model/db/{{TABLE}}.py

from sqlalchemy import Column, String, Text, DateTime, func
from playhouse.shortcuts import model_to_dict, dict_to_model

orm = wiz.model("portal/season/orm")
base = wiz.model("portal/season/dbbase")

class Table(orm.Model):
    __tablename__ = "{{TABLE_NAME}}"
    
    id = Column(String(32), primary_key=True)
    title = Column(String(255))
    content = Column(Text)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

class {{CLASS_NAME}}(base):
    table = Table

    def list(self, page=1, limit=20, **kwargs):
        """페이지네이션 목록"""
        return super().list(page=page, limit=limit, **kwargs)

    def get(self, id):
        """ID로 조회"""
        return super().get(id)

    def create(self, data):
        """생성"""
        return super().insert(data)

    def update(self, id, data):
        """수정"""
        return super().update(id, data)

    def delete(self, id):
        """삭제"""
        return super().delete(id)

Model = {{CLASS_NAME}}()
```

### 세션 Model
```python
# src/model/session.py

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

## 📄 Portal App 템플릿

### app.json
```json
{
    "type": "app",
    "mode": "portal",
    "title": "{{NAME}}",
    "id": "{{NAME}}",
    "namespace": "{{NAME}}",
    "viewuri": "",
    "category": "",
    "controller": "",
    "ng": {
        "selector": "wiz-portal-{{PACKAGE}}-{{NAME}}",
        "inputs": ["config"],
        "outputs": []
    },
    "template": "wiz-portal-{{PACKAGE}}-{{NAME}}([config]=\"\")"
}
```

### view.ts
```typescript
import { OnInit, Input, Output, EventEmitter } from "@angular/core";
import { Service } from '@wiz/libs/portal/season/service';

export class Component implements OnInit {
    @Input() config: any = {};
    @Output() onEvent = new EventEmitter<any>();

    constructor(public service: Service) { }

    public async ngOnInit() {
        await this.service.init();
        await this.service.render();
    }
}
```

---

## 📄 WebSocket 템플릿

### socket.py
```python
def connect():
    """클라이언트 연결 시"""
    pass

def disconnect():
    """클라이언트 연결 해제 시"""
    pass

def message(data):
    """메시지 수신 시"""
    # 처리 로직
    response = {"status": "ok", "data": data}
    wiz.response.send(response)

def broadcast(data):
    """브로드캐스트"""
    wiz.response.send(data, broadcast=True)
```

---

## 📄 Libs 템플릿 (TypeScript 라이브러리)

### {name}.ts
```typescript
// src/portal/{package}/libs/{name}.ts

import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class {{CLASS_NAME}} {
    constructor() { }

    public async init() {
        // 초기화 로직
    }

    public method() {
        // 메서드 구현
    }
}
```

**사용 예시**:
```typescript
import { {{CLASS_NAME}} } from '@wiz/libs/portal/{{PACKAGE}}/{{NAME}}';

export class Component {
    constructor(public myLib: {{CLASS_NAME}}) { }
}
```
