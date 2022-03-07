/*
Tytu³: Testowy wariant tworzenia raportu wydania z podsumowaniem procentowym ich wykonania na podstawie zakoñczonych zadañ.
Opis: Raport oparty na tabelach tymczasowych
Autor: Adam Bernaœ
Update: 26-09-2021
*/

IF OBJECT_ID('tempdb.dbo.#Alfa') IS NOT NULL DROP TABLE dbo.#Alfa;
IF OBJECT_ID('tempdb.dbo.#Tab1') IS NOT NULL DROP TABLE dbo.#Tab1;
IF OBJECT_ID('tempdb.dbo.#Tab2') IS NOT NULL DROP TABLE dbo.#Tab2;
IF OBJECT_ID('tempdb.dbo.#Tab3') IS NOT NULL DROP TABLE dbo.#Tab3;
IF OBJECT_ID('tempdb.dbo.#Tab4') IS NOT NULL DROP TABLE dbo.#Tab4;
IF OBJECT_ID('tempdb.dbo.#Tab5') IS NOT NULL DROP TABLE dbo.#Tab5;
IF OBJECT_ID('tempdb.dbo.#Tab6') IS NOT NULL DROP TABLE dbo.#Tab6;
IF OBJECT_ID('tempdb.dbo.#Tab7') IS NOT NULL DROP TABLE dbo.#Tab7;
GO

USE TechnicalCatalogManagement
GO

SELECT  
D.IdDT, D.IdDoc, D.ObjectId,
DI.IdDTI, DI.DocumentValue,
DTI.CodeDTI
INTO #Alfa
from Document			  as D
join DocumentTemplateItem as DTI
	on D.IdDT = DTI.IdDT
join DocumentItem		  as DI
	ON DI.IdDTI = DTI.IdDTI
	and DI.IdDoc = D.IdDoc

select *
INTO #Tab1
from #Alfa
where CodeDTI = 'CODE_R';

select *
INTO #Tab2
from #Alfa
where CodeDTI = 'NAME_R';

select *
INTO #Tab3
from #Alfa
where CodeDTI = 'SCOPE_R';

select *
INTO #Tab4
from #Alfa
where CodeDTI = 'PRODUCER_R';

select *
INTO #Tab5
from #Alfa
where CodeDTI = 'GROUP_R';

select *
INTO #Tab6
from #Alfa
where CodeDTI = 'NAME_LINE_R';

With X as 
(
SELECT 
a.ObjectId		  as ObjectId, 
count(*)		  as TaskQty, 
count(b.IsClosed) as OpenTaskQty
FROM task as a
	left join taskState as b
	ON a.IdTaskState = b.IdTaskState
	and b.IsClosed = 0 
WHERE a.IdTaskState <> 6
GROUP BY a.ObjectId )
SELECT *, (100 * (x.TaskQty - x.OpenTaskQty) / x.TaskQty) as PctEnd
INTO #Tab7
FROM X;

select
a.DocumentValue as [Kod],
b.DocumentValue as [Nazwa],
c.DocumentValue as [Zakres],
d.DocumentValue as [Producent],
e.DocumentValue as [Grupa],
f.DocumentValue as [Typoszereg],
g.PctEnd		as [% wykonania]

from #Tab1 as a
join #Tab2 as b
	on a.IdDoc = b.IdDoc
join #Tab3 as c
	on b.IdDoc = c.IdDoc
join #Tab4 as d
	on c.IdDoc = d.IdDoc
join #Tab5 as e
	on d.IdDoc = e.IdDoc
join #Tab6 as f
	on e.IdDoc = f.IdDoc
join #Tab7 as g
	on f.ObjectId = g.ObjectId
