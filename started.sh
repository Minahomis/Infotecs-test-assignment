#!/bin/bash
set -e

BUILD_TYPE=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Проверка валидности аргумента
if [ -z "$BUILD_TYPE" ]; then
    echo "Ошибка! Не указан тип сборки" >&2
    exit 1
fi

case "$BUILD_TYPE" in
    release|debug|coverage) ;;
    *)
        echo "Ошибка! Неверный тип сборки: $BUILD_TYPE" >&2
        echo "Допустимо: release | debug | coverage" >&2
        exit 1
        ;;
esac

# Сборка образа если нет
if ! sudo docker image inspect nginx:last-test > /dev/null 2>&1; then
    echo "Образ отсутствует — выполняется сборка"
    sudo docker build -t nginx:last-test .
else
    echo "Образ существует — будет запущен контейнер"
fi

# Запуск контейнера и передача BUILD_TYPE
    sudo docker run --rm \
        -v "$(pwd)/coverage_reports:/coverage" \
        -v "$(pwd)/artefacts:/artefacts" \
        -v "$(pwd)/history:/reports" \
        nginx:last-test "$BUILD_TYPE"
