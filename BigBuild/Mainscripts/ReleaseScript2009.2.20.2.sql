/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 22.11.2013 16:34 %%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
SET NOEXEC OFF -- режим компиляция+выполнение скрипта
SET NOCOUNT ON
--*--создаем таблицу логов, если ее нет в БД --*--
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ScriptsSetupLogs]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ScriptsSetupLogs](
	[RC_ID] [int] IDENTITY(1,1) NOT NULL,
	[RC_Date] [datetime] NOT NULL DEFAULT (getdate()),
	[RC_Creator] [nvarchar](25) NOT NULL,
	[RC_Text] [nvarchar](254) NOT NULL,
	[RC_Status] [nvarchar](20) NOT NULL,
	[RC_Computer] [nvarchar](50) NOT NULL,
	[RC_LOG] [ntext] NULL,
	CONSTRAINT [PK_ScriptsSetupLogs] PRIMARY KEY CLUSTERED 
(
	[RC_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GRANT SELECT, INSERT, UPDATE ON [dbo].[ScriptsSetupLogs] TO PUBLIC
END
--*--
-- =====================  скрипт для проверки совместимости БД ===================== --
BEGIN TRY
	DECLARE @Message varchar (500)
	DECLARE @CurrentVer nvarchar(128)
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	--*--непосредственно обработка и сравнение --*--
	SET @CurrentVer = (SELECT compatibility_level FROM sys.databases WHERE name = (SELECT DB_NAME()))
	IF (@CurrentVer < 100)
		BEGIN
			SET @Message = 'Режим совместимости базы данных - ' + (SELECT DB_NAME()) + ' указан (' + @CurrentVer + '), для корректного обновления и работы ПК "Мастер-Тур" нужен режим совместимости 2008 (100) и выше.'
			RAISERROR(@Message, 16, 1)
		END
END TRY
BEGIN CATCH
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при выполнении скрипта по БД Мастер-Тура.', 'ERR', @HOST_NAME, @Message)
	RAISERROR(@Message, 16, 1) WITH NOWAIT
	SET NOEXEC ON;
END CATCH

-- =====================  скрипт для проверки версии SQL-сервера. Маска версии: [мажорная версия](2 символа).[минорная версия](2 символа).[релизная версия](4 символа) ===================== 
BEGIN TRY
	DECLARE @CurrentSQLVersion nvarchar(128)
	DECLARE @MinimalSQLVersion nvarchar(128)
	DECLARE @curver varchar(20) = null
    DECLARE @minver varchar(20) = null
	--*--непосредственно обработка и сравнение версий SQL --*--
	SET @CurrentSQLVersion = CAST(serverproperty('ProductVersion') AS nvarchar)
	SET @MinimalSQLVersion = '10.50.1600.0'
	
	---------------------------------------
	IF(@CurrentSQLVersion != @MinimalSQLVersion)
	BEGIN
		WHILE LEN(@CurrentSQLVersion) > 0
		BEGIN               
			WHILE LEN(@MinimalSQLVersion) > 0
			BEGIN
				IF PATINDEX('%.%',@CurrentSQLVersion) > 0
				BEGIN
					SET @curver = SUBSTRING(@CurrentSQLVersion, 0, PATINDEX('%.%',@CurrentSQLVersion))
					SET @CurrentSQLVersion = SUBSTRING(@CurrentSQLVersion, LEN(@curver + '.') + 1, LEN(@CurrentSQLVersion))
					SET @minver = SUBSTRING(@MinimalSQLVersion, 0, PATINDEX('%.%',@MinimalSQLVersion))
					SET @MinimalSQLVersion = SUBSTRING(@MinimalSQLVersion, LEN(@minver + '.') + 1, LEN(@MinimalSQLVersion))
					--------в мажорных, минорных и релиз версиях смотрим любое отклонение от 0---------- 
					IF(convert(int, @curver) - convert(int, @minver)) < 0
					BEGIN
							-- обнуляем и выходим из цикла, т.к. уже ошибка
							SET @Message = 'Используемая версия MS SQL Server — ' + CAST(serverproperty('ProductVersion') AS nvarchar)
							+ ', для корректного обновления и работы ПК "Мастер-Тур" нужна версия не ниже MS SQL Server 2008 R2 (10.50.1600.0).'
							RAISERROR(@Message, 16, 1)
					END   
					ELSE IF(convert(int, @curver) - convert(int, @minver)) > 0
					BEGIN
							SET @CurrentSQLVersion = NULL
							SET @MinimalSQLVersion = NULL
					END
				END
				ELSE IF (PATINDEX('%.%',@CurrentSQLVersion) < PATINDEX('%.%',@MinimalSQLVersion))
				BEGIN
					SET @curver = @CurrentSQLVersion
					SET @minver = SUBSTRING(@MinimalSQLVersion, 0, PATINDEX('%.%',@MinimalSQLVersion))
					IF(convert(int, @curver) - convert(int, @minver)) < 0
					BEGIN
						-- обнуляем и выходим из цикла, т.к. уже ошибка
						SET @Message = 'Используемая версия MS SQL Server — ' + CAST(serverproperty('ProductVersion') AS nvarchar)
							+ ', для корректного обновления и работы ПК "Мастер-Тур" нужна версия не ниже MS SQL Server 2008 R2 (10.50.1600.0).'
						RAISERROR(@Message, 16, 1)
					END
	                                            
					-- обнуляем
					SET @CurrentSQLVersion = NULL
					SET @MinimalSQLVersion = NULL     
				END
				ELSE
				BEGIN
					-- обнуляем, т.к. на этом шаге уже идет проверка SP, а нам достаточно до релиза
					SET @CurrentSQLVersion = NULL
					SET @MinimalSQLVersion = NULL    
				END
			END
		END
    END
 ---------------------------------------------------
END TRY
BEGIN CATCH
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при выполнении скрипта по БД Мастер-Тура из-за некорректной версии SQL Server.', 'ERR', @HOST_NAME, @Message)
	RAISERROR(@Message, 16, 1) WITH NOWAIT
	SET NOEXEC ON;
END CATCH



-- =====================  скрипт для проверки релиза МТ ===================== 
BEGIN TRY
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.1'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.2'

	IF(@PrevVersion != @CurrentVersion And @CurrentVersion != @NewVersion)
		BEGIN
			SET @Message = 'Вы запустили некорректный скрипт (обновление с ' + @PrevVersion + ' до ' + @NewVersion + '). Версия Вашей базы — ' + @CurrentVersion
			RAISERROR(@Message, 16, 1)
		END
END TRY
BEGIN CATCH
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении релиза БД Мастер-Тура.', 'ERR', @HOST_NAME, @Message)
	RAISERROR(@Message, 16, 1) WITH NOWAIT
	SET NOEXEC ON;
END CATCH
GO
/*********************************************************************/
/* begin (2013.11.12)_Insert_ObjectAliases.sql */
/*********************************************************************/
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 55))
 insert into ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_NameLat, OA_TABLEID, OA_CommunicationInfo) 
 values (55, 'NewAnkReportConverted', 'Исправление шаблонов для печати визовых анкет', 'Application forms report template update', 0, null)
go
/*********************************************************************/
/* end (2013.11.12)_Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.11.19)_Alter_Table_VisaDocumentContents.sql */
/*********************************************************************/
-- Расширение файла
IF NOT EXISTS (SELECT 1 FROM dbo.syscolumns WHERE name = 'VC_Extension' AND id = object_id(N'[dbo].[VisaDocumentContents]'))
BEGIN
	ALTER TABLE dbo.VisaDocumentContents ADD VC_Extension nvarchar(10) NULL
END
GO

/*********************************************************************/
/* end (2013.11.19)_Alter_Table_VisaDocumentContents.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.11.13)_ALTER_TABLE_Bonuses.sql */
/*********************************************************************/
-- Минимальная стоимость путевки
IF NOT EXISTS (SELECT 1 FROM dbo.syscolumns WHERE name = 'BN_MinPrice' AND id = object_id(N'[dbo].[Bonuses]'))
BEGIN
	ALTER TABLE dbo.Bonuses ADD BN_MinPrice MONEY NULL
END
GO
-- Максимальная стоимость путевки
IF NOT EXISTS (SELECT 1 FROM dbo.syscolumns WHERE name = 'BN_MaxPrice' AND id = object_id(N'[dbo].[Bonuses]'))
BEGIN
	ALTER TABLE dbo.Bonuses ADD BN_MaxPrice MONEY NULL
END
GO
-- Рассматривать стоимость с учетом скидки
IF NOT EXISTS (SELECT 1 FROM dbo.syscolumns WHERE name = 'BN_IsCommission' AND id = object_id(N'[dbo].[Bonuses]'))
BEGIN
	ALTER TABLE dbo.Bonuses ADD BN_IsCommission BIT NULL
END
GO

/*********************************************************************/
/* end (2013.11.13)_ALTER_TABLE_Bonuses.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.11.14)_x_mwCheckFlightQuotes.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Costs]') AND name = N'x_mwCheckFlightQuotes')
begin
	DROP INDEX [x_mwCheckFlightQuotes] ON [dbo].[tbl_Costs] WITH ( ONLINE = OFF )
end
GO

CREATE NONCLUSTERED INDEX [x_mwCheckFlightQuotes] ON [dbo].[tbl_Costs]
(
	[CS_SVKEY] ASC,
	[CS_CODE] ASC,
	[CS_SUBCODE1] ASC,
	[CS_PKKEY] ASC,
	[CS_DATE] ASC,
	[CS_DATEEND] ASC,
	[cs_checkindatebeg] asc,
	[cs_checkindateend] asc,
	[cs_week] asc
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Charter]') AND name = N'x_mwCheckFlightQuotes')
begin
	DROP INDEX [x_mwCheckFlightQuotes] ON [dbo].[Charter] WITH ( ONLINE = OFF )
end
GO

CREATE NONCLUSTERED INDEX [x_mwCheckFlightQuotes] ON [dbo].[Charter]
(
	ch_citykeyfrom,
	ch_citykeyto
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[stopavia]') AND name = N'x_mwCheckFlightQuotes')
begin
	DROP INDEX [x_mwCheckFlightQuotes] ON [dbo].[stopavia] WITH ( ONLINE = OFF )
end
GO

CREATE NONCLUSTERED INDEX [x_mwCheckFlightQuotes] ON [dbo].[stopavia]
(
	sa_ctkeyfrom,
	sa_ctkeyto,
	sa_stop,
	sa_dbeg,
	sa_dend
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaObjects]') AND name = N'x_mwCheckFlightQuotes')
begin
	DROP INDEX [x_mwCheckFlightQuotes] ON [dbo].[QuotaObjects] WITH ( ONLINE = OFF )
end
GO

CREATE NONCLUSTERED INDEX [x_mwCheckFlightQuotes] ON [dbo].[QuotaObjects]
(
	qo_svkey,
	qo_code,
	qo_subcode1
)
INCLUDE
(
	qo_qtid
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/*********************************************************************/
/* end (2013.11.14)_x_mwCheckFlightQuotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.11.21)_DELETE_TP_TourDates.sql */
/*********************************************************************/
--<VERSION>9.2.20</VERSION>
--<DATE>2013-11-21</DATE>
--<SUMMARY>
-- Находит max значение ключа для таблицы Tp_turDates в Keys и удаляет из Keys запись с TP_TourDates
--</SUMMARY>
declare @maxKeyForTurDates int 
declare @maxKeyForTourDates int
Select @maxKeyForTurDates = id from Keys WITH (UPDLOCK) where Key_Table = 'tp_turdates'
Select @maxKeyForTourDates = id from Keys WITH (UPDLOCK) where Key_Table = 'tp_tourdates'
If @maxKeyForTurDates < @maxKeyForTourDates
	begin
		update Key_TPTurDates
		set ID = @maxKeyForTourDates
	end
--
delete from Keys
where key_table like 'tp_tourdates' or key_table like 'tp_turdates'
GO
/*********************************************************************/
/* end (2013.11.21)_DELETE_TP_TourDates.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20130426_AlterTable_PriceServiceLink.sql */
/*********************************************************************/
if not exists 
	(
		select * from sys.columns col
		left join sys.tables tab on col.object_id = tab.object_id
		where tab.name = 'PriceServiceLink'
			and col.name = 'PS_Key'
			and is_identity = 1
	)
begin
	-- change primary key identity property to 1:
	-- first, delete all dependent objects
	if exists(select * from sys.sysobjects where name = 'PK_PriceServiceLink' and xtype = 'PK')
	begin
		ALTER TABLE PriceServiceLink drop constraint PK_PriceServiceLink
	end

	if exists (select top 1 1
			from sys.tables tab
			left join sys.indexes ix on ix.object_id = tab.object_id
			where tab.name = 'PriceServiceLink'
				and ix.name = 'PK_PriceServiceLink'
				and ix.type = 1)
	begin
		DROP INDEX PK_PriceServiceLink ON PriceServiceLink WITH ( ONLINE = OFF )
	end

	exec RecreateDependentObjects 'PriceServiceLink', 'PS_Key', '
	-- drop old column
	if exists (select * from dbo.syscolumns where name =''PS_Key'' and id = object_id(N''[dbo].[PriceServiceLink]''))
	begin
		ALTER TABLE PriceServiceLink drop column PS_Key
	end

	-- recreate primary key column with is_identity=1 property value
	if not exists (select * from dbo.syscolumns where name =''PS_Key'' and id = object_id(N''[dbo].[PriceServiceLink]''))
	begin
		ALTER TABLE PriceServiceLink add PS_Key int IDENTITY(1,1) NOT NULL
	end
	'
end
GO

if not exists(select * from sys.sysobjects where name like 'PK_PriceServiceLink' and xtype = 'PK')
begin
	if exists (select top 1 1
			from sys.tables tab
			left join sys.indexes ix on ix.object_id = tab.object_id
			where tab.name = 'PriceServiceLink'
				and ix.name = 'PK_PriceServiceLink'
				and ix.type = 1)
	begin
		DROP INDEX PK_PriceServiceLink ON PriceServiceLink WITH ( ONLINE = OFF )
	end

	ALTER TABLE PriceServiceLink add CONSTRAINT [PK_PriceServiceLink] PRIMARY KEY CLUSTERED 
	(
		[PS_Key] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
end
GO
/*********************************************************************/
/* end 20130426_AlterTable_PriceServiceLink.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetNKey.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetNKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[GetNKey]
GO
CREATE PROCEDURE [dbo].[GetNKey]
  (@sTable varchar(50) = null,
  @nNewKey int = null output)
AS
--<VERSION>9.2.20</VERSION>
--<DATE>2013-11-09</DATE>
--<SUMMARY>Возвращает ключ для таблицы</SUMMARY>

declare @transactionIsolationLevel int
declare @nID int
declare @keyTable varchar(100)
declare @query nvarchar (1000)

SELECT @transactionIsolationLevel = transaction_isolation_level 
FROM sys.dm_exec_sessions 
where session_id = @@spid

SET TRANSACTION ISOLATION LEVEL Serializable;

if @sTable like 'TP_TOURDATES'
	set @sTable = 'TP_TURDATES'

set nocount on
select @keyTable = 
		case 
		when @sTable like 'TP_TURDATES' then 'Key_TPTurDates'
		when @sTable like 'TP_Lists' then 'Key_TPLists'
		when @sTable like 'TP_Services' then 'Key_TPServices'
		when @sTable like 'TP_Tours' then 'Key_TPTours'
		when @sTable like 'TP_ServiceLists' then 'Key_TPServiceLists'
		when @sTable like 'TP_Prices' then 'Key_TPPrices'
		when @sTable like 'TURSERVICE' then 'Key_TURSERVICE'
		when @sTable like 'TURIST' then 'Key_TURIST'
		when @sTable like 'TURLIST' then 'Key_TURLIST'
		when @sTable like 'TurMargin' then 'Key_TurMargin'
		when @sTable like 'PRICELIST' then 'Key_PRICELIST'
		when @sTable like 'PRICESERVICELINK' then 'Key_PRICESERVICELINK'
		when @sTable like 'PARTNERS' then 'Key_PARTNERS'
		when @sTable like 'DogovorList' then 'Key_DogovorList'
		when @sTable like 'Dogovor' then 'Key_Dogovor'
	end

if @keyTable is not null
begin
	set @query = N'
	declare @maxKeyFromTable int 
	declare @maxKeyFromKeys int
	
	Select @maxKeyFromTable = id from @keyTable (updlock) 
	Select @maxKeyFromKeys = id from Keys WITH (UPDLOCK) where Key_Table = ''@sTable''
	If @maxKeyFromKeys is null Or @maxKeyFromKeys < @maxKeyFromTable
		Set @nNewKeyOut = @maxKeyFromTable 
	Else 
		Set @nNewKeyOut = @maxKeyFromKeys
	--
	Set @nNewKeyOut = @nNewKeyOut + 1
	update @keyTable set Id = @nNewKeyOut
	update Keys set Id = @nNewKeyOut where Key_Table = ''@sTable''
	'
	begin tran
	set @query = REPLACE(@query, '@keyTable', @keyTable)
	set @query = REPLACE(@query, '@sTable', @sTable)
	EXECUTE sp_executesql @query, N'@nNewKeyOut int output', @nNewKeyOut = @nNewKey  output
	commit tran
end
else
begin 	
	begin tran
	if exists (select top 1 1 from Keys where Key_Table = @sTable)
	begin
		Select @nNewKey = id + 1 from Keys WITH (UPDLOCK) where Key_Table = @sTable
		update Keys set Id = @nNewKey where Key_Table = @sTable
	end
	else
	begin
		insert into Keys (Key_Table, Id) values (@sTable, 1)
		set @nNewKey=1
	end	
	commit tran
end

if (@transactionIsolationLevel = 1) SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
if (@transactionIsolationLevel = 2) SET TRANSACTION ISOLATION LEVEL READ COMMITTED
if (@transactionIsolationLevel = 3) SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
if (@transactionIsolationLevel = 4) SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
if (@transactionIsolationLevel = 5) SET TRANSACTION ISOLATION LEVEL SNAPSHOT

return 0
GO
GRANT EXECUTE ON [dbo].[GetNKey] TO Public
GO
/*********************************************************************/
/* end sp_GetNKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetNKeys.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetNKeys]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetNKeys]
GO

create PROCEDURE [dbo].[GetNKeys]
  (@sTable varchar(50) = null,
  @nKeyCount int,
  @nNewKey int = null output)
AS
--<VERSION>9.2.20</VERSION>
--<DATE>2013-11-22</DATE>
--<SUMMARY>Возвращает опред. количество ключей для таблицы</SUMMARY>
declare @nID int
declare @keyTable varchar(100)
declare @query nvarchar (600)
declare @transactionIsolationLevel int

SELECT @transactionIsolationLevel = transaction_isolation_level 
FROM sys.dm_exec_sessions 
where session_id = @@spid

SET TRANSACTION ISOLATION LEVEL serializable;

set nocount on

if @nKeyCount is null
	set @nKeyCount = 0
	
if @sTable like 'TP_TOURDATES'
	set @sTable = 'TP_TURDATES'

set nocount on

select @keyTable = 
	case 
		when @sTable like 'TP_TURDATES' then 'Key_TPTurDates'
		when @sTable like 'TP_Lists' then 'Key_TPLists'
		when @sTable like 'TP_Services' then 'Key_TPServices'
		when @sTable like 'TP_Tours' then 'Key_TPTours'
		when @sTable like 'TP_ServiceLists' then 'Key_TPServiceLists'
		when @sTable like 'TP_Prices' then 'Key_TPPrices'
		when @sTable like 'TURSERVICE' then 'Key_TURSERVICE'
		when @sTable like 'TURIST' then 'Key_TURIST'
		when @sTable like 'TURLIST' then 'Key_TURLIST'
		when @sTable like 'TurMargin' then 'Key_TurMargin'
		when @sTable like 'PRICELIST' then 'Key_PRICELIST'
		when @sTable like 'PRICESERVICELINK' then 'Key_PRICESERVICELINK'
		when @sTable like 'PARTNERS' then 'Key_PARTNERS'
	end

if @keyTable is not null
begin
	set @query = N'
	declare @maxKeyFromTable int 
	declare @maxKeyFromKeys int
	
	Select @maxKeyFromTable = id from @keyTable (updlock) 
	Select @maxKeyFromKeys = id from Keys WITH (UPDLOCK) where Key_Table = ''@sTable''
	If @maxKeyFromKeys is null Or @maxKeyFromKeys < @maxKeyFromTable
		Set @nNewKeyOut = @maxKeyFromTable 
	Else 
		Set @nNewKeyOut = @maxKeyFromKeys
	--
	Set @nNewKeyOut = @nNewKeyOut + @nKeyCount
	update @keyTable set Id = @nNewKeyOut
	update Keys set Id = @nNewKeyOut where Key_Table = ''@sTable''
	'
	begin tran
	set @query = REPLACE(@query, '@keyTable', @keyTable)
	set @query = REPLACE(@query, '@sTable', @sTable)
	EXECUTE sp_executesql @query, N'@nNewKeyOut int output, @nKeyCount int', @nNewKeyOut = @nNewKey  output,  @nKeyCount = @nKeyCount
	commit tran
end
else
begin
	begin tran
	if exists (select top 1 1 from Keys where Key_Table = @sTable)
	begin
		Select @nNewKey = id + @nKeyCount from Keys WITH (UPDLOCK) where Key_Table = @sTable
		update Keys set Id = @nNewKey where Key_Table = @sTable
	end
	else
	begin
		insert into Keys (Key_Table, Id) values (@sTable, @nKeyCount)
		set @nNewKey=@nKeyCount
	end
	commit tran
end

if (@transactionIsolationLevel = 1) SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
if (@transactionIsolationLevel = 2) SET TRANSACTION ISOLATION LEVEL READ COMMITTED
if (@transactionIsolationLevel = 3) SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
if (@transactionIsolationLevel = 4) SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
if (@transactionIsolationLevel = 5) SET TRANSACTION ISOLATION LEVEL SNAPSHOT

return 0
GO
grant exec on [dbo].[GetNKeys] to public
GO
/*********************************************************************/
/* end sp_GetNKeys.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetServiceAddCosts.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceAddCosts]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceAddCosts]
GO
CREATE PROCEDURE [dbo].[GetServiceAddCosts]
	(
		-- хранимка расчитывает доплаты по услуге
		--<date>2013-11-12</date>
		--<version>9.2.20</version>
		/*mv 27.01.2012 : Внимание!
			в хранимке [dbo].[GetServiceAddCosts] 
			добавил параметр @days - новый обязательный параметр
			передача ключа партнера теперь идет сразу за SubCode2 (по аналогии с GetServiceCosts)
			переименовал параметр, возвращающий валюту @addCostRate
		  mv 27.01.2012_2 Добавил учет типа доплаты (за взрослого/ребенка и т.д.)
		  mv 27.01.2012_3 Добавил параметр "дата расчета" - @sellDate
		  AleXK 31.01.2012 Добавил 2 выходных параметра доплата за ребенка и доплата за взрослого
		  Gorshkov 10.02.2012 Добавил необязательный параметр - тип доплаты (@addCostType)
		  Gorshkov 10.02.2012_2 Теперь хранимка возвращает не сумму всех доплат, а только сумму последних доплат по каждому классу доплат
		  Beylkhanov 12.11.2013 Изменилась сортировка при выборе приоритетной доплаты, теперь сортировка по ключу доплаты будет с убыванием
		  т.е. доплата с наибольшим ключем должна быть более приоритетна.
		*/
		@tourKey int,
		@svKey int,
		@code int,
		@SubCode1 int,
		@SubCode2 int,
		@partnerKey int,
		@tourDate datetime,
		@tourDays int,
		@serviceDays int,
		@men int,
		@sellDate datetime = null,
		@addCostClass int = null,
		@addCostValueIsCommission money output,
		@addCostValueNoCommission money output,
		-- тут доплата только за 1 взрослого
		@addCostFromAdult money output,
		-- тут доплата только за 1 ребенка
		@addCostFromChild money output,
		@addCostRate nvarchar(2) output
	)
AS
BEGIN
	set @addCostValueIsCommission = null
	set @addCostValueNoCommission = null
	set @addCostFromAdult = null
	set @addCostFromChild = null
	set	@addCostRate=null

	if @tourKey is null
	begin
		return 0
	end

	declare @internal_pansionKey int, @internal_subCode1 int, @internal_subCode2 int, @internal_subCode3 int,
			@internal_Main_Count int, @internal_ExB_Count int
	-- отдельно обработаем отель
	if (@svKey = 3)
	begin
		set @internal_pansionKey = @SubCode2
		
		select @internal_subCode1 = HR_RMKEY, @internal_subCode2 = HR_RCKEY, @internal_subCode3=HR_ACKEY
		from HotelRooms with(nolock)
		where HR_KEY = @SubCode1
		
		if @internal_subCode1 is null
		begin
			return 0
		end
		
		select @internal_Main_Count=IsNull(AC_NRealPlaces,0), @internal_ExB_Count=IsNull(AC_NMenExBed,0) 
		from Accmdmentype with(nolock)
		where AC_Key=@internal_subCode3
		
		-- если доплата за человека то берем количество людей из Accmdmentype
		set @men = @internal_Main_Count
		
		If @internal_Main_Count=0 and @internal_ExB_Count=0
		begin
			set @internal_Main_Count=1
		end
	end
	else
	begin
		set @internal_pansionKey = null
		set @internal_subCode1=@SubCode1 
		set @internal_subCode2=@SubCode2
	end
	
	-- если наща услуга без продолжительности то устанавливаем ей продолжительность равную продолжительности тура
	-- что бы доплата не обнылялась если она за сутки
	if (exists (select top 1 1 from [Service] with(nolock) where SV_KEY = @svKey and SV_IsDuration != 1))
	begin
		set @serviceDays = @tourDays
	end;
	
	with onlyNeededAddCosts as
	(
		select *
		from dbo.AddCosts with(nolock)
		where 
			ADC_TLKey = @tourKey
			and ADC_SVKey = @svKey
			and (ADC_Code = 0 or ADC_Code = @code)
			and (ADC_SubCode1=0 or ADC_SubCode1 = @internal_subCode1)
			and (ADC_SubCode2=0 or ADC_SubCode2 = @internal_subCode2)
			and (ADC_PartnerKey=0 or ADC_PartnerKey = @partnerKey)
			and ((@internal_pansionKey is not null and (ADC_PansionKey=0 or ADC_PansionKey = @internal_pansionKey)) or (@internal_pansionKey is null))	
			and @tourDate between ADC_CheckinDateBeg and ADC_CheckinDateEnd
			and ((isnull(ADC_LongMin, 0) = 0 and isnull(ADC_LongMax, 0) = 0) or (@tourDays between ADC_LongMin and ADC_LongMax))
			and ((@sellDate is not null and @sellDate >= ADC_CreateDate) or (@sellDate is null))
			and ((ADC_DisableDate is null) or (ADC_DisableDate is not null and @sellDate < ADC_DisableDate))
			and (@addCostClass is null or ADC_ACNId = @addCostClass)
	),
	theLatestInEachAddCostType as
	(
		select ADC_TypeId, ADC_Value, ADC_ValueChild, ADC_CreateDate, ADC_Rate, ADC_IsCommission, ADC_IsDay
		from onlyNeededAddCosts as onac
		where ADC_Id = (select top 1 ac.ADC_ID
						from onlyNeededAddCosts as ac
						where ac.ADC_ACNId = onac.ADC_ACNId
						order by ac.ADC_CreateDate desc, ac.ADC_ID desc)
	)
	
	select top 1
		@addCostValueIsCommission = sum(case when ADC_IsCommission = 1 then isnull(ADC_Value * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END) * (CASE ADC_TypeID WHEN 1 THEN 1 WHEN 3 THEN @internal_Main_Count ELSE @men END), 0) else 0 end) +
									sum(case when ADC_IsCommission = 1 then isnull(isnull(ADC_ValueChild, 0) * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END) * (CASE ADC_TypeID WHEN 1 THEN 0 when 2 then 0 WHEN 3 THEN @internal_ExB_Count END), 0) else 0 end),
		@addCostValueNoCommission = sum(case when ADC_IsCommission = 0 then isnull(ADC_Value * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END) * (CASE ADC_TypeID WHEN 1 THEN 1 WHEN 3 THEN @internal_Main_Count ELSE @men END), 0) else 0 end) +
									sum(case when ADC_IsCommission = 0 then isnull(isnull(ADC_ValueChild, 0) * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END) * (CASE ADC_TypeID WHEN 1 THEN 0 when 2 then 0 WHEN 3 THEN @internal_ExB_Count END), 0) else 0 end),
		@addCostFromAdult = sum(isnull(ADC_Value * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END), 0)),
		@addCostFromChild = sum(isnull((case when ADC_TypeID = 3 then isnull(ADC_ValueChild, 0) else ADC_Value end) * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END), 0)),
		@addCostRate = ADC_Rate
	from theLatestInEachAddCostType
	group by ADC_Rate;
END
GO
grant exec on [dbo].[GetServiceAddCosts] to public
GO
/*********************************************************************/
/* end sp_GetServiceAddCosts.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCheckPriceTables.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckPriceTables]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwCheckPriceTables]
GO

CREATE procedure [dbo].[mwCheckPriceTables] (@jobId smallint = null)
as
begin
	--<VERSION>2009.2.20.1</VERSION>
	--<DATE>2013-11-13</DATE>
	declare @divideByCountry as bit
	set @divideByCountry = 0
	select @divideByCountry = SS_ParmValue from SystemSettings where SS_ParmName = 'MWDivideByCountry'

	if dbo.mwReplIsSubscriber() <= 0 
		and dbo.mwReplIsPublisher() <= 0
		and @divideByCountry = 1
	begin
		-- сегментирование ценовых таблиц без репликации.
		-- необходимо создать ценовые таблицы по новым направлениям
		declare @ctFromKey as int, @cnKey as int
		declare tCur cursor for
			select distinct ptl_ctFromKey, ptl_cnKey
			from mwPriceTablesList with (nolock)
			left join sys.tables on name = 'mwPriceDataTable_' + ltrim(rtrim(str(ptl_cnKey))) + '_' + ltrim(rtrim(str(ptl_ctFromKey)))
			where name is null
				
		open tCur
				
		fetch next from tCur into @ctFromKey, @cnKey
		while @@fetch_status = 0
		begin
				
			insert into SystemLog (sl_message) values ('Job mwCheckPriceTables. Attempt to create price table: city ' 
				+ str(@ctFromKey) + ' country ' + str(@cnKey))
				
			begin try
				
				exec mwCreateNewPriceTable @cnKey, @ctFromKey, 1
					
				delete from mwPriceTablesList where ptl_ctFromKey = @ctFromKey and ptl_cnKey = @cnKey
					
				insert into SystemLog (sl_message) values ('Job mwCheckPriceTables. Table: city ' 
					+ str(@ctFromKey) + ' country ' + str(@cnKey) + ' created.')
					
			end try
			begin catch
				
				insert into SystemLog (sl_date, sl_message) values (getdate(), 'Job mwCheckPriceTables. Error creating table' 
					+ str(@ctFromKey) + ' country ' + str(@cnKey) + '. Error: ' + error_message())
				
			end catch
				
			fetch next from tCur into @ctFromKey, @cnKey
			
		end
			
		close tCur
		deallocate tCur
	end

end
GO

grant exec on [dbo].[mwCheckPriceTables] to public
GO
/*********************************************************************/
/* end sp_mwCheckPriceTables.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwFillTP.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwFillTP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwFillTP]
GO

CREATE procedure [dbo].[mwFillTP] (@tokey int, @calcKey int = null)
as
begin
	-- <date>2013-11-12</date>
	-- <version>2009.2.20.1</version>
	declare @sql varchar(4000)
	declare @source varchar(200)
	set @source = ''
	
	declare @where as varchar(4000)

	declare @tokeyStr varchar (20)
	set @tokeyStr = cast(@tokey as varchar(20))

	declare @calcKeyStr varchar (20)
	set @calcKeyStr = cast(@calcKey as varchar(20))

	if dbo.mwReplIsSubscriber() > 0 and len(dbo.mwReplPublisherDB()) > 0
		set @source = '[mt].' + dbo.mwReplPublisherDB() + '.'
	
	delete from dbo.tp_tours where to_key = @calcKey	
	if not exists(select 1 from dbo.tp_tours with(nolock) where to_key = @tokey)
	begin
		set @sql = '
		insert into dbo.tp_tours with(rowlock) (
			[TO_Key],
			[TO_TRKey],
			[TO_Name],
			[TO_PRKey],
			[TO_CNKey],
			[TO_Rate],
			[TO_DateCreated],
			[TO_DateValid],
			[TO_PriceFor],
			[TO_OpKey],
			[TO_XML],
			[TO_DateBegin],
			[TO_DateEnd],
			[TO_IsEnabled],
			[TO_PROGRESS],
			[TO_UPDATE],
			[TO_UPDATETIME],
			[TO_DateValidBegin],
			[TO_CalculateDateEnd],
			[TO_PriceCount],
			[to_attribute],
			[TO_MinPrice],
			[TO_HotelNights]
		)
		select
			[TO_Key],
			[TO_TRKey],
			[TO_Name],
			[TO_PRKey],
			[TO_CNKey],
			[TO_Rate],
			[TO_DateCreated],
			[TO_DateValid],
			[TO_PriceFor],
			[TO_OpKey],
			[TO_XML],
			[TO_DateBegin],
			[TO_DateEnd],
			[TO_IsEnabled],
			[TO_PROGRESS],
			[TO_UPDATE],
			[TO_UPDATETIME],
			[TO_DateValidBegin],
			[TO_CalculateDateEnd],
			[TO_PriceCount],
			[to_attribute],
			[TO_MinPrice],
			[TO_HotelNights]
		from
			' + @source + 'dbo.tp_tours with(nolock)
		where
			to_key = ' + @tokeyStr

		exec (@sql)
	end
	
    delete dbo.tp_services where ts_tokey = @tokey
	--if not exists(select 1 from dbo.tp_services with(nolock) where ts_tokey = @calcKey)
	begin
		set @sql = 
		'insert into dbo.tp_services with(rowlock) (
			[TS_Key],
			[TS_TOKey],
			[TS_SVKey],
			[TS_Code],
			[TS_SubCode1],
			[TS_SubCode2],
			[TS_CNKey],
			[TS_CTKey],
			[TS_Day],
			[TS_Days],
			[TS_Men],
			[TS_Name],
			[TS_OpPartnerKey],
			[TS_OpPacketKey],
			[TS_Attribute],
			[TS_TEMPGROSS],
			[TS_CHECKMARGIN],
			[TS_CalculatingKey]
		)
		select top 10000
			[TS_Key],
			[TS_TOKey],
			[TS_SVKey],
			[TS_Code],
			[TS_SubCode1],
			[TS_SubCode2],
			[TS_CNKey],
			[TS_CTKey],
			[TS_Day],
			[TS_Days],
			[TS_Men],
			[TS_Name],
			[TS_OpPartnerKey],
			[TS_OpPacketKey],
			[TS_Attribute],
			[TS_TEMPGROSS],
			[TS_CHECKMARGIN],
			[TS_CalculatingKey]
		from
			' + @source + 'dbo.tp_services with(nolock)
		where
			'

		set @where = ''
		set @where = 'TS_TOKey = ' + @tokeyStr
		set @where = @where + ' and TS_Key not in (select TS_Key from dbo.tp_services with (nolock) where TS_TOKey = ' + @tokeyStr + ')'

		set @sql = 'while exists (select top 1 1 from ' + @source + 'dbo.tp_services  as r with (nolock) where ' + @where + ')
		begin
		' + @sql + @where + '
		end'

		exec (@sql)
	end

	delete from dbo.tp_lists where ti_tokey = @tokey
	--if not exists(select 1 from dbo.tp_lists with(nolock) where ti_tokey = @calcKey)
	begin
		set @sql = 
		'insert into dbo.tp_lists with(rowlock) (
			[TI_Key],
			[TI_TOKey],
			[TI_Name],
			[TI_FirstHDKey],
			[TI_FirstHRKey],
			[TI_FirstPNKey],
			[TI_Days],
			[TI_HotelKeys],
			[TI_PansionKeys],
			[TI_HotelDays],
			[TI_FirstHDStars],
			[TI_FirstRsKey],
			[TI_SecondHDKey],
			[TI_SecondHRKey],
			[TI_SecondPNKey],
			[TI_SecondHDStars],
			[TI_SecondCtKey],
			[TI_SecondRsKey],
			[TI_CtKeyFrom],
			[TI_CtKeyTo],
			[TI_ApKeyFrom],
			[TI_ApKeyTo],
			[ti_firsthotelday],
			[ti_hdpartnerkey],
			[ti_totaldays],
			[ti_nights],
			[ti_lasthotelday],
			[ti_chkey],
			[ti_chbackkey],
			[ti_hdday],
			[ti_hdnights],
			[ti_chday],
			[ti_chbackday],
			[ti_chpkkey],
			[ti_chprkey],
			[ti_chbackpkkey],
			[ti_chbackprkey],
			[TI_FirstCtKey],
			[TI_UPDATE],
			[TI_FIRSTHOTELPARTNERKEY],
			[ti_hotelroomkeys],
			[ti_hotelstars],
			[TI_CalculatingKey]
		)
		select top 10000
			[TI_Key],
			[TI_TOKey],
			[TI_Name],
			[TI_FirstHDKey],
			[TI_FirstHRKey],
			[TI_FirstPNKey],
			[TI_Days],
			[TI_HotelKeys],
			[TI_PansionKeys],
			[TI_HotelDays],
			[TI_FirstHDStars],
			[TI_FirstRsKey],
			[TI_SecondHDKey],
			[TI_SecondHRKey],
			[TI_SecondPNKey],
			[TI_SecondHDStars],
			[TI_SecondCtKey],
			[TI_SecondRsKey],
			[TI_CtKeyFrom],
			[TI_CtKeyTo],
			[TI_ApKeyFrom],
			[TI_ApKeyTo],
			[ti_firsthotelday],
			[ti_hdpartnerkey],
			[ti_totaldays],
			[ti_nights],
			[ti_lasthotelday],
			[ti_chkey],
			[ti_chbackkey],
			[ti_hdday],
			[ti_hdnights],
			[ti_chday],
			[ti_chbackday],
			[ti_chpkkey],
			[ti_chprkey],
			[ti_chbackpkkey],
			[ti_chbackprkey],
			[TI_FirstCtKey],
			[TI_UPDATE],
			[TI_FIRSTHOTELPARTNERKEY],
			[ti_hotelroomkeys],
			[ti_hotelstars],
			[TI_CalculatingKey]
		from
			' + @source + 'dbo.tp_lists with(nolock)
		where
			'
			
		set @where = ''
		if(@calcKey is not null)
			set @where = 'TI_Key in (select TP_TIKey from ' + @source + 'dbo.TP_Prices where TP_TOKey = TI_TOKey and TP_CalculatingKey = ' + ltrim(str(@calcKey)) + ') and '
		
		set @where = @where + 'TI_TOKey = ' + @tokeyStr
		set @where = @where + ' and TI_Key not in (select TI_Key from dbo.tp_lists with (nolock) where TI_TOKey = ' + @tokeyStr + ')'

		set @sql = 'while exists (select top 1 1 from ' + @source + 'dbo.tp_lists as r with (nolock) where ' + @where + ')
		begin
		' + @sql + @where + '
		end'

		exec (@sql)
	end

	delete from dbo.tp_servicelists where tl_tokey = @tokey
	--if not exists(select 1 from dbo.tp_servicelists with(nolock) where tl_tokey = @calcKey)
	begin	
		set @sql = 
		'
		set identity_insert tp_serviceLists on

		insert into dbo.tp_servicelists with(rowlock) (
			[TL_Key],
			[TL_TOKey],
			[TL_TSKey],
			[TL_TIKey],
			[TL_CalculatingKey]
		)
		select top 10000
			[TL_Key],
			[TL_TOKey],
			[TL_TSKey],
			[TL_TIKey],
			[TL_CalculatingKey]
		from
			' + @source + 'dbo.tp_servicelists with(nolock)
		where
			'

		set @where = 'TL_TOKey = ' + @tokeyStr
		set @where = @where + ' and TL_Key not in (select TL_Key from dbo.tp_servicelists with (nolock) where TL_TOKey = ' + @tokeyStr + ')'

		set @sql = 'while exists (select top 1 1 from ' + @source + 'dbo.tp_servicelists as r with (nolock) where ' + @where + ')
		begin
		' + @sql + @where + '
		end
		
		set identity_insert tp_serviceLists off'

		exec (@sql)
	end

	delete from dbo.tp_prices where tp_tokey = @tokey
	--if not exists(select 1 from dbo.tp_prices with(nolock) where tp_tokey = @calcKey)
	begin
		set @sql = 
		'insert into dbo.tp_prices with(rowlock) (
			[TP_Key],
			[TP_TOKey],
			[TP_DateBegin],
			[TP_DateEnd],
			[TP_Gross],
			[TP_TIKey],
			[TP_CalculatingKey]
		)
		select top 5000
			[TP_Key],
			[TP_TOKey],
			[TP_DateBegin],
			[TP_DateEnd],
			[TP_Gross],
			[TP_TIKey],
			[TP_CalculatingKey]
		from
			' + @source + 'dbo.tp_prices with(nolock)
		where
			'

		set @where = ''
		if(@calcKey is not null)
			set @where = 'TP_CalculatingKey = ' + @calcKeyStr + ' and TP_Key not in (select TP_Key from dbo.tp_prices with (nolock) where TP_CalculatingKey = ' + @calcKeyStr + ')'
		else
			set @where = 'TP_TOKey = ' + @tokeyStr + ' and TP_Key not in (select TP_Key from dbo.tp_prices with (nolock) where TP_TOKey = ' + @tokeyStr + ')'
			
		set @sql = 'while exists (select top 1 1 from ' + @source + 'dbo.tp_prices as r with (nolock) where ' + @where + ')
		begin
		' + @sql + @where + '
		end'
		
		exec (@sql)
	end
end
GO

GRANT EXEC ON [dbo].[mwFillTP] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwFillTP.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_RecreateDependentObjects.sql */
/*********************************************************************/
if exists(select top 1 1 from sys.objects where name = 'RecreateDependentObjects' and type = 'P')
	drop procedure RecreateDependentObjects
go

create procedure RecreateDependentObjects
-- выполняет указанный скрипт после удаления и до создания зависимых от колонки @ColumnName объектов
-- сейчас в качестве зависимых объектов поддерживаются только некластеризованные и кластеризованные индексы
--<VERSION>9.2.20</VERSION>
--<DATE>2013-11-22</DATE>
(
	@TableName sysname,				-- имя таблицы, колонка которой удаляется
	@ColumnName sysname,			-- имя удаляемой колонки
	@CustomScript nvarchar(max),	-- скрипт, выполняемый между созданием и удалением зависимых объектов
	@recreateWithoutColumn bit = 0	-- флаг, указывающий, что в зависимые объекты надо пересоздавать без переданной колонки
)
as
begin
	declare @errorMessage nvarchar(max)

	-- check arguments
	if not exists (select top 1 1 from sys.tables where name = @TableName)
	begin
		set @errorMessage = 'Table ' + @TableName + ' was not found in database.'
		RAISERROR(@errorMessage, 16, 1)
		return
	end

	if not exists (select top 1 1 from sys.columns where name = @ColumnName)
	begin
		set @errorMessage = 'Column ' + @ColumnName + ' was not found in database.'
		RAISERROR(@errorMessage, 16, 1)
		return
	end

	if not exists (select top 1 1 from sys.columns where name = @ColumnName and object_id = object_id(@TableName))
	begin
		set @errorMessage = 'Incorrect parameters: column ' + @ColumnName + ' doesn''t belong to table ' + @TableName
		RAISERROR(@errorMessage, 16, 1)
		return
	end

	-- признак, что пересоздание ссылающихся на колонку объектов прошло успешно
	declare @updateReferencesComplete as bit
	declare @errmsg as nvarchar(max)

	-- обработка индексов
	declare @ixName sysname
	declare @ixType tinyint

	declare @totalSql as nvarchar(max)
	declare @dropIndexSql as nvarchar(max)
	declare @createIndexSql as nvarchar(max)
	set @dropIndexSql = ''
	set @createIndexSql = ''

	declare indexesCursor cursor for
	select ix.name, ix.type
	from sys.tables tab
	left join sys.indexes ix on ix.object_id = tab.object_id
	where tab.name = @TableName
		and exists (select top 1 1 
					from sys.index_columns ic
					left join sys.columns col on col.column_id = ic.column_id and col.object_id = tab.object_id
					where ic.index_id = ix.index_id 
						and ic.object_id = tab.object_id
						and col.name = @ColumnName
					)

	open indexesCursor

	begin try

	fetch next from indexesCursor into @ixName, @ixType
	while @@FETCH_STATUS = 0
	begin
		if @ixType <> 2 and @ixType <> 1
		begin
			set @errmsg = 'Not supported index type is dependent on specified column ' + @ColumnName + '
			This stored procedure supports only nonclustered and clustered indexes recreation! Not supported index name: ' 
				+ @ixName + ' on table: ' + @TableName
			RAISERROR(@errmsg, 16, 1)
		end

		declare @indexColumns nvarchar(max)
		declare @includedColumns nvarchar(max)

		set @indexColumns = ''
		set @indexColumns = stuff((select ',' + col.name + 
					case
						when ic.is_descending_key = 1 then ' desc'
						else ' asc'
					end
					from sys.tables tab
					left join sys.indexes ix on ix.object_id = tab.object_id
					left join sys.index_columns ic on ic.object_id = tab.object_id and ic.index_id = ix.index_id
					left join sys.columns col on col.column_id = ic.column_id and col.object_id = tab.object_id
					where ic.index_id = ix.index_id 
						and ic.object_id = tab.object_id
						and ic.is_included_column = 0
						and ((@recreateWithoutColumn = 1 and col.name <> @ColumnName) or @recreateWithoutColumn = 0)
						and tab.name = @TableName
						and ix.name = @ixName
					for xml path(''), type
					).value('.', 'varchar(max)'),1,1,'')

		set @includedColumns = stuff((select ',' + col.name
					from sys.tables tab
					left join sys.indexes ix on ix.object_id = tab.object_id
					left join sys.index_columns ic on ic.object_id = tab.object_id and ic.index_id = ix.index_id
					left join sys.columns col on col.column_id = ic.column_id and col.object_id = tab.object_id
					where ic.index_id = ix.index_id 
						and ic.object_id = tab.object_id
						and ic.is_included_column = 1
						and ((@recreateWithoutColumn = 1 and col.name <> @ColumnName) or @recreateWithoutColumn = 0)
						and tab.name = @TableName
						and ix.name = @ixName
					for xml path(''), type
					).value('.', 'varchar(max)'),1,1,'')

		set @dropIndexSql = @dropIndexSql + '
			drop index [@ixName] on [@TableName]'

		if @indexColumns is not null
		begin
			set @createIndexSql = @createIndexSql + 
			'
			create @indexType index [@ixName] on [@TableName]
			(
				@indexColumns
			)'

			if @includedColumns is not null
			begin
				set @createIndexSql = @createIndexSql + 
				'
				include
				(
					@includedColumns
				)
				'
				set @createIndexSql = replace(@createIndexSql, '@includedColumns', isnull(@includedColumns, ''))
			end
			set @createIndexSql = @createIndexSql + 
			'
			WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, 
				ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
			'
			set @createIndexSql = replace(@createIndexSql, '@indexColumns', @indexColumns)
			set @createIndexSql = replace(@createIndexSql, '@indexType', case when @ixType = 2 then 'nonclustered' when @ixType = 1 then 'clustered' end)
		end

		set @createIndexSql = replace(@createIndexSql, '@ixName', @ixName)
		set @createIndexSql = replace(@createIndexSql, '@TableName', @TableName)
		set @dropIndexSql = replace(@dropIndexSql, '@ixName', @ixName)
		set @dropIndexSql = replace(@dropIndexSql, '@TableName', @TableName)

		fetch next from indexesCursor into @ixName, @ixType
	end
	end try
	begin catch 
		set @errmsg = error_message()
		set @updateReferencesComplete = 0
	end catch

	close indexesCursor
	deallocate indexesCursor

	if @updateReferencesComplete = 0
	begin
		RAISERROR(@errmsg, 16, 1)
		return
	end

	-- execute custom script between drop and recreate dependent objects
	set @totalSql = '
	begin transaction dropAndCreate
	' + @dropIndexSql + '
	' + @customScript + '
	' + @createIndexSql + '
	commit transaction dropAndCreate
	'

	exec sp_executesql @totalSql
end

GO

grant exec on RecreateDependentObjects to public

GO
/*********************************************************************/
/* end sp_RecreateDependentObjects.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_UpdDogListQuota.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_UpdDogListQuota]'))
DROP TRIGGER [dbo].[T_UpdDogListQuota]
GO
CREATE TRIGGER [dbo].[T_UpdDogListQuota] 
ON [dbo].[tbl_DogovorList]
AFTER INSERT, UPDATE, DELETE
AS
--<VERSION>2009.2.19.3</VERSION>
--<DATE>2013-11-21</DATE>

-- тип триггера (DEL - удаление, INS - вставка, UPD - обновление)
-- если включена настройка то выходим, рассадка теперь работает по другому
IF (EXISTS (SELECT TOP 1 1
		    FROM SystemSettings WITH (NOLOCK)
		    WHERE SS_ParmName = 'NewSetToQuota' AND SS_ParmValue = 1))
BEGIN
	RETURN;
END


DECLARE @DLKey int, @DGKey int, @O_DLSVKey int, @O_DLCode int, @O_DLSubcode1 int, @O_DLDateBeg datetime, @O_DLDateEnd datetime, @O_DLNMen int, @O_DLPartnerKey int, @O_DLControl int, 
		@N_DLSVKey int, @N_DLCode int, @N_DLSubcode1 int, @N_DLDateBeg datetime, @N_DLDateEnd datetime, @N_DLNMen int, @N_DLPartnerKey int, @N_DLControl int,
		@O_DLSubcode2 int, @N_DLSubcode2 int,
		@Date datetime, @RLID int, @RPID int,
		@HRIsMain smallint, @RMKey int, @RCKey int, @ACKey int,
		@RMPlacesMain smallint, @RMPlacesEx smallint,
		@ACPlacesMain smallint, @ACPlacesEx smallint, @ACPerRoom smallint,
		@RLPlacesMain smallint, @RLPlacesEx smallint, @RLCount smallint, 
		@AC_FreeMainPlacesCount smallint, @AC_FreeExPlacesCount smallint,
		@RL_Use smallint, @From int, --@SDPlace smallint, 
		@nDelCount smallint, @nInsCount smallint, @Mod varchar(3), @SetToNewQuota bit,
		@CurrentPlaceIsEx bit, @RL_FreeMainPlacesCount smallint, @RL_FreeExPlacesCount smallint,
		@Days smallint, @RPCount smallint, @NeedPlacesForMen smallint, @TUKey int,
		@SVQUOTED smallint

-- количество удаляемых записей
SELECT @nDelCount = COUNT(*)
FROM DELETED
-- количество вставляемых записей
SELECT @nInsCount = COUNT(*)
FROM INSERTED
SET @SetToNewQuota = 0
IF (@nInsCount = 0) -- если нет удаляемых записей, значит есть только вставляемые записи
BEGIN
    DECLARE cur_DogovorListChanged2 CURSOR 
    FOR 
    SELECT O.DL_Key, O.DL_DGKey, O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_SubCode2, O.DL_DateBeg, O.DL_DateEnd, O.DL_NMen, O.DL_PartnerKey, 
    		O.DL_Control, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, null
    FROM DELETED O
	SET @Mod = 'DEL'
END
ELSE IF (@nDelCount = 0) -- если нет вставляемых записей, есть только удаляемые записи
BEGIN
    DECLARE cur_DogovorListChanged2 CURSOR FOR 
    SELECT 	N.DL_Key, N.DL_DGKey,
			null, null, null, null, null, null, null, null, null,
			N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_SubCode2, N.DL_DateBeg, N.DL_DateEnd, N.DL_NMen, N.DL_PartnerKey, N.DL_Control
    FROM	INSERTED N 
	SET @Mod = 'INS'
END
ELSE -- если есть и удаляемые и вставляемые записи
BEGIN
    DECLARE cur_DogovorListChanged2 CURSOR FOR 
    SELECT 	N.DL_Key, N.DL_DGKey, 
		O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_Subcode2, O.DL_DateBeg, O.DL_DateEnd, O.DL_NMen, O.DL_PartnerKey, O.DL_Control,
		N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_Subcode2, N.DL_DateBeg, N.DL_DateEnd, N.DL_NMen, N.DL_PartnerKey, N.DL_Control
    FROM DELETED O, INSERTED N 
    WHERE N.DL_Key = O.DL_Key
	SET @Mod = 'UPD'
END

OPEN cur_DogovorListChanged2
FETCH NEXT 
FROM cur_DogovorListChanged2 
INTO @DLKey, @DGKey, @O_DLSVKey, @O_DLCode, @O_DLSubCode1, @O_DLSubcode2, @O_DLDateBeg, @O_DLDateEnd, @O_DLNMen, @O_DLPartnerKey, @O_DLControl, 
	@N_DLSVKey, @N_DLCode, @N_DLSubCode1, @N_DLSubcode2, @N_DLDateBeg, @N_DLDateEnd, @N_DLNMen, @N_DLPartnerKey, @N_DLControl
WHILE @@FETCH_STATUS = 0
BEGIN
	--18-10-2012 saifullina
	--при удалении услуги в путевке или аннулировании путевки -> удаляем путевку -> высвобождаем квоты
	IF (@N_DLDateBeg < '01-01-1901' AND @O_DLDateBeg >= '01-01-1901')
	BEGIN
		SET @Mod = 'DEL'
	END
	IF (@Mod = 'DEL'
		OR (@Mod = 'UPD' AND (ISNULL(@O_DLSVKey, 0) != ISNULL(@N_DLSVKey, 0))
			OR (ISNULL(@O_DLCode, 0) != ISNULL(@N_DLCode, 0))
			OR (ISNULL(@O_DLSubCode1, 0) != ISNULL(@N_DLSubCode1, 0))
			or (ISNULL(@O_DLSubCode2,0) != ISNULL(@N_DLSubCode2,0) and ISNULL(@N_DLSVKey,0) not in (1,3)
				and EXISTS(SELECT TOP 1 1 FROM [Service] WITH(NOLOCK) WHERE SV_IsSubCode2=1 AND SV_Quoted=1 AND SV_Key=ISNULL(@N_DLSVKey,0)))
			OR (ISNULL(@O_DLPartnerKey, 0) != ISNULL(@N_DLPartnerKey, 0))
			OR (ISNULL(@O_DLDateBeg, 0) != ISNULL(@N_DLDateBeg, 0))
			OR (ISNULL(@O_DLDateEnd, 0) != ISNULL(@N_DLDateEnd, 0))))
	BEGIN	
		DELETE
		FROM ServiceByDate
		WHERE SD_DLKey = @DLKey

		SET @SetToNewQuota = 1
	END
		
	SELECT @SVQUOTED = ISNULL(SV_Quoted, 0)
	FROM [Service]
	WHERE SV_KEY = @N_DLSVKey

	EXEC InsMasterEvent 3, @DLKey

	IF ((@O_DLSVKey IN (3, 7)
	    AND (@N_DLCode != @O_DLCode
	        OR @N_DLSubCode1 != @O_DLSubCode1
	        OR @O_DLDateBeg != @N_DLDateBeg
	        OR @O_DLDateEnd != @N_DLDateEnd))
		OR (@O_DLSVKey IN (1, 2, 4) 
		    AND @O_DLDateBeg != @N_DLDateBeg))
	BEGIN
		UPDATE TuristService
		SET TU_NUMROOM = ''
		WHERE TU_DLKEY = @DLKey
	END

	IF (@N_DLDateBeg < '01-JAN-1901' AND @O_DLDateBeg >= '01-JAN-1901')
	BEGIN
		SET @Mod = 'DEL'
	END

	IF (@N_DLDateBeg > '01-JAN-1901' AND @O_DLDateBeg <= '01-JAN-1901')
	BEGIN
		SET @SetToNewQuota = 1
	END

	IF (@Mod = 'UPD' AND ISNULL(@O_DLNMen, 0) = 0 AND ISNULL(@N_DLNMen, 0) > 0)
	BEGIN
		SET @Mod = 'INS'
	END
	-- если ВЫКЛЮЧЕНА настройка то запускаем всю эту дребедень, это старая рассадка в квоту
	-- ИЛИ произошла ошибка при посадке новым сервисом, то запускаем старую рассадку и проверку
	if (exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota' and SS_ParmValue = 0))
	BEGIN
		print 'Старая рассадка'
		--изменился период действия услуги
		IF @Mod = 'UPD' 
			and (
				@SetToNewQuota!=1 
				and (
					(@O_DLDateBeg != @N_DLDateBeg) 
					or (@O_DLDateEnd != @N_DLDateEnd)
					)
				)
		BEGIN
			IF (@N_DLDateBeg > @O_DLDateEnd OR @N_DLDateEnd < @O_DLDateBeg)
			BEGIN
				DELETE
				FROM ServiceByDate
				WHERE SD_DLKey = @DLKey
				SET @SetToNewQuota=1
			END
			-- для услуг имеющих продолжительность сохраняем информацию о квотировании в рамках периода
			ELSE
			BEGIN
				--если теперь услуга заканчивается раньше, чем до этого начиналась
				IF (@N_DLDateBeg < @O_DLDateBeg)
				BEGIN
					IF (@N_DLDateEnd < @O_DLDateBeg)
					BEGIN
						SET @Days = DATEDIFF(DAY, @N_DLDateBeg, @N_DLDateEnd) + 1
					END
					ELSE
					BEGIN
						SET @Days = DATEDIFF(DAY, @N_DLDateBeg, @O_DLDateBeg)
					END
						
					INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, SD_State)
					SELECT DATEADD(DAY,NU_ID-1,@N_DLDateBeg), SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, @SVQUOTED + 3 
					FROM ServiceByDate, Numbers
					WHERE (NU_ID BETWEEN 1 AND @Days) AND SD_Date = @O_DLDateBeg AND SD_DLKey = @DLKey
				END
				
				--если теперь услуга начинается позже, чем до этого заканчивалась
				IF (@N_DLDateEnd > @O_DLDateEnd)
				BEGIN
					IF (@N_DLDateBeg > @O_DLDateEnd)
					BEGIN
						SET @Days = DATEDIFF(DAY, @N_DLDateBeg, @N_DLDateEnd) + 1
					END
					ELSE
					BEGIN
						SET @Days = DATEDIFF(DAY, @O_DLDateEnd, @N_DLDateEnd)
					END
						
					INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, SD_State)
					SELECT DATEADD(DAY, - NU_ID + 1, @N_DLDateEnd), SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, @SVQUOTED + 3
					FROM ServiceByDate, Numbers
					WHERE (NU_ID BETWEEN 1 AND @Days) AND SD_Date = @O_DLDateEnd AND SD_DLKey = @DLKey
				END
				
				
				IF (@N_DLDateBeg > @O_DLDateBeg)
				BEGIN
					DELETE
					FROM ServiceByDate
					WHERE SD_DLKey = @DLKey AND SD_Date < @N_DLDateBeg
				END
				IF (@N_DLDateEnd < @O_DLDateEnd)
				BEGIN
					DELETE
					FROM ServiceByDate
					WHERE SD_DLKey = @DLKey AND SD_Date > @N_DLDateEnd
				END
			END
			
			-- если эта услуга на продолжительность
			-- и если услуга сидела на квоте с продолжительностью
			IF (EXISTS (SELECT 1
			            FROM [Service]
			            WHERE SV_KEY = @N_DLSVKey AND ISNULL(SV_ISDURATION, 0) = 1)
			    AND EXISTS (
			        SELECT 1
			        FROM ServiceByDate
			        WHERE SD_DLKey = @DLKey
			        AND EXISTS (
			            SELECT 1
			            FROM QuotaParts
			            WHERE QP_ID = SD_QPID AND QP_Durations IS NOT NULL)))
			BEGIN
				-- пересаживаем всю услугу
				EXEC DogListToQuotas @DLKey, NULL, NULL, NULL, NULL, @N_DLDateBeg, @N_DLDateEnd, NULL, NULL, @OldSetToQuota = 1
			END
		END
		SET @NeedPlacesForMen=0
		SET @From = CAST(@N_DLDateBeg as int)		
		-- если изменилось количество человек		
		IF @Mod = 'UPD' AND (@SetToNewQuota != 1 AND ISNULL(@O_DLNMen, 0) != ISNULL(@N_DLNMen, 0))
		BEGIN
		
			select *, 0 as xSD_STATE
			into #ServiceByDate
			from ServiceByDate
			where SD_DLKey = @DLKey
			
			SET @NeedPlacesForMen=ISNULL(@N_DLNMen,0)-ISNULL(@O_DLNMen,0)

			-- если новое число туристов меньше, чем было до этого (@O_DLNMen > @N_DLNMen)
			if ISNULL(@O_DLNMen,0) > ISNULL(@N_DLNMen,0)
			BEGIN
				while (SELECT count(1) FROM #ServiceByDate WHERE SD_DLKey=@DLKey and SD_Date=@N_DLDateBeg) > ISNULL(@N_DLNMen,0)
				BEGIN
					if @N_DLSVKey = 3 --для проживания отдельная ветка
					BEGIN					
						SELECT TOP 1 @RLID = SD_RLID, @RPCount = count(SD_ID) FROM #ServiceByDate WHERE SD_DLKey = @DLKey and SD_TUKey is null and SD_Date = @N_DLDateBeg
						GROUP BY SD_RLID
						ORDER BY 2
						
						SELECT TOP 1 @RPID = SD_RPID FROM #ServiceByDate WHERE SD_DLKey = @DLKey and SD_RLID = @RLID and SD_TUKey is null
						DELETE FROM #ServiceByDate WHERE SD_DLKey = @DLKey and SD_RLID = @RLID and ISNULL(SD_RPID,0) = ISNULL(@RPID,0) and SD_TUKey is null
					END
					ELSE
					BEGIN
						--обязательно!!! NULL туриста вперед 
						SELECT TOP 1 @RPID = SD_RPID FROM #ServiceByDate WHERE SD_DLKey = @DLKey order by SD_TUKey
						DELETE FROM #ServiceByDate WHERE SD_DLKey = @DLKey and ISNULL(SD_RPID,0) = ISNULL(@RPID,0)
					END
				END
				
				delete from ServiceByDate where SD_DLKey = @DLKey and SD_ID not in (select x.SD_ID from #ServiceByDate as x)
			END
			-- если новое число туристов больше, чем было до этого (@O_DLNMen < @N_DLNMen)
			ELSE
			BEGIN
				if @N_DLSVKey=3 --для проживания отдельная ветка
				BEGIN				
					SELECT	@HRIsMain=AC_MAIN, @ACPlacesMain=ISNULL(AC_NRealPlaces,0), @ACPlacesEx=ISNULL(AC_NMenExBed,0), @ACPerRoom=ISNULL(AC_PerRoom,0)
					FROM AccmdMenType
					WHERE AC_Key=(SELECT HR_ACKey From HotelRooms WHERE HR_Key=@N_DLSubCode1)
					IF @HRIsMain = 1 and @ACPlacesMain = 0 and @ACPlacesEx = 0
						set @ACPlacesMain = 1
					ELSE IF @HRIsMain = 0 and @ACPlacesMain = 0 and @ACPlacesEx = 0
						set @ACPlacesEx = 1
					--есть 3 варианта размещения: только основные, только дополнительные, основные и дополнительные
					--в первых 2-х вариантах сначала занимаем свободные уже существующие места данного типа в номерах этой услуги, в последнем занимаем все свободные места
					if @ACPlacesMain>0
						WHILE (@NeedPlacesForMen>0 and EXISTS(select RP_ID FROM RoomPlaces where RP_RLID in (SELECT SD_RLID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_Type=0))
						BEGIN
							select TOP 1 @RPID=RP_ID,@RLID=RP_RLID FROM RoomPlaces where RP_RLID in (SELECT SD_RLID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_Type=0
							INSERT INTO #ServiceByDate (xSD_STATE, SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_State)	
								SELECT 1, CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RLID, @RPID, 4
								FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@N_DLDateEnd as int)-@From+1
							SET @NeedPlacesForMen=@NeedPlacesForMen-1
						END
					if @ACPlacesEx>0
						WHILE (@NeedPlacesForMen>0 and EXISTS(select RP_ID FROM RoomPlaces where RP_RLID in (SELECT SD_RLID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_Type=1))
						BEGIN
							select TOP 1 @RPID=RP_ID,@RLID=RP_RLID FROM RoomPlaces where RP_RLID in (SELECT SD_RLID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_Type=1
							INSERT INTO #ServiceByDate (xSD_STATE, SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_State)	
								SELECT 1, CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RLID, @RPID, 4
								FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@N_DLDateEnd as int)-@From+1
							SET @NeedPlacesForMen=@NeedPlacesForMen-1
						END
				END
				
				insert into ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_QPID, SD_TUKey, SD_RPID, SD_State)
				select x.SD_Date, x.SD_DLKey, x.SD_RLID, x.SD_QPID, x.SD_TUKey, x.SD_RPID, x.SD_State
				from #ServiceByDate as x
				where x.xSD_STATE = 1
				
			END
			
			drop table #ServiceByDate
		END

		IF @Mod = 'INS'
			OR (@Mod = 'UPD' AND @SetToNewQuota = 1)
			OR @NeedPlacesForMen > 0
		BEGIN		
			-- для проживания отдельная ветка
			IF @N_DLSVKey = 3
			BEGIN
				If @NeedPlacesForMen>0
				BEGIN
				SELECT TOP 1 @RLPlacesMain = RL_NPlaces, @RLPlacesEx = RL_NPlacesEx, @RMKey = RL_RMKey, @RCKey = RL_RCKey
				FROM RoomNumberLists, ServiceByDate
				WHERE RL_ID = SD_RLID
					AND SD_DLKey = @DLKey
				END
				ELSE
				BEGIN
					SELECT @HRIsMain = HR_MAIN, @RMKey = HR_RMKEY, @RCKey = HR_RCKEY, @ACKey = HR_ACKEY, @RMPlacesMain = RM_NPlaces, 
					@RMPlacesEx = RM_NPlacesEx, @ACPlacesMain = ISNULL(AC_NRealPlaces, 0), @ACPlacesEx = ISNULL(AC_NMenExBed, 0), 
					@ACPerRoom = ISNULL(AC_PerRoom, 0)
					FROM HotelRooms, Rooms, AccmdMenType
					WHERE HR_Key = @N_DLSubcode1
						AND RM_Key = HR_RMKEY
						AND AC_KEY = HR_ACKEY
					IF @ACPerRoom = 1
						OR (
							ISNULL(@RMPlacesMain, 0) = 0
							AND ISNULL(@RMPlacesEx, 0) = 0
							)
					BEGIN
						SET @RLPlacesMain = @ACPlacesMain
						SET @RLPlacesEx = ISNULL(@ACPlacesEx,0)
					END
					ELSE
					BEGIN
						IF @HRIsMain = 1
							AND @ACPlacesMain = 0
							AND @ACPlacesEx = 0
						BEGIN
							SET @ACPlacesMain = 1
						END
						ELSE IF @HRIsMain = 0
							AND @ACPlacesMain = 0
							AND @ACPlacesEx = 0
						BEGIN
							SET @ACPlacesEx = 1
						END

						SET @RLPlacesMain = @RMPlacesMain
						SET @RLPlacesEx = ISNULL(@RMPlacesEx, 0)
					END

					-- если услуга полностью ставится на квоту (из-за глобальных изменений (было удаление из ServiceByDate))
					IF @Mod = 'UPD'
						AND @SetToNewQuota = 1
					BEGIN
						SET @NeedPlacesForMen = ISNULL(@N_DLNMen, 0)
					END
					ELSE
					BEGIN
						SET @NeedPlacesForMen = ISNULL(@N_DLNMen, 0) - ISNULL(@O_DLNMen, 0)
					END
				END
				
				SET @RLID = 0
				SET @AC_FreeMainPlacesCount = 0
				SET @AC_FreeExPlacesCount = 0
				SET @RL_FreeMainPlacesCount = 0
				SET @RL_FreeExPlacesCount = 0
				-- пока не распределили всех человек
				WHILE (@NeedPlacesForMen>0)
				BEGIN
					--если в последнем номере кончились места, то выставляем признак @RLID = 0
					IF @AC_FreeMainPlacesCount = 0
						AND @AC_FreeExPlacesCount = 0
					BEGIN
						SET @AC_FreeMainPlacesCount = @ACPlacesMain
						SET @AC_FreeExPlacesCount = @ACPlacesEx
						--создаем новый номер, всегда когда есть хоть кто-то на основном месте ???
						IF (@AC_FreeMainPlacesCount > @RL_FreeMainPlacesCount)
							OR (@AC_FreeExPlacesCount > @RL_FreeExPlacesCount)
						BEGIN
							--создаем новый номер для каждой услуги, если размещение на номер.
							IF @ACPerRoom>0
							BEGIN			
								INSERT INTO RoomNumberLists (RL_NPlaces, RL_NPlacesEx, RL_RMKey, RL_RCKey
									)
								VALUES (@RLPlacesMain, @RLPlacesEx, @RMKey, @RCKey)

								SET @RLID = SCOPE_IDENTITY()

								INSERT INTO RoomPlaces (RP_RLID, RP_Type)
								SELECT @RLID, CASE 
										WHEN NU_ID > @RLPlacesMain
											THEN 1
										ELSE 0
										END
								FROM NUMBERS
								WHERE NU_ID BETWEEN 1
										AND (@RLPlacesMain + @RLPlacesEx)
								set @RPID=SCOPE_IDENTITY()-@RLPlacesMain-@RLPlacesEx+1
								SET @RL_FreeMainPlacesCount = @RLPlacesMain
								SET @RL_FreeExPlacesCount = @RLPlacesEx
							END
							ELSE
							BEGIN
								-- ищем к кому подселиться в данной путевке, если не находим, то прийдется создавать новый номер
								set @RPID = null
								SELECT TOP 1 @RPID = RP_ID, @RLID = RP_RLID
								FROM RoomPlaces
								WHERE RP_Type = CASE 
										WHEN @ACPlacesMain > 0
											THEN 0
										ELSE 1
										END
									AND RP_RLID IN (
										SELECT SD_RLID
										FROM ServiceByDate, DogovorList, RoomNumberLists
										WHERE SD_DLKey = DL_Key
											AND DL_DGKey = @DGKey
											AND RL_ID = SD_RLID
											AND DL_SVKey = @N_DLSVKey
											AND DL_Code = @N_DLCode
											AND DL_DateBeg = @N_DLDateBeg
											AND DL_DateEnd = @N_DLDateEnd
											AND RL_RMKey = @RMKey
											AND RL_RCKey = @RCKey
										)
									AND NOT EXISTS (
										SELECT SD_RPID
										FROM ServiceByDate
										WHERE SD_RLID = RP_RLID
											AND SD_RPID = RP_ID
										)
								ORDER BY RP_ID
								-- надо создавать новый номер даже для дополнительного размещения
								IF @RPID IS NULL
								BEGIN
									INSERT INTO RoomNumberLists (RL_NPlaces, RL_NPlacesEx, RL_RMKey, RL_RCKey)
									VALUES (@RLPlacesMain, @RLPlacesEx, @RMKey, @RCKey)

									SET @RLID = SCOPE_IDENTITY()

									INSERT INTO RoomPlaces (RP_RLID, RP_Type)
									SELECT @RLID, CASE 
											WHEN NU_ID > @RLPlacesMain
												THEN 1
											ELSE 0
											END
									FROM NUMBERS
									WHERE NU_ID BETWEEN 1
											AND (@RLPlacesMain + @RLPlacesEx)

									SET @RPID = SCOPE_IDENTITY()
									-- Task 9853 29.11.2012 kolbeshkin: неправильное расселение при бронировании
									-- неправильно вычислять место как последнее созданное минус кол-во основных и доп мест + 1,
									-- лучше взять первое свободное место в комнате с ID = @RLID
									SET @RPID = (
									    SELECT MIN(rp_id)
										FROM RoomPlaces
										WHERE RP_RLID = @RLID
										    AND NOT EXISTS (
											    SELECT 1
												FROM ServiceByDate
												WHERE SD_RLID = @RLID
												    AND SD_RPID = RP_ID))
									SET @RL_FreeMainPlacesCount = @RLPlacesMain
									SET @RL_FreeExPlacesCount = @RLPlacesEx
								END
							END
						END
					END
					
					-- смотрим есть ли в текущем номере свободные основные места
					IF @AC_FreeMainPlacesCount > 0
					BEGIN
						SET @AC_FreeMainPlacesCount = @AC_FreeMainPlacesCount - 1
						SET @RL_FreeMainPlacesCount = @RL_FreeMainPlacesCount - 1
						SET @CurrentPlaceIsEx=0
					END
					--если ОСНОВНЫХ мест в номере уже нет, то может посадим на ДОПОЛНИТЕЛЬНОЕ? 
					ELSE
						IF @AC_FreeExPlacesCount > 0
						BEGIN
							SET @AC_FreeExPlacesCount = @AC_FreeExPlacesCount - 1
							SET @RL_FreeExPlacesCount = @RL_FreeExPlacesCount - 1
							SET @CurrentPlaceIsEx=1
						END

					SET @TUKey = NULL

					SELECT @TUKey = TU_TUKey
					FROM dbo.TuristService
					WHERE TU_DLKey = @DLKey
						AND TU_TUKey NOT IN (
							SELECT SD_TUKey
							FROM ServiceByDate
							WHERE SD_DLKey = @DLKey
							)
					INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_TUKey)
					SELECT CAST((N1.NU_ID + @From - 1) AS DATETIME), @DLKey, @RLID, @RPID, @TUKey
					FROM NUMBERS AS N1
					WHERE N1.NU_ID BETWEEN 1
							AND CAST(@N_DLDateEnd AS INT) - @From + 1
					SET @NeedPlacesForMen=@NeedPlacesForMen-1
					SET @RPID=@RPID+1
				END		
			END
			-- для всех услуг кроме проживания
			ELSE
			BEGIN
				IF @Mod = 'UPD'
					AND @SetToNewQuota = 1
					-- если услуга полностью ставится на квоту (из-за глобальных изменений (было удаление из ServiceByDate))
						SET @NeedPlacesForMen=ISNULL(@N_DLNMen,0)
				ELSE
						SET @NeedPlacesForMen=ISNULL(@N_DLNMen,0)-ISNULL(@O_DLNMen,0)

				while(@NeedPlacesForMen > 0)
				BEGIN
					set @TUKey=null

					SELECT @TUKey = TU_TUKey
					FROM dbo.TuristService
					WHERE TU_DLKey = @DLKey
						AND TU_TUKey NOT IN (
							SELECT SD_TUKey
							FROM ServiceByDate
							WHERE SD_DLKey = @DLKey
							)
					INSERT INTO RoomPlaces (RP_RLID, RP_Type)
					VALUES (0, 0)
					set @RPID=SCOPE_IDENTITY()				
					INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RPID, SD_TUKey)	
						SELECT CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RPID, @TUKey
					FROM NUMBERS AS N1
					WHERE N1.NU_ID BETWEEN 1
							AND CAST(@N_DLDateEnd AS INT) - @From + 1
					SET @NeedPlacesForMen = @NeedPlacesForMen - 1
				END
			END

			exec dbo.DogListToQuotas @DLKey, @OldSetToQuota = 1
		END
	END
	
	FETCH NEXT 
	FROM cur_DogovorListChanged2 
	INTO @DLKey, @DGKey, @O_DLSVKey, @O_DLCode, @O_DLSubCode1, @O_DLSubCode2, @O_DLDateBeg, @O_DLDateEnd, @O_DLNMen, @O_DLPartnerKey, 
		@O_DLControl, @N_DLSVKey, @N_DLCode, @N_DLSubCode1, @N_DLSubCode2, @N_DLDateBeg, @N_DLDateEnd, @N_DLNMen, @N_DLPartnerKey, @N_DLControl
END
CLOSE cur_DogovorListChanged2
DEALLOCATE cur_DogovorListChanged2

GO


/*********************************************************************/
/* end T_UpdDogListQuota.sql */
/*********************************************************************/

/*********************************************************************/
/* begin DisableTriggersOnSubscriber.sql */
/*********************************************************************/
-- ===================== Disable triggers on replication articles
if dbo.mwReplIsSubscriber() > 0 and exists (select top 1 1 from sys.servers where name = 'mt')
begin	
	declare @sql varchar(4000)
	-- do not disable triggers on this tables

	set @sql = '
	declare @excludedTables table
	(
		tableName varchar(50)
	)

	insert into @excludedTables values (''mwReplTours'')
	insert into @excludedTables values (''tp_tours'')
	insert into @excludedTables values (''Charter'')

	declare @tabName as varchar(max)

	declare tabsCur cursor for
	select art.source_object
	from mt.distribution.dbo.MSArticles art
	inner join sys.tables localTabs on localTabs.name = art.source_object
	where
			(art.publication_id = (select top 1 publication_id 
 				from mt.distribution.dbo.MSpublications 
				where publication = ''MW_PUB''))
			and (art.source_object not in (select tableName from @excludedTables)) 			
	order by art.source_object

	open tabsCur

	declare @sql varchar(4000)
	set @sql = ''''

	fetch next from tabsCur into @tabName
	while @@fetch_status = 0
	begin

		set @sql = @sql + ''
			alter table @tabName disable trigger all
		''
		set @sql = replace(@sql, ''@tabName'', @tabName)
		fetch next from tabsCur into @tabName

	end

	close tabsCur
	deallocate tabsCur'
	
	begin try
		exec (@sql)
	end try
	begin catch
		declare @errMsg as nvarchar(max)
		set @errMsg = 'Не удалось отключить триггеры на статьях репликации поисковой базы. Пожалуйста, сообщите об этом службе поддержки. Причина: ' + error_message();
		RAISERROR(@errMsg, 1, 1)
	end catch
end

GO
/*********************************************************************/
/* end DisableTriggersOnSubscriber.sql */
/*********************************************************************/
update [dbo].[setting] set st_version = '9.2.20.2', st_moduledate = convert(datetime, '2013-11-22', 120),  st_financeversion = '9.2.20.2', st_financedate = convert(datetime, '2013-11-22', 120) 
 GO
 UPDATE dbo.SystemSettings SET SS_ParmValue='2013-11-22' WHERE SS_ParmName='SYSScriptDate'
 GO