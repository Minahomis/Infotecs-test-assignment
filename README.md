# Pipline build nginx 

Проект был написан в рамках тестового задания на стажировку infotecs. 
Проект для автоматической сборки nginx из исходных файлов в docker конейнере, с поддержкой нескольких режимов сборки (release, budug, coverage). А также с хранением истории запусков

## Основные возможности

- Сборка nginx в трёх режимах:
  - `release` — оптимизированная сборка с `-O3` и strip
  - `debug` — сборка с отладочной информацией
  - `coverage` — сборка с инструментацией gcov/lcov + запуск тестов nginx-tests
- Сохранение артефактов
- Сохранение отчётов покрытия
- Хранение истории запусков (номер, ревизия, тип сборки, покрытие)

## Структура проекта
```
.
├── artefacts/               # артефакты nginx
├── coverage_reports/        # отчёты о покрытии
├── history/                 # история запусков
├── Dockerfile               # образ для сборки
├── started.sh               # скрипт запуска
├── start_nginx.sh           # скрипт для запуска nginx
└── README.md
```

## Запуск

```bash
# Release-сборка (оптимизированная)
bash started.sh release

# Debug-сборка (с отладочной информацией)
bash started.sh debug

# Coverage (запуск тестов)
bash started.sh coverage
```
После успешной сборки в директориях history/, artefacts/, coverage_reports/ будут записаны данные запуска контейнера.


## Полезные команды для отладки

```bash
# Посмотреть образы
docker image ls | grep nginx:last-test

# Удалить образ, чтобы пересобрать
docker rmi nginx-test:latest

# Запустить контейнер в интерактивном режиме для отладки
docker run -it --rm \
  -v "$(pwd)/coverage_reports:/coverage" \
  -v "$(pwd)/artefacts:/artefacts" \
  -v "$(pwd)/history:/reports" \
  nginx-test:latest bash
```

