#!/bin/bash

# === Цвета для вывода ===
GREEN='\033[0;32m'
NC='\033[0m'

clear
echo -e "${GREEN}🚀 Начинаем установку WireGuard + 3X-UI Pro Edition${NC}"
sleep 2

# === Шаг 1: Обновление системы ===
echo -e "${GREEN}🔄 Обновляем систему...${NC}"
apt update && apt upgrade -y

# === Шаг 2: Установка зависимостей ===
echo -e "${GREEN}📦 Устанавливаем Docker и зависимости...${NC}"
apt install -y curl wget qrencode iptables-persistent docker.io docker-compose

# === Шаг 3: Включение IP Forwarding ===
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/wg.conf
sysctl -p /etc/sysctl.d/wg.conf

iptables -A FORWARD -i wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

# === Шаг 4: Запуск 3X-UI через рабочий образ ===
echo -e "${GREEN}⚙️ Запускаем 3X-UI с поддержкой VLESS / Shadowsocks...${NC}"

docker run -d --name=3x-ui --restart always \
  -e TZ=Asia/Shanghai \
  -p 8000:8000 \
  -p 51820:51820/udp \
  -v /opt/3x-ui:/etc/x-ui \
  --network host \
  enwaiax/3x-ui:latest

# === Шаг 5: Установка WireGuard UI (wg-easy) ===
echo -e "${GREEN}⚙️ Устанавливаем WireGuard веб-панель...${NC}"

WG_HOST=$(curl -s ifconfig.me)
WEB_UI_PORT=8001
DOCKER_DIR="/opt/wireguard-ui"

mkdir -p "$DOCKER_DIR"
cd "$DOCKER_DIR" || exit

cat <<EOF > docker-compose.yml
version: '3.3'
services:
  wireguard-ui:
    image: weejewel/wg-easy
    container_name: wireguard-ui
    environment:
      - WG_HOST=$WG_HOST
      - USERNAME=admin
      - PASSWORD=admin1234
    volumes:
      - ./wg-data:/etc/wireguard
    ports:
      - "$WEB_UI_PORT:8000"
      - "51820:51820/udp"
    restart: unless-stopped
    cap-add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.conf.all.src_vmark=1
EOF

docker-compose up -d

# === Информация пользователю ===
echo ""
echo -e "${GREEN}🎉 Установка завершена успешно!${NC}"
echo ""
echo -e "${GREEN}🔐 Данные для WireGuard UI:${NC}"
echo "🌐 Адрес: http://$WG_HOST:$WEB_UI_PORT"
echo "👤 Логин: admin"
echo "🔑 Пароль: admin1234"
echo ""
echo -e "${GREEN}🔐 Данные для 3X-UI:${NC}"
echo "🌐 Адрес: http://$WG_HOST:8000"
echo "👤 Логин: admin"
echo "🔑 Пароль: admin"
echo ""
echo -e "${GREEN}💡 Совет: Измени оба пароля после первого входа.${NC}"
