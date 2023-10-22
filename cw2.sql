{\rtf1\ansi\ansicpg1250\cocoartf2709
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww18980\viewh13140\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 --4\
SELECT pp.* INTO tableB FROM popp as pp, majrivers as mr \
WHERE pp.f_codedesc='Building' \
AND ST_Distance(pp.geom,mr.geom)<1000;\
\
SELECT * FROM tableB;\
\
--5\
SELECT name, elev, geom \
INTO airportsNew \
FROM airports;\
SELECT * FROM airportsNew;\
\
--5a\
SELECT * FROM airportsNew \
	WHERE geom=(SELECT geom FROM airportsNew ORDER BY ST_Y(geom) LIMIT 1) OR geom=(SELECT geom FROM airportsNew ORDER BY ST_Y(geom) desc LIMIT 1);\
\
--5b\
INSERT INTO airportsNew VALUES\
(\
	'airportB',\
	(SELECT ABS(an1.elev - an2.elev)/2 FROM airportsNew as an1, airportsNew as an2 WHERE an1.name='NOATAK' AND an2.name='NIKOLSKI AS'),\
	ST_MakePoint(\
		(SELECT ST_X(an1.geom)-((ST_X(an1.geom)-ST_X(an2.geom))/2) FROM airportsNew as an1, airportsNew as an2 WHERE an1.name='NOATAK' AND an2.name='NIKOLSKI AS'),\
		(SELECT ST_Y(an1.geom)-((ST_Y(an1.geom)-ST_Y(an2.geom))/2) FROM airportsNew as an1, airportsNew as an2 WHERE an1.name='NOATAK' AND an2.name='NIKOLSKI AS')\
	)\
);\
\
--6\
SELECT ST_Area(ST_Buffer(ST_ShortestLine(lk.geom,ap.geom),1000)) \
FROM lakes AS lk, airports AS ap WHERE lk.names='Iliamna Lake' AND ap.name='AMBLER';\
\
--7\
SELECT tr.vegdesc AS tree_type, SUM(ST_Area(ST_Intersection(sp.geom,tr.geom))) AS swamp, SUM(ST_Area(ST_Intersection(td.geom,tr.geom))) AS tundra\
	FROM trees AS tr, swamp AS sp, tundra AS td WHERE ST_Intersects(tr.geom, sp.geom)=true or ST_Intersects(tr.geom, td.geom)=true GROUP BY tr.vegdesc;}