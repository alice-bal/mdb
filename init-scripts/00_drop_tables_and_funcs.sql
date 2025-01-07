-- Дроп таблиц
DROP TABLE IF EXISTS checklist_results CASCADE;
DROP TABLE IF EXISTS user_configurations CASCADE;
DROP TABLE IF EXISTS criteria CASCADE;
DROP TABLE IF EXISTS sub_dimensions CASCADE;
DROP TABLE IF EXISTS dimensions CASCADE;
DROP TABLE IF EXISTS models CASCADE;

-- Дроп функций
DROP FUNCTION IF EXISTS get_models();
DROP FUNCTION IF EXISTS get_criteria_by_model(INT);
DROP FUNCTION IF EXISTS add_user_configuration(INT, INT);
DROP FUNCTION IF EXISTS get_dimensions_by_model(INT);
DROP FUNCTION IF EXISTS generate_checklist(INT);
DROP FUNCTION IF EXISTS save_checklist_result(INT, INT, INT, TEXT);
DROP FUNCTION IF EXISTS analyze_results(INT);
DROP FUNCTION IF EXISTS get_recommendations(INT);
