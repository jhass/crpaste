DROP TABLE IF EXISTS pastes;
CREATE TABLE pastes (
  id serial PRIMARY KEY,
  content bytea NOT NULL,
  client_ip varchar(40),
  token varchar(32),
  owner_token varchar(32) NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);
