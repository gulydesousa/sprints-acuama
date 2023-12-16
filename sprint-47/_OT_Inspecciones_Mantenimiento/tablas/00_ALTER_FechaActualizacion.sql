--SELECT * FROM otInspecciones_Melilla

IF NOT EXISTS(
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'otInspecciones_Melilla' AND COLUMN_NAME = 'FechaActualizacion'
)
BEGIN
    ALTER TABLE otInspecciones_Melilla
    ADD FechaActualizacion DATETIME NULL;
END