/*
Tytu�: Testowy wariant tworzenia raportu wydania z podsumowaniem procentowym ich wykonania na podstawie zako�czonych zada�.
Opis: Tabela tworz�ca kolumny wpisana w tabele tymczasow�
Autor: Adam Berna�
Update: 20-02-2022
*/

IF OBJECT_ID('tempdb.dbo.#Alfa') IS NOT NULL DROP TABLE dbo.#Alfa;
GO

USE TechnicalCatalogManagement
GO

--Tworzenie tabeli tymczasowej przechowuj�cej okre�lone dane z zapytania ��cz�cego 3 tabele. Wykorzystana do tworzenia kolumn raportu g��wnego.
SELECT  
D.IdDT, D.IdDoc, D.ObjectId,
DI.IdDTI, DI.DocumentValue,
DTI.CodeDTI
INTO #Alfa
FROM Document			  as D
JOIN DocumentTemplateItem as DTI
	on D.IdDT = DTI.IdDT
JOIN DocumentItem		  as DI
	ON DI.IdDTI = DTI.IdDTI
	and DI.IdDoc = D.IdDoc;

/* Tablica TaskQty sumuje liczb� otwartych oraz zamkni�tych zada� dla ka�dego dokumentu (wydania). Nie uwzgl�dnia zada� usuni�tych (IdTaskState = 6).
Pozwala wyliczy� procent wykonanych zada�.
*/
WITH TaskQty as 
(
SELECT 
a.ObjectId		  as ObjectId, 
count(*)		  as TaskQty, 
count(b.IsClosed) as OpenTaskQty
FROM task as a
	LEFT JOIN taskState as b
	ON a.IdTaskState = b.IdTaskState
	and b.IsClosed = 0 
WHERE a.IdTaskState <> 6
GROUP BY a.ObjectId 
)

SELECT 
A.DocumentValue as [Kod],
B.DocumentValue as [Nazwa],
C.DocumentValue as [Zakres],
D.DocumentValue as [Producent],
E.DocumentValue as [Grupa],
F.DocumentValue as [Typoszereg],
G.PctEnd		as [% wykonania]
FROM
-- Dane do kolumny [Kod] Raportu g��wngo
	(SELECT * FROM #Alfa WHERE CodeDTI = 'CODE_R')	    as A
JOIN
-- Dane do kolumny [Nazwa] Raportu g��wngo
	(SELECT * FROM #Alfa WHERE CodeDTI = 'NAME_R')		as B
ON  a.IdDoc = b.IdDoc
JOIN
-- Dane do kolumny [Zakres] Raportu g��wngo
	(SELECT * FROM #Alfa WHERE CodeDTI = 'SCOPE_R')	    as C
ON b.IdDoc = c.IdDoc
JOIN
-- Dane do kolumny [Producent] Raportu g��wngo
	(SELECT * FROM #Alfa WHERE CodeDTI = 'PRODUCER_R')  as D
ON c.IdDoc = d.IdDoc
JOIN
-- Dane do kolumny [Grupa] Raportu g��wngo
	(SELECT * FROM #Alfa WHERE CodeDTI = 'GROUP_R')		as E
ON d.IdDoc = e.IdDoc
JOIN
-- Dane do kolumny [Typoszereg] Raportu g��wngo
	(SELECT * FROM #Alfa WHERE CodeDTI = 'NAME_LINE_R') as F
ON e.IdDoc = f.IdDoc
JOIN
/* Dane do kolumny [% wykonania] Raportu g��wngo. 
Dzieli r�wnic� pomi�dzy wszystkimi zadaniami a zadaniami otwartymi przez liczb� wszystkich zada� a nast�pnie mno�y przez 100 uzyskuj�c wynik procentowy */
(SELECT *,(100 * (TQ.TaskQty - TQ.OpenTaskQty) / TQ.TaskQty) as PctEnd
FROM TaskQty as TQ)											 as G
ON f.ObjectId = g.ObjectId