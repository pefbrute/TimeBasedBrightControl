#!/bin/bash

# Получаем текущий час и минуты (убираем ведущие нули)
current_hour=$(date +%-H)
current_minute=$(date +%-M)

# Добавляем отладочный вывод
echo "Текущее время: $current_hour:$current_minute"

# Функция для расчета яркости
calculate_brightness() {
    # Если время между 17:00 и 23:59
    if [ $current_hour -ge 17 ] && [ $current_hour -lt 24 ]; then
        # Общее количество минут от 17:00 до 24:00
        local total_minutes_decrease=420  # 7 часов * 60 минут
        
        # Текущее количество минут от 17:00
        local minutes_since_17=$(( (current_hour - 17) * 60 + current_minute ))
        
        # Линейная интерполяция от 100% до 2%
        # Формула: 100 - (minutes_since_17 / total_minutes_decrease) * (100 - 2)
        local brightness=$(( 100 - (minutes_since_17 * 98 / total_minutes_decrease) ))
        
        # Выводим отладочную информацию в stderr
        echo "Время $current_hour:$current_minute. Уменьшение яркости." >&2
        echo "Минут после 17:00: $minutes_since_17" >&2
        echo "Расчетная яркость: $brightness%" >&2
        
        # Ограничиваем минимальную яркость до 2%
        if [ $brightness -lt 2 ]; then
            brightness=2
        fi
        
        # Возвращаем только числовое значение
        echo $brightness
    # Если время между 00:00 и 06:59
    elif [ $current_hour -lt 7 ]; then
        echo "Время $current_hour:$current_minute. Минимальная яркость." >&2
        echo 2
    # Если время между 07:00 и 08:59
    elif [ $current_hour -ge 7 ] && [ $current_hour -lt 9 ]; then
        # Общее количество минут от 07:00 до 09:00
        local total_minutes_increase=120 # 2 часа * 60 минут
        
        # Текущее количество минут от 07:00
        local minutes_since_7=$(( (current_hour - 7) * 60 + current_minute ))
        
        # Линейная интерполяция от 2% до 100%
        # Формула: 2 + (minutes_since_7 / total_minutes_increase) * (100 - 2)
        local brightness=$(( 2 + (minutes_since_7 * 98 / total_minutes_increase) ))
        
        # Выводим отладочную информацию в stderr
        echo "Время $current_hour:$current_minute. Увеличение яркости." >&2
        echo "Минут после 07:00: $minutes_since_7" >&2
        echo "Расчетная яркость: $brightness%" >&2
        
        # Ограничиваем максимальную яркость до 100% (на всякий случай)
        if [ $brightness -gt 100 ]; then
            brightness=100
        fi
        
        # Возвращаем только числовое значение
        echo $brightness
    # Иначе (время между 09:00 и 16:59)
    else
        echo "Время $current_hour:$current_minute. Максимальная яркость." >&2
        echo 100
    fi
}

# Получаем расчетную яркость (только число)
brightness=$(calculate_brightness)

# Добавляем отладочный вывод
echo "Итоговая яркость: $brightness"

# Если яркость определена, устанавливаем её
if [ ! -z "$brightness" ]; then
    echo "Устанавливаем яркость: $brightness%"
    sudo brightnessctl set "$brightness%"
else
    echo "Яркость не определена (ошибка в расчетах)"
fi