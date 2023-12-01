
--ST_Intersects
CREATE TABLE kania.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table kania.intersects
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON kania.intersects
USING gist (ST_ConvexHull(rast));

SELECT * FROM kania.intersects;

-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('kania'::name,
'intersects'::name,'rast'::name);

--ST_Clip
CREATE TABLE kania.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';


--ST_Union
CREATE TABLE kania.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


--Tworzenie rastrów z wektorów (rastrowanie)

--ST_AsRaster
CREATE TABLE kania.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';	

--ST_Union
DROP TABLE kania.porto_parishes; --> drop table porto_parishes first
CREATE TABLE kania.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--ST_Tile
DROP TABLE kania.porto_parishes; --> drop table porto_parishes first
CREATE TABLE kania.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--Konwertowanie rastrów na wektory (wektoryzowanie)


--ST_Intersection
create table kania.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--ST_DumpAsPolygons
CREATE TABLE kania.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);



--ANALIZA RASTRÓW


--st_band
CREATE TABLE kania.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

--st_clip
CREATE TABLE kania.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--st_slpoe
CREATE TABLE kania.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM kania.paranhos_dem AS a;

--st_reclass
CREATE TABLE kania.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3','32BF',0)
FROM kania.paranhos_slope AS a;

--st_summarystats
SELECT st_summarystats(a.rast) AS stats
FROM kania.paranhos_dem AS a;

--st_summarystats & st_union
SELECT st_summarystats(ST_Union(a.rast))
FROM kania.paranhos_dem AS a;

--ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM kania.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--st_value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;



--Topographic Position Index (TPI)


create table kania.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON kania.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kania'::name,
'tpi30'::name,'rast'::name);

--problem do rozwiązania

CREATE TABLE kania.tpi30porto as
WITH porto AS (
	SELECT a.rast
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ILIKE 'porto'
)
SELECT ST_TPI(porto.rast,1) as rast FROM porto;


--Algebra map


--NDVI=(NIR-Red)/(NIR+Red)

--Wyrażenie Algebry Map
CREATE TABLE kania.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON kania.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kania'::name,
'porto_ndvi'::name,'rast'::name);

--Funkcja zwrotna
create or replace function kania.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE kania.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'kania.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON kania.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kania'::name,
'porto_ndvi2'::name,'rast'::name);


--Eksport Danych

--0) qgis

--1) st_astiff
SELECT ST_AsTiff(ST_Union(rast))
FROM kania.porto_ndvi;

--2) st_asgdalraster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM kania.porto_ndvi;

--3) Zapisywanie danych na dysku za pomocą dużego obiektu (large object,lo)
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0, ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM kania.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'D:\myraster.tiff') --> Save the file in a place
--where the user postgres have access. In windows a flash drive usualy works
--fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.


--rozwiązanie problemu B)
create table kania.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

CREATE INDEX idx_tpi30_porto_rast_gist ON kania.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kania'::name,
'tpi30_porto'::name,'rast'::name);