--DROP  TYPE [Indicadores].[tIndicadores_Semanal]

CREATE TYPE [Indicadores].[tIndicadores_Semanal] AS TABLE(
	[SEMANA] [INT] NOT NULL,
	[F.Desde] DATE NOT NULL,
	[F.Hasta] DATE NOT NULL,
	[I081] INT,
	[I085] INT,
	[I087] INT,
	[I088] INT,
	[I150] INT,
	[I152] INT
)
GO
