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
