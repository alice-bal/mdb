CREATE TABLE models (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT
);

INSERT INTO models (name, description) VALUES
('Deloitte DMM', 'Модель цифровой зрелости Deloitte'),
('TM Forum', 'Модель цифровой зрелости TM Forum');