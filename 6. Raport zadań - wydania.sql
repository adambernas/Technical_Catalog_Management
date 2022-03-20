--Tytuł: Raport wszystkich zadań w wydaniach
--Autor: Adam Bernaś
--Update: 03-03-2022
--Version v1.1

--Podglądu widoku
/*
SELECT * FROM View_TaskReport
*/

USE TechnicalCatalogManagement
GO
--Usuń widok jeśli istnieje
IF OBJECT_ID('View_TaskReport') IS NOT NULL DROP VIEW View_TaskReport
GO

--Tworzenie widoku z opcją SCHEMABINDING oraz CHECK OPTION
CREATE VIEW View_TaskReport WITH SCHEMABINDING
AS

--Tworzenie tablicy łączącej potrzebne tabele
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
		ISNULL(IIF(Status_dok = 'Nowy','Zadania nie zostały wygenerowane',Nazwa_zadania),'') as Nazwa_zadania, 
		ISNULL(Status_zadania,'')  as Status_zadania
FROM Tab

WITH CHECK OPTION;

/*
Alternatywnie aby zrezygnować z JOINA DocumentItem by stworzyć kolumne 'Typoszereg' można wyciągnąć kod typoszeregu z kolumny 'Nazwa_dok'
Przykład metody poniżej. W testach poprawia wydajnośc względem podstawowej wersji ale kod jest mniej czytelny.

LEFT( (RIGHT(DocName,CHARINDEX(' ',DocName,1))), (CHARINDEX('-',(RIGHT(DocName,CHARINDEX(' ',DocName,1)-1))))) as Typoszereg 
*/