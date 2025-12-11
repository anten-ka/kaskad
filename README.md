# Kaskad Traffic Manager

**Универсальный скрипт для настройки каскадных соединений, переадресации трафика (NAT) и ускорения сети на Linux.**

Решение от канала **anten-ka** для создания "мостов" к VPN (AmneziaWG, WireGuard) и Proxy (VLESS, XRay).

![Bash](https://img.shields.io/badge/Language-Bash-green)
![System](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Возможности

✓ **High Speed Core:** Работает через **Iptables (Kernel NAT)**. Никаких лишних процессов, скорость ограничена только пропускной способностью канала.
✓ **BBR Turbo:** Автоматически включает алгоритм **Google BBR** для оптимизации TCP соединений.
✓ **Мультипротокольность:** Поддержка UDP (AmneziaWG, WireGuard) и TCP (VLESS, VMess, Reality).
✓ **Мульти-туннелирование:** Создание неограниченного количества соединений на разных портах.
✓ **Автоматизация:** Настройка UFW, отключение `rp_filter`, сохранение правил после перезагрузки (`netfilter-persistent`).
✓ **Удобное меню:** Просмотр списка правил, точечное удаление, полный сброс.

---

## Установка и запуск

Подключитесь к вашему VPS (Ubuntu/Debian) под `root` и выполните команду:

```bash
wget -O install.sh [https://raw.githubusercontent.com/anten-ka/kaskad/main/install.sh](https://raw.githubusercontent.com/anten-ka/kaskad/main/install.sh) && chmod +x install.sh && ./install.sh

Полезные ссылки и инструкцииВся информация по настройке и использованию доступна на ресурсах канала anten-ka:YouTube канал: https://www.youtube.com/@antenkaruИнструкции (Boosty): https://boosty.to/anten-kaВсе ссылки (Taplink): https://antenka.taplink.wsПоддержка (Tribute): https://web.tribute.tg/p/cJuПоддержать автора донатом: CloudTips (pay.cloudtips.ru)Партнеры и ПромокодыХостинг, который мы рекомендуем для создания каскадов (работает со скидкой до 60%):Ссылка для регистрации: https://vk.cc/ct29NQПромокодОписание бонусаOFF6060% скидка на первый месяц арендыantenka20Буст +20% к балансу (+3% при оплате за 3 мес)antenka6Буст +15% к балансу (+5% при оплате за 6 мес)antenka12Буст +5% к балансу (+5% при оплате за 12 мес)Как использовать скриптПосле запуска появится интерактивное меню:Настроить AmneziaWG / UDPВведите IP зарубежного сервера и Порт (например, 34666).Скрипт настроит переадресацию: Ваш_VPS:34666 -> Зарубеж_VPS:34666.Настроить VLESS / TCPАналогичная настройка для TCP протоколов (например, порт 443).Посмотреть активные правилаВыводит таблицу всех текущих туннелей.Управление правиламиВозможность удалить конкретный туннель (по номеру) или сбросить все настройки.Системные требованияОС: Ubuntu 20.04+, Debian 10+Права: RootВиртуализация: KVM (рекомендуется). На LXC/OpenVZ убедитесь, что модули iptables/nat доступны на хосте.
