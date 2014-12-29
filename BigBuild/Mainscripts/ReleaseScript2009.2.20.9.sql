/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 07.03.2014 13:37 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.8'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.9'

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
/* begin (2014-02-05)_Create_Megatec_StateDataPaging.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Megatec_StateDataPaging]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[Megatec_StateDataPaging](
		[SDP_ID] [int] IDENTITY(1,1) NOT NULL,
		[SDP_Code] [int] NOT NULL,
		[SDP_Name] [nvarchar](250) NULL,
		[SDP_Date] [datetime] NOT NULL DEFAULT (getdate()),
		[SDP_PagingType] [smallint] NULL,
		[SDP_CountryKey] [int] NULL,
		[SDP_DepartFromKey] [int] NULL,
		[SDP_Filter] [varchar](4000) NULL,
		[SDP_SortExpr] [varchar](1024) NULL,
		[SDP_PageNum] [int] NULL,
		[SDP_PageSize] [int] NULL,
		[SDP_AgentKey] [int] NULL,
		[SDP_HotelQuotaMask] [smallint] NULL,
		[SDP_AviaQuotaMask] [smallint] NULL,
		[SDP_GetServices] [smallint] NULL,
		[SDP_FlightGroups] [varchar](256) NULL,
		[SDP_CheckAgentQuota] [smallint] NULL,
		[SDP_CheckCommonQuota] [smallint] NULL,
		[SDP_CheckNoLongQuota] [smallint] NULL,
		[SDP_RequestOnRelease] [smallint] NULL,
		[SDP_ExpiredReleaseResult] [int] NULL,
		[SDP_NoPlacesResult] [int] NULL,
		[SDP_FindFlight] [smallint] NULL,
		[SDP_CheckFlightPacket] [smallint] NULL,
		[SDP_CheckAllPartnersQuota] [smallint] NULL,
		[SDP_CalculateVisaDeadLine] [smallint] NULL,
		[SDP_NoSmartSearch] [bit] NULL,
		[SDP_Value] [int] NOT NULL,
		[SDP_AppName] [varchar](100) NULL,
		[SDP_HostName] [varchar](100) NULL,
	 CONSTRAINT [PK_Megatec_StateDataPaging] PRIMARY KEY CLUSTERED 
	(
		[SDP_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
	) ON [PRIMARY]
end
GO

if not exists (select 1 from dbo.syscolumns where name = 'SDP_AppName' and id = object_id(N'[dbo].[Megatec_StateDataPaging]'))
	alter table Megatec_StateDataPaging Add SDP_AppName varchar(100) null
GO

if not exists (select 1 from dbo.syscolumns where name = 'SDP_HostName' and id = object_id(N'[dbo].[Megatec_StateDataPaging]'))
	alter table Megatec_StateDataPaging Add SDP_HostName varchar(100) null
GO
/*********************************************************************/
/* end (2014-02-05)_Create_Megatec_StateDataPaging.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.02.11)_TFS_22173.sql */
/*********************************************************************/
-- TFS BUG 22173. Неверное значения ключей (отсутствие, NULL или несколько значений) в Key_* таблицах
-- задаем соответствия имени таблицы, имени первичного ключа в таблице и таблицы ключей
DECLARE @TableNamesAndKeys as table (keyTableName nvarchar(64), tableName nvarchar(64), tableKey nvarchar(16))
insert into @TableNamesAndKeys (keyTableName, tableName, tableKey) values 
(N'Key_Accmdmentype', N'Accmdmentype', N'AC_Key'),
(N'Key_AddDescript1', N'AddDescript1', N'A1_Key'),
(N'Key_AddDescript2', N'AddDescript2', N'A2_Key'),
(N'Key_Advertise', N'Advertise', N'AD_Key'),
(N'Key_Aircraft', N'Aircraft', N'AC_Key'),
(N'Key_AirService', N'AirService', N'AS_Key'),
(N'Key_AllHotelOption', N'AllHotelOption', N'AO_Key'),
(N'Key_AnkFields', N'Ank_Fields', N'AF_Key'),
(N'Key_AnnulReasons', N'AnnulReasons', N'AR_Key'),
(N'Key_Bills', N'Bills', N'BL_Key'),
(N'Key_Cabine', N'Cabine', N'CB_Key'),
(N'Key_CauseDiscounts', N'CauseDiscounts', N'CD_Key'),
(N'Key_Charter', N'Charter', N'CH_Key'),
(N'Key_CityDictionary', N'CityDictionary', N'CT_Key'),
(N'Key_Clients', N'Clients', N'CL_Key'),
(N'Key_Discount', N'Discounts', N'DS_Key'),
(N'KEY_DOCUMENTSTATUS', N'DocumentStatus', N'DS_Key'),
(N'Key_Dogovor', N'tbl_Dogovor', N'DG_Key'),
(N'Key_DogovorList', N'tbl_DogovorList', N'DL_Key'),
(N'Key_EventList', N'Messages', N'MS_Id'),
(N'Key_Events', N'Events', N'EV_Id'),
(N'Key_ExcurDictionar', N'ExcurDictionary', N'ED_Key'),
(N'Key_Factura', N'Factura', N'FC_Key'),
(N'Key_HotelDictionar', N'HotelDictionary', N'HD_Key'),
(N'Key_HotelRooms', N'HotelRooms', N'HR_Key'),
(N'Key_KindOfPay', N'KindOfPay', N'KP_Key'),
(N'Key_Locks', N'Locks', N'LK_Key'),
(N'Key_Order_Status', N'Order_Status', N'OS_Code'),
(N'Key_Pansion', N'Pansion', N'PN_Key'),
(N'Key_Partners', N'tbl_Partners', N'PR_Key'),
(N'Key_PaymentType', N'tbl_PaymentType', N'PT_Key'),
(N'Key_PriceList', N'PriceList', N'PL_Key'),
(N'Key_PriceServiceLink', N'PriceServiceLink', N'PS_Key'),
(N'Key_Profession', N'Profession', N'PF_Key'),
(N'Key_PrtDeps', N'PrtDeps', N'PDP_Key'),
(N'Key_PrtDogs', N'PrtDogs', N'PD_Key'),
(N'Key_PrtGroups', N'PrtGroups', N'PG_Key'),
(N'Key_PrtWarns', N'PrtWarns', N'PW_Key'),
(N'Key_Rep_Options', N'Rep_Options', N'RO_Key'),
(N'Key_Rep_Profiles', N'Rep_Profiles', N'RP_Key'),
(N'Key_Resorts', N'Resorts', N'RS_Key'),
(N'Key_Rooms', N'Rooms', N'RM_Key'),
(N'Key_RoomsCategory', N'RoomsCategory', N'RC_Key'),
(N'Key_Service', N'Service', N'SV_Key'),
(N'Key_ServiceList', N'ServiceList', N'SL_Key'),
(N'Key_Ship', N'Ship', N'SH_Key'),
(N'KEY_TOURSERVLIST', N'TourServiceList', N'TO_Key'),
(N'Key_Transfer', N'Transfer', N'TF_Key'),
(N'Key_Transport', N'Transport', N'TR_Key'),
(N'Key_Turist', N'tbl_Turist', N'TU_Key'),
(N'Key_Turlist', N'tbl_TurList', N'TL_Key'),
(N'Key_TURMARGIN', N'TURMARGIN', N'TM_Key'),
(N'Key_TurService', N'TurService', N'TS_Key'),
(N'Key_UserList', N'UserList', N'US_Key'),
(N'Key_Vehicle', N'Vehicle', N'VH_Key')

-- создаем курсор по именам таблиц
DECLARE @keyTableName nvarchar(64)
DECLARE @tableName nvarchar(64)
DECLARE @tableKey nvarchar(16)

DECLARE tableNamesAndKeysCursor cursor for
SELECT * FROM @TableNamesAndKeys

OPEN tableNamesAndKeysCursor
FETCH tableNamesAndKeysCursor INTO @keyTableName, @tableName, @tableKey

-- Обновляем ключи для таблиц, в которых есть null или в которых не одна запись
DECLARE @rowCount int
DECLARE @nullRowCount int
DECLARE @query nvarchar(256)
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @query = N'SELECT @nullRowCount = SUM(case when ID IS NULL THEN 1 ELSE 0 END), @rowCount = COUNT(*) FROM @keyTableName'
	SET @query = REPLACE(@query, N'@keyTableName', @keyTableName)
	EXECUTE sp_executesql @query, N'@rowCount int OUTPUT, @nullRowCount int OUTPUT', @rowCount = @rowCount output, @nullRowCount = @nullRowCount output

	IF (@rowCount != 1 OR @nullRowCount > 0)
	BEGIN
		SET @query = N'DELETE FROM @keyTableName;
					   INSERT INTO @keyTableName (ID) VALUES ((SELECT ISNULL(MAX(@tableKey),0)+1 from @tableName))'
		SET @query = REPLACE(@query, N'@keyTableName', @keyTableName)
		SET @query = REPLACE(@query, N'@tableName', @tableName)
		SET @query = REPLACE(@query, N'@tableKey', @tableKey)
		BEGIN TRAN
			EXECUTE sp_executesql @query
		COMMIT TRAN
	END	

	FETCH NEXT FROM tableNamesAndKeysCursor INTO @keyTableName, @tableName, @tableKey
END

-- удаляем курсор
CLOSE tableNamesAndKeysCursor
DEALLOCATE tableNamesAndKeysCursor
-- END TFS BUG 22173

GO
/*********************************************************************/
/* end (2014.02.11)_TFS_22173.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.03.03)_Insert_Actions.sql */
/*********************************************************************/
--добавление action Разрешить редактирование направлений в плагине Megatec Integration Services

IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 149) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (149, 'Плагин MIS -> Разрешить редактирование направлений', 'Разрешить редактирование направлений в плагине Megatec Integration Services', 'MIS plugin -> Allow edit settings', 0)
END
GO



/*********************************************************************/
/* end (2014.03.03)_Insert_Actions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (27.02.2014)_Create_Table_ScriptsSetupLogs.sql */
/*********************************************************************/
--<DATE>2014-02-27</DATE>
--<VERSION>9.2.21.8</VERSION>
--<SUMMARY>Создается таблица для вставки логов про прогоне скриптов</SUMMARY>

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
END

GRANT SELECT, INSERT, UPDATE ON [dbo].[ScriptsSetupLogs] TO PUBLIC
GO
/*********************************************************************/
/* end (27.02.2014)_Create_Table_ScriptsSetupLogs.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20131211_AlterTable_tbl_Partners.sql */
/*********************************************************************/
--<VERSION>9.2.20</VERSION>
--<DATE>2014-03-04</DATE>

if exists (select top 1 1 from sys.indexes where object_id = object_id(N'[dbo].[tbl_Partners]') AND name = N'IX_PR_MAIL_PHONE_CITY_NAME')
	drop index [IX_PR_MAIL_PHONE_CITY_NAME] on [dbo].[tbl_Partners] 
go

UPDATE [dbo].[tbl_Partners] SET PR_FULLNAME = N'' WHERE PR_FULLNAME IS NULL;
UPDATE [dbo].[tbl_Partners] SET PR_NAME = N'' WHERE PR_NAME IS NULL;

-- приведение ИНН к размеру в 30 символов (убираем пробелы справа, или отсекаем лишние символы)
declare @maxINN as int
set @maxINN = 30

update [dbo].[tbl_Partners] SET PR_INN = RTrim(PR_INN) where DATALENGTH(PR_INN) > @maxINN and LEN(PR_INN) < @maxINN
update [dbo].[tbl_Partners] SET PR_INN = LEFT(PR_INN, @maxINN) where DATALENGTH(PR_INN) > @maxINN and LEN(PR_INN) > @maxINN
UPDATE [dbo].[tbl_Partners] SET PR_INN = N'' WHERE PR_INN IS NULL;

-- пересоздадим зависимые от выбранных колонок индексы, попутно удалив колонки
exec RecreateDependentObjects 'tbl_Partners', 'PR_FULLNAME', 'ALTER TABLE [dbo].[tbl_Partners] ALTER COLUMN [PR_FULLNAME] [varchar](160) NOT NULL', 0
exec RecreateDependentObjects 'tbl_Partners', 'PR_NAME', 'ALTER TABLE [dbo].[tbl_Partners] ALTER COLUMN [PR_NAME] [varchar](160) NOT NULL', 0
exec RecreateDependentObjects 'tbl_Partners', 'PR_INN', 'ALTER TABLE [dbo].[tbl_Partners] ALTER COLUMN [PR_INN] [varchar](160) NOT NULL', 0

GO

/****** Object:  Index [IX_PR_MAIL_PHONE_CITY_NAME]    Script Date: 11.12.2013 11:02:09 *****/
CREATE NONCLUSTERED INDEX [IX_PR_MAIL_PHONE_CITY_NAME] ON [dbo].[tbl_Partners]
(
	[PR_KEY] ASC,
	[PR_EMAIL] ASC,
	[PR_PHONES] ASC,
	[PR_CITY] ASC,
	[PR_NAME] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
GO


/*********************************************************************/
/* end 20131211_AlterTable_tbl_Partners.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Delete_X_ROOMS_Rooms.sql */
/*********************************************************************/
--<VERSION>9.2.20.9</VERSION>
--<DATE>2014-02-24</DATE>
--<DESCRIPTION>Скрипт на удаление индекса X_ROOMS у таблицы Rooms</DESCRIPTION>

go
if exists(select * from sysindexes ind
	join sys.tables tab on ind.id = tab.object_id
	where tab.name = 'rooms'
	and ind.name = 'X_ROOMS')
 begin
	drop index X_ROOMS on rooms
 end
go
/*********************************************************************/
/* end Delete_X_ROOMS_Rooms.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalculatePriceList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalculatePriceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CalculatePriceList]
GO

CREATE PROCEDURE [dbo].[CalculatePriceList]
  (
	@nPriceTourKey int,			-- ключ обсчитываемого тура
	@nCalculatingKey int,		-- ключ итерации дозаписи
	@dtSaleDate datetime,		-- дата продажи
	@nNullCostAsZero smallint,	-- считать отсутствующие цены нулевыми (кроме проживания) 0 - нет, 1 - да
	@nNoFlight smallint,		-- при отсутствии перелёта в расписании 0 - ничего не делать, 1 - не обсчитывать тур, 2 - искать подходящий перелёт (если не найдено - не рассчитывать)
	@nUpdate smallint,			-- признак дозаписи 0 - расчет, 1 - дозапись
	@nUseHolidayRule smallint		-- Правило выходного дня: 0 - не использовать, 1 - использовать
  )
AS

--<DATE>2014-02-25</DATE>
---<VERSION>9.2.21.8</VERSION>

--проверяем настройку со страной, если совпала - запускаем новый CalculatePriceList
declare @toCnKey varchar(30), @setting varchar(260),@newpricesetting varchar 

select @toCnKey = rtrim(ltrim(str(to_cnkey))) from tp_tours where to_key = @nPriceTourKey

select @setting = rtrim(ltrim(ss_parmvalue)) from systemsettings where ss_parmname = 'MTDynamicCountries'

select @newpricesetting = SS_ParmValue from systemsettings where ss_parmname = 'NewReCalculatePrice'

if isnull(@newpricesetting,'') = '1'
begin
	if (IsNull(@setting, '') = '' OR exists (select top 1 1 from dbo.ParseKeys(@setting) where xt_key = convert(int, @toCnKey)))
	begin
		exec [dbo].[CalculatePriceListDynamic] @nPriceTourKey,@nCalculatingKey,@dtSaleDate,@nNullCostAsZero,@nNoFlight,@nUpdate,@nUseHolidayRule
		return
	end 
end

declare @variant int
declare @pricetour int
declare @turdate datetime
declare @servicedate datetime
declare @price_brutto money
declare @TrKey int
declare @userKey int
--
declare @nServiceKey int
declare @nSvkey int
declare @nCode int
declare @nSubcode1 int
declare @nSubcode2 int
declare @nPrkey int
declare @nPacketkey int
declare @nDay int
declare @nDays int
declare @sRate varchar(3)
declare @nMen int
declare @nMargin money
declare @nMarginType int
declare @nNetto money
declare @nBrutto money
declare @nDiscount money
declare @nTempGross money
declare @tsCheckMargin smallint
declare @tdCheckMargin smallint
declare @TI_DAYS int
declare @TS_CTKEY int
declare @TS_ATTRIBUTE int
--
declare @SERV_NOTCALCULATE int
--
declare @dtPrevDate datetime
declare @nPrevVariant int
declare @nPrevGross money
declare @nPrevGrossKey int
declare @nPrevGrossDate datetime
declare @nPriceFor smallint
declare @nTP_PriceKeyCurrent int
declare @nTP_PriceKeyMax int
declare @NumPrices int
--
declare @fetchStatus smallint
declare @nDeltaProgress decimal(14, 8)
declare @nTotalProgress decimal(14, 8)
declare @round smallint
--
declare @hdKey int
declare @prevHdKey int
--
declare @nProgressSkipLimit smallint
declare @nProgressSkipCounter smallint
declare @weekday varchar(3)
declare @nDateFirst smallint
declare @nFlightEnabled smallint
declare @nCH_Key int
declare @CS_PRKEY int
declare @dDateBeg1 datetime -- дата начала 1го периода
declare @dDateBeg3 datetime -- дата начала 2,3го периода
declare @dDateEnd1 datetime -- дата окончания 1го периода
declare @dDateEnd3 datetime -- дата окончания 2,3го периода
--
declare @sDetailed varchar(100) -- не используется, необходима только для передачи в качестве параметра в GSC
declare @sBadRate varchar(3)
declare @nettoDetail nvarchar(max)
declare @dtBadDate DateTime
--
declare @nSPId int -- возвращается из GSC, фактически это ключ из ServicePrices
declare @nPDId int 
declare @nBruttoWithCommission money

--переменные для разбиения сгруппированных цен
declare @priceDate datetime
declare @priceListKey int
declare @numDates int
declare @priceListGross int
---------------------------------------------
declare @ROUND_NOTWITHDISC int
declare @ROUND_SERVICE_MATH int
declare @ROUND_SERVICE0_5 int
declare @ROUND_PRICE0_5 int
declare @ROUND_SERVICE int
declare @ROUND_PRICE int
declare @ROUND_NOT int

Set @ROUND_NOTWITHDISC = 64
Set @ROUND_SERVICE_MATH = 32
Set @ROUND_SERVICE0_5 = 16
Set @ROUND_PRICE0_5 = 8
Set @ROUND_SERVICE = 4
Set @ROUND_PRICE = 2
Set @ROUND_NOT = 1
---------------------------------------------
declare @nIsEnabled smallint
select @nIsEnabled = TO_IsEnabled from TP_Tours where TO_Key = @nPriceTourKey
---------------------------------------------
declare @tpPricesCount int
declare @isPriceListPluginRecalculation smallint
select @tpPricesCount = count(1) from tp_prices with(nolock) where tp_tokey = @nPriceTourKey

Set @nTotalProgress = 1
update tp_tours with(rowlock) set to_progress = @nTotalProgress, TO_UPDATETIME = GetDate() where to_key = @nPriceTourKey

--осуществляется пересчет прайса планировщиком
if (@tpPricesCount > 0 and @nUpdate = 0)
begin
	set @isPriceListPluginRecalculation = 1
	set @nCalculatingKey = null
	
	select top 1 @nCalculatingKey = CP_Key from CalculatingPriceLists with(nolock) where CP_PriceTourKey = @nPriceTourKey and CP_Update = 0
	update tp_turdates set td_update = 0 where td_tokey = @nPriceTourKey
	update tp_lists set ti_update = 0 where ti_tokey = @nPriceTourKey
	
	set @nUpdate = 0
end
else
	set @isPriceListPluginRecalculation = 0

declare @nSign tinyint

create table #GetServiceCost(
	tid int identity primary key,
	svkey int,
	code int,
	subcode1 int,
	subcode2 int,
	prkey int,
	pkkey int,
	date datetime,
	days int,
	rate varchar(3),
	nmen int,
	margin money,
	marginType int,
	saleDate datetime,
	netto money,
	brutto money,
	discount money,
	details varchar(100),
	badrate varchar(3),
	baddate datetime,
	details2 varchar(100),
	spid int,
	row_sign tinyint
)

create index x_getservicecost on #GetServiceCost(svkey,code,subcode1,subcode2,prkey,pkkey,date,days,rate,nmen,margin,marginType,saleDate)
include (netto,brutto,discount,details,badRate,badDate,details2,spid,row_sign)

declare @calculatingPriceListsExists smallint -- 0 - CalculatingPriceLists нет, 1 - CalculatingPriceLists есть в базе

BEGIN
	set nocount on

	--koshelev
	--MEG00027550
	if @nUpdate = 0
		update tp_tours with(rowlock) set to_datecreated = GetDate() where to_key = @nPriceTourKey

	select @TrKey = to_trkey, @userKey = to_opkey from tp_tours with(nolock) where to_key = @nPriceTourKey

	if not exists (select 1 from CalculatingPriceLists with(nolock) where CP_PriceTourKey = @nPriceTourKey) and @nPriceTourKey is not null
	begin	
		insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_TourKey, CP_UserKey, CP_Status, CP_UseHolidayRule)
		values (@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @TrKey, @userKey, 1, @nUseHolidayRule)
	end
	else if @nPriceTourKey is not null
	begin
		update CalculatingPriceLists with(rowlock) set CP_Status = 1 where CP_Key = @nCalculatingKey
	end

	DECLARE @sHI_Text varchar(254), @nHIID int
	SELECT @sHI_Text=TO_Name FROM tp_tours with(nolock) where to_key = @nPriceTourKey
	EXEC @nHIID = dbo.InsHistory '', null, 11, @nPriceTourKey, 'INS', @sHI_Text, '', 0, ''

	SET @sHI_Text=CONVERT(varchar(30),@dtSaleDate,104)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11001, null, @sHI_Text, null, null, null, @dtSaleDate, 0
	If @nNullCostAsZero=0
		SET @sHI_Text='NO'
	ELSE
		SET @sHI_Text='YES'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11002, null, @sHI_Text, null, @nNullCostAsZero, null, null, 0
	If @nNoFlight=0
		SET @sHI_Text='NO'
	ELSE
		SET @sHI_Text='Flight search'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11003, null, @sHI_Text, null, @nNoFlight, null, null, 0
	If @nUpdate=0
		SET @sHI_Text='First calculate'
	ELSE
		SET @sHI_Text='Add calculate'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11004, null, @sHI_Text, null, @nUpdate, null, null, 0
	If @nUseHolidayRule = 0
		SET @sHI_Text = 'NO'
	ELSE
		SET @sHI_Text = 'YES'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11008, null, @sHI_Text, null, @nUpdate, null, null, 0

	--Засекаем время начала рассчета begin
	declare @beginPriceCalculate datetime
	set @beginPriceCalculate = GETDATE()
	SET @sHI_Text = CONVERT(varchar(30),@beginPriceCalculate,121)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11009, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Засекаем время начала рассчета end
	
	-- koshelev 15.02.2011
	-- для подбора перелетов
	if exists(select 1 from tp_lists with(nolock) where TI_TOKey = @nPriceTourKey and TI_TotalDays is null)
	begin
		exec sp_executesql N'
		select TI_Key as xTI_Key, TI_TOKey as xTI_TOKey, TI_CalculatingKey as xTI_CalculatingKey, ti_totaldays as xti_totaldays
		into #tmp
		from tp_lists with(nolock)
		where TI_TOKey = @nPriceTourKey 
		and TI_TotalDays is null
		
		update #tmp with(rowlock)
		set
			xti_totaldays = (select max(case ts_svkey 
							when 3 
							then ts_day + ts_days 
							else (case ts_days 
								when 0 
								then 1 
								else ts_days 
      								  end) + ts_day - 1 
 							   end)
					from dbo.tp_services with (nolock)
						inner join dbo.tp_servicelists with (nolock) on (tl_tskey = ts_key and TS_TOKey = @nPriceTourKey and TL_TOKey = @nPriceTourKey)
					where tl_tikey = xti_key)
		
		update TP_Lists
		set ti_totaldays = xti_totaldays
		from #tmp
		where xTI_Key = TI_Key
		', N'@nPriceTourKey int', @nPriceTourKey
	end

	select @nDateFirst = @@DATEFIRST
	set DATEFIRST 1

	set @SERV_NOTCALCULATE = 32768

	exec sp_executesql N'
	
	select distinct TO_Key, TD_Date + TS_Day - 1 as flight_day, TS_Code, TS_OpPartnerKey, TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, ti_totaldays, TD_Date
	into #TP_Flights
	from TP_Tours with(nolock) join TP_Services with(nolock) on TO_Key = TS_TOKey and TS_SVKey = 1
		join TP_ServiceLists with(nolock) on TL_TSKey = TS_Key and TS_TOKey = TO_Key
		join TP_Lists with(nolock) on TL_TIKey = TI_Key and TI_TOKey = TO_Key
		join TP_TurDates with(nolock) on TD_TOKey = TO_Key
	where TO_Key = @nPriceTourKey

	delete from #TP_Flights where exists (Select 1 From TP_Flights with(nolock) Where TF_TOKey=@nPriceTourKey and TF_Date=flight_day
		and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
		and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = ti_totaldays)
		
	insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_TourDate, TF_CalculatingKey)
	select *, @nCalculatingKey  from #tp_flights
	', N'@nPriceTourKey int, @nCalculatingKey int, @SERV_NOTCALCULATE int', @nPriceTourKey, @nCalculatingKey, @SERV_NOTCALCULATE

--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре (с учетом цен в которых дата продажи NULL или больше/равна сегодняшней дате )----

	exec sp_executesql 
	N'
	update TP_Flights set TF_CodeNew = null, TF_PRKeyNew = null, TF_SubCode1New = null where TF_TOKey = @nPriceTourKey

	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1, TF_CalculatingKey = @nCalculatingKey
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey 
			and TF_Date BETWEEN ISNULL(CS_Date, ''1900-01-01'') AND ISNULL(CS_DateEnd, ''2053-01-01'') 
			and TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(CS_CHECKINDATEEND, ''2053-01-01'')
			and (ISNULL(CS_Week, '''') = '''' or CS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'') 
			and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long) 
			and (cs_DateSellBeg <= @dtSaleDate or cs_DateSellBeg is null) 
			and (cs_DateSellEnd >= @dtSaleDate or cs_DateSellEnd is null))
			and TF_TOKey = @nPriceTourKey

	If @nNoFlight = 2
	BEGIN
		------ проверяем, а есть ли у данного парнера по рейсу, цены на другие рейсы в этом же пакете  ----
		IF exists(SELECT TF_ID FROM TP_Flights with(nolock) WHERE TF_TOKey = @nPriceTourKey and TF_CodeNew is Null)
		begin
			print ''Подбираем перелет''
			
			declare @newFlightsPartnerTable table
			(
				-- идентификатор
				xId int identity(1,1),
				-- ключ услуги перелет
				xTFId int,
				-- ключ исходного партнера
				xPRKey int,
				-- ключ партнера которого подобрали
				xPRKeyNew int,
				-- ключ перелета
				xCHKey int,
				-- ключ тарифа на перелет
				xASKey int
			)
			-- подбираем подходящие нам перелеты (у которых дата продажи NULL или больше/равна сегодняшней дате )
			insert into @newFlightsPartnerTable (xTFId, xCHKey, xASKey, xPRKey, xPRKeyNew)
			SELECT TF_Id, CH_Key, CS_SubCode1, TF_PRKeyOld, CS_PRKey
			FROM AirSeason with(nolock), Charter with(nolock), Costs with(nolock), TP_Flights with(nolock)
			WHERE CH_CityKeyFrom = TF_Subcode2 and
			CH_CityKeyTo = TF_CTKey and
			CS_Code = CH_Key and
			AS_CHKey = CH_Key and
			CS_SVKey = 1 and
			(	isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = CS_SubCode1), '''')
				= 
				isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = TF_Subcode1), '''')
			) 
			and (cs_DateSellBeg <= @dtSaleDate or cs_DateSellBeg is null) 
			and (cs_DateSellEnd >= @dtSaleDate or cs_DateSellEnd is null)
			and CS_PKKey = TF_PKKey and
			TF_Date BETWEEN AS_DateFrom and AS_DateTo and
			TF_Date BETWEEN CS_Date and CS_DateEnd and
			AS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'' and
			(ISNULL(CS_Week, '''') = '''' or CS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'') and
			(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long) and
			TF_CodeNew is Null and 
			TF_TOKey = @nPriceTourKey
			group by TF_Id, CH_Key, CS_SubCode1, TF_PRKeyOld, CS_PRKey
			
			-- удаляем повторяющиеся (если подобралось несколько перелетов)
			delete @newFlightsPartnerTable
			from @newFlightsPartnerTable as a
			where a.xId != (select top 1 b.xId 
							from @newFlightsPartnerTable as b 
							where b.xTFId = a.xTFId
							-- и приорететнее те перелеты в которых партнеры совпадают с исходным
							order by case when b.xPRKey = b.xPRKeyNew then 0 else 1 end)
			
			-- обновляем информацию о найденом перелете
			update TP_Flights with(rowlock)
			set TF_CodeNew = xCHKey,
			TF_SubCode1New = xASKey,
			TF_PRKeyNew = xPRKeyNew,
			TF_CalculatingKey = @nCalculatingKey
			from TP_Flights with(rowlock) join @newFlightsPartnerTable on TF_Id = xTFId
			
			print ''Закончили подбор перелетов''
		end
	END
	', N'@nPriceTourKey int, @nCalculatingKey int, @nNoFlight smallint, @dtSaleDate datetime', @nPriceTourKey, @nCalculatingKey, @nNoFlight, @dtSaleDate
	
	-----если перелет так и не найден, то в поле TF_CodeNew будет NULL

	--------------------------------------- закончили поиск подходящего перелета --------------------------------------
	--if ISNULL((select to_update from [dbo].tp_tours with(nolock) where to_key = @nPriceTourKey),0) <> 1
	
	declare @calcPricesCount int

	exec sys.sp_executesql N'
	
	if (1 = 1)
	BEGIN

		update [dbo].tp_tours with(rowlock) set to_update = 1 where to_key = @nPriceTourKey
		Set @nTotalProgress = 4
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	
		--------------------------------------- сохраняем цены во временной таблице --------------------------------------
		CREATE TABLE #TP_Prices
		(
			[xTP_Key] [int] PRIMARY KEY NOT NULL ,
			[xTP_TOKey] [int] NOT NULL ,
			[xTP_DateBegin] [datetime] NOT NULL ,
			[xTP_DateEnd] [datetime] NULL ,
			[xTP_Gross] [money] NULL ,
			[xTP_TIKey] [int] NOT NULL,
			[xTP_CalculatingKey] [int] NULL
		)

		CREATE NONCLUSTERED INDEX [x_fields] ON [#TP_Prices] 
		(
			[xTP_TOKey] ASC,
			[xTP_TIKey] ASC,
			[xTP_DateBegin] ASC,
			[xTP_DateEnd] ASC
		)

		DELETE FROM #TP_Prices
		--INSERT INTO #TP_Prices (xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey) select tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey from tp_prices where tp_tokey = @nPriceTourKey
		---------------------------------------КОНЕЦ  сохраняем цены во временной таблице --------------------------------------
		

		---------------------------------------разбиваем данные в таблицах tp_prices по датам
		if (select COUNT(TP_Key) from TP_Prices with(nolock) where TP_DateBegin != TP_DateEnd and TP_TOKey = @nPriceTourKey) > 0
		begin
			select @numDates = COUNT(1) from TP_TurDates with(nolock), TP_Lists with(nolock), TP_Prices with(nolock) where TP_TIKey = TI_Key and TD_Date between TP_DateBegin and TP_DateEnd and TP_TOKey = @nPriceTourKey and TD_TOKey = @nPriceTourKey and TI_TOKey = @nPriceTourKey
			exec GetNKeys ''TP_PRICES'', @numDates, @nTP_PriceKeyMax output
			set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @numDates + 1
		
			declare datesCursor cursor local fast_forward for
			select TD_Date, TI_Key, TP_Gross from TP_TurDates with(nolock), TP_Lists with(nolock), TP_Prices with(nolock) where TP_TIKey = TI_Key and TD_Date between TP_DateBegin and TP_DateEnd and TP_TOKey = @nPriceTourKey and TD_TOKey = @nPriceTourKey and TI_TOKey = @nPriceTourKey
			
			open datesCursor
			fetch next from datesCursor into @priceDate, @priceListKey, @priceListGross
			while @@FETCH_STATUS = 0
			begin
				insert into #TP_Prices (xTP_Key, xTP_TOKey, xTP_TIKey, xTP_Gross, xTP_DateBegin, xTP_DateEnd, xTP_CalculatingKey) 
				values (@nTP_PriceKeyCurrent, @nPriceTourKey, @priceListKey, @priceListGross, @priceDate, @priceDate, @nCalculatingKey)
				set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
				fetch next from datesCursor into @priceDate, @priceListKey, @priceListGross
			end
			
			close datesCursor
			deallocate datesCursor
			
			begin tran tEnd
				delete from TP_Prices with(rowlock) where TP_TOKey = @nPriceTourKey
				
				insert into TP_Prices (TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, TP_CalculatingKey)
				select xTP_Key, xTP_TOKey, xTP_TIKey, xTP_Gross, xTP_DateBegin, xTP_DateEnd, @nCalculatingKey
				from #TP_Prices  
				where xTP_DateBegin = xTP_DateEnd
				
				delete from #TP_Prices
			commit tran tEnd
		end
		--------------------------------------------------------------------------------------
		
		select @TrKey = to_trkey, @nPriceFor = to_pricefor from tp_tours with(nolock) where to_key = @nPriceTourKey
		
		set @nTotalProgress = 5
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey

		----------------------------------------------------------- Здесь апдейтим TS_CHECKMARGIN и TD_CHECKMARGIN
		update tp_services with(rowlock) set ts_checkmargin = 1 where
		(ts_svkey in (select tm_svkey FROM TurMargin with(nolock), tp_turdates with(nolock)
		WHERE	TM_TlKey = @TrKey and td_tokey = @nPriceTourKey
			and td_date Between TM_DateBeg and TM_DateEnd
			and (@dtSaleDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@dtSaleDate <= TM_DateSellEnd or TM_DateSellEnd is null)
		)
		or
		exists(select 1 FROM TurMargin with(nolock), tp_turdates with(nolock)
		WHERE	TM_TlKey = @TrKey and td_tokey = @nPriceTourKey
			and td_date Between TM_DateBeg and TM_DateEnd
			and (@dtSaleDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@dtSaleDate <= TM_DateSellEnd or TM_DateSellEnd is null)
			and tm_svkey = 0)
		)and ts_tokey = @nPriceTourKey

		update [dbo].tp_turdates with(rowlock) set td_checkmargin = 1 where
			exists(select 1 from TurMargin with(nolock) WHERE TM_TlKey = @TrKey
			and TD_DATE Between TM_DateBeg and TM_DateEnd
			and (@dtSaleDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@dtSaleDate <= TM_DateSellEnd or TM_DateSellEnd is null)
		)and td_tokey = @nPriceTourKey
		----------------------------------------------------------- Здесь апдейтим TS_CHECKMARGIN и TD_CHECKMARGIN

--		update TP_Services set ts_tempgross = null where ts_tokey = @nPriceTourKey

		SELECT @round = ST_RoundService FROM Setting
		--MEG00036108 увеличил значение
		set @nProgressSkipLimit = 10000

		set @nProgressSkipCounter = 0
		--Set @nTotalProgress = @nTotalProgress + 1
		--update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
		--считаем сколько записей надо посчитать
		set @NumPrices = ((select count(1) from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) * (select count(1) from tp_turdates with(nolock) where td_tokey = @nPriceTourKey and td_update = @nUpdate))

		if @NumPrices <> 0
			set @nDeltaProgress = (97.0 - 5) / @NumPrices
		else
			set @nDeltaProgress = 97.0 - 5

		exec GetNKeys ''TP_PRICES'', @NumPrices, @nTP_PriceKeyMax output
		set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @NumPrices + 1
		set @dtPrevDate = ''1899-12-31''
		set @nPrevVariant = -1
		set @nPrevGross = -1
		set @nPrevGrossDate = ''1899-12-31''
		set @prevHdKey = -1

		delete from #TP_Prices

		declare @calcPriceListCount int, @calcTurDates int
		select @calcPriceListCount = COUNT(1) from TP_Lists with(nolock) where TI_TOKey = @nPriceTourKey and TI_UPDATE = @nUpdate
		select @calcTurDates = COUNT(1) from TP_TurDates with(nolock) where TD_TOKey = @nPriceTourKey and TD_UPDATE = @nUpdate
		select @calcPricesCount = @calcPriceListCount * @calcTurDates

		insert into #TP_Prices (xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey, xTP_CalculatingKey) 
		select tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey
		from tp_prices with(nolock)
		where tp_tokey = @nPriceTourKey and 
			tp_tikey in (select ti_key from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) and
			tp_datebegin in (select td_date from tp_turdates with(nolock) where td_tokey = @nPriceTourKey and td_update = @nUpdate)
			
		create table #CursorTable
		(	
			id int identity(1,1) primary key,
			ti_firsthdkey int, 
			ts_key int, 
			ti_key int, 
			td_date datetime, 
			ts_svkey int, 
			ts_code int, 
			ts_subcode1 int, 
			ts_subcode2 int, 
			ts_oppartnerkey int, 
			ts_oppacketkey int, 
			ts_day int, 
			ts_days int, 
			to_rate varchar(3), 
			ts_men int, 
			ts_tempgross float, 
			ts_checkmargin smallint, 
			td_checkmargin smallint, 
			ti_totaldays int, 
			ts_ctkey int, 
			ts_attribute int
		)
		
		insert into #CursorTable (ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, to_rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_totaldays, ts_ctkey, ts_attribute)
		select ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, to_rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_totaldays, ts_ctkey, ts_attribute
		from tp_tours with(nolock), tp_services with(nolock), tp_lists with(nolock), tp_servicelists with(nolock), tp_turdates with(nolock)
		where to_key = @nPriceTourKey and to_key = ts_tokey and to_key = ti_tokey and to_key = tl_tokey and ts_key = tl_tskey and ti_key = tl_tikey and to_key = td_tokey
			and ti_update = @nUpdate and td_update = @nUpdate and (@nUseHolidayRule = 0 or (case cast(datepart(weekday, td_date) as int) when 7 then 0 else cast(datepart(weekday, td_date) as int) end + ti_days) >= 8)
		order by ti_firsthdkey, td_date, ti_key
		
		update #CursorTable
		set ts_code = TF_CodeNew, ts_subcode1 = TF_SubCode1New, ts_oppartnerkey = TF_PRKeyNew
		from TP_Flights 
		where TF_TOKey = @nPriceTourKey 
			AND TF_CodeOld = ts_code 
			AND TF_PRKeyOld = ts_oppartnerkey 
			AND TF_Date = td_date + ts_day - 1 
			AND TF_Days = ti_totaldays 
			AND TF_Subcode1 = ts_subcode1
			AND ts_svkey = 1
			
		declare serviceCursor cursor local fast_forward for
		select ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, to_rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_totaldays, ts_ctkey, ts_attribute
		from #CursorTable

		open serviceCursor

		fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_DAYS, @TS_CTKEY, @TS_ATTRIBUTE
		set @fetchStatus = @@fetch_status
		While (@fetchStatus = 0)
		BEGIN
			
			--данных не нашлось, выходим
			if @@fetch_status <> 0 and @nPrevVariant = -1
				break
				
			--очищаем переменные, записываем данные в таблицу #TP_Prices
			if @nPrevVariant <> @variant or @dtPrevDate <> @turdate or @@fetch_status <> 0
			BEGIN
				--записываем данные в таблицу #TP_Prices
				if @nPrevVariant <> -1
				begin
					if @price_brutto is not null
					BEGIN
						exec RoundPriceList @round, @price_brutto output

						if exists(select 1 from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant)
						begin
							if (@isPriceListPluginRecalculation = 0)
								update #TP_Prices set xtp_gross = @price_brutto, xtp_calculatingkey = @nCalculatingKey, xtp_key = @nTP_PriceKeyCurrent where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
							else
								update #TP_Prices set xtp_gross = @price_brutto, xtp_key = @nTP_PriceKeyCurrent where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
							set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
						end
						else if (@isPriceListPluginRecalculation = 0)
						begin
							insert into #TP_Prices (xtp_key, xtp_tokey, xtp_datebegin, xtp_dateend, xtp_gross, xtp_tikey, xTP_CalculatingKey) 
							values (@nTP_PriceKeyCurrent, @nPriceTourKey, @dtPrevDate, @dtPrevDate, @price_brutto, @nPrevVariant, @nCalculatingKey)
							
							set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
						end
					END
					ELSE
					BEGIN
						delete from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
					END
				end
			
				--очищаем данные
				if @@fetch_status = 0
				begin
					if @nTP_PriceKeyCurrent > @nTP_PriceKeyMax
					BEGIN
						exec GetNKeys ''TP_PRICES'', @NumPrices, @nTP_PriceKeyMax output
						set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @NumPrices + 1
					END
					
					set @price_brutto = 0
					set @nPrevVariant = @variant
					set @dtPrevDate = @turdate
				end
				
				set @nTotalProgress = @nTotalProgress + @nDeltaProgress
				if @nProgressSkipCounter = @nProgressSkipLimit
				BEGIN
					update tp_tours with(rowlock) set to_progress = @nTotalProgress, to_updatetime = GetDate() where to_key = @nPriceTourKey
					set @nProgressSkipCounter = 0
				END
				else
					set @nProgressSkipCounter = @nProgressSkipCounter + 1
			END

			--переписываем данные в таблицу tp_prices
			if @hdKey <> @prevHdKey or @@fetch_status <> 0
			begin
				set @prevHdKey = @hdKey
			end
			
			if @@fetch_status <> 0
				break
						
			---------------------------------------------------------------------------------

				if @tsCheckMargin = 1 and @tdCheckMargin = 1
					exec GetTourMargin @TrKey, @turdate, @nMargin output, @nMarginType output, @nSvkey, @TI_DAYS, @dtSaleDate, @nPacketkey
				else
				BEGIN
					set @nMargin = 0
					set @nMarginType = 0
				END
				set @servicedate = @turdate + @nDay - 1
				if @nSvkey = 1
					set @nDays = @TI_DAYS

				-- kurskih 2006/10/11
				-- добавил проверку признака нерассчитываемой услуги
				if @TS_ATTRIBUTE & @SERV_NOTCALCULATE = @SERV_NOTCALCULATE
				BEGIN
					set @nNetto = 0
					set @nBrutto = 0
					set @nDiscount = 0
					set @nPDID = 0
				END
				else
				BEGIN
				
					Set @nSPId = null		
					Set @nBrutto = null	
					if @nCode is not null
					begin
						set @nSign = null

						select
							@nNetto = netto,						
							@nBrutto = brutto,
							@nDiscount = discount,
							@sDetailed = details,
							@sBadRate = badRate,
							@dtBadDate = badDate,
							@sDetailed = details2,
							@nSPId = spid,
							@nSign = row_sign
						from
							#GetServiceCost
						where
							svkey = @nSvkey
							and code = @nCode
							and subcode1 = @nSubcode1
							and subcode2 = @nSubcode2
							and prkey = @nPrkey
							and pkkey = @nPacketkey
							and date = @servicedate
							and days = @nDays
							and rate = @sRate
							and nmen = @nMen
							and margin = @nMargin
							and marginType = @nMarginType
							and saleDate = @dtSaleDate

						if(@nSign is null) -- cost not found
						begin
							exec GetServiceCost @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @servicedate, @nDays,
							@sRate, @nMen, 0, @nMargin, @nMarginType,
							@dtSaleDate, @nNetto output, @nBrutto output, @nDiscount output,
							@nettoDetail output, @sBadRate output, @dtBadDate output,
							@sDetailed output, @nSPId output, 0, @TrKey, @turdate, @TI_DAYS, 1
							
							if @nMen > 1 and @nPriceFor = 0
								set @nBrutto = @nBrutto / @nMen
							if @nBrutto is not null and (@round = @ROUND_SERVICE or @round = @ROUND_SERVICE0_5 or @round = @ROUND_SERVICE_MATH)
								exec RoundPriceList @round, @nBrutto output

							insert into #GetServiceCost(
								svkey,
								code,
								subcode1,
								subcode2,
								prkey,
								pkkey,
								date,
								days,
								rate,
								nmen,
								margin,
								marginType,
								saleDate,
								netto,
								brutto,
								discount,
								details,
								badrate,
								baddate,
								details2,
								spid,
								row_sign)
							values(
								@nSvkey,
								@nCode,
								@nSubcode1,
								@nSubcode2,
								@nPrkey,
								@nPacketkey,
								@servicedate,
								@nDays,
								@sRate,
								@nMen,
								@nMargin,
								@nMarginType,
								@dtSaleDate,
								@nNetto,
								@nBrutto,
								@nDiscount,
								@sDetailed,
								@sBadRate,
								@dtBadDate,
								@sDetailed,
								@nSPId,
								1)
						end
					end
					else
						set @nBrutto = null

					if @nNullCostAsZero = 1 and @nBrutto is null and @nSvkey not in (1,3)
						set @nBrutto = 0
					if @nNullCostAsZero = 1 and @nBrutto is null and @nSvkey = 1 and @nNoFlight = 0
						set @nBrutto = 0	
		
				END

			set @price_brutto = @price_brutto + @nBrutto
			---------------------------------------------------------------------------------

			fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_DAYS, @TS_CTKEY, @TS_ATTRIBUTE
		END
		close serviceCursor
		deallocate serviceCursor

		----------------------------------------------------- возвращаем обратно цены ------------------------------------------------------

		Set @nTotalProgress = 97
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
		--удаление из веба
		if (@nIsEnabled = 1)
		begin
			if (@isPriceListPluginRecalculation = 0)
				EXEC ClearMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
			else	
				EXEC ClearMasterWebSearchFields @nPriceTourKey, null
		end

		delete from tp_prices with(rowlock)
		where tp_tokey = @nPriceTourKey and 
			tp_tikey in (select ti_key from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) and
			tp_DateBegin in (select td_date from TP_TurDates with(nolock) where td_tokey = @nPriceTourKey and TD_Update = @nUpdate)
			
		INSERT INTO TP_Prices with(rowlock) (tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey) 
			select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey, xTP_CalculatingKey 
			from #TP_Prices 

		-----------------------------------------------------КОНЕЦ возвращаем обратно цены ------------------------------------------------------

		update tp_lists with(rowlock) set ti_update = 0 where ti_tokey = @nPriceTourKey
		update tp_turdates with(rowlock) set td_update = 0, td_checkmargin = 0 where td_tokey = @nPriceTourKey
		Set @nTotalProgress = 99
		update tp_tours with(rowlock) set to_progress = @nTotalProgress, to_update = 0, to_updatetime = GetDate(),
							TO_CalculateDateEnd = GetDate(), TO_PriceCount = (Select Count(*) 
			From TP_Prices with(nolock) Where TP_ToKey = to_key) where to_key = @nPriceTourKey
		update tp_services with(rowlock) set ts_checkmargin = 0 where ts_tokey = @nPriceTourKey

	END

	--Заполнение полей в таблице tp_lists
	declare @toKey int, @add int
	set @toKey = @nPriceTourKey
	set @add = @nUpdate

		update tp_lists with(rowlock)
			set ti_hotelkeys = dbo.mwGetTiHotelKeys(ti_key),
				ti_hotelroomkeys = dbo.mwGetTiHotelRoomKeys(ti_key),
				ti_hoteldays = dbo.mwGetTiHotelNights(ti_key),
				ti_hotelstars = dbo.mwGetTiHotelStars(ti_key),
				ti_pansionkeys = dbo.mwGetTiPansionKeys(ti_key),
				ti_nights = dbo.mwGetTiNights(ti_key)
		where
			ti_tokey = @toKey and ti_CalculatingKey = @nCalculatingKey
		
		update tp_lists with(rowlock)
		set
			ti_hdpartnerkey = ts_oppartnerkey,
			ti_firsthotelpartnerkey = ts_oppartnerkey,
			ti_hdday = ts_day,
			ti_hdnights = ts_days
		from tp_servicelists with (nolock)
			inner join tp_services with (nolock) on (tl_tskey = ts_key and ts_svkey = 3)
		where tl_tikey = ti_key and ts_code = ti_firsthdkey and ti_tokey = @toKey and tl_tokey = @toKey
			and ts_tokey = @toKey and ti_CalculatingKey = @nCalculatingKey
		------------------------------------------------------------------------------

	Set @nTotalProgress = 100
	update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	
	', 
	N' @fetchStatus smallint
	, @hdKey int 
	, @isPriceListPluginRecalculation smallint
	, @nBrutto money
	, @nCode int
	, @nDiscount money
	, @nMargin money
	, @nMarginType int
	, @nMen int
	, @nNetto money
	, @nNullCostAsZero smallint
	, @nPDID int
	, @nPrevVariant int 
	, @nPriceTourKey int 
	, @nProgressSkipCounter smallint
	, @nSign tinyint
	, @nSPId int
	, @nSvkey int
	, @nTotalProgress decimal(14, 8)
	, @nTP_PriceKeyCurrent int
	, @nTP_PriceKeyMax int
	, @NumPrices int
	, @price_brutto money
	, @round smallint
	, @TI_DAYS int
	, @TrKey int
	, @TS_ATTRIBUTE int
	, @tsCheckMargin smallint
	, @turdate datetime
	, @variant int
	, @nServiceKey int
	, @nCalculatingKey int
	, @dtPrevDate datetime
	, @nDeltaProgress decimal(14, 8)
	, @nProgressSkipLimit smallint
	, @prevHdKey int
	, @tdCheckMargin smallint
	, @dtSaleDate datetime
	, @nDay int
	, @nDays int 
	, @SERV_NOTCALCULATE int
	, @sDetailed varchar(100)
	, @nSubcode1 int
	, @nPriceFor smallint
	, @ROUND_SERVICE int
	, @nNoFlight smallint
	, @nSubcode2 int
	, @nPacketkey int
	, @servicedate datetime 
	, @sBadRate varchar(3)
	, @ROUND_SERVICE0_5 int
	, @nPrkey int 
	, @dtBadDate datetime
	, @ROUND_SERVICE_MATH int
	, @sRate varchar(3)
	, @nTempGross money
	, @nettoDetail nvarchar(max)
	, @TS_CTKEY int
	, @calcPricesCount int output
	, @numDates int
	, @priceDate datetime
	, @priceListKey int
	, @nUpdate smallint
	, @nPrevGross money
	, @nPrevGrossDate datetime
	, @nIsEnabled smallint
	, @priceListGross int 
	, @nUseHolidayRule smallint'
	, @fetchStatus
	, @hdKey
	, @isPriceListPluginRecalculation
	, @nBrutto
	, @nCode
	, @nDiscount
	, @nMargin
	, @nMarginType
	, @nMen
	, @nNetto
	, @nNullCostAsZero
	, @nPDID
	, @nPrevVariant
	, @nPriceTourKey
	, @nProgressSkipCounter
	, @nSign
	, @nSPId
	, @nSvkey
	, @nTotalProgress
	, @nTP_PriceKeyCurrent
	, @nTP_PriceKeyMax
	, @NumPrices
	, @price_brutto
	, @round
	, @TI_DAYS
	, @TrKey
	, @TS_ATTRIBUTE
	, @tsCheckMargin
	, @turdate
	, @variant
	, @nServiceKey
	, @nCalculatingKey
	, @dtPrevDate
	, @nDeltaProgress
	, @nProgressSkipLimit
	, @prevHdKey
	, @tdCheckMargin
	, @dtSaleDate
	, @nDay
	, @nDays
	, @SERV_NOTCALCULATE
	, @sDetailed
	, @nSubcode1
	, @nPriceFor
	, @ROUND_SERVICE
	, @nNoFlight			
	, @nSubcode2
	, @nPacketkey
	, @servicedate
	, @sBadRate
	, @ROUND_SERVICE0_5
	, @nPrkey
	, @dtBadDate
	, @ROUND_SERVICE_MATH		
	, @sRate	
	, @nTempGross
	, @nettoDetail
	, @TS_CTKEY
	, @calcPricesCount output
	, @numDates
	, @priceDate
	, @priceListKey
	, @nUpdate
	, @nPrevGross
	, @nPrevGrossDate
	, @nIsEnabled	
	, @priceListGross
	, @nUseHolidayRule
	
	set DATEFIRST @nDateFirst

	set nocount off

	--Засекаем время окончания рассчета begin
	declare @endPriceCalculate datetime
	set @endPriceCalculate = GETDATE()
	SET @sHI_Text = CONVERT(varchar(30),@endPriceCalculate,121)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11010, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Засекаем время окончания рассчета end

	--Записываем кол-во рассчитанных цен begin
	SET @sHI_Text = CONVERT(varchar(10),@calcPricesCount)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11011, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Записываем кол-во рассчитанных цен end

	--Записываем скорость расчета цен begin
	declare @calculatingSpeed decimal(10,2), @seconds int
	set @seconds = datediff(ss,@beginPriceCalculate,@endPriceCalculate)
	if @seconds = 0
		set @seconds = 1
	set @calculatingSpeed = @calcPricesCount / @seconds
	SET @sHI_Text = CONVERT(varchar(10),@calculatingSpeed)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11012, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Записываем скорость расчета цен end
	
	if (@nIsEnabled = 1)
	begin
		if (@isPriceListPluginRecalculation = 0)
			EXEC FillMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
		else
			EXEC FillMasterWebSearchFields @nPriceTourKey, null
	end

	-- апдейтим таблицу CalculatingPriceLists
	update CalculatingPriceLists with(rowlock) set CP_Status = 0, CP_StartTime = null where CP_Key = @nCalculatingKey
	
	Return 0
END
GO

grant execute on [dbo].[CalculatePriceList] to public
GO
/*********************************************************************/
/* end sp_CalculatePriceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalculatePriceListDynamic.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalculatePriceListDynamic]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CalculatePriceListDynamic]
GO

CREATE PROCEDURE [dbo].[CalculatePriceListDynamic]
(
	--<data>2014-03-03</data>
	--<version>9.2.21.8</version>
	@nPriceTourKey int,				-- ключ обсчитываемого тура
	@nCalculatingKey int,			-- ключ итерации дозаписи
	@dtSaleDate datetime,			-- дата продажи
	@nNullCostAsZero smallint,		-- считать отсутствующие цены нулевыми (кроме проживания) 0 - нет, 1 - да
	@nNoFlight smallint,			-- при отсутствии перелёта в расписании 0 - ничего не делать, 1 - не обсчитывать тур, 2 - искать подходящий перелёт (если не найдено - не рассчитывать)
	@nUpdate smallint,				-- признак дозаписи 0 - расчет, 1 - дозапись
	@nUseHolidayRule smallint		-- Правило выходного дня: 0 - не использовать, 1 - использовать
)
AS

SET ARITHABORT off;
set nocount on;
declare @beginTime datetime
set @beginTime = getDate()

declare @variant int
declare @pricetour int
declare @turdate datetime
declare @servicedate datetime
declare @price_brutto money
declare @TrKey int
declare @userKey int
--
declare @nServiceKey int
declare @nSvkey int
declare @nCode int
declare @nSubcode1 int
declare @nSubcode2 int
declare @nPrkey int
declare @nPacketkey int
declare @nDay int
declare @nDays int
declare @sRate varchar(3)
declare @nMen int
declare @nMargin money
declare @nMarginType int
declare @nNetto money
declare @nBrutto money
declare @nDiscount money
declare @nTempGross money
declare @tsCheckMargin smallint
declare @tdCheckMargin smallint
declare @TI_DAYS int
declare @TS_CTKEY int
declare @TS_ATTRIBUTE int
--
declare @SERV_NOTCALCULATE int
--
declare @dtPrevDate datetime
declare @nPrevVariant int
declare @nPrevGross money
declare @nPrevGrossKey int
declare @nPrevGrossDate datetime
declare @nPriceFor smallint
declare @nTP_PriceKeyCurrent int
declare @nTP_PriceKeyMax int
declare @NumPrices int, @NumCalculated int, @PricesCount int
--
declare @fetchStatus smallint
--declare @nCount int
declare @nDeltaProgress decimal(14, 8)
declare @nTotalProgress decimal(14, 8)
declare @round smallint
--
declare @hdKey int
declare @prevHdKey int
--
declare @nProgressSkipLimit smallint
declare @nProgressSkipCounter smallint
declare @weekday varchar(3)
declare @nDateFirst smallint
declare @nFlightEnabled smallint
declare @nCH_Key int
declare @CS_PRKEY int
declare @dDateBeg1 datetime -- дата начала 1го периода
declare @dDateBeg3 datetime -- дата начала 2,3го периода
declare @dDateEnd1 datetime -- дата окончания 1го периода
declare @dDateEnd3 datetime -- дата окончания 2,3го периода
--
declare @sDetailed varchar(100) -- не используется, необходима только для передачи в качестве параметра в GSC
declare @sBadRate varchar(3)
declare @dtBadDate DateTime
--
declare @nSPId int -- возвращается из GSC, фактически это ключ из ServicePrices
declare @nPDId int 
declare @nBruttoWithCommission money

--переменные для разбиения сгруппированных цен
declare @priceDate datetime
declare @priceListKey int
declare @numDates int
declare @priceListGross int
---------------------------------------------
declare @ROUND_NOTWITHDISC int
declare @ROUND_SERVICE_MATH int
declare @ROUND_SERVICE0_5 int
declare @ROUND_PRICE0_5 int
declare @ROUND_SERVICE int
declare @ROUND_PRICE int
declare @ROUND_NOT int

Set @ROUND_NOTWITHDISC = 64
Set @ROUND_SERVICE_MATH = 32
Set @ROUND_SERVICE0_5 = 16
Set @ROUND_PRICE0_5 = 8
Set @ROUND_SERVICE = 4
Set @ROUND_PRICE = 2
Set @ROUND_NOT = 1
---------------------------------------------
declare @nIsEnabled smallint
--select @nIsEnabled = TO_IsEnabled from TP_Tours where TO_Key = @nPriceTourKey
--set @nIsEnabled = 0
---------------------------------------------
declare @tpPricesCount int
declare @isPriceListPluginRecalculation smallint
select @tpPricesCount = count(1) from tp_prices with(nolock) where tp_tokey = @nPriceTourKey

if exists(select top 1 1 from tp_lists with(nolock) where TI_TOKey = @nPriceTourKey and TI_TotalDays is null)
begin
	select TI_Key as xTI_Key, TI_TOKey as xTI_TOKey, TI_CalculatingKey as xTI_CalculatingKey, ti_totaldays as xti_totaldays
	into #tmp
	from tp_lists with(nolock)
	where TI_TOKey = @nPriceTourKey 
	and TI_TotalDays is null
		
	update #tmp with(rowlock)
	set
		xti_totaldays = (select max(case ts_svkey 
						when 3 
						then ts_day + ts_days 
						else (case ts_days 
							when 0 
							then 1 
							else ts_days 
      								end) + ts_day - 1 
 							end)
				from dbo.tp_services with (nolock)
					inner join dbo.tp_servicelists with (nolock) on (tl_tskey = ts_key and TS_TOKey = @nPriceTourKey and TL_TOKey = @nPriceTourKey)
				where tl_tikey = xti_key)
		
	update TP_Lists
	set ti_totaldays = xti_totaldays
	from #tmp
	where xTI_Key = TI_Key
end

if (@nCalculatingKey is null)
begin
	select top 1 @nCalculatingKey = CP_Key from CalculatingPriceLists with(nolock) where CP_PriceTourKey = @nPriceTourKey and CP_Update = 0
	update tp_turdates set td_update = 0 where td_tokey = @nPriceTourKey
	update tp_lists set ti_update = 0 where ti_tokey = @nPriceTourKey
	if (@tpPricesCount <> 0)
		set @isPriceListPluginRecalculation = 1
	else
		set @isPriceListPluginRecalculation = 0
end
else
	set @isPriceListPluginRecalculation = 0

declare @calculatingPriceListsExists smallint -- 0 - CalculatingPriceLists нет, 1 - CalculatingPriceLists есть в базе

print 'Инициализация: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
set @beginTime = getDate()

BEGIN		
	--koshelev
	--MEG00027550
	if @nUpdate = 0
	begin
		update tp_tours with(rowlock) set to_datecreated = GetDate() where to_key = @nPriceTourKey
	end

	select @TrKey = to_trkey, @userKey = to_opkey from tp_tours with(nolock) where to_key = @nPriceTourKey

	if not exists (select 1 from CalculatingPriceLists with(nolock) where CP_PriceTourKey = @nPriceTourKey) and @nPriceTourKey is not null
	begin	
		insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_TourKey, CP_UserKey, CP_Status, CP_UseHolidayRule)
		values (@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @TrKey, @userKey, 1, @nUseHolidayRule)
	end
	else if @nPriceTourKey is not null
	begin
		update CalculatingPriceLists with(rowlock) set CP_Status = 1 where CP_Key = @nCalculatingKey
	end

	DECLARE @sHI_Text varchar(254), @nHIID int
	SELECT @sHI_Text=TO_Name FROM tp_tours with(nolock) where to_key = @nPriceTourKey
	EXEC @nHIID = dbo.InsHistory '', null, 11, @nPriceTourKey, 'INS', @sHI_Text, '', 0, ''

	SET @sHI_Text=CONVERT(varchar(30),@dtSaleDate,104)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11001, null, @sHI_Text, null, null, null, @dtSaleDate, 0
	If @nNullCostAsZero=0
		SET @sHI_Text='NO'
	ELSE
		SET @sHI_Text='YES'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11002, null, @sHI_Text, null, @nNullCostAsZero, null, null, 0
	If @nNoFlight=0
		SET @sHI_Text='NO'
	ELSE
		SET @sHI_Text='Flight search'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11003, null, @sHI_Text, null, @nNoFlight, null, null, 0
	If @nUpdate=0
		SET @sHI_Text='First calculate'
	ELSE
		SET @sHI_Text='Add calculate'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11004, null, @sHI_Text, null, @nUpdate, null, null, 0
	If @nUseHolidayRule = 0
		SET @sHI_Text = 'NO'
	ELSE
		SET @sHI_Text = 'YES'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11008, null, @sHI_Text, null, @nUpdate, null, null, 0
	
	--Засекаем время начала рассчета begin
	declare @beginPriceCalculate datetime
	set @beginPriceCalculate = GETDATE()
	SET @sHI_Text = CONVERT(varchar(30),@beginPriceCalculate,121)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11009, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Засекаем время начала рассчета end
	
	print 'Запись в историю: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()

	Set @nTotalProgress=1
	update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	select @nDateFirst = @@DATEFIRST
	set DATEFIRST 1
	set @SERV_NOTCALCULATE = 32768

	If @nUpdate=0
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_TourDate, TF_CalculatingKey)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey,
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days, TD_Date, @nCalculatingKey
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock), TP_Lists with(nolock), TP_ServiceLists with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TI_TOKey = TO_Key and TL_TOKey = TO_Key and TL_TSKey = TS_Key and TL_TIKey = TI_Key and TO_Key = @nPriceTourKey
	Else
	BEGIN
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_TourDate, TF_CalculatingKey)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey,
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days, TD_Date, @nCalculatingKey
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock), TP_Lists with(nolock), TP_ServiceLists with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TI_TOKey = TO_Key and TL_TOKey = TO_Key and TL_TSKey = TS_Key and TL_TIKey = TI_Key and TO_Key = @nPriceTourKey
			and not exists (Select TF_ID From TP_Flights with(nolock) Where TF_TOKey=TO_Key and TF_Date=(TD_Date + TS_Day - 1) 
						and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
						and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = TI_Days and TF_CodeNew is not null)	
	END
	
	print 'Подбор перелетов 1: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре (с учетом цен в которых дата продажи NULL или больше/равна сегодняшней дате )----
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey 
			and TF_Date BETWEEN CS_Date AND  CS_DateEnd and (ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long) and (cs_DateSellBeg <= @dtSaleDate or cs_DateSellBeg is null) 
			and (cs_DateSellEnd >= @dtSaleDate or cs_DateSellEnd is null))
			and TF_TOKey = @nPriceTourKey
	
	print 'Подбор перелетов 2: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()

	If @nNoFlight = 2
	BEGIN
		------ проверяем, а есть ли у данного парнера по рейсу, цены на другие рейсы в этом же пакете ----		
		
		IF exists(SELECT TF_ID FROM TP_Flights with(nolock) WHERE TF_TOKey = @nPriceTourKey and TF_CodeNew is Null) 
		begin
			print 'Подбираем перелет'
			
			declare @newFlightsPartnerTable table
			(
				-- идентификатор
				xId int identity(1,1),
				-- ключ услуги перелет
				xTFId int,
				-- ключ исходного партнера
				xPRKey int,
				-- ключ партнера которого подобрали
				xPRKeyNew int,
				-- ключ перелета
				xCHKey int,
				-- ключ тарифа на перелет
				xASKey int
			)
			-- подбираем подходящие нам перелеты (с учетом цен в которых дата продажи NULL или больше/равна сегодняшней дате )
			insert into @newFlightsPartnerTable (xTFId, xCHKey, xASKey, xPRKey, xPRKeyNew)
			SELECT TF_Id, CH_Key, CS_SubCode1, TF_PRKeyOld, CS_PRKey
			FROM AirSeason with(nolock), Charter with(nolock), Costs with(nolock), TP_Flights with(nolock)
			WHERE CH_CityKeyFrom = TF_Subcode2 and
			CH_CityKeyTo = TF_CTKey and
			CS_Code = CH_Key and
			AS_CHKey = CH_Key and
			CS_SVKey = 1 and
			(	isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = CS_SubCode1), '')
				= 
				isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = TF_Subcode1), '')
			)
			and (cs_DateSellBeg <= @dtSaleDate or cs_DateSellBeg is null) 
			and (cs_DateSellEnd >= @dtSaleDate or cs_DateSellEnd is null)
			and CS_PKKey = TF_PKKey and
			TF_Date BETWEEN AS_DateFrom and AS_DateTo and
			TF_Date BETWEEN CS_Date and CS_DateEnd and
			AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
			(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and
			(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long) and
			TF_CodeNew is Null and 
			TF_TOKey = @nPriceTourKey
			group by TF_Id, CH_Key, CS_SubCode1, TF_PRKeyOld, CS_PRKey
			
			-- удаляем повторяющиеся (если подобралось несколько перелетов)
			delete @newFlightsPartnerTable
			from @newFlightsPartnerTable as a
			where a.xId != (select top 1 b.xId 
							from @newFlightsPartnerTable as b 
							where b.xTFId = a.xTFId
							-- и приорететнее те перелеты в которых партнеры совпадают с исходным
							order by case when b.xPRKey = b.xPRKeyNew then 0 else 1 end)
			
			-- обновляем информацию о найденом перелете
			update TP_Flights with(rowlock)
			set TF_CodeNew = xCHKey,
			TF_SubCode1New = xASKey,
			TF_PRKeyNew = xPRKeyNew,
			TF_CalculatingKey = @nCalculatingKey
			from TP_Flights with(rowlock) join @newFlightsPartnerTable on TF_Id = xTFId
			
			print 'Закончили подбор перелетов'		
		end
		
		print 'Подбор перелетов 3: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()	
	END

	--------------------------------------- закончили поиск подходящего перелета --------------------------------------
	if (1 = 1)
	BEGIN
		update [dbo].tp_tours with(rowlock) set to_update = 1 where to_key = @nPriceTourKey
		Set @nTotalProgress=4
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	
		--------------------------------------- сохраняем цены во временной таблице --------------------------------------
		CREATE TABLE #TP_Prices
		(
			[xTP_Key] [int] NULL ,
			[xTP_TOKey] [int] NOT NULL ,
			[xTP_DateBegin] [datetime] NOT NULL ,
			[xTP_DateEnd] [datetime] NULL ,
			-- формула расчета общей цены тура
			[xTP_Gross] as (((case when  [xSCPId_1] is not null then  [xGross_1] else 0 end) * (1 + (isnull( [xMarginPercent_1], 0)/100) * (1 + (isnull( [xIsCommission_1], 0) - 1) * isnull( [xCommissionOnly_1], 0))) + isnull( [xAddCostIsCommission_1], 0) * (1 + (isnull( [xMarginPercent_1], 0)/100)) + isnull( [xAddCostNoCommission_1], 0) * (1 + (isnull( [xMarginPercent_1], 0)/100) * (1 - isnull( [xCommissionOnly_1], 0)))) +
							((case when  [xSCPId_2] is not null then  [xGross_2] else 0 end) * (1 + (isnull( [xMarginPercent_2], 0)/100) * (1 + (isnull( [xIsCommission_2], 0) - 1) * isnull( [xCommissionOnly_2], 0))) + isnull( [xAddCostIsCommission_2], 0) * (1 + (isnull( [xMarginPercent_2], 0)/100)) + isnull( [xAddCostNoCommission_2], 0) * (1 + (isnull( [xMarginPercent_2], 0)/100) * (1 - isnull( [xCommissionOnly_2], 0)))) +
							((case when  [xSCPId_3] is not null then  [xGross_3] else 0 end) * (1 + (isnull( [xMarginPercent_3], 0)/100) * (1 + (isnull( [xIsCommission_3], 0) - 1) * isnull( [xCommissionOnly_3], 0))) + isnull( [xAddCostIsCommission_3], 0) * (1 + (isnull( [xMarginPercent_3], 0)/100)) + isnull( [xAddCostNoCommission_3], 0) * (1 + (isnull( [xMarginPercent_3], 0)/100) * (1 - isnull( [xCommissionOnly_3], 0)))) +
							((case when  [xSCPId_4] is not null then  [xGross_4] else 0 end) * (1 + (isnull( [xMarginPercent_4], 0)/100) * (1 + (isnull( [xIsCommission_4], 0) - 1) * isnull( [xCommissionOnly_4], 0))) + isnull( [xAddCostIsCommission_4], 0) * (1 + (isnull( [xMarginPercent_4], 0)/100)) + isnull( [xAddCostNoCommission_4], 0) * (1 + (isnull( [xMarginPercent_4], 0)/100) * (1 - isnull( [xCommissionOnly_4], 0)))) +
							((case when  [xSCPId_5] is not null then  [xGross_5] else 0 end) * (1 + (isnull( [xMarginPercent_5], 0)/100) * (1 + (isnull( [xIsCommission_5], 0) - 1) * isnull( [xCommissionOnly_5], 0))) + isnull( [xAddCostIsCommission_5], 0) * (1 + (isnull( [xMarginPercent_5], 0)/100)) + isnull( [xAddCostNoCommission_5], 0) * (1 + (isnull( [xMarginPercent_5], 0)/100) * (1 - isnull( [xCommissionOnly_5], 0)))) +
							((case when  [xSCPId_6] is not null then  [xGross_6] else 0 end) * (1 + (isnull( [xMarginPercent_6], 0)/100) * (1 + (isnull( [xIsCommission_6], 0) - 1) * isnull( [xCommissionOnly_6], 0))) + isnull( [xAddCostIsCommission_6], 0) * (1 + (isnull( [xMarginPercent_6], 0)/100)) + isnull( [xAddCostNoCommission_6], 0) * (1 + (isnull( [xMarginPercent_6], 0)/100) * (1 - isnull( [xCommissionOnly_6], 0)))) +
							((case when  [xSCPId_7] is not null then  [xGross_7] else 0 end) * (1 + (isnull( [xMarginPercent_7], 0)/100) * (1 + (isnull( [xIsCommission_7], 0) - 1) * isnull( [xCommissionOnly_7], 0))) + isnull( [xAddCostIsCommission_7], 0) * (1 + (isnull( [xMarginPercent_7], 0)/100)) + isnull( [xAddCostNoCommission_7], 0) * (1 + (isnull( [xMarginPercent_7], 0)/100) * (1 - isnull( [xCommissionOnly_7], 0)))) +
							((case when  [xSCPId_8] is not null then  [xGross_8] else 0 end) * (1 + (isnull( [xMarginPercent_8], 0)/100) * (1 + (isnull( [xIsCommission_8], 0) - 1) * isnull( [xCommissionOnly_8], 0))) + isnull( [xAddCostIsCommission_8], 0) * (1 + (isnull( [xMarginPercent_8], 0)/100)) + isnull( [xAddCostNoCommission_8], 0) * (1 + (isnull( [xMarginPercent_8], 0)/100) * (1 - isnull( [xCommissionOnly_8], 0)))) +
							((case when  [xSCPId_9] is not null then  [xGross_9] else 0 end) * (1 + (isnull( [xMarginPercent_9], 0)/100) * (1 + (isnull( [xIsCommission_9], 0) - 1) * isnull( [xCommissionOnly_9], 0))) + isnull( [xAddCostIsCommission_9], 0) * (1 + (isnull( [xMarginPercent_9], 0)/100)) + isnull( [xAddCostNoCommission_9], 0) * (1 + (isnull( [xMarginPercent_9], 0)/100) * (1 - isnull( [xCommissionOnly_9], 0)))) +
							((case when [xSCPId_10] is not null then [xGross_10] else 0 end) * (1 + (isnull([xMarginPercent_10], 0)/100) * (1 + (isnull([xIsCommission_10], 0) - 1) * isnull([xCommissionOnly_10], 0))) + isnull([xAddCostIsCommission_10], 0) * (1 + (isnull([xMarginPercent_10], 0)/100)) + isnull([xAddCostNoCommission_10], 0) * (1 + (isnull([xMarginPercent_10], 0)/100) * (1 - isnull([xCommissionOnly_10], 0)))) +
							((case when [xSCPId_11] is not null then [xGross_11] else 0 end) * (1 + (isnull([xMarginPercent_11], 0)/100) * (1 + (isnull([xIsCommission_11], 0) - 1) * isnull([xCommissionOnly_11], 0))) + isnull([xAddCostIsCommission_11], 0) * (1 + (isnull([xMarginPercent_11], 0)/100)) + isnull([xAddCostNoCommission_11], 0) * (1 + (isnull([xMarginPercent_11], 0)/100) * (1 - isnull([xCommissionOnly_11], 0)))) +
							((case when [xSCPId_12] is not null then [xGross_12] else 0 end) * (1 + (isnull([xMarginPercent_12], 0)/100) * (1 + (isnull([xIsCommission_12], 0) - 1) * isnull([xCommissionOnly_12], 0))) + isnull([xAddCostIsCommission_12], 0) * (1 + (isnull([xMarginPercent_12], 0)/100)) + isnull([xAddCostNoCommission_12], 0) * (1 + (isnull([xMarginPercent_12], 0)/100) * (1 - isnull([xCommissionOnly_12], 0)))) +
							((case when [xSCPId_13] is not null then [xGross_13] else 0 end) * (1 + (isnull([xMarginPercent_13], 0)/100) * (1 + (isnull([xIsCommission_13], 0) - 1) * isnull([xCommissionOnly_13], 0))) + isnull([xAddCostIsCommission_13], 0) * (1 + (isnull([xMarginPercent_13], 0)/100)) + isnull([xAddCostNoCommission_13], 0) * (1 + (isnull([xMarginPercent_13], 0)/100) * (1 - isnull([xCommissionOnly_13], 0)))) +
							((case when [xSCPId_14] is not null then [xGross_14] else 0 end) * (1 + (isnull([xMarginPercent_14], 0)/100) * (1 + (isnull([xIsCommission_14], 0) - 1) * isnull([xCommissionOnly_14], 0))) + isnull([xAddCostIsCommission_14], 0) * (1 + (isnull([xMarginPercent_14], 0)/100)) + isnull([xAddCostNoCommission_14], 0) * (1 + (isnull([xMarginPercent_14], 0)/100) * (1 - isnull([xCommissionOnly_14], 0)))) +
							((case when [xSCPId_15] is not null then [xGross_15] else 0 end) * (1 + (isnull([xMarginPercent_15], 0)/100) * (1 + (isnull([xIsCommission_15], 0) - 1) * isnull([xCommissionOnly_15], 0))) + isnull([xAddCostIsCommission_15], 0) * (1 + (isnull([xMarginPercent_15], 0)/100)) + isnull([xAddCostNoCommission_15], 0) * (1 + (isnull([xMarginPercent_15], 0)/100) * (1 - isnull([xCommissionOnly_15], 0))))),
			[xTP_TIKey] [int] NOT NULL,
			[xTP_HotelKey] [int] NOT NULL,
			[xTP_DepartureKey] [int] NOT NULL,
			[xTP_CalculatingKey] [int] NULL,
			[xTP_Days] [int] null,
			[xTP_Rate] [nvarchar](2) null,
			[xSCPId_1] [int] null,
			[xSCPId_2] [int] null,
			[xSCPId_3] [int] null,
			[xSCPId_4] [int] null,
			[xSCPId_5] [int] null,
			[xSCPId_6] [int] null,
			[xSCPId_7] [int] null,
			[xSCPId_8] [int] null,
			[xSCPId_9] [int] null,
			[xSCPId_10] [int] null,
			[xSCPId_11] [int] null,
			[xSCPId_12] [int] null,
			[xSCPId_13] [int] null,
			[xSCPId_14] [int] null,
			[xSCPId_15] [int] null,
			
			[xSvKey_1] [int] null,
			[xSvKey_2] [int] null,
			[xSvKey_3] [int] null,
			[xSvKey_4] [int] null,
			[xSvKey_5] [int] null,
			[xSvKey_6] [int] null,
			[xSvKey_7] [int] null,
			[xSvKey_8] [int] null,
			[xSvKey_9] [int] null,
			[xSvKey_10] [int] null,
			[xSvKey_11] [int] null,
			[xSvKey_12] [int] null,
			[xSvKey_13] [int] null,
			[xSvKey_14] [int] null,
			[xSvKey_15] [int] null,
			
			[xGross_1] [money] null,
			[xGross_2] [money] null,
			[xGross_3] [money] null,
			[xGross_4] [money] null,
			[xGross_5] [money] null,
			[xGross_6] [money] null,
			[xGross_7] [money] null,
			[xGross_8] [money] null,
			[xGross_9] [money] null,
			[xGross_10] [money] null,
			[xGross_11] [money] null,
			[xGross_12] [money] null,
			[xGross_13] [money] null,
			[xGross_14] [money] null,
			[xGross_15] [money] null,
			
			[xAddCostIsCommission_1] [money] null,
			[xAddCostIsCommission_2] [money] null,
			[xAddCostIsCommission_3] [money] null,
			[xAddCostIsCommission_4] [money] null,
			[xAddCostIsCommission_5] [money] null,
			[xAddCostIsCommission_6] [money] null,
			[xAddCostIsCommission_7] [money] null,
			[xAddCostIsCommission_8] [money] null,
			[xAddCostIsCommission_9] [money] null,
			[xAddCostIsCommission_10] [money] null,
			[xAddCostIsCommission_11] [money] null,
			[xAddCostIsCommission_12] [money] null,
			[xAddCostIsCommission_13] [money] null,
			[xAddCostIsCommission_14] [money] null,
			[xAddCostIsCommission_15] [money] null,
			
			[xAddCostNoCommission_1] [money] null,
			[xAddCostNoCommission_2] [money] null,
			[xAddCostNoCommission_3] [money] null,
			[xAddCostNoCommission_4] [money] null,
			[xAddCostNoCommission_5] [money] null,
			[xAddCostNoCommission_6] [money] null,
			[xAddCostNoCommission_7] [money] null,
			[xAddCostNoCommission_8] [money] null,
			[xAddCostNoCommission_9] [money] null,
			[xAddCostNoCommission_10] [money] null,
			[xAddCostNoCommission_11] [money] null,
			[xAddCostNoCommission_12] [money] null,
			[xAddCostNoCommission_13] [money] null,
			[xAddCostNoCommission_14] [money] null,
			[xAddCostNoCommission_15] [money] null,
			
			[xMarginPercent_1] [money] null,
			[xMarginPercent_2] [money] null,
			[xMarginPercent_3] [money] null,
			[xMarginPercent_4] [money] null,
			[xMarginPercent_5] [money] null,
			[xMarginPercent_6] [money] null,
			[xMarginPercent_7] [money] null,
			[xMarginPercent_8] [money] null,
			[xMarginPercent_9] [money] null,
			[xMarginPercent_10] [money] null,
			[xMarginPercent_11] [money] null,
			[xMarginPercent_12] [money] null,
			[xMarginPercent_13] [money] null,
			[xMarginPercent_14] [money] null,
			[xMarginPercent_15] [money] null,
			
			[xCommissionOnly_1] [bit] null,
			[xCommissionOnly_2] [bit] null,
			[xCommissionOnly_3] [bit] null,
			[xCommissionOnly_4] [bit] null,
			[xCommissionOnly_5] [bit] null,
			[xCommissionOnly_6] [bit] null,
			[xCommissionOnly_7] [bit] null,
			[xCommissionOnly_8] [bit] null,
			[xCommissionOnly_9] [bit] null,
			[xCommissionOnly_10] [bit] null,
			[xCommissionOnly_11] [bit] null,
			[xCommissionOnly_12] [bit] null,
			[xCommissionOnly_13] [bit] null,
			[xCommissionOnly_14] [bit] null,
			[xCommissionOnly_15] [bit] null,
			
			[xIsCommission_1] [bit] null,
			[xIsCommission_2] [bit] null,
			[xIsCommission_3] [bit] null,
			[xIsCommission_4] [bit] null,
			[xIsCommission_5] [bit] null,
			[xIsCommission_6] [bit] null,
			[xIsCommission_7] [bit] null,
			[xIsCommission_8] [bit] null,
			[xIsCommission_9] [bit] null,
			[xIsCommission_10] [bit] null,
			[xIsCommission_11] [bit] null,
			[xIsCommission_12] [bit] null,
			[xIsCommission_13] [bit] null,
			[xIsCommission_14] [bit] null,
			[xIsCommission_15] [bit] null
		)

		CREATE NONCLUSTERED INDEX [x_fields] ON [#TP_Prices] 
		(
			[xTP_TOKey] ASC,
			[xTP_TIKey] ASC,
			[xTP_DateBegin] ASC,
			[xTP_DateEnd] ASC
		)

		DELETE FROM #TP_Prices
		---------------------------------------КОНЕЦ  сохраняем цены во временной таблице --------------------------------------
		

		---------------------------------------разбиваем данные в таблицах tp_prices по датам
		if (select COUNT(TP_Key) from TP_Prices with(nolock) where TP_DateBegin != TP_DateEnd and TP_TOKey = @nPriceTourKey) > 0
		begin
		
			declare datesCursor cursor local fast_forward for
			select TD_Date, TI_Key, TP_Gross from TP_TurDates with(nolock), TP_Lists with(nolock), TP_Prices with(nolock) where TP_TIKey = TI_Key and TD_Date between TP_DateBegin and TP_DateEnd and TP_TOKey = @nPriceTourKey and TD_TOKey = @nPriceTourKey and TI_TOKey = @nPriceTourKey
			
			open datesCursor
			fetch next from datesCursor into @priceDate, @priceListKey, @priceListGross
			while @@FETCH_STATUS = 0
			begin
				insert into #TP_Prices (xTP_TOKey, xTP_TIKey, xTP_DateBegin, xTP_DateEnd, xTP_CalculatingKey) 
				values (@nPriceTourKey, @priceListKey, @priceDate, @priceDate, @nCalculatingKey)
				
				fetch next from datesCursor into @priceDate, @priceListKey, @priceListGross
			end
			
			close datesCursor
			deallocate datesCursor
			
			select @numDates = count(1) from #TP_Prices
			exec GetNKeys 'TP_PRICES', @numDates, @nTP_PriceKeyMax output
			set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @numDates
			
			update #tp_prices 
			set xTP_Key = @nTP_PriceKeyCurrent, @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
			
			begin tran tEnd
				delete from TP_Prices with(rowlock) where TP_TOKey = @nPriceTourKey
				
				insert into TP_Prices (TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, TP_CalculatingKey)
				select xTP_Key, xTP_TOKey, xTP_TIKey, xTP_Gross, xTP_DateBegin, xTP_DateEnd, @nCalculatingKey
				from #TP_Prices  
				where xTP_DateBegin = xTP_DateEnd
				
				delete from #TP_Prices
			commit tran tEnd
		end
		--------------------------------------------------------------------------------------
		
		select @TrKey = to_trkey, @nPriceFor = to_pricefor from tp_tours with(nolock) where to_key = @nPriceTourKey
		set @nTotalProgress = 5
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey

		----------------------------------------------------------- Здесь апдейтим TS_CHECKMARGIN и TD_CHECKMARGIN
		update tp_services with(rowlock) set ts_checkmargin = 1 where
		(ts_svkey in (select tm_svkey FROM TurMargin with(nolock), tp_turdates with(nolock)
		WHERE	TM_TlKey = @TrKey and td_tokey = @nPriceTourKey
			and td_date Between TM_DateBeg and TM_DateEnd
			and (@dtSaleDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@dtSaleDate <= TM_DateSellEnd or TM_DateSellEnd is null)
		)
		or
		exists(select 1 FROM TurMargin with(nolock), tp_turdates with(nolock)
		WHERE	TM_TlKey = @TrKey and td_tokey = @nPriceTourKey
			and td_date Between TM_DateBeg and TM_DateEnd
			and (@dtSaleDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@dtSaleDate <= TM_DateSellEnd or TM_DateSellEnd is null)
			and tm_svkey = 0)
		)and ts_tokey = @nPriceTourKey

		update [dbo].tp_turdates with(rowlock) set td_checkmargin = 1 where
			exists(select 1 from TurMargin with(nolock) WHERE TM_TlKey = @TrKey
			and TD_DATE Between TM_DateBeg and TM_DateEnd
			and (@dtSaleDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@dtSaleDate <= TM_DateSellEnd or TM_DateSellEnd is null)
		)and td_tokey = @nPriceTourKey
		----------------------------------------------------------- Здесь апдейтим TS_CHECKMARGIN и TD_CHECKMARGIN
		
		print 'Инициализация расчета цен: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		declare @tempTO_Rate nvarchar(3), @tempTO_TRKey int
		
		select @tempTO_Rate = TO_Rate, @tempTO_TRKey = TO_TRKey from tp_tours with(nolock) where TO_Key = @nPriceTourKey
		
		create table #CursorTable
		( 
			id int identity(1,1) primary key,
			ti_firsthdkey int, 
			ts_key int, 
			ti_key int, 
			td_date datetime, 
			ts_svkey int, 
			ts_code int, 
			ts_subcode1 int, 
			ts_subcode2 int, 
			ts_oppartnerkey int, 
			ts_oppacketkey int, 
			ts_day int, 
			ts_days int,
			tempTO_Rate varchar(3), 
			to_rate varchar(3), 
			ts_men int, 
			ts_tempgross float, 
			ts_checkmargin smallint, 
			td_checkmargin smallint, 
			ti_days int, 
			ts_ctkey int, 
			ts_attribute int,
			tiCtKeyFrom int,
			sv_IsDuration smallint,
			ti_totaldays int
		)
		
	  insert into #CursorTable (ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, tempTO_Rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_days, ts_ctkey, ts_attribute, tiCtKeyFrom, sv_IsDuration, ti_totaldays)
	  select ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, @tempTO_Rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_days, ts_ctkey, ts_attribute, (select TL_CTDepartureKey from tbl_TurList with(nolock) where @tempTO_TRKey = TL_KEY), SV_IsDuration, ti_totaldays
	  from tp_services with(nolock), tp_lists with(nolock), tp_servicelists with(nolock), tp_turdates with(nolock), [Service] with(nolock)
			where @nPriceTourKey = ts_tokey and @nPriceTourKey = ti_tokey and @nPriceTourKey = tl_tokey and ts_key = tl_tskey and ti_key = tl_tikey and @nPriceTourKey = td_tokey
				and ti_update = @nUpdate and td_update = @nUpdate and (@nUseHolidayRule = 0 or (case cast(datepart(weekday, td_date) as int) when 7 then 0 else cast(datepart(weekday, td_date) as int) end + ti_days) >= 8)
				and ts_svkey = SV_KEY
			order by ti_firsthdkey, td_date, ti_key, case when ti_firsthdkey = ts_code and TS_SVKey = 3 then 0 else 1 end
			
		update #CursorTable
		set ts_code = TF_CodeNew, ts_subcode1 = TF_SubCode1New, ts_oppartnerkey = TF_PRKeyNew
		from TP_Flights 
		where TF_TOKey = @nPriceTourKey
			and TF_CodeOld = ts_code 
			and TF_CalculatingKey = @nCalculatingKey
			and TF_PRKeyOld = ts_oppartnerkey 
			and TF_Date = td_date + ts_day - 1
			and TF_Days = ti_days
			and TF_Subcode1 = ts_subcode1
			and TF_SubCode2 = ts_subcode2
			and ts_svkey = 1
			
		-- формирование темповых таблиц на основе данных по туру
		create table #ServiceComponents
		(
			xSC_ID int identity(-10,-1) primary key,
			xSC_ID_InDB int,
			xSC_SVKEY int,
			xSC_CODE int,
			xSC_SUBCODE1 int,
			xSC_SUBCODE2 int,
			xSC_PRKEY int
		)
		SET IDENTITY_INSERT #ServiceComponents ON;
		
		insert into #ServiceComponents (xsc_id, xsc_svkey, xsc_code, xsc_subcode1, xsc_subcode2, xsc_prkey)
		select sc_id, sc_svkey, sc_code, sc_subcode1, sc_subcode2, sc_prkey 
		from TP_ServiceComponents with(nolock)
		where exists(select top 1 1 
					 from #CursorTable
					 where SC_SVKey = ts_svkey 
					 and SC_Code = ts_code 
					 and SC_SubCode1 = ts_subcode1 
					 and SC_SubCode2 = ts_subcode2 
					 and SC_PRKey = ts_oppartnerkey)
						 
		SET IDENTITY_INSERT #ServiceComponents OFF;

		CREATE INDEX IX_addServiceComponents ON #ServiceComponents
		(
			xSC_SVKEY, 
			xSC_CODE, 
			xSC_SUBCODE1, 
			xSC_SUBCODE2, 
			xSC_PRKEY
		)
		INCLUDE (xSC_ID);
			
		create table #ServiceCalculateParametrs
		(
			xSCP_Id int identity(-10,-1) primary key,
			xSCP_Id_InDB int,
			xSCP_SCId int,
			xscp_SVKEY int,
			xSCP_Date datetime,
			xSCP_DateCheckIn datetime,
			xSCP_Men int,
			xSCP_Days int,
			xSCP_PKKey int,
			xSCP_TourDays int,
			xSCP_DeleteDate datetime
		)
		SET IDENTITY_INSERT #ServiceCalculateParametrs ON;
		
		insert into #ServiceCalculateParametrs (xscp_id, xscp_scid, xscp_svkey, xscp_date, xscp_datecheckin, xscp_men, xscp_days, xscp_pkkey, xscp_tourdays)
		select SCP_Id, SCP_SCId, SCP_SvKey, SCP_Date, SCP_DateCheckIn, SCP_Men, SCP_Days, SCP_PKKey, SCP_TourDays 
		from TP_ServiceCalculateParametrs with(nolock)
		where exists(select 1
					 from #CursorTable
					 where SCP_SvKey = ts_svkey
					 and SCP_Date = dateAdd(dd, ts_day-1, td_date)
					 and SCP_DateCheckIn = td_date
					 and SCP_Men = ts_men
					 and SCP_Days = ts_days
					 and SCP_PKKey = ts_oppacketkey
					 and SCP_TourDays = ti_totaldays)
		and SCP_SCId in (select xsc_id from #ServiceComponents)
		
		SET IDENTITY_INSERT #ServiceCalculateParametrs OFF;

		CREATE INDEX IX_addServiceCalculateParametrs ON #ServiceCalculateParametrs
		(
			[xSCP_SCId] ASC,
			[xSCP_Date] ASC,
			[xSCP_DateCheckIn] ASC,
			[xSCP_Men] ASC,
			[xSCP_Days] ASC,
			[xSCP_TourDays] ASC,
			[xSCP_PKKey] ASC,
			[xSCP_DeleteDate] ASC,
			[xSCP_Id] ASC
		);
		
		create table #ServiceTours
		(
			xST_ID int identity(-10,-1)  primary key,
			xST_SCID int,
			xST_TOKEY int,
			xST_TRKEY int,
			xST_SVKEY int
		)
		
		SET IDENTITY_INSERT #ServiceTours ON;
		
		insert into #ServiceTours (xst_id, xst_scid, xst_tokey, xst_trkey, xst_svkey)
		select st_id, st_scid, st_tokey, st_trkey, st_svkey 
		from TP_ServiceTours with(nolock)
		where st_tokey = @nPriceTourKey
			and st_scid in (select xsc_id from #ServiceComponents)
			
		SET IDENTITY_INSERT #ServiceTours OFF;

		CREATE INDEX IX_addServiceTours ON #ServiceTours
		(
			xST_SVKEY, 
			xST_SCID, 
			xST_TOKEY, 
			xST_TRKEY
		)
		
		create table #TourParametrs
		(
			xTP_ID int identity(-10,-1) primary key,
			xTP_TOKey int,
			xTP_TourDays int,
			xTP_DateCheckIn datetime
		)
		
		SET IDENTITY_INSERT #TourParametrs ON;
				
		insert into #TourParametrs (xtp_id, xtp_tokey, xtp_tourdays, xtp_datecheckin)
		select tp_id, tp_tokey, tp_tourdays, tp_datecheckin  
		from TP_TourParametrs with(nolock)
		where tp_datecheckin in (select td_date 
								 from TP_TurDates with(nolock)
								 where td_calculatingkey = @nCalculatingKey)
				and tp_tokey = @nPriceTourKey
		
		SET IDENTITY_INSERT #TourParametrs OFF;

		CREATE INDEX IX_addServiceTours ON #TourParametrs
		(
			xTP_TOKey, 
			xTP_TourDays, 
			xTP_DateCheckIn
		)
		
		create table #ServicePriceActualDate
		(
			xSPAD_Id int identity (-10,-1) primary key,
			xSPAD_SCPId int,
			xSPAD_IsCommission bit,
			xSPAD_Rate varchar(3),
			xSPAD_SaleDate datetime,
			xSPAD_Gross money,
			xspad_Netto money,
			xspad_DateLastChange datetime,
			xspad_DateLastCalculate datetime,
			xSPAD_NeedApply int,
			xspad_AutoOnline int default 0
		)
		
		SET IDENTITY_INSERT #ServicePriceActualDate ON;
		
		insert into #ServicePriceActualDate (xSPAD_Id, xSPAD_SCPId, xSPAD_IsCommission, xSPAD_Rate, xSPAD_SaleDate, xSPAD_Gross, xspad_Netto, xspad_DateLastChange, xspad_DateLastCalculate, xSPAD_NeedApply, xspad_AutoOnline)
		select SPAD_Id, SPAD_SCPId, SPAD_IsCommission, SPAD_Rate, SPAD_SaleDate, SPAD_Gross,spad_Netto, spad_DateLastChange, spad_DateLastCalculate, SPAD_NeedApply, spad_AutoOnline
		from TP_ServicePriceActualDate with(nolock)
		where 
		SPAD_SaleDate is null 
		and SPAD_SCPId in (select xSCP_ID 
							 from #ServiceCalculateParametrs)
					  
		SET IDENTITY_INSERT #ServicePriceActualDate OFF;

		CREATE INDEX IX_INDEX2 ON #ServicePriceActualDate(xSPAD_SCPId, xSPAD_SaleDate, xSPAD_Rate, xSPAD_NeedApply)
		include (xSPAD_Gross, xSPAD_IsCommission)
		
		create table #GetServiceCost
		(
			id int not null identity(1,1) primary key,
			svKey int,
			code int,
			code1 int,
			code2 int,
			prKey int,
			packetKey int,
			tempdate datetime,
			tempdays int,
			resRate varchar(2),
			men int,
			discountPercent decimal(14,2),
			margin int,
			marginType decimal(14,2),
			sellDate datetime,
			tourKey int,
			tourDate datetime,
			tourDays int,
			netto decimal(14,2),
			brutto money, 
			nSPId int,
			discount decimal(14,2)
		)
		
		CREATE INDEX IX_INDEX1 ON #GetServiceCost(svKey, code, code1, code2, prKey, packetKey, tempdate, tempdays, resRate, men, discountPercent, margin, marginType, sellDate, tourDate, tourDays)
		include (netto, brutto, nSPId, discount)
		
		declare serviceCursor cursor local fast_forward for
		select ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, @tempTO_Rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_days, ts_ctkey, ts_attribute,tiCtKeyFrom, sv_IsDuration, ti_totaldays
		from #CursorTable

		open serviceCursor
		
			
		SELECT @round = ST_RoundService FROM Setting
		--MEG00036108 увеличил значение
		set @nProgressSkipLimit = 10000
		set @nProgressSkipCounter = 0

		declare @calcPricesCount int, @calcPriceListCount int, @calcTurDates int, @oldPriceKeyCurrent int
		select @calcPriceListCount = COUNT(1) from TP_Lists with(nolock) where TI_TOKey = @nPriceTourKey and TI_UPDATE = @nUpdate
		select @calcTurDates = COUNT(1) from TP_TurDates with(nolock) where TD_TOKey = @nPriceTourKey and TD_UPDATE = @nUpdate
		select @calcPricesCount = @calcPriceListCount * @calcTurDates
		set @NumPrices = @calcPricesCount
		
		if @NumPrices <> 0
			set @nDeltaProgress = (97.0 - 5) / @NumPrices
		else
			set @nDeltaProgress = 97.0 - 5

		set @dtPrevDate = '1899-12-31'
		set @nPrevVariant = -1
		set @nPrevGross = -1
		set @nPrevGrossDate = '1899-12-31'
		set @prevHdKey = -1

		TRUNCATE TABLE #TP_Prices
		
		declare @IsDuration smallint
		declare @tiCtKeyFrom int, @tiDays int, @titotaldays int
		declare @tsKey_1 int, @tsKey_2 int, @tsKey_3 int, @tsKey_4 int, @tsKey_5 int, @tsKey_6 int, @tsKey_7 int, @tsKey_8 int, @tsKey_9 int, @tsKey_10 int, @tsKey_11 int, @tsKey_12 int, @tsKey_13 int, @tsKey_14 int, @tsKey_15 int
		declare @tsSVKey_1 int, @tsSVKey_2 int, @tsSVKey_3 int, @tsSVKey_4 int, @tsSVKey_5 int, @tsSVKey_6 int, @tsSVKey_7 int, @tsSVKey_8 int, @tsSVKey_9 int, @tsSVKey_10 int, @tsSVKey_11 int, @tsSVKey_12 int, @tsSVKey_13 int, @tsSVKey_14 int, @tsSVKey_15 int
		declare @tsGross_1 money, @tsGross_2 money, @tsGross_3 money, @tsGross_4 money, @tsGross_5 money, @tsGross_6 money, @tsGross_7 money, @tsGross_8 money, @tsGross_9 money, @tsGross_10 money, @tsGross_11 money, @tsGross_12 money, @tsGross_13 money, @tsGross_14 money, @tsGross_15 money
		declare @tsAddIsCommission_1 money, @tsAddIsCommission_2 money, @tsAddIsCommission_3 money, @tsAddIsCommission_4 money, @tsAddIsCommission_5 money, @tsAddIsCommission_6 money, @tsAddIsCommission_7 money, @tsAddIsCommission_8 money, @tsAddIsCommission_9 money, @tsAddIsCommission_10 money, @tsAddIsCommission_11 money, @tsAddIsCommission_12 money, @tsAddIsCommission_13 money, @tsAddIsCommission_14 money, @tsAddIsCommission_15 money
		declare @tsAddNoCommission_1 money, @tsAddNoCommission_2 money, @tsAddNoCommission_3 money, @tsAddNoCommission_4 money, @tsAddNoCommission_5 money, @tsAddNoCommission_6 money, @tsAddNoCommission_7 money, @tsAddNoCommission_8 money, @tsAddNoCommission_9 money, @tsAddNoCommission_10 money, @tsAddNoCommission_11 money, @tsAddNoCommission_12 money, @tsAddNoCommission_13 money, @tsAddNoCommission_14 money, @tsAddNoCommission_15 money
		declare @tsMarginPercent_1 money, @tsMarginPercent_2 money, @tsMarginPercent_3 money, @tsMarginPercent_4 money, @tsMarginPercent_5 money, @tsMarginPercent_6 money, @tsMarginPercent_7 money, @tsMarginPercent_8 money, @tsMarginPercent_9 money, @tsMarginPercent_10 money, @tsMarginPercent_11 money, @tsMarginPercent_12 money, @tsMarginPercent_13 money, @tsMarginPercent_14 money, @tsMarginPercent_15 money
		declare @tsCommissionOnly_1 money, @tsCommissionOnly_2 money, @tsCommissionOnly_3 money, @tsCommissionOnly_4 money, @tsCommissionOnly_5 money, @tsCommissionOnly_6 money, @tsCommissionOnly_7 money, @tsCommissionOnly_8 money, @tsCommissionOnly_9 money, @tsCommissionOnly_10 money, @tsCommissionOnly_11 money, @tsCommissionOnly_12 money, @tsCommissionOnly_13 money, @tsCommissionOnly_14 money, @tsCommissionOnly_15 money
		declare @tsIsCommission_1 bit, @tsIsCommission_2 bit, @tsIsCommission_3 bit, @tsIsCommission_4 bit, @tsIsCommission_5 bit, @tsIsCommission_6 bit, @tsIsCommission_7 bit, @tsIsCommission_8 bit, @tsIsCommission_9 bit, @tsIsCommission_10 bit, @tsIsCommission_11 bit, @tsIsCommission_12 bit, @tsIsCommission_13 bit, @tsIsCommission_14 bit, @tsIsCommission_15 bit

		fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_DAYS, @TS_CTKEY, @TS_ATTRIBUTE, @tiCtKeyFrom, @IsDuration, @titotaldays
		
		set @fetchStatus = @@fetch_status	
			
		print 'Расчет цен 0: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		While (@fetchStatus = 0)
		BEGIN
			--данных не нашлось, выходим
			if @@fetch_status <> 0 and @nPrevVariant = -1
				break
				
		--очищаем переменные, записываем данные в таблицу #TP_Prices
			if @nPrevVariant <> @variant or @dtPrevDate <> @turdate or @@fetch_status <> 0
			BEGIN				
				--записываем данные в таблицу #TP_Prices
				if @nPrevVariant <> -1
				begin
					if exists(select 1 from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant)
					begin
						--select @nCalculatingKey
						update #TP_Prices set xtp_calculatingkey = @nCalculatingKey where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant and xtp_gross <> @price_brutto
						
					end
					else if (@isPriceListPluginRecalculation = 0)
					begin
						--select @nCalculatingKey
						insert into #TP_Prices (xtp_tokey, xtp_datebegin, xtp_dateend, xtp_tikey, xTP_CalculatingKey, xTP_Days, xTP_Rate, xTP_HotelKey, xTP_DepartureKey
						, xSCPId_1, xSCPId_2, xSCPId_3, xSCPId_4, xSCPId_5, xSCPId_6, xSCPId_7, xSCPId_8, xSCPId_9, xSCPId_10, xSCPId_11, xSCPId_12, xSCPId_13, xSCPId_14, xSCPId_15
						, xSvKey_1, xSvKey_2, xSvKey_3, xSvKey_4, xSvKey_5, xSvKey_6, xSvKey_7, xSvKey_8, xSvKey_9, xSvKey_10, xSvKey_11, xSvKey_12, xSvKey_13, xSvKey_14, xSvKey_15
						, xGross_1, xGross_2, xGross_3, xGross_4, xGross_5, xGross_6, xGross_7, xGross_8, xGross_9, xGross_10, xGross_11, xGross_12, xGross_13, xGross_14, xGross_15
						, xAddCostIsCommission_1, xAddCostIsCommission_2, xAddCostIsCommission_3, xAddCostIsCommission_4, xAddCostIsCommission_5, xAddCostIsCommission_6, xAddCostIsCommission_7, xAddCostIsCommission_8, xAddCostIsCommission_9, xAddCostIsCommission_10, xAddCostIsCommission_11, xAddCostIsCommission_12, xAddCostIsCommission_13, xAddCostIsCommission_14, xAddCostIsCommission_15
						, xAddCostNoCommission_1, xAddCostNoCommission_2, xAddCostNoCommission_3, xAddCostNoCommission_4, xAddCostNoCommission_5, xAddCostNoCommission_6, xAddCostNoCommission_7, xAddCostNoCommission_8, xAddCostNoCommission_9, xAddCostNoCommission_10, xAddCostNoCommission_11, xAddCostNoCommission_12, xAddCostNoCommission_13, xAddCostNoCommission_14, xAddCostNoCommission_15
						, xMarginPercent_1, xMarginPercent_2, xMarginPercent_3, xMarginPercent_4, xMarginPercent_5, xMarginPercent_6, xMarginPercent_7, xMarginPercent_8, xMarginPercent_9, xMarginPercent_10, xMarginPercent_11, xMarginPercent_12, xMarginPercent_13, xMarginPercent_14, xMarginPercent_15
						, xCommissionOnly_1, xCommissionOnly_2, xCommissionOnly_3, xCommissionOnly_4, xCommissionOnly_5, xCommissionOnly_6, xCommissionOnly_7, xCommissionOnly_8, xCommissionOnly_9, xCommissionOnly_10, xCommissionOnly_11, xCommissionOnly_12, xCommissionOnly_13, xCommissionOnly_14, xCommissionOnly_15
						, xIsCommission_1, xIsCommission_2, xIsCommission_3, xIsCommission_4, xIsCommission_5, xIsCommission_6, xIsCommission_7, xIsCommission_8, xIsCommission_9, xIsCommission_10, xIsCommission_11, xIsCommission_12, xIsCommission_13, xIsCommission_14, xIsCommission_15)
						values (@nPriceTourKey, @dtPrevDate, @dtPrevDate, @nPrevVariant, @nCalculatingKey, @tiDays, @sRate, @hdKey, @tiCtKeyFrom
						, @tsKey_1, @tsKey_2, @tsKey_3, @tsKey_4, @tsKey_5, @tsKey_6, @tsKey_7, @tsKey_8, @tsKey_9, @tsKey_10, @tsKey_11, @tsKey_12, @tsKey_13, @tsKey_14, @tsKey_15
						, @tsSVKey_1, @tsSVKey_2, @tsSVKey_3, @tsSVKey_4, @tsSVKey_5, @tsSVKey_6, @tsSVKey_7, @tsSVKey_8, @tsSVKey_9, @tsSVKey_10, @tsSVKey_11, @tsSVKey_12, @tsSVKey_13, @tsSVKey_14, @tsSVKey_15
						, @tsGross_1, @tsGross_2, @tsGross_3, @tsGross_4, @tsGross_5, @tsGross_6, @tsGross_7, @tsGross_8, @tsGross_9, @tsGross_10, @tsGross_11, @tsGross_12, @tsGross_13, @tsGross_14, @tsGross_15
						, @tsAddIsCommission_1, @tsAddIsCommission_2, @tsAddIsCommission_3, @tsAddIsCommission_4, @tsAddIsCommission_5, @tsAddIsCommission_6, @tsAddIsCommission_7, @tsAddIsCommission_8, @tsAddIsCommission_9, @tsAddIsCommission_10, @tsAddIsCommission_11, @tsAddIsCommission_12, @tsAddIsCommission_13, @tsAddIsCommission_14, @tsAddIsCommission_15
						, @tsAddNoCommission_1, @tsAddNoCommission_2, @tsAddNoCommission_3, @tsAddNoCommission_4, @tsAddNoCommission_5, @tsAddNoCommission_6, @tsAddNoCommission_7, @tsAddNoCommission_8, @tsAddNoCommission_9, @tsAddNoCommission_10, @tsAddNoCommission_11, @tsAddNoCommission_12, @tsAddNoCommission_13, @tsAddNoCommission_14, @tsAddNoCommission_15
						, @tsMarginPercent_1, @tsMarginPercent_2, @tsMarginPercent_3, @tsMarginPercent_4, @tsMarginPercent_5, @tsMarginPercent_6, @tsMarginPercent_7, @tsMarginPercent_8, @tsMarginPercent_9, @tsMarginPercent_10, @tsMarginPercent_11, @tsMarginPercent_12, @tsMarginPercent_13, @tsMarginPercent_14, @tsMarginPercent_15
						, @tsCommissionOnly_1, @tsCommissionOnly_2, @tsCommissionOnly_3, @tsCommissionOnly_4, @tsCommissionOnly_5, @tsCommissionOnly_6, @tsCommissionOnly_7, @tsCommissionOnly_8, @tsCommissionOnly_9, @tsCommissionOnly_10, @tsCommissionOnly_11, @tsCommissionOnly_12, @tsCommissionOnly_13, @tsCommissionOnly_14, @tsCommissionOnly_15
						, @tsIsCommission_1, @tsIsCommission_2, @tsIsCommission_3, @tsIsCommission_4, @tsIsCommission_5, @tsIsCommission_6, @tsIsCommission_7, @tsIsCommission_8, @tsIsCommission_9, @tsIsCommission_10, @tsIsCommission_11, @tsIsCommission_12, @tsIsCommission_13, @tsIsCommission_14, @tsIsCommission_15)
												
						set @tiDays = null
						
						set @tsKey_1 = null
						set @tsKey_2 = null
						set @tsKey_3 = null
						set @tsKey_4 = null
						set @tsKey_5 = null
						set @tsKey_6 = null
						set @tsKey_7 = null
						set @tsKey_8 = null
						set @tsKey_9 = null
						set @tsKey_10 = null
						set @tsKey_11 = null
						set @tsKey_12 = null
						set @tsKey_13 = null
						set @tsKey_14 = null
						set @tsKey_15 = null
						
						set @tsSVKey_1 = null
						set @tsSVKey_2 = null
						set @tsSVKey_3 = null
						set @tsSVKey_4 = null
						set @tsSVKey_5 = null
						set @tsSVKey_6 = null
						set @tsSVKey_7 = null
						set @tsSVKey_8 = null
						set @tsSVKey_9 = null
						set @tsSVKey_10 = null
						set @tsSVKey_11 = null
						set @tsSVKey_12 = null
						set @tsSVKey_13 = null
						set @tsSVKey_14 = null
						set @tsSVKey_15 = null
						
						set @tsGross_1 = null
						set @tsGross_2 = null
						set @tsGross_3 = null
						set @tsGross_4 = null
						set @tsGross_5 = null
						set @tsGross_6 = null
						set @tsGross_7 = null
						set @tsGross_8 = null
						set @tsGross_9 = null
						set @tsGross_10 = null
						set @tsGross_11 = null
						set @tsGross_12 = null
						set @tsGross_13 = null
						set @tsGross_14 = null
						set @tsGross_15 = null
						
						set @tsAddIsCommission_1 = null
						set @tsAddIsCommission_2 = null
						set @tsAddIsCommission_3 = null
						set @tsAddIsCommission_4 = null
						set @tsAddIsCommission_5 = null
						set @tsAddIsCommission_6 = null
						set @tsAddIsCommission_7 = null
						set @tsAddIsCommission_8 = null
						set @tsAddIsCommission_9 = null
						set @tsAddIsCommission_10 = null
						set @tsAddIsCommission_11 = null
						set @tsAddIsCommission_12 = null
						set @tsAddIsCommission_13 = null
						set @tsAddIsCommission_14 = null
						set @tsAddIsCommission_15 = null
						
						set @tsAddNoCommission_1 = null
						set @tsAddNoCommission_2 = null
						set @tsAddNoCommission_3 = null
						set @tsAddNoCommission_4 = null
						set @tsAddNoCommission_5 = null
						set @tsAddNoCommission_6 = null
						set @tsAddNoCommission_7 = null
						set @tsAddNoCommission_8 = null
						set @tsAddNoCommission_9 = null
						set @tsAddNoCommission_10 = null
						set @tsAddNoCommission_11 = null
						set @tsAddNoCommission_12 = null
						set @tsAddNoCommission_13 = null
						set @tsAddNoCommission_14 = null
						set @tsAddNoCommission_15 = null
						
						set @tsMarginPercent_1 = null
						set @tsMarginPercent_2 = null
						set @tsMarginPercent_3 = null
						set @tsMarginPercent_4 = null
						set @tsMarginPercent_5 = null
						set @tsMarginPercent_6 = null
						set @tsMarginPercent_7 = null
						set @tsMarginPercent_8 = null
						set @tsMarginPercent_9 = null
						set @tsMarginPercent_10 = null
						set @tsMarginPercent_11 = null
						set @tsMarginPercent_12 = null
						set @tsMarginPercent_13 = null
						set @tsMarginPercent_14 = null
						set @tsMarginPercent_15 = null
						
						set @tsCommissionOnly_1 = null
						set @tsCommissionOnly_2 = null
						set @tsCommissionOnly_3 = null
						set @tsCommissionOnly_4 = null
						set @tsCommissionOnly_5 = null
						set @tsCommissionOnly_6 = null
						set @tsCommissionOnly_7 = null
						set @tsCommissionOnly_8 = null
						set @tsCommissionOnly_9 = null
						set @tsCommissionOnly_10 = null
						set @tsCommissionOnly_11 = null
						set @tsCommissionOnly_12 = null
						set @tsCommissionOnly_13 = null
						set @tsCommissionOnly_14 = null
						set @tsCommissionOnly_15 = null
						
						set @tsIsCommission_1 = null
						set @tsIsCommission_2 = null
						set @tsIsCommission_3 = null
						set @tsIsCommission_4 = null
						set @tsIsCommission_5 = null
						set @tsIsCommission_6 = null
						set @tsIsCommission_7 = null
						set @tsIsCommission_8 = null
						set @tsIsCommission_9 = null
						set @tsIsCommission_10 = null
						set @tsIsCommission_11 = null
						set @tsIsCommission_12 = null
						set @tsIsCommission_13 = null
						set @tsIsCommission_14 = null
						set @tsIsCommission_15 = null
					end
				end
				
				--очищаем данные
				if @@fetch_status = 0
				begin	
					set @price_brutto = 0
					set @nPrevVariant = @variant
					set @dtPrevDate = @turdate
				end
				
				set @nTotalProgress = @nTotalProgress + @nDeltaProgress
				if @nProgressSkipCounter = @nProgressSkipLimit
				BEGIN
					update tp_tours with(rowlock) set to_progress = @nTotalProgress, to_updatetime = GetDate() where to_key = @nPriceTourKey
					set @nProgressSkipCounter = 0
				END
				else
					set @nProgressSkipCounter = @nProgressSkipCounter + 1
			END

			--переписываем данные в таблицу tp_prices
			if @hdKey <> @prevHdKey or @@fetch_status <> 0
			begin
				set @prevHdKey = @hdKey
			end
			
				if @@fetch_status <> 0
					break	
										
				declare @margin float, @marginType int, @addCostValueIsCommission money, @addCostValueNoCommission money
				declare @scId int -- ключ найденой записи в таблице TP_ServiceComponents
				declare @scpId int -- ключ найденой записи в таблице TP_ServiceCalculateParametrs
				declare @spadId  int -- ключ найденой записи в тиблице TP_ServiePriceActualDate
				
				---- gorshkov поднял дату сюда т.к. она нужна при замене дефолтного перелета на подобранный
				set @servicedate = dateAdd(dd, @nDay-1, @turdate)
				
				---- gorshkov проверка на то что данную услугу вообще нужно расчитывать
				if @TS_ATTRIBUTE & @SERV_NOTCALCULATE = @SERV_NOTCALCULATE
				begin
					set @nNetto = 0
					set @nBrutto = 0
					set @nDiscount = 0
					set @nPDID = 0
					
				end
				else
				begin
					 --если есть ключ услуги то расчитываем, иначе проставляем null
					if (@nCode is not null)
					begin					
						set @tiDays = @TI_DAYS
						
						/*создадим структуру таблиц если ее нету*/
						exec ReCalculate_CreateServiceCalculateParametrs @TrKey, @nPriceTourKey, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nDay, @turdate, @nMen, @nDays, @nPacketkey, @titotaldays, @scId output, @scpId output
						declare @gross money, @addCostIsCommission money, @addCostNoCommission money, @addCostFromAdult money, @addCostFromChild money, @marginPercent money, @CommissionOnly bit, @isCommission bit, @tourRate varchar(2)
						
						/*Производим расчет стоимости услуги*/
						exec ReCalculateCosts_CalculatePriceList @scpId, @nBrutto output, @isCommission output, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @servicedate, @nDays, @sRate, @nMen, 0, @nMargin, @nMarginType, null, @nNetto, @nDiscount, @sDetailed, @sBadRate, @dtBadDate, @sDetailed, @nSPId, @TrKey, @turdate, @TI_DAYS, @IsDuration
						
						 --проверям считать ли null цены = 0					
						if @nNullCostAsZero = 1 and @nBrutto is null and @nSvkey not in (1,3)
							set @nBrutto = 0
						if @nNullCostAsZero = 1 and @nBrutto is null and @nSvkey = 1 and @nNoFlight = 0
							set @nBrutto = 0
						set @gross = @nBrutto
		
						/*Производим расчет наценки*/
						--промежуточная хранимка для работы с кэшем (TP_TourMarginActualDate)
						exec ReCalculateMargins_CalculatePriceList @TrKey, @nPriceTourKey, @turdate, @margin output, @marginType output, @nSvkey, @TI_DAYS, @dtSaleDate, @nPacketkey
						set @marginPercent = @margin
						set @CommissionOnly = @marginType
						
						/*Производим расчет доплаты*/
						exec GetServiceAddCosts @TrKey, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @turdate, @TI_DAYS, @nDays, @nMen, null, null, @addCostValueIsCommission output, @addCostValueNoCommission output, @addCostFromAdult output, @addCostFromChild output, @tourRate output
						set @addCostIsCommission = @addCostValueIsCommission
						set @addCostNoCommission = @addCostValueNoCommission
					end
					else
					begin
						set @gross = null
						set @addCostIsCommission = null
						set @addCostNoCommission = null
						set @marginPercent = null
						set @CommissionOnly = null
						set @isCommission = null
					end
					
					-- запишем ключи TS_Key в таблицу (получим список услуг из которых состоит TP_Prices)
					if (@tsKey_1 is null)
					begin
						set @tsKey_1 = @scpId
						set @tsSVKey_1 = @nSvkey
						set @tsGross_1 = @gross
						set @tsAddIsCommission_1 = @addCostIsCommission
						set @tsAddNoCommission_1 = @addCostNoCommission
						set @tsMarginPercent_1 = @marginPercent
						set @tsCommissionOnly_1 = @CommissionOnly
						set @tsIsCommission_1 = @isCommission
					end
					else if (@tsKey_2 is null)
					begin
						set @tsKey_2 = @scpId
						set @tsSVKey_2 = @nSvkey
						set @tsGross_2 = @gross
						set @tsAddIsCommission_2 = @addCostIsCommission
						set @tsAddNoCommission_2 = @addCostNoCommission
						set @tsMarginPercent_2 = @marginPercent
						set @tsCommissionOnly_2 = @CommissionOnly
						set @tsIsCommission_2 = @isCommission
					end
					else if (@tsKey_3 is null)
					begin
						set @tsKey_3 = @scpId
						set @tsSVKey_3 = @nSvkey
						set @tsGross_3 = @gross
						set @tsAddIsCommission_3 = @addCostIsCommission
						set @tsAddNoCommission_3 = @addCostNoCommission
						set @tsMarginPercent_3 = @marginPercent
						set @tsCommissionOnly_3 = @CommissionOnly
						set @tsIsCommission_3 = @isCommission
					end
					else if (@tsKey_4 is null)
					begin
						set @tsKey_4 = @scpId
						set @tsSVKey_4 = @nSvkey
						set @tsGross_4 = @gross
						set @tsAddIsCommission_4 = @addCostIsCommission
						set @tsAddNoCommission_4 = @addCostNoCommission
						set @tsMarginPercent_4 = @marginPercent
						set @tsCommissionOnly_4 = @CommissionOnly
						set @tsIsCommission_4 = @isCommission
					end
					else if (@tsKey_5 is null)
					begin
						set @tsKey_5 = @scpId
						set @tsSVKey_5 = @nSvkey
						set @tsGross_5 = @gross
						set @tsAddIsCommission_5 = @addCostIsCommission
						set @tsAddNoCommission_5 = @addCostNoCommission
						set @tsMarginPercent_5 = @marginPercent
						set @tsCommissionOnly_5 = @CommissionOnly
						set @tsIsCommission_5 = @isCommission
					end
					else if (@tsKey_6 is null)
					begin
						set @tsKey_6 = @scpId
						set @tsSVKey_6 = @nSvkey
						set @tsGross_6 = @gross
						set @tsAddIsCommission_6 = @addCostIsCommission
						set @tsAddNoCommission_6 = @addCostNoCommission
						set @tsMarginPercent_6 = @marginPercent
						set @tsCommissionOnly_6 = @CommissionOnly
						set @tsIsCommission_6 = @isCommission
					end
					else if (@tsKey_7 is null)
					begin
						set @tsKey_7 = @scpId
						set @tsSVKey_7 = @nSvkey
						set @tsGross_7 = @gross
						set @tsAddIsCommission_7 = @addCostIsCommission
						set @tsAddNoCommission_7 = @addCostNoCommission
						set @tsMarginPercent_7 = @marginPercent
						set @tsCommissionOnly_7 = @CommissionOnly
						set @tsIsCommission_7 = @isCommission
					end
					else if (@tsKey_8 is null)
					begin
						set @tsKey_8 = @scpId
						set @tsSVKey_8 = @nSvkey
						set @tsGross_8 = @gross
						set @tsAddIsCommission_8 = @addCostIsCommission
						set @tsAddNoCommission_8 = @addCostNoCommission
						set @tsMarginPercent_8 = @marginPercent
						set @tsCommissionOnly_8 = @CommissionOnly
						set @tsIsCommission_8 = @isCommission
					end
					else if (@tsKey_9 is null)
					begin
						set @tsKey_9 = @scpId
						set @tsSVKey_9 = @nSvkey
						set @tsGross_9 = @gross
						set @tsAddIsCommission_9 = @addCostIsCommission
						set @tsAddNoCommission_9 = @addCostNoCommission
						set @tsMarginPercent_9 = @marginPercent
						set @tsCommissionOnly_9 = @CommissionOnly
						set @tsIsCommission_9 = @isCommission
					end
					else if (@tsKey_10 is null)
					begin
						set @tsKey_10 = @scpId
						set @tsSVKey_10 = @nSvkey
						set @tsGross_10 = @gross
						set @tsAddIsCommission_10 = @addCostIsCommission
						set @tsAddNoCommission_10 = @addCostNoCommission
						set @tsMarginPercent_10 = @marginPercent
						set @tsCommissionOnly_10 = @CommissionOnly
						set @tsIsCommission_10 = @isCommission
					end
					else if (@tsKey_11 is null)
					begin
						set @tsKey_11 = @scpId
						set @tsSVKey_11 = @nSvkey
						set @tsGross_11 = @gross
						set @tsAddIsCommission_11 = @addCostIsCommission
						set @tsAddNoCommission_11 = @addCostNoCommission
						set @tsMarginPercent_11 = @marginPercent
						set @tsCommissionOnly_11 = @CommissionOnly
						set @tsIsCommission_11 = @isCommission
					end
					else if (@tsKey_12 is null)
					begin
						set @tsKey_12 = @scpId
						set @tsSVKey_12 = @nSvkey
						set @tsGross_12 = @gross
						set @tsAddIsCommission_12 = @addCostIsCommission
						set @tsAddNoCommission_12 = @addCostNoCommission
						set @tsMarginPercent_12 = @marginPercent
						set @tsCommissionOnly_12 = @CommissionOnly
						set @tsIsCommission_12 = @isCommission
					end
					else if (@tsKey_13 is null)
					begin
						set @tsKey_13 = @scpId
						set @tsSVKey_13 = @nSvkey
						set @tsGross_13 = @gross
						set @tsAddIsCommission_13 = @addCostIsCommission
						set @tsAddNoCommission_13 = @addCostNoCommission
						set @tsMarginPercent_13 = @marginPercent
						set @tsCommissionOnly_13 = @CommissionOnly
						set @tsIsCommission_13 = @isCommission
					end
					else if (@tsKey_14 is null)
					begin
						set @tsKey_14 = @scpId
						set @tsSVKey_14 = @nSvkey
						set @tsGross_14 = @gross
						set @tsAddIsCommission_14 = @addCostIsCommission
						set @tsAddNoCommission_14 = @addCostNoCommission
						set @tsMarginPercent_14 = @marginPercent
						set @tsCommissionOnly_14 = @CommissionOnly
						set @tsIsCommission_14 = @isCommission
					end
					else if (@tsKey_15 is null)
					begin
						set @tsKey_15 = @scpId
						set @tsSVKey_15 = @nSvkey
						set @tsGross_15 = @gross
						set @tsAddIsCommission_15 = @addCostIsCommission
						set @tsAddNoCommission_15 = @addCostNoCommission
						set @tsMarginPercent_15 = @marginPercent
						set @tsCommissionOnly_15 = @CommissionOnly
						set @tsIsCommission_15 = @isCommission
					end

				end
		fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_DAYS, @TS_CTKEY, @TS_ATTRIBUTE, @tiCtKeyFrom, @IsDuration, @titotaldays
		END
		
		close serviceCursor
		deallocate serviceCursor

		Set @nTotalProgress = 97
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
		/* Заполнения основных таблиц, на основе темповых данных */

		declare @step int
		-- таблица сопоставления ключей ServiceComponents
		--если есть данные с отрицательными ключами - это новые данные, их надо добавить в основную таблицу
		if exists (select top 1 1 from #ServiceComponents where xsc_id < 0)
		begin
			insert into TP_ServiceComponents (sc_svkey, sc_code, sc_subcode1, sc_subcode2, sc_prkey)
			select xsc_svkey, xsc_code, xsc_subcode1, xsc_subcode2, xsc_prkey 
			from #ServiceComponents 
			where xsc_id < 0

			update #ServiceComponents
			set xSC_ID_InDB = sc_id
			from TP_ServiceComponents with(nolock)
			where 
			sc_svkey = xSC_SVKEY
			and sc_code = xSC_CODE
			and isnull(sc_subcode1,0) = isnull(xSC_SUBCODE1,0)
			and isnull(sc_subcode2,0) = isnull(xSC_SUBCODE2,0)
			and isnull(sc_prkey,0) = isnull(xSC_PRKEY,0) 			
			and xsc_id < 0
		end

		-- тут ничего не меняется колонка xSC_ID_InDB = xSC_ID
		update #ServiceComponents
		set xSC_ID_InDB = xSC_ID
		where xSC_ID > 0
		-------------------------------

		-- если есть данные с отрицательными ключами - это новые данные, их надо добавить в основную таблицу
		insert into TP_TourParametrs (tp_tokey, tp_tourdays, tp_datecheckin)
		select xtp_tokey, xtp_tourdays, xtp_datecheckin
		from #TourParametrs
		where xTP_ID < 0
		
		-- TP_ServiceTours
		insert into TP_ServiceTours (ST_SCId, ST_SVKey, ST_TOKey, ST_TRKey)
		select xSC_ID_InDB, xST_SVKey, xST_TOKey, xST_TRKey
		from #ServiceTours
		join #ServiceComponents on xSC_ID = xST_SCId
		where xST_ID < 0
		------------------

		-- TP_ServiceCalculateParametrs
		if exists (select top 1 1 from #ServiceCalculateParametrs where xSCP_Id < 0)
		begin
			insert into TP_ServiceCalculateParametrs (SCP_SCId, SCP_SvKey, SCP_Date, SCP_DateCheckIn, SCP_Men, SCP_Days, SCP_PKKey, SCP_TourDays)
			select xSC_ID_InDB, xSCP_SvKey, xSCP_Date, xSCP_DateCheckIn, xSCP_Men, xSCP_Days, xSCP_PKKey, xSCP_TourDays
			from #ServiceCalculateParametrs
			join #ServiceComponents on xSC_ID = xSCP_SCId
			where xSCP_Id < 0

			update #ServiceCalculateParametrs
			set xSCP_Id_InDB = scp_id
			from TP_ServiceCalculateParametrs with(nolock)
			join #ServiceComponents on scp_scid = xSC_ID_InDB
			where
			xSC_ID = xSCP_SCId
			and scp_date = xscp_date
			and scp_datecheckin = xscp_datecheckin
			and scp_men = xscp_men
			and scp_days = xscp_days
			and isnull(scp_tourdays,0) = isnull(xscp_tourdays,0)
			and scp_pkkey = xscp_pkkey
			and isnull(scp_deletedate, '19000101') = isnull(xscp_deletedate, '19000101')			
			and xSCP_Id < 0
		end

		update #ServiceCalculateParametrs
		set xSCP_Id_InDB = xSCP_Id
		where xSCP_Id > 0
		-------------------------------
		
		-- в таблице #TP_Prices для  новых (отрицательных) ST_SCPId происходит замена согласно таблице сопоставления ключей
		update #TP_Prices set xSCPId_1 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_1) where xSCPId_1 < 0
		update #TP_Prices set xSCPId_2 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_2) where xSCPId_2 < 0
		update #TP_Prices set xSCPId_3 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_3) where xSCPId_3 < 0
		update #TP_Prices set xSCPId_4 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_4) where xSCPId_4 < 0
		update #TP_Prices set xSCPId_5 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_5) where xSCPId_5 < 0
		update #TP_Prices set xSCPId_6 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_6) where xSCPId_6 < 0
		update #TP_Prices set xSCPId_7 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_7) where xSCPId_7 < 0
		update #TP_Prices set xSCPId_8 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_8) where xSCPId_8 < 0
		update #TP_Prices set xSCPId_9 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_9) where xSCPId_9 < 0
		update #TP_Prices set xSCPId_10 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_10) where xSCPId_10 < 0
		update #TP_Prices set xSCPId_11 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_11) where xSCPId_11 < 0
		update #TP_Prices set xSCPId_12 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_12) where xSCPId_12 < 0
		update #TP_Prices set xSCPId_13 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_13) where xSCPId_13 < 0
		update #TP_Prices set xSCPId_14 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_14) where xSCPId_14 < 0
		update #TP_Prices set xSCPId_15 = (select xSCP_Id_InDB from #ServiceCalculateParametrs where xSCP_Id = xSCPId_15) where xSCPId_15 < 0

		-- записи цен которые перерасчитались, обновляем из темповой таблицы 
		update TP_ServicePriceActualDate
		set SPAD_IsCommission = xSPAD_IsCommission,
			SPAD_Gross = xSPAD_Gross,			
			SPAD_Netto = xSPAD_Netto,
			SPAD_DateLastCalculate = xSPAD_DateLastCalculate,
			SPAD_NeedApply = ISNULL(xSPAD_NeedApply, 0)
		from #ServicePriceActualDate
		where xSPAD_Id = SPAD_Id 
		and xSPAD_Id > 0
		
		-- записи цен которых не было
		insert into TP_ServicePriceActualDate (SPAD_SCPId, SPAD_IsCommission, SPAD_Rate, SPAD_SaleDate, SPAD_Gross, spad_Netto, spad_DateLastChange, spad_DateLastCalculate, SPAD_NeedApply, spad_AutoOnline)
		select xSCP_Id_InDB, xSPAD_IsCommission, xSPAD_Rate, xSPAD_SaleDate, xSPAD_Gross, xspad_Netto, xspad_DateLastChange, xspad_DateLastCalculate, xSPAD_NeedApply, xspad_AutoOnline
		from #ServicePriceActualDate 
		join #ServiceCalculateParametrs on xSPAD_SCPId = xSCP_Id 
		where xSPAD_Id < 0 
		and xSPAD_NeedApply is not null
		
		print 'Расчет цен END: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()

		----------------------------------------------------- возвращаем обратно цены ------------------------------------------------------

		Set @nTotalProgress = 98
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
		--удаление из веба
		if (@nIsEnabled = 1)
		begin
			if (@isPriceListPluginRecalculation = 0)
				EXEC ClearMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
			else
				EXEC ClearMasterWebSearchFields @nPriceTourKey, null
		end
		
		-- запомним ключи цен которые потом нужно будет удалить из TP_PriceComponents
		declare @tpKeysForDelete table
		(
			xtp_key int
		)
		
		insert into @tpKeysForDelete
		select tp_key from tp_prices with(nolock)
		where tp_tokey = @nPriceTourKey and 
			tp_tikey in (select ti_key from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) and
			tp_DateBegin in (select td_date from TP_TurDates with(nolock) where td_tokey = @nPriceTourKey and TD_Update = @nUpdate)
		union
		select tpd_tpkey from dbo.TP_PricesDeleted with(nolock)
		where tpd_tokey = @nPriceTourKey and 
			tpd_tikey in (select ti_key from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) and
			tpd_DateBegin in (select td_date from TP_TurDates with(nolock) where td_tokey = @nPriceTourKey and TD_Update = @nUpdate)
		
		insert into TP_PricesCleaner(PC_TRKEY, PC_TOKEY, PC_TPKEY, PC_CalculatingKey)
		select @trKey, TP_TOKEY, TP_KEY, @nCalculatingKey from dbo.TP_Prices with(nolock)
		where TP_Key in (select xtp_key from @tpKeysForDelete)	

		delete from dbo.TP_Prices with(rowlock)
		where TP_Key in (select xtp_key from @tpKeysForDelete)	
		
		delete from dbo.TP_PricesDeleted with(rowlock)
		where TPD_TPKey in (select xtp_key from @tpKeysForDelete)	
		
		delete from dbo.TP_PriceComponents with(rowlock)
		where PC_TPKey in (select xtp_key from @tpKeysForDelete)	
		
		-- удалим цены которые не посчитались
		delete #TP_Prices
		where xTP_Gross is null
		
		--чтобы не было просадки в ключах
		select @PricesCount = count(1) from #TP_Prices
		exec GetNKeys 'TP_PRICES', @PricesCount, @nTP_PriceKeyMax output
		set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @PricesCount
			
		update #tp_prices 
		set xTP_Key = @nTP_PriceKeyCurrent, @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
		
		-- заносим детализацию по посчитанному туру
		declare @insertedTpKeys table(
			tpkey int not null
		)

		while (exists(select top 1 1 from #TP_Prices with(nolock)))
		begin
			insert into @insertedTpKeys
			select top 50000 xtp_key
			from #TP_Prices with(nolock)
		
			INSERT INTO TP_Prices (tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey)
			select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, CEILING(xTP_Gross), xTP_TIKey, xTP_CalculatingKey 
			from #TP_Prices with(nolock) where xtp_key in (select tpkey from  @insertedTpKeys)

			insert into TP_PriceComponents (PC_TIKey, PC_TOKey, PC_TRKey, PC_TourDate, PC_TPKey, PC_Days, PC_Rate, PC_HotelKey, PC_DepartureKey
			, SCPId_1, SCPId_2, SCPId_3, SCPId_4, SCPId_5, SCPId_6, SCPId_7, SCPId_8, SCPId_9, SCPId_10, SCPId_11, SCPId_12, SCPId_13, SCPId_14, SCPId_15
			, SVKey_1, SVKey_2, SVKey_3, SVKey_4, SVKey_5, SVKey_6, SVKey_7, SVKey_8, SVKey_9, SVKey_10, SVKey_11, SVKey_12, SVKey_13, SVKey_14, SVKey_15
			, Gross_1, Gross_2, Gross_3, Gross_4, Gross_5, Gross_6, Gross_7, Gross_8, Gross_9, Gross_10, Gross_11, Gross_12, Gross_13, Gross_14, Gross_15
			, AddCostIsCommission_1, AddCostIsCommission_2, AddCostIsCommission_3, AddCostIsCommission_4, AddCostIsCommission_5, AddCostIsCommission_6, AddCostIsCommission_7, AddCostIsCommission_8, AddCostIsCommission_9, AddCostIsCommission_10, AddCostIsCommission_11, AddCostIsCommission_12, AddCostIsCommission_13, AddCostIsCommission_14, AddCostIsCommission_15
			, AddCostNoCommission_1, AddCostNoCommission_2, AddCostNoCommission_3, AddCostNoCommission_4, AddCostNoCommission_5, AddCostNoCommission_6, AddCostNoCommission_7, AddCostNoCommission_8, AddCostNoCommission_9, AddCostNoCommission_10, AddCostNoCommission_11, AddCostNoCommission_12, AddCostNoCommission_13, AddCostNoCommission_14, AddCostNoCommission_15
			, MarginPercent_1, MarginPercent_2, MarginPercent_3, MarginPercent_4, MarginPercent_5, MarginPercent_6, MarginPercent_7, MarginPercent_8, MarginPercent_9, MarginPercent_10, MarginPercent_11, MarginPercent_12, MarginPercent_13, MarginPercent_14, MarginPercent_15
			, CommissionOnly_1, CommissionOnly_2, CommissionOnly_3, CommissionOnly_4, CommissionOnly_5, CommissionOnly_6, CommissionOnly_7, CommissionOnly_8, CommissionOnly_9, CommissionOnly_10, CommissionOnly_11, CommissionOnly_12, CommissionOnly_13, CommissionOnly_14, CommissionOnly_15
			, IsCommission_1, IsCommission_2, IsCommission_3, IsCommission_4, IsCommission_5, IsCommission_6, IsCommission_7, IsCommission_8, IsCommission_9, IsCommission_10, IsCommission_11, IsCommission_12, IsCommission_13, IsCommission_14, IsCommission_15)
			select xTP_TIKey, xtp_tokey, @TrKey, xtp_dateBegin, xtp_key, xTP_Days, xTP_Rate, xTP_HotelKey, xTP_DepartureKey
			, xSCPId_1, xSCPId_2, xSCPId_3, xSCPId_4, xSCPId_5, xSCPId_6, xSCPId_7, xSCPId_8, xSCPId_9, xSCPId_10, xSCPId_11, xSCPId_12, xSCPId_13, xSCPId_14, xSCPId_15
			, xSvKey_1, xSvKey_2, xSvKey_3, xSvKey_4, xSvKey_5, xSvKey_6, xSvKey_7, xSvKey_8, xSvKey_9, xSvKey_10, xSvKey_11, xSvKey_12, xSvKey_13, xSvKey_14, xSvKey_15
			, xGross_1, xGross_2, xGross_3, xGross_4, xGross_5, xGross_6, xGross_7, xGross_8, xGross_9, xGross_10, xGross_11, xGross_12, xGross_13, xGross_14, xGross_15
			, xAddCostIsCommission_1, xAddCostIsCommission_2, xAddCostIsCommission_3, xAddCostIsCommission_4, xAddCostIsCommission_5, xAddCostIsCommission_6, xAddCostIsCommission_7, xAddCostIsCommission_8, xAddCostIsCommission_9, xAddCostIsCommission_10, xAddCostIsCommission_11, xAddCostIsCommission_12, xAddCostIsCommission_13, xAddCostIsCommission_14, xAddCostIsCommission_15
			, xAddCostNoCommission_1, xAddCostNoCommission_2, xAddCostNoCommission_3, xAddCostNoCommission_4, xAddCostNoCommission_5, xAddCostNoCommission_6, xAddCostNoCommission_7, xAddCostNoCommission_8, xAddCostNoCommission_9, xAddCostNoCommission_10, xAddCostNoCommission_11, xAddCostNoCommission_12, xAddCostNoCommission_13, xAddCostNoCommission_14, xAddCostNoCommission_15
			, xMarginPercent_1, xMarginPercent_2, xMarginPercent_3, xMarginPercent_4, xMarginPercent_5, xMarginPercent_6, xMarginPercent_7, xMarginPercent_8, xMarginPercent_9, xMarginPercent_10, xMarginPercent_11, xMarginPercent_12, xMarginPercent_13, xMarginPercent_14, xMarginPercent_15
			, xCommissionOnly_1, xCommissionOnly_2, xCommissionOnly_3, xCommissionOnly_4, xCommissionOnly_5, xCommissionOnly_6, xCommissionOnly_7, xCommissionOnly_8, xCommissionOnly_9, xCommissionOnly_10, xCommissionOnly_11, xCommissionOnly_12, xCommissionOnly_13, xCommissionOnly_14, xCommissionOnly_15
			, xIsCommission_1, xIsCommission_2, xIsCommission_3, xIsCommission_4, xIsCommission_5, xIsCommission_6, xIsCommission_7, xIsCommission_8, xIsCommission_9, xIsCommission_10, xIsCommission_11, xIsCommission_12, xIsCommission_13, xIsCommission_14, xIsCommission_15
			from #TP_Prices with(nolock) where xtp_key in (select tpkey from  @insertedTpKeys)

			delete #TP_Prices where xtp_key in (select tpkey from  @insertedTpKeys)
			delete from @insertedTpKeys
		end
				
		-----------------------------------------------------КОНЕЦ возвращаем обратно цены ------------------------------------------------------
		Set @nTotalProgress = 99
		update tp_lists with(rowlock) set ti_update = 0 where ti_tokey = @nPriceTourKey
		update tp_turdates with(rowlock) set td_update = 0, td_checkmargin = 0 where td_tokey = @nPriceTourKey
		update tp_tours with(rowlock) set to_progress = @nTotalProgress, to_update = 0, to_updatetime = GetDate(),
							TO_CalculateDateEnd = GetDate(), TO_PriceCount = (Select Count(*) 
			From TP_Prices with(nolock) Where TP_ToKey = to_key) where to_key = @nPriceTourKey
		update tp_services with(rowlock) set ts_checkmargin = 0 where ts_tokey = @nPriceTourKey	
		
		print 'Запись результатов: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
	END

	--Заполнение полей в таблице tp_lists
	declare @toKey int, @add int
	set @toKey = @nPriceTourKey
	set @add = @nUpdate

	update tp_lists with(rowlock)
		set ti_hotelkeys = dbo.mwGetTiHotelKeys(ti_key),
			ti_hotelroomkeys = dbo.mwGetTiHotelRoomKeys(ti_key),
			ti_hoteldays = dbo.mwGetTiHotelNights(ti_key),
			ti_hotelstars = dbo.mwGetTiHotelStars(ti_key),
			ti_pansionkeys = dbo.mwGetTiPansionKeys(ti_key),
			ti_nights = dbo.mwGetTiNights(ti_key)
	where
		ti_tokey = @toKey and ti_CalculatingKey = @nCalculatingKey
	
	update tp_lists with(rowlock)
	set
		ti_hdpartnerkey = ts_oppartnerkey,
		ti_firsthotelpartnerkey = ts_oppartnerkey,
		ti_hdday = ts_day,
		ti_hdnights = ts_days
	from tp_servicelists with (nolock)
		inner join tp_services with (nolock) on (tl_tskey = ts_key and ts_svkey = 3)
	where tl_tikey = ti_key and ts_code = ti_firsthdkey and ti_tokey = @toKey and tl_tokey = @toKey
		and ts_tokey = @toKey and ti_CalculatingKey = @nCalculatingKey	
	------------------------------------------------------------------------------

	Set @nTotalProgress = 100
	update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	set DATEFIRST @nDateFirst
	
	select @nIsEnabled = TO_IsEnabled from TP_Tours where TO_Key = @nPriceTourKey
	
	
	--Засекаем время окончания рассчета begin
	declare @endPriceCalculate datetime
	set @endPriceCalculate = GETDATE()
	SET @sHI_Text = CONVERT(varchar(30),@endPriceCalculate,121)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11010, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Засекаем время окончания рассчета end

	--Записываем кол-во рассчитанных цен begin
	SET @sHI_Text = CONVERT(varchar(10),@calcPricesCount)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11011, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Записываем кол-во рассчитанных цен end

	--Записываем скорость расчета цен begin
	declare @calculatingSpeed decimal(10,2), @seconds int
	set @seconds = datediff(ss,@beginPriceCalculate,@endPriceCalculate)
	if @seconds = 0
		set @seconds = 1
	set @calculatingSpeed = @calcPricesCount / @seconds
	SET @sHI_Text = CONVERT(varchar(10),@calculatingSpeed)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11012, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Записываем скорость расчета цен end

	if (@nIsEnabled = 1)
	begin
		if (@isPriceListPluginRecalculation = 0)
			EXEC FillMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
		else
			EXEC FillMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
	end
	
	print 'Выставление в инет: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()

	-- апдейтим таблицу CalculatingPriceLists
	update CalculatingPriceLists with(rowlock) set CP_Status = 0, CP_StartTime = null where CP_Key = @nCalculatingKey

	Return 0
END
go 

grant exec on CalculatePriceListDynamic to public

go
/*********************************************************************/
/* end sp_CalculatePriceListDynamic.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CleanQuotaDetail.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CleanQuotaDetail]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[CleanQuotaDetail]
GO

CREATE PROCEDURE [dbo].[CleanQuotaDetail] 
	(
		@qtId int,
		@dateBeg datetime,
		@dateEnd datetime
	)
AS
BEGIN
	-- сначала удаляем ненужные QuotaDetails на которые нет записи в QuotaParts
	delete StopSales
	from StopSales join QuotaDetails on QD_ID = SS_QDID
	where QD_QTID = @qtId
	and QD_Date between @dateBeg and @dateEnd
	and not exists (select 1 
					from QuotaParts
					where QP_QDID = QD_ID)
					
	delete QuotaDetails
	where QD_QTID = @qtId
	and QD_Date between @dateBeg and @dateEnd
	and not exists (select 1 
					from QuotaParts
					where QP_QDID = QD_ID)
	
	declare @curQdId int
	-- теперь нужно пересчитать количество свободных и занятых мест
	declare curCleanQuotaDetail cursor local fast_forward for
										select QD_ID
										from QuotaDetails
										where QD_QTID = @qtId
										and QD_Date between @dateBeg and @dateEnd
	OPEN curCleanQuotaDetail
	FETCH NEXT FROM curCleanQuotaDetail INTO @curQdId
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		update QuotaDetails
		set QD_Places = isnull((select SUM(QP_Places) from QuotaParts where QP_QDID = @curQdId),0),
		QD_Busy = isnull((select SUM(QP_Busy) from QuotaParts where QP_QDID = @curQdId),0)
		where QD_ID = @curQdId
		
		
		FETCH NEXT FROM curCleanQuotaDetail INTO @curQdId
	END
	CLOSE curCleanQuotaDetail
	DEALLOCATE curCleanQuotaDetail
END
GO

GRANT EXECUTE on [dbo].[CleanQuotaDetail] to public
GO
/*********************************************************************/
/* end sp_CleanQuotaDetail.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_Run.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_Run]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_Run]
GO

CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_Run]
	(
		-- version 2009.12.03
		-- date 2012-04-13
		@deltaCost decimal(14,2),
		@itogCostMin decimal(14,2),
		@operation bit, -- 1 - изменяем цену, 0 - удаляем цену
		@costInPercent bit, -- 1 - цена в процентах, 0 - цена в у.е.
		@perPerson bit, -- 1 - за человека, 0 - нет
		@serviceTypeKey int,
		@serviceCodeList xml,
		@dateList xml,
		@turList xml,
		@durationList xml,
		@hotelKeys xml
	)
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	declare @round smallint
	SELECT @round = ST_RoundService FROM Setting

	declare @cost decimal(14,2)
	set @cost = @deltaCost;
	
	if (@operation = 0)
	begin
		set @cost = 0;
	end
	
	declare @partUpdate int
	
	set @partUpdate = 100000
	select @partUpdate = SS_ParmValue from SystemSettings where SS_ParmName = 'PartCorrectionPrice'
	
	declare @divide int, @mwReplIsPublisher int, @mwReplIsSubscriber int
	
	set @mwReplIsPublisher = dbo.mwReplIsPublisher()
	set @mwReplIsSubscriber = dbo.mwReplIsSubscriber()

	set @divide = 0

	select @divide = CONVERT(int, isnull(SS_ParmValue, '0'))
	from SystemSettings
	where SS_ParmName = 'MWDivideByCountry'

	select TI_Key
	into #tmp_CorrectionCalculatedPrice_Run
	from TP_ServiceLists with (nolock) join TP_Services with (nolock) on TL_TSKey = TS_Key
	join TP_Lists with (nolock) on TL_TIKey = TI_Key
	where TI_TOKey in (select tbl.res.value('.', 'int') from @turList.nodes('/ArrayOfInt/int') as tbl(res) join TP_Tours on tbl.res.value('.', 'int') = TO_Key where TO_UPDATE != 1)
	and TS_Code in (select tbl.res.value('.', 'int') from @serviceCodeList.nodes('/ArrayOfInt/int') as tbl(res))
	and (@serviceTypeKey != 3 or (TS_SubCode1 in (select tbl.res.value('.', 'int') from @hotelKeys.nodes('/ArrayOfInt/int') as tbl(res))))
	and TS_SVKey = @serviceTypeKey
	and ti_totaldays in (select tbl.res.value('.', 'int') from @durationList.nodes('/ArrayOfInt/int') as tbl(res))
	
	while ((select COUNT(*) from #tmp_CorrectionCalculatedPrice_Run) > 0)
	begin
		-- выборка цен
		select TP_Key as TPU_TPKey, TP_Gross as TPU_TPGrossOld, case when @costInPercent = 0 then
																									convert(int, case when @perPerson = 1 then
																														@cost * (	select top 1 TS_Men
																														from TP_Services with (nolock) join TP_ServiceLists with (nolock) on TS_Key = TL_TSKey 
																														where TS_SVKey = 3
																														and TL_TIKey = TP_TIKey)
																													else 
																														@cost 
																													end)
																								else
																									 convert(int, case when @perPerson = 1 then 
																														TP_Gross * (@cost / 100) * (	select top 1 TS_Men
																																						from TP_Services with (nolock) join TP_ServiceLists with (nolock) on TS_Key = TL_TSKey 
																																						where TS_SVKey = 3
																																						and TL_TIKey = TP_TIKey)
																													else 
																														TP_Gross * (@cost / 100)
																													end)
																								end as TPU_TPGrossDelta
		into #tmp_tpPricesUpdated
		from TP_Prices with (nolock)
		where TP_TIKey in ( select top (@partUpdate) TI_Key from #tmp_CorrectionCalculatedPrice_Run)
		and TP_DateBegin in (select res.value('.', 'datetime') from @dateList.nodes('/ArrayOfDateTime/dateTime') as tbl(res))
				
		if (@operation = 1)
		begin
			-- если изменяем цены
			update TP_Prices with (rowlock)
			set TP_Gross = dbo.RoundPrice(@round,TPU_TPGrossOld + TPU_TPGrossDelta)
			from TP_Prices join #tmp_tpPricesUpdated on TP_Key = TPU_TPKey
		end
		else
		begin
			-- если удаляем цены
			delete TP_Prices with (rowlock)
			from TP_Prices join #tmp_tpPricesUpdated on TP_Key = TPU_TPKey
		end

		-- запишем время изменения в туре
		update TP_Tours
		set to_updatetime = getdate()
		from TP_Tours join @turList.nodes('/ArrayOfInt/int') as tbl(res) on tbl.res.value('.', 'int') = to_key
		
		if (@mwReplIsPublisher <= 0 and @mwReplIsSubscriber <= 0)
		begin
			if (@divide = 0)
			begin
				update mwPriceDataTable with (rowlock)
				set pt_price = dbo.RoundPrice(@round,TPU_TPGrossOld + TPU_TPGrossDelta)
				from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
			end
			else
			begin
				declare @sql nvarchar(4000), @tableName nvarchar(100)
				declare cur cursor fast_forward read_only for
				select name
				from sysobjects
				where xtype = 'U' and name like 'mwPriceDataTable[_]%'

				open cur
				fetch next from cur into @tableName
				while (@@FETCH_STATUS = 0)
				begin
					if (@operation = 1)
					begin
						set @sql = 'update ' + @tableName + ' with (rowlock)
									set pt_price = dbo.RoundPrice(' + convert(varchar(max), @round) + ',TPU_TPGrossOld + TPU_TPGrossDelta)
									from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey'
					end
					else
					begin
						set @sql = 'delete ' + @tableName + ' with (rowlock)
									from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey'
					end
					
					exec (@sql)
					fetch next from cur into @tableName
				end
				
				close cur
				deallocate cur
			end
		end
		
		insert into TP_PricesUpdated(TPU_TPKey, TPU_TPGrossDelta, TPU_TPGrossOld, TPU_IsChangeCostMode)
		select TPU_TPKey, TPU_TPGrossDelta, TPU_TPGrossOld, @operation
		from #tmp_tpPricesUpdated

		delete top (@partUpdate) #tmp_CorrectionCalculatedPrice_Run
		drop table #tmp_tpPricesUpdated
	end
	
END

GO

grant exec on [dbo].[CorrectionCalculatedPrice_Run] to public
go
/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_Run.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_RunSubscriber.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_RunSubscriber]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_RunSubscriber]
GO

CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_RunSubscriber]
AS
BEGIN
	declare @partUpdate int
	
	set @partUpdate = 100000
	select @partUpdate = SS_ParmValue from SystemSettings where SS_ParmName = 'PartCorrectionPrice'
	
	declare @divide int, @mwReplIsSubscriber int
	
	set @mwReplIsSubscriber = dbo.mwReplIsSubscriber()

	set @divide = 0

	select @divide = CONVERT(int, isnull(SS_ParmValue, '0'))
	from SystemSettings
	where SS_ParmName = 'MWDivideByCountry'

	-- копируем таблицу TP_PricesUpdated
	select *
	into #tmp_CorrectionCalculatedPrice_Run
	from TP_PricesUpdated
	
	while ((select COUNT(*) from #tmp_CorrectionCalculatedPrice_Run) > 0)
	begin
		-- берем порцию
		select top (@partUpdate) *
		into #tmp_tpPricesUpdated
		from #tmp_CorrectionCalculatedPrice_Run
	
		if (@mwReplIsSubscriber > 0)
		begin
			if (@divide = 0)
			begin
				update mwPriceDataTable
				set pt_price = TPU_TPGrossOld + TPU_TPGrossDelta
				from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
				where TPU_IsChangeCostMode = 1
				
				delete mwPriceDataTable
				from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
				where TPU_IsChangeCostMode = 0
			end
			else
			begin
				declare @sql nvarchar(4000), @tableName nvarchar(100)
				declare cur cursor fast_forward read_only for
				select name
				from sysobjects
				where xtype = 'U' and name like 'mwPriceDataTable[_]%'

				open cur
				fetch next from cur into @tableName
				while (@@FETCH_STATUS = 0)
				begin
					set @sql = 'update ' + @tableName + '
								set pt_price = TPU_TPGrossOld + TPU_TPGrossDelta
								from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
								where TPU_IsChangeCostMode = 1
								
								delete ' + @tableName + '
								from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
								where TPU_IsChangeCostMode = 0'
					exec (@sql)
					fetch next from cur into @tableName
				end
				
				close cur
				deallocate cur
			end
		end
		
		-- очищаем временную таблицу #tmp_CorrectionCalculatedPrice_Run
		delete #tmp_CorrectionCalculatedPrice_Run
		from #tmp_CorrectionCalculatedPrice_Run 
		where exists (select top 1 1 
						from #tmp_tpPricesUpdated
						where #tmp_CorrectionCalculatedPrice_Run.TPU_Key = #tmp_tpPricesUpdated.TPU_Key)
		-- очищаем основнцю таблмцу TP_PricesUpdated
		delete TP_PricesUpdated
		from TP_PricesUpdated 
		where exists (select top 1 1 
						from #tmp_tpPricesUpdated
						where TP_PricesUpdated.TPU_Key = #tmp_tpPricesUpdated.TPU_Key)
		-- удаляем таблицу порцию
		drop table #tmp_tpPricesUpdated
	end
	
END
GO

grant exec on [dbo].[CorrectionCalculatedPrice_RunSubscriber] to public
GO
/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_RunSubscriber.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DS_GetCalendarTourDates.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetCalendarTourDates]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[GetCalendarTourDates]
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DS_GetCalendarTourDates]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[DS_GetCalendarTourDates]
END
GO

--<VERSION>9.2.20.2</VERSION>
--<DATE>2014-03-04</DATE>
--Получает список возможных дат туров для фильтра РП.
CREATE PROCEDURE [dbo].[DS_GetCalendarTourDates]
	
	@departFromKeys ListIntValue readonly,	--Список ключей городов вылета.
	@countryKeys ListIntValue readonly,		--Список ключей стран.
	@tourKeys ListIntValue readonly,		--Список ключей туров.
	@resortKeys ListIntValue readonly,		--Список ключей курортов.
	@tourTypeKeys ListIntValue readonly,	--Список ключей типов туров.
	@cityKeys ListIntValue readonly			--Список ключей городов.
AS
BEGIN
	SET DATEFIRST 1
	
	DECLARE @mwSearchType int
	SELECT @mwSearchType = LTRIM(RTRIM(ISNULL(SS_ParmValue, ''))) FROM dbo.SystemSettings 
		WHERE SS_ParmName = 'MWDivideByCountry'
	
	DECLARE @tableName nvarchar(100)
	IF (@mwSearchType = 0)
	BEGIN
		SET @tableName = 'dbo.mwPriceDataTable'
	END
	ELSE
	BEGIN
		DECLARE @firstCountryKey int
		SELECT TOP 1 @firstCountryKey = value FROM @countryKeys

		DECLARE @firstDepartFromKey int
		SELECT TOP 1 @firstDepartFromKey = value FROM @departFromKeys

		SET @tableName = dbo.mwGetPriceTableName(@firstCountryKey, @firstDepartFromKey)
	END

	DECLARE @exceptNoPlacesAviaQuota int
	
	SELECT @exceptNoPlacesAviaQuota = LTRIM(RTRIM(ISNULL(SS_ParmValue, '')))
	FROM dbo.SystemSettings
	WHERE SS_ParmName = 'ExceptTourDatesWithNoAQ'

	--Исключение дат, на которые заведены квоты на перелет, но мест в квоте нет
	DECLARE @quotaNeedFromPart nvarchar(2000)
	DECLARE @quotaNeedWherePart nvarchar(100)
	if (@exceptNoPlacesAviaQuota = 1)
	BEGIN
		SET @quotaNeedFromPart =
			' LEFT JOIN
			 (
				SELECT DISTINCT TD_Date
				FROM TP_TurDates
					INNER JOIN QuotaDetails ON QD_Date = TD_Date
					INNER JOIN Quotas ON QD_QTID = QT_ID
					INNER JOIN QuotaObjects ON QT_ID = QO_QTID AND QO_SVKey = 1
					INNER JOIN Charter ON QO_Code = CH_KEY
					LEFT JOIN StopSales as s1 ON s1.SS_QDID = QD_ID
					LEFT JOIN StopSales as s2 ON s2.SS_QOID = QO_ID
				WHERE QO_CNKey IN (SELECT value FROM @countryKeys)
					AND CH_CITYKEYFROM IN (SELECT value FROM @departFromKeys)
					AND ((QD_Places - QD_Busy) = 0
					OR (s1.SS_ID IS NOT NULL AND ISNULL(s1.SS_IsDeleted, 0) <> 1)
					OR (s2.SS_ID IS NOT NULL AND ISNULL(s2.SS_IsDeleted, 0) <> 1))
				) AS t ON t.TD_Date = TP_TurDates.TD_Date '

		SET @quotaNeedWherePart = ' AND t.TD_Date IS NULL '
	END
	ELSE
	BEGIN
		SET @quotaNeedFromPart = ''
		SET @quotaNeedWherePart = ''
	END

	DECLARE @sql nvarchar(MAX)
	SET @sql = 'SELECT DISTINCT DATEDIFF(ss, ''1970-01-01'', TP_TurDates.TD_Date) AS [key],
					CONVERT(varchar, TP_TurDates.TD_Date, 4) AS name,
					TP_TurDates.TD_Date
				FROM TP_TurDates 
					INNER JOIN mwSpoData with(nolock) ON TP_TurDates.TD_TOKey = mwSpoData.sd_tourkey ' +
				@quotaNeedFromPart + 
				'WHERE TP_TurDates.TD_Date > DATEADD(day, - 1, GETDATE())
					AND mwSpoData.sd_ctkeyfrom IN (SELECT value FROM @departFromKeys)
					AND mwSpoData.sd_cnkey IN (SELECT value FROM @countryKeys)' +
				@quotaNeedWherePart
             
	IF ((SELECT COUNT(*) FROM @tourKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourkey IN (SELECT value FROM @tourKeys) AND exists(SELECT TOP 1 1 FROM ' + @tableName +
			' WHERE pt_tourkey IN (SELECT value FROM @tourKeys) AND pt_tourdate = TP_TurDates.TD_Date) '
	END

	IF ((SELECT COUNT(*) FROM @resortKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_rskey IN (SELECT value FROM @resortKeys)'
	END

	IF ((SELECT COUNT(*) FROM @tourTypeKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourtype IN (SELECT value FROM @tourTypeKeys)'
	END

	IF ((SELECT COUNT(*) FROM @cityKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_ctkey IN (SELECT value FROM @cityKeys)'
	END
    
    SET @sql += ' ORDER BY TP_TurDates.TD_Date'

    EXEC sp_executesql @sql,
		N'@departFromKeys ListIntValue readonly, @countryKeys ListIntValue readonly,
			@tourKeys ListIntValue readonly, @resortKeys ListIntValue readonly,
			@tourTypeKeys ListIntValue readonly, @cityKeys ListIntValue readonly',
		@departFromKeys, @countryKeys, @tourKeys, @resortKeys, @tourTypeKeys, @cityKeys
END
GO

GRANT EXEC ON [dbo].[DS_GetCalendarTourDates] TO PUBLIC
GO
/*********************************************************************/
/* end sp_DS_GetCalendarTourDates.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DS_GetRoom.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DS_GetRoom]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[DS_GetRoom]
END
GO

--<VERSION>9.2.20.2</VERSION>
--<DATE>2014-03-04</DATE>
--Получает список типов номеров для фильтра РП.
CREATE PROCEDURE [dbo].[DS_GetRoom]
	@departFromKeys ListIntValue readonly,	--Список ключей городов вылета.
	@countryKeys ListIntValue readonly,		--Список ключей стран.
	@tourKeys ListIntValue readonly,		--Список ключей туров.
	@resortKeys ListIntValue readonly,		--Список ключей курортов.
	@tourTypeKeys ListIntValue readonly,	--Список ключей типов туров.
	@cityKeys ListIntValue readonly			--Список ключей городов.
AS
BEGIN
	SET DATEFIRST 1

	DECLARE @sql nvarchar(MAX)
	SET @sql = '
		SELECT DISTINCT Rooms.RM_KEY AS [key], Rooms.RM_NAME AS name
		FROM Rooms WITH(NOLOCK)
		WHERE RM_KEY IN
			(SELECT DISTINCT sd_rmkey
			 FROM mwPriceHotels WITH(NOLOCK)
			 WHERE ph_sdkey IN
				(SELECT sd_key
				 FROM mwSpoData WITH(NOLOCK)
				 WHERE mwSpoData.sd_ctkeyfrom IN (SELECT value FROM @departFromKeys)
					AND mwSpoData.sd_cnkey IN (SELECT value FROM @countryKeys)'

	IF ((SELECT COUNT(*) FROM @tourTypeKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourtype IN (SELECT value FROM @tourTypeKeys)'
	END

	IF ((SELECT COUNT(*) FROM @resortKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_rskey IN (SELECT value FROM @resortKeys)'
	END

	IF ((SELECT COUNT(*) FROM @cityKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_ctkey IN (SELECT value FROM @cityKeys)'
	END

	IF ((SELECT COUNT(*) FROM @tourKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourkey IN (SELECT value FROM @tourKeys)'
	END

	SET @sql += ')) ORDER BY Rooms.RM_NAME'

	print @sql

    EXEC sp_executesql @sql,
		N'@departFromKeys ListIntValue readonly, @countryKeys ListIntValue readonly,
			@tourKeys ListIntValue readonly, @resortKeys ListIntValue readonly,
			@tourTypeKeys ListIntValue readonly, @cityKeys ListIntValue readonly',
		@departFromKeys, @countryKeys, @tourKeys, @resortKeys, @tourTypeKeys, @cityKeys
END
GO

GRANT EXEC ON [dbo].[DS_GetRoom] TO PUBLIC
GO
/*********************************************************************/
/* end sp_DS_GetRoom.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetNKeys.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetNKeys]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetNKeys]
GO

create PROCEDURE [dbo].[GetNKeys]
(
	@sTable varchar(50) = null,
	@nKeyCount int,
	@nNewKey int = null output
)
AS
--<VERSION>9.2.20.9</VERSION>
--<DATE>2014-02-27</DATE>
--<SUMMARY>Возвращает опред. количество ключей для таблицы</SUMMARY>
declare @nID int
declare @keyTable varchar(100)
declare @query nvarchar (600)

set nocount on

if @nKeyCount is null
	set @nKeyCount = 0
	
if @sTable like 'TP_TOURDATES'
	set @sTable = 'TP_TURDATES'

set nocount on

if (@sTable like 'key_%')
begin
	set @keyTable = @sTable
end
else begin
	select @keyTable = 
		case 
			when @sTable like 'TP_TURDATES' then 'Key_TPTurDates'
			when @sTable like 'TP_Lists' then 'Key_TPLists'
			when @sTable like 'TP_Services' then 'Key_TPServices'
			when @sTable like 'TP_Tours' then 'Key_TPTours'
			when @sTable like 'TP_ServiceLists' then 'Key_TPServiceLists'
			when @sTable like 'TP_Prices' then 'Key_TPPrices'
			when @sTable like 'Accmdmentype' then 'Key_Accmdmentype'
			when @sTable like 'AddDescript1' then 'Key_AddDescript1'
			when @sTable like 'AddDescript2' then 'Key_AddDescript2'
			when @sTable like 'Advertise' then 'Key_Advertise'
			when @sTable like 'Aircraft' then 'Key_Aircraft'
			when @sTable like 'AirService' then 'Key_AirService'
			when @sTable like 'AllHotelOption' then 'Key_AllHotelOption'
			when @sTable like 'AnkFields' then 'Key_AnkFields'
			when @sTable like 'AnnulReasons' then 'Key_AnnulReasons'
			when @sTable like 'Bills' then 'Key_Bills'
			when @sTable like 'Cabine' then 'Key_Cabine'
			when @sTable like 'CauseDiscounts' then 'Key_CauseDiscounts'
			when @sTable like 'Charter' then 'Key_Charter'
			when @sTable like 'CityDictionary' then 'Key_CityDictionary'
			when @sTable like 'Clients' then 'Key_Clients'
			when @sTable like 'Discount' then 'Key_Discount'
			when @sTable like 'DOCUMENTSTATUS' then 'KEY_DOCUMENTSTATUS'
			when @sTable like 'Dogovor' then 'Key_Dogovor'
			when @sTable like 'DogovorList' then 'Key_DogovorList'
			when @sTable like 'EventList' then 'Key_EventList'
			when @sTable like 'Events' then 'Key_Events'
			when @sTable like 'ExcurDictionar' then 'Key_ExcurDictionar'
			when @sTable like 'Factura' then 'Key_Factura'
			when @sTable like 'HotelDictionar' then 'Key_HotelDictionar'
			when @sTable like 'HotelRooms' then 'Key_HotelRooms'
			when @sTable like 'KindOfPay' then 'Key_KindOfPay'
			when @sTable like 'Locks' then 'Key_Locks'
			when @sTable like 'Order_Status' then 'Key_Order_Status'
			when @sTable like 'Orders' then 'Key_Orders'
			when @sTable like 'Pansion' then 'Key_Pansion'
			when @sTable like 'Partners' then 'Key_Partners'
			when @sTable like 'PartnerStatus' then 'Key_PartnerStatus'
			when @sTable like 'PaymentType' then 'Key_PaymentType'
			when @sTable like 'PriceList' then 'Key_PriceList'
			when @sTable like 'PriceServiceLink' then 'Key_PriceServiceLink'
			when @sTable like 'Profession' then 'Key_Profession'
			when @sTable like 'PrtDeps' then 'Key_PrtDeps'
			when @sTable like 'PrtDogs' then 'Key_PrtDogs'
			when @sTable like 'PrtGroups' then 'Key_PrtGroups'
			when @sTable like 'PrtWarns' then 'Key_PrtWarns'
			when @sTable like 'Rep_Options' then 'Key_Rep_Options'
			when @sTable like 'Rep_Profiles' then 'Key_Rep_Profiles'
			when @sTable like 'Resorts' then 'Key_Resorts'
			when @sTable like 'Rooms' then 'Key_Rooms'
			when @sTable like 'RoomsCategory' then 'Key_RoomsCategory'
			when @sTable like 'RoomType' then 'Key_RoomType'
			when @sTable like 'Service' then 'Key_Service'
			when @sTable like 'ServiceList' then 'Key_ServiceList'
			when @sTable like 'Ship' then 'Key_Ship'
			when @sTable like 'TOURSERVLIST' then 'KEY_TOURSERVLIST'
			when @sTable like 'Transfer' then 'Key_Transfer'
			when @sTable like 'Transport' then 'Key_Transport'
			when @sTable like 'Turist' then 'Key_Turist'
			when @sTable like 'Turlist' then 'Key_Turlist'
			when @sTable like 'TURMARGIN' then 'Key_TURMARGIN'
			when @sTable like 'TurService' then 'Key_TurService'
			when @sTable like 'TypeAdvertise' then 'Key_TypeAdvertise'
			when @sTable like 'UserList' then 'Key_UserList'
			when @sTable like 'Vehicle' then 'Key_Vehicle'
			when @sTable like 'WarningList' then 'Key_WarningList'
		end
end

if @keyTable is not null
begin
	set @query = N'
	declare @maxKeyFromTable int
	set @maxKeyFromTable = isnull((Select id from @keyTable with (xlock, rowlock)), 1)
	Set @nNewKeyOut = @maxKeyFromTable + @nKeyCount

	update @keyTable set Id = @nNewKeyOut
	'
	set @query = REPLACE(@query, '@keyTable', @keyTable)
	begin tran
		EXECUTE sp_executesql @query, N'@nNewKeyOut int output, @nKeyCount int', @nNewKeyOut = @nNewKey  output,  @nKeyCount = @nKeyCount
	commit tran
end
else
begin	
	begin tran
		if exists (select top 1 1 from Keys where Key_Table = @sTable)
		begin
			Select @nNewKey = id + @nKeyCount from Keys WITH (xlock, rowlock) where Key_Table = @sTable
			update Keys set Id = @nNewKey where Key_Table = @sTable
		end
		else
		begin
			insert into Keys (Key_Table, Id) values (@sTable, @nKeyCount)
			set @nNewKey=@nKeyCount
		end
	commit tran
end

return 0
GO
grant exec on [dbo].[GetNKeys] to public
GO
/*********************************************************************/
/* end sp_GetNKeys.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetServiceList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceList]
GO

CREATE procedure [dbo].[GetServiceList] 
(
--<VERSION>2009.2.20.8</VERSION>
--<DATE>2014-02-11</DATE>
@TypeOfRelult int, -- 1-список по услугам, 2-список по туристам на услуге
@SVKey int, 
@Codes varchar(100), 
@SubCode1 int=null,
@Date datetime =null, 
@QDID int =null,
@QPID int =null,
@ShowHotels bit =null,
@ShowFligthDep bit =null,
@ShowDescription bit =null,
@State smallint=null,
@SubCode2 int = null,
@PrKey int = null
)
as 

--koshelev
--2012-07-19 TFS 6699 блокировки на базе мешали выполнению хранимки, вынужденная мера
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @Query varchar(8000)
 
CREATE TABLE #Result
(
	DG_Code nvarchar(max), DG_Key int, DG_DiscountSum money, DG_Price money, DG_Payed money,
	DG_PriceToPay money, DG_Rate nvarchar(3), DG_NMen int, PR_Name nvarchar(max), PR_Name_Lat nvarchar(max), CR_Name nvarchar(max), CR_Name_Lat nvarchar(max),
	DL_Key int, DL_NDays int, DL_NMen int, DL_Reserved int, DL_CTKeyTo int, DL_CTKeyFrom int, DL_CNKEYFROM int,
	DL_SubCode1 int, TL_Key int, TL_Name nvarchar(max), TL_Name_Lat nvarchar(max),  TUCount int, TU_NameRus nvarchar(max), TU_NameLat nvarchar(max),
	TU_FNameRus nvarchar(max), TU_FNameLat nvarchar(max), TU_Key int, TU_Sex Smallint, TU_PasportNum nvarchar(max),
	TU_PasportType nvarchar(max), TU_PasportDateEnd datetime, TU_BirthDay datetime, TU_Hotels nvarchar(max), TU_Hotels_Lat nvarchar(max),
	Request smallint, Commitment smallint, Allotment smallint, Ok smallint, TicketNumber nvarchar(max),
	FlightDepDLKey int, FligthDepDate datetime, FlightDepNumber nvarchar(max), ServiceDescription nvarchar(max), ServiceDescription_Lat nvarchar(max),
	ServiceDateBeg datetime, ServiceDateEnd datetime, RM_Name nvarchar(max), RC_Name nvarchar(max), SD_RLID int,
	TU_SNAMERUS nvarchar(max), TU_SNAMELAT nvarchar(max), TU_IDKEY int
)
 
if @TypeOfRelult = 2
begin
	--- создаем таблицу в которой пронумируем незаполненых туристов
	CREATE TABLE #TempServiceByDate
	(
		SD_ID int identity(1,1) not null,
		SD_Date datetime,
		SD_DLKey int,
		SD_RLID int,
		SD_QPID int,
		SD_TUKey int,
		SD_RPID int,
		SD_State int
	)

	-- вносим все записи которые нам могут подойти
	insert into #TempServiceByDate(SD_Date, SD_DLKey, SD_RLID, SD_QPID,	SD_TUKey, SD_RPID, SD_State)
	select SD_Date, SD_DLKey, SD_RLID, SD_QPID,	SD_TUKey, SD_RPID, SD_State
	from ServiceByDate as SSD join Dogovorlist on DL_KEY = SD_DLKey
	where DL_SVKEY = @SVKey
	and DL_CODE = convert(int, @Codes)
	and ((@SubCode1 is null) or (DL_SUBCODE1 = @SubCode1))
	and ((@QPID is null) or (SD_QPID = @QPID))
	and ((@State is null) or (SD_State = @State))
	--mv 24.10.2012 не понячл зачем нужен был подзапрос, но точно он приводил к следущей проблеме
	-- если отбираем с фильтром по статусу, то статус проверял на любой из дней, а не тот на который формируется список
	and SSD.SD_Date = @Date and (@PrKey is null or DL_PARTNERKEY = @PrKey)
	--and exists (select 1 from ServiceByDate as SSD2 where SSD.SD_DLKey = SSD2.SD_DLKey and SSD2.SD_Date = @Date)
	
	declare @Id int, @SDDate datetime, @SDDLKey int, @SDTUKey int,
	@oldDlKey int, @oldDate datetime, @i int

	set @i = -1
	 
	DECLARE noBodyTurists CURSOR FOR 
	select SD_ID, SD_Date, SD_DLKey, SD_TUKey
	from #TempServiceByDate
	where SD_TUKey is null
	order by SD_DLKey, SD_Date

	OPEN noBodyTurists
	FETCH NEXT FROM noBodyTurists INTO @Id, @SDDate, @SDDLKey, @SDTUKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- если мы встретили новую дату или услугу то сбрасываем счетчик
		if @oldDlKey != @SDDLKey or @oldDate != @SDDate
		begin
			set @i = -1
		end
			
		update #TempServiceByDate
		set SD_TUKey = @i
		where SD_ID = @Id
		
		set @i = @i - 1

		set @oldDlKey = @SDDLKey
		set @oldDate = @SDDate
		
		FETCH NEXT FROM noBodyTurists INTO @Id, @SDDate, @SDDLKey, @SDTUKey
	END
	CLOSE noBodyTurists
	DEALLOCATE noBodyTurists 

	--select * from #TempServiceByDate

	-- 29.10.13 Гусак изменил привязку покупателя
	-- с left join Partners on dl_agent = pr_key
	-- на 		left join Partners on dg_partnerkey = pr_key
	SET @Query = '
		INSERT INTO #Result (DG_Code, DG_Key, DG_DiscountSum, DG_Price, DG_Payed, 
		DG_PriceToPay, DG_Rate, DG_NMen, 
		PR_Name, PR_Name_Lat, CR_Name,  CR_Name_Lat,
		DL_Key, DL_NDays, DL_NMen, DL_Reserved, DL_CTKeyTo, DL_CTKeyFrom, DL_SubCode1, ServiceDateBeg, ServiceDateEnd, 
		TL_Key, TUCount, TU_NameRus, TU_NameLat, TU_FNameRus, TU_FNameLat, TU_Key, 
		TU_Sex, TU_PasportNum, TU_PasportType, TU_PasportDateEnd, TU_BirthDay, TicketNumber, TU_SNAMERUS, TU_SNAMELAT, TU_IDKEY)
		SELECT	  DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, 
		(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN, 
		PR_NAME, PR_NAMEENG, CR_NAME, CR_NameLat, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, 
		DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + '=3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END,
		DG_TRKey, 0, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS, TU_FNAMELAT, SD_TUKey, case when SD_TUKey > 0 then isnull(TU_SEX,0) else null end, TU_PASPORTTYPE + ''№'' + TU_PASPORTNUM, TU_PASPORTTYPE, 
		TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, TU_SNAMERUS, TU_SNAMELAT, TU_IDKEY
		FROM  Dogovor join Dogovorlist on dl_dGKEY = DG_KEY
--		left join Partners on dl_agent = pr_key
		left join Partners on dg_partnerkey = pr_key
		join Controls on dl_control = cr_key
		join #TempServiceByDate on SD_DLKey = DL_KEY
		left join TuristService on tu_dlkey = dl_key and TU_TUKEY = SD_TUKey
		left join Turist on tu_key = tu_tukey
		WHERE '

		SET @Query=@Query + '
			 DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' AND DL_CODE in (' + @Codes + ') AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND '

		IF @QPID is not null or @QDID is not null
		BEGIN
			IF @QPID is not null
				SET @Query=@Query + 'and SD_QPID IN (' + CAST(@QPID as varchar(20)) + ')'
			ELSE
				--buryak
				--2013-02-20 TFS 11520 MT.Экран "Список на услугу".Не отображались путевки без туристов.
				SET @Query=@Query + 'and exists (SELECT top 1 SD_DLKEY FROM #TempServiceByDate, QuotaParts WHERE SD_QPID=QP_ID and QP_QDID IN (' + CAST(@QDID as varchar(20)) + ') and SD_DLKEY=DL_Key and (tu_tukey is null or sd_tukey = tu_tukey))'
		END
				
		if (@SubCode1 != '0')
			SET @Query=@Query + ' AND DL_SUBCODE1 in (' + CAST(@SubCode1 as varchar(20)) + ')'
		IF @State is not null
			SET @Query=@Query + ' and SD_State=' + CAST(@State as varchar(1))
		if (@SubCode2 != '0')
			SET @Query=@Query + ' AND DL_SUBCODE2 in (' + CAST(@SubCode2 as varchar(20)) + ')'
		SET @Query=@Query + ' 
		group by DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, DG_PDTTYPE, DG_RATE, DG_NMEN, 
		PR_NAME, PR_NAMEENG, CR_NAME, CR_NameLat, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, DL_DateBeg,
		DL_DateEnd, DG_TRKey, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS,
		TU_FNAMELAT, SD_TUKey, TU_SEX, TU_PASPORTNUM, TU_PASPORTTYPE, TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, TU_SNAMERUS, TU_SNAMELAT, TU_IDKEY'
end
else
begin
	-- 29.10.13 Гусак изменил привязку покупателя
	-- с left join Partners on dl_agent = pr_key
	-- на 		left join Partners on dg_partnerkey = pr_key
	SET @Query = '
		INSERT INTO #Result (DG_Code, SD_RLID, RM_Name, RC_Name, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		DG_PriceToPay, DG_RATE, DG_NMEN,
		PR_NAME, PR_Name_Lat, CR_NAME, CR_NAME_Lat, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKeyTo, DL_SubCode1,
		ServiceDateBeg, ServiceDateEnd, TL_Key, TUCount, DL_Key, DL_CTKeyFrom)
		select DG_CODE, SD_RLID, RM_Name, RC_Name, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		(case when DG_PDTTYPE = 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN,
		PR_NAME, PR_NAMEENG, CR_NAME, CR_NAMELat, DL_NDays, 
		--mv 24.10.2012 -убрал очень странный код - в поле кол-во человек выводилосб количество комнат, сделал количество мест хотя бы
		--case when QT_ByRoom = 1 then count(distinct SD_RLID) else count(distinct SD_RPID) end as DL_NMEN,
		COUNT(SD_RPID),
		DL_RESERVED, DL_CTKey, DL_SubCode1, DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + ' = 3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END, DG_TRKey, Count(distinct SD_TUKey), DL_KEY, DL_SubCode2
		from ServiceByDate left join RoomNumberLists on sd_rlid = rl_id
		left join Rooms on rl_rmkey = rm_key
		left join RoomsCategory on rl_rckey = rc_key
		left join QuotaParts on sd_qpid = qp_id
		left join QuotaDetails on QP_QDID = QD_ID and QP_Date = QD_Date
		left join Quotas on QT_ID = QD_QTID
		join Dogovorlist on sd_dlkey = dl_key
		join Controls on dl_control = cr_key
--		left join Partners on dl_agent = pr_key
		join Dogovor on dl_dGKEY = DG_KEY
		left join Partners on dg_partnerkey = pr_key
		where DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' 
			AND DL_CODE in (' + @Codes + ') 
			AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND
			--mv 24.10.2012 добавил фильтр по дате SD, так как просмотр идет относительно этой даты
			AND SD_Date = ''' + CAST(@Date as varchar(20)) + ''' '
		
	if @QDID is not null
		SET @Query = @Query + ' and qp_qdid = ' + CAST(@QDID as nvarchar(max))
	if @QPID is not null
		SET @Query = @Query + ' and qp_id = ' + CAST(@QPID as nvarchar(max))
	IF @State is not null
		SET @Query=@Query + ' and SD_State=' + CAST(@State as varchar(1))
	-- mv 24.10.2012 - не было фильтра по услуге, в список попадали лишние
	IF @SubCode1 is not null
		SET @Query=@Query + ' and DL_SUBCODE1 = ' + CAST(@SubCode1 as varchar(20))
	
	SET @Query = @Query + '
		group by DG_CODE, SD_RLID, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		DG_PDTTYPE, DG_DISCOUNTSUM, DG_RATE, DG_NMEN,
		PR_NAME, PR_NAMEENG, CR_NAME,CR_NAMELat, DL_NDays, DL_RESERVED, DL_CTKey, DL_SubCode1, DL_SubCode2,
		DL_DateBeg, DL_DateEnd, DG_TRKey, RM_Name, RC_Name, QT_ByRoom, DL_KEY'
end

--PRINT @Query
EXEC (@Query)
 
UPDATE #Result SET #Result.TL_Name=(SELECT TL_Name FROM TurList WHERE #Result.TL_Key=TurList.TL_Key)
UPDATE #Result SET #Result.TL_Name_Lat=(SELECT TL_NameLat FROM TurList WHERE #Result.TL_Key=TurList.TL_Key)

--select * from  #Result

if @TypeOfRelult=1
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=1)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=3)
END
else
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=1)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=3)
END
 
IF @ShowHotels=1
BEGIN
	IF @TypeOfRelult = 2
	BEGIN
		DECLARE @HD_Name varchar(100), @HD_Name2_Lat varchar(100),  @HD_Stars varchar(25), @PR_Name varchar(100), @PR_Name_Lat varchar(100), @TU_Key int, @HD_Key int, @PR_Key int, @TU_KeyPrev int, @TU_Hotels varchar(255), @TU_Hotels_Lat varchar(255)
		DECLARE curServiceList CURSOR FOR 
			SELECT	  DISTINCT HD_Name, HD_NAMELAT, HD_Stars, PR_Name, PR_NAMEENG, TU_TUKey, HD_Key, PR_Key 
			FROM  HotelDictionary, DogovorList, TuristService, Partners
			WHERE	  PR_Key=DL_PartnerKey and HD_Key=DL_Code and TU_DLKey=DL_Key and TU_TUKey in (SELECT TU_Key FROM #Result) and dl_SVKey=3 
			ORDER BY TU_TUKey
		OPEN curServiceList
		FETCH NEXT FROM curServiceList INTO	  @HD_Name,@HD_Name2_Lat, @HD_Stars,@PR_Name, @PR_Name_Lat, @TU_Key, @HD_Key, @PR_Key
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @TU_Key!=@TU_KeyPrev or @TU_KeyPrev is null
			begin
			  Set @TU_Hotels=@HD_Name+' '+@HD_Stars+' ('+@PR_Name+')'
			  Set @TU_Hotels_Lat=@HD_Name2_Lat+' '+@HD_Stars+' ('+@PR_Name_Lat+')'
			end
			ELSE
			begin
			  Set @TU_Hotels=@TU_Hotels+', '+@HD_Name+' '+@HD_Stars+' ('+@PR_Name+')'
			  Set @TU_Hotels_Lat=@TU_Hotels_Lat+', '+@HD_Name2_Lat+' '+@HD_Stars+' ('+@PR_Name_Lat+')'
			end
			UPDATE #Result SET TU_Hotels=@TU_Hotels WHERE TU_Key=@TU_Key
			UPDATE #Result SET TU_Hotels_Lat=@TU_Hotels_Lat WHERE TU_Key=@TU_Key
			SET @TU_KeyPrev=@TU_Key
			FETCH NEXT FROM curServiceList INTO	   @HD_Name,@HD_Name2_Lat, @HD_Stars, @PR_Name, @PR_Name_Lat, @TU_Key, @HD_Key, @PR_Key
		END
		CLOSE curServiceList
		DEALLOCATE curServiceList
	END
	IF @TypeOfRelult = 1
	BEGIN
		DECLARE @HD_Name1 varchar(100), @HD_Name1_lat varchar(100), @HD_Stars1 varchar(25), @PR_Name1 varchar(100), @PR_Name1_Lat varchar(100), @DL_Key1 int, @HD_Key1 int, 
				@PR_Key1 int, @DL_KeyPrev1 int, @TU_Hotels1 varchar(255), @TU_Hotels1_Lat varchar(255), @DG_Key int, @DG_KeyPrev int
		DECLARE curServiceList CURSOR FOR 
			--SELECT DISTINCT HD_Name, HD_Stars, P.PR_Name, DogList.DL_Key, HD_Key, PR_Key--, DG_Key
			--FROM HotelDictionary, DogovorList DogList, TuristService, Partners P
			--WHERE P.PR_Key = DogList.DL_PartnerKey and HD_Key = DogList.DL_Code and TU_DLKey = DogList.DL_Key and
			--TU_TUKey in (SELECT TU_TUKEY FROM TuristService WHERE TU_DLKEY in (SELECT DL_KEY FROM #Result)) 
			--and DL_SVKey=3 
			--ORDER BY DogList.DL_Key
			SELECT DISTINCT HD_Name, HD_NameLat, HD_Stars, HD_Key, P.PR_Name, PR_NAMEENG, P.PR_Key, DogList.DL_Key, R.DG_Key
			FROM HotelDictionary, DogovorList DogList, Partners P, #Result R
			WHERE P.PR_Key = DogList.DL_PartnerKey and HD_Key = DogList.DL_Code and DogList.DL_DGKey = R.DG_Key			
				  and DogList.DL_SVKey=3 
			ORDER BY R.DG_Key
		OPEN curServiceList
		FETCH NEXT FROM curServiceList INTO @HD_Name1, @HD_Name1_lat, @HD_Stars1, @HD_Key1, @PR_Name1, @PR_Name1_Lat, @PR_Key1, @DL_Key1, @DG_Key
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @DG_Key != @DG_KeyPrev or @DG_KeyPrev is null  
			BEGIN
			  Set @TU_Hotels1=@HD_Name1+' '+@HD_Stars1+' ('+@PR_Name1+')'
			  Set @TU_Hotels1_Lat=@HD_Name1_lat+' '+@HD_Stars1+' ('+@PR_Name1_Lat+')'
			END
			ELSE
			BEGIN
			  Set @TU_Hotels1=@TU_Hotels1+', '+@HD_Name1+' '+@HD_Stars1+' ('+@PR_Name1+')'
			  Set @TU_Hotels1=@TU_Hotels1_Lat+', '+@HD_Name1_lat+' '+@HD_Stars1+' ('+@PR_Name1_Lat+')'
			END
			UPDATE #Result SET TU_Hotels=@TU_Hotels1 WHERE DG_Key=@DG_Key --DL_Key=@DL_Key1
			UPDATE #Result SET TU_Hotels_Lat=@TU_Hotels1_Lat WHERE DG_Key=@DG_Key --DL_Key=@DL_Key1
			SET @DG_KeyPrev = @DG_Key
			FETCH NEXT FROM curServiceList INTO @HD_Name1, @HD_Name1_lat, @HD_Stars1, @HD_Key1, @PR_Name1, @PR_Name1_Lat, @PR_Key1, @DL_Key1, @DG_Key
		END
		CLOSE curServiceList
		DEALLOCATE curServiceList
	END
END
 
IF @ShowFligthDep=1 and @SVKey=1
BEGIN
	IF @TypeOfRelult = 2
	BEGIN
		Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList,TuristService Where TU_DLKey=DL_Key and DL_DGKey=#Result.DG_Key and DL_CTKey=#Result.DL_CTKeyFrom and DL_SubCode2=#Result.DL_CTKeyTo and TU_TUKey=#Result.TU_Key and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc)
		if exists (select 1 from #Result Where FlightDepDLKey is null)
			Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList,TuristService Where TU_DLKey=DL_Key and DL_DGKey=#Result.DG_Key and DL_CTKey=#Result.DL_CTKeyFrom and TU_TUKey=#Result.TU_Key and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc) where FlightDepDLKey is null
		--если по городу не нашли ишем по стране
		if exists (select 1 from #Result Where FlightDepDLKey is null)     
		begin
			update #Result set DL_CNKEYFROM = (select top 1 ct_cnkey from citydictionary where ct_key =#Result.DL_CTKEYFROM)
			Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList,TuristService Where TU_DLKey=DL_Key and DL_DGKey=#Result.DG_Key and DL_CNKey=#Result.DL_CNKeyFrom and TU_TUKey=#Result.TU_Key and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc)	where FlightDepDLKey is null	  
		end
	END
	ELSE
	BEGIN
		Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList Where DL_DGKey=#Result.DG_Key and DL_CTKey=#Result.DL_CTKeyFrom and DL_SubCode2=#Result.DL_CTKeyTo and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc)
		if exists (select 1 from #Result Where FlightDepDLKey is null)
			Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList Where DL_DGKey=#Result.DG_Key and DL_CTKey=#Result.DL_CTKeyFrom and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc) where FlightDepDLKey is null
		--если по городу не нашли ишем по стране
		if exists (select 1 from #Result Where FlightDepDLKey is null)     
		begin
			update #Result set DL_CNKEYFROM = (select top 1 ct_cnkey from citydictionary where ct_key =#Result.DL_CTKEYFROM)
			Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList,TuristService Where TU_DLKey=DL_Key and DL_DGKey=#Result.DG_Key and DL_CNKey=#Result.DL_CNKeyFrom and TU_TUKey=#Result.TU_Key and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc)	where FlightDepDLKey is null	  
		end
	END
	Update #Result set FligthDepDate = (select dl_dateBeg From DogovorList where DL_Key=#Result.FlightDepDLKey)
	Update #Result set FlightDepNumber = (select CH_AirLineCode + ' ' + CH_Flight From DogovorList, Charter where DL_Code=CH_Key and DL_Key=#Result.FlightDepDLKey)
END

IF @ShowDescription=1
BEGIN
	IF @SVKey=1
		Update #Result SET ServiceDescription=LEFT((SELECT ISNUll(AS_Code, '') + '-' + AS_NameRus FROM AirService WHERE AS_Key=DL_SubCode1),80),
		ServiceDescription_Lat=LEFT((SELECT ISNUll(AS_Code, '') + '-' + AS_NAMELAT FROM AirService WHERE AS_Key=DL_SubCode1),80)
	ELSE IF (@SVKey=2 or @SVKey=4)
		Update #Result SET ServiceDescription=LEFT((SELECT TR_Name FROM Transport WHERE TR_Key=DL_SubCode1),80),
							ServiceDescription_Lat=LEFT((SELECT TR_NAMELAT FROM Transport WHERE TR_Key=DL_SubCode1),80)
	ELSE IF (@SVKey=3 or @SVKey=8)
	BEGIN
		Update #Result SET ServiceDescription=LEFT((SELECT RM_Name + '(' + RC_Name + ')' + AC_Name FROM Rooms,RoomsCategory,AccMdMenType,HotelRooms WHERE HR_Key=DL_SubCode1 and HR_RMKey=RM_Key and HR_RCKey=RC_Key and HR_ACKey=AC_Key),80),
							ServiceDescription_Lat=LEFT((SELECT RM_NAMELAT + '(' + RC_NAMELAT + ')' + AC_NAMELAT FROM Rooms,RoomsCategory,AccMdMenType,HotelRooms WHERE HR_Key=DL_SubCode1 and HR_RMKey=RM_Key and HR_RCKey=RC_Key and HR_ACKey=AC_Key),80)
		IF @SVKey=8
			Update #Result SET ServiceDescription='All accommodations' where DL_SubCode1=0
	END
	ELSE IF (@SVKey=7 or @SVKey=9)
	BEGIN
		Update #Result SET ServiceDescription=LEFT((SELECT ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_Name,'') FROM Cabine WHERE CB_Key=DL_SubCode1),80),
							ServiceDescription_Lat=LEFT((SELECT ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_NAMELAT,'') FROM Cabine WHERE CB_Key=DL_SubCode1),80)
		IF @SVKey=9
			Update #Result SET ServiceDescription='All accommodations' where DL_SubCode1=0
	END
	ELSE
		Update #Result SET ServiceDescription=LEFT((SELECT A1_Name FROM AddDescript1 WHERE A1_Key=DL_SubCode1),80), 
							ServiceDescription_Lat=LEFT((SELECT A1_NAMELAT FROM AddDescript1 WHERE A1_Key=DL_SubCode1),80) WHERE ISNULL(DL_SubCode1,0)>0
END

--print @Query
SELECT * FROM #Result

GO
GRANT EXECUTE ON [dbo].[GetServiceList] TO Public
GO
/*********************************************************************/
/* end sp_GetServiceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ImportExchangeQuotaStops.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ImportExchangeQuotaStops]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[ImportExchangeQuotaStops]
GO

CREATE PROCEDURE [dbo].[ImportExchangeQuotaStops]
	(
		@dateBeg datetime,
		@dateEnd datetime,
		@HotelKey int,
		@prKey int
	)
AS
BEGIN	
	-- процедура импортирует информацию о квотах из тиблицы ExchangeQuotaStops
	--<version>2009.2.21</version>
	--<data>2014-03-06</data>

	SET NOCOUNT ON;
	
	declare @SvKey int, @Code int, @SubCode1 int, @SubCode2 int, @SubCode3 int, @Date datetime, @IsStop bit, @Places int, @PartnerKey int
	declare @qtKey int, @qoKey int, @qdKey int, @releaseConst int, @release int

	set @releaseConst = 365
	set @release = null
	
	declare ExchangeQuotaStops_cursor cursor local fast_forward for
	select EQS_SvKey, EQS_Code, EQS_SubCode1, EQS_SubCode2, EQS_SubCode3, EQS_Date, EQS_IsStop, EQS_Places, EQS_PartnerKey
	from ExchangeQuotaStops 
	where EQS_Date between @dateBeg and @dateEnd
		AND EQS_Code = @HotelKey
		and EQS_SvKey = 3
	order by EQS_Date, EQS_IsStop;

	open ExchangeQuotaStops_cursor;
	
	fetch next from ExchangeQuotaStops_cursor into @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @Places, @PartnerKey;	
	while @@FETCH_STATUS = 0
	begin		
		-- пришли обычные квоты
		if (@IsStop = 0 and @Places >= 0)
		begin

			if (not exists (select 1
									from Quotas join QuotaObjects on QT_ID = QO_QTID
									where QT_PRKey = @PartnerKey
									and QO_SVKey = @SvKey
									and QO_Code = @Code
									and QO_SubCode1 = @SubCode1
									and QO_SubCode2 = @SubCode3))
			begin
				insert into Quotas (QT_PRKey, QT_ByRoom, QT_Comment)
				values (@PartnerKey, 1, 'Quotas from Interlook. Load: ' + convert(nvarchar(max), GETDATE(), 121))
				set @qtKey = SCOPE_IDENTITY()
					
				insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
				values (@qtKey, @SvKey, @Code, @SubCode1, @SubCode3)
				set @qoKey = SCOPE_IDENTITY()
			end
			else
			begin
				select @qtKey = QT_ID, @qoKey = QO_ID
				from Quotas join QuotaObjects on QT_ID = QO_QTID
				where QT_PRKey = @PartnerKey
				and QO_SVKey = @SvKey
				and QO_Code = @Code
				and QO_SubCode1 = @SubCode1
				and QO_SubCode2 = @SubCode3
			end

			if not exists (select 1 from QuotaDetails with(nolock) where QD_QTID = @qtKey and QD_Date = @Date and QD_Type = 1)
			begin
				insert into QuotaDetails(QD_QTID, QD_Date, QD_Type, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey, QD_Release)
				values (@qtKey, @Date, 1, @Places, 0, GETDATE(), [dbo].[GetUserId](), @release)
				set @qdKey = SCOPE_IDENTITY()
			end
			else
			begin
				select top(1) @qdKey = QD_ID
				from QuotaDetails with(nolock) 
				where QD_QTID = @qtKey 
				and QD_Date = @Date 
				and QD_Type = 1

				update QuotaDetails
				set QD_Places = @Places,
				QD_Busy = 0,
				QD_Release = @release,
				QD_IsDeleted = null
				where QD_ID = @qdKey
			end
				
			if not exists (select 1 from QuotaParts where QP_QDID = @qdKey and QP_Date = @Date and QP_IsNotCheckIn = 0 and QP_Durations = '')
			begin
				insert into QuotaParts(QP_QDID, QP_Date, QP_Places, QP_Busy, QP_Limit, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey)
				values (@qdKey, @Date, @Places, 0, 1, 0, '', GETDATE(), [dbo].[GetUserId]())
			end
			else
			begin
				declare @qpKey int

				select top(1) @qpKey = QP_ID
				from QuotaParts 
				where QP_QDID = @qdKey 
				and QP_Date = @Date 
				and QP_IsNotCheckIn = 0 
				and QP_Durations = ''

				update QuotaParts
				set QP_Places = @Places,
				QP_Busy = 0,
				QP_Limit = 1,
				QP_IsDeleted = null
				where QP_ID = @qpKey

			end
		end
		else if (@IsStop = 1)
		begin
			-- пришел новый стоп, добавляем его
			if (@Places >= 0)
			begin
				if not exists (	select 1
								from QuotaObjects
								where QO_SVKey = @SvKey
								and QO_Code = @Code
								and QO_SubCode1 = @SubCode1
								and QO_SubCode2 = @SubCode3
								and QO_QTID is null)
				begin
					insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
					values (null, @SvKey, @Code, @SubCode1, @SubCode3)
					set @qoKey = SCOPE_IDENTITY()
				end
				else
				begin
					select @qoKey = QO_ID
					from QuotaObjects
					where QO_SVKey = @SvKey
					and QO_Code = @Code
					and QO_SubCode1 = @SubCode1
					and QO_SubCode2 = @SubCode3
					and QO_QTID is null
				end
				
				insert into StopSales(SS_QOID, SS_QDID, SS_PRKey, SS_Date, SS_AllotmentAndCommitment, SS_Comment, SS_CreateDate, SS_CreatorKey)
				values (@qoKey, null, @PartnerKey, @Date, 0, '', GETDATE(), [dbo].[GetUserId]())
			end
			else
			begin
				-- стоп удален
				if exists (select 1 
						   from QuotaObjects 
						   join StopSales on SS_QOID = QO_ID 
						   where QO_SVKey = @SvKey
							   and QO_Code = @Code
							   and QO_SubCode1 = @SubCode1
							   and QO_SubCode2 = @SubCode3
							   and QO_QTID is null
							   and ISNULL(SS_IsDeleted, 0) = 0)
				begin
					update StopSales
					set SS_IsDeleted = 1
					from QuotaObjects
					where SS_QOID = QO_ID
						and QO_SVKey = @SvKey
						and QO_Code = @Code
						and QO_SubCode1 = @SubCode1
						and QO_SubCode2 = @SubCode3
						and QO_QTID is null
						and ISNULL(SS_IsDeleted, 0) = 0
						and SS_Date = @Date
				end
			end
		end		
	
		fetch next from ExchangeQuotaStops_cursor into @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @Places, @PartnerKey;		
	end
	
	close ExchangeQuotaStops_cursor;
	deallocate ExchangeQuotaStops_cursor;
END
GO

grant exec on [dbo].[ImportExchangeQuotaStops] to public
go
/*********************************************************************/
/* end sp_ImportExchangeQuotaStops.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ImportExchangeQuotaStops_Bulk.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ImportExchangeQuotaStops_Bulk]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[ImportExchangeQuotaStops_Bulk]
GO

CREATE PROCEDURE [dbo].[ImportExchangeQuotaStops_Bulk]
AS
BEGIN	
	-- процедура импортирует информацию о квотах из таблицы ExchangeQuotaStops
	--<version>2009.2.21</version>
	--<data>2014-03-06</data>

	SET NOCOUNT ON;
	
	declare @SvKey int, @Code int, @SubCode1 int, @SubCode2 int, @SubCode3 int, @Date datetime, @IsStop bit, @Places int, @PartnerKey int
	declare @qtKey int, @qoKey int, @qdKey int, @releaseConst int, @release int, @id int

	set @releaseConst = 365
	set @release = null
	
	declare ExchangeQuotaStops_cursor cursor local fast_forward for
	select EQS_ID, EQS_SvKey, EQS_Code, EQS_SubCode1, EQS_SubCode2, EQS_SubCode3, EQS_Date, EQS_IsStop, EQS_Places, EQS_PartnerKey
	from ExchangeQuotaStops 
	where EQS_IsProcessed = 0
	and EQS_SvKey = 3
	order by EQS_Date, EQS_IsStop;

	-- list of processed ExchangeQuotaStops keys
	create table #processedRecords
	(
		EQS_ID int
	)

	-- error during records processing flag
	declare @wasError as bit
	declare @errorMessage as nvarchar(max)
	set @wasError = 0

	begin try

		open ExchangeQuotaStops_cursor;
	
		fetch next from ExchangeQuotaStops_cursor into @id, @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @Places, @PartnerKey;	
		while @@FETCH_STATUS = 0
		begin		
		
			-- пришли обычные квоты
			if (@IsStop = 0 and @Places >= 0)
			begin

				if (not exists (select 1
										from Quotas join QuotaObjects on QT_ID = QO_QTID
										where QT_PRKey = @PartnerKey
										and QO_SVKey = @SvKey
										and QO_Code = @Code
										and QO_SubCode1 = @SubCode1
										and QO_SubCode2 = @SubCode3))
				begin
					insert into Quotas (QT_PRKey, QT_ByRoom, QT_Comment)
					values (@PartnerKey, 1, 'Quotas from Interlook. Load: ' + convert(nvarchar(max), GETDATE(), 121))
					set @qtKey = SCOPE_IDENTITY()
					
					insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
					values (@qtKey, @SvKey, @Code, @SubCode1, @SubCode3)
					set @qoKey = SCOPE_IDENTITY()
				end
				else
				begin
					select @qtKey = QT_ID, @qoKey = QO_ID
					from Quotas join QuotaObjects on QT_ID = QO_QTID
					where QT_PRKey = @PartnerKey
					and QO_SVKey = @SvKey
					and QO_Code = @Code
					and QO_SubCode1 = @SubCode1
					and QO_SubCode2 = @SubCode3
				end

				if not exists (select 1 from QuotaDetails with(nolock) where QD_QTID = @qtKey and QD_Date = @Date and QD_Type = 1)
				begin
					insert into QuotaDetails(QD_QTID, QD_Date, QD_Type, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey, QD_Release)
					values (@qtKey, @Date, 1, @Places, 0, GETDATE(), [dbo].[GetUserId](), @release)
					set @qdKey = SCOPE_IDENTITY()
				end
				else
				begin
					select top(1) @qdKey = QD_ID
					from QuotaDetails with(nolock) 
					where QD_QTID = @qtKey 
					and QD_Date = @Date 
					and QD_Type = 1

					update QuotaDetails
					set QD_Places = @Places,
					QD_Busy = 0,
					QD_Release = @release,
					QD_IsDeleted = null
					where QD_ID = @qdKey
				end
				
				if not exists (select 1 from QuotaParts where QP_QDID = @qdKey and QP_Date = @Date and QP_IsNotCheckIn = 0 and QP_Durations = '')
				begin
					insert into QuotaParts(QP_QDID, QP_Date, QP_Places, QP_Busy, QP_Limit, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey)
					values (@qdKey, @Date, @Places, 0, 1, 0, '', GETDATE(), [dbo].[GetUserId]())
				end
				else
				begin
					declare @qpKey int

					select top(1) @qpKey = QP_ID
					from QuotaParts 
					where QP_QDID = @qdKey 
					and QP_Date = @Date 
					and QP_IsNotCheckIn = 0 
					and QP_Durations = ''

					update QuotaParts
					set QP_Places = @Places,
					QP_Busy = 0,
					QP_Limit = 1,
					QP_IsDeleted = null
					where QP_ID = @qpKey

				end
			end
			else if (@IsStop = 1)
			begin
				-- пришел новый стоп, добавляем его
				if (@Places >= 0)
				begin
					if not exists (	select 1
									from QuotaObjects
									where QO_SVKey = @SvKey
									and QO_Code = @Code
									and QO_SubCode1 = @SubCode1
									and QO_SubCode2 = @SubCode3
									and QO_QTID is null)
					begin
						insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
						values (null, @SvKey, @Code, @SubCode1, @SubCode3)
						set @qoKey = SCOPE_IDENTITY()
					end
					else
					begin
						select @qoKey = QO_ID
						from QuotaObjects
						where QO_SVKey = @SvKey
						and QO_Code = @Code
						and QO_SubCode1 = @SubCode1
						and QO_SubCode2 = @SubCode3
						and QO_QTID is null
					end
				
					insert into StopSales(SS_QOID, SS_QDID, SS_PRKey, SS_Date, SS_AllotmentAndCommitment, SS_Comment, SS_CreateDate, SS_CreatorKey)
					values (@qoKey, null, @PartnerKey, @Date, 0, '', GETDATE(), [dbo].[GetUserId]())
				end
				else
				begin
					-- стоп удален
					if exists (select 1 
							   from QuotaObjects 
							   join StopSales on SS_QOID = QO_ID 
							   where QO_SVKey = @SvKey
								   and QO_Code = @Code
								   and QO_SubCode1 = @SubCode1
								   and QO_SubCode2 = @SubCode3
								   and QO_QTID is null
								   and ISNULL(SS_IsDeleted, 0) = 0)
					begin
						update StopSales
						set SS_IsDeleted = 1
						from QuotaObjects
						where SS_QOID = QO_ID
							and QO_SVKey = @SvKey
							and QO_Code = @Code
							and QO_SubCode1 = @SubCode1
							and QO_SubCode2 = @SubCode3
							and QO_QTID is null
							and ISNULL(SS_IsDeleted, 0) = 0
							and SS_Date = @Date
					end
				end
			end	

			-- mark record for update IsProcessed flag
			insert into #processedRecords (EQS_ID)
			values (@id)

			fetch next from ExchangeQuotaStops_cursor into @id, @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @Places, @PartnerKey;		
		end
	
	end try
	begin catch
		set @wasError = 1
		set @errorMessage = error_message()
	end catch

	-- update IsProcessed flag in ExchangeQuotaStops table for processed records
	update ExchangeQuotaStops
	set EQS_IsProcessed = 1
	where EQS_ID in (select EQS_ID from #processedRecords)

	-- release resources
	close ExchangeQuotaStops_cursor;
	deallocate ExchangeQuotaStops_cursor;

	drop table #processedRecords

	-- rethrow error if needed
	if @wasError = 1
	begin
		RAISERROR(@errorMessage, 16, 1)
	end
END
GO

grant exec on [dbo].[ImportExchangeQuotaStops_Bulk] to public
go
/*********************************************************************/
/* end sp_ImportExchangeQuotaStops_Bulk.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwAutobusQuotes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwAutobusQuotes]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwAutobusQuotes]
GO

CREATE PROCEDURE [dbo].[mwAutobusQuotes]
	@Filter varchar(2000),		
	@AgentKey int, 	
	@RequestOnRelease smallint,
	@NoPlacesResult int,
	@CheckAgentQuotes smallint,
	@CheckCommonQuotes smallint,
	@ExpiredReleaseResult int,
	@CountryKeys varchar(2000) = null,
	@CityKey int = null
AS
--<DATE>2014-02-27</DATE>
---<VERSION>9.2.25</VERSION>

if PATINDEX('pt_main', @Filter) <= 0
begin
	if LEN(@Filter) > 0
		set @Filter = @Filter + ' and pt_main > 0 '
	else
		set @Filter = ' pt_main > 0 '
end

---=== СОЗДАНИЕ ВРЕМЕННОЙ ТАБЛИЦЫ ===---
CREATE TABLE #pricesTable
(	
	[TourMessage] varchar (1024) null,
	[CountryKey] [int] NOT NULL,
	[TourDate] [datetime] NULL,
	[TourKey] [int] NULL,
	[TurListKey] [int] NULL,
	[TourDuration] [int] null,--продолжительность тура в днях
	[TourDescription] varchar (2000) null,
	[HotelKey] [int] NULL,
	[HotelKeys] varchar(1024) NULL,
	[HotelPartnerKey] [int] null,
	[HotelDay] [int] null,
	[HotelNights] [int] null,
	[RoomKey] [int] null,
	[RoomCategoryKey] [int] null,
	[RoomCategoryName] [varchar](60) null,	
	[Nights] [int] NULL,	
	[TourName] [varchar](128) NULL,
	[TourTypeKey] [int] NULL,
	[TourTypeName] [varchar] (50) NULL,
	[HotelName] [varchar](60) NULL,		
	[Rate] [varchar](3) NULL,
	[TransportKey] int null,
	[TransferKey] int null,
	[TransferDay] int NULL,
	QuotaPlaces varchar(1024),
	QuotaAllPlaces varchar(1024)
)

declare @rmKey int, @script varchar(8000), @script2 varchar(8000), @mwSearchType int, @rmCount int, @PNames as varchar(4000), @hrKeys varchar(200),
	@cityKeyString as nvarchar(100), @countryKeyString as nvarchar(100)

--временная таблица с нужными типами номеров
--т.е. теми, на которые есть цены
create table #roomKeys (rm_key int null, rm_code varchar(35) null)

create table #minPricesTable (ptCNKey int, ptACKey int, ptRMKey int, ptTourDate datetime, ptTourKey int, ptDays int, ptHDKey int, ptHDKeys varchar(2000), ptHDPartnerKey int,
	ptHDDay int, ptHDNights int, ptRCKey int, ptNights int, ptTourType int, ptPrice float)

--ключи размещений и признак - все ли размещения основные
create table #hrKeysStringsTable (hrkey varchar(200), hrmain int)

--данные из таблиц основной базы
create table #services (tl_tikey int,ts_subcode1 int,ts_code int,ts_day int)

select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) where SS_ParmName = 'MWDivideByCountry'

if (@mwSearchType=0)
begin
	set @script = 'select distinct(pt_hotelroomkeys), 0 from mwPriceDataTable where ' + @Filter
	
	insert into #hrKeysStringsTable exec (@script)
	
	declare cur1 cursor fast_forward for select distinct hrkey from #hrKeysStringsTable
	open cur1
	fetch next from cur1 into @hrKeys
	while @@fetch_status = 0
		begin
			--вставляем данные об основных местах для размещений
			set @script = 'update #hrKeysStringsTable
								set hrmain=(select min(ac_main)
											from Accmdmentype with(nolock)
											where ac_key in(select distinct hr_ackey from hotelRooms where hr_key in(' + @hrKeys + '))
											)
								where hrkey=''' + @hrKeys + ''''
			exec (@script)
			fetch next from cur1 into @hrKeys
		end
	close cur1
	deallocate cur1
	
	delete from #hrKeysStringsTable where hrmain=0
	
	set @script = 'select distinct pt_rmkey,pt_rmcode from mwPriceDataTable where ' + @Filter
	INSERT INTO #roomKeys EXEC(@script)
	
	set @script = 'select pt_cnkey, pt_ackey, pt_rmkey, pt_tourdate, pt_tourkey, pt_days, pt_hdkey, pt_hotelkeys, pt_hdpartnerkey,
					pt_hdday, pt_hdnights, pt_rckey, pt_nights, pt_tourtype, min(pt_price)
					from mwPriceDataTable with (nolock)
					inner join #hrKeysStringsTable on pt_hotelroomkeys=hrkey
					where ' + @Filter + '
					and pt_isEnabled=1
					group by pt_cnkey,pt_rmkey,pt_tourdate,pt_tourkey,pt_days,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,
						pt_hdday,pt_hdnights,pt_rckey,pt_ackey, pt_nights,pt_tourname,pt_tourtype'
	
	INSERT INTO #minPricesTable EXEC(@script)
	
	select @rmCount = count(rm_key) from #roomKeys
	
	if(@rmCount = 0)
		return
	
	declare roomCursor cursor for
		select rm_key from #roomKeys order by rm_key
	
	--добавляем колонки типов номеров в темповую таблицу
	OPEN roomCursor
	FETCH NEXT FROM roomCursor INTO @rmKey
	while @@fetch_status = 0
		begin
			set @script = 'alter table #pricesTable add rmkey_' +  convert(varchar,@rmKey) + ' int, pr_' + convert(varchar,@rmKey) + ' int' 
			
			exec (@script)
			FETCH NEXT FROM roomCursor INTO @rmKey
		end
	close roomCursor
	deallocate roomCursor
	
	-- Cобираем колонки типов номеров для запроса
	set @PNames = ''
	
	select @PNames = @PNames + ',' + '0 as ''rmkey_' + convert(varchar,rm_key) + ''',
		max(case when pt_rmkey = ' + convert(varchar,rm_key) + ' then pt_pricekey else 0 end) as ''pr_' + convert(varchar,rm_key) + ''''
		from #roomKeys
		order by rm_key
	
	set @PNames = substring(@PNames, 2, len(@PNames))
	
	set @script =
		'select '''' as TourMessage,pt_cnkey,pt_tourdate,pt_tourkey,pt_tlkey,pt_days,TL_DESCRIPTION,pt_hdkey,pt_hotelkeys,
			pt_hdpartnerkey,pt_hdday,pt_hdnights,pt_rmkey,pt_rckey,rc_name,pt_nights,pt_tourname,pt_tourtype,tp_name,pt_hdname,pt_rate,ts_subcode1,ts_code,ts_day,-1,-1,'+ @PNames + '
		from mwpricedatatable with(nolock)
		inner join #hrKeysStringsTable on pt_hotelroomkeys=hrkey
		inner join tiptur with(nolock) on pt_tourtype = tp_key
		inner join turlist with(nolock) on pt_tlkey = tl_key
		inner join roomscategory with(nolock) on pt_rckey = rc_key '
		
		if (((select dbo.mwReplIsSubscriber()) = 0) and (select dbo.mwReplIsPublisher()) = 0)
				begin
					set @script = @script
						+ '
						inner join tp_servicelists with(nolock) on tl_tikey = pt_pricelistkey
						inner join tp_services with(nolock) on ts_key = tl_tskey and ts_svkey = 2'
				end
				else
				begin
					set @script2 = '
						select tl_tikey,ts_subcode1,ts_code,ts_day from mt.' + dbo.mwReplPublisherDB() + '.dbo.tp_servicelists with(nolock)
						inner join mt.' + dbo.mwReplPublisherDB() + '.dbo.tp_services with(nolock) on ts_key = tl_tskey and ts_svkey = 2'
					
					insert into #services exec(@script2)
					
					set @script = @script + '
					inner join #services on #services.tl_tikey=pt_pricelistkey'
				end
		
		set @script = @script + '
		where ' + @Filter + '
		and exists(select top 1 1 from #minPricesTable
					where pt_rmkey=ptrmkey
					and pt_cnkey=ptcnkey
					and pt_ackey=ptackey
					and pt_tourdate=pttourdate
					and	pt_tourkey=pttourkey
					and pt_days=ptdays
					and pt_hdkey=pthdkey
					and pt_hdpartnerkey=pthdpartnerkey
					and pt_hdday=pthdday
					and pt_hdnights=pthdnights
					and	pt_rckey=ptrckey
					and pt_days=ptdays
					and pt_nights=ptnights
					and	pt_price=ptprice)
		and pt_isEnabled=1
		group by pt_cnkey,pt_tourdate,pt_tourkey,pt_tlkey,pt_days,TL_DESCRIPTION,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,pt_hdday,pt_hdnights,
			pt_rckey,rc_name,pt_ackey,pt_rmkey,pt_nights,pt_tourname,pt_tourtype,tp_name,pt_hdname,pt_rate,ts_subcode1,ts_code,ts_day
		order by pt_tourdate, pt_days, tp_name'
	
	INSERT INTO #pricesTable EXEC(@script)
end
else
begin
	declare @now datetime
	
	declare @tableNameString as nvarchar(100), @countryKey int
	
	create table #tables (tableName varchar(200))
	create table #countryKeys (cnkey int)
	
	if (@CountryKeys is not null)
	begin
		insert into #countryKeys select distinct * from dbo.ParseKeys(@CountryKeys)
	end
	else
	begin
		insert into #countryKeys select distinct to_cnkey from tp_tours where to_isEnabled=1
	end
	
	if (@cityKey is null or @cityKey=0)
		begin
			set @cityKeyString = '%'
		end
		else
		begin
			set @cityKeyString = CAST(@cityKey as varchar(100))
		end
	
	declare cur1 cursor fast_forward for select distinct cnkey from #countryKeys
	open cur1
	fetch next from cur1 into @countryKey
	while @@fetch_status = 0
	begin
		if (@countryKey is null or @countryKey=0)
		begin
			set @countryKeyString = '%'
		end
		else
		begin
			set @countryKeyString = CAST(@countryKey as varchar(100))
		end
		
		set @script = 'select distinct rtrim(name) from sys.tables where name like ''mwPriceDataTable_' + @countryKeyString + '_' + @cityKeyString + ''''
		
		insert into #tables exec(@script)
		
		fetch next from cur1 into @countryKey
	end
	close cur1
	deallocate cur1
	
	declare cur0 cursor fast_forward for select distinct tableName from #tables
	open cur0
	fetch next from cur0 into @tableNameString
	while @@FETCH_STATUS = 0
	begin
		set @script = 'select distinct pt_rmkey,pt_rmcode from ' + @tableNameString + ' where not exists(select top 1 1 from #roomKeys where rm_key=pt_rmkey) and ' + @Filter
		
		INSERT INTO #roomKeys EXEC(@script)
		
		declare roomCursor cursor for
				select rm_key from #roomKeys order by rm_key
		
		--добавляем колонки типов номеров в темповую таблицу
		OPEN roomCursor
		FETCH NEXT FROM roomCursor INTO @rmKey
		while @@fetch_status = 0
			begin
				set @script = 'alter table #pricesTable add rmkey_' +  convert(varchar,@rmKey) + ' int, pr_' + convert(varchar,@rmKey) + ' int'
				begin try
					exec (@script)
				end try
				begin catch
					print 'Column already added'
				end catch
				FETCH NEXT FROM roomCursor INTO @rmKey
			end
		close roomCursor
		deallocate roomCursor
		
		fetch next from cur0 into @tableNameString
	end
	close cur0
	deallocate cur0
	
	-- Cобираем колонки типов номеров для запроса
	set @PNames = ''
	
	select @PNames = @PNames + ',
		' + '0 as ''rmkey_' + convert(varchar,rm_key) + ''',max(case when pt_rmkey = ' + convert(varchar,rm_key) + ' then pt_priceKey else 0 end) as ''pr_' + convert(varchar,rm_key) + ''''
		from #roomKeys
		order by rm_key
	
	set @PNames = substring(@PNames, 2, len(@PNames))
	
	declare cur2 cursor fast_forward for select distinct tableName from #tables
	open cur2
	fetch next from cur2 into @tableNameString
	while @@FETCH_STATUS = 0
	begin
		delete from #hrKeysStringsTable
	
		set @script = 'select distinct(pt_hotelroomkeys), 0 from ' + @tableNameString + ' where ' + @Filter
	
		insert into #hrKeysStringsTable exec (@script)
		
		declare cur1 cursor fast_forward for select distinct hrkey from #hrKeysStringsTable
		open cur1
		fetch next from cur1 into @hrKeys
		while @@fetch_status = 0
			begin
				--вставляем данные об основных местах для размещений
				set @script = 'update #hrKeysStringsTable
									set hrmain=(select min(ac_main)
												from Accmdmentype with(nolock)
												where ac_key in(select distinct hr_ackey from hotelRooms where hr_key in(' + @hrKeys + '))
												)
									where hrkey=''' + @hrKeys + ''''
				exec (@script)
				fetch next from cur1 into @hrKeys
			end
		close cur1
		deallocate cur1
		
		delete from #hrKeysStringsTable where hrmain=0
		
		select @rmCount = count(rm_key) from #roomKeys
		
		if(@rmCount <> 0)
		begin
			delete from #minPricesTable
		
			set @script = 'select pt_cnkey,pt_ackey,pt_rmkey,pt_tourdate,pt_tourkey,pt_days,pt_hdkey,pt_hotelkeys,
								pt_hdpartnerkey,pt_hdday,pt_hdnights,pt_rckey,pt_nights,pt_tourtype,min(pt_price)
							from ' + @tableNameString + ' with(nolock)
							where ' + @Filter + '
							and exists(select top 1 1 from #hrKeysStringsTable where pt_hotelroomkeys=hrkey)
							and pt_isEnabled=1
							group by pt_cnkey,pt_rmkey,pt_tourdate,pt_tourkey,pt_days,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,
								pt_hdday,pt_hdnights,pt_rckey,pt_ackey, pt_nights,pt_tourname,pt_tourtype'
			
			INSERT INTO #minPricesTable EXEC(@script)

			set @script =
				'select '''' as TourMessage,pt_cnkey,pt_tourdate,pt_tourkey,pt_tlkey,pt_days,TL_DESCRIPTION,pt_hdkey,pt_hotelkeys,
					pt_hdpartnerkey,pt_hdday,pt_hdnights,pt_rmkey,pt_rckey,rc_name,pt_nights,pt_tourname,pt_tourtype,tp_name,pt_hdname,pt_rate,ts_subcode1,ts_code,ts_day,-1,-1,'+ @PNames + '
				from ' + @tableNameString + ' with(nolock)
				inner join tipTur with(nolock) on pt_tourtype = tp_key
				inner join turList with(nolock) on pt_tlkey = tl_key
				inner join roomsCategory with(nolock) on pt_rckey = rc_key '
				
				if (((select dbo.mwReplIsSubscriber()) = 0) and (select dbo.mwReplIsPublisher()) = 0)
				begin
					set @script = @script
						+ '
						inner join tp_servicelists with(nolock) on tl_tikey = pt_pricelistkey
						inner join tp_services with(nolock) on ts_key = tl_tskey and ts_svkey = 2'
				end
				else
				begin
					set @script2 = null
					
					if (@CountryKeys is not null)
					begin
						set @script2 = ' where ts_cnkey in (' + @CountryKeys + ')'
					end
					
					set @script2 = 'select tl_tikey,ts_subcode1,ts_code,ts_day from mt.' + dbo.mwReplPublisherDB() + '.dbo.tp_servicelists with(nolock)
						inner join mt.' + dbo.mwReplPublisherDB() + '.dbo.tp_services with(nolock) on ts_key = tl_tskey and ts_svkey = 2 ' + isnull(@script2,'')

					insert into #services exec(@script2)
					
					set @script = @script + '
					inner join #services on #services.tl_tikey=pt_pricelistkey'
				end
				
				set @script = @script + '
				where ' + @Filter + '
				and exists(select top 1 1 from #minPricesTable
							where pt_rmkey=ptrmkey
							and pt_cnkey=ptcnkey
							and pt_ackey=ptackey
							and pt_tourdate=pttourdate
							and	pt_tourkey=pttourkey
							and pt_days=ptdays
							and pt_hdkey=pthdkey
							and pt_hdpartnerkey=pthdpartnerkey
							and pt_hdday=pthdday
							and pt_hdnights=pthdnights
							and	pt_rckey=ptrckey
							and pt_days=ptdays
							and pt_nights=ptnights
							and	pt_price=ptprice)
				and pt_isEnabled=1
				group by pt_cnkey,pt_tourdate,pt_tourkey,pt_tlkey,pt_days,TL_DESCRIPTION,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,
					pt_hdday,pt_hdnights,pt_rckey,rc_name,pt_ackey,pt_rmkey,pt_nights,pt_tourname,pt_tourtype,tp_name,pt_hdname,pt_rate,ts_subcode1,ts_code,ts_day
				order by pt_tourdate, pt_days, tp_name'
			
			INSERT INTO #pricesTable EXEC(@script)
		end
		fetch next from cur2 into @tableNameString
	end
	close cur2
	deallocate cur2
end

-- Формируем скрипт, заполняющий стоимость по ключу цены
declare @update_price as varchar(4000)
set @update_price = ''

select @update_price = @update_price + 'update #pricesTable set rmkey_' + convert(varchar,rm_key) + ' = TP_Gross from TP_Prices where tp_key = pr_' + convert(varchar,rm_key) + '; '
	from #roomKeys order by rm_key

exec (@update_price)

declare	@HotelKey int, @HotelKeys VARCHAR(1024), @RoomKey int, @RoomCategoryKey int, @FromDate datetime, @HotelPartnerKey int, @HotelDay int,
	@HotelNights int, @TourDuration int, @TourKey int, @TourMessage varchar (1024), @TurListKey int

DECLARE hSql CURSOR
	FOR
		SELECT HotelKey, HotelKeys, RoomKey, RoomCategoryKey,TourDate,HotelPartnerKey,HotelDay,HotelNights,TourDuration,TourKey,TourMessage,TurListKey FROM #pricesTable
	FOR UPDATE OF QuotaPlaces, QuotaAllPlaces, TourMessage

OPEN hSql
FETCH NEXT FROM hSql INTO @HotelKey, @HotelKeys, @RoomKey, @RoomCategoryKey, @FromDate, @HotelPartnerKey, @HotelDay,@HotelNights,@TourDuration,@TourKey,@TourMessage,@TurListKey

declare @qt_places int, @qt_allplaces int, @qt_tourMessage varchar (1024)

WHILE @@FETCH_STATUS = 0
BEGIN	      

	DECLARE @idx INT = 1      
	DECLARE @delimiter CHAR = ','
	DECLARE @slice VARCHAR(1024)
	DECLARE @quotas VARCHAR(1024) = ''
	DECLARE @allQuotas VARCHAR(1024) = ''
	DECLARE @hotelKeysVar VARCHAR(1024) = @HotelKeys
	DECLARE @curHotelKey as int
	
	WHILE @idx != 0       
	BEGIN       
		SET @idx = CHARINDEX(@delimiter, @hotelKeysVar)       
		IF @idx != 0       
			SET @slice = LEFT(@hotelKeysVar, @idx - 1)       
		ELSE       
			SET @slice = @hotelKeysVar    
			   
		SET @curHotelKey = CAST(@slice AS INT)

		SELECT TOP 1 @qt_places = qt_places, @qt_allplaces = qt_allplaces 
					 from mwCheckQuotesEx(3, @curHotelKey, @RoomKey, 
										  @RoomCategoryKey, @AgentKey, 
										  @HotelPartnerKey, @FromDate, 
										  @HotelDay, @HotelNights, 
										  @RequestOnRelease, @NoPlacesResult, 
										  @CheckAgentQuotes, @CheckCommonQuotes, 
										  1, 0, 0, 0, 0, 
										  @TourDuration, @ExpiredReleaseResult)		       
		if LEN(@quotas) > 0
			SET @quotas = @quotas + ',' + cast(@qt_places as VARCHAR(1024))
		else
			SET @quotas = cast(@qt_places as VARCHAR(1024))
		
		if LEN(@allQuotas) > 0
			SET @allQuotas = @allQuotas + ',' + cast(@qt_allplaces as VARCHAR(1024))
		else
			SET @allQuotas = cast(@qt_allplaces as VARCHAR(1024))
			 
			 
		set @hotelKeysVar = RIGHT(@hotelKeysVar, LEN(@hotelKeysVar) - @idx)       
		if LEN(@hotelKeysVar) = 0 break       
	END 
	
	 -- MEG00030302. Golubinsky. 07.06.2011
	SET @qt_tourMessage = ''
	SELECT TOP 1 @qt_tourMessage = MS_Text
	FROM [Messages] with (nolock) WHERE (( @FromDate between MS_ServiceDateBeg AND MS_ServiceDateEnd) AND MS_IsDeleted IS NULL OR MS_IsDeleted = 0) AND MS_LGId IN
			(SELECT DISTINCT LM_LGId FROM LimitationGroups, Limitations, LimitationTours WITH (NOLOCK)
				WHERE LM_ID = LD_LMId AND LG_ID = LM_LGId AND LD_TRKey = @TurListKey)
	ORDER BY MS_ServiceDateBeg, MS_ServiceDateEnd ASC
	-- MEG00030302 end
	
	UPDATE #pricesTable SET QuotaPlaces = @quotas, QuotaAllPlaces = @allQuotas, TourMessage = @qt_tourMessage
		WHERE current of hSql
	
	FETCH NEXT FROM hSql INTO @HotelKey, @HotelKeys, @RoomKey, @RoomCategoryKey, @FromDate, @HotelPartnerKey, @HotelDay,@HotelNights,@TourDuration,@TourKey,@TourMessage,@TurListKey
END
CLOSE hSql
DEALLOCATE hSql

select * from #pricesTable

drop table #pricesTable
drop table #roomKeys
drop table #minPricesTable
drop table #hrKeysStringsTable
GO

grant exec on [dbo].[mwAutobusQuotes] to public
GO
/*********************************************************************/
/* end sp_mwAutobusQuotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCleaner.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCleaner]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwCleaner]
GO

create proc [dbo].[mwCleaner] @priceCount int = 1000000, @deleteToday smallint = 0
as
begin
	--<DATE>2013-07-31</DATE>
	--<VERSION>9.2.20.1</VERSION>
	declare @counter bigint
	declare @deletedRowCount bigint

	insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Запуск mwCleaner', 1)

	declare @today datetime
	set @today = getdate()
	if (@deleteToday <> 1)
	begin
		set @today = dateadd(day, -1, @today)
	end

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReplDeletedPricesTemp]') AND type in (N'U'))
	begin
		delete from mwReplDeletedPricesTemp
		where rdp_date < DATEADD(day, -3, @today)

		if not exists(select top 1 1 from mwReplDeletedPricesTemp)
		begin
			if (dbo.mwReplIsSubscriber() <= 0)
				DBCC CHECKIDENT('mwReplDeletedPricesTemp', RESEED, 0)
			else
				truncate table mwReplDeletedPricesTemp
		end
	end

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Megatec_StateDataPaging]') AND type in (N'U'))
	begin
		while (1 = 1)
		begin
			delete top (@priceCount) from Megatec_StateDataPaging
			where SDP_Date < DATEADD(MONTH, -1, @today)	

			if (@@ROWCOUNT = 0)
				break
		end
	end

	if dbo.mwReplIsSubscriber() > 0 or dbo.mwReplIsPublisher() = 0
	begin
	truncate table CacheQuotas
	end
	
	if dbo.mwReplIsSubscriber() <= 0
	begin
		-- очистка таблиц только на основной базе в случае репликации или если репликации нет

		-- Удаляем записи из таблицы TP_ServiceTours, если таких туров больше нету
		-- Тут количество записей будет не большим, поэтому можно не делить на пачки, туры удаляются редко в ДЦ
		SELECT ST_Id 
		into #Keys
		FROM TP_ServiceTours with(nolock)
		where not exists (select top 1 1 from TP_Tours with(nolock) where TO_Key = ST_TOKey)
		and st_tokey not in (select CP_PriceTourKey from CalculatingPriceLists with(nolock) where CP_StartTime is not null)
	
		delete TP_ServiceTours WHERE ST_Id in (select x.ST_Id from #Keys as x)
	
		drop table #Keys
	
		-- Удаляем неактуальные цены
		set @counter = 0
		while(1 = 1)
		begin
	
			delete 
			from dbo.tp_prices with(rowlock) 
			where tp_key in (SELECT top (@priceCount/10) tp_key 
							 from dbo.tp_prices with(nolock) 
							 WHERE tp_dateend < @today 
								   and tp_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
								   and tp_tokey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null) --за исключением отложенного расчета
							)
					
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_prices завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
				--print 'Удаление tp_prices завершено. Удалено ' + ltrim(str(@counter)) + ' записей'
				break
			end
			else
			begin
				print 'Удалено из tp_prices ' + ltrim(str(@deletedRowCount)) + ' записей'
				set @counter = @counter + @deletedRowCount
			end
		end

		-- Удаляем неактуальные удаленные цены из TP_PricesDeleted (ДЦ)
		set @counter = 0
		while(1 = 1)
		begin
			delete 
			from dbo.tp_pricesDeleted with(rowlock) 
			where tpd_id in (select top (@priceCount/5) tpd_id 
							 from dbo.tp_pricesDeleted with(nolock)
							 where tpd_dateend < @today 
								   and tpd_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
								   and tpd_tokey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null) --за исключением отложенного расчета
			)
		
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_pricesDeleted завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
				print 'Удаление tp_pricesDeleted завершено. Удалено ' + ltrim(str(@counter)) + ' записей'
				break
			end
			else
			begin
				print 'Удалено из tp_pricesDeleted ' + ltrim(str(@deletedRowCount)) + ' записей'
				set @counter = @counter + @deletedRowCount
			end
		end	
	
		-- Удаляем неактуальные удаленные цены из TP_PriceComponents (ДЦ)
		set @counter = 0
		while(1 = 1)
		begin
			delete 
			from dbo.TP_PriceComponents with(rowlock) 
			where PC_ID in (SELECT top (@priceCount/50) PC_ID 
							FROM dbo.TP_PriceComponents with(nolock) 
							WHERE PC_TourDate < @today
							and pc_tokey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null) --за исключением отложенного расчета
			)
		
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление TP_PriceComponents завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
				--print 'Удаление TP_PriceComponents завершено. Удалено ' + ltrim(str(@counter)) + ' записей'
				break
			end
			else
			begin
				print 'Удалено из TP_PriceComponents ' + ltrim(str(@deletedRowCount)) + ' записей'
				set @counter = @counter + @deletedRowCount
			end			
		end	
	
		-- Удаляем неактуальные удаленные цены из TP_ServiceCalculateParametrs (ДЦ)
		set @counter = 0
		while(1 = 1)
		begin
			delete 
			from dbo.TP_ServiceCalculateParametrs with(rowlock) 
			where SCP_ID in (select top (@priceCount) SCP_ID 
							 from dbo.TP_ServiceCalculateParametrs 
							 WHERE SCP_DateCheckIn < @today)
						 
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление TP_ServiceCalculateParametrs завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
				break
			end
			else
				set @counter = @counter + @deletedRowCount
		end	
	end

	-- Удаляем неактуальные удаленные цены из tp_turdates
	set @counter = 0
	while (1 = 1)
	begin
		delete 
		from dbo.tp_turdates with(rowlock) 
		where td_key in (select top (@priceCount/10) td_key 
							from dbo.tp_turdates with(nolock) 
							where td_date < @today 
							and td_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
							and td_tokey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null) --за исключением отложенного расче
		)
			
		set @deletedRowCount = @@ROWCOUNT
		if @deletedRowCount = 0
		begin
			insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_turdates завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
			break
		end
		else
			set @counter = @counter + @deletedRowCount
	end
		
	if dbo.mwReplIsSubscriber() <= 0
	begin
		-- tp_servicelists, tp_lists, tp_services		
		create table #tikeys (tikey int, tokey int)
		CREATE NONCLUSTERED INDEX [IX_Index1]
		ON #tikeys ([tokey])
		INCLUDE ([tikey])

		declare @toKey int
		declare tourCursor cursor local fast_forward for
		select to_key
		from tp_tours with(nolock)
		where TO_Key not in (select CP_PriceTourKey from CalculatingPriceLists with(nolock) where CP_StartTime is not null)
		and TO_Key not in (select to_key from tp_tours with(nolock) where to_update <> 0)
		order by to_key desc

		set @counter = 0

		open tourCursor
		fetch tourCursor into @toKey
		while (@@FETCH_STATUS = 0)
		begin
			insert into #tikeys 
			select ti_key, ti_tokey 
			from dbo.tp_lists with(nolock) 
			where not exists (select 1 from tp_prices with(nolock) where ti_key = tp_tikey and tp_tokey = TI_TOKey)
			and not exists (select 1 from TP_PricesDeleted with(nolock) where ti_key = tpd_tikey and tpd_tokey = TI_TOKey)
			and ti_tokey = @toKey

			delete 
			from dbo.tp_servicelists
			where exists (select 1 from #tikeys where tikey = TL_TIKey and tokey = TL_TOKey)
			and tl_tokey = @toKey

			set @counter = @counter + @@ROWCOUNT

			delete 
			from dbo.tp_lists with(rowlock) 
			where ti_key in (select tikey from #tikeys where tokey = TI_TOKey) 
			and ti_tokey = @toKey

			set @counter = @counter + @@ROWCOUNT

			delete 
			from dbo.tp_services 
			where TS_Key not in (select TL_TSKey from TP_ServiceLists with(nolock) where TL_TOKey = TS_TOKey)
			and TS_TOKey = @toKey

			set @counter = @counter + @@ROWCOUNT

			truncate table #tikeys

			fetch tourCursor into @toKey
		end
		close tourCursor
		deallocate tourCursor

		drop table #tikeys

		insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_servicelists, tp_lists, tp_services завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)		
	end
	else
	begin
		exec dbo.mwClearOldData
	end

	declare @mwSearchType int
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'
	
	if dbo.mwReplIsSubscriber() <= 0
	begin
		-- Удаляем неактуальные туры
		set @counter = 0
		while(1 = 1)
		begin

			delete 
			from dbo.TP_Tours with(rowlock) 
			where to_key in (SELECT TOP 1 TO_Key 
							 FROM TP_Tours 
							 WHERE to_datevalid < @today
							 and to_key not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null) --за исключением отложенного расчета
			)
			
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление TP_Tours завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)		
				break
			end
			else
				set @counter = @counter + @deletedRowCount
		end

		create table #tours
		(
			xKey int identity(1,1),
			xToKey int
		)
	
		insert into #tours (xToKey)
		select TO_Key
		from tp_tours with(nolock) where to_update = 0 and exists(select top 1 1 from dbo.tp_turdates with(nolock) where td_tokey = to_key and td_date < @today)

		declare @currentKey int, @maxKey int
		set @currentKey = 0
		select @maxKey = MAX(xKey) from #tours
		while (@currentKey < @maxKey)
		begin
			set @currentKey = @currentKey + 1
		
			update dbo.tp_tours
			set to_pricecount = (select count(1) from dbo.tp_prices with(nolock) where tp_tokey = to_key), 
				to_updatetime = getdate()
			where to_key = (select xToKey from #tours where xKey = @currentKey)
		
		end
	
		drop table #tours
		insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Обновление tp_tours завершено. Обновлено ' + ltrim(@deletedRowCount) + ' записей', 1)
	end

	if dbo.mwReplIsPublisher() <= 0
	begin

		if exists(select 1 from mwReplQueue with(nolock) where rq_tokey not in (select to_key from tp_tours with(nolock)) and rq_mode <> 4)
		begin
			delete 
			from mwReplQueue
			where rq_tokey not in (select to_key from tp_tours with(nolock))
			and rq_mode <> 4
		end

		if(@mwSearchType = 0)
		begin
			set @counter = 0
			while(1 = 1)
			begin
				delete top (@priceCount) from dbo.mwPriceDataTable with(rowlock) where pt_tourdate < @today and pt_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
							and pt_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null) --за исключением отложенного расчета
				set @deletedRowCount = @@ROWCOUNT
				if @deletedRowCount = 0
				begin
					insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление mwPriceDataTable завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)	
					break
				end
				else
					set @counter = @counter + @deletedRowCount
			end
			
			set @counter = 0
			while(1 = 1)
			begin
				delete top (@priceCount) from dbo.mwSpoDataTable with(rowlock) where sd_tourkey not in (select pt_tourkey from dbo.mwPriceDataTable with(nolock)) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
							and sd_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null) --за исключением отложенного расчета
				set @deletedRowCount = @@ROWCOUNT
				if @deletedRowCount = 0
				begin
					insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление mwSpoDataTable завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)	
					break
				end
				else
					set @counter = @counter + @deletedRowCount
			end
			
			set @counter = 0
			while(1 = 1)
			begin
				delete top (@priceCount) from dbo.mwPriceDurations with(rowlock) where not exists(select 1 from dbo.mwPriceDataTable with(nolock) where pt_tourkey = sd_tourkey and pt_days = sd_days and pt_nights = sd_nights) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
							and sd_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null) --за исключением отложенного расчета
				set @deletedRowCount = @@ROWCOUNT
				if @deletedRowCount = 0
				begin
					insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление mwPriceDurations завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)	
					break
				end
				else
					set @counter = @counter + @deletedRowCount
			end
		end
		else
		begin
			declare @objName nvarchar(50), @counterPart int
			declare @sql nvarchar(500), @params nvarchar(500)
			declare delCursor cursor fast_forward read_only for select distinct sd_cnkey, sd_ctkeyfrom from dbo.mwSpoDataTable
			declare @cnkey int, @ctkeyfrom int
			open delCursor
			fetch next from delCursor into @cnkey, @ctkeyfrom
			while(@@fetch_status = 0)
			begin
				set @objName = dbo.mwGetPriceTableName(@cnkey, @ctkeyfrom)
				set @counter = 0
				while(1 = 1)
				begin
					set @sql = 'delete top (' + ltrim(rtrim(str(@priceCount))) + ') from ' + @objName + ' with(rowlock) where pt_tourdate < @today and pt_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0) and pt_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null); set @counterOut = @@ROWCOUNT'
					set @params = '@today datetime, @counterOut int output'
				
					EXECUTE sp_executesql @sql, @params, @today = @today, @counterOut = @counterPart output
				
					if @counterPart = 0
					begin
						insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление ' + @objName + ' завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)	
						break
					end
					else
						set @counter = @counter + @counterPart
				end

				set @counter = 0
				while(1 = 1)
				begin
					set @sql = 'delete top (' + ltrim(rtrim(str(@priceCount))) + ') from dbo.mwSpoDataTable with(rowlock) where sd_cnkey = ' + ltrim(rtrim(str(@cnkey))) + ' and sd_ctkeyfrom = ' + ltrim(rtrim(str(@ctkeyfrom))) + ' and sd_tourkey not in (select pt_tourkey from ' + @objName + ' with(nolock)) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0) and sd_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null); set @counterOut = @@ROWCOUNT'
					set @params = '@counterOut int output'
					EXECUTE sp_executesql @sql, @params, @counterOut = @counterPart output
				
					if @counterPart = 0
					begin
						insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление mwSpoDataTable завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)	
						break
					end
					else
						set @counter = @counter + @counterPart
				end
				fetch next from delCursor into @cnkey, @ctkeyfrom
			end
			close delCursor
			deallocate delCursor
		end
	
		set @counter = 0
		while(1 = 1)
		begin
			delete top (@priceCount) from dbo.mwPriceHotels with(rowlock) where sd_tourkey not in (select sd_tourkey from dbo.mwSpoDataTable with(nolock)) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
						and sd_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null)
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление mwPriceHotels завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
				break
			end
			else
				set @counter = @counter + @deletedRowCount
		end
	end

	-- Удаляем неактуальные логи (остаются логи за последние 7 дней)
	set @counter = 0
	while(1 = 1)
	begin
		delete top (@priceCount) from dbo.SystemLog with(rowlock) where SL_DATE < DATEADD(day, -7, @today)
		set @deletedRowCount = @@ROWCOUNT
		if @deletedRowCount = 0
		begin
			insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление systemLog завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
			break
		end
		else
			set @counter = @counter + @deletedRowCount
	end

	insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Окончание выполнения mwCleaner', 1)
end
GO

grant exec on dbo.mwCleaner to public
GO
/*********************************************************************/
/* end sp_mwCleaner.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwHotelQuotes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwHotelQuotes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mwHotelQuotes]

GO
CREATE PROCEDURE [dbo].[mwHotelQuotes]
	(
		-- хранимка получает сведения о квотах для отелей
		--<version>2009.2.22</version>
		--<date>2014-02-24</date> 
		@Filter varchar(2000),
		@DaysCount int,
		@AgentKey int, 
		@FromDate	datetime,
		@RequestOnRelease smallint,
		@NoPlacesResult int,
		@CheckAgentQuotes smallint,
		@CheckCommonQuotes smallint,
		@ExpiredReleaseResult int
	)
AS
BEGIN

-- создание временной таблицы
CREATE TABLE #tmp
(
	CityKey int,
	CityName varchar(50) COLLATE Cyrillic_General_BIN,
	HotelKey int,
	HotelName varchar(200) COLLATE Cyrillic_General_BIN,
	HotelHTTP varchar(254),
	RoomKey int,
	RoomName varchar(35) COLLATE Cyrillic_General_BIN,
	RoomCategoryKey int,
	RoomCategoryName varchar(60) COLLATE Cyrillic_General_BIN,
	Quotas varchar(2000),
	HotelRoomsKey int,
	HotelRoomsMain int
)

-- формирование данных
DECLARE	@HotelKey int
DECLARE	@RoomKey int 
DECLARE	@RoomCategoryKey int 
DECLARE @HotelRoomsKey int
DECLARE @HotelRoomsMain int
DECLARE @freePlacesMask int

DECLARE @script VARCHAR(4000)
SET @script = 'SELECT DISTINCT SD_CTKEY, SD_CTNAME, mwSpoDataTable.SD_HDKEY, SD_HDNAME  + '' ('' + ISNULL(SD_RSNAME, SD_CTNAME) + '') '' + mwSpoDataTable.SD_HDSTARS as HotelName,
				ISNULL(HD_HTTP, ''''), SD_RMKEY, RM_NAME, SD_RCKEY, RC_NAME, '''', HR_Key, HR_Main
	FROM mwPriceHotels with(nolock)
		JOIN mwSpoDataTable with(nolock) ON mwPriceHotels.PH_SDKEY = mwSpoDataTable.SD_KEY
		JOIN Rooms with(nolock) ON SD_RMKEY = RM_KEY		
		JOIN RoomsCategory with(nolock) ON SD_RCKEY = RC_KEY
		JOIN HotelDictionary with(nolock) ON mwSpoDataTable.SD_HDKEY = HD_KEY
		JOIN HotelRooms with(nolock) ON (SD_HRKey = HR_Key)
		WHERE ' + @filter + ' ORDER BY HotelName'
		
INSERT INTO #tmp EXEC(@script)

DECLARE hSql CURSOR local fast_forward for
	SELECT distinct HotelKey, RoomKey, RoomCategoryKey FROM #tmp

OPEN hSql
FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey

WHILE @@FETCH_STATUS = 0
BEGIN
	Declare @result varchar(256), @places int, @step_index smallint, @price_correction int, @additional varchar(2000), @findFlight smallint
	
	exec mwCacheQuotaSearch 3,@HotelKey,@RoomKey,@RoomCategoryKey,@FromDate,1,@DaysCount,0,0,@result output,@places output,@step_index output,
		@price_correction output,@additional output,0
	
	if (@result is not null)
	begin
		Update #tmp SET Quotas = @result where current of hSql
	end
	else
	begin
		select top 1 @result = qt_additional
									from mwCheckQuotesEx(3, @HotelKey, @RoomKey, @RoomCategoryKey, @AgentKey, -1, @FromDate, 1, @DaysCount,
									@RequestOnRelease, @NoPlacesResult, @CheckAgentQuotes, @CheckCommonQuotes, 1, 0, 0, 0, 0, -1, @ExpiredReleaseResult)
		
		UPDATE #tmp SET Quotas = @result where HotelKey = @HotelKey and RoomKey = @RoomKey and RoomCategoryKey = @RoomCategoryKey
	end
	
	FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey
END
CLOSE hSql
DEALLOCATE hSql

SELECT DISTINCT CityKey, CityName, HotelKey, HotelName, HotelHTTP, RoomKey, RoomName, RoomCategoryKey, RoomCategoryName, Quotas, min(HotelRoomsKey)
FROM #tmp
GROUP BY CityKey, CityName, HotelKey, HotelName, HotelHTTP, RoomKey, RoomName, RoomCategoryKey, RoomCategoryName, Quotas

-- удаление временной таблицы
DROP TABLE #tmp

END

GO
grant exec on [dbo].[mwHotelQuotes] to public
go
/*********************************************************************/
/* end sp_mwHotelQuotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplDisablePriceTour.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwReplDisablePriceTour')
	drop proc dbo.[mwReplDisablePriceTour]
go

create proc [dbo].[mwReplDisablePriceTour] @tourkey int, @rqId int = null
as
begin
	-- <date>2014-02-28</date>
	-- <version>9.2.1</version>

	declare @mwSearchType int
	select @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
		where SS_ParmName = 'MWDivideByCountry'

	if @mwSearchType = 0
	begin
		if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwPriceDataTable.'
			
		update mwPriceDataTable
		set pt_isenabled = 0
		where pt_tourkey = @tourkey
	end
	else
	begin
		declare @tableName varchar(100), @tokey int, @cnkey int
		declare @sql varchar(8000)

		select top 1 
			@tokey = to_key, 
			@cnkey = to_cnkey
		from 
			tp_tours with(nolock)
		where to_key = @tourkey

		DECLARE @cityFromKey INT
		DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT distinct sd_ctkeyfrom FROM mwSpoDataTable with (nolock) WHERE sd_tourkey = @tokey AND sd_isenabled > 0
		OPEN cur
		FETCH NEXT FROM cur INTO @cityFromKey
		WHILE @@fetch_status = 0
		BEGIN 
			set @tableName = dbo.mwGetPriceTableName(@cnkey, @cityFromKey)	
			if (@rqId is not null)
				insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwPriceDataTable.'
				
			IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(@tableName) AND type in (N'U'))	
			BEGIN
				set @sql = 'update ' + @tableName + ' set pt_isenabled = 0 where pt_tourkey = ' + ltrim(str(@tokey))
				exec (@sql)
			END
			FETCH NEXT FROM cur INTO @cityFromKey
		END	
		CLOSE cur
		DEALLOCATE cur
	end

	if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwSpoDataTable.'
			
	update mwSpoDataTable
	set sd_isenabled = 0	
	where sd_tourkey = @tourkey
end
GO

grant exec on [dbo].[mwReplDisablePriceTour] to public

GO
/*********************************************************************/
/* end sp_mwReplDisablePriceTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplProcessQueueDivide.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReplProcessQueueDivide]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwReplProcessQueueDivide]
GO

create procedure [dbo].[mwReplProcessQueueDivide] 
(
	@jobId smallint = null,
	@countryKeysToProcess ListIntValue readonly,		-- ключи стран, которые должны обрабатываться (берутся только переданные страны)
	@countryKeysToNotProcess ListIntValue readonly	-- ключи стран, которые не должны обрабатываться (берутся все, кроме переданных стран)
	-- если переданы одновременно @countryKeysToProcess и @countryKeysToNotProcess, то произойдет ошибка
)
as
begin
	--<VERSION>2009.2.20</VERSION>
	--<DATE>2014-02-14</DATE>
	if dbo.mwReplIsSubscriber() <= 0
		return

	if exists (select top 1 1 from @countryKeysToProcess)
		and exists (select top 1 1 from @countryKeysToNotProcess)
	begin
		RAISERROR('must pass only one of @countryKeysToProcess and @countryKeysToNotProcess or neither of them', 16, 1)
		return
	end

	-- обновляем инфу о стране и городе вылета по туру
	if exists(select 1 from mwReplQueue with(nolock) where rq_state = 1 and rq_cnkey is null)
	begin
		update mwReplQueue
		set rq_cnkey = TO_CNKey,
		rq_ctkeyfrom = TL_CTDepartureKey
		from tp_tours
		join tbl_TurList on tl_key = to_trkey
		where to_key = rq_tokey
		and rq_cnkey is null
		and rq_state = 1
	end
		
	if (@jobId is null)
		set @jobId = @@SPID
		
	-- такое может происходить, только если произошла аварийная остановка джоба и его повторный запуск
	-- апдейтим таблицу направлений и таблицу очереди
	if exists(select 1 from mwReplDirections where RD_IsUsed = @jobId)
	begin
		update mwReplQueue 
		set rq_state = 4 
		from mwReplDirections
		where RD_CNKey = rq_cnkey
		and RD_CTKeyFrom = rq_ctkeyfrom
		and rq_state = 3
		and RD_IsUsed = @jobId
		
		update mwReplDirections set RD_IsUsed = 0 where RD_IsUsed = @jobId		
	end
		
	declare @mwSearchType int
	declare @cnKey int, @ctKey int
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'

	declare @rqId int
	declare @rqMode int
	declare @rqToKey int
	declare @rqCalculatingKey int
	declare @rqOverwritePrices bit	

	declare @selectedDirections table(CNKey int, CTKey int)
	declare @currentQueue table(xrq_id int, xrq_mode int, xrq_tokey int, xrq_CalculatingKey int, xRQ_OverwritePrices bit, xrq_state int, xrq_enddate datetime)

	declare @directionsCount as smallint
	select @directionsCount = count(*) from @countryKeysToProcess

	if @directionsCount = 0
		select @directionsCount = count(*) from @countryKeysToProcess

	-- select directions
	if exists (select top 1 1 from @countryKeysToProcess)
	begin
		insert into @selectedDirections
		select isnull(rq_cnkey, 0), isnull(rq_ctkeyfrom, 0)
		from mwReplQueue with(nolock)
		join mwReplDirections with(nolock) on rd_cnkey = isnull(rq_cnkey, 0) and rd_ctkeyfrom = isnull(rq_ctkeyfrom, 0)
		where rd_isUsed = 0
		and (rq_state = 1 or rq_state = 2)
		and rq_mode <= 5
		and isnull(rq_cnkey, 0) in (select value from @countryKeysToProcess)
		order by rq_priority desc, rq_crdate
	end
	else if exists (select top 1 1 from @countryKeysToNotProcess)
	begin
		insert into @selectedDirections
		select isnull(rq_cnkey, 0), isnull(rq_ctkeyfrom, 0)
		from mwReplQueue with(nolock)
		join mwReplDirections with(nolock) on rd_cnkey = isnull(rq_cnkey, 0) and rd_ctkeyfrom = isnull(rq_ctkeyfrom, 0)
		where rd_isUsed = 0
		and (rq_state = 1 or rq_state = 2)
		and rq_mode <= 5
		and isnull(rq_cnkey, 0) not in (select value from @countryKeysToNotProcess)
		order by rq_priority desc, rq_crdate
	end
	else
	begin
		insert into @selectedDirections
		select top 1 isnull(rq_cnkey, 0), isnull(rq_ctkeyfrom, 0)
		from mwReplQueue with(nolock)
		join mwReplDirections with(nolock) on rd_cnkey = isnull(rq_cnkey, 0) and rd_ctkeyfrom = isnull(rq_ctkeyfrom, 0)
		where rd_isUsed = 0
		and (rq_state = 1 or rq_state = 2)
		and rq_mode <= 5
		order by rq_priority desc, rq_crdate
	end

	update mwReplDirections 
	set RD_IsUsed = @jobId
	where RD_IsUsed = 0 
		and exists (select top 1 1 from @selectedDirections where cnKey = rd_cnkey and ctKey = RD_CTKeyFrom)

	if not exists(select 1 from mwReplDirections where RD_IsUsed = @jobId)
		return
		
	-- select commands by directions
	insert into @currentQueue (xrq_id, xrq_mode, xrq_tokey, xrq_CalculatingKey, xRQ_OverwritePrices)
	select top 1 rq_id, rq_mode, rq_tokey, rq_CalculatingKey, RQ_OverwritePrices
	from mwReplQueue 
	where (rq_state = 1 or rq_state = 2)
	and exists (select top 1 1 from @selectedDirections where cnKey = rq_cnkey and ctKey = rq_ctkeyfrom)
	and rq_mode <= 5
	order by rq_priority desc, rq_crdate
	
	update mwReplQueue set [rq_state] = 3, [rq_startdate] = getdate() where rq_id in (select xrq_id from @currentQueue)
	
	declare queueCursor cursor local fast_forward for
	select xrq_id, xrq_mode, xrq_tokey, xrq_CalculatingKey, xRQ_OverwritePrices
	from @currentQueue
	
	-- process commands
	open queueCursor
	fetch queueCursor into @rqId, @rqMode, @rqToKey, @rqCalculatingKey, @rqOverwritePrices
	
	while (@@FETCH_STATUS = 0)
	begin
		
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
		select @rqId, 'Command start.'
			
		begin try	
			if (@rqMode = 1)
			begin
				exec FillMasterWebSearchFields @tokey = @rqToKey, @calcKey = @rqCalculatingKey, @overwritePrices = @rqOverwritePrices
			end
			else if (@rqMode = 2)
			begin
				exec FillMasterWebSearchFields @tokey = @rqToKey, @calcKey = @rqCalculatingKey, @overwritePrices = @rqOverwritePrices
			end
			else if (@rqMode = 3)
			begin
				exec mwReplDisablePriceTour @rqToKey, @rqId
			end
			else if (@rqMode = 4)
			begin
				exec mwReplDeletePriceTour @rqToKey, @rqId
			end
			else if (@rqMode = 5)
			begin
				exec mwReplUpdatePriceTourDateValid @rqToKey, @rqId
			end
			
			update mwReplQueue set rq_state = 5, rq_enddate = getdate() where rq_id = @rqId
			
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
			select @rqId, 'Command complete.'
		
		end try
		begin catch
			update mwReplQueue set rq_state = 4, rq_enddate = getdate() where rq_id = @rqId
			
			declare @errMessage varchar(max)
			set @errMessage = 'Error at ' + isnull(ERROR_PROCEDURE(), '[mwReplProcessQueueDivide]') +' : ' + isnull(ERROR_MESSAGE(), '[msg_not_set]')
			
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
			select @rqId, @errMessage
		end catch
		
		fetch queueCursor into @rqId, @rqMode, @rqToKey, @rqCalculatingKey, @rqOverwritePrices
		
	end
	
	close queueCursor
	deallocate queueCursor
	
	update mwReplDirections set rd_isUsed = 0 where rd_isUsed = @jobId
	
	if exists(select top 1 1 from mwReplQueue with(nolock) where rq_state = 4 and DATEDIFF(MINUTE, rq_enddate, GETDATE()) > 10 and rq_priority > 0)
	begin
		delete from mwReplQueue where rq_tokey not in (select to_key from TP_Tours) and rq_mode <> 4 and (rq_startdate is null or rq_state = 4)
		
		update mwReplQueue set rq_state = 1, rq_startdate = null, rq_enddate = null, rq_priority = rq_priority - 1
		where rq_state = 4 
		and DATEDIFF(MINUTE, rq_enddate, GETDATE()) > 10
		and rq_priority > 0

	end
end
GO

grant exec on [dbo].[mwReplProcessQueueDivide] to public
GO
/*********************************************************************/
/* end sp_mwReplProcessQueueDivide.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwSyncDictionaryData.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwSyncDictionaryData]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwSyncDictionaryData]
GO

CREATE procedure [dbo].[mwSyncDictionaryData] 
	@update_search_table smallint = 0, -- нужно ли синхронизировать данные в mwPriceDataTable
	@update_fields varchar(1024) = NULL -- какие именно данные нужно синхронизировать
as
begin

	--<VERSION>2009.2.20.9</VERSION>
	--<DATE>2014-02-28</DATE>

	-- Список допустимых параметров для @update_fields (нечувствительны к регистру)
	-- COUNTRY
	-- HOTEL
	-- CITY
	-- RESORT
	-- TOUR
	-- TOURTYPE
	-- PANSION
	-- ROOM
	-- ROOMCATEGORY
	-- ACCOMODATION
	-- TP_TOUR     
	
	declare @mwSearchType int
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'     
	declare @sql as nvarchar(max)
	declare @tablesCondition as nvarchar(100), @tableName nvarchar(100)

	if @mwSearchType = 0
		set @tablesCondition = 'mwPriceDataTable'
	else
		set @tablesCondition = 'mwPriceDataTable[_]%'
	
	-- Признак того, откуда брать дополнительные места
	-- Если @isAddPlacesFromRooms = 1 и в таблице Accmdmentype по данному ключу NULL,
	-- дополнительные места беруться из таблицы Rooms, иначе из Accmdmentype
	declare @isAddPlacesFromRooms bit
	select @isAddPlacesFromRooms = SS_ParmValue
	from dbo.SystemSettings
	where SS_ParmName='MWRoomsExtraPlaces'
	
	--обновление синхронизируемых таблиц происходит пакетами; размер указывается в процентах
	declare @updatePackageSize real
	set @updatePackageSize = 10.0	--in

	declare @sdtUpdatePackageSize int
	set @sdtUpdatePackageSize = (select count(*) from mwSpoDataTable with(nolock)) * @updatePackageSize / 100.0
	
	if (@sdtUpdatePackageSize <= 0)
		set @sdtUpdatePackageSize = @updatePackageSize
		
	declare @pdtUpdatePackageSize int
	set @pdtUpdatePackageSize = 100000

	declare @fields table(fname varchar(20));
	declare @blUpdateAllFields smallint	

	-- если параметр @update_fields не задан, то будем выполнять синхронизацию по
	-- всем основным полям
	if @update_fields is null or @update_fields = ''
	begin
		set @blUpdateAllFields = 1
	end
	else
	begin
		set @blUpdateAllFields = 0

		-- произведём сплит строки @update_fields по запятой
		-- и запишем результат в таблицу @fields
		declare @nextString varchar(4000) 
		declare @pos int, @nextPos int 
		declare @commaCheck varchar(1) 
		declare @string varchar(4000)
		declare @delimiter varchar(1)
	 
		set @delimiter = ','
		set @nextString = '' 
		set @commaCheck = right(@update_fields, 1) 
		set @string = @update_fields + @delimiter 
	 
		set @pos = charindex(@delimiter, @string) 
		set @nextPos = 1 
		while (@pos <> 0) 
		begin 
			set @nextString = substring(@string, 1, @pos - 1) 
	 
			insert into @fields( fname) 
			values (upper(ltrim(rtrim(@nextString))))
	 
			set @string = substring(@string, @pos + 1, len(@string)) 
			set @nextPos = @pos 
			set @pos = charindex(@delimiter, @string) 
		end
	end

	declare @dateUpdate datetime
	set @dateUpdate = '2000-01-01'

	if @blUpdateAllFields = 1
	begin
		insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'mwSyncDictionaryData: Start', 1)

		select top 1 @dateUpdate = sl_date
		from systemlog 
		where convert(varchar(max), sl_message) = 'mwSyncDictionaryData: End'
		order by sl_date desc
	end
	else
	begin
		insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'mwSyncDictionaryData: Start ' + @update_fields, 1)

		select top 1 @dateUpdate = sl_date
		from systemlog 
		where convert(varchar(max), sl_message) = 'mwSyncDictionaryData: End '+ @update_fields
		order by sl_date desc
	end

	-- страна
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='COUNTRY')
	begin
		if (exists(select top 1 1 from tbl_country with (nolock) where cn_updatedate > @dateUpdate))
		begin
			-- mwSpoDataTable
			while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
				where exists(select top 1 1 from tbl_country with(nolock) 
					where sd_cnkey = cn_key and cn_updatedate > @dateUpdate and isnull(sd_cnname, '-1') <> isnull(cn_name, '')))
			begin
				update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
				set
					sd_cnname = isnull(cn_name, '')
				from
					tbl_country
				where
					sd_cnkey = cn_key and 
					cn_updatedate > @dateUpdate and
					isnull(sd_cnname, '-1') <> isnull(cn_name, '')
			end
		end
	end
	
	-- отель
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='HOTEL')
	begin
		if (exists(select top 1 1 from hoteldictionary with (nolock) where hd_updatedate > @dateUpdate))
		begin
			-- mwSpoDataTable
			while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
				where exists(select top 1 1 from dbo.hoteldictionary with(nolock) where
					sd_hdkey = hd_key
					and hd_updatedate > @dateUpdate
					and (
						isnull(sd_hdstars, '-1') <> isnull(hd_stars, '') or 
						isnull(sd_ctkey, -1) <> isnull(hd_ctkey, 0) or 
						isnull(sd_rskey, -1) <> isnull(hd_rskey, 0) or 
						isnull(sd_hdname, '-1') <> isnull(hd_name, '') or 
						isnull(sd_hotelurl, '-1') <> isnull(hd_http, '')
					)
				)
			)
			begin
				update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
				set
					sd_hdstars = isnull(hd_stars, ''),
					sd_ctkey = isnull(hd_ctkey, 0),
					sd_rskey = isnull(hd_rskey, 0),
					sd_hdname = isnull(hd_name, ''),
					sd_hotelurl = isnull(hd_http, '')
				from
					dbo.hoteldictionary
				where
					sd_hdkey = hd_key
					and hd_updatedate > @dateUpdate 
					and (
						isnull(sd_hdstars, '-1') <> isnull(hd_stars, '') or 
						isnull(sd_ctkey, -1) <> isnull(hd_ctkey, 0) or 
						isnull(sd_rskey, -1) <> isnull(hd_rskey, 0) or 
						isnull(sd_hdname, '-1') <> isnull(hd_name, '') or 
						isnull(sd_hotelurl, '-1') <> isnull(hd_http, '')
					)
			end
		
			-- mwPriceDataTable	
			if @update_search_table > 0
			begin

				declare tableCursor cursor for
				select name from sys.tables 
				where name like @tablesCondition

				open tableCursor
				fetch tableCursor into @tableName
				while @@FETCH_STATUS = 0
				begin
					set @sql = '
								while exists(select top 1 1 from @tableName with(nolock) 
								where exists(select top 1 1 from dbo.hoteldictionary with(nolock) where
									pt_hdkey = hd_key 
									and hd_updatedate > ''@dateUpdate''
									and (
										isnull(pt_hdstars, ''-1'') <> isnull(hd_stars, '''') or 
										isnull(pt_ctkey, -1) <> isnull(hd_ctkey, 0) or
										isnull(pt_rskey, -1) <> isnull(hd_rskey, 0) or
										isnull(pt_hdname, ''-1'') <> isnull(hd_name, '''') or
										isnull(pt_hotelurl, ''-1'') <> isnull(hd_http, '''')
										)
									)
								)
								begin
									update top (@pdtUpdatePackageSize) @tableName
									set
										pt_hdstars = isnull(hd_stars, ''''),
										pt_ctkey = isnull(hd_ctkey, 0),
										pt_rskey = isnull(hd_rskey, 0),
										pt_hdname = isnull(hd_name, ''''),
										pt_hotelurl = isnull(hd_http, '''')
									from
										dbo.hoteldictionary
									where
										pt_hdkey = hd_key 
										and hd_updatedate > ''@dateUpdate''
										and (
											isnull(pt_hdstars, ''-1'') <> isnull(hd_stars, '''') or 
											isnull(pt_ctkey, -1) <> isnull(hd_ctkey, 0) or
											isnull(pt_rskey, -1) <> isnull(hd_rskey, 0) or
											isnull(pt_hdname, ''-1'') <> isnull(hd_name, '''') or
											isnull(pt_hotelurl, ''-1'') <> isnull(hd_http, '''')
										)
								end
					'

					set @sql = REPLACE(@sql, '@tableName', @tableName)
					set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
					set @sql = REPLACE(@sql, '@dateUpdate', convert(varchar(max), @dateUpdate))

					exec (@sql)

					fetch tableCursor into @tableName
				end
				close tableCursor
				deallocate tableCursor
			end
		end
	end
	
	-- город отправления
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='CITY')
	begin
		if (exists(select top 1 1 from citydictionary with (nolock) where ct_updatedate > @dateUpdate))
		begin
			-- mwSpoDataTable
			while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
				where exists(select top 1 1 from citydictionary with(nolock) 
					where sd_ctkeyfrom <> 0 and sd_ctkeyfrom = ct_key and ct_updatedate > @dateUpdate and isnull(sd_ctfromname, '-1') <> isnull(ct_name, '')))
			begin
				update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
				set
					sd_ctfromname = isnull(ct_name,'')
				from
					dbo.citydictionary
				where
					sd_ctkeyfrom <> 0	-- город отправления -Без перелета- не обновляем, это константа (см. FillMasterwebSearchFields)
					and sd_ctkeyfrom = ct_key
					and ct_updatedate > @dateUpdate
					and isnull(sd_ctfromname, '-1') <> isnull(ct_name, '')
			end

			while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
				where exists(select top 1 1 from citydictionary with(nolock) 
					where sd_ctkey = ct_key and ct_updatedate > @dateUpdate and isnull(sd_ctname, '-1') <> isnull(ct_name, '')
				)
			)
			begin
				update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
				set
					sd_ctname = isnull(ct_name,'')
				from
					dbo.citydictionary
				where
					sd_ctkey = ct_key 
					and ct_updatedate > @dateUpdate 
					and isnull(sd_ctname, '-1') <> isnull(ct_name, '')
			end
		
			-- mwPriceDataTable
			if @update_search_table > 0
			begin
				declare tableCursor cursor for
				select name from sys.tables 
				where name like @tablesCondition

				open tableCursor
				fetch tableCursor into @tableName
				while @@FETCH_STATUS = 0
				begin
					set @sql = '
								while exists(select top 1 1 from @tableName with(nolock)
									where exists(select top 1 1 from dbo.citydictionary with(nolock) where
										pt_ctkey = ct_key and ct_updatedate > ''@dateUpdate'' and isnull(pt_ctname, ''-1'') <> isnull(ct_name, '''')
									)
								)
								begin
									update top (@pdtUpdatePackageSize) @tableName
									set
										pt_ctname = isnull(ct_name,'''')
									from
										dbo.citydictionary
									where
										pt_ctkey = ct_key 
										and ct_updatedate > ''@dateUpdate'' and
										isnull(pt_ctname, ''-1'') <> isnull(ct_name, '''')
								end
					'
					set @sql = REPLACE(@sql, '@tableName', @tableName)
					set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
					set @sql = REPLACE(@sql, '@dateUpdate', convert(varchar(max), @dateUpdate))
					exec (@sql)

					fetch tableCursor into @tableName
				end
				close tableCursor
				deallocate tableCursor

			end
		end
	end
	
	--курорт
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='RESORT')
	begin
		if (exists(select top 1 1 from resorts with (nolock) where rs_updatedate > @dateUpdate))
		begin
			-- mwSpoDataTable
			while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock)
				where exists(select top 1 1 from dbo.resorts with(nolock) where
					sd_rskey = rs_key and rs_updatedate > @dateUpdate and isnull(sd_rsname, '-1') <> isnull(rs_name, '')
				)
			)
			begin
				update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
				set
					sd_rsname = isnull(rs_name,'')
				from
					dbo.resorts
				where
					sd_rskey = rs_key and rs_updatedate > @dateUpdate and
					isnull(sd_rsname, '-1') <> isnull(rs_name, '')
			end
		
			-- mwPriceDataTable	
			if @update_search_table > 0
			begin
				declare tableCursor cursor for
				select name from sys.tables 
				where name like @tablesCondition

				open tableCursor
				fetch tableCursor into @tableName
				while @@FETCH_STATUS = 0
				begin
					set @sql = '
								while exists(select top 1 1 from @tableName with(nolock)
									where exists(select top 1 1 from dbo.resorts with(nolock) where
										pt_rskey = rs_key and rs_updatedate > ''@dateUpdate'' and isnull(pt_rsname, ''-1'') <> isnull(rs_name, '''')
									)
								)		
								begin
									update top (@pdtUpdatePackageSize) @tableName
									set
										pt_rsname = isnull(rs_name, '''')
									from
										dbo.resorts
									where
										pt_rskey = rs_key 
										and rs_updatedate > ''@dateUpdate'' 
										and isnull(pt_rsname, ''-1'') <> isnull(rs_name, '''')
								end
					'

					set @sql = REPLACE(@sql, '@tableName', @tableName)
					set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
					set @sql = REPLACE(@sql, '@dateUpdate', convert(varchar(max), @dateUpdate))
					exec (@sql)

					fetch tableCursor into @tableName
				end
				close tableCursor
				deallocate tableCursor

			end
		end
	end
	
	-- тур
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='TOUR')
	begin
		while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock)
			where exists(select top 1 1 from dbo.tbl_turlist with(nolock) where
				sd_tlkey = tl_key
				and (
					isnull(sd_tourname, '-1') <> isnull(tl_nameweb, '') or 
					isnull(sd_tourtype, -1) <> isnull(tl_tip, 0)
				)
			)
		)
		begin
			update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
			set
				sd_tourname = isnull(tl_nameweb, ''),
				sd_tourtype = isnull(tl_tip, 0)
			from
				dbo.tbl_turlist
			where
				sd_tlkey = tl_key
				and (
					isnull(sd_tourname, '-1') <> isnull(tl_nameweb, '') or 
					isnull(sd_tourtype, -1) <> isnull(tl_tip, 0)
				)
		end
		
		-- mwPriceDataTable	
		if @update_search_table > 0
		begin			
			declare tableCursor cursor for
			select name from sys.tables 
			where name like @tablesCondition

			open tableCursor
			fetch tableCursor into @tableName
			while @@FETCH_STATUS = 0
			begin
				set @sql = '
							while exists(select top 1 1 from @tableName with(nolock)
								where exists(select top 1 1 from dbo.tbl_turlist with(nolock) where
									pt_tlkey = tl_key
									and (
										isnull(pt_tourname, ''-1'') <> isnull(tl_nameweb, '''') or
										isnull(pt_toururl, ''-1'') <> isnull(tl_webhttp, '''') or
										isnull(pt_tourtype, -1) <> isnull(tl_tip, 0)
									)
								)
							)
							begin
								update top (@pdtUpdatePackageSize) @tableName
								set
									pt_tourname = isnull(tl_nameweb, ''''),
									pt_toururl = isnull(tl_webhttp, ''''),
									pt_tourtype = isnull(tl_tip, 0)
								from
									dbo.tbl_turlist
								where
									pt_tlkey = tl_key
									and (
										isnull(pt_tourname, ''-1'') <> isnull(tl_nameweb, '''') or
										isnull(pt_toururl, ''-1'') <> isnull(tl_webhttp, '''') or
										isnull(pt_tourtype, -1) <> isnull(tl_tip, 0)
									)
							end
				'

				set @sql = REPLACE(@sql, '@tableName', @tableName)
				set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
				exec (@sql)

				fetch tableCursor into @tableName

			end
			close tableCursor
			deallocate tableCursor
		end
	end
	
	-- тип тура
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='TOURTYPE')
	begin
		while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 1 from dbo.tiptur with(nolock) 
				where sd_tourtype = tp_key and isnull(sd_tourtypename, '-1') <> isnull(tp_name, '')
			)
		)
		begin
			update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
			set
				sd_tourtypename = isnull(tp_name, '')
			from
				dbo.tiptur
			where
				sd_tourtype = tp_key
				and isnull(sd_tourtypename, '-1') <> isnull(tp_name, '')
		end
	end

	-- питание
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='PANSION')
	begin
		while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 1 from dbo.pansion with(nolock) 
				where sd_pnkey = pn_key and isnull(sd_pncode, '-1') <> isnull(pn_code, '')
			)
		)
		begin
			update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
			set
				sd_pncode = isnull(pn_code, '')
			from
				dbo.pansion
			where
				sd_pnkey = pn_key and 
				isnull(sd_pncode, '-1') <> isnull(pn_code, '')
		end	
		
		if @update_search_table > 0
		begin
			declare tableCursor cursor for
			select name from sys.tables 
			where name like @tablesCondition

			open tableCursor
			fetch tableCursor into @tableName
			while @@FETCH_STATUS = 0
			begin
				set @sql = '
							while exists(select top 1 1 from @tableName with(nolock)
								where exists(select top 1 1 from dbo.pansion with(nolock) where
									pt_pnkey = pn_key
									and (
										isnull(pt_pnname, ''-1'') <> isnull(pn_name, '''') or
										isnull(pt_pncode, ''-1'') <> isnull(pn_code, '''')
									)
								)
							)
							begin
								update top (@pdtUpdatePackageSize) @tableName
								set 
									pt_pnname = isnull(pn_name, ''''),
									pt_pncode = isnull(pn_code, '''')
								from dbo.pansion
								where
									pt_pnkey = pn_key
									and (
										isnull(pt_pnname, ''-1'') <> isnull(pn_name, '''') or
										isnull(pt_pncode, ''-1'') <> isnull(pn_code, '''')
									)
							end
				'
				set @sql = REPLACE(@sql, '@tableName', @tableName)
				set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
				exec (@sql)

				fetch tableCursor into @tableName
			end

			close tableCursor
			deallocate tableCursor
		end
	end
	
	-- номер	
	if ((@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='ROOM')) and @update_search_table > 0
	begin
		if (exists(select top 1 1 from rooms with (nolock) where rm_updatedate > @dateUpdate))
		begin
			declare tableCursor cursor for
			select name from sys.tables 
			where name like @tablesCondition

			open tableCursor
			fetch tableCursor into @tableName
			while @@FETCH_STATUS = 0
			begin
				set @sql = '
							while exists(select top 1 1 from @tableName with(nolock)
								where exists(select top 1 1 from dbo.rooms with(nolock) where
									pt_rmkey = rm_key 
									and rm_updatedate > ''@dateUpdate''
									and (
										isnull(pt_rmname, ''-1'') <> isnull(rm_name, '''') or 
										isnull(pt_rmcode, ''-1'') <> isnull(rm_code, '''') or 
										isnull(pt_rmorder, -1) <> isnull(rm_order, 0)
									)
								)
							)
							begin
								update top (@pdtUpdatePackageSize) @tableName
								set
									pt_rmname = isnull(rm_name, ''''),
									pt_rmcode = isnull(rm_code, ''''),
									pt_rmorder = isnull(rm_order, 0)
								from
									dbo.rooms
								where
									pt_rmkey = rm_key 
									and rm_updatedate > ''@dateUpdate''
									and (
										isnull(pt_rmname, ''-1'') <> isnull(rm_name, '''') or 
										isnull(pt_rmcode, ''-1'') <> isnull(rm_code, '''') or 
										isnull(pt_rmorder, -1) <> isnull(rm_order, 0)
									)			
							end
				'
				set @sql = REPLACE(@sql, '@tableName', @tableName)
				set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
				set @sql = REPLACE(@sql, '@dateUpdate', convert(varchar(max), @dateUpdate))
				exec (@sql)

				fetch tableCursor into @tableName
			end

			close tableCursor
			deallocate tableCursor
		end
	end
	
	-- категория номера
	if ((@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='ROOMCATEGORY')) and @update_search_table > 0
	begin
		if (exists(select top 1 1 from roomscategory with (nolock) where rc_updatedate > @dateUpdate))
		begin
			declare tableCursor cursor for
			select name from sys.tables 
			where name like @tablesCondition

			open tableCursor
			fetch tableCursor into @tableName
			while @@FETCH_STATUS = 0
			begin
				set @sql = '
							while exists(select top 1 1 from @tableName with(nolock)
								where exists(select top 1 1 from dbo.roomscategory with(nolock) where
									pt_rckey = rc_key 
									and rc_updatedate > ''@dateUpdate''
									and (
										isnull(pt_rcname, ''-1'') <> isnull(rc_name, '''') or 
										isnull(pt_rccode, ''-1'') <> isnull(rc_code, '''') or 
										isnull(pt_rcorder, -1) <> isnull(rc_order, 0)
									)
								)
							)
							begin
								update top (@pdtUpdatePackageSize) @tableName
								set
									pt_rcname = isnull(rc_name, ''''),
									pt_rccode = isnull(rc_code, ''''),
									pt_rcorder = isnull(rc_order, 0)
								from
									dbo.roomscategory
								where
									pt_rckey = rc_key 
									and rc_updatedate > ''@dateUpdate''
									and (
										isnull(pt_rcname, ''-1'') <> isnull(rc_name, '''') or 
										isnull(pt_rccode, ''-1'') <> isnull(rc_code, '''') or 
										isnull(pt_rcorder, -1) <> isnull(rc_order, 0)
									)
							end
				'
				set @sql = REPLACE(@sql, '@tableName', @tableName)
				set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
				set @sql = REPLACE(@sql, '@dateUpdate', convert(varchar(max), @dateUpdate))
				exec (@sql)

				fetch tableCursor into @tableName
			end

			close tableCursor
			deallocate tableCursor
		end
	end
	
	-- размещение
	--kadraliev MEG00029412 29.09.2010 Добавил синхронизацию признака isMain, возрастов детей
	if ((@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='ACCOMODATION')) and @update_search_table > 0
	begin	
		if (exists(select top 1 1 from accmdmentype with (nolock) where ac_updatedate > @dateUpdate))
		begin
			declare tableCursor cursor for
			select name from sys.tables 
			where name like @tablesCondition

			open tableCursor
			fetch tableCursor into @tableName
			while @@FETCH_STATUS = 0
			begin
				set @sql = '
							while exists(select top 1 1 from @tableName with(nolock)
								where exists(select top 1 1 from dbo.accmdmentype with(nolock) where
									pt_ackey = ac_key 
									and ac_updatedate > ''@dateUpdate''
									and (
										isnull(pt_acname, ''-1'') <> isnull(ac_name, '''') or
										isnull(pt_accode, ''-1'') <> isnull(ac_code, '''') or
										isnull(pt_acorder, -1) <> isnull(ac_order, 0) or
										isnull(pt_main, -1) <> isnull(ac_main, 0) or
										isnull(pt_childagefrom, -1) <> isnull(ac_agefrom, 0) or
										isnull(pt_childageto, -1) <> isnull(ac_ageto, 0) or
										isnull(pt_childagefrom2, -1) <> isnull(ac_agefrom2, 0) or
										isnull(pt_childageto2, -1) <> isnull(ac_ageto2, 0)					
									)
								)
							)
							begin
								update top (@pdtUpdatePackageSize) @tableName
								set
									pt_acname = isnull(ac_name, ''''),
									pt_accode = isnull(ac_code, ''''),
									pt_acorder = isnull(ac_order, 0),
									pt_main = isnull(ac_main, 0),
									pt_childagefrom = isnull(ac_agefrom, 0),
									pt_childageto = isnull(ac_ageto, 0),
									pt_childagefrom2 = isnull(ac_agefrom2, 0),
									pt_childageto2 = isnull(ac_ageto2, 0)
								from
									dbo.accmdmentype
								where
									pt_ackey = ac_key 
									and ac_updatedate > ''@dateUpdate''
									and (
										isnull(pt_acname, ''-1'') <> isnull(ac_name, '''') or
										isnull(pt_accode, ''-1'') <> isnull(ac_code, '''') or
										isnull(pt_acorder, -1) <> isnull(ac_order, 0) or
										isnull(pt_main, -1) <> isnull(ac_main, 0) or
										isnull(pt_childagefrom, -1) <> isnull(ac_agefrom, 0) or
										isnull(pt_childageto, -1) <> isnull(ac_ageto, 0) or
										isnull(pt_childagefrom2, -1) <> isnull(ac_agefrom2, 0) or
										isnull(pt_childageto2, -1) <> isnull(ac_ageto2, 0)	
									)
							end
				'
				set @sql = REPLACE(@sql, '@tableName', @tableName)
				set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
				set @sql = REPLACE(@sql, '@dateUpdate', convert(varchar(max), @dateUpdate))
				exec (@sql)

				fetch tableCursor into @tableName	
			end

			close tableCursor
			deallocate tableCursor
		end
	end

	--kadraliev MEG00029412 29.09.2010 номер и размещение (количество основных и дополнительных мест)
	if ((@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='ROOM' or fname='ACCOMODATION')) and @update_search_table > 0
	begin
		if (exists(select top 1 1 from rooms with (nolock) where rm_updatedate > @dateUpdate) or exists(select top 1 1 from accmdmentype with (nolock) where ac_updatedate > @dateUpdate))
		begin
			declare tableCursor cursor for
			select name from sys.tables 
			where name like @tablesCondition

			open tableCursor
			fetch tableCursor into @tableName
			while @@FETCH_STATUS = 0
			begin
				set @sql = '
				while exists(select top 1 1 
				from @tableName with(nolock)
				inner join rooms with(nolock) on pt_rmkey = rm_key
				inner join accmdmentype with(nolock) on pt_ackey = ac_key
				where
				pt_main > 0 
				and (ac_updatedate > ''@dateUpdate'' or rm_updatedate > ''@dateUpdate'')
				and isnull(pt_mainplaces,-1) <> (	case when @mwAccomodationPlaces = 0
													then 
														isnull(rm_nplaces, 0)
													else 
														case when @findByAdultChild = 1 -- искать по взрослым
														then 
															isnull(AC_NADMAIN, 0) + isnull(AC_NADEXTRA,0)
															-- искать по основным
														else 
															isnull(AC_NADMAIN, 0) + isnull(AC_NCHMAIN, 0)
														end
													end)
											 or
				isnull(pt_addplaces,-1) <> (case when isnull(ac_nmenexbed, -1) = -1
											then 
												case when @mwRoomsExtraPlaces <> 0
												then isnull(rm_nplacesex, 0)
												else isnull(ac_nmenexbed, 0)
											end
											else 
												case when @findByAdultChild = 1 -- искать по детям
												then isnull(AC_NCHMAIN, 0) + isnull(AC_NCHEXTRA, 0)
												-- искать по дополнительным местам
												else isnull(AC_NADEXTRA, 0) + isnull(AC_NCHEXTRA, 0)
											end
											end)
			)
			begin
				update top (@pdtUpdatePackageSize) @tableName
				set
					pt_mainplaces = (case when @mwAccomodationPlaces = 0
									then 
										isnull(rm_nplaces, 0)
									else 
										case when @findByAdultChild = 1 -- искать по взрослым
										then 
											isnull(AC_NADMAIN, 0) + isnull(AC_NADEXTRA,0)
											-- искать по основным
										else 
											isnull(AC_NADMAIN, 0) + isnull(AC_NCHMAIN, 0)
										end
									end),
					pt_addplaces =	(case when isnull(ac_nmenexbed, -1) = -1
									then 
										case when @mwRoomsExtraPlaces <> 0
										then isnull(rm_nplacesex, 0)
										else isnull(ac_nmenexbed, 0)
									end
									else 
										case when @findByAdultChild = 1 -- искать по детям
										then isnull(AC_NCHMAIN, 0) + isnull(AC_NCHEXTRA, 0)
										-- искать по дополнительным местам
										else isnull(AC_NADEXTRA, 0) + isnull(AC_NCHEXTRA, 0)
									end
									end)
				from @tableName orig with(nolock)
					left join rooms with(nolock) on orig.pt_rmkey = rm_key
					left join accmdmentype with(nolock) on orig.pt_ackey = ac_key
				where
					pt_main > 0 
					and (ac_updatedate > ''@dateUpdate'' or rm_updatedate > ''@dateUpdate'')
					and isnull(pt_mainplaces,-1) <> (	case when @mwAccomodationPlaces = 0
														then 
															isnull(rm_nplaces, 0)
														else 
															case when @findByAdultChild = 1 -- искать по взрослым
															then 
																isnull(AC_NADMAIN, 0) + isnull(AC_NADEXTRA,0)
																-- искать по основным
															else 
																isnull(AC_NADMAIN, 0) + isnull(AC_NCHMAIN, 0)
															end
														end)
												 or
					isnull(pt_addplaces,-1) <> (case when isnull(ac_nmenexbed, -1) = -1
												then 
													case when @mwRoomsExtraPlaces <> 0
													then isnull(rm_nplacesex, 0)
													else isnull(ac_nmenexbed, 0)
												end
												else 
													case when @findByAdultChild = 1 -- искать по детям
													then isnull(AC_NCHMAIN, 0) + isnull(AC_NCHEXTRA, 0)
													-- искать по дополнительным местам
													else isnull(AC_NADEXTRA, 0) + isnull(AC_NCHEXTRA, 0)
												end
												end)
			end
				'

				-- Признак того, откуда брать основые места
				-- Если @isMainPlacesFromAccomodation = 1, основные места беруться из таблицы Accmdmentype, иначе из Rooms
				-- Синхронизация основных мест происходит если pt_main > 0
				declare @mwAccomodationPlaces bit
				select @mwAccomodationPlaces = SS_ParmValue
				from dbo.SystemSettings
				where SS_ParmName='MWAccomodationPlaces'

				-- Признак того, откуда брать дополнительные места
				-- Если @isAddPlacesFromRooms = 1 и в таблице Accmdmentype по данному ключу NULL,
				-- дополнительные места беруться из таблицы Rooms, иначе из Accmdmentype
				declare @mwRoomsExtraPlaces nvarchar(254)
				select @mwRoomsExtraPlaces = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings with(nolock) 
				where SS_ParmName = 'MWRoomsExtraPlaces'

				declare @findByAdultChild int
				set @findByAdultChild = isnull((select top 1 convert(int, SS_ParmValue) from SystemSettings where SS_ParmName = 'OnlineFindByAdultChild'), 0)

				set @sql = REPLACE(@sql, '@mwAccomodationPlaces', @mwAccomodationPlaces)
				set @sql = REPLACE(@sql, '@findByAdultChild', @findByAdultChild)
				set @sql = REPLACE(@sql, '@mwRoomsExtraPlaces', @mwRoomsExtraPlaces)

				set @sql = REPLACE(@sql, '@tableName', @tableName)
				set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
				set @sql = REPLACE(@sql, '@dateUpdate', convert(varchar(max), @dateUpdate))
				exec (@sql)

				fetch tableCursor into @tableName	
			end

			close tableCursor
			deallocate tableCursor		
		end
	end

	-- расчитанный тур
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='TP_TOUR')
	begin
		if (exists(select top 1 1 from tp_tours with (nolock) where to_updatetime > @dateUpdate))
		begin
			while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock)
				where exists(select top 1 1 from dbo.tp_tours with(nolock) where
					sd_tourkey = to_key
					and to_updatetime > @dateUpdate
					and (
						isnull(sd_tourcreated, '1900-01-02') <> isnull(to_datecreated, '1900-01-01') or 
						isnull(sd_tourvalid, '1900-01-02') <> isnull(to_datevalid, '1900-01-01')
					)
				)
			)
			begin
				update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
				set
					sd_tourcreated = isnull(to_datecreated, '1900-01-01'),
					sd_tourvalid = isnull(to_datevalid, '1900-01-01')
				from
					dbo.tp_tours
				where
					sd_tourkey = to_key
					and to_updatetime > @dateUpdate
					and (
						isnull(sd_tourcreated, '1900-01-02') <> isnull(to_datecreated, '1900-01-01') or 
						isnull(sd_tourvalid, '1900-01-02') <> isnull(to_datevalid, '1900-01-01')
					)
			end

			-- mwPriceDataTable
			if @update_search_table > 0
			begin		
				declare tableCursor cursor for
				select name from sys.tables 
				where name like @tablesCondition

				open tableCursor
				fetch tableCursor into @tableName
				while @@FETCH_STATUS = 0
				begin
					set @sql = '
								while exists(select top 1 1 from @tableName with(nolock)
									where exists(select top 1 1 from dbo.tp_tours with(nolock) where
										pt_tourkey = to_key 
										and to_updatetime > ''@dateUpdate''
										and (
											isnull(pt_tourcreated, ''1900-01-02'') <> isnull(to_datecreated, ''1900-01-01'') or 
											isnull(pt_tourvalid, ''1900-01-02'') <> isnull(to_datevalid, ''1900-01-01'') or 
											isnull(pt_rate, ''-1'') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '''') COLLATE DATABASE_DEFAULT
										)
									)
								)
								begin
									update top (@pdtUpdatePackageSize) @tableName
									set
										pt_tourcreated = isnull(to_datecreated, ''1900-01-01''),
										pt_tourvalid = isnull(to_datevalid, ''1900-01-01''),
										pt_rate = isnull(to_rate, '''')
									from
										dbo.tp_tours
									where
										pt_tourkey = to_key 
										and to_updatetime > ''@dateUpdate''
										and (
											isnull(pt_tourcreated, ''1900-01-02'') <> isnull(to_datecreated, ''1900-01-01'') or 
											isnull(pt_tourvalid, ''1900-01-02'') <> isnull(to_datevalid, ''1900-01-01'') or 
											isnull(pt_rate, ''-1'') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '''') COLLATE DATABASE_DEFAULT
										)
								end
					'

					set @sql = REPLACE(@sql, '@tableName', @tableName)
					set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
					set @sql = REPLACE(@sql, '@dateUpdate', convert(varchar(max), @dateUpdate))

					exec (@sql)
					fetch tableCursor into @tableName	
				end

				close tableCursor
				deallocate tableCursor
			
			end
		end
	end

	if @blUpdateAllFields = 1
		insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'mwSyncDictionaryData: End', 1)
	else
		insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'mwSyncDictionaryData: End ' + @update_fields, 1)
end
GO

grant exec on [dbo].[mwSyncDictionaryData] to public
go
/*********************************************************************/
/* end sp_mwSyncDictionaryData.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_Paging.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Paging]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[Paging]
GO

--<DATE>2014-01-30</DATE>
--<VERSION>2009.2.20.7</VERSION>
CREATE PROCEDURE [dbo].[Paging]
	@pagingType	smallint=2,
	@countryKey	int,
	@departFromKey	int,
	@filter		varchar(MAX),
	@sortExpr	varchar(1024),
	@pageNum	int=0,						-- номер страницы(начиная с 1 или количество уже просмотренных записей для исключения при @pagingType=@ACTUALPLACES_PAGING)
	@pageSize	int=9999,
	@agentKey	int=0,
	@hotelQuotaMask smallint=0,
	@aviaQuotaMask smallint=0,
	@getServices	smallint=0,
	@flightGroups	varchar(256),
	@checkAgentQuota smallint,
	@checkCommonQuota smallint,
	@checkNoLongQuota smallint,
	@requestOnRelease smallint,
	@expiredReleaseResult int,
	@noPlacesResult int,
	@findFlight smallint,
	@checkFlightPacket smallint,
	@checkAllPartnersQuota smallint = null,
	@calculateVisaDeadLine smallint = 0,
	@noSmartSearch bit = 0,
	@HideWithNotStartedSaleDate bit = 0		-- не показывать цены по турам, дата продажи которых еще не наступила.
AS
set nocount on

--koshelev
--@noPlacesResult должен быть больше 0
--2012-08-17
if (@noPlacesResult > 0 or @filter like '%in ()%')
	return

declare @beginTime datetime
set @beginTime = getDate()

/******************************************************************************
**		Parameters:

		@filter		varchar(1024),	 - поисковый фильтр (where-фраза)
		@sortExpr	varchar(1024),	 - выражение сортировки
		@pageNum	int=1,	 - № страницы
		@pageSize	int=9999	 - размер страницы
		@transform	smallint=0	 - преобразовывать ли полученные данные для расположения продолжительностей по горизонтали
		@noSmartSearch bit = 0	- запрещает подмешивать варианты в поиск (приоритетней чем настройка в SystemSettings) - используется при недефолтной сортировке
*******************************************************************************/

-- vinge 9.08.2012 перенес в начало файла объявление таблицы с результатами
create table #resultsTable(
	paging_id int,
	pt_key bigint,			-- MEG00038762. Golubinsky. 20.12.2011. Увеличил тип до bigint
	pt_ctkeyfrom int,
	pt_cnkey int,
	pt_tourdate datetime,
	pt_pnkey int,
	pt_hdkey int,
	pt_hrkey int,
	pt_tourkey int,
	pt_tlkey int,
	pt_tourtype int,
	pt_tourname varchar(256),
	pt_toururl varchar(256),
	pt_hdname varchar(60),
	pt_hdstars varchar(12),
	pt_ctkey int,
	pt_rskey int,
	pt_hotelurl varchar(256),
	pt_pncode varchar(30),
	pt_rate varchar(3),
	pt_rmkey int,
	pt_rckey int,
	pt_ackey int,
	-- MEG00025561 Paul G 08.02.2010
	-- чтоб возраст ребёнка можно было отображать в прайсе
	pt_childagefrom int,
	pt_childageto int,
	pt_childagefrom2 int,
	pt_childageto2 int,
	-- End MEG00025561
	pt_cnname varchar(50),
	pt_ctname varchar(50),
	pt_rsname varchar(50),		
	pt_rmname varchar(60),
	pt_rcname varchar(60),
	pt_acname varchar(30),
	pt_chkey int,
	pt_chbackkey int,
	pt_hotelkeys varchar(256),
	pt_hotelroomkeys varchar(256),
	pt_hotelnights varchar(256),
	pt_hotelstars varchar(256),
	pt_pansionkeys varchar(256),
	pt_actual smallint,
	pt_visadeadline datetime
)


-- vinge 9.08.2012 без этой проверки хранимка вылетает с ошибкой
if (@hotelQuotaMask = 0) and (@aviaQuotaMask = 0)
begin
	select 0
	select 0
	select * from #resultsTable

	return
end

---=== Если это пейджинг для пакса, то перенаправляемся в его хранимку ===---
if (@pagingType = 4)
begin
	exec PagingPax @countryKey, @departFromKey, @filter, @sortExpr, @pageNum, @pageSize
			, @agentKey, @hotelQuotaMask,  @aviaQuotaMask, @flightGroups, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota
			, @requestOnRelease, @expiredReleaseResult, @noPlacesResult, @findFlight, @checkFlightPacket
	return
end


declare @mwSearchType int
select @mwSearchType=isnull(SS_ParmValue,1) from dbo.systemsettings 
where SS_ParmName='MWDivideByCountry'

-- BEGIN Added by Allen to prevent latest price selection
declare @mwLatestPrices int
select @mwLatestPrices = isnull(SS_ParmValue,1) from dbo.systemsettings 
where SS_ParmName='MW_PACLatestPrices'

-- BEGIN Added by Allen to prevent latest price selection
declare @tableName varchar(256)
declare @viewName varchar(256)
if(@mwSearchType=0)
begin
	set @tableName='mwPriceTable'
	set @viewName='dbo.mwPriceTableView'
	set @filter=' pt_cnkey= ' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom= ' + LTRIM(STR(@departFromKey)) + ' and ' + @filter
end
else 
begin
	set @tableName=dbo.mwGetPriceViewName(@countryKey,@departFromKey)
	set @viewName=REPLACE(@tableName,'PriceTable','PriceTableView')
end

declare @MAX_ROWCOUNT int
set @MAX_ROWCOUNT=1000 -- если @pageSize больше этого числа,что пейджинг производиться не будет
declare @SIMPLE_PAGING smallint
set @SIMPLE_PAGING=1
declare @ACTUALPLACES_PAGING smallint
set @ACTUALPLACES_PAGING=2
declare @DYNAMIC_SPO_PAGING smallint
set @DYNAMIC_SPO_PAGING=3
declare @QUOTAMASK_NO smallint
set @QUOTAMASK_NO=0
declare @QUOTAMASK_ALL smallint
set @QUOTAMASK_ALL=7

-- настройка включающая SmartSearch
declare @mwUseSmartSearch int
select @mwUseSmartSearch=isnull(SS_ParmValue,0) from dbo.systemsettings 
where SS_ParmName='mwUseSmartSearch'
-- пока SmartSearch работает с только с ACTUALPLACES_PAGING
-- параметр @noSmartSearch - блокирует подмешивание
if (@pagingType <> @ACTUALPLACES_PAGING or @noSmartSearch = 1)
begin
	set @mwUseSmartSearch = 0
end

-- направление сортировки
declare @sortType smallint
set @sortType=1 -- по возр
declare @spageNum varchar(30)
declare @spageSize varchar(30)
set @spageNum=LTRIM(STR(@pageNum))
set @spageSize=LTRIM(STR(@pageSize))


if(@pagingType = @DYNAMIC_SPO_PAGING)
	set @findFlight = 0

if(@hotelQuotaMask > 0 or @aviaQuotaMask > 0)
begin
		create table #checked(
			svkey int,
			code int,
			rmkey int,
			rckey int,
			date datetime,
			day int,
			days int,
			prkey int,
			pkkey int,
			res varchar(256),
			places int,
			step_index smallint,
			price_correction int,
			find_flight bit default(0)	-- 07.02.2012. Golubinsky. Для правильного кеширования результатов при подборе перелета
		)
end

declare @sql varchar(MAX)
set @sql=''
if (@pagingType = 0 or @pagingType = 5)
begin
	declare @zptPos int
	declare @prefix varchar(1024)
	set @zptPos = charindex(',',@sortExpr)
	if(@zptPos > 0)
		set @prefix = substring(@sortExpr, 1, @zptPos)
	else
	set @prefix = @sortExpr

	if(charindex('desc', @prefix) > 0)
		set @sortType=-1

	if(@sortType <= 0)
	begin
		set @viewName=replace(@viewName,'mwPriceTableView','mwPriceTableViewDesc')
	end
	else
	begin
		set @viewName=replace(@viewName,'mwPriceTableView','mwPriceTableViewAsc')
	end

	create table #days(
		days int,
		nights int
	)

	if (@pagingType = 5)
		set @sql='select distinct top 5 pt_days,pt_nights from '
	else if (@pagingType = 0)
		set @sql='select distinct top 5 pt_days,pt_nights from '


	if(@mwSearchType=0)
-- BEGIN Removed by Allen
--			set @sql=@sql + @tableName +  ' t1 with(nolock) inner join (select pt_ctkeyfrom ctkeyfrom,pt_cnkey cnkey, pt_tourtype tourtype,pt_mainplaces mainplaces, pt_addplaces addplaces, pt_tourdate tourdate,pt_pnkey pnkey,pt_pansionkeys pansionkeys,pt_days days,pt_nights nights,pt_hdkey hdkey,pt_hotelkeys hotelkeys,pt_hrkey hrkey,max(pt_key) ptkey from ' + @tableName + ' with(nolock) group by pt_ctkeyfrom,pt_cnkey,pt_tourtype,pt_mainplaces, pt_addplaces,pt_tourdate,pt_pnkey,pt_pansionkeys,pt_nights,pt_hotelnights,pt_days,pt_hdkey,pt_hotelkeys,pt_hrkey) t2
--		on t1.pt_ctkeyfrom=t2.ctkeyfrom and t1.pt_cnkey=t2.cnkey and t1.pt_tourtype = t2.tourtype and t1.pt_mainplaces=t2.mainplaces and t1.pt_addplaces=t2.addplaces and t1.pt_tourdate=t2.tourdate
--			and t1.pt_pnkey=t2.pnkey and t1.pt_nights=t2.nights and t1.pt_days=t2.days and
--				t1.pt_hdkey=t2.hdkey and t1.pt_hrkey=t2.hrkey and t1.pt_key=t2.ptkey where pt_cnkey=' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom=' + LTRIM(STR(@departFromKey)) + ' and ' + @filter
-- END Removed by Allen


-- BEGIN Added by Allen
	 begin
		if (@mwLatestPrices=0 and charindex('pt_tourkey', @filter) > 0)	
			set @sql=@sql + @tableName +  ' t1 with(nolock) where pt_cnkey=' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom=' + LTRIM(STR(@departFromKey)) + ' and ' + @filter
		else
			set @sql=@sql + @tableName +  ' t1 with(nolock) inner join (select pt_ctkeyfrom ctkeyfrom,pt_cnkey cnkey, pt_tourtype tourtype,pt_mainplaces mainplaces, pt_addplaces addplaces, pt_tourdate tourdate,pt_pnkey pnkey,pt_pansionkeys pansionkeys,pt_days days,pt_nights nights,pt_hdkey hdkey,pt_hotelkeys hotelkeys,pt_hrkey hrkey,max(pt_key) ptkey from ' + @tableName + ' with(nolock) group by pt_ctkeyfrom,pt_cnkey,pt_tourtype,pt_mainplaces, pt_addplaces,pt_tourdate,pt_pnkey,pt_pansionkeys,pt_nights,pt_hotelnights,pt_days,pt_hdkey,pt_hotelkeys,pt_hrkey) t2
		on t1.pt_ctkeyfrom=t2.ctkeyfrom and t1.pt_cnkey=t2.cnkey and t1.pt_tourtype = t2.tourtype and t1.pt_mainplaces=t2.mainplaces and t1.pt_addplaces=t2.addplaces and t1.pt_tourdate=t2.tourdate
			and t1.pt_pnkey=t2.pnkey and t1.pt_nights=t2.nights and t1.pt_days=t2.days and
				t1.pt_hdkey=t2.hdkey and t1.pt_hrkey=t2.hrkey and t1.pt_key=t2.ptkey where pt_cnkey=' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom=' + LTRIM(STR(@departFromKey)) + ' and ' + @filter
	end	
-- END Added by Allen
	else
		set @sql=@sql + @tableName + ' t1 with(nolock) inner join (select pt_ctkeyfrom ctkeyfrom,pt_cnkey cnkey, pt_tourtype tourtype,pt_mainplaces mainplaces, pt_addplaces addplaces, pt_tourdate tourdate,pt_pnkey pnkey,pt_pansionkeys pansionkeys,pt_days days,pt_nights nights,pt_hdkey hdkey,pt_hotelkeys hotelkeys,,pt_hrkey hrkey,max(pt_key) ptkey from ' + @tableName + ' with(nolock) group by pt_ctkeyfrom,pt_cnkey,pt_tourtype,pt_mainplaces, pt_addplaces,pt_tourdate,pt_pnkey,pt_pansionkeys,pt_nights,pt_hotelnights,pt_days,pt_hdkey,pt_hotelkeys,pt_hrkey) t2
	on t1.pt_ctkeyfrom=t2.ctkeyfrom and t1.pt_cnkey=t2.cnkey and t1.pt_tourtype = t2.tourtype and t1.pt_mainplaces=t2.mainplaces and t1.pt_addplaces=t2.addplaces and t1.pt_tourdate=t2.tourdate
		and t1.pt_pnkey=t2.pnkey and t1.pt_nights=t2.nights and t1.pt_days=t2.days and
			t1.pt_hdkey=t2.hdkey and t1.pt_hrkey=t2.hrkey and t1.pt_key=t2.ptkey where ' + @filter

	set @sql=@sql + ' order by pt_days,pt_nights'
	insert into #days exec(@sql)

	declare @sKeysSelect varchar(2024)
	set @sKeysSelect=''
	declare @sAlter varchar(2024)
	set @sAlter=''

	if(@hotelQuotaMask > 0 or @aviaQuotaMask > 0)
	begin
		create table #quotaCheckTable(
			pt_key bigint,			-- MEG00038762. Golubinsky. 20.12.2011. Увеличил тип до bigint
			pt_pricekey int,
			pt_tourdate datetime,			
			pt_days int,
			pt_nights int,
			pt_hdkey int,		
			pt_hdday int,
			pt_hdnights int,			
			pt_hdpartnerkey int,
			pt_rmkey int,
			pt_rckey int,
			pt_chkey int,
			pt_chday int,
			pt_chpkkey int,
			pt_chprkey int,
			pt_chbackkey int,
			pt_chbackday int,
			pt_chbackpkkey int,
			pt_chbackprkey int,
			pt_hdquota varchar(10),
			pt_chtherequota varchar(256),
			pt_chbackquota varchar(256),	
			pt_hdallquota varchar(128)
		)
	end

	declare @d int
	declare @n int
	declare @sdays varchar(10)
	declare @sWhere varchar(2024)
	set @sWhere=''
	declare @sAddSelect varchar(2024)
	set @sAddSelect=''
	declare @sAddIN varchar(2024)
	set @sAddIN=''
	declare @sAddDeclare varchar(2024)
	set @sAddDeclare=''
	declare @sJoin varchar(2024)
	set @sJoin=''
	declare @sUpdateList varchar(8000)
	set @sUpdateList=''
	declare @sTmp varchar(8000)
	set @sTmp=''
	declare @rowCount int
	declare @priceFilter nvarchar(512)
	set @priceFilter = N''
	declare @priceKeyFilter nvarchar(512)
	set @priceKeyFilter = N''

	declare @pricePart nvarchar(100)
	declare @nightsPart nvarchar(256)
	declare @hotelNightsPart nvarchar(256)

	set @pricePart = dbo.mwGetFilterPart(@filter, 'pt_price')

	declare dCur cursor for select days,nights from #days
	open dCur
	fetch next from dCur into @d,@n
	while (@@fetch_status=0)
	begin
		set @sdays=LTRIM(STR(@d)) + '_' + LTRIM(STR(@n))
		if(substring(@sortExpr, 1, 1) = '*')
		begin
			set @sortExpr = 'p_' + @sdays + substring(@sortExpr, 2, len(@sortExpr) - 1)
		end

		if(len(@sKeysSelect) > 0)
			set @sKeysSelect=@sKeysSelect + ','

		if (@pagingType = 5)
			set @sKeysSelect=@sKeysSelect + 'p_' + @sdays + ',pk_' + @sdays + ',null prk_' + @sdays + ',null hq_' + @sdays +',null cq_' + @sdays + ',null cbq_' + @sdays
		else if (@pagingType = 0)
			set @sKeysSelect=@sKeysSelect + 'p_' + @sdays + ',pk_' + @sdays 

		if(@pricePart is not null)
		begin
			if(len(@priceFilter) > 0)
				set @priceFilter = @priceFilter  + ' or '

			set @priceFilter = @priceFilter + replace(@pricePart, 'pt_price', 'p_' + @sdays)
		end

		if(len(@priceKeyFilter) > 0)
			set @priceKeyFilter = @priceKeyFilter  + ' or '

		set @priceKeyFilter = @priceKeyFilter + 'pk_' + @sdays + ' > 0'

		if(@hotelQuotaMask > 0 or @aviaQuotaMask > 0)
		begin

			if(len(@sAlter) > 0)
				set @sAlter=@sAlter + ','

			if(len(@sAddSelect) > 0)
				set @sAddSelect=@sAddSelect + ','

			if (@pagingType = 5)
			begin
				set @sAlter=@sAlter + 'p_' + @sdays + ' float,pk_' + @sdays + ' int,prk_' + @sdays + ' int,hq_' + @sdays + ' varchar(10),cq_' + @sdays + ' varchar(256),cbq_' + @sdays + ' varchar(256)'

--				if(len(@sUpdateList) > 0)
--					set @sUpdateList=@sUpdateList + ','
				set @sUpdateList=@sUpdateList + '
				if exists(select pt_key from #quotaCheckTable where pt_days = ' + LTRIM(STR(@d)) + ' and pt_nights = ' + LTRIM(STR(@n)) + ')
				update #resultsTable set'

				set @sUpdateList = @sUpdateList + '
					prk_' + @sdays + ' = (case when pk_' + @sdays + ' = tbl.pt_key then pt_pricekey end),
					hq_' + @sdays + ' = (case when pk_' + @sdays + ' = tbl.pt_key then pt_hdquota end),
					cq_' + @sdays + ' = (case when pk_' + @sdays + ' = tbl.pt_key then pt_chtherequota end),
					cbq_' + @sdays + ' = (case when pk_' + @sdays + ' = tbl.pt_key then pt_chbackquota end)' 

				set @sUpdateList=@sUpdateList + '
				from (select * from #quotaCheckTable where pt_days = ' + LTRIM(STR(@d)) + ' and pt_nights = ' + LTRIM(STR(@n)) + ') tbl
				where CURRENT OF dataCursor'

				if(len(@sAddDeclare) > 0)
					set @sAddDeclare=@sAddDeclare + ','

				set @sAddDeclare=@sAddDeclare + '@pk_' + @sdays + ' int'

				set @sAddSelect=@sAddSelect + '@pk_' + @sdays + ' = pk_' + @sdays

				if(len(@sAddIN) > 0)
					set @sAddIN=@sAddIN + ','

				set @sAddIN=@sAddIN + '@pk_' + @sdays
			end
			else if (@pagingType = 0)
			begin
				set @sAlter=@sAlter + 'p_' + @sdays + ' float,pk_' + @sdays + ' int'

				if(len(@sWhere) > 0)
					set @sWhere=@sWhere + ' or '

				set @sWhere=@sWhere + 'pt_key in (select pk_' + @sdays + ' from #resultsTable)'

				set @sAddSelect=@sAddSelect + ' t_' + @sdays + '.pt_pricekey prk_' + @sdays + ', t_' + @sdays + '.pt_hdquota hq_' + @sdays + ', t_' + @sdays + '.pt_chtherequota cq_' + @sdays + ', t_' + @sdays + '.pt_chbackquota cbq_' + @sdays

				set @sJoin=@sJoin + ' left outer join #quotaCheckTable t_' + @sdays + ' on t.pk_' + @sdays + ' = t_' + @sdays + '.pt_key'

			end
		end

		fetch next from dCur into @d,@n
	end
	close dCur
	deallocate dCur

	if(len(@sKeysSelect) > 0 and(@hotelQuotaMask > 0 or @aviaQuotaMask > 0))
	begin
		set @sTmp = 'alter table #resultsTable add ' + @sAlter
		exec(@sTmp)

		if(@pricePart is not null)
		begin
			set @filter = REPLACE(@filter, @pricePart, '1 = 1')
			set @filter = @filter + ' and (' + @priceFilter + ')'
			set @sWhere = @sWhere + ' and ' + @pricePart
		end

		set @nightsPart = dbo.mwGetFilterPart(@filter, 'pt_nights')
		if(@nightsPart is not null)
			set @filter = REPLACE(@filter, @nightsPart, '1 = 1')

		set @hotelNightsPart = dbo.mwGetFilterPart(@filter, 'pt_hotelnights')
		while(@hotelNightsPart is not null)
		begin
			set @filter = REPLACE(@filter, @hotelNightsPart, '1 = 1')
			set @hotelNightsPart = dbo.mwGetFilterPart(@filter, 'pt_hotelnights')
		end

		set @filter = @filter + ' and (' + @priceKeyFilter + ')'
		
		--MEG00038933 Tkachuk 16-02-2012
		--вызываем с последним параметром=null, иначе пытается записать в #resultsTable доп.столбец, и падает с ошибкой
		insert into #resultsTable exec PagingSelect @pagingType,@sKeysSelect,@spageNum,@spageSize,@filter,@sortExpr,@tableName,@viewName, null
		
		--MEG00038933 Tkachuk 16-02-2012
		--получаем количество строк не через output-переменную в предыдущей строке, а через select в результирующей таблице
		Set @rowCount = (select COUNT(*) from #resultsTable)
		Select @rowCount

		declare @aviaMask smallint

		if (@pagingType = 5)
		begin
			declare dataCursor cursor for
				select paging_id from #resultsTable
			for update

			open dataCursor

			declare @paging_id int, @reviewed int, @selected int, @actual smallint, @actualRow smallint

			set @aviaMask = @aviaQuotaMask
			set @reviewed = @pageNum
			set @selected = 0

			fetch next from dataCursor into @paging_id
		end
		else if (@pagingType = 0)
		begin
			set @aviaMask = null
		end
		while (@pagingType = 0 or (@@fetch_status = 0 and @selected < @pageSize))
		begin
			if (@pagingType = 5)
			begin
				set @actualRow = 0

				set @sTmp = 'declare ' + @sAddDeclare + '
							select ' + @sAddSelect + ' from #resultsTable where paging_id = ' + ltrim(str(@paging_id)) + '
							select pt_key, pt_pricekey, pt_tourdate, pt_days,	pt_nights, pt_hdkey, pt_hdday,
									pt_hdnights, pt_hdpartnerkey, pt_rmkey,	pt_rckey, pt_chkey,	pt_chday, pt_chpkkey,
									pt_chprkey, pt_chbackkey, pt_chbackday, pt_chbackpkkey, pt_chbackprkey, null, null, null, null
							from ' + @tableName + ' with(nolock)
							where pt_key in (' + @sAddIN + ')'
			end
			else if (@pagingType = 0)
			begin
				set @sTmp = 'select pt_key, pt_pricekey, pt_tourdate, pt_days,	pt_nights, pt_hdkey, pt_hdday,
									pt_hdnights, pt_hdpartnerkey, pt_rmkey,	pt_rckey, pt_chkey,	pt_chday, pt_chpkkey,
									pt_chprkey, pt_chbackkey, pt_chbackday, pt_chbackpkkey, pt_chbackprkey, null, null, null, null
							from ' + @tableName + ' with(nolock)
							where ' + @sWhere
			end

			insert into #quotaCheckTable exec(@sTmp)

			declare quotaCursor cursor for
			select pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,
				pt_chkey,pt_chbackkey,
				pt_hdday,pt_hdnights,(case when isnull(@checkAllPartnersQuota, 0) > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when @checkFlightPacket > 0 then pt_chpkkey else -1 end) as pt_chpkkey,pt_chprkey,
				pt_chbackday,(case when @checkFlightPacket > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey, pt_chbackprkey,pt_days
			from #quotaCheckTable
			for update of pt_hdquota,pt_chtherequota,pt_chbackquota

			declare @hdkey int,@rmkey int,@rckey int,@tourdate datetime,
				@chkey int,@chbackkey int,@hdday int,@hdnights int,@hdprkey int,
				@chday int,@chpkkey int,@chprkey int,@chbackday int,
				@chbackpkkey int,@chbackprkey int,@days int

			open quotaCursor

			fetch next from quotaCursor into @hdkey,@rmkey,@rckey,
				@tourdate,@chkey,@chbackkey,@hdday,@hdnights,@hdprkey,
				@chday,@chpkkey,@chprkey,@chbackday,
				@chbackpkkey,@chbackprkey,@days

			declare @tmpHotelQuota varchar(10)
			declare @tmpThereAviaQuota varchar(256)		
			declare @tmpBackAviaQuota varchar(256)		
			declare @allPlaces int,@places int

			while(@@fetch_status=0)
			begin
				set @actual=1		
	
				if(@aviaQuotaMask > 0)
				begin
					set @tmpThereAviaQuota=null
					if(@chkey > 0)
					begin 
						select @tmpThereAviaQuota=res from #checked where svkey=1 and code=@chkey and date=@tourdate and day=@chday and days=@days and prkey=@chprkey and pkkey=@chpkkey
						if (@tmpThereAviaQuota is null)
						begin
							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @days, @expiredReleaseResult, @aviaMask, @tmpThereAviaQuota output
							insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(1,@chkey,0,0,@tourdate,@chday,@days,@chprkey,@chpkkey,@tmpThereAviaQuota)
						end
						if(len(@tmpThereAviaQuota)=0)
							set @actual=0						
					end
					set @tmpBackAviaQuota=null
					if(@chbackkey > 0)
					begin
						select @tmpBackAviaQuota=res from #checked where svkey=1 and code=@chbackkey and date=@tourdate and day=@chbackday and days=@days and prkey=@chbackprkey and pkkey=@chbackpkkey
						if (@tmpBackAviaQuota is null)
						begin
							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chbackkey, @flightGroups,@agentKey,@chbackprkey, @tourdate,@chbackday,@requestOnRelease,@noPlacesResult,@checkAgentQuota,@checkCommonQuota,@checkNoLongQuota,@findFlight,@chbackpkkey,@days,@expiredReleaseResult,@aviaMask, @tmpBackAviaQuota output
							insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey,@tmpBackAviaQuota)
						end
						if(len(@tmpBackAviaQuota)=0)
							set @actual=0
					end
				end
				if(@hotelQuotaMask > 0)
				begin
					set @tmpHotelQuota=null
					select @tmpHotelQuota=res,@places=places from #checked where svkey=3 and code=@hdkey and rmkey=@rmkey and rckey=@rckey and date=@tourdate and day=@hdday and days=@hdnights and prkey=@hdprkey
					if (@tmpHotelQuota is null)
					begin
						select @places=qt_places,@allPlaces=qt_allPlaces from dbo.mwCheckQuotesEx(3,@hdkey,@rmkey,@rckey, @agentKey,@hdprkey,@tourdate,@hdday,@hdnights,@requestOnRelease,@noPlacesResult,@checkAgentQuota,@checkCommonQuota,@checkNoLongQuota,0,0,0,0,0,@expiredReleaseResult)
						set @tmpHotelQuota=ltrim(str(@places)) + ':' + ltrim(str(@allPlaces))
						insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res,places) values(3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota,@places)
					end
			
					if((@places > 0 and (@hotelQuotaMask & 1)=0) or (@places=0 and (@hotelQuotaMask & 2)=0) or (@places=-1 and (@hotelQuotaMask & 4)=0))
						set @actual=0
				end
				update #quotaCheckTable set pt_hdquota=@tmpHotelQuota,
					pt_chtherequota=@tmpThereAviaQuota,
					pt_chbackquota=@tmpBackAviaQuota
				where CURRENT OF quotaCursor
				
				if (@pagingType = 5)
				begin
					if (@actual > 0)
						set @actualRow = 1
				end

				fetch next from quotaCursor into @hdkey,@rmkey,@rckey,
					@tourdate,@chkey,@chbackkey,@hdday,@hdnights,@hdprkey,
					@chday,@chpkkey,@chprkey,@chbackday,
					@chbackpkkey,@chbackprkey,@days
			end

			close quotaCursor
			deallocate quotaCursor

			if (@pagingType = 5)
			begin
				if(@actualRow > 0)
				begin
					set @sTmp = @sUpdateList--'update #resultsTable set ' + @sUpdateList + ', pt_actual = 1 from #quotaCheckTable where CURRENT OF dataCursor'
					set @sTmp = @sTmp + '
					update #resultsTable set pt_actual = 1 where CURRENT OF dataCursor
					'
--					print @sTmp
--					select * from #resultsTable
--					select * from #quotaCheckTable
					exec (@sTmp)
--					select * from #resultsTable

					set @selected = @selected + 1
				end

				truncate table #quotaCheckTable
				
				set @reviewed=@reviewed + 1

				fetch next from dataCursor into @paging_id
			end
			else if (@pagingType = 0)
			begin
				set @sTmp = 'select t.*, ' + @sAddSelect + ' from #resultsTable t ' + @sJoin + ' order by t.paging_id'
				exec(@sTmp)
				break
			end
		end

		if (@pagingType = 5)
		begin
			close dataCursor
			deallocate dataCursor
			
			select @reviewed
			select * from #resultsTable where pt_actual = 1 order by paging_id
		end
	end
	else if(len(@sKeysSelect) > 0)
		exec PagingSelect @pagingType,@sKeysSelect,@spageNum,@spageSize,@filter,@sortExpr,@tableName,@viewName, 1
	else
	begin
		select 0
		if (@pagingType = 5)
			select 0
		select * from #resultsTable
	end
end
else
begin

	-- @pageSize > @MAX_ROWCOUNT=считаем,что в этом случае пейджинг не нужен - тянется все
	if(@pageSize > @MAX_ROWCOUNT)
	begin
		set @sql=@sql + '
			select 0
			select
			'
	end
	else -- реализуем пейджинг
	begin
		create table #Paging(
			pgId int identity,
			ptKey int primary key,
			ptpricekey bigint,
			newPrice money,
			pt_hdquota varchar(10),
			pt_chtherequota varchar(256),
			pt_chbackquota varchar(256),
			chkey int,
			chbackkey int,
			stepId int,
			priceCorrection float,
			pt_hdallquota varchar(256),
			-- признак того что вариант был подмешан (нужно для выделения)
			pt_smartSearch bit default 0
		)
		
		if((@pagingType <> @ACTUALPLACES_PAGING and @pagingType <> @DYNAMIC_SPO_PAGING) or (@hotelQuotaMask <= 0 and @aviaQuotaMask <= 0))
			set @sql=@sql + ' 
			insert into #Paging(ptkey) select ' 
		else
		begin

			-- Подмешивание отелей (SmartSearch) работает только для первой страницы
			if (@mwUseSmartSearch = 1 and @pageNum = 0)
			begin
				-- максимально возможное количество результов, которые могут быть подмешаны
				declare @maxSmartSearchResult tinyint; set @maxSmartSearchResult = 3;
				declare @smaxSmartSearchResult varchar(3); set @smaxSmartSearchResult=LTRIM(STR(@maxSmartSearchResult))
				
				-- количество реально подмешанных вариантов
				declare @realDashVariantsNumber smallint;
				
				set @sql=@sql + '
				declare quotaCursor cursor fast_forward read_only for
				select pt_key,pt_tourkey,pt_pricekey
				,pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,pt_hdday,pt_hdnights, (case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chpkkey else -1 end) as pt_chpkkey,pt_chprkey,pt_chbackday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey,pt_chbackprkey,pt_days, 
				pt_chkey, pt_chbackkey, 0, '''' pt_chdirectkeys, '''' pt_chbackkeys, '''' pt_hddetails
				, pt_directFlightAttribute, pt_backFlightAttribute, pt_mainplaces, pt_hrkey
				from ' + @tableName + ' with(nolock) inner join hotelPriorities with(nolock) on pt_hdkey = hp_hdkey'
				
				if @HideWithNotStartedSaleDate = 1
					set @sql = @sql + ' inner join tp_tours with (nolock) on pt_tourkey = to_key and (TO_DateValidBegin IS NULL OR getdate() >= TO_DateValidBegin) AND (TO_DateValid IS NULL OR getdate() <= TO_DateValid) '
					
				set @sql = @sql + ' where (' + @filter
				-- null не может быть для ВСЕХ одновременно приоритетов присутствующих в фильтах
				-- т.к. по стране фильтруем всегда, то приоритет для страны проверяем на null тоже всегда
				set @sql = @sql + ') and (HP_CountryPriority is not null'
				-- если есть фильтр для города, то проверяем на null приоритет для города
				if (charindex('pt_ctkey',@filter) > 0)
				begin
					set @sql = @sql + ' or HP_CityPriority is not null '
				end
				-- если есть фильтр для курорта, то проверяем на null приоритет для курорта
				if (charindex('pt_rskey',@filter) > 0)
				begin
					set @sql = @sql + ' or HP_ResortPriority is not null '
				end
				set @sql = @sql + ') '
				set @sql = @sql + '
				-- фильтр по отсутсвию инфанта
				and not exists (select top 1 1 from accmdmentype where ac_key=pt_ackey and ac_name like ''%инфант%'')
				order by '
				
				-- если в фильтре есть город
				if (charindex('pt_ctkey',@filter) > 0)
				begin
					set @sql = @sql + 'case when HP_CityPriority is null then 1 else 0 end, hp_cityPriority, '
				end
				
				-- если в фильтре есть курорт
				if (charindex('pt_rskey',@filter) > 0)
				begin
					set @sql = @sql + 'case when HP_ResortPriority is null then 1 else 0 end, hp_resortPriority, '
				end
				
				-- по стране и стандартной сортировке сортируем в любом случае
				set @sql = @sql + 'case when HP_CountryPriority is null then 1 else 0 end, hp_countryPriority, ' + @sortExpr

				-- запустим mwCheckQuotesCycle с последним параметром = 1 (индикатор того, что ищем подмешанные варианты)
				-- маски квот для подмешанных вариантов:
				-- отель: 1 - есть
				-- перелет: 1 - есть
				set @sql=@sql + '
				open quotaCursor

				exec dbo.mwCheckQuotesCycle ' + ltrim(str(@pagingType))+ ', ' + @spageNum + ', ' + @smaxSmartSearchResult + ', ' + ltrim(str(@agentKey)) + ', 1, 1, ''' + @flightGroups + ''', ' + ltrim(str(@checkAgentQuota)) + ', ' + ltrim(str(@checkCommonQuota)) + ', ' + ltrim(str(@checkNoLongQuota)) + ', ' + ltrim(str(@requestOnRelease)) + ', ' + ltrim(str(@expiredReleaseResult)) + ', ' + ltrim(str(@noPlacesResult)) + ', ' + ltrim(str(@findFlight)) + ', 1

				close quotaCursor
				deallocate quotaCursor
				'
				--print @sql;
				exec (@sql);
				set @sql = '';
				-- после этого в #Paginge - хранится столько строк сколько мы подмешали (0-3)
				-- уменьшим pageSize на это число, чтобы сохранить общее кол-во выводимых строк
				select @realDashVariantsNumber = count(1) from #Paging;
				set @pageSize = @pageSize - @realDashVariantsNumber;
				set @spageSize=ltrim(str(@pageSize));
			end

			set @sql=@sql + ' 
			declare quotaCursor cursor fast_forward read_only for '
			if(@pagingType = @DYNAMIC_SPO_PAGING)
				set @sql = @sql + ' with Prices as (select '
			else
				set @sql = @sql + ' select '
		end

		if(@pageSize < @MAX_ROWCOUNT)
		begin
			if(@pagingType=@SIMPLE_PAGING)
				set @sql=@sql + ' top ' + str(@MAX_ROWCOUNT)
			else if((@pagingType=@ACTUALPLACES_PAGING or @pagingType=@DYNAMIC_SPO_PAGING) and @hotelQuotaMask=0 and @aviaQuotaMask=0)
				set @sql=@sql + ' top ' + @spageSize
		end
	
		set @sql=@sql + ' pt_key,pt_tourkey, pt_pricekey '
		if((@pagingType=@ACTUALPLACES_PAGING or @pagingType=@DYNAMIC_SPO_PAGING) and (@hotelQuotaMask > 0 or @aviaQuotaMask > 0))
		begin
			set @sql=@sql + ',pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,pt_hdday,pt_hdnights, (case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chpkkey else -1 end) as pt_chpkkey,pt_chprkey,pt_chbackday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey,pt_chbackprkey,pt_days, '
			if(@pagingType <> @DYNAMIC_SPO_PAGING)
				set @sql = @sql + ' pt_chkey, pt_chbackkey, 0, pt_chdirectkeys, pt_chbackkeys, pt_hddetails '
			else
				set @sql = @sql + ' ch_key as pt_chkey, chb_key as pt_chbackkey, row_number() over(order by ' + @sortExpr + ') as rowNum '
		end
		set @sql=@sql + ' , pt_directFlightAttribute, pt_backFlightAttribute, pt_mainplaces, pt_hrkey from ' + @tableName + ' with(nolock) '
		
		if @HideWithNotStartedSaleDate = 1
			set @sql = @sql + ' inner join tp_tours with (nolock) on pt_tourkey = to_key and (TO_DateValidBegin IS NULL OR getdate() >= TO_DateValidBegin) AND (TO_DateValid IS NULL OR getdate() <= TO_DateValid) '

		if(@pagingType = @DYNAMIC_SPO_PAGING)
			set @sql = @sql + ' left outer join 
			(select pt_tourdate as tourdate, pt_chbackday as chbackday, pt_chkey as chkey, pt_chbackkey as chbackkey, ch.ch_key as ch_key, chb.ch_key as chb_key 
				from (select distinct pt_tourdate, pt_chbackday, pt_chkey, pt_chbackkey from ' + @tableName + ' where ' + @filter + ') ptd 
				left outer join charter ptch with(nolock) on (ptch.ch_key = pt_chkey) left outer join charter ptchb with(nolock) on (ptchb.ch_key = pt_chbackkey)
				left outer join charter ch with(nolock) on (ptch.ch_citykeyfrom = ch.ch_citykeyfrom and ptch.ch_citykeyto = ch.ch_citykeyto) left outer join charter chb with(nolock) on (ptchb.ch_citykeyto = chb.ch_citykeyto and ptchb.ch_citykeyfrom = chb.ch_citykeyfrom and chb.ch_airlinecode = ch.ch_airlinecode) 
			left outer join airseason a with(nolock) on (a.as_chkey = ch.ch_key and ptd.pt_tourdate between a.as_datefrom and a.as_dateto and a.as_week like (''%'' +  ltrim(str(datepart(dw, dateadd(day, -1, ptd.pt_tourdate))))+ ''%'')) left outer join airseason ab with(nolock) on (ab.as_chkey = chb.ch_key and dateadd(day, pt_chbackday - 1, ptd.pt_tourdate) between ab.as_datefrom and ab.as_dateto and ab.as_week like (''%'' +  ltrim(str(datepart(dw, dateadd(day, pt_chbackday - 2, ptd.pt_tourdate)))) + ''%''))) pt1
		on (pt_tourdate = tourdate and pt_chkey = chkey and pt_chbackkey = chbackkey and pt_chbackday = chbackday)'

		if (@mwSearchType=0)
			set @sql=@sql + ' where pt_cnkey=' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom=' +  LTRIM(STR(@departFromKey)) + ' and ' + @filter
		else 
			set @sql=@sql + ' where ' + @filter
			

		if((@pagingType=@ACTUALPLACES_PAGING) and @pageNum > 0)
		begin
			declare @a int
--			--и еще добавим невключающее условие по количеству предварительно просмотренных записей
--			set @sql=@sql + ' and pt_key not in (select top '+@spageNum+' pt_key '
--
--			if (@mwSearchType=0)
--				set @sql=@sql + ' from dbo.mwPriceTable  with(nolock) where pt_cnkey=' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom=' + LTRIM(STR(@departFromKey)) + ' and ' + @filter
--			else
--				set @sql=@sql + ' from ' + dbo.mwGetPriceViewName (@countryKey,@departFromKey) + ' with(nolock) where ' + @filter
--
--			if len(isnull(@sortExpr,'')) > 0
--				set @sql=@sql + ' order by '+ @sortExpr
--			set @sql=@sql + ') '
		end
		else if(@pagingType = @DYNAMIC_SPO_PAGING)
			set @sql = @sql + ') select * from Prices where rowNum > ' + @spageNum
		
		if(substring(@sortExpr, 1, 1) = '*')					-- begin tkachuk 21.02.2012 Исправлена ошибка, возникающая при некотором наборе параметров
		begin
			set @sortExpr = SUBSTRING(@sortExpr, 2, LEN(@sortExpr) - 1)
			set @sortExpr = LTRIM(@sortExpr)
			
			if(SUBSTRING(@sortExpr, 1, 1) = ',')
			begin
				set @sortExpr = SUBSTRING(@sortExpr, 2, LEN(@sortExpr) - 1)
				set @sortExpr = LTRIM(@sortExpr)
			end
		end														-- end tkachuk 21.02.2012

		if (len(isnull(@sortExpr,'')) > 0 and @pagingType <> @DYNAMIC_SPO_PAGING)
			set @sql=@sql + ' order by '+ @sortExpr
	
		if(@pagingType=@ACTUALPLACES_PAGING or @pagingType=@DYNAMIC_SPO_PAGING)
		begin
			if (@pageNum=0) -- количество записей возвращаем только при запросе первой страницы
			begin
				set @sql=@sql + ' 
				select count(*) from ' + @tableName + ' with(nolock) '
				
				if @HideWithNotStartedSaleDate = 1
					set @sql = @sql + ' inner join tp_tours with (nolock) on pt_tourkey = to_key and (TO_DateValidBegin IS NULL OR getdate() >= TO_DateValidBegin) AND (TO_DateValid IS NULL OR getdate() <= TO_DateValid)'
				
				if(@pagingType = @DYNAMIC_SPO_PAGING)
					set @sql = @sql + ' left outer join 
						(select pt_tourdate tourdate, pt_chbackday chbackday, pt_chkey chkey, pt_chbackkey chbackkey, ch.ch_key as ch_key, chb.ch_key as chb_key 
							from (select distinct pt_tourdate, pt_chbackday, pt_chkey, pt_chbackkey from ' + @tableName + ' where ' + @filter + ') ptd 
							left outer join charter ptch with(nolock) on (ptch.ch_key = pt_chkey) left outer join charter ptchb with(nolock) on (ptchb.ch_key = pt_chbackkey) left outer join charter ch with(nolock) on (ptch.ch_citykeyfrom = ch.ch_citykeyfrom and ptch.ch_citykeyto = ch.ch_citykeyto)
						left outer join charter chb with(nolock) on (ptchb.ch_citykeyto = chb.ch_citykeyto and ptchb.ch_citykeyfrom = chb.ch_citykeyfrom and chb.ch_airlinecode = ch.ch_airlinecode) left outer join airseason a with(nolock) on (a.as_chkey = ch.ch_key and ptd.pt_tourdate between a.as_datefrom and a.as_dateto and a.as_week like (''%'' +  ltrim(str(datepart(dw, dateadd(day, -1, ptd.pt_tourdate))))+ ''%''))
						left outer join airseason ab with(nolock) on (ab.as_chkey = chb.ch_key and dateadd(day, pt_chbackday - 1, ptd.pt_tourdate) between ab.as_datefrom and ab.as_dateto and ab.as_week like (''%'' +  ltrim(str(datepart(dw, dateadd(day, pt_chbackday - 2, ptd.pt_tourdate)))) + ''%''))) pt1
					on (pt_tourdate = tourdate and pt_chkey = chkey and pt_chbackkey = chbackkey and pt_chbackday = chbackday)'
				if (@mwSearchType=0)
					set @sql = @sql + ' where pt_cnkey=' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom=' + LTRIM(STR(@departFromKey)) + ' and ' + @filter
				else
					set @sql = @sql + ' where ' + @filter
			end
			else
				set @sql=@sql + ' select 0 '

			if(@hotelQuotaMask=0 and @aviaQuotaMask=0)
				set @sql=@sql + ' 
					select ' + ltrim(str(@pageNum + @pageSize))
			else
			begin
				set @sql=@sql + '
				open quotaCursor

				exec dbo.mwCheckQuotesCycle ' + ltrim(str(@pagingType))+ ', ' + @spageNum + ', ' + @spageSize + ', ' + ltrim(str(@agentKey)) + ', ' + ltrim(str(@hotelQuotaMask)) + ', ' + ltrim(str(@aviaQuotaMask)) + ', ''' + @flightGroups + ''', ' + ltrim(str(@checkAgentQuota)) + ', ' + ltrim(str(@checkCommonQuota)) + ', ' + ltrim(str(@checkNoLongQuota)) + ', ' + ltrim(str(@requestOnRelease)) + ', ' + ltrim(str(@expiredReleaseResult)) + ', ' + ltrim(str(@noPlacesResult)) + ', ' + ltrim(str(@findFlight)) + ', 0, ''' + @tableName + '''

				close quotaCursor
				deallocate quotaCursor
				'
				if(@pagingType = @DYNAMIC_SPO_PAGING)
					set @sql = @sql + 'select dbo.GetDynamicRulesStepValue(getdate())'
			end
		end
		else
		begin

			set @sql=@sql + '
			select @@rowCount'
		end

		exec(@sql)

		if(@pagingType=@SIMPLE_PAGING)
		begin
			set @sql ='
			DECLARE @firstRecord int,@lastRecord int
			SET @firstRecord=('+ @spageNum + ' - 1) * ' + @spageSize+ ' + 1
			SET @lastRecord=('+ @spageNum +' *'+ @spageSize + ') 
			select '
		end
		else
			set @sql= ' select '

	end

	set @sql=@sql + '
		pt_tourdate,
		pt_days,
		pt_nights,
		pt_cnkey,
		pt_ctkeyfrom,
		pt_ctkeyto,
		pt_tourkey,
		pt_tourtype,
		pt_tlkey,
		pt_main,
		pt_pricelistkey,
		pt_pricekey,'
	if (@pagingType = 1)
	begin
		set @sql=@sql + 'pt_price,'
	end
	else
	begin
		set @sql=@sql + 'case when newPrice is not null then newPrice else pt_price end as pt_price,'
	end		
	set @sql=@sql + 'pt_hdkey,
		pt_hdpartnerkey,
		pt_rskey,
		pt_ctkey,
		pt_hdstars,
		pt_pnkey,
		pt_hrkey,
		pt_rmkey,
		pt_rckey,
		pt_ackey,
		pt_childagefrom,
		pt_childageto,
		pt_childagefrom2,
		pt_childageto2,
		pt_hdname,
		pt_tourname,
		pt_pnname,
		pt_pncode,
		pt_rmname,
		pt_rmcode,
		pt_rcname,
		pt_rccode,
		pt_acname,
		pt_accode,
		pt_rsname,
		pt_ctname,
		pt_rmorder,
		pt_rcorder,
		pt_acorder,
		pt_rate,
		tl_webhttp pt_toururl,
		hd_http pt_hotelurl,
		[pt_hdday],
		[pt_hdnights],
		[pt_chday],
		[pt_chpkkey],
		[pt_chprkey],
		[pt_chbackday],
		[pt_chbackpkkey],
		[pt_chbackprkey],
		[pt_ctkeybackfrom],
		[pt_ctkeybackto],
		pt_hotelkeys,
		pt_hotelroomkeys,
		pt_hotelstars,
		pt_pansionkeys,
		pt_hotelnights,
		pt_key,
		pt_hddetails,
		pt_topricefor,'		-- MEG00031932. Golubinsky. 06.07.2011. Включение в результат типа цены

	if(@pagingType = @DYNAMIC_SPO_PAGING)
		set @sql = @sql + '
		chkey as	pt_chkey,
		chbackkey as pt_chbackkey,
		stepId as pt_hdstepindex,
		priceCorrection as pt_hdpricecorrection
	'
	else
		set @sql = @sql + '
		[pt_chkey],
		[pt_chbackkey]
	'

	if (@pagingType = @ACTUALPLACES_PAGING)
	begin
		set @sql = @sql + '
		,[pt_smartSearch]
	'
	end

	if(@getServices > 0)
		set @sql=@sql + ',dbo.mwGetServiceClasses(pt_pricelistkey) pt_srvClasses'
	if (@pagingType <> @SIMPLE_PAGING)
	begin
		if(@hotelQuotaMask > 0)
			set @sql=@sql + ',pt_hdquota,pt_hdallquota '
		if(@aviaQuotaMask > 0)
			set @sql=@sql + ',pt_chtherequota,pt_chbackquota '
	end
	if(@calculateVisaDeadLine > 0)
		set @sql=@sql + ',dbo.mwGetVisaDeadlineDate(pt_tlkey, pt_tourdate, pt_ctkeyfrom) pt_visadeadline '

	if(@pagingType = @DYNAMIC_SPO_PAGING)
		set @sql = @sql + ', (''<nobr><b>'' + isnull(ch.ch_airlinecode, '''') + '' '' + isnull(ch.ch_flight, '''') + ''</b>'' + ''('' + isnull(ltrim(str(datepart(hh, a.as_timefrom))), '''') + '':'' + isnull(ltrim(str(datepart(mi, a.as_timefrom))), '''') + ''-'' + isnull(ltrim(str(datepart(hh, a.as_timeto))), '''') + '':'' + isnull(ltrim(str(datepart(mi, a.as_timeto))), '''') + '')</nobr><br/>'' + isnull(ch.ch_aircraft, '''') + ''&nbsp;('' + isnull(ch.ch_portcodefrom, '''') + ''-'' + isnull(ch.ch_portcodeto, '''') + '')'') as pt_chinfo
						,(''<nobr><b>'' + isnull(chb.ch_airlinecode, '''') + '' '' + isnull(chb.ch_flight, '''') + ''</b>''  + ''('' + isnull(ltrim(str(datepart(hh, ab.as_timefrom))), '''') + '':'' + isnull(ltrim(str(datepart(mi, ab.as_timefrom))), '''') + ''-'' + isnull(ltrim(str(datepart(hh, ab.as_timeto))), '''') + '':'' + isnull(ltrim(str(datepart(mi, ab.as_timeto))), '''') + '')</nobr><br/>'' + isnull(chb.ch_aircraft, '''') + ''&nbsp;('' + isnull(chb.ch_portcodefrom, '''') + ''-'' + isnull(chb.ch_portcodeto, '''') + '')'') as pt_chbackinfo'

	if(@pagingType=@SIMPLE_PAGING and (@hotelQuotaMask > 0 or @aviaQuotaMask > 0))
		set @sql=@sql + ' into #resultsTable '

	if (@mwSearchType=0)
		set @sql=@sql + ' from mwPriceTable'
	else
		set @sql=@sql + ' from ' + dbo.mwGetPriceViewName (@countryKey,@departFromKey)
	set @sql=@sql + ' with(nolock) inner join hoteldictionary with(nolock) on pt_hdkey=hd_key inner join tbl_turlist with(nolock) on pt_tlkey=tl_key '

	if(@pageSize > @MAX_ROWCOUNT)
	begin
		set @sql=@sql + ' where ' + @filter

		if len(isnull(@sortExpr,'')) > 0
			set @sql=@sql + ' order by '+ @sortExpr

		if(@pagingType=@SIMPLE_PAGING)
		begin
			set @sql=@sql + '
			select * from #resultsTable
			'
		end
	end
	else
	begin
		set @sql=@sql + ' inner join #Paging on (pt_key=ptKey) '
		if(@pagingType = @DYNAMIC_SPO_PAGING)
			set @sql = @sql + ' left outer join Charter ch with(nolock) on chkey = ch.ch_key left outer join airseason a with(nolock) on (pt_chkey = a.as_chkey and pt_tourdate between a.as_datefrom and a.as_dateto and charindex(cast(datepart(dw, dateadd(day, -1, pt_tourdate)) as varchar(1)), a.as_week) > 0)
					left outer join Charter chb with(nolock) on chbackkey = chb.ch_key left outer join airseason ab with(nolock) on (pt_chbackkey = ab.as_chkey and dateadd(day, pt_chbackday - 1, pt_tourdate) between ab.as_datefrom and ab.as_dateto and charindex(cast(datepart(dw, dateadd(day, pt_chbackday-2, pt_tourdate)) as varchar(1)), ab.as_week) > 0)'
		if(@pagingType=@SIMPLE_PAGING)
		begin
			set @sql=@sql + ' where pgId between @firstRecord and @lastRecord order by pgId'

			if(@hotelQuotaMask > 0 or @aviaQuotaMask > 0)
				set @sql=@sql + '

					declare quotaCursor cursor for
					select pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,
						pt_chkey,pt_chbackkey,
						pt_hdday,pt_hdnights,(case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0)))+ ' > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when ' + ltrim(str(@checkFlightPacket))+ ' > 0 then pt_chpkkey else -1 end) as pt_chpkkey,pt_chprkey,
						pt_chbackday,(case when ' + ltrim(str(@checkFlightPacket))+ ' > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey,pt_chbackprkey,pt_days
					from #resultsTable
					for update of pt_hdquota,pt_chtherequota,pt_chbackquota
	
					declare @hdkey int,@rmkey int,@rckey int,@tourdate datetime,
						@chkey int,@chbackkey int,@hdday int,@hdnights int,@hdprkey int,
						@chday int,@chpkkey int,@chprkey int,@chbackday int,
						@chbackpkkey int,@chbackprkey int,@days int
	
					open quotaCursor
	
					fetch next from quotaCursor into @hdkey,@rmkey,@rckey,
						@tourdate,@chkey,@chbackkey,@hdday,@hdnights,@hdprkey,
						@chday,@chpkkey,@chprkey,@chbackday,
						@chbackpkkey,@chbackprkey,@days
	
					declare @tmpHotelQuota varchar(10)
					declare @tmpThereAviaQuota varchar(256)		
					declare @tmpBackAviaQuota varchar(256)		
					declare @allPlaces int,@places int
	
					while(@@fetch_status=0)
					begin
						'				
					if(@hotelQuotaMask > 0)
						set @sql=@sql + ' 
						set @tmpHotelQuota=null
						select @tmpHotelQuota=res from #checked where svkey=3 and code=@hdkey and rmkey=@rmkey and rckey=@rckey and date=@tourdate and day=@hdday and days=@hdnights and prkey=@hdprkey
						if (@tmpHotelQuota is null)
						begin
							select @places=qt_places,@allPlaces=qt_allPlaces from dbo.mwCheckQuotesEx(3,@hdkey,@rmkey,@rckey,' + ltrim(str(@agentKey)) + ',@hdprkey,@tourdate,@hdday,@hdnights,' + ltrim(str(@requestOnRelease))+ ',' + ltrim(str(@noPlacesResult))+ ',' + ltrim(str(@checkAgentQuota)) + ',' + ltrim(str(@checkCommonQuota)) + ',' + ltrim(str(@checkNoLongQuota)) + ',0,0,0,0,0,' + ltrim(str(@expiredReleaseResult)) +')
							set @tmpHotelQuota=ltrim(str(@places)) + '':'' + ltrim(str(@allPlaces))
							insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota)
						end
						'
					if(@aviaQuotaMask > 0)
						set @sql=@sql + ' 
						set @tmpThereAviaQuota=null
						if(@chkey > 0)
						begin
							select @tmpThereAviaQuota=res from #checked where svkey=1 and code=@chkey and date=@tourdate and day=@chday and days=@days and prkey=@chprkey and pkkey=@chpkkey
							if (@tmpThereAviaQuota is null)
							begin
								exec dbo.mwCheckFlightGroupsQuotes ' + ltrim(str(@pagingType)) + ',@chkey,''' + @flightGroups + ''',' + ltrim(str(@agentKey)) + ',@chprkey, @tourdate,@chday,' + ltrim(str(@requestOnRelease))+ ',' + ltrim(str(@noPlacesResult))+ ',' + ltrim(str(@checkAgentQuota)) + ',' + ltrim(str(@checkCommonQuota)) + ',' + ltrim(str(@checkNoLongQuota)) + ',' + ltrim(str(@findFlight)) + ',@chpkkey,@days,' + ltrim(str(@expiredReleaseResult)) +',null, @tmpThereAviaQuota output
								insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(1,@chkey,0,0,@tourdate,@chday,@days,@chprkey,@chpkkey,@tmpThereAviaQuota)
							end
						end

						set @tmpBackAviaQuota=null
						if(@chbackkey > 0)
						begin
							select @tmpBackAviaQuota=res from #checked where svkey=1 and code=@chbackkey and date=@tourdate and day=@chbackday and days=@days and prkey=@chbackprkey and pkkey=@chbackpkkey
							if (@tmpBackAviaQuota is null)
							begin
								exec dbo.mwCheckFlightGroupsQuotes ' + ltrim(str(@pagingType)) + ',@chbackkey,''' + @flightGroups + ''',' + ltrim(str(@agentKey)) + ',@chbackprkey, @tourdate,@chbackday,' + ltrim(str(@requestOnRelease))+ ',' + ltrim(str(@noPlacesResult))+ ',' + ltrim(str(@checkAgentQuota)) + ',' + ltrim(str(@checkCommonQuota)) + ',' + ltrim(str(@checkNoLongQuota)) + ',' + ltrim(str(@findFlight)) + ',@chbackpkkey,@days,' + ltrim(str(@expiredReleaseResult)) +',null, @tmpBackAviaQuota output
								insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey,@tmpBackAviaQuota)
							end
						end
						'

					set @sql=@sql + '
						update #resultsTable set pt_hdquota=@tmpHotelQuota,
							pt_chtherequota=@tmpThereAviaQuota,
							pt_chbackquota=@tmpBackAviaQuota
						where CURRENT OF quotaCursor


						fetch next from quotaCursor into @hdkey,@rmkey,@rckey,
							@tourdate,@chkey,@chbackkey,@hdday,@hdnights,@hdprkey,
							@chday,@chpkkey,@chprkey,@chbackday,
							@chbackpkkey,@chbackprkey,@days
					end

					close quotaCursor
					deallocate quotaCursor

					if (@calculateVisaDeadLine > 0)
					begin
						update #resultsTable
						set pt_visadeadline = dbo.mwGetVisaDeadlineDate(pt_tlkey, pt_tourdate, pt_ctkeyfrom)
					end

					select * from #resultsTable
				'
			end
			else
				set @sql=@sql + ' order by pgId '

	end

exec (@sql)

if exists (select 1 from SystemSettings where SS_ParmName like 'LogPagingState' and SS_ParmValue = '1')
begin
	declare @DurationQuery int
	SET @DurationQuery = DATEDIFF(millisecond, @beginTime, GetDate())
	INSERT INTO [dbo].[Megatec_StateDataPaging]
			   ([SDP_Code],[SDP_Name],[SDP_PagingType],[SDP_CountryKey]
			   ,[SDP_DepartFromKey],[SDP_Filter],[SDP_SortExpr],[SDP_PageNum],[SDP_PageSize]
			   ,[SDP_AgentKey],[SDP_HotelQuotaMask],[SDP_AviaQuotaMask],[SDP_GetServices],[SDP_FlightGroups]
			   ,[SDP_CheckAgentQuota],[SDP_CheckCommonQuota],[SDP_CheckNoLongQuota],[SDP_RequestOnRelease],[SDP_ExpiredReleaseResult]
			   ,[SDP_NoPlacesResult],[SDP_FindFlight],[SDP_CheckFlightPacket],[SDP_CheckAllPartnersQuota],[SDP_CalculateVisaDeadLine]
			   ,[SDP_NoSmartSearch],[SDP_Value],[SDP_AppName],[SDP_HostName])
		 VALUES
			   (10001 ,'Paging. Выполнение' ,@pagingType ,@countryKey
				,@departFromKey ,@filter ,@sortExpr ,@pageNum ,@pageSize
				,@agentKey ,@hotelQuotaMask ,@aviaQuotaMask ,@getServices ,@flightGroups
				,@checkAgentQuota ,@checkCommonQuota ,@checkNoLongQuota ,@requestOnRelease ,@expiredReleaseResult
				,@noPlacesResult ,@findFlight ,@checkFlightPacket ,@checkAllPartnersQuota ,@calculateVisaDeadLine
				,@noSmartSearch ,@DurationQuery, APP_NAME(),HOST_NAME())
end

end
GO

GRANT EXECUTE on [dbo].[Paging] to public
GO
/*********************************************************************/
/* end sp_Paging.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_RecalculatePriceListScheduler.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RecalculatePriceListScheduler]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[RecalculatePriceListScheduler]
GO

CREATE PROCEDURE [dbo].[RecalculatePriceListScheduler]
AS
--<DATE>2014-02-27</DATE>
---<VERSION>9.2.21.8</VERSION>
BEGIN

	declare @cpkey int
	declare @priceTOKey int
	declare @saleDate datetime
	declare @nullCostAsZero smallint
	declare @noFlight smallint
	declare @useHolidayRule smallint
		
	begin tran
		select top 1 @cpkey = CP_Key 
		from CalculatingPriceLists 
		where CP_StartTime is not null and (CP_Update = 0 and CP_Status = 3 and CP_StartTime<=GETDATE()) order by CP_StartTime asc
		UPDATE CalculatingPriceLists WITH (ROWLOCK) Set CP_Status=1 where CP_Key=@cpkey
	commit tran
	if (@cpkey is not null)
	begin
		select @priceTOKey = CP_PriceTourKey, @saleDate = CP_SaleDate,
			 @nullCostAsZero = CP_NullCostAsZero, @noFlight = CP_NoFlight, @useHolidayRule = CP_UseHolidayRule
		from CalculatingPriceLists where CP_Key = @cpkey
		begin try
			exec CalculatePriceList @priceTOKey, @cpkey, @saleDate, @nullCostAsZero, @noFlight, 0, @useHolidayRule
		end try
		begin catch
			UPDATE CalculatingPriceLists with (rowlock) set CP_Status=2 where CP_Key=@cpkey
			--логируем ошибку
			DECLARE @ErrorMessage varchar(500)
			SELECT @ErrorMessage = ERROR_MESSAGE()
			EXEC dbo.InsHistory '', null, 11, @priceTOKey, 'ERR', @ErrorMessage, 'Ошибка при расчете тура', 0, ''
		end catch
	end

	-- проверяем расчеты, которые завершились с ошибкой
	DECLARE @ErrorHours int = 4, @CP_Key int

	DECLARE calc_cursor CURSOR FOR 
	SELECT	cp.CP_Key FROM dbo.CalculatingPriceLists cp
	JOIN dbo.TP_Tours tp ON cp.CP_TourKey = tp.TO_TRKey
	WHERE (cp.CP_Status = 1 OR cp.CP_StartTime IS NOT NULL) 
	AND tp.TO_PROGRESS != 100 and DATEDIFF(HOUR, tp.TO_UPDATETIME, GETDATE()) >= @ErrorHours
	ORDER BY cp.CP_StartTime ASC

	OPEN calc_cursor
	FETCH NEXT FROM calc_cursor 
	INTO @CP_Key

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		if @CP_Key is NOT NULL
		BEGIN
			UPDATE dbo.CalculatingPriceLists
			SET CP_Status = 2 -- ошибка расчета
			WHERE CP_Key = @CP_Key
		END
	FETCH NEXT FROM calc_cursor
	INTO @CP_Key
	END
 
	CLOSE calc_cursor;
	DEALLOCATE calc_cursor;

END
GO

GRANT EXEC ON [dbo].[RecalculatePriceListScheduler] TO PUBLIC
GO
/*********************************************************************/
/* end sp_RecalculatePriceListScheduler.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_CostOffersUpdate.sql */
/*********************************************************************/
if exists ( select  * from    sys.triggers where   object_id = object_id(N'[dbo].[T_CostOffersUpdate]') )
	DROP TRIGGER [dbo].[T_CostOffersUpdate]
GO
if (not exists (select top 1 1 from ObjectAliases where OA_Id = 44005))
begin
	INSERT into ObjectAliases (OA_Id, OA_Alias, OA_Name)
	values (44005, 'Состояние ЦБ', 'State CostOffers')
end
go

CREATE TRIGGER [dbo].[T_CostOffersUpdate]
ON [dbo].[CostOffers]
FOR UPDATE, INSERT, DELETE
AS
if ( update(co_name) or update(co_code) or update(co_SaleDateBeg) or update(co_SaleDateEnd)  or update(CO_State)
	or (not exists(select top 1 1 from inserted) and exists (select top 1 1 from deleted)))
BEGIN
--<VERSION>2009.2.12.1</VERSION>
--<DATE>2012-02-28</DATE>
  DECLARE @CO_Id int
  
  DECLARE @OCO_Name nvarchar(254)
  DECLARE @OCO_Code nvarchar(254)
  DECLARE @OCO_SaleDateBeg datetime
  DECLARE @OCO_SaleDateEnd datetime
  DECLARE @OCO_State smallint
  
  DECLARE @NCO_Name nvarchar(254)
  DECLARE @NCO_Code nvarchar(254)
  DECLARE @NCO_SaleDateBeg datetime
  DECLARE @NCO_SaleDateEnd datetime
  DECLARE @NCO_State smallint

  DECLARE @sMod varchar(3)
  DECLARE @nDelCount int
  DECLARE @nInsCount int
  DECLARE @nHIID int
  DECLARE @sHI_Text varchar(254)
  
  DECLARE @bNeedCommunicationUpdate smallint
	  
  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED

  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
	DECLARE cur_CostOffers CURSOR FOR 
	SELECT 	N.CO_Id,null,null,null,null,null,
			N.CO_Name,N.CO_Code,N.CO_SaleDateBeg,N.CO_SaleDateEnd,N.CO_State
	  FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
	DECLARE cur_CostOffers CURSOR FOR 
	SELECT 	O.CO_Id,O.CO_Name,O.CO_Code,O.CO_SaleDateBeg,O.CO_SaleDateEnd,O.CO_State,
			null,null,null,null,null
	FROM DELETED O
  END
  ELSE 
  BEGIN
	SET @sMod = 'UPD'
	DECLARE cur_CostOffers CURSOR FOR 
	SELECT 	N.CO_Id,O.CO_Name,O.CO_Code,O.CO_SaleDateBeg,O.CO_SaleDateEnd,O.CO_State,
			N.CO_Name,N.CO_Code,N.CO_SaleDateBeg,N.CO_SaleDateEnd,N.CO_State
	FROM DELETED O, INSERTED N 
	WHERE N.CO_Id = O.CO_Id
  END
  
  OPEN cur_CostOffers
	FETCH NEXT FROM cur_CostOffers INTO 
		@CO_Id,@OCO_Name,@OCO_Code,@OCO_SaleDateBeg,@OCO_SaleDateEnd,@OCO_State,
			@NCO_Name,@NCO_Code,@NCO_SaleDateBeg,@NCO_SaleDateEnd,@NCO_State
	WHILE @@FETCH_STATUS = 0
	BEGIN
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OCO_Name, '') != ISNULL(@NCO_Name, '') OR
			ISNULL(@OCO_Code, '') != ISNULL(@NCO_Code, '') OR
			ISNULL(@OCO_SaleDateBeg, '') != ISNULL(@NCO_SaleDateBeg, '') OR
			ISNULL(@OCO_SaleDateEnd, '') != ISNULL(@NCO_SaleDateEnd, '') OR
			ISNULL(@OCO_State, '') != ISNULL(@NCO_State, '')
			)
		BEGIN
			------------Запись в историю--------------------------------------------------------------------
			if (@sMod = 'INS')
			BEGIN
				SET @sHI_Text = ISNULL(@NCO_Name, '')
			END
			else if (@sMod = 'DEL')
				BEGIN
					SET @sHI_Text = ISNULL(@OCO_Name, '')
				END
			else if (@sMod = 'UPD')
			BEGIN
				SET @sHI_Text = ISNULL(@NCO_Name, '')
			END
			
			EXEC @nHIID = dbo.InsHistory null, null, 44, @CO_Id, @sMod, @sHI_Text, '', 0, ''
			
			--------Детализация--------------------------------------------------
	
			If (ISNULL(@OCO_Name, '') != ISNULL(@NCO_Name, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 44001, @OCO_Name, @NCO_Name, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END
			
			If (ISNULL(@OCO_Code, '') != ISNULL(@NCO_Code, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 44002, @OCO_Code, @NCO_Code, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END
				
			If (ISNULL(@OCO_SaleDateBeg, '') != ISNULL(@NCO_SaleDateBeg, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 44003, null, null, null, null, @OCO_SaleDateBeg, @NCO_SaleDateBeg, 0, @bNeedCommunicationUpdate output
				END
				
			If (ISNULL(@OCO_SaleDateEnd, '') != ISNULL(@NCO_SaleDateEnd, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 44004, null, null, null, null, @OCO_SaleDateEnd, @NCO_SaleDateEnd, 0, @bNeedCommunicationUpdate output
				END

			If (ISNULL(@OCO_State, '') != ISNULL(@NCO_State, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 44005, @OCO_State, @NCO_State, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END
		END
		FETCH NEXT FROM cur_CostOffers INTO 
		@CO_Id,@OCO_Name,@OCO_Code,@OCO_SaleDateBeg,@OCO_SaleDateEnd,@OCO_State,
		@NCO_Name,@NCO_Code,@NCO_SaleDateBeg,@NCO_SaleDateEnd,@NCO_State
	END
  CLOSE cur_CostOffers
  DEALLOCATE cur_CostOffers
END
GO



/*********************************************************************/
/* end T_CostOffersUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_DogovorListUpdate.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_DogovorListUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_DogovorListUpdate]
GO

CREATE TRIGGER [T_DogovorListUpdate]
ON [dbo].[tbl_DogovorList]
FOR UPDATE, INSERT, DELETE
AS
IF @@ROWCOUNT > 0
BEGIN
--<VERSION>2009.2.17.2</VERSION>
--<DATE>2012-12-12</DATE>
  DECLARE @ODL_DgCod varchar(10)
  DECLARE @ODL_Key int
  DECLARE @ODL_SvKey int
  DECLARE @ODL_Code int
  DECLARE @ODL_SubCode1 int
  DECLARE @ODL_SubCode2 int
  DECLARE @ODL_CnKey int
  DECLARE @ODL_CtKey int
  DECLARE @ODL_NMen smallint
  DECLARE @ODL_Day smallint
  DECLARE @ODL_NDays smallint
  DECLARE @ODL_PartnerKey int
  DECLARE @ODL_Cost money
  DECLARE @ODL_Brutto money
  DECLARE @ODL_Discount money
  DECLARE @ODL_Wait smallint
  DECLARE @ODL_Control int
  DECLARE @ODL_sDateBeg varchar(10)
  DECLARE @ODL_DateBeg datetime
  DECLARE @ODL_sDateEnd varchar(10)
  DECLARE @ODL_DateEnd datetime
  DECLARE @ODL_RealNetto money
  DECLARE @ODL_Attribute int
  DECLARE @ODL_PaketKey int
  DECLARE @ODL_Name varchar(250)
  DECLARE @ODL_Payed money
  DECLARE @ODL_DGKey int
  DECLARE @ODL_QuoteKey int
  DECLARE @ODL_TimeBeg datetime
  DECLARE @ODL_TimeEnd datetime

  DECLARE @NDL_DgCod varchar(10)
  DECLARE @NDL_Key int
  DECLARE @NDL_SvKey int
  DECLARE @NDL_Code int
  DECLARE @NDL_SubCode1 int
  DECLARE @NDL_SubCode2 int
  DECLARE @NDL_CnKey int
  DECLARE @NDL_CtKey int
  DECLARE @NDL_NMen smallint
  DECLARE @NDL_Day smallint
  DECLARE @NDL_NDays smallint
  DECLARE @NDL_PartnerKey int
  DECLARE @NDL_Cost money
  DECLARE @NDL_Brutto money
  DECLARE @NDL_Discount money
  DECLARE @NDL_Wait smallint
  DECLARE @NDL_Control int
  DECLARE @NDL_sDateBeg varchar(10)
  DECLARE @NDL_DateBeg datetime
  DECLARE @NDL_sDateEnd varchar(10)
  DECLARE @NDL_DateEnd datetime
  DECLARE @NDL_RealNetto money
  DECLARE @NDL_Attribute int
  DECLARE @NDL_PaketKey int
  DECLARE @NDL_Name varchar(250)
  DECLARE @NDL_Payed money
  DECLARE @NDL_DGKey int
  DECLARE @NDL_QuoteKey int
  DECLARE @NDL_TimeBeg datetime
  DECLARE @NDL_TimeEnd datetime

  DECLARE @sMod varchar(3)
  DECLARE @nDelCount int
  DECLARE @nInsCount int
  DECLARE @nHIID int
  DECLARE @sHI_Text varchar(254)
  DECLARE @DL_Key int
  DECLARE @nDGSorGlobalCode_Old int, @nDGSorGlobalCode_New int,  @nDGSorCode_New int, @dDGTourDate datetime, @nDGKey int
  DECLARE @bNeedCommunicationUpdate smallint
  DECLARE @nSVKey int
  DECLARE @sDisableDogovorStatusChange varchar(254), @sUpdateMainDogovorStatuses varchar(254)

  DECLARE @dg_key INT

  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED

  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_DogovorList CURSOR FOR 
    SELECT 	N.DL_Key,
			null, null, null, null, null, null, null, null, null, null, null,
			null, null, null, null, null, null, null, null, 
			null, null, null, null, null, null, null,
			N.DL_DgCod, N.DL_DGKey, N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_SubCode2, N.DL_CnKey, N.DL_CtKey, N.DL_NMen, N.DL_Day, N.DL_NDays, 
			N.DL_PartnerKey, N.DL_Cost, N.DL_Brutto, N.DL_Discount, N.DL_Wait, N.DL_Control, N.DL_DateBeg, N.DL_DateEnd,
			N.DL_RealNetto, N.DL_Attribute, N.DL_PaketKey, N.DL_Name, N.DL_Payed, N.DL_QuoteKey, N.DL_TimeBeg
			
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_DogovorList CURSOR FOR 
    SELECT 	O.DL_Key,
			O.DL_DgCod, O.DL_DGKey, O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_SubCode2, O.DL_CnKey, O.DL_CtKey, O.DL_NMen, O.DL_Day, O.DL_NDays, 
			O.DL_PartnerKey, O.DL_Cost, O.DL_Brutto, O.DL_Discount, O.DL_Wait, O.DL_Control, O.DL_DateBeg, O.DL_DateEnd,
			O.DL_RealNetto, O.DL_Attribute, O.DL_PaketKey, O.DL_Name, O.DL_Payed, O.DL_QuoteKey, O.DL_TimeBeg, 
			null, null, null, null, null, null, null, null, null, null, null,
			null, null, null, null, null, null, null, null, 
			null, null, null, null, null, null, null
    FROM DELETED O
  END
  ELSE 
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_DogovorList CURSOR FOR 
    SELECT 	N.DL_Key,
			O.DL_DgCod, O.DL_DGKey, O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_SubCode2, O.DL_CnKey, O.DL_CtKey, O.DL_NMen, O.DL_Day, O.DL_NDays, 
			O.DL_PartnerKey, O.DL_Cost, O.DL_Brutto, O.DL_Discount, O.DL_Wait, O.DL_Control, O.DL_DateBeg, O.DL_DateEnd,
			O.DL_RealNetto, O.DL_Attribute, O.DL_PaketKey, O.DL_Name, O.DL_Payed, O.DL_QuoteKey, O.DL_TimeBeg,
	  		N.DL_DgCod, N.DL_DGKey, N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_SubCode2, N.DL_CnKey, N.DL_CtKey, N.DL_NMen, N.DL_Day, N.DL_NDays, 
			N.DL_PartnerKey, N.DL_Cost, N.DL_Brutto, N.DL_Discount, N.DL_Wait, N.DL_Control, N.DL_DateBeg, N.DL_DateEnd,
			N.DL_RealNetto, N.DL_Attribute, N.DL_PaketKey, N.DL_Name, N.DL_Payed, N.DL_QuoteKey, N.DL_TimeBeg
    FROM DELETED O, INSERTED N 
    WHERE N.DL_Key = O.DL_Key
  END

    OPEN cur_DogovorList
    FETCH NEXT FROM cur_DogovorList INTO 
		@DL_Key, 
			@ODL_DgCod, @ODL_DGKey, @ODL_SvKey, @ODL_Code, @ODL_SubCode1, @ODL_SubCode2, @ODL_CnKey, @ODL_CtKey, @ODL_NMen, @ODL_Day, @ODL_NDays, 
			@ODL_PartnerKey, @ODL_Cost, @ODL_Brutto, @ODL_Discount, @ODL_Wait, @ODL_Control, @ODL_DateBeg, @ODL_DateEnd, 
			@ODL_RealNetto, @ODL_Attribute, @ODL_PaketKey, @ODL_Name, @ODL_Payed, @ODL_QuoteKey, @ODL_TimeBeg,
			@NDL_DgCod, @NDL_DGKey, @NDL_SvKey, @NDL_Code, @NDL_SubCode1, @NDL_SubCode2, @NDL_CnKey, @NDL_CtKey, @NDL_NMen, @NDL_Day, @NDL_NDays, 
			@NDL_PartnerKey, @NDL_Cost, @NDL_Brutto, @NDL_Discount, @NDL_Wait, @NDL_Control, @NDL_DateBeg, @NDL_DateEnd, 
			@NDL_RealNetto, @NDL_Attribute, @NDL_PaketKey, @NDL_Name, @NDL_Payed, @NDL_QuoteKey, @NDL_TimeBeg
    WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @NDL_sDateBeg=CONVERT( char(10), @NDL_DateBeg, 104)
		SET @ODL_sDateBeg=CONVERT( char(10), @ODL_DateBeg, 104)
		SET @NDL_sDateEnd=CONVERT( char(10), @NDL_DateEnd, 104)
		SET @ODL_sDateEnd=CONVERT( char(10), @ODL_DateEnd, 104)

    	------------Проверка, надо ли что-то писать в историю квот-------------------------------------------   
		If ISNULL(@ODL_QuoteKey, 0) != ISNULL(@NDL_QuoteKey, 0) and (ISNULL(@NDL_QuoteKey, 0)>1 or ISNULL(@ODL_QuoteKey, 0)>1)
		BEGIN
			declare @sOper varchar(25)
			EXEC dbo.CurrentUser @sOper output
			if ISNULL(@ODL_QuoteKey, 0)!=0
				INSERT INTO HistoryQuote (HQ_Date, HQ_Mod, HQ_Who, HQ_Text, HQ_QTKey, HQ_DLKey)
					VALUES (GETDATE(), 'DEL', @sOper, @sHI_Text, @ODL_QuoteKey, @DL_Key)
			if ISNULL(@NDL_QuoteKey, 0)!=0
				INSERT INTO HistoryQuote (HQ_Date, HQ_Mod, HQ_Who, HQ_Text, HQ_QTKey, HQ_DLKey)
					VALUES (GETDATE(), 'INS', @sOper, @sHI_Text, @NDL_QuoteKey, @DL_Key)
		END

    	------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@ODL_DgCod, '') != ISNULL(@NDL_DgCod, '')  OR
			ISNULL(@ODL_DGKey, '') != ISNULL(@NDL_DGKey, '')  OR
			ISNULL(@ODL_SvKey, '') != ISNULL(@NDL_SvKey, '')  OR
			ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, '')  OR
			ISNULL(@ODL_SubCode1, '') != ISNULL(@NDL_SubCode1, '')  OR
			ISNULL(@ODL_SubCode2, '') != ISNULL(@NDL_SubCode2, '')  OR
			ISNULL(@ODL_CnKey, '') != ISNULL(@NDL_CnKey, '')  OR
			ISNULL(@ODL_CtKey, '') != ISNULL(@NDL_CtKey, '')  OR
			ISNULL(@ODL_NMen, '') != ISNULL(@NDL_NMen, '')  OR
			ISNULL(@ODL_Day, '') != ISNULL(@NDL_Day, '')  OR
			ISNULL(@ODL_NDays, '') != ISNULL(@NDL_NDays, '')  OR
			ISNULL(@ODL_PartnerKey, '') != ISNULL(@NDL_PartnerKey, '')  OR
			ISNULL(@ODL_Cost, 0) != ISNULL(@NDL_Cost, 0)  OR
			ISNULL(@ODL_Brutto, 0) != ISNULL(@NDL_Brutto, 0)  OR
			ISNULL(@ODL_Discount, 0) != ISNULL(@NDL_Discount, 0)  OR
			ISNULL(@ODL_Wait, '') != ISNULL(@NDL_Wait, '')  OR
			ISNULL(@ODL_Control, '') != ISNULL(@NDL_Control, '')  OR
			ISNULL(@ODL_sDateBeg, '') != ISNULL(@NDL_sDateBeg, '')  OR
			ISNULL(@ODL_sDateEnd, '') != ISNULL(@NDL_sDateEnd, '')  OR
			ISNULL(@ODL_RealNetto, 0) != ISNULL(@NDL_RealNetto, 0)  OR
			ISNULL(@ODL_Attribute, '') != ISNULL(@NDL_Attribute, '')  OR
			ISNULL(@ODL_PaketKey, '') != ISNULL(@NDL_PaketKey, '') OR
			ISNULL(@ODL_Name, '') != ISNULL(@NDL_Name, '') OR 
			ISNULL(@ODL_Payed, 0) != ISNULL(@NDL_Payed, 0) OR 
			ISNULL(@ODL_TimeBeg, 0) != ISNULL(@NDL_TimeBeg, 0)
		)
		BEGIN
		  	------------Запись в историю--------------------------------------------------------------------
			if (@sMod = 'INS')
			BEGIN
				SET @sHI_Text = ISNULL(@NDL_Name, '')
				SET @nDGKey=@NDL_DGKey
				SET @nSVKey=@NDL_SvKey
			END
			else if (@sMod = 'DEL')
				BEGIN
				SET @sHI_Text = ISNULL(@ODL_Name, '')
				SET @NDL_DgCod = @ODL_DgCod
				SET @nDGKey=@ODL_DGKey
				SET @nSVKey=@ODL_SvKey
				END
			else if (@sMod = 'UPD')
			BEGIN
				SET @sHI_Text = ISNULL(@NDL_Name, '')
				SET @nDGKey=@NDL_DGKey
				SET @nSVKey=@NDL_SvKey
			END
			EXEC @nHIID = dbo.InsHistory @NDL_DgCod, @nDGKey, 2, @DL_Key, @sMod, @sHI_Text, '', 0, '', 0, @nSVKey
			--SELECT @nHIID = IDENT_CURRENT('History')		
			--------Детализация--------------------------------------------------

			DECLARE @sText_Old varchar(100)
			DECLARE @sText_New varchar(100)
    
    			DECLARE @sText_AllTypeRooming varchar(20)
			SET @sText_AllTypeRooming  = 'Все типы размещения'

			If (ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, ''))
			BEGIN
				/*
				IF @NDL_SvKey=1
				BEGIN
					-- mv26.04.2010
					-- Перенес вниз см. начиная с "-- ИНДИВИДУАЛЬНАЯ ОБРАБОТКА АВИАПЕРЕЛЕТОВ"
				END
				*/
				IF @NDL_SvKey!=1
				BEGIN
					exec dbo.GetSVCodeName @ODL_SvKey, @ODL_Code, @sText_Old output, null
					exec dbo.GetSVCodeName @NDL_SvKey, @NDL_Code, @sText_New output, null
					IF @NDL_SvKey = 2
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1028, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
					ELSE IF (@NDL_SvKey = 3 or @NDL_SvKey = 8)
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1029, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
					ELSE IF @NDL_SvKey = 4
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1030, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
					ELSE IF (@NDL_SvKey = 7 or @NDL_SvKey = 9)
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1031, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
					ELSE 
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1032, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
				END
			END

			If (ISNULL(@ODL_SubCode1, '') != ISNULL(@NDL_SubCode1, ''))
				IF @NDL_SvKey = 1 or @ODL_SvKey = 1
				BEGIN
					Select @sText_Old = AS_Code + ' ' + AS_NameRus from AirService where AS_Key = @ODL_SubCode1
					Select @sText_New = AS_Code + ' ' + AS_NameRus from AirService where AS_Key = @NDL_SubCode1
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1033, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE IF @NDL_SvKey = 2 or @NDL_SvKey = 4 or @ODL_SvKey = 2 or @ODL_SvKey = 4
				BEGIN
					Select @sText_Old = TR_Name from Transport where TR_Key = @ODL_SubCode1
					Select @sText_New = TR_Name from Transport where TR_Key = @NDL_SubCode1
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1034, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE IF @NDL_SvKey = 3 or @NDL_SvKey = 8 or @ODL_SvKey = 3 or @ODL_SvKey = 8
				BEGIN
					Select @sText_Old = RM_Name + ',' + RC_Name + ',' + AC_Code from HotelRooms,Rooms,RoomsCategory,AccmdMenType where HR_Key = @ODL_SubCode1 and RM_Key=HR_RmKey and RC_Key=HR_RcKey and AC_Key=HR_AcKey
					Select @sText_New = RM_Name + ',' + RC_Name + ',' + AC_Code from HotelRooms,Rooms,RoomsCategory,AccmdMenType where HR_Key = @NDL_SubCode1 and RM_Key=HR_RmKey and RC_Key=HR_RcKey and AC_Key=HR_AcKey
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1035, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE IF @NDL_SvKey = 7 or @NDL_SvKey = 9 or @ODL_SvKey = 7 or @ODL_SvKey = 9
				BEGIN
					IF @ODL_SubCode1 = 0
						Set @sText_Old = @sText_AllTypeRooming
					Else
						Select @sText_Old = ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_Name,'') from Cabine where CB_Key = @ODL_SubCode1
					IF @NDL_SubCode1 = 0
						Set @sText_New = @sText_AllTypeRooming
					Else
						Select @sText_New = ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_Name,'') from Cabine where CB_Key = @NDL_SubCode1
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1035, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE
				BEGIN
					Select @sText_Old = A1_Name from AddDescript1 where A1_Key = @ODL_SubCode1
					Select @sText_New = A1_Name from AddDescript1 where A1_Key = @NDL_SubCode1
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1036, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
	
			If (ISNULL(@ODL_SubCode2, '') != ISNULL(@NDL_SubCode2, ''))
				IF @NDL_SvKey = 3 or @NDL_SvKey = 7 or @ODL_SvKey = 3 or @ODL_SvKey = 7
				BEGIN
					Select @sText_Old = PN_Name from Pansion where PN_Key = @ODL_SubCode2
					Select @sText_New = PN_Name from Pansion where PN_Key = @NDL_SubCode2
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1037, @sText_Old, @sText_New, @ODL_SubCode2, @NDL_SubCode2, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE
				BEGIN
					Select @sText_Old = A2_Name from AddDescript2 where A2_Key = @ODL_SubCode2
					Select @sText_New = A2_Name from AddDescript2 where A2_Key = @NDL_SubCode2
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1038, @sText_Old, @sText_New, @ODL_SubCode2, @NDL_SubCode2, null, null, 0, @bNeedCommunicationUpdate output
				END

			If (ISNULL(@ODL_PartnerKey, '') != ISNULL(@NDL_PartnerKey, ''))
			BEGIN
				Select @sText_Old = PR_Name from Partners where PR_Key = @ODL_PartnerKey
				Select @sText_New = PR_Name from Partners where PR_Key = @NDL_PartnerKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1039, @sText_Old, @sText_New, @ODL_PartnerKey, @NDL_PartnerKey, null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_Control, '') != ISNULL(@NDL_Control, ''))
			BEGIN
				Select @sText_Old = CR_Name from Controls where CR_Key = @ODL_Control
				Select @sText_New = CR_Name from Controls where CR_Key = @NDL_Control
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1040, @sText_Old, @sText_New, @ODL_Control, @NDL_Control, null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_CtKey, '') != ISNULL(@NDL_CtKey, ''))
			BEGIN
				Select @sText_Old = CT_Name from CityDictionary where CT_Key = @ODL_CtKey
				Select @sText_New = CT_Name from CityDictionary where CT_Key = @NDL_CtKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1041, @sText_Old, @sText_New, @ODL_CtKey, @NDL_CtKey, null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_CnKey, '') != ISNULL(@NDL_CnKey, ''))
			BEGIN
				Select @sText_Old = CN_Name from Country where CN_Key = @ODL_CnKey
				Select @sText_New = CN_Name from Country where CN_Key = @NDL_CnKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1042, @sText_Old, @sText_New, @ODL_CnKey, @NDL_CnKey, null, null, 0, @bNeedCommunicationUpdate output
			END

		 	If (ISNULL(@ODL_NMen  , '') != ISNULL(@NDL_NMen, ''))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1043, @ODL_NMen  , @NDL_NMen, '', '', null, null, 0, @bNeedCommunicationUpdate output
			If (ISNULL(@ODL_Cost, 0) != ISNULL(@NDL_Cost, 0))
			BEGIN	
				Set @sText_Old = CAST(@ODL_Cost as varchar(100))
				Set @sText_New = CAST(@NDL_Cost as varchar(100))				
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1044, @sText_Old, @sText_New, '', '', null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_Brutto, 0) != ISNULL(@NDL_Brutto, 0))
			BEGIN	
				Set @sText_Old = CAST(@ODL_Brutto as varchar(100))
				Set @sText_New = CAST(@NDL_Brutto as varchar(100))				
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1045, @sText_Old, @sText_New, '', '', null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_sDateBeg, 0) != ISNULL(@NDL_sDateBeg, 0))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1046, @ODL_sDateBeg, @NDL_sDateBeg, null, null, @ODL_DateBeg, @NDL_DateBeg, 0, @bNeedCommunicationUpdate output
			If (ISNULL(@ODL_sDateEnd, 0) != ISNULL(@NDL_sDateEnd, 0))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1047, @ODL_sDateEnd, @NDL_sDateEnd, null, null, @ODL_DateEnd, @NDL_DateEnd, 0, @bNeedCommunicationUpdate output
			If (ISNULL(@ODL_NDays, 0) != ISNULL(@NDL_NDays, 0))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1048, @ODL_NDays, @NDL_NDays, null, null, null, null, 0, @bNeedCommunicationUpdate output

			If (ISNULL(@ODL_Wait, '') != ISNULL(@NDL_Wait, '')) 
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1049, @ODL_Wait, @NDL_Wait, @ODL_Wait, @NDL_Wait, null, null, 0, @bNeedCommunicationUpdate output
			END
			
			If (ISNULL(@ODL_Name, 0) != ISNULL(@NDL_Name, 0))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1050, @ODL_Name, @NDL_Name, null, null, null, null, 0, @bNeedCommunicationUpdate output
			If (ISNULL(@ODL_RealNetto, 0) != ISNULL(@NDL_RealNetto, 0))
			BEGIN
				Set @sText_Old = left(convert(varchar, @ODL_RealNetto), 10)
				Set @sText_New = left(convert(varchar, @NDL_RealNetto), 10)				
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1119, @sText_Old, @sText_New, '', '', null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_Payed, 0) != ISNULL(@NDL_Payed, 0))
			BEGIN
				Set @sText_Old = CAST(@ODL_Payed as varchar(10))
				Set @sText_New = CAST(@NDL_Payed as varchar(10))				
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1120, @sText_Old, @sText_New, '', '', null, null, 0, @bNeedCommunicationUpdate output
			END
			If @ODL_TimeBeg!=@NDL_TimeBeg
			BEGIN
				Set @sText_Old=ISNULL(CONVERT(char(5), @ODL_TimeBeg, 114), 0)
				Set @sText_New=ISNULL(CONVERT(char(5), @NDL_TimeBeg, 114), 0)
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1125, @sText_Old, @sText_New, null, null, @ODL_TimeBeg, @NDL_TimeBeg, 0, @bNeedCommunicationUpdate output
			END
			
			If (ISNULL(@ODL_Control, '') != ISNULL(@NDL_Control, '')  OR ISNULL(@ODL_Wait, '') != ISNULL(@NDL_Wait, ''))
			BEGIN
				If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey) )
					UPDATE Communications SET 
						CM_StatusConfirmed=(SELECT Count(1) FROM DogovorList, Controls WHERE DL_Control=CR_Key AND CR_GlobalState=1 AND DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey),
						CM_StatusNotConfirmed=(SELECT Count(1) FROM DogovorList, Controls WHERE DL_Control=CR_Key AND CR_GlobalState=3 AND DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey),
						CM_StatusWait=(SELECT Count(1) FROM DogovorList, Controls WHERE DL_Control=CR_Key AND CR_GlobalState=2 AND DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey),
						CM_StatusUnknown=(SELECT Count(1) FROM DogovorList, Controls WHERE DL_Control=CR_Key AND CR_GlobalState is null AND DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey)
					WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey)
			END
			If ( ( ISNULL(@ODL_Cost, 0) != ISNULL(@NDL_Cost, 0) ) or ( ISNULL(@ODL_RealNetto, 0) != ISNULL(@NDL_RealNetto, 0) ) )
			BEGIN	
				If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey) )
					UPDATE Communications SET 
						CM_SumNettoPlan=(SELECT SUM(DL_Cost) FROM DogovorList WHERE DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey),
						CM_SumNettoProvider=(SELECT SUM(DL_RealNetto) FROM DogovorList WHERE DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey)
					WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey)
			END
			-- ИНДИВИДУАЛЬНАЯ ОБРАБОТКА АВИАПЕРЕЛЕТОВ
			If (@NDL_SvKey = 1 AND ((ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, '')) OR (ISNULL(@ODL_sDateBeg, 0) != ISNULL(@NDL_sDateBeg, 0)) OR ((ISNULL(@ODL_Name, 0) != ISNULL(@NDL_Name, 0)))))
			BEGIN
				DECLARE @APFrom_Old varchar(50), @APTo_Old varchar(50), @AL_Old varchar(50)
				IF ISNULL(@ODL_Code, '') != ''
				BEGIN
					SELECT 
						@sText_Old=CH_AirLineCode + ' ' + CH_Flight,
						@APFrom_Old=(SELECT TOP 1 AP_Name FROM AirPort WHERE AP_Code=CH_PortCodeFrom), 
						@APTo_Old=(SELECT TOP 1 AP_Name FROM AirPort WHERE AP_Code=CH_PortCodeTo), 
						@AL_Old=(SELECT TOP 1 AL_Name FROM AirLine WHERE AL_Code=CH_AirLineCode) 
						FROM Charter WHERE CH_Key=@ODL_Code
				END
				DECLARE @APFrom_New varchar(50), @APTo_New varchar(50), @AL_New varchar(50)
				IF ISNULL(@NDL_Code, '') != ''
				BEGIN
					SELECT 
						@sText_New=CH_AirLineCode + ' ' + CH_Flight,
						@APFrom_New=(SELECT TOP 1 AP_Name FROM AirPort WHERE AP_Code=CH_PortCodeFrom), 
						@APTo_New=(SELECT TOP 1 AP_Name FROM AirPort WHERE AP_Code=CH_PortCodeTo), 
						@AL_New=(SELECT TOP 1 AL_Name FROM AirLine WHERE AL_Code=CH_AirLineCode) 
						FROM Charter WHERE CH_Key=@NDL_Code
				END
				If (ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1027, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
				If (ISNULL(@APFrom_Old, '') != ISNULL(@APFrom_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1135, @APFrom_Old, @APFrom_New, null, null, null, null, 0, @bNeedCommunicationUpdate output
				If (ISNULL(@APTo_Old, '') != ISNULL(@APTo_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1136, @APTo_Old, @APTo_New, null, null, null, null, 0, @bNeedCommunicationUpdate output
				If (ISNULL(@AL_Old, '') != ISNULL(@AL_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1139, @AL_Old, @AL_New, null, null, null, null, 0, @bNeedCommunicationUpdate output

				DECLARE @sTimeBeg_Old varchar(5), @sTimeEnd_Old varchar(5), @sTimeBeg_New varchar(5), @sTimeEnd_New varchar(5)
				Declare @nday int
				IF (ISNULL(@ODL_Code, '') != '')
				BEGIN
					Set @nday = DATEPART(dw, @ODL_DateBeg)  + @@DATEFIRST - 1
					If @nday > 7 
		    			set @nday = @nday - 7
					SELECT	TOP 1 
						@sTimeBeg_Old=LEFT(CONVERT(varchar, AS_TimeFrom, 8),5),
						@sTimeEnd_Old=LEFT(CONVERT(varchar, AS_TimeTo, 8),5)
					FROM 	dbo.AirSeason
					WHERE 	AS_CHKey=@ODL_Code
						and CHARINDEX(CAST(@nday as varchar(1)),AS_Week)>0
						and @ODL_DateBeg between AS_DateFrom and AS_DateTo
					ORDER BY AS_TimeFrom DESC
				END

				IF (ISNULL(@NDL_Code, '') != '')
				BEGIN
					Set @nday = DATEPART(dw, @NDL_DateBeg)  + @@DATEFIRST - 1
					If @nday > 7 
						set @nday = @nday - 7
					SELECT	TOP 1 
						@sTimeBeg_New=LEFT(CONVERT(varchar, AS_TimeFrom, 8),5),
						@sTimeEnd_New=LEFT(CONVERT(varchar, AS_TimeTo, 8),5)
					FROM 	dbo.AirSeason
					WHERE 	AS_CHKey=@NDL_Code
						and CHARINDEX(CAST(@nday as varchar(1)),AS_Week)>0
						and @NDL_DateBeg between AS_DateFrom and AS_DateTo
					ORDER BY AS_TimeFrom DESC
				END
				If (ISNULL(@sTimeBeg_Old, '') != ISNULL(@sTimeBeg_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1137, @sTimeBeg_Old, @sTimeBeg_New, null, null, null, null, 0, @bNeedCommunicationUpdate output
				If (ISNULL(@sTimeEnd_Old, '') != ISNULL(@sTimeEnd_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1138, @sTimeEnd_Old, @sTimeEnd_New, null, null, null, null, 0, @bNeedCommunicationUpdate output
			END
		END
		
		/*Запись о том что нужно квотировать услугу*/
		-- только при измении этих полей нужно перезапустить механиз квотирования
		if ((isnull(@ODL_SvKey, '') != isnull(@NDL_SvKey, '')
			or isnull(@ODL_Code, '') != isnull(@NDL_Code, '')
			or isnull(@ODL_SubCode1, '') != isnull(@NDL_SubCode1, '')
			or isnull(@ODL_PartnerKey, '') != isnull(@NDL_PartnerKey, '')
			or isnull(@ODL_sDateBeg, '') != isnull(@NDL_sDateBeg, '')
			or isnull(@ODL_sDateEnd, '') != isnull(@NDL_sDateEnd, '')
			or isnull(@ODL_NMen, '') != isnull(@NDL_NMen, ''))
			and (exists (select top 1 1 from [Service] where SV_KEY = @NDL_SvKey and SV_QUOTED = 1))
			and (@sMod = 'UPD'))
		begin
			-- создаем запись о необходимости произвести рассадку в квоту
			insert into DogovorListNeedQuoted (DLQ_DLKey, DLQ_Date, DLQ_State, DLQ_Host, DLQ_User)
			values (@DL_Key, getdate(), 0, host_name(), user_name())
		end
		
		If @bNeedCommunicationUpdate=1
		BEGIN
			If @nSVKey=1 and ( 
					(ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, '')) or 
					(ISNULL(@ODL_sDateBeg, 0) != ISNULL(@NDL_sDateBeg, 0))
					 )
			BEGIN
				If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@nDGKey)
					UPDATE Communications SET CM_ChangeDate=GetDate() WHERE CM_DGKey=@nDGKey
			END
			
			ELSE
			BEGIN
				If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey) )
					UPDATE Communications SET CM_ChangeDate=GetDate() WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey)
			END
		END
		------------Аннуляция полиса при удаления услуги----------------------------------
		if (@sMod = 'DEL')
		BEGIN
			UPDATE InsPolicy
			SET IP_ARKEY = 0, IP_AnnulDate = GetDate()
			WHERE IP_DLKey = @DL_KEY AND IP_ARKEY IS NULL AND IP_ANNULDATE IS NULL
		END

    	------------Для поддержки совместимости-------------------------------------------   

			If 	(ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, '')) or
				(ISNULL(@ODL_SubCode1, '') != ISNULL(@NDL_SubCode1, '')) or
				(ISNULL(@ODL_SubCode2, '') != ISNULL(@NDL_SubCode2, '')) or
				(ISNULL(@ODL_NDays, 0) != ISNULL(@NDL_NDays, 0)) or 
				(ISNULL(@ODL_Day, '') != ISNULL(@NDL_Day, ''))
				EXECUTE dbo.InsHistory @NDL_DgCod, @NDL_DGKey, 2, @DL_Key, 'MOD', @ODL_Name, '', 1, '', 0, @nSVKey

			If 	(ISNULL(@ODL_Wait, '') != ISNULL(@NDL_Wait, '')) 
			BEGIN
				If (@NDL_Wait = 1)
					EXECUTE dbo.InsHistory @NDL_DgCod, @NDL_DGKey, 2, @DL_Key, '+WL', @ODL_Name, '', 0, '', 0, @nSVKey
				else
					EXECUTE dbo.InsHistory @NDL_DgCod, @NDL_DGKey, 2, @DL_Key, '-WL', @ODL_Name, '', 0, '', 0, @nSVKey
			END

		    FETCH NEXT FROM cur_DogovorList INTO 
		@DL_Key, 
			@ODL_DgCod, @ODL_DGKey, @ODL_SvKey, @ODL_Code, @ODL_SubCode1, @ODL_SubCode2, @ODL_CnKey, @ODL_CtKey, @ODL_NMen, @ODL_Day, @ODL_NDays, 
			@ODL_PartnerKey, @ODL_Cost, @ODL_Brutto, @ODL_Discount, @ODL_Wait, @ODL_Control, @ODL_DateBeg, @ODL_DateEnd, 
			@ODL_RealNetto, @ODL_Attribute, @ODL_PaketKey, @ODL_Name, @ODL_Payed, @ODL_QuoteKey, @ODL_TimeBeg,
			@NDL_DgCod, @NDL_DGKey, @NDL_SvKey, @NDL_Code, @NDL_SubCode1, @NDL_SubCode2, @NDL_CnKey, @NDL_CtKey, @NDL_NMen, @NDL_Day, @NDL_NDays, 
			@NDL_PartnerKey, @NDL_Cost, @NDL_Brutto, @NDL_Discount, @NDL_Wait, @NDL_Control, @NDL_DateBeg, @NDL_DateEnd, 
			@NDL_RealNetto, @NDL_Attribute, @NDL_PaketKey, @NDL_Name, @NDL_Payed, @NDL_QuoteKey, @NDL_TimeBeg
	END
  CLOSE cur_DogovorList
  DEALLOCATE cur_DogovorList
 END
GO
/*********************************************************************/
/* end T_DogovorListUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_GroupAuthInsert.sql */
/*********************************************************************/
-- =============================================
--<VERSION>9.2.122</VERSION>
--<DATE>2014-02-26</DATE>	
-- =============================================
ALTER TRIGGER [dbo].[T_GroupAuthInsert]
   ON  [dbo].[GroupAuth]
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @insertedValue table(id int identity(1,1), MessageName nvarchar(max),GroupName nvarchar(max))
	
	INSERT INTO @insertedValue
		SELECT 'Для группы '''+sys.database_principals.name+''' создано разрешение на действие '+Actions.AC_Name as MessageName,
		sys.database_principals.name as GroupName
		FROM ((inserted left join Synonyms ON inserted.GRA_SYKEY=Synonyms.sy_key) inner join sys.database_principals On inserted.GRA_GRKey=principal_id) inner join Actions On inserted.GRA_ACKey=Actions.AC_Key	


	DECLARE @i int
	SET @i=1
	
	DECLARE @count int
	SET @count=(select COUNT(*) from @insertedValue)
	
	DECLARE @message nvarchar(max)
	DECLARE @SubjectName nvarchar(50)
	WHILE @i<=@count
	BEGIN
		
		set @message=(select MessageName from @insertedValue where id=@i)
		set @SubjectName=(select GroupName from @insertedValue where id=@i)
		
		INSERT INTO ActionsLog([ACL_DateAction], [ACL_OldValue], [ACL_NewValue], [ACL_UserLogin], [ACL_Host], [ACL_Name],[ACL_ChangeType],[ACL_ChangeSubject])
		VALUES (GETDATE(),'Выключено', 'Включено', Upper(SYSTEM_USER), HOST_NAME(), @message, 1,@SubjectName)	
			
		SET @i=@i+1
	END
END
GO
/*********************************************************************/
/* end T_GroupAuthInsert.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_mwReplDeletePrice.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[mwReplDeletePrice]'))
	DROP TRIGGER [dbo].[mwReplDeletePrice]
GO

CREATE trigger [dbo].[mwReplDeletePrice] on [dbo].[TP_Prices]
for delete as
begin
	--<DATE>2014-03-05</DATE>
	--<VERSION>9.2.21</VERSION>
	
	if dbo.mwReplIsPublisher() > 0 or (dbo.mwReplIsPublisher() <= 0 and dbo.mwReplIsSubscriber() <= 0)
	begin
		if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
		begin
			insert into dbo.mwReplDeletedPricesTemp (rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey) 
			select tp_key, to_cnkey, tl_ctdeparturekey from deleted inner join 
						TP_Tours with(nolock) on TP_TOKey=TO_Key inner join
						tbl_TurList with(nolock) on TL_KEY = TO_TRKey;
		end
		else if dbo.mwReplIsPublisher() > 0 
		begin
			insert into dbo.mwReplDeletedPricesTemp (rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey) 
			select tp_key, TO_CNKey, TL_CTDepartureKey
			from deleted
			join tp_tours on tp_tokey = to_key
			join tbl_TurList on tl_key = to_trkey
		end
	end
end
GO
/*********************************************************************/
/* end T_mwReplDeletePrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TP_Tours_mwUpdateDateValid.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='TR' and name='mwUpdateDateValid')
	drop trigger dbo.mwUpdateDateValid
go

CREATE trigger [dbo].[mwUpdateDateValid] on [dbo].[TP_Tours]
for update
as
begin

	--<VERSION>2009.2</VERSION>
	--<DATE>2014-03-05</DATE>

	if (UPDATE(TO_DateValid) 
		and exists (select top 1 1 
					from inserted ins 
					inner join deleted del on ins.TO_Key = del.TO_Key 
					where ins.TO_DateValid <> del.TO_DateValid))
	begin
		if dbo.mwReplIsSubscriber() <= 0 and dbo.mwReplIsPublisher() <= 0
		begin	

			update mwSpoDataTable
			set sd_tourvalid  = TO_DateValid
			from inserted where sd_tourkey = to_key

			update mwPriceDataTable
			set pt_tourvalid  = TO_DateValid
			from inserted where pt_tourkey = to_key

		end
		else if dbo.mwReplIsSubscriber() > 0 
		begin

			insert into [mwReplQueue]([rq_mode], [rq_tokey])
				select 5, to_key from inserted i

		end
	end
end

GO
/*********************************************************************/
/* end T_TP_Tours_mwUpdateDateValid.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TP_Tours_mwUpdatePriceTourEnabled.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='TR' and name='mwUpdatePriceTourEnabled')
	drop trigger dbo.mwUpdatePriceTourEnabled
go

CREATE trigger [dbo].[mwUpdatePriceTourEnabled] on [dbo].[TP_Tours]
for update
as
begin
	--<VERSION>9.2.19.1</VERSION>
	--<DATE>2014-02-28</DATE>

	if @@rowcount > 0 and update(to_isenabled)
	begin

		if dbo.mwReplIsSubscriber() > 0
		begin
			select i.to_key as xrq_tokey, i.TO_TRKey as xrq_trkey, i.TO_CNKey as xrq_cnkey
			into #mwReplQueue
			from inserted i 
			inner join deleted d on i.to_key = d.to_key
			where i.to_isenabled <> d.to_isenabled and i.to_isenabled = 0
			
			declare @DirTable table(xrq_cnkey int, xrq_ctkeyfrom int)
			
			insert into mwReplQueue(rq_mode, rq_tokey, rq_cnkey, rq_ctkeyfrom)
			output inserted.rq_cnkey, inserted.rq_ctkeyfrom into @DirTable (xrq_cnkey, xrq_ctkeyfrom)
			select 3, xrq_tokey, xrq_cnkey, TL_CTDepartureKey
			from #mwReplQueue
			join tbl_TurList on TL_KEY = xrq_trkey
			
			insert into mwReplDirections (rd_cnkey, rd_ctkeyfrom)
			select xrq_cnkey, isnull(xrq_ctkeyfrom, 0)
			from @DirTable
			left join mwReplDirections with(nolock) on xrq_cnkey = rd_cnkey and isnull(xrq_ctkeyfrom, 0) = rd_ctkeyfrom
			where rd_id is null
			
		end
		else if dbo.mwReplIsPublisher() <= 0
		begin

			declare @mwSearchType int
			select @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
				where SS_ParmName = 'MWDivideByCountry'

			if @mwSearchType = 0
			begin
				update mwPriceDataTable
				set pt_isenabled = 0
				from inserted i inner join deleted d on i.to_key = d.to_key			
				where pt_tourkey = i.to_key
					and i.to_isenabled <> d.to_isenabled and i.to_isenabled = 0
			end
			else
			begin
				declare @tableName varchar(100), @tokey int, @cnkey int, @ctkey int
				declare @sql varchar(8000)

				create table #tmpPriceTours(
					to_key int
				)
				create index x_tokey on #tmpPriceTours(to_key)

				insert into #tmpPriceTours
				select i.to_key
				from inserted i inner join deleted d on i.to_key = d.to_key
				where i.to_isenabled <> d.to_isenabled and i.to_isenabled = 0

				declare tblCursor cursor fast_forward read_only for 
				select 
					to_key, 
					to_cnkey, 
					tl_ctdeparturekey
				from 
					tp_tours tt with(nolock)
					inner join tbl_TurList with(nolock) on to_trkey = tl_key
				where
					exists(select 1 from #tmpPriceTours t where t.to_key = tt.to_key)

				open tblCursor

				fetch next from tblCursor into @tokey, @cnkey, @ctkey
				while @@fetch_status = 0
				begin	
					set @tableName = dbo.mwGetPriceTableName(@cnkey, @ctkey)
					IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(@tableName) AND type in (N'U'))	
					BEGIN
						set @sql = 'update ' + @tableName + ' set pt_isenabled = 0 where pt_tourkey = ' + ltrim(str(@tokey))
						exec (@sql)
					END
					fetch next from tblCursor into @tokey, @cnkey, @ctkey
				end

				close tblCursor
				deallocate tblCursor
			end

			update mwSpoDataTable
			set sd_isenabled = 0
			from inserted i inner join deleted d on i.to_key = d.to_key			
			where sd_tourkey = i.to_key
				and i.to_isenabled <> d.to_isenabled and i.to_isenabled = 0	

		end
	end
end

GO
/*********************************************************************/
/* end T_TP_Tours_mwUpdatePriceTourEnabled.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_UpdatePartner.sql */
/*********************************************************************/
/****** Object:  Trigger [dbo].[T_PartnerUpdate]    Script Date: 11.12.2013 14:13:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[T_PartnerUpdate]
ON [dbo].[tbl_Partners] 
FOR UPDATE, INSERT, DELETE
AS
---<VERSION>9.2.20</VERSION>
--<DATE>2013-12-11</DATE>
IF @@ROWCOUNT > 0
BEGIN
    DECLARE 
		@PR_Key int,
		@OPR_FullName varchar(160), @OPR_Name varchar(140), @OPR_NameEng varchar(80), @OPR_BossName varchar(40), @OPR_Boss varchar(50), @OPR_Adress varchar(330), 
		@OPR_Phones varchar(254), @OPR_Fax varchar(120), @OPR_Email varchar(50), @OPR_CTKey int, @OPR_Cod varchar(6), @OPR_Filial int, 
		@OPR_Owner int, @OPR_Deleted smallint, @OPR_LicenseNumber varchar(50), @OPR_AdditionalInfo varchar(50), @OPR_LegalAddress varchar(350), @OPR_INN varchar(30), 
		@OPR_KPP varchar(30), @OPR_CodeOKONH varchar(30), @OPR_CodeOKPO varchar(30), @OPR_HomePage varchar(100), @OPR_LegalPostIndex varchar(6), @OPR_PostIndex varchar(6), 
		@OPR_RegisterNumber varchar(50), @OPR_RegisterSeries varchar(10),

		@NPR_FullName varchar(160), @NPR_Name varchar(140), @NPR_NameEng varchar(80), @NPR_BossName varchar(40), @NPR_Boss varchar(50), @NPR_Adress varchar(330), 
		@NPR_Phones varchar(254), @NPR_Fax varchar(120), @NPR_Email varchar(50), @NPR_CTKey int, @NPR_Cod varchar(6), @NPR_Filial int, 
		@NPR_Owner int, @NPR_Deleted smallint, @NPR_LicenseNumber varchar(50), @NPR_AdditionalInfo varchar(50), @NPR_LegalAddress varchar(350), @NPR_INN varchar(30), 
		@NPR_KPP varchar(30), @NPR_CodeOKONH varchar(30), @NPR_CodeOKPO varchar(30), @NPR_HomePage varchar(100), @NPR_LegalPostIndex varchar(6), @NPR_PostIndex varchar(6), 
		@NPR_RegisterNumber varchar(50), @NPR_RegisterSeries varchar(10),
    
		@sMod varchar(3), @nDelCount int, @nInsCount int, @nHIID int, @sHI_Text varchar(254), @sText_Old varchar(254), @sText_New varchar(254)

  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED
  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_Partner CURSOR FOR 
		SELECT N.PR_Key, 
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null,
			N.PR_FullName, N.PR_Name, N.PR_NameEng, N.PR_BossName, N.PR_Boss, N.PR_Adress, 
			N.PR_Phones, N.PR_Fax, N.PR_Email, N.PR_CTKey, N.PR_Cod, N.PR_Filial, 
			N.PR_Owner, N.PR_Deleted, N.PR_LicenseNumber, N.PR_AdditionalInfo, N.PR_LegalAddress, N.PR_INN, 
			N.PR_KPP, N.PR_CodeOKONH, N.PR_CodeOKPO, N.PR_HomePage, N.PR_LegalPostIndex, N.PR_PostIndex, 
			N.PR_RegisterNumber, N.PR_RegisterSeries
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_Partner CURSOR FOR 
		SELECT O.PR_Key, 
			O.PR_FullName, O.PR_Name, O.PR_NameEng, O.PR_BossName, O.PR_Boss, O.PR_Adress, 
			O.PR_Phones, O.PR_Fax, O.PR_Email, O.PR_CTKey, O.PR_Cod, O.PR_Filial, 
			O.PR_Owner, O.PR_Deleted, O.PR_LicenseNumber, O.PR_AdditionalInfo, O.PR_LegalAddress, O.PR_INN, 
			O.PR_KPP, O.PR_CodeOKONH, O.PR_CodeOKPO, O.PR_HomePage, O.PR_LegalPostIndex, O.PR_PostIndex, 
			O.PR_RegisterNumber, O.PR_RegisterSeries, 
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null
      FROM DELETED O 
  END
  ELSE 
  BEGIN
	SET @sMod = 'UPD'
    DECLARE cur_Partner CURSOR FOR 
		SELECT N.PR_Key, 
			O.PR_FullName, O.PR_Name, O.PR_NameEng, O.PR_BossName, O.PR_Boss, O.PR_Adress, 
			O.PR_Phones, O.PR_Fax, O.PR_Email, O.PR_CTKey, O.PR_Cod, O.PR_Filial, 
			O.PR_Owner, O.PR_Deleted, O.PR_LicenseNumber, O.PR_AdditionalInfo, O.PR_LegalAddress, O.PR_INN, 
			O.PR_KPP, O.PR_CodeOKONH, O.PR_CodeOKPO, O.PR_HomePage, O.PR_LegalPostIndex, O.PR_PostIndex, 
			O.PR_RegisterNumber, O.PR_RegisterSeries, 
		  	N.PR_FullName, N.PR_Name, N.PR_NameEng, N.PR_BossName, N.PR_Boss, N.PR_Adress, 
			N.PR_Phones, N.PR_Fax, N.PR_Email, N.PR_CTKey, N.PR_Cod, N.PR_Filial, 
			N.PR_Owner, N.PR_Deleted, N.PR_LicenseNumber, N.PR_AdditionalInfo, N.PR_LegalAddress, N.PR_INN, 
			N.PR_KPP, N.PR_CodeOKONH, N.PR_CodeOKPO, N.PR_HomePage, N.PR_LegalPostIndex, N.PR_PostIndex, 
			N.PR_RegisterNumber, N.PR_RegisterSeries
      FROM DELETED O, INSERTED N 
      WHERE N.PR_Key = O.PR_Key
  END

  OPEN cur_Partner
    FETCH NEXT FROM cur_Partner INTO
		@PR_Key,
		@OPR_FullName, @OPR_Name, @OPR_NameEng, @OPR_BossName, @OPR_Boss, @OPR_Adress, 
		@OPR_Phones, @OPR_Fax, @OPR_Email, @OPR_CTKey, @OPR_Cod, @OPR_Filial, 
		@OPR_Owner, @OPR_Deleted, @OPR_LicenseNumber, @OPR_AdditionalInfo, @OPR_LegalAddress, @OPR_INN, 
		@OPR_KPP, @OPR_CodeOKONH, @OPR_CodeOKPO, @OPR_HomePage, @OPR_LegalPostIndex, @OPR_PostIndex, 
		@OPR_RegisterNumber, @OPR_RegisterSeries,
		@NPR_FullName, @NPR_Name, @NPR_NameEng, @NPR_BossName, @NPR_Boss, @NPR_Adress, 
		@NPR_Phones, @NPR_Fax, @NPR_Email, @NPR_CTKey, @NPR_Cod, @NPR_Filial, 
		@NPR_Owner, @NPR_Deleted, @NPR_LicenseNumber, @NPR_AdditionalInfo, @NPR_LegalAddress, @NPR_INN, 
		@NPR_KPP, @NPR_CodeOKONH, @NPR_CodeOKPO, @NPR_HomePage, @NPR_LegalPostIndex, @NPR_PostIndex, 
		@NPR_RegisterNumber, @NPR_RegisterSeries

    WHILE @@FETCH_STATUS = 0
    BEGIN 
	 -- Если поменялось название партнера, то апдейтим и US_COMPANYNAME для представителей этого партнера
		IF @sMod = 'UPD' AND ISNULL(@OPR_Name, '') != ISNULL(@NPR_Name, '')
		UPDATE DBO.DUP_USER SET US_COMPANYNAME = ISNULL(@NPR_Name, '') WHERE US_PRKEY = @PR_Key
	  ------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		IF	(
			ISNULL(@OPR_FullName, '')	!= ISNULL(@NPR_FullName, '') OR
			ISNULL(@OPR_Name, '')		!= ISNULL(@NPR_Name, '') OR
			ISNULL(@OPR_NameEng, '')	!= ISNULL(@NPR_NameEng, '') OR
			ISNULL(@OPR_BossName, '')	!= ISNULL(@NPR_BossName, '') OR
			ISNULL(@OPR_Boss, '')		!= ISNULL(@NPR_Boss, '') OR
			ISNULL(@OPR_Adress, '')		!= ISNULL(@NPR_Adress, '') OR
			ISNULL(@OPR_Phones, '')		!= ISNULL(@NPR_Phones, '') OR
			ISNULL(@OPR_Fax, '')		!= ISNULL(@NPR_Fax, '') OR
			ISNULL(@OPR_Email, '')		!= ISNULL(@NPR_Email, '') OR
			ISNULL(@OPR_CTKey, 0)		!= ISNULL(@NPR_CTKey, 0) OR
			ISNULL(@OPR_Cod, '')			!= ISNULL(@NPR_Cod, '') OR
			ISNULL(@OPR_Filial, 0)		!= ISNULL(@NPR_Filial, 0) OR
			ISNULL(@OPR_Owner, 0)		!= ISNULL(@NPR_Owner, 0) OR
			ISNULL(@OPR_Deleted, 0)		!= ISNULL(@NPR_Deleted, 0) OR
			ISNULL(@OPR_LicenseNumber, '')  != ISNULL(@NPR_LicenseNumber, '') OR
			ISNULL(@OPR_AdditionalInfo, '') != ISNULL(@NPR_AdditionalInfo, '') OR
			ISNULL(@OPR_LegalAddress, '')   != ISNULL(@NPR_LegalAddress, '')  OR
			ISNULL(@OPR_INN, '')			!= ISNULL(@NPR_INN, '')  OR
			ISNULL(@OPR_KPP, '')			!= ISNULL(@NPR_KPP, '')  OR
			ISNULL(@OPR_CodeOKONH, '')	!= ISNULL(@NPR_CodeOKONH, '')  OR
			ISNULL(@OPR_CodeOKPO, '')	!= ISNULL(@NPR_CodeOKPO, '')  OR
			ISNULL(@OPR_HomePage, '')	!= ISNULL(@NPR_HomePage, '')  OR
			ISNULL(@OPR_LegalPostIndex, '') != ISNULL(@NPR_LegalPostIndex, '')  OR
			ISNULL(@OPR_PostIndex, '')	!= ISNULL(@NPR_PostIndex, '')  OR
			ISNULL(@OPR_RegisterNumber, '') != ISNULL(@NPR_RegisterNumber, '')  OR
			ISNULL(@OPR_RegisterSeries, '') != ISNULL(@NPR_RegisterSeries, '') 
		)
	  BEGIN
	  	------------Запись в историю--------------------------------------------------------------------
		
		if (@sMod = 'INS') or (@sMod = 'UPD')
			SET @sHI_Text = ISNULL(@NPR_Name, '')
		else if (@sMod = 'DEL')
			SET @sHI_Text = ISNULL(@OPR_Name, '')
		EXEC @nHIID = dbo.InsHistory '', null, 10, @PR_Key, @sMod, @sHI_Text, '', 0, ''

		--------Детализация--------------------------------------------------
		if (ISNULL(@OPR_FullName, '')	!= ISNULL(@NPR_FullName, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10001, @OPR_FullName, @NPR_FullName, null, null, null, null, 0
		if (ISNULL(@OPR_Name, '')		!= ISNULL(@NPR_Name, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10002, @OPR_Name, @NPR_Name, null, null, null, null, 0
		if (ISNULL(@OPR_NameEng, '')	!= ISNULL(@NPR_NameEng, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10003, @OPR_NameEng, @NPR_NameEng, null, null, null, null, 0
		if (ISNULL(@OPR_BossName, '')	!= ISNULL(@NPR_BossName, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10004, @OPR_BossName, @NPR_BossName, null, null, null, null, 0
		if (ISNULL(@OPR_Boss, '')		!= ISNULL(@NPR_Boss, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10005, @OPR_Boss, @NPR_Boss, null, null, null, null, 0
		if (ISNULL(@OPR_Adress, '')		!= ISNULL(@NPR_Adress, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10006, @OPR_Adress, @NPR_Adress, null, null, null, null, 0
		if (ISNULL(@OPR_Phones, '')		!= ISNULL(@NPR_Phones, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10007, @OPR_Phones, @NPR_Phones, null, null, null, null, 0
		if (ISNULL(@OPR_Fax, '')		!= ISNULL(@NPR_Fax, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10008, @OPR_Fax, @NPR_Fax, null, null, null, null, 0
		if (ISNULL(@OPR_Email, '')		!= ISNULL(@NPR_Email, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10009, @OPR_Email, @NPR_Email, null, null, null, null, 0
		if (ISNULL(@OPR_CTKey, 0)		!= ISNULL(@NPR_CTKey, 0))
		BEGIN
			Set @sText_Old = null
			Set @sText_New = null
			SELECT @sText_Old=CT_Name FROM dbo.CityDictionary WHERE CT_Key=@OPR_CTKey
			SELECT @sText_New=CT_Name FROM dbo.CityDictionary WHERE CT_Key=@NPR_CTKey
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10010, @sText_Old, @sText_New, @OPR_CTKey, @NPR_CTKey, null, null, 0
		END
		if (ISNULL(@OPR_Cod, '')			!= ISNULL(@NPR_Cod, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10011, @OPR_Cod, @NPR_Cod, null, null, null, null, 0
		if (ISNULL(@OPR_Filial, 0)		!= ISNULL(@NPR_Filial, 0))
		BEGIN
			Set @sText_Old = null
			Set @sText_New = null
			SELECT @sText_Old=CASE WHEN @OPR_Filial=1 THEN 'Фирма-владелец' WHEN @OPR_Filial=2 THEN 'Филиал' ELSE '' END
			SELECT @sText_New=CASE WHEN @NPR_Filial=1 THEN 'Фирма-владелец' WHEN @NPR_Filial=2 THEN 'Филиал' ELSE '' END
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10012, @sText_Old, @sText_New, @OPR_Filial, @NPR_Filial, null, null, 0
		END
		if (ISNULL(@OPR_Owner, 0)		!= ISNULL(@NPR_Owner, 0))
		BEGIN
			Set @sText_Old = null
			Set @sText_New = null
			SELECT @sText_Old=US_FullName FROM dbo.UserList WHERE US_Key=@OPR_Owner
			SELECT @sText_New=US_FullName FROM dbo.UserList WHERE US_Key=@NPR_Owner
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10013, @sText_Old, @sText_New, @OPR_Owner, @NPR_Owner, null, null, 0
		END
		if (ISNULL(@OPR_Deleted, 0)		!= ISNULL(@NPR_Deleted, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10014, @OPR_Deleted, @NPR_Deleted, @OPR_Deleted, @NPR_Deleted, null, null, 0
		if (ISNULL(@OPR_LicenseNumber, '')  != ISNULL(@NPR_LicenseNumber, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10015, @OPR_LicenseNumber, @NPR_LicenseNumber, null, null, null, null, 0
		if (ISNULL(@OPR_AdditionalInfo, '') != ISNULL(@NPR_AdditionalInfo, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10016, @OPR_AdditionalInfo, @NPR_AdditionalInfo, null, null, null, null, 0
		if (ISNULL(@OPR_LegalAddress, '')   != ISNULL(@NPR_LegalAddress, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10017, @OPR_LegalAddress, @NPR_LegalAddress, null, null, null, null, 0
		if (ISNULL(@OPR_INN, '')			!= ISNULL(@NPR_INN, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10018, @OPR_INN, @NPR_INN, null, null, null, null, 0
		if (ISNULL(@OPR_KPP, '')			!= ISNULL(@NPR_KPP, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10019, @OPR_KPP, @NPR_KPP, null, null, null, null, 0
		if (ISNULL(@OPR_CodeOKONH, '')	!= ISNULL(@NPR_CodeOKONH, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10020, @OPR_CodeOKONH, @NPR_CodeOKONH, null, null, null, null, 0
		if (ISNULL(@OPR_CodeOKPO, '')	!= ISNULL(@NPR_CodeOKPO, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10021, @OPR_CodeOKPO, @NPR_CodeOKPO, null, null, null, null, 0
		if (ISNULL(@OPR_HomePage, '')	!= ISNULL(@NPR_HomePage, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10022, @OPR_HomePage, @NPR_HomePage, null, null, null, null, 0
		if (ISNULL(@OPR_LegalPostIndex, '') != ISNULL(@NPR_LegalPostIndex, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10023, @OPR_LegalPostIndex, @NPR_LegalPostIndex, null, null, null, null, 0
		if (ISNULL(@OPR_PostIndex, '')	!= ISNULL(@NPR_PostIndex, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10024, @OPR_PostIndex, @NPR_PostIndex, null, null, null, null, 0
		if (ISNULL(@OPR_RegisterNumber, '') != ISNULL(@NPR_RegisterNumber, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10025, @OPR_RegisterNumber, @NPR_RegisterNumber, null, null, null, null, 0
		if (ISNULL(@OPR_RegisterSeries, '') != ISNULL(@NPR_RegisterSeries, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10026, @OPR_RegisterSeries, @NPR_RegisterSeries, null, null, null, null, 0
	  END
    FETCH NEXT FROM cur_Partner INTO
		@PR_Key,
		@OPR_FullName, @OPR_Name, @OPR_NameEng, @OPR_BossName, @OPR_Boss, @OPR_Adress, 
		@OPR_Phones, @OPR_Fax, @OPR_Email, @OPR_CTKey, @OPR_Cod, @OPR_Filial, 
		@OPR_Owner, @OPR_Deleted, @OPR_LicenseNumber, @OPR_AdditionalInfo, @OPR_LegalAddress, @OPR_INN, 
		@OPR_KPP, @OPR_CodeOKONH, @OPR_CodeOKPO, @OPR_HomePage, @OPR_LegalPostIndex, @OPR_PostIndex, 
		@OPR_RegisterNumber, @OPR_RegisterSeries,
		@NPR_FullName, @NPR_Name, @NPR_NameEng, @NPR_BossName, @NPR_Boss, @NPR_Adress, 
		@NPR_Phones, @NPR_Fax, @NPR_Email, @NPR_CTKey, @NPR_Cod, @NPR_Filial, 
		@NPR_Owner, @NPR_Deleted, @NPR_LicenseNumber, @NPR_AdditionalInfo, @NPR_LegalAddress, @NPR_INN, 
		@NPR_KPP, @NPR_CodeOKONH, @NPR_CodeOKPO, @NPR_HomePage, @NPR_LegalPostIndex, @NPR_PostIndex, 
		@NPR_RegisterNumber, @NPR_RegisterSeries
    END
  CLOSE cur_Partner
  DEALLOCATE cur_Partner
END
GO
/*********************************************************************/
/* end T_UpdatePartner.sql */
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
	declare @publicationId as int

	select @publicationId = publication_id 
 			from mt.distribution.dbo.MSpublications 
			where publication = ''MW_PUB''

	declare tabsCur cursor for
	select art.source_object
	from mt.distribution.dbo.MSArticles art
	inner join sys.tables localTabs on localTabs.name = art.source_object
	where
			(art.publication_id = @publicationId)
			and (art.source_object not in (select tableName from @excludedTables)) 			
	order by art.source_object

	open tabsCur

	declare @sql varchar(4000)
	set @sql = ''''

	fetch next from tabsCur into @tabName
	while @@fetch_status = 0
	begin

		set @sql = ''alter table @tabName disable trigger all''
		set @sql = replace(@sql, ''@tabName'', @tabName)

		exec (@sql)

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
-- =====================   Обновление версии БД. 9.2.20.9 - номер версии, 2014-03-07 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.9', st_moduledate = convert(datetime, '2014-03-07', 120),  st_financeversion = '9.2.20.9', st_financedate = convert(datetime, '2014-03-07', 120)
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении версии БД', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO

BEGIN TRY	
	DECLARE @SUSER_NAME nvarchar = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar = (SELECT HOST_NAME())	

	UPDATE [dbo].[SYSTEMSETTINGS] 
	SET SS_ParmValue='2014-03-07' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO