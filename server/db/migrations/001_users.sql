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
