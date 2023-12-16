--USE ACUAMA_MELILLA;

UPDATE E SET eplmail='fjcapilla@sacyr.com'
OUTPUT INSERTED.*
FROm empleados AS E WHERE eplnom LIKE '%Francisco Javier Capilla%'

UPDATE E SET eplmail='hmohamed@sacyr.com'
OUTPUT INSERTED.*
FROm empleados AS E WHERE eplnom LIKE '%HOUSSEIN MOHAMED AISA%'