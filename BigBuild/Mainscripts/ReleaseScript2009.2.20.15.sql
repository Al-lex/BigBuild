/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 16.06.2014 18:28 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.14'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.15'

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
/* begin sp_mwCacheQuotaSearch.sql */
/*********************************************************************/
if object_id('dbo.mwCacheQuotaSearch', 'p') is not null
	drop proc dbo.mwCacheQuotaSearch
go

CREATE procedure [dbo].[mwCacheQuotaSearch]
	@svkey	int,
	@code	int,
	@subcode1	int,
	@subcode2	int,
	@date	datetime,
	@day	int,
	@days	int,
	@prkey	int,
	@pkkey	int,
	@result varchar(256) output,
	@places int output,
	@step_index smallint output,
	@price_correction int output,
	@additional varchar(2000) output,
	@findFlight smallint
as
begin
	--<VERSION>9.2.21.1</VERSION>
	--<DATE>2014-04-23</DATE>
	set @result = NULL
	
	select TOP 1 @result = cq_res, @places = cq_places,
			@step_index = cq_stepindex, @price_correction = cq_pricecorrection,
			@additional = cq_Additional
	FROM	CacheQuotas  with (nolock)
	WHERE	cq_svkey = @svkey and cq_code = @code
			and ((@subcode1 = 0) OR (@subcode1 = cq_rmkey))
			and ((@subcode2 = 0) OR (@subcode2 = cq_rckey))
			and cq_date = @date
			and cq_day = @day
			and cq_days = @days
			and ((@prkey = 0) OR (cq_prkey = @prkey))
			and ((cq_pkkey = 0) OR (cq_pkkey = @pkkey))
			and cq_findFlight = @findFlight
end
GO

grant execute on [dbo].[mwCacheQuotaSearch] to public
GO
/*********************************************************************/
/* end sp_mwCacheQuotaSearch.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.06.03)_Insert_ObjectAliases.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_ID = 310001)
BEGIN
	INSERT INTO ObjectAliases (OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES (310001, '', 'Платежная система QIWI', 63)
END
GO


IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_ID = 310002)
BEGIN
	INSERT INTO ObjectAliases (OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES (310002, '', 'Платежная система Leader', 63)
END
GO


IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_ID = 310003)
BEGIN
	INSERT INTO ObjectAliases (OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES (310003, '', 'Платежная система TourPay', 63)
END
GO


IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_ID = 310004)
BEGIN
	INSERT INTO ObjectAliases (OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES (310004, '', 'Платежная система Paytravel', 63)
END
GO

/*********************************************************************/
/* end (2014.06.03)_Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.06.03)_sp_RecalculatePriceListScheduler.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RecalculatePriceListScheduler]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[RecalculatePriceListScheduler]
GO

CREATE PROCEDURE [dbo].[RecalculatePriceListScheduler]
AS
--<DATE>2014-06-03</DATE>
---<VERSION>9.2.21.14</VERSION>
BEGIN

	declare @cpkey int
	declare @priceTOKey int
	declare @saleDate datetime
	declare @nullCostAsZero smallint
	declare @noFlight smallint
	declare @useHolidayRule smallint
		
	begin tran
		select top 1 @cpkey = CP_Key 
		from CalculatingPriceLists WITH (XLOCK,ROWLOCK) 
		where CP_StartTime is not null and (CP_Update = 0 and CP_Status = 3 and CP_StartTime<=GETDATE()) order by CP_StartTime asc
		UPDATE CalculatingPriceLists Set CP_Status=1 where CP_Key=@cpkey
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
/* end (2014.06.03)_sp_RecalculatePriceListScheduler.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014_06_06)_AlterTable_CountrySettings.sql */
/*********************************************************************/
if not exists(select top 1 1 from sys.columns col
				inner join sys.tables tab on col.object_id=tab.object_id
				where tab.name = 'CountrySettings'
				and col.name = 'CS_Id')
begin
	ALTER TABLE dbo.CountrySettings ADD CS_Id INT NOT NULL IDENTITY (1,1)
end

if not exists (select * from sys.key_constraints k
left join sys.tables tab on k.parent_object_id = tab.object_id
left join sys.columns col on col.object_id = tab.object_id 
where tab.name = 'CountrySettings'
	and col.name = 'CS_Id'
	and k.name = 'PK_CountrySettings'
	and k.[type] = 'PK')
begin
	ALTER TABLE dbo.CountrySettings ADD CONSTRAINT
		PK_CountrySettings PRIMARY KEY CLUSTERED
		(
			CS_Id
		)
end
go
/*********************************************************************/
/* end (2014_06_06)_AlterTable_CountrySettings.sql */
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

/*********************************************************************/
/* begin JOB_ClearCacheQuotas.sql */
/*********************************************************************/
declare @errorMessage nvarchar(max)
declare @serverVersion nvarchar(128)
declare @dbName nvarchar(128)
declare @jobName varchar(255)

-- либо поисковая база в случае реплики, либо единственная и реплики нет
if (dbo.mwReplIsPublisher() = 0)
begin
	select @serverVersion = cast(serverproperty('edition') as nvarchar)
	if (@serverVersion not like '%express%')
	begin
		set @dbName = DB_NAME()

		declare @jobNames table (xName varchar(255))

		insert into @jobNames (xName)
		SELECT name 
		FROM msdb.dbo.sysjobs_view 
		where job_id in (select job_id
						 from msdb.dbo.sysjobsteps 
						 where command like '%ClearQuotaCache%' 
						 and database_name like @dbName)

		if exists (select 1 from @jobNames)
		begin
			declare jobNamesCursor cursor local fast_forward for
			select xName
			from @jobNames

			open jobNamesCursor
			fetch jobNamesCursor into @jobName
			while (@@FETCH_STATUS = 0)
			begin
				EXEC msdb.dbo.sp_delete_job @job_name = @jobName, @delete_unused_schedule=1

				fetch jobNamesCursor into @jobName
			end
			close jobNamesCursor
			deallocate jobNamesCursor
		end

		set @jobName = DB_NAME() + '_ClearCacheQuotas'

		BEGIN TRANSACTION

			DECLARE @ReturnCode INT
			SELECT @ReturnCode = 0

			IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
			BEGIN
				EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
				IF (@@ERROR <> 0 OR @ReturnCode <> 0)
					GOTO QuitWithRollback
			END

			DECLARE @jobId BINARY(16)
			EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@jobName, 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'Удаляет неактуальные данные из таблицы CacheQuotas', 
			@category_name=N'[Uncategorized (Local)]', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ClearCacheQuotas', 
					@step_id=1, 
					@cmdexec_success_code=0, 
					@on_success_action=1, 
					@on_success_step_id=0, 
					@on_fail_action=2, 
					@on_fail_step_id=0, 
					@retry_attempts=0, 
					@retry_interval=0, 
					@os_run_priority=0, @subsystem=N'TSQL', 
					@command=N'SET DATEFORMAT YMD
exec ClearQuotaCache', 
					@database_name=@dbName, 
					@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'ClearCacheQuotas', 
					@enabled=1, 
					@freq_type=4, 
					@freq_interval=1, 
					@freq_subday_type=4, 
					@freq_subday_interval=1, --каждую 1 минуту
					@freq_relative_interval=0, 
					@freq_recurrence_factor=0, 
					@active_start_date=20131205, 
					@active_end_date=99991231, 
					@active_start_time=0, 
					@active_end_time=235959
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		COMMIT TRANSACTION
		GOTO EndSave
		QuitWithRollback:
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
		EndSave:
	end
	ELSE
	begin
		set @errorMessage = 'Не удалось создать стандартное задание (job) ClearCacheQuotas на SQL-сервере. 
Либо редакция SQL-сервера не поддерживает установку заданий, либо не включен SQL Server Agent.
Вы можете использовать планировщик Windows для создания данного задания. 
Подробнее об использовании планировщика можно прочитать в описании: 
http://wiki.megatec.ru/Мастер-Тур:Создание_заданий_для_MS_SQL_Server_Express.'
		RAISERROR(@errorMessage, 16, 1)
	end
end
GO
/*********************************************************************/
/* end JOB_ClearCacheQuotas.sql */
/*********************************************************************/
-- =====================   Обновление версии БД. 9.2.20.15 - номер версии, 2014-06-11 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.15', st_moduledate = convert(datetime, '2014-06-11', 120),  st_financeversion = '9.2.20.15', st_financedate = convert(datetime, '2014-06-11', 120)
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
	SET SS_ParmValue='2014-06-11' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO