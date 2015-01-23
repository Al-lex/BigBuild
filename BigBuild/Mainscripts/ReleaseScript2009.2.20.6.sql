/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 28.01.2014 13:07 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.5'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.6'

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
/* begin (2013.11.12)_Insert_Actions.sql */
/*********************************************************************/
--добавление action Разрешить пересадку услуг запрещенных для редактирования
IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 147) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (147, 'Разрешить пересадку услуг с запретом на редактирование', 'Разрешить пересадку услуг, несмотря на запрет редактирования параметров услуги', 'Allow transfer not editable parameters services', 0)
END
GO



/*********************************************************************/
/* end (2013.11.12)_Insert_Actions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.12.18)_ALTER_VIEW_mwFlightCosts.sql */
/*********************************************************************/
ALTER VIEW [dbo].[mwFlightCosts]
AS
SELECT     dbo.Costs.CS_CODE AS fc_code, dbo.Costs.CS_SUBCODE1 AS fc_subcode1, dbo.Costs.CS_SUBCODE2 AS fc_subcode2, dbo.Costs.CS_PKKEY AS fc_pkkey, 
                      dbo.Costs.CS_PRKEY AS fc_prkey, dbo.Costs.CS_DATE AS fc_costdatebegin, dbo.Costs.CS_DATEEND AS fc_costdateend, dbo.Costs.CS_LONG AS fc_long, 
                      dbo.Costs.CS_LONGMIN AS fc_longmin, dbo.Costs.CS_CHECKINDATEBEG AS fc_checkindatebeg, dbo.Costs.CS_CHECKINDATEEND AS fc_checkindateend, 
                      dbo.Charter.CH_CITYKEYFROM AS fc_ctkeyfrom, dbo.Charter.CH_CITYKEYTO AS fc_ctkeyto, dbo.AirSeason.AS_DATEFROM AS fc_asdatefrom, 
                      dbo.AirSeason.AS_DATETO AS fc_asdateto, dbo.AirSeason.AS_WEEK AS fc_week, dbo.Charter.CH_FLIGHT AS fc_flight, 
                      dbo.Charter.CH_AIRLINECODE AS fc_airlinecode, dbo.Costs.CS_WEEK AS fc_costweek
FROM         dbo.Costs INNER JOIN
                      dbo.Charter ON dbo.Costs.CS_SVKEY = 1 AND dbo.Costs.CS_CODE = dbo.Charter.CH_KEY INNER JOIN
                      dbo.AirSeason ON dbo.Charter.CH_KEY = dbo.AirSeason.AS_CHKEY

GO

sp_refreshviewforall 'mwFlightCosts'
GO
/*********************************************************************/
/* end (2013.12.18)_ALTER_VIEW_mwFlightCosts.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.17.12)_ALTER_MIS_Quotas.sql */
/*********************************************************************/
--<VERSION></VERSION>
--<DATE>2013-12-17</DATE>
--добавление колонки с временной печатью

--[MIS_Quotas]
if not exists (select 1 from dbo.syscolumns where name = 'MQ_RoomKey' and id = object_id(N'[dbo].[MIS_Quotas]'))
	ALTER TABLE [dbo].[MIS_Quotas] Add MQ_RoomKey int 
GO
/*********************************************************************/
/* end (2013.17.12)_ALTER_MIS_Quotas.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.01.17)_Alter_Table_HotelAccForm.sql */
/*********************************************************************/
if not exists (select 1 from dbo.syscolumns where name = 'HF_COID' and id = object_id(N'[dbo].[HotelAccForm]'))
	ALTER TABLE [dbo].[HOTELACCFORM] ADD HF_COID INT DEFAULT(0)
GO
/*********************************************************************/
/* end (2014.01.17)_Alter_Table_HotelAccForm.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.01.20)_Update_SystemSettings.sql */
/*********************************************************************/
-- Обновление имен Системных переменных для работы с дополнительной комиссией
IF EXISTS (SELECT 1 FROM SystemSettings WHERE SS_ParmName='MWAddEarlyCommDays') 
	AND NOT EXISTS (SELECT 1 FROM SystemSettings WHERE SS_ParmName='MWAddEarlyCommDaysPercent') 
BEGIN
	UPDATE SystemSettings 
	SET SS_ParmName = 'MWAddEarlyCommDaysPercent' 
	WHERE SS_ParmName = 'MWAddEarlyCommDays';
END
GO

IF EXISTS (SELECT 1 FROM SystemSettings WHERE SS_ParmName='MWAddEarlyCommValue')
	AND NOT EXISTS (SELECT 1 FROM SystemSettings WHERE SS_ParmName='MWAddEarlyCommPercent') 
BEGIN
	UPDATE SystemSettings 
	SET SS_ParmName = 'MWAddEarlyCommPercent' 
	WHERE SS_ParmName = 'MWAddEarlyCommValue';	
END
GO

IF EXISTS (SELECT 1 FROM SystemSettings WHERE SS_ParmName='MWBronniEarlyCommDays')
	AND NOT EXISTS (SELECT 1 FROM SystemSettings WHERE SS_ParmName='MWBronniEarlyCommDaysP') 
BEGIN
	UPDATE SystemSettings 
	SET SS_ParmName = 'MWBronniEarlyCommDaysP' 
	WHERE SS_ParmName = 'MWBronniEarlyCommDays';
END
GO

IF EXISTS (SELECT 1 FROM SystemSettings WHERE SS_ParmName='MWBronniEarlyCommValue')
	AND NOT EXISTS (SELECT 1 FROM SystemSettings WHERE SS_ParmName='MWBronniEarlyCommPercent') 
BEGIN
	UPDATE SystemSettings 
	SET SS_ParmName = 'MWBronniEarlyCommPercent' 
	WHERE SS_ParmName = 'MWBronniEarlyCommValue';
END
GO

/*********************************************************************/
/* end (2014.01.20)_Update_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.01.21)_Update_Descriptions.sql */
/*********************************************************************/
-- Обновление значений для доп.комиссии по названию туров
-- DS_TableId = 37 - Tables.TurLists
-- DS_DTKey = 118 - DescTypes.TourNameCommission
IF EXISTS (SELECT 1 FROM Descriptions WHERE DS_TableId = 37 AND DS_DTKey = 118 AND DS_PKKey = 0)
BEGIN
	DECLARE @pipe AS INT, @equally AS INT, @str AS VARCHAR(MAX);
	SET @str = '';
	SELECT @str = DS_Value FROM Descriptions 
	WHERE DS_TableId = 37 AND DS_DTKey = 118 AND DS_PKKey = 0;
	IF (@str != '')
	BEGIN
		SET @pipe = LEN(REPLACE(@str, '|', '**'))-LEN(@str);
		SET @equally = LEN(REPLACE(@str, '=', '**'))-LEN(@str);	
		IF (@pipe + 1 = @equally)
		BEGIN
			UPDATE Descriptions SET DS_Value = REPLACE(@str, '|', '=1|') + '=1'
			WHERE DS_TableId = 37 AND DS_DTKey = 118 AND DS_PKKey = 0;
		END
	END
END
GO

/*********************************************************************/
/* end (2014.01.21)_Update_Descriptions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalcPriceByNationalCurrencyRate.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='CalcPriceByNationalCurrencyRate')
	drop proc dbo.CalcPriceByNationalCurrencyRate
go

--<DATE>2013-12-24</DATE>
--<VERSION>2009.2.20.5</VERSION>

CREATE PROCEDURE [dbo].[CalcPriceByNationalCurrencyRate]
@dogovor_code varchar(50),
@currency varchar(5),
@old_currency varchar(5),
@national_currency varchar(5),
@price money,
@old_price money,
@who varchar(500),
@action varchar(50),
@final_price money output,
@new_currency_rate money,
@order_status smallint -- null OR passing the new value for dg_sor_code from the trigger when it's (dg_sor_code) updated
as
begin
	declare @dogovorDate datetime

	declare @sys_PrtReg varchar(5)
	set @sys_PrtReg = '0'
	select @sys_PrtReg = SS_ParmValue from SystemSettings where SS_ParmName = 'SYSPrtReg'
	if @sys_PrtReg = '1'
	begin
		set @final_price = null

		declare @current_national_price money
		set @current_national_price = null

		declare @difference money

		if @order_status is null
			select @order_status = DG_SOR_CODE, @difference = DG_PAYED - @old_price, @dogovorDate = dg_crdate from tbl_Dogovor with (nolock) where DG_CODE = @dogovor_code
		else
			select @difference = DG_PAYED - @old_price, @dogovorDate = dg_crdate from tbl_Dogovor with (nolock) where DG_CODE = @dogovor_code

		declare @flag smallint
		set @flag = 0

		if @currency <> @national_currency and
			@currency = @old_currency
			--and @order_status in (7,35)
			and @difference >= 0
		begin
			set @flag = 1
		end

		if @flag = 1
		begin
			create table #tmp (tmp_id int identity, currency_rate varchar(254), oa_id int)

			insert into #tmp(currency_rate, oa_id)
			select HI_TEXT, HI_OAId
			from history with (nolock)
			where HI_DGCOD = @dogovor_code and HI_OAId = 20 and HI_REMARK = @currency
			and HI_DATE >= @dogovorDate
			order by HI_DATE asc

			declare @last_rate money
			set @last_rate = null
			select top 1 @last_rate = cast(currency_rate as money) from #tmp order by tmp_id desc

			if @last_rate is not null
			begin
				if (@price - @old_price) = 0
				begin
					set @final_price = @old_price * @new_currency_rate
				end
				else
				begin
					declare @str varchar(1000)

					select @current_national_price = DG_NATIONALCURRENCYPRICE
					from tbl_dogovor
					where DG_CODE = @dogovor_code

					if (@price - @old_price) > 0 and @current_national_price is not null
					begin
						set @final_price = @current_national_price + (@price - @old_price) * @new_currency_rate
						set @str = cast(@current_national_price as varchar) + ' + (' + cast(@price as varchar) + ' - ' + cast(@old_price as varchar) + ') * ' + cast(@new_currency_rate as varchar)
					end
					else if (@price - @old_price) < 0
					begin
						set @final_price = @price * @last_rate
						set @str = cast(@price as varchar) + ' * ' + cast(@last_rate as varchar)
					end

					if @action = 'INSERT_TO_HISTORY'
					begin
						insert into dbo.history
						(HI_DGCOD, HI_WHO, HI_TEXT, HI_REMARK, HI_MOD, HI_TYPE, HI_OAId)
						values
						(@dogovor_code, @who, @str, @currency, 'INS', 'CALC_FINAL_PRICE', 22)
					end
				end
			end

			drop table #tmp
		end
	end
end

go

grant exec on dbo.CalcPriceByNationalCurrencyRate to public

go

/*********************************************************************/
/* end sp_CalcPriceByNationalCurrencyRate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetCalendarTourDates.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetCalendarTourDates]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[GetCalendarTourDates]
END
GO

--<VERSION>9.2.18</VERSION>
--<DATE>2013-01-13</DATE>
CREATE PROCEDURE [dbo].[GetCalendarTourDates]
	@departFromKeys VARCHAR(200),
	@countryKeys VARCHAR(200),
	@tourKeys VARCHAR(200) = null,
	@resortKeys VARCHAR(200) = null,
	@tourTypeKeys VARCHAR(200) = null,
	@cityKeys VARCHAR(200) = null
AS
BEGIN
	SET DATEFIRST 1
	
	DECLARE @mwSearchType INT
	SELECT @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) FROM dbo.systemsettings 
	WHERE SS_ParmName = 'MWDivideByCountry'
	
	DECLARE @tableName NVARCHAR(100)
	IF (@mwSearchType = 0)
		SET @tableName = 'dbo.mwPriceDataTable'
	ELSE
		SET @tableName = dbo.mwGetPriceTableName(@countryKeys, @departFromKeys)
		
	DECLARE @sql NVARCHAR(4000)
	SET @sql = 'SELECT DISTINCT DATEDIFF(ss, ''1970-01-01'', TP_TurDates.TD_Date) AS [key],
					CONVERT(varchar, TP_TurDates.TD_Date, 4) AS name,
					TP_TurDates.TD_Date
				FROM TP_TurDates 
					INNER JOIN mwSpoData with(nolock) ON TP_TurDates.TD_TOKey = mwSpoData.sd_tourKey
					LEFT JOIN
					(
						SELECT distinct TD_Date
						FROM TP_TurDates
							INNER JOIN QuotaDetails ON QD_Date = TD_Date
							INNER JOIN Quotas ON QD_QTID = QT_ID
							INNER JOIN QuotaObjects ON QT_ID = QO_QTID AND QO_SVKey = 1
							INNER JOIN Charter ON QO_Code = CH_KEY
							LEFT JOIN StopSales as s1 ON s1.SS_QDID = QD_ID
							LEFT JOIN StopSales as s2 ON s2.SS_QOID = QO_ID
						WHERE
							(((QD_Places - QD_Busy) <= 0 AND QO_CNKey IN (' + @countryKeys + ') AND CH_CITYKEYFROM IN (' + @departFromKeys + '))
							OR (s1.SS_ID IS NOT NULL AND ISNULL(s1.SS_IsDeleted, 0) <> 1)
							OR (s2.SS_ID IS NOT NULL AND ISNULL(s2.SS_IsDeleted, 0) <> 1))
							AND  TD_Date NOT IN
								(SELECT distinct QD_Date
								FROM QuotaDetails
									INNER JOIN Quotas ON QD_QTID = QT_ID
									INNER JOIN QuotaObjects ON QT_ID = QO_QTID AND QO_SVKey = 1
									INNER JOIN Charter ON QO_Code = CH_Key
									LEFT JOIN StopSales as s1 ON s1.SS_QDID = QD_ID
									LEFT JOIN StopSales as s2 ON s2.SS_QOID = QO_ID
								WHERE (QD_Places - QD_Busy) > 0
									AND (s1.SS_ID IS NULL OR ISNULL(s1.SS_IsDeleted, 0) = 1)
									AND (s2.SS_ID IS NULL OR ISNULL(s2.SS_IsDeleted, 0) = 1))
					) AS t ON t.TD_Date = TP_TurDates.TD_Date
				WHERE TP_TurDates.TD_Date > DATEADD(day, - 1, GETDATE())
					AND mwSpoData.sd_ctkeyfrom IN (' + @departFromKeys + ')
					AND mwSpoData.sd_cnkey IN (' + @countryKeys + ')
					AND t.TD_Date IS NULL'
             
	IF @tourKeys IS NOT NULL
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourKeys IN (' + @tourKeys + ') AND exists(SELECT TOP 1 1 FROM ' + @tableName + ' WHERE pt_tourKeys IN (' + @tourKeys + ') AND pt_tourdate = TP_TurDates.TD_Date) '
	END

	IF @resortKeys IS NOT NULL
	BEGIN
		SET @sql += ' AND mwSpoData.sd_rskey IN (' + @resortKeys + ')'
	END

	if @tourTypeKeys IS NOT NULL
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourtype IN (' + @tourTypeKeys + ')'
	END

	if @cityKeys IS NOT NULL
	BEGIN
		SET @sql += ' AND mwSpoData.sd_ctkey IN (' + @cityKeys + ')'
	END
    
    SET @sql += ' ORDER BY TP_TurDates.TD_Date '
    
    EXEC sp_executesql @sql
END

GO

grant exec on [dbo].[GetCalendarTourDates] to public
GO
/*********************************************************************/
/* end sp_GetCalendarTourDates.sql */
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
--<VERSION>9.2.20.4</VERSION>
--<DATE>2013-12-10</DATE>
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
	set @maxKeyFromTable = isnull((Select id from @keyTable (updlock)), 1)
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
/* begin sp_GetPartnerCommission.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='GetPartnerCommission')
	drop proc dbo.GetPartnerCommission
go

CREATE PROCEDURE [dbo].[GetPartnerCommission] 
     @nTLKey int,
     @nPRKey int,
     @nBTKey int,
     @nDSKey int output,
     @nValue money output,
     @nIsPercent int output, 
	 @dCheckinDate datetime,
	 @nCNKey int=0,
	 @DGCreateDate datetime = null,
	 @nDepartureCity int = 0,
	 @sDiscountCode varchar(5) = null,
	 @sDiscountNumber varchar(10) = null,
	 @price decimal(16,6) = null,
	 @rate varchar(3) = null,
	 @dogovorCode varchar(10) = null
AS
    --<VERSION>2009.2.20</VERSION>
    --<DATE>2014-01-23</DATE>
	declare @discountSettingValue varchar(256)
	select @discountSettingValue = ISNULL(SS_ParmValue, '0') from dbo.SystemSettings where SS_ParmName like 'SYSUseDiscountCards'
	if @discountSettingValue = '1' and ISNULL(@sDiscountCode, '') != '' and ISNULL(@sDiscountNumber, '') != ''
	begin
		
		declare @discountCode varchar(5)
		declare @discountNumber varchar(10)
		declare @reservationsCount int, @cardKey int
		declare @reservationsPrice decimal(16,6)
		declare @nationalRate varchar(3)
		declare @discount money
		declare @discountId int

		if (ISNULL(@dogovorCode, '') = '')
		begin
			set @sDiscountCode = rtrim(ltrim(@sDiscountCode))
			set @sDiscountNumber = rtrim(ltrim(@sDiscountNumber))
				
			select @cardKey = CD_Key from Cards where ISNULL(CD_Code, '') = ISNULL(@sDiscountCode, '') and ISNULL(CD_Number, '') = ISNULL(@sDiscountNumber, '')
			select @reservationsCount = count(RR_ID) from ReservationsRegister where RR_CardKey = @cardKey
			select @reservationsPrice = sum(DG_NationalCurrencyPrice) from Dogovor where DG_CODE in (select RR_DGCODE  COLLATE Cyrillic_General_CI_AS from ReservationsRegister where RR_CardKey = @cardKey)
			select @nationalRate = RA_Code from dbo.Rates where RA_National = 1
			exec ExchangeCost @price output, @rate, @nationalRate, @dCheckinDate

			set @reservationsPrice = ISNULL(@reservationsPrice, 0)
		
			select top 1 @discount = cast(ISNULL(DS_DISCOUNT, 0) as money), @discountId = DS_ID  
				from dbo.DiscountScheme, dbo.TurList, dbo.TurService where 
				TL_Key = @nTLKey and 
				TS_TRKey = TL_Key and
				DS_Series like @sDiscountCode and
				((DS_CityFromKey is not null and DS_CityFromKey = TL_CTDepartureKey) or (DS_CityFromKey is null)) and
				((DS_CountryKey is not null and DS_CountryKey = TL_CNKey) or (DS_CountryKey is null)) and
				((DS_CityKey is not null and DS_CityKey = TS_CTKey) or (DS_CityKey is null)) and
				((DS_TourTypeKey is not null and DS_TourTypeKey = TL_TIP) or (DS_TourTypeKey is null) or DS_TourTypeKey = -1) and
				((DS_ReservationsFrom is not null and DS_ReservationsFrom <= (@reservationsCount + 1)) or (DS_ReservationsFrom is null)) and
				((DS_ReservationsTo is not null and DS_ReservationsTo >= (@reservationsCount + 1)) or (DS_ReservationsTo is null)) and
				((DS_TotalCostFrom is not null and DS_TotalCostFrom <= (@reservationsPrice + @price)) or (DS_TotalCostFrom is null)) and
				((DS_TotalCostTo is not null and DS_TotalCostTo >= (@reservationsPrice + @price)) or (DS_TotalCostTo is null)) and
				((DS_MinPrice is not null and DS_MinPrice <= @price) or (DS_MinPrice is null))
			order by DS_ID DESC

			set @nDSKey = -1
			set @nValue = @discount
			set @nIsPercent = 1
			return 1
		end
		else
		begin
			
			select @discount = DD_DiscountPercent from dbo.DogovorDetails where DD_DGCODE like @dogovorCode
			set @discount = ISNULL(@discount, 0)
			set @nDSKey = -1
			set @nValue = @discount
			set @nIsPercent = 1
			return 1
		end
		
	end

     if @nPRKey = 0
     begin
          set @nDSKey = -1     
          set @nValue = 0     
          set @nIsPercent = 1     
		  return 0
     end

	declare @nPGKey int, @nTpKey int, @nAttr int, @nCTDepartureKey int
	set @nTpKey=0
	if 	@nPRKey>0
		select @nPGKey = PR_PGKey from Partners where PR_Key = @nPRKey
	else
		set @nPGKey=0
	if @nTLKey>0
		select @nCNKey = TL_CNKey, @nTpKey=TL_TIP, @nAttr = isnull(TL_Attribute, 0) 
		from TurList where TL_Key = @nTLKey

	declare @discountAction int
	set @discountAction = 0
	if @nAttr & 16 > 0
		set @discountAction = 1

	if @dCheckinDate is null
		SET @dCheckinDate=ISNULL(@dCheckinDate,GetDate())
     if @nBTKey = 0 or @nBTKey is null
     begin
          select top 1 @nDSKey = DS_Key, @nValue = DS_Value, @nIsPercent = DS_IsPercent from Discounts
          where DS_PRKey IN(0, @nPRKey) AND DS_BTKey IN (0, @nBTKey) AND DS_PGKey IN (0, @nPGKey) 
				AND DS_TLKey IN (0, @nTLKey) AND DS_CNKey IN (0, @nCNKey) AND DS_TPKEY IN (-1,@nTpKey)
				AND @dCheckinDate between ISNULL(DS_CheckInFrom,'30-DEC-1899') and ISNULL(DS_CheckInTo,'30-DEC-2200')
				AND DATEDIFF(d, GetDate(), @dCheckinDate) <= ISNULL(DS_DaysBeforeCheckIn, 99999)
				AND ISNULL(@DGCreateDate, ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899')) between ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899') and dateadd(second,-1,dateadd(day,1,CONVERT(char(10), ISNULL(DS_DogovorCreateDateTo,'30-DEC-2200'),126)))
				AND (CASE WHEN @discountAction = 0 THEN ISNULL(DS_DAKey, 0) ELSE 0 END) = 0
				AND DS_DepartureCityKey IN (0, @nDepartureCity)
          order by DS_Priority, DS_BTKey, DS_TLKey desc, DS_CNKey desc,DS_TPKEY desc, DS_PRKey desc, DS_PGKey desc, DS_DepartureCityKey desc
          , (case when @dCheckinDate = '1899-12-30' then GETDATE() else @dCheckinDate end) - ISNULL(DS_DaysBeforeCheckIn, 77777) asc
          , DS_DogovorCreateDateFrom asc, DS_DogovorCreateDateTo asc, DS_DAKey asc
     end
     else
     begin
          set @nBTKey = 1
          select top 1 @nDSKey = DS_Key, @nValue = DS_Value, @nIsPercent = DS_IsPercent from Discounts
          where DS_PRKey IN(0, @nPRKey) AND DS_BTKey IN (0, @nBTKey) AND DS_PGKey IN (0, @nPGKey) 
				AND DS_TLKey IN (0, @nTLKey) AND DS_CNKey IN (0, @nCNKey) AND DS_TPKEY IN (-1,@nTpKey)
				AND @dCheckinDate between ISNULL(DS_CheckInFrom,'30-DEC-1899') and ISNULL(DS_CheckInTo,'30-DEC-2200')
				AND DATEDIFF(d, GetDate(), @dCheckinDate) <= ISNULL(DS_DaysBeforeCheckIn, 99999)
				AND ISNULL(@DGCreateDate, ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899')) between ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899') and dateadd(second,-1,dateadd(day,1,CONVERT(char(10), ISNULL(DS_DogovorCreateDateTo,'30-DEC-2200'),126)))
				AND (CASE WHEN @discountAction = 0 THEN ISNULL(DS_DAKey, 0) ELSE 0 END) = 0
				AND DS_DepartureCityKey IN (0, @nDepartureCity)
          order by DS_Priority, DS_BTKey desc, DS_TLKey desc, DS_CNKey desc, DS_TPKEY desc,DS_PRKey desc, DS_PGKey desc, DS_DepartureCityKey desc
          , (case when @dCheckinDate = '1899-12-30' then GETDATE() else @dCheckinDate end) - ISNULL(DS_DaysBeforeCheckIn, 77777) asc
          , DS_DogovorCreateDateFrom asc, DS_DogovorCreateDateTo asc, DS_DAKey asc
     end

     if @nDSKey is null
     begin
          set @nDSKey = -1     
          set @nValue = 0     
          set @nIsPercent = 1     
     end

GO

grant execute on [dbo].[GetPartnerCommission] to public

GO

/*********************************************************************/
/* end sp_GetPartnerCommission.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_LoadMisQuotas.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'[dbo].[LoadMisQuotas]') AND TYPE IN (N'P', N'PC'))
    DROP PROCEDURE [dbo].[LoadMisQuotas]
GO

CREATE PROCEDURE [dbo].[LoadMisQuotas]
(
    @hotelKey INT = NULL,           -- ключ отеля
    @startDate DATETIME = NULL,     -- дата начала интервала, по которому изменялись квоты (для стопов передается null)
    @endDate DATETIME = NULL,       -- дата окончания интервала, по которому изменялись квоты (для стопов передается null)
    @quotesUpdate BIT = NULL        -- признак того, что обновлять надо квоты (т.е. 1 - обновление квот, 0 - обновление стопов)
)
AS
BEGIN
    IF (dbo.mwReplIsSubscriber() = 1)
        RETURN;

    DECLARE @qtid INT, @qoid INT, @qpid INT, @qdid INT, @stid INT, @qdbusy INT, @uskey INT, @str NVARCHAR(MAX), @str1 NVARCHAR(MAX), @str3 NVARCHAR(MAX), @hdname VARCHAR(100),
            @partnerName VARCHAR(100), @rcname VARCHAR(100), @ss_allotmentAndCommitment INT, @email VARCHAR(1000), @bkid INT, @isErrorState BIT

    IF (@startDate IS NULL)
        SET @startDate = '1900-01-01'
    IF (@endDate IS NULL)
        SET @endDate = '2099-12-01'

    SET @str = 'Количество квот, полученное из MIS_Quotas меньше, чем число занятых мест. Параметры квот:'
    SET @str1 = 'Из MIS_Quotas пришло отрицательное количество мест. Параметры квот:'
    SET @str3 = 'Запрет на заезд не был проставлен, в связи с тем, что не существует квоты в Мастер-Туре. Параметры квот:'

    SET @isErrorState = 0
    SET @uskey = 0
    SELECT @uskey = ISNULL(US_Key,0) FROM dbo.UserList WHERE US_USERID = SYSTEM_USER

    DECLARE @mq_Id  INT, @mq_PartnerKey INT, @mq_HotelKey   INT, @mq_RoomCategoryKey INT, @mq_RoomKey INT, @mq_Date DATETIME,
    @mq_State SMALLINT, @mq_CommitmentTotal INT, @mq_AllotmentTotal INT, @mq_Release INT, @mq_StopSale BIT, -- 0 - квоты, 1 - стопы
    @mq_CancelStopSale BIT, -- 1 - удаление стопов, 0 - добавление стопов
    @mq_IsByCheckin BIT,    -- признак "запрет заезда"
    @mq_ErrorState TINYINT  -- если равен 1, то заново письмо менеджерам не отправляем

    -- ключи квот, которые нужно удалить
    DECLARE @tmpDeleteQuotаs TABLE(tmpQoid INT, tmpQtid INT)

    IF (ISNULL(@quotesUpdate, 1) = 1)
    BEGIN
        DECLARE qCur CURSOR FOR
        SELECT  MQ_Id, Mq_PartnerKey, Mq_HotelKey, Mq_RoomCategoryKey, Mq_RoomKey, Mq_Date, MQ_CommitmenTotal, MQ_AllotmentTotal,
                Mq_Release, Mq_StopSale, Mq_CancelStopSale, MQ_ErrorState
                FROM MIS_Quotas WHERE ((@hotelKey IS NOT NULL AND MQ_HotelKey = @hotelKey) OR (@hotelKey IS NULL))
                                      AND MQ_StopSale = 0
                                      AND (MQ_IsByCheckin <> 1 OR MQ_IsByCheckin IS NULL)

        OPEN qCur
        FETCH NEXT FROM qCur
        INTO @mq_Id, @mq_PartnerKey, @mq_HotelKey, @mq_RoomCategoryKey, @mq_RoomKey, @mq_Date, @mq_CommitmentTotal, @mq_AllotmentTotal, @mq_Release, @mq_StopSale, @mq_CancelStopSale, @mq_ErrorState

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                IF (@mq_CommitmentTotal >= 0 OR (@mq_CommitmentTotal = 0 AND @mq_AllotmentTotal = 0))
                BEGIN
                    IF (@mq_CommitmentTotal > 0) AND (NOT EXISTS (SELECT TOP 1 1
                                                      FROM Quotas WITH(NOLOCK)
                                                      INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                                      WHERE QT_PRKey = @mq_PartnerKey
                                                          AND QO_SVKey = 3
                                                          AND QO_Code = @mq_HotelKey
                                                          AND QO_SubCode1 = @mq_RoomKey
                                                          AND QO_SubCode2 = @mq_RoomCategoryKey
                                                          AND QT_ByRoom = 1
                                                          AND QT_IsByCheckIn = 0))
                    BEGIN
                        INSERT INTO Quotas (QT_PRKey, QT_ByRoom, QT_Comment, QT_IsByCheckIn)
                        VALUES (@mq_PartnerKey, 1, '', 0)
                        SET @qtid = SCOPE_IDENTITY()

                        INSERT INTO QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
                        VALUES (@qtid, 3, @mq_HotelKey, @mq_RoomKey, @mq_RoomCategoryKey)
                        SET @qoid = SCOPE_IDENTITY()

                        INSERT INTO QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Release, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
                        VALUES (@qtid, @mq_Date, 2, NULLIF(@mq_Release, 0), @mq_CommitmentTotal, 0, GETDATE(), ISNULL(@uskey,0))
                        SET @qdid = SCOPE_IDENTITY()

                        UPDATE MIS_Quotas
                        SET Commitment_MT_Key = @qdid
                        WHERE MQ_Id = @mq_Id

                        INSERT INTO QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
                        VALUES (@qdid, @mq_Date, @mq_CommitmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0)

                        UPDATE QuotaObjects
                        SET QO_CTKey = (SELECT HD_CTKey FROM HotelDictionary WITH(NOLOCK) WHERE HD_Key = QO_Code)
                        WHERE QO_SVKey = 3 AND QO_ID = @qoid AND QO_CTKey IS NULL

                        UPDATE QuotaObjects
                        SET QO_CNKey = (SELECT CT_CNKey FROM CityDictionary WITH(NOLOCK) WHERE CT_Key = QO_CTKey)
                        WHERE QO_CNKey IS NULL AND QO_CTKey IS NOT NULL AND QO_ID = @qoid

                        UPDATE MIS_Quotas SET MQ_ErrorState = NULL WHERE MQ_Id = @mq_Id
                    END
                    ELSE
                    BEGIN
                        IF EXISTS (SELECT TOP 1 1
                                FROM Quotas WITH(NOLOCK)
                                INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                WHERE QT_PRKey = @mq_PartnerKey
                                    AND QO_SVKey = 3
                                    AND QO_Code = @mq_HotelKey
                                    AND QO_SubCode1 = @mq_RoomKey
                                    AND QO_SubCode2 = @mq_RoomCategoryKey
                                    AND QD_Date = @mq_Date
                                    AND QT_ByRoom = 1
                                    AND QD_Type = 2
                                    AND QT_IsByCheckIn = 0)
                        BEGIN
                            SELECT @qdid = QD_ID, @qdbusy = QD_Busy
                                FROM Quotas WITH(NOLOCK)
                                INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                WHERE QT_PRKey = @mq_PartnerKey
                                    AND QO_SVKey = 3
                                    AND QO_Code = @mq_HotelKey
                                    AND QO_SubCode1 = @mq_RoomKey
                                    AND QO_SubCode2 = @mq_RoomCategoryKey
                                    AND QD_Date = @mq_Date
                                    AND QT_ByRoom = 1
                                    AND QD_Type = 2
                                    AND QT_IsByCheckIn = 0

                            IF (@qdbusy > @mq_CommitmentTotal)
                            BEGIN
                                -- если число занятых мест в МТ больше числа мест пришедших из Протура, то в Places = Busy
                                UPDATE QuotaDetails SET QD_Places = @mq_CommitmentTotal, QD_Release = NULLIF(@mq_Release, 0), QD_IsDeleted = NULL WHERE QD_ID = @qdid
                                UPDATE QuotaParts SET QP_Places = @mq_CommitmentTotal, QP_IsDeleted = NULL WHERE QP_QDID = @qdid

                                -- чтобы несколько раз письмо не отправлять
                                IF (@mq_ErrorState IS NULL)
                                BEGIN
                                    -- отправляем письмо
                                    SELECT @hdname = ISNULL(HD_Name,0) FROM HotelDictionary WITH(NOLOCK) WHERE HD_Key = @mq_HotelKey
                                    SELECT @rcname = ISNULL(RC_Name,0) FROM RoomsCategory WITH(NOLOCK) WHERE RC_key = @mq_RoomCategoryKey
                                    SELECT @partnerName = ISNULL(PR_FullName,0) FROM Partners WITH(NOLOCK) WHERE PR_Key = @mq_PartnerKey
                                    SET @str = @str + CHAR(13) + CHAR(13) + 'Партнер:' + CONVERT(VARCHAR(100),@partnerName) + '(' + CONVERT(VARCHAR(100),@mq_PartnerKey) + ')' + CHAR(13) +
                                                                'Отель:' + CONVERT(VARCHAR(100),@hdname) + '(' + CONVERT(VARCHAR(100),@mq_HotelKey) + ')' + CHAR(13) +
                                                                'Категория номера:' + CONVERT(VARCHAR(100),@rcname) + CHAR(13) +
                                                                'Дата:' + CONVERT(VARCHAR(100),@mq_Date, 105) + CHAR(13) +
                                                                'Количество мест:' + CONVERT(VARCHAR(100),@mq_CommitmentTotal) + CHAR(13)
                                    PRINT @str
                                END

                                SET @isErrorState = 1
                            END
                            ELSE
                            BEGIN
                                -- если из Протура приходит 0 и в МТ кол-во занятых мест равно 0, то удаляем квоту, вне зависимости от значения кол-ва мест в МТ
                                IF (@mq_CommitmentTotal = 0 AND @qdbusy = 0)
                                BEGIN
                                    UPDATE QuotaDetails
                                    SET QD_IsDeleted = 4 -- Request
                                    WHERE QD_ID = @qdid

                                    UPDATE MIS_Quotas
                                    SET Commitment_MT_Key = @qdid
                                    WHERE MQ_Id = @mq_Id

                                    UPDATE MIS_Quotas SET MQ_ErrorState = NULL WHERE MQ_Id = @mq_Id
                                END
                                ELSE
                                BEGIN
                                    UPDATE QuotaDetails SET QD_Places = @mq_CommitmentTotal, QD_Release = NULLIF(@mq_Release, 0), QD_IsDeleted = NULL WHERE QD_ID = @qdid
                                    UPDATE QuotaParts SET QP_Places = @mq_CommitmentTotal, QP_IsDeleted = NULL WHERE QP_QDID = @qdid

                                    UPDATE MIS_Quotas
                                    SET Commitment_MT_Key = @qdid
                                    WHERE MQ_Id = @mq_Id

                                    UPDATE MIS_Quotas SET MQ_ErrorState = NULL WHERE MQ_Id = @mq_Id
                                END
                            END
                        END
                        ELSE
                        BEGIN
                            IF (@mq_CommitmentTotal > 0)
                            BEGIN
                            SELECT TOP 1 @qtid = QT_ID, @qoid = QO_ID
                                FROM Quotas WITH(NOLOCK)
                                INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                WHERE QT_PRKey = @mq_PartnerKey
                                    AND QO_SVKey = 3
                                    AND QO_Code = @mq_HotelKey
                                    AND QO_SubCode1 = @mq_RoomKey
                                    AND QO_SubCode2 = @mq_RoomCategoryKey
                                    AND QT_ByRoom = 1
                                    AND QT_IsByCheckIn = 0
                                ORDER BY QT_ID

                                INSERT INTO QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Release, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
                                VALUES (@qtid, @mq_Date, 2, NULLIF(@mq_Release, 0), @mq_CommitmentTotal, 0, GETDATE(), ISNULL(@uskey,0))
                                SET @qdid = SCOPE_IDENTITY()

                                UPDATE MIS_Quotas
                                SET Commitment_MT_Key = @qdid
                                WHERE MQ_Id = @mq_Id

                                INSERT INTO QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
                                VALUES (@qdid, @mq_Date, @mq_CommitmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0)

                                UPDATE MIS_Quotas SET MQ_ErrorState = NULL WHERE MQ_Id = @mq_Id
                            END
                        END
                    END
                END
            END TRY
            BEGIN CATCH
                DECLARE @errorMessage2 AS NVARCHAR(MAX)
                SET @errorMessage2 = 'Error in LoadMisQuotas commitment: ' + ERROR_MESSAGE() + CONVERT(NVARCHAR(MAX), @mq_Id)

                INSERT INTO SystemLog (sl_date, sl_message) VALUES (GETDATE(), @errorMessage2)
            END CATCH

            BEGIN TRY
                IF (@mq_AllotmentTotal >= 0 OR (@mq_CommitmentTotal = 0 AND @mq_AllotmentTotal = 0))
                    BEGIN
                        IF NOT EXISTS (SELECT TOP 1 1
                                    FROM Quotas WITH(NOLOCK)
                                    INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                    WHERE QT_PRKey = @mq_PartnerKey
                                        AND QO_SVKey = 3
                                        AND QO_Code = @mq_HotelKey
                                        AND QO_SubCode1 = @mq_RoomKey
                                        AND QO_SubCode2 = @mq_RoomCategoryKey
                                        AND QT_ByRoom = 1
                                        AND QT_IsByCheckIn = 0)
                            AND (@mq_AllotmentTotal > 0)
                        BEGIN
                            INSERT INTO Quotas (QT_PRKey, QT_ByRoom, QT_Comment, QT_IsByCheckIn)
                            VALUES (@mq_PartnerKey, 1, '', 0)
                            SET @qtid = SCOPE_IDENTITY()

                            INSERT INTO QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
                            VALUES (@qtid, 3, @mq_HotelKey, @mq_RoomKey, @mq_RoomCategoryKey)
                            SET @qoid = SCOPE_IDENTITY()

                            INSERT INTO QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Release, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
                            VALUES (@qtid, @mq_Date, 1, NULLIF(@mq_Release, 0), @mq_AllotmentTotal, 0, GETDATE(), ISNULL(@uskey,0))
                            SET @qdid = SCOPE_IDENTITY()

                            UPDATE MIS_Quotas
                            SET Allotment_MT_Key = @qdid
                            WHERE MQ_Id = @mq_Id

                            INSERT INTO QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
                            VALUES (@qdid, @mq_Date, @mq_AllotmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0)

                            UPDATE QuotaObjects
                            SET QO_CTKey = (SELECT HD_CTKey FROM HotelDictionary WITH(NOLOCK) WHERE HD_Key = QO_Code)
                            WHERE QO_SVKey = 3 AND QO_ID = @qoid AND QO_CTKey IS NULL

                            UPDATE QuotaObjects
                            SET QO_CNKey= (SELECT CT_CNKey FROM CityDictionary WITH(NOLOCK) WHERE CT_Key=QO_CTKey)
                            WHERE QO_CNKey IS NULL AND QO_CTKey IS NOT NULL AND QO_ID = @qoid

                            UPDATE MIS_Quotas SET MQ_ErrorState = NULL WHERE MQ_Id = @mq_Id
                        END
                        ELSE
                        BEGIN
                            IF EXISTS (SELECT TOP 1 1
                                    FROM Quotas WITH(NOLOCK)
                                    INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                    INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                    WHERE QT_PRKey = @mq_PartnerKey
                                        AND QO_SVKey = 3
                                        AND QO_Code = @mq_HotelKey
                                        AND QO_SubCode1 = @mq_RoomKey
                                        AND QO_SubCode2 = @mq_RoomCategoryKey
                                        AND QD_Date = @mq_Date
                                        AND QT_ByRoom = 1
                                        AND QD_Type = 1
                                        AND QT_IsByCheckIn = 0)
                            BEGIN
                                SELECT @qdid = QD_ID, @qdbusy = QD_Busy
                                    FROM Quotas WITH(NOLOCK)
                                    INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                    INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                    WHERE QT_PRKey = @mq_PartnerKey
                                        AND QO_SVKey = 3
                                        AND QO_Code = @mq_HotelKey
                                        AND QO_SubCode1 = @mq_RoomKey
                                        AND QO_SubCode2 = @mq_RoomCategoryKey
                                        AND QD_Date = @mq_Date
                                        AND QT_ByRoom = 1
                                        AND QD_Type = 1
                                        AND QT_IsByCheckIn = 0

                                IF (@qdbusy > @mq_AllotmentTotal)
                                BEGIN
                                    -- если число занятых мест в МТ больше числа мест пришедших из Протура, то в Places = Busy
                                    UPDATE QuotaDetails SET QD_Places = @mq_AllotmentTotal, QD_Release = NULLIF(@mq_Release, 0), QD_IsDeleted = NULL WHERE QD_ID = @qdid
                                    UPDATE QuotaParts SET QP_Places = @mq_AllotmentTotal, QP_IsDeleted = NULL WHERE QP_QDID = @qdid

                                    -- чтобы несколько раз письмо не отправлять
                                    IF (@mq_ErrorState IS NULL)
                                    BEGIN
                                        -- отправляем письмо
                                        SELECT @hdname = ISNULL(HD_Name,0) FROM HotelDictionary WITH(NOLOCK) WHERE HD_Key = @mq_HotelKey
                                        SELECT @rcname = ISNULL(RC_Name,0) FROM RoomsCategory WITH(NOLOCK) WHERE RC_key = @mq_RoomCategoryKey
                                        SELECT @partnerName = ISNULL(PR_FullName,0) FROM Partners WITH(NOLOCK) WHERE PR_Key = @mq_PartnerKey
                                        SET @str = @str + CHAR(13) + CHAR(13) + 'Партнер:' + CONVERT(VARCHAR(100),@partnerName) + '(' + CONVERT(VARCHAR(100),@mq_PartnerKey) + ')' + CHAR(13) +
                                                                    'Отель:' + CONVERT(VARCHAR(100),@hdname) + '(' + CONVERT(VARCHAR(100),@mq_HotelKey) + ')' + CHAR(13) +
                                                                    'Категория номера:' + CONVERT(VARCHAR(100),@rcname) + CHAR(13) +
                                                                    'Дата:' + CONVERT(VARCHAR(100),@mq_Date, 105) + CHAR(13) +
                                                                    'Количество мест:' + CONVERT(VARCHAR(100),@mq_AllotmentTotal) + CHAR(13)
                                    END

                                    SET @isErrorState = 1
                                END
                                ELSE
                                BEGIN
                                    -- если из Протура приходит 0 и в МТ кол-во занятых мест равно 0, то удаляем квоту, вне зависимости от значения кол-ва мест в МТ
                                    IF (@mq_AllotmentTotal = 0 AND @qdbusy = 0)
                                    BEGIN
                                        UPDATE QuotaDetails
                                        SET QD_IsDeleted = 4 -- Request
                                        WHERE QD_ID = @qdid

                                        UPDATE MIS_Quotas
                                        SET Allotment_MT_Key = @qdid
                                        WHERE MQ_Id = @mq_Id

                                        UPDATE MIS_Quotas SET MQ_ErrorState = NULL WHERE MQ_Id = @mq_Id
                                    END
                                    ELSE
                                    BEGIN
                                        UPDATE QuotaDetails SET QD_Places = @mq_AllotmentTotal, QD_Release = NULLIF(@mq_Release, 0), QD_IsDeleted = NULL WHERE QD_ID = @qdid
                                        UPDATE QuotaParts SET QP_Places = @mq_AllotmentTotal, QP_IsDeleted = NULL WHERE QP_QDID = @qdid

                                        UPDATE MIS_Quotas
                                        SET Allotment_MT_Key = @qdid
                                        WHERE MQ_Id = @mq_Id

                                        UPDATE MIS_Quotas SET MQ_ErrorState = NULL WHERE MQ_Id = @mq_Id
                                    END
                                END
                            END
                            ELSE
                            BEGIN
                                IF (@mq_AllotmentTotal > 0)
                                BEGIN
                                SELECT TOP 1 @qtid = QT_ID, @qoid = QO_ID
                                    FROM Quotas WITH(NOLOCK)
                                    INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                    WHERE QT_PRKey = @mq_PartnerKey
                                        AND QO_SVKey = 3
                                        AND QO_Code = @mq_HotelKey
                                        AND QO_SubCode1 = @mq_RoomKey
                                        AND QO_SubCode2 = @mq_RoomCategoryKey
                                        AND QT_ByRoom = 1
                                        AND QT_IsByCheckIn = 0
                                    ORDER BY QT_ID

                                    INSERT INTO QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Release, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
                                    VALUES (@qtid, @mq_Date, 1, NULLIF(@mq_Release, 0), @mq_AllotmentTotal, 0, GETDATE(), ISNULL(@uskey,0))
                                    SET @qdid = SCOPE_IDENTITY()

                                    UPDATE MIS_Quotas
                                    SET Allotment_MT_Key = @qdid
                                    WHERE MQ_Id = @mq_Id

                                    INSERT INTO QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
                                    VALUES (@qdid, @mq_Date, @mq_AllotmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0)

                                    UPDATE MIS_Quotas SET MQ_ErrorState = NULL WHERE MQ_Id = @mq_Id
                                END
                            END
                        END
                    END

            END TRY
            BEGIN CATCH
                DECLARE @errorMessage3 AS NVARCHAR(MAX)
                SET @errorMessage3 = 'Error in LoadMisQuotas allotment: ' + ERROR_MESSAGE() + CONVERT(NVARCHAR(MAX), @mq_Id)

                INSERT INTO SystemLog (sl_date, sl_message)
                VALUES (GETDATE(), @errorMessage3)
            END CATCH

            IF (@mq_CommitmentTotal < 0 AND @mq_AllotmentTotal < 0)
            BEGIN
                -- отправляем письмо
                SELECT @hdname = ISNULL(HD_Name,0) FROM HotelDictionary WITH(NOLOCK) WHERE HD_Key = @mq_HotelKey
                SELECT @rcname = ISNULL(RC_Name,0) FROM RoomsCategory WITH(NOLOCK) WHERE RC_key = @mq_RoomCategoryKey
                SELECT @partnerName = ISNULL(PR_FullName,0) FROM Partners WITH(NOLOCK) WHERE PR_Key = @mq_PartnerKey
                SET @str1 = @str1 + CHAR(13) + CHAR(13) + 'Партнер:' + CONVERT(VARCHAR(100),@partnerName) + '(' + CONVERT(VARCHAR(100),@mq_PartnerKey) + ')' + CHAR(13) +
                                                        'Отель:' + CONVERT(VARCHAR(100),@hdname) + '(' + CONVERT(VARCHAR(100),@mq_HotelKey) + ')' + CHAR(13) +
                                                        'Категория номера:' + CONVERT(VARCHAR(100),@rcname) + CHAR(13) +
                                                        'Дата:' + CONVERT(VARCHAR(100),@mq_Date, 105) + CHAR(13) +
                                                        'Количество мест:' + CONVERT(VARCHAR(100),@mq_AllotmentTotal) + CHAR(13)
                PRINT @str1
            END

            -- рассадка в квоты по раннее оформленным услугам, т.е. cажаем в квоты услуги, которые сидят на запросе
            IF EXISTS (SELECT TOP 1 1
                        FROM Dogovorlist WITH(NOLOCK)
                        JOIN HotelRooms WITH(NOLOCK) ON DL_SUBCODE1 = HR_KEY
                        WHERE dl_svkey = 3
                            AND dl_code = @mq_HotelKey
                            AND ((@mq_RoomCategoryKey = 0) OR (HR_RCKEY = @mq_RoomCategoryKey))
                            AND (SELECT COALESCE(MIN(SD_State), 4) FROM ServiceByDate WHERE SD_DLKey = DL_Key) = 4
                            AND @mq_Date BETWEEN DL_DateBeg AND DL_DATEEND)
            BEGIN
                EXEC ProtourSetServiceToQuota @mq_HotelKey, @mq_RoomCategoryKey, @mq_Date
            END

            IF (@isErrorState = 0 AND @mq_CommitmentTotal <= 0 AND @mq_AllotmentTotal <= 0)
            BEGIN
                UPDATE MIS_Quotas SET MQ_ErrorState = NULL WHERE MQ_Id = @mq_Id
            END

            SET @isErrorState = 0

            FETCH NEXT FROM qCur INTO @mq_Id, @mq_PartnerKey, @mq_HotelKey, @mq_RoomCategoryKey, @mq_RoomKey, @mq_Date,
                            @mq_CommitmentTotal, @mq_AllotmentTotal, @mq_Release, @mq_StopSale, @mq_CancelStopSale, @mq_ErrorState
        END
        CLOSE qCur
        DEALLOCATE qCur

        -- удаление квот
        EXEC QuotaDetailAfterDelete

        DELETE QuotaObjects WHERE QO_ID IN (SELECT tmpQoid FROM @tmpDeleteQuotаs)
        DELETE Quotas WHERE QT_ID IN (SELECT tmpQtid FROM @tmpDeleteQuotаs)

        BEGIN TRY
            IF EXISTS (SELECT 1 FROM SystemSettings WITH(NOLOCK) WHERE SS_ParmName='SYSEmailProtourQuotes')
                SELECT @email = SS_ParmValue FROM SystemSettings WITH(NOLOCK) WHERE SS_ParmName='SYSEmailProtourQuotes'

            IF (@str <> 'Количество квот, полученное из ProTour меньше, чем число занятых мест. Параметры квот:')
            BEGIN
                -- отправка письма, если количество квот, полученное из ProTour меньше, чем число занятых мест
                INSERT INTO SendMail (SM_EMAIL, SM_Text, SM_Date, SM_DateGet, SM_Creator, SM_DgKey) VALUES (ISNULL(@email,''), @str, GETDATE(), '1900-01-01', ISNULL(@uskey,0), 0)
            END

            IF (@str1 <> 'Из ProTour пришло отрицательное количество мест. Параметры квот:')
            BEGIN
                -- отправка письма, если из ProTour пришло отрицательное количество мест
                INSERT INTO SendMail (SM_EMAIL, SM_Text, SM_Date, SM_DateGet, SM_Creator, SM_DgKey) VALUES (ISNULL(@email,''), @str1, GETDATE(), '1900-01-01', ISNULL(@uskey,0), 0)
            END
        END TRY
        BEGIN CATCH
            DECLARE @errorMessage4 AS NVARCHAR(MAX)
            SET @errorMessage4 = 'Error in LoadMisQuotas insert Blanks: ' + ERROR_MESSAGE()

            INSERT INTO SystemLog (sl_date, sl_message) VALUES (GETDATE(), @errorMessage4)
        END CATCH
    END

    --обрабатываем стопы
    IF (@quotesUpdate = 0 OR @quotesUpdate IS NULL)
    BEGIN
        DECLARE @tmpQuotаs TABLE(
        mqId INT,
        mqPartnerKey INT,
        mqHotelKey INT,
        mqRoomCategoryKey INT,
        mqRoomKey INT,
        mqDate DATETIME,
        mqCommitmentTotal INT,
        mqAllotmentTotal INT,
        mqRelease INT,
        mqStopSale BIT,
        mqCancelStopSale BIT
        )

        INSERT INTO @tmpQuotаs SELECT * FROM
        (SELECT MQ_Id, Mq_PartnerKey, Mq_HotelKey, Mq_RoomCategoryKey, Mq_RoomKey, Mq_Date, MQ_CommitmenTotal, MQ_AllotmentTotal, Mq_Release, Mq_StopSale, Mq_CancelStopSale
         FROM MIS_Quotas WHERE (MQ_HotelKey = @hotelKey OR @hotelKey IS NULL) AND MQ_StopSale=1 AND MQ_CancelStopSale = 0 AND MQ_Date < '2079-06-05'
                               AND (MQ_IsByCheckin <> 1 OR MQ_IsByCheckin IS NULL)
        ) AS innerQuotas

        DECLARE qCur CURSOR FOR

        SELECT  MQ_Id, Mq_PartnerKey, Mq_HotelKey, Mq_RoomCategoryKey, mq_RoomKey, Mq_Date, MQ_CommitmenTotal, MQ_AllotmentTotal, Mq_Release, Mq_StopSale, Mq_CancelStopSale, MQ_IsByCheckin
        FROM MIS_Quotas WHERE (MQ_HotelKey = @hotelKey OR @hotelKey IS NULL) AND MQ_StopSale=1 AND MQ_Date < '2079-06-05'

        OPEN qCur
        FETCH NEXT FROM qCur
		INTO @mq_Id, @mq_PartnerKey, @mq_HotelKey, @mq_RoomCategoryKey, @mq_RoomKey, @mq_Date, @mq_CommitmentTotal, @mq_AllotmentTotal, @mq_Release, @mq_StopSale, @mq_CancelStopSale, @mq_IsByCheckin

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                IF (@mq_CommitmentTotal = 1 AND @mq_AllotmentTotal = 1)
					SET @ss_allotmentAndCommitment = 1
                ELSE IF (@mq_AllotmentTotal = 1 AND @mq_CommitmentTotal = 0)
                    SET @ss_allotmentAndCommitment = 0
                ELSE
                    SET @ss_allotmentAndCommitment = 1

                IF (@mq_CancelStopSale = 0 AND (@mq_IsByCheckin <> 1 OR @mq_IsByCheckin IS NULL)) -- 0 - добавление стопов, 1 - удаление стопов
                BEGIN
                    IF EXISTS (SELECT TOP 1 1 FROM QuotaObjects WITH(NOLOCK)
					           WHERE QO_Code = @mq_HotelKey AND QO_SVKey = 3 AND QO_SubCode1 = @mq_RoomKey AND QO_SubCode2 = @mq_RoomCategoryKey AND QO_QTID IS NULL)
                    BEGIN
                        IF NOT EXISTS (SELECT TOP 1 1 FROM StopSales WITH(NOLOCK)
						               JOIN QuotaObjects WITH(NOLOCK) ON SS_QOID = QO_ID
									   WHERE SS_PRKey = @mq_PartnerKey
											AND QO_Code = @mq_HotelKey
											AND SS_Date = @mq_Date
											AND QO_SubCode1 = @mq_RoomKey
											AND QO_SubCode2 = @mq_RoomCategoryKey
											AND SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
											AND QO_QTID IS NULL
											AND QO_SVKey = 3)
                        BEGIN
                            SELECT @qoid = QO_ID FROM QuotaObjects WITH(NOLOCK)
							WHERE QO_Code = @mq_HotelKey AND QO_SVKey = 3 AND QO_SubCode1 = @mq_RoomKey AND QO_SubCode2 = @mq_RoomCategoryKey AND QO_QTID IS NULL

                            INSERT INTO StopSales(SS_QOID, SS_QDID, SS_PRKey, SS_Date, SS_AllotmentAndCommitment, SS_Comment, SS_CreateDate, SS_CreatorKey, SS_LastUpdate)
                            VALUES (@qoid, NULL, @mq_PartnerKey, @mq_Date, @ss_allotmentAndCommitment, '', GETDATE(), ISNULL(@uskey,0), GETDATE())

                            SET @stid = SCOPE_IDENTITY()

                            UPDATE MIS_Quotas
                            SET Allotment_MT_Key = @qoid
                            WHERE MQ_Id = @mq_Id
                        END
                        ELSE IF EXISTS (SELECT TOP 1 1 FROM StopSales WITH(NOLOCK)
						                JOIN QuotaObjects WITH(NOLOCK) ON SS_QOID = QO_ID
                                        WHERE SS_PRKey = @mq_PartnerKey
											AND QO_Code = @mq_HotelKey
											AND SS_Date = @mq_Date
											AND QO_SubCode1 = @mq_RoomKey
											AND QO_SubCode2 = @mq_RoomCategoryKey
											AND SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
											AND QO_QTID IS NULL
											AND QO_SVKey = 3
											AND SS_IsDeleted = 1)
                        BEGIN
                            UPDATE StopSales
                            SET SS_IsDeleted = 0
                            FROM StopSales WITH(NOLOCK)
							JOIN QuotaObjects WITH(NOLOCK) ON SS_QOID = QO_ID
                            WHERE SS_PRKey = @mq_PartnerKey
                                AND QO_Code = @mq_HotelKey
                                AND SS_Date = @mq_Date
                                AND QO_SubCode1 = @mq_RoomKey
                                AND QO_SubCode2 = @mq_RoomCategoryKey
                                AND SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
                                AND QO_QTID IS NULL
                                AND QO_SVKey = 3
                                AND SS_IsDeleted = 1
                        END
                        ELSE
                        BEGIN
                            IF NOT EXISTS (SELECT TOP 1 1 FROM StopSales WITH(NOLOCK) JOIN QuotaObjects WITH(NOLOCK) ON SS_QOID = QO_ID
                                WHERE SS_PRKey = @mq_PartnerKey
									AND QO_Code = @mq_HotelKey
									AND SS_Date = @mq_Date
									AND QO_SubCode1 = @mq_RoomKey
									AND QO_SubCode2 = @mq_RoomCategoryKey
									AND SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
									AND QO_QTID IS NULL
									AND QO_SVKey = 3)
                            BEGIN
                                DECLARE @errorMessage AS NVARCHAR(MAX)
                                SET @errorMessage = 'Error in LoadMisQuotas stop (not exists):  ' + CONVERT(NVARCHAR(MAX), @mq_Id)

                                INSERT INTO SystemLog (sl_date, sl_message) VALUES (GETDATE(), @errorMessage)
                            END
                        END
                    END
                    ELSE
                    BEGIN
                        INSERT INTO QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
                        VALUES (NULL, 3, @mq_HotelKey, @mq_RoomKey, @mq_RoomCategoryKey)

						SET @qoid = SCOPE_IDENTITY()

                        INSERT INTO StopSales(SS_QOID, SS_QDID, SS_PRKey, SS_Date, SS_AllotmentAndCommitment, SS_Comment, SS_CreateDate, SS_CreatorKey, SS_LastUpdate)
                        VALUES (@qoid, NULL, @mq_PartnerKey, @mq_Date, @ss_allotmentAndCommitment, '', GETDATE(), ISNULL(@uskey,0), GETDATE())

                        SET @stid = SCOPE_IDENTITY()

                        UPDATE MIS_Quotas
                        SET Allotment_MT_Key = @qoid
                        WHERE MQ_Id = @mq_Id
                    END

                    UPDATE QuotaObjects
                    SET QO_CTKEY = (SELECT HD_CTKEY FROM HotelDictionary WITH(NOLOCK) WHERE HD_KEY = QO_Code)
                    WHERE QO_ID = @qoid

                    UPDATE QuotaObjects
                    SET QO_CNKey = (SELECT CT_CNKEY FROM CityDictionary WITH(NOLOCK) WHERE CT_KEY = QO_CTKey)
                    WHERE (QO_CNKey IS NULL) AND (QO_CTKey IS NOT NULL) AND (QO_ID = @qoid)
                END
            END TRY
            BEGIN CATCH
                DECLARE @errorMessage_1 AS NVARCHAR(MAX)
                SET @errorMessage_1 = 'Error in LoadMisQuotas stop: ' + ERROR_MESSAGE() + CONVERT(NVARCHAR(MAX), @mq_Id)

                INSERT INTO SystemLog (sl_date, sl_message) VALUES (GETDATE(), @errorMessage_1)
            END CATCH
            BEGIN TRY
                IF (@mq_CancelStopSale = 1 AND (@mq_IsByCheckin <> 1 OR @mq_IsByCheckin IS NULL))
                BEGIN
                    IF (@mq_CommitmentTotal = 1 AND @mq_AllotmentTotal = 1)
                        SET @ss_allotmentAndCommitment = 2
                    ELSE IF (@mq_AllotmentTotal = 1 AND @mq_CommitmentTotal = 0)
                        SET @ss_allotmentAndCommitment = 0
                    ELSE IF (@mq_AllotmentTotal = 0 AND @mq_CommitmentTotal = 1)
                        SET @ss_allotmentAndCommitment = 1

                    IF (@ss_allotmentAndCommitment = 0 OR @ss_allotmentAndCommitment = 1)
                    BEGIN
						SET @qoid = (SELECT TOP 1 QO_ID
						             FROM StopSales WITH(NOLOCK)
						             JOIN QuotaObjects WITH(NOLOCK) ON SS_QOID = QO_ID
									 WHERE QO_Code = @mq_HotelKey
										AND QO_SVKey = 3
										AND SS_Date = @mq_Date
										AND SS_PRKey = @mq_PartnerKey
										AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
										AND SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
										AND QO_QTID IS NULL)
						IF (ISNULL(@qoid,0) <> 0)
                        BEGIN
                            DELETE StopSales
                            FROM StopSales WITH(NOLOCK)
                            JOIN QuotaObjects WITH(NOLOCK) ON SS_QOID = QO_ID
                            WHERE QO_Code = @mq_HotelKey
								AND QO_SVKey = 3
								AND SS_Date = @mq_Date
								AND SS_PRKey = @mq_PartnerKey
								AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
								AND SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
								AND QO_QTID IS NULL

							UPDATE MIS_Quotas
							SET Allotment_MT_Key = @qoid
							WHERE MQ_Id = @mq_Id
                        END
                        ELSE
                        BEGIN
                            PRINT 'Стоп-сейл был уже ранее удален'
                        END
                    END
                    ELSE IF (@ss_allotmentAndCommitment = 2) -- если пришла отмена на все (на allotment+commitment и на allotment)
                    BEGIN
						SET @qoid = (SELECT TOP 1 QO_ID
						             FROM StopSales WITH(NOLOCK)
									 JOIN QuotaObjects WITH(NOLOCK) ON SS_QOID = QO_ID
									 WHERE QO_Code = @mq_HotelKey
										AND QO_SVKey = 3
										AND SS_Date = @mq_Date
										AND SS_PRKey = @mq_PartnerKey
										AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
										AND QO_QTID IS NULL)
						IF (ISNULL(@qoid,0) <> 0)
                        BEGIN
                            DELETE StopSales
                            FROM StopSales WITH(NOLOCK)
							JOIN QuotaObjects WITH(NOLOCK) ON SS_QOID = QO_ID
                            WHERE QO_Code = @mq_HotelKey
								AND QO_SVKey = 3
								AND SS_Date = @mq_Date
								AND SS_PRKey = @mq_PartnerKey
								AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
								AND QO_QTID IS NULL

							UPDATE MIS_Quotas
							SET Allotment_MT_Key = @qoid, Commitment_MT_Key = @qoid
							WHERE MQ_Id = @mq_Id
                        END
                        ELSE
                        BEGIN
                            PRINT 'Стоп-сейл был уже ранее удален'
                        END
                    END
                END
            END TRY
            BEGIN CATCH
                DECLARE @errorMessage9 AS NVARCHAR(MAX)
                SET @errorMessage9 = 'Error in LoadMisQuotas cancel stop: ' + ERROR_MESSAGE() + CONVERT(NVARCHAR(MAX), @mq_Id)

                INSERT INTO SystemLog (sl_date, sl_message) VALUES (GETDATE(), @errorMessage9)
            END CATCH

            -- запретить заезд, т.е если @ptq_IsByCheckin = 1
            BEGIN TRY
                IF (@mq_IsByCheckin = 1 AND (@mq_CancelStopSale = 0 OR @mq_CancelStopSale IS NULL))
                BEGIN
                    IF (@mq_CommitmentTotal > 0)
                    BEGIN
                        IF EXISTS (SELECT TOP 1 1
                                    FROM Quotas WITH(NOLOCK)
									INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                    INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                    WHERE QT_PRKey = @mq_PartnerKey
										AND QO_SVKey = 3
										AND QO_Code = @mq_HotelKey
										AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
										AND QD_Date = @mq_Date
										AND QT_ByRoom = 1
										AND QD_Type = 2
										AND QT_IsByCheckIn = 0)
                        BEGIN
                            UPDATE QuotaParts SET QP_IsNotCheckIn = 1 WHERE QP_QDID IN
                                (SELECT QD_ID
                                FROM Quotas WITH(NOLOCK)
								INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                WHERE QT_PRKey = @mq_PartnerKey
									AND QO_SVKey = 3
									AND QO_Code = @mq_HotelKey
									AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
									AND QD_Date = @mq_Date
									AND QT_ByRoom = 1
									AND QD_Type = 2
									AND QT_IsByCheckIn = 0)

                            SET @qpid = SCOPE_IDENTITY()

                            UPDATE MIS_Quotas
                            SET Commitment_MT_Key = @qpid
                            WHERE MQ_Id = @mq_Id
                        END
                        ELSE
                        BEGIN
                            -- отправляем письмо
                            SELECT @hdname = ISNULL(HD_Name,0) FROM HotelDictionary WITH(NOLOCK) WHERE HD_Key = @mq_HotelKey
                            SELECT @rcname = ISNULL(RC_Name,0) FROM RoomsCategory WITH(NOLOCK) WHERE RC_key = @mq_RoomCategoryKey
                            SELECT @partnerName = ISNULL(PR_FullName,0) FROM Partners WITH(NOLOCK) WHERE PR_Key = @mq_PartnerKey
                            SET @str3 = @str3 + CHAR(13) + CHAR(13) + 'Партнер:' + CONVERT(VARCHAR(100),@partnerName) + '(' + CONVERT(VARCHAR(100),@mq_PartnerKey) + ')' + CHAR(13) +
                                                                    'Отель:' + CONVERT(VARCHAR(100),@hdname) + '(' + CONVERT(VARCHAR(100),@mq_HotelKey) + ')' + CHAR(13) +
                                                                    'Категория номера:' + CONVERT(VARCHAR(100),@rcname) + CHAR(13) +
                                                                    'Дата:' + CONVERT(VARCHAR(100),@mq_Date, 105) + CHAR(13)
                        END
                    END
                    IF (@mq_AllotmentTotal > 0)
                    BEGIN
                        IF EXISTS (SELECT TOP 1 1
                                    FROM Quotas WITH(NOLOCK)
									INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                    INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                    WHERE QT_PRKey = @mq_PartnerKey
										AND QO_SVKey = 3
										AND QO_Code = @mq_HotelKey
										AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
										AND QD_Date = @mq_Date
										AND QT_ByRoom = 1
										AND QD_Type = 1
										AND QT_IsByCheckIn = 0)
                        BEGIN
                            UPDATE QuotaParts  SET QP_IsNotCheckIn = 1 WHERE QP_QDID IN
                                (SELECT QD_ID
                                FROM Quotas WITH(NOLOCK)
								INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                WHERE QT_PRKey = @mq_PartnerKey
									AND QO_SVKey = 3
									AND QO_Code = @mq_HotelKey
									AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
									AND QD_Date = @mq_Date
									AND QT_ByRoom = 1
									AND QD_Type = 1
									AND QT_IsByCheckIn = 0)

                            SET @qpid = SCOPE_IDENTITY()

                            UPDATE MIS_Quotas
                            SET Allotment_MT_Key = @qpid
                            WHERE MQ_Id = @mq_Id
                        END
                        ELSE
                        BEGIN
                            -- отправляем письмо
                            SELECT @hdname = ISNULL(HD_Name,0) FROM HotelDictionary WITH(NOLOCK) WHERE HD_Key = @mq_HotelKey
                            SELECT @rcname = ISNULL(RC_Name,0) FROM RoomsCategory WITH(NOLOCK) WHERE RC_key = @mq_RoomCategoryKey
                            SELECT @partnerName = ISNULL(PR_FullName,0) FROM Partners WITH(NOLOCK) WHERE PR_Key = @mq_PartnerKey
                            SET @str3 = @str3 + CHAR(13) + CHAR(13) + 'Партнер:' + CONVERT(VARCHAR(100),@partnerName) + '(' + CONVERT(VARCHAR(100),@mq_PartnerKey) + ')' + CHAR(13) +
                                                                    'Отель:' + CONVERT(VARCHAR(100),@hdname) + '(' + CONVERT(VARCHAR(100),@mq_HotelKey) + ')' + CHAR(13) +
                                                                    'Категория номера:' + CONVERT(VARCHAR(100),@rcname) + CHAR(13) +
                                                                    'Дата:' + CONVERT(VARCHAR(100),@mq_Date, 105) + CHAR(13)
                        END
                    END
                END

                -- отправляем письмо
                IF EXISTS (SELECT 1 FROM SystemSettings WITH(NOLOCK) WHERE SS_ParmName='SYSEmailProtourQuotes')
                    SELECT @email = SS_ParmValue FROM SystemSettings WITH(NOLOCK) WHERE SS_ParmName='SYSEmailProtourQuotes'

                IF (@str3 <> 'Запрет на заезд не был проставлен, в связи с тем, что не существует квоты в Мастер-Туре. Параметры квот:')
                BEGIN
                    INSERT INTO SendMail (SM_EMAIL, SM_Text, SM_Date, SM_DateGet, SM_Creator, SM_DgKey) VALUES (ISNULL(@email,''), @str3, GETDATE(), '1900-01-01', ISNULL(@uskey,0), 0)
                END

            END TRY
            BEGIN CATCH
                DECLARE @errorMessage_20 AS NVARCHAR(MAX)
                SET @errorMessage_20 = 'Error in LoadMisQuotas ByCheckin: ' + ERROR_MESSAGE() + CONVERT(NVARCHAR(MAX), @mq_Id)

                INSERT INTO SystemLog (sl_date, sl_message)
                VALUES (GETDATE(), @errorMessage_20)
            END CATCH

            -- отмена запрета на заезд, т.е если @ptq_IsByCheckin = 1 и @ptq_CancelStopSale = 1
            BEGIN TRY
                IF (@mq_IsByCheckin = 1 AND @mq_CancelStopSale = 1)
                BEGIN
                    IF (@mq_CommitmentTotal > 0)
                    BEGIN
                        IF EXISTS (SELECT TOP 1 1
                                    FROM Quotas WITH(NOLOCK)
									INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                    INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                    WHERE QT_PRKey = @mq_PartnerKey
										AND QO_SVKey = 3
										AND QO_Code = @mq_HotelKey
										AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
										AND QD_Date = @mq_Date
										AND QT_ByRoom = 1
										AND QD_Type = 2
										AND QT_IsByCheckIn = 0)
                        BEGIN
                            UPDATE QuotaParts  SET QP_IsNotCheckIn = 0 WHERE QP_QDID IN
                                (SELECT QD_ID
                                FROM Quotas WITH(NOLOCK)
								INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                WHERE QT_PRKey = @mq_PartnerKey
									AND QO_SVKey = 3
									AND QO_Code = @mq_HotelKey
									AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
									AND QD_Date = @mq_Date
									AND QT_ByRoom = 1
									AND QD_Type = 2
									AND QT_IsByCheckIn = 0)

                            SET @qpid = (SELECT QD_ID
                            FROM Quotas WITH(NOLOCK)
							INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                            INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                            WHERE QT_PRKey = @mq_PartnerKey
								AND QO_SVKey = 3
								AND QO_Code = @mq_HotelKey
								AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
								AND QD_Date = @mq_Date
								AND QT_ByRoom = 1
								AND QD_Type = 2
								AND QT_IsByCheckIn = 0)

                            UPDATE MIS_Quotas
                            SET Commitment_MT_Key = @qpid
                            WHERE MQ_Id = @mq_Id
                        END
                        ELSE
                        BEGIN
                            -- отправляем письмо
                            SELECT @hdname = ISNULL(HD_Name,0) FROM HotelDictionary WITH(NOLOCK) WHERE HD_Key = @mq_HotelKey
                            SELECT @rcname = ISNULL(RC_Name,0) FROM RoomsCategory WITH(NOLOCK) WHERE RC_key = @mq_RoomCategoryKey
                            SELECT @partnerName = ISNULL(PR_FullName,0) FROM Partners WITH(NOLOCK) WHERE PR_Key = @mq_PartnerKey
                            SET @str3 = @str3 + CHAR(13) + CHAR(13) + 'Партнер:' + CONVERT(VARCHAR(100),@partnerName) + '(' + CONVERT(VARCHAR(100),@mq_PartnerKey) + ')' + CHAR(13) +
                                                                    'Отель:' + CONVERT(VARCHAR(100),@hdname) + '(' + CONVERT(VARCHAR(100),@mq_HotelKey) + ')' + CHAR(13) +
                                                                    'Категория номера:' + CONVERT(VARCHAR(100),@rcname) + CHAR(13) +
                                                                    'Дата:' + CONVERT(VARCHAR(100),@mq_Date, 105) + CHAR(13)
                        END
                    END
                    IF (@mq_AllotmentTotal > 0)
                    BEGIN
                        IF EXISTS (SELECT TOP 1 1
                                    FROM Quotas WITH(NOLOCK)
									INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                    INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                    WHERE QT_PRKey = @mq_PartnerKey
										AND QO_SVKey = 3
										AND QO_Code = @mq_HotelKey
										AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
										AND QD_Date = @mq_Date
										AND QT_ByRoom = 1
										AND QD_Type = 1
										AND QT_IsByCheckIn = 0)
                        BEGIN
                            UPDATE QuotaParts SET QP_IsNotCheckIn = 0 WHERE QP_QDID IN
                                (SELECT QD_ID
                                FROM Quotas WITH(NOLOCK)
								INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                                INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                                WHERE QT_PRKey = @mq_PartnerKey
									AND QO_SVKey = 3
									AND QO_Code = @mq_HotelKey
									AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
									AND QD_Date = @mq_Date
									AND QT_ByRoom = 1
									AND QD_Type = 1
									AND QT_IsByCheckIn = 0)

                            SET @qpid = (SELECT TOP 1 QD_ID
                            FROM Quotas WITH(NOLOCK)
							INNER JOIN QuotaDetails WITH(NOLOCK) ON QT_ID = QD_QTID
                            INNER JOIN QuotaObjects WITH(NOLOCK) ON QT_ID = QO_QTID
                            WHERE QT_PRKey = @mq_PartnerKey
								AND QO_SVKey = 3
								AND QO_Code = @mq_HotelKey
								AND (QO_SubCode2 = @mq_RoomCategoryKey OR @mq_RoomCategoryKey = 0)
								AND QD_Date = @mq_Date
								AND QT_ByRoom = 1
								AND QD_Type = 1
								AND QT_IsByCheckIn = 0)

                            UPDATE MIS_Quotas
                            SET Allotment_MT_Key = @qpid
                            WHERE MQ_Id = @mq_Id
                        END
                        ELSE
                        BEGIN
                            -- отправляем письмо
                            SELECT @hdname = ISNULL(HD_Name,0) FROM HotelDictionary WITH(NOLOCK) WHERE HD_Key = @mq_HotelKey
                            SELECT @rcname = ISNULL(RC_Name,0) FROM RoomsCategory WITH(NOLOCK) WHERE RC_key = @mq_RoomCategoryKey
                            SELECT @partnerName = ISNULL(PR_FullName,0) FROM Partners WITH(NOLOCK) WHERE PR_Key = @mq_PartnerKey
                            SET @str3 = @str3 + CHAR(13) + CHAR(13) + 'Партнер:' + CONVERT(VARCHAR(100),@partnerName) + '(' + CONVERT(VARCHAR(100),@mq_PartnerKey) + ')' + CHAR(13) +
                                                                    'Отель:' + CONVERT(VARCHAR(100),@hdname) + '(' + CONVERT(VARCHAR(100),@mq_HotelKey) + ')' + CHAR(13) +
                                                                    'Категория номера:' + CONVERT(VARCHAR(100),@rcname) + CHAR(13) +
                                                                    'Дата:' + CONVERT(VARCHAR(100),@mq_Date, 105) + CHAR(13)
                        END
                    END
                END

                -- отправляем письмо
                IF EXISTS (SELECT 1 FROM SystemSettings WITH(NOLOCK) WHERE SS_ParmName='SYSEmailProtourQuotes')
                    SELECT @email = SS_ParmValue FROM SystemSettings WITH(NOLOCK) WHERE SS_ParmName='SYSEmailProtourQuotes'

                IF (@str3 <> 'Запрет на заезд не был снят, в связи с тем, что не существует квоты в Мастер-Туре. Параметры квот:')
                BEGIN
                    INSERT INTO SendMail (SM_EMAIL, SM_Text, SM_Date, SM_DateGet, SM_Creator, SM_DgKey) VALUES (ISNULL(@email,''), @str3, GETDATE(), '1900-01-01', ISNULL(@uskey,0), 0)
                END

            END TRY
            BEGIN CATCH
                DECLARE @errorMessage_21 AS NVARCHAR(MAX)
                SET @errorMessage_21 = 'Error in LoadMisQuotas cancel ByCheckin: ' + ERROR_MESSAGE() + CONVERT(NVARCHAR(MAX), @mq_Id)

                INSERT INTO SystemLog (sl_date, sl_message) VALUES (GETDATE(), @errorMessage_21)
            END CATCH

            FETCH NEXT FROM qCur INTO @mq_Id, @mq_PartnerKey, @mq_HotelKey, @mq_RoomCategoryKey, @mq_RoomKey, @mq_Date, @mq_CommitmentTotal, @mq_AllotmentTotal,
                            @mq_Release, @mq_StopSale, @mq_CancelStopSale, @mq_IsByCheckin
        END
        CLOSE qCur
        DEALLOCATE qCur
    END

    -- Контрольная проверка (проверяем попали ли записи из Протура в МТ).
    DECLARE Cur CURSOR FOR
    SELECT * FROM @tmpQuotаs

    OPEN Cur
    FETCH NEXT FROM Cur INTO @mq_Id, @mq_PartnerKey, @mq_HotelKey, @mq_RoomCategoryKey, @mq_RoomKey, @mq_Date, @mq_CommitmentTotal, @mq_AllotmentTotal,
                             @mq_Release, @mq_StopSale, @mq_CancelStopSale

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT TOP 1 1 FROM StopSales WITH(NOLOCK)
                       JOIN QuotaObjects WITH(NOLOCK) ON SS_QOID = QO_ID
                        WHERE SS_PRKey = @mq_PartnerKey
                            AND QO_Code = @mq_HotelKey
                            AND SS_Date = @mq_Date
                            AND QO_SubCode2 = @mq_RoomCategoryKey
                            AND SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
                            AND QO_QTID IS NULL
                            AND QO_SVKey = 3)
        BEGIN
            DECLARE @error AS NVARCHAR(MAX)
            SET @error = 'Error in LoadMisQuotas stop not exists: ' + ERROR_MESSAGE() + CONVERT(NVARCHAR(MAX), @mq_Id)

            INSERT INTO SystemLog (sl_date, sl_message) VALUES (GETDATE(), @error)
        END
        FETCH NEXT FROM Cur INTO @mq_Id, @mq_PartnerKey, @mq_HotelKey, @mq_RoomCategoryKey, @mq_RoomKey, @mq_Date, @mq_CommitmentTotal, @mq_AllotmentTotal,
                                 @mq_Release, @mq_StopSale, @mq_CancelStopSale
    END
    CLOSE Cur
    DEALLOCATE Cur

    IF NOT EXISTS (SELECT TOP 1 1 FROM History WHERE (HI_Date BETWEEN DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND GETDATE()) AND HI_Text = 'Произошла закачка квот из ProtourQuotes')
    BEGIN
        INSERT INTO History (HI_Date, HI_Text) VALUES (GETDATE(), 'Произошла закачка квот из ProtourQuotes')
    END
END
GO

GRANT EXEC ON [dbo].[LoadMisQuotas] TO PUBLIC
GO

/*********************************************************************/
/* end sp_LoadMisQuotas.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplDeletePriceTour.sql */
/*********************************************************************/
if exists (select * from [dbo].sysobjects where id = object_id(N'[dbo].[mwReplDeletePriceTour]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    DROP PROCEDURE [dbo].[mwReplDeletePriceTour]
GO

create proc [dbo].[mwReplDeletePriceTour] @tokey int, @rqId int = null
as
begin

	--<VERSION>2009.2.21</VERSION>
	--<DATE>2014-01-16</DATE>

	if dbo.mwReplIsSubscriber() <= 0
		return

	declare @mwSearchType int
	select @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
		where SS_ParmName = 'MWDivideByCountry'

	if @mwSearchType = 0
	begin
		if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start insert into mwDeleted.'
		
		insert into mwDeleted with(rowlock) (del_key) 
			select pt_pricekey 
			from mwPriceDataTable with(nolock) 
			where pt_tourkey = @tokey

		if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwPriceDataTable.'
								
		update mwPriceDataTable with(rowlock) 
		set pt_isenabled = 0 
		where pt_isenabled > 0 and pt_tourkey = @tokey
	end
	else
	begin
		declare @tablename varchar(100), @sql varchar(8000)
		declare dCur cursor for select name from sysobjects with(nolock) where name like 'mwPriceDataTable[_]%' and xtype = 'u'
		open dCur

		if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start insert into mwDeleted and update mwPriceDataTables.'

		fetch next from dCur into @tablename

		while (@@fetch_status=0)
		begin
			set @sql = 'insert into mwDeleted with(rowlock) (del_key) 
				select pt_pricekey 
				from ' + @tableName + ' with(nolock) 
				where pt_tourkey = ' + ltrim(str(@tokey))
			exec (@sql)

			set @sql = 'update ' + @tableName + ' with(rowlock) 
				set pt_isenabled = 0 
				where pt_isenabled > 0 and pt_tourkey = ' + ltrim(str(@tokey))
			exec (@sql)

			fetch next from dCur into @tablename
		end
		close dCur
		deallocate dCur
	end
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwSpoDataTable.'
			
	update mwSpoDataTable with(rowlock) 
	set sd_isenabled = 0 
	where sd_isenabled > 0 and sd_tourkey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_Prices.'
	delete from TP_Prices with(rowlock) where tp_tokey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_ServiceLists.'
	delete from TP_ServiceLists with(rowlock) where tl_tokey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_Services.'
	delete from TP_Services with(rowlock) where ts_tokey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_Lists.'
	delete from TP_Lists with(rowlock) where ti_tokey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_Tours.'
	delete from TP_Tours with(rowlock) where to_key = @tokey
end
GO

GRANT exec ON [dbo].[mwReplDeletePriceTour] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwReplDeletePriceTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_RecalculatePriceListScheduler.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RecalculatePriceListScheduler]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[RecalculatePriceListScheduler]
GO

CREATE PROCEDURE [dbo].[RecalculatePriceListScheduler]
AS
--<DATE>2013-09-11</DATE>
---<VERSION>9.2.0</VERSION>
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
		where CP_StartTime is not null and (CP_Status = 3 and CP_StartTime<=GETDATE()) order by CP_StartTime asc
		UPDATE CalculatingPriceLists WITH (ROWLOCK) Set CP_Status=1 where CP_Key=@cpkey
	commit tran
	if (@cpkey is not null)
	begin
		select @priceTOKey = CP_PriceTourKey, @saleDate = CP_SaleDate,
			 @nullCostAsZero = CP_NullCostAsZero, @noFlight = CP_NoFlight, @useHolidayRule = CP_UseHolidayRule
		from CalculatingPriceLists where CP_Key = @cpkey
		begin try
			exec CalculatePriceList @priceTOKey, @cpkey, @saleDate, @nullCostAsZero, @noFlight, 0, @useHolidayRule
			UPDATE CalculatingPriceLists WITH (ROWLOCK) Set CP_Status=0, CP_StartTime=null where CP_Key=@cpkey
		end try
		begin catch
			UPDATE CalculatingPriceLists with (rowlock) set CP_Status=2 where CP_Key=@cpkey
		end catch
	end
END
GO

GRANT EXEC ON [dbo].[RecalculatePriceListScheduler] TO PUBLIC
GO
/*********************************************************************/
/* end sp_RecalculatePriceListScheduler.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_UpdateDeleteCost.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UpdateDeleteCost]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[UpdateDeleteCost]
GO

CREATE procedure [dbo].[UpdateDeleteCost]
(
	@sMode varchar(256), @nOldNetto float, @nOldBrutto float,  
	@dOldBeg datetime, @dOldEnd datetime, @nSvKey int, @nCode int, @nCode1 int, 
	@nCode2 int, @nPartner int, @nPaket int, @nNewNetto float, @nNewBrutto float, 
	@dNewBeg datetime, @dNewEnd datetime
)
AS

--<VERSION>2009.2.21</VERSION>
--<DATE>2014-01-16</DATE>
	declare @sOper varchar(256),
		@sText varchar(256),
		@sOldNetto varchar(256),
		@sOldBrutto varchar(256),
		@sNewNetto varchar(256),
		@sNewBrutto varchar(256),
		@sOldDateBeg varchar(256),
		@sOldDateEnd varchar(256),
		@sNewDateBeg varchar(256),
		@sNewDateEnd varchar(256)
	
	-- Flink 24-06-2005 MEG00004332	
	DECLARE @iHC_Key	int
	
	if	(@nOldNetto = @nNewNetto) and (@nOldBrutto = @nNewBrutto) and 
		(@dOldBeg = @dNewBeg) and (@dOldEnd = @dNewEnd) and (@sMode != 'DEL')
		Return 0

	Set @sOldNetto = isnull(CAST ( @nOldNetto  AS varchar ), '')
	Set @sNewNetto = isnull(CAST ( @nNewNetto  AS varchar ), '')
	Set @sOldBrutto = isnull(CAST ( @nOldBrutto  AS varchar ), '')
	Set @sNewBrutto = isnull(CAST ( @nNewBrutto  AS varchar ), '')
	Set @sOldDateBeg = isnull(CONVERT ( varchar , @dOldBeg, 105), '')
	Set @sNewDateBeg = isnull(CONVERT ( varchar , @dNewBeg, 105), '')
	Set @sOldDateEnd = isnull(CONVERT ( varchar , @dOldEnd, 105), '')
	Set @sNewDateEnd = isnull(CONVERT ( varchar , @dNewEnd, 105), '')

	EXEC dbo.CurrentUser @sOper output

	Set @sText = ''
	If @sMode != 'DEL'
	begin
		if @nOldNetto != @nNewNetto
		begin
			set @sText = 'Изменение нетто с ' + @sOldNetto + ' на ' + @sNewNetto + ' сезон ' + @sNewDateBeg + ' - ' + @sNewDateEnd
			
			-- Flink 24-06-2005 MEG00004332
			EXEC GetNKey 'HistoryCost', @iHC_Key output
			
			Insert into HistoryCost (HC_Key, HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
			VALUES (@iHC_Key, GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1,	@nCode2, @nPartner, @nPaket)
		end
		if @nOldBrutto != @nNewBrutto
		begin
			set @sText = 'Изменение брутто с ' + @sOldBrutto + ' на ' + @sNewBrutto + ' сезон ' + @sNewDateBeg + ' - ' + @sNewDateEnd
				
			-- Flink 24-06-2005 MEG00004332
			EXEC GetNKey 'HistoryCost', @iHC_Key output
			
			Insert into HistoryCost (HC_Key, HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
			VALUES ( @iHC_Key, GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1, @nCode2, @nPartner, @nPaket)
		end
		Set @sText = ''
		if @dOldBeg != @dNewBeg
			set @sText = 'Изменение даты начала с ' + @sOldDateBeg + ' на ' + @sNewDateBeg
		if @dOldEnd != @dNewEnd
		begin
			if @sText != ''
				set @sText = @sText + ', окончания с '
			Else
				set @sText = @sText + 'Изменение даты окончания с '
				
			set @sText = @sText + @sOldDateEnd + ' на ' + @sNewDateEnd
		end
		IF @sText != '' BEGIN		
			-- Flink 24-06-2005 MEG00004332
			EXEC GetNKey 'HistoryCost', @iHC_Key output
			
			Insert into HistoryCost (HC_Key, HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
			VALUES (@iHC_Key, GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1, @nCode2, @nPartner, @nPaket)
		END
	end
	else
	begin
		SET @sText = 'Удаление цены: нетто ' + @sOldNetto + ', брутто ' + @sOldBrutto + ', сезон с ' + @sOldDateBeg + ' по ' + @sOldDateEnd
		
		-- Flink 24-06-2005 MEG00004332
		EXEC GetNKey 'HistoryCost', @iHC_Key output
		
		INSERT INTO HistoryCost (HC_Key, HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
		VALUES (@iHC_Key, GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1, @nCode2, @nPartner, @nPaket)
	end
GO

GRANT EXECUTE ON [dbo].[UpdateDeleteCost]	TO PUBLIC
GO
/*********************************************************************/
/* end sp_UpdateDeleteCost.sql */
/*********************************************************************/

/*********************************************************************/
/* begin SynchronizeKeyTables.sql */
/*********************************************************************/
--удаление из таблицы Keys лишних записей (для которых есть таблица типа Key_ )
declare @tables table(
	tablekey nvarchar(50),
	tablename nvarchar(50)
)

insert into @tables
select key_table, name
from sys.objects 
inner join keys on key_table like replace(name, 'key_', '') 
where name like 'key_%' order by name

declare @sql nvarchar(max)
declare @tablekey nvarchar(50)
declare @tablename nvarchar(50)
declare cur cursor fast_forward read_only
for select tablekey, tablename from @tables

open cur

fetch next from cur into @tablekey, @tablename
while @@fetch_status = 0
begin
	set @sql = '
		declare @id int

		select @id = id from keys where key_table like ''' + @tablekey + '''

		update ' + @tablename + '
		set id = @id
		where id < @id

		delete from keys where key_table like ''' + @tablekey + '''
	'
	exec(@sql)
	fetch next from cur into @tablekey, @tablename
end

close cur
deallocate cur
GO
/*********************************************************************/
/* end SynchronizeKeyTables.sql */
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
update [dbo].[setting] set st_version = '9.2.20.6', st_moduledate = convert(datetime, '2014-01-24', 120),  st_financeversion = '9.2.20.6', st_financedate = convert(datetime, '2014-01-24', 120) 
 GO
 UPDATE dbo.SystemSettings SET SS_ParmValue='2014-01-24' WHERE SS_ParmName='SYSScriptDate'
 GO