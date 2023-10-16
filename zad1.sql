--2
CREATE DATABASE bdp;

--3
CREATE EXTENSION postgis;

--4
CREATE TABLE budynki(id INT,geometria GEOMETRY, nazwa VARCHAR(30));

CREATE TABLE drogi(id_ INT,geometria GEOMETRY,nazwa VARCHAR(30));

CREATE TABLE punkty(id INT,geometria GEOMETRY,nazwa VARCHAR(30));

--5
INSERT INTO budynki
VALUES
(1, 'POLYGON((8 1.5, 8 4, 10.5 4, 10.5 1.5, 8 1.5))', 'BuildingA'),
(2, 'POLYGON((4 5, 4 7, 6 7, 6 5, 4 5))', 'BuildingB'),
(3, 'POLYGON((3 6, 3 8, 5 8, 5 6, 3 6))', 'BuildingC'),
(4, 'POLYGON((9 8, 9 9, 10 9, 10 8, 9 8))', 'BuildingD'),
(5, 'POLYGON((1 1, 1 2, 2 2, 2 1, 1 1))', 'BuildingF');

INSERT INTO drogi
VALUES
(1, 'LINESTRING(0 4.5, 12 4.5)', 'RoadX'),
(2, 'LINESTRING(7.5 0, 7.5 10.5)', 'RoadY');

INSERT INTO punkty
VALUES
(1, 'Point(1 3.5)', 'G'),
(2, 'Point(5.5 1.5)', 'H'),
(3, 'Point(9.5 6)', 'I'),
(4, 'Point(6.5 6)', 'J'),
(5, 'Point(6 9.5)', 'K');

--6
--a
SELECT SUM(ST_Length(d.geometria)) AS "Calkowita dlugosc drog"FROMdrogi d;
--b
SELECT ST_AsText(b.geometria) AS "Geometria", ST_Area(b.geometria) AS "Pole powierzchni",ST_Perimeter(b.geometria) AS "Obwod"
FROM budynki WHEREnazwa='BuildingA';
--c
SELECT b.nazwa AS "Nazwa", ST_Area(b.geometria) AS "Pole powierzchni"
FROM budynki b ORDER BY b.nazwa;
--d
SELECT b.nazwa AS "Nazwa", ST_Perimeter(b.geometria) AS "Obwod"
FROM budynki b ORDER BY ST_Area(b.geometria) DESC LIMIT 2;
--e
SELECT ST_Distance(b.geometria, p.geometria) AS "Najkrotsza odleglosc miedzy budynkiem C i punktem G"
FROM budynki b, punkty p WHERE b.nazwa='BuildingC' AND p.nazwa='G';
--f
SELECT ST_Area(b2.geometria)-ST_Area(ST_Intersection(ST_Buffer(b1.geometria, 0.5), b2.geometria)) AS "Pole powierzchni"
FROM budynki b1, budynki b2 WHERE b1.nazwa='BuildingB' AND b2.nazwa='BuildingC';
--g
SELECT b.id AS "ID", b.nazwa AS "Nazwa" FROM drogi d, budynki  
WHERE d.nazwa='RoadX' AND ST_Y(ST_Centroid(b.geometria))>ST_Y(ST_PointN(d.geometria, 1));
--h
SELECT ST_Area(ST_Difference(b.geometria, ST_GeomFromText('Polygon((4 7, 6 7, 6 8, 4 8, 4 7))')))+ST_Area(ST_Difference(ST_GeomFromText('Polygon((4 7, 6 7, 6 8, 4 8, 4 7))'), b.geometria))
FROM budynki b WHERE b.nazwa='BuildingC';
