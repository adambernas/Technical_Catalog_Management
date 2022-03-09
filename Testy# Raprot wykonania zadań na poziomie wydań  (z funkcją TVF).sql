--Tytuł: Testowy wariant raportu wydań z procentowym podsumowaniem ich wykonania na podstawie zakończonych zadań
--Opis:  Wykorzystuje funkcje tabelaryczną
--Autor: Adam Bernaś
--Update: 20-02-2022

/* Funkcja tabelaryczna TVF tworzącą tabelą główną do raportu. 
USE TechnicalCatalogManagement
GO
CREATE FUNCTION dbo.GetTableInReportPCLINE
( @CODE as varchar(15) )
RETURNS TABLE
AS
RETURN
SELECT  
D.IdDT, D.IdDoc, D.ObjectId,
DI.IdDTI, DI.DocumentValue,
DTI.CodeDTI
FROM Document			    as D
JOIN DocumentTemplateItem   as DTI
	ON D.IdDT = DTI.IdDT
JOIN DocumentItem		    as DI
	ON DI.IdDTI = DTI.IdDTI
	and DI.IdDoc = D.IdDoc
	and DTI.CodeDTI = @CODE
*/

USE TechnicalCatalogManagement
GO

/* Tablica TaskQty sumuje liczbę otwartych oraz zamkniętych zadań dla każdego dokumentu (wydania). Nie uwzględnia zadań usuniętych (IdTaskState = 6).
Służy do wyliczania procentu wykonanych zadań */

WITH TaskQty as 
(
SELECT 
	Task.ObjectId			  as ObjectId, 
	COUNT(*)				  as TaskQty, 
	COUNT(TaskState.IsClosed) as OpenTaskQty
FROM dbo.Task
	LEFT JOIN dbo.TaskState
ON Task.IdTaskState = TaskState.IdTaskState
	AND TaskState.IsClosed = 0 
WHERE Task.IdTaskState <> 6
GROUP BY Task.ObjectId
)

SELECT
A.DocumentValue as [Kod],
B.DocumentValue as [Nazwa],
C.DocumentValue as [Zakres],
D.DocumentValue as [Producent],
E.DocumentValue as [Grupa],
F.DocumentValue as [Typoszereg],
G.PctEnd		as [% wykonania]

FROM dbo.GetTableInReportPCLINE	   ('CODE_R')	   as A
	JOIN dbo.GetTableInReportPCLINE('NAME_R')	   as B
ON a.IdDoc = b.IdDoc
	JOIN dbo.GetTableInReportPCLINE('SCOPE_R')	   as C
ON b.IdDoc = c.IdDoc
	JOIN dbo.GetTableInReportPCLINE('PRODUCER_R')  as D
ON c.IdDoc=d.IdDoc
	JOIN dbo.GetTableInReportPCLINE('GROUP_R')	   as E
ON d.IdDoc = e.IdDoc
	JOIN dbo.GetTableInReportPCLINE('NAME_LINE_R') as F
ON e.IdDoc = f.IdDoc
	JOIN 
	(SELECT TQ.ObjectId, TQ.TaskQty, TQ.OpenTaskQty,
	(100 * (TQ.TaskQty - TQ.OpenTaskQty) / TQ.TaskQty) as PctEnd 
	 FROM TaskQty as TQ)							   as G
ON f.ObjectId = g.ObjectId


