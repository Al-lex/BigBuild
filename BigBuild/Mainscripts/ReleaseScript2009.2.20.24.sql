/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 28.11.2014 15:28 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.23'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersionFull nvarchar(128) = '9.2.20.24'
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

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '(2014-11-26)_Create_Debug_Indexes.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin (2014-11-26)_Create_Debug_Indexes.sql */
/*********************************************************************/
if not exists (select * from syscolumns where name='db_key' and id=object_id('dbo.Debug'))
begin
	alter table dbo.Debug add db_key int not null identity(1,1) primary key
end
go

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Debug]') AND name = N'IX_MarginMigrate')
begin
	CREATE NONCLUSTERED INDEX [IX_MarginMigrate]
	ON [dbo].[Debug] ([db_Mod])
	INCLUDE ([db_n1])
end
GO

/*********************************************************************/
/* end (2014-11-26)_Create_Debug_Indexes.sql */
/*********************************************************************/
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '(2014-11-26)_Create_Debug_Indexes.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '(2014.11.20)_Insert_ObjectAliases.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin (2014.11.20)_Insert_ObjectAliases.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_ID = 300004)
BEGIN
	INSERT INTO ObjectAliases (OA_ID, OA_ALIAS, OA_NAME, OA_NAMELAT, OA_TABLEID)
	VALUES (300004, 'WriteOffRepresentativeBonusesToPrice', 'Сумма, списанная со счёта бонусами представителя', 'Write-off representative bonuses price', 0)
END
ELSE
BEGIN
	UPDATE ObjectAliases 
	set OA_ALIAS = 'WriteOffRepresentativeBonusesToPrice', OA_NAME = 'Сумма, списанная со счёта бонусами представителя', OA_NAMELAT = 'Write-off representative bonuses price'
	where OA_ID = 300004
END
GO

IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_ID = 300006)
BEGIN
	INSERT INTO ObjectAliases (OA_ID, OA_ALIAS, OA_NAME, OA_NAMELAT, OA_TABLEID)
	VALUES (300006, 'WriteOffRepresentativeBonusesCount', 'Количество списанных баллов со счёта представителя', 'Write-off representative bonuses count', 0)
END
ELSE
BEGIN
	UPDATE ObjectAliases 
	set OA_ALIAS = 'WriteOffRepresentativeBonusesCount', OA_NAME = 'Количество списанных баллов со счёта представителя', OA_NAMELAT = 'Write-off representative bonuses count'
	where OA_ID = 300006
END
GO

IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_ID = 300009)
BEGIN
	INSERT INTO ObjectAliases (OA_ID, OA_ALIAS, OA_NAME, OA_NAMELAT, OA_TABLEID)
	VALUES (300009, 'WriteOffBonusesByAgencyKey', 'Ключ агентства', 'Write-off partner key', 0)
END
GO


IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_ID = 300010)
BEGIN
	INSERT INTO ObjectAliases (OA_ID, OA_ALIAS, OA_NAME, OA_NAMELAT, OA_TABLEID)
	VALUES (300010, 'WriteOffAgencyBonusesCount', 'Количество списанных баллов с агентского счёта', 'Write-off partner bonuses count', 0)
END
GO

IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_ID = 300011)
BEGIN
	INSERT INTO ObjectAliases (OA_ID, OA_ALIAS, OA_NAME, OA_NAMELAT, OA_TABLEID)
	VALUES (300011, 'WriteOffAgencyBonusesToPrice', 'Сумма, списанная со счёта бонусами агентства', 'Write-off partner bonuses price', 0)
END
GO
/*********************************************************************/
/* end (2014.11.20)_Insert_ObjectAliases.sql */
/*********************************************************************/
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), '(2014.11.20)_Insert_ObjectAliases.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'fn_mwCheckQuotasHotelsOnPeriod.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
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
				AND qt_date = @currentDate
				AND (qt_type <> @qdType
					or (qt_qoid = @qoId and qt_long <> @qpLong)
					or (qt_qoid = @qoId and qt_agent <> @qdAgentKey)
					or qt_qoid <> @qoId)))
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'fn_mwCheckQuotasHotelsOnPeriod.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'job_mwRemoveDeletedNightly.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin job_mwRemoveDeletedNightly.sql */
/*********************************************************************/
declare @errorMessage nvarchar(max)
declare @serverVersion nvarchar(128)

if (dbo.mwReplIsSubscriber() = 1)
begin
	select @serverVersion = cast(serverproperty('edition') as nvarchar)
	if (@serverVersion like '%express%')
	begin
		GOTO invalidServerVersion
	end
end

declare @dbName nvarchar(128), @jobname nvarchar(128)
set @jobname = DB_NAME() + '_mwRemoveDeletedNightly'
set @dbName = DB_NAME()

if (dbo.mwReplIsPublisher() <> 1)
begin
	IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = @jobname)
		EXEC msdb.dbo.sp_delete_job @job_name = @jobname, @delete_unused_schedule=1
end

if (dbo.mwReplIsPublisher() <> 1)
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
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name = @jobname, 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'Очищает рассчитанные цены на прошедшие даты, перестраивает индексы в поисковых таблицах.', 
			@category_name=N'[Uncategorized (Local)]', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [mwRemoveDeleted]    Script Date: 15.10.2013 17:02:15 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'mwRemoveDeleted', 
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
exec dbo.mwRemoveDeleted', 
			@database_name=@dbName, 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'mwShedule', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20100524, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959, 
			@schedule_uid=N'106a4084-5c98-487f-8120-a2bb3726dac6'

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	COMMIT TRANSACTION

	GOTO EndSave
	QuitWithRollback:
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
end

	GOTO endsave

invalidServerVersion:
			set @errorMessage = 'Не удалось создать стандартное задание (job) на SQL-сервере. 
Либо редакция SQL-сервера не поддерживает установку заданий, либо не включен SQL Server Agent.
Вы можете использовать планировщик Windows для создания данного задания. 
Подробнее об использовании планировщика можно прочитать в описании: 
http://wiki.megatec.ru/Мастер-Тур:Создание_заданий_для_MS_SQL_Server_Express.'
		RAISERROR(@errorMessage, 16, 1)

EndSave:
GO
/*********************************************************************/
/* end job_mwRemoveDeletedNightly.sql */
/*********************************************************************/
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'job_mwRemoveDeletedNightly.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_CalculatePriceList.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
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

--<DATE>2014-11-05</DATE>
---<VERSION>9.2.21</VERSION>

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
			--INSERT INTO CalculatingPriceLists (CP_CreateDate, CP_PriceTourKey) VALUES (GETDATE(), @nPriceTourKey) 
			--SET @cpKey = SCOPE_IDENTITY()	
			SET @cpKey = @nCalculatingKey
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_CalculatePriceList.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_CalculatePriceListDynamic.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin sp_CalculatePriceListDynamic.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalculatePriceListDynamic]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CalculatePriceListDynamic]
GO

CREATE PROCEDURE [dbo].[CalculatePriceListDynamic]
(
	--<data>2014-10-01</data>
	--<version>9.2.20.21</version>
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
	into #tmp2
	from tp_lists with(nolock)
	where TI_TOKey = @nPriceTourKey 
	and TI_TotalDays is null
		
	update #tmp2 with(rowlock)
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
	from #tmp2
	where xTI_Key = TI_Key

	drop table #tmp2
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

	select distinct TO_Key, TD_Date + TS_Day - 1 as flight_day, TS_Code, TS_OpPartnerKey, TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, ti_totaldays, TD_Date
	into #TP_Flights1
	from TP_Tours with(nolock) join TP_Services with(nolock) on TO_Key = TS_TOKey and TS_SVKey = 1
		join TP_ServiceLists with(nolock) on TL_TSKey = TS_Key and TS_TOKey = TO_Key
		join TP_Lists with(nolock) on TL_TIKey = TI_Key and TI_TOKey = TO_Key
		join TP_TurDates with(nolock) on TD_TOKey = TO_Key
	where TO_Key = @nPriceTourKey

	delete from #TP_Flights1 where exists (Select 1 From TP_Flights with(nolock) Where TF_TOKey=@nPriceTourKey and TF_Date=flight_day
		and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
		and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = ti_totaldays)
		
	insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_TourDate, TF_CalculatingKey)
	select *, @nCalculatingKey  from #tp_flights1

	drop table #tp_flights1
	
	print 'Подбор перелетов 1: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()


	select 
		TF_ID, null as TF_CodeNew, null as TF_SubCode1New, null as TF_PRKeyNew, TF_CalculatingKey, 
		TF_CodeOld, TF_Subcode2, TF_PRKeyOld, TF_CTKey, TF_Subcode1, TF_PKKey, TF_Date, TF_TourDate, TF_Days
	into #TP_Flights
	from TP_Flights with(nolock)
	where TF_TOKey = @nPriceTourKey

	create index X_TP_Flights ON #TP_Flights (TF_ID)
	include (TF_CodeNew, TF_PRKeyNew, TF_SubCode1New, TF_CalculatingKey)
	

	------ проверяем, а подходит ли текущий рейс, указанный в туре (с учетом цен в которых дата продажи NULL или больше/равна сегодняшней дате )----
	Update	#TP_Flights Set TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1, TF_CalculatingKey = @nCalculatingKey
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey 
			and TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') 
			and TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01')
			and (ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') 
			and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long) 
			and (cs_DateSellBeg <= @dtSaleDate or cs_DateSellBeg is null) 
			and (cs_DateSellEnd >= @dtSaleDate or cs_DateSellEnd is null))

	--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------
	
	print 'Подбор перелетов 2: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()

	If @nNoFlight = 2
	BEGIN
		------ проверяем, а есть ли у данного парнера по рейсу, цены на другие рейсы в этом же пакете ----
		IF exists(SELECT top 1 1 FROM #TP_Flights WHERE TF_CodeNew is Null)
		begin
			print 'Подбираем перелет'
			
			declare @newFlightsPartnerTable table
			(
				-- идентификатор
				xId int identity(1,1) primary key,
				-- ключ записи в таблице tp_flights
				xTFId int,
				-- ключ нового партнера
				xPRKeyNew int,
				-- ключ нового перелета
				xCHKeyNew int,
				-- ключ нового тарифа на перелет
				xASKeyNew int
			)

			-- подбираем подходящие нам перелеты
			SELECT TF_Id as xTFId, CS_Code as xCHKeyNew, CS_SubCode1 as xASKeyNew, CS_PRKey as xPRKeyNew,
			case
				when TF_PRKeyOld = CS_PRKey then 4
				else 0 
			end 
			+
			case
				when TF_CodeOld = CH_Key then 2
				else 0 
			end 
			+ 
			case
				when TF_SubCode1 = CS_SubCode1 then 1
				else 0 
			end as xPriority
			into #tmp
			FROM AirSeason with(nolock), Charter with(nolock), Costs with(nolock), #TP_Flights with(nolock)
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
			TF_CodeNew is Null;

			with max_priority as
			(
				select xTFId, max(xPriority) as xPriority
				from #tmp
				group by xTFId
			)
			insert into @newFlightsPartnerTable (xTFId, xCHKeyNew, xASKeyNew, xPRKeyNew)
			select x.xTFId, min(x.xCHKeyNew), min(x.xASKeyNew), min(x.xPRKeyNew)
			from #tmp as x
			where exists (	select 1 
							from max_priority as xmax
							where x.xTFId = xmax.xTFId
								and x.xPriority = xmax.xPriority)
			group by x.xTFId, x.xPriority
			
			-- обновляем информацию о найденом перелете
			update #TP_Flights
			set TF_CodeNew = xCHKeyNew,
			TF_SubCode1New = xASKeyNew,
			TF_PRKeyNew = xPRKeyNew,
			TF_CalculatingKey = @nCalculatingKey
			from @newFlightsPartnerTable
			where TF_Id = xTFId
			
			print 'Закончили подбор перелетов'
		end
		
		print 'Подбор перелетов 3: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()	
	END

	update TF set 
		TF.TF_CodeNew = TF_Temp.TF_CodeNew, 
		TF.TF_PRKeyNew = TF_Temp.TF_PRKeyNew, 
		TF.TF_SubCode1New = TF_Temp.TF_SubCode1New, 
		TF.TF_CalculatingKey = TF_Temp.TF_CalculatingKey
	from TP_Flights TF
	inner join #TP_Flights TF_Temp on TF.TF_ID = TF_Temp.TF_ID

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
						insert into #TP_Prices (xtp_tokey, xtp_datebegin, xtp_dateend, xtp_tikey, xTP_CalculatingKey, xTP_Days, xTP_Rate, xTP_HotelKey, xTP_DepartureKey
						, xSCPId_1, xSCPId_2, xSCPId_3, xSCPId_4, xSCPId_5, xSCPId_6, xSCPId_7, xSCPId_8, xSCPId_9, xSCPId_10, xSCPId_11, xSCPId_12, xSCPId_13, xSCPId_14, xSCPId_15
						, xSvKey_1, xSvKey_2, xSvKey_3, xSvKey_4, xSvKey_5, xSvKey_6, xSvKey_7, xSvKey_8, xSvKey_9, xSvKey_10, xSvKey_11, xSvKey_12, xSvKey_13, xSvKey_14, xSvKey_15
						, xGross_1, xGross_2, xGross_3, xGross_4, xGross_5, xGross_6, xGross_7, xGross_8, xGross_9, xGross_10, xGross_11, xGross_12, xGross_13, xGross_14, xGross_15
						, xAddCostIsCommission_1, xAddCostIsCommission_2, xAddCostIsCommission_3, xAddCostIsCommission_4, xAddCostIsCommission_5, xAddCostIsCommission_6, xAddCostIsCommission_7, xAddCostIsCommission_8, xAddCostIsCommission_9, xAddCostIsCommission_10, xAddCostIsCommission_11, xAddCostIsCommission_12, xAddCostIsCommission_13, xAddCostIsCommission_14, xAddCostIsCommission_15
						, xAddCostNoCommission_1, xAddCostNoCommission_2, xAddCostNoCommission_3, xAddCostNoCommission_4, xAddCostNoCommission_5, xAddCostNoCommission_6, xAddCostNoCommission_7, xAddCostNoCommission_8, xAddCostNoCommission_9, xAddCostNoCommission_10, xAddCostNoCommission_11, xAddCostNoCommission_12, xAddCostNoCommission_13, xAddCostNoCommission_14, xAddCostNoCommission_15
						, xMarginPercent_1, xMarginPercent_2, xMarginPercent_3, xMarginPercent_4, xMarginPercent_5, xMarginPercent_6, xMarginPercent_7, xMarginPercent_8, xMarginPercent_9, xMarginPercent_10, xMarginPercent_11, xMarginPercent_12, xMarginPercent_13, xMarginPercent_14, xMarginPercent_15
						, xCommissionOnly_1, xCommissionOnly_2, xCommissionOnly_3, xCommissionOnly_4, xCommissionOnly_5, xCommissionOnly_6, xCommissionOnly_7, xCommissionOnly_8, xCommissionOnly_9, xCommissionOnly_10, xCommissionOnly_11, xCommissionOnly_12, xCommissionOnly_13, xCommissionOnly_14, xCommissionOnly_15
						, xIsCommission_1, xIsCommission_2, xIsCommission_3, xIsCommission_4, xIsCommission_5, xIsCommission_6, xIsCommission_7, xIsCommission_8, xIsCommission_9, xIsCommission_10, xIsCommission_11, xIsCommission_12, xIsCommission_13, xIsCommission_14, xIsCommission_15)
						values (@nPriceTourKey, @dtPrevDate, @dtPrevDate, @nPrevVariant, @nCalculatingKey, @tiDays, @sRate, @hdKey, @tiCtKeyFrom
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
			select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, CEILING(ROUND(xTP_Gross, 2)), xTP_TIKey, xTP_CalculatingKey 
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_CalculatePriceListDynamic.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_CalculatePriceListInit.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin sp_CalculatePriceListInit.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CalculatePriceListInit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[CalculatePriceListInit]
GO

CREATE PROCEDURE [dbo].[CalculatePriceListInit]
  (
	@nPriceTourKey int,			-- ключ обсчитываемого тура
	@dtSaleDate datetime,		-- дата продажи
	@nNullCostAsZero smallint,	-- считать отсутствующие цены нулевыми (кроме проживания) 0 - нет, 1 - да
	@nNoFlight smallint,		-- при отсутствии перелёта в расписании 0 - ничего не делать, 1 - не обсчитывать тур, 2 - искать подходящий перелёт (если не найдено - не рассчитывать)
	@nUpdate smallint,			-- признак дозаписи 0 - расчет, 1 - дозапись
	@nUseHolidayRule smallint		-- Правило выходного дня: 0 - не использовать, 1 - использовать
  )
AS
--<DATE>2014-10-28</DATE>
--<VERSION>9.2.21</VERSION>
BEGIN
	declare @tourKey int
	declare @userKey int
	declare @nCPKey int
	select @tourKey = TO_TRKey from TP_Tours where TO_Key = @nPriceTourKey
	exec GetUserKey @userKey output
	
	update TP_Tours set TO_UPDATE = 1 where TO_Key = @nPriceTourKey
	
	insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_TourKey, CP_UserKey, CP_Status, CP_UseHolidayRule, CP_CreateDate)
	values(@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @tourKey, @userKey, 1, @nUseHolidayRule, GETDATE())
	
	Set @nCPKey = SCOPE_IDENTITY()

	Return @nCPKey
END
GO

GRANT EXEC ON [dbo].[CalculatePriceListInit] TO PUBLIC
GO
/*********************************************************************/
/* end sp_CalculatePriceListInit.sql */
/*********************************************************************/
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_CalculatePriceListInit.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_mwCheckFlightGroupsQuotes.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
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

				-- koshelev
				-- 29337 В процессе расчета у нас могут подбираться не только перелеты, но и партнеры по перелетам
				-- при этом в mwCheckQuotesEx2 при @partnerKey < 0 партнер подбирается, а в обратном случае нет
				-- случай, когда @findFlight = 1 и @partnerKey > 0 некорректна
				if (@findFlight = 1)
					set @partnerKey = -1

				select @tmpPlaces = qt_places, @tmpPlacesAll = qt_allPlaces
				from dbo.mwCheckQuotesEx2(1, @chkey, @nkey, 0, @agentKey, @partnerKey, @tourdate,
					@day, 1, @requestOnRelease, @noPlacesResult, @checkAgentQuota,
					@checkCommonQuota, @checkNoLongQuota, @findFlight, 0, 0, @pkkey,
					@tourDays, @expiredReleaseResult, @linked_day, @airlineCodes)
				
				-- если места есть, но их не хватает, то возвращаем нет мест
				if (@tmpPlaces < @requestedPlaces and @tmpPlaces > 0)
				BEGIN
					set @tmpPlaces = @noPlacesResult
					set @tmpPlacesAll = 0
				END
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_mwCheckFlightGroupsQuotes.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_mwGetTourMonthesQuotas.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin sp_mwGetTourMonthesQuotas.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwGetTourMonthesQuotas')
	drop proc dbo.mwGetTourMonthesQuotas
GO

--<DATE>2014-11-11</DATE>
--<VERSION>2009.2.20.14</VERSION>

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
			
			set @tour_quotas = @tour_quotas + LTRIM(STR(YEAR(@tour_date))) + ':' + LTRIM(STR(@month)) + '='
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_mwGetTourMonthesQuotas.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_mwReplDisableDeletedPrices.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin sp_mwReplDisableDeletedPrices.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReplDisableDeletedPrices]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwReplDisableDeletedPrices]
GO

CREATE procedure [dbo].[mwReplDisableDeletedPrices]
--<DATE>2014-11-18</DATE>
--<VERSION>9.2.21.2</VERSION>
as
begin
	declare @cnKey int
	declare @ctKeyFrom int
	declare @sql varchar (500)
	declare @wasError as bit
	declare @errorText as nvarchar(max)

	set @wasError = 0

	select top 100000 * into #mwReplDeletedPricesTemp from dbo.mwReplDeletedPricesTemp with(nolock) order by rdp_cnkey, rdp_ctdeparturekey;
	create index x_pricekey on #mwReplDeletedPricesTemp(rdp_pricekey);

	begin try
	if exists(select top 1 1 from #mwReplDeletedPricesTemp)
	begin
		if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
		begin
			declare @wasErrorInCycle as bit
			set @wasErrorInCycle = 0
			
			create table #PriceDetailsToDelete (xPriceKey int primary key, xTourKey int)
			create index x_tourkey on #PriceDetailsToDelete(xTourKey);

			create table #delKeys (xKey int primary key)

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
						truncate table #PriceDetailsToDelete

						-- удаляем цены из поисковой таблицы
						set @sql = 'insert into #PriceDetailsToDelete (xPriceKey, xTourKey)
						select pt_pricekey, pt_tourkey from ' + @mwPriceDataTableName + '
						where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey)'
						exec (@sql)

						set @sql='
							update ' + @mwPriceDataTableName + ' 
							set pt_isenabled = 0
							where pt_isenabled = 1
							and pt_pricekey in (select xPriceKey from #PriceDetailsToDelete)';
						exec (@sql)

						-- удаляем записи из поискового фильтра
						truncate table #delKeys
						
						set @sql = 'insert into #delKeys (xKey) 
							select sd_key
							from mwSpoDataTable
							where sd_isenabled = 1
							and sd_cnkey = ' + ltrim(str(@cnKey)) + ' and sd_ctkeyfrom = ' + ltrim(str(@ctKeyFrom)) + '
							and sd_tourkey in (select distinct xTourKey from #PriceDetailsToDelete)
							and not exists (select 1 from [dbo].[' + @mwPriceDataTableName + '] with(nolock) where pt_isenabled = 1 and pt_tourkey = sd_tourkey and sd_hdkey = pt_hdkey and pt_tourkey in (select distinct xTourKey from #PriceDetailsToDelete))'
						exec (@sql)

						set @sql = 'update mwSpoDataTable set sd_isenabled = 0 where sd_key in (select xKey from #delKeys)'
						exec (@sql)

						-- удаляем записи из таблицы продолжительностей						
						truncate table #delKeys

						set @sql = 'insert into #delKeys (xKey) 
							select pd_key
							from mwPriceDurations
							where sd_tourkey in (select distinct xTourKey from #PriceDetailsToDelete)
							and not exists (select 1 from [dbo].[' + @mwPriceDataTableName + '] with(nolock) where pt_isenabled = 1 and pt_tourkey = sd_tourkey and pt_tourkey in (select distinct xTourKey from #PriceDetailsToDelete) and pt_nights = sd_nights)'
						exec (@sql)

						set @sql = 'delete from mwPriceDurations where pd_key in (select xKey from #delKeys)'
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
			truncate table #PriceDetailsToDelete

			-- удаляем цены из поисковой таблицы
			insert into #PriceDetailsToDelete (xPriceKey, xTourKey)
			select pt_pricekey, pt_tourkey 
			from mwPriceDataTable
			where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey)

			update mwPriceDataTable
			set pt_isenabled = 0
			where pt_isenabled = 1
			and pt_pricekey in (select xPriceKey from #PriceDetailsToDelete)

			truncate table #delKeys
						
			-- удаляем записи из поискового фильтра
			insert into #delKeys (xKey) 
			select sd_key
			from mwSpoDataTable
			where sd_isenabled = 1
			and sd_tourkey in (select distinct xTourKey from #PriceDetailsToDelete)
			and not exists (select 1 from [dbo].[mwPriceDataTable] with(nolock) where pt_isenabled = 1 and pt_tourkey = sd_tourkey and sd_hdkey = pt_hdkey and pt_tourkey in (select distinct xTourKey from #PriceDetailsToDelete))

			update mwSpoDataTable set sd_isenabled = 0 where sd_key in (select xKey from #delKeys) and sd_isenabled = 1
						
			truncate table #delKeys

			-- удаляем записи из таблицы продолжительностей
			insert into #delKeys (xKey) 
			select pd_key
			from mwPriceDurations
			where sd_tourkey in (select distinct xTourKey from #PriceDetailsToDelete)
			and not exists (select 1 from [dbo].[mwPriceDataTable] with(nolock) where pt_isenabled = 1 and pt_tourkey = sd_tourkey and pt_tourkey in (select distinct xTourKey from #PriceDetailsToDelete) and pt_nights = sd_nights)

			delete from mwPriceDurations where pd_key in (select xKey from #delKeys)
		end

		-- delete from source table only if processing was successful
		delete from mwReplDeletedPricesTemp
		where exists(select top 1 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = mwReplDeletedPricesTemp.rdp_pricekey)

	end

	end try
	begin catch
		set @wasError = 1
		set @errorText = ERROR_MESSAGE()
	end catch

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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_mwReplDisableDeletedPrices.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_Paging.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin sp_Paging.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Paging]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[Paging]
GO

	--<VERSION>9.2.22</VERSION>
	--<DATE>2014-11-26</DATE>
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
	@airlineCodes ListSysNameValue readonly,
	@showCOName bit = 0						-- отображать ли в QD название ценового блока, из которого берется цена проживания
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

	if (exists(select top 1 1 from SystemSettings where SS_ParmName='NewReCalculatePrice' and SS_ParmValue='1')
		and @showCOName=1)
	begin
		--находим название ценового блока, из которого берется цена проживания
		set @sql = @sql +
			'ISNULL((select top 1 CO_Name from CostOffers with(nolock)
				inner join CostOfferServices with(nolock) on COS_COID=CO_Id
				inner join tbl_Costs with(nolock) on CS_COID=CO_Id
				inner join Turlist with(nolock) on TL_KEY=pt_tlkey
				inner join TurService with(nolock) on TS_TRKEY=TL_KEY
				where COS_SVKey=3
				and TS_SVKEY=3
				and TS_CODE=pt_hdkey
				and CS_SVKey=3
				and CO_SVKey=3
				and COS_Code=pt_hdkey
				and CS_Code=pt_hdkey
				and CO_PKKey=TS_PKKEY
				and
				(
					ISNULL(CS_DATE,''1900-01-01'') <= DATEADD(DAY,pt_days,pt_tourdate) and ISNULL(CS_DATEEND,''2300-01-01'') >= pt_tourdate
					and
					ISNULL(CS_CHECKINDATEBEG,''1900-01-01'') <= pt_tourdate and ISNULL(CS_CHECKINDATEEND,''2300-01-01'') >= pt_tourdate
				)
				and GETDATE() between ISNULL(CO_SaleDateBeg,''1900-01-01'') and ISNULL(CO_SaleDateEnd,''2050-01-01'')
				and CS_PRKey=pt_hdpartnerkey
				and CO_PartnerKey=pt_hdpartnerkey
				and CO_State=1
				and CO_DateClose is null
				order by ISNULL(CO_DateLastPublish,''1900-01-01'') desc,ISNULL(CO_DateActive,''1900-01-01'') desc),'''') as co_name,'
	end
	else
	begin
		set @sql = @sql + ''''' as co_name,'
	end

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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_Paging.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_ReCalculate_MigrateToPrice.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
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
			tp.TP_Gross = CEILING(ROUND(xSummPrice, 2)),
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'sp_ReCalculate_MigrateToPrice.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'T_DogovorUpdate.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin T_DogovorUpdate.sql */
/*********************************************************************/
IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_DogovorUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	DROP TRIGGER [dbo].[T_DogovorUpdate]
GO

CREATE TRIGGER [dbo].[T_DogovorUpdate]
ON [dbo].[tbl_Dogovor] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>9.2.21</VERSION>
--<DATE>2014-11-26</DATE>
IF @@ROWCOUNT > 0
BEGIN
    DECLARE @sMod varchar(3)
    DECLARE @nDelCount int
    DECLARE @nInsCount int
	
    SELECT @nDelCount = COUNT(*) FROM DELETED
    SELECT @nInsCount = COUNT(*) FROM INSERTED
	
    -- При включенной настройке BookingDBLogicInDotNet все связанное с вставкой путевки находится в BusinessRules
    IF (EXISTS (SELECT TOP 1 1 FROM SystemSettings WHERE SS_ParmName = 'BookingDBLogicInDotNet' AND SS_ParmValue = '1') AND @nDelCount = 0)
        RETURN
		
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
	DECLARE @statusChangedMultiplicity smallint
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

  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT N.DG_Key, 
		N.DG_Code, null, null, null, null, null, null, null, null, null, null, null, null, null, 
		null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
		N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, N.DG_TurDate, N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
		CONVERT( char(11), N.DG_PPaymentDate, 104) + CONVERT( char(5), N.DG_PPaymentDate, 108), CONVERT( char(10), N.DG_PaymentDate, 104), 
		N.DG_RazmerP, N.DG_Procent, N.DG_Locked, N.DG_SOR_Code, N.DG_IsOutDoc, CONVERT( char(10), N.DG_VisaDate, 104), N.DG_CauseDisc, N.DG_OWNER, 
		N.DG_LEADDEPARTMENT, N.DG_DupUserKey, N.DG_MainMen, N.DG_MainMenEMail, N.DG_MAINMENPHONE, N.DG_CodePartner, N.DG_Creator, N.DG_CTDepartureKey, N.DG_Payed, N.DG_ProTourFlag
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT O.DG_Key,
		O.DG_Code, O.DG_Price, O.DG_Rate, O.DG_DiscountSum, O.DG_PartnerKey, O.DG_TRKey, O.DG_TurDate, O.DG_CTKEY, O.DG_NMEN, O.DG_NDAY, 
		CONVERT( char(11), O.DG_PPaymentDate, 104) + CONVERT( char(5), O.DG_PPaymentDate, 108), CONVERT( char(10), O.DG_PaymentDate, 104), O.DG_RazmerP, 
		O.DG_Procent, O.DG_Locked, O.DG_SOR_Code, O.DG_IsOutDoc, CONVERT( char(10), O.DG_VisaDate, 104), O.DG_CauseDisc, O.DG_OWNER, 
		O.DG_LEADDEPARTMENT, O.DG_DupUserKey, O.DG_MainMen, O.DG_MainMenEMail, O.DG_MAINMENPHONE, O.DG_CodePartner, O.DG_Creator, O.DG_CTDepartureKey, O.DG_Payed, O.DG_ProTourFlag,
		null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
      FROM DELETED O 
  END
ELSE 
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT N.DG_Key,
		O.DG_Code, O.DG_Price, O.DG_Rate, O.DG_DiscountSum, O.DG_PartnerKey, O.DG_TRKey, O.DG_TurDate, O.DG_CTKEY, O.DG_NMEN, O.DG_NDAY, 
		CONVERT( char(11), O.DG_PPaymentDate, 104) + CONVERT( char(5), O.DG_PPaymentDate, 108), CONVERT( char(10), O.DG_PaymentDate, 104), O.DG_RazmerP,
		O.DG_Procent, O.DG_Locked, O.DG_SOR_Code, O.DG_IsOutDoc, CONVERT( char(10), O.DG_VisaDate, 104), O.DG_CauseDisc, O.DG_OWNER, 
		O.DG_LEADDEPARTMENT, O.DG_DupUserKey, O.DG_MainMen, O.DG_MainMenEMail, O.DG_MAINMENPHONE, O.DG_CodePartner, O.DG_Creator, O.DG_CTDepartureKey, O.DG_Payed,
		O.DG_ProTourFlag, N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, N.DG_TurDate, N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
		CONVERT( char(11), N.DG_PPaymentDate, 104) + CONVERT( char(5), N.DG_PPaymentDate, 108),  CONVERT( char(10), N.DG_PaymentDate, 104), N.DG_RazmerP, 
		N.DG_Procent, N.DG_Locked, N.DG_SOR_Code, N.DG_IsOutDoc,  CONVERT( char(10), N.DG_VisaDate, 104), N.DG_CauseDisc, N.DG_OWNER, 
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
					-- Получаем кратность 
					select @statusChangedMultiplicity = NC_Multiplicity from NationalCurrencyReservationStatuses with(nolock) where NC_OrderStatus = ISNULL(@NDG_SOR_Code, 0)
					if (@statusChangedMultiplicity = 1 OR @bCurrencyChangedPrevFixDate > 0) -- Кратность: только один раз 
					begin -- либо включена опция, что при смене валюты стоимость пересчитывается по дате предыдущей фиксации
						-- пытаемя получить дату первой установки нужного статуса, либо текущую дату, если еще не фиксировали
						set @changedDate = ISNULL(dbo.GetFirstDogovorStatusDate (@DG_Key, @NDG_SOR_Code), GetDate())
					end
					if (@statusChangedMultiplicity = 2)	-- Кратность: каждый раз при смене статуса, берем текущую дату 
					begin
						set @changedDate = GetDate()
					end
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
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'T_DogovorUpdate.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'T_NCReservationStatusesUpdate.sql начат', 'SCRIPTTIMELINE', HOST_NAME())
/*********************************************************************/
/* begin T_NCReservationStatusesUpdate.sql */
/*********************************************************************/
IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_NCReservationStatusesUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	DROP TRIGGER [dbo].[T_NCReservationStatusesUpdate]
GO

CREATE TRIGGER [dbo].[T_NCReservationStatusesUpdate]
ON [dbo].[NationalCurrencyReservationStatuses] 
FOR INSERT, DELETE, UPDATE
AS
--<VERSION>9.2.21</VERSION>
--<DATE>2014-11-26</DATE>
IF @@ROWCOUNT > 0
BEGIN
	DECLARE @NC_ID int
	DECLARE @ONC_OrderStatus int
	DECLARE @NNC_OrderStatus int
	DECLARE @ONC_Multiplicity int
	DECLARE @NNC_Multiplicity int
	DECLARE @HIID int
	DECLARE @Mod varchar(3)
	DECLARE @HiText varchar(254)
	DECLARE @hostName varchar(25)
	DECLARE @bNeedCommunicationUpdate smallint
	DECLARE @DelCount int
	DECLARE @InsCount int
	DECLARE @oldValue int
	DECLARE @newValue int
	DECLARE @OAID int	
	SELECT @DelCount = COUNT(*) FROM DELETED
	SELECT @InsCount = COUNT(*) FROM INSERTED
	
	if(@DelCount = 0)
	BEGIN
		Set @Mod = 'INS'
		DECLARE cur_Modification CURSOR FOR	
		SELECT N.NC_ID
			 , null, null
			 , N.NC_OrderStatus, N.NC_Multiplicity
		FROM INSERTED N 	
	END
	ELSE IF(@InsCount = 0)
	BEGIN 
		Set @Mod = 'DEL'
		DECLARE cur_Modification CURSOR FOR	
		SELECT O.NC_ID
			 , O.NC_OrderStatus, O.NC_Multiplicity
			 , null, null
		FROM DELETED O 
	END
	ELSE
	BEGIN
		Set @Mod = 'UPD'	
		DECLARE cur_Modification CURSOR FOR	
		SELECT N.NC_ID
			 , O.NC_OrderStatus, O.NC_Multiplicity
			 , N.NC_OrderStatus, N.NC_Multiplicity
		FROM INSERTED N, DELETED O
		WHERE N.NC_ID = O.NC_ID
	END
	
	SET @hostName = SUBSTRING(HOST_NAME(),1,25);
	OPEN cur_Modification
    FETCH NEXT FROM cur_Modification INTO @NC_ID
										, @ONC_OrderStatus, @ONC_Multiplicity
										, @NNC_OrderStatus, @NNC_Multiplicity
    WHILE @@FETCH_STATUS = 0
    BEGIN 
		IF((@Mod = 'UPD' OR @Mod = 'INS' OR @Mod = 'DEL') AND 
		  ((ISNULL(@ONC_OrderStatus, 0) != ISNULL(@NNC_OrderStatus, 0)) OR
		   (ISNULL(@ONC_Multiplicity, 0) != ISNULL(@NNC_Multiplicity, 0))))
		BEGIN
			SET @oldValue = ISNULL(@ONC_OrderStatus, 0)
			SET @newValue = ISNULL(@NNC_OrderStatus, 0)
			IF(ISNULL(@ONC_OrderStatus, 0) != ISNULL(@NNC_OrderStatus, 0))
			BEGIN 
				SET @HiText = 'Значение колонки NC_OrderStatus изменилось с '+CAST(@oldValue AS varchar(3))+' на '+CAST(@newValue AS varchar(3))
				SET @OAID = 32001
				EXEC @HIID = dbo.InsHistory null, null, 32, @NC_ID, @Mod, @HiText, @hostName, 0, ''
				EXEC dbo.InsertHistoryDetail @HIID , @OAID, null, null, @oldValue, @newValue, null, null, 0, @bNeedCommunicationUpdate output
			END
			SET @oldValue = ISNULL(@ONC_Multiplicity, 0)
			SET @newValue = ISNULL(@NNC_Multiplicity, 0)
			IF(ISNULL(@ONC_Multiplicity, 0) != ISNULL(@NNC_Multiplicity, 0))
			BEGIN 
				SET @HiText = 'Значение колонки NC_Multiplicity изменилось с '+CAST(@oldValue AS varchar(3))+' на '+CAST(@newValue AS varchar(3))
				SET @OAID = 32002
				EXEC @HIID = dbo.InsHistory null, null, 32, @NC_ID, @Mod, @HiText, @hostName, 0, ''
				EXEC dbo.InsertHistoryDetail @HIID , @OAID, null, null, @oldValue, @newValue, null, null, 0, @bNeedCommunicationUpdate output
			END
		END
		FETCH NEXT FROM cur_Modification INTO @NC_ID
										, @ONC_OrderStatus, @ONC_Multiplicity
										, @NNC_OrderStatus, @NNC_Multiplicity
	END
	CLOSE cur_Modification
	DEALLOCATE cur_Modification
END
GO

/*********************************************************************/
/* end T_NCReservationStatusesUpdate.sql */
/*********************************************************************/
INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'T_NCReservationStatusesUpdate.sql завершен', 'SCRIPTTIMELINE', HOST_NAME())

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
-- =====================   Обновление версии БД. 9.2.20.24 - номер версии, 2014-11-28 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.24', st_moduledate = convert(datetime, '2014-11-28', 120),  st_financeversion = '9.2.20.24', st_financedate = convert(datetime, '2014-11-28', 120)
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
	SET SS_ParmValue='2014-11-28' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO

INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer) VALUES(SUSER_NAME(), 'Выполнение релизного скрипта завершено. Версия релиза: 9.2.20.24. Дата релиза: 2014-11-28', 'SCRIPTTIMELINE', HOST_NAME())
GO