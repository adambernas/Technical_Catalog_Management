USE TechnicalCatalogManagement
GO
--Usuñ widok jeœli istnieje
IF OBJECT_ID('View_TaskReport') IS NOT NULL DROP VIEW View_TaskReport
GO

--Skrót do podgl¹du widoku
/*
SELECT * FROM View_TaskReport
*/

--Tworzenie widoku z opcj¹ SCHEMABINDING oraz CHECK OPTION
CREATE VIEW View_TaskReport WITH SCHEMABINDING
AS

--Tworzenie tablicy ³¹cz¹cej potrzebne tabele
WITH Tab AS
(
SELECT	
		D.ObjectId						as Numer_dok,
		DI.DocumentValue				as Typoszereg,
		D.DocName						as Nazwa_dok,
		TS2.Name						as Status_dok,
		T.Name							as Nazwa_zadania,
		TS.Name							as Status_zadania
FROM dbo.Document						as D
LEFT JOIN dbo.Task						as T
	ON D.ObjectId = T.ObjectId
LEFT JOIN dbo.TaskState					as TS
	ON T.IdTaskState = TS.IdTaskState
JOIN dbo.TaskState as TS2
	ON TS2.IdTaskState = D.IdDocState
JOIN dbo.DocumentItem					as DI
	ON D.IdDoc = DI.IdDoc
		WHERE DI.IdDTI = 11
)
SELECT  Numer_dok,
		Typoszereg, 
		Nazwa_dok, 
		ISNULL(Status_dok,'') as Status_dok, 
		ISNULL(IIF(Status_dok = 'Nowy','Zadania nie zosta³y wygenerowane',Nazwa_zadania),'') as Nazwa_zadania, 
		ISNULL(Status_zadania,'')  as Status_zadania
FROM Tab

WITH CHECK OPTION;

/*
Alternatywnie aby zrezygnowaæ z JOINA DocumentItem by stworzyæ kolumne 'Typoszereg' mo¿na wyci¹gn¹æ kod typoszeregu z kolumny 'Nazwa_dok'
Przyk³ad metody poni¿ej. W testach poprawia wydajnoœc wzglêdem podstawowej wersji ale kod jest mniej czytelny.

LEFT( (RIGHT(DocName,CHARINDEX(' ',DocName,1))), (CHARINDEX('-',(RIGHT(DocName,CHARINDEX(' ',DocName,1)-1))))) as Typoszereg 
*/