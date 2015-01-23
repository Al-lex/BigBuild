/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 05.12.2013 19:44 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.2'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.3'

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
/* begin (2013_11_22)_AlterTable_QuestionnaireFieldCase.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM dbo.syscolumns WHERE name = 'QFC_IsDefault' AND id = object_id(N'[dbo].[QuestionnaireFieldCase]'))
BEGIN
	ALTER TABLE dbo.QuestionnaireFieldCase ADD QFC_IsDefault BIT NOT NULL DEFAULT '0'
END
GO

/*********************************************************************/
/* end (2013_11_22)_AlterTable_QuestionnaireFieldCase.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.11.26)_INSERT_INTO_ACTIONS.sql */
/*********************************************************************/
-- Добавление action Редактирование номера путевки
IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 145) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) VALUES (145, 'Турпутевка->Запретить редактирование номера путевки', 'Запретить редактирование номера путевки', 'Reservation->Deny edit voucher number', 1);
END	
GO

-- Добавление action Перерасчет только на дату оформления путевки
IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 146) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) VALUES (146, 'Турпутевка->Перерасчет только на дату оформления путевки', 'Запретить пересчет путевки на текущую или выбранную дату, пересчет только на дату оформления путевки', 'Reservation->Recalculation only on the create date of tour', 1);
END
GO

/*********************************************************************/
/* end (2013.11.26)_INSERT_INTO_ACTIONS.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckQuotaExist.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckQuotaExist]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckQuotaExist]
GO

CREATE PROCEDURE [dbo].[CheckQuotaExist]
(
--<DATE>2013-11-28</VERSION>
--<VERSION>2009.2.22</VERSION>
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
			
	print @Query

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
		
		select @Places_Count = SUM(TMP_Count) from @Tbl_DQ where TMP_Count > 0 and TMP_ByRoom = 0 and TMP_ReleaseIgnore = 0
		select @Places_Count_ReleaseIgnore = SUM(TMP_Count) from @Tbl_DQ where TMP_Count > 0 and TMP_ByRoom = 0 and TMP_ReleaseIgnore = 1
		
		If (@SVKey in (3) or (@SVKey=8 and EXISTS(SELECT TOP 1 1 FROM [Service] WHERE SV_KEY=@SVKey AND SV_QUOTED=1)))
		begin
			select @Rooms_Count = SUM(TMP_Count) from @Tbl_DQ where TMP_Count > 0 and TMP_ByRoom = 1 and TMP_ReleaseIgnore = 0
			select @Rooms_Count_ReleaseIgnore = SUM(TMP_Count) from @Tbl_DQ where TMP_Count > 0 and TMP_ByRoom = 1 and TMP_ReleaseIgnore = 1
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
/* begin sp_CopyTpPricesUpdatedToSubscriptions.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CopyTpPricesUpdatedToSubscriptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CopyTpPricesUpdatedToSubscriptions]
GO
CREATE PROCEDURE [dbo].[CopyTpPricesUpdatedToSubscriptions]
AS
-- копирует данные из таблицы TP_PricesUpdated на все подписчики
--<DATE>2013-03-06</DATE>
--<VERSION>9.2.19</VERSION>
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
			
			DECLARE @subscriptionLinkedServer as nvarchar(50)
			DECLARE @subscriptionDatabaseName as nvarchar(100)			

			DECLARE subscriptionsCursor CURSOR FOR
			SELECT linkedServerName, subscriptionDatabaseName
			FROM [dbo].[mwReplGetSubscriptions]()

			BEGIN TRY

				OPEN subscriptionsCursor

				FETCH NEXT FROM subscriptionsCursor INTO @subscriptionLinkedServer, @subscriptionDatabaseName
				
				WHILE @@Fetch_Status = 0
				BEGIN
			
					print @subscriptionLinkedServer
					SET @source = @subscriptionLinkedServer + '.' + @subscriptionDatabaseName
				
					SET @sql = '
					insert into ' + @source + '.dbo.TP_PricesUpdated with(rowlock) ([TPU_Key], [TPU_TPKey], [TPU_IsChangeCostMode], [TPU_TPGrossOld], [TPU_TPGrossDelta], [TPU_DateUpdate]) 
					select [TPU_Key], [TPU_TPKey], [TPU_IsChangeCostMode], [TPU_TPGrossOld], [TPU_TPGrossDelta], [TPU_DateUpdate] 
					from #TP_PricesUpdated src with (nolock)
					where src.TPU_Key not in (select TPU_Key from ' + @source + '.dbo.TP_PricesUpdated with (nolock))
					';
										
					PRINT(@sql)
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
/* begin sp_GetCalendarTourDates.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetCalendarTourDates]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetCalendarTourDates]
GO

--<VERSION>9.2.18</VERSION>
--<DATE>2013-11-27</DATE>
CREATE PROCEDURE [dbo].[GetCalendarTourDates]
	@departFromKey INT,
	@countryKey INT,
	@tourKey INT = null,
	@resORtKey INT = null,
	@tourTypeKey INT = null,
	@cityKey INT = null
AS
BEGIN
	SET DATEFIRST 1
	
	DECLARE @mwSearchType INT
	SELECT @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) FROM dbo.systemsettings 
	WHERE SS_ParmName = 'MWDivideByCountry'
	
	DECLARE @tableName NVARCHAR(100)
	IF (@mwSearchType = 0)
		SET @tableName = 'dbo.mwPriceDataTable'
	ELSE
		SET @tableName = dbo.mwGetPriceTableName(@countryKey, @departFromKey)	
		
	DECLARE @sql NVARCHAR(4000)
	SET @sql = 'SELECT DISTINCT DATEDIFF(ss, ''1970-01-01'', TP_TurDates.TD_Date) AS [key],
					CONVERT(varchar, TP_TurDates.TD_Date, 4) AS name,
					TP_TurDates.TD_Date
				FROM TP_TurDates 
					INNER JOIN mwSpoData with(nolock) ON TP_TurDates.TD_TOKey = mwSpoData.sd_tourkey
					LEFT JOIN
					(
						SELECT distinct TD_Date
						FROM TP_TurDates
							INNER JOIN QuotaDetails ON QD_Date = TD_Date
							INNER JOIN Quotas ON QD_QTID = QT_ID
							INNER JOIN QuotaObjects ON QT_ID = QO_QTID AND QO_SVKey = 1
							INNER JOIN Charter ON QO_Code = CH_KEY
							LEFT JOIN StopSales as s1 ON s1.SS_QDID = QD_ID
							LEFT JOIN StopSales as s2 ON s2.SS_QOID = QO_ID
						WHERE
							(((QD_Places - QD_Busy) <= 0 AND QO_CNKey = @countryKey AND CH_CITYKEYFROM = @departFromKey)
							OR (s1.SS_ID IS NOT NULL AND ISNULL(s1.SS_IsDeleted, 0) <> 1)
							OR (s2.SS_ID IS NOT NULL AND ISNULL(s2.SS_IsDeleted, 0) <> 1))
							AND  TD_Date NOT IN
								(SELECT distinct QD_Date
								FROM QuotaDetails
									INNER JOIN Quotas ON QD_QTID = QT_ID
									INNER JOIN QuotaObjects ON QT_ID = QO_QTID AND QO_SVKey = 1
									INNER JOIN Charter ON QO_Code = CH_Key
									LEFT JOIN StopSales as s1 ON s1.SS_QDID = QD_ID
									LEFT JOIN StopSales as s2 ON s2.SS_QOID = QO_ID
								WHERE (QD_Places - QD_Busy) > 0
									AND (s1.SS_ID IS NULL OR ISNULL(s1.SS_IsDeleted, 0) = 1)
									AND (s2.SS_ID IS NULL OR ISNULL(s2.SS_IsDeleted, 0) = 1))
					) AS t ON t.TD_Date = TP_TurDates.TD_Date
				WHERE TP_TurDates.TD_Date > DATEADD(day, - 1, GETDATE())
					AND mwSpoData.sd_ctkeyfrom = @departFromKey
					AND mwSpoData.sd_cnkey = @countryKey
					AND t.TD_Date IS NULL'
             
	IF @tourKey is not null
	BEGIN
		SET @sql += ' AND mwSpoData.sd_tourkey = @tourKey AND exists(SELECT TOP 1 1 FROM ' + @tableName + ' WHERE pt_tourkey = @tourKey AND pt_tourdate = TP_TurDates.TD_Date) '
	END
	IF @resORtKey is not null
		SET @sql += ' AND mwSpoData.sd_rskey = @resORtKey '
	if @tourTypeKey is not null
		SET @sql += ' AND mwSpoData.sd_tourtype = @tourTypeKey '
	if @cityKey is not null
		SET @sql += ' AND mwSpoData.sd_ctkey = @cityKey '        
    
    SET @sql += ' ORDER BY TP_TurDates.TD_Date '
    
    DECLARE @paramDef NVARCHAR(500)
    SET @paramDef = ' @departFromKey INT, 
				  @countryKey INT, 
				  @tourKey INT = NULL, 
				  @resORtKey INT = NULL, 
				  @tourTypeKey INT = NULL, 
				  @cityKey INT = NULL, 
				  @tableName NVARCHAR(100) = NULL'
       
    exec sp_executesql @sql, @paramDef,
							 @departFromKey = @departFromKey, 
							 @countryKey = @countryKey, 
							 @tourKey = @tourKey,
							 @resORtKey = @resORtKey,
							 @tourTypeKey = @tourTypeKey,
							 @cityKey = @cityKey
 
END

GO

grant exec on [dbo].[GetCalendarTourDates] to public
GO
/*********************************************************************/
/* end sp_GetCalendarTourDates.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetServiceList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceList]
GO

CREATE procedure [dbo].[GetServiceList] 
(
--<VERSION>2009.2.20.1</VERSION>
--<DATE>2013-12-05</DATE>
@TypeOfRelult int, -- 1-список по услугам, 2-список по туристам на услуге
@SVKey int, 
@Codes varchar(100), 
@SubCode1 int=null,
@Date datetime =null, 
@QDID int =null,
@QPID int =null,
@ShowHotels bit =null,
@ShowFligthDep bit =null,
@ShowDescription bit =null,
@State smallint=null,
@SubCode2 int = null,
@PrKey int = null
)
as 

--koshelev
--2012-07-19 TFS 6699 блокировки на базе мешали выполнению хранимки, вынужденная мера
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @Query varchar(8000)
 
CREATE TABLE #Result
(
	DG_Code nvarchar(max), DG_Key int, DG_DiscountSum money, DG_Price money, DG_Payed money,
	DG_PriceToPay money, DG_Rate nvarchar(3), DG_NMen int, PR_Name nvarchar(max), PR_Name_Lat nvarchar(max), CR_Name nvarchar(max), CR_Name_Lat nvarchar(max),
	DL_Key int, DL_NDays int, DL_NMen int, DL_Reserved int, DL_CTKeyTo int, DL_CTKeyFrom int, DL_CNKEYFROM int,
	DL_SubCode1 int, TL_Key int, TL_Name nvarchar(max), TL_Name_Lat nvarchar(max),  TUCount int, TU_NameRus nvarchar(max), TU_NameLat nvarchar(max),
	TU_FNameRus nvarchar(max), TU_FNameLat nvarchar(max), TU_Key int, TU_Sex Smallint, TU_PasportNum nvarchar(max),
	TU_PasportType nvarchar(max), TU_PasportDateEnd datetime, TU_BirthDay datetime, TU_Hotels nvarchar(max), TU_Hotels_Lat nvarchar(max),
	Request smallint, Commitment smallint, Allotment smallint, Ok smallint, TicketNumber nvarchar(max),
	FlightDepDLKey int, FligthDepDate datetime, FlightDepNumber nvarchar(max), ServiceDescription nvarchar(max), ServiceDescription_Lat nvarchar(max),
	ServiceDateBeg datetime, ServiceDateEnd datetime, RM_Name nvarchar(max), RC_Name nvarchar(max), SD_RLID int,
	TU_SNAMERUS nvarchar(max), TU_SNAMELAT nvarchar(max), TU_IDKEY int
)
 
if @TypeOfRelult = 2
begin
	--- создаем таблицу в которой пронумируем незаполненых туристов
	CREATE TABLE #TempServiceByDate
	(
		SD_ID int identity(1,1) not null,
		SD_Date datetime,
		SD_DLKey int,
		SD_RLID int,
		SD_QPID int,
		SD_TUKey int,
		SD_RPID int,
		SD_State int
	)

	-- вносим все записи которые нам могут подойти
	insert into #TempServiceByDate(SD_Date, SD_DLKey, SD_RLID, SD_QPID,	SD_TUKey, SD_RPID, SD_State)
	select SD_Date, SD_DLKey, SD_RLID, SD_QPID,	SD_TUKey, SD_RPID, SD_State
	from ServiceByDate as SSD join Dogovorlist on DL_KEY = SD_DLKey
	where DL_SVKEY = @SVKey
	and DL_CODE = convert(int, @Codes)
	and ((@SubCode1 is null) or (DL_SUBCODE1 = @SubCode1))
	and ((@QPID is null) or (SD_QPID = @QPID))
	and ((@State is null) or (SD_State = @State))
	--mv 24.10.2012 не понячл зачем нужен был подзапрос, но точно он приводил к следущей проблеме
	-- если отбираем с фильтром по статусу, то статус проверял на любой из дней, а не тот на который формируется список
	and SSD.SD_Date = @Date and (@PrKey is null or DL_PARTNERKEY = @PrKey)
	--and exists (select 1 from ServiceByDate as SSD2 where SSD.SD_DLKey = SSD2.SD_DLKey and SSD2.SD_Date = @Date)
	
	declare @Id int, @SDDate datetime, @SDDLKey int, @SDTUKey int,
	@oldDlKey int, @oldDate datetime, @i int

	set @i = -1
	 
	DECLARE noBodyTurists CURSOR FOR 
	select SD_ID, SD_Date, SD_DLKey, SD_TUKey
	from #TempServiceByDate
	where SD_TUKey is null
	order by SD_DLKey, SD_Date

	OPEN noBodyTurists
	FETCH NEXT FROM noBodyTurists INTO @Id, @SDDate, @SDDLKey, @SDTUKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- если мы встретили новую дату или услугу то сбрасываем счетчик
		if @oldDlKey != @SDDLKey or @oldDate != @SDDate
		begin
			set @i = -1
		end
			
		update #TempServiceByDate
		set SD_TUKey = @i
		where SD_ID = @Id
		
		set @i = @i - 1

		set @oldDlKey = @SDDLKey
		set @oldDate = @SDDate
		
		FETCH NEXT FROM noBodyTurists INTO @Id, @SDDate, @SDDLKey, @SDTUKey
	END
	CLOSE noBodyTurists
	DEALLOCATE noBodyTurists 

	--select * from #TempServiceByDate

	-- 29.10.13 Гусак изменил привязку покупателя
	-- с left join Partners on dl_agent = pr_key
	-- на 		left join Partners on dg_partnerkey = pr_key
	SET @Query = '
		INSERT INTO #Result (DG_Code, DG_Key, DG_DiscountSum, DG_Price, DG_Payed, 
		DG_PriceToPay, DG_Rate, DG_NMen, 
		PR_Name, PR_Name_Lat, CR_Name,  CR_Name_Lat,
		DL_Key, DL_NDays, DL_NMen, DL_Reserved, DL_CTKeyTo, DL_CTKeyFrom, DL_SubCode1, ServiceDateBeg, ServiceDateEnd, 
		TL_Key, TUCount, TU_NameRus, TU_NameLat, TU_FNameRus, TU_FNameLat, TU_Key, 
		TU_Sex, TU_PasportNum, TU_PasportType, TU_PasportDateEnd, TU_BirthDay, TicketNumber, TU_SNAMERUS, TU_SNAMELAT, TU_IDKEY)
		SELECT	  DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, 
		(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN, 
		PR_NAME, PR_NAMEENG, CR_NAME, CR_NameLat, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, 
		DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + '=3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END,
		DG_TRKey, 0, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS, TU_FNAMELAT, SD_TUKey, case when SD_TUKey > 0 then isnull(TU_SEX,0) else null end, TU_PASPORTTYPE + ''№'' + TU_PASPORTNUM, TU_PASPORTTYPE, 
		TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, TU_SNAMERUS, TU_SNAMELAT, TU_IDKEY
		FROM  Dogovor join Dogovorlist on dl_dGKEY = DG_KEY
--		left join Partners on dl_agent = pr_key
		left join Partners on dg_partnerkey = pr_key
		join Controls on dl_control = cr_key
		join #TempServiceByDate on SD_DLKey = DL_KEY
		left join TuristService on tu_dlkey = dl_key and TU_TUKEY = SD_TUKey
		left join Turist on tu_key = tu_tukey
		WHERE '

		SET @Query=@Query + '
			 DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' AND DL_CODE in (' + @Codes + ') AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND '

		IF @QPID is not null or @QDID is not null
		BEGIN
			IF @QPID is not null
				SET @Query=@Query + 'and SD_QPID IN (' + CAST(@QPID as varchar(20)) + ')'
			ELSE
				--buryak
				--2013-02-20 TFS 11520 MT.Экран "Список на услугу".Не отображались путевки без туристов.
				SET @Query=@Query + 'and exists (SELECT top 1 SD_DLKEY FROM #TempServiceByDate, QuotaParts WHERE SD_QPID=QP_ID and QP_QDID IN (' + CAST(@QDID as varchar(20)) + ') and SD_DLKEY=DL_Key and (tu_tukey is null or sd_tukey = tu_tukey))'
		END
				
		if (@SubCode1 != '0')
			SET @Query=@Query + ' AND DL_SUBCODE1 in (' + CAST(@SubCode1 as varchar(20)) + ')'
		IF @State is not null
			SET @Query=@Query + ' and SD_State=' + CAST(@State as varchar(1))
		if (@SubCode2 != '0')
			SET @Query=@Query + ' AND DL_SUBCODE2 in (' + CAST(@SubCode2 as varchar(20)) + ')'
		SET @Query=@Query + ' 
		group by DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, DG_PDTTYPE, DG_RATE, DG_NMEN, 
		PR_NAME, PR_NAMEENG, CR_NAME, CR_NameLat, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, DL_DateBeg,
		DL_DateEnd, DG_TRKey, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS,
		TU_FNAMELAT, SD_TUKey, TU_SEX, TU_PASPORTNUM, TU_PASPORTTYPE, TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, TU_SNAMERUS, TU_SNAMELAT, TU_IDKEY'
end
else
begin
	-- 29.10.13 Гусак изменил привязку покупателя
	-- с left join Partners on dl_agent = pr_key
	-- на 		left join Partners on dg_partnerkey = pr_key
	SET @Query = '
		INSERT INTO #Result (DG_Code, SD_RLID, RM_Name, RC_Name, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		DG_PriceToPay, DG_RATE, DG_NMEN,
		PR_NAME, PR_Name_Lat, CR_NAME, CR_NAME_Lat, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKeyTo, DL_SubCode1,
		ServiceDateBeg, ServiceDateEnd, TL_Key, TUCount, DL_Key, DL_CTKeyFrom)
		select DG_CODE, SD_RLID, RM_Name, RC_Name, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		(case when DG_PDTTYPE = 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN,
		PR_NAME, PR_NAMEENG, CR_NAME, CR_NAMELat, DL_NDays, 
		--mv 24.10.2012 -убрал очень странный код - в поле кол-во человек выводилосб количество комнат, сделал количество мест хотя бы
		--case when QT_ByRoom = 1 then count(distinct SD_RLID) else count(distinct SD_RPID) end as DL_NMEN,
		COUNT(SD_RPID),
		DL_RESERVED, DL_CTKey, DL_SubCode2, DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + ' = 3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END, DG_TRKey, Count(distinct SD_TUKey), DL_KEY, DL_SubCode2
		from ServiceByDate left join RoomNumberLists on sd_rlid = rl_id
		left join Rooms on rl_rmkey = rm_key
		left join RoomsCategory on rl_rckey = rc_key
		left join QuotaParts on sd_qpid = qp_id
		left join QuotaDetails on QP_QDID = QD_ID and QP_Date = QD_Date
		left join Quotas on QT_ID = QD_QTID
		join Dogovorlist on sd_dlkey = dl_key
		join Controls on dl_control = cr_key
--		left join Partners on dl_agent = pr_key
		join Dogovor on dl_dGKEY = DG_KEY
		left join Partners on dg_partnerkey = pr_key
		where DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' 
			AND DL_CODE in (' + @Codes + ') 
			AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND
			--mv 24.10.2012 добавил фильтр по дате SD, так как просмотр идет относительно этой даты
			AND SD_Date = ''' + CAST(@Date as varchar(20)) + ''' '
		
	if @QDID is not null
		SET @Query = @Query + ' and qp_qdid = ' + CAST(@QDID as nvarchar(max))
	if @QPID is not null
		SET @Query = @Query + ' and qp_id = ' + CAST(@QPID as nvarchar(max))
	IF @State is not null
		SET @Query=@Query + ' and SD_State=' + CAST(@State as varchar(1))
	-- mv 24.10.2012 - не было фильтра по услуге, в список попадали лишние
	IF @SubCode1 is not null
		SET @Query=@Query + ' and DL_SUBCODE1 = ' + CAST(@SubCode1 as varchar(20))
	
	SET @Query = @Query + '
		group by DG_CODE, SD_RLID, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		DG_PDTTYPE, DG_DISCOUNTSUM, DG_RATE, DG_NMEN,
		PR_NAME, PR_NAMEENG, CR_NAME,CR_NAMELat, DL_NDays, DL_RESERVED, DL_CTKey, DL_SubCode2,
		DL_DateBeg, DL_DateEnd, DG_TRKey, RM_Name, RC_Name, QT_ByRoom, DL_KEY'
end

--PRINT @Query
EXEC (@Query)
 
UPDATE #Result SET #Result.TL_Name=(SELECT TL_Name FROM TurList WHERE #Result.TL_Key=TurList.TL_Key)
UPDATE #Result SET #Result.TL_Name_Lat=(SELECT TL_NameLat FROM TurList WHERE #Result.TL_Key=TurList.TL_Key)

--select * from  #Result

if @TypeOfRelult=1
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=1)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=3)
END
else
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=1)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=3)
END
 
IF @ShowHotels=1
BEGIN
	IF @TypeOfRelult = 2
	BEGIN
		DECLARE @HD_Name varchar(100), @HD_Name2_Lat varchar(100),  @HD_Stars varchar(25), @PR_Name varchar(100), @PR_Name_Lat varchar(100), @TU_Key int, @HD_Key int, @PR_Key int, @TU_KeyPrev int, @TU_Hotels varchar(255), @TU_Hotels_Lat varchar(255)
		DECLARE curServiceList CURSOR FOR 
			SELECT	  DISTINCT HD_Name, HD_NAMELAT, HD_Stars, PR_Name, PR_NAMEENG, TU_TUKey, HD_Key, PR_Key 
			FROM  HotelDictionary, DogovorList, TuristService, Partners
			WHERE	  PR_Key=DL_PartnerKey and HD_Key=DL_Code and TU_DLKey=DL_Key and TU_TUKey in (SELECT TU_Key FROM #Result) and dl_SVKey=3 
			ORDER BY TU_TUKey
		OPEN curServiceList
		FETCH NEXT FROM curServiceList INTO	  @HD_Name,@HD_Name2_Lat, @HD_Stars,@PR_Name, @PR_Name_Lat, @TU_Key, @HD_Key, @PR_Key
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @TU_Key!=@TU_KeyPrev or @TU_KeyPrev is null
			begin
			  Set @TU_Hotels=@HD_Name+' '+@HD_Stars+' ('+@PR_Name+')'
			  Set @TU_Hotels_Lat=@HD_Name2_Lat+' '+@HD_Stars+' ('+@PR_Name_Lat+')'
			end
			ELSE
			begin
			  Set @TU_Hotels=@TU_Hotels+', '+@HD_Name+' '+@HD_Stars+' ('+@PR_Name+')'
			  Set @TU_Hotels_Lat=@TU_Hotels_Lat+', '+@HD_Name2_Lat+' '+@HD_Stars+' ('+@PR_Name_Lat+')'
			end
			UPDATE #Result SET TU_Hotels=@TU_Hotels WHERE TU_Key=@TU_Key
			UPDATE #Result SET TU_Hotels_Lat=@TU_Hotels_Lat WHERE TU_Key=@TU_Key
			SET @TU_KeyPrev=@TU_Key
			FETCH NEXT FROM curServiceList INTO	   @HD_Name,@HD_Name2_Lat, @HD_Stars, @PR_Name, @PR_Name_Lat, @TU_Key, @HD_Key, @PR_Key
		END
		CLOSE curServiceList
		DEALLOCATE curServiceList
	END
	IF @TypeOfRelult = 1
	BEGIN
		DECLARE @HD_Name1 varchar(100), @HD_Name1_lat varchar(100), @HD_Stars1 varchar(25), @PR_Name1 varchar(100), @PR_Name1_Lat varchar(100), @DL_Key1 int, @HD_Key1 int, 
				@PR_Key1 int, @DL_KeyPrev1 int, @TU_Hotels1 varchar(255), @TU_Hotels1_Lat varchar(255), @DG_Key int, @DG_KeyPrev int
		DECLARE curServiceList CURSOR FOR 
			--SELECT DISTINCT HD_Name, HD_Stars, P.PR_Name, DogList.DL_Key, HD_Key, PR_Key--, DG_Key
			--FROM HotelDictionary, DogovorList DogList, TuristService, Partners P
			--WHERE P.PR_Key = DogList.DL_PartnerKey and HD_Key = DogList.DL_Code and TU_DLKey = DogList.DL_Key and
			--TU_TUKey in (SELECT TU_TUKEY FROM TuristService WHERE TU_DLKEY in (SELECT DL_KEY FROM #Result)) 
			--and DL_SVKey=3 
			--ORDER BY DogList.DL_Key
			SELECT DISTINCT HD_Name, HD_NameLat, HD_Stars, HD_Key, P.PR_Name, PR_NAMEENG, P.PR_Key, DogList.DL_Key, R.DG_Key
			FROM HotelDictionary, DogovorList DogList, Partners P, #Result R
			WHERE P.PR_Key = DogList.DL_PartnerKey and HD_Key = DogList.DL_Code and DogList.DL_DGKey = R.DG_Key			
				  and DogList.DL_SVKey=3 
			ORDER BY R.DG_Key
		OPEN curServiceList
		FETCH NEXT FROM curServiceList INTO @HD_Name1, @HD_Name1_lat, @HD_Stars1, @HD_Key1, @PR_Name1, @PR_Name1_Lat, @PR_Key1, @DL_Key1, @DG_Key
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @DG_Key != @DG_KeyPrev or @DG_KeyPrev is null  
			BEGIN
			  Set @TU_Hotels1=@HD_Name1+' '+@HD_Stars1+' ('+@PR_Name1+')'
			  Set @TU_Hotels1_Lat=@HD_Name1_lat+' '+@HD_Stars1+' ('+@PR_Name1_Lat+')'
			END
			ELSE
			BEGIN
			  Set @TU_Hotels1=@TU_Hotels1+', '+@HD_Name1+' '+@HD_Stars1+' ('+@PR_Name1+')'
			  Set @TU_Hotels1=@TU_Hotels1_Lat+', '+@HD_Name1_lat+' '+@HD_Stars1+' ('+@PR_Name1_Lat+')'
			END
			UPDATE #Result SET TU_Hotels=@TU_Hotels1 WHERE DG_Key=@DG_Key --DL_Key=@DL_Key1
			UPDATE #Result SET TU_Hotels_Lat=@TU_Hotels1_Lat WHERE DG_Key=@DG_Key --DL_Key=@DL_Key1
			SET @DG_KeyPrev = @DG_Key
			FETCH NEXT FROM curServiceList INTO @HD_Name1, @HD_Name1_lat, @HD_Stars1, @HD_Key1, @PR_Name1, @PR_Name1_Lat, @PR_Key1, @DL_Key1, @DG_Key
		END
		CLOSE curServiceList
		DEALLOCATE curServiceList
	END
END
 
IF @ShowFligthDep=1 and @SVKey=1
BEGIN
	IF @TypeOfRelult = 2
	BEGIN
		Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList,TuristService Where TU_DLKey=DL_Key and DL_DGKey=#Result.DG_Key and DL_CTKey=#Result.DL_CTKeyFrom and DL_SubCode2=#Result.DL_CTKeyTo and TU_TUKey=#Result.TU_Key and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc)
		if exists (select 1 from #Result Where FlightDepDLKey is null)
			Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList,TuristService Where TU_DLKey=DL_Key and DL_DGKey=#Result.DG_Key and DL_CTKey=#Result.DL_CTKeyFrom and TU_TUKey=#Result.TU_Key and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc) where FlightDepDLKey is null
		--если по городу не нашли ишем по стране
		if exists (select 1 from #Result Where FlightDepDLKey is null)     
		begin
			update #Result set DL_CNKEYFROM = (select top 1 ct_cnkey from citydictionary where ct_key =#Result.DL_CTKEYFROM)
			Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList,TuristService Where TU_DLKey=DL_Key and DL_DGKey=#Result.DG_Key and DL_CNKey=#Result.DL_CNKeyFrom and TU_TUKey=#Result.TU_Key and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc)	where FlightDepDLKey is null	  
		end
	END
	ELSE
	BEGIN
		Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList Where DL_DGKey=#Result.DG_Key and DL_CTKey=#Result.DL_CTKeyFrom and DL_SubCode2=#Result.DL_CTKeyTo and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc)
		if exists (select 1 from #Result Where FlightDepDLKey is null)
			Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList Where DL_DGKey=#Result.DG_Key and DL_CTKey=#Result.DL_CTKeyFrom and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc) where FlightDepDLKey is null
		--если по городу не нашли ишем по стране
		if exists (select 1 from #Result Where FlightDepDLKey is null)     
		begin
			update #Result set DL_CNKEYFROM = (select top 1 ct_cnkey from citydictionary where ct_key =#Result.DL_CTKEYFROM)
			Update #Result SET FlightDepDLKey=(Select TOP 1 DL_Key From DogovorList,TuristService Where TU_DLKey=DL_Key and DL_DGKey=#Result.DG_Key and DL_CNKey=#Result.DL_CNKeyFrom and TU_TUKey=#Result.TU_Key and DL_DGKey=#Result.DG_Key and dl_svkey=1 order by dl_datebeg desc)	where FlightDepDLKey is null	  
		end
	END
	Update #Result set FligthDepDate = (select dl_dateBeg From DogovorList where DL_Key=#Result.FlightDepDLKey)
	Update #Result set FlightDepNumber = (select CH_AirLineCode + ' ' + CH_Flight From DogovorList, Charter where DL_Code=CH_Key and DL_Key=#Result.FlightDepDLKey)
END

IF @ShowDescription=1
BEGIN
	IF @SVKey=1
		Update #Result SET ServiceDescription=LEFT((SELECT ISNUll(AS_Code, '') + '-' + AS_NameRus FROM AirService WHERE AS_Key=DL_SubCode1),80),
		ServiceDescription_Lat=LEFT((SELECT ISNUll(AS_Code, '') + '-' + AS_NAMELAT FROM AirService WHERE AS_Key=DL_SubCode1),80)
	ELSE IF (@SVKey=2 or @SVKey=4)
		Update #Result SET ServiceDescription=LEFT((SELECT TR_Name FROM Transport WHERE TR_Key=DL_SubCode1),80),
							ServiceDescription_Lat=LEFT((SELECT TR_NAMELAT FROM Transport WHERE TR_Key=DL_SubCode1),80)
	ELSE IF (@SVKey=3 or @SVKey=8)
	BEGIN
		Update #Result SET ServiceDescription=LEFT((SELECT RM_Name + '(' + RC_Name + ')' + AC_Name FROM Rooms,RoomsCategory,AccMdMenType,HotelRooms WHERE HR_Key=DL_SubCode1 and HR_RMKey=RM_Key and HR_RCKey=RC_Key and HR_ACKey=AC_Key),80),
							ServiceDescription_Lat=LEFT((SELECT RM_NAMELAT + '(' + RC_NAMELAT + ')' + AC_NAMELAT FROM Rooms,RoomsCategory,AccMdMenType,HotelRooms WHERE HR_Key=DL_SubCode1 and HR_RMKey=RM_Key and HR_RCKey=RC_Key and HR_ACKey=AC_Key),80)
		IF @SVKey=8
			Update #Result SET ServiceDescription='All accommodations' where DL_SubCode1=0
	END
	ELSE IF (@SVKey=7 or @SVKey=9)
	BEGIN
		Update #Result SET ServiceDescription=LEFT((SELECT ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_Name,'') FROM Cabine WHERE CB_Key=DL_SubCode1),80),
							ServiceDescription=LEFT((SELECT ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_NAMELAT,'') FROM Cabine WHERE CB_Key=DL_SubCode1),80)
		IF @SVKey=9
			Update #Result SET ServiceDescription='All accommodations' where DL_SubCode1=0
	END
	ELSE
		Update #Result SET ServiceDescription=LEFT((SELECT A1_Name FROM AddDescript1 WHERE A1_Key=DL_SubCode1),80), 
							ServiceDescription_Lat=LEFT((SELECT A1_NAMELAT FROM AddDescript1 WHERE A1_Key=DL_SubCode1),80) WHERE ISNULL(DL_SubCode1,0)>0
END

--print @Query
SELECT * FROM #Result

GO
GRANT EXECUTE ON [dbo].[GetServiceList] TO Public
GO
/*********************************************************************/
/* end sp_GetServiceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_RecreateDependentObjects.sql */
/*********************************************************************/
if exists(select top 1 1 from sys.objects where name = 'RecreateDependentObjects' and type = 'P')
	drop procedure RecreateDependentObjects
go

create procedure RecreateDependentObjects
-- выполняет указанный скрипт после удаления и до создания зависимых от колонки @ColumnName объектов
-- сейчас в качестве зависимых объектов поддерживаются только некластеризованные и кластеризованные индексы
--<VERSION>9.2.20</VERSION>
--<DATE>2013-12-05</DATE>
(
	@TableName sysname,				-- имя таблицы, колонка которой удаляется
	@ColumnName sysname,			-- имя удаляемой колонки
	@CustomScript nvarchar(max),	-- скрипт, выполняемый между созданием и удалением зависимых объектов
	@recreateWithoutColumn bit = 0	-- флаг, указывающий, что в зависимые объекты надо пересоздавать без переданной колонки
)
as
begin
	-- ANSI_PADDING OFF setting is incompatible with xml data types, used in this stored procedure
	SET ANSI_PADDING ON;

	declare @errorMessage nvarchar(max)

	-- check arguments
	if not exists (select top 1 1 from sys.tables where name = @TableName)
	begin
		set @errorMessage = 'Table ' + @TableName + ' was not found in database.'
		RAISERROR(@errorMessage, 16, 1)
		return
	end

	if not exists (select top 1 1 from sys.columns where name = @ColumnName)
	begin
		set @errorMessage = 'Column ' + @ColumnName + ' was not found in database.'
		RAISERROR(@errorMessage, 16, 1)
		return
	end

	if not exists (select top 1 1 from sys.columns where name = @ColumnName and object_id = object_id(@TableName))
	begin
		set @errorMessage = 'Incorrect parameters: column ' + @ColumnName + ' doesn''t belong to table ' + @TableName
		RAISERROR(@errorMessage, 16, 1)
		return
	end

	-- признак, что пересоздание ссылающихся на колонку объектов прошло успешно
	declare @updateReferencesComplete as bit
	declare @errmsg as nvarchar(max)

	-- обработка индексов
	declare @ixName sysname
	declare @ixType tinyint

	declare @totalSql as nvarchar(max)
	declare @dropIndexSql as nvarchar(max)
	declare @createIndexSql as nvarchar(max)
	set @dropIndexSql = ''
	set @createIndexSql = ''

	declare indexesCursor cursor for
	select ix.name, ix.type
	from sys.tables tab
	left join sys.indexes ix on ix.object_id = tab.object_id
	where tab.name = @TableName
		and exists (select top 1 1 
					from sys.index_columns ic
					left join sys.columns col on col.column_id = ic.column_id and col.object_id = tab.object_id
					where ic.index_id = ix.index_id 
						and ic.object_id = tab.object_id
						and col.name = @ColumnName
					)

	open indexesCursor

	begin try

	fetch next from indexesCursor into @ixName, @ixType
	while @@FETCH_STATUS = 0
	begin
		if @ixType <> 2 and @ixType <> 1
		begin
			set @errmsg = 'Not supported index type is dependent on specified column ' + @ColumnName + '
			This stored procedure supports only nonclustered and clustered indexes recreation! Not supported index name: ' 
				+ @ixName + ' on table: ' + @TableName
			RAISERROR(@errmsg, 16, 1)
		end

		declare @indexColumns nvarchar(max)
		declare @includedColumns nvarchar(max)

		set @indexColumns = ''
		set @indexColumns = stuff((select ',' + col.name + 
					case
						when ic.is_descending_key = 1 then ' desc'
						else ' asc'
					end
					from sys.tables tab
					left join sys.indexes ix on ix.object_id = tab.object_id
					left join sys.index_columns ic on ic.object_id = tab.object_id and ic.index_id = ix.index_id
					left join sys.columns col on col.column_id = ic.column_id and col.object_id = tab.object_id
					where ic.index_id = ix.index_id 
						and ic.object_id = tab.object_id
						and ic.is_included_column = 0
						and ((@recreateWithoutColumn = 1 and col.name <> @ColumnName) or @recreateWithoutColumn = 0)
						and tab.name = @TableName
						and ix.name = @ixName
					for xml path(''), type
					).value('.', 'varchar(max)'),1,1,'')

		set @includedColumns = stuff((select ',' + col.name
					from sys.tables tab
					left join sys.indexes ix on ix.object_id = tab.object_id
					left join sys.index_columns ic on ic.object_id = tab.object_id and ic.index_id = ix.index_id
					left join sys.columns col on col.column_id = ic.column_id and col.object_id = tab.object_id
					where ic.index_id = ix.index_id 
						and ic.object_id = tab.object_id
						and ic.is_included_column = 1
						and ((@recreateWithoutColumn = 1 and col.name <> @ColumnName) or @recreateWithoutColumn = 0)
						and tab.name = @TableName
						and ix.name = @ixName
					for xml path(''), type
					).value('.', 'varchar(max)'),1,1,'')

		set @dropIndexSql = @dropIndexSql + '
			drop index [@ixName] on [@TableName]'

		if @indexColumns is not null
		begin
			set @createIndexSql = @createIndexSql + 
			'
			create @indexType index [@ixName] on [@TableName]
			(
				@indexColumns
			)'

			if @includedColumns is not null
			begin
				set @createIndexSql = @createIndexSql + 
				'
				include
				(
					@includedColumns
				)
				'
				set @createIndexSql = replace(@createIndexSql, '@includedColumns', isnull(@includedColumns, ''))
			end
			set @createIndexSql = @createIndexSql + 
			'
			WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, 
				ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
			'
			set @createIndexSql = replace(@createIndexSql, '@indexColumns', @indexColumns)
			set @createIndexSql = replace(@createIndexSql, '@indexType', case when @ixType = 2 then 'nonclustered' when @ixType = 1 then 'clustered' end)
		end

		set @createIndexSql = replace(@createIndexSql, '@ixName', @ixName)
		set @createIndexSql = replace(@createIndexSql, '@TableName', @TableName)
		set @dropIndexSql = replace(@dropIndexSql, '@ixName', @ixName)
		set @dropIndexSql = replace(@dropIndexSql, '@TableName', @TableName)

		fetch next from indexesCursor into @ixName, @ixType
	end
	end try
	begin catch 
		set @errmsg = error_message()
		set @updateReferencesComplete = 0
	end catch

	close indexesCursor
	deallocate indexesCursor

	if @updateReferencesComplete = 0
	begin
		RAISERROR(@errmsg, 16, 1)
		return
	end

	-- execute custom script between drop and recreate dependent objects
	set @totalSql = '
	begin transaction dropAndCreate
	' + @dropIndexSql + '
	' + @customScript + '
	' + @createIndexSql + '
	commit transaction dropAndCreate
	'

	exec sp_executesql @totalSql
end

GO

grant exec on RecreateDependentObjects to public

GO
/*********************************************************************/
/* end sp_RecreateDependentObjects.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetKey_Rights.sql */
/*********************************************************************/
--<VERSION>9.2.20.3</VERSION>
--<DATE>2013-12-05</DATE>
--<DESCRIPTION>РЎРєСЂРёРїС‚ СЂР°Р·РґР°РµС‚ РїСЂР°РІР° РЅР° РІСЃРµ Key_ С‚Р°Р±Р»РёС†С‹</DESCRIPTION>
declare @queryTemplate nvarchar (100)
declare @query nvarchar (100)
declare @tableName nvarchar(50)

set @queryTemplate = 'grant select, delete, update, insert on @tableName to public'

declare cur1 cursor for 
	select name from sys.tables
	where name like'Key_%'
open cur1

FETCH NEXT FROM cur1 into @tableName
while @@FETCH_STATUS=0
begin
	set @query = replace(@queryTemplate, '@tableName', @tableName)
	execute sp_executesql @query
	FETCH NEXT FROM cur1 into @tableName
end
CLOSE cur1
DEALLOCATE cur1
go

/*********************************************************************/
/* end sp_SetKey_Rights.sql */
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

	declare tabsCur cursor for
	select art.source_object
	from mt.distribution.dbo.MSArticles art
	inner join sys.tables localTabs on localTabs.name = art.source_object
	where
			(art.publication_id = (select top 1 publication_id 
 				from mt.distribution.dbo.MSpublications 
				where publication = ''MW_PUB''))
			and (art.source_object not in (select tableName from @excludedTables)) 			
	order by art.source_object

	open tabsCur

	declare @sql varchar(4000)
	set @sql = ''''

	fetch next from tabsCur into @tabName
	while @@fetch_status = 0
	begin

		set @sql = @sql + ''
			alter table @tabName disable trigger all
		''
		set @sql = replace(@sql, ''@tabName'', @tabName)
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
update [dbo].[setting] set st_version = '9.2.20.3', st_moduledate = convert(datetime, '2013-12-06', 120),  st_financeversion = '9.2.20.3', st_financedate = convert(datetime, '2013-12-06', 120) 
 GO
 UPDATE dbo.SystemSettings SET SS_ParmValue='2013-12-06' WHERE SS_ParmName='SYSScriptDate'
 GO