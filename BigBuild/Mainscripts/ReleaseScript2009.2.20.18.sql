/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 25.07.2014 13:37 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.17'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.18'

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
/* begin (2014-06-26)_AlterTable_Accmdmtype_AlterColumn_AcMain.sql */
/*********************************************************************/
if exists ( select * from sysindexes where id = object_id(N'[dbo].[Accmdmentype]') and name = N'IX_ACMain' ) 
drop index IX_ACMain on [dbo].[Accmdmentype] 

BEGIN TRY
	update Accmdmentype set AC_MAIN = 0 where AC_MAIN is null
    alter table Accmdmentype alter column ac_main smallint not null
END TRY
BEGIN CATCH
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		
		SELECT 
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
		RAISERROR ('Произошла ошибка при изменении столбца ac_main таблицы Accmdmentype. Обратитесь в техподдержку.',
               @ErrorSeverity,@ErrorState); 
END CATCH

if not exists ( select * from sysindexes where id = object_id(N'[dbo].[Accmdmentype]') and name = N'IX_ACMain' )
CREATE NONCLUSTERED INDEX [IX_ACMain] ON [dbo].[Accmdmentype] 
(
	[AC_MAIN] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO







/*********************************************************************/
/* end (2014-06-26)_AlterTable_Accmdmtype_AlterColumn_AcMain.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-07-16)_StopSales_IX_LoadServices.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[StopSales]') AND name = N'IX_LoadServices')
	DROP INDEX [IX_LoadServices] ON [dbo].[StopSales] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [IX_LoadServices]
ON [dbo].[StopSales] ([SS_QOID],[SS_Date])
INCLUDE ([SS_IsDeleted])
GO
/*********************************************************************/
/* end (2014-07-16)_StopSales_IX_LoadServices.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-07-16)_X_QuotaDetails_WCFService.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetails]') AND name = N'X_QuotaDetails_WCFService')
	DROP INDEX [X_QuotaDetails_WCFService] ON [dbo].[QuotaDetails] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [X_QuotaDetails_WCFService] ON [dbo].[QuotaDetails]
(
	[QD_Date] ASC,
	[QD_IsDeleted] ASC
)
INCLUDE ( 	[QD_ID],
	[QD_QTID],
	[QD_Type],
	[QD_Places],
	[QD_Busy],
	[QD_Release],
	[QD_Comment],
	[QD_CreatorKey],
	[QD_CreateDate],
	[QD_QTKEYOLD],
	[QD_LongMin],
	[QD_LongMax],
	rowId) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/*********************************************************************/
/* end (2014-07-16)_X_QuotaDetails_WCFService.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-07-16)_X_QuotaParts_WCFService.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaParts]') AND name = N'X_QuotaParts_WCFService')
	DROP INDEX [X_QuotaParts_WCFService] ON [dbo].[QuotaParts] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [X_QuotaParts_WCFService] ON [dbo].[QuotaParts] 
(
	[QP_Date] ASC,
	[QP_IsDeleted] ASC
)
INCLUDE ( [QP_ID],
[QP_QDID],
[QP_Places],
[QP_Busy],
[QP_Limit],
[QP_Comment],
[QP_CreatorKey],
[QP_CreateDate],
[QP_FilialKey],
[QP_AgentKey],
[QP_CityDepartments],
[QP_Durations],
[QP_IsNotCheckIn],
[QP_QTKEYOLD],
[QP_Long],
[QP_CheckInPlaces],
[QP_CheckInPlacesBusy],
[QP_LastUpdate],
rowId) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/*********************************************************************/
/* end (2014-07-16)_X_QuotaParts_WCFService.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.07.22)_Insert_SystemSettings.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM SystemSettings WHERE SS_PARMNAME='SYSTouristCitizenship')
	INSERT INTO SystemSettings(SS_PARMNAME,SS_PARMVALUE) VALUES ('SYSTouristCitizenship',0)
GO

/*********************************************************************/
/* end (2014.07.22)_Insert_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.07.23)_Insert_Actions.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 165) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (165, 'Касса -> Запретить осуществлять проводки на прошедшие даты', 'Запретить осуществлять проводки на прошедшие даты', 'Сash -> Deny create payment on past date', 1)
END
GO

IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 166) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (166, 'Касса -> Запретить редактирование платежных операций на прошедшие даты', 'Запретить редактирование платежных операций на прошедшие даты', 'Cash -> Deny edit payment operation with past date payment', 1)
END
GO

/*********************************************************************/
/* end (2014.07.23)_Insert_Actions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckQuotesFlights.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesFlights]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesFlights]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesFlights]
(	
	--<VERSION>2009.2.21.06</VERSION>
	--<DATE>2014-07-04</DATE>
	-- функция проверки квот на авиаперелеты
	@code int,                   -- код услуги
	@subcode1 int,	             -- тариф на авиаперелет 
	@agentKey int,               -- ключ агента (авторизованного пользователя)
	@partnerKey int,             -- ключ партнера (поставщика)
	@date datetime,	             -- дата предоставления услуги
	@day int,                    -- день, с которого предоставляется услуга
	@requestOnRelease smallint, 
	@noPlacesResult int,         -- возвращаемое значение в случае, если закончились места
	@checkAgentQuotes smallint,  -- проверять ли агентские квоты
	@checkCommonQuotes bit,
	@checkNoLongQuotes smallint, -- проверять ли общие квоты
	@findFlight smallint,        -- искать ли заменяющий перелет в случае отсутствия квот
	@cityFrom int,               -- ключ города отправления
	@cityTo int,                 -- ключ города прибытия
	@flightpkkey int,            -- ключ пакета, в котором ищется заменяющий перелет
	@tourDuration int,           -- продолжительность тура
	@expiredReleaseResult int,   -- возвращаемое значение, если наступил релиз-период
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
	declare @tariffToStop varchar(20), @isNewSetToQuota bit
	set @tariffToStop = ',' + ltrim(str(@subcode1)) + ','
	set @isNewSetToQuota = 0
	if exists(select 1 from dbo.systemsettings where ss_parmname='MWTariffsToStop' and charindex(@tariffToStop, ',' + ss_parmvalue + ',') > 0)
		set @noPlacesResult = 0
		
	if exists(select 1 from dbo.systemsettings where ss_parmname='NewSetToQuota' and ss_parmvalue = 1)
		set @isNewSetToQuota = 1
		
	if(COALESCE(@cityFrom, 0) <= 0 or COALESCE(@cityTo, 0) <= 0)
		select @cityFrom = ch_citykeyfrom, @cityTo = ch_citykeyto from charter with(nolock) where ch_key = @code	
	
	-- если стоп ставится плагином Stop-sale на авиаперелеты
	declare @linked_date datetime, @dt1 datetime, @dt2 datetime, @ctFromStop int, @ctToStop int, @dateStop datetime
	SET @dateStop = DATEDIFF(day, @day - 1, @date)
	if @linked_day is not null
	begin
		set @linked_date = dateadd(day, @linked_day - 1, @dateStop)
		if(@linked_date > @date)
		begin
			set @dt1 = @date
			set @dt2 = @linked_date
			set @ctFromStop = @cityFrom
			set @ctToStop =@cityTo
		end
		else
		begin
			set @dt1 = @linked_date
			set @dt2 = @date
			set @ctFromStop = @cityTo
			set @ctToStop = @cityFrom
		end
	end	
	
	declare @dayOfWeek int	
	set @dayOfWeek = datepart(dw, @date) - 1
	if(@dayOfWeek = 0)
		set @dayOfWeek = 7

	declare @chartersKeyTable table(
			x_chkey int
		)		
	
	-- подбираем подходящие нам перелеты, в зависимости от @findFlight
	-- проверяем наличие расписания и не стоит ли стоп на перелет, через плагин Stop-Avia	
	insert into @chartersKeyTable (x_chkey)
	select ch_key
	FROM charter with(nolock) inner join airseason with(nolock) on as_chkey = ch_key
	where ((@findFlight <= 0 and ch_key = @code) or (@findFlight > 0 and ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo)) 
		and (as_week is null or len(as_week)=0 or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
		and (as_dateFrom is null or @date >= as_dateFrom)
		and (as_dateTo is null or @date <= as_dateTo)
		and not exists (select 1 from dbo.stopavia with(nolock) 
						where sa_ctkeyfrom = @ctFromStop and sa_ctkeyto = @ctToStop
						and COALESCE(sa_stop, 0) > 0
						and sa_dbeg = @dt1 and sa_dend = @dt2)
	
	if not exists (select top 1 1 from @chartersKeyTable)
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
			qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
		return
	end	
	
	declare @chartersAndPartnersKeysTable table(
			x_chkey int,
			x_prKey int
		)		
	
	-- если передается ключ пакета, то проверяем цены на перелеты в этом пакете в зависимости от партнера
	if (@flightpkkey > 0)
	begin 
		insert into @chartersAndPartnersKeysTable (x_chkey, x_prKey)			
		select x_chkey, CS_PRKEY
		from @chartersKeyTable join tbl_Costs on x_chkey = CS_CODE
		WHERE cs_svkey = 1 and cs_subcode1 in (@subcode1, 0)	
			and (@date between cs_date and cs_dateend
				or @date between cs_checkindatebeg and cs_checkindateend)
			and (COALESCE(cs_week, '') = '' or cs_week LIKE ('%' + cast(@dayOfWeek as varchar) + '%'))
			and cs_pkkey = @flightpkkey	and (CS_PRKEY = @partnerKey or @partnerKey < 0)
	end
	ELSE
	BEGIN
		insert into @chartersAndPartnersKeysTable (x_chkey, x_prKey)		
			SELECT x_chkey, @partnerKey from @chartersKeyTable
	END 
		
	if not exists (select top 1 1 from @chartersAndPartnersKeysTable)
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
			qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
		return
	end	
	
	declare @currentDate datetime
	set @currentDate = getdate()		
	
	declare @quotasSourceTable as CheckQuotasSourceTable
		
	-- формируем таблицу с квотами, со стопами: общими и частными
	insert into @quotasSourceTable (qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,
		qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin)
	select distinct
			1, qo_code,
			COALESCE(qo_subcode1, 0) as qo_subcode1, -1,				
			COALESCE(qp_agentkey, 0) as qp_agentkey,
			COALESCE(qt_prkey, 0) as qt_prkey,
			COALESCE(qp_isnotcheckin, 0) as qp_isnotcheckin, 
			qd_release as qt_release, 
			COALESCE(qp_places, 0) - COALESCE(qp_busy, 0),
			qd_date, qt_byroom, qd_type,
			COALESCE(ql_duration, 0) as ql_duration,
			COALESCE(qp_places, 0), 0 as qt_stop,
			qo_id as qt_qoid, qd_id as qt_qdid,
			qt_isByCheckIn
			from Quotas q with(nolock) 
			right outer join QuotaObjects qo with(nolock) on qt_id = qo_qtid 
			inner join @chartersAndPartnersKeysTable on qo_code = x_chkey
			inner join QuotaDetails qd with(nolock) on qt_id = qd_qtid 
			inner join QuotaParts qp with(nolock) on qd_id = qp_qdid
			left outer join QuotaLimitations ql with(nolock) on qp_id = ql_qpid								
			where
			qo_svkey = 1 and COALESCE(QD_IsDeleted, 0) = 0 and COALESCE(qo_subcode1, 0) in (0, @subcode1)
			and ((@checkAgentQuotes > 0 and coalesce(qp_agentkey, 0) in (0, @agentKey))
				or (@checkAgentQuotes <= 0 and coalesce(qp_agentkey, 0) = 0)) 
			and (x_prKey < 0 or COALESCE(qt_prkey, 0) in (0, x_prKey))
			and qd_date = @date	
			and (@tourDuration < 0 or (COALESCE(ql_duration, 0) in (0, @tourDuration)))					
			-- нужно учитывать стопы общие и частные, даже если квот нету
			union
			select
				1, qo_code,
				COALESCE(qo_subcode1, 0) as qo_subcode1,
				COALESCE(qo_subcode2, 0) as qo_subcode2,
				0,
				COALESCE(ss_prkey, 0) as qt_prkey,
				0,null,0,ss_date,null,COALESCE(SS_AllotmentAndCommitment, 0) + 1,0,0,1,
				qo_id as qt_qoid, null, null
			from StopSales
				inner join QuotaObjects on qo_id=ss_qoid
				inner join @chartersAndPartnersKeysTable on qo_code = x_chkey
			where ss_date = @date
			and ss_qdid is null
			and COALESCE(ss_isdeleted, 0) = 0
			and qo_svkey = 1
			and (COALESCE(qo_subcode1, 0) in (0, @subcode1) or qo_subcode1 = 0)
			and (x_prKey < 0 or COALESCE(ss_prkey, 0) in (x_prKey, 0))
	order by
			qd_date, qt_stop desc, qp_agentkey DESC, qd_type DESC, QT_PrKey DESC, qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC	
	
	-- если нет ни одной квоты и ни одного стопа, то возвращаем запрос
	if not exists (select top 1 1 from @quotasSourceTable) 
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
		values(0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0)		
		return
	end	
	
	-- если нет ни одной квоты, но есть стопы, то возвращаем нет мест
	if not exists (select top 1 1 from @quotasSourceTable where qt_stop = 0)
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')		
		return
	end
	
	declare @quotasTableWithStops as CheckQuotasSourceTable
	-- теперь проверяем наличие частных стопов, отбрасываем квоты на которые стоит частный стоп
	insert into @quotasTableWithStops (qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin)
	select qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin 
	from @quotasSourceTable
	where (qt_stop = 0
		and not exists (select top 1 1 from StopSales where SS_QDID = qt_qdid and COALESCE(ss_isdeleted, 0) = 0))
	or qt_stop = 1
	
	-- если после проверки на стопы не осталось квот, значит на все квоты стоят стопы, то возвращаем нет мест
	if not exists (select top 1 1 from @quotasTableWithStops where qt_stop = 0) 
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')		
		return
	end

	declare @datePlaces int, @dateAllPlaces int, @additional varchar(2000), @result varchar(2000), @existsRecord bit
	set @additional = ''
	set @result = ''
	set @existsRecord = 0
	set @datePlaces = 0
	set @dateAllPlaces = 0
	
	declare @durations table(
					duration int)
	
	-- выбираем подходящие продолжительности, на которые будем выбирать квоты
	if (@tourDuration >= 0)
	begin
		if (@checkNoLongQuotes = 1)
		begin
			-- подбираем агентские и общие квоты
			insert into @durations select distinct qt_long from @quotasTableWithStops where qt_long in (0, @tourDuration) order by qt_long	desc		 
		end	
		else
		begin
			-- подбираем агентские квоты
			insert into @durations select distinct qt_long from @quotasTableWithStops where qt_long = @tourDuration order by qt_long
			-- если агентские квоты не заведены, то подбираем общие квоты
			if not exists(select top 1 1 from @durations)
				insert into @durations(duration) values (0)
		end		
	end
	else
	begin
		-- подбираем квоты на все продолжительности
		insert into @durations select distinct qt_long from @quotasTableWithStops order by qt_long
	end
	
	declare @rowCount int
	select @rowCount = COUNT(*) from @durations
	
	if(@rowCount > 0)
	begin
		declare @tmpQuotes as CheckQuotasSourceTable
		declare @quotaDuration int
		declare durationCur cursor fast_forward read_only for
			select duration from @durations
	
		open durationCur
	
		fetch next from durationCur into @quotaDuration
		while(@@fetch_status = 0)
		begin
			set @existsRecord = 0
			set @datePlaces = 0
			set @dateAllPlaces = 0
			
			if (@tourDuration < 0 and len(@additional) > 0)
				set @additional = @additional + '|'
			
			-- формируем таблицу с квотами, со стопами: общими и частными
			insert into @tmpQuotes (qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin)
				select qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin
				 from @quotasTableWithStops where qt_long = @quotaDuration or qt_stop = 1			
			
			-- если нет ни одной квоты и ни одного стопа, то возвращаем запрос
			if not exists (select top 1 1 from @tmpQuotes)
			begin
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
					qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
				values(0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0)		
				set @datePlaces = -1
				set @dateAllPlaces = 0
					
				set @existsRecord = 1
			end	
			-- если нет ни одной квоты, но есть стопы, то возвращаем нет мест
			if @existsRecord = 0 and not exists (select top 1 1 from @tmpQuotes where qt_stop = 0)
			begin
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
					qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')	
				set @datePlaces = 0
				set @dateAllPlaces = 0	
				
				set @existsRecord = 1
			end
			
			-- теперь проверяем наличие стоп-сейла
			if @existsRecord = 0 
			begin
				-- если стоит общий стоп на тип квоты Allotment+Commitment, то удаляем квоту Commitment и Allotment
				if exists(select top 1 1 from @tmpQuotes where qt_stop = 1 and qt_type = 2) 			
				begin
					delete from @tmpQuotes 
					from @tmpQuotes qt2 where qt2.qt_stop = 0 
					and exists (select top 1 1 from @tmpQuotes qt1 where qt1.qt_stop = 1 and qt1.qt_type = 2
								and (qt2.qt_subcode1 = qt1.qt_subcode1 or qt1.qt_subcode1 = 0 or qt2.qt_subcode1 = 0) and qt2.qt_code = qt1.qt_code)
				end
				
				-- если стоит общий стоп на тип квоты Allotment, то удаляем квоту Allotment
				if exists(select top 1 1 from @tmpQuotes where qt_stop = 1 and qt_type = 1) 		
				begin
					delete from @tmpQuotes 
					from @tmpQuotes qt2 where qt_stop = 0 and qt_type = 1 
					and exists (select top 1 1 from @tmpQuotes qt1 where qt1.qt_stop = 1 and qt1.qt_type = 1
								and (qt2.qt_subcode1 = qt1.qt_subcode1 or qt1.qt_subcode1 = 0 or qt2.qt_subcode1 = 0) and qt2.qt_code = qt1.qt_code)
				end
				
				-- если после проверки на стопы не осталось квот, значит на все квоты стоят стопы, то возвращаем нет мест
				if not exists (select top 1 1 from @tmpQuotes where qt_stop = 0) 
				begin
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
						qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
					values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')		
					set @datePlaces = 0
					set @dateAllPlaces = 0
					
					set @existsRecord = 1
				end
			end		
			
			-- теперь проверяем наличие запрета на заезд
			if @existsRecord = 0 
			begin	
				if exists(select top 1 1 from @tmpQuotes where qt_stop = 0 and qt_isNotCheckin = 1)
				begin
					delete from @tmpQuotes 
					from @tmpQuotes qt2 where qt2.qt_stop = 0 and qt2.qt_subcode1 = 0
					and exists (select top 1 1 from @tmpQuotes qt1 where qt1.qt_stop = 0 and qt1.qt_isNotCheckin = 1 and qt2.qt_code = qt1.qt_code)
								
					delete from @tmpQuotes where qt_stop = 0 and qt_isNotCheckin = 1
				end
				
				-- если после проверки на запрет на заезд не осталось квот, значит на всех квотах стоят запреты на заезд, то возвращаем нет мест
				if not exists(select top 1 1 from @tmpQuotes where qt_stop = 0)
				begin		
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
						qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
					values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
					set @datePlaces = 0
					set @dateAllPlaces = 0
					
					set @existsRecord = 1
				end	
			end
			
			-- теперь проверяем наличие релиз-периода 
			if @existsRecord = 0 
			begin
				if exists(select top 1 1 from @tmpQuotes where qt_stop = 0 and qt_release > 0 and datediff(day, qt_release, qt_date) < @currentDate) 			
				begin
					delete from @tmpQuotes where qt_stop = 0 and qt_release > 0 and datediff(day, qt_release, qt_date) < @currentDate
				end
			
				-- если после проверки на релиз-период не осталось квот, значит на всех квотах наступил релиз-период, то возвращаем запрос
				if not exists(select top 1 1 from @tmpQuotes where qt_stop = 0)
				begin		
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
						qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
					values(0, 0, 0, 0, 0, 0, 0, 0, @expiredReleaseResult, 0, 0, 0, '0=' + ltrim(rtrim(str(@expiredReleaseResult))) + ':0')
					set @datePlaces = @expiredReleaseResult
					set @dateAllPlaces = 0
					
					set @existsRecord = 1
				end	
			end

			-- если после всех проверок есть квоты, но них нет мест, то возвращаем @noPlacesResult
			if @existsRecord = 0 and not exists(select top 1 1 from @tmpQuotes where qt_stop = 0 and qt_places > 0)
			begin
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
					qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, @noPlacesResult, 0, 0, 0, '0=' + ltrim(rtrim(str(@noPlacesResult))) + ':0')
				set @datePlaces = @noPlacesResult
				set @dateAllPlaces = 0
				
				set @existsRecord = 1
			end	
			
			-- если после всех проверок есть квоты и на них есть места
			if @existsRecord = 0 and @checkAgentQuotes > 0 
			begin
				-- сначала проверяем агентскую квоту, если она существует, то выводим ее
				if exists(select top 1 1 from @tmpQuotes where qt_stop = 0 and qt_agent > 0)
				begin
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
					select top 1 qt_svkey, qt_code, qt_subcode1, 0, qt_agent, qt_prkey, qt_isNotCheckin,
						qt_byroom, qt_places, qt_placesAll, qt_type, qt_long 
					from @tmpQuotes 
					where qt_stop = 0 and qt_agent > 0
					order by qt_places desc
					
					set @datePlaces = 0
					set @dateAllPlaces = 0

					select @datePlaces = SUM(qt_Places), @dateAllPlaces = SUM(qt_placesAll) 
					from @tmpQuotes where qt_stop = 0 and qt_agent > 0

					set @existsRecord = 1
				end

				-- проверяется общая квота, если:
				--		агентская квота закончилась или не заведена (@checkCommonQuotes > 0)
				--		агентская квота не заведена (@checkCommonQuotes = 0)
				if (@checkCommonQuotes > 0 and (@existsRecord = 0 or @datePlaces = 0))
					or (@checkCommonQuotes = 0 and @existsRecord = 0)
				begin
					if exists (select top 1 1 from @tmpQuotes where qt_code = @code and (@partnerKey < 0 or qt_prkey = @partnerKey) 
						and qt_stop = 0 and qt_agent = 0 and qt_places > 0) and @findFlight > 0
					BEGIN
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
						select top 1 qt_svkey, qt_code, qt_subcode1, 0, qt_agent, qt_prkey, qt_isNotCheckin,
							qt_byroom, qt_places, qt_placesAll, qt_type, qt_long 
						from @tmpQuotes 
						where qt_code = @code and (@partnerKey < 0 or qt_prkey = @partnerKey) and 
							qt_stop = 0 and qt_agent = 0 and qt_places > 0
						order by qt_places desc
						
						select @datePlaces = SUM(qt_Places), @dateAllPlaces = SUM(qt_placesAll) 
						from @tmpQuotes where qt_code = @code and (@partnerKey < 0 or qt_prkey = @partnerKey) and 
							qt_stop = 0 AND qt_agent = 0 AND qt_places > 0
					END
					else 
					begin
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
						select top 1 qt_svkey, qt_code, qt_subcode1, 0, qt_agent, qt_prkey, qt_isNotCheckin,
							qt_byroom, qt_places, qt_placesAll, qt_type, qt_long 
						from @tmpQuotes 
						where qt_stop = 0 and qt_agent = 0 and qt_places > 0
						order by qt_places desc
						
						select @datePlaces = SUM(qt_Places), @dateAllPlaces = SUM(qt_placesAll) 
						from @tmpQuotes where qt_stop = 0 AND qt_agent = 0 AND qt_places > 0
					end
					
					if exists (select top 1 1 from @tmpResQuotes where qt_places > 0)
					begin
						delete from @tmpResQuotes where qt_places = 0
						set @existsRecord = 1
					end
				end
			end
			
			-- если после всех проверок есть квоты и на них есть места
			if @existsRecord = 0 
			begin
				if exists (select top 1 1 from @tmpQuotes where qt_code = @code and (@partnerKey < 0 or qt_prkey = @partnerKey) 
					and qt_stop = 0 and qt_places > 0) and @findFlight > 0
				BEGIN
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
					select top 1 qt_svkey, qt_code, qt_subcode1, 0, qt_agent, qt_prkey, qt_isNotCheckin,
						qt_byroom, qt_places, qt_placesAll, qt_type, qt_long 
					from @tmpQuotes 
					where qt_code = @code and (@partnerKey < 0 or qt_prkey = @partnerKey) and qt_stop = 0 and qt_places > 0
					
					select @datePlaces = SUM(qt_Places), @dateAllPlaces = SUM(qt_placesAll)
					from @tmpQuotes 
					where qt_code = @code and (@partnerKey < 0 or qt_prkey = @partnerKey) and qt_stop = 0 and qt_places > 0
				END
				else 
				if exists (select top 1 1 from @tmpQuotes where qt_stop = 0 and qt_places > 0)
				begin
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
					select top 1 qt_svkey, qt_code, qt_subcode1, 0, qt_agent, qt_prkey, qt_isNotCheckin,
						qt_byroom, qt_places, qt_placesAll, qt_type, qt_long 
					from @tmpQuotes 
					where qt_stop = 0 and qt_places > 0
					
					select @datePlaces = SUM(qt_Places), @dateAllPlaces = SUM(qt_placesAll) 
					from @tmpQuotes where qt_stop = 0 and qt_places > 0
				end
			end
			
			--if (@requestOnRelease <= 0 and @findFlight <= 0)
			-- 26882, в случае, если пришел @findFlight > 0 - значит это вызов точно не из экрана QD
			if (@findFlight <= 0)
			begin
				if (@existsRecord = 0)
				begin
					select @datePlaces = SUM(qt_Places), @dateAllPlaces = SUM(qt_placesAll) from @tmpQuotes where qt_stop = 0
				end
				
				if (@tourDuration < 0)
				begin
					set @result = ltrim(str(@datePlaces)) + ':' + ltrim(str(@dateAllPlaces))		
					set @additional = @additional + ltrim(str(@quotaDuration)) + '=' + @result											
				end
			end	
			
			delete from @tmpQuotes
			
			fetch next from durationCur into @quotaDuration
		end	
		
		update @tmpResQuotes set qt_places = @datePlaces, qt_allPlaces = @dateAllPlaces
		
		if (len(@additional) > 0)	
		begin
			update @tmpResQuotes set qt_additional = @additional
		end
			
		close durationCur
		deallocate durationCur
	
		return
	end
	else
	begin
		-- не нашли квот подходящих по продолжительности
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, @noPlacesResult, 0, 0, 0, '0=' + ltrim(rtrim(str(@noPlacesResult))) + ':0')		
		return				
	end			
	return
end
GO

GRANT SELECT ON [dbo].[mwCheckQuotesFlights] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwCheckQuotesFlights.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ALTER_X_Alias_HistoryDetail.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[HistoryDetail]') AND name = N'x_alias')
	DROP INDEX [x_alias] ON [dbo].[HistoryDetail] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [x_alias] ON [dbo].[HistoryDetail]
(
	[HD_Alias] ASC
)
INCLUDE ([HD_HIID],[HD_IntValueNew]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO

/*********************************************************************/
/* end INDEX_ALTER_X_Alias_HistoryDetail.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ALTER_X_Alias_ValueNew.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[HistoryDetail]') AND name = N'x_alias_valueNew')
	DROP INDEX [x_alias_valueNew] ON [dbo].[HistoryDetail] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [x_alias_valueNew] ON [dbo].[HistoryDetail]
(
	[HD_Alias] ASC,
	[HD_ValueNew] ASC
)
INCLUDE ([HD_HIID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO

/*********************************************************************/
/* end INDEX_ALTER_X_Alias_ValueNew.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckQuotaExists.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckQuotaExist]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckQuotaExist]
GO

CREATE PROCEDURE [dbo].[CheckQuotaExist]
(
--<DATE>2014-07-16</VERSION>
--<VERSION>2009.2.27</VERSION>
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
/* end sp_CheckQuotaExists.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_Run.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CorrectionCalculatedPrice_Run]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CorrectionCalculatedPrice_Run]
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
	
	set @partUpdate = 5000 -----100000
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
			insert into dbo.mwReplDeletedPricesTemp (rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey) 
			select TPU_TPKey, TO_CNKey, TL_CTDepartureKey
			from #tmp_tpPricesUpdated
			join TP_Prices on TP_Key = TPU_TPKey
			join tp_tours on tp_tokey = to_key
			join tbl_TurList on tl_key = to_trkey
		
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
				if (@operation = 1)
				begin
					update mwPriceDataTable
					set pt_price = dbo.RoundPrice(@round,TPU_TPGrossOld + TPU_TPGrossDelta)
					from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
				end
				else
				begin
					delete from mwPriceDataTable
					where pt_pricekey in (select TPU_TPKey from #tmp_tpPricesUpdated)
				end
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
						set @sql = 'update ' + @tableName + '
									set pt_price = dbo.RoundPrice(@round,TPU_TPGrossOld + TPU_TPGrossDelta)
									from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey'
					end
					else
					begin
						set @sql = 'delete ' + @tableName + '
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

GRANT EXEC ON [dbo].[CorrectionCalculatedPrice_Run] TO PUBLIC
GO
/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_Run.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DogListToQuotas.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogListToQuotas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogListToQuotas]
GO

CREATE PROCEDURE [dbo].[DogListToQuotas]
(
	--<VERSION>9.20.14</VERSION>
	--<DATA>17.07.2014</DATA>
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

declare @SVKey int, @Code int, @SubCode1 int, @PRKey int, @AgentKey int, @DgKey int,
		@TourDuration int, @FilialKey int, @CityDepartment int,
		@ServiceDateBeg datetime, @ServiceDateEnd datetime, @Pax smallint, @IsWait smallint,@SVQUOTED smallint,
		@SdStateOld int, @SdStateNew int, @nHIID int, @dgCode nvarchar(10), @dlName nvarchar(max), @Long smallint
		
declare @sOldValue nvarchar(max), @sNewValue nvarchar(max), @AddServiceDLKey int

DECLARE @dlControl int
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

	return
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
		exec SetStatusInRoom @DLKey
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
		exec SetStatusInRoom @DLKey
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

--необходимо проставить доп.услугам статусы основных услуг
--вызывать только в случае оформления путевки
if (@SVKey=3 and exists(select top 1 1 from HotelRooms with(nolock) where HR_KEY=@SubCode1 and HR_MAIN=0) and @SetQuotaByRoom is null and @SetQuotaType is null)
begin
	Declare @SDRLID int, @RMKEY int

	SET @SDRLID = null
	SET @RMKEY = null
	
	select @RMKEY=HR_RMKEY from HotelRooms with(nolock) where HR_KEY=@SubCode1
	
	--считаем, что доп.услуга сидит в одной комнате с основным местом
	select top 1 @SDRLID=SD_RLID from ServiceByDate with(nolock) where SD_DLKEY=@dlkey
	
	if @SDRLID is not null and @RMKEY is not null
	begin
		if exists(select top 1 1 from Dogovorlist with(nolock)
					inner join ServiceByDate with(nolock) on SD_DLKey=DL_Key
					inner join QuotaParts with(nolock) on QP_ID=SD_QPID
					inner join QuotaDetails with(nolock) on QP_QDID=QD_ID
					inner join Quotas with(nolock) on QD_QTID=QT_ID
					inner join HotelRooms with(nolock) on HR_Key=DL_SUBCODE1
					inner join RoomPlaces with(nolock) on RP_ID=SD_RPID
					where DL_CODE=@Code
					and RTRIM(DL_DGCOD)=RTRIM(@dgCode)
					and SD_RLID=@SDRLID
					and QT_ByRoom=1
					and HR_MAIN=1
					and HR_RMKEY=@RMKEY
					and RP_Type=0
				)
		begin
			exec SetStatusInRoom @DLKey
			
			-- хранимка простановки статусов у услуг
			EXEC dbo.SetServiceStatusOk @DLKey,@dlControl
			return 0
		end
	end
end

-- проверим если это доп место в комнате, то ее нельзя посадить в квоты, сажаем внеквоты и эта квота за человека
if exists(select 1 from systemsettings where ss_parmname='SYSSetQuotaForAddPlaces' and SS_ParmValue=1)
begin
	if (exists (select top 1 1 from ServiceByDate with(nolock) join RoomPlaces with(nolock) on SD_RPID = RP_ID where SD_DLKey = @DLKey and RP_Type = 1) and (@SetQuotaByRoom = 0))
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
				
				-- хранимка простановки статусов у услуг
				EXEC dbo.SetServiceStatusOk @DlKey,@dlControl
				
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
		if @SVKey = 3
		begin
			DECLARE DLCURSOR CURSOR FAST_FORWARD FOR
			select distinct SD_DLKey from ServiceByDate SD1 with(nolock)
				inner join Dogovorlist DL1 with(nolock) on SD1.SD_DLKey=DL1.DL_KEY
				inner join HotelRooms with(nolock) on HR_KEY=DL1.DL_SUBCODE1
				where DL1.DL_DGKEY in (select DL2.DL_DGKEY from Dogovorlist DL2 with(nolock)
										inner join ServiceByDate SD2 on DL2.DL_KEY=SD2.SD_DLKey
										where DL2.DL_KEY=@DLKey
										and DL2.DL_SVKEY=3
										and SD2.SD_RLID=SD1.SD_RLID
									)
				and DL1.DL_Key<>@DLKey
				and DL1.DL_SVKEY=3
				and HR_MAIN=0
			OPEN DLCURSOR
			FETCH NEXT FROM DLCURSOR INTO @AddServiceDLKey
			WHILE @@FETCH_STATUS = 0
			BEGIN
				--устанавливаем статус доп.услугам, выделенным в отдельную услугу, но сидящим в том же номере
				exec SetStatusInRoom @AddServiceDLKey
				
				EXEC dbo.SetServiceStatusOk @AddServiceDLKey,@dlControl
			END
			FETCH NEXT FROM DLCURSOR INTO @AddServiceDLKey
			CLOSE DLCURSOR
			DEALLOCATE DLCURSOR
		end
		
		-- хранимка простановки статусов у услуг
		EXEC dbo.SetServiceStatusOk @DlKey,@dlControl
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
		end
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
						and QO_SubCode2=CASE
											WHEN @SVKey=3 THEN @Q_SubCode2
											WHEN @SVKey<>3 AND EXISTS(SELECT TOP 1 1 FROM [Service] WHERE SV_KEY=@SVKey AND SV_ISSUBCODE2=1)
												THEN (SELECT DL_Subcode2 FROM tbl_DogovorList WITH(NOLOCK) WHERE DL_Key=@DLKey)
											ELSE QO_SubCode2 END
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
IF @SetQuotaByRoom=1 and @SVKey=3
BEGIN
	IF @SetQuotaRLKey is null
	BEGIN
		UPDATE ServiceByDate SET SD_State = 4 where SD_DLKey = @DLKey and SD_QPID is null
	END
	ELSE
	BEGIN
		UPDATE ServiceByDate SET SD_State = 4 where SD_DLKey = @DLKey and SD_RLID = @SetQuotaRLKey and SD_QPID is null
	END
END
ELSE
BEGIN
	IF @SetQuotaRPKey is null
	BEGIN
		UPDATE ServiceByDate SET SD_State = 4 where SD_DLKey = @DLKey and SD_QPID is null
	END
	ELSE
	BEGIN
		UPDATE ServiceByDate SET SD_State = 4 where SD_DLKey = @DLKey and SD_RPID = @SetQuotaRPKey and SD_QPID is null
	END
END

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

EXEC dbo.SetServiceStatusOk @DlKey,@dlControl
GO

GRANT EXEC ON [dbo].[DogListToQuotas] TO PUBLIC
GO
/*********************************************************************/
/* end sp_DogListToQuotas.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_RemoveDeleted.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE name = 'mwRemoveDeleted' and type='P')
	DROP PROCEDURE [dbo].[mwRemoveDeleted]
GO

create proc [dbo].[mwRemoveDeleted] 
	@remove tinyint = 0
as
begin
	--<VERSION>9.2.20.18</VERSION>
	--<DATE>2014-07-18</DATE>

	declare @mwSearchType int
	declare @cnKey int, @ctKey int, @toKey int, @sql varchar(max)

	select @mwSearchType = isnull(SS_ParmValue, 0) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'

	if (@mwSearchType = 0)
	begin
		while (1 = 1)
		begin
			delete top (100000) from mwPriceDatatable  where pt_isenabled = 0
			if (@@ROWCOUNT = 0)
				break
		end
	end
	else
	begin
		declare delCur cursor local fast_forward read_only for 
		select distinct sd_cnkey, sd_ctkeyfrom
		from mwSpoDataTable with(nolock)
		where sd_isenabled = 1

		open delCur
		fetch delCur into @cnKey, @ctKey
		while (@@fetch_status = 0)
		begin
			set @sql = 'while (1 = 1)
			begin
				delete top (100000) from mwPriceDatatable_' + ltrim(str(@cnKey)) + '_' + ltrim(str(@ctKey)) + ' where pt_isenabled = 0
				if (@@ROWCOUNT = 0)
					break
			end'
			exec (@sql)
			fetch delCur into @cnKey, @ctKey
		end
		close delCur
		deallocate delCur
	end

	declare @pubdb nvarchar(50), @source as nvarchar(50)
	set @pubdb = dbo.mwReplPublisherDB()
	set @source = ''
	if dbo.mwReplIsSubscriber() > 0
	begin
		set @source = 'mt.' + @pubdb + '.'
	end

	create table #tmpDeleted (del_key int)

	truncate table #tmpDeleted
	set @sql = 'insert into #tmpDeleted (del_key) select sd_key from dbo.mwSpoDataTable with(nolock) where not exists(select top (1) 1 from ' + @source + 'dbo.tp_prices with(nolock) where tp_tokey = sd_tourkey)'
	exec (@sql)
	delete from dbo.mwSpoDataTable where sd_key in (select del_key from #tmpDeleted)

	truncate table #tmpDeleted
	set @sql = 'insert into #tmpDeleted (del_key) select ph_key from dbo.mwPriceHotels with(nolock) where not exists(select top (1) 1 from ' + @source + 'dbo.tp_prices with(nolock) where tp_tokey = sd_tourkey)'
	exec (@sql)
	delete from dbo.mwPriceHotels where ph_key in (select del_key from #tmpDeleted)

	truncate table #tmpDeleted
	set @sql = 'insert into #tmpDeleted (del_key) select pd_key from dbo.mwPriceDurations with(nolock) where not exists(select top (1) 1 from ' + @source + 'dbo.tp_prices with(nolock) where tp_tokey = sd_tourkey)'
	exec (@sql)
	delete from dbo.mwPriceDurations where pd_key in (select del_key from #tmpDeleted)
	
	drop table #tmpDeleted

	set nocount off
end
GO

GRANT EXEC on [dbo].[mwRemoveDeleted] to public
GO
/*********************************************************************/
/* end sp_RemoveDeleted.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetStatusInRoom.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetStatusInRoom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetStatusInRoom]
GO

CREATE PROCEDURE [dbo].[SetStatusInRoom] 
	(
		--<VERSION>2009.2.6</VERSION>
		--<DATA>17.07.2014</DATA>
		@DlKey int
	)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	/*
	Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	1. Если "Осн" в состоянии "Ок", "А", или "С" - тогда "доп" - в "Ок".
	2. Если "Осн" в "RQ" - тогда доп - в "RQ".
	*/
	declare @ServiceHotelKey int, @SVKey int		-- ключ услуги проживание
	declare @DGKey int, @RPType int, @SDState int, @QTByRoom bit, @Code int
	set @ServiceHotelKey = 3
	
	select @SVKey=dl_svkey, @DGKey = DL_DGKEY, @Code = DL_CODE from DogovorList with(nolock) where dl_key = @DLKey
	
	if (@SVKey <> @ServiceHotelKey)
		return 0
	
	SELECT top 1 @QTByRoom = QT_ByRoom 
		FROM Quotas with(nolock)
		join QuotaObjects with(nolock) on QT_ID = QO_QTID
		where QO_Code = @Code
		and QO_SVKey = @ServiceHotelKey
	
	if (@QTByRoom = 1)
	begin
		select @rpType = RP_Type, @SDState = MAX(COALESCE(SD_State, 4))
			from ServiceByDate with(nolock)
			join RoomPlaces with(nolock) on SD_RLID = RP_RLID
			where SD_DLKey = @DlKey
			group by SD_DLKey, RP_Type
		
		if (@rpType = 0)
		begin
			create table #DlKeys
			(
				dlKey int
			)
			
			insert into #DLKeys
				select dl_key
				from Dogovorlist with(nolock)
				where dl_dgkey = @DGKey
				and dl_svkey = @ServiceHotelKey
			
			update ServiceByDate
				set SD_State = @SDState
				from RoomPlaces with(nolock)
				where RP_RLID = SD_RLID
				and SD_DLKey in (select dlKey from #DlKeys)
				and RP_Type = 1
				and SD_RLID in (select SD_RLID
								from ServiceByDate with(nolock)
								where SD_DLKey = @DlKey)
			
			drop table #DLKeys
		end
		else
		begin
			select @SDState = MAX(COALESCE(SD_State,4)) from DogovorList dl1 with(nolock)
				inner join hotelRooms with(nolock) on dl1.dl_subcode1=hr_key
				inner join ServiceByDate sd1 with(nolock) on dl1.DL_KEY = sd1.SD_DLKey
				inner join RoomPlaces with(nolock) on sd1.SD_RLID = RP_RLID
				where DL_DGCOD in (select DL_DGCOD from dogovorlist dl2 with(nolock)
									inner join ServiceByDate sd2 on sd2.SD_DLKey=dl2.DL_KEY
									where dl2.DL_KEY=@DlKey
									and dl1.DL_SVKEY=dl2.DL_SVKEY
									and sd1.SD_RLID=sd2.SD_RLID)
				and HR_MAIN = 1
				and RP_Type = 0
			
			update ServiceByDate
				set SD_State = @SDState
				where SD_DLKey = @DlKey
		end
	end
END

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

GRANT EXEC ON [dbo].[SetStatusInRoom] TO PUBLIC
GO
/*********************************************************************/
/* end sp_SetStatusInRoom.sql */
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
--<VERSION>9.2.1.3</VERSION>
--<DATE>2014-07-16</DATE>

-- тип триггера (DEL - удаление, INS - вставка, UPD - обновление)
-- если включена настройка то выходим, рассадка теперь работает по другому
IF (EXISTS (SELECT TOP 1 1
		    FROM SystemSettings WITH (NOLOCK)
		    WHERE SS_ParmName = 'NewSetToQuota' AND SS_ParmValue = 1))
BEGIN
	RETURN;
END

DECLARE @DLKey int, @DGKey int, @O_DLSVKey int, @O_DLCode int, @O_DLSubcode1 int, @O_DLDateBeg datetime, @O_DLDateEnd datetime, @O_DLNMen int, @O_DLAgentKey int, @O_DLPartnerKey int, @O_DLControl int, 
		@N_DLSVKey int, @N_DLCode int, @N_DLSubcode1 int, @N_DLDateBeg datetime, @N_DLDateEnd datetime, @N_DLNMen int, @N_DLAgentKey int, @N_DLPartnerKey int, @N_DLControl int,
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
    SELECT O.DL_Key, O.DL_DGKey, O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_SubCode2, O.DL_DateBeg, O.DL_DateEnd, O.DL_NMen, O.DL_AGENT, O.DL_PartnerKey, 
    		O.DL_Control, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, null, null
    FROM DELETED O
	SET @Mod = 'DEL'
END
ELSE IF (@nDelCount = 0) -- если нет вставляемых записей, есть только удаляемые записи
BEGIN
    DECLARE cur_DogovorListChanged2 CURSOR FOR 
    SELECT 	N.DL_Key, N.DL_DGKey,
			null, null, null, null, null, null, null, null, null, null,
			N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_SubCode2, N.DL_DateBeg, N.DL_DateEnd, N.DL_NMen, N.DL_AGENT, N.DL_PartnerKey, N.DL_Control
    FROM	INSERTED N 
	SET @Mod = 'INS'
END
ELSE -- если есть и удаляемые и вставляемые записи
BEGIN
    DECLARE cur_DogovorListChanged2 CURSOR FOR 
    SELECT 	N.DL_Key, N.DL_DGKey, 
		O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_Subcode2, O.DL_DateBeg, O.DL_DateEnd, O.DL_NMen, O.DL_AGENT, O.DL_PartnerKey, O.DL_Control,
		N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_Subcode2, N.DL_DateBeg, N.DL_DateEnd, N.DL_NMen, N.DL_AGENT, N.DL_PartnerKey, N.DL_Control
    FROM DELETED O, INSERTED N 
    WHERE N.DL_Key = O.DL_Key
	SET @Mod = 'UPD'
END

OPEN cur_DogovorListChanged2
FETCH NEXT 
FROM cur_DogovorListChanged2 
INTO @DLKey, @DGKey, @O_DLSVKey, @O_DLCode, @O_DLSubCode1, @O_DLSubcode2, @O_DLDateBeg, @O_DLDateEnd, @O_DLNMen, @O_DLAgentKey, @O_DLPartnerKey, @O_DLControl, 
	@N_DLSVKey, @N_DLCode, @N_DLSubCode1, @N_DLSubcode2, @N_DLDateBeg, @N_DLDateEnd, @N_DLNMen, @N_DLAgentKey, @N_DLPartnerKey, @N_DLControl
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
			or (ISNULL(@O_DLSubCode2,0) != ISNULL(@N_DLSubCode2,0) AND ISNULL(@N_DLSVKey,0) not in (1,3)
				and EXISTS(SELECT TOP 1 1 FROM [Service] WITH(NOLOCK) WHERE SV_IsSubCode2=1 AND SV_Quoted=1 AND SV_Key=ISNULL(@N_DLSVKey,0)))
			OR (ISNULL(@O_DLPartnerKey, 0) != ISNULL(@N_DLPartnerKey, 0))
			OR (ISNULL(@O_DLAgentKey, 0) != ISNULL(@N_DLAgentKey, 0))
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
	if (exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota' AND SS_ParmValue = 0))
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
				while (SELECT count(1) FROM #ServiceByDate WHERE SD_DLKey=@DLKey AND SD_Date=@N_DLDateBeg) > ISNULL(@N_DLNMen,0)
				BEGIN
					if (@N_DLSVKey = 3 or @N_DLSVKey=8) --для проживания отдельная ветка
					BEGIN					
						SELECT TOP 1 @RLID = SD_RLID, @RPCount = count(SD_ID) FROM #ServiceByDate WHERE SD_DLKey = @DLKey AND SD_TUKey is null AND SD_Date = @N_DLDateBeg
						GROUP BY SD_RLID
						ORDER BY 2
						
						SELECT TOP 1 @RPID = SD_RPID FROM #ServiceByDate WHERE SD_DLKey = @DLKey AND SD_RLID = @RLID AND SD_TUKey is null
						DELETE FROM #ServiceByDate WHERE SD_DLKey = @DLKey AND SD_RLID = @RLID AND ISNULL(SD_RPID,0) = ISNULL(@RPID,0) AND SD_TUKey is null
					END
					ELSE
					BEGIN
						--обязательно!!! NULL туриста вперед 
						SELECT TOP 1 @RPID = SD_RPID FROM #ServiceByDate WHERE SD_DLKey = @DLKey order by SD_TUKey
						DELETE FROM #ServiceByDate WHERE SD_DLKey = @DLKey AND ISNULL(SD_RPID,0) = ISNULL(@RPID,0)
					END
				END
				
				delete from ServiceByDate where SD_DLKey = @DLKey AND SD_ID not in (select x.SD_ID from #ServiceByDate as x)
			END
			-- если новое число туристов больше, чем было до этого (@O_DLNMen < @N_DLNMen)
			ELSE
			BEGIN
				if (@N_DLSVKey=3 or @N_DLSVKey=8) --для проживания отдельная ветка
				BEGIN
					SELECT @HRIsMain=AC_MAIN, @ACPlacesMain=ISNULL(AC_NRealPlaces,0), @ACPlacesEx=ISNULL(AC_NMenExBed,0), @ACPerRoom=ISNULL(AC_PerRoom,0)
						FROM AccmdMenType
						WHERE AC_Key=(SELECT HR_ACKey From HotelRooms WHERE HR_Key=@N_DLSubCode1)
					
					SELECT @RMPlacesMain=ISNULL(RM_NPLACES,0), @RMPlacesEx=ISNULL(RM_NPlacesEx,0)
						FROM Rooms
						WHERE RM_KEY=(SELECT HR_RMKey From HotelRooms WHERE HR_KEY=@N_DLSubcode1)
					
					IF @HRIsMain = 1 AND @ACPlacesMain = 0 AND @ACPlacesEx = 0
						set @ACPlacesMain = 1
					ELSE IF @HRIsMain = 0 AND @ACPlacesMain = 0 AND @ACPlacesEx = 0
						set @ACPlacesEx = 1
					
					if (@ACPerRoom = 1)
					begin
						SET @AC_FreeMainPlacesCount = @ACPlacesMain
						SET @AC_FreeExPlacesCount = @ACPlacesEx
					end
					else
					begin
						SET @AC_FreeMainPlacesCount = @RMPlacesMain
						SET @AC_FreeExPlacesCount = @RMPlacesEx
					end
					
					--есть 3 варианта размещения: только основные, только дополнительные, основные и дополнительные
					--в первых 2-х вариантах сначала занимаем свободные уже существующие места данного типа в номерах этой услуги, в последнем занимаем все свободные места
					if @ACPlacesMain>0
						WHILE (@NeedPlacesForMen>0 and EXISTS(select RP_ID FROM RoomPlaces (nolock) where RP_RLID in (SELECT SD_RLID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_Type=0))
						BEGIN
							select TOP 1 @RPID=RP_ID,@RLID=RP_RLID FROM RoomPlaces (nolock) where RP_RLID in (SELECT SD_RLID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_Type=0
							INSERT INTO #ServiceByDate (xSD_STATE, SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_State)	
								SELECT 1, CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RLID, @RPID, 4
								FROM NUMBERS as N1 WHERE N1.NU_ID between 1 AND CAST(@N_DLDateEnd as int)-@From+1
							SET @NeedPlacesForMen=@NeedPlacesForMen-1
						END
					if @ACPlacesEx>0
						WHILE (@NeedPlacesForMen>0 and EXISTS(select RP_ID FROM RoomPlaces (nolock) where RP_RLID in (SELECT SD_RLID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_Type=1))
						BEGIN
							select TOP 1 @RPID=RP_ID,@RLID=RP_RLID FROM RoomPlaces (nolock) where RP_RLID in (SELECT SD_RLID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM #ServicebyDate where SD_DLKey=@DLKey) and RP_Type=1
							INSERT INTO #ServiceByDate (xSD_STATE, SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_State)	
								SELECT 1, CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RLID, @RPID, 4
								FROM NUMBERS as N1 WHERE N1.NU_ID between 1 AND CAST(@N_DLDateEnd as int)-@From+1
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
			IF (@N_DLSVKey = 3 OR @N_DLSVKey = 8)
			BEGIN
				
				If @NeedPlacesForMen > 0
				BEGIN
					SELECT TOP 1 @RLPlacesMain = RL_NPlaces, @RLPlacesEx = RL_NPlacesEx, @RMKey = RL_RMKey, @RCKey = RL_RCKey
						FROM RoomNumberLists, ServiceByDate
						WHERE RL_ID = SD_RLID
						AND SD_DLKey = @DLKey
				END
				ELSE
				BEGIN
					IF (@N_DLSVKey = 3 OR (@N_DLSVKey = 8 AND @N_DLSubcode1 is not null AND @N_DLSubcode1!=0))
					BEGIN
						SELECT @HRIsMain = HR_MAIN, @RMKey = HR_RMKEY, @RCKey = HR_RCKEY, @ACKey = HR_ACKEY, @RMPlacesMain = RM_NPlaces, 
						@RMPlacesEx = RM_NPlacesEx, @ACPlacesMain = ISNULL(AC_NRealPlaces, 0), @ACPlacesEx = ISNULL(AC_NMenExBed, 0), 
						@ACPerRoom = ISNULL(AC_PerRoom, 0)
						FROM HotelRooms, Rooms, AccmdMenType
						WHERE HR_Key = @N_DLSubcode1
							AND RM_Key = HR_RMKEY
							AND AC_KEY = HR_ACKEY
					END
					ELSE
					BEGIN
						SELECT @HRIsMain = HR_MAIN, @RMKey = HR_RMKEY, @RCKey = HR_RCKEY, @ACKey = HR_ACKEY, @RMPlacesMain = RM_NPlaces, 
						@RMPlacesEx = RM_NPlacesEx, @ACPlacesMain = ISNULL(AC_NRealPlaces, 0), @ACPlacesEx = ISNULL(AC_NMenExBed, 0), 
						@ACPerRoom = ISNULL(AC_PerRoom, 0)
						FROM HotelRooms, Rooms, AccmdMenType
						WHERE HR_Key = (select top 1 DL_SUBCODE1 from Dogovorlist (nolock) dl1
										where DL_SVKEY=3
										and DL_DGCOD=(select top 1 DL_DGCOD from Dogovorlist (nolock) dl2
														where DL_KEY=@DLKey and DL1.DL_CODE=DL2.DL_CODE))
							AND RM_Key = HR_RMKEY
							AND AC_KEY = HR_ACKEY
					END
					
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
				WHILE (@NeedPlacesForMen > 0)
				BEGIN
					IF (EXISTS(SELECT TOP 1 1 FROM HotelRooms WHERE HR_MAIN=1 AND HR_KEY=@N_DLSubcode1)
						AND ISNULL(@AC_FreeMainPlacesCount,0)=0)
					BEGIN
							SET @AC_FreeExPlacesCount = 0
					END
					
					--если в последнем номере кончились места, то выставляем признак @RLID = 0
					IF (ISNULL(@AC_FreeMainPlacesCount,0) = 0)
						AND ISNULL(@AC_FreeExPlacesCount,0) = 0
					BEGIN
						SELECT @ACPlacesMain=ISNULL(AC_NRealPlaces,0), @ACPlacesEx=ISNULL(AC_NMenExBed,0), @ACPerRoom=ISNULL(AC_PerRoom,0)
							FROM AccmdMenType WHERE AC_Key=(SELECT HR_ACKey From HotelRooms WHERE HR_Key=@N_DLSubCode1)
						
						SELECT @RMPlacesMain=ISNULL(RM_NPLACES,0), @RMPlacesEx=ISNULL(RM_NPlacesEx,0)
							FROM Rooms WHERE RM_KEY=(SELECT HR_RMKey From HotelRooms WHERE HR_KEY=@N_DLSubcode1)
						
						if (@ACPerRoom = 1)
						begin
							SET @AC_FreeMainPlacesCount = @ACPlacesMain
							SET @AC_FreeExPlacesCount = @ACPlacesEx
						end
						else
						begin
							SET @AC_FreeMainPlacesCount = @RMPlacesMain
							SET @AC_FreeExPlacesCount = @RMPlacesEx
							
							IF (EXISTS(SELECT TOP 1 1 FROM HotelRooms WITH(NOLOCK) WHERE HR_KEY=@N_DLSubcode1 AND HR_MAIN=0))
							BEGIN
								DECLARE @SDRLID INT, @DGCode VARCHAR(50), @MainPlacesBusy INT, @ExPlacesBusy INT
								
								SET @SDRLID = NULL
								
								SELECT @DGCode=DL_DGCod FROM Dogovorlist WITH(NOLOCK) WHERE DL_KEY=@DLKey
								
								--считаем, что доп.услуга сидит в одной комнате с основным местом
								SELECT TOP 1 @SDRLID=SD_RLID FROM ServiceByDate WITH(NOLOCK) WHERE SD_DLKEY=@DLKey
								
								SELECT TOP 1 @SDRLID=SD_RLID FROM Dogovorlist DL1 WITH(NOLOCK)
									INNER JOIN ServiceByDate WITH(NOLOCK) ON DL1.dl_key=SD_DLKey
									INNER JOIN HotelRooms WITH(NOLOCK) ON HR_KEY=Dl1.DL_SUBCODE1
									INNER JOIN RoomPlaces WITH(NOLOCK) ON RP_ID=SD_RPID
									WHERE DL1.DL_CODE=@N_DLCode
									AND DL1.DL_SUBCODE2=@N_DLSubcode2
									AND HR_MAIN=1
									AND RP_Type=0
									AND exists(select top 1 1 FROM Dogovorlist DL2 WITH(NOLOCK)
												WHERE DL2.DL_KEY=@DLKey AND DL2.DL_DGCOD=DL1.DL_DGCOD)
								
								IF @SDRLID IS NOT NULL
								BEGIN
									SELECT @MainPlacesBusy=COUNT(*) FROM Dogovorlist WITH(NOLOCK)
										INNER JOIN ServiceByDate WITH(NOLOCK) ON SD_DLKey=DL_Key
										INNER JOIN QuotaParts WITH(NOLOCK) ON QP_ID=SD_QPID
										INNER JOIN QuotaDetails WITH(NOLOCK) ON QP_QDID=QD_ID
										INNER JOIN Quotas WITH(NOLOCK) ON QD_QTID=QT_ID
										INNER JOIN HotelRooms WITH(NOLOCK) ON HR_Key=DL_SUBCODE1
										INNER JOIN RoomPlaces WITH(NOLOCK) ON RP_ID=SD_RPID
										WHERE DL_CODE=@N_DLCode
										AND RTRIM(DL_DGCOD)=RTRIM(@DGCode)
										AND SD_RLID=@SDRLID
										AND QT_ByRoom=1
										AND HR_MAIN=1
										AND HR_RMKEY=@RMKEY
										AND RP_Type=0
									
									SELECT @ExPlacesBusy=COUNT(*) FROM Dogovorlist WITH(NOLOCK)
										INNER JOIN ServiceByDate WITH(NOLOCK) ON SD_DLKey=DL_Key
										INNER JOIN QuotaParts WITH(NOLOCK) ON QP_ID=SD_QPID
										INNER JOIN QuotaDetails WITH(NOLOCK) ON QP_QDID=QD_ID
										INNER JOIN Quotas WITH(NOLOCK) ON QD_QTID=QT_ID
										INNER JOIN HotelRooms WITH(NOLOCK) ON HR_Key=DL_SUBCODE1
										INNER JOIN RoomPlaces WITH(NOLOCK) ON RP_ID=SD_RPID
										WHERE DL_CODE=@N_DLCode
										AND RTRIM(DL_DGCOD)=RTRIM(@DGCode)
										AND SD_RLID=@SDRLID
										AND QT_ByRoom=1
										AND HR_MAIN=0
										AND HR_RMKEY=@RMKEY
										AND RP_Type=1
									
									SET @AC_FreeMainPlacesCount = @AC_FreeMainPlacesCount - @MainPlacesBusy
									SET @AC_FreeExPlacesCount = @AC_FreeExPlacesCount - @ExPlacesBusy
								END
							END
						end
						
						--создаем новый номер, всегда когда есть хоть кто-то на основном месте ???
						IF (@AC_FreeMainPlacesCount > @RL_FreeMainPlacesCount)
							OR (@AC_FreeExPlacesCount > @RL_FreeExPlacesCount)
						BEGIN
							--создаем новый номер для каждой услуги, если размещение на номер.
							IF @ACPerRoom>0
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
								set @RPID=SCOPE_IDENTITY()-@RLPlacesMain-@RLPlacesEx+1
								
								SET @RL_FreeMainPlacesCount = @RLPlacesMain
								SET @RL_FreeExPlacesCount = @RLPlacesEx
							END
							ELSE
							BEGIN
								-- ищем к кому подселиться в данной путевке, если не находим, то прийдется создавать новый номер
								set @RPID = null
								
								IF NOT EXISTS(SELECT TOP 1 1 FROM HotelRooms(NOLOCK)
											WHERE HR_KEY=@N_DLSubcode1
											AND HR_MAIN=1)
								BEGIN
									SELECT TOP 1 @RPID = RP_ID, @RLID = RP_RLID
									FROM RoomPlaces(NOLOCK)
									WHERE RP_Type = CASE 
											WHEN @ACPlacesMain > 0
												THEN 0
											ELSE 1
											END
										AND RP_RLID IN (
											SELECT SD_RLID
											FROM ServiceByDate(NOLOCK), DogovorList(NOLOCK), RoomNumberLists(NOLOCK)
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
											FROM ServiceByDate(NOLOCK)
											WHERE SD_RLID = RP_RLID
												AND SD_RPID = RP_ID
											)
									ORDER BY RP_RLID DESC,RP_ID ASC
								END
								
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
										FROM RoomPlaces (nolock)
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
					ELSE IF @AC_FreeExPlacesCount > 0
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
	INTO @DLKey, @DGKey, @O_DLSVKey, @O_DLCode, @O_DLSubCode1, @O_DLSubCode2, @O_DLDateBeg, @O_DLDateEnd, @O_DLNMen, @O_DLAgentKey, @O_DLPartnerKey, 
		@O_DLControl, @N_DLSVKey, @N_DLCode, @N_DLSubCode1, @N_DLSubCode2, @N_DLDateBeg, @N_DLDateEnd, @N_DLNMen, @N_DLAgentKey, @N_DLPartnerKey, @N_DLControl
END
CLOSE cur_DogovorListChanged2
DEALLOCATE cur_DogovorListChanged2

GO


/*********************************************************************/
/* end T_UpdDogListQuota.sql */
/*********************************************************************/

/*********************************************************************/
/* begin !DisableTriggersOnSubscriber.sql */
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
/* end !DisableTriggersOnSubscriber.sql */
/*********************************************************************/

/*********************************************************************/
/* begin !DropForeignKeyConstraintsOnSubscriber.sql */
/*********************************************************************/
-- script drop foreign key constraints on subscriber

-- drop foreign keys
if dbo.mwReplIsSubscriber() > 0 and exists (select top 1 1 from sys.servers where name = 'mt')
	and exists (select top 1 1 from sys.foreign_keys)
begin
	-- drop foreign key constraints
	declare @killSql as varchar(max)
	set @killSql = ''

	set @killSql = 'alter table #table drop constraint #constraint'
	
	declare @table as sysname, @fkName as sysname

	declare constr cursor for
	select parent.name, fk.name
	from sys.foreign_keys fk
	left join sys.tables parent on fk.parent_object_id = parent.object_id
	left join sys.tables child on fk.referenced_object_id = child.object_id

	declare @killSqlConcrete as nvarchar(max)

	open constr
	fetch next from constr into @table, @fkName
	while @@fetch_status = 0
	begin

		set @killSqlConcrete = replace(@killSql, '#table', @table)
		set @killSqlConcrete = replace(@killSqlConcrete, '#constraint', @fkName)

		--print @killSqlConcrete
		exec (@killSqlConcrete)

		fetch next from constr into @table, @fkName

	end

	close constr
	deallocate constr

end

go
/*********************************************************************/
/* end !DropForeignKeyConstraintsOnSubscriber.sql */
/*********************************************************************/

/*********************************************************************/
/* begin !ChangeDistributionAgentProfile.sql */
/*********************************************************************/
-- скрипт меняет профиль агента распространителя на 'continue on data consistency errors': устанавливает его 
-- как профиль по умолчанию и уставливает его для всех существующих подписок

-- ========================== 0. CHECK DISTRIBUTOR EXISTS
declare @distTable table
(
	installed int,
	dist_server sysname NULL,
	distribution_db_installed int,
	is_distribution_publisher int,
	has_remote_distribution_publisher int
)
	
insert into @distTable exec sp_get_distributor

if exists (select top 1 1 from @distTable where installed = 1 and distribution_db_installed = 1)
begin
	-- ========================== 1. GET DISTRIBUTION DATABASES
	declare @distributionAgentProfileType as int
	set @distributionAgentProfileType = 3

	declare @type int                                      -- agent type 

	set @type = @distributionAgentProfileType

	set nocount on
	declare @distribution int
				,@db_name sysname
				,@cmd nvarchar(4000)
				,@distbit int

	--
	-- initialize
	--
	select @distbit = 16
			,@distribution = 3
	--
	-- For each distribution database collect meta 
	--
	declare #hCdatabase CURSOR LOCAL FAST_FORWARD FOR
		select name 
		from master.dbo.sysdatabases 
		where category & @distbit <> 0 
			and has_dbaccess(name) = 1
	for read only

	create table #distribution_agents (dbname sysname collate database_default not null, 
		name nvarchar(100) collate database_default not null,  
		status int NOT NULL,
		publisher sysname collate database_default not null, publisher_db sysname collate database_default not null, 
		publication sysname collate database_default null,
		subscriber sysname collate database_default null, subscriber_db sysname collate database_default null, subscription_type int NULL,
		start_time nvarchar(24) collate database_default null, time nvarchar(24) collate database_default null, duration int NULL,
		comments nvarchar(4000) NULL, delivery_time int NULL, 
		delivered_transactions int NULL, delivered_commands int NULL, 
		average_commands int NULL, delivery_rate int NULL, 
		delivery_latency int NULL, error_id INT NULL,
		job_id binary(16) NULL, local_job bit NULL, profile_id int NOT NULL, 
		agent_id int NOT NULL, local_timestamp binary(8) NOT NULL, 
		offload_enabled bit NOT NULL, offload_server sysname collate database_default null,
		subscriber_type tinyint NULL)

	open #hCdatabase
	fetch next from #hCdatabase into @db_name
	while (@@fetch_status <> -1)
	begin     
		-- script the insert command to cache the agent metadata in temp table 
		-- for this distribution database
		select @cmd = 'insert into #distribution_agents exec ' + quotename(@db_name) + '.dbo.sp_MSenum_distribution @show_distdb = 1, @exclude_anonymous = 0' 
	
		-- execute the insert command
		exec (@cmd)
		fetch next from #hCdatabase into @db_name
	end

	close #hCdatabase
	deallocate #hCdatabase

	delete from #distribution_agents where publisher_db <> db_name()

	-- ========================== 2. FIND SKIPERRORS AGENT PROFILE
	declare @skipErrorsAgentProfileFound as bit
	set @skipErrorsAgentProfileFound = 0

	declare @agentProfiles as table 
	(
		id int, name sysname, agentType int, [type] int, decription nvarchar(300), isDefault bit
	)

	insert into @agentProfiles
	exec sp_help_agent_profile @agent_type = 3

	declare @skipErrorsAgentProfileId as int

	declare profilesCursor cursor for
	select id from @agentProfiles

	declare @skipErorrCodes table 
	(
		code int
	)

	insert into @skipErorrCodes values ('2601')
	insert into @skipErorrCodes values ('2627')
	insert into @skipErorrCodes values ('20598')

	open profilesCursor
	fetch next from profilesCursor into @skipErrorsAgentProfileId
	while @@fetch_status = 0
	begin

		declare @agentParameters as table
		(
			profileId int, name sysname, value nvarchar(255)
		)

		insert into @agentParameters
		exec sp_help_agent_parameter @skipErrorsAgentProfileId

		declare @skippedErrors as nvarchar(250)
		select @skippedErrors = value from @agentParameters where name = '-SkipErrors'

		if not exists (select code from @skipErorrCodes where code not in (select item from [dbo].[DelimitedSplit] (@skippedErrors, ':')))
		begin

			set @skipErrorsAgentProfileFound = 1
			break;

		end

		fetch next from profilesCursor into @skipErrorsAgentProfileId

	end

	close profilesCursor
	deallocate profilesCursor

	if @skipErrorsAgentProfileFound = 0
	begin
		raiserror('В списке профилей агента распространителя не найден профиль ''continue on data consistency errors. Обратитесь за помощью в службу поддержки.''', 16, 1)
	end
	else
	begin
		-- ========================== 3. CHANGE DISTRIBUTION AGENT PROFILE FOR EACH AGENT
		declare @agentId as int
	
		declare agentsCursor cursor for
		select agent_id from #distribution_agents

		open agentsCursor
		fetch next from agentsCursor into @agentId
		while @@fetch_status = 0
		begin
		
			exec distribution.dbo.sp_update_agent_profile @agent_type = @distributionAgentProfileType, @agent_id = @agentId, @profile_id = @skipErrorsAgentProfileId
			fetch next from agentsCursor into @agentId

		end

		drop table #distribution_agents
		close agentsCursor
		deallocate agentsCursor

		-- ========================== 4. CHANGE DEFAULT DISTRIBUTION AGENT PROFILE
		exec distribution.dbo.sp_MSupdate_agenttype_default @profile_id = @skipErrorsAgentProfileId
	end
end

go
/*********************************************************************/
/* end !ChangeDistributionAgentProfile.sql */
/*********************************************************************/
-- =====================   Обновление версии БД. 9.2.20.18 - номер версии, 2014-07-25 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.18', st_moduledate = convert(datetime, '2014-07-25', 120),  st_financeversion = '9.2.20.18', st_financedate = convert(datetime, '2014-07-25', 120)
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
	SET SS_ParmValue='2014-07-25' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO