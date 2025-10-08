import csv, re
from pathlib import Path

root = Path(__file__).resolve().parent
ds = root / "dataset"

# файлы
movies_p = ds / "movies.csv"
ratings_p = ds / "ratings.csv"
tags_p = ds / "tags.csv"
users_p = ds / "users.txt"
genres_p = ds / "genres.txt"


def esc(s: str) -> str:  # экранирую кавычки для SQL
    return s.replace("'", "''") if s is not None else ""


def cut_year(title: str):
    m = re.search(r"\s\((\d{4})\)\s*$", title or "")
    if m: return title[:m.start()].rstrip(), int(m.group(1))
    return title, None


def read_users(p: Path):
    out = []
    with p.open(encoding="utf-8") as f:
        for row in csv.reader(f, delimiter="|"):
            if not row: continue
            out.append({
                "id": int(row[0]), "name": row[1], "email": row[2],
                "gender": row[3], "register_date": row[4], "occupation": row[5]
            })
    return out


def read_movies(p: Path):
    out = []
    with p.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            t, y = cut_year(r["title"])
            out.append({"id": int(r["movieId"]), "title": t, "year": y, "genres": r.get("genres", "")})
    return out


def read_ratings(p: Path):
    out, i = [], 1
    with p.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            out.append({"id": i, "user_id": int(r["userId"]), "movie_id": int(r["movieId"]),
                        "rating": float(r["rating"]), "timestamp": int(r["timestamp"])})
            i += 1
    return out


def read_tags(p: Path):
    out, i = [], 1
    with p.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            out.append({"id": i, "user_id": int(r["userId"]), "movie_id": int(r["movieId"]),
                        "tag": r.get("tag", ""), "timestamp": int(r["timestamp"])})
            i += 1
    return out


def main():
    # быстрый чек наличия
    for p in (movies_p, ratings_p, tags_p, users_p, genres_p):
        if not p.exists(): raise SystemExit(f"Нет файла: {p}")

    users = read_users(users_p)
    movies = read_movies(movies_p)
    ratings = read_ratings(ratings_p)
    tags = read_tags(tags_p)

    sql = []
    sql += ["-- db_init.sql (автоген)", "BEGIN;"]
    sql += ["DROP TABLE IF EXISTS ratings;",
            "DROP TABLE IF EXISTS tags;",
            "DROP TABLE IF EXISTS movies;",
            "DROP TABLE IF EXISTS users;"]

    sql += ["""CREATE TABLE users(
        id INTEGER PRIMARY KEY, name TEXT, email TEXT, gender TEXT, register_date TEXT, occupation TEXT
    );"""]

    sql += ["""CREATE TABLE movies(
        id INTEGER PRIMARY KEY, title TEXT, year INTEGER, genres TEXT
    );"""]

    sql += ["""CREATE TABLE ratings(
        id INTEGER PRIMARY KEY, user_id INTEGER, movie_id INTEGER, rating REAL, timestamp INTEGER,
        FOREIGN KEY(user_id) REFERENCES users(id),
        FOREIGN KEY(movie_id) REFERENCES movies(id)
    );"""]

    sql += ["""CREATE TABLE tags(
        id INTEGER PRIMARY KEY, user_id INTEGER, movie_id INTEGER, tag TEXT, timestamp INTEGER,
        FOREIGN KEY(user_id) REFERENCES users(id),
        FOREIGN KEY(movie_id) REFERENCES movies(id)
    );"""]

    for u in users:
        sql.append(
            f"INSERT INTO users VALUES ({u['id']},'{esc(u['name'])}','{esc(u['email'])}','{esc(u['gender'])}','{u['register_date']}','{esc(u['occupation'])}');")

    for m in movies:
        y = "NULL" if m["year"] is None else m["year"]
        sql.append(f"INSERT INTO movies VALUES ({m['id']},'{esc(m['title'])}',{y},'{esc(m['genres'])}');")

    for r in ratings:
        sql.append(
            f"INSERT INTO ratings VALUES ({r['id']},{r['user_id']},{r['movie_id']},{r['rating']},{r['timestamp']});")

    for t in tags:
        sql.append(
            f"INSERT INTO tags VALUES ({t['id']},{t['user_id']},{t['movie_id']},'{esc(t['tag'])}',{t['timestamp']});")

    sql += ["COMMIT;"]

    (root / "db_init.sql").write_text("\n".join(sql), encoding="utf-8")
    print("OK: db_init.sql готов (лежит рядом со скриптом)")


if __name__ == "__main__":
    main()
