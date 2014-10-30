
DROP TABLE IF EXISTS artists;
CREATE TABLE artists(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT
);

DROP TABLE IF EXISTS albums;
CREATE TABLE albums(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    artist_id INTEGER,
    title TEXT,
    year INTEGER,
    FOREIGN KEY(artist_id) REFERENCES artists(id)
);


INSERT INTO artists(name) VALUES ("Nirvana"), ("Green Day");

INSERT INTO albums(artist_id, title, year)
VALUES (1, "Bleach", 1989), (1, "Nervermind", 1991), (1, "In Utero", 1993);
INSERT INTO albums(artist_id, title, year)
VALUES (2, "39/Smooth", 1990), (2, "Kerplunk", 1992),
(2, "Dookie", 1994), (2, "Insomniac", 1995),
(2, "Nimrod", 1997), (2, "Warning", 2000),
(2, "American Idiot", 2004), (2, "21st Century Breakdown", 2009);
