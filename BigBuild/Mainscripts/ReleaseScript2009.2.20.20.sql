/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 21.08.2014 18:22 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.19'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.20'

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
/* begin (2014_07_23)_CreateTable_QuestionnaireDataQuery.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT TOP 1 1 FROM SYS.TABLES WHERE NAME = 'QuestionnaireDataQuery')
BEGIN
	CREATE TABLE [dbo].[QuestionnaireDataQuery](
		[QDQ_Key] [int] IDENTITY(1,1) NOT NULL,
		[QDQ_Name] [nvarchar](100) NULL,
		[QDQ_Text] [varchar](800) NULL,
	 CONSTRAINT [PK_QuestionnaireDataQuery] PRIMARY KEY CLUSTERED 
	(
		[QDQ_Key] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
	) ON [PRIMARY]
END

GRANT SELECT, INSERT, DELETE, UPDATE ON [dbo].[QuestionnaireDataQuery] TO PUBLIC

GO
/*********************************************************************/
/* end (2014_07_23)_CreateTable_QuestionnaireDataQuery.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-08-06)_AlterTable_SystemSettings.sql */
/*********************************************************************/
-- скрипт устанавливает признак "not for replication" в true для колонки ss_id таблицы SystemSettings

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
go
/*********************************************************************/
/* end (2014-08-06)_AlterTable_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-08-19)_Insert_Actions.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 168) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (168, 'Скрытие колонок -> "Недоплата"', 
		'Скрывать колонку "Недоплата"', 
		'Hide columns -> "Rest Payment"', 1)
END
GO

IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 169) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (169, 'Скрытие колонок -> "Недоплата в национальной валюте"', 
		'Скрывать колонку "Недоплата в национальной валюте"', 
		'Hide columns -> "Rest Payment in national price"', 1)
END
GO

/*********************************************************************/
/* end (2014-08-19)_Insert_Actions.sql */
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
	@CityKey int = null,
	@priceType varchar(10) = null
AS
--<DATE>2014-05-14</DATE>
---<VERSION>9.2.27</VERSION>

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

create table #minPricesTable (ptCNKey int, ptRMKey int, ptTourDate datetime, ptTourKey int, ptDays int, ptHDKey int, ptHDKeys varchar(2000), ptHDPartnerKey int,
	ptHDDay int, ptHDNights int, ptRCKey int, ptNights int, ptTourType int, ptPrice float)

--ключи размещений и признак - все ли размещения основные
create table #hrKeysStringsTable (hrkey varchar(200), hrmain int)

--данные из таблиц основной базы
create table #services (tl_tikey int,ts_subcode1 int,ts_code int,ts_day int)

select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) where SS_ParmName = 'MWDivideByCountry'

if (@mwSearchType=0)
begin
	set @script = 'select distinct(pt_hotelroomkeys), 0 from mwPriceDataTable with(nolock) where ' + @Filter
	
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
	
	set @script = 'select distinct pt_rmkey,pt_rmcode from mwPriceDataTable with(nolock) where ' + @Filter

	INSERT INTO #roomKeys EXEC(@script)
	
	set @script = 'select pt_cnkey, pt_rmkey, pt_tourdate, pt_tourkey, pt_days, pt_hdkey, pt_hotelkeys, pt_hdpartnerkey,
					pt_hdday, pt_hdnights, pt_rckey, pt_nights, pt_tourtype, '
	
	if RTRIM(ISNULL(@priceType,'min'))='max'
		set @script = @script + 'max'
	else
		set @script = @script + 'min'
	
	set @script = @script + '(pt_price) from mwPriceDataTable with (nolock)
					inner join #hrKeysStringsTable on pt_hotelroomkeys=hrkey
					where ' + @Filter + '
					and pt_isEnabled=1
					group by pt_cnkey,pt_rmkey,pt_tourdate,pt_tourkey,pt_days,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,
						pt_hdday,pt_hdnights,pt_rckey,pt_nights,pt_tourname,pt_tourtype'
	
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
			pt_rckey,rc_name,pt_rmkey,pt_nights,pt_tourname,pt_tourtype,tp_name,pt_hdname,pt_rate,ts_subcode1,ts_code,ts_day
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
		
			set @script = 'select pt_cnkey,pt_rmkey,pt_tourdate,pt_tourkey,pt_days,pt_hdkey,pt_hotelkeys,
								pt_hdpartnerkey,pt_hdday,pt_hdnights,pt_rckey,pt_nights,pt_tourtype,'
			
			if RTRIM(ISNULL(@priceType,'min'))='max'
				set @script = @script + 'max'
			else
				set @script = @script + 'min'
				
			set @script=@script + '(pt_price) from ' + @tableNameString + ' with(nolock)
							where ' + @Filter + '
							and exists(select top 1 1 from #hrKeysStringsTable where pt_hotelroomkeys=hrkey)
							and pt_isEnabled=1
							group by pt_cnkey,pt_rmkey,pt_tourdate,pt_tourkey,pt_days,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,
								pt_hdday,pt_hdnights,pt_rckey,pt_nights,pt_tourname,pt_tourtype'
			
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
					pt_hdday,pt_hdnights,pt_rckey,rc_name,pt_rmkey,pt_nights,pt_tourname,pt_tourtype,tp_name,pt_hdname,pt_rate,ts_subcode1,ts_code,ts_day
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

if (((select dbo.mwReplIsSubscriber()) = 0) and (select dbo.mwReplIsPublisher()) = 0)
begin
	select @update_price = @update_price + 'update #pricesTable set rmkey_' + convert(varchar,rm_key) + ' = TP_Gross from dbo.TP_Prices where tp_key = pr_' + convert(varchar,rm_key) + '; '
	from #roomKeys order by rm_key
end
else
begin
	select @update_price = @update_price + 'update #pricesTable set rmkey_' + convert(varchar,rm_key) + ' = TP_Gross from mt.' + dbo.mwReplPublisherDB() + '.dbo.TP_Prices where tp_key = pr_' + convert(varchar,rm_key) + '; '
	from #roomKeys order by rm_key
end


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

grant exec on dbo.mwAutobusQuotes to public
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

CREATE proc [dbo].[mwCleaner] @priceCount int = 1000000, @deleteToday smallint = 0
as
begin
	--<DATE>2014-08-18</DATE>
	--<VERSION>9.2.21.2</VERSION>
	declare @counter bigint
	declare @deletedRowCount bigint

	insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Запуск mwCleaner', 1)

	declare @today datetime
	set @today = getdate()
	if (@deleteToday <> 1)
	begin
		set @today = dateadd(day, -1, @today)
	end
	
	IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwDeleted]') AND type in (N'U'))
	begin
		if not exists(select top 1 1 from mwDeleted)
		begin
			--на основной базе точно будет присутствовать первичный ключ, на поисковой - не факт, поэтому делаем универсальный truncate
			truncate table mwDeleted
		end
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
		and st_tokey not in (select CP_PriceTourKey from CalculatingPriceLists with(nolock) where CP_StartTime is not null and CP_PriceTourKey is not null)
	
		delete TP_ServiceTours WHERE ST_Id in (select x.ST_Id from #Keys as x)
	
		drop table #Keys
	
		-- Удаляем неактуальные цены
		set @counter = 0
		while(1 = 1)
		begin
	
			delete 
			from dbo.tp_prices 
			where tp_key in (SELECT top (@priceCount/10) tp_key 
							 from dbo.tp_prices with(nolock) 
							 WHERE tp_dateend < @today 
								   and tp_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
								   and tp_tokey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null) --за исключением отложенного расчета
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
			from dbo.tp_pricesDeleted 
			where tpd_id in (select top (@priceCount/5) tpd_id 
							 from dbo.tp_pricesDeleted with(nolock)
							 where tpd_dateend < @today 
								   and tpd_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
								   and tpd_tokey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null) --за исключением отложенного расчета
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
			from dbo.TP_PriceComponents 
			where PC_ID in (SELECT top (@priceCount/50) PC_ID 
							FROM dbo.TP_PriceComponents with(nolock) 
							WHERE PC_TourDate < @today
							and pc_tokey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null) --за исключением отложенного расчета
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
			from dbo.TP_ServiceCalculateParametrs 
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
		from dbo.tp_turdates 
		where td_key in (select top (@priceCount/10) td_key 
							from dbo.tp_turdates with(nolock) 
							where td_date < @today 
							and td_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
							and td_tokey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null) --за исключением отложенного расче
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
		where TO_Key not in (select CP_PriceTourKey from CalculatingPriceLists with(nolock) where CP_StartTime is not null and CP_PriceTourKey is not null)
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
			from dbo.tp_lists 
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
			from dbo.TP_Tours 
			where to_key in (SELECT TOP 1 TO_Key 
							 FROM TP_Tours 
							 WHERE to_datevalid < @today
							 and to_key not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null) --за исключением отложенного расчета
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
				delete top (@priceCount) from dbo.mwPriceDataTable where pt_tourdate < @today and pt_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
							and pt_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null) --за исключением отложенного расчета
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
				delete top (@priceCount) 
				from dbo.mwSpoDataTable 
				where not exists (select 1 from dbo.mwPriceDataTable with(nolock) where pt_tourkey = sd_tourkey and sd_hdkey = pt_hdkey) 
				and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
				and sd_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null) --за исключением отложенного расчета

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
				delete top (@priceCount) from dbo.mwPriceDurations where not exists(select 1 from dbo.mwPriceDataTable with(nolock) where pt_tourkey = sd_tourkey and pt_days = sd_days and pt_nights = sd_nights) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
							and sd_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null) --за исключением отложенного расчета
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
					set @sql = 'delete top (' + ltrim(rtrim(str(@priceCount))) + ') from ' + @objName + ' where pt_tourdate < @today and pt_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0) and pt_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null); set @counterOut = @@ROWCOUNT'
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
					set @sql = 'delete top (' + ltrim(rtrim(str(@priceCount))) + ') 
					from dbo.mwSpoDataTable 
					where sd_cnkey = ' + ltrim(rtrim(str(@cnkey))) + ' and sd_ctkeyfrom = ' + ltrim(rtrim(str(@ctkeyfrom))) + '
					and not exists (select 1 from ' + @objName + ' with(nolock) where pt_tourkey = sd_tourkey and sd_hdkey = pt_hdkey) 
					and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0) 
					and sd_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null); set @counterOut = @@ROWCOUNT'
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
			delete top (@priceCount) from dbo.mwPriceHotels where sd_tourkey not in (select sd_tourkey from dbo.mwSpoDataTable with(nolock)) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
						and sd_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null)
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
		delete top (@priceCount) from dbo.SystemLog where SL_DATE < DATEADD(day, -7, @today)
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
/* begin sp_mwSimpleTourInfo.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwSimpleTourInfo]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwSimpleTourInfo]
GO

CREATE PROCEDURE [dbo].[mwSimpleTourInfo]
(
	--<VERSION>9.20</VERSION>
	--<DATA>30.07.2014</DATA>
	@roomKeys varchar(50), 
	@onlySpo smallint, 
	@priceFromTpTours smallint = 0, 
	@countryKey int = null, 
	@tourType int = null
)
as
begin
	declare @sql varchar(3000)

	if (@priceFromTpTours = 0)
	begin
		set @sql = '      
		select     pt_cnkey, cn_name, pt_ctkeyfrom, ct_name, pt_tourkey, pt_tourname, pt_toururl, pt_rate,
				   dbo.mwTop5TourDates(pt_cnkey, pt_tourkey, pt_tlkey, 0) as dates, 
				   dbo.mwTourHotelNights(pt_tourkey) as nights, min_price, CONVERT(varchar(10), pt_tourdate, 21) as pt_firsttourdate, pt_tourcreated, 			
				   tl_tip as tourtype, tl_dopdesc as note
		from 
		(
			  select max(pt_cnkey) pt_cnkey, max(pt_ctkeyfrom) pt_ctkeyfrom, pt_tourkey, max(tl_name) pt_tourname, max(tl_webhttp) pt_toururl, max(pt_tlkey) pt_tlkey, max(pt_rate) pt_rate, min(pt_price) min_price, min(pt_tourdate) pt_tourdate, max(pt_tourcreated) pt_tourcreated
			  from dbo.mwPriceTable with(nolock)
			  where pt_main > 0 and pt_rmkey in (' + @roomKeys + ') and pt_tourdate >= getdate()
			  group by pt_tourkey
		 ) as prices
			  join tbl_turlist with(nolock) on tl_key = pt_tlkey
			  join dbo.Country with(nolock) on pt_cnkey = cn_key
			  join dbo.CityDictionary with(nolock) on pt_ctkeyfrom = ct_key
		where (' + ltrim(str(isnull(@onlySpo, 0))) + ' = 0 or exists(select 1 from tp_tours with(nolock) where (to_attribute & 1) > 0 and to_key = pt_tourkey))'

		if @countryKey is not null
			set @sql = @sql + ' and pt_cnkey = ' + ltrim(str(@countryKey))
		if @tourtype is not null
			set @sql = @sql + ' and tl_tip = ' + ltrim(str(@tourtype))
		set @sql = @sql + ' order by pt_tourcreated desc'
	end
	else
	begin
		set @sql = '     
		select	isnull(ct_name, ''-Без перелета-'') as ct_name, 
			isnull(tl_ctdeparturekey,0) as pt_ctkeyfrom, 
			to_cnkey + isnull(tl_ctdeparturekey,0) as cnctkey,
			to_cnkey as pt_cnkey, 
			cn_name, 
			tl_name as pt_tourname, 
			tl_webhttp as pt_toururl, 
			tl_rate as pt_rate,
			dbo.mwTop5TourDates(to_cnkey, to_key, tl_key, 0) as dates, 
			TO_MinPrice as min_price, 
			dbo.mwTourHotelNights(to_key) as nights,
			CONVERT(varchar(10), (select min(TD_Date) from TP_TurDates where TD_ToKey = TO_Key), 21) as pt_firsttourdate,
			to_DateCreated pt_tourcreated,
			to_key pt_tourkey,
			tl_tip as tourtype,
			tl_dopdesc as note
		from tp_tours
			left join tbl_turlist on tl_key = to_trkey
			left join dbo.Country on to_cnkey = cn_key
			left join dbo.CityDictionary on tl_ctdeparturekey = ct_key
		where TO_IsEnabled > 0 and TO_DateValid >= getdate() and (' + ltrim(str(isnull(@onlySpo, 0))) + ' = 0 or (to_attribute & 1) > 0 )'

		if @countryKey is not null
			set @sql = @sql + ' and to_cnkey = ' + ltrim(str(@countryKey))
		if @tourtype is not null
			set @sql = @sql + ' and tl_tip = ' + ltrim(str(@tourtype))
		set @sql = @sql + ' order by ct_name, cn_name, to_DateCreated'
	end

	exec(@sql)
end
GO

GRANT EXEC on [dbo].[mwSimpleTourInfo] to public
GO
/*********************************************************************/
/* end sp_mwSimpleTourInfo.sql */
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
-- =====================   Обновление версии БД. 9.2.20.20 - номер версии, 2014-08-22 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.20', st_moduledate = convert(datetime, '2014-08-22', 120),  st_financeversion = '9.2.20.20', st_financedate = convert(datetime, '2014-08-22', 120)
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
	SET SS_ParmValue='2014-08-22' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO