--Tytuł: Raport wydań z procentowym podsumowaniem wykonania na podstawie zakończonych zadań.
--Autor: Adam Bernaś
--Update: 20-02-2022
--Version v1.3

/*Podgląd raportu
SELECT * FROM dbo.View_ReleaseReport
*/

USE TechnicalCatalogManagement
GO
--Usuń widok jeżeli istnieje
IF OBJECT_ID ('dbo.View_ReleaseReport') IS NOT NULL DROP VIEW dbo.View_ReleaseReport
GO

--Tworzenie widoku z opcją SCHEMABINDING oraz CHECK OPTION

CREATE VIEW dbo.View_ReleaseReport
WITH SCHEMABINDING
AS

/* Tablica TaskQty sumuje liczbę otwartych oraz zamkniętych zadań dla każdego dokumentu (wydania). Nie uwzględnia zadań usuniętych (IdTaskState = 6).
Służy do wyliczania procentu wykonanych zadań */

WITH TaskQty as 
(
SELECT 
	T.ObjectId		    as ObjectId, 
	COUNT(T.IdTask)		as TaskQty, 
	COUNT(TS.IsClosed)  as OpenTaskQty
FROM dbo.Task		    as T
LEFT JOIN dbo.TaskState as TS
	ON T.IdTaskState = TS.IdTaskState
	AND TS.IsClosed = 0 
		WHERE T.IdTaskState <> 6
GROUP BY T.ObjectId
),

--Tablica Tab z tabelą główną do raportu
Tab as
(
SELECT  
	D.IdDT, D.IdDoc, D.ObjectId,
	DI.IdDTI, DI.DocumentValue,
	DTI.CodeDTI
FROM dbo.Document			  as D
JOIN dbo.DocumentTemplateItem as DTI
	ON D.IdDT = DTI.IdDT
JOIN dbo.DocumentItem		  as DI
	ON DI.IdDTI = DTI.IdDTI
	AND DI.IdDoc = D.IdDoc
)
-- Tworzenie Raportu głównego
SELECT 
A.DocumentValue as [Kod wydania],
B.DocumentValue as [Nazwa],
C.DocumentValue as [Zakres],
D.DocumentValue as [Producent],
E.DocumentValue as [Grupa],
F.DocumentValue as [Typoszereg],
G.PctEnd		as [% wykonania]
FROM
-- Dane do kolumny [Kod wydania]
	(SELECT IdDT, IdDoc, ObjectId, IdDTI, DocumentValue, CodeDTI FROM Tab 
	 WHERE CodeDTI = 'CODE_R')													as A
JOIN
-- Dane do kolumny [Nazwa]
	(SELECT IdDT, IdDoc, ObjectId, IdDTI, DocumentValue, CodeDTI FROM Tab 
	 WHERE CodeDTI = 'NAME_R')													as B
ON  a.IdDoc = b.IdDoc
JOIN
-- Dane do kolumny [Zakres]
	(SELECT IdDT, IdDoc, ObjectId, IdDTI, DocumentValue, CodeDTI FROM Tab 
	 WHERE CodeDTI = 'SCOPE_R')													as C
ON b.IdDoc = c.IdDoc
JOIN
-- Dane do kolumny [Producent]
	(SELECT IdDT, IdDoc, ObjectId, IdDTI, DocumentValue, CodeDTI FROM Tab
	 WHERE CodeDTI = 'PRODUCER_R')												as D
ON c.IdDoc = d.IdDoc
JOIN
-- Dane do kolumny [Grupa]
	(SELECT IdDT, IdDoc, ObjectId, IdDTI, DocumentValue, CodeDTI FROM Tab
	 WHERE CodeDTI = 'GROUP_R')													as E
ON d.IdDoc = e.IdDoc
JOIN
-- Dane do kolumny [Typoszereg]
	(SELECT IdDT, IdDoc, ObjectId, IdDTI, DocumentValue, CodeDTI FROM Tab
	 WHERE CodeDTI = 'NAME_LINE_R')												as F
ON e.IdDoc = f.IdDoc
JOIN
/* Dane do kolumny [% wykonania]
Dzieli różnicę pomiędzy wszystkimi zadaniami a zadaniami otwartymi przez liczbę wszystkich zadań a następnie mnoży przez 100 uzyskując wynik procentowy */
	(SELECT TQ.ObjectId, TQ.TaskQty, TQ.OpenTaskQty, 
	(100 * (TQ.TaskQty - TQ.OpenTaskQty) / TQ.TaskQty)							as PctEnd
	FROM TaskQty as TQ)															as G
ON f.ObjectId = g.ObjectId

WITH CHECK OPTION;

