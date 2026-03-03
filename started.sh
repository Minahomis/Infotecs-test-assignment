#!/bin/bash
set -e

BUILD_TYPE=$(echo "$1" | tr '[:upper:]' '[:lower:]')
HISTORY_DIR="$(pwd)/history"
mkdir -p "$HISTORY_DIR"

COUNTER_FILE="$HISTORY_DIR/.last_run_number"
if [ ! -f "$COUNTER_FILE" ]; then
    echo 0 > "$COUNTER_FILE"
    chmod 666 "$COUNTER_FILE" 2>/dev/null || true
fi
LAST_RUN=$(cat "$COUNTER_FILE")
RUN_NUMBER=$((LAST_RUN + 1))
echo "$RUN_NUMBER" > "$COUNTER_FILE"

# Проверка типа сборки (твой код без изменений)
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

if ! docker image inspect nginx-test:latest > /dev/null 2>&1; then
    echo "Образ отсутствует — выполняется сборка"
    docker build -t nginx-test:latest .
else
    echo "Образ существует — будет запущен контейнер"
fi

DATE_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
HISTORY_FILENAME="build_report_${DATE_TIME}.txt"
HISTORY_FILE_CONTAINER="/reports/${HISTORY_FILENAME}"

docker run --rm \
    -v "$HISTORY_DIR:/reports" \
    -v "$(pwd)/coverage_reports:/coverage" \
    -v "$(pwd)/artefacts:/artefacts" \
    -e RUN_NUMBER="$RUN_NUMBER" \
    nginx-test:latest "$BUILD_TYPE" "$HISTORY_FILE_CONTAINER"
