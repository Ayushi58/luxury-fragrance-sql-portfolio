CREATE DATABASE luxury_fragrance;

USE luxury_fragrance;

CREATE TABLE raw_fragrances (
url VARCHAR(500),
perfume_name VARCHAR(260),
brand VARCHAR(260),
country VARCHAR(100),
gender VARCHAR(50),
rating_value DECIMAL(3,2),
rating_count INT,
year INT,
top_notes TEXT,
middle_notes TEXT,
base_notes TEXT,
perfumer1 VARCHAR(260),
perfumer2 VARCHAR(260),
mainaccord1 VARCHAR(100),
mainaccord2 VARCHAR(100),
mainaccord3 VARCHAR(100),
mainaccord4 VARCHAR(100),
mainaccord5 VARCHAR(100)
);

-- Temporarily modified rating_value to text, since original data used commas instead of points for decimal
ALTER TABLE raw_fragrances MODIFY rating_value VARCHAR(20);

-- Replace commas with points to fix number format
UPDATE raw_fragrances
SET rating_value = REPLACE(rating_value, ',', '.');

-- Convert rating_value back to decimal
ALTER TABLE raw_fragrances MODIFY rating_value DECIMAL(3,2);

SELECT COUNT(*) FROM raw_fragrances;
SELECT * FROM raw_fragrances LIMIT 5;

CREATE TABLE brands(
brand_id INT auto_increment PRIMARY KEY,
brand_name VARCHAR(260) UNIQUE,
country VARCHAR(100)
);

CREATE TABLE perfumes(
perfume_id INT auto_increment PRIMARY KEY,
perfume_name VARCHAR(260),
brand_id INT,
gender VARCHAR(50),
rating_value DECIMAL(3,2),
rating_count INT,
year INT,
url VARCHAR(500),
FOREIGN KEY(brand_id) REFERENCES brands(brand_id)
);

CREATE TABLE perfumers(
perfumer_id INT auto_increment PRIMARY KEY,
perfumer_name VARCHAR(260) UNIQUE
);

-- Linking tables to connect each perfume to its perfumer(s)
CREATE TABLE perfume_perfumers(
perfume_id INT,
perfumer_id INT,
FOREIGN KEY(perfume_id) REFERENCES perfumes(perfume_id),
FOREIGN KEY(perfumer_id) REFERENCES perfumers(perfumer_id)
);

CREATE TABLE notes(
note_id INT auto_increment PRIMARY KEY,
note_name VARCHAR(260) UNIQUE
);

-- Linking tables to connect each perfume to its individual notes
CREATE TABLE perfume_notes(
perfume_id INT,
note_id INT,
note_type VARCHAR(20),
PRIMARY KEY (perfume_id, note_id, note_type),
FOREIGN KEY (perfume_id ) REFERENCES perfumes(perfume_id ),
FOREIGN KEY (note_id ) REFERENCES notes(note_id )
);

CREATE TABLE accords(
accord_id INT auto_increment PRIMARY KEY,
accord_name VARCHAR(100) UNIQUE
);

-- Linking perfumes to their accords
CREATE TABLE perfume_accords(
perfume_id INT,
accord_id INT,
PRIMARY KEY(perfume_id, accord_id),
FOREIGN KEY(perfume_id) REFERENCES perfumes(perfume_id),
FOREIGN KEY(accord_id) REFERENCES accords(accord_id)
);

-- Creating a helper table to split comma-separated notes
CREATE TABLE numbers(n INT);
INSERT INTO numbers VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10);


INSERT INTO brands(brand_name, country)
SELECT DISTINCT brand, country
FROM raw_fragrances
WHERE brand IS NOT NULL AND brand != ' ';

INSERT INTO perfumes( perfume_name, brand_id, gender, rating_value, rating_count, year, url)
SELECT r.perfume_name, b.brand_id, r.gender, r.rating_value, r.rating_count, r.year, r.url
FROM raw_fragrances r
JOIN brands b
ON r.brand = b.brand_name;

INSERT INTO perfumers(perfumer_name)
SELECT DISTINCT perfumer1 FROM raw_fragrances
WHERE perfumer1 IS NOT NULL AND perfumer1 != ' ';

INSERT IGNORE INTO perfumers(perfumer_name)
SELECT DISTINCT perfumer2 FROM raw_fragrances
WHERE perfumer2 IS NOT NULL AND perfumer2 != ' ';

INSERT INTO perfume_perfumers(perfume_id, perfumer_id)
SELECT p.perfume_id, pf.perfumer_id
FROM raw_fragrances r
JOIN perfumes p ON r.perfume_name=p.perfume_name
JOIN perfumers pf ON r.perfumer1=pf.perfumer_name
WHERE r.perfumer1 IS NOT NULL AND r.perfumer1 !=' ';

INSERT INTO perfume_perfumers(perfume_id, perfumer_id)
SELECT p.perfume_id, pf.perfumer_id
FROM raw_fragrances r
JOIN perfumes p ON r.perfume_name=p.perfume_name
JOIN perfumers pf ON r.perfumer2=pf.perfumer_name
WHERE r.perfumer2 IS NOT NULL AND r.perfumer2 !=' ';

-- Building notes table(top + middle + base combined)
INSERT IGNORE INTO notes(note_name)

SELECT DISTINCT TRIM(SUBSTRING_INDEX (SUBSTRING_INDEX (r.top_notes, ',', num.n), ',', -1))
FROM raw_fragrances r
JOIN numbers num ON CHAR_LENGTH(r.top_notes)-CHAR_LENGTH(REPLACE(r.top_notes, ',', '')) >= num.n - 1
WHERE r.top_notes IS NOT NULL AND r.top_notes != ''
UNION ALL
SELECT DISTINCT TRIM(SUBSTRING_INDEX (SUBSTRING_INDEX (r.middle_notes, ',', num.n), ',', -1))
FROM raw_fragrances r
JOIN numbers num ON CHAR_LENGTH(r.middle_notes)-CHAR_LENGTH(REPLACE(r.middle_notes, ',', '')) >= num.n - 1
WHERE r.middle_notes IS NOT NULL AND r.middle_notes != ''
UNION ALL
SELECT DISTINCT TRIM(SUBSTRING_INDEX (SUBSTRING_INDEX (r.base_notes, ',', num.n), ',', -1))
FROM raw_fragrances r
JOIN numbers num ON CHAR_LENGTH(r.base_notes)-CHAR_LENGTH(REPLACE(r.base_notes, ',', '')) >= num.n - 1
WHERE r.base_notes IS NOT NULL AND r.base_notes != '';

-- Building perfume_notes table(top + middle + base combined)
INSERT IGNORE INTO perfume_notes(perfume_id, note_id, note_type)

SELECT DISTINCT p.perfume_id, nt.note_id, 'top'
FROM raw_fragrances r
JOIN perfumes p ON p.url=r.url
JOIN numbers num ON CHAR_LENGTH(r.top_notes)-CHAR_LENGTH(REPLACE(r.top_notes, ',', '')) >= num.n - 1
JOIN notes nt ON nt.note_name = TRIM(SUBSTRING_INDEX (SUBSTRING_INDEX (r.top_notes, ',', num.n), ',', -1))
WHERE r.top_notes IS NOT NULL AND r.top_notes != ''
UNION ALL
SELECT DISTINCT p.perfume_id, nt.note_id, 'middle'
FROM raw_fragrances r
JOIN perfumes p ON p.url=r.url
JOIN numbers num ON CHAR_LENGTH(r.top_notes)-CHAR_LENGTH(REPLACE(r.top_notes, ',', '')) >= num.n - 1
JOIN notes nt ON nt.note_name = TRIM(SUBSTRING_INDEX (SUBSTRING_INDEX (r.top_notes, ',', num.n), ',', -1))
WHERE r.middle_notes IS NOT NULL AND r.middle_notes != ''
UNION ALL
SELECT DISTINCT p.perfume_id, nt.note_id, 'base'
FROM raw_fragrances r
JOIN perfumes p ON p.url=r.url
JOIN numbers num ON CHAR_LENGTH(r.base_notes)-CHAR_LENGTH(REPLACE(r.base_notes, ',', '')) >= num.n - 1
JOIN notes nt ON nt.note_name = TRIM(SUBSTRING_INDEX (SUBSTRING_INDEX (r.base_notes, ',', num.n), ',', -1))
WHERE r.base_notes IS NOT NULL AND r.base_notes != '';

-- To count how many perfume-note link exists for each note type
SELECT note_type, COUNT(*) 
FROM perfume_notes
GROUP BY note_type;

INSERT IGNORE INTO accords(accord_name)
SELECT DISTINCT mainaccord1 FROM raw_fragrances WHERE mainaccord1 IS NOT NULL AND mainaccord1 != ''
UNION 
SELECT DISTINCT mainaccord2 FROM raw_fragrances WHERE mainaccord2 IS NOT NULL AND mainaccord2 != ''
UNION
SELECT DISTINCT mainaccord3 FROM raw_fragrances WHERE mainaccord3 IS NOT NULL AND mainaccord3 != ''
UNION
SELECT DISTINCT mainaccord4 FROM raw_fragrances WHERE mainaccord4 IS NOT NULL AND mainaccord4 != ''
UNION
SELECT DISTINCT mainaccord5 FROM raw_fragrances WHERE mainaccord5 IS NOT NULL AND mainaccord2 != '';

INSERT IGNORE INTO perfume_accords (perfume_id, accord_id)
SELECT p.perfume_id, a.accord_id
FROM raw_fragrances r
JOIN perfumes p ON r.url = p.url
JOIN accords a ON r.mainaccord1 = a.accord_name
WHERE r.mainaccord1 IS NOT NULL AND r.mainaccord1 != ''
UNION ALL
SELECT p.perfume_id, a.accord_id
FROM raw_fragrances r
JOIN perfumes p ON r.url = p.url
JOIN accords a ON r.mainaccord2 = a.accord_name
WHERE r.mainaccord2 IS NOT NULL AND r.mainaccord2 != ''
UNION ALL
SELECT p.perfume_id, a.accord_id
FROM raw_fragrances r
JOIN perfumes p ON r.url = p.url
JOIN accords a ON r.mainaccord3 = a.accord_name
WHERE r.mainaccord3 IS NOT NULL AND r.mainaccord3 != ''
UNION ALL
SELECT p.perfume_id, a.accord_id
FROM raw_fragrances r
JOIN perfumes p ON r.url = p.url
JOIN accords a ON r.mainaccord4 = a.accord_name
WHERE r.mainaccord4 IS NOT NULL AND r.mainaccord4 != ''
UNION ALL
SELECT p.perfume_id, a.accord_id
FROM raw_fragrances r
JOIN perfumes p ON r.url = p.url
JOIN accords a ON r.mainaccord5 = a.accord_name
WHERE r.mainaccord5 IS NOT NULL AND r.mainaccord5 != '';

-- to see how many perfumes have 1 accord, 2 accords and so on
SELECT accord_count, COUNT(*) AS num_perfumes FROM
(SELECT perfume_id, COUNT(*) AS accord_count
FROM perfume_accords
GROUP BY perfume_id)
as sub
GROUP BY accord_count
ORDER BY accord_count;

-- to check whether perfume name and brand combination was unique - No, this is why the join was rebuilt using url instead
SELECT perfume_name, brand_id, COUNT(*) AS matching_rows
FROM perfumes
GROUP BY perfume_name, brand_id
HAVING COUNT(*)>1;

-- to clear previous duplicate records
TRUNCATE TABLE perfume_accords;

-- re-ran the perfume_accords insert query using perfume's url



-- avg rating by country
SELECT b.country, ROUND(AVG(p.rating_value), 2) AS avg_rating, COUNT(*) AS perfume_count
FROM perfumes p
JOIN brands b ON b.brand_id = p.brand_id
GROUP BY b.country
HAVING COUNT(*)>=20
ORDER BY avg_rating DESC
LIMIT 10;

-- most consistent brands
SELECT b.brand_name, COUNT(*) AS num_perfumes, ROUND(AVG(p.rating_value),2) AS avg_rating
FROM perfumes p
JOIN brands b ON b.brand_id=p.brand_id
GROUP BY b.brand_name
HAVING COUNT(*)>=10
ORDER BY avg_rating DESC
LIMIT 10;

-- top 10 notes in perfumes rated above 4.0
SELECT n.note_name, COUNT(*) AS times_used
FROM perfume_notes pn
JOIN notes n ON pn.note_id=n.note_id
JOIN perfumes p ON pn.perfume_id = p.perfume_id
WHERE p.rating_value>4.0
GROUP BY n.note_name
ORDER BY times_used DESC
LIMIT 10;

-- best rated perfumers
SELECT pf.perfumer_name, COUNT(*) AS num_perfumes, ROUND(AVG(p.rating_value),2) as avg_rating
FROM perfume_perfumers pp
JOIN perfumes p ON pp.perfume_id = p.perfume_id
JOIN perfumers pf ON pp.perfumer_id = pf.perfumer_id
GROUP BY pf.perfumer_name
HAVING COUNT(*) >= 5
ORDER BY avg_rating DESC
LIMIT 10;

-- avg rating by decade, to check if avg rating has changed across decades
SELECT ROUND(AVG(rating_value),2) as avg_rating, COUNT(*) AS perfume_count,
CASE
WHEN year BETWEEN 2000 AND 2009 THEN '2000s'
WHEN year BETWEEN 2010 AND 2019 THEN '2010s'
WHEN year BETWEEN 2020 AND 2029 THEN '2020s'
ELSE 'other'
END AS decade
FROM perfumes
WHERE year IS NOT NULL
GROUP BY decade
ORDER BY decade;

-- unisex percentage trend by year
SELECT year, 
SUM(CASE WHEN gender = 'unisex' THEN 1 ELSE 0 END) AS unisex_count,
COUNT(*) AS total_count,
ROUND(100 * SUM(CASE WHEN gender = 'unisex' THEN 1 ELSE 0 END) / COUNT(*), 1) AS unisex_percentage
FROM perfumes
WHERE year IS NOT NULL
GROUP BY year
HAVING total_count>=10
ORDER BY year;

-- hidden gem brands(high rating, low popularity)
SELECT b.brand_name, ROUND(AVG(p.rating_value),2) AS avg_rating, ROUND(AVG(p.rating_count),0) AS avg_popularity
FROM perfumes p
JOIN brands b ON b.brand_id = p.brand_id
GROUP BY b.brand_name
HAVING avg_rating>4.0 AND avg_popularity<500 AND COUNT(*)>=5
ORDER BY avg_rating DESC
LIMIT 10;

-- perfumes that are popular but rating below their own brand's average
WITH brand_averages AS (
SELECT b.brand_id, ROUND(AVG(p.rating_value),2) as brand_avg_rating
FROM perfumes p
JOIN brands b ON p.brand_id = b.brand_id
GROUP BY b.brand_id)
SELECT p.perfume_name, b.brand_name, p.rating_value, ba.brand_avg_rating, p.rating_count
FROM perfumes p
JOIN brands b ON b.brand_id=p.brand_id
JOIN brand_averages ba ON ba.brand_id=p.brand_id
WHERE p.rating_value<ba.brand_avg_rating
AND p.rating_count>1000
ORDER BY p.rating_count DESC
LIMIT 10;

-- to get report of a brand
DELIMITER $$
CREATE PROCEDURE get_brand_report(IN input_brand_name VARCHAR(260))
BEGIN
SELECT b.brand_name, b.country,
COUNT(p.perfume_id) AS total_perfumes,
ROUND(AVG(p.rating_value),2) AS avg_rating,
SUM(p.rating_count) AS total_ratings,
MAX(p.rating_value) AS highest_rated
FROM brands b
JOIN perfumes p ON p.brand_id=b.brand_id
WHERE b.brand_name=input_brand_name
GROUP BY b.brand_name, b.country;
END$$
DELIMITER ;

CALL get_brand_report('chanel');

-- adding a new column to see whether a perfume is popular or not
ALTER TABLE perfumes
ADD COLUMN is_popular BOOLEAN DEFAULT FALSE;

-- defining values of is_popular for existing rows
UPDATE perfumes
SET is_popular = TRUE
WHERE rating_count>1000;

SELECT is_popular, COUNT(*)
FROM perfumes
GROUP BY is_popular;

-- to auto-flag popular perfumes
DELIMITER $$
CREATE TRIGGER popularity_check
BEFORE INSERT ON perfumes
FOR EACH ROW
BEGIN
IF NEW.rating_count>1000 THEN 
SET NEW.is_popular = TRUE;
END IF;
END $$
DELIMITER ;

-- To test trigger
INSERT INTO perfumes(perfume_name, brand_id, gender, rating_value, rating_count, year, url)
VALUES('tp', 1, 'unisex', 4.5, 5000, 2024, 'tu123');
SELECT perfume_name, rating_count, is_popular
FROM perfumes
WHERE url='tu123';
-- removing test row
DELETE FROM perfumes WHERE url='tu123';