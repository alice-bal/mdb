-- Тест 1: Список моделей
SELECT * FROM get_models();

-- Тест 2: Иерархия измерений по модели 1
SELECT * FROM generate_dimensions_tree(1);

-- Тест 3: Создание пользовательской конфигурации
SELECT add_user_configuration(1, 1);
SELECT * FROM user_configurations;

-- Тест 4: Привязка критериев к конфигурации
SELECT link_criteria_to_config(1, 1);
SELECT link_criteria_to_config(1, 2);
SELECT link_criteria_to_config(1, 3);

-- Тест 5: Сохранение оценок
SELECT save_criteria_score(1, 1, 4, 'Хороший прогресс', FALSE);
SELECT save_criteria_score(1, 2, 3, 'Есть идеи, нужно масштабировать', FALSE);
SELECT save_criteria_score(1, 3, 2, 'Мало облака', FALSE);
SELECT * FROM requirements_status;

-- Тест 6: Анализ результатов
SELECT * FROM analyze_results(1);

-- Тест 7: Рекомендации
SELECT * FROM get_recommendations(1);

-- Проверка пустых конфигураций
SELECT * FROM get_recommendations(99);
SELECT * FROM analyze_results(99);
