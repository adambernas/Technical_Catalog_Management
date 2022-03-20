--Tytuł: Aktualizacja listy zadań po zmianie nazwy albo zakresu wydania.
--Opis: Uwaga! Możliwość zmiany zakresu listy zadań istniejącego wydania nie odzwierciedla prawidłowej logiki aplikacji.
--		Ten wariant kodu napisany w celach treningowych do testowania różnych scenariuszy.
--Autor: Adam Bernaś
--Update: 23-02-2022
--Wersja: 1.4

/*Opis obsługi procedury (Zmienne w aplikacji są obsługiwane poprzez interfejs graficzny)

@IdDoc				- Podaj istniejący numer Id dokumentu wydania gdzie chcesz dokonać zmiany
@DocumentValueId_7  - Podaj nową nazwę wydania
@StateName          - Podaj zakres wydania ('Pełny' , 'Podstawowy' , 'Tylko opis')
@IdDocState			- Podaj id statusu dokumentu od 1 do 6
					  (1 -Nowy, 2 -Realizowane, 3 -Wstrzymane, 4 -Odrzucony, 5 -Wykonany, 6-Usunięte) */

/* Skrót do obsługi procedury:
Exec UpdateTask
@IdDoc = 4,
@DocumentValueId_7 = '2020',
@StateName = 'Podstawowy', 
@IdDocState = 2	
*/

USE TechnicalCatalogManagement
GO
--Usuń procedure jeżeli istnieje
IF OBJECT_ID ('dbo.UpdateTask') IS NOT NULL DROP PROC dbo.UpdateTask
GO

--Tworzenie procedury
CREATE PROC dbo.UpdateTask

--Deklarowanie zmiennych

--Zmienne wprowadzane przez użytkownika
@IdDoc as INT = NULL,					
@DocumentValueId_7 as nvarchar(20)= NULL,  
@StateName as nvarchar(10) = NULL,		   
@IdDocState as INT = NULL,				   

--Zmienne generowane przez procedure
--Szablon dokumentu (1 typoszereg, 2 wydanie)
@CodeDT as nvarchar(15) = NULL,			   
--Numer dokumentu wydania
@ObjectId as nvarchar(10) = NULL,	   
--Kod wydania
@DocumentValueId_6 as nvarchar(30) = NULL  

AS
--Otwarcie bloku do obsługi błędów
BEGIN TRY

--Rozpoczęcie transakcji
BEGIN TRAN
SET NOCOUNT ON

--Weryfikacja wprowadzenia poprawnej zmiennej @StateName
IF NOT EXISTS
	(SELECT [Value] FROM dbo.DictionaryItem 
 	 WHERE	[Value] = @StateName AND 
			CodeValue IN ('FULL', 'BASIC', 'DESC'))
BEGIN
	ROLLBACK TRAN
	PRINT 'BŁĄD: Podano błędny zakres wydania'
	RETURN
END; 

--Weryfikacja czy wskazany numer id dokumentu wydania istnieje
IF NOT EXISTS
	(SELECT IdDoc FROM dbo.Document 
	 WHERE  IdDoc = @IdDoc)
BEGIN
	ROLLBACK TRAN
	PRINT 'BŁĄD: Nie ma takiego numeru dokumentu'
	RETURN
END;

--Weryfikacja czy podana nowa nazwa wydania ze wskazanym zakresem już istnieje
IF @DocumentValueId_7 IN
(
	SELECT DI.DocumentValue --,D.IdDoc as IdDocWydania, D.IdDocRelation
	FROM dbo.DocumentItem		  as DI
	JOIN dbo.Document			  as D
		ON D.IdDoc = DI.IdDoc
	JOIN dbo.DocumentTemplateItem as DTI
		ON DTI.IdDTI = DI.IdDTI
			WHERE DTI.CodeDTI = 'NAME_R' AND
				  D.IdDocRelation =
					 (	SELECT D.IdDocRelation --,D.IdDoc as IdDocWydania,  DI.IdDoc as IdDocTyposzereg, DI.DocumentValue
						FROM Document			  as D
						JOIN DocumentItem		  as DI
							ON D.IdDocRelation = DI.IdDoc
						JOIN DocumentTemplateItem as DTI
							ON DI.IdDTI = DTI.IdDTI
								WHERE DTI.CodeDTI = 'NAME_L' AND
									  D.IdDoc = @IdDoc )
)
AND
	@StateName = (SELECT DocumentValue 
				  FROM dbo.DocumentItem			as DI
				  JOIN dbo.DocumentTemplateItem as DTI
					 ON DI.IdDTI = DTI.IdDTI
						 WHERE IdDoc = @IdDoc AND
							   DTI.CodeDTI = 'SCOPE_R')
BEGIN
	PRINT 'BŁĄD: Podana nazwa wydania ' +'"'+ @DocumentValueId_7 +'"'+ ' w takim zakresie zadań juz istnieje'
	ROLLBACK TRAN
	RETURN
END;

--Zapisywanie Id szablonu dokumentu
SET @CodeDT =					
	(SELECT DT.CodeDT
	FROM dbo.Document		  as D 
	JOIN dbo.DocumentTemplate as DT 
		ON D.IdDT=DT.IdDT
			WHERE D.IdDoc = @IdDoc);

--Weryfikacja czy wskazany dokument nie jest typoszeregiem
IF @CodeDT = 'PCLINE'
BEGIN
	PRINT 'BŁĄD: Wskazany dokument to typoszereg, zadania generuje się w wydaniu'
	ROLLBACK TRAN
	RETURN
END;

--Weryfikacja czy wskazane wydanie ma odpowiedni status do generowania zadań
IF  @CodeDT = 'PCRELEASE' and 
	@IdDocState <> 2 or @IdDocState IS NULL
BEGIN
	ROLLBACK TRAN

--Zmienna do określenia statusu dokumentu w formacie tekstowym
DECLARE @PrintMessage NVARCHAR(20);
SET @PrintMessage = (SELECT Name FROM dbo.TaskState WHERE IdTaskState = @IdDocState)

	PRINT 'BŁĄD: Zadania można generować tylko gdy dokument ma status "Realizowane". ' +
	'Obecnie status dokumentu to: ' + '"'+ @PrintMessage +'"'
	RETURN
END;

--Informacja o zmianie listy zadań w istniejącym wydaniu
IF	@StateName <> (SELECT DocumentValue 
				  FROM dbo.DocumentItem			as DI
				  JOIN dbo.DocumentTemplateItem as DTI
					 ON DI.IdDTI = DTI.IdDTI
					    WHERE IdDoc = @IdDoc AND
							  DTI.CodeDTI = 'SCOPE_R')

AND	@DocumentValueId_7 = (SELECT DocumentValue 
							FROM dbo.DocumentItem		  as DI
							JOIN dbo.DocumentTemplateItem as DTI
								ON DI.IdDTI = DTI.IdDTI
									WHERE IdDoc = @IdDoc AND
										  DTI.CodeDTI = 'NAME_R')
BEGIN
	PRINT 'Wydanie ' +'"'+ @DocumentValueId_7 +'"'+ ' już istnieje, wygenerowano nową listę zadań w zakresie '+'"'+ @StateName +'".'
END;

-- Aktualizacja nazwy wydania w polu dokumentu wydania
WITH TabForUpdate_1 AS
(
SELECT DI.DocumentValue
FROM dbo.DocumentItem	  as DI
JOIN DocumentTemplateItem as DTI
	ON DI.IdDTI = DTI.IdDTI
		WHERE DI.IdDoc = @IdDoc AND 
			  DTI.CodeDTI = 'NAME_R'
)
UPDATE TabForUpdate_1
	SET DocumentValue = @DocumentValueId_7
	OUTPUT
		deleted.DocumentValue as Old_NAME_R,
		inserted.DocumentValue as New_NAME_R;

--Aktualizacja zakresu w polu dokumentu wydania
WITH TabForUpdate_2 AS
(
SELECT DI.DocumentValue
FROM dbo.DocumentItem			  as DI
JOIN dbo.DocumentTemplateItem as DTI
	ON DI.IdDTI = DTI.IdDTI
		WHERE DI.IdDoc = @IdDoc AND 
			  DTI.CodeDTI = 'SCOPE_R'
)
UPDATE TabForUpdate_2
	SET DocumentValue = @StateName
	OUTPUT
		deleted.DocumentValue as Old_SCOPE_R,
		inserted.DocumentValue as New_SCOPE_R;

-- Aktualizacja kodu wydania w polu dokumentu wydania (kod składa się z 3 części odzielonych znaikiem "-")
WITH TabForUpdate_3 AS
(
SELECT DocumentValue 
FROM dbo.DocumentItem	  as DI 
JOIN DocumentTemplateItem as DTI 
	ON DI.IdDTI = DTI.IdDTI
		WHERE DI.IdDoc = @IdDoc AND 
			  DTI.CodeDTI = 'CODE_R'
) 
UPDATE TabForUpdate_3
	SET DocumentValue = 
	    /* 1 część */
	 (	SELECT CodeValue FROM dbo.DictionaryItem WHERE [Value] = 
		  (	SELECT DocumentValue 
			FROM dbo.DocumentItem as DI 
			JOIN DocumentTemplateItem as DTI 
				ON DI.IdDTI = DTI.IdDTI
					WHERE DI.IdDoc = @IdDoc AND DTI.CodeDTI = 'PRODUCER_R' )
	 )
	  + '-' /* 2 część */
	  +	  (	SELECT DocumentValue 
			FROM dbo.DocumentItem as DI 
			JOIN DocumentTemplateItem as DTI 
				ON DI.IdDTI = DTI.IdDTI
					WHERE DI.IdDoc = @IdDoc AND DTI.CodeDTI = 'NAME_LINE_R' )
	  + '-' /* 3 część */
	  + @DocumentValueId_7
	  OUTPUT
		deleted.DocumentValue as Old_CODE_R,
		inserted.DocumentValue as New_CODE_R;

--Aktualizacja nazwy dokumentu wydania w dokumentach
/*Opis: Nazwa dokumentu składa się z 3 elementów. 
		Zagnieżdżone funkcję określają tylko ostatni fragment dokonując podmiany na wartość ze zmiennej*/

WITH TabForUpdate_4 AS
(
SELECT DocName 
FROM dbo.Document
WHERE IdDoc = @IdDoc
)
UPDATE TabForUpdate_4
	SET DocName = 
	REPLACE(DocName,(SUBSTRING(DocName,(CHARINDEX('-',DocName,1)+1),100)),@DocumentValueId_7)
	OUTPUT
		deleted.DocName as Old_DocName,
		inserted.DocName as New_DocName;

--Przypisanie numeru dokumentu wydania do zmiennej
SET @ObjectId = (SELECT ObjectId FROM dbo.Document WHERE IdDoc = @IdDoc);	

--Przypisanie kodu wydania do zmiennej				  
SET @DocumentValueId_6 = (SELECT DocumentValue 
						  FROM dbo.DocumentItem as DI
						  JOIN DocumentTemplateItem as DTI 
							 ON DI.IdDTI = DTI.IdDTI
							   WHERE DI.IdDoc = @IdDoc AND 
								     DTI.CodeDTI = 'CODE_R'); 

--Usuwanie starej wersji zadań
DELETE 
	FROM dbo.Task
	WHERE ObjectId = (SELECT ObjectId FROM dbo.Document WHERE IdDoc = @IdDoc);

/*
Generowanie zadań do wydania w zależności od wskazanego zakresu. 
Wydanie musi być w statusie "Realizowane"
Zadania domyślnie mają status "Nowy"
*/
IF 
	@CodeDT	= 'PCRELEASE' and 
	@IdDocState = 2
BEGIN
	IF @StateName  = 'Pełny'
		INSERT INTO dbo.Task (IdTaskState,ObjectId,Name)
		SELECT 1, @ObjectId, TaskName + @DocumentValueId_6 
		FROM dbo.TasksList 
		WHERE CodeScope = 'FULL'
	ELSE
	IF @StateName = 'Podstawowy'
		INSERT INTO dbo.Task (IdTaskState,ObjectId,Name)
		SELECT 1, @ObjectId, TaskName + @DocumentValueId_6 
		FROM dbo.TasksList 
		WHERE CodeScope = 'BASIC'
	ELSE
	IF @StateName  = 'Tylko opis'
		INSERT INTO dbo.Task (IdTaskState,ObjectId,Name)
		SELECT 1, @ObjectId, TaskName + @DocumentValueId_6 
		FROM dbo.TasksList 
		WHERE CodeScope = 'DESC'
END

--Koniec transakcji
COMMIT TRAN

END TRY

-- Obsługa błędu wycofuje transakcje i wyświetla komunikat o nim
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
