set nocount on
-- T_DUP_USER_INSERT.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_DUP_USER_INSERT]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_DUP_USER_INSERT]
GO

CREATE TRIGGER [T_DUP_USER_INSERT]
	ON [dbo].[DUP_USER]
FOR INSERT
AS
BEGIN
	update dbo.DUP_USER set us_companyname = 
		(select PR_Name from dbo.tbl_Partners with(nolock) where PR_Key = US_PRKey)
	where us_companyname is null
END
GO

-- fn_mwGetServiceClassesNamesExtended.sql
if exists(select id from sysobjects where xtype='fn' and name='mwGetServiceClassesNamesExtended')
	drop function dbo.mwGetServiceClassesNamesExtended
go

create function [dbo].[mwGetServiceClassesNamesExtended](@tiKey INTEGER, @servicesDelimeter VARCHAR(5), @detailsDelimeter VARCHAR(5))
returns varchar(8000)
as
begin
	declare @Result varchar(8000),
			@TourDate datetime

	set @Result = ''
	--MEG00026439 Paul G 11.03.2010 Дата начала тура
	select @TourDate = to_datebegin 
	from tp_lists 
		inner join tp_tours on ti_tokey=to_key 
	where ti_key=@tiKey

	select @Result = @Result + 
		case when CHARINDEX (@servicesDelimeter + ltrim(rtrim(sv_name)), @Result) = 0
			 then @servicesDelimeter + ltrim(rtrim(sv_name)) + ' : ' + sv_detail
			 else case when sv_key=3 then '' else @detailsDelimeter + sv_detail end
		end
	from (select distinct
			sv_name, 
			sv_key, 
			case when sv_key=1 then isnull(ch_airlinecode, '') + isnull(ch_flight, '') + ' ' + isnull(ch_portcodefrom, '') + '(' + isnull(cityfrom.ct_name, '') + ')'
					--MEG00026439 Paul G 11.03.2010 Вывожу расписание рейсов
					--MEG00028245 Danil 06.07.2010 Не показывать время вылета
					--+ IsNull((select top 1 IsNull(' ' + left(convert(varchar(8), as_timefrom, 108),5) + ' ','') from airseason where as_chkey=ch_key and dateadd(day, ts_day, @TourDate) between as_datefrom and as_dateto),'') 
					+ '-' + isnull(ch_portcodeto, '') + '(' + isnull(cityto.ct_name, '') + ')'
					--MEG00026439 Paul G 11.03.2010 Вывожу расписание рейсов
					--MEG00028245 Danil 06.07.2010 Не показывать время вылета
					--+ IsNull((select top 1 IsNull(' ' + left(convert(varchar(8), as_timeto, 108),5) + ' ','') from airseason where as_chkey=ch_key and dateadd(day, ts_day, @TourDate) between as_datefrom and as_dateto),'') 
				when sv_key=2 then isnull(tf_name, '')
				when sv_key=3 then 'Отель(питание по программе)'
				when sv_key=4 then ed_name
				when sv_key>4 then IsNull(sl_name,'')
			end sv_detail,
			ts_day
		from tp_services with(nolock)
			inner join tp_servicelists with(nolock) on tl_tskey = ts_key
			inner join service with(nolock) on sv_key = ts_svkey
			left join charter with(nolock) on ch_key=ts_code and sv_key=1
			left join citydictionary cityfrom with(nolock) on cityfrom.ct_key=ch_citykeyfrom and sv_key=1
			left join citydictionary cityto with(nolock) on cityto.ct_key=ch_citykeyto and sv_key=1
			left join transfer with(nolock) on tf_key=ts_code and sv_key=2
			left join excurdictionary with(nolock) on ed_key=ts_code and sv_key=4
			left join servicelist with(nolock) on sl_key=ts_code and sv_key>4
		where tl_tikey = @tiKey and ((ts_attribute & 32832) = 0)) tbl
	order by sv_key,ts_day

	set @Result = isnull(@Result, '')
	if len(@Result) > 0
		return substring(@Result, len(@servicesDelimeter) + 1, len(@Result) - len(@servicesDelimeter))

	return ''
end

go

grant exec on [dbo].[mwGetServiceClassesNamesExtended] to public

go


-- 100709 insert systemsettings.sql
IF(NOT EXISTS(SELECT 1 FROM [dbo].[SystemSettings] WHERE SS_ParmName Like 'SYSRemovalOfPaidServices'))
	INSERT INTO [dbo].[SystemSettings] (SS_ParmName, SS_ParmValue)
	VALUES('SYSRemovalOfPaidServices',0)
GO


-- 100709 insert objectAliases.sql
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 30))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(30, 'Mappings', 'Соответствие объектов в импорте прайс-листов', 74)
GO
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 30001))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(30001, 'MP_INTKEY', 'Значение ключевого поля таблицы из поля TableID, если оно числовое', 74)
GO
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 30002))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(30002, 'MP_CHARKEY', 'Значение ключевого поля таблицы из поля TableID, если оно текстовое', 74)
GO
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 30003))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(30003, 'MP_VALUE', 'Текстовое значение в импортируемом прайс-листе (HASH-код)', 74)
GO
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 30004))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(30004, 'MP_PRKEY', 'Партнер (ссылка на таблицу Partners)', 74)
GO
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 30005))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(30005, 'MP_STRVALUE', 'Текстовое значение в импортируемом прайс-листе', 74)
GO

-- 100715 insert actions.sql
IF(NOT EXISTS(SELECT 1 FROM [dbo].[Actions] WHERE AC_KEY = 69))
INSERT INTO [dbo].[Actions] (AC_KEY, AC_Name, AC_NameLat)
VALUES(69,'Партнёры->Разрешить печать','Patners->Allow print')
GO
INSERT INTO [dbo].[ActionsAuth]
SELECT 69 AS ACA_ACKEY,US_KEY AS ACA_USKEY FROM [dbo].[UserList]
GO

-- sp_CalculatePriceList.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CalculatePriceList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CalculatePriceList]
GO
 
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO
SET ANSI_WARNINGS OFF
GO

CREATE PROCEDURE [dbo].[CalculatePriceList]
  (
	@nPriceTourKey int,			-- ключ обсчитываемого тура
	@dtSaleDate datetime,		-- дата продажи
	@nNullCostAsZero smallint,	-- считать отсутствующие цены нулевыми (кроме проживания) 0 - нет, 1 - да
	@nNoFlight smallint,		-- при отсутствии перелёта в расписании 0 - ничего не делать, 1 - не обсчитывать тур, 2 - искать подходящий перелёт (если не найдено - не рассчитывать)
	@nUpdate smallint,			-- признак дозаписи 0 - расчет, 1 - дозапись
	@nPriceList2006 smallint,    -- Копирование цен в таблицы PriceList
	@nPLNotDeleted smallint,		-- PriceList: 0 - удалять дублирующиеся цены, 1 - не удалять
	@nUseHolidayRule smallint		-- Правило выходного дня: 0 - не использовать, 1 - использовать
  )
AS
--<DATE>2008-05-20</DATE>
---<VERSION>5.2.38.3</VERSION>
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
declare @NumPrices int, @NumCalculated int
--
declare @fetchStatus smallint
--declare @nCount int
declare @nDeltaProgress money
declare @nTotalProgress money
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
declare @sUseServicePrices varchar(1)

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

create index x_getservicecost on #GetServiceCost(svkey, code, subcode1, subcode2, prkey, pkkey, date, days)


declare @calculatingPriceListsExists smallint -- 0 - CalculatingPriceLists нет, 1 - CalculatingPriceLists есть в базе

BEGIN
	set nocount on

	--koshelev
	--MEG00027550
	if @nUpdate = 0
		update tp_tours with(rowlock) set to_datecreated = GetDate() where to_key = @nPriceTourKey

	select @TrKey = to_trkey, @userKey = to_opkey from tp_tours with(nolock) where to_key = @nPriceTourKey

	delete from CalculatingPriceLists with(rowlock) where CP_PriceTourKey not in (select to_key from tp_tours with(nolock))

	if not exists (select 1 from CalculatingPriceLists with(nolock) where CP_PriceTourKey = @nPriceTourKey)
	begin	
		insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_PriceList2006, CP_PLNotDeleted, CP_TourKey, CP_UserKey, CP_Status, CP_UseHolidayRule)
		values (@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @nPriceList2006, @nPLNotDeleted, @TrKey, @userKey, 1, @nUseHolidayRule)
	end
	else
	begin
		update CalculatingPriceLists with(rowlock) set CP_Status = 1 where CP_PriceTourKey = @nPriceTourKey
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
	If @nPriceList2006 = 0
		SET @sHI_Text = 'NO'
	ELSE
		SET @sHI_Text = 'YES'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11006, null, @sHI_Text, null, @nUpdate, null, null, 0
	If @nPLNotDeleted = 0
		SET @sHI_Text = 'NO'
	ELSE
		SET @sHI_Text = 'YES'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11007, null, @sHI_Text, null, @nUpdate, null, null, 0
	If @nUseHolidayRule = 0
		SET @sHI_Text = 'NO'
	ELSE
		SET @sHI_Text = 'YES'
	EXECUTE dbo.InsertHistoryDetail @nHIID , 11008, null, @sHI_Text, null, @nUpdate, null, null, 0


	Set @nTotalProgress=1
	update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	select @nDateFirst = @@DATEFIRST
	set DATEFIRST 1
	set @SERV_NOTCALCULATE = 32768

	--Настройка (использовать связку обсчитанных цен с текущими ценами, пока не реализована)
	select @sUseServicePrices = SS_ParmValue from systemsettings with(nolock) where SS_ParmName = 'UseServicePrices'

	If @nUpdate=0
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey, 
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TO_Key = @nPriceTourKey
	Else
	BEGIN
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey, 
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TO_Key = @nPriceTourKey
			and not exists (Select TF_ID From TP_Flights with(nolock) Where TF_TOKey=TO_Key and TF_Date=(TD_Date + TS_Day - 1) 
						and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
						and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2)		
	END

--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey and TF_Date BETWEEN CS_Date AND  CS_DateEnd)
			and TF_TOKey = @nPriceTourKey

	If @nNoFlight = 2
	BEGIN
		------ проверяем, а есть ли у данного парнера по рейсу, цены на другие рейсы в этом же пакете ----
		IF exists(SELECT TF_ID FROM TP_Flights with(nolock) WHERE TF_TOKey = @nPriceTourKey and TF_CodeNew is Null) 
		begin
			Update	TP_Flights with(rowlock) Set 	TF_CodeNew = (	SELECT top 1 CH_Key
							FROM AirSeason with(nolock), Charter with(nolock), Costs with(nolock)
							WHERE CH_CityKeyFrom = TF_Subcode2 AND
								CH_CityKeyTo = TF_CTKey AND
								CS_Code = CH_Key AND
								AS_CHKey = CH_Key AND
								CS_SVKey = 1 AND
								CS_SubCode1 = TF_Subcode1 AND
								CS_PRKey = TF_PRKeyOld AND
								CS_PKKey = TF_PKKey AND
								TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND
								TF_Date BETWEEN CS_Date AND  CS_DateEnd AND
								AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%'
								),
					TF_PRKeyNew = TF_PRKeyOld
			Where	TF_CodeNew is Null 
					and TF_TOKey = @nPriceTourKey

		end
		------ проверяем, а есть ли у кого-нибудь цены на любой рейс в этом же пакете ----
		IF exists(SELECT TF_ID FROM TP_Flights with(nolock) WHERE TF_TOKey = @nPriceTourKey and TF_CodeNew is Null) 
		begin
			Update	TP_Flights with(rowlock) Set 	TF_CodeNew = (	SELECT top 1 CH_Key
								FROM AirSeason with(nolock), Charter with(nolock), Costs with(nolock)
								WHERE CH_CityKeyFrom = TF_Subcode2 AND
									CH_CityKeyTo = TF_CTKey AND
									CS_Code = CH_Key AND
									AS_CHKey = CH_Key AND
									CS_SVKey = 1 AND
									CS_SubCode1 = TF_Subcode1 AND
									CS_PKKey = TF_PKKey AND
									TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND
									TF_Date BETWEEN CS_Date AND  CS_DateEnd AND
									AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%'
									),
								TF_PRKeyNew = (	SELECT top 1 CS_PRKEY
								FROM AirSeason with(nolock), Charter with(nolock), Costs with(nolock)
								WHERE CH_CityKeyFrom = TF_Subcode2 AND
									CH_CityKeyTo = TF_CTKey AND
									CS_Code = CH_Key AND
									AS_CHKey = CH_Key AND
									CS_SVKey = 1 AND
									CS_SubCode1 = TF_Subcode1 AND
									CS_PKKey = TF_PKKey AND
									TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND
									TF_Date BETWEEN CS_Date AND  CS_DateEnd AND
									AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%'
									)			
			Where	TF_CodeNew is Null 
					and TF_TOKey = @nPriceTourKey

		end
	END
	-----если перелет так и не найден, то в поле TF_CodeNew будет NULL

	--------------------------------------- закончили поиск подходящего перелета --------------------------------------

	if ISNULL((select to_update from [dbo].tp_tours with(nolock) where to_key = @nPriceTourKey),0) <> 1
	BEGIN

		update [dbo].tp_tours with(rowlock) set to_update = 1 where to_key = @nPriceTourKey
		Set @nTotalProgress=4
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	
		--------------------------------------- сохраняем цены во временной таблице --------------------------------------
		CREATE TABLE #TP_Prices
		(
			[xTP_Key] [int] PRIMARY KEY NOT NULL ,
			[xTP_TOKey] [int] NOT NULL ,
			[xTP_DateBegin] [datetime] NOT NULL ,
			[xTP_DateEnd] [datetime] NULL ,
			[xTP_Gross] [money] NULL ,
			[xTP_TIKey] [int] NOT NULL 
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
			exec GetNKeys 'TP_PRICES', @numDates, @nTP_PriceKeyMax output
			set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @numDates + 1
		
			declare datesCursor cursor local fast_forward for
			select TD_Date, TI_Key, TP_Gross from TP_TurDates with(nolock), TP_Lists with(nolock), TP_Prices with(nolock) where TP_TIKey = TI_Key and TD_Date between TP_DateBegin and TP_DateEnd and TP_TOKey = @nPriceTourKey and TD_TOKey = @nPriceTourKey and TI_TOKey = @nPriceTourKey
			
			open datesCursor
			fetch next from datesCursor into @priceDate, @priceListKey, @priceListGross
			while @@FETCH_STATUS = 0
			begin
				insert into #TP_Prices (xTP_Key, xTP_TOKey, xTP_TIKey, xTP_Gross, xTP_DateBegin, xTP_DateEnd) 
				values (@nTP_PriceKeyCurrent, @nPriceTourKey, @priceListKey, @priceListGross, @priceDate, @priceDate)
				set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
				fetch next from datesCursor into @priceDate, @priceListKey, @priceListGross
			end
			
			close datesCursor
			deallocate datesCursor
			
			begin tran tEnd
				delete from TP_Prices with(rowlock) where TP_TOKey = @nPriceTourKey
				
				insert into TP_Prices (TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd)
				select xTP_Key, xTP_TOKey, xTP_TIKey, xTP_Gross, xTP_DateBegin, xTP_DateEnd from #TP_Prices  
				where xTP_DateBegin = xTP_DateEnd
				
				delete from #TP_Prices
			commit tran tEnd
		end
		--------------------------------------------------------------------------------------
		
		select @TrKey = to_trkey, @nPriceFor = to_pricefor from tp_tours with(nolock) where to_key = @nPriceTourKey

		--смотрим сколько записей по текущему прайсу уже посчитано	
		Set @NumCalculated = (SELECT COUNT(1) FROM tp_prices with(nolock) where tp_tokey = @nPriceTourKey)
		--считаем сколько записей надо посчитать
		set @NumPrices = ((select count(1) from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) * (select count(1) from tp_turdates with(nolock) where td_tokey = @nPriceTourKey and td_update = @nUpdate))

		if (@NumCalculated + @NumPrices) = 0
			set @NumPrices = 1

		Set @nTotalProgress=@nTotalProgress + (CAST(@NumCalculated as money)/CAST((@NumCalculated+@NumPrices) as money) * (90-@nTotalProgress))
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
		declare serviceCursor cursor local fast_forward for
			select ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, to_rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_days, ts_ctkey, ts_attribute
			from tp_tours with(nolock), tp_services with(nolock), tp_lists with(nolock), tp_servicelists with(nolock), tp_turdates with(nolock)
			where to_key = @nPriceTourKey and to_key = ts_tokey and to_key = ti_tokey and to_key = tl_tokey and ts_key = tl_tskey and ti_key = tl_tikey and to_key = td_tokey
				and ti_update = @nUpdate and td_update = @nUpdate and (@nUseHolidayRule = 0 or (case cast(datepart(weekday, td_date) as int) when 7 then 0 else cast(datepart(weekday, td_date) as int) end + ti_days) >= 8)
			order by ti_firsthdkey, td_date, ti_key

		open serviceCursor
		SELECT @round = ST_RoundService FROM Setting
		set @nProgressSkipLimit = 50

		set @nProgressSkipCounter = 0
		Set @nTotalProgress = @nTotalProgress + 1
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey

		if @NumPrices <> 0
			set @nDeltaProgress = (95.0-@nTotalProgress) / @NumPrices
		else
			set @nDeltaProgress = 95.0-@nTotalProgress

		exec GetNKeys 'TP_PRICES', @NumPrices, @nTP_PriceKeyMax output
		set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @NumPrices + 1
		set @dtPrevDate = '1899-12-31'
		set @nPrevVariant = -1
		set @nPrevGross = -1
		set @nPrevGrossDate = '1899-12-31'
		set @prevHdKey = -1

		delete from #TP_Prices

		insert into #TP_Prices (xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey) 
		select tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey 
		from tp_prices with(nolock)
		where tp_tokey = @nPriceTourKey and 
			tp_tikey in (select ti_key from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) and
			tp_datebegin in (select td_date from tp_turdates with(nolock) where td_tokey = @nPriceTourKey and td_update = @nUpdate)

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

							update #TP_Prices set xtp_gross = @price_brutto where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
							
							if @sUseServicePrices = '1'
								delete from TP_PriceDetails with(rowlock) where PD_TPKey = @nTP_PriceKeyCurrent

						end
						else
						begin

							insert into #TP_Prices (xtp_key, xtp_tokey, xtp_datebegin, xtp_dateend, xtp_gross, xtp_tikey) 
							values (@nTP_PriceKeyCurrent, @nPriceTourKey, @dtPrevDate, @dtPrevDate, @price_brutto, @nPrevVariant)
							
							if @sUseServicePrices = '1'
								delete from TP_PriceDetails with(rowlock) where PD_TPKey = @nTP_PriceKeyCurrent
							
							set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent +1
							if @nTP_PriceKeyCurrent > @nTP_PriceKeyMax and @@fetch_status = 0
							BEGIN
								exec GetNKeys 'TP_PRICES', @NumPrices, @nTP_PriceKeyMax output
								set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @NumPrices + 1
							END

						end
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

					if @nSvkey = 1
					BEGIN
						SELECT 	@nCode = TF_CodeNew,
								@nPrkey = TF_PRKeyNew
						FROM	TP_Flights with(nolock)
						WHERE	TF_TOKey = @nPriceTourKey AND
								TF_CodeOld = @nCode AND
								TF_PRKeyOld = @nPrkey AND
								TF_Date = @servicedate
					END	
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
							exec GetServiceCost @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @servicedate, @nDays, @sRate, @nMen, 0, @nMargin, @nMarginType, @dtSaleDate, @nNetto output, @nBrutto output, @nDiscount output, @sDetailed output, @sBadRate output, @dtBadDate output, @sDetailed output, @nSPId output

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
					if @nMen > 1 and @nPriceFor = 0
						set @nBrutto = @nBrutto / @nMen

					if @nSPId is not null and @sUseServicePrices = '1'
					BEGIN				
						insert into TP_PriceDetails (PD_SPID, PD_TPKey, PD_Margin, PD_MarginType) values (@nSPId, @nTP_PriceKeyCurrent, @nMargin, @nMarginType)
						Set @nPDID = SCOPE_IDENTITY()
					END		
		
				END

			if @nBrutto is not null and (@round = @ROUND_SERVICE or @round = @ROUND_SERVICE0_5 or @round = @ROUND_SERVICE_MATH)
				exec RoundPriceList @round, @nBrutto output

			set @price_brutto = @price_brutto + @nBrutto
			---------------------------------------------------------------------------------

			fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_DAYS, @TS_CTKEY, @TS_ATTRIBUTE
		END
		close serviceCursor
		deallocate serviceCursor

		----------------------------------------------------- возвращаем обратно цены ------------------------------------------------------

		Set @nTotalProgress = 97
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey

		declare @nRowPart int
		set @nRowPart = 200
		declare @TPkeyMax int
		declare @TPkeyMin int

		
		select 	@TPkeyMax = MAX(xtp_key), 
				@TPkeyMin = MIN(xtp_key) 
		from 	#TP_Prices

		delete from tp_prices with(rowlock)
		where tp_tokey = @nPriceTourKey and 
			tp_tikey in (select ti_key from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) and
			tp_DateBegin in (select td_date from TP_TurDates with(nolock) where td_tokey = @nPriceTourKey and TD_Update = @nUpdate)

		while 	@TPkeyMin <= @TPkeyMax
		BEGIN
			begin tran tEnd
			INSERT INTO TP_Prices with(rowlock) (tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey) 
				select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey 
				from #TP_Prices 
				where xtp_key between @TPkeyMin and @TPkeyMin + @nRowPart
			commit tran tEnd
			Set @TPkeyMin = @TPkeyMin + @nRowPart + 1
		END

		-----------------------------------------------------КОНЕЦ возвращаем обратно цены ------------------------------------------------------

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
	--Заполнение полей в таблице tp_lists
	declare @toKey int, @add int
	set @toKey = @nPriceTourKey
	set @add = @nUpdate

	create table #tmpPrices(
		tpkey int,
		tikey int
	)

	if(@add > 0)
	begin
		insert into #tmpPrices 
			select tp_key, tp_tikey 
			from tp_prices
			where tp_tokey = @toKey and tp_dateend >= getdate()  
					 and not exists 
					(select 1 from mwPriceDataTable with(nolock)
					where pt_tourkey = @toKey)
	end
	
	update tp_lists with(rowlock)
		set ti_hotelkeys = dbo.mwGetTiHotelKeys(ti_key),
			ti_hotelroomkeys = dbo.mwGetTiHotelRoomKeys(ti_key),
			ti_hoteldays = dbo.mwGetTiHotelNights(ti_key),
			ti_hotelstars = dbo.mwGetTiHotelStars(ti_key),
			ti_pansionkeys = dbo.mwGetTiPansionKeys(ti_key)
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))
	
	update tp_lists with(rowlock)
	set
		ti_hdpartnerkey = ts_oppartnerkey,
		ti_firsthotelpartnerkey = ts_oppartnerkey,
		ti_hdday = ts_day,
		ti_hdnights = ts_days
	from tp_servicelists with (nolock)
		inner join tp_services with (nolock) on (tl_tskey = ts_key and ts_svkey = 3)
	where tl_tikey = ti_key and ts_code = ti_firsthdkey and ti_tokey = @toKey and tl_tokey = @toKey
		and ts_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	------------------------------------

	------------------------------------------------------------------------
	if @nPriceList2006 is not null and @nPriceList2006 <> 0
	BEGIN
		-- -- -- -- -- запись в PriceList
		-- insert into History (Hi_date, Hi_text, Hi_SVKey) values (GetDate(), 'Начало расчета', @nPriceTourKey)
		delete from dbo.pricelist with(rowlock) where pl_trkey=@TrKey
		DECLARE @TP_Lists TABLE (
            [xTI_Key] [int] PRIMARY KEY NOT NULL ,
            [xTI_FirstHdKey] [int] NOT NULL ,
            [xTI_FirstHrKey] [int] NOT NULL ,
            [xTI_FirstPnKey] [int] NOT NULL ,  
            [xTI_Days] [int] NOT NULL ,  
            [xTI_PNCode] varchar(3) NULL , 
            [xTI_ACMain] [int] , 
            [xTI_ACNRealPlaces] [int] , 
            [xTI_ACNMenExBed] [int] , 
            [xTI_ACAgeFrom] [int] , 
            [xTI_ACName] varchar(30) , 
            [xTI_RCKey] [int] NOT NULL , 
            [xTI_RMKey] [int] NOT NULL , 
            [xTI_RCName] varchar(60) , 
            [xTI_RMName] varchar(60) , 
            [xTI_HDStars] varchar(12) , 
            [xTI_HDName] varchar(60) , 
            [xTI_HDHTTP] varchar(128) , 
            [xTI_HDCNKey] [int], 
            [xTI_HDCTKey] [int], 
            [xTI_HDRSKey] [int], 
            [xTI_RSName] varchar(50),
            [xTI_CTName] varchar(50),
            
            [xti_su1] varchar(824),
            [xti_su2] varchar(824),
            [xti_CityArr] [int],
            [xti_sh1] varchar(824),
            [xti_st1] varchar(824),
            [xti_st2] varchar(824),
            [xti_ss1] varchar(824),
            [xti_sv1] varchar(824),
            [xti_sd1] varchar(824),
            [xti_u] varchar(824)
      )
      DELETE FROM @TP_Lists
      INSERT INTO @TP_Lists (xTI_Key, xTI_FirstHdKey, xTI_FirstHrKey, xTI_FirstPnKey, xTI_Days, 
                        xTI_ACMain, xTI_ACNRealPlaces, xTI_ACNMenExBed, xTI_ACAgeFrom, xTI_ACName,
                        xTI_RCKey, xTI_RMKey,
                        xTI_HDStars, xTI_HDName, xTI_HDCNKey, xTI_HDCTKey, xTI_HDRSKey, xTI_HDHTTP
                        ) 
            select      TI_Key, TI_FirstHdKey, TI_FirstHrKey, TI_FirstPnKey, TI_Days, 
                        AC_Main, AC_NRealPlaces, AC_NMenExBed, AC_AgeFrom, AC_Name, 
                        HR_RCKey, HR_RMKey,
                        HD_Stars, HD_Name, HD_CNKey, HD_CTKey, HD_RSKey, HD_HTTP
            from  dbo.TP_Lists with(nolock), 
                        dbo.HotelRooms with(nolock),
                        dbo.AccmdMenType with(nolock),
                        dbo.HotelDictionary with(nolock)
            where TI_TOKey = @nPriceTourKey
                        and HR_Key = TI_FirstHrKey
                        and AC_Key = HR_ACKey
                        and HD_Key = TI_FirstHdKey
 
            update @TP_Lists Set xTI_RSName = (Select RS_Name From dbo.Resorts with(nolock) Where RS_Key = xTI_HDRSKey)
            update @TP_Lists Set xTI_PNCode = (Select PN_Code From dbo.Pansion with(nolock) Where PN_Key = xTI_FirstPnKey)
            update @TP_Lists Set xTI_RCName = (Select RC_Name From dbo.RoomsCategory with(nolock) Where RC_Key = xTI_RCKey)
            update @TP_Lists Set xTI_RMName = (Select RM_Name From dbo.Rooms with(nolock) Where RM_Key = xTI_RMKey)
            update @TP_Lists Set xTI_CTName = (Select CT_Name From dbo.CityDictionary with(nolock) Where CT_Key = xTI_HDCTKey)
 
            update @TP_Lists Set xti_su2 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists with(nolock), dbo.TP_Services with(nolock) Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 1 and TS_Day != 1)

/*
					xti_chbackkey = TS_Code,
					xti_chbackday = TS_Day,
					xti_chbackpkkey = TS_OpPacketKey,
					xti_chbackprkey = TS_OpPartnerKey
*/
 
            update @TP_Lists Set xti_su1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists with(nolock), dbo.TP_Services with(nolock) Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 1 and TS_Day = 1)

/*
					xti_chkey = TS_Code,
					xti_chday = TS_Day,
					xti_ctkeyto = TS_CtKey,
					xti_chpkkey = TS_OpPacketKey,
					xti_chprkey = TS_OpPartnerKey
*/
 
            update @TP_Lists Set xti_CityArr = (
                  Select TOP 1 TS_SubCode2
                  From dbo.TP_ServiceLists with(nolock), dbo.TP_Services with(nolock) Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 1 and TS_Day = 1)
 
            update @TP_Lists Set xti_sh1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_Days)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists with(nolock), dbo.TP_Services with(nolock) Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 3)
 
            update @TP_Lists Set xti_st2 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists with(nolock), dbo.TP_Services with(nolock) Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 2 and TS_Day != 1)
 
            update @TP_Lists Set xti_st1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists with(nolock), dbo.TP_Services with(nolock) Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 2 and TS_Day = 1)
 
            update @TP_Lists Set xti_ss1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_Days)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists with(nolock), dbo.TP_Services with(nolock) Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 6)
 
            update @TP_Lists Set xti_sv1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_Days)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists with(nolock), dbo.TP_Services with(nolock) Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 5)
 
            update @TP_Lists Set xti_sd1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_Days)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists with(nolock), dbo.TP_Services with(nolock) Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 8)
 
            update @TP_Lists Set xti_u = 'MID=' + LTRIM(STR(@TrKey)) + '&' + 'DAY=' + LTRIM(STR(xTI_Days)) + '&' + 'H=1&H1=' + xti_sh1 + '&'
            update @TP_Lists Set xti_u = xti_u + 'U=2&' + 'U1=' + xti_su1 + '&' + 'U2=' + xti_su2 + '&'
                  where xti_su2 != '' and xti_su2 is not null
            update @TP_Lists Set xti_u = xti_u + 'U=1&' + 'U1=' + xti_su1 + '&'
                  where (xti_su2 = '' or xti_su2 is null) and xti_su1 != '' and xti_su1 is not null 
            update @TP_Lists Set xti_u = xti_u + 'T=2&' + 'T1=' + xti_st1 +  '&' + 'T2=' + xti_st2 +  '&'
                  where xti_st2 != '' and xti_st2 is not null
            update @TP_Lists Set xti_u = xti_u + 'T=1&' + 'T1=' + xti_st1 + '&'
                  where (xti_st2 = '' or xti_st2 is null) and xti_st1 != '' and xti_st1 is not null 
 
            update @TP_Lists Set xti_u = 'S=1&' + xti_u + 'S1=' + xti_ss1 + '&'
                  where xti_ss1 != '' and xti_ss1 is not null
            update @TP_Lists Set xti_u = 'V=1&' + xti_u + 'V1=' + xti_sv1 + '&'
                  where xti_sv1 != '' and xti_sv1 is not null
            update @TP_Lists Set xti_u = 'D=1&' + xti_u + 'D1=' + xti_sd1 + '&'
                  where xti_sd1 != '' and xti_sd1 is not null
 
		select 	@TPkeyMax = MAX(tp_key), 
				@TPkeyMin = MIN(tp_key) 
		from 	TP_Prices with(nolock)
		where tp_tokey = @nPriceTourKey
 
            Set @NumPrices = @TPkeyMax - @TPkeyMin + 1     -- определяем сколько нам понадобится сделать записей в таблицу pricelist
		declare @nPriceListKeyMax int                  -- максимально возможный ключ PriceList, который можно использовать
            exec GetNKeys 'PRICELIST', @NumPrices, @nPriceListKeyMax output
		declare @nDeltaTP_Price_PriceList int          -- разница в ключах между таблицами TP_Price и PriceList
            Set @nDeltaTP_Price_PriceList = (@nPriceListKeyMax - @NumPrices + 1) - @TPkeyMin
		declare @sURL varchar(250)                           -- ссылка, у Виталия Головченко называлась @u
		declare @sTLName varchar(160)
		declare @sTLWebHTTP varchar(128)
            select @sTLName = TL_Name, @sTLWebHTTP = TL_WebHTTP from dbo.TurList with(nolock) where TL_key = @TrKey
      
      -- начало. удаление похожих цен
	if @nPLNotDeleted = 0
      delete from dbo.pricelist with(rowlock) where exists (
                        select      1
                        from  @tp_lists, TP_TurDates with(nolock)
                        where xTI_FirstHdKey = pl_hdkey_first and xTI_FirstHrKey = PL_ROOM
                                   and xTI_FirstPnKey = PL_PNKEY and xTI_Days = PL_NDays and xti_CityArr = PL_CITYARR 
                                   and TD_TOKey = @nPriceTourKey
                                   and TD_Date = PL_DATEBEG
								   and PL_TrKey not IN (select tl_key from turlist with(nolock) where tl_tip in (6, 7)) 
								   and exists (select 1 from TP_Prices with(nolock) where tp_tokey = @nPriceTourKey and TD_Date=TP_DateBegin and TP_TIKey=xTI_Key) )
      -- конец. удаление похожих цен
 
		while       @TPkeyMin <= @TPkeyMax
		BEGIN
            begin tran tEnd
                  insert into dbo.PRICELIST with(rowlock) ( 
                        PL_KEY, PL_TI, PL_TO, PL_TP, 
                        PL_CREATOR, PL_DATEBEG, PL_DATEEND, PL_BRUTTO, 
                        PL_TRKEY, PL_NDays, PL_HDKEY_FIRST, PL_ROOM, 
                        PL_PANSION, PL_Category, PL_Main, PL_ACNMENAD, 
                        PL_ACNMENEXB, PL_ACAGEFROM1, PL_STARS, PL_HDNAME, 
                        PL_CNKEY, PL_HDCTKEY, PL_HDRSKEY, PL_URL, 
                        PL_CITYARR, PL_TLWEBHTTP, PL_HDHTTP, PL_ACNAME, 
                        PL_RCNAME, PL_RMNAME, PL_RSNAME, PL_RMKEY, 
                        PL_PNKEY, PL_TLNAME, PL_CTNAME) 
                  select @nDeltaTP_Price_PriceList + tp_key, TP_TIKey, tp_tokey, tp_key, 
                        0, tp_dateBegin, tp_DateEnd, TP_Gross, 
                        @TrKey, xTI_Days, xTI_FirstHdKey, xTI_FirstHrKey, --@TrKey объявлена в коде выше
                        xTI_PNCode, xTI_RCKey, xTI_ACMain, xTI_ACNRealPlaces,
                        xTI_ACNMenExBed, xTI_ACAgeFrom, xTI_HDStars, xTI_HDName, 
                        xTI_HDCNKey, xTI_HDCTKey, xTI_HDRSKey, xti_u,
                        xti_CityArr, @sTLWebHTTP, xTI_HDHTTP, xTI_ACName,
                        xTI_RCName, xTI_RMName, xTI_RSName, xTI_RMKey, 
                        xTI_FirstPnKey, @sTLName, xTI_CTName
                        from TP_Prices with(nolock), @TP_Lists               
                        where TP_TIKey = xTI_Key and tp_tokey = @nPriceTourKey                                  
                                   and tp_key between @TPkeyMin and @TPkeyMin + @nRowPart
            commit tran tEnd
            Set @TPkeyMin = @TPkeyMin + @nRowPart + 1
		END
		--  exec ttsCreatePrice123456Table @TrKey
		-- insert into History (Hi_date, Hi_text, Hi_SVKey) values (GetDate(), 'Скопировали в PriceList123.. и закончили расчет', @nPriceTourKey)	
		-- окончание записи в PriceList
		--    exec ttsLoadAllTpPrice @TrKey
	END
		

	Set @nTotalProgress = 100
	update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	set DATEFIRST @nDateFirst

	set nocount off

	Return 0
END

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

GRANT EXEC ON [dbo].[CalculatePriceList] TO PUBLIC
GO

-- 100716_alter_Debug_db_text.sql
ALTER TABLE [dbo].[Debug] ALTER COLUMN db_Text varchar(255);
GO

-- 100714_AlterCharterConstraints.sql
/*
delete from Charter where CH_AIRCRAFT not in (select AC_CODE from Aircraft)
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Charter_Aircraft]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
	ALTER TABLE dbo.Charter DROP CONSTRAINT [FK_Charter_Aircraft]
GO

ALTER TABLE [dbo].[Charter]  WITH CHECK ADD  CONSTRAINT [FK_Charter_Aircraft] FOREIGN KEY([CH_AIRCRAFT])
REFERENCES [dbo].[Aircraft] ([AC_CODE])
ON UPDATE CASCADE ON DELETE CASCADE
GO

delete from Charter where CH_AIRLINECODE not in (select AL_CODE from Airline)
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Charter_Airline]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
	ALTER TABLE dbo.Charter DROP CONSTRAINT [FK_Charter_Airline]
GO

ALTER TABLE [dbo].[Charter]  WITH CHECK ADD  CONSTRAINT [FK_Charter_Airline] FOREIGN KEY([CH_AIRLINECODE])
REFERENCES [dbo].[Airline] ([AL_CODE])
ON UPDATE CASCADE ON DELETE CASCADE
GO
*/

-- 100716_CreateDescType.sql
if not exists (select 1 from DescTypes where DT_Key = 133)
	insert into DescTypes (DT_Name, DT_Key, DT_TABLEID, DT_Order) values('Доплата', 133, 12, 0)
go

-- T_DogovorListUpdate.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_DogovorListUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_DogovorListUpdate]
GO

CREATE TRIGGER [T_DogovorListUpdate]
ON [dbo].[tbl_DogovorList]
FOR UPDATE, INSERT, DELETE
AS
IF @@ROWCOUNT > 0
BEGIN
--<VERSION>2007.2.37.0</VERSION>
--<DATE>2010-04-26</DATE>
  DECLARE @ODL_DgCod varchar(10)
  DECLARE @ODL_Key int
  DECLARE @ODL_SvKey int
  DECLARE @ODL_Code int
  DECLARE @ODL_SubCode1 int
  DECLARE @ODL_SubCode2 int
  DECLARE @ODL_CnKey int
  DECLARE @ODL_CtKey int
  DECLARE @ODL_NMen smallint
  DECLARE @ODL_Day smallint
  DECLARE @ODL_NDays smallint
  DECLARE @ODL_PartnerKey int
  DECLARE @ODL_Cost money
  DECLARE @ODL_Brutto money
  DECLARE @ODL_Discount money
  DECLARE @ODL_Wait smallint
  DECLARE @ODL_Control int
  DECLARE @ODL_sDateBeg varchar(10)
  DECLARE @ODL_DateBeg datetime
  DECLARE @ODL_sDateEnd varchar(10)
  DECLARE @ODL_DateEnd datetime
  DECLARE @ODL_RealNetto money
  DECLARE @ODL_Attribute int
  DECLARE @ODL_PaketKey int
  DECLARE @ODL_Name varchar(250)
  DECLARE @ODL_Payed money
  DECLARE @ODL_DGKey int
  DECLARE @ODL_QuoteKey int
  DECLARE @ODL_TimeBeg datetime
  DECLARE @ODL_TimeEnd datetime

  DECLARE @NDL_DgCod varchar(10)
  DECLARE @NDL_Key int
  DECLARE @NDL_SvKey int
  DECLARE @NDL_Code int
  DECLARE @NDL_SubCode1 int
  DECLARE @NDL_SubCode2 int
  DECLARE @NDL_CnKey int
  DECLARE @NDL_CtKey int
  DECLARE @NDL_NMen smallint
  DECLARE @NDL_Day smallint
  DECLARE @NDL_NDays smallint
  DECLARE @NDL_PartnerKey int
  DECLARE @NDL_Cost money
  DECLARE @NDL_Brutto money
  DECLARE @NDL_Discount money
  DECLARE @NDL_Wait smallint
  DECLARE @NDL_Control int
  DECLARE @NDL_sDateBeg varchar(10)
  DECLARE @NDL_DateBeg datetime
  DECLARE @NDL_sDateEnd varchar(10)
  DECLARE @NDL_DateEnd datetime
  DECLARE @NDL_RealNetto money
  DECLARE @NDL_Attribute int
  DECLARE @NDL_PaketKey int
  DECLARE @NDL_Name varchar(250)
  DECLARE @NDL_Payed money
  DECLARE @NDL_DGKey int
  DECLARE @NDL_QuoteKey int
  DECLARE @NDL_TimeBeg datetime
  DECLARE @NDL_TimeEnd datetime

  DECLARE @sMod varchar(3)
  DECLARE @nDelCount int
  DECLARE @nInsCount int
  DECLARE @nHIID int
  DECLARE @sHI_Text varchar(254)
  DECLARE @DL_Key int
  DECLARE @nDGSorGlobalCode_Old int, @nDGSorGlobalCode_New int,  @nDGSorCode_New int, @dDGTourDate datetime, @nDGKey int
  DECLARE @bNeedCommunicationUpdate smallint
  DECLARE @nSVKey int
  DECLARE @sDisableDogovorStatusChange varchar(254), @sUpdateMainDogovorStatuses varchar(254)

  DECLARE @dg_key INT

  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED

  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_DogovorList CURSOR FOR 
    SELECT 	N.DL_Key,
			null, null, null, null, null, null, null, null, null, null, null,
			null, null, null, null, null, null, null, null, 
			null, null, null, null, null, null, null,
			N.DL_DgCod, N.DL_DGKey, N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_SubCode2, N.DL_CnKey, N.DL_CtKey, N.DL_NMen, N.DL_Day, N.DL_NDays, 
			N.DL_PartnerKey, N.DL_Cost, N.DL_Brutto, N.DL_Discount, N.DL_Wait, N.DL_Control, N.DL_DateBeg, N.DL_DateEnd,
			N.DL_RealNetto, N.DL_Attribute, N.DL_PaketKey, N.DL_Name, N.DL_Payed, N.DL_QuoteKey, N.DL_TimeBeg
			
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_DogovorList CURSOR FOR 
    SELECT 	O.DL_Key,
			O.DL_DgCod, O.DL_DGKey, O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_SubCode2, O.DL_CnKey, O.DL_CtKey, O.DL_NMen, O.DL_Day, O.DL_NDays, 
			O.DL_PartnerKey, O.DL_Cost, O.DL_Brutto, O.DL_Discount, O.DL_Wait, O.DL_Control, O.DL_DateBeg, O.DL_DateEnd,
			O.DL_RealNetto, O.DL_Attribute, O.DL_PaketKey, O.DL_Name, O.DL_Payed, O.DL_QuoteKey, O.DL_TimeBeg, 
			null, null, null, null, null, null, null, null, null, null, null,
			null, null, null, null, null, null, null, null, 
			null, null, null, null, null, null, null
    FROM DELETED O
  END
  ELSE 
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_DogovorList CURSOR FOR 
    SELECT 	N.DL_Key,
			O.DL_DgCod, O.DL_DGKey, O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_SubCode2, O.DL_CnKey, O.DL_CtKey, O.DL_NMen, O.DL_Day, O.DL_NDays, 
			O.DL_PartnerKey, O.DL_Cost, O.DL_Brutto, O.DL_Discount, O.DL_Wait, O.DL_Control, O.DL_DateBeg, O.DL_DateEnd,
			O.DL_RealNetto, O.DL_Attribute, O.DL_PaketKey, O.DL_Name, O.DL_Payed, O.DL_QuoteKey, O.DL_TimeBeg,
	  		N.DL_DgCod, N.DL_DGKey, N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_SubCode2, N.DL_CnKey, N.DL_CtKey, N.DL_NMen, N.DL_Day, N.DL_NDays, 
			N.DL_PartnerKey, N.DL_Cost, N.DL_Brutto, N.DL_Discount, N.DL_Wait, N.DL_Control, N.DL_DateBeg, N.DL_DateEnd,
			N.DL_RealNetto, N.DL_Attribute, N.DL_PaketKey, N.DL_Name, N.DL_Payed, N.DL_QuoteKey, N.DL_TimeBeg
    FROM DELETED O, INSERTED N 
    WHERE N.DL_Key = O.DL_Key
  END

    OPEN cur_DogovorList
    FETCH NEXT FROM cur_DogovorList INTO 
		@DL_Key, 
			@ODL_DgCod, @ODL_DGKey, @ODL_SvKey, @ODL_Code, @ODL_SubCode1, @ODL_SubCode2, @ODL_CnKey, @ODL_CtKey, @ODL_NMen, @ODL_Day, @ODL_NDays, 
			@ODL_PartnerKey, @ODL_Cost, @ODL_Brutto, @ODL_Discount, @ODL_Wait, @ODL_Control, @ODL_DateBeg, @ODL_DateEnd, 
			@ODL_RealNetto, @ODL_Attribute, @ODL_PaketKey, @ODL_Name, @ODL_Payed, @ODL_QuoteKey, @ODL_TimeBeg,
			@NDL_DgCod, @NDL_DGKey, @NDL_SvKey, @NDL_Code, @NDL_SubCode1, @NDL_SubCode2, @NDL_CnKey, @NDL_CtKey, @NDL_NMen, @NDL_Day, @NDL_NDays, 
			@NDL_PartnerKey, @NDL_Cost, @NDL_Brutto, @NDL_Discount, @NDL_Wait, @NDL_Control, @NDL_DateBeg, @NDL_DateEnd, 
			@NDL_RealNetto, @NDL_Attribute, @NDL_PaketKey, @NDL_Name, @NDL_Payed, @NDL_QuoteKey, @NDL_TimeBeg
    WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @NDL_sDateBeg=CONVERT( char(10), @NDL_DateBeg, 104)
		SET @ODL_sDateBeg=CONVERT( char(10), @ODL_DateBeg, 104)
		SET @NDL_sDateEnd=CONVERT( char(10), @NDL_DateEnd, 104)
		SET @ODL_sDateEnd=CONVERT( char(10), @ODL_DateEnd, 104)

    	------------Проверка, надо ли что-то писать в историю квот-------------------------------------------   
		If ISNULL(@ODL_QuoteKey, 0) != ISNULL(@NDL_QuoteKey, 0) and (ISNULL(@NDL_QuoteKey, 0)>1 or ISNULL(@ODL_QuoteKey, 0)>1)
		BEGIN
			declare @sOper varchar(25)
			EXEC dbo.CurrentUser @sOper output
			if ISNULL(@ODL_QuoteKey, 0)!=0
				INSERT INTO HistoryQuote (HQ_Date, HQ_Mod, HQ_Who, HQ_Text, HQ_QTKey, HQ_DLKey)
					VALUES (GETDATE(), 'DEL', @sOper, @sHI_Text, @ODL_QuoteKey, @DL_Key)
			if ISNULL(@NDL_QuoteKey, 0)!=0
				INSERT INTO HistoryQuote (HQ_Date, HQ_Mod, HQ_Who, HQ_Text, HQ_QTKey, HQ_DLKey)
					VALUES (GETDATE(), 'INS', @sOper, @sHI_Text, @NDL_QuoteKey, @DL_Key)
		END

    	------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@ODL_DgCod, '') != ISNULL(@NDL_DgCod, '')  OR
			ISNULL(@ODL_DGKey, '') != ISNULL(@NDL_DGKey, '')  OR
			ISNULL(@ODL_SvKey, '') != ISNULL(@NDL_SvKey, '')  OR
			ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, '')  OR
			ISNULL(@ODL_SubCode1, '') != ISNULL(@NDL_SubCode1, '')  OR
			ISNULL(@ODL_SubCode2, '') != ISNULL(@NDL_SubCode2, '')  OR
			ISNULL(@ODL_CnKey, '') != ISNULL(@NDL_CnKey, '')  OR
			ISNULL(@ODL_CtKey, '') != ISNULL(@NDL_CtKey, '')  OR
			ISNULL(@ODL_NMen, '') != ISNULL(@NDL_NMen, '')  OR
			ISNULL(@ODL_Day, '') != ISNULL(@NDL_Day, '')  OR
			ISNULL(@ODL_NDays, '') != ISNULL(@NDL_NDays, '')  OR
			ISNULL(@ODL_PartnerKey, '') != ISNULL(@NDL_PartnerKey, '')  OR
			ISNULL(@ODL_Cost, 0) != ISNULL(@NDL_Cost, 0)  OR
			ISNULL(@ODL_Brutto, 0) != ISNULL(@NDL_Brutto, 0)  OR
			ISNULL(@ODL_Discount, 0) != ISNULL(@NDL_Discount, 0)  OR
			ISNULL(@ODL_Wait, '') != ISNULL(@NDL_Wait, '')  OR
			ISNULL(@ODL_Control, '') != ISNULL(@NDL_Control, '')  OR
			ISNULL(@ODL_sDateBeg, '') != ISNULL(@NDL_sDateBeg, '')  OR
			ISNULL(@ODL_sDateEnd, '') != ISNULL(@NDL_sDateEnd, '')  OR
			ISNULL(@ODL_RealNetto, 0) != ISNULL(@NDL_RealNetto, 0)  OR
			ISNULL(@ODL_Attribute, '') != ISNULL(@NDL_Attribute, '')  OR
			ISNULL(@ODL_PaketKey, '') != ISNULL(@NDL_PaketKey, '') OR
			ISNULL(@ODL_Name, '') != ISNULL(@NDL_Name, '') OR 
			ISNULL(@ODL_Payed, 0) != ISNULL(@NDL_Payed, 0) OR 
			ISNULL(@ODL_TimeBeg, 0) != ISNULL(@NDL_TimeBeg, 0)
		)
		BEGIN
		  	------------Запись в историю--------------------------------------------------------------------
			if (@sMod = 'INS')
			BEGIN
				SET @sHI_Text = ISNULL(@NDL_Name, '')
				SET @nDGKey=@NDL_DGKey
				SET @nSVKey=@NDL_SvKey
			END
			else if (@sMod = 'DEL')
				BEGIN
				SET @sHI_Text = ISNULL(@ODL_Name, '')
				SET @NDL_DgCod = @ODL_DgCod
				SET @nDGKey=@ODL_DGKey
				SET @nSVKey=@ODL_SvKey
				END
			else if (@sMod = 'UPD')
			BEGIN
				SET @sHI_Text = ISNULL(@NDL_Name, '')
				SET @nDGKey=@NDL_DGKey
				SET @nSVKey=@NDL_SvKey
			END
			EXEC @nHIID = dbo.InsHistory @NDL_DgCod, @nDGKey, 2, @DL_Key, @sMod, @sHI_Text, '', 0, ''
			--SELECT @nHIID = IDENT_CURRENT('History')		
			--------Детализация--------------------------------------------------

			DECLARE @sText_Old varchar(100)
			DECLARE @sText_New varchar(100)
    
    			DECLARE @sText_AllTypeRooming varchar(20)
			SET @sText_AllTypeRooming  = 'Все типы размещения'

			If (ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, ''))
			BEGIN
				/*
				IF @NDL_SvKey=1
				BEGIN
					-- mv26.04.2010
					-- Перенес вниз см. начиная с "-- ИНДИВИДУАЛЬНАЯ ОБРАБОТКА АВИАПЕРЕЛЕТОВ"
				END
				*/
				IF @NDL_SvKey!=1
				BEGIN
					exec dbo.GetSVCodeName @ODL_SvKey, @ODL_Code, @sText_Old output, null
					exec dbo.GetSVCodeName @NDL_SvKey, @NDL_Code, @sText_New output, null
					IF @NDL_SvKey = 2
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1028, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
					ELSE IF (@NDL_SvKey = 3 or @NDL_SvKey = 8)
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1029, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
					ELSE IF @NDL_SvKey = 4
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1030, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
					ELSE IF (@NDL_SvKey = 7 or @NDL_SvKey = 9)
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1031, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
					ELSE 
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1032, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
				END
			END

			If (ISNULL(@ODL_SubCode1, '') != ISNULL(@NDL_SubCode1, ''))
				IF @NDL_SvKey = 1 or @ODL_SvKey = 1
				BEGIN
					Select @sText_Old = AS_Code + ' ' + AS_NameRus from AirService where AS_Key = @ODL_SubCode1
					Select @sText_New = AS_Code + ' ' + AS_NameRus from AirService where AS_Key = @NDL_SubCode1
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1033, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE IF @NDL_SvKey = 2 or @NDL_SvKey = 4 or @ODL_SvKey = 2 or @ODL_SvKey = 4
				BEGIN
					Select @sText_Old = TR_Name from Transport where TR_Key = @ODL_SubCode1
					Select @sText_New = TR_Name from Transport where TR_Key = @NDL_SubCode1
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1034, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE IF @NDL_SvKey = 3 or @NDL_SvKey = 8 or @ODL_SvKey = 3 or @ODL_SvKey = 8
				BEGIN
					Select @sText_Old = RM_Name + ',' + RC_Name + ',' + AC_Code from HotelRooms,Rooms,RoomsCategory,AccmdMenType where HR_Key = @ODL_SubCode1 and RM_Key=HR_RmKey and RC_Key=HR_RcKey and AC_Key=HR_AcKey
					Select @sText_New = RM_Name + ',' + RC_Name + ',' + AC_Code from HotelRooms,Rooms,RoomsCategory,AccmdMenType where HR_Key = @NDL_SubCode1 and RM_Key=HR_RmKey and RC_Key=HR_RcKey and AC_Key=HR_AcKey
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1035, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE IF @NDL_SvKey = 7 or @NDL_SvKey = 9 or @ODL_SvKey = 7 or @ODL_SvKey = 9
				BEGIN
					IF @ODL_SubCode1 = 0
						Set @sText_Old = @sText_AllTypeRooming
					Else
						Select @sText_Old = ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_Name,'') from Cabine where CB_Key = @ODL_SubCode1
					IF @NDL_SubCode1 = 0
						Set @sText_New = @sText_AllTypeRooming
					Else
						Select @sText_New = ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_Name,'') from Cabine where CB_Key = @NDL_SubCode1
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1035, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE
				BEGIN
					Select @sText_Old = A1_Name from AddDescript1 where A1_Key = @ODL_SubCode1
					Select @sText_New = A1_Name from AddDescript1 where A1_Key = @NDL_SubCode1
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1036, @sText_Old, @sText_New, @ODL_SubCode1, @NDL_SubCode1, null, null, 0, @bNeedCommunicationUpdate output
				END
	
			If (ISNULL(@ODL_SubCode2, '') != ISNULL(@NDL_SubCode2, ''))
				IF @NDL_SvKey = 3 or @NDL_SvKey = 7 or @ODL_SvKey = 3 or @ODL_SvKey = 7
				BEGIN
					Select @sText_Old = PN_Name from Pansion where PN_Key = @ODL_SubCode2
					Select @sText_New = PN_Name from Pansion where PN_Key = @NDL_SubCode2
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1037, @sText_Old, @sText_New, @ODL_SubCode2, @NDL_SubCode2, null, null, 0, @bNeedCommunicationUpdate output
				END
				ELSE
				BEGIN
					Select @sText_Old = A2_Name from AddDescript2 where A2_Key = @ODL_SubCode2
					Select @sText_New = A2_Name from AddDescript2 where A2_Key = @NDL_SubCode2
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1038, @sText_Old, @sText_New, @ODL_SubCode2, @NDL_SubCode2, null, null, 0, @bNeedCommunicationUpdate output
				END

			If (ISNULL(@ODL_PartnerKey, '') != ISNULL(@NDL_PartnerKey, ''))
			BEGIN
				Select @sText_Old = PR_Name from Partners where PR_Key = @ODL_PartnerKey
				Select @sText_New = PR_Name from Partners where PR_Key = @NDL_PartnerKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1039, @sText_Old, @sText_New, @ODL_PartnerKey, @NDL_PartnerKey, null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_Control, '') != ISNULL(@NDL_Control, ''))
			BEGIN
				Select @sText_Old = CR_Name from Controls where CR_Key = @ODL_Control
				Select @sText_New = CR_Name from Controls where CR_Key = @NDL_Control
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1040, @sText_Old, @sText_New, @ODL_Control, @NDL_Control, null, null, 0, @bNeedCommunicationUpdate output

				-- StatusRules
				if @ODL_DGKey is not null
					set @dg_key = @ODL_DGKey
				else
					set @dg_key = @NDL_DGKey

				exec dbo.SetReservationStatus @dg_key
				--------------
			END
			If (ISNULL(@ODL_CtKey, '') != ISNULL(@NDL_CtKey, ''))
			BEGIN
				Select @sText_Old = CT_Name from CityDictionary where CT_Key = @ODL_CtKey
				Select @sText_New = CT_Name from CityDictionary where CT_Key = @NDL_CtKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1041, @sText_Old, @sText_New, @ODL_CtKey, @NDL_CtKey, null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_CnKey, '') != ISNULL(@NDL_CnKey, ''))
			BEGIN
				Select @sText_Old = CN_Name from Country where CN_Key = @ODL_CnKey
				Select @sText_New = CN_Name from Country where CN_Key = @NDL_CnKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1042, @sText_Old, @sText_New, @ODL_CnKey, @NDL_CnKey, null, null, 0, @bNeedCommunicationUpdate output
			END

		 	If (ISNULL(@ODL_NMen  , '') != ISNULL(@NDL_NMen, ''))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1043, @ODL_NMen  , @NDL_NMen, '', '', null, null, 0, @bNeedCommunicationUpdate output
			If (ISNULL(@ODL_Cost, 0) != ISNULL(@NDL_Cost, 0))
			BEGIN	
				Set @sText_Old = CAST(@ODL_Cost as varchar(100))
				Set @sText_New = CAST(@NDL_Cost as varchar(100))				
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1044, @sText_Old, @sText_New, '', '', null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_Brutto, 0) != ISNULL(@NDL_Brutto, 0))
			BEGIN	
				Set @sText_Old = CAST(@ODL_Brutto as varchar(100))
				Set @sText_New = CAST(@NDL_Brutto as varchar(100))				
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1045, @sText_Old, @sText_New, '', '', null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_sDateBeg, 0) != ISNULL(@NDL_sDateBeg, 0))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1046, @ODL_sDateBeg, @NDL_sDateBeg, null, null, null, null, 0, @bNeedCommunicationUpdate output
			If (ISNULL(@ODL_sDateEnd, 0) != ISNULL(@NDL_sDateEnd, 0))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1047, @ODL_sDateEnd, @NDL_sDateEnd, null, null, null, null, 0, @bNeedCommunicationUpdate output
			If (ISNULL(@ODL_NDays, 0) != ISNULL(@NDL_NDays, 0))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1048, @ODL_NDays, @NDL_NDays, null, null, null, null, 0, @bNeedCommunicationUpdate output

			If (ISNULL(@ODL_Wait, '') != ISNULL(@NDL_Wait, '')) 
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1049, @ODL_Wait, @NDL_Wait, @ODL_Wait, @NDL_Wait, null, null, 0, @bNeedCommunicationUpdate output
				
				-- StatusRules
				if @ODL_DGKey is not null
					set @dg_key = @ODL_DGKey
				else
					set @dg_key = @NDL_DGKey

				exec dbo.SetReservationStatus @dg_key
				--------------
			END
			
			If (ISNULL(@ODL_Name, 0) != ISNULL(@NDL_Name, 0))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1050, @ODL_Name, @NDL_Name, null, null, null, null, 0, @bNeedCommunicationUpdate output
			If (ISNULL(@ODL_RealNetto, 0) != ISNULL(@NDL_RealNetto, 0))
			BEGIN
				Set @sText_Old = CAST(@ODL_RealNetto as varchar(10))
				Set @sText_New = CAST(@NDL_RealNetto as varchar(10))				
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1119, @sText_Old, @sText_New, '', '', null, null, 0, @bNeedCommunicationUpdate output
			END
			If (ISNULL(@ODL_Payed, 0) != ISNULL(@NDL_Payed, 0))
			BEGIN
				Set @sText_Old = CAST(@ODL_Payed as varchar(10))
				Set @sText_New = CAST(@NDL_Payed as varchar(10))				
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1120, @sText_Old, @sText_New, '', '', null, null, 0, @bNeedCommunicationUpdate output
			END
			If @ODL_TimeBeg!=@NDL_TimeBeg
			BEGIN
				Set @sText_Old=ISNULL(CONVERT(char(5), @ODL_TimeBeg, 114), 0)
				Set @sText_New=ISNULL(CONVERT(char(5), @NDL_TimeBeg, 114), 0)
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1125, @sText_Old, @sText_New, null, null, @ODL_TimeBeg, @NDL_TimeBeg, 0, @bNeedCommunicationUpdate output
			END
			
			If (ISNULL(@ODL_Control, '') != ISNULL(@NDL_Control, '')  OR ISNULL(@ODL_Wait, '') != ISNULL(@NDL_Wait, ''))
			BEGIN
				/*
				Set @nDGSorGlobalCode_New = 0

				----------------Изменение статуса путевки в случае, если статусы услуг установлены в ОК
				Select @nDGSorGlobalCode_Old = OS_Global, @dDGTourDate = DG_TurDate from Dogovor, dbo.Order_Status where DG_Key=@nDGKey and DG_Sor_Code=OS_Code
				IF @dDGTourDate != '30-DEC-1899' -- путевка не должна быть аннулирована.
				BEGIN
					select @sDisableDogovorStatusChange = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSDisDogovorStatusChange'
					if (@sDisableDogovorStatusChange is null or @sDisableDogovorStatusChange = '0')
					begin
						set @nDGSorCode_New = 7				--ОК
						IF exists (SELECT 1 FROM dbo.Setting WHERE ST_Version like '7%')
						BEGIN
							IF exists (Select DL_Key from DogovorList where DL_DGKey=@nDGKey and DL_Wait>0)
							BEGIN
								set @nDGSorCode_New = 3			--Wait-List
								set @nDGSorGlobalCode_New = 3	--Глобальный Wait-List
							END
						END
						IF @nDGSorGlobalCode_New!=3 
							IF exists (Select DL_Key from DogovorList where DL_DGKey=@nDGKey and DL_Control > 0)
							BEGIN
								set @nDGSorCode_New = 4			--Не подтвержден
								set @nDGSorGlobalCode_New = 1	--Глобальный "Не подтвержден"
							END

						if @nDGSorGlobalCode_Old != @nDGSorGlobalCode_New
						BEGIN
							select @sUpdateMainDogovorStatuses = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSUpdateMainDogStatuses'
							if (ISNULL(@sUpdateMainDogovorStatuses, '0') = '0')
								update Dogovor set DG_Sor_Code = @nDGSorCode_New where DG_Key=@nDGKey
							else
								-- изменяем статус путевки только если он был стандартным
								update Dogovor set DG_Sor_Code = @nDGSorCode_New where DG_Key=@nDGKey and DG_Sor_Code in (1,2,3,7)
						END
					end
				END
				*/
				If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey) )
					UPDATE Communications SET 
						CM_StatusConfirmed=(SELECT Count(1) FROM DogovorList, Controls WHERE DL_Control=CR_Key AND CR_GlobalState=1 AND DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey),
						CM_StatusNotConfirmed=(SELECT Count(1) FROM DogovorList, Controls WHERE DL_Control=CR_Key AND CR_GlobalState=3 AND DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey),
						CM_StatusWait=(SELECT Count(1) FROM DogovorList, Controls WHERE DL_Control=CR_Key AND CR_GlobalState=2 AND DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey),
						CM_StatusUnknown=(SELECT Count(1) FROM DogovorList, Controls WHERE DL_Control=CR_Key AND CR_GlobalState is null AND DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey)
					WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey)
			END
			If ( ( ISNULL(@ODL_Cost, 0) != ISNULL(@NDL_Cost, 0) ) or ( ISNULL(@ODL_RealNetto, 0) != ISNULL(@NDL_RealNetto, 0) ) )
			BEGIN	
				If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey) )
					UPDATE Communications SET 
						CM_SumNettoPlan=(SELECT SUM(DL_Cost) FROM DogovorList WHERE DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey),
						CM_SumNettoProvider=(SELECT SUM(DL_RealNetto) FROM DogovorList WHERE DL_PartnerKey=CM_PRKey AND DL_DGKey=CM_DGKey)
					WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey)
			END
			-- ИНДИВИДУАЛЬНАЯ ОБРАБОТКА АВИАПЕРЕЛЕТОВ
			If (@NDL_SvKey = 1 AND ((ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, '')) OR (ISNULL(@ODL_sDateBeg, 0) != ISNULL(@NDL_sDateBeg, 0)) OR ((ISNULL(@ODL_Name, 0) != ISNULL(@NDL_Name, 0)))))
			BEGIN
				DECLARE @APFrom_Old varchar(50), @APTo_Old varchar(50), @AL_Old varchar(50)
				IF ISNULL(@ODL_Code, '') != ''
				BEGIN
					SELECT 
						@sText_Old=CH_AirLineCode + ' ' + CH_Flight,
						@APFrom_Old=(SELECT TOP 1 AP_Name FROM AirPort WHERE AP_Code=CH_PortCodeFrom), 
						@APTo_Old=(SELECT TOP 1 AP_Name FROM AirPort WHERE AP_Code=CH_PortCodeTo), 
						@AL_Old=(SELECT TOP 1 AL_Name FROM AirLine WHERE AL_Code=CH_AirLineCode) 
						FROM Charter WHERE CH_Key=@ODL_Code
				END
				DECLARE @APFrom_New varchar(50), @APTo_New varchar(50), @AL_New varchar(50)
				IF ISNULL(@NDL_Code, '') != ''
				BEGIN
					SELECT 
						@sText_New=CH_AirLineCode + ' ' + CH_Flight,
						@APFrom_New=(SELECT TOP 1 AP_Name FROM AirPort WHERE AP_Code=CH_PortCodeFrom), 
						@APTo_New=(SELECT TOP 1 AP_Name FROM AirPort WHERE AP_Code=CH_PortCodeTo), 
						@AL_New=(SELECT TOP 1 AL_Name FROM AirLine WHERE AL_Code=CH_AirLineCode) 
						FROM Charter WHERE CH_Key=@NDL_Code
				END
				If (ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1027, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
				If (ISNULL(@APFrom_Old, '') != ISNULL(@APFrom_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1135, @APFrom_Old, @APFrom_New, null, null, null, null, 0, @bNeedCommunicationUpdate output
				If (ISNULL(@APTo_Old, '') != ISNULL(@APTo_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1136, @APTo_Old, @APTo_New, null, null, null, null, 0, @bNeedCommunicationUpdate output
				If (ISNULL(@AL_Old, '') != ISNULL(@AL_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1139, @AL_Old, @AL_New, null, null, null, null, 0, @bNeedCommunicationUpdate output

				DECLARE @sTimeBeg_Old varchar(5), @sTimeEnd_Old varchar(5), @sTimeBeg_New varchar(5), @sTimeEnd_New varchar(5)
				Declare @nday int
				IF (ISNULL(@ODL_Code, '') != '')
				BEGIN
					Set @nday = DATEPART(dw, @ODL_DateBeg)  + @@DATEFIRST - 1
					If @nday > 7 
		    			set @nday = @nday - 7
					SELECT	TOP 1 
						@sTimeBeg_Old=LEFT(CONVERT(varchar, AS_TimeFrom, 8),5),
						@sTimeEnd_Old=LEFT(CONVERT(varchar, AS_TimeTo, 8),5)
					FROM 	dbo.AirSeason
					WHERE 	AS_CHKey=@ODL_Code
						and CHARINDEX(CAST(@nday as varchar(1)),AS_Week)>0
						and @ODL_DateBeg between AS_DateFrom and AS_DateTo
					ORDER BY AS_TimeFrom DESC
				END

				IF (ISNULL(@NDL_Code, '') != '')
				BEGIN
					Set @nday = DATEPART(dw, @NDL_DateBeg)  + @@DATEFIRST - 1
					If @nday > 7 
						set @nday = @nday - 7
					SELECT	TOP 1 
						@sTimeBeg_New=LEFT(CONVERT(varchar, AS_TimeFrom, 8),5),
						@sTimeEnd_New=LEFT(CONVERT(varchar, AS_TimeTo, 8),5)
					FROM 	dbo.AirSeason
					WHERE 	AS_CHKey=@NDL_Code
						and CHARINDEX(CAST(@nday as varchar(1)),AS_Week)>0
						and @NDL_DateBeg between AS_DateFrom and AS_DateTo
					ORDER BY AS_TimeFrom DESC
				END
				If (ISNULL(@sTimeBeg_Old, '') != ISNULL(@sTimeBeg_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1137, @sTimeBeg_Old, @sTimeBeg_New, null, null, null, null, 0, @bNeedCommunicationUpdate output
				If (ISNULL(@sTimeEnd_Old, '') != ISNULL(@sTimeEnd_New, ''))
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1138, @sTimeEnd_Old, @sTimeEnd_New, null, null, null, null, 0, @bNeedCommunicationUpdate output
			END
		END
			If @bNeedCommunicationUpdate=1
			BEGIN
				If @nSVKey=1 and ( 
						(ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, '')) or 
						(ISNULL(@ODL_sDateBeg, 0) != ISNULL(@NDL_sDateBeg, 0))
						 )
				BEGIN
					If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@nDGKey)
						UPDATE Communications SET CM_ChangeDate=GetDate() WHERE CM_DGKey=@nDGKey
				END
				
				ELSE
				BEGIN
					If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey) )
						UPDATE Communications SET CM_ChangeDate=GetDate() WHERE CM_DGKey=@nDGKey and CM_PRKey in (@ODL_PartnerKey,@NDL_PartnerKey)
				END
			END
		------------Аннуляция полиса при удаления услуги----------------------------------
		if (@sMod = 'DEL')
		BEGIN
			UPDATE InsPolicy
			SET IP_ARKEY = 0, IP_AnnulDate = GetDate()
			WHERE IP_DLKey = @DL_KEY AND IP_ARKEY IS NULL AND IP_ANNULDATE IS NULL
		END

    	------------Для поддержки совместимости-------------------------------------------   

			If 	(ISNULL(@ODL_Code, '') != ISNULL(@NDL_Code, '')) or
				(ISNULL(@ODL_SubCode1, '') != ISNULL(@NDL_SubCode1, '')) or
				(ISNULL(@ODL_SubCode2, '') != ISNULL(@NDL_SubCode2, '')) or
				(ISNULL(@ODL_NDays, 0) != ISNULL(@NDL_NDays, 0)) or 
				(ISNULL(@ODL_Day, '') != ISNULL(@NDL_Day, ''))
				EXECUTE dbo.InsHistory @NDL_DgCod, @NDL_DGKey, 2, @DL_Key, 'MOD', @ODL_Name, '', 1, ''

			If 	(ISNULL(@ODL_Wait, '') != ISNULL(@NDL_Wait, '')) 
			BEGIN
				If (@NDL_Wait = 1)
					EXECUTE dbo.InsHistory @NDL_DgCod, @NDL_DGKey, 2, @DL_Key, '+WL', @ODL_Name, '', 0, ''
				else
					EXECUTE dbo.InsHistory @NDL_DgCod, @NDL_DGKey, 2, @DL_Key, '-WL', @ODL_Name, '', 0, ''
			END

		    FETCH NEXT FROM cur_DogovorList INTO 
		@DL_Key, 
			@ODL_DgCod, @ODL_DGKey, @ODL_SvKey, @ODL_Code, @ODL_SubCode1, @ODL_SubCode2, @ODL_CnKey, @ODL_CtKey, @ODL_NMen, @ODL_Day, @ODL_NDays, 
			@ODL_PartnerKey, @ODL_Cost, @ODL_Brutto, @ODL_Discount, @ODL_Wait, @ODL_Control, @ODL_DateBeg, @ODL_DateEnd, 
			@ODL_RealNetto, @ODL_Attribute, @ODL_PaketKey, @ODL_Name, @ODL_Payed, @ODL_QuoteKey, @ODL_TimeBeg,
			@NDL_DgCod, @NDL_DGKey, @NDL_SvKey, @NDL_Code, @NDL_SubCode1, @NDL_SubCode2, @NDL_CnKey, @NDL_CtKey, @NDL_NMen, @NDL_Day, @NDL_NDays, 
			@NDL_PartnerKey, @NDL_Cost, @NDL_Brutto, @NDL_Discount, @NDL_Wait, @NDL_Control, @NDL_DateBeg, @NDL_DateEnd, 
			@NDL_RealNetto, @NDL_Attribute, @NDL_PaketKey, @NDL_Name, @NDL_Payed, @NDL_QuoteKey, @NDL_TimeBeg
	END
  CLOSE cur_DogovorList
  DEALLOCATE cur_DogovorList
 END
GO

-- 20100729_AlterTableClients.sql
alter table Clients alter column CL_BIRTHCITY varchar(60) collate database_default
GO
alter table Clients alter column CL_POSTCITY varchar(60) collate database_default
GO
alter table Clients alter column CL_POSTBILD varchar(10) collate database_default
GO

-- T_Service.sql
/****** Объект:  Trigger [T_Service]    Дата сценария: 08/02/2010 17:58:07 ******/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_Service]'))
DROP TRIGGER [dbo].[T_Service]
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: 30.07.2010
-- Description:	Запрещает изменять поле SV_ISCITY, SV_ISSUBCODE1 и SV_ISSUBCODE2  Если по этому классу услуг есть связи
-- =============================================
CREATE TRIGGER [dbo].[T_Service]
   ON  [dbo].[Service]
   AFTER UPDATE
AS 
BEGIN
	if (EXISTS (SELECT * FROM deleted join inserted on deleted.sv_key = inserted.sv_key AND (deleted.SV_ISCITY <> inserted.SV_ISCITY OR deleted.SV_ISSUBCODE1 <> inserted.SV_ISSUBCODE1 OR deleted.SV_ISSUBCODE2 <> inserted.SV_ISSUBCODE2) AND (dbo.fn_GetServiceLink(inserted.sv_key) = 1)))
		BEGIN
			ROLLBACK TRANSACTION
			RAISERROR('Нельзя изменить привязку местоположения и описание, если по классу услуг есть зависимости',16,1)
		END
END
GO

-- 100803(Alter COLUMN TU_NUMDOC).sql
if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS
	where TABLE_SCHEMA='dbo' and TABLE_NAME='TuristService' and COLUMN_NAME='TU_NUMDOC')<30)
ALTER TABLE dbo.TuristService ALTER COLUMN TU_NUMDOC varchar(30) NULL
GO

-- sp_DogovorPayment.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DogovorPayment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DogovorPayment]
GO

CREATE  procedure [dbo].[DogovorPayment]
(
	@nDGKey int
)
as
-- VERSION 2007.2 
-- 2010-04-23
declare @nDGPayed money, @nDGPrice money
declare @nPaymentDetailsSum money
declare @nPaymentDetailsSumNational money
declare @nDGNationalCurrencyPayed money
declare @sAutoBlock varchar(1)

if @nDGKey is null or @nDGKey = 0
	return 0

select @nDGPayed = DG_Payed, @nDGPrice = DG_Price, @nDGNationalCurrencyPayed = DG_NationalCurrencyPayed from Dogovor where DG_Key = @nDGKey

select @nPaymentDetailsSum = ROUND(sum(PD_SumInDogovorRate),2), @nPaymentDetailsSumNational = ROUND(sum(PD_SumNational),2)
from PaymentDetails, Payments, PaymentOperations
where PD_PMId = PM_Id and PM_POId = PO_Id 
	and PD_DGKey = @nDGKey
	and (PM_IsDeleted is null or PM_IsDeleted = 0) 
	and (PO_Type is null or PO_Type = 0)
group by PD_DGKey

if @nPaymentDetailsSum is null
	set @nPaymentDetailsSum = 0

Select @sAutoBlock = SS_ParmValue from dbo.SystemSettings where SS_ParmName='SYSAutoBlock'

if ISNULL(@nDGPayed, 0) != ISNULL(@nPaymentDetailsSum, 0) OR ISNULL(@nDGNationalCurrencyPayed, 0) != ISNULL(@nPaymentDetailsSumNational, 0)
BEGIN
	if @sAutoBlock = '1' and @nDGPrice <= (@nPaymentDetailsSum + 0.01)
		update Dogovor set DG_Locked = 1, DG_Payed = @nPaymentDetailsSum, DG_NationalCurrencyPayed=@nPaymentDetailsSumNational  where DG_Key = @nDGKey
	else
		update Dogovor set DG_Payed = @nPaymentDetailsSum, DG_NationalCurrencyPayed=@nPaymentDetailsSumNational  where DG_Key = @nDGKey
END
return 0
GO

grant execute on [dbo].[DogovorPayment] to public
GO



-- sp_GetSvCode1Name.sql
GO
/****** Объект:  StoredProcedure [dbo].[GetSvCode1Name]    Дата сценария: 08/03/2010 13:01:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetSvCode1Name]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetSvCode1Name]
GO
/****** Объект:  StoredProcedure [dbo].[GetSvCode1Name]    Дата сценария: 08/03/2010 13:01:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetSvCode1Name]
(
--<VERSION>2005.4.22</VERSION>
	@nSvKey INT,
	@nCode1 INT,
	@sTitle VARCHAR(800) OUTPUT,
	@sName VARCHAR(800) OUTPUT,
	@sTitleLat VARCHAR(800) OUTPUT,
	@sNameLat VARCHAR(800) OUTPUT,
	@bIsQuote bit = null
) AS
DECLARE 
	@nRoom INT,
	@nCategory INT,
	@sNameCategory VARCHAR(800),
	@sNameCategoryLat VARCHAR(800),
	@nHrMain INT,
	@nAgeFrom INT,
	@nAgeTo INT,
	@sAcCode VARCHAR(800),
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

		IF EXISTS(SELECT * FROM dbo.AirService WHERE AS_Key = @nCode1) AND (@nCode1 <> -1)
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
	IF (@nSvKey = @TYPE_HOTELADDSRV or @nSvKey = @TYPE_HOTEL)
	BEGIN
		IF @nCode1 = 0
			IF ISNULL(@bIsQuote,0) = 1
			BEGIN
				SET @sTitle = 'Тип номера'
				SET @sName = 'Все типы номеров'
				SET @sTitleLat = 'Room type'
				SET @sNameLat = 'All room types'
			END
			ELSE
			BEGIN
				SET @sTitle = 'Размещение'
				SET @sName = 'Все размещения'
				SET @sTitleLat = 'Accommodation'
				SET @sNameLat = 'All accommodations'
			END
		ELSE	
			IF ISNULL(@bIsQuote,0) = 1
			BEGIN
				EXEC GetRoomName @nCode1, @sName output, @sNameLat output

				Set @sTitle = 'Тип номера'
				Set @sTitleLat = 'Room type'
			END
			ELSE
			BEGIN
				EXEC GetRoomKey @nCode1, @nRoom output
				EXEC GetRoomCategoryKey @nCode1, @nCategory output
				EXEC GetRoomName @nRoom, @sName output, @sNameLat output
				EXEC GetRoomCtgrName @nCategory, @sNameCategory output, @sNameCategoryLat output

				Set @sName = @sName + '(' + @sNameCategory + ')'
				Set @sNameLat = @sNameLat + '(' + @sNameCategoryLat + ')'
				Set @sTitle = 'Размещение'
				Set @sTitleLat = 'Accommodation'
			END
			
			SELECT @nHrMain = IsNull(HR_Main, 0), @nAgeFrom = IsNull(HR_AgeFrom, 0), @nAgeTo = IsNull(HR_AgeTo, 0), @sAcCode = IsNull(AC_Code, '') FROM dbo.HotelRooms, dbo.AccmdMenType WHERE (HR_Key = @nCode1) AND (HR_AcKey = AC_Key)
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
	ELSE
	BEGIN
		Set @sTmp = 'CODE1'
		EXEC dbo.GetSvListParm @nSvKey, @sTmp, @bTmp output
	
		IF @bTmp > 0
		BEGIN
			SET @sTitle = 'Доп.описание'
			SET @sName = 'Любое'
			SET @sTitleLat = 'Add.description'
			SET @sNameLat = 'Any'
			
			IF EXISTS( SELECT * FROM dbo.AddDescript1 WHERE A1_Key = @nCode1 )
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


	IF @nCode1 > 0 and ((@nSvKey = @TYPE_HOTEL) or (@nSvKey = @TYPE_HOTELADDSRV))
	BEGIN
		if @sAcCode is not null
			begin
				Set @sName = @sName + ',' + isnull(@sAcCode, '')
				Set @sNameLat = @sNameLat + ',' + isnull(@sAcCode, '')
			end
		SET @sTmp = isnull(CAST(@nAgeFrom as varchar(5)), '0') + '-' + isnull(cast(@nAgeTo as varchar(5)), '')
		If @nHrMain <= 0
		begin				
			SET @sName = @sName + ' доп(' + @sTmp + ')'
			SET @sNameLat = @sNameLat + ' ex(' + @sTmp + ')'
		END
		ELSE
			IF (@nAgeFrom > 0) or (@nAgeTo > 0)
			BEGIN
				SET @sName =  @sName + ' (' + @sTmp + ')'
				SET @sNameLat = @sNameLat + ' (' + @sTmp + ')'				
			END
	END
GO

grant execute on [dbo].[GetSvCode1Name] to public
GO

-- Data_UpdateQuotaObjects.sql
UPDATE dbo.QuotaObjects
SET QO_SubCode2 = -1
WHERE QO_SVKey = 1
AND QO_SubCode2 in (SELECT CT_Key FROM dbo.CityDictionary)
AND QO_SubCode2 not in (SELECT AS_Key FROM dbo.AirService)
GO

-- fn_mwGetFirstConfirmDogovorDate.sql
if exists(select id from sysobjects where xtype='fn' and name='fn_mwGetFirstConfirmDogovorDate')
	drop function dbo.fn_mwGetFirstConfirmDogovorDate
go

if exists(select id from sysobjects where xtype='fn' and name='mwGetFirstConfirmDogovorDate')
	drop function dbo.mwGetFirstConfirmDogovorDate
go

create function [dbo].[mwGetFirstConfirmDogovorDate](@dgKey int)
returns datetime
as
begin

	declare @historyTable table(date datetime, newvalue int);
	declare @currDate datetime, @result datetime

	insert into @historyTable(date, newvalue)
	select hi_date, hd_intvaluenew
	from historydetail 
	inner join history on hi_id = hd_hiid
	where hi_dgkey=@dgKey and hd_alias = 'DG_SOR_CODE'

	declare history_cursor cursor for
	select date
	from @historyTable
	where newvalue in (7, 21) -- статус Ок
	order by date

	set @result = null
	OPEN history_cursor

	FETCH NEXT FROM history_cursor 
	INTO @currDate
	 
	WHILE @@FETCH_STATUS = 0
	BEGIN
--		if not exists(select * from @historyTable where date between dateadd(second, 1, @currDate) and dateadd(second, 30, @currDate))	
		if not exists(select * from @historyTable where (date > @currDate) and (date < dateadd(second, 30, @currDate)))
		begin
			if @result is null set @result = @currDate
		end
		FETCH NEXT FROM history_cursor 
		INTO @currDate
	END

	CLOSE history_cursor
	DEALLOCATE history_cursor

	return @result
end
go

grant exec on dbo.mwGetFirstConfirmDogovorDate to public
go

-- sp_GetTableQuotaDetails.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetTableQuotaDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetTableQuotaDetails]
GO
CREATE procedure [dbo].[GetTableQuotaDetails]
(
--<VERSION>2008.1.02.02a</VERSION>
@DL_Key int =null,
@QT_ID int  =null,
@DateStart smalldatetime = null,
@DaysCount int  =null,
@QT_Type int  =null,
@QT_Release int  =null,
@DL_SVKey int  =null, 
@DL_Code int  =null, 
@DL_SubCode1 int  =null, 
@DL_PRKey int  =null,
@GroupByQD bit = null
)
AS
/*
возвращает таблицу со стопами по всем комбинациям услуг

есть 5 вариантов вызова
1. экран "Наличие мест на квоте" - @QT_ID, @DateStart, @DaysCount !!! до 2008.1.1 (после 2008.1.2 см.пункт 5 )
2. экран "Выбрать квоту (основной режим)" - @DL_Key, @DateStart, @DaysCount
3. функция проверки наличия мест [CheckQuotaExist] @QT_ID, @DateStart, @DaysCount, @DL_SVKey, @DL_Code, @DL_SubCode1, @DL_PRKey
4. из экрана Стоп по квоте @QT_ID, @DateStart, @DaysCount, @QT_Type
5. экран "Наличие мест на квоте" - @DateStart, @DaysCount, @DL_SVKey, @DL_Code, @GroupByQD !!! после 2008.1.2 (до 2008.1.1 см.пункт 1 ) 
*/
DECLARE @DateEnd smalldatetime
Set @DateEnd = DATEADD(DAY, @DaysCount-1, @DateStart)

DECLARE @QO_SubCode1 int, @QO_SubCode2 int
IF @DL_Key is not null --значит смотрим из конкретной услуги
	SELECT @DL_SVKey=DL_SVKey, @DL_Code=DL_Code, @DL_SubCode1=DL_SubCode1, @DL_PRKey=DL_PartnerKey FROM DogovorList WHERE DL_Key=@DL_Key
IF @DL_SVKey is not null and @DL_SubCode1 is not null
BEGIN
	SET @QO_SubCode2=0
	IF @DL_SVKey=3
		SELECT @QO_SubCode1=HR_RMKey, @QO_SubCode2=HR_RCKey FROM HotelRooms WHERE HR_Key=@DL_SubCode1
	ELSE
		SET @QO_SubCode1=@DL_SubCode1

	IF @DL_SVKey=1
		SET @QO_SubCode2 = -1
		--SELECT @QO_SubCode2=CH_CITYKEYFROM FROM Charter WHERE CH_KEY=@DL_Code
END

--проверка стопов
--начало
CREATE TABLE #StopSaleTemp_Local
(
SST_Code int,
SST_SubCode1 int,
SST_SubCode2 int,
SST_QOID int,
SST_PRKey int,
SST_Date smalldatetime,
SST_QDID int,
SST_Type smallint,
SST_State smallint,
SST_Comment varchar(255)
)

IF @DL_Key is not null --значит смотрим по конкретной услуги
BEGIN
	INSERT INTO #StopSaleTemp_Local (SST_Code,SST_SubCode1,SST_SubCode2,SST_QOID,SST_PRKey,SST_Date,SST_QDID,SST_Type)
		SELECT	QO_Code,QO_SubCode1,QO_SubCode2,QO_ID,QT_PRKey,QD_Date,QD_ID,QD_Type
		FROM	QuotaObjects,Quotas,QuotaDetails
		WHERE	QO_QTID=QT_ID and ((QT_ID=@QT_ID and @QT_ID is not null) or (@QT_ID is null)) and QD_QTID=QT_ID
				and QD_Date between @DateStart and @DateEnd
				and QO_SVKey=@DL_SVKey and QO_Code=@DL_Code and (QO_SubCode1=@QO_SubCode1 or QO_SubCode1=0)
				and (QO_SubCode2=@QO_SubCode2 or QO_SubCode2=0)
				and (QT_PRKey=@DL_PRKey or QT_PRKey=0)
END
ELSE IF @QT_ID is not null
BEGIN
	INSERT INTO #StopSaleTemp_Local (SST_Code,SST_SubCode1,SST_SubCode2,SST_QOID,SST_PRKey,SST_Date,SST_QDID,SST_Type)
		SELECT	QO_Code,QO_SubCode1,QO_SubCode2,QO_ID,QT_PRKey,QD_Date,QD_ID,QD_Type
		FROM	QuotaObjects,Quotas,QuotaDetails
		WHERE	QO_QTID=QT_ID and ((QT_ID=@QT_ID and @QT_ID is not null) or (@QT_ID is null)) and QD_QTID=QT_ID
				and QD_Date between @DateStart and @DateEnd
				and ((QO_SVKey=@DL_SVKey and @DL_SVKey is not null) or (@DL_SVKey is null))
				and ((QO_Code=@DL_Code and @DL_Code is not null) or (@DL_Code is null))
				and (((QO_SubCode1=0 or QO_SubCode1=@QO_SubCode1) and @QO_SubCode1 is not null) or (@QO_SubCode1 is null))
				and (((QO_SubCode2=0 or QO_SubCode2=@QO_SubCode2) and @QO_SubCode2 is not null) or (@QO_SubCode2 is null))
				and ((QD_Type=@QT_Type and @QT_Type is not null) or (@QT_Type is null))
				and ((ISNULL(QD_Release,0)=ISNULL(@QT_Release,0) and @QT_Type is not null) or (@QT_Type is null))	--специально смотрим @QT_Type, т.к. @QT_Release может прийти NULL
END
ELSE IF @QT_ID is null --экран "Наличие мест" (после 2008.1.2)
BEGIN
	INSERT INTO #StopSaleTemp_Local (SST_Code,SST_SubCode1,SST_SubCode2,SST_QOID,SST_PRKey,SST_Date,SST_QDID,SST_Type)
		SELECT	QO_Code,QO_SubCode1,QO_SubCode2,QO_ID,QT_PRKey,QD_Date,QD_ID,QD_Type
		FROM	QuotaObjects,Quotas,QuotaDetails
		WHERE	QO_QTID=QT_ID and QD_QTID=QT_ID
				and QD_Date between @DateStart and @DateEnd
				and QO_SVKey=@DL_SVKey and QO_Code=@DL_Code
END

if not exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSCheckQuotaRelease' and SS_ParmValue=1)
BEGIN
	IF @DL_Key is not null --значит по услуге, значит не надо смотреть в QuotaObjects, так как объекты уже отобраны
		Update #StopSaleTemp_Local Set SST_State=1, SST_Comment= (SELECT TOP 1 REPLACE(SS_Comment,'''','"') FROM StopSales,QuotaObjects WHERE SS_QOID=QO_ID and SS_QDID=SST_QDID and QO_Code=@DL_Code and SS_Date between @DateStart and @DateEnd and (SS_IsDeleted is null or SS_IsDeleted=0)
				and (QO_SubCode1=SST_SubCode1 or QO_SubCode1=0)	and (QO_SubCode2=SST_SubCode2 or QO_SubCode2=0))
			WHERE exists (SELECT SS_ID FROM StopSales,QuotaObjects WHERE SS_QOID=QO_ID and SS_QDID=SST_QDID and QO_Code=@DL_Code and SS_Date between @DateStart and @DateEnd and (SS_IsDeleted is null or SS_IsDeleted=0)
				and (QO_SubCode1=SST_SubCode1 or QO_SubCode1=0)	and (QO_SubCode2=SST_SubCode2 or QO_SubCode2=0))
	Else
		Update #StopSaleTemp_Local Set SST_State=1, SST_Comment= (SELECT TOP 1 REPLACE(SS_Comment,'''','"') FROM StopSales WHERE SS_QDID=SST_QDID and SS_QOID=SST_QOID and SS_Date between @DateStart and @DateEnd and (SS_IsDeleted is null or SS_IsDeleted=0))
			WHERE exists (SELECT SS_ID FROM StopSales WHERE SS_QDID=SST_QDID and SS_QOID=SST_QOID and SS_Date between @DateStart and @DateEnd and (SS_IsDeleted is null or SS_IsDeleted=0))
	Update #StopSaleTemp_Local Set SST_State=2, SST_Comment= 
		(
			SELECT TOP 1 REPLACE(SS_Comment,'''','"') FROM StopSales,QuotaObjects 
			WHERE	SS_QDID is null
					and SS_Date between @DateStart and @DateEnd
					and (SS_PRKey=SST_PRKey or SS_PRKey=0)					
					and SS_QOID = QO_ID
					and SS_Date=SST_Date
					and (QO_Code = SST_Code or QO_Code=0)
					and (QO_SubCode1 = SST_SubCode1 or QO_SubCode1 = 0 or SST_SubCode1 = 0)
					and (QO_SubCode2 = SST_SubCode2 or QO_SubCode2 = 0 or SST_SubCode2 = 0)
					and (SS_IsDeleted is null or SS_IsDeleted=0)
		)
		WHERE (
					exists ( SELECT SS_ID 
						FROM StopSales,QuotaObjects
						WHERE SS_QDID is null
						and SS_Date between @DateStart and @DateEnd
						and (SS_PRKey = SST_PRKey or SS_PRKey=0)
						and SS_QOID = QO_ID
						and SS_Date=SST_Date
						and (QO_Code = SST_Code or QO_Code=0)
						and (QO_SubCode1 = SST_SubCode1 or QO_SubCode1 = 0 or SST_SubCode1 = 0)
						and (QO_SubCode2 = SST_SubCode2 or QO_SubCode2 = 0 or SST_SubCode2 = 0)
						and (SS_IsDeleted is null or SS_IsDeleted=0)
					) and SST_Type=1
				)OR	--добавил для определения на что ставится стоп на Allotment или на AllotmentAndCommitment
					exists ( SELECT SS_ID 
						FROM StopSales,QuotaObjects 
						WHERE SS_QDID is null
						and SS_Date between @DateStart and @DateEnd
						and (SS_PRKey=SST_PRKey or SS_PRKey=0)						
						and SS_QOID = QO_ID						
						and SS_Date=SST_Date
						and (QO_Code=SST_Code or QO_Code=0)					
						and (QO_SubCode1 = SST_SubCode1 or QO_SubCode1 = 0 or SST_SubCode1 = 0)
						and (QO_SubCode2 = SST_SubCode2 or QO_SubCode2 = 0 or SST_SubCode2 = 0)
						and (SS_IsDeleted is null or SS_IsDeleted=0)
						and isnull(SS_AllotmentAndCommitment,0) = 1
					)
				
		
END
 --where sst_QDID=2602
--GO
--проверка стопов
--окончание
if @GroupByQD=1
	select	SST_QDID, Count(*) as SST_QO_Count, 
			(SELECT count(*) from #StopSaleTemp_Local s2 WHERE s2.SST_QDID=s1.SST_QDID and SST_State is not null) as SST_QO_CountWithStop,
			(SELECT TOP 1 SST_Comment FROM #StopSaleTemp_Local s3 WHERE s3.SST_QDID=s1.SST_QDID and SST_Comment is not null and SST_Comment != '') as SST_Comment
	from #StopSaleTemp_Local s1
	group by SST_QDID
	having (SELECT count(*) from #StopSaleTemp_Local s2 WHERE s2.SST_QDID=s1.SST_QDID and SST_State is not null)>0
else
	select * from #StopSaleTemp_Local
GO
GRANT EXECUTE ON [dbo].[GetTableQuotaDetails] TO PUBLIC 
GO

-- AlterTable_StopSales.sql
if not exists(select id from syscolumns where id = OBJECT_ID('StopSales') and name = 'SS_AllotmentAndCommitment')
	ALTER TABLE dbo.StopSales ADD SS_AllotmentAndCommitment [bit] NULL DEFAULT ((0))
go

-- 100709 create contacts.sql


IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactTypes]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[ContactTypes](
	[CT_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_ContactTypes] PRIMARY KEY CLUSTERED ,
	[CT_Name] [nvarchar](255) NOT NULL,
	[CT_Comment] [nvarchar](1024) NULL,
	[CT_Icon] [image] NULL
)
GO
GRANT select, update, insert, delete on [dbo].[ContactTypes] to public
GO

IF not EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactTypeFields]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[ContactTypeFields](
	[CTF_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_ContactTypeFields] PRIMARY KEY CLUSTERED ,
	[CTF_Name] [nvarchar](255) NOT NULL,
	[CTF_Comment] [nvarchar](1024) NULL,
	[CTF_CTID] int NOT NULL CONSTRAINT [FK_ContactTypeFields_ContactTypes] 
	REFERENCES [dbo].[ContactTypes]([CT_Id]) ON DELETE CASCADE
)
GO
GRANT select, update, insert, delete on [dbo].[ContactTypeFields] to public
GO

IF not EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[Contacts]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[Contacts](
	[CC_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED ,
	[CC_CTID] int NOT NULL CONSTRAINT [FK_Contacts_ContactTypes] 
	REFERENCES [dbo].[ContactTypes]([CT_Id]) ON DELETE CASCADE
)
GO
GRANT select, update, insert, delete on [dbo].[Contacts] to public
GO

IF not EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactFields]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[ContactFields](
	[CF_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_ContactFields] PRIMARY KEY CLUSTERED ,
	[CF_CCID] int NOT NULL CONSTRAINT [FK_ContactFields_Contacts] 
	REFERENCES [dbo].[Contacts]([CC_Id]) ON DELETE CASCADE,
	[CF_CTFValue] [nvarchar](1024) NULL,
	[CF_CTFID] int NOT NULL CONSTRAINT [FK_ContactFields_ContactTypeFields] 
	REFERENCES [dbo].[ContactTypeFields]([CTF_Id]) ON DELETE NO ACTION
)
GO
GRANT select, update, insert, delete on [dbo].[ContactFields] to public
GO

IF not EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactLinks]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[ContactLinks](
	[CL_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_ContactLinks] PRIMARY KEY CLUSTERED ,
	[CL_CCID] int NOT NULL CONSTRAINT [FK_ContactLinks_Contacts] 
	REFERENCES [dbo].[Contacts]([CC_Id]) ON DELETE CASCADE,
	[CL_TUKey] int NOT NULL CONSTRAINT [FK_ContactLinks_TBL_TURIST] 
	REFERENCES [dbo].[TBL_TURIST]([TU_Key]) ON DELETE CASCADE
)
GO
GRANT select, update, insert, delete on [dbo].[ContactLinks] to public
GO


-- sp_InsDogovor.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InsDogovor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure dbo.InsDogovor
GO
CREATE procedure [dbo].[InsDogovor]
(
--<VERSION>2005.2.38</VERSION>
@nReturn int output,
@nKeyDogovor int output,				-- возвращает ключ созданного договора
@sDogovor varchar (10) = null,			-- номер путевки, которую требуется создать
@dTour datetime = null,					-- дата заезда
@nDays int = null,						-- количество дней поездки
@nTour int = null,						-- ключ тура (TurList)
@nCountry int = null,					-- ключ страны (Country) 
@nCity int = null,						-- ключ города (CityDictionary)
@nMen smallint = null,					-- количество человек в путевке
@sRate varchar (3) = null,				-- код валюты путевки
@nPrice money = null,					-- стоимость (к оплате)
@nPayed money = null,					-- оплачено по путевке (МТ передает "0")
@nDiscount money = null,				-- размер скидки(комиссии) номинальный
@nDiscountKey int = null,				-- ключ скидки(комиссии)
@nPcnt smallint = null,					-- скидка в процентах (1-да, 0-нет)
@nDiscountSum money = null,				-- величина скидки (комиссии) в у.е.
@nCauseDiscount int = null,				-- ключ причины скидки (CauseDiscount)
@nAgent int = null,						-- ключ покупателя (Partners)
@nOper int = null,						-- ключ менеджера создавшего путевку (UserList)
@sOper varchar (25) = null,				-- имя менеджера создавшего путевку
@sMainMen varchar (45) = null,			-- контактное лицо. ФИО (лицо, заключившее договор)
@sMainMenPhone varchar (30) = null,		-- контактное лицо. телефон
@sMainMenAdress varchar (320) = null,	-- контактное лицо. адрес
@sMainMenPasport varchar (70) = null,	-- контактное лицо. паспорт
@nOwner int = null,						-- ключ ведущего менеджера по путевке (UserList)
@nStatus int = null,					-- статус по умолчанию (OrderStatus)  		- МТ передает 1 (не определен)
@nPrintVaucher smallint = null,			-- признак путевки. ваучер распечатан		- МТ передает 0 (не распечатан)
@nPrintDogovor smallint = null,			-- признак путевки. путевка распечатана	 	- МТ передает 0 (не распечатан)
@nAdvertiseKey int = null,				-- ключ справочника источник рекламы (Advertisment) 
@nLocked smallint = null,				-- признак путевки. путевка заблокирована 	- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@dVisaDate datetime = null,				-- дата сдачи документов для визы 		- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@dPaymentDate datetime = null,			-- дата полной оплаты 				- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@dPPaymentDate datetime = null,			-- дата предоплаты				- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@nRazmerPPayment int = null,			-- размер предоплаты 				- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@nPercentPPayment int = null,			-- предоплата в % (1-да, 0-нет)			- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@sDocument varchar (250) = null,		-- принятые документы (текстовое поле)		- МТ НЕ ПЕРЕДАЕТ !!!!!!!!!!!!!
@nLeadDepartmentKey int = null,			-- ключ ведущего отдела (PrtDeps)	

@sMainMenEMail varchar (250) = null,	-- контактное лицо. e-mail
@sMainMenComment varchar (250) = null,	-- контактное лицо. комментарий
@nDupUserKey int = null,				-- менеджер покупателя (Dup_User)
@nBookingTypeKey int = null,			-- система бронирования (0-МТ, 1-MW) 		- МТ передает 0

@nPartnerDogovorKey int = null,			-- ключ договора партнера
@nCityDepartureKey int = null,			-- ключ города вылета
@nFilialKey int = null,					-- ключ филиала, к которому будет привязана путевка (если Null, то получит филиал ведущего менеджера)
@sOldDogovor varchar (10) = null		-- не использовать для переименования используйте ХП RenameDogovor
)
as
declare @nCount int
declare @sKeyTable varchar (11)
declare @sMode varchar (3)
declare @sText varchar (80)
declare @sValue varchar(254)
declare @dtCurrentDate DateTime
declare @sOperID varchar(255)
declare @nOperLeadDepartmentKey int
declare @sOperLat varchar(25)
declare @nDatePayed_Local int
declare @nDefaultProcent int
declare @nAgentDogovorGlobalType int
declare @nOperLeadFilialKey int

set @sDocument = RTRIM(LTRIM(@sDocument))
Select @nCount = count(*) from Dogovor where DG_Code=@sDogovor
if @nCount > 0
BEGIN
	set @nReturn = 1
	return 0
END

if @nKeyDogovor > 0 and @sOldDogovor != ''
BEGIN
	set @sMode = 'REN'
	Select @nFilialKey = DG_FilialKey from Dogovor where DG_Code = @sOldDogovor
END 
ELSE BEGIN
	set @sMode = 'BEG'
	IF (@nKeyDogovor <= 0 or @nKeyDogovor is null)
	BEGIN
		set @nKeyDogovor = 0
		set @sKeyTable = 'KEY_DOGOVOR'
		exec dbo.GETNEWKEY @sKeyTable, @nKeyDogovor output
	END

	IF @nKeyDogovor > 0
		set @nReturn = 0
	ELSE BEGIN
		set @nReturn = 1
		return 0
	END
END

if @nBookingTypeKey=1
BEGIN
	if (ISNULL(@nCityDepartureKey,0)=0) and (@nTour > 0)
		Select @nCityDepartureKey=TL_CTDepartureKey from TurList where TL_Key=@nTour
	if (ISNULL(@nPartnerDogovorKey,0)=0) and @nAgent>0
		Select top 1 @nPartnerDogovorKey=PD_Key from PrtDogs where PD_Key > 0 AND PD_PRKEY = @nAgent AND 
			(PD_DateBeg <= GetDate() OR PD_DateBeg is null) AND ((PD_DateEnd+1) >= GetDate() OR PD_DateEnd is null)
			ORDER BY PD_IsDefault DESC, PD_UpdDate DESC
END
set @nPartnerDogovorKey = ISNULL(@nPartnerDogovorKey,0)

If @sMode = 'BEG'
BEGIN
	Select @dtCurrentDate = GETDATE()
	SET @sRate = LTRIM(RTRIM(@sRate) )

	Exec dbo.GetUserKey @nOper output	
	Exec dbo.GetUserInfo @sOperID output, @nOper output, @sOper output, @nOperLeadFilialKey output, @nOperLeadDepartmentKey output, @sOperLat output
	If @nFilialKey is null or @nFilialKey = 0
		Set @nFilialKey = @nOperLeadFilialKey
	SET @sOper = LTRIM(RTRIM(@sOper) )
	SET @sMainMen = LTRIM(RTRIM(@sMainMen) )
	SET @sMainMenPhone = LTRIM(RTRIM(@sMainMenPhone) )
	SET @sMainMenAdress = LTRIM(RTRIM(@sMainMenAdress) )
	SET @sMainMenPasport = LTRIM(RTRIM(@sMainMenPasport) )
	SET @sMainMenEMail = LTRIM(RTRIM(@sMainMenEMail) )
	SET @sMainMenComment = LTRIM(RTRIM(@sMainMenComment) )

	If (@dPaymentDate is NULL or @nRazmerPPayment is NULL) and @nTour > 0
	BEGIN
		SELECT 	@nDatePayed_Local = TL_DatePayed, 
			@nDefaultProcent = TL_DfltPaymentPcnt
		FROM	TurList 
		WHERE	TL_Key=@nTour
	
		if @dPaymentDate is NULL
		begin
			if (GETDATE() + @nDatePayed_Local) >= @dTour
			begin
				Set @dPaymentDate = CONVERT(CHAR(10), @dTour - 1, 102)
			end
			else
			begin
				Set @dPaymentDate = CONVERT(CHAR(10), GETDATE() + @nDatePayed_Local, 102)
			end
		end

		If @nRazmerPPayment is NULL
		BEGIN
			Set @nRazmerPPayment = @nDefaultProcent
			Set @nPercentPPayment = 1
		END
	END	

	declare @da_key int
	if @nDiscountKey is not null and @nDiscountKey <> 0 and @nDiscountKey <> -1
	begin
		set @da_key = null
		select @da_key = DS_DAKey from Discounts where DS_Key = @nDiscountKey
	end

	SELECT	@nAgentDogovorGlobalType = PDT_Type FROM dbo.PrtDogs, dbo.PrtDogTypes WHERE PD_Key = @nPartnerDogovorKey and PD_DogType = PDT_ID

	Insert into dbo.tbl_Dogovor (DG_Key,DG_Code,DG_TurDate,DG_CnKey,DG_CtKey,
			DG_NMen,DG_Rate,DG_Price,DG_NDay,DG_PartnerKey,
			DG_PrtDogKey,DG_Operator,DG_Payed,DG_MainMen,DG_MainMenPhone,
			DG_MainMenAdress,DG_MainMenPasport,DG_Discount,DG_TypeCount,DG_DiscountSum,
			DG_CauseDisc,DG_TrKey,DG_PrintDogovor,DG_PrintVaucher,DG_Owner,
			DG_Creator,DG_CrDate,DG_sor_code,DG_ADVERTISE,DG_LOCKED,
			DG_VISADATE,DG_PAYMENTDATE,DG_PPAYMENTDATE,DG_RAZMERP,DG_PROCENT,
			DG_DOCUMENT,DG_FilialKey, DG_LeadDepartment, DG_MainMenComment, DG_MAINMENEMAIL, 
			DG_DupUserKey, DG_BTKey, DG_CTDepartureKey, DG_PDTType, DG_DAKey)
	Values (@nKeyDogovor, @sDogovor, @dTour, @nCountry, @nCity, 
			@nMen, @sRate, @nPrice, @nDays,	@nAgent, 
			@nPartnerDogovorKey, @sOper, @nPayed, @sMainMen, @sMainMenPhone, 
			@sMainMenAdress, @sMainMenPasport,@nDiscount, @nPcnt, @nDiscountSum, 
			@nCauseDiscount, @nTour, @nPrintDogovor, @nPrintVaucher, @nOwner, 
			@nOper,	@dtCurrentDate, @nStatus, @nAdvertiseKey, @nLocked, 
			@dVisaDate, @dPaymentDate, @dPPaymentDate, @nRazmerPPayment, @nPercentPPayment, 
			@sDocument, @nFilialKey, @nLeadDepartmentKey, @sMainMenComment, @sMainMenEMail, 
			@nDupUserKey, @nBookingTypeKey, @nCityDepartureKey, @nAgentDogovorGlobalType, @da_key)


	-- Begin Donskov 17.03.2009

	-- находим национальную валюту
	declare @national_currency varchar(5)
	select top 1 @national_currency = RA_CODE from Rates where RA_National = 1

	declare @rc_course money
	declare @rc_courseStr char(30)


	if rtrim(ltrim(@national_currency)) <> rtrim(ltrim(@sRate))
	begin
		-- проверяем, есть ли курс валюты в базе
		set @rc_course = -1
		select top 1 @rc_courseStr = RC_COURSE from RealCourses
		where
		RC_RCOD1 = @national_currency and RC_RCOD2 = @sRate
		and convert(char(10), RC_DATEBEG, 102) = convert(char(10), getdate(), 102)
		set @rc_course = cast(isnull(@rc_courseStr, -1) as money)
	end
	else
	begin
		set @rc_course = 1
		set @rc_courseStr = '1'
	end

	declare @sHI_WHO varchar(25)
	exec dbo.CurrentUser @sHI_WHO output

	-- 1) пишем в хистори курс валюты
    -- 2) в созданную путёвку записываем стоимость в национальной валюте и скидку в национальной валюте
	--    (если присутствует соответствующий курс в базе)
	if @rc_course <> -1
	begin
		-- 1: пишем в хистори
		if (select count(*) from dbo.history where HI_DGCOD = @sDogovor and HI_MOD = 'INS' and HI_TYPE = 'DOGOVORCURRENCY' and HI_OAId = 20) > 0
		begin
			delete from dbo.history where HI_DGCOD = @sDogovor and HI_MOD = 'INS' and HI_TYPE = 'DOGOVORCURRENCY' and HI_OAId = 20
		end

		insert into dbo.history
		(HI_DGCOD, HI_WHO, HI_TEXT, HI_REMARK, HI_MOD, HI_TYPE, HI_OAId)
		values
		(@sDogovor, @sHI_WHO, @rc_courseStr, @sRate, 'INS', 'DOGOVORCURRENCY', 20)

		-- 2: в созданную путёвку записываем стоимость и скидку в национальной валюте 
		update dbo.tbl_Dogovor
		set
			DG_NATIONALCURRENCYPRICE = @rc_course * @nPrice,
			DG_NATIONALCURRENCYDISCOUNTSUM = @rc_course * @nDiscountSum
		where
			DG_Key = @nKeyDogovor
	end
	else
	begin
		insert into dbo.history
		(HI_DGCOD, HI_WHO, HI_TEXT, HI_REMARK, HI_MOD, HI_TYPE, HI_OAId)
		values
		(@sDogovor, @sHI_WHO, 'Курс отсутствует', @sRate, 'INS', 'DOGOVORCURRENCYISNULL', 21)
	end
	-- End Donskov 17.03.2009

	--пишем ключ акции в историю
		if @da_key is not null
		begin
			if (select count(*) from dbo.history where HI_DGCOD = @sDogovor and HI_OAId = 25) > 0
			begin
				delete from dbo.history where HI_DGCOD = @sDogovor and HI_OAId = 25
			end

			insert into dbo.history
			(HI_DGCOD, HI_WHO, HI_TEXT, HI_REMARK, HI_MOD, HI_TYPE, HI_OAId)
			values
			(@sDogovor, @sHI_WHO, cast(@da_key as varchar), 'Ключ акции', 'INS', 'DA_KEY', 25)
		end


	if @@error = 0
		set @nReturn = 0
	else
		set @nReturn = 2

	set @sText = N'Создание путевки'
	--EXEC dbo.InsertHistory @sDogovor, '', @sMode, @sText, ''

	Update Partners set PR_DateLastContact = GETDATE() WHERE PR_Key = @nAgent
	Select @sValue = SS_ParmValue from dbo.SystemSettings where SS_ParmName = 'SYSUseTimeLimit'
	if @sValue = '1'
		exec dbo.CreatePPaymentDate @sDogovor, @dTour, @dtCurrentDate

	exec InsMasterEvent 1, @nKeyDogovor
END
Else if @sMode = 'REN'
BEGIN
	/*
	set @sText = N'Переименование путевки с'+@sOldDogovor+' на '+@sDogovor
	set @sMode = 'REN'
	EXEC dbo.InsertHistory @sDogovor, '', @sMode, @sText, ''
	*/
	Update Dogovorlist set DL_DgCod = @sDogovor where DL_Dgcod = @sOldDogovor
	Update tbl_Turist set TU_DgCod = @sDogovor where TU_Dgcod = @sOldDogovor
	Update History set HI_DgCod = @sDogovor where HI_Dgcod = @sOldDogovor
	Update PrintDocuments set DC_DgCod = @sDogovor where DC_DgCod = @sOldDogovor
	Update SendMail set SM_DgCode = @sDogovor where SM_DgCode = @sOldDogovor
	Update BillsDogovor set BD_DgCod = @sDogovor where BD_DgCod = @sOldDogovor
	Update Accounts set AC_DgCod=@sDogovor where AC_DgCod=@sOldDogovor
	
	if exists(select st_version from setting where st_version like '5.2%')
	begin
		Update Orders set OR_Dogovor = @sDogovor where OR_Dogovor = @sOldDogovor
		Update OrderHistory set OH_DgCod = @sDogovor where OH_DgCod = @sOldDogovor
	end

	Update Dogovor set DG_Code = @sDogovor where DG_Code = @sOldDogovor
	if @@error = 0
		set @nReturn = 0
END
return 0
GO

GRANT EXECUTE ON dbo.InsDogovor TO PUBLIC 
GO

-- Data_Delete_UserSettings.sql
DELETE UserSettings
WHERE ST_ParmName in ('VisaTouristForm.visaTouristServicesGrid', 'DogovorMainForm.visaTouristServicesGrid')
GO

-- 100803 update systemsettings.sql
IF NOT EXISTS(SELECT * FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSReservationNCRate')
BEGIN
	DECLARE @value INT 
	SET @value = 0
	DECLARE @Currency int
	SELECT @Currency = CAST(SS_PARMVALUE AS INT) FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSRateFixOnCurrency'
	IF @Currency = 1
	BEGIN
		DECLARE @CurrencyChanged int	
		SELECT @CurrencyChanged = CAST(SS_PARMVALUE AS INT) FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSPrtRegQuestion'
		 --2 по старому остальные по новому
		IF(@CurrencyChanged = 2)
			SET @value = @value|2
		ELSE
			SET @value = @value|4
	END
	SELECT @value = @value|8 FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSRateFixOnPrice' AND SS_PARMVALUE = '1'
	SELECT @value = @value|16 FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSRateFixOnDiscount' AND SS_PARMVALUE = '1'
	SELECT @value = @value|32 FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSRateFixOnStatus' AND SS_PARMVALUE = '1'
	
	INSERT INTO dbo.SystemSettings(SS_PARMNAME, SS_PARMVALUE)
	VALUES('SYSReservationNCRate', @value)
	
	DELETE FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSRateFixOnCurrency'
	DELETE FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSPrtRegQuestion'
	DELETE FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSRateFixOnPrice'
	DELETE FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSRateFixOnDiscount'
	DELETE FROM dbo.SystemSettings WHERE SS_PARMNAME LIKE 'SYSRateFixOnStatus'
END
GO

-- fn_ParseKeys.sql
if exists(select id from sysobjects where xtype = 'TF' and name='ParseKeys')
	drop function dbo.ParseKeys
go

CREATE function [dbo].[ParseKeys](@data as varchar(max)) 
	returns @keys table(xt_key int)
begin
	if(@data is null)
		return
            
	declare @start int, @end int, @tmp int, @tmpKey varchar(max)
    set @start = 0
    set @end = charindex(',', @data, @start)
	
    while(@end > 0)
    begin
		select @tmpKey = substring(@data, @start, @end - @start)
		set @tmp = CONVERT(int, RTRIM(LTRIM(@tmpKey)), 0)
		insert into @keys(xt_key) values(@tmp)
		
		set @start = @end + 1
		set @end = charindex(',', @data, @start)
	end
	
	select @tmpKey = substring(@data, @start, LEN(@data) - @start + 1)
	set @tmp = CONVERT(int, RTRIM(LTRIM(@tmpKey)), 0)
	insert into @keys(xt_key) values(@tmp)

	return
end
GO

grant select on [dbo].[ParseKeys] to public
GO

-- sp_GetQuotaLoadListData_N.sql
if exists(select id from sysobjects where xtype = 'p' and name='GetQuotaLoadListData_N')
	drop procedure [dbo].[GetQuotaLoadListData_N]
go
/****** Объект:  StoredProcedure [dbo].[GetQuotaLoadListData_N]    Дата сценария: 08/10/2010 17:28:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[GetQuotaLoadListData_N]
(
--<VERSION>2008.1.01.20a</VERSION>
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
@bShowByCheckIn bit =null
)
as 

DECLARE @DateEnd smalldatetime, @Service_PRKey int, @QT_IDLocal int, @Result_From smallint, @Result_To smallint, @ServiceLong smallint, @DurationLocal smallint, @ByRoom int
--@Result
--11 - общее кол-во мест (строка 8000)
--12 - кол-во свободных мест (строка 8000)
--13 - кол-во занятых мест (строка 8000)
--21 - кол-во свободных мест (smallint)
--22 - % Stop-Sale (smallint)
--23 - возможен ли заезд (smallint)
if (@ResultType is null) or (@ResultType <> 10)
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

CREATE TABLE #QuotaLoadList(
QL_QTID int, QL_PRKey int, QL_SubCode1 int, QL_PartnerName nvarchar(100) collate Cyrillic_General_CI_AS, QL_Description nvarchar(255) collate Cyrillic_General_CI_AS, 
QL_dataType smallint, QL_Type smallint, QL_Release int, QL_Durations nvarchar(20) collate Cyrillic_General_CI_AS, QL_FilialKey int, 
QL_CityDepartments int, QL_AgentKey int, QL_CustomerInfo nvarchar(150) collate Cyrillic_General_CI_AS, QL_DateCheckinMin smalldatetime,
QL_ByRoom int)

--CREATE CLUSTERED INDEX X_QuotaLoadList
--ON #QuotaLoadList(QL_QTID ASC)

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
		set @str = 'ALTER TABLE #QuotaLoadList ADD QL_' + CAST(@n as varchar(3)) + ' smallint'
		exec (@str)
		set @n = @n + 1
	END
END


if @bShowCommonInfo = 1
BEGIN
	DECLARE @TempTable TABLE
	(
		QL_QTID int, QL_Type smallint, QL_Release int, QL_DateCheckinMin smalldatetime, QL_PRKey int, QL_ByRoom int
	)
		
	insert into @TempTable (QL_QTID, QL_Type, QL_Release, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	select QT_ID, QD_Type, QD_Release, /*NU_ID,*/ @DateEnd+1, QT_PRKey, QT_ByRoom
	from Quotas (nolock), QuotaObjects (nolock), QuotaDetails (nolock)
	where QT_ID=QO_QTID and QD_QTID=QT_ID
			and ((QO_Code=@Service_Code 
					and QO_SVKey=@Service_SVKey 
					and QO_QTID is not null
					and @QT_ID is null)
				or (@QT_ID is not null 
					and @QT_ID=QT_ID))
			and ISNULL(QD_IsDeleted,0)=0
			and QD_Date between @DateStart and @DateEnd
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0)

	insert into #QuotaLoadList (QL_QTID, QL_Type, QL_Release, QL_dataType, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	SELECT DISTINCT QL_QTID, QL_Type, QL_Release, NU_ID, QL_DateCheckinMin, QL_PRKey, QL_ByRoom
	FROM @TempTable nolock, Numbers (nolock)
	WHERE NU_ID between 1 and 3

END
else
BEGIN
	DECLARE @Service_SubCode1 int, @Object_SubCode1 int, @Object_SubCode2 int, @Service_SubCode2 int
	SET @Object_SubCode1=0
	SET @Object_SubCode2=0
	IF @DLKey is not null				-- если мы запустили процедуру из конкрентной услуги
	BEGIN
		SELECT	@Service_SVKey=DL_SVKey, @Service_Code=DL_Code, @Service_SubCode1=DL_SubCode1
			  , @AgentKey=ISNULL(DL_Agent,0), @Service_PRKey=DL_PartnerKey, @Service_SubCode2 = DL_SubCode2
		FROM	DogovorList (nolock)
		WHERE	DL_Key=@DLKey
		If @Service_SVKey=3
			SELECT @Object_SubCode1=HR_RMKey, @Object_SubCode2=HR_RCKey 
			FROM dbo.HotelRooms (nolock) WHERE HR_Key=@Service_SubCode1
		Else
			SET @Object_SubCode1=@Service_SubCode1
		IF @Service_SVKey=1
			SET @Object_SubCode2=@Service_SubCode2
	END

if (@ResultType is null) or (@ResultType <> 10)
BEGIN
	Set @Result_From=11
	Set @Result_To=13
END
ELSE
BEGIN
	--для наличия мест(из оформления)
	Set @Result_From=21
	Set @Result_To=23
END	
	-- чтобы ускорить инсерт добавим временную таблицу
	DECLARE @TempTable2 TABLE
	(
		QL_QTID int,
		QL_Type smallint,
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
	
	insert into @TempTable2 (QL_QTID, QL_Type, QL_Release, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	select QT_ID, QD_Type, QD_Release, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, '', @DateEnd + 1, QT_PRKey,QT_ByRoom
	from	Quotas (nolock), QuotaObjects (nolock), QuotaDetails (nolock), QuotaParts (nolock)
	where	QT_ID=QO_QTID
			and QD_QTID=QT_ID
			and QP_QDID = QD_ID
			and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) and QD_Date between @DateStart and @DateEnd
			and (QP_AgentKey is null or (@bShowAgencyInfo=1 and ((@AgentKey=QP_AgentKey) or (@AgentKey is null))))
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey=QT_PRKey or QT_PRKey=0)))
			and (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select QL_QPID From QuotaLimitations (nolock) WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID))))
			and ISNULL(QP_IsDeleted,0)=0
			and ISNULL(QD_IsDeleted,0)=0			
			and (@DLKey is null or (@DLKey is not null and QO_SubCode1 in (0,@Object_SubCode1) and QO_SubCode2 in (0,@Object_SubCode2)))

	insert into #QuotaLoadList (QL_QTID, QL_Type, QL_Release, QL_dataType, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	SELECT DISTINCT QL_QTID, QL_Type, QL_Release, NU_ID, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom
	FROM @TempTable2 nolock, Numbers (nolock)
	WHERE NU_ID between @Result_From and @Result_To
END

--update #QuotaLoadList set QL_CustomerInfo = (Select PR_Name from Partners where PR_Key = QL_FilialKey and QL_FilialKey > 0)

DECLARE @QD_ID int, @Date smalldatetime, @State smallint, @QD_Release int, @QP_Durations varchar(20), @QP_FilialKey int,
		@QP_CityDepartments int, @QP_AgentKey int, @Quota_Places int, @Quota_Busy int, @QP_IsNotCheckIn bit,
		@QD_QTID int, @QP_ID int, @Quota_Comment varchar(8000), @Stop_Comment varchar(255) --,	@QT_ID int
DECLARE @ColumnName varchar(10), @QueryUpdate varchar(8000), @QueryUpdate1 varchar(255), @QueryWhere1 varchar(255), @QueryWhere2 varchar(255), 
		@QD_PrevID int, @StopSale_Percent int, @CheckInPlaces smallint, @CheckInPlacesBusy smallint --@QuotaObjects_Count int, 

if @bShowCommonInfo = 1
	DECLARE curQLoadList CURSOR FOR SELECT
			QT_ID, QD_ID, QD_Date, QD_Type, QD_Release,
			QD_Places, QD_Busy,
			0,'',0,0,0,0, ISNULL(REPLACE(QD_Comment,'''','"'),''),0,0
	FROM	Quotas, QuotaObjects, QuotaDetails
	WHERE	QT_ID=QO_QTID and QD_QTID=QT_ID
			and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) and QD_Date between @DateStart and @DateEnd
			and (QD_IsDeleted = 0 or QD_IsDeleted is null)
	ORDER BY QD_Date DESC, QD_ID
else
	DECLARE curQLoadList CURSOR FOR SELECT
			QT_ID, QD_ID, QD_Date, QD_Type, QD_Release,			
			QP_Places, QP_Busy,
			QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, ISNULL(QP_IsNotCheckIn,0), 
			ISNULL(REPLACE(QD_Comment,'''','"'),'') + '' + ISNULL(REPLACE(QP_Comment,'''','"'),''), QP_CheckInPlaces, QP_CheckInPlacesBusy
	FROM	Quotas, QuotaObjects, QuotaDetails,QuotaParts
	WHERE	QT_ID=QO_QTID and QD_QTID=QT_ID and QP_QDID = QD_ID			
			and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) and QD_Date between @DateStart and @DateEnd
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
									@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, @QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy
SET @QD_PrevID = @QD_ID - 1

--SELECT @QuotaObjects_Count = count(*) from QuotaObjects, Quotas where QO_QTID = QT_ID and QT_ID = @QT_ID

SET @StopSale_Percent=0
WHILE @@FETCH_STATUS = 0
BEGIN
	set @QueryUpdate1=''
	if DATEADD(DAY,ISNULL(@QD_Release,0),GetDate()) < @Date
		set @QueryUpdate1=', QL_DateCheckInMin=''' + CAST(@Date as varchar(250)) + ''''
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
		if @QP_Durations is null
			set @QueryWhere2 = @QueryWhere2 + ' and QL_Durations is null' 
		else
			set @QueryWhere2 = @QueryWhere2 + ' and QL_Durations = ''' + @QP_Durations + ''''
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
		-- находим услуга на продолжение или нет
		DECLARE @SV_isDurations bit
		set @SV_isDurations = ISNULL((select SV_IsDuration from [Service] where SV_KEY = @Service_SVKey), 0)
		
		IF @ResultType is null or @ResultType not in (10)
		BEGIN
			IF @bShowByCheckIn = 1 and @QP_Durations <> '' 
			set @QueryUpdate = 'UPDATE #QuotaLoadList SET	
					QL_' + @ColumnName + ' = (CASE QL_dataType WHEN 11 THEN ''' + 
					CASE @SV_isDurations WHEN 1 THEN CONVERT(varchar(10), ISNULL(@Quota_Places,0)) ELSE CONVERT(varchar(10), ISNULL(@CheckInPlaces,0)) END + ''' WHEN 12 THEN ''' +
					CASE @SV_isDurations WHEN 1 THEN CONVERT(varchar(10), ISNULL(@Quota_Places-@Quota_Busy,0)) ELSE CONVERT(varchar(10), ISNULL(@CheckInPlaces-@CheckInPlacesBusy,0)) END + ''' WHEN 13 THEN ''' +
					CASE @SV_isDurations WHEN 1 THEN CONVERT(varchar(10), ISNULL(@Quota_Busy,0)) ELSE CONVERT(varchar(10), ISNULL(@CheckInPlacesBusy,0)) END + ''' END)+' + ''';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(@Quota_Comment as varchar(7900)) + ''''
				+ @QueryUpdate1
				+ @QueryWhere1 + @QueryWhere2 + ' and QL_dataType in (11,12,13) and QL_QTID=' + CAST(@QT_IDLocal as varchar(10))
			ELSE
			set @QueryUpdate = 'UPDATE #QuotaLoadList SET	
					QL_' + @ColumnName + ' = (CASE QL_dataType WHEN 11 THEN ''' + CAST((@Quota_Places) as varchar(10)) + ''' WHEN 12 THEN ''' + CAST((@Quota_Places-@Quota_Busy) as varchar(10)) + ''' WHEN 13 THEN ''' + CAST((@Quota_Busy) as varchar(10)) + ''' END)+' + ''';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(@Quota_Comment as varchar(7900)) + ''''
				+ @QueryUpdate1
				+ @QueryWhere1 + @QueryWhere2 + ' and QL_dataType in (11,12,13) and QL_QTID=' + CAST(@QT_IDLocal as varchar(10))
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
										@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, @QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy
END
CLOSE curQLoadList
DEALLOCATE curQLoadList

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

update #QuotaLoadList set QL_CustomerInfo = (Select PR_Name from Partners (nolock) where PR_Key = QL_AgentKey and QL_AgentKey > 0)
update #QuotaLoadList set QL_PartnerName = (Select PR_Name from Partners (nolock) where PR_Key = QL_PRKey and QL_PRKey > 0)
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

DECLARE @QO_SubCode int, @QO_TypeD smallint, @DL_SubCode1 int, @QT_ID_Prev int, @ServiceName1 varchar(100), @ServiceName2 varchar(100), @Temp varchar(100)
DECLARE curQLoadListQO CURSOR FOR 
	SELECT QO_QTID, QO_SubCode1, 1, null FROM QuotaObjects (nolock) WHERE QO_QTID in (SELECT QL_QTID FROM #QuotaLoadList (nolock) WHERE QO_QTID is not null)
	UNION
	SELECT QO_QTID, QO_SubCode2, 2, null FROM QuotaObjects (nolock) WHERE QO_QTID in (SELECT QL_QTID FROM #QuotaLoadList (nolock) WHERE QO_QTID is not null)
	UNION
	SELECT null, null, null, QL_SubCode1 FROM #QuotaLoadList (nolock) WHERE QL_SubCode1 is not null
	ORDER BY 1,3

OPEN curQLoadListQO
FETCH NEXT FROM curQLoadListQO INTO	@QT_IDLocal, @QO_SubCode, @QO_TypeD, @DL_SubCode1
Set @QT_ID_Prev=@QT_IDLocal
Set @ServiceName1=''
Set @ServiceName2=''


WHILE @@FETCH_STATUS = 0
BEGIN
	if @DL_SubCode1 is not null
	BEGIN
		Set @Temp=''
		exec GetSvCode1Name @Service_SVKey, @DL_SubCode1, null, @Temp output, null, null

		Update #QuotaLoadList set QL_Description=ISNULL(QL_Description,'') + @Temp where QL_SubCode1=@DL_SubCode1
	END
	Else
	BEGIN
		If @QT_ID_Prev != @QT_IDLocal
		BEGIN
			If @Service_SVKey=3
			BEGIN
				Set @ServiceName2='(' + @ServiceName2 + ')'
			END
			Update #QuotaLoadList set QL_Description=LEFT(ISNULL(QL_Description,'') + @ServiceName1 + @ServiceName2,255) where QL_QTID=@QT_ID_Prev
			Set @ServiceName1=''
			Set @ServiceName2=''
		END
		SET @QT_ID_Prev=@QT_IDLocal
		Set @Temp=''
		If @Service_SVKey=3
		BEGIN
			IF @QO_TypeD=1
			BEGIN
				EXEC GetRoomName @QO_SubCode, @Temp output, null
				If @ServiceName1!=''
					Set @ServiceName1=@ServiceName1+','
				Set @ServiceName1=@ServiceName1+@Temp
			END			
			Set @Temp=''
			IF @QO_TypeD=2
			BEGIN
				EXEC GetRoomCtgrName @QO_SubCode, @Temp output, null
				If @ServiceName2!=''
					Set @ServiceName2=@ServiceName2+','
				Set @ServiceName2=@ServiceName2+@Temp
			END
		END
		ELse
		BEGIN
			exec GetSvCode1Name @Service_SVKey, @QO_SubCode, null, @Temp output, null, null
			If @ServiceName1!=''
				Set @ServiceName1=@ServiceName1+','
			Set @ServiceName1=@ServiceName1+@Temp
		END
	END
	FETCH NEXT FROM curQLoadListQO INTO	@QT_IDLocal, @QO_SubCode, @QO_TypeD, @DL_SubCode1
END
If @Service_SVKey=3
BEGIN
	Set @ServiceName2='(' + @ServiceName2 + ')'
END
Update #QuotaLoadList set QL_Description=LEFT(ISNULL(QL_Description,'') + @ServiceName1 + @ServiceName2,255) where QL_QTID=@QT_ID_Prev

CLOSE curQLoadListQO
DEALLOCATE curQLoadListQO

If @Service_SVKey=3
BEGIN
	Update #QuotaLoadList set QL_Description = QL_Description + ' - Per person' where QL_ByRoom = 0
END

IF @ResultType is null or @ResultType not in (10)
BEGIN
	select * 
	from #QuotaLoadList (nolock)
	order by QL_QTID-QL_QTID DESC /*Сначала квоты, потом неквоты*/,QL_Description,QL_PartnerName,QL_Type DESC,QL_Release,QL_Durations,QL_CityDepartments,QL_FilialKey,QL_CustomerInfo,QL_QTID,QL_DataType
	RETURN 0
END
ELSE
BEGIN --для наличия мест(из оформления)
	declare @ServicePlacesTrTable varchar (1000)
	set @ServicePlacesTrTable = '
	DECLARE  @ServicePlacesTr TABLE
	(
		SPT_QTID int, SPT_PRKey int, SPT_SubCode1 int, SPT_PartnerName varchar(100), SPT_Description varchar(255), 
		SPT_Type smallint, SPT_FilialKey int, SPT_CityDepartments int, SPT_Release int, SPT_Durations varchar(100),
		SPT_AgentKey int, SPT_Date smalldatetime, SPT_Places smallint, SPT_Stop smallint, SPT_CheckIn smallint
	)'
	
	DECLARE  @ServicePlacesTr TABLE
	(
		SPT_QTID int, SPT_PRKey int, SPT_SubCode1 int, SPT_PartnerName nvarchar(100), SPT_Description nvarchar(255), 
		SPT_Type smallint, SPT_FilialKey int, SPT_CityDepartments int, SPT_Release int, SPT_Durations nvarchar(100),
		SPT_AgentKey int, SPT_Date smalldatetime, SPT_Places smallint, SPT_Stop smallint, SPT_CheckIn smallint
	)
	
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

		set @str = @ServicePlacesTrTable + '
			INSERT INTO @ServicePlacesTr 
				(SPT_QTID, SPT_PRKey,SPT_SubCode1,SPT_PartnerName,SPT_Description,SPT_Type,
				SPT_FilialKey,SPT_CityDepartments,SPT_Release,SPT_Durations,SPT_AgentKey,
				SPT_Date,SPT_Places) 
			SELECT QL_QTID, QL_PRKey,QL_SubCode1,QL_PartnerName, QL_Description, QL_Type, 
				QL_FilialKey, QL_CityDepartments,QL_Release,QL_Durations,QL_AgentKey, 
				''' + CAST(@curDate as varchar(20)) + ''', QL_' + CAST(@n as varchar(3)) + '
				FROM #QuotaLoadList (nolock)
				WHERE QL_dataType=21'
		exec (@str)

		set @str = @ServicePlacesTrTable + 'UPDATE @ServicePlacesTr SET SPT_Stop=
					(SELECT QL_' + CAST(@n as varchar(3)) + '
					FROM #QuotaLoadList (nolock)
					WHERE  QL_dataType=22 and 
					SPT_QTID=QL_QTID and
					SPT_PRKey=QL_PRKey and 
					ISNULL(SPT_SubCode1,-1)=ISNULL(QL_SubCode1,-1) and 
					SPT_PartnerName=QL_PartnerName and 
					SPT_Description=QL_Description and 
					SPT_Type=QL_Type and 
					ISNULL(SPT_FilialKey,-1)=ISNULL(QL_FilialKey,-1) and 
					ISNULL(SPT_CityDepartments,-1)=ISNULL(QL_CityDepartments,-1) and 
					ISNULL(SPT_Release,-1)=ISNULL(QL_Release,-1) and 
					ISNULL(SPT_Durations,-1)=ISNULL(QL_Durations,-1) and 
					ISNULL(SPT_AgentKey,-1)=ISNULL(QL_AgentKey,-1) and 
					SPT_Date=''' + CAST(@curDate as varchar(20)) + ''')
					WHERE SPT_Date=''' + CAST(@curDate as varchar(20))+ ''''

		exec (@str)

		set @str = @ServicePlacesTrTable + 'UPDATE @ServicePlacesTr SET SPT_CheckIn=
					(SELECT QL_' + CAST(@n as varchar(3)) + '
					FROM #QuotaLoadList (nolock)
					WHERE  QL_dataType=23 and
					SPT_QTID=QL_QTID and 
					SPT_PRKey=QL_PRKey and 
					ISNULL(SPT_SubCode1,-1)=ISNULL(QL_SubCode1,-1) and 
					SPT_PartnerName=QL_PartnerName and 
					SPT_Description=QL_Description and 
					SPT_Type=QL_Type and 
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
	SP_Type smallint, SP_FilialKey int, SP_CityDepartments int, 
	SP_Places1 smallint, SP_Places2 smallint, SP_Places3 smallint, 
	SP_NonReleasePlaces1 smallint,SP_NonReleasePlaces2 smallint,SP_NonReleasePlaces3 smallint, 
	SP_StopPercent1 smallint,SP_StopPercent2 smallint,SP_StopPercent3 smallint
)

DECLARE @SPT_QTID int, @SPT_PRKey int, @SPT_SubCode1 int, @SPT_PartnerName varchar(100), @SPT_Description varchar(255), 
		@SPT_Type smallint, @SPT_FilialKey int, @SPT_CityDepartments int, @SPT_Release smallint, @SPT_Date smalldatetime, 
		@SPT_Places smallint, @SPT_Stop smallint, @SPT_CheckIn smallint, @SPT_PRKey_Old int, @SPT_PartnerName_Old varchar(100), 
		@SPT_SubCode1_Old int, @SPT_Description_Old varchar(255), @SPT_Type_Old smallint, @SPT_FilialKey_Old int,
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
			 SPT_QTID, SPT_PRKey, SPT_SubCode1, SPT_PartnerName, SPT_Description, SPT_Type, SPT_FilialKey, 
			 SPT_CityDepartments, ISNULL(SPT_Release, 0), SPT_Date, ISNULL(SPT_Places, 0), ISNULL(SPT_Stop,0), SPT_CheckIn
	FROM	#ServicePlacesTr
	ORDER BY  SPT_PRKey, SPT_Type, SPT_SubCode1, SPT_PartnerName, SPT_Description, 
		SPT_FilialKey, SPT_CityDepartments, SPT_Date, SPT_Release

OPEN curQ2
FETCH NEXT FROM curQ2 INTO @SPT_QTID, @SPT_PRKey, @SPT_SubCode1, @SPT_PartnerName, @SPT_Description, 
		@SPT_Type, @SPT_FilialKey, @SPT_CityDepartments, @SPT_Release, @SPT_Date, @SPT_Places, @SPT_Stop, @SPT_CheckIn	

SET @SPT_PRKey_Old=@SPT_PRKey
SET @SPT_Description_Old=@SPT_Description
SET @SPT_PartnerName_Old=@SPT_PartnerName
SET @SPT_Type_Old=@SPT_Type
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
-- При смене даты обнуляем текущие колличества мест
		SET @currentPlaces1=0
		SET @currentPlaces2=0
		SET @currentPlaces3=0
		SET @currentNonReleasePlaces1=0
		SET @currentNonReleasePlaces2=0
		SET @currentNonReleasePlaces3=0
	END

	IF @SPT_PRKey!=@SPT_PRKey_Old or @SPT_Description!=@SPT_Description_Old or ISNULL(@SPT_Type,-1)!=ISNULL(@SPT_Type_Old,-1)
	BEGIN
		IF @quotaCounter1 = 0 SET @quotaCounter1 = 1
		IF @quotaCounter2 = 0 SET @quotaCounter2 = 1
		IF @quotaCounter3 = 0 SET @quotaCounter3 = 1
		INSERT INTO @ServicePlaces (SP_PRKey, SP_SubCode1, SP_PartnerName, SP_Description, SP_Type, 
				SP_FilialKey, SP_CityDepartments, SP_Places1, SP_Places2, SP_Places3, 
				SP_NonReleasePlaces1, SP_NonReleasePlaces2, SP_NonReleasePlaces3,
				SP_StopPercent1,SP_StopPercent2,SP_StopPercent3)
		Values (@SPT_PRKey_Old, @SPT_SubCode1_Old, @SPT_PartnerName_Old, @SPT_Description_Old, @SPT_Type_Old, 
				@SPT_FilialKey_Old, @SPT_CityDepartments_Old, 
				ISNULL(@OblectPlacesMin1,@currentPlaces1), ISNULL(@OblectPlacesMin2,@currentPlaces2), ISNULL(@OblectPlacesMin3,@currentPlaces3),
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
	SET @SPT_Date_Old=@SPT_Date
	FETCH NEXT FROM curQ2 INTO @SPT_QTID, @SPT_PRKey, @SPT_SubCode1, @SPT_PartnerName, @SPT_Description, 
			@SPT_Type, @SPT_FilialKey, @SPT_CityDepartments, @SPT_Release, @SPT_Date, @SPT_Places, @SPT_Stop, @SPT_CheckIn	

	If @@FETCH_STATUS != 0
	BEGIN
		IF @quotaCounter1 = 0 SET @quotaCounter1 = 1
		IF @quotaCounter2 = 0 SET @quotaCounter2 = 1
		IF @quotaCounter3 = 0 SET @quotaCounter3 = 1
		INSERT INTO @ServicePlaces (SP_PRKey, SP_SubCode1, SP_PartnerName, SP_Description, SP_Type, 
			SP_FilialKey, SP_CityDepartments, SP_Places1, SP_Places2, SP_Places3, 
			SP_NonReleasePlaces1, SP_NonReleasePlaces2, SP_NonReleasePlaces3,
			SP_StopPercent1,SP_StopPercent2,SP_StopPercent3)
		Values (@SPT_PRKey_Old, @SPT_SubCode1_Old, @SPT_PartnerName_Old, @SPT_Description_Old, @SPT_Type_Old, 
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
		SP_PRKey,SP_PartnerName,SP_Description,SP_SubCode1,SP_Type,SP_FilialKey,SP_CityDepartments,
		CAST(SP_Places1 as varchar(4))+';'+CAST(SP_NonReleasePlaces1 as varchar(4))+';'+CAST(SP_StopPercent1 as varchar(4)) as SP_1,
		CAST(SP_Places2 as varchar(4))+';'+CAST(SP_NonReleasePlaces2 as varchar(4))+';'+CAST(SP_StopPercent2 as varchar(4)) as SP_2,
		CAST(SP_Places3 as varchar(4))+';'+CAST(SP_NonReleasePlaces3 as varchar(4))+';'+CAST(SP_StopPercent3 as varchar(4)) as SP_3
	from @ServicePlaces
	order by SP_Description, SP_PartnerName, SP_Type
GO

grant execute on [dbo].[GetQuotaLoadListData_N] to public
GO

-- sp_NationalCurrencyPrice2.sql
if exists(select id from sysobjects where id = object_id(N'[dbo].[NationalCurrencyPrice2]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop proc [dbo].[NationalCurrencyPrice2]
GO

CREATE PROCEDURE [dbo].[NationalCurrencyPrice2]
@sRate varchar(5), -- валюта пересчета
@sRateOld varchar(5), -- старая валюта
@sDogovor varchar(100), -- код договора
@nPrice money, -- новая цена в указанной валюте
@nPriceOld money, -- старая цена
@nDiscountSum money, -- новая скидка в указанной валюте
@date DateTime, -- действие
@order_status smallint -- null OR passing the new value for dg_sor_code from the trigger when it's (dg_sor_code) updated
AS
BEGIN
      declare @national_currency varchar(5)
      select top 1 @national_currency = RA_CODE from Rates where RA_National = 1

      declare @rc_course money
      declare @rc_courseStr char(30)


            set @rc_course = -1
            select top 1 @rc_courseStr = RC_COURSE from RealCourses
            where
            RC_RCOD1 = @national_currency and RC_RCOD2 = @sRate
            and convert(char(10), RC_DATEBEG, 102) = convert(char(10), @date, 102)
            set @rc_course = cast(isnull(@rc_courseStr, -1) as money)

      if @sRate = @national_currency
      begin
            set @rc_courseStr = '1'
            set @rc_course = 1
      end
      
      declare @sHI_WHO varchar(25)
      exec dbo.CurrentUser @sHI_WHO output

      if @rc_course <> -1
      begin
            declare @final_price money
            set @final_price = @rc_course * @nPrice
            
            declare @sys_setting varchar(5)
			set @sys_setting = null
			select @sys_setting = SS_ParmValue from SystemSettings where SS_ParmName = 'RECALC_NATIONAL_PRICE'

            -- пересчитываем цену, если надо
            if (@sys_setting <> '-1')
            begin
				declare @tmp_final_price money
				set @tmp_final_price = null
				exec [dbo].[CalcPriceByNationalCurrencyRate] @sDogovor, @sRate, @sRateOld, @national_currency, @nPrice, @nPriceOld, @sHI_WHO, 'INSERT_TO_HISTORY', @tmp_final_price output, @rc_course, @order_status

				if @tmp_final_price is not null
				begin
					set @final_price = @tmp_final_price
				end
            end
            --

            insert into dbo.history
            (HI_DGCOD, HI_WHO, HI_TEXT, HI_REMARK, HI_MOD, HI_TYPE, HI_OAId)
            values
            (@sDogovor, @sHI_WHO, @rc_courseStr, @sRate, 'UPD', 'DOGOVORCURRENCY', 20)

            update dbo.tbl_Dogovor
            set
                  DG_NATIONALCURRENCYPRICE = @final_price,
                  DG_NATIONALCURRENCYDISCOUNTSUM = @rc_course * @nDiscountSum
            where
                  DG_CODE = @sDogovor
      end
      else
      begin
            update dbo.tbl_Dogovor
            set
                  DG_NATIONALCURRENCYPRICE = null,
                  DG_NATIONALCURRENCYDISCOUNTSUM = null
            where
                  DG_CODE = @sDogovor

            insert into dbo.history
            (HI_DGCOD, HI_WHO, HI_TEXT, HI_REMARK, HI_MOD, HI_TYPE, HI_OAId)
            values
            (@sDogovor, @sHI_WHO, 'Курс отсутствует', @sRate, 'UPD', 'DOGOVORCURRENCYISNULL', 21)
      end
END
return 0
GO


-- f_GetFirstDogovorStatusDate.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetFirstDogovorStatusDate]') and OBJECTPROPERTY(id, N'IsTableFunction') = 0)
	drop function [dbo].[GetFirstDogovorStatusDate]
GO

CREATE function [dbo].[GetFirstDogovorStatusDate](@dgKey int, @statusKey int)
returns datetime
as
begin

	declare @historyTable table(xht_date datetime, xht_value int)
	declare @xht_date datetime, @result datetime

	insert into @historyTable(xht_date, xht_value)
	select hi_date, hd_intvaluenew
	from history with(nolock) inner join historydetail with(nolock) on hi_id = hd_hiid
	where HI_DGKEY = @dgKey and HD_OAId = 1019 and HD_IntValueNew = @statusKey

	declare history_cursor cursor for
	select xht_date
	from @historyTable
	order by xht_date

	set @result = null
	OPEN history_cursor
	FETCH NEXT FROM history_cursor INTO @xht_date
	 
	WHILE @@FETCH_STATUS = 0 and @result is null
	BEGIN
		if not exists(select * from @historyTable where (xht_date > @xht_date) and (xht_date < dateadd(second, 30, @xht_date)))
		begin
			if @result is null set @result = @xht_date
		end
		
		FETCH NEXT FROM history_cursor INTO @xht_date
	END

	CLOSE history_cursor
	DEALLOCATE history_cursor

	return @result
end
GO

-- 100812_update_systemsettings.sql
update SystemSettings set SS_ParmValue = '-1' where SS_ParmName = 'RECALC_NATIONAL_PRICE'
go

-- fn_mwGetFullHotelNames.sql
------------------------------------
-- При изменении учеть, что она создается в скрипте ReplicationSUB
-------------------------------------




if object_id('dbo.mwGetFullHotelNames', 'fn') is not null
	drop function dbo.mwGetFullHotelNames
go

create function [dbo].[mwGetFullHotelNames](@tikey int, @separator varchar(10), @fullPansionName smallint,
	@hotelOnly smallint, @showStars smallint)
returns varchar(8000)
as
begin
	declare @result varchar(8000)
	set @result = ''
	select @result = @result + case isnull(hd_http, '') 
					when '' then ltrim(rtrim(isnull(hd_name, ''))) + '&nbsp;' + (case @showStars when 0 then '' else hd_stars end) 
					else '<a href=''' + ltrim(rtrim(hd_http)) + ''' target=''_blank''>' + isnull(hd_name, '') + (case @showStars when 0 then '' else ('&nbsp;' + isnull(hd_stars, '')) end) + '</a>'
					end
				+ '&nbsp;(' + isnull(rs_name, ct_name) + ')' + case @hotelOnly 
					when 0 then ',&nbsp;' + (case @fullPansionName when 0 then isnull(pn_code, '') else isnull(pn_name, '') end) 
					else '' 
					end
				+ @separator
	from tp_services ts inner join tp_servicelists tl with(nolock) on tl.tl_tskey = ts.ts_key
		inner join hoteldictionary with(nolock) on (ts_svkey = 3 and ts_code = hd_key)
		inner join citydictionary with(nolock) on hd_ctkey = ct_key
		inner join pansion with(nolock) on ts_subcode2 = pn_key
		left outer join resorts with(nolock) on (hd_rskey = rs_key)
	where tl.tl_tikey = @tikey
	order by ts_day

	declare @len int
	set @len = len(@result)
	if(@len > 0)
		set @result = substring(@result, 1, @len - len(@separator))
	return @result
end
go

grant exec on dbo.mwGetFullHotelNames to public
go

-- fn_mwReplIsPublisher.sql
if object_id('dbo.mwReplIsPublisher', 'fn') is not null
	drop function dbo.mwReplIsPublisher
go

create function dbo.mwReplIsPublisher()
returns smallint
as
begin
	declare @repl_setting varchar(50)
	select @repl_setting = lower(isnull(ss_parmvalue, ''))
	from SystemSettings with(nolock)
	where ss_parmname = 'MWReplication'

	if(@repl_setting = 'publisher' or @repl_setting = 'subscriber_publisher')
		return 1
	return 0
end
go

grant exec on dbo.mwReplIsPublisher to public
go

-- fn_mwReplIsSubscriber.sql
if object_id('dbo.mwReplIsSubscriber', 'fn') is not null
	drop function dbo.mwReplIsSubscriber
go

create function dbo.mwReplIsSubscriber()
returns smallint
as
begin
	declare @repl_setting varchar(50)
	select @repl_setting = lower(isnull(ss_parmvalue, ''))
	from SystemSettings with(nolock)
	where ss_parmname = 'MWReplication'

	if(@repl_setting = 'subscriber' or @repl_setting = 'subscriber_publisher')
		return 1
	return 0
end
go

grant exec on dbo.mwReplIsSubscriber to public
go

-- fn_mwReplPublisherDB.sql
if object_id('dbo.mwReplPublisherDB', 'fn') is not null
	drop function dbo.mwReplPublisherDB
go

create function dbo.mwReplPublisherDB()
returns varchar (254)
as
begin
	--возвращаем имя базы с первого поискового сервера, будем считать на остальных серверах данные одинаковые
	declare @repl_setting varchar(254)
	select @repl_setting = lower(isnull(ss_parmvalue, ''))
	from SystemSettings with(nolock)
	where ss_parmname = 'mwReplPublisherDB'
	
	return @repl_setting
end
go

grant exec on dbo.mwReplPublisherDB to public
go

-- fn_mwReplSubscriberDB.sql
if object_id('dbo.mwReplSubscriberDB', 'fn') is not null
	drop function dbo.mwReplSubscriberDB
go

create function dbo.mwReplSubscriberDB()
returns varchar (254)
as
begin
	--возвращаем имя базы с первого поискового сервера, будем считать на остальных серверах данные одинаковые
	declare @repl_setting varchar(254)
	select @repl_setting = lower(isnull(ss_parmvalue, ''))
	from SystemSettings with(nolock)
	where ss_parmname = 'MWReplSubscriberDB'
	
	return @repl_setting
end
go

grant exec on dbo.mwReplSubscriberDB to public
go

-- tbl_mwDeleted.sql
if not exists(select id from sysobjects where xtype = 'U' and name='mwDeleted')
begin
declare @sql varchar (1000)
if (@@version like '%SQL%Server%2000%')
	begin
		set @sql = 'CREATE TABLE [dbo].[mwDeleted](
				[id] [int] IDENTITY(1,1) NOT NULL,
				[del_key] [int] NULL,
			PRIMARY KEY CLUSTERED ([id] ASC)
			) ON [PRIMARY]'
		exec sp_executesql @sql
	end
	else
	begin
		set @sql = 'CREATE TABLE [dbo].[mwDeleted](
				[id] [int] IDENTITY(1,1) NOT NULL,
				[del_key] [int] NULL,
			PRIMARY KEY CLUSTERED 
			(
				[id] ASC
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
			) ON [PRIMARY]'
		exec sp_executesql @sql
	end	
end

go


-- T_mwDeletePrice.sql
if exists(select id from sysobjects where xtype='TR' and name='mwDeletePrice')
	drop trigger dbo.mwDeletePrice
go

create trigger [dbo].[mwDeletePrice] on [dbo].[TP_Prices] for delete as
begin	
	if dbo.mwReplIsSubscriber() <= 0
		insert into dbo.mwDeleted with(rowlock) (del_key) select tp_key from deleted
end

GO

-- tbl_mwReplTours.sql
if exists(select id from sysobjects where name='mwReplTours' and xtype='U')
	drop table [dbo].[mwReplTours]
go

CREATE TABLE [dbo].[mwReplTours](
	[rt_key] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[rt_trkey] [int] NULL,
	[rt_tokey] [int] NULL,
	[rt_add] [smallint] NULL,
	[rt_date] [datetime] null,
PRIMARY KEY CLUSTERED 
(
	[rt_key] ASC
)
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[mwReplTours]  WITH CHECK ADD FOREIGN KEY([rt_tokey])
REFERENCES [dbo].[TP_Tours] ([TO_Key])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[mwReplTours]  WITH CHECK ADD FOREIGN KEY([rt_trkey])
REFERENCES [dbo].[tbl_TurList] ([TL_KEY])
GO

-- T_mwInsertTour.sql
if exists(select id from sysobjects where xtype='TR' and name='mwInsertTour')
	drop trigger dbo.mwInsertTour
go

CREATE trigger [dbo].[mwInsertTour] on [dbo].[mwReplTours] for insert
as
begin

	if dbo.mwReplIsSubscriber() > 0
	begin
		select rt_tokey as trkey, rt_add as is_add into #tmpKeys from inserted

		declare replcur cursor fast_forward read_only for
		select trkey, is_add from #tmpKeys

		declare @trkey int, @add smallint

		open replcur

		fetch next from replcur into @trkey, @add
		while(@@fetch_status = 0)
		begin
	--		insert into dbo.mwDebug(data) values(ltrim(rtrim(str(@trkey))))
			if @trkey is not null
				exec dbo.FillMasterWebSearchFields @trkey, @add, 1
	--		insert into dbo.mwDebug(data) values(ltrim(rtrim(str(@trkey))))
			fetch next from replcur into @trkey, @add
		end
		
		close replcur
		deallocate replcur	
	end
end

GO


-- sp_mwFillTP.sql

if exists(select id from sysobjects where xtype='p' and name='mwFillTP')
	drop proc dbo.mwFillTP
go

create procedure [dbo].[mwFillTP] (@tokey int)
as
begin
	declare @sql varchar(4000)
	declare @source varchar(200)
	set @source = ''

	declare @tokeyStr varchar (30)
	set @tokeyStr = cast(@tokey as varchar(30))

	if dbo.mwReplIsSubscriber() > 0 and len(dbo.mwReplPublisherDB()) > 0
		set @source = '[mt].[' + dbo.mwReplPublisherDB() + '].'
	
	--delete from dbo.tp_tours where to_key = @tokey	
	if not exists(select 1 from dbo.tp_tours with(nolock) where to_key = @tokey)
	begin
		set @sql = 'insert into dbo.tp_tours with(rowlock) (
			[TO_Key],
			[TO_TRKey],
			[TO_Name],
			[TO_PRKey],
			[TO_CNKey],
			[TO_Rate],
			[TO_DateCreated],
			[TO_DateValid],
			[TO_PriceFor],
			[TO_OpKey],
			[TO_XML],
			[TO_DateBegin],
			[TO_DateEnd],
			[TO_IsEnabled],
			[TO_PROGRESS],
			[TO_UPDATE],
			[TO_UPDATETIME],
			[TO_DateValidBegin],
			[TO_CalculateDateEnd],
			[TO_PriceCount],
			[to_attribute],
			[TO_MinPrice],
			[TO_HotelNights]
		)
		select
			[TO_Key],
			[TO_TRKey],
			[TO_Name],
			[TO_PRKey],
			[TO_CNKey],
			[TO_Rate],
			[TO_DateCreated],
			[TO_DateValid],
			[TO_PriceFor],
			[TO_OpKey],
			[TO_XML],
			[TO_DateBegin],
			[TO_DateEnd],
			[TO_IsEnabled],
			[TO_PROGRESS],
			[TO_UPDATE],
			[TO_UPDATETIME],
			[TO_DateValidBegin],
			[TO_CalculateDateEnd],
			[TO_PriceCount],
			[to_attribute],
			[TO_MinPrice],
			[TO_HotelNights]
		from
			' + @source + 'dbo.tp_tours with(nolock)
		where
			to_key = ' + @tokeyStr

		exec (@sql)
	end
	
	
	delete from dbo.TP_TurDates where td_tokey = @tokey
	--if not exists(select 1 from dbo.TP_TurDates with(nolock) where td_tokey = @tokey)
	begin
		set @sql = 
		'insert into dbo.TP_TurDates with(rowlock) (
			[TD_Key],
			[TD_TOKey],
			[TD_Date],
			[TD_UPDATE],
			[TD_CHECKMARGIN]
		)
		select
			[TD_Key],
			[TD_TOKey],
			[TD_Date],
			[TD_UPDATE],
			[TD_CHECKMARGIN]
		from
			' + @source + 'dbo.TP_TurDates with(nolock)
		where
			td_tokey = ' + @tokeyStr

		exec (@sql)		
	end	
	
    delete dbo.tp_services where ts_tokey = @tokey
	--if not exists(select 1 from dbo.tp_services with(nolock) where ts_tokey = @tokey)
	begin
		set @sql = 
		'insert into dbo.tp_services with(rowlock) (
			[TS_Key],
			[TS_TOKey],
			[TS_SVKey],
			[TS_Code],
			[TS_SubCode1],
			[TS_SubCode2],
			[TS_CNKey],
			[TS_CTKey],
			[TS_Day],
			[TS_Days],
			[TS_Men],
			[TS_Name],
			[TS_OpPartnerKey],
			[TS_OpPacketKey],
			[TS_Attribute],
			[TS_TEMPGROSS],
			[TS_CHECKMARGIN]
		)
		select
			[TS_Key],
			[TS_TOKey],
			[TS_SVKey],
			[TS_Code],
			[TS_SubCode1],
			[TS_SubCode2],
			[TS_CNKey],
			[TS_CTKey],
			[TS_Day],
			[TS_Days],
			[TS_Men],
			[TS_Name],
			[TS_OpPartnerKey],
			[TS_OpPacketKey],
			[TS_Attribute],
			[TS_TEMPGROSS],
			[TS_CHECKMARGIN]
		from
			' + @source + 'dbo.tp_services with(nolock)
		where
			ts_tokey = ' + @tokeyStr

		exec (@sql)
	end

	delete from dbo.tp_lists where ti_tokey = @tokey
	--if not exists(select 1 from dbo.tp_lists with(nolock) where ti_tokey = @tokey)
	begin
		set @sql = 
		'insert into dbo.tp_lists with(rowlock) (
			[TI_Key],
			[TI_TOKey],
			[TI_Name],
			[TI_FirstHDKey],
			[TI_FirstHRKey],
			[TI_FirstPNKey],
			[TI_Days],
			[TI_HotelKeys],
			[TI_PansionKeys],
			[TI_HotelDays],
			[TI_FirstHDStars],
			[TI_FirstRsKey],
			[TI_SecondHDKey],
			[TI_SecondHRKey],
			[TI_SecondPNKey],
			[TI_SecondHDStars],
			[TI_SecondCtKey],
			[TI_SecondRsKey],
			[TI_CtKeyFrom],
			[TI_CtKeyTo],
			[TI_ApKeyFrom],
			[TI_ApKeyTo],
			[ti_firsthotelday],
			[ti_hdpartnerkey],
			[ti_totaldays],
			[ti_nights],
			[ti_lasthotelday],
			[ti_chkey],
			[ti_chbackkey],
			[ti_hdday],
			[ti_hdnights],
			[ti_chday],
			[ti_chbackday],
			[ti_chpkkey],
			[ti_chprkey],
			[ti_chbackpkkey],
			[ti_chbackprkey],
			[TI_FirstCtKey],
			[TI_UPDATE],
			[TI_FIRSTHOTELPARTNERKEY],
			[ti_hotelroomkeys],
			[ti_hotelstars]
		)
		select
			[TI_Key],
			[TI_TOKey],
			[TI_Name],
			[TI_FirstHDKey],
			[TI_FirstHRKey],
			[TI_FirstPNKey],
			[TI_Days],
			[TI_HotelKeys],
			[TI_PansionKeys],
			[TI_HotelDays],
			[TI_FirstHDStars],
			[TI_FirstRsKey],
			[TI_SecondHDKey],
			[TI_SecondHRKey],
			[TI_SecondPNKey],
			[TI_SecondHDStars],
			[TI_SecondCtKey],
			[TI_SecondRsKey],
			[TI_CtKeyFrom],
			[TI_CtKeyTo],
			[TI_ApKeyFrom],
			[TI_ApKeyTo],
			[ti_firsthotelday],
			[ti_hdpartnerkey],
			[ti_totaldays],
			[ti_nights],
			[ti_lasthotelday],
			[ti_chkey],
			[ti_chbackkey],
			[ti_hdday],
			[ti_hdnights],
			[ti_chday],
			[ti_chbackday],
			[ti_chpkkey],
			[ti_chprkey],
			[ti_chbackpkkey],
			[ti_chbackprkey],
			[TI_FirstCtKey],
			[TI_UPDATE],
			[TI_FIRSTHOTELPARTNERKEY],
			[ti_hotelroomkeys],
			[ti_hotelstars]
		from
			' + @source + 'dbo.tp_lists with(nolock)
		where
			ti_tokey = ' + @tokeyStr

		exec (@sql)
	end

	delete from dbo.tp_servicelists where tl_tokey = @tokey
	--if not exists(select 1 from dbo.tp_servicelists with(nolock) where tl_tokey = @tokey)
	begin	
		set @sql = 
		'insert into dbo.tp_servicelists with(rowlock) (
			[TL_Key],
			[TL_TOKey],
			[TL_TSKey],
			[TL_TIKey]
		)
		select
			[TL_Key],
			[TL_TOKey],
			[TL_TSKey],
			[TL_TIKey]
		from
			' + @source + 'dbo.tp_servicelists with(nolock)
		where
			tl_tokey = ' + @tokeyStr

		exec (@sql)
	end

	delete from dbo.tp_prices where tp_tokey = @tokey
	--if not exists(select 1 from dbo.tp_prices with(nolock) where tp_tokey = @tokey)
	begin
		set @sql = 
		'insert into dbo.tp_prices with(rowlock) (
			[TP_Key],
			[TP_TOKey],
			[TP_DateBegin],
			[TP_DateEnd],
			[TP_Gross],
			[TP_TIKey]
		)
		select
			[TP_Key],
			[TP_TOKey],
			[TP_DateBegin],
			[TP_DateEnd],
			[TP_Gross],
			[TP_TIKey]
		from
			' + @source + 'dbo.tp_prices with(nolock)
		where
			tp_tokey = ' + @tokeyStr

		exec (@sql)
	end
end
GO

grant exec on dbo.mwFillTP to public
go

-- T_mwUpdatePriceTourEnabled.sql

if exists(select id from sysobjects where xtype='TR' and name='mwUpdatePriceTourEnabled')
	drop trigger dbo.mwUpdatePriceTourEnabled
go

CREATE trigger [dbo].[mwUpdatePriceTourEnabled] on [dbo].[TP_Tours]
for update
as
begin
	if @@rowcount > 0 and update(to_isenabled)
	begin	
			if dbo.mwReplIsSubscriber() <= 0
				return

			declare @mwSearchType int
			select @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
				where SS_ParmName = 'MWDivideByCountry'

			if @mwSearchType = 0
			begin
				update mwPriceDataTable with (rowlock)
				set pt_isenabled = 0
				from inserted i inner join deleted d on i.to_key = d.to_key			
				where pt_tourkey = i.to_key
					and i.to_isenabled <> d.to_isenabled and i.to_isenabled = 0
			end
			else
			begin
				declare @tableName varchar(100), @tokey int, @cnkey int, @ctkey int
				declare @sql varchar(8000)

				create table #tmpPriceTours(
					to_key int
				)
				create index x_tokey on #tmpPriceTours(to_key)

				insert into #tmpPriceTours
				select i.to_key
				from inserted i inner join deleted d on i.to_key = d.to_key
				where i.to_isenabled <> d.to_isenabled and i.to_isenabled = 0

				declare tblCursor cursor fast_forward read_only for 
				select 
					to_key, 
					to_cnkey, 
					tl_ctdeparturekey
				from 
					tp_tours tt with(nolock)
					inner join tbl_TurList with(nolock) on to_trkey = tl_key
				where
					exists(select 1 from #tmpPriceTours t where t.to_key = tt.to_key)

				open tblCursor

				fetch next from tblCursor into @tokey, @cnkey, @ctkey
				while @@fetch_status = 0
				begin	
					set @tableName = dbo.mwGetPriceTableName(@cnkey, @ctkey)
					set @sql = 'update ' + @tableName + ' with(rowlock) set pt_isenabled = 0 where pt_tourkey = ' + ltrim(str(@tokey))
					exec (@sql)

					fetch next from tblCursor into @tokey, @cnkey, @ctkey
				end

				close tblCursor
				deallocate tblCursor
			end

			update mwSpoDataTable with(rowlock)
			set sd_isenabled = 0
			from inserted i inner join deleted d on i.to_key = d.to_key			
			where sd_tourkey = i.to_key
				and i.to_isenabled <> d.to_isenabled and i.to_isenabled = 0	
	end
end


GO

-- tbl_mwReplDeletedPricesTemp.sql

if not exists(select id from sysobjects where xtype = 'U' and name='mwReplDeletedPricesTemp')
begin

		CREATE TABLE [dbo].[mwReplDeletedPricesTemp](
		[rdp_id] [int] IDENTITY(1,1) NOT NULL,
		[rdp_pricekey] [int] NULL,
			PRIMARY KEY CLUSTERED 
			(
				[rdp_id] ASC
			)
			) ON [PRIMARY]			

			/****** Object:  Index [x_pricekey]    Script Date: 06/04/2010 16:00:45 ******/
			CREATE NONCLUSTERED INDEX [x_pricekey] ON [dbo].[mwReplDeletedPricesTemp] 
			(
				[rdp_pricekey] ASC
			) ON [PRIMARY]			

		grant select, insert, update, delete on dbo.[mwReplDeletedPricesTemp] to public

end

GO

-- T_mwReplDeletePrice.sql
if exists(select id from sysobjects where xtype='TR' and name='mwReplDeletePrice')
	drop trigger dbo.mwReplDeletePrice

GO

create trigger [dbo].[mwReplDeletePrice] on [dbo].[TP_Prices] for delete as
begin
	if dbo.mwReplIsPublisher() > 0
		insert into dbo.mwReplDeletedPricesTemp with(rowlock) (rdp_pricekey) select tp_key from deleted
end

GO


-- t_mwDeleteTour.sql

if exists(select id from sysobjects where xtype='TR' and name='mwDeleteTour')
	drop trigger dbo.mwDeleteTour
go


CREATE trigger [dbo].[mwDeleteTour] on [dbo].[TP_Tours]
for delete
as
begin
	if dbo.mwReplIsSubscriber() <= 0
				return

	declare disableCursor cursor fast_forward read_only for
	select 
		to_key
	from 
		deleted 

	open disableCursor
	declare @tableName nvarchar(100), @sql nvarchar(4000), @tokey int
	set @tableName = 'dbo.mwPriceDataTable'
	
	fetch next from disableCursor into @tokey
	while @@fetch_status = 0
	begin
		if(@tableName is not null and len(@tableName) > 0)
		begin
			set @sql = 'insert into mwDeleted with(rowlock) (del_key) select pt_pricekey from ' + @tableName + ' with(nolock) where pt_tourkey = ' + ltrim(str(@tokey)) + '
						update ' + @tableName + ' with(rowlock) set pt_isenabled = 0 where pt_isenabled > 0 and pt_tourkey = ' + ltrim(str(@tokey)) + '
						update mwSpoDataTable with(rowlock) set sd_isenabled = 0 where sd_isenabled > 0 and sd_tourkey = ' + ltrim(str(@tokey))
			exec (@sql)
		end

		fetch next from disableCursor into @tokey
	end
	
	close disableCursor
	deallocate disableCursor

	delete from TP_Prices with(rowlock) where tp_tokey = @tokey
	delete from TP_ServiceLists with(rowlock) where tl_tokey = @tokey
	delete from TP_Services with(rowlock) where ts_tokey = @tokey
	delete from TP_Lists with(rowlock) where ti_tokey = @tokey
	delete from TP_Tours with(rowlock) where to_key = @tokey
end

GO

-- sp_mwReplDisableDeletedPrices.sql
if exists(select id from sysobjects where xtype='P' and name='mwReplDisableDeletedPrices')
	drop proc dbo.mwReplDisableDeletedPrices
go

create proc [dbo].[mwReplDisableDeletedPrices]
as
begin
	select * into #mwReplDeletedPricesTemp from dbo.mwReplDeletedPricesTemp with(nolock)
	create index x_pricekey on #mwReplDeletedPricesTemp(rdp_pricekey)
	
	delete from dbo.mwReplDeletedPricesTemp with(rowlock)
	where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = mwReplDeletedPricesTemp.rdp_pricekey)
	
	if dbo.mwReplIsPublisher() > 0 
	begin
		declare @sql varchar (500)
		declare @source varchar(200)
		set @source = ''
		
		if len(dbo.mwReplSubscriberDB()) > 0
			set @source = '[mw].[' + dbo.mwReplSubscriberDB() + '].'

		if exists(select 1 from #mwReplDeletedPricesTemp)
		begin
			set @sql = '
			insert into ' + @source + 'dbo.mwReplDeletedPricesTemp with(rowlock) (rdp_pricekey)
			select rdp_pricekey from #mwReplDeletedPricesTemp'

			exec (@sql)
		end
	end
	else if dbo.mwReplIsSubscriber() > 0
	begin

		if exists(select 1 from #mwReplDeletedPricesTemp)
		begin
			insert into dbo.mwDeleted with(rowlock) (del_key)
			select rdp_pricekey from #mwReplDeletedPricesTemp

			update dbo.mwPriceDataTable with(rowlock)
			set pt_isenabled = 0
			where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey)
		end
	end
end

GO

-- sp_FillMasterWebSearchFields.sql
if exists(select id from sysobjects where xtype='p' and name='FillMasterWebSearchFields')
	drop proc dbo.FillMasterWebSearchFields
go

create procedure [dbo].[FillMasterWebSearchFields](@tokey int, @add smallint = null, @forceEnable smallint = null)
-- if @forceEnable > 0 (by default) then make call mwEnablePriceTour @tokey, 1 at the end of the procedure
as
begin
	set @forceEnable = isnull(@forceEnable, 1)

	if @tokey is null
	begin
		print 'Procedure does not support NULL param'
		return
	end

	update dbo.TP_Tours set TO_Update = 1, TO_Progress = 0, TO_IsEnabled = 1 where TO_Key = @tokey
	update CalculatingPriceLists with(rowlock) set CP_Status = 1 where CP_PriceTourKey = @tokey

	if dbo.mwReplIsSubscriber() > 0
		exec dbo.mwFillTP @tokey

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
		thd_cnname nvarchar(200),
		thd_tourname nvarchar(200),
		thd_hdname nvarchar(200),
		thd_ctname nvarchar(200),
		thd_rsname nvarchar(200),
		thd_ctfromname nvarchar(200),
		thd_cttoname nvarchar(200),
		thd_tourtypename nvarchar(200),
		thd_pncode nvarchar(50),
		thd_hdorder int,
		thd_hotelkeys nvarchar(256),
		thd_pansionkeys nvarchar(256),
		thd_hotelnights nvarchar(256),
		thd_tourvalid datetime,
		thd_hotelurl varchar(254)
	)

	create table #tempPriceTable(
		[pt_mainplaces] [int] NULL ,
		[pt_addplaces] [int] NULL ,
		[pt_main] [smallint] NULL ,
		[pt_tourvalid] [datetime] NULL ,
		[pt_tourcreated] [datetime] NULL ,
		[pt_tourdate] [datetime] NOT NULL,
		[pt_days] [int] NULL ,
		[pt_nights] [int] NULL ,
		[pt_cnkey] [int] NULL ,
		[pt_ctkeyfrom] [int] NULL ,
		[pt_apkeyfrom] [int] NULL ,
		[pt_ctkeyto] [int] NULL ,
		[pt_apkeyto] [int] NULL ,
		[pt_ctkeybackfrom] [int] NULL,
		[pt_ctkeybackto] [int] NULL,
		[pt_tourkey] [int] NOT NULL,
		[pt_tourtype] [int] NULL ,
		[pt_tlkey] [int] NULL ,
		[pt_pricelistkey] [int] NULL ,
		[pt_pricekey] [int] NOT NULL,
		[pt_price] [float] NULL ,
		[pt_hdkey] [int] NULL ,
		[pt_hdpartnerkey] [int] null,
		[pt_rskey] [int] NULL ,
		[pt_ctkey] [int] NULL ,
		[pt_hdstars] [nvarchar] (12) NULL ,
		[pt_pnkey] [int] NULL ,
		[pt_hrkey] [int] NULL ,
		[pt_rmkey] [int] NULL ,
		[pt_rckey] [int] NULL ,
		[pt_ackey] [int] NULL ,
		[pt_childagefrom] [int] NULL ,
		[pt_childageto] [int] NULL ,
		[pt_childagefrom2] [int] NULL ,
		[pt_childageto2] [int] NULL ,
		[pt_hdname] [nvarchar] (60),
		[pt_tourname] [nvarchar] (160),
		[pt_pnname] [nvarchar] (30),
		[pt_pncode] [nvarchar] (3),
		[pt_rmname] [nvarchar] (60),
		[pt_rmcode] [nvarchar] (60),
		[pt_rcname] [nvarchar] (60),
		[pt_rccode] [nvarchar] (40),
		[pt_acname] [nvarchar] (70),
		[pt_accode] [nvarchar] (70),
		[pt_rsname] [nvarchar] (50),
		[pt_ctname] [nvarchar] (50),
		[pt_rmorder] [int] NULL ,
		[pt_rcorder] [int] NULL ,
		[pt_acorder] [int] NULL ,
		[pt_rate] [nvarchar] (3),
		[pt_toururl] [nvarchar] (128),
		[pt_hotelurl] [nvarchar] (254),
		[pt_isenabled] [smallint] NULL,
		[pt_chkey] int null,
		[pt_chbackkey] int null,
		[pt_hdday] int null,
		[pt_hdnights] int null,
		[pt_chday] int null,
		[pt_chpkkey] int null,
		[pt_chprkey] int null,
		[pt_chbackday] int null,
		[pt_chbackpkkey] int null,
		[pt_chbackprkey] int null,
		pt_hotelkeys nvarchar(256),
		pt_hotelroomkeys nvarchar(256),
		pt_hotelstars nvarchar(256),
		pt_pansionkeys nvarchar(256),
		pt_hotelnights nvarchar(256),
		pt_chdirectkeys nvarchar(256) null,
		pt_chbackkeys nvarchar(256) null,
		[pt_topricefor] [smallint] NOT NULL DEFAULT (0),
		pt_tlattribute int null,
		pt_hddetails nvarchar(256) null
	)

	declare @mwAccomodationPlaces nvarchar(254)
	declare @mwRoomsExtraPlaces nvarchar(254)
	declare @mwSearchType int
	declare @sql nvarchar(4000)
	declare @countryKey int
	declare @cityFromKey int

---===========================---
---=== Реализация дозаписи ===---
---=                         =---

	set @add = isnull(@add, 0)

	create table #tmpPrices(
		tpkey int,
		tikey int
	)

	if(@add > 0)
	begin
		set @sql = '
				insert into #tmpPrices 
				select tp_key, tp_tikey 
				from tp_prices
				where tp_tokey = ' + STR(@toKey) + ' and tp_dateend >= getdate()  
						 and not exists 
						(select 1 from '

		if dbo.mwReplIsPublisher() > 0 and len(dbo.mwReplSubscriberDB()) > 0
			set @sql = @sql + '[mw].[' + dbo.mwReplSubscriberDB() + '].'

		set @sql = @sql + 'dbo.mwPriceDataTable with(nolock)
						where pt_tourkey = ' + STR(@toKey) + ' and pt_pricekey = tp_key)'

		exec (@sql)
	end			

---=                         =---
---===                     ===---
---===========================---

	declare @firsthdday int
	select @firsthdday = (select min(ts_day) 
				from tp_services with (nolock)
 				where ts_svkey = 3 and ts_tokey = @toKey)

	update tp_lists with(rowlock)
	set
		ti_firsthotelday = @firsthdday
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours with(rowlock) set TO_Progress = 7 where TO_Key = @tokey

	update TP_Tours with(rowlock) set TO_MinPrice = (
			select min(TP_Gross) 
			from TP_Prices with(nolock) 
				left join TP_Lists with(nolock) on ti_key = tp_tikey
				left join HotelRooms with(nolock) on hr_key = ti_firsthrkey
				
			where TP_TOKey = TO_Key and hr_main > 0 and isnull(HR_AGEFROM, 100) > 16
		)
		where TO_Key = @toKey


	update dbo.TP_Tours with(rowlock) set TO_Progress = 13 where TO_Key = @tokey

	update tp_lists with(rowlock)
	set
		ti_lasthotelday = (select max(ts_day)
				from tp_servicelists  with (nolock)
					inner join tp_services with (nolock) on tl_tskey = ts_key
				where tl_tikey = ti_key and ts_svkey = 3)
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours with(rowlock) set TO_Progress = 20 where TO_Key = @tokey

	update tp_lists with(rowlock)
	set
		ti_totaldays = (select max(case ts_svkey 
						when 3 
						then ts_day + ts_days 
						else (case ts_days 
							when 0 
							then 1 
							else ts_days 
	      						  end) + ts_day - 1 
     					   end)
				from dbo.tp_services with (nolock)
					inner join dbo.tp_servicelists with (nolock) on tl_tskey = ts_key 
				where tl_tikey = ti_key)
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours with(rowlock) set TO_Progress = 30 where TO_Key = @tokey

	update tp_lists with(rowlock)
	set
	-- MEG00024548 Paul G 11.01.2009
	-- изменил логику подсчёта кол-ва ночей в туре
	-- раньше было сумма ночей проживания по всем отелям в туре
	-- теперь если проживания пересекаются, лишние ночи не суммируются
		ti_nights = dbo.mwGetTiNights(ti_key)
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update TP_Tours with(rowlock) set TO_HotelNights = dbo.mwTourHotelNights(TO_Key) where TO_Key = @toKey

	update dbo.TP_Tours with(rowlock) set TO_Progress = 40 where TO_Key = @tokey

	update tp_lists with(rowlock)
		set ti_hotelkeys = dbo.mwGetTiHotelKeys(ti_key),
			ti_hotelroomkeys = dbo.mwGetTiHotelRoomKeys(ti_key),
			ti_hoteldays = dbo.mwGetTiHotelNights(ti_key),
			ti_hotelstars = dbo.mwGetTiHotelStars(ti_key),
			ti_pansionkeys = dbo.mwGetTiPansionKeys(ti_key)
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update tp_lists with(rowlock)
	set
		ti_hdpartnerkey = ts_oppartnerkey,
		ti_firsthotelpartnerkey = ts_oppartnerkey,
		ti_hdday = ts_day,
		ti_hdnights = ts_days
	from tp_servicelists with (nolock)
		inner join tp_services with (nolock) on (tl_tskey = ts_key and ts_svkey = 3)
	where tl_tikey = ti_key and ts_code = ti_firsthdkey and ti_tokey = @toKey and tl_tokey = @toKey
		and ts_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

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

	-- город вылета
	update tp_lists with(rowlock)
	set 
		ti_chkey = (select top 1 ts_code
			from tp_servicelists with(nolock) 
				inner join tp_services with(nolock) on tl_tskey = ts_key and ts_svkey = 1
			where tl_tikey = ti_key and (ts_day <= tp_lists.ti_firsthotelday or (ts_day = 1 and tp_lists.ti_firsthotelday = 0)) and ts_subcode2 = @ctdeparturekey)
	where ti_tokey = @tokey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours with(rowlock) set TO_Progress = 50 where TO_Key = @tokey

	-- город вылета + прямой перелет
	update tp_lists with(rowlock)
	set 
		ti_chday = ts_day,
		ti_chpkkey = ts_oppacketkey,
		ti_chprkey = ts_oppartnerkey
    from tp_servicelists with(nolock) inner join tp_services with(nolock) on tl_tskey = ts_key and ts_svkey = 1
	where	tl_tikey = ti_key 
		and (ts_day <= tp_lists.ti_firsthotelday or (ts_day = 1 and tp_lists.ti_firsthotelday = 0))
		and ts_code = ti_chkey 
		and ts_subcode2 = @ctdeparturekey
		and ti_tokey = @tokey 
		and tl_tokey = @tokey 
		and ts_tokey = @tokey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update tp_lists with(rowlock)
	set 
		ti_ctkeyfrom = tl_ctdeparturekey
	from tp_tours with(nolock)
		inner join tbl_turList with(nolock) on tl_key = to_trkey
	where	ti_tokey = to_key 
		and to_key = @tokey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	-- Проверка наличия перелетов в город вылета
	declare @existBackCharter smallint
	select	@existBackCharter = count(ts_key)
	from	tp_services
		inner join tp_tours with(nolock) on ts_tokey = to_key 
		inner join tbl_turList with(nolock) on tbl_turList.tl_key = to_trkey
	where	ts_tokey = @tokey
		and	ts_svkey = 1
		and ts_ctkey = tl_ctdeparturekey

	-- город прилета + обратный перелет
	update tp_lists with(rowlock) 
	set 
		ti_chbackkey = ts_code,
		ti_chbackday = ts_day,
		ti_chbackpkkey = ts_oppacketkey,
		ti_chbackprkey = ts_oppartnerkey,
		ti_ctkeyto = ts_subcode2
	from tp_servicelists with(nolock)
		inner join tp_services with(nolock) on (tl_tskey = ts_key and ts_svkey = 1)
		inner join tp_tours with(nolock) on ts_tokey = to_key 
--		inner join tbl_turList with(nolock) on tbl_turList.tl_key = to_trkey
	where 
		tl_tikey = ti_key 
		and ts_day > ti_lasthotelday
		and (ts_ctkey = @ctdeparturekey or @existBackCharter = 0)
		and ti_tokey = to_key
		and ti_tokey = @tokey
		and tl_tokey = @tokey
		and ts_tokey = @tokey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	-- _ключ_ аэропорта вылета
	update tp_lists with(rowlock)
	set 
		ti_apkeyfrom = (select top 1 ap_key from airport with(nolock), charter with(nolock) 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chkey)
	where
		ti_tokey = @toKey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	-- _ключ_ аэропорта прилета
	update tp_lists with(rowlock)
	set 
		ti_apkeyto = (select top 1 ap_key from airport with(nolock), charter with(nolock) 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chbackkey)
	where
		ti_tokey = @toKey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	-- ключ города и ключ курорта + звезды
	update tp_lists with(rowlock)
	set
		ti_firstctkey = hd_ctkey,
		ti_firstrskey = hd_rskey,
		ti_firsthdstars = hd_stars
	from hoteldictionary with(nolock)
	where 
		ti_tokey = @toKey and
		ti_firsthdkey = hd_key
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours with(rowlock) set TO_Progress = 60 where TO_Key = @tokey

	if dbo.mwReplIsPublisher() > 0
	begin
		declare @trkey int
		select @trkey = to_trkey from dbo.tp_tours with(nolock) where to_key = @tokey
		
		insert into dbo.mwReplTours with(rowlock) (rt_trkey, rt_tokey, rt_add, rt_date)
		values (@trkey, @tokey, @add, getdate())
		
		update dbo.TP_Tours with(rowlock) set TO_Update = 0, TO_Progress = 100 where TO_Key = @tokey
		
		return
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
		to_isenabled, 
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
	from tp_lists with(nolock)
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
	where to_key = @toKey and to_datevalid >= getdate() and ti_tokey = @toKey and tl_tokey = @toKey and ts_tokey = @toKey
		 and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

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

	if (@add <= 0)
	begin
		delete from dbo.mwSpoDataTable with(rowlock) where sd_tourkey = @tokey
		delete from dbo.mwPriceHotels with(rowlock) where sd_tourkey = @tokey
		delete from dbo.mwPriceDurations with(rowlock) where sd_tourkey = @tokey
	end

	--MEG00026692 Paul G 25.03.2010
	--функции от ti_key должны вызываться на каждую запись из tp_lists
	--поэтому результаты их выполнения записываю в темповую таблицу
	--которую джоиню в последующем селекте
	create table #tempTourInfo (
		tt_tikey int,
		tt_charterto varchar(256),
		tt_charterback varchar(256),
		tt_tourhotels varchar(256)
	)

	insert into #tempTourInfo
	(
		tt_tikey, 
		tt_charterto, 
		tt_charterback, 
		tt_tourhotels
	)
	select 
		ti_key, 
		dbo.mwGetTourCharters(ti_key, 1), 
		dbo.mwGetTourCharters(ti_key, 0), 
		dbo.mwGetTourHotels(ti_key)
	from tp_lists with(nolock)
	where ti_tokey = @toKey
	--End MEG00026692	

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
		pt_hddetails
	)
	select 
			(case when @mwAccomodationPlaces = '0'
				then isnull(rm_nplaces, 0)
				else isnull(ac_nrealplaces, 0) 
			end),
			(case isnull(ac_nmenexbed, -1) 
				when -1 then (case when @mwRoomsExtraPlaces <> '0' then isnull(rm_nplacesex, 0)
							else isnull(ac_nmenexbed, 0)
						end) 
				else isnull(ac_nmenexbed, 0)
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
		to_isenabled,
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
		tt_tourhotels
	from tp_tours with(nolock)
		inner join turList with(nolock) on to_trkey = tl_key
		inner join tp_lists with(nolock) on ti_tokey = to_key
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
		to_key = @toKey and ti_tokey = @toKey and tp_tokey = @toKey
		and (@add <= 0 or tp_key in (select tpkey from #tmpPrices))

	--чтобы не перевыставлялись удаленные цены при выставлении тура в он-лайн
	update #tempPriceTable set pt_isenabled = 0 where exists (select 1 from mwdeleted with (nolock) where del_key = pt_pricekey)

	update dbo.TP_Tours set TO_Progress = 80 where TO_Key = @tokey

	insert into dbo.mwPriceDurations with(rowlock) (
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
	from tp_lists with(nolock) inner join tp_tours with(nolock) on ti_tokey = to_key
	where ti_tokey = @toKey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	-- Даты в поисковой таблице ставим как в таблице туров - чтобы не было двоений MEG00021274
	update mwspodatatable with(rowlock) set sd_tourcreated = to_datecreated from tp_tours with(nolock) where sd_tourkey = to_key and to_key = @tokey

	-- Переписываем данные из временной таблицы и уничтожаем ее
	if @mwSearchType = 0
	begin
		if (@add <= 0)
		begin
			set @sql = 'delete from mwPriceDataTable with(rowlock) where pt_tourkey = ' + cast(@tokey as nvarchar(20))
			exec(@sql)
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

			if (@add <= 0)
			begin
				set @sql = 'delete from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' with(rowlock) where pt_tourkey = ' + cast(@tokey as nvarchar(20))
				exec(@sql)
			end

			exec dbo.mwFillPriceTable '#tempPriceTable', @countryKey, @cityFromKey

			exec dbo.mwCreatePriceTableIndexes @countryKey, @cityFromKey
			fetch next from cur into @countryKey, @cityFromKey
		end		
		close cur
		deallocate cur
	end

	update dbo.TP_Tours set TO_Progress = 90 where TO_Key = @tokey

	insert into dbo.mwPriceHotels with(rowlock) (
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
	insert into mwSpoDataTable with(rowlock)(
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

	update mwPriceHotels with(rowlock) set ph_sdkey = mwsdt.sd_key
		from mwSpoDataTable mwsdt with(nolock)
		where mwsdt.sd_tourkey = mwPriceHotels.sd_tourkey and mwsdt.sd_hdkey = mwPriceHotels.sd_mainhdkey
			and mwsdt.sd_tourkey = @tokey
			and mwPriceHotels.sd_tourkey = @tokey

	-- Указываем на необходимость обновления в таблице минимальных цен отеля
	update mwHotelDetails with(rowlock)
		set htd_needupdate = 1
		where htd_hdkey in (select thd_hdkey from #tmpHotelData)

	if(@forceEnable > 0)
		exec dbo.mwEnablePriceTour @tokey, 1

	if dbo.mwReplIsSubscriber() > 0
	begin
		delete from TP_Prices with(rowlock) where tp_tokey = @tokey
		delete from TP_ServiceLists with(rowlock) where tl_tokey = @tokey
		delete from TP_Services with(rowlock) where ts_tokey = @tokey
		delete from TP_Lists with(rowlock) where ti_tokey = @tokey
		-- don't delete from TP_Tours	
	end

	update CalculatingPriceLists with(rowlock) set CP_Status = 0 where CP_PriceTourKey = @tokey
	update dbo.TP_Tours set TO_Update = 0, TO_Progress = 100, TO_DateCreated = GetDate(), TO_UpdateTime = GetDate() where TO_Key = @tokey
end

go

grant exec on dbo.FillMasterWebSearchFields to public
go

-- sp_mwReindex.sql
if exists(select id from sysobjects where xtype='p' and name='mwReindex')
	drop proc dbo.mwReindex
go

create procedure [dbo].[mwReindex] as
begin
	dbcc dbreindex ('dbo.mwSpoDataTable', '', 70)
	dbcc dbreindex ('dbo.mwPriceHotels', '', 70)
	dbcc dbreindex ('dbo.mwPriceDurations', '', 70)
	dbcc dbreindex ('dbo.TP_Lists', '', 70)
	dbcc dbreindex ('dbo.TP_Prices', '', 70)
	dbcc dbreindex ('dbo.TP_ServiceLists', '', 70)
	dbcc dbreindex ('dbo.TP_Services', '', 70)
	dbcc dbreindex ('dbo.TP_Tours', '', 70)
	dbcc dbreindex ('dbo.TP_TurDates', '', 70)

	declare @mwSearchType int 
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings 
	where SS_ParmName = 'MWDivideByCountry'

	if @mwSearchType = 0
	begin
		dbcc dbreindex ('dbo.mwPriceDataTable', '', 70)
	end
	else
	begin
		declare @sql varchar(4000)
		declare @tableName varchar(50)

		declare cur cursor fast_forward for select distinct name from sysobjects where name like 'mwPriceDataTable[_]%[_]%'
		open cur
		fetch next from cur into @tableName
		while @@fetch_status = 0
			begin
				set @sql = 'dbcc dbreindex (''dbo.' + @tableName + ''', '''', 70)'
--						backup log with truncate_only
--						dbcc shrinkfile(2)'
				exec(@sql)
				fetch next from cur into @tableName
			end		
		close cur
		deallocate cur
	end
end

GO

grant exec on dbo.mwReindex to public

GO

-- sp_mwCleaner.sql
if exists(select id from sysobjects where name='mwCleaner' and xtype='p')
	drop procedure [dbo].[mwCleaner]
go

create proc [dbo].[mwCleaner] as
begin
	-- Удаляем неактуальные туры
	delete from dbo.TP_Tours where to_datevalid < getdate()
	
	-- Удаляем неактуальные цены
	delete from dbo.tp_prices where tp_dateend < getdate() - 1 and tp_tokey not in (select to_key from tp_tours where to_update <> 0)

	update dbo.tp_tours set to_pricecount = 
		(select count(1) from dbo.tp_prices with(nolock) where tp_tokey = to_key) 
	where to_update = 0 and exists(select 1 from dbo.tp_turdates with(nolock) where td_tokey = to_key and td_date < getdate() - 1)

	-- Видимо Антон очепятался с названием функции
	if dbo.mwReplIsSubscriber() <= 0
	begin
		delete from dbo.tp_turdates where td_date < getdate() - 1 and td_tokey not in (select to_key from tp_tours where to_update <> 0)

		delete from dbo.tp_servicelists where tl_tikey not in (select tp_tikey from tp_prices) and tl_tokey not in (select to_key from tp_tours where to_update <> 0)
		delete from dbo.tp_lists where ti_key not in (select tp_tikey from tp_prices) and ti_tokey not in (select to_key from tp_tours where to_update <> 0)
		delete from dbo.tp_services where ts_key not in (select tl_tskey from tp_servicelists) and ts_tokey not in (select to_key from tp_tours where to_update <> 0)
		delete from dbo.tp_tours where to_key not in (select ti_tokey from tp_lists) and to_update = 0
	end

	declare @mwSearchType int
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'

	if(@mwSearchType = 0)
	begin
			delete from dbo.mwPriceDataTable where pt_tourdate < getdate() - 1 and pt_tourkey not in (select to_key from tp_tours where to_update <> 0)
			delete from dbo.mwSpoDataTable where sd_tourkey not in (select pt_tourkey from dbo.mwPriceDataTable) and sd_tourkey not in (select to_key from tp_tours where to_update <> 0)
			delete from dbo.mwPriceDurations where not exists(select 1 from dbo.mwPriceDataTable where pt_tourkey = sd_tourkey and pt_days = sd_days and pt_nights = sd_nights) and sd_tourkey not in (select to_key from tp_tours where to_update <> 0)
	end
	else
	begin
		declare @objName nvarchar(50)
		declare @sql nvarchar(500)
		declare delCursor cursor fast_forward read_only for select distinct sd_cnkey, sd_ctkeyfrom from dbo.mwSpoDataTable
		declare @cnkey int, @ctkeyfrom int
		open delCursor
		fetch next from delCursor into @cnkey, @ctkeyfrom
		while(@@fetch_status = 0)
		begin
			set @objName = dbo.mwGetPriceTableName(@cnkey, @ctkeyfrom)
			set @sql = 'delete from ' + @objName + ' where pt_tourdate < getdate() - 1 and pt_tourkey not in (select to_key from tp_tours where to_update <> 0)'
			exec sp_executesql @sql
			set @sql = 'delete from dbo.mwSpoDataTable where sd_cnkey = ' + ltrim(rtrim(str(@cnkey))) + ' and sd_ctkeyfrom = ' + ltrim(rtrim(str(@ctkeyfrom))) + ' and sd_tourkey not in (select pt_tourkey from ' + @objName + ') and sd_tourkey not in (select to_key from tp_tours where to_update <> 0)'
			exec sp_executesql @sql
			set @sql = 'delete from dbo.mwPriceDurations where sd_cnkey = ' + ltrim(rtrim(str(@cnkey))) + ' and sd_ctkeyfrom = ' + ltrim(rtrim(str(@ctkeyfrom))) + ' and not exists(select 1 from ' + @objName + ' where pt_tourkey = sd_tourkey and pt_days = sd_days and pt_nights = sd_nights) and sd_tourkey not in (select to_key from tp_tours where to_update <> 0)'
			exec sp_executesql @sql
			fetch next from delCursor into @objName
		end
		close delCursor
		deallocate delCursor
	end 

	delete from dbo.mwPriceHotels where sd_tourkey not in (select sd_tourkey from dbo.mwSpoDataTable) and sd_tourkey not in (select to_key from tp_tours where to_update <> 0)
end
go

grant exec on [dbo].[mwCleaner] to public
go

-- sp_mwRemoveDeleted.sql

if exists(select id from sysobjects where name='mwRemoveDeleted' and xtype='p')
	drop procedure [dbo].[mwRemoveDeleted]
go


create proc [dbo].[mwRemoveDeleted] 
	@remove tinyint = 0
as
begin
	set nocount on

	select del_key into #tmpDeleted from dbo.mwDeleted with(nolock)
	declare @name varchar(50)
	declare @sql varchar(8000)
	declare delCur cursor fast_forward read_only 
		for select name from sysobjects with(nolock) where name like 'mwPriceDataTable%' and xtype = 'u'
	open delCur
	fetch next from delCur into @name	
	while(@@fetch_status = 0)
	begin
		set @sql = 'delete from dbo.' + ltrim(@name) + ' with(rowlock) where pt_pricekey in (select del_key from #tmpDeleted)'
		exec(@sql)
		fetch next from delCur into @name
	end

	close delCur
	deallocate delCur

	if dbo.mwReplIsSubscriber() = 0
	begin
		delete from dbo.mwSpoDataTable with(rowlock) where not exists(select top 1 tp_key from tp_prices with(nolock) where tp_tokey = sd_tourkey)
		delete from dbo.mwPriceHotels with(rowlock) where  not exists(select top 1 tp_key from tp_prices with(nolock) where tp_tokey = sd_tourkey)
		delete from dbo.mwPriceDurations with(rowlock) where  not exists(select top 1 tp_key from tp_prices with(nolock) where tp_tokey = sd_tourkey)
	end
	delete from dbo.mwDeleted with(rowlock) where del_key in (select del_key from #tmpDeleted)

	set nocount off
end

GO

grant exec on [dbo].[mwRemoveDeleted] to public
go


-- fn_mwCheckQuotesEx.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesEx]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckQuotesEx]
GO

CREATE function [dbo].[mwCheckQuotesEx](
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
			DEFAULT
		)
	return
end
GO

GRANT SELECT ON [dbo].[mwCheckQuotesEx] TO PUBLIC
GO


-- fn_mwGetTiNights.sql
if exists(select id from sysobjects where xtype='fn' and name='mwGetTiNights')
	drop function dbo.mwGetTiNights
go

create function [dbo].[mwGetTiNights] (@tikey int) returns int 	
as
begin
	declare @nights int,
			@currday int,
			@day int,
			@duration int
	set @nights = 0
	set @currday = 0

	declare curs cursor for
	select ts_day, ts_days
	from tp_servicelists
		inner join tp_services on tl_tskey = ts_key 
	where tl_tikey = @tikey and ts_svkey = 3
	order by ts_day
	open curs

	fetch NEXT from curs
	into @day, @duration

	while @@FETCH_STATUS = 0
	begin
		if @currday <= @day
		begin
			set @nights = @nights + @duration
			set @currday = @day + @duration
		end

		fetch NEXT from curs
		into @day, @duration
	end

	close curs
	deallocate curs

	return @nights
end

GO

grant exec on [dbo].[mwGetTiNights] to public

GO

-- sp_mwcheckquotescycle.sql
if exists(select id from sysobjects where xtype='p' and name='mwCheckQuotesCycle')
	drop proc dbo.mwCheckQuotesCycle
go

create procedure [dbo].[mwCheckQuotesCycle]
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
@findFlight smallint
as
begin

	declare @mwCheckInnerAviaQuotes int
	select @mwCheckInnerAviaQuotes = isnull(SS_ParmValue,0) from dbo.systemsettings 
	where SS_ParmName = 'mwCheckInnerAviaQuotes'

	declare @DYNAMIC_SPO_PAGING smallint
	set @DYNAMIC_SPO_PAGING=3

	declare @tmpHotelQuota varchar(10), @tmpThereAviaQuota varchar(256), @tmpBackAviaQuota varchar(256), @allPlaces int,@places int,@actual smallint,@tmp varchar(256),
			@ptkey int,@hdkey int,@rmkey int,@rckey int,@tourdate datetime,@chkey int,@chbackkey int,@hdday int,@hdnights int,@hdprkey int,	@chday int,@chpkkey int,@chprkey int,@chbackday int,
		@chbackpkkey int,@chbackprkey int,@days int, @rowNum int, @hdStep smallint, @reviewed int,@selected int, @hdPriceCorrection int

	declare @pt_chdirectkeys varchar(256), @pt_chbackkeys varchar(256)
	declare @tmpAllHotelQuota varchar(128),@pt_hddetails varchar(256)

	set @reviewed= @pageNum
	set @selected=0

	declare @now datetime, @percentPlaces float, @pos int
	set @now = getdate()
	set @pos = 0

	fetch next from quotaCursor into @ptkey,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,@chday,@chpkkey,@chprkey,@chbackday,@chbackpkkey,@chbackprkey,@days,@chkey,@chbackkey,@rowNum, @pt_chdirectkeys, @pt_chbackkeys, @pt_hddetails
	while(@@fetch_status=0 and @selected < @pageSize)
	begin
		if @pos >= @pageNum
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
						exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @chbackday
						insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(1,@chkey,0,0,@tourdate,@chday,@days,@chprkey, @chpkkey, @tmpThereAviaQuota)
					end					
					if(len(@tmpThereAviaQuota)=0)
						set @actual=0
				end
				if(@actual > 0)
				begin
					set @tmpBackAviaQuota=null
					if(@chbackkey > 0)
					begin
						select @tmpBackAviaQuota=res from #checked where svkey=1 and code=@chbackkey and date=@tourdate and day=@chbackday and days=@days and prkey=@chbackprkey and pkkey=@chbackpkkey
						if (@tmpBackAviaQuota is null)
						begin
							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chbackkey, @flightGroups, @agentKey, @chbackprkey, @tourdate,@chbackday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chbackpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output, @chday
							insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey, @tmpBackAviaQuota)
						end

						if(len(@tmpBackAviaQuota)=0)
							set @actual=0
					end
				end
			end			
			if(@hotelQuotaMask > 0)
			begin
				if(@actual > 0)
				begin
					set @tmpHotelQuota=null
					set @hdStep = 0
					set @hdPriceCorrection = 0
					select @tmpHotelQuota=res,@places=places,@hdStep=step_index,@hdPriceCorrection=price_correction from #checked where svkey=3 and code=@hdkey and rmkey=@rmkey and rckey=@rckey and date=@tourdate and day=@hdday and days=@hdnights and prkey=@hdprkey
					if (@tmpHotelQuota is null)
					begin
						select @places=qt_places,@allPlaces=qt_allPlaces from dbo.mwCheckQuotesEx(3,@hdkey,@rmkey,@rckey, @agentKey, @hdprkey,@tourdate,@hdday,@hdnights, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 0, 0, 0, 0, 0, @expiredReleaseResult)
						set @tmpHotelQuota=ltrim(str(@places)) + ':' + ltrim(str(@allPlaces))
						if(@pagingType = @DYNAMIC_SPO_PAGING and @places > 0)
						begin
							exec dbo.GetDynamicCorrections @now,@tourdate,3,@hdkey,@rmkey,@rckey,@places, @hdStep output, @hdPriceCorrection output
						end

						insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res,places,step_index,price_correction) values(3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota,@places,@hdStep,@hdPriceCorrection)
					end

					-----------------------------------------------
					--=== Check quotes for all hotels in tour ===--
					--===              [BEGIN]                -----
					if (1 = 1 and @pt_hddetails is not null and charindex(',', @pt_hddetails, 0) > 0)
					begin
						set @tmpAllHotelQuota = ''
						-- Mask for hotel details column :
						-- [HotelKey]:[RoomKey]:[RoomCategoryKey]:[HotelDay]:[HotelDays]:[HotelPartnerKey],...
						declare @curHotelKey int, @curRoomKey int , @curRoomCategoryKey int , @curHotelDay int , @curHotelDays int , @curHotelPartnerKey int

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
							exec mwParseHotelDetails @curHotelDetails, @curHotelKey output, @curRoomKey output, @curRoomCategoryKey output, @curHotelDay output, @curHotelDays output, @curHotelPartnerKey output

							-----
											set @curHotelQuota = null
											select @curHotelQuota=res from #checked where svkey=3 and code=@curHotelKey and rmkey=@curRoomKey and rckey=@curRoomCategoryKey and date=@tourdate and day=@curHotelDay and days=@curHotelDays and prkey=@curHotelPartnerKey
											if (@curHotelQuota is null)
											begin
												select @tempPlaces=qt_places,@tempAllPlaces=qt_allPlaces from dbo.mwCheckQuotesEx(3,@curHotelKey,@curRoomKey,@curRoomCategoryKey, @agentKey, @hdprkey,@tourdate,@hdday,@hdnights, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 0, 0, 0, 0, 0, @expiredReleaseResult)
												set @curHotelQuota=ltrim(str(@tempPlaces)) + ':' + ltrim(str(@tempAllPlaces))

												insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res,places) values(3,@curHotelKey,@curRoomKey,@curRoomCategoryKey,@tourdate,@curHotelDay,@curHotelDays,@curHotelPartnerKey,0,@curHotelQuota,@tempPlaces)
											end
							-----
							set @tmpAllHotelQuota = @tmpAllHotelQuota + @curHotelQuota + '|'

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
					
					if((@places > 0 and (@hotelQuotaMask & 1)=0) or (@places=0 and (@hotelQuotaMask & 2)=0) or (@places=-1 and (@hotelQuotaMask & 4)=0))
						set @actual=0
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
					exec dbo.mwCheckFlightGroupsQuotesWithInnerFlights @pagingType, @pt_chdirectkeys, 
							@flightGroups, @agentKey, @tourdate, @requestOnRelease, @noPlacesResult, 
							@checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, 
							@days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @pt_chbackkeys
					if (len(@tmpThereAviaQuota) = 0)
						set @actual = 0
				end 

				-- Back flights
				if(@actual > 0)
				begin
					if (@pt_chbackkeys is not null and charindex(',', @pt_chbackkeys, 0) > 0)
					begin
						exec dbo.mwCheckFlightGroupsQuotesWithInnerFlights @pagingType, @pt_chbackkeys,   
							@flightGroups, @agentKey, @tourdate, @requestOnRelease, @noPlacesResult, 
							@checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, 
							@days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output, @pt_chdirectkeys
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
				set @selected=@selected + 1
				insert into #Paging(ptKey,pt_hdquota,pt_chtherequota,pt_chbackquota,chkey,chbackkey,stepId,priceCorrection, pt_hdallquota)
				values(@ptkey,@tmpHotelQuota,@tmpThereAviaQuota,@tmpBackAviaQuota,@chkey,@chbackkey,@hdStep,@hdPriceCorrection, @tmpAllHotelQuota)
			end

			set @reviewed=@reviewed + 1
		end
		fetch next from quotaCursor into @ptkey,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,@chday,@chpkkey,@chprkey,@chbackday,@chbackpkkey,@chbackprkey,@days,@chkey,@chbackkey,@rowNum, @pt_chdirectkeys, @pt_chbackkeys, @pt_hddetails
		set @pos = @pos + 1
	end

	select @reviewed
end
go

grant exec on dbo.mwCheckQuotesCycle to public
go

-- sp_mwGetServiceVariants.sql
if exists(select id from sysobjects where xtype='p' and name='mwGetServiceVariants')
	drop proc dbo.mwGetServiceVariants
go

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

	declare @selectClause varchar(300)
	set		@selectClause = ' SELECT cs1.CS_Code, cs1.CS_SubCode1, cs1.CS_SubCode2, cs1.CS_PrKey, cs1.CS_PkKey, cs1.CS_Profit, cs1.CS_Type, cs1.CS_Discount, cs1.CS_Creator, cs1.CS_Rate, cs1.CS_Cost '
	
	declare @fromClause varchar(300)
	set		@fromClause   = ' FROM COSTS cs1 '
	set		@additionalFilter = replace(@additionalFilter, 'CS_', 'cs1.CS_')
				
	declare @whereClause varchar(6000)
		set @whereClause  = ''
	
	--MEG00027493 Paul G 15.07.2010
	if (@showCalculatedCostsOnly=1)
	begin
		set @whereClause = @whereClause +
			'EXISTS(SELECT 1 FROM TP_SERVICES WHERE TS_CODE=cs1.CS_CODE 
				AND TS_SVKEY=cs1.CS_SVKEY 
				AND TS_SUBCODE1=cs1.CS_SUBCODE1 
				AND TS_SUBCODE2=cs1.CS_SUBCODE2 
				AND TS_OPPARTNERKEY=cs1.CS_PRKEY
				AND TS_OPPACKETKEY=cs1.CS_PKKEY
				AND TS_TOKEY=(SELECT TO_KEY FROM TP_TOURS WHERE TO_TRKEY='+ convert(varchar(50), @tourKey) +')) AND 
			'
	end
	
	if (@svKey=1)
	begin
		set @whereClause = @whereClause + ' cs1.CS_SVKEY = ' + CAST(@svKey as varchar)
		set @whereClause = @whereClause + ' AND cs1.CS_PKKEY = '+cast(@pkKey as varchar)
		set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATE, ''1900-01-01'') <=    ''' + @dateBegin + ''''
		set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATEEND, ''9000-01-01'') >= ''' + @dateBegin + ''''
		set @whereClause = @whereClause + ' AND (cs1.CS_LONG >= ' + cast(@tourNDays as varchar) + ' OR cs1.CS_LONG is NULL)' 
		set @whereClause = @whereClause + ' AND EXISTS (SELECT CH_KEY FROM CHARTER ' 
										+ ' WHERE CH_KEY = cs1.CS_CODE AND CH_CITYKEYFROM = ' + cast(@cityFromKey as varchar) + ' AND CH_CITYKEYTO = '+cast(@cityToKey as varchar)+')'
		-- Filter on day of week
		set @whereClause = @whereClause + ' AND (cs1.CS_WEEK is null or cs1.CS_WEEK = '''' or cs1.CS_WEEK like dbo.GetWeekDays(''' + @dateBegin + ''',''' + @dateBegin + '''))'
		-- Filter on CHECKIN DATE
		set @whereClause = @whereClause + ' AND ''' + @dateBegin + ''' BETWEEN ISNULL(cs1.CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(cs1.CS_CHECKINDATEEND, ''9000-01-01'') ' + @additionalFilter + ' order by cs1.CS_long'
	end
	else if (@serviceDays>1)
	begin
		set @whereClause = @whereClause + ' cs1.CS_SVKEY = '+cast (@svKey as varchar)+' AND cs1.CS_PKKEY = '+cast(@pkKey as varchar)
		
		-- Спорный момент, но иначе не работает вариант, когда изначально берется цена с cs_long < @serviceDays, а потом добивается другими квотами с конца
		--set @whereClause = @whereClause + ' AND ' + cast(@serviceDays as varchar) + ' between isnull(cs1.CS_longmin, -1) and isnull(cs1.CS_long, 10000)'
		set @whereClause = @whereClause + ' AND ' + cast(@serviceDays as varchar) + ' >= isnull(cs1.CS_longmin, -1)'
		set @whereClause = @whereClause + ' AND ''' + @dateBegin + ''' BETWEEN ISNULL(cs1.CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(cs1.CS_CHECKINDATEEND, ''9000-01-01'') ' + @additionalFilter
		
		-- Exclude services that not have cost at last service day
		set @fromClause = @fromClause + ' INNER JOIN COSTS cs2 ON cs1.CS_CODE = cs2.CS_CODE AND cs1.CS_SUBCODE1 = cs2.CS_SUBCODE1 AND cs1.CS_SUBCODE2 = cs2.CS_SUBCODE2'
		set @whereClause = @whereClause + ' AND ' + replace(@whereClause, 'cs1.', 'cs2.')
		set @whereClause = @whereClause + ' AND ISNULL(cs2.CS_DATE,    ''1900-01-01'') <= ''' + cast(dateadd(day, @serviceDays - 1, cast(@dateBegin as datetime)) as varchar) + ''''
		set @whereClause = @whereClause + ' AND ISNULL(cs2.CS_DATEEND, ''9000-01-01'') >= ''' + cast(DATEADD(day, @serviceDays - 1, cast(@dateBegin as datetime)) as varchar) + ''''
		
		-- Раньше здесь к @dateBegin прибавлялся еще один день, по-моему это неправильно
		set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATE,    ''1900-01-01'') <= ''' + @dateBegin + ''''
		set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATEEND, ''9000-01-01'') >= ''' + @dateBegin + ''''
		
		set @whereClause = @whereClause + ' order by cs1.CS_UPDDATE DESC'
	end
	else
	begin
		set @whereClause = @whereClause + ' cs1.CS_SVKEY = '+cast (@svKey as varchar)+' AND cs1.CS_PKKEY = '+cast(@pkKey as varchar)
		set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATE, ''1900-01-01'')    <= ''' + @dateBegin + ''''
		set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATEEND, ''9000-01-01'') >= ''' + @dateBegin + ''''
		set @whereClause = @whereClause + ' AND ' + cast(@serviceDays as varchar) + ' between isnull(cs1.CS_longmin, -1) and isnull(cs1.CS_long, 10000)';
		set @whereClause = @whereClause + ' AND ''' + @dateBegin + ''' BETWEEN ISNULL(cs1.CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(cs1.CS_CHECKINDATEEND, ''9000-01-01'') ' + @additionalFilter + ' order by cs1.CS_long'
	end

	exec (@selectClause + @fromClause + ' WHERE ' + @whereClause)

end
go

grant exec on dbo.mwGetServiceVariants to public
go


-- sp_mwHotelQuotes.sql
if exists(select id from sysobjects where name='mwHotelQuotes' and xtype='p')
	drop procedure [dbo].[mwHotelQuotes]
go

create PROCEDURE [dbo].[mwHotelQuotes]
	@Filter varchar(2000),
	@DaysCount int,
	@AgentKey int, 
	@FromDate	datetime,
	@RequestOnRelease smallint,
	@NoPlacesResult int,
	@CheckAgentQuotes smallint,
	@CheckCommonQuotes smallint,
	@ExpiredReleaseResult int
AS

---=== СОЗДАНИЕ ВРЕМЕННОЙ ТАБЛИЦЫ ===---
CREATE TABLE #tmp
(
	CityKey int,
	CityName varchar(50) COLLATE Cyrillic_General_BIN,
	HotelKey int,
	HotelName varchar(200) COLLATE Cyrillic_General_BIN,
	HotelHTTP varchar(254),
	RoomKey int,
	RoomName varchar(35) COLLATE Cyrillic_General_BIN,
	RoomCategoryKey int,
	RoomCategoryName varchar(60) COLLATE Cyrillic_General_BIN,
	Quotas varchar(2000)
)

---=== ФОРМИРОВАНИЕ ДАННЫХ ===---
DECLARE	@HotelKey int
DECLARE	@RoomKey int 
DECLARE	@RoomCategoryKey int 

DECLARE @script VARCHAR(4000)
SET @script = 'SELECT DISTINCT SD_CTKEY, SD_CTNAME, mwSpoDataTable.SD_HDKEY, SD_HDNAME  + '' ('' + ISNULL(SD_RSNAME, SD_CTNAME) + '') '' + mwSpoDataTable.SD_HDSTARS as HotelName, ISNULL(HD_HTTP, ''''), SD_RMKEY, RM_NAME, SD_RCKEY, RC_NAME, ''''
	FROM mwPriceHotels with(nolock)
		JOIN mwSpoDataTable with(nolock) ON mwPriceHotels.PH_SDKEY = mwSpoDataTable.SD_KEY
		JOIN Rooms with(nolock) ON SD_RMKEY = RM_KEY		
		JOIN RoomsCategory with(nolock) ON SD_RCKEY = RC_KEY
		JOIN HotelDictionary with(nolock) ON mwSpoDataTable.SD_HDKEY = HD_KEY
		WHERE ' + @filter + ' ORDER BY HotelName'

INSERT INTO #tmp
	EXEC(@script)

DECLARE hSql CURSOR 
	FOR 
		SELECT HotelKey, RoomKey, RoomCategoryKey FROM #tmp
	FOR UPDATE OF Quotas

OPEN hSql
FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey

WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE #tmp SET Quotas = (select top 1 qt_additional from mwCheckQuotesEx(3, @HotelKey, @RoomKey, @RoomCategoryKey, @AgentKey, -1, @FromDate, 1, @DaysCount, @RequestOnRelease, @NoPlacesResult, @CheckAgentQuotes, @CheckCommonQuotes, 1, 0, 0, 0, 0, -1, @ExpiredReleaseResult))
		WHERE current of hSql
	FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey
END
CLOSE hSql
DEALLOCATE hSql

SELECT * FROM #tmp

---=== УДАЛЕНИЕ ВРЕМЕННОЙ ТАБЛИЦЫ ===---
DROP TABLE  #tmp
go

grant exec on [dbo].[mwHotelQuotes] to public
go


-- sp_paging.sql
if exists(select id from sysobjects where xtype='p' and name='Paging')
	drop proc dbo.Paging
go

create procedure [dbo].[Paging]
@pagingType	smallint=2,
@countryKey	int,
@departFromKey	int,
@filter		varchar(4000),
@sortExpr	varchar(1024),
@pageNum	int=0,		-- номер страницы(начиная с 1 или количество уже просмотренных записей для исключения при @pagingType=@ACTUALPLACES_PAGING)
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
@checkAllPartnersQuota smallint = null
AS
set nocount on

/******************************************************************************
**		Parameters:

		@filter		varchar(1024),	 - поисковый фильтр (where-фраза)
		@sortExpr	varchar(1024),	 - выражение сортировки
		@pageNum	int=1,	 - № страницы
		@pageSize	int=9999	 - размер страницы
		@transform	smallint=0	 - преобразовывать ли полученные данные для расположения продолжительностей по горизонтали
*******************************************************************************/

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
			price_correction int
		)
end

declare @sql varchar(8000)
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
--	print @sql
	insert into #days exec(@sql)

	declare @sKeysSelect varchar(2024)
	set @sKeysSelect=''
	declare @sAlter varchar(2024)
	set @sAlter=''

	if(@hotelQuotaMask > 0 or @aviaQuotaMask > 0)
	begin
		create table #resultsTable(
			paging_id int,
			pt_key int,
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
			pt_actual smallint
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

		insert into #resultsTable exec PagingSelect @pagingType,@sKeysSelect,@spageNum,@spageSize,@filter,@sortExpr,@tableName,@viewName, @rowCount output
		select @rowCount

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
							from ' + @tableName + '
							where pt_key in (' + @sAddIN + ')'
			end
			else if (@pagingType = 0)
			begin
				set @sTmp = 'select pt_key, pt_pricekey, pt_tourdate, pt_days,	pt_nights, pt_hdkey, pt_hdday,
									pt_hdnights, pt_hdpartnerkey, pt_rmkey,	pt_rckey, pt_chkey,	pt_chday, pt_chpkkey,
									pt_chprkey, pt_chbackkey, pt_chbackday, pt_chbackpkkey, pt_chbackprkey, null, null, null, null
							from ' + @tableName + '
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
							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @days, @expiredReleaseResult,@aviaMask, @tmpThereAviaQuota output
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
			pt_hdquota varchar(10),
			pt_chtherequota varchar(256),
			pt_chbackquota varchar(256),
			chkey int,
			chbackkey int,
			stepId int,
			priceCorrection float,
			pt_hdallquota varchar(256)
		)
		
		if((@pagingType <> @ACTUALPLACES_PAGING and @pagingType <> @DYNAMIC_SPO_PAGING) or (@hotelQuotaMask <= 0 and @aviaQuotaMask <= 0))
			set @sql=@sql + ' 
			insert into #Paging(ptkey) select ' 
		else
		begin

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
	
		set @sql=@sql + ' pt_key '
		if((@pagingType=@ACTUALPLACES_PAGING or @pagingType=@DYNAMIC_SPO_PAGING) and (@hotelQuotaMask > 0 or @aviaQuotaMask > 0))
		begin
			set @sql=@sql + ',pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,pt_hdday,pt_hdnights, (case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chpkkey else -1 end) as pt_chpkkey,pt_chprkey,pt_chbackday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey,pt_chbackprkey,pt_days, '
			if(@pagingType <> @DYNAMIC_SPO_PAGING)
				set @sql = @sql + ' pt_chkey, pt_chbackkey, 0, pt_chdirectkeys, pt_chbackkeys, pt_hddetails '
			else
				set @sql = @sql + ' ch_key as pt_chkey, chb_key as pt_chbackkey, row_number() over(order by ' + @sortExpr + ') as rowNum '
		end
		set @sql=@sql + ' from ' + @tableName + ' with(nolock) '

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
	
		if (len(isnull(@sortExpr,'')) > 0 and @pagingType <> @DYNAMIC_SPO_PAGING)
			set @sql=@sql + ' order by '+ @sortExpr

		if(@pagingType=@ACTUALPLACES_PAGING or @pagingType=@DYNAMIC_SPO_PAGING)
		begin
			if (@pageNum=0) -- количество записей возвращаем только при запросе первой страницы
			begin
				set @sql=@sql + ' 
				select count(*) from ' + @tableName + ' with(nolock) '

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

				exec dbo.mwCheckQuotesCycle ' + ltrim(str(@pagingType))+ ', ' + @spageNum + ', ' + @spageSize + ', ' + ltrim(str(@agentKey)) + ', ' + ltrim(str(@hotelQuotaMask)) + ', ' + ltrim(str(@aviaQuotaMask)) + ', ''' + @flightGroups + ''', ' + ltrim(str(@checkAgentQuota)) + ', ' + ltrim(str(@checkCommonQuota)) + ', ' + ltrim(str(@checkNoLongQuota)) + ', ' + ltrim(str(@requestOnRelease)) + ', ' + ltrim(str(@expiredReleaseResult)) + ', ' + ltrim(str(@noPlacesResult)) + ', ' + ltrim(str(@findFlight)) + '

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
		pt_pricekey,
		pt_price,
		pt_hdkey,
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
		pt_topricefor,
		pt_key,
		pt_hddetails,'

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


	if(@getServices > 0)
		set @sql=@sql + ',dbo.mwGetServiceClasses(pt_pricelistkey) pt_srvClasses'
	if(@hotelQuotaMask > 0)
		set @sql=@sql + ',pt_hdquota,pt_hdallquota '
	if(@aviaQuotaMask > 0)
		set @sql=@sql + ',pt_chtherequota,pt_chbackquota '

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
	
					select * from #resultsTable
				'
			end
			else
				set @sql=@sql + ' order by pgId '

	end

exec (@sql)
end
go

grant exec on dbo.Paging to public
go

-- sp_DogListToQuotas.sql
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogListToQuotas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogListToQuotas]


GO
CREATE PROCEDURE [dbo].[DogListToQuotas]
(
--<VERSION>2008.1.02.28a</VERSION>
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
	@SetQuotaDateFirst datetime = null
) AS

--insert into Debug (db_n1, db_n2, db_n3) values (@DLKey, @SetQuotaType, 999)
declare @SVKey int, @Code int, @SubCode1 int, @PRKey int, @AgentKey int, 
		@TourDuration int, @FilialKey int, @CityDepartment int,
		@ServiceDateBeg datetime, @ServiceDateEnd datetime, @Pax smallint, @IsWait smallint,@SVQUOTED smallint

SELECT	@SVKey=DL_SVKey, @Code=DL_Code, @SubCode1=DL_SubCode1, @PRKey=DL_PartnerKey, 
		@ServiceDateBeg=DL_DateBeg, @ServiceDateEnd=DL_DateEnd, @Pax=DL_NMen,
		@AgentKey=DG_PartnerKey, @TourDuration=DG_NDay, @FilialKey=DG_FilialKey, @CityDepartment=DG_CTDepartureKey, @IsWait=ISNULL(DL_Wait,0)
FROM	DogovorList, Dogovor 
WHERE	DL_DGKey=DG_Key and DL_Key=@DLKey

if @IsWait=1 and (@SetQuotaType in (1,2) or @SetQuotaType is null)  --Установлен признак "Не снимать квоту при бронировании". На квоту не ставим
BEGIN
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
	return 0
END
SELECT @SVQUOTED=isnull(SV_Quoted,0) from service where sv_key=@SVKEY
if @SVQUOTED=0
BEGIN
	UPDATE ServiceByDate SET SD_State=3 WHERE SD_DLKey=@DLKey
	return 0
END

-- ДОБАВЛЕНА НАСТРОЙКА ЗАПРЕЩАЮЩАЯ СНЯТИЕ КВОТЫ ДЛЯ УСЛУГИ, 
-- ТАК КАК В КВОТАХ НЕТ РЕАЛЬНОЙ ИНФОРМАЦИИ, А ТОЛЬКО ПРИЗНАК ИХ НАЛИЧИЯ (ПЕРЕДАЕТСЯ ИЗ INTERLOOK)
IF (@SetQuotaType in (1,2) or @SetQuotaType is null) and  EXISTS (SELECT 1 FROM dbo.SystemSettings WHERE SS_ParmName='IL_SyncILPartners' and SS_ParmValue LIKE '%/' + CAST(@PRKey as varchar(20)) + '/%')
BEgin
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null	
	return 0
End


/*
If @SVKey=3
	SELECT TOP 1 @Quota_SubCode1=HR_RMKey, @Quota_SubCode2=HR_RCKey FROM HotelRooms WHERE HR_Key=@SubCode1
Else
	Set @Quota_SubCode1=@SubCode1
*/
declare @Q_Count smallint, @Q_AgentKey int, @Q_Type smallint, @Q_ByRoom bit, 
		@Q_PRKey int, @Q_FilialKey int, @Q_CityDepartments int, @Q_Duration smallint, @Q_DateBeg datetime, @Q_DateEnd datetime, @Q_DateFirst datetime, @Q_SubCode1 int, @Q_SubCode2 int,
		@Query varchar(8000), @SubQuery varchar(1500), @Current int, @CurrentString varchar(50), @QTCount_Need smallint, @n smallint, @n2 smallint, @Result_Exist bit, @nTemp smallint, @dTemp datetime
--Если идет полная постановка услуги на квоту (@SetQuotaType is null) обычно после бронирования
--Или прошло удаление какой-то квоты и сейчас требуется освободить эту квоту и занять другую
--То требуется найти оптимально подходящую квоту и ее использовать

If @SetQuotaType is null or @SetQuotaType<0 --! @SetQuotaType<0 <--при переходе на 2008.1
BEGIN
	IF @SetQuotaCheck=1 
		UPDATE ServiceByDate SET SD_State=null, SD_QPID=null where SD_DLKey=@DLKey and SD_RPID in (SELECT DISTINCT SD_RPID FROM QuotaDetails,QuotaParts,ServiceByDate WHERE SD_QPID=QP_ID and QP_QDID=QD_ID and QD_IsDeleted=1 and SD_DLKey=@DLKey)
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
			Select @Q_Type=QD_Type from QuotaDetails,QuotaParts Where QP_QDID=QD_ID and QP_ID=@SetQuotaQPID
	END
	Else
		Set @Q_Type=null		
	--@SetQuotaQPID это конкретная квота, ее заполнение возможно только из режима ручного постановки услуги на квоту
	IF @SetQuotaByRoom=1 and @SVKey=3
	BEGIN
		if @SetQuotaRLKey is null
			UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=@SetQuotaQPID where SD_DLKey=@DLKey and SD_Date between @SetQuotaDateBeg and @SetQuotaDateEnd
		else
			UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=@SetQuotaQPID where SD_DLKey=@DLKey and SD_RLID=@SetQuotaRLKey and SD_Date between @SetQuotaDateBeg and @SetQuotaDateEnd
	END
	ELSE
	BEGIN
		if @SetQuotaRPKey is null
			UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=@SetQuotaQPID where SD_DLKey=@DLKey and SD_Date between @SetQuotaDateBeg and @SetQuotaDateEnd
		else
			UPDATE ServiceByDate SET SD_State=@Q_Type, SD_QPID=@SetQuotaQPID where SD_DLKey=@DLKey and SD_RPID=@SetQuotaRPKey and SD_Date between @SetQuotaDateBeg and @SetQuotaDateEnd
	END
	IF @SetQuotaType=4 or @SetQuotaType=3 or @SetQuotaQPID is not null --собственно выход (либо не надо ставить на квоту либо квота конкретная)
		return 0

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

If not exists (SELECT * FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_State is null)
	print 'WARNING_DogListToQuotas_1'
If @Q_Count is null
	print 'WARNING_DogListToQuotas_2'
If @Result_Exist > 0
	print 'WARNING_DogListToQuotas_3'

--print 'sddddd0'
WHILE exists (SELECT * FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_State is null) and @n<5 and (@Q_Count is not null or @Result_Exist=0)
BEGIN
	--print @n
	set @n=@n+1
	Set @SubQuery = ' QT_ID=QD_QTID and QP_QDID=QD_ID
				and QD_Type=' + CAST(@Q_Type as varchar(10)) + ' and QT_ByRoom=' + CAST(@Q_ByRoom as varchar(10)) + '
				and QD_IsDeleted is null and QP_IsDeleted is null
				and QO_QTID=QT_ID and QO_SVKey=' + CAST(@SVKey as varchar(10)) +' and QO_Code=' + CAST(@Code as varchar(10)) +' and QO_SubCode1=' + CAST(@Q_SubCode1 as varchar(10))
	IF @SVKey=3
		Set @SubQuery=@SubQuery+' and QO_SubCode2=' + CAST(@Q_SubCode2 as varchar(10))
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

	IF @Q_PRKey is null
		SET @SubQuery = @SubQuery + ' and QT_PRKey is null'
	ELSE
		SET @SubQuery = @SubQuery + ' and QT_PRKey=' + CAST(@Q_PRKey as varchar(10))
	IF @Q_Duration=0
		SET @SubQuery = @SubQuery + ' and QP_Durations='''' '
	ELSE
		SET @SubQuery = @SubQuery + ' and QP_ID in (Select QL_QPID From QuotaLimitations Where QL_Duration=' + CAST(@Q_Duration as varchar(5)) + ') ' 	

	Set @Query = '
		DECLARE @n1 smallint, @n2 smallint, @CurrentDate smalldatetime, @Long smallint, @prev bit, @durations_prev varchar(25), @release_prev smallint, @QP_ID int, @SK_Current int, @Temp smallint, @Error bit
		DECLARE @ServiceKeys Table 	(SK_ID int identity(1,1), SK_Key int, SK_QPID int, SK_Date smalldatetime )'

	IF @SetQuotaType is null or @SetQuotaType<0 --! @SetQuotaType<0 <--при переходе на 2008.1
		Set @Query = @Query+'
			INSERT INTO @ServiceKeys (SK_Key,SK_Date) SELECT DISTINCT ' + CASE @Q_ByRoom WHEN 1 THEN 'SD_RLID' ELSE 'SD_RPID' END +', SD_Date FROM ServiceByDate WHERE SD_DLKey=' + CAST(@DLKey as varchar(10)) +' and SD_State is null'
	ELSE IF @Q_ByRoom=1
		Set @Query = @Query+'
			INSERT INTO @ServiceKeys (SK_Key,SK_Date) SELECT DISTINCT SD_RLID, SD_Date FROM ServiceByDate WHERE SD_DLKey=' + CAST(@DLKey as varchar(10)) +' and SD_RLID=' + CAST(@SetQuotaRLKey as varchar(10)) + '	and SD_State is null'
	ELSE IF @Q_ByRoom=0
		Set @Query = @Query+'
			INSERT INTO @ServiceKeys (SK_Key,SK_Date) SELECT DISTINCT SD_RPID, SD_Date FROM ServiceByDate WHERE SD_DLKey=' + CAST(@DLKey as varchar(10)) +' and SD_RPID=' + CAST(@SetQuotaRPKey as varchar(10)) + ' and SD_State is null'

		Set @Query = @Query+'
			--SELECT * FROM @ServiceKeys
			SET @CurrentDate=''' + CAST(@Q_DateBeg as varchar(20)) + '''
			SET @Long=DATEDIFF(DAY,''' + CAST(@Q_DateBeg as varchar(20)) + ''',''' + CAST(@Q_DateEnd as varchar(20)) + ''')+1
			SET @Error=0
			SELECT @SK_Current=MIN(SK_Key) FROM @ServiceKeys WHERE SK_QPID is null
			WHILE @SK_Current is not null and @Error=0
			BEGIN
				SET @n1=1
				WHILE @n1<=@Long and @Error=0
				BEGIN
					SET @QP_ID=null
					SET @n2=0
					WHILE (@QP_ID is null) and @n2<2
					BEGIN
						DECLARE @DATETEMP datetime
						SET @DATETEMP = GetDate()
						if exists (select SS_ParmValue from systemsettings where SS_ParmName=''SYSCheckQuotaRelease'' and SS_ParmValue=1) OR exists (select SS_ParmValue from systemsettings where SS_ParmName=''SYSAddQuotaPastPermit'' and SS_ParmValue=1)
							SET @DATETEMP=''10-JAN-1900''
						IF @prev=1'
		Set @Query = @Query + '	SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release
								FROM QuotaParts QP1, QuotaDetails QD1, Quotas QT1, QuotaObjects
								WHERE ' + @SubQuery + ' and QD_Date=DATEADD(DAY,@n1-1,@CurrentDate)
									and (QP_Places-QP_Busy)>0 and QP_Durations=@durations_prev and QD_Release=@release_prev
									and (isnull(QP_Durations, '''') = '''' or (isnull(QP_Durations, '''') != '''' and QP_IsNotCheckIn = 1) or (isnull(QP_Durations, '''') != '''' and QD_Date = ''' + CAST(@Q_DateFirst as varchar(20)) + '''))
									and ((QP_IsNotCheckIn = 0) 
											or (QP_IsNotCheckIn = 1 
												and exists (select 1 
															from QuotaDetails as tblQD
															where exists (select 1 
																			from QuotaParts as tblQP 
																			where tblQP.QP_QDID = tblQD.QD_ID
																			--and tblQP.QP_ID = QP1.QP_ID
																			and tblQP.QP_IsNotCheckIn = 0)
															and tblQD.QD_Date = ''' + CAST(@Q_DateFirst as varchar(20)) + '''
															and tblQD.QD_QTID = QD1.QD_QTID)))
									and not exists (SELECT SS_ID FROM StopSales WHERE SS_QDID=QD_ID and SS_QOID=QO_ID and SS_Date=DATEADD(DAY,@n1-1,@CurrentDate) and (SS_IsDeleted is null or SS_IsDeleted=0))
									and not exists (SELECT QP_ID FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2 
									WHERE ' + @SubQuery + ' and QD2.QD_Date=''' + CAST(@Q_DateFirst as varchar(20)) + '''
										and ISNULL(QD2.QD_Release,0)=ISNULL(QD1.QD_Release,0) and QP2.QP_Durations=QP1.QP_Durations and (QP_IsNotCheckIn=1 or QP_CheckInPlaces-QP_CheckInPlacesBusy <= 0))
										and QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1)			
								ORDER BY ISNULL(QD_Release,0) DESC, (select count(distinct QD_QTID) 
																	from QuotaDetails as QDP join QuotaParts as QPP on QDP.QD_ID = QPP.QP_QDID
																	where exists (select 1 from @ServiceKeys as SKP where SKP.SK_QPID = QPP.QP_ID)
																	and QDP.QD_QTID = QD1.QD_QTID) DESC
			ELSE'
		Set @Query = @Query + '	SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release
								FROM QuotaParts QP1, QuotaDetails QD1, Quotas QT1, QuotaObjects
								WHERE ' + @SubQuery + ' and QD_Date=DATEADD(DAY,@n1-1,@CurrentDate)
									and (QP_Places-QP_Busy)>0 
									and (isnull(QP_Durations, '''') = '''' or (isnull(QP_Durations, '''') != '''' and QP_IsNotCheckIn = 1) or (isnull(QP_Durations, '''') != '''' and QD_Date = ''' + CAST(@Q_DateFirst as varchar(20)) + '''))
									and ((QP_IsNotCheckIn = 0) 
											or (QP_IsNotCheckIn = 1 
												and exists (select 1 
															from QuotaDetails as tblQD
															where exists (select 1 
																			from QuotaParts as tblQP 
																			where tblQP.QP_QDID = tblQD.QD_ID
																			--and tblQP.QP_ID = QP1.QP_ID
																			and tblQP.QP_IsNotCheckIn = 0)
															and tblQD.QD_Date = ''' + CAST(@Q_DateFirst as varchar(20)) + '''
															and tblQD.QD_QTID = QD1.QD_QTID)))
									and not exists (SELECT SS_ID FROM StopSales WHERE SS_QDID=QD_ID and SS_QOID=QO_ID and SS_Date=DATEADD(DAY,@n1-1,@CurrentDate) and (SS_IsDeleted is null or SS_IsDeleted=0))
									and not exists (SELECT QP_ID FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2
									WHERE ' + @SubQuery + ' and QD2.QD_Date=''' + CAST(@Q_DateFirst as varchar(20)) + '''
										and ISNULL(QD2.QD_Release,0)=ISNULL(QD1.QD_Release,0) and QP2.QP_Durations=QP1.QP_Durations and (QP_IsNotCheckIn=1 or QP_CheckInPlaces-QP_CheckInPlacesBusy <= 0))
										and QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1)
								ORDER BY ISNULL(QD_Release,0) DESC, (select count(distinct QD_QTID) 
																	from QuotaDetails as QDP join QuotaParts as QPP on QDP.QD_ID = QPP.QP_QDID
																	where exists (select 1 from @ServiceKeys as SKP where SKP.SK_QPID = QPP.QP_ID)
																	and QDP.QD_QTID = QD1.QD_QTID) DESC

							SET @n2=@n2+1
						IF @QP_ID is null
							SET @prev=1				
						ELSE
							UPDATE @ServiceKeys SET SK_QPID=@QP_ID WHERE SK_Key=@SK_Current and SK_Date=DATEADD(DAY,@n1-1,@CurrentDate)	
					END
					If @QP_ID is null
						SET @Error=1
					SET @n1=@n1+1
				END
				IF @Error=0
				begin
					--select * from @ServiceKeys
					UPDATE ServiceByDate SET SD_State=' + CAST(@Q_Type as varchar(1)) + ', SD_QPID=(SELECT SK_QPID FROM @ServiceKeys WHERE SK_Date=SD_Date and SK_Key=' + CASE @Q_ByRoom WHEN 1 THEN 'SD_RLID' ELSE 'SD_RPID' END +')
						WHERE SD_DLKey=' + CAST(@DLKey as varchar(10)) +' and ' + CASE @Q_ByRoom WHEN 1 THEN 'SD_RLID' ELSE 'SD_RPID' END +'=@SK_Current and SD_State is null
				end
				SET @SK_Current=null	
				SELECT @SK_Current=MIN(SK_Key) FROM @ServiceKeys WHERE SK_QPID is null
			END'
	print @Query
	--select * from ServiceByDate where SD_DLKey = 201662
	exec (@Query)
	--select * from ServiceByDate where SD_DLKey = 201662
	
	--если @SetQuotaType is null -значит это начальная постановка услги на квоту и ее надо делать столько раз
	--сколько номеров или людей в услуге.
	If @SetQuotaType is null or @SetQuotaType<0 --! @SetQuotaType<0 <--при переходе на 2008.1
	BEGIN		
		If exists (SELECT * FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_State is null)
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
UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null

GO
grant exec on [dbo].[DogListToQuotas] to public
go

-- sp_GetServiceCost.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetServiceCost]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[GetServiceCost] 
GO
CREATE PROCEDURE [dbo].[GetServiceCost] 
		@svKey int, @code int, @code1 int, @code2 int, @prKey int, @packetKey int, @date datetime, @days int,
		@resRate varchar(2), @men int, @discountPercent decimal(14,2), @margin decimal(14,2) = 0, @marginType int =0, 
		@sellDate dateTime, @netto decimal(14,2) output, @brutto decimal(14,2) output, @discount decimal(14,2) output, 
		@nettoDetail varchar(100) = '' output, @sBadRate varchar(2) = '' output, @dtBadDate DateTime = '' output,
		@sDetailed varchar(100) = '' output,  @nSPId int = null output, @useDiscountDays int = 0 output
as
--<DATE>2009-04-16</DATE>
---<VERSION>7.2.24.1</VERSION>

SET DATEFIRST 1
DECLARE @tourlong int

Set @sellDate = ISNULL(@sellDate,GetDate())

If @svKey = 1 and @days > 0
BEGIN
	Set @tourlong = @days
	Set @days = 0
END
else
	set @tourlong = 0
If ((@days <= 0) or (@days is null)) and (@svKey != 3 and @svKey != 8)
	Set @days = 1

/*
Новый код!!!!!!
НАЧАЛО
*/
declare @rakey int, @marginCalcValue decimal(14,2), @bSPUpdate bit, @sUseServicePrices varchar(1)
Select @rakey = RA_Key from dbo.Rates where RA_Code = @resRate

select @sUseServicePrices = SS_ParmValue from systemsettings where SS_ParmName = 'UseServicePrices'
if @sUseServicePrices = '1'
BEGIN
	SET @bSPUpdate = 0
	set @netto = null

	if @nSPId is not null 
		if exists (select SP_ID from dbo.ServicePrices where SP_ID = @nSPId)
			Set @bSPUpdate = 1

	if @bSPUpdate = 0
	BEGIN
		select	@nSPId = SP_ID, @netto = SP_Cost, @brutto = SP_Price, @discount = SP_PriceWithCommission
		from	dbo.ServicePrices
		where 
				SP_SVKey = @svKey and SP_Code = @code and SP_SubCode1 = @code1 and
				SP_SubCode2 = @code2 and SP_PRKey = @prKey and SP_PKKey = @packetKey and
				SP_Long = @days and SP_Date = @date and SP_Pax = @men and
				SP_RateKey = @rakey
	END
END

if @nSPId is null or @bSPUpdate = 1
BEGIN
/*
Новый код!!!!!!
КОНЕЦ
*/

DECLARE @profitValue decimal(14,2)
Set @marginType = ISNULL(@marginType,0)
Set @packetKey = ISNULL(@packetKey,0)

DECLARE @TMP_Number_Period int, @TMP_DATE_Period datetime, @nCostByDayExists smallint, @WeekDate varchar(1), @IsFetchNormal bit, @csid int
DECLARE @TMP_Number INT, @DayOfWeek char(1), @DayOfWeeks varchar(13), @String varchar(500), @COST_ID INT, @TMP_Date DATETIME, @CS_Date DATETIME, @CS_DateEnd DATETIME, @CS_Week varchar(7), @CS_CostNetto decimal(14,4), @CS_Cost decimal(14,4)
DECLARE @CS_Discount decimal(14,4), @CS_Type INT, @CS_Rate varchar(2), @CS_LongMin int, @CS_Long int
--DECLARE @CS_ByDay INT, @CS_Profit decimal(8,4), @CS_ID INT, @TMP_Rate varchar(2), @course decimal (8,6), @sBadRate varchar(3), @dtBadDate DateTime
DECLARE @CS_ByDay INT, @CS_Profit decimal(14,4), @CS_ID INT, @TMP_Rate varchar(2), @course decimal (18,8), @CS_CheckInDateBEG datetime, @CS_CheckInDateEND datetime, @CS_DateSellBeg datetime, @CS_DateSellEnd datetime, @NotCalculatedCosts smallint, @CS_Pax smallint, @FindCostByPeriod smallint


set @NotCalculatedCosts = 1
set @WeekDate = DATEPART (weekday, @date)

--	REGION		MEG00015352 2008-02-22
	DECLARE @RealNetto decimal(14,2)	-- Сюда будем фиксировать НЕТТО, если цены в базе разделены 
	DECLARE @UseTypeDivisionMode int	-- Переменная, которая определяет ведется ли расчет отдельно по брутто и отдельно по нетто ценам
	DECLARE @TypeDivision int	-- Переменная указывает по какому типу цены ведем расчет (1-нетто, 2-брутто)
	SET @TypeDivision = 0

	SELECT @UseTypeDivisionMode = SS_ParmValue from dbo.SystemSettings where SS_ParmName = 'SYSUseCostTypeDivision'
	IF @UseTypeDivisionMode is not null and @UseTypeDivisionMode > 0
	BEGIN
		SELECT @UseTypeDivisionMode = COUNT(*) FROM tbl_costs
			WHERE	CS_TYPEDIVISION > 0 AND
					CS_SVKey = @svKey and CS_Code = @code and CS_SubCode1 = @code1 and CS_SubCode2 = @code2 and 
					CS_PrKey = @prKey and CS_PkKey = @packetKey
					and ((@date between CS_CheckInDateBEG and CS_CheckInDateEnd) or (CS_CheckInDateBEG is null)) 
					and (CS_DateEnd >= @date and CS_DATE < @date+isnull(@days,0) or CS_DATE IS NULL) 
	END
	-- Если есть разделение цен на НЕТТО и БРУТТО
	IF @UseTypeDivisionMode is not null and @UseTypeDivisionMode > 0
	BEGIN
		SET @UseTypeDivisionMode = 2
		SET @TypeDivision = 1
	END
	ELSE
	BEGIN
		SET @UseTypeDivisionMode = 0	-- там и так ноль, но для наглядности
		SET @TypeDivision = 0
	END

	WHILE @TypeDivision <= @UseTypeDivisionMode
	BEGIN
--	ENDREGION	MEG00015352 2008-02-22 Разделение цен на НЕТТО и БРУТТО

	if @UseTypeDivisionMode > 0
		declare costCursor cursor local fast_forward for
		select 
		CS_DATE, CS_DATEEND, CS_WEEK, CS_COSTNETTO, CAST(CS_COST as decimal(14,2)),
		CS_DISCOUNT, isnull(CS_TYPE,0), CS_RATE, CS_LONGMIN, CS_LONG,
		CS_BYDAY, CS_PROFIT, CS_ID, CS_CheckInDateBEG, CS_CheckInDateEND, 
		ISNULL(CS_DateSellBeg, '19000101'), ISNULL(CS_DateSellEnd, '99980101')
			from tbl_costs               
			WHERE	CS_SVKey = @svKey and CS_Code = @code and CS_SubCode1 = @code1 and CS_SubCode2 = @code2 and 
				    CS_PrKey = @prKey and CS_PkKey = @packetKey
				--	and (CS_CheckInDateEnd >= @date or CS_CheckInDateEnd is null)
					and ((@date between CS_CheckInDateBEG and CS_CheckInDateEnd) or (CS_CheckInDateBEG is null and CS_CheckInDateEnd is null)) 
				    and (CS_DateEnd >= @date and CS_DATE <= @date+isnull(@days,0) or (CS_DATE is null and CS_DateEnd is null))
	            --    and ((GetDate() between CS_DateSellBeg and CS_DateSellEnd) or (CS_DateSellBeg is null))
					and (CS_TYPEDIVISION IN (0,@TypeDivision) OR CS_TYPEDIVISION IS NULL)	-- отбираем цены только определенного типа при использовании режима разделения цен (брутто или нетто)
		    ORDER BY
					CS_CheckInDateBEG Desc, CS_CheckInDateEnd, CS_Date Desc, CS_DATEEND, CS_LONGMIN desc, 
					CS_LONG, CS_DateSellBeg Desc, CS_DateSellEnd, CS_BYDAY,	CS_WEEK ASC
	else
		declare costCursor cursor local fast_forward for
		select 
		CS_DATE, CS_DATEEND, CS_WEEK, CS_COSTNETTO, CAST(CS_COST as decimal(14,2)),
		CS_DISCOUNT, isnull(CS_TYPE,0), CS_RATE, CS_LONGMIN, CS_LONG,
		CS_BYDAY, CS_PROFIT, CS_ID, CS_CheckInDateBEG, CS_CheckInDateEND,
		ISNULL(CS_DateSellBeg, '19000101'), ISNULL(CS_DateSellEnd, '99980101')
			from tbl_costs               
			WHERE	CS_SVKey = @svKey and CS_Code = @code and CS_SubCode1 = @code1 and CS_SubCode2 = @code2 and 
				    CS_PrKey = @prKey and CS_PkKey = @packetKey
				--	and (CS_CheckInDateEnd >= @date or CS_CheckInDateEnd is null)
					and ((@date between CS_CheckInDateBEG and CS_CheckInDateEnd) or (CS_CheckInDateBEG is null and CS_CheckInDateEnd is null)) 
				    and (CS_DateEnd >= @date and CS_DATE <= @date+isnull(@days,0) or (CS_DATE is null and CS_DateEnd is null))
	            --    and ((GetDate() between CS_DateSellBeg and CS_DateSellEnd) or (CS_DateSellBeg is null))
		    ORDER BY
					CS_CheckInDateBEG Desc, CS_CheckInDateEnd, CS_Date Desc, CS_DATEEND, CS_LONGMIN desc, 
					CS_LONG, CS_DateSellBeg Desc, CS_DateSellEnd, CS_BYDAY,	CS_WEEK ASC

	--1, 
	open costCursor

	set @nCostByDayExists = 0

	fetch next from costCursor 
		into	@CS_Date, @CS_DateEnd, @CS_Week, @CS_CostNetto, @CS_Cost, 
				@CS_Discount, @CS_Type, @CS_Rate, @CS_LongMin, @CS_Long, 
				@CS_ByDay, @CS_Profit, @CS_ID, @CS_CheckInDateBEG, @CS_CheckInDateEND, @CS_DateSellBeg, @CS_DateSellEnd

If @days >1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)
BEGIN
	If @@fetch_status = 0
	BEGIN

		declare @TMPTable Table 
 		( CL_Date datetime,
		CL_CostNetto decimal(14,6),
		CL_Cost decimal(14,6),
		CL_Discount smallint,
		CL_Type smallint,
		CL_Rate varchar(2),
		CL_Course decimal(14,6),
		CL_Pax smallint default 1,
		CL_ByDay smallint,
		CL_Part smallint,
		CL_Profit decimal(14,6))

		DECLARE @temp_date DATETIME
		SET @temp_date = @date + @days - 1

		while @temp_date >= @date 
		BEGIN -- begin while @temp_date >= @date 
			insert into @TMPTable (CL_Date, CL_ByDay) values (@temp_date, -1 )
			set @temp_date = @temp_date - 1 
		END  -- end while @temp_date >= @date 
	END
	Else
	BEGIN
		close costCursor
		deallocate costCursor
		return 0
	END

	set @COST_ID = 1 --идетификатор уникальности цены
	If @CS_ByDay = 2
		Set @nCostByDayExists = 1

	If @CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) --or (@CS_ByDay = 0 and @days = 0)
		insert into @TMPTable (CL_Date, CL_ByDay) values (@date + @days, -1 )
END

set @NotCalculatedCosts = 1
set @FindCostByPeriod = 0   --переменная контролирует поиск цены за период, точно совпадающий с периодом предоставления услуги

While (@@fetch_status = 0) and (@NotCalculatedCosts > 0 or @FindCostByPeriod > 0)  --цены уже могут быть найдены на все даты, но возможно где-то еще есть цена на период...
BEGIN -- While (@@fetch_status = 0)
	-- подправим продолжительность цены, чтобы было проще искать по периодам и по неделям
	Set @IsFetchNormal = 1
		-- если не указаны даты периодов, то значит указаны даты заедов
		-- в этом случае "дни недели", подразумевают дни заездов, и действуют все дни из периодов]

	If	@CS_CheckInDateBEG is not null and @CS_Date is null and @CS_Week is not null and @CS_Week != ''
		if CHARINDEX ( @WeekDate, @CS_Week ) = 0
			Set @IsFetchNormal = 0
		Else
			Set @CS_Week = ''

	If @tourlong > 0 and @svKey = 1
	Begin		
		If (@CS_LongMin is null or @tourlong >= @CS_LongMin) and (@CS_Long is null or @tourlong <= @CS_Long)
			Set @IsFetchNormal = @IsFetchNormal
		else
			Set @IsFetchNormal = 0
	end     

	If @svKey != 1
	begin
		If @CS_LongMin is not null and @CS_LongMin > @days
			Set @IsFetchNormal = 0
	end

	-- Если время не задано, то увеличиваем период продажи на один день. Иначе, смотрим точный период.
	If DATEPART(hour, @CS_DateSellEnd)+DATEPART(minute, @CS_DateSellEnd) = 0
		Set @CS_DateSellEnd = @CS_DateSellEnd + 1
	-- При переходе с 5.2 возможны цены с периодом продаж оганиченном только с одной стороны.
	If (@sellDate between ISNULL(@CS_DateSellBeg, @sellDate - 1) and ISNULL(@CS_DateSellEnd, @sellDate + 1))
		Set @IsFetchNormal = @IsFetchNormal 
	else
		Set @IsFetchNormal = 0

	If @FindCostByPeriod = 1 and ((@days between @CS_LongMin and @CS_Long) or @CS_Long is null) and @CS_DateEnd = (@date + @days - 1) -- смотрим может есть цена за период точно совпадает с периодом действия услуги
		Update @TMPTable Set CL_CostNetto = null, CL_Cost = null, CL_Discount = null, CL_Type = null, 
			CL_Rate = null, CL_Course = null, CL_Pax = 1, CL_ByDay =-1, CL_Part = null, CL_Profit = null

--	If @CS_ByDay = 1 and @CS_Long is not null and @CS_Long < @days
--		Set @IsFetchNormal = 0
	If @CS_Week != '' and (@days = 0 or (@days = 1 and (@CS_ByDay != 2 or (@svKey!=3 and @svKey!=8) ) ) )
	BEGIN
		If CHARINDEX ( @WeekDate, @CS_Week ) > 0
			Set @IsFetchNormal = @IsFetchNormal 
		Else
			Set @IsFetchNormal = 0
	END

	If @Days = 1 and @CS_Date > @date
		Set @IsFetchNormal = 0

	If @Days = 1 and @CS_ByDay in (3,4)
		Set @IsFetchNormal = 0

--ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! 
--ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! ВНИМАНИЕ!!!! 
/*
	If 	@CS_CheckInDateBEG is not null
	BEGIN
		Set @CS_Date = null
		Set @CS_DateEnd = null
	END
*/
		If (@Days > 1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)) and @IsFetchNormal = 1 	-- fetch нам подходит
		BEGIN			--цены подходят для поиска
			Set @CS_Date = (isnull(@CS_Date,@date))
			Set @CS_DateEnd = isnull(@CS_DateEnd,@date+ISNULL(@CS_Long,999))

			If @nCostByDayExists = 0 and @CS_ByDay = 2 and (@svKey = 3 or @svKey = 8)
			BEGIN
				update @TMPTable Set CL_CostNetto = null, CL_Cost = null, CL_Discount = null, CL_Type = null, 
						CL_Rate = null, CL_Course = null, CL_Pax = 1, CL_ByDay =-1, CL_Part = null, CL_Profit = null
				if not exists (select * from @TMPTable where CL_Date = @date + @days)
					insert into @TMPTable (CL_Date, CL_ByDay) values (@date + @days, -1 )
				Set @nCostByDayExists = 1	
			END

			if @CS_Date < @date
				Set @CS_Date = @date
			if @CS_DateEnd > @date + @days
				Set @CS_DateEnd = @date + @days
			Set @CS_Discount = ISNULL(@CS_Discount,0)
			Set @TMP_Number_Period = null

			if @CS_ByDay = 3 and (@nCostByDayExists = 0 or (@svKey != 3 and @svKey != 8)) -- если цена за неделю
			BEGIN -- if @CS_ByDay = 3
				if (@CS_DateEnd - @CS_Date + 1) >= 7 and ((@days between @CS_LongMin and @CS_Long) or @CS_Long is null)
				BEGIN
					select @TMP_Number = count(*), @TMP_Date = MIN(CL_Date) from @TMPTable Where CL_Date between @CS_Date and @CS_DateEnd and CL_ByDay in (-1,1,4)
					while @TMP_Number >= 7
					BEGIN
						UPDATE @TMPTable SET CL_CostNetto = @CS_CostNetto, CL_ByDay = @CS_ByDay, CL_Part = @COST_ID, 
							CL_Cost = @CS_Cost, CL_Discount = (CASE WHEN @CS_Discount=1 THEN 1 ELSE null END), CL_Type = @CS_Type, CL_Rate = @CS_Rate, 
							CL_Pax = 1, CL_Profit = @CS_Profit
							WHERE CL_DATE between @TMP_Date and @TMP_Date + 6  and CL_ByDay  in (-1,1,4)
	
						UPDATE @TMPTable SET CL_Pax = 0 WHERE CL_DATE != @TMP_Date and CL_Part = @COST_ID
						SET @TMP_Number = @TMP_Number - 7
						SET @TMP_Date = @TMP_Date + 7
						SET @COST_ID = @COST_ID + 1
					END
				END
			END	-- if @CS_ByDay = 3

	--		print 'поиск'
			if @CS_ByDay = 0 and (@nCostByDayExists = 0 or (@svKey != 3 and @svKey != 8)) -- если цена за период
			BEGIN -- if @CS_ByDay = 0
	--			print 'период'
				select @TMP_Number = count(*), @TMP_Date = MIN(CL_Date) from @TMPTable 
					Where	CL_Date between @CS_Date and @CS_DateEnd and CL_ByDay != 3 and CL_ByDay != 0

				if @CS_Date < @TMP_Date and @date < @TMP_Date
				BEGIN
					select @TMP_Number_Period = CL_Part from @TMPTable where CL_Date = @TMP_Date - 1 and CL_ByDay = 0
			--		print @TMP_Number_Period
					if @TMP_Number_Period is not null
					BEGIN					
						select @TMP_Date_Period = MIN(CL_Date) from @TMPTable where CL_Part = @TMP_Number_Period
						if @CS_Date <= @TMP_Date_Period and (@CS_Long is null or @CS_Long > DATEDIFF(DAY,@TMP_Date_Period,@TMP_Date + @TMP_Number)) and (@CS_LongMin is null or @CS_LongMin <= DATEDIFF(DAY,@TMP_Date_Period,@TMP_Date + @TMP_Number))
						BEGIN
							select @TMP_Number = count(*), @TMP_Date = MIN(CL_Date) from @TMPTable 
								Where	CL_Date between @CS_Date and @CS_DateEnd and CL_ByDay != 3 and (CL_ByDay != 0 or CL_Part = @TMP_Number_Period)					
						END
					END
					Set @TMP_Number_Period = null
				END

				if @CS_Long is null or @CS_Long > @TMP_Number
				BEGIN
					--если предыдущий период захватывается полностью, то его надо включить
					--это делается только в случае, если цену указана за период
			--		print @TMP_Date + @TMP_Number
					select @TMP_Number_Period = CL_Part from @TMPTable where CL_Date = @TMP_Date + @TMP_Number and CL_ByDay = 0
		--			print @TMP_Number_Period
					if @TMP_Number_Period is not null
					BEGIN 
						select @TMP_Date_Period = MAX(CL_Date) from @TMPTable where CL_Part = @TMP_Number_Period
	--					print @TMP_Date_Period
						if (@CS_Long is null or @CS_Long > DATEDIFF(DAY,@TMP_Date,@TMP_Date_Period + 1)) and (@CS_LongMin is null or @CS_LongMin <= DATEDIFF(DAY,@TMP_Date,@TMP_Date_Period + 1)) and @TMP_Date_Period <= @CS_DateEnd
							Set @TMP_Number = DATEDIFF(DAY,@TMP_Date,@TMP_Date_Period) + 1
					END
				END

				if @CS_Long is not null and @CS_Long < @TMP_Number
					set @TMP_Number = @CS_Long

				if @CS_LongMin is null or @CS_LongMin <= @TMP_Number
				BEGIN
					UPDATE @TMPTable SET CL_CostNetto = @CS_CostNetto, CL_ByDay = @CS_ByDay, CL_Part = @COST_ID, 
						CL_Cost = @CS_Cost, CL_Discount = (CASE WHEN @CS_Discount=1 THEN 1 ELSE null END), CL_Type = @CS_Type, CL_Rate = @CS_Rate, 
						CL_Pax = 1, CL_Profit = @CS_Profit
						WHERE CL_DATE between @TMP_Date and @TMP_Date + @TMP_Number - 1 and CL_ByDay != 3
					UPDATE @TMPTable SET CL_Pax = 0 WHERE CL_DATE != @TMP_Date and CL_Part = @COST_ID
					SET @COST_ID = @COST_ID + 1
				END
			END	-- if @CS_ByDay = 0
	
			if (@CS_ByDay = 1 and @nCostByDayExists = 0) or (@CS_ByDay = 2 and @nCostByDayExists = 1) or ((@svKey != 3 and @svKey != 8) and @CS_ByDay in (1,2))  -- если цена за ночь / день
			BEGIN -- if @CS_ByDay = 1/2
				if @CS_DateEnd > @date + @CS_Long - 1		-- если дата окончания цены действует в паре с продолжительностью
					Set @CS_DateEnd = @date + @CS_Long - 1

				if 1=1 -- временная заглушка, 
				BEGIN  -- если Цена удовлетворяет условиям
					SET @DayOfWeeks = @CS_Week
					While exists (select TOP 1 CL_Part from @TMPTable where CL_ByDay = 0 group by CL_Part having MIN(CL_Date) >= @CS_Date and MAX(CL_Date) <= @CS_DateEnd)
					BEGIN
						select TOP 1 @TMP_Number = CL_Part from @TMPTable where CL_ByDay = 0 group by CL_Part having MIN(CL_Date) >= @CS_Date and MAX(CL_Date) <= @CS_DateEnd
						update @TMPTable Set CL_CostNetto = null, CL_Cost = null, CL_Discount = null, CL_Type = null, 
							CL_Rate = null, CL_Course = null, CL_Pax = 1, CL_ByDay =-1, CL_Part = null, CL_Profit = null
							Where CL_Part = @TMP_Number
					END				

					IF @DayOfWeeks = ''
						UPDATE @TMPTable SET CL_CostNetto = @CS_CostNetto, CL_ByDay = @CS_ByDay, CL_Part = @COST_ID,
							CL_Cost = @CS_Cost, CL_Discount = (CASE WHEN @CS_Discount=1 THEN 1 ELSE null END), CL_Type = @CS_Type, CL_Rate = @CS_Rate, CL_Profit = @CS_Profit, CL_Course = ISNULL(@CS_Long,999)
							WHERE	CL_DATE between @CS_Date and @CS_DateEnd and (CL_ByDay in (-1,4) or (CL_ByDay in (1,2) and CL_Course < ISNULL(@CS_Long,999)))
					ELSE
						UPDATE @TMPTable SET CL_CostNetto = @CS_CostNetto, CL_ByDay = @CS_ByDay, CL_Part = @COST_ID,
							CL_Cost = @CS_Cost, CL_Discount = (CASE WHEN @CS_Discount=1 THEN 1 ELSE null END), CL_Type = @CS_Type, CL_Rate = @CS_Rate, CL_Profit = @CS_Profit, CL_Course = ISNULL(@CS_Long,999)
							WHERE	CL_DATE between @CS_Date and @CS_DateEnd and (CL_ByDay in (-1,4) or (CL_ByDay in (1,2) and CL_Course < ISNULL(@CS_Long,999))) AND CHARINDEX(CAST(DATEPART (weekday, CL_DATE) as varchar(1)),@DayOfWeeks) > 0

					SET @COST_ID = @COST_ID + 1
				END   -- если Цена удовлетворяет условиям
			END	-- if @CS_ByDay = 1

			if @CS_ByDay = 4 --and @nCostByDayExists = 0 -- если цена за доп.ночь
			BEGIN -- if @CS_ByDay = 4
				if @CS_DateEnd > @date + @CS_Long - 1		-- если дата окончания цены действует в паре с продолжительностью
					Set @CS_DateEnd = @date + @CS_Long - 1

				SET @DayOfWeeks = ''
				Set @CS_Week = REPLACE(@CS_Week,'.','');

				if @CS_Week != ''
				BEGIN			
					Set @TMP_Number = 1
					Set @DayOfWeeks = LEFT(@CS_Week,1)
					while @TMP_Number < LEN(@CS_Week)
					BEGIN
						Set @TMP_Number = @TMP_Number + 1
						Set @DayOfWeeks = @DayOfWeeks + ',' + SUBSTRING(@CS_Week, @TMP_Number, 1)				
					END
				END
				
				-- доп.ночи могут только добивать в конец, первый день точно не к ним
				If @CS_Date = @date
					Set @CS_Date = @CS_Date + 1

				IF @DayOfWeeks = ''
					UPDATE @TMPTable SET CL_CostNetto = @CS_CostNetto, CL_ByDay = @CS_ByDay, CL_Part = @COST_ID,
						CL_Cost = @CS_Cost, CL_Discount = (CASE WHEN @CS_Discount=1 THEN 1 ELSE null END), CL_Type = @CS_Type, CL_Rate = @CS_Rate
						WHERE	CL_DATE between @CS_Date and @CS_DateEnd and (CL_ByDay = -1)
				ELSE
					UPDATE @TMPTable SET CL_CostNetto = @CS_CostNetto, CL_ByDay = @CS_ByDay, CL_Part = @COST_ID,
						CL_Cost = @CS_Cost, CL_Discount = (CASE WHEN @CS_Discount=1 THEN 1 ELSE null END), CL_Type = @CS_Type, CL_Rate = @CS_Rate
						WHERE	CL_DATE between @CS_Date and @CS_DateEnd and (CL_ByDay = -1) AND CHARINDEX(CAST(DATEPART (weekday, CL_DATE) as varchar(1)),@DayOfWeeks) > 0
				SET @COST_ID = @COST_ID + 1
			END	-- if @CS_ByDay = 4
			select @NotCalculatedCosts = Count(*) from @TMPTable where CL_CostNetto is null
		END -- цены подходят для поиска и есть продолжительность
		ELSE
			If @IsFetchNormal = 1
				Set @NotCalculatedCosts = 0

	If (@Days > 1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)) or @IsFetchNormal = 0
	BEGIN
		fetch next from costCursor 
			into	@CS_Date, @CS_DateEnd, @CS_Week, @CS_CostNetto, @CS_Cost, 
					@CS_Discount, @CS_Type, @CS_Rate, @CS_LongMin, @CS_Long, 
					@CS_ByDay, @CS_Profit, @CS_ID, @CS_CheckInDateBEG, @CS_CheckInDateEND, @CS_DateSellBeg, @CS_DateSellEnd

		If @CS_ByDay = 0 and @CS_Date = @date and @CS_DateEnd <= (@date + @days) and @days > 1 and (@sellDate between ISNULL(@CS_DateSellBeg, @sellDate - 1) and ISNULL(@CS_DateSellEnd, @sellDate + 1))
			Set @FindCostByPeriod = 1  -- отметка, что может быть эта цена за период, нам супер подойдет
		Else
			Set @FindCostByPeriod = 0
	END
END -- While (@@fetch_status = 0)
close costCursor
deallocate costCursor

--if @svKey = 3 
--	insert into TMP (CL_Date, CL_CostNetto, CL_Cost, CL_Discount, CL_Type, CL_Rate, CL_Course, CL_ByDay, CL_Part, CL_Profit) select CL_Date, CL_CostNetto, CL_Cost, CL_Discount, CL_Type, CL_Rate, CL_Course, CL_ByDay, CL_Part, CL_Profit from @TMPTable

if @NotCalculatedCosts > 0
BEGIN
--	delete from @TMPTable
	if @bSPUpdate = 1
		delete from dbo.ServicePrices where SP_ID = @nSPId	
	return 0
END

If @days > 1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)
BEGIN
	Update @TMPTable set CL_Course = null
	Update @TMPTable set CL_Course = 1 Where CL_Rate = @resRate
	Update @TMPTable set CL_Course = 0 Where CL_CostNetto = 0 and ISNULL(CL_Cost,0) = 0 and ISNULL(CL_Profit,0) = 0

	set @TMP_Rate = null
	SELECT TOP 1 @TMP_Rate = CL_Rate from @TMPTable where CL_Course is null

	while @TMP_Rate is not null
	BEGIN
		Set @course = 1
		exec ExchangeCost @course output, @TMP_Rate, @resRate, @date
		if (@course is null) 
		begin 
			set @sBadRate=@TMP_Rate
			set @dtBadDate =@date
			--print 'нет курса между ' + ISNULL(@TMP_Rate,'NULL') + ' и ' + ISNULL(@resRate,'NULL') + ' на ' + CAST(@dtBadDate as varchar(12))
			if @bSPUpdate = 1
				delete from dbo.ServicePrices where SP_ID = @nSPId	
			return 0 		
		end 
		Update @TMPTable set CL_Course = @course Where CL_Rate = @TMP_Rate

		set @TMP_Rate = null
		SELECT TOP 1 @TMP_Rate = CL_Rate from @TMPTable where CL_Course is null
	END
end
else
BEGIN
	set @course=1
	If @CS_CostNetto = 0 and ISNULL(@CS_Cost,0) = 0 and ISNULL(@CS_Profit,0) = 0
		set @course = 0
	Else IF (@CS_Rate<>@resRate)
		exec ExchangeCost @course output, @CS_Rate, @resRate, @date             

	if (@course is null) 
	begin 
		set @sBadRate = @CS_Rate
		set @dtBadDate = @date
		--print 'нет курса между ' + ISNULL(@TMP_Rate,'NULL') + ' и ' + ISNULL(@resRate,'NULL') + ' на ' + CAST(@dtBadDate as varchar(12))
		--delete from @TMPTable
		if @bSPUpdate = 1
			delete from dbo.ServicePrices where SP_ID = @nSPId	
		return 0 		
	end 			
END

--select * from TMP
If @days > 1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)
	Update @TMPTable set CL_Pax = CL_Pax * @men Where CL_Type = 0
else
	If (isnull(@CS_Type, 0) = 0)
		Set @CS_Pax = @men
	Else
		Set @CS_Pax = 1

--Update @TMP set CL_Course = 0 Where CL_ByDay not in (0,3) and CL_DateFirst != CL_Date
--Update @TMP set CL_Course = CL_Course*(@margin + 100)/100 Where CL_Discount + (1- @marginType) != 0

If @days > 1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)
BEGIN	
	update @TMPTable set CL_Profit = 0 where CL_Date != @date
	if not exists (Select * from @TMPTable where CL_Cost is null)
		select	@brutto = SUM((CL_Cost + ISNULL(CL_Profit,0)) * CL_Course * CL_Pax),
				@discount = SUM((CL_Cost + ISNULL(CL_Profit,0)) * CL_Course * CL_Pax * CL_Discount) 
		from @TMPTable
	select	@netto = SUM(CL_CostNetto * CL_Course * CL_Pax) from @TMPTable
--	select	@profitValue = ISNULL(CL_Profit * CL_Course * CL_Pax * CL_Margin,0) from @TMPTable where CL_Date = @date
--	select	@profitValue = CL_Profit from @TMPTable where CL_Date = @date
	set @useDiscountDays = (select SUM(ISNULL(CL_Discount,0)) from @TMPTable)
	
END
else
BEGIN
	set @brutto = (@CS_Cost + ISNULL(@CS_Profit,0)) * @course * @CS_Pax
	set @discount = (@CS_Cost + ISNULL(@CS_Profit,0)) * @course * @CS_Pax * @CS_Discount
	set @netto = @CS_CostNetto * @course * @CS_Pax 
	set @useDiscountDays = @CS_Discount
--	set @profitValue = @CS_Profit * @course * @CS_Pax * @CS_Margin
END

/*
Новый код!!!!!!
НАЧАЛО
*/
If @sUseServicePrices = '1'
BEGIN
		if @bSPUpdate = 1
			update	dbo.ServicePrices 
					set	SP_Cost = @netto, SP_Price = @brutto, SP_PriceWithCommission = ISNULL(@discount,0)
			where SP_ID = @nSPId	
		else
		begin
			insert into dbo.ServicePrices (SP_SVKey, SP_Code, SP_SubCode1, SP_SubCode2, SP_PRKey,
				SP_PKKey, SP_Long, SP_Date, SP_Pax, SP_Cost, 
				SP_Price, SP_PriceWithCommission, SP_RateKey)
			values (@svKey, @code, @code1, @code2, @prKey,
				@packetKey, @days, @date, @men, @netto,
				@brutto, ISNULL(@discount,0), @rakey )
			Set @nSPId = SCOPE_IDENTITY()
		end
	END

--	REGION		MEG00015352 2008-02-22 Разделение цен на НЕТТО и БРУТТО		
		IF		(@TypeDivision = 1)	-- Если производили расчет по ценам НЕТТО
			BEGIN
				SET @RealNetto = @netto -- Фиксируем НЕТТО
				DELETE FROM @TMPTable	-- Подчищаем за собой для следующей итерации
			END
		ELSE IF	(@TypeDivision = 2)	-- Если производили расчет по ценам БРУТТО
			BEGIN
				SET @netto = @RealNetto	-- Восстанавливаем НЕТТО
			END
		SET @TypeDivision = @TypeDivision + 1
	END -- WHILE @TypeDivision <= @UseTypeDivisionMode
--	ENDREGION	MEG00015352 2008-02-22 Разделение цен на НЕТТО и БРУТТО

END -- Это конец основного блока !!!!!!!!!
/*
Новый код!!!!!!
КОНЕЦ
*/

--@discount на данный момент хранит сумму, с которой надо давать скидку
declare @sum_with_commission decimal(18,2)
set @sum_with_commission = @discount

If @marginType = 0 -- даем наценку, вне зависмости от наличия комиссии по услуге
	Set @brutto = ISNULL(@brutto,0) * (100 + @margin) / 100 
Else -- даем наценку, только при наличии комиссии
	Set @brutto = ISNULL(@brutto,0) - ISNULL(@sum_with_commission,0) + ISNULL(@sum_with_commission,0) * (100 + @margin) / 100 

--теперь @discount это именно сумма скидки
Set @discount = @sum_with_commission * ((100 + @margin) / 100) * @discountPercent / 100

exec RoundCost @brutto output, 1

Set @brutto = ISNULL(@brutto,0) - ISNULL(@discount,0)

DECLARE @TMP_Number_Course decimal(12,4), @TMP_Number_Part INT, @TMP_Number_Pax int
DECLARE @TMP_Number_CostNetto decimal(12,2), @TMP_Number_Cost decimal(12,2)

If (@days > 1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)) and @nSPId is null    -- Новый код !!!!!  and @useServicePrices is null
BEGIN
	set @nettoDetail = '='
	set @sDetailed = '='
	while exists (select * from @TMPTable where CL_Course != 0)
	begin
		SELECT TOP 1	@CS_Date = CL_Date, @TMP_Number_CostNetto = CL_CostNetto, @TMP_Number_Cost = CL_Cost, @TMP_Number_Course = CL_Course, 
						@TMP_Number_Part = CL_Part, @TMP_Number_Pax = CL_Pax
		from			@TMPTable 
		where			CL_Course != 0	 
		Order By		CL_Date

		Set @TMP_Number = 0
		Select @TMP_Number = Count(*) from @TMPTable where CL_Part = @TMP_Number_Part and CL_Pax != 0
		UPDATE @TMPTable SET CL_Course = 0 WHERE CL_Part = @TMP_Number_Part
		if @nettoDetail != '='
			Set @nettoDetail = @nettoDetail + ' +'
		if @sDetailed != '='
			Set @sDetailed = @sDetailed + ' +'

		Set @nettoDetail = @nettoDetail + CAST(@TMP_Number_CostNetto as varchar(15)) 
		Set @sDetailed = @sDetailed + CAST(@TMP_Number_Cost as varchar(15)) 

		if @TMP_Number != 1
		begin
			Set @nettoDetail = @nettoDetail + '*' + CAST(@TMP_Number as varchar(15)) 
			Set @sDetailed = @sDetailed + '*' + CAST(@TMP_Number as varchar(15)) 
		end

		if @TMP_Number_Pax != 1
		begin
			Set @nettoDetail = @nettoDetail + '*' + CAST(@TMP_Number_Pax as varchar(15))
			Set @sDetailed = @sDetailed + '*' + CAST(@TMP_Number_Pax as varchar(15))
		end

		if @TMP_Number_Course != 1
		begin
			Set @nettoDetail = @nettoDetail + '*' + CAST(@TMP_Number_Course as varchar(15)) 
			Set @sDetailed = @sDetailed + '*' + CAST(@TMP_Number_Course as varchar(15)) 
		end
	end

	If ISNULL(@profitValue,0) > 0
		Set @sDetailed = @sDetailed + ' +' + CAST(@profitValue as varchar(15)) 

	if @marginCalcValue > 0
		Set @sDetailed = @sDetailed + '+' + CAST(@marginCalcValue as varchar(15)) 

	If ISNULL(@discount,0) > 0
		Set @sDetailed = @sDetailed + ' -' + CAST(@discount as varchar(15)) 
END
GO
GRANT EXECUTE ON [dbo].[GetServiceCost] TO PUBLIC 
GO

-- sp_mwFlightsWithOnlyAgentQuotes_v9.sql
if exists(select id from sysobjects where name='mwFlightsWithOnlyAgentQuotes' and xtype='p')
	drop procedure [dbo].[mwFlightsWithOnlyAgentQuotes]
go

create proc [dbo].[mwFlightsWithOnlyAgentQuotes]
(
	@charterKeys varchar(500), 
	@dateFrom datetime, 
	@dateTo datetime,
	@agentKey int
)
as
begin
	create table #onlyAgentQuotes
	(
		chkey int,
		flightdate datetime
	)
	
	declare @sql varchar(1000)
		set @sql = 
'	select ch_key, as_datefrom, as_dateto, as_week
	from charter with(nolock)
		join airseason with(nolock) on ch_key = as_chkey
	where ch_key in (' + @charterKeys + ')
		and as_datefrom <= ''' + CONVERT(varchar, @dateTo , 101) + '''
		and as_dateto >= ''' + CONVERT(varchar, @dateFrom , 101) + ''''
	print @sql
	
	create table #charter_shedule
	(
		ch_key int, as_datefrom datetime, as_dateto datetime, as_week varchar(7)
	)
	
	insert into #charter_shedule
	exec (@sql)
	
	declare @dayofweek tinyint	
	declare @dateCurrent datetime
		set @dateCurrent = @dateFrom
		
	while (@dateCurrent <= @dateTo)
	begin
		set @dayofweek = DATEPART(dw, @dateCurrent)
		if @dayofweek = 1
			set @dayofweek = 7
		else
			set @dayofweek = @dayofweek - 1

		insert into #onlyAgentQuotes
			select ch_key, @dateCurrent
			from #charter_shedule
			where @dateCurrent between as_datefrom and as_dateto
				and as_week like '%' + CAST(@dayofweek as varchar(1)) + '%'
		
		set @dateCurrent = DATEADD(d, 1, @dateCurrent)
	end

	select chkey, flightdate 
	from
	(	select chkey
		, flightdate
		, (
			select count(*) 
			from QuotaParts 
				inner join QuotaDetails on QP_QDID = QD_ID
				inner join Quotas on QD_QTID = QT_ID
				inner join QuotaObjects on QO_QTID = QT_ID
			where qo_svkey = 1
				and qd_date = flightdate 
				and qo_code = chkey
				and isnull(QP_AgentKey, 0) > 0 and isnull(QP_AgentKey, 0) != @agentkey
			) as AgentQuotaCount
		, (
			select count(*) 
			from QuotaParts 
				inner join QuotaDetails on QP_QDID = QD_ID
				inner join Quotas on QD_QTID = QT_ID
				inner join QuotaObjects on QO_QTID = QT_ID
			where qo_svkey = 1
				and qd_date = flightdate 
				and qo_code = chkey
				and (isnull(QP_AgentKey, 0) = 0 or isnull(QP_AgentKey, 0) = @agentkey)
			) as CommonQuotaCount
		from #onlyAgentQuotes
	) as subquery
	where AgentQuotaCount > 0 and CommonQuotaCount = 0
end
go

grant exec on [dbo].[mwFlightsWithOnlyAgentQuotes] to public
go

-- 20100817_AlterTable_Payments.sql
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[payments]') and name = 'PM_VData')
	alter table dbo.payments add PM_VData varchar(100)
GO


-- 100816_Alter_ContactTypeFields.sql
IF(NOT EXISTS(select * from dbo.syscolumns where name = 'CTF_Order' and id = object_id(N'[dbo].[ContactTypeFields]') ))
ALTER TABLE [dbo].[ContactTypeFields] ADD CTF_Order INT NOT NULL DEFAULT(0)
go

IF (EXISTS(select 1 from [dbo].[ContactTypeFields] where CTF_Order = 0))
BEGIN
	DECLARE @Id INT
	DECLARE @ContactTypeId INT

	DECLARE cur_ContactTypeField CURSOR FOR
	SELECT CTF_ID, CTF_CTID FROM dbo.ContactTypeFields

	OPEN cur_ContactTypeField
	FETCH NEXT FROM cur_ContactTypeField INTO @Id, @ContactTypeId

	WHILE @@FETCH_STATUS = 0
	BEGIN 

		UPDATE dbo.ContactTypeFields
		   SET CTF_Order = (SELECT MAX(CTF_Order) + 1 
							  FROM dbo.ContactTypeFields 
							 WHERE CTF_CTID = @ContactTypeId)
		 WHERE CTF_Id = @Id
		 
		FETCH NEXT FROM cur_ContactTypeField INTO @Id, @ContactTypeId
	END
	CLOSE cur_ContactTypeField
	DEALLOCATE cur_ContactTypeField
END
GO


-- sp_mwAutobusQuotes.sql
if exists(select id from sysobjects where xtype='p' and name='mwAutobusQuotes')
	drop proc dbo.mwAutobusQuotes
go

CREATE PROCEDURE [dbo].[mwAutobusQuotes]
	@Filter varchar(2000),		
	@AgentKey int, 	
	@RequestOnRelease smallint,
	@NoPlacesResult int,
	@CheckAgentQuotes smallint,
	@CheckCommonQuotes smallint,
	@ExpiredReleaseResult int
AS
/*
declare @Filter varchar(2000)
	declare @AgentKey int
	declare @RequestOnRelease smallint
	declare @NoPlacesResult int
	declare @CheckAgentQuotes smallint
	declare @CheckCommonQuotes smallint
	declare @ExpiredReleaseResult int


set @Filter = 'pt_tourdate >= ''2009-06-05'' AND pt_tourdate <= ''2010-06-04''
 AND pt_days <= 1000
 AND pt_tourkey = 256'

set @Filter = 'pt_tourdate >= ''2009-08-07'' AND pt_tourdate <= ''2010-07-06''
 AND pt_days <= 1000
 AND pt_tourkey = 575


set @AgentKey = 0
set @RequestOnRelease = 0
set @NoPlacesResult = 0
set @CheckAgentQuotes = 1
set @CheckCommonQuotes = 0
set @ExpiredReleaseResult = -1
*/
---=== СОЗДАНИЕ ВРЕМЕННОЙ ТАБЛИЦЫ ===---
CREATE TABLE #tmp
(	
	[CountryKey] [int] NOT NULL,
	[TourDate] [datetime] NULL,
	[TourKey] [int] NULL,
	[TurListKey] [int] NULL,
	[TourDuration] [int] null,--продолжительность тура в днях
	[TourDescription] varchar (1024) null,
	[HotelKey] [int] NULL,
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
	QuotaPlaces int,
	QuotaAllPlaces int
)

declare @rmKey int
declare @script varchar(8000)
--временная таблица с нужными типами номеров
--т.е. теми, на которые есть цены
create table #tmp1
(
	rm_key int null,
	rm_code varchar(35) null
)

set @script = 'select distinct pt_rmkey,pt_rmcode from mwpricedatatable where ' + @Filter

INSERT INTO #tmp1
	EXEC(@script)

declare @rmCount int
select @rmCount = count(rm_key)
from #tmp1

if(@rmCount = 0)
	return

declare roomCursor cursor 
	for
		select rm_key from #tmp1 order by rm_key

--добавляем колонки типов номеров в темповую таблицу
OPEN roomCursor
FETCH NEXT FROM roomCursor INTO @rmKey
while @@fetch_status = 0
	begin
		set @script = 'alter table #tmp add rmkey_' +  convert(varchar,@rmKey) + ' int, pr_' + convert(varchar,@rmKey) + ' int' 

		exec (@script)
		FETCH NEXT FROM roomCursor INTO @rmKey
	end
close roomCursor
deallocate roomCursor

-- Cобираем колонки типов номеров для запроса
declare @PNames as varchar(4000)
set @PNames = ''
select @PNames = @PNames + ',' +
	'0 as ''rmkey_' + convert(varchar,rm_key) + ''',
	max(case when pt_rmkey = ' + convert(varchar,rm_key) +
	' then pt_pricekey else 0 end) as ''pr_' + convert(varchar,rm_key) + ''''
from #tmp1
order by rm_key

set @PNames = substring(@PNames, 2, len(@PNames))

set @script =
'select pt_cnkey,pt_tourdate,
pt_tourkey,pt_tlkey, pt_days, TL_DESCRIPTION, pt_hdkey,
pt_hdpartnerkey,pt_hdday,pt_hdnights,pt_rmkey,pt_rckey,rc_name,
pt_nights,pt_tourname,pt_tourtype,tp_name,pt_hdname, pt_rate,ts_subcode1,ts_code,ts_day, -1,-1,'+ @PNames + '
from(select 
pt_cnkey ptcnkey,pt_ackey ptackey,pt_rmkey ptrmkey,pt_tourdate pttourdate,pt_tourkey pttourkey,
pt_days ptdays,pt_hdkey pthdkey,pt_hdpartnerkey pthdpartnerkey,pt_hdday pthdday, 
pt_hdnights pthdnights,pt_rckey ptrckey,pt_nights ptnights,pt_tourtype pttourtype,
min(pt_price) ptprice 
from mwpricedatatable with (nolock)
where ' + @Filter + '
group by pt_cnkey,pt_rmkey,pt_tourdate,pt_tourkey,pt_days,pt_hdkey,pt_hdpartnerkey,pt_hdday,pt_hdnights,pt_rckey,pt_ackey, pt_nights,pt_tourname,pt_tourtype
) t
inner join mwpricedatatable mwp with (nolock)
on
(
pt_rmkey=t.ptrmkey and 
pt_cnkey=t.ptcnkey and mwp.pt_ackey=t.ptackey and  mwp.pt_tourdate=t.pttourdate and
pt_tourkey=t.pttourkey and mwp.pt_days=t.ptdays and mwp.pt_hdkey=t.pthdkey and
pt_hdpartnerkey=t.pthdpartnerkey and mwp.pt_hdday=t.pthdday and mwp.pt_hdnights=t.pthdnights and
pt_rckey=t.ptrckey and mwp.pt_days=t.ptdays and  
pt_nights=t.ptnights and
pt_price=t.ptprice)
inner join tiptur on pt_tourtype = tp_key
inner join turlist on pt_tlkey = tl_key
inner join roomscategory on pt_rckey = rc_key
inner join tp_servicelists on tl_tikey = pt_pricelistkey
inner join tp_services on ts_key = tl_tskey and ts_svkey = 2
where ' + @Filter + '
group by pt_cnkey,pt_tourdate, 
pt_tourkey,pt_tlkey, pt_days,TL_DESCRIPTION,pt_hdkey,
pt_hdpartnerkey,pt_hdday,pt_hdnights,pt_rckey,rc_name,pt_ackey, pt_rmkey,
pt_nights,pt_tourname,pt_tourtype,tp_name,pt_hdname,pt_rate,ts_subcode1,ts_code,ts_day
order by pt_tourdate, pt_days, tp_name'

print @script
INSERT INTO #tmp
	EXEC(@script)

-- Формируем скрипт, заполняющий стоимость по ключу цены
declare @update_price as varchar(4000)
set @update_price = ''
	select @update_price = @update_price + 'update #tmp set rmkey_' + convert(varchar,rm_key) + ' = TP_Gross from TP_Prices where tp_key = pr_' + convert(varchar,rm_key) + '; '
	from #tmp1
	order by rm_key
--print @update_price
exec (@update_price)

DECLARE	@HotelKey int
DECLARE	@RoomKey int 
DECLARE	@RoomCategoryKey int 
declare @FromDate datetime
declare @HotelPartnerKey int 
declare @HotelDay int 
declare @HotelNights int 
declare @TourDuration int 


DECLARE hSql CURSOR 
	FOR 
		SELECT HotelKey, RoomKey, RoomCategoryKey,TourDate,HotelPartnerKey,HotelDay,HotelNights,TourDuration FROM #tmp
	FOR UPDATE OF QuotaPlaces, QuotaAllPlaces

OPEN hSql
FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey, @FromDate, @HotelPartnerKey, @HotelDay,@HotelNights,@TourDuration


declare @qt_places int
declare @qt_allplaces int

WHILE @@FETCH_STATUS = 0
BEGIN	
	select top 1 @qt_places = qt_places,@qt_allplaces = qt_allplaces from mwCheckQuotesEx(3, @HotelKey, @RoomKey, @RoomCategoryKey, @AgentKey, @HotelPartnerKey, @FromDate, @HotelDay, @HotelNights, @RequestOnRelease, @NoPlacesResult, @CheckAgentQuotes, @CheckCommonQuotes, 1, 0, 0, 0, 0, @TourDuration, @ExpiredReleaseResult)
	UPDATE #tmp SET QuotaPlaces = @qt_places, QuotaAllPlaces = @qt_allplaces
		WHERE current of hSql
		
	FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey, @FromDate, @HotelPartnerKey, @HotelDay,@HotelNights,@TourDuration
END
CLOSE hSql
DEALLOCATE hSql

select * from #tmp

drop table #tmp
drop table #tmp1

GO

grant exec on [dbo].[mwAutobusQuotes] to public
go

-- (100820)dropMwUpdateTriggers.sql
if exists(select id from sysobjects where xtype='TR' and name='mwUpdateHotel')
	drop trigger dbo.mwUpdateHotel
go

if exists(select id from sysobjects where xtype='TR' and name='mwTourTypeTrigger')
	drop trigger dbo.mwTourTypeTrigger
go

if exists(select id from sysobjects where xtype='TR' and name='mwTourNameWebTrigger')
	drop trigger dbo.mwTourNameWebTrigger
go

if exists(select id from sysobjects where xtype='TR' and name='mwCodeAndNameTrigger')
	drop trigger dbo.mwCodeAndNameTrigger
go

if exists(select id from sysobjects where xtype='TR' and name='onUpdate')
	drop trigger dbo.onUpdate
go

if exists(select id from sysobjects where xtype='TR' and name='mwUpdateWebHttp')
	drop trigger dbo.mwUpdateWebHttp
go

if exists(select id from sysobjects where xtype='TR' and name='mwUpdateTlWeb')
	drop trigger dbo.mwUpdateTlWeb
go


-- T_DogovorUpdate.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_DogovorUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_DogovorUpdate]
GO

CREATE TRIGGER [T_DogovorUpdate]
ON [dbo].[tbl_Dogovor] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2007.2.29.1</VERSION>
--<DATE>2009-07-23</DATE>
IF @@ROWCOUNT > 0
BEGIN
    DECLARE @ODG_Code		varchar(10)
    DECLARE @ODG_Price		float
    DECLARE @ODG_Rate		varchar(3)
    DECLARE @ODG_DiscountSum	float
    DECLARE @ODG_PartnerKey		int
    DECLARE @ODG_TRKey		int
    DECLARE @ODG_TurDate		varchar(10)
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
    
    DECLARE @NDG_Code		varchar(10)
    DECLARE @NDG_Price		float
    DECLARE @NDG_Rate		varchar(3)
    DECLARE @NDG_DiscountSum	float
    DECLARE @NDG_PartnerKey		int
    DECLARE @NDG_TRKey		int
    DECLARE @NDG_TurDate		varchar(10)
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

	DECLARE  @sUpdateMainDogovorStatuses varchar(254)
	
	DECLARE @nReservationNationalCurrencyRate smallint
	DECLARE @bReservationCreated smallint
	DECLARE @bCurrencyChangedPrevFixDate smallint
	DECLARE @bCurrencyChangedDate smallint
	DECLARE @bPriceChanged smallint
	DECLARE @bFeeChanged smallint
	DECLARE @bStatusChanged smallint
	DECLARE @changedDate datetime
	
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

  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED
  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT N.DG_Key, 
		N.DG_Code, null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null, null, 
		null, null, null, null, null, null, null, null, null,
		N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, CONVERT( char(10), N.DG_TurDate, 104), N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
		CONVERT( char(11), N.DG_PPaymentDate, 104) + CONVERT( char(5), N.DG_PPaymentDate, 108), CONVERT( char(10), N.DG_PaymentDate, 104), N.DG_RazmerP, N.DG_Procent, N.DG_Locked, N.DG_SOR_Code, N.DG_IsOutDoc, CONVERT( char(10), N.DG_VisaDate, 104), N.DG_CauseDisc, N.DG_OWNER, 
		N.DG_LEADDEPARTMENT, N.DG_DupUserKey, N.DG_MainMen, N.DG_MainMenEMail, N.DG_MAINMENPHONE, N.DG_CodePartner, N.DG_Creator, N.DG_CTDepartureKey, N.DG_Payed
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT O.DG_Key,
		O.DG_Code, O.DG_Price, O.DG_Rate, O.DG_DiscountSum, O.DG_PartnerKey, O.DG_TRKey, CONVERT( char(10), O.DG_TurDate, 104), O.DG_CTKEY, O.DG_NMEN, O.DG_NDAY, 
		CONVERT( char(11), O.DG_PPaymentDate, 104) + CONVERT( char(5), O.DG_PPaymentDate, 108), CONVERT( char(10), O.DG_PaymentDate, 104), O.DG_RazmerP, O.DG_Procent, O.DG_Locked, O.DG_SOR_Code, O.DG_IsOutDoc, CONVERT( char(10), O.DG_VisaDate, 104), O.DG_CauseDisc, O.DG_OWNER, 
		O.DG_LEADDEPARTMENT, O.DG_DupUserKey, O.DG_MainMen, O.DG_MainMenEMail, O.DG_MAINMENPHONE, O.DG_CodePartner, O.DG_Creator, O.DG_CTDepartureKey, O.DG_Payed,
		null, null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null, null, 
		null, null, null, null, null, null, null, null, null
      FROM DELETED O 
  END
ELSE 
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT N.DG_Key,
		O.DG_Code, O.DG_Price, O.DG_Rate, O.DG_DiscountSum, O.DG_PartnerKey, O.DG_TRKey, CONVERT( char(10), O.DG_TurDate, 104), O.DG_CTKEY, O.DG_NMEN, O.DG_NDAY, 
		CONVERT( char(11), O.DG_PPaymentDate, 104) + CONVERT( char(5), O.DG_PPaymentDate, 108), CONVERT( char(10), O.DG_PaymentDate, 104), O.DG_RazmerP, O.DG_Procent, O.DG_Locked, O.DG_SOR_Code, O.DG_IsOutDoc, CONVERT( char(10), O.DG_VisaDate, 104), O.DG_CauseDisc, O.DG_OWNER, 
		O.DG_LEADDEPARTMENT, O.DG_DupUserKey, O.DG_MainMen, O.DG_MainMenEMail, O.DG_MAINMENPHONE, O.DG_CodePartner, O.DG_Creator, O.DG_CTDepartureKey, O.DG_Payed,
		N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, CONVERT( char(10), N.DG_TurDate, 104), N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
		CONVERT( char(11), N.DG_PPaymentDate, 104) + CONVERT( char(5), N.DG_PPaymentDate, 108),  CONVERT( char(10), N.DG_PaymentDate, 104), N.DG_RazmerP, N.DG_Procent, N.DG_Locked, N.DG_SOR_Code, N.DG_IsOutDoc,  CONVERT( char(10), N.DG_VisaDate, 104), N.DG_CauseDisc, N.DG_OWNER, 
		N.DG_LEADDEPARTMENT, N.DG_DupUserKey, N.DG_MainMen, N.DG_MainMenEMail, N.DG_MAINMENPHONE, N.DG_CodePartner, N.DG_Creator, N.DG_CTDepartureKey, N.DG_Payed
      FROM DELETED O, INSERTED N 
      WHERE N.DG_Key = O.DG_Key
  END
  
    OPEN cur_Dogovor
    FETCH NEXT FROM cur_Dogovor INTO @DG_Key,
		@ODG_Code, @ODG_Price, @ODG_Rate, @ODG_DiscountSum, @ODG_PartnerKey, @ODG_TRKey, @ODG_TurDate, @ODG_CTKEY, @ODG_NMEN, @ODG_NDAY, 
		@ODG_PPaymentDate, @ODG_PaymentDate, @ODG_RazmerP, @ODG_Procent, @ODG_Locked, @ODG_SOR_Code, @ODG_IsOutDoc, @ODG_VisaDate, @ODG_CauseDisc, @ODG_OWNER, 
		@ODG_LEADDEPARTMENT, @ODG_DupUserKey, @ODG_MainMen, @ODG_MainMenEMail, @ODG_MAINMENPHONE, @ODG_CodePartner, @ODG_Creator, @ODG_CTDepartureKey, @ODG_Payed,
		@NDG_Code, @NDG_Price, @NDG_Rate, @NDG_DiscountSum, @NDG_PartnerKey, @NDG_TRKey, @NDG_TurDate, @NDG_CTKEY, @NDG_NMEN, @NDG_NDAY, 
		@NDG_PPaymentDate, @NDG_PaymentDate, @NDG_RazmerP, @NDG_Procent, @NDG_Locked, @NDG_SOR_Code, @NDG_IsOutDoc, @NDG_VisaDate, @NDG_CauseDisc, @NDG_OWNER, 
		@NDG_LEADDEPARTMENT, @NDG_DupUserKey, @NDG_MainMen, @NDG_MainMenEMail, @NDG_MAINMENPHONE, @NDG_CodePartner, @NDG_Creator, @NDG_CTDepartureKey, @NDG_Payed

    WHILE @@FETCH_STATUS = 0
    BEGIN 
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
			ISNULL(@ODG_Payed, 0) != ISNULL(@NDG_Payed, 0)
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
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1010, @ODG_TurDate, @NDG_TurDate, null, null, null, null, 0, @bNeedCommunicationUpdate output

				Update DogovorList set DL_TURDATE = CONVERT(datetime, @NDG_TurDate, 104) where DL_DGKey = @DG_Key
				Update tbl_Turist set TU_TURDATE = CONVERT(datetime, @NDG_TurDate, 104) where TU_DGKey = @DG_Key

				--Путевка разаннулируется
				IF (ISNULL(@ODG_SOR_Code, 0) = 2)
				BEGIN
					DECLARE @nDGSorCode_New int, @sDisableDogovorStatusChange int

					SELECT @sDisableDogovorStatusChange = SS_ParmValue FROM SystemSettings WHERE SS_ParmName like 'SYSDisDogovorStatusChange'
					IF (@sDisableDogovorStatusChange is null or @sDisableDogovorStatusChange = '0')
					BEGIN
						exec dbo.SetReservationStatus @DG_Key
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
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1013, @ODG_NDAY, @NDG_NDAY, null, null, null, null, 0, @bNeedCommunicationUpdate output
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
		if (ISNULL(@ODG_SOR_Code, 0) != ISNULL(@NDG_SOR_Code, 0))
			BEGIN
				Select @sText_Old = OS_Name_Rus, @nValue_Old = OS_Global from Order_Status Where OS_Code = @ODG_SOR_Code
				Select @sText_New = OS_Name_Rus, @nValue_New = OS_Global from Order_Status Where OS_Code = @NDG_SOR_Code
				If @nValue_New = 7 and @nValue_Old != 7
					UPDATE [dbo].[tbl_Dogovor] SET DG_ConfirmedDate = GetDate() WHERE DG_Key = @DG_Key
				If @nValue_New != 7 and @nValue_Old = 7
					UPDATE [dbo].[tbl_Dogovor] SET DG_ConfirmedDate = NULL WHERE DG_Key = @DG_Key
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1019, @sText_Old, @sText_New, @ODG_SOR_Code, @NDG_SOR_Code, null, null, 0, @bNeedCommunicationUpdate output
				------путевка была создана--------------
				if (ISNULL(@ODG_SOR_Code, 0) = 0 and @sMod = 'INS')
					EXECUTE dbo.InsertHistoryDetail @nHIID, 1122, null, null, null, null, null, null, 1, @bNeedCommunicationUpdate output
				------путевка была аннулирована--------------
				if (@NDG_SOR_Code = 2 and @sMod = 'UPD')
					EXECUTE dbo.InsertHistoryDetail @nHIID, 1123, null, null, null, null, null, null, 1, @bNeedCommunicationUpdate output
				
				if @bStatusChanged > 0 and exists(select NC_Id from NationalCurrencyReservationStatuses with(nolock) where NC_OrderStatus = ISNULL(@NDG_SOR_Code, 0))
				begin
					if (@bCurrencyChangedPrevFixDate > 0)
						set @changedDate = ISNULL(dbo.GetFirstDogovorStatusDate (@DG_Key, @NDG_SOR_Code), GetDate())
					
					SET @bUpdateNationalCurrencyPrice = 1
				end
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

		If @bNeedCommunicationUpdate=1
			If exists (SELECT 1 FROM Communications WHERE CM_DGKey=@DG_Key)
				UPDATE Communications SET CM_ChangeDate=GetDate() WHERE CM_DGKey=@DG_Key

		
		-- $$$ PRICE RECALCULATION $$$ --
		IF (@bUpdateNationalCurrencyPrice = 1 AND @sMod = 'UPD') OR (@sMod = 'INS' AND @bReservationCreated > 0)
		BEGIN
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

    	  FETCH NEXT FROM cur_Dogovor INTO @DG_Key,
		@ODG_Code, @ODG_Price, @ODG_Rate, @ODG_DiscountSum, @ODG_PartnerKey, @ODG_TRKey, @ODG_TurDate, @ODG_CTKEY, @ODG_NMEN, @ODG_NDAY, 
		@ODG_PPaymentDate, @ODG_PaymentDate, @ODG_RazmerP, @ODG_Procent, @ODG_Locked, @ODG_SOR_Code, @ODG_IsOutDoc, @ODG_VisaDate, @ODG_CauseDisc, @ODG_OWNER, 
		@ODG_LEADDEPARTMENT, @ODG_DupUserKey, @ODG_MainMen, @ODG_MainMenEMail, @ODG_MAINMENPHONE, @ODG_CodePartner, @ODG_Creator, @ODG_CTDepartureKey, @ODG_Payed,
		@NDG_Code, @NDG_Price, @NDG_Rate, @NDG_DiscountSum, @NDG_PartnerKey, @NDG_TRKey, @NDG_TurDate, @NDG_CTKEY, @NDG_NMEN, @NDG_NDAY, 
		@NDG_PPaymentDate, @NDG_PaymentDate, @NDG_RazmerP, @NDG_Procent, @NDG_Locked, @NDG_SOR_Code, @NDG_IsOutDoc, @NDG_VisaDate, @NDG_CauseDisc, @NDG_OWNER, 
		@NDG_LEADDEPARTMENT, @NDG_DupUserKey, @NDG_MainMen, @NDG_MainMenEMail, @NDG_MAINMENPHONE, @NDG_CodePartner, @NDG_Creator, @NDG_CTDepartureKey, @NDG_Payed
    END
  CLOSE cur_Dogovor
  DEALLOCATE cur_Dogovor
END
GO

-- fn_DateToChar.sql
if object_id('dbo.DateToChar', 'fn') is not null
	drop function dbo.DateToChar
go

create function dbo.DateToChar(@date datetime, @format varchar(20))
returns varchar(10)
as
begin
	if @format is null
		set @format = 'yyyy-MM-dd'

	if (lower(@format) = 'dd.mm.yyyy')
		return CONVERT(varchar(10), @date, 104)

	return CONVERT(varchar(10), @date, 21)
end
go

grant exec on dbo.DateToChar to public
go

-- job_SyncDictionaryData.sql
/****** Object:  Job [mwSyncDictionaryData]  ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [MasterWeb_JobCategory] ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'MasterWeb_JobCategory' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'MasterWeb_JobCategory'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE name = N'mwSyncDictionaryData'
IF (@jobId IS NOT NULL)
	EXEC msdb.dbo.sp_delete_job @jobId
SET @jobId = NULL

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'mwSyncDictionaryData', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Синхронизирует данные в поисковых таблицах с данными в справочниках.', 
		@category_name=N'MasterWeb_JobCategory', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ExecProc]    Script Date: 08/20/2010 15:48:20 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ExecProc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec mwSyncDictionaryData 1', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SyncSchedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20100820, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- 100825InsertObjectAliases.sql
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 31))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(31, 'SystemSettings', 'Настройки программы', 75)
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 31001))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(31001, 'SS_ParmValue', 'Значение параметра', 75)
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 32))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(32, 'NationalCurrencyReservationStatuses', 'Курс национальной валюты в путевке', 76)
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 32001))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(32001, 'NC_OrderStatus', 'Статус', 76)
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 32002))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(32002, 'NC_Multiplicity', 'Кратность', 76)

-- 100728 create NationalCurrencyReservationStatuses.sql
--создать таблицу
IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[NationalCurrencyReservationStatuses]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[NationalCurrencyReservationStatuses]
GO
CREATE TABLE [dbo].[NationalCurrencyReservationStatuses](
	[NC_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_NationalCurrencyReservationStatuses] PRIMARY KEY CLUSTERED,
	[NC_OrderStatus] [int] NOT NULL CONSTRAINT [FK_NationalCurrencyReservationStatuses_Order_Status] 
	REFERENCES [dbo].[Order_Status]([OS_CODE]) ON DELETE CASCADE,
	[NC_Multiplicity] [int] NOT NULL 
)
GO
GRANT SELECT, UPDATE, INSERT, DELETE ON [dbo].[NationalCurrencyReservationStatuses] TO PUBLIC
GO




-- T_NCReservationStatusesUpdate.sql
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[T_NCReservationStatusesUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [dbo].[T_NCReservationStatusesUpdate]
GO

CREATE TRIGGER [dbo].[T_NCReservationStatusesUpdate]
ON [dbo].[NationalCurrencyReservationStatuses] 
FOR INSERT, DELETE, UPDATE
AS

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
			END
			IF(ISNULL(@ONC_Multiplicity, 0) != ISNULL(@NNC_Multiplicity, 0))
			BEGIN 
				SET @HiText = 'Значение колонки NC_Multiplicity изменилось с '+CAST(@oldValue AS varchar(3))+' на '+CAST(@newValue AS varchar(3))
				SET @OAID = 32002
			END
			EXEC @HIID = dbo.InsHistory null, null, 32, @NC_ID, @Mod, @HiText, @hostName, 0, ''
			EXEC dbo.InsertHistoryDetail @HIID , @OAID, null, null, @oldValue, @newValue, null, null, 0, @bNeedCommunicationUpdate output
		END
		FETCH NEXT FROM cur_Modification INTO @NC_ID
										, @ONC_OrderStatus, @ONC_Multiplicity
										, @NNC_OrderStatus, @NNC_Multiplicity
	END
	CLOSE cur_Modification
	DEALLOCATE cur_Modification
END

GO

-- T_SystemSettingsUpdate.sql
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[T_SystemSettingsUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [dbo].[T_SystemSettingsUpdate]
GO

CREATE TRIGGER [dbo].[T_SystemSettingsUpdate] 
ON [dbo].[SystemSettings] 
FOR UPDATE
AS

IF @@ROWCOUNT > 0
BEGIN
	DECLARE @SS_ID int
	DECLARE @SS_ParmName varchar(25)
	DECLARE @OSS_ParmValue varchar(254)
	DECLARE @NSS_ParmValue varchar(254)
	DECLARE @HIID int
	DECLARE @Mod varchar(3)
	DECLARE @HiText varchar(254)
	DECLARE @hostName varchar(25)
	DECLARE @bNeedCommunicationUpdate smallint
	DECLARE @newValue varchar(3)
	DECLARE @oldValue varchar(3) 
	
	SET @hostName = SUBSTRING(HOST_NAME(),1,25);
	SET @Mod = 'UPD'
	DECLARE cur_Modification CURSOR FOR	
	SELECT N.SS_ParmName, N.SS_ID 
		 , O.SS_ParmValue
		 , N.SS_ParmValue
	FROM INSERTED N, DELETED O
	WHERE N.SS_ID = O.SS_ID
	OPEN cur_Modification
    FETCH NEXT FROM cur_Modification INTO @SS_ParmName, @SS_ID, @OSS_ParmValue, @NSS_ParmValue
    WHILE @@FETCH_STATUS = 0
    BEGIN 
		IF(@SS_ParmName like '%SYSReservationNCRate%' 
		AND (ISNULL(@OSS_ParmValue, '') != ISNULL(@NSS_ParmValue, '')))
		BEGIN
			SET @newValue = CAST(ISNULL(@NSS_ParmValue, '') AS varchar(3))
			SET @oldValue = CAST(ISNULL(@OSS_ParmValue, '') AS varchar(3))
			SET @HiText = 'Значение колонки SS_ParmValue изменилось с '+@oldValue+' на '+@newValue
			EXEC @HIID = dbo.InsHistory null, null, 31, @SS_ID, @Mod, @HiText, @hostName, 0, ''
			EXEC dbo.InsertHistoryDetail @HIID , 31001, @OSS_ParmValue, @NSS_ParmValue,  null, null, null, null, 0, @bNeedCommunicationUpdate output
		END
		FETCH NEXT FROM cur_Modification INTO @SS_ParmName, @SS_ID, @OSS_ParmValue, @NSS_ParmValue
	END
	CLOSE cur_Modification
	DEALLOCATE cur_Modification
END

GO


-- T_MappingsUpdate.sql
/****** Object:  Trigger [T_MappingsInsert]    Script Date: 07/09/2010 10:07:57 ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_MappingsInsert]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [dbo].[T_MappingsInsert]
GO

/****** Object:  Trigger [dbo].[T_MappingsInsert]    Script Date: 07/09/2010 10:07:57 ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_MappingsUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [dbo].[T_MappingsUpdate]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[T_MappingsUpdate] 
ON [dbo].[Mappings] 
FOR INSERT, UPDATE, DELETE
AS

IF @@ROWCOUNT > 0
BEGIN

	DECLARE @NMP_IntKey int
	DECLARE @NMP_CharKey varchar(10)
	DECLARE @NMP_Value varchar(10)
	DECLARE @NMP_PRKey int
	DECLARE @NMP_StrValue varchar(200)

	DECLARE @OMP_IntKey int
	DECLARE @OMP_CharKey varchar(10)
	DECLARE @OMP_Value varchar(10)
	DECLARE @OMP_PRKey int
	DECLARE @OMP_StrValue varchar(200)

	DECLARE @MP_CreateDate datetime
	DECLARE @MP_Key int
	DECLARE @MP_TableID smallint

	DECLARE @nDelCount int
	DECLARE @nInsCount int
	DECLARE @sMod varchar(3)
	DECLARE @nHIID int 
	DECLARE @bNeedCommunicationUpdate smallint
	DECLARE @sHiText varchar(254)
	
	DECLARE @newValue varchar(100)
	DECLARE @oldValue varchar(100)
	
	SELECT @nDelCount = COUNT(*) FROM DELETED
	SELECT @nInsCount = COUNT(*) FROM INSERTED
	
	if(@nInsCount = 0)
	BEGIN
		Set @sMod = 'DEL'
		DECLARE cur_Modification CURSOR FOR	
		SELECT O.MP_KEY, O.MP_TABLEID, O.MP_CREATEDATE
			 , O.MP_IntKey, O.MP_CharKey, O.MP_Value
			 , O.MP_PRKey, O.MP_StrValue
			 , null, null, null, null, null
		FROM DELETED O 
				
	END
	ELSE IF(@nDelCount = 0)
	BEGIN 
		Set @sMod = 'INS'
		
		DECLARE cur_Modification CURSOR FOR	
		SELECT N.MP_KEY, N.MP_TABLEID, N.MP_CREATEDATE
			 , null, null, null, null, null
			 , N.MP_IntKey, N.MP_CharKey, N.MP_Value
			 , N.MP_PRKey, N.MP_StrValue
		FROM INSERTED N 
	END
	ELSE
	BEGIN
		Set @sMod = 'UPD'
		DECLARE cur_Modification CURSOR FOR	
		SELECT N.MP_KEY, N.MP_TABLEID, N.MP_CREATEDATE
			 , O.MP_IntKey, O.MP_CharKey, O.MP_Value
			 , O.MP_PRKey, O.MP_StrValue
			 , N.MP_IntKey, N.MP_CharKey, N.MP_Value
			 , N.MP_PRKey, N.MP_StrValue
		FROM INSERTED N, DELETED O
		WHERE N.MP_KEY = O.MP_KEY
	END
	
	OPEN cur_Modification
    FETCH NEXT FROM cur_Modification INTO @MP_Key, @MP_TableID, @MP_CreateDate
		, @OMP_IntKey, @OMP_CharKey, @OMP_Value, @OMP_PRKey, @OMP_StrValue
		, @NMP_IntKey, @NMP_CharKey, @NMP_Value, @NMP_PRKey, @NMP_StrValue
    WHILE @@FETCH_STATUS = 0
    BEGIN 
		IF(@sMod = 'INS')
		BEGIN
			delete from [dbo].[Mappings] 
			where MP_Key != @MP_Key and MP_TableID = @MP_TableID
					and @NMP_IntKey = MP_IntKey and @NMP_Value = MP_Value 
					and @NMP_PRKey = MP_PRKey and @NMP_CharKey = MP_CharKey
		END
		IF((@sMod = 'INS' OR @sMod = 'UPD' OR @sMod = 'DEL') AND 
			((ISNULL(@OMP_IntKey, 0) != ISNULL(@NMP_IntKey, 0)) OR 
			(ISNULL(@OMP_CharKey, '') != ISNULL(@NMP_CharKey, '')) OR
			(ISNULL(@OMP_Value, '') != ISNULL(@NMP_Value, '')) OR
			(ISNULL(@OMP_PRKey, 0) != ISNULL(@NMP_PRKey, 0)) OR
			(ISNULL(@OMP_StrValue, '') != ISNULL(@NMP_StrValue, '')))
			)
		BEGIN
			DECLARE @hostName varchar(25);
			SET @hostName = SUBSTRING(HOST_NAME(),1,25);
			IF(ISNULL(@OMP_IntKey, 0) != ISNULL(@NMP_IntKey, 0))
			BEGIN
				SET @oldValue = CAST(ISNULL(@OMP_IntKey, 0) AS varchar(100))
				SET @newValue = CAST(ISNULL(@NMP_IntKey, 0) AS varchar(100))
				SET @sHiText = 'Значение колонки MP_IntKey изменилось с '+@oldValue+' на '+@newValue
				EXEC @nHIID = dbo.InsHistory null, null, 30, @MP_Key, @sMod, @sHiText, @hostName, 0, ''
				EXEC dbo.InsertHistoryDetail @nHIID , 30001,  null, null, @OMP_IntKey, @NMP_IntKey, null, null, 0, @bNeedCommunicationUpdate output
			END
			IF(ISNULL(@OMP_CharKey, '') != ISNULL(@NMP_CharKey, ''))
			BEGIN
				SET @oldValue = ISNULL(@OMP_CharKey, '') 
				SET @newValue = ISNULL(@NMP_CharKey, '') 
				SET @sHiText = 'Значение колонки MP_CharKey изменилось с ' + @oldValue+' на '+@newValue
				EXEC @nHIID = dbo.InsHistory null, null, 30, @MP_Key, @sMod, @sHiText, @hostName, 0, ''
				EXEC dbo.InsertHistoryDetail @nHIID , 30002, @OMP_CharKey, @NMP_CharKey, null, null, null, null, 0, @bNeedCommunicationUpdate output
			END
			IF(ISNULL(@OMP_Value, '') != ISNULL(@NMP_Value, ''))
			BEGIN
				SET @oldValue = ISNULL(@OMP_Value, '') 
				SET @newValue = ISNULL(@NMP_Value, '') 
				SET @sHiText = 'Значение колонки MP_Value изменилось с '+@oldValue+' на '+@newValue
				EXEC @nHIID = dbo.InsHistory null, null, 30, @MP_Key, @sMod, @sHiText, @hostName, 0, ''
				EXEC dbo.InsertHistoryDetail @nHIID , 30003, @OMP_Value, @NMP_Value, null, null, null, null, 0, @bNeedCommunicationUpdate output
			END
			IF(ISNULL(@OMP_PRKey, 0) != ISNULL(@NMP_PRKey, 0))
			BEGIN
				SET @oldValue = CAST(ISNULL(@OMP_PRKey, '') AS varchar(100))
				SET @newValue = CAST(ISNULL(@NMP_PRKey, '') AS varchar(100))
				SET @sHiText = 'Значение колонки MP_PRKey изменилось с '+@oldValue+' на '+@newValue
				EXEC @nHIID = dbo.InsHistory null, null, 30, @MP_Key, @sMod, @sHiText , @hostName, 0, ''
				EXEC dbo.InsertHistoryDetail @nHIID , 30004, null, null,  @OMP_PRKey, @NMP_PRKey, null, null, 0, @bNeedCommunicationUpdate output
			END
			IF(ISNULL(@OMP_StrValue, '') != ISNULL(@NMP_StrValue, ''))
			BEGIN
				IF(LEN(ISNULL(@OMP_StrValue, '')) > 100)
					SET @oldValue = SUBSTRING(@OMP_StrValue,1,100)
				ELSE
					SET @oldValue = ISNULL(@OMP_StrValue, '')
				IF(LEN(ISNULL(@NMP_StrValue, '')) > 100)
					SET @newValue = SUBSTRING(@NMP_StrValue,1,100)
				ELSE
					SET @newValue = ISNULL(@NMP_StrValue, '')
				SET @sHiText = 'Значение колонки MP_StrValue изменилось с '+@oldValue+' на '+@newValue
				EXEC @nHIID = dbo.InsHistory null, null, 30, @MP_Key, @sMod, @sHiText, @hostName, 0, ''
				EXEC dbo.InsertHistoryDetail @nHIID , 30005, @OMP_StrValue, @NMP_StrValue, null, null, null, null, 0, @bNeedCommunicationUpdate output   
			END
		END
		FETCH NEXT FROM cur_Modification INTO @MP_Key, @MP_TableID, @MP_CreateDate
			, @OMP_IntKey, @OMP_CharKey, @OMP_Value, @OMP_PRKey, @OMP_StrValue
			, @NMP_IntKey, @NMP_CharKey, @NMP_Value, @NMP_PRKey, @NMP_StrValue
    END
  CLOSE cur_Modification
  DEALLOCATE cur_Modification
END

GO




-- tr_mwUpdateHotel.sql
/****** Объект:  Trigger [mwUpdateHotel]    Дата сценария: 07/29/2010 15:39:38 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[mwUpdateHotel]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [dbo].[mwUpdateHotel]
GO

/****** Объект:  Trigger [dbo].[mwUpdateHotel]    Дата сценария: 07/29/2010 15:39:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE TRIGGER [dbo].[mwUpdateHotel] ON [dbo].[HotelDictionary] 
FOR UPDATE 
AS
IF @@ROWCOUNT > 0
begin
	
	UPDATE dbo.HotelDictionary
	SET HD_STARS = (SELECT COH_Name FROM dbo.CategoriesOfHotel WHERE dbo.CategoriesOfHotel.COH_Id = dbo.HotelDictionary.HD_COHId)
	FROM dbo.HotelDictionary join inserted on dbo.HotelDictionary.HD_Key = inserted.HD_KEY

	if (UPDATE(HD_RSKEY) or UPDATE(HD_STARS) or UPDATE(HD_HTTP) or UPDATE(HD_NAME))
	begin

		declare @mwSearchType int
		select  @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings 
			where SS_ParmName = 'MWDivideByCountry'
	
		if (@mwSearchType = 0)
		begin
			update mwPriceDataTable
			set pt_rskey = hd_rskey,
				pt_hdstars = hd_stars,
				pt_hotelurl = hd_http,
				pt_hdname = hd_name
			from inserted where pt_hdkey = hd_key
		end
		else
		begin
			declare @objName nvarchar(50)
			declare @sql nvarchar(500)
			declare @countryKey int
			select	@countryKey = hd_cnkey from inserted

			select hd_key, hd_rskey, hd_stars, hd_name into #temp from inserted

			declare delCursor cursor fast_forward read_only for select name from sysobjects where name like 'mwPriceDataTable_' + ltrim(rtrim(cast(isnull(@countryKey, 0) as varchar))) + '_%' and xtype='u'
			open delCursor
			fetch next from delCursor into @objName
			while(@@fetch_status = 0)
			begin
				set @sql = '
					update ' + @objName + ' with(rowlock)
						set pt_rskey = hd_rskey,
							pt_hdstars = hd_stars,
							pt_hotelurl = hd_http,
							pt_hdname = hd_name
						from #temp where pt_hdkey = hd_key'
				exec sp_executesql @sql
				fetch next from delCursor into @objName
			end
			close delCursor
			deallocate delCursor
		end		

		update dbo.mwSpoDataTable 
		set sd_rskey = hd_rskey, 
			sd_hdstars = hd_stars,
			sd_hotelurl = hd_http,
			sd_hdname = hd_name
		from inserted where sd_hdkey = hd_key

	end
end
GO

-- fn_mwTourHotelStars.sql
------------------------------------------
--- Create Function [mwTourHotelStars] ---
------------------------------------------

if exists(select id from sysobjects where name='mwTourHotelStars' and xtype='fn')
	drop function dbo.[mwTourHotelStars]
go

create function [dbo].[mwTourHotelStars] (@tourkey int) returns varchar(256)
as
begin
	declare @result varchar(256)
	set @result = ''
	
	select @result = @result + rtrim(ltrim(tbl.sd_hdstars)) + ', ' 
	from 
	(
		select distinct sd_hdstars 
		from mwSpoData with(nolock) 
		where sd_tourkey= @tourkey
	) as tbl 
	order by tbl.sd_hdstars

	declare @len int
	set @len = len(@result)
	if(@len > 0)
		set @result = substring(@result, 1, @len - 1)

	return @result
end
go

grant exec on [dbo].[mwTourHotelStars] to public
go

-- sp_mwSyncDictionaryData.sql
--kadraliev MEG00029412 30.09.2010 Добавил проверку isnull при сравнении значений полей
if object_id('dbo.mwSyncDictionaryData', 'p') is not null
	drop proc dbo.mwSyncDictionaryData
go

create proc dbo.mwSyncDictionaryData 
	@update_search_table smallint = 0, -- нужно ли синхронизировать данные в mwPriceDataTable
	@update_fields varchar(1024) = NULL -- какие именно данные нужно синхронизировать
as
begin
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

	declare @fields table(fname varchar(20));
	declare @blUpdateAllFields smallint

	declare @isAccomodationFirstForSync smallint
	select @isAccomodationFirstForSync = count(*)
	from dbo.SystemSettings
	where 
		(SS_ParmName='MWAccomodationPlaces' and SS_ParmValue=1) or
		(SS_ParmName='MWAccomodationPlaces' and SS_ParmValue=0 and not exists (select * from dbo.SystemSettings where SS_ParmName='MWRoomsExtraPlaces' and SS_ParmValue=1))

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
	if (@blUpdateAllFields = 1) or exists(select * from @fields where fname='COUNTRY')
	begin
		-- mwSpoDataTable
		while exists(select 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select 1 from tbl_country with(nolock) 
				where sd_cnkey = cn_key
					and isnull(sd_cnname, '') <> isnull(cn_name, '')))
		begin
			update dbo.mwSpoDataTable
			set
				sd_cnname = cn_name
			from
				tbl_country
			where
				sd_cnkey = cn_key
				and isnull(sd_cnname, '') <> isnull(cn_name, '')
		end
	end
	
	-- отель
	if (@blUpdateAllFields = 1) or exists(select * from @fields where fname='HOTEL')
	begin
		-- mwSpoDataTable
		while exists(select 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select 1 from dbo.hoteldictionary with(nolock) where
				sd_hdkey = hd_key
				and (
					isnull(sd_hdstars, '') <> isnull(hd_stars, '')
					or isnull(sd_ctkey, 0) <> isnull(hd_ctkey, 0)
					or isnull(sd_rskey, 0) <> isnull(hd_rskey, 0)
					or isnull(sd_hdname, '') <> isnull(hd_name, '')
					or isnull(sd_hotelurl, '') <> isnull(hd_http, '')
				)
			)
		)
		begin
			update dbo.mwSpoDataTable
			set
				sd_hdstars = hd_stars,
				sd_ctkey = hd_ctkey,
				sd_rskey = hd_rskey,
				sd_hdname = hd_name,
				sd_hotelurl = hd_http
			from
				dbo.hoteldictionary
			where
				sd_hdkey = hd_key
				and (
					isnull(sd_hdstars, '') <> isnull(hd_stars, '')
					or isnull(sd_ctkey, 0) <> isnull(hd_ctkey, 0)
					or isnull(sd_rskey, 0) <> isnull(hd_rskey, 0)
					or isnull(sd_hdname, '') <> isnull(hd_name, '')
					or isnull(sd_hotelurl, '') <> isnull(hd_http, '')
				)
		end
		
		-- mwPriceDataTable	
		if @update_search_table > 0
		begin
			while exists(select 1 from dbo.mwPriceDataTable with(nolock) 
				where exists(select 1 from dbo.hoteldictionary with(nolock) where
					pt_hdkey = hd_key
					and (
						isnull(pt_hdstars, '') <> isnull(hd_stars, '')
						or isnull(pt_ctkey, 0) <> isnull(hd_ctkey, 0)
						or isnull(pt_rskey, 0) <> isnull(hd_rskey, 0)
						or isnull(pt_hdname, '') <> isnull(hd_name, '')
						or isnull(pt_hotelurl, '') <> isnull(hd_http, '')
					)
				)
			)
			begin
				update dbo.mwPriceDataTable
				set
					pt_hdstars = hd_stars,
					pt_ctkey = hd_ctkey,
					pt_rskey = hd_rskey,
					pt_hdname = hd_name,
					pt_hotelurl = hd_http
				from
					dbo.hoteldictionary
				where
					pt_hdkey = hd_key
					and (
						isnull(pt_hdstars, '') <> isnull(hd_stars, '')
						or isnull(pt_ctkey, 0) <> isnull(hd_ctkey, 0)
						or isnull(pt_rskey, 0) <> isnull(hd_rskey, 0)
						or isnull(pt_hdname, '') <> isnull(hd_name, '')
						or isnull(pt_hotelurl, '') <> isnull(hd_http, '')
					)
			end
		end
	end
	
	-- город отправления
	if (@blUpdateAllFields = 1) or exists(select * from @fields where fname='CITY')
	begin
		-- mwSpoDataTable
		while exists(select 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select 1 from citydictionary with(nolock) 
				where sd_ctkeyfrom = ct_key
					and isnull(sd_ctfromname, '') <> isnull(ct_name, '')))
		begin
			update dbo.mwSpoDataTable
			set
				sd_ctfromname = ct_name
			from
				dbo.citydictionary
			where
				sd_ctkeyfrom = ct_key
				and isnull(sd_ctfromname, '') <> isnull(ct_name, '')
		end

		while exists(select 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select 1 from citydictionary with(nolock) 
				where sd_ctkey = ct_key
					and isnull(sd_ctname, '') <> isnull(ct_name, '')))
		begin
			update dbo.mwSpoDataTable
			set
				sd_ctname = ct_name
			from
				dbo.citydictionary
			where
				sd_ctkey = ct_key
				and isnull(sd_ctname, '') <> isnull(ct_name, '')
		end	
		
		-- mwPriceDataTable
		if @update_search_table > 0
		begin
			while exists(select 1 from dbo.mwPriceDataTable with(nolock)
				where exists(select 1 from dbo.citydictionary with(nolock) where
					pt_ctkey = ct_key
					and isnull(pt_ctname, '') <> isnull(ct_name, '')
				)
			)
			begin
				update dbo.mwPriceDataTable
				set
					pt_ctname = ct_name
				from
					dbo.citydictionary
				where
					pt_ctkey = ct_key
					and isnull(pt_ctname, '') <> isnull(ct_name, '')
			end
		end
	end
	
	--курорт
	if (@blUpdateAllFields = 1) or exists(select * from @fields where fname='RESORT')
	begin
		-- mwSpoDataTable
		while exists(select 1 from dbo.mwSpoDataTable with(nolock)
			where exists(select 1 from dbo.resorts with(nolock) where
				sd_rskey = rs_key
				and isnull(sd_rsname, '') <> isnull(rs_name, '')
			)
		)
		begin
			update dbo.mwSpoDataTable
			set
				sd_rsname = rs_name
			from
				dbo.resorts
			where
				sd_rskey = rs_key
				and isnull(sd_rsname, '') <> isnull(rs_name, '')
		end
		
		-- mwPriceDataTable	
		if @update_search_table > 0
		begin
			while exists(select 1 from dbo.mwPriceDataTable with(nolock)
				where exists(select 1 from dbo.resorts with(nolock) where
					pt_rskey = rs_key
					and isnull(pt_rsname, '') <> isnull(rs_name, '')
				)
			)		
			begin
				update dbo.mwPriceDataTable
				set
					pt_rsname = rs_name
				from
					dbo.resorts
				where
					pt_rskey = rs_key
					and isnull(pt_rsname, '') <> isnull(rs_name, '')
			end
		end
	end
	
	-- тур
	if (@blUpdateAllFields = 1) or exists(select * from @fields where fname='TOUR')
	begin
		while exists(select 1 from dbo.mwSpoDataTable with(nolock)
			where exists(select 1 from dbo.tbl_turlist with(nolock) where
				sd_tlkey = tl_key
				and (
					isnull(sd_tourname, '') <> isnull(tl_nameweb, '')
					or isnull(sd_tourtype, 0) <> isnull(tl_tip, 0)
				)
			)
		)
		begin
			update dbo.mwSpoDataTable
			set
				sd_tourname = tl_nameweb,
				sd_tourtype = tl_tip
			from
				dbo.tbl_turlist
			where
				sd_tlkey = tl_key
				and (
					isnull(sd_tourname, '') <> isnull(tl_nameweb, '')
					or isnull(sd_tourtype, 0) <> isnull(tl_tip, 0)
				)
		end
		
		-- mwPriceDataTable	
		if @update_search_table > 0
		begin			
			while exists(select 1 from dbo.mwPriceDataTable with(nolock)
				where exists(select 1 from dbo.tbl_turlist with(nolock) where
					pt_tlkey = tl_key
					and (
						isnull(pt_tourname, '') <> isnull(tl_nameweb, '') or
						isnull(pt_toururl, '') <> isnull(tl_webhttp, '') or
						isnull(pt_tourtype, 0) <> isnull(tl_tip, 0)
					)
				)
			)
			begin
				update dbo.mwPriceDataTable
				set
					pt_tourname = tl_nameweb,
					pt_toururl = tl_webhttp,
					pt_tourtype = tl_tip
				from
					dbo.tbl_turlist
				where
					pt_tlkey = tl_key
					and (
						isnull(pt_tourname, '') <> isnull(tl_nameweb, '') or
						isnull(pt_toururl, '') <> isnull(tl_webhttp, '') or
						isnull(pt_tourtype, 0) <> isnull(tl_tip, 0)
					)
			end
		end
	end
	
	-- тип тура
	if (@blUpdateAllFields = 1) or exists(select * from @fields where fname='TOURTYPE')
	begin
		while exists(select 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select 1 from dbo.tiptur with(nolock) 
				where sd_tourtype = tp_key
					and isnull(sd_tourtypename, '') <> isnull(tp_name, '')))
		begin
			update dbo.mwSpoDataTable
			set
				sd_tourtypename = tp_name
			from
				dbo.tiptur
			where
				sd_tourtype = tp_key
				and isnull(sd_tourtypename, '') <> isnull(tp_name, '')
		end
	end

	-- питание
	if (@blUpdateAllFields = 1) or exists(select * from @fields where fname='PANSION')
	begin
		while exists(select 1 from dbo.mwSpoDataTable with(nolock) 
			where exists(select 1 from dbo.pansion with(nolock) 
				where sd_pnkey = pn_key
					and isnull(sd_pncode, '') <> isnull(pn_code, '')))
		begin
			update dbo.mwSpoDataTable
			set
				sd_pncode = pn_code
			from
				dbo.pansion
			where
				sd_pnkey = pn_key
				and isnull(sd_pncode, '') <> isnull(pn_code, '')
		end	
		
		if @update_search_table > 0
		begin
			while exists(select 1 from dbo.mwPriceDataTable with(nolock)
				where exists(select 1 from dbo.pansion with(nolock) where
					pt_pnkey = pn_key
					and (
						isnull(pt_pnname, '') <> isnull(pn_name, '') or
						isnull(pt_pncode, '') <> isnull(pn_code, '')
					)
				)
			)
			begin
				update dbo.mwPriceDataTable
				set 
					pt_pnname = pn_name,
					pt_pncode = pn_code
				from dbo.pansion
				where
					pt_pnkey = pn_key
					and (
						isnull(pt_pnname, '') <> isnull(pn_name, '') or
						isnull(pt_pncode, '') <> isnull(pn_code, '')
					)

			end
		end
	end
	
	-- номер	
	if ((@blUpdateAllFields = 1) or exists(select * from @fields where fname='ROOM')) and @update_search_table > 0
	begin
		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.rooms with(nolock) where
				pt_rmkey = rm_key
				and (
					isnull(pt_rmname, '') <> isnull(rm_name, '')
					or isnull(pt_rmcode, '') <> isnull(rm_code, '')
					or isnull(pt_rmorder, 0) <> isnull(rm_order, 0)
				)
			)
		)
		begin
			update dbo.mwPriceDataTable
			set
				pt_rmname = rm_name,
				pt_rmcode = rm_code,
				pt_rmorder = rm_order
			from
				dbo.rooms
			where
				pt_rmkey = rm_key
				and (
					isnull(pt_rmname, '') <> isnull(rm_name, '')
					or isnull(pt_rmcode, '') <> isnull(rm_code, '')
					or isnull(pt_rmorder, 0) <> isnull(rm_order, 0)		
				)			
		end
	end
	
	-- категория номера
	if ((@blUpdateAllFields = 1) or exists(select * from @fields where fname='ROOMCATEGORY')) and @update_search_table > 0
	begin
		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.roomscategory with(nolock) where
				pt_rckey = rc_key
				and (
					isnull(pt_rcname, '') <> isnull(rc_name, '')
					or isnull(pt_rccode, '') <> isnull(rc_code, '')
					or isnull(pt_rcorder, 0) <> isnull(rc_order, 0)
				)
			)
		)
		begin
			update dbo.mwPriceDataTable
			set
				pt_rcname = rc_name,
				pt_rccode = rc_code,
				pt_rcorder = rc_order
			from
				dbo.roomscategory
			where
				pt_rckey = rc_key
				and (
					isnull(pt_rcname, '') <> isnull(rc_name, '')
					or isnull(pt_rccode, '') <> isnull(rc_code, '')
					or isnull(pt_rcorder, 0) <> isnull(rc_order, 0)
				)
		end
	end
	
	-- размещение
	--kadraliev MEG00029412 29.09.2010 Добавил синхронизацию признака isMain, возрастов детей, количеству основных и дополнительных мест
	if ((@blUpdateAllFields = 1) or exists(select * from @fields where fname='ACCOMODATION')) and @update_search_table > 0
	begin	
		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.accmdmentype with(nolock) where
				pt_ackey = ac_key
				and (
					isnull(pt_acname, '') <> isnull(ac_name, '')
					or isnull(pt_accode, '') <> isnull(ac_code, '')
					or isnull(pt_acorder, 0) <> isnull(ac_order, 0)
					or isnull(pt_main, 0) <> isnull(ac_main, 0)
					or isnull(pt_childagefrom, 0) <> isnull(ac_agefrom, 0)
					or isnull(pt_childageto, 0) <> isnull(ac_ageto, 0)
					or isnull(pt_childagefrom2, 0) <> isnull(ac_agefrom2, 0)
					or isnull(pt_childageto2, 0) <> isnull(ac_ageto2, 0)
				)
			)
		)
		begin
			update dbo.mwPriceDataTable
			set
				pt_acname = ac_name,
				pt_accode = ac_code,
				pt_acorder = ac_order,
				pt_main = ac_main,
				pt_childagefrom = ac_agefrom,
				pt_childageto = ac_ageto,
				pt_childagefrom2 = ac_agefrom2,
				pt_childageto2 = ac_ageto2
			from
				dbo.accmdmentype
			where
				pt_ackey = ac_key
				and (
					isnull(pt_acname, '') <> isnull(ac_name, '')
					or isnull(pt_accode, '') <> isnull(ac_code, '')
					or isnull(pt_acorder, 0) <> isnull(ac_order, 0)
					or isnull(pt_main, 0) <> isnull(ac_main, 0)
					or isnull(pt_childagefrom, 0) <> isnull(ac_agefrom, 0)
					or isnull(pt_childageto, 0) <> isnull(ac_ageto, 0)
					or isnull(pt_childagefrom2, 0) <> isnull(ac_agefrom2, 0)
					or isnull(pt_childageto2, 0) <> isnull(ac_ageto2, 0)
				)
		end
	end
		
	--kadraliev MEG00029412 29.09.2010 номер и размещение (признак isMain, количество основных и дополнительных мест)
	if ((@blUpdateAllFields = 1) or exists(select * from @fields where fname='ROOM' or fname='ACCOMODATION')) and @update_search_table > 0
	begin
		if (@isAccomodationFirstForSync = 0)
		begin
			while exists(select 1 from dbo.mwPriceDataTable with(nolock)
				where exists(select 1 from dbo.rooms with(nolock) where
					pt_rmkey = rm_key
					and (
						isnull(pt_mainplaces, 0) <> isnull(rm_nplaces, 0)
						or isnull(pt_addplaces, 0) <> isnull(rm_nplacesex, 0)
					)
				)
			)
			begin				
				update dbo.mwPriceDataTable
				set
					pt_mainplaces = rm_nplaces,
					pt_addplaces = rm_nplacesex
				from
					dbo.rooms
				where
					pt_rmkey = rm_key
					and (
						isnull(pt_mainplaces, 0) <> isnull(rm_nplaces, 0)
						or isnull(pt_addplaces, 0) <> isnull(rm_nplacesex, 0)
					)				
			end
		end
		else begin
			while exists(select 1 from dbo.mwPriceDataTable with(nolock)
				where exists(select 1 from dbo.accmdmentype with(nolock) where
					pt_ackey = ac_key
					and (
						isnull(pt_acname, '') <> isnull(ac_name, '')
						or isnull(pt_accode, '') <> isnull(ac_code, '')
						or isnull(pt_acorder, 0) <> isnull(ac_order, 0)
					)
				)
			)
			begin
				update dbo.mwPriceDataTable
				set
					pt_main = ac_main,
					pt_mainplaces = ac_nrealplaces,
					pt_addplaces = ac_nmenexbed
				from
					dbo.accmdmentype
				where
					pt_ackey = ac_key
					and (
						isnull(pt_main, 0)  <> isnull(ac_main, 0)
						or isnull(pt_mainplaces, 0) <> isnull(ac_nrealplaces, 0)
						or isnull(pt_addplaces, 0) <> isnull(ac_nmenexbed, 0)
					)		
			end
		end
	end

	-- расчитанный тур
	if (@blUpdateAllFields = 1) or exists(select * from @fields where fname='TP_TOUR')
	begin
		while exists(select 1 from dbo.mwSpoDataTable with(nolock)
			where exists(select 1 from dbo.tp_tours with(nolock) where
				sd_tourkey = to_key
				and (
					isnull(sd_tourcreated, '2010-10-10') <> isnull(to_datecreated, '2010-10-10')
					or isnull(sd_tourvalid, '2010-10-10') <> isnull(to_datevalid, '2010-10-10')
				)
			)
		)
		begin
			update dbo.mwSpoDataTable
			set
				sd_tourcreated = to_datecreated,
				sd_tourvalid = to_datevalid
			from
				dbo.tp_tours
			where
				sd_tourkey = to_key
				and (
					isnull(sd_tourcreated, '2010-10-10') <> isnull(to_datecreated, '2010-10-10')
					or isnull(sd_tourvalid, '2010-10-10') <> isnull(to_datevalid, '2010-10-10')
				)
		end
		
		-- mwPriceDataTable
		if @update_search_table > 0
		begin			
			while exists(select 1 from dbo.mwPriceDataTable with(nolock)
				where exists(select 1 from dbo.tp_tours with(nolock) where
					pt_tourkey = to_key
					and (
						isnull(pt_tourcreated, '2010-10-10') <> isnull(to_datecreated, '2010-10-10')
						or isnull(pt_tourvalid, '2010-10-10') <> isnull(to_datevalid, '2010-10-10')
						or isnull(pt_rate, '') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '') COLLATE DATABASE_DEFAULT
					)
				)
			)
			begin
				update dbo.mwPriceDataTable
				set
					pt_tourcreated = to_datecreated,
					pt_tourvalid = to_datevalid,
					pt_rate = to_rate
				from
					dbo.tp_tours
				where
					pt_tourkey = to_key
					and (
						isnull(pt_tourcreated, '2010-10-10') <> isnull(to_datecreated, '2010-10-10')
						or isnull(pt_tourvalid, '2010-10-10') <> isnull(to_datevalid, '2010-10-10')
						or isnull(pt_rate, '') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '') COLLATE DATABASE_DEFAULT
					)
			end			
		end
	end
end
go

grant exec on dbo.mwSyncDictionaryData to public
go

-- Index_on_tbl_Dogovor_X_MW_PR_CR_DUP.sql
if exists(select 1 from sysindexes where name='X_MW_PR_CR_DUP' and id = object_id(N'tbl_Dogovor'))
	drop index [tbl_Dogovor].[X_MW_PR_CR_DUP]
go

CREATE NONCLUSTERED INDEX [X_MW_PR_CR_DUP] ON [dbo].[tbl_Dogovor] 
(
	[DG_PARTNERKEY] ASC,
	DG_CRDATE DESC,
	DG_DUPUSERKEY
)
GO

-- AlterTable_PrtBonuses.sql
if not exists(select id from syscolumns where id = OBJECT_ID('PrtBonuses') and name = 'PB_TotalExpense')
	alter table PrtBonuses ADD PB_TotalExpense money
go

-- AlterTable_PrtBonusDetails.sql
if not exists(select id from syscolumns where id = OBJECT_ID('PrtBonusDetails') and name = 'PBD_Expense')
	alter table PrtBonusDetails ADD PBD_Expense money
go

-- UpdateData_PrtBonuses.sql
UPDATE PrtBonuses
SET PB_PRKey = (select US_PRKey 
				from Dup_user 
				where US_Key=PB_DUKey)
WHERE PB_DUKey is not null
GO

-- UpdateData_PrtBonusDetails.sql
UPDATE PrtBonusDetails 
SET PBD_Expense =- PBD_Bonus, PBD_Bonus = 0
WHERE PBD_Bonus < 0
GO

-- UpdateData_UserSettings.sql
DELETE UserSettings
WHERE ST_ParmName = 'PrtBonusesForm.prtBonusesGrid'
GO

-- 20100827_Alter_ObjectGroupLinks.sql
if object_id('dbo.ObjectGroupLinks', 'u') is not null
	drop table dbo.ObjectGroupLinks
go

if object_id('dbo.ObjectGroupLinks', 'u') is null
begin
	create table dbo.ObjectGroupLinks(
		ogl_id int identity primary key,
		ogl_objtype int foreign key references dbo.ObjectTypes,
		ogl_objid int,
		ogl_group int foreign key references dbo.ObjectGroups on delete cascade,
		ogl_linked_group int foreign key references dbo.ObjectGroups,
		ogl_linked_objtype int foreign key references dbo.ObjectTypes,
		ogl_linked_objid int
	)

	grant select, insert, update, delete on dbo.ObjectGroupLinks to public
end
go

-- 100810_AlterTableDogovor.sql
--alter table tbl_Dogovor alter column DG_CrDate DateTime null
--go

--exec sp_refreshviewforall 'Dogovor'
--GO

-- sp_mwCheckFlightGroupsQuotesWithInnerFlights.sql
if exists(select id from sysobjects where xtype='p' and name='mwCheckFlightGroupsQuotesWithInnerFlights')
	drop proc dbo.mwCheckFlightGroupsQuotesWithInnerFlights
go

create procedure [dbo].[mwCheckFlightGroupsQuotesWithInnerFlights]
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
	@linkedcharters varchar(256)
as
begin
print @charters
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
	while (charindex(',', @linkedcharters, @curPosition + 1) > 0 or @flag = 0)
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

					exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @tourDays, @expiredReleaseResult, @aviaQuotaMask, @curQuota output, @linkedchday
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

-- sp_mwCheckBlackListTourist.sql
if exists(select id from sysobjects where name='mwCheckBlackListTourist' and xtype='p')
	drop procedure [dbo].[mwCheckBlackListTourist]
go

create procedure [dbo].[mwCheckBlackListTourist]
	@Name varchar(50),
	@FName varchar(50),
	@PassportSeria varchar(50) = null,
	@PassportNum varchar(50) = null,
	@PassportSeriaRus varchar(50) = null,
	@PassportNumRus varchar(50) = null
as
begin
	declare @result int
	set @result = 0
	-- если задан один из паспортов
	if (@PassportNum is not null and @PassportNum <> '') or (@PassportNumRus is not null and @PassportNumRus <> '')
	begin
		-- проверим только на паспорта, т.к. в фамилия или имя может храниться в базе не так, как вводит пользователь 
		-- или как преобразовала их транслитерация
	   select @result = case when exists (select 1 from clients
			where cl_type & 1 > 0 -- условие чёрности списка
					and (cl_pasportser = @PassportSeria or @PassportSeria is null or @PassportSeria='')
					and (cl_pasportnum = @PassportNum or @PassportNum is null or @PassportNum='')
					and (cl_paspruser = @PassportSeriaRus or @PassportSeriaRus is null or @PassportSeriaRus='')
					and (cl_pasprunum = @PassportNumRus or @PassportNumRus is null or @PassportNumRus='')
								)
				then 1 else 0 end
	end
	
	-- если по паспорту не нашли - ищем по фамилии
	if @result = 0
	begin
		select @result = case when exists (select 1 from clients
					where cl_type & 1 > 0 -- условие чёрности списка
						-- проверю что либо русские, либо латинские имя и фамилия совпадают(без учёта регистра)
						and ((upper(cl_namerus) = upper(@Name) and upper(cl_fnamerus) = upper(@FName)) or (upper(cl_namelat) = upper(@Name) and upper(cl_fnamelat) = upper(@FName)))
								)
					then 1 else 0 end
	end

	select @result
end
go

grant exec on [dbo].[mwCheckBlackListTourist] to public
go


-- 100908(AlterTable_Clients).sql
alter table Clients alter column CL_NAMERUS varchar(35) not null
go
alter table Clients alter column CL_NAMELAT varchar(35) not null
go

-- sp_GetSubKeysFromRecursive.sql
--------------------------------------------
--- Create Storage Procedure [GetSubKeysFromRecursive] ---
--------------------------------------------

if exists(select id from sysobjects where id = OBJECT_ID('GetSubKeysFromRecursive') and xtype = 'P')
	drop procedure dbo.GetSubKeysFromRecursive
go

CREATE procedure GetSubKeysFromRecursive 
	@table_name varchar(50),
	@pk_field varchar(50),
	@fk_field varchar(50),
	@pk_keys varchar(500)
as
begin
	create table #tmp (	pk int, fk int )
	
	declare @sql varchar(500)
	set @sql = 'insert into #tmp select ' + @pk_field + ', ' + @fk_field + ' from ' + @table_name + ' where ' + @pk_field + ' in (' + @pk_keys + ')'
	exec (@sql)

	declare @count_curr int
	select @count_curr = count(*) from #tmp

	declare @count_prev int
	set @count_prev = 0

	while (@count_curr != @count_prev)
	begin
		set @count_prev = @count_curr
		set @sql = 'insert into #tmp select ' + @pk_field + ', ' + @fk_field + ' from ' + @table_name + ' where ' + @pk_field + ' not in (select pk from #tmp) and ' + @fk_field + ' in (select pk from #tmp)'
		exec (@sql)
		select @count_curr = count(*) from #tmp	
	end

	declare @result varchar(1000)
		set @result = ''
	
	select @result = @result + ',' + cast(pk as varchar(10)) from #tmp
	
	if (len(@result) > 1)
		select (substring(@result, 2, len(@result) - 1))
	else 
		select ''
		
	drop table #tmp
end
go

grant exec on dbo.GetSubKeysFromRecursive to public
go

--exec GetSubKeysFromRecursive 'TipTur', 'TP_KEY', 'TP_TPKEY', '32,12'

-- tbl_CountrySettings.sql
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CountrySettings]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[CountrySettings](
	[CS_SSParmName] [varchar](25) NOT NULL,
	[CS_CNKey] [int] NOT NULL,
	[CS_Value] [varchar](254) NULL
)
GO

if not exists (select 1 from sysobjects where name = 'FK_CS_SSParmName' and xtype = 'F')
ALTER TABLE [dbo].[CountrySettings]  WITH CHECK ADD  CONSTRAINT [FK_CS_SSParmName] FOREIGN KEY([CS_SSParmName])
REFERENCES [dbo].[SystemSettings] ([SS_ParmName])
GO

if exists (select 1 from sysobjects where name = 'FK_CS_SSParmName' and xtype = 'F')
ALTER TABLE [dbo].[CountrySettings] CHECK CONSTRAINT [FK_CS_SSParmName]
GO

if not exists (select 1 from sysobjects where name = 'FK_CS_CNKey' and xtype = 'F')
ALTER TABLE [dbo].[CountrySettings]  WITH CHECK ADD  CONSTRAINT [FK_CS_CNKey] FOREIGN KEY([CS_CNKey])
REFERENCES [dbo].[tbl_Country] ([CN_Key])
GO

if exists (select 1 from sysobjects where name = 'FK_CS_CNKey' and xtype = 'F')
ALTER TABLE [dbo].[CountrySettings] CHECK CONSTRAINT [FK_CS_CNKey]
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[CountrySettings] TO PUBLIC
go


-- fn_GetCountrySetting.sql
if exists(select id from sysobjects where xtype='fn' and name='GetCountrySetting')
	drop function dbo.GetCountrySetting
GO

create function [dbo].[GetCountrySetting] (@cnkey int, @settingName [varchar](25)) returns [varchar](254)
as
begin
	declare @result [varchar](254)
	select @result = lower(rtrim(ltrim(cs_value)))
	from dbo.CountrySettings
	where cs_ssparmname = @settingName and cs_cnkey = @cnkey
	
	-- если эта настройка для страны не указана, возьмём из SystemSettings
	if @result is null
	begin
		select @result = lower(rtrim(ltrim(ss_parmvalue)))
		from dbo.SystemSettings
		where ss_parmname = @settingName
	end

	return @result
end
GO

grant exec on [dbo].[GetCountrySetting] to public
GO


-- sp_CheckQuotaExist.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CheckQuotaExist]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CheckQuotaExist]


GO
CREATE PROCEDURE [dbo].[CheckQuotaExist]
(
--<VERSION>2008.1.03.13a</VERSION>
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

/*
insert into Debug (db_Text) values ('@SVKey= '+CAST(@SVKey as varchar(10))+'
'+'@Code= '+CAST(@Code as varchar(10))+'
'+'@SubCode1= '+CAST(@SubCode1 as varchar(10))+'
'+'@DateBeg= '+CAST(@DateBeg as varchar(10))+'
'+'@DateEnd= '+CAST(@DateEnd as varchar(10))+'
'+'@DateFirst= '+CAST(@DateFirst as varchar(10))+'
'+'@PRKey= '+CAST(@PRKey as varchar(10))+'
'+'@AgentKey= '+CAST(@AgentKey as varchar(10))+'
'+'@TourDuration= '+CAST(@TourDuration as varchar(10))
)
*/
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
--declare @StopExist int, @StopDate smalldatetime
--Проверка отсутствия Стопа
declare @StopExist int, @StopDate smalldatetime

if not exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSCheckQuotaRelease' and SS_ParmValue=1)
	exec CheckStopInfo 1,null,@SVKey,@Code,@SubCode1,@PRKey,@DateBeg,@DateEnd,@StopExist output,@StopDate output

declare @Q_QTID int, @Q_Partner int, @Q_ByRoom int, @Q_Type int, @Q_Release int, 
		@Q_FilialKey int, @Q_CityDepartments int, @Q_AgentKey int, @Q_Duration smallint,
		@Q_Places smallint, @ServiceWithDuration bit, @SubQuery varchar(5000), @Query varchar(5000),
		@Q_SubCode1 int, @Q_SubCode2 int, @Q_QTID_Prev int, @DaysCount int

SET @DaysCount=DATEDIFF(DAY,@DateBeg,@DateEnd)+1
SET @Q_QTID_Prev=0

SELECT @ServiceWithDuration=ISNULL(SV_IsDuration,0) FROM [Service] WHERE SV_Key=@SVKey
IF @ServiceWithDuration=1
	SET @TourDuration=DATEDIFF(DAY,@DateBeg,@DateEnd)+1

IF @SVKey=3
BEGIN
	declare CheckQuotaExistСursor cursor for 
		select	DISTINCT QT_ID, QT_PRKey, QT_ByRoom, 
				QD_Type, 
				QP_FilialKey, QP_CityDepartments, QP_AgentKey, CASE WHEN QP_Durations='' THEN 0 ELSE @TourDuration END, QP_FilialKey, QP_CityDepartments, 
				QO_SubCode1, QO_SubCode2
		from	QuotaObjects, Quotas, QuotaDetails, QuotaParts, HotelRooms
		where	
			QO_SVKey=@SVKey and QO_Code=@Code and HR_Key=@SubCode1 and (QO_SubCode1=HR_RMKey or QO_SubCode1=0) and (QO_SubCode2=HR_RCKey or QO_SubCode2=0) and QO_QTID=QT_ID
			and QD_QTID=QT_ID and QD_Date between @DateBeg and @DateEnd
			and QP_QDID = QD_ID
			and (QP_AgentKey=@AgentKey or QP_AgentKey is null) 
			and (QT_PRKey=@PRKey or QT_PRKey=0)
			and QP_IsDeleted is null and QD_IsDeleted is null	
			and (QP_Durations = '' or @TourDuration in (Select QL_Duration From QuotaLimitations Where QL_QPID=QP_ID))
		group by QT_ID, QT_PRKey, QT_ByRoom, QD_Type, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_Durations, QO_SubCode1, QO_SubCode2
		--having Count(*) = (@Days+1)
		order by QP_AgentKey DESC, QT_PRKey DESC
END
ELSE
BEGIN
	declare CheckQuotaExistСursor cursor for 
		select	DISTINCT QT_ID, QT_PRKey, QT_ByRoom, 
				QD_Type, 
				QP_FilialKey, QP_CityDepartments, QP_AgentKey, CASE WHEN QP_Durations='' THEN 0 ELSE @TourDuration END, QP_FilialKey, QP_CityDepartments, 
				QO_SubCode1, QO_SubCode2
		from	QuotaObjects, Quotas, QuotaDetails, QuotaParts
		where	
			QO_SVKey=@SVKey and QO_Code=@Code and (QO_SubCode1=@SubCode1 or QO_SubCode1=0) and QO_QTID=QT_ID
			and QD_QTID=QT_ID and QD_Date between @DateBeg and @DateEnd
			and QP_QDID = QD_ID
			and (QP_AgentKey=@AgentKey or QP_AgentKey is null) 
			and (QT_PRKey=@PRKey or QT_PRKey=0)
			and QP_IsDeleted is null and QD_IsDeleted is null	
			and (QP_Durations = '' or @TourDuration in (Select QL_Duration From QuotaLimitations Where QL_QPID=QP_ID))
		group by QT_ID, QT_PRKey, QT_ByRoom, QD_Type, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_Durations, QO_SubCode1, QO_SubCode2
		--having Count(*) = (@Days+1)
		order by QP_AgentKey DESC, QT_PRKey DESC
END
open CheckQuotaExistСursor
fetch CheckQuotaExistСursor into	@Q_QTID, @Q_Partner, @Q_ByRoom, 
									@Q_Type, 
									@Q_FilialKey, @Q_CityDepartments, @Q_AgentKey, @Q_Duration, @Q_FilialKey, @Q_CityDepartments, 
									@Q_SubCode1, @Q_SubCode2

CREATE TABLE #Tbl (	TMP_Count int, TMP_QTID int, TMP_AgentKey int, TMP_Type smallint, TMP_Date datetime, 
					TMP_ByRoom bit, TMP_Release smallint, TMP_Partner int, TMP_Durations nvarchar(25) COLLATE Cyrillic_General_CI_AS, TMP_FilialKey int, 
					TMP_CityDepartments int, TMP_SubCode1 int, TMP_SubCode2 int)

CREATE TABLE #StopSaleTemp
(SST_Code int, SST_SubCode1 int, SST_SubCode2 int, SST_QOID int, SST_PRKey int, SST_Date smalldatetime,
SST_QDID int, SST_Type smallint, SST_State smallint, SST_Comment varchar(255)
)

While (@@fetch_status = 0)
BEGIN
	IF @Q_QTID_Prev!=@Q_QTID
	BEGIN
		DELETE FROM #StopSaleTemp
		INSERT INTO #StopSaleTemp exec dbo.GetTableQuotaDetails
						NULL, @Q_QTID, @DateBeg, @DaysCount, null, null, @SVKey, @Code, @SubCode1, @PRKey
	END
/*
	insert into Debug (db_date, db_n1, db_n2, db_n3) values (@DateBeg, @Q_QTID, @DaysCount, 670)
	insert into Debug (db_date, db_n1, db_n2, db_n3) values (@DateBeg, @SVKey, @Code, 671)
	insert into Debug (db_date, db_n1, db_n2, db_n3) values (@DateBeg, @SubCode1, @PRKey, 672)
*/
	SET @SubQuery = 'QD_QTID=QT_ID and QP_QDID = QD_ID 
		and QT_ID=' + CAST(@Q_QTID as varchar(10)) + '
		and QT_ByRoom=' + CAST(@Q_ByRoom as varchar(1)) + ' and QD_Type=' + CAST(@Q_Type as varchar(1)) + ' 
		and QO_SVKey=' + CAST(@SVKey as varchar(10)) + ' and QO_Code=' + CAST(@Code as varchar(10)) + ' and QO_SubCode1=' + CAST(@Q_SubCode1 as varchar(10)) + ' and QO_SubCode2=' + CAST(@Q_SubCode2 as varchar(10)) + '	
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
	--QP_Durations=' + CAST(@Q_Durations as varchar(10))
	IF @Q_Partner =''
		SET @SubQuery = @SubQuery + ' and QT_PRKey = '''' '
	ELSE
		SET @SubQuery = @SubQuery + ' and QT_PRKey=' + CAST(@Q_Partner as varchar(10))

	declare @SubCode2 int
	--if @SVKey=3
	--	SELECT @SubCode1=HR_RMKey, @SubCode2=HR_RCKey FROM HotelRooms WHERE HR_Key=@SubCode1
	SET @Query = 
	'
	INSERT INTO #Tbl (	TMP_Count, TMP_QTID, TMP_AgentKey, TMP_Type, TMP_Date, 
						TMP_ByRoom, TMP_Release, TMP_Partner, TMP_Durations, TMP_FilialKey, 
						TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2)
		SELECT	DISTINCT QP_Places-QP_Busy as d1, QT_ID, QP_AgentKey, QD_Type, QD_Date, 
				QT_ByRoom, QD_Release, QT_PRKey, QP_Durations, QP_FilialKey,
				QP_CityDepartments, QO_SubCode1, QO_SubCode2
		FROM	Quotas QT1, QuotaDetails QD1, QuotaParts QP1, QuotaObjects QO1, #StopSaleTemp
		WHERE	QO_ID=SST_QOID and QD_ID=SST_QDID and SST_State is null and ' + @SubQuery

		--and QD_Date > GetDate()+ISNULL(QD_Release,0)'
	--print @Query

	exec (@Query)
	
	SET @Q_QTID_Prev=@Q_QTID
	fetch CheckQuotaExistСursor into	@Q_QTID, @Q_Partner, @Q_ByRoom, 
										@Q_Type, 
										@Q_FilialKey, @Q_CityDepartments, @Q_AgentKey, @Q_Duration, @Q_FilialKey, @Q_CityDepartments, 
										@Q_SubCode1, @Q_SubCode2	
END

--DELETE FROM #Tbl WHERE 

DELETE FROM #Tbl WHERE exists 
		(SELECT QP_ID FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2 
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
--самая важная часть, ПОРЯДОК выбора квоты
--эта часть должна быть доработана
/*
IF EXISTS(SELECT * FROM dbo.SystemSettings WHERE SS_ParmName='SYSLimitAgentQuote')
	SELECT @vLimitAgentQuote = ISNULL(SS_ParmValue, '0') FROM dbo.SystemSettings WHERE SS_ParmName='SYSLimitAgentQuote'
IF EXISTS(SELECT * FROM dbo.SystemSettings WHERE SS_ParmName='SYSLimitQuoteLong')
	SELECT @vLimitQuoteLong = ISNULL(SS_ParmValue, '0') FROM dbo.SystemSettings WHERE SS_ParmName='SYSLimitQuoteLong'
SELECT @nQtLong = ISNULL(SS_ParmValue, '0') FROM dbo.SystemSettings WHERE SS_ParmName='SYSLimitQuoteLong'
*/

DECLARE @Tbl_DQ Table 
 		(TMP_Count smallint, TMP_AgentKey int, TMP_Type smallint, TMP_ByRoom bit, 
				TMP_Partner int, TMP_Duration smallint, TMP_FilialKey int, TMP_CityDepartments int,
				TMP_SubCode1 int, TMP_SubCode2 int, TMP_ReleaseIgnore bit)

DECLARE @DATETEMP datetime
SET @DATETEMP = GetDate()
if exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSCheckQuotaRelease' and SS_ParmValue=1) OR exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSAddQuotaPastPermit' and SS_ParmValue=1)
	SET @DATETEMP='01-JAN-1900'
INSERT INTO @Tbl_DQ
	SELECT	MIN(d1) as TMP_Count, TMP_AgentKey, TMP_Type, TMP_ByRoom, TMP_Partner, 
			d2 as TMP_Duration, TMP_FilialKey, TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2,0 as TMP_ReleaseIgnore FROM
		(SELECT	SUM(TMP_Count) as d1, TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner, 
				TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END as d2, TMP_SubCode1, TMP_SubCode2
		FROM	#Tbl
		WHERE	TMP_Date >= @DATETEMP+ISNULL(TMP_Release,0)
		GROUP BY	TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner,
					TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END, TMP_SubCode1, TMP_SubCode2) D
	GROUP BY	TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner,
				TMP_FilialKey, TMP_CityDepartments, d2, TMP_SubCode1, TMP_SubCode2
	HAVING count(*)=DATEDIFF(day,@DateBeg,@DateEnd)+1
	UNION
	SELECT	MIN(d1) as TMP_Count, TMP_AgentKey, TMP_Type, TMP_ByRoom, TMP_Partner, 
			d2 as TMP_Duration, TMP_FilialKey, TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2,1 as TMP_ReleaseIgnore FROM
		(SELECT	SUM(TMP_Count) as d1, TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner, 
				TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END as d2, TMP_SubCode1, TMP_SubCode2
		FROM	#Tbl
		GROUP BY	TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner,
					TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END, TMP_SubCode1, TMP_SubCode2) D
	GROUP BY	TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner,
				TMP_FilialKey, TMP_CityDepartments, d2, TMP_SubCode1, TMP_SubCode2
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
		select * from @Tbl_DQ order by TMP_ReleaseIgnore, TMP_Type, TMP_Partner DESC, TMP_AgentKey DESC, TMP_SubCode1 DESC, TMP_SubCode2 DESC, TMP_Duration DESC
	ELSE
		select * from @Tbl_DQ order by TMP_ReleaseIgnore, TMP_Type DESC, TMP_Partner DESC, TMP_AgentKey DESC, TMP_SubCode1 DESC, TMP_SubCode2 DESC, TMP_Duration DESC
END

DECLARE @Priority int;
SELECT @Priority=QPR_Type FROM   QuotaPriorities 
WHERE  QPR_Date=@DateFirst and QPR_SVKey = @SVKey and QPR_Code=@Code and QPR_PRKey=@PRKey

IF @Priority is not null
	SET @IsCommitmentFirst=@Priority-1

If @TypeOfResult=1 --(возвращаем характеристики оптимальной квоты)
BEGIN
	If exists (SELECT * FROM @Tbl_DQ)
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

If @TypeOfResult=2 --(попытка проверить возможность постановки услуги на квоту)
BEGIN
	DECLARE @Places_Count int, @Rooms_Count int,		 --доступное количество мест/номеров в квотах
			@PlacesNeed_Count smallint,					-- количество мест, которых недостаточно для оформления услуги
			@RowCountActual smallint, @RowCountReleaseIgnore smallint

	SELECT @RowCountReleaseIgnore=Count(1) FROM @Tbl_DQ
	DELETE FROM @Tbl_DQ WHERE TMP_ReleaseIgnore=1
 	SELECT @RowCountActual=Count(1) FROM @Tbl_DQ

	If exists (SELECT * FROM @Tbl_DQ)
	BEGIN
		SET @PlacesNeed_Count=0		
		select	@Places_Count=SUM(TMP_Count) from	@Tbl_DQ  where	TMP_Count>0 and TMP_ByRoom=0
		If @SVKey=3
			select	@Rooms_Count=SUM(TMP_Count) from	@Tbl_DQ  where	TMP_Count>0 and TMP_ByRoom=1

		Set @Places_Count=ISNULL(@Places_Count,0)
		Set @Rooms_Count=ISNULL(@Rooms_Count,0)
	
		--проверяем достаточно ли будет текущего кол-ва мест для бронирования
		declare @nPlaces smallint, @nRoomsService smallint
		If @SVKey=3 and @Rooms_Count>0
		BEGIN
			--insert into Debug (db_n1) values (233)--
			exec GetServiceRoomsCount @Code, @SubCode1, @Pax, @nRoomsService output
			If @nRoomsService>@Rooms_Count
				Set @PlacesNeed_Count=@nRoomsService-@Rooms_Count
		END
		ELSE
			If @Pax>@Places_Count
				Set @PlacesNeed_Count=@Pax-@Places_Count

		If @PlacesNeed_Count <= 0 --мест в квоте хватило
			Set @Quota_CheckState=1						--Возвращаем "Ok (квоты есть)"
	END
	
	If @Quota_CheckState=0 or @Quota_CheckState is null
	BEGIN
		If @StopExist>0	--и установлен STOP 
		BEGIN
			Set @Quota_CheckState=2						--Возвращаем "Внимание STOP"
			Set @Quota_CheckDate=@StopDate
		END
		Else
		BEGIN
			If @RowCountActual<@RowCountReleaseIgnore
				Set @Quota_CheckState=3						--Возвращаем "Release" (мест не достаточно, но наступил РЕЛИЗ-Период)
			ELSE
				Set @Quota_CheckState=0						--Возвращаем "RQ" (дальше требуется расширять AUTOSTOP)
			Set @Quota_CheckInfo=@PlacesNeed_Count
		END
	END
END
GO
GRANT EXECUTE ON [dbo].[CheckQuotaExist] TO PUBLIC 
GO

-- fn_GetServiceLink.sql
/****** Объект:  UserDefinedFunction [dbo].[fn_GetServiceLink]    Дата сценария: 08/02/2010 17:56:36 ******/
IF  EXISTS (SELECT * FROM sysobjects WHERE name= 'fn_GetServiceLink' AND (xtype = 'TF' or xtype = 'FN'))
DROP FUNCTION [dbo].[fn_GetServiceLink]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: 02.08.2010
-- Description:	Возвращает true если по классу услуг есть связь
-- =============================================
CREATE FUNCTION fn_GetServiceLink(@sv_key int)
RETURNS int
AS
BEGIN
	if ISNULL((SELECT ST_VERSION FROM Setting),'') like '7.2%' or ISNULL((SELECT ST_VERSION FROM Setting),'') like '8.1%' or ISNULL((SELECT ST_VERSION FROM Setting),'') like '9.2%'
	BEGIN
		-- если старая версия то проверяем только эти связи
		if (	EXISTS (SELECT dl_key FROM dbo.tbl_DogovorList WHERE dl_svkey = @sv_key) OR
				EXISTS (SELECT to_key FROM dbo.TourServiceList WHERE to_svkey = @sv_key) OR
				EXISTS (SELECT ts_key FROM dbo.TP_Services WHERE ts_svkey = @sv_key) OR
				EXISTS (SELECT sr_id FROM dbo.StatusRules WHERE SR_ExcludeServiceId = @sv_key)
			)	
		BEGIN
			RETURN(1)
		END
	END
	ELSE
	BEGIN
		-- если версия новее то проверяем все связи
		if (	EXISTS (SELECT dl_key FROM dbo.tbl_DogovorList WHERE dl_svkey = @sv_key) OR
				EXISTS (SELECT to_key FROM dbo.TourServiceList WHERE to_svkey = @sv_key) OR
				EXISTS (SELECT ts_id FROM dbo.TourServiceVariants WHERE ts_svkey = @sv_key) OR
				EXISTS (SELECT ts_key FROM dbo.TP_Services WHERE ts_svkey = @sv_key) OR
				EXISTS (SELECT co_id FROM dbo.CostOffers WHERE co_svkey = @sv_key) OR
				EXISTS (SELECT co_id FROM dbo.CostOfferServices WHERE co_svkey = @sv_key) OR
				EXISTS (SELECT co_id FROM dbo.CostOfferTourServices WHERE co_svkey = @sv_key) OR
				EXISTS (SELECT st_id FROM dbo.ServiceTariffs WHERE st_svkey = @sv_key) OR
				EXISTS (SELECT sr_id FROM dbo.StatusRules WHERE SR_ExcludeServiceId = @sv_key)
			)	
		BEGIN
			RETURN(1)
		END
	END

	RETURN(0)
END
GO

grant execute on dbo.fn_GetServiceLink to public 
GO

-- alter_mwPriceDataTable_pt_autodisabled.sql
if not exists(select id from syscolumns where id = OBJECT_ID('mwPriceDataTable') and name = 'pt_autodisabled')
ALTER TABLE mwPriceDataTable ADD pt_autodisabled smallint null
go

exec sp_refreshviewforall mwPriceTable
go

-- alter_tp_turdates_td_autodisabled.sql
if not exists(select id from syscolumns where id = OBJECT_ID('tp_turdates') and name = 'td_autodisabled')
ALTER TABLE tp_turdates ADD td_autodisabled smallint null
go


-- Index_mwPriceDataTable_x_singleprice.sql
if exists(select 1 from sysindexes where name='x_singleprice' and id = object_id(N'mwPriceDataTable'))
	drop index [dbo].[mwPriceDataTable].[x_singleprice]
go

CREATE NONCLUSTERED INDEX [x_singleprice] ON [dbo].[mwPriceDataTable] 
(
	[pt_tourdate] ASC,
	[pt_hdkey] ASC,
	[pt_rmkey] ASC,
	[pt_rckey] ASC,
	[pt_ackey] ASC,
	[pt_pnkey] ASC,
	[pt_days] ASC,
	[pt_nights] ASC
)
INCLUDE ( [pt_hdpartnerkey],
[pt_chprkey],
[pt_tourtype],
[pt_main],
[pt_isenabled],
[pt_autodisabled],
[pt_tourkey],
[pt_price],
[pt_ctkeyfrom]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

go

-- sp_mwLoginExists.sql
if exists(select id from sysobjects where xtype='p' and name='mwLoginExists')
	drop proc dbo.mwLoginExists
go

create procedure [dbo].[mwLoginExists]
(
	@login varchar(50)
)
as
begin
	if @login = ''
		select 0
	else
		select case when exists(select 1 from dup_user where us_id=@login) then 1 else 0 end
end
go

grant exec on [dbo].[mwLoginExists] to public
go

-- sp_mwEnablePriceTour.sql
if object_id('dbo.mwEnablePriceTour', 'p') is not null
	drop proc dbo.mwEnablePriceTour
go

create proc [dbo].[mwEnablePriceTour] @tourkey int, @enabled smallint
as
begin
	update tp_tours with(rowlock)
	set to_isenabled = @enabled
	where to_key = @tourkey


	declare @cityFromKey int
	declare @countryKey int

	select @countryKey = sd_cnkey, @cityFromKey = sd_ctkeyfrom from dbo.mwSpoDataTable where sd_tourkey = @tourkey 


	declare @mwSinglePrice nvarchar(10)
	select @mwSinglePrice = isnull(dbo.GetCountrySetting(@countryKey, 'mwSinglePrice'), N'0')

	if(@mwSinglePrice != '0')
	begin
		declare @mwSinglePriceType nvarchar(10) -- 'last' or 'min'
		select @mwSinglePriceType = isnull(dbo.GetCountrySetting(@countryKey, 'mwSinglePriceType'), N'last') 

		declare @mwSinglePriceAllTours nvarchar(10) -- single price for tour
		select @mwSinglePriceAllTours = isnull(dbo.GetCountrySetting(@countryKey, 'mwSinglePriceAllTours'), N'0') 

		declare @mwSinglePriceAllHotelPrt nvarchar(10) -- single price for hotel partner
		select @mwSinglePriceAllHotelPrt = isnull(dbo.GetCountrySetting(@countryKey, 'mwSinglePriceAllHotelPrt'), N'0') 

		declare @mwSinglePriceAllFlightPrt nvarchar(10) -- single price for flight partner
		select @mwSinglePriceAllFlightPrt = isnull(dbo.GetCountrySetting(@countryKey, 'mwSinglePriceAllFlightPrt'), N'0')

		declare @mwSinglePriceAllTourTypes nvarchar(10) -- single price for tour type
		select @mwSinglePriceAllTourTypes = isnull(dbo.GetCountrySetting(@countryKey, 'mwSinglePriceAllTourTypes'), N'0')

		declare @mwSinglePriceAllDeparts nvarchar(10) -- single price for depart from
		select @mwSinglePriceAllDeparts = isnull(dbo.GetCountrySetting(@countryKey, 'mwSinglePriceAllDeparts'), N'1')
	end

	declare @sql varchar(8000)

	declare @mwSearchType int
	select @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
	where SS_ParmName = 'MWDivideByCountry'
 
	if (@countryKey is not null and @cityFromKey is not null)
	begin
		declare @tableName nvarchar(100)
		if (@mwSearchType = 0)
			set @tableName = 'dbo.mwPriceDataTable'
		else
			set @tableName = dbo.mwGetPriceTableName(@countryKey, @cityFromKey)

		create table #tmpTours (tourkey int)

		if(@mwSinglePrice != '0')
		begin
			if(@enabled > 0 and @mwSinglePriceAllTours != '0') -- turn the tour on
			begin	
				-- disable all prices for main places that greater than new prices (setting = min) or
				-- than are more old than new prices (setting = last)
				declare @sqlwhere varchar(8000)

				set @sqlwhere = 'where
					' + @tableName + '.pt_main > 0 and 
					' + @tableName + '.pt_tourdate >= getdate() and
					' + @tableName + '.pt_isenabled > 0 and exists(select 1 from dbo.mwPriceDataTable tweb with(nolock)
					where tweb.pt_main > 0 and tweb.pt_tourdate >= getdate() and tweb.pt_tourkey = ' + ltrim(str(@tourkey)) + ' and
					' + @tableName + '.pt_hdkey = tweb.pt_hdkey and
					' + @tableName + '.pt_rmkey = tweb.pt_rmkey and
					' + @tableName + '.pt_rckey = tweb.pt_rckey and
					' + @tableName + '.pt_ackey = tweb.pt_ackey and
					' + @tableName + '.pt_pnkey = tweb.pt_pnkey and
					' + @tableName + '.pt_tourdate = tweb.pt_tourdate and
					' + @tableName + '.pt_days = tweb.pt_days and
					' + @tableName + '.pt_nights = tweb.pt_nights'
						if(@mwSinglePriceAllHotelPrt = '0') -- single price for hotel partner
							set @sqlwhere = @sqlwhere + ' and
					' + @tableName + '.pt_hdpartnerkey = tweb.pt_hdpartnerkey'		
						
						if(@mwSinglePriceAllFlightPrt = '0') -- single price for flight partner
							set @sqlwhere = @sqlwhere + ' and
					' + @tableName + '.pt_chprkey = tweb.pt_chprkey'

						if(@mwSinglePriceAllTourTypes = '0') -- single price for tour type
							set @sqlwhere = @sqlwhere + ' and
					' + @tableName + '.pt_tourtype = tweb.pt_tourtype'

						if(@mwSinglePriceAllDeparts = '0') -- single price for departfrom
							set @sqlwhere = @sqlwhere + ' and
					' + @tableName + '.pt_ctkeyfrom = tweb.pt_ctkeyfrom'

						if(@mwSinglePriceType = 'min')
							set @sqlwhere = @sqlwhere + ' and
					' + @tableName + '.pt_price > tweb.pt_price'
					
				set @sqlwhere = @sqlwhere + ')'

					if(@mwSinglePriceAllTours = '0')
						set @sqlwhere = @sqlwhere + ' and
				' + @tableName + '.pt_tourkey = ' + ltrim(str(@tourkey))
					else
						set @sqlwhere = @sqlwhere + ' and
				' + @tableName + '.pt_tourkey != '+ ltrim(str(@tourkey))
					

				set @sql = 'select distinct pt_tourkey from mwpricedatatable with (nolock) ' + @sqlWhere

				insert into #tmpTours exec(@sql)
				create index x_tmptokey on #tmpTours (tourkey)

				-- заполним таблицу с ценами, которые нужно выключить
				create table #tmpPricesOff(pt_pricekey int)
				set @sql = 'select pt_pricekey from mwpricedatatable with (nolock) ' + @sqlWhere
				insert into #tmpPricesOff exec(@sql)

				-- выключаем цены
				set @sql = '
				update ' + @tableName + ' with(rowlock)
				set pt_isenabled = 0, pt_autodisabled = 1 
				where '+ @tableName + '.pt_pricekey in (select pt_pricekey from #tmpPricesOff) '

				--print @sql
				exec(@sql) -- turn off max or old prices for main places

				-- выключаем вслед за ними соответствующие данные из tp_turdates
				set @sql = '
				update updturdates with(rowlock)
				set td_autodisabled = 1
				from tp_turdates updturdates
					inner join ' + @tableName + ' on ' + @tableName + '.pt_tourkey = updturdates.td_tokey
														and ' + @tableName + '.pt_tourdate = updturdates.td_date
				where '+ @tableName + '.pt_pricekey in (select pt_pricekey from #tmpPricesOff) '
				--print @sql
				exec (@sql)
			end -- if(@enabled > 0 and @mwSinglePriceAllTours != '0')
		end -- if(@mwSinglePrice != '0')


		----------------=============== Обработаем снятие тура из интернета ===============----------------
		--======== В этом блоке будем искать цены, взамен снимаемых для их последующей реанимации ========--
		--==== Вместе с ценами будем обновлять соответствующие данные из mwSpoDataTable и tp_turdates ====--
		if (@enabled = 0 and @mwSinglePriceAllTours != '0' and (@mwSinglePriceType = 'last' or @mwSinglePriceType = 'min')) -- turn off the tour
		begin
			-- сформируем запрос, который возвращает список ключей цен для реанимации
			declare @groupbyexpr varchar(1024),
					@havingexpr varchar(1024),
					@pricekeyexpr varchar(1024),
					@joinclauseexpr varchar(1024),
					@pricetableexpr varchar(8000)
					
			set @joinclauseexpr = ''
			set @groupbyexpr = ''
			
			if (@mwSinglePriceAllHotelPrt = '0')
			begin
				set @joinclauseexpr = @joinclauseexpr + ' and 
					tweb2.pt_hdpartnerkey = tweb.pt_hdpartnerkey'
				set @groupbyexpr = @groupbyexpr + 'tweb.pt_hdpartnerkey, '
			end
			if (@mwSinglePriceAllFlightPrt = '0')
			begin
				set @joinclauseexpr = @joinclauseexpr + ' and 
					tweb2.pt_chprkey = tweb.pt_chprkey'
				set @groupbyexpr = @groupbyexpr + 'tweb.pt_chprkey, '
			end
			if (@mwSinglePriceAllTourTypes = '0')
			begin
				set @joinclauseexpr = @joinclauseexpr + ' and 
					tweb2.pt_tourtype = tweb.pt_tourtype'
				set @groupbyexpr = @groupbyexpr + 'tweb.pt_tourtype, '
			end
			if (@mwSinglePriceAllDeparts = '0')
			begin
				set @joinclauseexpr = @joinclauseexpr + ' and 
					tweb2.pt_ctkeyfrom = tweb.pt_ctkeyfrom'
				set @groupbyexpr = @groupbyexpr + 'tweb.pt_tourtype, '
			end

			if (@mwSinglePriceType = 'last')
			begin
				set @groupbyexpr = @groupbyexpr + 'tweb.pt_pricekey'
				set @pricekeyexpr = 'max(tweb2.pt_pricekey)'
			end
			else if (@mwSinglePriceType = 'min')
			begin
				set @groupbyexpr = 'tweb.pt_price'
				set @pricekeyexpr = '(
										select top 1 pt_pricekey from #tablename# tweb3 with (nolock)
										where	tweb3.pt_price = min(tweb2.pt_price) and
												tweb3.pt_main > 0 and
												tweb3.pt_hdkey = tweb.pt_hdkey and
												tweb3.pt_rmkey = tweb.pt_rmkey and
												tweb3.pt_rckey = tweb.pt_rckey and
												tweb3.pt_ackey = tweb.pt_ackey and
												tweb3.pt_pnkey = tweb.pt_pnkey and
												tweb3.pt_tourdate = tweb.pt_tourdate and
												tweb3.pt_days = tweb.pt_days and
												tweb3.pt_nights = tweb.pt_nights and
												tweb3.pt_ctkeyfrom = tweb.pt_ctkeyfrom 	and
												tweb3.pt_tourkey <> #tourkey# and
												(tweb3.pt_isenabled = 1 or (tweb3.pt_isenabled = 0 and tweb3.pt_autodisabled = 1)) #whereclause#
										order by 1 desc
									)'
				set @pricekeyexpr = replace(@pricekeyexpr, '#whereclause#', replace(@joinclauseexpr, 'tweb2', 'tweb3'))
			end
			
			set @pricetableexpr = '				select #pricekey# as pt_pricekey
				from #tablename# tweb	with (nolock)
					inner join #tablename# tweb2 with (nolock) on
									tweb2.pt_main = tweb.pt_main and
									tweb2.pt_hdkey = tweb.pt_hdkey and
									tweb2.pt_rmkey = tweb.pt_rmkey and
									tweb2.pt_rckey = tweb.pt_rckey and
									tweb2.pt_ackey = tweb.pt_ackey and
									tweb2.pt_pnkey = tweb.pt_pnkey and
									tweb2.pt_tourdate = tweb.pt_tourdate and
									tweb2.pt_days = tweb.pt_days and
									tweb2.pt_nights = tweb.pt_nights and
									tweb2.pt_ctkeyfrom = tweb.pt_ctkeyfrom 	and
									tweb2.pt_tourkey <> tweb.pt_tourkey and
									(tweb2.pt_isenabled = 1 or (tweb2.pt_isenabled = 0 and tweb2.pt_autodisabled = 1)) #joinclause#
				where tweb.pt_main > 0 and tweb.pt_tourkey = #tourkey# and tweb.pt_tourdate >= getdate()
				group by tweb.pt_hdkey,
					tweb.pt_rmkey,
					tweb.pt_rckey,
					tweb.pt_ackey,
					tweb.pt_pnkey,
					tweb.pt_tourdate,
					tweb.pt_days,
					tweb.pt_nights, 
					tweb.pt_ctkeyfrom, 
					#groupby#'

			set @pricetableexpr = replace(@pricetableexpr, '#pricekey#', @pricekeyexpr)
			set @pricetableexpr = replace(@pricetableexpr, '#groupby#', @groupbyexpr)
			set @pricetableexpr = replace(@pricetableexpr, '#joinclause#', @joinclauseexpr)
			set @pricetableexpr = replace(@pricetableexpr, '#tourkey#', convert(varchar, @tourkey))
			set @pricetableexpr = replace(@pricetableexpr, '#tablename#', @tableName)

			-- закончили формирование #pricetable#, который возвращает список ключей цен для реанимации

			create table #tmpPrices (pt_pricekey int)
			insert into #tmpPrices exec (@pricetableexpr)

			-- шаблон запроса, который выставляет в интернет оптимальные цены взамен цен, снимаемых из интернета
			set @sql = '
			update updweb with(rowlock)
			set pt_isenabled = 1,
				pt_autodisabled = 0
			from #tablename# updweb
				inner join #tmpPrices prices on updweb.pt_pricekey = prices.pt_pricekey 
			where updweb.pt_main > 0 and (updweb.pt_isenabled = 1 or (updweb.pt_isenabled = 0 and updweb.pt_autodisabled = 1)) and updweb.pt_tourdate >= getdate() and updweb.pt_tourkey != #tourkey#
'
			set @sql = replace(@sql, '#tourkey#', convert(varchar, @tourkey))
			set @sql = replace(@sql, '#tablename#', @tableName)

			--print @sql
			exec (@sql)

			-- шаблон запроса, который реанимирует данные из mwSpoDataTable вслед за ценами
			set @sql = '
				update updspo with(rowlock)
				set sd_isenabled = 1
				from mwSpoDataTable updspo
				inner join
				(
					select updweb.pt_tourkey, updweb.pt_cnkey, updweb.pt_ctkeyfrom, updweb.pt_hdkey, updweb.pt_pnkey
					from #tablename# updweb
						inner join #tmpPrices prices on updweb.pt_pricekey = prices.pt_pricekey 
					where updweb.pt_main > 0 and (updweb.pt_isenabled = 1 or (updweb.pt_isenabled = 0 and updweb.pt_autodisabled = 1)) and updweb.pt_tourdate >= getdate() and updweb.pt_tourkey != #tourkey#
				) tbl
					on updspo.sd_tourkey = tbl.pt_tourkey
						and updspo.sd_cnkey = tbl.pt_cnkey
						and updspo.sd_ctkeyfrom = tbl.pt_ctkeyfrom
						and updspo.sd_hdkey = tbl.pt_hdkey
						and updspo.sd_pnkey = tbl.pt_pnkey'

			set @sql = replace(@sql, '#tourkey#', convert(varchar, @tourkey))
			set @sql = replace(@sql, '#tablename#', @tableName)
--print @sql
			exec (@sql)

			-- шаблон запроса, который реанимирует данные из tp_turdates вслед за ценами
			set @sql = '			
				update updturdates with(rowlock)
				set td_autodisabled = 0
				from tp_turdates updturdates
				inner join
				(
					select updweb.pt_tourkey, updweb.pt_tourdate
					from #tablename# updweb
						inner join #tmpPrices prices on updweb.pt_pricekey = prices.pt_pricekey 
					where updweb.pt_main > 0 and (updweb.pt_isenabled = 1 or (updweb.pt_isenabled = 0 and updweb.pt_autodisabled = 1)) and updweb.pt_tourdate >= getdate() and updweb.pt_tourkey != #tourkey#
				) tbl
					on updturdates.td_tokey = tbl.pt_tourkey
						and updturdates.td_date = tbl.pt_tourdate'

			set @sql = replace(@sql, '#tourkey#', convert(varchar, @tourkey))
			set @sql = replace(@sql, '#tablename#', @tableName)
			exec (@sql)	

		end --if (@enabled = 0 and @mwSinglePriceAllTours != '0' and (@mwSinglePriceType = 'last' or @mwSinglePriceType = 'min'))

		-- Выключим все цены по текущему туру с признаком autodisabled = 1
		-- чтобы те цены, которые не будут включены, могли быть реанимированы позднее
		if (@enabled > 0 and @mwSinglePrice != '0')
		begin
			set @sql = '
			update ' + @tableName + ' with(rowlock)
			set pt_isenabled = 0, pt_autodisabled = 1
			where pt_tourdate >= cast(convert(varchar(10),getdate(), 102 ) as datetime) and pt_tourkey = ' + CAST(@tourkey as varchar)

			exec (@sql)
		end

		set @sql = '
		update ' + @tableName + ' with(rowlock)
		set pt_isenabled = ' + CAST(@enabled as varchar) + ', pt_autodisabled = 0
		where pt_tourdate >= cast(convert(varchar(10),getdate(), 102 ) as datetime) and pt_tourkey = ' + CAST(@tourkey as varchar)

		if(@enabled > 0)
		begin
			if (@mwSinglePrice != '0')
			begin
				-- enable all new prices for main places that are min (setting = min) or
				-- that are new (setting = last)
				set @sql = @sql + ' and pt_main > 0 and not exists(
				select 1 from ' + @tableName + ' pt with(nolock)
				where 
				pt.pt_main > 0 and
				pt.pt_hdkey = ' + @tableName + '.pt_hdkey and
				pt.pt_rmkey = ' + @tableName + '.pt_rmkey and
				pt.pt_rckey = ' + @tableName + '.pt_rckey and
				pt.pt_ackey = ' + @tableName + '.pt_ackey and
				pt.pt_pnkey = ' + @tableName + '.pt_pnkey and
				pt.pt_tourdate = ' + @tableName + '.pt_tourdate and
				pt.pt_days = ' + @tableName + '.pt_days and
				pt.pt_nights = ' + @tableName + '.pt_nights'
				if(@mwSinglePriceAllHotelPrt = '0') -- single price for hotel partner
					set @sql = @sql + ' and
				pt.pt_hdpartnerkey = ' + @tableName + '.pt_hdpartnerkey'
				
				if(@mwSinglePriceAllFlightPrt = '0') -- single price for flight partner
					set @sql = @sql + ' and
				pt.pt_chprkey = ' + @tableName + '.pt_chprkey'

				if(@mwSinglePriceAllTourTypes = '0') -- single price for tour type
					set @sql = @sql + ' and
				pt.pt_tourtype = ' + @tableName + '.pt_tourtype'

				if(@mwSinglePriceAllDeparts = '0') -- single price for departfrom
					set @sql = @sql + ' and
				pt_ctkeyfrom = ' + ltrim(str(@cityFromKey))

				if(@mwSinglePriceType = 'last')
					set @sql = @sql + '	and
				pt.pt_key > ' + @tableName + '.pt_key'
				else if(@mwSinglePriceType = 'min')
					set @sql = @sql + '	and
				pt.pt_price < ' + @tableName + '.pt_price'

					if(@mwSinglePriceAllTours = '0')
						set @sql = @sql + ' and
				pt_tourkey = ' + ltrim(str(@tourkey))
					else
						set @sql = @sql + ' and pt.pt_isenabled > 0 and
				pt_tourkey != ' + ltrim(str(@tourkey))

				set @sql = @sql + ')'		
			end
		end
		--print @sql
		exec (@sql)

		if (@mwSinglePrice != '0')
		begin
			-- enable all new prices for extra places for which exist new prices for main places (in the new tour)
			set @sql = '
			update ' + @tableName + ' with(rowlock)
			set pt_isenabled = 1, pt_autodisabled = 0
			where pt_tourdate >= cast(convert(varchar(10),getdate(), 102 ) as datetime)
			and isnull(pt_main, 0) <= 0 and exists(
			select 1 from ' + @tableName + ' pt with(nolock)
			where pt.pt_tourkey = ' + @tableName + '.pt_tourkey and
			pt.pt_isenabled > 0 and
			pt.pt_main > 0 and
			pt.pt_hdkey = ' + @tableName + '.pt_hdkey and
			pt.pt_rmkey = ' + @tableName + '.pt_rmkey and
			pt.pt_rckey = ' + @tableName + '.pt_rckey and
			pt.pt_pnkey = ' + @tableName + '.pt_pnkey and
			pt.pt_tourdate = ' + @tableName + '.pt_tourdate and
			pt.pt_days = ' + @tableName + '.pt_days and
			pt.pt_nights = ' + @tableName + '.pt_nights and
			pt.pt_hdpartnerkey = ' + @tableName + '.pt_hdpartnerkey)'
--				print @sql
			exec(@sql)

			-- disable all old prices for extra places for which does not exist old prices for main places (in the same old tour)
			set @sql = '
			update ' + @tableName + ' with(rowlock)
			set pt_isenabled = 0, pt_autodisabled = 0
			where pt_tourdate >= cast(convert(varchar(10),getdate(), 102 ) as datetime)
			and isnull(pt_main, 0) <= 0 and pt_isenabled > 0 and not exists(
			select 1 from ' + @tableName + ' pt with(nolock)
			where pt.pt_tourkey = ' + @tableName + '.pt_tourkey and
			pt.pt_isenabled > 0 and
			isnull(pt.pt_main, 0) > 0 and
			pt.pt_hdkey = ' + @tableName + '.pt_hdkey and
			pt.pt_rmkey = ' + @tableName + '.pt_rmkey and
			pt.pt_rckey = ' + @tableName + '.pt_rckey and
			pt.pt_pnkey = ' + @tableName + '.pt_pnkey and
			pt.pt_tourdate = ' + @tableName + '.pt_tourdate and
			pt.pt_days = ' + @tableName + '.pt_days and
			pt.pt_nights = ' + @tableName + '.pt_nights and
			pt.pt_hdpartnerkey = ' + @tableName + '.pt_hdpartnerkey)'
			--print @sql
			exec(@sql)
		end
	end

	update dbo.mwSpoDataTable set sd_isenabled = @enabled where sd_tourkey = @tourkey

	if(@mwSinglePrice != '0')
	begin	
		update dbo.mwSpoDataTable with (rowlock)
		set sd_isenabled = 0
		where (exists (select 1 from #tmpTours where sd_tourkey = tourkey) or sd_tourkey = @tourkey) and not exists(select 1 from dbo.mwPriceTable
			where pt_cnkey = sd_cnkey
				and pt_ctkeyfrom = sd_ctkeyfrom
				and pt_tourkey = sd_tourkey
				and pt_hdkey = sd_hdkey
				and pt_pnkey = sd_pnkey
				and (exists (select 1 from #tmpTours where sd_tourkey = tourkey) or sd_tourkey = @tourkey))
	end
end
go

grant exec on dbo.mwEnablePriceTour to public
go

-- sp_SpoListResults.sql
-------------------------------------------------
--- Create Storage Procedure [SPOListResults] ---
-------------------------------------------------

if exists(select id from sysobjects where id = OBJECT_ID('SPOListResults') and xtype = 'P')
	drop procedure dbo.[SPOListResults]
go

CREATE PROCEDURE [dbo].[SPOListResults] 
(
	@filter varchar(1024),
	@searchType varchar (10),
	@dateFrom varchar (10),
	@dateTo varchar (10),
	@top varchar(10)
)
AS
DECLARE @additionalQuery varchar (1024)

if (@searchType = 'SPO')
	BEGIN
		SET @additionalQuery = 'AND SD_TOURKEY IN (SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE (TO_ATTRIBUTE & 1) > 0)'
	END
else if (@searchType = 'Leader')
	BEGIN
		SET @additionalQuery = 'AND SD_TOURKEY IN (SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE (TO_ATTRIBUTE & 2) > 0)'
	END
else
	BEGIN
		SET @additionalQuery = 'AND SD_TOURKEY IN (SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE (TO_ATTRIBUTE & 3) > 0)'
	END

DECLARE @command varchar (8000)
SET @command =
'
CREATE TABLE #resultsTable (
	[createdate] [datetime],
	[tourname] [varchar] (128) COLLATE Cyrillic_General_CI_AS,
	[tourhttp] [varchar] (128) COLLATE Cyrillic_General_CI_AS,
	[resort] [varchar] (1024) COLLATE Cyrillic_General_CI_AS,
	[city] [varchar] (1024) COLLATE Cyrillic_General_CI_AS,
	[hotels] [varchar] (7000) COLLATE Cyrillic_General_CI_AS, 
	[tourdates] [varchar] (1024),
	[countryName] [varchar] (25) COLLATE Cyrillic_General_CI_AS,
	[countryNameLat] varchar (25),
	[countryKey] int, 
	[tourKey] int,
	[tourListKey] int
) 

DECLARE @tourkey  int
DECLARE @hotelkey  int
DECLARE @tourdate datetime
DECLARE @resortkey  int
DECLARE @citykey  int
DECLARE @countrykey  int
DECLARE @createdate datetime
DECLARE @tourlistkey int

DECLARE @lastTourkey int
DECLARE @lastTourListKey int
DECLARE @lastHotelkey int
DECLARE @lastResortkey int
DECLARE @lastCountrykey int
DECLARE @lastCreateDate datetime
DECLARE @exit bit
DECLARE @resortKeys varchar(8000);
DECLARE @cityKeys varchar(8000);

DECLARE @hotelNames varchar (7000)
DECLARE @tourDates varchar (1024)
DECLARE @resorts varchar (1024)
DECLARE @cities varchar (1024)

SET @lastTourkey = -1
SET @lastHotelkey = -1
SET @lastResortkey = -1
SET @exit = 0
SET @resortKeys = ''''
SET @cityKeys = ''''

SELECT distinct top '+ @top +' sd_tourkey, SD_TOURCREATED into #tempSpoTable from MWSPoDataTable ' + @filter +' '+ @additionalQuery + ' ORDER BY SD_TOURCREATED DESC 

DECLARE SPO_Cursor CURSOR FOR
SELECT SD_TOURCREATED, SD_TOURKEY, SD_HDKEY, td_date, SD_RSKEY, SD_CTKEY, SD_CNKEY, SD_TLKEY
FROM MWSPoDataTable inner join tp_turdates on (sd_tourkey = td_tokey)
WHERE sd_tourkey in (select sd_tourkey from  #tempSpoTable) ORDER BY sd_CNKEY,sd_tourkey, sd_hdkey, sd_rskey

OPEN SPO_Cursor

if (@@CURSOR_ROWS > 0)
Begin

FETCH NEXT FROM SPO_Cursor INTO @createdate, @tourkey, @hotelkey, @tourdate, @resortkey, @citykey, @countrykey, @tourlistkey
WHILE 1=1
BEGIN
    
    if (((@lastTourkey = -1) OR (@lastTourkey = @tourkey)) AND (@@FETCH_STATUS = 0))
	BEGIN
		--Отели
		IF (@lastHotelkey <> @hotelkey)
			BEGIN
				declare @hdName varchar (1024)
				declare @hdUrl varchar (1024)
				SELECT @hdName = (isnull (HD_NAME,'''') + '' '' + ltrim(rtrim(isnull(HD_STARS,'''')))), @hdUrl = isnull (HD_HTTP,'''') from hoteldictionary where HD_KEY = @hotelkey
				if (@lastTourkey = -1)
					BEGIN
						SET @hotelNames = @hdName + ''|'' + @hdUrl
					END
				else
					BEGIN
						SET @hotelNames = @hotelNames + '', '' + @hdName + ''|'' + @hdUrl
					END
				SET @lastHotelkey = @hotelkey
			END
		
		if (@lastTourkey = -1)
			BEGIN
				if (@resortkey is NULL)
					SET @resorts = ''нет''
			END
		
		IF (@resortkey is not null)
		BEGIN
			declare @rsName varchar (50)
														
			if (CHARINDEX(''|''+CAST(@resortkey as varchar)+''|'',@resortKeys) = 0)
			BEGIN
				SET @resortKeys = @resortKeys + ''|'' + CAST(@resortkey as varchar) +''|''
				SELECT @rsName = RS_NAME from resorts where RS_KEY = @resortkey
				if (@lastTourkey = -1)
					BEGIN
						SET @resorts = @rsName
					END
				else
					BEGIN
						SET @resorts = @resorts + '', '' + @rsName
				END
			END
	
		END

		IF (@citykey is not null)
		BEGIN
			declare @ctName varchar (50)
														
			if (CHARINDEX(''|''+CAST(@citykey as varchar)+''|'',@cityKeys) = 0)
				BEGIN
					SET @cityKeys = @cityKeys + ''|'' + CAST(@citykey as varchar) +''|''
					SELECT @ctName = CT_NAME from citydictionary where CT_KEY = @citykey
					if (@lastTourkey = -1)
						BEGIN
							SET @cities = @ctName
						END
					else
						BEGIN
							SET @cities = @cities + '', '' + @ctName
					END
				END
	
		END

		SET @lastCountrykey = @countrykey
		SET @lastCreateDate = @createdate
		SET @lastTourListKey = @tourlistkey
		
	END
    else
	BEGIN
		
		if @@FETCH_STATUS <> 0
			SET @exit = 1
		
		DECLARE @tourName varchar(128)
		DECLARE @tourHttp varchar(128)
		SELECT @tourName = TL_NAMEWEB, @tourHttp = TL_WEBHTTP from TURLIST where TL_KEY = @lastTourListKey
		
		DECLARE @countryName varchar(25)
		DECLARE @countryNameLat varchar(25)

		SELECT @countryName = CN_NAME, @countryNameLat = CN_NAMELAT FROM tbl_Country WHERE CN_KEY = @lastCountrykey
		
		DECLARE @currentDate dateTime
		DECLARE @lastDate dateTime
		DECLARE @lastWriteDate dateTime
		DECLARE @first int
		DECLARE @datesInInterval int

		SET @first = 0

		DECLARE SPODate_Cursor CURSOR FOR
		SELECT DISTINCT td_date FROM tp_turdates
		WHERE td_tokey = @lastTourkey AND td_date >= ''' + @dateFrom + ''' AND td_date <= ''' + @dateTo + '''  ORDER BY td_date
		
		OPEN SPODate_Cursor

		FETCH NEXT FROM SPODate_Cursor INTO @currentDate

		WHILE @@FETCH_STATUS = 0
			BEGIN
					
					if (@first = 0)
						BEGIN 
							SET @datesInInterval = 0
							SET @first = 1
							SET @lastWriteDate = @currentDate
							SET @tourDates = CONVERT (char(5),@currentDate, 4)
						END
					else
						BEGIN
							if (@currentDate <> DATEADD (day,1,@lastDate))
								BEGIN
									SET @datesInInterval = 0
									if (@lastWriteDate = @lastDate)
										SET @tourDates = @tourDates + '', '' + CONVERT (char(5),@currentDate, 4)
									else
										SET @tourDates = @tourDates + '' - '' + CONVERT (char(5),@lastDate, 4) + '', '' + CONVERT (char(5),@currentDate, 4)
									SET @lastWriteDate = @currentDate
								END
						END
						SET @datesInInterval = @datesInInterval + 1
						SET @lastDate = @currentDate
						FETCH NEXT FROM SPODate_Cursor INTO @currentDate
				
			END
		CLOSE SPODate_Cursor
		DEALLOCATE SPODate_Cursor

		if (@lastWriteDate <> @currentDate)
			BEGIN
				if (@datesInInterval > 1)
					SET @tourDates = @tourDates + '' - '' + CONVERT (char(5),@currentDate, 4)
				else
					BEGIN
						if (@currentDate <> DATEADD (day,1,@lastWriteDate))
							SET @tourDates = @tourDates + '', '' + CONVERT (char(5),@currentDate, 4)
						else
							SET @tourDates = @tourDates + '' - '' + CONVERT (char(5),@currentDate, 4)
					END
			END
		

		INSERT #resultsTable Values (@lastCreateDate, @tourName, @tourHttp, @resorts, @cities, @hotelNames, @tourDates, @countryName, @countryNameLat, @lastCountrykey,  @lastTourkey, @lastTourListKey)
		
		if (@exit = 1)
			BREAK
		
		SELECT @hdName = isnull (HD_NAME,''''), @hdUrl = isnull (HD_HTTP,'''') from hoteldictionary where HD_KEY = @hotelkey
		SET @hotelNames = @hdName + ''|'' + @hdUrl
		if (@resortKey is not NULL)
			BEGIN
				SET @resortKeys = ''|'' + CAST (@resortkey as varchar) + ''|''
				SELECT @resorts = RS_NAME from resorts where RS_KEY = @resortkey
			END
		else
			SET @resorts = ''нет''

		if (@cityKey is not NULL)
			BEGIN
				SET @cityKeys = ''|'' + CAST (@cityKey as varchar) + ''|''
				SELECT @cities = ct_NAME from citydictionary where ct_KEY = @cityKey
			END
		else
			SET @cities = ''нет''

		SET @lastHotelkey = @hotelkey
		SET @lastCountrykey = @countrykey
		SET @lastCreateDate = @createdate
		SET @lastTourListKey = @tourlistkey
	
	END

	
	SET @lastTourkey = @tourkey
	
	FETCH NEXT FROM SPO_Cursor INTO @createdate, @tourkey, @hotelkey, @tourdate, @resortkey, @citykey, @countrykey, @tourlistkey
END
end

CLOSE SPO_Cursor
DEALLOCATE SPO_Cursor


SELECT * FROM #resultsTable order by [countryName],[createdate]
DROP TABLE #tempSpoTable
DROP TABLE  #resultsTable'

exec (@command)
go

grant exec on dbo.[SPOListResults] to public
go

-- 090708(Create_table_DiscountActions).sql
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[tbl_DiscountActions]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[tbl_DiscountActions](
	[DA_Key] [int] IDENTITY(1,1) NOT NULL,
	[DA_Name] [varchar](50) NULL,
	[DA_NameLat] [varchar](50) NULL,
	[DA_Comment] [varchar](500) NULL,
 CONSTRAINT [PK_tbl_DiscountActions] PRIMARY KEY CLUSTERED 
(
	[DA_Key] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO


IF exists(Select * from sysviews where name = 'DiscountActions' and CREATOR = 'DBO')
	DROP VIEW dbo.DiscountActions
GO

CREATE VIEW dbo.DiscountActions AS 
    SELECT	DA_Key AS DA_Key,
			DA_Name as DA_Name,
			DA_NameLat as DA_NameLat,
			DA_Comment as DA_Comment
	FROM	[dbo].[tbl_DiscountActions]
GO

exec sp_RefreshViewForAll 'DiscountActions'
GO

grant select ,insert, delete,update on  [dbo].[tbl_DiscountActions] to public 
GO

grant select ,insert, delete,update on  [dbo].[DiscountActions] to public 
GO


-- alterTable_PRT_Bonuses.sql
--это поле используеться в Trigger [dbo].[DupUser_Change] у моса
if not exists(select id from syscolumns where id = OBJECT_ID('PrtBonuses') and name = 'PB_DateRegistration')
ALTER TABLE [dbo].[PrtBonuses] ADD [PB_DateRegistration] [datetime] NULL
GO

-- Version92.sql
-- для версии 2009.2
update [dbo].[setting] set st_version = '9.2.8', st_moduledate = convert(datetime, '2010-09-30', 120),  st_financeversion = '9.2.8', st_financedate = convert(datetime, '2010-09-30', 120) where st_version like '9.%'
GO
UPDATE dbo.SystemSettings SET SS_ParmValue='2010-09-30' WHERE SS_ParmName='SYSScriptDate'
GO

--1_AddFieldQP_Date.sql
if not exists(select id from syscolumns where id = OBJECT_ID('QuotaParts') and name = 'QP_Date')
     alter TABLE [dbo].[QuotaParts] add [QP_Date] smalldatetime NULL
GO
update QuotaParts
set QP_Date = QD_Date
from QuotaDetails 
where QD_ID = QP_QDID

--2_AddTrigger.sql
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_QuotaDetails_QuotaPartsDate]'))
DROP TRIGGER [dbo].[T_QuotaDetails_QuotaPartsDate]
GO
CREATE TRIGGER [dbo].[T_QuotaDetails_QuotaPartsDate]
   ON  [dbo].[QuotaDetails]
   FOR INSERT,UPDATE
AS 
BEGIN
	update QuotaParts
	set QP_Date = QD_Date
	from INSERTED 
	where QD_ID = QP_QDID
END
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_QuotaPartsDate]'))
DROP TRIGGER [dbo].[T_QuotaPartsDate]
GO
CREATE TRIGGER [dbo].[T_QuotaPartsDate]
   ON  [dbo].[QuotaParts]
   FOR INSERT,UPDATE
AS 
BEGIN
	update QuotaParts
	set QP_Date = QD_Date
	from QuotaParts as QP join QuotaDetails as QD on QD_ID = QP_QDID
	where exists (select 1 from Inserted as Ins where Ins.QP_ID = QP.QP_ID)
END
GO
 
--3_CreateIndex.sql
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetails]') AND name = N'X_QD_Object_1')
DROP INDEX [X_QD_Object_1] ON [dbo].[QuotaDetails] WITH ( ONLINE = OFF )
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetails]') AND name = N'X_QD_Object_2')
DROP INDEX [X_QD_Object_2] ON [dbo].[QuotaDetails] WITH ( ONLINE = OFF )
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetails]') AND name = N'X_QD_Object_3')
DROP INDEX [X_QD_Object_3] ON [dbo].[QuotaDetails] WITH ( ONLINE = OFF )
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaParts]') AND name = N'X_QP_Object_1')
DROP INDEX [X_QP_Object_1] ON [dbo].[QuotaParts] WITH ( ONLINE = OFF )
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaParts]') AND name = N'X_QP_Object_2')
DROP INDEX [X_QP_Object_2] ON [dbo].[QuotaParts] WITH ( ONLINE = OFF )
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetails]') AND name = N'x_QD_Object')
DROP INDEX [x_QD_Object] ON [dbo].[QuotaDetails] WITH ( ONLINE = OFF )
GO
/*CREATE NONCLUSTERED INDEX [x_QD_Object] ON [dbo].[QuotaDetails] 
(
	[QD_Date] ASC,
	[QD_Type] ASC,
	[QD_IsDeleted] ASC
)
INCLUDE ( [QD_QTID],
[QD_Release]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]*/

CREATE NONCLUSTERED INDEX [x_QD_Object] ON [dbo].[QuotaDetails] 
(
	[QD_QTID] asc,
	[QD_Date] asc	
)
INCLUDE ([QD_ID],[QD_Type],[QD_Release],[QD_Comment],[QD_IsDeleted]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaLimitations]') AND name = N'x_QL_Object')
DROP INDEX [x_QL_Object] ON [dbo].[QuotaLimitations] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [x_QL_Object] ON [dbo].[QuotaLimitations] 
(
	[QL_QPID] ASC,
	[QL_Duration] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaParts]') AND name = N'x_QP_Object')
DROP INDEX [x_QP_Object] ON [dbo].[QuotaParts] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [x_QP_Object] ON [dbo].[QuotaParts] 
(
	[QP_QDID] ASC,
	[QP_Date] ASC
)
INCLUDE ( [QP_FilialKey],
[QP_CityDepartments],
[QP_IsDeleted],
[QP_AgentKey],
[QP_Durations]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_DogovorList]') AND name = N'X_DL_GetQuotaLoadListData_N')
DROP INDEX [X_DL_GetQuotaLoadListData_N] ON [dbo].[tbl_DogovorList] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_DL_GetQuotaLoadListData_N]
ON [dbo].[tbl_DogovorList] ([DL_SVKEY],[DL_CODE])
INCLUDE ([DL_KEY],[DL_SUBCODE1],[DL_PARTNERKEY],[DL_DATEBEG],[DL_DATEEND])
GO

--4_GetQuotaLoadListData_N.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetQuotaLoadListData_N]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetQuotaLoadListData_N]
GO

CREATE procedure [dbo].[GetQuotaLoadListData_N]
(
--<VERSION>2008.1.01.20a</VERSION>
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
@bShowByCheckIn bit =null
)
as 

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

CREATE TABLE #QuotaLoadList(
QL_QTID int, QL_PRKey int, QL_SubCode1 int, QL_PartnerName nvarchar(100) collate Cyrillic_General_CI_AS, QL_Description nvarchar(255) collate Cyrillic_General_CI_AS, 
QL_dataType smallint, QL_Type smallint, QL_Release int, QL_Durations nvarchar(20) collate Cyrillic_General_CI_AS, QL_FilialKey int, 
QL_CityDepartments int, QL_AgentKey int, QL_CustomerInfo nvarchar(150) collate Cyrillic_General_CI_AS, QL_DateCheckinMin smalldatetime,
QL_ByRoom int)

--CREATE CLUSTERED INDEX X_QuotaLoadList
--ON #QuotaLoadList(QL_QTID ASC)

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
		set @str = 'ALTER TABLE #QuotaLoadList ADD QL_' + CAST(@n as varchar(3)) + ' smallint'
		exec (@str)
		set @n = @n + 1
	END
END


if @bShowCommonInfo = 1
BEGIN
	insert into #QuotaLoadList 
	(QL_QTID, QL_Type, QL_Release, QL_dataType, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	select	DISTINCT QT_ID, QD_Type, QD_Release, NU_ID, @DateEnd+1,QT_PRKey, QT_ByRoom
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
	DECLARE @Service_SubCode1 int, @Object_SubCode1 int, @Object_SubCode2 int, @Service_SubCode2 int
	SET @Object_SubCode1=0
	SET @Object_SubCode2=0
	IF @DLKey is not null				-- если мы запустили процедуру из конкрентной услуги
	BEGIN
		SELECT	@Service_SVKey=DL_SVKey, @Service_Code=DL_Code, @Service_SubCode1=DL_SubCode1
			  , @AgentKey=ISNULL(DL_Agent,0), @Service_PRKey=DL_PartnerKey, @Service_SubCode2 = DL_SubCode2
		FROM	DogovorList (nolock)
		WHERE	DL_Key=@DLKey
		If @Service_SVKey=3
			SELECT @Object_SubCode1=HR_RMKey, @Object_SubCode2=HR_RCKey 
			FROM dbo.HotelRooms (nolock) WHERE HR_Key=@Service_SubCode1
		Else
			SET @Object_SubCode1=@Service_SubCode1
		IF @Service_SVKey=1
			SET @Object_SubCode2=@Service_SubCode2
	END

--временная таблица чтобы не делать 2 запросов
DECLARE @QuotaLoadTemp table(
	 QT_ID int
	,QT_PRKey int
	,QT_ByRoom bit
	,QO_SubCode1 int
	,QO_SubCode2 int
	,QD_ID int
	,QD_Date smalldatetime
	,QD_Type int
	,QD_Release smallint
	,QP_Places smallint
	,QP_Busy smallint
	,QP_ID int
	,QP_Durations varchar(20)
	,QP_FilialKey int
	,QP_CityDepartments int
	,QP_AgentKey int
	,QP_IsNotCheckIn bit
	,QD_Comment varchar(255)
	,QP_Comment varchar(255)
	,QP_CheckInPlaces smallint
	,QP_CheckInPlacesBusy smallint
)
	if @bShowCommonInfo != 1
	INSERT INTO @QuotaLoadTemp (QT_ID, QT_PRKey, QT_ByRoom, QO_SubCode1, QO_SubCode2, QD_ID, QD_Date, QD_Type, QD_Release, QP_Places, QP_Busy, QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_IsNotCheckIn, QD_Comment, QP_Comment, QP_CheckInPlaces, QP_CheckInPlacesBusy)
	SELECT QT_ID, QT_PRKey, QT_ByRoom, QO_SubCode1, QO_SubCode2, QD_ID, QD_Date, QD_Type, QD_Release, QP_Places, QP_Busy, QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_IsNotCheckIn, QD_Comment, QP_Comment, QP_CheckInPlaces, QP_CheckInPlacesBusy
	FROM	Quotas join QuotaObjects on QT_ID = QO_QTID
			join QuotaDetails on QD_QTID = QT_ID
			join QuotaParts on QP_QDID = QD_ID
	WHERE	((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) 
			and QD_Date between @DateStart and @DateEnd
			and QP_Date between @DateStart and @DateEnd
			and QP_QDID = QD_ID	
			and (QP_AgentKey is null or (@bShowAgencyInfo=1 and ((@AgentKey=QP_AgentKey) or (@AgentKey is null))))
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey=QT_PRKey or QT_PRKey=0)))
			and (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select QL_QPID From QuotaLimitations WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID))))
			and ISNULL(QP_IsDeleted,0)=0
			and ISNULL(QD_IsDeleted,0)=0
	ORDER BY QD_Date DESC, QD_ID


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
END
	/*insert into #QuotaLoadList (QL_QTID, QL_Type, QL_Release, QL_dataType, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	select DISTINCT QT_ID, QD_Type, QD_Release, NU_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, '', @DateEnd+1,QT_PRKey,QT_ByRoom
	from	Quotas, QuotaObjects, QuotaDetails, QuotaParts, Numbers
	where	QT_ID=QO_QTID and QD_QTID=QT_ID and QP_QDID = QD_ID 
			and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) 
			and QD_Date between @DateStart and @DateEnd
			and QP_Date between @DateStart and @DateEnd
			and (QP_AgentKey is null or (@bShowAgencyInfo=1 and ((@AgentKey=QP_AgentKey) or (@AgentKey is null))))
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey=QT_PRKey or QT_PRKey=0)))
			and (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select 1 From QuotaLimitations WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID))))
			and ISNULL(QP_IsDeleted,0)=0
			and ISNULL(QD_IsDeleted,0)=0
			and NU_ID between @Result_From and @Result_To
			and (@DLKey is null or (@DLKey is not null and QO_SubCode1 in (0,@Object_SubCode1) and QO_SubCode2 in (0,@Object_SubCode2)))*/
			
	insert into #QuotaLoadList (QL_QTID, QL_Type, QL_Release, QL_dataType, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	select DISTINCT QT_ID, QD_Type, QD_Release, NU_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, '', @DateEnd+1,QT_PRKey,QT_ByRoom
	from @QuotaLoadTemp, Numbers
	where NU_ID between @Result_From and @Result_To
	and (@DLKey is null or (@DLKey is not null and QO_SubCode1 in (0,@Object_SubCode1) and QO_SubCode2 in (0,@Object_SubCode2)))
END

--update #QuotaLoadList set QL_CustomerInfo = (Select PR_Name from Partners where PR_Key = QL_FilialKey and QL_FilialKey > 0)

DECLARE @QD_ID int, @Date smalldatetime, @State smallint, @QD_Release int, @QP_Durations varchar(20), @QP_FilialKey int,
		@QP_CityDepartments int, @QP_AgentKey int, @Quota_Places int, @Quota_Busy int, @QP_IsNotCheckIn bit,
		@QD_QTID int, @QP_ID int, @Quota_Comment varchar(8000), @Stop_Comment varchar(255) --,	@QT_ID int
DECLARE @ColumnName varchar(10), @QueryUpdate varchar(8000), @QueryUpdate1 varchar(255), @QueryWhere1 varchar(255), @QueryWhere2 varchar(255), 
		@QD_PrevID int, @StopSale_Percent int, @CheckInPlaces smallint, @CheckInPlacesBusy smallint --@QuotaObjects_Count int, 

if @bShowCommonInfo = 1
	DECLARE curQLoadList CURSOR FOR SELECT
			QT_ID, QD_ID, QD_Date, QD_Type, QD_Release,
			QD_Places, QD_Busy,
			0,'',0,0,0,0, ISNULL(REPLACE(QD_Comment,'''','"'),''),0,0
	FROM	Quotas, QuotaObjects, QuotaDetails
	WHERE	QT_ID=QO_QTID and QD_QTID=QT_ID
			and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) and QD_Date between @DateStart and @DateEnd
			and (QD_IsDeleted = 0 or QD_IsDeleted is null)
	ORDER BY QD_Date DESC, QD_ID
else
	/*DECLARE curQLoadList CURSOR FOR 
	SELECT QT_ID, QD_ID, QD_Date, QD_Type, QD_Release, QP_Places, QP_Busy, QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, ISNULL(QP_IsNotCheckIn,0), ISNULL(REPLACE(QD_Comment,'''','"'),'') + '' + ISNULL(REPLACE(QP_Comment,'''','"'),''), QP_CheckInPlaces, QP_CheckInPlacesBusy
	FROM	Quotas, QuotaObjects, QuotaDetails,QuotaParts
	WHERE	QT_ID=QO_QTID and QD_QTID=QT_ID and QP_QDID = QD_ID			
			and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) 
			and QD_Date between @DateStart and @DateEnd
			and QP_Date between @DateStart and @DateEnd
			and QP_QDID = QD_ID	
			and (QP_AgentKey is null or (@bShowAgencyInfo=1 and ((@AgentKey=QP_AgentKey) or (@AgentKey is null))))
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey=QT_PRKey or QT_PRKey=0)))
			and (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select QL_QPID From QuotaLimitations WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID))))
			and (QP_IsDeleted = 0 or QP_IsDeleted is null)
			and (QD_IsDeleted = 0 or QD_IsDeleted is null)
	ORDER BY QD_Date DESC, QD_ID*/
	
	
	DECLARE curQLoadList CURSOR FOR 
	SELECT QT_ID, QD_ID, QD_Date, QD_Type, QD_Release, QP_Places, QP_Busy, QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, ISNULL(QP_IsNotCheckIn,0), ISNULL(REPLACE(QD_Comment,'''','"'),'') + '' + ISNULL(REPLACE(QP_Comment,'''','"'),''), QP_CheckInPlaces, QP_CheckInPlacesBusy
	FROM	@QuotaLoadTemp
	ORDER BY QD_Date DESC, QD_ID

OPEN curQLoadList
FETCH NEXT FROM curQLoadList INTO	@QT_IDLocal,
									@QD_ID, @Date, @State, @QD_Release, @Quota_Places, @Quota_Busy,
									@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, @QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy
SET @QD_PrevID = @QD_ID - 1
--SELECT @QuotaObjects_Count = count(*) from QuotaObjects, Quotas where QO_QTID = QT_ID and QT_ID = @QT_ID

SET @StopSale_Percent=0
WHILE @@FETCH_STATUS = 0
BEGIN
	set @QueryUpdate1=''
	if DATEADD(DAY,ISNULL(@QD_Release,0),GetDate()) < @Date
		set @QueryUpdate1=', QL_DateCheckInMin=''' + CAST(@Date as varchar(250)) + ''''
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
		if @QP_Durations is null
			set @QueryWhere2 = @QueryWhere2 + ' and QL_Durations is null' 
		else
			set @QueryWhere2 = @QueryWhere2 + ' and QL_Durations = ''' + @QP_Durations + ''''
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
			set @QueryUpdate = 'UPDATE #QuotaLoadList SET	
					QL_' + @ColumnName + ' = (CASE QL_dataType WHEN 11 THEN ''' + CAST((@Quota_Places) as varchar(10)) + ''' WHEN 12 THEN ''' + CAST((@Quota_Places-@Quota_Busy) as varchar(10)) + ''' WHEN 13 THEN ''' + CAST((@Quota_Busy) as varchar(10)) + ''' END)+' + ''';' + CAST(@QP_ID as varchar(10)) + ';' + CAST(@StopSale_Percent as varchar(10)) + ';' + CAST(@QP_IsNotCheckIn as varchar(1)) + ';'  + CAST(@Quota_Comment as varchar(7900)) + ''''
				+ @QueryUpdate1
				+ @QueryWhere1 + @QueryWhere2 + ' and QL_dataType in (11,12,13) and QL_QTID=' + CAST(@QT_IDLocal as varchar(10))
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
										@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, @QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy
END
CLOSE curQLoadList
DEALLOCATE curQLoadList

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

update #QuotaLoadList set QL_CustomerInfo = (Select PR_Name from Partners (nolock) where PR_Key = QL_AgentKey and QL_AgentKey > 0)
update #QuotaLoadList set QL_PartnerName = (Select PR_Name from Partners (nolock) where PR_Key = QL_PRKey and QL_PRKey > 0)
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

DECLARE @QO_SubCode int, @QO_TypeD smallint, @DL_SubCode1 int, @QT_ID_Prev int, @ServiceName1 varchar(100), @ServiceName2 varchar(100), @Temp varchar(100)
DECLARE curQLoadListQO CURSOR FOR 
	SELECT DISTINCT QO_QTID, QO_SubCode1, 1, null FROM QuotaObjects (nolock) WHERE QO_QTID in (SELECT QL_QTID FROM #QuotaLoadList (nolock) WHERE QO_QTID is not null)
	UNION
	SELECT DISTINCT QO_QTID, QO_SubCode2, 2, null FROM QuotaObjects (nolock) WHERE QO_QTID in (SELECT QL_QTID FROM #QuotaLoadList (nolock) WHERE QO_QTID is not null)
	UNION
	SELECT DISTINCT null, null, null, QL_SubCode1 FROM #QuotaLoadList (nolock) WHERE QL_SubCode1 is not null
	ORDER BY 1,3

OPEN curQLoadListQO
FETCH NEXT FROM curQLoadListQO INTO	@QT_IDLocal, @QO_SubCode, @QO_TypeD, @DL_SubCode1
Set @QT_ID_Prev=@QT_IDLocal
Set @ServiceName1=''
Set @ServiceName2=''


WHILE @@FETCH_STATUS = 0
BEGIN
	if @DL_SubCode1 is not null
	BEGIN
		Set @Temp=''
		exec GetSvCode1Name @Service_SVKey, @DL_SubCode1, null, @Temp output, null, null

		Update #QuotaLoadList set QL_Description=ISNULL(QL_Description,'') + @Temp where QL_SubCode1=@DL_SubCode1
	END
	Else
	BEGIN
		If @QT_ID_Prev != @QT_IDLocal
		BEGIN
			If @Service_SVKey=3
			BEGIN
				Set @ServiceName2='(' + @ServiceName2 + ')'
			END
			Update #QuotaLoadList set QL_Description=LEFT(ISNULL(QL_Description,'') + @ServiceName1 + @ServiceName2,255) where QL_QTID=@QT_ID_Prev
			Set @ServiceName1=''
			Set @ServiceName2=''
		END
		SET @QT_ID_Prev=@QT_IDLocal
		Set @Temp=''
		If @Service_SVKey=3
		BEGIN
			IF @QO_TypeD=1
			BEGIN
				EXEC GetRoomName @QO_SubCode, @Temp output, null
				If @ServiceName1!=''
					Set @ServiceName1=@ServiceName1+','
				Set @ServiceName1=@ServiceName1+@Temp
			END			
			Set @Temp=''
			IF @QO_TypeD=2
			BEGIN
				EXEC GetRoomCtgrName @QO_SubCode, @Temp output, null
				If @ServiceName2!=''
					Set @ServiceName2=@ServiceName2+','
				Set @ServiceName2=@ServiceName2+@Temp
			END
		END
		ELse
		BEGIN
			exec GetSvCode1Name @Service_SVKey, @QO_SubCode, null, @Temp output, null, null
			If @ServiceName1!=''
				Set @ServiceName1=@ServiceName1+','
			Set @ServiceName1=@ServiceName1+@Temp
		END
	END
	FETCH NEXT FROM curQLoadListQO INTO	@QT_IDLocal, @QO_SubCode, @QO_TypeD, @DL_SubCode1
END
If @Service_SVKey=3
BEGIN
	Set @ServiceName2='(' + @ServiceName2 + ')'
END
Update #QuotaLoadList set QL_Description=LEFT(ISNULL(QL_Description,'') + @ServiceName1 + @ServiceName2,255) where QL_QTID=@QT_ID_Prev

CLOSE curQLoadListQO
DEALLOCATE curQLoadListQO

If @Service_SVKey=3
BEGIN
	Update #QuotaLoadList set QL_Description = QL_Description + ' - Per person' where QL_ByRoom = 0
END

IF @ResultType is null or @ResultType not in (10)
BEGIN
	select * 
	from #QuotaLoadList (nolock)
	order by QL_QTID-QL_QTID DESC /*Сначала квоты, потом неквоты*/,QL_Description,QL_PartnerName,QL_Type DESC,QL_Release,QL_Durations,QL_CityDepartments,QL_FilialKey,QL_CustomerInfo,QL_QTID,QL_DataType
	RETURN 0
END
ELSE
BEGIN --для наличия мест(из оформления)
	declare @ServicePlacesTrTable varchar (1000)
	set @ServicePlacesTrTable = '
	DECLARE  @ServicePlacesTr TABLE
	(
		SPT_QTID int, SPT_PRKey int, SPT_SubCode1 int, SPT_PartnerName varchar(100), SPT_Description varchar(255), 
		SPT_Type smallint, SPT_FilialKey int, SPT_CityDepartments int, SPT_Release int, SPT_Durations varchar(100),
		SPT_AgentKey int, SPT_Date smalldatetime, SPT_Places smallint, SPT_Stop smallint, SPT_CheckIn smallint
	)'
	
	DECLARE  @ServicePlacesTr TABLE
	(
		SPT_QTID int, SPT_PRKey int, SPT_SubCode1 int, SPT_PartnerName nvarchar(100), SPT_Description nvarchar(255), 
		SPT_Type smallint, SPT_FilialKey int, SPT_CityDepartments int, SPT_Release int, SPT_Durations nvarchar(100),
		SPT_AgentKey int, SPT_Date smalldatetime, SPT_Places smallint, SPT_Stop smallint, SPT_CheckIn smallint
	)
	
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

		set @str = @ServicePlacesTrTable + '
			INSERT INTO @ServicePlacesTr 
				(SPT_QTID, SPT_PRKey,SPT_SubCode1,SPT_PartnerName,SPT_Description,SPT_Type,
				SPT_FilialKey,SPT_CityDepartments,SPT_Release,SPT_Durations,SPT_AgentKey,
				SPT_Date,SPT_Places) 
			SELECT QL_QTID, QL_PRKey,QL_SubCode1,QL_PartnerName, QL_Description, QL_Type, 
				QL_FilialKey, QL_CityDepartments,QL_Release,QL_Durations,QL_AgentKey, 
				''' + CAST(@curDate as varchar(20)) + ''', QL_' + CAST(@n as varchar(3)) + '
				FROM #QuotaLoadList (nolock)
				WHERE QL_dataType=21'
		exec (@str)

		set @str = @ServicePlacesTrTable + 'UPDATE @ServicePlacesTr SET SPT_Stop=
					(SELECT QL_' + CAST(@n as varchar(3)) + '
					FROM #QuotaLoadList (nolock)
					WHERE  QL_dataType=22 and 
					SPT_QTID=QL_QTID and
					SPT_PRKey=QL_PRKey and 
					ISNULL(SPT_SubCode1,-1)=ISNULL(QL_SubCode1,-1) and 
					SPT_PartnerName=QL_PartnerName and 
					SPT_Description=QL_Description and 
					SPT_Type=QL_Type and 
					ISNULL(SPT_FilialKey,-1)=ISNULL(QL_FilialKey,-1) and 
					ISNULL(SPT_CityDepartments,-1)=ISNULL(QL_CityDepartments,-1) and 
					ISNULL(SPT_Release,-1)=ISNULL(QL_Release,-1) and 
					ISNULL(SPT_Durations,-1)=ISNULL(QL_Durations,-1) and 
					ISNULL(SPT_AgentKey,-1)=ISNULL(QL_AgentKey,-1) and 
					SPT_Date=''' + CAST(@curDate as varchar(20)) + ''')
					WHERE SPT_Date=''' + CAST(@curDate as varchar(20))+ ''''

		exec (@str)

		set @str = @ServicePlacesTrTable + 'UPDATE @ServicePlacesTr SET SPT_CheckIn=
					(SELECT QL_' + CAST(@n as varchar(3)) + '
					FROM #QuotaLoadList (nolock)
					WHERE  QL_dataType=23 and
					SPT_QTID=QL_QTID and 
					SPT_PRKey=QL_PRKey and 
					ISNULL(SPT_SubCode1,-1)=ISNULL(QL_SubCode1,-1) and 
					SPT_PartnerName=QL_PartnerName and 
					SPT_Description=QL_Description and 
					SPT_Type=QL_Type and 
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
	SP_Type smallint, SP_FilialKey int, SP_CityDepartments int, 
	SP_Places1 smallint, SP_Places2 smallint, SP_Places3 smallint, 
	SP_NonReleasePlaces1 smallint,SP_NonReleasePlaces2 smallint,SP_NonReleasePlaces3 smallint, 
	SP_StopPercent1 smallint,SP_StopPercent2 smallint,SP_StopPercent3 smallint
)

DECLARE @SPT_QTID int, @SPT_PRKey int, @SPT_SubCode1 int, @SPT_PartnerName varchar(100), @SPT_Description varchar(255), 
		@SPT_Type smallint, @SPT_FilialKey int, @SPT_CityDepartments int, @SPT_Release smallint, @SPT_Date smalldatetime, 
		@SPT_Places smallint, @SPT_Stop smallint, @SPT_CheckIn smallint, @SPT_PRKey_Old int, @SPT_PartnerName_Old varchar(100), 
		@SPT_SubCode1_Old int, @SPT_Description_Old varchar(255), @SPT_Type_Old smallint, @SPT_FilialKey_Old int,
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
			 SPT_QTID, SPT_PRKey, SPT_SubCode1, SPT_PartnerName, SPT_Description, SPT_Type, SPT_FilialKey, 
			 SPT_CityDepartments, ISNULL(SPT_Release, 0), SPT_Date, ISNULL(SPT_Places, 0), ISNULL(SPT_Stop,0), SPT_CheckIn
	FROM	@ServicePlacesTr
	ORDER BY  SPT_PRKey, SPT_Type, SPT_SubCode1, SPT_PartnerName, SPT_Description, 
		SPT_FilialKey, SPT_CityDepartments, SPT_Date, SPT_Release

OPEN curQ2
FETCH NEXT FROM curQ2 INTO @SPT_QTID, @SPT_PRKey, @SPT_SubCode1, @SPT_PartnerName, @SPT_Description, 
		@SPT_Type, @SPT_FilialKey, @SPT_CityDepartments, @SPT_Release, @SPT_Date, @SPT_Places, @SPT_Stop, @SPT_CheckIn	

SET @SPT_PRKey_Old=@SPT_PRKey
SET @SPT_Description_Old=@SPT_Description
SET @SPT_PartnerName_Old=@SPT_PartnerName
SET @SPT_Type_Old=@SPT_Type
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
-- При смене даты обнуляем текущие колличества мест
		SET @currentPlaces1=0
		SET @currentPlaces2=0
		SET @currentPlaces3=0
		SET @currentNonReleasePlaces1=0
		SET @currentNonReleasePlaces2=0
		SET @currentNonReleasePlaces3=0
	END

	IF @SPT_PRKey!=@SPT_PRKey_Old or @SPT_Description!=@SPT_Description_Old or ISNULL(@SPT_Type,-1)!=ISNULL(@SPT_Type_Old,-1)
	BEGIN
		IF @quotaCounter1 = 0 SET @quotaCounter1 = 1
		IF @quotaCounter2 = 0 SET @quotaCounter2 = 1
		IF @quotaCounter3 = 0 SET @quotaCounter3 = 1
		INSERT INTO @ServicePlaces (SP_PRKey, SP_SubCode1, SP_PartnerName, SP_Description, SP_Type, 
				SP_FilialKey, SP_CityDepartments, SP_Places1, SP_Places2, SP_Places3, 
				SP_NonReleasePlaces1, SP_NonReleasePlaces2, SP_NonReleasePlaces3,
				SP_StopPercent1,SP_StopPercent2,SP_StopPercent3)
		Values (@SPT_PRKey_Old, @SPT_SubCode1_Old, @SPT_PartnerName_Old, @SPT_Description_Old, @SPT_Type_Old, 
				@SPT_FilialKey_Old, @SPT_CityDepartments_Old, 
				ISNULL(@OblectPlacesMin1,@currentPlaces1), ISNULL(@OblectPlacesMin2,@currentPlaces2), ISNULL(@OblectPlacesMin3,@currentPlaces3),
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
	SET @SPT_Date_Old=@SPT_Date
	FETCH NEXT FROM curQ2 INTO @SPT_QTID, @SPT_PRKey, @SPT_SubCode1, @SPT_PartnerName, @SPT_Description, 
			@SPT_Type, @SPT_FilialKey, @SPT_CityDepartments, @SPT_Release, @SPT_Date, @SPT_Places, @SPT_Stop, @SPT_CheckIn	

	If @@FETCH_STATUS != 0
	BEGIN
		IF @quotaCounter1 = 0 SET @quotaCounter1 = 1
		IF @quotaCounter2 = 0 SET @quotaCounter2 = 1
		IF @quotaCounter3 = 0 SET @quotaCounter3 = 1
		INSERT INTO @ServicePlaces (SP_PRKey, SP_SubCode1, SP_PartnerName, SP_Description, SP_Type, 
			SP_FilialKey, SP_CityDepartments, SP_Places1, SP_Places2, SP_Places3, 
			SP_NonReleasePlaces1, SP_NonReleasePlaces2, SP_NonReleasePlaces3,
			SP_StopPercent1,SP_StopPercent2,SP_StopPercent3)
		Values (@SPT_PRKey_Old, @SPT_SubCode1_Old, @SPT_PartnerName_Old, @SPT_Description_Old, @SPT_Type_Old, 
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
		SP_PRKey,SP_PartnerName,SP_Description,SP_SubCode1,SP_Type,SP_FilialKey,SP_CityDepartments,
		CAST(SP_Places1 as varchar(4))+';'+CAST(SP_NonReleasePlaces1 as varchar(4))+';'+CAST(SP_StopPercent1 as varchar(4)) as SP_1,
		CAST(SP_Places2 as varchar(4))+';'+CAST(SP_NonReleasePlaces2 as varchar(4))+';'+CAST(SP_StopPercent2 as varchar(4)) as SP_2,
		CAST(SP_Places3 as varchar(4))+';'+CAST(SP_NonReleasePlaces3 as varchar(4))+';'+CAST(SP_StopPercent3 as varchar(4)) as SP_3
	from @ServicePlaces
	order by SP_Description, SP_PartnerName, SP_Type
GO

grant execute on [dbo].[GetQuotaLoadListData_N] to public
GO