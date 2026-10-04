-- Склейка двух источников. После сборки снежинки staging удаляется.
DROP SCHEMA IF EXISTS clickhouse.staging CASCADE;
DROP SCHEMA IF EXISTS clickhouse.star CASCADE;
CREATE SCHEMA clickhouse.staging;
CREATE SCHEMA clickhouse.star;

CREATE TABLE clickhouse.staging.all_mock (
    load_id bigint NOT NULL,
    id varchar,
    customer_first_name varchar,
    customer_last_name varchar,
    customer_age varchar,
    customer_email varchar,
    customer_country varchar,
    customer_postal_code varchar,
    customer_pet_type varchar,
    customer_pet_name varchar,
    customer_pet_breed varchar,
    seller_first_name varchar,
    seller_last_name varchar,
    seller_email varchar,
    seller_country varchar,
    seller_postal_code varchar,
    product_name varchar,
    product_category varchar,
    product_price varchar,
    product_quantity varchar,
    sale_date varchar,
    sale_customer_id varchar,
    sale_seller_id varchar,
    sale_product_id varchar,
    sale_quantity varchar,
    sale_total_price varchar,
    store_name varchar,
    store_location varchar,
    store_city varchar,
    store_state varchar,
    store_country varchar,
    store_phone varchar,
    store_email varchar,
    pet_category varchar,
    product_weight varchar,
    product_color varchar,
    product_size varchar,
    product_brand varchar,
    product_material varchar,
    product_description varchar,
    product_rating varchar,
    product_reviews varchar,
    product_release_date varchar,
    product_expiry_date varchar,
    supplier_name varchar,
    supplier_contact varchar,
    supplier_email varchar,
    supplier_phone varchar,
    supplier_address varchar,
    supplier_city varchar,
    supplier_country varchar
)
WITH (
    engine = 'MergeTree',
    order_by = ARRAY['load_id']
);

-- типы String совпадают за счёт clickhouse.map-string-as-varchar в каталоге Trino
INSERT INTO clickhouse.staging.all_mock
SELECT row_number() OVER (), src.*
FROM (
    SELECT * FROM postgres.public.mock_data
    UNION ALL
    SELECT * FROM clickhouse.raw.mock_data
) src;

CREATE TABLE clickhouse.star.dim_country (
    country_id bigint NOT NULL,
    country_name varchar NOT NULL
)
WITH (
    engine = 'MergeTree',
    order_by = ARRAY['country_id']
);

INSERT INTO clickhouse.star.dim_country
SELECT row_number() OVER (ORDER BY country_name), country_name
FROM (
    SELECT DISTINCT NULLIF(trim(customer_country), '') AS country_name FROM clickhouse.staging.all_mock
    UNION
    SELECT DISTINCT NULLIF(trim(seller_country), '') FROM clickhouse.staging.all_mock
    UNION
    SELECT DISTINCT NULLIF(trim(store_country), '') FROM clickhouse.staging.all_mock
    UNION
    SELECT DISTINCT NULLIF(trim(supplier_country), '') FROM clickhouse.staging.all_mock
) c
WHERE country_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_pet_type (
    pet_type_id bigint NOT NULL,
    pet_type_name varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['pet_type_id']);

INSERT INTO clickhouse.star.dim_pet_type
SELECT row_number() OVER (ORDER BY pet_type_name), pet_type_name
FROM (
    SELECT DISTINCT NULLIF(trim(customer_pet_type), '') AS pet_type_name
    FROM clickhouse.staging.all_mock
) t
WHERE pet_type_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_pet_breed (
    pet_breed_id bigint NOT NULL,
    breed_name varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['pet_breed_id']);

INSERT INTO clickhouse.star.dim_pet_breed
SELECT row_number() OVER (ORDER BY breed_name), breed_name
FROM (
    SELECT DISTINCT NULLIF(trim(customer_pet_breed), '') AS breed_name
    FROM clickhouse.staging.all_mock
) t
WHERE breed_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_product_category (
    category_id bigint NOT NULL,
    category_name varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['category_id']);

INSERT INTO clickhouse.star.dim_product_category
SELECT row_number() OVER (ORDER BY category_name), category_name
FROM (
    SELECT DISTINCT NULLIF(trim(product_category), '') AS category_name
    FROM clickhouse.staging.all_mock
) t
WHERE category_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_pet_category (
    pet_category_id bigint NOT NULL,
    pet_category_name varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['pet_category_id']);

INSERT INTO clickhouse.star.dim_pet_category
SELECT row_number() OVER (ORDER BY pet_category_name), pet_category_name
FROM (
    SELECT DISTINCT NULLIF(trim(pet_category), '') AS pet_category_name
    FROM clickhouse.staging.all_mock
) t
WHERE pet_category_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_brand (
    brand_id bigint NOT NULL,
    brand_name varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['brand_id']);

INSERT INTO clickhouse.star.dim_brand
SELECT row_number() OVER (ORDER BY brand_name), brand_name
FROM (
    SELECT DISTINCT NULLIF(trim(product_brand), '') AS brand_name
    FROM clickhouse.staging.all_mock
) t
WHERE brand_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_color (
    color_id bigint NOT NULL,
    color_name varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['color_id']);

INSERT INTO clickhouse.star.dim_color
SELECT row_number() OVER (ORDER BY color_name), color_name
FROM (
    SELECT DISTINCT NULLIF(trim(product_color), '') AS color_name
    FROM clickhouse.staging.all_mock
) t
WHERE color_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_size (
    size_id bigint NOT NULL,
    size_name varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['size_id']);

INSERT INTO clickhouse.star.dim_size
SELECT row_number() OVER (ORDER BY size_name), size_name
FROM (
    SELECT DISTINCT NULLIF(trim(product_size), '') AS size_name
    FROM clickhouse.staging.all_mock
) t
WHERE size_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_material (
    material_id bigint NOT NULL,
    material_name varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['material_id']);

INSERT INTO clickhouse.star.dim_material
SELECT row_number() OVER (ORDER BY material_name), material_name
FROM (
    SELECT DISTINCT NULLIF(trim(product_material), '') AS material_name
    FROM clickhouse.staging.all_mock
) t
WHERE material_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_date (
    date_id bigint NOT NULL,
    full_date date NOT NULL,
    year_num integer NOT NULL,
    quarter_num integer NOT NULL,
    month_num integer NOT NULL,
    day_num integer NOT NULL,
    month_name varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['date_id']);

INSERT INTO clickhouse.star.dim_date
SELECT
    row_number() OVER (ORDER BY full_date),
    full_date,
    year(full_date),
    quarter(full_date),
    month(full_date),
    day(full_date),
    date_format(full_date, '%M')
FROM (
    SELECT DISTINCT TRY(CAST(date_parse(trim(sale_date), '%c/%e/%Y') AS date)) AS full_date
    FROM clickhouse.staging.all_mock
) d
WHERE full_date IS NOT NULL;

CREATE TABLE clickhouse.star.dim_city (
    city_id bigint NOT NULL,
    city_name varchar NOT NULL,
    country_id bigint NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['city_id']);

INSERT INTO clickhouse.star.dim_city
SELECT row_number() OVER (ORDER BY x.country_name, x.city_name), x.city_name, c.country_id
FROM (
    SELECT DISTINCT NULLIF(trim(store_city), '') AS city_name, NULLIF(trim(store_country), '') AS country_name
    FROM clickhouse.staging.all_mock
    UNION
    SELECT DISTINCT NULLIF(trim(supplier_city), ''), NULLIF(trim(supplier_country), '')
    FROM clickhouse.staging.all_mock
) x
JOIN clickhouse.star.dim_country c ON c.country_name = x.country_name
WHERE x.city_name IS NOT NULL;

CREATE TABLE clickhouse.star.dim_supplier (
    supplier_id bigint NOT NULL,
    supplier_name varchar,
    contact_name varchar,
    email varchar NOT NULL,
    phone varchar,
    address varchar,
    city_id bigint
)
WITH (engine = 'MergeTree', order_by = ARRAY['supplier_id']);

INSERT INTO clickhouse.star.dim_supplier
SELECT
    row_number() OVER (ORDER BY s.email),
    s.supplier_name,
    s.contact_name,
    s.email,
    s.phone,
    s.address,
    ci.city_id
FROM (
    SELECT
        NULLIF(trim(supplier_name), '') AS supplier_name,
        NULLIF(trim(supplier_contact), '') AS contact_name,
        NULLIF(trim(supplier_email), '') AS email,
        NULLIF(trim(supplier_phone), '') AS phone,
        NULLIF(trim(supplier_address), '') AS address,
        NULLIF(trim(supplier_city), '') AS city_name,
        NULLIF(trim(supplier_country), '') AS country_name,
        row_number() OVER (PARTITION BY NULLIF(trim(supplier_email), '') ORDER BY load_id) AS rn
    FROM clickhouse.staging.all_mock
) s
LEFT JOIN clickhouse.star.dim_country co ON co.country_name = s.country_name
LEFT JOIN clickhouse.star.dim_city ci ON ci.city_name = s.city_name AND ci.country_id = co.country_id
WHERE s.email IS NOT NULL AND s.rn = 1;

CREATE TABLE clickhouse.star.dim_customer (
    customer_id bigint NOT NULL,
    first_name varchar,
    last_name varchar,
    age integer,
    email varchar NOT NULL,
    postal_code varchar,
    country_id bigint,
    pet_type_id bigint,
    pet_breed_id bigint,
    pet_name varchar
)
WITH (engine = 'MergeTree', order_by = ARRAY['customer_id']);

INSERT INTO clickhouse.star.dim_customer
SELECT
    row_number() OVER (ORDER BY c.email),
    c.first_name,
    c.last_name,
    c.age,
    c.email,
    c.postal_code,
    co.country_id,
    pt.pet_type_id,
    pb.pet_breed_id,
    c.pet_name
FROM (
    SELECT
        NULLIF(trim(customer_first_name), '') AS first_name,
        NULLIF(trim(customer_last_name), '') AS last_name,
        TRY(CAST(NULLIF(trim(customer_age), '') AS integer)) AS age,
        NULLIF(trim(customer_email), '') AS email,
        NULLIF(trim(customer_postal_code), '') AS postal_code,
        NULLIF(trim(customer_country), '') AS country_name,
        NULLIF(trim(customer_pet_type), '') AS pet_type_name,
        NULLIF(trim(customer_pet_breed), '') AS breed_name,
        NULLIF(trim(customer_pet_name), '') AS pet_name,
        row_number() OVER (PARTITION BY NULLIF(trim(customer_email), '') ORDER BY load_id) AS rn
    FROM clickhouse.staging.all_mock
) c
LEFT JOIN clickhouse.star.dim_country co ON co.country_name = c.country_name
LEFT JOIN clickhouse.star.dim_pet_type pt ON pt.pet_type_name = c.pet_type_name
LEFT JOIN clickhouse.star.dim_pet_breed pb ON pb.breed_name = c.breed_name
WHERE c.email IS NOT NULL AND c.rn = 1;

CREATE TABLE clickhouse.star.dim_seller (
    seller_id bigint NOT NULL,
    first_name varchar,
    last_name varchar,
    email varchar NOT NULL,
    postal_code varchar,
    country_id bigint
)
WITH (engine = 'MergeTree', order_by = ARRAY['seller_id']);

INSERT INTO clickhouse.star.dim_seller
SELECT
    row_number() OVER (ORDER BY s.email),
    s.first_name,
    s.last_name,
    s.email,
    s.postal_code,
    co.country_id
FROM (
    SELECT
        NULLIF(trim(seller_first_name), '') AS first_name,
        NULLIF(trim(seller_last_name), '') AS last_name,
        NULLIF(trim(seller_email), '') AS email,
        NULLIF(trim(seller_postal_code), '') AS postal_code,
        NULLIF(trim(seller_country), '') AS country_name,
        row_number() OVER (PARTITION BY NULLIF(trim(seller_email), '') ORDER BY load_id) AS rn
    FROM clickhouse.staging.all_mock
) s
LEFT JOIN clickhouse.star.dim_country co ON co.country_name = s.country_name
WHERE s.email IS NOT NULL AND s.rn = 1;

CREATE TABLE clickhouse.star.dim_store (
    store_id bigint NOT NULL,
    store_name varchar,
    location varchar,
    state_name varchar,
    phone varchar,
    email varchar NOT NULL,
    city_id bigint
)
WITH (engine = 'MergeTree', order_by = ARRAY['store_id']);

INSERT INTO clickhouse.star.dim_store
SELECT
    row_number() OVER (ORDER BY s.email),
    s.store_name,
    s.location,
    s.state_name,
    s.phone,
    s.email,
    ci.city_id
FROM (
    SELECT
        NULLIF(trim(store_name), '') AS store_name,
        NULLIF(trim(store_location), '') AS location,
        NULLIF(trim(store_state), '') AS state_name,
        NULLIF(trim(store_phone), '') AS phone,
        NULLIF(trim(store_email), '') AS email,
        NULLIF(trim(store_city), '') AS city_name,
        NULLIF(trim(store_country), '') AS country_name,
        row_number() OVER (PARTITION BY NULLIF(trim(store_email), '') ORDER BY load_id) AS rn
    FROM clickhouse.staging.all_mock
) s
LEFT JOIN clickhouse.star.dim_country co ON co.country_name = s.country_name
LEFT JOIN clickhouse.star.dim_city ci ON ci.city_name = s.city_name AND ci.country_id = co.country_id
WHERE s.email IS NOT NULL AND s.rn = 1;

CREATE TABLE clickhouse.star.dim_product (
    product_id bigint NOT NULL,
    product_name varchar,
    price decimal(12, 2),
    stock_quantity integer,
    weight decimal(12, 2),
    rating decimal(4, 2),
    reviews integer,
    description varchar,
    release_date date,
    expiry_date date,
    category_id bigint,
    pet_category_id bigint,
    brand_id bigint,
    color_id bigint,
    size_id bigint,
    material_id bigint,
    supplier_id bigint,
    product_nk varchar NOT NULL
)
WITH (engine = 'MergeTree', order_by = ARRAY['product_id']);

INSERT INTO clickhouse.star.dim_product
SELECT
    row_number() OVER (ORDER BY p.product_nk),
    p.product_name,
    p.price,
    p.stock_quantity,
    p.weight,
    p.rating,
    p.reviews,
    p.description,
    p.release_date,
    p.expiry_date,
    pc.category_id,
    pet.pet_category_id,
    b.brand_id,
    col.color_id,
    sz.size_id,
    mat.material_id,
    sup.supplier_id,
    p.product_nk
FROM (
    SELECT
        NULLIF(trim(product_name), '') AS product_name,
        TRY(CAST(NULLIF(trim(product_price), '') AS decimal(12, 2))) AS price,
        TRY(CAST(NULLIF(trim(product_quantity), '') AS integer)) AS stock_quantity,
        TRY(CAST(NULLIF(trim(product_weight), '') AS decimal(12, 2))) AS weight,
        TRY(CAST(NULLIF(trim(product_rating), '') AS decimal(4, 2))) AS rating,
        TRY(CAST(NULLIF(trim(product_reviews), '') AS integer)) AS reviews,
        NULLIF(trim(product_description), '') AS description,
        TRY(CAST(date_parse(trim(product_release_date), '%c/%e/%Y') AS date)) AS release_date,
        TRY(CAST(date_parse(trim(product_expiry_date), '%c/%e/%Y') AS date)) AS expiry_date,
        NULLIF(trim(product_category), '') AS category_name,
        NULLIF(trim(pet_category), '') AS pet_category_name,
        NULLIF(trim(product_brand), '') AS brand_name,
        NULLIF(trim(product_color), '') AS color_name,
        NULLIF(trim(product_size), '') AS size_name,
        NULLIF(trim(product_material), '') AS material_name,
        NULLIF(trim(supplier_email), '') AS supplier_email,
        lower(to_hex(md5(to_utf8(concat_ws('|',
            coalesce(NULLIF(trim(product_name), ''), ''),
            coalesce(NULLIF(trim(product_category), ''), ''),
            coalesce(NULLIF(trim(product_price), ''), ''),
            coalesce(NULLIF(trim(product_quantity), ''), ''),
            coalesce(NULLIF(trim(pet_category), ''), ''),
            coalesce(NULLIF(trim(product_weight), ''), ''),
            coalesce(NULLIF(trim(product_color), ''), ''),
            coalesce(NULLIF(trim(product_size), ''), ''),
            coalesce(NULLIF(trim(product_brand), ''), ''),
            coalesce(NULLIF(trim(product_material), ''), ''),
            coalesce(NULLIF(trim(product_description), ''), ''),
            coalesce(NULLIF(trim(product_rating), ''), ''),
            coalesce(NULLIF(trim(product_reviews), ''), ''),
            coalesce(NULLIF(trim(product_release_date), ''), ''),
            coalesce(NULLIF(trim(product_expiry_date), ''), ''),
            coalesce(NULLIF(trim(supplier_email), ''), '')
        ))))) AS product_nk,
        row_number() OVER (
            PARTITION BY lower(to_hex(md5(to_utf8(concat_ws('|',
                coalesce(NULLIF(trim(product_name), ''), ''),
                coalesce(NULLIF(trim(product_category), ''), ''),
                coalesce(NULLIF(trim(product_price), ''), ''),
                coalesce(NULLIF(trim(product_quantity), ''), ''),
                coalesce(NULLIF(trim(pet_category), ''), ''),
                coalesce(NULLIF(trim(product_weight), ''), ''),
                coalesce(NULLIF(trim(product_color), ''), ''),
                coalesce(NULLIF(trim(product_size), ''), ''),
                coalesce(NULLIF(trim(product_brand), ''), ''),
                coalesce(NULLIF(trim(product_material), ''), ''),
                coalesce(NULLIF(trim(product_description), ''), ''),
                coalesce(NULLIF(trim(product_rating), ''), ''),
                coalesce(NULLIF(trim(product_reviews), ''), ''),
                coalesce(NULLIF(trim(product_release_date), ''), ''),
                coalesce(NULLIF(trim(product_expiry_date), ''), ''),
                coalesce(NULLIF(trim(supplier_email), ''), '')
            )))))
            ORDER BY load_id
        ) AS rn
    FROM clickhouse.staging.all_mock
) p
LEFT JOIN clickhouse.star.dim_product_category pc ON pc.category_name = p.category_name
LEFT JOIN clickhouse.star.dim_pet_category pet ON pet.pet_category_name = p.pet_category_name
LEFT JOIN clickhouse.star.dim_brand b ON b.brand_name = p.brand_name
LEFT JOIN clickhouse.star.dim_color col ON col.color_name = p.color_name
LEFT JOIN clickhouse.star.dim_size sz ON sz.size_name = p.size_name
LEFT JOIN clickhouse.star.dim_material mat ON mat.material_name = p.material_name
LEFT JOIN clickhouse.star.dim_supplier sup ON sup.email = p.supplier_email
WHERE p.rn = 1;

CREATE TABLE clickhouse.star.fact_sales (
    sale_id bigint NOT NULL,
    sale_date_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    seller_id bigint NOT NULL,
    product_id bigint NOT NULL,
    store_id bigint NOT NULL,
    sale_quantity integer,
    sale_total_price decimal(14, 2)
)
WITH (engine = 'MergeTree', order_by = ARRAY['sale_id']);

INSERT INTO clickhouse.star.fact_sales
SELECT
    row_number() OVER (ORDER BY m.load_id),
    d.date_id,
    c.customer_id,
    s.seller_id,
    p.product_id,
    st.store_id,
    TRY(CAST(NULLIF(trim(m.sale_quantity), '') AS integer)),
    TRY(CAST(NULLIF(trim(m.sale_total_price), '') AS decimal(14, 2)))
FROM clickhouse.staging.all_mock m
JOIN clickhouse.star.dim_date d
    ON d.full_date = TRY(CAST(date_parse(trim(m.sale_date), '%c/%e/%Y') AS date))
JOIN clickhouse.star.dim_customer c
    ON c.email = NULLIF(trim(m.customer_email), '')
JOIN clickhouse.star.dim_seller s
    ON s.email = NULLIF(trim(m.seller_email), '')
JOIN clickhouse.star.dim_store st
    ON st.email = NULLIF(trim(m.store_email), '')
JOIN clickhouse.star.dim_product p
    ON p.product_nk = lower(to_hex(md5(to_utf8(concat_ws('|',
        coalesce(NULLIF(trim(m.product_name), ''), ''),
        coalesce(NULLIF(trim(m.product_category), ''), ''),
        coalesce(NULLIF(trim(m.product_price), ''), ''),
        coalesce(NULLIF(trim(m.product_quantity), ''), ''),
        coalesce(NULLIF(trim(m.pet_category), ''), ''),
        coalesce(NULLIF(trim(m.product_weight), ''), ''),
        coalesce(NULLIF(trim(m.product_color), ''), ''),
        coalesce(NULLIF(trim(m.product_size), ''), ''),
        coalesce(NULLIF(trim(m.product_brand), ''), ''),
        coalesce(NULLIF(trim(m.product_material), ''), ''),
        coalesce(NULLIF(trim(m.product_description), ''), ''),
        coalesce(NULLIF(trim(m.product_rating), ''), ''),
        coalesce(NULLIF(trim(m.product_reviews), ''), ''),
        coalesce(NULLIF(trim(m.product_release_date), ''), ''),
        coalesce(NULLIF(trim(m.product_expiry_date), ''), ''),
        coalesce(NULLIF(trim(m.supplier_email), ''), '')
    )))));

DROP SCHEMA clickhouse.staging CASCADE;

SELECT count(*) AS fact_rows FROM clickhouse.star.fact_sales;
