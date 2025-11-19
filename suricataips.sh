#!/bin/bash

echo "Скрипт для конфигурациия Suricata в режиме IPS"

if apt list --installed 2>/dev/null | grep -q suricata;
then
    echo "Suricata установлена."
else
    echo "Suricata не установлена. Установите и настройте Suricata по инструкциям прошлых работ"
    exit 1 
fi

#Добавляем правило IPS
cat > "/etc/suricata/rules/custom.rules" << EOF
drop icmp any any -> any any (msg:"[DROP] ICMP Ping Detected"; sid:1000001; rev:1;)
EOF

#Редактируем конфиг Suricata
yq -i '.nfq +=[{"id":0,"fail-open":"yes","buffer-size":1048576}]' /etc/suricata/suricata.yaml

#Включаем модуль nfnetlink_queue
modprobe nfnetlink_queue

#правила iptables
iptables -I INPUT -j NFQUEUE --queue-num 0
iptables -I OUTPUT -j NFQUEUE --queue-num 0

if apt list --installed 2>/dev/null | grep -q suricata;
then
    echo "Suricata установлена."
else
    echo "Suricata не установлена. Установите и настройте Suricata по инструкциям прошлых работ"
    exit 1 
fi

if systemctl is-active suricata | grep active;
then 
    systemctl stop -q suricata
fi    

echp "Настройка Suricata в режиме IPS завершена!"