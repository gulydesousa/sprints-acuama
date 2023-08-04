--UPDATE T SET tskTOverlapping = 0 FROM Task_Types AS T WHERE tskTType IN (20, 40, 630) 

UPDATE T SET tskTOverlapping = 0 FROM Task_Types AS T WHERE tskTType IN (40) 
UPDATE T SET tskTOverlapping = 0 FROM Task_Types AS T WHERE tskTType IN (630) 

--SELECT * FROM Task_Types
