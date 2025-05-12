@echo off
chcp 65001 >nul

echo "Остановка контейнеров и удаление volumes..."
docker-compose down -v

echo "Пересборка и запуск..."
docker-compose up --build

pause