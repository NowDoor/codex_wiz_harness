# overflow 부모 내 드롭다운 클리핑 문제

- **카테고리**: web-ui / css
- **키워드**: `overflow`, `absolute`, `fixed`, 드롭다운, 클리핑, `getBoundingClientRect`
- **심각도**: 런타임 (UI 잘림)

## 증상

`overflow-y-auto` 또는 `overflow-hidden`이 설정된 부모 요소 안에서, `position: absolute`로 펼쳐지는 드롭다운/팝오버가 **부모 영역 밖에서 잘린다**.

## 원인

CSS에서 `overflow: auto/hidden/scroll`을 가진 요소는 **클리핑 컨텍스트**를 생성한다. `position: absolute`인 자식 요소는 이 클리핑 컨텍스트에 의해 부모 경계 밖으로 나가지 못한다.

## 해결

잘리는 드롭다운을 `position: fixed`로 변경하고, `getBoundingClientRect()`로 좌표를 동적 계산한다.

```typescript
// view.ts
openDropdown(event: MouseEvent) {
    const trigger = event.currentTarget as HTMLElement;
    const rect = trigger.getBoundingClientRect();
    this.dropdownStyle = {
        position: 'fixed',
        top: `${rect.bottom + 4}px`,
        left: `${rect.left}px`,
        zIndex: 9999
    };
    this.isDropdownOpen = true;
}
```

```pug
//- view.pug
div(*ngIf="isDropdownOpen",
  [ngStyle]="dropdownStyle",
  class="bg-white rounded-lg shadow-lg border")
  //- 드롭다운 내용
```

## 적용 범위

- 사이드바 내 프로젝트 전환 드롭다운
- 테이블 행의 액션 메뉴
- 스크롤 컨테이너 내의 모든 팝오버/툴팁
