/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 10.02.2014 18:02 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.6'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.7'

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
/* begin (05-02-2014)_ALTER_TABLE_COSTS.sql */
/*********************************************************************/
--Обнаружена проблема: брутто некоторых цен неожиданно становится равным NULL.
--Предположительно проблема связана с сервис-паком 9.2.20.4 или 9.2.20.5.
--Было принято решение: сделать колонку брутто NOT NULL, чтобы понять, какой код пытается присвоить пустое значение.

UPDATE tbl_costs SET cs_cost=cs_costnetto WHERE cs_cost IS NULL
GO

ALTER TABLE tbl_costs ALTER COLUMN cs_cost FLOAT NOT NULL
GO
/*********************************************************************/
/* end (05-02-2014)_ALTER_TABLE_COSTS.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwCheckQuotesEx2.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesEx2]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesEx2]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesEx2]
(
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
	@expiredReleaseResult int,
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
	--<VERSION>9.2.19.15</VERSION>
	--<DATE>2013-09-17</DATE>

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

	declare @ALLDAYS_CHECK int
	set @ALLDAYS_CHECK = -777

	-- для квот на продолжительность
	declare @long int
	if(@svkey = 1 or @svkey = 2 or @svkey = 4 or @checkNoLongQuotes = @ALLDAYS_CHECK)
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
			@dateFrom, @requestOnRelease, @noPlacesResult, @checkAgentQuotes, 
			@checkCommonQuotes, @checkNoLongQuotes, @findFlight, @cityFrom,	@cityTo, @flightpkkey,
			@tourDuration, @expiredReleaseResult, @linked_day)
		
		return
	end
	else
	begin
		declare @tmpSubcode1 int
		if(@svkey = 3 and @subcode1 > 0 and @subcode2 <= 0) 
		begin
			select @tmpSubcode1 = hr_rmkey, @subcode2 = hr_rckey from hotelrooms with(nolock) where hr_key = @subcode1
			set @subcode1 = @tmpSubcode1
		end
		
		declare @currentDate datetime
		select @currentDate = currentDate from dbo.mwCurrentDate
		
		declare @tmpQuotes as CheckQuotasSourceTable
		
		declare @qtSvkey int, @qtCode int, @qtSubcode1 int, @qtSubcode2 int, @qtAgent int,
		@qtPrkey int, @qtNotcheckin int, @qtRelease int, @qtPlaces int, @qtDate datetime,
		@qtByroom int, @qtType int, @qtLong int, @qtPlacesAll int, @qtStop smallint, @qtQoId int

		declare	@svkeyRes int, @codeRes int, @subcode1Res int, 
			@subcode2Res int, @agentRes int, @prkeyRes int,
			@bycheckinRes int, @byroomRes int, @placesRes int,
			@allPlacesRes int, @typeRes int, @longRes int, @releaseRes int, @additional varchar(2000), @stopSale smallint

		set @svkeyRes = 0
		set @codeRes = 0
		set @subcode1Res = 0
		set @subcode2Res = 0
		set @agentRes = 0
		set @prkeyRes = 0
		set @bycheckinRes = 0
		set @byroomRes = 0
		set @typeRes = 0
		set @allPlacesRes = 0
		set @longRes = 0
		set @releaseRes = -1
		set @additional = ''
		
		insert into @tmpQuotes select * from 
		(select 
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
			(case when (isnull(ss_id, 0) > 0 and isnull(ss_isdeleted, 0) = 0) then 1 else 0 end) as qt_stop,
			qo_id as qt_qoid, qd_id as qt_qdid
		from quotas q with(nolock) inner join 
			quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
			left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
			right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid 
			left outer join StopSales ss with(nolock) on (qd_id = ss_qdid and isnull(ss_isdeleted, 0) = 0)
		where
			qo_svkey = @svkey
			and ISNULL(QD_IsDeleted, 0) = 0
			and qo_code = @code
			and isnull(qo_subcode1, 0) in (0, @subcode1)
			and (@svKey = 1 or isnull(qo_subcode2, 0) in (0, @subcode2))
			and ((@checkAgentQuotes > 0 and @checkCommonQuotes > 0 and isnull(qp_agentkey, 0) in (0, @agentKey)) or
				(@checkAgentQuotes <= 0 and isnull(qp_agentkey, 0) = 0) or
				(@checkAgentQuotes > 0 and @checkCommonQuotes <= 0 and isnull(qp_agentkey, 0) in (0, @agentKey)))
			and (@partnerKey < 0 or isnull(qt_prkey, 0) in (0, @partnerKey))
			and ((@days = 1 and qd_date = @dateFrom) or (@days > 1 and qd_date between @dateFrom and @dateTo))
			and (@tourDuration < 0 or (@checkNoLongQuotes <> @ALLDAYS_CHECK and isnull(ql_duration, 0) in (0, @long)) or (@checkNoLongQuotes = @ALLDAYS_CHECK and isnull(ql_duration, 0) = @long))
			and not exists (select top 1 1 
									from StopSales inner join QuotaObjects on qo_id=ss_qoid
									where ((@days = 1 and ss_date = @dateFrom) or (@days > 1 and ss_date between @dateFrom and @dateTo))
									and ss_qdid is null
									and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
									and isnull(ss_isdeleted, 0) = 0
									and (qd.QD_Type = 1 or SS_AllotmentAndCommitment = 1)
									and qo_svkey = @svkey
									and qo_code = @code
									and isnull(qo_subcode1, 0) in (0, @subcode1)
									and isnull(qo_subcode2, 0) in (0, @subcode2))
		-- Paul G 07.02.2011 MEG00031547, MEG00031454
		-- Не отлавливались такие дни, на которые нет квот, но есть стоп-сейл.
		-- Да и вообще не учитывались стопы с пустой ссылкой на QuotaDetails.
		-- Добавил union, который учитывает стопы с пустой ссылкой на QuotaDetails.
		union
			select
				qo_svkey,
				qo_code,
				isnull(qo_subcode1, 0) as qo_subcode1,
				isnull(qo_subcode2, 0) as qo_subcode2,
				0,
				isnull(ss_prkey, 0) as qt_prkey,
				0,null,0,ss_date,null,isnull(SS_AllotmentAndCommitment, 0) + 1,0,0,1,
				qo_id as qt_qoid, null
			from StopSales
				inner join QuotaObjects on qo_id=ss_qoid
			where ((@days = 1 and ss_date = @dateFrom) or (@days > 1 and ss_date between @dateFrom and @dateTo))
					and ss_qdid is null
					and isnull(ss_isdeleted, 0) = 0
					and qo_svkey = @svkey
					and qo_code = @code
					and isnull(qo_subcode1, 0) in (0, @subcode1)
					and isnull(qo_subcode2, 0) in (0, @subcode2)
					and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
			union
			select
				qo_svkey,
				qo_code,
				isnull(qo_subcode1, 0) as qo_subcode1,
				isnull(qo_subcode2, 0) as qo_subcode2,
				0,
				isnull(ss_prkey, 0) as qt_prkey,
				0,null,0,ss_date,null,isnull(SS_AllotmentAndCommitment, 0) + 1,QL_Duration,0,1,
				qo_id as qt_qoid, QD_ID as qt_qdid
			from StopSales
				inner join QuotaObjects on qo_id=ss_qoid
				inner join QuotaDetails on QD_ID=SS_QDID
				left join QuotaParts on QP_QDID = qd_id
				left join QuotaLimitations on QL_QPID = qp_id
			where ((@days = 1 and ss_date = @dateFrom) or (@days > 1 and ss_date between @dateFrom and @dateTo))
					and ss_qdid is not null
					and isnull(ss_isdeleted, 0) = 0
					and qo_svkey = @svkey
					and qo_code = @code
					and isnull(qo_subcode1, 0) in (@subcode1)
					and isnull(qo_subcode2, 0) in (0, @subcode2)
					and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
		) as innerQuotas
		order by
			qd_date, qp_agentkey DESC, qt_freePlaces, QD_Release desc, qd_type DESC, QT_PrKey DESC, qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC, qo_subcode2 DESC
		-- тут вставлю логику проверки для отелей
		
		-- если квота проверяется из экрана HotelQuotes, проверка на наличие общего стопа
		if (@tourDuration < 0 and @svkey = 3)
		begin
			if exists(select 1 
					from stopsales with(nolock) 
						inner join quotaobjects qo with(nolock) on ss_qoid = qo_id
					where qo_svkey = @svkey and qo_code = @code and isnull(qo_subcode1, 0) in (0, @subcode1)
						and isnull(qo_subcode2, 0) in (0, @subcode2) and ss_date between @dateFrom and @dateTo
						and (ss_qdid is null ) 
						and isnull(ss_isdeleted, 0) = 0 
						and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
						and (IsNull(ss_allotmentandcommitment, 0) = 1 
							or not exists(select 1 from
							quotas with(nolock) inner join quotaobjects qo1 with(nolock) on
							qo1.qo_qtid = qt_id inner join quotadetails with(nolock) on qd_qtid = qt_id
							 where qo.qo_svkey = qo1.qo_svkey and qo.qo_code = qo1.qo_code and (qo.qo_subcode1 in (qo1.qo_subcode1, 0) or qo1.qo_subcode1 = 0)
							 and (qo.qo_subcode2 in (qo1.qo_subcode2, 0) or qo1.qo_subcode2 = 0) and qd_date = ss_date and qd_places > qd_busy and qd_type = 2)))
			begin
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
				qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
				
				return
			end							 
		end
		
		-- для экрана HotelQuotes
		-- если не существует не одной квоты, то возвращаем запрос
		-- если есть места, но стоит стоп, то возвращаем нет мест	
		if (not exists (select top 1 1 from @tmpQuotes) and @tourDuration < 0
			and not exists(select top 1 1 from quotas q with(nolock) inner join 
											quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
											left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
											right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid
											where qo_svkey = @svkey
											and ISNULL(QD_IsDeleted, 0) = 0
											and qo_code = @code
											and isnull(qo_subcode1, 0) in (0, @subcode1)
											and isnull(qo_subcode2, 0) in (0, @subcode2)
											and ((@checkAgentQuotes > 0 and @checkCommonQuotes > 0 and isnull(qp_agentkey, 0) in (0, @agentKey)) or
												(@checkAgentQuotes <= 0 and isnull(qp_agentkey, 0) = 0) or
												(@checkAgentQuotes > 0 and @checkCommonQuotes <= 0 and isnull(qp_agentkey, 0) in (0, @agentKey)))
											and (@partnerKey < 0 or isnull(qt_prkey, 0) in (0, @partnerKey))
											and ((@days = 1 and qd_date = @dateFrom) or (@days > 1 and qd_date between @dateFrom and @dateTo))
											and (@tourDuration < 0 or (@checkNoLongQuotes <> @ALLDAYS_CHECK 
											and isnull(ql_duration, 0) in (0, @long)) or (@checkNoLongQuotes = @ALLDAYS_CHECK and isnull(ql_duration, 0) = @long))))
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, @noPlacesResult, 0, 0, 0, '0=-1:0')
			return
		end
		else if (not exists (select top 1 1 from @tmpQuotes) and @tourDuration < 0)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
			return
		end
		
		-- пробуем удалить стопы по следующему принципу: если стоит стоп на один тип квоты, но на другом типе с квотами все в порядке
		if ((select count(distinct qt_date) from @tmpQuotes where qt_places > 0 and qt_stop = 0 and qt_type = 1) = @days
			and exists(select 1 from @tmpQuotes where qt_stop = 1 and qt_type = 2))
		begin
			delete from @tmpQuotes where qt_stop = 1 and qt_type = 2
		end
		
		if ((select count(distinct qt_date) from @tmpQuotes where qt_places > 0 and qt_stop = 0 and qt_type = 2) = @days
			and exists(select 1 from @tmpQuotes where qt_stop = 1 and qt_type = 1)
		)
		begin
			delete from @tmpQuotes where qt_stop = 1 and qt_type = 1
		end

		if (exists(select top 1 1 from @tmpQuotes where qt_date=@dateFrom and qt_bycheckin=1)
			and not exists(select top 1 1 from @tmpQuotes where qt_date=@dateFrom and qt_places>0 and qt_placesAll>0 and isNull(qt_release,0) <= (@dateFrom - GETDATE()))
			and exists(select top 1 1 from @tmpQuotes where qt_date=@dateFrom and isNull(qt_release,0) > (@dateFrom - GETDATE())))
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
			return
		end
		
		-- если одновременно на alotment и commitment нет мест, возвращаем отсутствие мест
		if
		(
			(
				exists(select 1 from @tmpQuotes as tq1 where ((qt_stop = 1 or qt_places = 0) and qt_type = 2) and not exists(select 1 from @tmpQuotes as tq2 where tq2.qt_stop=0 and tq2.qt_places>0 and tq2.qt_date=tq1.qt_date))
			)
			and
			(
				exists(select 1 from @tmpQuotes as tq1 where ((qt_stop = 1 or qt_places = 0) and qt_type = 1) and not exists(select 1 from @tmpQuotes as tq2 where tq2.qt_stop=0 and tq2.qt_places>0 and tq2.qt_date=tq1.qt_date))
			)
		)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent, qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, @noPlacesResult, 0, 0, 0, '0=0:0')
				
			return
		end
		
		if(@tourDuration < 0) -- надо проверить все возможные квоты по дням на все возможные продолжительности (используется при проверке наличия мест в отеле и на перелете)
		begin
			set @checkNoLongQuotes = @ALLDAYS_CHECK

			declare @durations table(
				duration int
			)

			insert into @durations select distinct qt_long from @tmpQuotes order by qt_long

			declare @rowCount int
			set @rowCount = @@rowCount

			if(@rowCount > 1)
			begin
				declare @quotaDuration int
				declare durationCur cursor fast_forward read_only for
					select duration from @durations
	
				open durationCur
	
				fetch next from durationCur into @quotaDuration
				while(@@fetch_status = 0)
				begin
					if(len(@additional) > 0)
						set @additional = @additional + '|'
	
					select 
						@additional = @additional + qt_additional
					from dbo.mwCheckQuotesEx(@svkey, @code, @subcode1, @subcode2, @agentKey, @partnerKey, 
						@date, @day, @days, @requestOnRelease, @noPlacesResult, @checkAgentQuotes, 
						@checkCommonQuotes, @ALLDAYS_CHECK, @findFlight, @cityFrom,	@cityTo, @flightpkkey,
						@quotaDuration,	@expiredReleaseResult)
	
					fetch next from durationCur into @quotaDuration
				end
	
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @additional)
			
				close durationCur
				deallocate durationCur
	
				return
			end
			else if(@rowCount = 1)
				select @long = duration from @durations
			else
				set @long = 0
		end
		else
		begin
			-- check stopsale
			-- MT ignore stop on object for commitment quotas
			if exists(select 1 
					from stopsales with(nolock) 
						inner join quotaobjects qo with(nolock) on ss_qoid = qo_id
					where qo_svkey = @svkey and qo_code = @code and isnull(qo_subcode1, 0) in (0, @subcode1)
						and isnull(qo_subcode2, 0) in (0, @subcode2) and ss_date between @dateFrom and @dateTo
						and (ss_qdid is null ) 
						and isnull(ss_isdeleted, 0) = 0 
						and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
						-- MEG00032187 Paul G 14.02.2011
						-- Отсеиваем те стопы, которые ставятся только на allotment (ss_allotmentandcommitment = 0)
						-- и по которым на соответствующие дни есть квоты commitment.
						and (IsNull(ss_allotmentandcommitment, 0) = 1 
							or not exists(select 1 from
							quotas with(nolock) inner join quotaobjects qo1 with(nolock) on
							qo1.qo_qtid = qt_id inner join quotadetails with(nolock) on qd_qtid = qt_id
						--MEG00029495 Paul G 18.02.2010
						--Добавил условие qd_places > qd_busy
						--Смысл в том, что это условие должно проверять существование квот commitment на некоторые дни, но только тех
						--на которые еще есть места. Иначе возможна ситуация, когда на все commitment закончились места, а allotment на стопе
						--и проверка на наличие стопа не сработает
							 where qo.qo_svkey = qo1.qo_svkey and qo.qo_code = qo1.qo_code and (qo.qo_subcode1 in (qo1.qo_subcode1, 0) or qo1.qo_subcode1 = 0)
							 and (qo.qo_subcode2 in (qo1.qo_subcode2, 0) or qo1.qo_subcode2 = 0) and qd_date = ss_date and qd_places > qd_busy and qd_type = 2 /*commitment*/)))
			begin
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
						values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
							return 
			end

		end
		
		if (isnull((select min(qt_bycheckin)
					from @tmpQuotes
					where qt_date = @dateFrom), 0) = 1 AND @checkNoLongQuotes != @ALLDAYS_CHECK AND (SELECT CASE WHEN (SELECT COUNT(*) FROM @tmpQuotes) > 0 THEN 1 ELSE 0 END)=1)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
								values(0, 0, 0, 0, 0, 0, 0, 0, case when @stopSale > 0 then 0 else @noPlacesResult end, 0, 0, 0)
								return
		end

		if isnull((select max(stopSale)
					from (select min(qt_stop) as stopSale
							from @tmpQuotes
							where qt_qoid = (select top 1 qt_qoid from @tmpQuotes where qt_date = @dateFrom) and isnull(qt_prkey, 0) = isnull(@partnerkey, 0)
							group by qt_date) as tbl), 0) = 1
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
						values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
							return 
		end
		
		-- MEG00024921, Danil, 10.02.2010: значения переменных предыдущей проверенной строки
		declare @prevSubCode1 int, @prevSubCode2 int, @prevQtType int, @result int, @tmpDate datetime
		-- MEG00024921 End

		declare qCur cursor fast_forward read_only for 
		select
			qt_svkey,
			qt_code,
			qt_subcode1,
			qt_subcode2,
			qt_agent,
			qt_prkey,
			qt_bycheckin,
			qt_release,
			qt_places,
			qt_date,
			qt_byroom,
			qt_type,
			qt_long,
			qt_placesAll,
			qt_stop,
			qt_qoid
		from @tmpQuotes

		open qCur

		fetch next from qCur 
			into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
				@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, 
				@qtByroom, @qtType, @qtLong, @qtPlacesAll, @qtStop, @qtQoId

		-- MEG00024921, Danil, 10.02.2010: значения переменных предыдущей проверенной строки
		set @prevSubCode1 = @qtSubcode1
		set @prevSubCode2 = @qtSubcode2
		set @prevQtType = @qtType
		-- MEG00024921 End
		
		if(@@fetch_status = 0)
		begin
			set @result = 1000000

			declare @prevDate datetime, @dateRes int, @dateAllPlaces int, @wasLongQuota smallint, @wasAgentQuota smallint, 
			@checkAfterWasLong smallint, @checkAfterWasAgent smallint, @isFirstDate bit, @prevDateRes int, @prevDateOld datetime

			set @prevDate = @dateFrom
			if(@qtDate = @dateFrom)
				set @dateRes = 0
			else
				set @dateRes = -1
			set @dateAllPlaces = 0
			set @stopSale = 1
			set @wasLongQuota = 0
			set @wasAgentQuota = 0
			set @checkAfterWasLong = 0
			set @checkAfterWasAgent = 0
			set @isFirstDate = 1
			set @prevDateRes = 0

			declare @quoteOnFirstDayExist smallint -- признак существования квоты на ПЕРВЫЙ день
				set @quoteOnFirstDayExist = 0

			while(@@fetch_status = 0)
			begin
				if(@qtStop > 0) -- stop sale
				begin
					close qCur
					deallocate qCur

					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
					values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
					return
				end

				if(@checkNoLongQuotes != @ALLDAYS_CHECK)
				begin
					-- Если обрабатываемая квота - квота на первый день, то выставляем индикатор в true
					if (@qtDate = @dateFrom and @qtNotcheckin = 0)
						set @quoteOnFirstDayExist = 1

					-- Если обрабатываемая квота - квота НЕ на первый день и в первый день ее не обнаруживалось, то возвращаем ЗАПРОС
					if (@qtDate != @dateFrom and @quoteOnFirstDayExist = 0)
					begin
						--MEG00032854 Paul G 05.04.2011
						--раньше в этом месте анализ квот прекращался и возвращался запрос, но это неправильно. 
						set @dateRes = -1
					end
				end

				--MEG00035270 Paul G 14.06.2011
				--для дальнейшего анализа квоты необходимо выполнение условия:
				--если она не на заезд, то должна найтись другая квота на заезд, на день предоставления услуги, но в том же объекте квотирования
				--эта проверка нужна для того, чтобы при наличии 2-х объектов квотирования с разными разбиениями на заезды не пересекались
				if (@qtNotcheckin = 1 and not exists(select 1 from @tmpQuotes where qt_qoid = @qtQoId and qt_bycheckin = 0 and qt_date = @dateFrom))
				begin
					fetch next from qCur 
						into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
							@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, 
							@qtByroom, @qtType, @qtLong, @qtPlacesAll, @qtStop, @qtQoId

					continue
				end
				--End MEG00035270

				if(@qtNotcheckin <= 0 or @qtDate <> @dateFrom or @checkNoLongQuotes = @ALLDAYS_CHECK)
				begin
					if(@prevDate != @qtDate)
					begin

						if(@dateRes = 0 /*and @stopSale <= 0*/ and ((@wasLongQuota > 0 and @checkAfterWasLong <= 0 and @checkNoLongQuotes > 0) or (@wasAgentQuota > 0 and @checkAfterWasAgent <= 0 and @checkCommonQuotes > 0)))
							set @dateRes = -1
				
						if(@checkNoLongQuotes = @ALLDAYS_CHECK)
						begin
							if(len(@additional) > 0)
								set @additional = @additional + ','

							if(@dateRes = 0 and @stopSale <= 0)
								set @dateRes = @noPlacesResult

							set @additional = @additional + ltrim(str(@dateRes)) + ':' + ltrim(str(@dateAllPlaces))
						end
						else
						if(@dateRes <= 0 or @dateRes < @result or @qtStop > 0)
						begin
							set @result = @dateRes
							set @allPlacesRes = @dateAllPlaces -- total places in quota

							if(@result = 0 or @qtStop > 0) -- no places
							begin
								close qCur
								deallocate qCur

								insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
								values(0, 0, 0, 0, 0, 0, 0, 0, case when @qtStop > 0 then 0 else @noPlacesResult end, 0, 0, 0, '0=0:0')
								return
							end
						end
						else
						begin
							if(@wasLongQuota > 0)
								set @checkAfterWasLong = 1

							if(@wasAgentQuota > 0)
								set @checkAfterWasAgent = 1
						end
		
						if(datediff(day, @prevDate, @qtDate) > 1) -- there are days for wich quota doesn't exist
						begin
							set @result = -1 -- request
							if(@checkNoLongQuotes = @ALLDAYS_CHECK)
							begin
								set @tmpDate = dateadd(day, 1, @prevDate)
								while(@tmpDate < @qtDate)
								begin
									if(len(@additional) > 0)
										set @additional = @additional + ','

									set @additional = @additional + '-1:0'
									set @tmpDate = dateadd(day, 1, @tmpDate)
								end
							end
						end
							
						set @prevDate = @qtDate
						set @dateRes = 0
						set @dateAllPlaces = 0
						set @stopSale = 1
						set @wasLongQuota = 0
						set @wasAgentQuota = 0
						set @checkAfterWasLong = 0
						set @checkAfterWasAgent = 0

						-- MEG00024921, Danil, 10.02.2010: значения переменных предыдущей проверенной строки
						set @prevSubCode1 = @qtSubcode1
						set @prevSubCode2 = @qtSubcode2
						set @prevQtType = @qtType
						-- MEG00024921 End

					end
					
					if( -- MEG00024921, Danil, 10.02.2010: это условие было странным образом закомментарено + добавлена проверка на qtStop.
						-- Привел логику в соответствие с версией хранимки для 2007.2, где в аналогичной ситуации все работает.
						-- Проверку на qtStop перенес в следующий if
						(@stopSale <= 0 or ((@prevSubCode1 = @qtSubcode1 and @prevSubCode2 = @qtSubcode2) or @prevQtType <> @qtType))
						and not(@agentKey > 0 and @qtAgent = 0 and @wasAgentQuota > 0 and (@checkCommonQuotes <= 0))
								and not(@long > 0 and @qtLong = 0 and @wasLongQuota > 0 and (@checkNoLongQuotes <= 0)))
					begin
						if((@qtRelease is null or datediff(day, @currentDate, @qtDate) >= isnull(@qtRelease, 0))
							-- MEG00024921, Danil, 10.02.2010: сюда перенес проверку на qtStop из условия выше (по аналогии с версией 2007.2)
							and isnull(@qtStop, 0) = 0)
							-- MEG00024921 End
						begin
							if((@requestOnRelease <= 0 or @qtRelease is null or @qtRelease > 0) and
								@qtPlaces > 0 and not(@stopSale > 0 and @wasAgentQuota > 0 /*request for agents if they have agent quota and this quota is stopped (they try to reserve general quota by low cost)*/))
							begin

								--koshelev
								--TFS 7661 28.08.2012
								if (@days = 1)
								begin
									set @dateRes = @qtPlaces--@dateRes + @qtPlaces
								end
								else
								begin
									if (@qtPlaces = 1)
										set @dateRes = @qtPlaces
									else									
										set @dateRes = @dateRes + @qtPlaces
								end
								set @dateAllPlaces = @dateAllPlaces + @qtPlacesAll
								
								if (@qtPlaces < @result) -- result перезапишется
								begin
									set @svkeyRes = @qtSvkey
									set @codeRes = @qtCode
									set @subcode1Res = @qtSubcode1
									set @subcode2Res = @qtSubcode2
									set @agentRes = @qtAgent
									set @prkeyRes = @qtPrkey										
									set @byroomRes = @qtByroom
									set @typeRes = @qtType
									set @longRes = @qtLong
									set @releaseRes = @qtRelease
								end
							end
							else if(@qtPlaces > 0)
								set @dateRes = -1
						end
						else 
						begin
							if(isnull(@qtStop, 0) = 0 and @qtPlaces > 0)
								set @dateRes = @expiredReleaseResult -- no or request (0 or -1)
							else
							-- MEG00024921, Danil, 10.02.2010: добавил эту секцию, чтобы в случае, если не стоп, 
							-- а просто закончились места возвращалось @noPlacesResult
							if(isnull(@qtStop, 0) = 0)
							begin
								set @dateRes = @noPlacesResult -- no places
							end
							else
							-- MEG00024921 End
							begin
								set @dateRes = 0 -- stop sale
								set @result = 0
							end
						end
						--set @bycheckinRes =  1 - @qtNotcheckin
--set @bycheckinRes =  0
						
						-- MEG00024921, Danil, 10.02.2010: простановка признака "был ли стоп" для проверяемой даты
						-- опять же по аналогии с 2007.2
						if (isnull(@qtStop, 0) = 0)
							set @stopSale = 0
						-- MEG00024921 End
					end
					else if(@dateRes = 0 and @checkNoLongQuotes <> @ALLDAYS_CHECK)
					begin
						close qCur
						deallocate qCur
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						-- MEG00024921, Danil, 10.02.2010: добавил значение qt_additional и его заполнение
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
						values(0, 0, 0, 0, 0, 0, 0, 0, case when @stopSale > 0 then 0 else @noPlacesResult end, 0, 0, 0, '0=0:0')
						-- MEG00024921 End
						return 
					end

					if(@wasAgentQuota <= 0 and @qtAgent > 0) -- признак того, что агентская квота заведена, но закончилась
						set @wasAgentQuota = 1
					if(@wasLongQuota <= 0 and @qtLong > 0)  -- признак того, что квота на продолжительность заведена, но закончилась
						set @wasLongQuota = 1
				end

				-- MEG00024921, Danil, 10.02.2010: значения переменных предыдущей проверенной строки
				set @prevSubCode1 = @qtSubcode1
				set @prevSubCode2 = @qtSubcode2
				set @prevQtType = @qtType
				-- MEG00024921 End
				if (@isFirstDate = 0 and @prevDateOld = @qtDate and @prevDateRes > 0)
				begin
					set @dateRes = @prevDateRes
				end
				set @isFirstDate = 0
				set @prevDateRes = @dateRes
				set @prevDateOld = @qtDate
				fetch next from qCur into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
					@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, @qtByroom, @qtType, 
					@qtLong, @qtPlacesAll, @qtStop, @qtQoId
			end

			if(@checkNoLongQuotes = @ALLDAYS_CHECK)
			begin
				if(len(@additional) > 0)
					set @additional = @additional + ','

				if(@dateRes = 0 and @stopSale <= 0)
					set @dateRes = @noPlacesResult
				
				set @additional = @additional + ltrim(str(@dateRes)) + ':' + ltrim(str(@dateAllPlaces))
			end
			else
			if(@dateRes <= 0 or @dateRes < @result)
			begin
				set @result = @dateRes
				set @allPlacesRes = @dateAllPlaces -- total places in quota

				if(@result = 0) -- iano iao
					set @result = case when @stopSale > 0 then 0 else @noPlacesResult end
			end

			if(@qtDate <> @dateTo and ((@result > 0 and @bycheckinRes <= 0) or @checkNoLongQuotes = @ALLDAYS_CHECK)) -- ia iaio ec aao aeaiaciia eaioa ia caaaaaia
			begin
				set @result = -1 -- cai?in
				if(@checkNoLongQuotes = @ALLDAYS_CHECK)
				begin
					set @tmpDate = dateadd(day, 1, @qtDate)
					while(@tmpDate <= @dateTo)
					begin
						if(len(@additional) > 0)
							set @additional = @additional + ','

						set @additional = @additional + '-1:0'
						set @tmpDate = dateadd(day, 1, @tmpDate)
					end
				end
			end
		end
		else
		begin
			set @result = -1
			if(@checkNoLongQuotes = @ALLDAYS_CHECK)
			begin
				set @tmpDate = @dateFrom
				while(@tmpDate <= @dateTo)
				begin
					if(len(@additional) > 0)
						set @additional = @additional + ','

					set @additional = @additional + '-1:0'
					set @tmpDate = dateadd(day, 1, @tmpDate)								
				end
			end
		end	
		
		if(@checkNoLongQuotes <> @ALLDAYS_CHECK)
		begin
			if (@result > 0)
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
				values(@svkeyRes, @codeRes, @subcode1Res, @subcode2Res, @agentRes, 
					@prkeyRes, @bycheckinRes, @byroomRes, @result, @allPlacesRes, @typeRes, @longRes)
			else
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
				values(0, 0, 0, 0, 0, 0, 0, 0, @result, 0, 0, 0)
		end
		else
		begin
				set @additional = ltrim(str(@long)) + '=' + @additional
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @additional)
		end
		
		return 
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
/* begin fn_mwGetFilterPart.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwGetFilterPart]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwGetFilterPart]
GO

--<DATE>2014-01-30</DATE>
--<VERSION>2009.2.20.7</VERSION>
CREATE FUNCTION [dbo].[mwGetFilterPart](
	@filter nvarchar(MAX),
	@prefix nvarchar(50))
	returns nvarchar(512)
as
begin
	declare @result nvarchar(512)
	declare @pos int, @lastPos int, @tmpPos1 int, @tmpPos2 int, @tmpPos3 int, @tmpPos4 int 
	
	set @pos = charindex(@prefix, @filter)
	if(@pos > 0)
	begin
		set @tmpPos1 = charindex('and', @filter, @pos)
		if(@tmpPos1 < @pos)
			set @tmpPos1 = null
		set @tmpPos2 = charindex('or', @filter, @pos)
		if(@tmpPos2 < @pos)
			set @tmpPos2 = null
		set @tmpPos3 = charindex(')', @filter, @pos)
		if(@tmpPos3 < @pos)
			set @tmpPos3 = null
		set @tmpPos4 = charindex('in', @filter, @pos)
		if(@tmpPos4 < @pos or @tmpPos3 is null or @tmpPos4 > @tmpPos3)
			set @tmpPos4 = null
		else
			set @tmpPos3 = @tmpPos3 + 1


		if(@tmpPos1 is not null)
			set @lastPos = @tmpPos1
		if(@tmpPos2 is not null and @tmpPos2 < @lastPos)
			set @lastPos = @tmpPos2
		if(@tmpPos3 is not null and @tmpPos3 < @lastPos)
			set @lastPos = @tmpPos3
		
		if(@lastPos is null)
			set @result = substring(@filter, @pos, len(@filter) - @pos + 1)
		else
			set @result = substring(@filter, @pos, @lastPos - @pos)
	end
	
	return @result
end
GO

GRANT EXEC ON [dbo].[mwGetFilterPart] TO PUBLIC
GO
/*********************************************************************/
/* end fn_mwGetFilterPart.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalculatePriceList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalculatePriceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CalculatePriceList]
GO

CREATE PROCEDURE [dbo].[CalculatePriceList]
  (
	@nPriceTourKey int,			-- РєР»СЋС‡ РѕР±СЃС‡РёС‚С‹РІР°РµРјРѕРіРѕ С‚СѓСЂР°
	@nCalculatingKey int,		-- РєР»СЋС‡ РёС‚РµСЂР°С†РёРё РґРѕР·Р°РїРёСЃРё
	@dtSaleDate datetime,		-- РґР°С‚Р° РїСЂРѕРґР°Р¶Рё
	@nNullCostAsZero smallint,	-- СЃС‡РёС‚Р°С‚СЊ РѕС‚СЃСѓС‚СЃС‚РІСѓСЋС‰РёРµ С†РµРЅС‹ РЅСѓР»РµРІС‹РјРё (РєСЂРѕРјРµ РїСЂРѕР¶РёРІР°РЅРёСЏ) 0 - РЅРµС‚, 1 - РґР°
	@nNoFlight smallint,		-- РїСЂРё РѕС‚СЃСѓС‚СЃС‚РІРёРё РїРµСЂРµР»С‘С‚Р° РІ СЂР°СЃРїРёСЃР°РЅРёРё 0 - РЅРёС‡РµРіРѕ РЅРµ РґРµР»Р°С‚СЊ, 1 - РЅРµ РѕР±СЃС‡РёС‚С‹РІР°С‚СЊ С‚СѓСЂ, 2 - РёСЃРєР°С‚СЊ РїРѕРґС…РѕРґСЏС‰РёР№ РїРµСЂРµР»С‘С‚ (РµСЃР»Рё РЅРµ РЅР°Р№РґРµРЅРѕ - РЅРµ СЂР°СЃСЃС‡РёС‚С‹РІР°С‚СЊ)
	@nUpdate smallint,			-- РїСЂРёР·РЅР°Рє РґРѕР·Р°РїРёСЃРё 0 - СЂР°СЃС‡РµС‚, 1 - РґРѕР·Р°РїРёСЃСЊ
	@nUseHolidayRule smallint		-- РџСЂР°РІРёР»Рѕ РІС‹С…РѕРґРЅРѕРіРѕ РґРЅСЏ: 0 - РЅРµ РёСЃРїРѕР»СЊР·РѕРІР°С‚СЊ, 1 - РёСЃРїРѕР»СЊР·РѕРІР°С‚СЊ
  )
AS
--<DATE>2013-12-20</DATE>
---<VERSION>9.2.20.4</VERSION>

--РїСЂРѕРІРµСЂСЏРµРј РЅР°СЃС‚СЂРѕР№РєСѓ СЃРѕ СЃС‚СЂР°РЅРѕР№, РµСЃР»Рё СЃРѕРІРїР°Р»Р° - Р·Р°РїСѓСЃРєР°РµРј РЅРѕРІС‹Р№ CalculatePriceList
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
declare @dDateBeg1 datetime -- РґР°С‚Р° РЅР°С‡Р°Р»Р° 1РіРѕ РїРµСЂРёРѕРґР°
declare @dDateBeg3 datetime -- РґР°С‚Р° РЅР°С‡Р°Р»Р° 2,3РіРѕ РїРµСЂРёРѕРґР°
declare @dDateEnd1 datetime -- РґР°С‚Р° РѕРєРѕРЅС‡Р°РЅРёСЏ 1РіРѕ РїРµСЂРёРѕРґР°
declare @dDateEnd3 datetime -- РґР°С‚Р° РѕРєРѕРЅС‡Р°РЅРёСЏ 2,3РіРѕ РїРµСЂРёРѕРґР°
--
declare @sDetailed varchar(100) -- РЅРµ РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ, РЅРµРѕР±С…РѕРґРёРјР° С‚РѕР»СЊРєРѕ РґР»СЏ РїРµСЂРµРґР°С‡Рё РІ РєР°С‡РµСЃС‚РІРµ РїР°СЂР°РјРµС‚СЂР° РІ GSC
declare @sBadRate varchar(3)
declare @nettoDetail nvarchar(max)
declare @dtBadDate DateTime
--
declare @nSPId int -- РІРѕР·РІСЂР°С‰Р°РµС‚СЃСЏ РёР· GSC, С„Р°РєС‚РёС‡РµСЃРєРё СЌС‚Рѕ РєР»СЋС‡ РёР· ServicePrices
declare @nPDId int 
declare @nBruttoWithCommission money

--РїРµСЂРµРјРµРЅРЅС‹Рµ РґР»СЏ СЂР°Р·Р±РёРµРЅРёСЏ СЃРіСЂСѓРїРїРёСЂРѕРІР°РЅРЅС‹С… С†РµРЅ
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

--РѕСЃСѓС‰РµСЃС‚РІР»СЏРµС‚СЃСЏ РїРµСЂРµСЃС‡РµС‚ РїСЂР°Р№СЃР° РїР»Р°РЅРёСЂРѕРІС‰РёРєРѕРј
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

--if (@nCalculatingKey is null)
--begin
--	select top 1 @nCalculatingKey = CP_Key from CalculatingPriceLists where CP_PriceTourKey = @nPriceTourKey and CP_Update = 0
--	update tp_turdates set td_update = 0 where td_tokey = @nPriceTourKey
--	update tp_lists set ti_update = 0 where ti_tokey = @nPriceTourKey
--end

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

declare @calculatingPriceListsExists smallint -- 0 - CalculatingPriceLists РЅРµС‚, 1 - CalculatingPriceLists РµСЃС‚СЊ РІ Р±Р°Р·Рµ

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

	--Р—Р°СЃРµРєР°РµРј РІСЂРµРјСЏ РЅР°С‡Р°Р»Р° СЂР°СЃСЃС‡РµС‚Р° begin
	declare @beginPriceCalculate datetime
	set @beginPriceCalculate = GETDATE()
	SET @sHI_Text = CONVERT(varchar(30),@beginPriceCalculate,121)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11009, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Р—Р°СЃРµРєР°РµРј РІСЂРµРјСЏ РЅР°С‡Р°Р»Р° СЂР°СЃСЃС‡РµС‚Р° end
	
	-- koshelev 15.02.2011
	-- РґР»СЏ РїРѕРґР±РѕСЂР° РїРµСЂРµР»РµС‚РѕРІ
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

--------------------------------------- РёС‰РµРј РїРѕРґС…РѕРґСЏС‰РёР№ РїРµСЂРµР»РµС‚, РµСЃР»Рё СЃС‚РѕРёС‚ РЅР°СЃС‚СЂРѕР№РєР° РїРѕРґР±РѕСЂР° РїРµСЂРµР»РµС‚Р° --------------------------------------

	------ РїСЂРѕРІРµСЂСЏРµРј, Р° РїРѕРґС…РѕРґРёС‚ Р»Рё С‚РµРєСѓС‰РёР№ СЂРµР№СЃ, СѓРєР°Р·Р°РЅРЅС‹Р№ РІ С‚СѓСЂРµ ----
	--Update	TP_Flights with(rowlock) Set 	TF_CodeNew = TF_CodeOld,
	--			TF_PRKeyNew = TF_PRKeyOld
	--Where	(SELECT count(*) FROM AirSeason  with(nolock) WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') > 0 
	--	and TF_TOKey = @nPriceTourKey	

	exec sp_executesql 
	N'
	update TP_Flights set TF_CodeNew = null, TF_PRKeyNew = null, TF_SubCode1New = null where TF_TOKey = @nPriceTourKey

	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1, TF_CalculatingKey = @nCalculatingKey
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey 
			and TF_Date BETWEEN ISNULL(CS_Date, ''1900-01-01'') AND ISNULL(CS_DateEnd, ''2053-01-01'') 
			and TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(CS_CHECKINDATEEND, ''2053-01-01'')
			and (ISNULL(CS_Week, '''') = '''' or CS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'') 
			and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long))
			and TF_TOKey = @nPriceTourKey

	If @nNoFlight = 2
	BEGIN
		------ РїСЂРѕРІРµСЂСЏРµРј, Р° РµСЃС‚СЊ Р»Рё Сѓ РґР°РЅРЅРѕРіРѕ РїР°СЂРЅРµСЂР° РїРѕ СЂРµР№СЃСѓ, С†РµРЅС‹ РЅР° РґСЂСѓРіРёРµ СЂРµР№СЃС‹ РІ СЌС‚РѕРј Р¶Рµ РїР°РєРµС‚Рµ ----
		IF exists(SELECT TF_ID FROM TP_Flights with(nolock) WHERE TF_TOKey = @nPriceTourKey and TF_CodeNew is Null)
		begin
			print ''РџРѕРґР±РёСЂР°РµРј РїРµСЂРµР»РµС‚''
			
			declare @newFlightsPartnerTable table
			(
				-- РёРґРµРЅС‚РёС„РёРєР°С‚РѕСЂ
				xId int identity(1,1),
				-- РєР»СЋС‡ СѓСЃР»СѓРіРё РїРµСЂРµР»РµС‚
				xTFId int,
				-- РєР»СЋС‡ РёСЃС…РѕРґРЅРѕРіРѕ РїР°СЂС‚РЅРµСЂР°
				xPRKey int,
				-- РєР»СЋС‡ РїР°СЂС‚РЅРµСЂР° РєРѕС‚РѕСЂРѕРіРѕ РїРѕРґРѕР±СЂР°Р»Рё
				xPRKeyNew int,
				-- РєР»СЋС‡ РїРµСЂРµР»РµС‚Р°
				xCHKey int,
				-- РєР»СЋС‡ С‚Р°СЂРёС„Р° РЅР° РїРµСЂРµР»РµС‚
				xASKey int
			)
			-- РїРѕРґР±РёСЂР°РµРј РїРѕРґС…РѕРґСЏС‰РёРµ РЅР°Рј РїРµСЂРµР»РµС‚С‹
			insert into @newFlightsPartnerTable (xTFId, xCHKey, xASKey, xPRKey, xPRKeyNew)
			SELECT TF_Id, CH_Key, CS_SubCode1, TF_PRKeyOld, CS_PRKey
			FROM AirSeason with(nolock), Charter with(nolock), Costs with(nolock), TP_Flights with(nolock)
			WHERE CH_CityKeyFrom = TF_Subcode2 and
			CH_CityKeyTo = TF_CTKey and
			CS_Code = CH_Key and
			AS_CHKey = CH_Key and
			CS_SVKey = 1 and
			(	isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = CS_SubCode1), '''')
				= 
				isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = TF_Subcode1), '''')
			) and
			CS_PKKey = TF_PKKey and
			TF_Date BETWEEN AS_DateFrom and AS_DateTo and
			TF_Date BETWEEN CS_Date and CS_DateEnd and
			AS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'' and
			(ISNULL(CS_Week, '''') = '''' or CS_Week LIKE ''%''+cast(datepart(weekday, TF_Date)as varchar(1))+''%'') and
			(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long) and
			TF_CodeNew is Null and 
			TF_TOKey = @nPriceTourKey
			group by TF_Id, CH_Key, CS_SubCode1, TF_PRKeyOld, CS_PRKey
			
			-- СѓРґР°Р»СЏРµРј РїРѕРІС‚РѕСЂСЏСЋС‰РёРµСЃСЏ (РµСЃР»Рё РїРѕРґРѕР±СЂР°Р»РѕСЃСЊ РЅРµСЃРєРѕР»СЊРєРѕ РїРµСЂРµР»РµС‚РѕРІ)
			delete @newFlightsPartnerTable
			from @newFlightsPartnerTable as a
			where a.xId != (select top 1 b.xId 
							from @newFlightsPartnerTable as b 
							where b.xTFId = a.xTFId
							-- Рё РїСЂРёРѕСЂРµС‚РµС‚РЅРµРµ С‚Рµ РїРµСЂРµР»РµС‚С‹ РІ РєРѕС‚РѕСЂС‹С… РїР°СЂС‚РЅРµСЂС‹ СЃРѕРІРїР°РґР°СЋС‚ СЃ РёСЃС…РѕРґРЅС‹Рј
							order by case when b.xPRKey = b.xPRKeyNew then 0 else 1 end)
			
			-- РѕР±РЅРѕРІР»СЏРµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ РЅР°Р№РґРµРЅРѕРј РїРµСЂРµР»РµС‚Рµ
			update TP_Flights with(rowlock)
			set TF_CodeNew = xCHKey,
			TF_SubCode1New = xASKey,
			TF_PRKeyNew = xPRKeyNew,
			TF_CalculatingKey = @nCalculatingKey
			from TP_Flights with(rowlock) join @newFlightsPartnerTable on TF_Id = xTFId
			
			print ''Р—Р°РєРѕРЅС‡РёР»Рё РїРѕРґР±РѕСЂ РїРµСЂРµР»РµС‚РѕРІ''
		end
	END
	', N'@nPriceTourKey int, @nCalculatingKey int, @nNoFlight smallint', @nPriceTourKey, @nCalculatingKey, @nNoFlight
	
	-----РµСЃР»Рё РїРµСЂРµР»РµС‚ С‚Р°Рє Рё РЅРµ РЅР°Р№РґРµРЅ, С‚Рѕ РІ РїРѕР»Рµ TF_CodeNew Р±СѓРґРµС‚ NULL

	--------------------------------------- Р·Р°РєРѕРЅС‡РёР»Рё РїРѕРёСЃРє РїРѕРґС…РѕРґСЏС‰РµРіРѕ РїРµСЂРµР»РµС‚Р° --------------------------------------
	--if ISNULL((select to_update from [dbo].tp_tours with(nolock) where to_key = @nPriceTourKey),0) <> 1
	
	declare @calcPricesCount int
	
	exec sp_executesql			
	N'	
	
	if (1 = 1)
	BEGIN

		update [dbo].tp_tours with(rowlock) set to_update = 1 where to_key = @nPriceTourKey
		Set @nTotalProgress = 4
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	
		--------------------------------------- СЃРѕС…СЂР°РЅСЏРµРј С†РµРЅС‹ РІРѕ РІСЂРµРјРµРЅРЅРѕР№ С‚Р°Р±Р»РёС†Рµ --------------------------------------
		CREATE TABLE #TP_Prices
		(
			[xTP_Key] [int] PRIMARY KEY NOT NULL ,
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
		---------------------------------------РљРћРќР•Р¦  СЃРѕС…СЂР°РЅСЏРµРј С†РµРЅС‹ РІРѕ РІСЂРµРјРµРЅРЅРѕР№ С‚Р°Р±Р»РёС†Рµ --------------------------------------
		

		---------------------------------------СЂР°Р·Р±РёРІР°РµРј РґР°РЅРЅС‹Рµ РІ С‚Р°Р±Р»РёС†Р°С… tp_prices РїРѕ РґР°С‚Р°Рј
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

		----------------------------------------------------------- Р—РґРµСЃСЊ Р°РїРґРµР№С‚РёРј TS_CHECKMARGIN Рё TD_CHECKMARGIN
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
		----------------------------------------------------------- Р—РґРµСЃСЊ Р°РїРґРµР№С‚РёРј TS_CHECKMARGIN Рё TD_CHECKMARGIN

--		update TP_Services set ts_tempgross = null where ts_tokey = @nPriceTourKey

		SELECT @round = ST_RoundService FROM Setting
		--MEG00036108 СѓРІРµР»РёС‡РёР» Р·РЅР°С‡РµРЅРёРµ
		set @nProgressSkipLimit = 10000

		set @nProgressSkipCounter = 0
		--Set @nTotalProgress = @nTotalProgress + 1
		--update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
		--СЃС‡РёС‚Р°РµРј СЃРєРѕР»СЊРєРѕ Р·Р°РїРёСЃРµР№ РЅР°РґРѕ РїРѕСЃС‡РёС‚Р°С‚СЊ
		set @NumPrices = ((select count(1) from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) * (select count(1) from tp_turdates with(nolock) where td_tokey = @nPriceTourKey and td_update = @nUpdate))

		if @NumPrices <> 0
			set @nDeltaProgress = (97.0 - 5) / @NumPrices
		else
			set @nDeltaProgress = 97.0 - 5

		exec GetNKeys ''TP_PRICES'', @NumPrices, @nTP_PriceKeyMax output
		set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @NumPrices + 1
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

		insert into #TP_Prices (xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey, xTP_CalculatingKey) 
		select tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey
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
			
			--РґР°РЅРЅС‹С… РЅРµ РЅР°С€Р»РѕСЃСЊ, РІС‹С…РѕРґРёРј
			if @@fetch_status <> 0 and @nPrevVariant = -1
				break
				
			--РѕС‡РёС‰Р°РµРј РїРµСЂРµРјРµРЅРЅС‹Рµ, Р·Р°РїРёСЃС‹РІР°РµРј РґР°РЅРЅС‹Рµ РІ С‚Р°Р±Р»РёС†Сѓ #TP_Prices
			if @nPrevVariant <> @variant or @dtPrevDate <> @turdate or @@fetch_status <> 0
			BEGIN
				--Р·Р°РїРёСЃС‹РІР°РµРј РґР°РЅРЅС‹Рµ РІ С‚Р°Р±Р»РёС†Сѓ #TP_Prices
				if @nPrevVariant <> -1
				begin
					if @price_brutto is not null
					BEGIN
						exec RoundPriceList @round, @price_brutto output

						if exists(select 1 from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant)
						begin
							--select @nCalculatingKey
							if (@isPriceListPluginRecalculation = 0)
								update #TP_Prices set xtp_gross = @price_brutto, xtp_calculatingkey = @nCalculatingKey, xtp_key = @nTP_PriceKeyCurrent where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
							else
								update #TP_Prices set xtp_gross = @price_brutto, xtp_key = @nTP_PriceKeyCurrent where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
							set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
						end
						else if (@isPriceListPluginRecalculation = 0)
						begin
							--select @nCalculatingKey
							
							insert into #TP_Prices (xtp_key, xtp_tokey, xtp_datebegin, xtp_dateend, xtp_gross, xtp_tikey, xTP_CalculatingKey) 
							values (@nTP_PriceKeyCurrent, @nPriceTourKey, @dtPrevDate, @dtPrevDate, @price_brutto, @nPrevVariant, @nCalculatingKey)
							
							set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
						end
					END
					ELSE
					BEGIN
						delete from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
					END
				end
			
				--РѕС‡РёС‰Р°РµРј РґР°РЅРЅС‹Рµ
				if @@fetch_status = 0
				begin
					if @nTP_PriceKeyCurrent > @nTP_PriceKeyMax
					BEGIN
						exec GetNKeys ''TP_PRICES'', @NumPrices, @nTP_PriceKeyMax output
						set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @NumPrices + 1
					END
					
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

			--РїРµСЂРµРїРёСЃС‹РІР°РµРј РґР°РЅРЅС‹Рµ РІ С‚Р°Р±Р»РёС†Сѓ tp_prices
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
				-- РґРѕР±Р°РІРёР» РїСЂРѕРІРµСЂРєСѓ РїСЂРёР·РЅР°РєР° РЅРµСЂР°СЃСЃС‡РёС‚С‹РІР°РµРјРѕР№ СѓСЃР»СѓРіРё
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

		----------------------------------------------------- РІРѕР·РІСЂР°С‰Р°РµРј РѕР±СЂР°С‚РЅРѕ С†РµРЅС‹ ------------------------------------------------------

		Set @nTotalProgress = 97
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
		--СѓРґР°Р»РµРЅРёРµ РёР· РІРµР±Р°
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
			
		INSERT INTO TP_Prices with(rowlock) (tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey) 
			select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey, xTP_CalculatingKey 
			from #TP_Prices 

		-----------------------------------------------------РљРћРќР•Р¦ РІРѕР·РІСЂР°С‰Р°РµРј РѕР±СЂР°С‚РЅРѕ С†РµРЅС‹ ------------------------------------------------------

		update tp_lists with(rowlock) set ti_update = 0 where ti_tokey = @nPriceTourKey
		update tp_turdates with(rowlock) set td_update = 0, td_checkmargin = 0 where td_tokey = @nPriceTourKey
		Set @nTotalProgress = 99
		update tp_tours with(rowlock) set to_progress = @nTotalProgress, to_update = 0, to_updatetime = GetDate(),
							TO_CalculateDateEnd = GetDate(), TO_PriceCount = (Select Count(*) 
			From TP_Prices with(nolock) Where TP_ToKey = to_key) where to_key = @nPriceTourKey
		update tp_services with(rowlock) set ts_checkmargin = 0 where ts_tokey = @nPriceTourKey

	END

	update CalculatingPriceLists with(rowlock) set CP_Status = 0, CP_CreateDate = GetDate(), CP_StartTime = null where CP_PriceTourKey = @nPriceTourKey
	------------------------------------		

	--Р—Р°РїРѕР»РЅРµРЅРёРµ РїРѕР»РµР№ РІ С‚Р°Р±Р»РёС†Рµ tp_lists
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
	, @calcPricesCount int
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
	, @calcPricesCount
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

	--Р—Р°СЃРµРєР°РµРј РІСЂРµРјСЏ РѕРєРѕРЅС‡Р°РЅРёСЏ СЂР°СЃСЃС‡РµС‚Р° begin
	declare @endPriceCalculate datetime
	set @endPriceCalculate = GETDATE()
	SET @sHI_Text = CONVERT(varchar(30),@endPriceCalculate,121)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11010, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Р—Р°СЃРµРєР°РµРј РІСЂРµРјСЏ РѕРєРѕРЅС‡Р°РЅРёСЏ СЂР°СЃСЃС‡РµС‚Р° end

	--Р—Р°РїРёСЃС‹РІР°РµРј РєРѕР»-РІРѕ СЂР°СЃСЃС‡РёС‚Р°РЅРЅС‹С… С†РµРЅ begin
	SET @sHI_Text = CONVERT(varchar(10),@calcPricesCount)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11011, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Р—Р°РїРёСЃС‹РІР°РµРј РєРѕР»-РІРѕ СЂР°СЃСЃС‡РёС‚Р°РЅРЅС‹С… С†РµРЅ end

	--Р—Р°РїРёСЃС‹РІР°РµРј СЃРєРѕСЂРѕСЃС‚СЊ СЂР°СЃС‡РµС‚Р° С†РµРЅ begin
	declare @calculatingSpeed decimal(10,2), @seconds int
	set @seconds = datediff(ss,@beginPriceCalculate,@endPriceCalculate)
	if @seconds = 0
		set @seconds = 1
	set @calculatingSpeed = @calcPricesCount / @seconds
	SET @sHI_Text = CONVERT(varchar(10),@calculatingSpeed)
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11012, null, @sHI_Text, null, @nUpdate, null, null, 0
	--Р—Р°РїРёСЃС‹РІР°РµРј СЃРєРѕСЂРѕСЃС‚СЊ СЂР°СЃС‡РµС‚Р° С†РµРЅ end
	
	if (@nIsEnabled = 1)
	begin
		if (@isPriceListPluginRecalculation = 0)
			EXEC FillMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
		else
			EXEC FillMasterWebSearchFields @nPriceTourKey, null
	end

	Return 0
END
GO

grant execute on [dbo].[CalculatePriceList] to public
GO
/*********************************************************************/
/* end sp_CalculatePriceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckQuotaExist.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckQuotaExist]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckQuotaExist]
GO

CREATE PROCEDURE [dbo].[CheckQuotaExist]
(
--<DATE>2014-02-10</VERSION>
--<VERSION>2009.2.24</VERSION>
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

-- karimbaeva 28-04-2012 чтобы не выводилось сообщение о недостатке квоты на дополнительное место, если квота последняя и размещение на номер 
IF @SVKey = 3
begin
	if exists(SELECT TOP 1 1 FROM QuotaObjects, Quotas, QuotaDetails, QuotaParts, HotelRooms WHERE QD_QTID=QT_ID and QD_ID=QP_QDID and QO_QTID=QT_ID
	and HR_Key=@SubCode1 and HR_MAIN=0 and QT_ByRoom = 1 and (QP_AgentKey=@AgentKey or QP_AgentKey is null)
	and (QT_PRKey=@PRKey or QT_PRKey=0) and QO_Code=@Code and QD_Date between @DateBeg and @DateEnd and QP_Date = QD_Date
	and QP_ID in (select SD_QPID
					from ServiceByDate as SBD2 join RoomPlaces as RP2 on SBD2.SD_RPID = RP2.RP_ID
					where RP2.RP_Type = 0))
	begin
		set @Quota_CheckInfo = 0
		Set @Quota_CheckState = 1
		If @StopExist > 0
		BEGIN
			Set @Quota_CheckState = 2						
			Set @Quota_CheckDate = @StopDate
		END
		return 0
	end
end
	
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
			
	--print @Query

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

If ISNULL(@TypeOfResult,-1)=1
	delete from @Tbl_DQ where TMP_Count < @Pax

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
		
		Set @Places_Count = (select top 1 SUM(TMP_COUNT) from @Tbl_DQ
								where TMP_Count > 0 and TMP_ByRoom = 0 and TMP_ReleaseIgnore = 0 GROUP BY TMP_Type,TMP_SubCode1,TMP_Partner order by 1 desc)
		Set @Places_Count_ReleaseIgnore = (select top 1 SUM(TMP_COUNT) from @Tbl_DQ
								where TMP_Count > 0 and TMP_ByRoom = 0 and TMP_ReleaseIgnore = 1 GROUP BY TMP_Type,TMP_SubCode1,TMP_Partner order by 1 desc)
		
		If (@SVKey in (3) or (@SVKey=8 and EXISTS(SELECT TOP 1 1 FROM [Service] WHERE SV_KEY=@SVKey AND SV_QUOTED=1)))
		begin
			Set @Rooms_Count = (select top 1 SUM(TMP_COUNT) from @Tbl_DQ
								where TMP_Count > 0 and TMP_ByRoom = 1 and TMP_ReleaseIgnore = 0 GROUP BY TMP_Type,TMP_SubCode1,TMP_Partner order by 1 desc)
			Set @Rooms_Count_ReleaseIgnore = (select top 1 SUM(TMP_COUNT) from @Tbl_DQ
												where TMP_Count > 0 and TMP_ByRoom = 1 and TMP_ReleaseIgnore = 1 GROUP BY TMP_Type,TMP_SubCode1,TMP_Partner order by 1 desc)
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
/* end sp_CheckQuotaExist.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetCalendarTourDates.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetCalendarTourDates]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[GetCalendarTourDates]
END
GO

--<VERSION>9.2.20.7</VERSION>
--<DATE>2014-01-30</DATE>
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

	DECLARE @sql NVARCHAR(MAX)
	SET @sql = 'SELECT DISTINCT DATEDIFF(ss, ''1970-01-01'', TP_TurDates.TD_Date) AS [key],
					CONVERT(varchar, TP_TurDates.TD_Date, 4) AS name,
					TP_TurDates.TD_Date
				FROM TP_TurDates 
					INNER JOIN mwSpoData with(nolock) ON TP_TurDates.TD_TOKey = mwSpoData.sd_tourkey ' +
				@quotaNeedFromPart + 
				'WHERE TP_TurDates.TD_Date > DATEADD(day, - 1, GETDATE())
					AND mwSpoData.sd_ctkeyfrom IN (' + @departFromKeys + ')
					AND mwSpoData.sd_cnkey IN (' + @countryKeys + ')' +
				@quotaNeedWherePart
             
	IF (@tourKeys IS NOT NULL)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourkey IN (' + @tourKeys + ') AND exists(SELECT TOP 1 1 FROM ' + @tableName +
			' WHERE pt_tourkey IN (' + @tourKeys + ') AND pt_tourdate = TP_TurDates.TD_Date) '
	END

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
    
    SET @sql += ' ORDER BY TP_TurDates.TD_Date '

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
--<VERSION>2009.2.24</VERSION>
--<DATE>2013-12-25</DATE>
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
		IF @Service_NDays is null
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
				and (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select QL_QPID From QuotaLimitations (nolock) WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID))))
				and ISNULL(QP_IsDeleted,0)=0
				and ISNULL(QD_IsDeleted,0)=0			
				and (@DLKey is null or (@DLKey is not null
				and ((QD_LongMin is null and QD_LongMax is null) or (@Service_Duration >= QD_LongMin and @Service_Duration <= QD_LongMax)) and ((QO_SubCode1 = -1) or (QO_SubCode1 in (0,@Object_SubCode1))) 
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
				and (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select QL_QPID From QuotaLimitations (nolock) WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID))))
				and ISNULL(QP_IsDeleted,0)=0
				and ISNULL(QD_IsDeleted,0)=0			
				and (@DLKey is null or (@DLKey is not null
				and (QP_Durations='' or PATINDEX('%,' + CAST(@Service_Duration AS VARCHAR) + ',%', ',' + QP_Durations + ',') != 0)
				and ((QO_SubCode1 = -1) or (QO_SubCode1 in (0,@Object_SubCode1))) 
				and ((QO_SubCode2 = -1) or (QO_SubCode2 in (0,@Object_SubCode2)))))
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
				--print @Temp
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
/* begin sp_mwSyncDictionaryData.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwSyncDictionaryData]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwSyncDictionaryData]
GO

create procedure [dbo].[mwSyncDictionaryData] 
	@update_search_table smallint = 0, -- нужно ли синхронизировать данные в mwPriceDataTable
	@update_fields varchar(1024) = NULL -- какие именно данные нужно синхронизировать
as
begin

	--<VERSION>2009.2.20.2</VERSION>
	--<DATE>2014-01-31</DATE>

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
	
	-- Признак того, откуда брать основые места
	-- Если @isMainPlacesFromAccomodation = 1, основные места беруться из таблицы Accmdmentype, иначе из Rooms
	-- Синхронизация основных мест происходит если pt_main > 0
	declare @isMainPlacesFromAccomodation bit
	select @isMainPlacesFromAccomodation = SS_ParmValue
	from dbo.SystemSettings
	where SS_ParmName='MWAccomodationPlaces'

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
	set @pdtUpdatePackageSize = 10000

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
	
	-- страна
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='COUNTRY')
	begin
		-- mwSpoDataTable
		while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 1 from tbl_country with(nolock) 
				where sd_cnkey = cn_key and isnull(sd_cnname, '-1') <> isnull(cn_name, '')))
		begin
			update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
			set
				sd_cnname = isnull(cn_name, '')
			from
				tbl_country
			where
				sd_cnkey = cn_key and 
				isnull(sd_cnname, '-1') <> isnull(cn_name, '')
		end
	end
	
	-- отель
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='HOTEL')
	begin
		-- mwSpoDataTable
		while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 1 from dbo.hoteldictionary with(nolock) where
				sd_hdkey = hd_key
				and (
					isnull(sd_hdstars, '-1') <> isnull(hd_stars, '') or 
					isnull(sd_ctkey, -1) <> isnull(hd_ctkey, 0) or 
					isnull(sd_rskey, -1) <> isnull(hd_rskey, 0) or 
					isnull(sd_hdname, '-1') <> isnull(hd_name, '') or 
					isnull(sd_hotelurl, '-1') <> isnull(hd_http, '')
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
				and (
					isnull(sd_hdstars, '-1') <> isnull(hd_stars, '') or 
					isnull(sd_ctkey, -1) <> isnull(hd_ctkey, 0) or 
					isnull(sd_rskey, -1) <> isnull(hd_rskey, 0) or 
					isnull(sd_hdname, '-1') <> isnull(hd_name, '') or 
					isnull(sd_hotelurl, '-1') <> isnull(hd_http, '')
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
								and (
									isnull(pt_hdstars, ''-1'') <> isnull(hd_stars, '''') or 
									isnull(pt_ctkey, -1) <> isnull(hd_ctkey, 0) or
									isnull(pt_rskey, -1) <> isnull(hd_rskey, 0) or
									isnull(pt_hdname, ''-1'') <> isnull(hd_name, '''') or
									isnull(pt_hotelurl, ''-1'') <> isnull(hd_http, '''')
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
									and (
										isnull(pt_hdstars, ''-1'') <> isnull(hd_stars, '''') or 
										isnull(pt_ctkey, -1) <> isnull(hd_ctkey, 0) or
										isnull(pt_rskey, -1) <> isnull(hd_rskey, 0) or
										isnull(pt_hdname, ''-1'') <> isnull(hd_name, '''') or
										isnull(pt_hotelurl, ''-1'') <> isnull(hd_http, '''')
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
	
	-- город отправления
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='CITY')
	begin
		-- mwSpoDataTable
		while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 1 from citydictionary with(nolock) 
				where sd_ctkeyfrom <> 0 and sd_ctkeyfrom = ct_key and isnull(sd_ctfromname, '-1') <> isnull(ct_name, '')))
		begin
			update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
			set
				sd_ctfromname = isnull(ct_name,'')
			from
				dbo.citydictionary
			where
				sd_ctkeyfrom <> 0	-- город отправления -Без перелета- не обновляем, это константа (см. FillMasterwebSearchFields)
				and sd_ctkeyfrom = ct_key
				and isnull(sd_ctfromname, '-1') <> isnull(ct_name, '')
		end

		while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 1 from citydictionary with(nolock) 
				where sd_ctkey = ct_key and isnull(sd_ctname, '-1') <> isnull(ct_name, '')
			)
		)
		begin
			update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
			set
				sd_ctname = isnull(ct_name,'')
			from
				dbo.citydictionary
			where
				sd_ctkey = ct_key and 
				isnull(sd_ctname, '-1') <> isnull(ct_name, '')
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
									pt_ctkey = ct_key and isnull(pt_ctname, ''-1'') <> isnull(ct_name, '''')
								)
							)
							begin
								update top (@pdtUpdatePackageSize) @tableName
								set
									pt_ctname = isnull(ct_name,'''')
								from
									dbo.citydictionary
								where
									pt_ctkey = ct_key and 
									isnull(pt_ctname, ''-1'') <> isnull(ct_name, '''')
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
	
	--курорт
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='RESORT')
	begin
		-- mwSpoDataTable
		while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock)
			where exists(select top 1 1 from dbo.resorts with(nolock) where
				sd_rskey = rs_key and isnull(sd_rsname, '-1') <> isnull(rs_name, '')
			)
		)
		begin
			update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
			set
				sd_rsname = isnull(rs_name,'')
			from
				dbo.resorts
			where
				sd_rskey = rs_key and 
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
									pt_rskey = rs_key and isnull(pt_rsname, ''-1'') <> isnull(rs_name, '''')
								)
							)		
							begin
								update top (@pdtUpdatePackageSize) @tableName
								set
									pt_rsname = isnull(rs_name, '''')
								from
									dbo.resorts
								where
									pt_rskey = rs_key and 
									isnull(pt_rsname, ''-1'') <> isnull(rs_name, '''')
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
										isnull(pt_toururl, ''-1'') <> isnull(tl_webhttp, '''') or
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
										isnull(pt_toururl, ''-1'') <> isnull(tl_webhttp, '''') or
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
									and (
										isnull(pt_rmname, ''-1'') <> isnull(rm_name, '''') or 
										isnull(pt_rmcode, ''-1'') <> isnull(rm_code, '''') or 
										isnull(pt_rmorder, -1) <> isnull(rm_order, 0)
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
	
	-- категория номера
	if ((@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='ROOMCATEGORY')) and @update_search_table > 0
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
									and (
										isnull(pt_rcname, ''-1'') <> isnull(rc_name, '''') or 
										isnull(pt_rccode, ''-1'') <> isnull(rc_code, '''') or 
										isnull(pt_rcorder, -1) <> isnull(rc_order, 0)
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
	
	-- размещение
	--kadraliev MEG00029412 29.09.2010 Добавил синхронизацию признака isMain, возрастов детей
	if ((@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='ACCOMODATION')) and @update_search_table > 0
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
				exec (@sql)

				fetch tableCursor into @tableName	
			end

			close tableCursor
			deallocate tableCursor
	end

	--kadraliev MEG00029412 29.09.2010 номер и размещение (количество основных и дополнительных мест)
	if ((@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='ROOM' or fname='ACCOMODATION')) and @update_search_table > 0
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
											pt_main > 0 and isnull(pt_mainplaces,-1) <> (case when @isMainPlacesFromAccomodation = 1
													then isnull(ac_nrealplaces,0)
													else isnull(rm_nplaces,0) end) or
											isnull(pt_addplaces,-1) <> (case isnull(ac_nmenexbed, -1) when -1 
													then (case when @isAddPlacesFromRooms = 1 
															then isnull(rm_nplacesex, 0)
															else isnull(ac_nmenexbed, 0) end)
													else isnull(ac_nmenexbed, 0) end))
							begin									
								update top (@pdtUpdatePackageSize) @tableName
								set
									pt_mainplaces = (case when pt_main > 0
													then (case when @isMainPlacesFromAccomodation = 1
														then isnull(ac_nrealplaces,0)
														else isnull(rm_nplaces,0) end)
													else isnull(pt_mainplaces,0) end),
									pt_addplaces =	(case isnull(ac_nmenexbed, -1) when -1 
														then (case when @isAddPlacesFromRooms = 1 
																then isnull(rm_nplacesex, 0)
																else isnull(ac_nmenexbed, 0) end)
														else isnull(ac_nmenexbed, 0) end )
								from @tableName orig with(nolock)
									left join rooms with(nolock) on orig.pt_rmkey = rm_key
									left join accmdmentype with(nolock) on orig.pt_ackey = ac_key
								where
									pt_main > 0 and isnull(pt_mainplaces,-1) <> (case when @isMainPlacesFromAccomodation = 1
											then isnull(ac_nrealplaces,0)
											else isnull(rm_nplaces,0) end) or
									isnull(pt_addplaces,-1) <> (case isnull(ac_nmenexbed, -1) when -1 
											then (case when @isAddPlacesFromRooms = 1 
													then isnull(rm_nplacesex, 0)
													else isnull(ac_nmenexbed, 0) end)
											else isnull(ac_nmenexbed, 0) end)
							end
				'

				set @sql = REPLACE(@sql, '@isMainPlacesFromAccomodation', @isMainPlacesFromAccomodation)
				set @sql = REPLACE(@sql, '@isAddPlacesFromRooms', @isAddPlacesFromRooms)
				set @sql = REPLACE(@sql, '@tableName', @tableName)
				set @sql = REPLACE(@sql, '@pdtUpdatePackageSize', @pdtUpdatePackageSize)
				exec (@sql)

				fetch tableCursor into @tableName	
			end

			close tableCursor
			deallocate tableCursor

			
	end

	-- расчитанный тур
	if (@blUpdateAllFields = 1) or exists(select top 1 1 from @fields where fname='TP_TOUR')
	begin
		while exists(select top 1 1 from dbo.mwSpoDataTable with(nolock)
			where exists(select top 1 1 from dbo.tp_tours with(nolock) where
				sd_tourkey = to_key
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
									and (
										isnull(pt_tourcreated, ''1900-01-02'') <> isnull(to_datecreated, ''1900-01-01'') or 
										isnull(pt_tourvalid, ''1900-01-02'') <> isnull(to_datevalid, ''1900-01-01'') or 
										isnull(pt_rate, ''-1'') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '''') COLLATE DATABASE_DEFAULT
									)
								)
							)
							begin
								update top (@pdtUpdatePackageSize) @tableName
								set
									pt_tourcreated = isnull(to_datecreated, ''1900-01-01''),
									pt_tourvalid = isnull(to_datevalid, ''1900-01-01''),
									pt_rate = isnull(to_rate, '''')
								from
									dbo.tp_tours
								where
									pt_tourkey = to_key
									and (
										isnull(pt_tourcreated, ''1900-01-02'') <> isnull(to_datecreated, ''1900-01-01'') or 
										isnull(pt_tourvalid, ''1900-01-02'') <> isnull(to_datevalid, ''1900-01-01'') or 
										isnull(pt_rate, ''-1'') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '''') COLLATE DATABASE_DEFAULT
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
end
GO

grant exec on [dbo].[mwSyncDictionaryData] to public
GO
/*********************************************************************/
/* end sp_mwSyncDictionaryData.sql */
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
			ptKey int primary key,
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

		if @aviaQuotaMask = 5 or @aviaQuotaMask = 1
		begin
			-- Соединим выборку курсора квот с кешем квот, чтобы отсеять туры с закончившимися перелетами
			set @filter = @filter + '
			and not exists 
								(
								select top 1 1 
								from CacheQuotas as directCharter with (nolock) 
								where 
									directCharter.cq_svkey = 1
									and directCharter.cq_code = pt_chkey
									and directCharter.cq_date = pt_tourdate
									and directCharter.cq_day = pt_chday
									and directCharter.cq_days = pt_days
									and directCharter.cq_prkey = pt_chprkey
									and directCharter.cq_pkkey = pt_chpkkey
									and directCharter.cq_places = 0
									and (pt_directFlightAttribute is not null 
											and 
											(
												(directCharter.cq_findFlight = 1 and (pt_directFlightAttribute & 2) = 2)
												or
												(directCharter.cq_findFlight = 0 and (pt_directFlightAttribute & 2) = 0)
											)
										)
								)
			and not exists 
								(
								select top 1 1 
								from CacheQuotas as backCharter  with (nolock) 
								where
									backCharter.cq_svkey = 1
									and backCharter.cq_code = pt_chbackkey
									and backCharter.cq_date = pt_tourdate
									and backCharter.cq_day = pt_chbackday
									and backCharter.cq_days = pt_days
									and backCharter.cq_prkey = pt_chprkey
									and backCharter.cq_pkkey = pt_chpkkey
									and backCharter.cq_places = 0
									and (pt_backFlightAttribute is not null 
											and 
											(
												(backCharter.cq_findFlight = 1 and (pt_backFlightAttribute & 2) = 2)
												or
												(backCharter.cq_findFlight = 0 and (pt_backFlightAttribute & 2) = 0)
											)
									)
								)
			'
		end

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

end
GO

GRANT EXECUTE on [dbo].[Paging] to public
GO
/*********************************************************************/
/* end sp_Paging.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_PagingPax.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PagingPax]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[PagingPax]
GO

--<DATE>2014-01-30</DATE>
--<VERSION>2009.2.20.7</VERSION>
CREATE PROCEDURE [dbo].[PagingPax]
@countryKey	int,			
	@departFromKey	int,		
	@filter		varchar(MAX),
	@sortExpr	varchar(1024),	
	@pageNum	int=0,			
	@pageSize	int=9999,		
	@agentKey	int=0,			
	@hotelQuotaMask smallint=0,	
	@aviaQuotaMask smallint=0,	
	@flightGroups	varchar(256),	
	@checkAgentQuota smallint,
	@checkCommonQuota smallint,
	@checkNoLongQuota smallint,
	@requestOnRelease smallint,
	@expiredReleaseResult int,
	@noPlacesResult int,
	@findFlight smallint,
	@checkFlightPacket smallint,
	@checkAllPartnersQuota smallint = null
AS
set nocount on

declare @pagingType int
	set @pagingType = 0

-- Move @countryKey and @departFromKey to filter
set @filter=' pt_cnkey= ' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom= ' + LTRIM(STR(@departFromKey)) + ' and ' + @filter

declare @MAX_ROWCOUNT int
	set @MAX_ROWCOUNT=1000 

declare @sortType smallint
	set @sortType = 1	

declare @spageNum varchar(30)		
	set @spageNum=LTRIM(STR(@pageNum))

declare @spageSize varchar(30)		
	set @spageSize=LTRIM(STR(@pageSize))

declare @sql varchar(MAX)
	set @sql=''

declare @zptPos int
declare @prefix varchar(1024)
set @zptPos = charindex(',',@sortExpr)
if(@zptPos > 0)
	set @prefix = substring(@sortExpr, 1, @zptPos)
else
	set @prefix = @sortExpr

if(charindex('desc', @prefix) > 0)
	set @sortType=-1

declare @viewName varchar(256)
if(@sortType <= 0)
	set @viewName='mwPriceTablePaxViewDesc'
else
	set @viewName='mwPriceTablePaxViewAsc'


CREATE TABLE #days
(
	days int,
	nights int
)

SET @sql='
	select		distinct pt_days,pt_nights 
	from		dbo.mwPriceTable t1 with(nolock) 
---- Берем только последние цены
--	inner join 
--	(	
--		select	pt_ctkeyfrom ctkeyfrom,	pt_cnkey cnkey, 		pt_tourtype tourtype,	pt_mainplaces mainplaces, 
--				pt_addplaces addplaces,	pt_tourdate tourdate,	pt_pnkey pnkey, 		pt_pansionkeys pansionkeys,
--				pt_days days,			pt_nights nights,		pt_hdkey hdkey,			pt_hotelkeys hotelkeys,
--				pt_hrkey hrkey,			max(pt_key) ptkey 
--		from	dbo.mwPriceTable with(nolock) 
--		group by 
--				pt_ctkeyfrom,			pt_cnkey,				pt_tourtype,			pt_mainplaces,
--				pt_addplaces,			pt_tourdate,			pt_pnkey,				pt_pansionkeys,
--				pt_nights,				pt_hotelnights,			pt_days,				pt_hdkey,
--				pt_hotelkeys,			pt_hrkey
--	) t2
--	on			t1.pt_ctkeyfrom=t2.ctkeyfrom 		and			t1.pt_cnkey=t2.cnkey 
--		and		t1.pt_tourtype = t2.tourtype 		and			t1.pt_mainplaces=t2.mainplaces 
--		and		t1.pt_addplaces=t2.addplaces 		and			t1.pt_tourdate=t2.tourdate
--		and		t1.pt_pnkey=t2.pnkey				and			t1.pt_nights=t2.nights
--		and		t1.pt_days=t2.days					and			t1.pt_hdkey=t2.hdkey 
--		and		t1.pt_hrkey=t2.hrkey				and			t1.pt_key=t2.ptkey 
	where ' + @filter + ' and pt_days is not null and pt_nights is not null and pt_days>=1 and pt_nights>=1		-- минимальная длина туров
	order by pt_days,pt_nights'
--print @sql
--print ' Before Execute GetDurationsScript: ' + CONVERT(VARCHAR(20), getdate(),114 )
INSERT INTO #days EXEC(@sql)
--print ' After  Execute GetDurationsScript: ' + CONVERT(VARCHAR(20), getdate(),114 )

	create table #checked(
		svkey int,		code int,
		rmkey int,		rckey int,
		date datetime,	[day] int,
		days int,		prkey int,
		pkkey int,		res varchar(256),
		places int,		step_index smallint,
		price_correction int
	)

	create table #resultsTable(
		paging_id int, 
		pt_ctkey int, 
		pt_ctname varchar(50), 
		pt_hdkey int, 
		pt_hdname varchar(60), 
		pt_hdstars varchar(12), 
		pt_hotelurl varchar(254),
		pt_pnkey int, 
		pt_pncode varchar(30), 
		pt_rate varchar(3), 
		pt_rmkey int, 
		pt_rmname varchar(35), 
		pt_rckey int, 
		pt_rcname varchar(35),
		pt_tourdate datetime
	)

	create table #quotaCheckTable(
		pt_key int,
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
		pt_chbackquota varchar(256)		
	)

declare @d int
declare @n int
declare @sdays varchar(10)

declare @sKeysSelect varchar(2024)
	set @sKeysSelect=''

declare @sAlter varchar(2024)
	set @sAlter=''

declare @sWhere varchar(5000)
	set @sWhere=''

--declare @sAddSelect varchar(3950)
--	set @sAddSelect=''
--
--declare @sJoin varchar(3950)
--	set @sJoin=''

declare @sJoinTable varchar(20)
	set @sJoinTable=''

declare @sTmp varchar(8000)
	set @sTmp=''

declare @rowCount int

declare @priceFilter nvarchar(512)
	set @priceFilter = N''

declare @priceKeyFilter nvarchar(512)
	set @priceKeyFilter = N''

declare @nightsPart nvarchar(256)
declare @hotelNightsPart nvarchar(256)

declare @dml varchar(7950)
	set @dml = N''

DECLARE dCur CURSOR FOR SELECT days,nights FROM #days
OPEN dCur
FETCH NEXT FROM dCur INTO @d,@n
WHILE (@@fetch_status=0)
BEGIN
	set @sdays=LTRIM(STR(@d)) + '_' + LTRIM(STR(@n))
	if(substring(@sortExpr, 1, 1) = '*')
	begin
		set @sortExpr = 'p_' + @sdays + '_DBL' + substring(@sortExpr, 2, len(@sortExpr) - 1)
	end
	
----------------------------------------------------------
-- Prepare script for add quota columns to result table --
----------------------------------------------------------
 	if(len(@dml) > 0) 
		set @dml = @dml + ','

	set @dml = @dml + 'prk_' + @sdays + '_DBL varchar(256), hq_' + @sdays + '_DBL varchar(10), cq_' + @sdays + '_DBL varchar(256), cbq_' + @sdays + '_DBL varchar(256), ' +
		'prk_' + @sdays + '_SGL varchar(256), hq_' + @sdays + '_SGL varchar(10), cq_' + @sdays + '_SGL varchar(256), cbq_' + @sdays + '_SGL varchar(256), ' +
		'prk_' + @sdays + '_EXB varchar(256), hq_' + @sdays + '_EXB varchar(10), cq_' + @sdays + '_EXB varchar(256), cbq_' + @sdays + '_EXB varchar(256), ' +
		'prk_' + @sdays + '_CHD varchar(256), hq_' + @sdays + '_CHD varchar(10), cq_' + @sdays + '_CHD varchar(256), cbq_' + @sdays + '_CHD varchar(256)'

---------------------------------------------------------------------------------------
-- Prepare script for select price-duration columns values from View to result table --
---------------------------------------------------------------------------------------
 	if(len(@sKeysSelect) > 0)
		set @sKeysSelect=@sKeysSelect + ', '
	
	set @sKeysSelect=@sKeysSelect 
		+ '  p_' + @sdays + '_DBL' + ', pk_' + @sdays + '_DBL'
		+ ', p_' + @sdays + '_SGL' + ', pk_' + @sdays + '_SGL'
		+ ', p_' + @sdays + '_EXB' + ', pk_' + @sdays + '_EXB'
		+ ', p_' + @sdays + '_CHD' + ', pk_' + @sdays + '_CHD'

-------------------------------------------------------------------
-- Prepare script for add price-duration columns to result table --
-------------------------------------------------------------------
	if(len(@sAlter) > 0)
		set @sAlter=@sAlter + ','

	set @sAlter=@sAlter + 'p_' + @sdays + '_DBL float,pk_' + @sdays + '_DBL int'
		+ ',p_' + @sdays + '_SGL float,pk_' + @sdays + '_SGL int'
		+ ',p_' + @sdays + '_EXB float,pk_' + @sdays + '_EXB int'
		+ ',p_' + @sdays + '_CHD float,pk_' + @sdays + '_CHD int'

-----------------------------------------------
-- Prepare filter predicate for quotas table --
-----------------------------------------------
	if(len(@sWhere) > 0)
		set @sWhere=@sWhere + ' or '

	set @sWhere=@sWhere + 'pt_key in (select pk_' + @sdays + '_DBL from #resultsTable)'
		+ ' or pt_key in (select pk_' + @sdays + '_SGL from #resultsTable)'
		+ ' or pt_key in (select pk_' + @sdays + '_EXB from #resultsTable)'
		+ ' or pt_key in (select pk_' + @sdays + '_CHD from #resultsTable)'

--	if(len(@sAddSelect) > 0)
--		set @sAddSelect=@sAddSelect + ','
--
--	set @sAddSelect=@sAddSelect + ' t_' + @sdays + '_DBL.pt_pricekey prk_' + @sdays + '_DBL, t_' + @sdays + '_DBL.pt_hdquota hq_' + @sdays + '_DBL, t_' + @sdays + '_DBL.pt_chtherequota cq_' + @sdays + '_DBL, t_' + @sdays + '_DBL.pt_chbackquota cbq_' + @sdays + '_DBL'
--								+ ',t_' + @sdays + '_SGL.pt_pricekey prk_' + @sdays + '_SGL, t_' + @sdays + '_SGL.pt_hdquota hq_' + @sdays + '_SGL, t_' + @sdays + '_SGL.pt_chtherequota cq_' + @sdays + '_SGL, t_' + @sdays + '_SGL.pt_chbackquota cbq_' + @sdays + '_SGL'
--								+ ',t_' + @sdays + '_EXB.pt_pricekey prk_' + @sdays + '_EXB, t_' + @sdays + '_EXB.pt_hdquota hq_' + @sdays + '_EXB, t_' + @sdays + '_EXB.pt_chtherequota cq_' + @sdays + '_EXB, t_' + @sdays + '_EXB.pt_chbackquota cbq_' + @sdays + '_EXB'
--								+ ',t_' + @sdays + '_CHD.pt_pricekey prk_' + @sdays + '_CHD, t_' + @sdays + '_CHD.pt_hdquota hq_' + @sdays + '_CHD, t_' + @sdays + '_CHD.pt_chtherequota cq_' + @sdays + '_CHD, t_' + @sdays + '_CHD.pt_chbackquota cbq_' + @sdays + '_CHD'
--
--
--	set @sJoin=@sJoin + ' left outer join #quotaCheckTable t_' + @sdays + '_DBL on t.pk_' + @sdays + '_DBL = t_' + @sdays + '_DBL.pt_key'
--		+ ' left outer join #quotaCheckTable t_' + @sdays + '_SGL on t.pk_' + @sdays + '_SGL = t_' + @sdays + '_SGL.pt_key'
--		+ ' left outer join #quotaCheckTable t_' + @sdays + '_EXB on t.pk_' + @sdays + '_EXB = t_' + @sdays + '_EXB.pt_key'
--		+ ' left outer join #quotaCheckTable t_' + @sdays + '_CHD on t.pk_' + @sdays + '_CHD = t_' + @sdays + '_CHD.pt_key'

	FETCH NEXT FROM dCur INTO @d,@n
END
CLOSE dCur
DEALLOCATE dCur

if(len(@sKeysSelect) > 0)
begin
	set @sTmp = 'alter table #resultsTable add ' + @sAlter
	exec(@sTmp)

	declare @daysPart varchar(50)
	set @daysPart = dbo.mwGetFilterPart(@filter, 'pt_days')

	if(@daysPart is not null)
		set @filter = REPLACE(@filter, @daysPart, '1 = 1')

	--print ' Before Execute PagingSelect: ' + CONVERT(VARCHAR(20), getdate(),114 )

	declare @nSql nvarchar(4000)
	set @nSql=N'
	DECLARE @firstRecord int,@lastRecord int
	SET @firstRecord=('+ @spageNum + ' - 1) * ' + @spageSize+ ' + 1
	SET @lastRecord=('+ @spageNum +' *'+ @spageSize + ')
	select top 250 identity(int,1,1) paging_id, pt_ctkey, pt_ctname, pt_hdkey, pt_hdname, pt_hdstars, hd_http as pt_hotelurl, pt_pnkey, pt_pncode, pt_rate, pt_rmkey, pt_rmname, pt_rckey, pt_rcname, pt_tourdate' 
	
	if(len(@sKeysSelect) > 0)
		set @nSql=@nSql + ',' + @sKeysSelect 
	
	set @nSql=@nSql + '
		into #pg from ' + @viewName + ' inner join hoteldictionary with(nolock) on pt_hdkey = hd_key where ' + @filter

	if(len(isnull(@sortExpr,'')) > 0)
		set @nSql=@nSql + '		order by ' + @sortExpr 
		
	Set @rowCount = null
		
	if(@rowCount is not null)
		set @nSql = @nSql + '
	select @@RowCount as RowsCount'
	else
		set @nSql = @nSql + '
	set @rowCountOUT = @@RowCount'

	set @nSql=@nSql + ' 
	select paging_id, pt_ctkey, pt_ctname, pt_hdkey, pt_hdname, pt_hdstars, pt_hotelurl, pt_pnkey, pt_pncode, pt_rate, pt_rmkey, pt_rmname, pt_rckey, pt_rcname, pt_tourdate'
	if(len(@sKeysSelect) > 0)
		set @nSql=@nSql + ',' + @sKeysSelect 
	set @nSql = @nSql +
	'
	from #pg WHERE #pg.paging_id BETWEEN @firstRecord and @lastRecord order by paging_id
	'

	declare @ParamDef nvarchar(100)
	set @ParamDef = '@rowCountOUT int output'
	
--	print @nSql
	INSERT INTO #resultsTable
		exec sp_executesql @nSql, @ParamDef, @rowCountOUT = @rowCount output
	
	Set @rowCount = (select COUNT(*) from #resultsTable)		--MEG00038933 Tkachuk 16-02-2012 Получаем количество строк не через output-переменную в предыдущей строке, а через select в результирующей таблице
	Select @rowCount

--print ' After Filling #resultTable: ' + CONVERT(VARCHAR(20), getdate(), 114)
--print @nSql

	-- Add quota columns to result table
	set @dml = 'ALTER TABLE #resultsTable ADD  ' + @dml
	exec (@dml)

	SET @sTmp = 'select pt_key, pt_pricekey, pt_tourdate, pt_days,	pt_nights, pt_hdkey, pt_hdday,
						pt_hdnights, (case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_hdpartnerkey end), pt_rmkey,	pt_rckey, pt_chkey,	pt_chday, pt_chpkkey,
						pt_chprkey, pt_chbackkey, pt_chbackday, pt_chbackpkkey, pt_chbackprkey, null, null, null
				from dbo.mwPriceTablePax
				where ' + @sWhere
--print ' Before Execute GetQuotaCheckTableScript: ' + CONVERT(VARCHAR(20), getdate(),114 )
--	print @sTmp
	INSERT INTO #quotaCheckTable exec(@sTmp)
--print ' After  Execute GetQuotaCheckTableScript: ' + CONVERT(VARCHAR(20), getdate(),114 )

	declare quotaCursor cursor for
	select pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,
		pt_chkey,pt_chbackkey,
		pt_hdday,pt_hdnights,pt_hdpartnerkey,pt_chday,(case when @checkFlightPacket > 0 then pt_chpkkey else -1 end) as pt_chpkkey,pt_chprkey,
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
		if(@hotelQuotaMask > 0)
		begin
			set @tmpHotelQuota=null
			select @tmpHotelQuota=res from #checked where svkey=3 and code=@hdkey and rmkey=@rmkey and rckey=@rckey and date=@tourdate and day=@hdday and days=@hdnights and prkey=@hdprkey
			if (@tmpHotelQuota is null)
			begin
				select @places=qt_places,@allPlaces=qt_allPlaces from dbo.mwCheckQuotesEx(3,@hdkey,@rmkey,@rckey, @agentKey,@hdprkey,@tourdate,@hdday,@hdnights,@requestOnRelease,@noPlacesResult,@checkAgentQuota,@checkCommonQuota,@checkNoLongQuota,0,0,0,0,0,@expiredReleaseResult)
				set @tmpHotelQuota=ltrim(str(@places)) + ':' + ltrim(str(@allPlaces))

				insert into #checked(svkey,code,rmkey,rckey,date,[day],days,prkey,pkkey,res) values(3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota)
			end
		end

		update #quotaCheckTable set pt_hdquota=@tmpHotelQuota,
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

------------------------------------------------------------------------------------------
------------------------- Fill #resultsTable with data of quotes -------------------------
--																						--
	DECLARE @UpdateQuotesSQL varchar(8000)												--
		SET @UpdateQuotesSQL = N''														--
																						--
	DECLARE daysCursor CURSOR FOR SELECT days,nights FROM #days							--
	OPEN daysCursor																		--
	FETCH NEXT FROM daysCursor INTO @d,@n												--
	WHILE (@@fetch_status=0)															--
	BEGIN																				--
		SET @sdays = LTRIM(STR(@d)) + '_' + LTRIM(STR(@n))								--
																						--
		SET @UpdateQuotesSQL =															--
			'UPDATE #resultsTable SET ' +												--
				'prk_' + @sdays + '_DBL = pt_pricekey, ' +								--
				'hq_' + @sdays + '_DBL = pt_hdquota, ' +								--
				'cq_' + @sdays + '_DBL = pt_chtherequota, ' +							--
				'cbq_' + @sdays + '_DBL = pt_chbackquota ' +							--
			'FROM #quotaCheckTable WHERE pk_' + @sdays + '_DBL = pt_key '				--
		EXEC (@UpdateQuotesSQL)															--
																						--
		SET @UpdateQuotesSQL =															--
			'UPDATE #resultsTable SET ' +												--
				'prk_' + @sdays + '_SGL = pt_pricekey, ' +								--
				'hq_' + @sdays + '_SGL = pt_hdquota, ' +								--
				'cq_' + @sdays + '_SGL = pt_chtherequota, ' +							--
				'cbq_' + @sdays + '_SGL = pt_chbackquota ' +							--
			'FROM #quotaCheckTable WHERE pk_' + @sdays + '_SGL = pt_key '				--
		EXEC (@UpdateQuotesSQL)															--
																						--
		SET @UpdateQuotesSQL =															--
			'UPDATE #resultsTable SET ' +												--
				'prk_' + @sdays + '_EXB = pt_pricekey, ' +								--
				'hq_' + @sdays + '_EXB = pt_hdquota, ' +								--
				'cq_' + @sdays + '_EXB = pt_chtherequota, ' +							--
				'cbq_' + @sdays + '_EXB = pt_chbackquota ' +							--
			'FROM #quotaCheckTable WHERE pk_' + @sdays + '_EXB = pt_key '				--
		EXEC (@UpdateQuotesSQL)															--
																						--
		SET @UpdateQuotesSQL =															--
			'UPDATE #resultsTable SET ' +												--
				'prk_' + @sdays + '_CHD = pt_pricekey, ' +								--
				'hq_' + @sdays + '_CHD = pt_hdquota, ' +								--
				'cq_' + @sdays + '_CHD = pt_chtherequota, ' +							--
				'cbq_' + @sdays + '_CHD = pt_chbackquota ' +							--
			'FROM #quotaCheckTable WHERE pk_' + @sdays + '_CHD = pt_key '				--
		EXEC (@UpdateQuotesSQL)															--
																						--
		FETCH NEXT FROM daysCursor INTO @d,@n											--
	END																					--
	CLOSE daysCursor																	--
	DEALLOCATE daysCursor																--
--																						--
-------------------------										 -------------------------
------------------------------------------------------------------------------------------

select * from #resultsTable

end
else 
begin
	select 0
	select * from #resultsTable
end
GO

GRANT EXECUTE on [dbo].[PagingPax] to public
GO
/*********************************************************************/
/* end sp_PagingPax.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_PagingSelect.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PagingSelect]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[PagingSelect]
GO

--<DATE>2014-01-30</DATE>
--<VERSION>2009.2.20.7</VERSION>
CREATE PROCEDURE [dbo].[PagingSelect]
	@pagingType int,
	@sKeysSelect varchar(2024),
	@spageNum varchar(30),
	@spageSize varchar(30),
	@filter	varchar(MAX),
	@orderBy varchar (2024),
	@tableName varchar(256),
	@viewName varchar(256),
	@rowCount int output
as
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
	res varchar(10)
)	

declare @sql nvarchar(MAX)
declare @nRowCount int
set @nRowCount = 1000
set @sql=N'
DECLARE @firstRecord int,@lastRecord int
SET @firstRecord=('+ @spageNum + ' - 1) * ' + @spageSize+ ' + 1
SET @lastRecord=('+ @spageNum +' *'+ @spageSize + ')
select top ' + ltrim(str(@nRowCount)) + ' identity(int,1,1) paging_id, pt_key,pt_tourdate,pt_pnkey,pt_hdkey,pt_hrkey,pt_tourkey' 
if(len(@sKeysSelect) > 0)
	set @sql=@sql + ',' + @sKeysSelect 
set @sql=@sql + '
into #pg from ' + @viewName + ' where ' + @filter

if(len(isnull(@orderBy,'')) > 0)
	set @sql=@sql + ' order by ' + @orderBy 

if(@rowCount is not null)
	set @sql = @sql + '
		select @@RowCount as RowsCount'
else
	begin
		set @sql = @sql + '
			set @rowCountOUT = @@RowCount
'
	end
set @sql=@sql + ' 
select #pg.paging_id paging_id,#pg.pt_key,tbl.pt_ctkeyfrom,tbl.pt_cnkey,#pg.pt_tourdate,#pg.pt_pnkey,#pg.pt_hdkey,#pg.pt_hrkey,#pg.pt_tourkey,tbl.pt_tlkey as pt_tlkey,tl_tip as pt_tourtype,tl_nameweb as pt_tourname,tl_webhttp as pt_toururl,
hd_name pt_hdname,hd_stars pt_hdstars,hd_ctkey pt_ctkey,hd_rskey pt_rskey,hd_http pt_hotelurl,pn_code pt_pncode,tbl.pt_rate pt_rate,tbl.pt_rmkey pt_rmkey,tbl.pt_rckey pt_rckey,tbl.pt_ackey pt_ackey,tbl.pt_childagefrom pt_childagefrom,tbl.pt_childageto pt_childageto,tbl.pt_childagefrom2 pt_childagefrom2,tbl.pt_childageto2 pt_childageto2, cn_name pt_cnname, ct_name pt_ctname, rs_name pt_rsname, tbl.pt_rmname pt_rmname,tbl.pt_rcname pt_rcname,tbl.pt_acname pt_acname, tbl.pt_chkey pt_chkey, tbl.pt_chbackkey pt_chbackkey, tbl.pt_hotelkeys pt_hotelkeys, tbl.pt_hotelroomkeys pt_hotelroomkeys, tbl.pt_hotelnights pt_hotelnights, tbl.pt_hotelstars pt_hotelstars, tbl.pt_pansionkeys pt_pansionkeys, tbl.pt_rckey pt_actual, dbo.mwGetVisaDeadlineDate(tbl.pt_tlkey, tbl.pt_tourdate, tbl.pt_ctkeyfrom) pt_visadeadline ' --MEG00038933 Tkachuk 16-02-2012: не хватало двух последних столбцов для корректной работы хранимой процедуры
if(len(@sKeysSelect) > 0)
	set @sql=@sql + ',' + @sKeysSelect 
set @sql = @sql +
'
from #pg inner join ' + @tableName + ' tbl on tbl.pt_key=#pg.pt_key inner join turlist on tl_key = tbl.pt_tlkey inner join country on tbl.pt_cnkey = cn_key inner join hoteldictionary on hd_key=#pg.pt_hdkey inner join pansion on #pg.pt_pnkey=pn_key inner join citydictionary on hd_ctkey = ct_key left outer join resorts on hd_rskey = rs_key
WHERE #pg.paging_id '
if (@pagingType = 5)
	set @sql = @sql + '>' + @spageNum
else if (@pagingType = 0)
	set @sql = @sql + 'BETWEEN @firstRecord and @lastRecord'
set @sql = @sql + ' order by paging_id'
declare @ParamDef nvarchar(100)
--print @sql
set @ParamDef = '@rowCountOUT int output'
exec sp_executesql @sql, @ParamDef, @rowCountOUT = @rowCount output
end
GO

GRANT EXECUTE on [dbo].[PagingSelect] to public
GO
/*********************************************************************/
/* end sp_PagingSelect.sql */
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

--<VERSION>2009.2.21</VERSION>
--<DATE>2014-01-16</DATE>
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
	
	-- Flink 24-06-2005 MEG00004332	
	DECLARE @iHC_Key	int
	
	if	(@nOldNetto = @nNewNetto) and (@nOldBrutto = @nNewBrutto) and 
		(@dOldBeg = @dNewBeg) and (@dOldEnd = @dNewEnd) and (@sMode != 'DEL')
		Return 0

	Set @sOldNetto = isnull(CAST ( @nOldNetto  AS varchar ), '')
	Set @sNewNetto = isnull(CAST ( @nNewNetto  AS varchar ), '')
	Set @sOldBrutto = isnull(CAST ( @nOldBrutto  AS varchar ), '')
	Set @sNewBrutto = isnull(CAST ( @nNewBrutto  AS varchar ), '')
	Set @sOldDateBeg = isnull(CONVERT ( varchar , @dOldBeg, 105), '')
	Set @sNewDateBeg = isnull(CONVERT ( varchar , @dNewBeg, 105), '')
	Set @sOldDateEnd = isnull(CONVERT ( varchar , @dOldEnd, 105), '')
	Set @sNewDateEnd = isnull(CONVERT ( varchar , @dNewEnd, 105), '')

	EXEC dbo.CurrentUser @sOper output

	Set @sText = ''
	If @sMode != 'DEL'
	begin
		if @nOldNetto != @nNewNetto
		begin
			set @sText = 'Изменение нетто с ' + @sOldNetto + ' на ' + @sNewNetto + ' сезон ' + @sNewDateBeg + ' - ' + @sNewDateEnd
			
			-- Flink 24-06-2005 MEG00004332
			EXEC GetNKey 'HistoryCost', @iHC_Key output
			
			Insert into HistoryCost (HC_Key, HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
			VALUES (@iHC_Key, GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1,	@nCode2, @nPartner, @nPaket)
		end
		if @nOldBrutto != @nNewBrutto
		begin
			set @sText = 'Изменение брутто с ' + @sOldBrutto + ' на ' + @sNewBrutto + ' сезон ' + @sNewDateBeg + ' - ' + @sNewDateEnd
				
			-- Flink 24-06-2005 MEG00004332
			EXEC GetNKey 'HistoryCost', @iHC_Key output
			
			Insert into HistoryCost (HC_Key, HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
			VALUES ( @iHC_Key, GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1, @nCode2, @nPartner, @nPaket)
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
		IF @sText != '' BEGIN		
			-- Flink 24-06-2005 MEG00004332
			EXEC GetNKey 'HistoryCost', @iHC_Key output
			
			Insert into HistoryCost (HC_Key, HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
			VALUES (@iHC_Key, GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1, @nCode2, @nPartner, @nPaket)
		END
	end
	else
	begin
		SET @sText = 'Удаление цены: нетто ' + @sOldNetto + ', брутто ' + @sOldBrutto + ', сезон с ' + @sOldDateBeg + ' по ' + @sOldDateEnd
		
		-- Flink 24-06-2005 MEG00004332
		EXEC GetNKey 'HistoryCost', @iHC_Key output
		
		INSERT INTO HistoryCost (HC_Key, HC_Date, HC_Mod, HC_Who, HC_Text, HC_SvKey, HC_Code, HC_Code1, HC_Code2, HC_PrKey, HC_Paket)
		VALUES (@iHC_Key, GETDATE(), @sMode, @sOper, @sText, @nSvKey, @nCode, @nCode1, @nCode2, @nPartner, @nPaket)
	end
GO

GRANT EXECUTE ON [dbo].[UpdateDeleteCost]	TO PUBLIC
GO
/*********************************************************************/
/* end sp_UpdateDeleteCost.sql */
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
update [dbo].[setting] set st_version = '9.2.20.7', st_moduledate = convert(datetime, '2014-02-10', 120),  st_financeversion = '9.2.20.7', st_financedate = convert(datetime, '2014-02-10', 120) 
 GO
 UPDATE dbo.SystemSettings SET SS_ParmValue='2014-02-10' WHERE SS_ParmName='SYSScriptDate'
 GO