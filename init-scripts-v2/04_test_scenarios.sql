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
