#!/bin/bash

LOG_FILE="proxy.log"
ADDRESSES_FILE="ip_mapping.json"

echo "Анализ логов..."

[ ! -f "$LOG_FILE" ] && echo "Файл $LOG_FILE не найден!" && exit 1

TEMP_FILE=$(mktemp)

grep "unknown DC" $LOG_FILE | \
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
  grep -v "127.0.0.1" | \
  sort | uniq > $TEMP_FILE

[ "$(wc -l < $TEMP_FILE)" -eq 0 ] && echo "Неизвестные IP не найдены" && rm $TEMP_FILE && exit 0

# Загружаем существующие ключи
EXISTING=$(python3 -c "import json; print(' '.join(json.load(open('$ADDRESSES_FILE')).keys()))" 2>/dev/null || echo "")

get_dc() {
  case $1 in
    149.154.175.*) echo 1 ;;
    149.154.167.*) echo 2 ;;
    149.154.166.*) echo 4 ;;
    91.108.56.*)   echo 5 ;;
    91.105.192.*)  echo 203 ;;
    *) echo 2 ;;
  esac
}

get_media() {
  case $1 in
    149.154.167.151|149.154.167.222|149.154.167.223) echo true ;;
    149.154.166.120|149.154.166.121|149.154.165.111) echo true ;;
    91.108.56.102|91.108.56.128|91.108.56.151) echo true ;;
    *) echo false ;;
  esac
}

# Читаем текущий файл или создаём новый
if [ -f "$ADDRESSES_FILE" ]; then
  cp "$ADDRESSES_FILE" "${ADDRESSES_FILE}.bak"
  python3 -c "import json; d=json.load(open('$ADDRESSES_FILE')); print(json.dumps(d, indent=2))" > "${ADDRESSES_FILE}.tmp"
  mv "${ADDRESSES_FILE}.tmp" "$ADDRESSES_FILE"
else
  echo "{}" > "$ADDRESSES_FILE"
fi

# Добавляем новые IP
while read -r IP; do
  echo "$EXISTING" | grep -qw "$IP" && continue
  
  DC=$(get_dc "$IP")
  MEDIA=$(get_media "$IP")
  
  python3 -c "
import json
with open('$ADDRESSES_FILE', 'r') as f:
    d = json.load(f)
d['$IP'] = [$DC, $MEDIA]
with open('$ADDRESSES_FILE', 'w') as f:
    json.dump(d, f, indent=2)
"
  echo "Добавлен: $IP -> DC$DC"
done < $TEMP_FILE

rm $TEMP_FILE
echo "Готово. Файл: $ADDRESSES_FILE"