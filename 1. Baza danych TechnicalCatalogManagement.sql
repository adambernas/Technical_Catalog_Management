--Tytuł: Generowanie struktury bazy danych TechnicalCatalogManagement z przykładowymi danymi
--Autor: Adam Bernaś
--Update: 27-02-2022
--Wersia: 1.4
--Opis: 
--	# dodatkowe elementy i funkcjonalności tej bazy jak widoki, procedury czy funkcję znajdują są w repozytorium w postaci osobnych plików
--	# aby zapłenić bazę więszką ilością danych należy użyć procedury z pliku "Generator losowych danych do TechnicalCatalogManagement"
--	# baza danych może zostać rozbudowana o nowe elementy i funkcjonalności

--Sprawdzanie czy baza danych już istnieje
IF EXISTS (SELECT name FROM sys.databases WHERE name='TechnicalCatalogManagement')  
DROP DATABASE TechnicalCatalogManagement
GO
--Tworzenie i korzystanie z bazy danych "TechnicalCatalogManagement"
CREATE DATABASE TechnicalCatalogManagement
GO
USE TechnicalCatalogManagement
GO
SET NOCOUNT ON
--Tworzenie tabeli Dictionary
CREATE TABLE dbo.Dictionary
(
	IdDict int NOT NULL 
		CONSTRAINT PK_Dictionary PRIMARY KEY(IdDict)
		CONSTRAINT CH_Dictionary_IdDict CHECK(IdDict > 0),
	NameDict nvarchar(30) NOT NULL
)
GO
--Tworzenie tabeli DictionaryItem
CREATE TABLE dbo.DictionaryItem
(
	IdDicItem int NOT NULL
		CONSTRAINT PK_DictionaryItem PRIMARY KEY(IdDicItem)
		CONSTRAINT CH_DictionaryItem_IdDicItem CHECK(IdDicItem > 0),
	IdDict int NOT NULL,	
	Value varchar(30) NOT NULL,
	CodeValue nvarchar(20) NOT NULL
		CONSTRAINT UNQ_DictionaryItem_CodeValue UNIQUE(CodeValue)
)
GO
CREATE INDEX INDEX_DictionaryItem_IdDict ON dbo.DictionaryItem(IdDict)
GO
--Tworzenie tabeli Document
CREATE TABLE dbo.Document
(
	IdDoc int IDENTITY(1,1) NOT NULL 
		CONSTRAINT PK_Document PRIMARY KEY(IdDoc),
	IdDT int NOT NULL,
	DocName nvarchar(50) NOT NULL
		CONSTRAINT UNIQ_Document_DocName UNIQUE(DocName),
	IdDocState int NULL,
	IdDocRelation int NULL,
	ObjectId nvarchar(15) NULL
		CONSTRAINT UNQ_Document_ObjectId UNIQUE(ObjectId)
)
GO
--Tworzenie tabeli DocumentItem
CREATE TABLE dbo.DocumentItem
(
	IdDocI int IDENTITY(1,1) NOT NULL
		CONSTRAINT PK_DocumentItem PRIMARY KEY(IdDocI),
	IdDTI int NOT NULL,
	IdDoc int NOT NULL,
	DocumentValue nvarchar(35) NOT NULL
)
GO
--Tworzenie tabeli DocumentTemplate
CREATE TABLE dbo.DocumentTemplate
(
	IdDT int NOT NULL
		CONSTRAINT PK_DocumentTemplate PRIMARY KEY(IdDT),
	CodeDT nvarchar(20) NOT NULL,
	NameDT nvarchar(30) NOT NULL 
)
GO
CREATE INDEX INDEX_DocumentTemplate_CodeDT ON dbo.DocumentTemplate(CodeDT)
GO
--Tworzenie tabeli DocumentTemplateItem
CREATE TABLE dbo.DocumentTemplateItem
(
	IdDTI int NOT NULL
		CONSTRAINT PK_DocumentTemplateItem PRIMARY KEY(IdDTI),
	IdDT int NOT NULL,
	CodeDTI nvarchar(20) NOT NULL,
	NameDTI nvarchar(30) NOT NULL
)
GO
CREATE INDEX INDEX_DocumentTemplateItem_IdDT_CodeDTI ON dbo.DocumentTemplateItem(IdDT,CodeDTI)
GO
--Tworzenie tabeli Task
CREATE TABLE dbo.Task
(
	IdTask int IDENTITY(1,1) NOT NULL
		CONSTRAINT PK_Task PRIMARY KEY(IdTask),
	IdTaskState int NOT NULL,
	ObjectId nvarchar(15) NOT NULL,
	Name nvarchar(50) NOT NULL
)
GO
--Tworzenie tabeli TasksList
CREATE TABLE dbo.TasksList
(
	IdTaskList int NOT NULL
		CONSTRAINT PK_TaskList PRIMARY KEY(IdTaskList),
	TaskName varchar(60) NOT NULL,
	CodeScope nvarchar(20) NOT NULL
)
GO
CREATE INDEX INDEX_TaskList_CodeScope ON dbo.TasksList(CodeScope)
GO
--Tworzenie tabeli TaskState
CREATE TABLE dbo.TaskState
(
	IdTaskState int NOT NULL 
		CONSTRAINT PK_TaskState PRIMARY KEY(IdTaskState),
	Name varchar(20) NOT NULL,
	IsClosed int NOT NULL
)
GO
CREATE INDEX INDEX_TaskState_IsClosed ON dbo.TaskState(IsClosed)
GO
--Wprowadzanie danych do tabeli Dictionary
INSERT dbo.Dictionary (IdDict, NameDict) VALUES 
(1, N'Zakres danych katalogu'),
(2, N'Producenci'),
(3, N'Grupy produktów')

--Wprowadzanie danych do tabeli DictionaryItem
INSERT INTO dbo.DictionaryItem (IdDicItem, IdDict, Value, CodeValue) VALUES 
(1, 1, N'Pełny', N'FULL'),
(2, 1, N'Podstawowy', N'BASIC'),
(3, 1, N'Tylko opis', N'DESC'),
(4, 2, N'Danfoss', N'DAN'),
(5, 3, N'Sprężarka', 'COMPRE'),
(6, 2, N'Frascold', N'FRA'),
(7, 2, N'Copeland', N'COP'),
(8, 3, N'Agregat', 'UNIT'),
(9, 2, N'Cubigel', N'CUB'),
(10, 2, N'Mitsubishi', N'MHI'),
(11, 2, N'LG', N'LG'),
(12, 2, N'ECO', N'ECO'),
(13, 2, N'Thermofin', N'TMF'),
(14, 3, N'Klimatyzacja', N'AIRCOND'),
(15, 3, N'Pompy ciepła', N'HEADPUMP'),
(16, 3, N'Chłodnice powietrza', N'AIRCOL'),
(17, 3, N'Systemy VRF', N'VRF'),
(18, 2, N'Samsung', N'SMG'),
(19, 2, N'Alfa-Laval', N'ALV'),
(20, 3, N'Skraplacze', N'COND')

--Wprowadzanie danych do tabeli Document
SET IDENTITY_INSERT dbo.Document ON
INSERT INTO dbo.Document (IdDoc, IdDT, DocName, IdDocState, IdDocRelation, ObjectId) VALUES 
(1, 1, N'Typoszereg Danfoss MTZ', NULL, NULL, N'DOC1'),
(2, 1, N'Typoszereg Danfoss NTZ', NULL, NULL, N'DOC2'),
(3, 2, N'Wydanie Danfoss MTZ-2020', 2, 1, N'DOC3'),
(4, 2, N'Wydanie Danfoss NTZ-2021', 4, 2, N'DOC4'),
(5, 2, N'Wydanie Danfoss MTZ-2021', 2, 1, N'DOC5'),
(6, 1, N'Typoszereg Frascold ABC', NULL, NULL, N'DOC6'),
(7, 2, N'Wydanie Frascold ABC-2020', 2, 6, N'DOC7'),
(8, 2, N'Wydanie Frascold ABC-2021', 5, 6, N'DOC8'),
(9, 1, N'Typoszereg Copeland XYZ', NULL, NULL, N'DOC9'),
(10, 2, N'Wydanie Coepland XYZ-2021', 5, 9, N'DOC10'),
(11, 2, N'Wydanie Coepland XYZ-2022', 2, 9, N'DOC11'),
(12, 2, N'Wydanie Coepland XYZ-2023', 1, 9, N'DOC12')
SET IDENTITY_INSERT dbo.Document OFF

--Wprowadzanie danych do tabeli DocumentItem
SET IDENTITY_INSERT dbo.DocumentItem ON
INSERT INTO dbo.DocumentItem (IdDocI, IdDTI, IdDoc, DocumentValue) VALUES 
(1, 1, 1, N'DAN-MTZ'),
(2, 2, 1, N'MTZ'),
(3, 3, 1, N'Pełny'),
(4, 4, 1, N'Danfoss'),
(5, 5, 1, N'Sprężarka'),
(6, 1, 2, N'DAN-NTZ'),
(7, 2, 2, N'NTZ'),
(8, 3, 2, N'Pełny'),
(9, 4, 2, N'Danfoss'),
(10, 5, 2, N'Sprężarka'),
(11, 6, 3, N'DAN-MTZ-2020'),
(12, 7, 3, N'2020'),
(13, 8, 3, N'Pełny'),
(14, 9, 3, N'Danfoss'),
(15, 10, 3, N'Sprężarka'),
(16, 6, 4, N'DAN-NTZ-2021'),
(17, 7, 4, N'2021'),
(18, 8, 4, N'Pełny'),
(19, 9, 4, N'Danfoss'),
(20, 10, 4, N'Sprężarka'),
(21, 11, 3, N'MTZ'),
(22, 11, 4, N'NTZ'),
(23, 6, 5, N'DAN-MTZ-2021'),
(24, 7, 5, N'2021'),
(25, 8, 5, N'Tylko opis'),
(26, 9, 5, N'Danfoss'),
(27, 10, 5, N'Sprężarka'),
(28, 11, 5, N'MTZ'),
(29, 1, 6, N'FRA-ABC'),
(30, 2, 6, N'ABC'),
(31, 3, 6, N'Tylko opis'),
(32, 4, 6, N'Frascold'),
(33, 5, 6, N'Agregat'),
(34, 6, 7, N'FRA-ABC-2020'),
(35, 7, 7, N'2020'),
(36, 8, 7, N'Tylko opis'),
(37, 9, 7, N'Frascold'),
(38, 10, 7, N'Agregat'),
(39, 11, 7, N'ABC'),
(40, 6, 8, N'FRA-ABC-2021'),
(41, 7, 8, N'2021'),
(42, 8, 8, N'Podstawowy'),
(43, 9, 8, N'Frascold'),
(44, 10, 8, N'Agregat'),
(45, 11, 8, N'ABC'),
(46, 1, 9, N'COP-XYZ'),
(47, 2, 9, N'XYZ'),
(48, 3, 9, N'Tylko opis'),
(49, 4, 9, N'Copeland'),
(50, 5, 9, N'Agregat'),
(51, 6, 10, N'COP-XYZ-2021'),
(52, 7, 10, N'2021'),
(53, 8, 10, N'Tylko opis'),
(54, 9, 10, N'Copeland'),
(55, 10, 10, N'Agregat'),
(56, 11, 10, N'XYZ'),
(57, 6, 11, N'COP-XYZ-2022'),
(58, 7, 11, N'2022'),
(59, 8, 11, N'Tylko opis'),
(60, 9, 11, N'Copeland'),
(61, 10, 11, N'Agregat'),
(62, 11, 11, N'XYZ'),
(63, 6, 12, N'COP-XYZ-2023'),
(64, 7, 12, N'2023'),
(65, 8, 12, N'Tylko opis'),
(66, 9, 12, N'Copeland'),
(67, 10, 12, N'Agregat'),
(68, 11, 12, N'XYZ')
SET IDENTITY_INSERT dbo.DocumentItem OFF

--Wprowadzanie danych do tabeli DocumentTemplate
INSERT INTO dbo.DocumentTemplate (IdDT, CodeDT, NameDT) VALUES 
(1, N'PCLINE', N'Typoszereg'),
(2, N'PCRELEASE', N'Wydanie')

--Wprowadzanie danych do tabeli DocumentTemplateItem
INSERT INTO dbo.DocumentTemplateItem (IdDTI, IdDT, CodeDTI, NameDTI) VALUES 
(1, 1, N'CODE_L', N'Kod'),
(2, 1, N'NAME_L', N'Nazwa'),
(3, 1, N'SCOPE_L', N'Zakres'),
(4, 1, N'PRODUCER_L', N'Producent'),
(5, 1, N'GROUP_L', N'Grupa'),
(6, 2, N'CODE_R', N'Kod'),
(7, 2, N'NAME_R', N'Nazwa'),
(8, 2, N'SCOPE_R', N'Zakres'),
(9, 2, N'PRODUCER_R', N'Producent'),
(10, 2, N'GROUP_R', N'Grupa'),
(11, 2, N'NAME_LINE_R', N'Nazwa typoszeregu')

--Wprowadzanie danych do tabeli Task
SET IDENTITY_INSERT dbo.Task ON 
INSERT INTO dbo.Task (IdTask, IdTaskState, ObjectId, Name) VALUES 
(1, 1, N'DOC3', N'Zadanie 1 dla wydania DAN-MTZ-2020'),
(2, 1, N'DOC3', N'Zadanie 2 dla wydania DAN-MTZ-2020'),
(3, 1, N'DOC3', N'Zadanie 3 dla wydania DAN-MTZ-2020'),
(4, 1, N'DOC3', N'Zadanie 4 dla wydania DAN-MTZ-2020'),
(5, 1, N'DOC3', N'Zadanie 5 dla wydania DAN-MTZ-2020'),
(6, 1, N'DOC3', N'Zadanie 6 dla wydania DAN-MTZ-2020'),
(7, 1, N'DOC3', N'Zadanie 7 dla wydania DAN-MTZ-2020'),
(8, 2, N'DOC3', N'Zadanie 8 dla wydania DAN-MTZ-2020'),
(9, 5, N'DOC4', N'Zadanie 1 dla wydania DAN-NTZ-2021'),
(10, 2, N'DOC4', N'Zadanie 2 dla wydania DAN-NTZ-2021'),
(11, 4, N'DOC4', N'Zadanie 3 dla wydania DAN-NTZ-2021'),
(12, 3, N'DOC4', N'Zadanie 4 dla wydania DAN-NTZ-2021'),
(13, 3, N'DOC4', N'Zadanie 5 dla wydania DAN-NTZ-2021'),
(14, 5, N'DOC4', N'Zadanie 6 dla wydania DAN-NTZ-2021'),
(15, 6, N'DOC4', N'Zadanie 7 dla wydania DAN-NTZ-2021'),
(16, 6, N'DOC4', N'Zadanie 8 dla wydania DAN-NTZ-2021'),
(17, 1, N'DOC5', N'Zadanie 1 dla wydania DAN-MTZ-2021'),
(18, 4, N'DOC5', N'Zadanie 2 dla wydania DAN-MTZ-2021'),
(19, 5, N'DOC5', N'Zadanie 3 dla wydania DAN-MTZ-2021'),
(20, 1, N'DOC7', N'Zadanie 1 dla wydania FRA-ABC-2020'),
(21, 2, N'DOC7', N'Zadanie 2 dla wydania FRA-ABC-2020'),
(22, 4, N'DOC7', N'Zadanie 3 dla wydania FRA-ABC-2020'),
(23, 1, N'DOC8', N'Zadanie 1 dla wydania FRA-ABC-2021'),
(24, 1, N'DOC8', N'Zadanie 2 dla wydania FRA-ABC-2021'),
(25, 6, N'DOC8', N'Zadanie 3 dla wydania FRA-ABC-2021'),
(26, 6, N'DOC8', N'Zadanie 4 dla wydania FRA-ABC-2021'),
(27, 5, N'DOC8', N'Zadanie 5 dla wydania FRA-ABC-2021'),
(28, 5, N'DOC10', N'Zadanie 1 dla wydania COP-XYZ-2021'),
(29, 5, N'DOC10', N'Zadanie 2 dla wydania COP-XYZ-2021'),
(30, 5, N'DOC10', N'Zadanie 3 dla wydania COP-XYZ-2021'),
(31, 2, N'DOC11', N'Zadanie 1 dla wydania COP-XYZ-2022'),
(32, 2, N'DOC11', N'Zadanie 2 dla wydania COP-XYZ-2022'),
(33, 5, N'DOC11', N'Zadanie 3 dla wydania COP-XYZ-2022')
SET IDENTITY_INSERT dbo.Task OFF

--Wprowadzanie danych do tabeli TaskList
INSERT INTO dbo.TasksList (IdTaskList, TaskName, CodeScope) VALUES 
(1, N'Zadanie 1 dla wydania ', N'FULL'),
(2, N'Zadanie 2 dla wydania ', N'FULL'),
(3, N'Zadanie 3 dla wydania ', N'FULL'),
(4, N'Zadanie 4 dla wydania ', N'FULL'),
(5, N'Zadanie 5 dla wydania ', N'FULL'),
(6, N'Zadanie 6 dla wydania ', N'FULL'),
(7, N'Zadanie 7 dla wydania ', N'FULL'),
(8, N'Zadanie 8 dla wydania ', N'FULL'),
(9, N'Zadanie 1 dla wydania ', N'BASIC'),
(10, N'Zadanie 2 dla wydania ', N'BASIC'),
(11, N'Zadanie 3 dla wydania ', N'BASIC'),
(12, N'Zadanie 4 dla wydania ', N'BASIC'),
(13, N'Zadanie 5 dla wydania ', N'BASIC'),
(14, N'Zadanie 1 dla wydania ', N'DESC'),
(15, N'Zadanie 2 dla wydania ', N'DESC'),
(16, N'Zadanie 3 dla wydania ', N'DESC')

--Wprowadzanie danych do tabeli TaskState
INSERT INTO dbo.TaskState (IdTaskState, Name, IsClosed) VALUES 
(1, N'Nowy', 0),
(2, N'Realizowany', 0),
(3, N'Wstrzymany', 0),
(4, N'Odrzucony', 1),
(5, N'Wykonany', 1),
(6, N'Usunięty', 1)
GO
--Tworzenie kluczy obcych do tabel
ALTER TABLE dbo.DictionaryItem 
	ADD CONSTRAINT FK_DictionaryItem_Dictionary 
	FOREIGN KEY(IdDict)
	REFERENCES dbo.Dictionary(IdDict)
	ON UPDATE CASCADE
GO
ALTER TABLE dbo.Document 
	ADD CONSTRAINT FK_Document_DocumentTemplate 
	FOREIGN KEY(IdDT)
	REFERENCES dbo.DocumentTemplate(IdDT)
	ON UPDATE CASCADE
GO
ALTER TABLE dbo.Document
	ADD CONSTRAINT FK_Document_TaskState 
	FOREIGN KEY(IdDocState)
	REFERENCES dbo.TaskState(IdTaskState)
GO
ALTER TABLE dbo.Document
	ADD CONSTRAINT FK_Document_Document 
	FOREIGN KEY(IdDocRelation)
	REFERENCES dbo.Document(IdDoc)
GO
ALTER TABLE dbo.DocumentItem
	ADD CONSTRAINT FK_DocumentItem_Document 
	FOREIGN KEY(IdDoc)
	REFERENCES dbo.Document(IdDoc)
	ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE dbo.DocumentItem  
	ADD CONSTRAINT FK_DocumentItem_DocumentTemplateItem 
	FOREIGN KEY(IdDTI)
	REFERENCES dbo.DocumentTemplateItem(IdDTI)
	ON UPDATE CASCADE
GO
ALTER TABLE dbo.DocumentTemplateItem 
	ADD CONSTRAINT FK_DocumentTemplateItem_DocumentTemplate 
	FOREIGN KEY(IdDT)
	REFERENCES dbo.DocumentTemplate(IdDT)
GO
ALTER TABLE dbo.Task  
	ADD CONSTRAINT FK_Task_TaskState 
	FOREIGN KEY(IdTaskState)
	REFERENCES dbo.TaskState(IdTaskState)
	ON UPDATE CASCADE
GO
ALTER TABLE dbo.Task
	ADD CONSTRAINT FK_Task_Document 
	FOREIGN KEY(ObjectId)
	REFERENCES dbo.Document(ObjectId)
	ON DELETE CASCADE ON UPDATE CASCADE
