# 서버 데이터베이스 스키마

PostgreSQL에 만들 구조다. 테이블은 계정 `users`와 목표 `goals` 두 개다. 로그인 토큰은 표로 저장하지 않는다.

실행할 SQL은 [`server/db/migrations`](../../server/db/migrations)에 둔다. 번호 순서대로 `001_users.sql`을 먼저 실행하고 `002_goals.sql`을 다음에 실행한다. 이 문서는 그 구조를 설명하는 문서다. `--` 뒤 문장은 각 항목이 무엇을 담는지에 대한 설명이다. 데이터베이스 컬럼은 밑줄 이름을 쓴다. 앱에 내려줄 때는 `StoredGoal` 필드 이름으로 바꾼다.

## users

로그인한 사람 한 명당 한 행이다.

로그인은 카카오 로그인이다. 카카오가 준 회원 번호로 기존 계정을 찾고, 없으면 이 표에 새 행을 만든다.

```sql
create table users (
  -- 계정을 구분하는 번호. 데이터베이스가 1부터 차례로 매긴다.
  id bigint generated always as identity primary key,

  -- 카카오가 회원에게 부여한 번호. 같은 카카오 회원은 한 행만 가진다.
  kakao_id bigint not null unique,

  -- 카카오가 이메일을 알려 준 경우에만 저장한다. 로그인에 쓰지 않는다. 있으면 소문자로 저장하고, 같은 주소는 한 번만 둔다.
  email text unique,

  -- 이 계정이 만들어진 시각.
  created_at timestamptz not null default now()
);
```

| 컬럼 | API 키 | 설명 |
| --- | --- | --- |
| `id` | `id` | 계정 번호 |
| `kakao_id` | `kakaoId` | 카카오 회원 번호. 계정을 찾는 기준 |
| `email` | `email` | 카카오가 제공한 이메일. 없을 수 있다 |
| `created_at` | `createdAt` | 첫 로그인으로 계정이 만들어진 시각 |

## goals

등록된 목표 한 건당 한 행이다. 홈 목록은 이 표를 최근 등록순으로 읽는다.

```sql
create table goals (
  -- 목표를 구분하는 번호. 데이터베이스가 1부터 차례로 매긴다.
  id bigint generated always as identity primary key,

  -- 이 목표의 주인. 서버가 로그인 토큰으로 채운다. 앱에 내려보내는 목표 데이터에는 넣지 않는다.
  user_id bigint not null references users (id),

  -- 사용자가 입력한 목표 문장.
  text text not null,

  -- 사용자가 고른 인증 방법의 제목.
  verification text not null,

  -- 사용자가 고른 인증 방법만 담은 JSON. Gemini 응답 전체는 저장하지 않는다.
  response_json text not null,

  -- 등록 버튼을 눌러 이 행이 만들어진 시각.
  created_at timestamptz not null default now(),

  -- 목표를 시작하는 시각. 비울 수 없다.
  start_at timestamptz not null,

  -- 목표가 끝나는 시각. 시작 시각과 같거나 그 뒤여야 한다.
  end_at timestamptz not null,

  -- 인증 판정. 아직 인증하지 않았으면 빈 문자열이다. 그 외에는 pass, fail, unclear 만 허용한다.
  verdict text not null default '',

  -- 판정 이유를 적은 문장. 인증 전에는 빈 문자열이다.
  verdict_reason text not null default '',

  -- 판정이 저장된 시각. 인증 전에는 비어 있다.
  verified_at timestamptz,

  -- 종료 시각이 시작 시각보다 이르면 저장을 거부한다.
  check (end_at >= start_at),

  -- 판정 값이 약속된 네 가지 밖이면 저장을 거부한다.
  check (verdict in ('', 'pass', 'fail', 'unclear'))
);

-- 한 계정의 목표를 최근 등록순으로 찾을 때 쓰는 색인.
create index goals_user_created_idx on goals (user_id, created_at desc);
```

| 컬럼 | API 키 | 설명 |
| --- | --- | --- |
| `id` | `id` | 목표 번호 |
| `user_id` | 없음 | 주인 계정. 응답에 포함하지 않는다 |
| `text` | `text` | 목표 문장 |
| `verification` | `verification` | 고른 인증 방법 제목 |
| `response_json` | `responseJson` | 고른 인증 방법 JSON |
| `created_at` | `createdAt` | 등록 시각 |
| `start_at` | `startAt` | 시작 시각 |
| `end_at` | `endAt` | 종료 시각 |
| `verdict` | `verdict` | 판정. 빈 값, `pass`, `fail`, `unclear` |
| `verdict_reason` | `verdictReason` | 판정 이유 |
| `verified_at` | `verifiedAt` | 판정 시각. 인증 전에는 비어 있다 |

시작 시각이나 종료 시각이 없는 휴대폰 속 예전 목표는 이 표에 올리지 않는다.
