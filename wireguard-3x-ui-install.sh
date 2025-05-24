#!/bin/bash

echo "🚀 Начинаем установку WireGuard + 3X-UI..."

# === Обновление системы ===
apt update && apt upgrade -y

# === Установка Docker и зависимостей ===
apt install docker.io docker-compose curl qrencode iptables-persistent -y

# === Настройка NAT и IP Forwarding ===
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/wg.conf
sysctl -p /etc/sysctl.d/wg.conf

iptables -A FORWARD -i wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

# === Запуск 3X-UI через Docker ===
docker run -d --name=3x-ui --restart always \
  -e TZ=Asia/Shanghai \
  -p 8000:8000 \
  -p 51820:51820/udp \
  -v /opt/3x-ui:/etc/x-ui \
  --network host \
  mhsanaei/x-ui:latest

# === Готово!
echo ""
echo "🎉 Установка завершена!"
echo "🌐 Панель 3X-UI: http://ваш_IP:8000"
echo "🔐 Логин: admin"
echo "🔑 Пароль: admin"
echo "🚪 WireGuard работает на порту: 51820"
echo "📱 QR-коды можно генерировать через панель"
