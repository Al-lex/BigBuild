/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 24.03.2014 17:30 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.9'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.10'

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
/* begin ChangeDistributionAgentProfile.sql */
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
/* end ChangeDistributionAgentProfile.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.03.31)_Alter_Table_SystemSettings.sql */
/*********************************************************************/
-- скрипт устанавливает признак "not for replication" в true для колонки ss_id таблицы SystemSettings

if dbo.mwReplIsPublisher() > 0 or dbo.mwReplIsSubscriber() > 0
begin

	if not exists (select top 1 1 from sys.identity_columns col 
				left join sys.tables tab on col.object_id = tab.object_id
				where tab.name = 'systemsettings'
					and col.name = 'ss_id'
					and col.is_identity = 1
					and col.is_not_for_replication = 1)
	begin

		begin transaction

		alter table SystemSettings drop column SS_Id

		alter table SystemSettings add SS_Id int identity(1, 1) not for replication

		commit transaction

	end

end

go
/*********************************************************************/
/* end (2014.03.31)_Alter_Table_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-03-19)_Insert_SYSQuotasToHistory.sql */
/*********************************************************************/
if not exists(select 1 from SystemSettings with(nolock) where SS_ParmName like 'SYSQuotasToHistory')
begin
	insert into SystemSettings (SS_ParmName, SS_ParmValue)
	values ('SYSQuotasToHistory', '1')
end
GO
/*********************************************************************/
/* end (2014-03-19)_Insert_SYSQuotasToHistory.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.08.28)_Create_Type_CheckQuotasSourceTable.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckingQuotaForDay]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckingQuotaForDay]
GO

IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'CheckQuotasSourceTable' AND ss.name = N'dbo')
	DROP TYPE [dbo].[CheckQuotasSourceTable] 
GO

CREATE TYPE [dbo].[CheckQuotasSourceTable] AS TABLE(
		[qt_svkey] [int] NULL,
		[qt_code] [int] NULL,
		[qt_subcode1] [int] NULL,
		[qt_subcode2] [int] NULL,
		[qt_agent] [int] NULL,
		[qt_prkey] [int] NULL,
		[qt_isNotCheckin] [bit] NULL, -- запрет на заезд: 1 - заезд запрещен, 0 - запрет разрешен
		[qt_release] [int] NULL,
		[qt_places] [int] NULL,
		[qt_date] [datetime] NULL,
		[qt_byroom] [int] NULL,
		[qt_type] [int] NULL,
		[qt_long] [int] NULL,
		[qt_placesAll] [int] NULL,
		[qt_stop] [smallint] NULL,
		[qt_qoid] [int] NULL,
		[qt_qdid] [int] NULL,
		[qt_byCheckin] [bit] NULL, -- вид квоты: 1 - на заезд, 0 - на период
		[qt_key] [int] not null identity(1,1)
	)
GO
GRANT EXECUTE ON TYPE::dbo.[CheckQuotasSourceTable] TO public
go

/*********************************************************************/
/* end (2013.08.28)_Create_Type_CheckQuotasSourceTable.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckingQuotaForDay.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckingQuotaForDay]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckingQuotaForDay]
GO

CREATE FUNCTION [dbo].[mwCheckingQuotaForDay]
(	
	--<VERSION>9.2.21.02</VERSION>
	--<DATE>2014-03-07</DATE>
	-- функция проверки квот на день
	@tmpQuotas CheckQuotasSourceTable readonly, -- таблица подходящих квот на день
	@isFirstDay bit -- первый ли день предоставления услуги (день заезда)
	)
returns @resultTable table(   -- возвращаем параметры приоритетной квоты
	qt_state smallint,        -- 0 - стоп-сейл или запрет на заезд (0)
							  -- 1 - нет мест (@noPlacesResult)
							  -- 2 - релиз-период (@expiredReleaseResult)
							  -- 3 - квота отсутствует
							  -- 4 - есть свободные места
							  -- статусы в порядке уменьшения приоритета
	qt_qdid int,
	qt_places int,
	qt_allPlaces int,
	qt_byCheckin bit -- вид квоты: 1 - на заезд, 0 - на период
	)
begin
	-- создаем новую переменную, чтобы иметь возможность изменять ее
	DECLARE @tmpQuotasOnDay CheckQuotasSourceTable
	INSERT INTO @tmpQuotasOnDay (qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,
			qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin)
	SELECT qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,qt_places,qt_date,
			qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin  
	FROM @tmpQuotas 
	--
	
	declare @currentDate datetime
	select @currentDate = currentDate from dbo.mwCurrentDate
	
	-- константы статусов, для наглядного чтения кода
	DECLARE @isStopSale smallint, @isNoPlaces smallint, @isReleasePeriod smallint, @isYesPlaces smallint
	SET @isStopSale = 0
	SET @isNoPlaces = 1
	SET @isReleasePeriod = 2
	SET @isYesPlaces = 4
	--
	
	INSERT INTO @resultTable (qt_byCheckin)
		SELECT qt_byCheckin FROM @tmpQuotasOnDay
	
	DECLARE @qdId int, @places int, @allPlaces int
						  
	-- проверяем квоту на наличие частного стоп-сейла
	IF exists(SELECT TOP 1 1 FROM @tmpQuotas JOIN StopSales ON SS_QDID = qt_qdid 
		WHERE COALESCE(SS_IsDeleted, 0) = 0)
	BEGIN
		-- если нашли стоп-сейл сразу выходим
		UPDATE @resultTable SET qt_state = @isStopSale
		RETURN
	END	
	
	-- проверяем квоту на наличие общего стоп-сейла	
	if exists(SELECT TOP 1 1 FROM @tmpQuotas, 
		QuotaObjects, StopSales
		WHERE QO_ID = SS_QOID AND QO_SVKey = qt_svkey 
		AND QO_Code = qt_code 
		AND COALESCE(QO_Subcode1, 0) = qt_subcode1
		AND COALESCE(QO_Subcode2, 0) = qt_subcode2
		and SS_Date = qt_date and SS_QDID is null
		AND COALESCE(SS_IsDeleted, 0) = 0
		and COALESCE(ss_prkey, 0) = COALESCE(qt_prkey, 0)
		and (COALESCE(SS_AllotmentAndCommitment, 0) + 1) in (qt_type, 2))
	BEGIN
		-- если нашли стоп-сейл сразу выходим
		UPDATE @resultTable SET qt_state = @isStopSale
		RETURN
	END	
	
	-- проверяем квоту на наличие запрета на заезд, если это первый день заезда
	IF (@isFirstDay = 1 AND EXISTS(SELECT TOP 1 1 FROM @tmpQuotas WHERE qt_isNotCheckin = 1))
	BEGIN
		UPDATE @resultTable SET qt_state = @isStopSale
		RETURN
	END		
	
	-- проверяем квоту на наличие свободных мест
	IF EXISTS(SELECT TOP 1 1 FROM @tmpQuotas WHERE qt_places = 0)
	BEGIN
		UPDATE @resultTable SET qt_state = @isNoPlaces
		RETURN  
	END	
	
	-- проверяем квоту на наличие релиз-периода
	IF EXISTS(SELECT TOP 1 1 FROM @tmpQuotas WHERE COALESCE(qt_release,0) > datediff(day, @currentDate, qt_date))
	BEGIN
		UPDATE @resultTable SET qt_state = @isReleasePeriod
		RETURN
	END
	
	-- если все проверки прошли, то возращаем статус есть свободные места
	SELECT @places = qt_places, @allPlaces = qt_placesAll, @qdId = qt_qdid FROM @tmpQuotasOnDay 
	UPDATE @resultTable SET qt_state = @isYesPlaces, qt_places = @places, qt_allPlaces = @allPlaces, qt_qdid = @qdId
	
	RETURN 
end
GO

GRANT SELECT  ON [dbo].[mwCheckingQuotaForDay] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwCheckingQuotaForDay.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckQuotasHotels.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotasHotels]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotasHotels]
GO

CREATE FUNCTION [dbo].[mwCheckQuotasHotels]
(	
	--<VERSION>2009.2.21.2</VERSION>
	--<DATE>2014-01-14</DATE>
	-- функция проверки квот на заезд на услугу проживание
	@code int,                  -- код услуги
	@subcode1 int,              -- вид проживания	
	@subcode2 int,	            -- тип проживания
	@agentKey int,              -- ключ агента (авторизованного пользователя)
	@partnerKey int,            -- ключ партнера (поставщика)
	@date datetime,	            -- дата начала услуги
	@days int,                  -- продолжительность услуги
	@noPlacesResult int,        -- возвращаемое значение в случае, если закончились места
	@checkAgentQuotes smallint, -- проверять ли агентские квоты
	@tourDuration int,          -- продолжительность тура
	@expiredReleaseResult int   -- возвращаемое значение, если наступил релиз-период
)

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
	qt_additional varchar(2000),
	qt_noQuotas bit)
begin	
	declare @currentDate datetime
	set @currentDate = getdate()		
	
	declare @quotasSourceTable as CheckQuotasSourceTable
		
	-- формируем таблицу с квотами и общими стопами
	insert into @quotasSourceTable 
	select 
			3, qo_code,
			coalesce(qo_subcode1, 0) as qo_subcode1,
			coalesce(qo_subcode2, 0) as qo_subcode2,
			coalesce(qp_agentkey, 0) as qp_agentkey,
			coalesce(qt_prkey, 0) as qt_prkey,
			coalesce(qp_isnotcheckin, 0) as qp_isnotcheckin, 
			qd_release, 
			coalesce(qp_places, 0) - coalesce(qp_busy, 0) as qt_freePlaces,
			qd_date, qt_byroom, qd_type,
			coalesce(ql_duration, 0) as ql_duration,
			coalesce(qp_places, 0) as qp_places, 0 as qt_stop,
			qo_id as qt_qoid, qd_id as qt_qdid, 
			qt_isByCheckIn
			from Quotas q with(nolock) 
			right outer join QuotaObjects qo with(nolock) on qt_id = qo_qtid 
			inner join QuotaDetails qd with(nolock) on qt_id = qd_qtid 
			inner join QuotaParts qp with(nolock) on qd_id = qp_qdid
			left outer join QuotaLimitations ql with(nolock) on qp_id = ql_qpid
			where
			qt_isByCheckIn = 1 and qo_svkey = 3
			and coalesce(QD_IsDeleted, 0) = 0
			and qo_code = @code
			and coalesce(qo_subcode1, 0) in (0, @subcode1)
			and coalesce(qo_subcode2, 0) in (0, @subcode2)
			and qd_date = @date
			and (
					(coalesce(QD_LongMin, 0) <= @days and @days <= coalesce(QD_LongMax, 100500)) or
					@tourDuration < 0
				)				
			and ((@checkAgentQuotes > 0 and coalesce(qp_agentkey, 0) in (0, @agentKey))
				or (@checkAgentQuotes <= 0 and coalesce(qp_agentkey, 0) = 0))
			and (@partnerKey < 0 or coalesce(qt_prkey, 0) in (0, @partnerKey))
			union
			select
				3, qo_code,
				coalesce(qo_subcode1, 0) as qo_subcode1,
				coalesce(qo_subcode2, 0) as qo_subcode2,
				0, coalesce(ss_prkey, 0) as qt_prkey,
				0,null,0,ss_date,null,coalesce(SS_AllotmentAndCommitment, 0) + 1,0,0,1,
				qo_id as qt_qoid, null, null
			from StopSales
				inner join QuotaObjects on qo_id=ss_qoid
			where ss_date = @date
					and ss_qdid is null
					and coalesce(ss_isdeleted, 0) = 0
					and qo_svkey = 3
					and qo_code = @code
					and (coalesce(qo_subcode1, 0) in (0, @subcode1) or qo_subcode1 = 0)
					and (coalesce(qo_subcode2, 0) in (0, @subcode2) or qo_subcode2 = 0)
					and (@partnerkey < 0 or coalesce(ss_prkey, 0) in (coalesce(@partnerkey, 0), 0))
	order by
			qd_date, qt_stop desc, qp_agentkey desc, qt_freePlaces, QD_Release desc, qd_type desc, QT_PrKey desc, qp_isnotcheckin, ql_duration desc, qo_subcode1 desc, qo_subcode2 desc	
	
	-- если нет ни одной квоты и ни одного стопа, то возвращаем запрос
	if not exists (select top 1 1 from @quotasSourceTable) 
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_noQuotas)
		values(0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 1)		
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
	insert into @quotasTableWithStops (qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin)
	select qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin 
	from @quotasSourceTable
	where (qt_stop = 0
		and not exists (select top 1 1 from StopSales where SS_QDID = qt_qdid and coalesce(ss_isdeleted, 0) = 0))
	or qt_stop = 1
	
	-- если после проверки на стопы не осталось квот, значит на все квоты стоят стопы, то возвращаем нет мест
	if not exists (select top 1 1 from @quotasTableWithStops where qt_stop = 0) 
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')		
		return
	end
	
	-- если стоит общий стоп на тип квоты Allotment+Commitment, то удаляем квоту Commitment и Allotment
	if exists(select top 1 1 from @quotasTableWithStops where qt_stop = 1 and qt_type = 2) 			
	begin
		delete from @quotasTableWithStops 
		from @quotasTableWithStops qt2 where qt2.qt_stop = 0 
		and exists (select top 1 1 from @quotasTableWithStops qt1 where qt1.qt_stop = 1
		and (
				(qt2.qt_subcode1 = qt1.qt_subcode1 and qt2.qt_subcode2 = qt1.qt_subcode2) or
				(@subcode1 = qt1.qt_subcode1 and @subcode2 = qt1.qt_subcode2) or
				(qt1.qt_subcode1 = 0 and  @subcode2 = qt1.qt_subcode2) or
				(qt1.qt_subcode2 = 0 and  @subcode1 = qt1.qt_subcode1) or
				(qt1.qt_subcode1 = 0 and qt1.qt_subcode2 = 0)
			) 
		)
	end
				
	-- если стоит общий стоп на тип квоты Allotment, то удаляем квоту Allotment
	if exists(select top 1 1 from @quotasTableWithStops where qt_stop = 1 and qt_type = 1) 		
	begin
		delete from @quotasTableWithStops 
		from @quotasTableWithStops qt2 where qt_stop = 0 and qt_type = 1 
		and exists (select top 1 1 from @quotasTableWithStops qt1 where qt1.qt_stop = 1 and qt1.qt_type = 1
		and (
				(qt2.qt_subcode1 = qt1.qt_subcode1 and qt2.qt_subcode2 = qt1.qt_subcode2) or
				(@subcode1 = qt1.qt_subcode1 and @subcode2 = qt1.qt_subcode2) or
				(qt1.qt_subcode1 = 0 and  @subcode2 = qt1.qt_subcode2) or
				(qt1.qt_subcode2 = 0 and  @subcode1 = qt1.qt_subcode1) or
				(qt1.qt_subcode1 = 0 and qt1.qt_subcode2 = 0)
			) 
		)
	end
				
	-- если после проверки на стопы не осталось квот, значит на все квоты стоят стопы, то возвращаем нет мест
	if not exists (select top 1 1 from @quotasTableWithStops where qt_stop = 0) 
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')		
		
		return
	end
	
	-- теперь проверяем наличие запрета на заезд
	if exists(select top 1 1 from @quotasTableWithStops where qt_stop = 0 and qt_isNotCheckin = 1)
	begin
		delete from @quotasTableWithStops 
		from @quotasTableWithStops qt2 where qt2.qt_stop = 0 		
		and exists (select top 1 1 from @quotasTableWithStops qt1 where qt1.qt_stop = 0 and qt1.qt_isNotCheckin = 1 
		and (
				(qt2.qt_subcode1 = qt1.qt_subcode1 and qt2.qt_subcode2 = qt1.qt_subcode2) or
				(@subcode1 = qt1.qt_subcode1 and @subcode2 = qt1.qt_subcode2) or
				(qt1.qt_subcode1 = 0 and  @subcode2 = qt1.qt_subcode2) or
				(qt1.qt_subcode2 = 0 and  @subcode1 = qt1.qt_subcode1) or
				(qt1.qt_subcode1 = 0 and qt1.qt_subcode2 = 0)
			) 
		)
										
		delete from @quotasTableWithStops where qt_stop = 0 and qt_isNotCheckin = 1
	end
				
	-- если после проверки на запрет на заезд не осталось квот, значит на всех квотах стоят запреты на заезд, то возвращаем нет мест
	if not exists(select top 1 1 from @quotasTableWithStops where qt_stop = 0)
	begin		
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
		
		return
	end	
	
	-- теперь проверяем наличие релиз-периода 
	if exists(select top 1 1 from @quotasTableWithStops where qt_stop = 0 and qt_release > 0 and datediff(day, qt_release, qt_date) < @currentDate) 			
	begin
		delete from @quotasTableWithStops where qt_stop = 0 and qt_release > 0 and datediff(day, qt_release, qt_date) < @currentDate
	end
			
	-- если после проверки на релиз-период не осталось квот, значит на всех квотах наступил релиз-период, то возвращаем запрос
	if not exists(select top 1 1 from @quotasTableWithStops where qt_stop = 0)
	begin		
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, @expiredReleaseResult, 0, 0, 0, '0=' + ltrim(rtrim(str(@expiredReleaseResult))) + ':0')
		
		return		
	end	
	
	-- если после всех проверок есть квоты, на них нет мест, то возвращаем @noPlacesResult
	if not exists(select top 1 1 from @quotasTableWithStops where qt_stop = 0 and qt_places > 0)
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, 
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, @noPlacesResult, 0, 0, 0, '0=' + ltrim(rtrim(str(@noPlacesResult))) + ':0')
		
		return
	end
	
	-- если после всех проверок есть квоты и на них есть места
	if @checkAgentQuotes > 0 
	begin
		-- сначала проверяем агентскую квоту, если она существует, то выводим ее
		if exists(select top 1 1 from @quotasTableWithStops where qt_stop = 0 and qt_agent > 0)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
				qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
			select top 1 qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_bycheckin,
				qt_byroom, qt_places, qt_placesAll, qt_type, qt_long, '0=' + cast(qt_places as varchar(20)) + ':' + cast(qt_placesAll as varchar(20)) as qt_additional  
			from @quotasTableWithStops 
			where qt_stop = 0 and qt_agent > 0
			order by qt_places desc
					
			return
		end
	end	
	
	insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
		qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
	select top 1 qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_isNotCheckin,
		qt_byroom, qt_places, qt_placesAll, qt_type, qt_long, '0=' + cast(qt_places as varchar(20)) + ':' + cast(qt_placesAll as varchar(20)) as qt_additional
	from @quotasTableWithStops 
	where qt_stop = 0 and qt_places > 0
	order by qt_places desc
	
	return
end
GO

GRANT SELECT ON [dbo].[mwCheckQuotasHotels] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwCheckQuotasHotels.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckQuotasHotelsOnPeriod.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotasHotelsOnPeriod]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotasHotelsOnPeriod]
GO

CREATE FUNCTION [dbo].[mwCheckQuotasHotelsOnPeriod]
(	
	--<VERSION>2009.2.21.6</VERSION>
	--<DATE>2014-03-18</DATE>
	-- функция проверки квот на период на услугу проживание
	@svkey int,                  -- класс услуги
	@code int,                   -- код услуги
	@subcode1 int,               -- вид проживания	
	@subcode2 int,	             -- тип проживания
	@agentKey int,               -- ключ агента (авторизованного пользователя)
	@partnerKey int,             -- ключ партнера (поставщика)
	@dateFrom datetime,	         -- дата начала услуги
	@dateTo datetime,
	@days int,                   -- продолжительность услуги
	@long int,
	@requestOnRelease smallint, 
	@noPlacesResult int,         -- возвращаемое значение в случае, если закончились места
	@checkAgentQuotes smallint,  -- проверять ли агентские квоты
	@checkCommonQuotes smallint, -- проверять ли общие квоты
	@checkNoLongQuotes smallint, -- проверять ли квоты на продолжительность
	@tourDuration int,           -- продолжительность тура
	@expiredReleaseResult int    -- возвращаемое значение, если наступил релиз-период
)

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
	qt_additional varchar(2000),
	qt_noQuotas bit)
begin		
	declare @tmpQuotas as CheckQuotasSourceTable, @additional varchar(2000)

	-- описание полей типа CheckQuotasSourceTable
	--TYPE [dbo].[CheckQuotasSourceTable] AS TABLE(
	--	[qt_svkey] [int] NULL,
	--	[qt_code] [int] NULL,
	--	[qt_subcode1] [int] NULL,
	--	[qt_subcode2] [int] NULL,
	--	[qt_agent] [int] NULL,
	--	[qt_prkey] [int] NULL,
	--	[qt_isNotCheckin] [bit] NULL, -- запрет на заезд: 1 - заезд запрещен, 0 - запрет разрешен
	--	[qt_release] [int] NULL,
	--	[qt_places] [int] NULL,
	--	[qt_date] [datetime] NULL,
	--	[qt_byroom] [int] NULL,
	--	[qt_type] [int] NULL,
	--	[qt_long] [int] NULL,
	--	[qt_placesAll] [int] NULL,
	--	[qt_stop] [smallint] NULL,
	--	[qt_qoid] [int] NULL,
	--	[qt_qdid] [int] NULL,
	--	[qt_byCheckin] [bit] NULL,   -- вид квоты: 1 - на заезд, 0 - на период
	--	[qt_key] [int] not null identity(1,1)
	--)
		
	INSERT INTO @tmpQuotas (qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,
		qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin)
	SELECT 
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
		0 as qt_stop,
		qo_id as qt_qoid, qd_id as qt_qdid, QT_IsByCheckIn
	FROM quotas q with(nolock) inner join 
		quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
		left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
		right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid 
	WHERE
		qt_isByCheckIn = 0 and qo_svkey = @svkey
		and ISNULL(QD_IsDeleted, 0) = 0
		and qo_code = @code
		and isnull(qo_subcode1, 0) in (0, @subcode1)
		and isnull(qo_subcode2, 0) in (0, @subcode2)
		and ((@checkAgentQuotes > 0 and isnull(qp_agentkey, 0) in (0, @agentKey)) or
			(@checkAgentQuotes <= 0 and isnull(qp_agentkey, 0) = 0))
		and (@partnerKey < 0 or isnull(qt_prkey, 0) in (0, @partnerKey))
		and ((@days = 1 and qd_date = @dateFrom) or (@days > 1 and qd_date between @dateFrom and @dateTo))
		and (@tourDuration < 0 
			or (@tourDuration >= 0 and isnull(ql_duration, 0) in (0, @long)))
	UNION
	SELECT QO_SVKey, QO_Code,
		COALESCE(QO_SubCode1, 0) as QO_SubCode1,
		COALESCE(QO_SubCode2, 0) as QO_SubCode2,
		0 AS QP_AgentKey,
		isnull(SS_PRKey, 0) as QT_PRKey,
		0 AS QP_IsNotCheckIn, NULL AS QD_Release,
		0 AS QP_FreePlaces, SS_Date AS QD_Date, 
		0 AS QT_ByRoom, 
		COALESCE(SS_AllotmentAndCommitment, 0) + 1 AS QD_Type,
		0 AS QL_Duration,   
		0 AS QP_Places, 
		1 AS QT_Stop, QO_ID, NULL AS QD_ID, 
		0 AS QT_IsByCheckIn
	from StopSales
		inner join QuotaObjects on qo_id=ss_qoid
	where ((@days = 1 and ss_date = @dateFrom) 
			or (@days > 1 and ss_date between @dateFrom and @dateTo))
		and SS_QDID IS NULL
		and COALESCE(ss_isdeleted, 0) = 0
		and qo_svkey = @svkey
		and qo_code = @code
		and COALESCE(qo_subcode1, 0) in (0, @subcode1)
		and COALESCE(qo_subcode2, 0) in (0, @subcode2)
		and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))	
	order by
		qd_date, qp_agentkey DESC, qt_freePlaces, QD_Release desc, qd_type DESC, QT_PrKey DESC, 
		qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC, qo_subcode2 DESC
		
	-- если нет ни одной квоты, то возвращаем запрос
	if not exists (select top 1 1 from @tmpQuotas) 
	begin
		INSERT INTO @tmpResQuotes (qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey,
		qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		VALUES (0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, '0=-1:0')
		RETURN
	end	
	
	DECLARE @numberDay int, @currentDate datetime, @isFirstDay bit, -- первый ли день предоставления услуги (день заезда)
		@currentQuotaPlaces int, @currentAllPlaces int
	
	SET @additional = ''		
		
	-- надо проверить все возможные квоты по дням, на все возможные продолжительности 
	-- (используется при проверке наличия мест в отеле в экране HotelQuotes)
	IF(@tourDuration < 0)
	BEGIN
		DECLARE @durations table(
			duration int
		)
		
		-- заполняем таблицу с продолжительностями, чтобы проверить квоты на каждую продолжительность	
		insert into @durations select distinct qt_long from @tmpQuotas order by qt_long

		DECLARE @rowCount int
		SET @rowCount = @@rowCount
		
		IF(@rowCount > 1)
		BEGIN
			DECLARE @quotaDuration int
			DECLARE durationCur cursor fast_forward read_only for
				SELECT duration FROM @durations
	
			OPEN durationCur
	
			FETCH NEXT FROM durationCur INTO @quotaDuration
			WHILE(@@fetch_status = 0)
			BEGIN
				IF(len(@additional) > 0)
				BEGIN
					SET @additional = @additional + '|'
				END
	
				select top 1
					@additional = @additional + qt_additional
				from dbo.mwCheckQuotasHotelsOnPeriod(@svkey, @code, @subcode1, @subcode2, @agentKey, @partnerKey, 
					@dateFrom, @dateTo, @days, @quotaDuration, @requestOnRelease, @noPlacesResult, @checkAgentQuotes, 
					@checkCommonQuotes, @checkNoLongQuotes, 1, @expiredReleaseResult)
				order by (
							case
								when qt_additional is not null 
								then CONVERT(
											int,SUBSTRING(
														qt_additional,
														CHARINDEX('=',qt_additional) + 1,
														(CHARINDEX(':', qt_additional) - 1) - CHARINDEX('=', qt_additional)
														)
											)
							else 0
							end
						) DESC 
	
				FETCH NEXT FROM durationCur INTO @quotaDuration
			END			
				
			INSERT INTO @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
				qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
			VALUES(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @additional)
				
			CLOSE durationCur
			DEALLOCATE durationCur
	
			RETURN
		END
		ELSE IF EXISTS(select top 1 1 from @tmpQuotas WHERE qt_long = 0)
		BEGIN
			SET @long = 0
		END
	END 
	
	-- статусы квот
	DECLARE @currentGlobalState smallint, @currentState smallint	-- состояние квоты 
																	-- 0 - стоп-сейл или запрет на заезд (0)
																    -- 1 - нет мест (@noPlacesResult)
																    -- 2 - релиз-период (@expiredReleaseResult)
																    -- 3 - квота отсутствует
																    -- 4 - есть свободные места
																    -- статусы в порядке уменьшения приоритета													  
	-- константы статусов, для наглядного чтения кода
	DECLARE @isStopSale smallint, @isNoPlaces smallint, @isReleasePeriod smallint, @isNoQuota smallint, @isYesPlaces smallint
	SET @isStopSale = 0
	SET @isNoPlaces = 1
	SET @isReleasePeriod = 2
	SET @isNoQuota = 3
	SET @isYesPlaces = 4
	-- 
	
	-- временная таблица с результами статусов квот 
	declare @StatusTable as table (quotaState int)
	
	-- переменные, которые содержат параметры результата														 
	DECLARE @svkeyRes int, @codeRes int, @subcode1Res int, @subcode2Res int, 
			@agentRes int, @prkeyRes int, @bycheckinRes int, @qdId int, 
			@byroomRes int, @allPlacesRes int, @typeRes int, @longRes int, @releaseRes int,
			@quotaPlaces int, @sumQuotaPlaces int, @sumAllPlacesRes int
			
	SET @sumQuotaPlaces = 0
	SET @sumAllPlacesRes = 0
	
	-- переменные курсора
	DECLARE @qoid int, @qdType int, @qdAgentKey int, @qpLong int, @qoSubcode1 int, @qoSubcode2 int, 
		@qtPrKey int, @qoStop smallint
	
	-- будем ходить по определенному виду квот: относящихся к одному qo_id, к одному типу квоту и имещим одинаковую продолжительность, 
	-- ключ партнера и ключ агента,
	-- чтобы квоты не подбирались "лесенкой"
	DECLARE qCur CURSOR FOR
		SELECT qt_qoid, qt_subcode1, qt_subcode2, qt_prkey, qt_stop, qt_agent, qt_long, qt_type FROM @tmpQuotas 
		GROUP BY qt_qoid, qt_subcode1, qt_subcode2, qt_prkey, qt_stop, qt_agent, qt_long, qt_type 
		ORDER BY  qt_subcode1 DESC, qt_subcode2 DESC, qt_prkey DESC, qt_agent DESC, qt_long DESC, qt_type DESC, qt_stop DESC
		
	OPEN qCur
	FETCH NEXT FROM qCur INTO @qoId, @qoSubcode1, @qoSubcode2, @qtPrKey, @qoStop, @qdAgentKey, @qpLong, @qdType 
	WHILE(@@fetch_status = 0)
	BEGIN
		-- если самым приоритетным по объекту квотирования является стоп-сейл на Allotment+Commitment, 
		-- то сразу выходим
		IF (@qoStop = 1 AND @qdType = 2)
		BEGIN
			INSERT INTO @StatusTable (quotaState) VALUES (@isStopSale)
			BREAK;
		END
		
		-- если самым приоритетным по объекту квотирования является стоп-сейл на Allotment,
		-- то проверяем нет ли приоритетной квоты на Commitment  
		IF (@qoStop = 1 AND @qdType = 1)
		BEGIN
			INSERT INTO @StatusTable (quotaState) VALUES (@isStopSale)
			IF NOT EXISTS(SELECT TOP 1 1 FROM @tmpQuotas WHERE qt_stop = 0 AND qt_type = 2)
			BEGIN
				BREAK;
			END
			ELSE
			BEGIN
				FETCH NEXT FROM qCur INTO @qoId, @qoSubcode1, @qoSubcode2, @qtPrKey, @qoStop, @qdAgentKey, @qpLong, @qdType 
				CONTINUE;
			END
		END
		
		SET @currentGlobalState = -1
		SET @numberDay = 0			
		SET @isFirstDay = 0
		SET @quotaPlaces = 0
		SET @currentDate = @dateFrom
		
		WHILE @currentDate <= @dateTo 
		BEGIN			
			-- если это первый день предоставления услуги
			if (@numberDay = 0)
			BEGIN
				SET @isFirstDay = 1 
			END
			
			DECLARE @tmpQuotasOnDay AS CheckQuotasSourceTable 
		
			INSERT INTO @tmpQuotasOnDay (qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,
				qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin)
			SELECT qt_svkey,qt_code,qt_subcode1,qt_subcode2,qt_agent,qt_prkey,qt_isNotCheckin,qt_release,
				qt_places,qt_date,qt_byroom,qt_type,qt_long,qt_placesAll,qt_stop,qt_qoid,qt_qdid,qt_byCheckin  
			FROM @tmpQuotas
			WHERE qt_qoid = @qoId AND qt_type = @qdType AND qt_date = @currentDate AND qt_agent = @qdAgentKey AND qt_long = @qpLong
			
			-- если на этот день квота отсутствует
			IF (NOT EXISTS(SELECT TOP 1 1 FROM @tmpQuotasOnDay WHERE qt_stop = 0) AND @currentGlobalState NOT IN (@isNoPlaces, @isReleasePeriod))
			BEGIN
				-- проверяем, нет ли общего стопа на этот день
				IF EXISTS(SELECT TOP 1 1 FROM @tmpQuotas 
					WHERE qt_subcode1 IN (@subcode1, 0) AND qt_subcode1 IN (@subcode2, 0)
					AND qt_prkey IN (@partnerKey, 0) AND qt_date = @currentDate AND qt_stop > 0)
				BEGIN
					SET @currentGlobalState = @isStopSale
					SET @isFirstDay = 0
					SET @numberDay = @numberDay + 1
					SET @currentDate = DATEADD(DAY, @numberDay, @dateFrom)
					DELETE FROM @tmpQuotasOnDay
					BREAK;
				END
				ELSE
				-- если нет, то выводим нет мест
				BEGIN
					SET @currentGlobalState = @isNoQuota
					SET @isFirstDay = 0
					SET @numberDay = @numberDay + 1
					SET @currentDate = DATEADD(DAY, @numberDay, @dateFrom)
					DELETE FROM @tmpQuotasOnDay
					CONTINUE;
				END		
			END
			
			-- проверяем квоту на наличие общего стоп-сейла
			IF EXISTS(SELECT TOP 1 1 FROM @tmpQuotasOnDay q, @tmpQuotas s 
					WHERE s.qt_stop > 0 AND q.qt_code = s.qt_code 
					AND s.qt_subcode1 IN (@subcode1, 0) AND s.qt_subcode2 IN (@subcode2, 0)
					AND s.qt_prkey in (q.qt_prkey, 0) AND q.qt_date = s.qt_date 
					AND s.qt_type in (q.qt_type, 2))
			BEGIN
				SET @currentGlobalState = @isStopSale
				SET @isFirstDay = 0
				SET @numberDay = @numberDay + 1
				SET @currentDate = DATEADD(DAY, @numberDay, @dateFrom)
				DELETE FROM @tmpQuotasOnDay
				BREAK;
			END	
			
			-- проверяем квоту на наличие частного стоп-сейла 
			IF EXISTS(SELECT TOP 1 1 FROM @tmpQuotasOnDay, StopSales, QuotaObjects
				WHERE SS_QOID = QO_ID AND QO_Code = qt_code AND QO_SVKey = qt_svkey 
				AND SS_QDID is NOT NULL AND  SS_Date = qt_date AND SS_PRKey IN (qt_prkey, 0)
				AND (QO_SubCode1 = 0 OR (QO_SubCode1 = @subcode1 AND qt_subcode1 = 0)) 
				AND (QO_SubCode2 = 0 OR (QO_SubCode2 = @subcode2 AND qt_subcode2 = 0)) 
				AND SS_AllotmentAndCommitment = (qt_type -1)
				AND COALESCE(SS_IsDeleted, 0) = 0)			
			BEGIN
				SET @currentGlobalState = @isStopSale
				SET @isFirstDay = 0
				SET @numberDay = @numberDay + 1
				SET @currentDate = DATEADD(DAY, @numberDay, @dateFrom)
				DELETE FROM @tmpQuotasOnDay
				BREAK;
			END
			
			-- запускаем функцию проверки по дням 
			SELECT @currentState = qt_state, @qdId = qt_qdid, @currentQuotaPlaces = qt_places, 
				@currentAllPlaces = qt_allPlaces
			FROM dbo.mwCheckingQuotaForDay(@tmpQuotasOnDay, @isFirstDay)	
			
			-- если на квоту стоит стоп-сейл или запрет заезда
			IF (@currentState = @isStopSale)
			BEGIN
				SET @currentGlobalState = @currentState
				SET @isFirstDay = 0
				SET @numberDay = @numberDay + 1
				SET @currentDate = DATEADD(DAY, @numberDay, @dateFrom)
				DELETE FROM @tmpQuotasOnDay
				BREAK;
			END
			
			-- если на приоритетную квоту закончились места
			IF (@currentState = @isNoPlaces)
			BEGIN
				SET @currentGlobalState = @currentState
			END
			
			-- если на приоритетную квоту наступил релиз-период
			IF (@currentState = @isReleasePeriod AND @currentGlobalState != @isNoPlaces)
			BEGIN
				SET @currentGlobalState = @currentState
			END
			
			-- если на приоритетную квоту есть места
			IF (@currentState = @isYesPlaces AND @currentGlobalState NOT IN (@isNoPlaces, @isReleasePeriod, @isNoQuota)
				AND (@quotaPlaces > @currentQuotaPlaces or @quotaPlaces = 0))
			BEGIN
				SET @currentGlobalState = @currentState
				SET @quotaPlaces = @currentQuotaPlaces
				SET @allPlacesRes = @currentAllPlaces
				
				SELECT @svkeyRes = qt_svkey, @codeRes = qt_code, @subcode1Res = qt_subcode1, @subcode2Res = qt_subcode2,
				@agentRes = qt_agent, @prkeyRes = qt_prkey, @bycheckinRes = qt_isNotCheckin, @byroomRes = qt_byroom,
				@typeRes = qt_type, @longRes = qt_long FROM @tmpQuotasOnDay
				WHERE qt_qdid = @qdId
			END
			
			SET @isFirstDay = 0
			SET @numberDay = @numberDay + 1
			SET @currentDate = DATEADD(DAY, @numberDay, @dateFrom)
			DELETE FROM @tmpQuotasOnDay
		END
		
		IF (@currentGlobalState = @isYesPlaces)
		BEGIN
			SET @sumQuotaPlaces = @sumQuotaPlaces + @quotaPlaces
			SET @sumAllPlacesRes = @sumAllPlacesRes + @allPlacesRes
		END
		
		INSERT INTO @StatusTable (quotaState) VALUES (@currentGlobalState)
		
		-- если мы проверили агентскую квоту и стоит настройка общую квоту не проверять
		IF (@qdAgentKey > 0 AND @checkAgentQuotes > 0 and @checkCommonQuotes <= 0)
		BEGIN
			BREAK;
		END
			
		-- если мы проверили квоту на продолжительность и стоит настройка общую квоту не проверять
		IF (@qpLong > 0 AND @checkNoLongQuotes <= 0)
		BEGIN
			BREAK;
		END
		
		-- если на приоритетном объекте квотирования стоит стоп-сейл или запрет заезда, 
		-- то проверяем нет ли такой же квоты, но с другим типом квоты, еще, 
		-- если нет, то выходим
		IF (@currentGlobalState = @isStopSale AND 
			NOT EXISTS(SELECT TOP 1 1 
				FROM @tmpQuotas 
				WHERE qt_subcode1 = @qoSubcode1
				AND qt_subcode2 = @qoSubcode2
				AND qt_prkey = @qtPrKey
				AND qt_type <> @qdType)) 
		BEGIN
			BREAK;
		END
		
		FETCH NEXT FROM qCur INTO @qoId, @qoSubcode1, @qoSubcode2, @qtPrKey, @qoStop, @qdAgentKey, @qpLong, @qdType 
	END
	
	CLOSE qCur
	DEALLOCATE qCur
	
	-- есть свободные места на все дни продолжительности услуги
	IF EXISTS(SELECT TOP 1 1 FROM @StatusTable WHERE quotaState = @isYesPlaces)
	BEGIN
		set @additional = ltrim(str(@longRes)) + '=' + ltrim(str(@sumQuotaPlaces)) + ':' + ltrim(str(@sumAllPlacesRes))
		
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
		qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(@svkeyRes, @codeRes, @subcode1Res, @subcode2Res, @agentRes, @prkeyRes,
		@bycheckinRes, @byroomRes, @sumQuotaPlaces, @sumAllPlacesRes, @typeRes, @longRes, @additional)
		RETURN
	END
	
	-- если на квоте нет ни одной квоты
	IF EXISTS(SELECT TOP 1 1 FROM @StatusTable WHERE quotaState = @isNoQuota)
	BEGIN
		set @additional = ltrim(rtrim(str(@long))) + '=-1:0'
		
		INSERT INTO @tmpResQuotes (qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey,
		qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		VALUES (0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, @additional)
		RETURN
	END
	
	-- если на квоте наступил релиз-период
	IF EXISTS(SELECT TOP 1 1 FROM @StatusTable WHERE quotaState = @isReleasePeriod)
	BEGIN
		set @additional = ltrim(rtrim(str(@long))) + '=' + ltrim(rtrim(str(@expiredReleaseResult))) + ':0'
		
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
		qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, @expiredReleaseResult, 0, 0, 0, @additional)
		RETURN
	END
	
	-- если на квоте закончились места 
	IF EXISTS(SELECT TOP 1 1 FROM @StatusTable WHERE quotaState = @isNoPlaces)
	BEGIN		
		set @additional = ltrim(rtrim(str(@long))) + '=' + ltrim(rtrim(str(@noPlacesResult))) + ':0'
		
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
		qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, @noPlacesResult, 0, 0, 0, @additional)
		RETURN
	END
	
	-- если на квоте наступил стоп-сейл
	IF EXISTS(SELECT TOP 1 1 FROM @StatusTable WHERE quotaState = @isStopSale)
	BEGIN	
		set @additional = ltrim(rtrim(str(@long))) + '=0:0'
		INSERT INTO @tmpResQuotes (qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey,
			qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		VALUES (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @additional)
		RETURN
	END
	
	return
end
GO

GRANT SELECT ON [dbo].[mwCheckQuotasHotelsOnPeriod] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwCheckQuotasHotelsOnPeriod.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckQuotesFlights.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesFlights]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesFlights]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesFlights]
(	
	--<VERSION>2009.2.21.04</VERSION>
	--<DATE>2014-03-18</DATE>
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
			ch_key int
		)		
	
	-- подбираем подходящие нам перелеты
	-- проверяем наличие расписания и не стоит ли стоп на перелет, через плагин Stop-Avia	
	-- если ключ пакета больше или равен нулю (@flightpkkey >= 0), то проверяем заведена ли цена на авиаперелет
	insert into @chartersKeyTable (ch_key)
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
		and ((@flightpkkey >= 0 
				and exists (select top 1 1 from tbl_costs 
					where cs_svkey = 1 
					and cs_code = ch_key 
					and cs_subcode1 in (@subcode1, 0) 
					and (@date between cs_date and cs_dateend
						or @date between cs_checkindatebeg and cs_checkindateend)
					and (COALESCE(cs_week, '') = '' or cs_week LIKE ('%' + cast(@dayOfWeek as varchar) + '%'))
					and cs_pkkey = @flightpkkey))
				or (@flightpkkey < 0))
		
	if not exists (select top 1 1 from @chartersKeyTable)
	begin
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
			qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
		return
	end	
	
	declare @currentDate datetime
	set @currentDate = getdate()		
	
	declare @oldPartnerKey int
	-- сохраняем ключ партнера, чтобы находить стопы, только от данного партнера
	set @oldPartnerKey = @partnerKey
	if (@findFlight > 0)
	begin 
		-- подбираем перелеты от разных партнеров
		set @partnerKey = -1 
	end
	
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
			inner join @chartersKeyTable on qo_code = ch_key
			inner join QuotaDetails qd with(nolock) on qt_id = qd_qtid 
			inner join QuotaParts qp with(nolock) on qd_id = qp_qdid
			left outer join QuotaLimitations ql with(nolock) on qp_id = ql_qpid								
			where
			qo_svkey = 1 and COALESCE(QD_IsDeleted, 0) = 0 and COALESCE(qo_subcode1, 0) in (0, @subcode1)
			and ((@checkAgentQuotes > 0 and coalesce(qp_agentkey, 0) in (0, @agentKey))
				or (@checkAgentQuotes <= 0 and coalesce(qp_agentkey, 0) = 0)) 
			and (@partnerKey < 0 or COALESCE(qt_prkey, 0) in (0, @partnerKey))
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
			where ss_date = @date
					and ss_qdid is null
					and COALESCE(ss_isdeleted, 0) = 0
					and qo_svkey = 1
					and qo_code = @code
					and (COALESCE(qo_subcode1, 0) in (0, @subcode1) or qo_subcode1 = 0)
					and (@oldPartnerKey < 0 or COALESCE(ss_prkey, 0) in (COALESCE(@oldPartnerKey, 0), 0))
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
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
					select top 1 qt_svkey, qt_code, qt_subcode1, 0, qt_agent, qt_prkey, qt_isNotCheckin,
						qt_byroom, qt_places, qt_placesAll, qt_type, qt_long 
					from @tmpQuotes 
					where qt_stop = 0 and qt_agent = 0 and qt_places > 0
					order by qt_places desc
					
					select @datePlaces = SUM(qt_Places), @dateAllPlaces = SUM(qt_placesAll) 
					from @tmpQuotes where qt_stop = 0 AND qt_agent = 0 AND qt_places > 0
					
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
				if exists (select top 1 1 from @tmpQuotes where qt_prkey = @oldPartnerKey and qt_stop = 0 and qt_places > 0) and @findFlight > 0
				begin
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
					select top 1 qt_svkey, qt_code, qt_subcode1, 0, qt_agent, qt_prkey, qt_isNotCheckin,
						qt_byroom, qt_places, qt_placesAll, qt_type, qt_long 
					from @tmpQuotes 
					where qt_prkey = @oldPartnerKey and qt_stop = 0 and qt_places > 0
					
					select @datePlaces = SUM(qt_Places), @dateAllPlaces = SUM(qt_placesAll) 
					from @tmpQuotes where qt_prkey = @oldPartnerKey and qt_stop = 0 and qt_places > 0
				end
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
			
			if (@requestOnRelease <= 0 and @findFlight <= 0)
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
/* begin fn_mwCheckQuotesEx2.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesEx2]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesEx2]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesEx2]
(
	@svkey int, -- класс услуги
	@code int, -- код услуги
	@subcode1 int, -- вид проживания (sv_key = 3) или тариф на авиаперелеты (sv_key = 1)
	@subcode2 int, -- тип проживания (sv_key = 3) или равен -1 (sv_key = 1)
	@agentKey int, -- ключ агента (авторизованного пользователя)
	@partnerKey int, -- ключ партнера (поставщика)
	@date datetime, -- дата начала тура	
	@day int, -- день, с которого предоставляется услуга
	@days int, -- продолжительность услуги
	@requestOnRelease smallint, 
	@noPlacesResult int, -- возвращаемое значение в случае, если закончились места
	@checkAgentQuotes smallint, -- проверять ли агентские квоты
	@checkCommonQuotes smallint, -- проверять ли общие квоты
	@checkNoLongQuotes smallint, -- проверять ли квоты на продолжительность
	@findFlight smallint, -- искать ли заменяющий перелет в случае отсутствия квот
	@cityFrom int, -- город отправления
	@cityTo int, -- город прибытия
	@flightpkkey int, -- ключ пакета, в котором ищется заменяющий перелет
	@tourDuration int, -- продолжительность тура
	@expiredReleaseResult int, -- возвращаемое значение, если наступил релиз-период
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
	--<VERSION>9.2.21.05</VERSION>
	--<DATE>2014-02-25</DATE>

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

	-- для квот на продолжительность
	declare @long int
	if(@svkey = 1 or @svkey = 2 or @svkey = 4)
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
			@dateFrom, @day, @requestOnRelease, @noPlacesResult, @checkAgentQuotes, @checkCommonQuotes,
			@checkNoLongQuotes, @findFlight, @cityFrom, @cityTo, @flightpkkey,
			@tourDuration, @expiredReleaseResult, @linked_day)
		
		return
	end
	else
	begin
		-- промежуточная таблица результата
		declare @tmpIntermediateResQuotes table(
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
			qt_additional varchar(2000),
			qt_noQuotas bit -- признак, что квота вообще не заведена
		)
		
		declare @tmpSubcode1 int
		if(@svkey = 3 and @subcode1 > 0 and @subcode2 <= 0) 
		begin
			select @tmpSubcode1 = hr_rmkey, @subcode2 = hr_rckey from hotelrooms with(nolock) where hr_key = @subcode1
			set @subcode1 = @tmpSubcode1
		end
		
		-- начало проверки квот на заезд на проживание
		insert into @tmpIntermediateResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, 
									qt_long, qt_additional, qt_noQuotas)
		-- функция проверки квот на заезд на проживание
		select *
		from dbo.mwCheckQuotasHotels(@code, @subcode1, @subcode2, @agentKey, @partnerKey, 
			@dateFrom, @days, @noPlacesResult, @checkAgentQuotes, @tourDuration, @expiredReleaseResult)
		
		-- если существует свободные места на заезд, то квоты на период не проверяем	
		if exists(select top 1 1 from @tmpIntermediateResQuotes where qt_places > 0)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
			select qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional
									from @tmpIntermediateResQuotes where qt_places > 0									
			return
		end
		
		-- если квота на заезд вообще не заведена, эту информацию в таблице результата не сохраняем,
		-- т.к. при проверке квот на период будет информация о квотах, не будем засорять таблицу
		if exists(select top 1 1 from @tmpIntermediateResQuotes where qt_noQuotas = 1)
		begin
			delete from @tmpIntermediateResQuotes
		end
		
		-- есть четыре варианта после проверки квот на заезд:
		--	есть места 
		--  квоты не заведены
		--  запрос (наступил релиз-период)
		--  нет мест (нет свободных мест, запрет на заезд или стоп-сейл) 
		-- если есть места, то сразу выходим 
		-- если возвращается запрос и нет мест, то обрабатываем ниже
		
		-- окончание проверки квот на заезд на проживание
		
		
		-- начало проверки квот на период на проживание
		insert into @tmpIntermediateResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, 
									qt_long, qt_additional, qt_noQuotas)
		-- функция проверки квот на период на проживание
		select *
		from dbo.mwCheckQuotasHotelsOnPeriod(@svkey, @code, @subcode1, @subcode2, @agentKey, @partnerKey, 
			@dateFrom, @dateTo, @days, @long, @requestOnRelease, @noPlacesResult, @checkAgentQuotes, 
			@checkCommonQuotes, @checkNoLongQuotes, @tourDuration, @expiredReleaseResult)
		
		-- если существует свободные места на период, то выводим результат и выходим	
		if exists(select top 1 1 from @tmpIntermediateResQuotes where qt_places > 0)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
			select qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional
									from @tmpIntermediateResQuotes where qt_places > 0									
			return
		end		
		-- окончание проверки квот на период на проживание
		
		-- если в результирующей таблице есть квоты на которых наступил релиз-период или квота не заведена, то выводим результат и выходим
		if exists(select top 1 1 from @tmpIntermediateResQuotes where qt_places = -1)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
			select top 1 qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional
									from @tmpIntermediateResQuotes where qt_places = -1				
			return
		end
		
		-- если в результирующей таблице есть квоты на которых стоит стоп-сейл, нет мест или запрет на заезд, то выводим результат и выходим
		if exists(select top 1 1 from @tmpIntermediateResQuotes where qt_places = 0)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
			select top 1 qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional
									from @tmpIntermediateResQuotes where qt_places = 0								
			return
		end
		
		insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
		select top 1 qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional
									from @tmpIntermediateResQuotes 
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
/* begin dropMwReplProcedures.sql */
/*********************************************************************/
-- удаляет неиспользуемые более процедуры mwReplGetSubscriptions, mwReplAddSubscription, mwReplRemoveSubscription
if exists (select * from sys.objects where name = 'mwReplGetSubscriptions' and [type] = 'TF')
begin

	drop function mwReplGetSubscriptions

end

if exists (select * from sys.objects where name = 'mwReplAddSubscription' and [type] = 'P')
begin

	drop procedure mwReplAddSubscription

end

if exists (select * from sys.objects where name = 'mwReplRemoveSubscription' and [type] = 'P')
begin

	drop procedure mwReplRemoveSubscription

end
GO
/*********************************************************************/
/* end dropMwReplProcedures.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CopyTpPricesUpdatedToSubscriptions.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CopyTpPricesUpdatedToSubscriptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CopyTpPricesUpdatedToSubscriptions]
GO
CREATE PROCEDURE [dbo].[CopyTpPricesUpdatedToSubscriptions]
AS
-- копирует данные из таблицы TP_PricesUpdated на все подписчики
--<DATE>2014-02-27</DATE>
--<VERSION>9.2.20</VERSION>
begin

	if dbo.mwReplIsPublisher() > 0 
	begin
		select top 10000 * into #TP_PricesUpdated from dbo.TP_PricesUpdated with(nolock) order by TPU_Key;
	
		delete from dbo.TP_PricesUpdated with(rowlock)
		where exists(select 1 from #TP_PricesUpdated r where r.TPU_Key = TP_PricesUpdated.TPU_Key);
	
		declare @sql varchar (500);
		declare @source varchar(200);
		set @source = '';
		
		if exists(select 1 from #TP_PricesUpdated)
		begin
			declare @subscriptionLinkedServer sysname, @subscriptionDatabaseName sysname

			declare @t table
			(
				[PublisherDBName] sysname,
				[PublisherName] sysname,
				[SubscriberName] sysname,
				[SubscriptionDBName] sysname
			)

			insert into @t
			exec mwGetSubscriptions

			DECLARE subscriptionsCursor CURSOR FOR
			SELECT SubscriberName, SubscriptionDBName
			FROM @t

			BEGIN TRY

				OPEN subscriptionsCursor

				FETCH NEXT FROM subscriptionsCursor INTO @subscriptionLinkedServer, @subscriptionDatabaseName
				
				WHILE @@Fetch_Status = 0
				BEGIN
			
					print @subscriptionLinkedServer
					SET @source = '[' + @subscriptionLinkedServer + '].[' + @subscriptionDatabaseName + ']'
				
					SET @sql = '
					insert into ' + @source + '.dbo.TP_PricesUpdated with(rowlock) ([TPU_Key], [TPU_TPKey], [TPU_IsChangeCostMode], [TPU_TPGrossOld], [TPU_TPGrossDelta], [TPU_DateUpdate]) 
					select [TPU_Key], [TPU_TPKey], [TPU_IsChangeCostMode], [TPU_TPGrossOld], [TPU_TPGrossDelta], [TPU_DateUpdate] 
					from #TP_PricesUpdated src with (nolock)
					where src.TPU_Key not in (select TPU_Key from ' + @source + '.dbo.TP_PricesUpdated with (nolock))
					'

					EXEC (@sql)
			
					FETCH NEXT FROM subscriptionsCursor INTO @subscriptionLinkedServer, @subscriptionDatabaseName
				
				END

			END TRY
			BEGIN CATCH

				DECLARE @errorMessage as nvarchar(max)
				SET @errorMessage = 'Error in TP_PricesUpdated copy to subscribers: ' + ERROR_MESSAGE()

				INSERT INTO SystemLog (sl_date, sl_message)
				VALUES (getdate(), @errorMessage)
				
				RAISERROR (@errorMessage, 18, 100); 

			END CATCH

			CLOSE subscriptionsCursor
			DEALLOCATE subscriptionsCursor
		end
		
		drop table #TP_PricesUpdated;
	end

end

GRANT EXEC ON [dbo].[CopyTpPricesUpdatedToSubscriptions] TO PUBLIC
GO
/*********************************************************************/
/* end sp_CopyTpPricesUpdatedToSubscriptions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-03-20)_AlterTable_tbl_Dogovor.sql */
/*********************************************************************/
--<VERSION>9.2.20.10</VERSION>
--<DATE>2014-03-21</DATE>

if exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[tbl_dogovor]') and name = 'DG_DAKey')
begin
	ALTER TABLE [dbo].[tbl_dogovor] ALTER COLUMN [DG_DAKey] int NULL
end
else
	ALTER TABLE [dbo].[tbl_dogovor] ADD DG_DAKey int NULL
GO

exec [sp_RefreshViewForAll] 'Dogovor'

GO
/*********************************************************************/
/* end (2014-03-20)_AlterTable_tbl_Dogovor.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.02.25)_Create_Table_CheckPluginVersionExclusion.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT TOP 1 1 FROM SYS.TABLES WHERE NAME = 'CheckPluginVersionExclusions')
BEGIN
	CREATE TABLE [dbo].[CheckPluginVersionExclusions](
		[CPV_Key] [int] IDENTITY(1,1) NOT NULL,
		[CPV_PluginName] [nvarchar](150) NOT NULL,
	 CONSTRAINT [PK_CheckPluginVersionExclusions] PRIMARY KEY CLUSTERED 
	(
		[CPV_Key] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
	) ON [PRIMARY]
END

GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[CheckPluginVersionExclusions] TO PUBLIC

GO
/*********************************************************************/
/* end (2014.02.25)_Create_Table_CheckPluginVersionExclusion.sql */
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

--<DATE>2014-03-18</DATE>
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
declare @PricesCount int

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
	select 
		TF_ID, null as TF_CodeNew, null as TF_SubCode1New, null as TF_PRKeyNew, TF_CalculatingKey, 
		TF_CodeOld, TF_Subcode2, TF_PRKeyOld, TF_CTKey, TF_Subcode1, TF_PKKey, TF_Date, TF_TourDate, TF_Days
	into #TP_Flights
	from TP_Flights with(nolock)
	where TF_TOKey = @nPriceTourKey

	create index X_TP_Flights ON #TP_Flights (TF_ID)
	include (TF_CodeNew, TF_PRKeyNew, TF_SubCode1New, TF_CalculatingKey)
	
	Update	#TP_Flights Set TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1, TF_CalculatingKey = @nCalculatingKey
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey 
			and TF_Date BETWEEN ISNULL(CS_Date, ''1900-01-01'') AND ISNULL(CS_DateEnd, ''2053-01-01'') 
			and TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(CS_CHECKINDATEEND, ''2053-01-01'')
			and (ISNULL(CS_Week, '''') = '''' or CS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'') 
			and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long) 
			and (cs_DateSellBeg <= @dtSaleDate or cs_DateSellBeg is null) 
			and (cs_DateSellEnd >= @dtSaleDate or cs_DateSellEnd is null))

	If @nNoFlight = 2
	BEGIN
		------ проверяем, а есть ли у данного парнера по рейсу, цены на другие рейсы в этом же пакете  ----
		IF exists(SELECT TOP 1 1 FROM #TP_Flights WHERE TF_CodeNew is Null)
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
			FROM AirSeason with(nolock), Charter with(nolock), Costs with(nolock), #TP_Flights
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
			TF_CodeNew is Null 
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
			update TF
			set TF_CodeNew = xCHKey,
			TF_SubCode1New = xASKey,
			TF_PRKeyNew = xPRKeyNew,
			TF_CalculatingKey = @nCalculatingKey
			from #TP_Flights TF join @newFlightsPartnerTable on TF_Id = xTFId
			
			print ''Закончили подбор перелетов''
		end
	END
	
	update TF set 
		TF.TF_CodeNew = TF_Temp.TF_CodeNew, 
		TF.TF_PRKeyNew = TF_Temp.TF_PRKeyNew, 
		TF.TF_SubCode1New = TF_Temp.TF_SubCode1New, 
		TF.TF_CalculatingKey = TF_Temp.TF_CalculatingKey
	from TP_Flights TF with (rowlock)
	inner join #TP_Flights TF_Temp on TF.TF_ID = TF_Temp.TF_ID
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
			[xTP_Key] [int] NULL ,
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

		insert into #TP_Prices (xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey, xTP_CalculatingKey) 
		select tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey
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
								update #TP_Prices set xtp_gross = @price_brutto, xtp_calculatingkey = @nCalculatingKey where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
							else
								update #TP_Prices set xtp_gross = @price_brutto where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
						end
						else if (@isPriceListPluginRecalculation = 0)
						begin
							insert into #TP_Prices (xtp_tokey, xtp_datebegin, xtp_dateend, xtp_gross, xtp_tikey, xTP_CalculatingKey) 
							values (@nPriceTourKey, @dtPrevDate, @dtPrevDate, @price_brutto, @nPrevVariant, @nCalculatingKey)
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
			
		select @PricesCount = count(1) from #TP_Prices
		exec GetNKeys ''TP_PRICES'', @PricesCount, @nTP_PriceKeyMax output
		set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @PricesCount + 1
		
		update #tp_prices 
		set xTP_Key = @nTP_PriceKeyCurrent, @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
		
			
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
	, @PricesCount int
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
	, @PricesCount
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
					if exists(select 1 from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_tikey = @nPrevVariant)
					begin
						--select @nCalculatingKey
						update #TP_Prices set xtp_calculatingkey = @nCalculatingKey where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_tikey = @nPrevVariant and xtp_gross <> @price_brutto
						
					end
					else if (@isPriceListPluginRecalculation = 0)
					begin
						--select @nCalculatingKey
						insert into #TP_Prices (xtp_tokey, xtp_datebegin, xtp_tikey, xTP_CalculatingKey, xTP_Days, xTP_Rate, xTP_HotelKey, xTP_DepartureKey
						, xSCPId_1, xSCPId_2, xSCPId_3, xSCPId_4, xSCPId_5, xSCPId_6, xSCPId_7, xSCPId_8, xSCPId_9, xSCPId_10, xSCPId_11, xSCPId_12, xSCPId_13, xSCPId_14, xSCPId_15
						, xSvKey_1, xSvKey_2, xSvKey_3, xSvKey_4, xSvKey_5, xSvKey_6, xSvKey_7, xSvKey_8, xSvKey_9, xSvKey_10, xSvKey_11, xSvKey_12, xSvKey_13, xSvKey_14, xSvKey_15
						, xGross_1, xGross_2, xGross_3, xGross_4, xGross_5, xGross_6, xGross_7, xGross_8, xGross_9, xGross_10, xGross_11, xGross_12, xGross_13, xGross_14, xGross_15
						, xAddCostIsCommission_1, xAddCostIsCommission_2, xAddCostIsCommission_3, xAddCostIsCommission_4, xAddCostIsCommission_5, xAddCostIsCommission_6, xAddCostIsCommission_7, xAddCostIsCommission_8, xAddCostIsCommission_9, xAddCostIsCommission_10, xAddCostIsCommission_11, xAddCostIsCommission_12, xAddCostIsCommission_13, xAddCostIsCommission_14, xAddCostIsCommission_15
						, xAddCostNoCommission_1, xAddCostNoCommission_2, xAddCostNoCommission_3, xAddCostNoCommission_4, xAddCostNoCommission_5, xAddCostNoCommission_6, xAddCostNoCommission_7, xAddCostNoCommission_8, xAddCostNoCommission_9, xAddCostNoCommission_10, xAddCostNoCommission_11, xAddCostNoCommission_12, xAddCostNoCommission_13, xAddCostNoCommission_14, xAddCostNoCommission_15
						, xMarginPercent_1, xMarginPercent_2, xMarginPercent_3, xMarginPercent_4, xMarginPercent_5, xMarginPercent_6, xMarginPercent_7, xMarginPercent_8, xMarginPercent_9, xMarginPercent_10, xMarginPercent_11, xMarginPercent_12, xMarginPercent_13, xMarginPercent_14, xMarginPercent_15
						, xCommissionOnly_1, xCommissionOnly_2, xCommissionOnly_3, xCommissionOnly_4, xCommissionOnly_5, xCommissionOnly_6, xCommissionOnly_7, xCommissionOnly_8, xCommissionOnly_9, xCommissionOnly_10, xCommissionOnly_11, xCommissionOnly_12, xCommissionOnly_13, xCommissionOnly_14, xCommissionOnly_15
						, xIsCommission_1, xIsCommission_2, xIsCommission_3, xIsCommission_4, xIsCommission_5, xIsCommission_6, xIsCommission_7, xIsCommission_8, xIsCommission_9, xIsCommission_10, xIsCommission_11, xIsCommission_12, xIsCommission_13, xIsCommission_14, xIsCommission_15)
						values (@nPriceTourKey, @dtPrevDate, @nPrevVariant, @nCalculatingKey, @tiDays, @sRate, @hdKey, @tiCtKeyFrom
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
		set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @PricesCount + 1
		
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
				if exists(select top 1 1 from #tmp_tpPricesUpdated where TPU_IsChangeCostMode = 1)
				begin
					update mwPriceDataTable
					set pt_price = TPU_TPGrossOld + TPU_TPGrossDelta
					from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
					where TPU_IsChangeCostMode = 1
				end

				if exists(select top 1 1 from #tmp_tpPricesUpdated where TPU_IsChangeCostMode = 0)
				begin
					delete mwPriceDataTable
					from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
					where TPU_IsChangeCostMode = 0
				end
			end
			else
			begin
				declare @IsExistsUpdate bit
				set @IsExistsUpdate = 0

				declare @IsExistsDelete bit
				set @IsExistsDelete = 0
				
				select top 1 @IsExistsUpdate = 1 from #tmp_tpPricesUpdated where TPU_IsChangeCostMode = 1
				select top 1 @IsExistsDelete = 1 from #tmp_tpPricesUpdated where TPU_IsChangeCostMode = 0			
			
				declare @sql nvarchar(4000), @tableName nvarchar(100)
				declare cur cursor fast_forward read_only for
				select name
				from sysobjects
				where xtype = 'U' and name like 'mwPriceDataTable[_]%'

				open cur
				fetch next from cur into @tableName
				while (@@FETCH_STATUS = 0)
				begin
					set @sql = ''
					if (@IsExistsUpdate = 1)
						set @sql = 'update ' + @tableName + '
									set pt_price = TPU_TPGrossOld + TPU_TPGrossDelta
									from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
									where TPU_IsChangeCostMode = 1 
									'
					
					if (@IsExistsDelete = 1)
						set @sql = @sql + 
									'delete ' + @tableName + '
									from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
									where TPU_IsChangeCostMode = 0'

					if (@sql <> '')
					begin
						set @sql = 'if exists(select top 1 1 from ' + @tableName + ' with(nolock) join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey)
									begin
									' + @sql + '
									end'
						exec (@sql)
					end
					
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
/* begin sp_DogListToQuotas.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogListToQuotas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogListToQuotas]
GO

CREATE PROCEDURE [dbo].[DogListToQuotas]
(
	--<VERSION>9.20.10</VERSION>
	--<DATA>20.03.2014</DATA>
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
		if @SetQuotaByRoom = 0 and @SVKey = 3
		begin
			exec SetStatusInRoom @dlkey
		end
		-- запускаем хранимку на установку статуса путевки
		--exec SetReservationStatus @DgKey

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
EXEC dbo.SetServiceStatusOk @DlKey,@dlControl
GO

GRANT EXEC ON [dbo].[DogListToQuotas] TO PUBLIC
GO

/*********************************************************************/
/* end sp_DogListToQuotas.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwRemoveDeleted.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwRemoveDeleted]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwRemoveDeleted]
GO

create proc [dbo].[mwRemoveDeleted] 
	@remove tinyint = 0
as
begin
	--<VERSION>9.2.20.10</VERSION>
	--<DATE>2014-03-12</DATE>

	set nocount on
	if (dbo.mwReplIsPublisher() = 1)
	begin
		delete from dbo.mwDeleted
		return
	end
	
	declare @name varchar(50)
	declare @sql varchar(8000)
		
	if object_id('tempdb..#tmpDeleted') is not null
	begin
		drop table #tmpDeleted
	end
	create table #tmpDeleted(
		del_key int
	)
	declare @pubdb nvarchar(50)
	set @pubdb = dbo.mwReplPublisherDB()
	
	declare delCur cursor fast_forward read_only 
			for select [name] from sysobjects with(nolock) where name like 'mwPriceDataTable[_]%' and xtype = 'u'			
	
	while exists(select top (1) 1 from dbo.mwDeleted with (nolock))
	begin

		insert into #tmpDeleted
		select top (100000) del_key 
		from dbo.mwDeleted with(nolock)				

		open delCur
		fetch next from delCur into @name	
		while(@@fetch_status = 0)
		begin
			while 1=1
			begin
				set @sql = 'delete top (10000) from dbo.' + ltrim(rtrim(@name)) + ' where pt_pricekey in (select del_key from #tmpDeleted)'
				exec(@sql)
				if @@rowcount = 0
					break
			end

			fetch next from delCur into @name
		end
		close delCur

		delete from dbo.mwDeleted where del_key in (select del_key from #tmpDeleted)

		delete from #tmpDeleted	
	end

	deallocate delCur

	declare @source as nvarchar(50)
	set @source = ''

	if dbo.mwReplIsSubscriber() > 0
	begin
		set @source = 'mt.' + @pubdb + '.'
	end

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

GRANT EXECUTE on [dbo].[mwRemoveDeleted] to public
GO
/*********************************************************************/
/* end sp_mwRemoveDeleted.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplDisableDeletedPrices.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReplDisableDeletedPrices]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwReplDisableDeletedPrices]
GO

CREATE procedure [dbo].[mwReplDisableDeletedPrices]
as
begin

	--<DATE>2014-03-12</DATE>
	--<VERSION>9.2.21.0</VERSION>

	declare @cnKey int
	declare @ctKeyFrom int
	declare @sql varchar (500)
	declare @wasError as bit
	declare @errorText as nvarchar(max)

	set @wasError = 0

	select top 100000 * into #mwReplDeletedPricesTemp from dbo.mwReplDeletedPricesTemp with(nolock) order by rdp_cnkey, rdp_ctdeparturekey;
	create index x_pricekey on #mwReplDeletedPricesTemp(rdp_pricekey);

	begin try

	if (dbo.mwReplIsSubscriber() > 0 or (dbo.mwReplIsPublisher() <= 0 and dbo.mwReplIsSubscriber() <= 0))
		and (exists(select top 1 1 from #mwReplDeletedPricesTemp))
	begin
		insert into dbo.mwDeleted (del_key)
		select rdp_pricekey from #mwReplDeletedPricesTemp;

		if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
		begin
			declare @wasErrorInCycle as bit
			set @wasErrorInCycle = 0

			create table #delKeys (xKey int)

			begin try
				--Используется секционирование ценовых таблиц
				declare mwPriceDataTableNameCursor cursor local fast_forward for
				select distinct dbo.mwGetPriceTableName(rdp_cnkey, rdp_ctdeparturekey) as ptn_tablename, rdp_cnkey, rdp_ctdeparturekey
					from #mwReplDeletedPricesTemp with(nolock);

				declare @mwPriceDataTableName varchar(200);
				open mwPriceDataTableNameCursor;
				fetch next from mwPriceDataTableNameCursor into @mwPriceDataTableName, @cnKey, @ctKeyFrom;

				while @@FETCH_STATUS = 0
				begin
					if exists (select * from sys.tables where @mwPriceDataTableName like '%' + name)
					begin
						set @sql='
							update ' + @mwPriceDataTableName + ' 
							set pt_isenabled = 0
							where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey)';
						print (@sql)
						exec (@sql)

						truncate table #delKeys
						
						set @sql = 'insert into #delKeys (xKey) 
							select sd_key
							from mwSpoDataTable
							where sd_isenabled = 1
							and sd_cnkey = ' + ltrim(str(@cnKey)) + ' and sd_ctkeyfrom = ' + ltrim(str(@ctKeyFrom)) + '
							and not exists (select 1 from [dbo].[' + @mwPriceDataTableName + '] with(nolock) where pt_isenabled = 1 and pt_tourkey = sd_tourkey and sd_hdkey = pt_hdkey)'
						print (@sql)
						exec (@sql)

						set @sql = 'update mwSpoDataTable set sd_isenabled = 0 where sd_key in (select xKey from #delKeys)'
						exec (@sql)
						
						
					end

					fetch next from mwPriceDataTableNameCursor into @mwPriceDataTableName, @cnKey, @ctKeyFrom;
				end
			end try
			begin catch
				set @wasErrorInCycle = 1
				set @errorText = ERROR_MESSAGE()
			end catch

			-- release resources
			close mwPriceDataTableNameCursor
			deallocate mwPriceDataTableNameCursor

				if @wasErrorInCycle = 1
			begin
				-- rethrow error after resources release
				raiserror(@errorText, 16, 1)
			end
		end
		else
		begin
			--Секционирование не используется
			update dbo.mwPriceDataTable 
			set pt_isenabled = 0
			where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey);
		end
	end

	end try
	begin catch
		set @wasError = 1
		set @errorText = ERROR_MESSAGE()
	end catch

	if @wasError = 0
	begin
		-- delete from source table only if processing was successful
		delete from mwReplDeletedPricesTemp
		where exists(select top 1 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = mwReplDeletedPricesTemp.rdp_pricekey)
	end

	-- release resources
	drop index x_pricekey on #mwReplDeletedPricesTemp;
	drop table #mwReplDeletedPricesTemp;

	if @wasError = 1
	begin
		-- rethrow error after resources release
		raiserror(@errorText, 16, 1)
	end
end
GO

GRANT EXECUTE on [dbo].[mwReplDisableDeletedPrices] to public
GO
/*********************************************************************/
/* end sp_mwReplDisableDeletedPrices.sql */
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
					(isnull(sd_cnname, '-1') <> isnull(cn_name, '') or DATALENGTH(sd_cnname) <> DATALENGTH(cn_name))
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
						DATALENGTH(sd_hdstars) <> DATALENGTH(hd_stars) or 
						isnull(sd_ctkey, -1) <> isnull(hd_ctkey, 0) or 
						isnull(sd_rskey, -1) <> isnull(hd_rskey, 0) or 
						isnull(sd_hdname, '-1') <> isnull(hd_name, '') or 
						DATALENGTH(sd_hdname) <> DATALENGTH(hd_name) or 
						isnull(sd_hotelurl, '-1') <> isnull(hd_http, '') or
						DATALENGTH(sd_hotelurl) <> DATALENGTH(hd_http)
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
						DATALENGTH(sd_hdstars) <> DATALENGTH(hd_stars) or 
						isnull(sd_ctkey, -1) <> isnull(hd_ctkey, 0) or 
						isnull(sd_rskey, -1) <> isnull(hd_rskey, 0) or 
						isnull(sd_hdname, '-1') <> isnull(hd_name, '') or 
						DATALENGTH(sd_hdname) <> DATALENGTH(hd_name) or 
						isnull(sd_hotelurl, '-1') <> isnull(hd_http, '') or
						DATALENGTH(sd_hotelurl) <> DATALENGTH(hd_http)
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
										DATALENGTH(pt_hdstars) <> DATALENGTH(hd_stars) or 
										isnull(pt_ctkey, -1) <> isnull(hd_ctkey, 0) or 
										isnull(pt_rskey, -1) <> isnull(hd_rskey, 0) or 
										isnull(pt_hdname, ''-1'') <> isnull(hd_name, '''') or 
										DATALENGTH(pt_hdname) <> DATALENGTH(hd_name) or 
										isnull(pt_hotelurl, ''-1'') <> isnull(hd_http, '''') or
										DATALENGTH(pt_hotelurl) <> DATALENGTH(hd_http)
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
											DATALENGTH(pt_hdstars) <> DATALENGTH(hd_stars) or 
											isnull(pt_ctkey, -1) <> isnull(hd_ctkey, 0) or 
											isnull(pt_rskey, -1) <> isnull(hd_rskey, 0) or 
											isnull(pt_hdname, ''-1'') <> isnull(hd_name, '''') or 
											DATALENGTH(pt_hdname) <> DATALENGTH(hd_name) or 
											isnull(pt_hotelurl, ''-1'') <> isnull(hd_http, '''') or
											DATALENGTH(pt_hotelurl) <> DATALENGTH(hd_http)
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
										isnull(pt_toururl, '''') <> isnull(tl_webhttp, '''') or
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
										isnull(pt_toururl, '''') <> isnull(tl_webhttp, '''') or
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
											isnull(pt_tourvalid, ''1900-01-02'') <> isnull(to_datevalid, ''1900-01-01'') or 
											isnull(pt_rate, ''-1'') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '''') COLLATE DATABASE_DEFAULT
										)
									)
								)
								begin
									update top (@pdtUpdatePackageSize) @tableName
									set
										pt_tourvalid = isnull(to_datevalid, ''1900-01-01''),
										pt_rate = isnull(to_rate, '''')
									from
										dbo.tp_tours
									where
										pt_tourkey = to_key 
										and to_updatetime > ''@dateUpdate''
										and (
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
/* begin sp_ReCalculateCosts_CalculatePriceList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculateCosts_CalculatePriceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculateCosts_CalculatePriceList]
GO
CREATE PROCEDURE [dbo].[ReCalculateCosts_CalculatePriceList]
	(
		@scpId int,
		@brutto money output,
		@IsCommission bit output,
		
		@svKey int,
		@code int,
		@code1 int,
		@code2 int,
		@prKey int,
		@packetKey int,
		@date datetime,
		@days int,
		@resRate varchar(2),
		@men int,
		@discountPercent decimal(14,6),
		@margin decimal(14,6),
		@marginType int,
		@sellDate dateTime, 
		@netto decimal(14,6),		
		@discount decimal(14,6),
		@nettoDetail varchar(100),
		@sBadRate varchar(2),
		@dtBadDate dateTime,
		@sDetailed varchar(100),
		@nSPId int,
		@tourKey int,
		@tourDate datetime,
		@tourDays int,
		@IsDuration smallint
	)
as

--<data>2013-07-23</data>
--<version>9.20</version>

BEGIN
	declare @useDiscountDays int
	
	-- если наща услуга без продолжительности то устанавливаем ей продолжительность равную продолжительности тура
	if (@svKey = 1)
	begin
		set @days = @tourDays
	end

	/*Нужно вставить логику которая идет перед расчетом услуги в старом CalculatePriceList*/

	set @brutto = null	
	set @sellDate = null
	set @margin = 0
	set @marginType = 0

	/*попробуем найти запись нужной нам цены*/
	-- gorshkov у строк вставленных этой хранимкой (там пониже есть инсерт)
	-- SPAD_DateLastChange = SPAD_DateLastCalculate = getdate()
	-- т.е. здесь нужно использовать <= а не <
	select	top 1 
		@brutto = xSPAD_Gross,
		@IsCommission = xSPAD_IsCommission
	from #ServicePriceActualDate with(nolock)
	where xSPAD_SCPId = @scpId
	and xSPAD_SaleDate is null
	-- или расчитана и перенесена или только расчитана но не перенесена
	and xSPAD_Rate = @resRate
	and xSPAD_NeedApply = 0
	
	if (@brutto is not null)
	begin
		--update Debug  set db_n1 = db_n1 +1 where db_Text = '- #GetServiceCost'
		return
	end
	
	-- не нашли расчитанной цены, нужно расчитать и записать результат в TP_ServicePriceActualDate
	exec GetServiceCost @svKey, @code, @code1, @code2, @prKey, @packetKey, @date, @days,
	@resRate, @men, @discountPercent, @margin, @marginType,
	@sellDate, @netto output, @brutto output, @discount output,
	@nettoDetail output, @sBadRate output, @dtBadDate output,
	@sDetailed output,  @nSPId output, @useDiscountDays output,
	@tourKey, @tourDate, @tourDays, 0
	
	--update Debug  set db_n1 = db_n1 +1 where db_Text = '+ #GetServiceCost'
	
	/*Нужно вствить логику на праверку устаревших данных по полю SPAD_SaleDate
	Если есть строки с SPAD_SaleDate <= getadte() то у ней, она должны быть нужно установить SPAD_SaleDate = null, а старые записи с SPAD_SaleDate = null удалить
	Пока не понятно как это будет работать нужно обсудить*/		
	
	if (@discount is null)
		set @IsCommission = 0
	else
		set @IsCommission = 1
	
	if (not exists (select top 1 1
					from #ServicePriceActualDate with(nolock)
					where xSPAD_SCPId = @scpId
					and xSPAD_SaleDate is null
					and xSPAD_Rate = @resRate))
	begin
		-- gorshkov зафиксировал время, которое будет вставляться в SPAD_DateLastChange и SPAD_DateLastCalculate
		declare @modificationDate datetime;
		set @modificationDate=getdate();
		insert into #ServicePriceActualDate (xSPAD_SCPId, xSPAD_IsCommission, xSPAD_Rate, xSPAD_SaleDate, xSPAD_Gross, xSPAD_Netto, xSPAD_DateLastChange,
												xSPAD_DateLastCalculate, xSPAD_NeedApply)
		values (@scpId, @IsCommission, @resRate, null, @brutto, @netto, @modificationDate, @modificationDate , 0)
	end
	else
	begin
		-- обновим и скажем чтобы обновились цены в других турах
		update #ServicePriceActualDate
		set xSPAD_Gross = @brutto,
		xSPAD_Netto = @netto,
		xSPAD_IsCommission = @IsCommission,
		xSPAD_DateLastCalculate = getdate(),
		xSPAD_NeedApply = 0
		where xSPAD_SCPId = @scpId
		and xSPAD_SaleDate is null
		and xSPAD_Rate = @resRate
	end
END

GO

grant exec on [dbo].[ReCalculateCosts_CalculatePriceList] to public
go

/*********************************************************************/
/* end sp_ReCalculateCosts_CalculatePriceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_MigrateToPrice.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_MigrateToPrice]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[ReCalculate_MigrateToPrice]
GO

--<VERSION>2009.2.19.1</VERSION>
--<DATE>2014-03-19</DATE>
CREATE PROCEDURE [dbo].[ReCalculate_MigrateToPrice]
	(
		-- хранимка суммирует стоимость отдельных услуг и кладет их в TP_Prices		
		-- максимальное количество записей для переноса за 1 раз
		@countItem INT,  
		
		--ключи цен на перерасчет
		@tpKeys dbo.ListIntValue readonly,
		
		--ключ тура
		--если указан, @tpToursCount не учитывается - обрабатывается только один тур
		@toKey INT = NULL,

		--количество туров
		@tpToursCount INT = NULL --для совместимости с предыдущими версиями
	)
AS
BEGIN
	SET ARITHABORT ON;

	--Таблица для цен из TP_PriceComponents
	CREATE TABLE #tempGrossTable 
	(
		xPCId int,
		xTPKey int,
		xSummPrice money,
		xToKey int,
		xUpdateDate datetime
	)
	
	create index X_TempGrossTable ON #tempGrossTable (xTPKey, xSummPrice, xToKey)
	
	DECLARE  @numRowsInserted int , @numRowsUpdated int, @numRowsDeleted int
	SET @numRowsInserted = 0
	SET @numRowsUpdated = 0
	SET @numRowsDeleted = 0

	-- если указаны ключи цен, обрабатываем их
	IF (EXISTS(SELECT TOP 1 1 FROM @tpKeys))
	BEGIN
		  
		SELECT PC_Id, PC_TPKey, PC_SummPrice, PC_ToKey, PC_UpdateDate
		FROM TP_PriceComponents
		INNER JOIN @tpKeys ON value = PC_TPKey
		WHERE pc_state = 1    
		
		
			--добавлен инсерт для обработки значений в этой же хранимой процедуре при применении ММ
				INSERT INTO #tempGrossTable (xPCId, xTPKey, xSummPrice, xToKey, xUpdateDate)
				SELECT TOP (@countItem) PC_Id, PC_TPKey, PC_SummPrice, PC_ToKey, PC_UpdateDate
				FROM TP_PriceComponents INNER JOIN @tpKeys ON value = PC_TPKey
				WHERE PC_State = 1   
		 
	END  
	ELSE
	BEGIN  

		--Если указан @toKey, обрабатываем только один тур
		IF (@toKey IS NOT NULL)
		BEGIN
    
			INSERT INTO #tempGrossTable (xPCId, xTPKey, xSummPrice, xToKey, xUpdateDate)
			SELECT TOP (@countItem) PC_Id, PC_TPKey, PC_SummPrice, PC_ToKey, PC_UpdateDate
			FROM TP_PriceComponents
			WHERE PC_State = 1 AND PC_TOKey = @toKey

			--добавлен инсерт для обработки значений в этой же хранимой процедуре при применении ММ
				INSERT INTO #tempGrossTable (xPCId, xTPKey, xSummPrice, xToKey, xUpdateDate)
				SELECT TOP (@countItem) PC_Id, PC_TPKey, PC_SummPrice, PC_ToKey, PC_UpdateDate
				FROM TP_PriceComponents INNER JOIN @tpKeys ON value = PC_TPKey
				WHERE PC_State = 1 

		END
     		ELSE
		BEGIN
  
			--Если указано количество туров, берем в обработкe @countItem цен @toursCount туров    
			IF (@tpToursCount IS NOT NULL)
			BEGIN      
    
				DECLARE tourscursor CURSOR FAST_FORWARD READ_ONLY
				FOR SELECT TOP (@tpToursCount) to_key FROM tp_tours (NOLOCK)
				WHERE to_key IN (SELECT PC_TOKey FROM TP_PriceComponents with(nolock) WHERE PC_State = 1)

				OPEN toursCursor
	
				FETCH NEXT FROM toursCursor INTO @toKey

				WHILE @@FETCH_STATUS = 0
				BEGIN

					INSERT INTO #tempGrossTable (xPCId, xTPKey, xSummPrice, xToKey, xUpdateDate)
					SELECT TOP (@countItem) PC_Id, PC_TPKey, PC_SummPrice, PC_ToKey, PC_UpdateDate
					FROM TP_PriceComponents
					WHERE PC_State = 1 AND PC_TOKey = @toKey

					FETCH NEXT FROM toursCursor INTO @toKey

				END

				CLOSE toursCursor
				DEALLOCATE toursCursor

			END
  
			-- Иначе обрабатываем первые @countItem записей из очереди         
			ELSE
			BEGIN    

				INSERT INTO #tempGrossTable (xPCId, xTPKey, xSummPrice, xToKey, xUpdateDate)
				SELECT TOP (@countItem) PC_Id, PC_TPKey, PC_SummPrice, PC_ToKey, PC_UpdateDate
				FROM TP_PriceComponents
				WHERE PC_State = 1

			END

		END
	
	END
    
	DECLARE @tempGrossTableCount INT
	SELECT @tempGrossTableCount=COUNT(1) FROM #tempGrossTable
	print 'Количество строк в TP_PriceComponents: ' + convert(nvarchar(max), @tempGrossTableCount)
	
	DECLARE currReCalculate_MigrateToPrice CURSOR FOR SELECT DISTINCT xToKey FROM #tempGrossTable
	OPEN currReCalculate_MigrateToPrice

	FETCH NEXT FROM currReCalculate_MigrateToPrice INTO @toKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
			
		INSERT INTO CalculatingPriceLists (CP_CreateDate,CP_PriceTourKey) VALUES (GETDATE(),@toKey) 
		DECLARE	@cpKey int
		SET @cpKey = SCOPE_IDENTITY()
			
		-- переносим цены в таблицу для удаленных цен
		INSERT INTO tp_pricesdeleted (TPD_TPKey, TPD_TOKey, TPD_TIKey, TPD_Gross, TPD_DateBegin, TPD_DateEnd, TPD_CalculatingKey)
		SELECT TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, @cpKey 
		FROM tp_prices (NOLOCK)
		WHERE tp_key IN (SELECT xTPKey FROM #tempgrosstable WHERE xSummPrice IS NULL AND xToKey = @toKey)
								
		-- удаляем цены из tp_prices
		DELETE FROM tp_prices
		WHERE tp_key IN (SELECT xTPKey FROM #tempgrosstable WHERE xSummPrice IS NULL AND xToKey = @toKey)
		SET @numRowsDeleted = @@ROWCOUNT
			
		--восстанавливаем цены из таблицы удаленных цен
		INSERT INTO tp_prices (TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, TP_CalculatingKey)
		SELECT TPD_TPKey, TPD_TOKey, TPD_TIKey, TPD_Gross, TPD_DateBegin, TPD_DateEnd, @cpKey
		FROM tp_pricesdeleted (NOLOCK)
		WHERE tpd_tpkey IN (SELECT xTPKey FROM #tempgrosstable WHERE xSummPrice IS NOT NULL AND xToKey = @toKey)
		SET @numRowsInserted = @@ROWCOUNT
								
		-- и удаляем из из таблицы удаленных цен
		DELETE FROM tp_pricesdeleted
		WHERE tpd_tpkey IN (SELECT xTPKey FROM #tempgrosstable WHERE xSummPrice IS NOT NULL AND xToKey = @toKey)
								
		-- обновляем цены, которые ранее не были удалены и изменились, или ранее были удалены но сейчас востановились
		UPDATE TP_Prices
		SET TP_Gross = CEILING(xSummPrice),
		tp_updatedate = GetDate(),
		TP_CalculatingKey = @cpKey
		FROM TP_Prices join #tempGrossTable on TP_Key = xTPKey
		WHERE xSummPrice is not null
		AND xToKey = @toKey
			
		SET @numRowsUpdated = @@ROWCOUNT
			
		IF EXISTS (SELECT TOP 1 1 FROM TP_Tours WHERE to_Key = @toKey AND to_isEnabled = 1)
		BEGIN
			-- Реплицируем только если тур уже выставлен в online
			IF (@numRowsInserted > 0 or @numRowsDeleted > 0)
			BEGIN
				EXEC FillMasterWebSearchFields @toKey, @cpKey
			END
			ELSE IF (@numRowsUpdated > 0)
			BEGIN
				-- нужно для корректной обработки необходимости обновления кэша в TourML
				UPDATE TP_Tours SET TO_UPDATETIME = GETDATE() WHERE TO_Key = @toKey

				IF dbo.mwReplIsPublisher() > 0
				BEGIN
					INSERT INTO mwReplTours(rt_trkey, rt_tokey, rt_date, rt_calckey, rt_updateOnlinePrices)
					SELECT TO_TRKey, TO_Key, GETDATE(), @cpKey, 2
					FROM tp_tours
					WHERE TO_Key = @toKey
				END
				ELSE
				BEGIN
					EXEC mwReplUpdatePriceEnabledAndValue @toKey, @cpKey
				END
			END
		END
		
		-- отметим что уже перенесли
		UPDATE TP_PriceComponents
		SET PC_DateLastUpdateToPrice = GETDATE(),
		PC_State = 0
		FROM TP_PriceComponents inner join #tempGrossTable ON PC_Id = xPCId
		WHERE PC_TOKey = @toKey AND PC_UpdateDate = xUpdateDate
		
		FETCH NEXT FROM currReCalculate_MigrateToPrice INTO @toKey
	END

	CLOSE currReCalculate_MigrateToPrice
	DEALLOCATE currReCalculate_MigrateToPrice
	
END
GO

GRANT EXECUTE ON [dbo].[ReCalculate_MigrateToPrice]	TO PUBLIC
GO
/*********************************************************************/
/* end sp_ReCalculate_MigrateToPrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReСalculateNationalRatePrice.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReСalculateNationalRatePrice]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReСalculateNationalRatePrice]
GO
CREATE PROCEDURE [dbo].[ReСalculateNationalRatePrice]
(
	@DG_KEY INT,
	@NDG_RATE VARCHAR(3),
	@ODG_RATE VARCHAR(3),
	@ODG_CODE VARCHAR(10),
	@NDG_PRICE FLOAT,
	@ODG_PRICE FLOAT,
	@NDG_DISCOUNTSUM FLOAT,
	@NDG_SOR_CODE INT
)
AS
BEGIN
--<VERSION>9.2.20.10</VERSION>
--<DATE>2014-03-17</DATE>
-- Task 10558 tfs neupokoev 26.12.2012
-- Повторная фиксация курса валюты, в случае если он не зафиксировался
	DECLARE @HI_DATE DATETIME

	SELECT TOP 1 @HI_DATE = HI_DATE
	FROM HISTORY
	WHERE HI_DGKEY = @DG_KEY AND HI_OAID = 21 ORDER BY HI_DATE DESC
	
	IF @HI_DATE IS NOT NULL
		EXEC DBO.NationalCurrencyPrice2 @NDG_RATE, @ODG_RATE, @ODG_CODE, @NDG_PRICE, @ODG_PRICE, @NDG_DISCOUNTSUM, @HI_DATE, @NDG_SOR_CODE
END

GO

GRANT EXEC ON [dbo].[ReСalculateNationalRatePrice] TO PUBLIC
GO
/*********************************************************************/
/* end sp_ReСalculateNationalRatePrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_ServiceByDateChanged.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='TR' and name='T_ServiceByDateChanged')
	-- удал¤ю лишний триггер
	drop trigger dbo.T_ServiceByDateChanged
go

CREATE TRIGGER [dbo].[T_ServiceByDateChanged] ON [dbo].[ServiceByDate]
AFTER INSERT, UPDATE, DELETE
AS
--<DATE>2013-06-17</DATE>
--<VERSION>2009.2.20.0</VERSION>
DECLARE @sMod varchar(3), @nHIID int, @sDGCode varchar(10), @nDGKey int, @sDLName varchar(150), @sTemp varchar(25), @sTemp2 varchar(255), @sTuristName varchar(55)
DECLARE @sOldValue varchar(255), @sNewValue varchar(255), @nOldValue int, @nNewValue int, @SDDate datetime
DECLARE @nRowsCount int, @sServiceStatusToHistory varchar(255)

DECLARE @SDID int, @N_SD_DLKey int, @N_SD_RLID int, @N_SD_TUKEY int, @N_SD_QPID int, @N_SD_State int, @N_SD_Date datetime,
		@O_SD_DLKey int, @O_SD_RLID int, @O_SD_TUKEY int, @O_SD_QPID int, @O_SD_State int, @O_SD_Date datetime, @QT_ByRoom bit,
		@nDelCount int, @nInsCount int, @DLDateBeg datetime, @DLNDays int, @QState int, @NewQState int, @QD_ID int

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED
IF (@nInsCount = 0)
BEGIN
    DECLARE cur_ServiceByDateChanged CURSOR local FAST_FORWARD FOR 
    SELECT 	O.SD_ID,
			O.SD_DLKey, O.SD_RLID, O.SD_TUKey, O.SD_QPID, O.SD_State, O.SD_Date,
			null, null, null, null, null, null
    FROM DELETED O
END
ELSE IF (@nDelCount = 0)
BEGIN
    DECLARE cur_ServiceByDateChanged CURSOR local FAST_FORWARD FOR 
    SELECT 	N.SD_ID,
			null, null, null, null, null, null,
			N.SD_DLKey, N.SD_RLID, N.SD_TUKey, N.SD_QPID, N.SD_State, N.SD_Date
			--DL_DateBeg, DL_NDays
    FROM	INSERTED N
	--LEFT OUTER JOIN tbl_DogovorList ON N.SD_DLKey = DL_Key
	-- CRM01871H3T9 30.05.2012 kolbeshkin: отсеиваем неквотируемые услуги, дл¤ них триггер не должен отрабатывать
	where exists (select 1 from DogovorList,[Service] where DL_KEY=N.SD_DLKey and DL_SVKEY=SV_KEY 
    and ISNULL(SV_QUOTED,0)<>0)
END
ELSE 
BEGIN
    DECLARE cur_ServiceByDateChanged CURSOR local FAST_FORWARD FOR 
    SELECT 	N.SD_ID,
			O.SD_DLKey, O.SD_RLID, O.SD_TUKey, O.SD_QPID, O.SD_State, O.SD_Date,
	  		N.SD_DLKey, N.SD_RLID, N.SD_TUKey, N.SD_QPID, N.SD_State, N.SD_Date
			--DL_DateBeg, DL_NDays
    FROM DELETED O, INSERTED N
	--LEFT OUTER JOIN tbl_DogovorList ON N.SD_DLKey = DL_Key 
    WHERE N.SD_ID = O.SD_ID
	-- CRM01871H3T9 30.05.2012 kolbeshkin: отсеиваем неквотируемые услуги, дл¤ них триггер не должен отрабатывать
	and exists (select 1 from DogovorList,[Service] where DL_KEY=N.SD_DLKey and DL_SVKEY=SV_KEY 
    and ISNULL(SV_QUOTED,0)<>0)
END

select @sServiceStatusToHistory = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSServiceStatusToHistory'

declare @RLIDCount int

OPEN cur_ServiceByDateChanged
FETCH NEXT FROM cur_ServiceByDateChanged 
	INTO @SDID, @O_SD_DLKey, @O_SD_RLID, @O_SD_TUKEY, @O_SD_QPID, @O_SD_State, @O_SD_Date,
				@N_SD_DLKey, @N_SD_RLID, @N_SD_TUKEY, @N_SD_QPID, @N_SD_State, @N_SD_Date
				--@DLDateBeg, @DLNDays
WHILE @@FETCH_STATUS = 0
BEGIN
	IF ISNULL(@O_SD_QPID,0)!=ISNULL(@N_SD_QPID,0) OR ISNULL(@O_SD_RLID,0)!=ISNULL(@N_SD_RLID,0)
	BEGIN
		If @O_SD_QPID is not null
		BEGIN			
			SELECT @QT_ByRoom=QT_ByRoom FROM Quotas inner join QuotaDetails on QD_QTID=QT_ID inner join QuotaParts on QD_ID=QP_QDID where QP_ID=@O_SD_QPID
			IF @QT_ByRoom = 1
			BEGIN
				set @RLIDCount = (SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate WHERE SD_QPID=@O_SD_QPID)
				UPDATE QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=@RLIDCount WHERE QP_ID=@O_SD_QPID
				
				select @QD_ID = QP_QDID from QuotaParts where QP_ID = @O_SD_QPID
				set @RLIDCount = (SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate inner join QuotaParts on SD_QPID=QP_ID inner join QuotaDetails on QP_QDID=QD_ID where QP_QDID=@QD_ID)				
				UPDATE QuotaDetails SET QD_Busy=@RLIDCount WHERE QD_ID = @QD_ID
				
				set @RLIDCount = (SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate inner join tbl_DogovorList on SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key inner join [Service] on DL_SVKey = SV_KEY
					WHERE SD_QPID=@O_SD_QPID AND isnull(SV_IsDuration, 0) = 1)
				UPDATE QuotaParts SET QP_CheckInPlacesBusy=@RLIDCount WHERE QP_ID=@O_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				set @RLIDCount = (SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID=@O_SD_QPID)
				UPDATE QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=@RLIDCount WHERE QP_ID=@O_SD_QPID
				
				select @QD_ID = QP_QDID from QuotaParts where QP_ID = @O_SD_QPID
				set @RLIDCount = (SELECT COUNT(*) FROM ServiceByDate inner join QuotaParts on SD_QPID=QP_ID inner join QuotaDetails on QP_QDID=QD_ID where QP_QDID=@QD_ID)				
				UPDATE QuotaDetails SET QD_Busy=(@RLIDCount) WHERE QD_ID = @QD_ID
				
				set @RLIDCount = (SELECT COUNT(*) FROM ServiceByDate inner join tbl_DogovorList on SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key inner join [Service] on DL_SVKey = SV_KEY
					WHERE SD_QPID=@O_SD_QPID and isnull(SV_IsDuration, 0) = 1)
				UPDATE QuotaParts SET QP_CheckInPlacesBusy=@RLIDCount WHERE QP_ID=@O_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
		END
		
		If @N_SD_QPID is not null
		BEGIN
			SELECT @QT_ByRoom=QT_ByRoom FROM Quotas,QuotaDetails,QuotaParts WHERE QD_QTID=QT_ID and QD_ID=QP_QDID and QP_ID=@N_SD_QPID
			IF @QT_ByRoom = 1
			BEGIN
				set @RLIDCount=(SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate WHERE SD_QPID=@N_SD_QPID)
				UPDATE QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=@RLIDCount WHERE QP_ID=@N_SD_QPID
				
				select @QD_ID = QP_QDID from QuotaParts where QP_ID = @N_SD_QPID
				set @RLIDCount= (SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate inner join QuotaParts on SD_QPID=QP_ID inner join QuotaDetails on QP_QDID=QD_ID where QP_QDID=@QD_ID)
				UPDATE QuotaDetails SET QD_Busy=@RLIDCount WHERE QD_ID = @QD_ID
				
				set @RLIDCount = (SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate inner join tbl_DogovorList on SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key inner join [Service] on DL_SVKey = SV_KEY
					WHERE SD_QPID=@N_SD_QPID AND isnull(SV_IsDuration, 0) = 1)
				UPDATE QuotaParts SET QP_CheckInPlacesBusy=@RLIDCount WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				set @RLIDCount=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID=@N_SD_QPID)
				UPDATE QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=@RLIDCount WHERE QP_ID=@N_SD_QPID
				
				select @QD_ID = QP_QDID from QuotaParts where QP_ID = @N_SD_QPID
				set @RLIDCount = (SELECT COUNT(*) FROM ServiceByDate inner join QuotaParts on SD_QPID=QP_ID inner join QuotaDetails on QP_QDID=QD_ID where QP_QDID=@QD_ID)				
				UPDATE QuotaDetails SET QD_Busy=@RLIDCount WHERE QD_ID = @QD_ID
				
				set @RLIDCount=(SELECT COUNT(*) FROM ServiceByDate inner join tbl_DogovorList on SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key inner join [Service] on DL_SVKey = SV_KEY
					WHERE SD_QPID=@N_SD_QPID and isnull(SV_IsDuration, 0) = 1)
				UPDATE QuotaParts SET QP_CheckInPlacesBusy=@RLIDCount WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
		END
	END
	
	IF (ISNULL(@O_SD_STATE, 0) != ISNULL(@N_SD_STATE, 0) or 
		ISNULL(@O_SD_TUKEY,0)!=ISNULL(@N_SD_TUKEY,0)) and ISNULL(@sServiceStatusToHistory, '0') != '0'
	BEGIN
		Select @QState = QS_STATE from QuotedState where QS_DLID = @N_SD_DLKey and ISNULL(QS_TUID,0) = ISNULL(@N_SD_TUKEY,0)
		IF @QState is NULL and @N_SD_DLKey is not NULL
		BEGIN
			Set @QState = 4
			Insert into QuotedState (QS_DLID, QS_TUID, QS_STATE) values (@N_SD_DLKey, @N_SD_TUKEY, @QState)
		END

		Select @NewQState = MAX(SD_STATE) from ServiceByDate where SD_DLKey = @N_SD_DLKey and ISNULL(SD_TUKEY,0) = ISNULL(@N_SD_TUKEY,0)
		
		if @NewQState is null
		 	set @NewQState = 4
		IF @QState <> @NewQState
			IF @N_SD_DLKey is not NULL
				Update QuotedState set QS_STATE = @NewQState where QS_DLID=@N_SD_DLKey and ISNULL(QS_TUID,0)=ISNULL(@N_SD_TUKEY,0)
			ELSE
				IF @O_SD_DLKey is not NULL
					Update QuotedState set QS_STATE = @NewQState where QS_DLID=@O_SD_DLKey and ISNULL(QS_TUID,0)=ISNULL(@N_SD_TUKEY,0)
	END
	FETCH NEXT FROM cur_ServiceByDateChanged 
		INTO @SDID, @O_SD_DLKey, @O_SD_RLID, @O_SD_TUKEY, @O_SD_QPID, @O_SD_State, @O_SD_Date,
					@N_SD_DLKey, @N_SD_RLID, @N_SD_TUKEY, @N_SD_QPID, @N_SD_State, @N_SD_Date
					--@DLDateBeg, @DLNDays
END
IF @O_SD_DLKey is not null and @N_SD_DLKey is null
	IF exists (SELECT 1 FROM RoomNumberLists WHERE RL_ID not in (SELECT SD_RLID FROM ServiceByDate))
		DELETE FROM RoomNumberLists WHERE RL_ID not in (SELECT SD_RLID FROM ServiceByDate)

CLOSE cur_ServiceByDateChanged
DEALLOCATE cur_ServiceByDateChanged
GO
/*********************************************************************/
/* end T_ServiceByDateChanged.sql */
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
-- =====================   Обновление версии БД. 9.2.20.10 - номер версии, 2014-03-24 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.10', st_moduledate = convert(datetime, '2014-03-24', 120),  st_financeversion = '9.2.20.10', st_financedate = convert(datetime, '2014-03-24', 120)
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
	SET SS_ParmValue='2014-03-24' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO