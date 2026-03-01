#!/bin/bash

#Проверка, есть ли в локальном репозитории образ nginx

if sudo docker image inspect nginx:test-arg > /dev/null 2>&1; then
    echo "Образ существует"
    sudo docker create nginx
else 
    echo "Такого образа не существует"
    sudo docker build --build-arg build_type=$1 -t nginx:test-arg .
    sudo docker create nginx
fi


