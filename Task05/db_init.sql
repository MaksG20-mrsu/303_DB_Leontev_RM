------------------------------------------------------------
-- Справочник профессий
------------------------------------------------------------
CREATE TABLE occupations (
    id   INTEGER PRIMARY KEY,                                   -- автоинкремент за счёт rowid
    name TEXT    NOT NULL
                  UNIQUE
                  CHECK (length(trim(name)) > 0)
);

------------------------------------------------------------
-- Пользователи
------------------------------------------------------------
CREATE TABLE users (
    id            INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL
                        CHECK (length(trim(name)) > 0),
    email         TEXT    NOT NULL
                        UNIQUE
                        CHECK (instr(email, '@') > 1),
    gender        TEXT    NOT NULL
                        CHECK (gender IN ('M', 'F')),
    register_date TEXT    NOT NULL
                        DEFAULT (date('now')),
    occupation_id INTEGER
                        REFERENCES occupations(id)
                        ON DELETE SET NULL
);

------------------------------------------------------------
-- Фильмы
------------------------------------------------------------
CREATE TABLE movies (
    id           INTEGER PRIMARY KEY,
    title        TEXT    NOT NULL
                        CHECK (length(trim(title)) > 0),
    year         INTEGER
                        CHECK (
                            year IS NULL
                            OR (year >= 1888 AND year <= 2100)
                        ),
    created_date TEXT    NOT NULL
                        DEFAULT (datetime('now'))
);


------------------------------------------------------------
-- Жанры
------------------------------------------------------------
CREATE TABLE genres (
    id   INTEGER PRIMARY KEY,
    name TEXT    NOT NULL
                UNIQUE
                CHECK (length(trim(name)) > 0)
);

------------------------------------------------------------
-- Связь фильм–жанр (многие ко многим)
------------------------------------------------------------
CREATE TABLE movie_genres (
    movie_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(id)  ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE
);

------------------------------------------------------------
-- Оценки
------------------------------------------------------------
CREATE TABLE ratings (
    id        INTEGER PRIMARY KEY,
    user_id   INTEGER NOT NULL
                     REFERENCES users(id)  ON DELETE CASCADE,
    movie_id  INTEGER NOT NULL
                     REFERENCES movies(id) ON DELETE RESTRICT,
    rating    REAL    NOT NULL
                     CHECK (rating >= 0 AND rating <= 5),
    timestamp INTEGER NOT NULL
                     DEFAULT (strftime('%s', 'now'))
);

------------------------------------------------------------
-- Теги
------------------------------------------------------------
CREATE TABLE tags (
    id        INTEGER PRIMARY KEY,
    user_id   INTEGER NOT NULL
                     REFERENCES users(id)  ON DELETE CASCADE,
    movie_id  INTEGER NOT NULL
                     REFERENCES movies(id) ON DELETE CASCADE,
    tag       TEXT    NOT NULL
                     CHECK (length(trim(tag)) > 0),
    timestamp INTEGER NOT NULL
                     DEFAULT (strftime('%s', 'now'))
);

------------------------------------------------------------
-- Индексы
------------------------------------------------------------
CREATE INDEX idx_users_name       ON users(name);
CREATE INDEX idx_movies_title     ON movies(title);
CREATE INDEX idx_movies_year      ON movies(year);
CREATE INDEX idx_ratings_user_id  ON ratings(user_id);
CREATE INDEX idx_ratings_movie_id ON ratings(movie_id);
CREATE INDEX idx_tags_user_id     ON tags(user_id);
CREATE INDEX idx_tags_movie_id    ON tags(movie_id);

------------------------------------------------------------
-- Начальное наполнение справочников
------------------------------------------------------------
INSERT INTO occupations (name) VALUES
  ('artist'),
  ('doctor'),
  ('engineer'),
  ('executive'),
  ('homemaker'),
  ('lawyer'),
  ('librarian'),
  ('marketing'),
  ('none'),
  ('other'),
  ('programmer'),
  ('retired'),
  ('salesman'),
  ('scientist'),
  ('student'),
  ('technician'),
  ('writer');

INSERT INTO genres (name) VALUES
  ('Action'),
  ('Adventure'),
  ('Animation'),
  ('Children'),
  ('Comedy'),
  ('Crime'),
  ('Documentary'),
  ('Drama'),
  ('Fantasy'),
  ('Film-Noir'),
  ('Horror'),
  ('Musical'),
  ('Mystery'),
  ('Romance'),
  ('Sci-Fi'),
  ('Thriller'),
  ('War'),
  ('Western');
