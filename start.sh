#!/bin/bash

PORT=1080
LOG_FILE="proxy.log"
ADDRESSES_FILE="addresses.log"

echo "Запуск прокси на порту $PORT..."
killall python 2>/dev/null
nohup python proxy/tg_ws_proxy.py --port $PORT --verbose > $LOG_FILE 2>&1 &
PROXY_PID=$!

echo "Прокси запущен (PID: $PROXY_PID)"
echo "Логи пишутся в: $LOG_FILE"
echo ""

sleep 5

echo "Сбор неизвестных IP из логов..."
grep "unknown DC" $LOG_FILE | \
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
  sort | \
  uniq > $ADDRESSES_FILE

IP_COUNT=$(wc -l < $ADDRESSES_FILE)

if [ "$IP_COUNT" -gt 0 ]; then
    echo "Найдено IP-адресов: $IP_COUNT"
    echo ""
    echo "Список сохранён в $ADDRESSES_FILE:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat $ADDRESSES_FILE
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "Неизвестные IP не найдены!"
fi

echo "Полезные команды:"
echo "• Просмотр логов в реальном времени: tail -f $LOG_FILE"
echo "• Посмотреть собранные адреса: cat $ADDRESSES_FILE"
echo "• Остановить прокси: killall python"