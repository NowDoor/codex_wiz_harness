# Pug 멀티라인 속성 파싱 실패

- **카테고리**: web-ui / pug
- **키워드**: `*ngIf`, `*ngFor`, 멀티라인, 콤마, 여는 괄호
- **심각도**: 빌드 실패 (컴파일 타임)

## 증상

Angular 디렉티브(`*ngIf`, `*ngFor`, `[class]` 등)를 포함한 속성을 여러 줄로 나눌 때, 첫 번째 속성이 여는 괄호와 같은 줄에 없으면 파싱 오류 발생.

```pug
//- ❌ 파싱 실패 — 첫 속성이 다음 줄에 위치
div(
  *ngIf="condition"
  class="flex"
)
```

## 원인

WIZ의 Pug 컴파일러는 여는 괄호 `(` 직후에 첫 속성이 같은 줄에 시작되어야 정상 파싱한다. 줄바꿈이 개입하면 속성 블록 인식에 실패한다.

## 해결

**모든 속성을 콤마(`,`)로 구분하고, 첫 속성은 반드시 여는 괄호와 같은 줄에 배치**한다.

```pug
//- ✅ 단일 줄 — 권장
div(*ngIf="condition", class="flex items-center")

//- ✅ 멀티라인 — 첫 속성을 괄호와 같은 줄에
div(*ngIf="condition",
  class="flex items-center",
  (click)="onClick()")

//- ✅ 긴 속성 — 콤마 구분
app-component(*ngIf="data",
  [items]="list",
  (onChange)="handle($event)",
  class="w-full")
```

## 핵심 규칙

1. 첫 속성은 `(` 바로 뒤에 위치
2. 속성 사이는 반드시 `,` 콤마로 구분
3. `)` 닫는 괄호는 마지막 속성과 같은 줄 또는 다음 줄
