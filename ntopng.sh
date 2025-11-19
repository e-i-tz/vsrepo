#!/bin/bash

#Путь к конфигу
CONFIG_PATH = /etc/ntopng.conf


#ntopng 
apt install -y software-properties-common wget add-apt-repository universe
wget https://packages.ntop.org/apt-stable/24.04/all/apt-ntop-stable.deb
apt install -y ./apt-ntop-stable.deb
apt update

apt install -y pfring-dkms nprobe ntopng n2disk cento

INTERFACE=$(ip a | grep -Po '(?<=2: )\w+')
echo "Ваш интерфейс: $INTERFACE"

cat > "$CONFIG_PATH" << EOF
# This configuration file is similar to the command line, with the exception
# that an equal sign '=' must be used between key and value. Example: -i=p1p2
# or --interface=p1p2 For options with no value (e.g. -v) the equal is also
# necessary. Example: "-v=" must be used.
#
# DO NOT REMOVE the following option, required for daemonization.
-e=

# Custom configuration
--interface=$INTERFACE
--http-port=3000
--local-networks="192.168.0.0/24"
--disable-login=0
EOF

echo "Конфигурационный файл полностью обновлен"

systemctl enable -q ntopng
systemctl start -q ntopng
if [ $? eq 0 ]
then
    echo "Запуск демона ntopng прошёл успешно"
else
    echo "Ошибка запуска ntopng" >&2
fi

