/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 04.04.2014 15:09 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.10'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.11'

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
/* begin (2014.03.28)_ALTER_PROCEDURE_DogovorMonitor.sql */
/*********************************************************************/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DogovorMonitor]
--<VERSION>2009.2.20.11</VERSION>
--<DATE>2014-03-28</DATE>
	@dtStartDate datetime,			-- начальная дата просмотра изменений
	@dtEndDate datetime,			-- конечная дата просмотра изменений
	@nCountryKey int,				-- ключ страны
	@nCityKey int,					-- ключ города
	@nDepartureCityKey int,			-- ключ города вылета
	@nCreatorKey int,				-- ключ создателя
	@nOwnerKey int,					-- ключ ведущего менеджера
	@nViewProceed smallint,			-- не показывать обработанные: 0 - показывать, 1 - не показывать
	@sFilterKeys varchar(255),		-- ключи выбранных фильтров
	@nFilialKey int,				-- ключ филиала
	@nBTKey int,					-- ключ типа бронирования: -1 - все, 0 - офис, 1 - онлайн
	@sLang varchar(10)				-- язык (если en, селектим поля NameLat, а не Name)	       
AS
BEGIN

CREATE TABLE #DogovorMonitorTable
(
	DM_CreateDate datetime, -- DM_HistoryDate
	DM_FirstProcDate datetime, -- NEW
	DM_LastProcDate datetime, -- DM_ProcDate
	DM_DGCODE nvarchar(10),
	DM_CREATOR nvarchar(25),
	DM_TurDate datetime,
	DM_TurName nvarchar(160),
	DM_PartnerName nvarchar(80),
	DM_FilterName nvarchar(1024),
	DM_NotesCount int,
	DM_PaymentStatus nvarchar(4),
	DM_IsBilled bit,
	DM_MessageCount int,
    DM_MessageCountRead int,
	DM_MessageCountUnRead int,
	DM_ParnerMessageCount int,					-- Kirillov 24081: подсчет значений прочитанных/не прочитанных сообщений от партнеров
    DM_ParnerMessageCountRead int,				-- Kirillov 24081: подсчет значений прочитанных/не прочитанных сообщений от партнеров
	DM_ParnerMessageCountUnRead int,			-- Kirillov 24081: подсчет значений прочитанных/не прочитанных сообщений от партнеров
	DM_AnnulReason varchar(60),
	DM_AnnulDate datetime,
	DM_PriceToPay money,
	DM_Payed money,
	DM_OrderStatus varchar(20)
)

CREATE TABLE #TempTable
(
	#dogovorCreateDate datetime,
	#lastDogovorActionDate datetime,
	#sDGCode varchar(10),
	#sCreator varchar(25),
	#dtTurDate datetime,
	#sTurName nvarchar(160),
	#sPartnerName nvarchar(80),
	#dgKey int,
	#sPaymentStatus nvarchar(4),
	#AnnulReason varchar(60),
	#PriceToPay money,
	#Payed money
)

declare @nObjectAliasFilter int, @sFilterType varchar(3)

DECLARE @dogovorCreateDate datetime, @lastDogovorActionDate datetime -- @dtHistoryDate
declare @sDGCode varchar(10), @nDGKey int
declare @sCreator varchar(25), @dtTurDate datetime, @sTurName varchar(160)
declare @sPartnerName varchar(80), @sFilterName varchar(255), @nHIID int
declare @sHistoryMod varchar(3), @sPaymentStatus as varchar(4)
declare @AnnulReason AS varchar(60), @AnnulDate AS datetime, @PriceToPay AS money, @Payed AS money

set @sHistoryMod = 'DMP'

declare @nFilterKey int, @nLastPos int

while len(@sFilterKeys) > 0
begin
	set @nLastPos = 0
	set @nLastPos = charindex(',', @sFilterKeys, @nLastPos)
	if @nLastPos = 0
		set @nLastPos = len(@sFilterKeys) + 1
	
	set @nFilterKey = cast(substring(@sFilterKeys, 0, @nLastPos) as int)
	if @nLastPos <> len(@sFilterKeys) + 1
		set @sFilterKeys = substring(@sFilterKeys, @nLastPos + 1, len(@sFilterKeys) - @nLastPos)
	else
		set @sFilterKeys = ''
	
	select @sFilterName = DS_Value from Descriptions where DS_KEY = @nFilterKey


	declare filterCursor cursor local fast_forward for
	select OF_OAId, OF_Type
	from ObjectAliasFilters
	where OF_DSKey = @nFilterKey
	order by OF_OAId
	
	open filterCursor
	fetch next from filterCursor into @nObjectAliasFilter, @sFilterType
	while(@@fetch_status = 0)
	begin
		
		declare @sql varchar(max)

		set @sql = N'insert into #TempTable
				select DISTINCT 
				(SELECT MIN(HI_DATE) FROM history h2 WHERE h2.HI_DGCOD = DG_CODE) AS DOGOVOR_CREATE_DATE, 
				(SELECT MAX(HI_DATE) FROM history h2 WHERE h2.HI_DGCOD = DG_CODE) AS LAST_DOGOVOR_ACTION_DATE, 
				DG_CODE, ISNULL(US_FullName,''''), DG_TurDate, TL_NAME, PR_NAME, DG_KEY,
				CASE
					WHEN DG_PRICE = 0 AND DG_PAYED = DG_PRICE THEN ''OK''
					WHEN DG_PAYED = 0 THEN ''NONE''
					WHEN DG_PAYED < DG_PRICE THEN ''LOW''
					WHEN DG_PAYED = DG_PRICE THEN ''OK''
					WHEN DG_PAYED > DG_PRICE THEN ''OVER''
					ELSE '''' 
				END AS DM_PAYMENTSTATUS, AR_Name, 
				CASE
					WHEN DG_PDTTYPE = 1 THEN DG_PRICE + DG_DISCOUNTSUM
					ELSE DG_PRICE					
				END AS DM_PriceToPay, DG_PAYED
			from dogovor with(nolock) 
			join  history with(nolock) on HI_DGCOD = DG_CODE
			join historydetail with(nolock) on HI_ID = HD_HIID
			join  TurList with(nolock) on TL_KEY = DG_TRKEY
			join Partners with(nolock) on PR_KEY = DG_PARTNERKEY 
			join AnnulReasons with(nolock) on AR_Key = DG_ARKEY
			left join userlist with(nolock) on US_KEY = DG_CREATOR
			where 
				HI_DATE BETWEEN ''' + convert(varchar, @dtStartDate, 120) + ''' and dateadd(day, 1, ''' + convert(varchar, @dtEndDate, 120) + ''') and
				((' + str(@nCountryKey) + ' < 0 and DG_CNKEY in (select CN_KEY from Country with(nolock))) OR (' + str(@nCountryKey) + ' >= 0 and DG_CNKEY = ' + str(@nCountryKey) + ')) and
				(' + str(@nCityKey) + ' < 0 OR DG_CTKEY = ' + str(@nCityKey) + ') and
				(' + str(@nDepartureCityKey) + ' < 0 OR DG_CTDepartureKey = ' + str(@nDepartureCityKey) + ') and
				(' + str(@nCreatorKey) + ' < 0 OR DG_CREATOR = ' + str(@nCreatorKey) + ') and
				(' + str(@nOwnerKey) + ' < 0 OR DG_OWNER = ' + str(@nOwnerKey) + ') and
				(' + str(@nFilialKey) + ' < 0 OR DG_FILIALKEY = ' + str(@nFilialKey) + ') and
				(' + str(@nBTKey) + ' < 0 OR (' + str(@nBTKey) + ' = 0 AND DG_BTKEY is NULL) OR DG_BTKEY = ' + str(@nBTKey) + ')'
				
-----------------------------------------------------------------------------------------------
-- MEG00037288 06.09.2011 Kolbeshkin: добавил алиасы 41-43 для проверки корректности путевки --
-----------------------------------------------------------------------------------------------
		DECLARE @sNotAnnuled varchar(max)
		SET @sNotAnnuled = ' and DG_TURDATE <> ''1899-12-30 00:00:00.000'' '
		SET @sql = @sql + 
		CASE 
		WHEN (@nObjectAliasFilter = 41) -- Путевка без услуг
			THEN ' and not exists (select 1 from dogovorlist where dl_dgkey = dg_key)' + @sNotAnnuled
		WHEN (@nObjectAliasFilter = 42) -- Путевка без туристов
			THEN ' and not exists (select 1 from Turist where TU_DGKEY = DG_KEY)' + @sNotAnnuled
		WHEN (@nObjectAliasFilter = 43) -- Услуги с непривязанными туристами
			THEN ' and exists (select 1 from dogovorlist where dl_dgkey = dg_key and not exists (select 1 from TuristService where tu_dlkey = dl_key))' + @sNotAnnuled
		--o.omelchenko 10391 добавила фильтр по новым сообщениям пришедшым из веба
		-- Kirillov 19267 Заменил тип сообщения с WWW на MTM
		WHEN (@nObjectAliasFilter = 12005) -- новые сообщения от агенств
		     THEN ' and DG_CODE in (select distinct  HI_DGCOD from History
					where HI_MessEnabled >=2
					and HI_MOD like ''MTM'' 
					and HI_DATE BETWEEN ''' + convert(varchar, @dtStartDate, 120) + ''' and dateadd(day, 1, ''' + convert(varchar, @dtEndDate, 120) + ''') ) '
		-- Kirillov 24081: добавил новый фильтр по переписки с партнерами
		WHEN (@nObjectAliasFilter = 12006) -- Новые сообщения от партнеров
		     THEN ' and DG_CODE in (select distinct  HI_DGCOD from History
					where HI_MessEnabled >=2
					and HI_MOD like ''MFP'' 
					and HI_DATE BETWEEN ''' + convert(varchar, @dtStartDate, 120) + ''' and dateadd(day, 1, ''' + convert(varchar, @dtEndDate, 120) + ''') ) '
		
		--------- Отсутствуют обязательные(неудаляемые) услуги решено пока не делать, потому что нет прямой связи DogovorList c TurService
		--WHEN (@nObjectAliasFilter = 44) -- Отсутствуют обязательные(неудаляемые) услуги
		--	THEN ' and ((select (
		--	(select COUNT(1) from TurService ts where TS_TRKEY=dg.DG_TRKEY and TS_ATTRIBUTE % 2 = 0) -- Кол-во неудаляемых услуг в туре
		--	-
		--	(select COUNT(1) from Dogovorlist dl join TurService ts on -- Кол-во услуг попавших в путевку из неудаляемых в туре
		--	(ts.TS_TRKEY = dg.DG_TRKEY and ts.TS_ATTRIBUTE % 2 = 0
		--	and dl.DL_SVKEY = ts.TS_SVKEY and dl.DL_CODE = ts.TS_CODE
		--	) where dl.DL_DGKEY = dg.DG_Key and dl.DL_TRKEY = dg.DG_TRKEY )))
		--	> 0) ' 
		ELSE 
			 ' and (HD_OAId = ' + str(@nObjectAliasFilter) + ') 
			 and (''' + @sFilterType + '''= '''' OR HI_MOD = ''' + @sFilterType + ''')'
		END
		
-------------------------------------------------------------------------------------
-- MEG00037288 07.09.2011 Kolbeshkin: локализация. Если язык En, селектим поля LAT --
-------------------------------------------------------------------------------------
		IF @sLang like 'en'
		BEGIN
		set @sql = REPLACE(@sql,'US_FullName','US_FullNameLat')
		set @sql = REPLACE(@sql,'TL_NAME','TL_NAMELAT')
		set @sql = REPLACE(@sql,'PR_NAME','PR_NAMEENG')
		set @sql = REPLACE(@sql,'AR_Name','AR_NameLat')
		END
		--print @sql
		exec (@sql)
		
		declare dogovorsCursor cursor local fast_forward for
		select * from #TempTable

		--нашли путевки
		open dogovorsCursor
		fetch next from dogovorsCursor into @dogovorCreateDate, @lastDogovorActionDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @nDGKey, @sPaymentStatus, @AnnulReason, @PriceToPay, @Payed
		while(@@fetch_status = 0)
		begin
			--if not exists (select * from #DogovorMonitorTable where datediff(mi, DM_HistoryDate, @dtHistoryDate) = 0 and DM_DGCODE = @sDGCode and DM_FilterName LIKE @sFilterName)
			--begin
				DECLARE @firstDogovorProcessDate datetime 
				DECLARE @lastDogovorProcessDate datetime -- @hiDate

				SET @firstDogovorProcessDate = (select MIN(HI_DATE) from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod)
				SET @lastDogovorProcessDate = (select MAX(HI_DATE) from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod)

--				--select @hiDate = HI_DATE from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod
--				if exists (select HI_DATE from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod)
--					select @hiDate = HI_DATE from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod
--				else
--					set @hiDate = NULL


				------ Получение даты тура до аннуляции ------
				IF (@dtTurDate = '12/30/1899')
				BEGIN
					SELECT @dtTurDate = DG_TURDATEBFRANNUL
					FROM Dogovor
					WHERE DG_Code = @sDGCode
				END
				----------------------------------------------

				SET @AnnulDate = NULL;
				------ Получение даты аннуляции ------
				SELECT @AnnulDate = History.HI_DATE
				FROM HistoryDetail
				JOIN History 
					ON HI_ID = HD_HIID
				WHERE HistoryDetail.HD_Alias = 'DG_Annulate' AND History.HI_DgCod = @sDGCode
				--------------------------------------
				
				DECLARE @notesCount int 
				SET @notesCount =0
				SELECT @notesCount = COUNT(HI_TEXT) FROM HISTORY
				WHERE HI_DGCOD = @sDGCode AND HI_MOD = 'MTM'

				DECLARE @isBilled bit
				SET @isBilled = 0
				IF EXISTS(SELECT AC_KEY FROM ACCOUNTS WHERE AC_DGCOD = @sDGCode)
					SET @isBilled = 1

				DECLARE @messageCount int , @MessageCountRead int, @MessageCountUnRead int 
				SET @messageCount = 0
				SET @MessageCountRead  = 0
				SET @MessageCountUnRead  = 0
				SELECT @messageCount = COUNT(HI_TEXT)
			          ,@MessageCountRead = SUM(case when HI_MessEnabled <= 1 then 1 else 0 end)
			          ,@MessageCountUnRead = SUM(case when HI_MessEnabled >= 2 then 1 else 0 end)
			    FROM HISTORY
				-- Kirillov 19267 Заменил тип сообщения с WWW на MTM
				WHERE HI_DGCOD = @sDGCode AND HI_MOD = 'MTM'
				--AND HI_TEXT NOT LIKE 'От агента: %' -- notes from web (copies of 'WWW' moded notes)
				
				-- Kirillov 24081: подсчет значений прочитанных/не прочитанных сообщений от партнеров
				DECLARE @PartnerMessageCount int , @PartnerMessageCountRead int, @PartnerMessageCountUnRead int 
				SET @PartnerMessageCount = 0
				SET @PartnerMessageCountRead  = 0
				SET @PartnerMessageCountUnRead  = 0
				SELECT @PartnerMessageCount = COUNT(HI_TEXT)
			          ,@PartnerMessageCountRead = SUM(case when HI_MessEnabled <= 1 then 1 else 0 end)
			          ,@PartnerMessageCountUnRead = SUM(case when HI_MessEnabled >= 2 then 1 else 0 end)
			    FROM HISTORY
				WHERE HI_DGCOD = @sDGCode AND HI_MOD = 'MFP' 
				
				--узнаем статус путевки
				DECLARE @orderStatus varchar(20);
				select @orderStatus  = case when @sLang='en' then o.OS_NameLat else o.OS_NAME_RUS end
				from Order_Status o
				left join Dogovor d on d.DG_SOR_CODE=o.OS_CODE
				where d.DG_Key = @nDGKey

				DECLARE @includeRecord bit
				SET @includeRecord = 0

				if (@nViewProceed = 0) OR (@lastDogovorProcessDate IS NULL)
				begin
					--insert into #DogovorMonitorTable (DM_HistoryDate, DM_ProcDate, DM_DGCODE, DM_CREATOR, DM_TurDate, DM_TurName, DM_PartnerName, DM_FilterName, DM_NotesCount, DM_PaymentStatus, DM_IsBilled, DM_MessageCount)
					--values (@dtHistoryDate, @hiDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @sFilterName, @notesCount, @sPaymentStatus, @isBilled, @messageCount)
					SET @includeRecord = 1
				end
				else
				begin
					--if @dtHistoryDate > @hiDate
					if @lastDogovorActionDate > @lastDogovorProcessDate
					begin
						--insert into #DogovorMonitorTable (DM_HistoryDate, DM_ProcDate, DM_DGCODE, DM_CREATOR, DM_TurDate, DM_TurName, DM_PartnerName, DM_FilterName, DM_NotesCount, DM_PaymentStatus, DM_IsBilled, DM_MessageCount) 
						--values (@dtHistoryDate, @hiDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @sFilterName, @notesCount, @sPaymentStatus, @isBilled, @messageCount)
						SET @includeRecord = 1
					end
				end
              
				-------------------
				IF @includeRecord = 1
				BEGIN
					IF EXISTS (SELECT dm_dgcode FROM #DogovorMonitorTable WHERE dm_dgcode = @sDGCode)
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM #DogovorMonitorTable WHERE dm_dgcode = @sDGCode AND dm_filtername LIKE '%' + @sFilterName + '%')
							UPDATE #DogovorMonitorTable SET DM_FilterName = DM_FilterName + ', ' + @sFilterName WHERE dm_dgcode = @sDGCode
					END
					ELSE
					BEGIN
						INSERT INTO #DogovorMonitorTable
						VALUES (@dogovorCreateDate, @firstDogovorProcessDate, @lastDogovorProcessDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @sFilterName, @notesCount, @sPaymentStatus, @isBilled, @messageCount, @MessageCountRead , @MessageCountUnRead, @PartnerMessageCount, @PartnerMessageCountRead , @PartnerMessageCountUnRead, @AnnulReason, @AnnulDate, @PriceToPay, @Payed,@orderStatus);
					END
				END
				-------------------

			--end
			fetch next from dogovorsCursor into @dogovorCreateDate, @lastDogovorActionDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @nDGKey, @sPaymentStatus, @AnnulReason, @PriceToPay, @Payed
		end
			
		close dogovorsCursor
		deallocate dogovorsCursor
		delete from #TempTable

		fetch next from filterCursor into @nObjectAliasFilter, @sFilterType
	end

	close filterCursor
	deallocate filterCursor
end
	SELECT *
	FROM #DogovorMonitorTable
	ORDER BY DM_CreateDate
	
	DROP TABLE #TempTable
	DROP TABLE #DogovorMonitorTable

END
GO

/*********************************************************************/
/* end (2014.03.28)_ALTER_PROCEDURE_DogovorMonitor.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.03.28)_Insert_ObjectAliases.sql */
/*********************************************************************/
IF (NOT EXISTS (SELECT * FROM ObjectAliases WHERE OA_Id = 12005))
	BEGIN
		INSERT INTO ObjectAliases VALUES (12005,'Reservation_new_messages_customer','Новые сообшения от покупателя','New messages from customer',49,NULL)
	END
ELSE
	BEGIN
		UPDATE ObjectAliases SET OA_Alias = 'Reservation_new_messages_customer', OA_Name = 'Новые сообшения от покупателя', OA_NameLat = 'New messages from customer' WHERE OA_Id = 12005
	END
GO
IF (NOT EXISTS (SELECT * FROM ObjectAliases WHERE OA_Id = 12006))
	BEGIN
		INSERT INTO ObjectAliases VALUES (12006,'Reservation_new_messages_partner','Новые сообшения от партнера','New messages from partner',49,NULL)
	END
ELSE
	BEGIN
		UPDATE ObjectAliases SET OA_Alias = 'Reservation_new_messages_partner', OA_Name = 'Новые сообшения от партнера', OA_NameLat = 'New messages from partner' WHERE OA_Id = 12006
	END
GO


/*********************************************************************/
/* end (2014.03.28)_Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckingQuotaForDay.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckingQuotaForDay]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckingQuotaForDay]
GO

CREATE FUNCTION [dbo].[mwCheckingQuotaForDay]
(	
	--<VERSION>9.2.21.03</VERSION>
	--<DATE>2014-04-02</DATE>
	-- функция проверки квот на день
	@tmpQuotas CheckQuotasSourceTable readonly, -- таблица подходящих квот на день
	@isFirstDay bit -- первый ли день предоставления услуги (день заезда)
	)
returns @resultTable table(   -- возвращаем параметры приоритетной квоты
	qt_state smallint,        -- 0 - стоп-сейл
							  -- 1 - запрет на заезд
							  -- 2 - нет мест (@noPlacesResult)
							  -- 3 - релиз-период (@expiredReleaseResult)
							  -- 4 - квота отсутствует
							  -- 5 - есть свободные места
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
	DECLARE @isStopSale smallint, @isNotCheckin smallint, @isNoPlaces smallint, @isReleasePeriod smallint, @isYesPlaces smallint
	SET @isStopSale = 0
	SET @isNotCheckin = 1
	SET @isNoPlaces = 2
	SET @isReleasePeriod = 3
	SET @isYesPlaces = 5
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
		UPDATE @resultTable SET qt_state = @isNotCheckin
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
/* begin fn_mwCheckQuotasHotelsOnPeriod.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotasHotelsOnPeriod]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotasHotelsOnPeriod]
GO

CREATE FUNCTION [dbo].[mwCheckQuotasHotelsOnPeriod]
(	
	--<VERSION>2009.2.21.8</VERSION>
	--<DATE>2014-04-02</DATE>
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
																	-- 0 - стоп-сейл 
																	-- 1 - запрет на заезд
																    -- 2 - нет мест (@noPlacesResult)
																    -- 3 - релиз-период (@expiredReleaseResult)
																    -- 4 - квота отсутствует
																    -- 5 - есть свободные места
																    -- статусы в порядке уменьшения приоритета													  
	-- константы статусов, для наглядного чтения кода
	DECLARE @isStopSale smallint, @isNotCheckin smallint, @isNoPlaces smallint, @isReleasePeriod smallint, @isNoQuota smallint, @isYesPlaces smallint
	SET @isStopSale = 0
	SET @isNotCheckin = 1
	SET @isNoPlaces = 2
	SET @isReleasePeriod = 3
	SET @isNoQuota = 4
	SET @isYesPlaces = 5
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
			IF (@currentState in (@isStopSale, @isNotCheckin))
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
		
		-- если на приоритетном объекте квотирования стоит запрет заезда, 
		-- то проверяем нет ли такой же квоты, но с другим типом квоты, еще, 
		-- если нет, то выходим, т.к менее приоритетную квоту проверять не надо
		IF (@currentGlobalState = @isNotCheckin AND 
			NOT EXISTS(SELECT TOP 1 1 
				FROM @tmpQuotas 
				WHERE qt_subcode1 = @qoSubcode1
				AND qt_subcode2 = @qoSubcode2
				AND qt_prkey = @qtPrKey
				AND (qt_type <> @qdType
					or (qt_qoid = @qoId and qt_long <> @qpLong)
					or (qt_qoid = @qoId and qt_agent <> @qdAgentKey))))
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
	
	-- если на квоте наступил стоп-сейл или стоит запрет заезда
	IF EXISTS(SELECT TOP 1 1 FROM @StatusTable WHERE quotaState in (@isStopSale, @isNotCheckin))
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
/* begin INDEX_ADD_X_Mappings_TblID_IntKey_ImpID.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Mappings]') AND name = N'X_Mappings_TblID_IntKey_ImpID')
DROP INDEX [X_Mappings_TblID_IntKey_ImpID] ON [dbo].[Mappings] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [X_Mappings_TblID_IntKey_ImpID] ON [dbo].[Mappings] 
(
	[MP_TableID] ASC,
	[MP_IntKey] ASC,
	[MP_ImportIdentificator] ASC
)
INCLUDE ( [MP_Key],
[MP_CharKey],
[MP_Value],
[MP_StrValue],
[MP_CreateDate],
[MP_PRKey]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/*********************************************************************/
/* end INDEX_ADD_X_Mappings_TblID_IntKey_ImpID.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ALTER_X_TURISTSERVICED_TuristService.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TuristService]') AND name = N'X_TURISTSERVICED')
DROP INDEX [X_TURISTSERVICED] ON [dbo].[TuristService] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [X_TURISTSERVICED] ON [dbo].[TuristService] 
(
	[TU_DLKEY] ASC
)
INCLUDE ( [TU_TUKEY]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/*********************************************************************/
/* end INDEX_ALTER_X_TURISTSERVICED_TuristService.sql */
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
declare @isUpdateOnly bit
set @isUpdateOnly = 1
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

							set @isUpdateOnly = 0
						end
					END
					ELSE
					BEGIN
						delete from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
						set @isUpdateOnly = 0
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
		if (@nIsEnabled = 1 and (@isUpdateOnly = 0 or dbo.mwReplIsPublisher() = 0))
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
	, @nUseHolidayRule smallint
	, @isUpdateOnly bit output'
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
	, @isUpdateOnly output
	
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
		if (@isUpdateOnly = 1 and dbo.mwReplIsPublisher() > 0)
		begin
			INSERT INTO mwReplTours(rt_trkey, rt_tokey, rt_date, rt_calckey, rt_updateOnlinePrices)
			SELECT TO_TRKey, TO_Key, GETDATE(), @nCalculatingKey, 2
			FROM tp_tours with(nolock)
			WHERE TO_Key = @nPriceTourKey
		end
		else begin
			if (@isPriceListPluginRecalculation = 0)
				EXEC FillMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
			else
				EXEC FillMasterWebSearchFields @nPriceTourKey, null
		end
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
/* begin sp_DogListToQuotas.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogListToQuotas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogListToQuotas]
GO

CREATE PROCEDURE [dbo].[DogListToQuotas]
(
	--<VERSION>9.20.10</VERSION>
	--<DATA>31.03.2014</DATA>
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
/* begin sp_GetPermissions.sql */
/*********************************************************************/
DROP PROCEDURE [dbo].[GetPermissions]
GO
Create PROCEDURE [dbo].[GetPermissions] 
  (
	@sTable nvarchar(50) = null,
	@nSelect int  = null output,
	@nInsert int  = null output,
	@nUpdate int  = null output,
	@nDelete int  = null output
)
AS


Declare @sName nvarchar(50)
Declare @nPermissions int
Select @sName = Name FROM dbo.sysobjects WHERE id = object_id(@sTable ) and OBJECTPROPERTY(id, N'IsView') = 1
If @sName is not null
	begin
	if exists (Select Name FROM dbo.sysobjects WHERE id = object_id('tbl_' + @sTable ) and OBJECTPROPERTY(id, N'IsTable') = 1)
		set @sTable = 'tbl_' + @sTable
	end
Select @nPermissions = PERMISSIONS (OBJECT_ID (@sTable))

--SELECT - 1
--UPDATE - 2
--INSERT - 8
--DELETE - 16
if (@nPermissions is not null)
begin
	Set @nSelect = @nPermissions & 1
	Set @nInsert = ( @nPermissions & 8 ) / 8
	Set @nUpdate = ( @nPermissions & 2 ) / 2
	Set @nDelete = ( @nPermissions & 16 ) / 16
end
else
begin
	Set @nSelect = 0
	Set @nInsert = 0
	Set @nUpdate = 0
	Set @nDelete = 0
end

Return  0

GO
grant exec on [dbo].[GetPermissions] to public
go
/*********************************************************************/
/* end sp_GetPermissions.sql */
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
			ptKey bigint primary key,
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
/* begin sp_ReCalculateCosts_MarginMigrateTRKey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculateCosts_MarginMigrateTRKey]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculateCosts_MarginMigrateTRKey]
GO

CREATE PROCEDURE [dbo].[ReCalculateCosts_MarginMigrateTRKey]
		-- хранимка переносит цены из таблицы TP_PriceActualDate в TP_PriceComponents
		-- <version>9.2.19</version>
		-- <data>2014-04-02</data>
		(@TrKey int = null,
		@MinValue smallint = null,
		@JobID smallint = null)
AS
BEGIN
	SET ARITHABORT ON;
	SET DATEFIRST 1;
	set nocount on;
	
	declare @beginTime datetime
	set @beginTime = getDate()	
	
	/*таблица первоночальной выборки*/
	create table #tableForMigrate
	(
		TMAD_Id int,
		TMAD_TRKey int,
		TMAD_DateCheckIn datetime,
		TMAD_SvKey int,
		TMAD_Long smallint,
		TMAD_Percent money,
		TMAD_IsCommission bit
	)
	
	create nonclustered index IX_tableForMigrate ON #tableForMigrate 
	(TMAD_TRKey, TMAD_DateCheckIn, TMAD_Long, TMAD_SvKey) include(TMAD_IsCommission, TMAD_Percent)
	
	declare @count int, @DateCheckInMin datetime, @DateCheckInMax datetime, @Return smallint
	
	if @TrKey is null 
	Begin
		if @MinValue = 1
		begin
			select TOP 1 @TrKey=TMAD_TRKey, @count=COUNT(*)
			from TP_TourMarginActualDate with(nolock)
			where TMAD_NeedApply = 2
				and not exists (select 1 from Debug with(nolock) where db_Mod='MMI' and db_n1=TMAD_TRKey)
			group by TMAD_TRKey
			order by 2
		end
		else
		begin
			select TOP 1 @TrKey=TMAD_TRKey, @count=COUNT(*)
			from TP_TourMarginActualDate with(nolock)
			where TMAD_NeedApply = 2
				and not exists (select 1 from Debug with(nolock) where db_Mod='MMI' and db_n1=TMAD_TRKey)
			group by TMAD_TRKey
			order by 2 desc
		end
	end
	else
		select @count=COUNT(*) from TP_TourMarginActualDate with(nolock) where TMAD_NeedApply = 2 and TMAD_TRKey=@TrKey

	if @TrKey is null 
		print 'нет записей для переноса'
	begin
		if @TrKey is not null
			insert into Debug (db_Mod, db_n1, db_n2) values ('MMI',@TrKey, @JobID)
		
		insert into #tableForMigrate (TMAD_Id, TMAD_TRKey, TMAD_DateCheckIn, TMAD_SvKey, TMAD_Long, TMAD_Percent, TMAD_IsCommission)
		select TOP 5000 TMAD_Id, TMAD_TRKey, TMAD_DateCheckIn, TMAD_SvKey, TMAD_Long, TMAD_Percent, TMAD_IsCommission
		from TP_TourMarginActualDate with(nolock)
		where TMAD_NeedApply = 2
			and TMAD_TRKey = @TrKey --and TMAD_DateCheckIn=@DateCheckIn
		
		select @DateCheckInMin = MIN(TMAD_DateCheckIn), @DateCheckInMax = MAX(TMAD_DateCheckIn) from #tableForMigrate 
		
		print 'TourKey: ' + CAST(@TrKey as varchar(100)) + ' Дата c: ' + convert(varchar, @DateCheckInMin, 111) + ' Дата по: ' + convert(varchar, @DateCheckInMax, 111)
		
		print 'выборка записей из очереди: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()

		set @Return = 0
		
		/*перенесем изменения в основную таблицу*/
		-- разобьем апдейт по кортежам
		
		create table #tempPCIdtable
		(
			xPCId bigint,
			xIsCommission bit,
			xPercent money
		)
		
		-- %%%%%%%%%%%%%%%%%%% Кортеж 1 %%%%%%%%%%%%%%%%%%%%%%%
		insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
		select PC_Id, TMAD_IsCommission, TMAD_Percent
		from #tableForMigrate 
		inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
		where PC_TourDate = TMAD_DateCheckIn
		and PC_Days = TMAD_Long
		and SVKey_1 = TMAD_SvKey
		and PC_TRKey = @TrKey

		if @TrKey is not null
			update Debug set db_n3 = 0 where db_Mod='MMI' and db_n1=@TrKey

		if exists (select top 1 1 from #tempPCIdtable)
		begin
			update pc
			set	PC_DateLastChangeMargin = getdate(), 
				PC_UpdateDate = getdate(),
				CommissionOnly_1 = xIsCommission,
				MarginPercent_1 = xPercent,
				PC_State = 1
			from #tempPCIdtable
			inner join TP_PriceComponents pc on PC_Id = xPCId
			WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
					and PC_TRKey = @TrKey		
			
			truncate table #tempPCIdtable
		end
		-- %%%%%%%%%%%%%%%%%%% Кортеж 1 %%%%%%%%%%%%%%%%%%%%%%%
		if @TrKey is not null
			update Debug set db_n3 = 1 where db_Mod='MMI' and db_n1=@TrKey
		
		-- %%%%%%%%%%%%%%%%%%% Кортеж 2 %%%%%%%%%%%%%%%%%%%%%%%
		insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
		select PC_Id, TMAD_IsCommission, TMAD_Percent
		from #tableForMigrate
		inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
		where PC_TourDate = TMAD_DateCheckIn
		and PC_Days = TMAD_Long
		and SVKey_2 = TMAD_SvKey
		and PC_TRKey = @TrKey
		
		if exists (select top 1 1 from #tempPCIdtable)
		begin
			update pc
			set	PC_DateLastChangeMargin = getdate(), 
				PC_UpdateDate = getdate(),
				CommissionOnly_2 = xIsCommission,
				MarginPercent_2 = xPercent,
				PC_State = 1
			from #tempPCIdtable 
			inner join TP_PriceComponents pc on PC_Id = xPCId
			WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
					and PC_TRKey = @TrKey		
						
			truncate table #tempPCIdtable
		end
		-- %%%%%%%%%%%%%%%%%%% Кортеж 2 %%%%%%%%%%%%%%%%%%%%%%%
		
		-- %%%%%%%%%%%%%%%%%%% Кортеж 3 %%%%%%%%%%%%%%%%%%%%%%%
		insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
		select PC_Id, TMAD_IsCommission, TMAD_Percent
		from #tableForMigrate 
		inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
		where PC_TourDate = TMAD_DateCheckIn
		and PC_Days = TMAD_Long
		and SVKey_3 = TMAD_SvKey
		and PC_TRKey = @TrKey
		
		if exists (select top 1 1 from #tempPCIdtable)
		begin
			update pc
			set	PC_DateLastChangeMargin = getdate(), 
				PC_UpdateDate = getdate(),
				CommissionOnly_3 = xIsCommission,
				MarginPercent_3 = xPercent,
				PC_State = 1
			from  #tempPCIdtable 
			inner join TP_PriceComponents pc on PC_Id = xPCId
			WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
					and PC_TRKey = @TrKey		
			
			truncate table #tempPCIdtable
		end
		-- %%%%%%%%%%%%%%%%%%% Кортеж 3 %%%%%%%%%%%%%%%%%%%%%%%
		
		if @TrKey is not null
			update Debug set db_n3 = 3 where db_Mod='MMI' and db_n1=@TrKey
	
		-- %%%%%%%%%%%%%%%%%%% Кортеж 4 %%%%%%%%%%%%%%%%%%%%%%%
		insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
		select PC_Id, TMAD_IsCommission, TMAD_Percent
		from #tableForMigrate
		inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
		where PC_TourDate = TMAD_DateCheckIn
		and PC_Days = TMAD_Long
		and SVKey_4 = TMAD_SvKey
		and PC_TRKey = @TrKey
		
		if exists (select top 1 1 from #tempPCIdtable)
		begin
			update pc
			set	PC_DateLastChangeMargin = getdate(), 
				PC_UpdateDate = getdate(),
				CommissionOnly_4 = xIsCommission,
				MarginPercent_4 = xPercent,
				PC_State = 1
			from #tempPCIdtable
			inner join TP_PriceComponents pc on PC_Id = xPCId
			WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
					and PC_TRKey = @TrKey		
			
			truncate table #tempPCIdtable
		end
		-- %%%%%%%%%%%%%%%%%%% Кортеж 4 %%%%%%%%%%%%%%%%%%%%%%%
		
		-- %%%%%%%%%%%%%%%%%%% Кортеж 5 %%%%%%%%%%%%%%%%%%%%%%%
		insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
		select PC_Id, TMAD_IsCommission, TMAD_Percent
		from #tableForMigrate
		inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
		where PC_TourDate = TMAD_DateCheckIn
		and PC_Days = TMAD_Long
		and SVKey_5 = TMAD_SvKey
		and PC_TRKey = @TrKey
		
		if exists (select top 1 1 from #tempPCIdtable)
		begin
			update pc
			set	PC_DateLastChangeMargin = getdate(), 
				PC_UpdateDate = getdate(),
				CommissionOnly_5 = xIsCommission,
				MarginPercent_5 = xPercent,
				PC_State = 1
			from #tempPCIdtable
			inner join TP_PriceComponents pc on PC_Id = xPCId
			WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
					and PC_TRKey = @TrKey		
			
			truncate table #tempPCIdtable
		end
		-- %%%%%%%%%%%%%%%%%%% Кортеж 5 %%%%%%%%%%%%%%%%%%%%%%%
		

		if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_6 is not null)				
		begin
			-- %%%%%%%%%%%%%%%%%%% Кортеж 6 %%%%%%%%%%%%%%%%%%%%%%%
			insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
			select PC_Id, TMAD_IsCommission, TMAD_Percent
			from #tableForMigrate
			inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
			where PC_TourDate = TMAD_DateCheckIn
			and PC_Days = TMAD_Long
			and SVKey_6 = TMAD_SvKey
			and PC_TRKey = @TrKey
			
			if exists (select top 1 1 from #tempPCIdtable)
			begin
				update pc
				set	PC_DateLastChangeMargin = getdate(), 
					PC_UpdateDate = getdate(),
					CommissionOnly_6 = xIsCommission,
					MarginPercent_6 = xPercent,
					PC_State = 1
				from #tempPCIdtable
				inner join TP_PriceComponents pc on PC_Id = xPCId
				WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
						and PC_TRKey = @TrKey		
				
				truncate table #tempPCIdtable
			end
			-- %%%%%%%%%%%%%%%%%%% Кортеж 6 %%%%%%%%%%%%%%%%%%%%%%%
		end
		else
			set @Return = 1

		if @TrKey is not null
			update Debug set db_n3 = 6 where db_Mod='MMI' and db_n1=@TrKey

		if 	@Return != 1
		begin
			if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_7 is not null)				
			begin
				-- %%%%%%%%%%%%%%%%%%% Кортеж 7 %%%%%%%%%%%%%%%%%%%%%%%
				insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
				select PC_Id, TMAD_IsCommission, TMAD_Percent
				from #tableForMigrate
				inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
				where PC_TourDate = TMAD_DateCheckIn
				and PC_Days = TMAD_Long
				and SVKey_7 = TMAD_SvKey
				and PC_TRKey = @TrKey
				
				if exists (select top 1 1 from #tempPCIdtable)
				begin
					update pc
					set	PC_DateLastChangeMargin = getdate(), 
						PC_UpdateDate = getdate(),
						CommissionOnly_7 = xIsCommission,
						MarginPercent_7 = xPercent,
						PC_State = 1
					from #tempPCIdtable
					inner join TP_PriceComponents pc on PC_Id = xPCId
					WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
							and PC_TRKey = @TrKey		
					
					truncate table #tempPCIdtable
				end
				-- %%%%%%%%%%%%%%%%%%% Кортеж 7 %%%%%%%%%%%%%%%%%%%%%%%
			end
			else
				set @Return = 1
		end

		if 	@Return != 1
		begin
			if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_8 is not null)				
			begin
				-- %%%%%%%%%%%%%%%%%%% Кортеж 8 %%%%%%%%%%%%%%%%%%%%%%%
				insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
				select PC_Id, TMAD_IsCommission, TMAD_Percent
				from #tableForMigrate
				inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
				where PC_TourDate = TMAD_DateCheckIn
				and PC_Days = TMAD_Long
				and SVKey_8 = TMAD_SvKey
				and PC_TRKey = @TrKey
				
				if exists (select top 1 1 from #tempPCIdtable)
				begin
					update pc
					set	PC_DateLastChangeMargin = getdate(), 
						PC_UpdateDate = getdate(),
						CommissionOnly_8 = xIsCommission,
						MarginPercent_8 = xPercent,
						PC_State = 1
					from #tempPCIdtable 
					inner join TP_PriceComponents pc on PC_Id = xPCId
					WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
							and PC_TRKey = @TrKey		
					
					truncate table #tempPCIdtable
				end
				-- %%%%%%%%%%%%%%%%%%% Кортеж 8 %%%%%%%%%%%%%%%%%%%%%%%
			end
			else
				set @Return = 1
		end
		
		if 	@Return != 1
		begin
			if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_9 is not null)				
			begin
				-- %%%%%%%%%%%%%%%%%%% Кортеж 9 %%%%%%%%%%%%%%%%%%%%%%%
				insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
				select PC_Id, TMAD_IsCommission, TMAD_Percent
				from #tableForMigrate 
				inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
				where PC_TourDate = TMAD_DateCheckIn
				and PC_Days = TMAD_Long
				and SVKey_9 = TMAD_SvKey
				and PC_TRKey = @TrKey
				
				if exists (select top 1 1 from #tempPCIdtable)
				begin
					update pc
					set	PC_DateLastChangeMargin = getdate(), 
						PC_UpdateDate = getdate(),
						CommissionOnly_9 = xIsCommission,
						MarginPercent_9 = xPercent,
						PC_State = 1
					from #tempPCIdtable
					inner join TP_PriceComponents pc on PC_Id = xPCId
					WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
							and PC_TRKey = @TrKey		
					
					truncate table #tempPCIdtable
				end
				-- %%%%%%%%%%%%%%%%%%% Кортеж 9 %%%%%%%%%%%%%%%%%%%%%%%
			end
			else
				set @Return = 1
		end

		if @TrKey is not null
			update Debug set db_n3 = 9 where db_Mod='MMI' and db_n1=@TrKey
		
		if 	@Return != 1
		begin
			if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_10 is not null)				
			begin
				-- %%%%%%%%%%%%%%%%%%% Кортеж 10 %%%%%%%%%%%%%%%%%%%%%%%
				insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
				select PC_Id, TMAD_IsCommission, TMAD_Percent
				from #tableForMigrate 
				inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
				where PC_TourDate = TMAD_DateCheckIn
				and PC_Days = TMAD_Long
				and SVKey_10 = TMAD_SvKey
				and PC_TRKey = @TrKey
				
				if exists (select top 1 1 from #tempPCIdtable)
				begin
					update pc
					set	PC_DateLastChangeMargin = getdate(), 
						PC_UpdateDate = getdate(),
						CommissionOnly_10 = xIsCommission,
						MarginPercent_10 = xPercent,
						PC_State = 1
					from #tempPCIdtable 
					inner join TP_PriceComponents pc on PC_Id = xPCId
					WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
							and PC_TRKey = @TrKey		
					
					truncate table #tempPCIdtable
				end
				-- %%%%%%%%%%%%%%%%%%% Кортеж 10 %%%%%%%%%%%%%%%%%%%%%%%
			end
			else
				set @Return = 1
		end
				
		if 	@Return != 1
		begin
			if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_11 is not null)				
			begin
				-- %%%%%%%%%%%%%%%%%%% Кортеж 11 %%%%%%%%%%%%%%%%%%%%%%%
				insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
				select PC_Id, TMAD_IsCommission, TMAD_Percent
				from #tableForMigrate
				inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
				where PC_TourDate = TMAD_DateCheckIn
				and PC_Days = TMAD_Long
				and SVKey_11 = TMAD_SvKey
				and PC_TRKey = @TrKey
				
				if exists (select top 1 1 from #tempPCIdtable)
				begin
					update pc
					set	PC_DateLastChangeMargin = getdate(), 
						PC_UpdateDate = getdate(),
						CommissionOnly_11 = xIsCommission,
						MarginPercent_11 = xPercent,
						PC_State = 1
					from #tempPCIdtable 
					inner join TP_PriceComponents pc on PC_Id = xPCId
					WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
							and PC_TRKey = @TrKey		
					
					truncate table #tempPCIdtable
				end
				-- %%%%%%%%%%%%%%%%%%% Кортеж 11 %%%%%%%%%%%%%%%%%%%%%%%
			end
			else
				set @Return = 1
		end
		
		if 	@Return != 1
		begin
			if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_12 is not null)				
			begin
				-- %%%%%%%%%%%%%%%%%%% Кортеж 12 %%%%%%%%%%%%%%%%%%%%%%%
				insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
				select PC_Id, TMAD_IsCommission, TMAD_Percent
				from #tableForMigrate
				inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
				where PC_TourDate = TMAD_DateCheckIn
				and PC_Days = TMAD_Long
				and SVKey_12 = TMAD_SvKey
				and PC_TRKey = @TrKey
				
				if exists (select top 1 1 from #tempPCIdtable)
				begin
					update pc
					set	PC_DateLastChangeMargin = getdate(), 
						PC_UpdateDate = getdate(),
						CommissionOnly_12 = xIsCommission,
						MarginPercent_12 = xPercent,
						PC_State = 1
					from #tempPCIdtable 
					inner join TP_PriceComponents pc on PC_Id = xPCId
					WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
							and PC_TRKey = @TrKey		
					
					truncate table #tempPCIdtable
				end
				-- %%%%%%%%%%%%%%%%%%% Кортеж 12 %%%%%%%%%%%%%%%%%%%%%%%
			end
			else
				set @Return = 1
		end

		if @TrKey is not null
			update Debug set db_n3 = 12 where db_Mod='MMI' and db_n1=@TrKey
		
		if 	@Return != 1
		begin
			if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_13 is not null)				
			begin
				-- %%%%%%%%%%%%%%%%%%% Кортеж 13 %%%%%%%%%%%%%%%%%%%%%%%
				insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
				select PC_Id, TMAD_IsCommission, TMAD_Percent
				from #tableForMigrate
				inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
				where PC_TourDate = TMAD_DateCheckIn
				and PC_Days = TMAD_Long
				and SVKey_13 = TMAD_SvKey
				and PC_TRKey = @TrKey
				
				if exists (select top 1 1 from #tempPCIdtable)
				begin
					update pc
					set	PC_DateLastChangeMargin = getdate(), 
						PC_UpdateDate = getdate(),
						CommissionOnly_13 = xIsCommission,
						MarginPercent_13 = xPercent,
						PC_State = 1
					from #tempPCIdtable 
					inner join TP_PriceComponents pc on PC_Id = xPCId
					WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
							and PC_TRKey = @TrKey		
					
					truncate table #tempPCIdtable
				end
				-- %%%%%%%%%%%%%%%%%%% Кортеж 13 %%%%%%%%%%%%%%%%%%%%%%%
			end
			else
				set @Return = 1
		end
		
		if 	@Return != 1
		begin
			if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_14 is not null)				
			begin
				-- %%%%%%%%%%%%%%%%%%% Кортеж 14 %%%%%%%%%%%%%%%%%%%%%%%
				insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
				select PC_Id, TMAD_IsCommission, TMAD_Percent
				from #tableForMigrate
				inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
				where PC_TourDate = TMAD_DateCheckIn
				and PC_Days = TMAD_Long
				and SVKey_14 = TMAD_SvKey
				and PC_TRKey = @TrKey
				
				if exists (select top 1 1 from #tempPCIdtable)
				begin
					update pc
					set	PC_DateLastChangeMargin = getdate(), 
						PC_UpdateDate = getdate(),
						CommissionOnly_14 = xIsCommission,
						MarginPercent_14 = xPercent,
						PC_State = 1
					from #tempPCIdtable
					inner join TP_PriceComponents pc on PC_Id = xPCId
					WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
							and PC_TRKey = @TrKey		
					
					truncate table #tempPCIdtable
				end
				-- %%%%%%%%%%%%%%%%%%% Кортеж 14 %%%%%%%%%%%%%%%%%%%%%%%
			end
			else
				set @Return = 1
		end
		
		if 	@Return != 1
		begin
			if exists (select 1 from TP_PriceComponents with (nolock) where PC_TRKey = @TrKey and SCPId_15 is not null)				
			begin
				-- %%%%%%%%%%%%%%%%%%% Кортеж 15 %%%%%%%%%%%%%%%%%%%%%%%
				insert into #tempPCIdtable (xPCId, xIsCommission, xPercent)
				select PC_Id, TMAD_IsCommission, TMAD_Percent
				from #tableForMigrate
				inner join TP_PriceComponents with (nolock) on PC_TRKey = TMAD_TRKey
				where PC_TourDate = TMAD_DateCheckIn
				and PC_Days = TMAD_Long
				and SVKey_15 = TMAD_SvKey
				and PC_TRKey = @TrKey
				
				if exists (select top 1 1 from #tempPCIdtable)
				begin
					update pc
					set	PC_DateLastChangeMargin = getdate(), 
						PC_UpdateDate = getdate(),
						CommissionOnly_15 = xIsCommission,
						MarginPercent_15 = xPercent,
						PC_State = 1
					from #tempPCIdtable 
					inner join TP_PriceComponents pc on PC_Id = xPCId
					WHERE	PC_TourDate between @DateCheckInMin and @DateCheckInMax
							and PC_TRKey = @TrKey		
					
					truncate table #tempPCIdtable
				end
				-- %%%%%%%%%%%%%%%%%%% Кортеж 15 %%%%%%%%%%%%%%%%%%%%%%%
			end
			else
				set @Return = 1
		end

		print 'Переносим записи: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()	
			
		/*обновим галку о необходимости переноса цены*/
		update TP_TourMarginActualDate
		set TMAD_NeedApply = 0
		where TMAD_Id in (select TMAD_Id from #tableForMigrate)

		print 'Количество строк в TP_TourMarginActualDate: ' + convert(nvarchar(max), @@rowcount)		
				
		if @TrKey is not null
		begin
			delete from Debug where db_Mod='MMI' and db_n1=@TrKey
			--insert into Megatec_StateData (SD_Code, SD_Name, SD_Value) values (3001, 'ReCalculateCosts_MarginMigrate', @count)
		end
	end
END
go
grant exec on [dbo].[ReCalculateCosts_MarginMigrateTRKey] to public
go
/*********************************************************************/
/* end sp_ReCalculateCosts_MarginMigrateTRKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_MigrateToPrice.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_MigrateToPrice]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[ReCalculate_MigrateToPrice]
GO

--<VERSION>2009.2.19.1</VERSION>
--<DATE>2014-04-02</DATE>
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
		xUpdateDate datetime,
		xSummPriceDeleted as (case when xSummPrice is null then 1 else 0 end) persisted
	)
	
	-- Таблица для ключей туров
	CREATE TABLE #calculatingTours 
	(
		xToKey int
	)

	CREATE NONCLUSTERED INDEX IX_tempGrossTable_xSummPriceDeleted ON #tempGrossTable(xSummPriceDeleted) INCLUDE(xTPKey)

	DECLARE @numRowsInserted int, @numRowsUpdated int, @numRowsDeleted int
	SET @numRowsInserted = 0
	SET @numRowsUpdated = 0
	SET @numRowsDeleted = 0

	DECLARE @numRowsUpdatedTotal int
	DECLARE @dtStarted datetime 
	SET @dtStarted = getdate()

	DECLARE @nullDate datetime 
	SET @nullDate = '1900-01-01'

	-- если указаны ключи цен, обрабатываем их
	IF (EXISTS(SELECT TOP 1 1 FROM @tpKeys))
	BEGIN
		PRINT 'R1: @countItem ' + cast(@countItem as nvarchar(32))
		
		INSERT INTO #calculatingTours(xToKey)
		SELECT DISTINCT PC_ToKey
		FROM @tpKeys inner join TP_PriceComponents ON value = PC_TPKey
		WHERE PC_State = 1
	END  
	ELSE
	BEGIN  
		--Если указан @toKey, обрабатываем только один тур
		IF (@toKey IS NOT NULL)
		BEGIN
			PRINT 'R2: @toKey ' + cast(@toKey as nvarchar(32)) + ' @countItem ' + cast(@countItem as nvarchar(32))
			
			INSERT INTO #calculatingTours(xToKey)
			VALUES (@toKey)
		END
   		ELSE
		BEGIN
			--Если указано количество туров, берем в обработкe @countItem цен @toursCount туров    
			IF (@tpToursCount IS NOT NULL)
			BEGIN      
				PRINT 'R3: @tpToursCount ' + cast(@tpToursCount as nvarchar(32)) + ' @countItem ' + cast(@countItem as nvarchar(32))

				INSERT INTO #calculatingTours(xToKey)
				SELECT DISTINCT TOP(@tpToursCount) t.to_key
				FROM TP_PriceComponents tp WITH(NOLOCK)
				INNER JOIN tp_tours t WITH(NOLOCK) ON t.TO_Key = tp.PC_TOKey and tp.PC_State = 1
			END
			-- Иначе обрабатываем первые @countItem записей из очереди         
			ELSE
			BEGIN
				PRINT 'R4: @countItem ' + cast(@countItem as nvarchar(32))

				INSERT INTO #calculatingTours(xToKey)
				SELECT DISTINCT TOP (@countItem) PC_ToKey
				FROM TP_PriceComponents
				WHERE PC_State = 1
			END
		END
	END

	DECLARE currReCalculate_MigrateToPrice CURSOR FAST_FORWARD READ_ONLY
	FOR SELECT xToKey FROM #calculatingTours

	OPEN currReCalculate_MigrateToPrice

	FETCH NEXT FROM currReCalculate_MigrateToPrice INTO @toKey

	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- Очистка временной таблицы
		TRUNCATE TABLE #tempGrossTable

		-- Получение цен для обновления
		INSERT INTO #tempGrossTable (xPCId, xTPKey, xSummPrice, xUpdateDate)
		SELECT TOP (@countItem) PC_Id, PC_TPKey, PC_SummPrice, PC_UpdateDate
		FROM TP_PriceComponents
		WHERE PC_State = 1 AND PC_TOKey = @toKey
		SET @numRowsUpdatedTotal = ISNULL(@numRowsUpdatedTotal, 0) + @@ROWCOUNT

		INSERT INTO CalculatingPriceLists (CP_CreateDate,CP_PriceTourKey) VALUES (GETDATE(),@toKey) 
		DECLARE	@cpKey int
		SET @cpKey = SCOPE_IDENTITY()

		-- переносим цены в таблицу для удаленных цен
		INSERT INTO tp_pricesdeleted (TPD_TPKey, TPD_TOKey, TPD_TIKey, TPD_Gross, TPD_DateBegin, TPD_DateEnd, TPD_CalculatingKey)
		SELECT TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, @cpKey 
		FROM #tempGrossTable
		INNER JOIN tp_prices tp WITH(NOLOCK) ON TP_Key = xTPKey AND xSummPriceDeleted = 1

		-- удаляем цены из tp_prices
		DELETE tp 
		FROM #tempGrossTable WITH(NOLOCK)
		INNER JOIN tp_prices tp ON TP_Key = xTPKey AND xSummPriceDeleted = 1
		SET @numRowsDeleted = @@ROWCOUNT

		--восстанавливаем цены из таблицы удаленных цен
		INSERT INTO tp_prices (TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, TP_CalculatingKey)
		SELECT TPD_TPKey, TPD_TOKey, TPD_TIKey, TPD_Gross, TPD_DateBegin, TPD_DateEnd, @cpKey
		FROM #tempGrossTable
		INNER JOIN tp_pricesdeleted WITH(NOLOCK) ON tpd_tpkey = xTPKey AND xSummPriceDeleted = 0
		SET @numRowsInserted = @@ROWCOUNT

		-- и удаляем из из таблицы удаленных цен
		DELETE tpd
		FROM #tempGrossTable
		INNER JOIN tp_pricesdeleted tpd ON tpd_tpkey = xTPKey AND xSummPriceDeleted = 0

		-- обновляем цены, которые ранее не были удалены и изменились, или ранее были удалены но сейчас востановились
		UPDATE tp
		SET 
			tp.TP_Gross = CEILING(xSummPrice),
			tp.tp_updatedate = GETDATE(),
			tp.TP_CalculatingKey = @cpKey
		FROM #tempGrossTable
		INNER JOIN TP_Prices tp ON tp_key = xTPKey AND xSummPriceDeleted = 0
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
		UPDATE pc
		SET 
			pc.PC_DateLastUpdateToPrice = GETDATE(),
			pc.PC_State = 0
		FROM #tempGrossTable
		INNER JOIN TP_PriceComponents pc ON pc.PC_Id = xPCId AND 
			ISNULL(pc.PC_UpdateDate, @nullDate) = ISNULL(xUpdateDate, @nullDate)

		FETCH NEXT FROM currReCalculate_MigrateToPrice INTO @toKey
	END

	CLOSE currReCalculate_MigrateToPrice
	DEALLOCATE currReCalculate_MigrateToPrice

	DECLARE @tsWorked int
	SET @tsWorked = DATEDIFF(SECOND, @dtStarted, GETDATE()) + 1

	PRINT 'Обработка завершена, общее кол-во обработаных цен: ' + CONVERT(nvarchar(max), @numRowsUpdatedTotal) 
		+ ', общее время работы: ' + CAST((@tsWorked / 60) as nvarchar(16)) + ' мин ' + CAST((@tsWorked % 60) as nvarchar(16)) + ' сек'
		+ ', средняя скорость обсчета: ' +  CAST((CAST(@numRowsUpdatedTotal as decimal) / @tsWorked * 60) as nvarchar(32)) + ' цен/мин'

END
GO

GRANT EXECUTE ON [dbo].[ReCalculate_MigrateToPrice]	TO PUBLIC
GO
/*********************************************************************/
/* end sp_ReCalculate_MigrateToPrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetServiceStatusOK.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetServiceStatusOK]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[SetServiceStatusOK]
GO

CREATE PROCEDURE [dbo].[SetServiceStatusOK]
	(
		--<VERSION>2009.2.20.1</VERSION>
		--<DATA>03.04.2014</DATA>
		-- хранимка определяет какой статус необходимо установить услуги, после изменения статуса квотирования
		@dlkey int,
		@dlcontrol int out -- новый статус
	)
AS
BEGIN
	set @dlcontrol = null
	-- теперь в завмсимости от настроек будем менять статусы на Ок
	-- 0 - все галки сняты
	-- 1 - Все услуги
	-- 2 - Авиаперелет
	-- 3 - Все услуги & Авиаперелет
	-- 4 - Проживание
	-- 5 - Все услуги & Проживание
	-- 6 - Авиаперелет & Проживание
	-- 7 - Все услуги & Авиаперелет & Проживание
	
	DECLARE @dlPartnerKey int, @svkey int, @sdState int, @svControl int, @svQuoted int, @oldDLControl int  
	
	-- Если это услуга из Интерлука, ничего не делаем
	select @dlPartnerKey=DL_PARTNERKEY, @svkey = dl_svkey, @oldDLControl = DL_Control, 
	@svControl = SV_CONTROL, @svQuoted = SV_QUOTED  
	from tbl_dogovorList join [service] on dl_svkey = sv_key 
	where dl_key = @dlkey and isnull(SV_QUOTED, 0) = 1
	
	if (exists (select top 1 1 from dbo.SystemSettings where SS_ParmName = 'IL_SyncILPartners' AND SS_ParmValue LIKE '%/' + convert(nvarchar(max) ,@dlPartnerKey) + '/%'))
		return
	
	select @sdState = MAX(COALESCE(SD_State, 4))
	from ServiceByDate 
	where SD_DLKey = @dlkey
	
	if (@sdState < 4 and @svQuoted = 1)
	begin 
		-- MEG00032041
		-- Теперь проверим есть ли на эту квоту запись в таблице QuotaStatuses
		-- которая говорит нам что нужно изменить статус услуги на тот который в этой таблице
		if exists(select 1 from QuotaStatuses join Quotas on QS_QTID = QT_ID						
					join QuotaDetails on QT_ID = QD_QTID
					join QuotaParts on QP_QDID = QD_ID
					join ServiceByDate on SD_QPID = QP_ID
					where SD_DLKey = @dlkey and SD_State = QS_Type) 
		begin
			select @dlcontrol = QS_CRKey
			from QuotaStatuses join Quotas on QS_QTID = QT_ID 
			join QuotaDetails on QT_ID = QD_QTID
			join QuotaParts on QP_QDID = QD_ID
			join ServiceByDate on SD_QPID = QP_ID
			where SD_DLKey = @dlkey and SD_State = QS_Type
					
			if (@oldDLControl != @dlcontrol)
			begin
				update Dogovorlist set DL_Control = @dlcontrol where DL_Key = @dlKey 
			end
			
			return;
		end
		
		-- Авиаперелет
		if (@svkey = 1)
		begin
			if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('2', '3', '6', '7'))
			begin
				set @dlcontrol = 0
				update Dogovorlist set DL_Control = @dlcontrol where DL_Key = @dlKey 
				return;
			end
		end
			
		-- Проживание
		if (@svkey = 3)
		begin
			if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('4', '5', '6', '7'))
			begin
				set @dlcontrol = 0
				update Dogovorlist set DL_Control = @dlcontrol where DL_Key = @dlKey 
				return;
			end
		end
			
		-- Все услуги
		if (@svkey not in (1, 3))
		begin
			if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('1', '3', '5', '7'))
			begin
				set @dlcontrol = 0
				update Dogovorlist set DL_Control = @dlcontrol where DL_Key = @dlKey 
				return;
			end
		end
	end
	else if (@sdState = 4 and @svQuoted = 1)
	begin 
		set @dlcontrol = 1
		update Dogovorlist set DL_Control = @dlcontrol where DL_Key = @dlKey
		return;
	end 	
	
	-- установим нашей услуге статус из справочника услуг
	if (@svControl != @oldDLControl and @svQuoted = 1 and @svControl is not null)
	begin
		set @dlcontrol = @svControl
		update Dogovorlist set DL_Control = @svControl where DL_Key = @dlKey and DL_Control != @svControl
		return
	end
END
GO

grant execute on [dbo].[SetServiceStatusOK] to public
GO

/*********************************************************************/
/* end sp_SetServiceStatusOK.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_DogovorUpdate.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_DogovorUpdate]'))
DROP TRIGGER [dbo].[T_DogovorUpdate]
GO

CREATE TRIGGER [dbo].[T_DogovorUpdate]
ON [dbo].[tbl_Dogovor] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>9.2</VERSION>
--<DATE>2014-04-04</DATE>
IF @@ROWCOUNT > 0
BEGIN
    DECLARE @ODG_Code		varchar(10)
    DECLARE @ODG_Price		float
    DECLARE @ODG_Rate		varchar(3)
    DECLARE @ODG_DiscountSum	float
    DECLARE @ODG_PartnerKey		int
    DECLARE @ODG_TRKey		int
    DECLARE @ODG_TurDate		datetime
    DECLARE @ODG_CTKEY		int
    DECLARE @ODG_NMEN		int
    DECLARE @ODG_NDAY		int
    DECLARE @ODG_PPaymentDate	varchar(16)
    DECLARE @ODG_PaymentDate	varchar(10)
    DECLARE @ODG_RazmerP		float
    DECLARE @ODG_Procent		int
    DECLARE @ODG_Locked		int
    DECLARE @ODG_SOR_Code	int
    DECLARE @ODG_IsOutDoc		int
    DECLARE @ODG_VisaDate		varchar(10)
    DECLARE @ODG_CauseDisc		int
    DECLARE @ODG_OWNER		int
    DECLARE @ODG_LEADDEPARTMENT	int
    DECLARE @ODG_DupUserKey	int
    DECLARE @ODG_MainMen		varchar(50)
    DECLARE @ODG_MainMenEMail	varchar(50)
    DECLARE @ODG_MAINMENPHONE	varchar(50)
    DECLARE @ODG_CodePartner	varchar(50)
    DECLARE @ODG_Creator		int
	DECLARE @ODG_CTDepartureKey int
	DECLARE @ODG_Payed money
	DECLARE @ODG_ProTourFlag int
	DECLARE @NDG_ProTourFlag int
    
    DECLARE @NDG_Code		varchar(10)
    DECLARE @NDG_Price		float
    DECLARE @NDG_Rate		varchar(3)
    DECLARE @NDG_DiscountSum	float
    DECLARE @NDG_PartnerKey		int
    DECLARE @NDG_TRKey		int
    DECLARE @NDG_TurDate		datetime
    DECLARE @NDG_CTKEY		int
    DECLARE @NDG_NMEN		int
    DECLARE @NDG_NDAY		int
    DECLARE @NDG_PPaymentDate	varchar(16)
    DECLARE @NDG_PaymentDate	varchar(10)
    DECLARE @NDG_RazmerP		float
    DECLARE @NDG_Procent		int
    DECLARE @NDG_Locked		int
    DECLARE @NDG_SOR_Code	int
    DECLARE @NDG_IsOutDoc		int
    DECLARE @NDG_VisaDate		varchar(10)
    DECLARE @NDG_CauseDisc		int
    DECLARE @NDG_OWNER		int
    DECLARE @NDG_LEADDEPARTMENT	int
    DECLARE @NDG_DupUserKey	int
    DECLARE @NDG_MainMen		varchar(50)
    DECLARE @NDG_MainMenEMail	varchar(50)
    DECLARE @NDG_MAINMENPHONE	varchar(50)
    DECLARE @NDG_CodePartner	varchar(50)
	DECLARE @NDG_Creator		int
	DECLARE @NDG_CTDepartureKey int
	DECLARE @NDG_Payed money

    DECLARE @sText_Old varchar(255)
    DECLARE @sText_New varchar(255)

    DECLARE @nValue_Old int
    DECLARE @nValue_New int

    DECLARE @DG_Key int
    
    DECLARE @sMod varchar(3)
    DECLARE @nDelCount int
    DECLARE @nInsCount int
    DECLARE @nHIID int
    DECLARE @sHI_Text varchar(254)
	DECLARE @bNeedCommunicationUpdate smallint

	DECLARE @bUpdateNationalCurrencyPrice bit

	DECLARE @sUpdateMainDogovorStatuses varchar(254)
	
	DECLARE @nReservationNationalCurrencyRate smallint
	DECLARE @bReservationCreated smallint
	DECLARE @bCurrencyChangedPrevFixDate smallint
	DECLARE @bCurrencyChangedDate smallint
	DECLARE @bPriceChanged smallint
	DECLARE @bFeeChanged smallint
	DECLARE @bStatusChanged smallint
	DECLARE @changedDate datetime
	declare @dtCurrentDate datetime
	
    SELECT @nReservationNationalCurrencyRate = SS_PARMVALUE 
      FROM SystemSettings 
     WHERE SS_PARMNAME LIKE 'SYSReservationNCRate'
    SET @bReservationCreated = @nReservationNationalCurrencyRate & 1
    SET @bCurrencyChangedPrevFixDate = @nReservationNationalCurrencyRate & 2
    SET @bCurrencyChangedDate = @nReservationNationalCurrencyRate & 4
    SET @bPriceChanged = @nReservationNationalCurrencyRate & 8
    SET @bFeeChanged = @nReservationNationalCurrencyRate & 16
    SET @bStatusChanged = @nReservationNationalCurrencyRate & 32
	SET @changedDate = getdate()
	set @dtCurrentDate = GETDATE()

  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED
  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT N.DG_Key, 
		N.DG_Code, null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null, null, 
		null, null, null, null, null, null, null, null, null, null,
		N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, N.DG_TurDate, N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
		CONVERT( char(11), N.DG_PPaymentDate, 104) + CONVERT( char(5), N.DG_PPaymentDate, 108), CONVERT( char(10), N.DG_PaymentDate, 104), N.DG_RazmerP, N.DG_Procent, N.DG_Locked, N.DG_SOR_Code, N.DG_IsOutDoc, CONVERT( char(10), N.DG_VisaDate, 104), N.DG_CauseDisc, N.DG_OWNER, 
		N.DG_LEADDEPARTMENT, N.DG_DupUserKey, N.DG_MainMen, N.DG_MainMenEMail, N.DG_MAINMENPHONE, N.DG_CodePartner, N.DG_Creator, N.DG_CTDepartureKey, N.DG_Payed, N.DG_ProTourFlag
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT O.DG_Key,
		O.DG_Code, O.DG_Price, O.DG_Rate, O.DG_DiscountSum, O.DG_PartnerKey, O.DG_TRKey, O.DG_TurDate, O.DG_CTKEY, O.DG_NMEN, O.DG_NDAY, 
		CONVERT( char(11), O.DG_PPaymentDate, 104) + CONVERT( char(5), O.DG_PPaymentDate, 108), CONVERT( char(10), O.DG_PaymentDate, 104), O.DG_RazmerP, O.DG_Procent, O.DG_Locked, O.DG_SOR_Code, O.DG_IsOutDoc, CONVERT( char(10), O.DG_VisaDate, 104), O.DG_CauseDisc, O.DG_OWNER, 
		O.DG_LEADDEPARTMENT, O.DG_DupUserKey, O.DG_MainMen, O.DG_MainMenEMail, O.DG_MAINMENPHONE, O.DG_CodePartner, O.DG_Creator, O.DG_CTDepartureKey, O.DG_Payed, O.DG_ProTourFlag,
		null, null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null, null, 
		null, null, null, null, null, null, null, null, null, null
      FROM DELETED O 
  END
ELSE 
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT N.DG_Key,
		O.DG_Code, O.DG_Price, O.DG_Rate, O.DG_DiscountSum, O.DG_PartnerKey, O.DG_TRKey, O.DG_TurDate, O.DG_CTKEY, O.DG_NMEN, O.DG_NDAY, 
		CONVERT( char(11), O.DG_PPaymentDate, 104) + CONVERT( char(5), O.DG_PPaymentDate, 108), CONVERT( char(10), O.DG_PaymentDate, 104), O.DG_RazmerP, O.DG_Procent, O.DG_Locked, O.DG_SOR_Code, O.DG_IsOutDoc, CONVERT( char(10), O.DG_VisaDate, 104), O.DG_CauseDisc, O.DG_OWNER, 
		O.DG_LEADDEPARTMENT, O.DG_DupUserKey, O.DG_MainMen, O.DG_MainMenEMail, O.DG_MAINMENPHONE, O.DG_CodePartner, O.DG_Creator, O.DG_CTDepartureKey, O.DG_Payed, O.DG_ProTourFlag,
		N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, N.DG_TurDate, N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
		CONVERT( char(11), N.DG_PPaymentDate, 104) + CONVERT( char(5), N.DG_PPaymentDate, 108),  CONVERT( char(10), N.DG_PaymentDate, 104), N.DG_RazmerP, N.DG_Procent, N.DG_Locked, N.DG_SOR_Code, N.DG_IsOutDoc,  CONVERT( char(10), N.DG_VisaDate, 104), N.DG_CauseDisc, N.DG_OWNER, 
		N.DG_LEADDEPARTMENT, N.DG_DupUserKey, N.DG_MainMen, N.DG_MainMenEMail, N.DG_MAINMENPHONE, N.DG_CodePartner, N.DG_Creator, N.DG_CTDepartureKey, N.DG_Payed, N.DG_ProTourFlag
      FROM DELETED O, INSERTED N 
      WHERE N.DG_Key = O.DG_Key
  END
  
    OPEN cur_Dogovor
    FETCH NEXT FROM cur_Dogovor INTO @DG_Key,
		@ODG_Code, @ODG_Price, @ODG_Rate, @ODG_DiscountSum, @ODG_PartnerKey, @ODG_TRKey, @ODG_TurDate, @ODG_CTKEY, @ODG_NMEN, @ODG_NDAY, 
		@ODG_PPaymentDate, @ODG_PaymentDate, @ODG_RazmerP, @ODG_Procent, @ODG_Locked, @ODG_SOR_Code, @ODG_IsOutDoc, @ODG_VisaDate, @ODG_CauseDisc, @ODG_OWNER, 
		@ODG_LEADDEPARTMENT, @ODG_DupUserKey, @ODG_MainMen, @ODG_MainMenEMail, @ODG_MAINMENPHONE, @ODG_CodePartner, @ODG_Creator, @ODG_CTDepartureKey, @ODG_Payed, @ODG_ProTourFlag,
		@NDG_Code, @NDG_Price, @NDG_Rate, @NDG_DiscountSum, @NDG_PartnerKey, @NDG_TRKey, @NDG_TurDate, @NDG_CTKEY, @NDG_NMEN, @NDG_NDAY, 
		@NDG_PPaymentDate, @NDG_PaymentDate, @NDG_RazmerP, @NDG_Procent, @NDG_Locked, @NDG_SOR_Code, @NDG_IsOutDoc, @NDG_VisaDate, @NDG_CauseDisc, @NDG_OWNER, 
		@NDG_LEADDEPARTMENT, @NDG_DupUserKey, @NDG_MainMen, @NDG_MainMenEMail, @NDG_MAINMENPHONE, @NDG_CodePartner, @NDG_Creator, @NDG_CTDepartureKey, @NDG_Payed, @NDG_ProTourFlag

    WHILE @@FETCH_STATUS = 0
    BEGIN	    
		DECLARE @ODG_TurDateS		varchar(10)
		Set @ODG_TurDateS = CONVERT( char(10), @ODG_TurDate, 104)
		DECLARE @NDG_TurDateS		varchar(10)
		Set @NDG_TurDateS = CONVERT( char(10), @NDG_TurDate, 104)
    	  ------------Проверка, надо ли что-то писать в историю-------------------------------------------   
	  If (
			ISNULL(@ODG_Code, '') != ISNULL(@NDG_Code, '') OR
			ISNULL(@ODG_Rate, '') != ISNULL(@NDG_Rate, '') OR
			ISNULL(@ODG_MainMen, '') != ISNULL(@NDG_MainMen, '') OR
			ISNULL(@ODG_MainMenEMail, '') != ISNULL(@NDG_MainMenEMail, '') OR
			ISNULL(@ODG_MAINMENPHONE, '') != ISNULL(@NDG_MAINMENPHONE, '') OR
			ISNULL(@ODG_Price, 0) != ISNULL(@NDG_Price, 0) OR
			ISNULL(@ODG_DiscountSum, 0) != ISNULL(@NDG_DiscountSum, 0) OR
			ISNULL(@ODG_PartnerKey, 0) != ISNULL(@NDG_PartnerKey, 0) OR
			ISNULL(@ODG_TRKey, 0) != ISNULL(@NDG_TRKey, 0) OR
			ISNULL(@ODG_TurDate, 0) != ISNULL(@NDG_TurDate, 0) OR
			ISNULL(@ODG_CTKEY, 0) != ISNULL(@NDG_CTKEY, 0) OR
			ISNULL(@ODG_NMEN, 0) != ISNULL(@NDG_NMEN, 0) OR
			ISNULL(@ODG_NDAY, 0) != ISNULL(@NDG_NDAY, 0) OR
			ISNULL(@ODG_PPaymentDate, 0) != ISNULL(@NDG_PPaymentDate, 0) OR
			ISNULL(@ODG_PaymentDate, 0) != ISNULL(@NDG_PaymentDate, 0) OR
			ISNULL(@ODG_RazmerP, 0) != ISNULL(@NDG_RazmerP, 0) OR
			ISNULL(@ODG_Procent, 0) != ISNULL(@NDG_Procent, 0) OR
			ISNULL(@ODG_Locked, 0) != ISNULL(@NDG_Locked, 0) OR
			ISNULL(@ODG_SOR_Code, 0) != ISNULL(@NDG_SOR_Code, 0) OR
			ISNULL(@ODG_IsOutDoc, 0) != ISNULL(@NDG_IsOutDoc, 0) OR
			ISNULL(@ODG_VisaDate, 0) != ISNULL(@NDG_VisaDate, 0) OR
			ISNULL(@ODG_CauseDisc, 0) != ISNULL(@NDG_CauseDisc, 0) OR
			ISNULL(@ODG_OWNER, 0) != ISNULL(@NDG_OWNER, 0) OR
			ISNULL(@ODG_LEADDEPARTMENT, 0) != ISNULL(@NDG_LEADDEPARTMENT, 0) OR
			ISNULL(@ODG_DupUserKey, 0) != ISNULL(@NDG_DupUserKey, 0) OR
			ISNULL(@ODG_CodePartner, '') != ISNULL(@NDG_CodePartner, '') OR
			ISNULL(@ODG_Creator, 0) != ISNULL(@NDG_Creator, 0) OR
			ISNULL(@ODG_CTDepartureKey, 0) != ISNULL(@NDG_CTDepartureKey, 0) OR
			ISNULL(@ODG_Payed, 0) != ISNULL(@NDG_Payed, 0)OR
			ISNULL(@ODG_ProTourFlag, 0) != ISNULL(@NDG_ProTourFlag, 0)
		)
	  BEGIN
	  	------------Запись в историю--------------------------------------------------------------------
		EXEC dbo.InsMasterEvent 4, @DG_Key

		if (@sMod = 'INS')
			SET @sHI_Text = ISNULL(@NDG_Code, '')
		else if (@sMod = 'DEL')
			SET @sHI_Text = ISNULL(@ODG_Code, '')
		else if (@sMod = 'UPD')
			SET @sHI_Text = ISNULL(@NDG_Code, '')

		EXEC @nHIID = dbo.InsHistory @sHI_Text, @DG_Key, 1, @DG_Key, @sMod, @sHI_Text, '', 0, ''
		--SELECT @nHIID = IDENT_CURRENT('History')
		IF(@sMod = 'INS')
		BEGIN
			DECLARE @PrivatePerson int;
			EXEC @PrivatePerson = [dbo].[CheckPrivatePerson] @NDG_code;
			IF(@PrivatePerson = 0)
				IF(ISNULL(@NDG_DUPUSERKEY,-1) >= 0)
					EXEC [dbo].[UpdateReservationMainManByPartnerUser] @NDG_code;
		END
		--------Детализация--------------------------------------------------
		if (ISNULL(@ODG_Code, '') != ISNULL(@NDG_Code, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1001, @ODG_Code, @NDG_Code, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_Rate, '') != ISNULL(@NDG_Rate, ''))
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1002, @ODG_Rate, @NDG_Rate, null, null, null, null, 0, @bNeedCommunicationUpdate output
				IF @bCurrencyChangedPrevFixDate > 0 OR @bCurrencyChangedDate > 0
					SET @bUpdateNationalCurrencyPrice = 1
				IF @bCurrencyChangedPrevFixDate > 0
					select @changedDate = MAX(HI_DATE) from history where HI_OAID = 20 and hi_dgcod = @ODG_CODE
			END
		if (ISNULL(@ODG_MainMen, '') != ISNULL(@NDG_MainMen, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1003, @ODG_MainMen, @NDG_MainMen, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_MainMenEMail, '') != ISNULL(@NDG_MainMenEMail, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1004, @ODG_MainMenEMail, @NDG_MainMenEMail, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_MAINMENPHONE, '') != ISNULL(@NDG_MAINMENPHONE, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1005, @ODG_MAINMENPHONE, @NDG_MAINMENPHONE, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_Price, 0) != ISNULL(@NDG_Price, 0))
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1006, @ODG_Price, @NDG_Price, null, null, null, null, 0, @bNeedCommunicationUpdate output
				IF @bPriceChanged > 0
					SET @bUpdateNationalCurrencyPrice = 1
			END
		if (ISNULL(@ODG_DiscountSum, 0) != ISNULL(@NDG_DiscountSum, 0))
		BEGIN
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1007, @ODG_DiscountSum, @NDG_DiscountSum, null, null, null, null, 0, @bNeedCommunicationUpdate output
			IF @bFeeChanged > 0 
				SET @bUpdateNationalCurrencyPrice = 1
		END
		if (ISNULL(@ODG_PartnerKey, 0) != ISNULL(@NDG_PartnerKey, 0))
			BEGIN
				Select @sText_Old = PR_Name from Partners where PR_Key = @ODG_PartnerKey
				Select @sText_New = PR_Name from Partners where PR_Key = @NDG_PartnerKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1008, @sText_Old, @sText_New, @ODG_PartnerKey, @NDG_PartnerKey, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_TRKey, 0) != ISNULL(@NDG_TRKey, 0))
			BEGIN
				Select @sText_Old = TL_Name from Turlist where TL_Key = @ODG_TRKey
				Select @sText_New = TL_Name from Turlist where TL_Key = @NDG_TRKey
				If @NDG_TRKey is not null
					Update DogovorList set DL_TRKey=@NDG_TRKey where DL_DGKey=@DG_Key
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1009, @sText_Old, @sText_New, @ODG_TRKey, @NDG_TRKey, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_TurDate, '') != ISNULL(@NDG_TurDate, ''))
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1010, @ODG_TurDateS, @NDG_TurDateS, null, null, null, null, 0, @bNeedCommunicationUpdate output

				Update DogovorList set DL_TURDATE = @NDG_TurDate where DL_DGKey = @DG_Key
				Update tbl_Turist set TU_TURDATE = @NDG_TurDate where TU_DGKey = @DG_Key

				--Путевка разаннулируется
				IF (ISNULL(@ODG_SOR_Code, 0) = 2)
				BEGIN
					DECLARE @nDGSorCode_New int, @sDisableDogovorStatusChange int

					SELECT @sDisableDogovorStatusChange = SS_ParmValue FROM SystemSettings WHERE SS_ParmName like 'SYSDisDogovorStatusChange'
					IF (@sDisableDogovorStatusChange is null or @sDisableDogovorStatusChange = '0')
					BEGIN
						exec dbo.SetReservationStatus @DG_Key
						-- 20611:CRM05885G9M9 Вызов перенесен в триггрер T_DogovorUpdate
						exec dbo.CreatePPaymentDate @NDG_Code, @NDG_TurDate, @dtCurrentDate
					END
				END
			END
		if (ISNULL(@ODG_CTKEY, 0) != ISNULL(@NDG_CTKEY, 0))
			BEGIN
				Select @sText_Old = CT_Name from CityDictionary  where CT_Key = @ODG_CTKEY
				Select @sText_New = CT_Name from CityDictionary  where CT_Key = @NDG_CTKEY
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1011, @sText_Old, @sText_New, @ODG_CTKEY, @NDG_CTKEY, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_NMEN, 0) != ISNULL(@NDG_NMEN, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1012, @ODG_NMEN, @NDG_NMEN, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_NDAY, 0) != ISNULL(@NDG_NDAY, 0))
		begin
			-- если изменилась продолжительность путевки, то нужно пересадить все услуги которые сидят на квотах 
			-- на продолжительность и сами не имеют продолжительности
			declare @DLKey int, @DLDateBeg datetime, @DLDateEnd datetime
			
			declare curSetQuoted CURSOR FORWARD_ONLY for
						select DL_KEY, DL_DATEBEG, DL_DATEEND
						from Dogovorlist join [Service] on SV_KEY = DL_SVKEY
						where DL_DGKEY = @DG_Key
						and isnull(SV_IsDuration, 0) = 0
			OPEN curSetQuoted
			FETCH NEXT FROM curSetQuoted INTO @DLKey, @DLDateBeg, @DLDateEnd

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- услуга сидит на квоте на продолжительность
				if (exists(select 1 from QuotaParts with(nolock) where LEN(ISNULL(QP_Durations, '')) > 0 and QP_ID in (select SD_QPID from ServiceByDate with(nolock) where SD_DLKey = @DLKey)))
					EXEC DogListToQuotas @DLKey, null, null, null, null, @DLDateBeg, @DLDateEnd, null, null
			
				FETCH NEXT FROM curSetQuoted INTO @DLKey, @DLDateBeg, @DLDateEnd
			end
			CLOSE curSetQuoted
			DEALLOCATE curSetQuoted
			
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1013, @ODG_NDAY, @NDG_NDAY, null, null, null, null, 0, @bNeedCommunicationUpdate output
		end
		if (ISNULL(@ODG_PPaymentDate, 0) != ISNULL(@NDG_PPaymentDate, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1014, @ODG_PPaymentDate, @NDG_PPaymentDate, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_PaymentDate, 0) != ISNULL(@NDG_PaymentDate, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1015, @ODG_PaymentDate, @NDG_PaymentDate, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_RazmerP, 0) != ISNULL(@NDG_RazmerP, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1016, @ODG_RazmerP, @NDG_RazmerP, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_Procent, 0) != ISNULL(@NDG_Procent, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1017, @ODG_Procent, @NDG_Procent, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_Locked, 0) != ISNULL(@NDG_Locked, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1018, @ODG_Locked, @NDG_Locked, null, null, null, null, 0, @bNeedCommunicationUpdate output
		
		--MEG00040358 вынесла запись истории из условия if (ISNULL(@ODG_SOR_Code, 0) != ISNULL(@NDG_SOR_Code, 0)),
		-- так как условие на вставку в этом блоке никогда не срабатывало, потому что в новой путевке @NDG_SOR_Code всегда нул , а @ODG_SOR_Code всегда ноль
		------путевка была создана--------------
		if (ISNULL(@ODG_SOR_Code, 0) = 0 and @sMod = 'INS')
		begin
			EXECUTE dbo.InsertHistoryDetail @nHIID, 1122, null, null, null, null, null, null, 1, @bNeedCommunicationUpdate output
			-- 20611:CRM05885G9M9 Вызов перенесен в триггрер T_DogovorUpdate
			exec dbo.CreatePPaymentDate @NDG_Code, @NDG_TurDate, @dtCurrentDate
		end

		
		if (ISNULL(@ODG_SOR_Code, 0) != ISNULL(@NDG_SOR_Code, 0))
			BEGIN
				Select @sText_Old = OS_Name_Rus, @nValue_Old = OS_Global from Order_Status Where OS_Code = @ODG_SOR_Code
				Select @sText_New = OS_Name_Rus, @nValue_New = OS_Global from Order_Status Where OS_Code = @NDG_SOR_Code
				If @nValue_New = 7 and @nValue_Old != 7
					UPDATE [dbo].[tbl_Dogovor] SET DG_ConfirmedDate = GetDate() WHERE DG_Key = @DG_Key
				If @nValue_New != 7 and @nValue_Old = 7
					UPDATE [dbo].[tbl_Dogovor] SET DG_ConfirmedDate = NULL WHERE DG_Key = @DG_Key
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1019, @sText_Old, @sText_New, @ODG_SOR_Code, @NDG_SOR_Code, null, null, 0, @bNeedCommunicationUpdate output
				
				------путевка была аннулирована--------------
				if (@NDG_SOR_Code = 2 and @sMod = 'UPD')
					EXECUTE dbo.InsertHistoryDetail @nHIID, 1123, null, null, null, null, null, null, 1, @bNeedCommunicationUpdate output
				
				if @bStatusChanged > 0 and exists(select NC_Id from NationalCurrencyReservationStatuses with(nolock) where NC_OrderStatus = ISNULL(@NDG_SOR_Code, 0))
				begin
					if (@bCurrencyChangedPrevFixDate > 0)
						set @changedDate = ISNULL(dbo.GetFirstDogovorStatusDate (@DG_Key, @NDG_SOR_Code), GetDate())
					
					SET @bUpdateNationalCurrencyPrice = 1
				end
				-- 20611:CRM05885G9M9 Вызов перенесен в триггрер T_DogovorUpdate
				exec dbo.CreatePPaymentDate @NDG_Code, @NDG_TurDate, @dtCurrentDate
			END
		if (ISNULL(@ODG_IsOutDoc, 0) != ISNULL(@NDG_IsOutDoc, 0))
			BEGIN
				Select @sText_Old = DS_Name from DocumentStatus Where DS_Key = @ODG_IsOutDoc
				Select @sText_New = DS_Name from DocumentStatus Where DS_Key = @NDG_IsOutDoc
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1020, @sText_Old, @sText_New, @ODG_IsOutDoc, @NDG_IsOutDoc, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_VisaDate, 0) != ISNULL(@NDG_VisaDate, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1021, @ODG_VisaDate, @NDG_VisaDate, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_CauseDisc, 0) != ISNULL(@NDG_CauseDisc, 0))
			BEGIN
				Select @sText_Old = CD_Name from CauseDiscounts Where CD_Key = @ODG_CauseDisc
				Select @sText_New = CD_Name from CauseDiscounts Where CD_Key = @NDG_CauseDisc
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1022, @sText_Old, @sText_New, @ODG_CauseDisc, @NDG_CauseDisc, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_OWNER, 0) != ISNULL(@NDG_OWNER, 0))
			BEGIN
				Select @sText_Old = US_FullName from UserList Where US_Key = @ODG_Owner
				Select @sText_New = US_FullName from UserList Where US_Key = @NDG_Owner
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1023, @sText_Old, @sText_New, @ODG_Owner, @NDG_Owner, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_Creator, 0) != ISNULL(@NDG_Creator, 0))
			BEGIN
				Select @sText_Old = US_FullName from UserList Where US_Key = @ODG_Creator
				Select @sText_New = US_FullName from UserList Where US_Key = @NDG_Creator
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1117, @sText_Old, @sText_New, @ODG_Creator, @NDG_Creator, null, null, 0, @bNeedCommunicationUpdate output
				Select @nValue_Old = US_DepartmentKey from UserList Where US_Key = @ODG_Creator
				Select @nValue_New = US_DepartmentKey from UserList Where US_Key = @NDG_Creator
				if (@nValue_Old is not null OR @nValue_New is not null)
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1134, @nValue_Old, @nValue_New, null, null, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_LEADDEPARTMENT, 0) != ISNULL(@NDG_LeadDepartment, 0))
			BEGIN
				Select @sText_Old = PDP_Name from PrtDeps where PDP_Key = @ODG_LeadDepartment
				Select @sText_New = PDP_Name from PrtDeps where PDP_Key = @NDG_LeadDepartment
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1024, @sText_Old, @sText_New, @ODG_LeadDepartment, @NDG_LeadDepartment, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_DupUserKey, 0) != ISNULL(@NDG_DupUserKey, 0))
			BEGIN
				Select @sText_Old = US_FullName FROM Dup_User WHERE US_Key = @ODG_DupUserKey
				Select @sText_New = US_FullName FROM Dup_User WHERE US_Key = @NDG_DupUserKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1025, @sText_Old, @sText_New, @ODG_DupUserKey, @NDG_DupUserKey, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_CTDepartureKey, 0) != ISNULL(@NDG_CTDepartureKey, 0))
			BEGIN
				Select @sText_Old = CT_Name FROM CityDictionary WHERE CT_Key = @ODG_CTDepartureKey
				Select @sText_New = CT_Name FROM CityDictionary WHERE CT_Key = @NDG_CTDepartureKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1121, @sText_Old, @sText_New, @ODG_CTDepartureKey, @NDG_CTDepartureKey, null, null, 0, @bNeedCommunicationUpdate output
			END
		if (ISNULL(@ODG_CodePartner, '') != ISNULL(@NDG_CodePartner, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1026, @ODG_CodePartner, @NDG_CodePartner, null, null, null, null, 0, @bNeedCommunicationUpdate output

		if (ISNULL(@ODG_Payed, 0) != ISNULL(@NDG_Payed, 0))
		begin
			declare @varcharODGPayed varchar(255), @varcharNDGPayed varchar(255)
			set @varcharODGPayed = cast(@ODG_Payed as varchar(255))
			set @varcharNDGPayed = cast(@NDG_Payed as varchar(255))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 5, @varcharODGPayed, @varcharNDGPayed, null, null, null, null, 0, @bNeedCommunicationUpdate output
		end
		IF (ISNULL(@ODG_ProTourFlag, 0) != ISNULL(@NDG_ProTourFlag, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 399999, @ODG_ProTourFlag, @NDG_ProTourFlag, null, null, null, null, 0, @bNeedCommunicationUpdate output

		If @bNeedCommunicationUpdate=1
			If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@DG_Key)
				UPDATE Communications SET CM_ChangeDate=GetDate() WHERE CM_DGKey=@DG_Key

		
		-- $$$ PRICE RECALCULATION $$$ --
		IF (@bUpdateNationalCurrencyPrice = 1 AND @sMod = 'UPD') OR (@sMod = 'INS' AND @bReservationCreated > 0)
		BEGIN
			--если не удалось определить дату, на которую рассчитывается и стоит настройка брать жату создания путевки, то ее и берем
			if @changedDate is null and @bReservationCreated > 0				
				select @changedDate = DG_CrDate from inserted i where i.dg_key = @DG_Key				   
				
			EXEC dbo.NationalCurrencyPrice2 @NDG_Rate, @ODG_Rate, @ODG_Code, @NDG_Price, @ODG_Price, @NDG_DiscountSum, @changedDate, @NDG_SOR_Code
		END
	  END

		-- recalculate if exchange rate changes (another table) & saving from frmDogovor (tour.apl)
		-- + force-drop #RecalculateAction table in case hasn't been
		/*IF OBJECT_ID('tempdb..#RecalculateAction') IS NOT NULL
		BEGIN
            DECLARE @AlwaysRecalcPrice int 
            SELECT  @AlwaysRecalcPrice = isnull(SS_ParmValue,0) FROM dbo.systemsettings  
            WHERE SS_ParmName = 'SYSAlwaysRecalcNational' 

			SELECT @DGCODE  = [DGCODE] FROM #RecalculateAction
			if @DGCODE = @NDG_Code
			begin
				SELECT @sAction = [Action] FROM #RecalculateAction
				DROP TABLE #RecalculateAction
				if @AlwaysRecalcPrice > 0
					EXEC dbo.NationalCurrencyPrice @ODG_Rate, @NDG_Rate, @ODG_Code, @NDG_Price, @ODG_Price, @NDG_DiscountSum, @sAction, @NDG_SOR_Code
		    end
		END*/
		-- $$$ ------------------- $$$ --

        -- Task 7613. rozin. 27.08.2012. Добавление Предупреждений и Комментариев (таблица PrtWarns) по партнеру в историю при создании путевки
		IF(@sMod = 'INS')
		BEGIN
			DECLARE @warningTextPattern varchar(128)        
			DECLARE @warningText varchar(256)       
			DECLARE @warningType varchar(256)       
			DECLARE @warningMessage varchar(256) 
			DECLARE @partnerName varchar(256)
			DECLARE cur_PrtWarns CURSOR LOCAL FOR
				SELECT PW_Text, PW_Type
				FROM PrtWarns 
				WHERE PW_PRKey = @NDG_PartnerKey AND PW_IsAddToHistory = 1
	        
			SET @warningTextPattern = 'Прошу обратить внимание, что по заявке [1] у партнера [2] имеется [3]: [4]'
	        
			OPEN cur_PrtWarns
			FETCH NEXT FROM cur_PrtWarns INTO @warningText, @warningType
	        
			WHILE @@FETCH_STATUS = 0
			BEGIN 		
				SET @warningMessage = REPLACE(@warningTextPattern, '[1]', @NDG_Code)
				
				select @partnerName = pr_name from tbl_Partners where pr_key = @NDG_PartnerKey
				SET @warningMessage = REPLACE(@warningMessage, '[2]', @partnerName)
				
				IF (@warningType = 2)
					SET @warningMessage = REPLACE(@warningMessage, '[3]', 'предупреждение')
				ELSE IF (@warningType = 3)
					SET @warningMessage = REPLACE(@warningMessage, '[3]', 'комментарий')
				ELSE
					SET @warningMessage = REPLACE(@warningMessage, '[3]', '') -- таких сутуаций быть не должно
				
				SET @warningMessage = REPLACE(@warningMessage, '[4]', @warningText)
				
				EXEC dbo.InsHistory @NDG_Code, @DG_Key, NULL, NULL, 'MTM', @warningMessage, '', 0, '', 1
				FETCH NEXT FROM cur_PrtWarns INTO @warningText, @warningType
			END
	        
			CLOSE cur_PrtWarns
			DEALLOCATE cur_PrtWarns
		END
        -- END Task 7613
       
        DECLARE @DG_NATIONALCURRENCYPRICE int
	    DECLARE @DG_NATIONALCURRENCYDISCOUNTSUM int
		SET @DG_NATIONALCURRENCYPRICE = NULL
		SET @DG_NATIONALCURRENCYDISCOUNTSUM = NULL

		SELECT @DG_NATIONALCURRENCYPRICE = DG_NATIONALCURRENCYPRICE, @DG_NATIONALCURRENCYDISCOUNTSUM = DG_NATIONALCURRENCYDISCOUNTSUM FROM DOGOVOR 
		WHERE DG_KEY=@DG_Key
		 --Task 12886 04/04/2013 o.omelchenko - если идет инсерт и нац валюта не просчиталась, то считаем её на текущую дату
        if(@sMod = 'INS' and (@DG_NATIONALCURRENCYPRICE IS NULL OR @DG_NATIONALCURRENCYDISCOUNTSUM  IS NULL))
        BEGIN
            SET @changedDate = GETDATE()
            EXEC dbo.NationalCurrencyPrice2 @NDG_Rate, @ODG_Rate, @ODG_Code, @NDG_Price, @ODG_Price, @NDG_DiscountSum, @changedDate, @NDG_SOR_Code, 0 
        END
		-- Task 10558 tfs neupokoev 26.12.2012
		-- Повторная фиксация курса валюты, в случае если он не зафиксировался
		IF(@sMod = 'UPD')
			BEGIN			

				IF(@DG_NATIONALCURRENCYPRICE IS NULL OR @DG_NATIONALCURRENCYDISCOUNTSUM  IS NULL)
					BEGIN
						EXEC dbo.ReСalculateNationalRatePrice @DG_KEY, @NDG_Rate, @ODG_Rate, @ODG_Code, @NDG_Price, @ODG_Price, @NDG_DiscountSum, @NDG_SOR_Code
					END 
					
			    -- Если нету фиксации, то перерасчитываем на текущую дату
				IF not exists(select * from History where HI_DGKEY =@DG_KEY and (HI_OAId = 20 or HI_OAId = 21))
				BEGIN					     
					  EXEC dbo.NationalCurrencyPrice2 @NDG_Rate, @ODG_Rate, @ODG_Code, @NDG_Price, @ODG_Price, @NDG_DiscountSum, @changedDate, @NDG_SOR_Code, 0            
				END 
			END
		-- end Task 10558
        
    	  FETCH NEXT FROM cur_Dogovor INTO @DG_Key,
		@ODG_Code, @ODG_Price, @ODG_Rate, @ODG_DiscountSum, @ODG_PartnerKey, @ODG_TRKey, @ODG_TurDate, @ODG_CTKEY, @ODG_NMEN, @ODG_NDAY, 
		@ODG_PPaymentDate, @ODG_PaymentDate, @ODG_RazmerP, @ODG_Procent, @ODG_Locked, @ODG_SOR_Code, @ODG_IsOutDoc, @ODG_VisaDate, @ODG_CauseDisc, @ODG_OWNER, 
		@ODG_LEADDEPARTMENT, @ODG_DupUserKey, @ODG_MainMen, @ODG_MainMenEMail, @ODG_MAINMENPHONE, @ODG_CodePartner, @ODG_Creator, @ODG_CTDepartureKey, @ODG_Payed, @ODG_ProTourFlag,
		@NDG_Code, @NDG_Price, @NDG_Rate, @NDG_DiscountSum, @NDG_PartnerKey, @NDG_TRKey, @NDG_TurDate, @NDG_CTKEY, @NDG_NMEN, @NDG_NDAY, 
		@NDG_PPaymentDate, @NDG_PaymentDate, @NDG_RazmerP, @NDG_Procent, @NDG_Locked, @NDG_SOR_Code, @NDG_IsOutDoc, @NDG_VisaDate, @NDG_CauseDisc, @NDG_OWNER, 
		@NDG_LEADDEPARTMENT, @NDG_DupUserKey, @NDG_MainMen, @NDG_MainMenEMail, @NDG_MAINMENPHONE, @NDG_CodePartner, @NDG_Creator, @NDG_CTDepartureKey, @NDG_Payed, @NDG_ProTourFlag
    END
  CLOSE cur_Dogovor
  DEALLOCATE cur_Dogovor
END
GO

/*********************************************************************/
/* end T_DogovorUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_QuotaObjectsChange.sql */
/*********************************************************************/
if exists (select id from sysobjects where xtype = 'TR' and name='T_QuotaObjectsChange')
	drop trigger dbo.[T_QuotaObjectsChange]
go

CREATE TRIGGER [dbo].[T_QuotaObjectsChange]
ON [dbo].[QuotaObjects] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2008.1.01.03a</VERSION>
IF @@ROWCOUNT > 0 and exists(select 1 from SystemSettings with(nolock) where SS_ParmName like 'SYSQuotasToHistory' and ISNULL(SS_ParmValue, '0') <> '0')
BEGIN
	DECLARE @QT_Id int, @QT_ByRoom bit, @QT_PRKey int, @QT_PrtDogsKey int, @QO_ID int,
			@OQO_SVKey int, @OQO_Code int, @OQO_SubCode1 int, @OQO_SubCode2 int,
			@NQO_SVKey int, @NQO_Code int, @NQO_SubCode1 int, @NQO_SubCode2 int
    DECLARE @sText_Old varchar(255), @sText_New varchar(255), @sHI_Text varchar(255)
    
    DECLARE @sMod varchar(3), @nDelCount int, @nInsCount int, @nHIID int

	SELECT @nDelCount = COUNT(*) FROM DELETED
	SELECT @nInsCount = COUNT(*) FROM INSERTED
	IF (@nDelCount = 0)
	BEGIN
		SET @sMod = 'INS'
		DECLARE cur_QuotaObjects CURSOR LOCAL FOR 
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, N.QO_ID,
					null, null, null, null,
					N.QO_SVKey, N.QO_Code, N.QO_SubCode1, N.QO_SubCode2
			FROM	INSERTED N, dbo.Quotas
			WHERE	QT_ID=QO_QTID
	END
	ELSE IF (@nInsCount = 0)
	BEGIN
		SET @sMod = 'DEL'
		DECLARE cur_QuotaObjects CURSOR LOCAL FOR 
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, O.QO_ID,
					O.QO_SVKey, O.QO_Code, O.QO_SubCode1, O.QO_SubCode2,
					null, null, null, null
			FROM	DELETED O, dbo.Quotas
			WHERE	QT_ID=QO_QTID
	END
	ELSE 
	BEGIN
		SET @sMod = 'UPD'
		DECLARE cur_QuotaObjects CURSOR LOCAL FOR
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, N.QO_ID,
					O.QO_SVKey, O.QO_Code, O.QO_SubCode1, O.QO_SubCode2,
					N.QO_SVKey, N.QO_Code, N.QO_SubCode1, N.QO_SubCode2					
			FROM	DELETED O, INSERTED N, dbo.Quotas
			WHERE	QT_Id = N.QO_QTID and O.QO_Id=N.QO_Id
	END

	OPEN cur_QuotaObjects
	FETCH NEXT FROM cur_QuotaObjects INTO @QT_Id, @QT_ByRoom, @QT_PRKey, @QT_PrtDogsKey, @QO_ID,
					@OQO_SVKey, @OQO_Code, @OQO_SubCode1, @OQO_SubCode2, 
					@NQO_SVKey, @NQO_Code, @NQO_SubCode1, @NQO_SubCode2
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OQO_SVKey, 0) != ISNULL(@NQO_SVKey, 0) OR
			ISNULL(@OQO_Code, 0) != ISNULL(@NQO_Code, 0) OR
			ISNULL(@OQO_SubCode1, 0) != ISNULL(@NQO_SubCode1, 0) OR
			ISNULL(@OQO_SubCode2, 0) != ISNULL(@NQO_SubCode2, 0)
			)
		BEGIN
			------------Запись в историю--------------------------------------------------------------------
			If @QT_PRKey=0
				Set @sHI_Text='All partners'
			Else
				Select @sHI_Text = PR_Name from Partners where PR_Key=@QT_PRKey
			SET @sText_New=@sHI_Text
			Set @sHI_Text = null
			If isnull(@QT_PrtDogsKey,0) >0
				Select @sHI_Text = PD_DogNumber from PrtDogs where PD_Key=@QT_PrtDogsKey
			If @sHI_Text is not null
				SET @sText_New=@sText_New + '(' + @sHI_Text + ')'
			If (@OQO_SVKey=3 or @NQO_SVKey=3)
				If @QT_ByRoom=0
					SET @sText_New=@sText_New + '(BY PERSON)'
				Else
					SET @sText_New=@sText_New + '(BY ROOM)'
			Set @sHI_Text=CAST(@QO_Id as varchar(15))
			If @sMod = 'DEL'
				--EXEC @nHIID = dbo.InsHistory '', null, 12, @QO_Id, @sMod, @sText_New, '', 0, @sHI_Text, 0, @OQO_SVKey, @OQO_Code
			EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 12,
							@nTypeCode = @QO_ID,
							@sMod = @sMod,
							@sText = @sText_New,
							@sRemark = @sHI_Text,
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = @OQO_SVKey,
							@nCode = @OQO_Code
			Else
				--EXEC @nHIID = dbo.InsHistory '', null, 12, @QO_Id, @sMod, @sText_New, '', 0, @sHI_Text, 0, @NQO_SVKey, @NQO_Code
			EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 12,
							@nTypeCode = @QO_ID,
							@sMod = @sMod,
							@sText = @sText_New,
							@sRemark = @sHI_Text,
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = @NQO_SVKey,
							@nCode = @NQO_Code
			SET @sText_Old=''
			SET @sText_New=''
			--------Детализация--------------------------------------------------
			if ISNULL(@OQO_SVKey, 0) != ISNULL(@NQO_SVKey, 0)
			BEGIN
				If @OQO_SVKey is not null
					Select @sText_Old = SV_Name from dbo.Service where SV_Key = @OQO_SVKey
				If @NQO_SVKey is not null
					Select @sText_New = SV_Name from dbo.Service where SV_Key = @NQO_SVKey
				EXECUTE dbo.InsertHistoryDetail @nHIID, 12001, @sText_Old, @sText_New, @OQO_SVKey, @NQO_SVKey, null, null, 0
				SET @sText_Old=''
				SET @sText_New=''
			END
			if ISNULL(@OQO_Code, 0) != ISNULL(@NQO_Code, 0)
			BEGIN
				If @OQO_Code is not null
					exec dbo.GetSvCodeName @OQO_SVKey, @OQO_Code, @sText_Old, null
				If @NQO_Code is not null
					exec dbo.GetSvCodeName @NQO_SVKey, @NQO_Code, @sText_New, null					--exec @NQO_Code,@NQO_SVKey					
				EXECUTE dbo.InsertHistoryDetail @nHIID, 12002, @sText_Old, @sText_New, @OQO_Code, @NQO_Code, null, null, 0
				SET @sText_Old=''
				SET @sText_New=''
			END
			if ISNULL(@OQO_SubCode1, 0) != ISNULL(@NQO_SubCode1, 0)
			BEGIN
				If @OQO_SubCode1 is not null
					exec dbo.GetSvCode1Name @OQO_SVKey,@OQO_SubCode1,null,@sText_Old output,null,null,1
				If @NQO_SubCode1 is not null
					exec dbo.GetSvCode1Name @NQO_SVKey,@NQO_SubCode1,null,@sText_New output,null,null,1
				If @OQO_SubCode1 is not null or @NQO_SubCode1 is not null
					EXECUTE dbo.InsertHistoryDetail @nHIID, 12003, @sText_Old, @sText_New, @OQO_SubCode1, @NQO_SubCode1, null, null, 0
				SET @sText_Old=''
				SET @sText_New=''
			END
			if ISNULL(@OQO_SubCode2, 0) != ISNULL(@NQO_SubCode2, 0)
			BEGIN
				If @OQO_SubCode2 is not null
					exec dbo.GetSvCode2Name @OQO_SVKey,@OQO_SubCode2,null,@sText_Old output,1
				If @NQO_SubCode2 is not null
					exec dbo.GetSvCode2Name @NQO_SVKey,@NQO_SubCode2,null,@sText_New output,1
				If @OQO_SubCode2 is not null or @NQO_SubCode2 is not null
					EXECUTE dbo.InsertHistoryDetail @nHIID, 12004, @sText_Old, @sText_New, @OQO_SubCode2, @NQO_SubCode2, null, null, 0
				SET @sText_Old=''
				SET @sText_New=''
			END
		END
		FETCH NEXT FROM cur_QuotaObjects INTO @QT_Id, @QT_ByRoom, @QT_PRKey, @QT_PrtDogsKey, @QO_ID,
				@OQO_SVKey, @OQO_Code, @OQO_SubCode1, @OQO_SubCode2, 
				@NQO_SVKey, @NQO_Code, @NQO_SubCode1, @NQO_SubCode2
    END
	CLOSE cur_QuotaObjects
	DEALLOCATE cur_QuotaObjects
END
GO
/*********************************************************************/
/* end T_QuotaObjectsChange.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_StopSalesChange.sql */
/*********************************************************************/
if exists (select id from sysobjects where xtype = 'TR' and name='T_StopSalesChange')
	drop trigger dbo.[T_StopSalesChange]
go

CREATE TRIGGER [dbo].[T_StopSalesChange]
ON [dbo].[StopSales] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2009.2.01</VERSION>
--<DATE>2012-12-24</VERSION>
IF @@ROWCOUNT > 0
BEGIN
	DECLARE @QO_SVKey int, @QO_Code int, @QO_SubCode1 int, @QO_SubCode2 int, @SS_ID int,
			@OSS_PRKey int, @OSS_Date datetime, @OSS_IsDeleted smallint, @OSS_QDID int,
			@NSS_PRKey int, @NSS_Date datetime, @NSS_IsDeleted smallint, @NSS_QDID int,
			@SS_PRKey int, @SS_Date datetime, @SS_QDID int

    DECLARE @sText_Old varchar(255), @sText_New varchar(255), @sHI_Text varchar(255)
    DECLARE @sMod varchar(3), @nDelCount int, @nInsCount int, @nHIID int
	DECLARE @insToHistory varchar(50)

	select @insToHistory = ISNULL(SS_ParmValue, '0') from SystemSettings with(nolock) where SS_ParmName like 'SYSQuotasToHistory'

	SELECT @nDelCount = COUNT(*) FROM DELETED
	SELECT @nInsCount = COUNT(*) FROM INSERTED
	IF (@nDelCount = 0)
	BEGIN
		SET @sMod = 'INS'
		DECLARE cur_StopSales CURSOR LOCAL FOR 
			SELECT	QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2, N.SS_ID,
					null, null, null, null,
					N.SS_PRKey, N.SS_Date, N.SS_IsDeleted, N.SS_QDID
			FROM	INSERTED N, dbo.QuotaObjects
			WHERE	N.SS_QOID=QO_ID
	END
	ELSE IF (@nInsCount = 0)
	BEGIN
		SET @sMod = 'DEL'
		DECLARE cur_StopSales CURSOR LOCAL FOR 
			SELECT	QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2, O.SS_ID,
					O.SS_PRKey, O.SS_Date, O.SS_IsDeleted, O.SS_QDID,
					null, null, null, null
			FROM	DELETED O, dbo.QuotaObjects
			WHERE	O.SS_QOID=QO_ID
	END
	ELSE 
	BEGIN
		SET @sMod = 'UPD'
		DECLARE cur_StopSales CURSOR LOCAL FOR
			SELECT	QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2, N.SS_ID,
					O.SS_PRKey, O.SS_Date, O.SS_IsDeleted, O.SS_QDID,
					N.SS_PRKey, N.SS_Date, N.SS_IsDeleted, N.SS_QDID
			FROM	DELETED O, INSERTED N, dbo.QuotaObjects
			WHERE	N.SS_QOID=QO_ID and O.SS_ID=N.SS_ID
	END
	OPEN cur_StopSales
	FETCH NEXT FROM cur_StopSales INTO 
			@QO_SVKey, @QO_Code, @QO_SubCode1, @QO_SubCode2, @SS_ID,
			@OSS_PRKey, @OSS_Date, @OSS_IsDeleted, @OSS_QDID,
			@NSS_PRKey, @NSS_Date, @NSS_IsDeleted, @NSS_QDID
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OSS_PRKey, 0) != ISNULL(@NSS_PRKey, 0) OR
			ISNULL(@OSS_Date, GetDate()) != ISNULL(@NSS_Date, GetDate()) OR
			ISNULL(@OSS_IsDeleted, 0) != ISNULL(@NSS_IsDeleted, 0)
			) and @insToHistory <> '0'
		BEGIN
			------------Запись в историю--------------------------------------------------------------------
			If @sMod = 'DEL'
			BEGIN
				Set @SS_PRKey=@OSS_PRKey
				Set @SS_Date=@OSS_Date
				Set @SS_QDID=@OSS_QDID
			END
			Else
			BEGIN
				Set @SS_PRKey=@NSS_PRKey
				Set @SS_Date=@NSS_Date
				Set @SS_QDID=@NSS_QDID
			END
			
			--insert into Debug(db_n1,db_n2,db_n3) values (361,@QO_SVKey,@QO_SubCode1)
			If @QO_SubCode1 is not null
				exec dbo.GetServiceNameByCode 4,@QO_SVKey,null,@QO_SubCode1,null,1,@sHI_Text output,null
			If ISNULL(@sHI_Text,'')!=''
				Set @sText_New=@sHI_Text
			Set @sHI_Text=null
			--insert into Debug(db_n1,db_n2,db_n3) values (362,@QO_SVKey,@QO_SubCode2)
			If @QO_SubCode2 is not null
				exec dbo.GetServiceNameByCode 5,@QO_SVKey,null,null,@QO_SubCode2,1,@sHI_Text output,null
			If ISNULL(@sHI_Text,'')!=''
				Set @sText_New=@sText_New + ',' + @sHI_Text
			Set @sHI_Text=null
			If @SS_PRKey=0
				Set @sHI_Text='All partners'
			Else
				Select @sHI_Text=PR_Name from Partners where PR_Key=@SS_PRKey
			If ISNULL(@sText_New,'')!=''
				Set @sText_New=@sText_New + ' (' + @sHI_Text + ')'
			Else
				Set @sText_New=@sHI_Text
			Set @sHI_Text=null
			
			SET @sHI_Text='A'
			If @SS_QDID is not null
				if exists (SELECT 1 FROM dbo.QuotaDetails WHERE QD_ID=@SS_QDID and QD_Type=2)
					SET @sHI_Text='C'
			Set @sHI_Text=@sHI_Text+' (' + CONVERT(varchar(20),@SS_Date,104)+')'

			IF @NSS_IsDeleted=1 and ISNULL(@OSS_IsDeleted,0)=0
				SET @sMod='DEL'
			--EXEC @nHIID = dbo.InsHistory '', null, 14, @SS_Id, @sMod, @sText_New, '', 0, @sHI_Text, 0, @QO_SVKey, @QO_Code
			EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 14,
							@nTypeCode = @SS_ID,
							@sMod = @sMod,
							@sText = @sText_New,
							@sRemark = @sHI_Text,
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = @QO_SVKey,
							@nCode = @QO_Code
			SET @sText_Old=''
			SET @sText_New=''
			
			--------Детализация--------------------------------------------------
			if ISNULL(@OSS_PRKey, -1) != ISNULL(@NSS_PRKey, -1)
			BEGIN
				If @OSS_PRKey=0
					Set @sText_Old='All partners'
				Else If @OSS_PRKey is not null
					Select @sText_Old=PR_Name from Partners where PR_Key=@OSS_PRKey
				If @NSS_PRKey=0
					Set @sText_New='All partners'
				Else If @NSS_PRKey is not null
					Select @sText_New = PR_Name from Partners where PR_Key=@NSS_PRKey
				EXECUTE dbo.InsertHistoryDetail @nHIID, 14001, @sText_Old, @sText_New, @OSS_PRKey, @NSS_PRKey, null, null, 0
				SET @sText_Old=''
				SET @sText_New=''				
			END
			if ISNULL(@OSS_Date, GetDate()) != ISNULL(@NSS_Date, GetDate())
			BEGIN
				If @OSS_Date is not null
					Set @sText_Old=CONVERT(varchar(20),@OSS_Date,104)
				If @NSS_Date is not null
					Set @sText_New=CONVERT(varchar(20),@NSS_Date,104)
				EXECUTE dbo.InsertHistoryDetail @nHIID, 14002, @sText_Old, @sText_New, null, null, @OSS_Date, @NSS_Date, 0
				SET @sText_Old=''
				SET @sText_New=''
			END	
		END

		Update StopSales set SS_LastUpdate = GetDate() where SS_ID = @SS_ID	

		-- удаление стопов из Протура, если происходит удаление из Мт
		if (@sMod = 'DEL' and exists (select 1 from SystemSettings where SS_ParmName='SYSDeleteProtourQuotes' and SS_ParmValue = 1))
		begin				
			if (@QO_SVKey = 3 and @QO_SubCode1 = 0)
			begin
				delete from ProTourQuotes 
					where PTQ_HotelKey = @QO_Code
					AND PTQ_Date = @OSS_Date
					AND PTQ_RoomCategoryKey = @QO_SubCode2
					AND PTQ_StopSale = 1
					AND PTQ_CancelStopSale = 0
			end								
		end

		FETCH NEXT FROM cur_StopSales INTO 
			@QO_SVKey, @QO_Code, @QO_SubCode1, @QO_SubCode2, @SS_ID,
			@OSS_PRKey, @OSS_Date, @OSS_IsDeleted, @OSS_QDID,
			@NSS_PRKey, @NSS_Date, @NSS_IsDeleted, @NSS_QDID
    END
	CLOSE cur_StopSales
	DEALLOCATE cur_StopSales
END
GO
/*********************************************************************/
/* end T_StopSalesChange.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TuristUpdate.sql */
/*********************************************************************/
update Turist set TU_ISMAIN = 0 where TU_KEY not in 
(
select MIN(tu_key)
from Dogovor, Turist where TU_DGKEY = DG_Key and TU_ISMAIN = 1 group by DG_Key having COUNT(*) > 1
)
and TU_DGKEY in 
(
select dg_key from Dogovor, Turist where TU_DGKEY = DG_Key and TU_ISMAIN = 1 group by DG_Key having COUNT(*) > 1
)
and TU_ISMAIN = 1

GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_TuristUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_TuristUpdate]
GO


CREATE TRIGGER [dbo].[T_TuristUpdate]
ON [dbo].[tbl_Turist] 
FOR UPDATE, INSERT, DELETE
AS
--<DATE>2014-04-02</DATE>
--<VERSION>2009.2.20.11</VERSION>
IF @@ROWCOUNT > 0
BEGIN
    DECLARE @OTU_DGCod 		varchar(10)
    DECLARE @OTU_NameRus 		varchar(25)
    DECLARE @OTU_NameLat 		varchar(25)
    DECLARE @OTU_FNameRus 	varchar(15)
    DECLARE @OTU_FNameLat 		varchar(15)
    DECLARE @OTU_SNameRus 	varchar(15)
    DECLARE @OTU_SNameLat 		varchar(15)
    DECLARE @OTU_BirthDay 		varchar(10)
    DECLARE @OTU_PasportType 	varchar(10)
    DECLARE @OTU_PasportNum 	varchar(20)
    DECLARE @OTU_PaspRuSer 	varchar(10)
    DECLARE @OTU_PaspRuNum 	varchar(20)
    DECLARE @OTU_PasportDate 	varchar(10)
    DECLARE @OTU_PasportDateEnd 	varchar(10)
    DECLARE @OTU_PasportByWhoM 	varchar(20)
    DECLARE @OTU_PaspRuDate 	varchar(10)
    DECLARE @OTU_PaspRuByWhoM 	varchar(50)
    DECLARE @OTU_Sex 	int
    DECLARE @OTU_RealSex 	int
	DECLARE @OTU_DGKey		int
-- 
	DECLARE @OTU_BIRTHCOUNTRY varchar(25)
	DECLARE @OTU_BIRTHCITY varchar(25)
    DECLARE @OTU_CITIZEN varchar(50)
	DECLARE @OTU_POSTINDEX varchar(8)
	DECLARE @OTU_POSTCITY varchar(15)
	DECLARE @OTU_POSTSTREET varchar(25)
	DECLARE @OTU_POSTBILD varchar(6)
	DECLARE @OTU_POSTFLAT varchar(4)

	DECLARE @OTU_ISMAIN smallint
	DECLARE @OTU_PHONE varchar(30)
	DECLARE @OTU_EMAIL varchar(50)
    
    DECLARE @NTU_DGCod 		varchar(10)
    DECLARE @NTU_NameRus 		varchar(25)
    DECLARE @NTU_NameLat 		varchar(25)
    DECLARE @NTU_FNameRus 	varchar(15)
    DECLARE @NTU_FNameLat 		varchar(15)
    DECLARE @NTU_SNameRus 	varchar(15)
    DECLARE @NTU_SNameLat 		varchar(15)
    DECLARE @NTU_BirthDay 		varchar(10)
    DECLARE @NTU_PasportType 	varchar(10)
    DECLARE @NTU_PasportNum 	varchar(20)
    DECLARE @NTU_PaspRuSer 	varchar(10)
    DECLARE @NTU_PaspRuNum 	varchar(20)
    DECLARE @NTU_PasportDate 	varchar(10)
    DECLARE @NTU_PasportDateEnd 	varchar(10)
    DECLARE @NTU_PasportByWhoM 	varchar(20)
    DECLARE @NTU_PaspRuDate 	varchar(10)
    DECLARE @NTU_PaspRuByWhoM 	varchar(50)
    DECLARE @NTU_Sex 	int
    DECLARE @NTU_RealSex 	int
	DECLARE @NTU_DGKey		int
--
	DECLARE @NTU_BIRTHCOUNTRY varchar(25)
	DECLARE @NTU_BIRTHCITY varchar(25)
    DECLARE @NTU_CITIZEN varchar(50)
	DECLARE @NTU_POSTINDEX varchar(8)
	DECLARE @NTU_POSTCITY varchar(15)
	DECLARE @NTU_POSTSTREET varchar(25)
	DECLARE @NTU_POSTBILD varchar(6)
	DECLARE @NTU_POSTFLAT varchar(4)

	DECLARE @NTU_ISMAIN smallint
	DECLARE @NTU_PHONE varchar(30)
	DECLARE @NTU_EMAIL varchar(50)

	DECLARE @TU_Key int

	DECLARE @sTU_ShortName varchar(8)
	DECLARE @sMod varchar(3)
	DECLARE @nDelCount int
	DECLARE @nInsCount int
	DECLARE @nHIID int
	DECLARE @sHI_Text varchar(254)

	DECLARE @sText_Old varchar(254)
	DECLARE @sText_New varchar(254)
	DECLARE @bNeedCommunicationUpdate smallint
	DECLARE @nDGKey int
	DECLARE @sDGCod	varchar(10)

  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED
  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_Turist CURSOR FOR 
      SELECT N.TU_Key, N.TU_ShortName,
			 N.TU_DGCod, N.TU_DGKey, null, null, null, null, 
	  	     null, null, null, null, null, null,
			 null, null, null, null, null, null,
			 null, null,
			 null, null, null, null,
			 null, null, null, null, null, null, null,
		  	 N.TU_DGCod, N.TU_DGKey, N.TU_NameRus, N.TU_NameLat, N.TU_FNameRus, N.TU_FNameLat,
			 N.TU_SNameRus, N.TU_SNameLat, CONVERT( char(10),N.TU_BirthDay, 104), N.TU_PasportType, N.TU_PasportNum, N.TU_PaspRuSer,
			 N.TU_PaspRuNum, CONVERT( char(10),N.TU_PasportDate, 104), CONVERT( char(10),N.TU_PasportDateEnd, 104), N.TU_PasportByWhoM, CONVERT( char(10),N.TU_PaspRuDate, 104), N.TU_PaspRuByWhoM,
			 N.TU_Sex, N.TU_RealSex, 
				N.TU_BIRTHCOUNTRY,
				N.TU_BIRTHCITY,
				N.TU_CITIZEN,
				N.TU_POSTINDEX,
				N.TU_POSTCITY,
				N.TU_POSTSTREET,
				N.TU_POSTBILD,
				N.TU_POSTFLAT,
				N.TU_ISMAIN,
				N.TU_PHONE,
				N.TU_EMAIL
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_Turist CURSOR FOR 
      SELECT O.TU_Key, O.TU_ShortName,
			 O.TU_DGCod, O.TU_DGKey, O.TU_NameRus, O.TU_NameLat, O.TU_FNameRus, O.TU_FNameLat,
			 O.TU_SNameRus, O.TU_SNameLat, CONVERT( char(10),O.TU_BirthDay, 104), O.TU_PasportType, O.TU_PasportNum, O.TU_PaspRuSer,
			 O.TU_PaspRuNum, CONVERT( char(10), O.TU_PasportDate, 104), CONVERT( char(10), O.TU_PasportDateEnd, 104), O.TU_PasportByWhoM, CONVERT( char(10), O.TU_PaspRuDate, 104), O.TU_PaspRuByWhoM, 
			 O.TU_Sex, O.TU_RealSex, 
				O.TU_BIRTHCOUNTRY,
				O.TU_BIRTHCITY,
				O.TU_CITIZEN,
				O.TU_POSTINDEX,
				O.TU_POSTCITY,
				O.TU_POSTSTREET,
				O.TU_POSTBILD,
				O.TU_POSTFLAT,
				O.TU_ISMAIN,
				O.TU_PHONE,
				O.TU_EMAIL,
		  	 O.TU_DGCod, O.TU_DGKey, null, null, null, null,
			 null, null, null, null, null, null,
			 null, null, null, null, null, null,
			 null, null,
			 null, null, null, null,
			 null, null, null, null, null, null, null
      FROM DELETED O 
  END
  ELSE 
  BEGIN
	SET @sMod = 'UPD'
    DECLARE cur_Turist CURSOR FOR 
      SELECT N.TU_Key, N.TU_ShortName,
			 O.TU_DGCod, O.TU_DGKey, O.TU_NameRus, O.TU_NameLat, O.TU_FNameRus, O.TU_FNameLat,
			 O.TU_SNameRus, O.TU_SNameLat, CONVERT( char(10),O.TU_BirthDay, 104), O.TU_PasportType, O.TU_PasportNum, O.TU_PaspRuSer,
			 O.TU_PaspRuNum, CONVERT( char(10), O.TU_PasportDate, 104), CONVERT( char(10), O.TU_PasportDateEnd, 104), O.TU_PasportByWhoM, CONVERT( char(10), O.TU_PaspRuDate, 104), O.TU_PaspRuByWhoM, 
			 O.TU_Sex, O.TU_RealSex, 
				O.TU_BIRTHCOUNTRY,
				O.TU_BIRTHCITY,
				O.TU_CITIZEN,
				O.TU_POSTINDEX,
				O.TU_POSTCITY,
				O.TU_POSTSTREET,
				O.TU_POSTBILD,
				O.TU_POSTFLAT,
				O.TU_ISMAIN,
				O.TU_PHONE,
				O.TU_EMAIL,
		  	 N.TU_DGCod, N.TU_DGKey, N.TU_NameRus, N.TU_NameLat, N.TU_FNameRus, N.TU_FNameLat, 
			 N.TU_SNameRus, N.TU_SNameLat, CONVERT( char(10),N.TU_BirthDay, 104), N.TU_PasportType, N.TU_PasportNum, N.TU_PaspRuSer,
			 N.TU_PaspRuNum, CONVERT( char(10),N.TU_PasportDate, 104), CONVERT( char(10),N.TU_PasportDateEnd, 104), N.TU_PasportByWhoM, CONVERT( char(10),N.TU_PaspRuDate, 104), N.TU_PaspRuByWhoM,
			 N.TU_Sex, N.TU_RealSex, 
				N.TU_BIRTHCOUNTRY,
				N.TU_BIRTHCITY,
				N.TU_CITIZEN,
				N.TU_POSTINDEX,
				N.TU_POSTCITY,
				N.TU_POSTSTREET,
				N.TU_POSTBILD,
				N.TU_POSTFLAT,
				N.TU_ISMAIN,
				N.TU_PHONE,
				N.TU_EMAIL
      FROM DELETED O, INSERTED N 
      WHERE N.TU_Key = O.TU_Key
  END

  OPEN cur_Turist
    FETCH NEXT FROM cur_Turist INTO @TU_Key, @sTU_ShortName,
				@OTU_DGCod, @OTU_DGKey, @OTU_NameRus, @OTU_NameLat, @OTU_FNameRus, @OTU_FNameLat,
				@OTU_SNameRus, @OTU_SNameLat, @OTU_BirthDay, @OTU_PasportType, @OTU_PasportNum,	@OTU_PaspRuSer,
				@OTU_PaspRuNum, @OTU_PasportDate, @OTU_PasportDateEnd, @OTU_PasportByWhoM, @OTU_PaspRuDate, @OTU_PaspRuByWhoM, 
				@OTU_Sex, @OTU_RealSex, 
				@OTU_BIRTHCOUNTRY,
				@OTU_BIRTHCITY,
				@OTU_CITIZEN,
				@OTU_POSTINDEX,
				@OTU_POSTCITY,
				@OTU_POSTSTREET,
				@OTU_POSTBILD,
				@OTU_POSTFLAT,
				@OTU_ISMAIN,
				@OTU_PHONE,
				@OTU_EMAIL,
				@NTU_DGCod, @NTU_DGKey, @NTU_NameRus, @NTU_NameLat,	@NTU_FNameRus, @NTU_FNameLat,
				@NTU_SNameRus, @NTU_SNameLat, @NTU_BirthDay, @NTU_PasportType, @NTU_PasportNum,	@NTU_PaspRuSer,
				@NTU_PaspRuNum, @NTU_PasportDate, @NTU_PasportDateEnd, @NTU_PasportByWhoM, @NTU_PaspRuDate, @NTU_PaspRuByWhoM,
				@NTU_Sex, @NTU_RealSex,
				@NTU_BIRTHCOUNTRY,
				@NTU_BIRTHCITY,
				@NTU_CITIZEN,
				@NTU_POSTINDEX,
				@NTU_POSTCITY,
				@NTU_POSTSTREET,
				@NTU_POSTBILD,
				@NTU_POSTFLAT,
				@NTU_ISMAIN,
				@NTU_PHONE,
				@NTU_EMAIL
    WHILE @@FETCH_STATUS = 0
    BEGIN 	
	  If ((((@sMod = 'UPD') AND (@OTU_DGCod = @NTU_DGCod)) OR (@sMod = 'INS') OR (@sMod = 'DEL')) AND
		(
			ISNULL(@OTU_NameRus, '') != ISNULL(@NTU_NameRus, '') OR
			ISNULL(@OTU_NameLat, '') != ISNULL(@NTU_NameLat, '') OR
			ISNULL(@OTU_FNameRus, '') != ISNULL(@NTU_FNameRus, '') OR
			ISNULL(@OTU_FNameLat, '') != ISNULL(@NTU_FNameLat, '') OR
			ISNULL(@OTU_SNameRus, '') != ISNULL(@NTU_SNameRus, '') OR
			ISNULL(@OTU_SNameLat, '') != ISNULL(@NTU_SNameLat, '') OR
			ISNULL(@OTU_BirthDay, 0) != ISNULL(@NTU_BirthDay, 0) OR
			ISNULL(@OTU_PasportType, 0) != ISNULL(@NTU_PasportType, 0) OR
			ISNULL(@OTU_PasportNum, 0) != ISNULL(@NTU_PasportNum, 0) OR
			ISNULL(@OTU_PaspRuSer, 0) != ISNULL(@NTU_PaspRuSer, 0) OR
			ISNULL(@OTU_PaspRuNum, 0) != ISNULL(@NTU_PaspRuNum, 0) OR
			ISNULL(@OTU_PasportDate, 0) != ISNULL(@NTU_PasportDate, 0) OR
			ISNULL(@OTU_PasportDateEnd, 0) != ISNULL(@NTU_PasportDateEnd, 0) OR
			ISNULL(@OTU_PasportByWhoM, 0) != ISNULL(@NTU_PasportByWhoM, 0) OR
			ISNULL(@OTU_PaspRuDate, 0) != ISNULL(@NTU_PaspRuDate, 0) OR
			ISNULL(@OTU_PaspRuByWhoM, 0) != ISNULL(@NTU_PaspRuByWhoM, 0)  OR
			ISNULL(@OTU_Sex, 0) != ISNULL(@NTU_Sex, 0)  OR
			ISNULL(@OTU_RealSex, 0) != ISNULL(@NTU_RealSex, 0) OR
--
			ISNULL(@OTU_BIRTHCOUNTRY, '') != ISNULL(@NTU_BIRTHCOUNTRY, '') OR
			ISNULL(@OTU_BIRTHCITY, '') != ISNULL(@NTU_BIRTHCITY, '') OR
			ISNULL(@OTU_CITIZEN, '') != ISNULL(@NTU_CITIZEN, '') OR
			ISNULL(@OTU_POSTINDEX, '') != ISNULL(@NTU_POSTINDEX, '') OR
			ISNULL(@OTU_POSTCITY, '') != ISNULL(@NTU_POSTCITY, '') OR
			ISNULL(@OTU_POSTSTREET, '') != ISNULL(@NTU_POSTSTREET, '') OR
			ISNULL(@OTU_POSTBILD, '') != ISNULL(@NTU_POSTBILD, '') OR
			ISNULL(@OTU_POSTFLAT, '') != ISNULL(@NTU_POSTFLAT, '') OR
			ISNULL(@OTU_ISMAIN, 0) != ISNULL(@NTU_ISMAIN, 0)
		))
	  BEGIN
	
		
		SET @nDGKey=@NTU_DGKey
		SET @sHI_Text = ISNULL(@NTU_NameRus, '') + ' ' + ISNULL(@sTU_ShortName, '')
		SET @sDGCod=@NTU_DGCod
		if (@sMod = 'DEL')
		BEGIN
			SET @nDGKey=@OTU_DGKey
			SET @sHI_Text = ISNULL(@OTU_NameRus, '') + ' ' + ISNULL(@sTU_ShortName, '')
			SET @sDGCod=@OTU_DGCod
		END
		EXEC @nHIID = dbo.InsHistory @sDGCod, @nDGKey, 3, @TU_Key, @sMod, @sHI_Text, '', 0, ''	
		if (ISNULL(@OTU_NameRus, '') != ISNULL(@NTU_NameRus, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1051, @OTU_NameRus, @NTU_NameRus, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_NameLat, '') != ISNULL(@NTU_NameLat, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1052, @OTU_NameLat, @NTU_NameLat, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_FNameRus, '') != ISNULL(@NTU_FNameRus, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1053, @OTU_FNameRus, @NTU_FNameRus, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_FNameLat, '') != ISNULL(@NTU_FNameLat, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1054, @OTU_FNameLat, @NTU_FNameLat, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_SNameRus, '') != ISNULL(@NTU_SNameRus, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1055, @OTU_SNameRus, @NTU_SNameRus, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_SNameLat, '') != ISNULL(@NTU_SNameLat, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1056, @OTU_SNameLat, @NTU_SNameLat, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_BirthDay, 0) != ISNULL(@NTU_BirthDay, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1057, @OTU_BirthDay, @NTU_BirthDay, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_PasportType, '') != ISNULL(@NTU_PasportType, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1058, @OTU_PasportType, @NTU_PasportType, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_PasportNum, '') != ISNULL(@NTU_PasportNum, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1059, @OTU_PasportNum, @NTU_PasportNum, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_PaspRuSer, '') != ISNULL(@NTU_PaspRuSer, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1060, @OTU_PaspRuSer, @NTU_PaspRuSer, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_PaspRuNum, '') != ISNULL(@NTU_PaspRuNum, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1061, @OTU_PaspRuNum, @NTU_PaspRuNum, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_PasportDate, 0) != ISNULL(@NTU_PasportDate, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1062, @OTU_PasportDate, @NTU_PasportDate, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_PasportDateEnd, 0) != ISNULL(@NTU_PasportDateEnd, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1063, @OTU_PasportDateEnd, @NTU_PasportDateEnd, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_PasportByWhoM, '') != ISNULL(@NTU_PasportByWhoM, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1064, @OTU_PasportByWhoM, @NTU_PasportByWhoM, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_PaspRuDate, 0) != ISNULL(@NTU_PaspRuDate, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1065, @OTU_PaspRuDate, @NTU_PaspRuDate, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_PaspRuByWhoM, '') != ISNULL(@NTU_PaspRuByWhoM, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1066, @OTU_PaspRuByWhoM, @NTU_PaspRuByWhoM, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_Sex, 0) != ISNULL(@NTU_Sex, 0))
			BEGIN
				IF not ((ISNULL(@OTU_Sex, 0) = 1 and ISNULL(@NTU_Sex, 0) = 0) or (ISNULL(@OTU_Sex, 0) = 0 and ISNULL(@NTU_Sex, 0) = 1))
				BEGIN
					IF @sMod != 'INS'
						SELECT @sText_Old = CASE ISNULL(@OTU_Sex, 0)
								WHEN 0 THEN 'Adult'
								WHEN 1 THEN 'Adult'
								WHEN 2 THEN 'Child'
								WHEN 3 THEN 'Infant'
								END
					ELSE
						SET @sText_Old = ''
					IF @sMod != 'DEL'
						SELECT @sText_New = CASE ISNULL(@NTU_Sex, 0)
								WHEN 0 THEN 'Adult'
								WHEN 1 THEN 'Adult'
								WHEN 2 THEN 'Child'
								WHEN 3 THEN 'Infant'
								END
					ELSE
						SET @sText_New = ''
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1067, @sText_Old, @sText_New, @OTU_Sex, @NTU_Sex, null, null, 0, @bNeedCommunicationUpdate output
				END
			END
		if (ISNULL(@OTU_RealSex, 0) != ISNULL(@NTU_RealSex, 0))
		BEGIN
				IF @sMod != 'INS'
					SELECT @sText_Old = CASE ISNULL(@OTU_RealSex, 0)
							WHEN 0 THEN 'Male'
							WHEN 1 THEN 'Female'
							END
				ELSE
					Set @sText_Old = ''
				IF @sMod != 'DEL'
					SELECT @sText_New = CASE ISNULL(@NTU_RealSex, 0)
							WHEN 0 THEN 'Male'
							WHEN 1 THEN 'Female'
							END
				ELSE
					Set	@sText_New = ''
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1068, @sText_Old, @sText_New, @OTU_RealSex, @NTU_RealSex, null, null, 0, @bNeedCommunicationUpdate output
		END

		if (ISNULL(@OTU_BIRTHCOUNTRY, '') != ISNULL(@NTU_BIRTHCOUNTRY, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1126, @OTU_BIRTHCOUNTRY, @NTU_BIRTHCOUNTRY, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_BIRTHCITY, '') != ISNULL(@NTU_BIRTHCITY, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1127, @OTU_BIRTHCITY, @NTU_BIRTHCITY, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_CITIZEN, '') != ISNULL(@NTU_CITIZEN, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1128, @OTU_CITIZEN, @NTU_CITIZEN, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_POSTINDEX, '') != ISNULL(@NTU_POSTINDEX, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1129, @OTU_POSTINDEX, @NTU_POSTINDEX, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_POSTCITY, '') != ISNULL(@NTU_POSTCITY, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1130, @OTU_POSTCITY, @NTU_POSTCITY, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_POSTSTREET, '') != ISNULL(@NTU_POSTSTREET, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1131, @OTU_POSTSTREET, @NTU_POSTSTREET, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_POSTBILD, '') != ISNULL(@NTU_POSTBILD, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1132, @OTU_POSTBILD, @NTU_POSTBILD, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@OTU_POSTFLAT, '') != ISNULL(@NTU_POSTFLAT, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1133, @OTU_POSTFLAT, @NTU_POSTFLAT, null, null, null, null, 0, @bNeedCommunicationUpdate output
		-- 
		DECLARE @PrivatePerson int;
		DECLARE @NewMainTourist int;
		DECLARE @HaveMainMan int, @MainManSex int;
		DECLARE @Name varchar(35),
			@FName varchar(15),
			@SName varchar(15),
			@Phone varchar(60),
			@Email varchar(50),
			@PostIndex varchar(8),
			@PostCity varchar(60),
			@PostStreet varchar(25),
			@PostBuilding varchar(10),
			@PostFlat varchar(4),
			@PassportSeries varchar(10),
			@PassportNumber varchar(10);		
		IF (@sMod = 'UPD')
		BEGIN
			IF ISNULL(@OTU_ISMAIN, 0) != ISNULL(@NTU_ISMAIN, 0)
				BEGIN
					IF(ISNULL(@NTU_ISMAIN,0) >= 1)
						BEGIN
							UPDATE [dbo].[TBL_TURIST]
							SET TU_ISMAIN = 0
							WHERE TU_KEY <> @TU_Key AND TU_DGCOD = @NTU_DGCod;
						
							UPDATE [dbo].[TBL_TURIST]
							SET TU_ISMAIN = 1
							WHERE TU_KEY = @TU_Key
						 
							EXEC @PrivatePerson = dbo.CheckPrivatePerson @NTU_DGCOD;
							IF(@PrivatePerson = 1)
								BEGIN
									EXEC [dbo].[UpdateReservationMainManByTourist] @NTU_NAMERUS, @NTU_FNAMERUS, @NTU_SNAMERUS, @NTU_PHONE, @NTU_EMAIL
																				 , @NTU_POSTINDEX, @NTU_POSTCITY, @NTU_POSTSTREET
																				 , @NTU_POSTBILD, @NTU_POSTFLAT, @NTU_PASPRUSER
																				 , @NTU_PASPRUNUM, @NTU_DGCOD;
								END
						END
					ELSE
						BEGIN
							SELECT @HaveMainMan = TU_KEY, @MainManSex = TU_SEX
								FROM [dbo].[TBL_TURIST]
								WHERE TU_KEY <> @TU_Key AND TU_DGCOD = @NTU_DGCOD AND TU_ISMAIN = 1
							IF @HaveMainMan IS NULL
								BEGIN
									SELECT @NewMainTourist = TU_KEY 
									FROM [dbo].[TBL_TURIST]
									WHERE TU_KEY <> @TU_Key AND TU_SEX < 2 AND TU_DGCOD = @NTU_DGCOD;
									IF(@NewMainTourist IS NULL)
										BEGIN
											SELECT @NewMainTourist = TU_KEY 
											FROM [dbo].[TBL_TURIST]
											WHERE TU_KEY <> @TU_Key AND TU_DGCOD = @NTU_DGCOD;
										END
									IF(@NewMainTourist IS NOT NULL)
										BEGIN
											UPDATE [dbo].[TBL_TURIST]
											SET TU_ISMAIN = 0
											WHERE TU_KEY <> @NewMainTourist AND TU_DGCOD = @NTU_DGCod;
									
											UPDATE [dbo].[TBL_TURIST]
											SET TU_ISMAIN = 1
											WHERE TU_KEY = @NewMainTourist;
										
											EXEC @PrivatePerson = dbo.CheckPrivatePerson @OTU_DGCOD;
											IF(@PrivatePerson = 1)
											BEGIN
												SELECT @Name = TU_NAMERUS, @FName = TU_FNAMERUS, @SName = TU_SNAMERUS, @Phone = TU_PHONE, @Email=TU_EMAIL
												, @PostIndex = TU_POSTINDEX, @PostCity = TU_POSTCITY, @PostStreet = TU_POSTSTREET
												, @PostBuilding = TU_POSTBILD, @PostFlat = TU_POSTFLAT, @PassportSeries = TU_PASPRUSER
												, @PassportNumber = TU_PASPRUNUM
												FROM [dbo].[tbl_turist]
												WHERE TU_KEY = @NewMainTourist;
												EXEC [dbo].[UpdateReservationMainManByTourist] @Name, @FName, @SName, @Phone, @Email
																					 , @PostIndex, @PostCity, @PostStreet
																					 , @PostBuilding, @PostFlat, @PassportSeries
																					 , @PassportNumber, @OTU_DGCOD;
											END
										END
								END	
						END
				END	
			ELSE IF ISNULL(@OTU_ISMAIN, 0) = ISNULL(@NTU_ISMAIN, 0) 
					AND  ISNULL(@NTU_ISMAIN, 0) >= 1					
					AND (ISNULL(@OTU_NameRus, '') != ISNULL(@NTU_NameRus, '') 
						OR ISNULL(@OTU_FNameRus, '') != ISNULL(@NTU_FNameRus, '')
						OR ISNULL(@OTU_SNameRus, '') != ISNULL(@NTU_SNameRus, '')
						OR ISNULL(@OTU_PHONE, '') != ISNULL(@NTU_PHONE, '')
						OR ISNULL(@OTU_EMAIL, '') != ISNULL(@NTU_EMAIL, '')
						OR ISNULL(@OTU_POSTINDEX, '') != ISNULL(@NTU_POSTINDEX, '')
						OR ISNULL(@OTU_POSTCITY, '') != ISNULL(@NTU_POSTCITY, '')
						OR ISNULL(@OTU_POSTSTREET, '') != ISNULL(@NTU_POSTSTREET, '')
						OR ISNULL(@OTU_POSTBILD, '') != ISNULL(@NTU_POSTBILD, '')
						OR ISNULL(@OTU_POSTFLAT, '') != ISNULL(@NTU_POSTFLAT, '')
						OR ISNULL(@OTU_PASPRUSER, '') != ISNULL(@NTU_PASPRUSER, '')
						OR ISNULL(@OTU_PASPRUNUM, '') != ISNULL(@NTU_PASPRUNUM, '')
						OR ISNULL(@OTU_DGCOD, '') != ISNULL(@NTU_DGCOD, ''))	
				BEGIN
					SELECT @HaveMainMan = TU_KEY, @MainManSex = TU_SEX
							FROM [dbo].[TBL_TURIST]
							WHERE TU_KEY <> @TU_Key AND TU_DGCOD = @NTU_DGCOD AND TU_ISMAIN = 1
					IF 	@HaveMainMan IS NULL 
						BEGIN
							EXEC @PrivatePerson = dbo.CheckPrivatePerson @NTU_DGCOD;
							IF(@PrivatePerson = 1)
								BEGIN									
									EXEC [dbo].[UpdateReservationMainManByTourist] @NTU_NAMERUS, @NTU_FNAMERUS, @NTU_SNAMERUS, @NTU_PHONE, @NTU_EMAIL
																			 , @NTU_POSTINDEX, @NTU_POSTCITY, @NTU_POSTSTREET
																			 , @NTU_POSTBILD, @NTU_POSTFLAT, @NTU_PASPRUSER
																			 , @NTU_PASPRUNUM, @NTU_DGCOD;
								END
						END		
				END
		END
		ELSE IF (@sMod = 'DEL')
		BEGIN
			DECLARE @MainTouristExists int;
			SELECT @MainTouristExists = TU_KEY 
			  FROM [dbo].[TBL_TURIST]
			 WHERE TU_KEY <> @TU_Key AND TU_DGCOD = @OTU_DGCOD AND TU_ISMAIN = 1;
		
			IF @MainTouristExists IS NULL
				BEGIN
					SELECT @NewMainTourist = TU_KEY 
					  FROM [dbo].[TBL_TURIST]
					 WHERE TU_KEY <> @TU_Key AND TU_SEX < 2 AND TU_DGCOD = @OTU_DGCOD;
					IF(@NewMainTourist IS NULL)
					BEGIN
						SELECT @NewMainTourist = TU_KEY 
						  FROM [dbo].[TBL_TURIST]
						 WHERE TU_KEY <> @TU_Key AND TU_DGCOD = @OTU_DGCOD;
					END
					IF(@NewMainTourist IS NOT NULL)
					BEGIN
						UPDATE [dbo].[TBL_TURIST]
						   SET TU_ISMAIN = 1
						 WHERE TU_KEY = @NewMainTourist;
							EXEC @PrivatePerson = dbo.CheckPrivatePerson @OTU_DGCOD;
							IF(@PrivatePerson = 1)
							BEGIN
								SELECT @Name = TU_NAMERUS, @FName = TU_FNAMERUS, @SName = TU_SNAMERUS, @Phone = TU_PHONE, @Email=TU_EMAIL
									 , @PostIndex = TU_POSTINDEX, @PostCity = TU_POSTCITY, @PostStreet = TU_POSTSTREET
									 , @PostBuilding = TU_POSTBILD, @PostFlat = TU_POSTFLAT, @PassportSeries = TU_PASPRUSER
									 , @PassportNumber = TU_PASPRUNUM
								  FROM [dbo].[tbl_turist]
								 WHERE TU_KEY = @NewMainTourist;
								EXEC [dbo].[UpdateReservationMainManByTourist] @Name, @FName, @SName, @Phone, @Email
																			 , @PostIndex, @PostCity, @PostStreet
																			 , @PostBuilding, @PostFlat, @PassportSeries
																			 , @PassportNumber, @OTU_DGCOD;
							END
							ELSE
							BEGIN
								EXEC [dbo].[UpdateReservationMainMan] '','','','','',@OTU_DGCOD;
							END
						END
				END	
			END	
		ELSE IF(@sMod = 'INS')
		BEGIN
			SELECT @HaveMainMan = TU_KEY, @MainManSex = TU_SEX
			  FROM [dbo].[TBL_TURIST]
			 WHERE TU_KEY <> @TU_Key AND TU_DGCOD = @NTU_DGCOD AND TU_ISMAIN = 1
			IF(@HaveMainMan IS NULL OR ((ISNULL(@MainManSex,0) >= 2) AND ISNULL(@NTU_SEX,99) < 2 AND ISNULL(@NTU_ISMAIN,0) = 1))
			BEGIN
				IF(@HaveMainMan IS NULL)
				BEGIN
					UPDATE [dbo].[TBL_TURIST]
					   SET TU_ISMAIN = 1
					 WHERE TU_KEY = @TU_Key;
				END
				ELSE
				BEGIN
					UPDATE [dbo].[TBL_TURIST]
					   SET TU_ISMAIN = 0
					 WHERE TU_KEY = @HaveMainMan;
				END				
					EXEC @PrivatePerson = dbo.CheckPrivatePerson @NTU_DGCOD;
					IF(@PrivatePerson = 1)
					BEGIN
						EXEC [dbo].[UpdateReservationMainManByTourist] @NTU_NAMERUS, @NTU_FNAMERUS, @NTU_SNAMERUS, @NTU_PHONE, @NTU_EMAIL
																	 , @NTU_POSTINDEX, @NTU_POSTCITY, @NTU_POSTSTREET
																	 , @NTU_POSTBILD, @NTU_POSTFLAT, @NTU_PASPRUSER
																	 , @NTU_PASPRUNUM, @NTU_DGCOD;
					END
				END		
			ELSE IF(@HaveMainMan IS NOT NULL AND ISNULL(@NTU_ISMAIN,0) = 1)
			BEGIN
				UPDATE [dbo].[TBL_TURIST]
				   SET TU_ISMAIN = 0
				 WHERE TU_KEY = @HaveMainMan; 
				
					EXEC @PrivatePerson = dbo.CheckPrivatePerson @NTU_DGCOD;
					IF(@PrivatePerson = 1)
					BEGIN
						EXEC [dbo].[UpdateReservationMainManByTourist] @NTU_NAMERUS, @NTU_FNAMERUS, @NTU_SNAMERUS, @NTU_PHONE, @NTU_EMAIL
																	 , @NTU_POSTINDEX, @NTU_POSTCITY, @NTU_POSTSTREET
																	 , @NTU_POSTBILD, @NTU_POSTFLAT, @NTU_PASPRUSER
																	 , @NTU_PASPRUNUM, @NTU_DGCOD; 
				END
			END
		END
		
		If @bNeedCommunicationUpdate=1
			If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@nDGKey)
				UPDATE Communications SET CM_ChangeDate=GetDate() WHERE CM_DGKey=@nDGKey

	  ------------------------------------------------------------------------------------------------
	  END
    FETCH NEXT FROM cur_Turist INTO @TU_Key, @sTU_ShortName,
				@OTU_DGCod, @OTU_DGKey, @OTU_NameRus, @OTU_NameLat, @OTU_FNameRus, @OTU_FNameLat,
				@OTU_SNameRus, @OTU_SNameLat, @OTU_BirthDay, @OTU_PasportType, @OTU_PasportNum,	@OTU_PaspRuSer,
				@OTU_PaspRuNum, @OTU_PasportDate, @OTU_PasportDateEnd, @OTU_PasportByWhoM, @OTU_PaspRuDate, @OTU_PaspRuByWhoM, 
				@OTU_Sex, @OTU_RealSex, 
				@OTU_BIRTHCOUNTRY,
				@OTU_BIRTHCITY,
				@OTU_CITIZEN,
				@OTU_POSTINDEX,
				@OTU_POSTCITY,
				@OTU_POSTSTREET,
				@OTU_POSTBILD,
				@OTU_POSTFLAT,
				@OTU_ISMAIN,
				@OTU_PHONE,
				@OTU_EMAIL,
				@NTU_DGCod, @NTU_DGKey, @NTU_NameRus, @NTU_NameLat,	@NTU_FNameRus, @NTU_FNameLat,
				@NTU_SNameRus, @NTU_SNameLat, @NTU_BirthDay, @NTU_PasportType, @NTU_PasportNum,	@NTU_PaspRuSer,
				@NTU_PaspRuNum, @NTU_PasportDate, @NTU_PasportDateEnd, @NTU_PasportByWhoM, @NTU_PaspRuDate, @NTU_PaspRuByWhoM,
				@NTU_Sex, @NTU_RealSex,
				@NTU_BIRTHCOUNTRY,
				@NTU_BIRTHCITY,
				@NTU_CITIZEN,
				@NTU_POSTINDEX,
				@NTU_POSTCITY,
				@NTU_POSTSTREET,
				@NTU_POSTBILD,
				@NTU_POSTFLAT,
				@NTU_ISMAIN,
				@NTU_PHONE,
				@NTU_EMAIL
    END
  CLOSE cur_Turist
  DEALLOCATE cur_Turist
END

GO




/*********************************************************************/
/* end T_TuristUpdate.sql */
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
--<VERSION>9.2</VERSION>
--<DATE>2014-04-03</DATE>

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
-- =====================   Обновление версии БД. 9.2.20.11 - номер версии, 2014-04-04 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.11', st_moduledate = convert(datetime, '2014-04-04', 120),  st_financeversion = '9.2.20.11', st_financedate = convert(datetime, '2014-04-04', 120)
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
	SET SS_ParmValue='2014-04-04' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO