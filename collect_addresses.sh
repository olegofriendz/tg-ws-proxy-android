#!/bin/bash

LOG_FILE="proxy.log"
ADDRESSES_FILE="addresses.log"

echo "Анализ логов..."

if [ ! -f "$LOG_FILE" ]; then
    echo "Файл $LOG_FILE не найден!"
    echo "Сначала запусти: ./start_proxy.sh"
    exit 1
fi

LOG_LINES=$(wc -l < $LOG_FILE) # кол-во строк

if [ "$LOG_LINES" -eq 0 ]; then
    echo "Лог пуст!"
    exit 1
fi

grep "unknown DC" $LOG_FILE | \
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
  sort | \
  uniq > $ADDRESSES_FILE

IP_COUNT=$(wc -l < $ADDRESSES_FILE)

echo "Статистика:"
echo "Строк в логе: $LOG_LINES"
echo "Найдено IP: $IP_COUNT"
echo ""

if [ "$IP_COUNT" -gt 0 ]; then
    echo "Адреса сохранены в $ADDRESSES_FILE:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat $ADDRESSES_FILE
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "Неизвестные IP не найдены"
    echo "Возможно:"
    echo "Все IP уже известны прокси"
    echo "Telegram ещё не успел загрузить контент"
    echo "Попробуй загрузить больше видео/картинок"
fi