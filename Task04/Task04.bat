#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм (без дублей и самих себя). Вывести имена пользователей и название фильма (первые 100 записей)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo <<'SQL'
SELECT
    u1.name AS user1_name,
    u2.name AS user2_name,
    m.title AS movie_title
FROM ratings AS r1
JOIN ratings AS r2
  ON r1.movie_id = r2.movie_id
 AND r1.user_id < r2.user_id
JOIN users AS u1
  ON u1.id = r1.user_id
JOIN users AS u2
  ON u2.id = r2.user_id
JOIN movies AS m
  ON m.id = r1.movie_id
LIMIT 100;
SQL
echo " "


echo "2. Найти 10 самых старых оценок от разных пользователей. Вывести фильм, пользователя, оценку и дату отзыва (ГГГГ-ММ-ДД)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo <<'SQL'
WITH user_first_ratings AS (
    SELECT
        r.id,
        r.user_id,
        r.movie_id,
        r.rating,
        r.timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY r.user_id
            ORDER BY r.timestamp
        ) AS rn
    FROM ratings AS r
)
SELECT
    m.title AS movie_title,
    u.name  AS user_name,
    r.rating,
    date(r.timestamp, 'unixepoch') AS rating_date
FROM user_first_ratings AS r
JOIN users  AS u ON u.id = r.user_id
JOIN movies AS m ON m.id = r.movie_id
WHERE r.rn = 1
ORDER BY r.timestamp
LIMIT 10;
SQL
echo " "


echo "3. Вывести фильмы с максимальным и минимальным средним рейтингом в одном списке. Отсортировать по году и названию. В колонке Рекомендуем: Да (максимум), Нет (минимум)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo <<'SQL'
WITH movie_stats AS (
    SELECT
        m.id,
        m.title,
        m.year,
        AVG(r.rating) AS avg_rating
    FROM movies AS m
    JOIN ratings AS r
      ON r.movie_id = m.id
    GROUP BY
        m.id,
        m.title,
        m.year
),
min_max AS (
    SELECT
        MIN(avg_rating) AS min_avg,
        MAX(avg_rating) AS max_avg
    FROM movie_stats
)
SELECT
    ms.title,
    ms.year,
    ROUND(ms.avg_rating, 2) AS avg_rating,
    CASE
        WHEN ms.avg_rating = mm.max_avg THEN 'Да'
        ELSE 'Нет'
    END AS recommend_flag
FROM movie_stats AS ms
CROSS JOIN min_max AS mm
WHERE ms.avg_rating = mm.min_avg
   OR ms.avg_rating = mm.max_avg
ORDER BY
    ms.year,
    ms.title;
SQL
echo " "


echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo <<'SQL'
SELECT
    COUNT(*)                AS ratings_count,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM ratings AS r
JOIN users AS u
  ON u.id = r.user_id
WHERE u.gender = 'male'
  AND date(r.timestamp, 'unixepoch')
      BETWEEN '2011-01-01' AND '2014-12-31';
SQL
echo " "


echo "5. Составить список фильмов с указанием средней оценки и количества пользователей, которые их оценили. Отсортировать по году и названию. В списке оставить первые 20 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo <<'SQL'
SELECT
    m.title,
    m.year,
    ROUND(AVG(r.rating), 2)           AS avg_rating,
    COUNT(DISTINCT r.user_id)         AS users_count
FROM movies AS m
LEFT JOIN ratings AS r
  ON r.movie_id = m.id
GROUP BY
    m.id,
    m.title,
    m.year
ORDER BY
    m.year,
    m.title
LIMIT 20;
SQL
echo " "


echo "6. Определить самый распространённый жанр фильма и количество фильмов в этом жанре (жанры берутся из поля movies.genres)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo <<'SQL'
WITH RECURSIVE movie_genres AS (
    SELECT
        id AS movie_id,
        TRIM(
            CASE
                WHEN INSTR(genres, '|') = 0
                    THEN genres
                ELSE SUBSTR(genres, 1, INSTR(genres, '|') - 1)
            END
        ) AS genre,
        CASE
            WHEN INSTR(genres, '|') = 0
                THEN ''
            ELSE SUBSTR(genres, INSTR(genres, '|') + 1)
        END AS rest
    FROM movies

    UNION ALL

    SELECT
        movie_id,
        TRIM(
            CASE
                WHEN INSTR(rest, '|') = 0
                    THEN rest
                ELSE SUBSTR(rest, 1, INSTR(rest, '|') - 1)
            END
        ) AS genre,
        CASE
            WHEN INSTR(rest, '|') = 0
                THEN ''
            ELSE SUBSTR(rest, INSTR(rest, '|') + 1)
        END AS rest
    FROM movie_genres
    WHERE rest <> ''
)
SELECT
    genre,
    COUNT(DISTINCT movie_id) AS movies_count
FROM movie_genres
WHERE genre <> ''
GROUP BY genre
ORDER BY
    movies_count DESC,
    genre
LIMIT 1;
SQL
echo " "


echo "7. Вывести список из 10 последних зарегистрированных пользователей в формате \"Фамилия Имя|Дата регистрации\"."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo <<'SQL'
SELECT
    printf(
        '%s %s|%s',
        SUBSTR(name, INSTR(name, ' ') + 1),      -- фамилия
        SUBSTR(name, 1, INSTR(name, ' ') - 1),   -- имя
        register_date
    ) AS user_info
FROM users
ORDER BY register_date DESC
LIMIT 10;
SQL
echo " "


echo "8. С помощью рекурсивного CTE определить, на какие дни недели приходился ваш день рождения в каждом году (пример: 15 мая, годы 1995–2025)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo <<'SQL'
WITH RECURSIVE years(y) AS (
    SELECT 1995
    UNION ALL
    SELECT y + 1
    FROM years
    WHERE y < 2025
)
SELECT
    y AS year,
    date(y || '-05-15') AS birthday,
    CASE strftime('%w', date(y || '-05-15'))
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END AS weekday_name
FROM years
ORDER BY year;
SQL
echo " "
