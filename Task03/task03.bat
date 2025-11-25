#!/bin/bash

# смена кодировки для Windows (в git-bash chcp есть, в macOS/Linux — нет)
if command -v chcp >/dev/null 2>&1; then
  chcp 65001
fi

# проверяем, что db_init.sql существует рядом со скриптом
if [ ! -f "db_init.sql" ]; then
  echo "Файл db_init.sql не найден. Сначала сгенерируй его командой:"
  echo "  python make_db_init.py"
  exit 1
fi

# пересоздаём базу из db_init.sql
rm -f movies_rating.db
sqlite3 movies_rating.db < db_init.sql

echo "1. Составить список фильмов, имеющих хотя бы одну оценку. Список фильмов отсортировать по году выпуска и по названиям. В списке оставить первые 10 фильмов."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    m.id,
    m.title,
    m.year,
    COUNT(r.id) AS rating_count
FROM movies AS m
JOIN ratings AS r ON r.movie_id = m.id
GROUP BY m.id, m.title, m.year
HAVING COUNT(r.id) >= 1
ORDER BY m.year, m.title
LIMIT 10;"
echo " "

echo "2. Вывести список всех пользователей, фамилии (не имена!) которых начинаются на букву 'A'. Полученный список отсортировать по дате регистрации. В списке оставить первых 5 пользователей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    id,
    name,
    email,
    gender,
    register_date,
    occupation
FROM users
WHERE substr(name, instr(name, ' ') + 1) LIKE 'A%'
ORDER BY register_date
LIMIT 5;"
echo " "

echo "3. Написать запрос, возвращающий информацию о рейтингах в более читаемом формате: имя и фамилия эксперта, название фильма, год выпуска, оценка и дата оценки в формате ГГГГ-ММ-ДД. Отсортировать данные по имени эксперта, затем названию фильма и оценке. В списке оставить первые 50 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    substr(u.name, 1, instr(u.name, ' ') - 1) AS first_name,
    substr(u.name, instr(u.name, ' ') + 1)    AS last_name,
    m.title,
    m.year,
    r.rating,
    date(r.timestamp, 'unixepoch')            AS rating_date
FROM ratings AS r
JOIN users   AS u ON u.id = r.user_id
JOIN movies  AS m ON m.id = r.movie_id
ORDER BY first_name, m.title, r.rating
LIMIT 50;"
echo " "

echo "4. Вывести список фильмов с указанием тегов, которые были им присвоены пользователями. Сортировать по году выпуска, затем по названию фильма, затем по тегу. В списке оставить первые 40 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    m.id,
    m.title,
    m.year,
    t.tag
FROM movies AS m
JOIN tags   AS t ON t.movie_id = m.id
WHERE t.tag <> ''
ORDER BY m.year, m.title, t.tag
LIMIT 40;"
echo " "

echo "5. Вывести список самых свежих фильмов. В список должны войти все фильмы последнего года выпуска, имеющиеся в базе данных. Запрос должен быть универсальным, не зависящим от исходных данных (нужный год выпуска должен определяться в запросе, а не жестко задаваться)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    id,
    title,
    year
FROM movies
WHERE year = (SELECT MAX(year) FROM movies)
ORDER BY title;"
echo " "

echo "6. Найти все драмы, выпущенные после 2005 года, которые понравились женщинам (оценка не ниже 4.5). Для каждого фильма в этом списке вывести название, год выпуска и количество таких оценок. Результат отсортировать по году выпуска и названию фильма."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    m.title,
    m.year,
    COUNT(*) AS female_high_ratings
FROM ratings AS r
JOIN users   AS u ON u.id = r.user_id
JOIN movies  AS m ON m.id = r.movie_id
WHERE
    u.gender = 'female'
    AND r.rating >= 4.5
    AND m.year > 2005
    AND m.genres LIKE '%Drama%'
GROUP BY m.id, m.title, m.year
ORDER BY m.year, m.title;"
echo " "

echo "7. Провести анализ востребованности ресурса - вывести количество пользователей, регистрировавшихся на сайте в каждом году. Найти, в каких годах регистрировалось больше всего и меньше всего пользователей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH yearly AS (
    SELECT
        substr(register_date, 1, 4) AS year,
        COUNT(*) AS user_count
    FROM users
    GROUP BY substr(register_date, 1, 4)
),
limits AS (
    SELECT
        MAX(user_count) AS max_count,
        MIN(user_count) AS min_count
    FROM yearly
)
SELECT
    y.year,
    y.user_count,
    CASE
        WHEN y.user_count = l.max_count THEN 'max'
        WHEN y.user_count = l.min_count THEN 'min'
        ELSE ''
    END AS note
FROM yearly AS y, limits AS l
ORDER BY y.year;"
echo " "
