/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%% Дата формирования: 31.01.2012 19:09 Для поисковой: False %%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*********************************************************************/
/* begin sp_GetServiceCost.sql */
/*********************************************************************/
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
--<DATE>2012-01-11</DATE>
---<VERSION>2009.2.9.8</VERSION>

SET DATEFIRST 1
DECLARE @tourlong int

Set @sellDate = ISNULL(@sellDate,GetDate())

If @svKey = 1 and @days > 0
BEGIN
	Set @tourlong = @days
	-- karimbaeva 11.01.2012 продолжительность тура устанавливалась в ноль
	--Set @days = 0 
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

If @days > 0 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)
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
		If (@days > 0 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)) and @IsFetchNormal = 1 	-- fetch нам подходит
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
						WHERE	CL_DATE between @CS_Date and @CS_DateEnd /*and (CL_ByDay = -1)*/
				ELSE
					UPDATE @TMPTable SET CL_CostNetto = @CS_CostNetto, CL_ByDay = @CS_ByDay, CL_Part = @COST_ID,
						CL_Cost = @CS_Cost, CL_Discount = (CASE WHEN @CS_Discount=1 THEN 1 ELSE null END), CL_Type = @CS_Type, CL_Rate = @CS_Rate
						WHERE	CL_DATE between @CS_Date and @CS_DateEnd /*and (CL_ByDay = -1)*/ AND CHARINDEX(CAST(DATEPART (weekday, CL_DATE) as varchar(1)),@DayOfWeeks) > 0
				SET @COST_ID = @COST_ID + 1
			END	-- if @CS_ByDay = 4
			select @NotCalculatedCosts = Count(*) from @TMPTable where CL_CostNetto is null
		END -- цены подходят для поиска и есть продолжительность
		ELSE
			If @IsFetchNormal = 1
				Set @NotCalculatedCosts = 0

	If (@days > 0 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)) or @IsFetchNormal = 0
	BEGIN
		fetch next from costCursor 
			into	@CS_Date, @CS_DateEnd, @CS_Week, @CS_CostNetto, @CS_Cost, 
					@CS_Discount, @CS_Type, @CS_Rate, @CS_LongMin, @CS_Long, 
					@CS_ByDay, @CS_Profit, @CS_ID, @CS_CheckInDateBEG, @CS_CheckInDateEND, @CS_DateSellBeg, @CS_DateSellEnd

		If @CS_ByDay = 0 and @CS_Date = @date and @CS_DateEnd <= (@date + @days) and @days > 0 and (@sellDate between ISNULL(@CS_DateSellBeg, @sellDate - 1) and ISNULL(@CS_DateSellEnd, @sellDate + 1))
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

If @days > 0 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)
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
If @days > 0 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)
	Update @TMPTable set CL_Pax = CL_Pax * @men Where CL_Type = 0
else
	If (isnull(@CS_Type, 0) = 0)
		Set @CS_Pax = @men
	Else
		Set @CS_Pax = 1

--Update @TMP set CL_Course = 0 Where CL_ByDay not in (0,3) and CL_DateFirst != CL_Date
--Update @TMP set CL_Course = CL_Course*(@margin + 100)/100 Where CL_Discount + (1- @marginType) != 0

If @days > 0 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)
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

If (@days > 0 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)) and @nSPId is null    -- Новый код !!!!!  and @useServicePrices is null
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
		UPDATE @TMPTable SET CL_Course = 0 WHERE ISNULL(CL_Part, 0) = ISNULL(@TMP_Number_Part, 0)
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
/*********************************************************************/
/* end sp_GetServiceCost.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 07122011_AlterView_Quotes.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='v' and name='Quotes')
	drop view dbo.Quotes
go

CREATE VIEW [dbo].[Quotes]
AS
SELECT     q.QT_PRKey, qo.QO_SVKey AS qt_svkey, qo.QO_SubCode1 AS qt_subcode1, qo.QO_SubCode2 AS subcode2, qo.QO_Code AS qt_code, qd.QD_Date AS qt_date, 
                      qd.QD_Places AS qt_places, qd.QD_Busy AS qt_busy, qp.QP_AgentKey AS qt_agent, q.QT_ID AS qt_key, qd.QD_Release AS qt_release
FROM         dbo.Quotas AS q INNER JOIN
                      dbo.QuotaObjects AS qo ON qo.QO_QTID = q.QT_ID INNER JOIN
                      dbo.QuotaDetails AS qd ON qd.QD_QTID = q.QT_ID INNER JOIN
                      dbo.QuotaParts AS qp ON qp.QP_QDID = qd.QD_ID
GO

grant select on dbo.Quotes to public
go
/*********************************************************************/
/* end 07122011_AlterView_Quotes.sql */
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
	--<VERSION>2009.2.9</VERSION>
	--<DATE>2011-12-13</DATE>

      declare @isSubCode2 smallint
      select @isSubCode2 = isnull(SV_ISSUBCODE2, 0) from [Service] where SV_key = @svkey
      if(@isSubCode2 <= 0)
            set @subcode2 = 0
            
      if(@svkey = 1)
            set @subcode2 = -1

      -- MEG00023260 Paul G 20.12.2010
      -- сделал для 9-й версии более гибкую настройку @noPlacesResult
      if exists(select 1 from systemsettings where ss_parmname like 'NoPlacesQuoteResult_' + convert(varchar, @svkey))
      begin
            select @noPlacesResult = cast(IsNull(ss_parmvalue,@noPlacesResult) as int) from systemsettings where ss_parmname like 'NoPlacesQuoteResult_' + convert(varchar, @svkey)
      end
      -- End MEG00023260

	if (@svkey = 1)
	begin
		declare @tariffToStop varchar(20)
		set @tariffToStop = ',' + ltrim(str(@subcode1)) + ','
		if exists(select 1 from dbo.systemsettings where ss_parmname='MWTariffsToStop' and charindex(@tariffToStop, ',' + ss_parmvalue + ',') > 0)
			set @noPlacesResult = 0
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


	declare @dateFrom datetime
	declare @dateTo datetime
	set @dateFrom = dateadd(day, @day - 1, @date)
	set @dateTo = dateadd(day, @day + @days - 2, @date)

	declare @tmpSubcode1 int
	if(@svkey = 3 and @subcode1 > 0 and @subcode2 <= 0) -- hotelRoomKey --> subcode1, subcode2
	begin
		select @tmpSubcode1 = hr_rmkey, @subcode2 = hr_rckey from hotelrooms with(nolock) where hr_key = @subcode1
		set @subcode1 = @tmpSubcode1
	end

				
	
	declare @result int
	declare @currentDate datetime
	select @currentDate = currentDate from dbo.mwCurrentDate


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

	declare @tmpQuotes table(
		qt_svkey int,
		qt_code int,
		qt_subcode1 int,
		qt_subcode2 int,
		qt_agent int,
		qt_prkey int,
		qt_bycheckin int,
		qt_release int,
		qt_places int,
		qt_date datetime,
		qt_byroom int,
		qt_type int,
		qt_long int,
		qt_placesAll int,
		qt_stop smallint,
		qt_qoid int
	)

	declare @tmpDate datetime
	declare @dayOfWeek int

	if(@svkey <> 1 or @findFlight <= 0)
	begin
		if(@svkey = 1)
		begin


			set @dayOfWeek = datepart(dw, @dateFrom) - 1
			if(@dayOfWeek = 0)
				set @dayOfWeek = 7

				if (@flightpkkey < 0)
				begin
					 if not exists(select top 1 ch_key from charter with(nolock) inner join airseason with(nolock) on as_chkey = ch_key
				where ch_key = @code 
					and (AS_WEEK is null or len(as_week)=0 or as_week like ('%' + cast(@dayOfWeek as varchar) + '%')) -- Golubinsky. 13.12.2011. MEG00039207. проверка AS_WEEK на случай, когда поле не заполнено
					and (as_dateFrom is null or (as_dateFrom is not null and @dateFrom >= as_dateFrom))
					and (AS_DATETO is null or (AS_DATETO is not null and @dateFrom <= AS_DATETO)))	-- Golubinsky. 13.12.2011. MEG00039207. проверка диапазона дат на случай, если as_dateFrom и AS_DATETO null
					begin
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
						values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
							return 
					end
				end
				else
				begin
			if (@flightpkkey >= 0)
			begin
			 if not exists(select top 1 ch_key from charter with(nolock) inner join airseason with(nolock) on as_chkey = ch_key
						inner join tbl_costs on (cs_svkey = 1 and cs_code = ch_key 
						and @dateFrom between cs_date and cs_dateend
						and cs_subcode1=@subcode1 and cs_pkkey = @flightpkkey)
						where ch_key = @code 
							and (AS_WEEK is null or len(as_week)=0 or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
							and (as_dateFrom is null or (as_dateFrom is not null and @dateFrom >= as_dateFrom))
							and (AS_DATETO is null or (AS_DATETO is not null and @dateFrom <= AS_DATETO)))
				begin
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
					values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
						return 
				end
				end
			end
		end


					
		--

		insert into @tmpQuotes
		select 
			qo_svkey,
			qo_code,
			isnull(qo_subcode1, 0) as qo_subcode1,
			isnull(qo_subcode2, 0) as qo_subcode2,
			isnull(qp_agentkey, 0) as qp_agentkey,
			isnull(qt_prkey, 0) as qt_prkey,
			isnull(qp_isnotcheckin, 0) as qp_isnotcheckin, 
			qd_release, 
			isnull(qp_places, 0) - isnull(qp_busy, 0),
			qd_date,
			qt_byroom,
			qd_type,
			isnull(ql_duration, 0) as ql_duration,
			isnull(qp_places, 0),
			(case when (isnull(ss_id, 0) > 0 and isnull(ss_isdeleted, 0) = 0) then 1 else 0 end) as qt_stop,
			qo_id as qt_qoid
		from quotas q with(nolock) inner join 
			quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
			left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
			right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid 
			left outer join StopSales ss with(nolock) on (qd_id = ss_qdid and isnull(ss_isdeleted, 0) = 0)
		where
			qo_svkey = @svkey
			--and isnull(QP_IsNotCheckin, 0) = 0
			and qo_code = @code
			and isnull(qo_subcode1, 0) in (0, @subcode1)
			and isnull(qo_subcode2, 0) in (0, @subcode2)
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
									and isnull(ss_prkey,0) = isnull(@partnerkey, 0)
									and isnull(ss_isdeleted, 0) = 0
									and qd.QD_Type = (SS_AllotmentAndCommitment + 1)
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
				qo_id as qt_qoid
			from StopSales
				inner join QuotaObjects on qo_id=ss_qoid
			where ((@days = 1 and ss_date = @dateFrom) or (@days > 1 and ss_date between @dateFrom and @dateTo))
					and ss_qdid is null
					and isnull(ss_isdeleted, 0) = 0
					and qo_svkey = @svkey
					and qo_code = @code
					and isnull(qo_subcode1, 0) in (0, @subcode1)
					and isnull(qo_subcode2, 0) in (0, @subcode2)
					and isnull(ss_prkey, 0)    in (0, @partnerkey)
		order by
			qd_date, qp_agentkey DESC, qd_type DESC, QT_PrKey DESC, qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC, qo_subcode2 DESC

--  declare  @hyt int
--select @hyt=count(*) from @tmpQuotes
--set @hyt = @hyt+1
--	insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
--		qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
--	values(0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, @hyt, 'asdfasdf')
--		return 


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
						and isnull(ss_prkey, 0) = isnull(@partnerkey, 0)
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
							 where qo.qo_svkey = qo1.qo_svkey and qo.qo_code = qo1.qo_code and qo1.qo_subcode1 in (qo.qo_subcode1, 0) and qo1.qo_subcode2 in (qo.qo_subcode2, 0) and qd_date = ss_date and qd_places > qd_busy and qd_type = 2 /*commitment*/)))
			begin
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
						values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
							return 
			end

		end

		if ( isnull((select min(qt_bycheckin)
					from @tmpQuotes
					where qt_date = @dateFrom), 1) = 1 AND @checkNoLongQuotes != @ALLDAYS_CHECK AND (SELECT CASE WHEN (SELECT COUNT(*) FROM @tmpQuotes) > 0 THEN 1 ELSE 0 END)=1)
		begin
			insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
								values(0, 0, 0, 0, 0, 0, 0, 0, case when @stopSale > 0 then 0 else @noPlacesResult end, 0, 0, 0)
								return
		end

		if isnull((select max(stopSale)
					from (	select min(qt_stop) as stopSale
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
		declare @prevSubCode1 int, @prevSubCode2 int, @prevQtType int
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

			declare @prevDate datetime, @dateRes int, @dateAllPlaces int, 
				@wasLongQuota smallint, @wasAgentQuota smallint, @checkAfterWasLong smallint, @checkAfterWasAgent smallint

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

			declare @quoteOnFirstDayExist smallint -- признак существования квоты на ПЕРВЫЙ день
				set @quoteOnFirstDayExist = 0

			while(@@fetch_status = 0)
			begin

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
						if(@dateRes <= 0 or @dateRes < @result)
						begin
							set @result = @dateRes
							set @allPlacesRes = @dateAllPlaces -- total places in quota

							if(@result = 0) -- no places
							begin
								close qCur
								deallocate qCur

								insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
								values(0, 0, 0, 0, 0, 0, 0, 0, case when @stopSale > 0 then 0 else @noPlacesResult end, 0, 0, 0)
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
		
--                        if (@bycheckinRes > 0 and @checkNoLongQuotes <> @ALLDAYS_CHECK)
--begin
--						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
--						-- MEG00024921, Danil, 10.02.2010: добавил значение qt_additional и его заполнение
--							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
--						values(0, 0, 0, 0, 0, 0, 0, 0, case when @stopSale > 0 then 0 else @noPlacesResult end, 0, 0, 0, 'break')
--							break
--end 

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

					if(@dateRes = 0 
						-- MEG00024921, Danil, 10.02.2010: это условие было странным образом закомментарено + добавлена проверка на qtStop.
						-- Привел логику в соответствие с версией хранимки для 2007.2, где в аналогичной ситуации все работает.
						-- Проверку на qtStop перенес в следующий if
						and (@stopSale <= 0 or ((@prevSubCode1 = @qtSubcode1 and @prevSubCode2 = @qtSubcode2) or @prevQtType <> @qtType)) 
						-- MEG00024921 End
						and not(@agentKey > 0 and @qtAgent = 0 and @wasAgentQuota > 0 and (@checkCommonQuotes <= 0))
								and not(@long > 0 and @qtLong = 0 and @wasLongQuota > 0 and (@checkNoLongQuotes <= 0)))
					begin
						if((@qtRelease is null or datediff(day, @currentDate, @qtDate) > isnull(@qtRelease, 0))
							-- MEG00024921, Danil, 10.02.2010: сюда перенес проверку на qtStop из условия выше (по аналогии с версией 2007.2)
							and isnull(@qtStop, 0) = 0)
							-- MEG00024921 End
						begin
							if((@requestOnRelease <= 0 or @qtRelease is null or @qtRelease > 0) and
								@qtPlaces > 0 and not(@stopSale > 0 and @wasAgentQuota > 0 /*request for agents if they have agent quota and this quota is stopped (they try to reserve general quota by low cost)*/))
							begin
								set @dateRes = @qtPlaces
								set @dateAllPlaces = @qtPlacesAll

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
				
				fetch next from qCur into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
					@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, @qtByroom, @qtType, 
					@qtLong, @qtPlacesAll, @qtStop, @qtQoId
			end

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
	end
	else
	begin
		set @partnerKey = -1 -- подбираем перелеты от разных партнеров
		if(isnull(@cityFrom, 0) <= 0 or isnull(@cityTo, 0) <= 0)
			select @cityFrom = ch_citykeyfrom, @cityTo = ch_citykeyto from charter with(nolock) where ch_key = @code
			
		set @dayOfWeek = datepart(dw, @dateFrom) - 1
		if(@dayOfWeek = 0)
			set @dayOfWeek = 7

		if @flightpkkey >= 0
		begin
			if not exists(select top 1 ch_key from charter with(nolock) inner join airseason with(nolock) on as_chkey = ch_key
				inner join tbl_costs with(nolock) on (cs_svkey = 1 and cs_code = ch_key and @dateFrom between cs_date and cs_dateend
					and cs_subcode1=@subcode1 and cs_pkkey = @flightpkkey)
				where ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo 
					and (AS_WEEK is null or len(as_week)=0 or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
					and @dateFrom between as_dateFrom and as_dateto)
			begin
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
					return 
			end

			insert into @tmpQuotes
			select distinct
				qo_svkey,
				qo_code,
				isnull(qo_subcode1, 0) as qo_subcode1,
				isnull(qo_subcode2, 0) as qo_subcode2,
				isnull(qp_agentkey, 0) as qp_agentkey,
				isnull(qt_prkey, 0) as qt_prkey,
				isnull(qp_isnotcheckin, 0) as qp_isnotcheckin, 
				qd_release as qt_release, 
				isnull(qp_places, 0) - isnull(qp_busy, 0),
				qd_date,
				qt_byroom,
				qd_type,
				isnull(ql_duration, 0) as ql_duration,
				isnull(qp_places, 0),
				(case when (isnull(ss_id, 0) > 0 and isnull(ss_isdeleted, 0) = 0) then 1 else 0 end) as qt_stop,
				qo_id as qt_qoid
			from quotas q with(nolock) inner join 
				quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
				left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
				right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid 
				left outer join StopSales ss with(nolock) on (qd_id = ss_qdid and isnull(ss_isdeleted, 0) = 0)
				 inner join charter on (qo_svkey = @svkey and ch_key = qo_code) inner join airseason on as_chkey = ch_key
			where
				exists (select top 1 cs_id from tbl_costs with(nolock)
					where cs_svkey=@svkey and cs_code=qo_code and cs_subcode1=@subcode1 
						and @dateFrom between cs_date and cs_dateend and cs_pkkey = @flightpkkey)
				and qo_svkey = @svkey
				and isnull(qo_subcode1, 0) in (0, @subcode1)
			--	and isnull(qo_subcode2, 0) in (0, @subcode2)
				and ((@checkAgentQuotes > 0 and @checkCommonQuotes > 0 and isnull(qp_agentkey, 0) in (0, @agentKey)) or
					(@checkAgentQuotes <= 0 and isnull(qp_agentkey, 0) = 0) or
					(@checkAgentQuotes > 0 and @checkCommonQuotes <= 0 and isnull(qp_agentkey, 0) in (0, @agentKey)))
				and (@partnerKey < 0 or isnull(qt_prkey, 0) in (0, @partnerKey))
				and qd_date = @dateFrom
				and ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo 
				and (AS_WEEK is null or len(as_week)=0 or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
				and @dateFrom between as_dateFrom and as_dateto
				and (@tourDuration < 0 or (@checkNoLongQuotes <> @ALLDAYS_CHECK and isnull(ql_duration, 0) in (0, @long)) or (@checkNoLongQuotes = @ALLDAYS_CHECK and isnull(ql_duration, 0) = @long))
			order by
				qd_date, qp_agentkey DESC, qd_type DESC, QT_PrKey DESC, qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC, qo_subcode2 DESC
		end
		else
		begin
			if not exists(select top 1 ch_key from charter with(nolock) inner join airseason with(nolock) on as_chkey = ch_key
				where ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo 
					and (AS_WEEK is null or len(as_week)=0 or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
					and @dateFrom between as_dateFrom and as_dateto)
			begin
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
					return 
			end

			insert into @tmpQuotes
			select distinct
				qo_svkey,
				qo_code,
				isnull(qo_subcode1, 0) as qo_subcode1,
				isnull(qo_subcode2, 0) as qo_subcode2,
				isnull(qp_agentkey, 0) as qp_agentkey,
				isnull(qt_prkey, 0) as qt_prkey,
				isnull(qp_isnotcheckin, 0) as qp_isnotcheckin, 
				qd_release, 
				isnull(qp_places, 0) - isnull(qp_busy, 0),
				qd_date,
				qt_byroom,
				qd_type,
				isnull(ql_duration, 0) as ql_duration,
				isnull(qp_places, 0),
				(case when (isnull(ss_id, 0) > 0 and isnull(ss_isdeleted, 0) = 0) then 1 else 0 end) as qt_stop,
				qo_id as qt_qoid
			from quotas q with(nolock) inner join 
				quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
				left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
				right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid 
				left outer join StopSales ss with(nolock) on (qd_id = ss_qdid and isnull(ss_isdeleted, 0) = 0)
				inner join charter with(nolock) on (qo_svkey = @svkey and ch_key = qo_code) inner join airseason with(nolock) on as_chkey = ch_key
			where
				qo_svkey = @svkey
				--and isnull(QP_IsNotCheckin, 0) = 0
				and isnull(qo_subcode1, 0) in (0, @subcode1)
			--	and isnull(qo_subcode2, 0) in (0, @subcode2)
				and 
				(	(@agentKey != -666
						and ((@checkAgentQuotes > 0 and @checkCommonQuotes > 0 and isnull(qp_agentkey, 0) in (0, @agentKey)) or
						(@checkAgentQuotes <= 0 and isnull(qp_agentkey, 0) = 0) or
						(@checkAgentQuotes > 0 and @checkCommonQuotes <= 0 and isnull(qp_agentkey, 0) in (0, @agentKey)))
					)
					or (@agentKey = -666 and qp_agentkey>0)
				)
				and (@partnerKey < 0 or isnull(qt_prkey, 0) in (0, @partnerKey))
				and qd_date = @dateFrom
				and ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo 
				and (AS_WEEK is null or len(as_week)=0 or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
				and @dateFrom between as_dateFrom and as_dateto
				and (@tourDuration < 0 or (@checkNoLongQuotes <> @ALLDAYS_CHECK and isnull(ql_duration, 0) in (0, @long)) or (@checkNoLongQuotes = @ALLDAYS_CHECK and isnull(ql_duration, 0) = @long))
			order by
				qd_date, qp_agentkey DESC, qd_type DESC, QT_PrKey DESC, qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC, qo_subcode2 DESC
		end

		update @tmpQuotes 
			set qt_stop = 1 
		from stopsales with(nolock) inner join quotaobjects qo with(nolock) on (ss_qoid = qo_id and ss_date = @dateFrom)
				where qt_svkey = qo.qo_svkey and qt_code = qo.qo_code 
					and isnull(qt_subcode1, 0) in (0, qo.qo_subcode1)
					and isnull(qt_subcode2, 0) in (0, qo.qo_subcode2)					
					and ss_qdid is null and isnull(ss_isdeleted, 0) = 0

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

		fetch next from qCur into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
			@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, @qtByroom, @qtType, 
			@qtLong, @qtPlacesAll, @qtStop, @qtQoId

		declare @prevCode int
		declare @wasAgent int
		declare @wasLong int		
		if(@@fetch_status = 0)
		begin
			set @result = 0
			set @stopSale = 1
			set @wasAgent = 0
			set @wasLong = 0
			while(@@fetch_status = 0)
			begin
				if((@wasLong > 0 and @qtLong = 0 and (@result <> 0 or @checkNoLongQuotes <= 0)) or (@wasAgent > 0 and @qtAgent = 0 and (@result <> 0 or @checkCommonQuotes <= 0)))
					break

				if(isnull(@qtStop, 0) = 0)
					set @stopSale = 0

				if(@qtLong > 0)
					set @wasLong = 1

				if(@qtAgent > 0)
					set @wasAgent = 1

				if(@qtPlaces > 0 and @qtPlaces > @result and isnull(@qtStop, 0) = 0)
				begin
					if(@qtRelease is null or datediff(day, @currentDate, @qtDate) > isnull(@qtRelease, 0))
					begin
							if(@requestOnRelease <= 0 or @qtRelease is null or @qtRelease > 0)
							begin
								set @result = @qtPlaces

								set @svkeyRes = @qtSvkey
								set @codeRes = @qtCode
								set @subcode1Res = @qtSubcode1
								set @subcode2Res = @qtSubcode2
								set @agentRes = @qtAgent
								set @prkeyRes = @qtPrkey
								set @bycheckinRes = 0
								set @byroomRes = @qtByroom
								set @typeRes = @qtType
								set @longRes = @qtLong
								set @allPlacesRes = @qtPlacesAll
								set @releaseRes = @qtRelease
							end
							else if(@result = 0)
								set @result = -1;
					end
					else
					begin if(@result = 0)
						set @result = @expiredReleaseResult
					end
				end
	
				fetch next from qCur into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
					@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, @qtByroom, @qtType, 
					@qtLong, @qtPlacesAll, @qtStop, @qtQoId
	
			end		

			if(@result = 0)
			begin
				if(@stopSale <= 0)
					set @result = @noPlacesResult
				else
					set @result = 0
			end
		end
		else
			set @result = -1
	end

	close qCur
	deallocate qCur

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
GO

GRANT SELECT ON [dbo].[mwCheckQuotesEx2] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwCheckQuotesEx2.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalculateCalendar.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[CalculateCalendar]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CalculateCalendar]
GO
CREATE PROCEDURE [dbo].[CalculateCalendar]
	(
		@calendarKey int,
		@dateFrom datetime = null,
		@dateEnd datetime = null
	)
AS
BEGIN
	-- установим чтобы неделя начиналась с понедельника
	SET DATEFIRST 1;
	-- если даты пришли пустыми то берем их из календаря
	if (@dateFrom is null)
	begin
		select @dateFrom = CL_DateFrom from Calendars where CL_Key = @calendarKey
	end
	if (@dateEnd is null)
	begin
		select @dateEnd = CL_DateTo from Calendars where CL_Key = @calendarKey
	end
	
	-- если даты на пересчет пришли больше чем сам календарь, то устанавливаем их по календарю
	select @dateFrom = CL_DateFrom from Calendars where CL_Key = @calendarKey and @dateFrom < CL_DateFrom
	select @dateEnd = CL_DateTo from Calendars where CL_Key = @calendarKey and @dateEnd > CL_DateTo

	declare @currentDate datetime, @newKey int
	set @currentDate = @dateFrom
	
	while (@currentDate <= @dateEnd)
	begin
		-- смотрим есть ли на этот день записи в календаре или в исключения
		if exists(select 1 
					from Schedules join CalendarWeekDays on SC_CalendarWeekDaysKey = CWD_Key
					where SC_CalendarKey = @calendarKey
					and DATEPART(weekday, @currentDate) = CWD_WeekDayNumber)
			or exists (	select 1
						from CalendarExclusions
						where CE_Date = @currentDate
						and CE_CalendarKey = @calendarKey)
		begin
			-- если запись есть, то вставляем запись, но сначала проверим, нету ли уже такой записи
			set @newKey = null
			select @newKey = CD_Key
			from CalendarDates
			where CD_Date = @currentDate
			and CD_CalendarKey = @calendarKey
			
			if (@newKey is null)
			begin
				insert into CalendarDates (CD_Date, CD_CalendarKey)
				values (@currentDate, @calendarKey)
				set @newKey = SCOPE_IDENTITY()
			end

			-- удалим записи из дат, если есть исключение
			-- для того чтобы не было 2 записей на 1 дату
			delete CalendarDateEvents
			from CalendarDateEvents join CalendarDates on CDE_CalendarDateKey = CD_Key
			where CD_Date = @currentDate
			and CD_CalendarKey = @calendarKey
			and exists (select 1 from CalendarExclusions where CD_Date = CE_Date and CD_CalendarKey = CE_CalendarKey)

			-- добавляем новые события из календаря
			insert into CalendarDateEvents (CDE_CalendarDateKey, CDE_CalendarEventTypeKey)
			select @newKey, SC_CalendarEventTypeKey
			from Schedules join CalendarWeekDays on SC_CalendarWeekDaysKey = CWD_Key
			where SC_CalendarKey = @calendarKey
			and DATEPART(weekday, @currentDate) = CWD_WeekDayNumber
			-- чтобы не было дубликатов
			and not exists (select 1 from CalendarDateEvents where CDE_CalendarDateKey = @newKey and CDE_CalendarEventTypeKey = SC_CalendarEventTypeKey)
			-- и если нету исключений на этот день
			and not exists (select 1 from CalendarExclusions join CalendarExclusionsEvent on CE_Key = CEE_CEKey where CE_Date = @currentDate and CE_CalendarKey = @calendarKey)
			
			-- добавляем новые события из исключений
			insert into CalendarDateEvents (CDE_CalendarDateKey, CDE_CalendarEventTypeKey)
			select @newKey, CEE_CETKey
			from CalendarExclusions join CalendarExclusionsEvent on CE_Key = CEE_CEKey
			where CE_Date = @currentDate and CE_CalendarKey = @calendarKey
			-- чтобы не было дубликатов
			and not exists (select 1 from CalendarDateEvents where CDE_CalendarDateKey = @newKey and CDE_CalendarEventTypeKey = CEE_CETKey)
			
			-- удаляем старые события
			delete CalendarDateEvents
			from CalendarDateEvents join CalendarDates on CD_Key = CDE_CalendarDateKey and CD_Date = @currentDate
			where not exists (	select 1 -- если нету таких событий в календарях
								from Schedules join CalendarWeekDays on SC_CalendarWeekDaysKey = CWD_Key
								where SC_CalendarKey = @calendarKey
								and DATEPART(weekday, @currentDate) = CWD_WeekDayNumber
								and CDE_CalendarDateKey = @newKey 
								and CDE_CalendarEventTypeKey = SC_CalendarEventTypeKey)
			and CDE_CalendarEventTypeKey not in (	select CEE_CETKey -- если нету таких событий в исключениях
													from CalendarExclusions join CalendarExclusionsEvent on CE_Key = CEE_CEKey
													where CE_Date = @currentDate 
													and CE_CalendarKey = @calendarKey) and CD_CalendarKey = @calendarKey
		end
		else -- иначе удаляем запись из CalendarDates
		begin
			-- сначала удалим события
			delete CalendarDateEvents
			where CDE_CalendarDateKey in (	select CD_Key
											from CalendarDates
											where CD_CalendarKey = @calendarKey
											and CD_Date = @currentDate)
		
			-- теперь удалим сами даты
			delete CalendarDates
			where CD_CalendarKey = @calendarKey
			and CD_Date = @currentDate
		end
		
		set @currentDate = dateadd(day, 1, @currentDate)
	end
	
	-- удалим записи которые находяться вне рамках календаря
	-- сначала удалим события
	delete CalendarDateEvents
	where CDE_CalendarDateKey in (	select CD_Key
									from CalendarDates join Calendars on CD_CalendarKey = CL_Key
									where CD_CalendarKey = @calendarKey
									and CD_Date not between CL_DateFrom and CL_DateTo)
	
	-- теперь удалим сами даты
	delete CalendarDates
	from CalendarDates join Calendars on CD_CalendarKey = CL_Key
	where CD_CalendarKey = @calendarKey
	and CD_Date not between CL_DateFrom and CL_DateTo
END
GO
grant exec on [dbo].[CalculateCalendar] to public
go
/*********************************************************************/
/* end sp_CalculateCalendar.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20111220_AlterTable_mwPriceDataTable.sql */
/*********************************************************************/
--<VERSION>ALL</VERSION>
--<DATE>2011-12-20</DATE>

-- script for change pt_key column's type of mwPriceDataTable table from int to bigint

declare @priceTableName as nvarchar(100)
set @priceTableName = 'mwPriceDataTable'

-- change data type for all price tables in case of splitting search tables
declare ptCur cursor for
	select tab.name from sys.tables tab
	where tab.name like 'mwPriceDataTable%'
	
open ptCur
fetch next from ptCur into @priceTableName

while @@FETCH_STATUS = 0
begin
	
	print 'changing ' + @priceTableName + ' table'

	-- Check pt_key data type
	if not exists	(
					select * from sys.columns col
					left join sys.tables tab on col.object_id = tab.object_id
					left join sys.types tp on col.system_type_id = tp.system_type_id
					where	col.name = 'pt_key' 
							and tab.name = @priceTableName
							and tp.name = 'bigint'
				)
	begin

		-- data type of pt_key is not bigint, change it

		-- get name of PK constraint
		declare @PKName as nvarchar(100)

		select @PKName = pk.name from sys.objects as pk
		left join sys.objects tab on pk.parent_object_id = tab.object_id
		where tab.name = @priceTableName and pk.type = 'PK'

		declare @script as nvarchar(max)
		set @script = 'BEGIN TRANSACTION'

		-- Drop PK constraint because it depends on pt_key column
		if (@PKName is not null)
		begin
			set @script = @script + '
			alter table ' + @priceTableName + ' drop constraint ' + @PKName
		end

		-- Alter pt_key column data type
		set @script = @script + ' 
		alter table ' + @priceTableName + ' alter column pt_key bigint'

		-- Create PK constraint
		if (@PKName is not null)
		begin
			set @script = @script + '
						ALTER TABLE ' + @priceTableName + ' ADD CONSTRAINT
								' + @PKName + ' PRIMARY KEY CLUSTERED 
								(
								pt_key
								) WITH( STATISTICS_NORECOMPUTE = OFF, 
								IGNORE_DUP_KEY = OFF, 
								ALLOW_ROW_LOCKS = ON, 
								ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
						  '
		end

		set @script = @script + '
		COMMIT TRANSACTION
		'
		
		begin try
			exec (@script)
		end try
		begin catch
			print 'error changing ' + @priceTableName + ' table'
		end catch
		
	end
	
	fetch next from ptCur into @priceTableName
end
close ptCur
deallocate ptCur

GO
/*********************************************************************/
/* end 20111220_AlterTable_mwPriceDataTable.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCreatePriceTable.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCreatePriceTable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[mwCreatePriceTable]
GO

CREATE PROCEDURE [dbo].[mwCreatePriceTable] @countryKey int, @cityFromKey int
as
begin
declare @sql varchar(8000)
declare @tableName varchar(1024)
set @tableName = dbo.mwGetPriceTableName(@countryKey, @cityFromKey)
set @sql = 
'CREATE TABLE ' + @tableName + ' (
		[pt_mainplaces] int,
		[pt_addplaces] int,
		[pt_main] smallint,
		[pt_tourvalid] datetime,
		[pt_tourcreated] datetime,
		[pt_tourdate] datetime,
		[pt_days] int,
		[pt_nights] int,
		[pt_cnkey]  int NOT NULL check(pt_cnkey = ' + cast(isnull(@countryKey, 0) as varchar) + '),
		[pt_ctkeyfrom] int NOT NULL  check(pt_ctkeyfrom = ' + cast(isnull(@cityFromKey, 0) as varchar) + '),
		[pt_apkeyfrom] int,
		[pt_ctkeyto] int,
		[pt_apkeyto] int,
		[pt_ctkeybackfrom] int,
		[pt_ctkeybackto] int,
		[pt_tourkey] int,
		[pt_tourtype] int,
		[pt_tlkey] int,
		[pt_pricelistkey] int null,
		[pt_pricekey] int,
		[pt_price] float,
		[pt_hdkey] int,
		[pt_hdpartnerkey] int,
		[pt_rskey] int,
		[pt_ctkey] int,
		[pt_hdstars] varchar(12),
		[pt_pnkey] int,
		[pt_hrkey] int,
		[pt_rmkey] int,
		[pt_rckey] int,
		[pt_ackey] int,
		[pt_childagefrom] int,
		[pt_childageto] int,
		[pt_childagefrom2] int,
		[pt_childageto2] int,
		[pt_hdname] varchar(60),
		[pt_tourname] varchar(128),
		[pt_pnname] varchar(30),
		[pt_pncode] varchar(30),
		[pt_rmname] varchar(35),
		[pt_rmcode] varchar(35),
		[pt_rcname] varchar(35),
		[pt_rccode] varchar(35),
		[pt_acname] varchar(30),
		[pt_accode] varchar(30),
		[pt_rsname] varchar(20),
		[pt_ctname] varchar(50),
		[pt_rmorder] int,
		[pt_rcorder] int,
		[pt_acorder] int,
		[pt_rate] varchar(3),
		[pt_toururl] varchar(128),
		[pt_hotelurl] varchar(254),
		[pt_isenabled] smallint,
		[pt_chkey] int,
		[pt_chbackkey] int,
		[pt_hdday] int,
		[pt_hdnights] int,
		[pt_chday] int,
		[pt_chpkkey] int,
		[pt_chprkey] int,
		[pt_chbackday] int,
		[pt_chbackpkkey] int,
		[pt_chbackprkey] int,
		pt_hotelkeys varchar(256),
		pt_hotelroomkeys varchar(256),
		pt_hotelstars varchar(256),
		pt_pansionkeys varchar(256),
		pt_hotelnights varchar(256),
		[pt_key] [bigint] IDENTITY PRIMARY KEY,		-- MEG00038762. Golubinsky. 20.12.2011. Увеличил тип до bigint
		pt_chdirectkeys varchar(256),
		pt_chbackkeys varchar(256),
		pt_topricefor smallint,
		pt_hash varchar(1024),
		pt_tlattribute int,
		pt_spo int,		
		pt_hddetails varchar(256),
		pt_AccmdType smallint,		
		pt_autodisabled smallint,
		pt_quotastatus smallint,
		pt_quotadetails smallint)'
exec(@sql)
set @sql='grant select, delete, update, insert on '+@tableName+' to public'
exec(@sql)
end
GO
/*********************************************************************/
/* end sp_mwCreatePriceTable.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_Paging.sql */
/*********************************************************************/
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
@checkAllPartnersQuota smallint = null,
@calculateVisaDeadLine smallint = 0
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
			price_correction int,
			findFlight smallint
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
	
		set @sql=@sql + ' pt_key,pt_tourkey '
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


	if(@getServices > 0)
		set @sql=@sql + ',dbo.mwGetServiceClasses(pt_pricelistkey) pt_srvClasses'
	if(@hotelQuotaMask > 0)
		set @sql=@sql + ',pt_hdquota,pt_hdallquota '
	if(@aviaQuotaMask > 0)
		set @sql=@sql + ',pt_chtherequota,pt_chbackquota '
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
go

grant exec on dbo.Paging to public
go
/*********************************************************************/
/* end sp_Paging.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20111221_AlterTable_WebServiceLog.sql */
/*********************************************************************/
--<VERSION>ALL</VERSION>
--<DATE>2012-01-26</DATE>

IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'webservicelog')  
      create table dbo.Webservicelog (name nvarchar(50), date datetime  DEFAULT  GETDATE(), host nvarchar(15),Duration float,Params nvarchar(1024))
IF NOT EXISTS(SELECT id FROM syscolumns WHERE id = OBJECT_ID('webservicelog') AND name = 'UserName')
      ALTER TABLE dbo.Webservicelog ADD UserName nvarchar(60) NULL

GRANT INSERT ON [dbo].[Webservicelog] TO [public]
GO
GRANT REFERENCES ON [dbo].[Webservicelog] TO [public]
GO
GRANT SELECT ON [dbo].[Webservicelog] TO [public]
GO
GRANT UPDATE ON [dbo].[Webservicelog] TO [public]
GO
GRANT DELETE ON [dbo].[Webservicelog] TO [public]
GO
GRANT VIEW DEFINITION ON [dbo].[Webservicelog] TO [public]
GO

-- if webservicelog table exists in non-dbo schema,
-- then create same table in dbo schema, fill data to it and drop
-- non-dbo schema table
IF EXISTS(SELECT * 
			FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'webservicelog'
				AND TABLE_SCHEMA <> 'dbo')
BEGIN

	print 'webservicelog processing...'

	declare @otherSchema as nvarchar(50)
	SELECT top 1 @otherSchema = TABLE_SCHEMA 
			FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'webservicelog'
				AND TABLE_SCHEMA <> 'dbo'
				
	declare @sql as nvarchar(max)
	set @sql = '
				INSERT INTO dbo.webservicelog 
				SELECT * from ' + @otherSchema + '.webservicelog 
				'
	
	set @sql = @sql + '
				DROP TABLE ' + @otherSchema + '.webservicelog 
				'
	
	exec (@sql)
	
	print 'webservicelog processing complete'

END 

GO
/*********************************************************************/
/* end 20111221_AlterTable_WebServiceLog.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 2011.12.22_Insert_SystemSettings.sql */
/*********************************************************************/
if not exists (select 1 from SystemSettings where SS_ParmName = 'SYSPayerPartnersSelection')
insert into SystemSettings (SS_ParmName,SS_ParmValue) values ('SYSPayerPartnersSelection','1')
go 
/*********************************************************************/
/* end 2011.12.22_Insert_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_DogovorListUpdate.sql */
/*********************************************************************/
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
			END
			
			If (ISNULL(@ODL_Name, 0) != ISNULL(@NDL_Name, 0))
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1050, @ODL_Name, @NDL_Name, null, null, null, null, 0, @bNeedCommunicationUpdate output
			If (ISNULL(@ODL_RealNetto, 0) != ISNULL(@NDL_RealNetto, 0))
			BEGIN
				Set @sText_Old = left(convert(varchar, @ODL_RealNetto), 10)
				Set @sText_New = left(convert(varchar, @NDL_RealNetto), 10)				
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
/*********************************************************************/
/* end T_DogovorListUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.01.23)_Drop_table_PartnersNetworks.sql */
/*********************************************************************/

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FX_PR_PNKEY]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_Partners]'))
ALTER TABLE [dbo].[tbl_Partners] DROP CONSTRAINT [FX_PR_PNKEY]
GO

IF  EXISTS (SELECT * FROM sys.columns c WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Partners]') AND name = N'PR_PNKEY')
ALTER TABLE [dbo].[tbl_Partners] DROP COLUMN PR_PNKEY
go

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FX_PN_MAINPRID]') AND parent_object_id = OBJECT_ID(N'[dbo].[PartnersNetworks]'))
ALTER TABLE [dbo].[PartnersNetworks] DROP CONSTRAINT [FX_PN_MAINPRID]
GO


GO

/****** Object:  Table [dbo].[PartnersNetworks]    Script Date: 01/23/2012 16:24:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PartnersNetworks]') AND type in (N'U'))
DROP TABLE [dbo].[PartnersNetworks]
GO

sp_RefreshViewForAll 'Partners'
GO
/*********************************************************************/
/* end (2012.01.23)_Drop_table_PartnersNetworks.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (110510)NewAction.sql */
/*********************************************************************/
if not exists (select 1 from Actions where AC_Key = 74)
	insert into Actions (AC_Key, AC_Name, AC_NameLat) values (74, 'Разрешить работу с надстройкой "График работы консульств"', 'Allow work to add "Schedule Consulates"')
else 
	print 'Обратитесь в службу поддержки, Actions с номером 74 занят'
go

update Actions 
set AC_Name = 'Разрешить работу с надстройкой "График работы консульств"'
where AC_Name = 'Разрешить работь с надстройкой "График работы консульств"'

go

if not exists (select 1 from Actions where AC_Key = 75)
begin
	insert into Actions (AC_Key, AC_Name, AC_NameLat)
	values (75, 'Разрешить создавать путевку на прошлую дату', 'Allow to create a ticket to the last date')
end
else
begin
	print 'Обратитесь в службу поддержки, Actions с номером 75 занят'
end
go
/*********************************************************************/
/* end (110510)NewAction.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.01.19)_x_Quota_indexes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_QO_web_1')
     DROP INDEX QuotaObjects.x_QO_web_1
GO
CREATE NONCLUSTERED INDEX [x_QO_web_1] ON [dbo].[QuotaObjects] 
(
	[QO_SVKey] ASC,
	[QO_Code] ASC
)
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_SS_web_1')
     DROP INDEX StopSales.x_SS_web_1
GO
CREATE NONCLUSTERED INDEX [x_SS_web_1] ON [dbo].[StopSales] 
(
	[SS_QDID] ASC,
	[SS_Date] ASC,
	[SS_ID] ASC,
	[SS_QOID] ASC
)
INCLUDE ( [SS_IsDeleted])
GO
/*********************************************************************/
/* end (2012.01.19)_x_Quota_indexes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 111017_Insert_Actions.sql */
/*********************************************************************/
IF NOT EXISTS (select 1 from actions where AC_Key = 83)
BEGIN
	insert Actions (AC_Key, AC_Name, AC_NameLat)
	VALUES(83, 'Разрешить управление правами доступа к ПДН','Allow manage access to TPD')
END
GO
/*********************************************************************/
/* end 111017_Insert_Actions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 111116(new_mwIndexes).sql */
/*********************************************************************/
--<VERSION>2009.1</VERSION>
--<DATE>2011-11-16</DATE>

IF  EXISTS (SELECT * FROM dbo.sysindexes WHERE id = OBJECT_ID(N'[dbo].[mwSpoDataTable]') AND name = N'x_main')
	DROP INDEX [dbo].[mwSpoDataTable].[x_main]
GO

CREATE NONCLUSTERED INDEX [x_main] ON [dbo].[mwSpoDataTable] 
(
	[sd_cnkey] ASC,
	[sd_ctkeyfrom] ASC,
	[sd_tourtype] ASC,
	sd_rskey,
	[sd_ctkey] ASC,
	[sd_tourkey] ASC
)
INCLUDE ( [sd_hdkey], sd_isenabled, sd_tourvalid) WITH (FILLFACTOR = 70) ON [PRIMARY]
go

IF  EXISTS (SELECT * FROM dbo.sysindexes WHERE id = OBJECT_ID(N'[dbo].[mwPriceDataTable]') AND name = N'x_main_roomprice')
	DROP INDEX [dbo].[mwPriceDataTable].[x_main_roomprice]
GO

CREATE NONCLUSTERED INDEX [x_main_roomprice] ON [dbo].[mwPriceDataTable] 
(
	[pt_ctkeyfrom] ASC,
	[pt_cnkey] ASC,
	[pt_mainplaces] ASC,
	[pt_addplaces] ASC,
	[pt_tourdate] ASC,
	[pt_tourtype] ASC,
	[pt_rskey] ASC,
	[pt_ctkey] ASC,
	[pt_tourkey] ASC,
	[pt_nights] ASC,
	[pt_pnkey] ASC,
	[pt_hdstars] ASC
)
INCLUDE ( [pt_tlkey],
[pt_hdkey],
[pt_pricekey],
[pt_price],
[pt_rmkey],
[pt_rckey],
[pt_days],
[pt_isenabled],
[pt_hdname],
[pt_rcname],
[pt_rccode],
[pt_chkey],
[pt_chbackkey],
[pt_hdday],
[pt_hdnights],
[pt_hdpartnerkey],
[pt_chday],
[pt_chpkkey],
[pt_chprkey],
[pt_chbackday],
[pt_chbackpkkey],
[pt_chbackprkey],
[pt_childagefrom],
[pt_childageto],
[pt_childagefrom2],
[pt_childageto2],
[pt_main],
[pt_tourvalid],
[pt_chbackkeys],
[pt_chdirectkeys],
[pt_hddetails],
[pt_topricefor]) WITH (FILLFACTOR = 70) ON [PRIMARY]
go

IF  EXISTS (SELECT * FROM dbo.sysindexes WHERE id = OBJECT_ID(N'[dbo].[mwPriceDataTable]') AND name = N'x_main_persprice')
	DROP INDEX [dbo].[mwPriceDataTable].[x_main_persprice]
GO

CREATE NONCLUSTERED INDEX [x_main_persprice] ON [dbo].[mwPriceDataTable] 
(
	[pt_ctkeyfrom] ASC,
	[pt_cnkey] ASC,
	[pt_tourdate] ASC,
	[pt_tourtype] ASC,
	[pt_rskey] ASC,
	[pt_ctkey] ASC,
	[pt_tourkey] ASC,
	[pt_nights] ASC,
	[pt_pnkey] ASC,
	[pt_hdstars] ASC
)
INCLUDE ( [pt_tlkey],
[pt_hdkey],
[pt_pricekey],
[pt_price],
[pt_rmkey],
[pt_rckey],
[pt_days],
[pt_isenabled],
[pt_hdname],
[pt_rcname],
[pt_rccode],
[pt_chkey],
[pt_chbackkey],
[pt_hdday],
[pt_hdnights],
[pt_hdpartnerkey],
[pt_chday],
[pt_chpkkey],
[pt_chprkey],
[pt_chbackday],
[pt_chbackpkkey],
[pt_chbackprkey],
[pt_childagefrom],
[pt_childageto],
[pt_childagefrom2],
[pt_childageto2],
[pt_main],
[pt_tourvalid],
[pt_chbackkeys],
[pt_chdirectkeys],
[pt_hddetails],
[pt_topricefor]) WITH (FILLFACTOR = 70) ON [PRIMARY]
go

IF  EXISTS (SELECT * FROM dbo.sysindexes WHERE id = OBJECT_ID(N'[dbo].[mwPriceHotels]') AND name = N'x_sdkey_rmkey')
	DROP INDEX [dbo].[mwPriceHotels].[x_sdkey_rmkey]
GO

CREATE NONCLUSTERED INDEX [x_sdkey_rmkey] ON [dbo].[mwPriceHotels] 
(
	[ph_sdkey] ASC
)
INCLUDE ( [sd_rmkey]) WITH (FILLFACTOR=70) ON [PRIMARY]
go

IF  EXISTS (SELECT * FROM dbo.sysindexes WHERE id = OBJECT_ID(N'[dbo].[mwPriceDataTable]') AND name = N'x_complex')
	DROP INDEX [dbo].[mwPriceDataTable].[x_complex]
GO

CREATE NONCLUSTERED INDEX [x_complex] ON [dbo].[mwPriceDataTable] 
(
     [pt_cnkey] ASC,
     [pt_ctkeyfrom] ASC,
     [pt_tourkey] ASC,
     [pt_tourdate] ASC
)
INCLUDE ( [pt_hdkey],
[pt_pnkey]) WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

/*********************************************************************/
/* end 111116(new_mwIndexes).sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20111212_AlterProcedure_mwReplDisableDeletedPrices.sql */
/*********************************************************************/
if exists (select 1 from dbo.sysobjects where id = object_id(N'[dbo].[mwReplDisableDeletedPrices]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[mwReplDisableDeletedPrices];
go

create proc [dbo].[mwReplDisableDeletedPrices]
as
begin
	--<DATE>2011-12-12</DATE>
	--<VERSION>9.2.10.3</VERSION>

	select * into #mwReplDeletedPricesTemp from dbo.mwReplDeletedPricesTemp with(nolock);
	create index x_pricekey on #mwReplDeletedPricesTemp(rdp_pricekey);
	
	delete from dbo.mwReplDeletedPricesTemp with(rowlock)
	where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = mwReplDeletedPricesTemp.rdp_pricekey);
	
	if dbo.mwReplIsPublisher() > 0 
	begin
		declare @sql varchar (500);
		declare @source varchar(200);
		set @source = '';
		
		if len(dbo.mwReplSubscriberDB()) > 0
			set @source = '[mw].[' + dbo.mwReplSubscriberDB() + '].';

		if exists(select 1 from #mwReplDeletedPricesTemp)
		begin
			set @sql = '
			insert into ' + @source + 'dbo.mwReplDeletedPricesTemp with(rowlock) (rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey)
			select rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey from #mwReplDeletedPricesTemp';
			
			exec (@sql);
		end
	end
	else if dbo.mwReplIsSubscriber() > 0
	begin
		if exists(select 1 from #mwReplDeletedPricesTemp)
		begin
			insert into dbo.mwDeleted with(rowlock) (del_key)
			select rdp_pricekey from #mwReplDeletedPricesTemp;
			
			if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
			begin
				--Используется секционирование ценовых таблиц			
				declare mwPriceDataTableNameCursor cursor for
					select distinct dbo.mwGetPriceTableName(rdp_cnkey, rdp_ctdeparturekey) as ptn_tablename
					from
						#mwReplDeletedPricesTemp with(nolock);
					
				declare @mwPriceDataTableName varchar(200);
				open mwPriceDataTableNameCursor;
				fetch next from mwPriceDataTableNameCursor 
				into @mwPriceDataTableName;

				while @@FETCH_STATUS = 0
					begin
					if exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].[' + @mwPriceDataTableName + ']') AND type in (N'U'))
						begin
						set @sql='
							update [dbo].[' + @mwPriceDataTableName + '] with(rowlock)
							set pt_isenabled = 0
							where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey)';
							
							exec (@sql);
							fetch next from mwPriceDataTableNameCursor 
						end
					end
				close mwPriceDataTableNameCursor;
				deallocate mwPriceDataTableNameCursor;
			end
			else
			begin
				--Секционирование не используется
				update dbo.mwPriceDataTable with(rowlock)
				set pt_isenabled = 0
				where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey);
			end
		end
	end
	
	drop index x_pricekey on #mwReplDeletedPricesTemp;
	drop table #mwReplDeletedPricesTemp;
end
go

grant exec on [dbo].[mwReplDisableDeletedPrices] to public
go
/*********************************************************************/
/* end 20111212_AlterProcedure_mwReplDisableDeletedPrices.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20111212_AlterTable_mwReplDeletedPricesTemp.sql */
/*********************************************************************/
--<DATE>2011-12-12</DATE>
--<VERSION>9.2.10.3</VERSION>
	
if not exists(select id from syscolumns where id = OBJECT_ID('mwReplDeletedPricesTemp') and name = 'rdp_cnkey')
	alter table mwReplDeletedPricesTemp add rdp_cnkey int null
go

if not exists(select id from syscolumns where id = OBJECT_ID('mwReplDeletedPricesTemp') and name = 'rdp_ctdeparturekey')
	alter table mwReplDeletedPricesTemp add rdp_ctdeparturekey int null
go
/*********************************************************************/
/* end 20111212_AlterTable_mwReplDeletedPricesTemp.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20111212_AlterTrigger_mwDeleteTour.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwDeleteTour]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[mwDeleteTour]
go

CREATE trigger [dbo].[mwDeleteTour] on [dbo].[TP_Tours]
for delete
as
begin
	--<DATE>2011-12-12</DATE>
	--<VERSION>9.2.10.3</VERSION>
	if dbo.mwReplIsSubscriber() <= 0
	begin
		return;
	end

	declare @tableName nvarchar(100), @sql nvarchar(4000), @tokey int
	if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
	begin
		--Используется секционирование ценовых таблиц
		declare disableCursor cursor fast_forward read_only for
		select 
			to_key, dbo.mwGetPriceTableName(to_cnkey, tl_ctdeparturekey)
		from 
			deleted inner join tbl_turlist with(nolock) on to_trkey = tl_key

		open disableCursor
		fetch next from disableCursor into @tokey, @tableName
		
		while @@fetch_status = 0
		begin
			if(@tableName is not null and len(@tableName) > 0)
			begin
				set @sql = 'insert into mwDeleted with(rowlock) (del_key) select pt_pricekey from ' + @tableName + ' with(nolock) where pt_tourkey = ' + ltrim(str(@tokey)) + '
							update ' + @tableName + ' with(rowlock) set pt_isenabled = 0 where pt_isenabled > 0 and pt_tourkey = ' + ltrim(str(@tokey)) + '
							update mwSpoDataTable with(rowlock) set sd_isenabled = 0 where sd_isenabled > 0 and sd_tourkey = ' + ltrim(str(@tokey))
				exec (@sql)
			end

			delete from TP_Prices with(rowlock) where tp_tokey = @tokey
			delete from TP_ServiceLists with(rowlock) where tl_tokey = @tokey
			delete from TP_Services with(rowlock) where ts_tokey = @tokey
			delete from TP_Lists with(rowlock) where ti_tokey = @tokey

			fetch next from disableCursor into @tokey, @tableName
		end
		
		close disableCursor
		deallocate disableCursor
	end
	else
	begin
		--Секционирование ценовых таблиц НЕ используется
		set @tableName = 'dbo.mwPriceDataTable'
		declare disableCursor cursor fast_forward read_only for
		select 
			to_key
		from 
			deleted 

		open disableCursor
		
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

			delete from TP_Prices with(rowlock) where tp_tokey = @tokey
			delete from TP_ServiceLists with(rowlock) where tl_tokey = @tokey
			delete from TP_Services with(rowlock) where ts_tokey = @tokey
			delete from TP_Lists with(rowlock) where ti_tokey = @tokey

			fetch next from disableCursor into @tokey
		end
		
		close disableCursor
		deallocate disableCursor
	end
end
GO



/*********************************************************************/
/* end 20111212_AlterTrigger_mwDeleteTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20111212_AlterTrigger_mwReplDeletePrice.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwReplDeletePrice]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[mwReplDeletePrice]
GO

create trigger [dbo].[mwReplDeletePrice] on [dbo].[TP_Prices] for delete as
begin
	--<DATE>2011-12-12</DATE>
	--<VERSION>9.2.10.3</VERSION>
	
	if dbo.mwReplIsPublisher() > 0
	begin
		if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
			begin
			insert into dbo.mwReplDeletedPricesTemp with(rowlock) (rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey) select tp_key, to_cnkey, tl_ctdeparturekey from deleted inner join 
							TP_Tours with(nolock) on TP_TOKey=TO_Key inner join
							tbl_TurList with(nolock) on TL_KEY = TO_TRKey;
			end
		else
			begin
			insert into dbo.mwReplDeletedPricesTemp with(rowlock) (rdp_pricekey) select tp_key from deleted
			end
	end
end
GO



/*********************************************************************/
/* end 20111212_AlterTrigger_mwReplDeletePrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20111219_AlterTrigger_UpdDogListQuota.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_UpdDogListQuota]'))
DROP TRIGGER [dbo].[T_UpdDogListQuota]
GO

CREATE TRIGGER [dbo].[T_UpdDogListQuota] 
ON [dbo].[tbl_DogovorList]
AFTER INSERT, UPDATE, DELETE
AS
--<VERSION>2009.2.10.4</VERSION>
--<DATE>2011-12-19</DATE>
-- inserting into roomnumberlists , servicebydate
DECLARE @DLKey int, @DGKey int, @O_DLSVKey int, @O_DLCode int, @O_DLSubcode1 int, @O_DLDateBeg datetime, @O_DLDateEnd datetime, @O_DLNMen int, @O_DLPartnerKey int, @O_DLControl int, 
		@N_DLSVKey int, @N_DLCode int, @N_DLSubcode1 int, @N_DLDateBeg datetime, @N_DLDateEnd datetime, @N_DLNMen int, @N_DLPartnerKey int, @N_DLControl int,
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

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED
SET @SetToNewQuota = 0
IF (@nInsCount = 0)
BEGIN
    DECLARE cur_DogovorListChanged2 CURSOR FOR 
    SELECT 	O.DL_Key, O.DL_DGKey,
			O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_DateBeg, O.DL_DateEnd, O.DL_NMen, O.DL_PartnerKey, O.DL_Control, 
			null, null, null, null, null, null, null, null
    FROM DELETED O
	SET @Mod = 'DEL'
END
ELSE IF (@nDelCount = 0)
BEGIN
    DECLARE cur_DogovorListChanged2 CURSOR FOR 
    SELECT 	N.DL_Key, N.DL_DGKey,
			null, null, null, null, null, null, null, null,
			N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_DateBeg, N.DL_DateEnd, N.DL_NMen, N.DL_PartnerKey, N.DL_Control
    FROM	INSERTED N 
	SET @Mod = 'INS'
END
ELSE 
BEGIN
    DECLARE cur_DogovorListChanged2 CURSOR FOR 
    SELECT 	N.DL_Key, N.DL_DGKey, 
			O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_DateBeg, O.DL_DateEnd, O.DL_NMen, O.DL_PartnerKey, O.DL_Control, 
			N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_DateBeg, N.DL_DateEnd, N.DL_NMen, N.DL_PartnerKey, N.DL_Control
    FROM DELETED O, INSERTED N 
    WHERE N.DL_Key = O.DL_Key
	SET @Mod = 'UPD'
END

OPEN cur_DogovorListChanged2
FETCH NEXT FROM cur_DogovorListChanged2 
	INTO	@DLKey, @DGKey,
			@O_DLSVKey, @O_DLCode, @O_DLSubCode1, @O_DLDateBeg, @O_DLDateEnd, @O_DLNMen, @O_DLPartnerKey, @O_DLControl, 
			@N_DLSVKey, @N_DLCode, @N_DLSubCode1, @N_DLDateBeg, @N_DLDateEnd, @N_DLNMen, @N_DLPartnerKey, @N_DLControl
WHILE @@FETCH_STATUS = 0
BEGIN

	SELECT @SVQUOTED=isnull(SV_Quoted,0) from service where sv_key=@N_DLSVKey

	EXEC InsMasterEvent 3, @DLKey
	IF ((@O_DLSVKey in (3,7)) and ((@N_DLCode!=@O_DLCode) or (@N_DLSubCode1!=@O_DLSubCode1) or (@O_DLDateBeg!=@N_DLDateBeg) or (@O_DLDateEnd!=@N_DLDateEnd)))
		or ((@O_DLSVKey in (1,2,4)) and (@O_DLDateBeg!=@N_DLDateBeg))
		update turistservice set tu_numroom='' where tu_dlkey=@DLKey

	IF @N_DLDateBeg < '01-JAN-1901' and @O_DLDateBeg >= '01-JAN-1901'
		SET @Mod='DEL'
	IF @N_DLDateBeg > '01-JAN-1901' and @O_DLDateBeg <= '01-JAN-1901'
		SET @SetToNewQuota=1
		--SET @Mod='INS'
		/*select @rlid=sd_rlid from servicebydate where sd_dlkey=@dlkey
		delete from roomnumberlists where rl_id=@rlid
		delete from servicebydate where sd_dlkey=@dlkey*/
	IF @Mod='UPD' and ISNULL(@O_DLNMen,0)=0 and ISNULL(@N_DLNMen,0)>0
		SET @Mod='INS'
	IF @Mod='DEL' or (@Mod='UPD' and 
		(ISNULL(@O_DLSVKey,0) != ISNULL(@N_DLSVKey,0)) or (ISNULL(@O_DLCode,0) != ISNULL(@N_DLCode,0)) 
		or (ISNULL(@O_DLSubCode1,0) != ISNULL(@N_DLSubCode1,0)) or (ISNULL(@O_DLPartnerKey,0) != ISNULL(@N_DLPartnerKey,0)) )
	BEGIN	
		DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey
		SET @SetToNewQuota=1
	END

	--изменился период действия услуги
	IF @Mod='UPD' and (@SetToNewQuota!=1 and ((@O_DLDateBeg != @N_DLDateBeg) or (@O_DLDateEnd != @N_DLDateEnd)))
	BEGIN
		IF @N_DLDateBeg>@O_DLDateEnd OR @N_DLDateEnd<@O_DLDateBeg
		BEGIN
			DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey
			SET @SetToNewQuota=1
		END
		ELSE --для услуг имеющих продолжительность сохраняем информацию о квотировании в рамках периода
		BEGIN
			--если теперь услуга заканчивается раньше, чем до этого начиналась
			IF @N_DLDateBeg < @O_DLDateBeg
			BEGIN
				IF @N_DLDateEnd<@O_DLDateBeg
					Set @Days=DATEDIFF(DAY,@N_DLDateBeg,@N_DLDateEnd)+1
				ELSE
					Set @Days=DATEDIFF(DAY,@N_DLDateBeg,@O_DLDateBeg)
					
				INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, SD_State)
				SELECT DATEADD(DAY,NU_ID-1,@N_DLDateBeg), SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, @SVQUOTED + 3 
				FROM ServiceByDate, Numbers
				WHERE (NU_ID between 1 and @Days) and SD_Date=@O_DLDateBeg and SD_DLKey=@DLKey
			END
			
			--если теперь услуга начинается позже, чем до этого заканчивалась
			IF @N_DLDateEnd > @O_DLDateEnd
			BEGIN
				IF @N_DLDateBeg>@O_DLDateEnd
					Set @Days=DATEDIFF(DAY,@N_DLDateBeg,@N_DLDateEnd)+1
				ELSE
					Set @Days=DATEDIFF(DAY,@O_DLDateEnd,@N_DLDateEnd)
					
				INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, SD_State)
				SELECT DATEADD(DAY,-NU_ID+1,@N_DLDateEnd), SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, @SVQUOTED + 3 
				FROM ServiceByDate, Numbers
				WHERE (NU_ID between 1 and @Days) and SD_Date=@O_DLDateEnd and SD_DLKey=@DLKey
			END
			
			
			IF @N_DLDateBeg>@O_DLDateBeg
				DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_Date < @N_DLDateBeg
			IF @N_DLDateEnd<@O_DLDateEnd
				DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_Date > @N_DLDateEnd
		END
		
		-- если эта услуга на продолжительность
		if exists (select 1 from [Service] where SV_Key = @N_DLSVKey and isnull(SV_IsDuration,0) = 1)
		and exists(select 1 -- если услуга сидела на квоте с продолжительностью
						from ServiceByDate 
						where SD_DLKey = @DLKey 
						and exists (select 1 
									from QuotaParts
									where QP_ID = SD_QPID
									and QP_Durations is not null))
		begin
			--то пересаживаем всю услугу
			EXEC DogListToQuotas @DLKey, null, null, null, null, @N_DLDateBeg, @N_DLDateEnd, null, null
		end
	END
	SET @NeedPlacesForMen=0
	SET @From = CAST(@N_DLDateBeg as int)
	--изменилось количество человек
	IF @Mod='UPD' and (@SetToNewQuota!=1 and ISNULL(@O_DLNMen,0) != ISNULL(@N_DLNMen,0))
	BEGIN
		SET @NeedPlacesForMen=ISNULL(@N_DLNMen,0)-ISNULL(@O_DLNMen,0)
		if ISNULL(@O_DLNMen,0) > ISNULL(@N_DLNMen,0)
		BEGIN
			while (SELECT count(1) FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_Date=@N_DLDateBeg)>ISNULL(@N_DLNMen,0)
			BEGIN
				if @N_DLSVKey=3 --для проживания отдельная ветка
				BEGIN
					SELECT TOP 1 @RLID=SD_RLID, @RPCount=count(SD_ID) FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_TUKey is null and SD_Date=@N_DLDateBeg
					GROUP BY SD_RLID
					ORDER BY 2
					--SELECT @RLID=SDRLID, @RPCount=SDIDcount
					--FROM
					--( 
					--	SELECT TOP 1 SD_RLID SDRLID, count(SD_ID) SDIDcount
					--	FROM ServiceByDate 
					--	WHERE SD_DLKey=@DLKey and SD_TUKey is null and SD_Date=@N_DLDateBeg
					--	GROUP BY SD_RLID
					--	ORDER BY 2
					--) AS QUERY
					SELECT TOP 1 @RPID=SD_RPID FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_RLID=@RLID and SD_TUKey is null
					DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_RLID=@RLID and SD_RPID=@RPID and SD_TUKey is null
				END
				ELSE
				BEGIN
					-- MEG00039209 Gorshkov 16.12.2011 Убрал условие SD_TUKey is null т.к. при удалении туриста из QuotaBlocks приводило
					-- к бесконечному циклу т.к. SD_TUKey в ServiceByDate задан
					SELECT TOP 1 @RPID=SD_RPID FROM ServiceByDate WHERE SD_DLKey=@DLKey-- and SD_TUKey is null
					DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_RPID=@RPID-- and SD_TUKey is null
				END
			END
		END
		ELSE --если новое число туристов больше, чем было до этого (@O_DLNMen<@N_DLNMen)
		BEGIN
			if @N_DLSVKey=3 --для проживания отдельная ветка
			BEGIN				
				SELECT	@HRIsMain=AC_MAIN, @ACPlacesMain=ISNULL(AC_NRealPlaces,0), @ACPlacesEx=ISNULL(AC_NMenExBed,0), @ACPerRoom=ISNULL(AC_PerRoom,0)
				FROM AccmdMenType
				WHERE AC_Key=(SELECT HR_ACKey From HotelRooms WHERE HR_Key=@N_DLSubCode1)
				IF @HRIsMain = 1 and @ACPlacesMain = 0 and @ACPlacesEx = 0
					set @ACPlacesMain = 1
				ELSE IF @HRIsMain = 0 and @ACPlacesMain = 0 and @ACPlacesEx = 0
					set @ACPlacesEx = 1
				--есть 3 варианта размещения: только основные, только дополнительные, основные и дополнительные
				--в первых 2-х вариантах сначала занимаем свободные уже существующие места данного типа в номерах этой услуги, в последнем занимаем все свободные места
				if @ACPlacesMain>0
					WHILE (@NeedPlacesForMen>0 and EXISTS(select RP_ID FROM RoomPlaces where RP_RLID in (SELECT SD_RLID FROM ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM ServicebyDate where SD_DLKey=@DLKey) and RP_Type=0))
					BEGIN
						select TOP 1 @RPID=RP_ID,@RLID=RP_RLID FROM RoomPlaces where RP_RLID in (SELECT SD_RLID FROM ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM ServicebyDate where SD_DLKey=@DLKey) and RP_Type=0
						INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_State)	
							SELECT CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RLID, @RPID, 4
							FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@N_DLDateEnd as int)-@From+1
						SET @NeedPlacesForMen=@NeedPlacesForMen-1
					END
				if @ACPlacesEx>0
					WHILE (@NeedPlacesForMen>0 and EXISTS(select RP_ID FROM RoomPlaces where RP_RLID in (SELECT SD_RLID FROM ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM ServicebyDate where SD_DLKey=@DLKey) and RP_Type=1))
					BEGIN
						select TOP 1 @RPID=RP_ID,@RLID=RP_RLID FROM RoomPlaces where RP_RLID in (SELECT SD_RLID FROM ServicebyDate where SD_DLKey=@DLKey) and RP_ID not in (SELECT SD_RPID FROM ServicebyDate where SD_DLKey=@DLKey) and RP_Type=1
						INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_State)	
							SELECT CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RLID, @RPID, 4
							FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@N_DLDateEnd as int)-@From+1
						SET @NeedPlacesForMen=@NeedPlacesForMen-1
					END
			END
		END
	END

	IF @Mod='INS' or (@Mod='UPD' and @SetToNewQuota=1) or @NeedPlacesForMen>0
	BEGIN
		if @N_DLSVKey=3 --для проживания отдельная ветка
		BEGIN
			If @NeedPlacesForMen>0
			BEGIN
				SELECT TOP 1 @RLPlacesMain=RL_NPlaces, @RLPlacesEx=RL_NPlacesEx, @RMKey=RL_RMKey, @RCKey=RL_RCKey from RoomNumberLists,ServiceByDate where RL_ID=SD_RLID and SD_DLKey=@DLKey
			END
			ELSE
			BEGIN
				SELECT	@HRIsMain=HR_MAIN, @RMKey=HR_RMKEY, @RCKey=HR_RCKEY, @ACKey=HR_ACKEY,
						@RMPlacesMain=RM_NPlaces, @RMPlacesEx=RM_NPlacesEx,
						@ACPlacesMain=ISNULL(AC_NRealPlaces,0), @ACPlacesEx=ISNULL(AC_NMenExBed,0), @ACPerRoom=ISNULL(AC_PerRoom,0)
				FROM HotelRooms, Rooms, AccmdMenType
				WHERE HR_Key=@N_DLSubcode1 and RM_Key=HR_RMKEY and AC_KEY=HR_ACKEY
				if @ACPerRoom=1 or (ISNULL(@RMPlacesMain,0)=0 and ISNULL(@RMPlacesEx,0)=0)
				BEGIN
					SET @RLPlacesMain = @ACPlacesMain
					SET @RLPlacesEx = ISNULL(@ACPlacesEx,0)
				END
				Else
				BEGIN
					IF @HRIsMain = 1 and @ACPlacesMain = 0 and @ACPlacesEx = 0
					BEGIN
						set @ACPlacesMain = 1
					END
					ELSE IF @HRIsMain = 0 and @ACPlacesMain = 0 and @ACPlacesEx = 0
					BEGIN
						set @ACPlacesEx = 1
					END

					SET @RLPlacesMain = @RMPlacesMain
					SET	@RLPlacesEx = ISNULL(@RMPlacesEx,0)
				END
				IF @Mod='UPD' and @SetToNewQuota=1	--если услуга полностью ставится на квоту (из-за глобальных изменений (было удаление из ServiceByDate))
					SET @NeedPlacesForMen=ISNULL(@N_DLNMen,0)
				ELSE
					SET @NeedPlacesForMen=ISNULL(@N_DLNMen,0)-ISNULL(@O_DLNMen,0)
			END
	
			SET @RLID = 0
			SET @AC_FreeMainPlacesCount = 0
			SET @AC_FreeExPlacesCount = 0
			SET @RL_FreeMainPlacesCount = 0
			SET @RL_FreeExPlacesCount = 0
			WHILE (@NeedPlacesForMen>0)
			BEGIN
				--если в последнем номере кончились места, то выставляем признак @RLID = 0
				IF @AC_FreeMainPlacesCount = 0 and @AC_FreeExPlacesCount = 0
				BEGIN
					SET @AC_FreeMainPlacesCount = @ACPlacesMain
					SET @AC_FreeExPlacesCount = @ACPlacesEx
					--создаем новый номер, всегда когда есть хоть кто-то на основном месте ???
					IF (@AC_FreeMainPlacesCount > @RL_FreeMainPlacesCount) or (@AC_FreeExPlacesCount > @RL_FreeExPlacesCount)
					BEGIN
						--создаем новый номер для каждой услуги, если размещение на номер.
						--IF @ACPlacesMain>0
						IF @ACPerRoom>0
						BEGIN			
							INSERT INTO RoomNumberLists(RL_NPlaces, RL_NPlacesEx, RL_RMKey, RL_RCKey) values (@RLPlacesMain, @RLPlacesEx, @RMKey, @RCKey)
							set @RLID=SCOPE_IDENTITY()
							INSERT INTO RoomPlaces (RP_RLID, RP_Type)
								SELECT @RLID, CASE WHEN NU_ID>@RLPlacesMain THEN 1 ELSE 0 END FROM NUMBERS WHERE NU_ID between 1 and (@RLPlacesMain+@RLPlacesEx)
							set @RPID=SCOPE_IDENTITY()-@RLPlacesMain-@RLPlacesEx+1
							SET @RL_FreeMainPlacesCount = @RLPlacesMain
							SET @RL_FreeExPlacesCount = @RLPlacesEx
						END
						ELSE
						BEGIN
							/*
							1. Ищем к кому подселиться в данной путевке, если не находим, то прийдется создавать новый номер
							*/
							set @RPID = null
							SELECT	TOP 1 @RPID=RP_ID, @RLID=RP_RLID
							FROM	RoomPlaces
							WHERE
								RP_Type=CASE WHEN @ACPlacesMain>0 THEN 0 ELSE 1 END
								and RP_RLID in 
								(	SELECT SD_RLID 
									FROM ServiceByDate,DogovorList,RoomNumberLists 
									WHERE SD_DLKey=DL_Key and DL_DGKey=@DGKey and RL_ID=SD_RLID and SD_TUKey=@TUKey
										and DL_SVKey=@N_DLSVKey and DL_Code=@N_DLCode 
										and DL_DateBeg=@N_DLDateBeg and DL_DateEnd=@N_DLDateEnd
										and RL_RMKey=@RMKey and RL_RCKey=@RCKey
								)
								and not exists 
								(	SELECT SD_RPID FROM ServiceByDate WHERE SD_RLID=RP_RLID and SD_RPID=RP_ID)
							ORDER BY RP_ID
							IF @RPID is null	-- надо создавать новый номер даже для дополнительного размещения
							BEGIN
								INSERT INTO RoomNumberLists(RL_NPlaces, RL_NPlacesEx, RL_RMKey, RL_RCKey) values (@RLPlacesMain, @RLPlacesEx, @RMKey, @RCKey)
								set @RLID=SCOPE_IDENTITY()
								INSERT INTO RoomPlaces (RP_RLID, RP_Type)
								SELECT @RLID, CASE WHEN NU_ID>@RLPlacesMain THEN 1 ELSE 0 END FROM NUMBERS WHERE NU_ID between 1 and (@RLPlacesMain+@RLPlacesEx)
								set @RPID = SCOPE_IDENTITY()
								set @RPID=CASE WHEN @ACPlacesMain>0 THEN SCOPE_IDENTITY()-@RLPlacesEx-@RLPlacesMain+1 ELSE SCOPE_IDENTITY()-@RLPlacesEx+1 END
								SET @RL_FreeMainPlacesCount = @RLPlacesMain
								SET @RL_FreeExPlacesCount = @RLPlacesEx
							END
						END
					END
				END
				
				--смотрим есть ли в текущем номере свободные ОСНОВНЫЕ места
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
				--INSERT INTO RoomPlaces (RP_RLID, RP_Type) values (@RLID,@CurrentPlaceIsEx)
				--set @RPID=SCOPE_IDENTITY()
				--SELECT @RPID=RP_ID FROM RoomPlaces WHERE RP_RLID=@RLID and RP_Type=@CurrentPlaceIsEx and RP_ID NOT IN (SELECT SD_RPID FROM ServiceByDate)
				--insert into debug (db_n1, db_n2, db_n3) values (@RLID, @CurrentPlaceIsEx, 1011)
				set @TUKey=null			
				
				--SELECT getdate(), convert(nvarchar(max), CAST((N1.NU_ID+@From-1) as datetime)) + ';' + convert(nvarchar(max), @DLKey) + ';' + convert(nvarchar(max), @RLID) + ';' + convert(nvarchar(max), @RPID) + ';' + convert(nvarchar(max), @TUKey)
				--FROM NUMBERS as N1 
				--WHERE N1.NU_ID between 1 and CAST(@N_DLDateEnd as int) - @From + 1
				
				
				SELECT @TUKey = TU_TUKey
				FROM dbo.TuristService
				WHERE TU_DLKey = @DLKey
				and TU_TUKey not in (SELECT SD_TUKey FROM ServiceByDate WHERE SD_DLKey = @DLKey)
				INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_TUKey)
					SELECT CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RLID, @RPID, @TUKey
					FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@N_DLDateEnd as int)-@From+1
				SET @NeedPlacesForMen=@NeedPlacesForMen-1
				SET @RPID=@RPID+1
			END		
		END --для проживания отдельная ветка... (КОНЕЦ)
		else --для всех услуг кроме проживания
		--while (@Date<=@N_DLDateEnd)
		BEGIN
			IF @Mod='UPD' and @SetToNewQuota=1	--если услуга полностью ставится на квоту (из-за глобальных изменений (было удаление из ServiceByDate))
				SET @NeedPlacesForMen=ISNULL(@N_DLNMen,0)
			ELSE
				SET @NeedPlacesForMen=ISNULL(@N_DLNMen,0)-ISNULL(@O_DLNMen,0)

			while(@NeedPlacesForMen > 0)
			BEGIN
				--INSERT INTO ServiceByDate (SD_Date, SD_DLKey) values (@Date, @DLKey)
				set @TUKey=null
				SELECT @TUKey=TU_TUKey FROM dbo.TuristService WHERE TU_DLKey=@DLKey and TU_TUKey not in (SELECT SD_TUKey FROM ServiceByDate WHERE SD_DLKey=@DLKey)
				INSERT INTO RoomPlaces(RP_RLID, RP_Type) values (0,0)
				set @RPID=SCOPE_IDENTITY()				
				INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RPID, SD_TUKey)	
					SELECT CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RPID, @TUKey
					FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@N_DLDateEnd as int)-@From+1
				set @NeedPlacesForMen=@NeedPlacesForMen-1
			END
			--set @Date=@Date+1
		END
		exec dbo.DogListToQuotas @DLKey --в этой хранимке будет выполнена попытка постановки услуги на квоту
	END
	FETCH NEXT FROM cur_DogovorListChanged2 
		INTO	@DLKey, @DGKey,
				@O_DLSVKey, @O_DLCode, @O_DLSubCode1, @O_DLDateBeg, @O_DLDateEnd, @O_DLNMen, @O_DLPartnerKey, @O_DLControl,
				@N_DLSVKey, @N_DLCode, @N_DLSubCode1, @N_DLDateBeg, @N_DLDateEnd, @N_DLNMen, @N_DLPartnerKey, @N_DLControl
END
CLOSE cur_DogovorListChanged2
DEALLOCATE cur_DogovorListChanged2

GO



/*********************************************************************/
/* end 20111219_AlterTrigger_UpdDogListQuota.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20111219_AlterView_Quotes.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='v' and name='Quotes')
	drop view dbo.Quotes
go

CREATE VIEW [dbo].[Quotes]
AS
--<VERSION>2009.2.10.3</VERSION>
--<DATE>2011-12-19</DATE>
SELECT     q.QT_PRKey, qo.QO_SVKey AS qt_svkey, qo.QO_SubCode1 AS qt_subcode1, qo.QO_SubCode2 AS subcode2, qo.QO_Code AS qt_code, qd.QD_Date AS qt_date, 
                      qd.QD_Places AS qt_places, qd.QD_Busy AS qt_busy, qp.QP_AgentKey AS qt_agent, qp.QP_ID AS qt_key, qd.QD_Release AS qt_release,
                      qp.QP_IsNotCheckIn AS qt_isnotcheckin, qp.QP_Long as qt_long, q.QT_ByRoom as qt_byroom
FROM         dbo.Quotas AS q INNER JOIN
                      dbo.QuotaObjects AS qo ON qo.QO_QTID = q.QT_ID INNER JOIN
                      dbo.QuotaDetails AS qd ON qd.QD_QTID = q.QT_ID INNER JOIN
                      dbo.QuotaParts AS qp ON qp.QP_QDID = qd.QD_ID
GO

grant select on dbo.Quotes to public
go
/*********************************************************************/
/* end 20111219_AlterView_Quotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin AlterTable_InsPolicy.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM InsPolicyStatuses WHERE IPS_ID = 7)
BEGIN
    INSERT INTO InsPolicyStatuses(IPS_ID, IPS_Name) VALUES (7, 'не акцептован')
END
GO

IF NOT EXISTS (SELECT 1 FROM InsPolicyStatuses WHERE IPS_ID = 8)
BEGIN
    INSERT INTO InsPolicyStatuses(IPS_ID, IPS_Name) VALUES (8, 'акцептован')
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.syscolumns WHERE id = object_id(N'[dbo].[InsPolicy]') and name = 'IP_IPSID')
BEGIN
    ALTER TABLE dbo.InsPolicy ADD IP_IPSID int NULL DEFAULT 0 WITH VALUES
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[FK_InsPolicy_InsPolicyStatuses]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
BEGIN
    ALTER TABLE dbo.InsPolicy ADD CONSTRAINT FK_InsPolicy_InsPolicyStatuses
        FOREIGN KEY (IP_IPSID) REFERENCES dbo.InsPolicyStatuses (IPS_ID)
        ON UPDATE CASCADE
END
GO
/*********************************************************************/
/* end AlterTable_InsPolicy.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Alter_NationalCurrencyReservationStatuses_Add_NC_IsGlobal.sql */
/*********************************************************************/
if not exists (select * from dbo.syscolumns where name = 'NC_IsGlobal' and id = object_id(N'[dbo].[NationalCurrencyReservationStatuses]'))
	ALTER TABLE dbo.NationalCurrencyReservationStatuses add NC_IsGlobal smallint null
	
GO

update NationalCurrencyReservationStatuses set NC_IsGlobal = 0

GO
/*********************************************************************/
/* end Alter_NationalCurrencyReservationStatuses_Add_NC_IsGlobal.sql */
/*********************************************************************/

/*********************************************************************/
/* begin alter_table_ObjectGroups.sql */
/*********************************************************************/
if not exists(select id from syscolumns where id = OBJECT_ID('ObjectGroups') and name = 'og_namelat')
	alter table ObjectGroups add og_namelat varchar(250) null
go

if not exists(select id from syscolumns where id = OBJECT_ID('ObjectGroupLinks') and name = 'OGL_LINK_TYPE')
	alter table ObjectGroupLinks add OGL_LINK_TYPE int not null default(0)
go
/*********************************************************************/
/* end alter_table_ObjectGroups.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Create_Table_PartnersNetworks.sql */
/*********************************************************************/
--***************************************Calendars Table**********************************************************************


IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[PartnersNetworks]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[PartnersNetworks](
		[PN_Key] [int] IDENTITY(1,1) NOT NULL,
		[PN_NAME] [varchar](250) NULL,
		[PN_NAMELAT] [varchar](250) NULL,
		[PN_MAINPRID] int NULL,
	PRIMARY KEY CLUSTERED 
	(
		[PN_Key] ASC
	))
end
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'FX_PN_MAINPRID' AND type in (N'F'))
ALTER TABLE [dbo].[PartnersNetworks]  WITH CHECK ADD  CONSTRAINT [FX_PN_MAINPRID] FOREIGN KEY([PN_MAINPRID])
REFERENCES [dbo].[tbl_Partners] ([PR_KEY])
GO


grant select, insert, update, delete on [dbo].[PartnersNetworks] to public
go


if not exists (select 1 from PartnersNetworks where PN_Key = 0)
begin
set identity_insert PartnersNetworks on
insert into PartnersNetworks (pn_key,pn_name,pn_namelat) values (0,'','')
set identity_insert PartnersNetworks off
end
go

if not exists(select id from syscolumns where id = OBJECT_ID('tbl_Partners') and name = 'PR_PNKEY')
	and exists (select id from syscolumns where id = OBJECT_ID('tbl_Partners'))
	begin
		alter table dbo.tbl_Partners add PR_PNKEY [int] NULL 
			
		IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'FX_PR_PNKEY' AND type in (N'F'))	
		ALTER TABLE [dbo].[tbl_Partners]  WITH CHECK ADD  CONSTRAINT [FX_PR_PNKEY] FOREIGN KEY([PR_PNKEY])
		REFERENCES [dbo].[PartnersNetworks] ([PN_KEY])	
	end
GO

exec sp_RefreshViewForAll 'Partners'
GO
/*********************************************************************/
/* end Create_Table_PartnersNetworks.sql */
/*********************************************************************/

/*********************************************************************/
/* begin I_x_tp_service_list.sql */
/*********************************************************************/
--x_tp_servicelist_1
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_1_old')
	DROP INDEX [x_tp_servicelist_1_old] ON [dbo].[TP_ServiceLists] WITH ( ONLINE = OFF )
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_1')
	EXEC sp_rename N'dbo.TP_ServiceLists.x_tp_servicelist_1', N'x_tp_servicelist_1_old', N'INDEX';
go
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_1')
	DROP INDEX [x_tp_servicelist_1] ON [dbo].[TP_ServiceLists] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_tp_servicelist_1] ON [dbo].[TP_ServiceLists] 
(
	[TL_TIKey] ASC
)WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_1_old')
	DROP INDEX [x_tp_servicelist_1_old] ON [dbo].[TP_ServiceLists] WITH ( ONLINE = OFF )
GO

--x_tp_servicelist_2
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_2_old')
	DROP INDEX [x_tp_servicelist_2_old] ON [dbo].[TP_ServiceLists] WITH ( ONLINE = OFF )
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_2')
	EXEC sp_rename N'dbo.TP_ServiceLists.x_tp_servicelist_2', N'x_tp_servicelist_2_old', N'INDEX';
go
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_2')
	DROP INDEX [x_tp_servicelist_2] ON [dbo].[TP_ServiceLists] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_tp_servicelist_2] ON [dbo].[TP_ServiceLists] 
(
	[TL_TOKey] ASC
)
	INCLUDE ( [TL_TSKey],
	[TL_TIKey]) WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_2_old')
	DROP INDEX [x_tp_servicelist_2_old] ON [dbo].[TP_ServiceLists] WITH ( ONLINE = OFF )
GO

--x_tp_servicelist_3
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_3_old')
	DROP INDEX [x_tp_servicelist_3_old] ON [dbo].[TP_ServiceLists] WITH ( ONLINE = OFF )
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_3')
	EXEC sp_rename N'dbo.TP_ServiceLists.x_tp_servicelist_3', N'x_tp_servicelist_3_old', N'INDEX';
go
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_3')
	DROP INDEX [x_tp_servicelist_3] ON [dbo].[TP_ServiceLists] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_tp_servicelist_3] ON [dbo].[TP_ServiceLists] 
(
	[TL_TSKey] ASC
)
	INCLUDE ( [TL_TIKey]) WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceLists]') AND name = N'x_tp_servicelist_3_old')
	DROP INDEX [x_tp_servicelist_3_old] ON [dbo].[TP_ServiceLists] WITH ( ONLINE = OFF )
GO
/*********************************************************************/
/* end I_x_tp_service_list.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalculateCalendarDeadLines.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalculateCalendarDeadLines]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CalculateCalendarDeadLines]
GO
CREATE PROCEDURE [dbo].[CalculateCalendarDeadLines]
	(
		@calendarKey int
	)	
AS
BEGIN	
	if (@calendarKey is null)
	begin
		return 0		
	end

	declare @issue int, @reception int, @holiDay int
	-- выдача документов
	set @issue = 3
	-- прием документов
	set @reception = 2
	-- выходной
	set @holiDay = 1
	
	declare @cdId int, @cdCtKey int, @cdArrivalDate datetime
	
	declare calculateCalendarDeadLinesCursor cursor forward_only local for
		select CD_Id, CD_CTKey, CD_ArrivalDate
		from CalendarDeadLines
		where CD_CLKey = @calendarKey
	open calculateCalendarDeadLinesCursor;
	fetch next from calculateCalendarDeadLinesCursor into @cdId, @cdCtKey, @cdArrivalDate;
	while @@FETCH_STATUS = 0
	begin
		declare @visaDays int, @regionDays int, @tempDate datetime
		
		declare @temp_table table
		(
			CD_Key int,
			CD_Date datetime
		)
		delete @temp_table
		-- количество дней на оформление услуги виза
		set @visaDays = isnull((	select top 1 SL_DaysCountMin
									from ServiceList join CalendarDeadLines on SL_KEY = CD_SLKey
									where CD_Id = @cdId), 0)
		-- количество дней на регион
		set @regionDays = isnull((	select top 1 CR_AddDay
									from CalendarRegion
									where CR_CLKey = @calendarKey
									and CR_CTKey = @cdCtKey), 0)
		-- дата выдачи = дата вылета - 1 день
		set @tempDate = ISNULL((	select MAX(CD_DATE)
									from CalendarDates join CalendarDateEvents on CD_Key = CDE_CalendarDateKey 
									where CD_CalendarKey = @calendarKey
									and CDE_CalendarEventTypeKey = @issue
									and CD_Date <= DATEADD(day, -1, @cdArrivalDate)), '1890-01-01')
		-- вычитаем (@visaDays + @regionDays) рабочий день - 1 рабочий день (еще +1 потому что берем минимальное значение из выборки)
		insert into @temp_table(CD_Key, CD_Date)
		select top (@visaDays + @regionDays + 2) CD_Key, CD_Date
		from CalendarDates
		where CD_CalendarKey = @calendarKey
		and exists (select 1 from CalendarDateEvents where CD_Key = CDE_CalendarDateKey and CDE_CalendarEventTypeKey != @holiDay)
		and CD_Date <= @tempDate
		group by CD_Key, CD_Date
		order by CD_Date desc
		
		if ((select count(*) from @temp_table) = (@visaDays + @regionDays + 2))
		begin
			set @tempDate = ISNULL((select MIN(CD_Date)
									from @temp_table
									), '1890-01-01')
		end
		else
		begin
			set @tempDate = '1890-01-01'
		end
		-- находим день сдачи документов
		set @tempDate = ISNULL((	select MAX(CD_DATE)
									from CalendarDates join CalendarDateEvents on CD_Key = CDE_CalendarDateKey 
									where CD_CalendarKey = @calendarKey
									and CDE_CalendarEventTypeKey = @reception
									and CD_Date <= @tempDate), '1890-01-01')
		-- сохраняем результат
		update CalendarDeadLines
		set CD_DeadLineConsulateDate = @tempDate
		where CD_Id = @cdId
		
		--select @tempDate
		
		fetch next from calculateCalendarDeadLinesCursor into @cdId, @cdCtKey, @cdArrivalDate;
	end
END

GO
grant exec on [dbo].[CalculateCalendarDeadLines] to public
go
/*********************************************************************/
/* end sp_CalculateCalendarDeadLines.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalculatePriceList.sql */
/*********************************************************************/
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
	@nCalculatingKey int,		-- ключ итерации дозаписи
	@dtSaleDate datetime,		-- дата продажи
	@nNullCostAsZero smallint,	-- считать отсутствующие цены нулевыми (кроме проживания) 0 - нет, 1 - да
	@nNoFlight smallint,		-- при отсутствии перелёта в расписании 0 - ничего не делать, 1 - не обсчитывать тур, 2 - искать подходящий перелёт (если не найдено - не рассчитывать)
	@nUpdate smallint,			-- признак дозаписи 0 - расчет, 1 - дозапись
	@nUseHolidayRule smallint		-- Правило выходного дня: 0 - не использовать, 1 - использовать
  )
AS

--<DATE>2012-01-26</DATE>
---<VERSION>9.2.10.1</VERSION>
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
declare @TI_TOTALDAYS int
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

--осуществляется пересчет прайса планировщиком
if (@tpPricesCount > 0 and @nUpdate = 0)
begin
	set @isPriceListPluginRecalculation = 1
	set @nCalculatingKey = null
	
	select top 1 @nCalculatingKey = CP_Key from CalculatingPriceLists where CP_PriceTourKey = @nPriceTourKey and CP_Update = 0
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

	Set @nTotalProgress=1
	update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	select @nDateFirst = @@DATEFIRST
	set DATEFIRST 1
	set @SERV_NOTCALCULATE = 32768

	If @nUpdate=0
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_CalculatingKey, TF_TourDate)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey,
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_TotalDays, @nCalculatingKey, TD_Date
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock), TP_Lists with(nolock), TP_ServiceLists with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TI_TOKey = TO_Key and TL_TOKey = TO_Key and TL_TSKey = TS_Key and TL_TIKey = TI_Key and TO_Key = @nPriceTourKey
	Else
	BEGIN
		select distinct TO_Key, TD_Date + TS_Day - 1 flight_day, TS_Code , TS_OpPartnerKey,	TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_TotalDays, TD_Date
		into #tp_flights
		from TP_Tours with(nolock) join TP_Services with(nolock) on TO_Key = TS_TOKey and TS_SVKey = 1
			join TP_ServiceLists with(nolock) on TL_TSKey = TS_Key and TS_TOKey = TO_Key
			join TP_Lists with(nolock) on TL_TIKey = TI_Key and TI_TOKey = TO_Key
			join TP_TurDates with(nolock) on TD_TOKey = TO_Key
		where TO_Key = @nPriceTourKey
		
		delete from #tp_flights where exists (Select 1 From TP_Flights with(nolock) Where TF_TOKey=@nPriceTourKey and TF_Date=flight_day
			and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
			and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = TI_TotalDays)
	
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_TourDate, TF_CalculatingKey)
		select *, @nCalculatingKey  from #tp_flights
	END

--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
	--Update	TP_Flights with(rowlock) Set 	TF_CodeNew = TF_CodeOld,
	--			TF_PRKeyNew = TF_PRKeyOld
	--Where	(SELECT count(*) FROM AirSeason  with(nolock) WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') > 0 
	--	and TF_TOKey = @nPriceTourKey	
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_CalculatingKey = @nCalculatingKey
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey 
			and TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') 
			and TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01')
			and (ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') 
			and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long))
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
								TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') 
								AND TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01') 
								AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
								(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and
								(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long)
								),
					TF_PRKeyNew = TF_PRKeyOld,
					TF_CalculatingKey = @nCalculatingKey
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
									TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') 
									AND TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01') 
									AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
									(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and
									(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long)
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
									TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') 
									AND TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01') 
									AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
									(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and
									(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long)
									),
					TF_CalculatingKey = @nCalculatingKey	
			Where	TF_CodeNew is Null 
					and TF_TOKey = @nPriceTourKey

		end
	END
	-----если перелет так и не найден, то в поле TF_CodeNew будет NULL

	--------------------------------------- закончили поиск подходящего перелета --------------------------------------
	--if ISNULL((select to_update from [dbo].tp_tours with(nolock) where to_key = @nPriceTourKey),0) <> 1
	if (1 = 1)
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

		--смотрим сколько записей по текущему прайсу уже посчитано
		Set @NumCalculated = (SELECT COUNT(1) FROM tp_prices with(nolock) where tp_tokey = @nPriceTourKey)
		--считаем сколько записей надо посчитать
		set @NumPrices = ((select count(1) from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) * (select count(1) from tp_turdates with(nolock) where td_tokey = @nPriceTourKey and td_update = @nUpdate))

		if (@NumCalculated + @NumPrices) = 0
			set @NumPrices = 1

		--Set @nTotalProgress=@nTotalProgress + (CAST(@NumCalculated as money)/CAST((@NumCalculated+@NumPrices) as money) * (90-@nTotalProgress))
		set @nTotalProgress = @nTotalProgress + CAST(@NumCalculated as money) / CAST((@NumCalculated + @NumPrices) as money)
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
			select ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, to_rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_totaldays, ts_ctkey, ts_attribute
			from tp_tours with(nolock), tp_services with(nolock), tp_lists with(nolock), tp_servicelists with(nolock), tp_turdates with(nolock)
			where to_key = @nPriceTourKey and to_key = ts_tokey and to_key = ti_tokey and to_key = tl_tokey and ts_key = tl_tskey and ti_key = tl_tikey and to_key = td_tokey
				and ti_update = @nUpdate and td_update = @nUpdate and (@nUseHolidayRule = 0 or (case cast(datepart(weekday, td_date) as int) when 7 then 0 else cast(datepart(weekday, td_date) as int) end + ti_totaldays) >= 8)
			order by ti_firsthdkey, td_date, ti_key

		open serviceCursor
		SELECT @round = ST_RoundService FROM Setting
		--MEG00036108 увеличил значение
		set @nProgressSkipLimit = 10000

		set @nProgressSkipCounter = 0
		--Set @nTotalProgress = @nTotalProgress + 1
		--update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey

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

		declare @calcPricesCount int, @calcPriceListCount int, @calcTurDates int
		select @calcPriceListCount = COUNT(1) from TP_Lists with(nolock) where TI_TOKey = @nPriceTourKey and TI_UPDATE = @nUpdate
		select @calcTurDates = COUNT(1) from TP_TurDates with(nolock) where TD_TOKey = @nPriceTourKey and TD_UPDATE = @nUpdate
		select @calcPricesCount = @calcPriceListCount * @calcTurDates

		insert into #TP_Prices (xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey, xTP_CalculatingKey) 
		select tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey
		from tp_prices with(nolock)
		where tp_tokey = @nPriceTourKey and 
			tp_tikey in (select ti_key from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) and
			tp_datebegin in (select td_date from tp_turdates with(nolock) where td_tokey = @nPriceTourKey and td_update = @nUpdate)
		

		fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_TOTALDAYS, @TS_CTKEY, @TS_ATTRIBUTE
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
							--select @nCalculatingKey
							if (@isPriceListPluginRecalculation = 0)
								update #TP_Prices set xtp_gross = @price_brutto, xtp_calculatingkey = @nCalculatingKey, xtp_key = @nTP_PriceKeyCurrent where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant and xtp_gross <> @price_brutto
							else
								update #TP_Prices set xtp_gross = @price_brutto, xtp_key = @nTP_PriceKeyCurrent where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant and xtp_gross <> @price_brutto
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
			
				--очищаем данные
				if @@fetch_status = 0
				begin
					if @nTP_PriceKeyCurrent > @nTP_PriceKeyMax
					BEGIN
						exec GetNKeys 'TP_PRICES', @NumPrices, @nTP_PriceKeyMax output
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

			--переписываем данные в таблицу tp_prices
			if @hdKey <> @prevHdKey or @@fetch_status <> 0
			begin
				set @prevHdKey = @hdKey
			end
			
			if @@fetch_status <> 0
				break
						
			---------------------------------------------------------------------------------

				if @tsCheckMargin = 1 and @tdCheckMargin = 1
					exec GetTourMargin @TrKey, @turdate, @nMargin output, @nMarginType output, @nSvkey, @TI_TOTALDAYS, @dtSaleDate, @nPacketkey
				else
				BEGIN
					set @nMargin = 0
					set @nMarginType = 0
				END
				set @servicedate = @turdate + @nDay - 1
				if @nSvkey = 1
					set @nDays = @TI_TOTALDAYS

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
								TF_Date = @servicedate AND
								TF_Days = @TI_TOTALDAYS
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

			fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_TOTALDAYS, @TS_CTKEY, @TS_ATTRIBUTE
		END
		close serviceCursor
		deallocate serviceCursor

		----------------------------------------------------- возвращаем обратно цены ------------------------------------------------------

		Set @nTotalProgress = 97
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
		--удаление из веба
		if (@nIsEnabled = 1)
		begin
			--if (@isPriceListPluginRecalculation = 0)
			--EXEC ClearMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
			--else
			--koshelev временная мера
			EXEC ClearMasterWebSearchFields @nPriceTourKey, null
		end

		delete from tp_prices with(rowlock)
		where tp_tokey = @nPriceTourKey and 
			tp_tikey in (select ti_key from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) and
			tp_DateBegin in (select td_date from TP_TurDates with(nolock) where td_tokey = @nPriceTourKey and TD_Update = @nUpdate)
			
		INSERT INTO TP_Prices with(rowlock) (tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey) 
			select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey, xTP_CalculatingKey 
			from #TP_Prices 

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
	set
		ti_nights = dbo.mwGetTiNights(ti_key)
	where 
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))
	
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

	Set @nTotalProgress = 100
	update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
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
	
	if (@nIsEnabled = 1)
	begin
		--if (@isPriceListPluginRecalculation = 0)
		--EXEC FillMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
		--else
		--koshelev временная мера
		EXEC FillMasterWebSearchFields @nPriceTourKey, null
	end

	Return 0
END
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

GRANT EXEC ON [dbo].[CalculatePriceList] TO PUBLIC
GO

/*********************************************************************/
/* end sp_CalculatePriceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckDoubleDogovor.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckDoubleDogovor]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckDoubleDogovor]
GO
CREATE procedure [dbo].[CheckDoubleDogovor]  
	--<VERSION>2009.2.3<VERSION/>
	--<DATA>20011-11-21<DATA/>
	@TourDate varchar (12),
	@TourDuration int,
	@LastName varchar (25),
	@FirstName varchar (25),	
	@HotelKey int
AS
begin
	SET @LastName = REPLACE (@LastName,'''','')
	SET @FirstName = REPLACE (@FirstName,'''','')
	
	if (@HotelKey > 0)
		BEGIN
			SELECT TU_DGCOD, TU_KEY 
			From dbo.tbl_turist 
			where RTRIM(LTRIM((UPPER(TU_NAMERUS)))) = RTRIM(LTRIM((UPPER(@LastName)))) 
			AND RTRIM(LTRIM((UPPER(TU_FNAMERUS)))) = RTRIM(LTRIM((UPPER(@FirstName)))) 
			AND EXISTS (SELECT DG_KEY 
						FROM dogovor 
						WHERE DG_CODE = TU_DGCOD 
						and (@TourDate between DG_TURDATE and DATEADD(DAY, DG_NDAY - 1, DG_TURDATE)
								or DG_TURDATE between @TourDate and DATEADD(DAY, @TourDuration - 1, @TourDate)))
			AND EXISTS (SELECT DL_KEY 
						FROM [dbo].[tbl_dogovorlist] 
						WHERE DL_DGCOD = TU_DGCOD 
						AND DL_SVKEY = 3 
						AND DL_CODE = @HotelKey)
		END
	else
		BEGIN
			SELECT TU_DGCOD, TU_KEY 
			From [dbo].[tbl_turist] 
			where RTRIM(LTRIM((UPPER(TU_NAMERUS)))) = RTRIM(LTRIM((UPPER(@LastName)))) 
			AND RTRIM(LTRIM((UPPER(TU_FNAMERUS)))) = RTRIM(LTRIM((UPPER(@FirstName)))) 
			AND EXISTS (SELECT DG_KEY 
						FROM dogovor 
						where DG_CODE = TU_DGCOD
						and (@TourDate between DG_TURDATE and DATEADD(DAY, DG_NDAY - 1, DG_TURDATE)
								or DG_TURDATE between @TourDate and DATEADD(DAY, @TourDuration - 1, @TourDate)))
		END  
end

GO

grant exec on [dbo].[CheckDoubleDogovor] to public
go
/*********************************************************************/
/* end sp_CheckDoubleDogovor.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckDoubleReservation.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckDoubleReservation]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckDoubleReservation]
GO

create procedure [dbo].[CheckDoubleReservation]
(	
	--<VERSION>2009.2.2<VERSION/>
	--<DATA>20011-11-21<DATA/>
	-- процедура определяет есть ли дублирующая путевка
	-- ключ договора
	@dogovorKey int,
	-- ключ дублирующего договора, если значение null то дублирующего договора не найдено
	@doubledogovorKey int output
)
AS
begin
	set @doubledogovorKey = null

	select top 1 @doubledogovorKey = DG_Key
	from tbl_turist as TU1 join tbl_Dogovor as DG1 on DG1.DG_CODE = TU1.TU_DGCOD
	where DG1.DG_Key != @dogovorKey
	and exists (select top 1 1
				from tbl_turist as TU2 join tbl_Dogovor as DG2 on DG2.DG_CODE = TU2.TU_DGCOD				
				where DG2.DG_Key = @dogovorKey
				and (DG1.DG_TURDATE between DG2.DG_TURDATE and DATEADD(DAY, DG2.DG_NDAY - 1, DG2.DG_TURDATE)
					or DG2.DG_TURDATE between DG1.DG_TURDATE and DATEADD(DAY, DG1.DG_NDAY - 1, DG1.DG_TURDATE))
				and RTRIM(LTRIM((UPPER(TU1.TU_NAMERUS)))) = RTRIM(LTRIM((UPPER(TU2.TU_NAMERUS))))
				and RTRIM(LTRIM((UPPER(TU1.TU_FNAMERUS)))) = RTRIM(LTRIM((UPPER(TU2.TU_FNAMERUS)))))
end
GO
grant exec on [dbo].[CheckDoubleReservation] to public
go
/*********************************************************************/
/* end sp_CheckDoubleReservation.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DeleteTPDAccesses.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeleteTPDAccesses]') 
AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DeleteTPDAccesses]
GO
CREATE Procedure dbo.DeleteTPDAccesses (@daysNumber int)
AS
BEGIN
	IF(ISNULL(@daysNumber, 0) < 30)
		return;
	delete from tpdaccesses 
	where DATEDIFF(day, TA_DATE, getdate()) > @daysNumber;
END
GO
/*********************************************************************/
/* end sp_DeleteTPDAccesses.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GenerateStartCode.sql */
/*********************************************************************/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GenerateStartCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP procedure [dbo].[GenerateStartCode]
GO

CREATE procedure [dbo].[GenerateStartCode]
AS
	declare @dateInt int
	declare @sTableName varchar(30)
	set @sTableName = 'CriticalChanges'
	select @dateInt = CAST(SS_ParmValue as int) from dbo.SystemSettings where SS_ParmName = 'GS_' + @sTableName
	if @dateInt is not null and @dateInt < CAST(GetDate() as float)
	begin
		delete from dbo.CriticalChanges where CC_Date < (GetDate() - 92)
		update dbo.SystemSettings set SS_ParmValue = CAST(FLOOR(CAST(GetDate() as float) + 14) as varchar(20)) where SS_ParmName = 'GS_' + @sTableName
	end

	set @dateInt = null
	set @sTableName = 'MasterEvents'
	select @dateInt = CAST(SS_ParmValue as int) from dbo.SystemSettings where SS_ParmName = 'GS_' + @sTableName
	if @dateInt is not null and @dateInt < CAST(GetDate() as float)
	begin
		delete from dbo.MasterEvents where ME_Date < (GetDate() - 10)
		update dbo.SystemSettings set SS_ParmValue = CAST(FLOOR(CAST(GetDate() as float) + 3) as varchar(20))  where SS_ParmName = 'GS_' + @sTableName
	end

	set @dateInt = null
	set @sTableName = 'HistoryPartner'
	select @dateInt = CAST(SS_ParmValue as int) from dbo.SystemSettings where SS_ParmName = 'GS_' + @sTableName
	if @dateInt is not null and @dateInt < CAST(GetDate() as float)
	begin
		delete from dbo.HistoryPartner where HP_Date < (GetDate() - 183)
		update dbo.SystemSettings set SS_ParmValue = CAST(FLOOR(CAST(GetDate() as float) + 14) as varchar(20))  where SS_ParmName = 'GS_' + @sTableName
	end
GO

grant execute on [dbo].[GenerateStartCode] to public
GO
/*********************************************************************/
/* end sp_GenerateStartCode.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetUserActions.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetUserActions]') 
AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetUserActions]
GO
CREATE Procedure dbo.GetUserActions (@userId int)
AS
BEGIN
    SELECT ACA_ACKey as ActionId
    FROM ( SELECT ACA_ACKey 
		   FROM ActionsAuth  	
		   WHERE ACA_USKey = @userId
		   UNION
		   SELECT GRA_ACKey 
		   FROM GroupAuth, UserList, sysmembers m, sysusers u, sysusers g  	
		   WHERE m.memberuid = u.uid AND GRA_GRKey = m.groupuid 
		   AND g.uid = m.groupuid AND u.name = US_UserID 
		   AND US_Key = @userId ) a
    WHERE a.ACA_ACKey is Not NULL
END
GO



/*********************************************************************/
/* end sp_GetUserActions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ImportExchangeQuotaStops.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ImportExchangeQuotaStops]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ImportExchangeQuotaStops]
GO

CREATE PROCEDURE [dbo].[ImportExchangeQuotaStops]
	(
		-- процедура импортирует информацию о квотах из тиблицы ExchangeQuotaStops
		--<version>2009.2.02</version>
		--<data>2011-11-25</data>
		@dateBeg datetime,
		@dateEnd datetime,
		@HotelKey int,
		@prKey int
	)
AS
BEGIN	
	SET NOCOUNT ON;
	
	declare @SvKey int, @Code int, @SubCode1 int, @SubCode2 int, @SubCode3 int, @Date datetime, @IsStop bit, @Places int, @PartnerKey int
	declare @qtKey int, @qoKey int, @qdKey int
	

	
	declare ExchangeQuotaStops_cursor cursor local fast_forward for
	select EQS_SvKey, EQS_Code, EQS_SubCode1, EQS_SubCode2, EQS_SubCode3, EQS_Date, EQS_IsStop, EQS_Places, EQS_PartnerKey
	from ExchangeQuotaStops 
	where EQS_Date between @dateBeg and @dateEnd
		AND EQS_Places >= 0 -- если -1 то значит что стоп(квота) удален
		AND EQS_Code =@HotelKey
	order by EQS_Date, EQS_IsStop;
	open ExchangeQuotaStops_cursor;
	
	fetch next from ExchangeQuotaStops_cursor into @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @Places, @PartnerKey;	
	while @@FETCH_STATUS = 0
	begin		
		-- сначала нужно снять с квоты (если вдруг они сидят) и удалить квоты и стопы которые пришли с такими же характеристиками на заданную дату			
		--exec ImportExchangeQuotaStops_Delete @SvKey, @Code, @SubCode1, @SubCode2, @SubCode3, @Date, @IsStop, @PartnerKey
		
		-- теперь, после того как все удалено создаем новые квоты и стопы
		if (@IsStop = 0)
		begin			
			if @SvKey = 3 and @Places >= 0
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
				
				insert into QuotaDetails(QD_QTID, QD_Date, QD_Type, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
				values (@qtKey, @Date, 1, @Places, 0, GETDATE(), [dbo].[GetUserId]())
				set @qdKey = SCOPE_IDENTITY()
				
				insert into QuotaParts(QP_QDID, QP_Date, QP_Places, QP_Busy, QP_Limit, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey)
				values (@qdKey, @Date, @Places, 0, 1, 0, '', GETDATE(), [dbo].[GetUserId]())
			end
		end
		else -- обрабатываем стопы
		begin
			if @SvKey = 3 
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
				values (@qoKey, null, @PartnerKey, @Date, 1, '', GETDATE(), [dbo].[GetUserId]())
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
GRANT exec on [dbo].[ImportExchangeQuotaStops] to public 

GO
/*********************************************************************/
/* end sp_ImportExchangeQuotaStops.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ImportExchangeQuotaStops_Delete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ImportExchangeQuotaStops_Delete]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ImportExchangeQuotaStops_Delete]
GO

CREATE PROCEDURE [dbo].[ImportExchangeQuotaStops_Delete]
	(
		-- хранимка удаляет стопы и квоты которые пришли из интерука для удаления
		--<version>2009.2.01</version>
		--<data>2011-11-24</data>
		@SvKey int,
		@Code int,
		@SubCode1 int,
		@SubCode2 int,
		@SubCode3 int,
		@Date datetime,
		@IsStop bit,
		@PartnerKey int
	)
AS
BEGIN	
	
	declare @SDDLKey int, @SDDate datetime
	
	-- если это квота то снимаем с нее все услуги (если вдруг что то сидит, хотя не должно)
	if (@IsStop = 0)
	begin
		-- пометим для удаления
		update QuotaDetails
		set QD_IsDeleted = 4 -- Request
		from QuotaDetails join Quotas on QT_ID = QD_QTID
		join QuotaObjects on QT_ID = QO_QTID
		where QO_Code = @Code
		and QO_SVKey = @SvKey
		--and QO_SubCode1 = @SubCode1
		--and QO_SubCode2 = @SubCode3
		and (@SubCode1 = -1 or QO_SubCode1 =@SubCode1)
		and (@SubCode2 = -1 or QO_SubCode2 =@SubCode2)
		and QD_Date = @Date
		and QT_PrKey = @PartnerKey;
		
		-- в этой хранимке снимим если сидела и удалим
		exec QuotaDetailAfterDelete
	end

	-- стопы бывают 2 видов 
	-- 1. На объект квотирования 
	delete StopSales
	from StopSales join QuotaObjects on SS_QOID = QO_ID
	where QO_Code = @Code
	and QO_SVKey = @SvKey
	--and QO_SubCode1 = @SubCode1
	--and QO_SubCode2 = @SubCode3
		and (@SubCode1 = -1 or QO_SubCode1 =@SubCode1)
		and (@SubCode2 = -1 or QO_SubCode2 =@SubCode2)
	and SS_Date = @Date
	and SS_QDID is null
	and QO_QTID is null
	and SS_PRKey = @PartnerKey;
	
	-- 2. на саму квоту (QuotaDetails)
	delete StopSales
	from StopSales join QuotaObjects on SS_QOID = QO_ID
	join QuotaDetails on SS_QDID = QD_ID
	join Quotas on QT_ID = QD_QTID and QT_ID = QO_QTID
	where QO_Code = @Code
	and QO_SVKey = @SvKey
	--and QO_SubCode1 = @SubCode1
	--and QO_SubCode2 = @SubCode3
		and (@SubCode1 = -1 or QO_SubCode1 =@SubCode1)
		and (@SubCode2 = -1 or QO_SubCode2 =@SubCode2)
	and SS_Date = @Date
	and QT_PrKey = @PartnerKey;
	
	
	-- теперь удалим объект квотирования и саму квоту, к которым не привязанно ни QuotaDetails ни StopSales
	delete QuotaObjects
	from QuotaObjects join Quotas on QO_QTID = QT_ID
	where not exists (select 1 from StopSales where SS_QOID = QO_ID)
	and not exists (select 1 from QuotaDetails where QD_QTID = QT_ID)
	and QO_SVKey = @SvKey
	and QO_Code = @Code
	
	delete Quotas
	from Quotas join QuotaObjects on QT_ID = QO_QTID
	where not exists (select 1 from QuotaObjects where QO_QTID = QT_ID)
	and not exists (select 1 from QuotaDetails where QD_QTID = QT_ID)
	and QO_SVKey = @SvKey
	and QO_Code = @Code
END

GO

grant exec on [dbo].[ImportExchangeQuotaStops_Delete] to public
go
/*********************************************************************/
/* end sp_ImportExchangeQuotaStops_Delete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCheckQuotesCycle.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwCheckQuotesCycle')
	drop proc dbo.mwCheckQuotesCycle
go

create procedure [dbo].[mwCheckQuotesCycle]
--<VERSION>2007.2.41.5</VERSION>
--<DATE>2011-11-17</DATE>
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
			@ptkey int,@pttourkey int,@hdkey int,@rmkey int,@rckey int,@tourdate datetime,@chkey int,@chbackkey int,@hdday int,@hdnights int,@hdprkey int,	@chday int,@chpkkey int,@chprkey int,@chbackday int,
		@chbackpkkey int,@chbackprkey int,@days int, @rowNum int, @hdStep smallint, @reviewed int,@selected int, @hdPriceCorrection int

	declare @pt_chdirectkeys varchar(256), @pt_chbackkeys varchar(256)
	declare @tmpAllHotelQuota varchar(128),@pt_hddetails varchar(256)

	set @reviewed= @pageNum
	set @selected=0

	declare @now datetime, @percentPlaces float, @pos int
	set @now = getdate()
	set @pos = 0

	fetch next from quotaCursor into
	@ptkey,
	@pttourkey,
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
	@pt_hddetails

	-- Golubinsky. 15.12.2011. Переменная, сохраняющая начальное значение параметра @findFlight
	-- для установки в начале каждой итерации и до поиска обратного перелета, чтобы не учитывался результат предыдущей итерации
	declare @initialFindflight as int
	set @initialFindflight = @findFlight

	while(@@fetch_status=0 and @selected < @pageSize)
	begin
	
		set @findFlight = @initialFindflight 
	
		if @pos >= @pageNum
		begin
			set @actual=1
			if(@aviaQuotaMask > 0)
			begin		
				declare @isEditableService bit
				set @tmpThereAviaQuota=null
				if(@chkey > 0)
				begin 
					--karimbaeva MEG00038768 17.11.2011 получаем редактируемый атрибут услуги
					exec [dbo].[mwGetServiceIsEditableAttribute] 1, @pttourkey, @chkey, @chday, @isEditableService output
					if (@isEditableService = 0)
							set @findFlight = 0
					select @tmpThereAviaQuota=res from #checked where svkey=1 and code=@chkey and date=@tourdate and day=@chday and days=@days and prkey=@chprkey and pkkey=@chpkkey and findflight = @findflight
					if (@tmpThereAviaQuota is null)
					begin
						--kadraliev MEG00025990 03.  в туре запрещено менять рейс, устанавливаем @findFlight = 0
						exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @chbackday
						insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res, findflight) values(1,@chkey,0,0,@tourdate,@chday,@days,@chprkey, @chpkkey, @tmpThereAviaQuota, @findflight)
					end					
					if(len(@tmpThereAviaQuota)=0)
						set @actual=0
						
					set @findFlight = @initialFindflight
						
				end
				if(@actual > 0)
				begin
					set @tmpBackAviaQuota=null
					if(@chbackkey > 0)
					begin
						--karimbaeva MEG00038768 17.11.2011 получаем редактируемый атрибут услуги
						exec [dbo].[mwGetServiceIsEditableAttribute] 1, @pttourkey, @chbackkey, @chbackday, @isEditableService output
						if (@isEditableService = 0)
							set @findFlight = 0
						select @tmpBackAviaQuota=res from #checked where svkey=1 and code=@chbackkey and date=@tourdate and day=@chbackday and days=@days and prkey=@chbackprkey and pkkey=@chbackpkkey and findflight = @findflight
						if (@tmpBackAviaQuota is null)
						begin
							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chbackkey, @flightGroups, @agentKey, @chbackprkey, @tourdate,@chbackday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chbackpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output, @chday
							insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res, findflight) values(1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey, @tmpBackAviaQuota, @findflight)
						end

						if(len(@tmpBackAviaQuota)=0)
							set @actual=0
							
						set @findFlight = @initialFindflight
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
												-- MEG00029210 kadraliev 08.02.2011 Использование @curHotelDay,@curHotelDays в качестве параметров для mwCheckQuotesEx при проверке квот на дополнительные отели
												select @tempPlaces=qt_places,@tempAllPlaces=qt_allPlaces from dbo.mwCheckQuotesEx(3,@curHotelKey,@curRoomKey,@curRoomCategoryKey, @agentKey, @hdprkey,@tourdate,@curHotelDay,@curHotelDays, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 0, 0, 0, 0, 0, @expiredReleaseResult)
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
		fetch next from quotaCursor into @ptkey,@pttourkey,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,@chday,@chpkkey,@chprkey,@chbackday,@chbackpkkey,@chbackprkey,@days,@chkey,@chbackkey,@rowNum, @pt_chdirectkeys, @pt_chbackkeys, @pt_hddetails
		set @pos = @pos + 1
	end

	select @reviewed
end
go

grant exec on dbo.mwCheckQuotesCycle to public
go

/*********************************************************************/
/* end sp_mwCheckQuotesCycle.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetServiceIsEditableAttribute.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwGetServiceIsEditableAttribute')
	drop proc dbo.mwGetServiceIsEditableAttribute
go

create procedure [dbo].[mwGetServiceIsEditableAttribute]
--<VERSION>2007.2.41.3</VERSION>
--<DATE>2011-11-17</DATE>
	@tssvkey int,
	@tokey int,
	@tscode int,
	@tsday int,
	@isEditable bit output

as
begin	
	declare @editableCode int
	set @editableCode = 2
	
	declare @path varchar(50)
	set @path = case dbo.mwReplIsPublisher() when 1 
					then '' 
					else 'mt.' + dbo.mwReplPublisherDB() + '.' end

	declare @sql varchar(4000)
	set @sql ='declare @tmp bit				
	select @tmp=1 from ' + @path + 'dbo.tp_services
	where ts_svkey= '+ltrim(rtrim(str(@tssvkey)))+' and ts_tokey= '+ltrim(rtrim(str(@tokey)))+' and ts_code='+ltrim(rtrim(str(@tscode)))+' and ts_day='+ltrim(rtrim(str(@tsday)))+'and (ts_attribute&+'+ltrim(rtrim(str(@editableCode)))+')='+ltrim(rtrim(str(@editableCode)))	
	exec (@sql)	
	set @isEditable = @@ROWCOUNT
end

go

grant exec on dbo.[mwGetServiceIsEditableAttribute] to public
go
/*********************************************************************/
/* end sp_mwGetServiceIsEditableAttribute.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwMakeFullSVName.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MWMAKEFULLSVNAME]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mwMakeFullSVName]
GO
CREATE    PROCEDURE [dbo].[mwMakeFullSVName]
(
--<VERSION>2009.2.11.1</VERSION>
--<DATE>2012-1-30</DATE>
	@nCountry INT,
	@nCity INT,
	@nSvKey INT,
	@nCode INT,
	@nNDays INT,
	@nCode1 INT,
	@nCode2 INT,
	@nPartner INT,
	@dServDate DATETIME,
	@sServiceByHand VARCHAR(800),	
	@sResult VARCHAR(800) OUTPUT,
	@sResultLat VARCHAR(800) OUTPUT
) AS
	DECLARE @nTempNumber INT

	DECLARE @sName VARCHAR(800)
	DECLARE @sNameLat VARCHAR(800)
	DECLARE @sText VARCHAR(800)
	DECLARE @sTextLat VARCHAR(800)
	DECLARE @sTempString VARCHAR(800)
	DECLARE @sTempStringLat VARCHAR(800)

	DECLARE @nMain INT
	DECLARE @nAgeFrom INT
	DECLARE @nAgeTo INT

	DECLARE 
	@TYPE_FLIGHT INT, 
	@TYPE_TRANSFER INT,
	@TYPE_HOTEL INT,
	@TYPE_EXCUR INT,
	@TYPE_VISA INT,
	@TYPE_INSUR INT,
	@TYPE_SHIP INT,
	@TYPE_HOTELADDSRV INT,
	@TYPE_SHIPADDSRV INT,
	@bIsCruise INT

	DECLARE @sTextCity VARCHAR(800)
	DECLARE @sTextCityLat VARCHAR(800)
	
	Set @TYPE_FLIGHT = 1
	Set @TYPE_TRANSFER = 2
	Set @TYPE_HOTEL = 3
	Set @TYPE_EXCUR = 4
	Set @TYPE_VISA = 5
	Set @TYPE_INSUR = 6
	Set @TYPE_SHIP = 7
	Set @TYPE_HOTELADDSRV = 8
	Set @TYPE_SHIPADDSRV = 9
	Set @bIsCruise = 0

	Set @nTempNumber = 1

	EXEC dbo.GetServiceName @nSvKey, @nTempNumber, @sName output, @sNameLat output

	If @sName != ''
		Set @sName = @sName + '::'
	If @sNameLat != ''
		Set @sNameLat = @sNameLat + '::'
--if Code is less than zero, we need only name of subservices
if (@nCode <= 0 and @sServiceByHand='')
begin
Set @sName=''
Set @sNameLat=''
end
--
	If @nSvKey = @TYPE_FLIGHT
	BEGIN
if (@nCode > 0)
begin
		Set @sText = '  '
		Set @sTextLat = '  '
		If @nCode2>0
			SELECT  @sText = CT_Name,
				@sTextLat = isnull(CT_NameLat, CT_Name)
			FROM	dbo.CityDictionary 
			WHERE	CT_Key = @nCode2
		Set @sName = @sName + @sText + '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'

		Set @sText = '  '
		Set @sTextLat = '  '
		If @nCity>0
			SELECT 	@sText = CT_Name,
				@sTextLat = isnull(CT_NameLat, CT_Name)
			FROM	dbo.CityDictionary 
			WHERE	CT_Key = @nCity
		Set @sName = @sName + @sText + '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'

		Set @sText = isnull(@sServiceByHand, '')
		Set @sTextLat = isnull(@sServiceByHand, '')	

		-- Aaiu iaaaee a oi?iaoa 1 - iii, 7 - an
		Declare @nday int
		Set @nday = DATEPART(dw, @dServDate)  + @@DATEFIRST - 1
		If @nday > 7 
	    		set @nday = @nday - 7
	
		If @nCode>0
			SELECT	@sText = isnull(CH_AirLineCode, '') + CH_Flight + ', ' + isnull(CH_PortCodeFrom, '') + '-' + isnull(CH_PortCodeTo, '') + ', ' + isnull(left(convert(varchar, AS_TimeFrom, 8),5),'') + '-' + isnull(left(convert(varchar, AS_TimeTo, 8),5),''),
				@sTextLat = isnull(CH_AirLineCode, '') + CH_Flight + ', ' + isnull(CH_PortCodeFrom, '') + '-' + isnull(CH_PortCodeTo, '') + ', ' + isnull(left(convert(varchar, AS_TimeFrom, 8),5),'') + '-' + isnull(left(convert(varchar, AS_TimeTo, 8),5),'')
			FROM 	dbo.Charter,dbo.AirSeason 
			WHERE 	CH_Key = @nCode and AS_ChKey = CH_Key and @dServDate between AS_DATEFROM and AS_DATETO  and 
				charindex(Cast(@nday as varchar(1)),AS_WEEK) > 0
		Set @sName = @sName + @sText + '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'
END
If (@nCode1>0)
BEGIN
		Set @sText = '  '
		Set @sTextLat = '  '
		If @nCode1>0
			SELECT	@sText = isnull(AS_Code, '') + ' ' + isnull(AS_NameRus, ''),
				@sTextLat = isnull(AS_Code, '') + ' ' + isnull(AS_NameLat, AS_NameRus)
			FROM 	dbo.AirService 
			WHERE 	AS_Key = @nCode1
		Set @sName = @sName + @sText + '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'
END
	END
	ELSE If (@nSvKey = @TYPE_HOTEL or @nSvKey = @TYPE_HOTELADDSRV)
	BEGIN
If (@nCode>0)
BEGIN
		Set @sText = '  '
		Set @sTextLat = '  '
		If @nCity>0
			SELECT 	@sTextCity = CT_Name,
				@sTextCityLat = isnull(CT_NameLat, CT_Name)
			FROM	dbo.CityDictionary 
			WHERE	CT_Key = @nCity		      

		Set @sText = isnull(@sServiceByHand, '')

		If @nCode>0
		      	SELECT	@sText = isnull(HD_Name,'') + '-' + isnull(HD_Stars, ''), @bIsCruise = HD_IsCruise 
			FROM 	dbo.HotelDictionary 
			WHERE	HD_Key = @nCode
		Set @sTextLat = @sText
		If @bIsCruise = 1
			If @nSvKey = @TYPE_HOTEL
			BEGIN
				Set @sName = 'E?oec::'
				Set @sNameLat = 'Cruise::'
			END
			Else If @nSvKey = @TYPE_HOTELADDSRV
				Set @sName = 'ADCruise::'

		Set @sName = @sName + @sTextCity + '/'  + @sText
		Set @sNameLat = @sNameLat + @sTextCityLat + '/' + @sTextLat

		If @nNDays>0
		BEGIN
			Set @nTempNumber = 0
			EXEC dbo.SetNightString @nNDays, @nTempNumber, @sTempString output, @sTempStringLat output
			Set @sName = @sName + ',' + isnull(cast(@nNDays as varchar (4)), '') + ' ' + @sTempString
			Set @sNameLat = @sNameLat + ',' + isnull(cast(@nNDays as varchar (4)), '') + ' ' + @sTempStringLat
		END
		Set @sName = @sName + '/'
		Set @sNameLat = @sNameLat + '/'
END
If (@nCode1>0)
BEGIN
		Set @sText = '  '
		Set @sTextLat = '  '

      		EXEC dbo.GetSvCode1Name @nSvKey, @nCode1, @sText output, @sTempString output, @sTextLat output, @sTempStringLat output
       		Set @sName = @sName + isnull(@sTempString, '') + '/'
		Set @sNameLat = @sNameLat + isnull(@sTempStringLat, '') + '/'
END

If (@nCode2>0)
BEGIN
		Set @sText = '  '
              	EXEC dbo.GetSvCode2Name @nSvKey, @nCode2, @sTempString output, @sTempStringLat output
             
             	Set @sName = @sName + isnull(@sTempString, '') + '/'
		Set @sNameLat = @sNameLat + isnull(@sTempStringLat, '') + '/'
END
	END
	ELSE If (@nSvKey = @TYPE_EXCUR or @nSvKey = @TYPE_TRANSFER)
	BEGIN
if (@nCode > 0)
begin
		Set @sText = '  '
		Set @sTextLat = '  '
		If @nCity>0
			SELECT 	@sText = CT_Name,
				@sTextLat = isnull(CT_NameLat, CT_Name)
			FROM	dbo.CityDictionary 
			WHERE	CT_Key = @nCity	
		Set @sName = @sName + @sText + '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'

		Set @sText = isnull(@sServiceByHand, '')
		Set @sTextLat = isnull(@sServiceByHand, '')
		If @nCode>0
			If @nSvKey = @TYPE_EXCUR
				SELECT 	@sText = ED_Name +', ' + isnull(ED_Time, ''),
					@sTextLat = isnull(ED_NameLat,ED_Name) +', ' + isnull(ED_Time, '')
				FROM	dbo.ExcurDictionary 
				WHERE	ED_Key = @nCode
			ELSE
				SELECT 	@sText = TF_Name + ', ' + isnull (Left (Convert (varchar, TF_TimeBeg, 8), 5), '')  + ', ' + isnull(TF_TIME, ''),
					@sTextLat = isnull(TF_NameLat,TF_Name) + ', ' + isnull (Left (Convert (varchar, TF_TimeBeg, 8), 5), '')  + ', ' + isnull(TF_TIME, '')  
				FROM	dbo.Transfer 
				WHERE	TF_Key = @nCode
		Set @sName = @sName + @sText +  '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'
end
		Set @sText = '  '
		Set @sTextLat = '  '
		If @nCode1>0
begin
			SELECT 	@sText = TR_Name + (case  when (TR_NMen>0)  then (','+ CAST ( TR_NMen  AS VARCHAR(10) )+ ' ?ae.')  else ' ' end),
				@sTextLat = isnull(TR_NameLat,TR_Name) + (case  when (TR_NMen>0)  then (','+ CAST ( TR_NMen  AS VARCHAR(10) )+ ' pax.')  else ' ' end) 
			FROM	dbo.Transport  
			WHERE	TR_Key = @nCode1
		Set @sName = @sName + @sText + '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'
end
	END
	ELSE If (@nSvKey = @TYPE_SHIP or @nSvKey = @TYPE_SHIPADDSRV)
	BEGIN
if (@nCode>0)
begin
		Set @sText = '  '
		Set @sTextLat = '  '
		If @nCountry>0
	                        SELECT	@sText = CN_Name,
					@sTextLat = isnull(CN_NameLat, CN_Name)
				FROM	Country 
				WHERE	CN_Key = @nCountry
		Set @sName = @sName + @sText + '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'
		
		Set @sText = isnull(@sServiceByHand, '')
		If @nCode>0
		      	SELECT	@sText = SH_Name + '-' + isnull(SH_Stars, '') 
			FROM	dbo.Ship 
			WHERE	SH_Key = @nCode
		Set @sTextLat = @sText
				
		Set @sName = @sName + @sText
		Set @sNameLat = @sNameLat + @sTextLat
		
		If @nNDays>0
		BEGIN
			Set @sName = @sName + ',' + isnull(cast(@nNDays as varchar (10)), '') + ' ' + 'aiae'
			Set @sNameLat = @sNameLat + ',' + isnull(cast(@nNDays as varchar (10)), '') + ' ' + 'days'
		END					
		Set @sName = @sName + '/'
		Set @sNameLat = @sNameLat + '/'
end
if (@nCode1>=0)
begin
		Set @sText = '  '
		Set @sTextLat = '  '
		
	      	EXEC dbo.GetSvCode1Name @nSvKey, @nCode1, @sText output, @sTempString output, @sTextLat output, @sTempStringLat output
		Set @sName = @sName + isnull(@sTempString, '') + '/'
		Set @sNameLat = @sNameLat + isnull(@sTempStringLat, '') + '/'
end
if (@nCode2>=0)
begin
		Set @sText = '  '
              	EXEC dbo.GetSvCode2Name @nSvKey, @nCode2, @sTempString output, @sTempStringLat output
		
		Set @sName = @sName + isnull(@sTempString, '') + '/'
		Set @sNameLat = @sNameLat + isnull(@sTempStringLat, '') + '/'
end
	END
	ELSE
	BEGIN
if (@nCode>0)
begin
		Set @sText = '  '
		Set @sTextLat = '  '
		Set @sTempString = 'CITY'
		EXEC dbo.GetSvListParm @nSvKey, @sTempString, @nTempNumber output
		
		If @nTempNumber>0
		BEGIN
			If @nCity>0
				SELECT 	@sText = CT_Name,
					@sTextLat = isnull(CT_NameLat, CT_Name)
				FROM	dbo.CityDictionary 
				WHERE	CT_Key = @nCity	
			Set @sName = @sName + @sText + '/'
			Set @sNameLat = @sNameLat + @sTextLat + '/'
		END
		ELSE
		BEGIN
			If @nCountry>0
	                        SELECT	@sText = CN_Name,
					@sTextLat = isnull(CN_NameLat, CN_Name)
				FROM	Country 
				WHERE	CN_Key = @nCountry
			Else If @nCode>0
	             	        SELECT	@sText = CN_Name,
					@sTextLat = isnull(CN_NameLat, CN_Name)
				FROM	dbo.ServiceList, Country 
				WHERE	SL_Key = @nCode and CN_Key = SL_CnKey
			Set @sName = @sName + @sText + '/'
			Set @sNameLat = @sNameLat + @sTextLat + '/'
		END
		Set @sText = @sServiceByHand
		Set @sTextLat = @sServiceByHand
		If @nCode>0
		BEGIN

		    	SELECT	@sText = SL_Name,
				@sTextLat = isnull(SL_NameLat, SL_Name)
			FROM	dbo.ServiceList
			WHERE	SL_Key = @nCode
		END
		Set @sName = @sName + @sText
		Set @sNameLat = @sNameLat + @sTextLat

		If @nNDays>0
		BEGIN
			Set @nTempNumber = 1
			exec SetNightString @nNDays, @nTempNumber, @sTempString output, @sTempStringLat output
			Set @sName = @sName + ',' + isnull(cast(@nNDays as varchar (10)), '')  + ' ' + @sTempString
			Set @sNameLat = @sNameLat + ',' + isnull(cast(@nNDays as varchar (10)), '')  + ' ' + @sTempStringLat
		END
		Set @sName = @sName + '/'
		Set @sNameLat = @sNameLat + '/'
end
		Set @sText = '  '
		Set @sTextLat = '  '
		Set @sTempString = 'CODE1'
		exec dbo.GetSvListParm @nSvKey, @sTempString, @nTempNumber output

		If @nTempNumber>0
		BEGIN
if (@nCode1>0)
begin
			If @nCode1>0 and (@nSvKey != @TYPE_HOTELADDSRV or @nSvKey != @TYPE_SHIPADDSRV)
				SELECT	@sText = A1_Name,
					@sTextLat = isnull(A1_NameLat, A1_Name)
				FROM	dbo.AddDescript1
				WHERE	A1_Key = @nCode1
			ELSE
			BEGIN
				EXEC dbo.GetSvCode1Name @nSvKey, @nCode1, @sText output, @sTempString output, @sTextLat output, @sTempStringLat output
				set @sText = @sTempString
				set @sTextLat = @sTempStringLat
			END
			Set @sName = @sName + @sText + '/'
			Set @sNameLat = @sNameLat + @sTextLat + '/'
end
if (@nCode2>0)
begin
			Set @sTempString = 'CODE2'
			exec dbo.GetSvListParm @nSvKey, @sTempString, @nTempNumber output

			If @nTempNumber>0
			BEGIN
				If @nCode2>0
				SELECT	@sText = A2_Name,
					@sTextLat = isnull(A2_NameLat, A2_Name)
				FROM	dbo.AddDescript2
				WHERE	A2_Key = @nCode2
				Set @sName = @sName + @sText + '/'
				Set @sNameLat = @sNameLat + @sTextLat + '/'
			END
end
		END
	END
	Set @sResult = @sName
	Set @sResultLat = @sNameLat
GO
GRANT EXECUTE ON dbo.mwMakeFullSVName TO PUBLIC 
GO
/*********************************************************************/
/* end sp_mwMakeFullSVName.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwSyncDictionaryData.sql */
/*********************************************************************/
--kadraliev MEG00029412 30.09.2010 Добавил проверку isnull при сравнении значений полей
--kadraliev MEG00032468 18.02.2011 
--			Добавил проверку на NULL при обновлении полей синхронизируемых данных
--          Добавил пакетное обновление данных
--			Добавил выборку top 1 по первичному ключу при проверке наличия несинхронизированных записей

if object_id('dbo.mwSyncDictionaryData', 'p') is not null
	drop proc dbo.mwSyncDictionaryData
go

create proc dbo.mwSyncDictionaryData 
	@update_search_table smallint = 0, -- нужно ли синхронизировать данные в mwPriceDataTable
	@update_fields varchar(1024) = NULL -- какие именно данные нужно синхронизировать
as
begin

	--<VERSION>2009.2.10</VERSION>
	--<DATE>2011-12-09</DATE>

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
	set @pdtUpdatePackageSize = (select count(*) from mwPriceDataTable with(nolock)) * @updatePackageSize / 100.0

	if (@pdtUpdatePackageSize <= 0)
		set @pdtUpdatePackageSize = @updatePackageSize

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
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='COUNTRY')
	begin
		-- mwSpoDataTable
		while exists(select top 1 sd_cnkey from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 cn_key from tbl_country with(nolock) 
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
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='HOTEL')
	begin
		-- mwSpoDataTable
		while exists(select top 1 sd_hdkey from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 hd_key from dbo.hoteldictionary with(nolock) where
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
			while exists(select top 1 pt_hdkey from dbo.mwPriceDataTable with(nolock) 
				where exists(select top 1 hd_key from dbo.hoteldictionary with(nolock) where
					pt_hdkey = hd_key
					and (
						isnull(pt_hdstars, '-1') <> isnull(hd_stars, '') or 
						isnull(pt_ctkey, -1) <> isnull(hd_ctkey, 0) or
						isnull(pt_rskey, -1) <> isnull(hd_rskey, 0) or
						isnull(pt_hdname, '-1') <> isnull(hd_name, '') or
						isnull(pt_hotelurl, '-1') <> isnull(hd_http, '')
					)
				)
			)
			begin
				update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
				set
					pt_hdstars = isnull(hd_stars, ''),
					pt_ctkey = isnull(hd_ctkey, 0),
					pt_rskey = isnull(hd_rskey, 0),
					pt_hdname = isnull(hd_name, ''),
					pt_hotelurl = isnull(hd_http, '')
				from
					dbo.hoteldictionary
				where
					pt_hdkey = hd_key
					and (
						isnull(pt_hdstars, '-1') <> isnull(hd_stars, '') or 
						isnull(pt_ctkey, -1) <> isnull(hd_ctkey, 0) or
						isnull(pt_rskey, -1) <> isnull(hd_rskey, 0) or
						isnull(pt_hdname, '-1') <> isnull(hd_name, '') or
						isnull(pt_hotelurl, '-1') <> isnull(hd_http, '')
					)
			end
		end
	end
	
	-- город отправления
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='CITY')
	begin
		-- mwSpoDataTable
		while exists(select top 1 sd_ctkeyfrom from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 ct_key from citydictionary with(nolock) 
				where sd_ctkeyfrom = ct_key and isnull(sd_ctfromname, '-1') <> isnull(ct_name, '')))
		begin
			update top (@sdtUpdatePackageSize) dbo.mwSpoDataTable
			set
				sd_ctfromname = isnull(ct_name,'')
			from
				dbo.citydictionary
			where
				sd_ctkeyfrom = ct_key and 
				isnull(sd_ctfromname, '-1') <> isnull(ct_name, '')
		end

		while exists(select top 1 sd_ctkey from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 ct_key from citydictionary with(nolock) 
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
			while exists(select top 1 pt_ctkey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 ct_key from dbo.citydictionary with(nolock) where
					pt_ctkey = ct_key and isnull(pt_ctname, '-1') <> isnull(ct_name, '')
				)
			)
			begin
				update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
				set
					pt_ctname = isnull(ct_name,'')
				from
					dbo.citydictionary
				where
					pt_ctkey = ct_key and 
					isnull(pt_ctname, '-1') <> isnull(ct_name, '')
			end
		end
	end
	
	--курорт
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='RESORT')
	begin
		-- mwSpoDataTable
		while exists(select top 1 sd_rskey from dbo.mwSpoDataTable with(nolock)
			where exists(select top 1 rs_key from dbo.resorts with(nolock) where
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
			while exists(select top 1 pt_rskey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 rs_key from dbo.resorts with(nolock) where
					pt_rskey = rs_key and isnull(pt_rsname, '-1') <> isnull(rs_name, '')
				)
			)		
			begin
				update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
				set
					pt_rsname = isnull(rs_name, '')
				from
					dbo.resorts
				where
					pt_rskey = rs_key and 
					isnull(pt_rsname, '-1') <> isnull(rs_name, '')
			end
		end
	end
	
	-- тур
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='TOUR')
	begin
		while exists(select 1 from dbo.mwSpoDataTable with(nolock)
			where exists(select 1 from dbo.tbl_turlist with(nolock) where
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
			while exists(select top 1 pt_tlkey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 tl_key from dbo.tbl_turlist with(nolock) where
					pt_tlkey = tl_key
					and (
						isnull(pt_tourname, '-1') <> isnull(tl_nameweb, '') or
						isnull(pt_toururl, '-1') <> isnull(tl_webhttp, '') or
						isnull(pt_tourtype, -1) <> isnull(tl_tip, 0)
					)
				)
			)
			begin
				update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
				set
					pt_tourname = isnull(tl_nameweb, ''),
					pt_toururl = isnull(tl_webhttp, ''),
					pt_tourtype = isnull(tl_tip, 0)
				from
					dbo.tbl_turlist
				where
					pt_tlkey = tl_key
					and (
						isnull(pt_tourname, '-1') <> isnull(tl_nameweb, '') or
						isnull(pt_toururl, '-1') <> isnull(tl_webhttp, '') or
						isnull(pt_tourtype, -1) <> isnull(tl_tip, 0)
					)
			end
		end
	end
	
	-- тип тура
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='TOURTYPE')
	begin
		while exists(select top 1 sd_tourtype from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 tp_key from dbo.tiptur with(nolock) 
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
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='PANSION')
	begin
		while exists(select top 1 sd_pnkey from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 pn_key from dbo.pansion with(nolock) 
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
			while exists(select top 1 pt_pnkey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 pn_key from dbo.pansion with(nolock) where
					pt_pnkey = pn_key
					and (
						isnull(pt_pnname, '-1') <> isnull(pn_name, '') or
						isnull(pt_pncode, '-1') <> isnull(pn_code, '')
					)
				)
			)
			begin
				update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
				set 
					pt_pnname = isnull(pn_name, ''),
					pt_pncode = isnull(pn_code, '')
				from dbo.pansion
				where
					pt_pnkey = pn_key
					and (
						isnull(pt_pnname, '-1') <> isnull(pn_name, '') or
						isnull(pt_pncode, '-1') <> isnull(pn_code, '')
					)
			end
		end
	end
	
	-- номер	
	if ((@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='ROOM')) and @update_search_table > 0
	begin
		while exists(select top 1 pt_rmkey from dbo.mwPriceDataTable with(nolock)
			where exists(select top 1 rm_key from dbo.rooms with(nolock) where
				pt_rmkey = rm_key
				and (
					isnull(pt_rmname, '-1') <> isnull(rm_name, '') or 
					isnull(pt_rmcode, '-1') <> isnull(rm_code, '') or 
					isnull(pt_rmorder, -1) <> isnull(rm_order, 0)
				)
			)
		)
		begin
			update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
			set
				pt_rmname = isnull(rm_name, ''),
				pt_rmcode = isnull(rm_code, ''),
				pt_rmorder = isnull(rm_order, 0)
			from
				dbo.rooms
			where
				pt_rmkey = rm_key
				and (
					isnull(pt_rmname, '-1') <> isnull(rm_name, '') or 
					isnull(pt_rmcode, '-1') <> isnull(rm_code, '') or 
					isnull(pt_rmorder, -1) <> isnull(rm_order, 0)
				)			
		end
	end
	
	-- категория номера
	if ((@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='ROOMCATEGORY')) and @update_search_table > 0
	begin
		while exists(select top 1 pt_rckey from dbo.mwPriceDataTable with(nolock)
			where exists(select top 1 rc_key from dbo.roomscategory with(nolock) where
				pt_rckey = rc_key
				and (
					isnull(pt_rcname, '-1') <> isnull(rc_name, '') or 
					isnull(pt_rccode, '-1') <> isnull(rc_code, '') or 
					isnull(pt_rcorder, -1) <> isnull(rc_order, 0)
				)
			)
		)
		begin
			update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
			set
				pt_rcname = isnull(rc_name, ''),
				pt_rccode = isnull(rc_code, ''),
				pt_rcorder = isnull(rc_order, 0)
			from
				dbo.roomscategory
			where
				pt_rckey = rc_key
				and (
					isnull(pt_rcname, '-1') <> isnull(rc_name, '') or 
					isnull(pt_rccode, '-1') <> isnull(rc_code, '') or 
					isnull(pt_rcorder, -1) <> isnull(rc_order, 0)
				)
		end
	end
	
	-- размещение
	--kadraliev MEG00029412 29.09.2010 Добавил синхронизацию признака isMain, возрастов детей
	if ((@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='ACCOMODATION')) and @update_search_table > 0
	begin	
		while exists(select top 1 pt_ackey from dbo.mwPriceDataTable with(nolock)
			where exists(select top 1 ac_key from dbo.accmdmentype with(nolock) where
				pt_ackey = ac_key
				and (
					isnull(pt_acname, '-1') <> isnull(ac_name, '') or
					isnull(pt_accode, '-1') <> isnull(ac_code, '') or
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
			update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
			set
				pt_acname = isnull(ac_name, ''),
				pt_accode = isnull(ac_code, ''),
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
					isnull(pt_acname, '-1') <> isnull(ac_name, '') or
					isnull(pt_accode, '-1') <> isnull(ac_code, '') or
					isnull(pt_acorder, -1) <> isnull(ac_order, 0) or
					isnull(pt_main, -1) <> isnull(ac_main, 0) or
					isnull(pt_childagefrom, -1) <> isnull(ac_agefrom, 0) or
					isnull(pt_childageto, -1) <> isnull(ac_ageto, 0) or
					isnull(pt_childagefrom2, -1) <> isnull(ac_agefrom2, 0) or
					isnull(pt_childageto2, -1) <> isnull(ac_ageto2, 0)	
				)
		end
	end

	--kadraliev MEG00029412 29.09.2010 номер и размещение (количество основных и дополнительных мест)
	if ((@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='ROOM' or fname='ACCOMODATION')) and @update_search_table > 0
	begin	
		while exists(select top 1 pt_key 
					 from mwPriceDataTable with(nolock)
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
			update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
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
			from dbo.mwPriceDataTable orig with(nolock)
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
	end

	-- расчитанный тур
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='TP_TOUR')
	begin
		while exists(select top 1 sd_tourkey from dbo.mwSpoDataTable with(nolock)
			where exists(select top 1 to_key from dbo.tp_tours with(nolock) where
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
			while exists(select top 1 pt_tourkey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 to_key from dbo.tp_tours with(nolock) where
					pt_tourkey = to_key
					and (
						isnull(pt_tourcreated, '1900-01-02') <> isnull(to_datecreated, '1900-01-01') or 
						isnull(pt_tourvalid, '1900-01-02') <> isnull(to_datevalid, '1900-01-01') or 
						isnull(pt_rate, '-1') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '') COLLATE DATABASE_DEFAULT
					)
				)
			)
			begin
				update top (@pdtUpdatePackageSize) dbo.mwPriceDataTable
				set
					pt_tourcreated = isnull(to_datecreated, '1900-01-01'),
					pt_tourvalid = isnull(to_datevalid, '1900-01-01'),
					pt_rate = isnull(to_rate, '')
				from
					dbo.tp_tours
				where
					pt_tourkey = to_key
					and (
						isnull(pt_tourcreated, '1900-01-02') <> isnull(to_datecreated, '1900-01-01') or 
						isnull(pt_tourvalid, '1900-01-02') <> isnull(to_datevalid, '1900-01-01') or 
						isnull(pt_rate, '-1') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '') COLLATE DATABASE_DEFAULT
					)
			end			
		end
	end
end
go

grant exec on dbo.mwSyncDictionaryData to public
go
/*********************************************************************/
/* end sp_mwSyncDictionaryData.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetDogovorState.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetDogovorState]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetDogovorState]
GO

CREATE PROCEDURE [dbo].[SetDogovorState]
	(
		--<version>2009.2.01<version/>
		--<data>2011-11-16<data/>
		@dg_key int
	)
AS
BEGIN
	declare @new_dg_sor_code int, @new_dg_sor_code_duble_dogovor int, @old_dg_sor_code int
	declare @dg_code varchar(10), @dTour datetime, @dtCurrentDate datetime
	
	select @dg_code = DG_CODE, @dTour = DG_TurDate, @dtCurrentDate = GETDATE(), @old_dg_sor_code = dg_sor_code
	from Dogovor
	where DG_Key = @dg_key
	-- если путевка анулированна то выходим
	if (@dTour = '18991230')
	begin
		return;
	end
	
	-- сначала ужно установить статусы услуг в путевки в зависимости от статуса квотирования
	exec SetServiceStatus @dg_key

	-- получаем новые статусы
	exec GetDogovorStateId @dg_key, @new_dg_sor_code output, @new_dg_sor_code_duble_dogovor output
	if (@new_dg_sor_code_duble_dogovor is not null)
	begin
		-- если мы получили новый статус договора по дублирующей путевке то установим его, вместо статуса по правилам
		set @new_dg_sor_code = @new_dg_sor_code_duble_dogovor
	end

	IF @new_dg_sor_code is not null and @old_dg_sor_code != @new_dg_sor_code
	BEGIN			
		update dbo.tbl_Dogovor
		set dg_sor_code = @new_dg_sor_code
		where dg_key = @dg_key 
		and DG_TURDATE != '18991230'
		and dg_sor_code != @new_dg_sor_code
					
		exec dbo.CreatePPaymentDate @dg_code, @dTour, @dtCurrentDate
	END
END
GO
grant exec on [dbo].[SetDogovorState] to public
GO
/*********************************************************************/
/* end sp_SetDogovorState.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetServiceStatus.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetServiceStatus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetServiceStatus]
GO
CREATE PROCEDURE [dbo].[SetServiceStatus]
	(
		-- хранимка устанавливает статусы услуг в путевке в зависимости от статусов квотирования		
		--<version>2009.2.01</version>
		--<data>2011-11-23</data>
		@dg_key int -- ключ путевки
	)
AS
BEGIN
	declare @dlKey int, @dlControl int, @dlPartnerKey int

	declare setDogovorListStatusCursor cursor read_only fast_forward for
	select DL_Key, DL_Control, DL_PARTNERKEY
	from tbl_dogovorList join [service] on dl_svkey = sv_key
	where dl_dgkey = @dg_key
	and isnull(SV_QUOTED, 0) = 1
	
	open setDogovorListStatusCursor
	fetch next from setDogovorListStatusCursor into @dlKey, @dlControl, @dlPartnerKey
	while @@fetch_status = 0
	begin
		declare @newdlControl int
		set @newdlControl = null
		
		-- если эта услуга не из интерлука, то проститаем ее статус относительно статуса квотирования
		if (not exists (select top 1 1 from dbo.SystemSettings where SS_ParmName = 'IL_SyncILPartners' and SS_ParmValue LIKE '%/' + convert(nvarchar(max) ,@dlPartnerKey) + '/%'))
		begin
			exec SetServiceStatusOK @dlKey, @newdlControl out
		end
		
		if (@newdlControl != @dlControl and @newdlControl is not null)
		begin
			update tbl_dogovorList
			set DL_Control = @newdlControl
			where DL_Key = @dlKey
			and DL_Control != @newdlControl
		end	
		
		fetch next from setDogovorListStatusCursor into @dlKey, @dlControl, @dlPartnerKey
	end
	
	close setDogovorListStatusCursor
	deallocate setDogovorListStatusCursor
END

GO
grant exec on [dbo].[SetServiceStatus] to public
go
/*********************************************************************/
/* end sp_SetServiceStatus.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_DogovorUpdate.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_DogovorUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_DogovorUpdate]
GO

CREATE TRIGGER [T_DogovorUpdate]
ON [dbo].[tbl_Dogovor] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2009.2.30.1</VERSION>
--<DATE>2011-11-10</DATE>
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
	DECLARE @NDG_BTKey int

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
	
	declare @DLKey int, @DLDateBeg datetime, @DLDateEnd datetime
	
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
		N.DG_LEADDEPARTMENT, N.DG_DupUserKey, N.DG_MainMen, N.DG_MainMenEMail, N.DG_MAINMENPHONE, N.DG_CodePartner, N.DG_Creator, N.DG_CTDepartureKey, N.DG_Payed, N.DG_BTKey
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
		null, null, null, null, null, null, null, null, null, null
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
		N.DG_LEADDEPARTMENT, N.DG_DupUserKey, N.DG_MainMen, N.DG_MainMenEMail, N.DG_MAINMENPHONE, N.DG_CodePartner, N.DG_Creator, N.DG_CTDepartureKey, N.DG_Payed, N.DG_BTKey
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
		@NDG_LEADDEPARTMENT, @NDG_DupUserKey, @NDG_MainMen, @NDG_MainMenEMail, @NDG_MAINMENPHONE, @NDG_CodePartner, @NDG_Creator, @NDG_CTDepartureKey, @NDG_Payed, @NDG_BTKey

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

			DECLARE @IsAutoBlockMWDogovors int;
			SELECT @IsAutoBlockMWDogovors = SS_ParmValue FROM SystemSettings WHERE SS_ParmName = 'SYSAutoBlockMWDogovors'
			IF (ISNULL(@IsAutoBlockMWDogovors, 0) = 1 AND @NDG_BTKey = 1)
				UPDATE [dbo].[tbl_Dogovor] SET DG_Locked = 1 WHERE DG_Key = @DG_Key
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
				begin
					select @changedDate = MAX(HI_DATE) from history where HI_OAID = 20 and hi_dgcod = @ODG_CODE                     
                    If @changedDate is null
						SET @changedDate=GetDate()
				end


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
				UPDATE DogovorList 
				   SET DL_AGENT = @NDG_PartnerKey
				 WHERE DL_DGKEY = @DG_Key;
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
			declare curSetQuoted CURSOR FORWARD_ONLY for
						select DL_KEY, DL_DATEBEG, DL_DATEEND
						from Dogovorlist join [Service] on SV_KEY = DL_SVKEY
						where DL_DGKEY = @DG_Key
						and isnull(SV_IsDuration, 0) = 0
			OPEN curSetQuoted
			FETCH NEXT FROM curSetQuoted INTO @DLKey, @DLDateBeg, @DLDateEnd

			WHILE @@FETCH_STATUS = 0
			BEGIN
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
				BEGIN
					EXECUTE dbo.InsertHistoryDetail @nHIID, 1122, null, null, null, null, null, null, 1, @bNeedCommunicationUpdate output
				END
				------путевка была аннулирована--------------
				if (@NDG_SOR_Code = 2 and @sMod = 'UPD')
					EXECUTE dbo.InsertHistoryDetail @nHIID, 1123, null, null, null, null, null, null, 1, @bNeedCommunicationUpdate output
				
				if @bStatusChanged > 0
				begin
					declare @CanExecute bit
					set @CanExecute = 0

					declare @Occurancy tinyint
					set @Occurancy = (select NC_Multiplicity from NationalCurrencyReservationStatuses with(nolock) where NC_OrderStatus = ISNULL(@NDG_SOR_Code, 0) and NC_IsGlobal = 0)
	
					if @Occurancy = 1
					    begin
							if (select count(*) from History,HistoryDetail where HI_ID = HD_HIID and HI_DGKEY = @DG_Key and HD_OAId = 1019 and HD_IntValueNew = @NDG_SOR_Code) = 1
								set @CanExecute = 1
						end		
					else if @Occurancy = 2
						set @CanExecute = 1
					else
						begin
							declare @GlobalSorCode int
							set @GlobalSorCode = (select OS_Global from Order_Status where OS_Code = ISNULL(@NDG_SOR_Code, 0)) 
							set @Occurancy = (select NC_Multiplicity from NationalCurrencyReservationStatuses with(nolock) where NC_OrderStatus = ISNULL(@GlobalSorCode, 0) and NC_IsGlobal = 1)
			
							if @Occurancy = 1
								begin
									if (select count(*) from History,HistoryDetail where HI_ID = HD_HIID and HI_DGKEY = @DG_Key and HD_OAId = 1019 and HD_IntValueNew = @NDG_SOR_Code) = 1
										set @CanExecute = 1
								end		
							else if @Occurancy = 2
								set @CanExecute = 1
						end	
	
					if @CanExecute = 1
					begin
						if (@bCurrencyChangedPrevFixDate > 0)
							set @changedDate = ISNULL(dbo.GetFirstDogovorStatusDate (@DG_Key, @NDG_SOR_Code), GetDate())
					
						SET @bUpdateNationalCurrencyPrice = 1
					end
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

    	  FETCH NEXT FROM cur_Dogovor INTO @DG_Key,
			@ODG_Code, @ODG_Price, @ODG_Rate, @ODG_DiscountSum, @ODG_PartnerKey, @ODG_TRKey, @ODG_TurDate, @ODG_CTKEY, @ODG_NMEN, @ODG_NDAY, 
			@ODG_PPaymentDate, @ODG_PaymentDate, @ODG_RazmerP, @ODG_Procent, @ODG_Locked, @ODG_SOR_Code, @ODG_IsOutDoc, @ODG_VisaDate, @ODG_CauseDisc, @ODG_OWNER, 
			@ODG_LEADDEPARTMENT, @ODG_DupUserKey, @ODG_MainMen, @ODG_MainMenEMail, @ODG_MAINMENPHONE, @ODG_CodePartner, @ODG_Creator, @ODG_CTDepartureKey, @ODG_Payed,
			@NDG_Code, @NDG_Price, @NDG_Rate, @NDG_DiscountSum, @NDG_PartnerKey, @NDG_TRKey, @NDG_TurDate, @NDG_CTKEY, @NDG_NMEN, @NDG_NDAY, 
			@NDG_PPaymentDate, @NDG_PaymentDate, @NDG_RazmerP, @NDG_Procent, @NDG_Locked, @NDG_SOR_Code, @NDG_IsOutDoc, @NDG_VisaDate, @NDG_CauseDisc, @NDG_OWNER, 
			@NDG_LEADDEPARTMENT, @NDG_DupUserKey, @NDG_MainMen, @NDG_MainMenEMail, @NDG_MAINMENPHONE, @NDG_CodePartner, @NDG_Creator, @NDG_CTDepartureKey, @NDG_Payed,
			@NDG_BTKey
    END
  CLOSE cur_Dogovor
  DEALLOCATE cur_Dogovor
END
GO
/*********************************************************************/
/* end T_DogovorUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_mwUpdateHotel.sql */
/*********************************************************************/
--<VERSION>ALL</VERSION>
--<DATE>2012-01-30</DATE>


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwUpdateHotel]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[mwUpdateHotel]
GO

CREATE TRIGGER [mwUpdateHotel] ON [dbo].[HotelDictionary] 
FOR UPDATE 
AS
IF @@ROWCOUNT > 0
begin
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

			select hd_key, hd_rskey, hd_stars, hd_name, HD_HTTP into #temp from inserted

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

/*********************************************************************/
/* end T_mwUpdateHotel.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Version92.sql */
/*********************************************************************/
-- для версии 2009.2
update [dbo].[setting] set st_version = '9.2.11', st_moduledate = convert(datetime, '2011-12-27', 120),  st_financeversion = '9.2.11', st_financedate = convert(datetime, '2011-12-27', 120) where st_version like '9.%'
GO
UPDATE dbo.SystemSettings SET SS_ParmValue='2011-12-27' WHERE SS_ParmName='SYSScriptDate'
GO
/*********************************************************************/
/* end Version92.sql */
/*********************************************************************/

/*********************************************************************/
/* begin x_tp_services_1(tp_services).sql */
/*********************************************************************/
--if exists (select 1 from sysindexes where name='X_TP_SERVICES_1' and id = object_id(N'TP_Services'))
--	drop index [TP_Services].[X_TP_SERVICES_1]
--go

--declare @sql nvarchar (4000)
--if @@Version like '%SQL%Server%2000%' 
-- set @sql = 'create index [X_TP_SERVICES_1] on [dbo].[TP_Services] 
--	([TS_TOKey]
--	,[TS_SVKey]
--	,[TS_Key]
--	,[TS_Code]
--	,[TS_SubCode1]
--	,[TS_SubCode2]
--	,[TS_CTKey]
--	,[TS_Day]
--	,[TS_OpPartnerKey]
--	,[TS_OpPacketKey]
--	)'
--else
-- set @sql = 'CREATE NONCLUSTERED INDEX [X_TP_SERVICES_1] ON [dbo].[TP_Services] 
--(
--     [TS_TOKey] ASC,
--     [TS_SVKey] ASC
--)
--INCLUDE ( [TS_Key],
--[TS_Code],
--[TS_SubCode1],
--[TS_SubCode2],
--[TS_CTKey],
--[TS_Day],
--[TS_OpPartnerKey],
--[TS_OpPacketKey]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'

--exec sp_executesql @sql
--go
/*********************************************************************/
/* end x_tp_services_1(tp_services).sql */
/*********************************************************************/
