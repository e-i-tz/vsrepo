#!/bin/bash

apt update && apt upgrade 

if ls -l | grep grafana.asc;
then
    mv grafana.asc /etc/apt/keyrings
    gpg --dearmor /etc/apt/keyrings/grafana.asc 
    mv /etc/apt/keyrings/grafana.asc.gpg /etc/apt/keyrings/grafana.gpg
    chmod 644 /etc/apt/keyrings/grafana.gpg
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://mirror.yandex.ru/mirrors/packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
else
echo "Ключ репозитория Grafana не найден!
    Сделайте следующие шаги:
        1) перейдите по адресу https://apt.grafana.com/gpg.key (Требуется VPN)
        2) создате файл grafana.asc
        3) Перенесите в этот файл содержимое страницы"
    exit 1   
fi     

apt update && apt install -y grafana

echo "Проверяем, занят ли порт TCP:3000"

PORT3000_PID=$(sudo lsof -i TCP:3000 -sTCP:LISTEN | awk 'NR==2 {print $2}')

if [[ -n "$PORT3000_PID" ]]; then
    echo "TCP:3000 занят процессом PID $PORT3000_PID"
    kill -9 "$PORT3000_PID"
else
    echo "Порт 3000 свободен."
fi

systemctl enable -q grafana-server
systemctl start -q grafana-server

#Установка Loki и fluent-bit

apt install -y promtail loki

curl -fsSL https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg
codename=$(grep -oP '(?<=VERSION_CODENAME=).*' /etc/os-release 2>/dev/null || lsb_release -cs 2>/dev/null)
echo "deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/ubuntu/$codename $codename main" | sudo tee /etc/apt/sources.list.d/fluent-bit.list

apt-get update
apt-get install -y fluent-bit

#Редактирование конфига fluent-bit

if ls -l | grep fluent-bit.conf; then
mv fluent-bit.conf /etc/fluent-bit/fluent-bot.conf    
else
    echo "Скачайте файл fluent-bit.conf"
    exit 1
fi

systemctl enable fluent-bit
systemctl start -q fluent-bit