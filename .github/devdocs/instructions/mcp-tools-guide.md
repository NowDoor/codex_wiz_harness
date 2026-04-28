# WIZ MCP 도구 사용 가이드

> ⚠️ **MCP 도구 최우선 사용 원칙**: 앱 생성·파일 읽기/쓰기·빌드·프로젝트 관리 등 **WIZ MCP 도구로 수행 가능한 작업은 반드시 MCP 도구를 먼저 사용**한다. 파일시스템 직접 접근(`create_file`, `replace_string_in_file` 등)은 MCP로 처리할 수 없는 경우에만 사용한다.

> **도구 네이밍 규칙**: `wiz_{category}_{action}` 형태. 카테고리는 `workspace`, `project`, `source`, `package` 4가지.

> **projectName 자동 감지**: VS Code Explorer와 자동 동기화되므로 `projectName` 파라미터는 보통 생략한다. 모든 경로 파라미터는 상대경로를 지원하며 해당 루트 기준으로 자동 변환된다.

---

## 1. Workspace (7)

워크스페이스 전체 레벨의 조회·파일 작업.

| 도구 | 설명 |
|------|------|
| `wiz_workspace_status` | 워크스페이스 상태, 활성 프로젝트, 프로젝트 목록 반환 |
| `wiz_workspace_list_dir` | 디렉토리 내용 조회 (워크스페이스 루트 기준 상대경로) |
| `wiz_workspace_read_file` | 파일 읽기 (워크스페이스 루트 기준, 줄 범위 지원) |
| `wiz_workspace_write_file` | 파일 쓰기 (워크스페이스 루트 기준) |
| `wiz_workspace_create_dir` | 디렉토리 생성 |
| `wiz_workspace_delete` | 파일/디렉토리 삭제 |
| `wiz_workspace_rename` | 파일/디렉토리 이름 변경·이동 |

## 2. Project (19)

프로젝트 레벨의 관리·빌드·패키지 매니저·파일 작업.

| 도구 | 설명 |
|------|------|
| `wiz_project_info` | 프로젝트 종합 정보 (앱 타입별 개수, 패키지 목록, 경로) |
| `wiz_project_switch` | 활성 프로젝트 전환 (Explorer 동기화) |
| `wiz_project_build` | 프로젝트 빌드 (Normal/Clean) |
| `wiz_project_export` | `.wizproject` 아카이브로 내보내기 |
| `wiz_project_import` | `.wizproject` 파일에서 프로젝트 가져오기 |
| `wiz_project_structure` | `src/` 디렉토리 트리 구조 조회 |
| `wiz_project_list_dir` | 디렉토리 조회 (프로젝트 루트 기준 상대경로) |
| `wiz_project_read_file` | 파일 읽기 (프로젝트 루트 기준, 줄 범위 지원) |
| `wiz_project_write_file` | 파일 쓰기 (프로젝트 루트 기준) |
| `wiz_project_create_dir` | 프로젝트 내 디렉토리 생성 |
| `wiz_project_delete` | 프로젝트 내 파일/디렉토리 삭제 |
| `wiz_project_rename` | 프로젝트 내 이름 변경·이동 |
| `wiz_project_search_apps` | 앱 키워드 검색 (source + packages 통합) |
| `wiz_project_pip_list` | pip 패키지 목록 조회 |
| `wiz_project_pip_install` | pip 패키지 설치 |
| `wiz_project_pip_uninstall` | pip 패키지 제거 |
| `wiz_project_npm_list` | npm 패키지 목록 조회 |
| `wiz_project_npm_install` | npm 패키지 설치 |
| `wiz_project_npm_uninstall` | npm 패키지 제거 |

## 3. Source (13)

`src/` 하위의 앱(Page/Component/Layout/Route)·컨트롤러 관리.

| 도구 | 설명 |
|------|------|
| `wiz_source_list_apps` | Source 앱/라우트 목록 (타입별 필터 가능) |
| `wiz_source_app_info` | 앱 상세 정보 및 파일 목록 |
| `wiz_source_create_app` | 앱 생성 (page, component, layout) |
| `wiz_source_create_route` | 라우트(API 엔드포인트) 생성 |
| `wiz_source_update_app` | app.json 설정 수정 |
| `wiz_source_delete_app` | 앱/라우트 폴더 삭제 |
| `wiz_source_list_files` | 앱 폴더 내 파일 목록 |
| `wiz_source_read_file` | 앱 폴더 내 파일 읽기 |
| `wiz_source_write_file` | 앱 폴더 내 파일 쓰기 |
| `wiz_source_delete_file` | 앱 폴더 내 파일 삭제 |
| `wiz_source_rename_file` | 앱 폴더 내 파일 이름 변경 |
| `wiz_source_list_controllers` | Python 컨트롤러 목록 |
| `wiz_source_list_layouts` | 레이아웃 앱 목록 |

## 4. Package (15)

`src/portal/` 하위 패키지 및 패키지 내 앱·파일 관리.

| 도구 | 설명 |
|------|------|
| `wiz_package_list` | 포탈 패키지 목록 |
| `wiz_package_create` | 새 패키지 생성 |
| `wiz_package_export` | `.wizpkg` 아카이브로 패키지 내보내기 |
| `wiz_package_list_apps` | 패키지 내 앱/라우트 목록 |
| `wiz_package_app_info` | 패키지 앱 상세 정보 및 파일 목록 |
| `wiz_package_create_app` | 패키지 내 앱 생성 |
| `wiz_package_create_route` | 패키지 내 라우트 생성 |
| `wiz_package_update_app` | 패키지 앱 app.json 수정 |
| `wiz_package_delete_app` | 패키지 앱/라우트 삭제 |
| `wiz_package_list_files` | 패키지 앱 폴더 내 파일 목록 |
| `wiz_package_read_file` | 패키지 앱 폴더 내 파일 읽기 |
| `wiz_package_write_file` | 패키지 앱 폴더 내 파일 쓰기 |
| `wiz_package_delete_file` | 패키지 앱 폴더 내 파일 삭제 |
| `wiz_package_list_controllers` | 패키지 내 컨트롤러 목록 |

> **Note**: `wiz_package_rename_file` 도구도 존재하나 위 목록은 주요 도구 기준이다.

## 5. MCP 사용 원칙

- **상대경로 자동 변환**: 각 카테고리의 도구는 해당 루트(workspace/project/app 폴더) 기준으로 상대경로를 자동 변환한다.
- **projectName 자동 감지**: VS Code Explorer와 자동 동기화되므로 보통 생략한다.
- **앱 생성 후 파일 작성 순서**: `wiz_source_create_app` → `wiz_source_write_file`(view.ts) → `wiz_source_write_file`(view.pug) → `wiz_source_write_file`(api.py 등)
- **패키지 앱 생성**: `wiz_package_create_app` → `wiz_package_write_file`로 파일 작성
- **빌드**: `wiz_project_build`로 빌드. 기본 Normal, 사용자 명시 시에만 Clean.

### 5.1 Source vs Package 도구 선택 규칙

> ⚠️ **필수**: 파일 경로가 `src/portal/` 하위에 있으면 **반드시 `wiz_package_*` 도구**를 사용한다. `wiz_source_*` 도구는 `src/app/`, `src/route/` 등 Source 영역 전용이다.

| 대상 경로 | 사용할 도구 카테고리 | 예시 |
|-----------|---------------------|------|
| `src/app/{appName}/` | **Source** (`wiz_source_*`) | `wiz_source_read_file`, `wiz_source_write_file` |
| `src/route/{routeName}/` | **Source** (`wiz_source_*`) | `wiz_source_read_file`, `wiz_source_create_route` |
| `src/portal/{package}/app/{appName}/` | **Package** (`wiz_package_*`) | `wiz_package_read_file`, `wiz_package_write_file` |
| `src/portal/{package}/route/{routeName}/` | **Package** (`wiz_package_*`) | `wiz_package_read_file`, `wiz_package_create_route` |
| `src/portal/{package}/libs/` | **Package** (`wiz_package_*`) | `wiz_package_read_file`, `wiz_package_list_files` |
| `src/portal/{package}/styles/` | **Package** (`wiz_package_*`) | `wiz_package_read_file` |
| `src/portal/{package}/model/` | **Package** (`wiz_package_*`) | `wiz_package_read_file` |
| `src/portal/{package}/controller/` | **Package** (`wiz_package_*`) | `wiz_package_list_controllers` |
| `src/model/`, `src/controller/` | **Source** (`wiz_source_*`) | `wiz_source_list_controllers` |
| `src/angular/`, `src/assets/` | **Project** (`wiz_project_*`) | `wiz_project_read_file` |
| `config/`, 프로젝트 루트 파일 | **Project** (`wiz_project_*`) | `wiz_project_read_file` |

**판단 기준 요약**: `appPath` 파라미터가 `portal/` 접두사로 시작하면 → Package 도구, 그 외 → Source 도구.

## 6. 이전 도구명 → 현재 도구명 매핑

기존 문서에서 사용하던 도구명과의 대응 관계:

| 이전 이름 | 현재 이름 |
|-----------|-----------|
| `wiz_get_workspace_state` | `wiz_workspace_status` |
| `wiz_get_project_info` | `wiz_project_info` |
| `wiz_get_project_structure` | `wiz_project_structure` |
| `wiz_list_projects` | `wiz_workspace_status` (프로젝트 목록 포함) |
| `wiz_switch_project` | `wiz_project_switch` |
| `wiz_list_apps` | `wiz_source_list_apps` |
| `wiz_get_app_info` | `wiz_source_app_info` |
| `wiz_search_apps` | `wiz_project_search_apps` |
| `wiz_create_app` | `wiz_source_create_app` |
| `wiz_create_route` | `wiz_source_create_route` |
| `wiz_create_portal_app` | `wiz_package_create_app` |
| `wiz_create_portal_route` | `wiz_package_create_route` |
| `wiz_update_app` | `wiz_source_update_app` |
| `wiz_delete_app` | `wiz_source_delete_app` |
| `wiz_list_layouts` | `wiz_source_list_layouts` |
| `wiz_list_controllers` | `wiz_source_list_controllers` |
| `wiz_read_app_file` | `wiz_source_read_file` |
| `wiz_write_app_file` | `wiz_source_write_file` |
| `wiz_read_file` | `wiz_project_read_file` |
| `wiz_write_file` | `wiz_project_write_file` |
| `wiz_list_directory` | `wiz_project_list_dir` |
| `wiz_create_folder` | `wiz_project_create_dir` |
| `wiz_delete_file` | `wiz_project_delete` |
| `wiz_rename_file` | `wiz_project_rename` |
| `wiz_list_packages` | `wiz_package_list` |
| `wiz_create_package` | `wiz_package_create` |
| `wiz_export_package` | `wiz_package_export` |
| `wiz_export_project` | `wiz_project_export` |
| `wiz_import_project` | `wiz_project_import` |
| `wiz_build` | `wiz_project_build` |
