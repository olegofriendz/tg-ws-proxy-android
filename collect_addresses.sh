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

grep "unknown DC" $LOG_FILE | \
  sed -n 's/.*unknown DC\(-\?[0-9]*\) for \([0-9.]*\):.*/\2 \1/p' | \
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

echo "{" > $ADDRESSES_FILE

FIRST=true
while read -r line; do
    IP=$(echo $line | awk '{print $1}')
    DC=$(echo $line | awk '{print $2}')
    
    if [[ $DC == -* ]]; then
        IS_MEDIA="true"
    else
        IS_MEDIA="false"
    fi
    
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
echo "Сохранено в $ADDRESSES_FILE:"
cat $ADDRESSES_FILE