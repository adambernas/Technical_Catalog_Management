--Tytu�: Generowanie listy zada� do wydania o statusie dokumentu "Nowy"
--Opis:	Procedura po zmianie statusu dokumentu z "Nowy" na "Realizowany" generuje 
--      odpowiedni� pul� zada� na podstawie domyslnego zakresu typoszeregu.
--Autor: Adam Berna�
--Update: 27-02-2022
--Wersia: 1.4

--Skr�t do obs�ugi procedury (Zmienne w aplikacji s� obs�ugiwane poprzez interfejs graficzny)
/*
@IdDoc		- Podaj istniej�cy numer Id dokumentu wydania
@IdDocState - Podaj status dokumentu od 1 do 6
			  (1 -Nowy, 2 -Realizowane, 3 -Wstrzymane, 4 -Odrzucony, 5 -Wykonany, 6-Usuni�te)*/
/*
exec dbo.AddTask
@IdDoc = 12,		   
@IdDocState = 2			
*/

USE TechnicalCatalogManagement
GO
--Usu� procedure je�eli istnieje
IF OBJECT_ID ('dbo.AddTask') IS NOT NULL DROP PROC dbo.AddTask
GO

--Tworzenie procedury
CREATE PROC dbo.AddTask

--Deklarowanie zmiennych

--Zmienne wprowadzane przez u�ytkownika
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
--Otwarcie bloku do obs�ugi b��d�w
BEGIN TRY

--Rozpocz�cie transakcji
BEGIN TRAN

--Przypisanie numeru dokumentu do zmiennej na podstawie numeru wydania
SET @ObjectId =			
	(SELECT ObjectId 
	 FROM dbo.Document 
	 WHERE IdDoc = @IdDoc); 

--Przypisanie zakresu wydania z domy�lnego zakresu typoszeregu
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
	PRINT 'B��D: Nie ma takiego numeru dokumentu'
	RETURN
END;

--Weryfikacja wprowadzenia poprawnej zmiennej @StateName
IF NOT EXISTS 
	(SELECT [Value] FROM dbo.DictionaryItem 
	 WHERE  [Value] = @StateName and 
		    CodeValue IN ('FULL', 'BASIC', 'DESC'))
BEGIN
	ROLLBACK TRAN
	PRINT 'B��D: Podano b��dny zakres wydania'
	RETURN
END; 

--Weryfikacja czy wskazane wydanie ma ju� wygenerowan� list� zada�
IF EXISTS 
   (SELECT ObjectId FROM dbo.Task
    WHERE ObjectId = @ObjectId)
BEGIN
	ROLLBACK TRAN
	PRINT 'B��D: Dla tego dokumentu ju� zosta�y wygenerowane zadania'
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
	PRINT 'B��D: Wskazany dokument to typoszereg, zadania generuje si� w wydaniu'
	RETURN
END;

--Weryfikacja czy wskazane wydanie ma odpowiedni status do generowania zada�
IF  @CodeDT = 'PCRELEASE' AND 
	@IdDocState <> 2 OR @IdDocState IS NULL
BEGIN
	ROLLBACK TRAN

--Zmienna do okre�lenia statusu dokumentu w formacie tekstowym
DECLARE @PrintMessage NVARCHAR(20);
SET @PrintMessage = (SELECT Name FROM dbo.TaskState WHERE IdTaskState = @IdDocState)

	PRINT 'B��D: Zadania mo�na generowa� tylko gdy dokument ma status "Realizowane". ' +
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
Generowanie zada� do wydania w zale�no�ci od wskazanego zakresu. 
Wydanie musi by� w statusie "Realizowane"
Zadania domy�lnie maj� status "Nowy"
Generator implementuje liste na bazie tabeli dbo.TaskList
*/
IF 
	@CodeDT	= 'PCRELEASE' and 
	@IdDocState = 2
BEGIN
	IF @StateName  = 'Pe�ny'
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

  SELECT ObjectId as [Numer dokumentu], Name as [Wygenerowana lista zada�]
  FROM dbo.Task
  WHERE ObjectId = @ObjectId

END TRY

-- Obs�uga b��du wycofuje transakcje i wy�wietla komunikat o nim
BEGIN CATCH 

	IF ERROR_NUMBER() <> 0
		BEGIN
			ROLLBACK TRAN
		END

	PRINT 'Numer b��du    : ' + CAST(ERROR_NUMBER() as varchar(30));
	PRINT 'Komunikat b��du: ' + ERROR_MESSAGE();
	PRINT 'Wa�no�� b��du  : ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
	PRINT 'Stan b��du     : ' + CAST(ERROR_STATE() AS VARCHAR(10));
	PRINT 'Wiersz b��du   : ' + CAST(ERROR_LINE() AS VARCHAR(10));

END CATCH

/*########################################################################
Alternatywna metoda kt�ra generuje liste zada� poprzez kursor AddNewTask
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