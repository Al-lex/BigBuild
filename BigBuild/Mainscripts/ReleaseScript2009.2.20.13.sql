/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 16.05.2014 10:41 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.12'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.13'

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
/* begin (2014.05.08)_AlterTable_HistoryCost.sql */
/*********************************************************************/
if exists (select 1 from dbo.syscolumns where name = 'HC_Key' and id = object_id(N'[dbo].[HistoryCost]'))
begin
	if exists (select ind.name, * from sys.indexes ind
				left join sys.tables tab on ind.object_id = tab.object_id
				where tab.name = 'HistoryCost'
					and ind.name = 'IX_HistoryCost')
	begin
		DROP INDEX IX_HistoryCost ON dbo.HistoryCost
	end

	alter table HistoryCost drop column HC_Key

	alter table HistoryCost add HC_Key int not null identity(1, 1)

	CREATE UNIQUE CLUSTERED INDEX [IX_HistoryCost] ON [dbo].[HistoryCost] ([HC_Key] ASC)

end
GO
/*********************************************************************/
/* end (2014.05.08)_AlterTable_HistoryCost.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckQuotesFlights.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesFlights]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesFlights]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesFlights]
(	
	--<VERSION>2009.2.21.05</VERSION>
	--<DATE>2014-04-28</DATE>
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

			update T set T.xTP_Key = @nTP_PriceKeyCurrent + rowNumber
			from 
			(
				  select 
					  xTP_Key,
					  row_number() over (order by xTP_Key desc) as rowNumber
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
	where ti_nights is null

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
/* begin sp_GetQuotaLoadListData_N.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetQuotaLoadListData_N]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetQuotaLoadListData_N]
GO

CREATE procedure [dbo].[GetQuotaLoadListData_N]
(
--<VERSION>2009.2.32</VERSION>
--<DATE>2014-05-06</DATE>
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
						QL_' + @ColumnName + ' = QL_' + @ColumnName + ' + CAST(''' + @Quota_Comment + ''' as varchar(7900)) 
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
			and DL_SVKey=@Service_SVKey 
			and DL_Code=@Service_Code 
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
	--<DATE>2014-05-08</DATE>
	--<VERSION>9.2.21.1</VERSION>
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
		and st_tokey not in (select CP_PriceTourKey from CalculatingPriceLists with(nolock) where CP_StartTime is not null and CP_PriceTourKey is not null)
	
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
			from dbo.tp_pricesDeleted with(rowlock) 
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
			from dbo.TP_PriceComponents with(rowlock) 
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
				delete top (@priceCount) from dbo.mwPriceDataTable with(rowlock) where pt_tourdate < @today and pt_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
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
				delete top (@priceCount) from dbo.mwSpoDataTable with(rowlock) where sd_tourkey not in (select pt_tourkey from dbo.mwPriceDataTable with(nolock)) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
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
				delete top (@priceCount) from dbo.mwPriceDurations with(rowlock) where not exists(select 1 from dbo.mwPriceDataTable with(nolock) where pt_tourkey = sd_tourkey and pt_days = sd_days and pt_nights = sd_nights) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
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
					set @sql = 'delete top (' + ltrim(rtrim(str(@priceCount))) + ') from ' + @objName + ' with(rowlock) where pt_tourdate < @today and pt_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0) and pt_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null); set @counterOut = @@ROWCOUNT'
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
					set @sql = 'delete top (' + ltrim(rtrim(str(@priceCount))) + ') from dbo.mwSpoDataTable with(rowlock) where sd_cnkey = ' + ltrim(rtrim(str(@cnkey))) + ' and sd_ctkeyfrom = ' + ltrim(rtrim(str(@ctkeyfrom))) + ' and sd_tourkey not in (select pt_tourkey from ' + @objName + ' with(nolock)) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0) and sd_tourkey not in (select CP_PriceTourKey from CalculatingPriceLists where CP_StartTime is not null and CP_PriceTourKey is not null); set @counterOut = @@ROWCOUNT'
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

grant execute on [dbo].[mwCleaner] to public
GO
/*********************************************************************/
/* end sp_mwCleaner.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetTourMonthesQuotas.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwGetTourMonthesQuotas')
	drop proc dbo.mwGetTourMonthesQuotas
GO

--<DATE>2014-04-30</DATE>
--<VERSION>2009.2.20.13</VERSION>

CREATE proc [dbo].[mwGetTourMonthesQuotas] 
@month_count smallint,
@agent_key int,
@quoted_services nvarchar(100),
@cnkey int,
@tour_type int,
@checkAllPartnersQuota smallint,
@requestOnRelease smallint,
@noPlacesResult smallint,
@checkAgentQuotes smallint,
@checkCommonQuotes smallint,
@checkNoLongQuotes smallint,
@findFlight smallint,
@checkFlightPacket smallint,
@expiredReleaseResult smallint
as
begin
	create table #tourQuotas(
		tour_key int,
		tour_name nvarchar(250),
		tour_url nvarchar(500),
		tour_quotas nvarchar(4000)
	)
	
	declare tour_cursor cursor fast_forward read_only for
		select td_trkey, to_key, isnull(tl_nameweb, isnull(tl_name, '')), isnull(tl_webhttp, '') as tour_url, td_date, month(td_date), tl_nday
		from turdate with(nolock)
		inner join turlist with(nolock) on tl_key = td_trkey
		inner join tp_tours with(nolock) on to_trkey = td_trkey
		where td_date between getdate() 
			and dateadd(month, @month_count, getdate()) 
			and ((@cnkey >= 0 and tl_cnkey = @cnkey) or (@tour_type >= 0 and tl_tip = @tour_type))
			and to_isenabled = 1 
		order by isnull(tl_nameweb, isnull(tl_name, '')),td_date                 
	
	declare @tour_key int, @to_key int, @prev_tour_key int, @prev_month int, @tour_name nvarchar(250), @tour_url nvarchar(500), @tour_date datetime,
	@month int, @tour_quotas nvarchar(4000), @tour_duration int
	
	set @tour_key = -1
	set @to_key = -1
	set @prev_tour_key = -1
	set @prev_month = -1
	set @tour_name = ''
	set @tour_url = ''
	set @tour_date = '1800-01-01'
	set @month = 0
	set @tour_quotas = ''
	
	open tour_cursor
	
	create table #tp_Services(
		ts_svkey int,
		ts_code int,
		ts_subcode1 int,
		ts_subcode2 int,
		ts_day int,
		ts_ndays int,
		ts_partnerkey int,
		ts_pkkey int
	)
	
	declare @sql nvarchar(4000)
	
	fetch next from tour_cursor into @tour_key, @to_key, @tour_name, @tour_url, @tour_date, @month, @tour_duration
	while @@fetch_status = 0
	begin
		if (@tour_key != @prev_tour_key)
		begin
			insert into #tourQuotas (tour_key,	tour_name, tour_url) values (@tour_key, @tour_name, @tour_url)
			
			set @prev_month = -1
			
			if (@prev_tour_key > 0)
			begin
				update #tourQuotas set tour_quotas = @tour_quotas where tour_key = @prev_tour_key
			end
			
			set @tour_quotas = ''
			
			truncate table #tp_Services
			
			insert into #tp_Services
			select distinct ts_svkey, ts_code,
				(case TS_SVKEY when 3 then (select HR_RMKEY from HotelRooms with(nolock) where HR_KEY=t1.ts_subcode1) else t1.ts_subcode1 end) as ts_subcode1,
				(case TS_SVKEY when 3 then (select HR_RCKEY from HotelRooms with(nolock) where HR_KEY=t1.ts_subcode1) else t1.ts_subcode1 end) as ts_subcode2,
				ts_day, ts_days, ts_oppartnerkey, ts_oppacketkey
			from tp_services t1 with(nolock)
			where ts_tokey = @to_key and ts_svkey in (select item from dbo.DelimitedSplit(isnull(@quoted_services, N'3'), ','))
		end
		
		declare @svkey int, @code int, @subcode1 int, @subcode2 int, @day int, @ndays int,
			@partner_key int, @packet_key int, @places int, @allplaces int, @date_places int, @date_allplaces int
		
		if (@month != @prev_month or @tour_key != @prev_tour_key)
		begin
			if (len(@tour_quotas) > 0)         
			begin
				set @tour_quotas = @tour_quotas + '|' 
			end
			
			set @tour_quotas = @tour_quotas + ltrim(str(@month)) + '='
		end
		
		declare service_cursor cursor fast_forward read_only for
			select ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_day, ts_ndays,
				(case when @checkAllPartnersQuota > 0 then -1 else ts_partnerkey end),
				(case when ts_svkey = 1 and @checkFlightPacket > 0 then ts_pkkey else -1 end)
			from #tp_Services
		
		set @date_places = 1000
		set @date_allplaces = 1000
		set @places = null
		set @allplaces = null
		
		open service_cursor
		
		fetch next from service_cursor into @svkey, @code, @subcode1, @subcode2, @day, @ndays, @partner_key, @packet_key
		while @@fetch_status = 0
		begin
			select @places = qt_places, @allplaces = qt_allplaces
			from dbo.mwCheckQuotesEx(@svkey, 
				@code, 
				@subcode1, 
				@subcode2, 
				@agent_key, 
				@partner_key, 
				@tour_date,
				@day,
				@ndays,
				@requestOnRelease,
				@noPlacesResult,
				@checkAgentQuotes,
				@checkCommonQuotes,
				@checkNoLongQuotes,
				@findFlight,
				0,
				0,
				@packet_key,
				@tour_duration,
				@expiredReleaseResult)
			
			if (@places <> 0 or (@places = 0 and @date_places = 1000))
			begin
				set @date_places = @places
				set @date_allplaces = @allplaces
			end

			if (@places > 0)
			begin
				break
			end	
			
			fetch next from service_cursor into @svkey, @code, @subcode1, @subcode2, @day, @ndays, @partner_key, @packet_key
		end
		
		close service_cursor
		deallocate service_cursor
		
		if (@date_places is null)
		begin
			set @date_places = -1
			set @date_allplaces = 0
		end
		
		if(substring(@tour_quotas, len(@tour_quotas), 1) != '=')
		begin
			set @tour_quotas = @tour_quotas + ','
		end
		
		set @tour_quotas = @tour_quotas + ltrim(str(day(@tour_date))) + '#' + ltrim(str(@date_places)) + ':' + ltrim(str(@date_allplaces))
		set @prev_tour_key = @tour_key
		set @prev_month = @month
		
		fetch next from tour_cursor into @tour_key, @to_key, @tour_name, @tour_url, @tour_date, @month, @tour_duration
	end
	
	update #tourQuotas set tour_quotas = @tour_quotas where tour_key = @prev_tour_key
	
	close tour_cursor
	deallocate tour_cursor
	
	select * from #tourQuotas
end
GO

grant exec on dbo.mwGetTourMonthesQuotas to public
GO
/*********************************************************************/
/* end sp_mwGetTourMonthesQuotas.sql */
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
				pt_hdday,pt_hdnights,(case when isnull(@checkAllPartnersQuota, 0) > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when @checkFlightPacket > 0 then pt_chpkkey else -1 end) as pt_chpkkey,
				(case when isnull(@checkAllPartnersQuota, 0) > 0 then -1 else pt_chprkey end),pt_chbackday,(case when @checkFlightPacket > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey, 
				(case when isnull(@checkAllPartnersQuota, 0) > 0 then -1 else pt_chbackprkey end),pt_days
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
				,pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,pt_hdday,pt_hdnights, (case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chpkkey else -1 end) as pt_chpkkey,
				(case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_chprkey end),pt_chbackday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey,
				(case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_chbackprkey end),pt_days,pt_chkey, pt_chbackkey, 0, '''' pt_chdirectkeys, '''' pt_chbackkeys, '''' pt_hddetails
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
			set @sql=@sql + ',pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,pt_hdday,pt_hdnights, (case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chpkkey else -1 end) as pt_chpkkey,
				(case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_chprkey end),pt_chbackday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey,
				(case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_chbackprkey end),pt_days, '
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
						pt_hdday,pt_hdnights,(case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0)))+ ' > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when ' + ltrim(str(@checkFlightPacket))+ ' > 0 then pt_chpkkey else -1 end) as pt_chpkkey,
						(case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0)))+ ' > 0 then -1 else pt_chprkey end),
						pt_chbackday,(case when ' + ltrim(str(@checkFlightPacket))+ ' > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey,
						(case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0)))+ ' > 0 then -1 else pt_chbackprkey end),pt_days
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
SET CONCAT_NULL_YIELDS_NULL OFF 
--<VERSION>2003.4</VERSION>
--<DATE>2004-05-20</DATE>
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
	
	if	(@nOldNetto = @nNewNetto) and (@nOldBrutto = @nNewBrutto) and 
		(@dOldBeg = @dNewBeg) and (@dOldEnd = @dNewEnd) and (@sMode != 'DEL')
		Return 0

	Set @sOldNetto = CAST ( @nOldNetto  AS varchar )
	Set @sNewNetto = CAST ( @nNewNetto  AS varchar )
	Set @sOldBrutto = CAST ( @nOldBrutto  AS varchar )
	Set @sNewBrutto = CAST ( @nNewBrutto  AS varchar )
	Set @sOldDateBeg = CONVERT ( varchar , @dOldBeg, 105)
	Set @sNewDateBeg = CONVERT ( varchar , @dNewBeg, 105)
	Set @sOldDateEnd = CONVERT ( varchar , @dOldEnd, 105)
	Set @sNewDateEnd = CONVERT ( varchar , @dNewEnd, 105)

	EXEC dbo.CurrentUser @sOper output

	Set @sText = ''
	If @sMode != 'DEL'
	begin
		if @nOldNetto != @nNewNetto
		begin
			set @sText = 'Изменение нетто с ' + @sOldNetto + ' на ' + @sNewNetto + ' сезон ' + @sNewDateBeg + ' - ' + @sNewDateEnd
			
			Insert into HistoryCost (HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
			VALUES (GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1,	@nCode2, @nPartner, @nPaket)
		end
		if @nOldBrutto != @nNewBrutto
		begin
			set @sText = 'Изменение брутто с ' + @sOldBrutto + ' на ' + @sNewBrutto + ' сезон ' + @sNewDateBeg + ' - ' + @sNewDateEnd
				
			Insert into HistoryCost (HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
			VALUES (GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1, @nCode2, @nPartner, @nPaket)
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
		IF @sText != '' 
		BEGIN		
			Insert into HistoryCost (HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
			VALUES (GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1, @nCode2, @nPartner, @nPaket)
		END
	end
	else
	begin
		SET @sText = 'Удаление цены: нетто ' + @sOldNetto + ', брутто ' + @sOldBrutto + ', сезон с ' + @sOldDateBeg + ' по ' + @sOldDateEnd
		
		INSERT INTO HistoryCost (HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
		VALUES (GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1, @nCode2, @nPartner, @nPaket)
	end
SET CONCAT_NULL_YIELDS_NULL ON
GO

grant exec on [dbo].[UpdateDeleteCost] to public
GO
/*********************************************************************/
/* end sp_UpdateDeleteCost.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TSToServiceByDate.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_TSToServiceByDate]'))
	DROP TRIGGER [dbo].[T_TSToServiceByDate]
GO

CREATE TRIGGER [dbo].[T_TSToServiceByDate]
   ON [dbo].[TuristService]
   AFTER INSERT, DELETE 
AS 
--<VERSION>2009.2.20.13</VERSION>
--<DATE>2014-04-29</DATE>
DECLARE @TUID int, @O_DLKey int, @O_TUKey int, @N_DLKey int,@N_TUKey int,
		@BestPlace int, @BestRL int, @nDelCount int, @nInsCount int

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED

-- Task 8984 24.10.2012 kolbeshkin
-- Перераспределение туристов по услугам, класс которых имеет признак "Индивидуальное бронирование":
-- в каждой услуге должно быть не более 1 туриста.
IF (@nDelCount = 0)
begin
	DECLARE @isIndividualService smallint
	DECLARE @newTU_DLKEY int
	DECLARE @DL_DGKEY int
	DECLARE @DL_SVKEY int
		
	DECLARE cur_individual CURSOR FOR 
	SELECT 	N.TU_IDKey,	N.TU_DLKey
	FROM	INSERTED N 
	OPEN cur_individual
	FETCH NEXT FROM cur_individual 
	INTO @TUID, @O_DLKey

	WHILE @@FETCH_STATUS = 0
	BEGIN
		select @isIndividualService = ISNULL(SV_IsIndividual, 0),@DL_SVKEY=DL_SVKEY,@DL_DGKEY=DL_DGKEY  
		from dbo.Service,dbo.Dogovorlist where DL_KEY = @O_DLKey and SV_Key = DL_SVKEY 
		if @isIndividualService > 0 and (select COUNT(*) from TuristService where TU_DLKEY = @O_DLKey) > 1
		begin
				set @newTU_DLKEY = (select top 1 DL_KEY from dbo.Dogovorlist where DL_DGKEY = @DL_DGKEY
					and DL_SVKEY = @DL_SVKEY and not exists (select 1 from TuristService where TU_DLKEY = DL_KEY))
				if @newTU_DLKEY is not null
					update TuristService set TU_DLKEY = @newTU_DLKEY where TU_IDKEY = @TUID
		end
		FETCH NEXT FROM cur_individual 
		INTO @TUID, @O_DLKey
	end
	CLOSE cur_individual
	DEALLOCATE cur_individual
end
set @TUID=null
set @O_DLKey=null
-- 

IF (@nInsCount = 0)
BEGIN
	DECLARE cur_T_TSToServiceByDate CURSOR FOR 
	SELECT 	O.TU_IDKey,
			O.TU_DLKey, O.TU_TUKey,
			null, null
	FROM DELETED O
END
ELSE IF (@nDelCount = 0)
BEGIN
	DECLARE cur_T_TSToServiceByDate CURSOR FOR 
	SELECT 	N.TU_IDKey,
			null, null,
			N.TU_DLKey, N.TU_TUKey
	FROM	INSERTED N 
END

OPEN cur_T_TSToServiceByDate
FETCH NEXT FROM cur_T_TSToServiceByDate 
	INTO @TUID, @O_DLKey, @O_TUKey, @N_DLKey, @N_TUKey
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @N_TUKey is not null
	BEGIN
		SET @BestRL = 0
		SET @BestPlace = 0
		SELECT @BestRL=Min(SD_RLID),@BestPlace=Min(SD_RPID) FROM ServiceByDate WHERE SD_DLKey=@N_DLKey and SD_TUKey is null
		If @BestRL is null
			UPDATE ServiceByDate SET SD_TUKey=@N_TUKey WHERE SD_DLKey=@N_DLKey and SD_RPID=@BestPlace and SD_RLID is null
		Else
		BEGIN
			SELECT @BestPlace=Min(SD_RPID) FROM ServiceByDate WHERE SD_DLKey=@N_DLKey and SD_RLID=@BestRL and SD_TUKey is null
			UPDATE ServiceByDate SET SD_TUKey=@N_TUKey WHERE SD_DLKey=@N_DLKey and SD_RPID=@BestPlace and SD_RLID=@BestRL
		END
	END
	ELSE IF @O_TUKey is not null
		UPDATE ServiceByDate SET SD_TUKey=null WHERE SD_DLKey=@O_DLKey AND SD_TUKey=@O_TUKey

	-- Golubinsky. 11.08.2012. 
	-- TFS 7219: бронирование авиаперелетов для инфантов: перелеты садятся на подтверждение вне квоты
	UPDATE ServiceByDate SET SD_State=3
	WHERE SD_DLKey = @N_DLKey
			AND SD_TUKey = @N_TUKey
			AND EXISTS (SELECT TOP 1 1 FROM tbl_DogovorList WHERE DL_KEY = SD_DLKey AND DL_SVKEY = 1)
			AND EXISTS (SELECT TOP 1 1 FROM tbl_Turist WHERE TU_KEY = SD_TUKey AND TU_SEX=3)

	FETCH NEXT FROM cur_T_TSToServiceByDate
		INTO @TUID, @O_DLKey, @O_TUKey, @N_DLKey, @N_TUKey
END
CLOSE cur_T_TSToServiceByDate
DEALLOCATE cur_T_TSToServiceByDate
GO
/*********************************************************************/
/* end T_TSToServiceByDate.sql */
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
--<VERSION>9.2.1.1</VERSION>
--<DATE>2014-05-05</DATE>

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
					SELECT @HRIsMain=AC_MAIN, @ACPlacesMain=ISNULL(AC_NRealPlaces,0), @ACPlacesEx=ISNULL(AC_NMenExBed,0), @ACPerRoom=ISNULL(AC_PerRoom,0)
						FROM AccmdMenType
						WHERE AC_Key=(SELECT HR_ACKey From HotelRooms WHERE HR_Key=@N_DLSubCode1)
					
					SELECT @RMPlacesMain=ISNULL(RM_NPLACES,0), @RMPlacesEx=ISNULL(RM_NPlacesEx,0)
						FROM Rooms
						WHERE RM_KEY=(SELECT HR_RMKey From HotelRooms WHERE HR_KEY=@N_DLSubcode1)
					
					IF @HRIsMain = 1 and @ACPlacesMain = 0 and @ACPlacesEx = 0
						set @ACPlacesMain = 1
					ELSE IF @HRIsMain = 0 and @ACPlacesMain = 0 and @ACPlacesEx = 0
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
					
					IF ISNULL(@AC_FreeMainPlacesCount,0) = 0
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
-- =====================   Обновление версии БД. 9.2.20.13 - номер версии, 2014-05-16 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.13', st_moduledate = convert(datetime, '2014-05-16', 120),  st_financeversion = '9.2.20.13', st_financedate = convert(datetime, '2014-05-16', 120)
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
	SET SS_ParmValue='2014-05-16' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO