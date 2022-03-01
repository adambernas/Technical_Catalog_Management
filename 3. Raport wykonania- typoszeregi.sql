--Tytu³: Raport typoszeregów z podsumowaniem procentowym ich wykonania na podstawie zakoñczonych zadañ w wydaniach.
--Autor: Adam Bernaœ
--Update: 20-02-2022
--Version v1.3

/* Podgl¹d raportu:
SELECT * FROM dbo.View_LineReport
*/

USE TechnicalCatalogManagement
GO
--Usuñ widok je¿eli istnieje
IF OBJECT_ID ('dbo.View_LineReport') IS NOT NULL DROP VIEW dbo.View_LineReport
GO

--Tworzenie widoku z opcj¹ SCHEMABINDING oraz CHECK OPTION
CREATE VIEW dbo.View_LineReport
WITH SCHEMABINDING
AS

/* Tablica TaskQty sumuje liczbê otwartych oraz zamkniêtych zadañ dla ka¿dego dokumentu (wydania). Nie uwzglêdnia zadañ usuniêtych (IdTaskState = 6).
S³u¿y do wyliczania procentu wykonanych zadañ */

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

-- Tablica Tab z tabel¹ g³ówn¹ do raportu
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
-- Tworzenie Raportu g³ównego
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
-- Relacja w celu pozyskania kolumny Document.ObjectId które s¹ przypisane tylko do wydañ, kolumna ta s³u¿y do po³¹czenia z tablic¹ TaskQty
	dbo.Document									as D2
	ON D2.IdDocRelation = e.IdDoc
JOIN 
/* Dane do kolumny [% wykonania]
Dzieli ró¿nicê pomiêdzy wszystkimi zadaniami a zadaniami otwartymi przez liczbê wszystkich zadañ a nastêpnie mno¿y przez 100 uzyskuj¹c wynik procentowy */
	(SELECT TQ.ObjectId,TQ.OpenTaskQty,TQ.TaskQty, 
	(100 * (TQ.TaskQty - TQ.OpenTaskQty) / TQ.TaskQty) as PctEnd
	FROM TaskQty as TQ)								   as F
ON D2.ObjectId = f.ObjectId

--Grupowanie do uzyskania œredniej dla ca³ego wyposzeregu
GROUP BY 
a.DocumentValue,
b.DocumentValue,
c.DocumentValue,
d.DocumentValue,
e.DocumentValue

WITH CHECK OPTION;