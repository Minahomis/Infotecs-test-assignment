#!/bin/bash
#Заменить if else на switch case

echo "Тип сборки: $1"
BUILD_TYPE="$1"

git clone --progress https://github.com/nginx/nginx.git
cd nginx/
# Release version. Strip binary and -o3
# Release vervion работает! sleep 5 нужен, так как иначе strip начинает выполняться еще до того, как файл /usr/local/nginx/sbin/nginx полностью сбилдиться
#if $1 = release; then

#    ./auto/configure --with-cc-opt="-O3"
#    make install
#    make
#    sleep 5s
#    strip /usr/local/nginx/sbin/nginx
#elif $1 = debug; then
#    ./auto/configure --with-debug --with-cc-opt="-O2"
#    make install
#else
#    echo "Coverage development"
#fi

#Coverage 

case "$BUILD_TYPE" in

    release)
        echo "=== RELEASE BUILD ==="
        ./auto/configure --with-cc-opt="-O3"
        make install
        make
        sleep 5
        strip /usr/local/nginx/sbin/nginx
        ;;

    debug)
        echo "=== DEBUG BUILD ==="
        ./auto/configure --with-debug --with-cc-opt="-O2 -g"
        make install
        make
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

        DATE_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
        RESULT_FILE="/coverage/result_test-${DATE_TIME}.txt"
        echo "Function coverage: $FUNC_COVERAGE" > "$RESULT_FILE"
        echo "Отчёт сохранён: $RESULT_FILE"


         # --- Определяем предыдущий запуск по временной метке ---
        PREV_FILE=$(ls -1t /coverage/result_test-*.txt 2>/dev/null | grep -v "$RESULT_FILE" | head -n1)

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

                ARTIFACT="/artefacts/nginx_build_${DATE_TIME}.tar.gz"
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

