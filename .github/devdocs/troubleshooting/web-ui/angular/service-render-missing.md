# 이벤트 핸들러에서 service.render() 누락 시 UI 미갱신

- **카테고리**: web-ui / angular
- **키워드**: `service.render()`, `detectChanges()`, UI 미반영, 상태 변경, 이벤트 핸들러
- **심각도**: 런타임 (UI 미반영 — 다른 조작 시 지연 반영)

## 증상

버튼 클릭, 입력 변경 등 이벤트 핸들러에서 컴포넌트 상태를 변경했는데, **화면에 즉시 반영되지 않는다**. 다른 요소를 클릭하거나 마우스를 움직이면 뒤늦게 반영된다.

## 원인

WIZ의 `service.render()`는 `ChangeDetectorRef.detectChanges()`를 호출한다. WIZ 프레임워크에서는 이벤트 핸들러가 상태를 변경한 뒤 **명시적으로 `service.render()`를 호출하지 않으면** Angular가 변경을 감지하지 못해 UI가 갱신되지 않는다.

## 해결

**모든 상태 변경 이벤트 핸들러 끝에 `await this.service.render()` 호출 필수**.

```typescript
// ❌ 상태만 변경하고 render 미호출 → UI 미반영
public startEdit(item: any) {
    this.editingId = item.id;
    this.editingName = item.name;
}

// ✅ render 호출 → 즉시 반영
public async startEdit(item: any) {
    this.editingId = item.id;
    this.editingName = item.name;
    await this.service.render();
}
```

비동기 작업(`wiz.call()` 등) 후에도 반드시 호출:

```typescript
public async loadData() {
    const res = await wiz.call("search", { page: this.page });
    if (res.code === 200) {
        this.items = res.data;
    }
    await this.service.render();    // ✅ 비동기 작업 후에도 필수
}
```

## 적용 범위

- 모든 `(click)`, `(change)`, `(input)` 이벤트 핸들러
- `wiz.call()` 콜백/then 이후
- Socket.IO `this.socket.on()` 콜백 내
- `setTimeout`, `setInterval` 콜백 내
- Promise/Observable 구독 콜백 내
