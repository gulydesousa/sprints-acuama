CREATE FUNCTION [dbo].[fBlanquearCaracteresEspeciales](@String NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @MatchExpression VARCHAR(255) =  '%[^abcdefghijklmnñopqrstuvwxyz0-9 ]%';
    
    WHILE PatIndex(@MatchExpression, @String) > 0
        SET @String = Stuff(@String, PatIndex(@MatchExpression, @String), 1, ' ');
    
	SET @String = REPLACE(@String, 'Ñ', 'N');	
    RETURN @String
    
END