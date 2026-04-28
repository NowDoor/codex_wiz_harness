# Angular 컴포넌트 :host 스타일 필수

- **카테고리**: web-ui / angular
- **키워드**: `:host`, `display: block`, `height: 100%`, 레이아웃 깨짐, 스크롤 불가, flex
- **심각도**: 런타임 (레이아웃 깨짐)

## 증상

Page/Layout App에서 `h-full`, `flex-1`을 사용해도 컴포넌트가 화면 전체를 채우지 못하거나, 스크롤 영역이 동작하지 않는다. `overflow-y-auto`를 설정해도 스크롤바가 나타나지 않는다.

## 원인

Angular 컴포넌트의 **호스트 요소**(`<wiz-page-xxx>`, `<wiz-layout-xxx>`)는 기본적으로 `display: inline`이며 **높이가 없다**. 자식 요소에 `h-full`(height: 100%)을 써도, 부모(호스트 요소)에 높이가 설정되어 있지 않으므로 백분율 높이가 resolve되지 않는다.

```html
<!-- 빌드 결과물 DOM 구조 -->
<wiz-page-dashboard>          <!-- display: inline, height: auto → 0 -->
  <div class="h-full">        <!-- 100% of 0 = 0 -->
    <div class="overflow-y-auto">  <!-- 높이 0이므로 스크롤 안 됨 -->
      ...
    </div>
  </div>
</wiz-page-dashboard>
```

## 해결

모든 **Page/Layout App**의 `view.scss`에 `:host` 스타일을 필수 선언한다.

```scss
// view.scss — 기본 패턴 (Page)
:host {
    display: block;
    height: 100%;
}
```

```scss
// view.scss — flex 컨테이너 패턴 (Layout)
:host {
    display: flex;
    flex-direction: column;
    height: 100%;
}
```

## 적용 범위

| App 유형 | :host 필수 여부 | 권장 패턴 |
|---------|-----------------|----------|
| Page | ✅ 필수 | `display: block; height: 100%;` |
| Layout | ✅ 필수 | `display: flex; flex-direction: column; height: 100%;` |
| Component | 상황에 따라 | 부모 레이아웃에 맞춰 설정 |
| Portal App | 상황에 따라 | 삽입되는 컨텍스트에 따라 결정 |

## 체크리스트

새 Page/Layout App 생성 시:
1. ✅ `view.scss`에 `:host` 블록 추가
2. ✅ 최상위 `div`에 `h-full` 또는 `flex-1` 설정
3. ✅ 스크롤 영역에 `min-h-0 overflow-y-auto` 설정 (flex 레이아웃 시)
