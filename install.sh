#!/bin/bash

# --- ЦВЕТА ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---

type_text() {
    local text="$1"
    local delay=0.03
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[ERROR] Запустите скрипт с правами root!${NC}"
        exit 1
    fi
}

# --- ПОДГОТОВКА СИСТЕМЫ ---
prepare_system() {
    # Включение IP Forwarding
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    else
        sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    fi
    sysctl -p > /dev/null

    # Установка iptables-persistent
    export DEBIAN_FRONTEND=noninteractive
    if ! dpkg -s iptables-persistent >/dev/null 2>&1; then
        apt-get update -y > /dev/null
        apt-get install -y iptables-persistent netfilter-persistent > /dev/null
    fi
}

# --- ПРОМО БЛОК (ЗАПУСКАЕТСЯ ПЕРВЫМ) ---
show_promo() {
    local PROMO_LINK="https://vk.cc/ct29NQ"

    # Проверяем наличие qrencode
    if ! command -v qrencode &> /dev/null; then
        echo -e "${YELLOW}[*] Подготовка компонентов...${NC}"
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y > /dev/null
        apt-get install -y qrencode > /dev/null
    fi

    clear
    echo ""
    # Обновленный заголовок под размер текста
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║         ХОСТИНГ, КОТОРЫЙ РАБОТАЕТ СО СКИДКОЙ ДО -60%         ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # 1. Ссылки (Эффект печати)
    echo -ne "${CYAN}"
    type_text "  >>> $PROMO_LINK"
    type_text "  >>> $PROMO_LINK"
    type_text "  >>> $PROMO_LINK"
    echo -ne "${NC}"

    echo ""
    # 2. Орнамент-разделитель
    echo -e "${MAGENTA}❖ •••••••••••••••••• PROMO CODES ••••••••••••••••••• ❖${NC}"
    echo ""

    # 3. Таблица промокодов
    printf "  ${YELLOW}%-12s${NC} : ${WHITE}%s${NC}\n" "OFF60" "60% скидка на первый месяц"
    echo -e "${BLUE}  . . . . . . . . . . . . . . . . . . . . . . . . . . ${NC}"
    
    printf "  ${YELLOW}%-12s${NC} : ${WHITE}%s${NC}\n" "antenka20" "Буст 20% + 3% (при оплате за 3 мес)"
    echo -e "${BLUE}  . . . . . . . . . . . . . . . . . . . . . . . . . . ${NC}"

    printf "  ${YELLOW}%-12s${NC} : ${WHITE}%s${NC}\n" "antenka6" "Буст 15% + 5% (при оплате за 6 мес)"
    echo -e "${BLUE}  . . . . . . . . . . . . . . . . . . . . . . . . . . ${NC}"
	
    printf "  ${YELLOW}%-12s${NC} : ${WHITE}%s${NC}\n" "antenka12" "Буст 5% + 5% (при оплате за 12 мес)"

    echo ""
    echo -e "${MAGENTA}❖ •••••••••••••••••••••••••••••••••••••••••••••••••• ❖${NC}"

    # 4. QR Код
    echo -e "\n${YELLOW}Генерация QR-кода... (5 сек)${NC}"
    for i in {5..1}; do
        echo -ne "$i..."
        sleep 1
    done
    echo ""

    echo -e "\n${WHITE}" 
    qrencode -t ANSIUTF8 "$PROMO_LINK"
    echo -e "${NC}"
    
    echo -e "${GREEN}Сканируйте камерой телефона!${NC}"
    echo ""
    
    # Новая надпись при ожидании
    read -p "Нажмите enter для настройки каскадного скрипта..."
}

# --- ЯДРО НАСТРОЙКИ ---
configure_rule() {
    local PROTO=$1
    local NAME=$2

    echo -e "\n${CYAN}--- Настройка $NAME ($PROTO) ---${NC}"

    while true; do
        echo -e "Введите IP адрес назначения:"
        read -p "> " TARGET_IP
        if [[ -n "$TARGET_IP" ]]; then break; fi
    done

    while true; do
        echo -e "Введите Порт (входной и выходной):"
        read -p "> " PORT
        if [[ "$PORT" =~ ^[0-9]+$ ]] && [ "$PORT" -le 65535 ]; then break; fi
        echo -e "${RED}Ошибка: порт должен быть числом!${NC}"
    done

    IFACE=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
    if [[ -z "$IFACE" ]]; then
        echo -e "${RED}[ERROR] Не удалось определить интерфейс!${NC}"
        exit 1
    fi

    echo -e "${YELLOW}[*] Применение правил...${NC}"

    # Очистка
    iptables -t nat -D PREROUTING -p $PROTO --dport "$PORT" -j DNAT --to-destination "$TARGET_IP:$PORT" 2>/dev/null
    iptables -D INPUT -p $PROTO --dport "$PORT" -j ACCEPT 2>/dev/null
    iptables -D FORWARD -p $PROTO -d "$TARGET_IP" --dport "$PORT" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
    iptables -D FORWARD -p $PROTO -s "$TARGET_IP" --sport "$PORT" -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null

    # Применение
    iptables -A INPUT -p $PROTO --dport "$PORT" -j ACCEPT
    iptables -t nat -A PREROUTING -p $PROTO --dport "$PORT" -j DNAT --to-destination "$TARGET_IP:$PORT"
    
    if ! iptables -t nat -C POSTROUTING -o "$IFACE" -j MASQUERADE 2>/dev/null; then
        iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE
    fi

    iptables -A FORWARD -p $PROTO -d "$TARGET_IP" --dport "$PORT" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -p $PROTO -s "$TARGET_IP" --sport "$PORT" -m state --state ESTABLISHED,RELATED -j ACCEPT

    # UFW Fix
    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        ufw allow "$PORT"/$PROTO >/dev/null
        sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
        ufw reload >/dev/null
    fi

    netfilter-persistent save > /dev/null
    
    echo -e "${GREEN}[SUCCESS] Туннель настроен!${NC}"
    echo -e "$PROTO: Порт $PORT -> $TARGET_IP:$PORT"
    read -p "Нажмите Enter для возврата в меню..."
}

# --- СПИСОК ПРАВИЛ ---
list_active_rules() {
    echo -e "\n${CYAN}--- Активные переадресации ---${NC}"
    echo -e "${MAGENTA}ПОРТ\tПРОТОКОЛ\tЦЕЛЬ${NC}"
    iptables -t nat -S PREROUTING | grep "DNAT" | while read -r line ; do
        l_port=$(echo "$line" | grep -oP '(?<=--dport )\d+')
        l_proto=$(echo "$line" | grep -oP '(?<=-p )\w+')
        l_dest=$(echo "$line" | grep -oP '(?<=--to-destination )[\d\.:]+')
        if [[ -n "$l_port" ]]; then echo -e "$l_port\t$l_proto\t\t$l_dest"; fi
    done
    echo ""
    read -p "Нажмите Enter..."
}

# --- ПОЛНАЯ ОЧИСТКА ---
flush_rules() {
    echo -e "\n${RED}!!! ВНИМАНИЕ !!!${NC}"
    echo "Это удалит ВСЕ правила NAT и сбросит iptables."
    read -p "Вы уверены? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -t nat -F
        iptables -t mangle -F
        iptables -F
        iptables -X
        netfilter-persistent save > /dev/null
        echo -e "${GREEN}[OK] Очищено.${NC}"
    fi
    read -p "Нажмите Enter..."
}

# --- МЕНЮ ---
show_menu() {
    while true; do
        clear
        echo -e "${MAGENTA}"
        echo "******************************************************"
        echo "       anten-ka канал представляет..."
        echo "       TRAFFIC MANAGER & TOOLS"
        echo "******************************************************"
        echo -e "${NC}"
        
        echo -e "1) Настроить ${CYAN}AmneziaWG / WireGuard${NC} (UDP)"
        echo -e "2) Настроить ${CYAN}VLESS / XRay${NC} (TCP)"
        echo -e "3) Посмотреть активные правила"
        echo -e "4) Удалить все правила (Сброс)"
        echo -e "5) ${YELLOW}Показать PROMO${NC}"
        echo -e "0) Выход"
        echo -e "------------------------------------------------------"
        read -p "Ваш выбор: " choice

        case $choice in
            1) configure_rule "udp" "AmneziaWG" ;;
            2) configure_rule "tcp" "VLESS" ;;
            3) list_active_rules ;;
            4) flush_rules ;;
            5) show_promo ;;
            0) exit 0 ;;
            *) ;;
        esac
    done
}

# --- ЗАПУСК ---
check_root
prepare_system

# СНАЧАЛА ПОКАЗЫВАЕМ РЕКЛАМУ
show_promo

# ПОТОМ МЕНЮ
show_menu
