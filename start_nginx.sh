#!/bin/bash

git clone https://github.com/nginx/nginx.git

cd nginx/
# Release version. Strip binary and -o3
#

./auto/configure --with-cc-opt="-O3"

make install
make
sleep 5s
strip /usr/local/nginx/sbin/nginx
#Release vervion работает! sleep 5 нужен, так как иначе strip начинает выполняться еще до того, как файл /usr/local/nginx/sbin/nginx полностью сбилдиться

#Далее запуск Бэбаг версии
./auto/configure --with-debug --with-cc-opt="-O2"

make install
#Coverage 



#Debug version. --with-debug
#./auto/configure --with-debu
