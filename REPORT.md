# Отчёт по лабораторной работе №4 (BigDataTrino)

Работа выполнена студентом МАИ группы М8О-205СВ-25 Рудневым Виктором Владимировичем.

## Цель

Собрать ETL на Trino: первые пять CSV лежат в ClickHouse, следующие пять в PostgreSQL. Trino объединяет их и пишет модель «снежинка» в ClickHouse, затем шесть витрин.

## Шаги

1. `docker-compose.yml`: PostgreSQL 16, ClickHouse 24.8, Trino 455.
2. При старте ClickHouse (`sql/init-ch/load.sh`) в `raw.mock_data` грузятся `MOCK_DATA.csv` и файлы `(1)`–`(4)`, 5000 строк. Postgres (`sql/init-pg/00_mock_data.sql`) получает файлы `(5)`–`(9)`, тоже 5000.
3. Каталоги Trino (`postgres`, `clickhouse`) пишутся при старте контейнера из `.env`, в репозиторий файлы с паролями не попадают.
4. `sql/trino/01_star.sql` склеивает оба источника во временную `staging.all_mock`, собирает схему `star` и удаляет staging.
5. `sql/trino/02_reports.sql` пишет шесть таблиц в базу `reports`.
6. Проверил объёмы и те же срезы, что в прошлых работах.

## Обоснование

Модель та же, что в первой работе. Факт — продажа (`sale_quantity`, `sale_total_price`) со ссылками на дату, покупателя, продавца, товар и магазин. Страна и город отдельно, у товара отдельно категория, бренд, цвет, размер, материал и поставщик.

`id` и `sale_*_id` из CSV не брал: в каждом файле они с 1 по 1000 и относятся к разным строкам. Покупатель, продавец, магазин и поставщик определяются по email, товар — по `product_nk` (md5 атрибутов и email поставщика). Сумму чека не пересчитывал из цены и количества: в исходнике они не сходятся.

В ClickHouse нет внешних ключей, связи только по id. Staging нужен, чтобы не гонять `UNION` в каждом измерении; после загрузки схемы он удаляется. Исходные `mock_data` остаются.

У коннектора ClickHouse тип String без `clickhouse.map-string-as-varchar` приходит в Trino как varbinary, и `UNION` с varchar из Postgres не сходится. Флаг включён в каталоге.

Витрина — одна таблица на отчёт:

- `report_products` и `report_quality` — по варианту товара;
- `report_customers` — по покупателю;
- `report_time` — по году и месяцу;
- `report_stores` — по магазину;
- `report_suppliers` — по поставщику, средняя цена взята по его товарам, не по чеку.

Почти у каждого варианта товара одна продажа, поэтому топ по `sales_cnt` внутри варианта ничего не даёт. Имеет смысл группировать `report_products` по `product_name`. Корреляция рейтинга и числа продаж по варианту не считается: `sales_cnt` везде 1.

## Конфигурация

Параметры в `.env`. В git его нет, есть `.env_example`.

```bash
copy .env_example .env
```

| Переменная | Зачем |
|------------|--------|
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | доступ к Postgres |
| `POSTGRES_HOST`, `POSTGRES_INTERNAL_PORT` | адрес Postgres из Trino (`postgres` / `5432`) |
| `POSTGRES_PORT` | порт на хосте, в шаблоне `5435` |
| `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD`, `CLICKHOUSE_DB` | доступ к ClickHouse, база исходных данных `raw` |
| `CLICKHOUSE_HOST`, `CLICKHOUSE_INTERNAL_PORT` | адрес ClickHouse из Trino (`clickhouse` / `8123`) |
| `CLICKHOUSE_HTTP_PORT`, `CLICKHOUSE_NATIVE_PORT` | порты на хосте, в шаблоне `8124` и `9001` |
| `TRINO_PORT` | Trino UI и CLI на хосте, в шаблоне `8082` |

В шаблоне пароли локальные: Postgres `postgres`/`postgres`, база `pet_store`; ClickHouse пользователь `default`, пароль `clickhouse`.

Запуск из каталога `BigDataTrino`:

```bash
docker compose up -d --build
docker exec bdtrino-trino trino --file /sql/01_star.sql
docker exec bdtrino-trino trino --file /sql/02_reports.sql
```

Повторный прогон SQL пересоздаёт `star` и `reports`. Исходные таблицы при этом не трогаются. С нуля вместе с томами: `docker compose down -v && docker compose up -d --build`, затем те же две команды `trino`. Скрипты инициализации ClickHouse и Postgres выполняются только на пустом томе.

## Результат

Источники: Postgres `public.mock_data` — 5000, ClickHouse `raw.mock_data` — 5000. Строка из `MOCK_DATA.csv` (email `bmassingham0@army.mil`) лежит в ClickHouse, в Postgres её нет.

ClickHouse, схема `star`:

| Таблица | Строк |
|---------|------:|
| fact_sales | 10000 |
| dim_customer | 10000 |
| dim_seller | 10000 |
| dim_store | 10000 |
| dim_supplier | 10000 |
| dim_product | 10000 |
| dim_country | 230 |
| dim_city | 19434 |
| dim_date | 364 |

ClickHouse, база `reports`:

| Таблица | Строк |
|---------|------:|
| report_products | 10000 |
| report_customers | 10000 |
| report_stores | 10000 |
| report_suppliers | 10000 |
| report_quality | 10000 |
| report_time | 12 |

Выручка по категории товара: Toy 868101.63 (3406), Cage 831117.94 (3327), Food 830632.55 (3267).

По названию товара: Bird Cage 3352 продажи / 847478.05, Dog Food 3339 / 848567.19, Cat Toy 3309 / 833806.88.

Покупатели: больше всего из China (1738), дальше Indonesia (1174), Russia (628), Philippines (555), Brazil (385).

Все продажи за 2021 год, выручка 2529852.12, средний чек 252.98. По месяцам чек держится около 246–262, максимум заказов в августе (897) и октябре (892).

Рейтинг товаров в витрине качества от 1 до 5.
