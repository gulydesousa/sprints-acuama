ALTER TABLE dbo.remesasTrab
ADD remTskType SMALLINT NULL;

ALTER TABLE dbo.remesasTrab
ADD remTskNumber INT NULL;

ALTER TABLE dbo.remesasTrab
ADD CONSTRAINT FK_remesasTrab_TaskSchedule 
FOREIGN KEY (remUsrCod, remTskType, remTskNumber) 
REFERENCES Task_Schedule(tskUser, tskType, tskNumber);

