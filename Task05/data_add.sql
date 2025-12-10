------------------------------------------------------------
-- Добавление новых пользователей
------------------------------------------------------------

INSERT INTO users (name, email, gender, occupation_id)
VALUES
    ('Антонов Сергей Викторович',   'antonov_sv@study.ru',   'M',
        (SELECT id FROM occupations WHERE name = 'student')),
    ('Кузнецова Марина Олеговна',   'kuznetsova_mo@study.ru','F',
        (SELECT id FROM occupations WHERE name = 'student')),
    ('Васильев Дмитрий Игоревич',   'vasiliev_di@study.ru',  'M',
        (SELECT id FROM occupations WHERE name = 'student')),
    ('Громова Анастасия Павловна',  'gromova_ap@study.ru',   'F',
        (SELECT id FROM occupations WHERE name = 'student')),
    ('Еремин Алексей Николаевич',   'eremin_an@study.ru',    'M',
        (SELECT id FROM occupations WHERE name = 'student'));

------------------------------------------------------------
-- Добавление фильмов
------------------------------------------------------------

INSERT INTO movies (title, year) VALUES
    ('Побег из Кремниевой долины', 2024),
    ('Хроники Ледяного Клана',     2025),
    ('Сказание о Туманном Лесу',   2025);

------------------------------------------------------------
-- Присвоение жанров фильмам
------------------------------------------------------------

-- Побег из Кремниевой долины → Sci-Fi
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM movies m
JOIN genres g ON g.name = 'Sci-Fi'
WHERE m.title = 'Побег из Кремниевой долины';

-- Хроники Ледяного Клана → Fantasy
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM movies m
JOIN genres g ON g.name = 'Fantasy'
WHERE m.title = 'Хроники Ледяного Клана';

-- Сказание о Туманном Лесу → Adventure
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM movies m
JOIN genres g ON g.name = 'Adventure'
WHERE m.title = 'Сказание о Туманном Лесу';

------------------------------------------------------------
-- Добавление оценок
------------------------------------------------------------

-- Сергей → получает Sci-Fi фильм
INSERT INTO ratings (user_id, movie_id, rating)
SELECT
    (SELECT id FROM users WHERE email = 'antonov_sv@study.ru'),
    (SELECT id FROM movies WHERE title = 'Побег из Кремниевой долины'),
    4.7;

-- Марина → Fantasy фильм
INSERT INTO ratings (user_id, movie_id, rating)
SELECT
    (SELECT id FROM users WHERE email = 'kuznetsova_mo@study.ru'),
    (SELECT id FROM movies WHERE title = 'Хроники Ледяного Клана'),
    4.9;

-- Дмитрий → Adventure фильм
INSERT INTO ratings (user_id, movie_id, rating)
SELECT
    (SELECT id FROM users WHERE email = 'vasiliev_di@study.ru'),
    (SELECT id FROM movies WHERE title = 'Сказание о Туманном Лесу'),
    3.5;
