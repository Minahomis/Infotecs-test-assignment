#!/bin/bash
#Заменить if else на switch case

echo "Тип сборки: $1"

git clone --progress https://github.com/nginx/nginx.git
cd nginx/
# Release version. Strip binary and -o3
#Release vervion работает! sleep 5 нужен, так как иначе strip начинает выполняться еще до того, как файл /usr/local/nginx/sbin/nginx полностью сбилдиться
if $1 = release; then
    ./auto/configure --with-cc-opt="-O3"
    make install
    make
    sleep 5s
    strip /usr/local/nginx/sbin/nginx
elif $1 = debug; then
    ./auto/configure --with-debug --with-cc-opt="-O2"
    make install
else
    echo "Coverage development"
fi

#Coverage 



#Debug version. --with-debug
#./auto/configure --with-debu
