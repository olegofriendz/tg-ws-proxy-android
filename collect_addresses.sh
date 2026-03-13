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

# Извлекаем IP (игнорируем DC номер - он может быть неправильным)
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

# Загружаем существующие IP
if [ -f "$ADDRESSES_FILE" ]; then
    cp $ADDRESSES_FILE $BACKUP_FILE
    EXISTING_IPS=$(grep -oE '"[0-9.]+"' $ADDRESSES_FILE | tr -d '"')
    echo "Бэкап: $BACKUP_FILE"
else
    EXISTING_IPS=""
    echo "{}" > $ADDRESSES_FILE
fi

# Определяем DC по IP
get_dc_by_ip() {
    local ip=$1
    case $ip in
        149.154.175.*) echo "1" ;;
        149.154.167.*) echo "2" ;;
        149.154.166.*) echo "4" ;;
        91.108.56.*)   echo "5" ;;
        91.105.192.*)  echo "203" ;;
        149.154.165.*) echo "4" ;;
        *)             echo "2" ;;
    esac
}

# Определяем медиа (Python требует True/False с большой буквы!)
get_is_media() {
    local ip=$1
    case $ip in
        149.154.167.151|149.154.167.222|149.154.167.223) echo "True" ;;
        149.154.164.250|149.154.166.120|149.154.166.121) echo "True" ;;
        149.154.167.118|149.154.165.111|149.154.165.136) echo "True" ;;
        91.108.56.102|91.108.56.128|91.108.56.151) echo "True" ;;
        *) echo "False" ;;
    esac
}

# Начинаем JSON
echo "{" > $ADDRESSES_FILE

# Добавляем СТАРЫЕ IP
FIRST=true
if [ -f "$BACKUP_FILE" ]; then
    while IFS= read -r line; do
        IP=$(echo "$line" | grep -oE '"[0-9.]+"' | head -1 | tr -d '"')
        DATA=$(echo "$line" | grep -oE '\[[0-9-]+, [A-Za-z]+\]')
        if [ -n "$IP" ] && [ -n "$DATA" ]; then
            if [ "$FIRST" = true ]; then
                FIRST=false
            else
                echo "," >> $ADDRESSES_FILE
            fi
            printf '  "%s": %s' "$IP" "$DATA" >> $ADDRESSES_FILE
        fi
    done < <(grep -E '^\s*"[0-9.]+"' "$BACKUP_FILE")
fi

# Добавляем НОВЫЕ IP
while read -r IP; do
    if echo "$EXISTING_IPS" | grep -q "^${IP}$"; then
        continue
    fi
    
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

echo "Добавлено IP: $IP_COUNT"
echo "Файл: $ADDRESSES_FILE"
cat $ADDRESSES_FILE