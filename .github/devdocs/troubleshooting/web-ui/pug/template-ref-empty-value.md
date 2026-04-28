# Pug 템플릿 참조 변수 `#ref=""` 빈 문자열 필수

- **카테고리**: web-ui / pug
- **키워드**: `#ref`, `NG0301`, 템플릿 참조 변수, `=""`, Angular
- **심각도**: 런타임 오류 (Angular NG0301)

## 증상

Pug에서 Angular 템플릿 참조 변수(`#ref`)를 값 없이 선언하면, 빌드는 성공하지만 런타임에서 `NG0301: Export of name '...' not found` 오류가 발생한다.

```pug
//- ❌ 값 없이 선언 → Pug가 #myRef="#myRef"로 변환 → NG0301
div(#monacoContainer, class="w-full h-full")
ng-template(#treeNode, let-item="item")
```

## 원인

Pug 컴파일러는 `#attr`(값 없는 속성)을 `#attr="#attr"`(속성값 = 속성명)로 자동 변환한다. Angular는 `#monacoContainer="monacoContainer"`를 "monacoContainer라는 이름의 Directive export를 찾겠다"고 해석하여, 해당 export가 없으면 `NG0301` 에러를 발생시킨다.

## 해결

템플릿 참조 변수를 선언할 때 **반드시 빈 문자열 값(`=""`)을 명시**한다.

```pug
//- ✅ 빈 문자열 값 명시 → #monacoContainer="" → 정상 참조
div(#monacoContainer="", class="w-full h-full")
ng-template(#treeNode="", let-item="item")

//- ✅ 다른 예시
input(#searchInput="", type="text", class="w-full px-3 py-2")
textarea(#editor="", rows="10")
```

## 적용 범위

- 모든 `#변수명` 형태의 Angular 템플릿 참조 변수
- `ng-template`, `div`, `input` 등 모든 HTML 요소에 공통 적용
- Directive export가 있는 경우 (`#form="ngForm"` 등)에는 해당 값을 지정하되, **빈 참조**인 경우 반드시 `=""` 사용
