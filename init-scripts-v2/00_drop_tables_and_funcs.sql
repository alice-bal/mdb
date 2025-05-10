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
