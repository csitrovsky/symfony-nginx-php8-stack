# Symfony + Nginx + PHP 8.3 Docker Stack

[![Docker](https://img.shields.io/badge/Docker-3.0%2B-blue)](https://www.docker.com/)
[![PHP](https://img.shields.io/badge/PHP-8.3-purple)](https://www.php.net/)
[![Symfony](https://img.shields.io/badge/Symfony-6.4%2B-green)](https://symfony.com/)

Готовый шаблон для быстрого старта Symfony-проектов с Docker.  
**Особенности**:

- ⚡ Nginx 1.25 + PHP 8.3-FPM + Alpine Linux
- 📦 Автоматическая установка Symfony через Makefile
- 🔧 Поддержка Xdebug (опционально)
- 🔒 Безопасная конфигурация по умолчанию
- 🐳 Поддержка Redis, MySQL и ClickHouse
- 🔄 Автоперезагрузка кода при разработке

## 📋 Оглавление

- [Быстрый старт](#-быстрый-старт)
- [Управление проектом](#-управление-проектом)
- [Makefile команды](#-makefile-команды)
- [Конфигурация](#-конфигурация)
- [Структура проекта](#-структура-проекта)
- [FAQ](#-faq)
- [Лицензия](#-лицензия)

## 🚀 Быстрый старт

1. **Клонируйте репозиторий**:
    ```bash
    git clone https://github.com/csitrovsky/symfony-nginx-php8-stack.git
    cd symfony-nginx-php8-stack
    ```

2. **Настройте окружение**:
    ```bash
    make env-set
    nano .env  # Редактируйте параметры:
               # PROJECT_PORT, PROJECT_CAAS, PROJECT_PATH
    ```

3. **Инициализация проекта**:
    ```bash
    make build        # Сборка Docker-образов
    make app-install  # Установка Symfony + Webapp Bundle
    ```

4. **Откройте в браузере**:
    - Основное приложение: http://localhost:8888
    - PHP-FPM Status: http://localhost:8888/fpm-status

## 🛠 Управление проектом

```bash
# Сборка и запуск
make build        # Формирование сервисов
make up           # Запуск всех сервисов
make stop         # Остановка запущенных сервисов

# Управление приложением
make app-install  # Установка Symfony
make app-update   # Обновление зависимостей
make app-clean    # Очистка кэша

# Отладка
make ssh          # Войти в контейнер
```

## 🛠 Makefile команды

Полный список команд можно получить выполнив:

```bash
make help
```

Основные цели:

```
env            ## Показ текущих настроек
env-set        ## Формирование основных настроек

build          ## Формирование сервисов
up             ## Запуск всех сервисов
stop           ## Остановка запущенных сервисов

app-install    ## Установка Symfony
app-update     ## Обновление зависимостей

ssh            ## Вход в сервис
```

## ⚙️ Конфигурация

### Основные настройки (.env)

```ini
# =======================================================
# Конфигурация средства настройки
# =======================================================
# Пользователь Docker (sudo, если требуется)
DOCKER_USER = "sudo"

# =======================================================
# Метаданные сервиса
# =======================================================
# Отображаемое название проекта
PROJECT_TITLE = "My Awesome Project"
# Краткий идентификатор проекта (3-5 букв)
PROJECT_ABBR = "app"

# =======================================================
# Краткий идентификатор проекта
# =======================================================
# Привязка к хосту (127.0.0.1 или localhost)
PROJECT_HOST = "127.0.0.1"
# Сопоставление портов (80-8888)
PROJECT_PORT = "8080"
# Имя сервиса (строчные буквы со знаками подчеркивания)
PROJECT_CAAS = "symfony_app"
# Путь к приложению в контейнере (относительно корня проекта)
PROJECT_PATH = "app"
```

### Расширенные настройки

- `docker-compose.yml` - конфигурация сервисов
- `.docker/nginx/` - настройки веб-сервера
- `.docker/php/` - конфигурация PHP-FPM

### Базы данных

Пример настройки в `docker-compose.yml`:

```yaml
services:
    db:
        container_name: ${PROJECT_CAAS}-MySQL
        command: --default-authentication-plugin=mysql_native_password --explicit_defaults_for_timestamp=1
        environment:
            MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
            MYSQL_DATABASE: ${MYSQL_DATABASE}
            MYSQL_USER: ${MYSQL_USER}
            MYSQL_PASSWORD: ${MYSQL_PASSWORD}
            MYSQL_ROOT_HOST: ${MYSQL_ROOT_HOST}
        expose:
            - ${MYSQL_HOST_PORT}
        image: mysql/mysql-server:${MYSQL_VERSION}
        networks:
            - default
            - database
        platform: linux/amd64
        restart: always
        tty: true
        ports:
            - ${MYSQL_HOST_PORT}:3306
```

## 🗂 Структура проекта

```
├── .docker/
│   ├── nginx/             # Конфиги Nginx
│   ├── php/               # Конфиги PHP-FPM
│   ├── docker-compose.yml # Конфигурация Docker
├── app/                   # Исходный код
├── .env.example           # Шаблон конфигурации
└── Makefile               # Управление проектом
```

## 🔒 Безопасность

- Все сервисы работают от непривилегированного пользователя
- Автоматическое обновление зависимостей
- Защита от XSS и CSRF по умолчанию

## ❓ FAQ

**Q: Как добавить новую зависимость?**  
A: Используйте внутри контейнера:

```bash
make ssh
composer require package-name
```

**Q: Как настроить HTTPS?**  
A: Раскомментируйте SSL-секцию в `nginx.conf` и добавьте сертификаты.

## 📜 Лицензия

MIT License. Подробнее в [LICENSE](LICENSE).