DROP SCHEMA IF EXISTS clickhouse.reports CASCADE;
CREATE SCHEMA clickhouse.reports;

CREATE TABLE clickhouse.reports.report_products (
    product_name varchar NOT NULL,
    category_name varchar NOT NULL,
    brand_name varchar NOT NULL,
    revenue decimal(18, 2),
    sales_cnt bigint NOT NULL,
    qty_sum bigint,
    rating double,
    reviews integer
)
WITH (
    engine = 'MergeTree',
    order_by = ARRAY['category_name', 'product_name', 'brand_name']
);

INSERT INTO clickhouse.reports.report_products
SELECT
    coalesce(p.product_name, ''),
    coalesce(pc.category_name, ''),
    coalesce(b.brand_name, ''),
    cast(sum(f.sale_total_price) AS decimal(18, 2)),
    count(*),
    sum(f.sale_quantity),
    avg(cast(p.rating AS double)),
    max(p.reviews)
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_product p ON p.product_id = f.product_id
LEFT JOIN clickhouse.star.dim_product_category pc ON pc.category_id = p.category_id
LEFT JOIN clickhouse.star.dim_brand b ON b.brand_id = p.brand_id
GROUP BY 1, 2, 3, p.product_id, p.rating, p.reviews;

CREATE TABLE clickhouse.reports.report_customers (
    first_name varchar NOT NULL,
    last_name varchar NOT NULL,
    email varchar NOT NULL,
    country_name varchar NOT NULL,
    total_sum decimal(18, 2),
    orders_cnt bigint NOT NULL,
    avg_check decimal(18, 2)
)
WITH (
    engine = 'MergeTree',
    order_by = ARRAY['country_name', 'email']
);

INSERT INTO clickhouse.reports.report_customers
SELECT
    coalesce(c.first_name, ''),
    coalesce(c.last_name, ''),
    c.email,
    coalesce(co.country_name, ''),
    cast(sum(f.sale_total_price) AS decimal(18, 2)),
    count(*),
    cast(avg(f.sale_total_price) AS decimal(18, 2))
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_customer c ON c.customer_id = f.customer_id
LEFT JOIN clickhouse.star.dim_country co ON co.country_id = c.country_id
GROUP BY 1, 2, 3, 4;

CREATE TABLE clickhouse.reports.report_time (
    year_num integer NOT NULL,
    month_num integer NOT NULL,
    month_name varchar NOT NULL,
    revenue decimal(18, 2),
    orders_cnt bigint NOT NULL,
    avg_check decimal(18, 2)
)
WITH (
    engine = 'MergeTree',
    order_by = ARRAY['year_num', 'month_num']
);

INSERT INTO clickhouse.reports.report_time
SELECT
    d.year_num,
    d.month_num,
    trim(d.month_name),
    cast(sum(f.sale_total_price) AS decimal(18, 2)),
    count(*),
    cast(avg(f.sale_total_price) AS decimal(18, 2))
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_date d ON d.date_id = f.sale_date_id
GROUP BY 1, 2, 3;

CREATE TABLE clickhouse.reports.report_stores (
    store_name varchar NOT NULL,
    city_name varchar NOT NULL,
    country_name varchar NOT NULL,
    revenue decimal(18, 2),
    orders_cnt bigint NOT NULL,
    avg_check decimal(18, 2)
)
WITH (
    engine = 'MergeTree',
    order_by = ARRAY['country_name', 'city_name', 'store_name']
);

INSERT INTO clickhouse.reports.report_stores
SELECT
    coalesce(st.store_name, ''),
    coalesce(ci.city_name, ''),
    coalesce(co.country_name, ''),
    cast(sum(f.sale_total_price) AS decimal(18, 2)),
    count(*),
    cast(avg(f.sale_total_price) AS decimal(18, 2))
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_store st ON st.store_id = f.store_id
LEFT JOIN clickhouse.star.dim_city ci ON ci.city_id = st.city_id
LEFT JOIN clickhouse.star.dim_country co ON co.country_id = ci.country_id
GROUP BY 1, 2, 3;

CREATE TABLE clickhouse.reports.report_suppliers (
    supplier_name varchar NOT NULL,
    country_name varchar NOT NULL,
    revenue decimal(18, 2),
    avg_price decimal(18, 2),
    sales_cnt bigint NOT NULL
)
WITH (
    engine = 'MergeTree',
    order_by = ARRAY['country_name', 'supplier_name']
);

INSERT INTO clickhouse.reports.report_suppliers
SELECT
    coalesce(s.supplier_name, ''),
    coalesce(co.country_name, ''),
    cast(sales.revenue AS decimal(18, 2)),
    cast(coalesce(prices.avg_price, 0) AS decimal(18, 2)),
    sales.sales_cnt
FROM (
    SELECT p.supplier_id, sum(f.sale_total_price) AS revenue, count(*) AS sales_cnt
    FROM clickhouse.star.fact_sales f
    JOIN clickhouse.star.dim_product p ON p.product_id = f.product_id
    GROUP BY p.supplier_id
) sales
JOIN clickhouse.star.dim_supplier s ON s.supplier_id = sales.supplier_id
LEFT JOIN (
    SELECT supplier_id, avg(price) AS avg_price
    FROM clickhouse.star.dim_product
    GROUP BY supplier_id
) prices ON prices.supplier_id = sales.supplier_id
LEFT JOIN clickhouse.star.dim_city ci ON ci.city_id = s.city_id
LEFT JOIN clickhouse.star.dim_country co ON co.country_id = ci.country_id;

CREATE TABLE clickhouse.reports.report_quality (
    product_name varchar NOT NULL,
    category_name varchar NOT NULL,
    brand_name varchar NOT NULL,
    rating double NOT NULL,
    reviews integer NOT NULL,
    sales_cnt bigint NOT NULL,
    revenue decimal(18, 2)
)
WITH (
    engine = 'MergeTree',
    order_by = ARRAY['rating', 'reviews', 'product_name']
);

INSERT INTO clickhouse.reports.report_quality
SELECT
    coalesce(p.product_name, ''),
    coalesce(pc.category_name, ''),
    coalesce(b.brand_name, ''),
    coalesce(cast(p.rating AS double), 0),
    coalesce(p.reviews, 0),
    count(*),
    cast(sum(f.sale_total_price) AS decimal(18, 2))
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_product p ON p.product_id = f.product_id
LEFT JOIN clickhouse.star.dim_product_category pc ON pc.category_id = p.category_id
LEFT JOIN clickhouse.star.dim_brand b ON b.brand_id = p.brand_id
GROUP BY 1, 2, 3, p.product_id, p.rating, p.reviews;

SELECT 'report_products' AS report_name, count(*) AS rows FROM clickhouse.reports.report_products
UNION ALL
SELECT 'report_customers', count(*) FROM clickhouse.reports.report_customers
UNION ALL
SELECT 'report_time', count(*) FROM clickhouse.reports.report_time
UNION ALL
SELECT 'report_stores', count(*) FROM clickhouse.reports.report_stores
UNION ALL
SELECT 'report_suppliers', count(*) FROM clickhouse.reports.report_suppliers
UNION ALL
SELECT 'report_quality', count(*) FROM clickhouse.reports.report_quality;
