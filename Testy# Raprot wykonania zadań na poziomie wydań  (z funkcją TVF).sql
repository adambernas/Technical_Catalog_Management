--Tytu�: Testowy wariant raportu wyda� z procentowym podsumowaniem ich wykonania na podstawie zako�czonych zada�
--Opis:  Wykorzystuje funkcje tabelaryczn�
--Autor: Adam Berna�
--Update: 20-02-2022

/* Funkcja tabelaryczna TVF tworz�c� tabel� g��wn� do raportu. 
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

/* Tablica TaskQty sumuje liczb� otwartych oraz zamkni�tych zada� dla ka�dego dokumentu (wydania). Nie uwzgl�dnia zada� usuni�tych (IdTaskState = 6).
S�u�y do wyliczania procentu wykonanych zada� */

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


