# styles.scss 패키지 @import 누락 시 스타일 미적용

- **카테고리**: web-ui / angular
- **키워드**: `styles.scss`, `@import`, 번들, CSS 미적용, 다크모드, `data-theme`, 패키지 스타일
- **심각도**: 런타임 (무음 실패 — 스타일이 조용히 누락됨)

## 증상

패키지의 SCSS 파일에 정의된 CSS 셀렉터(예: `[data-theme="dark"]` 오버라이드)가 빌드 후 **전혀 적용되지 않는다**. 브라우저 DevTools에서 해당 셀렉터를 검색해도 찾을 수 없다.

```bash
# 번들에 다크모드 셀렉터가 0개
grep -c "data-theme" project/main/bundle/www/main.css
# 0
```

## 원인

WIZ Angular 빌드 시스템에서 최종 CSS 번들에 포함되는 스타일은 **`src/angular/styles/styles.scss`의 import 체인**을 통해 결정된다. 패키지 스타일 폴더(`src/portal/{package}/styles/`)에 SCSS 파일이 존재하더라도, `styles.scss`에서 해당 패키지의 진입점을 `@import`하지 않으면 **빌드에 포함되지 않는다**.

```
styles.scss
├── @import "portal/season/core"    ← 이 줄이 없으면
│   └── content/color.scss          ← 이 파일의 셀렉터가 번들에서 누락
│       └── [data-theme="dark"] { ... }
├── @import "portal/works/core"
└── ...
```

## 해결

패키지 스타일을 추가한 후 반드시 `src/angular/styles/styles.scss`에 해당 패키지의 `@import`를 확인/추가한다.

```scss
// src/angular/styles/styles.scss — import 체인 확인
@import "font";
@import "prose";
@import "portal/season/core";    // ✅ season 패키지 스타일 포함
@import "portal/works/core";     // ✅ works 패키지 스타일 포함
```

## 검증 방법

빌드 후 번들 CSS에 기대하는 셀렉터가 포함되었는지 확인:

```bash
# 빌드
# wiz_project_build (clean: false)

# 번들에서 셀렉터 확인
grep -c "data-theme" project/{name}/bundle/www/main.css
# 0이면 import 누락
```

## 적용 범위

- 새 패키지의 `styles/` 폴더 추가 시
- 기존 패키지 스타일에 새로운 CSS 변수/셀렉터 추가 후 미적용 시
- 다크모드, 커스텀 테마 등 CSS 변수 기반 기능 구현 시
- `portal.json`에 `"use_styles": true` 설정 확인 필수
