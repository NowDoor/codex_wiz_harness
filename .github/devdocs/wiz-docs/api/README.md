# WIZ Framework API Reference

WIZ 프레임워크의 전체 API 레퍼런스 문서입니다.

> ⚠️ **패키지 버전 안전성 주의**: 이 문서의 패키지 관련 예제(ORM, Session, Service, season.util 등)는 **일반적인 호출 패턴**을 보여줍니다. 패키지별 세부 API는 버전에 따라 다를 수 있으므로, 구현 시 반드시 해당 패키지의 `src/portal/{package}/README.md`를 확인하십시오.

## 📚 API 카테고리

### 백엔드 API (Python)

#### 1. [wiz 객체](wiz-object.md)
WIZ 프레임워크의 핵심 객체로, Python 코드(api.py, controller.py, model 등)에서 사용 가능한 모든 API를 제공합니다.

- **[wiz.request](wiz-request.md)** - HTTP 요청 처리
- **[wiz.response](wiz-response.md)** - HTTP 응답 생성
- **[wiz.project](wiz-project.md)** - 프로젝트 관리
- **[wiz.session](wiz-session.md)** - 세션 관리
- **[wiz.fs()](wiz-filesystem.md)** - 파일시스템 접근
- **[wiz.model()](wiz-model.md)** - 모델 로드
- **[wiz.controller()](wiz-controller.md)** - 컨트롤러 로드
- **[wiz.logger()](wiz-logger.md)** - 로깅

#### 2. [유틸리티 (season.util)](utilities.md)
프레임워크 전역에서 사용 가능한 유틸리티 함수 및 클래스

- Logger
- Cache
- Filesystem
- String
- Compiler

### 프론트엔드 API (TypeScript)

#### 3. [Service API](service-api.md)
Angular 컴포넌트에서 사용하는 Service 클래스 API

- service.api - 백엔드 API 호출
- service.socket - WebSocket 통신
- service.alert - 알림 및 대화상자
- service.loading - 로딩 인디케이터
- service.render - 컴포넌트 렌더링

### 설정

#### 4. [Configuration](configuration.md)
프로젝트 설정 파일 구조 및 옵션

- boot.py
- ide.py
- service.py
- plugin.json

## 🚀 빠른 참조

### 자주 사용하는 API

#### 요청 데이터 가져오기
```python
data = wiz.request.query()  # 모든 파라미터
name = wiz.request.query("name", "default")  # 특정 파라미터
```

#### JSON 응답 반환
```python
wiz.response.status(200, {"message": "Success"})
```

#### 파일 업로드 처리
```python
files = wiz.request.files()
for key in files:
    file = files[key]
    # 파일 처리
```

#### 세션 관리
```python
wiz.session.set("user_id", 123)
user_id = wiz.session.get("user_id")
```

#### 백엔드 API 호출 (TypeScript)
```typescript
let res = await this.service.api.call("functionName", data);
```

## 📖 문서 규칙

### 파라미터 표기

- **필수 파라미터**: `param` (볼드 표시)
- 선택적 파라미터: `[param]` (대괄호로 표시)
- 기본값: `param=value`

### 반환 타입

- `None` - 값을 반환하지 않음
- `str` - 문자열
- `int` - 정수
- `dict` - 딕셔너리
- `list` - 리스트
- `bool` - 불리언
- `object` - 객체

### 예제 코드

각 API 문서에는 실제 사용 예제가 포함되어 있습니다.

## 🔍 검색 가이드

### API 찾기

1. **요청 처리**: [wiz.request](wiz-request.md)
2. **응답 생성**: [wiz.response](wiz-response.md)
3. **파일 작업**: [wiz.fs()](wiz-filesystem.md), [wiz.project.fs()](wiz-project.md)
4. **데이터베이스**: [wiz.model()](wiz-model.md)
5. **세션**: [wiz.session](wiz-session.md)
6. **프론트엔드 통신**: [Service API](service-api.md)

## 버전 정보

이 문서는 WIZ Framework (season) 최신 버전을 기준으로 작성되었습니다.

## 기여

API 문서에 오류나 누락된 내용이 있다면 GitHub Issues를 통해 알려주세요.
