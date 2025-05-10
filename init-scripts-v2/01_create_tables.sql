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
    prev_level      INT  -- ссылка на dimension_id родительского измерения
);

-- Таблица criteria: критерии (требования), связанные с конкретным dimension_id
CREATE TABLE criteria (
    criteria_id     SERIAL PRIMARY KEY,
    dimension_id    INT REFERENCES dimensions(dimension_id) ON DELETE CASCADE,
    criteria_text   TEXT NOT NULL,
    level           INT CHECK (level >= 1 AND level <= 5),
    recommendations JSONB  -- рекомендации в формате JSON, зависящие от score
);

-- Таблица user_configurations: конфигурации для пользователей (какая модель выбрана)
CREATE TABLE user_configurations (
    config_id  SERIAL PRIMARY KEY,
    user_id    INT,
    model_id   INT REFERENCES models(model_id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблица requirements_status: многие-ко-многим между user_configurations и criteria
-- + хранение статуса выполнения и оценки
CREATE TABLE requirements_status (
    rs_id       SERIAL PRIMARY KEY,
    config_id   INT REFERENCES user_configurations(config_id) ON DELETE CASCADE,
    criteria_id INT REFERENCES criteria(criteria_id) ON DELETE CASCADE,
    is_completed BOOLEAN DEFAULT FALSE,
    score INT CHECK (score >= 1 AND score <= 5),
    comments TEXT
);

-- самосвязь dimensions (prev_level → dimension_id)
ALTER TABLE dimensions
ADD CONSTRAINT fk_dimensions_prev_level
FOREIGN KEY (prev_level)
REFERENCES dimensions(dimension_id)
ON DELETE SET NULL;