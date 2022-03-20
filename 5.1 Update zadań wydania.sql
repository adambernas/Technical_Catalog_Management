--Tytu�: Aktualizacja listy zada� po zmianie nazwy wydania.
--Opis: Gdy wskazany dokument ju� istnieje procedura blokuje zmian� listy zada� na inny zakres co odzwierciedla prawid�ow� logik� aplikacji.
--		W repozytorium znajduje si� 2 wersja tej procedury kt�ra umo�liwia zmiany listy zada� istniej�cych wyda�.
--Autor: Adam Berna�
--Update: 23-02-2022
--Wersja: 1.4

/*Opis obs�ugi procedury (Zmienne w aplikacji s� obs�ugiwane poprzez interfejs graficzny)

@IdDoc				- Podaj istniej�cy numer Id dokumentu wydania gdzie chcesz dokona� zmiany
@DocumentValueId_7  - Podaj now� nazw� wydania
@StateName          - Podaj zakres wydania ('Pe�ny' , 'Podstawowy' , 'Tylko opis')
@IdDocState			- Podaj id statusu dokumentu od 1 do 6
					  (1 -Nowy, 2 -Realizowane, 3 -Wstrzymane, 4 -Odrzucony, 5 -Wykonany, 6-Usuni�te) */

/* Skr�t do obs�ugi procedury:
Exec UpdateTask
@IdDoc = 12,
@DocumentValueId_7 = '2024',
@StateName = 'Tylko opis', 
@IdDocState = 2	
*/

USE TechnicalCatalogManagement
GO
--Usu� procedure je�eli istnieje
IF OBJECT_ID ('dbo.UpdateTask') IS NOT NULL DROP PROC dbo.UpdateTask
GO

--Tworzenie procedury
CREATE PROC dbo.UpdateTask

--Deklarowanie zmiennych

--Zmienne wprowadzane przez u�ytkownika
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
--Otwarcie bloku do obs�ugi b��d�w
BEGIN TRY

--Rozpocz�cie transakcji
BEGIN TRAN
SET NOCOUNT ON

--Weryfikacja wprowadzenia poprawnej zmiennej @StateName
IF NOT EXISTS
	(SELECT [Value] FROM dbo.DictionaryItem 
 	 WHERE	[Value] = @StateName AND 
			CodeValue IN ('FULL', 'BASIC', 'DESC'))
BEGIN
	ROLLBACK TRAN
	PRINT 'B��D: Podano b��dny zakres wydania'
	RETURN
END; 

--Weryfikacja czy wskazany numer id dokumentu wydania istnieje
IF NOT EXISTS
	(SELECT IdDoc FROM dbo.Document 
	 WHERE  IdDoc = @IdDoc)
BEGIN
	ROLLBACK TRAN
	PRINT 'B��D: Nie ma takiego numeru dokumentu'
	RETURN
END;

--Blokada pr�by zmiany listy zada� w wygenerowanym wydaniu
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
	--Zmienna @CheckStateName sprawdza nazw� aktualnego zakresu zada�
	DECLARE @CheckStateName NVARCHAR(15)
	SET @CheckStateName = (SELECT DocumentValue 
						   FROM dbo.DocumentItem as DI
						   JOIN dbo.DocumentTemplateItem as DTI
								ON DI.IdDTI = DTI.IdDTI
									WHERE IdDoc = @IdDoc AND
										  DTI.CodeDTI = 'SCOPE_R')

PRINT 'B��D: Wydanie ' +'"'+ @DocumentValueId_7 +'"'+ ' ma ju� wygenerowan� list� zada� w zakresie '+'"'+ @CheckStateName +'".'
PRINT 'Aby stworzy� now� list� usu� obecne wydanie lub stw�rz nowe.'
	ROLLBACK TRAN
	RETURN
END;

--Weryfikacja czy podana nowa nazwa wydania ju� istnieje
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
	PRINT 'B��D: Podana nazwa wydania ' +'"'+ @DocumentValueId_7 +'"'+ ' juz istnieje'
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
	PRINT 'B��D: Wskazany dokument to typoszereg, zadania generuje si� w wydaniu'
	ROLLBACK TRAN
	RETURN
END;

--Weryfikacja czy wskazane wydanie ma odpowiedni status do generowania zada�
IF  @CodeDT = 'PCRELEASE' and 
	@IdDocState <> 2 or @IdDocState IS NULL
BEGIN
	ROLLBACK TRAN

--Zmienna do okre�lenia nazwy dokumentu
DECLARE @PrintMessage NVARCHAR(20);
SET @PrintMessage = (SELECT Name FROM dbo.TaskState WHERE IdTaskState = @IdDocState)

	PRINT 'B��D: Zadania mo�na generowa� tylko gdy dokument ma status "Realizowane". ' +
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

-- Aktualizacja kodu wydania w polu dokumentu wydania (kod sk�ada si� z 3 cz�ci odzielonych znaikiem "-")
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
	    /* 1 cz�� */
	 (	SELECT CodeValue FROM dbo.DictionaryItem WHERE [Value] = 
		  (	SELECT DocumentValue 
			FROM dbo.DocumentItem as DI 
			JOIN DocumentTemplateItem as DTI 
				ON DI.IdDTI = DTI.IdDTI
					WHERE DI.IdDoc = @IdDoc AND DTI.CodeDTI = 'PRODUCER_R' )
	 )
	  + '-' /* 2 cz�� */
	  +	  (	SELECT DocumentValue 
			FROM dbo.DocumentItem as DI 
			JOIN DocumentTemplateItem as DTI 
				ON DI.IdDTI = DTI.IdDTI
					WHERE DI.IdDoc = @IdDoc AND DTI.CodeDTI = 'NAME_LINE_R' )
	  + '-' /* 3 cz�� */
	  + @DocumentValueId_7
	  OUTPUT
		deleted.DocumentValue as Old_CODE_R,
		inserted.DocumentValue as New_CODE_R;

--Aktualizacja nazwy dokumentu wydania w dokumentach
/*Opis: Nazwa dokumentu sk�ada si� z 3 element�w. 
		Zagnie�d�one funkcj� okre�laj� tylko ostatni fragment dokonuj�c podmiany na warto�� ze zmiennej*/

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

--Usuwanie starej wersji zada�
DELETE 
	FROM dbo.Task
	WHERE ObjectId = (SELECT ObjectId FROM dbo.Document WHERE IdDoc = @IdDoc);

/*
Generowanie zada� do wydania w zale�no�ci od wskazanego zakresu. 
Wydanie musi by� w statusie "Realizowane"
Zadania domy�lnie maj� status "Nowy"
*/
IF 
	@CodeDT	= 'PCRELEASE' and 
	@IdDocState = 2
BEGIN
	IF @StateName  = 'Pe�ny'
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
