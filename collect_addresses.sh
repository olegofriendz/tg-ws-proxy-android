#!/bin/bash

LOG_FILE="proxy.log"
ADDRESSES_FILE="ip_mapping.json"
BACKUP_FILE="ip_mapping.backup.json"

echo "Анализ логов..."

if [ ! -f "$LOG_FILE" ]; then
    echo "Файл $LOG_FILE не найден!"
    exit 1
fi

TEMP_FILE=$(mktemp)

# Извлекаем только IP (игнорируем неправильный DC из лога)
grep "unknown DC" $LOG_FILE | \
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
  grep -v "127.0.0.1" | \
  sort | uniq > $TEMP_FILE

IP_COUNT=$(wc -l < $TEMP_FILE)

if [ "$IP_COUNT" -eq 0 ]; then
    echo "Неизвестные IP не найдены"
    rm $TEMP_FILE
    exit 0
fi

if [ -f "$ADDRESSES_FILE" ]; then
    cp $ADDRESSES_FILE $BACKUP_FILE
    echo "Бэкап сохранён в $BACKUP_FILE"
fi

# Определяем DC по IP-диапазону
get_dc_by_ip() {
    local ip=$1
    
    case $ip in
        149.154.175.*) echo "1" ;;
        149.154.167.*) echo "2" ;;
        149.154.175.*) echo "3" ;;
        149.154.166.*) echo "4" ;;
        91.108.56.*)   echo "5" ;;
        91.105.192.*)  echo "203" ;;
        *)             echo "2" ;;
    esac
}

# Определяем, медиа ли это
get_is_media() {
    local ip=$1
    
    case $ip in
        149.154.167.151|149.154.167.222|149.154.167.223) echo "true" ;;
        149.154.164.250|149.154.166.120|149.154.166.121|149.154.167.118|149.154.165.111) echo "true" ;;
        91.108.56.102|91.108.56.128|91.108.56.151) echo "true" ;;
        *) echo "false" ;;
    esac
}

echo "{" > $ADDRESSES_FILE

FIRST=true
while read -r IP; do
    DC=$(get_dc_by_ip "$IP")
    IS_MEDIA=$(get_is_media "$IP")
    
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo "," >> $ADDRESSES_FILE
    fi
    
    printf '  "%s": [%s, %s]' "$IP" "$DC" "$IS_MEDIA" >> $ADDRESSES_FILE
    
done < $TEMP_FILE

echo "" >> $ADDRESSES_FILE
echo "}" >> $ADDRESSES_FILE

rm $TEMP_FILE

echo "Найдено IP: $IP_COUNT"
echo "Сохранено в $ADDRESSES_FILE"