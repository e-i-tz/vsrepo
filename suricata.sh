#!/bin/bash

INTERFACE=$(ip a | grep -Po '(?<=2: )\w+')
SURICATA_CONFIG_PATH=/etc/suricata/suricata.yaml

apt update && apt upgrade 
apt install -y suricata 

wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq

echo "Редактируем конфигурационный файл Suricata..."
yq eval -i '.default-rule-path = "'"/etc/suricata/rules"'"' $SURICATA_CONFIG_PATH
yq eval -i '.af-packet[0].interface = "'"$INTERFACE"'"' $SURICATA_CONFIG_PATH
yq -i '.rule-files += ["custom.rules"]' $SURICATA_CONFIG_PATH 
echo "Конфигурационный файл отредактирован!"

#Запись правила
touch /etc/suricata/rules/custom.rules
cat > "/etc/suricata/rules/custom.rules" << EOF
alert tcp any any -> any 4444 (msg:"[ALERT] TCP SYN Flood on port 4444 detected"; flags:S; threshold:type both, track by_src, count 20, seconds 1; sid:1000002; rev:1;)
EOF
echo "Правило создано!"

systemctl enable -q suricata
systemctl start -q suricata
if [ $? -eq 0 ]
then
    echo "Запуск suricata прошёл успешно"
else
    echo "Ошибка запуска suricata" >&2
fi 