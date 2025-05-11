-- Таблица моделей зрелости
CREATE TABLE models (
    model_id SERIAL PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблица измерений
CREATE TABLE dimensions (
    dimension_id SERIAL PRIMARY KEY,
    model_id INT REFERENCES models(model_id) ON DELETE CASCADE,
    dimension_name VARCHAR(255) NOT NULL,
    description TEXT
);

-- Таблица подизмерений
CREATE TABLE sub_dimensions (
    sub_dimension_id SERIAL PRIMARY KEY,
    dimension_id INT REFERENCES dimensions(dimension_id) ON DELETE CASCADE,
    sub_dimension_name VARCHAR(255) NOT NULL,
    description TEXT
);

-- Таблица критериев
CREATE TABLE criteria (
    criteria_id SERIAL PRIMARY KEY,
    sub_dimension_id INT REFERENCES sub_dimensions(sub_dimension_id) ON DELETE CASCADE,
    criteria_text TEXT NOT NULL,
    level INT CHECK (level >= 1 AND level <= 5),
    recommendations TEXT
);

-- Таблица пользовательских конфигураций
CREATE TABLE user_configurations (
    config_id SERIAL PRIMARY KEY,
    user_id INT,
    model_id INT REFERENCES models(model_id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблица результатов самооценки
CREATE TABLE checklist_results (
    result_id SERIAL PRIMARY KEY,
    config_id INT REFERENCES user_configurations(config_id) ON DELETE CASCADE,
    sub_dimension_id INT REFERENCES sub_dimensions(sub_dimension_id),
    score INT CHECK (score >= 1 AND score <= 5),
    comments TEXT
);
