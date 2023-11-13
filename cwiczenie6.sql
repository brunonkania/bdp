--create extension postgis;
CREATE TABLE obiekty (nazwa VARCHAR(7) NOT NULL,geom GEOMETRY NOT NULL);


INSERT INTO obiekty VALUES ('obiekt1', ST_GeomFromEWKT( 'COMPOUNDCURVE(INESTRING(0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), LINESTRING(5 1, 6 1))' ));
INSERT INTO obiekty 
VALUES ('obiekt2', ST_GeomFromEWKT('CURVEPOLYGON(
                     COMPOUNDCURVE( LINESTRING(10 2, 10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2)),
                     COMPOUNDCURVE( CIRCULARSTRING(11 2,12 3, 13 2), CIRCULARSTRING(13 2, 12 1, 11 2) ) )'));

INSERT INTO obiekty VALUES('obiekt3', ST_GeomFromEWKT('LINESTRING(7 15, 10 17, 12 13, 7 15)'));
INSERT INTO obiekty VALUES('obiekt4', ST_GeomFromEWKT( 'MULTILINESTRING((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5))' ));
INSERT INTO obiekty VALUES('obiekt5', ST_GeomFromEWKT( 'MULTIPOINT Z ((30 30 59),(38 32 234))' ));
INSERT INTO obiekty VALUES('obiekt6', ST_GeomFromEWKT( 'GEOMETRYCOLLECTION ( POINT(4 2), LINESTRING(1 1, 3 2))' ));

-- 1.

SELECT ST_Area(ST_Buffer(ST_ShortestLine
((SELECT geom FROM obiekty WHERE nazwa='obiekt3'),
(SELECT geom FROM obiekty WHERE nazwa='obiekt4')),5));
						 

-- 2.

UPDATE obiekty SET geom=ST_MakePolygon
(ST_LineMerge(ST_Union(geom, 'MULTILINESTRING((20.5 19.5, 20 20))')))
WHERE nazwa='obiekt4';


-- 3.
INSERT INTO obiekty(nazwa, geom) VALUES
('obiekt7', ST_Collect((SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'), (SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')));


-- 4.

WITH POLE AS (SELECT ST_Union(ARRAY(SELECT geom FROM obiekty
WHERE NOT ST_HasArc(geom))) as geom)
SELECT ST_Area(ST_Buffer(geom, 5))
FROM POLE;


--select nazwa, st_curvetoline(geom) from obiekty
--where nazwa ='obiekt5';