/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 10.07.2014 18:39 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.16'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.17'

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
/* begin (2014_07_02)_AlterTable_CountrySettings.sql */
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
	and k.[type] = 'PK')
and exists(select top 1 1 from sys.key_constraints k
			left join sys.tables tab on k.parent_object_id = tab.object_id
			left join sys.columns col on col.object_id = tab.object_id
			where tab.name = 'CountrySettings'
			and k.[type] = 'PK')
begin
	declare @sql varchar(max)
	set @sql = 'ALTER TABLE dbo.CountrySettings DROP CONSTRAINT ' + (select top 1 k.name from sys.key_constraints k
								inner join sys.tables tab on k.parent_object_id = tab.object_id
								inner join sys.columns col on col.object_id = tab.object_id
								where tab.name = 'CountrySettings'
								and k.[type] = 'PK')
	exec (@sql)
end

if not exists (select * from sys.key_constraints k
left join sys.tables tab on k.parent_object_id = tab.object_id
left join sys.columns col on col.object_id = tab.object_id 
where tab.name = 'CountrySettings'
	and col.name = 'CS_Id'
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
/* end (2014_07_02)_AlterTable_CountrySettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_Run.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CorrectionCalculatedPrice_Run]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CorrectionCalculatedPrice_Run]
GO

CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_Run]
	(
		-- version 2009.12.03
		-- date 2012-04-13
		@deltaCost decimal(14,2),
		@itogCostMin decimal(14,2),
		@operation bit, -- 1 - изменяем цену, 0 - удаляем цену
		@costInPercent bit, -- 1 - цена в процентах, 0 - цена в у.е.
		@perPerson bit, -- 1 - за человека, 0 - нет
		@serviceTypeKey int,
		@serviceCodeList xml,
		@dateList xml,
		@turList xml,
		@durationList xml,
		@hotelKeys xml
	)
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	declare @round smallint
	SELECT @round = ST_RoundService FROM Setting

	declare @cost decimal(14,2)
	set @cost = @deltaCost;
	
	if (@operation = 0)
	begin
		set @cost = 0;
	end
	
	declare @partUpdate int
	
	set @partUpdate = 5000 -----100000
	select @partUpdate = SS_ParmValue from SystemSettings where SS_ParmName = 'PartCorrectionPrice'
	
	declare @divide int, @mwReplIsPublisher int, @mwReplIsSubscriber int
	
	set @mwReplIsPublisher = dbo.mwReplIsPublisher()
	set @mwReplIsSubscriber = dbo.mwReplIsSubscriber()

	set @divide = 0

	select @divide = CONVERT(int, isnull(SS_ParmValue, '0'))
	from SystemSettings
	where SS_ParmName = 'MWDivideByCountry'

	select TI_Key
	into #tmp_CorrectionCalculatedPrice_Run
	from TP_ServiceLists with (nolock) join TP_Services with (nolock) on TL_TSKey = TS_Key
	join TP_Lists with (nolock) on TL_TIKey = TI_Key
	where TI_TOKey in (select tbl.res.value('.', 'int') from @turList.nodes('/ArrayOfInt/int') as tbl(res) join TP_Tours on tbl.res.value('.', 'int') = TO_Key where TO_UPDATE != 1)
	and TS_Code in (select tbl.res.value('.', 'int') from @serviceCodeList.nodes('/ArrayOfInt/int') as tbl(res))
	and (@serviceTypeKey != 3 or (TS_SubCode1 in (select tbl.res.value('.', 'int') from @hotelKeys.nodes('/ArrayOfInt/int') as tbl(res))))
	and TS_SVKey = @serviceTypeKey
	and ti_totaldays in (select tbl.res.value('.', 'int') from @durationList.nodes('/ArrayOfInt/int') as tbl(res))
	
	while ((select COUNT(*) from #tmp_CorrectionCalculatedPrice_Run) > 0)
	begin
		-- выборка цен
		select TP_Key as TPU_TPKey, TP_Gross as TPU_TPGrossOld, case when @costInPercent = 0 then
																									convert(int, case when @perPerson = 1 then
																														@cost * (	select top 1 TS_Men
																														from TP_Services with (nolock) join TP_ServiceLists with (nolock) on TS_Key = TL_TSKey 
																														where TS_SVKey = 3
																														and TL_TIKey = TP_TIKey)
																													else 
																														@cost 
																													end)
																								else
																									 convert(int, case when @perPerson = 1 then 
																														TP_Gross * (@cost / 100) * (	select top 1 TS_Men
																																						from TP_Services with (nolock) join TP_ServiceLists with (nolock) on TS_Key = TL_TSKey 
																																						where TS_SVKey = 3
																																						and TL_TIKey = TP_TIKey)
																													else 
																														TP_Gross * (@cost / 100)
																													end)
																								end as TPU_TPGrossDelta
		into #tmp_tpPricesUpdated
		from TP_Prices with (nolock)
		where TP_TIKey in ( select top (@partUpdate) TI_Key from #tmp_CorrectionCalculatedPrice_Run)
		and TP_DateBegin in (select res.value('.', 'datetime') from @dateList.nodes('/ArrayOfDateTime/dateTime') as tbl(res))
				
		if (@operation = 1)
		begin
			-- если изменяем цены
			update TP_Prices with (rowlock)
			set TP_Gross = dbo.RoundPrice(@round,TPU_TPGrossOld + TPU_TPGrossDelta)
			from TP_Prices join #tmp_tpPricesUpdated on TP_Key = TPU_TPKey
		end
		else
		begin
			insert into dbo.mwReplDeletedPricesTemp (rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey) 
			select TPU_TPKey, TO_CNKey, TL_CTDepartureKey
			from #tmp_tpPricesUpdated
			join TP_Prices on TP_Key = TPU_TPKey
			join tp_tours on tp_tokey = to_key
			join tbl_TurList on tl_key = to_trkey
		
			-- если удаляем цены
			delete TP_Prices with (rowlock)
			from TP_Prices join #tmp_tpPricesUpdated on TP_Key = TPU_TPKey
		end

		-- запишем время изменения в туре
		update TP_Tours
		set to_updatetime = getdate()
		from TP_Tours join @turList.nodes('/ArrayOfInt/int') as tbl(res) on tbl.res.value('.', 'int') = to_key
		
		if (@mwReplIsPublisher <= 0 and @mwReplIsSubscriber <= 0)
		begin
			if (@divide = 0)
			begin
				update mwPriceDataTable with (rowlock)
				set pt_price = dbo.RoundPrice(@round,TPU_TPGrossOld + TPU_TPGrossDelta)
				from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
			end
			else
			begin
				declare @sql nvarchar(4000), @tableName nvarchar(100)
				declare cur cursor fast_forward read_only for
				select name
				from sysobjects
				where xtype = 'U' and name like 'mwPriceDataTable[_]%'

				open cur
				fetch next from cur into @tableName
				while (@@FETCH_STATUS = 0)
				begin
					if (@operation = 1)
					begin
						set @sql = 'update ' + @tableName + ' with (rowlock)
									set pt_price = dbo.RoundPrice(@round,TPU_TPGrossOld + TPU_TPGrossDelta)
									from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey'
					end
					else
					begin
						set @sql = 'delete ' + @tableName + ' with (rowlock)
									from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey'
					end
					
					exec (@sql)
					fetch next from cur into @tableName
				end
				
				close cur
				deallocate cur
			end
		end
		
		insert into TP_PricesUpdated(TPU_TPKey, TPU_TPGrossDelta, TPU_TPGrossOld, TPU_IsChangeCostMode)
		select TPU_TPKey, TPU_TPGrossDelta, TPU_TPGrossOld, @operation
		from #tmp_tpPricesUpdated

		delete top (@partUpdate) #tmp_CorrectionCalculatedPrice_Run
		drop table #tmp_tpPricesUpdated
	end
	
END
GO

GRANT EXEC ON [dbo].[CorrectionCalculatedPrice_Run] TO PUBLIC
GO
/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_Run.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DS_GetCalendarTourDates.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DS_GetCalendarTourDates]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[DS_GetCalendarTourDates]
GO

--<VERSION>9.2.20.16</VERSION>
--<DATE>2014-06-30</DATE>
--Получает список возможных дат туров для фильтра РП.
CREATE PROCEDURE [dbo].[DS_GetCalendarTourDates]
	
	@departFromKeys ListIntValue readonly,	--Список ключей городов вылета.
	@countryKeys ListIntValue readonly,		--Список ключей стран.
	@tourKeys ListIntValue readonly,		--Список ключей туров.
	@resortKeys ListIntValue readonly,		--Список ключей курортов.
	@tourTypeKeys ListIntValue readonly,	--Список ключей типов туров.
	@cityKeys ListIntValue readonly			--Список ключей городов.
AS
BEGIN
	SET DATEFIRST 1
	
	DECLARE @mwSearchType int
	SELECT @mwSearchType = LTRIM(RTRIM(ISNULL(SS_ParmValue, ''))) FROM dbo.SystemSettings 
		WHERE SS_ParmName = 'MWDivideByCountry'
	
	DECLARE @tableName nvarchar(100)
	IF (@mwSearchType = 0)
	BEGIN
		SET @tableName = 'dbo.mwPriceDataTable'
	END
	ELSE
	BEGIN
		DECLARE @firstCountryKey int
		SELECT TOP 1 @firstCountryKey = value FROM @countryKeys

		DECLARE @firstDepartFromKey int
		SELECT TOP 1 @firstDepartFromKey = value FROM @departFromKeys

		SET @tableName = dbo.mwGetPriceTableName(@firstCountryKey, @firstDepartFromKey)
	END

	DECLARE @exceptNoPlacesAviaQuota int
	
	SELECT @exceptNoPlacesAviaQuota = LTRIM(RTRIM(ISNULL(SS_ParmValue, '')))
	FROM dbo.SystemSettings
	WHERE SS_ParmName = 'ExceptTourDatesWithNoAQ'

	--Исключение дат, на которые заведены квоты на перелет, но мест в квоте нет
	DECLARE @quotaNeedFromPart nvarchar(2000)
	DECLARE @quotaNeedWherePart nvarchar(100)
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
				WHERE QO_CNKey IN (SELECT value FROM @countryKeys)
					AND CH_CITYKEYFROM IN (SELECT value FROM @departFromKeys)
					AND ((QD_Places - QD_Busy) = 0
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

	DECLARE @sql nvarchar(MAX)
	SET @sql = 'SELECT DISTINCT DATEDIFF(ss, ''1970-01-01'', TP_TurDates.TD_Date) AS [key],
					CONVERT(varchar, TP_TurDates.TD_Date, 4) AS name,
					TP_TurDates.TD_Date
				FROM TP_TurDates 
					INNER JOIN mwSpoData with(nolock) ON TP_TurDates.TD_TOKey = mwSpoData.sd_tourkey ' +
				@quotaNeedFromPart + 
				'WHERE TP_TurDates.TD_Date > DATEADD(day, - 1, GETDATE())
					AND mwSpoData.sd_ctkeyfrom IN (SELECT value FROM @departFromKeys)
					AND mwSpoData.sd_cnkey IN (SELECT value FROM @countryKeys)' +
				@quotaNeedWherePart

	IF ((SELECT COUNT(*) FROM @tourKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourkey IN (SELECT value FROM @tourKeys) '
	END

	IF ((SELECT COUNT(*) FROM @resortKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_rskey IN (SELECT value FROM @resortKeys)'
	END

	IF ((SELECT COUNT(*) FROM @tourTypeKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourtype IN (SELECT value FROM @tourTypeKeys)'
	END

	IF ((SELECT COUNT(*) FROM @cityKeys) <> 0)
	BEGIN
		SET @sql += ' AND mwSpoData.sd_ctkey IN (SELECT value FROM @cityKeys)'
	END
    
    SET @sql += ' ORDER BY TP_TurDates.TD_Date'

	print (@sql)
    EXEC sp_executesql @sql,
		N'@departFromKeys ListIntValue readonly, @countryKeys ListIntValue readonly,
			@tourKeys ListIntValue readonly, @resortKeys ListIntValue readonly,
			@tourTypeKeys ListIntValue readonly, @cityKeys ListIntValue readonly',
		@departFromKeys, @countryKeys, @tourKeys, @resortKeys, @tourTypeKeys, @cityKeys
END
GO

GRANT EXECUTE on [dbo].[DS_GetCalendarTourDates] to public
GO
/*********************************************************************/
/* end sp_DS_GetCalendarTourDates.sql */
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
			QL_' + @ColumnName + ' = (CASE QL_dataType WHEN 1 THEN ''' + CAST((@Quota_Places) as varchar(10))  + ''' WHEN 2 THEN ''' + CAST((@Quota_Places-@Quota_Busy) as varchar(10))  + ''' WHEN 3 THEN ''' + CAST((@Quota_Busy) as varchar(10)) + ''' END)+' + ''';' + CAST(@QD_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(ISNULL(REPLACE(@Quota_Comment,'''','"'),'') as varchar(7980)) + ''''
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
					QL_' + @ColumnName + ' = (CASE QL_dataType WHEN 11 THEN ''' + CAST(ISNULL(@CheckInPlaces,0) as varchar(10)) + ''' WHEN 12 THEN ''' + CAST(ISNULL(@CheckInPlaces-@CheckInPlacesBusy,0) as varchar(10)) + ''' WHEN 13 THEN ''' + CAST(ISNULL(@CheckInPlacesBusy,0) as varchar(10)) + ''' END)+' + ''';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(ISNULL(REPLACE(@Quota_Comment,'''','"'),'') as varchar(7900)) + ''''
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
						QL_' + @ColumnName + ' = ' + @StopSaleOrPlaces + ';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(ISNULL(REPLACE(@Quota_Comment,'''','"'),'') as varchar(7900)) + ''''
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
			''' + @StopSaleOrPlaces + ';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(ISNULL(REPLACE(@Quota_Comment,'''','"'),'') as varchar(7900)) + '''
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
						QL_' + @ColumnName + ' = ''' + @StopSaleOrPlaces + ';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(ISNULL(REPLACE(@Quota_Comment,'''','"'),'') as varchar(7900)) + ''' 
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
						QL_' + @ColumnName + ' = QL_' + @ColumnName + ' + ''' + CAST(ISNULL(REPLACE(@Quota_Comment,'''','"'),'') as varchar(7900)) + '''
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
/* begin sp_ImportExchangeQuotaStops.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ImportExchangeQuotaStops]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[ImportExchangeQuotaStops]
GO

CREATE PROCEDURE [dbo].[ImportExchangeQuotaStops]
	(
		@dateBeg datetime,
		@dateEnd datetime,
		@HotelKey int,
		@prKey int
	)
AS
BEGIN	
	-- процедура импортирует информацию о квотах из тиблицы ExchangeQuotaStops
	--<version>2009.2.21</version>
	--<data>2014-03-06</data>

	SET NOCOUNT ON;
	
	declare @SvKey int, @Code int, @SubCode1 int, @SubCode2 int, @SubCode3 int, @Date datetime, @IsStop bit, @Places int, @PartnerKey int
	declare @qtKey int, @qoKey int, @qdKey int, @releaseConst int, @release int

	set @releaseConst = 365
	set @release = null
	
	declare ExchangeQuotaStops_cursor cursor local fast_forward for
	select EQS_SvKey, EQS_Code, EQS_SubCode1, EQS_SubCode2, EQS_SubCode3, EQS_Date, EQS_IsStop, EQS_Places, EQS_PartnerKey
	from ExchangeQuotaStops 
	where EQS_Date between @dateBeg and @dateEnd
		AND EQS_Code = @HotelKey
		and EQS_SvKey = 3
	order by EQS_Date, EQS_IsStop;

	open ExchangeQuotaStops_cursor;
	
	fetch next from ExchangeQuotaStops_cursor into @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @Places, @PartnerKey;	
	while @@FETCH_STATUS = 0
	begin		
		-- пришли обычные квоты
		if (@IsStop = 0 and @Places >= 0)
		begin

			if (not exists (select 1
									from Quotas join QuotaObjects on QT_ID = QO_QTID
									where QT_PRKey = @PartnerKey
									and QO_SVKey = @SvKey
									and QO_Code = @Code
									and QO_SubCode1 = @SubCode1
									and QO_SubCode2 = @SubCode3))
			begin
				insert into Quotas (QT_PRKey, QT_ByRoom, QT_Comment)
				values (@PartnerKey, 1, 'Quotas from Interlook. Load: ' + convert(nvarchar(max), GETDATE(), 121))
				set @qtKey = SCOPE_IDENTITY()
					
				insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
				values (@qtKey, @SvKey, @Code, @SubCode1, @SubCode3)
				set @qoKey = SCOPE_IDENTITY()
			end
			else
			begin
				select @qtKey = QT_ID, @qoKey = QO_ID
				from Quotas join QuotaObjects on QT_ID = QO_QTID
				where QT_PRKey = @PartnerKey
				and QO_SVKey = @SvKey
				and QO_Code = @Code
				and QO_SubCode1 = @SubCode1
				and QO_SubCode2 = @SubCode3
			end

			if not exists (select 1 from QuotaDetails with(nolock) where QD_QTID = @qtKey and QD_Date = @Date and QD_Type = 1)
			begin
				insert into QuotaDetails(QD_QTID, QD_Date, QD_Type, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey, QD_Release)
				values (@qtKey, @Date, 1, @Places, 0, GETDATE(), [dbo].[GetUserId](), @release)
				set @qdKey = SCOPE_IDENTITY()
			end
			else
			begin
				select top(1) @qdKey = QD_ID
				from QuotaDetails with(nolock) 
				where QD_QTID = @qtKey 
				and QD_Date = @Date 
				and QD_Type = 1

				update QuotaDetails
				set QD_Places = @Places,
				QD_Busy = 0,
				QD_Release = @release,
				QD_IsDeleted = null
				where QD_ID = @qdKey
			end
				
			if not exists (select 1 from QuotaParts where QP_QDID = @qdKey and QP_Date = @Date and QP_IsNotCheckIn = 0 and QP_Durations = '')
			begin
				insert into QuotaParts(QP_QDID, QP_Date, QP_Places, QP_Busy, QP_Limit, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey)
				values (@qdKey, @Date, @Places, 0, 1, 0, '', GETDATE(), [dbo].[GetUserId]())
			end
			else
			begin
				declare @qpKey int

				select top(1) @qpKey = QP_ID
				from QuotaParts 
				where QP_QDID = @qdKey 
				and QP_Date = @Date 
				and QP_IsNotCheckIn = 0 
				and QP_Durations = ''

				update QuotaParts
				set QP_Places = @Places,
				QP_Busy = 0,
				QP_Limit = 1,
				QP_IsDeleted = null
				where QP_ID = @qpKey

			end
		end
		else if (@IsStop = 1)
		begin
			-- пришел новый стоп, добавляем его
			if (@Places >= 0)
			begin
				if not exists (	select 1
								from QuotaObjects
								where QO_SVKey = @SvKey
								and QO_Code = @Code
								and QO_SubCode1 = @SubCode1
								and QO_SubCode2 = @SubCode3
								and QO_QTID is null)
				begin
					insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
					values (null, @SvKey, @Code, @SubCode1, @SubCode3)
					set @qoKey = SCOPE_IDENTITY()
				end
				else
				begin
					select @qoKey = QO_ID
					from QuotaObjects
					where QO_SVKey = @SvKey
					and QO_Code = @Code
					and QO_SubCode1 = @SubCode1
					and QO_SubCode2 = @SubCode3
					and QO_QTID is null
				end
				
				insert into StopSales(SS_QOID, SS_QDID, SS_PRKey, SS_Date, SS_AllotmentAndCommitment, SS_Comment, SS_CreateDate, SS_CreatorKey)
				values (@qoKey, null, @PartnerKey, @Date, 0, '', GETDATE(), [dbo].[GetUserId]())
			end
			else
			begin
				-- стоп удален
				if exists (select 1 
						   from QuotaObjects 
						   join StopSales on SS_QOID = QO_ID 
						   where QO_SVKey = @SvKey
							   and QO_Code = @Code
							   and QO_SubCode1 = @SubCode1
							   and QO_SubCode2 = @SubCode3
							   and QO_QTID is null
							   and ISNULL(SS_IsDeleted, 0) = 0)
				begin
					update StopSales
					set SS_IsDeleted = 1
					from QuotaObjects
					where SS_QOID = QO_ID
						and QO_SVKey = @SvKey
						and QO_Code = @Code
						and QO_SubCode1 = @SubCode1
						and QO_SubCode2 = @SubCode3
						and QO_QTID is null
						and ISNULL(SS_IsDeleted, 0) = 0
						and SS_Date = @Date
				end
			end
		end		
	
		-- обновим информацию о городе и строне вставленной квоты
		update quotaobjects
		set qo_ctkey = (select hd_ctkey from HotelDictionary where hd_key = qo_code)
		where qo_svkey = 3
		and QO_ID = @qoKey
					
		update quotaobjects
		set qo_cnkey= (select ct_cnKey from citydictionary where ct_key=qo_ctkey) 
		where qo_cnkey is null 
		and qo_ctkey is not null
		and QO_ID = @qoKey

		fetch next from ExchangeQuotaStops_cursor into @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @Places, @PartnerKey;		
	end
	
	close ExchangeQuotaStops_cursor;
	deallocate ExchangeQuotaStops_cursor;
END
GO

grant exec on [dbo].[ImportExchangeQuotaStops] to public
go
/*********************************************************************/
/* end sp_ImportExchangeQuotaStops.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ImportExchangeQuotaStops_Bulk.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ImportExchangeQuotaStops_Bulk]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[ImportExchangeQuotaStops_Bulk]
GO

CREATE PROCEDURE [dbo].[ImportExchangeQuotaStops_Bulk]
AS
BEGIN	
	-- процедура импортирует информацию о квотах из таблицы ExchangeQuotaStops
	--<version>2009.2.21</version>
	--<data>2014-03-06</data>

	SET NOCOUNT ON;
	
	declare @SvKey int, @Code int, @SubCode1 int, @SubCode2 int, @SubCode3 int, @Date datetime, @IsStop bit, @Places int, @PartnerKey int
	declare @qtKey int, @qoKey int, @qdKey int, @releaseConst int, @release int, @id int

	set @releaseConst = 365
	set @release = null
	
	declare ExchangeQuotaStops_cursor cursor local fast_forward for
	select EQS_ID, EQS_SvKey, EQS_Code, EQS_SubCode1, EQS_SubCode2, EQS_SubCode3, EQS_Date, EQS_IsStop, EQS_Places, EQS_PartnerKey
	from ExchangeQuotaStops 
	where EQS_IsProcessed = 0
	and EQS_SvKey = 3
	order by EQS_Date, EQS_IsStop;

	-- list of processed ExchangeQuotaStops keys
	create table #processedRecords
	(
		EQS_ID int
	)

	-- error during records processing flag
	declare @wasError as bit
	declare @errorMessage as nvarchar(max)
	set @wasError = 0

	begin try

		open ExchangeQuotaStops_cursor;
	
		fetch next from ExchangeQuotaStops_cursor into @id, @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @Places, @PartnerKey;	
		while @@FETCH_STATUS = 0
		begin		
		
			-- пришли обычные квоты
			if (@IsStop = 0 and @Places >= 0)
			begin

				if (not exists (select 1
										from Quotas join QuotaObjects on QT_ID = QO_QTID
										where QT_PRKey = @PartnerKey
										and QO_SVKey = @SvKey
										and QO_Code = @Code
										and QO_SubCode1 = @SubCode1
										and QO_SubCode2 = @SubCode3))
				begin
					insert into Quotas (QT_PRKey, QT_ByRoom, QT_Comment)
					values (@PartnerKey, 1, 'Quotas from Interlook. Load: ' + convert(nvarchar(max), GETDATE(), 121))
					set @qtKey = SCOPE_IDENTITY()
					
					insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
					values (@qtKey, @SvKey, @Code, @SubCode1, @SubCode3)
					set @qoKey = SCOPE_IDENTITY()
				end
				else
				begin
					select @qtKey = QT_ID, @qoKey = QO_ID
					from Quotas join QuotaObjects on QT_ID = QO_QTID
					where QT_PRKey = @PartnerKey
					and QO_SVKey = @SvKey
					and QO_Code = @Code
					and QO_SubCode1 = @SubCode1
					and QO_SubCode2 = @SubCode3
				end

				if not exists (select 1 from QuotaDetails with(nolock) where QD_QTID = @qtKey and QD_Date = @Date and QD_Type = 1)
				begin
					insert into QuotaDetails(QD_QTID, QD_Date, QD_Type, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey, QD_Release)
					values (@qtKey, @Date, 1, @Places, 0, GETDATE(), [dbo].[GetUserId](), @release)
					set @qdKey = SCOPE_IDENTITY()
				end
				else
				begin
					select top(1) @qdKey = QD_ID
					from QuotaDetails with(nolock) 
					where QD_QTID = @qtKey 
					and QD_Date = @Date 
					and QD_Type = 1

					update QuotaDetails
					set QD_Places = @Places,
					QD_Busy = 0,
					QD_Release = @release,
					QD_IsDeleted = null
					where QD_ID = @qdKey
				end
				
				if not exists (select 1 from QuotaParts where QP_QDID = @qdKey and QP_Date = @Date and QP_IsNotCheckIn = 0 and QP_Durations = '')
				begin
					insert into QuotaParts(QP_QDID, QP_Date, QP_Places, QP_Busy, QP_Limit, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey)
					values (@qdKey, @Date, @Places, 0, 1, 0, '', GETDATE(), [dbo].[GetUserId]())
				end
				else
				begin
					declare @qpKey int

					select top(1) @qpKey = QP_ID
					from QuotaParts 
					where QP_QDID = @qdKey 
					and QP_Date = @Date 
					and QP_IsNotCheckIn = 0 
					and QP_Durations = ''

					update QuotaParts
					set QP_Places = @Places,
					QP_Busy = 0,
					QP_Limit = 1,
					QP_IsDeleted = null
					where QP_ID = @qpKey

				end
			end
			else if (@IsStop = 1)
			begin
				-- пришел новый стоп, добавляем его
				if (@Places >= 0)
				begin
					if not exists (	select 1
									from QuotaObjects
									where QO_SVKey = @SvKey
									and QO_Code = @Code
									and QO_SubCode1 = @SubCode1
									and QO_SubCode2 = @SubCode3
									and QO_QTID is null)
					begin
						insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
						values (null, @SvKey, @Code, @SubCode1, @SubCode3)
						set @qoKey = SCOPE_IDENTITY()
					end
					else
					begin
						select @qoKey = QO_ID
						from QuotaObjects
						where QO_SVKey = @SvKey
						and QO_Code = @Code
						and QO_SubCode1 = @SubCode1
						and QO_SubCode2 = @SubCode3
						and QO_QTID is null
					end
				
					insert into StopSales(SS_QOID, SS_QDID, SS_PRKey, SS_Date, SS_AllotmentAndCommitment, SS_Comment, SS_CreateDate, SS_CreatorKey)
					values (@qoKey, null, @PartnerKey, @Date, 0, '', GETDATE(), [dbo].[GetUserId]())
				end
				else
				begin
					-- стоп удален
					if exists (select 1 
							   from QuotaObjects 
							   join StopSales on SS_QOID = QO_ID 
							   where QO_SVKey = @SvKey
								   and QO_Code = @Code
								   and QO_SubCode1 = @SubCode1
								   and QO_SubCode2 = @SubCode3
								   and QO_QTID is null
								   and ISNULL(SS_IsDeleted, 0) = 0)
					begin
						update StopSales
						set SS_IsDeleted = 1
						from QuotaObjects
						where SS_QOID = QO_ID
							and QO_SVKey = @SvKey
							and QO_Code = @Code
							and QO_SubCode1 = @SubCode1
							and QO_SubCode2 = @SubCode3
							and QO_QTID is null
							and ISNULL(SS_IsDeleted, 0) = 0
							and SS_Date = @Date
					end
				end
			end	
			
			-- обновим информацию о городе и строне вставленной квоты
			update quotaobjects
			set qo_ctkey = (select hd_ctkey from HotelDictionary where hd_key = qo_code)
			where qo_svkey = 3
			and QO_ID = @qoKey
					
			update quotaobjects
			set qo_cnkey= (select ct_cnKey from citydictionary where ct_key=qo_ctkey) 
			where qo_cnkey is null 
			and qo_ctkey is not null
			and QO_ID = @qoKey

			-- mark record for update IsProcessed flag
			insert into #processedRecords (EQS_ID)
			values (@id)

			fetch next from ExchangeQuotaStops_cursor into @id, @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @Places, @PartnerKey;		
		end
	
	end try
	begin catch
		set @wasError = 1
		set @errorMessage = error_message()
	end catch

	-- update IsProcessed flag in ExchangeQuotaStops table for processed records
	update ExchangeQuotaStops
	set EQS_IsProcessed = 1
	where EQS_ID in (select EQS_ID from #processedRecords)

	-- release resources
	close ExchangeQuotaStops_cursor;
	deallocate ExchangeQuotaStops_cursor;

	drop table #processedRecords

	-- rethrow error if needed
	if @wasError = 1
	begin
		RAISERROR(@errorMessage, 16, 1)
	end
END
GO

grant exec on [dbo].[ImportExchangeQuotaStops_Bulk] to public
go
/*********************************************************************/
/* end sp_ImportExchangeQuotaStops_Bulk.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_mwInsertTour.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwInsertTour]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[mwInsertTour]
GO

CREATE trigger [dbo].[mwInsertTour] on [dbo].[mwReplTours] for insert
as
begin
	--<VERSION>2009.2.20</VERSION>
	--<DATE>2014-07-04</DATE>
	if dbo.mwReplIsSubscriber() > 0
	begin
		SELECT rt_tokey as trkey, RT_CalcKey as calcKey, rt_trkey as tlkey, rt_overwritePrices as overwritePrices, rt_updateOnlinePrices as updateOnlinePrices, TO_CNKey as cnkey, ISNULL(TL_CTDepartureKey,0) as ctkeyfrom
		INTO #tmpKeys 
		FROM inserted
		join tbl_TurList on TL_KEY = rt_trkey
		join TP_Tours on TO_Key = rt_tokey

		declare replcur cursor fast_forward read_only for
		select trkey, calcKey, tlkey, overwritePrices, updateOnlinePrices, cnkey, ctkeyfrom from #tmpKeys

		declare @trkey int, @calcKey int, @tlkey int, @overwritePrices bit, @updateOnlinePrices smallint
		declare @cnKey int, @ctkeyfrom int

		open replcur

		fetch next from replcur into @trkey, @calcKey, @tlkey, @overwritePrices, @updateOnlinePrices, @cnKey, @ctkeyfrom
		while(@@fetch_status = 0)
		begin
			-- проверка: можно ли выставлять этот тур на этой базе
			-- MEG00040028. 09.02.2012. Golubinsky
			-- вынес проверку в функцию 
			if dbo.mwIsTourAllowedForPublish(@tlkey) = 1
			begin
				if (@calcKey = 0 or @calcKey is null)
				begin
					insert into mwReplQueue(rq_mode, rq_tokey, RQ_CalculatingKey, RQ_OverwritePrices, rq_cnkey, rq_ctkeyfrom)
					values(1, @trkey, @calcKey, @overwritePrices, @cnKey, @ctkeyfrom)
				end
				else if (ISNULL(@updateOnlinePrices, 0) <> 2)
				begin
					insert into mwReplQueue(rq_mode, rq_tokey, RQ_CalculatingKey, RQ_OverwritePrices, rq_cnkey, rq_ctkeyfrom)
					values(2, @trkey, @calcKey, @overwritePrices, @cnKey, @ctkeyfrom)
				end
				else
				begin
					insert into mwReplQueue(rq_mode, rq_tokey, RQ_CalculatingKey, RQ_OverwritePrices, rq_cnkey, rq_ctkeyfrom)
					values(6, @trkey, @calcKey, @overwritePrices, @cnKey, @ctkeyfrom)
				end
				
				if not exists(select 1 from mwReplDirections with(nolock) where rd_cnkey = @cnKey and rd_ctkeyfrom = @ctkeyfrom)
				begin
					insert into mwReplDirections (rd_cnkey, rd_ctkeyfrom)
					values(@cnKey, ISNULL(@ctkeyfrom, 0))
				end
			end
			fetch next from replcur into @trkey, @calcKey, @tlkey, @overwritePrices, @updateOnlinePrices, @cnKey, @ctkeyfrom
		end
		
		close replcur
		deallocate replcur	
	end
end
GO
/*********************************************************************/
/* end T_mwInsertTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_QuotaDetailsChange.sql */
/*********************************************************************/
if exists (select id from sysobjects where xtype = 'TR' and name='T_QuotaDetailsChange')
	drop trigger dbo.[T_QuotaDetailsChange]
go

CREATE TRIGGER [dbo].[T_QuotaDetailsChange]
ON [dbo].[QuotaDetails]
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2009.2.01</VERSION>
--<DATE>2012-12-28</DATE>
IF @@ROWCOUNT > 0 and exists(select 1 from SystemSettings with(nolock) where SS_ParmName like 'SYSQuotasToHistory' and ISNULL(SS_ParmValue, '0') <> '0')
BEGIN
	DECLARE @QO_SVKey int, @QO_Code int, @QT_Id int, @QT_ByRoom bit, @QT_PRKey int, @QT_PrtDogsKey int, @QD_ID int,
			@OQD_Type smallint, @OQD_Date smalldatetime, @OQD_Places smallint, @OQD_Busy smallint, @OQD_Release smallint, @OQD_IsDeleted smallint,
			@NQD_Type smallint, @NQD_Date smalldatetime, @NQD_Places smallint, @NQD_Busy smallint, @NQD_Release smallint, @NQD_IsDeleted smallint
    DECLARE @sText_Old varchar(255), @sText_New varchar(255), @sHI_Text varchar(255)
    DECLARE @sMod varchar(3), @nDelCount int, @nInsCount int, @nHIID int

	SELECT @nDelCount = COUNT(*) FROM DELETED
	SELECT @nInsCount = COUNT(*) FROM INSERTED
	IF (@nDelCount = 0)
	BEGIN
		SET @sMod = 'INS'
		DECLARE cur_QuotaDetails CURSOR LOCAL FOR 
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, N.QD_ID,
					null, null, null, null, null, null,
					N.QD_Type, N.QD_Date, N.QD_Places, N.QD_Busy, N.QD_Release, N.QD_IsDeleted
			FROM	INSERTED N join dbo.Quotas on N.QD_QTID = QT_ID
	END
	ELSE IF (@nInsCount = 0)
	BEGIN
		SET @sMod = 'DEL'
		DECLARE cur_QuotaDetails CURSOR LOCAL FOR
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, O.QD_ID,
					O.QD_Type, O.QD_Date, O.QD_Places, O.QD_Busy, O.QD_Release, O.QD_IsDeleted,
					null, null, null, null, null, null
			FROM	DELETED O join dbo.Quotas on O.QD_QTID = QT_ID
	END
	ELSE 
	BEGIN
		SET @sMod = 'UPD'
		DECLARE cur_QuotaDetails CURSOR LOCAL FOR
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, N.QD_ID,
					O.QD_Type, O.QD_Date, O.QD_Places, O.QD_Busy, O.QD_Release, O.QD_IsDeleted,
					N.QD_Type, N.QD_Date, N.QD_Places, N.QD_Busy, N.QD_Release, N.QD_IsDeleted
			FROM	DELETED O join dbo.Quotas on O.QD_QTID = QT_ID
					join INSERTED N on N.QD_QTID = QT_ID
	END

	OPEN cur_QuotaDetails
	FETCH NEXT FROM cur_QuotaDetails INTO @QT_Id, @QT_ByRoom, @QT_PRKey, @QT_PrtDogsKey, @QD_ID,
					@OQD_Type, @OQD_Date, @OQD_Places, @OQD_Busy, @OQD_Release, @OQD_IsDeleted,
					@NQD_Type, @NQD_Date, @NQD_Places, @NQD_Busy, @NQD_Release, @NQD_IsDeleted
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OQD_Type, 0) !=			ISNULL(@NQD_Type, 0) OR
			ISNULL(@OQD_Date, 0) !=			ISNULL(@NQD_Date, 0) OR
			ISNULL(@OQD_Places, 0) !=		ISNULL(@NQD_Places, 0) OR
			ISNULL(@OQD_Busy, 0) !=			ISNULL(@NQD_Busy, 0) OR
			ISNULL(@OQD_Release, 0) !=		ISNULL(@NQD_Release, 0) OR
			ISNULL(@OQD_IsDeleted, 0) !=	ISNULL(@NQD_IsDeleted, 0)
			)
		BEGIN
			------------Запись в историю--------------------------------------------------------------------
			If @QT_PRKey = 0
				Set @sHI_Text = 'All partners'
			Else
				Select @sHI_Text = PR_Name from Partners where PR_Key = @QT_PRKey
			SET @sText_New=@sHI_Text
			Set @sHI_Text = null
			If isnull(@QT_PrtDogsKey,0) >0
				Select @sHI_Text = PD_DogNumber from PrtDogs where PD_Key=@QT_PrtDogsKey
			If @sHI_Text is not null
				SET @sText_New=@sText_New + '(' + @sHI_Text + ')'
			
			Select TOP 1 @QO_SVKey=QO_SVKey, @QO_Code=QO_Code FROM QuotaObjects WHERE QO_QTID=@QT_Id
			If @QO_SVKey=3
			BEGIN
				If @QT_ByRoom=0
					SET @sText_New=@sText_New + '(BY PERSON)'
				Else
					SET @sText_New=@sText_New + '(BY ROOM)'
			END

			EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 34,
							@nTypeCode = @QD_ID,
							@sMod = @sMod,
							@sText = @sText_New,
							@sRemark = @sHI_Text,
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = @QO_SVKey,
							@nCode = @QO_Code
			SET @sText_Old = ''
			SET @sText_New = ''
				
			--------Детализация--------------------------------------------------
			if ISNULL(@OQD_Type, 0) != ISNULL(@NQD_Type, 0)
			begin				
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34001, @OQD_Type, @NQD_Type, @OQD_Type, @NQD_Type, null, null, 0
			end
			if ISNULL(@OQD_Date, 0) != ISNULL(@NQD_Date, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34002, @OQD_Date, @NQD_Date, null, null, null, null, 0
			END
			if ISNULL(@OQD_Places, 0) != ISNULL(@NQD_Places, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34003, @OQD_Places, @NQD_Places, @OQD_Places, @NQD_Places, null, null, 0
			END
			if ISNULL(@OQD_Busy, 0) != ISNULL(@NQD_Busy, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34004, @OQD_Busy, @NQD_Busy, @OQD_Busy, @NQD_Busy, null, null, 0
			END
			if ISNULL(@OQD_Release, 0) != ISNULL(@NQD_Release, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34005, @OQD_Release, @NQD_Release, @OQD_Release, @NQD_Release, null, null, 0
			END
			if ISNULL(@OQD_IsDeleted, 0) != ISNULL(@NQD_IsDeleted, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34006, @OQD_IsDeleted, @NQD_IsDeleted, @OQD_IsDeleted, @NQD_IsDeleted, null, null, 0
			END
		END
		
		FETCH NEXT FROM cur_QuotaDetails INTO @QT_Id, @QT_ByRoom, @QT_PRKey, @QT_PrtDogsKey, @QD_ID,
					@OQD_Type, @OQD_Date, @OQD_Places, @OQD_Busy, @OQD_Release, @OQD_IsDeleted,
					@NQD_Type, @NQD_Date, @NQD_Places, @NQD_Busy, @NQD_Release, @NQD_IsDeleted
    END
	CLOSE cur_QuotaDetails
	DEALLOCATE cur_QuotaDetails
END

-- 04-07-2012 karimbaeva если изменился тип квоты, то меняем статус квоты и в путевках, которые сидят в этой квоте
-- 02-07-2014 buryak при изменении QuotaDetails из триггера [T_ServiceByDateChanged] происходил повторный заход в триггер T_ServiceByDateChanged, повторно создавался курсор cur_ServiceByDateChanged
if @sMod = 'UPD' and ISNULL(@OQD_Type, 0) != ISNULL(@NQD_Type, 0)
begin	
	update ServiceByDate
	set SD_State = QD_Type
	from inserted with(nolock) 
	join QuotaParts with(nolock) on QD_ID = QP_QDID 
	where SD_QPID = QP_ID 
	and SD_State <> QD_Type 
end
GO
/*********************************************************************/
/* end T_QuotaDetailsChange.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TuristUpdate.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_TuristUpdate]'))
DROP TRIGGER [dbo].[T_TuristUpdate]
GO

CREATE TRIGGER [dbo].[T_TuristUpdate]
ON [dbo].[tbl_Turist] 
FOR UPDATE, INSERT, DELETE
AS
--<DATE>2014-07-10</DATE>
--<VERSION>2009.2.20.17</VERSION>
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
			ISNULL(@OTU_ISMAIN, 0) != ISNULL(@NTU_ISMAIN, 0) OR 
			ISNULL(@OTU_EMAIL, '') != ISNULL(@NTU_EMAIL, '') OR 
			ISNULL(@OTU_PHONE, '') != ISNULL(@NTU_PHONE, '')
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
-- =====================   Обновление версии БД. 9.2.20.17 - номер версии, 2014-07-11 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.17', st_moduledate = convert(datetime, '2014-07-11', 120),  st_financeversion = '9.2.20.17', st_financedate = convert(datetime, '2014-07-11', 120)
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
	SET SS_ParmValue='2014-07-11' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO