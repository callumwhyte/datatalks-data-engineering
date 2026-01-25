# SQL Beginner’s Guide (PostgreSQL‑friendly)

> **Who this is for:** You’re new to SQL and want a practical, plain‑English guide with lots of examples.
>
> **What you’ll learn:** Reading and writing common queries (SELECT/WHERE/JOIN/GROUP BY), modifying data (INSERT/UPDATE/DELETE), defining tables (CREATE), and useful extras (CTEs, window functions, indexes, and tips).

---

## 1) What is SQL?
**SQL (Structured Query Language)** lets you ask questions of data stored in **relational databases** (like PostgreSQL, MySQL, SQL Server). You write declarative statements such as:

- **Retrieve** data → `SELECT … FROM …`  
- **Filter** rows → `WHERE …`  
- **Sort** results → `ORDER BY …`  
- **Group**/summarise → `GROUP BY …`  
- **Join** tables → `JOIN … ON …`  
- **Add** data → `INSERT`  
- **Change** data → `UPDATE`  
- **Remove** data → `DELETE`  
- **Define** tables → `CREATE TABLE …`

> This guide uses **PostgreSQL** examples (works with small tweaks in most databases).

---

## 2) A tiny sample schema
We’ll imagine two tables:

```sql
-- Trips table (NYC taxi‑style)
CREATE TABLE yellow_taxi_trips (
  trip_id             SERIAL PRIMARY KEY,  -- unique row identifier
  tpep_pickup_datetime   TIMESTAMP NOT NULL,
  tpep_dropoff_datetime  TIMESTAMP NOT NULL,
  pu_location_id         INT,              -- pickup zone id
  do_location_id         INT,              -- dropoff zone id
  passenger_count        INT,
  trip_distance          NUMERIC(6,2),     -- e.g., 12.35 miles
  total_amount           NUMERIC(8,2)
);

-- Zones lookup table
CREATE TABLE zones (
  location_id  INT PRIMARY KEY,
  borough      TEXT,
  zone         TEXT
);
```

Populate a couple of rows:
```sql
INSERT INTO zones (location_id, borough, zone) VALUES
  (1, 'Manhattan', 'Upper East Side'),
  (2, 'Queens',    'JFK Airport');

INSERT INTO yellow_taxi_trips (
  tpep_pickup_datetime, tpep_dropoff_datetime, pu_location_id, do_location_id,
  passenger_count, trip_distance, total_amount
) VALUES
  ('2023-01-10 08:05', '2023-01-10 08:28', 1, 2, 1, 16.4, 52.10),
  ('2023-01-10 09:12', '2023-01-10 09:25', 1, 1, 2, 2.3, 12.50);
```

---

## 3) Selecting columns and rows
```sql
-- Select specific columns
SELECT
  tpep_pickup_datetime,
  tpep_dropoff_datetime,
  total_amount
FROM yellow_taxi_trips;

-- Limit how many rows you see (handy during exploration)
SELECT *
FROM yellow_taxi_trips
LIMIT 5;  -- show first 5 rows
```

### Filtering with WHERE
```sql
-- Comparison operators: =, !=, <, <=, >, >=
SELECT *
FROM yellow_taxi_trips
WHERE total_amount > 20;

-- Range / membership
SELECT * FROM yellow_taxi_trips WHERE total_amount BETWEEN 10 AND 20;
SELECT * FROM yellow_taxi_trips WHERE passenger_count IN (1, 2, 3);

-- Pattern matching (Postgres: ILIKE = case‑insensitive)
SELECT * FROM zones WHERE borough ILIKE 'man%';  -- starts with "man"

-- NULL checks (very important: NULL means unknown)
SELECT * FROM yellow_taxi_trips WHERE passenger_count IS NULL;  -- not = NULL
SELECT * FROM yellow_taxi_trips WHERE passenger_count IS NOT NULL;
```

### Sorting and paging
```sql
SELECT trip_id, total_amount
FROM yellow_taxi_trips
WHERE total_amount > 10
ORDER BY total_amount DESC  -- largest first
LIMIT 10
OFFSET 20;  -- skip first 20 rows (for pagination)
```

---

## 4) Aliases, expressions, and CASE
```sql
-- Aliases rename columns or tables to make results clearer
SELECT
  total_amount AS fare,
  trip_distance AS miles
FROM yellow_taxi_trips;

-- Calculated columns and built‑in functions
SELECT
  trip_id,
  total_amount,
  total_amount * 0.2 AS twenty_percent
FROM yellow_taxi_trips;

-- IF/ELSE logic with CASE
SELECT
  trip_id,
  passenger_count,
  CASE
    WHEN passenger_count IS NULL THEN 'unknown'
    WHEN passenger_count = 1 THEN 'solo'
    WHEN passenger_count BETWEEN 2 AND 4 THEN 'group'
    ELSE 'large group'
  END AS pax_category
FROM yellow_taxi_trips;
```

> Tip: In PostgreSQL, **double quotes** preserve case in identifiers (e.g., "ColumnName"). Prefer **lowercase_with_underscores** to avoid quoting.

---

## 5) JOINs (combining tables)
Use **JOIN** to bring related data together.

```sql
-- INNER JOIN: only rows that match in both tables
SELECT
  t.trip_id,
  t.total_amount,
  CONCAT(zpu.borough, ' | ', zpu.zone) AS pickup_loc,
  CONCAT(zdo.borough, ' | ', zdo.zone) AS dropoff_loc
FROM yellow_taxi_trips AS t
JOIN zones AS zpu ON t.pu_location_id = zpu.location_id
JOIN zones AS zdo ON t.do_location_id = zdo.location_id;

-- LEFT JOIN: keep all left rows, even if no match on the right
SELECT t.trip_id, zpu.zone
FROM yellow_taxi_trips t
LEFT JOIN zones zpu ON t.pu_location_id = zpu.location_id;
```

**Join types in one glance**
- `INNER JOIN` → matching pairs only.
- `LEFT JOIN` → all left rows + matching right rows (NULLs when no match).
- `RIGHT JOIN` → all right rows + matching left rows.
- `FULL JOIN` → everything from both, with NULLs where unmatched.
- `CROSS JOIN` → every combination (use sparingly).

---

## 6) Aggregations and GROUP BY
```sql
-- Aggregate functions: COUNT, SUM, AVG, MIN, MAX
SELECT
  COUNT(*)            AS trips,
  SUM(total_amount)   AS total_revenue,
  AVG(total_amount)   AS avg_fare
FROM yellow_taxi_trips;

-- Group by a category
SELECT
  zpu.borough,
  COUNT(*)          AS trips,
  ROUND(AVG(total_amount), 2) AS avg_fare
FROM yellow_taxi_trips t
JOIN zones zpu ON t.pu_location_id = zpu.location_id
GROUP BY zpu.borough
ORDER BY trips DESC;

-- Filter groups with HAVING (applies after grouping)
SELECT zpu.borough, COUNT(*) AS trips
FROM yellow_taxi_trips t
JOIN zones zpu ON t.pu_location_id = zpu.location_id
GROUP BY zpu.borough
HAVING COUNT(*) > 100;  -- only boroughs with more than 100 trips
```

> Rule of thumb: Every selected column must be either **aggregated** or appear in the **GROUP BY**.

---

## 7) Subqueries and CTEs (WITH)
```sql
-- Subquery in FROM
SELECT borough, avg_fare
FROM (
  SELECT zpu.borough, AVG(total_amount) AS avg_fare
  FROM yellow_taxi_trips t
  JOIN zones zpu ON t.pu_location_id = zpu.location_id
  GROUP BY zpu.borough
) s
WHERE avg_fare > 20;

-- CTE: name a subquery and reuse it
WITH borough_stats AS (
  SELECT zpu.borough, AVG(total_amount) AS avg_fare, COUNT(*) AS trips
  FROM yellow_taxi_trips t
  JOIN zones zpu ON t.pu_location_id = zpu.location_id
  GROUP BY zpu.borough
)
SELECT *
FROM borough_stats
WHERE trips > 100
ORDER BY avg_fare DESC;
```

---

## 8) Modifying data (DML)
```sql
-- INSERT rows
INSERT INTO zones (location_id, borough, zone)
VALUES (3, 'Brooklyn', 'Williamsburg');

-- UPDATE rows
UPDATE yellow_taxi_trips
SET total_amount = total_amount * 1.05  -- add 5%
WHERE trip_distance > 10;

-- DELETE rows (be careful!)
DELETE FROM yellow_taxi_trips
WHERE total_amount = 0;

-- Transactions: group changes atomically
BEGIN;
  UPDATE yellow_taxi_trips SET total_amount = total_amount + 2 WHERE total_amount < 10;
  DELETE FROM yellow_taxi_trips WHERE total_amount < 0;  -- sanity clean
COMMIT;  -- or ROLLBACK to undo
```

---

## 9) Defining tables and constraints (DDL)
```sql
-- Create a table with constraints
CREATE TABLE payments (
  payment_id   SERIAL PRIMARY KEY,
  trip_id      INT NOT NULL REFERENCES yellow_taxi_trips(trip_id),
  method       TEXT CHECK (method IN ('card','cash','other')),
  amount       NUMERIC(8,2) CHECK (amount >= 0),
  paid_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add / remove columns
ALTER TABLE yellow_taxi_trips ADD COLUMN tip_amount NUMERIC(6,2) DEFAULT 0;
ALTER TABLE yellow_taxi_trips DROP COLUMN tip_amount;

-- Drop a table
DROP TABLE payments;
```

**Common constraints**
- `PRIMARY KEY` – unique, non‑NULL identifier.
- `FOREIGN KEY` – references a key in another table; keeps relationships valid.
- `UNIQUE` – no duplicates allowed.
- `NOT NULL` – value must be provided.
- `CHECK` – custom rule (e.g., `amount >= 0`).

---

## 10) Indexes (speeding up queries)
Indexes help the database find rows faster, at the cost of extra write overhead and storage.

```sql
-- Create an index to speed lookups by pu_location_id
CREATE INDEX idx_trips_pu_location ON yellow_taxi_trips (pu_location_id);

-- Multi‑column index example
CREATE INDEX idx_trips_pu_pickup_time ON yellow_taxi_trips (pu_location_id, tpep_pickup_datetime);
```

> Use `EXPLAIN ANALYZE your_query;` to see how PostgreSQL executes a query and whether indexes are used.

---

## 11) Views and materialized views
```sql
-- Simple (virtual) view: always reflects current data
CREATE VIEW borough_fares AS
SELECT zpu.borough, AVG(total_amount) AS avg_fare
FROM yellow_taxi_trips t
JOIN zones zpu ON t.pu_location_id = zpu.location_id
GROUP BY zpu.borough;

-- Materialized view: stores results (refresh when needed)
CREATE MATERIALIZED VIEW borough_fares_mv AS
SELECT zpu.borough, AVG(total_amount) AS avg_fare
FROM yellow_taxi_trips t
JOIN zones zpu ON t.pu_location_id = zpu.location_id
GROUP BY zpu.borough;

-- Refresh a materialized view after data changes
REFRESH MATERIALIZED VIEW borough_fares_mv;
```

---

## 12) Window functions (powerful analytics)
Compute values **across** rows, without collapsing them like GROUP BY.

```sql
-- Rank trips by fare within each pickup borough
SELECT
  t.trip_id,
  zpu.borough,
  t.total_amount,
  RANK() OVER (PARTITION BY zpu.borough ORDER BY t.total_amount DESC) AS fare_rank
FROM yellow_taxi_trips t
JOIN zones zpu ON t.pu_location_id = zpu.location_id
ORDER BY zpu.borough, fare_rank;

-- Running total by pickup borough
SELECT
  zpu.borough,
  t.tpep_pickup_datetime,
  t.total_amount,
  SUM(t.total_amount) OVER (
    PARTITION BY zpu.borough
    ORDER BY t.tpep_pickup_datetime
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_revenue
FROM yellow_taxi_trips t
JOIN zones zpu ON t.pu_location_id = zpu.location_id;
```

---

## 13) Common pitfalls & pro tips
- **NULL logic**: `= NULL` is always false; use `IS NULL`/`IS NOT NULL`.
- **Implicit joins**: Prefer explicit `JOIN ... ON ...` over `FROM a, b WHERE ...`.
- **Integer division**: In some DBs, `1/2 = 0`. Cast to numeric: `1::numeric / 2`.
- **Quoting**: Avoid mixed‑case identifiers that force you to write "ThisColumn".
- **Small steps**: Build queries incrementally—`SELECT ... LIMIT 5` first, then add filters/joins.
- **Performance**: Add indexes for frequent filters/joins; verify with `EXPLAIN ANALYZE`.

---

## 14) Practice exercises
1) Show the **top 5 most expensive** trips and their pickup/dropoff zone names.  
2) Count how many trips started in each **borough**, sorted by most to least.  
3) What’s the **average fare by hour of day** (0–23)?  
4) Using a window function, rank trips by `trip_distance` within each pickup **borough**.  
5) Add a new zone and update some trips to use it; then **DELETE** those trips (wrap in a **transaction** and roll back).

---

## 15) Quick cheat sheet
```sql
-- Basic skeleton
SELECT col1, col2
FROM table_name
WHERE condition
GROUP BY col1
HAVING aggregate_condition
ORDER BY col1 DESC
LIMIT 10 OFFSET 0;

-- Joins
FROM a
JOIN b ON a.id = b.a_id
LEFT JOIN c ON a.id = c.a_id

-- Aggregates
COUNT(*), SUM(x), AVG(x), MIN(x), MAX(x)

-- Predicates
=, !=, <, <=, >, >=, BETWEEN, IN (...), LIKE/ILIKE, IS NULL/IS NOT NULL

-- Case
CASE WHEN cond THEN x ELSE y END
```

---

### Next steps
- Try queries on a real dataset (your NYC taxi tables are perfect).
- Practice reading `EXPLAIN ANALYZE` output.
- Explore more Postgres features: JSON/JSONB, full‑text search, and PostGIS (geospatial).

If you get stuck on any query, paste it and what you expect—happy to explain line by line.
