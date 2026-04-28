# Pug 소수점/슬래시 클래스 파싱 실패

- **카테고리**: web-ui / pug
- **키워드**: `gap-1.5`, `w-1/2`, `bg-black/50`, dot notation, class 속성
- **심각도**: 빌드 실패 (컴파일 타임)

## 증상

Tailwind CSS의 소수점(`.`) 또는 슬래시(`/`) 포함 클래스를 Pug dot notation으로 작성하면 빌드 오류 발생.

```pug
//- ❌ 빌드 실패 — Pug가 .gap-1 과 .5 를 별개 클래스로 파싱
div.gap-1.5.p-2

//- ❌ 빌드 실패 — 슬래시가 Pug 문법과 충돌
div.hover_bg-orange-100/40
```

## 원인

Pug는 `.`을 클래스 구분자로, `/`를 self-closing 태그 구분자로 사용한다. Tailwind의 `gap-1.5`, `bg-opacity-100/40` 같은 클래스명이 Pug 문법과 충돌한다.

## 해결

소수점·슬래시가 포함된 Tailwind 클래스는 반드시 `class=""` 속성 방식으로 작성한다.

```pug
//- ✅ class 속성 방식 — 안전
div(class="gap-1.5 p-2")
div(class="hover:bg-orange-100/40")

//- ✅ 혼합 사용 가능 — 안전한 클래스만 dot notation
div.flex.items-center(class="gap-1.5 p-2.5")
```

## 판단 기준

| 클래스 패턴 | 예시 | 방식 |
|-------------|------|------|
| 소수점 포함 | `gap-1.5`, `p-2.5`, `text-sm/6` | `class=""` 필수 |
| 슬래시 포함 | `bg-black/50`, `w-1/2` | `class=""` 필수 |
| 단순 하이픈 | `flex`, `items-center`, `text-sm` | dot notation 가능 |
