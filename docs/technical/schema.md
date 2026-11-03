# 서버 응답 키

계정과 목표의 테이블 정의는 서버 저장소 [`../../../server/docs/schema.md`](../../../server/docs/schema.md)에 둔다. 실행 SQL도 그 저장소의 `db/migrations`에 있다. 이 문서는 앱이 받는 응답 키만 적는다.

데이터베이스 컬럼은 밑줄 이름이다. 응답은 아래 키로 온다. 목표 응답에는 주인 계정을 넣지 않는다.

## 계정

| API 키 | 내용 |
| --- | --- |
| `id` | 계정 번호 |
| `kakaoId` | 카카오 회원 번호 |
| `email` | 카카오가 제공한 이메일. 없을 수 있다 |
| `createdAt` | 계정이 만들어진 시각 |

## 목표

`StoredGoal` 필드 이름과 같다.

| API 키 | 내용 |
| --- | --- |
| `id` | 목표 번호 |
| `text` | 목표 문장 |
| `verification` | 고른 인증 방법 제목 |
| `responseJson` | 고른 인증 방법 JSON |
| `createdAt` | 등록 시각 |
| `startAt` | 시작 시각 |
| `endAt` | 종료 시각 |
| `verdict` | 판정. 빈 값, `pass`, `fail`, `unclear` |
| `verdictReason` | 판정 이유 |
| `verifiedAt` | 판정 시각. 인증 전에는 비어 있다 |
