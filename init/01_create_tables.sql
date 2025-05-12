-- Таблица models: хранит модели зрелости
CREATE TABLE models (
    model_id     SERIAL PRIMARY KEY,
    model_name   VARCHAR(255) NOT NULL,
    description  TEXT,
    created_at   TIMESTAMP DEFAULT NOW()
);

-- Таблица dimensions: хранит иерархию измерений (через поле prev_level)
CREATE TABLE dimensions (
    dimension_id    SERIAL PRIMARY KEY,
    model_id        INT REFERENCES models(model_id) ON DELETE CASCADE,
    dimension_name  VARCHAR(255) NOT NULL,
    description     TEXT,
    prev_level      INT
);

-- Таблица criteria: критерии (требования), связанные с конкретным dimension_id
CREATE TABLE criteria (
    criteria_id     SERIAL PRIMARY KEY,
    dimension_id    INT REFERENCES dimensions(dimension_id) ON DELETE CASCADE,
    criteria_text   TEXT NOT NULL,
    level           INT CHECK (level >= 1 AND level <= 5),
    recommendations JSONB
);

-- Таблица user_configurations: конфигурации для пользователей (какая модель выбрана)
CREATE TABLE user_configurations (
    config_id  SERIAL PRIMARY KEY,
    user_id    INT,
    model_id   INT REFERENCES models(model_id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблица requirements_status: связи user_config <-> criteria + статус
CREATE TABLE requirements_status (
    rs_id        SERIAL PRIMARY KEY,
    config_id    INT REFERENCES user_configurations(config_id) ON DELETE CASCADE,
    criteria_id  INT REFERENCES criteria(criteria_id) ON DELETE CASCADE,
    is_completed BOOLEAN DEFAULT FALSE,
    score        INT CHECK (score >= 1 AND score <= 5),
    comments     TEXT
);

-- Самосвязь для dimensions
ALTER TABLE dimensions
ADD CONSTRAINT fk_dimensions_prev_level
FOREIGN KEY (prev_level)
REFERENCES dimensions(dimension_id)
ON DELETE SET NULL;

-- Добавляем поля
ALTER TABLE criteria
ADD COLUMN tags TEXT;

ALTER TABLE requirements_status
ADD COLUMN is_used BOOLEAN DEFAULT TRUE;
