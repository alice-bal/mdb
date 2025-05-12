-- 3.1 Функция: список моделей
CREATE OR REPLACE FUNCTION get_models()
RETURNS TABLE(model_id INT, model_name VARCHAR, description TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT m.model_id, m.model_name, m.description
    FROM models m;
END;
$$ LANGUAGE plpgsql;

-- 3.2 Рекурсивная иерархия измерений
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

-- 3.3 Создание конфигурации пользователя
CREATE OR REPLACE FUNCTION add_user_configuration(p_user_id INT, p_model_id INT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO user_configurations (user_id, model_id)
    VALUES (p_user_id, p_model_id);
END;
$$ LANGUAGE plpgsql;

-- 3.4 Связка конфигурации и критерия
CREATE OR REPLACE FUNCTION link_criteria_to_config(p_config_id INT, p_criteria_id INT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO requirements_status (config_id, criteria_id)
    VALUES (p_config_id, p_criteria_id);
END;
$$ LANGUAGE plpgsql;

-- 3.5 Сохранение оценки и статуса
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

-- 3.6 Анализ результатов
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

-- 3.7 Получение рекомендаций
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
