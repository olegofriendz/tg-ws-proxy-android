#!/bin/bash

PORT=1080
LOG_FILE="proxy.log"

echo "Запуск прокси на порту $PORT..."
killall python 2>/dev/null
nohup python proxy/tg_ws_proxy.py --port $PORT --verbose > $LOG_FILE 2>&1 &

echo "Прокси запущен (PID: $!)"
echo "Логи: $LOG_FILE"
echo ""
echo "Открой Telegram и загрузи несколько видео/картинок"
echo ""
echo "Когда закончишь — запусти:"
echo "./collect_addresses.sh"
echo ""
echo "Остановить прокси: killall python"