/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 08.09.2014 14:27 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.20'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.21'

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
/* begin Create_Type_ListSysNameValue.sql */
/*********************************************************************/
IF not EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ListSysNameValue' AND ss.name = N'dbo')
begin
	CREATE TYPE [dbo].[ListSysNameValue] AS TABLE(
		[value] [sysname] NOT NULL
	)
end
GO
GRANT EXECUTE ON TYPE::dbo.[ListSysNameValue] TO public
go

/*********************************************************************/
/* end Create_Type_ListSysNameValue.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-09-02)_Alter_CacheQuotas.sql */
/*********************************************************************/
--<DATE>2014-09-02</DATE>
--<VERSION>9.2.20</VERSION>
if not exists (select * from syscolumns where name='cq_airlineCodes' and id=object_id('dbo.CacheQuotas'))
begin
	alter table dbo.CacheQuotas add cq_airlineCodes varchar(max) NULL
end
go
/*********************************************************************/
/* end (2014-09-02)_Alter_CacheQuotas.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCacheQuotaInsert.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCacheQuotaInsert]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwCacheQuotaInsert]
GO

create procedure [dbo].[mwCacheQuotaInsert]
	@svkey	int,
	@code	int,
	@subcode1	int,
	@subcode2	int,
	@date	datetime,
	@day	int,
	@days	int,
	@prkey	int,
	@pkkey	int,
	@result varchar(256),
	@places int,
	@step_index smallint,
	@price_correction int,
	@additional varchar(2000),
	@findFlight smallint,
	@airlineCodes varchar(max) = ''	
as
begin
	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-09-02</DATE>

	if @airlineCodes is null
		set @airlineCodes = ''
	set @airlineCodes = UPPER(LTRIM(@airlineCodes))

	insert into CacheQuotas(cq_svkey,cq_code,cq_rmkey,cq_rckey,cq_date,cq_day,cq_days,cq_prkey,cq_pkkey,cq_res,cq_places,cq_findFlight,cq_Additional,cq_airlineCodes) 
	values(@svkey,@code,@subcode1,@subcode2,@date,@day,@days,@prkey,@pkkey,@result,@places,@findFlight,@additional, @airlineCodes)
end	
GO

grant execute on [dbo].[mwCacheQuotaInsert] to public
GO
/*********************************************************************/
/* end sp_mwCacheQuotaInsert.sql */
/*********************************************************************/

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
	@findFlight smallint,
	@airlineCodes varchar(max) = ''
as
begin
	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-09-02</DATE>
	set @result = NULL
	
	if @airlineCodes is null
		set @airlineCodes = ''
	set @airlineCodes = UPPER(LTRIM(@airlineCodes))

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
			and upper(cq_airlineCodes) = @airlineCodes
end
GO

grant execute on [dbo].[mwCacheQuotaSearch] to public
GO
/*********************************************************************/
/* end sp_mwCacheQuotaSearch.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckQuotesFlights.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesFlights]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesFlights]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesFlights]
(	
	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-09-02</DATE>
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
	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-09-02</DATE>

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
			@tourDuration, @expiredReleaseResult, @linked_day, @airlineCodes)
		
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
/* begin fn_mwCheckQuotesEx.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesEx]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesEx]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesEx](
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
	@expiredReleaseResult int)

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
	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-09-02</DATE>

	insert into @tmpResQuotes
	select 
		qt_svkey,
		qt_code,
		qt_subcode1,
		qt_subcode2,
		qt_agent,
		qt_prkey,
		qt_bycheckin,
		qt_byroom,
		qt_places,
		qt_allPlaces,
		qt_type,
		qt_long,
		qt_additional
	from
		dbo.mwCheckQuotesEx2(
			@svkey, 
			@code, 
			@subcode1,
			@subcode2, 
			@agentKey, 
			@partnerKey, 
			@date,
			@day,
			@days,
			@requestOnRelease, 
			@noPlacesResult, 
			@checkAgentQuotes, 
			@checkCommonQuotes,
			@checkNoLongQuotes,
			@findFlight,
			@cityFrom,
			@cityTo,
			@flightpkkey,
			@tourDuration,
			@expiredReleaseResult,
			DEFAULT,
			DEFAULT
		)
	return
end
GO

GRANT SELECT ON [dbo].[mwCheckQuotesEx] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwCheckQuotesEx.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCheckFlightGroupsQuotesWithInnerFlights.sql */
/*********************************************************************/
if object_id('dbo.mwCheckFlightGroupsQuotesWithInnerFlights', 'p') is not null
	drop proc dbo.mwCheckFlightGroupsQuotesWithInnerFlights
go

create proc [dbo].[mwCheckFlightGroupsQuotesWithInnerFlights]
	@pagingType int,
	@charters varchar(256),
	@flightGroups varchar(256),
	@agentKey int,
	@tourdate datetime,
	@requestOnRelease int,
	@noPlacesResult int,
	@checkAgentQuota int,
	@checkCommonQuota int,
	@checkNoLongQuota int,
	@findFlight smallint,
	@tourDays int,
	@expiredReleaseResult int,
	@aviaQuotaMask smallint,
	@result varchar(256) output,
	@linkedcharters varchar(256),
	@airlineCodes ListSysNameValue readonly
as
begin
	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-09-02</DATE>

	declare @curQuota varchar(256)

	declare @curPosition int
		set @curPosition = 0

	declare @tmpCurPosition int
	declare @tmpPrevPosition int
		

	declare @prevPosition int
		set @prevPosition = 1

	declare @charterString varchar(256)
		set @charterString  = ''

	declare @chkey int, @chday int,@chpkkey int,@chprkey int, @cityfromkey int, @citytokey int, @linkedchday int

	declare @flag smallint
		set @flag = 0

	--MEG00027974 Paul G 30.08.2010
	declare @linkedcharterstable table(chkey int, chday int);
	--вытащим из @linkedcharters ключи и дни связанных перелётов и положим в @linkedcharterstable
	--для удобности последующего использования
	while (len(@linkedcharters) > 0 and (charindex(',', @linkedcharters, @curPosition + 1) > 0 or @flag = 0))
	begin
		set @curPosition = charindex(',', @linkedcharters, @curPosition + 1)
		if (@curPosition = 0)
		begin
			set @charterString  = substring(@linkedcharters, @prevPosition, len(@linkedcharters))

			set @curPosition = len(@linkedcharters)
			set @flag = 1
		end 
		else
		begin
			set @charterString  = substring(@linkedcharters, @prevPosition, @curPosition - @prevPosition)
		end

		set @prevPosition = @curPosition + 1

		set @tmpPrevPosition = 0
		set @tmpCurPosition = charindex(':', @charterString, @tmpPrevPosition + 1)
		set @chkey = CAST(substring(@charterString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
		set @tmpPrevPosition = @tmpCurPosition + 1

		set @tmpCurPosition = charindex(':', @charterString, @tmpPrevPosition + 1)
		set @chday = CAST(substring(@charterString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
		set @tmpPrevPosition = @tmpCurPosition + 1

		set @tmpCurPosition = charindex(':', @charterString, @tmpPrevPosition + 1)
		set @chprkey = CAST(substring(@charterString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
		set @tmpPrevPosition = @tmpCurPosition + 1

		set @chpkkey = CAST(substring(@charterString, @tmpPrevPosition, len(@charterString) + 1 - @tmpPrevPosition) as int)

		insert into @linkedcharterstable(chkey, chday)
		values(@chkey, @chday)
	end

	set @curPosition = 0
	set @prevPosition = 1
	set @charterString  = ''
	set @flag = 0
	--End MEG00027974

	while (charindex(',', @charters, @curPosition + 1) > 0 or @flag = 0)
	begin
		set @curPosition = charindex(',', @charters, @curPosition + 1)
		if (@curPosition = 0)
		begin

			set @charterString  = substring(@charters, @prevPosition, len(@charters))

			set @curPosition = len(@charters)
			set @flag = 1
		end 
		else
			set @charterString  = substring(@charters, @prevPosition, @curPosition - @prevPosition)

		set @prevPosition = @curPosition + 1

		set @tmpPrevPosition = 0
		set @tmpCurPosition = charindex(':', @charterString, @tmpPrevPosition + 1)
		set @chkey = CAST(substring(@charterString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
		set @tmpPrevPosition = @tmpCurPosition + 1

		set @tmpCurPosition = charindex(':', @charterString, @tmpPrevPosition + 1)
		set @chday = CAST(substring(@charterString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
		set @tmpPrevPosition = @tmpCurPosition + 1

		set @tmpCurPosition = charindex(':', @charterString, @tmpPrevPosition + 1)
		set @chprkey = CAST(substring(@charterString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
		set @tmpPrevPosition = @tmpCurPosition + 1

		set @chpkkey = CAST(substring(@charterString, @tmpPrevPosition, len(@charterString) + 1 - @tmpPrevPosition) as int)

			set @curQuota = null
			if(@chkey > 0)
			begin 
				select @curQuota=res from #checked where svkey=1 and code=@chkey and date=@tourdate and day=@chday and days=@tourDays and prkey=@chprkey and pkkey=@chpkkey
				if (@curQuota is null)
				begin
					-- MEG00027974 Paul G 30.08.2010
					-- нужно расчитать день связанного перелёта
					select @cityfromkey = ch_citykeyfrom from charter where ch_key = @chkey
					select @citytokey = ch_citykeyto from charter where ch_key = @chkey
					select @linkedchday = chday 
					from charter
						inner join @linkedcharterstable on ch_key = chkey
					where ch_citykeyfrom = @citytokey and ch_citykeyto = @cityfromkey
					-- End MEG00027974

					exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @tourDays, @expiredReleaseResult, @aviaQuotaMask, @curQuota output, @linkedchday, 1, @airlineCodes
					insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(1,@chkey,0,0,@tourdate,@chday,@tourDays,@chprkey, @chpkkey, @curQuota)
				end	
				if (len(@curQuota) = 0)
				begin
					set @result = ''
					return
				end

				set @result = dbo.mwConcatFlightsGroupsQuotas(@result, @curQuota)

			end
	end
end
go

grant exec on dbo.mwCheckFlightGroupsQuotesWithInnerFlights to public
go
/*********************************************************************/
/* end sp_mwCheckFlightGroupsQuotesWithInnerFlights.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCheckFlightGroupsQuotes.sql */
/*********************************************************************/
if object_id('dbo.mwCheckFlightGroupsQuotes', 'p') is not null
	drop proc dbo.mwCheckFlightGroupsQuotes
go

create proc [dbo].[mwCheckFlightGroupsQuotes]
	@pagingType int,
	@chkey int,
	@flightGroups varchar(256),
	@agentKey int,
	@partnerKey int,
	@tourdate datetime,
	@day int,
	@requestOnRelease int,
	@noPlacesResult int,
	@checkAgentQuota int,
	@checkCommonQuota int,
	@checkNoLongQuota int,
	@findFlight smallint,
	@pkkey int,
	@tourDays int,
	@expiredReleaseResult int,
	@aviaQuotaMask smallint,
	@result varchar(256) output,	-- формат: <FreePlaces>:<TotalPlaces> [ | ...n]
	@linked_day int = null,
	@requestedPlaces int = 1,
	@airlineCodes ListSysNameValue readonly
as
begin

	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-09-02</DATE>
	if exists (select top 1 1 from SystemSettings with (nolock) where SS_ParmName = 'ServiceFlightSelection' and SS_ParmValue = 1)
	begin
		Declare @charterDateToService datetime
		set @charterDateToService = DATEADD(DAY, @day - 1, @tourdate)

		create table #resultTable
		(
			id int identity(1, 1),
			value nvarchar(max)
		)

		insert into #resultTable
		EXEC	[dbo].[WcfCheckFlightGroupQuotas]
				@charterGroupsString = @flightGroups,
				@charterKey = @chkey,
				@charterDate = @charterDateToService,
				@aviaQuotaMask = @aviaQuotaMask,
				@packetKey = @pkkey,
				@agentKey = @agentKey,
				@requestedPlaces = @requestedPlaces,
				@tourDuration = @tourDays

		select @result = value from #resultTable where id = 1
		Return;
	end

	-- настройки проверки квот через веб-сервис
	declare @checkQuotesOnWebService as bit, @checkQuotesService as nvarchar(150), @wasErrorCallingService bit
	set @checkQuotesOnWebService = 0
	set @wasErrorCallingService = 0
	select top 1 @checkQuotesOnWebService = ss_parmvalue from systemsettings with (nolock) where ss_parmname = 'NewSetToQuota'	

	declare @DYNAMIC_SPO_PAGING smallint
	set @DYNAMIC_SPO_PAGING=3

	declare @now datetime, @percentPlaces float
	select @now = currentDate from dbo.mwCurrentDate

	if(@aviaQuotaMask is null)
		set @aviaQuotaMask = 0

	declare @correctionResult varchar(128)
	set @result = ''
	set @correctionResult = ''

	declare @gpos int, @pos int, @gplaces int, @gallplaces int, @tmpPlaces int, @checkQuotesResult nvarchar(max), @tmpPlacesAll int, @gStep smallint, @gCorrection int
	set @gpos = 1
	
	declare @gseparatorPos int, @separatorPos int,
		@groupKeys varchar(256), @key varchar(256), @nkey int,
		@glen int, @len int

	set @glen = len(@flightGroups)
	while(@gpos < @glen)
	begin
		set @gseparatorPos = charindex('|', @flightGroups, @gpos)
		if(@gseparatorPos = 0)
		begin
			set @groupKeys = substring(@flightGroups, @gpos, @glen - @gpos + 1)	
			set @gpos = @glen
		end
		else
		begin
			set @groupKeys = substring(@flightGroups, @gpos, @gseparatorPos - @gpos)
			set @gpos = @gseparatorPos + 1
		end

		if(len(@result) > 0)
		begin
			set @result = @result + '|'
			if(@pagingType = @DYNAMIC_SPO_PAGING)
			begin
				set @correctionResult = @correctionResult + '|'
			end
		end

		set @gplaces = 0
		set @gallplaces = 0
		set @pos = 1
		set @len = len(@groupKeys)		
		while(@pos < @len)
		begin
			set @separatorPos = charindex(',', @groupKeys, @pos)
			if(@separatorPos = 0)
			begin
				set @key = substring(@groupKeys, @pos, @len - @pos + 1)	
				set @pos = @len
			end
			else
			begin
				set @key = substring(@groupKeys, @pos, @separatorPos - @pos)
				set @pos = @separatorPos + 1
			end

			set @nkey = cast(@key as int)
			if @checkQuotesOnWebService = 1
			begin
				-- включена проверка квот через веб-сервис
				-- подбор перелетов
				declare @cityFrom as int, @cityTo as int
				declare @charterDate datetime, @dayOfWeek int
				select top 1 @cityFrom = ch_citykeyfrom, @cityTo = ch_citykeyto from charter with(nolock) where ch_key = @chkey
				set @charterDate = DATEADD(DAY, @day - 1, @tourdate)
				
				set @wasErrorCallingService = 1	-- в случае, если сервис проверки не отработает - установим признак ошибки, чтобы проверить квоты старым способом
				
				set @dayOfWeek = datepart(dw, @charterDate) - 1
				if(@dayOfWeek = 0)
					set @dayOfWeek = 7

				declare @airlineCodesList ListSysNameValue
				if exists (select top 1 1 from @airlineCodes)
					insert into @airlineCodesList select value from @airlineCodes
				else
					insert into @airlineCodesList select al_code from airline

				declare altCharters cursor for
				select ch_key from
				(
					select distinct ch_key, case when ch_key=@chkey then 1 else 0 end as pr 
					from Charter with (nolock)
					left join AirSeason with (nolock) on AS_CHKEY = CH_KEY
					inner join tbl_costs with(nolock) on (cs_svkey = 1 
														and cs_code = ch_key 
														and (@charterDate between cs_date and cs_dateend
															or @charterDate between cs_checkindatebeg and cs_checkindateend)
														and cs_subcode1=@nkey 
														and cs_pkkey = @pkkey)
					where (@findFlight <> 0 or ch_key=@chkey)
						and CH_CITYKEYFROM = @cityFrom
						and CH_CITYKEYTO = @cityTo
						and (AS_WEEK is null 
								or len(as_week)=0 
								or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
						and @charterDate between as_dateFrom and as_dateto
						and ch_airlinecode in (select value from @airlineCodesList)
				) as alts
				order by pr desc
				
				declare @remPlaces int, @remPlacesAll int, @remResult int
				create table #charterPlacesResult
				(
					xPlaces int,
					xPlacesAll int,
					xPriority int
				)

				declare @altChKey as int
				open altCharters

				fetch next from altCharters into @altChKey
				while @@FETCH_STATUS = 0
				begin
					declare @dateFrom datetime, @dateTo datetime
					set @dateFrom = dateadd(day, @day-1, @tourdate)
					set @dateTo = dateadd(day, @day-1, @tourdate)

					begin try							
						exec mwCheckQuotaOneResult 1, 1, @altChKey, @nkey, @dateFrom, @dateTo,
							null, @agentKey, @tourDays, @requestedPlaces, null, @checkQuotesResult output, @tmpPlaces output, @tmpPlacesAll output
						
						set @wasErrorCallingService = 0						
					end try
					begin catch
						set @wasErrorCallingService = 1
						break
					end catch
								
					declare @freePlacesMask as int

					if @checkQuotesResult in ('StopSale', 'NoPlaces')
						set @freePlacesMask = 2	-- no places
					else if @checkQuotesResult in ('Release', 'Duration', 'NoQuota')
					begin
						set @freePlacesMask = 4	-- request
						set @tmpPlaces = -1
					end
					else if @checkQuotesResult = 'QuotaExist'
						set @freePlacesMask = 1	-- yes
						
					if (@aviaQuotaMask & @freePlacesMask) = @freePlacesMask
					begin
						declare @priority int
						if (@freePlacesMask = 1)
							set @priority = 1
						else if (@freePlacesMask = 4)
							set @priority = 2
						else
							set @priority = 3
						insert into #charterPlacesResult (xPlaces, xPlacesAll, xPriority) values (@tmpPlaces, @tmpPlacesAll, @priority)
					end
					
					fetch next from altCharters into @altChKey
				
				end
				
				if @wasErrorCallingService = 0
				begin
					select top 1 @tmpPlaces = xPlaces, @tmpPlacesAll = xPlacesAll from #charterPlacesResult order by xPriority asc					
				end
				
				close altCharters
				deallocate altCharters
				
				drop table #charterPlacesResult
			end
			
			-- не сделано через else к условию if @checkQuotesOnWebService = 1, чтобы в случае
			-- ошибки работы с веб-сервисом проверки квот
			if @wasErrorCallingService = 1 or @checkQuotesOnWebService = 0
			begin
				select @tmpPlaces = qt_places, @tmpPlacesAll = qt_allPlaces
				from dbo.mwCheckQuotesEx2(1, @chkey, @nkey, 0, @agentKey, @partnerKey, @tourdate,
					@day, 1, @requestOnRelease, @noPlacesResult, @checkAgentQuota,
					@checkCommonQuota, @checkNoLongQuota, @findFlight, 0, 0, @pkkey,
					@tourDays, @expiredReleaseResult, @linked_day, @airlineCodes)
			end

			if(@gplaces = 0 or (@tmpPlaces > 0 and @tmpPlaces > @gplaces))
			begin
				set @gplaces = @tmpPlaces
				set @gallplaces = @tmpPlacesAll

				if(@pagingType = @DYNAMIC_SPO_PAGING)
				begin
					set @percentPlaces = 0.0
					if(@gplaces > 0 and @gallplaces > 0)
						set @percentPlaces = 1.0*@gplaces/@gallplaces
					exec dbo.GetDynamicCorrections @now,@tourdate,1,@chkey,@nkey,0,@percentPlaces, @gStep output, @gCorrection output				
				end
			end

			if(@gplaces > 0)
				break	
		end

		set @result = @result + cast(@gplaces as varchar) + ':' + cast(@gallplaces as varchar)
		if(@pagingType = @DYNAMIC_SPO_PAGING)
			set @correctionResult = @correctionResult + cast(@gCorrection as varchar) + ':' + cast(@gStep as varchar)
	end

	if(@pagingType = @DYNAMIC_SPO_PAGING)
		set @result = @result + '#' + @correctionResult
end
go

grant exec on dbo.mwCheckFlightGroupsQuotes to public
go
/*********************************************************************/
/* end sp_mwCheckFlightGroupsQuotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCheckQuotesCycle.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesCycle]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwCheckQuotesCycle]
GO

create procedure [dbo].[mwCheckQuotesCycle]
	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-09-02</DATE>
@pagingType	smallint,
@pageNum	int,		-- номер страницы(начиная с 1 или количество уже просмотренных записей для исключения при @pagingType=@ACTUALPLACES_PAGING)
@pageSize	int,
@agentKey	int,
@hotelQuotaMask smallint,
@aviaQuotaMask smallint,
@flightGroups	varchar(256),
@checkAgentQuota smallint,
@checkCommonQuota smallint,
@checkNoLongQuota smallint,
@requestOnRelease smallint,
@expiredReleaseResult int,
@noPlacesResult int,
@findFlight smallint = 0,	-- параметр устарел, вместо него используется признак подбора перелета. Оставлен для совместимости.
-- 4864 gorshkov
-- признак того, что мы подбираем варианты для подмешивания в поиск
@smartSearch bit = 0,
@tableName varchar(256) = null,
@airlineCodes ListSysNameValue readonly
as
begin
	-- настройки проверки квот через веб-сервис
	declare @checkQuotesOnWebService as bit, @checkQuotesService as nvarchar(150), @wasErrorCallingService bit
	set @checkQuotesOnWebService = 0
	set @wasErrorCallingService = 0
	select top 1 @checkQuotesOnWebService = ss_parmvalue from systemsettings with (nolock) where ss_parmname = 'NewSetToQuota'

	declare @sAviaTariffFirst varchar(10), @sAviaTariffSecond varchar(10), 
	@nAviaTariffFirst smallint, @nAviaTariffSecond smallint
	
	declare @initialFindflight int
	set @initialFindflight = @findFlight

	declare @GREEN_LABEL smallint, @YELLOW_LABEL smallint, @RED_LABEL smallint
	set @GREEN_LABEL = 1
	set @YELLOW_LABEL = 4
	set @RED_LABEL = 2

	declare @step_index smallint, @price_correction int, @additional varchar(2000)
	
	if (@smartSearch = 1)
	begin
		-- хранит ключи отелей которые были подмешаны в поиск
		declare @smartSearchKeys table (hdKey int);
	end
	else
	begin
		-- настройка включающая SmartSearch
		declare @mwUseSmartSearch int
		select @mwUseSmartSearch=isnull(SS_ParmValue,0) from dbo.systemsettings 
		where SS_ParmName='mwUseSmartSearch'
		-- пока SmartSearch работает с только с ACTUALPLACES_PAGING
		if (@pagingType <> 2)
		begin
			set @mwUseSmartSearch = 0
		end
	end

	declare @mwCheckInnerAviaQuotes int
	select @mwCheckInnerAviaQuotes = isnull(SS_ParmValue,0) from dbo.systemsettings 
	where SS_ParmName = 'mwCheckInnerAviaQuotes'

	declare @DYNAMIC_SPO_PAGING smallint
	set @DYNAMIC_SPO_PAGING=3

	declare @tmpHotelQuota varchar(10), @tmpThereAviaQuota varchar(256), @tmpBackAviaQuota varchar(256), @allPlaces int,@places int,@actual smallint,@tmp varchar(256),
			@ptkey bigint,@pttourkey int, @ptpricekey bigint, @hdkey int,@rmkey int,@rckey int,@tourdate datetime,@chkey int,@chbackkey int,@hdday int,@hdnights int,@hdprkey int,	@chday int,@chpkkey int,@chprkey int,@chbackday int,
		@chbackpkkey int,@chbackprkey int,@days int, @rowNum int, @hdStep smallint, @reviewed int,@selected int, @hdPriceCorrection int, 
		@pt_directFlightAttribute int, @pt_backFlightAttribute int, @pt_mainplaces int, @pt_hrkey int, @sql varchar(max)

	declare @pt_chdirectkeys varchar(256), @pt_chbackkeys varchar(256)
	declare @tmpAllHotelQuota varchar(128),@pt_hddetails varchar(256)

	set @reviewed= @pageNum
	set @selected=0

	declare @sortedAirlineCodes ListSysNameValue
	insert into @sortedAirlineCodes select value from @airlineCodes order by upper([value])
				
	declare @airlineCodesStr varchar(max)
	select @airlineCodesStr = coalesce(@airlineCodesStr + ', ', '') + [value] from @sortedAirlineCodes order by [value]

	declare @now datetime, @percentPlaces float, @pos int
	declare @dateFrom datetime, @dateTo datetime
	set @now = getdate()
	set @pos = 0

	fetch next from quotaCursor into
	@ptkey,	
	@pttourkey,
	@ptpricekey,
	@hdkey,
	@rmkey,
	@rckey,
	@tourdate,
	@hdday,
	@hdnights,
	@hdprkey,
	@chday,
	@chpkkey,
	@chprkey,
	@chbackday,
	@chbackpkkey,
	@chbackprkey,
	@days,
	@chkey,
	@chbackkey,
	@rowNum, 
	@pt_chdirectkeys, 
	@pt_chbackkeys, 
	@pt_hddetails, 
	@pt_directFlightAttribute, 
	@pt_backFlightAttribute,
	@pt_mainplaces,
	@pt_hrkey

	declare @priceKeysPackIndex int; set @priceKeysPackIndex = 0;
	declare @priceKeysPackSize int; set @priceKeysPackSize = 100;
	declare @priceKeysPackString varchar(1800); set @priceKeysPackString = '';
	declare @serviceFlightSelection int; select @serviceFlightSelection = SS_ParmValue from SystemSettings with (nolock) where SS_ParmName = 'ServiceFlightSelection';
	
	while(@@fetch_status=0 and @selected < @pageSize)
	begin 
		if (@serviceFlightSelection = 1)
		begin			
			set @priceKeysPackIndex = @priceKeysPackIndex + 1;
			set @priceKeysPackString = @priceKeysPackString + ',' + @ptpricekey
		
			if (@priceKeysPackIndex = @priceKeysPackSize)
			begin
				insert into #paging (ptKey, pt_hdquota, ptpricekey, pt_chtherequota, pt_chbackquota, chkey, chbackkey, priceCorrection, pt_hdallquota, pt_smartSearch)
				exec WcfCheckQuotaCycle @priceKeysPackString;
				set @priceKeysPackString = '';
				set @priceKeysPackIndex = 0;
			end
			
		end
		else
		begin
			if (@pos >= @pageNum 
			-- для подмешиваемых вариантов - интересует только одно размещение для каждого отеля
			and (@smartSearch = 0 or not exists (select top 1 1 from @smartSearchKeys where hdKey = @hdkey)))
			begin

				set @actual=1
				if(@aviaQuotaMask > 0)
				begin		
					declare @editableCode int
					set @editableCode = 2
					declare @isEditableService bit
					set @tmpThereAviaQuota=null
					if(@chkey > 0)
					begin 
						if @pt_directFlightAttribute is null
						begin
							--kadraliev MEG00025990 03.11.2010 Если в туре запрещено менять рейс, устанавливаем @findFlight = 0
							exec dbo.mwGetServiceIsEditableAttribute @pttourkey, @chkey, @chday, @days, @chprkey, @chpkkey, @isEditableService output
							if (@isEditableService = 0)
								set @pt_directFlightAttribute = 0
							else
								set @pt_directFlightAttribute = 2
							if (@tableName is not null)
							begin
								set @sql = 'update ' + @tableName + ' set pt_directFlightAttribute = ' + ltrim(str(@pt_directFlightAttribute)) + ' where pt_key = ' + ltrim(str(@ptkey))
								exec (@sql)
							end
						end
						set @findFlight = (@pt_directFlightAttribute & 2) / 2
										
						set @places=0
						EXEC [dbo].[mwCacheQuotaSearch] 1, @chkey, 0, 0, @tourdate, @chday, @days, @chprkey, @chpkkey, 
							@tmpThereAviaQuota OUTPUT, @places output, @step_index output, @price_correction output, @additional output, @findFlight, @airlineCodesStr

						if (@tmpThereAviaQuota is null)
						begin		
							
							set @tmpThereAviaQuota = ''
							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, 
								@requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey,
								@days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @chbackday, @pt_mainplaces, @airlineCodes
							if len(ISNULL(@tmpThereAviaQuota, '')) != 0
							begin
								set @nAviaTariffFirst=0
								set @nAviaTariffSecond=0
								if len(@tmpThereAviaQuota)!=0
								BEGIN
									select 
										@sAviaTariffFirst = LEFT(@tmpThereAviaQuota,PATINDEX('%:%',@tmpThereAviaQuota)-1),
										@sAviaTariffSecond = LEFT(
										SUBSTRING(@tmpThereAviaQuota,PATINDEX('%|%',@tmpThereAviaQuota)+1,LEN(@tmpThereAviaQuota)-PATINDEX('%|%',@tmpThereAviaQuota)),
										PATINDEX('%:%',SUBSTRING(@tmpThereAviaQuota,PATINDEX('%|%',@tmpThereAviaQuota)+1,LEN(@tmpThereAviaQuota)-PATINDEX('%|%',@tmpThereAviaQuota)))-1)
									IF ISNUMERIC(@sAviaTariffFirst)=1
										set @nAviaTariffFirst=CAST(@sAviaTariffFirst as smallint)
									IF ISNUMERIC(@sAviaTariffSecond)=1
										set @nAviaTariffSecond=CAST(@sAviaTariffSecond as smallint)
									SET @places = abs(@nAviaTariffFirst)+abs(@nAviaTariffSecond)
								END

								EXEC [dbo].[mwCacheQuotaInsert] 1,@chkey,0,0,@tourdate,@chday,@days,@chprkey,@chpkkey,@tmpThereAviaQuota, @places, 0, 0, @additional, @findFlight, @airlineCodesStr
							end
						end		
						
						if len(@tmpThereAviaQuota)!=0
						begin
							-- проверка наличия мест на прямом перелете на соответствие маске квот
							-- проверяются все классы перелетов, если хотя бы один подходит - результат принимается
							declare @curIndex as int
							set @curIndex = 1
							
							declare @quota as varchar(260)
							set @quota = @tmpThereAviaQuota + '|'

							set @actual=0

							while @curIndex <= LEN(@quota)
							begin

								declare @freePlaces as int
								declare @freePlacesString as varchar(20)
								
								set @freePlaces = 0
								
								set @freePlacesString = SUBSTRING(@quota, @curIndex, CHARINDEX(':', @quota, @curIndex)-@curIndex)
								if ISNUMERIC(@freePlacesString) = 1
									set @freePlaces = CAST(@freePlacesString as smallint)
								
								set @curIndex = CHARINDEX('|', @quota, @curIndex)+1

								declare @freePlacesMask as int

								if @freePlaces = 0
									set @freePlacesMask = 2	-- no places
								else if @freePlaces < 0
									set @freePlacesMask = 4	-- request
								else
									set @freePlacesMask = 1	-- yes
									
								if (@aviaQuotaMask & @freePlacesMask) = @freePlacesMask
								begin
									-- прямой перелет удовлетворяет маске квот, прекращаем проверку
									set @actual=1
									break
								end
							end
						end
						else
							set @actual=0
					end
					if(@actual > 0)
					begin
						set @tmpBackAviaQuota=null
						if(@chbackkey > 0)
						begin
							if @pt_backFlightAttribute is null
							begin

								--karimbaeva MEG00038768 17.11.2011 получаем редактируемый атрибут услуги
								exec dbo.mwGetServiceIsEditableAttribute @pttourkey, @chbackkey, @chbackday, @days, @chbackprkey, @chbackpkkey, @isEditableService output
								if (@isEditableService = 0)
									set @pt_backFlightAttribute = 0
								else
									set @pt_backFlightAttribute = 2
								if (@tableName is not null)
								begin
									set @sql = 'update ' + @tableName + ' set pt_backFlightAttribute = ' + ltrim(str(@pt_backFlightAttribute)) + ' where pt_key = ' + ltrim(str(@ptkey))
									exec (@sql)
								end
			
							end

							set @findFlight = (@pt_backFlightAttribute & 2) / 2

							EXEC [dbo].[mwCacheQuotaSearch] 1, @chbackkey, 0, 0, @tourdate, @chbackday, @days, @chbackprkey, @chbackpkkey, 
								@tmpBackAviaQuota OUTPUT, @places output, @step_index output, @price_correction output, @additional output, @findFlight, @airlineCodesStr

							if (@tmpBackAviaQuota is null)
							begin
								
								set @tmpBackAviaQuota = ''												
								
								exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chbackkey, @flightGroups, @agentKey, @chbackprkey, @tourdate,
									@chbackday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 
									@findFlight, @chbackpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output, @chday, @pt_mainplaces, @airlineCodes

								if len(ISNULL(@tmpBackAviaQuota, '')) != 0
								begin
									set @nAviaTariffFirst=0
									set @nAviaTariffSecond=0
									if len(@tmpBackAviaQuota)!=0
									BEGIN
										select 
										@sAviaTariffFirst = LEFT(@tmpBackAviaQuota,PATINDEX('%:%',@tmpBackAviaQuota)-1),
										@sAviaTariffSecond = LEFT(
										SUBSTRING(@tmpBackAviaQuota,PATINDEX('%|%',@tmpBackAviaQuota)+1,LEN(@tmpBackAviaQuota)-PATINDEX('%|%',@tmpBackAviaQuota)),
										PATINDEX('%:%',SUBSTRING(@tmpBackAviaQuota,PATINDEX('%|%',@tmpBackAviaQuota)+1,LEN(@tmpBackAviaQuota)-PATINDEX('%|%',@tmpBackAviaQuota)))-1)
										IF ISNUMERIC(@sAviaTariffFirst)=1
											set @nAviaTariffFirst=CAST(@sAviaTariffFirst as smallint)
										IF ISNUMERIC(@sAviaTariffSecond)=1
											set @nAviaTariffSecond=CAST(@sAviaTariffSecond as smallint)
										SET @places = abs(@nAviaTariffFirst)+abs(@nAviaTariffSecond)
									END
															
									EXEC [dbo].[mwCacheQuotaInsert] 1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey,@tmpBackAviaQuota, @places, 0, 0, @additional, @findFlight, @airlineCodesStr
								end
							end

							if len(@tmpBackAviaQuota)!=0
							begin
								-- проверка наличия мест на обратном перелете на соответствие маске квот
								-- проверяются все классы перелетов, если хотя бы один подходит - результат принимается
								set @curIndex = 1						
								set @quota = @tmpBackAviaQuota + '|'
								set @actual=0

								while @curIndex <= LEN(@quota)
								begin
									
									set @freePlaces = 0
									
									set @freePlacesString = SUBSTRING(@quota, @curIndex, CHARINDEX(':', @quota, @curIndex)-@curIndex)
									if ISNUMERIC(@freePlacesString) = 1
										set @freePlaces = CAST(@freePlacesString as smallint)
									
									set @curIndex = CHARINDEX('|', @quota, @curIndex)+1
									if @freePlaces = 0
										set @freePlacesMask = 2	-- no places
									else if @freePlaces < 0
										set @freePlacesMask = 4	-- request
									else
										set @freePlacesMask = 1	-- yes
									
								if (@aviaQuotaMask & @freePlacesMask) = @freePlacesMask
									begin
										-- обратный перелет удовлетворяет маске квот, прекращаем проверку
										set @actual=1
										break
									end

								end
							
							end
							else
								set @actual=0				
								
						end
					end
				end			
				if(@hotelQuotaMask > 0)
				begin
					set @tmpAllHotelQuota = ''
					if(@actual > 0)
					begin
						if not (@pt_hddetails is not null and charindex(',', @pt_hddetails, 0) > 0)
						begin
							-- один отель
							set @tmpHotelQuota=null
							set @hdStep = 0
							set @hdPriceCorrection = 0
							set @places = 0
							
							EXEC [dbo].[mwCacheQuotaSearch] 3, @hdkey, @rmkey, @rckey, @tourdate, @hdday, @hdnights, @hdprkey, 0, 
								@tmpHotelQuota OUTPUT, @places output, @hdStep output, @hdPriceCorrection output, @additional output, 0, ''

							if (@tmpHotelQuota is null)
							begin
								if @checkQuotesOnWebService = 1
								begin
									declare @checkQuotesResult as nvarchar(max)
									set @dateFrom = dateadd(day, @hdday - 1, @tourdate)
									set @dateTo = dateadd(day, @hdnights - 1, @dateFrom)
									
									-- включена проверка квот через веб-сервис								
									begin try
										exec mwCheckQuotaOneResult  1, 3, @hdkey, @pt_hrkey, @dateFrom, @dateTo, @hdprkey, 
												@agentKey, @hdnights, 1, null, @checkQuotesResult output, @places output, @allPlaces output
									end try
									begin catch
										-- Ошибка при вызове веб-сервиса. Логируем, отправляем письмо и отключаем проверку через сервис
										set @wasErrorCallingService = 1
									end catch
											
									if @checkQuotesResult in ('StopSale', 'NoPlaces')
										set @freePlacesMask = 2	-- no places
									else if @checkQuotesResult in ('Release', 'Duration', 'NoQuota')
									begin
										set @freePlacesMask = 4	-- request
										set @places = -1
									end
									else if @checkQuotesResult = 'QuotaExist'
										set @freePlacesMask = 1	-- yes
									
								end
								
								-- не сделано через else к условию if @checkQuotesOnWebService = 1, чтобы в случае
								-- ошибки работы с веб-сервисом проверки квот
								if @wasErrorCallingService = 1 or @checkQuotesOnWebService = 0
								begin
									select @places=qt_places,@allPlaces=qt_allPlaces,@additional=qt_additional 
									from dbo.mwCheckQuotesEx2(3,@hdkey,@rmkey,@rckey, @agentKey, @hdprkey,@tourdate,@hdday,@hdnights, 
										@requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 0, 0, 0, 0, 0,
										@expiredReleaseResult, DEFAULT, @airlineCodes)
										
									if @places = 0
										set @freePlacesMask = 2	-- no places
									else if @places < 0
									begin
										set @freePlacesMask = 4	-- request
									end
									else
										set @freePlacesMask = 1	-- yes
								end
								
								set @tmpHotelQuota=ltrim(str(@places)) + ':' + ltrim(str(@allPlaces))
								if(@pagingType = @DYNAMIC_SPO_PAGING and @places > 0)
								begin
									exec dbo.GetDynamicCorrections @now,@tourdate,3,@hdkey,@rmkey,@rckey,@places, @hdStep output, @hdPriceCorrection output
								end

								EXEC [dbo].[mwCacheQuotaInsert] 3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota,@places,@hdStep,@hdPriceCorrection, @additional, 0, ''
							end
						end 
						else
						-----------------------------------------------
						--=== Check quotes for all hotels in tour ===--
						--===              [BEGIN]                -----
						begin
							set @places = 10000			-- первоначальное значение для дальнейшего сравнения и выбора наименьшего количества мест
														-- в многоотельном туре
						
							set @tmpAllHotelQuota = ''
							-- Mask for hotel details column :
							-- [HotelKey]:[RoomKey]:[RoomCategoryKey]:[HotelDay]:[HotelDays]:[HotelPartnerKey],...
							declare @curHotelKey int, @curRoomKey int , @curRoomCategoryKey int , @curHotelDay int , @curHotelDays int , @curHotelPartnerKey int
							declare @curHotelRoomKey as int

							declare @curHotelDetails varchar(256)
							declare @tempPlaces int
							declare @tempAllPlaces int
							declare @curPosition int
								set @curPosition = 0
							declare @prevPosition int
								set @prevPosition = 0
							declare @curHotelQuota  varchar(256)
							while (1 = 1)
							begin
								set @curPosition = charindex(',', @pt_hddetails, @curPosition + 1)
								if (@curPosition = 0)
									set @curHotelDetails  = substring(@pt_hddetails, @prevPosition, 256)
								else
									set @curHotelDetails  = substring(@pt_hddetails, @prevPosition, @curPosition - @prevPosition)
								
								-- Get details by current hotel
								begin try
									exec mwParseHotelDetails @curHotelDetails, @curHotelKey output, @curRoomKey output, @curRoomCategoryKey output, 
										@curHotelDay output, @curHotelDays output, @curHotelPartnerKey output, @curHotelRoomKey output
								end try
								begin catch
									--произошла ошибка, последующие отели просто не будут проверяться на наличие мест
									break
								end catch
								-----
								set @curHotelQuota = null
								EXEC [dbo].[mwCacheQuotaSearch] 3, @curHotelKey, @curRoomKey, @curRoomCategoryKey, @tourdate, @curHotelDay, @curHotelDays, @curHotelPartnerKey, 0, 
									@curHotelQuota OUTPUT, @tempPlaces output, @hdStep output, @hdPriceCorrection output, @additional output, 0, ''

								if (@curHotelQuota is null)
								begin
									if @checkQuotesOnWebService = 1
									begin
										begin try
											set @dateFrom = dateadd(day, @curHotelDay - 1, @tourdate)
											set @dateTo = dateadd(day, @curHotelDays - 1, @dateFrom)
											
											-- включена проверка квот через веб-сервис
											exec mwCheckQuotaOneResult 1, 3, @curHotelKey, @curHotelRoomKey, @dateFrom, @dateTo, @curHotelPartnerKey, 
													@agentKey, @curHotelDays, 1, null, @checkQuotesResult output, @tempPlaces output, @tempAllPlaces output
													
											-- отдельный случай для статуса "Запрос": сервис возвращает количество мест 0, а ожидается -1
											if @checkQuotesResult in ('Release', 'Duration', 'NoQuota')
												set @tempPlaces = -1
													
										end try
										begin catch
											set @wasErrorCallingService = 1
										end catch									
									end
									
									-- не сделано через else к условию if @checkQuotesOnWebService = 1, чтобы в случае
									-- ошибки работы с веб-сервисом проверки квот
									if @wasErrorCallingService = 1 or @checkQuotesOnWebService = 0
									begin
										select @tempPlaces=qt_places,@tempAllPlaces=qt_allPlaces,@additional=qt_additional 
										from dbo.mwCheckQuotesEx2(3,@curHotelKey,@curRoomKey,@curRoomCategoryKey, @agentKey, @curHotelPartnerKey,@tourdate,@curHotelDay,@curHotelDays, 
												@requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 0, 0, 0, 0, 0, @expiredReleaseResult, DEFAULT, @airlineCodes)
									end
									
									set @curHotelQuota=ltrim(str(@tempPlaces)) + ':' + ltrim(str(@tempAllPlaces))

									EXEC [dbo].[mwCacheQuotaInsert] 3,@curHotelKey,@curRoomKey,@curRoomCategoryKey,@tourdate,@curHotelDay,@curHotelDays,@curHotelPartnerKey,0,@curHotelQuota,@tempPlaces,0,0, @additional, 0, ''
								end
								-----
								set @tmpAllHotelQuota = @tmpAllHotelQuota + @curHotelQuota + '|'
								
								if (@tempPlaces < @places or (@places < 0 and @tempPlaces = 0)) and not (@places = 0 and @tempPlaces < 0)
								begin
									
									-- @places - результирующее значение количества мест в текущей строке. Оно принимается как
									-- минимальное из всех отелей в случае многоотельного тура
									-- Условие написано с учетом того, что в данном случае -1 > 0 (нет мест - более сильный статус, чем запрос)
									set @places = @tempPlaces
									set @tmpHotelQuota = @curHotelQuota

								end

								if (@curPosition = 0)
									break
								set @prevPosition = @curPosition + 1
							end
							
							-- Remove comma at the end of string
							if(len(@tmpAllHotelQuota) > 0)
								set @tmpAllHotelQuota = substring(@tmpAllHotelQuota, 1, len(@tmpAllHotelQuota) - 1)
						end
						--===                [END]                -----
						--=== Check quotes for all hotels in tour ===--
						-----------------------------------------------
						
						if @places = 0
							set @freePlacesMask = 2	-- no places
						else if @places < 0
						begin
							set @freePlacesMask = 4	-- request
						end
						else
							set @freePlacesMask = 1	-- yes
								
						if (@hotelQuotaMask & @freePlacesMask) = @freePlacesMask
							set @actual = 1
						else
							set @actual = 0
						
						--if((@places > 0 and (@hotelQuotaMask & 1)=0) or (@places=0 and (@hotelQuotaMask & 2)=0) or (@places=-1 and (@hotelQuotaMask & 4)=0))
						--	set @actual=0
					end
				end



		------==============================================================================================------
		--============================ Check inner avia quotes if needed by settings ===========================--
		--========																						========--
				if(@actual > 0 and @mwCheckInnerAviaQuotes > 0)
				begin
					-- Direct flights
					if (@pt_chdirectkeys is not null and charindex(',', @pt_chdirectkeys, 0) > 0)
					begin
						set @findFlight = @initialFindflight
						exec dbo.mwCheckFlightGroupsQuotesWithInnerFlights @pagingType, @pt_chdirectkeys, 
								@flightGroups, @agentKey, @tourdate, @requestOnRelease, @noPlacesResult, 
								@checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, 
								@days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @pt_chbackkeys, @airlineCodes
						if (len(@tmpThereAviaQuota) = 0)
							set @actual = 0
					end 

					-- Back flights
					if(@actual > 0)
					begin
						if (@pt_chbackkeys is not null and charindex(',', @pt_chbackkeys, 0) > 0)
						begin
							set @findFlight = @initialFindflight
							exec dbo.mwCheckFlightGroupsQuotesWithInnerFlights @pagingType, @pt_chbackkeys,   
								@flightGroups, @agentKey, @tourdate, @requestOnRelease, @noPlacesResult, 
								@checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, 
								@days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output, @pt_chdirectkeys, @airlineCodes
							if (len(@tmpBackAviaQuota) = 0)
								set @actual = 0
						end 
					end
				end
		--========																						========--
		--============================                                               ===========================--
		------==============================================================================================------
				
				if(@actual > 0)
				begin
					if (@smartSearch = 1)
					begin
						-- сохраним ключ отеля для которого уже было добавлено размещение
						insert into @smartSearchKeys(hdKey) values (@hdkey)
						set @selected=@selected + 1
						-- pt_smartSearch = 1 (для выделения подмешанных вариантов)
						insert into #Paging(ptKey,pt_hdquota,pt_chtherequota,pt_chbackquota,chkey,chbackkey,stepId,priceCorrection, pt_hdallquota, pt_smartSearch)
						values(@ptkey,@tmpHotelQuota,@tmpThereAviaQuota,@tmpBackAviaQuota,@chkey,@chbackkey,@hdStep,@hdPriceCorrection, @tmpAllHotelQuota, 1)
					end
					-- если используется SmartSearch (глобально - включена настройка, но mwCheckQuotesCycle вызвана НЕ для подмешанных вариантов) 
					-- то возможна ситуация когда данный ptKey уже был добавлен в #Paging как подмешанный
					else if (@mwUseSmartSearch = 0 or not exists (select top 1 1 from #Paging where ptKey = @ptkey))
					begin
						set @selected=@selected + 1
						insert into #Paging(ptKey,ptpricekey,pt_hdquota,pt_chtherequota,pt_chbackquota,chkey,chbackkey,stepId,priceCorrection, pt_hdallquota)
						values(@ptkey,@ptpricekey,@tmpHotelQuota,@tmpThereAviaQuota,@tmpBackAviaQuota,@chkey,@chbackkey,@hdStep,@hdPriceCorrection, @tmpAllHotelQuota)
					end
				end

				set @reviewed=@reviewed + 1
			end
			fetch next from quotaCursor into @ptkey,@pttourkey,@ptpricekey,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,@chday,@chpkkey,
				@chprkey,@chbackday,@chbackpkkey,@chbackprkey,@days,@chkey,@chbackkey,@rowNum, @pt_chdirectkeys, @pt_chbackkeys, 
				@pt_hddetails, @pt_directFlightAttribute, @pt_backFlightAttribute, @pt_mainplaces, @pt_hrkey
			set @pos = @pos + 1
			if (@serviceFlightSelection = 1 and @priceKeysPackIndex > 0 and @@fetch_status <> 0)
			begin
				insert into #paging (ptKey, pt_hdquota, ptpricekey, pt_chtherequota, pt_chbackquota, chkey, chbackkey, priceCorrection, pt_hdallquota, pt_smartSearch)
				exec WcfCheckQuotaCycle @priceKeysPackString;
			end
		end
	end

	if (@smartSearch=0)
	begin
		select @reviewed
	end
end
GO

GRANT EXECUTE on [dbo].[mwCheckQuotesCycle] to public
GO

/*********************************************************************/
/* end sp_mwCheckQuotesCycle.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_Paging.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Paging]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[Paging]
GO

	--<VERSION>9.2.20</VERSION>
	--<DATE>2014-09-02</DATE>
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
	@HideWithNotStartedSaleDate bit = 0,	-- не показывать цены по турам, дата продажи которых еще не наступила.
	@airlineCodes ListSysNameValue readonly
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

declare @sql nvarchar(MAX)
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

				exec dbo.mwCheckQuotesCycle ' + ltrim(str(@pagingType))+ ', ' + @spageNum + ', ' + @smaxSmartSearchResult + ', ' + ltrim(str(@agentKey)) + ', 1, 1, ''' + @flightGroups + ''', ' + ltrim(str(@checkAgentQuota)) + ', ' + ltrim(str(@checkCommonQuota)) + ', ' + ltrim(str(@checkNoLongQuota)) + ', ' + ltrim(str(@requestOnRelease)) + ', ' + ltrim(str(@expiredReleaseResult)) + ', ' + ltrim(str(@noPlacesResult)) + ', ' + ltrim(str(@findFlight)) + ', 1, null, @airlineCodes

				close quotaCursor
				deallocate quotaCursor
				'

				EXECUTE sp_executesql @sql, 
									  N'@airlineCodes ListSysNameValue READONLY', 
								      @airlineCodes

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

				exec dbo.mwCheckQuotesCycle ' + ltrim(str(@pagingType))+ ', ' + @spageNum + ', ' + @spageSize + ', ' + ltrim(str(@agentKey)) + ', ' + ltrim(str(@hotelQuotaMask)) + ', ' + ltrim(str(@aviaQuotaMask)) + ', ''' + @flightGroups + ''', ' + ltrim(str(@checkAgentQuota)) + ', ' + ltrim(str(@checkCommonQuota)) + ', ' + ltrim(str(@checkNoLongQuota)) + ', ' + ltrim(str(@requestOnRelease)) + ', ' + ltrim(str(@expiredReleaseResult)) + ', ' + ltrim(str(@noPlacesResult)) + ', ' + ltrim(str(@findFlight)) + ', 0, ''' + @tableName + ''', @airlineCodes

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
		
		EXECUTE sp_executesql @sql, 
						      N'@airlineCodes ListSysNameValue READONLY', 
							  @airlineCodes

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
/* begin (2014-09-01)_X_SVKEY_TRKEY_TurService.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TurService]') AND name = N'X_SVKEY_TRKEY')
	DROP INDEX [X_SVKEY_TRKEY] ON [dbo].[TurService] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [X_SVKEY_TRKEY] ON [dbo].[TurService]
(
	[TS_SVKEY] ASC,
	[TS_TRKEY] ASC
)
INCLUDE
(
	TS_PKKey,
	TS_CTKey,
	TS_SubCode2
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/*********************************************************************/
/* end (2014-09-01)_X_SVKEY_TRKEY_TurService.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014.08.26)_Insert_Actions.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 160) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (160, '"Работа менеджеров" -> Скрыть колонку "Прибыль планируемая"', 'Скрывать колонку "Прибыль планируемая" в экране "Работа менеджеров"', 'Window "Manager work" -> Hide columns "Profit planned"', 1)
END
ELSE
BEGIN
    UPDATE Actions SET AC_Name = '"Работа менеджеров" -> Скрыть колонку "Прибыль планируемая"', AC_Description =  'Скрывать колонку "Прибыль планируемая" в экране "Работа менеджеров"', AC_NameLat = 'Window "Manager work" -> Hide columns "Profit planned"'
        WHERE ac_key = 160
END
GO

IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 161) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (161, '"Работа менеджеров" -> Скрыть колонку "Прибыль планируемая, %"', 'Скрывать колонку "Прибыль планируемая %" в экране "Работа менеджеров"', 'Window "Manager work" -> Hide columns "Profit planned %"', 1)
END
BEGIN
    UPDATE Actions SET AC_Name = '"Работа менеджеров" -> Скрыть колонку "Прибыль планируемая, %"', AC_Description =  'Скрывать колонку "Прибыль планируемая %" в экране "Работа менеджеров"', AC_NameLat ='Window "Manager work" -> Hide columns "Profit planned %"'
        WHERE ac_key = 161
END
GO

IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 162) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (162, '"Работа менеджеров" -> Скрыть колонку "Прибыль реальная"', 'Скрывать колонку "Прибыль реальная" в экране  "Работа менеджеров"', 'Window "Manager work" -> Hide columns "Profit real"', 1)
END
BEGIN
    UPDATE Actions SET AC_Name = '"Работа менеджеров" -> Скрыть колонку "Прибыль реальная"', AC_Description =  'Скрывать колонку "Прибыль реальная" в экране  "Работа менеджеров"', AC_NameLat =  'Window "Manager work" -> Hide columns "Profit real"'
        WHERE ac_key = 162
END
GO

IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 170) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (170, '"Турпутевка" и "Оформление клиентов" -> Скрыть колонку "Прибыль планируемая"', 'Скрывать колонку "Прибыль планируемая" в экранах "Турпутевка" и "Оформление клиентов"', 'Window "Dogovor" and "Tour sale" -> Hide columns -> "Profit planned"', 1)
END
GO

IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 171) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (171, '"Турпутевка" и "Оформление клиентов" -> Скрыть колонку "Прибыль планируемая, %"', 'Скрывать колонку "Прибыль планируемая %" в экранах "Турпутевка" и "Оформление клиентов"', 'Window "Dogovor" and "Tour sale" -> Hide columns -> "Profit planned %"', 1)
END
GO

IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 172) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (172, '"Турпутевка" и "Оформление клиентов" -> Скрыть колонку "Прибыль реальная"', 'Скрывать колонку "Прибыль реальная" в экранах "Турпутевка" и "Оформление клиентов"', 'Window "Dogovor" and "Tour sale" -> Hide columns -> "Profit real"', 1)
END
GO
/*********************************************************************/
/* end (2014.08.26)_Insert_Actions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetAccmdNameByHRKey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetAccmdNameByHRKey]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetAccmdNameByHRKey]
GO

CREATE FUNCTION [dbo].[fn_GetAccmdNameByHRKey]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nHRKey INT
) RETURNS varchar(800)
BEGIN
	DECLARE @sReturn varchar(800)
	
	Set @sReturn = 'Все размещения'
	
	SELECT @sReturn = AC_NAME from Accmdmentype WITH(NOLOCK)
	inner join HotelRooms WITH(NOLOCK) on AC_KEY=HR_ACKEY
	WHERE HR_KEY=@nHRKey
	
	return @sReturn
END
GO

GRANT EXEC ON [dbo].[fn_GetAccmdNameByHRKey] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetAccmdNameByHRKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetHRKeyByRCKey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetHRKeyByRCKey]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetHRKeyByRCKey]
GO

CREATE FUNCTION [dbo].[fn_GetHRKeyByRCKey]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nRCKey INT
) RETURNS INT
BEGIN
	DECLARE @nHRKey int
	
	Set @nHRKey = 0
	
	If @nRCKey <> 0
	begin	
		SELECT @nHRKey = RC_Key from dbo.RoomsCategory
		inner join HotelRooms on HR_RCKEY=RC_KEY
		where RC_KEY=@nRCKey
	end
	return @nHRKey
END
GO

GRANT EXEC ON [dbo].[fn_GetHRKeyByRCKey] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetHRKeyByRCKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetHRKeyByRCKeyAndRMKey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetHRKeyByRCKeyAndRMKey]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetHRKeyByRCKeyAndRMKey]
GO

CREATE FUNCTION [dbo].[fn_GetHRKeyByRCKeyAndRMKey]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nRCKey INT,
	@nRMKey INT
) RETURNS INT
BEGIN
	DECLARE @nHRKey int
	
	Set @nHRKey = 0
	
	If (@nRCKey <> 0 AND @nRMKey <> 0)
	begin	
		SELECT @nHRKey = HR_Key from HotelRooms
		where HR_RCKEY=@nRCKey
		and HR_RMKEY=@nRMKey
	end
	return @nHRKey
END
GO

GRANT EXEC ON [dbo].[fn_GetHRKeyByRCKeyAndRMKey] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetHRKeyByRCKeyAndRMKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetHRKeyByRMKey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetHRKeyByRMKey]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetHRKeyByRMKey]
GO

CREATE FUNCTION [dbo].[fn_GetHRKeyByRMKey]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nRMKey INT
) RETURNS INT
BEGIN
	DECLARE @nHRKey int
	
	Set @nHRKey = 0
	
	If @nRMKey <> 0
	begin	
		SELECT @nHRKey = RM_Key from dbo.Rooms
		inner join HotelRooms on HR_RCKEY=RM_KEY
		where RM_KEY=@nRMKey
	end
	return @nHRKey
END
GO

GRANT EXEC ON [dbo].[fn_GetHRKeyByRMKey] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetHRKeyByRMKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetRCNameByHRKey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetRCKeyByHRKey]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetRCKeyByHRKey]
GO

CREATE FUNCTION [dbo].[fn_GetRCKeyByHRKey]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nHRKey INT
) RETURNS INT
BEGIN
	DECLARE @nRCKey int
	
	Set @nRCKey = 0
	
	If @nHRKey <> 0
	begin	
		SELECT @nRCKey = RC_Key from dbo.RoomsCategory
		inner join HotelRooms on HR_RCKEY=RC_KEY
		where HR_KEY=@nHRKey
	end
	return @nRCKey
END
GO

GRANT EXEC ON [dbo].[fn_GetRCKeyByHRKey] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetRCNameByHRKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetRMNameByHRKey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetRMKeyByHRKey]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetRMKeyByHRKey]
GO

CREATE FUNCTION [dbo].[fn_GetRMKeyByHRKey]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nHRKey INT
) RETURNS INT
BEGIN
	DECLARE @nRMKey int
	
	Set @nRMKey = 0
	
	If @nHRKey <> 0
	begin	
		SELECT @nRMKey = RM_Key from dbo.Rooms
		inner join HotelRooms on HR_RMKEY=RM_KEY
		where HR_KEY=@nHRKey
	end
	return @nRMKey
END
GO

GRANT EXEC ON [dbo].[fn_GetRMKeyByHRKey] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetRMNameByHRKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetRoomCtgrName.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetRoomCtgrName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetRoomCtgrName]
GO

CREATE FUNCTION [dbo].[fn_GetRoomCtgrName]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nCategory INT
) RETURNS varchar(800)
BEGIN
	DECLARE @sReturn varchar(800)
	
	If @nCategory = 0
	begin
		Set @sReturn = 'Любая категория'
	end
	else
	begin	
		Set @sReturn = 'Неизвестно !!!'
		SELECT @sReturn = RC_Name from dbo.RoomsCategory where RC_Key=@nCategory
	end
	return @sReturn
END
GO

GRANT EXEC ON [dbo].[fn_GetRoomCtgrName] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetRoomCtgrName.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetRoomName.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetRoomName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetRoomName]
GO

CREATE FUNCTION [dbo].[fn_GetRoomName]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nRMKey INT
) RETURNS varchar(800)
BEGIN
	DECLARE @sReturn varchar(800)
	
	Set @sReturn = 'Все типы номеров'

	begin	
		SELECT @sReturn = RM_Name from dbo.Rooms where RM_Key=@nRMKey
	end
	return @sReturn
END
GO

GRANT EXEC ON [dbo].[fn_GetRoomName] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetRoomName.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetSvCode1Name.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetSvCode1Name]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetSvCode1Name]
GO

CREATE FUNCTION [dbo].[fn_GetSvCode1Name]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nSvKey INT,
	@nCode1 INT
) RETURNS varchar(50)
BEGIN
DECLARE
	@sTitle varchar(50),
	@sName varchar(50),
	@sTitleLat varchar(50),
	@sNameLat varchar(50),
	@nRoom INT,
	@nCategory INT,
	@nAccmdmentype INT,
	@sNameCategory VARCHAR(800),
	@sNameCategoryLat VARCHAR(800),
	@nHrMain INT,
	@nAgeFrom INT,
	@nAgeTo INT,
	@sAcCode VARCHAR(800),
	@sAcCodeLat VARCHAR(800),
	@sTmp VARCHAR(800),
	@bTmp INT,

	@TYPE_FLIGHT INT, 
	@TYPE_TRANSFER INT,
	@TYPE_HOTEL INT,
	@TYPE_EXCUR INT,
	@TYPE_VISA INT,
	@TYPE_INSUR INT,
	@TYPE_SHIP INT,
	@TYPE_HOTELADDSRV INT,
	@TYPE_SHIPADDSRV INT
	
	Set @TYPE_FLIGHT = 1
	Set @TYPE_TRANSFER = 2
	Set @TYPE_HOTEL = 3
	Set @TYPE_EXCUR = 4
	Set @TYPE_VISA = 5
	Set @TYPE_INSUR = 6
	Set @TYPE_SHIP = 7
	Set @TYPE_HOTELADDSRV = 8
	Set @TYPE_SHIPADDSRV = 9
		
	Set @sName = ''

	IF @nSvKey = @TYPE_FLIGHT
	BEGIN
		SET @sTitle = 'Тариф'
		SET @sName = 'Любой'
		SET @sTitleLat = 'Tariff'
		SET @sNameLat = 'Any'

		IF EXISTS(SELECT * FROM dbo.AirService WHERE AS_Key = @nCode1) and (@nCode1 <> -1)
			SELECT	@sName = IsNull(AS_Code, '') + '-' + AS_NameRus,
				@sNameLat = IsNull(AS_Code, '') + '-' + IsNull(AS_NameLat, AS_NameRus)
			FROM 	dbo.AirService 
			WHERE	AS_Key = @nCode1
	END
	ELSE
	IF (@nSvKey = @TYPE_TRANSFER) or (@nSvKey = @TYPE_EXCUR)
	BEGIN
		SET @sTitle = 'Транспорт'
		SET @sName = 'Любой'
		SET @sTitleLat = 'Transport'
		SET @sNameLat = 'Any'
		
		IF EXISTS(SELECT * FROM dbo.Transport WHERE TR_Key = @nCode1)
			SELECT 	@sName = TR_Name + ',' + CAST(IsNull(TR_NMen, 0) AS varchar(5)),
				@sNameLat = IsNull(TR_NameLat, TR_Name) + ',' + CAST(IsNull(TR_NMen, 0) AS varchar(5))
			FROM 	dbo.Transport 
			WHERE 	TR_Key = @nCode1
	END
	ELSE
	IF (@nSvKey = @TYPE_HOTEL OR @nSvKey = @TYPE_HOTELADDSRV)
	BEGIN
		IF @nCode1 = 0
			BEGIN
				SET @sName = 'Все категории'
			END
		ELSE	
			BEGIN
				SELECT @nCategory=HR_RCKEY FROM HotelRooms WITH(NOLOCK) WHERE HR_KEY=@nCode1
				
				If @nCategory = 0
				begin
					Set @sNameCategory = 'Все категории'
				end
				else
				begin	
					Set @sNameCategory = 'Неизвестная категория'
					SELECT @sNameCategory = RC_Name from dbo.RoomsCategory where RC_Key=@nCategory
				end

				Set @sName = @sNameCategory
			END
			
			if isnull((select SS_ParmValue from SystemSettings where SS_ParmName = 'CartAccmdMenTypeView'), 0) = 0
			begin
				SELECT @nHrMain = IsNull(HR_Main, 0), @nAgeFrom = IsNull(HR_AgeFrom, 0), @nAgeTo = IsNull(HR_AgeTo, 0), @sAcCode = IsNull(AC_Name, ''),  @sAcCodeLat = IsNull(AC_NameLat, '') FROM dbo.HotelRooms, dbo.AccmdMenType WHERE (HR_Key = @nCode1) AND (HR_AcKey = AC_Key)				
			end
			else
			begin
				SELECT @nHrMain = IsNull(HR_Main, 0), @nAgeFrom = IsNull(HR_AgeFrom, 0), @nAgeTo = IsNull(HR_AgeTo, 0), @sAcCode = IsNull(AC_Code, '') FROM dbo.HotelRooms, dbo.AccmdMenType WHERE (HR_Key = @nCode1) AND (HR_AcKey = AC_Key)
			end
	END
	ELSE
	if (@nSvKey = @TYPE_SHIPADDSRV or @nSvKey = @TYPE_SHIP)
	BEGIN
		IF @nCode1 = 0
		BEGIN
			Set @sTitle = 'Каюта'
			Set @sName = 'Все каюты'
			SET @sTitleLat = 'Cabin'
			SET @sNameLat = 'All cabins'
		END
		ELSE
		BEGIN
			SET @sTitle = 'Каюта'
			SET @sName = 'Любая'
			SET @sTitleLat = 'Cabin'
			SET @sNameLat = 'Any'

			IF EXISTS( SELECT * FROM dbo.Cabine WHERE CB_Key = @nCode1 )
				SELECT	@sName = CB_Code + ',' + CB_Category + ',' + CB_Name,
					@sNameLat = CB_Code + ',' + CB_Category + ',' + ISNULL(CB_NameLat,CB_Name)
				FROM dbo.Cabine 
				WHERE CB_Key = @nCode1
		END
	END
	ELSE if (@nSvKey = @TYPE_VISA)
	BEGIN
		Select @bTmp = SV_IsSubCode1 from [Service] with(nolock) where SV_Key=@TYPE_VISA
	
		IF @bTmp > 0
		BEGIN
			SET @sTitle = 'Доп.описание'
			SET @sName = 'Любое'
			SET @sTitleLat = 'Add.description'
			SET @sNameLat = 'Any'
			
			IF EXISTS(SELECT * FROM dbo.AddDescript1 WHERE A1_Key = @nCode1)
				SELECT	@sName = A1_Name + 
						(CASE 
							WHEN ( LEN(IsNull(A1_Code, '')) > 0 ) THEN (','+ A1_Code) 
							ELSE ('') 
						END), 
					@sNameLat = ISNULL(A1_NameLat,A1_Name) + 
						(CASE 
							WHEN ( LEN(IsNull(A1_Code, '')) > 0 ) THEN (','+ A1_Code) 
							ELSE ('') 
						END)
				FROM dbo.AddDescript1 
				WHERE A1_Key = @nCode1
		END
		ELSE
		BEGIN
			SET @sTitle = ''
			SET @sTitleLat = ''
		END
	END
	ELSE
	BEGIN
		Select @bTmp = SV_IsSubCode1 from [Service] with(nolock) where SV_Key=@nSvKey
	
		IF @bTmp > 0
		BEGIN
			SET @sTitle = 'Доп.описание'
			SET @sName = 'Любое'
			SET @sTitleLat = 'Add.description'
			SET @sNameLat = 'Any'
			
			IF EXISTS(SELECT * FROM dbo.AddDescript1 WHERE A1_Key = @nCode1)
				SELECT	@sName = A1_Name + 
						(CASE 
							WHEN ( LEN(IsNull(A1_Code, '')) > 0 ) THEN (','+ A1_Code) 
							ELSE ('') 
						END), 
					@sNameLat = ISNULL(A1_NameLat,A1_Name) + 
						(CASE 
							WHEN ( LEN(IsNull(A1_Code, '')) > 0 ) THEN (','+ A1_Code) 
							ELSE ('') 
						END)
				FROM dbo.AddDescript1 
				WHERE A1_Key = @nCode1
		END
		ELSE
		BEGIN
			SET @sName = 'Без доп.описания'
			SET @sTitle = ''
			SET @sTitleLat = ''
		END
	END

	return @sName
END
GO

GRANT EXEC ON [dbo].[fn_GetSvCode1Name] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetSvCode1Name.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetSvCode2Name.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetSvCode2Name]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetSvCode2Name]
GO

CREATE FUNCTION [dbo].[fn_GetSvCode2Name]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nSvKey INT,
	@nCode2 INT
) RETURNS varchar(50)
BEGIN
	DECLARE
	@sResult varchar(50),
	@sResultLat varchar(50),
	@nMain INT,
	@nAgeFrom INT,
	@nAgeTo INT,
	
	@TYPE_FLIGHT INT, 
	@TYPE_TRANSFER INT,
	@TYPE_HOTEL INT,
	@TYPE_EXCUR INT,
	@TYPE_VISA INT,
	@TYPE_INSUR INT,
	@TYPE_SHIP INT,
	@TYPE_HOTELADDSRV INT,
	@TYPE_SHIPADDSRV INT,
	@sTempString VARCHAR(800),
	@nTempNumber INT
	
	Set @TYPE_FLIGHT = 1
	Set @TYPE_TRANSFER = 2
	Set @TYPE_HOTEL = 3
	Set @TYPE_EXCUR = 4
	Set @TYPE_VISA = 5
	Set @TYPE_INSUR = 6
	Set @TYPE_SHIP = 7
	Set @TYPE_HOTELADDSRV = 8
	Set @TYPE_SHIPADDSRV = 9
	
	Set @sResult = ''
	Set @sResultLat = ''
	
	-- Проживание
	IF @nSvKey = @TYPE_HOTEL 
		BEGIN
			IF EXISTS(SELECT * FROM	dbo.Pansion WHERE PN_Key = @nCode2)
				SELECT 	@sResult = IsNull(PN_Code, '') + ' ' + PN_Name,
					@sResultLat = IsNull(PN_Code, '') + ' ' + IsNull(PN_NameLat, PN_Name)
				FROM 	dbo.Pansion 
				WHERE 	PN_Key = @nCode2
		END	
	ELSE
	-- Круиз
	IF @nSvKey = @TYPE_SHIP
	BEGIN
		IF EXISTS(SELECT * FROM dbo.AccmdMenType WHERE AC_Key = @nCode2)
			SELECT  @sResult = IsNull(AC_Code, ''), 
				@sResultLat = IsNull(AC_Code, ''), 
				@nMain = IsNull(AC_Main, 0), 
				@nAgeFrom = IsNull(AC_AgeFrom, 0), 
				@nAgeTo = IsNull(AC_AgeTo, 0) 
			FROM 	dbo.AccmdMenType 
			WHERE 	AC_Key = @nCode2
	END
	ELSE
	-- Для всех остальных случаев
	BEGIN		
		--EXEC dbo.GetSvListParm @nSvKey, 'CODE2', @nTempNumber output
			
		DECLARE @bIsCode2 INT

		Select @bIsCode2 = SV_IsSubCode2 from dbo.Service where SV_Key=@nSvKey

		If @bIsCode2 <= 0
			Set @bIsCode2 = 0
		
		Set @nTempNumber = @bIsCode2
		
		IF @nTempNumber > 0
		BEGIN
			IF EXISTS(SELECT * FROM dbo.AddDescript2 WHERE A2_Key = @nCode2)
				SELECT	@sResult = A2_Name + (case when LEN(A2_Code) > 0 then ( ',' + IsNull(A2_Code, '') ) else '' end),
					@sResultLat = IsNull(A2_NameLat, A2_Name) + (case when LEN(A2_Code) > 0 then ( ',' + IsNull(A2_Code, '') ) else '' end)
				FROM dbo.AddDescript2 
				WHERE A2_Key = @nCode2
		END
	END
	
	IF (@nSvKey = @TYPE_SHIP) AND (@nCode2 > 0)
	BEGIN
		IF (@nMain > 0)
		BEGIN
			SET @sResult = @sResult + ',Осн'
			SET @sResultLat = @sResultLat + ',Main'
		END
		ELSE
		BEGIN
			SET @sResult = @sResult + ',доп'
			SET @sResultLat = @sResultLat + ',ex.b'
			IF @nAgeFrom >= 0
			BEGIN
				SET @sTempString = '(' + CAST( @nAgeFrom as varchar(5) ) + '-' +  CAST( @nAgeTo as varchar(5) ) + ')'
				SET @sResult = @sResult + @sTempString
				SET @sResultLat = @sResultLat + @sTempString
			END
		END
	END
	
	return @sResult
END
GO

GRANT EXEC ON [dbo].[fn_GetSvCode2Name] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetSvCode2Name.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetSVCodeName.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetSVCodeName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_GetSVCodeName]
GO

CREATE FUNCTION [dbo].[fn_GetSVCodeName]
(
--<VERSION>9.2.20.0</VERSION>
--<DATE>2014-09-05</DATE>
--Используется в экране PacketCostsCopying
	@nSVKey int,
	@nCode int
)
RETURNS varchar(50)
BEGIN
	DECLARE @sText varchar(50),@sTextLat varchar(50)

	IF @nSVKey=1
		Select @sText=CH_AirLineCode + ' ' + CH_Flight from Charter where CH_Key = @nCode
	Else IF @nSVKey=2
		Select @sText=TF_Name, @sTextLat=ISNULL(TF_NameLat,TF_Name) from Transfer where TF_Key = @nCode
	Else IF (@nSVKey=3 or @nSVKey=8)
		Select @sText=HD_Name + '-' + HD_Stars, @sTextLat=ISNULL(HD_NameLat,HD_Name) + '-' + HD_Stars from HotelDictionary where HD_Key = @nCode
	Else IF @nSVKey=4
		Select @sText=ED_Name, @sTextLat=ISNULL(ED_NameLat,ED_Name) from ExcurDictionary where ED_Key = @nCode
	Else IF (@nSVKey=7 or @nSVKey=9)
		Select @sText=SH_Name + '-' + SH_Stars, @sTextLat=SH_Name + '-' + SH_Stars from Ship where SH_Key = @nCode
	Else
		Select @sText=SL_Name,@sTextLat=SL_NameLat from ServiceList where SL_Key = @nCode
	return @sText
END
GO

GRANT EXEC ON [dbo].[fn_GetSVCodeName] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetSVCodeName.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetPricePage_Rename.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetPricePage]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetPricePage]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetPricePage]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetPricePage]
GO

CREATE PROCEDURE [dbo].[GetPricePage]
(
--<VERSION>2009.2.18</VERSION>
--<DATE>2013-02-04</DATE>
     @TurKey   int,
     @MinID     int,
     @SizePage     int
)
AS

DECLARE @TP_PRICES TABLE(xTP_Key [int] NOT NULL PRIMARY KEY CLUSTERED, xTP_TIKEY [int])

--tkachuk 11195
--если приходит минимальный ключ = -1, возвращаем все цены без фильтрации по ключу
if @MinID != -1
begin
	insert into @TP_PRICES(xTP_Key,xTP_TIKEY)
	SELECT  TOP (@SizePage) TP_KEY, TP_TIKEY
	FROM TP_PRICES WITH(NOLOCK)
	WHERE  TP_TOKEY = @TurKey
	and TP_KEY > @MinID
	ORDER BY TP_KEY

end

else

begin
	insert into @TP_PRICES(xTP_Key,xTP_TIKEY)
	SELECT  TOP (@SizePage) TP_KEY, TP_TIKEY
	FROM TP_PRICES WITH(NOLOCK)
	WHERE  TP_TOKEY = @TurKey
	ORDER BY TP_KEY

end



--get output results

select * from TP_PRICES WITH(NOLOCK)

WHERE TP_Key IN (SELECT xTP_Key FROM @TP_PRICES)

order by TP_KEY



-- Получаем все ServiceSet (варианты набора услуг).

SELECT DISTINCT xTP_TIKEY AS 'TP_TIKey' FROM @TP_PRICES



--Console.WriteLine("||  Получаем все связи услуг");

SELECT * FROM TP_SERVICELISTS WITH(NOLOCK)

WHERE TL_TIKEY in (SELECT DISTINCT xTP_TIKEY FROM @TP_PRICES)

ORDER BY TL_TIKEY

GO
GRANT EXECUTE ON [dbo].[GetPricePage] TO Public
GO

/*********************************************************************/
/* end sp_GetPricePage_Rename.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetPricePage_VP_Rename.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[sp_GetPricePage_VP]') AND xtype in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_GetPricePage_VP]
GO

IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[GetPricePage_VP]') AND xtype in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetPricePage_VP]
GO


--<VERSION>9.2.19.1</VERSION>
--<DATE>2013-04-24</DATE>

-- Версия sp_GetPricePage для динамического ценообразования
CREATE PROCEDURE [dbo].[GetPricePage_VP]
     @TourKey		int,			-- ключ тура (из таблицы TP_Tours)
     @calcKeyFrom	bigint,			-- начальный ключ calculatingKey
     @calcKeyTo		bigint			-- конечный ключ calculatingKey
AS

create table #TP_PRICES
	(
		xTP_Key [int] NOT NULL PRIMARY KEY CLUSTERED, 
		xTP_TIKEY [int]
	)

INSERT INTO #TP_PRICES(xTP_Key,xTP_TIKEY) 
SELECT TP_KEY, TP_TIKEY  
FROM TP_PRICES WITH(NOLOCK)
WHERE  TP_TOKEY = @TourKey 
   and TP_CalculatingKey between @calcKeyFrom and @calcKeyTo
ORDER BY TP_KEY
option(maxdop 10);

--get output results
SELECT * 
FROM TP_PRICES WITH(NOLOCK) 
WHERE TP_Key IN (SELECT xTP_Key FROM #TP_PRICES)
ORDER BY TP_KEY
option(maxdop 10);

-- Получаем все ServiceSet (варианты набора услуг).
SELECT DISTINCT xTP_TIKEY AS 'TP_TIKey' FROM #TP_PRICES
option(maxdop 10);

--Console.WriteLine("||  Получаем все связи услуг");
SELECT * FROM TP_SERVICELISTS WITH(NOLOCK)
WHERE TL_TIKEY in (SELECT DISTINCT xTP_TIKEY FROM #TP_PRICES)
ORDER BY TL_TIKEY
option(maxdop 10);

-- Получаем список удаленных цен
SELECT DISTINCT TPD_TPKey, TPD_TOKey, TPD_DateBegin, TPD_DateBegin, TPD_Gross, TPD_TIKey FROM TP_PricesDeleted WITH(NOLOCK)
WHERE TPD_TOKey = @TourKey
	and TPD_CalculatingKey between @calcKeyFrom and @calcKeyTo
option(maxdop 10);

GO

GRANT EXECUTE ON [dbo].[GetPricePage_VP] TO Public
GO
/*********************************************************************/
/* end sp_GetPricePage_VP_Rename.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetServiceVariants.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwGetServiceVariants')
	drop proc dbo.mwGetServiceVariants
go

--<VERSION>9.2.20.21</VERSION>
--<DATE>2014-08-25</DATE>

create procedure [dbo].[mwGetServiceVariants]
	@serviceDays int,
	@svKey	int,
	@pkKey int,
	@dateBegin varchar(10),
	@tourNDays smallint,
	@cityFromKey	int,
	@cityToKey	int,
	@additionalFilter varchar(1024),
	@tourKey int,
	@showCalculatedCostsOnly int
as
begin
	
	if (isnull(@serviceDays, 0)<=0 and @svKey != 3 and @svKey != 8)
		Set @serviceDays = 1
		
	-- 7693 neupokoev 29.08.2012
	-- Заточка под ДЦ
	declare @selectClause varchar(300)
	declare @fromClause varchar(300)
	declare @whereClause varchar(6000)
	declare @isNewReCalculatePrice bit

	-- Проверка на режим динамического ценообразования
	set @isNewReCalculatePrice = 0
	if (exists( select top 1 1 from SystemSettings with(nolock) where SS_ParmName = 'NewReCalculatePrice' and SS_ParmValue = 1))
		set @isNewReCalculatePrice = 1
	
	if (@isNewReCalculatePrice = 0)
	begin
		-- CRM04241L4F2 20.03.2012 kolbeshkin сделал distinct по CS_ID, т.к. были случаи дублирования одних и тех же записей в результирующем наборе
		set	@selectClause = ' SELECT CS_Code, CS_SubCode1, CS_SubCode2, CS_PrKey, CS_PkKey, CS_Profit, CS_Type, CS_Discount, CS_Creator, CS_Rate, CS_Cost 
		from costs
		where CS_ID in (select distinct cs1.cs_id '
		set	@fromClause   = ' FROM COSTS cs1 WITH(NOLOCK) '
		set	@whereClause  = ''
	end
	else
	begin 
		set	@selectClause = ' SELECT cs1.CS_Code, cs1.CS_SubCode1, cs1.CS_SubCode2, cs1.CS_PrKey, cs1.CS_PkKey, cs1.CS_Profit, cs1.CS_Type, cs1.CS_Discount, cs1.CS_Creator, cs1.CS_Rate, cs1.CS_Cost, CO_DateActive '
		set	@fromClause   = ' FROM COSTS cs1 WITH(NOLOCK) INNER JOIN COSTOFFERS WITH(NOLOCK) ON cs1.CS_Coid = CO_Id INNER JOIN Seasons WITH(NOLOCK) ON CO_SeasonId = SN_Id'
		set	@whereClause  = ' CO_State = 1 AND GETDATE() BETWEEN ISNULL(CO_SaleDateBeg, ''1900-01-01'') AND ISNULL(CO_SaleDateEnd, ''2050-01-01'') AND ISNULL(SN_IsActive, 0) = 1 AND '
	end
	
	set		@additionalFilter = replace(@additionalFilter, 'CS_', 'cs1.CS_')
		
	declare @orderClause varchar(100)
		set @orderClause  = 'CS_long'
	
	--MEG00027493 Paul G 15.07.2010
	if (@showCalculatedCostsOnly = 1)
	begin
		set @whereClause = @whereClause +
			'EXISTS(SELECT 1 FROM TP_SERVICES WITH(NOLOCK) WHERE TS_CODE=cs1.CS_CODE 
				AND TS_SVKEY=cs1.CS_SVKEY 
				AND TS_SUBCODE1=cs1.CS_SUBCODE1 
				AND TS_SUBCODE2=cs1.CS_SUBCODE2 
				AND TS_OPPARTNERKEY=cs1.CS_PRKEY
				AND TS_OPPACKETKEY=cs1.CS_PKKEY
				AND TS_TOKEY=(SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE TO_TRKEY='+ convert(varchar(50), @tourKey) +')) AND 
			'
	end
	
	set @whereClause = @whereClause + ' cs1.CS_SVKEY = ' + cast(@svKey as varchar)
	set @whereClause = @whereClause + ' AND cs1.CS_PKKEY = ' + cast(@pkKey as varchar)
	
	-- 8233 tfs neupokoev 
	-- При подборе вариантов не учитывались даты начала и окончания продаж
	if (@isNewReCalculatePrice = 0)
		set @whereClause = @whereClause + ' AND ' + 'GETDATE()' + ' BETWEEN ISNULL(cs1.CS_DATESELLBEG, ''1900-01-01'') AND ISNULL(cs1.CS_DATESELLEND, ''9000-01-01'') '
	
	set @whereClause = @whereClause + ' AND ''' + @dateBegin + ''' BETWEEN ISNULL(cs1.CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(cs1.CS_CHECKINDATEEND, ''9000-01-01'') ' + @additionalFilter
	
	if (@svKey=1)
	begin			
		set @whereClause = @whereClause + ' AND ' + cast(@tourNDays as varchar) + ' between isnull(cs1.CS_longmin, -1) and isnull(cs1.CS_LONG, 10000) '-- MEG00029229 Paul G 13.10.2010
				
		set @whereClause = @whereClause + ' AND EXISTS (SELECT CH_KEY FROM CHARTER WITH(NOLOCK)' 
										+ ' WHERE CH_KEY = cs1.CS_CODE AND CH_CITYKEYFROM = ' + cast(@cityFromKey as varchar) + ' AND CH_CITYKEYTO = ' + cast(@cityToKey as varchar)+')'
		-- Filter on day of week
		set @whereClause = @whereClause + ' AND (cs1.CS_WEEK is null or cs1.CS_WEEK = '''' or cs1.CS_WEEK like dbo.GetWeekDays(''' + @dateBegin + ''',''' + @dateBegin + '''))'
		-- Filter on CHECKIN DATE		
	end
	else 
	begin
		if (@serviceDays > 1)
		begin			
			-- buryak 2014.08.25 - Task 27453 : CRM-07178-V7X1 - Данко - множественное отображение услуг страховка в корзине
			-- Со "Спорным моментом"(см ниже) в расширенной корзине подбиралось 5 цен для дополнительной услуги-страховки, хотя по продолжительности тура должна была подходить лишь одна.
			-- Надо бы этот момент просто удалить, оставив between для продолжительности, но никто не знает для чего он делался (а он там очень давно). Решено оставить его только для квотируемых услуг, чтобы ничего не заломать.
			declare @isQuoted smallint
			select @isQuoted = SV_QUOTED from [Service] where SV_KEY = @svKey
			if(@isQuoted = 1)
			begin
				-- Спорный момент, но иначе не работает вариант, когда изначально берется цена с cs_long < @serviceDays, а потом добивается другими квотами с конца
				--set @whereClause = @whereClause + ' AND ' + cast(@serviceDays as varchar) + ' between isnull(cs1.CS_longmin, -1) and isnull(cs1.CS_long, 10000)'
				set @whereClause = @whereClause + ' AND ' + cast(@serviceDays as varchar) + ' >= isnull(cs1.CS_longmin, -1)'
			end
			else begin
				set @whereClause = @whereClause + ' AND ' + cast(@serviceDays as varchar) + ' between isnull(cs1.CS_longmin, -1) and isnull(cs1.CS_long, 10000)'
			end
			
			-- Exclude services that not have cost at last service day
			set @fromClause = @fromClause + ' INNER JOIN COSTS cs2 WITH(NOLOCK) ON cs1.CS_CODE = cs2.CS_CODE AND cs1.CS_SUBCODE1 = cs2.CS_SUBCODE1 AND cs1.CS_SUBCODE2 = cs2.CS_SUBCODE2'
			set @whereClause = @whereClause + ' AND ' + replace(@whereClause, 'cs1.', 'cs2.')
			set @whereClause = @whereClause + ' AND ISNULL(cs2.CS_DATE,    ''1900-01-01'') <= ''' + cast(dateadd(day, @serviceDays - 1, cast(@dateBegin as datetime)) as varchar) + ''''
			set @whereClause = @whereClause + ' AND ISNULL(cs2.CS_DATEEND, ''9000-01-01'') >= ''' + cast(DATEADD(day, @serviceDays - 1, cast(@dateBegin as datetime)) as varchar) + ''''
						
			if (len(@orderClause) > 0)
				set @orderClause = @orderClause + ', '
			set @orderClause = @orderClause + 'CS_UPDDATE DESC'
		end
		else
		begin				
			set @whereClause = @whereClause + ' AND ' + cast(@serviceDays as varchar) + ' between isnull(cs1.CS_longmin, -1) and isnull(cs1.CS_long, 10000)'
		end
		-- 7443 tfs neupokoev 22.08.2012
		-- Фильтруем цены по дням неделии у других услуг тоже
	set @whereClause = @whereClause + ' AND (cs1.CS_WEEK is null or cs1.CS_WEEK = '''' or cs1.CS_WEEK like dbo.GetWeekDays(''' + @dateBegin + ''',''' + @dateBegin + '''))'	
	end	
	
	set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATE,    ''1900-01-01'') <= ''' + @dateBegin + ''''
	set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATEEND, ''9000-01-01'') >= ''' + @dateBegin + ''''

	-- neupokoev 29.08.2012
	-- Заточка под ДЦ
	if (@isNewReCalculatePrice = 0)
		begin
			exec (@selectClause + @fromClause + ' WHERE ' + @whereClause + ') ORDER BY '+ @orderClause)
		end
	else
		begin
			exec ('WITH SERVICEINFO AS (' + 
					@selectClause + @fromClause + ' WHERE ' + @whereClause +
					') 
					SELECT * FROM SERVICEINFO AS si1
						WHERE si1.CO_DateActive = 
							(
								SELECT MAX(si2.CO_DateActive) 
								FROM SERVICEINFO AS si2 
								WHERE si1.CS_Code = si2.CS_Code and si1.CS_SubCode1 = si2.CS_SubCode1 and 
								      si1.CS_SubCode2 = si2.cs_SubCode2 and si1.CS_PRKey = si2.CS_PRKey
							)')
		end	
end
go

grant exec on dbo.mwGetServiceVariants to public
go

/*********************************************************************/
/* end sp_mwGetServiceVariants.sql */
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
-- =====================   Обновление версии БД. 9.2.20.21 - номер версии, 2014-09-05 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.21', st_moduledate = convert(datetime, '2014-09-05', 120),  st_financeversion = '9.2.20.21', st_financedate = convert(datetime, '2014-09-05', 120)
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
	SET SS_ParmValue='2014-09-05' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO