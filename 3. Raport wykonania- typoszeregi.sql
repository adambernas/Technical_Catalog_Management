--Tytuł: Raport typoszeregów z podsumowaniem procentowym ich wykonania na podstawie zakończonych zadań w wydaniach.
--Autor: Adam Bernaś
--Update: 20-02-2022
--Version v1.3

/* Podgląd raportu:
SELECT * FROM dbo.View_LineReport
*/

USE TechnicalCatalogManagement
GO
--Usuń widok jeżeli istnieje
IF OBJECT_ID ('dbo.View_LineReport') IS NOT NULL DROP VIEW dbo.View_LineReport
GO

--Tworzenie widoku z opcją SCHEMABINDING oraz CHECK OPTION
CREATE VIEW dbo.View_LineReport
WITH SCHEMABINDING
AS

/* Tablica TaskQty sumuje liczbę otwartych oraz zamkniętych zadań dla każdego dokumentu (wydania). Nie uwzględnia zadań usuniętych (IdTaskState = 6).
Służy do wyliczania procentu wykonanych zadań */

With TaskQty as 
(
SELECT 
	T.ObjectId			as ObjectId, 
	COUNT(T.IdTask)		as TaskQty, 
	COUNT(TS.IsClosed)	as OpenTaskQty
FROM dbo.Task			as T
LEFT JOIN dbo.TaskState as TS
	ON T.IdTaskState = TS.IdTaskState
	AND TS.IsClosed = 0 
		WHERE T.IdTaskState <> 6
GROUP BY T.ObjectId ),

-- Tablica Tab z tabelą główną do raportu
Tab as
(
SELECT  
	D.IdDT, D.IdDoc, 
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
	a.DocumentValue as [Kod],
	b.DocumentValue as [Nazwa],
	c.DocumentValue as [Zakres],
	d.DocumentValue as [Producent],
	e.DocumentValue as [Grupa],
	AVG(f.PctEnd)   as [% wykonania typoszeregu]
FROM
-- Dane do kolumny [Kod wydania]
	(SELECT  
	IdDT, IdDoc, IdDTI, DocumentValue, CodeDTI FROM Tab
	WHERE CodeDTI = 'CODE_L')						as A
JOIN
-- Dane do kolumny [Nazwa]
	(SELECT  
	IdDT, IdDoc, IdDTI, DocumentValue, CodeDTI FROM Tab
	WHERE CodeDTI = 'NAME_L')						as B
ON a.IdDoc = b.IdDoc
JOIN
-- Dane do kolumny [Zakres]
	(SELECT  
	IdDT, IdDoc, IdDTI, DocumentValue, CodeDTI FROM Tab
	WHERE CodeDTI = 'SCOPE_L')						as C
ON b.IdDoc = c.IdDoc
JOIN
-- Dane do kolumny [Producent]
	(SELECT  
	IdDT, IdDoc, IdDTI, DocumentValue, CodeDTI FROM Tab
	WHERE CodeDTI = 'PRODUCER_L')					as D
ON c.IdDoc = d.IdDoc
JOIN
-- Dane do kolumny [Grupa]
	(SELECT  
	IdDT, IdDoc, IdDTI, DocumentValue, CodeDTI FROM Tab
	WHERE CodeDTI = 'GROUP_L')						as E
ON d.IdDoc = e.IdDoc
JOIN
-- Relacja w celu pozyskania kolumny Document.ObjectId które są przypisane tylko do wydań, kolumna ta służy do połączenia z tablicą TaskQty
	dbo.Document									as D2
	ON D2.IdDocRelation = e.IdDoc
JOIN 
/* Dane do kolumny [% wykonania]
Dzieli różnicę pomiędzy wszystkimi zadaniami a zadaniami otwartymi przez liczbę wszystkich zadań a następnie mnoży przez 100 uzyskując wynik procentowy */
	(SELECT TQ.ObjectId,TQ.OpenTaskQty,TQ.TaskQty, 
	(100 * (TQ.TaskQty - TQ.OpenTaskQty) / TQ.TaskQty) as PctEnd
	FROM TaskQty as TQ)								   as F
ON D2.ObjectId = f.ObjectId

--Grupowanie do uzyskania średniej dla całego wyposzeregu
GROUP BY 
a.DocumentValue,
b.DocumentValue,
c.DocumentValue,
d.DocumentValue,
e.DocumentValue

WITH CHECK OPTION;