# WIZ 프레임워크 개발 시 컨텍스트 수집 가이드

이 문서는 GitHub Copilot Agent가 WIZ 프레임워크 개발 요청을 처리하기 전에 수집해야 할 컨텍스트를 정의합니다.

---

## 📋 요청 처리 전 컨텍스트 수집 체크리스트

### 1. 프로젝트 구조 파악

**확인할 디렉토리:**
```
project/main/src/
├── app/           # 기존 페이지/컴포넌트 확인
├── controller/    # 컨트롤러 체인 확인
├── model/         # 기존 모델 확인
├── route/         # 기존 라우트 확인
└── portal/        # 사용 가능한 패키지 확인
```

**수집 목적:**
- 기존 코드 패턴 파악
- 재사용 가능한 컴포넌트 식별
- 네이밍 컨벤션 확인

---

### 2. Controller 체인 파악

**확인 파일:**
```
src/controller/
├── base.py      # 세션 초기화 방식
├── user.py      # 인증 검증 방식
└── admin.py     # 권한 검증 방식
```

**확인 사항:**
- 세션 모델 호출 방식
- 인증 검증 로직
- 권한 레벨 정의
- 공통 유틸리티 메서드

---

### 3. 사용 가능한 패키지 확인

**확인 디렉토리:**
```
src/portal/
├── season/      # 기본 패키지 (필수)
│   ├── model/session.py
│   ├── libs/service.ts
│   └── app/
└── {package}/   # 추가 패키지
```

**주요 패키지 모델:**
- `portal/season/session` - 세션 관리
- `portal/season/config` - 설정 관리
- `portal/season/orm` - ORM 유틸리티

---

### 4. 기존 Model 구조 파악

**확인 디렉토리:**
```
src/model/
├── db/          # DB 테이블 모델
├── struct/      # 비즈니스 로직 구조체
└── *.py         # 유틸리티 모델
```

**확인 사항:**
- ORM 사용 여부
- Model 변수 반환 패턴 (클래스 vs 인스턴스)
- 공통 메서드 패턴

---

### 5. 기존 App 패턴 분석

**확인 항목:**
- `app.json` 필드 사용 패턴
- `view.ts` 초기화 패턴
- `api.py` 함수 네이밍
- 레이아웃 적용 방식

---

## 🔍 요청 유형별 컨텍스트 수집

### Page 생성 요청 시

1. **기존 유사 페이지 확인**
   ```
   src/app/page.*/
   ```

2. **사용할 레이아웃 확인**
   ```
   src/app/layout.*/app.json
   ```

3. **적용할 컨트롤러 확인**
   ```
   src/controller/*.py
   ```

4. **사용 가능한 컴포넌트 확인**
   ```
   src/app/component.*/
   src/portal/*/app/
   ```

---

### API/Route 생성 요청 시

1. **기존 라우트 패턴 확인**
   ```
   src/route/*/app.json
   src/route/*/controller.py
   ```

2. **관련 Model 확인**
   ```
   src/model/
   src/portal/*/model/
   ```

3. **인증 요구사항 확인**
   - Controller 체인 확인
   - 세션 검증 로직 확인

---

### Model 생성 요청 시

1. **기존 Model 패턴 확인**
   ```
   src/model/*.py
   ```

2. **ORM 설정 확인**
   ```
   src/portal/season/model/orm.py
   src/portal/season/model/dbbase.py
   ```

3. **DB 연결 설정 확인**
   ```
   config/boot.py
   ```

---

### 컴포넌트 생성 요청 시

1. **기존 컴포넌트 확인**
   ```
   src/app/component.*/
   src/portal/*/app/
   ```

2. **Import 패턴 확인**
   - `@wiz/libs/` 사용 패턴
   - 셀렉터 네이밍 패턴

---

## 📚 문서 참조 우선순위

### 구현 방법 질문
1. `.github/devdocs/web-development-guide/1-source/` (해당 가이드)
2. `.github/devdocs/wiz-docs/examples.md`
3. 기존 코드에서 유사 패턴 검색

### API 사용 질문
1. `.github/devdocs/wiz-docs/api-reference.md`
2. `.github/devdocs/wiz-docs/api/` (상세 API)

### 구조/아키텍처 질문
1. `.github/devdocs/wiz-docs/architecture.md`
2. `.github/devdocs/wiz-docs/usage-guide.md`

---

## ⚠️ 주의사항

### 코드 생성 전 확인
- [ ] 기존 코드의 네이밍 컨벤션 확인
- [ ] Controller 상속 체인 확인
- [ ] Model 변수 반환 패턴 확인
- [ ] Import 경로 패턴 확인

### 수정 전 확인
- [ ] 해당 파일의 전체 구조 파악
- [ ] 관련 파일 영향도 분석
- [ ] 의존성 확인 (다른 파일에서 호출)

### 삭제 전 확인
- [ ] 다른 파일에서 참조 여부
- [ ] Import 의존성
- [ ] 라우팅 연결

---

## 💡 효율적인 컨텍스트 수집 팁

1. **패턴 파악을 위한 파일 검색**
   - 유사한 기능의 기존 코드 검색
   - app.json 필드 사용 패턴 확인

2. **의존성 파악**
   - Import 문 확인
   - wiz.model() 호출 확인
   - wiz.controller() 상속 확인

3. **설정 확인**
   - portal.json (패키지 설정)
   - app.json (라우팅, 레이아웃)
   - config/boot.py (서버 설정)
