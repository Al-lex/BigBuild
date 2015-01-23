/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 30.10.2014 19:53 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	[RC_Status] [nvarchar](50) NOT NULL,
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.22'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersionFull nvarchar(128) = '9.2.20.23'
	DECLARE @PrevReleaseLastSPVersion nvarchar(128) = '9.2.20.21'
	
	declare @query nvarchar (max)
	set @query = N'
		declare @index int
		declare @type int
		declare @dotcount int

		set @index = 1
		set @type = 1
		set @dotcount = 0

		set @version = ''''
		set @release = ''''
		set @sp = ''''

		while @index <= len (@val)
		begin
			if (substring(@val, @index, 1) = ''.'')
			begin			
				if (@dotcount = 0 and @type = 1 and @val like ''9%'')
				begin
					set @dotcount = @dotcount + 1
				end	
				else
				begin
					set @type = @type + 1
					set @index = @index + 1
					continue
				end
			end

			if @type = 1
				set @version = @version + substring(@val, @index, 1)
			if @type = 2
				set @release = @release + substring(@val, @index, 1)
			if @type = 3
				set @sp = @sp + substring(@val, @index, 1)

			set @index = @index + 1
		end
	'

	declare @newVersion nvarchar(10)
	declare @newRelease nvarchar(2)
	declare @newSP nvarchar(2)

	declare @currVersion nvarchar(10)
	declare @currRelease nvarchar(2)
	declare @currSP nvarchar(2)
		
	declare @lastVersion nvarchar(10)
	declare @lastRelease nvarchar(2)
	declare @lastSP nvarchar(2)

	EXECUTE sp_executesql @query, N'@val nvarchar(50), @version nvarchar(10) output, @release nvarchar(2) output, @sp nvarchar(2) output', @val = @CurrentVersion, @version = @currVersion  output,  @release = @currRelease output, @sp = @currSP output	
	EXECUTE sp_executesql @query, N'@val nvarchar(50), @version nvarchar(10) output, @release nvarchar(2) output, @sp nvarchar(2) output', @val = @NewVersionFull, @version = @newVersion  output,  @release = @newRelease output, @sp = @newSP output
	EXECUTE sp_executesql @query, N'@val nvarchar(50), @version nvarchar(10) output, @release nvarchar(2) output, @sp nvarchar(2) output', @val = @PrevReleaseLastSPVersion, @version = @lastVersion  output,  @release = @lastRelease output, @sp = @lastSP output

	
	IF(@PrevVersion != @CurrentVersion And @CurrentVersion != @NewVersionFull)
		BEGIN
		
			IF NOT (@newSP = '0' and (convert(int, @newRelease) = convert(int, @currRelease) + 1) and @currRelease = @lastRelease and convert(int, @currSP) > convert(int, @lastSP))
			BEGIN
				SET @Message = 'Вы запустили некорректный скрипт (обновление с ' + @PrevVersion + ' до ' + @NewVersionFull + '). Версия Вашей базы — ' + @CurrentVersion
				RAISERROR(@Message, 16, 1)
			END
		END
END TRY
BEGIN CATCH
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении релиза БД Мастер-Тура.', 'ERR', @HOST_NAME, @Message)
	RAISERROR(@Message, 16, 1) WITH NOWAIT
	SET NOEXEC ON;
END CATCH
GO

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'fn_mwCheckQuotesFlights.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin fn_mwCheckQuotesFlights.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesFlights]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesFlights]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesFlights]
(	
	--<VERSION>9.2.20.23</VERSION>
	--<DATE>2014-10-15</DATE>
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
	@linked_day int = null,
	@airlineCodes ListSysNameValue readonly)

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
	SET @dateStop = case when exists(select top 1 1 from SystemSettings where SS_ParmName = 'BackWithDirectFlightStops' and SS_ParmValue = 1) then DATEDIFF(day, @day - 1, @date) else @date end
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

	declare @airlineCodesList ListSysNameValue
	if exists (select top 1 1 from @airlineCodes)
		insert into @airlineCodesList select value from @airlineCodes
	else
		insert into @airlineCodesList select al_code from airline

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
		and ch_airlinecode in (select [value] from @airlineCodesList)

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

				--28678 -- если нашлись места и вызов идет из QD, а не из экрана AviaQuotes, то квота найдена и выходим
				if (@tourDuration > 0 and @checkNoLongQuotes > 0)
				begin
					close durationCur
					deallocate durationCur
					
					return
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
			
			
			if (@requestOnRelease = 1 and exists(select top 1 1 from @tmpQuotes where qt_release = 0)) -- 28735, Есть места на квоты, и релиз период равен 0 и включена настройка setRequestIfReleaseIsZero
			begin
				set @additional = ltrim(str(@quotaDuration)) + '=-1:' + ltrim(str(@dateAllPlaces))				-- 28735, Вернем квоту Под запрос
			end
			else
			begin
				if (@findFlight <= 0)-- 26882, в случае, если пришел @findFlight > 0 - значит это вызов точно не из экрана QD						
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'fn_mwCheckQuotesFlights.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_AddPaymentToMasterTour.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin sp_AddPaymentToMasterTour.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AddPaymentToMasterTour]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[AddPaymentToMasterTour]
GO

CREATE PROCEDURE [dbo].[AddPaymentToMasterTour]
(
	@dogovorKey INT,
	@externalPaymentID VARCHAR(254),
	@operationID INT,	
	@filialKey INT,
	@partnerKey INT,
	@representativeName VARCHAR(120) = null,
	@partnerDepartmentID INT,
	@date DATETIME,
	@rateKey INT,
	@sum MONEY,
	@sumNational MONEY,
	@course MONEY,
	@dogovorRateSum MONEY,
	@reason VARCHAR(255) = null,
	@aliasID INT,
	@paymentId INT OUTPUT	
)

AS

-- транзакция
DECLARE @transactionName VARCHAR(20)

-- номер путевки
DECLARE @dogovorCode VARCHAR(10)

-- текущий пользователь
DECLARE @creatorKey INT
DECLARE @creatorFullName VARCHAR(25)

-- номер платежа
DECLARE	@documentNumber varchar(20)
DECLARE @blankRangeId INT
DECLARE @blankNumberCurrent INT
DECLARE @blankNumberEnd INT 
DECLARE @blankNumberStart INT 
DECLARE @blankSeries VARCHAR(10)

-- тип операции
DECLARE @paymentOperationPercent MONEY
DECLARE @paymentOperationPercentDecimal MONEY

-- алиас
DECLARE @aliasName VARCHAR(255)

SET @transactionName = 'MyTransaction'

BEGIN TRY
	BEGIN TRANSACTION @transactionName
		
		SELECT @creatorKey = US_KEY, @creatorFullName = US_FullName FROM UserList WITH(NOLOCK) WHERE US_USERID = SYSTEM_USER		
		SELECT @aliasName = OA_ALIAS FROM ObjectAliases WITH(NOLOCK) WHERE OA_Id = @aliasID
		SELECT @dogovorCode = DG_CODE FROM Dogovor WITH(NOLOCK) WHERE DG_Key = @dogovorKey

		SELECT TOP 1 @blankRangeId = BR_ID, 
						@blankSeries = BR_Series, 
						@blankNumberCurrent = BR_NumberCurrent, 
						@blankNumberEnd = BR_NumberEnd,
						@blankNumberStart = BR_NumberStart, 
						@paymentOperationPercent = PO_Percent
						
			FROM PaymentOperations WITH(NOLOCK) JOIN BlankRanges WITH(NOLOCK) ON  PO_BRTKey = BR_BRTKEY 
				WHERE PO_Id = @operationID 
					AND (GETDATE() >= BR_DATEBEGIN OR BR_DATEBEGIN IS NULL) 
					AND (BR_DATEEND >= GETDATE() OR BR_DATEEND IS NULL) 
					AND (BR_PRKEY = @filialKey OR BR_PRKEY IS NULL)
					
		IF(@blankNumberCurrent < @blankNumberStart)					
			SET @blankNumberCurrent = @blankNumberStart - 1;
		
		IF(@blankNumberCurrent < @blankNumberEnd)
			SET @blankNumberCurrent = @blankNumberCurrent + 1
	
		SET @documentNumber = @blankSeries +  REPLACE(SPACE(LEN(@blankNumberEnd) - LEN(@blankNumberCurrent)) + convert(varchar(20), @blankNumberCurrent), SPACE(1), '0') 	

		UPDATE BlankRanges SET BR_NumberCurrent = @blankNumberCurrent WHERE BR_ID = @blankRangeId

		INSERT INTO Payments (PM_CreateDate, PM_CreatorKey, PM_FilialKey, PM_DepartmentKey, PM_DocumentNumber, PM_Number, PM_PRKey, PM_POId,
								PM_Sum,PM_RAKey,PM_SumNational,PM_Used,PM_RepresentName,PM_Export,PM_Date)
			VALUES	(GETDATE(), @creatorKey, @filialKey, @partnerDepartmentID, @documentNumber, @blankNumberCurrent, @partnerKey, @operationID,
									@sum, @rateKey, @sumNational, @sum, @representativeName, 0, @date)	

		SET @paymentId = SCOPE_IDENTITY()							
		
		INSERT INTO PaymentDetails (PD_CreateDate, PD_CreatorKey, PD_Date, PD_Course, PD_Percent, PD_Sum, PD_SumNational, 
										PD_SumInDogovorRate,PD_Reason, PD_DGKey, PD_PMId) 
			VALUES (GETDATE(), @creatorKey, @date, @course, @paymentOperationPercent,@sum, @sumNational, @dogovorRateSum, @reason, @dogovorKey, @paymentId)
		
		INSERT INTO History (HI_DATE, HI_DGKEY, HI_WHO, HI_TEXT, HI_DocumentName, HI_OAId, HI_TYPE, HI_TYPECODE, HI_MESSENABLED, HI_DGCOD)
			VALUES(GETDATE(), @dogovorKey, @creatorFullName, @externalPaymentID, @documentNumber, @aliasID, @aliasName, @paymentId, 0, @dogovorCode)		
			
	COMMIT TRANSACTION @transactionName		
END TRY
BEGIN CATCH	
	ROLLBACK TRANSACTION @transactionName		
	
	SET @paymentId = -1
	
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE();   
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	
END CATCH	

RETURN 0

GO

GRANT EXECUTE ON [dbo].[AddPaymentToMasterTour] TO PUBLIC
GO
/*********************************************************************/
/* end sp_AddPaymentToMasterTour.sql */
/*********************************************************************/
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_AddPaymentToMasterTour.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_StatusCheck_TaskService.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin sp_StatusCheck_TaskService.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[StatusCheck_TaskService]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].StatusCheck_TaskService
GO

CREATE procedure [dbo].StatusCheck_TaskService
	(
		@FilialKeys varchar(max) = '-1',
		@ServiceStauses varchar(max) = null,
		@EarlierCheckIn bit = 0,
		@MonitorWaitListMode bit = 0,
		@ConfirmedEarlier bit = 0,
		@TypeService int,
		@ServiceKeys varchar(max),
		@Attribute int,
		@ServiceIds varchar(max),
		@Day int
	)
AS
-------------------------------
---<DATE>2014-09-23</DATE>
---<VERSION>9.2.20.20</VERSION>
---<COMMENT>Хранимая процедура формирует список путевок, по которым должно отработать задение Изменение статуса услуги с Мастер-Сервисе</COMMENT>
-------------------------------
DECLARE @Date date
DECLARE @Sql varchar(max)


CREATE TABLE #T1(
	xHI_ID int ,
	xHI_DGCOD varchar(10),
	xHI_DLKEY int NULL
)

CREATE TABLE #T2(
	xHI_ID int,
	xHI_DGCOD varchar(10),
	xHI_DLKEY int NULL 
)

CREATE TABLE #temptbl(
	xHI_ID int,
	xHI_DGCOD varchar(10) NULL,
	xHI_DATE datetime NULL,
	xHI_DLKEY int NULL
)

CREATE TABLE #temptbl_watelist(
	xHI_ID int,
	xHI_DGCOD varchar(10) NULL,
	xHI_DATE datetime NULL,
	xHI_DLKEY int NULL

)
		set @sql = '
				INSERT INTO #temptbl (xHI_ID, xHI_DGCOD, xHI_DATE, xHI_DLKEY)
				SELECT HI_ID, HI_DGCOD, HI_DATE, HI_TYPECODE
				FROM HISTORY  WITH(NOLOCK) 
				WHERE  HI_OAID in (2) AND HI_DATE BETWEEN '''+ convert(varchar, DATEADD(DAY,-@Day, GETDATE()), 120) +''' AND GETDATE()
				   AND EXISTS(SELECT 1 FROM tbl_Dogovor WHERE DG_CODE = HI_DGCOD AND DG_TURDATE > ''1900-01-01'' AND DG_FILIALKEY in ('+ @FilialKeys +'))
				   AND EXISTS(SELECT 1 FROM DogovorList WHERE '
		
		if ISNULL(@ServiceStauses, '') <> ''
			set @Sql = @Sql + 'DL_Control in ('+ @ServiceStauses +')'
		else 
			set @Sql = @Sql + ' DL_KEY = HI_TYPECODE '

		if @EarlierCheckIn <> 0
			set @Sql = @Sql + ' AND DL_TURDATE>GETDATE() AND DL_SVKEY IN ('+ @ServiceKeys +')
				   AND ((DL_ATTRIBUTE IS NULL) OR (DL_ATTRIBUTE & '+ CAST(@Attribute AS VARCHAR(MAX)) +' <> '+ CAST(@Attribute AS VARCHAR(MAX)) +')))
				   AND EXISTS(SELECT 1 FROM HISTORYDETAIL WHERE HI_ID=HD_HIID AND HI_MOD <> ''INS'' AND HD_OAID IN ('+ @ServiceIds +'))
					   AND HI_ID NOT IN (select ME_ValueInt from dbo.MasterEvents where ME_Type = '+ CAST(@TypeService AS VARCHAR(MAX)) +')'
		else
			set @Sql = @Sql +' AND DL_SVKEY IN ('+ @ServiceKeys +')
				   AND ((DL_ATTRIBUTE IS NULL) OR (DL_ATTRIBUTE & '+ CAST(@Attribute AS VARCHAR(MAX)) +' <> '+ CAST(@Attribute AS VARCHAR(MAX)) +')))
				   AND EXISTS(SELECT 1 FROM HISTORYDETAIL WHERE HI_ID=HD_HIID AND HI_MOD <> ''INS'' AND HD_OAID IN ('+ @ServiceIds +'))
				   AND HI_ID NOT IN (select ME_ValueInt from dbo.MasterEvents where ME_Type = '+ CAST(@TypeService AS VARCHAR(MAX)) +')'

		IF 	@ConfirmedEarlier <> 0
		BEGIN
			SET @Sql = @Sql + '
				insert into #T1 (xHI_ID, xHI_DGCOD, xHI_DLKEY)
				SELECT xHI_ID, xHI_DGCOD, xHI_DLKEY
				FROM #temptbl AS T
				  WHERE EXISTS (SELECT 1 FROM HistoryDetail 
					 INNER JOIN History ON hd_hiid = hi_id
					 WHERE HI_DGCOD COLLATE Cyrillic_General_CI_AS
						   = xHI_DGCOD COLLATE Cyrillic_General_CI_AS AND HD_Alias = ''DG_SOR_Code'' AND HD_ValueNew = ''Ok'' AND hi_date < T.xHI_DATE)
				'
		END

	   exec(@Sql)

	If @MonitorWaitListMode = 1
	BEGIN
		set @sql = '
				insert into #temptbl_watelist (xHI_ID, xHI_DGCOD, xHI_DATE, xHI_DLKEY)
				SELECT HI_ID, HI_DGCOD, HI_DATE, HI_TYPECODE
				FROM HISTORY  WITH(NOLOCK) 
				WHERE HI_OAID=2 AND HI_DATE BETWEEN '''+ convert(varchar, DATEADD(DAY,-@Day, GETDATE()), 120) +''' AND GETDATE() 
				  AND HI_MOD = ''+WL''
				  AND EXISTS(SELECT 1 FROM tbl_Dogovor WHERE DG_CODE = HI_DGCOD AND DG_TURDATE > ''1900-01-01'')
				  AND EXISTS(SELECT 1 FROM tbl_Dogovor WHERE DG_CODE = HI_DGCOD AND DG_FILIALKEY in ('+ @FilialKeys +'))
				  AND EXISTS(SELECT 1 FROM DOGOVORLIST WHERE DL_SVKEY IN ('
				  
		IF ISNULL(@ServiceKeys, '') <> ''
			SET @Sql = @Sql + ''+ @ServiceKeys +''
		ELSE
			SET @Sql = @Sql +'DL_SVKEY'

		SET @Sql = @Sql + ') AND DL_KEY=HI_TYPECODE AND DL_TURDATE>GETDATE())
				  AND HI_ID NOT IN (select ME_ValueInt from dbo.MasterEvents where ME_Type = '+ CAST(@TypeService AS VARCHAR(MAX)) +')'

		IF 	@ConfirmedEarlier <> 0
		BEGIN
			SET @Sql = @Sql + '
				INSERT INTO #T2 (xHI_ID, xHI_DGCOD, xHI_DLKEY)
				SELECT xHI_ID, xHI_DGCOD, xHI_DLKEY
				FROM #temptbl_watelist AS TW
				  WHERE EXISTS (SELECT 1 FROM HistoryDetail 
					 INNER JOIN History ON hd_hiid = hi_id
					 WHERE HI_DGCOD COLLATE Cyrillic_General_CI_AS
						   = xHI_DGCOD COLLATE Cyrillic_General_CI_AS AND HD_Alias = ''DG_SOR_Code'' AND HD_ValueNew = ''Ok'' AND HI_DATE < xHI_DATE)'
	
			exec(@Sql)
		END

		if @ConfirmedEarlier <> 0
			BEGIN
				select xHI_ID as HI_ID, xHI_DGCOD as HI_DGCOD, xHI_DLKEY as HI_DLKEY from #T1
				UNION
				select xHI_ID as HI_ID, xHI_DGCOD as HI_DGCOD, xHI_DLKEY as HI_DLKEY From #T2
			END
		ELSE
			BEGIN
				select xHI_ID as HI_ID, xHI_DGCOD as HI_DGCOD, xHI_DLKEY as HI_DLKEY from #temptbl 
				UNION 
				select xHI_ID as HI_ID, xHI_DGCOD as HI_DGCOD, xHI_DLKEY as HI_DLKEY From #temptbl_watelist
			END
	END
	ELSE
	BEGIN
		if @ConfirmedEarlier <> 0
			select xHI_ID as HI_ID, xHI_DGCOD as HI_DGCOD, xHI_DLKEY as HI_DLKEY from #T1
		ELSE 
			select xHI_ID as HI_ID, xHI_DGCOD as HI_DGCOD, xHI_DLKEY as HI_DLKEY From #temptbl
	END

GO

GRANT EXEC on [dbo].[StatusCheck_TaskService] to public
GO
/*********************************************************************/
/* end sp_StatusCheck_TaskService.sql */
/*********************************************************************/
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_StatusCheck_TaskService.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '!DisableTriggersOnSubscriber.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '!DisableTriggersOnSubscriber.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '!DropForeignKeyConstraintsOnSubscriber.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '!DropForeignKeyConstraintsOnSubscriber.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '!ChangeDistributionAgentProfile.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '!ChangeDistributionAgentProfile.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())
-- =====================   Обновление версии БД. 9.2.20.23 - номер версии, 2014-10-31 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.23', st_moduledate = convert(datetime, '2014-10-31', 120),  st_financeversion = '9.2.20.23', st_financedate = convert(datetime, '2014-10-31', 120)
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
	SET SS_ParmValue='2014-10-31' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'Выполнение релизного скрипта завершено. Версия релиза: 9.2.20.23. Дата релиза: 2014-10-31', 'SCRIPTTIMELINE', HOST_NAME())
GO