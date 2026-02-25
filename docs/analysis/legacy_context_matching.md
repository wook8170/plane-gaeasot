# 과거 프로젝트 분석 맥락 반영 보고서 (GAEA 프로젝트 연계)

이 문서는 이전 프로젝트(`GAEA-PROJECT_3`, `GAEA-PROJECT_2_old`)에서 분석하고 수정했던 핵심 기능들이 현재 소스 코드(`PLANE.SO.GAEASOT`)의 어느 위치에 매핑되며, 향후 어떻게 확장해야 하는지 기술합니다.

## 1. 유료 에디션 기능 활성화 (Edition & License)

이전 프로젝트의 핵심 목표 중 하나는 커뮤니티 에디션의 제약을 해제하여 비즈니스/엔터프라이즈 기능을 사용하는 것이었습니다.

- **핵심 분석 지점**: `apps/api/plane/license/models/instance.py`
- **분석 내용**:
  - `Instance` 모델 내의 `edition` 필드가 시스템의 기능 가용 범위를 결정합니다.
  - 이전 프로젝트에서는 이를 `pro` 또는 `enterprise`로 강제 설정하거나, 관련 체크 데코레이터를 수정하여 모든 메뉴를 활성화했습니다.
- **연쇄 영향**: 에디션이 변경되면 프론트엔드의 `apps/web/core/store/workspace/workspace.store.ts` 등에서 관리되는 유효성 검사 로직이 함께 해제되어야 합니다.

---

## 2. 간트 차트 및 의존성 고도화 (Gantt Chart & Dependencies)

간트 차트에서 작업 간의 연결 화살표를 렌더링하고, 일정을 연쇄적으로 조정(Cascading Update)하는 기능입니다.

- **백엔드 로직**: `apps/api/plane/db/models/issue.py`의 `IssueRelation` 모델.
  - `relation_type`에 따른 논리적 연결(차단함, 관련됨 등)을 정의합니다.
- **프론트엔드 연동**: `apps/web/core/store/issue/issue_gantt_view.store.ts`
  - 이전 분석 결과에 따르면, 간트 화면에서 드래그 시 연쇄적으로 날짜가 변하는 로직은 스토어 내의 `updateIssueDates`와 연동되어 작동합니다.
  - 화살표 렌더링 최적화를 위해 SVG 경로 계산 로직이 `packages/ui` 또는 간트 전용 컴포넌트 내에 포함되어 있습니다.

---

## 3. 문서 시스템 및 파일 첨부 (Pages & Attachments)

`GAEA-PROJECT_2_old`에서 집중적으로 다루었던 문서 히스토리와 한국 특화 파일(HWPX 등) 처리 로직입니다.

- **첨부파일 명칭 이슈**:
  - **원인**: 파일 업로드 시 파일명의 인코딩 방식 차이로 인해 UI에서 이름이 깨지거나 표시되지 않는 현상.
  - **해결 핵심**: `apps/api/plane/app/views/issue/attachment.py`에서 저장 시 파일명을 처리하는 로직과, 프론트엔드의 `IssueAttachmentSerializer`에서 `asset_url`을 생성하는 방식을 일치시켜야 합니다.
- **문서 히스토리**: `apps/api/plane/app/models/page.py` 내의 버전 관리 로직을 통해 실시간 편집 내용을 복구할 수 있는 구조입니다.

---

## 4. 향후 확장 로직 제언

1.  **기능 이식**: 이전 프로젝트에서 검증된 `license` 우회 코드를 현재 소스의 `apps/api/plane/license` 경로에 적용하여 즉시 모든 기능을 테스트할 수 있습니다.
2.  **UI parity (동질화)**: 클라우드 버전의 최신 UI 요소를 `packages/propel`에 반영하여 시각적 완성도를 높일 수 있습니다.
3.  **실시간성 강화**: `apps/live` 서버의 설정을 최적화하여 여러 프로젝트 간의 데이터 동기화 지연을 최소화해야 합니다.
