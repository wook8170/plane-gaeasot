# 코드 단위 상세 분석 보고서 (Code-Level Detailed Analysis)

이 문서는 Plane.so의 핵심 소스 코드를 함수, 메서드, 클래스 단위로 꼼꼼하게 분석하여 기능을 기술한 문서입니다. 향후 기능 추가 및 수정 시 개발자가 참고할 수 있는 상세 가이드 역할을 합니다.

---

## 1. 백엔드 데이터 모델 계층 (Backend Model Layer)

`apps/api/plane/db/models` 폴더 내의 핵심 모델 분석입니다.

### 1.1 Issue 모델 (`models/issue.py`)

- **역할**: 작업(Task)의 핵심 엔터티로, 제목, 설명, 상태, 우선순위 등을 저장합니다.
- **핵심 메서드**:
  - `save(self, *args, **kwargs)`: 이슈 저장 시 중복 체크, 시퀀스 ID(예: PROJ-1) 자동 생성 로직을 포함합니다.
  - `__str__(self)`: 이슈의 제목 또는 고유 식별자를 반환합니다.
  - `IssueManager.get_queryset()`: 기본 쿼리에 워크스페이스 및 프로젝트 필터링을 자동으로 추가하여 보안을 강화합니다.
- **계층 구조**: `ProjectBaseModel`을 상속받아 프로젝트 및 워크스페이스 정보를 기본적으로 포함합니다.

### 1.2 IssueRelation 모델

- **역할**: 이슈 간의 관계(중복, 관련됨, 차단됨 등)를 정의합니다.
- **핵심 로직**: `IssueRelationChoices`를 통해 양방향 관계(Bidirectional pairs)를 관리합니다. (예: A가 B를 차단하면, B는 A에 의해 차단됨이 자동으로 인식됨)

---

## 2. 백엔드 컨트롤러 계층 (Backend View Layer)

`apps/api/plane/app/views` 폴더 내의 API 엔드포인트 로직 분석입니다.

### 2.1 IssueViewSet (`views/issue/base.py`)

- **역할**: 이슈에 대한 CRUD(생성, 조회, 수정, 삭제) REST API를 총괄합니다.
- **주요 메서드 별 기능**:
  - `list()`: 필터링 조건에 맞는 이슈 목록을 반환합니다. 대량 데이터 처리를 위해 최적화된 쿼리를 사용합니다.
  - `create()`: 이슈 생성 시 `IssueCreateSerializer`를 통해 데이터를 검증하고, 백그라운드 태스크(Activity 기록)를 생성합니다.
  - `apply_annotations(self, issues)`: 이슈 목록 정보 외에 추가적인 계산 데이터(하위 이슈 개수, 첨부파일 개수 등)를 쿼리셋에 효율적으로 병합(Annotate)합니다. 이는 여러 번의 DB 호출을 방지합니다.
  - `partial_update()`: 이슈의 특정 필드(상태 변경 등)만 수정할 때 사용되며, 변경 이력(Activity)을 자동으로 생성합니다.

---

## 3. 프론트엔드 서비스 계층 (Frontend Service Layer)

`apps/web/core/services` 폴더 내의 API 통신 메서드 분석입니다.

### 3.1 IssueService (`services/issue/issue.service.ts`)

- **역할**: 백엔드 API와 직접 통신하며 데이터를 주고받는 통로입니다.
- **주요 메서드**:
  - `getIssues(workspaceSlug, projectId, queries)`: 비즈니스 로직 필터가 적용된 이슈 목록을 서버에 요청합니다.
  - `patchIssue(workspaceSlug, projectId, issueId, data)`: 이슈의 특정 정보를 수정 요청하며, 성공 시 업데이트된 데이터를 반환합니다.
  - `bulkOperations()`: 여러 이슈의 상태나 담당자를 한꺼번에 변경하는 일괄 처리 기능을 담당합니다.

---

## 4. 프론트엔드 상태 관리 계층 (Frontend Store Layer)

`apps/web/core/store` 폴더 내의 MobX 기반 상테 관리 로직 분석입니다.

### 4.1 IssueStore (`store/issue/issue.store.ts`)

- **역할**: 서버에서 받아온 이슈 데이터를 클라이언트 메모리에 보관하고, UI 컴포넌트에 실시간으로 전달합니다.
- **핵심 속성 및 메서드**:
  - `issuesMap`: 이슈 ID를 키로 하여 이슈 객체를 저장하는 맵 구조입니다. O(1) 성능으로 데이터에 접근 가능합니다.
  - `addIssue(issues)`: 새로운 이슈들을 스토어에 추가하거나 기존 데이터를 업데이트(`update`)합니다.
  - `updateIssue(issueId, issue)`: 특정 이슈의 상태를 변경하면 화면 전체를 다시 그리지 않고 해당 부분만 반응형으로 업데이트합니다.
  - `removeIssue(issueId)`: 삭제된 이슈를 스토어에서 즉시 제거하여 UI에 반영합니다.

---

## 5. 계층 간 연동 구조 요약 (Cascading Chain)

신규 기능을 개발할 때의 코드 호출 연쇄 과정은 다음과 같습니다:

1.  **UI Component**: 사용자의 입력을 감지.
2.  **Store Action**: UI에서 전달된 데이터를 기반으로 비즈니스 로직(예: 중복 체크) 실행 후 Service 호출.
3.  **Service Method**: HTTP 요청을 생성하여 Backend로 전송.
4.  **Backend View**: 요청 수신 및 권한 체크, Serializer 호출.
5.  **Serializer**: 데이터 포맷 변환 및 비즈니스 규칙 검증.
6.  **Model Method**: 실제 데이터베이스 접근 및 저장 로직 수행.
7.  **Callback**: 저장 성공 시 역순으로 데이터가 전달되어 Store의 `issuesMap`이 업데이트되고 UI가 최종 렌더링됨.
