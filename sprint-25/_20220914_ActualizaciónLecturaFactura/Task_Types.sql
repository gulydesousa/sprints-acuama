
ALTER TABLE Task_Types
ADD  tskTOverlapping BIT NOT NULL
CONSTRAINT DF_tskTOverlapping DEFAULT (1);

--UPDATE T SET tskTOverlapping = 0 FROM Task_Types AS T WHERE tskTType IN (40, 630) 

--SELECT * FROM Task_Types

