/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 29.04.2014 15:12 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.11'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.12'

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
/* begin (2014-04-17)_GrantRights_On_mwReplDeletedPricesTemp.sql */
/*********************************************************************/
grant select, insert, update, delete on dbo.mwReplDeletedPricesTemp to public
GO
/*********************************************************************/
/* end (2014-04-17)_GrantRights_On_mwReplDeletedPricesTemp.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.04.11)_Insert_ObjectAliases.sql */
/*********************************************************************/
if not exists (select 1 from ObjectAliases where OA_ID = 11013)
begin
	insert into ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (11013, '', 'Число добавленных цен', 0)
end
GO

if not exists (select 1 from ObjectAliases where OA_ID = 11014)
begin
	insert into ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (11014, '', 'Число удаленных цен', 0)
end
GO

if not exists (select 1 from ObjectAliases where OA_ID = 11015)
begin
	insert into ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (11015, '', 'Число измененных цен', 0)
end
GO
/*********************************************************************/
/* end (2014.04.11)_Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.04.14)_Insert_CheckPluginVersionExclusions.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[CheckPluginVersionExclusions] where [CPV_PluginName] LIKE 'Megatec.MasterTour.Plugins.SyncIL.dll')
BEGIN
	INSERT INTO [dbo].[CheckPluginVersionExclusions] ([CPV_PluginName]) VALUES ('Megatec.MasterTour.Plugins.SyncIL.dll')
END
GO
/*********************************************************************/
/* end (2014.04.14)_Insert_CheckPluginVersionExclusions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.04.14)_Insert_ObjectAliases.sql */
/*********************************************************************/
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 400000))
 insert into ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TABLEID, OA_CommunicationInfo) 
 values (400000, '', 'Удаление справочника сторонним приложением', 0, null)
GO
/*********************************************************************/
/* end (2014.04.14)_Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.04.29)_Insert_CheckPluginVersionExclusions.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[CheckPluginVersionExclusions] where [CPV_PluginName] LIKE 'Megatec.MasterTour.Plugins.SyncILMessage.dll')
BEGIN
	INSERT INTO [dbo].[CheckPluginVersionExclusions] ([CPV_PluginName]) VALUES ('Megatec.MasterTour.Plugins.SyncILMessage.dll')
END
GO
/*********************************************************************/
/* end (2014.04.29)_Insert_CheckPluginVersionExclusions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Job_mwReplProcessQueueUpdate.sql */
/*********************************************************************/

if (dbo.mwReplIsSubscriber() = 1)
begin
	declare @dbName nvarchar(128), @jobname nvarchar(128)
	set @jobname = DB_NAME() + '_mwReplProcessQueueUpdate'
	set @dbName = DB_NAME()

	IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = @jobname)
	EXEC msdb.dbo.sp_delete_job @job_name = @jobname, @delete_unused_schedule=1
end
GO

if (dbo.mwReplIsSubscriber() = 1)
begin
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	DECLARE @jobId BINARY(16)
	declare @dbName nvarchar(128), @jobname nvarchar(128)
	set @jobname = DB_NAME() + '_mwReplProcessQueueUpdate'
	set @dbName = DB_NAME()
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name = @jobname, 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'Устанавливается при репликации. Обрабатывает изменения цен в поисковых таблицах.', 
			@category_name=N'[Uncategorized (Local)]', 
			@owner_login_name=N'REPLUSER', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [mwReplProcessQueueUpdateStep]    Script Date: 15.10.2013 17:15:46 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'mwReplProcessQueueUpdateStep', 
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
			exec mwReplProcessQueueUpdate', 
			@database_name=@dbName, 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'mwReplProcessQueueUpdateSchedule', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=2, 
			@freq_subday_interval=30, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20110404, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959, 
			@schedule_uid=N'5b9482c5-4e69-4152-8996-df722d15b6e7'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	COMMIT TRANSACTION
	GOTO EndSave
	QuitWithRollback:
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:
end
GO
/*********************************************************************/
/* end Job_mwReplProcessQueueUpdate.sql */
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

--<DATE>2014-04-23</DATE>
---<VERSION>9.2.21.12</VERSION>

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
-------------------------------------------
declare @insertedPricesCount int, @updatedPricesCount int, @deletedPricesCount int
-------------------------------------------

Set @nTotalProgress = 1
update tp_tours set to_progress = @nTotalProgress, TO_UPDATETIME = GetDate() where to_key = @nPriceTourKey

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

	select @TrKey = to_trkey, @userKey = to_opkey from tp_tours with(nolock) where to_key = @nPriceTourKey

	if not exists (select 1 from CalculatingPriceLists with(nolock) where CP_PriceTourKey = @nPriceTourKey) and @nPriceTourKey is not null
	begin	
		insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_TourKey, CP_UserKey, CP_Status, CP_UseHolidayRule)
		values (@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @TrKey, @userKey, 1, @nUseHolidayRule)
	end
	else if @nPriceTourKey is not null
	begin
		update CalculatingPriceLists set CP_Status = 1 where CP_Key = @nCalculatingKey
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
		
		update #tmp
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
	from TP_Flights TF
	inner join #TP_Flights TF_Temp on TF.TF_ID = TF_Temp.TF_ID
	', N'@nPriceTourKey int, @nCalculatingKey int, @nNoFlight smallint, @dtSaleDate datetime', @nPriceTourKey, @nCalculatingKey, @nNoFlight, @dtSaleDate
	
	-----если перелет так и не найден, то в поле TF_CodeNew будет NULL

	--------------------------------------- закончили поиск подходящего перелета --------------------------------------
	--if ISNULL((select to_update from [dbo].tp_tours with(nolock) where to_key = @nPriceTourKey),0) <> 1
	
	declare @calcPricesCount int

	exec sys.sp_executesql N'
	
	if (1 = 1)
	BEGIN

		update [dbo].tp_tours set to_update = 1 where to_key = @nPriceTourKey
		Set @nTotalProgress = 4
		update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	
		--------------------------------------- сохраняем цены во временной таблице --------------------------------------
		/*
			xTP_UpdateMode = 1 - обновление цены
			xTP_UpdateMode = 2 - добавление цены
			xTP_UpdateMode = 3 - удаление цены
		*/
		CREATE TABLE #TP_Prices
		(
			[xTP_Key] [int] NULL ,
			[xTP_TOKey] [int] NOT NULL ,
			[xTP_DateBegin] [datetime] NOT NULL ,
			[xTP_DateEnd] [datetime] NULL ,
			[xTP_Gross] [money] NULL ,
			[xTP_TIKey] [int] NOT NULL,
			[xTP_CalculatingKey] [int] NULL,
			[xTP_UpdateMode] [int] NOT NULL DEFAULT(0)
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
				delete from TP_Prices where TP_TOKey = @nPriceTourKey
				
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
		update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey

		----------------------------------------------------------- Здесь апдейтим TS_CHECKMARGIN и TD_CHECKMARGIN
		update tp_services set ts_checkmargin = 1 where
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

		update [dbo].tp_turdates set td_checkmargin = 1 where
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
		--update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
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

		insert into #TP_Prices (xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey) 
		select tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey
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
							--if (@isPriceListPluginRecalculation = 0)
							--	update #TP_Prices set xtp_gross = @price_brutto, xtp_calculatingkey = @nCalculatingKey where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
							--else
								update #TP_Prices set xtp_gross = @price_brutto, xTP_UpdateMode = 1 where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant and xtp_gross <> @price_brutto
						end
						else if (@isPriceListPluginRecalculation = 0)
						begin
							insert into #TP_Prices (xtp_tokey, xtp_datebegin, xtp_dateend, xtp_gross, xtp_tikey, xTP_UpdateMode) 
							values (@nPriceTourKey, @dtPrevDate, @dtPrevDate, @price_brutto, @nPrevVariant, 2)
						end
					END
					ELSE
					BEGIN
						update #TP_Prices set xTP_UpdateMode = 3 where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
						--delete from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
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
					update tp_tours set to_progress = @nTotalProgress, to_updatetime = GetDate() where to_key = @nPriceTourKey
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
		update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey

		delete from #tp_prices where xtp_dateBegin < dateadd(day, -1, getdate())

		select @updatedPricesCount = count(1) from #tp_prices where xTP_UpdateMode = 1
		select @insertedPricesCount = count(1) from #tp_prices where xTP_UpdateMode = 2
		select @deletedPricesCount = count(1) from #tp_prices where xTP_UpdateMode = 3

		DECLARE	@cpKey int
		if exists (select 1 from #tp_prices where xTP_UpdateMode in (1, 2))
		begin
			INSERT INTO CalculatingPriceLists (CP_CreateDate, CP_PriceTourKey) VALUES (GETDATE(), @nPriceTourKey) 
			SET @cpKey = SCOPE_IDENTITY()	
		end
		
		-- изменение цен
		if exists (select 1 from #tp_prices where xTP_UpdateMode = 1)
		begin
			update tp_prices
			set tp_gross = xtp_gross,
			tp_updatedate = getdate(),
			tp_calculatingkey = @cpKey
			from #tp_prices
			where TP_Key = xTP_Key
			and xTP_UpdateMode = 1
		end
		-- вставка цен
		if exists (select 1 from #tp_prices where xTP_UpdateMode = 2)
		begin
			select @PricesCount = count(1) from #TP_Prices where xTP_UpdateMode = 2
			exec GetNKeys ''TP_PRICES'', @PricesCount, @nTP_PriceKeyMax output
			set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @PricesCount + 1

			update T set T.xTP_Key = @nTP_PriceKeyMax - T.xTP_KeyNew + 2
			from 
			(
				select xTP_Key, row_number() over (order by xTP_Key) as xTP_KeyNew
				from #tp_prices
				where xTP_UpdateMode = 2 
			) as T option (maxdop 1)

			INSERT INTO TP_Prices (tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey) 
			select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey, @cpKey
			from #TP_Prices 
			where xTP_UpdateMode = 2
		end
		-- удаление
		if exists (select 1 from #tp_prices where xTP_UpdateMode = 3)
		begin
			delete from tp_prices 
			where tp_tokey = @nPriceTourKey
			and tp_key in (select xtp_key from #TP_Prices where xTP_UpdateMode = 3)
		end

		-- если в туре цены изменились, надо обновить дату создания (для TourML например)
		if exists (select 1 from #tp_prices where xTP_UpdateMode in (1, 2, 3))
			update tp_tours set to_datecreated = GetDate() where to_key = @nPriceTourKey

		if (@nIsEnabled = 1)
		begin
			-- только обновили значения
			if exists (select 1 from #tp_prices where xTP_UpdateMode = 1) and not exists (select 1 from #tp_prices where xTP_UpdateMode in (2,3))
			begin
				IF dbo.mwReplIsPublisher() > 0
				BEGIN
					INSERT INTO mwReplTours(rt_trkey, rt_tokey, rt_date, rt_calckey, rt_updateOnlinePrices)
					SELECT TO_TRKey, TO_Key, GETDATE(), @cpKey, 2
					FROM tp_tours
					WHERE TO_Key = @nPriceTourKey
				END
				ELSE
				BEGIN
					EXEC mwReplUpdatePriceEnabledAndValue @nPriceTourKey, @cpKey
				END
			end
			else
			begin
				declare @mwSinglePrice nvarchar(10), @countryKey int
				select @countryKey = to_cnkey from tp_tours where to_key = @nPriceTourKey
				select @mwSinglePrice = isnull(dbo.GetCountrySetting(@countryKey, ''mwSinglePrice''), N''0'')

				-- механизм единственной цены
				if (@mwSinglePrice <> ''0'')
				begin
					EXEC FillMasterWebSearchFields @nPriceTourKey, null
				end
				else
				begin
					-- удаляем из инета удаленные цены
					if exists (select 1 from #tp_prices where xTP_UpdateMode = 3)
					begin
						insert into dbo.mwReplDeletedPricesTemp (rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey) 
						select xtp_key, TO_CNKey, TL_CTDepartureKey
						from #TP_Prices
						join tp_tours on xtp_tokey = to_key
						join tbl_TurList on tl_key = to_trkey
						where xTP_UpdateMode = 3	
					end

					-- только обновление цен (удаление было выше)
					if exists (select 1 from #tp_prices where xTP_UpdateMode = 1) and not exists (select 1 from #tp_prices where xTP_UpdateMode = 2)
					begin
						IF dbo.mwReplIsPublisher() > 0
						BEGIN
							INSERT INTO mwReplTours(rt_trkey, rt_tokey, rt_date, rt_calckey, rt_updateOnlinePrices)
							SELECT TO_TRKey, TO_Key, GETDATE(), @cpKey, 2
							FROM tp_tours
							WHERE TO_Key = @nPriceTourKey
						END
						ELSE
						BEGIN
							EXEC mwReplUpdatePriceEnabledAndValue @nPriceTourKey, @cpKey
						END
					end
					-- выставляем в интернет новые цены
					else if exists (select 1 from #tp_prices where xTP_UpdateMode in (1, 2))
					begin
						EXEC FillMasterWebSearchFields @nPriceTourKey, @cpKey
					end	
				end
			end
		end

		-----------------------------------------------------КОНЕЦ возвращаем обратно цены ------------------------------------------------------

		update tp_lists set ti_update = 0 where ti_tokey = @nPriceTourKey
		update tp_turdates set td_update = 0, td_checkmargin = 0 where td_tokey = @nPriceTourKey
		Set @nTotalProgress = 99
		update tp_tours set to_progress = @nTotalProgress, to_update = 0, to_updatetime = GetDate(),
							TO_CalculateDateEnd = GetDate(), TO_PriceCount = (Select Count(*) 
			From TP_Prices with(nolock) Where TP_ToKey = to_key) where to_key = @nPriceTourKey
		update tp_services set ts_checkmargin = 0 where ts_tokey = @nPriceTourKey

	END

	--Заполнение полей в таблице tp_lists
	declare @toKey int, @add int
	set @toKey = @nPriceTourKey
	set @add = @nUpdate

		update tp_lists
			set ti_hotelkeys = dbo.mwGetTiHotelKeys(ti_key),
				ti_hotelroomkeys = dbo.mwGetTiHotelRoomKeys(ti_key),
				ti_hoteldays = dbo.mwGetTiHotelNights(ti_key),
				ti_hotelstars = dbo.mwGetTiHotelStars(ti_key),
				ti_pansionkeys = dbo.mwGetTiPansionKeys(ti_key),
				ti_nights = dbo.mwGetTiNights(ti_key)
		where
			ti_tokey = @toKey 
			and ti_CalculatingKey = @nCalculatingKey
		
		update tp_lists
		set
			ti_hdpartnerkey = ts_oppartnerkey,
			ti_firsthotelpartnerkey = ts_oppartnerkey,
			ti_hdday = ts_day,
			ti_hdnights = ts_days
		from tp_servicelists with (nolock)
			inner join tp_services with (nolock) on (tl_tskey = ts_key and ts_svkey = 3)
		where tl_tikey = ti_key and ts_code = ti_firsthdkey and ti_tokey = @toKey and tl_tokey = @toKey
			and ts_tokey = @toKey 
			and ti_CalculatingKey = @nCalculatingKey
		------------------------------------------------------------------------------

	Set @nTotalProgress = 100
	update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	
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
	, @nUseHolidayRule smallint
	, @insertedPricesCount int output
	, @updatedPricesCount int output
	, @deletedPricesCount int output'
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
	, @insertedPricesCount output
	, @updatedPricesCount output
	, @deletedPricesCount output
	
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

	SET @sHI_Text = CONVERT(varchar(10),@insertedPricesCount)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11013, null, @sHI_Text, null, @nUpdate, null, null, 0
	SET @sHI_Text = CONVERT(varchar(10),@deletedPricesCount)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11014, null, @sHI_Text, null, @nUpdate, null, null, 0
	SET @sHI_Text = CONVERT(varchar(10),@updatedPricesCount)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11015, null, @sHI_Text, null, @nUpdate, null, null, 0

	-- апдейтим таблицу CalculatingPriceLists
	update CalculatingPriceLists set CP_Status = 0, CP_StartTime = null where CP_Key = @nCalculatingKey
	
	Return 0
END
GO

grant execute on [dbo].[CalculatePriceList] to public
GO
/*********************************************************************/
/* end sp_CalculatePriceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DogListToQuotas.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogListToQuotas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogListToQuotas]
GO

CREATE PROCEDURE [dbo].[DogListToQuotas]
(
	--<VERSION>9.20.11</VERSION>
	--<DATA>07.04.2014</DATA>
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
/* begin sp_FillMasterWebSearchFields.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FillMasterWebSearchFields]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[FillMasterWebSearchFields]
GO

create procedure [dbo].[FillMasterWebSearchFields](@tokey int, @calcKey int = null, @forceEnable smallint = null, @overwritePrices bit = null)
-- if @forceEnable > 0 (by default) then make call mwEnablePriceTour @calcKey, 1 at the end of the procedure
as
begin
	--<VERSION>2009.2.21.1</VERSION>
	--<DATE>2014-04-16</DATE>
	set @forceEnable = isnull(@forceEnable, 1)

	declare @findByAdultChild int, @newRecalcPrice int
	
	declare @counter int, @deleteCount int, @params nvarchar(500)
	
	set @findByAdultChild = isnull((select top 1 convert(int, SS_ParmValue) from SystemSettings where SS_ParmName = 'OnlineFindByAdultChild'), 0)
	set @newRecalcPrice = isnull((select top 1 convert(int, SS_ParmValue) from SystemSettings where SS_ParmName = 'NewReCalculatePrice'), 0)

	if (@tokey is null)
	begin
		print 'Procedure does not support NULL param. You must specify @tokey parameter.'
		return
	end

	DECLARE @departFromKey INT
	SELECT top 1 @departFromKey = TL_CTDepartureKey FROM tbl_TurList 
	INNER JOIN tp_Tours 
	ON TL_KEY = TO_TRKey
	WHERE TO_Key = @tokey
	
	IF EXISTS(SELECT 1 FROM mwSpoDataTable WHERE sd_tourkey = @tokey AND sd_ctkeyfrom <> @departFromKey)
	BEGIN
		SET @calcKey = null
		EXEC mwReplDisablePriceTour @tokey
	END

	update dbo.TP_Tours set TO_Progress = 0 where TO_Key = @tokey

	if dbo.mwReplIsSubscriber() > 0
	begin
		exec dbo.mwFillTP @tokey, @calcKey
	end

	create table #tmpHotelData (
		thd_tourkey int, 
		thd_firsthdkey int,
		thd_firstpnkey int, 
		thd_cnkey int, 
		thd_tlkey int, 
		thd_isenabled smallint, 
		thd_tourcreated datetime, 
		thd_hdstars nvarchar(15), 
		thd_ctkey int, 
		thd_rskey int, 
		thd_hdkey int, 
		thd_hdpartnerkey int, 
		thd_hrkey int, 
		thd_rmkey int, 
		thd_rckey int, 
		thd_ackey int, 
		thd_pnkey int, 
		thd_hdmain smallint,
		thd_firsthotelday int,
		thd_ctkeyfrom int, 
		thd_ctkeyto int, 
		thd_apkeyfrom int, 
		thd_apkeyto int,
		thd_tourtype int,
		thd_cnname nvarchar(200) collate database_default,
		thd_tourname nvarchar(200) collate database_default,
		thd_hdname nvarchar(200) collate database_default,
		thd_ctname nvarchar(200) collate database_default,
		thd_rsname nvarchar(200) collate database_default,
		thd_ctfromname nvarchar(200) collate database_default,
		thd_cttoname nvarchar(200) collate database_default,
		thd_tourtypename nvarchar(200) collate database_default,
		thd_pncode nvarchar(50) collate database_default,
		thd_hdorder int,
		thd_hotelkeys nvarchar(256) collate database_default,
		thd_pansionkeys nvarchar(256) collate database_default,
		thd_hotelnights nvarchar(256) collate database_default,
		thd_tourvalid datetime,
		thd_hotelurl varchar(254) collate database_default
	)

	-- создадим темповую ценовую таблицу
	select top 1 * into #tempPriceTable from mwPriceDataTable with(nolock)
	truncate table #tempPriceTable
	
	
	CREATE NONCLUSTERED INDEX [x_main] ON [dbo].[#tempPriceTable] 
	(
		pt_tourdate asc,
		pt_hdkey asc,
		pt_rmkey asc,
		pt_rckey asc,
		pt_ackey asc,
		pt_pnkey asc,
		pt_days asc,
		pt_nights asc,
		pt_tourtype asc,
		pt_ctkeyfrom asc
	)

	select top 1
		ti_key,
		ti_tokey,
		ti_firsthdkey,
		ti_firstpnkey,
		ti_firsthrkey,
		ti_firsthotelday,
		ti_lasthotelday,
		ti_totaldays,
		ti_nights,
		ti_hotelkeys,
		ti_hotelroomkeys,
		ti_hoteldays,
		ti_hotelstars,
		ti_pansionkeys,
		ti_hdpartnerkey,
		ti_firsthotelpartnerkey,
		ti_hdday,
		ti_hdnights,
		ti_chkey,
		ti_chday,
		ti_chpkkey,
		ti_chprkey,
		ti_ctkeyfrom,
		ti_chbackkey,
		ti_chbackday,
		ti_chbackpkkey,
		ti_chbackprkey,
		ti_ctkeyto,
		ti_apkeyfrom,
		ti_apkeyto,
		ti_firstctkey,
		ti_firstrskey,
		ti_firsthdstars
	into #tp_lists
	from tp_lists with(nolock)

	truncate table #tp_lists
	alter table #tp_lists add primary key(ti_key)

	-- Город отправления из свойств тура
	declare @ctdeparturekey int
	select	@ctdeparturekey = tl_ctdeparturekey
	from	tp_tours with(nolock)
		inner join tbl_turList with(nolock) on tbl_turList.tl_key = to_trkey
	where to_key = @tokey

	if (@ctdeparturekey is null or @ctdeparturekey = 0)
	begin
		-- Подбираем город вылета первого рейса
		exec GetCityDepartureKey @tokey, @ctdeparturekey output
	end

	declare @firsthdday int
	select @firsthdday = (select min(ts_day) 
				from tp_services with (nolock)
 				where ts_svkey = 3 and ts_tokey = @tokey)

	declare @count_ts_code int

	select @count_ts_code = count(distinct ts_code)
	from tp_services with(nolock)
	where ts_svkey = 1 and ts_tokey = @tokey 
	and (ts_day <= @firsthdday or (ts_day = 1 and @firsthdday = 0)) 
	and ts_subcode2 = @ctdeparturekey

	if (@count_ts_code > 1)
	begin
		if(@calcKey is not null)
		begin
			insert into #tp_lists
			select
				ti_key,
				ti_tokey,
				ti_firsthdkey,
				ti_firstpnkey,
				ti_firsthrkey,
				@firsthdday as ti_firsthotelday,
				ti_lasthotelday,
				ti_totaldays,
				ti_nights,
				ti_hotelkeys,
				ti_hotelroomkeys,
				ti_hoteldays,
				ti_hotelstars,
				ti_pansionkeys,
				ti_hdpartnerkey,
				ti_firsthotelpartnerkey,
				ti_hdday,
				ti_hdnights,
				(
					select top 1 ts_code
					from tp_servicelists with(nolock) 
					inner join tp_services with(nolock) on tl_tskey = ts_key and ts_svkey = 1
					where tl_tikey = ti_key and ts_tokey = @tokey and tl_tokey = @tokey 
					and (ts_day <= @firsthdday or (ts_day = 1 and @firsthdday = 0)) and ts_subcode2 = @ctdeparturekey
				) as ti_chkey,
				ti_chday,
				ti_chpkkey,
				ti_chprkey,
				ti_ctkeyfrom,
				ti_chbackkey,
				ti_chbackday,
				ti_chbackpkkey,
				ti_chbackprkey,
				ti_ctkeyto,
				ti_apkeyfrom,
				ti_apkeyto,
				ti_firstctkey,
				ti_firstrskey,
				ti_firsthdstars
			from tp_lists with(nolock)
			where TI_Key in (select TP_TIKey from TP_Prices with(nolock) where TP_TOKey = TI_TOKey and TP_CalculatingKey = @calcKey) 
			and TI_TOKey = @tokey
		end
		else
		begin
			insert into #tp_lists
			select
				ti_key,
				ti_tokey,
				ti_firsthdkey,
				ti_firstpnkey,
				ti_firsthrkey,
				@firsthdday as ti_firsthotelday,
				ti_lasthotelday,
				ti_totaldays,
				ti_nights,
				ti_hotelkeys,
				ti_hotelroomkeys,
				ti_hoteldays,
				ti_hotelstars,
				ti_pansionkeys,
				ti_hdpartnerkey,
				ti_firsthotelpartnerkey,
				ti_hdday,
				ti_hdnights,
				(
					select top 1 ts_code
					from tp_servicelists with(nolock) 
					inner join tp_services with(nolock) on tl_tskey = ts_key and ts_svkey = 1
					where tl_tikey = ti_key and ts_tokey = @tokey and tl_tokey = @tokey 
					and (ts_day <= @firsthdday or (ts_day = 1 and @firsthdday = 0)) and ts_subcode2 = @ctdeparturekey
				) as ti_chkey,	
				ti_chday,
				ti_chpkkey,
				ti_chprkey,
				ti_ctkeyfrom,
				ti_chbackkey,
				ti_chbackday,
				ti_chbackpkkey,
				ti_chbackprkey,
				ti_ctkeyto,
				ti_apkeyfrom,
				ti_apkeyto,
				ti_firstctkey,
				ti_firstrskey,
				ti_firsthdstars
			from tp_lists with(nolock)
			where TI_TOKey = @tokey		
		end
	end
	else
	begin

		declare @ts_code int
		declare @ti_key int
		select top 1 @ti_key = ti_key
		from tp_lists with(nolock)
		where TI_TOKey = @tokey	

		select top 1 @ts_code = ts_code
		from tp_services with(nolock)
		where ts_svkey = 1 and ts_tokey = @tokey
		and (ts_day <= @firsthdday or (ts_day = 1 and @firsthdday = 0)) 
		and ts_subcode2 = @ctdeparturekey

		if(@calcKey is not null)
		begin
			insert into #tp_lists
			select
				ti_key,
				ti_tokey,
				ti_firsthdkey,
				ti_firstpnkey,
				ti_firsthrkey,
				@firsthdday as ti_firsthotelday,
				ti_lasthotelday,
				ti_totaldays,
				ti_nights,
				ti_hotelkeys,
				ti_hotelroomkeys,
				ti_hoteldays,
				ti_hotelstars,
				ti_pansionkeys,
				ti_hdpartnerkey,
				ti_firsthotelpartnerkey,
				ti_hdday,
				ti_hdnights,
				@ts_code as ti_chkey,			
				ti_chday,
				ti_chpkkey,
				ti_chprkey,
				ti_ctkeyfrom,
				ti_chbackkey,
				ti_chbackday,
				ti_chbackpkkey,
				ti_chbackprkey,
				ti_ctkeyto,
				ti_apkeyfrom,
				ti_apkeyto,
				ti_firstctkey,
				ti_firstrskey,
				ti_firsthdstars
			from tp_lists with(nolock)
			where TI_Key in (select TP_TIKey from TP_Prices with(nolock) where TP_TOKey = TI_TOKey and TP_CalculatingKey = @calcKey) 
			and TI_TOKey = @tokey
		end
		else
		begin
			insert into #tp_lists
			select
				ti_key,
				ti_tokey,
				ti_firsthdkey,
				ti_firstpnkey,
				ti_firsthrkey,
				@firsthdday as ti_firsthotelday,
				ti_lasthotelday,
				ti_totaldays,
				ti_nights,
				ti_hotelkeys,
				ti_hotelroomkeys,
				ti_hoteldays,
				ti_hotelstars,
				ti_pansionkeys,
				ti_hdpartnerkey,
				ti_firsthotelpartnerkey,
				ti_hdday,
				ti_hdnights,
				@ts_code as ti_chkey,			
				ti_chday,
				ti_chpkkey,
				ti_chprkey,
				ti_ctkeyfrom,
				ti_chbackkey,
				ti_chbackday,
				ti_chbackpkkey,
				ti_chbackprkey,
				ti_ctkeyto,
				ti_apkeyfrom,
				ti_apkeyto,
				ti_firstctkey,
				ti_firstrskey,
				ti_firsthdstars
			from tp_lists with(nolock)
			where TI_TOKey = @tokey		
		end
	end

	declare @mwAccomodationPlaces nvarchar(254)
	declare @mwRoomsExtraPlaces nvarchar(254)
	declare @mwSearchType int
	declare @sql nvarchar(4000)
	declare @countryKey int
	declare @cityFromKey int

	update dbo.TP_Tours set TO_Progress = 7 where TO_Key = @tokey

	update TP_Tours set TO_MinPrice = (
			select min(TP_Gross) 
			from TP_Prices with(nolock) 
				left join TP_Lists with(nolock) on ti_key = tp_tikey
				left join HotelRooms with(nolock) on hr_key = ti_firsthrkey				
			where TP_TOKey = TO_Key 
					and hr_main > 0 
					and (isnull(HR_AGEFROM, 0) <= 0 or isnull(HR_AGEFROM, 0) > 16)
		)
		where TO_Key = @tokey

	update dbo.TP_Tours set TO_Progress = 13 where TO_Key = @tokey

	update #tp_lists
	set
		ti_lasthotelday = (select max(ts_day)
				from tp_servicelists  with (nolock)
					inner join tp_services with (nolock) on tl_tskey = ts_key
				where tl_tikey = ti_key and ts_svkey = 3 and TS_TOKey = @tokey and TL_TOKey = @tokey)

	update dbo.TP_Tours set TO_Progress = 20 where TO_Key = @tokey	

	update dbo.TP_Tours set TO_Progress = 30 where TO_Key = @tokey

	-- MEG00024548 Paul G 11.01.2009
	-- изменил логику подсчёта кол-ва ночей в туре
	-- раньше было сумма ночей проживания по всем отелям в туре
	-- теперь если проживания пересекаются, лишние ночи не суммируются
	update #tp_lists 
	set
		ti_nights = dbo.mwGetTiNights(ti_key)

	--koshelev
	--02.04.2012 MEG00040744
    declare @result nvarchar(256)
    set @result = N''
    select @result = @result + rtrim(ltrim(str(tbl.ti_nights))) + N', ' from (select distinct ti_nights from (select ti_nights from #tp_lists union select ti_nights from tp_lists with(nolock) where ti_tokey = @tokey ) as tbl2) tbl order by tbl.ti_nights
    declare @len int
    set @len = len(@result)
    if(@len > 0)
          set @result = substring(@result, 1, @len - 1)

    update TP_Tours set TO_HotelNights = @result where TO_Key = @tokey

	update dbo.TP_Tours set TO_Progress = 40 where TO_Key = @tokey

	update #tp_lists 
		set ti_hotelkeys = dbo.mwGetTiHotelKeys(ti_key),
			ti_hotelroomkeys = dbo.mwGetTiHotelRoomKeys(ti_key),
			ti_hoteldays = dbo.mwGetTiHotelNights(ti_key),
			ti_hotelstars = dbo.mwGetTiHotelStars(ti_key),
			ti_pansionkeys = dbo.mwGetTiPansionKeys(ti_key)

	update #tp_lists
	set
		ti_hdpartnerkey = ts_oppartnerkey,
		ti_firsthotelpartnerkey = ts_oppartnerkey,
		ti_hdday = ts_day,
		ti_hdnights = ts_days
	from tp_servicelists with (nolock)
		inner join tp_services with (nolock) on (tl_tskey = ts_key and ts_svkey = 3)
	where tl_tikey = ti_key and ts_code = ti_firsthdkey and TS_TOKey = @tokey and TL_TOKey = @tokey

	update dbo.TP_Tours set TO_Progress = 50 where TO_Key = @tokey

	-- город вылета + прямой перелет
	update #tp_lists
	set 
		ti_chday = ts_day,
		ti_chpkkey = ts_oppacketkey,
		ti_chprkey = ts_oppartnerkey
	from tp_servicelists with(nolock) inner join tp_services with(nolock) on tl_tskey = ts_key and ts_svkey = 1
	where	tl_tikey = ti_key 
		and (ts_day <= ti_firsthotelday or (ts_day = 1 and ti_firsthotelday = 0))
		and ts_code = ti_chkey 
		and ts_subcode2 = @ctdeparturekey
		and TS_TOKey = @tokey and TL_TOKey = @tokey

	update #tp_lists
	set 
		ti_ctkeyfrom = @ctdeparturekey

	-- Проверка наличия перелетов в город вылета
	declare @existBackCharter smallint
	select	@existBackCharter = count(ts_key)
	from	tp_services with(nolock)
	where	ts_tokey = @tokey
		and	ts_svkey = 1
		and ts_ctkey = @ctdeparturekey

	-- город прилета + обратный перелет
	update #tp_lists
	set 
		ti_chbackkey = ts_code,
		ti_chbackday = ts_day,
		ti_chbackpkkey = ts_oppacketkey,
		ti_chbackprkey = ts_oppartnerkey,
		ti_ctkeyto = ts_subcode2
	from tp_servicelists with(nolock)
		inner join tp_services with(nolock) on (tl_tskey = ts_key and ts_svkey = 1)
		inner join tp_tours with(nolock) on ts_tokey = to_key 
	where 
		tl_tikey = ti_key 
		and ts_day > ti_lasthotelday
		and (ts_ctkey = @ctdeparturekey or @existBackCharter = 0)
		and TI_TOKey = @tokey
		and TS_TOKey = @tokey and TL_TOKey = @tokey

	-- _ключ_ аэропорта вылета
	update #tp_lists 
	set 
		ti_apkeyfrom = (select top 1 ap_key from airport with(nolock), charter with(nolock) 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chkey)

	-- _ключ_ аэропорта прилета
	update #tp_lists
	set 
		ti_apkeyto = (select top 1 ap_key from airport with(nolock), charter with(nolock) 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chbackkey)

	-- ключ города и ключ курорта + звезды
	update #tp_lists
	set
		ti_firstctkey = hd_ctkey,
		ti_firstrskey = hd_rskey,
		ti_firsthdstars = hd_stars
	from hoteldictionary with(nolock)
	where 
		ti_firsthdkey = hd_key

	update dbo.TP_Tours set TO_Progress = 60 where TO_Key = @tokey

	if dbo.mwReplIsPublisher() > 0
	begin
		declare @trkey int
		select @trkey = to_trkey from dbo.tp_tours with(nolock) where to_key = @tokey
		
		insert into dbo.mwReplTours (rt_trkey, rt_tokey, rt_date, rt_CalcKey)
		values (@trkey, @tokey, getdate(), @calcKey)
		
		update CalculatingPriceLists set CP_Status = 0 where CP_PriceTourKey = @tokey
		update dbo.TP_Tours 
		set TO_Update = 0, 
			TO_Progress = 100,
			TO_IsEnabled = 1
		where TO_Key = @tokey
		
		--return
	end

	-- временная таблица с информацией об отелях
	insert into #tmpHotelData (
		thd_tourkey, 
		thd_firsthdkey, 
		thd_firstpnkey, 
		thd_cnkey, 
		thd_tlkey, 
		thd_isenabled, 
		thd_tourcreated, 
		thd_hdstars, 
		thd_ctkey, 
		thd_rskey, 
		thd_hdkey, 
		thd_hdpartnerkey, 
		thd_hrkey, 
		thd_rmkey, 
		thd_rckey, 
		thd_ackey, 
		thd_pnkey, 
		thd_hdmain,
		thd_firsthotelday,
		thd_ctkeyfrom, 
		thd_ctkeyto, 
		thd_apkeyfrom, 
		thd_apkeyto,
		thd_tourtype,
		thd_cnname,
		thd_tourname,
		thd_hdname,
		thd_ctname,
		thd_rsname,
		thd_ctfromname,
		thd_cttoname,
		thd_tourtypename,
		thd_pncode,
		thd_hotelkeys,
		thd_pansionkeys,
		thd_hotelnights,
		thd_tourvalid,
		thd_hotelurl
	)
	select distinct 
		to_key, 
		ti_firsthdkey, 
		ti_firstpnkey,
		to_cnkey, 
		to_trkey, 
		@forceEnable, 
		to_datecreated, 
		hd_stars, 
		hd_ctkey, 
		hd_rskey, 
		ts_code, 
		ts_oppartnerkey, 
		ts_subcode1, 
		hr_rmkey, 
		hr_rckey, 
		hr_ackey, 
		ts_subcode2, 
		(case ts_code when ti_firsthdkey then 1 else 0 end),
		ti_firsthotelday,
		isnull(ti_ctkeyfrom, 0), 
		ti_ctkeyto, 
		ti_apkeyfrom, 
		ti_apkeyto,
		tl_tip,
		cn_name,
		isnull(tl_nameweb, isnull(to_name, tl_name)),
		hd_name,
		ct_name,
		null,
		null,
		null,
		tp_name,
		pn_code,
		ti_hotelkeys,
		ti_pansionkeys,
		ti_hoteldays,
		to_datevalid,
		hd_http
	from #tp_lists with(nolock)
		inner join tp_tours with(nolock) on ti_tokey = to_key
		inner join tp_servicelists with(nolock) on tl_tikey = ti_key 
		inner join tp_services with(nolock) on (tl_tskey = ts_key and ts_svkey = 3) 
		inner join hoteldictionary with(nolock) on ts_code = hd_key
		inner join hotelrooms with(nolock) on hr_key = ts_subcode1
		inner join turList with(nolock) on turList.tl_key = to_trkey
		inner join country with(nolock) on cn_key = to_cnkey
		inner join citydictionary with(nolock) on ct_key = hd_ctkey
		inner join tiptur with(nolock) on tp_key = tl_tip
		inner join pansion with(nolock) on pn_key = ts_subcode2
	where to_key = @tokey and to_datevalid >= getdate() 
		and TS_TOKey = @tokey and TL_TOKey = @tokey

	update #tmpHotelData set thd_hdorder = (select min(ts_day) from tp_services with(nolock) where ts_tokey = thd_tourkey and ts_svkey = 3 and ts_code = thd_hdkey)
	update #tmpHotelData set thd_rsname = rs_name from resorts with(nolock) where rs_key = thd_rskey
	update #tmpHotelData set thd_ctfromname = ct_name from citydictionary with(nolock) where ct_key = thd_ctkeyfrom
	update #tmpHotelData set thd_ctfromname = '-Без перелета-' where thd_ctkeyfrom = 0
	update #tmpHotelData set thd_cttoname = ct_name from citydictionary with(nolock) where ct_key = thd_ctkeyto
	update #tmpHotelData set thd_cttoname = '-Без перелета-' where thd_ctkeyto = 0
	--

	update dbo.TP_Tours set TO_Progress = 70 where TO_Key = @tokey

	select @mwAccomodationPlaces = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings with(nolock)
	where SS_ParmName = 'MWAccomodationPlaces'

	select @mwRoomsExtraPlaces = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWRoomsExtraPlaces'

	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'

	if (@calcKey is null)
	begin
		delete from dbo.mwSpoDataTable where sd_tourkey = @tokey
		delete from dbo.mwPriceHotels where sd_tourkey = @tokey
		delete from dbo.mwPriceDurations where sd_tourkey = @tokey
	end
	else
	begin
		--saifullina 16.01.2013 если мы изменили название и дозаписываем тур, то должны дозаписать с новым названием
		update dbo.mwSpoDataTable set sd_tourname=(select to_name from TP_Tours with(nolock) where TO_Key=@tokey) where sd_tourkey = @tokey
	end

	--MEG00026692 Paul G 25.03.2010
	--функции от ti_key должны вызываться на каждую запись из tp_lists
	--поэтому результаты их выполнения записываю в темповую таблицу
	--которую джоиню в последующем селекте
	create table #tempTourInfo (
		tt_tikey int,
		tt_charterto varchar(256) collate database_default,
		tt_charterback varchar(256) collate database_default,
		tt_tourhotels varchar(256) collate database_default,
		tt_directFlightAttribute int,
		tt_backFlightAttribute int
	)

	insert into #tempTourInfo
	(
		tt_tikey, 
		tt_charterto, 
		tt_charterback, 
		tt_tourhotels,
		tt_directFlightAttribute,
		tt_backFlightAttribute
	)
	select 
		ti_key, 
		dbo.mwGetTourCharters(ti_key, 1), 
		dbo.mwGetTourCharters(ti_key, 0), 
		dbo.mwGetTourHotels(ti_key),
		dbo.mwGetTourCharterAttribute(ti_key, 1),
		dbo.mwGetTourCharterAttribute(ti_key, 0)
	from #tp_lists with(nolock)
	--End MEG00026692	

	if(@calcKey is not null)
	begin
		insert into #tempPriceTable (
			[pt_mainplaces],
			[pt_addplaces],
			[pt_main],
			[pt_tourvalid],
			[pt_tourcreated],
			[pt_tourdate],
			[pt_days],
			[pt_nights],
			[pt_cnkey],
			[pt_ctkeyfrom],
			[pt_apkeyfrom],
			[pt_ctkeyto],
			[pt_apkeyto],
			[pt_ctkeybackfrom],
			[pt_ctkeybackto],
			[pt_tourkey],
			[pt_tourtype],
			[pt_tlkey],
			[pt_pricelistkey],
			[pt_pricekey],
			[pt_price],
			[pt_hdkey],
			[pt_hdpartnerkey],
			[pt_rskey],
			[pt_ctkey],
			[pt_hdstars],
			[pt_pnkey],
			[pt_hrkey],
			[pt_rmkey],
			[pt_rckey],
			[pt_ackey],
			[pt_childagefrom],
			[pt_childageto],
			[pt_childagefrom2],
			[pt_childageto2],
			[pt_hdname],
			[pt_tourname],
			[pt_pnname],
			[pt_pncode],
			[pt_rmname],
			[pt_rmcode],
			[pt_rcname],
			[pt_rccode],
			[pt_acname],
			[pt_accode],
			[pt_rsname],
			[pt_ctname],
			[pt_rmorder],
			[pt_rcorder],
			[pt_acorder],
			[pt_rate],
			[pt_toururl],
			[pt_hotelurl],
			[pt_isenabled],
			[pt_chkey],
			[pt_chbackkey],
			[pt_hdday],
			[pt_hdnights],
			[pt_chday],
			[pt_chpkkey],
			[pt_chprkey],
			[pt_chbackday],
			[pt_chbackpkkey],
			[pt_chbackprkey],
			pt_hotelkeys,
			pt_hotelroomkeys,
			pt_hotelstars,
			pt_pansionkeys,
			pt_hotelnights,
			pt_chdirectkeys,
			pt_chbackkeys,
			[pt_topricefor],
			pt_tlattribute,
			pt_hddetails,
			pt_directFlightAttribute,
			pt_backFlightAttribute
		)
		select 
				(	case when @mwAccomodationPlaces = '0'
					then isnull(rm_nplaces, 0)
					else (	case when @findByAdultChild = 1 -- искать по взрослым
							then isnull(AC_NADMAIN, 0) + isnull(AC_NADEXTRA,0)
							-- искать по основным
							else isnull(AC_NADMAIN, 0) + isnull(AC_NCHMAIN, 0)
							end)
					end),
				(	case when isnull(ac_nmenexbed, -1) = -1
					then (	case when @mwRoomsExtraPlaces <> '0' 
							then isnull(rm_nplacesex, 0)
							else isnull(ac_nmenexbed, 0)
							end)
					else (	case when @findByAdultChild = 1 -- искать по детям
							then isnull(AC_NCHMAIN, 0) + isnull(AC_NCHEXTRA, 0)
							-- искать по дополнительным местам
							else isnull(AC_NADEXTRA, 0) + isnull(AC_NCHEXTRA, 0)
							end)
					end),
			hr_main, 
			to_datevalid, 
			to_datecreated, 
			td_date,
			ti_totaldays,
			ti_nights,
			to_cnkey, 
			isnull(ti_ctkeyfrom, 0), 
			ti_apkeyfrom,
			ti_ctkeyto, 
			ti_apkeyto, 
			null,
			null,
			to_key, 
			tl_tip,
			tl_key, 
			ti_key, 
			tp_key,
			tp_gross, 
			ti_firsthdkey, 
			ti_hdpartnerkey,
			hd_rskey, 
			hd_ctkey, 
			hd_stars, 
			ti_firstpnkey,
			ti_firsthrkey, 
			hr_rmkey, 
			hr_rckey, 
			hr_ackey,
			ac_agefrom, 
			ac_ageto, 
			ac_agefrom2,
			ac_ageto2, 
			hd_name, 
			substring(tl_nameweb,1,128), 
			pn_name, 
			pn_code, 
			rm_name, 
			rm_code,
			rc_name, 
			rc_code, 
			ac_name, 
			ac_code, 
			rs_name,
			ct_name, 
			rm_order, 
			rc_order, 
			ac_order,
			to_rate,
			tl_webhttp,
			hd_http, 
			@forceEnable,
			ti_chkey,
			ti_chbackkey,
			ti_hdday,
			ti_hdnights,
			ti_chday,
			ti_chpkkey,
			ti_chprkey,
			ti_chbackday,
			ti_chbackpkkey,
			ti_chbackprkey,
			ti_hotelkeys,
			ti_hotelroomkeys,
			ti_hotelstars,
			ti_pansionkeys,
			ti_hoteldays,
			tt_charterto,
			tt_charterback,
			to_pricefor,
			tl_attribute,
			tt_tourhotels,
			tt_directFlightAttribute,
			tt_backFlightAttribute
		from tp_tours with(nolock)
			inner join turList with(nolock) on to_trkey = tl_key
			inner join #tp_lists with(nolock) on ti_tokey = to_key
			inner join tp_prices with(nolock) on tp_tikey = ti_key
			inner join tp_turdates with(nolock) on (td_tokey = to_key and td_date between tp_datebegin and tp_dateend)
			inner join hoteldictionary with(nolock) on ti_firsthdkey = hd_key
			inner join hotelrooms with(nolock) on ti_firsthrkey = hr_key
			inner join pansion with(nolock) on ti_firstpnkey = pn_key
			inner join rooms with(nolock) on hr_rmkey = rm_key
			inner join roomscategory with(nolock) on hr_rckey = rc_key
			inner join accmdmentype with(nolock) on hr_ackey = ac_key
			inner join citydictionary with(nolock) on hd_ctkey = ct_key
			left outer join resorts with(nolock) on hd_rskey = rs_key
			inner join #tempTourInfo on tt_tikey = ti_key
		where
			to_key = @tokey and TP_CalculatingKey = @calcKey
	end
	else
	begin
		insert into #tempPriceTable (
			[pt_mainplaces],
			[pt_addplaces],
			[pt_main],
			[pt_tourvalid],
			[pt_tourcreated],
			[pt_tourdate],
			[pt_days],
			[pt_nights],
			[pt_cnkey],
			[pt_ctkeyfrom],
			[pt_apkeyfrom],
			[pt_ctkeyto],
			[pt_apkeyto],
			[pt_ctkeybackfrom],
			[pt_ctkeybackto],
			[pt_tourkey],
			[pt_tourtype],
			[pt_tlkey],
			[pt_pricelistkey],
			[pt_pricekey],
			[pt_price],
			[pt_hdkey],
			[pt_hdpartnerkey],
			[pt_rskey],
			[pt_ctkey],
			[pt_hdstars],
			[pt_pnkey],
			[pt_hrkey],
			[pt_rmkey],
			[pt_rckey],
			[pt_ackey],
			[pt_childagefrom],
			[pt_childageto],
			[pt_childagefrom2],
			[pt_childageto2],
			[pt_hdname],
			[pt_tourname],
			[pt_pnname],
			[pt_pncode],
			[pt_rmname],
			[pt_rmcode],
			[pt_rcname],
			[pt_rccode],
			[pt_acname],
			[pt_accode],
			[pt_rsname],
			[pt_ctname],
			[pt_rmorder],
			[pt_rcorder],
			[pt_acorder],
			[pt_rate],
			[pt_toururl],
			[pt_hotelurl],
			[pt_isenabled],
			[pt_chkey],
			[pt_chbackkey],
			[pt_hdday],
			[pt_hdnights],
			[pt_chday],
			[pt_chpkkey],
			[pt_chprkey],
			[pt_chbackday],
			[pt_chbackpkkey],
			[pt_chbackprkey],
			pt_hotelkeys,
			pt_hotelroomkeys,
			pt_hotelstars,
			pt_pansionkeys,
			pt_hotelnights,
			pt_chdirectkeys,
			pt_chbackkeys,
			[pt_topricefor],
			pt_tlattribute,
			pt_hddetails,
			pt_directFlightAttribute,
			pt_backFlightAttribute
		)
		select
				(	case when @mwAccomodationPlaces = '0'
					then isnull(rm_nplaces, 0)
					else (	case when @findByAdultChild = 1 -- искать по взрослым
							then isnull(AC_NADMAIN, 0) + isnull(AC_NADEXTRA,0)
							-- искать по основным
							else isnull(AC_NADMAIN, 0) + isnull(AC_NCHMAIN, 0)
							end)
					end),
				(	case when isnull(ac_nmenexbed, -1) = -1
					then (	case when @mwRoomsExtraPlaces <> '0' 
							then isnull(rm_nplacesex, 0)
							else isnull(ac_nmenexbed, 0)
							end)
					else (	case when @findByAdultChild = 1 -- искать по детям
							then isnull(AC_NCHMAIN, 0) + isnull(AC_NCHEXTRA, 0)
							-- искать по дополнительным местам
							else isnull(AC_NADEXTRA, 0) + isnull(AC_NCHEXTRA, 0)
							end)
					end),
			hr_main, 
			to_datevalid, 
			to_datecreated, 
			td_date,
			ti_totaldays,
			ti_nights,
			to_cnkey, 
			isnull(ti_ctkeyfrom, 0), 
			ti_apkeyfrom,
			ti_ctkeyto, 
			ti_apkeyto, 
			null,
			null,
			to_key, 
			tl_tip,
			tl_key, 
			ti_key, 
			tp_key,
			tp_gross, 
			ti_firsthdkey, 
			ti_hdpartnerkey,
			hd_rskey, 
			hd_ctkey, 
			hd_stars, 
			ti_firstpnkey,
			ti_firsthrkey, 
			hr_rmkey, 
			hr_rckey, 
			hr_ackey,
			ac_agefrom, 
			ac_ageto, 
			ac_agefrom2,
			ac_ageto2, 
			hd_name, 
			substring(tl_nameweb,1,128), 
			pn_name, 
			pn_code, 
			rm_name, 
			rm_code,
			rc_name, 
			rc_code, 
			ac_name, 
			ac_code, 
			rs_name,
			ct_name, 
			rm_order, 
			rc_order, 
			ac_order,
			to_rate,
			tl_webhttp,
			hd_http, 
			@forceEnable,
			ti_chkey,
			ti_chbackkey,
			ti_hdday,
			ti_hdnights,
			ti_chday,
			ti_chpkkey,
			ti_chprkey,
			ti_chbackday,
			ti_chbackpkkey,
			ti_chbackprkey,
			ti_hotelkeys,
			ti_hotelroomkeys,
			ti_hotelstars,
			ti_pansionkeys,
			ti_hoteldays,
			tt_charterto,
			tt_charterback,
			to_pricefor,
			tl_attribute,
			tt_tourhotels,
			tt_directFlightAttribute,
			tt_backFlightAttribute
		from tp_tours with(nolock)
			inner join turList with(nolock) on to_trkey = tl_key
			inner join #tp_lists with(nolock) on ti_tokey = to_key
			inner join tp_prices with(nolock) on tp_tikey = ti_key
			inner join tp_turdates with(nolock) on (td_tokey = to_key and td_date between tp_datebegin and tp_dateend)
			inner join hoteldictionary with(nolock) on ti_firsthdkey = hd_key
			inner join hotelrooms with(nolock) on ti_firsthrkey = hr_key
			inner join pansion with(nolock) on ti_firstpnkey = pn_key
			inner join rooms with(nolock) on hr_rmkey = rm_key
			inner join roomscategory with(nolock) on hr_rckey = rc_key
			inner join accmdmentype with(nolock) on hr_ackey = ac_key
			inner join citydictionary with(nolock) on hd_ctkey = ct_key
			left outer join resorts with(nolock) on hd_rskey = rs_key
			inner join #tempTourInfo on tt_tikey = ti_key
		where
			to_key = @tokey and TP_TOKey = @tokey
	end	

	update dbo.TP_Tours set TO_Progress = 80 where TO_Key = @tokey

	if dbo.mwReplIsPublisher() <= 0
	begin
		insert into dbo.mwPriceDurations (
			sd_tourkey,
			sd_tlkey,
			sd_days,
			sd_nights,
			sd_hdnights
		)
		select distinct
			ti_tokey,
			to_trkey,
			ti_totaldays,
			ti_nights,
			ti_hoteldays
		from #tp_lists with(nolock) inner join tp_tours with(nolock) on ti_tokey = to_key

		-- Даты в поисковой таблице ставим как в таблице туров - чтобы не было двоений MEG00021274
		update mwspodatatable 
		set sd_tourcreated = to_datecreated 
		from tp_tours with(nolock)
		where sd_tourkey = to_key 		
			and to_key = @tokey
			and sd_tourcreated != to_datecreated 

		set @counter = -1
		set @deleteCount = 50000
		set @params = '@counterOut int output'

		-- Переписываем данные из временной таблицы и уничтожаем ее
		if @mwSearchType = 0
		begin
			while(@counter <> 0)
			begin
				if (@calcKey is not null)
					set @sql = 'delete top (' + ltrim(STR(@deleteCount)) +  ') from mwPriceDataTable where pt_pricekey in (select tp_key from tp_prices with(nolock) where TP_CalculatingKey = ' + cast(@calcKey as nvarchar(20)) + '); set @counterOut = @@ROWCOUNT'
				else
					set @sql = 'delete top(' + ltrim(STR(@deleteCount)) + ') from mwPriceDataTable where pt_tourkey = ' + cast(@tokey as nvarchar(20)) + ';set @counterOut = @@ROWCOUNT'
				EXECUTE sp_executesql @sql, @params, @counterOut = @counter output
			end
		
			exec dbo.mwFillPriceTable '#tempPriceTable', 0, 0
		end
		else
		begin			
			declare cur cursor fast_forward for select distinct thd_cnkey, isnull(thd_ctkeyfrom, 0) from #tmpHotelData
			open cur
			fetch next from cur into @countryKey, @cityFromKey
			while @@fetch_status = 0
			begin
				exec dbo.mwCreateNewPriceTable @countryKey, @cityFromKey

				set @counter = -1
				set @params = '@counterOut int output'
				while(@counter <> 0)
				begin
					if (@calcKey is not null)
						set @sql = 'delete top (' + ltrim(rtrim(str(@deleteCount)))  + ') from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' where pt_pricekey in (select tp_key from tp_prices with(nolock) where TP_CalculatingKey = ' + cast(@calcKey as nvarchar(20)) + '); set @counterOut = @@ROWCOUNT'
					else
						set @sql = 'delete top (' + ltrim(rtrim(str(@deleteCount))) + ') from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' where pt_tourkey = ' + cast(@tokey as nvarchar(20)) + '; set @counterOut = @@ROWCOUNT'
					EXECUTE sp_executesql @sql, @params, @counterOut = @counter output
				end

				exec dbo.mwFillPriceTable '#tempPriceTable', @countryKey, @cityFromKey

				exec dbo.mwCreatePriceTableIndexes @countryKey, @cityFromKey
				fetch next from cur into @countryKey, @cityFromKey
			end		
			close cur
			deallocate cur
		end
	end
	
	if dbo.mwReplIsPublisher() <= 0
	begin

		update dbo.TP_Tours set TO_Progress = 90 where TO_Key = @tokey

		insert into dbo.mwPriceHotels (
			sd_tourkey,
			sd_mainhdkey,
			sd_mainpnkey,
			sd_hdkey,
			sd_hdstars,
			sd_hdctkey,
			sd_hdrskey,
			sd_hrkey,
			sd_rmkey,
			sd_rckey,
			sd_ackey,
			sd_pnkey,
			sd_hdorder)
		select distinct 
			thd_tourkey, 
			thd_firsthdkey, 
			thd_firstpnkey,
			thd_hdkey, 
			thd_hdstars, 
			thd_ctkey, 
			thd_rskey, 
			thd_hrkey, 
			thd_rmkey, 
			thd_rckey, 
			thd_ackey, 
			thd_pnkey,
			thd_hdorder
		from #tmpHotelData

		-- информация об отелях
		insert into mwSpoDataTable (
			sd_tourkey, 
			sd_cnkey, 
			sd_hdkey, 
			sd_hdstars, 
			sd_ctkey, 
			sd_rskey, 
			sd_ctkeyfrom, 
			sd_ctkeyto, 
			sd_tlkey, 
			sd_isenabled, 
			sd_tourcreated,
			sd_main,
			sd_pnkey,
			sd_tourtype,
			sd_cnname,
			sd_tourname,
			sd_hdname,
			sd_ctname,
			sd_rsname,
			sd_ctfromname,
			sd_cttoname,
			sd_tourtypename,
			sd_pncode,
			sd_hotelkeys,
			sd_pansionkeys,
			sd_tourvalid,

			sd_hotelurl,
			sd_hdprkey
		) 
		select distinct 
			thd_tourkey, 
			thd_cnkey, 
			thd_hdkey, 
			thd_hdstars, 
			thd_ctkey, 
			thd_rskey, 
			thd_ctkeyfrom, 
			thd_ctkeyto, 
			thd_tlkey, 
			thd_isenabled, 
			thd_tourcreated,
			thd_hdmain,
			thd_pnkey,
			thd_tourtype,
			thd_cnname,
			thd_tourname,
			thd_hdname,
			thd_ctname,
			thd_rsname,
			thd_ctfromname,
			thd_cttoname,
			thd_tourtypename,
			thd_pncode,
			thd_hotelkeys,
			thd_pansionkeys,
			thd_tourvalid,
			thd_hotelurl,
			thd_hdpartnerkey
		from #tmpHotelData 
		where thd_hdmain > 0

		update mwPriceHotels set ph_sdkey = mwsdt.sd_key
			from mwSpoDataTable mwsdt with(nolock)
			where mwsdt.sd_tourkey = mwPriceHotels.sd_tourkey and mwsdt.sd_hdkey = mwPriceHotels.sd_mainhdkey
				and mwsdt.sd_tourkey = @tokey
				and mwPriceHotels.sd_tourkey = @tokey

		-- Указываем на необходимость обновления в таблице минимальных цен отеля
		update mwHotelDetails 
			set htd_needupdate = 1
			where htd_hdkey in (select thd_hdkey from #tmpHotelData)
			
	end
	
	if dbo.mwReplIsSubscriber() > 0
	begin
		while 1=1
		begin
			delete top (10000) from TP_Prices where tp_tokey = @tokey
			if @@rowcount = 0
				break
		end
	
		while 1=1
		begin
			delete top (10000) from TP_ServiceLists where tl_tokey = @tokey
			if @@rowcount = 0
				break
		end
		
		while 1=1
		begin
			delete top (10000) from TP_Services where ts_tokey = @tokey
			if @@rowcount = 0
				break
		end
		
		while 1=1
		begin
			delete top (10000) from TP_Lists where ti_tokey = @tokey
			if @@rowcount = 0
				break
		end
		-- don't delete from TP_Tours	
	end
	else
	begin
		update tp_lists
		set
			ti_firsthdkey = ti.ti_firsthdkey,
			ti_lasthotelday = ti.ti_lasthotelday,			
			ti_nights = ti.ti_nights,
			ti_hotelkeys = ti.ti_hotelkeys,
			ti_hotelroomkeys = ti.ti_hotelroomkeys,
			ti_hoteldays = ti.ti_hoteldays,
			ti_hotelstars = ti.ti_hotelstars,
			ti_pansionkeys = ti.ti_pansionkeys,
			ti_hdpartnerkey = ti.ti_hdpartnerkey,
			ti_firsthotelpartnerkey = ti.ti_firsthotelpartnerkey,
			ti_hdday = ti.ti_hdday,
			ti_hdnights = ti.ti_hdnights,
			ti_chkey = ti.ti_chkey,
			ti_chday = ti.ti_chday,
			ti_chpkkey = ti.ti_chpkkey,
			ti_chprkey = ti.ti_chprkey,
			ti_ctkeyfrom = ti.ti_ctkeyfrom,
			ti_chbackkey = ti.ti_chbackkey,
			ti_chbackday = ti.ti_chbackday,
			ti_chbackpkkey = ti.ti_chbackpkkey,
			ti_chbackprkey = ti.ti_chbackprkey,
			ti_ctkeyto = ti.ti_ctkeyto,
			ti_apkeyfrom = ti.ti_apkeyfrom,
			ti_apkeyto = ti.ti_apkeyto,
			ti_firstctkey = ti.ti_firstctkey,
			ti_firstrskey = ti.ti_firstrskey,
			ti_firsthdstars = ti.ti_firsthdstars
		from #tp_lists ti
		where
			tp_lists.TI_Key = ti.TI_Key
			and
			(
				isnull(tp_lists.ti_firsthdkey, 0) <> isnull(ti.ti_firsthdkey , 0)
				or isnull(tp_lists.ti_lasthotelday, 0) <> isnull(ti.ti_lasthotelday, 0)
				or isnull(tp_lists.ti_nights, 0) <> isnull(ti.ti_nights, 0)
				or isnull(tp_lists.ti_hotelkeys, 0) <> isnull(ti.ti_hotelkeys, 0)
				or isnull(tp_lists.ti_hotelroomkeys, 0) <> isnull(ti.ti_hotelroomkeys, 0)
				or isnull(tp_lists.ti_hoteldays, 0) <> isnull(ti.ti_hoteldays, 0)
				or isnull(tp_lists.ti_hotelstars, 0) <> isnull(ti.ti_hotelstars, 0)
				or isnull(tp_lists.ti_pansionkeys, 0) <> isnull(ti.ti_pansionkeys, 0)
				or isnull(tp_lists.ti_hdpartnerkey, 0) <> isnull(ti.ti_hdpartnerkey, 0)
				or isnull(tp_lists.ti_firsthotelpartnerkey, 0) <> isnull(ti.ti_firsthotelpartnerkey, 0)
				or isnull(tp_lists.ti_hdday, 0) <> isnull(ti.ti_hdday, 0)
				or isnull(tp_lists.ti_hdnights, 0) <> isnull(ti.ti_hdnights, 0)
				or isnull(tp_lists.ti_chkey, 0) <> isnull(ti.ti_chkey, 0)
				or isnull(tp_lists.ti_chday, 0) <> isnull(ti.ti_chday, 0)
				or isnull(tp_lists.ti_chpkkey, 0) <> isnull(ti.ti_chpkkey, 0)
				or isnull(tp_lists.ti_chprkey, 0) <> isnull(ti.ti_chprkey, 0)
				or isnull(tp_lists.ti_ctkeyfrom, 0) <> isnull(ti.ti_ctkeyfrom, 0)
				or isnull(tp_lists.ti_chbackkey, 0) <> isnull(ti.ti_chbackkey, 0)
				or isnull(tp_lists.ti_chbackday, 0) <> isnull(ti.ti_chbackday, 0)
				or isnull(tp_lists.ti_chbackpkkey, 0) <> isnull(ti.ti_chbackpkkey, 0)
				or isnull(tp_lists.ti_chbackprkey, 0) <> isnull(ti.ti_chbackprkey, 0)
				or isnull(tp_lists.ti_ctkeyto, 0) <> isnull(ti.ti_ctkeyto, 0)
				or isnull(tp_lists.ti_apkeyfrom, 0) <> isnull(ti.ti_apkeyfrom, 0)
				or isnull(tp_lists.ti_apkeyto, 0) <> isnull(ti.ti_apkeyto, 0)
				or isnull(tp_lists.ti_firstctkey, 0) <> isnull(ti.ti_firstctkey, 0)
				or isnull(tp_lists.ti_firstrskey, 0) <> isnull(ti.ti_firstrskey, 0)
				or isnull(tp_lists.ti_firsthdstars, 0) <> isnull(ti.ti_firsthdstars, 0)
			)
	end

	if(@forceEnable > 0 and @calcKey is null)
	begin
		exec mwEnablePriceTourNewSinglePrice @tokey, '#tempPriceTable'

		update tp_tours
		set to_isenabled = 1
		where to_key = @tokey
	end

	drop table #tempPriceTable

	update dbo.TP_Tours
	set TO_Update = 0,
		TO_Progress = 100,
		TO_DateCreated = GetDate()
	where
		TO_Key = @tokey

	if dbo.mwReplIsSubscriber() <= 0
	begin
		update dbo.TP_Tours 
		set TO_UpdateTime = GetDate()
		where
			TO_Key = @tokey
	end

	EXECUTE mwFillPriceListDetails @tokey

end
GO

GRANT EXEC on [dbo].[FillMasterWebSearchFields] to public
GO
/*********************************************************************/
/* end sp_FillMasterWebSearchFields.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetCalendarTourDates.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetCalendarTourDates]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[GetCalendarTourDates]
END
GO

--<VERSION>9.2.20.12</VERSION>
--<DATE>2014-04-09</DATE>
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
	SELECT @mwSearchType = LTRIM(RTRIM(ISNULL(SS_ParmValue, ''))) FROM dbo.SystemSettings 
		WHERE SS_ParmName = 'MWDivideByCountry'
	
	DECLARE @tableName NVARCHAR(100)
	IF (@mwSearchType = 0)
	BEGIN
		SET @tableName = 'dbo.mwPriceDataTable'
	END
	ELSE
	BEGIN
		SET @tableName = dbo.mwGetPriceTableName(@countryKeys, @departFromKeys)
	END

	DECLARE @exceptNoPlacesAviaQuota INT
	SELECT @exceptNoPlacesAviaQuota = LTRIM(RTRIM(ISNULL(SS_ParmValue, ''))) FROM dbo.SystemSettings
		WHERE SS_ParmName = 'ExceptTourDatesWithNoAQ'

	-- Исключение дат, на которые заведены квоты на перелет, но мест в квоте нет
	DECLARE @quotaNeedFromPart NVARCHAR(2000)
	DECLARE @quotaNeedWherePart NVARCHAR(100)
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
				WHERE QO_CNKey IN (' + @countryKeys + ') AND CH_CITYKEYFROM IN (' + @departFromKeys + ') AND
					((QD_Places - QD_Busy) = 0
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

	DECLARE @tempTableIfNeed NVARCHAR(100)
	IF (@tourKeys IS NOT NULL)
		SET @tempTableIfNeed = 'INTO #CalendarTourDates'
	ELSE
		SET @tempTableIfNeed = ''

	DECLARE @sql NVARCHAR(MAX)
	SET @sql = 'SELECT DISTINCT DATEDIFF(ss, ''1970-01-01'', TP_TurDates.TD_Date) AS [key],
					CONVERT(varchar, TP_TurDates.TD_Date, 4) AS name,
					TP_TurDates.TD_Date ' + @tempTableIfNeed + '
				FROM TP_TurDates 
					INNER JOIN mwSpoData with(nolock) ON TP_TurDates.TD_TOKey = mwSpoData.sd_tourkey ' +
				@quotaNeedFromPart + 
				'WHERE TP_TurDates.TD_Date > DATEADD(day, - 1, GETDATE())
					AND mwSpoData.sd_ctkeyfrom IN (' + @departFromKeys + ')
					AND mwSpoData.sd_cnkey IN (' + @countryKeys + ')' +
				@quotaNeedWherePart
             
	IF (@resortKeys IS NOT NULL)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_rskey IN (' + @resortKeys + ')'
	END

	if (@tourTypeKeys IS NOT NULL)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourtype IN (' + @tourTypeKeys + ')'
	END

	if (@cityKeys IS NOT NULL)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_ctkey IN (' + @cityKeys + ')'
	END
    
	IF (@tourKeys IS NOT NULL)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourkey IN (' + @tourKeys + ') 
		SELECT * FROM #CalendarTourDates 
		WHERE exists(SELECT TOP 1 1 FROM ' + @tableName + ' WHERE pt_tourkey IN (' + @tourKeys + ') AND pt_tourdate = TD_Date) 
		ORDER BY TD_Date'
	END
	ELSE
	BEGIN
		SET @sql += ' ORDER BY TP_TurDates.TD_Date '
	END

	EXEC sp_executesql @sql
END

GO

grant exec on [dbo].[GetCalendarTourDates] to public
GO
/*********************************************************************/
/* end sp_GetCalendarTourDates.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetQuotaLoadListData_N.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetQuotaLoadListData_N]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetQuotaLoadListData_N]
GO


CREATE procedure [dbo].[GetQuotaLoadListData_N]
(
--<VERSION>2009.2.31</VERSION>
--<DATE>2014-04-07</DATE>
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
				and ((QO_SubCode2 = -1) or (QO_SubCode2 in (0,@Object_SubCode2)) or (@Object_SubCode2=0 and @Service_SVKey=8))))
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
/* begin sp_MarginMonitor_PriceFilter.sql */
/*********************************************************************/
SET QUOTED_IDENTIFIER ON
GO

--реализация основных фильтров Маржинального монитора
--<version>2009.18.2</version>
--<data>2014-04-17</data>
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MarginMonitor_PriceFilter]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[MarginMonitor_PriceFilter]
GO
CREATE PROCEDURE [dbo].[MarginMonitor_PriceFilter]
(
	@tourDates                    XML ([dbo].[ArrayOfDateTime]),      -- даты туров
	@hotelKeys                    XML ([dbo].[ArrayOfInt]),			  -- ключи отелей
	@roomCategoryKeys             XML ([dbo].[ArrayOfInt]) = NULL,	  -- ключи категорий комнат
	@pansionKeys                  XML ([dbo].[ArrayOfInt]) = NULL,	  -- ключи питаний
	@longList                     XML ([dbo].[ArrayOfInt]) = NULL,	  -- продолжительности
	@countryKey                   INT,                                -- страна
	@departCityKey                INT = NULL,                         -- город вылета
	@targetFlyCityKey             INT,                                -- город прилета
	@targetCitiesKeys             XML ([dbo].[ArrayOfInt]),           -- список городов проживания
	@priceMin                     MONEY = NULL,                       -- минимальная стоимость тура
	@priceMax                     MONEY = NULL,                       -- максимальная стоимость тура
	@isDeletedPriceOnly           BIT   = NULL,                       -- только снятые цены
	@isMinPrice                   BIT   = NULL,                       -- по минимальным ценам
	@isOnlineOnly                 BIT   = NULL,                       -- только выставленные в интернет туры
	@isModifyPriceOnly            BIT   = NULL,                       -- только измененные цены
	@isAllotment                  BIT   = NULL,                       -- для отелей по квотам элотмент
	@isCommitment                 BIT   = NULL,                       -- для отелей по квотам коммитмент
	@accmdDefaultKey              INT   = NULL,                       -- тип размещения по умолчанию
	@roomTypeDefaultKey           INT   = NULL,                       -- тип комнаты по умолчанию
	@isOnlyActualTourDates        BIT   = 1,                          -- 1-отбор по датам не ниже текущей    0-отбор по всем переданным датам
	@isAccommodationWithAdult     BIT   = 1,                          -- только размещения без доп. мест
	@isWholeHotel                 BIT   = 1,                          -- 1 - поиск по всему отелю, 0 - по категориям номеров
	@priceKeys                    XML ([dbo].[ArrayOfLong]) = NULL	  -- ключи уже отобранных цен (для работы кнопки "Применить фильтр к отобранным турам")
) AS BEGIN

SET ARITHABORT ON;
SET DATEFIRST 1;
SET NOCOUNT ON;

DECLARE @beginTime DATETIME, @debug varchar(255)

CREATE TABLE #tourDatesTable (tourDate DATETIME)
INSERT INTO #tourDatesTable (tourDate)
SELECT tbl.res.value('.', 'datetime')
FROM @tourDates.nodes('/ArrayOfDateTime/dateTime') AS tbl(res)
CREATE INDEX IX_tourDatesTable
ON #tourDatesTable(tourDate)

IF @isOnlyActualTourDates = 1
BEGIN
	DELETE #tourDatesTable
	WHERE tourDate < CONVERT(datetime, dateadd(day, -1, GETDATE()))
END

CREATE TABLE #targetCitiesKeysTable(cityKey INT)
INSERT INTO #targetCitiesKeysTable (cityKey)
SELECT tbl.res.value('.', 'int')
FROM @targetCitiesKeys.nodes('/ArrayOfInt/int') AS tbl(res)
CREATE INDEX IX_targetCitiesKeysTable
ON #targetCitiesKeysTable(cityKey)

CREATE TABLE #hotelKeysTable (hotelKey INT)
INSERT INTO #hotelKeysTable (hotelKey)
SELECT tbl.res.value('.', 'int')
FROM @hotelKeys.nodes('/ArrayOfInt/int') AS tbl(res)
CREATE INDEX IX_hotelKeysTable
ON #hotelKeysTable(hotelKey)

create table #tourKeysTable (tourKey int)
insert into #tourKeysTable (tourKey)
select distinct TI_TOKey 
from TP_Lists with(nolock) 
where ti_firsthdkey in (select hotelKey from #hotelKeysTable)
CREATE INDEX IX_tourKeysTable
ON #tourKeysTable(tourKey)

CREATE TABLE #roomCategoryKeysTable (rcKey INT)
INSERT INTO #roomCategoryKeysTable (rcKey)
SELECT tbl.res.value('.', 'int')
FROM @roomCategoryKeys.nodes('/ArrayOfInt/int') AS tbl(res)
CREATE INDEX IX_roomCategoryKeysTable
ON #roomCategoryKeysTable(rcKey)

CREATE TABLE #pansionKeysTable(pansionKey INT)
INSERT INTO #pansionKeysTable(pansionKey)
SELECT tbl.res.value('.', 'int')
FROM @pansionKeys.nodes('/ArrayOfInt/int') AS tbl(res)
CREATE INDEX IX_pansionKeysTable
ON #pansionKeysTable(pansionKey)

CREATE TABLE #longListTable (longValue SMALLINT)
INSERT INTO #longListTable (longValue)
SELECT tbl.res.value('.', 'int')
FROM @longList.nodes('/ArrayOfInt/int') AS tbl(res)
CREATE INDEX IX_longListTable
ON #longListTable(longValue)

CREATE TABLE #priceKeysTable  (priceKey BIGINT)
INSERT INTO #priceKeysTable(priceKey)
SELECT tbl.res.value('.', 'bigint')
FROM @priceKeys.nodes('/ArrayOfLong/long') AS tbl(res)
CREATE INDEX IX_priceKeysTable
ON #priceKeysTable(priceKey)

SELECT AC_KEY 
into #AccomType
FROM Accmdmentype WHERE (ISNULL(AC_NADMAIN, 0) > 0) AND (ISNULL(AC_NCHMAIN, 0) = 0) AND (ISNULL(AC_NCHISINFMAIN, 0) = 0)
CREATE INDEX IX_AccomType
ON #AccomType(AC_KEY)

-- прямые и обратные перелеты
CREATE TABLE #chartersTable 
(
	xCityFrom INT,
	xCityTo INT,
	xCH_Key BIGINT,
	xCharterDate DATETIME,
	xTS_PKKey BIGINT,
	xTS_SubCode1 BIGINT,
	xBusyPlaces INT,
	xTotalPlaces INT
)

-- выборка прямых и обратных перелетов
SET @beginTime = GETDATE()

INSERT INTO #chartersTable(xCityFrom, xCityTo, xCH_Key, xCharterDate, xTS_PKKey, xTS_SubCode1)
select distinct TF_SubCode2, TF_CTKey, TF_CodeNew, TF_Date, TF_PKKey, TF_SubCode1New
from TP_Flights with(nolock)
where TF_TourDate in (SELECT tourDate FROM #tourDatesTable)
and ((TF_Date = TF_TourDate and TF_CTKey = @targetFlyCityKey and TF_SubCode2 = @departCityKey) or (TF_Date <> TF_TourDate and TF_CTKey = @departCityKey and TF_SubCode2 = @targetFlyCityKey))
and TF_SubCode1New is not null
and TF_CodeNew is not null

--SELECT DISTINCT
--	TS_SubCode2, TS_CTKey, TS_Code,
--	case TS_Day when 1 then TD_Date else TD_Date + TI_Days - 1 end,
--	TS_OpPacketKey, TS_SubCode1
--FROM TP_Lists WITH(NOLOCK)
--JOIN TP_TurDates WITH(NOLOCK) ON TI_TOKey = TD_TOKey
--JOIN TP_Services WITH(NOLOCK) ON TS_TOKey = TI_TOKey AND TS_SVKey = 1
--WHERE
--	(TD_Date IN (SELECT tourDate FROM @tourDatesTable)) AND
--	(((TS_Day = 1) AND (TS_CTKey = @targetFlyCityKey) AND (TS_SubCode2 = @departCityKey)) OR
--	 ((TS_Day = TI_Days) AND (TS_CTKey = @departCityKey) AND (TS_SubCode2 = @targetFlyCityKey))
--	)

PRINT 'грузим прямые перелеты: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
set @debug = 'грузим прямые перелеты: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
insert into Debug (db_Date, db_Mod, db_Text)
values(GETDATE(), 'MM', substring(@debug, 0, 255))

SET @beginTime = GETDATE()

-- дополнительные перелеты
CREATE TABLE #addChartersTable 
(
	xCH_Key BIGINT,
	xAddChKey BIGINT,
	xCharterDate DATETIME,
	xTS_SubCode1 BIGINT,
	xTS_PKKey BIGINT,
	xAddFlight VARCHAR(4),
	xAddAirlineCode VARCHAR(3),
	xOrder INT DEFAULT 1,
	xAS_Week VARCHAR(7),
	xAS_TimeFrom DATETIME
)

CREATE INDEX IX_addChartersTable
ON #addChartersTable(xCH_Key, xCharterDate, xTS_SubCode1, xTS_PKKey,xAS_Week)
INCLUDE (xAddFlight,xAddAirlineCode,xOrder);

INSERT INTO #addChartersTable(xCH_Key, xAddChKey, xCharterDate, xTS_SubCode1, xTS_PKKey, xAddFlight, xAddAirlineCode, xAS_Week, xAS_TimeFrom)
SELECT DISTINCT ct.xCH_Key, CH_Key, xCharterDate, xTS_SubCode1, xTS_PKKey, CH_FLIGHT, CH_AIRLINECODE, AS_WEEK, AS_TimeFrom
FROM AirSeason WITH(NOLOCK), Charter WITH(NOLOCK), Costs WITH(NOLOCK), #chartersTable ct
WHERE
	CH_CityKeyFrom = ct.xCityFrom AND
	CH_CityKeyTo = ct.xCityTo AND
	CS_Code = CH_Key AND
	AS_CHKey = CH_Key AND
	CS_SVKey = 1 AND
	(ISNULL((SELECT TOP 1 AS_GROUP FROM AIRSERVICE WITH(NOLOCK) WHERE AS_KEY = CS_SubCode1), '')
	 =
	 ISNULL((SELECT TOP 1 AS_GROUP FROM AIRSERVICE WITH(NOLOCK) WHERE AS_KEY = ct.xTS_SubCode1), '')
	) AND
	CS_PKKey = xTS_PKKey AND
	ct.xCharterDate BETWEEN AS_DateFrom AND AS_DateTo AND
	ct.xCharterDate BETWEEN CS_Date AND CS_DateEnd AND
	AS_Week LIKE '%'+CAST(DATEPART(WEEKDAY, ct.xCharterDate)AS VARCHAR(1))+'%' AND
	(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+CAST(DATEPART(WEEKDAY, ct.xCharterDate) AS VARCHAR(1))+'%')

-- чтобы рейс, с которым был рассчитан тур, был первым
UPDATE #addChartersTable SET xOrder = 0 WHERE xCH_Key = xAddChKey

CREATE TABLE #addChartersTableString 
(
	xCH_Key bigint,                 -- исходный перелет
	xAddChKeyString nvarchar(max),  -- список доп. перелетов через запятую (включая исходный)
	xCharterDate datetime,
	xTS_SubCode1 bigint,
	xTS_PKKey bigint,
	xAS_Week varchar(7),
	xAS_TimeFrom nvarchar(max)
)

CREATE INDEX IX_addChartersTableString
ON #addChartersTableString(xCH_Key, xCharterDate, xTS_SubCode1, xTS_PKKey)
INCLUDE (xAddChKeyString, xAS_Week, xAS_TimeFrom);

-- все доп. перелеты соединяем через запятую в одну строку
insert into #addChartersTableString(xCH_Key, xCharterDate, xTS_SubCode1, xTS_PKKey, xAS_Week, xAddChKeyString, xAS_TimeFrom)
select distinct t1.xCH_Key, t1.xCharterDate, t1.xTS_SubCode1, t1.xTS_PKKey,
	-- xAS_Week
	(select top 1 xAS_Week
	from #addChartersTable t2
	where (t2.xCH_Key = t1.xCH_Key) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
	order by len(xAS_Week) - len(replace(xAS_Week, '.', '')) desc),
 	-- xAddAirlineCode + xAddFlight
	(select xAddAirlineCode + xAddFlight + ', '
    from #addChartersTable t2
    where (t2.xCH_Key = t1.xCH_Key) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
    order by xOrder asc, xAddAirlineCode + xAddFlight asc
    for xml path('')),
    -- xAS_TimeFrom
    (select SUBSTRING(CONVERT(VARCHAR(8), xAS_TimeFrom, 108),0,6) + ', '
    from #addChartersTable t2
    where (t2.xCH_Key = t1.xCH_Key) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
    order by xOrder asc, xAddAirlineCode + xAddFlight asc
    for xml path(''))
from #addChartersTable t1

-- избавляемся от хвостовых запятых
update #addChartersTableString
set xAddChKeyString = LEFT(xAddChKeyString, LEN(xAddChKeyString) - 1),
    xAS_TimeFrom = LEFT(xAS_TimeFrom, LEN(xAS_TimeFrom) - 1)

UPDATE #chartersTable
SET xTotalPlaces = q.TotalPlaces, xBusyPlaces = q.BusyPlaces
FROM
   (SELECT ct.xCH_Key AS CH_Key, ct.xCharterDate AS CharterDate, SUM(QP_Places) AS TotalPlaces, SUM(QP_Busy) AS BusyPlaces
	FROM #chartersTable ct, QuotaDetails
	JOIN QuotaParts WITH(NOLOCK) ON QP_QDID = QD_ID
	JOIN QuotaObjects WITH(NOLOCK) ON QO_QTID = QD_QTID
	WHERE
		(QO_SVKey = 1) AND
		(QO_SubCode1 = ct.xTS_SubCode1) AND
		(QD_Date = ct.xCharterDate) AND
		(ISNULL(QP_IsDeleted,0) = 0) AND
		(ISNULL(QP_AgentKey,0) = 0) AND
		 QO_Code IN (SELECT act.xAddChKey FROM #addChartersTable act
					 WHERE (act.xCharterDate = ct.xCharterDate) AND
						   (act.xCH_Key = ct.xCH_Key) AND
						   (act.xTS_PKKey = ct.xTS_PKKey) AND
						   (act.xTS_SubCode1 = ct.xTS_SubCode1))
	GROUP BY ct.xCH_Key, ct.xCharterDate) AS q
WHERE xCH_Key = q.CH_Key AND xCharterDate = CharterDate

PRINT 'подбираем подходящие перелеты: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
set @debug = 'подбираем подходящие перелеты: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
insert into Debug (db_Date, db_Mod, db_Text)
values(GETDATE(), 'MM', substring(@debug, 0, 255))

--SELECT * from @chartersTable
--SELECT * from @addChartersTable
--SELECT * from @addChartersTableString

CREATE TABLE #tmpPriceTable 
(
	xTP_Key INT,
	xTP_TOKey INT,
	xTP_DateBegin DATETIME,
	xTP_Gross MONEY,
	xTP_TIKey INT,
	xCH_Key INT,
	xCH_TSOpPacketKey INT,
	xCH_TSSubCode1 INT
)

CREATE INDEX IX_tmpPriceTable
ON #tmpPriceTable(xTP_TOKey, xTP_TIKey, xCH_Key, xCH_TSOpPacketKey, xCH_TSSubCode1)
INCLUDE (xTP_Key, xTP_DateBegin, xTP_Gross);

-- только снятые цены
IF (ISNULL(@isDeletedPriceOnly, 0) = 0) BEGIN
	INSERT INTO #tmpPriceTable(xTP_Key, xTP_TOKey, xTP_DateBegin, xTP_Gross, xTP_TIKey, xCH_Key, xCH_TSOpPacketKey, xCH_TSSubCode1)
	SELECT TP_Key, TP_TOKey, TP_DateBegin, TP_Gross, TP_TIKey, TS_Code, TS_OpPacketKey, TS_SubCode1
	FROM TP_Prices WITH(NOLOCK)
	JOIN TP_Lists WITH(NOLOCK) ON TP_TIKey = TI_Key
	JOIN TP_ServiceLists WITH(NOLOCK) ON TI_Key = TL_TIKey
	LEFT JOIN TP_Services WITH(NOLOCK) ON TL_TSKey = TS_Key AND TS_SVKey = 1 AND TS_Day = 1
	WHERE
		(TP_DateBegin IN (SELECT tourDate FROM #tourDatesTable)) AND
		(TI_FirstHDKey IN (SELECT hotelKey FROM #hotelKeysTable)) AND
		(TI_FirstCTKey IN (SELECT cityKey FROM #targetCitiesKeysTable)) AND
		((@targetFlyCityKey != -1 AND TS_CTKey = @targetFlyCityKey AND TS_SubCode2 = @departCityKey)
		  OR
		 (@targetFlyCityKey = -1 AND TS_Key IS NULL)) AND
		 -- отсев по продолжительностям
		(@longList IS NULL OR TI_DAYS IN (SELECT longValue FROM #longListTable))
		and TI_TOKey in (select tourKey from #tourKeysTable)
		and TP_TOKey in (select tourKey from #tourKeysTable)
END


IF ISNULL(@isOnlineOnly,0) = 0 BEGIN
	INSERT INTO #tmpPriceTable(xTP_Key, xTP_TOKey, xTP_DateBegin, xTP_Gross, xTP_TIKey, xCH_Key, xCH_TSOpPacketKey, xCH_TSSubCode1)
	SELECT TPD_TPKey, TPD_TOKey, TPD_DateBegin, null, TPD_TIKey, TS_Code, TS_OpPacketKey, TS_SubCode1
	FROM TP_PricesDeleted WITH(NOLOCK)
	JOIN TP_Lists WITH(NOLOCK) ON TPD_TIKey = TI_Key
	JOIN TP_ServiceLists WITH(NOLOCK) ON TI_Key = TL_TIKey
	LEFT JOIN TP_Services WITH(NOLOCK) ON TL_TSKey = TS_Key AND TS_SVKey = 1 AND TS_Day = 1
	WHERE
		(TPD_DateBegin IN (SELECT tourDate FROM #tourDatesTable)) AND
		(TI_FirstHDKey IN (SELECT hotelKey FROM #hotelKeysTable)) AND
		(TI_FirstCTKey IN (SELECT cityKey FROM #targetCitiesKeysTable)) AND
		((@targetFlyCityKey != -1 AND TS_CTKey = @targetFlyCityKey AND TS_SubCode2 = @departCityKey)
		  OR
		 (@targetFlyCityKey = -1 AND TS_Key IS NULL)) AND
		 -- отсев по продолжительностям
		(@longList IS NULL OR TI_DAYS IN (SELECT longValue FROM #longListTable))
		and TPD_TOKey in (select tourKey from #tourKeysTable)
END


CREATE TABLE #prices 
(
	TourOldPrice                MONEY,
	TR_Key                      INT,
	TP_Key                      INT,
	IsOnline                    BIT,
	TourName                    NVARCHAR(MAX),
	TourDate                    DATETIME,
	TourDays                    SMALLINT,
	HotelDays                   SMALLINT,
	AccommodationKey            INT,
	AccommodationName           NVARCHAR(MAX),
	RoomKey                     INT,
	HotelCityName               NVARCHAR(MAX),
	HotelKey                    INT,
	HotelName                   NVARCHAR(MAX),
	HotelRoomKey                INT,
	RoomName                    NVARCHAR(MAX),
	RoomCategoryKey             INT,
	RoomCategoryName            NVARCHAR(MAX),
	PansionKey                  INT,
	PansionName                 NVARCHAR(MAX),
	PansionCode                 VARCHAR(100),
	PartnerKey                  INT,
	Mens                        SMALLINT,
	Airport                     VARCHAR(100),
	Charters                    NVARCHAR(MAX),
	FlightDays                  VARCHAR(7),
	FlightTime                  NVARCHAR(MAX),
	CharterBusyPlaces           INT,
	CharterTotalPlaces          INT,
	CharterUnsolidBackPlaces    INT,
	AllotmentDaysCount          INT,
	CommitmentDaysCount         INT,
	HotelAllPlaces              INT,
	HotelBusyPlaces             INT,
	HotelCommitmentPlaces       INT,
	StopSale                    BIT
)

SET @beginTime = GETDATE()

INSERT INTO #prices
(
	TourOldPrice,
	TR_Key,
	TP_Key,
	IsOnline,
	TourName,
	TourDate,
	TourDays,
	HotelDays,
	AccommodationKey,
	AccommodationName,
	RoomKey,
	HotelCityName,
	HotelKey,
	HotelName,
	HotelRoomKey,
	RoomName,
	RoomCategoryKey,
	RoomCategoryName,
	PansionKey,
	PansionName,
	PansionCode,
	PartnerKey,
	Mens,
	Airport,
	Charters,
	FlightDays,
	FlightTime,
	CharterBusyPlaces,
	CharterTotalPlaces,
	CharterUnsolidBackPlaces,
	AllotmentDaysCount,
	CommitmentDaysCount,
	HotelAllPlaces,
	HotelBusyPlaces,
	HotelCommitmentPlaces,
	StopSale
)
SELECT DISTINCT
	pr.xTP_Gross AS TourOldPrice,
	TO_TRKey AS TR_Key,
	pr.xTP_Key AS TP_Key,
	TO_IsEnabled AS IsOnline,
	TO_Name AS TourName,
	pr.xTP_DateBegin AS TourDate,
	lst.TI_DAYS AS TourDays,
	hs.TS_Days AS HotelDays,
	hr.HR_ACKEY AS AccommodationKey,
	ac.AC_CODE AS AccommodationName,
	hr.HR_RMKEY AS RoomKey,
	ct.CT_NAME AS HotelCityName,
	lst.TI_FirstHDKey AS HotelKey,
	hd.HD_NAME AS HotelName,
	hs.TS_SubCode1 AS HotelRoomKey,
	rm.RM_NAME AS RoomName,
	hr.HR_RCKEY AS RoomCategoryKey,
	rc.RC_Name AS RoomCategoryName,
	lst.TI_FirstPNKey AS PansionKey,
	pn.PN_Name AS PansionName,
	pn.PN_Code AS PansionCode,
	hs.TS_OpPartnerKey AS PartnerKey,
	hs.TS_Men AS Mens,
	-- CharterPortCodeFrom
	(SELECT TOP 1 CH_PortCodeFrom FROM Charter WHERE CH_Key = pr.xCH_Key)
	AS Airport,
	-- Charters
	(SELECT TOP 1 xAddChKeyString FROM #addChartersTableString act
	 WHERE (act.xCharterDate = pr.xTP_DateBegin) and (act.xCH_Key = pr.xCH_Key) and (act.xTS_PKKey = pr.xCH_TSOpPacketKey) and (act.xTS_SubCode1 = pr.xCH_TSSubCode1))
	AS Charters,
	-- FlightDays
	(SELECT TOP 1 xAS_Week FROM #addChartersTableString act
	 WHERE (act.xCharterDate = pr.xTP_DateBegin) and (act.xCH_Key = pr.xCH_Key) and (act.xTS_PKKey = pr.xCH_TSOpPacketKey) and (act.xTS_SubCode1 = pr.xCH_TSSubCode1))
	AS FlightDays,
	-- FlightTime
	(SELECT TOP 1 xAS_TimeFrom FROM #addChartersTableString act
	 WHERE (act.xCharterDate = pr.xTP_DateBegin) and (act.xCH_Key = pr.xCH_Key) and (act.xTS_PKKey = pr.xCH_TSOpPacketKey) and (act.xTS_SubCode1 = pr.xCH_TSSubCode1))
	AS FlightTime,
	-- CharterBusyPlaces
	--(SELECT TOP 1 xBusyPlaces FROM @chartersTable
	--WHERE (xCharterDate = pr.xTP_DateBegin) AND (xTS_PKKey = pr.xCH_TSOpPacketKey) AND (xTS_SubCode1 = pr.xCH_TSSubCode1))
	NULL AS CharterBusyPlaces,
	-- CharterTotalPlaces
	--(SELECT TOP 1 xTotalPlaces FROM @chartersTable
	--WHERE (xCharterDate = pr.xTP_DateBegin) AND (xTS_PKKey = pr.xCH_TSOpPacketKey) AND (xTS_SubCode1 = pr.xCH_TSSubCode1))
	null AS CharterTotalPlaces,
	-- CharterUnsolidBackPlaces
	--(SELECT TOP 1 (xTotalPlaces - xBusyPlaces) FROM @chartersTable
	--WHERE (xCharterDate = pr.xTP_DateBegin + lst.TI_Days - 1) AND (xTS_PKKey = pr.xCH_TSOpPacketKey) AND (xTS_SubCode1 = pr.xCH_TSSubCode1))
	null AS CharterUnsolidBackPlaces,
	-- AllotmentDaysCount
	--CASE @isAllotment WHEN 1 THEN
	--	dbo.GetHotelDays(DATEADD(DAY, hs.TS_Day - 1, pr.xTP_DateBegin), hs.TS_Day, lst.TI_FirstHDKey, hr.HR_RMKEY, hr.HR_RCKEY, 1)
	--ELSE NULL END
	null AS AllotmentDaysCount,
	-- CommitmentDaysCount
	--CASE @isCommitment WHEN 1 THEN
	--	dbo.GetHotelDays(DATEADD(DAY, hs.TS_Day - 1, pr.xTP_DateBegin), hs.TS_Day, lst.TI_FirstHDKey, hr.HR_RMKEY, hr.HR_RCKEY, 2)
	--ELSE NULL END
	null AS CommitmentDaysCount,
	-- HotelAllPlaces
	--dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 1, pr.xTP_DateBegin, hs.TS_Code, NULL, lst.TI_Days, hr.HR_RCKEY)
	null AS HotelAllPlaces,
	-- HotelBusyPlaces
	--dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 0, pr.xTP_DateBegin, hs.TS_Code, NULL, lst.TI_Days, hr.HR_RCKEY)
	null AS HotelBusyPlaces,
	-- HotelCommitmentPlaces
	--dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 1, pr.xTP_DateBegin, hs.TS_Code, 2, lst.TI_Days, hr.HR_RCKEY)
	null AS HotelCommitmentPlaces,
	-- Stop sale
--	(SELECT TOP 1 1 FROM StopSales WITH(NOLOCK)
--     INNER JOIN QuotaObjects WITH(NOLOCK) ON QO_ID = SS_QOID
--     WHERE
--        ISNULL(SS_IsDeleted, 0) = 0
--        AND SS_Date BETWEEN (pr.xTP_DateBegin + hs.TS_Day - 1) AND (pr.xTP_DateBegin + hs.TS_Day - 1 + hs.TS_Days - 1)
--	    AND QO_SVKey = 3
--		AND QO_Code = lst.TI_FirstHDKey
--		AND (QO_SubCode1 = HR_RMKEY OR QO_SubCode1 = 0)
--		AND (QO_SubCode2 = HR_RCKEY OR QO_SubCode2 = 0))
	null AS StopSale
FROM #tmpPriceTable       pr
JOIN TP_Tours             tour    WITH(NOLOCK) ON tour.TO_Key = pr.xTP_TOKey
JOIN TP_Lists             lst     WITH(NOLOCK) ON pr.xTP_TIKey = lst.TI_Key
JOIN HotelRooms           hr      WITH(NOLOCK) ON lst.TI_FirstHRKey = hr.HR_Key
JOIN Rooms                rm      WITH(NOLOCK) ON rm.RM_KEY = hr.HR_RMKey
JOIN RoomsCategory        rc      WITH(NOLOCK) ON hr.HR_RCKEY = rc.RC_Key
JOIN HotelDictionary      hd      WITH(NOLOCK) ON lst.TI_FirstHDKey = hd.HD_Key
JOIN TP_ServiceLists      slhs    WITH(NOLOCK) ON lst.TI_Key = slhs.TL_TIKey
JOIN TP_Services          hs      WITH(NOLOCK) ON slhs.TL_TSKey = hs.TS_Key AND hs.TS_SVKey = 3 AND hs.TS_Code = lst.TI_FirstHDKey
JOIN Pansion              pn      WITH(NOLOCK) ON lst.TI_FirstPNKey = pn.PN_Key
JOIN CityDictionary       ct      WITH(NOLOCK) ON hd.HD_CTKEY = ct.CT_KEY
JOIN Accmdmentype         ac      WITH(NOLOCK) ON hr.HR_ACKEY = ac.AC_KEY
WHERE
	TL_TOKey in (select tourKey from #tourKeysTable)
	and (ISNULL(@isAccommodationWithAdult, 0) = 0 OR (HR_ACKEY IN (SELECT AC_KEY FROM #AccomType))) AND
	-- фильтр по мин. ценам НЕ задан
	((ISNULL(@isMinPrice, 0) = 0 AND
	-- проверяем тур на те категории номеров и питаний, которые были переданы
	hr.HR_RCKEY IN (SELECT rcKey FROM #roomCategoryKeysTable) AND
	lst.TI_FirstPNKey IN (SELECT pansionKey FROM #pansionKeysTable))
	OR
	-- фильтр по мин. ценам задан
	(ISNULL(@isMinPrice, 0) != 0 AND
	-- проверяем по базовым привязкам отеля
	hr.HR_RCKEY = (SELECT TOP 1 ahc.AH_RcKey FROM AssociationHotelCat ahc WHERE ahc.AH_HdKey = lst.TI_FirstHDKey) AND
	lst.TI_FirstPNKey = (SELECT TOP 1 ahc.ah_pnkey FROM AssociationHotelCat ahc WHERE ahc.AH_HdKey = lst.TI_FirstHDKey) AND
	-- если заданы обе настройки с типом размещения и типом комнаты, то отсеиваем по ним
	(ISNULL(@accmdDefaultKey, 0) = 0 OR ISNULL(@roomTypeDefaultKey, 0) = 0 OR
	((hr.HR_ACKEY = @accmdDefaultKey) AND (hr.HR_RMKEY = @roomTypeDefaultKey))))
	) AND
	-- только выставленные в интернет туры
	(@isOnlineOnly IS NULL OR (@isOnlineOnly = CASE WHEN pr.xTP_Gross IS NULL THEN 0 ELSE TO_IsEnabled END)) AND
	-- отсев по ценам за тур
	(ISNULL(@priceMin, 0) = 0 OR (pr.xTP_Gross >= @priceMin)) AND
	(ISNULL(@priceMax, 0) = 0 OR (pr.xTP_Gross <= @priceMax))

-- только измененные цены
IF ISNULL(@isModifyPriceOnly, 0) != 0 BEGIN
	-- удаляем из @prices все неизмененные цены
	DELETE FROM #prices
	WHERE TP_Key IN (
		SELECT p.TP_Key FROM #prices p
		JOIN TP_PriceComponents pc ON p.TP_Key = pc.PC_TPKey
		WHERE NOT EXISTS(
		             SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_1  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_2  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_3  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_4  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_5  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_6  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_7  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_8  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_9  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_10 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_11 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_12 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_13 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_14 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_15 IS NOT NULL) AND (spad.SPAD_NeedApply != 0))
	)
END

	       
PRINT 'выбор туров: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
set @debug = 'выбор туров: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
insert into Debug (db_Date, db_Mod, db_Text)
values(GETDATE(), 'MM', substring(@debug, 0, 255))

SET @beginTime = GETDATE()
-- актуализируем цены по отобранным турам
declare @tpKeys nvarchar(max)
set @tpKeys = ''
select @tpKeys = @tpKeys + convert(nvarchar(max), p.TP_Key) + ', '
from #prices p
create table #tmp
	(
		tpKey bigint,
		newPrice money
	)
--По настройке получаем актуальную цену через сервис или хранимкой
if exists (select top 1 1 from SystemSettings with (nolock) where SS_ParmName = 'ServiceGetActualPrice' and SS_ParmValue = 1)
	begin
		SET @tpKeys = RTRIM(@tpKeys)
		
		if (RIGHT(@tpKeys,1) = ',')
			SET @tpKeys = SUBSTRING(@tpKeys, 0, LEN(@tpKeys))
		
		print 'exec WcfGetActualPrice ' + '''' +  @tpKeys + ''''
		-- делаем инсерт во веременную таблицу, что бы результата не выводился при запуске этой хранимки
		exec WcfGetActualPrice @tpKeys
	end
else
	begin
		print 'exec ReCalculate_CheckActualPrice ' + '''' +  @tpKeys + ''''
		-- делаем инсерт во веременную таблицу, что бы результата не выводился при запуске этой хранимки
		insert into #tmp (tpKey, newPrice)
		exec ReCalculate_CheckActualPrice @tpKeys
	end
print 'Расчитываем изменения в ценах: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
set @debug = 'Расчитываем изменения в ценах: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
insert into Debug (db_Date, db_Mod, db_Text)
values(GETDATE(), 'MM', substring(@debug, 0, 255))

SELECT p.*,
	pc.PC_Id AS PC_Id,
    pc.PC_Rate AS Rate,
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
	AddCostIsCommission_15, AddCostNoCommission_15, CommissionOnly_15, Gross_15, IsCommission_15, MarginPercent_15, SCPId_15, SVKey_15
	FROM #prices p
	JOIN TP_PriceComponents pc WITH(NOLOCK) ON pc.PC_TPKey = p.TP_Key
	WHERE (@priceKeys IS NULL OR pc.PC_Id IN (SELECT priceKey FROM #priceKeysTable))
END
GO
grant exec on [dbo].[MarginMonitor_PriceFilter] to public
go
/*********************************************************************/
/* end sp_MarginMonitor_PriceFilter.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwFillTP.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwFillTP]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwFillTP]
GO

CREATE procedure [dbo].[mwFillTP] (@tokey int, @calcKey int = null)
as
begin
	-- <date>2014-04-10</date>
	-- <version>2009.2.21.1</version>
	declare @sql varchar(4000)
	declare @source varchar(200)
	set @source = ''
	
	declare @where as varchar(4000)
	declare @whereCycle as varchar(4000)

	declare @tokeyStr varchar (20)
	set @tokeyStr = cast(@tokey as varchar(20))

	declare @calcKeyStr varchar (20)
	set @calcKeyStr = cast(@calcKey as varchar(20))

	if dbo.mwReplIsSubscriber() > 0 and len(dbo.mwReplPublisherDB()) > 0
		set @source = '[mt].' + dbo.mwReplPublisherDB() + '.'
	
	if not exists(select 1 from dbo.tp_tours with(nolock) where to_key = @tokey)
	begin
		set @sql = '
		insert into dbo.tp_tours (
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
		'insert into dbo.tp_services (
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

		set @whereCycle = 'TS_TOKey = ' + @tokeyStr
		set @sql = 'while (select count(1) from ' + @source + 'dbo.tp_services  as r with (nolock) where ' + @whereCycle + ') 
						> (select count(1) from tp_services with (nolock) where ' + @whereCycle + ')
		begin
		' + @sql + @where + '
			if @@rowcount = 0
				break
		end'

		exec (@sql)
	end

	print 'tp_prices'
	delete from dbo.tp_prices where tp_tokey = @tokey
	--if not exists(select 1 from dbo.tp_prices with(nolock) where tp_tokey = @calcKey)
	begin
		set @sql = 
		'insert into dbo.tp_prices (
			[TP_Key],
			[TP_TOKey],
			[TP_DateBegin],
			[TP_DateEnd],
			[TP_Gross],
			[TP_TIKey],
			[TP_CalculatingKey]
		)
		select top 10000
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
			
		set @whereCycle = ''
		if(@calcKey is null)
			set @whereCycle = 'TP_TOKey = ' + @tokeyStr
		else
			set @whereCycle = 'TP_CalculatingKey = ' + @calcKeyStr

		set @sql = 'while (select count(1) from ' + @source + 'dbo.tp_prices  as r with (nolock) where ' + @whereCycle + ') 
						> (select count(1) from tp_prices with (nolock) where ' + @whereCycle + ')
		begin
		' + @sql + @where + '
			if @@rowcount = 0
				break
		end'

		exec (@sql)
	end
	delete from dbo.tp_lists where ti_tokey = @tokey
	--if not exists(select 1 from dbo.tp_lists with(nolock) where ti_tokey = @calcKey)
	begin
		set @sql = 
		'insert into dbo.tp_lists (
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
		
		set @where = @where + 'TI_TOKey = ' + @tokeyStr
		set @where = @where + ' and TI_Key not in (select TI_Key from dbo.tp_lists with (nolock) where TI_TOKey = ' + @tokeyStr + ')'

		set @whereCycle = 'TI_TOKey = ' + @tokeyStr

		set @sql = 'while (select count(1) from ' + @source + 'dbo.tp_lists with (nolock) where ' + @whereCycle + ') 
						> (select count(1) from tp_lists with (nolock) where ' + @whereCycle + ')
		begin
		' + @sql + @where + '
			if @@rowcount = 0
				break
		end'

		exec (@sql)
	end

	delete from dbo.tp_servicelists where tl_tokey = @tokey
	--if not exists(select 1 from dbo.tp_servicelists with(nolock) where tl_tokey = @calcKey)
	begin	
		set @sql = 
		'
		set identity_insert tp_serviceLists on

		insert into dbo.tp_servicelists (
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

		set @whereCycle = 'TL_TOKey = ' + @tokeyStr

		--set @sql = 'while exists (select top 1 1 from ' + @source + 'dbo.tp_servicelists as r with (nolock) where ' + @where + ')
		set @sql = 'while (select count(1) from ' + @source + 'dbo.tp_servicelists  as r with (nolock) where ' + @whereCycle + ') 
						> (select count(1) from tp_servicelists with (nolock) where ' + @whereCycle + ')
		begin
		' + @sql + @where + '
			if @@rowcount = 0
				break
		end'
		
		exec (@sql)
	end
end
GO

grant execute on [dbo].[mwFillTP] to public
GO
/*********************************************************************/
/* end sp_mwFillTP.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplDisableDeletedPrices.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE name = 'mwReplDisableDeletedPrices' and type='P')
	DROP PROCEDURE [dbo].[mwReplDisableDeletedPrices]
GO

create procedure [dbo].[mwReplDisableDeletedPrices]
as
begin

	--<DATE>2014-04-16</DATE>
	--<VERSION>9.2.21.1</VERSION>

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

GRANT EXEC on [dbo].[mwReplDisableDeletedPrices] to public
GO
/*********************************************************************/
/* end sp_mwReplDisableDeletedPrices.sql */
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

	if exists(select top 1 1 from mwReplQueue with(nolock) where rq_state = 4 and DATEDIFF(MINUTE, rq_startdate, GETDATE()) > 10 and rq_priority > 0)
	begin
		delete from mwReplQueue where rq_tokey not in (select to_key from TP_Tours) and rq_mode <> 4 and (rq_startdate is null or rq_state = 4)
		
		update mwReplQueue set rq_state = 1, rq_startdate = null, rq_enddate = null, rq_priority = rq_priority - 1
		where rq_state = 4 
		and DATEDIFF(MINUTE, rq_startdate, GETDATE()) > 10
		and rq_priority > 0

	end

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
	and exists (select top 1 1 from @selectedDirections where cnKey = isnull(rq_cnkey, 0) and ctKey = isnull(rq_ctkeyfrom, 0))
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

		update mwReplQueue set rq_startdate = getdate() where rq_id = @rqId
		
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
	
end
GO

grant exec on [dbo].[mwReplProcessQueueDivide] to public
GO
/*********************************************************************/
/* end sp_mwReplProcessQueueDivide.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplUpdatePriceEnabledAndValue.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReplUpdatePriceEnabledAndValue]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwReplUpdatePriceEnabledAndValue]
GO

create proc [dbo].[mwReplUpdatePriceEnabledAndValue] @tokey int, @calcKey int, @rqId int = null
as
begin
	-- <date>2012-09-20</date>
	-- <version>2009.2.16.1</version>
	
	declare @ctFromKey int, @cnKey int
	declare @tableName varchar(500)
	declare @mwSearchType int
	declare @source varchar(200), @sql nvarchar(max)
	set @source = ''
	
	if dbo.mwReplIsSubscriber() > 0 and len(dbo.mwReplPublisherDB()) > 0
		set @source = '[mt].' + dbo.mwReplPublisherDB() + '.'
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start mwReplUpdatePriceEnabledAndValue'
		
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'
	
	if (@mwSearchType = 0)
	begin
		set @tableName = 'mwPriceDataTable'
	end
	else
	begin
		select @ctFromKey = TL_CTDepartureKey, @cnKey = TO_CNKey
		from Turlist join TP_Tours on TL_KEY = TO_TRKey
		where TO_Key = @tokey
		
		set @tableName = dbo.mwGetPriceTableName(@cnKey, @ctFromKey)		
	end
	
	set @sql = 'update ' + @tableName + ' set pt_isenabled = 1, pt_price = tp_gross'
	set @sql = @sql + ' from ' + @source + 'dbo.tp_prices'
	set @sql = @sql + ' where pt_pricekey = tp_key and tp_calculatingkey = ' + ltrim(STR(@calcKey))
	print (@sql)
	exec (@sql)

	set @sql = 'update ' + @tableName + ' set pt_tourcreated = to_datecreated'
	set @sql = @sql + ' from ' + @source + 'dbo.tp_tours'
	set @sql = @sql + ' where to_key = ' + ltrim(STR(@tokey))
	set @sql = @sql + ' and pt_tourkey = to_key'
	print (@sql)
	exec (@sql)

	set @sql = 'update mwSpoDataTable set sd_tourcreated = to_datecreated'
	set @sql = @sql + ' from ' + @source + 'dbo.tp_tours'
	set @sql = @sql + ' where to_key = ' + ltrim(STR(@tokey))
	set @sql = @sql + ' and sd_tourkey = to_key'
	print (@sql)
	exec (@sql)
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'End mwReplUpdatePriceEnabledAndValue'
end
GO

grant execute on [dbo].[mwReplUpdatePriceEnabledAndValue] to public
GO
/*********************************************************************/
/* end sp_mwReplUpdatePriceEnabledAndValue.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_RecalculateByTime.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RecalculateByTime]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[RecalculateByTime]
GO

CREATE PROCEDURE [dbo].[RecalculateByTime] 
(
	--<VERSION>2009.2.21.1</VERSION>
	--<DATA>2014-04-14</DATA>
	@cpkey int = null
)
AS
DECLARE
	@priceTourKey int,			-- ключ обсчитываемого тура
	@priceTOKey int,
	@saleDate datetime,		-- дата продажи
	@nullCostAsZero smallint,	-- считать отсутствующие цены нулевыми (кроме проживания) 0 - нет, 1 - да
	@noFlight smallint,		-- при отсутствии перелёта в расписании 0 - ничего не делать, 1 - не обсчитывать тур, 2 - искать подходящий перелёт (если не найдено - не рассчитывать)
	@update smallint,			-- признак дозаписи 0 - расчет, 1 - дозапись
	@useHolidayRule smallint,		-- Правило выходного дня: 0 - не использовать, 1 - использовать
	@countReCalcMax smallint,   --максимальное число одновременно расчитываемых прайс-листов
	@countRecalc int,      --число расчитываемых прайс листов
	@priceTOKeyActiv int,  --ключ тура который сейчас активен
	@flagTran bit = 0
BEGIN
	--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	
	select @countRecalcMax = SS_ParmValue from SystemSettings where SS_ParmName='SYSCalcPriceCountMax'
	select @countRecalc=COUNT(*) from tp_tours WHERE TO_PROGRESS<>100 and TO_TrKey in (select CP_TourKey from CalculatingPriceLists where CP_Status=1)
	
	--если количество одновременно расчитываемых туров не превышает максимального значения или не задан параметр максимальное количество расчитываемых туров
	if (@countRecalcMax > @countRecalc or @countRecalcMax is null )
	begin	
		begin tran
		
			select top 1 @cpkey = CP_Key from CalculatingPriceLists 
											where CP_StartTime is not null and 
												(CP_Status = 0 or (CP_Status = 1 and CP_StartTime<=DateAdd(hour,-10,GETDATE()))) 
											order by CP_Priority desc
			UPDATE CalculatingPriceLists WITH (ROWLOCK) Set CP_Status = 1, CP_StartTime=GETDATE() where CP_Key=@cpkey
			UPDATE TP_Tours WITH (ROWLOCK) Set TO_PROGRESS = 0, TO_UPDATE = 0, TO_UPDATETIME=GETDATE() where TO_Key= (select CP_PriceTourKey from  CalculatingPriceLists where CP_Key=@cpkey)
			
		commit tran
		if (@cpkey is not null)
		begin
		
			select @priceTourKey=CP_TourKey,  @saleDate=CP_SaleDate, @nullCostAsZero=CP_NullCostAsZero,@noFlight=CP_NoFlight, @update=CP_Update,
				@useHolidayRule=CP_UseHolidayRule, @priceTOKey = CP_PriceTourKey from CalculatingPriceLists where CP_Key=@cpkey
				
			-- если у нас есть активный тур  и это не дозапись то удаляем его
			select @priceTOKeyActiv=TO_Key from TP_Tours left join CalculatingPriceLists on CP_PriceTourKey=TO_Key 
											where TO_TRKey=@priceTourKey and CP_StartTime is null and TO_Key<>@priceTOKey
			
			begin try								
			
				if (@priceTOKeyActiv!=0 and @update<>1 and @priceTOKeyActiv is not null)
				begin	
					EXEC RemoveReferences 'TP_TOURS', @priceTOKeyActiv
					DELETE FROM CalculatingPriceLists with (rowlock) WHERE CP_PriceTourKey = @priceTOKeyActiv
					DELETE FROM TP_TOURS with (rowlock) WHERE TO_KEY = @priceTOKeyActiv
				end

				--если у тура менялом название то, меняем его, на название из тур листа
				--запоминаем значения отличные от названия (иначе триггер их перетрет)
				declare @nameWeb varchar(250)
				select @nameWeb = TL_NAMEWEB from Turlist where TL_KEY=@priceTourKey
				update TP_Tours SET TO_Name=(select TL_NAMEWEB from Turlist where TL_KEY=@priceTourKey) where TO_Key=@priceTOKey
				update Turlist set TL_NAMEWEB = @nameWeb  where TL_KEY=@priceTourKey

				--запуск расчета
				exec CalculatePriceList @nPriceTourKey=@priceTOKey, @nCalculatingKey=@cpkey, @dtSaleDate=@saleDate, @nNullCostAsZero=@nullCostAsZero, @nNoFlight =@noFlight,
					@nUpdate=@update,@nUseHolidayRule = @useHolidayRule
					
				--если стоит параметр выставить в интернет, выставляем тур в интернет	
				if exists(select 1 from CalculatingPriceLists where CP_Key=@cpkey and CP_ExposeWeb=1 and CP_Update = 0)
				begin
					exec FillMasterWebSearchFields @tokey=@priceTOKey, @calcKey=null
					update TP_Tours SET TO_IsEnabled=1 where TO_Key=@priceTOKey
				end
				
				--расчет прайс-листа завершен
				UPDATE CalculatingPriceLists Set CP_Status=0, CP_StartTime = null where CP_Key=@cpkey
			end try
			begin catch
				insert into Debug (db_Text,db_n1, db_n2) values (ERROR_MESSAGE(),4, @cpkey)
			end catch
		end
	END
END
GO

grant execute on [dbo].[RecalculateByTime] to public
GO
/*********************************************************************/
/* end sp_RecalculateByTime.sql */
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
	--<VERSION>9.2.20.11</VERSION>
	--<DATE>2014-04-16</DATE>

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
/* begin T_AccmdmentypeDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AccmdmentypeDelete]'))
DROP TRIGGER [dbo].[T_AccmdmentypeDelete]
GO

CREATE TRIGGER [dbo].[T_AccmdmentypeDelete]
   ON [dbo].[Accmdmentype]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>
	
	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Accmdmentype', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AC_Key, AC_Name', AC_Key, AC_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AccmdmentypeDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AddDescript1Delete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AddDescript1Delete]'))
DROP TRIGGER [dbo].[T_AddDescript1Delete]
GO

CREATE TRIGGER [dbo].[T_AddDescript1Delete]
   ON [dbo].[AddDescript1]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>
	
	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'AddDescript1', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'A1_Key, A1_Name', A1_Key, A1_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AddDescript1Delete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AddDescript2Delete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AddDescript2Delete]'))
DROP TRIGGER [dbo].[T_AddDescript2Delete]
GO

CREATE TRIGGER [dbo].[T_AddDescript2Delete]
   ON [dbo].[AddDescript2]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'AddDescript2', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'A2_Key, A2_Name', A2_Key, A2_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AddDescript2Delete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AdvertiseDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AdvertiseDelete]'))
DROP TRIGGER [dbo].[T_AdvertiseDelete]
GO

CREATE TRIGGER [dbo].[T_AdvertiseDelete]
   ON [dbo].[Advertise]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>
	
	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Advertise', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AD_Key, AD_Name', AD_Key, AD_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AdvertiseDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AircraftDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AircraftDelete]'))
DROP TRIGGER [dbo].[T_AircraftDelete]
GO

CREATE TRIGGER [dbo].[T_AircraftDelete]
   ON [dbo].[Aircraft]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Aircraft', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AC_Key, AC_Name', AC_Key, AC_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AircraftDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AirlineDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AirlineDelete]'))
DROP TRIGGER [dbo].[T_AirlineDelete]
GO

CREATE TRIGGER [dbo].[T_AirlineDelete]
   ON [dbo].[Airline]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Airline', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AL_Key, AL_Name', AL_Key, AL_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AirlineDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AirportDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AirportDelete]'))
DROP TRIGGER [dbo].[T_AirportDelete]
GO

CREATE TRIGGER [dbo].[T_AirportDelete]
   ON [dbo].[Airport]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Airport', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AP_Key, AP_Name', AP_Key, AP_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AirportDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AirSeasonDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AirSeasonDelete]'))
DROP TRIGGER [dbo].[T_AirSeasonDelete]
GO

CREATE TRIGGER [dbo].[T_AirSeasonDelete]
   ON [dbo].[AirSeason]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'AirSeason', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AS_ID', AS_ID, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AirSeasonDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AirServiceDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AirServiceDelete]'))
DROP TRIGGER [dbo].[T_AirServiceDelete]
GO

CREATE TRIGGER [dbo].[T_AirServiceDelete]
   ON [dbo].[AirService]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'AirService', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AS_Key, AS_NameRus', AS_Key, AS_NameRus, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AirServiceDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_Ank_CasesDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_Ank_CasesDelete]'))
DROP TRIGGER [dbo].[T_Ank_CasesDelete]
GO

CREATE TRIGGER [dbo].[T_Ank_CasesDelete]
   ON [dbo].[Ank_Cases]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Ank_Cases', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AC_AFKey, AC_Name', AC_AFKey, AC_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_Ank_CasesDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_Ank_FieldsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_Ank_FieldsDelete]'))
DROP TRIGGER [dbo].[T_Ank_FieldsDelete]
GO

CREATE TRIGGER [dbo].[T_Ank_FieldsDelete]
   ON [dbo].[Ank_Fields]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Ank_Fields', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AF_Key, AF_Name', AF_Key, AF_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_Ank_FieldsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AnnulReasonsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_AnnulReasonsDelete]'))
DROP TRIGGER [dbo].[T_AnnulReasonsDelete]
GO

CREATE TRIGGER [dbo].[T_AnnulReasonsDelete]
   ON [dbo].[AnnulReasons]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'AnnulReasons', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'AR_Key, AR_Name', AR_Key, AR_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_AnnulReasonsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_BanksDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_BanksDelete]'))
DROP TRIGGER [dbo].[T_BanksDelete]
GO

CREATE TRIGGER [dbo].[T_BanksDelete]
   ON [dbo].[Banks]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Banks', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'BN_Key, BN_Name', BN_Key, BN_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_BanksDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_CabineDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CabineDelete]'))
DROP TRIGGER [dbo].[T_CabineDelete]
GO

CREATE TRIGGER [dbo].[T_CabineDelete]
   ON [dbo].[Cabine]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Cabine', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'CB_Key, CB_Name', CB_Key, CB_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_CabineDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_CategoriesOfHotelDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CategoriesOfHotelDelete]'))
DROP TRIGGER [dbo].[T_CategoriesOfHotelDelete]
GO

CREATE TRIGGER [dbo].[T_CategoriesOfHotelDelete]
   ON [dbo].[CategoriesOfHotel]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'CategoriesOfHotel', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'COH_Id, COH_Name', COH_Id, COH_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_CategoriesOfHotelDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_CauseDiscountsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CauseDiscountsDelete]'))
DROP TRIGGER [dbo].[T_CauseDiscountsDelete]
GO

CREATE TRIGGER [dbo].[T_CauseDiscountsDelete]
   ON [dbo].[CauseDiscounts]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'CauseDiscounts', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'CD_Key, CD_Name', CD_Key, CD_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_CauseDiscountsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_CharterDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CharterDelete]'))
DROP TRIGGER [dbo].[T_CharterDelete]
GO

CREATE TRIGGER [dbo].[T_CharterDelete]
   ON [dbo].[Charter]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Charter', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'CH_Key', CH_Key, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_CharterDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_CityDictionaryDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CityDictionaryDelete]'))
DROP TRIGGER [dbo].[T_CityDictionaryDelete]
GO

CREATE TRIGGER [dbo].[T_CityDictionaryDelete]
   ON [dbo].[CityDictionary]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'CityDictionary', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'CT_Key, CT_Name', CT_Key, CT_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_CityDictionaryDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_ClientDel.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_ClientDel]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [dbo].[T_ClientDel]
GO
CREATE TRIGGER [T_ClientDel] ON [dbo].[Clients] 
FOR DELETE 
AS
--<DATE>2014-04-14</DATE>
---<VERSION>9.2.20.12</VERSION>
IF @@ROWCOUNT > 0
BEGIN
	DECLARE @n_ClKey INT
	DECLARE curClientDel cursor for SELECT CL_KEY FROM DELETED
	OPEN curClientDel
	FETCH NEXT FROM curClientDel INTO @n_ClKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE tbl_TURIST SET tu_id = null WHERE tu_id = @n_ClKey
		FETCH NEXT FROM curClientDel INTO @n_ClKey
	END
	CLOSE curClientDel
	DEALLOCATE curClientDel
	
	if APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Clients', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'CL_Key, CL_NameRus', CL_Key, CL_NameRus, 1 from DELETED
	end		
END
GO
/*********************************************************************/
/* end T_ClientDel.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_ControlsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_ControlsDelete]'))
DROP TRIGGER [dbo].[T_ControlsDelete]
GO

CREATE TRIGGER [dbo].[T_ControlsDelete]
   ON [dbo].[Controls]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Controls', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'CR_Key, CR_Name', CR_Key, CR_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_ControlsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_DiscountsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_DiscountsDelete]'))
DROP TRIGGER [dbo].[T_DiscountsDelete]
GO

CREATE TRIGGER [dbo].[T_DiscountsDelete]
   ON [dbo].[Discounts]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Discounts', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'DS_Key', DS_Key, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_DiscountsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_Discount_ClientDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_Discount_ClientDelete]'))
DROP TRIGGER [dbo].[T_Discount_ClientDelete]
GO

CREATE TRIGGER [dbo].[T_Discount_ClientDelete]
   ON [dbo].[Discount_Client]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Discount_Client', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'DS_Key, DS_Name', DS_Key, DS_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_Discount_ClientDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_DocumentStatusDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_DocumentStatusDelete]'))
DROP TRIGGER [dbo].[T_DocumentStatusDelete]
GO

CREATE TRIGGER [dbo].[T_DocumentStatusDelete]
   ON [dbo].[DocumentStatus]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'DocumentStatus', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'DS_Key, DS_Name', DS_Key, DS_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_DocumentStatusDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_DUP_USERDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_DUP_USERDelete]'))
DROP TRIGGER [dbo].[T_DUP_USERDelete]
GO

CREATE TRIGGER [dbo].[T_DUP_USERDelete]
   ON [dbo].[DUP_USER]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'DUP_USER', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'US_Key, US_FullName', US_Key, US_FullName, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_DUP_USERDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_ExcurDictionaryDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_ExcurDictionaryDelete]'))
DROP TRIGGER [dbo].[T_ExcurDictionaryDelete]
GO

CREATE TRIGGER [dbo].[T_ExcurDictionaryDelete]
   ON [dbo].[ExcurDictionary]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'ExcurDictionary', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'ED_Key, ED_Name', ED_Key, ED_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_ExcurDictionaryDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_HotelDictionaryDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_HotelDictionaryDelete]'))
DROP TRIGGER [dbo].[T_HotelDictionaryDelete]
GO

CREATE TRIGGER [dbo].[T_HotelDictionaryDelete]
   ON [dbo].[HotelDictionary]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'HotelDictionary', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'HD_Key, HD_Name', HD_Key, HD_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_HotelDictionaryDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_HotelTypesDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_HotelTypesDelete]'))
DROP TRIGGER [dbo].[T_HotelTypesDelete]
GO

CREATE TRIGGER [dbo].[T_HotelTypesDelete]
   ON [dbo].[HotelTypes]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'HotelTypes', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'HTT_ID, HTT_Name', HTT_ID, HTT_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_HotelTypesDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_mwReplDeletePrice_drop.sql */
/*********************************************************************/
if exists (select id from sysobjects where xtype = 'TR' and name='mwReplDeletePrice')
	drop trigger dbo.[mwReplDeletePrice]
go
/*********************************************************************/
/* end T_mwReplDeletePrice_drop.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_mwUpdatePriceTourEnabled.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[mwUpdatePriceTourEnabled]'))
	DROP TRIGGER [dbo].[mwUpdatePriceTourEnabled]
GO

create trigger [dbo].[mwUpdatePriceTourEnabled] on [dbo].[TP_Tours]
for update
as
begin
	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-04-17</DATE>

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
			select 3, xrq_tokey, xrq_cnkey, ISNULL(TL_CTDepartureKey, 0)
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
				update mwPriceDataTable with (rowlock)
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
						set @sql = 'update ' + @tableName + ' with(rowlock) set pt_isenabled = 0 where pt_tourkey = ' + ltrim(str(@tokey))
						exec (@sql)
					END
					fetch next from tblCursor into @tokey, @cnkey, @ctkey
				end

				close tblCursor
				deallocate tblCursor
			end

			update mwSpoDataTable with(rowlock)
			set sd_isenabled = 0
			from inserted i inner join deleted d on i.to_key = d.to_key			
			where sd_tourkey = i.to_key
				and i.to_isenabled <> d.to_isenabled and i.to_isenabled = 0	

		end
	end
end
GO
/*********************************************************************/
/* end T_mwUpdatePriceTourEnabled.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_Order_StatusDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_Order_StatusDelete]'))
DROP TRIGGER [dbo].[T_Order_StatusDelete]
GO

CREATE TRIGGER [dbo].[T_Order_StatusDelete]
   ON [dbo].[Order_Status]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Order_Status', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'OS_CODE, OS_Name_Rus', OS_CODE, OS_Name_Rus, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_Order_StatusDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_PansionDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_PansionDelete]'))
DROP TRIGGER [dbo].[T_PansionDelete]
GO

CREATE TRIGGER [dbo].[T_PansionDelete]
   ON [dbo].[Pansion]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Pansion', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'PN_Key, PN_Name', PN_Key, PN_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_PansionDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_ProfessionDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_ProfessionDelete]'))
DROP TRIGGER [dbo].[T_ProfessionDelete]
GO

CREATE TRIGGER [dbo].[T_ProfessionDelete]
   ON [dbo].[Profession]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Profession', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'PF_Key, PF_Name', PF_Key, PF_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_ProfessionDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_PrtDepsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_PrtDepsDelete]'))
DROP TRIGGER [dbo].[T_PrtDepsDelete]
GO

CREATE TRIGGER [dbo].[T_PrtDepsDelete]
   ON [dbo].[PrtDeps]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'PrtDeps', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'PDP_Key, PDP_Name', PDP_Key, PDP_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_PrtDepsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_PrtDogTypesDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_PrtDogTypesDelete]'))
DROP TRIGGER [dbo].[T_PrtDogTypesDelete]
GO

CREATE TRIGGER [dbo].[T_PrtDogTypesDelete]
   ON [dbo].[PrtDogTypes]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'PrtDogTypes', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'PDT_ID, PDT_Name', PDT_ID, PDT_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_PrtDogTypesDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_PrtGroupsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_PrtGroupsDelete]'))
DROP TRIGGER [dbo].[T_PrtGroupsDelete]
GO

CREATE TRIGGER [dbo].[T_PrtGroupsDelete]
   ON [dbo].[PrtGroups]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'PrtGroups', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'PG_Key, PG_Name', PG_Key, PG_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_PrtGroupsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_PrtTypesDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_PrtTypesDelete]'))
DROP TRIGGER [dbo].[T_PrtTypesDelete]
GO

CREATE TRIGGER [dbo].[T_PrtTypesDelete]
   ON [dbo].[PrtTypes]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'PrtTypes', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'PT_ID, PT_Name', PT_ID, PT_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_PrtTypesDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_RatesDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_RatesDelete]'))
DROP TRIGGER [dbo].[T_RatesDelete]
GO

CREATE TRIGGER [dbo].[T_RatesDelete]
   ON [dbo].[Rates]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Rates', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'RA_Key, RA_Name', RA_Key, RA_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_RatesDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_ResortsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_ResortsDelete]'))
DROP TRIGGER [dbo].[T_ResortsDelete]
GO

CREATE TRIGGER [dbo].[T_ResortsDelete]
   ON [dbo].[Resorts]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Resorts', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'RS_Key, RS_Name', RS_Key, RS_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_ResortsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_RoomsCategoryDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_RoomsCategoryDelete]'))
DROP TRIGGER [dbo].[T_RoomsCategoryDelete]
GO

CREATE TRIGGER [dbo].[T_RoomsCategoryDelete]
   ON [dbo].[RoomsCategory]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'RoomsCategory', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'RC_Key, RC_Name', RC_Key, RC_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_RoomsCategoryDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_RoomsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_RoomsDelete]'))
DROP TRIGGER [dbo].[T_RoomsDelete]
GO

CREATE TRIGGER [dbo].[T_RoomsDelete]
   ON [dbo].[Rooms]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Rooms', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'RM_Key, RM_Name', RM_Key, RM_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_RoomsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_ServiceDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_ServiceDelete]'))
DROP TRIGGER [dbo].[T_ServiceDelete]
GO

CREATE TRIGGER [dbo].[T_ServiceDelete]
   ON [dbo].[Service]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Service', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'SV_Key, SV_Name', SV_Key, SV_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_ServiceDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_ShipDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_ShipDelete]'))
DROP TRIGGER [dbo].[T_ShipDelete]
GO

CREATE TRIGGER [dbo].[T_ShipDelete]
   ON [dbo].[Ship]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Ship', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'SH_Key, SH_Name', SH_Key, SH_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_ShipDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_tbl_CountryDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_tbl_CountryDelete]'))
DROP TRIGGER [dbo].[T_tbl_CountryDelete]
GO

CREATE TRIGGER [dbo].[T_tbl_CountryDelete]
   ON [dbo].[tbl_Country]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'tbl_Country', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'CN_Key, CN_Name', CN_Key, CN_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_tbl_CountryDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_tbl_DiscountActionsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_tbl_DiscountActionsDelete]'))
DROP TRIGGER [dbo].[T_tbl_DiscountActionsDelete]
GO

CREATE TRIGGER [dbo].[T_tbl_DiscountActionsDelete]
   ON [dbo].[tbl_DiscountActions]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'tbl_DiscountActions', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'DA_Key, DA_Name', DA_Key, DA_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_tbl_DiscountActionsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TipTurDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_TipTurDelete]'))
DROP TRIGGER [dbo].[T_TipTurDelete]
GO

CREATE TRIGGER [dbo].[T_TipTurDelete]
   ON [dbo].[TipTur]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'TipTur', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'TP_Key, TP_Name', TP_Key, TP_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_TipTurDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TitleTypeClientDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_TitleTypeClientDelete]'))
DROP TRIGGER [dbo].[T_TitleTypeClientDelete]
GO

CREATE TRIGGER [dbo].[T_TitleTypeClientDelete]
   ON [dbo].[TitleTypeClient]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'TitleTypeClient', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'TL_Key, TL_Title', TL_Key, TL_Title, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_TitleTypeClientDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TitleTypeImpressDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_TitleTypeImpressDelete]'))
DROP TRIGGER [dbo].[T_TitleTypeImpressDelete]
GO

CREATE TRIGGER [dbo].[T_TitleTypeImpressDelete]
   ON [dbo].[TitleTypeClient]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'TitleTypeImpress', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'TL_Key, TL_Title', TL_Key, TL_Title, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_TitleTypeImpressDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TransferDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_TransferDelete]'))
DROP TRIGGER [dbo].[T_TransferDelete]
GO

CREATE TRIGGER [dbo].[T_TransferDelete]
   ON [dbo].[Transfer]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Transfer', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'TF_Key, TF_Name', TF_Key, TF_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_TransferDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TransportDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_TransportDelete]'))
DROP TRIGGER [dbo].[T_TransportDelete]
GO

CREATE TRIGGER [dbo].[T_TransportDelete]
   ON [dbo].[Transport]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'Transport', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'TR_Key, TR_Name', TR_Key, TR_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_TransportDelete.sql */
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
--<VERSION>9.2.1</VERSION>
--<DATE>2014-04-07</DATE>

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
			or (ISNULL(@O_DLSubCode2,0) != ISNULL(@N_DLSubCode2,0) and ISNULL(@N_DLSVKey,0) not in (1,3)
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
					if (@N_DLSVKey = 3 or @N_DLSVKey=8) --для проживания отдельная ветка
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
				if (@N_DLSVKey=3 or @N_DLSVKey=8) --для проживания отдельная ветка
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
			IF (@N_DLSVKey = 3 OR @N_DLSVKey = 8)
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
					IF (@N_DLSVKey = 3 OR (@N_DLSVKey = 8 AND @N_DLSubcode1 is not null AND @N_DLSubcode1!=0))
						SELECT @HRIsMain = HR_MAIN, @RMKey = HR_RMKEY, @RCKey = HR_RCKEY, @ACKey = HR_ACKEY, @RMPlacesMain = RM_NPlaces, 
						@RMPlacesEx = RM_NPlacesEx, @ACPlacesMain = ISNULL(AC_NRealPlaces, 0), @ACPlacesEx = ISNULL(AC_NMenExBed, 0), 
						@ACPerRoom = ISNULL(AC_PerRoom, 0)
						FROM HotelRooms, Rooms, AccmdMenType
						WHERE HR_Key = @N_DLSubcode1
							AND RM_Key = HR_RMKEY
							AND AC_KEY = HR_ACKEY
					ELSE
						SELECT @HRIsMain = HR_MAIN, @RMKey = HR_RMKEY, @RCKey = HR_RCKEY, @ACKey = HR_ACKEY, @RMPlacesMain = RM_NPlaces, 
						@RMPlacesEx = RM_NPlacesEx, @ACPlacesMain = ISNULL(AC_NRealPlaces, 0), @ACPlacesEx = ISNULL(AC_NMenExBed, 0), 
						@ACPerRoom = ISNULL(AC_PerRoom, 0)
						FROM HotelRooms, Rooms, AccmdMenType
						WHERE HR_Key = (select top 1 DL_SUBCODE1 from Dogovorlist dl1
										where DL_SVKEY=3
										and DL_DGCOD=(select top 1 DL_DGCOD from Dogovorlist dl2
														where DL_KEY=@DLKey and DL1.DL_CODE=DL2.DL_CODE))
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
/* begin T_VisaDocumentsDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_VisaDocumentsDelete]'))
DROP TRIGGER [dbo].[T_VisaDocumentsDelete]
GO

CREATE TRIGGER [dbo].[T_VisaDocumentsDelete]
   ON [dbo].[VisaDocuments]
   AFTER DELETE
AS 
BEGIN
	--<VERSION>9.2.20.12</VERSION>
	--<DATE>2014-04-14</DATE>

	if @@ROWCOUNT > 0 and APP_NAME() not like '%Master%Tour%' and dbo.mwReplIsSubscriber() <= 0
	begin
		declare @nHiId int
		
		insert into dbo.History with(rowlock) (HI_DGCOD, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_Type, HI_MessEnabled, HI_OAId, HI_USERID)
		values ('', GETDATE(), SYSTEM_USER, APP_NAME(), 'DEL', 'VisaDocuments', 0, 400000, 0)
		set @nHiId = SCOPE_IDENTITY()
		
		insert into dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_IntValueOld, HD_ValueOld, HD_Invisible)
		select @nHiId, 400000, '', 'VD_ID, VD_Name', VD_ID, VD_Name, 1 from DELETED
	end
END
GO


/*********************************************************************/
/* end T_VisaDocumentsDelete.sql */
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

/*********************************************************************/
/* begin DropForeignKeyConstraintsOnSubscriber.sql */
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
/* end DropForeignKeyConstraintsOnSubscriber.sql */
/*********************************************************************/
-- =====================   Обновление версии БД. 9.2.20.12 - номер версии, 2014-04-30 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.12', st_moduledate = convert(datetime, '2014-04-30', 120),  st_financeversion = '9.2.20.12', st_financedate = convert(datetime, '2014-04-30', 120)
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
	SET SS_ParmValue='2014-04-30' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO