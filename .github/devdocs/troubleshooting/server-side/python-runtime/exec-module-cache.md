# WIZ exec() 모듈 캐시 문제

- **카테고리**: server-side / python-runtime
- **키워드**: `import`, `sys.modules`, `__pycache__`, `importlib`, 변경 미반영, hot-reload
- **심각도**: 런타임 (코드 수정이 반영되지 않음)

## 증상

Python 파일을 수정했는데, WIZ 런타임에서 이전 코드가 계속 실행된다. 특히 `import`로 로드한 커스텀 모듈이 변경사항을 반영하지 않는다.

## 원인

WIZ는 Python 파일을 `exec()`로 실행한다. 이때 `import`로 로드된 모듈은 `sys.modules`에 캐시되어, 파일이 수정되어도 기존 캐시된 버전이 사용된다. `__pycache__/` 바이트코드도 마찬가지.

## 해결

커스텀 모듈은 `importlib.util`을 사용하여 매번 새로 로드한다.

```python
import importlib.util
import sys

def load_module_fresh(module_name, module_path):
    """sys.modules 캐시를 우회하여 항상 최신 코드 로드"""
    # 기존 캐시 제거
    if module_name in sys.modules:
        del sys.modules[module_name]
    
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module
```

## 적용 범위

- `src/model/` 내 커스텀 Python 모듈 간 상호 참조 시
- `data/tools/` Tool Package의 `handler.py`에서 helper 모듈 import 시
- 패키지(`src/portal/`)의 라이브러리 모듈 로드 시
