--+++++++++++++++++++
SELECT *
--UPDATE T SET trvfechafin='20221231' 
FROM tarval AS T  WHERE trvsrvcod=20 and trvtrfcod IN (101, 201, 8501, 301, 401, 501, 601, 701, 1001) AND trvfecha='20150501' AND trvfechafin='20150502' ;


SELECT *
--UPDATE T SET trvfecha='20230101'
FROM tarval AS T  WHERE trvsrvcod=20 and trvtrfcod IN (101, 201, 8501, 301, 401, 501, 601, 701, 1001) AND trvfechafin IS NULL AND trvfecha='20150503';

--+++++++++++++++++++
SELECT *
--UPDATE T SET trvfechafin='20221231' 
FROM tarval AS T  WHERE trvsrvcod=20 and trvtrfcod IN (801) AND trvfecha='20150315' AND trvfechafin='20150316' ;


SELECT *
--UPDATE T SET trvfecha='20230101'
FROM tarval AS T  WHERE trvsrvcod=20 and trvtrfcod IN (801) AND trvfechafin IS NULL AND trvfecha='20150317';