#!/bin/bash

BUILD_TYPE="$1"
HISTORY_FILE="$2" 
DATE_TIME=$(date +"%Y-%m-%d_%H-%M-%S")

echo "Тип сборки: $BUILD_TYPE"
git clone --progress https://github.com/nginx/nginx.git
cd nginx/

# переменные для report  
GIT_REVISION=$(git rev-parse --short HEAD)  # короткий SHA коммита
GIT_TAG=$(git describe --tags --always)     # человеко-читаемая форма
REVISION="${GIT_TAG}_${GIT_REVISION}"      # пример: v1.2.3_a1b2c3d
LAST_RUN=$(ls -1 /history/build_report_*.txt 2>/dev/null | wc -l)
RUN_NUMBER=$((LAST_RUN + 1))
CUR_COVERAGE="N/A"

case "$BUILD_TYPE" in

    release)
        echo "=== RELEASE BUILD ==="
        ./auto/configure --with-cc-opt="-O3"
        make install
        make
        sleep 5
        strip /usr/local/nginx/sbin/nginx

        ARTIFACT="/artefacts/nginx_${BUILD_TYPE}_r${REVISION}_${DATE_TIME}.tar.gz"
        tar czf "$ARTIFACT" ./objs
        echo "Артефакт сохранён: $ARTIFACT"
        # Sleep 5 нужен, так как иначе strip начинает выполняться еще до того, как файл /usr/local/nginx/sbin/nginx полностью сбилдиться
        ;;

    debug)
        echo "=== DEBUG BUILD ==="
        ./auto/configure --with-debug --with-cc-opt="-O2 -g"
        make install
        make
        ARTIFACT="/artefacts/nginx_${BUILD_TYPE}_r${REVISION}_${DATE_TIME}.tar.gz"
        tar czf "$ARTIFACT" ./objs
        echo "Артефакт сохранён: $ARTIFACT"
        ;;

    coverage)
        echo "=== COVERAGE BUILD ==="

        ./auto/configure \
            --with-debug \
            --with-cc-opt="-O0 -g -fprofile-arcs -ftest-coverage" \
            --with-ld-opt="-fprofile-arcs -ftest-coverage"

        make -j$(nproc)
        cd ..

        # Клонируем тесты если их нет
        if [ ! -d "nginx-tests" ]; then
            git clone https://github.com/nginx/nginx-tests.git
        fi

        cd nginx-tests
        export TEST_NGINX_BINARY=../nginx/objs/nginx
        echo "=== RUNNING TESTS ==="
        prove -r .

        cd ../nginx
        echo "=== GENERATING COVERAGE REPORT ==="
        lcov --capture --directory . --output-file coverage.info
        genhtml coverage.info --output-directory coverage-report

        SUMMARY=$(lcov --summary coverage.info 2>/dev/null)
        FUNC_COVERAGE=$(echo "$SUMMARY" | grep "functions" | awk '{print $2}')

        RESULT_FILE="/coverage/result_test-${DATE_TIME}.txt"
        echo "Function coverage: $FUNC_COVERAGE" > "$RESULT_FILE"
        echo "Отчёт сохранён: $RESULT_FILE"


         # Определяем предыдущий запуск по временной метке
        PREV_FILE=$(ls -1t /coverage/result_test-*.txt 2>/dev/null | grep -v "$RESULT_FILE" | head -n1)
        # Расчёт больше или меньше % покрытия
        if [ -n "$PREV_FILE" ]; then
            PREV_COVERAGE=$(cat "$PREV_FILE" | awk '{print $3}' | sed 's/%//')
            CUR_COVERAGE=$(echo "$FUNC_COVERAGE" | sed 's/%//')
            echo "Предыдущий процент покрытия: $PREV_COVERAGE%"
            echo "Текущий процент покрытия: $CUR_COVERAGE%"

            if (( $(echo "$CUR_COVERAGE < $PREV_COVERAGE" | bc -l) )); then
                echo "ВНИМАНИЕ! Процент покрытия интеграционными тестами уменьшился по сравнению с предыдущим запуском." >&2
                exit 1
            else
                echo "Сборка успешна."

                ARTIFACT="/artefacts/nginx_${BUILD_TYPE}_r${REVISION}_${DATE_TIME}.tar.gz"
                tar czf "$ARTIFACT" ./objs
                echo "Артефакт сохранён: $ARTIFACT"
            fi
        else
            echo "Первый запуск — предыдущего результата нет. Сохраняем текущий."
        fi
        ;;

    *)
        exit 1
        ;;
esac

#Запись истории

{
    echo "Номер запуска: $RUN_NUMBER"
    echo "Уникальный номер ревизии: $REVISION"
    echo "Тип сборки: $BUILD_TYPE"
    echo "Значение покрытия: $CUR_COVERAGE"
} >> "$HISTORY_FILE" 2>/dev/null || echo "ОШИБКА ЗАПИСИ В $HISTORY_FILE (код $?)"

echo "Сборка завершена, история сохранена: $HISTORY_FILE"

