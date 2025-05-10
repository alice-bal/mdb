-- Дроп таблиц
DROP TABLE IF EXISTS requirements_status CASCADE;
DROP TABLE IF EXISTS criteria CASCADE;
DROP TABLE IF EXISTS dimensions CASCADE;
DROP TABLE IF EXISTS user_configurations CASCADE;
DROP TABLE IF EXISTS models CASCADE;

-- Дроп функций
DROP FUNCTION IF EXISTS get_models();
DROP FUNCTION IF EXISTS generate_dimensions_tree(INT);
DROP FUNCTION IF EXISTS add_user_configuration(INT, INT);
DROP FUNCTION IF EXISTS link_criteria_to_config(INT, INT);
DROP FUNCTION IF EXISTS save_criteria_score(INT, INT, INT, TEXT, BOOLEAN);
DROP FUNCTION IF EXISTS analyze_results(INT);
DROP FUNCTION IF EXISTS get_recommendations(INT);

--=================================================================================
--=================================================================================

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

-- Удаляем внешний ключ, если он уже был
ALTER TABLE dimensions
DROP CONSTRAINT IF EXISTS fk_dimensions_prev_level;

ALTER TABLE dimensions
ADD CONSTRAINT fk_dimensions_prev_level
FOREIGN KEY (prev_level)
REFERENCES dimensions(dimension_id)
ON DELETE SET NULL;

-- Добавляем поле tag 
ALTER TABLE criteria
ADD COLUMN tags TEXT;

-- Добавляем поле is_used
ALTER TABLE requirements_status
ADD COLUMN is_used BOOLEAN DEFAULT TRUE;


--=================================================================================
--=================================================================================

-- =====================================================
-- 02_insert_test_data.sql
-- Заполняет базу тестовыми данными для обновленной схемы
-- (без sub_dimensions, с рекурсивным dimensions)
-- =====================================================

-- 1. Добавляем модели в таблицу models
INSERT INTO models (model_name, description) VALUES
('Digital Maturity Model', 'Оценка цифровой зрелости компании'),
('COBIT', 'Модель управления корпоративными ИТ');

-- 2. Добавляем несколько измерений в таблицу dimensions
--    Пример: для модели с ID = 1 (Digital Maturity Model)
--    prev_level = NULL -> корневой уровень
INSERT INTO dimensions (model_id, dimension_name, description, prev_level) VALUES
(1, 'Strategy', 'Оценка стратегии', NULL),            -- dimension_id=1
(1, 'Technology', 'Оценка технологий', NULL),         -- dimension_id=2
(1, 'Innovation', 'Стратегия инноваций', 1),          -- dimension_id=3 (дочерняя для Strategy)
(1, 'Cloud Adoption', 'Использование облачных технологий', 2), -- dimension_id=4 (дочерняя для Technology)

--    Пример: для модели с ID = 2 (COBIT)
(2, 'Governance', 'Управление корпоративными ИТ', NULL); -- dimension_id=5

-- 3. Добавляем критерии (требования) в таблицу criteria
--    При вставке в 'recommendations' используем валидный JSON, к примеру '{}'
--    Далее мы обновим это поле корректными JSON-данными.
INSERT INTO criteria (dimension_id, criteria_text, level, recommendations) VALUES
(1, 'Эффективность управления портфелем', 4, '{}'),
(3, 'Наличие четкой стратегии инноваций', 5, '{}'),
(4, 'Процент использования облачных технологий', 4, '{}'),
(5, 'IT Risk Management', 4, '{}');

-- 4. Обновляем поле recommendations JSON для уточнения рекомендаций по уровням
--    Теперь, когда в поле хранится '{}', можно безопасно выполнять UPDATE
UPDATE criteria
SET recommendations = '{
    "1": "Создайте базовый план управления портфелем.",
    "2": "Обучите сотрудников основам управления проектами.",
    "3": "Проводите регулярные аудиты эффективности.",
    "4": "Используйте ПО для управления портфелем.",
    "5": "Применяйте лучшие практики и делитесь опытом."
}'
WHERE dimension_id = 1;  -- Для 'Эффективность управления портфелем'

UPDATE criteria
SET recommendations = '{
    "1": "Сформулируйте инновационную стратегию и цели.",
    "2": "Организуйте мозговой штурм для сбора идей.",
    "3": "Внедрите процессы отбора инноваций.",
    "4": "Пересматривайте стратегию на основе новых данных.",
    "5": "Расширяйте масштабы инновационных проектов."
}'
WHERE dimension_id = 3;  -- Для 'Наличие четкой стратегии инноваций'

UPDATE criteria
SET recommendations = '{
    "1": "Оцените текущую ИТ-инфраструктуру.",
    "2": "Начните с миграции незначительных данных.",
    "3": "Обучите сотрудников облачным технологиям.",
    "4": "Оптимизируйте использование облака.",
    "5": "Полностью интегрируйте облачные решения в бизнес-процессы."
}'
WHERE dimension_id = 4;  -- Для 'Процент использования облачных технологий'

UPDATE criteria
SET recommendations = '{
    "1": "Идентифицируйте ключевые IT-риски и создайте базовый регистр.",
    "2": "Определите контрольные точки по стандартам COBIT.",
    "3": "Периодически пересматривайте риски и обновляйте планы.",
    "4": "Внедрите автоматизированные системы мониторинга.",
    "5": "Достигните зрелой практики управления рисками."
}'
WHERE dimension_id = 5;  -- Для 'IT Risk Management'

--=================================================================================
--=================================================================================

-- 3.1 Функция для получения списка моделей
CREATE OR REPLACE FUNCTION get_models()
RETURNS TABLE(model_id INT, model_name VARCHAR, description TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT m.model_id, m.model_name, m.description
    FROM models m;
END;
$$ LANGUAGE plpgsql;

-- 3.2 Функция для рекурсивного обхода измерений (через prev_level)
CREATE OR REPLACE FUNCTION generate_dimensions_tree(p_model_id INT)
RETURNS TABLE(dimension_id INT, dimension_name VARCHAR, prev_level INT) AS $$
BEGIN
    RETURN QUERY
        WITH RECURSIVE dim_tree AS (
            SELECT d.dimension_id, d.dimension_name, d.prev_level
            FROM dimensions d
            WHERE d.model_id = p_model_id
              AND d.prev_level IS NULL

            UNION ALL

            SELECT child.dimension_id, child.dimension_name, child.prev_level
            FROM dimensions child
            JOIN dim_tree parent ON child.prev_level = parent.dimension_id
        )
        SELECT * FROM dim_tree;
END;
$$ LANGUAGE plpgsql;

-- 3.3 Создание конфигурации пользователя (выбор модели зрелости)
CREATE OR REPLACE FUNCTION add_user_configuration(p_user_id INT, p_model_id INT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO user_configurations (user_id, model_id)
    VALUES (p_user_id, p_model_id);
END;
$$ LANGUAGE plpgsql;

-- 3.4 Связка конфигурации (config_id) и критерия (criteria_id)
CREATE OR REPLACE FUNCTION link_criteria_to_config(p_config_id INT, p_criteria_id INT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO requirements_status (config_id, criteria_id)
    VALUES (p_config_id, p_criteria_id);
END;
$$ LANGUAGE plpgsql;

-- 3.5 Сохранение оценки критерия и факта выполнения
CREATE OR REPLACE FUNCTION save_criteria_score(
    p_config_id INT,
    p_criteria_id INT,
    p_score INT,
    p_comments TEXT,
    p_completed BOOLEAN
)
RETURNS VOID AS $$
BEGIN
    UPDATE requirements_status
       SET score = p_score,
           comments = p_comments,
           is_completed = p_completed
     WHERE config_id = p_config_id
       AND criteria_id = p_criteria_id;
END;
$$ LANGUAGE plpgsql;

-- 3.6 Анализ результатов: средний балл по каждому измерению
CREATE OR REPLACE FUNCTION analyze_results(p_config_id INT)
RETURNS TABLE(dimension_name VARCHAR, average_score NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT d.dimension_name,
           AVG(rs.score) AS average_score
    FROM requirements_status rs
    JOIN criteria c ON rs.criteria_id = c.criteria_id
    JOIN dimensions d ON c.dimension_id = d.dimension_id
    WHERE rs.config_id = p_config_id
    GROUP BY d.dimension_name;
END;
$$ LANGUAGE plpgsql;

-- 3.7 Получение рекомендаций (для невыполненных или низких оценок)
CREATE OR REPLACE FUNCTION get_recommendations(p_config_id INT)
RETURNS TABLE(dimension_name VARCHAR, criteria_text TEXT, recommendation TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
       d.dimension_name,
       c.criteria_text,
       CASE
         WHEN c.recommendations::jsonb ? rs.score::TEXT 
              THEN c.recommendations::jsonb ->> rs.score::TEXT
         ELSE 'Рекомендация отсутствует'
       END AS recommendation
    FROM requirements_status rs
    JOIN criteria c ON rs.criteria_id = c.criteria_id
    JOIN dimensions d ON c.dimension_id = d.dimension_id
    WHERE rs.config_id = p_config_id
      AND (rs.score < 3 OR rs.is_completed = FALSE);
END;
$$ LANGUAGE plpgsql;


--=================================================================================
--=================================================================================

-- 04_test_scenarios.sql
-- Тестовые сценарии для новой структуры без sub_dimensions
-- ==============================================

-- Тест 1: Список моделей зрелости
SELECT * FROM get_models();

-- Тест 2: Иерархия измерений (ветвями)
-- Показываем структуру для модели с ID = 1 (Digital Maturity Model)
SELECT * FROM generate_dimensions_tree(1);

-- Тест 3: Создание пользовательской конфигурации
SELECT add_user_configuration(1, 1);  -- user_id=1, model_id=1
SELECT * FROM user_configurations;

-- Тест 4: Привязка критериев к конфигурации
-- Допустим, у нас есть criteria_id=1,2,3,4 -- связываем с config_id=1
SELECT link_criteria_to_config(1, 1);
SELECT link_criteria_to_config(1, 2);
SELECT link_criteria_to_config(1, 3);

-- Тест 5: Сохранение оценок и статуса выполнения
-- Проверяем, что можно выставить оценку (score) и факт выполнения (is_completed)
SELECT save_criteria_score(1, 1, 4, 'Хороший прогресс', FALSE);
SELECT save_criteria_score(1, 2, 3, 'Есть инновационные идеи, но нужно расширяться', FALSE);
SELECT save_criteria_score(1, 3, 2, 'Низкий процент использования облака', FALSE);

-- Смотрим, что записалось
SELECT * FROM requirements_status;

-- Тест 6: Анализ результатов
SELECT * FROM analyze_results(1);

-- Тест 7: Получение рекомендаций
-- Предполагаем, что все критерии с score<3 или is_completed=FALSE вернут рекомендации
SELECT * FROM get_recommendations(1);

-- Дополнительные тесты
-- Проверка пустых результатов (несуществующий config_id)
SELECT * FROM get_recommendations(99);
SELECT * FROM analyze_results(99);


