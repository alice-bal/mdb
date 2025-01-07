FROM postgres:14
ENV POSTGRES_DB=maturity_classifier
ENV POSTGRES_USER=admin
ENV POSTGRES_PASSWORD=secret

# Копируем скрипты для инициализации базы
COPY init-scripts/ /docker-entrypoint-initdb.d/
