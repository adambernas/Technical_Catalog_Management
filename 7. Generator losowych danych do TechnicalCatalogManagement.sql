--Tytuł: Generator losowych danych do bazy TechnicalCatalogManagement
--Opis: Procedura tworzy losowe typoszeregi z gotowymi wydaniami o losowym statusie i losowym zakresem oraz gotową listą zadań o losowym statusie.
--		Do określonych producentów przypisywane są tylko te określone grupy produktów zgodnie z ich porfolio.
--Autor: Adam Bernaś
--Update: 27-02-2022
--Wersja: 1.3

--Skrót do obsługi procedury

/*
exec AddNewDataForBaseTCM
GO "tu wprowadź liczbę nowych typoszeregów do wygenerowania"
*/

--Usuń procedure jeżeli istnieje
IF OBJECT_ID ('dbo.AddNewDataForBaseTCM') IS NOT NULL 
   DROP PROC dbo.AddNewDataForBaseTCM
GO
--Tworzenie procedury
CREATE PROC AddNewDataForBaseTCM

--Zmienne na atrybuty do tabeli Document
	@IdDoc_LINE as INT = NULL,				 --Id typoszeregu
	@IdDoc_RELEASE as INT = NULL,		   	 --Id wydania
	@IdDT_LINE as INT = 1,					 --szablon dokumentu typoszereg
	@IdDT_RELEASE as INT = 2,				 --szablon dokumentu wydanie
	@DocName_LINE as nvarchar(40) = NULL,	 --nazwa typoszeregu
	@DocName_RELEASE as nvarchar(40) = NULL, --nazwa wydania
	@IdDocState as INT = NULL,				 --stan wydania (losowy) od 1 do 6
	@ObjectId as nvarchar(10) = NULL,		 --numer dokumentu wydania
	@ObjectIdLine as nvarchar(10) = NULL,	 --numer dokumentu typoszeregu

--Zmienne na atrybuty do tabeli DocumentItem
	@DocumentValueId_1 as nvarchar(20) = NULL, --kod typoszeregu
	@DocumentValueId_2 as nvarchar(20) = NULL, --nazwa typoszeregu
	@DocumentValueId_3 as nvarchar(20) = NULL, --zakres domyślny
	@DocumentValueId_4 as nvarchar(20) = NULL, --producent
	@DocumentValueId_5 as nvarchar(20) = NULL, --grupa
	@DocumentValueId_6 as nvarchar(20) = NULL, --kod wydania
	@DocumentValueId_7 as nvarchar(20) = NULL, --nazwa wydania
	@YearUP as INT = 2010,					   --bieżący rok do generowania wydania
	@YearDOWN as INT = NULL					   --początkowy rok do generowania wydania

AS
BEGIN TRAN
	BEGIN TRY

SET NOCOUNT ON
--Generowanie losowych statusów zadań i wydania
SET @IdDocState = (SELECT TOP 1 TS.IdTaskState FROM TaskState as TS ORDER BY NEWID()); 

--Generator losowego kodu typoszeregu
SET	@DocumentValueId_2= (SELECT															   
	substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ',cast(((rand()*27))as INT),1)+
	substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ',cast(((rand()*27))as INT),1)+
	substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ',cast(((rand()*27))as INT),1))

SET @YearDOWN = year(GETDATE());

--Generowanie losego roku w przedziale od 2010 do roku bieżacego
SET @DocumentValueId_7 = ROUND(((@YearUP - @YearDOWN-1) * RAND() + @YearDOWN ),0);	

-- Generowanie losowego prodcenta z listy
SET @DocumentValueId_4 = (SELECT TOP 1 [value] FROM DictionaryItem WHERE IdDict = 2 ORDER BY NEWID()); 

--Generowanie kodu typoszeregu
SET @DocumentValueId_1 = (SELECT DI.CodeValue FROM DictionaryItem as DI						   
WHERE DI.Value = @DocumentValueId_4) + '-' + @DocumentValueId_2;

-- Generowanie losowego zakresu z listy
SET @DocumentValueId_3 = (SELECT TOP 1 [value] FROM DictionaryItem WHERE IdDict = 1 ORDER BY NEWID()); 

-- Generowanie losowej określonej grupy którą spełniają producenci
IF @DocumentValueId_4 IN ('Danfoss', 'Frascold', 'Copeland', 'Cubigel')
	SET @DocumentValueId_5 = (SELECT TOP 1 [value] FROM DictionaryItem WHERE IdDicItem IN (5, 8) 
							  ORDER BY NEWID()) --(Sprężarka, Agregat)
ELSE IF @DocumentValueId_4 IN ('Mitsubishi', 'LG', 'Samsung')
	SET @DocumentValueId_5 = (SELECT TOP 1 [value] FROM DictionaryItem WHERE IdDicItem IN (14, 15, 17) 
							 ORDER BY NEWID()) --(Klimatyzacja, Pompa ciepła, Systemy VRF)
ELSE IF @DocumentValueId_4 IN ('ECO', 'Thermofin', 'Alfa-Laval')
	SET @DocumentValueId_5 = (SELECT TOP 1 [value] FROM DictionaryItem WHERE IdDicItem IN (16, 20) 
							  ORDER BY NEWID()); --(Chłodnice powietrza, Skraplacze)
--Generowanie kodu wydania
SET @DocumentValueId_6 = (SELECT DictionaryItem.CodeValue FROM DictionaryItem WHERE DictionaryItem.Value = @DocumentValueId_4) 
	+ '-' + @DocumentValueId_2 + '-' + @DocumentValueId_7;

--Generowanie nazwy typoszeregu
SET @DocName_LINE = (SELECT NameDT FROM DocumentTemplate WHERE IdDT = 1) + '-' 
	+ cast(@DocumentValueId_4 as nvarchar(20)) + '-' + cast(@DocumentValueId_2 as nvarchar(20));

--Generowanie nazwy wydania
SET @DocName_RELEASE = (SELECT NameDT FROM DocumentTemplate WHERE IdDT = 2) 
	+ '-' + cast(@DocumentValueId_4 as nvarchar(20)) + '-' + cast(@DocumentValueId_2 as nvarchar(20)) + '-'+ @DocumentValueId_7;

--Dodanie nowego typoszeregu
INSERT INTO 
	dbo.Document(IdDT, DocName, ObjectId)
VALUES
	(@IdDT_LINE, @DocName_LINE, @ObjectIdLine)

SET @IdDoc_LINE = SCOPE_IDENTITY()
SET @ObjectIdLine = 'DOC'+ CAST(@IdDoc_LINE as nvarchar(15));

-- Generowanie nazwy dokumentu stworzonego typoszeregu
UPDATE dbo.Document
SET dbo.Document.ObjectId = @ObjectIdLine
WHERE dbo.Document.IdDoc = @IdDoc_LINE;

--Dodanie wydania do stworzonego typoszeregu
INSERT INTO 
	dbo.Document(IdDT, DocName, IdDocState, IdDocRelation)
VALUES
	(@IdDT_RELEASE, @DocName_RELEASE, @IdDocState, @IdDoc_LINE)

SET @IdDoc_RELEASE = SCOPE_IDENTITY();
SET @ObjectId = 'DOC'+ CAST(@IdDoc_RELEASE as nvarchar(15))

-- W typoszeregu może być kilka wydań więc nie można przypisać 1 relacji jak przy wydaniu

-- Generowanie nazwy dokumentu stworzonego wydania
UPDATE dbo.Document
SET dbo.Document.ObjectId = @ObjectId
WHERE dbo.Document.IdDoc = @IdDoc_RELEASE;

-- Wypełnianie pola szablonu dokumentu
INSERT INTO
	dbo.DocumentItem(IdDTI, IdDoc, DocumentValue)
VALUES
	(1,  @IdDoc_LINE, @DocumentValueId_1),
	(2,  @IdDoc_LINE, @DocumentValueId_2),
	(3,  @IdDoc_LINE, @DocumentValueId_3),
	(4,  @IdDoc_LINE, @DocumentValueId_4),
	(5,  @IdDoc_LINE, @DocumentValueId_5),
	(6,  @IdDoc_RELEASE, @DocumentValueId_6),
	(7,  @IdDoc_RELEASE, @DocumentValueId_7),
	(8,  @IdDoc_RELEASE, @DocumentValueId_3),
	(9,  @IdDoc_RELEASE, @DocumentValueId_4),
	(10, @IdDoc_RELEASE, @DocumentValueId_5),
	(11, @IdDoc_RELEASE, @DocumentValueId_2);

--Utworzenie zadań do wydania w zależności od zakresu 
--Zadania mogą być w procesie gdy stan dokumentu jest: (2-Realizowany, 3-Wstrzymany, 5-Wykonany)
IF 
	@IdDT_RELEASE = 2 and 
	@IdDocState in (2,3,5)
BEGIN
	DECLARE @CodeScope nvarchar(15)
	DECLARE @TaskName nvarchar(60) 
	DECLARE AddNewTask CURSOR FAST_FORWARD FOR
	SELECT CodeScope, TaskName
	FROM TasksList

	OPEN AddNewTask
	FETCH NEXT FROM AddNewTask 
	INTO @CodeScope, @TaskName
	WHILE @@FETCH_STATUS=0
BEGIN
IF  
	@CodeScope = 
	(SELECT CodeValue 
	 FROM DictionaryItem 
	 WHERE [Value] = @DocumentValueId_3)
BEGIN
	INSERT INTO Task(IdTaskState, ObjectId, Name)
	VALUES( (SELECT TOP 1 TS.IdTaskState FROM TaskState as TS ORDER BY NEWID()),
						  @ObjectId, @TaskName + @DocumentValueId_6)
END
	FETCH NEXT FROM AddNewTask INTO @CodeScope, @TaskName
END
	CLOSE AddNewTask
	DEALLOCATE AddNewTask
END

	END TRY

-- Obsługa błędu z wycofaniem transakcji i opisem błędu
BEGIN CATCH 

IF ERROR_NUMBER() <> 0
	BEGIN
		ROLLBACK TRAN
	END

PRINT 'Numer błędu    : ' + CAST(ERROR_NUMBER() as varchar(30));
PRINT 'Komunikat błędu: ' + ERROR_MESSAGE();
PRINT 'Ważność błędu  : ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
PRINT 'Stan błędu     : ' + CAST(ERROR_STATE() AS VARCHAR(10));
PRINT 'Wiersz błędu   : ' + CAST(ERROR_LINE() AS VARCHAR(10));

END CATCH
--Koniec transakcji
COMMIT TRAN
