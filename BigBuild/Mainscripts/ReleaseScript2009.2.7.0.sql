-- (100126)mwTop5TourDates.sql
if exists(select id from sysobjects where xtype='fn' and name='mwTop5TourDates')
	drop function dbo.[mwTop5TourDates]
go

CREATE function [dbo].[mwTop5TourDates] (@cnkey int, @priceTourKey int, @tourkey int, @useLinks smallint) returns nvarchar(1024)
as
begin
	declare @now datetime
	select @now = currentDate from dbo.mwCurrentDate

	declare @result nvarchar(1024)
	set @result = ''

	declare @lastDate datetime
	if (@useLinks > 0)
	begin
		select top 5 @lastDate = td_date, @result = @result + N'<a target="_blank" title="Нажмите для перехода на ценовой лист" href="../pricelist/complex.aspx?country=' + ltrim(str(@cnkey)) + N'&tour=' + ltrim(str(@priceTourKey)) + N'&dateFrom=' + dbo.mwDateToStrParam(td_date) + N'">' + dbo.mwDateToStr(td_date, 0, 0) + N'</a>, ' from turdate where td_trkey = @tourkey and td_date > @now
	end
	else
	begin
		select top 5 @lastDate = td_date, @result = @result + dbo.mwDateToStr(td_date, 0, 0) + N', ' from turdate where td_trkey = @tourkey and td_date > @now
	end

	declare @len int
	set @len = len(@result)
	if(@len > 0)
		set @result = substring(@result, 1, @len - 1)

	declare @maxDate datetime
	select @maxDate = max(td_date) from turdate where td_trkey = @tourkey and td_date >= @now

	if(@maxDate > @lastDate and @len > 0) 
	begin
		if (@useLinks > 0)
		begin
			set @result = @result + N', ... , ' + N'<a target="_blank" title="Нажмите для перехода на ценовой лист" href="../pricelist/complex.aspx?country=' + ltrim(str(@cnkey)) + N'&tour=' + ltrim(str(@priceTourKey)) + N'&dateFrom=' + dbo.mwDateToStrParam(@maxDate) + N'">' + dbo.mwDateToStr(@maxDate, 1, 0) + N'</a>'
		end
		else
		begin
			set @result = @result + N', ... , ' + dbo.mwDateToStr(@maxDate, 1, 0)
		end

	end

	return @result
end

GO

grant exec on [dbo].[mwTop5TourDates] to public

GO

-- 20100126_AlterTables_Descriptions.sql
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Pansion]') and name = 'PN_Description')
	alter table dbo.Pansion ADD PN_Description text
GO

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[AccmdMenType]') and name = 'AC_Description')
	alter table dbo.AccmdMenType ADD AC_Description text
GO

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[CategoriesOfHotel]') and name = 'COH_Description')
	alter table dbo.CategoriesOfHotel ADD COH_Description text
GO

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[RoomsCategory]') and name = 'RC_Description')
	alter table dbo.RoomsCategory ADD RC_Description text
GO

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Rooms]') and name = 'RM_Description')
	alter table dbo.Rooms ADD RM_Description text
GO

-- 20100128_DropTriggerTurList.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_TurListUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_TurListUpdate]
GO

-- sp_DeleteDiscountCard.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteDiscountCard]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[DeleteDiscountCard]
GO

create procedure dbo.DeleteDiscountCard
	@cardKey int
as
begin
	delete from DogovorDetails where DD_CardKey = @cardKey
	delete from Cards where CD_Key = @cardKey
end
GO

GRANT EXECUTE ON dbo.DeleteDiscountCard TO PUBLIC
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

-- 100128(Alter COLUMN DG_MAINMENADRESS).sql
--MEG00025189
if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS
	where TABLE_SCHEMA='dbo' and TABLE_NAME='tbl_Dogovor' and COLUMN_NAME='DG_MAINMENADRESS')<320)
ALTER TABLE dbo.tbl_Dogovor ALTER COLUMN DG_MAINMENADRESS varchar(320) NULL
GO


-- T_StopSalesChange.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_StopSalesChange]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_StopSalesChange]
GO

CREATE TRIGGER [dbo].[T_StopSalesChange]
ON [dbo].[StopSales] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2008.1.01.02a</VERSION>
IF @@ROWCOUNT > 0
BEGIN
	DECLARE @QO_SVKey int, @QO_Code int, @QO_SubCode1 int, @QO_SubCode2 int, @SS_ID int,
			@OSS_PRKey int, @OSS_Date datetime, @OSS_IsDeleted smallint, @OSS_QDID int,
			@NSS_PRKey int, @NSS_Date datetime, @NSS_IsDeleted smallint, @NSS_QDID int,
			@SS_PRKey int, @SS_Date datetime, @SS_QDID int

    DECLARE @sText_Old varchar(255), @sText_New varchar(255), @sHI_Text varchar(255)
    DECLARE @sMod varchar(3), @nDelCount int, @nInsCount int, @nHIID int

	SELECT @nDelCount = COUNT(*) FROM DELETED
	SELECT @nInsCount = COUNT(*) FROM INSERTED
	IF (@nDelCount = 0)
	BEGIN
		SET @sMod = 'INS'
		DECLARE cur_StopSales CURSOR LOCAL FOR 
			SELECT	QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2, N.SS_ID,
					null, null, null, null,
					N.SS_PRKey, N.SS_Date, N.SS_IsDeleted, N.SS_QDID
			FROM	INSERTED N, dbo.QuotaObjects
			WHERE	N.SS_QOID=QO_ID
	END
	ELSE IF (@nInsCount = 0)
	BEGIN
		SET @sMod = 'DEL'
		DECLARE cur_StopSales CURSOR LOCAL FOR 
			SELECT	QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2, O.SS_ID,
					O.SS_PRKey, O.SS_Date, O.SS_IsDeleted, O.SS_QDID,
					null, null, null, null
			FROM	DELETED O, dbo.QuotaObjects
			WHERE	O.SS_QOID=QO_ID
	END
	ELSE 
	BEGIN
		SET @sMod = 'UPD'
		DECLARE cur_StopSales CURSOR LOCAL FOR
			SELECT	QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2, N.SS_ID,
					O.SS_PRKey, O.SS_Date, O.SS_IsDeleted, O.SS_QDID,
					N.SS_PRKey, N.SS_Date, N.SS_IsDeleted, N.SS_QDID
			FROM	DELETED O, INSERTED N, dbo.QuotaObjects
			WHERE	N.SS_QOID=QO_ID and O.SS_ID=N.SS_ID
	END
	OPEN cur_StopSales
	FETCH NEXT FROM cur_StopSales INTO 
			@QO_SVKey, @QO_Code, @QO_SubCode1, @QO_SubCode2, @SS_ID,
			@OSS_PRKey, @OSS_Date, @OSS_IsDeleted, @OSS_QDID,
			@NSS_PRKey, @NSS_Date, @NSS_IsDeleted, @NSS_QDID
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OSS_PRKey, 0) != ISNULL(@NSS_PRKey, 0) OR
			ISNULL(@OSS_Date, GetDate()) != ISNULL(@NSS_Date, GetDate()) OR
			ISNULL(@OSS_IsDeleted, 0) != ISNULL(@NSS_IsDeleted, 0)
			)
		BEGIN
			------------Запись в историю--------------------------------------------------------------------
			If @sMod = 'DEL'
			BEGIN
				Set @SS_PRKey=@OSS_PRKey
				Set @SS_Date=@OSS_Date
				Set @SS_QDID=@OSS_QDID
			END
			Else
			BEGIN
				Set @SS_PRKey=@NSS_PRKey
				Set @SS_Date=@NSS_Date
				Set @SS_QDID=@NSS_QDID
			END
			
			--insert into Debug(db_n1,db_n2,db_n3) values (361,@QO_SVKey,@QO_SubCode1)
			If @QO_SubCode1 is not null
				exec dbo.GetServiceNameByCode 4,@QO_SVKey,null,@QO_SubCode1,null,1,@sHI_Text output,null
			If ISNULL(@sHI_Text,'')!=''
				Set @sText_New=@sHI_Text
			Set @sHI_Text=null
			--insert into Debug(db_n1,db_n2,db_n3) values (362,@QO_SVKey,@QO_SubCode2)
			If @QO_SubCode2 is not null
				exec dbo.GetServiceNameByCode 5,@QO_SVKey,null,null,@QO_SubCode2,1,@sHI_Text output,null
			If ISNULL(@sHI_Text,'')!=''
				Set @sText_New=@sText_New + ',' + @sHI_Text
			Set @sHI_Text=null
			If @SS_PRKey=0
				Set @sHI_Text='All partners'
			Else
				Select @sHI_Text=PR_Name from Partners where PR_Key=@SS_PRKey
			If ISNULL(@sText_New,'')!=''
				Set @sText_New=@sText_New + ' (' + @sHI_Text + ')'
			Else
				Set @sText_New=@sHI_Text
			Set @sHI_Text=null
			
			SET @sHI_Text='A'
			If @SS_QDID is not null
				if exists (SELECT 1 FROM dbo.QuotaDetails WHERE QD_ID=@SS_QDID and QD_Type=2)
					SET @sHI_Text='C'
			Set @sHI_Text=@sHI_Text+' (' + CONVERT(varchar(20),@SS_Date,104)+')'

			IF @NSS_IsDeleted=1 and ISNULL(@OSS_IsDeleted,0)=0
				SET @sMod='DEL'
			--EXEC @nHIID = dbo.InsHistory '', null, 14, @SS_Id, @sMod, @sText_New, '', 0, @sHI_Text, 0, @QO_SVKey, @QO_Code
			EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 14,
							@nTypeCode = @SS_ID,
							@sMod = @sMod,
							@sText = @sText_New,
							@sRemark = @sHI_Text,
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = @QO_SVKey,
							@nCode = @QO_Code
			SET @sText_Old=''
			SET @sText_New=''
			--------Детализация--------------------------------------------------
			if ISNULL(@OSS_PRKey, -1) != ISNULL(@NSS_PRKey, -1)
			BEGIN
				If @OSS_PRKey=0
					Set @sText_Old='All partners'
				Else If @OSS_PRKey is not null
					Select @sText_Old=PR_Name from Partners where PR_Key=@OSS_PRKey
				If @NSS_PRKey=0
					Set @sText_New='All partners'
				Else If @NSS_PRKey is not null
					Select @sText_New = PR_Name from Partners where PR_Key=@NSS_PRKey
				EXECUTE dbo.InsertHistoryDetail @nHIID, 14001, @sText_Old, @sText_New, @OSS_PRKey, @NSS_PRKey, null, null, 0
				SET @sText_Old=''
				SET @sText_New=''				
			END
			if ISNULL(@OSS_Date, GetDate()) != ISNULL(@NSS_Date, GetDate())
			BEGIN
				If @OSS_Date is not null
					Set @sText_Old=CONVERT(varchar(20),@OSS_Date,104)
				If @NSS_Date is not null
					Set @sText_New=CONVERT(varchar(20),@NSS_Date,104)
				EXECUTE dbo.InsertHistoryDetail @nHIID, 14002, @sText_Old, @sText_New, null, null, @OSS_Date, @NSS_Date, 0
				SET @sText_Old=''
				SET @sText_New=''
			END	
			
			Update StopSales set SS_LastUpdate = GetDate() where SS_ID = @SS_ID	
		END
		FETCH NEXT FROM cur_StopSales INTO 
			@QO_SVKey, @QO_Code, @QO_SubCode1, @QO_SubCode2, @SS_ID,
			@OSS_PRKey, @OSS_Date, @OSS_IsDeleted, @OSS_QDID,
			@NSS_PRKey, @NSS_Date, @NSS_IsDeleted, @NSS_QDID
    END
	CLOSE cur_StopSales
	DEALLOCATE cur_StopSales
END
GO

-- (100111)fn_mwGetTiNights.sql
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
	set @currday = 1

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

-- 100129(StopSale_AddColumn).sql
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[StopSales]') and name = 'SS_LastUpdate')
	ALTER TABLE dbo.StopSales ADD SS_LastUpdate datetime NULL
GO

-- fn_mwGetFullHotelNames.sql
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


-- sp_mwGetSpoList.sql
if exists(select id from sysobjects where xtype='p' and name='mwGetSpoList')
	drop proc dbo.mwGetSpoList
go

create procedure [dbo].[mwGetSpoList] @spoType int, @sort varchar(100), @filter varchar(300)
as
begin
if (len(isnull(@sort, '')) = 0 and len(isnull(@filter, '')) = 0)
	select cn_key, cn_name, cn_namelat, sd_tourkey as tokey, sd_tlkey as tlkey, sd_tourcreated as tourcreated, to_datevalid as datevalid, case when len(isnull(tl_webhttp, '')) > 0 then ('<a href=''' + tl_webhttp + ''' target=''_blank''>' + tl_nameweb + '</a>') else tl_nameweb end as tourname, dbo.mwGetSpoRegionNames(sd_tourkey) as regions,
		dbo.mwGetSpoHotelNames(sd_tourkey, 1) as hotels, CONVERT(varchar(10), to_datebegin, 21) as mindate, CONVERT(varchar(10), to_dateend, 21) as maxdate
	from 
		(select distinct sd_cnkey, sd_tourkey, sd_tlkey, sd_tourcreated, to_datevalid, to_datebegin, to_dateend 
		from dbo.mwSpoData 
			inner join tp_tours with(nolock) on sd_tourkey = to_key where to_datevalid >= getdate() and (to_attribute & @spoType) > 0)
		 as tbl 
		inner join country on tbl.sd_cnkey = cn_key 
		inner join turlist on tbl.sd_tlkey = tl_key
	order by cn_name, sd_tourcreated desc
else
begin
	if len(isnull(@filter, '')) != 0
		set @filter = ' and ' + @filter
	if len(isnull(@sort, '')) = 0
		set @sort = ' cn_name, sd_tourcreated desc'
	declare @sql varchar(4000)
	set @sql = 'select cn_key, cn_name, cn_namelat, sd_tourkey as tokey, sd_tlkey as tlkey, sd_tourcreated as tourcreated, to_datevalid as datevalid, case when len(isnull(tl_webhttp, '''')) > 0 then (''<a href='''''' + tl_webhttp + '''''' target=''''_blank''''>'' + tl_nameweb + ''</a>'') else tl_nameweb end as tourname, dbo.mwGetSpoRegionNames(sd_tourkey) as regions,
		dbo.mwGetSpoHotelNames(sd_tourkey, 1) as hotels, CONVERT(varchar(10), to_datebegin, 21) as mindate, CONVERT(varchar(10), to_dateend, 21) as maxdate
	from (select distinct sd_cnkey, sd_tourkey, sd_tlkey, sd_tourcreated, to_datevalid, to_datebegin, to_dateend from dbo.mwSpoData inner join tp_tours with(nolock) on sd_tourkey = to_key where to_datevalid >= getdate() and (to_attribute & ' + ltrim(rtrim(@spoType)) + ') > 0 ' + @filter + ') as tbl inner join country on tbl.sd_cnkey = cn_key inner join turlist on tbl.sd_tlkey = tl_key
	order by ' + @sort
	exec(@sql)
end
end
go

grant exec on dbo.mwGetSpoList to public
go

-- 100208(AddSetting).sql
if not exists( select 1 from dbo.SystemSettings where ss_parmname= 'INSIncludePolicyInBordero' )
	insert into [dbo].SystemSettings (ss_parmname,ss_parmvalue) values ('INSIncludePolicyInBordero','Manual')
GO

-- sp_InsPoliciesAddBordero.sql
if exists(select id from sysobjects where xtype='p' and name='InsPoliciesAddBordero')
	drop proc dbo.InsPoliciesAddBordero
go

create procedure [dbo].InsPoliciesAddBordero @borderoId  int
AS
BEGIN
  DECLARE @AgentKey int
  DECLARE @PartnerKey int

  SELECT @AgentKey = IBR_IAGID, @PartnerKey = IBR_PRKEY
  FROM InsBordero
  WHERE IBR_ID = @borderoId

  -- все не аннулированные, распечатанные, не включенные в др. бордеро полисы привязываем к этому бордеро
  UPDATE InsPolicy
  SET IP_IBRID = @borderoId
  WHERE IP_IBRID IS NULL
		AND IP_IBRID_ANNUL IS NULL
		AND IP_ANNULDATE IS NULL
		AND DBO.INSGETPOLICYSTATUS(IP_ID) = 1
        AND IP_IAGID = @AgentKey 
        AND IP_PRKEY = @PartnerKey
		-- для физ лица должна быть распечатана справка A7 
		AND (dbo.InsIsA7Print (IP_ID) = 1 
			OR IP_IAGID IN 
				(SELECT IAG_ID FROM InsAgents 
					WHERE InsPolicy.IP_IAGID = IAG_ID AND IAG_IsJuridical = 1)
			)
END

go

grant exec on dbo.InsPoliciesAddBordero to public
go


-- 100126(UpdateTable_Keys).sql
if object_id('dbo.keys') is not null
begin
	if not exists (select null from keys where key_table='TP_TOURDATES')
		insert into keys (key_table, id) values ('TP_TOURDATES', 2);

	declare @tu_count int
	declare @tou_count int

	select @tu_count = isnull(id, 2) from keys where key_table='TP_TURDATES';
	select @tou_count = isnull(id, 0) from keys where key_table='TP_TOURDATES';

	if @tu_count > @tou_count
		update keys set id = @tu_count where key_table='TP_TOURDATES';
end
GO

-- sp_GetNKey.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetNKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetNKey]
GO
CREATE PROCEDURE [dbo].[GetNKey]
  (@sTable varchar(50) = null,
  @nNewKey int = null output)
AS
-- MT 2005.2.33
declare @nID int
if @sTable = 'TP_TURDATES'
	set @sTable = 'TP_TOURDATES'
set nocount on
	update Keys WITH (ROWLOCK) set @nNewKey = Id = (Select id from Keys where Key_Table = @sTable) + 1 where Key_Table = @sTable
	if @nNewKey is Null
		begin
			insert into Keys (Key_Table, Id) values (@sTable, 2)
			set @nNewKey=1
		end
return 0
GO
GRANT EXECUTE ON [dbo].[GetNKey] TO Public
GO

-- sp_GetNKeys.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetNKeys]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetNKeys]
GO

CREATE PROCEDURE [dbo].[GetNKeys]
  (@sTable varchar(50) = null,
  @nKeyCount int,
  @nNewKey int = null output)
AS
-- MT 2005.2.31
declare @nID int
set nocount on
if @nKeyCount is null
	set @nKeyCount = 0
if @sTable = 'TP_TURDATES'
	set @sTable = 'TP_TOURDATES'
update Keys WITH (ROWLOCK) set @nNewKey = Id = (Select id from Keys where Key_Table = @sTable) + @nKeyCount where Key_Table = @sTable
if @nNewKey is Null
	begin
		insert into Keys (Key_Table, Id) values (@sTable, 2)
		set @nNewKey=@nKeyCount
	end
return 0
GO

GRANT EXECUTE ON [dbo].[GetNKeys] TO Public
GO

-- fn_mwCheckQuotesEx2.sql
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
-- date 2009-03-26 15:40
begin
	if (@svkey = 1)
	begin
		declare @tariffToStop varchar(20)
		set @tariffToStop = ',' + ltrim(str(@subcode1)) + ','
		if exists(select 1 from dbo.systemsettings where ss_parmname='MWTariffsToStop' and charindex(@tariffToStop, ',' + ss_parmvalue + ',') > 0)
			set @noPlacesResult = 0
	end

--	insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
--		qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
--	values(0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, '')
--		return 

	declare @ALLDAYS_CHECK int
	set @ALLDAYS_CHECK = -777
--	declare @STOP_SALE int
--	set @STOP_SALE = 777

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
	else if(@svkey <> 3)
		set @subcode2 = 0
				
	
	declare @result int
	declare @currentDate datetime
	select @currentDate = currentDate from dbo.mwCurrentDate


	declare @qtSvkey int, @qtCode int, @qtSubcode1 int, @qtSubcode2 int, @qtAgent int,
		@qtPrkey int, @qtNotcheckin int, @qtRelease int, @qtPlaces int, @qtDate datetime,
		@qtByroom int, @qtType int, @qtLong int, @qtPlacesAll int, @qtStop smallint

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
		qt_stop smallint
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
					where ch_key = @code and as_week like ('%' + cast(@dayOfWeek as varchar) + '%')
						and @dateFrom between as_dateFrom and as_dateto)
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
					inner join tbl_costs on (cs_svkey = 1 and cs_code = ch_key and @dateFrom between cs_date and cs_dateend
						and cs_subcode1=@subcode1 and cs_pkkey = @flightpkkey)
					where ch_key = @code and as_week like ('%' + cast(@dayOfWeek as varchar) + '%')
						and @dateFrom between as_dateFrom and as_dateto)
				begin
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
					values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
						return 
				end
				end
			end
		end

		-- check stopsale
		-- MT ignore stop on object for commitment quotas
		if exists(select 1 
				from stopsales with(nolock) 
					inner join quotaobjects qo with(nolock) on ss_qoid = qo_id
				where qo_svkey = @svkey and qo_code = @code and isnull(qo_subcode1, 0) in (0, @subcode1)
					and isnull(qo_subcode2, 0) in (0, @subcode2) and ss_date between @dateFrom and @dateTo
					and ss_qdid is null and isnull(ss_isdeleted, 0) = 0 
					/*ignore stop on object for COMMITMENT*/
					and not exists(select 1 from
						quotas with(nolock) inner join quotaobjects qo1 with(nolock) on
						qo1.qo_qtid = qt_id inner join quotadetails with(nolock) on qd_qtid = qt_id
						 where qo.qo_svkey = qo1.qo_svkey and qo.qo_code = qo1.qo_code and qo1.qo_subcode1 in (qo.qo_subcode1, 0) and qo1.qo_subcode2 in (qo.qo_subcode2, 0) and qd_date = ss_date and qd_type = 2 /*commitment*/))
		begin
					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
					values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
						return 
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
			(case when (isnull(ss_id, 0) > 0 and isnull(ss_isdeleted, 0) = 0) then 1 else 0 end) as qt_stop
		from quotas q with(nolock) inner join 
			quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
			left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
			right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid 
			left outer join StopSales ss with(nolock) on (qd_id = ss_qdid and isnull(ss_isdeleted, 0) = 0)
		where
			qo_svkey = @svkey
			and qo_code = @code
			and isnull(qo_subcode1, 0) in (0, @subcode1)
			and (@svkey = 1 or isnull(qo_subcode2, 0) in (0, @subcode2))
			and ((@checkAgentQuotes > 0 and @checkCommonQuotes > 0 and isnull(qp_agentkey, 0) in (0, @agentKey)) or
				(@checkAgentQuotes <= 0 and isnull(qp_agentkey, 0) = 0) or
				(@checkAgentQuotes > 0 and @checkCommonQuotes <= 0 and isnull(qp_agentkey, 0) in (0, @agentKey)))
			and (@partnerKey < 0 or isnull(qt_prkey, 0) in (0, @partnerKey))
			and ((@days = 1 and qd_date = @dateFrom) or (@days > 1 and qd_date between @dateFrom and @dateTo))
			and (@tourDuration < 0 or (@checkNoLongQuotes <> @ALLDAYS_CHECK and isnull(ql_duration, 0) in (0, @long)) or (@checkNoLongQuotes = @ALLDAYS_CHECK and isnull(ql_duration, 0) = @long))
		order by
			qd_date, qp_agentkey DESC, qd_type DESC, QT_PrKey DESC, qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC, qo_subcode2 DESC

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
			qt_stop
		from @tmpQuotes

		open qCur

		fetch next from qCur 
			into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
				@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, 
				@qtByroom, @qtType, @qtLong, @qtPlacesAll, @qtStop

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
						-- Если квота в первый день не заведена, то возвращаем ЗАПРОС
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
						values(0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0)
						return
					end
				end

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

						if(@bycheckinRes > 0 and @checkNoLongQuotes <> @ALLDAYS_CHECK)
							break
							
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
						set @bycheckinRes = 0
						
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
					@qtLong, @qtPlacesAll, @qtStop
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
				where ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo and as_week like ('%' + cast(@dayOfWeek as varchar) + '%')
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
				(case when (isnull(ss_id, 0) > 0 and isnull(ss_isdeleted, 0) = 0) then 1 else 0 end) as qt_stop
			from quotas q with(nolock) inner join 
				quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
				left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
				right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid 
				left outer join StopSales ss with(nolock) on (qd_id = ss_qdid and isnull(ss_isdeleted, 0) = 0)
				 inner join charter on (qo_svkey = @svkey and ch_key = qo_code) inner join airseason on as_chkey = ch_key
			where
				exists (select top 1 cs_id from costs with(nolock)
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
				and ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo and as_week like ('%' + cast(@dayOfWeek as varchar) + '%')
				and @dateFrom between as_dateFrom and as_dateto
				and (@tourDuration < 0 or (@checkNoLongQuotes <> @ALLDAYS_CHECK and isnull(ql_duration, 0) in (0, @long)) or (@checkNoLongQuotes = @ALLDAYS_CHECK and isnull(ql_duration, 0) = @long))
			order by
				qd_date, qp_agentkey DESC, qd_type DESC, QT_PrKey DESC, qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC, qo_subcode2 DESC
		end
		else
		begin
			if not exists(select top 1 ch_key from charter with(nolock) inner join airseason with(nolock) on as_chkey = ch_key
				where ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo and as_week like ('%' + cast(@dayOfWeek as varchar) + '%')
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
				(case when (isnull(ss_id, 0) > 0 and isnull(ss_isdeleted, 0) = 0) then 1 else 0 end) as qt_stop
			from quotas q with(nolock) inner join 
				quotadetails qd with(nolock) on qt_id = qd_qtid inner join quotaparts qp with(nolock) on qd_id = qp_qdid
				left outer join quotalimitations ql with(nolock) on qp_id = ql_qpid
				right outer join quotaobjects qo with(nolock) on qt_id = qo_qtid 
				left outer join StopSales ss with(nolock) on (qd_id = ss_qdid and isnull(ss_isdeleted, 0) = 0)
				inner join charter with(nolock) on (qo_svkey = @svkey and ch_key = qo_code) inner join airseason with(nolock) on as_chkey = ch_key
			where
				qo_svkey = @svkey
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
				and ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo and as_week like ('%' + cast(@dayOfWeek as varchar) + '%')
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
			qt_stop
		from @tmpQuotes

		open qCur

		fetch next from qCur into @qtSvkey, @qtCode, @qtSubcode1, @qtSubcode2, @qtAgent,
			@qtPrkey, @qtNotcheckin, @qtRelease, @qtPlaces, @qtDate, @qtByroom, @qtType, 
			@qtLong, @qtPlacesAll, @qtStop

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
					@qtLong, @qtPlacesAll, @qtStop
	
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

--	return (@result)
end
GO

GRANT SELECT ON [dbo].[mwCheckQuotesEx2] TO PUBLIC
GO


-- 100212(CreateIndex_CalculatingPriceLists).sql
IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_PriceTourKey')
     DROP INDEX CalculatingPriceLists.x_PriceTourKey 
GO

CREATE INDEX x_PriceTourKey ON CalculatingPriceLists (CP_PriceTourKey)
GO

-- 100215(AlterTable_HotelDictionary).sql
if not exists (select * from dbo.syscolumns where name = 'hd_rank' and id = object_id(N'[dbo].[HotelDictionary]'))
	alter table HotelDictionary add [hd_rank] [int] NULL 
GO

-- sp_CharterChange.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CharterChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP procedure [dbo].[CharterChange]
GO
CREATE PROCEDURE [dbo].[CharterChange]
(
--<VERSION>2007.2.27</VERSION>
	@Code int
) AS
SET DATEFIRST 1
--Если в хранимку в качестве параметра передать 0, то процедура отрабатывает по всем перелетам
declare @SVKey int, @CNKey int, @CTKey int, @SubCode1 int, @SubCode2 int, @Date datetime,
		@ServiceName varchar(255), @ServiceNameLat varchar(255), @ServiceTimeBeg DateTime, @ServiceTimeEnd DateTime

declare @hours varchar(2), @minutes varchar(2), @chKey int
declare @nullString varchar(2)
declare @dogovorListName varchar(150)
declare @timeTo datetime
set @nullString = '00'

Set @SVKey=1

declare CursorDLCharter 
-- Ищем и обновляем информацию о названии услуги и времени начала услуги
-- 1. Если время в справочнике не совпадает со временем в услуге
-- 2. Если услуга есть, а в справочнике расписаний такого рейса на данную дату нет
-- 3. Если название рейса (или аэропорта) не совпадает с названием в услуге
cursor local fast_forward for 
	SELECT	distinct DL_CNKey, DL_CTKey, DL_Code, DL_SubCode1, DL_SubCode2, DL_DateBeg
	FROM	Dogovorlist, dbo.AirSeason 
	WHERE	DL_SVKey=@SVKey and DL_DateBeg>(GetDate() - 366) and AS_CHKey=DL_Code 
			--and (DL_TimeBeg != AS_TimeFrom or DL_TimeBeg is null)
			and DL_DateBeg between AS_DateFrom and AS_DateTo 
			and CHARINDEX(CAST(DATEPART (weekday, DL_DateBeg) as varchar(1)),AS_Week)>0
			and ((DL_Code=@Code and @Code>0) or @Code=0)
UNION
SELECT	distinct DL_CNKey, DL_CTKey, DL_Code, DL_SubCode1, DL_SubCode2, DL_DateBeg
	FROM	Dogovorlist
	WHERE	DL_SVKey=@SVKey and DL_DateBeg>(GetDate() - 366)
			and not exists 
				(	SELECT 1 FROM dbo.AirSeason 
					WHERE	AS_CHKey=DL_Code and DL_DateBeg between AS_DateFrom and AS_DateTo 
							and AS_Week like '%'+ CAST(DATEPART (weekday, DL_DateBeg) as varchar(1))+'%') 
			and ((DL_Code=@Code and @Code>0) or @Code=0)
UNION
SELECT distinct DL_CNKey, DL_CTKey, DL_Code, DL_SubCode1, DL_SubCode2, DL_DateBeg
	FROM	Dogovorlist, dbo.Charter
	WHERE	DL_SVKey=@SVKey and DL_DateBeg>(GetDate() - 366) and DL_Code=CH_Key 
			and DL_Name not like '%'+CH_AirLineCode+CH_Flight+', '+CH_PortCodeFrom+'-'+CH_PortCodeTo+'%'
			and ((DL_Code=@Code and @Code>0) or @Code=0)
open CursorDLCharter
	fetch next from CursorDLCharter  into @CNKey, @CTKey, @Code, @SubCode1, @SubCode2, @Date
While (@@fetch_status = 0)
BEGIN
	Set @ServiceName = null
	Set @ServiceNameLat = null
	exec [dbo].[MakeFullSVName]
		@CNKey, @CTKey, @SVKey, @Code, null, 
		@SubCode1, @SubCode2, 0, @Date, null, 
		@ServiceName output, @ServiceNameLat output, @ServiceTimeBeg output, @ServiceTimeEnd output
	begin tran tDLCharterEnd
	UPDATE	DogovorList SET DL_Name=@ServiceName, DL_NameLat=@ServiceNameLat, DL_TimeBeg=@ServiceTimeBeg
	WHERE	DL_SVKey=@SVKey and DL_Code=@Code and DL_CNKey=@CNKey 
			and DL_CTKey=@CTKey and DL_SubCode1=@SubCode1 and DL_SubCode2=@SubCode2
			and DL_DateBeg=@Date and (DL_Name!=@ServiceName or (DL_TimeBeg!=@ServiceTimeBeg and DL_TimeBeg is not null) or DL_TimeBeg is null)
			and DL_DateBeg>(GetDate() - 366)
	commit tran tDLCharterEnd
	fetch next from CursorDLCharter  into @CNKey, @CTKey, @Code, @SubCode1, @SubCode2, @Date
END
close CursorDLCharter
deallocate CursorDLCharter
GO

GRANT EXECUTE on [dbo].[CharterChange] to public
GO

-- sp_mwSimpleTourInfo.sql
if exists(select id from sysobjects where xtype='p' and name='mwSimpleTourInfo')
	drop proc dbo.mwSimpleTourInfo
go

create  proc [dbo].[mwSimpleTourInfo](@roomKeys varchar(50), @onlySpo smallint, @priceFromTpTours smallint = 0)
as
begin
	declare @sql varchar(3000)

	if (@priceFromTpTours = 0)
	begin
		set @sql = '      
		select     pt_cnkey, cn_name, pt_ctkeyfrom, ct_name, pt_tourkey, pt_tourname, pt_toururl, pt_rate,
				   dbo.mwTop5TourDates(pt_cnkey, pt_tourkey, pt_tlkey, 0) as dates, 
				   dbo.mwTourHotelNights(pt_tourkey) as nights, min_price, CONVERT(varchar(10), pt_tourdate, 21) as pt_firsttourdate, pt_tourcreated
		from 
		(
			  select max(pt_cnkey) pt_cnkey, max(pt_ctkeyfrom) pt_ctkeyfrom, pt_tourkey, max(pt_tourname) pt_tourname, max(pt_toururl) pt_toururl, max(pt_tlkey) pt_tlkey, max(pt_rate) pt_rate, min(pt_price) min_price, min(pt_tourdate) pt_tourdate, max(pt_tourcreated) pt_tourcreated
			  from dbo.mwPriceTable with(nolock)
			  where pt_main > 0 and pt_rmkey in (' + @roomKeys + ') and pt_tourdate >= getdate()
			  group by pt_tourkey
		 ) as prices
			  join dbo.Country on pt_cnkey = cn_key
			  join dbo.CityDictionary on pt_ctkeyfrom = ct_key
		where ' + ltrim(str(isnull(@onlySpo, 0))) + ' = 0 or exists(select 1 from tp_tours with(nolock) where (to_attribute & 1) > 0 and to_key = pt_tourkey)
		order by pt_tourcreated desc'
	end
	else
	begin
		set @sql = '     
		select	isnull(ct_name, ''-Без перелета-'') as ct_name, 
			isnull(tl_ctdeparturekey,0) as pt_ctkeyfrom, 
			to_cnkey + isnull(tl_ctdeparturekey,0) as cnctkey,
			to_cnkey as pt_cnkey, 
			cn_name, 
			to_name as pt_tourname, 
			tl_webhttp as pt_toururl, 
			tl_rate as pt_rate,
			dbo.mwTop5TourDates(to_cnkey, to_key, tl_key, 0) as dates, 
			TO_MinPrice as min_price, 
			TO_HotelNights as nights,
			CONVERT(varchar(10), (select min(TD_Date) from TP_TurDates where TD_ToKey = TO_Key), 21) as pt_firsttourdate,
			to_DateCreated pt_tourcreated,
			to_key pt_tourkey
		from tp_tours
			left join turlist on tl_key = to_trkey
			left join dbo.Country on to_cnkey = cn_key
			left join dbo.CityDictionary on tl_ctdeparturekey = ct_key
		where TO_IsEnabled > 0 and TO_DateValid >= getdate() and (' + ltrim(str(isnull(@onlySpo, 0))) + ' = 0 or (to_attribute & 1) > 0 )
		order by ct_name, cn_name, to_DateCreated'
	end
	exec(@sql)
end

go

grant exec on mwSimpleTourInfo to public

-- 080508(alter_Trigger_mwOnUpdateNameWeb).sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwTourNameWebTrigger]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[mwTourNameWebTrigger]
GO

CREATE TRIGGER [dbo].[mwTourNameWebTrigger] ON [dbo].[tbl_TurList] 
FOR  UPDATE
AS
if UPDATE (TL_NAMEWEB)
	begin
		update [dbo].mwSpoDataTable set sd_tourname = tl_nameweb  from inserted where sd_tlkey = tl_key
		update [dbo].mwPriceDataTable set pt_tourname = tl_nameweb  from inserted where pt_tlkey = tl_key
	end
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwOnUpdateNameWeb]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[mwOnUpdateNameWeb]
GO

-- 100217(Insert_Action).sql
if not exists (select ac_key from dbo.Actions where AC_Key = 68)
	insert into dbo.Actions (ac_key, AC_Name, AC_NameLat) values (68, 'Турпутевка->Отображать курс', 'Reservation->Show course')
GO

-- alter_mwSpoDataTable.sql
if not exists(select id from syscolumns where id = OBJECT_ID('mwSpoDataTable') and name = 'sd_hdprkey')
ALTER TABLE mwSpoDataTable ADD sd_hdprkey int null
go

exec sp_refreshviewforall mwSpoData
go

update mwSpoDataTable 
set sd_hdprkey = (select top 1 ts_oppartnerkey from tp_services where ts_code = sd_hdkey and ts_subcode1 = sd_pnkey)
go



-- 20100219(AddTable_InsPolicyListDogovorList).sql
-- InsPolicyListDogovorList <--> InsPolicyList
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_InsPolicyListDogovorList_InsPolicyList]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[InsPolicyListDogovorList] DROP CONSTRAINT FK_InsPolicyListDogovorList_InsPolicyList
GO

-- InsPolicyListDogovorList <--> tblDogovorList
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_InsPolicyListDogovorList_tblDogovorList]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[InsPolicyListDogovorList] DROP CONSTRAINT FK_InsPolicyListDogovorList_tblDogovorList
GO

-- drop table
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InsPolicyListDogovorList]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[InsPolicyListDogovorList]
GO

-- create table
CREATE TABLE InsPolicyListDogovorList
(
	IPD_ID int IDENTITY(1, 1) NOT NULL,
	IPD_IPLID int NOT NULL,
	IPD_DLKEY int NOT NULL,
    IPD_IsInclude smallint,
	IPD_Brutto money
) ON [PRIMARY]
GO

-- create primary key
ALTER TABLE [dbo].[InsPolicyListDogovorList] WITH NOCHECK ADD 
	CONSTRAINT [PK_InsPolicyListDogovorList] PRIMARY KEY  CLUSTERED 
	(
		[IPD_ID]
	)  ON [PRIMARY] 
GO

-- create foreign keys
ALTER TABLE [dbo].[InsPolicyListDogovorList] ADD 
	CONSTRAINT [FK_InsPolicyListDogovorList_InsPolicyList] FOREIGN KEY 
	(
		[IPD_IPLID]
	) REFERENCES [dbo].[InsPolicyList] (
		[IPL_ID]
	)
	ON UPDATE CASCADE
	ON DELETE CASCADE
	,
	CONSTRAINT [FK_InsPolicyListDogovorList_tblDogovorList] FOREIGN KEY 
	(
		[IPD_DLKEY]
	) REFERENCES [dbo].[tbl_DogovorList] (
		[DL_KEY]
	)
	ON UPDATE CASCADE
	ON DELETE CASCADE
GO

-- create permissions
GRANT  SELECT ,  UPDATE ,  INSERT ,  DELETE  ON [dbo].[InsPolicyListDogovorList] TO PUBLIC
GO

-- sp_PagingSelect.sql
if exists(select id from sysobjects where xtype='p' and name='PagingSelect')
	drop proc dbo.PagingSelect
go

Create Procedure [dbo].[PagingSelect] 
@pagingType int,
@sKeysSelect varchar(2024),
@spageNum varchar(30),
@spageSize varchar(30),
@filter	varchar(2024),
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

declare @sql nvarchar(4000)
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
	set @sql = @sql + '
		set @rowCountOUT = @@RowCount
'
set @sql=@sql + ' 
select #pg.paging_id paging_id,#pg.pt_key,tbl.pt_ctkeyfrom,tbl.pt_cnkey,#pg.pt_tourdate,#pg.pt_pnkey,#pg.pt_hdkey,#pg.pt_hrkey,#pg.pt_tourkey,tbl.pt_tlkey as pt_tlkey,tl_tip as pt_tourtype,tl_nameweb as pt_tourname,tl_webhttp as pt_toururl,
hd_name pt_hdname,hd_stars pt_hdstars,hd_ctkey pt_ctkey,hd_rskey pt_rskey,hd_http pt_hotelurl,pn_code pt_pncode,tbl.pt_rate pt_rate,tbl.pt_rmkey pt_rmkey,tbl.pt_rckey pt_rckey,tbl.pt_ackey pt_ackey,tbl.pt_childagefrom pt_childagefrom,tbl.pt_childageto pt_childageto,tbl.pt_childagefrom2 pt_childagefrom2,tbl.pt_childageto2 pt_childageto2, cn_name pt_cnname, ct_name pt_ctname, rs_name pt_rsname, tbl.pt_rmname pt_rmname,tbl.pt_rcname pt_rcname,tbl.pt_acname pt_acname, tbl.pt_chkey pt_chkey, tbl.pt_chbackkey pt_chbackkey, tbl.pt_hotelkeys pt_hotelkeys, tbl.pt_hotelroomkeys pt_hotelroomkeys, tbl.pt_hotelnights pt_hotelnights, tbl.pt_hotelstars pt_hotelstars, tbl.pt_pansionkeys pt_pansionkeys,0 '
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
go

grant exec on dbo.PagingSelect to public
go

-- 100224(AlterTables).sql
if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='Accmdmentype' and COLUMN_NAME='AC_CODE') < 70)
	alter table Accmdmentype alter column AC_CODE varchar(70)
GO

if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='Accmdmentype' and COLUMN_NAME='AC_NAME') < 70)
	alter table Accmdmentype alter column AC_NAME varchar(70)
GO

if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='Accmdmentype' and COLUMN_NAME='AC_NAMELAT') < 70)
	alter table Accmdmentype alter column AC_NAMELAT varchar(70)
GO

if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='TurService' and COLUMN_NAME='TS_NAME') < 255)
	alter table TurService alter column TS_NAME varchar(255)
GO

if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='TurService' and COLUMN_NAME='TS_NAMELAT') < 255)
	alter table TurService alter column TS_NAMELAT varchar(255)
GO

if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='tbl_DogovorList' and COLUMN_NAME='DL_NAME') < 255)
	alter table tbl_DogovorList alter column DL_NAME varchar(255)
GO

if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='tbl_DogovorList' and COLUMN_NAME='DL_NAMELAT') < 255)
	alter table tbl_DogovorList alter column DL_NAMELAT varchar(255)
GO

exec sp_refreshviewforall 'DogovorList'
GO

if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='TP_Services' and COLUMN_NAME='TS_NAME') < 255)
	alter table TP_Services alter column TS_NAME varchar(255)
GO

-- 091209(CreateTable_Tariffs).sql
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Tariffs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[Tariffs](
	[TRF_ID] [int] IDENTITY(0,1) NOT NULL,
	[TRF_SvKey] [int],
	[TRF_Name] [varchar](255) NOT NULL,
	[TRF_NameLat] [varchar](255) NULL,
	[TRF_Comment] [varchar](max) NULL
 CONSTRAINT [PK_Tariffs] PRIMARY KEY CLUSTERED 
(
	[TRF_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists (select * from dbo.[Tariffs] where TRF_ID = 0)
	insert into dbo.[Tariffs](TRF_Name, TRF_NameLat, TRF_Comment) values('Базовый', 'Base', '')
GO

grant select,insert,update,delete on dbo.[Tariffs] to public
GO 

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[tbl_costs]') and name = 'CS_TRFId')
	ALTER TABLE dbo.tbl_costs ADD CS_TRFId int NOT NULL default(0)
GO

if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Costs_Tariffs]'))
	ALTER TABLE [dbo].[tbl_costs]  WITH CHECK ADD  CONSTRAINT [FK_Costs_Tariffs] FOREIGN KEY([CS_TRFId])
	REFERENCES [dbo].[Tariffs] ([TRF_ID])
	ON DELETE SET DEFAULT
GO

exec dbo.sp_refreshviewforall 'costs'
GO

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[TurService]') and name = 'TS_TRFId')
	ALTER TABLE dbo.TurService ADD TS_TRFId int NOT NULL default(0)
GO

if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_TurService_Tariffs]'))
	ALTER TABLE [dbo].[TurService]  WITH CHECK ADD  CONSTRAINT [FK_TurService_Tariffs] FOREIGN KEY([TS_TRFId])
	REFERENCES [dbo].[Tariffs] ([TRF_ID])
	ON DELETE SET DEFAULT
GO

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[tbl_DogovorList]') and name = 'DL_TRFId')
	ALTER TABLE dbo.tbl_DogovorList ADD DL_TRFId int NOT NULL default(0)
GO

--if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_DogovorList_Tariffs]'))
--	ALTER TABLE [dbo].[tbl_DogovorList]  WITH CHECK ADD  CONSTRAINT [FK_DogovorList_Tariffs] FOREIGN KEY([DL_TRFId])
--	REFERENCES [dbo].[Tariffs] ([TRF_ID])
--	ON DELETE SET DEFAULT
--GO

exec dbo.sp_refreshviewforall 'DogovorList'
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ServiceTariffs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[ServiceTariffs](
	[ST_ID] [int] IDENTITY(1,1) NOT NULL,
	[ST_SvKey] int NOT NULL,
	[ST_Code] int NOT NULL,
	[ST_TRFId] int NOT NULL,
	[ST_Default] smallint NOT NULL
 CONSTRAINT [PK_ServiceTariffs] PRIMARY KEY CLUSTERED 
(
	[ST_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ServiceTariffs_Service]'))
	ALTER TABLE [dbo].[ServiceTariffs]  WITH CHECK ADD  CONSTRAINT [FK_ServiceTariffs_Service] FOREIGN KEY([ST_SvKey])
	REFERENCES [dbo].[Service] ([SV_Key])
	ON DELETE CASCADE
GO

if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ServiceTariffs_Service]'))
	ALTER TABLE [dbo].[ServiceTariffs]  WITH CHECK ADD  CONSTRAINT [FK_ServiceTariffs_Tariffs] FOREIGN KEY([ST_TrfId])
	REFERENCES [dbo].[Tariffs] ([TRF_Id])
	ON DELETE CASCADE
GO

grant select,insert,update,delete on dbo.[ServiceTariffs] to public
GO 

-- sp_mwFillPriceTable.sql
if exists(select id from sysobjects where xtype='p' and name='mwFillPriceTable')
	drop proc dbo.mwFillPriceTable
go

create procedure [dbo].[mwFillPriceTable] 
	@dataTableName varchar (1024),
	@countryKey int,
	@cityFromKey int
as

declare @mwSearchType int
select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings 
where SS_ParmName = 'MWDivideByCountry'

declare @tableName varchar (1024)
if @mwSearchType = 0
	set @tableName = 'mwPriceDataTable'
else
	set @tableName = dbo.mwGetPriceTableName(@countryKey, @cityFromKey)
declare @sql varchar (8000)
set @sql = 'insert into ' + @tableName + '(
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
			pt_topricefor,
			pt_hddetails)
		select
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
			pt_topricefor,
			pt_hddetails
		from ' + @dataTableName
exec (@sql)
go

grant exec on dbo.mwFillPriceTable to public
go


-- fn_mwGetTourHotels.sql
if exists(select id from sysobjects where xtype='fn' and name='mwGetTourHotels')
	drop function dbo.[mwGetTourHotels]
go

create function [dbo].[mwGetTourHotels](@tiKey int)
returns varchar(256)
as
begin
	declare @result varchar(256)
	set		@result = ''

	select 
		@result = @result 
			+ isnull(ltrim(str(ts_code)),'') + ':' 
			+ isnull(ltrim(str(hr_rmkey)),'') + ':' 
			+ isnull(ltrim(str(hr_rckey)),'') + ':' 
			+ isnull(ltrim(str(ts_day)),'') + ':' 
			+ isnull(ltrim(str(ts_days)),'') + ':' 
			+ isnull(ltrim(str(TS_OpPartnerKey)),'') + ':' 
			+ isnull(ltrim(str(TS_subcode1)),'') + ':' 
			+ isnull(ltrim(str(TS_subcode2)),'') + ','
	from 
		tp_services 
			inner join tp_servicelists on tl_tskey = ts_key
			inner join tp_lists on ti_key = tl_tikey
			inner join HotelRooms on  hr_key = ts_subcode1
	where
		ts_svkey = 3 and
		tl_tikey = @tikey
	order by
		ts_day

	-- Remove comma at the end of string
	if(len(@result) > 0)
		set @result = substring(@result, 1, len(@result) - 1)

	return @result
end
go

grant exec on [dbo].[mwGetTourHotels] to public
go

-- 100224(alter_mwPriceDataTable).sql
print 'Alter mwPriceDataTable Tables and fill rows for tours that having more than one hotelservice'
go

declare @tablename nvarchar(128)
declare @sql varchar(1000)
declare cur cursor for select name from sysobjects where name like N'%mwPriceDataTable%' and xtype = N'U'
open cur

fetch cur into @tablename

while (@@FETCH_STATUS = 0)
begin
	print 'Edit ' + @tablename + ' :'
	-- Add pt_hddetails column to mwPriceDataTable table
	set @sql = 'if not exists(select id from syscolumns where id = OBJECT_ID(''' + @tablename + ''') and name = ''pt_hddetails'')
					ALTER TABLE ' + @tablename + ' ADD pt_hddetails varchar(256) null'
	exec (@sql)

	-- Fill pt_hddetails for tours that having more than one hotelservice
	set @sql = 'update ' + @tablename + '
					set pt_hddetails = dbo.mwGetTourHotels(pt_pricelistkey)
					where pt_tourkey in 
					(
						select ti_tokey
						from tp_lists
							inner join tp_serviceLists on ti_key = tl_tikey
							inner join tp_services on tl_tskey = ts_key
						where ts_svkey = 3
						group by ti_key,ti_tokey
						having count (ts_key) > 1
					)'
	exec (@sql)

	set @sql = 'sp_refreshviewforall ' + replace(@tablename, 'Data', '')
	exec (@sql)

	fetch cur into @tablename
end

close cur
deallocate cur
go


-- sp_mwCheckQuotesCycle.sql
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
							@days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output
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
							@days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output
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

-- sp_mwParseHotelDetails.sql
if exists(select id from sysobjects where xtype='p' and name='mwParseHotelDetails')
	drop proc dbo.mwParseHotelDetails
go

create procedure [dbo].[mwParseHotelDetails] 
	@HotelDetailsString varchar(256),
	@HotelKey int output, 
	@RoomKey int output, 
	@RoomCategoryKey int output, 
	@HotelDay int output, 
	@HotelDays int output, 
	@HotelPartnerKey int output
as
	declare @tmpCurPosition int
	declare @tmpPrevPosition int

	set @tmpPrevPosition = 0
	set @tmpCurPosition = charindex(':', @HotelDetailsString, @tmpPrevPosition + 1)
	set @HotelKey = CAST(substring(@HotelDetailsString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
	set @tmpPrevPosition = @tmpCurPosition + 1

	set @tmpCurPosition = charindex(':', @HotelDetailsString, @tmpPrevPosition + 1)
	set @RoomKey = CAST(substring(@HotelDetailsString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
	set @tmpPrevPosition = @tmpCurPosition + 1

	set @tmpCurPosition = charindex(':', @HotelDetailsString, @tmpPrevPosition + 1)
	set @RoomCategoryKey = CAST(substring(@HotelDetailsString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
	set @tmpPrevPosition = @tmpCurPosition + 1

	set @tmpCurPosition = charindex(':', @HotelDetailsString, @tmpPrevPosition + 1)
	set @HotelDay = CAST(substring(@HotelDetailsString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
	set @tmpPrevPosition = @tmpCurPosition + 1

	set @tmpCurPosition = charindex(':', @HotelDetailsString, @tmpPrevPosition + 1)
	set @HotelDays = CAST(substring(@HotelDetailsString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
	set @tmpPrevPosition = @tmpCurPosition + 1

	set @tmpCurPosition = charindex(':', @HotelDetailsString, @tmpPrevPosition + 1)
	set @HotelPartnerKey = CAST(substring(@HotelDetailsString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
go

grant exec on dbo.mwParseHotelDetails to public
go

-- 100226(AlterTable_Dogovor).sql
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[tbl_dogovor]') and name = 'DG_NATIONALCURRENCYPAYED')
	ALTER TABLE dbo.tbl_dogovor ADD DG_NATIONALCURRENCYPAYED money NULL
GO
exec sp_RefreshViewForAll 'Dogovor'
GO

-- fn_mwGetSpoHotelNames.sql
if object_id('dbo.mwGetSpoHotelNames', 'fn') is not null
	drop function dbo.mwGetSpoHotelNames
go

create function [dbo].[mwGetSpoHotelNames](@tokey int, @links smallint) 
returns varchar(8000) as
begin
	declare @result varchar(8000)
	set @result = ''
	select @result = @result + 
		case when len(@result) <= 7900
			then
			(
				case when @links > 0 and len(isnull(hd_http, '')) > 0 
					then '<a href=''' + hd_http + ''' target=''_blank''>' + isnull(hd_name, '') + ' ' + isnull(hd_stars, '') + '</a>, ' 
					else isnull(hd_name, '') + ' ' + isnull(hd_stars, '') + ', ' 
				end 
			)
			else ''
		end
	from 
	(
		select distinct sd_hdkey 
		from dbo.mwSpoData 
		where sd_tourkey = @tokey
	) tbl 
		inner join hoteldictionary with(nolock) on tbl.sd_hdkey = hd_key
	order by hd_name, hd_stars

	if len(@result) = 0	
		return @result

	set @result = ltrim(rtrim(@result))

	return substring(@result, 1, len(@result)-1)
end
go

grant exec on dbo.mwGetSpoHotelNames to public
go


-- sp_mwUpdateHotelDetails.sql
if exists(select id from sysobjects where name='mwUpdateHotelDetails' and xtype='p')
	drop procedure [dbo].[mwUpdateHotelDetails]
go

create proc [dbo].[mwUpdateHotelDetails] 
	@onlyNew smallint = 0 
as
begin
	delete from mwHotelDetails
		where htd_hdkey not in (select htr_hdkey from HotelTypeRelations)

	insert into mwHotelDetails(htd_hdkey, htd_needupdate) 
		select htr_hdkey, 1
		from HotelTypeRelations
		where htr_hdkey not in (select htd_hdkey from mwHotelDetails)

	update mwHotelDetails 
		set htd_minprice = pt_price, 
			htd_minpricedate = pt_tourdate,
			htd_minpricerate = pt_rate,
			htd_minpricectfrom = pt_ctkeyfrom,
			htd_minpricekey = pt_pricekey,
			htd_needupdate = 0
		from mwPriceTable
		inner join 
		(
			select distinct pt_hdkey hdkey, min(pt_pricekey) pricekey
			from mwPriceTable,
			(
				select pt_hdkey hdkey, min(pt_price) minprice
				from mwPriceTable with(nolock) 
				where pt_hdkey in
				( 
					select htd_hdkey
					from mwHotelDetails
					where  htd_needupdate = 1 or @onlyNew = 0
				)
				and pt_main > 0 
				group by pt_hdkey
			) tbl
			where pt_hdkey = hdkey and pt_price = minprice
			group by pt_hdkey
		) tbl2 on pt_pricekey = pricekey
		where htd_hdkey = pt_hdkey
/*
	update mwHotelDetails set htd_minprice = (select min(pt_price) from mwPriceTable with(nolock) where pt_main > 0 and pt_hdkey = htd_hdkey and pt_tourdate > getdate()), htd_needupdate = 2
		where htd_needupdate = 1 or @onlyNew = 0

	update mwHotelDetails set htd_minpricedate = (select min(pt_tourdate) from mwPriceTable with(nolock) where pt_main > 0 and pt_hdkey = htd_hdkey and pt_price = htd_minprice and pt_tourdate > getdate()), htd_needupdate = 3
		where htd_needupdate = 2

	update mwHotelDetails set htd_minpricerate = (select min(pt_rate) from mwPriceTable with(nolock) where pt_main > 0 and pt_hdkey = htd_hdkey and pt_price = htd_minprice and pt_tourdate > getdate()), htd_needupdate = 0
		where htd_needupdate = 3
*/

end
go

grant exec on [dbo].[mwUpdateHotelDetails] to public
go

-- alter_mwPriceDataTable.sql
if not exists(select id from syscolumns where id = OBJECT_ID('mwPriceDataTable') and name = 'pt_hash')
ALTER TABLE mwPriceDataTable ADD pt_hash varchar(1024) null
go

if not exists(select id from syscolumns where id = OBJECT_ID('mwPriceDataTable') and name = 'pt_tlattribute')
ALTER TABLE mwPriceDataTable ADD pt_tlattribute int null
go

if not exists(select id from syscolumns where id = OBJECT_ID('mwPriceDataTable') and name = 'pt_spo')
ALTER TABLE mwPriceDataTable ADD pt_spo int null
go

ALTER TABLE mwPriceDataTable ALTER COLUMN pt_acname varchar(70) null
go

ALTER TABLE mwPriceDataTable ALTER COLUMN pt_accode varchar(70) null
go

exec sp_refreshviewforall mwPriceTable
go

update mwPriceDataTable
set pt_tlattribute = tl_attribute
from TurList
where tl_key = pt_tlkey
go


-- view_mwPriceTableViewAsc.sql
if exists(select id from sysobjects where xtype='v' and name='mwPriceTableViewAsc')
	drop view dbo.mwPriceTableViewAsc
go

Create view [dbo].[mwPriceTableViewAsc] as
select pt_cnkey, pt_ctkeyfrom,pt_tourtype,pt_mainplaces,pt_addplaces,
pt_tourdate,pt_pnkey,pt_hdkey,pt_hdpartnerkey,pt_hrkey,pt_ctkey, pt_tourkey,pt_tlkey,pt_tlattribute,pt_topricefor,
MAX(pt_main) as pt_main,MAX(pt_rskey) as pt_rskey,max(pt_rmkey) pt_rmkey,
max(pt_rsname) pt_rsname, max(pt_ctname) pt_ctname, max(pt_rmname) pt_rmname, 
max(pt_rcname) pt_rcname, max(pt_acname) pt_acname,
MAX(pt_childagefrom) pt_childagefrom,MAX(pt_childageto) pt_childageto,
MAX(pt_childagefrom2) pt_childagefrom2,MAX(pt_childageto2) pt_childageto2,
MAX(pt_hdname) as pt_hdname, MAX(pt_tourname) as pt_tourname,MAX(pt_pncode) pt_pncode,
MAX(pt_hdstars) pt_hdstars,
pt_hotelkeys, MAX(pt_hotelnights) pt_hotelnights, 
MAX(pt_hotelstars) pt_hotelstars, pt_pansionkeys,
MAX(pt_key) pt_key,MIN(CASE WHEN (pt_days=3 and pt_nights=2) THEN pt_price ELSE 999999999 END ) p_3_2,SUM(CASE WHEN (pt_days=3 and pt_nights=2) THEN pt_key ELSE 0 END) pk_3_2,MIN(CASE WHEN (pt_days=4 and pt_nights=2) THEN pt_price ELSE 999999999 END ) p_4_2,SUM(CASE WHEN (pt_days=4 and pt_nights=2) THEN pt_key ELSE 0 END) pk_4_2,MIN(CASE WHEN (pt_days=4 and pt_nights=3) THEN pt_price ELSE 999999999 END ) p_4_3,SUM(CASE WHEN (pt_days=4 and pt_nights=3) THEN pt_key ELSE 0 END) pk_4_3,MIN(CASE WHEN (pt_days=5 and pt_nights=3) THEN pt_price ELSE 999999999 END ) p_5_3,SUM(CASE WHEN (pt_days=5 and pt_nights=3) THEN pt_key ELSE 0 END) pk_5_3,MIN(CASE WHEN (pt_days=5 and pt_nights=4) THEN pt_price ELSE 999999999 END ) p_5_4,SUM(CASE WHEN (pt_days=5 and pt_nights=4) THEN pt_key ELSE 0 END) pk_5_4,MIN(CASE WHEN (pt_days=6 and pt_nights=4) THEN pt_price ELSE 999999999 END ) p_6_4,SUM(CASE WHEN (pt_days=6 and pt_nights=4) THEN pt_key ELSE 0 END) pk_6_4,MIN(CASE WHEN (pt_days=6 and pt_nights=5) THEN pt_price ELSE 999999999 END ) p_6_5,SUM(CASE WHEN (pt_days=6 and pt_nights=5) THEN pt_key ELSE 0 END) pk_6_5,MIN(CASE WHEN (pt_days=7 and pt_nights=5) THEN pt_price ELSE 999999999 END ) p_7_5,SUM(CASE WHEN (pt_days=7 and pt_nights=5) THEN pt_key ELSE 0 END) pk_7_5,
	MIN(CASE WHEN (pt_days=7 and pt_nights=6) THEN pt_price ELSE 999999999 END ) p_7_6,SUM(CASE WHEN (pt_days=7 and pt_nights=6) THEN pt_key ELSE 0 END) pk_7_6,MIN(CASE WHEN (pt_days=8 and pt_nights=6) THEN pt_price ELSE 999999999 END ) p_8_6,SUM(CASE WHEN (pt_days=8 and pt_nights=6) THEN pt_key ELSE 0 END) pk_8_6,MIN(CASE WHEN (pt_days=8 and pt_nights=7) THEN pt_price ELSE 999999999 END ) p_8_7,SUM(CASE WHEN (pt_days=8 and pt_nights=7) THEN pt_key ELSE 0 END) pk_8_7,MIN(CASE WHEN (pt_days=9 and pt_nights=7) THEN pt_price ELSE 999999999 END ) p_9_7,SUM(CASE WHEN (pt_days=9 and pt_nights=7) THEN pt_key ELSE 0 END) pk_9_7,MIN(CASE WHEN (pt_days=9 and pt_nights=8) THEN pt_price ELSE 999999999 END ) p_9_8,SUM(CASE WHEN (pt_days=9 and pt_nights=8) THEN pt_key ELSE 0 END) pk_9_8,MIN(CASE WHEN (pt_days=10 and pt_nights=8) THEN pt_price ELSE 999999999 END ) p_10_8,SUM(CASE WHEN (pt_days=10 and pt_nights=8) THEN pt_key ELSE 0 END) pk_10_8,MIN(CASE WHEN (pt_days=10 and pt_nights=9) THEN pt_price ELSE 999999999 END ) p_10_9,SUM(CASE WHEN (pt_days=10 and pt_nights=9) THEN pt_key ELSE 0 END) pk_10_9,MIN(CASE WHEN (pt_days=11 and pt_nights=9) THEN pt_price ELSE 999999999 END ) p_11_9,SUM(CASE WHEN (pt_days=11 and pt_nights=9) THEN pt_key ELSE 0 END) pk_11_9,MIN(CASE WHEN (pt_days=11 and pt_nights=10) THEN pt_price ELSE 999999999 END ) p_11_10,SUM(CASE WHEN (pt_days=11 and pt_nights=10) THEN pt_key ELSE 0 END) pk_11_10,MIN(CASE WHEN (pt_days=12 and pt_nights=10) THEN pt_price ELSE 999999999 END ) p_12_10,SUM(CASE WHEN (pt_days=12 and pt_nights=10) THEN pt_key ELSE 0 END) pk_12_10,MIN(CASE WHEN (pt_days=12 and pt_nights=11) THEN pt_price ELSE 999999999 END ) p_12_11,SUM(CASE WHEN (pt_days=12 and pt_nights=11) THEN pt_key ELSE 0 END) pk_12_11,MIN(CASE WHEN (pt_days=13 and pt_nights=11) THEN pt_price ELSE 999999999 END ) p_13_11,SUM(CASE WHEN (pt_days=13 and pt_nights=11) THEN pt_key ELSE 0 END) pk_13_11,MIN(CASE WHEN (pt_days=13 and pt_nights=12) THEN pt_price ELSE 999999999 END ) p_13_12,SUM(CASE WHEN (pt_days=13 and pt_nights=12) THEN pt_key ELSE 0 END) pk_13_12,MIN(CASE WHEN (pt_days=14 and pt_nights=12) THEN pt_price ELSE 999999999 END ) p_14_12,SUM(CASE WHEN (pt_days=14 and pt_nights=12) THEN pt_key ELSE 0 END) pk_14_12,
	MIN(CASE WHEN (pt_days=14 and pt_nights=13) THEN pt_price ELSE 999999999 END ) p_14_13,SUM(CASE WHEN (pt_days=14 and pt_nights=13) THEN pt_key ELSE 0 END) pk_14_13,MIN(CASE WHEN (pt_days=15 and pt_nights=13) THEN pt_price ELSE 999999999 END ) p_15_13,SUM(CASE WHEN (pt_days=15 and pt_nights=13) THEN pt_key ELSE 0 END) pk_15_13,MIN(CASE WHEN (pt_days=15 and pt_nights=14) THEN pt_price ELSE 999999999 END ) p_15_14,SUM(CASE WHEN (pt_days=15 and pt_nights=14) THEN pt_key ELSE 0 END) pk_15_14,MIN(CASE WHEN (pt_days=16 and pt_nights=14) THEN pt_price ELSE 999999999 END ) p_16_14,SUM(CASE WHEN (pt_days=16 and pt_nights=14) THEN pt_key ELSE 0 END) pk_16_14,MIN(CASE WHEN (pt_days=16 and pt_nights=15) THEN pt_price ELSE 999999999 END ) p_16_15,SUM(CASE WHEN (pt_days=16 and pt_nights=15) THEN pt_key ELSE 0 END) pk_16_15,MIN(CASE WHEN (pt_days=17 and pt_nights=15) THEN pt_price ELSE 999999999 END ) p_17_15,SUM(CASE WHEN (pt_days=17 and pt_nights=15) THEN pt_key ELSE 0 END) pk_17_15,MIN(CASE WHEN (pt_days=17 and pt_nights=16) THEN pt_price ELSE 999999999 END ) p_17_16,SUM(CASE WHEN (pt_days=17 and pt_nights=16) THEN pt_key ELSE 0 END) pk_17_16,MIN(CASE WHEN (pt_days=18 and pt_nights=16) THEN pt_price ELSE 999999999 END ) p_18_16,SUM(CASE WHEN (pt_days=18 and pt_nights=16) THEN pt_key ELSE 0 END) pk_18_16,MIN(CASE WHEN (pt_days=18 and pt_nights=17) THEN pt_price ELSE 999999999 END ) p_18_17,SUM(CASE WHEN (pt_days=18 and pt_nights=17) THEN pt_key ELSE 0 END) pk_18_17,MIN(CASE WHEN (pt_days=19 and pt_nights=17) THEN pt_price ELSE 999999999 END ) p_19_17,SUM(CASE WHEN (pt_days=19 and pt_nights=17) THEN pt_key ELSE 0 END) pk_19_17,MIN(CASE WHEN (pt_days=19 and pt_nights=18) THEN pt_price ELSE 999999999 END ) p_19_18,SUM(CASE WHEN (pt_days=19 and pt_nights=18) THEN pt_key ELSE 0 END) pk_19_18,MIN(CASE WHEN (pt_days=20 and pt_nights=18) THEN pt_price ELSE 999999999 END ) p_20_18,SUM(CASE WHEN (pt_days=20 and pt_nights=18) THEN pt_key ELSE 0 END) pk_20_18,MIN(CASE WHEN (pt_days=20 and pt_nights=19) THEN pt_price ELSE 999999999 END ) p_20_19,SUM(CASE WHEN (pt_days=20 and pt_nights=19) THEN pt_key ELSE 0 END) pk_20_19,MIN(CASE WHEN (pt_days=21 and pt_nights=19) THEN pt_price ELSE 999999999 END ) p_21_19,SUM(CASE WHEN (pt_days=21 and pt_nights=19) THEN pt_key ELSE 0 END) pk_21_19,
	MIN(CASE WHEN (pt_days=21 and pt_nights=20) THEN pt_price ELSE 999999999 END ) p_21_20,SUM(CASE WHEN (pt_days=21 and pt_nights=20) THEN pt_key ELSE 0 END) pk_21_20,MIN(CASE WHEN (pt_days=22 and pt_nights=20) THEN pt_price ELSE 999999999 END ) p_22_20,SUM(CASE WHEN (pt_days=22 and pt_nights=20) THEN pt_key ELSE 0 END) pk_22_20,MIN(CASE WHEN (pt_days=22 and pt_nights=21) THEN pt_price ELSE 999999999 END ) p_22_21,SUM(CASE WHEN (pt_days=22 and pt_nights=21) THEN pt_key ELSE 0 END) pk_22_21,MIN(CASE WHEN (pt_days=23 and pt_nights=21) THEN pt_price ELSE 999999999 END ) p_23_21,SUM(CASE WHEN (pt_days=23 and pt_nights=21) THEN pt_key ELSE 0 END) pk_23_21,MIN(CASE WHEN (pt_days=23 and pt_nights=22) THEN pt_price ELSE 999999999 END ) p_23_22,SUM(CASE WHEN (pt_days=23 and pt_nights=22) THEN pt_key ELSE 0 END) pk_23_22 
from dbo.mwPriceTable t1 inner join 
(select pt_cnkey cnkey, pt_ctkeyfrom ctkeyfrom,pt_tourtype tourtype, pt_mainplaces mainplaces, pt_addplaces addplaces, pt_tourdate tourdate,pt_pnkey pnkey,pt_pansionkeys pansionkeys,pt_days days,pt_nights nights,pt_hdkey hdkey,pt_hotelkeys hotelkeys,pt_hdpartnerkey hdpartnerkey,pt_hrkey hrkey,max(pt_key) ptkey from dbo.mwPriceTable group by pt_cnkey, pt_ctkeyfrom,pt_tourtype,pt_mainplaces, pt_addplaces,pt_tourdate,pt_pnkey,pt_pansionkeys,pt_nights,pt_days,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,pt_hrkey,pt_spo) t2
on  t1.pt_cnkey=t2.cnkey and t1.pt_ctkeyfrom=t2.ctkeyfrom and t1.pt_tourtype=t2.tourtype and t1.pt_mainplaces=t2.mainplaces and t1.pt_addplaces=t2.addplaces and t1.pt_tourdate=t2.tourdate and t1.pt_pnkey=t2.pnkey and t1.pt_pansionkeys = t2.pansionkeys and t1.pt_nights=t2.nights and t1.pt_days=t2.days and t1.pt_hdkey=t2.hdkey and t1.pt_hotelkeys = t2.hotelkeys and t1.pt_hdpartnerkey = t2.hdpartnerkey and t1.pt_hrkey=t2.hrkey and t1.pt_key=t2.ptkey group by pt_cnkey, pt_ctkeyfrom,pt_mainplaces,pt_tourtype, pt_addplaces, pt_tourdate,pt_pnkey,pt_pansionkeys,pt_tourkey,pt_tlkey,pt_tlattribute,pt_topricefor,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,pt_ctkey, pt_hrkey
GO

grant select on dbo.mwPriceTableViewAsc to public
go

-- view_mwPriceTableViewDesc.sql
if exists(select id from sysobjects where xtype='v' and name='mwPriceTableViewDesc')
	drop view dbo.mwPriceTableViewDesc
go

Create view [dbo].[mwPriceTableViewDesc] as
select pt_cnkey, pt_ctkeyfrom,pt_tourtype,pt_mainplaces,pt_addplaces,pt_tourdate,pt_pnkey,pt_hdkey,pt_hdpartnerkey,pt_hrkey,pt_ctkey,pt_tourkey,pt_tlkey,pt_tlattribute,pt_topricefor,MAX(pt_main) as pt_main, MAX(pt_rskey) as pt_rskey,max(pt_rmkey) pt_rmkey,max(pt_rsname) pt_rsname, max(pt_ctname) pt_ctname, max(pt_rmname) pt_rmname, max(pt_rcname) pt_rcname, max(pt_acname) pt_acname,
MAX(pt_childagefrom) pt_childagefrom,MAX(pt_childageto) pt_childageto,MAX(pt_childagefrom2) pt_childagefrom2,MAX(pt_childageto2) pt_childageto2,MAX(pt_hdname) pt_hdname,MAX(pt_tourname) pt_tourname,MAX(pt_pncode) pt_pncode,MAX(pt_hdstars) pt_hdstars,
pt_hotelkeys, MAX(pt_hotelnights) pt_hotelnights, MAX(pt_hotelstars) pt_hotelstars, pt_pansionkeys,
MAX(pt_key) pt_key,MAX(CASE WHEN (pt_days=3 and pt_nights=2) THEN pt_price ELSE -999999999 END ) p_3_2,SUM(CASE WHEN (pt_days=3 and pt_nights=2) THEN pt_key ELSE 0 END) pk_3_2,MAX(CASE WHEN (pt_days=4 and pt_nights=2) THEN pt_price ELSE -999999999 END ) p_4_2,SUM(CASE WHEN (pt_days=4 and pt_nights=2) THEN pt_key ELSE 0 END) pk_4_2,MAX(CASE WHEN (pt_days=4 and pt_nights=3) THEN pt_price ELSE -999999999 END ) p_4_3,
	SUM(CASE WHEN (pt_days=4 and pt_nights=3) THEN pt_key ELSE 0 END) pk_4_3,MAX(CASE WHEN (pt_days=5 and pt_nights=3) THEN pt_price ELSE -999999999 END ) p_5_3,SUM(CASE WHEN (pt_days=5 and pt_nights=3) THEN pt_key ELSE 0 END) pk_5_3,MAX(CASE WHEN (pt_days=5 and pt_nights=4) THEN pt_price ELSE -999999999 END ) p_5_4,SUM(CASE WHEN (pt_days=5 and pt_nights=4) THEN pt_key ELSE 0 END) pk_5_4,MAX(CASE WHEN (pt_days=6 and pt_nights=4) THEN pt_price ELSE -999999999 END ) p_6_4,SUM(CASE WHEN (pt_days=6 and pt_nights=4) THEN pt_key ELSE 0 END) pk_6_4,MAX(CASE WHEN (pt_days=6 and pt_nights=5) THEN pt_price ELSE -999999999 END ) p_6_5,SUM(CASE WHEN (pt_days=6 and pt_nights=5) THEN pt_key ELSE 0 END) pk_6_5,MAX(CASE WHEN (pt_days=7 and pt_nights=5) THEN pt_price ELSE -999999999 END ) p_7_5,SUM(CASE WHEN (pt_days=7 and pt_nights=5) THEN pt_key ELSE 0 END) pk_7_5,
	MAX(CASE WHEN (pt_days=7 and pt_nights=6) THEN pt_price ELSE -999999999 END ) p_7_6,SUM(CASE WHEN (pt_days=7 and pt_nights=6) THEN pt_key ELSE 0 END) pk_7_6,MAX(CASE WHEN (pt_days=8 and pt_nights=6) THEN pt_price ELSE -999999999 END ) p_8_6,SUM(CASE WHEN (pt_days=8 and pt_nights=6) THEN pt_key ELSE 0 END) pk_8_6,MAX(CASE WHEN (pt_days=8 and pt_nights=7) THEN pt_price ELSE -999999999 END ) p_8_7,SUM(CASE WHEN (pt_days=8 and pt_nights=7) THEN pt_key ELSE 0 END) pk_8_7,MAX(CASE WHEN (pt_days=9 and pt_nights=7) THEN pt_price ELSE -999999999 END ) p_9_7,SUM(CASE WHEN (pt_days=9 and pt_nights=7) THEN pt_key ELSE 0 END) pk_9_7,MAX(CASE WHEN (pt_days=9 and pt_nights=8) THEN pt_price ELSE -999999999 END ) p_9_8,SUM(CASE WHEN (pt_days=9 and pt_nights=8) THEN pt_key ELSE 0 END) pk_9_8,MAX(CASE WHEN (pt_days=10 and pt_nights=8) THEN pt_price ELSE -999999999 END ) p_10_8,SUM(CASE WHEN (pt_days=10 and pt_nights=8) THEN pt_key ELSE 0 END) pk_10_8,
	MAX(CASE WHEN (pt_days=10 and pt_nights=9) THEN pt_price ELSE -999999999 END ) p_10_9,SUM(CASE WHEN (pt_days=10 and pt_nights=9) THEN pt_key ELSE 0 END) pk_10_9,MAX(CASE WHEN (pt_days=11 and pt_nights=9) THEN pt_price ELSE -999999999 END ) p_11_9,SUM(CASE WHEN (pt_days=11 and pt_nights=9) THEN pt_key ELSE 0 END) pk_11_9,MAX(CASE WHEN (pt_days=11 and pt_nights=10) THEN pt_price ELSE -999999999 END ) p_11_10,SUM(CASE WHEN (pt_days=11 and pt_nights=10) THEN pt_key ELSE 0 END) pk_11_10,MAX(CASE WHEN (pt_days=12 and pt_nights=10) THEN pt_price ELSE -999999999 END ) p_12_10,SUM(CASE WHEN (pt_days=12 and pt_nights=10) THEN pt_key ELSE 0 END) pk_12_10,MAX(CASE WHEN (pt_days=12 and pt_nights=11) THEN pt_price ELSE -999999999 END ) p_12_11,SUM(CASE WHEN (pt_days=12 and pt_nights=11) THEN pt_key ELSE 0 END) pk_12_11,MAX(CASE WHEN (pt_days=13 and pt_nights=11) THEN pt_price ELSE -999999999 END ) p_13_11,SUM(CASE WHEN (pt_days=13 and pt_nights=11) THEN pt_key ELSE 0 END) pk_13_11,MAX(CASE WHEN (pt_days=13 and pt_nights=12) THEN pt_price ELSE -999999999 END ) p_13_12,SUM(CASE WHEN (pt_days=13 and pt_nights=12) THEN pt_key ELSE 0 END) pk_13_12,MAX(CASE WHEN (pt_days=14 and pt_nights=12) THEN pt_price ELSE -999999999 END ) p_14_12,
	SUM(CASE WHEN (pt_days=14 and pt_nights=12) THEN pt_key ELSE 0 END) pk_14_12,MAX(CASE WHEN (pt_days=14 and pt_nights=13) THEN pt_price ELSE -999999999 END ) p_14_13,SUM(CASE WHEN (pt_days=14 and pt_nights=13) THEN pt_key ELSE 0 END) pk_14_13,MAX(CASE WHEN (pt_days=15 and pt_nights=13) THEN pt_price ELSE -999999999 END ) p_15_13,SUM(CASE WHEN (pt_days=15 and pt_nights=13) THEN pt_key ELSE 0 END) pk_15_13,MAX(CASE WHEN (pt_days=15 and pt_nights=14) THEN pt_price ELSE -999999999 END ) p_15_14,SUM(CASE WHEN (pt_days=15 and pt_nights=14) THEN pt_key ELSE 0 END) pk_15_14,MAX(CASE WHEN (pt_days=16 and pt_nights=14) THEN pt_price ELSE -999999999 END ) p_16_14,SUM(CASE WHEN (pt_days=16 and pt_nights=14) THEN pt_key ELSE 0 END) pk_16_14,MAX(CASE WHEN (pt_days=16 and pt_nights=15) THEN pt_price ELSE -999999999 END ) p_16_15,SUM(CASE WHEN (pt_days=16 and pt_nights=15) THEN pt_key ELSE 0 END) pk_16_15,MAX(CASE WHEN (pt_days=17 and pt_nights=15) THEN pt_price ELSE -999999999 END ) p_17_15,
	SUM(CASE WHEN (pt_days=17 and pt_nights=15) THEN pt_key ELSE 0 END) pk_17_15,MAX(CASE WHEN (pt_days=17 and pt_nights=16) THEN pt_price ELSE -999999999 END ) p_17_16,SUM(CASE WHEN (pt_days=17 and pt_nights=16) THEN pt_key ELSE 0 END) pk_17_16,MAX(CASE WHEN (pt_days=18 and pt_nights=16) THEN pt_price ELSE -999999999 END ) p_18_16,SUM(CASE WHEN (pt_days=18 and pt_nights=16) THEN pt_key ELSE 0 END) pk_18_16,MAX(CASE WHEN (pt_days=18 and pt_nights=17) THEN pt_price ELSE -999999999 END ) p_18_17,SUM(CASE WHEN (pt_days=18 and pt_nights=17) THEN pt_key ELSE 0 END) pk_18_17,MAX(CASE WHEN (pt_days=19 and pt_nights=17) THEN pt_price ELSE -999999999 END ) p_19_17,SUM(CASE WHEN (pt_days=19 and pt_nights=17) THEN pt_key ELSE 0 END) pk_19_17,MAX(CASE WHEN (pt_days=19 and pt_nights=18) THEN pt_price ELSE -999999999 END ) p_19_18,SUM(CASE WHEN (pt_days=19 and pt_nights=18) THEN pt_key ELSE 0 END) pk_19_18,MAX(CASE WHEN (pt_days=20 and pt_nights=18) THEN pt_price ELSE -999999999 END ) p_20_18,SUM(CASE WHEN (pt_days=20 and pt_nights=18) THEN pt_key ELSE 0 END) pk_20_18,
	MAX(CASE WHEN (pt_days=20 and pt_nights=19) THEN pt_price ELSE -999999999 END ) p_20_19,SUM(CASE WHEN (pt_days=20 and pt_nights=19) THEN pt_key ELSE 0 END) pk_20_19,MAX(CASE WHEN (pt_days=21 and pt_nights=19) THEN pt_price ELSE -999999999 END ) p_21_19,SUM(CASE WHEN (pt_days=21 and pt_nights=19) THEN pt_key ELSE 0 END) pk_21_19,MAX(CASE WHEN (pt_days=21 and pt_nights=20) THEN pt_price ELSE -999999999 END ) p_21_20,SUM(CASE WHEN (pt_days=21 and pt_nights=20) THEN pt_key ELSE 0 END) pk_21_20,MAX(CASE WHEN (pt_days=22 and pt_nights=20) THEN pt_price ELSE -999999999 END ) p_22_20,SUM(CASE WHEN (pt_days=22 and pt_nights=20) THEN pt_key ELSE 0 END) pk_22_20,MAX(CASE WHEN (pt_days=22 and pt_nights=21) THEN pt_price ELSE -999999999 END ) p_22_21,SUM(CASE WHEN (pt_days=22 and pt_nights=21) THEN pt_key ELSE 0 END) pk_22_21,MAX(CASE WHEN (pt_days=23 and pt_nights=21) THEN pt_price ELSE -999999999 END ) p_23_21,SUM(CASE WHEN (pt_days=23 and pt_nights=21) THEN pt_key ELSE 0 END) pk_23_21 from dbo.mwPriceTable t1 inner join (select pt_cnkey cnkey, pt_ctkeyfrom ctkeyfrom,pt_tourtype tourtype,pt_mainplaces mainplaces, pt_addplaces addplaces, pt_tourdate tourdate,pt_pnkey pnkey,pt_pansionkeys pansionkeys,pt_days days,pt_nights nights,pt_hdkey hdkey,pt_hotelkeys hotelkeys,pt_hdpartnerkey hdpartnerkey,pt_hrkey hrkey,max(pt_key) ptkey from dbo.mwPriceTable group by pt_cnkey, pt_ctkeyfrom,pt_tourtype,pt_mainplaces, pt_addplaces,pt_tourdate,pt_pnkey,pt_pansionkeys,pt_nights,pt_days,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,pt_hrkey,pt_spo) t2
on t1.pt_cnkey=t2.cnkey and t1.pt_ctkeyfrom=t2.ctkeyfrom and t1.pt_tourtype=t2.tourtype and t1.pt_mainplaces=t2.mainplaces and t1.pt_addplaces=t2.addplaces and t1.pt_tourdate=t2.tourdate and t1.pt_pnkey=t2.pnkey and t1.pt_pansionkeys=t2.pansionkeys and t1.pt_nights=t2.nights and t1.pt_days=t2.days and t1.pt_hdkey=t2.hdkey and t1.pt_hotelkeys = t2.hotelkeys and t1.pt_hdpartnerkey = t2.hdpartnerkey and t1.pt_hrkey=t2.hrkey and t1.pt_key=t2.ptkey group by pt_cnkey, pt_ctkeyfrom,pt_mainplaces,pt_tourtype, pt_addplaces, pt_tourdate,pt_pnkey,pt_pansionkeys,pt_tourkey,pt_tlkey,pt_tlattribute,pt_topricefor,pt_hdkey,pt_hotelkeys,pt_hdpartnerkey,pt_ctkey, pt_hrkey
GO

grant select on dbo.mwPriceTableViewDesc to public
go

-- alter_Dup_User.sql
if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='dup_user' and COLUMN_NAME='us_city') < 50)
	alter table dup_user alter column us_City varchar(50)
GO


-- 100215(CreateTable_mwHotelDetails).sql
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwHotelDetails]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	CREATE TABLE [dbo].[mwHotelDetails]
	(
		[htd_hdkey] [int] NOT NULL,
		[htd_minprice] [float] NULL,
		[htd_minpricedate] [datetime] NULL,
		[htd_minpricerate] [varchar](3) NULL,
		[htd_minpricectfrom] [int] NULL,
		[htd_minpricekey] [int] NULL,
		[htd_needupdate] [smallint] NULL,
		
		CONSTRAINT [PK_mwHotelDetails] PRIMARY KEY CLUSTERED 
		(
			[htd_hdkey] ASC
		)
		ON [PRIMARY]
	) ON [PRIMARY]
GO

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on [dbo].[mwHotelDetails] to public
GO

-- drop table mwHotelDetails

-- 100215(Index_mwPriceDataTable_mwHotelDetails).sql
if not exists(select * from sysindexes where name = 'x_mwHotelDetails' and id = object_id(N'[dbo].[mwPriceDataTable]'))
	CREATE NONCLUSTERED INDEX [x_mwHotelDetails] ON [dbo].[mwPriceDataTable] 
	(
		pt_isenabled desc,
		pt_tourvalid asc,
		pt_main desc,
		pt_hdkey asc,
		pt_price asc,
		pt_tourdate asc,
		pt_rate asc
	)
	ON [PRIMARY]
go

-- fn_FindInsuranceForPrice.sql
if exists(select id from sysobjects where xtype='fn' and name='FindInsuranceForPrice')
	drop function dbo.FindInsuranceForPrice
go

create function [dbo].[FindInsuranceForPrice](@svKey int, @price int, @code int, @partnerkey int, @packetkey int, @date varchar(10), @nDays int)
returns int
as
begin
	declare @insurances table(a1_key int, a1_cost int);
	declare @result int

	insert into @insurances
	select 
		a1_key, 
		case when IsNumeric(a1_name)=1 then cast(a1_name as int) else 0 end
	from adddescript1
	where a1_svkey = @svKey

	select top 1 @result = a1_key from @insurances 
	where a1_cost >= @price 
		--MEG00026299 Paul G 10.03.2010 
		--проверка на то, что у страховки есть цена
		and exists(select * from tbl_costs 
					where CS_SVKey = @svKey and CS_Code = @code and CS_SubCode1 = a1_key and 
						CS_PrKey = @partnerkey and CS_PkKey = @packetkey and ((convert(datetime, @date) between CS_CheckInDateBEG and CS_CheckInDateEnd) or (CS_CheckInDateBEG is null and CS_CheckInDateEnd is null)) and (CS_DateEnd >= convert(datetime, @date) and CS_DATE <= convert(datetime, @date)+isnull(@nDays,0) or (CS_DATE is null and CS_DateEnd is null)))
	order by a1_cost

	delete from @insurances

	return @result
end

go

grant exec on [dbo].[FindInsuranceForPrice] to public

go


-- 20100310(InsertUseHolidayRule).sql
if not exists(select 1 from dbo.SystemSettings where SS_ParmName like 'SYSUseHolidayRule')
	insert into dbo.SystemSettings(SS_ParmName, SS_ParmValue) values('SYSUseHolidayRule', '0')
GO

-- 20100310(AlterTable_CalculatePriceLists).sql
if not exists(select id from syscolumns where id = OBJECT_ID('CalculatingPriceLists') and name = 'CP_UseHolidayRule')
     alter TABLE [dbo].[CalculatingPriceLists] add [CP_UseHolidayRule] smallint not null default(0)
GO

-- 100311(alter_TurList).sql
alter table tbl_TurList alter column [tl_description] varchar(2000) NULL 
go

exec sp_refreshviewforall Turlist
go

-- sp_GetNewKeys.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetNewKeys]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetNewKeys]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

CREATE procedure [dbo].[GetNewKeys]
  (@sTable varchar(50) = null,
  @nKeyCount int,
  @nNewKey int = null output)
AS
declare @KeyTable varchar(100)
set @KeyTable=replace(@sTable,'Key_','')
exec GetNKeys @KeyTable, @nKeyCount,@nNewKey output
return 0
GO
GRANT EXEC ON [dbo].[GetNewKeys] TO PUBLIC
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
					+ IsNull((select top 1 IsNull(' ' + left(convert(varchar(8), as_timefrom, 108),5) + ' ','') from airseason where as_chkey=ch_key and dateadd(day, ts_day, @TourDate) between as_datefrom and as_dateto),'') 
					+ '-' + isnull(ch_portcodeto, '') + '(' + isnull(cityto.ct_name, '') + ')'
					--MEG00026439 Paul G 11.03.2010 Вывожу расписание рейсов
					+ IsNull((select top 1 IsNull(' ' + left(convert(varchar(8), as_timeto, 108),5) + ' ','') from airseason where as_chkey=ch_key and dateadd(day, ts_day, @TourDate) between as_datefrom and as_dateto),'') 
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


-- 100216(CreateTable_HotelTypes).sql

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[HotelTypes]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	CREATE TABLE [dbo].[HotelTypes](
		[htt_id] [int] IDENTITY(1,1) NOT NULL,
		[htt_name] [varchar](32) NULL,
		[htt_namelat] [varchar](32) NULL,
	CONSTRAINT [PK_HotelTypes] PRIMARY KEY CLUSTERED 
	(
		[htt_id] ASC
	)  ON [PRIMARY]
	) ON [PRIMARY]
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on [dbo].[HotelTypes] to public
GO

insert into HotelTypes(htt_name) values('Рекомендуемые')
go

-- 100216(CreateTable_HotelTypeRelations).sql
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[HotelTypeRelations]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	CREATE TABLE [dbo].[HotelTypeRelations](
		[htr_id] [int] IDENTITY(1,1) NOT NULL,
		[htr_hdkey] [int] NULL,
		[htr_httkey] [int] NULL,
	 CONSTRAINT [PK_HotelTypeRelations] PRIMARY KEY CLUSTERED 
	(
		[htr_id] ASC
	) ON [PRIMARY]
	) ON [PRIMARY]
go

if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_HotelTypeRelations_HotelTypes]'))
	ALTER TABLE [dbo].[HotelTypeRelations]  WITH CHECK ADD  CONSTRAINT [FK_HotelTypeRelations_HotelTypes] FOREIGN KEY([htr_httkey])
	REFERENCES [dbo].[HotelTypes] ([htt_id])
	ON DELETE CASCADE
GO

if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_HotelTypeRelations_Hotels]'))
	ALTER TABLE [dbo].[HotelTypeRelations]  WITH CHECK ADD  CONSTRAINT [FK_HotelTypeRelations_Hotels] FOREIGN KEY([htr_hdkey])
	REFERENCES [dbo].[HotelDictionary] ([hd_key])
	ON DELETE CASCADE
GO

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on [dbo].[HotelTypeRelations] to public
GO

-- 20100219(AlterTables_InsCases).sql
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[InsCases]') and name = 'IC_IsIncludedInCalcPrem')
	alter table dbo.InsCases add IC_IsIncludedInCalcPrem smallint
go

-- 100318(alter_Accmdmentype).sql
ALTER TABLE Accmdmentype ALTER COLUMN ac_name varchar(70)
go

ALTER TABLE Accmdmentype ALTER COLUMN ac_code varchar(70) null
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
DECLARE @CS_ByDay INT, @CS_Profit decimal(14,4), @CS_ID INT, @TMP_Rate varchar(2), @course decimal (14,6), @CS_CheckInDateBEG datetime, @CS_CheckInDateEND datetime, @CS_DateSellBeg datetime, @CS_DateSellEnd datetime, @NotCalculatedCosts smallint, @CS_Pax smallint, @FindCostByPeriod smallint


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
		CL_CostNetto decimal(14,4),
		CL_Cost decimal(14,4),
		CL_Discount smallint,
		CL_Type smallint,
		CL_Rate varchar(2),
		CL_Course decimal(14,4),
		CL_Pax smallint default 1,
		CL_ByDay smallint,
		CL_Part smallint,
		CL_Profit decimal(14,4))

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

		If @CS_ByDay = 0 and @CS_Date = @date and @CS_DateEnd <= (@date + @days) and @days > 1
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

-- 100204(alter_mwPriceHotels).sql.sql
if not exists(select id from syscolumns where id = OBJECT_ID('mwPriceHotels') and name = 'ph_sdkey')
	ALTER TABLE mwPriceHotels ADD ph_sdkey int null
go

update mwPriceHotels set ph_sdkey = mwsdt.sd_key
	from mwSpoDataTable mwsdt
	where mwsdt.sd_tourkey = mwPriceHotels.sd_tourkey and mwsdt.sd_hdkey = mwPriceHotels.sd_mainhdkey and ph_sdkey is null
go


-- tr_mwUpdateHotel.sql
if exists(select id from sysobjects where xtype='tr' and name='mwUpdateHotel')
	drop trigger dbo.mwUpdateHotel
go

CREATE TRIGGER [dbo].[mwUpdateHotel] ON [dbo].[HotelDictionary] 
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
				pt_hdstars = hd_stars
			from inserted where pt_hdkey = hd_key
		end
		else
		begin
			declare @objName nvarchar(50)
			declare @sql nvarchar(500)
			declare @countryKey int
			select	@countryKey = hd_cnkey from inserted

			select hd_key, hd_rskey, hd_stars into #temp from inserted

			declare delCursor cursor fast_forward read_only for select name from sysobjects where name like 'mwPriceDataTable_' + ltrim(rtrim(cast(isnull(@countryKey, 0) as varchar))) + '_%' and xtype='u'
			open delCursor
			fetch next from delCursor into @objName
			while(@@fetch_status = 0)
			begin
				set @sql = '
					update ' + @objName + ' with(rowlock)
						set pt_rskey = hd_rskey,
							pt_hdstars = hd_stars
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
go


-- 20100319_InsertObjectAliases.sql
if not exists (select 1 from dbo.ObjectAliases where OA_Id = 11006)
	insert into dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TableID) values(11006, '', 'Копирование цен в таблицы PriceList', 0)
GO

if not exists (select 1 from dbo.ObjectAliases where OA_Id = 11007)
	insert into dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TableID) values(11007, '', 'PriceList: 0 - удалять дублирующиеся цены, 1 - не удалять', 0)
GO

if not exists (select 1 from dbo.ObjectAliases where OA_Id = 11008)
	insert into dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TableID) values(11008, '', 'Правило выходного дня: 0 - не использовать, 1 - использовать', 0)
GO

-- 100309_CreateTable_StatusRules.sql
IF (OBJECT_ID('dbo.StatusRuleTypes') IS NULL)
BEGIN
	CREATE TABLE dbo.StatusRuleTypes
	(
		SRT_Id INT NOT NULL,
		SRT_Name NVARCHAR(64) NOT NULL,
		SRT_NameLat NVARCHAR(64) NOT NULL,
		SRT_Description NVARCHAR(255) NULL, 
		CONSTRAINT PK_StatusRuleTypes PRIMARY KEY CLUSTERED 
		(
			SRT_Id ASC
		) ON [PRIMARY]
	) ON [PRIMARY]

	INSERT INTO dbo.StatusRuleTypes (SRT_Id, SRT_Name, SRT_NameLat, SRT_Description) 
	VALUES (
		1, 
		'Одна услуга -> Путёвка',
		'Single Service -> Reservation',
		'Статус путёвки = ХХХХ, если хотя бы одна услуга находится в статусе YYYY, кроме услуг типа ZZZZ / Reservation status = XXXX if at least one service has YYYY status, except for services of ZZZZ type'
	);

	INSERT INTO dbo.StatusRuleTypes (SRT_Id, SRT_Name, SRT_NameLat, SRT_Description) 
	VALUES (
		2, 
		'Все услуги -> Путёвка',
		'All Services -> Reservation',
		'Статус путёвки = ХХХХ, если все услуги находится в статусе УУУУ, кроме услуг типа ZZZZ / Reservation status = XXXX if all services have YYYY status, except for services of ZZZZ type'
	);

--	INSERT INTO dbo.StatusRuleTypes (SRT_Id, SRT_Name, SRT_NameLat, SRT_Description) 
--	VALUES (
--		3, 
--		'Путёвка -> Услуги',
--		'Reservation -> Services',
--		'Статус всех услуг = ХХХХ (кроме услуг типа ZZZZ), если путёвка находится статусе YYYY / Status of all services = ХХХХ (except for services of ZZZZ type) if the reservation has YYYY status'
--	);
END
GO

IF (OBJECT_ID('dbo.StatusRules') IS NULL)
BEGIN
	CREATE TABLE dbo.StatusRules
	(
		SR_Id INT IDENTITY(1,1) NOT NULL,
		SR_TypeId INT NOT NULL,
		SR_OnWaitList SMALLINT NULL,
		SR_ReservationStatusId INT NOT NULL,
		SR_ServiceStatusId INT NULL,
		SR_ExcludeServiceId INT NULL,
		SR_Priority INT NOT NULL,
		SR_CountryId INT NULL,
		SR_TourId INT NULL
		CONSTRAINT PK_StatusRules PRIMARY KEY CLUSTERED 
		(
			SR_Id ASC
		) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE dbo.StatusRules WITH CHECK 
		ADD CONSTRAINT FK_StatusRules_StatusRuleTypes FOREIGN KEY(SR_TypeId)
		REFERENCES dbo.StatusRuleTypes (SRT_Id)

	ALTER TABLE dbo.StatusRules WITH CHECK 
		ADD CONSTRAINT FK_StatusRules_OrderStatus FOREIGN KEY(SR_ReservationStatusId)
		REFERENCES dbo.Order_Status (OS_CODE)

	ALTER TABLE dbo.StatusRules WITH CHECK 
		ADD CONSTRAINT FK_StatusRules_Controls FOREIGN KEY(SR_ServiceStatusId)
		REFERENCES dbo.Controls (CR_KEY)

	ALTER TABLE dbo.StatusRules WITH CHECK 
		ADD CONSTRAINT FK_StatusRules_Service FOREIGN KEY(SR_ExcludeServiceId)
		REFERENCES dbo.Service (SV_KEY)

	ALTER TABLE dbo.StatusRules WITH CHECK 
		ADD CONSTRAINT FK_StatusRules_tblCountry FOREIGN KEY(SR_CountryId)
		REFERENCES dbo.tbl_Country (CN_KEY)

	ALTER TABLE dbo.StatusRules WITH CHECK 
		ADD CONSTRAINT FK_StatusRules_tblTurList FOREIGN KEY(SR_TourId)
		REFERENCES dbo.tbl_TurList (TL_KEY)

	---------------------------
	-- DEFAULT Status Rule Set
	---------------------------
	INSERT INTO dbo.StatusRules
	(
		SR_TypeId,
		SR_OnWaitList,
		SR_ReservationStatusId,
		SR_ServiceStatusId,
		SR_ExcludeServiceId,
		SR_Priority,
		SR_CountryId,
		SR_TourId
	) 
	VALUES
	(
		1,		-- 'Service -> Reservation'
		1, 
		3,		-- Wait-list
		NULL,
		NULL,
		1,		-- Priority
		NULL,
		NULL
	)

	INSERT INTO dbo.StatusRules
	(
		SR_TypeId,
		SR_OnWaitList,
		SR_ReservationStatusId,
		SR_ServiceStatusId,
		SR_ExcludeServiceId,
		SR_Priority,
		SR_CountryId,
		SR_TourId
	) 
	VALUES
	(
		2,		-- 'Services -> Reservation'
		NULL, 
		7,		-- OK
		0,		-- OK
		NULL,
		2,		-- Priority
		NULL,
		NULL
	)
END
GO

GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.StatusRules TO PUBLIC
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.StatusRuleTypes TO PUBLIC


-- 100319_AddSetting.sql
if  not exists(select 1 from  [dbo].systemsettings where ss_parmname='SYSTouristAgePerService')
insert into [dbo].systemsettings (ss_parmname, ss_parmvalue) values('SYSTouristAgePerService', 0)
go

-- sp_mwAutentificate.sql
if exists(select id from sysobjects where xtype='p' and name='mwAutentificate')
	drop proc dbo.mwAutentificate
go

create procedure [dbo].[mwAutentificate]
(
	@login varchar(50),
	@password varchar(256),
	@type smallint = null
)
as
begin
	if @type is null
	begin
		select us_key
		from dup_user
		where us_id = @login and us_password = @password and us_reg = 1
	end
	else
	begin
		select us_key
		from dup_user
		where us_id = @login and us_password = @password and us_reg = 1 and us_type = @type
	end
end
go

grant exec on [dbo].[mwAutentificate] to public
go

-- sp_mwGetUserKeyByLogin.sql
if exists(select id from sysobjects where xtype='p' and name='mwGetUserKeyByLogin')
	drop proc dbo.mwGetUserKeyByLogin
go

create procedure [dbo].[mwGetUserKeyByLogin]
(
	@login varchar(30)
)
as
begin
	select us_key
	from userlist
	where us_userid=@login
end
go

grant exec on [dbo].[mwGetUserKeyByLogin] to public
go

-- 100204(AlterTable_FileHeaders).sql
if not exists(select * from dbo.syscolumns where Name = N'FH_IsPublic' and id = Object_ID(N'dbo.FileHeaders'))
begin
	alter table dbo.FileHeaders
	add  FH_IsPublic bit not null default 1
end
go

-- 100208UpdateDescriptions.sql
declare @val_old varchar(8000)
declare @val_new varchar(8000)
declare @ds_key int
declare cur cursor for	select  ds_key from dbo.descriptions where ds_tableid=9 and ds_dtkey=122
open cur
fetch next from cur into @ds_key
while @@fetch_status = 0
begin
  select @val_old = ds_value  from dbo.descriptions where ds_key=@ds_key
  set @val_new = replace(@val_old, 'translit="False"', 'translit="0"')
  set @val_new = replace(@val_new, 'translit="True"', 'translit="1"')
  if (@val_new <> @val_old)
    update dbo.Descriptions set ds_value = @val_new where ds_key=@ds_key
  fetch next from cur into @ds_key
end
close cur
deallocate cur
GO

-- 100121(mwSinglePrice).sql
if exists(select 1 from sysindexes where id = object_id('dbo.mwPriceDataTable') and name = 'x_singleprice')
	drop index dbo.mwPriceDataTable.x_singleprice
go

declare @sql nvarchar(4000)
if (@@version not like '%SQL%Server%2000%')
	set @sql = '
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
	[pt_tourkey],
	[pt_price],
	pt_ctkeyfrom)'
else
	set @sql = '
	create index x_singleprice on mwPriceDataTable(
	pt_tourdate,
	pt_hdkey,
	pt_rmkey,
	pt_rckey,
	pt_ackey,
	pt_pnkey,
	pt_days,
	pt_nights,
	pt_hdpartnerkey,
	pt_chprkey,
	pt_tourtype,
	pt_main,
	pt_isenabled,
	pt_tourkey,
	pt_price,
	pt_ctkeyfrom)
'
exec sp_executesql @sql
go

if exists(select 1 from sysindexes where id = object_id('dbo.mwPriceDataTable') and name = 'x_singleprice_tour')
	drop index dbo.mwPriceDataTable.x_singleprice_tour
go

declare @sql nvarchar(4000)
if (@@version not like '%SQL%Server%2000%')
	set @sql = '
	CREATE NONCLUSTERED INDEX [x_singleprice_tour] ON [dbo].[mwPriceDataTable] 
	(
		[pt_tourkey] ASC,
		[pt_main] ASC
	)
	INCLUDE ( [pt_tourdate],
	[pt_hdkey],
	[pt_rmkey],
	[pt_rckey],
	[pt_ackey],
	[pt_pnkey],
	[pt_days],
	[pt_nights],
	[pt_hdpartnerkey],
	[pt_chprkey],
	[pt_tourtype],
	pt_ctkeyfrom)
'
else
	set @sql = '
	create index x_singleprice_tour on mwPriceDataTable(
		pt_tourkey,
		pt_main,
		pt_tourdate,
		pt_hdkey,
		pt_rmkey,
		pt_rckey,
		pt_ackey,
		pt_pnkey,
		pt_days,
		pt_nights,
		pt_hdpartnerkey,
		pt_chprkey,
		pt_tourtype,
		pt_ctkeyfrom)
'
exec sp_executesql @sql
go

-- 100212(DropSettingColumns).sql
-- переносим данные из таблицы Setting в SystemSettings (Обоснование скидки, источник рекламы, дата входа)
declare @sql nvarchar (4000)
if exists (select * from [dbo].[syscolumns] where id = object_id(N'[dbo].[Setting]') and name = 'ST_Date')
begin
	set @sql ='
	declare @dtDate datetime
	select @dtDate = ST_Date from [dbo].[Setting]
	if not exists( select 1 from [dbo].[SystemSettings] where ss_parmname= ''SYSDate'' )
	begin
		insert into [dbo].[SystemSettings] (ss_parmname, ss_parmvalue) 
		values (''SYSDate'', @dtDate)
		alter table [dbo].[Setting] drop column ST_DATE
	end'
	exec sp_executesql @sql
end
go

declare @sql nvarchar (4000)
if exists (select * from [dbo].[syscolumns] where id = object_id(N'[dbo].[Setting]') and name = 'ST_CauseDiscount')
begin
	set @sql ='
	declare @nCauseDiscount smallint
	select @nCauseDiscount = ST_CauseDiscount from [dbo].[Setting]
	if not exists( select 1 from [dbo].[SystemSettings] where ss_parmname= ''SYSCauseDiscount'' )
	begin
		insert into [dbo].[SystemSettings] (ss_parmname, ss_parmvalue, ss_name) 
		values (''SYSCauseDiscount'', @nCauseDiscount, ''Обоснование скидки'')
		alter table [dbo].[Setting] drop column ST_CauseDiscount
	end'
	exec sp_executesql @sql
end
go

declare @sql nvarchar (4000)
if exists (select * from [dbo].[syscolumns] where id = object_id(N'[dbo].[Setting]') and name = 'ST_Advertisement')
begin
	set @sql ='
	declare @nAdvertisement smallint
	select @nAdvertisement = ST_Advertisement from [dbo].[Setting]
	if not exists( select 1 from [dbo].[SystemSettings] where ss_parmname= ''SYSAdvertisement'' )
	begin
		insert into [dbo].[SystemSettings] (ss_parmname, ss_parmvalue, ss_name) 
		values (''SYSAdvertisement'', @nAdvertisement, ''Источник рекламы'')
		alter table [dbo].[Setting] drop column ST_Advertisement
	end'
	exec sp_executesql @sql
end
go



-- (25032010)AlterTableCostsInsertNumber.sql
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[CostsInsertNumber]') and name = 'CIN_SVKEY')
	alter table dbo.CostsInsertNumber add CIN_SVKEY int
go

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[CostsInsertNumber]') and name = 'CIN_SPOKEY')
	alter table dbo.CostsInsertNumber add CIN_SPOKEY int
go

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[CostsInsertNumber]') and name = 'CIN_FilialKey')
	alter table dbo.CostsInsertNumber add CIN_FilialKey int
go

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[CostsInsertNumber]') and name = 'CIN_SupplierKey')
	alter table dbo.CostsInsertNumber add CIN_SupplierKey int
go

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[CostsInsertNumber]') and name = 'CIN_CODE')
	alter table dbo.CostsInsertNumber add CIN_CODE int
go

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[CostsInsertNumber]') and name = 'CIN_USERkey')
	alter table dbo.CostsInsertNumber add CIN_USERkey int
go

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[CostsInsertNumber]') and name = 'CIN_Descriptions')
	alter table dbo.CostsInsertNumber add CIN_Descriptions nvarchar(150)
go

-- 100225_CreateTable_CostOffers.sql
if not exists (select 1 from sysobjects where id = object_id(N'[dbo].[Seasons]') and xtype = 'U')
CREATE TABLE [dbo].[Seasons]
(
	[SN_Id] [int] IDENTITY(1,1) NOT NULL,
	[SN_Name] [nvarchar](255) NOT NULL,
	[SN_NameLat] [nvarchar](255) NOT NULL,
	[SN_IsActive] [bit] NOT NULL CONSTRAINT [DF_Seasons_IsActive] DEFAULT ((0)),
	[SN_CreateDate] [datetime] NOT NULL CONSTRAINT [DF_Seasons_CreateDate] DEFAULT (getdate())
	CONSTRAINT [PK_Seasons] PRIMARY KEY CLUSTERED 
	(
		[SN_Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists (select 1 from sysobjects where id = object_id(N'[dbo].[CostOfferTypes]') and xtype = 'U')
CREATE TABLE [dbo].[CostOfferTypes]
(
	[COT_Id] [int] NOT NULL,
	[COT_Name] [nvarchar](20) NOT NULL,
	[COT_NameLat] [nvarchar](20) NOT NULL,
	CONSTRAINT [PK_CostOfferTypes] PRIMARY KEY CLUSTERED 
	(
		[COT_Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists (select 1 from sysobjects where id = object_id(N'[dbo].[CostOffers]') and xtype = 'U')
CREATE TABLE [dbo].[CostOffers]
(
	[CO_Id] [int] IDENTITY(1,1) NOT NULL,
	[CO_Name] [nvarchar](255) NOT NULL,
	[CO_NameLat] [nvarchar](255) NOT NULL,
	[CO_PartnerId] [int] NOT NULL,
	[CO_Comment] [nvarchar](1024) NULL,
	[CO_SaleDateBeg] [smalldatetime] NULL,
	[CO_SaleDateEnd] [smalldatetime] NULL,
	[CO_CreateDate] [datetime] NOT NULL CONSTRAINT [DF_CostOffers_CreateDate] DEFAULT (getdate()),
	[CO_TypeId] [int] NOT NULL,
	[CO_SeasonId] [int] NULL,
	[CO_IsRules] [bit] NOT NULL CONSTRAINT [DF_CostOffers_IsRules] DEFAULT (0),
	CONSTRAINT [PK_CostOffers] PRIMARY KEY CLUSTERED 
	(
		[CO_Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists (select 1 from sysobjects where name = 'FK_CostOffers_Seasons')
ALTER TABLE [dbo].[CostOffers] WITH CHECK 
	ADD CONSTRAINT [FK_CostOffers_Seasons] FOREIGN KEY([CO_SeasonId])
	REFERENCES [dbo].[Seasons] ([SN_Id])
GO

if not exists (select 1 from sysobjects where name = 'FK_CostOffers_CostOfferTypes')
ALTER TABLE [dbo].[CostOffers] WITH CHECK 
	ADD CONSTRAINT [FK_CostOffers_CostOfferTypes] FOREIGN KEY([CO_TypeId])
	REFERENCES [dbo].[CostOfferTypes] ([COT_Id])
GO

if not exists (select 1 from sysobjects where name = 'FK_CostOffers_Partners')
ALTER TABLE [dbo].[CostOffers] WITH CHECK 
	ADD CONSTRAINT [FK_CostOffers_Partners] FOREIGN KEY([CO_PartnerId])
	REFERENCES [dbo].[tbl_Partners] ([PR_Key])
GO

if not exists (select 1 from sysobjects where id = object_id(N'[dbo].[XYRules]') and xtype = 'U')
CREATE TABLE [dbo].[XYRules](
	[XY_Id] [int] IDENTITY(1,1) NOT NULL,
	[XY_XFrom] [smallint] NOT NULL,
	[XY_XTo] [smallint] NOT NULL,
	[XY_Sign] [nchar](1) NOT NULL,
	[XY_Y] [smallint] NOT NULL,
	[XY_CostOfferId] [int] NOT NULL,
	CONSTRAINT [PK_XYRules] PRIMARY KEY CLUSTERED 
	(
		[XY_Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists (select 1 from sysobjects where name = 'FK_XYRules_CostOffers')
ALTER TABLE [dbo].[XYRules]  WITH CHECK 
	ADD CONSTRAINT [FK_XYRules_CostOffers] FOREIGN KEY([XY_CostOfferId])
	REFERENCES [dbo].[CostOffers] ([CO_Id])
	ON DELETE CASCADE
GO

grant select, update, insert, delete on dbo.Seasons to public
go
grant select, update, insert, delete on dbo.CostOffers to public
go
grant select, update, insert, delete on dbo.CostOfferTypes to public
go
grant select, update, insert, delete on dbo.XYRules to public
go

-- (090918)mwflightdirections.sql
declare @sql nvarchar (4000)
if exists (select * from dbo.sysviews where name like 'mwFlightDirections')
begin
	set @sql='
	ALTER view [dbo].[mwFlightDirections] as
	select distinct tl_key as fd_trkey, tl_cnkey as fd_cnkey, 
				ch_citykeyfrom as fd_ctkeyfrom, ch_citykeyto as fd_ctkeyto
	from tbl_TurList inner join turservice on (tl_key = ts_trkey and ts_svkey = 1) inner join tbl_Costs on 
	(cs_svkey = 1 and cs_pkkey = ts_pkkey ) inner join Charter on
		(cs_svkey = 1 and cs_code = ch_key and ch_citykeyfrom = ts_subcode2 and  ch_citykeyto = ts_ctkey)
	where cs_dateend >= getdate() and
		tl_key in (select ds_pkkey from descriptions where ds_dtkey = 115 and ds_tableid = 37 and ds_value like ''%1%'')
		and exists(select top 1 td_trkey from turdate where td_date >= getdate() and td_trkey = tl_key)'
	
	exec sp_executesql @sql

	exec sp_refreshviewforall [mwFlightDirections]
end
/* ранее используемые представления
select distinct tl_key as fd_trkey, tl_cnkey as fd_cnkey, 
			ch_citykeyfrom as fd_ctkeyfrom, ch_citykeyto as fd_ctkeyto
from tbl_TurList inner join turservice on (tl_key = ts_trkey and ts_svkey = 1) inner join tbl_Costs on (cs_svkey = 1 and cs_pkkey = ts_pkkey) 
inner join Charter on
	(cs_svkey = 1 and cs_code = ch_key )
where cs_dateend >= getdate() and
	tl_key in (select ds_pkkey from descriptions where ds_dtkey = 115 and ds_tableid = 37 and ds_value like '%1%')
	and exists(select top 1 td_trkey from turdate where td_date >= getdate() and td_trkey = tl_key) 
*/
/*
	select distinct tl_key as fd_trkey, tl_cnkey as fd_cnkey, 
			ch_citykeyfrom as fd_ctkeyfrom, ch_citykeyto as fd_ctkeyto
	from tbl_Costs inner join  tbl_TurList on cs_pkkey = tl_key inner join Charter on
		(cs_svkey = 1 and cs_code = ch_key)
	where cs_dateend >= getdate() and exists(select top 1 td_trkey from turdate where td_trkey = tl_key and td_date >= getdate()) and
		tl_key in (select ds_pkkey from descriptions where ds_dtkey = 115 and ds_tableid = 37 and ds_value like '%1%')
*/
GO

-- 100401_AlterConstraintDiscounts.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DS_PRKEY]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
	ALTER TABLE dbo.Discounts DROP CONSTRAINT [DS_PRKEY]
GO

ALTER TABLE dbo.Discounts WITH CHECK ADD CONSTRAINT [DS_PRKEY] FOREIGN KEY([DS_PRKEY])
REFERENCES [dbo].[tbl_Partners] ([PR_KEY]) 
ON DELETE CASCADE
GO

-- sp_mwSetOnline.sql
if object_id('dbo.mwTourLog', 'u') is not null
	drop table dbo.mwTourLog
go

create table dbo.mwTourLog(
	tl_id int identity primary key,
	tl_tourkey int
)
go

create index x_tourkey on dbo.mwTourLog(tl_tourkey)
go

grant select, insert, update, delete on dbo.mwTourLog to public
go

if object_id('dbo.mwSetOnline', 'p') is not null
	drop proc dbo.mwSetOnline
go

create proc dbo.mwSetOnline @tourCount smallint, @proc_name nvarchar(100)
as
begin
	declare @sql nvarchar(4000)
	set @sql = N'
	select top ' + ltrim(str(@tourCount)) + ' to_key 
	from tp_tours with(nolock) 
	where isnull(to_update, 0) = 0
		and to_key > isnull((select max(tl_tourkey) from dbo.mwTourLog with(nolock)), 0)
		and isnull(to_isenabled, 0) > 0
	order by to_key
	'

	create table #tours(
		tour_key int
	)

	insert into #tours exec(@sql)
	declare tour_cursor cursor fast_forward read_only for
		select tour_key
		from #tours

	open tour_cursor
	
	declare @tour_key int
	fetch next from tour_cursor into @tour_key

	while @@fetch_status = 0
	begin
		set @sql = N'exec ' + @proc_name + ' ' + ltrim(str(@tour_key)) + N'
		insert into dbo.mwTourLog(tl_tourkey) values (' + ltrim(str(@tour_key)) + N')
		'
		exec(@sql)

		fetch next from tour_cursor into @tour_key
	end

	close tour_cursor
	deallocate tour_cursor
end
go

grant exec on dbo.mwSetOnline to public
go

--if object_id('dbo.mwTesstt', 'p') is not null
--	drop proc dbo.mwTesstt
--go
--
--create proc dbo.mwTesstt @tourkey int
--as
--begin
--	print @tourkey
--end
--go
--
--grant exec on dbo.mwTesstt to public
--go



-- 20100402(AlterView_InsPolicyInfo).sql
If exists(Select 1 from sysviews where name = 'InsPolicyInfo' and CREATOR = 'DBO')
	DROP VIEW InsPolicyInfo
GO

CREATE VIEW [dbo].[InsPolicyInfo]
as
SELECT InsPolicy.IP_ID, InsPolicy.IP_PolicyNumber, 
	dbo.PolicyNeedSend(InsPolicy.IP_ID) IP_NeedSend, InsPolicy.IP_NMen, 
        InsPolicy.IP_IBRID_ANNUL, InsPolicy.IP_IFRID_ANNUL,
        InsPolicy.IP_IsMulti, InsPolicy.IP_IsCommonKoefs, InsPolicy.IP_RateOfExchange,
        InsPolicy.IP_IsNational, InsPolicy.IP_CreateDate, 
        InsPolicy.IP_DateBeg, InsPolicy.IP_DateEnd, DATEDIFF(day, InsPolicy.IP_DateBeg, InsPolicy.IP_DateEnd) + 1 as IP_NDays,
        InsPolicy.IP_IsJuridical, InsPolicy.IP_Tel, InsPolicy.IP_Adress, InsPolicy.IP_FIO,
	InsPolicy.IP_JurFullName, InsPolicy.IP_JurName, InsPolicy.IP_JurInn,
	CASE WHEN InsPolicy.IP_ARKEY IS NULL THEN 0 ELSE 1 END IP_IsAnnuled, 
        InsPolicy.IP_AnnulDate, InsPolicy.IP_ARKEY, AnnulReasons.AR_NAME as IP_AnnulReason, 
	DogovorList.DL_DGCOD AS IP_DGCode, 
        InsPolicy.IP_ITPID, InsTariffPlan.ITP_Name as IP_TariffPlanName,
	InsPolicy.IP_PremiumNat, InsPolicy.IP_Premium, 
	InsPolicy.IP_IRTID, InsRates.IRT_Code IP_RateCode,
	InsPolicy.IP_IBRID, InsBordero.IBR_Name IP_IBorderoName, InsBordero.IBR_ReadyToSend as IP_BorderoReadyToSend, 
	InsPolicy.IP_IFRID, InsFinReport.IFR_Name IP_IFinRepName, InsFinReport.IFR_ReadyToSend as IP_FinReportReadyToSend, 
	InsPolicy.IP_IAGID, Partners.PR_NAME as IP_AgentName, InsAgents.IAG_IsJuridical as IP_IsAgentJuridical, 
	InsPolicy.IP_PRKey, 
	dbo.InsGetPolicyMRDateBegin (InsPolicy.IP_ID) IP_MRDateBeg, 
	dbo.InsGetPolicyDateBegin (InsPolicy.IP_ID) IP_DateStart,
	dbo.InsIsA7Print(InsPolicy.IP_ID) IP_IsA7Print,
	dbo.InsGetPolicyStatus (InsPolicy.IP_ID) IP_STATUS, InsPolicyStatuses.IPS_NAME IP_STATUS_NAME,
    dbo.InsVariants.IV_Name AS IP_VariantName
FROM  Partners INNER JOIN InsAgents ON Partners.PR_KEY = InsAgents.IAG_AGENTKEY 
          RIGHT OUTER JOIN InsPolicy ON InsAgents.IAG_ID = InsPolicy.IP_IAGID
          LEFT OUTER JOIN InsBordero ON InsPolicy.IP_IBRID = InsBordero.IBR_ID 
          LEFT OUTER JOIN InsFinReport ON InsPolicy.IP_IFRID = InsFinReport.IFR_ID 
          LEFT OUTER JOIN InsRates ON InsPolicy.IP_IRTID = InsRates.IRT_ID 
          LEFT OUTER JOIN DogovorList ON InsPolicy.IP_DLKey = DogovorList.DL_KEY
          INNER JOIN InsPolicyStatuses ON InsPolicyStatuses.IPS_ID = dbo.InsGetPolicyStatus (InsPolicy.IP_ID)
          LEFT OUTER JOIN AnnulReasons ON InsPolicy.IP_ARKEY = AnnulReasons.AR_KEY
          LEFT OUTER JOIN InsTariffPlan ON InsPolicy.IP_ITPID = InsTariffPlan.ITP_ID
		  LEFT OUTER JOIN ServiceList ON DogovorList.DL_CODE = ServiceList.SL_KEY
		  LEFT OUTER JOIN InsVariantServices ON InsVariantServices.IVS_SLKey = ServiceList.SL_KEY 
		  LEFT OUTER JOIN InsVariants ON InsVariantServices.IVS_IVID = InsVariants.IV_ID
GO

GRANT  SELECT ,  UPDATE ,  INSERT ,  DELETE  ON [dbo].[InsPolicyInfo] TO PUBLIC
GO


-- 20100407(AlterTables_InsCosts).sql
-- drop foreign key InsCosts <--> InsVariants
if exists (select 1 from dbo.sysobjects where id = object_id(N'[dbo].[FK_InsCosts_InsVariants]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[InsCosts] DROP CONSTRAINT FK_InsCosts_InsVariants
GO

-- add column
if not exists (select 1 from dbo.syscolumns where id = object_id(N'[dbo].[InsCosts]') and name = 'ICS_IVID')
	alter table dbo.InsCosts add ICS_IVID int

-- create foreign key InsCosts <--> InsVariants
ALTER TABLE [dbo].[InsCosts] ADD 
	CONSTRAINT [FK_InsCosts_InsVariants] FOREIGN KEY 
	(
		[ICS_IVID]
	) REFERENCES [dbo].[InsVariants] (
		[IV_ID]
	)
GO



-- 20100407(AlterTables_InsVariantCases).sql
if not exists (select 1 from dbo.syscolumns where id = object_id(N'[dbo].[InsVariantCases]') and name = 'IVC_IsLocked')
	alter table dbo.InsVariantCases add IVC_IsLocked smallint
GO

-- sp_mwGetTourMonthesQuotas.sql
if object_id('[dbo].[mwGetTourMonthesQuotas]', 'p') is not null
	drop proc [dbo].[mwGetTourMonthesQuotas]
go

/****** Объект:  StoredProcedure [dbo].[mwGetTourMonthesQuotas]    Дата сценария: 04/13/2010 16:38:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

	declare tour_cursor cursor fast_forward read_only 
	for
		select 
			td_trkey,
			isnull(tl_nameweb, isnull(tl_name, '')),
			isnull(tl_webhttp, '') as tour_url,
			td_date,
			month(td_date),
			tl_nday
		from 
			turdate with(nolock)
			inner join turlist with(nolock) on tl_key = td_trkey
		where
			td_date between getdate() 
			and dateadd(month, @month_count, getdate()) 
			and ((@cnkey >= 0 and isnull(tl_cnkey, 0) = @cnkey) or (@tour_type >= 0 and isnull(tl_tip, 0) = @tour_type))
			and tl_web > 0 
		order by
			isnull(tl_nameweb, isnull(tl_name, '')),
			td_date			


		declare 
			@tour_key int, 
			@prev_tour_key int, 
			@prev_month int, 
			@tour_name nvarchar(250),
            @tour_url nvarchar(500),
            @tour_date datetime,
            @month int,
			@tour_quotas nvarchar(4000),
			@tour_duration int

	set @tour_key = -1
	set @prev_tour_key = -1
	set @prev_month = -1
	set @tour_name = ''
	set @tour_url = ''
	set @tour_date = '1800-01-01'
	set @month = 0
	set @tour_quotas = ''

	open tour_cursor

	create table #turService(
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

	fetch next from tour_cursor into @tour_key, @tour_name, @tour_url, @tour_date, @month, @tour_duration
	while @@fetch_status = 0
	begin

        if (@tour_key != @prev_tour_key)
        begin
			insert into #tourQuotas (
				tour_key,
				tour_name,
				tour_url)
			values (
				@tour_key,
				@tour_name,
				@tour_url
			)

            set @prev_month = -1
			if (@prev_tour_key > 0)
				update #tourQuotas
				set tour_quotas = @tour_quotas
				where tour_key = @prev_tour_key

			set @tour_quotas = ''

			truncate table #turService

			set @sql = N'select 
							ts_svkey,
							ts_code,
							ts_subcode1,
							ts_subcode2,
							ts_day,
							ts_ndays,
							ts_partnerkey,
							ts_pkkey
						from
							turservice
						where
							ts_trkey = ' + str(@tour_key) +N'
							and ts_svkey in (' + isnull(@quoted_services, N'3') + N')'

			insert into #turService exec(@sql)

        end

        if (@month != @prev_month or @tour_key != @prev_tour_key)
        begin
			if (len(@tour_quotas) > 0)		
				set @tour_quotas = @tour_quotas + '|' 
			set @tour_quotas = @tour_quotas + ltrim(str(@month)) + '='
        end
		
		declare service_cursor cursor fast_forward read_only
		for
			select
				ts_svkey,
				ts_code,
				ts_subcode1,
				ts_subcode2,
				ts_day,
				ts_ndays,
				(case when @checkAllPartnersQuota > 0 then -1 else ts_partnerkey end),
				(case when ts_svkey = 1 and @checkFlightPacket > 0 then ts_pkkey else -1 end)
			from 
				#turService
		
		declare
			@svkey int,
			@code int,
			@subcode1 int,
			@subcode2 int,
			@day int,
			@ndays int,
			@partner_key int,
			@packet_key int,
			@places int,
			@allplaces int,
			@date_places int,
			@date_allplaces int

		open service_cursor

		fetch next from service_cursor into @svkey, @code, 
			@subcode1, @subcode2, @day, @ndays, @partner_key, @packet_key
		while @@fetch_status = 0
		begin
			select 
				@places = qt_places,
				@allplaces = qt_allplaces
			from
				dbo.mwCheckQuotesEx(
					@svkey, 
					@code, 
					-1, 
					-1, 
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

            if (@places = 0)
            begin
                set @date_places = 0
				set @date_allplaces = 0
                break
            end
            else if (@places = -1)
			begin
                set @date_places = @places
				set @date_allplaces = 0
			end
            else if (@places > 0 and (@date_places is null or @date_places > @places))
			begin
                set @date_places = @places
				set @date_allplaces = @allplaces
			end

			fetch next from service_cursor into @svkey, @code, 
				@subcode1, @subcode2, @day, @ndays, @partner_key, @packet_key
		end
	
		close service_cursor
		deallocate service_cursor

		if(@date_places is null)
		begin	
			set @date_places = -1
			set @date_allplaces = 0
		end

		if(substring(@tour_quotas, len(@tour_quotas), 1) != '=')
			set @tour_quotas = @tour_quotas + ','
		set @tour_quotas = @tour_quotas + ltrim(str(day(@tour_date))) + '#' + ltrim(str(@date_places)) + ':' + ltrim(str(@date_allplaces))


		set @prev_tour_key = @tour_key
		set @prev_month = @month
		fetch next from tour_cursor into @tour_key, @tour_name, @tour_url, @tour_date, @month, @tour_duration
	end

	update #tourQuotas
	set tour_quotas = @tour_quotas
	where tour_key = @prev_tour_key

	close tour_cursor
	deallocate tour_cursor

	select * from #tourQuotas
end
go

grant exec on [dbo].[mwGetTourMonthesQuotas] to public
go

-- 100414_Insert_ObjectAliases.sql
IF NOT EXISTS (SELECT 1 FROM OBJECTALIASES WHERE OA_ID = 200003)
	INSERT INTO OBJECTALIASES (OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID) VALUES (200003, 'MS_ProTourReservationStatus', 'Импорт статуса услуги проживания из ProTour', 0);
GO

-- 100419_AlterTable_Bonuses.sql
IF NOT EXISTS(SELECT id FROM SYSCOLUMNS WHERE id = OBJECT_ID('dbo.Bonuses') AND name = 'BN_ReservationCreateDateFrom')
     ALTER TABLE dbo.Bonuses ADD BN_ReservationCreateDateFrom DATETIME NULL
GO

IF NOT EXISTS(SELECT id FROM SYSCOLUMNS WHERE id = OBJECT_ID('dbo.Bonuses') AND name = 'BN_ReservationCreateDateTo')
     ALTER TABLE dbo.Bonuses ADD BN_ReservationCreateDateTo DATETIME NULL
GO


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
	@additionalFilter varchar(1024)
as
begin

	declare @sql varchar(8000)
	set @sql ='SELECT CS_Code,CS_SubCode1,CS_SubCode2,CS_PrKey,CS_PkKey,
				CS_Profit,CS_Type,CS_Discount,CS_Creator,CS_Rate,CS_Cost 
			FROM COSTS
			WHERE '
	if (@svKey=1)--aaeaia?aeao
	begin
		set @sql = @sql+
			'CS_SVKEY = '+cast (@svKey as varchar)+' AND CS_PKKEY = '+cast(@pkKey as varchar)+
			' AND ISNULL(CS_DATE, ''1900-01-01'') <= '''+@dateBegin+'''
			 AND ISNULL(CS_DATEEND, ''9000-01-01'') >= '''+@dateBegin+'''
			 AND (CS_LONG >= '+cast(@tourNDays as varchar)+' OR CS_LONG is NULL) 
			AND EXISTS 
				( SELECT CH_KEY FROM CHARTER 
				WHERE CH_KEY = CS_CODE AND CH_CITYKEYFROM = '+cast(@cityFromKey as varchar)+'
					AND CH_CITYKEYTO = '+cast(@cityToKey as varchar)+')'
		-- Filter on day of week
		set @sql = @sql + ' AND (CS_WEEK is null or CS_WEEK = '''' or CS_WEEK like dbo.GetWeekDays(''' + @dateBegin + ''',''' + @dateBegin + '''))'
		-- Filter on CHECKIN DATE
		set @sql = @sql + ' AND ''' + @dateBegin + ''' BETWEEN ISNULL(CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(CS_CHECKINDATEEND, ''9000-01-01'') ' + @additionalFilter + ' order by cs_long'
	end
	else if (@serviceDays>1)
	begin
		set @sql = @sql +
			'CS_SVKEY = '+cast (@svKey as varchar)+' AND CS_PKKEY = '+cast(@pkKey as varchar)+
			' AND ISNULL(CS_DATE, ''1900-01-01'') <= '''+cast(dateadd(day,1,cast(@dateBegin as datetime)) as varchar)+'''
			 AND ISNULL(CS_DATEEND, ''9000-01-01'') >= '''+@dateBegin+''''
		set @sql = @sql + ' AND ' + cast(@serviceDays as varchar) + ' between isnull(cs_longmin, -1) and isnull(cs_long, 10000)';
		set @sql = @sql + ' AND ''' + @dateBegin + ''' BETWEEN ISNULL(CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(CS_CHECKINDATEEND, ''9000-01-01'') ' + @additionalFilter + ' order by CS_UPDDATE DESC';
	end
	else
	begin
		set @sql = @sql+
			'CS_SVKEY = '+cast (@svKey as varchar)+' AND CS_PKKEY = '+cast(@pkKey as varchar)+
			' AND ISNULL(CS_DATE, ''1900-01-01'') <= '''+@dateBegin+'''
			 AND ISNULL(CS_DATEEND, ''9000-01-01'') >= '''+@dateBegin+''''
		set @sql = @sql + ' AND ' + cast(@serviceDays as varchar) + ' between isnull(cs_longmin, -1) and isnull(cs_long, 10000)';
		set @sql = @sql + ' AND ''' + @dateBegin + ''' BETWEEN ISNULL(CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(CS_CHECKINDATEEND, ''9000-01-01'') ' + @additionalFilter + ' order by cs_long'
	end
	exec (@sql)

end
go

grant exec on dbo.mwGetServiceVariants to public
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
	select case when exists(select 1 from dup_user where us_id=@login) then 1 else 0 end
end
go

grant exec on [dbo].[mwLoginExists] to public
go

-- 21042010(CreateIndex_DogovorList).sql
IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'X_DogovorList_Object_1')
     DROP INDEX tbl_DogovorList.X_DogovorList_Object_1
GO

CREATE INDEX X_DogovorList_Object_1 ON tbl_DogovorList (DL_QUOTEKEY)
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
declare @sAutoBlock varchar(1)

if @nDGKey is null or @nDGKey = 0
	return 0

select @nDGPayed = DG_Payed, @nDGPrice = DG_Price from Dogovor where DG_Key = @nDGKey

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

if @nDGPayed != @nPaymentDetailsSum
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



-- Tbl_ObjectAliases_ModifyData(Flight).sql
--mv 26.04.2010 Данные описания предназначены для корректной работы плагина "Уведомление об изменении рейса"
if not exists (select 1 from dbo.ObjectAliases where OA_Id = 1135)
	insert into dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TableID) values(1135, '', 'Аэропорт вылета', 60)
GO
if not exists (select 1 from dbo.ObjectAliases where OA_Id = 1136)
	insert into dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TableID) values(1136, '', 'Аэропорт прилета', 60)
GO
if not exists (select 1 from dbo.ObjectAliases where OA_Id = 1137)
	insert into dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TableID) values(1137, '', 'Время вылета', 60)
GO
if not exists (select 1 from dbo.ObjectAliases where OA_Id = 1138)
	insert into dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TableID) values(1138, '', 'Время прилета', 60)
GO
if not exists (select 1 from dbo.ObjectAliases where OA_Id = 1139)
	insert into dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TableID) values(1139, '', 'Авиакомпания', 60)
GO

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
				declare @dg_key int
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
				EXECUTE dbo.InsertHistoryDetail @nHIID , 1049, @ODL_Wait, @NDL_Wait, @ODL_Wait, @NDL_Wait, null, null, 0, @bNeedCommunicationUpdate output
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

-- sp_MakePutName.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MakePutName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[MakePutName]
GO
CREATE procedure [dbo].[MakePutName]
@date datetime, 
@countryKey int, 
@cityKey int, 
@tourKey int, 
@partnerKey int, 
@sFormat0 varchar(10),
@name varchar(10) output
as
--<VERSION>2005.38</VERSION>
--<DATE>2005-05-06</DATE>
SET CONCAT_NULL_YIELDS_NULL OFF 
	set @name = ''
	declare @nullDate datetime
	set @nullDate = '1899-12-30'

	declare @notAllowedSymbols varchar(100)
	select @notAllowedSymbols = Upper(SS_ParmValue) from SystemSettings where SS_ParmName = 'SYSDogovorNumberDigits'

	declare @firstDigit char(1)
	set @firstDigit = dbo.NextDigit(@notAllowedSymbols, ASCII('0'))

	declare @selectDate datetime
	set @selectDate = DATEADD(day, -180, GETDATE())
	
	declare @format varchar(50)
	select @format = ST_FormatDogovor from Setting
	
	declare @curPos int
	set @curPos = 1

	set @format = @format

	declare @chPrev varchar(1)
	set @chPrev = substring(@format, 1, 1)
	set @format = substring(@format, 2, len(@format) - 1)

	declare @number_part_length int
	declare @number_part_start_point int
	declare @len int
	set @len = 1

	declare @temp varchar(50)
	while @format != ''
	begin
		set @temp = @format

		declare @ch varchar(1)
		set @ch = substring(@temp, 1, 1) 
		set @format = substring(@temp, 2, len(@format) - 1)

		if @ch != @chPrev or @format = ''
		begin
			if @format = ''
			begin
				set @len = @len + 1
				set @curPos = @curPos + 1
			end

			declare @str varchar(50)
			set @str = ''
			
			if @chPrev = 'N'
			begin
				select @str = UPPER(LEFT(LTRIM(TL_Name), @len)) from tbl_TurList where TL_Key = @tourKey
				exec dbo.FillString @str output, @len, 'n'
			end			
			else
			if @chPrev = 'T'
			begin
				select @str = UPPER(isnull(LEFT(CT_Code, @len), '')) from CityDictionary where CT_Key = @cityKey
				exec dbo.FillString @str output, @len, 't'				
			end
			else
			if @chPrev = 'C'
			begin
				select @str = UPPER(isnull(LEFT(CN_Code, @len),isnull(LEFT(CN_NameLat, @len), ''))) from Country where CN_Key = @countryKey
				exec dbo.FillString @str output, @len, 'c'
			end
			else
			if @chPrev = 'P'
			begin
				select @str = UPPER(isnull(LEFT(PR_Cod, @len),'')) from Partners where PR_Key = @partnerKey
				exec dbo.FillString @str output, @len, 'p'
			end
			else
			if @chPrev = 'Y'
				set @str = RIGHT(STR(YEAR(@date)), @len)
			else
			if @chPrev = 'D'
			begin
				set @temp = LTRIM(STR(DATEPART(dd, @date)))
				if LEN(@temp) < 2
					set @temp = '0' + @temp
				set @str = @temp
			end
			else
			if @chPrev = 'M'
			begin
				set @temp = LTRIM(STR(DATEPART(mm, @date)))
				if LEN(@temp) < 2
					set @temp = '0' + @temp
				set @str = @temp	
			end
			else
			if @chPrev = '9' or @chPrev = '#'
			begin
				if(@chPrev = '9')
					set @temp = REPLICATE('[0-9]', @len)
				else
					set @temp = REPLICATE('_', @len)
				declare @searchName varchar(50)
				
				set @searchName = @name + @temp + '%'

				select @str = max(DG_Code) from tbl_Dogovor where upper(DG_Code) like upper(@searchName) and ((DG_TurDate >= @selectDate) or (DG_TurDate is null) or (DG_TurDate = @nullDate))
				if @str is null
					set @str = ''
				
				if @str != ''
				begin
					Set @temp = @str
					set @str = substring(@temp, @curPos - @len + 1, @len)
				end

				set @number_part_length = @len
				set @number_part_start_point = @curPos - @len + 1

				if @chPrev = '9'
				begin
					if dbo.IsStrNumber(LTRIM(RTRIM(@str))) > 0
					begin
						set @str = dbo.NextNumber(@notAllowedSymbols, LTRIM(STR(CAST(@str as int) + 1)))
						exec dbo.FillString @str output, @number_part_length, @firstDigit

					end
					else
					begin
						set @str = dbo.NextNumber(@notAllowedSymbols, '1')
						exec dbo.FillString @str output, @number_part_length, @firstDigit
					end
				end
				else
				begin
					set @temp = @str
					set @str = Upper(dbo.NextStr(@temp, @len))
				end
			end
			if @str = ''
				set @str = REPLICATE(@chPrev, @len)

			set @name = @name + @str
			set @len = 1
		end
		else
			set @len = @len + 1
		set @curPos = @curPos + 1
		set @chPrev = @ch	
	end

	set @name = Upper(@name)
	declare @int int
	set @int = 0
	while exists(select DG_Code from tbl_Dogovor where DG_Code = @name) and @int < 1005
	begin
		if @chPrev = '9'
		begin
			set @str = substring(@name, @number_part_start_point, @number_part_length)
			set @str = RIGHT(dbo.NextNumber(@notAllowedSymbols, LTRIM(STR(CAST(@str as int) + 1))),@number_part_length)
			exec dbo.FillString @str output, @number_part_length, @firstDigit
			--set @name = LEFT(@name, @number_part_start_point - 1) + @str + RIGHT(@name, 10 - @number_part_start_point - @number_part_length + 1)
			set @name = LEFT(@name, @number_part_start_point - 1) + @str
		end
		else
		begin
			set @str = substring(@name, @number_part_start_point, @number_part_length)
			set @str = Upper(dbo.NextStr(@str, @number_part_length))
			set @name = LEFT(@name, @number_part_start_point - 1) + @str
		end
		set @int = @int + 1
		--print @name
	end
	SET CONCAT_NULL_YIELDS_NULL ON 
GO
GRANT EXECUTE ON [dbo].[MakePutName] TO Public
GO


-- sp_mwGetCalculatedPriceInfo.sql
-----------------------------------------------------------
--- Create Storage Procedure [mwGetCalculatedPriceInfo] ---
-----------------------------------------------------------

if exists(select id from sysobjects where id = OBJECT_ID('mwGetCalculatedPriceInfo') and xtype = 'P')
	drop procedure dbo.mwGetCalculatedPriceInfo
go

create procedure mwGetCalculatedPriceInfo 
	@priceKey	int,
	@includeTourDescriptionText	tinyint,
	@includeBookingConditionsText	tinyint
AS
	select TP_DateBegin as TourDate
		,  TI_TotalDays as TotalDays
		,  TI_Nights as Nights
		,  TO_Key as PriceTourKey
		,  TO_Name as PriceTourName
		,  TL_Key as TourKey
		,  TL_Name as TourName
		,  CASE WHEN @includeBookingConditionsText = 1 THEN TL_Description ELSE '' END as BookingConditions
		,  CASE WHEN @includeTourDescriptionText = 1 THEN TL_DopDesc ELSE '' END as TourDescription
		,  CN_Key as CountryKey
		,  CN_Name as CountryName
		,  dbo.mwGetServiceClassesNames(TI_Key, 1,', ') as IncludedServices
	from TP_Prices
		join TP_Lists on TP_TIKey = TI_Key
		join TP_Tours on TP_TOKey = TO_Key
		join tbl_TurList on TO_TRKey = TL_Key
		join tbl_Country on TO_CNKey = CN_Key
	where TP_Key = @priceKey
go

grant exec on dbo.mwGetCalculatedPriceInfo to public
go

-- 20100503(AlterTables_InsPolicy).sql
-- add column IP_AnnulPercent
if not exists (select 1 from dbo.syscolumns where id = object_id(N'[dbo].[InsPolicy]') and name = 'IP_AnnulPercent')
	alter table dbo.InsPolicy add IP_AnnulPercent money
GO
-- add column IP_AnnulSum
if not exists (select 1 from dbo.syscolumns where id = object_id(N'[dbo].[InsPolicy]') and name = 'IP_AnnulSum')
	alter table dbo.InsPolicy add IP_AnnulSum money
GO
-- add column IP_AnnulSumNat
if not exists (select 1 from dbo.syscolumns where id = object_id(N'[dbo].[InsPolicy]') and name = 'IP_AnnulSumNat')
	alter table dbo.InsPolicy add IP_AnnulSumNat money
GO

-- 20100503(AlterTables_InsVariants).sql
-- add column IV_AnnulPercent
if not exists (select 1 from dbo.syscolumns where id = object_id(N'[dbo].[InsVariants]') and name = 'IV_AnnulPercent')
	alter table dbo.InsVariants add IV_AnnulPercent money 
GO

-- sp_NationalCurrencyPrice.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[NationalCurrencyPrice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure [dbo].[NationalCurrencyPrice]
GO
CREATE PROCEDURE [dbo].[NationalCurrencyPrice]
@sRate varchar(5), -- валюта пересчета
@sRateOld varchar(5), -- старая валюта
@sDogovor varchar(100), -- код договора
@nPrice money, -- новая цена в указанной валюте
@nPriceOld money, -- старая цена
@nDiscountSum money, -- новая скидка в указанной валюте
@sAction varchar(100), -- действие
@order_status smallint -- null OR passing the new value for dg_sor_code from the trigger when it's (dg_sor_code) updated
AS
BEGIN
	--<VERSION>2007.2.35.1</VERSION>
	--<DATE>2010-04-29</DATE>
	--mv Если стоит настройка, что курс фиксируется при создании путевки, то никакого пересчета делать не требуется
	IF (SELECT SS_ParmValue FROM SystemSettings  WHERE SS_ParmName='SYSPrtRegQuestion')=2
		IF EXISTS (SELECT 1 FROM History WHERE HI_OAID=20 AND HI_DGCod=@sDogovor)
			return 0

	declare @national_currency varchar(5)
	select top 1 @national_currency = RA_CODE from Rates where RA_National = 1

	declare @rc_course money
	declare @rc_courseStr char(30)

	if @sAction = 'RECALCULATE_BY_TODAY_CURRENCY_RATE'
	begin
		set @rc_course = -1
		select top 1 @rc_courseStr = RC_COURSE from RealCourses
		where
		RC_RCOD1 = @national_currency and RC_RCOD2 = @sRate
		and convert(char(10), RC_DATEBEG, 102) = convert(char(10), getdate(), 102)
		set @rc_course = cast(isnull(@rc_courseStr, -1) as money)
	end
	else if @sAction = 'RECALCULATE_BY_OLD_CURRENCY_RATE'
	begin
		set @rc_course = -1
		select top 1 @rc_courseStr = HI_TEXT from History
		where HI_DGCOD = @sDogovor and HI_OAId=20 order by HI_DATE desc
		set @rc_course = cast(isnull(@rc_courseStr, -1) as money)
	end

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

		-- пересчитываем цену, если надо
		declare @tmp_final_price money
		set @tmp_final_price = null
		exec [dbo].[CalcPriceByNationalCurrencyRate] @sDogovor, @sRate, @sRateOld, @national_currency, @nPrice, @nPriceOld, @sHI_WHO, 'INSERT_TO_HISTORY', @tmp_final_price output, @rc_course, @order_status

		if @tmp_final_price is not null
		begin
			set @final_price = @tmp_final_price
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

GRANT EXECUTE ON [dbo].[NationalCurrencyPrice] TO PUBLIC 
GO


-- sp_GetServiceList.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetServiceList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetServiceList] 
GO
create procedure [dbo].[GetServiceList] 
(
--<VERSION>2008.1.01.09a</VERSION>
@TypeOfRelult int, -- 1-список по по услугам, 2-список по туристам на услуге
@SVKey int, 
@Codes varchar(100), 
@SubCode1 int=null,
@Date datetime =null, 
@QDID int =null,
@QPID int =null,
@ShowHotels bit =null,
@ShowFligthDep bit =null,
@ShowDescription bit =null,
@State smallint=null
)
as 
declare @Query varchar(8000)
 
CREATE TABLE #Result
(
DG_Code varchar(20) collate Cyrillic_General_CI_AS, DG_Key int, DG_DiscountSum money, DG_Price money, DG_Payed money, 
DG_PriceToPay money, DG_Rate varchar(3) collate Cyrillic_General_CI_AS, DG_NMen int, 
PR_Name varchar(100) collate Cyrillic_General_CI_AS, CR_Name varchar(50) collate Cyrillic_General_CI_AS, 
DL_Key int, DL_NDays int, DL_NMen int, DL_Reserved int, DL_CTKeyTo int, DL_CTKeyFrom int, DL_CNKEYFROM int, DL_SubCode1 int,
TL_Key int, TL_Name varchar(160) collate Cyrillic_General_CI_AS,
TUCount int,
TU_NameRus varchar(25) collate Cyrillic_General_CI_AS, TU_NameLat varchar(25) collate Cyrillic_General_CI_AS, TU_FNameRus varchar(15) collate Cyrillic_General_CI_AS, TU_FNameLat varchar(15) collate Cyrillic_General_CI_AS, TU_Key int, 
TU_Sex Smallint, TU_PasportNum varchar(13) collate Cyrillic_General_CI_AS, TU_PasportType varchar(5) collate Cyrillic_General_CI_AS, TU_PasportDateEnd datetime, TU_BirthDay datetime,
TU_Hotels varchar(255) collate Cyrillic_General_CI_AS,
Request smallint, Commitment smallint, Allotment smallint, Ok smallint, 
TicketNumber varchar(16) collate Cyrillic_General_CI_AS, FlightDepDLKey int, FligthDepDate datetime, FlightDepNumber varchar(10) collate Cyrillic_General_CI_AS,
ServiceDescription varchar(80) collate Cyrillic_General_CI_AS, ServiceDateBeg datetime, ServiceDateEnd datetime
)
 
SET @Query = '
	INSERT INTO #Result (DG_Code, DG_Key, DG_DiscountSum, DG_Price, DG_Payed, 
		DG_PriceToPay, DG_Rate, DG_NMen, 
		PR_Name, CR_Name, 
		DL_Key, DL_NDays, DL_NMen, DL_Reserved, DL_CTKeyTo, DL_CTKeyFrom, DL_SubCode1, ServiceDateBeg, ServiceDateEnd, 
		TL_Key, TUCount'
IF @TypeOfRelult=2
	SET @Query=@Query + ',
		TU_NameRus, TU_NameLat, TU_FNameRus, TU_FNameLat, TU_Key, 
		TU_Sex, TU_PasportNum, TU_PasportType, TU_PasportDateEnd, TU_BirthDay, TicketNumber'
SET @Query=@Query + ') 
	SELECT	  DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, 
		(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, 
		DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + '=3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END,
						DG_TRKey,'
IF @TypeOfRelult=1
	SET @Query=@Query + 'Count(tu_dlkey) '
ELSE IF @TypeOfRelult=2
	SET @Query=@Query + '0, 
		TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS, TU_FNAMELAT, TU_KEY,
		TU_SEX, TU_PASPORTNUM, TU_PASPORTTYPE, TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc '
SET @Query=@Query + '
FROM  Dogovor, Partners, Controls, Dogovorlist '
IF @TypeOfRelult=1
	SET @Query=@Query + 'left join Turistservice on tu_dlkey=dl_key '
ELSE IF @TypeOfRelult=2
	SET @Query=@Query + ', Turist, TuristService '
SET @Query=@Query + '
WHERE
		dl_dGKEY=DG_KEY and dl_control=cr_key and dl_agent=pr_key '
IF @QPID is not null or @QDID is not null
BEGIN
	IF @QPID is not null
		SET @Query=@Query + ' and exists (SELECT top 1 SD_DLKEY FROM ServiceByDate WHERE SD_QPID IN (' + CAST(@QPID as varchar(20)) + ') and SD_DLKEY=DL_Key)'
	ELSE
		SET @Query=@Query + ' and exists (SELECT top 1 SD_DLKEY FROM ServiceByDate, QuotaParts WHERE SD_QPID=QP_ID and QP_QDID IN (' + CAST(@QDID as varchar(20)) + ') and SD_DLKEY=DL_Key)'
END

SET @Query=@Query + '
	and DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' AND DL_CODE in (' + @Codes + ') AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND '
if (@SubCode1 != '0')
	SET @Query=@Query + ' AND DL_SUBCODE1 in (' + CAST(@SubCode1 as varchar(20)) + ')'
IF @State is not null
	SET @Query=@Query + ' and exists(SELECT 1 FROM ServiceByDate WHERE SD_State=' + CAST(@State as varchar(1)) + ' and SD_DLKey=DL_Key and SD_Date=''' + CAST(@Date as varchar(20)) + ''')'
 
IF @TypeOfRelult=1
	SET @Query=@Query + '
	group by DG_CODE,DG_KEY,DG_DISCOUNTSUM,DG_PDTTYPE,DG_PRICE,DG_PAYED,(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ) ,DG_RATE,DG_NMEN,PR_NAME,CR_NAME,
		DL_SUBCODE1,DL_SUBCODE2,DL_DateBeg,DL_DateEnd,DL_NDays,DL_WAIT,DL_KEY,DL_NMEN,DL_RESERVED,DG_TRKey,DL_CTKEY'
ELSE
	SET @Query=@Query + '
	and tu_dlkey = dl_key and tu_key = tu_tukey'
--PRINT @Query
EXEC (@Query)
 
UPDATE #Result SET #Result.TL_Name=(SELECT TL_Name FROM TurList WHERE #Result.TL_Key=TurList.TL_Key)
 
if @TypeOfRelult=1
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_State=1)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_State=3)
END
else
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=1)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=3)
END
 
IF @ShowHotels=1
BEGIN
	IF @TypeOfRelult = 2
	BEGIN
		DECLARE @HD_Name varchar(100), @HD_Stars varchar(25), @PR_Name varchar(100), @TU_Key int, @HD_Key int, @PR_Key int, @TU_KeyPrev int, @TU_Hotels varchar(255)
		DECLARE curServiceList CURSOR FOR 
			SELECT	  DISTINCT HD_Name, HD_Stars, PR_Name, TU_TUKey, HD_Key, PR_Key 
			FROM  HotelDictionary, DogovorList, TuristService, Partners
			WHERE	  PR_Key=DL_PartnerKey and HD_Key=DL_Code and TU_DLKey=DL_Key and TU_TUKey in (SELECT TU_Key FROM #Result) and dl_SVKey=3 
			ORDER BY TU_TUKey
		OPEN curServiceList
		FETCH NEXT FROM curServiceList INTO	  @HD_Name, @HD_Stars, @PR_Name, @TU_Key, @HD_Key, @PR_Key
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @TU_Key!=@TU_KeyPrev or @TU_KeyPrev is null
			  Set @TU_Hotels=@HD_Name+' '+@HD_Stars+' ('+@PR_Name+')'
			ELSE
			  Set @TU_Hotels=@TU_Hotels+', '+@HD_Name+' '+@HD_Stars+' ('+@PR_Name+')'
			UPDATE #Result SET TU_Hotels=@TU_Hotels WHERE TU_Key=@TU_Key
			SET @TU_KeyPrev=@TU_Key
			FETCH NEXT FROM curServiceList INTO	  @HD_Name, @HD_Stars, @PR_Name, @TU_Key, @HD_Key, @PR_Key
		END
		CLOSE curServiceList
		DEALLOCATE curServiceList
	END
	IF @TypeOfRelult = 1
	BEGIN
		DECLARE @HD_Name1 varchar(100), @HD_Stars1 varchar(25), @PR_Name1 varchar(100), @DL_Key1 int, @HD_Key1 int, 
				@PR_Key1 int, @DL_KeyPrev1 int, @TU_Hotels1 varchar(255), @DG_Key int, @DG_KeyPrev int
		DECLARE curServiceList CURSOR FOR 
			--SELECT DISTINCT HD_Name, HD_Stars, P.PR_Name, DogList.DL_Key, HD_Key, PR_Key--, DG_Key
			--FROM HotelDictionary, DogovorList DogList, TuristService, Partners P
			--WHERE P.PR_Key = DogList.DL_PartnerKey and HD_Key = DogList.DL_Code and TU_DLKey = DogList.DL_Key and
			--TU_TUKey in (SELECT TU_TUKEY FROM TuristService WHERE TU_DLKEY in (SELECT DL_KEY FROM #Result)) 
			--and DL_SVKey=3 
			--ORDER BY DogList.DL_Key
			SELECT DISTINCT HD_Name, HD_Stars, HD_Key, P.PR_Name, P.PR_Key, DogList.DL_Key, R.DG_Key
			FROM HotelDictionary, DogovorList DogList, Partners P, #Result R
			WHERE P.PR_Key = DogList.DL_PartnerKey and HD_Key = DogList.DL_Code and DogList.DL_DGKey = R.DG_Key			
				  and DogList.DL_SVKey=3 
			ORDER BY R.DG_Key
		OPEN curServiceList
		FETCH NEXT FROM curServiceList INTO @HD_Name1, @HD_Stars1, @HD_Key1, @PR_Name1, @PR_Key1, @DL_Key1, @DG_Key
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @DG_Key != @DG_KeyPrev or @DG_KeyPrev is null  
			BEGIN
			  Set @TU_Hotels1=@HD_Name1+' '+@HD_Stars1+' ('+@PR_Name1+')'
			END
			ELSE
			BEGIN
			  Set @TU_Hotels1=@TU_Hotels1+', '+@HD_Name1+' '+@HD_Stars1+' ('+@PR_Name1+')'
			END
			UPDATE #Result SET TU_Hotels=@TU_Hotels1 WHERE DG_Key=@DG_Key --DL_Key=@DL_Key1
			SET @DG_KeyPrev = @DG_Key
			FETCH NEXT FROM curServiceList INTO @HD_Name1, @HD_Stars1, @HD_Key1, @PR_Name1, @PR_Key1, @DL_Key1, @DG_Key
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
		Update #Result SET ServiceDescription=LEFT((SELECT ISNUll(AS_Code, '') + '-' + AS_NameRus FROM AirService WHERE AS_Key=DL_SubCode1),80)
	ELSE IF (@SVKey=2 or @SVKey=4)
		Update #Result SET ServiceDescription=LEFT((SELECT TR_Name FROM Transport WHERE TR_Key=DL_SubCode1),80)
	ELSE IF (@SVKey=3 or @SVKey=8)
	BEGIN
		Update #Result SET ServiceDescription=LEFT((SELECT RM_Name + '(' + RC_Name + ')' + AC_Name FROM Rooms,RoomsCategory,AccMdMenType,HotelRooms WHERE HR_Key=DL_SubCode1 and HR_RMKey=RM_Key and HR_RCKey=RC_Key and HR_ACKey=AC_Key),80)
		IF @SVKey=8
			Update #Result SET ServiceDescription='All accommodations' where DL_SubCode1=0
	END
	ELSE IF (@SVKey=7 or @SVKey=9)
	BEGIN
		Update #Result SET ServiceDescription=LEFT((SELECT ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_Name,'') FROM Cabine WHERE CB_Key=DL_SubCode1),80)
		IF @SVKey=9
			Update #Result SET ServiceDescription='All accommodations' where DL_SubCode1=0
	END
	ELSE
		Update #Result SET ServiceDescription=LEFT((SELECT A1_Name FROM AddDescript1 WHERE A1_Key=DL_SubCode1),80) WHERE ISNULL(DL_SubCode1,0)>0
END

--print @Query
SELECT * FROM #Result
GO
GRANT EXECUTE ON [dbo].[GetServiceList] TO Public
GO


-- 20100503(AlterView_InsPolicyInfo).sql
If exists(Select 1 from sysviews where name = 'InsPolicyInfo' and CREATOR = 'DBO')
	DROP VIEW InsPolicyInfo
GO

CREATE VIEW [dbo].[InsPolicyInfo]
as
SELECT InsPolicy.IP_ID, InsPolicy.IP_PolicyNumber, 
	dbo.PolicyNeedSend(InsPolicy.IP_ID) IP_NeedSend, InsPolicy.IP_NMen, 
        InsPolicy.IP_IBRID_ANNUL, InsPolicy.IP_IFRID_ANNUL,
        InsPolicy.IP_IsMulti, InsPolicy.IP_IsCommonKoefs, InsPolicy.IP_RateOfExchange,
        InsPolicy.IP_IsNational, InsPolicy.IP_CreateDate, 
        InsPolicy.IP_DateBeg, InsPolicy.IP_DateEnd, DATEDIFF(day, InsPolicy.IP_DateBeg, InsPolicy.IP_DateEnd) + 1 as IP_NDays,
        InsPolicy.IP_IsJuridical, InsPolicy.IP_Tel, InsPolicy.IP_Adress, InsPolicy.IP_FIO,
	InsPolicy.IP_JurFullName, InsPolicy.IP_JurName, InsPolicy.IP_JurInn,
	CASE WHEN InsPolicy.IP_ARKEY IS NULL THEN 0 ELSE 1 END IP_IsAnnuled, 
        InsPolicy.IP_AnnulDate, InsPolicy.IP_ARKEY, AnnulReasons.AR_NAME as IP_AnnulReason, 
		InsPolicy.IP_AnnulPercent, InsPolicy.IP_AnnulSum, InsPolicy.IP_AnnulSumNat, 
	DogovorList.DL_DGCOD AS IP_DGCode, 
        InsPolicy.IP_ITPID, InsTariffPlan.ITP_Name as IP_TariffPlanName,
	InsPolicy.IP_PremiumNat, InsPolicy.IP_Premium, 
	InsPolicy.IP_IRTID, InsRates.IRT_Code IP_RateCode,
	InsPolicy.IP_IBRID, InsBordero.IBR_Name IP_IBorderoName, InsBordero.IBR_ReadyToSend as IP_BorderoReadyToSend, 
	InsPolicy.IP_IFRID, InsFinReport.IFR_Name IP_IFinRepName, InsFinReport.IFR_ReadyToSend as IP_FinReportReadyToSend, 
	InsPolicy.IP_IAGID, Partners.PR_NAME as IP_AgentName, InsAgents.IAG_IsJuridical as IP_IsAgentJuridical, 
	InsPolicy.IP_PRKey, 
	dbo.InsGetPolicyMRDateBegin (InsPolicy.IP_ID) IP_MRDateBeg, 
	dbo.InsGetPolicyDateBegin (InsPolicy.IP_ID) IP_DateStart,
	dbo.InsIsA7Print(InsPolicy.IP_ID) IP_IsA7Print,
	dbo.InsGetPolicyStatus (InsPolicy.IP_ID) IP_STATUS, InsPolicyStatuses.IPS_NAME IP_STATUS_NAME,
    dbo.InsVariants.IV_Name AS IP_VariantName
FROM  Partners INNER JOIN InsAgents ON Partners.PR_KEY = InsAgents.IAG_AGENTKEY 
          RIGHT OUTER JOIN InsPolicy ON InsAgents.IAG_ID = InsPolicy.IP_IAGID
          LEFT OUTER JOIN InsBordero ON InsPolicy.IP_IBRID = InsBordero.IBR_ID 
          LEFT OUTER JOIN InsFinReport ON InsPolicy.IP_IFRID = InsFinReport.IFR_ID 
          LEFT OUTER JOIN InsRates ON InsPolicy.IP_IRTID = InsRates.IRT_ID 
          LEFT OUTER JOIN DogovorList ON InsPolicy.IP_DLKey = DogovorList.DL_KEY
          INNER JOIN InsPolicyStatuses ON InsPolicyStatuses.IPS_ID = dbo.InsGetPolicyStatus (InsPolicy.IP_ID)
          LEFT OUTER JOIN AnnulReasons ON InsPolicy.IP_ARKEY = AnnulReasons.AR_KEY
          LEFT OUTER JOIN InsTariffPlan ON InsPolicy.IP_ITPID = InsTariffPlan.ITP_ID
		  LEFT OUTER JOIN ServiceList ON DogovorList.DL_CODE = ServiceList.SL_KEY
		  LEFT OUTER JOIN InsVariantServices ON InsVariantServices.IVS_SLKey = ServiceList.SL_KEY 
		  LEFT OUTER JOIN InsVariants ON InsVariantServices.IVS_IVID = InsVariants.IV_ID
GO

GRANT  SELECT ,  UPDATE ,  INSERT ,  DELETE  ON [dbo].[InsPolicyInfo] TO PUBLIC
GO


-- fn_mwGetFirstConfirmDogovorDate.sql
if exists(select id from sysobjects where xtype='fn' and name='fn_mwGetFirstConfirmDogovorDate')
	drop function dbo.fn_mwGetFirstConfirmDogovorDate
go

create function [dbo].[fn_mwGetFirstConfirmDogovorDate](@dgKey int)
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
	where newvalue = 7 -- статус Ок
	order by date

	set @result = null
	OPEN history_cursor

	FETCH NEXT FROM history_cursor 
	INTO @currDate
	 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if not exists(select * from @historyTable where date between dateadd(second, 1, @currDate) and dateadd(second, 30, @currDate))	
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

grant exec on dbo.fn_mwGetFirstConfirmDogovorDate to public
go

-- 100429(Alter_mwPriceDataTable).sql
if exists(select id from syscolumns where id = OBJECT_ID('mwPriceDataTable') and name = 'pt_rmcode')
and ((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='mwPriceDataTable' and COLUMN_NAME='pt_rmcode') < 60)
alter table dbo.mwPriceDataTable alter column pt_rmcode varchar (60) NULL
GO
if exists(select id from syscolumns where id = OBJECT_ID('mwPriceDataTable') and name = 'pt_tourname')
and ((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='dbo' and TABLE_NAME='mwPriceDataTable' and COLUMN_NAME='pt_tourname') < 160)
alter table dbo.mwPriceDataTable alter column pt_tourname varchar (160) NULL
GO


-- alter_HotelTypes.sql
if not exists(select id from syscolumns where id = OBJECT_ID('HotelTypes') and name = 'HTT_ImageName')
	ALTER TABLE HotelTypes ADD HTT_ImageName varchar(128) null
go

-- sp_mwGetHotelTypeImageHtml.sql
----------------------------------------------------------
--- Create Storage Procedure [mwGetHotelTypeImageHtml] ---
----------------------------------------------------------

if exists(select id from sysobjects where id = OBJECT_ID('mwGetHotelTypeImageHtml') and xtype = 'P')
	drop procedure dbo.mwGetHotelTypeImageHtml
go

CREATE procedure mwGetHotelTypeImageHtml 
	  @hotelID int
	, @sourceFolder varchar(64) = ''
as
begin
	declare @result varchar(2048)
	set @result = ''

	select @result = @result + '<img alt="' + htt_name + '" src="' + @sourceFolder + HTT_ImageName + '" />'
	from HotelTypes with(nolock)
		join HotelTypeRelations with(nolock) on htr_httkey = htt_id
	where htr_hdkey = @hotelID and isnull(HTT_ImageName, '') != ''
	order by htt_id

	if (len(@result) > 0)
		set @result = '<div style="display:inline;">' + @result + '</div>'
	
	select @result as HotelTypeImageHtml
end
go

grant exec on dbo.mwGetHotelTypeImageHtml to public
go

-- 100513(Add_SYSSettings).sql
if not exists (select * from dbo.SystemSettings where SS_ParmName = 'SYSAlwaysShowMultiHotels')
	insert into dbo.SystemSettings (SS_ParmName, SS_ParmValue) values ('SYSAlwaysShowMultiHotels', '0')
GO

-- 100518(Delete_UserSettings).sql
delete from dbo.UserSettings where ST_ParmName like 'SearchDogovorsForm.dgvDogovors'
GO

-- 100518(AlterView_Orders).sql
if exists(select * from sysviews where name = 'Orders' and CREATOR = 'dbo')
	drop view dbo.Orders
GO

create view dbo.Orders as 
select	PD_Id as OR_KEY,
		PO_IsDebit as OR_INOUT,
		PO_Type as OR_TYPE,
		PO_PTKey as OR_PAYMENTTYPE,
		PD_SumTax1 as OR_NDCSUM,
		PM_Number as OR_NUMBER,
		PD_Course as OR_RATE,
		PM_RepresentName as OR_NAME,
		PD_SumNational as OR_SUMMARUS,
		PD_Sum as OR_SUMMAUSA,
		PD_SumTaxPercent1 as OR_NDC,
		PD_SumTaxPercent2 as OR_SPECN,
		PD_SumTax2 as OR_SPECNSUM,
		PD_SumNationalWords as OR_SUMMACHAR,
		PD_Reason as OR_PAYFOR,
		PM_Export as OR_EXPORT,
		DG_Code as OR_DOGOVOR,
		0 as OR_PRKEY,
		PD_CreatorKey as OR_OPERATOR,
		PD_Percent as OR_PERCENT,
		PM_Date as OR_DATE,
		PO_KPKey as OR_KPKEY,
		PD_SumNational as OR_FULLSUMRUS,
		PD_Sum as OR_FULLSUMUSA,
		PM_PRKey as OR_AgentKey,
		RA.RA_Code as OR_RACode,
		PM_RepresentInfo as OR_REPRESENTINFO,
		null as OR_HostName,
		PD_CreateDate as OR_DateCreate,
		PD_DGKey as OR_DGKEY,
		PD_SumInDogovorRate as OR_DogPayedSum,
		RA2.RA_Key as OR_DogPayedRAKey
from PaymentOperations PO 
join Payments PM on PO.PO_Id = PM.PM_POId
join PaymentDetails PD on PD.PD_PMId = PM.PM_Id
join dbo.Rates RA on RA.RA_Key = PM.PM_RAKey
left outer join Dogovor DG on DG.DG_Key = PD.PD_DGKey
left outer join dbo.Rates RA2 on RA2.RA_CODE = DG.DG_RATE
where isnull(PM_IsDeleted, 0) != 1
with check option
GO

grant select, insert, update, delete on dbo.Orders to public 
GO

-- sp_CheckCalculatePriceList.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CheckCalculatePriceList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CheckCalculatePriceList]
GO
 
CREATE PROCEDURE [dbo].[CheckCalculatePriceList]
  (
	@tokey int,					-- ключ тура
	@saleDate datetime,			-- дата продажи
	@nUpdate smallint			-- признак дозаписи 0 - расчет, 1 - дозапись
  )
with encryption
AS
	declare @numPrices int

	declare @svKey int
	declare @code int
	declare @subCode1 int
	declare @subCode2 int
	declare @partnerKey int
	declare @packetKey int

	declare @maxDate datetime
	declare @maxDateDuration datetime
	declare @maxDuration int

	declare @servicesCount int
	declare @procIncrement float
	declare @procents float
	
	declare @costsCount int
	declare @serviceName nvarchar(255)
	declare @maxCostDate datetime
	declare @maxServiceDate datetime

	declare @countryKey int, @cityKey int, @nDay int, @nDays int
	
	declare @resultTable table (RT_SvKey int, RT_SvName nvarchar(255), RT_MaxCostDate datetime, RT_MaxServiceDate datetime)

begin
	update dbo.TP_Tours with(rowlock) set TO_Progress = 0 where TO_Key = @tokey
	set @procents = 0

	select @servicesCount = count(*) from (select distinct TS_SVKey, TS_Code, TS_SubCode1, TS_SubCode2, TS_OpPartnerKey, TS_OpPacketKey from TP_Services with(nolock) where TS_TOKey = @tokey) as foo
	
	if @servicesCount > 0
		set @procIncrement = 100 / @servicesCount
	else
		set @procIncrement = 100

	declare serviceCursor cursor local fast_forward for
	select distinct TS_SVKey, TS_Code, TS_SubCode1, TS_SubCode2, TS_OpPartnerKey, TS_OpPacketKey
	from TP_Services with(nolock)
	where TS_TOKey = @tokey
	order by ts_svkey

	select @maxDate = max(TD_Date) from TP_TurDates with(nolock) where TD_TOKey = @tokey and TD_Update = @nUpdate

	open serviceCursor
	fetch next from serviceCursor into @svKey, @code, @subCode1, @subCode2, @partnerKey, @packetKey
	While (@@fetch_status = 0)
	begin

		select top 1 @serviceName = TS_Name, @nDays = TS_Days, @nDay = TS_Day from TP_Services with(nolock) where TS_SVKey = @svKey and TS_Code = @code and TS_SubCode1 = @subCode1 and TS_SubCode2 = @subCode2 and TS_OpPartnerKey = @partnerKey and TS_OpPacketKey = @packetKey order by TS_Days desc
		if @svKey = 3 or @svKey = 8
			set @nDays = @nDays + 1
		set @maxServiceDate = dateadd(day, @nDays + @nDay - 1, @maxDate)
		
		select @costsCount = count(CS_Id)
		from Costs with(nolock)
		where CS_SvKey = @svKey and CS_Code = @code and CS_SubCode1 = @subCode1 and CS_SubCode2 = @subCode2 and CS_PRKey = @partnerKey and CS_PKKey = @packetKey and 
			  ((@maxServiceDate between CS_Date and CS_DateEnd) or (CS_Date is null and CS_DateEnd is null)) and 
			  (@saleDate is null or (@saleDate between CS_DateSellBeg and CS_DateSellEnd) or (CS_DateSellBeg is null and CS_DateSellEnd is null)) and
			  ((@maxDate between CS_CheckinDateBeg and CS_CheckinDateEnd) or (CS_CheckinDateBeg is null and CS_CheckinDateEnd is null)) and
			  (@nDays = 0 or (@nDays between CS_LongMin and CS_Long) or (CS_LongMin is null and CS_Long is null))

		if @costsCount = 0
		begin
			if @svKey = 8
			begin
				select top 1 @countryKey = TS_CNKey, @cityKey = TS_CTKey, @nDays = TS_Days, @nDay = TS_Day from TP_Services with(nolock) where TS_SVKey = @svKey and TS_Code = @code and TS_SubCode1 = @subCode1 and TS_SubCode2 = @subCode2 and TS_OpPartnerKey = @partnerKey and TS_OpPacketKey = @packetKey order by TS_Days desc
				exec MakeFullSVName @countryKey, @cityKey, @svKey, @code, @nDays, @subCode1, @subCode2, @partnerKey, @maxDate, null, @serviceName output, null
			end
			
			select top 1 @maxCostDate = CS_DateEnd from Costs with(nolock) where CS_SvKey = @svKey and CS_Code = @code and CS_SubCode1 = @subCode1 and CS_SubCode2 = @subCode2 and CS_PRKey = @partnerKey and CS_PKKey = @packetKey order by CS_Date, CS_DateEnd desc
			set @maxServiceDate = @maxDate + @nDays + @nDay

			insert into @resultTable (RT_SvKey, RT_SvName, RT_MaxCostDate, RT_MaxServiceDate) values(@svKey, @serviceName, @maxCostDate, @maxServiceDate)
		end

		set @procents = @procents + @procIncrement
		update dbo.TP_Tours with(rowlock) set TO_Progress = @procents where TO_Key = @tokey
	
		fetch next from serviceCursor into @svKey, @code, @subCode1, @subCode2, @partnerKey, @packetKey
	end

	select RT_SvKey, RT_SvName, RT_MaxCostDate, RT_MaxServiceDate from @resultTable

	update dbo.TP_Tours with(rowlock) set TO_Progress = 100 where TO_Key = @tokey
end
GO

GRANT EXEC ON [dbo].[CheckCalculatePriceList] TO PUBLIC
GO

-- sp_GetCurrentNationalCurrencyRate.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetCurrentNationalCurrencyRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure [dbo].[GetCurrentNationalCurrencyRate]
GO
CREATE PROCEDURE [dbo].[GetCurrentNationalCurrencyRate]
@currency varchar(100),
@res money output
AS
BEGIN
	set @res = -1
	declare @national_currency varchar(5)
	select top 1 @national_currency = RA_CODE from Rates where RA_National = 1 
	if @national_currency = @currency 
	   set @res = -2
	else 
		select top 1 @res = isnull(RC_COURSE,-3) from RealCourses
		where 
		RC_RCOD1 = @national_currency and RC_RCOD2 = @currency 
		and convert(char(10), getdate(), 102) between convert(char(10), RC_DATEBEG, 102) and convert(char(10), RC_DATEEND, 102)
END

return 0
GO
GRANT EXECUTE ON [dbo].[GetCurrentNationalCurrencyRate] TO PUBLIC 
GO

-- 100519(AlterTable_Clients).sql
if exists (select 1 from syscolumns where id = object_id(N'dbo.Clients', N'U') and name = 'CL_DateUpdate' and isnullable = 1)
	alter table dbo.Clients
	alter column CL_DateUpdate datetime not null
go

-- view_mwFlightCosts.sql
if exists(select id from sysobjects where xtype='v' and name='mwFlightCosts')
	drop view dbo.mwFlightCosts
go

Create view [dbo].[mwFlightCosts] as
select cs_code as fc_code, cs_subcode1 as fc_subcode1, cs_subcode2 as fc_subcode2, cs_pkkey as fc_pkkey, cs_prkey as fc_prkey, 
cs_date as fc_costdatebegin, cs_dateend as fc_costdateend, cs_long as fc_long, cs_longmin as fc_longmin, 
cs_checkindatebeg as fc_checkindatebeg, cs_checkindateend as fc_checkindateend,
ch_citykeyfrom as fc_ctkeyfrom, ch_citykeyto as fc_ctkeyto, as_datefrom as fc_asdatefrom, as_dateto as fc_asdateto, as_week as fc_week, ch_flight as fc_flight, ch_airlinecode as fc_airlinecode
from costs inner join charter on (cs_svkey = 1 and cs_code = ch_key) 
	inner join airseason on ch_key = as_chkey
go
grant select on dbo.mwFlightCosts to public
go

-- view_mwFlightDirections.sql
if exists(select id from sysobjects where xtype='v' and name='mwFlightDirections')
	drop view dbo.mwFlightDirections
go

Create view [dbo].[mwFlightDirections] as
select distinct tl_key as fd_trkey, tl_cnkey as fd_cnkey, 
			ch_citykeyfrom as fd_ctkeyfrom, ch_citykeyto as fd_ctkeyto
from tbl_TurList inner join turservice on (tl_key = ts_trkey and ts_svkey = 1) inner join tbl_Costs on 
(cs_svkey = 1 and cs_pkkey = ts_pkkey ) inner join Charter on
	(cs_svkey = 1 and cs_code = ch_key and ch_citykeyfrom = ts_subcode2 and  ch_citykeyto = ts_ctkey)
where IsNull(cs_dateend, '2100-01-01') >= getdate() and IsNull(cs_checkindateend, '2100-01-01') >=getdate() and
	tl_key in (select ds_pkkey from descriptions where ds_dtkey = 115 and ds_tableid = 37 and ds_value like '%1%')
	and exists(select top 1 td_trkey from turdate where td_date >= getdate() and td_trkey = tl_key)

/*
select distinct tl_key as fd_trkey, tl_cnkey as fd_cnkey, 
			ch_citykeyfrom as fd_ctkeyfrom, ch_citykeyto as fd_ctkeyto
from tbl_TurList inner join turservice on (tl_key = ts_trkey and ts_svkey = 1) inner join tbl_Costs on (cs_svkey = 1 and cs_pkkey = ts_pkkey) 
inner join Charter on
	(cs_svkey = 1 and cs_code = ch_key )
where cs_dateend >= getdate() and
	tl_key in (select ds_pkkey from descriptions where ds_dtkey = 115 and ds_tableid = 37 and ds_value like '%1%')
	and exists(select top 1 td_trkey from turdate where td_date >= getdate() and td_trkey = tl_key) 
*/
/*
	select distinct tl_key as fd_trkey, tl_cnkey as fd_cnkey, 
			ch_citykeyfrom as fd_ctkeyfrom, ch_citykeyto as fd_ctkeyto
	from tbl_Costs inner join  tbl_TurList on cs_pkkey = tl_key inner join Charter on
		(cs_svkey = 1 and cs_code = ch_key)
	where cs_dateend >= getdate() and exists(select top 1 td_trkey from turdate where td_trkey = tl_key and td_date >= getdate()) and
		tl_key in (select ds_pkkey from descriptions where ds_dtkey = 115 and ds_tableid = 37 and ds_value like '%1%')
*/

go
grant select on dbo.mwFlightDirections to public
go

-- sp_mwCleaner.sql
if exists(select id from sysobjects where name='mwCleaner' and xtype='p')
	drop procedure [dbo].[mwCleaner]
go

create proc [dbo].[mwCleaner] as
begin
	delete from dbo.tp_turdates where td_date < getdate() - 1 and td_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_prices where tp_dateend < getdate() - 1 and tp_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_servicelists where tl_tikey not in (select tp_tikey from tp_prices) and tl_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_lists where ti_key not in (select tp_tikey from tp_prices) and ti_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_services where ts_key not in (select tl_tskey from tp_servicelists) and ts_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_tours where to_key not in (select ti_tokey from tp_lists) and to_update = 0

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

-- sp_ClearMasterWebSearchFields.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ClearMasterWebSearchFields]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP procedure [dbo].[ClearMasterWebSearchFields]
GO

CREATE PROCEDURE [dbo].[ClearMasterWebSearchFields]
	@tokey int -- ключ тура	
as
begin
	update dbo.TP_Tours set TO_Update = 1, TO_Progress = 0 where TO_Key = @tokey
	update CalculatingPriceLists with(rowlock) set CP_Status = 1 where CP_PriceTourKey = @tokey

	exec dbo.mwEnablePriceTour @tokey, 0

	delete from dbo.mwPriceDataTable where pt_tourkey = @tokey
	update dbo.TP_Tours set TO_Progress = 25 where TO_Key = @tokey

	delete from dbo.mwSpoDataTable where sd_tourkey = @tokey
	update dbo.TP_Tours set TO_Progress = 50 where TO_Key = @tokey

	delete from dbo.mwPriceDurations where sd_tourkey = @tokey
	update dbo.TP_Tours set TO_Progress = 75 where TO_Key = @tokey

	delete from dbo.mwPriceHotels where sd_tourkey = @tokey

	update CalculatingPriceLists with(rowlock) set CP_Status = 0 where CP_PriceTourKey = @tokey
	update dbo.TP_Tours set TO_Update = 0, TO_Progress = 100, TO_UpdateTime = GetDate() where TO_Key = @tokey
end
GO

GRANT EXECUTE ON [dbo].[ClearMasterWebSearchFields] TO PUBLIC 
GO

-- 100405_Insert_ObjectAliases.sql
IF NOT EXISTS (SELECT NULL FROM ObjectAliases WHERE OA_Id = 28)
	INSERT INTO ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	VALUES (28, 'QIWI Payment', 'Платёж через систему QIWI', 0)
GO

-- sp_DogovorMonitor.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DogovorMonitor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DogovorMonitor]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE [dbo].[DogovorMonitor]
  (
--<VERSION>2007.2.23</VERSION>
--<DATE>2009-03-03</DATE>
	@dtStartDate datetime,			-- начальная дата просмотра изменений
	@dtEndDate datetime,			-- конечная дата просмотра изменений
	@nCountryKey int,				-- ключ страны
	@nCityKey int,					-- ключ города
	@nDepartureCityKey int,			-- ключ города вылета
	@nCreatorKey int,				-- ключ создателя
	@nOwnerKey int,					-- ключ ведущего менеджера
	@nViewProceed smallint,			-- не показывать обработанные: 0 - показывать, 1 - не показывать
	@sFilterKeys varchar(255),		-- ключи выбранных фильтров
	@nFilialKey int					-- ключ филиала
  )
AS
BEGIN

CREATE TABLE #DogovorMonitorTable
(
	DM_CreateDate datetime, -- DM_HistoryDate
	DM_FirstProcDate datetime, -- NEW
	DM_LastProcDate datetime, -- DM_ProcDate
	DM_DGCODE nvarchar(10),
	DM_CREATOR nvarchar(25),
	DM_TurDate datetime,
	DM_TurName nvarchar(160),
	DM_PartnerName nvarchar(80),
	DM_FilterName nvarchar(1024),
	DM_NotesCount int,
	DM_PaymentStatus nvarchar(4),
	DM_IsBilled bit,
	DM_MessageCount int
)

declare @nObjectAliasFilter int, @sFilterType varchar(3)

DECLARE @dogovorCreateDate datetime, @lastDogovorActionDate datetime -- @dtHistoryDate
declare @sDGCode varchar(10), @nDGKey int
declare @sCreator varchar(25), @dtTurDate datetime, @sTurName varchar(160)
declare @sPartnerName varchar(80), @sFilterName varchar(255), @nHIID int
declare @sHistoryMod varchar(3), @sPaymentStatus as varchar(4)

set @sHistoryMod = 'DMP'

declare @nFilterKey int, @nLastPos int

while len(@sFilterKeys) > 0
begin
	set @nLastPos = 0
	set @nLastPos = charindex(',', @sFilterKeys, @nLastPos)
	if @nLastPos = 0
		set @nLastPos = len(@sFilterKeys) + 1
	
	set @nFilterKey = cast(substring(@sFilterKeys, 0, @nLastPos) as int)
	if @nLastPos <> len(@sFilterKeys) + 1
		set @sFilterKeys = substring(@sFilterKeys, @nLastPos + 1, len(@sFilterKeys) - @nLastPos)
	else
		set @sFilterKeys = ''
	
	select @sFilterName = DS_Value from Descriptions where DS_KEY = @nFilterKey


	declare filterCursor cursor local fast_forward for
	select OF_OAId, OF_Type
	from ObjectAliasFilters
	where OF_DSKey = @nFilterKey
	order by OF_OAId
	
	open filterCursor
	fetch next from filterCursor into @nObjectAliasFilter, @sFilterType
	while(@@fetch_status = 0)
	begin
		declare dogovorsCursor cursor local fast_forward for
		select DISTINCT 
			(SELECT MIN(HI_DATE) FROM history h2 WHERE h2.HI_DGCOD = DG_CODE) AS DOGOVOR_CREATE_DATE, 
			(SELECT MAX(HI_DATE) FROM history h2 WHERE h2.HI_DGCOD = DG_CODE) AS LAST_DOGOVOR_ACTION_DATE, 
			DG_CODE, US_FullName, DG_TurDate, TL_NAME, PR_NAME, DG_KEY,
			CASE
				WHEN DG_PRICE = 0 AND DG_PAYED = DG_PRICE THEN 'OK'
				WHEN DG_PAYED = 0 THEN 'NONE'
				WHEN DG_PAYED < DG_PRICE THEN 'LOW'
				WHEN DG_PAYED = DG_PRICE THEN 'OK'
				WHEN DG_PAYED > DG_PRICE THEN 'OVER'
			END AS DM_PAYMENTSTATUS
		from dogovor, history, historydetail, userlist, TurList, Partners
		where HI_DGCOD = DG_CODE and HI_ID = HD_HIID and US_KEY = DG_CREATOR and TL_KEY = DG_TRKEY and PR_KEY = DG_PARTNERKEY and 
			HI_DATE BETWEEN @dtStartDate and dateadd(day, 1, @dtEndDate) and
			(@nCountryKey < 0 OR DG_CNKEY = @nCountryKey) and
			(@nCityKey < 0 OR DG_CTKEY = @nCityKey) and
			(@nDepartureCityKey < 0 OR DG_CTDepartureKey = @nDepartureCityKey) and
			(@nCreatorKey < 0 OR DG_CREATOR = @nCreatorKey) and
			(@nOwnerKey < 0 OR DG_OWNER = @nOwnerKey) and
			(HD_OAId = @nObjectAliasFilter) and
			--(@nViewProceed = 0 OR NOT EXISTS (select HI_ID from history where HI_DGKEY = DG_KEY and HI_MOD LIKE @sHistoryMod)) and
			(@sFilterType = '' OR HI_MOD = @sFilterType) and
			(@nFilialKey < 0 OR DG_FILIALKEY = @nFilialKey)

		--нашли путевки
		open dogovorsCursor
		fetch next from dogovorsCursor into @dogovorCreateDate, @lastDogovorActionDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @nDGKey, @sPaymentStatus
		while(@@fetch_status = 0)
		begin
			--if not exists (select * from #DogovorMonitorTable where datediff(mi, DM_HistoryDate, @dtHistoryDate) = 0 and DM_DGCODE = @sDGCode and DM_FilterName LIKE @sFilterName)
			--begin
				DECLARE @firstDogovorProcessDate datetime 
				DECLARE @lastDogovorProcessDate datetime -- @hiDate

				SET @firstDogovorProcessDate = (select MIN(HI_DATE) from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod)
				SET @lastDogovorProcessDate = (select MAX(HI_DATE) from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod)

--				--select @hiDate = HI_DATE from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod
--				if exists (select HI_DATE from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod)
--					select @hiDate = HI_DATE from history where HI_DGCOD = @sDGCode and HI_MOD LIKE @sHistoryMod
--				else
--					set @hiDate = NULL

				DECLARE @notesCount int
				SELECT @notesCount = COUNT(HI_TEXT) FROM HISTORY
				WHERE HI_DGCOD = @sDGCode AND HI_MOD = 'WWW'

				DECLARE @isBilled bit
				SET @isBilled = 0
				IF EXISTS(SELECT AC_KEY FROM ACCOUNTS WHERE AC_DGCOD = @sDGCode)
					SET @isBilled = 1

				DECLARE @messageCount int
				SELECT @messageCount = COUNT(HI_TEXT) FROM HISTORY
				WHERE HI_DGCOD = @sDGCode AND HI_MOD = 'MTM'
				AND HI_TEXT NOT LIKE 'От агента: %' -- notes from web (copies of 'WWW' moded notes)

				DECLARE @includeRecord bit
				SET @includeRecord = 0

				if (@nViewProceed = 0) OR (@lastDogovorProcessDate IS NULL)
				begin
					--insert into #DogovorMonitorTable (DM_HistoryDate, DM_ProcDate, DM_DGCODE, DM_CREATOR, DM_TurDate, DM_TurName, DM_PartnerName, DM_FilterName, DM_NotesCount, DM_PaymentStatus, DM_IsBilled, DM_MessageCount)
					--values (@dtHistoryDate, @hiDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @sFilterName, @notesCount, @sPaymentStatus, @isBilled, @messageCount)
					SET @includeRecord = 1
				end
				else
				begin
					--if @dtHistoryDate > @hiDate
					if @lastDogovorActionDate > @lastDogovorProcessDate
					begin
						--insert into #DogovorMonitorTable (DM_HistoryDate, DM_ProcDate, DM_DGCODE, DM_CREATOR, DM_TurDate, DM_TurName, DM_PartnerName, DM_FilterName, DM_NotesCount, DM_PaymentStatus, DM_IsBilled, DM_MessageCount) 
						--values (@dtHistoryDate, @hiDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @sFilterName, @notesCount, @sPaymentStatus, @isBilled, @messageCount)
						SET @includeRecord = 1
					end
				end

				-------------------
				IF @includeRecord = 1
				BEGIN
					IF EXISTS (SELECT dm_dgcode FROM #DogovorMonitorTable WHERE dm_dgcode = @sDGCode)
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM #DogovorMonitorTable WHERE dm_dgcode = @sDGCode AND dm_filtername LIKE '%' + @sFilterName + '%')
							UPDATE #DogovorMonitorTable SET DM_FilterName = DM_FilterName + ', ' + @sFilterName WHERE dm_dgcode = @sDGCode
					END
					ELSE
					BEGIN
						INSERT INTO #DogovorMonitorTable
						VALUES (@dogovorCreateDate, @firstDogovorProcessDate, @lastDogovorProcessDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @sFilterName, @notesCount, @sPaymentStatus, @isBilled, @messageCount);
					END
				END
				-------------------

			--end
			fetch next from dogovorsCursor into @dogovorCreateDate, @lastDogovorActionDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @nDGKey, @sPaymentStatus
		end
			
		close dogovorsCursor
		deallocate dogovorsCursor

		fetch next from filterCursor into @nObjectAliasFilter, @sFilterType
	end

	close filterCursor
	deallocate filterCursor

end
	SELECT *
	FROM #DogovorMonitorTable
	ORDER BY DM_CreateDate
	
	DROP TABLE #DogovorMonitorTable

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT EXECUTE ON [dbo].[DogovorMonitor] TO Public
GO 


-- 100524(AlterTableTurMargin).sql
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[TurMargin]') and name = 'TM_Week')
	alter table dbo.TurMargin add TM_Week varchar(7) not null default('')
go

delete from dbo.UserSettings where ST_ParmName like 'TurMarginsForm.dgvTurMargins'
go

-- 100531_Insert_SystemSettings.sql
if not exists (select * from SystemSettings where SS_ParmName like 'SYSRateFixOnStatus')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values('SYSRateFixOnStatus', '1')
GO

if not exists (select * from SystemSettings where SS_ParmName like 'SYSRateFixOnDiscount')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values('SYSRateFixOnDiscount', '1')
GO

if not exists (select * from SystemSettings where SS_ParmName like 'SYSRateFixOnPrice')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values('SYSRateFixOnPrice', '1')
GO

if not exists (select * from SystemSettings where SS_ParmName like 'SYSRateFixOnCurrency')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values('SYSRateFixOnCurrency', '1')
GO

if not exists (select * from SystemSettings where SS_ParmName like 'SYSCheckChildAge')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values('SYSCheckChildAge', '0')
GO



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
				IF '1' = (SELECT SS_PARMVALUE FROM dbo.SystemSettings WHERE SS_PARMNAME = 'SYSRateFixOnCurrency')
					SET @bUpdateNationalCurrencyPrice = 1
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
				IF '1' = (SELECT SS_PARMVALUE FROM dbo.SystemSettings WHERE SS_PARMNAME = 'SYSRateFixOnPrice')
					SET @bUpdateNationalCurrencyPrice = 1
			END
		if (ISNULL(@ODG_DiscountSum, 0) != ISNULL(@NDG_DiscountSum, 0))
		BEGIN
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1007, @ODG_DiscountSum, @NDG_DiscountSum, null, null, null, null, 0, @bNeedCommunicationUpdate output
			IF '1' = (SELECT SS_PARMVALUE FROM dbo.SystemSettings WHERE SS_PARMNAME = 'SYSRateFixOnDiscount')
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

				IF (ISNULL(@ODG_SOR_Code, 0) = 2)
				BEGIN

					DECLARE @nDGSorCode_New int, @sDisableDogovorStatusChange int

					SELECT @sDisableDogovorStatusChange = SS_ParmValue FROM SystemSettings WHERE SS_ParmName like 'SYSDisDogovorStatusChange'
					IF (@sDisableDogovorStatusChange is null or @sDisableDogovorStatusChange = '0')
					BEGIN
					----------------Изменение статуса путевки в случае, если статусы услуг установлены в ОК
						SET @nDGSorCode_New = 7					--ОК
						IF exists (SELECT 1 FROM dbo.Setting WHERE ST_Version like '7%')
							IF exists (SELECT DL_Key FROM DogovorList WHERE DL_DGKey=@DG_Key and DL_Wait>0)
								SET @nDGSorCode_New = 3			--Wait-List

						IF @nDGSorCode_New != 3 
							IF exists (SELECT DL_Key FROM DogovorList WHERE DL_DGKey=@DG_Key and DL_Control > 0)
								SET @nDGSorCode_New = 4			--Не подтвержден
						
						select @sUpdateMainDogovorStatuses = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSUpdateMainDogStatuses'
						if (ISNULL(@sUpdateMainDogovorStatuses, '0') = '0')
							UPDATE Dogovor SET DG_Sor_Code = @nDGSorCode_New WHERE DG_Key=@DG_Key
						else
							-- изменяем статус путевки только если он был стандартным
							UPDATE Dogovor SET DG_Sor_Code = @nDGSorCode_New WHERE DG_Key=@DG_Key and DG_Sor_Code in (1,2,3,7)
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

				IF '1' = (SELECT SS_PARMVALUE FROM dbo.SystemSettings WHERE SS_PARMNAME = 'SYSRateFixOnStatus')
					SET @bUpdateNationalCurrencyPrice = 1
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
		IF @bUpdateNationalCurrencyPrice = 1 AND @sMod = 'UPD'
		BEGIN
			DECLARE @sAction VARCHAR(100)
			DECLARE @DGCODE VARCHAR(100)
			SET @sAction = 'RECALCULATE_BY_TODAY_CURRENCY_RATE'

			-- See if "variable" is set (with frmDogovor (tour.apl) only)
			IF OBJECT_ID('tempdb..#RecalculateAction') IS NOT NULL
			BEGIN
				SELECT @DGCODE  = [DGCODE] FROM #RecalculateAction
				if @DGCODE = @NDG_Code
				begin
					SELECT @sAction = [Action] FROM #RecalculateAction
					DROP TABLE #RecalculateAction
				end
			END
			EXEC dbo.NationalCurrencyPrice @ODG_Rate, @NDG_Rate, @ODG_Code, @NDG_Price, @ODG_Price, @NDG_DiscountSum, @sAction, @NDG_SOR_Code
	  END
	  END

		-- recalculate if exchange rate changes (another table) & saving from frmDogovor (tour.apl)
		-- + force-drop #RecalculateAction table in case hasn't been
		IF OBJECT_ID('tempdb..#RecalculateAction') IS NOT NULL
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
		END
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

-- T_mwUpdateHotel.sql
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


-- 100601_Insert_ObjectAliases.sql
IF NOT EXISTS (SELECT NULL FROM ObjectAliases WHERE OA_Id = 29)
	INSERT INTO ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	VALUES (29, 'HotelRooms', 'Номера в отелях', 0)
GO


-- T_HotelRoomsDelete.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_HotelRoomsDelete]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_HotelRoomsDelete]
GO

CREATE TRIGGER [T_HotelRoomsDelete]
	ON [dbo].[HotelRooms] 
FOR DELETE
AS
BEGIN
	declare @key int
	declare curDelete cursor for select hr_key from deleted
	open curDelete 
	Fetch Next From curDelete INTO @key
	WHILE @@FETCH_STATUS = 0
	BEGIN
		Delete from tbl_Costs Where CS_SvKey = 3 AND CS_SubCode1 = @key
		Fetch Next From curDelete INTO @key
	END
	close curDelete
	deallocate curDelete
	
	INSERT INTO dbo.History (HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_OAID, HI_TYPE, HI_TYPECODE, HI_HOST, HI_MessEnabled)
	SELECT GETDATE(), USER, APP_NAME(), 'DEL', 29, 'HotelRooms', HR_KEY, HOST_NAME(), 0
	FROM DELETED
END
GO

-- sp_GetTourMargin.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetTourMargin]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[GetTourMargin] 
GO
CREATE PROCEDURE [dbo].[GetTourMargin] 
(	@TrKey int, @Date datetime, @margin float output, @marginType int output, 
	@svKey int, @days int, @sellDate DateTime = null, @packetKey int)
as
--<DATE>2008-12-04</DATE>
--<VERSION>7.2.20</VERSION>
	SET DATEFIRST 1

	if @sellDate is null
		Set @sellDate = GetDate()

	set @margin = 0
	set @marginType = 0

	declare @nFromPacket int
	declare @dtSale DateTime
	Set @nFromPacket = 0
		
	SELECT TOP 1	@margin = TM_Margin, @marginType = TM_MarginType, @nFromPacket = TM_FromPacket, 
					@dtSale = ISNULL(TM_DateSellEnd,ISNULL(DATEADD(YEAR,10,TM_DateSellBeg),DATEADD(YEAR,15,GetDate())))
	FROM
		dbo.TurMargin
	WHERE
		TM_TlKey = @TrKey 
		and @Date Between TM_DateBeg and TM_DateEnd
		and (TM_SVKEY = @svKey or TM_SVKEY = 0)
		and (@sellDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
		and (@sellDate <= (TM_DateSellEnd + 1) or TM_DateSellEnd is null)
		and ((TM_Week like '%' + cast(datepart(weekday, @Date)as varchar(1)) + '%') or TM_Week like '.......' or TM_Week like '')
		and (TM_LONG = @days - 1 or TM_LONG = 0)
	ORDER BY	TM_SVKEY DESC,  TM_DateBeg DESC, TM_DateEnd, 4, TM_LONG DESC

	if @nFromPacket = 1 AND @packetKey>0
	begin 
		set @margin = 0
		set @marginType = 0
		SELECT TOP 1	@margin = TM_Margin, @marginType = TM_MarginType, @nFromPacket = TM_FromPacket, 
						@dtSale = ISNULL(TM_DateSellEnd,ISNULL(DATEADD(YEAR,10,TM_DateSellBeg),DATEADD(YEAR,15,GetDate())))
		FROM
			dbo.TurMargin
		WHERE
			TM_TlKey = @packetKey
			and @Date Between TM_DateBeg and TM_DateEnd
			and (TM_SVKEY = @svKey or TM_SVKEY = 0)
			and (@sellDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@sellDate <= (TM_DateSellEnd + 1) or TM_DateSellEnd is null)
			and ((TM_Week like '%' + cast(datepart(weekday, @Date)as varchar(1)) + '%') or TM_Week like '.......' or TM_Week like '')
			and (TM_LONG = @days - 1 or TM_LONG = 0)
			and TM_FromPacket = 0
		ORDER BY	TM_SVKEY DESC,  TM_DateBeg DESC, TM_DateEnd, 4, TM_LONG DESC
	end

	if @margin is null
		Set @margin = 0
	If @marginType is null
		set @marginType = 0
	Return 0
GO
GRANT EXECUTE ON [dbo].[GetTourMargin] TO PUBLIC 
GO

-- 100602_Insert_SystemSettings.sql
if not exists (select * from SystemSettings where SS_ParmName like 'SYSUseTouristBlackList')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values('SYSUseTouristBlackList', '0')
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
	Update	TP_Flights with(rowlock) Set 	TF_CodeNew = TF_CodeOld,
				TF_PRKeyNew = TF_PRKeyOld
	Where	(SELECT count(*) FROM AirSeason  with(nolock) WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') > 0 
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

	declare @bExist int
	exec isObjectExist 'mwReplTours', null, 'T' , @bExist out
	if @bExist = 1
		insert into dbo.mwReplTours (rt_trkey, rt_tokey) values (@TrKey, @nPriceTourKey)    

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

--собираем колонки типов номеров для запроса
declare @PNames as varchar(4000)
set @PNames = ''
select @PNames = @PNames + ',' +
	'max(case when pt_rmkey = ' + convert(varchar,rm_key) +
    ' then pt_price else 0 end) as ''rmkey_' + convert(varchar,rm_key) + ''',
	sum(case when pt_rmkey = ' + convert(varchar,rm_key) +
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

-- sp_Paging.sql
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
			ptKey int,
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

-- 100603(QuotaBlocks_TourMonthes).sql
if not exists(select 1 from desctypes where dt_key = 131)
	insert into desctypes(dt_key, dt_name, dt_tableid, dt_order)
	values(131, 'QuotaBlocksDaysDepth', 9, 0)
go


if not exists(select 1 from desctypes where dt_key = 132)
	insert into desctypes(dt_key, dt_name, dt_tableid, dt_order)
	values(132, 'QuotaBlocksMinDaysBeforeFlight', 9, 0)
go

if object_id('[dbo].[mwAnkCountryFields]', 'V') is not null
	drop view [dbo].[mwAnkCountryFields]
go

/****** Объект:  View [dbo].[mwAnkCountryFields] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[mwAnkCountryFields] AS
	SELECT AF_Key, AF_Name, AF_IsCopied, AF_UseDict, 
		AF_MainColumn, AF_IsVar, AF_DVALUE, AF_SELECT, AC_Required as AF_Required, AC_Description as AF_Comment, ANK_COUNTRY.AC_FRMKEY, ANK_COUNTRY.AC_ORDER FROM ANK_FIELDS INNER JOIN ANK_COUNTRY ON AC_AFKEY = AF_KEY
GO

grant select on [dbo].[mwAnkCountryFields] to public
go

if object_id('[dbo].[mwGetTourMonthesQuotas]', 'p') is not null
	drop proc [dbo].[mwGetTourMonthesQuotas]
go


/****** Объект:  StoredProcedure [dbo].[mwGetTourMonthesQuotas]  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

	declare tour_cursor cursor fast_forward read_only 
	for
		select 
			td_trkey,
			isnull(tl_nameweb, isnull(tl_name, '')),
			isnull(tl_webhttp, '') as tour_url,
			td_date,
			month(td_date),
			tl_nday
		from 
			turdate with(nolock)
			inner join turlist with(nolock) on tl_key = td_trkey
		where
			td_date between getdate() 
			and dateadd(month, @month_count, getdate()) 
			and ((@cnkey >= 0 and tl_cnkey = @cnkey) or (@tour_type >= 0 and tl_tip = @tour_type))
			and tl_web > 0 
		order by
			isnull(tl_nameweb, isnull(tl_name, '')),
			td_date			


		declare 
			@tour_key int, 
			@prev_tour_key int, 
			@prev_month int, 
			@tour_name nvarchar(250),
            @tour_url nvarchar(500),
            @tour_date datetime,
            @month int,
			@tour_quotas nvarchar(4000),
			@tour_duration int

	set @tour_key = -1
	set @prev_tour_key = -1
	set @prev_month = -1
	set @tour_name = ''
	set @tour_url = ''
	set @tour_date = '1800-01-01'
	set @month = 0
	set @tour_quotas = ''

	open tour_cursor

	create table #turService(
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

	fetch next from tour_cursor into @tour_key, @tour_name, @tour_url, @tour_date, @month, @tour_duration
	while @@fetch_status = 0
	begin

        if (@tour_key != @prev_tour_key)
        begin
			insert into #tourQuotas (
				tour_key,
				tour_name,
				tour_url)
			values (
				@tour_key,
				@tour_name,
				@tour_url
			)

            set @prev_month = -1
			if (@prev_tour_key > 0)
				update #tourQuotas
				set tour_quotas = @tour_quotas
				where tour_key = @prev_tour_key

			set @tour_quotas = ''

			truncate table #turService

			set @sql = N'select 
							ts_svkey,
							ts_code,
							ts_subcode1,
							ts_subcode2,
							ts_day,
							ts_ndays,
							ts_partnerkey,
							ts_pkkey
						from
							turservice
						where
							ts_trkey = ' + str(@tour_key) +N'
							and ts_svkey in (' + isnull(@quoted_services, N'3') + N')'

			insert into #turService exec(@sql)

        end

        if (@month != @prev_month or @tour_key != @prev_tour_key)
        begin
			if (len(@tour_quotas) > 0)		
				set @tour_quotas = @tour_quotas + '|' 
			set @tour_quotas = @tour_quotas + ltrim(str(@month)) + '='
        end
		
		declare service_cursor cursor fast_forward read_only
		for
			select
				ts_svkey,
				ts_code,
				ts_subcode1,
				ts_subcode2,
				ts_day,
				ts_ndays,
				(case when @checkAllPartnersQuota > 0 then -1 else ts_partnerkey end),
				(case when ts_svkey = 1 and @checkFlightPacket > 0 then ts_pkkey else -1 end)
			from 
				#turService
		
		declare
			@svkey int,
			@code int,
			@subcode1 int,
			@subcode2 int,
			@day int,
			@ndays int,
			@partner_key int,
			@packet_key int,
			@places int,
			@allplaces int,
			@date_places int,
			@date_allplaces int

		open service_cursor

		fetch next from service_cursor into @svkey, @code, 
			@subcode1, @subcode2, @day, @ndays, @partner_key, @packet_key
		while @@fetch_status = 0
		begin
			select 
				@places = qt_places,
				@allplaces = qt_allplaces
			from
				dbo.mwCheckQuotesEx(
					@svkey, 
					@code, 
					-1, 
					-1, 
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

            if (@places = 0)
            begin
                set @date_places = 0
				set @date_allplaces = 0
                break
            end
            else if (@places = -1)
			begin
                set @date_places = @places
				set @date_allplaces = 0
			end
            else if (@places > 0 and (@date_places is null or @date_places > @places))
			begin
                set @date_places = @places
				set @date_allplaces = @allplaces
			end

			fetch next from service_cursor into @svkey, @code, 
				@subcode1, @subcode2, @day, @ndays, @partner_key, @packet_key
		end
	
		close service_cursor
		deallocate service_cursor

		if(@date_places is null)
		begin	
			set @date_places = -1
			set @date_allplaces = 0
		end

		if(substring(@tour_quotas, len(@tour_quotas), 1) != '=')
			set @tour_quotas = @tour_quotas + ','
		set @tour_quotas = @tour_quotas + ltrim(str(day(@tour_date))) + '#' + ltrim(str(@date_places)) + ':' + ltrim(str(@date_allplaces))


		set @prev_tour_key = @tour_key
		set @prev_month = @month
		fetch next from tour_cursor into @tour_key, @tour_name, @tour_url, @tour_date, @month, @tour_duration
	end

	update #tourQuotas
	set tour_quotas = @tour_quotas
	where tour_key = @prev_tour_key

	close tour_cursor
	deallocate tour_cursor

	select * from #tourQuotas
end
go

grant exec on [dbo].[mwGetTourMonthesQuotas] to public
go

-- 100603_Insert_ObjectAliases.sql
IF NOT EXISTS (SELECT NULL FROM ObjectAliases WHERE OA_Id = 1140)
	INSERT INTO ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	VALUES (1140, 'NonGrataWarning', 'Предупреждение Non Grata', 0)
GO

-- 100528(AlterTable_Clients).sql
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[DUP_USER]') and name = 'US_CLKey')
	ALTER TABLE dbo.DUP_USER ADD US_CLKey int NULL
GO

-- 100325(RepotByWin_Alter).sql
if NOT EXISTS (select * from syscolumns where name='RW_ExternalPath' and id=object_id('REPORTBYWIN'))
BEGIN
	ALTER TABLE REPORTBYWIN 
	ADD RW_ExternalPath NVARCHAR(500)  NULL
END
GO

-- (100518)alter_history.sql
IF  EXISTS (select * from sysobjects where id = object_id(N'[dbo].[FK_HistoryDetail_History]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
ALTER TABLE [dbo].[HistoryDetail] DROP CONSTRAINT [FK_HistoryDetail_History]
GO

IF  EXISTS (SELECT * FROM sysindexes WHERE id = OBJECT_ID(N'[dbo].[History]') AND name = N'PK_History')
ALTER TABLE [dbo].[History] DROP CONSTRAINT [PK_History]
GO

ALTER TABLE [dbo].[History] ADD  CONSTRAINT [PK_HISTORY] PRIMARY KEY CLUSTERED 
([HI_ID] ASC) ON [PRIMARY]
GO

ALTER TABLE [dbo].[HistoryDetail]  WITH NOCHECK ADD  CONSTRAINT [FK_HistoryDetail_History] FOREIGN KEY([HD_HIID])
REFERENCES [dbo].[History] ([HI_ID])
ON DELETE CASCADE
GO

IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[InsHistory]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[InsHistory]
GO

CREATE PROCEDURE [dbo].[InsHistory]
(
--<VERSION>2005.2.41.2</VERSION>
	@sDGCod varchar(10),
	@nDGKey int,
	@nOAId int,
	@nTypeCode int,
	@sMod varchar(3),
	@sText varchar(254),
	@sRemark varchar(25),
	@nInvisible int,
	@sDocumentNumber varchar(255),
	@bMessEnabled bit=0,
	@nSVKey int=null,
	@nCode int=null,
	@nHiId int=null output
)
AS
	declare @sWho varchar(25), @sType varchar(32)
	EXEC dbo.CurrentUser @sWho output
	select @sType = left(OA_Alias, 32) from ObjectAliases where OA_Id = @nOAId
	
	IF @nDGKey IS NULL AND @sDGCod IS NOT NULL
	BEGIN
		SELECT @nDGKey = DG_KEY 
		FROM dbo.tbl_Dogovor 
		WHERE DG_CODE = @sDGCod
	END
	
	INSERT INTO dbo.History (
		HI_DGCOD, HI_DGKEY, HI_OAId, HI_DATE, HI_WHO, 
		HI_TEXT, HI_MOD, HI_REMARK, HI_TYPE, HI_TYPECODE, 
		HI_INVISIBLE, HI_DOCUMENTNAME, HI_MessEnabled, HI_SVKey, HI_Code)
	VALUES (
		@sDGCod, @nDGKey, @nOAId, GETDATE(), @sWho, 
		@sText, @sMod, @sRemark, @sType, @nTypeCode, 
		@nInvisible, @sDocumentNumber, @bMessEnabled, @nSVKey, @nCode)

		Set @nHiId = SCOPE_IDENTITY()

	RETURN SCOPE_IDENTITY()
GO

GRANT EXEC ON [dbo].[InsHistory] TO PUBLIC
GO

IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[InsertHistory]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[InsertHistory]
GO

CREATE PROCEDURE [dbo].[InsertHistory]
(
	@sHI_DGCOD varchar(10) = null,
	@nHI_DLKEY int = null,
	@sHI_MOD varchar(3),
	@sHI_TEXT varchar(254),
	@sHI_REMARK varchar(25)
)
AS
	declare @sHI_WHO varchar(25)
	declare @nHI_SVKEY int
	declare @nHI_CODE int
	declare @nHI_CODE1 int
	declare @nHI_CODE2 int
	declare @nHI_DAY smallint
	declare @nHI_NDAYS smallint
	declare @nHI_NMEN smallint
	declare @nHI_PRKEY int
	declare @nHI_DGKEY int

	Set @nHI_SVKEY = null
	Set @nHI_SVKEY = null
	Set @nHI_CODE = null
	Set @nHI_CODE1 = null
	Set @nHI_CODE2 = null
	Set @nHI_DAY = null
	Set @nHI_NDAYS = null
	Set @nHI_NMEN = null
	Set @nHI_PRKEY = null
	Set @nHI_DGKEY = null

	If @nHI_DLKEY is not null
	BEGIN
		SELECT 	@sHI_DGCOD = DL_DGCOD, @nHI_SVKEY = DL_SVKEY, @nHI_CODE = DL_CODE, @nHI_CODE1 = DL_SUBCODE1,
				@nHI_CODE2 = DL_SUBCODE2, @nHI_DAY = DL_DAY, @nHI_NDAYS = DL_NDAYS, @nHI_NMEN = DL_NMEN,
				@nHI_PRKEY = DL_PARTNERKEY, @nHI_DGKEY = DL_DGKEY
		FROM	dbo.tbl_DogovorList
		WHERE	DL_KEY = @nHI_DLKEY
	END

	EXEC dbo.CurrentUser @sHI_WHO output

	IF @nHI_DGKEY IS NULL AND @sHI_DGCOD IS NOT NULL
	BEGIN
		SELECT @nHI_DGKEY = DG_KEY 
		FROM dbo.tbl_Dogovor 
		WHERE DG_CODE = @sHI_DGCOD
	END

	INSERT INTO dbo.History (HI_DGCOD, HI_DGKEY, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_REMARK, HI_DLKEY, HI_SVKEY,
							 HI_CODE, HI_CODE1, HI_CODE2, HI_DAY, HI_NDAYS, HI_NMEN, HI_PRKEY)
	VALUES (@sHI_DGCOD, @nHI_DGKEY, GETDATE(), @sHI_WHO, @sHI_TEXT, @sHI_MOD, @sHI_REMARK, @nHI_DLKEY, @nHI_SVKEY,
			@nHI_CODE,  @nHI_CODE1, @nHI_CODE2, @nHI_DAY, @nHI_NDAYS, @nHI_NMEN, @nHI_PRKEY)
GO

GRANT EXEC ON [dbo].[InsertHistory] TO PUBLIC
GO

-- alter_SystemLog.sql
if (@@version like '%SQL%Server%2000%')
	alter table SystemLog alter column sl_message varchar(8000) null
else
	alter table SystemLog alter column sl_message text null


-- view_mwPriceTablePax.sql
if exists(select id from sysobjects where xtype='v' and name='mwPriceTablePax')
	drop view dbo.mwPriceTablePax
go

Create view [dbo].[mwPriceTablePax] as
select	*, 
			(CASE WHEN (pt_rmkey = 1 OR pt_rmkey = 2) THEN 0 ELSE pt_rmkey END) as pt_PaxRoomType,
			pt_AccmdType as pt_PaxColumnType
from	dbo.mwPriceDataTable with (nolock)
where	pt_isenabled > 0
go

grant select on dbo.mwPriceTablePax to public
go


-- view_mwPriceTablePaxViewAsc.sql
if exists(select id from sysobjects where xtype='v' and name='mwPriceTablePaxViewAsc')
	drop view dbo.mwPriceTablePaxViewAsc
go

Create view [dbo].[mwPriceTablePaxViewAsc] as
SELECT	
		max(t1.pt_ctkey)	pt_ctkey,
		max(t1.pt_ctname)	pt_ctname,
		t1.pt_hdkey			pt_hdkey,
		max(t1.pt_hdname)	pt_hdname,
		max(t1.pt_hdstars)	pt_hdstars,
		t1.pt_pnkey			pt_pnkey,
		max(t1.pt_pncode)	pt_pncode,
		max(t1.pt_rate)		pt_rate,
		max(t1.pt_rmkey)	pt_rmkey,
		max(t1.pt_rmname)	pt_rmname,
		t1.pt_rckey			pt_rckey,
		max(t1.pt_rcname)	pt_rcname,
		t1.pt_tourdate	,

		t1.pt_cnkey		,
		t1.pt_ctkeyfrom	,
		t1.pt_tourtype	,

		MIN(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_2_1_DBL,
		MAX(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_2_1_DBL,
		MIN(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_2_1_SGL,
		MAX(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_2_1_SGL,
		MIN(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_2_1_EXB,
		MAX(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_2_1_EXB,
		MIN(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_2_1_CHD,
		MAX(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_2_1_CHD,

		MIN(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_3_2_DBL,
		MAX(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_3_2_DBL,
		MIN(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_3_2_SGL,
		MAX(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_3_2_SGL,
		MIN(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_3_2_EXB,
		MAX(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_3_2_EXB,
		MIN(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_3_2_CHD,
		MAX(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_3_2_CHD,

		MIN(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_4_3_DBL,
		MAX(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_4_3_DBL,
		MIN(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_4_3_SGL,
		MAX(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_4_3_SGL,
		MIN(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_4_3_EXB,
		MAX(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_4_3_EXB,
		MIN(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_4_3_CHD,
		MAX(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_4_3_CHD,

		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_5_2_DBL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_5_2_DBL,
		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_5_2_SGL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_5_2_SGL,
		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_5_2_EXB,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_5_2_EXB,
		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_5_2_CHD,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_5_2_CHD,

		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_5_3_DBL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_5_3_DBL,
		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_5_3_SGL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_5_3_SGL,
		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_5_3_EXB,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_5_3_EXB,
		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_5_3_CHD,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_5_3_CHD,

		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_5_4_DBL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_5_4_DBL,
		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_5_4_SGL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_5_4_SGL,
		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_5_4_EXB,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_5_4_EXB,
		MIN(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_5_4_CHD,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_5_4_CHD,

		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_6_2_DBL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_6_2_DBL,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_6_2_SGL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_6_2_SGL,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_6_2_EXB,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_6_2_EXB,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_6_2_CHD,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_6_2_CHD,

		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_6_3_DBL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_6_3_DBL,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_6_3_SGL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_6_3_SGL,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_6_3_EXB,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_6_3_EXB,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_6_3_CHD,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_6_3_CHD,

		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_6_4_DBL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_6_4_DBL,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_6_4_SGL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_6_4_SGL,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_6_4_EXB,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_6_4_EXB,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_6_4_CHD,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_6_4_CHD,

		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_6_5_DBL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_6_5_DBL,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_6_5_SGL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_6_5_SGL,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_6_5_EXB,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_6_5_EXB,
		MIN(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_6_5_CHD,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_6_5_CHD,

		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_7_3_DBL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_7_3_DBL,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_7_3_SGL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_7_3_SGL,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_7_3_EXB,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_7_3_EXB,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_7_3_CHD,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_7_3_CHD,

		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_7_4_DBL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_7_4_DBL,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_7_4_SGL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_7_4_SGL,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_7_4_EXB,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_7_4_EXB,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_7_4_CHD,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_7_4_CHD,

		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_7_5_DBL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_7_5_DBL,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_7_5_SGL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_7_5_SGL,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_7_5_EXB,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_7_5_EXB,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_7_5_CHD,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_7_5_CHD,

		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_7_6_DBL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_7_6_DBL,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_7_6_SGL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_7_6_SGL,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_7_6_EXB,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_7_6_EXB,
		MIN(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_7_6_CHD,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_7_6_CHD,

		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_8_3_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_3_DBL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_8_3_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_3_SGL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_8_3_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_3_EXB,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_8_3_CHD,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_3_CHD,

		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_8_4_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_4_DBL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_8_4_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_4_SGL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_8_4_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_4_EXB,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_8_4_CHD,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_4_CHD,

		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_8_5_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_5_DBL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_8_5_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_5_SGL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_8_5_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_5_EXB,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_8_5_CHD,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_5_CHD,

		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_8_6_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_6_DBL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_8_6_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_6_SGL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_8_6_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_6_EXB,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_8_6_CHD,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_6_CHD,

		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_8_7_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_7_DBL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_8_7_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_7_SGL,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_8_7_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_7_EXB,
		MIN(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_8_7_CHD,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_7_CHD,

		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_9_4_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_4_DBL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_9_4_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_4_SGL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_9_4_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_4_EXB,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_9_4_CHD,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_4_CHD,

		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_9_5_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_5_DBL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_9_5_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_5_SGL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_9_5_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_5_EXB,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_9_5_CHD,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_5_CHD,

		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_9_6_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_6_DBL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_9_6_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_6_SGL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_9_6_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_6_EXB,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_9_6_CHD,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_6_CHD,

		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_9_7_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_7_DBL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_9_7_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_7_SGL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_9_7_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_7_EXB,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_9_7_CHD,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_7_CHD,

		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_9_8_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_8_DBL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_9_8_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_8_SGL,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_9_8_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_8_EXB,
		MIN(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_9_8_CHD,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_8_CHD,

		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_10_5_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_5_DBL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_10_5_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_5_SGL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_10_5_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_5_EXB,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_10_5_CHD,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_5_CHD,

		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_10_6_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_6_DBL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_10_6_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_6_SGL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_10_6_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_6_EXB,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_10_6_CHD,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_6_CHD,

		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_10_7_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_7_DBL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_10_7_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_7_SGL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_10_7_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_7_EXB,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_10_7_CHD,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_7_CHD,

		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_10_8_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_8_DBL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_10_8_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_8_SGL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_10_8_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_8_EXB,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_10_8_CHD,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_8_CHD,

		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_10_9_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_9_DBL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_10_9_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_9_SGL,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_10_9_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_9_EXB,
		MIN(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_10_9_CHD,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_9_CHD,

		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_11_6_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_6_DBL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_11_6_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_6_SGL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_11_6_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_6_EXB,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_11_6_CHD,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_6_CHD,

		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_11_7_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_7_DBL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_11_7_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_7_SGL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_11_7_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_7_EXB,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_11_7_CHD,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_7_CHD,

		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_11_8_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_8_DBL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_11_8_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_8_SGL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_11_8_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_8_EXB,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_11_8_CHD,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_8_CHD,

		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_11_9_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_9_DBL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_11_9_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_9_SGL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_11_9_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_9_EXB,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_11_9_CHD,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_9_CHD,

		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_11_10_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_10_DBL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_11_10_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_10_SGL,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_11_10_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_10_EXB,
		MIN(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_11_10_CHD,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_10_CHD,

		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_12_7_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_7_DBL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_12_7_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_7_SGL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_12_7_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_7_EXB,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_12_7_CHD,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_7_CHD,

		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_12_8_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_8_DBL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_12_8_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_8_SGL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_12_8_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_8_EXB,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_12_8_CHD,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_8_CHD,

		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_12_9_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_9_DBL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_12_9_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_9_SGL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_12_9_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_9_EXB,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_12_9_CHD,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_9_CHD,

		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_12_10_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_10_DBL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_12_10_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_10_SGL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_12_10_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_10_EXB,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_12_10_CHD,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_10_CHD,

		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_12_11_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_11_DBL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_12_11_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_11_SGL,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_12_11_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_11_EXB,
		MIN(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_12_11_CHD,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_11_CHD,

		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_13_8_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_8_DBL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_13_8_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_8_SGL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_13_8_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_8_EXB,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_13_8_CHD,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_8_CHD,

		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_13_9_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_9_DBL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_13_9_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_9_SGL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_13_9_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_9_EXB,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_13_9_CHD,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_9_CHD,

		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_13_10_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_10_DBL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_13_10_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_10_SGL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_13_10_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_10_EXB,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_13_10_CHD,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_10_CHD,

		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_13_11_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_11_DBL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_13_11_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_11_SGL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_13_11_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_11_EXB,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_13_11_CHD,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_11_CHD,

		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_13_12_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_12_DBL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_13_12_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_12_SGL,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_13_12_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_12_EXB,
		MIN(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_13_12_CHD,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_12_CHD,

		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_14_9_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_9_DBL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_14_9_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_9_SGL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_14_9_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_9_EXB,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_14_9_CHD,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_9_CHD,

		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_14_10_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_10_DBL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_14_10_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_10_SGL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_14_10_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_10_EXB,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_14_10_CHD,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_10_CHD,

		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_14_11_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_11_DBL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_14_11_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_11_SGL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_14_11_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_11_EXB,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_14_11_CHD,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_11_CHD,

		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_14_12_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_12_DBL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_14_12_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_12_SGL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_14_12_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_12_EXB,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_14_12_CHD,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_12_CHD,

		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_14_13_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_13_DBL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_14_13_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_13_SGL,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_14_13_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_13_EXB,
		MIN(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_14_13_CHD,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_13_CHD,

		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_15_10_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_10_DBL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_15_10_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_10_SGL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_15_10_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_10_EXB,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_15_10_CHD,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_10_CHD,

		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_15_11_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_11_DBL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_15_11_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_11_SGL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_15_11_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_11_EXB,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_15_11_CHD,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_11_CHD,

		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_15_12_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_12_DBL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_15_12_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_12_SGL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_15_12_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_12_EXB,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_15_12_CHD,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_12_CHD,

		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_15_13_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_13_DBL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_15_13_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_13_SGL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_15_13_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_13_EXB,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_15_13_CHD,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_13_CHD,

		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_15_14_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_14_DBL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_15_14_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_14_SGL,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_15_14_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_14_EXB,
		MIN(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_15_14_CHD,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_14_CHD,

		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_16_10_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_10_DBL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_16_10_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_10_SGL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_16_10_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_10_EXB,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_16_10_CHD,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_10_CHD,

		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_16_11_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_11_DBL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_16_11_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_11_SGL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_16_11_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_11_EXB,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_16_11_CHD,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_11_CHD,

		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_16_12_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_12_DBL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_16_12_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_12_SGL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_16_12_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_12_EXB,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_16_12_CHD,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_12_CHD,

		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_16_13_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_13_DBL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_16_13_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_13_SGL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_16_13_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_13_EXB,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_16_13_CHD,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_13_CHD,

		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_16_14_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_14_DBL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_16_14_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_14_SGL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_16_14_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_14_EXB,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_16_14_CHD,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_14_CHD,

		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_16_15_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_15_DBL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_16_15_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_15_SGL,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_16_15_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_15_EXB,
		MIN(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_16_15_CHD,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_15_CHD,

		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_17_12_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_12_DBL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_17_12_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_12_SGL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_17_12_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_12_EXB,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_17_12_CHD,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_12_CHD,

		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_17_13_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_13_DBL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_17_13_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_13_SGL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_17_13_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_13_EXB,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_17_13_CHD,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_13_CHD,

		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_17_14_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_14_DBL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_17_14_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_14_SGL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_17_14_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_14_EXB,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_17_14_CHD,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_14_CHD,

		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_17_15_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_15_DBL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_17_15_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_15_SGL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_17_15_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_15_EXB,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_17_15_CHD,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_15_CHD,

		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_17_16_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_16_DBL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_17_16_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_16_SGL,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_17_16_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_16_EXB,
		MIN(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_17_16_CHD,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_16_CHD,

		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_18_13_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_13_DBL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_18_13_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_13_SGL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_18_13_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_13_EXB,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_18_13_CHD,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_13_CHD,

		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_18_14_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_14_DBL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_18_14_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_14_SGL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_18_14_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_14_EXB,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_18_14_CHD,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_14_CHD,

		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_18_15_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_15_DBL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_18_15_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_15_SGL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_18_15_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_15_EXB,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_18_15_CHD,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_15_CHD,

		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_18_16_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_16_DBL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_18_16_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_16_SGL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_18_16_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_16_EXB,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_18_16_CHD,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_16_CHD,

		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_18_17_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_17_DBL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_18_17_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_17_SGL,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_18_17_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_17_EXB,
		MIN(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_18_17_CHD,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_17_CHD,

		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_19_14_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_14_DBL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_19_14_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_14_SGL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_19_14_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_14_EXB,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_19_14_CHD,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_14_CHD,		

		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_19_15_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_15_DBL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_19_15_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_15_SGL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_19_15_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_15_EXB,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_19_15_CHD,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_15_CHD,

		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_19_16_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_16_DBL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_19_16_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_16_SGL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_19_16_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_16_EXB,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_19_16_CHD,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_16_CHD,

		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_19_17_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_17_DBL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_19_17_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_17_SGL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_19_17_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_17_EXB,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_19_17_CHD,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_17_CHD,

		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_19_18_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_18_DBL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_19_18_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_18_SGL,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_19_18_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_18_EXB,
		MIN(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_19_18_CHD,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_18_CHD,

		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_20_15_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_15_DBL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_20_15_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_15_SGL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_20_15_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_15_EXB,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_20_15_CHD,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_15_CHD,

		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_20_16_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_16_DBL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_20_16_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_16_SGL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_20_16_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_16_EXB,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_20_16_CHD,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_16_CHD,

		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_20_17_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_17_DBL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_20_17_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_17_SGL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_20_17_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_17_EXB,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_20_17_CHD,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_17_CHD,

		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_20_18_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_18_DBL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_20_18_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_18_SGL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_20_18_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_18_EXB,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_20_18_CHD,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_18_CHD,

		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_20_19_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_19_DBL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_20_19_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_19_SGL,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_20_19_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_19_EXB,
		MIN(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_20_19_CHD,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_19_CHD,

		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_21_16_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_16_DBL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_21_16_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_16_SGL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_21_16_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_16_EXB,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_21_16_CHD,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_16_CHD,

		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_21_17_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_17_DBL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_21_17_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_17_SGL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_21_17_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_17_EXB,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_21_17_CHD,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_17_CHD,

		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_21_18_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_18_DBL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_21_18_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_18_SGL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_21_18_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_18_EXB,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_21_18_CHD,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_18_CHD,

		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_21_19_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_19_DBL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_21_19_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_19_SGL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_21_19_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_19_EXB,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_21_19_CHD,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_19_CHD,

		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_21_20_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_20_DBL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_21_20_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_20_SGL,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_21_20_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_20_EXB,
		MIN(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_21_20_CHD,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_20_CHD,

		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_22_17_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_17_DBL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_22_17_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_17_SGL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_22_17_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_17_EXB,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_22_17_CHD,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_17_CHD,

		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_22_18_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_18_DBL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_22_18_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_18_SGL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_22_18_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_18_EXB,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_22_18_CHD,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_18_CHD,

		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_22_19_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_19_DBL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_22_19_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_19_SGL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_22_19_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_19_EXB,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_22_19_CHD,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_19_CHD,

		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_22_20_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_20_DBL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_22_20_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_20_SGL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_22_20_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_20_EXB,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_22_20_CHD,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_20_CHD,

		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_22_21_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_21_DBL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_22_21_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_21_SGL,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_22_21_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_21_EXB,
		MIN(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_22_21_CHD,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_21_CHD,

		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_23_18_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_18_DBL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_23_18_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_18_SGL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_23_18_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_18_EXB,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_23_18_CHD,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_18_CHD,

		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_23_19_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_19_DBL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_23_19_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_19_SGL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_23_19_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_19_EXB,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_23_19_CHD,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_19_CHD,

		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_23_20_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_20_DBL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_23_20_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_20_SGL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_23_20_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_20_EXB,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_23_20_CHD,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_20_CHD,

		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_23_21_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_21_DBL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_23_21_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_21_SGL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_23_21_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_21_EXB,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_23_21_CHD,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_21_CHD,

		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_23_22_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_22_DBL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_23_22_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_22_SGL,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_23_22_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_22_EXB,
		MIN(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_23_22_CHD,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_22_CHD,

		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_24_19_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_19_DBL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_24_19_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_19_SGL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_24_19_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_19_EXB,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_24_19_CHD,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_19_CHD,

		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_24_20_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_20_DBL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_24_20_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_20_SGL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_24_20_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_20_EXB,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_24_20_CHD,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_20_CHD,

		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_24_21_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_21_DBL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_24_21_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_21_SGL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_24_21_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_21_EXB,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_24_21_CHD,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_21_CHD,

		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_24_22_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_22_DBL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_24_22_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_22_SGL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_24_22_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_22_EXB,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_24_22_CHD,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_22_CHD,

		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_24_23_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_23_DBL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_24_23_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_23_SGL,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_24_23_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_23_EXB,
		MIN(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_24_23_CHD,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_23_CHD,

		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_25_20_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_20_DBL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_25_20_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_20_SGL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_25_20_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_20_EXB,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_25_20_CHD,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_20_CHD,

		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_25_21_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_21_DBL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_25_21_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_21_SGL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_25_21_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_21_EXB,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_25_21_CHD,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_21_CHD,

		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_25_22_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_22_DBL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_25_22_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_22_SGL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_25_22_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_22_EXB,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_25_22_CHD,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_22_CHD,

		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_25_23_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_23_DBL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_25_23_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_23_SGL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_25_23_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_23_EXB,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_25_23_CHD,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_23_CHD,

		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_25_24_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_24_DBL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_25_24_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_24_SGL,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_25_24_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_24_EXB,
		MIN(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_25_24_CHD,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_24_CHD,

		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_26_21_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_21_DBL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_26_21_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_21_SGL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_26_21_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_21_EXB,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_26_21_CHD,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_21_CHD,

		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_26_22_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_22_DBL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_26_22_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_22_SGL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_26_22_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_22_EXB,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_26_22_CHD,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_22_CHD,

		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_26_23_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_23_DBL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_26_23_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_23_SGL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_26_23_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_23_EXB,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_26_23_CHD,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_23_CHD,

		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_26_24_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_24_DBL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_26_24_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_24_SGL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_26_24_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_24_EXB,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_26_24_CHD,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_24_CHD,

		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_26_25_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_25_DBL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_26_25_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_25_SGL,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_26_25_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_25_EXB,
		MIN(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_26_25_CHD,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_25_CHD,

		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_27_23_DBL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_27_23_DBL,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_27_23_SGL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_27_23_SGL,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_27_23_EXB,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_27_23_EXB,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_27_23_CHD,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_27_23_CHD,

		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_27_24_DBL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_27_24_DBL,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_27_24_SGL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_27_24_SGL,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_27_24_EXB,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_27_24_EXB,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_27_24_CHD,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_27_24_CHD,

		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_27_25_DBL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_27_25_DBL,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_27_25_SGL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_27_25_SGL,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_27_25_EXB,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_27_25_EXB,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_27_25_CHD,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_27_25_CHD,

		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_27_26_DBL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_27_26_DBL,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_27_26_SGL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_27_26_SGL,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_27_26_EXB,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_27_26_EXB,
		MIN(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_27_26_CHD,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_27_26_CHD,

		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_28_24_DBL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_28_24_DBL,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_28_24_SGL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_28_24_SGL,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_28_24_EXB,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_28_24_EXB,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_28_24_CHD,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_28_24_CHD,

		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_28_25_DBL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_28_25_DBL,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_28_25_SGL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_28_25_SGL,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_28_25_EXB,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_28_25_EXB,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_28_25_CHD,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_28_25_CHD,

		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_28_26_DBL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_28_26_DBL,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_28_26_SGL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_28_26_SGL,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_28_26_EXB,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_28_26_EXB,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_28_26_CHD,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_28_26_CHD,

		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_28_27_DBL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_28_27_DBL,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_28_27_SGL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_28_27_SGL,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_28_27_EXB,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_28_27_EXB,
		MIN(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_28_27_CHD,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_28_27_CHD,

		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_29_25_DBL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_29_25_DBL,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_29_25_SGL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_29_25_SGL,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_29_25_EXB,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_29_25_EXB,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_29_25_CHD,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_29_25_CHD,

		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_29_26_DBL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_29_26_DBL,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_29_26_SGL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_29_26_SGL,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_29_26_EXB,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_29_26_EXB,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_29_26_CHD,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_29_26_CHD,

		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_29_27_DBL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_29_27_DBL,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_29_27_SGL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_29_27_SGL,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_29_27_EXB,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_29_27_EXB,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_29_27_CHD,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_29_27_CHD,

		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_29_28_DBL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_29_28_DBL,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_29_28_SGL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_29_28_SGL,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_29_28_EXB,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_29_28_EXB,
		MIN(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_29_28_CHD,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_29_28_CHD,

		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_30_26_DBL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_30_26_DBL,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_30_26_SGL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_30_26_SGL,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_30_26_EXB,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_30_26_EXB,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_30_26_CHD,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_30_26_CHD,

		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_30_27_DBL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_30_27_DBL,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_30_27_SGL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_30_27_SGL,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_30_27_EXB,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_30_27_EXB,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_30_27_CHD,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_30_27_CHD,

		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_30_28_DBL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_30_28_DBL,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_30_28_SGL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_30_28_SGL,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_30_28_EXB,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_30_28_EXB,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_30_28_CHD,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_30_28_CHD,

		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE 999999999 END ) p_30_29_DBL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_30_29_DBL,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE 999999999 END ) p_30_29_SGL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_30_29_SGL,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE 999999999 END ) p_30_29_EXB,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_30_29_EXB,
		MIN(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE 999999999 END ) p_30_29_CHD,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_30_29_CHD

FROM	dbo.mwPriceTablePax t1 with(nolock)
WHERE	
--	t1.pt_price = 
--	(
--		SELECT	MIN(pt_price)
--		FROM	dbo.mwPriceTablePax t3
--		WHERE	t1.pt_tourtype	=t3.pt_tourtype 
--			AND t1.pt_tourdate	=t3.pt_tourdate 
--			AND t1.pt_pnkey		=t3.pt_pnkey 
--			AND t1.pt_nights	=t3.pt_nights 
--			AND t1.pt_days		=t3.pt_days 
--			AND t1.pt_hdkey		=t3.pt_hdkey 
--			AND t1.pt_rckey		=t3.pt_rckey 
--			AND t1.pt_PaxColumnType	=	t3.pt_PaxColumnType
--			AND t1.pt_PaxRoomType	=	t3.pt_PaxRoomType
--			AND t3.pt_key in (select pt_key from [mwActualEnabledPriceKeys])
--	)

	t1.pt_price <= ALL
	(
		SELECT	pt_price
		FROM	dbo.[mwPriceTablePax] t3 with(nolock)
		WHERE	t1.pt_tourtype	=t3.pt_tourtype 
			AND t1.pt_tourdate	=t3.pt_tourdate 
			AND t1.pt_pnkey		=t3.pt_pnkey 
			AND t1.pt_nights	=t3.pt_nights 
			AND t1.pt_days		=t3.pt_days 
			AND t1.pt_hdkey		=t3.pt_hdkey 
			AND t1.pt_rckey		=t3.pt_rckey 
			AND t1.pt_PaxColumnType	=	t3.pt_PaxColumnType
			AND t1.pt_PaxRoomType	=	t3.pt_PaxRoomType
--			AND t3.pt_key in (select pt_key from [mwActualEnabledPriceKeys])
	)

GROUP BY 
	t1.pt_cnkey,
	t1.pt_ctkeyfrom,
	t1.pt_tourtype, 
	t1.pt_tourdate,
	t1.pt_pnkey,
	t1.pt_hdkey,
	t1.pt_rckey,
	t1.pt_PaxRoomType
GO

grant select on dbo.mwPriceTablePaxViewAsc to public
go



-- view_mwPriceTablePaxViewDesc.sql
if exists(select id from sysobjects where xtype='v' and name='mwPriceTablePaxViewDesc')
	drop view dbo.mwPriceTablePaxViewDesc
go

Create view [dbo].[mwPriceTablePaxViewDesc] as
SELECT	
		max(t1.pt_ctkey)	pt_ctkey,
		max(t1.pt_ctname)	pt_ctname,
		t1.pt_hdkey			pt_hdkey,
		max(t1.pt_hdname)	pt_hdname,
		max(t1.pt_hdstars)	pt_hdstars,
		t1.pt_pnkey			pt_pnkey,
		max(t1.pt_pncode)	pt_pncode,
		max(t1.pt_rate)		pt_rate,
		max(t1.pt_rmkey)	pt_rmkey,
		max(t1.pt_rmname)	pt_rmname,
		t1.pt_rckey			pt_rckey,
		max(t1.pt_rcname)	pt_rcname,
		t1.pt_tourdate		pt_tourdate,

		max(t1.pt_cnkey)	pt_cnkey,
		max(t1.pt_ctkeyfrom)	pt_ctkeyfrom,
		max(t1.pt_tourtype)	pt_tourtype,

		MAX(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_2_1_DBL,
		SUM(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_2_1_DBL,
		MAX(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_2_1_SGL,
		SUM(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_2_1_SGL,
		MAX(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_2_1_EXB,
		SUM(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_2_1_EXB,
		MAX(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_2_1_CHD,
		SUM(CASE WHEN (t1.pt_days=2 and t1.pt_nights=1 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_2_1_CHD,

		MAX(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_3_2_DBL,
		SUM(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_3_2_DBL,
		MAX(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_3_2_SGL,
		SUM(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_3_2_SGL,
		MAX(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_3_2_EXB,
		SUM(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_3_2_EXB,
		MAX(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_3_2_CHD,
		SUM(CASE WHEN (t1.pt_days=3 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_3_2_CHD,

		MAX(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_4_3_DBL,
		SUM(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_4_3_DBL,
		MAX(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_4_3_SGL,
		SUM(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_4_3_SGL,
		MAX(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_4_3_EXB,
		SUM(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_4_3_EXB,
		MAX(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_4_3_CHD,
		SUM(CASE WHEN (t1.pt_days=4 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_4_3_CHD,

		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_5_2_DBL,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_5_2_DBL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_5_2_SGL,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_5_2_SGL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_5_2_EXB,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_5_2_EXB,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_5_2_CHD,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_5_2_CHD,

		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_5_3_DBL,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_5_3_DBL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_5_3_SGL,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_5_3_SGL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_5_3_EXB,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_5_3_EXB,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_5_3_CHD,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_5_3_CHD,

		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_5_4_DBL,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_5_4_DBL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_5_4_SGL,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_5_4_SGL,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_5_4_EXB,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_5_4_EXB,
		MAX(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_5_4_CHD,
		SUM(CASE WHEN (t1.pt_days=5 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_5_4_CHD,

		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_6_2_DBL,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_6_2_DBL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_6_2_SGL,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_6_2_SGL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_6_2_EXB,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_6_2_EXB,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_6_2_CHD,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=2 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_6_2_CHD,

		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_6_3_DBL,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_6_3_DBL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_6_3_SGL,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_6_3_SGL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_6_3_EXB,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_6_3_EXB,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_6_3_CHD,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_6_3_CHD,

		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_6_4_DBL,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_6_4_DBL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_6_4_SGL,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_6_4_SGL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_6_4_EXB,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_6_4_EXB,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_6_4_CHD,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_6_4_CHD,

		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_6_5_DBL,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_6_5_DBL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_6_5_SGL,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_6_5_SGL,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_6_5_EXB,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_6_5_EXB,
		MAX(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_6_5_CHD,
		SUM(CASE WHEN (t1.pt_days=6 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_6_5_CHD,

		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_7_3_DBL,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_7_3_DBL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_7_3_SGL,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_7_3_SGL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_7_3_EXB,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_7_3_EXB,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_7_3_CHD,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_7_3_CHD,

		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_7_4_DBL,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_7_4_DBL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_7_4_SGL,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_7_4_SGL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_7_4_EXB,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_7_4_EXB,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_7_4_CHD,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_7_4_CHD,

		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_7_5_DBL,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_7_5_DBL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_7_5_SGL,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_7_5_SGL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_7_5_EXB,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_7_5_EXB,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_7_5_CHD,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_7_5_CHD,

		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_7_6_DBL,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_7_6_DBL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_7_6_SGL,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_7_6_SGL,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_7_6_EXB,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_7_6_EXB,
		MAX(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_7_6_CHD,
		SUM(CASE WHEN (t1.pt_days=7 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_7_6_CHD,

		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_8_3_DBL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_3_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_8_3_SGL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_3_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_8_3_EXB,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_3_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_8_3_CHD,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=3 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_3_CHD,

		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_8_4_DBL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_4_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_8_4_SGL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_4_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_8_4_EXB,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_4_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_8_4_CHD,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_4_CHD,

		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_8_5_DBL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_5_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_8_5_SGL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_5_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_8_5_EXB,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_5_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_8_5_CHD,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_5_CHD,

		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_8_6_DBL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_6_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_8_6_SGL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_6_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_8_6_EXB,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_6_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_8_6_CHD,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_6_CHD,

		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_8_7_DBL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_8_7_DBL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_8_7_SGL,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_8_7_SGL,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_8_7_EXB,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_8_7_EXB,
		MAX(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_8_7_CHD,
		SUM(CASE WHEN (t1.pt_days=8 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_8_7_CHD,

		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_9_4_DBL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_4_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_9_4_SGL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_4_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_9_4_EXB,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_4_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_9_4_CHD,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=4 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_4_CHD,

		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_9_5_DBL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_5_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_9_5_SGL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_5_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_9_5_EXB,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_5_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_9_5_CHD,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_5_CHD,

		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_9_6_DBL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_6_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_9_6_SGL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_6_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_9_6_EXB,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_6_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_9_6_CHD,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_6_CHD,

		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_9_7_DBL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_7_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_9_7_SGL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_7_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_9_7_EXB,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_7_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_9_7_CHD,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_7_CHD,

		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_9_8_DBL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_9_8_DBL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_9_8_SGL,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_9_8_SGL,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_9_8_EXB,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_9_8_EXB,
		MAX(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_9_8_CHD,
		SUM(CASE WHEN (t1.pt_days=9 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_9_8_CHD,

		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_10_5_DBL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_5_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_10_5_SGL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_5_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_10_5_EXB,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_5_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_10_5_CHD,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=5 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_5_CHD,

		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_10_6_DBL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_6_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_10_6_SGL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_6_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_10_6_EXB,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_6_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_10_6_CHD,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_6_CHD,

		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_10_7_DBL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_7_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_10_7_SGL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_7_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_10_7_EXB,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_7_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_10_7_CHD,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_7_CHD,

		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_10_8_DBL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_8_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_10_8_SGL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_8_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_10_8_EXB,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_8_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_10_8_CHD,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_8_CHD,

		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_10_9_DBL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_10_9_DBL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_10_9_SGL,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_10_9_SGL,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_10_9_EXB,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_10_9_EXB,
		MAX(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_10_9_CHD,
		SUM(CASE WHEN (t1.pt_days=10 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_10_9_CHD,

		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_11_6_DBL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_6_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_11_6_SGL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_6_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_11_6_EXB,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_6_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_11_6_CHD,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=6 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_6_CHD,

		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_11_7_DBL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_7_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_11_7_SGL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_7_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_11_7_EXB,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_7_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_11_7_CHD,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_7_CHD,

		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_11_8_DBL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_8_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_11_8_SGL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_8_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_11_8_EXB,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_8_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_11_8_CHD,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_8_CHD,

		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_11_9_DBL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_9_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_11_9_SGL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_9_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_11_9_EXB,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_9_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_11_9_CHD,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_9_CHD,

		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_11_10_DBL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_11_10_DBL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_11_10_SGL,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_11_10_SGL,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_11_10_EXB,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_11_10_EXB,
		MAX(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_11_10_CHD,
		SUM(CASE WHEN (t1.pt_days=11 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_11_10_CHD,

		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_12_7_DBL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_7_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_12_7_SGL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_7_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_12_7_EXB,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_7_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_12_7_CHD,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=7 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_7_CHD,

		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_12_8_DBL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_8_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_12_8_SGL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_8_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_12_8_EXB,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_8_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_12_8_CHD,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_8_CHD,

		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_12_9_DBL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_9_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_12_9_SGL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_9_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_12_9_EXB,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_9_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_12_9_CHD,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_9_CHD,

		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_12_10_DBL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_10_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_12_10_SGL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_10_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_12_10_EXB,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_10_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_12_10_CHD,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_10_CHD,

		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_12_11_DBL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_12_11_DBL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_12_11_SGL,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_12_11_SGL,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_12_11_EXB,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_12_11_EXB,
		MAX(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_12_11_CHD,
		SUM(CASE WHEN (t1.pt_days=12 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_12_11_CHD,

		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_13_8_DBL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_8_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_13_8_SGL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_8_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_13_8_EXB,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_8_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_13_8_CHD,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=8 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_8_CHD,

		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_13_9_DBL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_9_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_13_9_SGL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_9_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_13_9_EXB,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_9_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_13_9_CHD,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_9_CHD,

		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_13_10_DBL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_10_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_13_10_SGL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_10_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_13_10_EXB,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_10_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_13_10_CHD,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_10_CHD,

		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_13_11_DBL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_11_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_13_11_SGL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_11_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_13_11_EXB,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_11_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_13_11_CHD,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_11_CHD,

		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_13_12_DBL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_13_12_DBL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_13_12_SGL,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_13_12_SGL,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_13_12_EXB,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_13_12_EXB,
		MAX(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_13_12_CHD,
		SUM(CASE WHEN (t1.pt_days=13 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_13_12_CHD,

		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_14_9_DBL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_9_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_14_9_SGL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_9_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_14_9_EXB,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_9_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_14_9_CHD,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=9 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_9_CHD,

		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_14_10_DBL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_10_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_14_10_SGL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_10_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_14_10_EXB,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_10_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_14_10_CHD,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_10_CHD,

		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_14_11_DBL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_11_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_14_11_SGL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_11_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_14_11_EXB,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_11_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_14_11_CHD,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_11_CHD,

		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_14_12_DBL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_12_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_14_12_SGL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_12_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_14_12_EXB,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_12_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_14_12_CHD,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_12_CHD,

		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_14_13_DBL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_14_13_DBL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_14_13_SGL,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_14_13_SGL,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_14_13_EXB,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_14_13_EXB,
		MAX(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_14_13_CHD,
		SUM(CASE WHEN (t1.pt_days=14 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_14_13_CHD,

		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_15_10_DBL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_10_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_15_10_SGL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_10_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_15_10_EXB,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_10_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_15_10_CHD,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_10_CHD,

		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_15_11_DBL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_11_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_15_11_SGL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_11_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_15_11_EXB,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_11_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_15_11_CHD,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_11_CHD,

		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_15_12_DBL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_12_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_15_12_SGL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_12_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_15_12_EXB,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_12_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_15_12_CHD,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_12_CHD,

		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_15_13_DBL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_13_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_15_13_SGL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_13_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_15_13_EXB,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_13_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_15_13_CHD,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_13_CHD,

		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_15_14_DBL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_15_14_DBL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_15_14_SGL,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_15_14_SGL,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_15_14_EXB,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_15_14_EXB,
		MAX(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_15_14_CHD,
		SUM(CASE WHEN (t1.pt_days=15 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_15_14_CHD,

		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_16_10_DBL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_10_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_16_10_SGL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_10_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_16_10_EXB,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_10_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_16_10_CHD,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=10 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_10_CHD,

		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_16_11_DBL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_11_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_16_11_SGL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_11_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_16_11_EXB,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_11_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_16_11_CHD,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=11 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_11_CHD,

		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_16_12_DBL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_12_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_16_12_SGL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_12_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_16_12_EXB,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_12_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_16_12_CHD,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_12_CHD,

		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_16_13_DBL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_13_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_16_13_SGL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_13_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_16_13_EXB,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_13_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_16_13_CHD,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_13_CHD,

		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_16_14_DBL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_14_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_16_14_SGL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_14_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_16_14_EXB,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_14_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_16_14_CHD,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_14_CHD,

		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_16_15_DBL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_16_15_DBL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_16_15_SGL,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_16_15_SGL,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_16_15_EXB,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_16_15_EXB,
		MAX(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_16_15_CHD,
		SUM(CASE WHEN (t1.pt_days=16 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_16_15_CHD,

		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_17_12_DBL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_12_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_17_12_SGL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_12_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_17_12_EXB,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_12_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_17_12_CHD,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=12 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_12_CHD,

		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_17_13_DBL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_13_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_17_13_SGL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_13_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_17_13_EXB,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_13_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_17_13_CHD,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_13_CHD,

		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_17_14_DBL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_14_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_17_14_SGL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_14_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_17_14_EXB,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_14_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_17_14_CHD,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_14_CHD,

		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_17_15_DBL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_15_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_17_15_SGL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_15_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_17_15_EXB,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_15_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_17_15_CHD,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_15_CHD,

		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_17_16_DBL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_17_16_DBL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_17_16_SGL,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_17_16_SGL,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_17_16_EXB,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_17_16_EXB,
		MAX(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_17_16_CHD,
		SUM(CASE WHEN (t1.pt_days=17 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_17_16_CHD,

		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_18_13_DBL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_13_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_18_13_SGL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_13_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_18_13_EXB,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_13_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_18_13_CHD,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=13 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_13_CHD,

		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_18_14_DBL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_14_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_18_14_SGL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_14_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_18_14_EXB,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_14_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_18_14_CHD,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_14_CHD,

		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_18_15_DBL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_15_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_18_15_SGL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_15_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_18_15_EXB,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_15_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_18_15_CHD,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_15_CHD,

		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_18_16_DBL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_16_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_18_16_SGL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_16_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_18_16_EXB,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_16_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_18_16_CHD,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_16_CHD,

		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_18_17_DBL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_18_17_DBL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_18_17_SGL,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_18_17_SGL,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_18_17_EXB,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_18_17_EXB,
		MAX(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_18_17_CHD,
		SUM(CASE WHEN (t1.pt_days=18 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_18_17_CHD,

		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_19_14_DBL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_14_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_19_14_SGL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_14_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_19_14_EXB,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_14_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_19_14_CHD,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=14 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_14_CHD,

		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_19_15_DBL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_15_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_19_15_SGL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_15_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_19_15_EXB,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_15_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_19_15_CHD,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_15_CHD,

		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_19_16_DBL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_16_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_19_16_SGL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_16_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_19_16_EXB,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_16_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_19_16_CHD,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_16_CHD,

		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_19_17_DBL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_17_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_19_17_SGL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_17_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_19_17_EXB,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_17_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_19_17_CHD,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_17_CHD,

		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_19_18_DBL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_19_18_DBL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_19_18_SGL,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_19_18_SGL,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_19_18_EXB,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_19_18_EXB,
		MAX(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_19_18_CHD,
		SUM(CASE WHEN (t1.pt_days=19 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_19_18_CHD,

		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_20_15_DBL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_15_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_20_15_SGL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_15_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_20_15_EXB,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_15_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_20_15_CHD,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=15 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_15_CHD,

		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_20_16_DBL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_16_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_20_16_SGL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_16_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_20_16_EXB,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_16_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_20_16_CHD,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_16_CHD,

		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_20_17_DBL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_17_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_20_17_SGL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_17_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_20_17_EXB,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_17_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_20_17_CHD,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_17_CHD,

		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_20_18_DBL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_18_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_20_18_SGL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_18_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_20_18_EXB,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_18_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_20_18_CHD,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_18_CHD,

		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_20_19_DBL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_20_19_DBL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_20_19_SGL,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_20_19_SGL,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_20_19_EXB,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_20_19_EXB,
		MAX(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_20_19_CHD,
		SUM(CASE WHEN (t1.pt_days=20 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_20_19_CHD,

		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_21_16_DBL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_16_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_21_16_SGL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_16_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_21_16_EXB,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_16_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_21_16_CHD,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=16 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_16_CHD,

		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_21_17_DBL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_17_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_21_17_SGL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_17_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_21_17_EXB,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_17_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_21_17_CHD,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_17_CHD,

		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_21_18_DBL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_18_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_21_18_SGL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_18_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_21_18_EXB,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_18_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_21_18_CHD,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_18_CHD,

		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_21_19_DBL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_19_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_21_19_SGL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_19_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_21_19_EXB,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_19_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_21_19_CHD,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_19_CHD,

		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_21_20_DBL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_21_20_DBL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_21_20_SGL,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_21_20_SGL,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_21_20_EXB,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_21_20_EXB,
		MAX(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_21_20_CHD,
		SUM(CASE WHEN (t1.pt_days=21 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_21_20_CHD,

		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_22_17_DBL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_17_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_22_17_SGL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_17_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_22_17_EXB,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_17_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_22_17_CHD,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=17 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_17_CHD,

		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_22_18_DBL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_18_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_22_18_SGL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_18_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_22_18_EXB,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_18_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_22_18_CHD,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_18_CHD,

		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_22_19_DBL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_19_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_22_19_SGL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_19_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_22_19_EXB,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_19_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_22_19_CHD,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_19_CHD,

		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_22_20_DBL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_20_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_22_20_SGL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_20_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_22_20_EXB,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_20_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_22_20_CHD,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_20_CHD,

		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_22_21_DBL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_22_21_DBL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_22_21_SGL,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_22_21_SGL,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_22_21_EXB,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_22_21_EXB,
		MAX(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_22_21_CHD,
		SUM(CASE WHEN (t1.pt_days=22 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_22_21_CHD,

		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_23_18_DBL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_18_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_23_18_SGL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_18_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_23_18_EXB,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_18_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_23_18_CHD,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=18 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_18_CHD,

		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_23_19_DBL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_19_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_23_19_SGL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_19_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_23_19_EXB,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_19_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_23_19_CHD,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_19_CHD,

		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_23_20_DBL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_20_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_23_20_SGL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_20_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_23_20_EXB,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_20_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_23_20_CHD,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_20_CHD,

		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_23_21_DBL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_21_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_23_21_SGL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_21_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_23_21_EXB,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_21_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_23_21_CHD,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_21_CHD,

		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_23_22_DBL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_23_22_DBL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_23_22_SGL,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_23_22_SGL,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_23_22_EXB,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_23_22_EXB,
		MAX(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_23_22_CHD,
		SUM(CASE WHEN (t1.pt_days=23 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_23_22_CHD,

		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_24_19_DBL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_19_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_24_19_SGL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_19_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_24_19_EXB,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_19_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_24_19_CHD,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=19 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_19_CHD,

		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_24_20_DBL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_20_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_24_20_SGL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_20_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_24_20_EXB,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_20_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_24_20_CHD,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_20_CHD,

		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_24_21_DBL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_21_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_24_21_SGL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_21_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_24_21_EXB,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_21_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_24_21_CHD,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_21_CHD,

		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_24_22_DBL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_22_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_24_22_SGL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_22_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_24_22_EXB,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_22_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_24_22_CHD,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_22_CHD,

		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_24_23_DBL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_24_23_DBL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_24_23_SGL,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_24_23_SGL,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_24_23_EXB,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_24_23_EXB,
		MAX(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_24_23_CHD,
		SUM(CASE WHEN (t1.pt_days=24 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_24_23_CHD,

		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_25_20_DBL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_20_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_25_20_SGL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_20_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_25_20_EXB,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_20_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_25_20_CHD,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=20 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_20_CHD,

		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_25_21_DBL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_21_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_25_21_SGL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_21_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_25_21_EXB,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_21_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_25_21_CHD,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_21_CHD,

		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_25_22_DBL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_22_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_25_22_SGL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_22_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_25_22_EXB,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_22_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_25_22_CHD,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_22_CHD,

		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_25_23_DBL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_23_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_25_23_SGL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_23_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_25_23_EXB,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_23_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_25_23_CHD,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_23_CHD,

		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_25_24_DBL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_25_24_DBL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_25_24_SGL,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_25_24_SGL,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_25_24_EXB,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_25_24_EXB,
		MAX(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_25_24_CHD,
		SUM(CASE WHEN (t1.pt_days=25 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_25_24_CHD,

		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_26_21_DBL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_21_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_26_21_SGL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_21_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_26_21_EXB,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_21_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_26_21_CHD,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=21 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_21_CHD,

		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_26_22_DBL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_22_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_26_22_SGL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_22_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_26_22_EXB,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_22_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_26_22_CHD,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=22 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_22_CHD,

		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_26_23_DBL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_23_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_26_23_SGL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_23_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_26_23_EXB,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_23_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_26_23_CHD,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_23_CHD,

		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_26_24_DBL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_24_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_26_24_SGL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_24_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_26_24_EXB,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_24_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_26_24_CHD,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_24_CHD,

		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_26_25_DBL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_26_25_DBL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_26_25_SGL,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_26_25_SGL,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_26_25_EXB,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_26_25_EXB,
		MAX(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_26_25_CHD,
		SUM(CASE WHEN (t1.pt_days=26 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_26_25_CHD,

		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_27_23_DBL,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_27_23_DBL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_27_23_SGL,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_27_23_SGL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_27_23_EXB,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_27_23_EXB,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_27_23_CHD,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=23 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_27_23_CHD,

		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_27_24_DBL,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_27_24_DBL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_27_24_SGL,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_27_24_SGL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_27_24_EXB,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_27_24_EXB,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_27_24_CHD,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_27_24_CHD,

		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_27_25_DBL,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_27_25_DBL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_27_25_SGL,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_27_25_SGL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_27_25_EXB,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_27_25_EXB,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_27_25_CHD,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_27_25_CHD,

		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_27_26_DBL,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_27_26_DBL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_27_26_SGL,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_27_26_SGL,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_27_26_EXB,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_27_26_EXB,
		MAX(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_27_26_CHD,
		SUM(CASE WHEN (t1.pt_days=27 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_27_26_CHD,

		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_28_24_DBL,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_28_24_DBL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_28_24_SGL,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_28_24_SGL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_28_24_EXB,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_28_24_EXB,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_28_24_CHD,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=24 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_28_24_CHD,

		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_28_25_DBL,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_28_25_DBL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_28_25_SGL,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_28_25_SGL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_28_25_EXB,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_28_25_EXB,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_28_25_CHD,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_28_25_CHD,

		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_28_26_DBL,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_28_26_DBL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_28_26_SGL,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_28_26_SGL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_28_26_EXB,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_28_26_EXB,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_28_26_CHD,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_28_26_CHD,

		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_28_27_DBL,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_28_27_DBL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_28_27_SGL,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_28_27_SGL,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_28_27_EXB,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_28_27_EXB,
		MAX(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_28_27_CHD,
		SUM(CASE WHEN (t1.pt_days=28 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_28_27_CHD,

		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_29_25_DBL,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_29_25_DBL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_29_25_SGL,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_29_25_SGL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_29_25_EXB,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_29_25_EXB,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_29_25_CHD,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=25 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_29_25_CHD,

		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_29_26_DBL,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_29_26_DBL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_29_26_SGL,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_29_26_SGL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_29_26_EXB,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_29_26_EXB,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_29_26_CHD,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_29_26_CHD,

		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_29_27_DBL,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_29_27_DBL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_29_27_SGL,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_29_27_SGL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_29_27_EXB,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_29_27_EXB,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_29_27_CHD,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_29_27_CHD,

		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_29_28_DBL,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_29_28_DBL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_29_28_SGL,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_29_28_SGL,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_29_28_EXB,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_29_28_EXB,
		MAX(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_29_28_CHD,
		SUM(CASE WHEN (t1.pt_days=29 and t1.pt_nights=28 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_29_28_CHD,

		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_30_26_DBL,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_30_26_DBL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_30_26_SGL,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_30_26_SGL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_30_26_EXB,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_30_26_EXB,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_30_26_CHD,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=26 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_30_26_CHD,

		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_30_27_DBL,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_30_27_DBL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_30_27_SGL,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_30_27_SGL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_30_27_EXB,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_30_27_EXB,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_30_27_CHD,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=27 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_30_27_CHD,

		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_30_28_DBL,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_30_28_DBL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_30_28_SGL,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_30_28_SGL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_30_28_EXB,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_30_28_EXB,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_30_28_CHD,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=28 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_30_28_CHD,

		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 1) THEN t1.pt_price ELSE -999999999 END ) p_30_29_DBL,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 1) THEN t1.pt_key ELSE 0 END) pk_30_29_DBL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 2) THEN t1.pt_price ELSE -999999999 END ) p_30_29_SGL,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 2) THEN t1.pt_key ELSE 0 END) pk_30_29_SGL,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 3) THEN t1.pt_price ELSE -999999999 END ) p_30_29_EXB,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 3) THEN t1.pt_key ELSE 0 END) pk_30_29_EXB,
		MAX(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 4) THEN t1.pt_price ELSE -999999999 END ) p_30_29_CHD,
		SUM(CASE WHEN (t1.pt_days=30 and t1.pt_nights=29 and t1.pt_PaxColumnType = 4) THEN t1.pt_key ELSE 0 END) pk_30_29_CHD

FROM	dbo.mwPriceTablePax t1
WHERE	
--	t1.pt_price = 
--	(
--		SELECT	MIN(pt_price)
--		FROM	dbo.mwPriceTablePax t3
--		WHERE	t1.pt_tourtype	=t3.pt_tourtype 
--			AND t1.pt_tourdate	=t3.pt_tourdate 
--			AND t1.pt_pnkey		=t3.pt_pnkey 
--			AND t1.pt_nights	=t3.pt_nights 
--			AND t1.pt_days		=t3.pt_days 
--			AND t1.pt_hdkey		=t3.pt_hdkey 
--			AND t1.pt_rckey		=t3.pt_rckey 
--			AND t1.pt_PaxColumnType	=	t3.pt_PaxColumnType
--			AND t1.pt_PaxRoomType	=	t3.pt_PaxRoomType
--			AND t3.pt_key in (select pt_key from [mwActualEnabledPriceKeys])
--	)
	t1.pt_price <= ALL
	(
		SELECT	pt_price
		FROM	dbo.mwPriceTablePax t3 with(nolock)
		WHERE	t1.pt_tourtype	=t3.pt_tourtype 
			AND t1.pt_tourdate	=t3.pt_tourdate 
			AND t1.pt_pnkey		=t3.pt_pnkey 
			AND t1.pt_nights	=t3.pt_nights 
			AND t1.pt_days		=t3.pt_days 
			AND t1.pt_hdkey		=t3.pt_hdkey 
			AND t1.pt_rckey		=t3.pt_rckey 
			AND t1.pt_PaxColumnType	=	t3.pt_PaxColumnType
			AND t1.pt_PaxRoomType	=	t3.pt_PaxRoomType
--			AND t3.pt_key in (select pt_key from [mwActualEnabledPriceKeys])
	)
GROUP BY 
	t1.pt_tourtype, 
	t1.pt_tourdate,
	t1.pt_pnkey,
	t1.pt_hdkey,
	t1.pt_rckey,
	t1.pt_PaxRoomType
GO

grant select on dbo.mwPriceTablePaxViewDesc to public
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

	declare @mwSinglePrice nvarchar(10)
	select @mwSinglePrice = ltrim(isnull(ss_parmvalue, N'0'))
	from dbo.SystemSettings
	where ss_parmname = 'mwSinglePrice'

	if(@mwSinglePrice != '0')
	begin
		declare @mwSinglePriceType nvarchar(10)
		select @mwSinglePriceType = lower(ltrim(isnull(ss_parmvalue, N'last')))
		from dbo.SystemSettings
		where ss_parmname = 'mwSinglePriceType' -- 'last' or 'min'

		declare @mwSinglePriceAllTours nvarchar(10)
		select @mwSinglePriceAllTours = ltrim(isnull(ss_parmvalue, N'0'))
		from dbo.SystemSettings
		where ss_parmname = 'mwSinglePriceAllTours' -- single price for tour

		declare @mwSinglePriceAllHotelPrt nvarchar(10)
		select @mwSinglePriceAllHotelPrt = ltrim(isnull(ss_parmvalue, N'0'))
		from dbo.SystemSettings
		where ss_parmname = 'mwSinglePriceAllHotelPrt' -- single price for hotel partner

		declare @mwSinglePriceAllFlightPrt nvarchar(10)
		select @mwSinglePriceAllFlightPrt = ltrim(isnull(ss_parmvalue, N'0'))
		from dbo.SystemSettings
		where ss_parmname = 'mwSinglePriceAllFlightPrt' -- single price for flight partner

		declare @mwSinglePriceAllTourTypes nvarchar(10)
		select @mwSinglePriceAllTourTypes = ltrim(isnull(ss_parmvalue, N'0'))
		from dbo.SystemSettings
		where ss_parmname = 'mwSinglePriceAllTourTypes' -- single price for tour type

		declare @mwSinglePriceAllDeparts nvarchar(10)
		select @mwSinglePriceAllDeparts = ltrim(isnull(ss_parmvalue, N'1'))
		from dbo.SystemSettings
		where ss_parmname = 'mwSinglePriceAllDeparts' -- single price for depart from
	end

	declare @sql varchar(8000)
	declare @cityFromKey int
	declare @countryKey int

	declare @mwSearchType int
	select @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
	where SS_ParmName = 'MWDivideByCountry'

	select @countryKey = sd_cnkey, @cityFromKey = sd_ctkeyfrom from dbo.mwSpoDataTable where sd_tourkey = @tourkey 
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

					set @sql = '
			update ' + @tableName + ' with(rowlock)
			set pt_isenabled = 0 ' + @sqlWhere

					print @sql
					exec(@sql) -- turn off max or old prices for main places

				

			end -- if(@enabled > 0 and @mwSinglePriceAllTours != '0')
		end -- if(@mwSinglePrice != '0')

		set @sql = '
		update ' + @tableName + ' with(rowlock)
		set pt_isenabled = ' + CAST(@enabled as varchar) + '
		where pt_tourdate >= getdate() and pt_tourkey = ' + CAST(@tourkey as varchar)

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

		if(@enabled > 0)
		begin
			if (@mwSinglePrice != '0')
			begin
				-- enable all new prices for extra places for which exist new prices for main places (in the new tour)
				set @sql = '
				update ' + @tableName + ' with(rowlock)
				set pt_isenabled = ' + CAST(@enabled as varchar) + '
				where pt_tourkey = ' + CAST(@tourkey as varchar) + '
				and pt_tourdate >= getdate()
				and isnull(pt_main, 0) <= 0 and exists(
				select 1 from ' + @tableName + ' pt with(nolock)
				where pt.pt_tourkey = ' + CAST(@tourkey as varchar) + ' and
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
				set pt_isenabled = 0
				where pt_tourkey != ' + CAST(@tourkey as varchar) + '
				and pt_tourdate >= getdate()
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
	end
	
	update dbo.mwSpoDataTable with (rowlock)
	set sd_isenabled = 0
	where exists (select 1 from #tmpTours where sd_tourkey = tourkey) and not exists(select 1 from dbo.mwPriceTable
		where pt_cnkey = sd_cnkey
			and pt_ctkeyfrom = sd_ctkeyfrom
			and pt_tourkey = sd_tourkey
			and pt_hdkey = sd_hdkey
			and pt_pnkey = sd_pnkey
			and exists (select 1 from #tmpTours where pt_tourkey = tourkey))

	update dbo.mwSpoDataTable set sd_isenabled = @enabled where sd_tourkey = @tourkey
end
go

grant exec on dbo.mwEnablePriceTour to public
go

-- sp_FillMasterWebSearchFields.sql
if exists(select id from sysobjects where xtype='p' and name='FillMasterWebSearchFields')
	drop proc dbo.FillMasterWebSearchFields
go

create procedure [dbo].[FillMasterWebSearchFields](@tokey int, @add smallint = null, @forceEnable smallint = null)
-- if @forceEnable > 0 (by default) then make call mwEnablePriceTour @tokey, 1 at the end of the procedure
as
begin
	set @forceEnable = isnull(@forceEnable, 1)

	declare @replicationSetting nvarchar(254)
	select @replicationSetting = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSUseWebReplication'
	if IsNull(@replicationSetting, '0') = '1'
	begin
		update dbo.TP_Tours set TO_Update = 0, TO_Progress = 100, TO_UpdateTime = GetDate() where TO_Key = @tokey
		return
	end

	if @tokey is null
	begin
		print 'Procedure does not support NULL param'
		return
	end

	update dbo.TP_Tours set TO_Update = 1, TO_Progress = 0 where TO_Key = @tokey
	update CalculatingPriceLists with(rowlock) set CP_Status = 1 where CP_PriceTourKey = @tokey

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
		insert into #tmpPrices 
			select tp_key, tp_tikey 
			from tp_prices
			where tp_tokey = @toKey and tp_dateend >= getdate()  
					 and not exists 
					(select 1 from mwPriceDataTable with(nolock)
					where pt_tourkey = @toKey  and pt_pricekey = tp_key)
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

	update dbo.TP_Tours set TO_Progress = 7 where TO_Key = @tokey

	update TP_Tours set TO_MinPrice = (
			select min(TP_Gross) 
			from TP_Prices 
				left join TP_Lists on ti_key = tp_tikey
				left join HotelRooms on hr_key = ti_firsthrkey
				
			where TP_TOKey = TO_Key and hr_main > 0 and isnull(HR_AGEFROM, 100) > 16
		)
		where TO_Key = @toKey


	update dbo.TP_Tours set TO_Progress = 13 where TO_Key = @tokey

	update tp_lists with(rowlock)
	set
		ti_lasthotelday = (select max(ts_day)
				from tp_servicelists  with (nolock)
					inner join tp_services with (nolock) on tl_tskey = ts_key
				where tl_tikey = ti_key and ts_svkey = 3)
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours set TO_Progress = 20 where TO_Key = @tokey

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

	update dbo.TP_Tours set TO_Progress = 30 where TO_Key = @tokey

	update tp_lists with(rowlock)
	set
	-- MEG00024548 Paul G 11.01.2009
	-- изменил логику подсчёта кол-ва ночей в туре
	-- раньше было сумма ночей проживания по всем отелям в туре
	-- теперь если проживания пересекаются, лишние ночи не суммируются
		ti_nights = dbo.mwGetTiNights(ti_key)
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update TP_Tours set TO_HotelNights = dbo.mwTourHotelNights(TO_Key) where TO_Key = @toKey

	update dbo.TP_Tours set TO_Progress = 40 where TO_Key = @tokey

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
	from	tp_tours
		inner join tbl_turList on tbl_turList.tl_key = to_trkey
	where to_key = @tokey

	if (@ctdeparturekey is null or @ctdeparturekey = 0)
	begin
		-- Подбираем город вылета первого рейса
		exec GetCityDepartureKey @tokey, @ctdeparturekey output
	end

	-- город вылета
	update tp_lists
	set 
		ti_chkey = (select top 1 ts_code
			from tp_servicelists 
				inner join tp_services on tl_tskey = ts_key and ts_svkey = 1
			where tl_tikey = ti_key and ts_day <= tp_lists.ti_firsthotelday and ts_subcode2 = @ctdeparturekey)
	where ti_tokey = @tokey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours set TO_Progress = 50 where TO_Key = @tokey

	-- город вылета + прямой перелет
	update tp_lists
	set 
		ti_chday = ts_day,
		ti_chpkkey = ts_oppacketkey,
		ti_chprkey = ts_oppartnerkey
    from tp_servicelists with(nolock) inner join tp_services with(nolock) on tl_tskey = ts_key and ts_svkey = 1
	where	tl_tikey = ti_key 
		and ts_day <= tp_lists.ti_firsthotelday 
		and ts_code = ti_chkey 
		and ts_subcode2 = @ctdeparturekey
		and ti_tokey = @tokey 
		and tl_tokey = @tokey 
		and ts_tokey = @tokey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update tp_lists
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
		inner join tp_tours on ts_tokey = to_key 
		inner join tbl_turList on tbl_turList.tl_key = to_trkey
	where	ts_tokey = @tokey
		and	ts_svkey = 1
		and ts_ctkey = tl_ctdeparturekey

	-- город прилета + обратный перелет
	update tp_lists 
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
		ti_apkeyfrom = (select top 1 ap_key from airport, charter 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chkey)
	where
		ti_tokey = @toKey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	-- _ключ_ аэропорта прилета
	update tp_lists with(rowlock)
	set 
		ti_apkeyto = (select top 1 ap_key from airport, charter 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chbackkey)
	where
		ti_tokey = @toKey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	-- ключ города и ключ курорта + звезды
	update tp_lists
	set
		ti_firstctkey = hd_ctkey,
		ti_firstrskey = hd_rskey,
		ti_firsthdstars = hd_stars
	from hoteldictionary with(nolock)
	where 
		ti_tokey = @toKey and
		ti_firsthdkey = hd_key
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours set TO_Progress = 60 where TO_Key = @tokey

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

	update #tmpHotelData set thd_hdorder = (select min(ts_day) from tp_services where ts_tokey = thd_tourkey and ts_svkey = 3 and ts_code = thd_hdkey)
	update #tmpHotelData set thd_rsname = rs_name from resorts where rs_key = thd_rskey
	update #tmpHotelData set thd_ctfromname = ct_name from citydictionary where ct_key = thd_ctkeyfrom
	update #tmpHotelData set thd_ctfromname = '-Без перелета-' where thd_ctkeyfrom = 0
	update #tmpHotelData set thd_cttoname = ct_name from citydictionary where ct_key = thd_ctkeyto
	update #tmpHotelData set thd_cttoname = '-Без перелета-' where thd_ctkeyto = 0
	--

	update dbo.TP_Tours set TO_Progress = 70 where TO_Key = @tokey

	select @mwAccomodationPlaces = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
	where SS_ParmName = 'MWAccomodationPlaces'

	select @mwRoomsExtraPlaces = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
	where SS_ParmName = 'MWRoomsExtraPlaces'

	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings 
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
	from tp_lists
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

	update dbo.TP_Tours set TO_Progress = 80 where TO_Key = @tokey

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
	from tp_lists with(nolock) inner join tp_tours with(nolock) on ti_tokey = to_key
	where ti_tokey = @toKey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	-- Даты в поисковой таблице ставим как в таблице туров - чтобы не было двоений MEG00021274
	update mwspodatatable with(rowlock) set sd_tourcreated = to_datecreated from tp_tours where sd_tourkey = to_key and to_key = @tokey

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
	insert into mwSpoDataTable(
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
		from mwSpoDataTable mwsdt
		where mwsdt.sd_tourkey = mwPriceHotels.sd_tourkey and mwsdt.sd_hdkey = mwPriceHotels.sd_mainhdkey
			and mwsdt.sd_tourkey = @tokey
			and mwPriceHotels.sd_tourkey = @tokey

	-- Указываем на необходимость обновления в таблице минимальных цен отеля
	update mwHotelDetails
		set htd_needupdate = 1
		where htd_hdkey in (select thd_hdkey from #tmpHotelData)

	if(@forceEnable > 0)
		exec dbo.mwEnablePriceTour @tokey, 1

	update CalculatingPriceLists with(rowlock) set CP_Status = 0 where CP_PriceTourKey = @tokey
	update dbo.TP_Tours set TO_Update = 0, TO_Progress = 100, TO_DateCreated = GetDate(), TO_UpdateTime = GetDate() where TO_Key = @tokey
end

go

grant exec on dbo.FillMasterWebSearchFields to public
go

-- sp_GetQuotaLoadListData_N.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetQuotaLoadListData_N]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetQuotaLoadListData_N] 
GO
create procedure [dbo].[GetQuotaLoadListData_N]
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

	if exists (select 1 from dbo.Service where SV_Key=@Service_SVKey and SV_IsDuration=1)
		set @DurationLocal=@ServiceLong
	Else
		set @DurationLocal=@TourDurations
END

--DECLARE @StopSaleTemp TABLE
--(
--SST_QDID int, SST_QO_Count smallint, SST_QO_CountWithStop smallint, SST_Comment varchar(255)
--)
-- Для совместимости с MSSQL 2000
CREATE TABLE #StopSaleTemp
(
SST_QDID int, SST_QO_Count smallint, SST_QO_CountWithStop smallint, SST_Comment varchar(255)
)

INSERT INTO #StopSaleTemp exec dbo.GetTableQuotaDetails	@DLKey, null, @DateStart, @DaysCount, null, null, @Service_SVKey, @Service_Code, null, null, 1

/*
select * from quotas,quotaobjects,quotadetails where 
qt_id=qo_qtid and qd_qtid=qt_id
and qo_code=8439 and qo_svkey=1 and QO_QTID is not null
and ISNULL(QD_IsDeleted,0)=0
and QD_Date between @DateStart and DATEADD(DAY,@DaysCount,@DateStart)
*/
CREATE TABLE #QuotaLoadList(
QL_QTID int, QL_PRKey int, QL_SubCode1 int, QL_PartnerName nvarchar(100) collate Cyrillic_General_CI_AS, QL_Description nvarchar(255) collate Cyrillic_General_CI_AS, 
QL_dataType smallint, QL_Type smallint, QL_Release int, QL_Durations nvarchar(20) collate Cyrillic_General_CI_AS, QL_FilialKey int, 
QL_CityDepartments int, QL_AgentKey int, QL_CustomerInfo nvarchar(150) collate Cyrillic_General_CI_AS, QL_DateCheckinMin smalldatetime,
QL_ByRoom int)

DECLARE @n int, @str varchar(1000)
if @ResultType is null or @ResultType not in (10)
BEGIN
	set @n=1
	WHILE @n <= @DaysCount
	BEGIN
		set @str = 'ALTER TABLE #QuotaLoadList ADD QL_' + CAST(@n as varchar(3)) + ' varchar(8000)'
		--, QL_B_' + CAST(@n as varchar(3)) + ' varchar(8000)'
		--, QL_F_' + CAST(@n as varchar(3)) + ' varchar(8000)
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
		FROM	DogovorList
		WHERE	DL_Key=@DLKey
		If @Service_SVKey=3
			SELECT @Object_SubCode1=HR_RMKey, @Object_SubCode2=HR_RCKey 
			FROM dbo.HotelRooms WHERE HR_Key=@Service_SubCode1
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
END	
	insert into #QuotaLoadList 
		(QL_QTID, QL_Type, QL_Release, QL_dataType, 
		QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	select DISTINCT QT_ID, QD_Type, QD_Release, NU_ID, 
		QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, '', @DateEnd+1,QT_PRKey,QT_ByRoom
	from	Quotas, QuotaObjects, QuotaDetails, QuotaParts, Numbers
	where	QT_ID=QO_QTID and QD_QTID=QT_ID and QP_QDID = QD_ID 
			and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) and QD_Date between @DateStart and @DateEnd
			and (QP_AgentKey is null or (@bShowAgencyInfo=1 and ((@AgentKey=QP_AgentKey) or (@AgentKey is null))))
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey=QT_PRKey or QT_PRKey=0)))
			and (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select QL_QPID From QuotaLimitations WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID))))
			and ISNULL(QP_IsDeleted,0)=0
			and ISNULL(QD_IsDeleted,0)=0
			and NU_ID between @Result_From and @Result_To
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
			if Exists (SELECT 1 FROM #StopSaleTemp WHERE SST_QDID = @QD_ID )
				SELECT @StopSale_Percent = 100*SST_QO_Count/SST_QO_CountWithStop, @Stop_Comment = SST_Comment FROM #StopSaleTemp WHERE SST_QDID = @QD_ID
		END
		ELSE
		BEGIN
			if Exists (SELECT 1 FROM #StopSaleTemp WHERE SST_QDID = @QD_ID )
				SELECT @StopSale_Percent = 100, @Stop_Comment = SST_Comment FROM #StopSaleTemp WHERE SST_QDID = @QD_ID
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
	from	DogovorList,ServiceByDate
	where	SD_DLKey=DL_Key
			and DL_SVKey=@Service_SVKey and DL_Code=@Service_Code and ((DL_DateBeg between @DateStart and @DateEnd) or (DL_DateEnd between @DateStart and @DateEnd))
			and SD_Date<=@DateEnd and SD_Date>=@DateStart
			and SD_State not in (1,2)
	group by SD_Date,DL_SubCode1,DL_PartnerKey,SD_State
END

update #QuotaLoadList set QL_CustomerInfo = (Select PR_Name from Partners where PR_Key = QL_AgentKey and QL_AgentKey > 0)
update #QuotaLoadList set QL_PartnerName = (Select PR_Name from Partners where PR_Key = QL_PRKey and QL_PRKey > 0)
update #QuotaLoadList set QL_PartnerName = 'All partners' where QL_PRKey=0

IF @DLKey is null and @QT_ID is null and (@ResultType is null or @ResultType not in (10))
BEGIN
	DECLARE @ServiceCount int, @SubCode1 int, @PartnerKey int

	DECLARE curQServiceList CURSOR FOR SELECT
		SD_Date, CASE @ByRoom WHEN 1 THEN count(distinct SD_RLID) ELSE count(SD_ID) END, 
		DL_SubCode1, DL_PartnerKey, SD_State
		from	DogovorList,ServiceByDate
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
	SELECT DISTINCT QO_QTID, QO_SubCode1, 1, null FROM QuotaObjects WHERE QO_QTID in (SELECT DISTINCT QL_QTID FROM #QuotaLoadList) and QO_QTID is not null
	UNION
	SELECT DISTINCT QO_QTID, QO_SubCode2, 2, null FROM QuotaObjects WHERE QO_QTID in (SELECT DISTINCT QL_QTID FROM #QuotaLoadList) and QO_QTID is not null
	UNION
	SELECT DISTINCT null, null, null, QL_SubCode1 FROM #QuotaLoadList WHERE QL_SubCode1 is not null
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
	from #QuotaLoadList 
	order by QL_QTID-QL_QTID DESC /*Сначала квоты, потом неквоты*/,QL_Description,QL_PartnerName,QL_Type DESC,QL_Release,QL_Durations,QL_CityDepartments,QL_FilialKey,QL_CustomerInfo,QL_QTID,QL_DataType
	RETURN 0
END
ELSE
BEGIN --для наличия мест(из оформления)
	CREATE TABLE #ServicePlacesTr(
		SPT_QTID int, SPT_PRKey int, SPT_SubCode1 int, SPT_PartnerName varchar(100), SPT_Description varchar(255), 
		SPT_Type smallint, SPT_FilialKey int, SPT_CityDepartments int, SPT_Release int, SPT_Durations varchar(100),
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
				(SPT_QTID, SPT_PRKey,SPT_SubCode1,SPT_PartnerName,SPT_Description,SPT_Type,
				SPT_FilialKey,SPT_CityDepartments,SPT_Release,SPT_Durations,SPT_AgentKey,
				SPT_Date,SPT_Places) 
			SELECT QL_QTID, QL_PRKey,QL_SubCode1,QL_PartnerName, QL_Description, QL_Type, 
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

CREATE TABLE #ServicePlaces(
	SP_PRKey int, SP_SubCode1 int, SP_PartnerName varchar(100), SP_Description varchar(255), 
	SP_Type smallint, SP_FilialKey int, SP_CityDepartments int, 
	SP_Places1 smallint, SP_Places2 smallint, SP_Places3 smallint, 
	SP_NonReleasePlaces1 smallint,SP_NonReleasePlaces2 smallint,SP_NonReleasePlaces3 smallint, 
	SP_StopPercent1 smallint,SP_StopPercent2 smallint,SP_StopPercent3 smallint)

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
		INSERT INTO #ServicePlaces (SP_PRKey, SP_SubCode1, SP_PartnerName, SP_Description, SP_Type, 
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
		INSERT INTO #ServicePlaces (SP_PRKey, SP_SubCode1, SP_PartnerName, SP_Description, SP_Type, 
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
	from #ServicePlaces
	order by SP_Description, SP_PartnerName, SP_Type

GO

GRANT EXECUTE ON [dbo].[GetQuotaLoadListData_N] TO PUBLIC 
GO



-- 100225_CreateTable_CostOffers.sql
if not exists (select 1 from sysobjects where id = object_id(N'[dbo].[Seasons]') and xtype = 'U')
CREATE TABLE [dbo].[Seasons]
(
	[SN_Id] [int] IDENTITY(1,1) NOT NULL,
	[SN_Name] [nvarchar](255) NOT NULL,
	[SN_NameLat] [nvarchar](255) NOT NULL,
	[SN_IsActive] [bit] NOT NULL CONSTRAINT [DF_Seasons_IsActive] DEFAULT ((0)),
	[SN_CreateDate] [datetime] NOT NULL CONSTRAINT [DF_Seasons_CreateDate] DEFAULT (getdate())
	CONSTRAINT [PK_Seasons] PRIMARY KEY CLUSTERED 
	(
		[SN_Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists (select 1 from sysobjects where id = object_id(N'[dbo].[CostOfferTypes]') and xtype = 'U')
CREATE TABLE [dbo].[CostOfferTypes]
(
	[COT_Id] [int] NOT NULL,
	[COT_Name] [nvarchar](20) NOT NULL,
	[COT_NameLat] [nvarchar](20) NOT NULL,
	CONSTRAINT [PK_CostOfferTypes] PRIMARY KEY CLUSTERED 
	(
		[COT_Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists (select 1 from sysobjects where id = object_id(N'[dbo].[CostOffers]') and xtype = 'U')
CREATE TABLE [dbo].[CostOffers]
(
	[CO_Id] [int] IDENTITY(1,1) NOT NULL,
	[CO_Name] [nvarchar](255) NOT NULL,
	[CO_NameLat] [nvarchar](255) NOT NULL,
	[CO_PartnerId] [int] NOT NULL,
	[CO_Comment] [nvarchar](1024) NULL,
	[CO_SaleDateBeg] [smalldatetime] NULL,
	[CO_SaleDateEnd] [smalldatetime] NULL,
	[CO_CreateDate] [datetime] NOT NULL CONSTRAINT [DF_CostOffers_CreateDate] DEFAULT (getdate()),
	[CO_TypeId] [int] NOT NULL,
	[CO_SeasonId] [int] NULL,
	[CO_IsRules] [bit] NOT NULL CONSTRAINT [DF_CostOffers_IsRules] DEFAULT (0),
	CONSTRAINT [PK_CostOffers] PRIMARY KEY CLUSTERED 
	(
		[CO_Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists (select 1 from sysobjects where name = 'FK_CostOffers_Seasons')
ALTER TABLE [dbo].[CostOffers] WITH CHECK 
	ADD CONSTRAINT [FK_CostOffers_Seasons] FOREIGN KEY([CO_SeasonId])
	REFERENCES [dbo].[Seasons] ([SN_Id])
GO

if not exists (select 1 from sysobjects where name = 'FK_CostOffers_CostOfferTypes')
ALTER TABLE [dbo].[CostOffers] WITH CHECK 
	ADD CONSTRAINT [FK_CostOffers_CostOfferTypes] FOREIGN KEY([CO_TypeId])
	REFERENCES [dbo].[CostOfferTypes] ([COT_Id])
GO

if not exists (select 1 from sysobjects where name = 'FK_CostOffers_Partners')
ALTER TABLE [dbo].[CostOffers] WITH CHECK 
	ADD CONSTRAINT [FK_CostOffers_Partners] FOREIGN KEY([CO_PartnerId])
	REFERENCES [dbo].[tbl_Partners] ([PR_Key])
GO

if not exists (select 1 from sysobjects where id = object_id(N'[dbo].[XYRules]') and xtype = 'U')
CREATE TABLE [dbo].[XYRules](
	[XY_Id] [int] IDENTITY(1,1) NOT NULL,
	[XY_XFrom] [smallint] NOT NULL,
	[XY_XTo] [smallint] NOT NULL,
	[XY_Sign] [nchar](1) NOT NULL,
	[XY_Y] [smallint] NOT NULL,
	[XY_CostOfferId] [int] NOT NULL,
	CONSTRAINT [PK_XYRules] PRIMARY KEY CLUSTERED 
	(
		[XY_Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

if not exists (select 1 from sysobjects where name = 'FK_XYRules_CostOffers')
ALTER TABLE [dbo].[XYRules]  WITH CHECK 
	ADD CONSTRAINT [FK_XYRules_CostOffers] FOREIGN KEY([XY_CostOfferId])
	REFERENCES [dbo].[CostOffers] ([CO_Id])
	ON DELETE CASCADE
GO

grant select, update, insert, delete on dbo.Seasons to public
go
grant select, update, insert, delete on dbo.CostOffers to public
go
grant select, update, insert, delete on dbo.CostOfferTypes to public
go
grant select, update, insert, delete on dbo.XYRules to public
go

-- 100212(DropSettingColumns).sql
-- переносим данные из таблицы Setting в SystemSettings (Обоснование скидки, источник рекламы, дата входа)
declare @sql nvarchar (4000)
if exists (select * from [dbo].[syscolumns] where id = object_id(N'[dbo].[Setting]') and name = 'ST_Date')
begin
	set @sql ='
	declare @dtDate datetime
	select @dtDate = ST_Date from [dbo].[Setting]
	if not exists( select 1 from [dbo].[SystemSettings] where ss_parmname= ''SYSDate'' )
	begin
		insert into [dbo].[SystemSettings] (ss_parmname, ss_parmvalue) 
		values (''SYSDate'', @dtDate)
		alter table [dbo].[Setting] drop column ST_DATE
	end'
	exec sp_executesql @sql
end
go

declare @sql nvarchar (4000)
if exists (select * from [dbo].[syscolumns] where id = object_id(N'[dbo].[Setting]') and name = 'ST_CauseDiscount')
begin
	set @sql ='
	declare @nCauseDiscount smallint
	select @nCauseDiscount = ST_CauseDiscount from [dbo].[Setting]
	if not exists( select 1 from [dbo].[SystemSettings] where ss_parmname= ''SYSCauseDiscount'' )
	begin
		insert into [dbo].[SystemSettings] (ss_parmname, ss_parmvalue, ss_name) 
		values (''SYSCauseDiscount'', @nCauseDiscount, ''Обоснование скидки'')
		alter table [dbo].[Setting] drop column ST_CauseDiscount
	end'
	exec sp_executesql @sql
end
go

declare @sql nvarchar (4000)
if exists (select * from [dbo].[syscolumns] where id = object_id(N'[dbo].[Setting]') and name = 'ST_Advertisement')
begin
	set @sql ='
	declare @nAdvertisement smallint
	select @nAdvertisement = ST_Advertisement from [dbo].[Setting]
	if not exists( select 1 from [dbo].[SystemSettings] where ss_parmname= ''SYSAdvertisement'' )
	begin
		insert into [dbo].[SystemSettings] (ss_parmname, ss_parmvalue, ss_name) 
		values (''SYSAdvertisement'', @nAdvertisement, ''Источник рекламы'')
		alter table [dbo].[Setting] drop column ST_Advertisement
	end'
	exec sp_executesql @sql
end
go



-- sp_mwCheckQuotesCycle.sql
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
							@days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output
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
							@days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output
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

-- T_TPServicesDelete.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_TPServicesDelete]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_TPServicesDelete]
GO

CREATE TRIGGER [T_TPServicesDelete]
	ON [dbo].[TP_Services] 
FOR DELETE
AS
BEGIN


	declare @key int, @toKey int, @count int, @descr varchar(255)
	declare curDelete cursor for select ts_key, ts_tokey from deleted
	open curDelete 

	Fetch Next From curDelete INTO @key, @toKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		select @count = count(1) from tp_servicelists with(nolock) where tl_tskey = @key
		if @count > 0
		begin
			set @descr = 'tp_services_' + USER + '_' + HOST_NAME() + '_' + APP_NAME()
			insert into dbo.debug(db_Date, db_Mod, db_Text, db_n1, db_n2)
			values(GETDATE(), 'del', @descr, @toKey, @key)
		end
	
		Fetch Next From curDelete INTO @key, @toKey
	END
	close curDelete
	deallocate curDelete
	
END
GO

-- 100616_Insert_SystemSettings.sql
if not exists (select * from SystemSettings where SS_ParmName like 'SYSPriceDBName')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values('SYSPriceDBName', '')
GO


-- 100616_AlterTableDebug.sql
alter table dbo.debug alter column db_text varchar(255)
GO

-- sp_GetServiceList.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetServiceList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetServiceList] 
GO
create procedure [dbo].[GetServiceList] 
(
--<VERSION>2008.1.01.09a</VERSION>
@TypeOfRelult int, -- 1-список по по услугам, 2-список по туристам на услуге
@SVKey int, 
@Codes varchar(100), 
@SubCode1 int=null,
@Date datetime =null, 
@QDID int =null,
@QPID int =null,
@ShowHotels bit =null,
@ShowFligthDep bit =null,
@ShowDescription bit =null,
@State smallint=null
)
as 
declare @Query varchar(8000)
 
CREATE TABLE #Result
(
DG_Code varchar(20) collate Cyrillic_General_CI_AS, DG_Key int, DG_DiscountSum money, DG_Price money, DG_Payed money, 
DG_PriceToPay money, DG_Rate varchar(3) collate Cyrillic_General_CI_AS, DG_NMen int, 
PR_Name varchar(100) collate Cyrillic_General_CI_AS, CR_Name varchar(50) collate Cyrillic_General_CI_AS, 
DL_Key int, DL_NDays int, DL_NMen int, DL_Reserved int, DL_CTKeyTo int, DL_CTKeyFrom int, DL_CNKEYFROM int, DL_SubCode1 int,
TL_Key int, TL_Name varchar(160) collate Cyrillic_General_CI_AS,
TUCount int,
TU_NameRus varchar(25) collate Cyrillic_General_CI_AS, TU_NameLat varchar(25) collate Cyrillic_General_CI_AS, TU_FNameRus varchar(15) collate Cyrillic_General_CI_AS, TU_FNameLat varchar(15) collate Cyrillic_General_CI_AS, TU_Key int, 
TU_Sex Smallint, TU_PasportNum varchar(13) collate Cyrillic_General_CI_AS, TU_PasportType varchar(5) collate Cyrillic_General_CI_AS, TU_PasportDateEnd datetime, TU_BirthDay datetime,
TU_Hotels varchar(255) collate Cyrillic_General_CI_AS,
Request smallint, Commitment smallint, Allotment smallint, Ok smallint, 
TicketNumber varchar(16) collate Cyrillic_General_CI_AS, FlightDepDLKey int, FligthDepDate datetime, FlightDepNumber varchar(10) collate Cyrillic_General_CI_AS,
ServiceDescription varchar(80) collate Cyrillic_General_CI_AS, ServiceDateBeg datetime, ServiceDateEnd datetime
)
 
SET @Query = '
	INSERT INTO #Result (DG_Code, DG_Key, DG_DiscountSum, DG_Price, DG_Payed, 
		DG_PriceToPay, DG_Rate, DG_NMen, 
		PR_Name, CR_Name, 
		DL_Key, DL_NDays, DL_NMen, DL_Reserved, DL_CTKeyTo, DL_CTKeyFrom, DL_SubCode1, ServiceDateBeg, ServiceDateEnd, 
		TL_Key, TUCount'
IF @TypeOfRelult=2
	SET @Query=@Query + ',
		TU_NameRus, TU_NameLat, TU_FNameRus, TU_FNameLat, TU_Key, 
		TU_Sex, TU_PasportNum, TU_PasportType, TU_PasportDateEnd, TU_BirthDay, TicketNumber'
SET @Query=@Query + ') 
	SELECT	  DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, 
		(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, 
		DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + '=3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END,
						DG_TRKey,'
IF @TypeOfRelult=1
	SET @Query=@Query + 'Count(tu_dlkey) '
ELSE IF @TypeOfRelult=2
	SET @Query=@Query + '0, 
		TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS, TU_FNAMELAT, TU_KEY,
		TU_SEX, TU_PASPORTNUM, TU_PASPORTTYPE, TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc '
SET @Query=@Query + '
FROM  Dogovor, Partners, Controls, Dogovorlist '
IF @TypeOfRelult=1
	SET @Query=@Query + 'left join Turistservice on tu_dlkey=dl_key '
ELSE IF @TypeOfRelult=2
	SET @Query=@Query + ', Turist, TuristService '
SET @Query=@Query + '
WHERE
		dl_dGKEY=DG_KEY and dl_control=cr_key and dl_agent=pr_key '
IF @QPID is not null or @QDID is not null
BEGIN
	IF @QPID is not null
		SET @Query=@Query + ' and exists (SELECT top 1 SD_DLKEY FROM ServiceByDate WHERE SD_QPID IN (' + CAST(@QPID as varchar(20)) + ') and SD_DLKEY=DL_Key)'
	ELSE
		SET @Query=@Query + ' and exists (SELECT top 1 SD_DLKEY FROM ServiceByDate, QuotaParts WHERE SD_QPID=QP_ID and QP_QDID IN (' + CAST(@QDID as varchar(20)) + ') and SD_DLKEY=DL_Key)'
END

SET @Query=@Query + '
	and DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' AND DL_CODE in (' + @Codes + ') AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND '
if (@SubCode1 != '0')
	SET @Query=@Query + ' AND DL_SUBCODE1 in (' + CAST(@SubCode1 as varchar(20)) + ')'
IF @State is not null
	SET @Query=@Query + ' and exists(SELECT 1 FROM ServiceByDate WHERE SD_State=' + CAST(@State as varchar(1)) + ' and SD_DLKey=DL_Key and SD_Date=''' + CAST(@Date as varchar(20)) + ''')'
 
IF @TypeOfRelult=1
	SET @Query=@Query + '
	group by DG_CODE,DG_KEY,DG_DISCOUNTSUM,DG_PDTTYPE,DG_PRICE,DG_PAYED,(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ) ,DG_RATE,DG_NMEN,PR_NAME,CR_NAME,
		DL_SUBCODE1,DL_SUBCODE2,DL_DateBeg,DL_DateEnd,DL_NDays,DL_WAIT,DL_KEY,DL_NMEN,DL_RESERVED,DG_TRKey,DL_CTKEY'
ELSE
	SET @Query=@Query + '
	and tu_dlkey = dl_key and tu_key = tu_tukey'
--PRINT @Query
EXEC (@Query)
 
UPDATE #Result SET #Result.TL_Name=(SELECT TL_Name FROM TurList WHERE #Result.TL_Key=TurList.TL_Key)
 
if @TypeOfRelult=1
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_State=1)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_State=3)
END
else
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=1)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=3)
END
 
IF @ShowHotels=1
BEGIN
	IF @TypeOfRelult = 2
	BEGIN
		DECLARE @HD_Name varchar(100), @HD_Stars varchar(25), @PR_Name varchar(100), @TU_Key int, @HD_Key int, @PR_Key int, @TU_KeyPrev int, @TU_Hotels varchar(255)
		DECLARE curServiceList CURSOR FOR 
			SELECT	  DISTINCT HD_Name, HD_Stars, PR_Name, TU_TUKey, HD_Key, PR_Key 
			FROM  HotelDictionary, DogovorList, TuristService, Partners
			WHERE	  PR_Key=DL_PartnerKey and HD_Key=DL_Code and TU_DLKey=DL_Key and TU_TUKey in (SELECT TU_Key FROM #Result) and dl_SVKey=3 
			ORDER BY TU_TUKey
		OPEN curServiceList
		FETCH NEXT FROM curServiceList INTO	  @HD_Name, @HD_Stars, @PR_Name, @TU_Key, @HD_Key, @PR_Key
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @TU_Key!=@TU_KeyPrev or @TU_KeyPrev is null
			  Set @TU_Hotels=@HD_Name+' '+@HD_Stars+' ('+@PR_Name+')'
			ELSE
			  Set @TU_Hotels=@TU_Hotels+', '+@HD_Name+' '+@HD_Stars+' ('+@PR_Name+')'
			UPDATE #Result SET TU_Hotels=@TU_Hotels WHERE TU_Key=@TU_Key
			SET @TU_KeyPrev=@TU_Key
			FETCH NEXT FROM curServiceList INTO	  @HD_Name, @HD_Stars, @PR_Name, @TU_Key, @HD_Key, @PR_Key
		END
		CLOSE curServiceList
		DEALLOCATE curServiceList
	END
	IF @TypeOfRelult = 1
	BEGIN
		DECLARE @HD_Name1 varchar(100), @HD_Stars1 varchar(25), @PR_Name1 varchar(100), @DL_Key1 int, @HD_Key1 int, 
				@PR_Key1 int, @DL_KeyPrev1 int, @TU_Hotels1 varchar(255), @DG_Key int, @DG_KeyPrev int
		DECLARE curServiceList CURSOR FOR 
			--SELECT DISTINCT HD_Name, HD_Stars, P.PR_Name, DogList.DL_Key, HD_Key, PR_Key--, DG_Key
			--FROM HotelDictionary, DogovorList DogList, TuristService, Partners P
			--WHERE P.PR_Key = DogList.DL_PartnerKey and HD_Key = DogList.DL_Code and TU_DLKey = DogList.DL_Key and
			--TU_TUKey in (SELECT TU_TUKEY FROM TuristService WHERE TU_DLKEY in (SELECT DL_KEY FROM #Result)) 
			--and DL_SVKey=3 
			--ORDER BY DogList.DL_Key
			SELECT DISTINCT HD_Name, HD_Stars, HD_Key, P.PR_Name, P.PR_Key, DogList.DL_Key, R.DG_Key
			FROM HotelDictionary, DogovorList DogList, Partners P, #Result R
			WHERE P.PR_Key = DogList.DL_PartnerKey and HD_Key = DogList.DL_Code and DogList.DL_DGKey = R.DG_Key			
				  and DogList.DL_SVKey=3 
			ORDER BY R.DG_Key
		OPEN curServiceList
		FETCH NEXT FROM curServiceList INTO @HD_Name1, @HD_Stars1, @HD_Key1, @PR_Name1, @PR_Key1, @DL_Key1, @DG_Key
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @DG_Key != @DG_KeyPrev or @DG_KeyPrev is null  
			BEGIN
			  Set @TU_Hotels1=@HD_Name1+' '+@HD_Stars1+' ('+@PR_Name1+')'
			END
			ELSE
			BEGIN
			  Set @TU_Hotels1=@TU_Hotels1+', '+@HD_Name1+' '+@HD_Stars1+' ('+@PR_Name1+')'
			END
			UPDATE #Result SET TU_Hotels=@TU_Hotels1 WHERE DG_Key=@DG_Key --DL_Key=@DL_Key1
			SET @DG_KeyPrev = @DG_Key
			FETCH NEXT FROM curServiceList INTO @HD_Name1, @HD_Stars1, @HD_Key1, @PR_Name1, @PR_Key1, @DL_Key1, @DG_Key
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
		Update #Result SET ServiceDescription=LEFT((SELECT ISNUll(AS_Code, '') + '-' + AS_NameRus FROM AirService WHERE AS_Key=DL_SubCode1),80)
	ELSE IF (@SVKey=2 or @SVKey=4)
		Update #Result SET ServiceDescription=LEFT((SELECT TR_Name FROM Transport WHERE TR_Key=DL_SubCode1),80)
	ELSE IF (@SVKey=3 or @SVKey=8)
	BEGIN
		Update #Result SET ServiceDescription=LEFT((SELECT RM_Name + '(' + RC_Name + ')' + AC_Name FROM Rooms,RoomsCategory,AccMdMenType,HotelRooms WHERE HR_Key=DL_SubCode1 and HR_RMKey=RM_Key and HR_RCKey=RC_Key and HR_ACKey=AC_Key),80)
		IF @SVKey=8
			Update #Result SET ServiceDescription='All accommodations' where DL_SubCode1=0
	END
	ELSE IF (@SVKey=7 or @SVKey=9)
	BEGIN
		Update #Result SET ServiceDescription=LEFT((SELECT ISNULL(CB_Code,'') + ',' + ISNULL(CB_Category,'') + ',' + ISNULL(CB_Name,'') FROM Cabine WHERE CB_Key=DL_SubCode1),80)
		IF @SVKey=9
			Update #Result SET ServiceDescription='All accommodations' where DL_SubCode1=0
	END
	ELSE
		Update #Result SET ServiceDescription=LEFT((SELECT A1_Name FROM AddDescript1 WHERE A1_Key=DL_SubCode1),80) WHERE ISNULL(DL_SubCode1,0)>0
END

--print @Query
SELECT * FROM #Result
GO
GRANT EXECUTE ON [dbo].[GetServiceList] TO Public
GO


-- 100617 PrivatePerson and SystemSettings.sql
IF NOT EXISTS(SELECT * FROM dbo.syscolumns WHERE id = object_id(N'[dbo].[tbl_Partners]') and name = 'PR_PrivatePerson')
ALTER TABLE [dbo].[tbl_Partners] ADD [PR_PrivatePerson] bit NOT NULL DEFAULT(0)
GO
EXEC sp_RefreshViewForAll 'Partners'
GO
IF NOT EXISTS(SELECT 1 FROM SYSTEMSETTINGS WHERE SS_ParmName LIKE 'SYSDGMainManRule')
INSERT INTO SYSTEMSETTINGS(SS_ParmName, SS_ParmValue)
VALUES('SYSDGMainManRule','0')
GO
DECLARE @DogovorWithMainTourist varchar(1)
SELECT @DogovorWithMainTourist = SS_ParmValue 
FROM SYSTEMSETTINGS 
WHERE SS_ParmName LIKE 'SYSDogovorWithMainTourist'
IF(@DogovorWithMainTourist IS NOT NULL AND (@DogovorWithMainTourist = '0' OR @DogovorWithMainTourist = '1'))
BEGIN
	UPDATE SYSTEMSETTINGS
	SET SS_ParmValue = @DogovorWithMainTourist
	WHERE SS_ParmName LIKE 'SYSDGMainManRule'
END
DELETE 
FROM SYSTEMSETTINGS
WHERE SS_ParmName LIKE 'SYSDogovorWithMainTourist'
GO
-- 0 - в зависимости от партнёра по путёвке
-- 1 - всегда использовать информацию из главного туриста
-- 2 - всегда использовать информацию из лица заключившего договор


-- sp_UpdateReservationMainManByTourist.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateReservationMainManByTourist]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateReservationMainManByTourist] 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateReservationMainManByTourist]
	@Name varchar(35),
	@FName varchar(15),
	@SName varchar(15),
	@Phone varchar(60),
	@PostIndex varchar(8),
	@PostCity varchar(60),
	@PostStreet varchar(25),
	@PostBuilding varchar(10),
	@PostFlat varchar(4),
	@PassportSeries varchar(10),
	@PassportNumber varchar(10),
	@ReservationCode varchar(10)
AS
BEGIN
	DECLARE @ManName varchar(45)
		  , @ManPhone varchar(50)
		  , @ManAddress varchar(320)
		  , @ManPassport varchar(70)
		  , @ManSName char(1);
	IF (LEN(ISNULL(@SName,'')) > 1)
		SET @ManSName = SUBSTRING(@SName,1,1);
	ELSE
		SET @ManSName = ISNULL(@SName,'');
	SET @ManName = ISNULL(@Name,'') +' '+ ISNULL(@FName,'') +' '+ @ManSName;
	IF (LEN(ISNULL(@Phone,'')) > 30)
		SET @ManPhone = SUBSTRING(@Phone,1,30);
	ELSE
		SET @ManPhone = ISNULL(@Phone,'');
	SET @ManAddress = ISNULL(@PostIndex,'');
	IF(LEN(ISNULL(@PostCity,'')) > 0)
		SET @ManAddress = @ManAddress + ' ' + @PostCity;
	IF(LEN(ISNULL(@PostStreet,'')) > 0)
		SET @ManAddress = @ManAddress + ',' + @PostStreet;
	IF(LEN(ISNULL(@PostBuilding,'')) > 0)
		SET @ManAddress = @ManAddress + '-' + @PostBuilding;
	IF(LEN(ISNULL(@PostFlat,'')) > 0)
		SET @ManAddress = @ManAddress + ',' + @PostFlat + ' кв.';
	SET @ManPassport = ISNULL(@PassportSeries,'') +' '+ISNULL(@PassportNumber,'');
	EXEC [dbo].[UpdateReservationMainMan] @ManName, @ManPhone, @ManAddress
	                                    , @ManPassport, @ReservationCode
END
go
GRANT EXECUTE ON [dbo].[UpdateReservationMainManByTourist] TO PUBLIC
go

-- sp_UpdateReservationMainManByPartnerUser.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateReservationMainManByPartnerUser]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateReservationMainManByPartnerUser] 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateReservationMainManByPartnerUser]
	@ReservationCode varchar(10)
AS
BEGIN
	DECLARE @PartnerUserKey int
		  , @PartnerUserAddress varchar(250)
		  , @PartnerUserName varchar(50)
		  , @PartnerUserPhone varchar(50)
		  , @PartnerUserPassport varchar(18)
		  , @MainManName varchar(45)
		  , @MainManPhone varchar(50)
		  , @MainManAddress varchar(320)
		  , @MainManPassport varchar(70);
	SELECT @PartnerUserKey = DG_DUPUSERKEY 
	  FROM [dbo].[TBL_DOGOVOR] 
	 WHERE DG_CODE = @ReservationCode;
	IF(ISNULL(@PartnerUserKey,0)<>0)
	BEGIN
		SELECT @MainManName = DG_MAINMEN
			 , @MainManPhone = DG_MAINMENPHONE
			 , @MainManAddress = DG_MAINMENADRESS
			 , @MainManPassport = DG_MAINMENPASPORT
		  FROM [dbo].[TBL_DOGOVOR]
		 WHERE DG_CODE = @ReservationCode;
		IF ((ISNULL(@MainManName,'') = '') AND (ISNULL(@MainManPhone,'') = '') 
			AND (ISNULL(@MainManAddress,'') = '') AND (ISNULL(@MainManPassport,'') = ''))
		BEGIN
			SELECT @PartnerUserName = SUBSTRING(ISNULL(US_FULLNAME,''),1,45)
				 , @PartnerUserPhone = ISNULL(US_PHONE,'')
				 , @PartnerUserAddress = ISNULL(US_ADDRESS,'')
				 , @PartnerUserPassport = ISNULL(US_PassportCode,'') + ' ' + ISNULL(US_PassportNo,'')
			  FROM [dbo].[DUP_USER]
			 WHERE US_KEY = @PartnerUserKey;
			EXEC [dbo].[UpdateReservationMainMan] @PartnerUserName, @PartnerUserPhone
												, @PartnerUserAddress, @PartnerUserPassport
												, @ReservationCode;
		END
	END
END
go
GRANT EXECUTE ON [dbo].[UpdateReservationMainManByPartnerUser] TO PUBLIC
go

-- sp_CheckPrivatePerson.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CheckPrivatePerson]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CheckPrivatePerson] 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CheckPrivatePerson]
		@ReservationCode varchar(10)
AS
BEGIN
	DECLARE @PartnerKey int
		  , @UserSetting varchar(1)
		  , @PrivatePerson bit;
	SELECT @UserSetting = SUBSTRING(SS_ParmValue,1,1)
	  FROM SYSTEMSETTINGS
	 WHERE SS_ParmName = 'SYSDGMainManRule'; 
	IF(@UserSetting = '2') 
		RETURN 0;
	ELSE IF(@UserSetting = '1')
		RETURN 1;
	ELSE
	BEGIN
		SELECT @PartnerKey = DG_PARTNERKEY 
		  FROM [dbo].[TBL_DOGOVOR]
		 WHERE DG_CODE = @ReservationCode;
		IF(@PartnerKey = 0)
			RETURN 1;
		ELSE
		BEGIN
			SELECT @PrivatePerson = PR_PrivatePerson
			  FROM [dbo].[TBL_PARTNERS]
			 WHERE PR_KEY = @PartnerKey;
			IF(@PrivatePerson = 1) 
				RETURN 1;
		END
		RETURN 0;
	END
END
GO

GRANT EXECUTE ON [dbo].[CheckPrivatePerson] TO PUBLIC
GO

-- sp_SetReservationStatus.sql
IF OBJECT_ID('dbo.SetReservationStatus') IS NOT NULL
	DROP PROCEDURE dbo.SetReservationStatus
GO

CREATE PROCEDURE dbo.SetReservationStatus(@dg_key int)
AS
BEGIN
	DECLARE @StatusRuleId int
	DECLARE @id int, @typeid int, @onWaitList int, @serviceStatusId int, @excludeServiceId int
	DECLARE @dlCount1 int, @dlCount2 int, @dlCount3 int, @dlWaitCount int
	DECLARE @sUpdateMainDogovorStatuses varchar(254)

	declare ruleCursor cursor read_only fast_forward for
	select sr_id, sr_typeid, sr_onwaitlist, sr_servicestatusid, sr_excludeserviceid
	from dbo.StatusRules
	order by sr_priority asc

	open ruleCursor
	fetch next from ruleCursor into @id, @typeid, @onWaitList, @serviceStatusId, @excludeServiceId
	while @@fetch_status = 0 and @StatusRuleId is null
	begin
		
		-- 1. Services -> Reservation
		if @typeid = 2
		begin
			select @dlCount1 = COUNT(dl_key) FROM dbo.tbl_DogovorList 
			WHERE 
				dl_dgkey = @dg_key 
			AND (dl_control = @serviceStatusId OR @serviceStatusId IS NULL)
			AND ((dbo.DogovorListRequestStatus(DL_Key) = 4 and ISNULL(@onWaitList, 0) = 1) or ISNULL(@onWaitList, 0) = 0)
			AND dl_svkey != ISNULL(@excludeServiceId, 0)

			SELECT @dlCount2 = COUNT(dl_key) FROM dbo.tbl_DogovorList 
			WHERE 
				dl_dgkey = @dg_key 
			AND dl_svkey != ISNULL(@excludeServiceId, 0)

			if (@dlCount1 = @dlCount2 and @dlCount2 > 0)
				set @StatusRuleId = @id
		end

		-- 2. Service -> Reservation
		if @typeid = 1
		begin
			SELECT @dlCount1 = count(dl_key) FROM dbo.tbl_DogovorList 
				WHERE 
					dl_dgkey = @dg_key 
				AND (dl_control = @serviceStatusId OR @serviceStatusId IS NULL)
				AND ((dbo.DogovorListRequestStatus(DL_Key) = 4 and ISNULL(@onWaitList, 0) = 1) or ISNULL(@onWaitList, 0) = 0)
				AND dl_svkey != ISNULL(@excludeServiceId, 0)

			if @dlCount1 > 0
				set @StatusRuleId = @id
		end

		fetch next from ruleCursor into @id, @typeid, @onWaitList, @serviceStatusId, @excludeServiceId
	end

	close ruleCursor
	deallocate ruleCursor

	-- 3. Update
	select @sUpdateMainDogovorStatuses = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSUpdateMainDogStatuses'
	IF @StatusRuleId IS NOT NULL
	BEGIN
		if (ISNULL(@sUpdateMainDogovorStatuses, '0') = '0')
		begin
			UPDATE dbo.tbl_Dogovor 
				SET dg_sor_code = (SELECT sr_ReservationStatusId FROM dbo.StatusRules WHERE sr_id = @StatusRuleId)
			WHERE dg_key = @dg_key
		end
		else
		begin
			UPDATE dbo.tbl_Dogovor 
				SET dg_sor_code = (SELECT sr_ReservationStatusId FROM dbo.StatusRules WHERE sr_id = @StatusRuleId)
			WHERE dg_key = @dg_key and DG_Sor_Code in (1,2,3,7)
		end
	END
END
GO

GRANT EXECUTE ON [dbo].[SetReservationStatus] TO Public
GO

-- 100617_ReservationStatuses_Fix.sql
--
/*
if not exists (select 1 from statusrules where sr_priority = 777)
begin
	insert into StatusRules (sr_typeid, sr_reservationstatusid, sr_servicestatusid, sr_priority)
	select 1, 1, cr_key, 777 from controls where isnull(cr_globalstate, 0)<>1
end
go

-- 
declare Dog_cursor cursor fast_forward read_only
for select dg_key from dbo.tbl_Dogovor where dg_crdate >= '2010-06-05'

open Dog_cursor

declare @dg_key int
fetch next from Dog_cursor into @dg_key 
while @@fetch_status = 0 
begin
	exec dbo.SetReservationStatus @dg_key 
	print @dg_key
	fetch next from Dog_cursor into @dg_key 
end

close Dog_cursor
deallocate Dog_cursor
go
*/

-- sp_UpdateReservationMainMan.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateReservationMainMan]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateReservationMainMan] 
GO

CREATE PROCEDURE [dbo].[UpdateReservationMainMan]
	@ManName varchar(45), 
	@ManPhone varchar(50), 
	@ManAddress varchar(320), 
	@ManPassport varchar(70),
	@ReservationCode varchar(10)
AS
BEGIN
	UPDATE [dbo].[TBL_DOGOVOR]
	   SET DG_MAINMEN = @ManName
	     , DG_MAINMENPHONE = @ManPhone
	     , DG_MAINMENADRESS = @ManAddress
         , DG_MAINMENPASPORT = @ManPassport
	 WHERE DG_CODE = @ReservationCode;
END
go
GRANT EXECUTE ON [dbo].[UpdateReservationMainMan] TO PUBLIC
go

-- T_TuristUpdate.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_TuristUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_TuristUpdate]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create TRIGGER [dbo].[T_TuristUpdate]
ON [dbo].[tbl_Turist] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2007.2.22.1</VERSION>
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
			 null, null, null, null, null, null,
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
				N.TU_PHONE
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
		  	 O.TU_DGCod, O.TU_DGKey, null, null, null, null,
			 null, null, null, null, null, null,
			 null, null, null, null, null, null,
			 null, null,
			 null, null, null, null,
			 null, null, null, null, null, null
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
				N.TU_PHONE
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
				@NTU_PHONE
    WHILE @@FETCH_STATUS = 0
    BEGIN 
	  ------------Проверка, надо ли что-то писать в историю-------------------------------------------   
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
			ISNULL(@OTU_ISMAIN, 0) != ISNULL(@NTU_ISMAIN, 0)
		))
	  BEGIN
	  	------------Запись в историю--------------------------------------------------------------------
		
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
		--SELECT @nHIID = IDENT_CURRENT('History')
		--------Детализация--------------------------------------------------
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
		IF (@sMod = 'UPD')
		BEGIN
			IF((ISNULL(@OTU_ISMAIN,0) = 1)AND(ISNULL(@NTU_ISMAIN,0) = 0))
			BEGIN
				DECLARE @HaveMainTourist int;
				SELECT @HaveMainTourist = TU_ISMAIN
				  FROM [dbo].[TBL_TURIST]
				 WHERE TU_DGCOD = @NTU_DGCOD AND TU_Key <> @TU_KEY;
				IF(@HaveMainTourist IS NULL)
				BEGIN
					UPDATE [dbo].[TBL_TURIST]
					SET TU_ISMAIN = 1
					WHERE TU_Key = @TU_KEY;
				END
			END
			IF(ISNULL(@NTU_ISMAIN,0) = 1)
			BEGIN
				EXEC @PrivatePerson = dbo.CheckPrivatePerson @NTU_DGCOD;
				IF(@PrivatePerson = 1)
				BEGIN
					EXEC [dbo].[UpdateReservationMainManByTourist] @NTU_NAMERUS, @NTU_FNAMERUS, @NTU_SNAMERUS, @NTU_PHONE
																 , @NTU_POSTINDEX, @NTU_POSTCITY, @NTU_POSTSTREET
																 , @NTU_POSTBILD, @NTU_POSTFLAT, @NTU_PASPRUSER
																 , @NTU_PASPRUNUM, @NTU_DGCOD;
				END
			END
		END
		ELSE IF (@sMod = 'DEL')
		BEGIN
			DECLARE @NewMainTourist int;
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
					DECLARE @Name varchar(35),
							@FName varchar(15),
							@SName varchar(15),
							@Phone varchar(60),
							@PostIndex varchar(8),
							@PostCity varchar(60),
							@PostStreet varchar(25),
							@PostBuilding varchar(10),
							@PostFlat varchar(4),
							@PassportSeries varchar(10),
							@PassportNumber varchar(10);
					SELECT @Name = TU_NAMERUS, @FName = TU_FNAMERUS, @SName = TU_SNAMERUS, @Phone = TU_PHONE
						 , @PostIndex = TU_POSTINDEX, @PostCity = TU_POSTCITY, @PostStreet = TU_POSTSTREET
						 , @PostBuilding = TU_POSTBILD, @PostFlat = TU_POSTFLAT, @PassportSeries = TU_PASPRUSER
						 , @PassportNumber = TU_PASPRUNUM
					  FROM [dbo].[tbl_turist]
					 WHERE TU_KEY = @NewMainTourist;
					EXEC [dbo].[UpdateReservationMainManByTourist] @Name, @FName, @SName, @Phone
												                 , @PostIndex, @PostCity, @PostStreet
												                 , @PostBuilding, @PostFlat, @PassportSeries
												                 , @PassportNumber, @OTU_DGCOD;
				END
				ELSE
				BEGIN
					EXEC [dbo].[UpdateReservationMainMan] '','','','',@OTU_DGCOD;
				END
			END
		END
		ELSE IF(@sMod = 'INS')
		BEGIN
			DECLARE @HaveMainMan int, @MainManSex int;
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
					EXEC [dbo].[UpdateReservationMainManByTourist] @NTU_NAMERUS, @NTU_FNAMERUS, @NTU_SNAMERUS, @NTU_PHONE
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
					EXEC [dbo].[UpdateReservationMainManByTourist] @NTU_NAMERUS, @NTU_FNAMERUS, @NTU_SNAMERUS, @NTU_PHONE
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
				@NTU_PHONE
    END
  CLOSE cur_Turist
  DEALLOCATE cur_Turist
END
GO

-- sp_BeforeDeleteRow.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[BeforeDeleteRow]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[BeforeDeleteRow]
GO
CREATE PROCEDURE [dbo].[BeforeDeleteRow]
(	@sTableName varchar(256),  
	@nKey int,
	@nNewKey int )
AS
Declare @ObjectName varchar(255)
If @sTableName = 'CategoriesOfHotel'
BEGIN	
	Select @ObjectName=COH_Name From dbo.CategoriesOfHotel Where COH_ID=@nNewKey
	Update dbo.HotelDictionary Set HD_Stars=@ObjectName Where HD_COHId=@nNewKey	
END
if @sTableName='tbl_Partners' OR @sTableName='Partners'
begin
	IF OBJECT_ID('FIN_CHECKPARTNER') IS NOT NULL AND
		OBJECT_ID('FIN_CHANGEPARTNER') IS NOT NULL 
	BEGIN
		declare @nUsed int
		execute FIN_CHECKPARTNER @nKey, @nUsed OUTPUT
		if @nUsed = 1
			execute FIN_CHANGEPARTNER @nKey, @nNewKey
	END
end
GO

GRANT EXEC ON [dbo].[BeforeDeleteRow] TO PUBLIC
GO

-- sp_RowHasChild.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RowHasChild]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[RowHasChild]
GO
create procedure [dbo].[RowHasChild]
	@sTableName varchar(256),
	@nKey int,
	@nHasChild int output
AS
SET @nHasChild = 0
if @sTableName='tbl_Partners' OR @sTableName='Partners'
begin
	IF OBJECT_ID('FIN_CHECKPARTNER') IS NOT NULL
	execute FIN_CHECKPARTNER @nKey, @nHasChild OUTPUT
end
GO

GRANT EXEC ON [dbo].[RowHasChild] TO PUBLIC
GO

-- fn_DogovorListRequestStatus.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DogovorListRequestStatus]') and OBJECTPROPERTY(id, N'IsTableFunction') = 0)
	drop function [dbo].[DogovorListRequestStatus]
GO

CREATE function [dbo].[DogovorListRequestStatus](@dlKey int) returns int
begin
	--	1,2  на квоте 		- зеленый
	--	3     если на OK целиком	- голубой
	--	4     на RQ целиком	- розовый
	declare @status int
	SELECT  @status = CASE (	SELECT 	COUNT(DISTINCT ISNULL(NULLIF(SD_State,2),1)) 
			FROM 	ServiceByDate with(nolock)
			WHERE 	SD_DLKey = @dlKey)
		WHEN 	1  THEN (SELECT TOP 1 SD_State FROM ServiceByDate WHERE SD_DLKey = @dlKey)
		ELSE 	0	
		END

	return @status
end
GO

grant exec on [dbo].[DogovorListRequestStatus] to public
go


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ConvertQuotesPlaces]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ConvertQuotesPlaces] 

 GO

create PROCEDURE [dbo].[ConvertQuotesPlaces]
( @datestart datetime )
as
begin
---перенос занимаемых мест по квоте

-- %%%%%%%% AleXK отключаем триггеры которые пишут в  историю %%%%%%%%
DISABLE TRIGGER [T_SystemSettingsUpdate] ON systemsettings;
-- этот триггер нельзя отключать
--DISABLE TRIGGER [T_ServiceByDateChanged] ON ServiceByDate;
DISABLE TRIGGER [T_QuotaPartsChange] ON [QuotaParts];
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exists (select * from systemsettings where SS_ParmName='SYSCheckQuotaRelease')
	update systemsettings set SS_ParmValue=1 where SS_ParmName = 'SYSCheckQuotaRelease'	
else 
	insert into systemsettings (SS_ParmName, SS_ParmValue) values ('SYSCheckQuotaRelease', 1)

	DECLARE @nDL_Max int
	if not exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSMT2008DLKEY')
	BEGIN
		SELECT @nDL_Max=MAX(DL_KEY) FROM DOGOVORLIST
		insert into systemsettings (SS_ParmName, SS_ParmValue) values ('SYSMT2008DLKEY',@nDL_Max )
	END
	ELSE
		SELECT @nDL_Max=CAST(SS_ParmValue as int) FROM systemsettings where SS_ParmName='SYSMT2008DLKEY'

	Declare @TUKEY INT, @dlkey int, @DGKey int, @DLSVKey int, @DLCode int, @DLSubcode1 int, @DLDateBeg datetime, @DLDateEnd datetime, @DLNMen int, @QuoteKey int, @QuoteType smallint, @TempType smallint, @HRMain smallint
	Declare @qddate datetime ,@qtkey  int ,@from int 
	declare @Date datetime, @RLID int 
	declare @HRIsMain smallint, @RMKey int, @RCKey int, @ACKey int
	Declare	@NeedPlacesForMen int,@rpid int ,
			@RMPlacesMain smallint, @RMPlacesEx smallint,
			@ACPlacesMain smallint, @ACPlacesEx smallint, @ACPerRoom smallint,
			@RLPlacesMain smallint, @RLPlacesEx smallint, @RLCount smallint, 
			@AC_FreeMainPlacesCount smallint, @AC_FreeExPlacesCount smallint,
			@CurrentPlaceIsEx bit, @RL_FreeMainPlacesCount smallint, @RL_FreeExPlacesCount smallint
	DECLARE cur_DogovorList CURSOR FOR 
		SELECT 	DL_Key,DL_SvKey, DL_Code, DL_SubCode1, DL_DateBeg, DL_DateEnd, DL_NMen, DL_QuoteKey
		FROM	Dogovorlist where dl_svkey <> 3
				--%% AleXK добавил чтобы квоты переносились только по квотируемым услугам %%
				and dl_svkey in (select sv_key from [service] where SV_QUOTED = 1)
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				and dl_key not in (select DC_DLKey from dbo.DLConverted)
				and DL_DateBeg > @datestart and DL_Key <= @nDL_Max
	-- and dl_cnkey=6221
	OPEN cur_DogovorList
	FETCH NEXT FROM cur_DogovorList
		INTO @DLKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @NeedPlacesForMen=ISNULL(@DLNMen,0)		
		SET @From = CAST(@DLDateBeg as int)

		while(@NeedPlacesForMen > 0)
		BEGIN
			--INSERT INTO ServiceByDate (SD_Date, SD_DLKey) values (@Date, @DLKey)			
			
			set @TUKey=null
			
			SELECT @TUKey=TU_TUKey FROM dbo.TuristService WHERE TU_DLKey=@DLKey and TU_TUKey not in (SELECT SD_TUKey FROM ServiceByDate WHERE SD_DLKey=@DLKey)
			INSERT INTO RoomPlaces(RP_RLID, RP_Type) values (0,0)
			
			set @RPID=SCOPE_IDENTITY()
			
			INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RPID, SD_TUKey)	
			SELECT CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RPID, @TUKey
			FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@DLDateEnd as int)-@From+1

			set @NeedPlacesForMen=@NeedPlacesForMen-1
		END
		
		SET @QuoteType=null
		IF @QuoteKey is not null and @QuoteKey != 0
		BEGIN
			SELECT @QuoteType=QT_Type FROM tbl_Quotes_old WHERE QT_Key=@QuoteKey
			SET @TempType=@QuoteType-2 --передаем в хранимку (последний параметр) -1 для Allotment, -2 для коммитмента
			--в этой хранимке будет выполнена попытка постановки услуги на квоту
			EXEC DogListToQuotas @DLKey,null,null,null,null,@DLDateBeg, @DLDateEnd,null,@TempType
		END
		ELSE
			EXEC DogListToQuotas @DLKey,null,null,null,null,@DLDateBeg, @DLDateEnd,null,4	-- если услуга была не на квоте, то ставим ее на Request

		INSERT INTO dbo.DLConverted (DC_DLKey,DC_QuoteType) values (@DLKey,@QuoteType)
		FETCH NEXT FROM cur_DogovorList
		INTO @DLKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey
	
	ENd
	CLOSE cur_DogovorList
	DEALLOCATE   cur_DogovorList

DECLARE cur_DogovorListhotel CURSOR FOR 
    SELECT DISTINCT 	DL_Key, DL_DGkey, DL_SvKey, DL_Code, DL_SubCode1, DL_DateBeg, DL_DateEnd, DL_NMen,DL_QUOTEKEY, HR_Main
    FROM	Dogovorlist, HotelRooms  
	where   dl_subcode1=HR_key 
			and dl_svkey = 3
			and dl_key not in (select DC_DLKey from dbo.DLConverted)
			and DL_DateBeg > @datestart and DL_Key <= @nDL_Max
	order by HR_Main desc, dl_key
OPEN cur_DogovorListhotel
FETCH NEXT FROM cur_DogovorListhotel
	INTO @DLKey, @DGKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey, @HRMain

WHILE @@FETCH_STATUS = 0
BEGIN	
				--If @NeedPlacesForMen>0 надо ли это
				SET @From = CAST(@DLDateBeg as int)
				SELECT	@HRIsMain=HR_MAIN, @RMKey=HR_RMKEY, @RCKey=HR_RCKEY, @ACKey=HR_ACKEY,
						@RMPlacesMain=RM_NPlaces, @RMPlacesEx=RM_NPlacesEx,
						@ACPlacesMain=ISNULL(AC_NRealPlaces,0), @ACPlacesEx=ISNULL(AC_NMenExBed,0), @ACPerRoom=ISNULL(AC_PerRoom,0)
				FROM HotelRooms, Rooms, AccmdMenType
				WHERE HR_Key=@DLSubcode1 and RM_Key=HR_RMKEY and AC_KEY=HR_ACKEY 
				if @ACPerRoom=1
				BEGIN
					SET @RLPlacesMain = @ACPlacesMain
					SET @RLPlacesEx = ISNULL(@ACPlacesEx,0)
				END
				Else
				BEGIN
					IF @HRIsMain = 1 and @ACPlacesMain = 0 and @ACPlacesEx = 0
						set @ACPlacesMain = 1
					ELSE IF @HRIsMain = 0 and @ACPlacesMain = 0 and @ACPlacesEx = 0
						set @ACPlacesEx = 1
					SET @RLPlacesMain = @RMPlacesMain
					SET	@RLPlacesEx = ISNULL(@RMPlacesEx,0)
				END
				
				SET @NeedPlacesForMen=ISNULL(@DLNMen,0)
				
	
			SET @RLID = 0
			SET @RPID = null
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
					--создаем новый номер, всегда когда есть хоть кто-то на основном месте
					IF (@AC_FreeMainPlacesCount > @RL_FreeMainPlacesCount) or (@AC_FreeExPlacesCount > @RL_FreeExPlacesCount)
					BEGIN
						IF @ACPlacesMain>0
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
							1. Ищем к кому подселиться в данной путевке, если не находим, то повисаем в воздухе 
							*/
							SELECT	TOP 1 @RPID=RP_ID, @RLID=RP_RLID
							FROM	RoomPlaces
							WHERE
								RP_Type=1
								and RP_RLID in 
								(	SELECT SD_RLID 
									FROM ServiceByDate,DogovorList,RoomNumberLists 
									WHERE SD_DLKey=DL_Key and DL_DGKey=@DGKey and RL_ID=SD_RLID
										and DL_SVKey=@DLSVKey and DL_Code=@DLCode 
										and DL_DateBeg=@DLDateBeg and DL_DateEnd=@DLDateEnd
										and RL_RMKey=@RMKey and RL_RCKey=@RCKey
								)
								and not exists 
								(	SELECT SD_RPID FROM ServiceByDate WHERE SD_RLID=RP_RLID and SD_RPID=RP_ID)
							ORDER BY RP_ID
						END
						IF @RPID is null	-- надо создавать новый номер даже для дополнительного размещения
						BEGIN
							INSERT INTO RoomNumberLists(RL_NPlaces, RL_NPlacesEx, RL_RMKey, RL_RCKey) values (@RLPlacesMain, @RLPlacesEx, @RMKey, @RCKey)
							set @RLID=SCOPE_IDENTITY()
							INSERT INTO RoomPlaces (RP_RLID, RP_Type)
							SELECT @RLID, CASE WHEN NU_ID>@RLPlacesMain THEN 1 ELSE 0 END FROM NUMBERS WHERE NU_ID between 1 and (@RLPlacesMain+@RLPlacesEx)
							set @RPID=SCOPE_IDENTITY()-@RLPlacesEx+1
							SET @RL_FreeMainPlacesCount = @RLPlacesMain
							SET @RL_FreeExPlacesCount = @RLPlacesEx
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
				
				
				set @TUKey=null
				SELECT @TUKey=TU_TUKey FROM dbo.TuristService WHERE TU_DLKey=@DLKey and TU_TUKey not in (SELECT SD_TUKey FROM ServiceByDate WHERE SD_DLKey=@DLKey)
				
				INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_TUKey)
					SELECT CAST((N1.NU_ID+@From-1) as datetime), @DLKey, @RLID, @RPID, @TUKey
					FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@DLDateEnd as int)-@From+1
				
				SET @NeedPlacesForMen=@NeedPlacesForMen-1
				SET @RPID=@RPID+1	
				

				End
		SET @QuoteType=null
		IF @QuoteKey is not null and @QuoteKey != 0
		BEGIN
			SELECT QT_Type 
			FROM tbl_Quotes_old,DogovorQuotes_old
			WHERE dq_dlkey=qt_key and DQ_DLKEY=@DLKEY
			SET @TempType=@QuoteType-2 --передаем в хранимку (последний параметр) -1 для Allotment, -2 для коммитмента
			--в этой хранимке будет выполнена попытка постановки услуги на квоту
			EXEC DogListToQuotas @DLKey,null,null,null,null,@DLDateBeg, @DLDateEnd,null,@TempType
		END
		ELSE
			EXEC DogListToQuotas @DLKey,null,null,null,null,@DLDateBeg, @DLDateEnd,null,4	-- если услуга была не на квоте, то ставим ее на Request
		INSERT INTO dbo.DLConverted (DC_DLKey,DC_QuoteType) values (@DLKey,@QuoteType)
	--EXEC DogListToQuotas @DLKey 
	FETCH NEXT FROM cur_DogovorListhotel
		INTO @DLKey, @DGKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey, @HRMain

END

CLOSE cur_DogovorListhotel
DEALLOCATE   cur_DogovorListhotel

if exists (select * from systemsettings where SS_ParmName='SYSCheckQuotaRelease')
	update systemsettings set SS_ParmValue=0 where SS_ParmName = 'SYSCheckQuotaRelease';	

-- %%%%%%%% AleXK включаем триггеры которые пишут в  историю %%%%%%%%
ENABLE Trigger [T_SystemSettingsUpdate] ON systemsettings;
--ENABLE Trigger [T_ServiceByDateChanged] ON ServiceByDate;
ENABLE TRIGGER [T_QuotaPartsChange] ON [QuotaParts];
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
GO

GRANT EXECUTE ON [dbo].[ConvertQuotesPlaces] TO PUBLIC 

GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DogListToQuotas]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DogListToQuotas]

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
						if exists (select SS_ParmValue from systemsettings where SS_ParmName=''SYSCheckQuotaRelease'' and SS_ParmValue=1)
							SET @DATETEMP=''01-JAN-1900''
						IF @prev=1'
		Set @Query = @Query + '	SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release FROM QuotaParts QP1, QuotaDetails QD1, Quotas QT1, QuotaObjects
								WHERE ' + @SubQuery + ' and QD_Date=DATEADD(DAY,@n1-1,@CurrentDate)
									and (QP_Places-QP_Busy)>0 and QP_Durations=@durations_prev and QD_Release=@release_prev
									and not exists (SELECT SS_ID FROM StopSales WHERE SS_QDID=QD_ID and SS_QOID=QO_ID and SS_Date=DATEADD(DAY,@n1-1,@CurrentDate) and (SS_IsDeleted is null or SS_IsDeleted=0))
									and not exists (SELECT QP_ID FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2 
									WHERE ' + @SubQuery + ' and QD2.QD_Date=''' + CAST(@Q_DateFirst as varchar(20)) + '''
										and QD2.QD_Release=QD1.QD_Release and QP2.QP_Durations=QP1.QP_Durations and (QP_IsNotCheckIn=1 or QP_CheckInPlaces-QP_CheckInPlacesBusy <= 0))
										and QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,0)			
								ORDER BY ISNULL(QD_Release,0) DESC
			ELSE'
		Set @Query = @Query + '	SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release FROM QuotaParts QP1, QuotaDetails QD1, Quotas QT1, QuotaObjects
								WHERE ' + @SubQuery + ' and QD_Date=DATEADD(DAY,@n1-1,@CurrentDate)
									and (QP_Places-QP_Busy)>0 
									and not exists (SELECT SS_ID FROM StopSales WHERE SS_QDID=QD_ID and SS_QOID=QO_ID and SS_Date=DATEADD(DAY,@n1-1,@CurrentDate) and (SS_IsDeleted is null or SS_IsDeleted=0))
									and not exists (SELECT QP_ID FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2 
									WHERE ' + @SubQuery + ' and QD2.QD_Date=''' + CAST(@Q_DateFirst as varchar(20)) + '''
										and QD2.QD_Release=QD1.QD_Release and QP2.QP_Durations=QP1.QP_Durations and (QP_IsNotCheckIn=1 or QP_CheckInPlaces-QP_CheckInPlacesBusy <= 0))
										and QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,0)
								ORDER BY ISNULL(QD_Release,0) DESC

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
					UPDATE ServiceByDate SET SD_State=' + CAST(@Q_Type as varchar(1)) + ', SD_QPID=(SELECT SK_QPID FROM @ServiceKeys WHERE SK_Date=SD_Date and SK_Key=' + CASE @Q_ByRoom WHEN 1 THEN 'SD_RLID' ELSE 'SD_RPID' END +')
						WHERE SD_DLKey=' + CAST(@DLKey as varchar(10)) +' and ' + CASE @Q_ByRoom WHEN 1 THEN 'SD_RLID' ELSE 'SD_RPID' END +'=@SK_Current and SD_State is null
				SET @SK_Current=null	
				SELECT @SK_Current=MIN(SK_Key) FROM @ServiceKeys WHERE SK_QPID is null
			END'
--	print @Query
	exec (@Query)

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
GRANT EXECUTE ON [dbo].[DogListToQuotas] TO PUBLIC 

 GO

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
					TMP_ByRoom bit, TMP_Release smallint, TMP_Partner int, TMP_Durations varchar(25), TMP_FilialKey int, 
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
if exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSCheckQuotaRelease' and SS_ParmValue=1)
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


-- Version92.sql
-- для версии 2007.2
update [dbo].[setting] set st_version = '9.2.7', st_moduledate = convert(datetime, '2010-06-15', 120),  st_financeversion = '9.2.7', st_financedate = convert(datetime, '2010-06-15', 120) where st_version like '9.%'
GO
UPDATE dbo.SystemSettings SET SS_ParmValue='2010-06-15' WHERE SS_ParmName='SYSScriptDate'
GO

