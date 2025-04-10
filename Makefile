# Для этого Makefile требуется GNU Make
MAKEFLAGS += --silent

# =================================================================================================
#  Инициализация
# =================================================================================================
# Загрузка переменных окружения из .env файла
ENV_FILE := .env
DOCKER_DIR := .docker

# Проверка существования .env файла
ifneq (,$(wildcard $(ENV_FILE)))
    include $(ENV_FILE)
    export $(shell sed 's/=.*//' $(ENV_FILE) | xargs)
endif

# =================================================================================================
#  Конфигурация
# =================================================================================================
# Значения по умолчанию для переменных окружения
DOCKER_USER				?= sudo
PROJECT_TITLE			?= Symfony App
PROJECT_ABBR			?= app
PROJECT_HOST			?= 127.0.0.1
PROJECT_PORT			?= 8888
PROJECT_CAAS			?= symfony_app
PROJECT_PATH			?= app
SYMFONY_VERSION			?= 7.2.x

# Вычисляемые переменные
CURRENT_DIR				:= $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))
DOCKER_COMPOSE			:= $(DOCKER_USER) docker compose --env-file $(ENV_FILE)
DOCKER_EXEC				:= $(DOCKER_USER) docker exec -it $(PROJECT_CAAS) sh -c

# Цвета для терминала
C_HEAD					:= \033[1;36m
C_BLU					:= \033[0;34m
C_GRN					:= \033[0;32m
C_RED					:= \033[0;31m
C_YEL					:= \033[0;33m
C_END					:= \033[0m

# =================================================================================================
#  Справочная система
# =================================================================================================
.PHONY: help
help: ## Показать справку по командам
	echo "$(C_HEAD)Доступные команды:$(C_END)"
	echo "$(C_BLU)Использование: make [цель]$(C_END)"
	echo
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(C_YEL)%-25s$(C_END) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =================================================================================================
#  Управление окружающей средой
# =================================================================================================
.PHONY: env env-set env-validate

env: ## Отображение текущей конфигурации среды
	printf "$(C_HEAD)Текущая конфигурация среды:$(C_END)\n"
	awk '!/^#/ && !/^$$/ {printf "  $(C_BLU)%-20s$(C_END) %s\n", $$1, $$2}' FS='=' $(ENV_FILE)

env-set: ## Создание шаблона среды
	printf "\
	# =======================================================\n\
	# Конфигурация средства настройки\n\
	# =======================================================\n\
	# Пользователь Docker (sudo, если требуется)\n\
	DOCKER_USER=\"%s\"\n\n\
	# =======================================================\n\
	# Метаданные сервиса\n\
	# =======================================================\n\
	# Отображаемое название проекта\n\
	PROJECT_TITLE=\"%s\"\n\
	# Краткий идентификатор проекта (3-5 букв)\n\
	PROJECT_ABBR=\"%s\"\n\n\
	# =======================================================\n\
	# Краткий идентификатор проекта\n\
	# =======================================================\n\
	# Привязка к хосту (127.0.0.1 или localhost)\n\
	PROJECT_HOST=\"%s\"\n\
	# Сопоставление портов (80-8888)\n\
	PROJECT_PORT=\"%s\"\n\
	# Имя сервиса (строчные буквы со знаками подчеркивания)\n\
	PROJECT_CAAS=\"%s\"\n\
	# Путь к приложению в контейнере (относительно корня проекта)\n\
	PROJECT_PATH=\"%s\"\n\n\
	" \
		"$(DOCKER_USER)" \
		"$(PROJECT_TITLE)" \
		"$(PROJECT_ABBR)" \
		"$(PROJECT_HOST)" \
		"$(PROJECT_PORT)" \
		"$(PROJECT_CAAS)" \
		"$(PROJECT_PATH)" \
	| sed 's/^\t\t//' > $(ENV_FILE)
	printf "$(C_GRN)✓ Создан шаблон среды$(C_END)\n"
	printf "$(C_YEL)⚠ Пожалуйста, просмотрите и отредактируйте env-файлы$(C_END)\n"

env-validate: ## Проверка конфигурации среды
	test -s $(ENV_FILE) || (echo "$(C_RED)✗ Отсутствует файл .env$(C_END)"; exit 1)
	printf "$(C_GRN)✓ Допустимая конфигурация среды$(C_END)\n"

# =================================================================================================
#  Управление docker
# =================================================================================================
.PHONY: build up start stop restart clean

build: env-validate ## Формирование сервисов
	$(DOCKER_COMPOSE) -f $(DOCKER_DIR)/docker-compose.yml up --build --no-recreate -d
	printf "$(C_GRN)✓ Контейнеры успешно построены$(C_END)\n"

up: env-validate ## Запуск всех сервисов
	$(DOCKER_COMPOSE) -f $(DOCKER_DIR)/docker-compose.yml up -d
	printf "$(C_GRN)✓ Контейнеры запущены$(C_END)\n"

start: env-validate ## Запуск существующих сервисов
	$(DOCKER_COMPOSE) -f $(DOCKER_DIR)/docker-compose.yml start
	printf "$(C_GRN)✓ Контейнеры перезапущены$(C_END)\n"

stop: ## Остановка запущенных сервисов
	$(DOCKER_COMPOSE) -f $(DOCKER_DIR)/docker-compose.yml stop
	printf "$(C_YEL)⚠ Контейнеры остановлены$(C_END)\n"

restart: stop start ## Перезапуск сервисов

clean: ## Удаление всех сервисов и зависимостей
	$(DOCKER_COMPOSE) -f $(DOCKER_DIR)/docker-compose.yml down -v --rmi local
	printf "$(C_YEL)⚠ Удаленны контейнеры и объемы$(C_END)\n"

# =================================================================================================
#  Управление приложением
# =================================================================================================
.PHONY: app-install app-update app-clean

app-install: env-validate ## Установка приложения Symfony с помощью пакета webapp bundle
	echo "$(C_YEL)▶ Установка каркаса Symfony...$(C_END)"
	$(DOCKER_EXEC) ' \
		composer create-project symfony/skeleton:"$(SYMFONY_VERSION)" skeleton --no-interaction && \
		cd skeleton && \
		composer require webapp --no-interaction && \
		(mv -n * /var/www/html/ || true) && \
		(mv -n .[!.]* /var/www/html/ || true) && \
		cd .. && \
		rm -rf skeleton \
	'
	printf "$(C_GRN)✓ Приложение Symfony успешно установлено с помощью пакета webapp$(C_END)\n"

app-update: env-validate ## Обновление зависимостей
	$(DOCKER_EXEC) "composer update --with-dependencies"
	printf "$(C_GRN)✓ Зависимости обновлены$(C_END)\n"

app-clean: ## Очистка кэша приложения
	$(DOCKER_EXEC) "rm -rf var/cache/*"
	printf "$(C_YEL)⚠ Application cache cleaned$(C_END)\n"

# =================================================================================================
#  Управление услугами
# =================================================================================================
.PHONY: ssh

ssh: env-validate ## Войти в контейнер
	$(DOCKER_USER) docker exec -it $(PROJECT_CAAS) sh