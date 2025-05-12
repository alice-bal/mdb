CREATE TABLE IF NOT EXISTS models (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT
);

INSERT INTO models (name, description)
VALUES
  ('Deloitte DMM', 'Модель цифровой зрелости от Deloitte'),
  ('TM Forum', 'TM Forum Digital Maturity Model');