#!/bin/bash

#Проверка, есть ли в локальном репозитории образ nginx


if sudo docker image inspect nginx > /dev/null 2>&1; then
    echo "Образ существует"
    $(sudo docker create nginx)
else 
    echo "Такого образа не существует"
    $(sudo docker build nginx)
    $(sudo docker create nginx)
fi


