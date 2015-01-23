/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 03.10.2014 11:02 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.21'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.22'

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

	If @nUpdate=0
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_TourDate, TF_CalculatingKey)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey,
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days, TD_Date, @nCalculatingKey
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock), TP_Lists with(nolock), TP_ServiceLists with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TI_TOKey = TO_Key and TL_TOKey = TO_Key and TL_TSKey = TS_Key and TL_TIKey = TI_Key and TO_Key = @nPriceTourKey
	Else
	BEGIN
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_TourDate, TF_CalculatingKey)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey,
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days, TD_Date, @nCalculatingKey
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock), TP_Lists with(nolock), TP_ServiceLists with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TI_TOKey = TO_Key and TL_TOKey = TO_Key and TL_TSKey = TS_Key and TL_TIKey = TI_Key and TO_Key = @nPriceTourKey
			and not exists (Select TF_ID From TP_Flights with(nolock) Where TF_TOKey=TO_Key and TF_Date=(TD_Date + TS_Day - 1) 
						and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
						and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = TI_Days and TF_CodeNew is not null)	
	END
	
	print 'Подбор перелетов 1: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре (с учетом цен в которых дата продажи NULL или больше/равна сегодняшней дате )----
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey 
			and TF_Date BETWEEN CS_Date AND  CS_DateEnd and (ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long) and (cs_DateSellBeg <= @dtSaleDate or cs_DateSellBeg is null) 
			and (cs_DateSellEnd >= @dtSaleDate or cs_DateSellEnd is null))
			and TF_TOKey = @nPriceTourKey
	
	print 'Подбор перелетов 2: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()

	If @nNoFlight = 2
	BEGIN
		------ проверяем, а есть ли у данного парнера по рейсу, цены на другие рейсы в этом же пакете ----		
		
		IF exists(SELECT TF_ID FROM TP_Flights with(nolock) WHERE TF_TOKey = @nPriceTourKey and TF_CodeNew is Null) 
		begin
			print 'Подбираем перелет'
			
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
			-- подбираем подходящие нам перелеты (с учетом цен в которых дата продажи NULL или больше/равна сегодняшней дате )
			insert into @newFlightsPartnerTable (xTFId, xCHKey, xASKey, xPRKey, xPRKeyNew)
			SELECT TF_Id, CH_Key, CS_SubCode1, TF_PRKeyOld, CS_PRKey
			FROM AirSeason with(nolock), Charter with(nolock), Costs with(nolock), TP_Flights with(nolock)
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
			TF_CodeNew is Null and 
			TF_TOKey = @nPriceTourKey
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
			update TP_Flights with(rowlock)
			set TF_CodeNew = xCHKey,
			TF_SubCode1New = xASKey,
			TF_PRKeyNew = xPRKeyNew,
			TF_CalculatingKey = @nCalculatingKey
			from TP_Flights with(rowlock) join @newFlightsPartnerTable on TF_Id = xTFId
			
			print 'Закончили подбор перелетов'		
		end
		
		print 'Подбор перелетов 3: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()	
	END

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
			select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, CEILING(xTP_Gross), xTP_TIKey, xTP_CalculatingKey 
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
								FROM [dbo].[TBL_TURIST] WITH(NOLOCK)
								WHERE TU_KEY <> @TU_Key AND TU_DGCOD = @NTU_DGCOD AND TU_ISMAIN = 1
							IF @HaveMainMan IS NULL
								BEGIN
									SELECT @NewMainTourist = TU_KEY 
									FROM [dbo].[TBL_TURIST] WITH(NOLOCK)
									WHERE TU_KEY <> @TU_Key AND TU_SEX < 2 AND TU_DGCOD = @NTU_DGCOD;
									IF(@NewMainTourist IS NULL)
										BEGIN
											SELECT @NewMainTourist = TU_KEY 
											FROM [dbo].[TBL_TURIST] WITH(NOLOCK)
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
							FROM [dbo].[TBL_TURIST] WITH(NOLOCK)
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
			  FROM [dbo].[TBL_TURIST] WITH(NOLOCK)
			 WHERE TU_KEY <> @TU_Key AND TU_DGCOD = @OTU_DGCOD AND TU_ISMAIN = 1;
		
			IF @MainTouristExists IS NULL
				BEGIN
					SELECT @NewMainTourist = TU_KEY 
					  FROM [dbo].[TBL_TURIST] WITH(NOLOCK)
					 WHERE TU_KEY <> @TU_Key AND TU_SEX < 2 AND TU_DGCOD = @OTU_DGCOD;
					IF(@NewMainTourist IS NULL)
					BEGIN
						SELECT @NewMainTourist = TU_KEY 
						  FROM [dbo].[TBL_TURIST] WITH(NOLOCK)
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
			  FROM [dbo].[TBL_TURIST] WITH(NOLOCK)
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
-- =====================   Обновление версии БД. 9.2.20.22 - номер версии, 2014-10-03 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.22', st_moduledate = convert(datetime, '2014-10-03', 120),  st_financeversion = '9.2.20.22', st_financedate = convert(datetime, '2014-10-03', 120)
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
	SET SS_ParmValue='2014-10-03' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO