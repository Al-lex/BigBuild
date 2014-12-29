/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 06.03.2014 17:43 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.7'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.8'

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
/* begin (2014.02.13)_Insert_Actions.sql */
/*********************************************************************/
--добавление action Разрешить пересадку услуг запрещенных для редактирования
IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 148) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES(148,'Квоты -> Отображать все продолжительности в экране "Статус бронирования"','Квоты -> Отображать все продолжительности в экране "Статус бронирования"', 'Quotes -> Show all durations in "Reservation status"', 1)
END
GO



/*********************************************************************/
/* end (2014.02.13)_Insert_Actions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.02.14)_Alter_Index_IX_MM1.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Lists]') AND name = N'IX_MM1')
DROP INDEX [IX_MM1] ON [dbo].[TP_Lists] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [IX_MM1] ON [dbo].[TP_Lists] 
(
	[TI_DAYS] ASC,
	[TI_FIRSTHDKEY] ASC
)
INCLUDE ( [TI_TOKey],TI_CTKEYFROM) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/*********************************************************************/
/* end (2014.02.14)_Alter_Index_IX_MM1.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.02.17)_Alter_Table_BonusWithDrawalRules.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM dbo.syscolumns WHERE name = 'BR_ProfitMin' AND id = object_id(N'[dbo].[BonusWithDrawalRules]'))
	ALTER TABLE [dbo].[BonusWithDrawalRules] ADD BR_ProfitMin MONEY NULL
GO

IF NOT EXISTS (SELECT 1 FROM dbo.syscolumns WHERE name = 'BR_ProfitMax' AND id = object_id(N'[dbo].[BonusWithDrawalRules]'))
	ALTER TABLE [dbo].[BonusWithDrawalRules] ADD BR_ProfitMax MONEY NULL
GO

IF NOT EXISTS (SELECT 1 FROM dbo.syscolumns WHERE name = 'BR_PriceMin' AND id = object_id(N'[dbo].[BonusWithDrawalRules]'))
	ALTER TABLE [dbo].[BonusWithDrawalRules] ADD BR_PriceMin MONEY NULL
GO
/*********************************************************************/
/* end (2014.02.17)_Alter_Table_BonusWithDrawalRules.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.02.19)_Alter_Table_ToursPackets.sql */
/*********************************************************************/
IF not exists( select 1 from dbo.sysobjects  where id = object_id(N'[dbo].[FK_ToursPackets_Tbl_TurList_TourId]')  and OBJECTPROPERTY(id, N'IsForeignKey') = 1) 
BEGIN
    ALTER TABLE [dbo].[ToursPackets] WITH CHECK ADD CONSTRAINT [FK_ToursPackets_Tbl_TurList_TourId] FOREIGN KEY([TRPK_TourId])
    REFERENCES [dbo].[tbl_TurList] ([TL_Key])
END
GO

IF not exists( select 1 from dbo.sysobjects  where id = object_id(N'[dbo].[FK_ToursPackets_Tbl_TurList_ExtSrvPacketId]')  and OBJECTPROPERTY(id, N'IsForeignKey') = 1) 
BEGIN
    ALTER TABLE [dbo].[ToursPackets] WITH CHECK ADD CONSTRAINT [FK_ToursPackets_Tbl_TurList_ExtSrvPacketId] FOREIGN KEY([TRPK_ExtSrvPkId])
    REFERENCES [dbo].[tbl_TurList] ([TL_Key])
END
GO
/*********************************************************************/
/* end (2014.02.19)_Alter_Table_ToursPackets.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckQuotesEx2.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesEx2]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesEx2]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesEx2]
(
	@svkey int, 
	@code int, 
	@subcode1 int,
	@subcode2 int, 
	@agentKey int, 
	@partnerKey int, 
	@date datetime,
	@day int,
	@days int,
	@requestOnRelease smallint, 
	@noPlacesResult int, 
	@checkAgentQuotes smallint, 
	@checkCommonQuotes smallint,
	@checkNoLongQuotes smallint,
	@findFlight smallint,
	@cityFrom int,
	@cityTo int,
	@flightpkkey int,
	@tourDuration int,
	@expiredReleaseResult int,
	@linked_day int = null)

returns @tmpResQuotes table(
	qt_svkey int,
	qt_code int,
	qt_subcode1 int,
	qt_subcode2 int,
	qt_agent int,
	qt_prkey int,
	qt_bycheckin int,
	qt_byroom int,
	qt_places int,
	qt_allPlaces int,
	qt_type int,
	qt_long int,
	qt_additional varchar(2000))
begin
	--<VERSION>9.2.19.15</VERSION>
	--<DATE>2013-09-17</DATE>

    declare @isSubCode2 smallint
    select @isSubCode2 = COALESCE(SV_ISSUBCODE2, 0) from [Service] where SV_key = @svkey
    if(@isSubCode2 <= 0)
		set @subcode2 = 0  		
	if(@svkey = 1)
		set @subcode2 = -1      
	
	-- настройка указывает, что отображать если нет мест
    if exists(select 1 from systemsettings where ss_parmname like 'NoPlacesQuoteResult_' + convert(varchar, @svkey))
    begin
		select @noPlacesResult = cast(COALESCE(ss_parmvalue,@noPlacesResult) as int) from systemsettings where ss_parmname like 'NoPlacesQuoteResult_' + convert(varchar, @svkey)          
    end

	declare @ALLDAYS_CHECK int
	set @ALLDAYS_CHECK = -777

	-- для квот на продолжительность
	declare @long int
	if(@svkey = 1 or @svkey = 2 or @svkey = 4 or @checkNoLongQuotes = @ALLDAYS_CHECK)
		set @long = @tourDuration
	else
		set @long = @days

	if(@day <= 0 or @day is null)
		set @day = 1
	if(@days <= 0 or @days is null)
		set @days = 1

	declare @dateFrom datetime, @dateTo datetime
	set @dateFrom = dateadd(day, @day - 1, @date)
	set @dateTo = dateadd(day, @day + @days - 2, @date)		

	if(@svkey = 1)
	begin
		
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		-- функция проверки квот на авиаперелеты
		select *
		from dbo.mwCheckQuotesFlights(@code, @subcode1, @agentKey, @partnerKey, 
			@dateFrom, @requestOnRelease, @noPlacesResult, @checkAgentQuotes, 
			@checkCommonQuotes, @checkNoLongQuotes, @findFlight, @cityFrom,	@cityTo, @flightpkkey,
			@tourDuration, @expiredReleaseResult, @linked_day)
		
		return
	end
	else
	begin
		declare @tmpSubcode1 int
		if(@svkey = 3 and @subcode1 > 0 and @subcode2 <= 0) 
		begin
			select @tmpSubcode1 = hr_rmkey, @subcode2 = hr_rckey from hotelrooms with(nolock) where hr_key = @subcode1
			set @subcode1 = @tmpSubcode1
		end
		
		declare @currentDate datetime
		select @currentDate = currentDate from dbo.mwCurrentDate
		
		declare @tmpQuotes as CheckQuotasSourceTable
		
		declare @qtSvkey int, @qtCode int, @qtSubcode1 int, @qtSubcode2 int, @qtAgent int,
		@qtPrkey int, @qtNotcheckin int, @qtRelease int, @qtPlaces int, @qtDate datetime,
		@qtByroom int, @qtType int, @qtLong int, @qtPlacesAll int, @qtStop smallint, @qtQoId int

		declare	@svkeyRes int, @codeRes int, @subcode1Res int, 
			@subcode2Res int, @agentRes int, @prkeyRes int,
			@bycheckinRes int, @byroomRes int, @placesRes int,
			@allPlacesRes int, @typeRes int, @longRes int, @releaseRes int, @additional varchar(2000), @stopSale smallint

		set @svkeyRes = 0
		set @codeRes = 0
		set @subcode1Res = 0
		set @subcode2Res = 0
		set @agentRes = 0
		set @prkeyRes = 0
		set @bycheckinRes = 0
		set @byroomRes = 0
		set @typeRes = 0
		set @allPlacesRes = 0
		set @longRes = 0
		set @releaseRes = -1
		set @additional = ''
		
		insert into @tmpQuotes select * from 
		(select 
			qo_svkey,
			qo_code,
			isnull(qo_subcode1, 0) as qo_subcode1,
			isnull(qo_subcode2, 0) as qo_subcode2,
			isnull(qp_agentkey, 0) as qp_agentkey,
			isnull(qt_prkey, 0) as qt_prkey,
			isnull(qp_isnotcheckin, 0) as qp_isnotcheckin, 
			qd_release, 
			isnull(qp_places, 0) - isnull(qp_busy, 0) as qt_freePlaces,
			qd_date,
			qt_byroom,
			qd_type,
			isnull(ql_duration, 0) as ql_duration,
			isnull(qp_places, 0) as qp_places,
			(case when (isnull(ss_id, 0) > 0 and isnull(ss_isdeleted, 0) = 0) then 1 else 0 end) as qt_stop,
			qo_id as qt_qoid, qd_id as qt_qdid
		from quotas q with(nolock) inner join 
			quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
			left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
			right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid 
			left outer join StopSales ss with(nolock) on (qd_id = ss_qdid and isnull(ss_isdeleted, 0) = 0)
		where
			qo_svkey = @svkey
			and ISNULL(QD_IsDeleted, 0) = 0
			and qo_code = @code
			and isnull(qo_subcode1, 0) in (0, @subcode1)
			and (@svKey = 1 or isnull(qo_subcode2, 0) in (0, @subcode2))
			and ((@checkAgentQuotes > 0 and @checkCommonQuotes > 0 and isnull(qp_agentkey, 0) in (0, @agentKey)) or
				(@checkAgentQuotes <= 0 and isnull(qp_agentkey, 0) = 0) or
				(@checkAgentQuotes > 0 and @checkCommonQuotes <= 0 and isnull(qp_agentkey, 0) in (0, @agentKey)))
			and (@partnerKey < 0 or isnull(qt_prkey, 0) in (0, @partnerKey))
			and ((@days = 1 and qd_date = @dateFrom) or (@days > 1 and qd_date between @dateFrom and @dateTo))
			and (@tourDuration < 0 or (@checkNoLongQuotes <> @ALLDAYS_CHECK and isnull(ql_duration, 0) in (0, @long)) or (@checkNoLongQuotes = @ALLDAYS_CHECK and isnull(ql_duration, 0) = @long))
			and not exists (select top 1 1 
									from StopSales inner join QuotaObjects on qo_id=ss_qoid
									where ((@days = 1 and ss_date = @dateFrom) or (@days > 1 and ss_date between @dateFrom and @dateTo))
									and ss_qdid is null
									and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
									and isnull(ss_isdeleted, 0) = 0
									and (qd.QD_Type = 1 or SS_AllotmentAndCommitment = 1)
									and qo_svkey = @svkey
									and qo_code = @code
									and isnull(qo_subcode1, 0) in (0, @subcode1)
									and isnull(qo_subcode2, 0) in (0, @subcode2))
		-- Paul G 07.02.2011 MEG00031547, MEG00031454
		-- Не отлавливались такие дни, на которые нет квот, но есть стоп-сейл.
		-- Да и вообще не учитывались стопы с пустой ссылкой на QuotaDetails.
		-- Добавил union, который учитывает стопы с пустой ссылкой на QuotaDetails.
		union
			select
				qo_svkey,
				qo_code,
				isnull(qo_subcode1, 0) as qo_subcode1,
				isnull(qo_subcode2, 0) as qo_subcode2,
				0,
				isnull(ss_prkey, 0) as qt_prkey,
				0,null,0,ss_date,null,isnull(SS_AllotmentAndCommitment, 0) + 1,0,0,1,
				qo_id as qt_qoid, null
			from StopSales
				inner join QuotaObjects on qo_id=ss_qoid
			where ((@days = 1 and ss_date = @dateFrom) or (@days > 1 and ss_date between @dateFrom and @dateTo))
					and ss_qdid is null
					and isnull(ss_isdeleted, 0) = 0
					and qo_svkey = @svkey
					and qo_code = @code
					and isnull(qo_subcode1, 0) in (0, @subcode1)
					and isnull(qo_subcode2, 0) in (0, @subcode2)
					and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
			union
			select
				qo_svkey,
				qo_code,
				isnull(qo_subcode1, 0) as qo_subcode1,
				isnull(qo_subcode2, 0) as qo_subcode2,
				0,
				isnull(ss_prkey, 0) as qt_prkey,
				0,null,0,ss_date,null,isnull(SS_AllotmentAndCommitment, 0) + 1,QL_Duration,0,1,
				qo_id as qt_qoid, QD_ID as qt_qdid
			from StopSales
				inner join QuotaObjects on qo_id=ss_qoid
				inner join QuotaDetails on QD_ID=SS_QDID
				left join QuotaParts on QP_QDID = qd_id
				left join QuotaLimitations on QL_QPID = qp_id
			where ((@days = 1 and ss_date = @dateFrom) or (@days > 1 and ss_date between @dateFrom and @dateTo))
					and ss_qdid is not null
					and isnull(ss_isdeleted, 0) = 0
					and qo_svkey = @svkey
					and qo_code = @code
					and isnull(qo_subcode1, 0) in (@subcode1)
					and isnull(qo_subcode2, 0) in (0, @subcode2)
					and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
		) as innerQuotas
		order by
			qd_date, qp_agentkey DESC, qt_freePlaces, QD_Release desc, qd_type DESC, QT_PrKey DESC, qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC, qo_subcode2 DESC
		-- тут вставлю логику проверки для отелей
		
		-- если квота проверяется из экрана HotelQuotes, проверка на наличие общего стопа
		if (@tourDuration < 0 and @svkey = 3)
		begin
			if exists(select 1 
					from stopsales with(nolock) 
						inner join quotaobjects qo with(nolock) on ss_qoid = qo_id
					where qo_svkey = @svkey and qo_code = @code and isnull(qo_subcode1, 0) in (0, @subcode1)
						and isnull(qo_subcode2, 0) in (0, @subcode2) and ss_date between @dateFrom and @dateTo
						and (ss_qdid is null ) 
						and isnull(ss_isdeleted, 0) = 0 
						and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
						and (IsNull(ss_allotmentandcommitment, 0) = 1 
							or not exists(select 1 from
							quotas with(nolock) inner join quotaobjects qo1 with(nolock) on
							qo1.qo_qtid = qt_id inner join quotadetails with(nolock) on qd_qtid = qt_id
							 where qo.qo_svkey = qo1.qo_svkey and qo.qo_code = qo1.qo_code and (qo.qo_subcode1 in (qo1.qo_subcode1, 0) or qo1.qo_subcode1 = 0)
							 and (qo.qo_subcode2 in (qo1.qo_subcode2, 0) or qo1.qo_subcode2 = 0) and qd_date = ss_date and qd_places > qd_busy and qd_type = 2)))
			begin
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
				qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
				
				return
			end							 
		end
		
		-- для экрана HotelQuotes
		-- если не существует не одной квоты, то возвращаем запрос
		-- если есть места, но стоит стоп, то возвращаем нет мест	
		if (not exists (select top 1 1 from @tmpQuotes) and @tourDuration < 0
			and not exists(select top 1 1 from quotas q with(nolock) inner join 
											quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
											left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
											right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid
											where qo_svkey = @svkey
											and ISNULL(QD_IsDeleted, 0) = 0
											and qo_code = @code
											and isnull(qo_subcode1, 0) in (0, @subcode1)
											and isnull(qo_subcode2, 0) in (0, @subcode2)
											and ((@checkAgentQuotes > 0 and @checkCommonQuotes > 0 and isnull(qp_agentkey, 0) in (0, @agentKey)) or
												(@checkAgentQuotes <= 0 and isnull(qp_agentkey, 0) = 0) or
												(@checkAgentQuotes > 0 and @checkCommonQuotes <= 0 and isnull(qp_agentkey, 0) in (0, @agentKey)))
											and (@partnerKey < 0 or isnull(qt_prkey, 0) in (0, @partnerKey))
											and ((@days = 1 and qd_date = @dateFrom) or (@days > 1 and qd_date between @dateFrom and @dateTo))
											and (@tourDuration < 0 or (@checkNoLongQuotes <> @ALLDAYS_CHECK 
											and isnull(ql_duration, 0) in (0, @long)) or (@checkNoLongQuotes = @ALLDAYS_CHECK and isnull(ql_duration, 0) = @long))))
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, @noPlacesResult, 0, 0, 0, '0=-1:0')
			return
		end
		else if (not exists (select top 1 1 from @tmpQuotes) and @tourDuration < 0)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
			return
		end
		
		-- пробуем удалить стопы по следующему принципу: если стоит стоп на один тип квоты, но на другом типе с квотами все в порядке
		if ((select count(distinct qt_date) from @tmpQuotes where qt_places > 0 and qt_stop = 0 and qt_type = 1) = @days
			and exists(select 1 from @tmpQuotes where qt_stop = 1 and qt_type = 2))
		begin
			delete from @tmpQuotes where qt_stop = 1 and qt_type = 2
		end
		
		if ((select count(distinct qt_date) from @tmpQuotes where qt_places > 0 and qt_stop = 0 and qt_type = 2) = @days
			and exists(select 1 from @tmpQuotes where qt_stop = 1 and qt_type = 1)
		)
		begin
			delete from @tmpQuotes where qt_stop = 1 and qt_type = 1
		end

		if (exists(select top 1 1 from @tmpQuotes where qt_date=@dateFrom and qt_bycheckin=1)
			and not exists(select top 1 1 from @tmpQuotes where qt_date=@dateFrom and qt_places>0 and qt_placesAll>0 and isNull(qt_release,0) <= (@dateFrom - GETDATE()))
			and exists(select top 1 1 from @tmpQuotes where qt_date=@dateFrom and isNull(qt_release,0) > (@dateFrom - GETDATE())))
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
			return
		end
		
		-- если одновременно на alotment и commitment нет мест, возвращаем отсутствие мест
		if
		(
			(
				exists(select 1 from @tmpQuotes as tq1 where ((qt_stop = 1 or qt_places = 0) and qt_type = 2) and not exists(select 1 from @tmpQuotes as tq2 where tq2.qt_stop=0 and tq2.qt_places>0 and tq2.qt_date=tq1.qt_date))
			)
			and
			(
				exists(select 1 from @tmpQuotes as tq1 where ((qt_stop = 1 or qt_places = 0) and qt_type = 1) and not exists(select 1 from @tmpQuotes as tq2 where tq2.qt_stop=0 and tq2.qt_places>0 and tq2.qt_date=tq1.qt_date))
			)
		)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, @noPlacesResult, 0, 0, 0, '0=0:0')
				
			return
		end
		
		if(@tourDuration < 0) -- надо проверить все возможные квоты по дням на все возможные продолжительности (используется при проверке наличия мест в отеле и на перелете)
		begin
			set @checkNoLongQuotes = @ALLDAYS_CHECK

			declare @durations table(
				duration int
			)

			insert into @durations select distinct qt_long from @tmpQuotes order by qt_long

			declare @rowCount int
			set @rowCount = @@rowCount

			if(@rowCount > 1)
			begin
				declare @quotaDuration int
				declare durationCur cursor fast_forward read_only for
					select duration from @durations
	
				open durationCur
	
				fetch next from durationCur into @quotaDuration
				while(@@fetch_status = 0)
				begin
					if(len(@additional) > 0)
						set @additional = @additional + '|'
	
					select 
						@additional = @additional + qt_additional
					from dbo.mwCheckQuotesEx(@svkey, @code, @subcode1, @subcode2, @agentKey, @partnerKey, 
						@date, @day, @days, @requestOnRelease, @noPlacesResult, @checkAgentQuotes, 
						@checkCommonQuotes, @ALLDAYS_CHECK, @findFlight, @cityFrom,	@cityTo, @flightpkkey,
						@quotaDuration,	@expiredReleaseResult)
	
					fetch next from durationCur into @quotaDuration
				end
	
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @additional)
			
				close durationCur
				deallocate durationCur
	
				return
			end
			else if(@rowCount = 1)
				select @long = duration from @durations
			else
				set @long = 0
		end
		else
		begin
			-- check stopsale
			-- MT ignore stop on object for commitment quotas
			if exists(select 1 
					from stopsales with(nolock) 
						inner join quotaobjects qo with(nolock) on ss_qoid = qo_id
					where qo_svkey = @svkey and qo_code = @code and isnull(qo_subcode1, 0) in (0, @subcode1)
						and isnull(qo_subcode2, 0) in (0, @subcode2) and ss_date between @dateFrom and @dateTo
						and (ss_qdid is null ) 
						and isnull(ss_isdeleted, 0) = 0 
						and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
						-- MEG00032187 Paul G 14.02.2011
						-- Отсеиваем те стопы, которые ставятся только на allotment (ss_allotmentandcommitment = 0)
						-- и по которым на соответствующие дни есть квоты commitment.
						and (IsNull(ss_allotmentandcommitment, 0) = 1 
							or not exists(select 1 from
							quotas with(nolock) inner join quotaobjects qo1 with(nolock) on
							qo1.qo_qtid = qt_id inner join quotadetails with(nolock) on qd_qtid = qt_id
						--MEG00029495 Paul G 18.02.2010
						--Добавил условие qd_places > qd_busy
						--Смысл в том, что это условие должно проверять существование квот commitment на некоторые дни, но только тех
						--на которые еще есть места. Иначе возможна ситуация, когда на все commitment закончились места, а allotment на стопе
						--и проверка на наличие стопа не сработает
							 where qo.qo_svkey = qo1.qo_svkey and qo.qo_code = qo1.qo_code and (qo.qo_subcode1 in (qo1.qo_subcode1, 0) or qo1.qo_subcode1 = 0)
							 and (qo.qo_subcode2 in (qo1.qo_subcode2, 0) or qo1.qo_subcode2 = 0) and qd_date = ss_date and qd_places > qd_busy and qd_type = 2 /*commitment*/)))
			begin
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
						values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
							return 
			end

		end
		
		if (isnull((select min(qt_bycheckin)
					from @tmpQuotes
					where qt_date = @dateFrom), 0) = 1 AND @checkNoLongQuotes != @ALLDAYS_CHECK AND (SELECT CASE WHEN (SELECT COUNT(*) FROM @tmpQuotes) > 0 THEN 1 ELSE 0 END)=1)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
								values(0, 0, 0, 0, 0, 0, 0, 0, case when @stopSale > 0 then 0 else @noPlacesResult end, 0, 0, 0)
								return
		end

		if isnull((select max(stopSale)
					from (select min(qt_stop) as stopSale
							from @tmpQuotes
							where qt_qoid = (select top 1 qt_qoid from @tmpQuotes where qt_date = @dateFrom) and isnull(qt_prkey, 0) = isnull(@partnerkey, 0)
							group by qt_date) as tbl), 0) = 1
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
						values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
							return 
		end
		
		-- MEG00024921, Danil, 10.02.2010: значения переменных предыдущей проверенной строки
		declare @prevSubCode1 int, @prevSubCode2 int, @prevQtType int, @result int, @tmpDate datetime
		-- MEG00024921 End

		declare qCur cursor fast_forward read_only for 
		select
			qt_svkey,
			qt_code,
			qt_subcode1,
			qt_subcode2,
			qt_agent,
			qt_prkey,
			qt_bycheckin,
			qt_release,
			qt_places,
			qt_date,
			qt_byroom,
			qt_type,
			qt_long,
			qt_placesAll,
			qt_stop,
			qt_qoid
		from @tmpQuotes

		open qCur

		fetch next from qCur 
			into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
				@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, 
				@qtByroom, @qtType, @qtLong, @qtPlacesAll, @qtStop, @qtQoId

		-- MEG00024921, Danil, 10.02.2010: значения переменных предыдущей проверенной строки
		set @prevSubCode1 = @qtSubcode1
		set @prevSubCode2 = @qtSubcode2
		set @prevQtType = @qtType
		-- MEG00024921 End
		
		if(@@fetch_status = 0)
		begin
			set @result = 1000000

			declare @prevDate datetime, @dateRes int, @dateAllPlaces int, @wasLongQuota smallint, @wasAgentQuota smallint, 
			@checkAfterWasLong smallint, @checkAfterWasAgent smallint, @isFirstDate bit, @prevDateRes int, @prevDateOld datetime

			set @prevDate = @dateFrom
			if(@qtDate = @dateFrom)
				set @dateRes = 0
			else
				set @dateRes = -1
			set @dateAllPlaces = 0
			set @stopSale = 1
			set @wasLongQuota = 0
			set @wasAgentQuota = 0
			set @checkAfterWasLong = 0
			set @checkAfterWasAgent = 0
			set @isFirstDate = 1
			set @prevDateRes = 0

			declare @quoteOnFirstDayExist smallint -- признак существования квоты на ПЕРВЫЙ день
				set @quoteOnFirstDayExist = 0

			while(@@fetch_status = 0)
			begin
				if(@qtStop > 0) -- stop sale
				begin
					close qCur
					deallocate qCur

					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
					values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
					return
				end

				if(@checkNoLongQuotes != @ALLDAYS_CHECK)
				begin
					-- Если обрабатываемая квота - квота на первый день, то выставляем индикатор в true
					if (@qtDate = @dateFrom and @qtNotcheckin = 0)
						set @quoteOnFirstDayExist = 1

					-- Если обрабатываемая квота - квота НЕ на первый день и в первый день ее не обнаруживалось, то возвращаем ЗАПРОС
					if (@qtDate != @dateFrom and @quoteOnFirstDayExist = 0)
					begin
						--MEG00032854 Paul G 05.04.2011
						--раньше в этом месте анализ квот прекращался и возвращался запрос, но это неправильно. 
						set @dateRes = -1
					end
				end

				--MEG00035270 Paul G 14.06.2011
				--для дальнейшего анализа квоты необходимо выполнение условия:
				--если она не на заезд, то должна найтись другая квота на заезд, на день предоставления услуги, но в том же объекте квотирования
				--эта проверка нужна для того, чтобы при наличии 2-х объектов квотирования с разными разбиениями на заезды не пересекались
				if (@qtNotcheckin = 1 and not exists(select 1 from @tmpQuotes where qt_qoid = @qtQoId and qt_bycheckin = 0 and qt_date = @dateFrom))
				begin
					fetch next from qCur 
						into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
							@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, 
							@qtByroom, @qtType, @qtLong, @qtPlacesAll, @qtStop, @qtQoId

					continue
				end
				--End MEG00035270

				if(@qtNotcheckin <= 0 or @qtDate <> @dateFrom or @checkNoLongQuotes = @ALLDAYS_CHECK)
				begin
					if(@prevDate != @qtDate)
					begin

						if(@dateRes = 0 /*and @stopSale <= 0*/ and ((@wasLongQuota > 0 and @checkAfterWasLong <= 0 and @checkNoLongQuotes > 0) or (@wasAgentQuota > 0 and @checkAfterWasAgent <= 0 and @checkCommonQuotes > 0)))
							set @dateRes = -1
				
						if(@checkNoLongQuotes = @ALLDAYS_CHECK)
						begin
							if(len(@additional) > 0)
								set @additional = @additional + ','

							if(@dateRes = 0 and @stopSale <= 0)
								set @dateRes = @noPlacesResult

							set @additional = @additional + ltrim(str(@dateRes)) + ':' + ltrim(str(@dateAllPlaces))
						end
						else
						if(@dateRes <= 0 or @dateRes < @result or @qtStop > 0)
						begin
							set @result = @dateRes
							set @allPlacesRes = @dateAllPlaces -- total places in quota

							if(@result = 0 or @qtStop > 0) -- no places
							begin
								close qCur
								deallocate qCur

								insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
								values(0, 0, 0, 0, 0, 0, 0, 0, case when @qtStop > 0 then 0 else @noPlacesResult end, 0, 0, 0, '0=0:0')
								return
							end
						end
						else
						begin
							if(@wasLongQuota > 0)
								set @checkAfterWasLong = 1

							if(@wasAgentQuota > 0)
								set @checkAfterWasAgent = 1
						end
		
						if(datediff(day, @prevDate, @qtDate) > 1) -- there are days for wich quota doesn't exist
						begin
							set @result = -1 -- request
							if(@checkNoLongQuotes = @ALLDAYS_CHECK)
							begin
								set @tmpDate = dateadd(day, 1, @prevDate)
								while(@tmpDate < @qtDate)
								begin
									if(len(@additional) > 0)
										set @additional = @additional + ','

									set @additional = @additional + '-1:0'
									set @tmpDate = dateadd(day, 1, @tmpDate)
								end
							end
						end
							
						set @prevDate = @qtDate
						set @dateRes = 0
						set @dateAllPlaces = 0
						set @stopSale = 1
						set @wasLongQuota = 0
						set @wasAgentQuota = 0
						set @checkAfterWasLong = 0
						set @checkAfterWasAgent = 0

						-- MEG00024921, Danil, 10.02.2010: значения переменных предыдущей проверенной строки
						set @prevSubCode1 = @qtSubcode1
						set @prevSubCode2 = @qtSubcode2
						set @prevQtType = @qtType
						-- MEG00024921 End

					end
					
					if( -- MEG00024921, Danil, 10.02.2010: это условие было странным образом закомментарено + добавлена проверка на qtStop.
						-- Привел логику в соответствие с версией хранимки для 2007.2, где в аналогичной ситуации все работает.
						-- Проверку на qtStop перенес в следующий if
						(@stopSale <= 0 or ((@prevSubCode1 = @qtSubcode1 and @prevSubCode2 = @qtSubcode2) or @prevQtType <> @qtType))
						and not(@agentKey > 0 and @qtAgent = 0 and @wasAgentQuota > 0 and (@checkCommonQuotes <= 0))
								and not(@long > 0 and @qtLong = 0 and @wasLongQuota > 0 and (@checkNoLongQuotes <= 0)))
					begin
						if((@qtRelease is null or datediff(day, @currentDate, @qtDate) >= isnull(@qtRelease, 0))
							-- MEG00024921, Danil, 10.02.2010: сюда перенес проверку на qtStop из условия выше (по аналогии с версией 2007.2)
							and isnull(@qtStop, 0) = 0)
							-- MEG00024921 End
						begin
							if((@requestOnRelease <= 0 or @qtRelease is null or @qtRelease > 0) and
								@qtPlaces > 0 and not(@stopSale > 0 and @wasAgentQuota > 0 /*request for agents if they have agent quota and this quota is stopped (they try to reserve general quota by low cost)*/))
							begin

								--koshelev
								--TFS 7661 28.08.2012
								if (@days = 1)
								begin
									set @dateRes = @qtPlaces--@dateRes + @qtPlaces
								end
								else
								begin
									if (@qtPlaces = 1)
										set @dateRes = @qtPlaces
									else									
										set @dateRes = @dateRes + @qtPlaces
								end
								set @dateAllPlaces = @dateAllPlaces + @qtPlacesAll
								
								if (@qtPlaces < @result) -- result перезапишется
								begin
									set @svkeyRes = @qtSvkey
									set @codeRes = @qtCode
									set @subcode1Res = @qtSubcode1
									set @subcode2Res = @qtSubcode2
									set @agentRes = @qtAgent
									set @prkeyRes = @qtPrkey										
									set @byroomRes = @qtByroom
									set @typeRes = @qtType
									set @longRes = @qtLong
									set @releaseRes = @qtRelease
								end
							end
							else if(@qtPlaces > 0)
								set @dateRes = -1
						end
						else 
						begin
							if(isnull(@qtStop, 0) = 0 and @qtPlaces > 0)
								set @dateRes = @expiredReleaseResult -- no or request (0 or -1)
							else
							-- MEG00024921, Danil, 10.02.2010: добавил эту секцию, чтобы в случае, если не стоп, 
							-- а просто закончились места возвращалось @noPlacesResult
							if(isnull(@qtStop, 0) = 0)
							begin
								set @dateRes = @noPlacesResult -- no places
							end
							else
							-- MEG00024921 End
							begin
								set @dateRes = 0 -- stop sale
								set @result = 0
							end
						end
						--set @bycheckinRes =  1 - @qtNotcheckin
--set @bycheckinRes =  0
						
						-- MEG00024921, Danil, 10.02.2010: простановка признака "был ли стоп" для проверяемой даты
						-- опять же по аналогии с 2007.2
						if (isnull(@qtStop, 0) = 0)
							set @stopSale = 0
						-- MEG00024921 End
					end
					else if(@dateRes = 0 and @checkNoLongQuotes <> @ALLDAYS_CHECK)
					begin
						close qCur
						deallocate qCur
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						-- MEG00024921, Danil, 10.02.2010: добавил значение qt_additional и его заполнение
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
						values(0, 0, 0, 0, 0, 0, 0, 0, case when @stopSale > 0 then 0 else @noPlacesResult end, 0, 0, 0, '0=0:0')
						-- MEG00024921 End
						return 
					end

					if(@wasAgentQuota <= 0 and @qtAgent > 0) -- признак того, что агентская квота заведена, но закончилась
						set @wasAgentQuota = 1
					if(@wasLongQuota <= 0 and @qtLong > 0)  -- признак того, что квота на продолжительность заведена, но закончилась
						set @wasLongQuota = 1
				end

				-- MEG00024921, Danil, 10.02.2010: значения переменных предыдущей проверенной строки
				set @prevSubCode1 = @qtSubcode1
				set @prevSubCode2 = @qtSubcode2
				set @prevQtType = @qtType
				-- MEG00024921 End
				if (@isFirstDate = 0 and @prevDateOld = @qtDate and @prevDateRes > 0)
				begin
					set @dateRes = @prevDateRes
				end
				set @isFirstDate = 0
				set @prevDateRes = @dateRes
				set @prevDateOld = @qtDate
				fetch next from qCur into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
					@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, @qtByroom, @qtType, 
					@qtLong, @qtPlacesAll, @qtStop, @qtQoId
			end

			if(@checkNoLongQuotes = @ALLDAYS_CHECK)
			begin
				if(len(@additional) > 0)
					set @additional = @additional + ','

				if(@dateRes = 0 and @stopSale <= 0)
					set @dateRes = @noPlacesResult
				
				set @additional = @additional + ltrim(str(@dateRes)) + ':' + ltrim(str(@dateAllPlaces))
			end
			else
			if(@dateRes <= 0 or @dateRes < @result)
			begin
				set @result = @dateRes
				set @allPlacesRes = @dateAllPlaces -- total places in quota

				if(@result = 0) -- iano iao
					set @result = case when @stopSale > 0 then 0 else @noPlacesResult end
			end

			if(@qtDate <> @dateTo and ((@result > 0 and @bycheckinRes <= 0) or @checkNoLongQuotes = @ALLDAYS_CHECK)) -- ia iaio ec aao aeaiaciia eaioa ia caaaaaia
			begin
				set @result = -1 -- cai?in
				if(@checkNoLongQuotes = @ALLDAYS_CHECK)
				begin
					set @tmpDate = dateadd(day, 1, @qtDate)
					while(@tmpDate <= @dateTo)
					begin
						if(len(@additional) > 0)
							set @additional = @additional + ','

						set @additional = @additional + '-1:0'
						set @tmpDate = dateadd(day, 1, @tmpDate)
					end
				end
			end
		end
		else
		begin
			set @result = -1
			if(@checkNoLongQuotes = @ALLDAYS_CHECK)
			begin
				set @tmpDate = @dateFrom
				while(@tmpDate <= @dateTo)
				begin
					if(len(@additional) > 0)
						set @additional = @additional + ','

					set @additional = @additional + '-1:0'
					set @tmpDate = dateadd(day, 1, @tmpDate)								
				end
			end
		end	
		
		if(@checkNoLongQuotes <> @ALLDAYS_CHECK)
		begin
			if (@result > 0)
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
				values(@svkeyRes, @codeRes, @subcode1Res, @subcode2Res, @agentRes, 
					@prkeyRes, @bycheckinRes, @byroomRes, @result, @allPlacesRes, @typeRes, @longRes)
			else
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
				values(0, 0, 0, 0, 0, 0, 0, 0, @result, 0, 0, 0)
		end
		else
		begin
				set @additional = ltrim(str(@long)) + '=' + @additional
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @additional)
		end
		
		return 
	end
	return  
end
GO

GRANT SELECT ON [dbo].[mwCheckQuotesEx2] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwCheckQuotesEx2.sql */
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

--<DATE>2014-02-20</DATE>
---<VERSION>9.2.21.7</VERSION>

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

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
	--Update	TP_Flights with(rowlock) Set 	TF_CodeNew = TF_CodeOld,
	--			TF_PRKeyNew = TF_PRKeyOld
	--Where	(SELECT count(*) FROM AirSeason  with(nolock) WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') > 0 
	--	and TF_TOKey = @nPriceTourKey	

	exec sp_executesql 
	N'
	update TP_Flights set TF_CodeNew = null, TF_PRKeyNew = null, TF_SubCode1New = null where TF_TOKey = @nPriceTourKey

	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1, TF_CalculatingKey = @nCalculatingKey
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey 
			and TF_Date BETWEEN ISNULL(CS_Date, ''1900-01-01'') AND ISNULL(CS_DateEnd, ''2053-01-01'') 
			and TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(CS_CHECKINDATEEND, ''2053-01-01'')
			and (ISNULL(CS_Week, '''') = '''' or CS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'') 
			and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long))
			and TF_TOKey = @nPriceTourKey

	If @nNoFlight = 2
	BEGIN
		------ проверяем, а есть ли у данного парнера по рейсу, цены на другие рейсы в этом же пакете ----
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
			-- подбираем подходящие нам перелеты
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
			) and
			CS_PKKey = TF_PKKey and
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
	', N'@nPriceTourKey int, @nCalculatingKey int, @nNoFlight smallint', @nPriceTourKey, @nCalculatingKey, @nNoFlight
	
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
	--<data>2014-02-19</data>
	--<version>9.2.21.7</version>
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
declare @NumPrices int, @NumCalculated int
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

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey and TF_Date BETWEEN CS_Date AND  CS_DateEnd and (ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long))
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
			-- подбираем подходящие нам перелеты
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
			) and
			CS_PKKey = TF_PKKey and
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
			[xTP_Key] [int] PRIMARY KEY NOT NULL ,
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
			
			select @numDates = COUNT(1) from TP_TurDates with(nolock), TP_Lists with(nolock), TP_Prices with(nolock) where TP_TIKey = TI_Key and TD_Date between TP_DateBegin and TP_DateEnd and TP_TOKey = @nPriceTourKey and TD_TOKey = @nPriceTourKey and TI_TOKey = @nPriceTourKey
			exec GetNKeys 'TP_PRICES', @numDates, @nTP_PriceKeyMax output
			set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @numDates + 1
		
			declare datesCursor cursor local fast_forward for
			select TD_Date, TI_Key, TP_Gross from TP_TurDates with(nolock), TP_Lists with(nolock), TP_Prices with(nolock) where TP_TIKey = TI_Key and TD_Date between TP_DateBegin and TP_DateEnd and TP_TOKey = @nPriceTourKey and TD_TOKey = @nPriceTourKey and TI_TOKey = @nPriceTourKey
			
			open datesCursor
			fetch next from datesCursor into @priceDate, @priceListKey, @priceListGross
			while @@FETCH_STATUS = 0
			begin
				insert into #TP_Prices (xTP_Key, xTP_TOKey, xTP_TIKey, xTP_DateBegin, xTP_DateEnd, xTP_CalculatingKey) 
				values (@nTP_PriceKeyCurrent, @nPriceTourKey, @priceListKey, @priceDate, @priceDate, @nCalculatingKey)
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

		exec GetNKeys 'TP_PRICES', @NumPrices, @nTP_PriceKeyMax output
		set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @NumPrices + 1
		set @dtPrevDate = '1899-12-31'
		set @nPrevVariant = -1
		set @nPrevGross = -1
		set @nPrevGrossDate = '1899-12-31'
		set @prevHdKey = -1

		delete from #TP_Prices
		
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
						update #TP_Prices set xtp_calculatingkey = @nCalculatingKey, xtp_key = @nTP_PriceKeyCurrent where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant and xtp_gross <> @price_brutto
						set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
						
					end
					else if (@isPriceListPluginRecalculation = 0)
					begin
						--select @nCalculatingKey
						insert into #TP_Prices (xtp_key, xtp_tokey, xtp_datebegin, xtp_dateend, xtp_tikey, xTP_CalculatingKey, xTP_Days, xTP_Rate, xTP_HotelKey, xTP_DepartureKey
						, xSCPId_1, xSCPId_2, xSCPId_3, xSCPId_4, xSCPId_5, xSCPId_6, xSCPId_7, xSCPId_8, xSCPId_9, xSCPId_10, xSCPId_11, xSCPId_12, xSCPId_13, xSCPId_14, xSCPId_15
						, xSvKey_1, xSvKey_2, xSvKey_3, xSvKey_4, xSvKey_5, xSvKey_6, xSvKey_7, xSvKey_8, xSvKey_9, xSvKey_10, xSvKey_11, xSvKey_12, xSvKey_13, xSvKey_14, xSvKey_15
						, xGross_1, xGross_2, xGross_3, xGross_4, xGross_5, xGross_6, xGross_7, xGross_8, xGross_9, xGross_10, xGross_11, xGross_12, xGross_13, xGross_14, xGross_15
						, xAddCostIsCommission_1, xAddCostIsCommission_2, xAddCostIsCommission_3, xAddCostIsCommission_4, xAddCostIsCommission_5, xAddCostIsCommission_6, xAddCostIsCommission_7, xAddCostIsCommission_8, xAddCostIsCommission_9, xAddCostIsCommission_10, xAddCostIsCommission_11, xAddCostIsCommission_12, xAddCostIsCommission_13, xAddCostIsCommission_14, xAddCostIsCommission_15
						, xAddCostNoCommission_1, xAddCostNoCommission_2, xAddCostNoCommission_3, xAddCostNoCommission_4, xAddCostNoCommission_5, xAddCostNoCommission_6, xAddCostNoCommission_7, xAddCostNoCommission_8, xAddCostNoCommission_9, xAddCostNoCommission_10, xAddCostNoCommission_11, xAddCostNoCommission_12, xAddCostNoCommission_13, xAddCostNoCommission_14, xAddCostNoCommission_15
						, xMarginPercent_1, xMarginPercent_2, xMarginPercent_3, xMarginPercent_4, xMarginPercent_5, xMarginPercent_6, xMarginPercent_7, xMarginPercent_8, xMarginPercent_9, xMarginPercent_10, xMarginPercent_11, xMarginPercent_12, xMarginPercent_13, xMarginPercent_14, xMarginPercent_15
						, xCommissionOnly_1, xCommissionOnly_2, xCommissionOnly_3, xCommissionOnly_4, xCommissionOnly_5, xCommissionOnly_6, xCommissionOnly_7, xCommissionOnly_8, xCommissionOnly_9, xCommissionOnly_10, xCommissionOnly_11, xCommissionOnly_12, xCommissionOnly_13, xCommissionOnly_14, xCommissionOnly_15
						, xIsCommission_1, xIsCommission_2, xIsCommission_3, xIsCommission_4, xIsCommission_5, xIsCommission_6, xIsCommission_7, xIsCommission_8, xIsCommission_9, xIsCommission_10, xIsCommission_11, xIsCommission_12, xIsCommission_13, xIsCommission_14, xIsCommission_15)
						values (@nTP_PriceKeyCurrent, @nPriceTourKey, @dtPrevDate, @dtPrevDate, @nPrevVariant, @nCalculatingKey, @tiDays, @sRate, @hdKey, @tiCtKeyFrom
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
						
						set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
					end
				end
				
				--очищаем данные
				if @@fetch_status = 0
				begin
					if @nTP_PriceKeyCurrent > @nTP_PriceKeyMax
					BEGIN
						exec GetNKeys 'TP_PRICES', @NumPrices, @nTP_PriceKeyMax output
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

	update CalculatingPriceLists with(rowlock) set CP_Status = 0, CP_StartTime = null where CP_Key = @nCalculatingKey

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

	Return 0
END
go 

grant exec on CalculatePriceListDynamic to public

go
/*********************************************************************/
/* end sp_CalculatePriceListDynamic.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckQuotaExist.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckQuotaExist]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckQuotaExist]
GO

CREATE PROCEDURE [dbo].[CheckQuotaExist]
(
--<DATE>2014-02-20</VERSION>
--<VERSION>2009.2.25</VERSION>
	@SVKey int,
	@Code int,
	@SubCode1 int,
	@DateBeg datetime, 
	@DateEnd datetime,
	@DateFirst datetime,
	@PRKey int,
	@AgentKey int,
	@TourDuration smallint,
	@FilialKey int,				--пока не обрабатывается 
	@CityDepartment int,		--пока не обрабатывается 
	--возвращаемые параметры
	--при наличии Stop-Sale возвращаем

--	Убрал, не нужны более
--	@StopExist int output, --ключ стопа
--	@StopDate smalldatetime output, --дата стопа 

	--переехали из [CheckQuotaInfo]
	@TypeOfResult smallint =null,			
	/*	тип результата 
			0-возвращение полной таблицы данных (без фильтров) используется в экране проверки мест, 
			1-информация о первой подходящей квоте, 
			2-максимальное доступное число мест по всем квотам */	
	@Pax smallint =null,					--кол-во туристов по услуге
	--возвращаемые параметры, в случае @TypeOfResult=2 (попытка проверить возможность постановки услуги на квоту)
	@Wait smallint =null, --в случае не надо снимать квоту,
	@Quota_CheckState smallint =null output,
	/*	0 - RQ (можно бронировать только под запрос)
		1 - OK (можно посадить на квоту)
		2 - STOP (стоп, мест на сущ.квотах недостаточно)
		3 - RELEASE (стопа нет, есть релиз, мест на сущ.квотах недостаточно)	*/
	@Quota_CheckDate smalldatetime =null output,
	/*  если @Quota_Check=2, то в этом поле дата на которую стоит стоп */
	@Quota_CheckInfo smallint =null output,
	/*  если @Quota_Check in (0,3), то в этом поле сколько мест не хватает */

	--возвращаемые параметры, в случае @TypeOfResult=1 (возвращаем характеристики оптимальной квоты)
	@Quota_Count int =null output,
	@Quota_AgentKey int =null output,
	@Quota_Type smallint =null output,
	@Quota_ByRoom bit =null output,
	@Quota_PRKey int =null output, 
	@Quota_FilialKey int =null output,
	@Quota_CityDepartments int =null output,
	@Quota_Duration smallint =null output,
	@Quota_SubCode1 int =null output,
	@Quota_SubCode2 int =null output
	
) AS

if (@Wait=1 AND @TypeOfResult=2)
BEGIN
	set @Quota_CheckState=0
	return 0
end
declare @quoted smallint
select @quoted = isnull(SV_Quoted, 0) from Service where SV_Key = @SVKEY
if (@quoted = 0)
BEGIN
	set @Quota_CheckState=1
	return 0
end
Set @DateFirst=ISNULL(@DateFirst,@DateBeg)

declare @LimitAgentQuote bit, @LimitQuoteLong bit
set @LimitAgentQuote = 0
set @LimitQuoteLong = 0

IF EXISTS(SELECT top 1 1 FROM dbo.SystemSettings WHERE SS_ParmName='SYSLimitAgentQuote' and SS_ParmValue = 1)
	set @LimitAgentQuote = 1
IF EXISTS(SELECT top 1 1 FROM dbo.SystemSettings WHERE SS_ParmName='SYSLimitQuoteLong' and SS_ParmValue = 1)
	set @LimitQuoteLong = 1

--Проверка отсутствия Стопа
declare @StopExist int, @StopDate smalldatetime

exec CheckStopInfo 1,null,@SVKey,@Code,@SubCode1,@PRKey,@DateBeg,@DateEnd,@StopExist output,@StopDate output

declare @Q_QTID int, @Q_Partner int, @Q_ByRoom int, @Q_Type int, @Q_Release int, 
		@Q_FilialKey int, @Q_CityDepartments int, @Q_AgentKey int, @Q_Duration smallint,
		@Q_Places smallint, @ServiceWithDuration bit, @SubQuery varchar(5000), @Query varchar(5000),
		@Q_SubCode1 int, @Q_SubCode2 int, @Q_QTID_Prev int, @DaysCount int, @Q_IsByCheckIn smallint

SET @DaysCount=DATEDIFF(DAY,@DateBeg,@DateEnd)+1
SET @Q_QTID_Prev=0

SELECT @ServiceWithDuration=ISNULL(SV_IsDuration,0) FROM [Service] WHERE SV_Key=@SVKey
IF @ServiceWithDuration=1
	SET @TourDuration=DATEDIFF(DAY,@DateBeg,@DateEnd)+1

-- karimbaeva 28-04-2012 чтобы не выводилось сообщение о недостатке квоты на дополнительное место, если квота последняя и размещение на номер 
IF @SVKey = 3
begin
	if exists(SELECT TOP 1 1 FROM QuotaObjects, Quotas, QuotaDetails, QuotaParts, HotelRooms WHERE QD_QTID=QT_ID and QD_ID=QP_QDID and QO_QTID=QT_ID
	and HR_Key=@SubCode1 and HR_MAIN=0 and QT_ByRoom = 1 and (QP_AgentKey=@AgentKey or QP_AgentKey is null)
	and (QT_PRKey=@PRKey or QT_PRKey=0) and QO_Code=@Code and QD_Date between @DateBeg and @DateEnd and QP_Date = QD_Date
	and QP_ID in (select SD_QPID
					from ServiceByDate as SBD2 join RoomPlaces as RP2 on SBD2.SD_RPID = RP2.RP_ID
					where RP2.RP_Type = 0))
	begin
		set @Quota_CheckInfo = 0
		Set @Quota_CheckState = 1
		If @StopExist > 0
		BEGIN
			Set @Quota_CheckState = 2						
			Set @Quota_CheckDate = @StopDate
		END
		return 0
	end
end

-- создаем таблицу со стопами
CREATE TABLE #StopSaleTemp
(SST_Code int, SST_SubCode1 int, SST_SubCode2 int, SST_QOID int, SST_PRKey int, SST_Date smalldatetime,
SST_QDID int, SST_Type smallint, SST_State smallint, SST_Comment varchar(255)
)

-- Task 9148 31.10.2012 ошибка при преобразовании datetime в smalldatetime
if @DateBeg<'1900-01-01'
	set @DateBeg='1900-01-01'
--
INSERT INTO #StopSaleTemp exec dbo.GetTableQuotaDetails NULL, @Q_QTID, @DateBeg, @DaysCount, null, null, @SVKey, @Code, @SubCode1, @PRKey

IF @SVKey = 3
BEGIN
	declare CheckQuotaExistСursor cursor for 
		select	DISTINCT QT_ID, QT_PRKey, QT_ByRoom, 
				QD_Type, 
				QP_FilialKey, QP_CityDepartments, QP_AgentKey, CASE WHEN QP_Durations='' THEN 0 ELSE @TourDuration END, QP_FilialKey, QP_CityDepartments, 
				QO_SubCode1, QO_SubCode2, QT_IsByCheckIn
		from	QuotaObjects, Quotas, QuotaDetails, QuotaParts, HotelRooms
		where	QO_SVKey=@SVKey and QO_Code=@Code and HR_Key=@SubCode1 and (QO_SubCode1=HR_RMKey or QO_SubCode1=0) and (QO_SubCode2=HR_RCKey or QO_SubCode2=0) and QO_QTID=QT_ID
			and QD_QTID=QT_ID and QD_Date between @DateBeg and @DateEnd
			and QP_Date = QD_Date
			and QP_QDID = QD_ID
			and (QP_AgentKey=@AgentKey or QP_AgentKey is null) 
			and (QT_PRKey=@PRKey or QT_PRKey=0)
			and QP_IsDeleted is null and QD_IsDeleted is null	
			and (QP_Durations = '' or @TourDuration in (Select QL_Duration From QuotaLimitations Where QL_QPID=QP_ID))
			and not exists(select top 1 1
							from #StopSaleTemp 
							where SST_PRKey = QT_PRKey
							and SST_QOID = QO_ID
							and SST_QDID = QD_ID
							and SST_Date = QD_Date
							and SST_State is not null)
		group by QT_ID, QT_PRKey, QT_ByRoom, QD_Type, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_Durations, QO_SubCode1, QO_SubCode2, QT_IsByCheckIn
		--having Count(*) = (@Days+1)
		order by QP_AgentKey DESC, QT_PRKey DESC
END
ELSE
BEGIN
	declare CheckQuotaExistСursor cursor for 
		select	DISTINCT QT_ID, QT_PRKey, QT_ByRoom, 
				QD_Type, 
				QP_FilialKey, QP_CityDepartments, QP_AgentKey, CASE WHEN QP_Durations='' THEN 0 ELSE @TourDuration END, QP_FilialKey, QP_CityDepartments, 
				QO_SubCode1, QO_SubCode2, QT_IsByCheckIn
		from	QuotaObjects, Quotas, QuotaDetails, QuotaParts
		where	
			QO_SVKey = @SVKey and QO_Code = @Code and (QO_SubCode1=@SubCode1 or QO_SubCode1=0) and QO_QTID=QT_ID
			and QD_QTID = QT_ID and QD_Date between @DateBeg and @DateEnd
			and QP_QDID = QD_ID
			and QP_Date = QD_Date
			and (QP_AgentKey=@AgentKey or QP_AgentKey is null) 
			and (QT_PRKey=@PRKey or QT_PRKey=0)
			and QP_IsDeleted is null and QD_IsDeleted is null	
			and (QP_Durations = '' or @TourDuration in (Select QL_Duration From QuotaLimitations Where QL_QPID=QP_ID))
			and not exists(select top 1 1
							from #StopSaleTemp 
							where SST_PRKey = QT_PRKey
							and SST_QOID = QO_ID
							and SST_QDID = QD_ID
							and SST_Date = QD_Date
							and SST_State is not null)
		group by QT_ID, QT_PRKey, QT_ByRoom, QD_Type, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_Durations, QO_SubCode1, QO_SubCode2, QT_IsByCheckIn
		order by QP_AgentKey DESC, QT_PRKey DESC
END
open CheckQuotaExistСursor
fetch CheckQuotaExistСursor into	@Q_QTID, @Q_Partner, @Q_ByRoom, 
									@Q_Type, 
									@Q_FilialKey, @Q_CityDepartments, @Q_AgentKey, @Q_Duration, @Q_FilialKey, @Q_CityDepartments, 
									@Q_SubCode1, @Q_SubCode2, @Q_IsByCheckIn

CREATE TABLE #Tbl (	TMP_Count int, TMP_QTID int, TMP_AgentKey int, TMP_Type smallint, TMP_Date datetime, 
					TMP_ByRoom bit, TMP_Release smallint, TMP_Partner int, TMP_Durations nvarchar(25) COLLATE Cyrillic_General_CI_AS, TMP_FilialKey int, 
					TMP_CityDepartments int, TMP_SubCode1 int, TMP_SubCode2 int, TMP_IsByCheckIn smallint, TMP_DurationsCheckIn nvarchar(25))

While (@@fetch_status = 0)
BEGIN
	SET @SubQuery = 'QD_QTID = QT_ID and QP_QDID = QD_ID 
		and QT_ID=' + CAST(@Q_QTID as varchar(10)) + '
		and QT_ByRoom=' + CAST(@Q_ByRoom as varchar(1)) + ' 
		and QD_Type=' + CAST(@Q_Type as varchar(1)) + ' 
		and QO_SVKey=' + CAST(@SVKey as varchar(10)) + '
		and QO_Code=' + CAST(@Code as varchar(10)) + ' 
		and QO_SubCode1=' + CAST(@Q_SubCode1 as varchar(10)) + ' 
		and QO_SubCode2=' + CAST(@Q_SubCode2 as varchar(10)) + '	
		and (QD_Date between ''' + CAST((@DateBeg) as varchar(20)) + ''' and ''' + CAST(@DateEnd as varchar(20)) + ''') and QD_IsDeleted is null'

	IF @Q_FilialKey is null
		SET @SubQuery = @SubQuery + ' and QP_FilialKey is null'
	ELSE
		SET @SubQuery = @SubQuery + ' and QP_FilialKey=' + CAST(@Q_FilialKey as varchar(10))
	IF @Q_CityDepartments is null
		SET @SubQuery = @SubQuery + ' and QP_CityDepartments is null'
	ELSE
		SET @SubQuery = @SubQuery + ' and QP_CityDepartments=' + CAST(@Q_CityDepartments as varchar(10))
	IF @Q_AgentKey is null
		SET @SubQuery = @SubQuery + ' and QP_AgentKey is null'
	ELSE
		SET @SubQuery = @SubQuery + ' and QP_AgentKey=' + CAST(@Q_AgentKey as varchar(10))		
	IF @Q_Duration=0
		SET @SubQuery = @SubQuery + ' and QP_Durations = '''' '
	ELSE
		SET @SubQuery = @SubQuery + ' and QP_ID in (Select QL_QPID From QuotaLimitations Where QL_Duration=' + CAST(@Q_Duration as varchar(5)) + ') '
	IF @Q_Partner =''
		SET @SubQuery = @SubQuery + ' and QT_PRKey = '''' '
	ELSE
		SET @SubQuery = @SubQuery + ' and QT_PRKey=' + CAST(@Q_Partner as varchar(10))
	IF @Q_IsByCheckIn is null
		SET @SubQuery = @SubQuery + ' and QT_IsByCheckIn is null'
	ELSE
		SET @SubQuery = @SubQuery + ' and QT_IsByCheckIn=' + CAST(@Q_IsByCheckIn as varchar(10))

	declare @SubCode2 int
	
	IF (@Q_IsByCheckIn = 0 or @Q_IsByCheckIn is null)
		SET @Query = 
		'
		INSERT INTO #Tbl (	TMP_Count, TMP_QTID, TMP_AgentKey, TMP_Type, TMP_Date, 
							TMP_ByRoom, TMP_Release, TMP_Partner, TMP_Durations, TMP_FilialKey, 
							TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2, TMP_IsByCheckIn, TMP_DurationsCheckIn)
			SELECT	DISTINCT QP_Places-QP_Busy as d1, QT_ID, QP_AgentKey, QD_Type, QD_Date, 
					QT_ByRoom, QD_Release, QT_PRKey, QP_Durations, QP_FilialKey,
					QP_CityDepartments, QO_SubCode1, QO_SubCode2, QT_IsByCheckIn, '''' 
			FROM	Quotas QT1, QuotaDetails QD1, QuotaParts QP1, QuotaObjects QO1, #StopSaleTemp
			WHERE	QO_ID = SST_QOID and QD_ID = SST_QDID and SST_State is null and ' + @SubQuery
	
	IF @Q_IsByCheckIn = 1
		SET @Query = 
		'
		INSERT INTO #Tbl (	TMP_Count, TMP_QTID, TMP_AgentKey, TMP_Type, TMP_Date, 
							TMP_ByRoom, TMP_Release, TMP_Partner, TMP_Durations, TMP_FilialKey, 
							TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2, TMP_IsByCheckIn, TMP_DurationsCheckIn)
			SELECT	DISTINCT QP_Places-QP_Busy as d1, QT_ID, QP_AgentKey, QD_Type, QD_Date, 
					QT_ByRoom, QD_Release, QT_PRKey, QP_Durations, QP_FilialKey,
					QP_CityDepartments, QO_SubCode1, QO_SubCode2, QT_IsByCheckIn, convert(nvarchar(max) ,QD_LongMin) + ''-'' + convert(nvarchar(max) ,QD_LongMax)
			FROM	Quotas QT1, QuotaDetails QD1, QuotaParts QP1, QuotaObjects QO1, #StopSaleTemp
			WHERE	QO_ID = SST_QOID and QD_ID = SST_QDID and SST_State is null and ' + @SubQuery
			
	--print @Query

	exec (@Query)
	
	SET @Q_QTID_Prev=@Q_QTID
	fetch CheckQuotaExistСursor into	@Q_QTID, @Q_Partner, @Q_ByRoom, 
										@Q_Type, 
										@Q_FilialKey, @Q_CityDepartments, @Q_AgentKey, @Q_Duration, @Q_FilialKey, @Q_CityDepartments, 
										@Q_SubCode1, @Q_SubCode2, @Q_IsByCheckIn	
END

--select * from #tbl

/*
Обработаем настройки
						При наличии квоты на агенство, запретить бронирование из общей квоты
						При наличии квоты на продолжительность, запретить бронировать из квоты без продолжительности
*/

-- если стоят 2 настройки и параметры пришли и на продолжительность и на агенство и есть такая квота сразу на агенство и на продолжительность,
-- то удалим остальные
if ((@LimitAgentQuote = 1) and (@LimitQuoteLong = 1))
begin
	if ((isnull(@AgentKey, 0) != 0) and (isnull(@TourDuration, 0) != 0) and (exists (select top 1 1 from #Tbl where isnull(TMP_AgentKey, 0) = @AgentKey and isnull(TMP_Durations, 0) = @TourDuration)))
	begin
		delete #Tbl where isnull(TMP_AgentKey, 0) != @AgentKey or isnull(TMP_Durations, 0) != @TourDuration
	end
	
	--бывают случаии когда обе настройки включены, но найти нужно только по одному из параметров
	if (exists (select top 1 1 from #Tbl where isnull(TMP_AgentKey, 0) = @AgentKey))
	begin
		delete #Tbl where isnull(TMP_AgentKey, 0) != @AgentKey
	end
	if (exists (select top 1 1 from #Tbl where isnull(TMP_Durations, 0) = @TourDuration))
	begin
		delete #Tbl where isnull(TMP_Durations, 0) != @TourDuration
	end
end
-- если стоит настройка только на агенство и нам пришол параметром агенство и квота на агенство есть,
-- то удалим остальные
else if ((@LimitAgentQuote = 1) and (@LimitQuoteLong = 0) and (isnull(@AgentKey, 0) != 0) and (exists (select top 1 1 from #Tbl where isnull(TMP_AgentKey, 0) = @AgentKey)))
begin
	delete #Tbl where isnull(TMP_AgentKey, 0) != @AgentKey
end
-- если есть настройка на продолжительность, и нам пришол параметр продолжительность и есть квота на продолжительность,
-- то удалим остальные
else if ((@LimitAgentQuote = 0) and (@LimitQuoteLong = 1) and (isnull(@TourDuration, 0) != 0) and (exists (select top 1 1 from #Tbl where isnull(TMP_Durations, 0) = @TourDuration)))
begin
	delete #Tbl where isnull(TMP_Durations, 0) != @TourDuration	
end

DELETE FROM #Tbl WHERE exists 
		(SELECT top 1 1  FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2 
		WHERE	QT_ID=QD_QTID and QP_QDID=QD_ID
				and QD_Type=TMP_Type and QT_ByRoom=TMP_ByRoom
				and QD_IsDeleted is null and QP_IsDeleted is null
				and QT_ID=TMP_QTID
				and ISNULL(QP_FilialKey,-1)=ISNULL(TMP_FilialKey,-1) and ISNULL(QP_CityDepartments,-1)=ISNULL(TMP_CityDepartments,-1)
				and ISNULL(QP_AgentKey,-1)=ISNULL(TMP_AgentKey,-1) and ISNULL(QT_PRKey,-1)=ISNULL(TMP_Partner,-1)
				and QP_Durations=TMP_Durations and ISNULL(QD_Release,-1)=ISNULL(TMP_Release,-1)
				and QD_Date=@DateFirst and (QP_IsNotCheckIn=1 or QP_CheckInPlaces-QP_CheckInPlacesBusy <= 0))

close CheckQuotaExistСursor
deallocate CheckQuotaExistСursor

DECLARE @Tbl_DQ Table 
 		(TMP_Count smallint, TMP_AgentKey int, TMP_Type smallint, TMP_ByRoom bit, 
				TMP_Partner int, TMP_Duration smallint, TMP_FilialKey int, TMP_CityDepartments int,
				TMP_SubCode1 int, TMP_SubCode2 int, TMP_ReleaseIgnore bit, TMP_IsByCheckIn smallint, TMP_DurationsCheckIn nvarchar(25))

DECLARE @DATETEMP datetime
SET @DATETEMP = GetDate()
-- Разрешим посадить в квоту с релиз периодом 0 текущим числом
set @DATETEMP = DATEADD(day, -1, @DATETEMP)
if exists (select top 1 1 from systemsettings where SS_ParmName='SYSAddQuotaPastPermit' and SS_ParmValue=1 and @DateBeg < @DATETEMP)
	SET @DATETEMP='01-JAN-1900'
INSERT INTO @Tbl_DQ
	SELECT	MIN(d1) as TMP_Count, TMP_AgentKey, TMP_Type, TMP_ByRoom, TMP_Partner, 
			d2 as TMP_Duration, TMP_FilialKey, TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2, 0 as TMP_ReleaseIgnore, TMP_IsByCheckIn, TMP_DurationsCheckIn FROM
		(SELECT	SUM(TMP_Count) as d1, TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner, 
				TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END as d2, TMP_SubCode1, TMP_SubCode2, TMP_IsByCheckIn, TMP_DurationsCheckIn
		FROM	#Tbl
		WHERE	(TMP_Date >= @DATETEMP + ISNULL(TMP_Release,0) OR (TMP_Date < GETDATE() - 1))
		GROUP BY	TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner,
					TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END, TMP_SubCode1, TMP_SubCode2, TMP_IsByCheckIn, TMP_DurationsCheckIn) D
	GROUP BY	TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner,
				TMP_FilialKey, TMP_CityDepartments, d2, TMP_SubCode1, TMP_SubCode2, TMP_IsByCheckIn, TMP_DurationsCheckIn
	HAVING count(*)=DATEDIFF(day,@DateBeg,@DateEnd)+1
	UNION
	SELECT	MIN(d1) as TMP_Count, TMP_AgentKey, TMP_Type, TMP_ByRoom, TMP_Partner, 
			d2 as TMP_Duration, TMP_FilialKey, TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2, 1 as TMP_ReleaseIgnore, TMP_IsByCheckIn, TMP_DurationsCheckIn FROM
		(SELECT	SUM(TMP_Count) as d1, TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner, 
				TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END as d2, TMP_SubCode1, TMP_SubCode2, TMP_IsByCheckIn, TMP_DurationsCheckIn
		FROM	#Tbl
		GROUP BY	TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner,
					TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END, TMP_SubCode1, TMP_SubCode2, TMP_IsByCheckIn, TMP_DurationsCheckIn) D
	GROUP BY	TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner,
				TMP_FilialKey, TMP_CityDepartments, d2, TMP_SubCode1, TMP_SubCode2, TMP_IsByCheckIn, TMP_DurationsCheckIn
	HAVING count(*)=DATEDIFF(day,@DateBeg,@DateEnd)+1

/*
Комментарии к запросу выше!!!
Заполняем таблицу квот, которые могут нам подойти (группируя квоты по всем разделяемым параметрам, кроме релиз-периода
Все строки в таблице дублируются (важно! 11-ый параметр): 
	квоты с учетом релиз-периода (0) --TMP_ReleaseIgnore
	квоты без учета релиз-периода (1)--TMP_ReleaseIgnore
При выводе всех доступных квот требуется отсекать строки без учета релиз-периода и с количеством мест <=0 
*/

DECLARE @IsCommitmentFirst bit
IF Exists (SELECT SS_ID FROM dbo.SystemSettings WHERE SS_ParmName='SYS_Commitment_First' and SS_ParmValue='1')
	SET @IsCommitmentFirst=1

If @TypeOfResult is null or @TypeOfResult=0
BEGIN
	IF @IsCommitmentFirst=1
		select * from @Tbl_DQ order by TMP_IsByCheckIn DESC
	ELSE
		select * from @Tbl_DQ order by TMP_IsByCheckIn DESC
END

DECLARE @Priority int;
SELECT @Priority=QPR_Type FROM   QuotaPriorities 
WHERE  QPR_Date=@DateFirst and QPR_SVKey = @SVKey and QPR_Code=@Code and QPR_PRKey=@PRKey

IF @Priority is not null
	SET @IsCommitmentFirst=@Priority-1

If @TypeOfResult=1 --(возвращаем характеристики оптимальной квоты)
BEGIN
	If exists (SELECT top 1 1 FROM @Tbl_DQ)
	BEGIN
		IF @Quota_Type=1 or @IsCommitmentFirst=1
			select	TOP 1 @Quota_Count=TMP_Count, 
					@Quota_AgentKey=TMP_AgentKey, @Quota_Type=TMP_Type, @Quota_ByRoom=TMP_ByRoom,
					@Quota_PRKey=TMP_Partner, @Quota_FilialKey=TMP_FilialKey, @Quota_CityDepartments=TMP_CityDepartments, 
					@Quota_Duration=TMP_Duration, @Quota_SubCode1=TMP_SubCode1, @Quota_SubCode2=TMP_SubCode2
			from	@Tbl_DQ 
			where	TMP_Count>0 and TMP_ReleaseIgnore=0
			order by TMP_ReleaseIgnore, TMP_Type DESC, TMP_Partner DESC, TMP_AgentKey DESC, TMP_SubCode1 DESC, TMP_SubCode2 DESC, TMP_Duration DESC
		ELSE
			select	TOP 1 @Quota_Count=TMP_Count, 
					@Quota_AgentKey=TMP_AgentKey, @Quota_Type=TMP_Type, @Quota_ByRoom=TMP_ByRoom,
					@Quota_PRKey=TMP_Partner, @Quota_FilialKey=TMP_FilialKey, @Quota_CityDepartments=TMP_CityDepartments, 
					@Quota_Duration=TMP_Duration, @Quota_SubCode1=TMP_SubCode1, @Quota_SubCode2=TMP_SubCode2
			from	@Tbl_DQ 
			where	TMP_Count>0 and TMP_ReleaseIgnore=0
			order by TMP_ReleaseIgnore, TMP_Type, TMP_Partner DESC, TMP_AgentKey DESC, TMP_SubCode1 DESC, TMP_SubCode2 DESC, TMP_Duration DESC
	END
END

	--Проверим на стоп	
	--если есть два стопа, то это либо общий стоп, либо два отдельных стопа
	if @StopExist > 1
		and exists(select 1 from #StopSaleTemp where SST_State is not null and SST_Date between @DateBeg and @DateEnd and SST_Type=1)
		and exists(select 1 from #StopSaleTemp where SST_State is not null and SST_Date between @DateBeg and @DateEnd and SST_Type=2)
	BEGIN
		Set @Quota_CheckState = 2
		Set @Quota_CheckDate = @StopDate
		return
	END
	
	--если существуют стоп на один тип квот, а другой тип квот заведен неполностью или не заведен вовсе
	if (@StopExist > 0
			and
			(
				exists(select 1 from #StopSaleTemp where SST_Date between @DateBeg and @DateEnd and SST_Type=1 and SST_State is not null)
				and (select count (distinct TMP_Date) from #Tbl where TMP_QTID not in (select TMP_QTID from #Tbl,#StopSaleTemp where TMP_Date=SST_Date and SST_State=2 and SST_Type=1) and TMP_Type=1) > 0
				and (select count (distinct TMP_Date) from #Tbl where TMP_QTID not in (select TMP_QTID from #Tbl,#StopSaleTemp where TMP_Date=SST_Date and SST_State=2 and SST_Type=2) and TMP_Type=2) < @DaysCount
				or
				exists(select 1 from #StopSaleTemp where SST_Date between @DateBeg and @DateEnd and SST_Type=2 and SST_State is not null)
				and (select count (distinct TMP_Date) from #Tbl where TMP_QTID not in (select TMP_QTID from #Tbl,#StopSaleTemp where TMP_Date=SST_Date and SST_State=2 and SST_Type=2) and TMP_Type=2) > 0
				and (select count (distinct TMP_Date) from #Tbl where TMP_QTID not in (select TMP_QTID from #Tbl,#StopSaleTemp where TMP_Date=SST_Date and SST_State=2 and SST_Type=1) and TMP_Type=1) < @DaysCount
			)
		)
	BEGIN
		Set @Quota_CheckState = 2
		Set @Quota_CheckDate = @StopDate
		return
	END

	--если существуют два стопа и нет дней с незаведенными квотами
	if (@StopExist > 0 and
		exists(select 1 from #StopSaleTemp where SST_Date between @DateBeg and @DateEnd and SST_Type=1 and SST_State is not null) and
		exists(select 1 from #StopSaleTemp where SST_Date between @DateBeg and @DateEnd and SST_Type=2 and SST_State is not null) and
		((select COUNT(distinct SST_Date) from #StopSaleTemp where SST_Type=1) = @DaysCount) and
			((select COUNT(distinct SST_Date) from #StopSaleTemp where SST_Type=2) = @DaysCount))
	BEGIN
		Set @Quota_CheckState = 2
		Set @Quota_CheckDate = @StopDate
		return
	END

	--если есть стоп на commitment и закончился релиз-период на alotment, или наоборот...
	if (not exists(select 1 from #Tbl where TMP_Type=2 and TMP_Date = @DateBeg and dateadd(day, -1, GETDATE()) < (@DateBeg - ISNULL(TMP_Release, 0)))
		and
		(select count (distinct TMP_Date) from #Tbl where TMP_QTID not in (select TMP_QTID from #Tbl,#StopSaleTemp where TMP_Date=SST_Date and SST_State=2 and SST_Type=TMP_Type) and TMP_Type=1) < @DaysCount
		or
		not exists(select 1 from #Tbl where TMP_Type=1 and TMP_Date = @DateBeg and dateadd(day, -1, GETDATE()) < (@DateBeg - ISNULL(TMP_Release, 0)))
		and
		(select count (distinct TMP_Date) from #Tbl where TMP_QTID not in (select TMP_QTID from #Tbl,#StopSaleTemp where TMP_Date=SST_Date and SST_State=2 and SST_Type=TMP_Type) and TMP_Type=2) < @DaysCount)
	begin
		if exists(select 1 from #Tbl where TMP_Release is not null and TMP_Release!=0 and TMP_Date = @DateBeg AND dateadd(day, -1, GETDATE()) >= (@DateBeg - ISNULL(TMP_Release, 0)))
		begin
			set @Quota_CheckState = 3	-- наступил РЕЛИЗ-Период
			return
		end
	end
	
	--если существует стоп и на первый день нет квот
	If @StopExist > 0 and not exists (select 1 from #Tbl where TMP_Count > 0 and TMP_Date = @DateBeg)
	BEGIN
		Set @Quota_CheckState = 2						--Возвращаем "Внимание STOP"
		Set @Quota_CheckDate = @StopDate
		return
	END
	
	--Проверим на наличие квот
	if not exists (select 1 from #Tbl where TMP_Count > 0)
	begin
		Set @Quota_CheckState = 0
		return
	end

If @TypeOfResult=2 --(попытка проверить возможность постановки услуги на квоту)
BEGIN
	DECLARE @Places_Count int, @Rooms_Count int,		 --доступное количество мест/номеров в квотах
			@Places_Count_ReleaseIgnore int, @Rooms_Count_ReleaseIgnore int,		 --доступное количество мест/номеров в квотах
			@PlacesNeed_Count smallint,					-- количество мест, которых недостаточно для оформления услуги
			@PlacesNeed_Count_ReleaseIgnore smallint					-- количество мест, которых недостаточно для оформления услуги
	
	If exists (SELECT top 1 1 FROM @Tbl_DQ)
	BEGIN
		set @PlacesNeed_Count = 0
		set @PlacesNeed_Count_ReleaseIgnore = 0
		
		select @Places_Count = SUM(TMP_Count) from @Tbl_DQ where TMP_Count > 0 and TMP_ByRoom = 0 and TMP_ReleaseIgnore = 0
		select @Places_Count_ReleaseIgnore = SUM(TMP_Count) from @Tbl_DQ where TMP_Count > 0 and TMP_ByRoom = 0 and TMP_ReleaseIgnore = 1
		
		If (@SVKey in (3) or (@SVKey=8 and EXISTS(SELECT TOP 1 1 FROM [Service] WHERE SV_KEY=@SVKey AND SV_QUOTED=1)))
		begin
			select @Rooms_Count = SUM(TMP_Count) from @Tbl_DQ where TMP_Count > 0 and TMP_ByRoom = 1 and TMP_ReleaseIgnore = 0
			select @Rooms_Count_ReleaseIgnore = SUM(TMP_Count) from @Tbl_DQ where TMP_Count > 0 and TMP_ByRoom = 1 and TMP_ReleaseIgnore = 1
		end
		
		Set @Places_Count = ISNULL(@Places_Count,0)
		Set @Rooms_Count = ISNULL(@Rooms_Count,0)
		Set @Places_Count_ReleaseIgnore = ISNULL(@Places_Count_ReleaseIgnore,0)
		Set @Rooms_Count_ReleaseIgnore = ISNULL(@Rooms_Count_ReleaseIgnore,0)
		
		SET @StopExist = ISNULL(@StopExist, 0)
		
		--проверяем достаточно ли будет текущего кол-ва мест для бронирования, если нет устанавливаем статус бронирования под запрос
		declare @nPlaces smallint, @nRoomsService smallint
		If ((@SVKey in (3) OR (@SVKey=8 and EXISTS(SELECT TOP 1 1 FROM [Service] WHERE SV_KEY=@SVKey AND SV_QUOTED=1))) and @Rooms_Count > 0)
		BEGIN
			Set @nRoomsService = 1
			
			if (@SVKey = 3)
				exec GetServiceRoomsCount @Code, @SubCode1, @Pax, @nRoomsService output
			
			If @nRoomsService > @Rooms_Count
			begin
				Set @PlacesNeed_Count = @nRoomsService - @Rooms_Count
				Set @Quota_CheckState = 0
			end
			
			If @nRoomsService > @Rooms_Count_ReleaseIgnore
			begin
				Set @PlacesNeed_Count_ReleaseIgnore = @nRoomsService - @Rooms_Count_ReleaseIgnore
				Set @Quota_CheckState = 0
			end
		END
		ELSE
		begin
			If @Pax > @Places_Count
			begin
				Set @PlacesNeed_Count = @Pax - @Places_Count
				Set @Quota_CheckState = 0
			end 
			
			If @Pax > @Places_Count_ReleaseIgnore
			begin
				Set @PlacesNeed_Count_ReleaseIgnore = @Pax - @Places_Count_ReleaseIgnore
				Set @Quota_CheckState = 0
			end
		end
		
		-- проверим на релиз
		If @PlacesNeed_Count_ReleaseIgnore <= 0 --мест в квоте хватило
			Set @Quota_CheckState = 3						--Возвращаем "Release" (мест не достаточно, но наступил РЕЛИЗ-Период)"
		
		If @PlacesNeed_Count <= 0 --мест в квоте хватило
			Set @Quota_CheckState = 1						--Возвращаем "Ok (квоты есть)"
		else
			set @Quota_CheckInfo = @PlacesNeed_Count
	END
	else
	begin
		-- если выборка пустая
		Set @Quota_CheckState = 0
	end
END
GO

grant exec on [dbo].[CheckQuotaExist] to public
go
/*********************************************************************/
/* end sp_CheckQuotaExist.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DogListToQuotas.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogListToQuotas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogListToQuotas]
GO

CREATE PROCEDURE [dbo].[DogListToQuotas]
(
	--<VERSION>9.2.1</VERSION>
	--<DATA>20.02.2014</DATA>
	@DLKey int,
	@SetQuotaCheck bit = null,			--если передается этот признак, то по услуге проверяются актуальные квоты, и в случае не актуальности номер/место снимается с квоты целиком и пытается поставиться на квоту заново
										--остальные квоты занимаемые услугой не снимаются, остаются как есть
	@SetQuotaRLKey int = null,
	@SetQuotaRPKey int = null,
	@SetQuotaQPID int = null,			--передается только из руч.режима (только для одной даты!!!!!!)	
	@SetQuotaDateBeg datetime = null,
	@SetQuotaDateEnd datetime = null,
	@SetQuotaAgentKey int = null, 
	@SetQuotaType smallint = null,		--при переходе на 2008.1 в этот параметр передается отрицательное число (-1 Allotment, -2 Коммитемент)
	@SetQuotaByRoom bit = null, 
	@SetQuotaPartner int = null, 
	@SetQuotaDuration smallint = null,
	@SetQuotaSubCode1 int = null,
	@SetQuotaSubCode2 int = null,
	@SetQuotaFilialKey int = null, 
	@SetQuotaCityDepartments int = null,
	@SetQuotaDateFirst datetime = null,
	@SetOkIfRequest bit = 0, -- запуск из тригера T_UpdDogListQuota
	@OldSetToQuota bit = 0, -- запустить старый механизм посадки
	@ToSetQuotaDateFrom datetime = null,
	@ToSetQuotaDateTo datetime = null
) 
AS

--insert into Debug (db_n1, db_n2, db_n3) values (@DLKey, @SetQuotaType, 999)
declare @SVKey int, @Code int, @SubCode1 int, @PRKey int, @AgentKey int, @DgKey int,
		@TourDuration int, @FilialKey int, @CityDepartment int,
		@ServiceDateBeg datetime, @ServiceDateEnd datetime, @Pax smallint, @IsWait smallint,@SVQUOTED smallint,
		@SdStateOld int, @SdStateNew int, @nHIID int, @dgCode nvarchar(10), @dlName nvarchar(max), @Long smallint
		
declare @sOldValue nvarchar(max), @sNewValue nvarchar(max)

-- если включена настройка то отрабатывает новый метод посадки и рассадки в квоту
if exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota' and SS_ParmValue = 1) and @OldSetToQuota = 0
begin
	-- запоминаем старый статус услуги
	select @SdStateOld = max(SD_State) from ServiceByDate with(nolock) where SD_DLKey = @DLKey


	exec WcfSetServiceToQuota @DLKey, @SetQuotaType, @ToSetQuotaDateFrom, @ToSetQuotaDateTo
	
	-- находим новый статус
	select @SdStateNew = max(SD_State) from ServiceByDate with(nolock) where SD_DLKey = @DLKey

	-- устанавливаем новый статус
	Declare @dlControlNew int
	exec SetServiceStatusOk @DLKey, @dlControlNew output

	-- запись в историю, только если статус услуги поменялся
	if exists(select top 1 1 from SystemSettings where SS_ParmName like 'SYSServiceStatusToHistory' and SS_ParmValue = '1') and @SdStateOld != @SdStateNew
	begin
		IF ISNULL(@SdStateOld, 0) = 0
			SET @sOldValue = ''
		ELSE IF @SdStateOld = 1
			SET @sOldValue = 'Allotment'
		ELSE IF @SdStateOld = 2
			SET @sOldValue = 'Commitment'
		ELSE IF @SdStateOld = 3
			SET @sOldValue = 'Confirmed'
		ELSE IF @SdStateOld = 4
			SET @sOldValue = 'Wait'

		IF ISNULL(@SdStateNew, 0) = 0
			SET @sNewValue = ''
		ELSE IF @SdStateNew = 1
			SET @sNewValue = 'Allotment'
		ELSE IF @SdStateNew = 2
			SET @sNewValue = 'Commitment'
		ELSE IF @SdStateNew = 3
			SET @sNewValue = 'Confirmed'
		ELSE IF @SdStateNew = 4
			SET @sNewValue = 'Wait'

		EXEC @nHIID = dbo.InsHistory @dgCode, @DgKey, 19, '', 'UPD', @dlName, '', 0, ''
		EXECUTE dbo.InsertHistoryDetail @nHIID, 19001, @sOldValue, @sNewValue, @SdStateOld, @SdStateNew, '', '', 0
	end

	return;
end

SELECT	@SVKey=DL_SVKey, @Code=DL_Code, @SubCode1=DL_SubCode1, @PRKey=DL_PartnerKey, 
		@ServiceDateBeg=DL_DateBeg, @ServiceDateEnd=DL_DateEnd, @Pax=DL_NMen,
		@AgentKey=DG_PartnerKey, @TourDuration=DG_NDay, @FilialKey=DG_FilialKey, @CityDepartment=DG_CTDepartureKey, @IsWait=ISNULL(DL_Wait,0),
		@DgKey = DL_DGKEY,
		@dgCode = DG_CODE,
		@dlName = DL_NAME
FROM	DogovorList join Dogovor on DL_DGKey = DG_Key
WHERE	DL_Key = @DLKey

-- сохраним старое значение квотируемости
select @SdStateOld = MAX(SD_State) from ServiceByDate with(nolock) where SD_DLKey = @DLKey

if @IsWait=1 and (@SetQuotaType in (1,2) or @SetQuotaType is null)  --Установлен признак "Не снимать квоту при бронировании". На квоту не ставим
BEGIN
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null	-- изменение
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0 and @SVKey = 3
	begin
		exec SetStatusInRoom @dlkey
	end
	return 0
END

SELECT @SVQUOTED=isnull(SV_Quoted,0) from [service] with(nolock) where sv_key=@SVKEY
if @SVQUOTED=0
BEGIN
	UPDATE ServiceByDate SET SD_State=3 WHERE SD_DLKey=@DLKey	
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0 and @SVKey = 3
	begin
		exec SetStatusInRoom @dlkey
	end
	return 0
END

-- ДОБАВЛЕНА НАСТРОЙКА ЗАПРЕЩАЮЩАЯ СНЯТИЕ КВОТЫ ДЛЯ УСЛУГИ, 
-- ТАК КАК В КВОТАХ НЕТ РЕАЛЬНОЙ ИНФОРМАЦИИ, А ТОЛЬКО ПРИЗНАК ИХ НАЛИЧИЯ (ПЕРЕДАЕТСЯ ИЗ INTERLOOK)
IF (@SetQuotaType in (1,2) or @SetQuotaType is null) and  EXISTS (SELECT 1 FROM dbo.SystemSettings WHERE SS_ParmName='IL_SyncILPartners' and SS_ParmValue LIKE '%/' + CAST(@PRKey as varchar(20)) + '/%')
Begin
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0 and @SVKey = 3
	begin
		exec SetStatusInRoom @dlkey
	end
	return 0
End

-- проверим если это доп место в комнате, то ее нельзя посадить в квоты, сажаем внеквоты и эта квота за человека
if exists(select 1 from systemsettings where ss_parmname='SYSSetQuotaForAddPlaces' and SS_ParmValue=1)
begin
	if ( exists (select top 1 1 from ServiceByDate with(nolock) join RoomPlaces with(nolock) on SD_RPID = RP_ID where SD_DLKey = @DLKey and RP_Type = 1) and (@SetQuotaByRoom = 0))
	begin
		set @SetQuotaType = 3
	end
end

declare @Q_Count smallint, @Q_AgentKey int, @Q_Type smallint, @Q_ByRoom bit, 
		@Q_PRKey int, @Q_FilialKey int, @Q_CityDepartments int, @Q_Duration smallint, @Q_DateBeg datetime, @Q_DateEnd datetime, @Q_DateFirst datetime, @Q_SubCode1 int, @Q_SubCode2 int,
		@Query nvarchar(max), @SubQuery varchar(1500), @Current int, @CurrentString varchar(50), @QTCount_Need smallint, @n smallint, @Result_Exist bit, @nTemp smallint, @Quota_CheckState smallint, @dTemp datetime

--karimbaeva 19-04-2012  по умолчанию если не хватает квот на всех туристов, то ставим их всех на запрос, если установлена настройка 
-- SYSSetQuotaToTourist - 1 - ставим туристов на запрос, 0- снимаем квоты на кого хватает, остальных ставим на запрос
if not exists(select 1 from systemsettings where ss_parmname='SYSSetQuotaToTourist' and SS_ParmValue=0)
begin
	If exists (SELECT top 1 1 FROM ServiceByDate with(nolock) WHERE SD_DLKey=@DLKey and SD_State is null)
	BEGIN
	declare @QT_ByRoom_1 bit
	create table #DlKeys_1
	(
		dlKey int
	)

	insert into #DLKeys_1
		select dl_key 
		from dogovorlist with(nolock)
		where dl_dgkey in (
							select dl_dgkey 
							from dogovorlist with(nolock) 
							where dl_key = @DLKey
						   )
		and dl_svkey = 3
		
		SELECT @QT_ByRoom_1=QT_ByRoom FROM Quotas with(nolock),QuotaDetails with(nolock),QuotaParts with(nolock) WHERE QD_QTID=QT_ID and QD_ID=QP_QDID 
		and QP_ID = (select top 1 SD_QPID
					from ServiceByDate with(nolock) join RoomPlaces with(nolock) on SD_RLID = RP_RLID  
					where RP_Type = 0 and sd_dlkey in (select dlKey from #DlKeys_1) and SD_RLID = (select TOP 1 SD_RLID from ServiceByDate with(nolock) where sd_dlkey=@DlKey))
		
		
		if (@QT_ByRoom_1=0 or @QT_ByRoom_1 is null)
		begin	
		SET @Q_DateBeg=@ServiceDateBeg
		SET @Q_DateEnd=@ServiceDateEnd
		SET @Q_DateFirst=@ServiceDateBeg
	
		EXEC dbo.[CheckQuotaExist] @SVKey, @Code, @SubCode1, @Q_DateBeg,
				@Q_DateEnd, @Q_DateFirst, @PRKey, @AgentKey, @TourDuration, 
				@FilialKey,	@CityDepartment, 2, @Pax,@IsWait, 
				@Quota_CheckState output, @dTemp output, @nTemp output,
				@Q_Count output, @Q_AgentKey output, @Q_Type output, @Q_ByRoom output, @Q_PRKey output, 
				@Q_FilialKey output, @Q_CityDepartments output,	@Q_Duration output, @Q_SubCode1 output, @Q_SubCode2 output
						
		if @Quota_CheckState = 0	
		begin
			UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
			-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
			if @SetQuotaByRoom = 0 and @SVKey = 3
			begin
				exec SetStatusInRoom @dlkey
			end
			return 0
		end	
		end	
END
end 

--Если идет полная постановка услуги на квоту (@SetQuotaType is null) обычно после бронирования
--Или прошло удаление какой-то квоты и сейчас требуется освободить эту квоту и занять другую
--То требуется найти оптимально подходящую квоту и ее использовать

If @SetQuotaType is null or @SetQuotaType<0 --! @SetQuotaType<0 <--при переходе на 2008.1
BEGIN
	IF @SetQuotaCheck=1 
	begin
		UPDATE ServiceByDate SET SD_State=null, SD_QPID=null where SD_DLKey=@DLKey
			and SD_RPID in (SELECT DISTINCT SD_RPID FROM QuotaDetails with(nolock),QuotaParts with(nolock),ServiceByDate with(nolock)
							WHERE SD_QPID=QP_ID and QP_QDID=QD_ID and QD_IsDeleted=1 and SD_DLKey=@DLKey)
	end
	ELSE
	BEGIN
		IF @SetQuotaRLKey is not null
			UPDATE ServiceByDate SET SD_State=null, SD_QPID=null where SD_DLKey=@DLKey and SD_RLID=@SetQuotaRLKey
		ELSE IF @SetQuotaRPKey is not null
			UPDATE ServiceByDate SET SD_State=null, SD_QPID=null where SD_DLKey=@DLKey and SD_RPID=@SetQuotaRPKey
		ELSE
			UPDATE ServiceByDate SET SD_State=null, SD_QPID=null where SD_DLKey=@DLKey
	END
	SET @Q_DateBeg=@ServiceDateBeg
	SET @Q_DateEnd=@ServiceDateEnd
	SET @Q_DateFirst=@ServiceDateBeg
	IF @SetQuotaType=-1
		SET @Q_Type=1
	ELSE IF @SetQuotaType=-2
		SET @Q_Type=2
	
	EXEC dbo.[CheckQuotaExist] @SVKey, @Code, @SubCode1, @Q_DateBeg,
						@Q_DateEnd, @Q_DateFirst, @PRKey, @AgentKey, @TourDuration, 
						@FilialKey,	@CityDepartment, 1, @Pax, @IsWait,
						@nTemp output, @dTemp output, @nTemp output,
						@Q_Count output, @Q_AgentKey output, @Q_Type output, @Q_ByRoom output, @Q_PRKey output, 
						@Q_FilialKey output, @Q_CityDepartments output,	@Q_Duration output, @Q_SubCode1 output, @Q_SubCode2 output
END
ELSE
BEGIN
	IF @SetQuotaType=4 or @SetQuotaType=3  --если новый статус Wait-list или Ok(вне квоты), то меняем статус и выходим из хранимки
		Set @Q_Type=@SetQuotaType
	Else If @SetQuotaQPID is not null
	BEGIN
		If @SetQuotaType is not null and @SetQuotaType>=0
			Set @Q_Type=@SetQuotaType
		Else
			Select @Q_Type=QD_Type from QuotaDetails with(nolock),QuotaParts with(nolock) Where QP_QDID=QD_ID and QP_ID=@SetQuotaQPID
	END
	Else
		Set @Q_Type=null		
	--@SetQuotaQPID это конкретная квота, ее заполнение возможно только из режима ручного постановки услуги на квоту
	IF @SetQuotaByRoom=1 and @SVKey=3
	BEGIN
		if @SetQuotaRLKey is null
		begin
			UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=@SetQuotaQPID where SD_DLKey=@DLKey and SD_Date between @SetQuotaDateBeg and @SetQuotaDateEnd
		end
		else
		begin
			UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=@SetQuotaQPID where SD_DLKey=@DLKey and SD_RLID=@SetQuotaRLKey and SD_Date between @SetQuotaDateBeg and @SetQuotaDateEnd
		end
	END
	ELSE
	BEGIN
		if @SetQuotaRPKey is null
		begin
			UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=@SetQuotaQPID where SD_DLKey=@DLKey and SD_Date between @SetQuotaDateBeg and @SetQuotaDateEnd
		end
		else
		begin
			UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=@SetQuotaQPID where SD_DLKey=@DLKey and SD_RPID=@SetQuotaRPKey and SD_Date between @SetQuotaDateBeg and @SetQuotaDateEnd
		end
	END
	IF @SetQuotaType=4 or @SetQuotaType=3 or @SetQuotaQPID is not null --собственно выход (либо не надо ставить на квоту либо квота конкретная)
	begin
		-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
		if @SetQuotaByRoom = 0 and @SVKey = 3
		begin
			exec SetStatusInRoom @dlkey
		end
		-- запускаем хранимку на установку статуса путевки
		--exec SetReservationStatus @DgKey
		return 0
	end

	--	select * from ServiceByDate where SD_DLKey=202618 and SD_RLID=740
	SET @Q_AgentKey=@SetQuotaAgentKey
	SET @Q_Type=@SetQuotaType
	SET @Q_ByRoom=@SetQuotaByRoom
	SET @Q_PRKey=@SetQuotaPartner
	SET @Q_FilialKey=@SetQuotaFilialKey
	SET @Q_CityDepartments=@SetQuotaCityDepartments
	SET @Q_Duration=@SetQuotaDuration
	SET @Q_SubCode1=@SetQuotaSubCode1
	SET @Q_SubCode2=@SetQuotaSubCode2
	SET @Q_DateBeg=@SetQuotaDateBeg
	SET @Q_DateEnd=@SetQuotaDateEnd
	SET @Q_DateFirst=ISNULL(@SetQuotaDateFirst,@Q_DateBeg)
	SET @Result_Exist=0	
END

set @n=0

If not exists (SELECT top 1 1 FROM ServiceByDate with(nolock) WHERE SD_DLKey=@DLKey and SD_State is null)
	print 'WARNING_DogListToQuotas_1'
If @Q_Count is null
	print 'WARNING_DogListToQuotas_2'
If @Result_Exist > 0
	print 'WARNING_DogListToQuotas_3'

CREATE table #StopSales (SS_QDID int,SS_QOID int,SS_DATE dateTime)
CREATE table #Quotas1(QP_ID int,QD_QTID int,QD_ID int,QO_ID int,QD_Release smallint,QP_Durations varchar(20),
	QD_Date DateTime,QP_IsNotCheckIn bit,QP_CheckInPlaces smallint,QP_CheckInPlacesBusy smallint,
	QP_Places smallint,QP_Busy smallint,QT_ID int,QO_QTID int,QO_SVKey int,QO_Code int,QO_SubCode1 int,QO_SubCode2 int)

DECLARE @DATETEMP datetime
SET @DATETEMP = GetDate()
-- Разрешим посадить в квоту с релиз периодом 0 текущим числом
set @DATETEMP = DATEADD(day, -1, @DATETEMP)

if exists (select top 1 1 from systemsettings where SS_ParmName='SYSCheckQuotaRelease' and SS_ParmValue=1) OR exists (select top 1 1 from systemsettings where SS_ParmName='SYSAddQuotaPastPermit' and SS_ParmValue=1 and @Q_DateFirst < @DATETEMP)
	SET @DATETEMP='10-JAN-1900'

WHILE (exists(SELECT top 1 1 FROM ServiceByDate with(nolock) WHERE SD_DLKey=@DLKey and SD_State is null) and @n<5 and (@Q_Count is not null or @Result_Exist=0))
BEGIN
	set @n=@n+1

	SET @Long=DATEDIFF(DAY,@Q_DateBeg,@Q_DateEnd)+1
	
	DECLARE @n1 smallint, @n2 smallint, @prev bit, @durations_prev varchar(25), @release_prev smallint, @QP_ID int, @SK_Current int, @Temp smallint, @Error bit
	DECLARE @ServiceKeys Table (SK_ID int identity(1,1), SK_Key int, SK_QPID int, SK_Date smalldatetime)

	IF (@SetQuotaType is null or @SetQuotaType < 0) --! @SetQuotaType<0 <--при переходе на 2008.1
	BEGIN
		IF (@Q_ByRoom = 1)
			INSERT INTO @ServiceKeys (SK_Key,SK_Date) SELECT DISTINCT SD_RLID, SD_Date FROM ServiceByDate with(nolock) WHERE SD_DLKey=@DLKey and SD_State is null
		ELSE
			INSERT INTO @ServiceKeys (SK_Key,SK_Date) SELECT DISTINCT SD_RPID, SD_Date FROM ServiceByDate with(nolock) WHERE SD_DLKey=@DLKey and SD_State is null
		END
		ELSE IF @Q_ByRoom=1
		BEGIN
			INSERT INTO @ServiceKeys (SK_Key,SK_Date) SELECT DISTINCT SD_RLID, SD_Date FROM ServiceByDate with(nolock) WHERE SD_DLKey=@DLKey and SD_RLID=@SetQuotaRLKey and SD_State is null
		END
		ELSE IF @Q_ByRoom=0
		BEGIN
			INSERT INTO @ServiceKeys (SK_Key,SK_Date) SELECT DISTINCT SD_RPID, SD_Date FROM ServiceByDate with(nolock) WHERE SD_DLKey=@DLKey and SD_RPID=@SetQuotaRPKey and SD_State is null
		END

		SET @Error=0
		SELECT @SK_Current=MIN(SK_Key) FROM @ServiceKeys WHERE SK_QPID is null
		
		Set @prev = null
		
		WHILE @SK_Current is not null and @Error=0
		BEGIN
			SET @n1=1
			
			WHILE @n1<=@Long and @Error=0
			BEGIN
				SET @QP_ID=null
				SET @n2=0
				
				WHILE (@QP_ID is null) and @n2<2
				BEGIN
					truncate table #Quotas1
					truncate table #StopSales
					
					insert into #Quotas1 (QP_ID,QD_QTID,QD_ID,QO_ID,QD_Release,QP_Durations,QD_Date,QP_IsNotCheckIn,QP_CheckInPlaces,QP_CheckInPlacesBusy,QP_Places,QP_Busy,QT_ID,QO_QTID,QO_SVKey,QO_Code,QO_SubCode1,QO_SubCode2)
						select QP_ID,QD_QTID,QD_ID,QO_ID,QD_Release,QP_Durations,QD_Date,QP_IsNotCheckIn,QP_CheckInPlaces,QP_CheckInPlacesBusy,QP_Places,QP_Busy,QT_ID,QO_QTID,QO_SVKey,QO_Code,QO_SubCode1,QO_SubCode2
						FROM QuotaParts as QP1 with(nolock)
						inner join QuotaDetails as QD1 with(nolock) on QP_QDID=QD_ID and QD_Date = QP_Date
						inner join Quotas with(nolock) on QT_ID=QD_QTID
						inner join QuotaObjects with(nolock) on QO_QTID=QT_ID
						WHERE QD_Type=@Q_Type
						and QT_ByRoom=@Q_ByRoom
						and QD_IsDeleted is null
						and QP_IsDeleted is null
						and QO_SVKey=@SVKey
						and QO_Code=@Code
						and QO_SubCode1=@Q_SubCode1
						and QO_SubCode2=CASE WHEN @SVKey=3 THEN @Q_SubCode2 ELSE QO_SubCode2 END
						and ISNULL(QP_FilialKey, -100) = ISNULL(@Q_FilialKey, -100)
						and ISNULL(QP_CityDepartments, -100) = ISNULL(@Q_CityDepartments, -100)
						and ISNULL(QP_AgentKey, -100) = ISNULL(@Q_AgentKey, -100)
						and ISNULL(QT_PRKey, -100) = ISNULL(@Q_PRKey, -100)
						and QP_Durations = CASE WHEN @Q_Duration=0 THEN '' ELSE QP_Durations END
						and QD_Date between @Q_DateBeg and DATEADD(DAY,@Long,@Q_DateBeg)
						and (QP_Places-QP_Busy) > 0
						and (isnull(QP_Durations, '') = ''
						or (isnull(QP_Durations, '') != '' and (QP_IsNotCheckIn = 1 or QP_CheckInPlaces - QP_CheckInPlacesBusy > 0))
						or (isnull(QP_Durations, '') != '' and (QP_IsNotCheckIn = 0 or QP_Places - QP_Busy > 0))
						or (isnull(QP_Durations, '') != '' and QD_Date = @Q_DateFirst))
						and (QD1.QD_Date > @DATETEMP + ISNULL(QD1.QD_Release,-1) OR (QD1.QD_Date < getdate() - 1))
						and ((QP_IsNotCheckIn = 0) or (QP_IsNotCheckIn = 1 and exists (select top 1 1 from QuotaDetails as tblQD with(nolock)
																							inner join QuotaParts as tblQP with(nolock)
																							on tblQP.QP_QDID = tblQD.QD_ID and tblQP.QP_Date = tblQD.QD_Date
																							where tblQP.QP_IsNotCheckIn = 0
																							and tblQD.QD_Date=@Q_DateFirst
																							and tblQD.QD_QTID=QD1.QD_QTID)))
						and QP_ID not in
						(SELECT QP_ID FROM QuotaParts QP2 with(nolock)
								inner join QuotaDetails QD2 with(nolock) on QP_QDID=QD_ID and QD_Date=QP_Date
								inner join Quotas QT2 with(nolock) on QT_ID=QD_QTID
								WHERE QD2.QD_Type=@Q_Type
								and QT2.QT_ByRoom=@Q_ByRoom
								and QD2.QD_IsDeleted is null
								and QP2.QP_IsDeleted is null
								and ISNULL(QP2.QP_FilialKey, -100) = ISNULL(@Q_FilialKey, -100)
								and ISNULL(QP2.QP_CityDepartments, -100) = ISNULL(@Q_CityDepartments, -100)
								and ISNULL(QP2.QP_AgentKey, -100) = ISNULL(@Q_AgentKey, -100)
								and ISNULL(QT2.QT_PRKey, -100) = ISNULL(@Q_PRKey, -100)
								and ((@Q_Duration=0 and QP2.QP_Durations = '') or (@Q_Duration <> 0 and QP2.QP_ID in (Select QL_QPID From QuotaLimitations with(nolock) Where QL_Duration = @Q_Duration)))
								and QD2.QD_Date=@Q_DateFirst
								and (QP2.QP_IsNotCheckIn=1 or QP2.QP_CheckInPlaces-QP2.QP_CheckInPlacesBusy <= 0)
								and QO_QTID=QT2.QT_ID
								and ISNULL(QD2.QD_Release,0)=ISNULL(QD1.QD_Release,0)
								and QP2.QP_Durations COLLATE DATABASE_DEFAULT = QP1.QP_Durations COLLATE DATABASE_DEFAULT)

						if (@Q_Duration<>0)
						begin
							delete from #Quotas1 where QP_ID not in (Select QL_QPID From QuotaLimitations with(nolock) Where QL_Duration=@Q_Duration)
						end

						insert into #StopSales SELECT SS_QDID, SS_QOID, SS_Date FROM StopSales with(nolock) inner join #Quotas1 on SS_QOID=#Quotas1.QO_ID and SS_QDID=#Quotas1.QD_ID WHERE isnull(SS_IsDeleted, 0) = 0

						delete from #Quotas1 where exists (SELECT top 1 1 FROM #StopSales WHERE SS_QDID=QD_ID and SS_QOID=QO_ID and SS_Date=QD_Date)
					
					IF @prev=1
					begin
						SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release
						FROM #Quotas1 AS Q1
						WHERE QD_Date=DATEADD(DAY,@n1-1,@Q_DateBeg) and QP_Durations=@durations_prev and QD_Release=@release_prev
						ORDER BY ISNULL(QD_Release,0) DESC, (select count(distinct QD_QTID) from QuotaDetails as QDP with(nolock)
								join QuotaParts as QPP with(nolock) on QDP.QD_ID = QPP.QP_QDID and QDP.QD_Date = QPP.QP_Date
								where exists (select top 1 1 from @ServiceKeys as SKP
												where SKP.SK_QPID = QPP.QP_ID)
								and QDP.QD_QTID = Q1.QD_QTID) DESC
					end
					ELSE
					begin
						SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release
						FROM #Quotas1 as Q1
						WHERE QD_Date=DATEADD(DAY,@n1-1,@Q_DateBeg)
						ORDER BY ISNULL(QD_Release,0) DESC, (select count(distinct QD_QTID) from QuotaDetails as QDP with(nolock)
								join QuotaParts as QPP on QDP.QD_ID = QPP.QP_QDID and QDP.QD_Date = QPP.QP_Date
								where exists (select top 1 1 from @ServiceKeys as SKP
												where SKP.SK_QPID = QPP.QP_ID)
								and QDP.QD_QTID = Q1.QD_QTID) DESC
					end
					
					SET @n2=@n2+1
					
					IF @QP_ID is null
					BEGIN
						SET @prev=1
					END
					ELSE
						UPDATE @ServiceKeys SET SK_QPID=@QP_ID WHERE SK_Key=@SK_Current and SK_Date=DATEADD(DAY,@n1-1,@Q_DateBeg)
					END
					
					If @QP_ID is null
						SET @Error=1
					
					SET @n1=@n1+1
				END

				IF @Error=0
				begin
					IF @Q_ByRoom = 1
					begin
						if exists(select 1 from systemsettings where ss_parmname='SYSSetQuotaToTourist' and SS_ParmValue=0)
						begin
							UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=(SELECT MIN(SK_QPID) FROM @ServiceKeys join QuotaParts on SK_QPID=QP_ID WHERE SK_Date=SD_Date and SK_Key=SD_RLID and QP_Places-QP_Busy>0)
								WHERE SD_DLKey=@DLKey and SD_RLID=@SK_Current and SD_State is null and SD_Date between @ServiceDateBeg and @ServiceDateEnd
						end
						else
						begin
							UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=(SELECT MIN(SK_QPID) FROM @ServiceKeys WHERE SK_Date=SD_Date and SK_Key=SD_RLID)
								WHERE SD_DLKey=@DLKey and SD_RLID=@SK_Current and SD_State is null and SD_Date between @ServiceDateBeg and @ServiceDateEnd
						end
					end
					ELSE
					begin
						if exists(select 1 from systemsettings where ss_parmname='SYSSetQuotaToTourist' and SS_ParmValue=0)
						begin
							UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=(SELECT MIN(SK_QPID) FROM @ServiceKeys join QuotaParts on SK_QPID=QP_ID WHERE SK_Date=SD_Date and SK_Key=SD_RPID and QP_Places-QP_Busy>0)
								WHERE SD_DLKey=@DLKey and SD_RPID=@SK_Current and SD_State is null and SD_Date between @ServiceDateBeg and @ServiceDateEnd
						end
						else
						begin
							UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=(SELECT MIN(SK_QPID) FROM @ServiceKeys WHERE SK_Date=SD_Date and SK_Key=SD_RPID)
								WHERE SD_DLKey=@DLKey and SD_RPID=@SK_Current and SD_State is null and SD_Date between @ServiceDateBeg and @ServiceDateEnd
						end
					end
				end
				
				SET @SK_Current=null
				SELECT @SK_Current=MIN(SK_Key) FROM @ServiceKeys WHERE SK_QPID is null
			END

	declare @QTByRoom bit
	
	SELECT top 1 @QTByRoom = QT_ByRoom 
		FROM Quotas with(nolock)
		join QuotaObjects with(nolock) on QT_ID = QO_QTID
		where QO_Code = @Code
		and QO_SVKey = 3
	
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0 and @SVKey = 3 and @QTByRoom = 0
	begin
		exec SetStatusInRoom @dlkey
	end
	
	--если @SetQuotaType is null -значит это начальная постановка услги на квоту и ее надо делать столько раз
	--сколько номеров или людей в услуге.
	If @SetQuotaType is null or @SetQuotaType<0 --! @SetQuotaType<0 <--при переходе на 2008.1
	BEGIN
		If exists (SELECT top 1 1 FROM ServiceByDate with(nolock) WHERE SD_DLKey=@DLKey and SD_State is null)
		BEGIN
			EXEC dbo.[CheckQuotaExist] @SVKey, @Code, @SubCode1, @Q_DateBeg,
				@Q_DateEnd, @Q_DateFirst, @PRKey, @AgentKey, @TourDuration, 
				@FilialKey,	@CityDepartment, 1, @Pax,@IsWait, 
				@nTemp output, @dTemp output, @nTemp output,
				@Q_Count output, @Q_AgentKey output, @Q_Type output, @Q_ByRoom output, @Q_PRKey output, 
				@Q_FilialKey output, @Q_CityDepartments output,	@Q_Duration output, @Q_SubCode1 output, @Q_SubCode2 output
		END
	END	
	ELSE --а если @SetQuotaType is not null -значит ставим на услугу конкретное место, а раз так то оно должно встать на квоту должно было с первого раза, устанавливаем бит выхода.	
		SET @Result_Exist=1		--бит выхода
END

--все квоты уже заняты (такие услуги попали в условие QP_Places-QP_Busy>0), для оставшихся проставляем статус запрос
UPDATE ServiceByDate SET SD_State = 4 where SD_DLKey=@DLKey and SD_QPID is null

if exists(select top 1 1 from ServiceByDate with(nolock) where SD_DLKey=@DLKey and SD_State is null) and @SVKey = 3
begin
	exec SetStatusInRoom @dlkey
end

drop table #StopSales
drop table #Quotas1

UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null

-- сохраним новое значение квотируемости
select @SdStateNew = MAX(SD_State) from ServiceByDate with(nolock) where SD_DLKey = @DLKey

-- запись в историю
if exists(select top 1 1 from SystemSettings where SS_ParmName like 'SYSServiceStatusToHistory' and SS_ParmValue = '1')
begin
	IF ISNULL(@SdStateOld, 0) = 0
		SET @sOldValue = ''
	ELSE IF @SdStateOld = 1
		SET @sOldValue = 'Allotment'
	ELSE IF @SdStateOld = 2
		SET @sOldValue = 'Commitment'
	ELSE IF @SdStateOld = 3
		SET @sOldValue = 'Confirmed'
	ELSE IF @SdStateOld = 4
		SET @sOldValue = 'Wait'

	IF ISNULL(@SdStateNew, 0) = 0
		SET @sNewValue = ''
	ELSE IF @SdStateNew = 1
		SET @sNewValue = 'Allotment'
	ELSE IF @SdStateNew = 2
		SET @sNewValue = 'Commitment'
	ELSE IF @SdStateNew = 3
		SET @sNewValue = 'Confirmed'
	ELSE IF @SdStateNew = 4
		SET @sNewValue = 'Wait'

	EXEC @nHIID = dbo.InsHistory @dgCode, @DgKey, 19, '', 'UPD', @dlName, '', 0, ''
	EXECUTE dbo.InsertHistoryDetail @nHIID, 19001, @sOldValue, @sNewValue, @SdStateOld, @SdStateNew, '', '', 0
end

-- 2012-10-12 tkachuk, task 8473 - меняем статус для услуг, привязанных к изменившимся квотам
DECLARE @dlControl int
EXEC dbo.SetServiceStatusOk @DlKey,@dlControl
GO

GRANT EXEC ON [dbo].[DogListToQuotas] TO PUBLIC
GO
/*********************************************************************/
/* end sp_DogListToQuotas.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetQuotaLoadListData_N.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetQuotaLoadListData_N]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetQuotaLoadListData_N]
GO


CREATE procedure [dbo].[GetQuotaLoadListData_N]
(
--<VERSION>2009.2.29</VERSION>
--<DATE>2014-02-14</DATE>
@QT_ID int=null,
@Service_SVKey int=null,
@Service_Code int=null,
@DateStart smalldatetime = null,
@DaysCount int=null,			 -- для режима 10-для наличия мест - в этом поле передается продолжительность услуги

@nShowQuotaTypes smallint =null,  -- показывать квоты типа (0 - все, 1 - allotment, 2 - commitment)
@bShowCommonInfo bit =null,  -- показывать (1-общую информацию по квоте, 0-информацию по распределению квоты)
@bShowAgencyInfo bit =null,   -- показывать информацию об агентских квотах
@AgentKey int =null,
@bFreeSale bit =null,
@DLKey int =null,
@ResultType smallint=null,		--варианты отображения (0,null-общее, 10-для наличия мест(из оформления))
@TourDurations  smallint=null,
@DateStart2 smalldatetime = null,
@DateStart3 smalldatetime = null,
@bShowByCheckIn bit =null,
@bCommonRelease bit =null,
@bShowCommonRequest bit = null,   --отображение услуг по запросу одной строкой
@nGridFilter int = 0              -- фильтр в зависимости от экрана / 3-английский вариант экранов
)
as 

set transaction isolation level read uncommitted

DECLARE @DateEnd smalldatetime, @Service_PRKey int, @QT_IDLocal int, @Result_From smallint, @Result_To smallint, @ServiceLong smallint, @DurationLocal smallint, @ByRoom int
--@Result
--11 - общее кол-во мест (строка 8000)
--12 - кол-во свободных мест (строка 8000)
--13 - кол-во занятых мест (строка 8000)
--21 - кол-во свободных мест (smallint)
--22 - % Stop-Sale (smallint)
--23 - возможен ли заезд (smallint)
if @ResultType is null or @ResultType not in (10)
	Set @DateEnd = DATEADD(DAY, @DaysCount-1, @DateStart)
Else --для наличия мест(из оформления)
BEGIN
	Set @ServiceLong=@DaysCount
	Set @DateEnd = DATEADD(DAY,ISNULL(@DaysCount,1)-1,@DateStart3)
	Set @DaysCount=DATEDIFF(DAY,@DateStart,@DateEnd)+1

	if exists (select 1 from dbo.Service(nolock) where SV_Key=@Service_SVKey and SV_IsDuration=1)
		set @DurationLocal=@ServiceLong
	Else
		set @DurationLocal=@TourDurations
END

CREATE TABLE #StopSaleTemp
(
SST_QDID int, SST_QO_Count smallint, SST_QO_CountWithStop smallint, SST_Comment varchar(255)
)

CREATE CLUSTERED INDEX idx_StopSaleTemp
ON #StopSaleTemp(SST_QDID ASC)

INSERT INTO #StopSaleTemp exec dbo.GetTableQuotaDetails	@DLKey, null, @DateStart, @DaysCount, null, null, @Service_SVKey, @Service_Code, null, null, 1

--SELECT * FROM #StopSaleTemp

CREATE TABLE #QuotaLoadList(QL_ID int identity(1,1),
QL_QTID int, QL_QOID int, QL_PRKey int, QL_SubCode1 int, QL_SubCode2 int, QL_PartnerName nvarchar(100) collate Cyrillic_General_CI_AS, QL_Description nvarchar(255) collate Cyrillic_General_CI_AS, 
QL_dataType smallint, QL_Type smallint, QL_TypeQuota smallint, QL_Release nvarchar(max), QL_Durations nvarchar(20) collate Cyrillic_General_CI_AS, QL_FilialKey int, 
QL_CityDepartments int, QL_AgentKey int, QL_CustomerInfo nvarchar(150) collate Cyrillic_General_CI_AS, QL_DateCheckinMin smalldatetime,
QL_ByRoom int)

DECLARE @n int, @str varchar(8000)
if (@ResultType is null) or (@ResultType <> 10)
BEGIN
	set @n=1
	WHILE @n <= @DaysCount
	BEGIN
		set @str = 'ALTER TABLE #QuotaLoadList ADD QL_' + CAST(@n as varchar(3)) + ' varchar(8000)'
		exec (@str)
		set @n = @n + 1
	END
END
ELSE
BEGIN
	--для наличия мест(из оформления)
	set @n=1
	WHILE @n <= @DaysCount
	BEGIN
		set @str = 'ALTER TABLE #QuotaLoadList ADD QL_' + CAST(@n as varchar(3)) + ' varchar(8000)'--' smallint'
		exec (@str)
		set @n = @n + 1
	END
END



Declare @userKey int
Declare @actionsKeys table(actionKey int)
Declare @ShowAllDurations bit

Set @userKey=dbo.GetUserId()

insert into @actionsKeys exec GetEndbledActions @userKey

-- Проверяем, имеет ли текущий пользователь права на просмотр квот со всеми продолжительностями

If exists(select top 1 1 from @actionsKeys where actionKey=148)
	Set @ShowAllDurations = 1
Else
	Set @ShowAllDurations = 0



if @bShowCommonInfo = 1
BEGIN
	insert into #QuotaLoadList 
	(QL_QTID, QL_Type, QL_Release, QL_dataType, QL_DateCheckinMin, QL_PRKey, QL_ByRoom, QL_TypeQuota)
	select	DISTINCT QT_ID, QD_Type, case when QD_Release = 0 then null else QD_Release end, NU_ID, @DateEnd+1,QT_PRKey, QT_ByRoom, QT_IsByCheckIn
	from	Quotas, QuotaObjects, QuotaDetails, Numbers
	where	QT_ID=QO_QTID and QD_QTID=QT_ID
			and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and ISNULL(QD_IsDeleted,0)=0
			and QD_Date between @DateStart and @DateEnd
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0)
			and NU_ID between 1 and 3
END
else
BEGIN
DECLARE @Service_SubCode1 int
	, @Object_SubCode1 int
	, @Object_SubCode2 int
	, @Service_SubCode2 int
	, @Service_NDays int
	, @Service_Day int
	, @Dogovor_NDay int
	, @Service_Duration int
	, @Dogovor_Key int
	SET @Object_SubCode1=0
	SET @Object_SubCode2=0
	
	IF @DLKey is not null				-- если мы запустили процедуру из конкрентной услуги
	BEGIN
		SELECT	@Service_SVKey=DL_SVKey, @Service_Code=DL_Code, @Service_SubCode1=DL_SubCode1
			  , @AgentKey=ISNULL(DL_Agent,0), @Service_PRKey=DL_PartnerKey, @Service_SubCode2 = DL_SubCode2
			  , @Service_NDays = DL_NDAYS
			  , @Service_Day = DL_DAY
			  , @Dogovor_Key = DL_DGKEY
		FROM	DogovorList (nolock)
		WHERE	DL_Key=@DLKey
		
		IF (@Service_NDays is null or @Service_NDays=0)
			SELECT @Service_Duration = DG_NDAY FROM Dogovor WHERE DG_Key = @Dogovor_Key
		ELSE
			SET @Service_Duration = @Service_NDays

		If @Service_SVKey=3
			SELECT @Object_SubCode1=HR_RMKey, @Object_SubCode2=HR_RCKey 
				FROM dbo.HotelRooms (nolock) WHERE HR_Key=@Service_SubCode1
		Else
			SET @Object_SubCode1=@Service_SubCode1
		
		IF @Service_SVKey=1
			SET @Object_SubCode2=@Service_SubCode2
	END

if @ResultType is null or @ResultType not in (10)
BEGIN
	Set @Result_From=11
	Set @Result_To=13
END
ELSE
BEGIN
	--для наличия мест(из оформления)
	Set @Result_From=21
	Set @Result_To=23
END;
	-- сначала заполняем таблицу квотами
	-- чтобы ускорить инсерт добавим временную таблицу
	DECLARE @TempTable2 TABLE
	(
		QL_QTID int,
		QL_Type smallint,
		QL_TypeQuota smallint,
		QL_Release int,
		QL_Durations varchar(20),
		QL_FilialKey int,
		QL_CityDepartments int,
		QL_AgentKey int,
		QL_CustomerInfo varchar(150),
		QL_DateCheckinMin smalldatetime,
		QL_PRKey int,
		QL_ByRoom int		
	)
	
	declare @QT_IsByCheckIn bit
	select @QT_IsByCheckIn = QT_IsByCheckIn from Quotas where QT_ID = @QT_ID

if (@QT_IsByCheckIn = 1 or @QT_IsByCheckIn is null)
		insert into @TempTable2 (QL_QTID, QL_Type, QL_TypeQuota, QL_Release, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
		select QT_ID, QD_Type, QT_IsByCheckIn, QD_Release, convert(nvarchar(max) ,QD_LongMin) + '-' + convert(nvarchar(max) ,QD_LongMax), QP_FilialKey, QP_CityDepartments, QP_AgentKey, '', @DateEnd + 1, QT_PRKey,QT_ByRoom
		from	Quotas (nolock), QuotaObjects (nolock), QuotaDetails (nolock), QuotaParts (nolock)
		where	QT_ID=QO_QTID
				and QD_QTID=QT_ID
				and QP_QDID = QD_ID
				and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
				and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) 
				and QD_Date between @DateStart and @DateEnd
				and QP_Date between @DateStart and @DateEnd
				and (QP_AgentKey is null or (@bShowAgencyInfo=1 and ((@AgentKey=QP_AgentKey) or (@AgentKey is null))))
				and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey=QT_PRKey or QT_PRKey=0)))
				and (QP_Durations='' or (@DurationLocal is null	
											or (@DurationLocal is not null
												and exists (Select QL_QPID From QuotaLimitations (nolock) WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID)))
					or @ShowAllDurations = 1)
				and ISNULL(QP_IsDeleted,0)=0
				and ISNULL(QD_IsDeleted,0)=0			
				and (@DLKey is null or @ShowAllDurations = 1 or (@DLKey is not null
				and ((QD_LongMin is null and QD_LongMax is null) or (@Service_Duration >= QD_LongMin and @Service_Duration <= QD_LongMax))
					and ((QO_SubCode1 = -1) or (QO_SubCode1 in (0,@Object_SubCode1)))
				and ((QO_SubCode2 = -1) or (QO_SubCode2 in (0,@Object_SubCode2)))))
				and QT_IsByCheckIn = 1
	
	if (@QT_IsByCheckIn = 0 or @QT_IsByCheckIn is null)
		insert into @TempTable2 (QL_QTID, QL_Type, QL_TypeQuota, QL_Release, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
		select QT_ID, QD_Type, QT_IsByCheckIn, QD_Release, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, '', @DateEnd + 1, QT_PRKey,QT_ByRoom
		from	Quotas (nolock), QuotaObjects (nolock), QuotaDetails (nolock), QuotaParts (nolock)
		where	QT_ID=QO_QTID
				and QD_QTID=QT_ID
				and QP_QDID = QD_ID
				and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
				and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) 
				and QD_Date between @DateStart and @DateEnd
				and QP_Date between @DateStart and @DateEnd
				and (QP_AgentKey is null or (@bShowAgencyInfo=1 and ((@AgentKey=QP_AgentKey) or (@AgentKey is null))))
				and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey=QT_PRKey or QT_PRKey=0)))
				and (@ShowAllDurations = 1 or (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select QL_QPID From QuotaLimitations (nolock) WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID)))))
				and ISNULL(QP_IsDeleted,0)=0
				and ISNULL(QD_IsDeleted,0)=0			
				and (@DLKey is null or (@DLKey is not null
				and ((QP_Durations='' or PATINDEX('%,' + CAST(@Service_Duration AS VARCHAR) + ',%', ',' + QP_Durations + ',') != 0) or @ShowAllDurations = 1)
				and ((QO_SubCode1 = -1) or (QO_SubCode1 in (0,@Object_SubCode1))) 
				and ((QO_SubCode2 = -1) or (QO_SubCode2 in (0,@Object_SubCode2)))))
				and QT_IsByCheckIn = 0
				
	insert into #QuotaLoadList (QL_QTID, QL_Type, QL_TypeQuota, QL_Release, QL_dataType, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	SELECT DISTINCT QL_QTID, QL_Type, QL_TypeQuota, QL_Release, NU_ID, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom
	FROM @TempTable2 nolock, Numbers (nolock)
	WHERE NU_ID between @Result_From and @Result_To

END

DECLARE @QD_ID int, @Date smalldatetime, @State smallint, @QD_Release int, @QP_Durations varchar(20), @QP_FilialKey int,
		@QP_CityDepartments int, @QP_AgentKey int, @Quota_Places int, @Quota_Busy int, @QP_IsNotCheckIn bit,
		@QD_QTID int, @QP_ID int, @Quota_Comment varchar(8000), @Stop_Comment varchar(255), @QO_ID int, @QT_IsNotCheckIn smallint, @QD_LongMin smallint, @QD_LongMax smallint--,	@QT_ID int
DECLARE @ColumnName varchar(10), @QueryUpdate varchar(8000), @QueryUpdate1 varchar(255), @QueryWhere1 varchar(255), @QueryWhere2 varchar(255), 
		@QD_PrevID int, @StopSale_Percent int, @CheckInPlaces smallint, @CheckInPlacesBusy smallint --@QuotaObjects_Count int, 

if @bShowCommonInfo = 1
	DECLARE curQLoadList CURSOR FOR SELECT 
			QT_ID, QD_ID, QD_Date, QD_Type, case when QD_Release = 0 then null else QD_Release end,
			QD_Places, QD_Busy,
			0,'',0,0,0,0, ISNULL(REPLACE(QD_Comment,'''','"'),''),0,0,0,0,0
	FROM	Quotas, QuotaDetails
	WHERE	QD_QTID=QT_ID
			and 
			(	
				(@QT_ID is null and exists 
					(	
						SELECT 1 FROM QuotaObjects WHERE QT_ID=QO_QTID 
						and QO_Code=@Service_Code and QO_SVKey=@Service_SVKey
					)
				)
				or
				(@QT_ID is not null and @QT_ID=QT_ID)
			)
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) and QD_Date between @DateStart and @DateEnd
			and (QD_IsDeleted = 0 or QD_IsDeleted is null)
	ORDER BY QD_Date DESC, QD_ID
else
	DECLARE curQLoadList CURSOR FOR 
	SELECT QT_ID, QD_ID, QD_Date, QD_Type, QD_Release, 
			QP_Places, QP_Busy, 
			QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, ISNULL(QP_IsNotCheckIn,0), ISNULL(REPLACE(QD_Comment,'''','"'),'') + '' + ISNULL(REPLACE(QP_Comment,'''','"'),''), QP_CheckInPlaces, QP_CheckInPlacesBusy, QT_IsByCheckIn, QD_LongMin, QD_LongMax
	FROM	Quotas, QuotaDetails,QuotaParts
	WHERE	QD_QTID=QT_ID and QP_QDID = QD_ID
			and 
			(	
				(@QT_ID is null and exists 
					(	
						SELECT 1 FROM QuotaObjects WHERE QT_ID=QO_QTID 
						and QO_Code=@Service_Code and QO_SVKey=@Service_SVKey
					)
				)
				or
				(@QT_ID is not null and @QT_ID=QT_ID)
			)
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) 
			and QD_Date between @DateStart and @DateEnd
			and QP_Date between @DateStart and @DateEnd
			and QP_QDID = QD_ID	
			and (QP_AgentKey is null or (@bShowAgencyInfo=1 and ((@AgentKey=QP_AgentKey) or (@AgentKey is null))))
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey=QT_PRKey or QT_PRKey=0)))
			and (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select QL_QPID From QuotaLimitations WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID))))
			and (QP_IsDeleted = 0 or QP_IsDeleted is null)
			and (QD_IsDeleted = 0 or QD_IsDeleted is null)
	ORDER BY QD_Date DESC, QD_ID


OPEN curQLoadList
FETCH NEXT FROM curQLoadList INTO	@QT_IDLocal,
									@QD_ID, @Date, @State, @QD_Release, @Quota_Places, @Quota_Busy,
									@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, 
									@QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy, @QT_IsNotCheckIn, @QD_LongMin, @QD_LongMax
SET @QD_PrevID = @QD_ID - 1

SET @StopSale_Percent=0
WHILE @@FETCH_STATUS = 0
BEGIN
	set @QueryUpdate1=''
	if DATEADD(DAY,ISNULL(@QD_Release,0),DATEADD(hh,0,GETDATE()- {fn CURRENT_time()})) < @Date
	begin
		set @QueryUpdate1=', QL_DateCheckInMin=''' + CAST(@Date as varchar(250)) + ''''
		--print @QueryUpdate1
	end
	--если релиз период наступил сегодня
	if DATEADD(DAY,ISNULL(@QD_Release,0),DATEADD(hh,0,GETDATE()- {fn CURRENT_time()})) = @Date
	begin
		set @QueryUpdate1=', QL_DateCheckInMin=''' + CAST(@Date as varchar(250)) + ''''
		--print @QueryUpdate1
	end
	set @ColumnName = CAST(CAST((@Date-@DateStart+1) as int) as varchar(6))

	If @QD_PrevID != @QD_ID
	BEGIN
		SET @StopSale_Percent=0
		
		SET @Stop_Comment = ''
		IF @DLKey is null
		BEGIN
			if Exists (SELECT 1 FROM #StopSaleTemp (nolock) WHERE SST_QDID = @QD_ID )
				SELECT @StopSale_Percent = 100*SST_QO_Count/SST_QO_CountWithStop, @Stop_Comment = SST_Comment FROM #StopSaleTemp (nolock) WHERE SST_QDID = @QD_ID
		END
		ELSE
		BEGIN
			if Exists (SELECT 1 FROM #StopSaleTemp (nolock) WHERE SST_QDID = @QD_ID )
				SELECT @StopSale_Percent = 100, @Stop_Comment = SST_Comment FROM #StopSaleTemp (nolock) WHERE SST_QDID = @QD_ID
		END

		If @Stop_Comment!=''
			SET @Quota_Comment=@Quota_Comment+ 'Stop-Sale info: ' + @Stop_Comment
		SET @QD_PrevID = @QD_ID
	END	
	ELSE
		If @Stop_Comment!=''
			SET @Quota_Comment=@Quota_Comment+ 'Stop-Sale info: ' + @Stop_Comment

	set @QueryWhere1 = ' where QL_Type = ' + CAST(@State as varchar(1))
	if @QD_Release is null
		set @QueryWhere1 = @QueryWhere1 + ' and QL_Release is null' 
	else
		set @QueryWhere1 = @QueryWhere1 + ' and QL_Release = ' + CAST(@QD_Release as varchar(5))
	
	if @bShowCommonInfo = 1
	BEGIN
	--			+ ',QL_B_' + @ColumnName + ' = ''' + CAST((@Quota_Busy) as varchar(10)) + ';' + CAST(@QD_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@Quota_Comment as varchar(7980)) + ''''
		set @QueryUpdate = 'UPDATE #QuotaLoadList SET 
			QL_' + @ColumnName + ' = (CASE QL_dataType WHEN 1 THEN ''' + CAST((@Quota_Places) as varchar(10))  + ''' WHEN 2 THEN ''' + CAST((@Quota_Places-@Quota_Busy) as varchar(10))  + ''' WHEN 3 THEN ''' + CAST((@Quota_Busy) as varchar(10)) + ''' END)+' + ''';' + CAST(@QD_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@Quota_Comment as varchar(7980)) + ''''
				+ @QueryUpdate1
				+ @QueryWhere1 + ' and QL_dataType in (1,2,3) and QL_QTID=' + CAST(@QT_IDLocal as varchar(10))
		--print @QueryUpdate
		exec (@QueryUpdate)
	END
	else
	BEGIN
		set @QueryWhere2 = ''
		
		if (@QT_IsNotCheckIn = 1 or @QT_IsNotCheckIn is null)
		begin
			if @QD_LongMin is null and @QD_LongMax is null
				set @QueryWhere2 = @QueryWhere2 + ' and QL_Durations is null' 
			else
				set @QueryWhere2 = @QueryWhere2 + ' and QL_Durations = ''' + (convert(nvarchar(max) ,@QD_LongMin) + '-' + convert(nvarchar(max) ,@QD_LongMax)) + ''''
		end
		if (@QT_IsNotCheckIn = 0 or @QT_IsNotCheckIn is null)
		begin
			if @QP_Durations is null
				set @QueryWhere2 = @QueryWhere2 + ' and QL_Durations is null' 
			else
				set @QueryWhere2 = @QueryWhere2 + ' and QL_Durations = ''' + @QP_Durations + ''''
		end
		
		if @QP_FilialKey is null
			set @QueryWhere2 = @QueryWhere2 + ' and QL_FilialKey is null' 
		else
			set @QueryWhere2 = @QueryWhere2 + ' and QL_FilialKey = ' + CAST(@QP_FilialKey as varchar(10))
		if @QP_CityDepartments is null
			set @QueryWhere2 = @QueryWhere2 + ' and QL_CityDepartments is null' 
		else
			set @QueryWhere2 = @QueryWhere2 + ' and QL_CityDepartments = ' + CAST(@QP_CityDepartments as varchar(10))
 		if @QP_AgentKey is null
			set @QueryWhere2 = @QueryWhere2 + ' and QL_AgentKey is null' 
		else
			set @QueryWhere2 = @QueryWhere2 + ' and QL_AgentKey = ' + CAST(@QP_AgentKey as varchar(10))
	--			+ ',QL_B_' + @ColumnName + ' = ''' + CAST((@Quota_Busy) as varchar(10))  + ';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(@Quota_Comment as varchar(7980)) + ''''
		IF @ResultType is null or @ResultType not in (10)
		BEGIN
			IF @bShowByCheckIn = 1 and @QP_Durations <> '' 
			set @QueryUpdate = 'UPDATE #QuotaLoadList SET	
					QL_' + @ColumnName + ' = (CASE QL_dataType WHEN 11 THEN ''' + CAST(ISNULL(@CheckInPlaces,0) as varchar(10)) + ''' WHEN 12 THEN ''' + CAST(ISNULL(@CheckInPlaces-@CheckInPlacesBusy,0) as varchar(10)) + ''' WHEN 13 THEN ''' + CAST(ISNULL(@CheckInPlacesBusy,0) as varchar(10)) + ''' END)+' + ''';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(@Quota_Comment as varchar(7900)) + ''''
				+ @QueryUpdate1
				+ @QueryWhere1 + @QueryWhere2 + ' and QL_dataType in (11,12,13) and QL_QTID=' + CAST(@QT_IDLocal as varchar(10))
			ELSE
			BEGIN
				-- @StopSaleOrPlaces служит для показывания буквы 'S' для стопов на объекты квотирования вместо 0
				DECLARE @StopSaleOrPlaces varchar(255)
				if @QD_ID < 0
					set @StopSaleOrPlaces = '''S'
				else
					set @StopSaleOrPlaces = '(CASE QL_dataType WHEN 11 THEN ''' + CAST((@Quota_Places) as varchar(10)) + ''' WHEN 12 THEN ''' + CAST((@Quota_Places-@Quota_Busy) as varchar(10)) + ''' WHEN 13 THEN ''' + CAST((@Quota_Busy) as varchar(10)) + ''' END)+'''
					
				set @QueryUpdate = 'UPDATE #QuotaLoadList SET	
						QL_' + @ColumnName + ' = ' + @StopSaleOrPlaces + ';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(@Quota_Comment as varchar(7900)) + ''''
					+ @QueryUpdate1
					+ @QueryWhere1 + @QueryWhere2 + ' and QL_dataType in (11,12,13) and QL_QTID=' + CAST(@QT_IDLocal as varchar(10))
			END		
		END
		ELSE
		BEGIN
		--для наличия мест(из оформления)
			--  WHEN 22 THEN ' + @StopSale_Percent + ' WHEN 23 THEN ' + @QP_IsNotCheckIn + ' END
			set @QueryUpdate = 'UPDATE #QuotaLoadList SET	
					QL_' + @ColumnName + ' = (CASE QL_dataType WHEN 21 THEN ' + CAST((@Quota_Places-@Quota_Busy) as varchar(5)) + ' WHEN 22 THEN ' + CAST(@StopSale_Percent as varchar(5)) + ' WHEN 23 THEN ' + CAST(@QP_IsNotCheckIn as varchar(5)) + ' END)' 
				+ @QueryUpdate1
				+ @QueryWhere1 + @QueryWhere2 + ' and QL_dataType in (21,22,23) and QL_QTID=' + CAST(@QT_IDLocal as varchar(10))
		END	
		--print @QueryUpdate
		exec (@QueryUpdate)
	END	
	FETCH NEXT FROM curQLoadList INTO	@QT_IDLocal,
										@QD_ID, @Date, @State, @QD_Release, @Quota_Places, @Quota_Busy,
										@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, 
										@QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy, @QT_IsNotCheckIn, @QD_LongMin, @QD_LongMax
END
CLOSE curQLoadList
DEALLOCATE curQLoadList

--select * from #QuotaLoadList
-- заполняем таблицу стопами, т.е. обозначаем квоты на которых стоит стоп, и если стоп поставлен плагином, добавляем строчку с буквой "S"
DECLARE @TEMP_QL_ID INT, 
	@SS_Code INT, @SS_SubCode1 INT, @SS_SubCode2 INT, @SS_PRKey INT, @SS_AllotmentAndCommitment INT, @SS_Date datetime, @SS_Comment varchar(255),
	@SS_PrevCode INT, @SS_PrevSubCode1 INT, @SS_PrevSubCode2 INT, @SS_PrevPRKey INT, @SS_PrevAllotmentAndCommitment INT, @SS_PrevDate datetime, 
	@SS_PrevComment varchar(255)

SET @StopSaleOrPlaces = 'S'
SET @QP_ID=-1
SET @StopSale_Percent = 100
SET @QP_IsNotCheckIn = 0
SET @TEMP_QL_ID = null

declare StopSaleWithOutQO CURSOR FOR
	SELECT	QO_Code, QO_SubCode1, QO_SubCode2, SS_PRKey, ISNULL(SS_AllotmentAndCommitment,0), SS_Date, SS_Comment
	FROM	QuotaObjects, StopSales 
	WHERE	QO_ID = SS_QOID 
			and QO_Code = @Service_Code and QO_SVKey = @Service_SVKey and QO_QTID is null
			and SS_Date between @DateStart and @DateEnd
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey = SS_PRKey or SS_PRKey = 0)))
			and ISNULL(SS_IsDeleted,0) = 0
	ORDER BY QO_Code, QO_SubCode1, QO_SubCode2, SS_PRKey, SS_AllotmentAndCommitment, SS_Date, SS_Comment
OPEN StopSaleWithOutQO
FETCH NEXT FROM StopSaleWithOutQO INTO	
			@SS_Code, @SS_SubCode1, @SS_SubCode2, @SS_PRKey, @SS_AllotmentAndCommitment, @SS_Date, @SS_Comment
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @SS_Code != ISNULL(@SS_PrevCode,-100)
		OR @SS_SubCode1 != @SS_PrevSubCode1
		OR @SS_SubCode2 != @SS_PrevSubCode2
		OR @SS_PRKey != @SS_PrevPRKey
		OR @SS_AllotmentAndCommitment != @SS_PrevAllotmentAndCommitment
	BEGIN
		SET @SS_PrevDate = null
		SET @ColumnName = CAST((DATEDIFF(DAY,@DateStart,@SS_Date)+1) as varchar(3))
		SET @Quota_Comment = ISNULL(@SS_Comment,'')
		SET @QueryUpdate='INSERT INTO #QuotaLoadList 
			(QL_QTID, QL_PRKey, QL_SubCode1, QL_SubCode2, QL_dataType, 
			QL_Type, QL_ByRoom, QL_' + @ColumnName + ')
			values 
			(0, ' + CAST(@SS_PRKey as varchar(15)) + ', ' + CAST(@SS_SubCode1 as varchar(15)) + ', ' + CAST(@SS_SubCode2 as varchar(15)) + ', 11, ' +
			CAST((@SS_AllotmentAndCommitment+1) as varchar(2)) + ', 1, 
			''' + @StopSaleOrPlaces + ';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(@Quota_Comment as varchar(7900)) + '''
			)
		'
		exec (@QueryUpdate)
	END
	ELSE
	BEGIN
		IF @SS_Date != @SS_PrevDate
		BEGIN
			SET @ColumnName = CAST((DATEDIFF(DAY,@DateStart,@SS_Date)+1) as varchar(3))
			SET @Quota_Comment = ISNULL(@SS_Comment,'')
			SET @QueryUpdate='UPDATE #QuotaLoadList SET	
						QL_' + @ColumnName + ' = ''' + @StopSaleOrPlaces + ';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(@Quota_Comment as varchar(7900)) + ''' 
						WHERE 
							QL_PRKey = ' + CAST(@SS_PRKey as varchar(15)) + '
							AND QL_SubCode1 = ' + CAST(@SS_SubCode1 as varchar(15)) + '
							AND QL_SubCode2 = ' + CAST(@SS_SubCode2 as varchar(15)) + '
							AND QL_Type = ' + CAST((@SS_AllotmentAndCommitment+1) as varchar(2)) 
							
			exec (@QueryUpdate)
		END
		ELSE IF @SS_Date = @SS_PrevDate
		BEGIN 
			IF @SS_Comment != @SS_PrevComment
			BEGIN
				SET @Quota_Comment = ISNULL(@SS_Comment,'')
				SET @QueryUpdate='UPDATE #QuotaLoadList SET	
						QL_' + @ColumnName + ' = QL_' + @ColumnName + ' + CAST(' + @Quota_Comment + ' as varchar(7900)) +  
						WHERE 
							QL_PRKey = ' + CAST(@SS_PRKey as varchar(15)) + '
							AND QL_SubCode1 = ' + CAST(@SS_SubCode1 as varchar(15)) + '
							AND QL_SubCode2 = ' + CAST(@SS_SubCode2 as varchar(15)) + '
							AND QL_Type = ' + CAST((@SS_AllotmentAndCommitment+1) as varchar(2)) 
				exec (@QueryUpdate)
			END
		END
	END
	SET @SS_PrevDate = @SS_Date
	SET @SS_PrevComment = @SS_Comment	
	SET @SS_PrevCode = @SS_Code
	SET @SS_PrevSubCode1 = @SS_SubCode1
	SET @SS_PrevSubCode2 = @SS_SubCode2
	SET @SS_PrevPRKey = @SS_PRKey
	SET @SS_PrevAllotmentAndCommitment = @SS_AllotmentAndCommitment
	FETCH NEXT FROM StopSaleWithOutQO INTO	
				@SS_Code, @SS_SubCode1, @SS_SubCode2, @SS_PRKey, @SS_AllotmentAndCommitment, @SS_Date, @SS_Comment
END
CLOSE StopSaleWithOutQO
DEALLOCATE StopSaleWithOutQO


IF @DLKey is null and @QT_ID is null and (@ResultType is null or @ResultType not in (10))
BEGIN
	IF(@Service_SVKey = 3)
		SET @ByRoom = (SELECT AVG(ISNULL(QL_ByRoom,0)) FROM #QuotaLoadList)
	ELSE
		SET @ByRoom = 0

	insert into #QuotaLoadList 
		(QL_SubCode1, QL_Type, QL_dataType, QL_PRKey, QL_ByRoom)
	select DISTINCT DL_SubCode1, SD_State, 21, DL_PartnerKey, @ByRoom
	from	DogovorList (nolock),ServiceByDate (nolock)
	where	SD_DLKey=DL_Key
			and DL_SVKey=@Service_SVKey and DL_Code=@Service_Code and ((DL_DateBeg between @DateStart and @DateEnd) or (DL_DateEnd between @DateStart and @DateEnd))
			and SD_Date<=@DateEnd and SD_Date>=@DateStart
			and SD_State not in (1,2)
	group by SD_Date,DL_SubCode1,DL_PartnerKey,SD_State
END

if (@nGridFilter=3)
begin
	update #QuotaLoadList set QL_CustomerInfo = (Select PR_NameENG from Partners (nolock) where PR_Key = QL_AgentKey and QL_AgentKey > 0)
	update #QuotaLoadList set QL_PartnerName = (Select PR_NameENG from Partners (nolock) where PR_Key = QL_PRKey and QL_PRKey > 0)
end
else
begin
	update #QuotaLoadList set QL_CustomerInfo = (Select PR_Name from Partners (nolock) where PR_Key = QL_AgentKey and QL_AgentKey > 0)
	update #QuotaLoadList set QL_PartnerName = (Select PR_Name from Partners (nolock) where PR_Key = QL_PRKey and QL_PRKey > 0)
end
update #QuotaLoadList set QL_PartnerName = 'All partners' where QL_PRKey=0

IF @DLKey is null and @QT_ID is null and (@ResultType is null or @ResultType not in (10))
BEGIN
	DECLARE @ServiceCount int, @SubCode1 int, @PartnerKey int

	DECLARE curQServiceList CURSOR FOR SELECT
		SD_Date,
		CASE @ByRoom WHEN 1 THEN count(distinct SD_RLID) ELSE count(SD_ID) END,
		DL_SubCode1,
		DL_PartnerKey,
		SD_State
		from	DogovorList (nolock),ServiceByDate (nolock)
		where	SD_DLKey=DL_Key
				and DL_SVKey=@Service_SVKey and DL_Code=@Service_Code 
				and DL_DateBeg<=@DateEnd and DL_DateEnd>=@DateStart
				and SD_Date<=@DateEnd and SD_Date>=@DateStart
				and SD_State not in (1,2)
		group by SD_Date,DL_SubCode1,DL_PartnerKey,SD_State
	OPEN curQServiceList
	FETCH NEXT FROM curQServiceList INTO	@Date, @ServiceCount, @SubCode1, @PartnerKey, @State

	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @ColumnName = CAST(CAST((@Date-@DateStart+1) as int) as varchar(6))
		set @QueryWhere1 = ' where QL_Type = ' + CAST(@State as varchar(1))

		set @QueryUpdate = 'UPDATE #QuotaLoadList SET QL_' + @ColumnName + ' = ''' + CAST((@ServiceCount) as varchar(10))  + ''' 
		WHERE QL_Type = ' + CAST(@State as varchar(1)) + ' and QL_SubCode1= ' + CAST(@SubCode1 as varchar(10)) + ' and QL_PRKey= ' + CAST(@PartnerKey as varchar(10))

		exec (@QueryUpdate)
		FETCH NEXT FROM curQServiceList INTO	@Date, @ServiceCount, @SubCode1, @PartnerKey, @State
	END
	CLOSE curQServiceList
	DEALLOCATE curQServiceList
END

DECLARE @QO_SubCode int, @QO_TypeD smallint, @DL_SubCode1 int, @QT_ID_Prev int, @ServiceName1 varchar(100), @ServiceName2 varchar(100), @Temp varchar(100),
	@IDEN_Local int, @IDEN_Prev int, @IDENTYPE_Local int, @IDENTYPE_Prev int
DECLARE curQLoadListQO CURSOR FOR 
	SELECT DISTINCT QO_QTID, QO_SubCode1, 1, null, 1 FROM QuotaObjects (nolock) WHERE QO_QTID in (SELECT QL_QTID FROM #QuotaLoadList (nolock) WHERE QO_QTID is not null)
	UNION
	SELECT DISTINCT QO_QTID, QO_SubCode2, 2, null, 1 FROM QuotaObjects (nolock) WHERE QO_QTID in (SELECT QL_QTID FROM #QuotaLoadList (nolock) WHERE QO_QTID is not null)
	UNION
	SELECT DISTINCT QL_ID, QL_SubCode1, 1, null, 3 FROM #QuotaLoadList (nolock) WHERE QL_SubCode1 is not null
	UNION
	SELECT DISTINCT QL_ID, QL_SubCode2, 2, null, 3 FROM #QuotaLoadList (nolock) WHERE QL_SubCode2 is not null
	UNION
	SELECT DISTINCT null, null, null, QL_SubCode1, 2 FROM #QuotaLoadList (nolock) WHERE QL_SubCode1 is not null
	ORDER BY 5,1,3

OPEN curQLoadListQO
FETCH NEXT FROM curQLoadListQO INTO	@IDEN_Local, @QO_SubCode, @QO_TypeD, @DL_SubCode1, @IDENType_Local
Set @IDEN_Prev=@IDEN_Local
Set @IDENTYPE_Prev=@IDENTYPE_Local

Set @ServiceName1=''
Set @ServiceName2=''

WHILE @@FETCH_STATUS = 0
BEGIN
	if @DL_SubCode1 is not null
	BEGIN
		Set @Temp=''
		if (@nGridFilter=3)
			begin
				--для англ версии
				exec GetSvCode1Name @Service_SVKey, @DL_SubCode1, null, null, null, @Temp output
			end
			else
			begin
				--для русской версии
				exec GetSvCode1Name @Service_SVKey, @DL_SubCode1, null, @Temp output, null, null
			end

		Update #QuotaLoadList set QL_Description=ISNULL(QL_Description,'') + @Temp where QL_SubCode1=@DL_SubCode1
		--print @Temp
	END
	Else
	BEGIN
		If (@IDEN_Prev != @IDEN_Local) OR (@IDENTYPE_Prev != @IDENTYPE_Local)
		BEGIN
			If @Service_SVKey=3
			BEGIN
				Set @ServiceName2='(' + @ServiceName2 + ')'
			END
			IF @IDENTYPE_Prev = 1
				Update #QuotaLoadList set QL_Description=LEFT(ISNULL(QL_Description,'') + @ServiceName1 + @ServiceName2,255) where QL_QTID=@IDEN_Prev
			IF @IDENTYPE_Prev = 3
			--обработка стоп сейла
				Update #QuotaLoadList set QL_Description=LEFT(@ServiceName1 + @ServiceName2,255) where QL_ID=@IDEN_Prev and QL_QTID is not null
			Set @ServiceName1=''
			Set @ServiceName2=''
		END
		
		SET @IDEN_Prev=@IDEN_Local
		SET @IDENTYPE_Prev=@IDENTYPE_Local
		Set @Temp=''
		If @Service_SVKey=3
		BEGIN
			IF @QO_TypeD=1
			BEGIN
				if (@nGridFilter=3)
				begin
					--для англ версии
					EXEC GetRoomName @QO_SubCode, null, @Temp output
				end
				else
				begin
					--для русской версии
					EXEC GetRoomName @QO_SubCode, @Temp output, null
				end
				If @ServiceName1!=''
					Set @ServiceName1=@ServiceName1+','
				Set @ServiceName1=@ServiceName1+@Temp
			END			
			Set @Temp=''
			IF @QO_TypeD=2
			BEGIN
				if (@nGridFilter=3)
				begin
					--для англ версии
					EXEC GetRoomCtgrName @QO_SubCode, null, @Temp output
				end
				else
				begin
					--для русской версии
					EXEC GetRoomCtgrName @QO_SubCode, @Temp output, null
				end
				If @ServiceName2!=''
					Set @ServiceName2=@ServiceName2+','
				Set @ServiceName2=@ServiceName2+@Temp
				--print @Temp
			END
		END
		ELse
		BEGIN
			if (@nGridFilter=3)
			begin
				--для англ версии
				exec GetSvCode1Name @Service_SVKey, @QO_SubCode, null, null, null, @Temp output
			end
			else
			begin
				--для русской версии
				exec GetSvCode1Name @Service_SVKey, @QO_SubCode, null, @Temp output, null, null
			end
			If @ServiceName1!=''
				Set @ServiceName1=@ServiceName1+','
			Set @ServiceName1=@ServiceName1+@Temp
		END
	END
	FETCH NEXT FROM curQLoadListQO INTO	@IDEN_Local, @QO_SubCode, @QO_TypeD, @DL_SubCode1, @IDENType_Local
END


If @Service_SVKey=3
BEGIN
	Set @ServiceName2='(' + @ServiceName2 + ')'
END
	IF @IDENTYPE_Prev = 1
		Update #QuotaLoadList set QL_Description=LEFT(ISNULL(QL_Description,'') + @ServiceName1 + @ServiceName2,255) where QL_QTID=@IDEN_Prev
	IF @IDENTYPE_Prev = 3
		--обработка стоп сейла
		Update #QuotaLoadList set QL_Description=LEFT(@ServiceName1 + @ServiceName2,255) where QL_ID=@IDEN_Prev and QL_QTID is not null
	--print @ServiceName1
	--print @ServiceName2
CLOSE curQLoadListQO
DEALLOCATE curQLoadListQO


/*
-- 29-03-2012 karimbaeva удаляю строки, чтобы не дублировались при выводе в окне, если стоп стоит по нескольким типам номеров
delete from #QuotaLoadList where ql_qoid <> (select top 1  ql_qoid from #QuotaLoadList) and ql_qoid is not null
*/

if (@bShowCommonRequest=1)
begin

--saifullina 11.02.2013
--формируем темповую таблицу для услуг на запросе
CREATE TABLE #tmpQuotaLoadList(QLID int,
	QLQTID int, QLQOID int, QLPRKey int, QLSubCode1 int, QLSubCode2 int, QLPartnerName nvarchar(100) collate Cyrillic_General_CI_AS, QLDescription nvarchar(255) collate Cyrillic_General_CI_AS, 
	QLdataType smallint, QLType smallint, QLTypeQuota smallint, QLRelease int, QLDurations nvarchar(20) collate Cyrillic_General_CI_AS, QLFilialKey int, 
	QLCityDepartments int, QLAgentKey int, QLCustomerInfo nvarchar(150) collate Cyrillic_General_CI_AS, QLDateCheckinMin smalldatetime,
	QLByRoom int)
	
	set @n=1 
	set @str = ''
	 
	WHILE @n <= @DaysCount
	BEGIN
		set @str = 'ALTER TABLE #tmpQuotaLoadList ADD QL' + CAST(@n as varchar(3)) + ' int'
		exec (@str)
		set @n = @n + 1
	END

declare @qlid int,
@qlPrKey int,
@qlAgentKey int,
@qlAgentName varchar(max),
@qlPartnerName varchar(max)
	--добавляем все услуги на запросе в таблицу
	DECLARE qCur CURSOR FAST_FORWARD READ_ONLY FOR
	select QL_ID,QL_PRKey,QL_AgentKey,QL_PartnerName,QL_CustomerInfo from #QuotaLoadList where QL_Type = 4		
	OPEN qCur								
	FETCH NEXT FROM qCur INTO @qlid,@qlPrKey,@qlAgentKey,@qlPartnerName,@qlAgentName		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		insert into #tmpQuotaLoadList (QLID,QLSubCode1, QLType, QLdataType, QLByRoom,QLAgentKey,QLPRKey) select top 1 QL_ID, QL_SubCode1, QL_Type, QL_dataType, QL_ByRoom, QL_AgentKey, QL_PRKey from #QuotaLoadList where QL_ID=@qlid
		set @n = 1
		declare @turist nvarchar(max)
		WHILE @n <= @DaysCount
		begin
			set @QueryUpdate = ''
		set @QueryUpdate = 'UPDATE #tmpQuotaLoadList SET QL' + CAST(@n as varchar(3)) + ' = (select CAST (QL_' + CAST(@n as varchar(3))  +' as int) from #QuotaLoadList
		WHERE QL_ID = ' + CAST(@qlid as varchar(10)) + ' and QL_' + CAST(@n as varchar(3)) + ' is not null) where QLID='+CAST(@qlid as varchar(25))
		exec (@QueryUpdate) 
			set @n = @n + 1
		end
		
		delete #QuotaLoadList where QL_Type=4 and QL_ID=@qlid
		
		if not exists (select * from #QuotaLoadList where (QL_Description like 'Любое' or  QL_Description like 'Any') and QL_Type=4 and QL_dataType=21 and (QL_AgentKey=@qlAgentKey or (QL_AgentKey is null and @qlAgentKey is null))and QL_PRKey = @qlPrKey)
		begin
			if (@ngridfilter=3)
			begin
				insert into #QuotaLoadList (QL_Description, QL_Type,QL_dataType,QL_AgentKey,QL_PRKey, QL_CustomerInfo, QL_PartnerName) values ('Any',4,21,@qlAgentKey,@qlPrKey,@qlAgentName,@qlPartnerName)
			end
			else
			begin
				insert into #QuotaLoadList (QL_Description, QL_Type,QL_dataType,QL_AgentKey,QL_PRKey, QL_CustomerInfo, QL_PartnerName) values ('Любое',4,21,@qlAgentKey,@qlPrKey,@qlAgentName,@qlPartnerName)
			end
		end
		
	FETCH NEXT FROM qCur INTO @qlid,@qlPrKey,@qlAgentKey,@qlPartnerName,@qlAgentName
	END
	CLOSE qCur
	DEALLOCATE qCur

set @n = 1
WHILE @n <= @DaysCount
	begin
		set @QueryUpdate = ''
	set @QueryUpdate = 'UPDATE #QuotaLoadList SET QL_' + CAST(@n as varchar(3)) + ' =' + '(select SUM(QL' + CAST(@n as varchar(3)) + ') from #tmpQuotaLoadList)
	WHERE QL_Type=4'
	exec (@QueryUpdate) 
		set @n = @n + 1
	end
drop table #tmpQuotaLoadList

end

If @Service_SVKey=3
BEGIN
	Update #QuotaLoadList set QL_Description = QL_Description + ' - Per person' where QL_ByRoom = 0
END
--Общий релиз период
if (@bCommonRelease is not null and @bCommonRelease = 1) and (@ResultType is null or @ResultType not in (10))
begin
	update #QuotaLoadList set QL_Release=0 where QL_Release is null
	
	CREATE TABLE #tempQuotaLoadList(QLID int,
	QLQTID int, QLQOID int, QLPRKey int, QLSubCode1 int, QLSubCode2 int, QLPartnerName nvarchar(100) collate Cyrillic_General_CI_AS, QLDescription nvarchar(255) collate Cyrillic_General_CI_AS, 
	QLdataType smallint, QLType smallint, QLTypeQuota smallint, QLRelease nvarchar(max), QLDurations nvarchar(20) collate Cyrillic_General_CI_AS, QLFilialKey int, 
	QLCityDepartments int, QLAgentKey int, QLCustomerInfo nvarchar(150) collate Cyrillic_General_CI_AS, QLDateCheckinMin smalldatetime,
	QLByRoom int)

	set @n=1 
	set @str = ''
	 
	WHILE @n <= @DaysCount
	BEGIN
		set @str = 'ALTER TABLE #tempQuotaLoadList ADD QL' + CAST(@n as varchar(3)) + ' varchar(8000)'
		exec (@str)
		set @n = @n + 1
	END
	
	declare @Qtid int, @Prkey int, @partnerName nvarchar(100), @description nvarchar(100), @dataType smallint, @type smallint, 
	@typeQuota smallint, @durations nvarchar(20), @agent int, @qlid_min int 
	DECLARE @placesResult TABLE ( isPlacesExists bit  )
	DECLARE qCur CURSOR FAST_FORWARD READ_ONLY FOR
	select QL_QTID, QL_PRKey, QL_PartnerName, QL_Description, QL_DataType, QL_Type, QL_TypeQuota, QL_Durations, QL_AgentKey, MIN(QL_ID) as ql_id
								from #QuotaLoadList
								where QL_Release is not null
								group by QL_QTID, QL_PRKey, QL_PartnerName, QL_Description, QL_DataType, QL_Type, QL_TypeQuota, QL_Durations, QL_AgentKey
								having count(*)>1
								
	OPEN qCur								
	FETCH NEXT FROM qCur INTO @Qtid, @Prkey, @partnerName, @description, @dataType, @type, @typeQuota, @durations, @agent, @qlid_min 						
	WHILE @@FETCH_STATUS = 0
	BEGIN
		insert into #tempQuotaLoadList 
		select *
		from #QuotaLoadList where QL_QTID = @Qtid and QL_PRKey = @Prkey and QL_PartnerName = @partnerName 
		and QL_Description = @description and QL_DataType = @dataType and QL_Type = @type 
		and QL_TypeQuota = @typeQuota and ((QL_Durations is null and @durations is null) or (QL_Durations = @durations))   
		and ((QL_AgentKey is null and @agent is null) or (QL_AgentKey = @agent))
		and QL_ID <> @qlid_min
		
		set @n = 1
		WHILE @n <= @DaysCount
		begin
			delete from @placesResult
			set @QueryUpdate = ''
			set @QueryUpdate = 'select top 1 1 from #tempQuotaLoadList where QL' + CAST(@n as varchar(3)) + ' is not null'
			INSERT INTO @placesResult EXEC (@QueryUpdate)
			if exists(select top 1 1 from @placesResult where isPlacesExists = 1)
			begin
				set @QueryUpdate = ''
				set @QueryUpdate = 'with Places as (select( 
															sum(
																	CONVERT(int,SUBSTRING(QL' + CAST(@n as varchar(3)) + ',0,CHARINDEX('';'',QL' + CAST(@n as varchar(3)) + ')))
																)
															) as d												
			from #tempQuotaLoadList
														where QL' + CAST(@n as varchar(3)) + ' is not null
													) update #tempQuotaLoadList set QL' + CAST(@n as varchar(3)) + ' = convert(varchar,(select top 1 * from Places)) + 
													  SUBSTRING(QL' + CAST(@n as varchar(3)) + ',CHARINDEX('';'',QL' + CAST(@n as varchar(3)) + '),LEN(QL' + CAST(@n as varchar(3)) + '))	
									where QL' + CAST(@n as varchar(3)) + ' is not null'
				exec (@QueryUpdate) 
			end
			set @n = @n + 1
		end		
		set @n = 1
		WHILE @n <= @DaysCount
		begin
			delete from @placesResult
			set @QueryUpdate = ''
			set @QueryUpdate = 'select top 1 1 from #tempQuotaLoadList where QL' + CAST(@n as varchar(3)) + ' is not null'
			INSERT INTO @placesResult EXEC (@QueryUpdate)
			if exists(select top 1 1 from @placesResult where isPlacesExists = 1)
			begin
				set @QueryUpdate = ''
				set @QueryUpdate = 'UPDATE #QuotaLoadList 
				SET QL_' + CAST(@n as varchar(3)) + ' = Convert(varchar,(
																			COALESCE(CONVERT(int,SUBSTRING(QL_' + CAST(@n as varchar(3)) + ',0,CHARINDEX('';'',QL_' + CAST(@n as varchar(3)) + '))), 0) 
																			+ (select top 1 CONVERT(int,SUBSTRING(QL' + CAST(@n as varchar(3)) + ',0,CHARINDEX('';'',QL' + CAST(@n as varchar(3)) + '))) 
																				from #tempQuotaLoadList where QL' + CAST(@n as varchar(3)) + ' is not null)
																		)
																) 
														+ (select top 1 SUBSTRING(QL' + CAST(@n as varchar(3)) + ',CHARINDEX('';'',QL' + CAST(@n as varchar(3)) + '),LEN(QL' + CAST(@n as varchar(3)) + ')) 
																from #tempQuotaLoadList where QL' + CAST(@n as varchar(3)) + ' is not null)
				WHERE QL_ID = ' + CAST(@qlid_min as varchar(10)) + ''

			exec (@QueryUpdate) 
			end
			set @n = @n + 1
		end
				
		declare @commonRelease nvarchar(20), @tempRelease nvarchar(max)
		set @tempRelease = ''
		DECLARE qCurs CURSOR FAST_FORWARD READ_ONLY FOR
		select QLRelease from #tempQuotaLoadList
		OPEN qCurs								
		FETCH NEXT FROM qCurs INTO @commonRelease					
		WHILE @@FETCH_STATUS = 0
		BEGIN
			set @tempRelease = @tempRelease + ',' + @commonRelease
			FETCH NEXT FROM qCurs INTO @commonRelease			
		END
		CLOSE qCurs
		DEALLOCATE qCurs
		update #QuotaLoadList set QL_Release = QL_Release + @tempRelease where QL_ID = @qlid_min
				
		delete from #QuotaLoadList where QL_ID in (select QLID from #tempQuotaLoadList)
		truncate table #tempQuotaLoadList
		FETCH NEXT FROM qCur INTO @Qtid, @Prkey, @partnerName, @description, @dataType, @type, @typeQuota, @durations, @agent, @qlid_min 
	END
	CLOSE qCur
	DEALLOCATE qCur
	drop table #tempQuotaLoadList
end

-- удаляем вспомогательный столбец
alter table #QuotaLoadList drop column QL_QOID
alter table #QuotaLoadList drop column QL_SubCode2
alter table #QuotaLoadList drop column QL_ID

-- если запуск из экрана Статус бронирования
-- фильтруем по квотам на зезд, они должны отображаться только на 1-й день
if (@nGridFilter=1)
begin
	set @n = 2
		WHILE @n <= @DaysCount
		begin
			set @QueryUpdate = ''
			--set @QueryUpdate = 'UPDATE #QuotaLoadList SET QL_' + CAST(@n as varchar(3)) + ' = null 
			--WHERE QL_QTID in (select QT_ID from Quotas join QuotaDetails on QT_ID = QD_QTID where QT_IsByCheckIn=1 and QD_Date <> ' + CAST(@DateStart as varchar(20))  +')'
			set @QueryUpdate = 'UPDATE #QuotaLoadList SET QL_' + CAST(@n as varchar(3)) + ' = null 
			WHERE QL_TypeQuota = 1'
			--print @QueryUpdate
			exec (@QueryUpdate) 
			set @n = @n + 1
		end
end

IF @ResultType is null or @ResultType not in (10)
BEGIN
	if (@bCommonRelease is not null and @bCommonRelease = 1)
	begin
		select *
		from #QuotaLoadList (nolock)
		order by
			(case
			when QL_QTID is not null then 1
			else 0
			end) DESC,
			QL_Description /*Сначала квоты, потом неквоты*/,QL_PartnerName,QL_Type DESC, 
			CONVERT(int,SUBSTRING(QL_Release,0,CHARINDEX('-',QL_Release))),
			--сортируем по первому числу продолжительности если продолжительность с "-",","," "
			case 
			when CHARINDEX('-',QL_DURATIONS) <>0 then CONVERT(int, REPLACE(QL_DURATIONS, '-', ''))
			when CHARINDEX(',',QL_DURATIONS) <>0 then CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX(',',QL_DURATIONS)))
			when CHARINDEX(' ',QL_DURATIONS) <>0 then CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX(' ',QL_DURATIONS)))
			when CHARINDEX('-',QL_DURATIONS) = 0 then CONVERT(int,QL_DURATIONS)
			end,
			QL_CityDepartments,QL_FilialKey,QL_CustomerInfo,QL_QTID,QL_DataType
		RETURN 0
	end
	else
	begin
		select *
		from #QuotaLoadList (nolock)
		order by
			(case
			when QL_QTID is not null then 1
			else 0
			end) DESC,
			QL_Description /*Сначала квоты, потом неквоты*/,QL_PartnerName,QL_Type DESC, CONVERT(int, QL_Release),
			--сортируем по первому числу продолжительности если продолжительность с "-",","," "
			case 
			--when CHARINDEX('-',QL_DURATIONS) <>0 then CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX('-',QL_DURATIONS)) + SUBSTRING(QL_DURATIONS,CHARINDEX('-',QL_DURATIONS) + 1, LEN(QL_DURATIONS) - CHARINDEX('-',QL_DURATIONS)))
			when CHARINDEX('-',QL_DURATIONS) <>0 then CONVERT(int, REPLACE(QL_DURATIONS, '-', ''))
			when CHARINDEX(',',QL_DURATIONS) <>0 then CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX(',',QL_DURATIONS)))
			when CHARINDEX(' ',QL_DURATIONS) <>0 then CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX(' ',QL_DURATIONS)))
			when CHARINDEX('-',QL_DURATIONS) = 0 then CONVERT(int,QL_DURATIONS)
			end,
			QL_CityDepartments,QL_FilialKey,QL_CustomerInfo,QL_QTID,QL_DataType
		RETURN 0
	end
END
ELSE
BEGIN --для наличия мест(из оформления)
	CREATE TABLE #ServicePlacesTr(
		SPT_QTID int, SPT_PRKey int, SPT_SubCode1 int, SPT_PartnerName varchar(100), SPT_Description varchar(255), 
		SPT_Type smallint, SPT_TypeQuota smallint, SPT_FilialKey int, SPT_CityDepartments int, SPT_Release int, SPT_Durations varchar(100),
		SPT_AgentKey int, SPT_Date smalldatetime, SPT_Places smallint, SPT_Stop smallint, SPT_CheckIn smallint)
	
	-- В MSSQL 2000 это не работает
	--ALTER TABLE #ServicePlacesTr ADD SPT_Date smalldatetime
	--ALTER TABLE #ServicePlacesTr ADD SPT_Places smallint
	--ALTER TABLE #ServicePlacesTr ADD SPT_Stop smallint
	--ALTER TABLE #ServicePlacesTr ADD SPT_CheckIn smallint


	set @n=1
	WHILE @n <= @DaysCount
	BEGIN
		DECLARE @curDate smalldatetime
		SET @curDate = DATEADD(DAY,@n-1,@DateStart)

		set @str = '
			INSERT INTO #ServicePlacesTr 
				(SPT_QTID, SPT_PRKey,SPT_SubCode1,SPT_PartnerName,SPT_Description,SPT_Type, SPT_TypeQuota,
				SPT_FilialKey,SPT_CityDepartments,SPT_Release,SPT_Durations,SPT_AgentKey,
				SPT_Date,SPT_Places) 
			SELECT QL_QTID, QL_PRKey,QL_SubCode1,QL_PartnerName, QL_Description, QL_Type, QL_TypeQuota,
				QL_FilialKey, QL_CityDepartments,QL_Release,QL_Durations,QL_AgentKey, 
				''' + CAST(@curDate as varchar(20)) + ''', QL_' + CAST(@n as varchar(3)) + '
				FROM #QuotaLoadList
				WHERE QL_dataType=21'
		exec (@str)

		set @str = 'UPDATE #ServicePlacesTr SET SPT_Stop=
					(SELECT QL_' + CAST(@n as varchar(3)) + '
					FROM #QuotaLoadList
					WHERE  QL_dataType=22 and 
					SPT_QTID=QL_QTID and
					SPT_PRKey=QL_PRKey and 
					ISNULL(SPT_SubCode1,-1)=ISNULL(QL_SubCode1,-1) and 
					SPT_PartnerName=QL_PartnerName and 
					SPT_Description=QL_Description and 
					SPT_Type=QL_Type and 
					SPT_TypeQuota = QL_TypeQuota and
					ISNULL(SPT_FilialKey,-1)=ISNULL(QL_FilialKey,-1) and 
					ISNULL(SPT_CityDepartments,-1)=ISNULL(QL_CityDepartments,-1) and 
					ISNULL(SPT_Release,-1)=ISNULL(QL_Release,-1) and 
					ISNULL(SPT_Durations,-1)=ISNULL(QL_Durations,-1) and 
					ISNULL(SPT_AgentKey,-1)=ISNULL(QL_AgentKey,-1) and 
					SPT_Date=''' + CAST(@curDate as varchar(20)) + ''')
					WHERE SPT_Date=''' + CAST(@curDate as varchar(20))+ ''''

		exec (@str)

		set @str = 'UPDATE #ServicePlacesTr SET SPT_CheckIn=
					(SELECT QL_' + CAST(@n as varchar(3)) + '
					FROM #QuotaLoadList
					WHERE  QL_dataType=23 and
					SPT_QTID=QL_QTID and 
					SPT_PRKey=QL_PRKey and 
					ISNULL(SPT_SubCode1,-1)=ISNULL(QL_SubCode1,-1) and 
					SPT_PartnerName=QL_PartnerName and 
					SPT_Description=QL_Description and 
					SPT_Type=QL_Type and
					SPT_TypeQuota = QL_TypeQuota and 
					ISNULL(SPT_FilialKey,-1)=ISNULL(QL_FilialKey,-1) and 
					ISNULL(SPT_CityDepartments,-1)=ISNULL(QL_CityDepartments,-1) and 
					ISNULL(SPT_Release,-1)=ISNULL(QL_Release,-1) and 
					ISNULL(SPT_Durations,-1)=ISNULL(QL_Durations,-1) and
					ISNULL(SPT_AgentKey,-1)=ISNULL(QL_AgentKey,-1) and 
					SPT_Date= ''' + CAST(@curDate as varchar(20)) + ''')
					WHERE SPT_Date=''' + CAST(@curDate as varchar(20)) + ''''

		exec (@str)
		set @n = @n + 1
	END
END

--Select * from #ServicePlacesTr 	ORDER BY  SPT_PRKey, SPT_Type, SPT_SubCode1, SPT_PartnerName, SPT_Description, SPT_FilialKey, SPT_CityDepartments, SPT_Date, SPT_Release

DECLARE @ServicePlaces TABLE
(
	SP_PRKey int, SP_SubCode1 int, SP_PartnerName nvarchar(100), SP_Description nvarchar(255), 
	SP_Type smallint, SP_TypeQuota smallint, SP_FilialKey int, SP_CityDepartments int, 
	SP_Places1 smallint, SP_Places2 smallint, SP_Places3 smallint, 
	SP_NonReleasePlaces1 smallint,SP_NonReleasePlaces2 smallint,SP_NonReleasePlaces3 smallint, 
	SP_StopPercent1 smallint,SP_StopPercent2 smallint,SP_StopPercent3 smallint
)

DECLARE @SPT_QTID int, @SPT_PRKey int, @SPT_SubCode1 int, @SPT_PartnerName varchar(100), @SPT_Description varchar(255), 
		@SPT_Type smallint, @SPT_TypeQuota smallint, @SPT_FilialKey int, @SPT_CityDepartments int, @SPT_Release smallint, @SPT_Date smalldatetime, 
		@SPT_Places smallint, @SPT_Stop smallint, @SPT_CheckIn smallint, @SPT_PRKey_Old int, @SPT_PartnerName_Old varchar(100), 
		@SPT_SubCode1_Old int, @SPT_Description_Old varchar(255), @SPT_Type_Old smallint, @SPT_TypeQuota_Old smallint, @SPT_FilialKey_Old int,
		@SPT_CityDepartments_Old int, @SPT_Date_Old smalldatetime,
		@currentPlaces1 smallint, @currentPlaces2 smallint, @currentPlaces3 smallint,
		@currentNonReleasePlaces1 smallint, @currentNonReleasePlaces2 smallint, @currentNonReleasePlaces3 smallint,
		@OblectPlacesMin1 smallint, @OblectPlacesMin2 smallint, @OblectPlacesMin3 smallint,
		@OblectNonReleasePlacesMin1 smallint, @OblectNonReleasePlacesMin2 smallint, @OblectNonReleasePlacesMin3 smallint,
		@stopPercentSum1 smallint,@stopPercentSum2 smallint,@stopPercentSum3 smallint,
		@quotaCounter1 smallint,@quotaCounter2 smallint,@quotaCounter3 smallint,
		@Now smalldatetime

SET @Now = GETDATE()
		
DECLARE curQ2 CURSOR FOR SELECT
			 SPT_QTID, SPT_PRKey, SPT_SubCode1, SPT_PartnerName, SPT_Description, SPT_Type, SPT_TypeQuota, SPT_FilialKey, 
			 SPT_CityDepartments, ISNULL(SPT_Release, 0), SPT_Date, ISNULL(SPT_Places, 0), ISNULL(SPT_Stop,0), SPT_CheckIn
	FROM	#ServicePlacesTr
	ORDER BY  SPT_PRKey DESC, SPT_Description DESC, SPT_Type DESC, SPT_TypeQuota DESC, SPT_Date DESC, SPT_SubCode1 DESC, SPT_PartnerName DESC, 
		SPT_FilialKey DESC, SPT_CityDepartments DESC, SPT_Places, SPT_Release DESC

OPEN curQ2
FETCH NEXT FROM curQ2 INTO @SPT_QTID, @SPT_PRKey, @SPT_SubCode1, @SPT_PartnerName, @SPT_Description, 
		@SPT_Type, @SPT_TypeQuota, @SPT_FilialKey, @SPT_CityDepartments, @SPT_Release, @SPT_Date, @SPT_Places, @SPT_Stop, @SPT_CheckIn	

SET @SPT_PRKey_Old=@SPT_PRKey
SET @SPT_Description_Old=@SPT_Description
SET @SPT_PartnerName_Old=@SPT_PartnerName
SET @SPT_Type_Old=@SPT_Type
SET @SPT_TypeQuota_Old=@SPT_TypeQuota
SET @SPT_Date_Old=@SPT_Date
SET @currentPlaces1=0
SET @currentPlaces2=0
SET @currentPlaces3=0
SET @currentNonReleasePlaces1=0
SET @currentNonReleasePlaces2=0
SET @currentNonReleasePlaces3=0
SET @stopPercentSum1=0
SET @stopPercentSum2=0
SET @stopPercentSum3=0
SET @quotaCounter1=0
SET @quotaCounter2=0
SET @quotaCounter3=0


WHILE @@FETCH_STATUS = 0
BEGIN
	IF @SPT_PRKey=@SPT_PRKey_Old and @SPT_Description=@SPT_Description_Old and ISNULL(@SPT_Type,-1)=ISNULL(@SPT_Type_Old,-1) and @SPT_Date!=@SPT_Date_Old
	BEGIN
		If (@OblectPlacesMin1 is null or @OblectPlacesMin1 > @currentPlaces1) AND @SPT_Date_Old BETWEEN @DateStart AND DATEADD(DAY,@ServiceLong-1,@DateStart)
		BEGIN
			--Set @quotaCounter1=0
			Set @OblectPlacesMin1=@currentPlaces1
			--Set @currentPlaces1=0
			Set @OblectNonReleasePlacesMin1=@currentNonReleasePlaces1
			--Set @currentNonReleasePlaces1=0
		END
		If (@OblectPlacesMin2 is null or @OblectPlacesMin2 > @currentPlaces2) AND @SPT_Date_Old BETWEEN @DateStart2 AND DATEADD(DAY,@ServiceLong-1,@DateStart2)
		BEGIN
			--Set @quotaCounter2=0
			Set @OblectPlacesMin2=@currentPlaces2
			--Set @currentPlaces2=0
			Set @OblectNonReleasePlacesMin2=@currentNonReleasePlaces2
			--Set @currentNonReleasePlaces2=0
		END
		If (@OblectPlacesMin3 is null or @OblectPlacesMin3 > @currentPlaces3) AND @SPT_Date_Old BETWEEN @DateStart3 AND DATEADD(DAY,@ServiceLong-1,@DateStart3)
		BEGIN
			--Set @quotaCounter3=0
			Set @OblectPlacesMin3=@currentPlaces3
			--Set @currentPlaces3=0
			Set @OblectNonReleasePlacesMin3=@currentNonReleasePlaces3
			--Set @currentNonReleasePlaces3=0
		END
-- При смене даты обнуляем текущие количества мест
		SET @currentPlaces1=0
		SET @currentPlaces2=0
		SET @currentPlaces3=0
		SET @currentNonReleasePlaces1=0
		SET @currentNonReleasePlaces2=0
		SET @currentNonReleasePlaces3=0
	END

	IF @SPT_PRKey!=@SPT_PRKey_Old or @SPT_Description!=@SPT_Description_Old or ISNULL(@SPT_Type,-1)!=ISNULL(@SPT_Type_Old,-1) or ISNULL(@SPT_TypeQuota,-1)!=ISNULL(@SPT_TypeQuota_Old,-1)
	BEGIN
		IF @quotaCounter1 = 0 SET @quotaCounter1 = 1
		IF @quotaCounter2 = 0 SET @quotaCounter2 = 1
		IF @quotaCounter3 = 0 SET @quotaCounter3 = 1
		INSERT INTO @ServicePlaces (SP_PRKey, SP_SubCode1, SP_PartnerName, SP_Description, SP_Type, SP_TypeQuota,
				SP_FilialKey, SP_CityDepartments, SP_Places1, SP_Places2, SP_Places3, 
				SP_NonReleasePlaces1, SP_NonReleasePlaces2, SP_NonReleasePlaces3,
				SP_StopPercent1,SP_StopPercent2,SP_StopPercent3)
		Values (@SPT_PRKey_Old, @SPT_SubCode1_Old, @SPT_PartnerName_Old, @SPT_Description_Old, @SPT_Type_Old, @SPT_TypeQuota_Old,
				@SPT_FilialKey_Old, @SPT_CityDepartments_Old, 
				@currentPlaces1, @currentPlaces2, @currentPlaces3,
				ISNULL(@OblectNonReleasePlacesMin1,@currentNonReleasePlaces1), ISNULL(@OblectNonReleasePlacesMin2,@currentNonReleasePlaces2), ISNULL(@OblectNonReleasePlacesMin3,@currentNonReleasePlaces3),
				@stopPercentSum1/@quotaCounter1,@stopPercentSum2/@quotaCounter2,@stopPercentSum3/@quotaCounter3)

		set @OblectPlacesMin1 = null
		set @OblectPlacesMin2 = null
		set @OblectPlacesMin3 = null
		set @OblectNonReleasePlacesMin1 = null
		set @OblectNonReleasePlacesMin2 = null
		set @OblectNonReleasePlacesMin3 = null
		Set @currentPlaces1=0
		Set @currentPlaces2=0
		Set @currentPlaces3=0
		Set @currentNonReleasePlaces1=0
		Set @currentNonReleasePlaces2=0
		Set @currentNonReleasePlaces3=0
		Set @stopPercentSum1=0
		Set @stopPercentSum2=0
		Set @stopPercentSum3=0
		Set @quotaCounter1=0
		Set @quotaCounter2=0
		Set @quotaCounter3=0
	END

	If @SPT_Date BETWEEN @DateStart AND DATEADD(DAY,@ServiceLong-1,@DateStart)
	BEGIN
			Set @quotaCounter1=@quotaCounter1+1
		Set @stopPercentSum1 = @stopPercentSum1 + @SPT_Stop
		Set @currentPlaces1=@currentPlaces1+@SPT_Places
		If @DateStart > DATEADD(DAY,@SPT_Release,@Now)
			Set @currentNonReleasePlaces1=@currentNonReleasePlaces1+@SPT_Places
	END
	If @SPT_Date BETWEEN @DateStart2 AND DATEADD(DAY,@ServiceLong-1,@DateStart2)
	BEGIN
			Set @quotaCounter2=@quotaCounter2+1
		Set @stopPercentSum2 = @stopPercentSum2 + @SPT_Stop
		Set @currentPlaces2=@currentPlaces2+@SPT_Places
		If @DateStart2 > DATEADD(DAY,@SPT_Release,@Now)
			Set @currentNonReleasePlaces2=@currentNonReleasePlaces2+@SPT_Places
	END
	If @SPT_Date BETWEEN @DateStart3 AND DATEADD(DAY,@ServiceLong-1,@DateStart3)
	BEGIN
			Set @quotaCounter3=@quotaCounter3+1
		Set @stopPercentSum3 = @stopPercentSum3 + @SPT_Stop
		Set @currentPlaces3=@currentPlaces3+@SPT_Places
		If @DateStart3 > DATEADD(DAY,@SPT_Release,@Now)
			Set @currentNonReleasePlaces3=@currentNonReleasePlaces3+@SPT_Places
	END

	SET @SPT_PRKey_Old=@SPT_PRKey
	SET @SPT_PartnerName_Old=@SPT_PartnerName
	SET @SPT_Description_Old=@SPT_Description
	SET @SPT_Type_Old=@SPT_Type
	SET @SPT_TypeQuota_Old=@SPT_TypeQuota
	SET @SPT_Date_Old=@SPT_Date
	FETCH NEXT FROM curQ2 INTO @SPT_QTID, @SPT_PRKey, @SPT_SubCode1, @SPT_PartnerName, @SPT_Description, 
			@SPT_Type, @SPT_TypeQuota, @SPT_FilialKey, @SPT_CityDepartments, @SPT_Release, @SPT_Date, @SPT_Places, @SPT_Stop, @SPT_CheckIn	

	If @@FETCH_STATUS != 0
	BEGIN
		IF @quotaCounter1 = 0 SET @quotaCounter1 = 1
		IF @quotaCounter2 = 0 SET @quotaCounter2 = 1
		IF @quotaCounter3 = 0 SET @quotaCounter3 = 1
		INSERT INTO @ServicePlaces (SP_PRKey, SP_SubCode1, SP_PartnerName, SP_Description, SP_Type, SP_TypeQuota,
			SP_FilialKey, SP_CityDepartments, SP_Places1, SP_Places2, SP_Places3, 
			SP_NonReleasePlaces1, SP_NonReleasePlaces2, SP_NonReleasePlaces3,
			SP_StopPercent1,SP_StopPercent2,SP_StopPercent3)
		Values (@SPT_PRKey_Old, @SPT_SubCode1_Old, @SPT_PartnerName_Old, @SPT_Description_Old, @SPT_Type_Old, @SPT_TypeQuota_Old,
			@SPT_FilialKey_Old, @SPT_CityDepartments_Old, 
			ISNULL(@OblectPlacesMin1,@currentPlaces1), ISNULL(@OblectPlacesMin2,@currentPlaces2), ISNULL(@OblectPlacesMin3,@currentPlaces3),
			ISNULL(@OblectNonReleasePlacesMin1,@currentNonReleasePlaces1), ISNULL(@OblectNonReleasePlacesMin2,@currentNonReleasePlaces2), ISNULL(@OblectNonReleasePlacesMin3,@currentNonReleasePlaces3),
			@stopPercentSum1/@quotaCounter1,@stopPercentSum2/@quotaCounter2,@stopPercentSum3/@quotaCounter3)
		END
END
CLOSE curQ2
DEALLOCATE curQ2

--select * from #ServicePlacesTr
--ORDER BY  SPT_PRKey, SPT_Type, SPT_SubCode1, SPT_PartnerName, SPT_Description, 
--		SPT_FilialKey, SPT_CityDepartments, SPT_Date, SPT_Release

--select * from #ServicePlaces


	select 
		SP_PRKey,SP_PartnerName,SP_Description,SP_SubCode1,SP_Type,SP_TypeQuota,SP_FilialKey,SP_CityDepartments,
		CAST(SP_Places1 as varchar(4))+';'+CAST(SP_NonReleasePlaces1 as varchar(4))+';'+CAST(SP_StopPercent1 as varchar(4)) as SP_1,
		CAST(SP_Places2 as varchar(4))+';'+CAST(SP_NonReleasePlaces2 as varchar(4))+';'+CAST(SP_StopPercent2 as varchar(4)) as SP_2,
		CAST(SP_Places3 as varchar(4))+';'+CAST(SP_NonReleasePlaces3 as varchar(4))+';'+CAST(SP_StopPercent3 as varchar(4)) as SP_3
	from @ServicePlaces
	order by SP_Description, SP_PartnerName, SP_Type, SP_TypeQuota
GO

GRANT EXECUTE ON [dbo].[GetQuotaLoadListData_N]	TO PUBLIC
GO
/*********************************************************************/
/* end sp_GetQuotaLoadListData_N.sql */
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
							ServiceDescription=LEFT((SELECT ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_NAMELAT,'') FROM Cabine WHERE CB_Key=DL_SubCode1),80)
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
/* begin sp_InsDogovor.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InsDogovor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure dbo.InsDogovor
GO
CREATE procedure [dbo].[InsDogovor]
(
--<VERSION>2005.2.38</VERSION>
@nReturn int output,
@nKeyDogovor int output,				-- возвращает ключ созданного договора
@sDogovor varchar (10) = null,			-- номер путевки, которую требуется создать
@dTour datetime = null,					-- дата заезда
@nDays int = null,						-- количество дней поездки
@nTour int = null,						-- ключ тура (TurList)
@nCountry int = null,					-- ключ страны (Country) 
@nCity int = null,						-- ключ города (CityDictionary)
@nMen smallint = null,					-- количество человек в путевке
@sRate varchar (3) = null,				-- код валюты путевки
@nPrice money = null,					-- стоимость (к оплате)
@nPayed money = null,					-- оплачено по путевке (МТ передает "0")
@nDiscount money = null,				-- размер скидки(комиссии) номинальный
@nDiscountKey int = null,				-- ключ скидки(комиссии)
@nPcnt smallint = null,					-- скидка в процентах (1-да, 0-нет)
@nDiscountSum money = null,				-- величина скидки (комиссии) в у.е.
@nCauseDiscount int = null,				-- ключ причины скидки (CauseDiscount)
@nAgent int = null,						-- ключ покупателя (Partners)
@nOper int = null,						-- ключ менеджера создавшего путевку (UserList)
@sOper varchar (25) = null,				-- имя менеджера создавшего путевку
@sMainMen varchar (45) = null,			-- контактное лицо. ФИО (лицо, заключившее договор)
@sMainMenPhone varchar (30) = null,		-- контактное лицо. телефон
@sMainMenAdress varchar (320) = null,	-- контактное лицо. адрес
@sMainMenPasport varchar (70) = null,	-- контактное лицо. паспорт
@nOwner int = null,						-- ключ ведущего менеджера по путевке (UserList)
@nStatus int = null,					-- статус по умолчанию (OrderStatus)  		- МТ передает 1 (не определен)
@nPrintVaucher smallint = null,			-- признак путевки. ваучер распечатан		- МТ передает 0 (не распечатан)
@nPrintDogovor smallint = null,			-- признак путевки. путевка распечатана	 	- МТ передает 0 (не распечатан)
@nAdvertiseKey int = null,				-- ключ справочника источник рекламы (Advertisment) 
@nLocked smallint = null,				-- признак путевки. путевка заблокирована 	- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@dVisaDate datetime = null,				-- дата сдачи документов для визы 		- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@dPaymentDate datetime = null,			-- дата полной оплаты 				- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@dPPaymentDate datetime = null,			-- дата предоплаты				- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@nRazmerPPayment int = null,			-- размер предоплаты 				- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@nPercentPPayment int = null,			-- предоплата в % (1-да, 0-нет)			- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@sDocument varchar (250) = null,		-- принятые документы (текстовое поле)		- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@nLeadDepartmentKey int = null,			-- ключ ведущего отдела (PrtDeps)	

@sMainMenEMail varchar (250) = null,	-- контактное лицо. e-mail
@sMainMenComment varchar (250) = null,	-- контактное лицо. комментарий
@nDupUserKey int = null,				-- менеджер покупателя (Dup_User)
@nBookingTypeKey int = null,			-- система бронирования (0-МТ, 1-MW) 		- МТ передает 0

@nPartnerDogovorKey int = null,			-- ключ договора партнера
@nCityDepartureKey int = null,			-- ключ города вылета
@nFilialKey int = null,					-- ключ филиала, к которому будет привязана путевка (если Null, то получит филиал ведущего менеджера)
@sOldDogovor varchar (10) = null		-- не использовать для переименования используйте ХП RenameDogovor
)
as
declare @nCount int
declare @sKeyTable varchar (11)
declare @sMode varchar (3)
declare @sText varchar (80)
declare @sValue varchar(254)
declare @dtCurrentDate DateTime
declare @sOperID varchar(255)
declare @nOperLeadDepartmentKey int
declare @sOperLat varchar(25)
declare @nDatePayed_Local int
declare @nDefaultProcent int
declare @nAgentDogovorGlobalType int
declare @nOperLeadFilialKey int

set @sDocument = RTRIM(LTRIM(@sDocument))
Select @nCount = count(*) from Dogovor where DG_Code=@sDogovor
if @nCount > 0
BEGIN
	set @nReturn = 1
	return 0
END

-- AleXK обнуляем статус путевки. При создани путевки он должен быть "В работе" т.е 0
set @nStatus = 0

if @nKeyDogovor > 0 and @sOldDogovor != ''
BEGIN
	set @sMode = 'REN'
	Select @nFilialKey = DG_FilialKey from Dogovor where DG_Code = @sOldDogovor
END 
ELSE BEGIN
	set @sMode = 'BEG'
	IF (@nKeyDogovor <= 0 or @nKeyDogovor is null)
	BEGIN
		set @nKeyDogovor = 0
		set @sKeyTable = 'KEY_DOGOVOR'
		exec dbo.GETNEWKEY @sKeyTable, @nKeyDogovor output
	END

	IF @nKeyDogovor > 0
		set @nReturn = 0
	ELSE BEGIN
		set @nReturn = 1
		return 0
	END
END

if @nBookingTypeKey=1
BEGIN
	if (ISNULL(@nCityDepartureKey,0)=0) and (@nTour > 0)
		Select @nCityDepartureKey=TL_CTDepartureKey from TurList where TL_Key=@nTour
	if (ISNULL(@nPartnerDogovorKey,0)=0) and @nAgent>0
		Select top 1 @nPartnerDogovorKey=PD_Key from PrtDogs where PD_Key > 0 AND PD_PRKEY = @nAgent AND 
			(PD_DateBeg <= GetDate() OR PD_DateBeg is null) AND ((PD_DateEnd+1) >= GetDate() OR PD_DateEnd is null)
			ORDER BY PD_IsDefault DESC, PD_UpdDate DESC
END
set @nPartnerDogovorKey = ISNULL(@nPartnerDogovorKey,0)

If @sMode = 'BEG'
BEGIN
	Select @dtCurrentDate = GETDATE()
	SET @sRate = LTRIM(RTRIM(@sRate) )

	Exec dbo.GetUserKey @nOper output	
	Exec dbo.GetUserInfo @sOperID output, @nOper output, @sOper output, @nOperLeadFilialKey output, @nOperLeadDepartmentKey output, @sOperLat output
	If @nFilialKey is null or @nFilialKey = 0
		Set @nFilialKey = @nOperLeadFilialKey
	SET @sOper = LTRIM(RTRIM(@sOper) )
	SET @sMainMen = LTRIM(RTRIM(@sMainMen) )
	SET @sMainMenPhone = LTRIM(RTRIM(@sMainMenPhone) )
	SET @sMainMenAdress = LTRIM(RTRIM(@sMainMenAdress) )
	SET @sMainMenPasport = LTRIM(RTRIM(@sMainMenPasport) )
	SET @sMainMenEMail = LTRIM(RTRIM(@sMainMenEMail) )
	SET @sMainMenComment = LTRIM(RTRIM(@sMainMenComment) )

	If (@dPaymentDate is NULL or @nRazmerPPayment is NULL) and @nTour > 0
	BEGIN
		SELECT 	@nDatePayed_Local = TL_DatePayed, 
			@nDefaultProcent = TL_DfltPaymentPcnt
		FROM	TurList 
		WHERE	TL_Key=@nTour
	
		if @dPaymentDate is NULL
		begin
			if (GETDATE() + @nDatePayed_Local) >= @dTour
			begin
				Set @dPaymentDate = CONVERT(CHAR(10), @dTour - 1, 102)
			end
			else
			begin
				Set @dPaymentDate = CONVERT(CHAR(10), GETDATE() + @nDatePayed_Local, 102)
			end
		end

		If @nRazmerPPayment is NULL
		BEGIN
			Set @nRazmerPPayment = @nDefaultProcent
			Set @nPercentPPayment = 1
		END
	END	

	declare @da_key int
	if @nDiscountKey is not null and @nDiscountKey <> 0 and @nDiscountKey <> -1
	begin
		set @da_key = null
		select @da_key = DS_DAKey from Discounts where DS_Key = @nDiscountKey
	end

	SELECT	@nAgentDogovorGlobalType = PDT_Type FROM dbo.PrtDogs, dbo.PrtDogTypes WHERE PD_Key = @nPartnerDogovorKey and PD_DogType = PDT_ID
	SET @nAgentDogovorGlobalType = ISNULL(@nAgentDogovorGlobalType, 0)

	Insert into dbo.tbl_Dogovor (DG_Key,DG_Code,DG_TurDate,DG_CnKey,DG_CtKey,
			DG_NMen,DG_Rate,DG_Price,DG_NDay,DG_PartnerKey,
			DG_PrtDogKey,DG_Operator,DG_Payed,DG_MainMen,DG_MainMenPhone,
			DG_MainMenAdress,DG_MainMenPasport,DG_Discount,DG_TypeCount,DG_DiscountSum,
			DG_CauseDisc,DG_TrKey,DG_PrintDogovor,DG_PrintVaucher,DG_Owner,
			DG_Creator,DG_CrDate,DG_sor_code,DG_ADVERTISE,DG_LOCKED,
			DG_VISADATE,DG_PAYMENTDATE,DG_PPAYMENTDATE,DG_RAZMERP,DG_PROCENT,
			DG_DOCUMENT,DG_FilialKey, DG_LeadDepartment, DG_MainMenComment, DG_MAINMENEMAIL, 
			DG_DupUserKey, DG_BTKey, DG_CTDepartureKey, DG_PDTType, DG_DAKey)
	Values (@nKeyDogovor, @sDogovor, @dTour, @nCountry, @nCity, 
			@nMen, @sRate, @nPrice, @nDays,	@nAgent, 
			@nPartnerDogovorKey, @sOper, @nPayed, @sMainMen, @sMainMenPhone, 
			@sMainMenAdress, @sMainMenPasport,@nDiscount, @nPcnt, @nDiscountSum, 
			@nCauseDiscount, @nTour, @nPrintDogovor, @nPrintVaucher, @nOwner, 
			@nOper,	@dtCurrentDate, @nStatus, @nAdvertiseKey, @nLocked, 
			@dVisaDate, @dPaymentDate, @dPPaymentDate, @nRazmerPPayment, @nPercentPPayment, 
			@sDocument, @nFilialKey, @nLeadDepartmentKey, @sMainMenComment, @sMainMenEMail, 
			@nDupUserKey, @nBookingTypeKey, @nCityDepartureKey, @nAgentDogovorGlobalType, @da_key)

	declare @sHI_WHO varchar(25)
	exec dbo.CurrentUser @sHI_WHO output

	--пишем ключ акции в историю
		if @da_key is not null
		begin
			if (select count(*) from dbo.history where HI_DGCOD = @sDogovor and HI_OAId = 25) > 0
			begin
				delete from dbo.history where HI_DGCOD = @sDogovor and HI_OAId = 25
			end

			insert into dbo.history
			(HI_DGCOD, HI_WHO, HI_TEXT, HI_REMARK, HI_MOD, HI_TYPE, HI_OAId)
			values
			(@sDogovor, @sHI_WHO, cast(@da_key as varchar), 'Ключ акции', 'INS', 'DA_KEY', 25)
		end


	if @@error = 0
		set @nReturn = 0
	else
		set @nReturn = 2

	set @sText = N'Создание путевки'
	--EXEC dbo.InsertHistory @sDogovor, '', @sMode, @sText, ''

	Update Partners set PR_DateLastContact = GETDATE() WHERE PR_Key = @nAgent

	exec InsMasterEvent 1, @nKeyDogovor
END
Else if @sMode = 'REN'
BEGIN
	/*
	set @sText = N'Переименование путевки с'+@sOldDogovor+' на '+@sDogovor
	set @sMode = 'REN'
	EXEC dbo.InsertHistory @sDogovor, '', @sMode, @sText, ''
	*/
	Update Dogovorlist set DL_DgCod = @sDogovor where DL_Dgcod = @sOldDogovor
	Update tbl_Turist set TU_DgCod = @sDogovor where TU_Dgcod = @sOldDogovor
	Update History set HI_DgCod = @sDogovor where HI_Dgcod = @sOldDogovor
	Update PrintDocuments set DC_DgCod = @sDogovor where DC_DgCod = @sOldDogovor
	Update SendMail set SM_DgCode = @sDogovor where SM_DgCode = @sOldDogovor
	Update BillsDogovor set BD_DgCod = @sDogovor where BD_DgCod = @sOldDogovor
	Update Accounts set AC_DgCod=@sDogovor where AC_DgCod=@sOldDogovor
	
	if exists(select st_version from setting where st_version like '5.2%')
	begin
		Update Orders set OR_Dogovor = @sDogovor where OR_Dogovor = @sOldDogovor
		Update OrderHistory set OH_DgCod = @sDogovor where OH_DgCod = @sOldDogovor
	end

	Update Dogovor set DG_Code = @sDogovor where DG_Code = @sOldDogovor
	if @@error = 0
		set @nReturn = 0
END
return 0
GO

GRANT EXECUTE ON dbo.InsDogovor TO PUBLIC 
GO
/*********************************************************************/
/* end sp_InsDogovor.sql */
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
		where rdp_date < DATEADD(MONTH, -1, @today)

		if not exists(select top 1 1 from mwReplDeletedPricesTemp)
		begin
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
/* begin sp_mwClearOldData.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCleanerQuotes]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwCleanerQuotes]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwClearOldData]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwClearOldData]
GO

CREATE PROCEDURE [dbo].[mwClearOldData]
	(
		-- хранимка удаления устаревших квто на поисковой базе
		-- дата с которой считается что квоты устарели
		@oldDate datetime = null,
		-- размер пачки на удаление
		@countRowDeleted int = 10000
	)
AS
BEGIN

	--<VERSION>2009.2.21</VERSION>
	--<DATE>2014-02-10</DATE>

	if (@oldDate is null)
	begin
		set @oldDate = dateadd(day, -1, getdate());
	end

	-- чистим ServiceByDate
	while (1 = 1)
	begin
		delete top (@countRowDeleted) ServiceByDate
		from ServiceByDate
		where SD_Date < @oldDate
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end
	
	-- чистим quotaLimitation
	while (1 = 1)
	begin
		delete top (@countRowDeleted) QuotaLimitations 
		from QuotaLimitations
		where QL_QPID in (select QP_Id from QuotaParts with (nolock) where QP_Date < @oldDate)
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end
	
	-- чистим QuotaParts
	while (1 = 1)
	begin
		delete top (@countRowDeleted) QuotaParts 
		from QuotaParts
		where QP_Date < @oldDate
		and not exists (select top 1 1 from QuotaLimitations with (nolock) where QL_QPID = QP_ID)
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end
	
	-- чистим StopSales
	while (1 = 1)
	begin
		delete top (@countRowDeleted) StopSales 
		from StopSales
		where SS_Date < @oldDate
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end
	
	-- чистим QuotaDetailes
	while (1 = 1)
	begin
		delete top (@countRowDeleted) QuotaDetails 
		from QuotaDetails
		where QD_Date < @oldDate
		and not exists (select top 1 1 from StopSales with (nolock) where SS_QDID = QD_Id)
		and not exists (select top 1 1 from QuotaParts with (nolock) where QP_QDID = QD_Id)
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end

	-- чистим QuotaObjects
	while (1 = 1)
	begin
		delete top (@countRowDeleted) QuotaObjects 
		from QuotaObjects
		where not exists (select 1 from StopSales where SS_QOID = QO_ID)
		and not exists (select 1 from QuotaDetails where QD_QTID = QO_QTID)
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end

	-- чистим Quotas
	while (1 = 1)
	begin
		delete top (@countRowDeleted) Quotas 
		from Quotas
		where not exists (select 1 from QuotaObjects where QO_QTID = QT_ID)
		and not exists (select 1 from QuotaDetails where QD_QTID = QT_ID)
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end

	-- чистим tbl_Costs
	while (1 = 1)
	begin
		delete top (@countRowDeleted) tbl_Costs 
		from tbl_Costs 
		where (CS_DATEEND is null or CS_DATEEND < @oldDate)
		and (CS_CHECKINDATEEND is null or CS_CHECKINDATEEND < @oldDate)
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end

	-- чистим AirSeason
	while (1 = 1)
	begin
		delete top (@countRowDeleted) AirSeason
		from AirSeason 
		where AS_DATETO < @oldDate
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end

END
GO

GRANT EXEC on [dbo].[mwClearOldData] to public
GO
/*********************************************************************/
/* end sp_mwClearOldData.sql */
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
--<DATE>2014-02-18</DATE>
---<VERSION>9.2.21.7</VERSION>
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
/* begin sp_ReCalculate_ViewHotelCost.sql */
/*********************************************************************/
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_ViewHotelCost]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_ViewHotelCost]
GO
CREATE PROCEDURE [dbo].[ReCalculate_ViewHotelCost]
(
	--хранимка выводит информацию о ценах на отель по набору заданных параметров, либо по ключам цен
	--<version>2009.2.09</version>
	--<data>2014-02-14</data>
	@departureKey int,										-- ключ города вылета
	@tourKey int = null,									-- ключ тура
	@hotelKeys xml ([dbo].[ArrayOfInt]) = null,				-- ключ отеля
	@checkinDateBegin datetime = null,						-- дата начала заезда
	@checkinDateEnd datetime = null,						-- дата начала заезда
	@roomKeys xml ([dbo].[ArrayOfInt]) = null,				-- ключ типа комнаты
	@roomCategoryKeys xml ([dbo].[ArrayOfInt]) = null,		-- ключ категории номера
	@accommodationKeys xml ([dbo].[ArrayOfInt]) = null,		-- ключ размещения
	@pansionKeys xml ([dbo].[ArrayOfInt]) = null,			-- ключ питания
	@longList xml ([dbo].[ArrayOfShort]) = null,			-- продолжительности
	@weekDays nvarchar(7) = null,							-- дни недели
	@agentCommission money = null,							-- процент агентской коммисии
	@IsChangePriceOnly bit = null,							-- только с измененными ценами
	@IsDeletePriceOnly bit = null,							-- только с удаленными ценами
	@isHideAccommodationWithAdult bit = null,				-- только размещения без доп. мест
	@IsOnlineOnly bit = null,								-- только выставленные в интернет туры
	@priceKeys xml ([dbo].[ArrayOfLong]) = null,			-- ключи цен, передаваемые из плагина MarginMonitor
	@IsWholeHotel bit = 1                                   -- 1 - поиск по всему отелю, 0 - по категориям номеров
)
AS
BEGIN
	declare @beginTime datetime
	declare @tpKeys nvarchar(max)

	declare @hotelRoomsTable table
	(
		SC_Id int,
		SC_Code int,
		SC_SubCode1 int,
		SC_SubCode2 int,
		SC_PRKey int,
		HR_RMKEY int,
		HR_ACKEY int,
		HR_RCKEY int
	)

	if (@priceKeys is not null)
	begin
	    SET ARITHABORT OFF;
		SET DATEFIRST 1;
		set nocount on;

		declare @tablePriceKeysTable table (xPriceKey bigint)
		insert into @tablePriceKeysTable(xPriceKey)
		select tbl.res.value('.', 'bigint') 
		from @priceKeys.nodes('/ArrayOfLong/long') as tbl(res)
		
		set @beginTime = getdate()
		-- актуализируем цены по отобранным турам
		set @tpKeys = ''
		select @tpKeys = @tpKeys + convert(nvarchar(max), PC_TPKey) + ', '
		from TP_PriceComponents WITH(NOLOCK)
		where PC_Id in (select xPriceKey from @tablePriceKeysTable)
		declare @tmp table(tpKey bigint, newPrice money)
		-- делаем инсерт во веременную таблицу, что бы результата не выводился при запуске этой хранимки
		insert into @tmp (tpKey, newPrice)
		exec ReCalculate_CheckActualPrice @tpKeys
		print 'exec ReCalculate_CheckActualPrice ' + '''' +  @tpKeys + ''''
		print 'Расчитываем изменения в ценах: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))

		insert into @hotelRoomsTable(SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY)
		select distinct SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY
		from tp_serviceComponents with(nolock)
		inner join hotelRooms with(nolock) on SC_SubCode1 = HR_KEY
		inner join tp_serviceCalculateParametrs with(nolock) on sc_id=scp_scid
		where tp_serviceCalculateParametrs.scp_id in
		(
			select scpid_1  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_2  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_3  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_4  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_5  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_6  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_7  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_8  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_9  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_10 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_11 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_12 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_13 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_14 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_15 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
		)
		
		-- таблица с перелетами
		declare @chartersTable table
		(
			xIsForward bit,    -- 1-прямой перелет    0-обратный
			xTS_TIKey bigint,
			xCH_Key bigint,
			xTS_SubCode1 bigint,
			xTS_PKKey bigint,
			xTS_CityKeyFrom bigint,
			xTS_CityKeyTo bigint,
			xCharterDate datetime,
			xCH_PortCodeFrom varchar(4)
		)
		
		-- берем прямые и обратные перелеты
		insert into @chartersTable
		(xIsForward, xTS_TIKey, xCH_Key, xTS_SubCode1, xTS_PKKey, xTS_CityKeyFrom, xTS_CityKeyTo, xCharterDate, xCH_PortCodeFrom)
		select distinct
			case TS_Day when 1 then 1 else 0 end,
			PC_TIKey, TS_Code, TS_SubCode1, TS_OpPacketKey, TS_SubCode2, TS_CTKey,
			case TS_Day when 1 then PC_TourDate else PC_TourDate + PC_Days - 1 end,
			CH_PORTCODEFROM
		from TP_PriceComponents with(nolock)
		join TP_ServiceLists sl with(nolock) on sl.TL_TIKey = PC_TIKey
		join TP_Services cs with(nolock) on sl.TL_TSKey = cs.TS_Key and cs.TS_SVKey = 1
		join Charter ch with(nolock) on ch.CH_KEY = TS_Code
		where
		    (PC_Id in (select xPriceKey from @tablePriceKeysTable)) and
		    (TS_SVKey = 1) and ((TS_Day = 1) or (TS_Day = PC_Days))  -- перелеты на первый или последний день
		
		-- подбор подходящих перелетов
        --select * from @chartersTable
		declare @addChartersTable table  -- таблица с дополнительными перелетами
		(
			xCHKey bigint,
			xAddChKey bigint,
			xAddFlight varchar(4),
			xAddAirlineCode varchar(3),
			xCharterDate datetime,
			xTS_SubCode1 bigint,
			xTS_PKKey bigint,
			xOrder int default 1,
			xAS_Week varchar(7),
			xAS_TimeFrom datetime
		)
		
		insert into @addChartersTable(xCHKey, xAddChKey, xAddFlight, xAddAirlineCode, xCharterDate, xTS_SubCode1, xTS_PKKey, xAS_Week, xAS_TimeFrom)
		select distinct xCH_Key, CH_Key, CH_FLIGHT, CH_AIRLINECODE, xCharterDate, xTS_SubCode1, xTS_PKKey, AS_WEEK, AS_TimeFrom
		from AirSeason with(nolock), Charter with(nolock), Costs with(nolock), @chartersTable
		where
			CH_CityKeyFrom = xTS_CityKeyFrom and
			CH_CityKeyTo = xTS_CityKeyTo and
			CS_Code = CH_Key and
			AS_CHKey = CH_Key and
			CS_SVKey = 1 and
			(	isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = CS_SubCode1), '')
				= 
				isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = xTS_SubCode1), '')
			) and
			CS_PKKey = xTS_PKKey and
			xCharterDate between AS_DateFrom and AS_DateTo and
			xCharterDate between CS_Date and CS_DateEnd and
			AS_Week LIKE '%'+cast(datepart(weekday, xCharterDate)as varchar(1))+'%' and
			(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, xCharterDate)as varchar(1))+'%')
			
		-- для сортировки рейсов
		update @addChartersTable
		set xOrder = 0             -- чтобы рейс тура был первым
		where xCHKey = xAddChKey

        --select * from @addChartersTable

		declare @addChartersTableString table
		(
			xCHKey bigint,                 -- исходный перелет
			xAddChKeyString varchar(5000), -- список доп. перелетов через запятую (включая исходный)
			xCharterDate datetime,
			xTS_SubCode1 bigint,
			xTS_PKKey bigint,
			xAS_Week varchar(7),
			xAS_TimeFrom varchar(5000)
		)

		-- все доп. перелеты соединяем через запятую в одну строку
		insert into @addChartersTableString(xCHKey, xCharterDate, xTS_SubCode1, xTS_PKKey, xAS_Week, xAddChKeyString, xAS_TimeFrom)
		select distinct t1.xCHKey, t1.xCharterDate, t1.xTS_SubCode1, t1.xTS_PKKey,
			-- xAS_Week
			(select top 1 xAS_Week
			from @addChartersTable t2
			where (t2.xCHKey = t1.xCHKey) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
			order by len(xAS_Week) - len(replace(xAS_Week, '.', '')) desc),
		 	-- xAS_TimeFrom
			(select xAddAirlineCode + xAddFlight + ', '
		    from @addChartersTable t2
		    where (t2.xCHKey = t1.xCHKey) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
		    order by xOrder asc, xAddAirlineCode + xAddFlight asc
		    for xml path('')),
		    -- xAddAirlineCode + xAddFlight
		    (select SUBSTRING(CONVERT(VARCHAR(8), xAS_TimeFrom, 108),0,6) + ', '
		    from @addChartersTable t2
		    where (t2.xCHKey = t1.xCHKey) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
		    order by xOrder asc, xAddAirlineCode + xAddFlight asc
		    for xml path(''))
		from @addChartersTable t1
		
		-- избавляемся от хвостовых запятых
		update @addChartersTableString
		set xAddChKeyString = LEFT(xAddChKeyString, LEN(xAddChKeyString) - 1),
		    xAS_TimeFrom = LEFT(xAS_TimeFrom, LEN(xAS_TimeFrom) - 1)

        --select * from @addChartersTableString
        
		SET ANSI_WARNINGS OFF;
		select distinct PC_Id, PC_TPKey, PC_TourDate, SCP_Date, SC_Code, SC_SubCode1, HR_RMKEY, HR_ACKEY, HR_RCKEY, SC_SubCode2, SC_PRKey,
		PC_Days, SCP_Days, SCP_Men, PC_TOKey, PC_SummPrice, TO_TRKey, TO_Name, TO_Rate, TO_IsEnabled,
		AddCostIsCommission_1,  AddCostNoCommission_1,  CommissionOnly_1,  Gross_1,  IsCommission_1,  MarginPercent_1,  SCPId_1,  SVKey_1,
		AddCostIsCommission_2,  AddCostNoCommission_2,  CommissionOnly_2,  Gross_2,  IsCommission_2,  MarginPercent_2,  SCPId_2,  SVKey_2,
		AddCostIsCommission_3,  AddCostNoCommission_3,  CommissionOnly_3,  Gross_3,  IsCommission_3,  MarginPercent_3,  SCPId_3,  SVKey_3,
		AddCostIsCommission_4,  AddCostNoCommission_4,  CommissionOnly_4,  Gross_4,  IsCommission_4,  MarginPercent_4,  SCPId_4,  SVKey_4,
		AddCostIsCommission_5,  AddCostNoCommission_5,  CommissionOnly_5,  Gross_5,  IsCommission_5,  MarginPercent_5,  SCPId_5,  SVKey_5,
		AddCostIsCommission_6,  AddCostNoCommission_6,  CommissionOnly_6,  Gross_6,  IsCommission_6,  MarginPercent_6,  SCPId_6,  SVKey_6,
		AddCostIsCommission_7,  AddCostNoCommission_7,  CommissionOnly_7,  Gross_7,  IsCommission_7,  MarginPercent_7,  SCPId_7,  SVKey_7,
		AddCostIsCommission_8,  AddCostNoCommission_8,  CommissionOnly_8,  Gross_8,  IsCommission_8,  MarginPercent_8,  SCPId_8,  SVKey_8,
		AddCostIsCommission_9,  AddCostNoCommission_9,  CommissionOnly_9,  Gross_9,  IsCommission_9,  MarginPercent_9,  SCPId_9,  SVKey_9,
		AddCostIsCommission_10, AddCostNoCommission_10, CommissionOnly_10, Gross_10, IsCommission_10, MarginPercent_10, SCPId_10, SVKey_10,
		AddCostIsCommission_11, AddCostNoCommission_11, CommissionOnly_11, Gross_11, IsCommission_11, MarginPercent_11, SCPId_11, SVKey_11,
		AddCostIsCommission_12, AddCostNoCommission_12, CommissionOnly_12, Gross_12, IsCommission_12, MarginPercent_12, SCPId_12, SVKey_12,
		AddCostIsCommission_13, AddCostNoCommission_13, CommissionOnly_13, Gross_13, IsCommission_13, MarginPercent_13, SCPId_13, SVKey_13,
		AddCostIsCommission_14, AddCostNoCommission_14, CommissionOnly_14, Gross_14, IsCommission_14, MarginPercent_14, SCPId_14, SVKey_14,
		AddCostIsCommission_15, AddCostNoCommission_15, CommissionOnly_15, Gross_15, IsCommission_15, MarginPercent_15, SCPId_15, SVKey_15,
		-- PortFrom
		xCH_PORTCODEFROM as CH_PORTCODEFROM,
		-- Flight
		(select top 1 act.xAddChKeyString from @addChartersTableString act
		where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1))
		as CH_FLIGHT,
		-- Week
		(select top 1 act.xAS_Week from @addChartersTableString act
		where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1))
		as AS_WEEK,
        -- TimeFrom
        (select top 1 act.xAS_TimeFrom from @addChartersTableString act
		where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1))
		as AS_TIMEFROM,
		-- SeatsFree
		(select sum(qp.QP_Places - qp.QP_Busy)
		from QuotaDetails qd with(nolock)
		join QuotaParts qp with(nolock) on qp.QP_QDID = qd.QD_ID
		join QuotaObjects qo with(nolock) on qo.QO_QTID = qd.QD_QTID
		where (qo.QO_SVKey = 1) and (qo.QO_SubCode1 = xTS_SubCode1) and (qd.QD_Date = PC_TourDate) and (isnull(qp.QP_IsDeleted,0) = 0) and (isnull(qp.QP_AgentKey,0) = 0) and
			   qo.QO_Code in (select act.xAddChKey from @addChartersTable act
			                  where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1)))
		as SeatsFree,
		-- Cax
		(select sum(qp.QP_Places)
		from QuotaDetails qd with(nolock)
		join QuotaParts qp with(nolock) on qp.QP_QDID = qd.QD_ID
		join QuotaObjects qo with(nolock) on qo.QO_QTID = qd.QD_QTID
		where (qo.QO_SVKey = 1) and (qo.QO_SubCode1 = xTS_SubCode1) and (qd.QD_Date = PC_TourDate) and (isnull(qp.QP_IsDeleted,0) = 0) and (isnull(qp.QP_AgentKey,0) = 0) and
			   qo.QO_Code in (select act.xAddChKey from @addChartersTable act
			                  where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1)))
		as Cax,
		-- SeatsFreeBackCharters
		(select sum(qp.QP_Places - qp.QP_Busy)
		from QuotaDetails qd with(nolock)
		join QuotaParts qp with(nolock) on qp.QP_QDID = qd.QD_ID
		join QuotaObjects qo with(nolock) on qo.QO_QTID = qd.QD_QTID
		where (qo.QO_SVKey = 1) and (qo.QO_SubCode1 = xTS_SubCode1) and (qd.QD_Date = PC_TourDate + PC_Days - 1) and (isnull(qp.QP_IsDeleted,0) = 0) and (isnull(qp.QP_AgentKey,0) = 0) and
			   qo.QO_Code in (select act.xAddChKey from @addChartersTable act
			                  where (act.xCharterDate = PC_TourDate + PC_Days - 1) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1) and
			                        (act.xCHKey = (select top 1 xCH_Key from @chartersTable
			                                       where xTS_TIKey = PC_TIKey and xIsForward = 0 and xCharterDate = PC_TourDate + PC_Days - 1))))
		as SeatsFreeBackCharters,
		-- RoomsAll
		dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 1, PC_TourDate, hs.TS_Code, NULL, PC_Days, HR_RCKEY)
		as RoomsAll,
		-- RoomsSold
		dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 0, PC_TourDate, hs.TS_Code, NULL, PC_Days, HR_RCKEY)
		as RoomsSold,
		-- Commitment Rooms
		dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 1, PC_TourDate, hs.TS_Code, 2, PC_Days, HR_RCKEY)
		as CommitmentRooms,
		-- StopSale
		(SELECT TOP 1 'S' FROM StopSales ss with(nolock)
 	     INNER JOIN QuotaObjects qo with(nolock) ON qo.QO_ID = ss.SS_QOID
 	     WHERE
 	       ISNULL(ss.SS_IsDeleted, 0) = 0
 	       AND ss.SS_Date BETWEEN (PC_TourDate + hs.TS_Day - 1) AND (PC_TourDate + hs.TS_Day - 1 + hs.TS_Days - 1)
		   AND qo.QO_SVKey = 3
		   AND qo.QO_Code = SC_Code
		   AND (qo.QO_SubCode1 = HR_RMKEY OR qo.QO_SubCode1 = 0)
		   AND (qo.QO_SubCode2 = HR_RCKEY OR qo.QO_SubCode2 = 0))
		as StopSale
		from TP_PriceComponents with(nolock)
		join TP_Tours with(nolock) on TO_Key = PC_TOKey
		join TP_ServiceCalculateParametrs with(nolock) on SCPId_1 = SCP_Id
		join @hotelRoomsTable on SCP_SCId = SC_Id
		join TP_ServiceLists sl with(nolock) on sl.TL_TIKey = PC_TIKey
		join TP_Services hs with(nolock) on sl.TL_TSKey = hs.TS_Key and hs.TS_SVKey = 3 and hs.TS_Code = SC_Code
		left join @chartersTable on xTS_TIKey = PC_TIKey
		where
			PC_Id in (select xPriceKey from @tablePriceKeysTable) and
			(xIsForward is null or xIsForward = 1 and xCharterDate = PC_TourDate) and
			-- чтобы при обновлении грида (например после снятия цены) выставленные/невыставленные цены корректно обрабатывались, в зависимости от значения фильтра
			(@IsOnlineOnly is null or (@IsOnlineOnly = case when PC_SummPrice is null then 0 else TO_IsEnabled end))
	end
	else
	begin
		SET ARITHABORT ON;
		SET DATEFIRST 1;
		set nocount on;
		
		set @beginTime = getDate()

		declare @hotelService int, @aviaService int
		set @hotelService = 3
		set @aviaService = 1
		
		declare @tableHotelKeys table
		(
			xHotelKey int
		)	
		insert into @tableHotelKeys(xHotelKey)
		select tbl.res.value('.', 'int') 
		from @hotelKeys.nodes('/ArrayOfInt/int') as tbl(res)
		
		print 'Парсинг @hotelKeys: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		declare @tableLongList table
		(
			xLong int
		)
		insert into @tableLongList(xLong)
		select tbl.res.value('.', 'smallint') 
		from @longList.nodes('/ArrayOfShort/short') as tbl(res);
		
		print 'Парсинг @longList: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		set @tpKeys = ''
		
		select @tpKeys = @tpKeys + CONVERT(nvarchar(max), TP_Key) + ','
		from TP_Prices 
		where (TP_TOKey is null or TP_TOKey = @tourKey)
		and TP_DateBegin between isnull(@checkinDateBegin, TP_DateBegin) and isnull(@checkinDateEnd, TP_DateBegin)
		and (@weekDays is null or (@weekDays like '%' + convert(nvarchar(1), datepart(dw, TP_DateBegin)) + '%'))
		and TP_TIKey in (select ti_key from TP_Lists where TI_DAYS in (select xLong from @tableLongList)
							and ti_ctkeyfrom = ISNULL(@departureKey,0)
							and TI_FIRSTHDKEY in (select xHotelKey from @tableHotelKeys)
							and TI_TOKey = TP_TOKey)
		
		print 'Определяем ключи @tpKeys: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
				
		-- проверяем актуальность цен
		declare @result table
		(
			tpKey bigint,
			newPrice money
		)
				
		--По настройке получаем актуальную цену через сервис или хранимкой
		if exists (select top 1 1 from SystemSettings with (nolock) where SS_ParmName = 'ServiceGetActualPrice' and SS_ParmValue = 1)
			begin
				print 'exec WcfGetActualPrice ' + '''' +  @tpKeys + ''''
				-- делаем инсерт во веременную таблицу, чтобы результат не выводился при запуске этой хранимки
				exec WcfGetActualPrice @tpKeys
			end
		else
			begin
				print 'exec ReCalculate_CheckActualPrice ' + '''' +  @tpKeys + ''''
				-- делаем инсерт во веременную таблицу, чтобы результат не выводился при запуске этой хранимки
				insert into @result (tpKey, newPrice)
				exec ReCalculate_CheckActualPrice @tpKeys
			end
		
		print 'Расчитываем изменения в ценах: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		insert into @hotelRoomsTable(SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY)
		select SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY
		from HotelRooms join TP_ServiceComponents on SC_SubCode1 = HR_KEY
		where 
			SC_Code in (select xHotelKey from @tableHotelKeys)
		and (@pansionKeys is null or (SC_SubCode2 in	(select tbl.res.value('.', 'int') from @pansionKeys.nodes('/ArrayOfInt/int') as tbl(res))))
		and (isnull(@isHideAccommodationWithAdult, 0) = 0 or (HR_ACKEY in (select AC_KEY from Accmdmentype where (isnull(AC_NADMAIN, 0) > 0) and (isnull(AC_NCHMAIN, 0) = 0) and (isnull(AC_NCHISINFMAIN, 0) = 0))))
		
		print 'Заполнение вспомогательной таблицы: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		delete @hotelRoomsTable
		where 
			(@roomKeys is not null and (HR_RMKEY not in (select tbl.res.value('.', 'int') from @roomKeys.nodes('/ArrayOfInt/int') as tbl(res))))
		or (@roomCategoryKeys is not null and (HR_RCKEY not in	(select tbl.res.value('.', 'int') from @roomCategoryKeys.nodes('/ArrayOfInt/int') as tbl(res))))
		or (@accommodationKeys is not null and (HR_ACKEY not in (select tbl.res.value('.', 'int') from @accommodationKeys.nodes('/ArrayOfInt/int') as tbl(res))))
		
		print 'Очистка вспомогательной таблицы: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		select PC_Id, PC_TPKey, PC_TourDate, SCP_Date, SC_Code, SC_SubCode1, HR_RMKEY, HR_ACKEY, HR_RCKEY, SC_SubCode2, SC_PRKey, PC_Days, SCP_Days, SCP_Men, PC_TOKey, PC_SummPrice, TO_TRKey, TO_Name, TO_Rate, TO_IsEnabled,
		AddCostIsCommission_1, AddCostNoCommission_1, CommissionOnly_1, Gross_1, IsCommission_1, MarginPercent_1, SCPId_1, SVKey_1,
		AddCostIsCommission_2, AddCostNoCommission_2, CommissionOnly_2, Gross_2, IsCommission_2, MarginPercent_2, SCPId_2, SVKey_2,
		AddCostIsCommission_3, AddCostNoCommission_3, CommissionOnly_3, Gross_3, IsCommission_3, MarginPercent_3, SCPId_3, SVKey_3,
		AddCostIsCommission_4, AddCostNoCommission_4, CommissionOnly_4, Gross_4, IsCommission_4, MarginPercent_4, SCPId_4, SVKey_4,
		AddCostIsCommission_5, AddCostNoCommission_5, CommissionOnly_5, Gross_5, IsCommission_5, MarginPercent_5, SCPId_5, SVKey_5,
		AddCostIsCommission_6, AddCostNoCommission_6, CommissionOnly_6, Gross_6, IsCommission_6, MarginPercent_6, SCPId_6, SVKey_6,
		AddCostIsCommission_7, AddCostNoCommission_7, CommissionOnly_7, Gross_7, IsCommission_7, MarginPercent_7, SCPId_7, SVKey_7,
		AddCostIsCommission_8, AddCostNoCommission_8, CommissionOnly_8, Gross_8, IsCommission_8, MarginPercent_8, SCPId_8, SVKey_8,
		AddCostIsCommission_9, AddCostNoCommission_9, CommissionOnly_9, Gross_9, IsCommission_9, MarginPercent_9, SCPId_9, SVKey_9,
		AddCostIsCommission_10, AddCostNoCommission_10, CommissionOnly_10, Gross_10, IsCommission_10, MarginPercent_10, SCPId_10, SVKey_10,
		AddCostIsCommission_11, AddCostNoCommission_11, CommissionOnly_11, Gross_11, IsCommission_11, MarginPercent_11, SCPId_11, SVKey_11,
		AddCostIsCommission_12, AddCostNoCommission_12, CommissionOnly_12, Gross_12, IsCommission_12, MarginPercent_12, SCPId_12, SVKey_12,
		AddCostIsCommission_13, AddCostNoCommission_13, CommissionOnly_13, Gross_13, IsCommission_13, MarginPercent_13, SCPId_13, SVKey_13,
		AddCostIsCommission_14, AddCostNoCommission_14, CommissionOnly_14, Gross_14, IsCommission_14, MarginPercent_14, SCPId_14, SVKey_14,
		AddCostIsCommission_15, AddCostNoCommission_15, CommissionOnly_15, Gross_15, IsCommission_15, MarginPercent_15, SCPId_15, SVKey_15
		from TP_PriceComponents with(nolock) join TP_Tours with(nolock) on TO_Key = PC_TOKey
		join TP_ServiceCalculateParametrs with (nolock) on SCPId_1 = SCP_Id
		join @hotelRoomsTable on SCP_SCId = SC_Id
		where PC_TOKey = isnull(@tourKey, PC_TOKey)
		and PC_HotelKey in (select xHotelKey from @tableHotelKeys)
		and PC_DepartureKey = isnull(@departureKey, 0)
		and PC_TourDate between isnull(@checkinDateBegin, PC_TourDate) and isnull(@checkinDateEnd, PC_TourDate)
		and (@weekDays is null or (@weekDays like '%' + convert(nvarchar(1), datepart(dw, PC_TourDate)) + '%'))
		and (@longList is null or (PC_Days in (select xLong from @tableLongList)))
		and (isnull(@IsDeletePriceOnly, 0) = 0 or PC_SummPrice is null)
		and (@IsOnlineOnly is null or (@IsOnlineOnly = case when PC_SummPrice is null then 0 else TO_IsEnabled end))
		
		print 'Выводим результат: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
	end
END

GO

grant exec on [dbo].[ReCalculate_ViewHotelCost] to public
go

/*********************************************************************/
/* end sp_ReCalculate_ViewHotelCost.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetReservationStatus.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetReservationStatus]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[SetReservationStatus]
GO

CREATE PROCEDURE [dbo].[SetReservationStatus](@dg_key int)
AS
BEGIN
	declare @ReservationStatusId int, @ReservationStatusIdFromDoubleDogovor int
	DECLARE @sUpdateMainDogovorStatuses varchar(254)

	exec GetDogovorStateId @dg_key, @ReservationStatusId output, @ReservationStatusIdFromDoubleDogovor output

	-- 3. Update
	select @sUpdateMainDogovorStatuses = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSUpdateMainDogStatuses'
	IF @ReservationStatusId IS NOT NULL
	BEGIN
		if (ISNULL(@sUpdateMainDogovorStatuses, '0') = '0')
		begin
			UPDATE dbo.tbl_Dogovor
				SET dg_sor_code = @ReservationStatusId
			WHERE dg_key = @dg_key and DG_TURDATE <> '1899-12-30'
			and dg_sor_code != @ReservationStatusId
		end
		else
		begin
			UPDATE dbo.tbl_Dogovor
				SET dg_sor_code = @ReservationStatusId
			WHERE dg_key = @dg_key and DG_Sor_Code in (1,2,3,7) and DG_TURDATE <> '1899-12-30'
			and dg_sor_code != @ReservationStatusId
		end
	END
END
GO

GRANT EXECUTE on [dbo].[SetReservationStatus] to public
GO
/*********************************************************************/
/* end sp_SetReservationStatus.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_WcfReCalculateAddCostsByTour.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WcfReCalculateAddCostsByTour]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[WcfReCalculateAddCostsByTour]
GO

CREATE PROCEDURE [dbo].[WcfReCalculateAddCostsByTour]
		--<VERSION>20.7</VERSION>
	    --<DATA>2014.02.20</DATA>
	    (
			@tourKey int
	    )
AS
BEGIN
	declare @commandLine varchar(2000), @path varchar(2000)
	
	select @path = SS_ParmValue from SystemSettings where SS_ParmName = 'PathToWcfClient'
	
	set @commandLine = @path + ' ReCalculateAddCostsByTour'
	
	if (@tourKey is not null)
	begin
		set @commandLine = @commandLine + ' ' + convert(varchar, @tourKey)
	end

	exec xp_cmdshell @commandLine, no_output
END

GO
grant exec on [dbo].[WcfReCalculateAddCostsByTour] to public
go

/*********************************************************************/
/* end sp_WcfReCalculateAddCostsByTour.sql */
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
update [dbo].[setting] set st_version = '9.2.20.8', st_moduledate = convert(datetime, '2014-02-21', 120),  st_financeversion = '9.2.20.8', st_financedate = convert(datetime, '2014-02-21', 120) 
 GO
 UPDATE dbo.SystemSettings SET SS_ParmValue='2014-02-21' WHERE SS_ParmName='SYSScriptDate'
 GO