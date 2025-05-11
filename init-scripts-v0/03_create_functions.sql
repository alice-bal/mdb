-- Удаление старых функций, если они существуют
DROP FUNCTION IF EXISTS get_models();
DROP FUNCTION IF EXISTS get_criteria_by_model(INT);
DROP FUNCTION IF EXISTS add_user_configuration(INT, INT);
DROP FUNCTION IF EXISTS get_dimensions_by_model(INT);
DROP FUNCTION IF EXISTS generate_checklist(INT);
DROP FUNCTION IF EXISTS save_checklist_result(INT, INT, INT, TEXT);
DROP FUNCTION IF EXISTS analyze_results(INT);
DROP FUNCTION IF EXISTS get_recommendations(INT);

-- Функция для получения списка моделей зрелости
CREATE OR REPLACE FUNCTION get_models()
RETURNS TABLE(model_id INT, model_name VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT m.model_id, m.model_name
    FROM models m;
END;
$$ LANGUAGE plpgsql;

-- Функция для получения критериев по модели
CREATE OR REPLACE FUNCTION get_criteria_by_model(p_model_id INT)
RETURNS TABLE(dimension_name VARCHAR, sub_dimension_name VARCHAR, criteria_text TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT d.dimension_name, sd.sub_dimension_name, c.criteria_text
    FROM dimensions d
    JOIN sub_dimensions sd ON d.dimension_id = sd.dimension_id
    JOIN criteria c ON sd.sub_dimension_id = c.sub_dimension_id
    WHERE d.model_id = p_model_id;
END;
$$ LANGUAGE plpgsql;

-- Функция для добавления пользовательской конфигурации
CREATE OR REPLACE FUNCTION add_user_configuration(p_user_id INT, p_model_id INT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO user_configurations (user_id, model_id)
    VALUES (p_user_id, p_model_id);
END;
$$ LANGUAGE plpgsql;

-- Функция для получения измерений для конкретной модели
CREATE OR REPLACE FUNCTION get_dimensions_by_model(p_model_id INT)
RETURNS TABLE(dimension_id INT, dimension_name VARCHAR, description TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT d.dimension_id, d.dimension_name, d.description
    FROM dimensions d
    WHERE d.model_id = p_model_id;
END;
$$ LANGUAGE plpgsql;

-- Функция для генерации чек-листа для самооценки
CREATE OR REPLACE FUNCTION generate_checklist(p_model_id INT)
RETURNS TABLE(dimension_name VARCHAR, sub_dimension_name VARCHAR, criteria_text TEXT, level INT) AS $$
BEGIN
    RETURN QUERY
    SELECT d.dimension_name, sd.sub_dimension_name, c.criteria_text, c.level
    FROM dimensions d
    JOIN sub_dimensions sd ON d.dimension_id = sd.dimension_id
    JOIN criteria c ON sd.sub_dimension_id = c.sub_dimension_id
    WHERE d.model_id = p_model_id;
END;
$$ LANGUAGE plpgsql;

-- Функция для сохранения результатов самооценки
CREATE OR REPLACE FUNCTION save_checklist_result(p_config_id INT, p_sub_dimension_id INT, p_score INT, p_comments TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO checklist_results (config_id, sub_dimension_id, score, comments)
    VALUES (p_config_id, p_sub_dimension_id, p_score, p_comments);
END;
$$ LANGUAGE plpgsql;

-- Функция для расчета среднего балла по измерению
CREATE OR REPLACE FUNCTION analyze_results(p_config_id INT)
RETURNS TABLE(dimension_name VARCHAR, average_score NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT d.dimension_name, AVG(cr.score) AS average_score
    FROM checklist_results cr
    JOIN sub_dimensions sd ON cr.sub_dimension_id = sd.sub_dimension_id
    JOIN dimensions d ON sd.dimension_id = d.dimension_id
    WHERE cr.config_id = p_config_id
    GROUP BY d.dimension_name;
END;
$$ LANGUAGE plpgsql;

-- Функция для получения слабых мест
CREATE OR REPLACE FUNCTION get_recommendations(p_config_id INT)
RETURNS TABLE(dimension_name VARCHAR, sub_dimension_name VARCHAR, criteria_text TEXT, recommendations TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.dimension_name,
        sd.sub_dimension_name,
        c.criteria_text,
        CASE
            WHEN c.recommendations::jsonb ? cr.score::TEXT THEN c.recommendations::jsonb ->> cr.score::TEXT
            ELSE 'Рекомендация отсутствует'
        END AS recommendations
    FROM checklist_results cr
    JOIN sub_dimensions sd ON cr.sub_dimension_id = sd.sub_dimension_id
    JOIN dimensions d ON sd.dimension_id = d.dimension_id
    JOIN criteria c ON c.sub_dimension_id = cr.sub_dimension_id
    WHERE cr.config_id = p_config_id;
END;
$$ LANGUAGE plpgsql;


