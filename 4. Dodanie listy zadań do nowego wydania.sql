--Tytu³: Generowanie listy zadañ do wydania o statusie dokumentu "Nowy"
--Opis:	Procedura po zmianie statusu dokumentu z "Nowy" na "Realizowany" generuje 
--      odpowiedni¹ pulê zadañ na podstawie domyslnego zakresu typoszeregu.
--Autor: Adam Bernaœ
--Update: 27-02-2022
--Wersia: 1.4

--Skrót do obs³ugi procedury (Zmienne w aplikacji s¹ obs³ugiwane poprzez interfejs graficzny)
/*
@IdDoc		- Podaj istniej¹cy numer Id dokumentu wydania
@IdDocState - Podaj status dokumentu od 1 do 6
			  (1 -Nowy, 2 -Realizowane, 3 -Wstrzymane, 4 -Odrzucony, 5 -Wykonany, 6-Usuniête)*/
/*
exec dbo.AddTask
@IdDoc = 12,		   
@IdDocState = 2			
*/

USE TechnicalCatalogManagement
GO
--Usuñ procedure je¿eli istnieje
IF OBJECT_ID ('dbo.AddTask') IS NOT NULL DROP PROC dbo.AddTask
GO

--Tworzenie procedury
CREATE PROC dbo.AddTask

--Deklarowanie zmiennych

--Zmienne wprowadzane przez u¿ytkownika
@IdDoc as INT = NULL,   
@IdDocState as INT = NULL,		
			   
--Zmienne generowane przez procedure
--zakresu wydania			   
@StateName as nvarchar(10) = NULL,	
--numer dokumentu		   
@ObjectId as nvarchar(10) = NULL,
--szablon dokumentu (1 typoszereg, 2 wydanie)
@CodeDT as nvarchar(15) = NULL,
--kod wydania		   
@DocumentValueId_6 as nvarchar(20) = NULL
AS
--Otwarcie bloku do obs³ugi b³êdów
BEGIN TRY

--Rozpoczêcie transakcji
BEGIN TRAN

--Przypisanie numeru dokumentu do zmiennej na podstawie numeru wydania
SET @ObjectId =			
	(SELECT ObjectId 
	 FROM dbo.Document 
	 WHERE IdDoc = @IdDoc); 

--Przypisanie zakresu wydania z domyœlnego zakresu typoszeregu
SET @StateName =
	(	SELECT DocumentValue 
		FROM DocumentItem		  as DI
		JOIN DocumentTemplateItem as DTI
			ON DI.IdDTI = DTI.IdDTI
			WHERE DI.IdDoc = 
				(SELECT D.IdDocRelation 
				FROM Document	  as D
				WHERE D.IdDoc = @IdDoc)
			AND DTI.CodeDTI = 'SCOPE_L'
	);

--Weryfikacja czy wskazany numer id dokumentu wydania istnieje
IF NOT EXISTS  
	(SELECT IdDoc FROM dbo.Document 
	 WHERE IdDoc = @IdDoc)
BEGIN
	ROLLBACK TRAN
	PRINT 'B£¥D: Nie ma takiego numeru dokumentu'
	RETURN
END;

--Weryfikacja wprowadzenia poprawnej zmiennej @StateName
IF NOT EXISTS 
	(SELECT [Value] FROM dbo.DictionaryItem 
	 WHERE  [Value] = @StateName and 
		    CodeValue IN ('FULL', 'BASIC', 'DESC'))
BEGIN
	ROLLBACK TRAN
	PRINT 'B£¥D: Podano b³êdny zakres wydania'
	RETURN
END; 

--Weryfikacja czy wskazane wydanie ma ju¿ wygenerowan¹ listê zadañ
IF EXISTS 
   (SELECT ObjectId FROM dbo.Task
    WHERE ObjectId = @ObjectId)
BEGIN
	ROLLBACK TRAN
	PRINT 'B£¥D: Dla tego dokumentu ju¿ zosta³y wygenerowane zadania'
	RETURN
END;

--Przypisanie zmiennej Id szablonu dokumentu
SET @CodeDT =					
		(SELECT DT.CodeDT								
		FROM dbo.Document		  as D 
		JOIN dbo.DocumentTemplate as DT 
			ON D.IdDT=DT.IdDT
				WHERE D.IdDoc = @IdDoc);

--Weryfikacja czy wskazany dokument nie jest typoszeregiem
IF @CodeDT = 'PCLINE'
BEGIN
	ROLLBACK TRAN
	PRINT 'B£¥D: Wskazany dokument to typoszereg, zadania generuje siê w wydaniu'
	RETURN
END;

--Weryfikacja czy wskazane wydanie ma odpowiedni status do generowania zadañ
IF  @CodeDT = 'PCRELEASE' AND 
	@IdDocState <> 2 OR @IdDocState IS NULL
BEGIN
	ROLLBACK TRAN

--Zmienna do okreœlenia statusu dokumentu w formacie tekstowym
DECLARE @PrintMessage NVARCHAR(20);
SET @PrintMessage = (SELECT Name FROM dbo.TaskState WHERE IdTaskState = @IdDocState)

	PRINT 'B£¥D: Zadania mo¿na generowaæ tylko gdy dokument ma status "Realizowane". ' +
	'Obecnie status dokumentu to: ' + '"'+ @PrintMessage +'"'
	RETURN
END;

--Przypisanie zmiennej kodu wydania			 
SET @DocumentValueId_6 =	
	(SELECT DI.DocumentValue 
	FROM dbo.DocumentItem				as DI			
		JOIN dbo.DocumentTemplateItem	as DTI 
		ON DI.IdDTI = DTI.IdDTI
	WHERE DI.IdDoc = @IdDoc AND 
		  DTI.CodeDTI = 'CODE_R');

--Aktualizacja statusu dokumentu
UPDATE dbo.Document
SET	IdDocState = @IdDocState
	WHERE IdDoc = @IdDoc AND 
		  @CodeDT = 'PCRELEASE'

/* UPDATE in 1.4
Generowanie zadañ do wydania w zale¿noœci od wskazanego zakresu. 
Wydanie musi byæ w statusie "Realizowane"
Zadania domyœlnie maj¹ status "Nowy"
Generator implementuje liste na bazie tabeli dbo.TaskList
*/
IF 
	@CodeDT	= 'PCRELEASE' and 
	@IdDocState = 2
BEGIN
	IF @StateName  = 'Pe³ny'
		INSERT INTO dbo.Task (IdTaskState, ObjectId, Name)
		SELECT 1, @ObjectId, TS.TaskName + @DocumentValueId_6 
		FROM dbo.TasksList as TS
		WHERE CodeScope = 'FULL'
	ELSE
	IF @StateName = 'Podstawowy'
		INSERT INTO dbo.Task (IdTaskState, ObjectId, Name)
		SELECT 1, @ObjectId, TS.TaskName + @DocumentValueId_6 
		FROM dbo.TasksList as TS
		WHERE CodeScope = 'BASIC'
	ELSE
	IF @StateName  = 'Tylko opis'
		INSERT INTO dbo.Task (IdTaskState, ObjectId, Name)
		SELECT 1, @ObjectId, TS.TaskName + @DocumentValueId_6 
		FROM dbo.TasksList as TS
		WHERE CodeScope = 'DESC'
END

--Koniec transakcji
COMMIT TRAN

  SELECT ObjectId as [Numer dokumentu], Name as [Wygenerowana lista zadañ]
  FROM dbo.Task
  WHERE ObjectId = @ObjectId

END TRY

-- Obs³uga b³êdu wycofuje transakcje i wyœwietla komunikat o nim
BEGIN CATCH 

	IF ERROR_NUMBER() <> 0
		BEGIN
			ROLLBACK TRAN
		END

	PRINT 'Numer b³êdu    : ' + CAST(ERROR_NUMBER() as varchar(30));
	PRINT 'Komunikat b³êdu: ' + ERROR_MESSAGE();
	PRINT 'Wa¿noœæ b³êdu  : ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
	PRINT 'Stan b³êdu     : ' + CAST(ERROR_STATE() AS VARCHAR(10));
	PRINT 'Wiersz b³êdu   : ' + CAST(ERROR_LINE() AS VARCHAR(10));

END CATCH

/*########################################################################
Alternatywna metoda która generuje liste zadañ poprzez kursor AddNewTask
IF
	@CodeDT	= 'PCRELEASE' and 
	@IdDocState = 2
BEGIN
	DECLARE @CodeScope nvarchar(15)
	DECLARE @TaskName nvarchar(60) 
	
	DECLARE AddNewTask CURSOR FAST_FORWARD FOR
		SELECT CodeScope, TaskName
		FROM dbo.TasksList
		ORDER BY IdTaskList

	OPEN AddNewTask
	FETCH NEXT FROM AddNewTask 
	INTO @CodeScope, @TaskName
	WHILE @@FETCH_STATUS=0
BEGIN
	IF @CodeScope = 
	(SELECT CodeValue FROM dbo.DictionaryItem WHERE [Value] = @StateName)

BEGIN
	INSERT INTO Task(IdTaskState, ObjectId, Name)
	VALUES(1, @ObjectId, @TaskName + @DocumentValueId_6)
END
	FETCH NEXT FROM AddNewTask INTO @CodeScope, @TaskName
END
	CLOSE AddNewTask
	DEALLOCATE AddNewTask
END 
###########################################################################*/