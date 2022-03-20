--Tytu³: Aktualizacja listy zadañ po zmianie nazwy wydania.
--Opis: Gdy wskazany dokument ju¿ istnieje procedura blokuje zmianê listy zadañ na inny zakres co odzwierciedla prawid³ow¹ logikê aplikacji.
--		W repozytorium znajduje siê 2 wersja tej procedury która umo¿liwia zmiany listy zadañ istniej¹cych wydañ.
--Autor: Adam Bernaœ
--Update: 23-02-2022
--Wersja: 1.4

/*Opis obs³ugi procedury (Zmienne w aplikacji s¹ obs³ugiwane poprzez interfejs graficzny)

@IdDoc				- Podaj istniej¹cy numer Id dokumentu wydania gdzie chcesz dokonaæ zmiany
@DocumentValueId_7  - Podaj now¹ nazwê wydania
@StateName          - Podaj zakres wydania ('Pe³ny' , 'Podstawowy' , 'Tylko opis')
@IdDocState			- Podaj id statusu dokumentu od 1 do 6
					  (1 -Nowy, 2 -Realizowane, 3 -Wstrzymane, 4 -Odrzucony, 5 -Wykonany, 6-Usuniête) */

/* Skrót do obs³ugi procedury:
Exec UpdateTask
@IdDoc = 12,
@DocumentValueId_7 = '2024',
@StateName = 'Tylko opis', 
@IdDocState = 2	
*/

USE TechnicalCatalogManagement
GO
--Usuñ procedure je¿eli istnieje
IF OBJECT_ID ('dbo.UpdateTask') IS NOT NULL DROP PROC dbo.UpdateTask
GO

--Tworzenie procedury
CREATE PROC dbo.UpdateTask

--Deklarowanie zmiennych

--Zmienne wprowadzane przez u¿ytkownika
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
--Otwarcie bloku do obs³ugi b³êdów
BEGIN TRY

--Rozpoczêcie transakcji
BEGIN TRAN
SET NOCOUNT ON

--Weryfikacja wprowadzenia poprawnej zmiennej @StateName
IF NOT EXISTS
	(SELECT [Value] FROM dbo.DictionaryItem 
 	 WHERE	[Value] = @StateName AND 
			CodeValue IN ('FULL', 'BASIC', 'DESC'))
BEGIN
	ROLLBACK TRAN
	PRINT 'B£¥D: Podano b³êdny zakres wydania'
	RETURN
END; 

--Weryfikacja czy wskazany numer id dokumentu wydania istnieje
IF NOT EXISTS
	(SELECT IdDoc FROM dbo.Document 
	 WHERE  IdDoc = @IdDoc)
BEGIN
	ROLLBACK TRAN
	PRINT 'B£¥D: Nie ma takiego numeru dokumentu'
	RETURN
END;

--Blokada próby zmiany listy zadañ w wygenerowanym wydaniu
IF	@StateName <> (SELECT DocumentValue 
				  FROM dbo.DocumentItem as DI
				  JOIN dbo.DocumentTemplateItem as DTI
					ON DI.IdDTI = DTI.IdDTI
					  WHERE IdDoc = @IdDoc AND
							DTI.CodeDTI = 'SCOPE_R')

AND	@DocumentValueId_7 = (SELECT DocumentValue 
							FROM dbo.DocumentItem as DI
								JOIN dbo.DocumentTemplateItem as DTI
							ON DI.IdDTI = DTI.IdDTI
								WHERE IdDoc = @IdDoc AND
									  DTI.CodeDTI = 'NAME_R')
BEGIN
	--Zmienna @CheckStateName sprawdza nazwê aktualnego zakresu zadañ
	DECLARE @CheckStateName NVARCHAR(15)
	SET @CheckStateName = (SELECT DocumentValue 
						   FROM dbo.DocumentItem as DI
						   JOIN dbo.DocumentTemplateItem as DTI
								ON DI.IdDTI = DTI.IdDTI
									WHERE IdDoc = @IdDoc AND
										  DTI.CodeDTI = 'SCOPE_R')

PRINT 'B£¥D: Wydanie ' +'"'+ @DocumentValueId_7 +'"'+ ' ma ju¿ wygenerowan¹ listê zadañ w zakresie '+'"'+ @CheckStateName +'".'
PRINT 'Aby stworzyæ now¹ listê usuñ obecne wydanie lub stwórz nowe.'
	ROLLBACK TRAN
	RETURN
END;

--Weryfikacja czy podana nowa nazwa wydania ju¿ istnieje
IF @DocumentValueId_7 IN
(	SELECT DI.DocumentValue --,D.IdDoc as IdDocWydania, D.IdDocRelation
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
BEGIN
	PRINT 'B£¥D: Podana nazwa wydania ' +'"'+ @DocumentValueId_7 +'"'+ ' juz istnieje'
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
	PRINT 'B£¥D: Wskazany dokument to typoszereg, zadania generuje siê w wydaniu'
	ROLLBACK TRAN
	RETURN
END;

--Weryfikacja czy wskazane wydanie ma odpowiedni status do generowania zadañ
IF  @CodeDT = 'PCRELEASE' and 
	@IdDocState <> 2 or @IdDocState IS NULL
BEGIN
	ROLLBACK TRAN

--Zmienna do okreœlenia nazwy dokumentu
DECLARE @PrintMessage NVARCHAR(20);
SET @PrintMessage = (SELECT Name FROM dbo.TaskState WHERE IdTaskState = @IdDocState)

	PRINT 'B£¥D: Zadania mo¿na generowaæ tylko gdy dokument ma status "Realizowane". ' +
	'Obecnie status dokumentu to: ' + '"'+ @PrintMessage +'"'
	RETURN
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
FROM dbo.DocumentItem		  as DI
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

-- Aktualizacja kodu wydania w polu dokumentu wydania (kod sk³ada siê z 3 czêœci odzielonych znaikiem "-")
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
	    /* 1 czêœæ */
	 (	SELECT CodeValue FROM dbo.DictionaryItem WHERE [Value] = 
		  (	SELECT DocumentValue 
			FROM dbo.DocumentItem as DI 
			JOIN DocumentTemplateItem as DTI 
				ON DI.IdDTI = DTI.IdDTI
					WHERE DI.IdDoc = @IdDoc AND DTI.CodeDTI = 'PRODUCER_R' )
	 )
	  + '-' /* 2 czêœæ */
	  +	  (	SELECT DocumentValue 
			FROM dbo.DocumentItem as DI 
			JOIN DocumentTemplateItem as DTI 
				ON DI.IdDTI = DTI.IdDTI
					WHERE DI.IdDoc = @IdDoc AND DTI.CodeDTI = 'NAME_LINE_R' )
	  + '-' /* 3 czêœæ */
	  + @DocumentValueId_7
	  OUTPUT
		deleted.DocumentValue as Old_CODE_R,
		inserted.DocumentValue as New_CODE_R;

--Aktualizacja nazwy dokumentu wydania w dokumentach
/*Opis: Nazwa dokumentu sk³ada siê z 3 elementów. 
		Zagnie¿d¿one funkcjê okreœlaj¹ tylko ostatni fragment dokonuj¹c podmiany na wartoœæ ze zmiennej*/

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

--Usuwanie starej wersji zadañ
DELETE 
	FROM dbo.Task
	WHERE ObjectId = (SELECT ObjectId FROM dbo.Document WHERE IdDoc = @IdDoc);

/*
Generowanie zadañ do wydania w zale¿noœci od wskazanego zakresu. 
Wydanie musi byæ w statusie "Realizowane"
Zadania domyœlnie maj¹ status "Nowy"
*/
IF 
	@CodeDT	= 'PCRELEASE' and 
	@IdDocState = 2
BEGIN
	IF @StateName  = 'Pe³ny'
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
