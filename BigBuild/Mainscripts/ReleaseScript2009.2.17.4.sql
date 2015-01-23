/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 27.08.2013 19:12 %%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*********************************************************************/
/* begin (2012.12.04)_Create_Table_DogovorListNeedQuoted.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogovorListNeedQuoted]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[DogovorListNeedQuoted](
		[DLQ_Id] [int] IDENTITY(1,1) NOT NULL,
		[DLQ_DLKey] [int] NOT NULL,
		[DLQ_Date] [datetime] NOT NULL,
		[DLQ_State] [int] NOT NULL,
		[DLQ_Host] [nvarchar](255) NULL,
		[DLQ_User] [nvarchar](255) NULL,
	 CONSTRAINT [PK_DogovorListNeedQuoted] PRIMARY KEY CLUSTERED 
	(
		[DLQ_Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[DogovorListNeedQuoted]  WITH CHECK ADD  CONSTRAINT [FK_DogovorListNeedQuoted_tbl_DogovorList] FOREIGN KEY([DLQ_DLKey])
	REFERENCES [dbo].[tbl_DogovorList] ([DL_KEY])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[DogovorListNeedQuoted] CHECK CONSTRAINT [FK_DogovorListNeedQuoted_tbl_DogovorList]

	ALTER TABLE [dbo].[DogovorListNeedQuoted] ADD  CONSTRAINT [DF_DogovorListNeedQuoted_DLQ_Date]  DEFAULT (getdate()) FOR [DLQ_Date]
end
go
grant select, insert, update, delete on [dbo].[DogovorListNeedQuoted] to public
go
/*********************************************************************/
/* end (2012.12.04)_Create_Table_DogovorListNeedQuoted.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DogListToQuotas.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogListToQuotas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogListToQuotas]
GO
CREATE PROCEDURE [dbo].[DogListToQuotas]
(
	--<VERSION>2009.2.33</VERSION>
	--<DATA>15.05.2013</DATA>
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
	@SetQuotaDateFirst datetime = null,
	@SetOkIfRequest bit = 0, -- запуск из тригера T_UpdDogListQuota
	@OldSetToQuota bit = 0 -- запустить старый механизм посадки
) 
AS

--insert into Debug (db_n1, db_n2, db_n3) values (@DLKey, @SetQuotaType, 999)
declare @SVKey int, @Code int, @SubCode1 int, @PRKey int, @AgentKey int, @DgKey int,
		@TourDuration int, @FilialKey int, @CityDepartment int,
		@ServiceDateBeg datetime, @ServiceDateEnd datetime, @Pax smallint, @IsWait smallint,@SVQUOTED smallint,
		@SdStateOld int, @SdStateNew int, @nHIID int, @dgCode nvarchar(10), @dlName nvarchar(max)
		
declare @sOldValue nvarchar(max), @sNewValue nvarchar(max)

DECLARE @dlControl int

-- если включена настройка то отрабатывает новый метод посадки и рассадки в квоту
if exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota' and SS_ParmValue = 1) and @OldSetToQuota = 0
begin
	-- запоминаем старый статус услуги
	select @SdStateOld = max(SD_State) from ServiceByDate where SD_DLKey = @DLKey

	declare @result int
	select @result = [dbo].WcfSetServiceToQuota(@DLKey, @SetQuotaType)
	
	-- находим новый статус
	select @SdStateNew = max(SD_State) from ServiceByDate where SD_DLKey = @DLKey

	-- устанавливаем новый статус
	Declare @dlControlNew int
	exec SetServiceStatusOk @DLKey, @dlControlNew output

	-- запись в историю, только если статус услуги поменялся
	if exists(select top 1 1 from SystemSettings where SS_ParmName like 'SYSServiceStatusToHistory' and SS_ParmValue = '1') and @SdStateOld != @SdStateNew
	begin
		IF ISNULL(@SdStateOld, 0) = 0
			SET @sOldValue = ''
		ELSE IF @SdStateOld = 1
			SET @sOldValue = 'Allotment'
		ELSE IF @SdStateOld = 2
			SET @sOldValue = 'Commitment'
		ELSE IF @SdStateOld = 3
			SET @sOldValue = 'Confirmed'
		ELSE IF @SdStateOld = 4
			SET @sOldValue = 'Wait'

		IF ISNULL(@SdStateNew, 0) = 0
			SET @sNewValue = ''
		ELSE IF @SdStateNew = 1
			SET @sNewValue = 'Allotment'
		ELSE IF @SdStateNew = 2
			SET @sNewValue = 'Commitment'
		ELSE IF @SdStateNew = 3
			SET @sNewValue = 'Confirmed'
		ELSE IF @SdStateNew = 4
			SET @sNewValue = 'Wait'

		EXEC @nHIID = dbo.InsHistory @dgCode, @DgKey, 19, '', 'UPD', @dlName, '', 0, ''
		EXECUTE dbo.InsertHistoryDetail @nHIID, 19001, @sOldValue, @sNewValue, @SdStateOld, @SdStateNew, '', '', 0
	end

	return;
end

SELECT	@SVKey=DL_SVKey, @Code=DL_Code, @SubCode1=DL_SubCode1, @PRKey=DL_PartnerKey, 
		@ServiceDateBeg=DL_DateBeg, @ServiceDateEnd=DL_DateEnd, @Pax=DL_NMen,
		@AgentKey=DG_PartnerKey, @TourDuration=DG_NDay, @FilialKey=DG_FilialKey, @CityDepartment=DG_CTDepartureKey, @IsWait=ISNULL(DL_Wait,0),
		@DgKey = DL_DGKEY,
		@dgCode = DG_CODE,
		@dlName = DL_NAME
FROM	DogovorList join Dogovor on DL_DGKey = DG_Key
WHERE	DL_Key = @DLKey

-- сохраним старое значение квотируемости
select @SdStateOld = MAX(SD_State)
from ServiceByDate
where SD_DLKey = @DLKey

if @IsWait=1 and (@SetQuotaType in (1,2) or @SetQuotaType is null)  --Установлен признак "Не снимать квоту при бронировании". На квоту не ставим
BEGIN
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
	begin
		exec SetStatusInRoom @dlkey
	end
	return 0
END
SELECT @SVQUOTED=isnull(SV_Quoted,0) from service where sv_key=@SVKEY
if @SVQUOTED=0
BEGIN
	UPDATE ServiceByDate SET SD_State=3 WHERE SD_DLKey=@DLKey	
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
	begin
		exec SetStatusInRoom @dlkey
	end
	return 0
END

-- ДОБАВЛЕНА НАСТРОЙКА ЗАПРЕЩАЮЩАЯ СНЯТИЕ КВОТЫ ДЛЯ УСЛУГИ, 
-- ТАК КАК В КВОТАХ НЕТ РЕАЛЬНОЙ ИНФОРМАЦИИ, А ТОЛЬКО ПРИЗНАК ИХ НАЛИЧИЯ (ПЕРЕДАЕТСЯ ИЗ INTERLOOK)
IF (@SetQuotaType in (1,2) or @SetQuotaType is null) and  EXISTS (SELECT 1 FROM dbo.SystemSettings WHERE SS_ParmName='IL_SyncILPartners' and SS_ParmValue LIKE '%/' + CAST(@PRKey as varchar(20)) + '/%')
BEgin
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
	begin
		exec SetStatusInRoom @dlkey
	end
	return 0
End

-- проверим если это доп место в комнате, то ее нельзя посадить в квоты, сажаем внеквоты и эта квота за человека
if exists(select 1 from systemsettings where ss_parmname='SYSSetQuotaForAddPlaces' and SS_ParmValue=1)
begin
set @SetQuotaByRoom=0
	if ( exists (select top 1 1 from ServiceByDate join RoomPlaces on SD_RPID = RP_ID where SD_DLKey = @DLKey and RP_Type = 1) and (@SetQuotaByRoom = 0))
	begin
		set @SetQuotaType = 3
	end
end

/*
If @SVKey=3
	SELECT TOP 1 @Quota_SubCode1=HR_RMKey, @Quota_SubCode2=HR_RCKey FROM HotelRooms WHERE HR_Key=@SubCode1
Else
	Set @Quota_SubCode1=@SubCode1
*/
declare @Q_Count smallint, @Q_AgentKey int, @Q_Type smallint, @Q_ByRoom bit, 
		@Q_PRKey int, @Q_FilialKey int, @Q_CityDepartments int, @Q_Duration smallint, @Q_DateBeg datetime, @Q_DateEnd datetime, @Q_DateFirst datetime, @Q_SubCode1 int, @Q_SubCode2 int,
		@Query nvarchar(max), @SubQuery varchar(1500), @Current int, @CurrentString varchar(50), @QTCount_Need smallint, @n smallint, @n2 smallint, @Result_Exist bit, @nTemp smallint, @Quota_CheckState smallint, @dTemp datetime

--karimbaeva 19-04-2012  по умолчанию если не хватает квот на всех туристов, то ставим их всех на запрос, если установлена настройка 
-- SYSSetQuotaToTourist - 1 - ставим туристов на запрос, 0- снимаем квоты на кого хватает, остальных ставим на запрос
if not exists(select 1 from systemsettings where ss_parmname='SYSSetQuotaToTourist' and SS_ParmValue=0)
begin
	If exists (SELECT top 1 1 FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_State is null)
	BEGIN
		declare @QT_ByRoom_1 bit
		create table #DlKeys_1
		(
			dlKey int
		)
		
		insert into #DLKeys_1
			select dl_key 
			from dogovorlist 
			where dl_dgkey in (
								select dl_dgkey 
								from dogovorlist 
								where dl_key = @DLKey
							   )
			and dl_svkey = 3
			
			SELECT @QT_ByRoom_1=QT_ByRoom FROM Quotas,QuotaDetails,QuotaParts WHERE QD_QTID=QT_ID and QD_ID=QP_QDID 
			and QP_ID = (select top 1 SD_QPID
						from ServiceByDate join RoomPlaces on SD_RLID = RP_RLID  
						where RP_Type = 0 and sd_dlkey in (select dlKey from #DlKeys_1) and SD_RLID = (select TOP 1 SD_RLID from ServiceByDate where sd_dlkey=@DlKey))
			
			
			if (@QT_ByRoom_1=0 or @QT_ByRoom_1 is null)
			begin	
				SET @Q_DateBeg=@ServiceDateBeg
				SET @Q_DateEnd=@ServiceDateEnd
				SET @Q_DateFirst=@ServiceDateBeg
			
				EXEC dbo.[CheckQuotaExist] @SVKey, @Code, @SubCode1, @Q_DateBeg,
						@Q_DateEnd, @Q_DateFirst, @PRKey, @AgentKey, @TourDuration, 
						@FilialKey,	@CityDepartment, 2, @Pax,@IsWait, 
						@Quota_CheckState output, @dTemp output, @nTemp output,
						@Q_Count output, @Q_AgentKey output, @Q_Type output, @Q_ByRoom output, @Q_PRKey output, 
						@Q_FilialKey output, @Q_CityDepartments output,	@Q_Duration output, @Q_SubCode1 output, @Q_SubCode2 output
								
				if @Quota_CheckState = 0	
				begin
					UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
					-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
					if @SetQuotaByRoom = 0
					begin
						exec SetStatusInRoom @dlkey
					end
					
					EXEC dbo.SetServiceStatusOk @DlKey,@dlControl

					return 0
				end	
			end	
	END
end 

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
	begin
		-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
		if @SetQuotaByRoom = 0
		begin
			exec SetStatusInRoom @dlkey
		end
		-- запускае хранимку на установку статуса путевки
		--exec SetReservationStatus @DgKey
		return 0
	end

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

If not exists (SELECT top 1 1 FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_State is null)
	print 'WARNING_DogListToQuotas_1'
If @Q_Count is null
	print 'WARNING_DogListToQuotas_2'
If @Result_Exist > 0
	print 'WARNING_DogListToQuotas_3'

WHILE exists (SELECT top 1 1 FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_State is null) and @n<5 and (@Q_Count is not null or @Result_Exist=0)
BEGIN
	--print @n
	set @n=@n+1
	Set @SubQuery = ' QT_ID=QD_QTID and QP_QDID=QD_ID
				and QD_Date = QP_Date
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
						-- Разрешим посадить в квоту с релиз периодом 0 текущим числом
						set @DATETEMP = DATEADD(day, -1, @DATETEMP)
						if exists (select top 1 1 from systemsettings where SS_ParmName=''SYSCheckQuotaRelease'' and SS_ParmValue=1) OR exists (select top 1 1 from systemsettings where SS_ParmName=''SYSAddQuotaPastPermit'' and SS_ParmValue=1 and ''' + CAST(@Q_DateFirst as varchar(20)) + ''' < @DATETEMP)
							SET @DATETEMP=''10-JAN-1900''
						IF @prev=1'
		Set @Query = @Query + '	SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release
								FROM QuotaParts QP1, QuotaDetails QD1, Quotas QT1, QuotaObjects
								WHERE ' + @SubQuery + ' and QD_Date=DATEADD(DAY,@n1-1,@CurrentDate)
									and (QP_Places-QP_Busy)>0 and QP_Durations=@durations_prev and QD_Release=@release_prev
									and (	isnull(QP_Durations, '''') = '''' 
											or (isnull(QP_Durations, '''') != '''' and (QP_IsNotCheckIn = 1 or QP_CheckInPlaces - QP_CheckInPlacesBusy > 0)) 
											or (isnull(QP_Durations, '''') != '''' and (QP_IsNotCheckIn = 0 or QP_Places - QP_Busy > 0))
											or (isnull(QP_Durations, '''') != '''' and QD_Date = ''' + CAST(@Q_DateFirst as varchar(20)) + ''')
										)
									and ((QP_IsNotCheckIn = 0) 
											or (QP_IsNotCheckIn = 1 
												and exists (select top 1 1 
															from QuotaDetails as tblQD
															where exists (select top 1 1 
																			from QuotaParts as tblQP 
																			where tblQP.QP_QDID = tblQD.QD_ID
																			and tblQP.QP_Date = tblQD.QD_Date
																			and tblQP.QP_IsNotCheckIn = 0)
															and tblQD.QD_Date = ''' + CAST(@Q_DateFirst as varchar(20)) + '''
															and tblQD.QD_QTID = QD1.QD_QTID)))
									and not exists (SELECT top 1 1 FROM StopSales WHERE SS_QDID=QD_ID and SS_QOID=QO_ID and SS_Date=DATEADD(DAY,@n1-1,@CurrentDate) and (SS_IsDeleted is null or SS_IsDeleted=0))
									and not exists (SELECT top 1 1 FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2 
									WHERE ' + @SubQuery + ' and QD2.QD_Date=''' + CAST(@Q_DateFirst as varchar(20)) + '''
										and ISNULL(QD2.QD_Release,0)=ISNULL(QD1.QD_Release,0) and QP2.QP_Durations=QP1.QP_Durations and (QP_IsNotCheckIn=1 or QP_CheckInPlaces-QP_CheckInPlacesBusy <= 0))
										and (QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1) OR (QD1.QD_Date < getdate() - 1))
								ORDER BY ISNULL(QD_Release,0) DESC, (select count(distinct QD_QTID) 
																	from QuotaDetails as QDP join QuotaParts as QPP on QDP.QD_ID = QPP.QP_QDID and QDP.QD_Date = QPP.QP_Date
																	where exists (select top 1 1 from @ServiceKeys as SKP where SKP.SK_QPID = QPP.QP_ID)
																	and QDP.QD_QTID = QD1.QD_QTID) DESC
			ELSE'
		Set @Query = @Query + '	SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release
								FROM QuotaParts QP1, QuotaDetails QD1, Quotas QT1, QuotaObjects
								WHERE ' + @SubQuery + ' and QD_Date=DATEADD(DAY,@n1-1,@CurrentDate)
									and (QP_Places-QP_Busy)>0 
									and (	isnull(QP_Durations, '''') = '''' 
											or (isnull(QP_Durations, '''') != '''' and (QP_IsNotCheckIn = 1 or QP_CheckInPlaces - QP_CheckInPlacesBusy > 0)) 
											or (isnull(QP_Durations, '''') != '''' and (QP_IsNotCheckIn = 0 or QP_Places - QP_Busy > 0))
											or (isnull(QP_Durations, '''') != '''' and QD_Date = ''' + CAST(@Q_DateFirst as varchar(20)) + ''')
										)
									and ((QP_IsNotCheckIn = 0) 
											or (QP_IsNotCheckIn = 1 
												and exists (select top 1 1 
															from QuotaDetails as tblQD
															where exists (select top 1 1 
																			from QuotaParts as tblQP 
																			where tblQP.QP_QDID = tblQD.QD_ID
																			and tblQP.QP_Date = tblQD.QD_Date
																			and tblQP.QP_IsNotCheckIn = 0)
															and tblQD.QD_Date = ''' + CAST(@Q_DateFirst as varchar(20)) + '''
															and tblQD.QD_QTID = QD1.QD_QTID)))
									and not exists (SELECT top 1 1 FROM StopSales WHERE SS_QDID=QD_ID and SS_QOID=QO_ID and SS_Date=DATEADD(DAY,@n1-1,@CurrentDate) and (SS_IsDeleted is null or SS_IsDeleted=0))
									and not exists (SELECT top 1 1 FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2
									WHERE ' + @SubQuery + ' and QD2.QD_Date=''' + CAST(@Q_DateFirst as varchar(20)) + '''
										and ISNULL(QD2.QD_Release,0)=ISNULL(QD1.QD_Release,0) and QP2.QP_Durations=QP1.QP_Durations and (QP_IsNotCheckIn=1 or QP_CheckInPlaces-QP_CheckInPlacesBusy <= 0))
										and (QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1) OR (QD1.QD_Date < getdate() - 1))
								ORDER BY ISNULL(QD_Release,0) DESC, (select count(distinct QD_QTID) 
																	from QuotaDetails as QDP join QuotaParts as QPP on QDP.QD_ID = QPP.QP_QDID and QDP.QD_Date = QPP.QP_Date
																	where exists (select top 1 1 from @ServiceKeys as SKP where SKP.SK_QPID = QPP.QP_ID)
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
					UPDATE ServiceByDate SET SD_State=' + CAST(@Q_Type as varchar(1)) + ', SD_QPID=(SELECT SK_QPID FROM @ServiceKeys WHERE SK_Date=SD_Date and SK_Key=' + CASE @Q_ByRoom WHEN 1 THEN 'SD_RLID' ELSE 'SD_RPID' END +')
						WHERE SD_DLKey=' + CAST(@DLKey as varchar(10)) +' and ' + CASE @Q_ByRoom WHEN 1 THEN 'SD_RLID' ELSE 'SD_RPID' END +'=@SK_Current and SD_State is null
				end
				SET @SK_Current=null	
				SELECT @SK_Current=MIN(SK_Key) FROM @ServiceKeys WHERE SK_QPID is null
			END'
	--print @Query	
	exec (@Query)
		
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
	begin
		exec SetStatusInRoom @dlkey
	end

	--если @SetQuotaType is null -значит это начальная постановка услги на квоту и ее надо делать столько раз
	--сколько номеров или людей в услуге.
	If @SetQuotaType is null or @SetQuotaType<0 --! @SetQuotaType<0 <--при переходе на 2008.1
	BEGIN		
		If exists (SELECT top 1 1 FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_State is null)
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

if exists(select top 1 1 from ServiceByDate where SD_DLKey=@DLKey and SD_State is null) 
begin
	exec SetStatusInRoom @dlkey
end

UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null

-- сохраним новое значение квотируемости
select @SdStateNew = MAX(SD_State)
from ServiceByDate
where SD_DLKey = @DLKey

-- запись в историю
if exists(select top 1 1 from SystemSettings where SS_ParmName like 'SYSServiceStatusToHistory' and SS_ParmValue = '1')
begin
	IF ISNULL(@SdStateOld, 0) = 0
		SET @sOldValue = ''
	ELSE IF @SdStateOld = 1
		SET @sOldValue = 'Allotment'
	ELSE IF @SdStateOld = 2
		SET @sOldValue = 'Commitment'
	ELSE IF @SdStateOld = 3
		SET @sOldValue = 'Confirmed'
	ELSE IF @SdStateOld = 4
		SET @sOldValue = 'Wait'

	IF ISNULL(@SdStateNew, 0) = 0
		SET @sNewValue = ''
	ELSE IF @SdStateNew = 1
		SET @sNewValue = 'Allotment'
	ELSE IF @SdStateNew = 2
		SET @sNewValue = 'Commitment'
	ELSE IF @SdStateNew = 3
		SET @sNewValue = 'Confirmed'
	ELSE IF @SdStateNew = 4
		SET @sNewValue = 'Wait'

	EXEC @nHIID = dbo.InsHistory @dgCode, @DgKey, 19, '', 'UPD', @dlName, '', 0, ''
	EXECUTE dbo.InsertHistoryDetail @nHIID, 19001, @sOldValue, @sNewValue, @SdStateOld, @SdStateNew, '', '', 0
end

-- 2012-10-12 tkachuk, task 8473 - меняем статус для услуг, привязанных к изменившимся квотам
EXEC dbo.SetServiceStatusOk @DlKey,@dlControl

GO
grant exec on [dbo].[DogListToQuotas] to public
go


/*********************************************************************/
/* end sp_DogListToQuotas.sql */
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
--<VERSION>2009.2.17.2</VERSION>
--<DATE>2013-02-26</DATE>
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
	--18-10-2012 saifullina
	--при удалении услуги в путевке или аннулировании путевки -> удаляем путевку -> высвобождаем квоты
	IF @N_DLDateBeg < '01-JAN-1901' and @O_DLDateBeg >= '01-JAN-1901'
		SET @Mod='DEL'
	IF @Mod='DEL' or (@Mod='UPD' and 
			(ISNULL(@O_DLSVKey,0) != ISNULL(@N_DLSVKey,0)) or (ISNULL(@O_DLCode,0) != ISNULL(@N_DLCode,0)) 
			or (ISNULL(@O_DLSubCode1,0) != ISNULL(@N_DLSubCode1,0)) or (ISNULL(@O_DLPartnerKey,0) != ISNULL(@N_DLPartnerKey,0)) 
			or (ISNULL(@O_DLDateBeg,0) != ISNULL(@N_DLDateBeg,0)) or (ISNULL(@O_DLDateEnd,0) != ISNULL(@N_DLDateEnd,0)))
		BEGIN	
			DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey
			SET @SetToNewQuota=1
		END
		
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
	
	-- признак того что произошла ошибка при запуске сервиса
	declare @errorNewSetToQuota bit
	set @errorNewSetToQuota = 0	
	
	-- если ВКЛЮЧЕНА настройка то запускаем DogListToQuotas, в ней уже есть новая рассадка
	if exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota' and SS_ParmValue = 1)
	begin
		print 'Новая рассадка'
		print 'exec dbo.DogListToQuotas ' + convert(nvarchar(max), @DLKey) + ', @OldSetToQuota = 0'
		
		IF @Mod='INS' or (@Mod='UPD' and @SetToNewQuota=1)
		begin
			-- Указывает, выполняет ли SQL Server автоматический откат текущей транзакции, если инструкция языка Transact-SQL вызывает ошибку выполнения.
			SET XACT_ABORT OFF
			
			begin try
				exec dbo.DogListToQuotas @DLKey, @OldSetToQuota = 0
			end try
			begin catch			
				print 'Произошла ошибка при посадке новм методом, запускаем старый метод'
				set @errorNewSetToQuota = 1
			end catch
		end
	end
		
	-- если ВЫКЛЮЧЕНА настройка то запускаем всю эту дребедень, это старая рассадка в квоту
	-- ИЛИ произошла ошибка при посадке новым сервисом, то запускаем старую рассадку и проверку
	if (exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota' and SS_ParmValue = 0)
	or @errorNewSetToQuota = 1)
	begin
		print 'Старая рассадка'
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
				EXEC DogListToQuotas @DLKey, null, null, null, null, @N_DLDateBeg, @N_DLDateEnd, null, null, @OldSetToQuota = 1
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
						DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_RLID=@RLID and ISNULL(SD_RPID,0)=ISNULL(@RPID,0) and SD_TUKey is null
					END
					ELSE
					BEGIN
						SELECT TOP 1 @RPID=SD_RPID FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_TUKey is null
						DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey and ISNULL(SD_RPID,0)=ISNULL(@RPID,0) and SD_TUKey is null
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
								IF @RPID is null	-- надо создавать новый номер даже для дополнительного размещения
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
									set @RPID = SCOPE_IDENTITY()
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
					SELECT @TUKey=TU_TUKey FROM dbo.TuristService WHERE TU_DLKey=@DLKey and TU_TUKey not in (SELECT SD_TUKey FROM ServiceByDate WHERE SD_DLKey=@DLKey)
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
		print 'exec dbo.DogListToQuotas ' + convert(nvarchar(max), @DLKey)
		exec dbo.DogListToQuotas @DLKey, @OldSetToQuota = 1
		END
	end
	
	FETCH NEXT FROM cur_DogovorListChanged2 
		INTO	@DLKey, @DGKey,
				@O_DLSVKey, @O_DLCode, @O_DLSubCode1, @O_DLDateBeg, @O_DLDateEnd, @O_DLNMen, @O_DLPartnerKey, @O_DLControl,
				@N_DLSVKey, @N_DLCode, @N_DLSubCode1, @N_DLDateBeg, @N_DLDateEnd, @N_DLNMen, @N_DLPartnerKey, @N_DLControl
END
CLOSE cur_DogovorListChanged2
DEALLOCATE cur_DogovorListChanged2

GO


/*********************************************************************/
/* end T_UpdDogListQuota.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_QuotaDetailsAfterDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetailAfterDelete]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[QuotaDetailAfterDelete]
GO

CREATE PROCEDURE [dbo].[QuotaDetailAfterDelete]
AS
--<VERSION>2008.1.01.06</VERSION>
--2012.10.30
--Процедура освобождает удаленные квоты
--QD_IsDeleted хранит статус, в который требуется поставить услуги, на данный момент находящиеся на данной квоте
--QD_IsDeleted=3 - подтвердить (ВАЖНО подтверждается только те даты которые удаляются)
--QD_IsDeleted=4 - Request (ВАЖНО на Request только те даты которые удаляются)
--QD_IsDeleted=1 - попытка поставить на квоту (ВАЖНО на квоту пробуем поставить место, на всем протяжении услуги, то есть - если это проживание и только один день удаляем из квоты, то место снимается с квоты целиком и пытается сесть снова)

DECLARE @SD_DLKey int

IF Exists (SELECT top 1 1 FROM QuotaDetails with (nolock),QuotaParts with (nolock),ServiceByDate with (nolock) WHERE QP_QDID=QD_ID and SD_QPID=QP_ID and QD_IsDeleted in (3,4))
BEGIN
	declare @DLKeysForUpdare table
	(
		DL_Key int
	)
	
	insert into @DLKeysForUpdare(DL_Key) select SD_DLKey from ServiceByDate,QuotaParts where QP_ID = SD_QPID and QP_IsDeleted in (3,4)

	UPDATE ServiceByDate with (rowlock) SET SD_State=3,SD_QPID=null WHERE SD_QPID in (SELECT QP_ID FROM QuotaDetails with (nolock),QuotaParts with (nolock) WHERE QP_QDID=QD_ID and QD_IsDeleted=3)
	UPDATE ServiceByDate with (rowlock) SET SD_State=4,SD_QPID=null WHERE SD_QPID in (SELECT QP_ID FROM QuotaDetails with (nolock),QuotaParts with (nolock) WHERE QP_QDID=QD_ID and QD_IsDeleted=4)
	
	DECLARE cur_QuotaDetailDelete CURSOR FOR 
		SELECT DISTINCT DL_Key FROM @DLKeysForUpdare
	OPEN cur_QuotaDetailDelete
	FETCH NEXT FROM cur_QuotaDetailDelete INTO @SD_DLKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC dbo.DogListToQuotas @SD_DLKey, 1
		FETCH NEXT FROM cur_QuotaDetailDelete INTO @SD_DLKey
	END
	CLOSE cur_QuotaDetailDelete
	DEALLOCATE cur_QuotaDetailDelete
END

IF Exists (SELECT top 1 1 FROM QuotaDetails with (nolock),QuotaParts with (nolock),ServiceByDate with (nolock) WHERE QP_QDID=QD_ID and SD_QPID=QP_ID and QD_IsDeleted in (1))
BEGIN
	DECLARE cur_QuotaDetailDelete CURSOR FOR 
		SELECT DISTINCT SD_DLKey FROM ServiceByDate with (nolock) WHERE SD_QPID in (SELECT QP_ID FROM QuotaDetails with (nolock),QuotaParts with (nolock) WHERE QP_QDID=QD_ID and QD_IsDeleted=1)
	OPEN cur_QuotaDetailDelete
	FETCH NEXT FROM cur_QuotaDetailDelete INTO @SD_DLKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC dbo.DogListToQuotas @SD_DLKey, 1
		FETCH NEXT FROM cur_QuotaDetailDelete INTO @SD_DLKey
	END
	CLOSE cur_QuotaDetailDelete
	DEALLOCATE cur_QuotaDetailDelete
END

update QuotaParts set QP_IsDeleted = 1 from QuotaParts join QuotaDetails on QP_QDID = QD_ID where QD_IsDeleted in (1,3,4)

DELETE FROM QuotaLimitations with (rowlock) WHERE QL_QPID in (SELECT QP_ID FROM QuotaParts with (nolock), QuotaDetails with (nolock) WHERE QD_ID=QP_QDID and QD_IsDeleted in (1,3,4))
DELETE QuotaParts with (rowlock) where exists(select top 1 1 from QuotaDetails with (nolock) WHERE QD_IsDeleted in (1,3,4) and QD_ID = QP_QDID) and not exists(select top 1 1 from ServiceByDate with(nolock) where SD_QPID=QP_ID) and QP_IsDeleted = 1
DELETE FROM StopSales with (rowlock) WHERE SS_QDID in (SELECT QD_ID FROM QuotaDetails with (nolock) WHERE QD_IsDeleted in (1,3,4))
DELETE FROM QuotaDetails with (rowlock) WHERE QD_IsDeleted in (1,3,4) and QD_ID not in (Select QP_QDID from ServiceByDate with (nolock), QuotaParts with (nolock) where SD_QPID=QP_ID and QP_QDID=QD_ID)

GO

grant exec on [dbo].[QuotaDetailAfterDelete] to public
go
/*********************************************************************/
/* end sp_QuotaDetailsAfterDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DogovorMonitor.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogovorMonitor]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogovorMonitor]
GO

CREATE PROCEDURE [dbo].[DogovorMonitor]
  (
--<VERSION>2009.2.13</VERSION>
--<DATE>2012-07-05</DATE>
	@dtStartDate datetime,			-- начальная дата просмотра изменений
	@dtEndDate datetime,			-- конечная дата просмотра изменений
	@nCountryKey int,				-- ключ страны
	@nCityKey int,					-- ключ города
	@nDepartureCityKey int,			-- ключ города вылета
	@nCreatorKey int,				-- ключ создателя
	@nOwnerKey int,					-- ключ ведущего менеджера
	@nViewProceed smallint,			-- не показывать обработанные: 0 - показывать, 1 - не показывать
	@sFilterKeys varchar(255),		-- ключи выбранных фильтров
	@nFilialKey int,				-- ключ филиала
	@nBTKey int,					-- ключ типа бронирования: -1 - все, 0 - офис, 1 - онлайн
	@sLang varchar(10)				-- язык (если en, селектим поля NameLat, а не Name)
	       
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
	DM_MessageCount int,
    DM_MessageCountRead int,
	DM_MessageCountUnRead int,
	DM_AnnulReason varchar(60),
	DM_AnnulDate datetime,
	DM_PriceToPay money,
	DM_Payed money,
	DM_OrderStatus varchar(20)
)

CREATE TABLE #TempTable
(
	#dogovorCreateDate datetime,
	#lastDogovorActionDate datetime,
	#sDGCode varchar(10),
	#sCreator varchar(25),
	#dtTurDate datetime,
	#sTurName nvarchar(160),
	#sPartnerName nvarchar(80),
	#dgKey int,
	#sPaymentStatus nvarchar(4),
	#AnnulReason varchar(60),
	#PriceToPay money,
	#Payed money
)

declare @nObjectAliasFilter int, @sFilterType varchar(3)

DECLARE @dogovorCreateDate datetime, @lastDogovorActionDate datetime -- @dtHistoryDate
declare @sDGCode varchar(10), @nDGKey int
declare @sCreator varchar(25), @dtTurDate datetime, @sTurName varchar(160)
declare @sPartnerName varchar(80), @sFilterName varchar(255), @nHIID int
declare @sHistoryMod varchar(3), @sPaymentStatus as varchar(4)
declare @AnnulReason AS varchar(60), @AnnulDate AS datetime, @PriceToPay AS money, @Payed AS money

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
		
		declare @sql varchar(max)

		set @sql = N'insert into #TempTable
				select DISTINCT 
				(SELECT MIN(HI_DATE) FROM history h2 WHERE h2.HI_DGCOD = DG_CODE) AS DOGOVOR_CREATE_DATE, 
				(SELECT MAX(HI_DATE) FROM history h2 WHERE h2.HI_DGCOD = DG_CODE) AS LAST_DOGOVOR_ACTION_DATE, 
				DG_CODE, US_FullName, DG_TurDate, TL_NAME, PR_NAME, DG_KEY,
				CASE
					WHEN DG_PRICE = 0 AND DG_PAYED = DG_PRICE THEN ''OK''
					WHEN DG_PAYED = 0 THEN ''NONE''
					WHEN DG_PAYED < DG_PRICE THEN ''LOW''
					WHEN DG_PAYED = DG_PRICE THEN ''OK''
					WHEN DG_PAYED > DG_PRICE THEN ''OVER''
				END AS DM_PAYMENTSTATUS, AR_Name, 
				CASE
					WHEN DG_PDTTYPE = 1 THEN DG_PRICE + DG_DISCOUNTSUM
					ELSE DG_PRICE					
				END AS DM_PriceToPay, DG_PAYED
			from dogovor with(nolock), history with(nolock), historydetail with(nolock), userlist with(nolock), TurList with(nolock), Partners with(nolock), AnnulReasons with(nolock)
			where HI_DGCOD = DG_CODE and HI_ID = HD_HIID and US_KEY = DG_CREATOR and TL_KEY = DG_TRKEY and PR_KEY = DG_PARTNERKEY and 
				HI_DATE BETWEEN ''' + convert(varchar, @dtStartDate, 120) + ''' and dateadd(day, 1, ''' + convert(varchar, @dtEndDate, 120) + ''') and
				((' + str(@nCountryKey) + ' < 0 and DG_CNKEY in (select CN_KEY from Country with(nolock))) OR (' + str(@nCountryKey) + ' >= 0 and DG_CNKEY = ' + str(@nCountryKey) + ')) and
				(' + str(@nCityKey) + ' < 0 OR DG_CTKEY = ' + str(@nCityKey) + ') and
				(' + str(@nDepartureCityKey) + ' < 0 OR DG_CTDepartureKey = ' + str(@nDepartureCityKey) + ') and
				(' + str(@nCreatorKey) + ' < 0 OR DG_CREATOR = ' + str(@nCreatorKey) + ') and
				(' + str(@nOwnerKey) + ' < 0 OR DG_OWNER = ' + str(@nOwnerKey) + ') and
				(' + str(@nFilialKey) + ' < 0 OR DG_FILIALKEY = ' + str(@nFilialKey) + ') and
				(' + str(@nBTKey) + ' < 0 OR (' + str(@nBTKey) + ' = 0 AND DG_BTKEY is NULL) OR DG_BTKEY = ' + str(@nBTKey) + ') and
				(AR_Key = DG_ARKEY)'
				
-----------------------------------------------------------------------------------------------
-- MEG00037288 06.09.2011 Kolbeshkin: добавил алиасы 41-43 для проверки корректности путевки --
-----------------------------------------------------------------------------------------------
		DECLARE @sNotAnnuled varchar(max)
		SET @sNotAnnuled = ' and DG_TURDATE <> ''1899-12-30 00:00:00.000'' '
		SET @sql = @sql + 
		CASE 
		WHEN (@nObjectAliasFilter = 41) -- Путевка без услуг
			THEN ' and not exists (select 1 from dogovorlist where dl_dgkey = dg_key)' + @sNotAnnuled
		WHEN (@nObjectAliasFilter = 42) -- Путевка без туристов
			THEN ' and not exists (select 1 from Turist where TU_DGKEY = DG_KEY)' + @sNotAnnuled
		WHEN (@nObjectAliasFilter = 43) -- Услуги с непривязанными туристами
			THEN ' and exists (select 1 from dogovorlist where dl_dgkey = dg_key and not exists (select 1 from TuristService where tu_dlkey = dl_key))' + @sNotAnnuled
		--------- Отсутствуют обязательные(неудаляемые) услуги решено пока не делать, потому что нет прямой связи DogovorList c TurService
		--WHEN (@nObjectAliasFilter = 44) -- Отсутствуют обязательные(неудаляемые) услуги
		--	THEN ' and ((select (
		--	(select COUNT(1) from TurService ts where TS_TRKEY=dg.DG_TRKEY and TS_ATTRIBUTE % 2 = 0) -- Кол-во неудаляемых услуг в туре
		--	-
		--	(select COUNT(1) from Dogovorlist dl join TurService ts on -- Кол-во услуг попавших в путевку из неудаляемых в туре
		--	(ts.TS_TRKEY = dg.DG_TRKEY and ts.TS_ATTRIBUTE % 2 = 0
		--	and dl.DL_SVKEY = ts.TS_SVKEY and dl.DL_CODE = ts.TS_CODE
		--	) where dl.DL_DGKEY = dg.DG_Key and dl.DL_TRKEY = dg.DG_TRKEY )))
		--	> 0) ' 
		ELSE 
			 ' and (HD_OAId = ' + str(@nObjectAliasFilter) + ') 
			 and (''' + @sFilterType + '''= '''' OR HI_MOD = ''' + @sFilterType + ''')'
		END
		
-------------------------------------------------------------------------------------
-- MEG00037288 07.09.2011 Kolbeshkin: локализация. Если язык En, селектим поля LAT --
-------------------------------------------------------------------------------------
		IF @sLang like 'en'
		BEGIN
		set @sql = REPLACE(@sql,'US_FullName','US_FullNameLat')
		set @sql = REPLACE(@sql,'TL_NAME','TL_NAMELAT')
		set @sql = REPLACE(@sql,'PR_NAME','PR_NAMEENG')
		set @sql = REPLACE(@sql,'AR_Name','AR_NameLat')
		END
		--print @sql
		exec (@sql)
		
		declare dogovorsCursor cursor local fast_forward for
		select * from #TempTable

		--нашли путевки
		open dogovorsCursor
		fetch next from dogovorsCursor into @dogovorCreateDate, @lastDogovorActionDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @nDGKey, @sPaymentStatus, @AnnulReason, @PriceToPay, @Payed
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


				------ Получение даты тура до аннуляции ------
				IF (@dtTurDate = '12/30/1899')
				BEGIN
					SELECT @dtTurDate = DG_TURDATEBFRANNUL
					FROM Dogovor
					WHERE DG_Code = @sDGCode
				END
				----------------------------------------------

				SET @AnnulDate = NULL;
				------ Получение даты аннуляции ------
				SELECT @AnnulDate = History.HI_DATE
				FROM HistoryDetail
				JOIN History 
					ON HI_ID = HD_HIID
				WHERE HistoryDetail.HD_Alias = 'DG_Annulate' AND History.HI_DgCod = @sDGCode
				--------------------------------------
				
				DECLARE @notesCount int
				SELECT @notesCount = COUNT(HI_TEXT) FROM HISTORY
				WHERE HI_DGCOD = @sDGCode AND HI_MOD = 'WWW'

				DECLARE @isBilled bit
				SET @isBilled = 0
				IF EXISTS(SELECT AC_KEY FROM ACCOUNTS WHERE AC_DGCOD = @sDGCode)
					SET @isBilled = 1

				DECLARE @messageCount int, @MessageCountRead int, @MessageCountUnRead int
				SELECT @messageCount = COUNT(HI_TEXT)
			          ,@MessageCountRead = COUNT(case when HI_MessEnabled <= 1 then 1 else 0 end)
			          ,@MessageCountUnRead = COUNT(case when HI_MessEnabled >= 2 then 1 else 0 end)
			    FROM HISTORY
				WHERE HI_DGCOD = @sDGCode AND HI_MOD = 'MTM'
				AND HI_TEXT NOT LIKE 'От агента: %' -- notes from web (copies of 'WWW' moded notes)
				
				--узнаем статус путевки
				DECLARE @orderStatus varchar(20);
				select @orderStatus  = case when @sLang='en' then o.OS_NameLat else o.OS_NAME_RUS end
				from Order_Status o
				left join Dogovor d on d.DG_SOR_CODE=o.OS_CODE
				where d.DG_Key = @nDGKey

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
						VALUES (@dogovorCreateDate, @firstDogovorProcessDate, @lastDogovorProcessDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @sFilterName, @notesCount, @sPaymentStatus, @isBilled, @messageCount, @MessageCountRead , @MessageCountUnRead, @AnnulReason, @AnnulDate, @PriceToPay, @Payed,@orderStatus);
					END
				END
				-------------------

			--end
			fetch next from dogovorsCursor into @dogovorCreateDate, @lastDogovorActionDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @nDGKey, @sPaymentStatus, @AnnulReason, @PriceToPay, @Payed
		end
			
		close dogovorsCursor
		deallocate dogovorsCursor
		delete from #TempTable

		fetch next from filterCursor into @nObjectAliasFilter, @sFilterType
	end

	close filterCursor
	deallocate filterCursor
end
	SELECT *
	FROM #DogovorMonitorTable
	ORDER BY DM_CreateDate
	
	DROP TABLE #TempTable
	DROP TABLE #DogovorMonitorTable

END
GO

grant exec on [dbo].[DogovorMonitor] to public
GO

/*********************************************************************/
/* end sp_DogovorMonitor.sql */
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
--<VERSION>2009.2.30</VERSION>
--<DATE>2012-08-29</DATE>
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
	DECLARE @ODG_ProTourFlag int
	DECLARE @NDG_ProTourFlag int
    
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
		null, null, null, null, null, null, null, null, null, null,
		N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, CONVERT( char(10), N.DG_TurDate, 104), N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
		CONVERT( char(11), N.DG_PPaymentDate, 104) + CONVERT( char(5), N.DG_PPaymentDate, 108), CONVERT( char(10), N.DG_PaymentDate, 104), N.DG_RazmerP, N.DG_Procent, N.DG_Locked, N.DG_SOR_Code, N.DG_IsOutDoc, CONVERT( char(10), N.DG_VisaDate, 104), N.DG_CauseDisc, N.DG_OWNER, 
		N.DG_LEADDEPARTMENT, N.DG_DupUserKey, N.DG_MainMen, N.DG_MainMenEMail, N.DG_MAINMENPHONE, N.DG_CodePartner, N.DG_Creator, N.DG_CTDepartureKey, N.DG_Payed, N.DG_ProTourFlag
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT O.DG_Key,
		O.DG_Code, O.DG_Price, O.DG_Rate, O.DG_DiscountSum, O.DG_PartnerKey, O.DG_TRKey, CONVERT( char(10), O.DG_TurDate, 104), O.DG_CTKEY, O.DG_NMEN, O.DG_NDAY, 
		CONVERT( char(11), O.DG_PPaymentDate, 104) + CONVERT( char(5), O.DG_PPaymentDate, 108), CONVERT( char(10), O.DG_PaymentDate, 104), O.DG_RazmerP, O.DG_Procent, O.DG_Locked, O.DG_SOR_Code, O.DG_IsOutDoc, CONVERT( char(10), O.DG_VisaDate, 104), O.DG_CauseDisc, O.DG_OWNER, 
		O.DG_LEADDEPARTMENT, O.DG_DupUserKey, O.DG_MainMen, O.DG_MainMenEMail, O.DG_MAINMENPHONE, O.DG_CodePartner, O.DG_Creator, O.DG_CTDepartureKey, O.DG_Payed, O.DG_ProTourFlag,
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
		O.DG_LEADDEPARTMENT, O.DG_DupUserKey, O.DG_MainMen, O.DG_MainMenEMail, O.DG_MAINMENPHONE, O.DG_CodePartner, O.DG_Creator, O.DG_CTDepartureKey, O.DG_Payed, O.DG_ProTourFlag,
		N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, CONVERT( char(10), N.DG_TurDate, 104), N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
		CONVERT( char(11), N.DG_PPaymentDate, 104) + CONVERT( char(5), N.DG_PPaymentDate, 108),  CONVERT( char(10), N.DG_PaymentDate, 104), N.DG_RazmerP, N.DG_Procent, N.DG_Locked, N.DG_SOR_Code, N.DG_IsOutDoc,  CONVERT( char(10), N.DG_VisaDate, 104), N.DG_CauseDisc, N.DG_OWNER, 
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
			EXECUTE dbo.InsertHistoryDetail @nHIID, 1122, null, null, null, null, null, null, 1, @bNeedCommunicationUpdate output

		
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

/*********************************************************************/
/* begin 20121128_UpdateActions_Rename_DenyDogovorAttributeEdit.sql */
/*********************************************************************/
if exists (select 1 from Actions where AC_Name = 'Турпутевка->Запретить снимать запрет на ограничения по редактированию услуг')
begin 
 update Actions set AC_Name = 'Турпутевка->Разрешить снимать запрет на ограничения по редактированию услуг'
					, AC_NameLat  = 'Reservation->Allow dogovor attribute edit'
 where AC_Name = 'Турпутевка->Запретить снимать запрет на ограничения по редактированию услуг'
end 

go
/*********************************************************************/
/* end 20121128_UpdateActions_Rename_DenyDogovorAttributeEdit.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.11.29)UpdateReportTemplates_RT_DATA.sql */
/*********************************************************************/
-- изменение типа поля RT_DATA на nvarchar(max) для хранения диакритических символов
alter table dbo.reporttemplates alter column RT_DATA nvarchar(max)
go
/*********************************************************************/
/* end (2012.11.29)UpdateReportTemplates_RT_DATA.sql */
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
--<DATE>2012-12-4</DATE>
--<VERSION>2009.2.18.1</VERSION>
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
		------- CRM02174G8K3 28.06.2012 kolbeshkin: будем проверять DG_DUPUSERKEY, если он уже проставлен, то покупателя не меняем,
		-- иначе в покупателе представитель партнера (DupUser) затрется главным туристом
		-- 9146 neupokoev 01.11.2012 Убрал проверку DG_DUPUSERKEY, потому что иначе при пронировании из веба в качестве dg_mainman
		-- вне зависимости от настройки SYSDGMainManRule всегда будет представитель партнера, а это дело регулируется из мт
		-------
		IF (@sMod = 'UPD')
		BEGIN
			IF(ISNULL(@NTU_ISMAIN,0) = 1)
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
								@Email varchar(50),
								@PostIndex varchar(8),
								@PostCity varchar(60),
								@PostStreet varchar(25),
								@PostBuilding varchar(10),
								@PostFlat varchar(4),
								@PassportSeries varchar(10),
								@PassportNumber varchar(10);
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
/* begin sp_mwGetTourInfo.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwGetTourInfo')
	drop proc dbo.[mwGetTourInfo]
go

create proc [dbo].[mwGetTourInfo](@cityFromKey int, @countryKey int, @tourType int, @cityKey int, @dateFrom datetime, @dateTo datetime, @checkQuota smallint, @agentKey int, @setRequestOnZeroRelease smallint, @noPlacesResult smallint, @checkAgentQuota smallint, @checkCommonQuota smallint, @checkNoLongQuota smallint, @expiredReleaseResult smallint, @quotaYes smallint, @sort varchar(256), @viewType smallint = null)
as
begin
-- <date>2013-04-23</date>
-- <version>9.2.17.2</version>
declare @sql nvarchar(4000)

--13337. Кошелевым было принято решение отключить получение квот из-за долгой работы загрузки
set @checkQuota = -1

if(@viewType is null)
begin
	create table #tmpTours(
		tlkey int,
		tourkey int,
		tourname varchar(256),
		tourlink varchar(512),
		tourdays int,
		tournights int,
		tourprice float,
		pricelink varchar(512),
		quota int
	)
	
	insert into #tmpTours
		select distinct to_trkey as tlkey, to_key as tourkey, isnull(tl_nameweb, isnull(to_name, tl_name)) as tourname, 
		isNull(tl_webhttp,'') + '|' + ltrim(str(@countryKey)) + '|' + ltrim(str(to_key)) + '|' + isnull(tl_nameweb, isnull(to_name, tl_name)) as tourlink,
		ti_totaldays as tourdays, ti_nights as tournights, cast(0 as float) as tourprice, cast('' as varchar(500)) as pricelink, cast(0 as int) as quota
		from tp_tours with(nolock)
		inner join tbl_turlist with(nolock) on to_trkey = tl_key
		inner join tp_lists ti with(nolock) on ti_tokey = to_key
		where to_isenabled > 0
		and to_cnkey = @countryKey
		and ti_firstctkey = case @cityKey when -1 then ti_firstctkey else @cityKey end
		and TO_TRKey in (select TD_TRKEY from TurDate td with(nolock) where TD_DATE between @dateFrom and @dateTo)
										
	update #tmpTours set tourprice = (select min(tp_gross)
		from tp_prices with(nolock)
		where TP_TIKey in (select TI_Key 
						   from TP_Lists with(nolock)
						   where TI_FIRSTHRKEY in (select HR_KEY from HotelRooms with(nolock) where HR_MAIN > 0)
						   and ti_totaldays = tourdays
						   and ti_nights = tournights
						   and TI_TOKey = tourkey)
		and TP_DateBegin >= @dateFrom
		and TP_TOKey = tourkey)

	if (@checkQuota = -1)
	begin
		update #tmpTours set quota = -1
	end
	else
	begin
		declare qtCursor cursor fast_forward read_only for 
			select tlkey, tourkey, tourdays, tournights from #tmpTours

		declare @tlkey int, @tourkey int, @tourdays int, @tournights int
		
		open qtCursor
		fetch next from qtCursor into @tlkey, @tourkey, @tourdays, @tournights
		while(@@fetch_status = 0)
		begin
			print @tlkey
			print @tourkey
			print @tourdays
			print @tournights
			print @dateFrom
			print @dateTo
			print @agentKey
			print @setRequestOnZeroRelease
			print @noPlacesResult
			print @checkAgentQuota
			print @checkCommonQuota
			print @checkNoLongQuota
			print @expiredReleaseResult
			update #tmpTours set quota = dbo.mwCheckTourQuotes(@tlkey, @tourkey, @tourdays, @tournights, @dateFrom, @dateTo, @agentKey, @setRequestOnZeroRelease, @noPlacesResult,
															@checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @expiredReleaseResult)
			
			fetch next from qtCursor into @tlkey, @tourkey, @tourdays, @tournights
		end

		close qtCursor
		deallocate qtCursor
	end
	
	update #tmpTours set pricelink = (ltrim(str(@countryKey)) + '|' + ltrim(str(tourkey)) 
		+ '|' + ltrim(str(datepart(yyyy, @dateFrom))) + '-' + ltrim(str(datepart(mm, @dateFrom))) + '-' + ltrim(str(datepart(dd, @dateFrom)))
		+ '|' + ltrim(str(datepart(yyyy, @dateTo))) + '-' + ltrim(str(datepart(mm, @dateTo))) + '-' + ltrim(str(datepart(dd, @dateTo)))
		+ '|' + ltrim(str(tourprice)))
	
	set @sql = N'select * from #tmpTours where tourprice is not null and quota <> case ' + ltrim(str(@quotaYes)) + ' when -1 then -10 else 0 end '
	
	if len(@sort) > 0
		set @sql = @sql + ' order by ' + @sort
	print @sql
	exec sp_executesql @sql
	
	drop table #tmpTours
end
else
begin
	create table #tmpTours1(
		cnname varchar(256),
		tourkey int,
		tourname varchar(256),
		tourtype int,
		tourtypename varchar(256),
		tourlink varchar(512),
		tourdates varchar(1024),
		hoteldays varchar(256),
		hotelstars varchar(256),
		tourprice float,
		pricelink varchar(512),
		quota int,
		cnkey int,
		tourrate varchar(3),
		departfrom varchar(256),
		tlkey int,
		t_id int identity primary key
	)

	if(@viewType = 1)
	begin
		insert into #tmpTours1
			select distinct cn_name as cnname, sd_tourkey as tourkey, isnull(tl_nameweb, isnull(to_name, tl_name)) as tourname, sd_tourtype, tp_name as tourtypename, 
			isNull(tl_webhttp,'') + '|' + ltrim(str(@countryKey)) + '|' + ltrim(str(sd_tourkey)) + '|' + isnull(tl_nameweb, isnull(to_name, tl_name)) as tourlink,
			dbo.mwTop5TourDates(sd_cnkey, sd_tourkey, tl_key, 1) as tourdates, dbo.mwTourHotelNights(sd_tourkey) as hotelnights, dbo.mwTourHotelStars(sd_tourkey) as hotelstars, 
			cast(0 as float) as tourprice, cast('' as varchar(500)) as pricelink, cast(0 as int) as quota, sd_cnkey as cnkey, to_rate as tourrate, isnull(ct_name, '') as cityfrom, tl_key as tlkey
			from mwSpoData with(nolock) inner join 
			tp_tours with(nolock)  on sd_tourkey = to_key inner join 
			tbl_turlist with(nolock) on to_trkey = tl_key inner join
			tiptur with(nolock) on tl_tip = tp_key inner join 
			country with(nolock) on sd_cnkey = cn_key left outer join
			citydictionary with(nolock) on sd_ctkeyfrom = ct_key
			where (isnull(sd_ctkeyfrom, 0) = case @cityFromKey when - 1 then isnull(sd_ctkeyfrom, 0) else @cityFromKey end) and sd_cnkey = case @countryKey when -1 then sd_cnkey else @countryKey end and tl_tip = case @tourType when -1 then tl_tip else @tourType end and sd_ctkey = case @cityKey when -1 then sd_ctkey else @cityKey end
			and exists(select top 1 td_trkey from turdate where td_trkey = tl_key and td_date > getdate())
	end
	else
	if(@viewType = 2)
	begin
		insert into #tmpTours1
			select distinct cn_name as cnname, ti_tokey as tourkey, isnull(tl_nameweb, isnull(to_name, tl_name)) as tourname, tl_tip, tp_name as tourtypename, 
			isNull(tl_webhttp,'') + '|' + ltrim(str(@countryKey)) + '|' + ltrim(str(ti_tokey)) + '|' + isnull(tl_nameweb, isnull(to_name, tl_name)) as tourlink,
			dbo.mwTop5TourDates(to_cnkey, ti_tokey, tl_key, 1) as tourdates, dbo.mwTourHotelNights(ti_tokey) as hotelnights, dbo.mwTourHotelStars(ti_tokey) as hotelstars, 
			cast(0 as float) as tourprice, cast('' as varchar(500)) as pricelink, cast(0 as int) as quota, to_cnkey as cnkey, to_rate as tourrate, isnull(ct_name, '') as cityfrom, tl_key as tlkey
			from tp_lists with(nolock) inner join 
			tp_tours with(nolock)  on ti_tokey = to_key inner join 
			tbl_turlist with(nolock) on to_trkey = tl_key inner join
			tiptur with(nolock) on tl_tip = tp_key inner join 
			country with(nolock) on to_cnkey = cn_key left outer join
			citydictionary with(nolock) on ti_ctkeyfrom = ct_key
			where (isnull(ti_ctkeyfrom, 0) = case @cityFromKey when -1 then isnull(ti_ctkeyfrom, 0) else @cityFromKey end) and to_cnkey = case @countryKey when -1 then to_cnkey else @countryKey end and tl_tip = case @tourType when -1 then tl_tip else @tourType end and ti_firstctkey = case @cityKey when -1 then ti_firstctkey else @cityKey end
			and exists(select top 1 td_trkey from turdate where td_trkey = tl_key and td_date > getdate()) and to_isenabled > 0
	end

	update #tmpTours1 set tourprice = (select min(tp_gross) from tp_prices where tp_dateend > getdate() and tp_tikey in (select ti_key from tp_lists inner join hotelrooms on ti_firsthrkey = hr_key where ti_tokey = tourkey and hr_main > 0 and tp_gross > 0)),
		quota = 0
 
	update #tmpTours1 set pricelink = (ltrim(str(cnkey)) + '|' + ltrim(str(tourkey)) + '|' + dbo.mwFirstTourDate(tlkey) + '|' + ltrim(str(tourprice)) + '|' + tourrate)
  
	set @sql = N'select * from #tmpTours1 where tourprice is not null and quota <> case ' + ltrim(str(@quotaYes)) + ' when -1 then -10 else 0 end '

	if len(@sort) > 0
		set @sql = @sql + ' order by ' + @sort

	exec sp_executesql @sql

	drop table #tmpTours1
	
	end
end
go

grant exec on [dbo].[mwGetTourInfo] to public
go
/*********************************************************************/
/* end sp_mwGetTourInfo.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckDoubleReservation.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckDoubleReservation]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckDoubleReservation]
GO

create procedure [dbo].[CheckDoubleReservation]
(	
	--<VERSION>2009.2.20<VERSION/>
	--<DATE>2013-08-01<DATE/>
	-- процедура определяет есть ли дублирующая путевка
	-- ключ договора
	@dogovorKey int,
	-- ключ дублирующего договора, если значение null то дублирующего договора не найдено
	@doubledogovorKey int output
)
AS
begin
	set @doubledogovorKey = null
	declare @dg_nday int
	declare @dg_turdate datetime
	
	select @dg_nday=DG_NDAY,@dg_turdate=DG_TURDATE from tbl_Dogovor where DG_Key=@dogovorKey

	select top 1 @doubledogovorKey = TU1.TU_DGKEY
	from  tbl_turist as TU1
	inner join tbl_turist as TU2 on TU2.TU_DGKEY = @dogovorKey
	where TU1.TU_DGKEY != @dogovorKey
	and TU1.TU_DGKEY in (select dg_key from dogovor where DG_TURDATE > GETDATE()-100 and
	(DG_TURDATE between @dg_turdate and DATEADD(DAY, @dg_nday - 1, @dg_turdate)
	or @dg_turdate between DG_TURDATE and DATEADD(DAY, DG_NDAY - 1, DG_TURDATE)))
	AND  RTRIM(LTRIM(UPPER(TU1.TU_NAMERUS))) = RTRIM(LTRIM(UPPER(TU2.TU_NAMERUS)))
	and RTRIM(LTRIM(UPPER(TU1.TU_FNAMERUS))) = RTRIM(LTRIM(UPPER(TU2.TU_FNAMERUS)))
	and (TU1.TU_BIRTHDAY IS NULL or TU2.TU_BIRTHDAY IS NULL or TU1.TU_BIRTHDAY = TU2.TU_BIRTHDAY)
	and (
		TU1.TU_PASPORTTYPE IS NULL 
		or TU2.TU_PASPORTTYPE IS NULL 
		or RTRIM(LTRIM(UPPER(TU1.TU_PASPORTTYPE))) = RTRIM(LTRIM(UPPER(TU2.TU_PASPORTTYPE)))
	)
	and (
		TU1.TU_PASPORTNUM IS NULL 
		or TU2.TU_PASPORTNUM IS NULL 
		or RTRIM(LTRIM(UPPER(TU1.TU_PASPORTNUM))) = RTRIM(LTRIM(UPPER(TU2.TU_PASPORTNUM)))
	)
end
go

grant exec on [dbo].[CheckDoubleReservation] to public
go
/*********************************************************************/
/* end sp_CheckDoubleReservation.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.02.13)Insert_Action.sql */
/*********************************************************************/
delete from Actions where ac_key in (104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120
,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139)

-- MEG00038702. 13.02.2012. Golubinsky
-- Создание Actions на запрет доступа к справочникам
if not exists (select 1 from actions where ac_key = 104) 
INSERT INTO actions (ac_key,ac_name) VALUES ( 104, 'Скрыть справочник стран')
if not exists (select 1 from actions where ac_key = 105)
INSERT INTO actions (ac_key,ac_name) VALUES ( 105, 'Скрыть справочник городов')
if not exists (select 1 from actions where ac_key = 106)
INSERT INTO actions (ac_key,ac_name) VALUES ( 106, 'Скрыть справочник классов услуг')
if not exists (select 1 from actions where ac_key = 107)
INSERT INTO actions (ac_key,ac_name) VALUES ( 107, 'Скрыть справочник статусов путевок')
if not exists (select 1 from actions where ac_key = 108)
INSERT INTO actions (ac_key,ac_name) VALUES ( 108, 'Скрыть справочник отелей')
if not exists (select 1 from actions where ac_key = 109)
INSERT INTO actions (ac_key,ac_name) VALUES ( 109, 'Скрыть справочник паромов')
if not exists (select 1 from actions where ac_key = 110)
INSERT INTO actions (ac_key,ac_name) VALUES ( 110, 'Скрыть справочник авиаперелетов')
if not exists (select 1 from actions where ac_key = 111)
INSERT INTO actions (ac_key,ac_name) VALUES ( 111, 'Скрыть справочник трансферов')
if not exists (select 1 from actions where ac_key = 112)
INSERT INTO actions (ac_key,ac_name) VALUES ( 112, 'Скрыть справочник экскурсий')
if not exists (select 1 from actions where ac_key = 113)
INSERT INTO actions (ac_key,ac_name) VALUES ( 113, 'Скрыть справочник страховок')
if not exists (select 1 from actions where ac_key = 114)
INSERT INTO actions (ac_key,ac_name) VALUES ( 114, 'Скрыть справочник виз')
if not exists (select 1 from actions where ac_key = 115)
INSERT INTO actions (ac_key,ac_name) VALUES ( 115, 'Скрыть справочник типов номеров')
if not exists (select 1 from actions where ac_key = 116)
INSERT INTO actions (ac_key,ac_name) VALUES ( 116, 'Скрыть справочник категорий номеров')
if not exists (select 1 from actions where ac_key = 117)
INSERT INTO actions (ac_key,ac_name) VALUES ( 117, 'Скрыть справочник типов питания')
if not exists (select 1 from actions where ac_key = 118)
INSERT INTO actions (ac_key,ac_name) VALUES ( 118, 'Скрыть справочник типов кают')
if not exists (select 1 from actions where ac_key = 119)
INSERT INTO actions (ac_key,ac_name) VALUES ( 119, 'Скрыть справочник типов размещения')
if not exists (select 1 from actions where ac_key = 120)
INSERT INTO actions (ac_key,ac_name) VALUES ( 120, 'Скрыть справочник типов транспорта')
if not exists (select 1 from actions where ac_key = 121)
INSERT INTO actions (ac_key,ac_name) VALUES ( 121, 'Скрыть справочник тарифов на авиаперелеты')
--if not exists (select 1 from actions where ac_key = 122)
--INSERT INTO actions (ac_key,ac_name) VALUES ( 122, 'Скрыть справочник видов проживания')
if not exists (select 1 from actions where ac_key = 123)
INSERT INTO actions (ac_key,ac_name) VALUES ( 123, 'Скрыть справочник доп. описаний 1')
if not exists (select 1 from actions where ac_key = 124)
INSERT INTO actions (ac_key,ac_name) VALUES ( 124, 'Скрыть справочник доп. описаний 2')
if not exists (select 1 from actions where ac_key = 125)
INSERT INTO actions (ac_key,ac_name) VALUES ( 125, 'Скрыть справочник статусов услуг')
if not exists (select 1 from actions where ac_key = 126)
INSERT INTO actions (ac_key,ac_name) VALUES ( 126, 'Скрыть справочник оснований для скидок')
if not exists (select 1 from actions where ac_key = 127)
INSERT INTO actions (ac_key,ac_name) VALUES ( 127, 'Скрыть справочник валют')
if not exists (select 1 from actions where ac_key = 128)
INSERT INTO actions (ac_key,ac_name) VALUES ( 128, 'Скрыть справочник курсов валют')
if not exists (select 1 from actions where ac_key = 129)
INSERT INTO actions (ac_key,ac_name) VALUES ( 129, 'Скрыть справочник план. кросс-курсов валют')
if not exists (select 1 from actions where ac_key = 130)
INSERT INTO actions (ac_key,ac_name) VALUES ( 130, 'Скрыть справочник видов рекламы')
if not exists (select 1 from actions where ac_key = 131)
INSERT INTO actions (ac_key,ac_name) VALUES ( 131, 'Скрыть справочник постоянных клиентов')
if not exists (select 1 from actions where ac_key = 132)
INSERT INTO actions (ac_key,ac_name) VALUES ( 132, 'Скрыть справочник названий полей анкет')
if not exists (select 1 from actions where ac_key = 133)
INSERT INTO actions (ac_key,ac_name) VALUES ( 133, 'Скрыть справочник вариантов полей анкет')
if not exists (select 1 from actions where ac_key = 134)
INSERT INTO actions (ac_key,ac_name) VALUES ( 134, 'Скрыть справочник полей анкет по странам')
if not exists (select 1 from actions where ac_key = 135)
INSERT INTO actions (ac_key,ac_name) VALUES ( 135, 'Скрыть справочник причин аннуляции')
if not exists (select 1 from actions where ac_key = 136)
INSERT INTO actions (ac_key,ac_name) VALUES ( 136, 'Скрыть справочник системы оповещений')
if not exists (select 1 from actions where ac_key = 137)
INSERT INTO actions (ac_key,ac_name) VALUES ( 137, 'Скрыть справочник статусов документов')
if not exists (select 1 from actions where ac_key = 138)
INSERT INTO actions (ac_key,ac_name) VALUES ( 138, 'Скрыть справочник отелей и цен')
if not exists (select 1 from actions where ac_key = 139)
INSERT INTO actions (ac_key,ac_name) VALUES ( 139, 'Скрыть справочник реал. кросс-курсов валют')
go


if not exists(select id from syscolumns where id = OBJECT_ID('actions') and name = 'AC_IsActionForRestriction')
alter table actions add AC_IsActionForRestriction bit not null default(0)
go

update actions set ac_isactionforrestriction = 1, ac_customscript = null, ac_name = 'Справочники -> ' + ac_name where 
ac_key in (104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120
,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139)

GO

-- ponkrashin 02.08.2012
-- Создание Actions на ограничение доступа к редактированию количества мест и релиз-периода квот
IF (SELECT COUNT(*) FROM Actions WHERE AC_Key = 141) = 0
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_NameLat, AC_IsActionForRestriction)
	VALUES (141, 'Квоты -> Разрешить редактирование числа мест в квоте', 'Quotas -> Allow editing quotas places', 0)
END

IF (SELECT COUNT(*) FROM Actions WHERE AC_Key = 142) = 0
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_NameLat, AC_IsActionForRestriction)
	VALUES (142, 'Квоты -> Разрешить редактирование релиз-периода', 'Quotas -> Allow editing quotas release period', 0)
END

GO

-- ponkrashin 09.08.2012
-- Установки Action'ов для всех групп, для которых они не были установлены
INSERT INTO GroupAuth (GRA_GRKEY, GRA_ACKey)
	(SELECT principal_id, 141 FROM sys.database_principals
	WHERE type='R' AND
		(SELECT COUNT(*) FROM GroupAuth WHERE GroupAuth.GRA_GRKEY = sys.database_principals.principal_id AND GroupAuth.GRA_ACKey = 141) = 0)

INSERT INTO GroupAuth (GRA_GRKEY, GRA_ACKey)
	(SELECT principal_id, 142 FROM sys.database_principals
	WHERE type='R' AND
		(SELECT COUNT(*) FROM GroupAuth WHERE GroupAuth.GRA_GRKEY = sys.database_principals.principal_id AND GroupAuth.GRA_ACKey = 142) = 0)

GO

-- karimbaeva 25.10.2012
-- Создание Actions на разрешение числа мест в квоте на количество мест меньшее, чем на квоте сидит туристов
IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 143) 
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) VALUES (143, 'Квоты -> Разрешить редактирование числа мест меньше занятых', 
	'Квоты -> Разрешить редактирование числа мест в квоте на количество мест меньшее, чем на квоте сидит туристов', 'Quotas -> Allow editing quotas places less busy', 0)
	
GO
/*********************************************************************/
/* end (2012.02.13)Insert_Action.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.10.15)_CREATE_Role_UserRole_ActionRole.sql */
/*********************************************************************/
	--<VERSION>9.2</VERSION>
	--<DATE>2012-10-15</DATE>	
--1. Добавить PK_RLID (роль по умолчанию) в таблицу tbl_Partners
IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[tbl_Partners]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1) and  
		NOT EXISTS (select * from syscolumns where name='PK_RLID' and id=object_id('tbl_Partners'))
	ALTER table tbl_Partners ADD  PK_RLID int null;
GO

--2. Добавить US_URId (пользователь в Users) в таблицу dup_user
IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[dup_user]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1) and  
		NOT EXISTS (select * from syscolumns where name='US_UsersId' and id=object_id('dup_user'))
	ALTER table dup_user ADD  US_UsersId int null;
GO

--3. Добавить US_URId (пользователь в Users) в таблицу UserList
IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[UserList]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1) and  
		NOT EXISTS (select * from syscolumns where name='US_UsersId' and id=object_id('UserList'))
	ALTER table UserList ADD  US_UsersId int null;
GO

--4. Создаем таблицу Users
IF not EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[Users]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1) 
CREATE TABLE [dbo].[Users](
	[US_Id] [int] IDENTITY(1,1) NOT NULL,
	[US_Login] [nvarchar](50) NOT NULL,
	[US_Password] [nvarchar](64) NOT NULL,
	[US_PRKey] [int] NOT NULL,
	[US_CreatorId] [int] NOT NULL,
	[US_Name] [nvarchar](30) NULL,
	[US_Surname] [nvarchar](30) NULL,
	[US_SecondName] [nvarchar](30) NULL,
	[US_Birthday] [datetime] NOT NULL,
	[US_LastLogDate] [datetime] NOT NULL,
	[US_PassExpireTime] [int] NOT NULL,
	[US_LastPassChange] [datetime] NOT NULL,
	[US_ChangePassword] [bit] NOT NULL,
	[US_DisableUser] [bit] NOT NULL,
	[US_DateCreate] [datetime] NOT NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[US_Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--5. Создаем таблицу UserRole
IF not EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[UserRole]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1) 
	CREATE TABLE [dbo].[UserRole](
		[UR_ID] [int] IDENTITY(1,1) NOT NULL,
		[UR_USKEY] [int] NOT NULL,
		[UR_RLID] [int] NOT NULL,
		CONSTRAINT [PK_UserRole] PRIMARY KEY CLUSTERED 
		(
			[UR_ID] ASC
		)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

--6. Создаем таблицу Role
IF not EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[Role]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1) 
	CREATE TABLE [dbo].[Role](
		[RL_ID] [int] IDENTITY(1,1) NOT NULL,
		[RL_NAME] [nvarchar](450) NOT NULL,
		[RL_ROLETYPE] [int] NOT NULL,
		[RL_PRKEY] [int] NULL,
		[RL_USKEY] [int] NULL,
		CONSTRAINT [PK_Role] PRIMARY KEY CLUSTERED 
		(
			[RL_ID] ASC
		)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

--7. Создаем таблицу ActionRole
IF not EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ActionRole]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1) 
	CREATE TABLE [dbo].[ActionRole](
		[AR_ID] [int] IDENTITY(1,1) NOT NULL,
		[AR_RLID] [int] NOT NULL,
		[AR_ACTION] [int] NOT NULL,
		CONSTRAINT [PK_ActionRole] PRIMARY KEY CLUSTERED 
		(
			[AR_ID] ASC
		)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO



--8. Создаем констрейнт Users.US_Id - Users.US_CreatorId
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_Users_Users]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.Users ADD CONSTRAINT
	FK_Users_Users FOREIGN KEY
	(
	US_CreatorId
	) REFERENCES dbo.Users
	(
	US_Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

--9. Создаем констрейнт tbl_Partners.PR_KEY - Role.RL_PRKEY
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_Role_tbl_Partners]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.Role ADD CONSTRAINT
	FK_Role_tbl_Partners FOREIGN KEY
	(
	RL_PRKEY
	) REFERENCES dbo.tbl_Partners
	(
	PR_KEY
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

--10. Создаем констрейнт Users.US_Id - Role.RL_USKEY
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_Role_Users]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.Role ADD CONSTRAINT
	FK_Role_Users FOREIGN KEY
	(
	RL_USKEY
	) REFERENCES dbo.Users
	(
	US_Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

if dbo.mwReplIsSubscriber() <= 0
begin
	-- Выполняем только либо без репликации, либо на публикаторе. При репликации изменения схемы передаются через механизм репликации.
	--11. Создаем констрейнт tbl_Partners.PK_RLID - Role.RL_ID
	IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_tbl_Partners_Role]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
	ALTER TABLE dbo.tbl_Partners ADD CONSTRAINT
		FK_tbl_Partners_Role FOREIGN KEY
		(
		PK_RLID
		) REFERENCES dbo.Role
		(
		RL_ID
		) ON UPDATE  NO ACTION 
		 ON DELETE  NO ACTION 
end

GO

--12. Создаем констрейнт ActionRole.AR_RLID - Role.RL_ID
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_ActionRole_Role]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.ActionRole ADD CONSTRAINT
	FK_ActionRole_Role FOREIGN KEY
	(
	AR_RLID
	) REFERENCES dbo.Role
	(
	RL_ID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

--13. Создаем констрейнт UserRole.UR_RLID - Role.RL_ID
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_UserRole_Role]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.UserRole ADD CONSTRAINT
	FK_UserRole_Role FOREIGN KEY
	(
	UR_RLID
	) REFERENCES dbo.Role
	(
	RL_ID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

--14. Создаем констрейнт UserRole.UR_USKEY - Users.US_Id
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_UserRole_Users]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.UserRole ADD CONSTRAINT
	FK_UserRole_Users FOREIGN KEY
	(
	UR_USKEY
	) REFERENCES dbo.Users
	(
	US_Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

--15. Создаем констрейнт tbl_Partners.PK_Key - Users.US_PRKey
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_Users_tbl_Partners]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.Users ADD CONSTRAINT
	FK_Users_tbl_Partners FOREIGN KEY
	(
	US_PRKey
	) REFERENCES dbo.tbl_Partners
	(
	PR_KEY
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

--16. Создаем констрейнт tbl_Partners.PK_Key - Users.US_PRKey
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_Users_tbl_Partners]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.Users ADD CONSTRAINT
	FK_Users_tbl_Partners FOREIGN KEY
	(
	US_PRKey
	) REFERENCES dbo.tbl_Partners
	(
	PR_KEY
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

--17. Создаем констрейнт UserList.US_UsersId - Users.US_Id
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_UserList_Users]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.UserList ADD CONSTRAINT
	FK_UserList_Users FOREIGN KEY
	(
	US_UsersId
	) REFERENCES dbo.Users
	(
	US_Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

if dbo.mwReplIsSubscriber() <= 0
begin
	-- Выполняем только либо без репликации, либо на публикаторе. При репликации изменения схемы передаются через механизм репликации.
	--18. Создаем констрейнт DUP_USER.US_UsersId - Users.US_Id
	IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_DUP_USER_Users]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
	ALTER TABLE dbo.DUP_USER ADD CONSTRAINT
		FK_DUP_USER_Users FOREIGN KEY
		(
		US_UsersId
		) REFERENCES dbo.Users
		(
		US_Id
		) ON UPDATE  NO ACTION 
		 ON DELETE  NO ACTION 
end

GO
/*********************************************************************/
/* end (2012.10.15)_CREATE_Role_UserRole_ActionRole.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.10.24)_ADD_COLUMNS_ServiceByDate.sql */
/*********************************************************************/
if not exists (select 1 from dbo.syscolumns where name = 'SD_QPIDOld' and id = object_id(N'[dbo].[ServiceByDate]'))
	alter table dbo.ServiceByDate add SD_QPIDOld int
go

/*********************************************************************/
/* end (2012.10.24)_ADD_COLUMNS_ServiceByDate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.11.12)AlterTable_FileHeaders_AddColumn_FH_FileTitle.sql */
/*********************************************************************/
if not exists (select * from dbo.syscolumns where name = 'FH_FileTitle' and id = object_id(N'[dbo].[FileHeaders]'))
ALTER TABLE dbo.FileHeaders add FH_FileTitle nvarchar(100)
--<VERSION>2009.2.17.0</VERSION>
--<DATE>2012-11-12</DATE>
GO
/*********************************************************************/
/* end (2012.11.12)AlterTable_FileHeaders_AddColumn_FH_FileTitle.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.11.20)_Alter_Data_SystemSettings.sql */
/*********************************************************************/
if (not exists (select top 1 1 from SystemSettings where SS_ParmName = 'IdentityFromWebService'))
begin
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values ('IdentityFromWebService', '')
end
go
/*********************************************************************/
/* end (2012.11.20)_Alter_Data_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.11.20)_CreateTable_AddCostsNewYearDinner-branch.sql */
/*********************************************************************/
IF not EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AddCostsNewYearDinner]') AND type in (N'U'))
begin
	--<VERSION>2009.2.18.0</VERSION>
	--<DATE>2012-11-20</DATE>
	CREATE TABLE [dbo].[AddCostsNewYearDinner](
		[AC_KEY] [int] IDENTITY(1,1) NOT NULL,
		[AC_DATE] [datetime] NOT NULL,
		[AC_CODE] [int] NULL,
		[AC_SUBCODE1] [int] NULL,
		[AC_SUBCODE2] [int] NULL,
		[AC_HDKEY] [int] NULL,
		[AC_PNKEY] [int] NULL,
		[AC_YESNO] [int] NULL,
		[AC_MAIN] [int] NULL,
		[AC_AGEFROM] [int] NULL,
		[AC_AGETO] [int] NULL,
		[AC_RATE] [varchar](3) NULL,
		[AC_PRICE] [int] NULL,
		[AC_SVKEY] [int] NULL,
		[AC_CNKEY] [int] NULL,
		[AC_PrKey] [int] NULL,
		[AC_DateEnd] [datetime] NULL
	) ON [PRIMARY]
end
GO

grant select, update, delete, insert on [dbo].[AddCostsNewYearDinner] to public
go


/*********************************************************************/
/* end (2012.11.20)_CreateTable_AddCostsNewYearDinner-branch.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.12.03)_ALTER_CalculatingPriceLists.sql */
/*********************************************************************/
--добавление колонки выставление в интернет
if not exists (select * from dbo.syscolumns where name ='CP_ExposeWeb' and id = object_id(N'[dbo].[CalculatingPriceLists]'))
begin
	ALTER   TABLE    CalculatingPriceLists ADD [CP_ExposeWeb] [smallint] NOT NULL CONSTRAINT [CP_ExposeWeb_DEFAULT] DEFAULT 0
end
GO

if exists(select * from sys.sysobjects where xtype = 'D' and name like 'CP_Priority')
begin
	ALTER TABLE CalculatingPriceLists drop constraint CP_Priority
end
GO

if exists (select * from dbo.syscolumns where name ='CP_Priority' and id = object_id(N'[dbo].[CalculatingPriceLists]'))
begin
	ALTER TABLE CalculatingPriceLists drop column [CP_Priority]
end
GO

--добавление колонки приоритета расчета прайс листа
if not exists (select * from dbo.syscolumns where name ='CP_Priority' and id = object_id(N'[dbo].[CalculatingPriceLists]'))
begin
	ALTER   TABLE    CalculatingPriceLists     ADD    [CP_Priority] [smallint] NOT NULL CONSTRAINT [CP_Priority] DEFAULT 1
end
GO
/*********************************************************************/
/* end (2012.12.03)_ALTER_CalculatingPriceLists.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20121003)_AlterTable_ProTourQuotes.sql */
/*********************************************************************/
--<DATE>2012-10-03</DATE>
--<VERSION>2009.2.16.1</VERSION>
if exists (select top 1 1 from sys.columns where object_id = object_id('ProTourQuotes') and name = 'PTQ_CommitmentFree' and is_nullable = 0)
	alter table ProTourQuotes alter column PTQ_CommitmentFree int null
go

if exists (select top 1 1 from sys.columns where object_id = object_id('ProTourQuotes') and name = 'PTQ_CommitmentSold' and is_nullable = 0)
	alter table ProTourQuotes alter column PTQ_CommitmentSold int null
go

if exists (select top 1 1 from sys.columns where object_id = object_id('ProTourQuotes') and name = 'PTQ_AllotmentFree' and is_nullable = 0)
	alter table ProTourQuotes alter column PTQ_AllotmentFree int null
go

if exists (select top 1 1 from sys.columns where object_id = object_id('ProTourQuotes') and name = 'PTQ_AllotmentSold' and is_nullable = 0)
	alter table ProTourQuotes alter column PTQ_AllotmentSold int null
go

if not exists (select * from dbo.syscolumns where name = 'PTQ_RecordDate' and id = object_id(N'[dbo].[ProTourQuotes]'))
begin
	alter table ProTourQuotes add PTQ_RecordDate datetime null
end
go

if not exists (select * from dbo.syscolumns where name = 'PTQ_UpdateDate' and id = object_id(N'[dbo].[ProTourQuotes]'))
begin
	alter table ProTourQuotes add PTQ_UpdateDate datetime null
end
go

if not exists (select * from dbo.syscolumns where name = 'PTQ_MethodType' and id = object_id(N'[dbo].[ProTourQuotes]'))
begin
	alter table ProTourQuotes add PTQ_MethodType smallint null
end
go
/*********************************************************************/
/* end (20121003)_AlterTable_ProTourQuotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20121120)AlterTable_mwReplTours.sql */
/*********************************************************************/
if exists (select * from dbo.syscolumns where name = 'rt_add' and id = object_id(N'[dbo].[mwReplTours]'))
begin
	alter table mwReplTours drop column rt_add
end
go

if not exists (select * from dbo.syscolumns where name = 'rt_updateOnlinePrices' and id = object_id(N'[dbo].[mwReplTours]'))
begin
	alter table mwReplTours add rt_updateOnlinePrices smallint not null default(0)
end
go
/*********************************************************************/
/* end (20121120)AlterTable_mwReplTours.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20121121)_AlterMWIndexes.sql */
/*********************************************************************/
declare @mwSearchType int
select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
where SS_ParmName = 'MWDivideByCountry'

declare @objName nvarchar(50)

if (dbo.mwReplIsPublisher() = 0)
begin
	--сегментирование есть
	if (@mwSearchType = 1)
	begin
		declare @counterPart int
		declare @sql nvarchar(max), @params nvarchar(500)
		declare delCursor cursor fast_forward read_only for select distinct sd_cnkey, sd_ctkeyfrom from dbo.mwSpoDataTable order by sd_cnkey, sd_ctkeyfrom
		declare @cnkey int, @ctkeyfrom int
		open delCursor
		fetch next from delCursor into @cnkey, @ctkeyfrom
		while(@@fetch_status = 0)
		begin
			set @objName = dbo.mwGetPriceTableName(@cnkey, @ctkeyfrom)
		
			set @sql = 'IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + @objName + ''') AND name = N''x_main_persprice'')
				DROP INDEX [x_main_persprice] ON ' + @objName + ' WITH ( ONLINE = OFF )'
			exec (@sql)
		
			set @sql = 'CREATE NONCLUSTERED INDEX [x_main_persprice] ON ' + @objName + ' 
			(
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
			[pt_topricefor],
			[pt_directFlightAttribute],
			[pt_backFlightAttribute],
			[pt_mainplaces], 
			[pt_hrkey]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70)'
			exec (@sql)
		
			set @sql = 'IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + @objName + ''') AND name = N''x_main_roomprice'')
				DROP INDEX [x_main_roomprice] ON ' + @objName + ' WITH ( ONLINE = OFF )'
			exec (@sql)
			
			set @sql = 'CREATE NONCLUSTERED INDEX [x_main_roomprice] ON ' + @objName + '
			(
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
			[pt_topricefor],
			[pt_directFlightAttribute],
			[pt_backFlightAttribute],
			[pt_hrkey]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70)'
			exec (@sql)
		
			fetch next from delCursor into @cnkey, @ctkeyfrom
		end
		close delCursor
		deallocate delCursor
	end
	else
	begin
		set @objName = 'dbo.mwPriceDataTable'
		
		set @sql = 'IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + @objName + ''') AND name = N''x_main_persprice'')
				DROP INDEX [x_main_persprice] ON ' + @objName + ' WITH ( ONLINE = OFF )'
		exec (@sql)
		
		set @sql = 'CREATE NONCLUSTERED INDEX [x_main_persprice] ON ' + @objName + ' 
		(
		    [pt_cnkey] ASC,
			[pt_ctkeyfrom] ASC,
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
		[pt_topricefor],
		[pt_directFlightAttribute],
		[pt_backFlightAttribute],
		[pt_mainplaces], 
		[pt_hrkey]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70)'
		exec (@sql)
	
		set @sql = 'IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + @objName + ''') AND name = N''x_main_roomprice'')
			DROP INDEX [x_main_roomprice] ON ' + @objName + ' WITH ( ONLINE = OFF )'
		exec (@sql)
		
		set @sql = 'CREATE NONCLUSTERED INDEX [x_main_roomprice] ON ' + @objName + '
		(
			[pt_cnkey] ASC,
			[pt_ctkeyfrom] ASC,
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
		[pt_topricefor],
		[pt_directFlightAttribute],
		[pt_backFlightAttribute],
		[pt_hrkey]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70)'
		exec (@sql)
	end
end
go
/*********************************************************************/
/* end (20121121)_AlterMWIndexes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.01.22)_ALTER_CalculatingPriceLists.sql */
/*********************************************************************/
--добавление колонки выставление в интернет
if not exists (select * from dbo.syscolumns where name ='CP_ExposeWeb' and id = object_id(N'[dbo].[CalculatingPriceLists]'))
begin
	ALTER   TABLE    CalculatingPriceLists     ADD    [CP_ExposeWeb] [smallint] NOT NULL CONSTRAINT [CP_ExposeWeb_DEFAULT] DEFAULT 0
end
Go
--добавление колонки приоритета расчета прайс листа
if not exists (select * from dbo.syscolumns where name ='CP_Priority' and id = object_id(N'[dbo].[CalculatingPriceLists]'))
	ALTER   TABLE    CalculatingPriceLists     ADD    [CP_Priority] [smallint] NOT NULL CONSTRAINT [CP_Priority] DEFAULT 1
Go

/*********************************************************************/
/* end (2013.01.22)_ALTER_CalculatingPriceLists.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.01.22)_Create_Table_mwPriceTablesList.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwPriceTablesList]') AND type in (N'U'))
begin

	CREATE TABLE dbo.mwPriceTablesList
		(
		ptl_key int NOT NULL identity(1, 1),
		ptl_ctFromKey int NOT NULL,
		ptl_cnKey int NOT NULL
		)  ON [PRIMARY]

	ALTER TABLE dbo.mwPriceTablesList ADD CONSTRAINT
		PK_mwPriceTablesList PRIMARY KEY CLUSTERED 
		(
		ptl_key
		) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	
	ALTER TABLE dbo.mwPriceTablesList ADD CONSTRAINT
		FK_mwPriceTablesList_tbl_Country FOREIGN KEY
		(
		ptl_cnKey
		) REFERENCES dbo.tbl_Country
		(
		CN_KEY
		) ON UPDATE  NO ACTION 
		 ON DELETE  NO ACTION
end

grant select, insert, update, delete on [dbo].[mwPriceTablesList] to public
go
/*********************************************************************/
/* end (2013.01.22)_Create_Table_mwPriceTablesList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.01.23)_Create_Index_X_TourParametrs.sql */
/*********************************************************************/
IF not EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_TourParametrs]') AND name = N'X_TourParametrs')
begin
	CREATE NONCLUSTERED INDEX [X_TourParametrs] ON [dbo].[TP_TourParametrs] 
	(
		[TP_TOKey] ASC,
		[TP_TourDays] ASC,
		[TP_DateCheckIn] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
end	
GO



/*********************************************************************/
/* end (2013.01.23)_Create_Index_X_TourParametrs.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.01.27)AlterTable_mwReplTours.sql */
/*********************************************************************/
if dbo.mwReplIsSubscriber() <= 0
begin
	-- Выполняем только либо без репликации, либо на публикаторе. При репликации изменения схемы передаются через механизм репликации.
	if exists (select * from dbo.syscolumns where name = 'rt_add' and id = object_id(N'[dbo].[mwReplTours]'))
	begin
		alter table mwReplTours drop column rt_add
	end
end
go

if dbo.mwReplIsSubscriber() <= 0
begin
	-- Выполняем только либо без репликации, либо на публикаторе. При репликации изменения схемы передаются через механизм репликации.
	if not exists (select * from dbo.syscolumns where name = 'rt_updateOnlinePrices' and id = object_id(N'[dbo].[mwReplTours]'))
	begin
		alter table mwReplTours add rt_updateOnlinePrices smallint not null default(0)
	end
end
go
/*********************************************************************/
/* end (2013.01.27)AlterTable_mwReplTours.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.01.27)_ADD_COLUMNS_ServiceByDate.sql */
/*********************************************************************/
if dbo.mwReplIsSubscriber() <= 0
begin
	-- Выполняем только либо без репликации, либо на публикаторе. При репликации изменения схемы передаются через механизм репликации.
	if not exists (select 1 from dbo.syscolumns where name = 'SD_QPIDOld' and id = object_id(N'[dbo].[ServiceByDate]'))
		alter table dbo.ServiceByDate add SD_QPIDOld int
end	
	
go

/*********************************************************************/
/* end (2013.01.27)_ADD_COLUMNS_ServiceByDate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.01.27)_Alter_Data_SystemSettings.sql */
/*********************************************************************/
if dbo.mwReplIsSubscriber() <= 0
begin
	-- Выполняем только либо без репликации, либо на публикаторе. При репликации изменения передаются через механизм репликации.
	if (not exists (select top 1 1 from SystemSettings where SS_ParmName = 'IdentityFromWebService'))
	begin
		insert into SystemSettings (SS_ParmName, SS_ParmValue) values ('IdentityFromWebService', '')
	end
end

go
/*********************************************************************/
/* end (2013.01.27)_Alter_Data_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.01.27)_Create_Index_WCFService.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[StopSales]') AND name = N'X_StopSales_WCFService')
begin
	CREATE NONCLUSTERED INDEX X_StopSales_WCFService
	ON [dbo].[StopSales] ([SS_Date],[SS_IsDeleted])
	INCLUDE ([SS_ID],[SS_QDID],[SS_Comment],[SS_CreatorKey],[SS_CreateDate],[SS_QOID],[SS_PRKey],[SS_LastUpdate],[SS_AllotmentAndCommitment])
end
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetails]') AND name = N'X_QuotaDetails_WCFService')
begin
	CREATE NONCLUSTERED INDEX X_QuotaDetails_WCFService
	ON [dbo].[QuotaDetails] ([QD_Date],[QD_IsDeleted])
	INCLUDE ([QD_ID],[QD_QTID],[QD_Type],[QD_Places],[QD_Busy],[QD_Release],[QD_Comment],[QD_CreatorKey],[QD_CreateDate],[QD_QTKEYOLD],[QD_LongMin],[QD_LongMax])
end
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaParts]') AND name = N'X_QuotaParts_WCFService')
begin
	CREATE NONCLUSTERED INDEX X_QuotaParts_WCFService
	ON [dbo].[QuotaParts] ([QP_Date],[QP_IsDeleted])
	INCLUDE ([QP_ID],[QP_QDID],[QP_Places],[QP_Busy],[QP_Limit],[QP_Comment],[QP_CreatorKey],[QP_CreateDate],[QP_FilialKey],[QP_AgentKey],[QP_CityDepartments],[QP_Durations],[QP_IsNotCheckIn],[QP_QTKEYOLD],[QP_Long],[QP_CheckInPlaces],[QP_CheckInPlacesBusy],[QP_LastUpdate])
end
GO

/*********************************************************************/
/* end (2013.01.27)_Create_Index_WCFService.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.08.01)_Alter_Table_History.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM dbo.syscolumns WHERE NAME = 'HI_WHO' AND ID = object_id(N'[dbo].[History]'))
begin
	alter table [dbo].[History] alter column HI_WHO VARCHAR(50)			
end
go
/*********************************************************************/
/* end (2013.08.01)_Alter_Table_History.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.08.13)_Alter_Table_SendMail.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM dbo.syscolumns WHERE NAME = 'SM_EMAIL' AND ID = object_id(N'[dbo].[SendMail]'))
begin
	alter table [dbo].[SendMail] alter column SM_EMAIL VARCHAR(510)			
end
go
/*********************************************************************/
/* end (2013.08.13)_Alter_Table_SendMail.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20130201)_AlterView_Quotes.sql */
/*********************************************************************/

ALTER VIEW [dbo].[Quotes]
AS
SELECT     q.QT_PRKey, qo.QO_SVKey AS qt_svkey, qo.QO_SubCode1 AS qt_subcode1, qo.QO_SubCode2 AS qt_subcode2, qo.QO_Code AS qt_code, 
                      qd.QD_Date AS qt_date, qd.QD_Places AS qt_places, qd.QD_Busy AS qt_busy, ISNULL(qp.QP_AgentKey, 0) AS qt_agent, qp.QP_ID AS qt_key, 
                      qd.QD_Release AS qt_release, qp.QP_IsNotCheckIn AS qt_isnotcheckin, qp.QP_Long AS qt_long, q.QT_ByRoom, qd.QD_Type AS qt_type, 
                      qd.QD_CreateDate AS QT_CREATEDATE, qp.QP_LastUpdate AS QT_LastUpdate, qp.QP_CreatorKey AS QT_OWNER, 
                      ISNULL(qp.QP_CheckInPlaces, 0) AS QT_BYCHECKIN, 0 AS QT_PayTerm, '1900-01-01' AS qt_EntryDate
FROM        Quotas q
INNER JOIN QuotaObjects qo ON qo.QO_QTID = q.QT_ID
INNER JOIN QuotaDetails qd ON qd.QD_QTID = q.QT_ID 
INNER JOIN QuotaParts qp ON qp.QP_QDID = qd.QD_ID

GO

sp_refreshviewforall 'Quotes'
GO
/*********************************************************************/
/* end (20130201)_AlterView_Quotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20130127_Grant_mwDeleted.sql */
/*********************************************************************/
GRANT insert, delete, update ON mwDeleted To public

go
/*********************************************************************/
/* end 20130127_Grant_mwDeleted.sql */
/*********************************************************************/

/*********************************************************************/
/* begin AddSystemSetting_SYSHotelRoomsCount.sql */
/*********************************************************************/
--<DATE>2013-02-14</DATE>
--<VERSION>9.2</VERSION>
--<DESCRIPTION>Настройка по которой определяется максимальное количество показываемых вариантов размещений в форме "Цены на отели"</DESCRIPTION>
IF (SELECT COUNT(*)
	FROM SystemSettings
	WHERE SS_ParmName = 'SYSHotelRoomsCount') = 0
BEGIN
	INSERT INTO SystemSettings (SS_ParmName, SS_ParmValue)
	VALUES ('SYSHotelRoomsCount', 180)
END

GO

/*********************************************************************/
/* end AddSystemSetting_SYSHotelRoomsCount.sql */
/*********************************************************************/

/*********************************************************************/
/* begin cs_CostOfferChange.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CostOfferChange]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CostOfferChange]
GO

CREATE PROCEDURE [dbo].[CostOfferChange]
	(
		-- хранимка активирует деактивирует и публикует ЦБ
		-- ключ ЦБ
		@coId int,
		-- ключ операции 1 - активировать, 2 - деактивировать, 3 - публиковать
		@operationId smallint
	)
AS
BEGIN

	-- временная таблица для цен
	declare @spadIdTable table
	(
		spadId bigint		
	)
	
	-- временная таблица для цен на будущие даты
	declare @spndIdTable table
	(
		spndId bigint
	)

	-- активация ценового блока или деактивация
	if (@operationId = 1 or @operationId = 2)
	begin		
		
		insert into @spadIdTable (spadId)
		select spad.SPAD_Id
		from (dbo.TP_ServicePriceActualDate as spad with (nolock)
				join dbo.TP_ServiceCalculateParametrs as scp with (nolock) on spad.SPAD_SCPId = scp.SCP_Id
				join dbo.TP_ServiceComponents as sc with (nolock) on scp.SCP_SCId = sc.SC_Id)
				cross join
			(CostOffers as [co] with (nolock)
				join dbo.CostOfferServices as [cos] with (nolock) on co.CO_Id = [cos].COS_COID
				join dbo.Seasons as seas with (nolock) on co.CO_SeasonId = seas.SN_Id)
		where
			[co].CO_Id = @coId
			-- должны публиковаться только последние актуальные цены
			and spad.SPAD_SaleDate is null			
			and seas.SN_IsActive = 1			
			and SC_SVKey = co.CO_SVKey
			and sc.SC_Code = [cos].COS_CODE
			and scp.SCP_PKKey = co.CO_PKKey
			and SC_PRKey = co.CO_PartnerKey
			-- и только если он ранее был неактивирован или мы его деактивируем
			and (co.CO_State = 0 or co.CO_State = 1)
			--mv 13102012 для индекса	
			and scp.SCP_SvKey = co.CO_SVKey
			--mv 13102012 дата заезда при отборе должна быть ограничена датами заезда в ценах
			and scp.SCP_DateCheckIn between  
						(SELECT MIN(ISNULL(CS_CHECKINDATEBEG,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = co.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = co.CO_SVKey) 
					and (SELECT MAX(ISNULL(CS_CHECKINDATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = co.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = co.CO_SVKey)
			--mv 13102012 дата заезда должна быть больше текущей даты
			and scp.SCP_DateCheckIn >= DATEADD(DAY,-1,GetDate())
			--mv 13102012 дата заезда не можеть быть больше максимальной даты в ценах
			and scp.SCP_DateCheckIn <= (SELECT MAX(ISNULL(CS_DATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = co.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = co.CO_SVKey)
			--mv 13102012 дата заезда + продолжительность тура не можеть быть меньше, чем минимальная дата в ценах
			and DATEADD(DAY, scp.SCP_TourDays, scp.SCP_DateCheckIn) >= (SELECT MIN(ISNULL(CS_DATE,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = co.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = co.CO_SVKey)
		
		-- в ценах которые расчитали на будущее, тоже нужно пересчитать	
		insert into @spndIdTable (spndId)
		select spnd.SPND_Id
		from (dbo.TP_ServicePriceNextDate as spnd with (nolock)
				join dbo.TP_ServiceCalculateParametrs as scp with (nolock) on spnd.SPND_SCPId = scp.SCP_Id
				join dbo.TP_ServiceComponents as sc with (nolock) on scp.SCP_SCId = sc.SC_Id)
				cross join
			(CostOffers as [co] with (nolock)
				join dbo.CostOfferServices as [cos] with (nolock) on [co].CO_Id = [cos].COS_COID
				join dbo.Seasons as seas with (nolock) on [co].CO_SeasonId = seas.SN_Id)
		where			
			[co].CO_Id = @coId
			and seas.SN_IsActive = 1
			and SC_SVKey = [co].CO_SVKey
			and sc.SC_Code = [cos].COS_CODE
			and scp.SCP_PKKey = [co].CO_PKKey
			and SC_PRKey = [co].CO_PartnerKey
			-- и только если он ранее был неактивирован или мы его деактивировали
			and ([co].CO_State = 0)
			--mv 13102012 для индекса	
			and scp.SCP_SvKey = [co].CO_SVKey
			--mv 13102012 дата заезда при отборе должна быть ограничена датами заезда в ценах
			and scp.SCP_DateCheckIn between  
						(SELECT MIN(ISNULL(CS_CHECKINDATEBEG,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey) 
					and (SELECT MAX(ISNULL(CS_CHECKINDATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			--mv 13102012 дата заезда должна быть больше текущей даты
			and scp.SCP_DateCheckIn >= DATEADD(DAY,-1,GetDate())
			--mv 13102012 дата заезда не можеть быть больше максимальной даты в ценах
			and scp.SCP_DateCheckIn <= (SELECT MAX(ISNULL(CS_DATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			--mv 13102012 дата заезда + продолжительность тура не можеть быть меньше, чем минимальная дата в ценах
			and DATEADD(DAY, scp.SCP_TourDays, scp.SCP_DateCheckIn) >= (SELECT MIN(ISNULL(CS_DATE,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			
		while(exists (select top 1 1 from @spadIdTable))
		begin			
			update top (10000) spad
			set 
			spad.SPAD_NeedApply = 1,
			spad.SPAD_DateLastChange = getdate()
			from dbo.TP_ServicePriceActualDate as spad join @spadIdTable on spad.SPAD_Id = spadId
			
			delete @spadIdTable 
			where exists (	select top 1 1 
							from dbo.TP_ServicePriceActualDate as spad with(nolock) 
							where spad.SPAD_Id = spadId 
							and (spad.SPAD_NeedApply = 1))
		end
			
		while(exists (select top 1 1 from @spndIdTable))
		begin			
			update top (10000) spnd
			set spnd.SPND_NeedApply = 1,
			spnd.SPND_DateLastChange = getdate()
			from dbo.TP_ServicePriceNextDate as spnd join @spndIdTable on spnd.SPND_Id = spndId
			
			delete @spndIdTable 
			where exists (	select top 1 1 
							from dbo.TP_ServicePriceNextDate as spnd with(nolock) 
							where spnd.SPND_Id = spndId
							and spnd.SPND_NeedApply = 1)
		end
		
		-- временная затычка что бы не запускать тригер
		insert into Debug (db_Date, db_Mod, db_n1)
		values (getdate(), 'COS', @coId)

		if (@operationId = 1)
		begin
			-- переводим ЦБ в активное состояние					
			update CostOffers
			set CO_State = 1, CO_DateActive = getdate()
			where CO_Id = @coId
		end
		else if (@operationId = 2)
		begin
			-- переводим ЦБ в закрытое состояние					
			update CostOffers
			set CO_State = 2, CO_DateClose = getdate()
			where CO_Id = @coId
		end
	end	
	-- публикация ценового блока
	else if (@operationId = 3)
	begin
		insert into @spadIdTable (spadId)
		select spad.SPAD_Id
		from (dbo.TP_ServicePriceActualDate as spad with (nolock)
				join dbo.TP_ServiceCalculateParametrs as scp with (nolock) on spad.SPAD_SCPId = scp.SCP_Id
				join dbo.TP_ServiceComponents as sc with (nolock) on scp.SCP_SCId = sc.SC_Id)
				cross join
			(CostOffers as [co] with (nolock)
				join dbo.CostOfferServices as [cos] with (nolock) on [co].CO_Id = [cos].COS_COID
				join dbo.Seasons as seas with (nolock) on [co].CO_SeasonId = seas.SN_Id)
		where
			[co].CO_Id = @coId
			-- должны публиковаться только последние актуальные цены
			and spad.SPAD_SaleDate is null
			and seas.SN_IsActive = 1			
			and SC_SVKey = [co].CO_SVKey
			and sc.SC_Code = [cos].COS_CODE
			and scp.SCP_PKKey = [co].CO_PKKey
			and SC_PRKey = [co].CO_PartnerKey
			-- и дата продажи ценового блока должна быть вокруг текущей даты
			and getdate() between isnull([co].CO_SaleDateBeg, '1900-01-01') and isnull([co].CO_SaleDateEnd, '2072-01-01')
			--mv 13102012 для индекса	
			and scp.SCP_SvKey = [co].CO_SVKey
			--mv 13102012 дата заезда при отборе должна быть ограничена датами заезда в ценах
			and scp.SCP_DateCheckIn between  
						(SELECT MIN(ISNULL(CS_CHECKINDATEBEG,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey) 
					and (SELECT MAX(ISNULL(CS_CHECKINDATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			--mv 13102012 дата заезда должна быть больше текущей даты
			and scp.SCP_DateCheckIn >= DATEADD(DAY,-1,GetDate())
			--mv 13102012 дата заезда не можеть быть больше максимальной даты в ценах
			and scp.SCP_DateCheckIn <= (SELECT MAX(ISNULL(CS_DATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			--mv 13102012 дата заезда + продолжительность тура не можеть быть меньше, чем минимальная дата в ценах
			and DATEADD(DAY, scp.SCP_TourDays, scp.SCP_DateCheckIn) >= (SELECT MIN(ISNULL(CS_DATE,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			
		while(exists (select top 1 1 from @spadIdTable))
		begin			
			update top (10000) spad
			set 			
			spad.SPAD_AutoOnline = 1,
			spad.SPAD_DateLastChange = getdate()
			from dbo.TP_ServicePriceActualDate as spad join @spadIdTable on spad.SPAD_Id = spadId
			
			delete @spadIdTable 
			where exists (	select top 1 1 
							from dbo.TP_ServicePriceActualDate as spad with(nolock) 
							where spad.SPAD_Id = spadId 
							and (spad.SPAD_AutoOnline = 1))
		end
		
		-- временная затычка что бы не запускать тригер
		insert into Debug (db_Date, db_Mod, db_n1)
		values (getdate(), 'COS', @coId)
		
		-- обновим дату публикации
		update CostOffers
		set CO_DateLastPublish = getdate()
		where CO_Id = @coId
	end
	
END

GO

grant exec on [dbo].[CostOfferChange] to public
go
/*********************************************************************/
/* end cs_CostOfferChange.sql */
/*********************************************************************/

/*********************************************************************/
/* begin DeleteFromSystemSettings.sql */
/*********************************************************************/
-- delete obsolete setting from systemsettings
delete from systemsettings where ss_parmname = 'SYSCheckQuotaRelease'
GO
/*********************************************************************/
/* end DeleteFromSystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetHotelDays.sql */
/*********************************************************************/
if  exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].[GetHotelDays]') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function [dbo].[GetHotelDays]
go

--возвращает число дней, для которых есть места на соответствующей квоте
--<version>2009.17.1</version>
--<data>2013-03-06</data>
create function dbo.GetHotelDays(
	@date datetime,               -- дата начала проживания в отеле
	@duration int,                -- продолжительность проживания
	@hotelKey int,                -- ключ отеля
	@quotaType int                -- тип квоты: 1-allotment, 2-commitment
)
returns int
as begin

-- проверяем квоту на продолжительность
if (select top 1 1 from QuotaDetails join QuotaObjects on QO_QTID = QD_QTID join QuotaParts on QP_QDID = QD_ID
    where
		((QD_LongMin is not null and QD_LongMin is not null and QD_Date = @date and @duration between QD_LongMin and QD_LongMax) or
		 (@duration in (select QL_Duration from QuotaLimitations where QL_QPID = QP_ID))
		) and
        QD_Type = @quotaType
		and QO_SVKey = 3
		and QO_Code  = @hotelKey
		and isnull(QP_IsDeleted, 0) = 0
		and isnull(QP_AgentKey, 0) = 0
		and QP_Places > 0
   ) = 1

	-- если есть такая, то возвращаем продолжительность проживания
	-- т.к. уже на все дни есть места
	return @duration

-- нет квоты на продолжительность
else
	-- берем кол-во дат, на которые есть квоты
	declare @x int
	set @x = (select count(t.QD_Date) from
		(select distinct QD_Date from QuotaDetails join QuotaObjects on QO_QTID = QD_QTID join QuotaParts on QP_QDID = QD_ID
 	     where
 	        QD_Date between @date and (@date + @duration - 1)
			and QD_Type  = @quotaType
			and QO_SVKey = 3
			and QO_Code  = @hotelKey
 	        and isnull(QP_IsDeleted, 0) = 0
 	        and isnull(QP_AgentKey, 0) = 0
			and QP_Places > 0
		)t )

	return @x

end
go

GRANT EXEC ON [dbo].[GetHotelDays] TO PUBLIC
GO

/*********************************************************************/
/* end fn_GetHotelDays.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetHotelLoad.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetHotelLoad]') AND TYPE IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[GetHotelLoad]
GO

--возвращает загрузку по отелю
--используется в маржинальном мониторе
--<version>2009.17.1</version>
--<data>2013-02-08</data>
CREATE FUNCTION [dbo].[GetHotelLoad]
(
	@isWholeHotel       BIT,           -- подсчет квот: 1-по отелю в целом, 0-по категориям номеров
	@tourDate           DATETIME,      -- дата заезда тура
	@hotelKey           INT,           -- ключ отеля
	@roomCategoryKey    INT            -- ключ категории номера
)
RETURNS INT
AS BEGIN

--По всем категориям номеров в отеле считаем количество проданных комнат в квотах комитмент и элотмент за период +/- 15 дней от даты заезда.
--Способом сложения определяем их число (X) в заданном периоде.
--Далее берем общее число номеров в отеле в квотах комитмент и элотмент по всем категориям номеров в каждый день в периоде и так же суммируем (Y).
--После чего делим X на Y и получаем процент загрузки.
--Если встречается квота на заезд, то нам нужно знать сколько комнат (всего/продано)
--в каждый конкретный день в выбранном периоде и как итог сумму этих комнат.
--Поэтому для квоты на заезд нужно умножить число комнат на продолжительность указанную для квоты на заезд.

-- таблица с занятыми и общими местами по отелю
DECLARE @placesTable TABLE
(
	places  INT,
	busy    INT,
	QP_Date DATETIME,
	QD_ID   INT
)

-- определяем временной интервал, в котором будем искать квоты
DECLARE @startDate DATETIME, @endDate DATETIME
SET @startDate = DATEADD(DAY, -15, @tourDate)
SET @endDate = DATEADD(DAY, 15, @tourDate)

-- заполняем таблицу квотами на период
INSERT INTO @placesTable (places, busy, QP_Date, QD_ID)
SELECT DISTINCT QP_Places AS places, QP_Busy AS busy, QP_Date AS QP_Date, QD_ID
FROM QuotaDetails JOIN QuotaParts ON QP_QDID = QD_ID JOIN QuotaObjects ON QO_QTID = QD_QTID
WHERE
   (QP_Date BETWEEN @startDate AND @endDate) AND
   (QO_SVKey = 3) AND (QO_Code = @hotelKey) AND
   (QP_Durations = '' AND QD_LongMin IS NULL AND QD_LongMax IS NULL) AND
   (ISNULL(@isWholeHotel,0) = 1 OR (QO_SubCode2 = @roomCategoryKey OR QO_SubCode2 = 0)) AND
   (ISNULL(QP_IsDeleted,0) = 0) AND (ISNULL(QP_AgentKey,0) = 0)

-- добавляем места по квотам выделенных на продолжительность
INSERT INTO @placesTable (places, busy, QP_Date, QD_ID)
SELECT DISTINCT QP_Places AS places, QP_Busy AS busy, QP_Date AS QP_Date, QD_ID
FROM QuotaDetails JOIN QuotaParts ON QP_QDID = QD_ID JOIN QuotaObjects ON QO_QTID = QD_QTID
WHERE
   (QP_Date BETWEEN @startDate AND @endDate) AND
   (QO_SVKey = 3) AND (QO_Code = @hotelKey) AND
   (QP_Durations != '') AND
   (ISNULL(@isWholeHotel,0) = 1 OR (QO_SubCode2 = @roomCategoryKey OR QO_SubCode2 = 0)) AND
   (ISNULL(QP_IsDeleted,0) = 0) AND (ISNULL(QP_AgentKey,0) = 0)

-- таблица с новыми квотами на продолжительность
DECLARE @durationTable TABLE
(
	places     INT,
	busy       INT,
	QP_Date    DATETIME,
	QD_ID      INT,
	QD_LongMax INT
)

-- заполняем таблицу квотами на продолжительность
INSERT INTO @durationTable (places, busy, QP_Date, QD_ID, QD_LongMax)
SELECT DISTINCT QP_Places AS places, QP_Busy AS busy, QP_Date AS QP_Date, QD_LongMax AS QD_LongMax, QD_ID
FROM QuotaDetails JOIN QuotaParts ON QP_QDID = QD_ID JOIN QuotaObjects ON QO_QTID = QD_QTID
WHERE
	(QO_SVKey = 3) AND (QO_Code = @hotelKey) AND
	(QD_LongMin IS NOT NULL AND QD_LongMax IS NOT NULL) AND
	(@startDate < QD_Date + QD_LongMax - 1) AND (QD_Date < @endDate) AND
	(ISNULL(@isWholeHotel,0) = 1 OR (QO_SubCode2 = @roomCategoryKey OR QO_SubCode2 = 0)) AND
	(ISNULL(QP_IsDeleted,0) = 0) AND (ISNULL(QP_AgentKey,0) = 0)

-- считаем свободные и занятые места
DECLARE @places FLOAT, @busyPlaces FLOAT, @result FLOAT

SET @places = (SELECT SUM(places) FROM @placesTable)
SET @places = ISNULL(@places,0) + ISNULL((SELECT SUM(places * dbo.GetIntersecDaysCount(@startDate, @endDate, QP_Date, QP_Date + QD_LongMax - 1))
                                          FROM @durationTable), 0)

SET @busyPlaces = (SELECT SUM(busy) FROM @placesTable)
SET @busyPlaces = ISNULL(@busyPlaces,0) + ISNULL((SELECT SUM(busy * dbo.GetIntersecDaysCount(@startDate, @endDate, QP_Date, QP_Date + QD_LongMax - 1))
                                                  FROM @durationTable), 0)

-- считаем процент загрузки
IF @places > 0
	SET @result = 100.0 * @busyPlaces / @places
ELSE
	SET @result = NULL

RETURN @result

END
GO

GRANT EXEC ON [dbo].[GetHotelLoad] TO PUBLIC
GO

/*********************************************************************/
/* end fn_GetHotelLoad.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetHotelPlaces.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetHotelPlaces]') AND TYPE IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[GetHotelPlaces]
GO

--возвращает общее/занятое число мест по отелю
--используется в маржинальном мониторе
--<version>2009.17.1</version>
--<data>2013-02-08</data>
CREATE FUNCTION dbo.GetHotelPlaces(
	@isWholeHotel       BIT,           -- подсчет квот: 1-по отелю в целом, 0-по категориям номеров
	@isTotalPlaces      BIT,           -- 1-считаем общее число мест, 0-считаем занятые места
	@tourDate           DATETIME,      -- дата тура
	@hotelKey           INT,           -- ключ отеля
	@quotaType          INT,           -- тип квоты: NULL-без учета, 1-allotment,  2-commitment
	@tourDuration       INT,           -- продолжительность тура
	@roomCategoryKey    INT            -- ключ категори номера
)
RETURNS INT
AS BEGIN

-- таблица с занятыми и общими местами по отелю
DECLARE @placesTable TABLE
(
	places  INT,
	busy    INT,
	QP_Date DATETIME,
	QD_ID   INT
)

-- определяем временной интервал, в котором будем искать квоты
DECLARE @startDate DATETIME, @endDate DATETIME
SET @startDate = @tourDate
SET @endDate = @tourDate + @tourDuration - 1

-- заполняем таблицу placesTable датами из интервала и проставляем кол-во мест равное нулю
-- чтобы на те дни, на которые не заведено квот, их число было ноль
DECLARE @i INT
SET @i = 0
WHILE DATEADD(DAY, @i, @startDate) < @endDate BEGIN
	INSERT INTO @placesTable (places, busy, QP_Date, QD_ID) VALUES (0, 0, DATEADD(DAY, @i, @startDate), 0)
	SET @i = @i + 1
END

-- заполняем таблицу placesTable местами по квотам на каждую дату в интервале
INSERT INTO @placesTable (places, busy, QP_Date, QD_ID)
SELECT DISTINCT QP_Places AS places, QP_Busy AS busy, QP_Date AS QP_Date, QD_ID
FROM QuotaDetails JOIN QuotaParts ON QP_QDID = QD_ID JOIN QuotaObjects ON QO_QTID = QD_QTID
WHERE
   (QP_Date BETWEEN @startDate AND @endDate) AND
   (ISNULL(@quotaType,0) = 0 OR (QD_Type = @quotaType)) AND
   (QO_SVKey = 3) AND (QO_Code = @hotelKey) AND
   (QP_Durations = '' AND QD_LongMin IS NULL AND QD_LongMax IS NULL) AND
   (ISNULL(@isWholeHotel,0) = 1 OR (QO_SubCode2 = @roomCategoryKey OR QO_SubCode2 = 0)) AND
   (ISNULL(QP_IsDeleted,0) = 0) AND (ISNULL(QP_AgentKey,0) = 0)

DECLARE
	@places INT,          -- места в квотах на период
	@durationPlaces INT   -- места в квотах на заезд

SET @places =
	(SELECT CASE @isTotalPlaces WHEN 1 THEN MIN(q.places) ELSE MAX(q.busy) END
	 FROM
	   (SELECT SUM(q.places) places, SUM(q.busy) busy
		FROM (SELECT * FROM @placesTable) q
		GROUP BY q.QP_Date) q)

-- считаем места по квотам на заезд
SET @durationPlaces =
	(SELECT CASE @isTotalPlaces WHEN 1 THEN MIN(q.places) ELSE MAX(q.busy) END
	 FROM
	   (SELECT DISTINCT QP_Places AS places, QP_Busy AS busy, QD_ID
		FROM QuotaDetails JOIN QuotaParts ON QP_QDID = QD_ID JOIN QuotaObjects ON QO_QTID = QD_QTID
		WHERE
		   (QD_Date = @tourDate) AND
		   (ISNULL(@quotaType,0) = 0 OR (QD_Type = @quotaType)) AND
		   (QO_SVKey = 3) AND (QO_Code = @hotelKey) AND
		   (QP_Durations != '' OR (QD_LongMin IS NOT NULL AND QD_LongMax IS NOT NULL)) AND
		   ((@tourDuration IN (SELECT QL_Duration FROM QuotaLimitations WHERE QL_QPID = QP_ID)) OR (@tourDuration BETWEEN QD_LongMin AND QD_LongMax)) AND
		   (ISNULL(@isWholeHotel,0) = 1 OR (QO_SubCode2 = @roomCategoryKey OR QO_SubCode2 = 0)) AND
		   (ISNULL(QP_IsDeleted,0) = 0) AND (ISNULL(QP_AgentKey,0) = 0)
	   ) q )


RETURN ISNULL(@places,0) + ISNULL(@durationPlaces,0)

END
GO

GRANT EXEC ON [dbo].[GetHotelPlaces] TO PUBLIC
GO

/*********************************************************************/
/* end fn_GetHotelPlaces.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetIntersecDaysCount.sql */
/*********************************************************************/
if  exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].[GetIntersecDaysCount]') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function [dbo].[GetIntersecDaysCount]
go

--возвращает число дней, в которых пересекаются два диапазона дат
--<version>2009.17.1</version>
--<data>2012-12-25</data>
create function [dbo].[GetIntersecDaysCount]
(
	-- начальная и конечная даты первого диапазона
	@startDate1 datetime,
	@endDate1   datetime,
	-- начальная и конечная даты второго диапазона
	@startDate2 datetime,
	@endDate2   datetime
)
returns int
as begin

declare @left datetime, @right datetime, @result int

set @left =
	case
		when @startDate1 > @startDate2 then @startDate1
		else @startDate2
	end

set @right =
	case
		when @endDate1 < @endDate2 then @endDate1
		else @endDate2
	end

set @result = datediff(day, @left, @right) + 1
-- если даты не пересекаются, то @result будет отрицательным
if @result < 0 set @result = 0

return @result

end
go

grant exec on [dbo].[GetIntersecDaysCount] to public
go

/*********************************************************************/
/* end fn_GetIntersecDaysCount.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetQuotaDurationByQuotaPart.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[GetQuotaDurationByQuotaPart]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[GetQuotaDurationByQuotaPart]
GO

--<VERSION>9.2.18.1</VERSION>
--<DATA>2012-11-15</DATA>
CREATE FUNCTION [dbo].[GetQuotaDurationByQuotaPart]
(
	@quotaPartId int
)
RETURNS varchar(20)
AS
BEGIN
	DECLARE @isQuotaByCheckin int
	SET @isQuotaByCheckin = 
		(SELECT QT_IsByCheckIn
		FROM Quotas INNER JOIN QuotaDetails ON QT_ID = QD_QTID
			INNER JOIN QuotaParts ON QD_ID = QP_QDID
		WHERE QP_ID = @quotaPartId)
		
	DECLARE @duration varchar(20)
		
	IF @isQuotaByCheckin = 1
	BEGIN
		DECLARE @fromDuration smallint 
		SET @fromDuration =
			(SELECT QD_LongMin
			FROM QuotaDetails INNER JOIN QuotaParts ON QD_ID = QP_QDID
			WHERE QP_ID = @quotaPartId)
		
		DECLARE @toDuration smallint
		SET @toDuration =
			(SELECT QD_LongMax
			FROM QuotaDetails INNER JOIN QuotaParts ON QD_ID = QP_QDID
			WHERE QP_ID = @quotaPartId)

		IF @fromDuration IS NULL OR @toDuration IS NULL
			SET @duration = '0'
		ELSE IF @fromDuration = @toDuration
			SET @duration = CAST(@fromDuration AS varchar)
		ELSE
			SET @duration = CAST(@fromDuration AS varchar) + '-' + CAST(@toDuration AS varchar)
	END
	ELSE
	BEGIN
		DECLARE @tempDuration varchar(20)
		SET @tempDuration = (SELECT QP_Durations FROM QuotaParts WHERE QP_ID = @quotaPartId)
		
		IF @tempDuration IS NULL OR @tempDuration = ''
			SET @duration = '0'
		ELSE
			SET @duration = @tempDuration
	END
	
	RETURN @duration
END

GO

GRANT EXEC ON [dbo].[GetQuotaDurationByQuotaPart] TO PUBLIC
GO
/*********************************************************************/
/* end fn_GetQuotaDurationByQuotaPart.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetQuotaIsByCheckin.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[GetQuotaIsByCheckin]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[GetQuotaIsByCheckin]
GO

--<VERSION>9.2.18.1</VERSION>
--<DATA>2012-11-16</DATA>
CREATE FUNCTION [dbo].[GetQuotaIsByCheckin]
(
	@quotaId int
)
RETURNS bit
AS
BEGIN
	DECLARE @isQuotaByCheckin bit
	SET @isQuotaByCheckin = (SELECT QT_IsByCheckIn FROM Quotas WHERE QT_ID = @quotaId)
		
	RETURN @isQuotaByCheckin
END

GO

GRANT EXEC ON [dbo].[GetQuotaIsByCheckin] TO public
GO
/*********************************************************************/
/* end fn_GetQuotaIsByCheckin.sql */
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
	--<VERSION>9.2.17.1</VERSION>
	--<DATE>2013-08-23</DATE>

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
	--karimbaeva 20-04-2012 не было обаботки квот, если стоп ставиться плагином Stop-sale на авиаперелеты
	declare @linked_date datetime, @dt1 datetime, @dt2 datetime, @ctFromStop int, @ctToStop int
	if @linked_day is not null
	begin
		set @linked_date = dateadd(day, @linked_day - 1, @date)
		if(@linked_date > @dateFrom)
		begin
			set @dt1 = @dateFrom
			set @dt2 = @linked_date
		end
		else
		begin
			set @dt1 = @linked_date
			set @dt2 = @dateFrom
		end
	end

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
		qt_qoid int,
		str_id int identity(1,1)
	)

	declare @tmpDate datetime
	declare @dayOfWeek int

	if(@svkey <> 1 or @findFlight <= 0)
	begin
		if(@svkey = 1)
		begin

			if(isnull(@cityFrom, 0) <= 0 or isnull(@cityTo, 0) <= 0)
				select @cityFrom = ch_citykeyfrom, @cityTo = ch_citykeyto from charter with(nolock) where ch_key = @code
				
			--karimbaeva 20-04-2012 не было обаботки квот, если стоп ставиться плагином Stop-sale на авиаперелеты
			if(@linked_date is not null and @linked_date < @dateFrom)
			begin
				set @ctFromStop = @cityTo
				set @ctToStop = @cityFrom
			end
			else
			begin
				set @ctFromStop = @cityFrom
				set @ctToStop =@cityTo
			end

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
			--karimbaeva 20-04-2012 не было обаботки квот, если стоп ставиться плагином Stop-sale на авиаперелеты
			 if not exists(select top 1 ch_key from charter with(nolock) inner join airseason with(nolock) on as_chkey = ch_key
						inner join tbl_costs on (cs_svkey = 1 and cs_code = ch_key 
						and (@dateFrom between cs_date and cs_dateend
							or @dateFrom between cs_checkindatebeg and cs_checkindateend)
						and cs_subcode1=@subcode1 and cs_pkkey = @flightpkkey)
						where ch_key = @code 
							and (AS_WEEK is null or len(as_week)=0 or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
							and (as_dateFrom is null or (as_dateFrom is not null and @dateFrom >= as_dateFrom))
							and (AS_DATETO is null or (AS_DATETO is not null and @dateFrom <= AS_DATETO)))
				or exists(select 1 from dbo.stopavia with(nolock) 
						where sa_ctkeyfrom = @ctFromStop and sa_ctkeyto = @ctToStop
							and isnull(sa_stop, 0) > 0
							and sa_dbeg = @dt1 and sa_dend = @dt2)
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
			qo_id as qt_qoid
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
									and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
									and isnull(ss_isdeleted, 0) = 0
									and qd.QD_Type = (SS_AllotmentAndCommitment + 1)
									and qo_svkey = @svkey
									and qo_code = @code
									and isnull(qo_subcode1, 0) in (@subcode1)
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
					and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
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
				inner join QuotaDetails on QD_ID=SS_QDID
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

		-- удалим стопы с условием: стоп стоит на allotment, но квота есть на allotment+commitment
		delete from @tmpQuotes where str_id in
		(
		select str_id from @tmpQuotes as quotasOut
		where exists (select top 1 1 from @tmpQuotes as quotasIn
							where quotasOut.qt_stop = 1
								and quotasIn.qt_stop = 0
								and quotasOut.qt_date = quotasIn.qt_date
								and quotasIn.qt_type = 2
								and quotasOut.qt_type = 1
								and quotasIn.qt_code = quotasOut.qt_code
								and quotasIn.qt_subcode2 = quotasOut.qt_subcode2
								and (quotasIn.qt_subcode1 = quotasOut.qt_subcode1 or 0 <> quotasIn.qt_subcode1)
								-- ищем стоп, который имеет отношение только к нашему типу квоты
						)
		)

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
							 where qo.qo_svkey = qo1.qo_svkey and qo.qo_code = qo1.qo_code and qo.qo_subcode1 in (qo1.qo_subcode1, 0) and qo.qo_subcode2 in (qo1.qo_subcode2, 0) and qd_date = ss_date and qd_places > qd_busy and qd_type = 2 /*commitment*/)))
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
									set @dateRes = @qtPlaces--@dateRes + @qtPlaces
								else
									set @dateRes = @dateRes + @qtPlaces
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
	end
	else
	begin
		set @partnerKey = -1 -- подбираем перелеты от разных партнеров
		if(isnull(@cityFrom, 0) <= 0 or isnull(@cityTo, 0) <= 0)
			select @cityFrom = ch_citykeyfrom, @cityTo = ch_citykeyto from charter with(nolock) where ch_key = @code
		
		if(@linked_date is not null and @linked_date < @dateFrom)
		begin
			set @ctFromStop = @cityTo
			set @ctToStop = @cityFrom
				end
		else
		begin
			set @ctFromStop = @cityFrom
			set @ctToStop =@cityTo
		end
			
		set @dayOfWeek = datepart(dw, @dateFrom) - 1
		if(@dayOfWeek = 0)
			set @dayOfWeek = 7
		
		--karimbaeva 20-04-2012 не было обаботки квот, если стоп ставиться плагином Stop-sale на авиаперелеты	
		if @flightpkkey >= 0
		begin
			if not exists(
				select top 1 ch_key 
				from charter with(nolock) 
				inner join airseason with(nolock) on as_chkey = ch_key
				inner join tbl_costs with(nolock) on (cs_svkey = 1 
														and cs_code = ch_key 
														and (@dateFrom between cs_date and cs_dateend
															or @dateFrom between cs_checkindatebeg and cs_checkindateend)
														and cs_subcode1=@subcode1 
														and cs_pkkey = @flightpkkey)
				where ch_citykeyfrom = @cityFrom 
						and ch_citykeyto = @cityTo 
						and (AS_WEEK is null 
								or len(as_week)=0 
								or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
						and @dateFrom between as_dateFrom and as_dateto
						)
			or exists(select 1 from dbo.stopavia with(nolock) 
						where sa_ctkeyfrom = @ctFromStop and sa_ctkeyto = @ctToStop
							and isnull(sa_stop, 0) > 0 
							and sa_dbeg = @dt1 and sa_dend = @dt2)
			begin
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
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
						and (@dateFrom between cs_date and cs_dateend 
							or @dateFrom between cs_checkindatebeg and cs_checkindateend)
						and cs_pkkey = @flightpkkey)
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
		--karimbaeva 20-04-2012 не было обаботки квот, если стоп ставиться плагином Stop-sale на авиаперелеты
			if not exists(select top 1 ch_key from charter with(nolock) inner join airseason with(nolock) on as_chkey = ch_key
				where ch_citykeyfrom = @cityFrom and ch_citykeyto = @cityTo 
					and (AS_WEEK is null or len(as_week)=0 or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
					and @dateFrom between as_dateFrom and as_dateto)
				or exists(select 1 from dbo.stopavia with(nolock) 
						where sa_ctkeyfrom = @cityFrom and sa_ctkeyto = @cityTo
							and isnull(sa_stop, 0) > 0 
							and sa_dbeg = @dt1 and sa_dend = @dt2)
			begin
				insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
					qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long, qt_additional)
				values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0=0:0')
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
/* begin fn_mwCheckToken.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckToken]') AND TYPE IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwCheckToken]
GO

-- проверяет токен на актуальность и правильность
-- <version>2009.18.2</version>
-- <data>2013-01-24</data>
CREATE FUNCTION [dbo].[mwCheckToken] (@token VARCHAR(500))
RETURNS INT -- 0 - invalid token; 1 - token expired; 2 -  OK
AS
BEGIN
	DECLARE @checkSecurityToken BIT

	-- получает параметр SYSCheckSecurityToken из таблицы SystemSettings
	-- по умолчанию считается, что параметр не установлен, и проверка токена не используется
	IF EXISTS (
			SELECT SS_ParmValue
			FROM SystemSettings
			WHERE SS_ParmName = 'SYSCheckSecurityToken'
			)
	BEGIN
		SET @checkSecurityToken = (
				SELECT ISNULL(SS_ParmValue, 0)
				FROM SystemSettings
				WHERE SS_ParmName = 'SYSCheckSecurityToken'
				)
	END
	ELSE
	BEGIN
		SET @checkSecurityToken = 0
	END
	-- если значение параметра равно 0 или параметр не задан,
	-- то токен считается правильным и актуальным
	IF @checkSecurityToken = 0
	BEGIN
		RETURN 2
	END

	IF EXISTS (
			SELECT TOP 1 1
			FROM Tokens
			WHERE T_Token = @token
				AND DATEDIFF(MINUTE, T_ExpireDate, GETDATE()) <= 0
			)
	BEGIN
		RETURN 2
	END

	IF EXISTS (
			SELECT TOP 1 1
			FROM Tokens
			WHERE T_Token = @token
				AND DATEDIFF(MINUTE, T_ExpireDate, GETDATE()) > 0
			)
	BEGIN
		RETURN 1
	END

	RETURN 0
END
GO

GRANT EXEC ON [dbo].[mwCheckToken] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwCheckToken.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_CostOfferServices_COID.sql */
/*********************************************************************/
if not exists (select 1 from sysindexes where name='CostOfferServices_COID' and id = object_id(N'CostOfferServices'))
begin
	CREATE NONCLUSTERED INDEX CostOfferServices_COID
	ON [dbo].[CostOfferServices] ([COS_COID])
	INCLUDE ([COS_Id],[COS_CODE])
end
go

/*********************************************************************/
/* end INDEX_ADD_CostOfferServices_COID.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_InsPolicyList_InsPolicy_InsTurists.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[InsPolicyList]') AND name = N'X_IPL_IPID_IPL_KoefValue')
CREATE NONCLUSTERED INDEX [X_IPL_IPID_IPL_KoefValue]
ON [dbo].[InsPolicyList] ([IPL_IPID],[IPL_KoefValue])
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[InsPolicy]') AND name = N'X_IP_CommisPrice_IP_AnnulDate')
CREATE NONCLUSTERED INDEX [X_IP_CommisPrice_IP_AnnulDate]
ON [dbo].[InsPolicy] ([IP_CommisPrice],[IP_AnnulDate])
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[InsTurists]') AND name = N'X_IT_IPID')
CREATE NONCLUSTERED INDEX [X_IT_IPID]
ON [dbo].[InsTurists] ([IT_IPID])
INCLUDE ([IT_TUKey])
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/*********************************************************************/
/* end INDEX_ADD_InsPolicyList_InsPolicy_InsTurists.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_IX_NullQuotas.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[ServiceByDate]') AND name = N'IX_NullQuotas')
begin
	DROP INDEX [IX_NullQuotas] ON [dbo].[ServiceByDate] WITH ( ONLINE = OFF )
end
GO
CREATE NONCLUSTERED INDEX [IX_NullQuotas]
ON [dbo].[ServiceByDate] 
(
	[SD_QPID],
	[SD_State],
	[SD_QPIDOld]
) 
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

GO
/*********************************************************************/
/* end INDEX_ADD_IX_NullQuotas.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_x_CostOffers_Season.sql */
/*********************************************************************/
if not exists (select 1 from sysindexes where name='x_CostOffers_Season' and id = object_id(N'CostOffers'))
begin
	CREATE NONCLUSTERED INDEX x_CostOffers_Season
	ON [dbo].[CostOffers] ([CO_SeasonId],[CO_State])
	INCLUDE ([CO_Id],[CO_PKKey],[CO_SVKey],[CO_PartnerKey])
end
GO

/*********************************************************************/
/* end INDEX_ADD_x_CostOffers_Season.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_x_CostOffers_State.sql */
/*********************************************************************/
if not exists (select 1 from sysindexes where name='x_CostOffers_State' and id = object_id(N'CostOffers'))
begin
	CREATE NONCLUSTERED INDEX x_CostOffers_State
	ON [dbo].[CostOffers] ([CO_State])
	INCLUDE ([CO_Id],[CO_SeasonId],[CO_PKKey],[CO_SVKey],[CO_PartnerKey])
end
GO

/*********************************************************************/
/* end INDEX_ADD_x_CostOffers_State.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_x_mwFill_Prices.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Prices]') AND name = N'x_mwfill')
DROP INDEX [x_mwfill] ON [dbo].[TP_Prices] WITH ( ONLINE = OFF )
GO
		
CREATE NONCLUSTERED INDEX [x_mwfill] ON [dbo].[TP_Prices] 
(
	[TP_TOKey] ASC,
	[TP_TIKey] ASC,
	[TP_DateBegin] ASC,
	[TP_DateEnd] ASC
)
INCLUDE(TP_Gross)
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/*********************************************************************/
/* end INDEX_ADD_x_mwFill_Prices.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_x_ServicePriceNextDate_SCPId.sql */
/*********************************************************************/
if not exists (select 1 from sysindexes where name='x_ServicePriceNextDate_SCPId' and id = object_id(N'TP_ServicePriceNextDate'))
begin
	CREATE NONCLUSTERED INDEX x_ServicePriceNextDate_SCPId
	ON [dbo].[TP_ServicePriceNextDate] ([SPND_SCPId])
	INCLUDE ([SPND_Id])
end
GO


/*********************************************************************/
/* end INDEX_ADD_x_ServicePriceNextDate_SCPId.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ALTER_tbl_Turist.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Turist]') AND name = N'tbl_Turist6')
	DROP INDEX [tbl_Turist6] ON [dbo].[tbl_Turist] WITH ( ONLINE = OFF )
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Turist]') AND name = N'tbl_Turist6')
CREATE NONCLUSTERED INDEX [tbl_Turist6] ON [dbo].[tbl_Turist] 
(
	[TU_DGCOD] ASC,
	[TU_KEY] ASC,
	[TU_NAMERUS] ASC,
	[TU_SHORTNAME] ASC,
	[TU_FNAMERUS] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Turist]') AND name = N'IX_TU_BIRTHDAY_PASPORTTYPE_PASPORTNUM')
	DROP INDEX [IX_TU_BIRTHDAY_PASPORTTYPE_PASPORTNUM] ON [dbo].[tbl_Turist] WITH ( ONLINE = OFF )
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Turist]') AND name = N'IX_TU_BIRTHDAY_PASPORTTYPE_PASPORTNUM')
CREATE NONCLUSTERED INDEX [IX_TU_BIRTHDAY_PASPORTTYPE_PASPORTNUM] ON [dbo].[tbl_Turist] 
(
	[TU_BIRTHDAY] ASC,
	[TU_PASPORTTYPE] ASC,
	[TU_PASPORTNUM] ASC
)
INCLUDE ( [TU_DGCOD],
[TU_KEY],
[TU_NAMERUS],
[TU_SEX],
[TU_FNAMERUS]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO



/*********************************************************************/
/* end INDEX_ALTER_tbl_Turist.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_AutoQuotesPlaces.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AutoQuotesPlaces]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[AutoQuotesPlaces]
GO

CREATE PROCEDURE [dbo].[AutoQuotesPlaces]
	(
		--<VERSION>2009.2.3</VERSION>
		--<DATA>05.12.2012</DATA>
		@pSv_key int
		,@pCode int						-- sv_code из QuotaObject
		,@pSub_code1 int				-- описание 1 из QuotaObject
		,@pSub_code2 int				-- описание 2 из QuotaObject
		,@datestart smalldatetime
		,@dateend smalldatetime
	)
as
begin

	Declare @TUKEY INT, @dlkey int, @DGKey int, @DLSVKey int, @DLCode int, @DLSubcode1 int, @DLDateBeg datetime, @DLDateEnd datetime, @DLNMen int, @QuoteKey int, @QuoteType smallint, @TempType smallint, @HRMain smallint
	Declare @qddate datetime ,@qtkey  int ,@from int 
	declare @Date datetime, @RLID int, @NewSetToQuota bit 
	declare @HRIsMain smallint, @RMKey int, @RCKey int, @ACKey int
	Declare	@NeedPlacesForMen int,@rpid int ,
			@RMPlacesMain smallint, @RMPlacesEx smallint,
			@ACPlacesMain smallint, @ACPlacesEx smallint, @ACPerRoom smallint,
			@RLPlacesMain smallint, @RLPlacesEx smallint, @RLCount smallint, 
			@AC_FreeMainPlacesCount smallint, @AC_FreeExPlacesCount smallint,
			@CurrentPlaceIsEx bit, @RL_FreeMainPlacesCount smallint, @RL_FreeExPlacesCount smallint	
	
	-- таблица с оттобранными услугами которые будем пересаживать		
	declare @dlKeyList table
	(
		dlKey int
	)
	
	-- для перелета
	if (@pSv_key = 1)
	begin
		insert into @dlKeyList (dlKey)
		select DL_Key
		from Dogovorlist
		where dl_svkey = 1
		and dl_code = @pCode
		and ((@pSub_code1 = 0) or (dl_subcode1 = @pSub_code1))
		and isnull((select max(SD_State) from ServiceByDate where SD_DLKey = DL_Key), 4) = 4
		and DL_DateBeg between @datestart and @dateend
	end
	-- для проживания
	else if (@pSv_key = 3)
	begin
		insert into @dlKeyList (dlKey)
		select DL_Key
		from Dogovorlist join HotelRooms on DL_SUBCODE1 = HR_KEY
		where dl_svkey = 3
		and dl_code = @pCode
		and ((@pSub_code1 = 0) or (HR_RMKEY = @pSub_code1))
		and ((@pSub_code2 = 0) or (HR_RCKEY = @pSub_code2))
		and isnull((select max(SD_State) from ServiceByDate where SD_DLKey = DL_Key), 4) = 4
		and DL_DateBeg between @datestart and @dateend
	end	
	-- для остальных услуг
	else
	begin
		if (exists (select 1 from [Service] where SV_KEY = @pSv_key and isnull(SV_QUOTED, 0) = 1))
		begin
			insert into @dlKeyList (dlKey)
			select DL_Key
			from Dogovorlist
			where dl_code = @pCode
			and ((@pSub_code1 = 0) or (DL_SUBCODE1 = @pSub_code1))
			and ((@pSub_code2 = 0) or (DL_SUBCODE2 = @pSub_code2))
			and isnull((select max(SD_State) from ServiceByDate where SD_DLKey = DL_Key), 4) = 4
			and DL_DateBeg between @datestart and @dateend
		end
	end	
	
	if exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota' and SS_ParmValue = 1)
		set @NewSetToQuota = 1
	
	DECLARE cur_DogovorListAutoQuotesPlaces CURSOR FOR
		SELECT 	DL_Key,DL_SvKey, DL_Code, DL_SubCode1, DL_DateBeg, DL_DateEnd, DL_NMen, DL_QuoteKey
		FROM	Dogovorlist join @dlKeyList on dl_key = dlKey
		
	OPEN cur_DogovorListAutoQuotesPlaces
	FETCH NEXT FROM cur_DogovorListAutoQuotesPlaces
		INTO @DLKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if (@NewSetToQuota = 1)
		begin
			SET XACT_ABORT OFF
			
			begin try
			--в этой хранимке будет выполнена попытка постановки услуги на квоту
				EXEC DogListToQuotas @DLKey,null,null,null,null,@DLDateBeg, @DLDateEnd,null,null, @OldSetToQuota = 0
			end try
			begin catch			
				print 'Произошла ошибка при посадке новым методом, запускаем старый метод'
			end catch
		end
		else 
			EXEC DogListToQuotas @DLKey,null,null,null,null,@DLDateBeg, @DLDateEnd,null,null, @OldSetToQuota = 1
				
		FETCH NEXT FROM cur_DogovorListAutoQuotesPlaces
		INTO @DLKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey
	
	ENd
	CLOSE cur_DogovorListAutoQuotesPlaces
	DEALLOCATE   cur_DogovorListAutoQuotesPlaces

end

GO

grant exec on [dbo].[AutoQuotesPlaces] to public
go
/*********************************************************************/
/* end sp_AutoQuotesPlaces.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalculatePriceList.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CalculatePriceList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CalculatePriceList]
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
--<DATE>2012-11-29</DATE>
---<VERSION>9.2.10.3</VERSION>

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
declare @nettoDetail nvarchar(max)
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

Set @nTotalProgress=1
	update tp_tours with(rowlock) set to_progress = @nTotalProgress, TO_UPDATETIME = GetDate() where to_key = @nPriceTourKey

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
	
	-- koshelev 15.02.2011
	-- для подбора перелетов
	if (@isPriceListPluginRecalculation = 0)
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

	select @nDateFirst = @@DATEFIRST
	set DATEFIRST 1
	set @SERV_NOTCALCULATE = 32768

	If @nUpdate=0
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_CalculatingKey, TF_TourDate)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey,
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, ti_totaldays, @nCalculatingKey, TD_Date
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock), TP_Lists with(nolock), TP_ServiceLists with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TI_TOKey = TO_Key and TL_TOKey = TO_Key and TL_TSKey = TS_Key and TL_TIKey = TI_Key and TO_Key = @nPriceTourKey
	Else
	BEGIN
		select distinct TO_Key, TD_Date + TS_Day - 1 flight_day, TS_Code , TS_OpPartnerKey,	TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, ti_totaldays, TD_Date
		into #tp_flights
		from TP_Tours with(nolock) join TP_Services with(nolock) on TO_Key = TS_TOKey and TS_SVKey = 1
			join TP_ServiceLists with(nolock) on TL_TSKey = TS_Key and TS_TOKey = TO_Key
			join TP_Lists with(nolock) on TL_TIKey = TI_Key and TI_TOKey = TO_Key
			join TP_TurDates with(nolock) on TD_TOKey = TO_Key
		where TO_Key = @nPriceTourKey
		
		delete from #tp_flights where exists (Select 1 From TP_Flights with(nolock) Where TF_TOKey=@nPriceTourKey and TF_Date=flight_day
			and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
			and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = ti_totaldays)
	
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days, TF_TourDate, TF_CalculatingKey)
		select *, @nCalculatingKey  from #tp_flights
	END

--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
	--Update	TP_Flights with(rowlock) Set 	TF_CodeNew = TF_CodeOld,
	--			TF_PRKeyNew = TF_PRKeyOld
	--Where	(SELECT count(*) FROM AirSeason  with(nolock) WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') > 0 
	--	and TF_TOKey = @nPriceTourKey	
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1, TF_CalculatingKey = @nCalculatingKey
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
			-- подбираем подходящие нам перелеты
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
			) and
			CS_PKKey = TF_PKKey and
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
				and ti_update = @nUpdate and td_update = @nUpdate and (@nUseHolidayRule = 0 or (case cast(datepart(weekday, td_date) as int) when 7 then 0 else cast(datepart(weekday, td_date) as int) end + ti_days) >= 8)
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
								@nPrkey = TF_PRKeyNew,
								@nSubcode1 = TF_SubCode1New
						FROM	TP_Flights with(nolock)
						WHERE	TF_TOKey = @nPriceTourKey AND
								TF_CodeOld = @nCode AND
								TF_PRKeyOld = @nPrkey AND
								TF_Date = @servicedate AND
								TF_Days = @TI_DAYS AND
								TF_Subcode1 = @nSubcode1
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
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
		--удаление из веба
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
		if (@isPriceListPluginRecalculation = 0)
			EXEC FillMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
		else
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
/* begin sp_ChangeQuotaPlaces.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ChangeQuotaPlaces]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ChangeQuotaPlaces]
GO
CREATE PROCEDURE [dbo].[ChangeQuotaPlaces]
(
	--<VERSION>2009.2.6</VERSION>
	--<DATA>15.11.2012</DATA>
	@qtId int = null
)
AS
BEGIN
	declare @qpId int, @dlkey int, @dlMen int, @qpPlaces int, @free int, @type int, @qdId int, @createdDate datetime, @qtByRoom int, @state int 
	set @state = 0
	declare @tmpTable table(
		qp_id int,
		qd_type int,
		qd_id int,
		qt_byroom int
	)
	
	IF (@qtId is null)
	BEGIN
		if Exists (SELECT top 1 1 from ServiceByDate
			where SD_QPIDOLD is not null and SD_QPID is null and SD_State = 3)
		begin
			insert into @tmpTable select * from
			(SELECT	distinct QP_ID, QD_Type, QD_ID, QT_ByRoom FROM Quotas with (nolock),QuotaDetails with (nolock),QuotaParts with (nolock),ServiceByDate with (nolock) 
				WHERE QT_ID = QD_QTID and QP_QDID=QD_ID and SD_QPIDOLD=QP_ID and SD_QPIDOLD is not null 
						and SD_QPID is null and SD_State = 3 and QD_Places > QD_Busy) as innerQuotas
		end
	END		
	ELSE IF Exists (SELECT top 1 1 FROM QuotaDetails with (nolock),QuotaParts with (nolock)
				WHERE QP_QDID=QD_ID and QP_IsDeleted in (1,3,4) 
					and QD_QTID = @qtId) 
	BEGIN
		-- если QP_IsDeleted = 1 пробуем сажать на другие квоты
		if Exists (SELECT top 1 1 from ServiceByDate
			where SD_State in (1, 2)
			and exists (select 1
						from QuotaParts join QuotaDetails on QP_QDID = QD_ID
						where QP_ID = SD_QPIDOld
						and QP_IsDeleted = 1
						and QD_QTID = @qtId))
		BEGIN
			set @state = 1
			
			insert into @tmpTable select * from
			(SELECT	distinct QP_ID, QD_Type, QD_ID, QT_ByRoom FROM Quotas with (nolock),QuotaDetails with (nolock),QuotaParts with (nolock)
							WHERE QT_ID = QD_QTID and QP_QDID=QD_ID and QP_IsDeleted = 1
							and QD_QTID = @qtId) as innerQuotas  
			
			update ServiceByDate
			set SD_State = null
			where exists (select 1
							from QuotaParts join QuotaDetails on QP_QDID = QD_ID
							where QP_ID = SD_QPIdOld
							and QP_IsDeleted = 1
							and QD_QTID = @qtId) and SD_State in (1, 2)
		END
		
		-- если QP_IsDeleted = 3 пробуем сажать на те же квоты, пока хватит места 
		if Exists (SELECT top 1 1 FROM QuotaDetails with (nolock),QuotaParts with (nolock)
						WHERE QP_QDID=QD_ID and QP_IsDeleted = 3
						and QD_QTID = @qtId)
		BEGIN
			set @state = 3
			
			insert into @tmpTable select * from
			(SELECT	distinct QP_ID, QD_Type, QD_ID, QT_ByRoom FROM Quotas with (nolock),QuotaDetails with (nolock),QuotaParts with (nolock)
							WHERE QT_ID = QD_QTID and QP_QDID=QD_ID and QP_IsDeleted = 3
							and QD_QTID = @qtId) as innerQuotas  
			
			UPDATE ServiceByDate with (rowlock) SET SD_State=3 WHERE SD_QPIDOLD in (SELECT QP_ID FROM QuotaDetails with (nolock),QuotaParts with (nolock) WHERE QP_QDID=QD_ID and QP_IsDeleted=3 and QD_QTID = @qtId)
		END
		
		-- если QP_IsDeleted = 4 ставим на Request
		if Exists (SELECT top 1 1 from ServiceByDate
			where SD_State in (1, 2)
			and exists (select 1
						from QuotaParts join QuotaDetails on QP_QDID = QD_ID
						where QP_ID = SD_QPIDOld
						and QP_IsDeleted = 4
						and QD_QTID = @qtId))
		BEGIN
			set @state = 4
			
			insert into @tmpTable select * from
			(SELECT	distinct QP_ID, QD_Type, QD_ID, QT_ByRoom FROM Quotas with (nolock),QuotaDetails with (nolock),QuotaParts with (nolock)
							WHERE QT_ID = QD_QTID and QP_QDID=QD_ID and QP_IsDeleted = 4
							and QD_QTID = @qtId) as innerQuotas
			
			update ServiceByDate
			set SD_State = 4
			where exists (select 1
							from QuotaParts join QuotaDetails on QP_QDID = QD_ID
							where QP_ID = SD_QPIdOld
							and QP_IsDeleted = 4
							and QD_QTID = @qtId) and SD_State in (1, 2)
		END
	END	
	ELSE IF Exists (SELECT top 1 1 FROM QuotaDetails with (nolock),QuotaParts with (nolock),ServiceByDate with (nolock) 
				WHERE QP_QDID=QD_ID and SD_QPIDOLD=QP_ID and QD_IsDeleted in (1,3,4) 
					and QD_QTID = @qtId) 
	BEGIN
		if Exists (SELECT top 1 1 from ServiceByDate
			where SD_State in (1, 2)
			and exists (select 1
						from QuotaParts join QuotaDetails on QP_QDID = QD_ID
						where QP_ID = SD_QPIDOld
						and QD_IsDeleted = 1
						and QD_QTID = @qtId))
		BEGIN
		-- если QD_IsDeleted = 1 пробуем сажать на другие квоты
			DECLARE @sdDlkey int
			DECLARE cur_QuotaDetail CURSOR FOR 
				SELECT DISTINCT SD_DLKey 
				FROM ServiceByDate 
				with (nolock) WHERE SD_State in (1, 2) and SD_QPID in 
				(SELECT QP_ID FROM QuotaDetails with (nolock),QuotaParts with (nolock) WHERE QP_QDID=QD_ID and QD_IsDeleted=1 and QD_QTID = @qtId)
			OPEN cur_QuotaDetail
			FETCH NEXT FROM cur_QuotaDetail INTO @sdDlkey
			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXEC dbo.DogListToQuotas @sdDlkey, 1
				update ServiceByDate
				set SD_QPIdOld = null 
				where SD_DLKey = @sdDlkey
				FETCH NEXT FROM cur_QuotaDetail INTO @sdDlkey
			END
			CLOSE cur_QuotaDetail
			DEALLOCATE cur_QuotaDetail
			UPDATE QuotaParts SET QP_IsDeleted = NULL WHERE QP_QDID in (select QD_ID from QuotaDetails where QD_QTID = @qtId)
			return
		END
		
		if Exists (SELECT top 1 1 FROM QuotaDetails with (nolock),QuotaParts with (nolock)
						WHERE QP_QDID=QD_ID and QD_IsDeleted = 3
						and QD_QTID = @qtId)
		BEGIN
			-- если QD_IsDeleted = 3 пробуем сажать на те же квоты, пока хватит места 
			insert into @tmpTable select * from
			(SELECT	distinct QP_ID, QD_Type, QD_ID, QT_ByRoom FROM Quotas with (nolock), QuotaDetails with (nolock),QuotaParts with (nolock),ServiceByDate with (nolock) 
							WHERE QT_ID = QD_QTID and QP_QDID=QD_ID and SD_QPIDOLD=QP_ID and QD_IsDeleted = 3
							and QD_QTID = @qtId) as innerQuotas  
			
			UPDATE ServiceByDate with (rowlock) SET SD_State=3
				WHERE SD_QPIDOLD in (SELECT QP_ID FROM QuotaDetails with (nolock),QuotaParts with (nolock) 
									WHERE QP_QDID=QD_ID and QD_IsDeleted=3 and QD_QTID = @qtId)
		END
		
		if Exists (SELECT top 1 1 from ServiceByDate
			where SD_State in (1, 2)
			and exists (select 1
						from QuotaParts join QuotaDetails on QP_QDID = QD_ID
						where QP_ID = SD_QPIDOld
						and QD_IsDeleted = 4
						and QD_QTID = @qtId))
		BEGIN
			-- если QD_IsDeleted = 4 ставим на Request
		
			UPDATE ServiceByDate with (rowlock) SET SD_State=4, SD_QPID = null, SD_QPIdOld = null 
				WHERE SD_QPIDOLD in (SELECT QP_ID FROM QuotaDetails with (nolock),QuotaParts with (nolock) 
							WHERE QP_QDID=QD_ID and QD_IsDeleted=4 and QD_QTID = @qtId)
				and SD_State in (1, 2)
				
			UPDATE QuotaDetails SET QD_IsDeleted = NULL WHERE QD_QTID = @qtId
			return
		END
	END
	
	DECLARE qCur CURSOR FAST_FORWARD READ_ONLY FOR
		SELECT * from @tmpTable
						
	OPEN qCur
	FETCH NEXT FROM qCur INTO	@qpId, @type, @qdId, @qtByRoom
							
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		if (@qtId is not null)
			update QuotaParts set QP_Busy = 0 where QP_ID = @qpId
		
		DECLARE Cur CURSOR FAST_FORWARD READ_ONLY FOR
		select distinct DL_KEY, DL_CreateDate  
		from Dogovorlist 
		left join ServiceByDate on Dl_Key =SD_DLKey 
		where SD_QPIdOld = @qpId and SD_QPID is null 
		order by DL_CreateDate
		
		OPEN Cur
		FETCH NEXT FROM Cur INTO @dlkey, @createdDate
		WHILE @@FETCH_STATUS = 0
		BEGIN 
			if (@qtByRoom = 1)
			begin
				select @dlMen = COUNT(DISTINCT SD_RLID)
				from ServiceByDate 
				where SD_QPIdOld = @qpId 
						and SD_DLKey = @dlkey
			end
			else
			begin
				select @dlMen = COUNT(SD_ID)
				from Dogovorlist 
				left join ServiceByDate on Dl_Key =SD_DLKey 
				where SD_QPIdOld = @qpId 
						and SD_DLKey = @dlkey
			end		
			select @free = (QP_Places - QP_Busy) from QuotaParts where QP_ID = @qpId 	
			
			if (@free > 0 and @dlMen <= @free)
			begin
				update ServiceByDate set SD_State = @type, SD_QPID = @qpId, SD_QPIdOld = null 
				where SD_QPIdOld = @qpId and SD_DLKey = @dlkey		
			end
			
			if (@state = 1 and @free = 0)
			begin
				update ServiceByDate set SD_QPIdOld = null where SD_DLKey = @dlkey
				EXEC dbo.DogListToQuotas @dlkey
			end
			
			DECLARE @dlControl int
			EXEC dbo.SetServiceStatusOk @dlkey,@dlControl
		
		FETCH NEXT FROM Cur INTO @dlkey, @createdDate
		END
		CLOSE Cur
		DEALLOCATE Cur
		if (@state = 4)
			update ServiceByDate set SD_QPIdOld = null where SD_QPIdOld = @qpId and SD_State = 4
			
		update QuotaDetails
			set QD_Places = isnull((select SUM(QP_Places) from QuotaParts where QP_QDID = @qdId),0),
			QD_Busy = isnull((select SUM(QP_Busy) from QuotaParts where QP_QDID = @qdId),0)
			where QD_ID = @qdId	
	UPDATE QuotaParts SET QP_IsDeleted = NULL WHERE QP_ID = @qpId	
	UPDATE QuotaDetails SET QD_IsDeleted = NULL WHERE QD_ID in (select QP_QDID from QuotaParts where QP_ID = @qpId)		
	FETCH NEXT FROM qCur INTO @qpId, @type, @qdId, @qtByRoom
	END
	CLOSE qCur
	DEALLOCATE qCur			
END
GO
grant exec on [dbo].[ChangeQuotaPlaces] to public
go



/*********************************************************************/
/* end sp_ChangeQuotaPlaces.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckQuotaExist.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckQuotaExist]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckQuotaExist]
GO

CREATE PROCEDURE [dbo].[CheckQuotaExist]
(
--<DATE>2013-07-24</VERSION>
--<VERSION>2009.2.17.2</VERSION>
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
IF @SVKey=3 and exists(SELECT TOP 1 1 FROM QuotaObjects, Quotas, QuotaDetails, QuotaParts, HotelRooms WHERE QD_QTID=QT_ID and QD_ID=QP_QDID and QO_QTID=QT_ID
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

IF @SVKey=3
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

-- Проверим на стоп
	If @StopExist > 0 and exists (select 1 from #Tbl,#StopSaleTemp where TMP_Count >0 and TMP_Date = SST_Date and (SST_State=2 and SST_Type=2))
	BEGIN
		Set @Quota_CheckState = 2
		Set @Quota_CheckDate = @StopDate
		return
	END

	--если существует стоп и нет квот...
	If @StopExist > 0 and not exists (select 1 from #Tbl where TMP_Count >0 and TMP_Date = @DateBeg)
	BEGIN
		Set @Quota_CheckState = 2						--Возвращаем "Внимание STOP"
		Set @Quota_CheckDate = @StopDate
		return
	END

	--Проверим на релиз период
	if not exists(select 1 from #Tbl where TMP_Date = @DateBeg and dateadd(day, -1, GETDATE()) < (@DateBeg - ISNULL(TMP_Release, 0)))
	begin
		--declare @release smallint 
		--select @release = TMP_Release from #Tbl where TMP_Count > 0 and TMP_Date = @DateBeg and TMP_Release > 0
		if exists(select 1 from #Tbl where TMP_Release is not null and TMP_Release!=0 and TMP_Date = @DateBeg AND dateadd(day, -1, GETDATE()) >= (@DateBeg - ISNULL(TMP_Release, 0)))
		begin
			set @Quota_CheckState = 3	-- наступил РЕЛИЗ-Период
			return 
		end
	end
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
		SET @PlacesNeed_Count = 0
		set @PlacesNeed_Count_ReleaseIgnore = 0
		
		select @Places_Count = SUM(TMP_Count) 
		from @Tbl_DQ 
		where TMP_Count > 0 and TMP_ByRoom = 0 and TMP_ReleaseIgnore = 0
		
		select @Places_Count_ReleaseIgnore = SUM(TMP_Count)
		from @Tbl_DQ 
		where TMP_Count > 0 and TMP_ByRoom = 0 and TMP_ReleaseIgnore = 1
		
		If @SVKey=3
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
		If @SVKey=3 and @Rooms_Count>0
		BEGIN
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
/* begin sp_ClearMasterWebSearchFields.sql */
/*********************************************************************/
if exists(select id from sysobjects where name='ClearMasterWebSearchFields' and xtype='p')
	drop procedure [dbo].[ClearMasterWebSearchFields]
go

CREATE PROCEDURE [dbo].[ClearMasterWebSearchFields]
	@tokey int, -- ключ тура
	@calcKey int = null
as
begin
	--<VERSION>2009.2.18</VERSION>
	--<DATE>2013-01-25</DATE>

	update dbo.TP_Tours set TO_Update = 1, TO_Progress = 0 where TO_Key = @tokey

	if(@calcKey is null)
		exec dbo.mwEnablePriceTour @tokey, 0, @calcKey
		
	update dbo.TP_Tours set TO_Progress = 10 where TO_Key = @tokey

	declare @tableName as nvarchar(150)
	declare tCur cursor for
	select name from sys.tables where name like 'mwPriceDataTable%'

	declare @sql as nvarchar(max)
	declare @condition as nvarchar(300)
	
	if(@calcKey is not null)
	begin		
		set @condition = 'pt_pricekey in (select tp_key from tp_prices with(nolock) where tp_calculatingkey = ' + STR(@calcKey) + ')'
	end
	else
	begin
		set @condition = 'pt_tourkey = ' + STR(@tokey)
	end

	open tCur
	fetch next from tCur into @tableName
	
	while @@fetch_status = 0
	begin
	
		set @sql = '
			while (1 = 1)
			begin
				delete top (100000) from #tableName where #condition
				if (@@ROWCOUNT = 0)
					break
			end
		'
		
		set @sql = REPLACE(@sql, '#tableName', @tableName)
		set @sql = REPLACE(@sql, '#condition', @condition)
		
		print @sql
		exec (@sql)
	
		fetch next from tCur into @tableName
	
	end
	
	close tCur
	deallocate tCur

	update dbo.TP_Tours set TO_Progress = 25 where TO_Key = @tokey

	update dbo.TP_Tours set TO_Progress = 50 where TO_Key = @tokey

	if(@calcKey is null)		
	begin
		while(1 = 1)
		begin
			delete top(100000) from dbo.mwPriceDurations where sd_tourkey = @tokey
			if (@@ROWCOUNT = 0)
				break
		end
	end

	update dbo.TP_Tours set TO_Progress = 75 where TO_Key = @tokey

	if(@calcKey is null)		
	begin
		while (1 = 1)
		begin
			delete top(100000) from dbo.mwPriceHotels where sd_tourkey = @tokey
			if (@@ROWCOUNT = 0)
				break
		end
	end

	update dbo.TP_Tours set TO_Update = 0, TO_Progress = 100, TO_UpdateTime = GetDate() where TO_Key = @tokey
end
GO

grant exec on [dbo].[ClearMasterWebSearchFields] to public
go

/*********************************************************************/
/* end sp_ClearMasterWebSearchFields.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CostOfferChange.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CostOfferChange]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CostOfferChange]
GO

CREATE PROCEDURE [dbo].[CostOfferChange]
	(
		-- хранимка активирует деактивирует и публикует ЦБ
		-- ключ ЦБ
		@coId int,
		-- ключ операции 1 - активировать, 2 - деактивировать, 3 - публиковать
		@operationId smallint
	)
AS
BEGIN

	-- временная таблица для цен
	declare @spadIdTable table
	(
		spadId bigint		
	)
	
	-- временная таблица для цен на будущие даты
	declare @spndIdTable table
	(
		spndId bigint
	)

	-- активация ценового блока или деактивация
	if (@operationId = 1 or @operationId = 2)
	begin		
		
		insert into @spadIdTable (spadId)
		select spad.SPAD_Id
		from (dbo.TP_ServicePriceActualDate as spad with (nolock)
				join dbo.TP_ServiceCalculateParametrs as scp with (nolock) on spad.SPAD_SCPId = scp.SCP_Id
				join dbo.TP_ServiceComponents as sc with (nolock) on scp.SCP_SCId = sc.SC_Id)
				cross join
			(CostOffers as [co] with (nolock)
				join dbo.CostOfferServices as [cos] with (nolock) on co.CO_Id = [cos].COS_COID
				join dbo.Seasons as seas with (nolock) on co.CO_SeasonId = seas.SN_Id)
		where
			[co].CO_Id = @coId
			-- должны публиковаться только последние актуальные цены
			and spad.SPAD_SaleDate is null
			and seas.SN_IsActive = 1			
			and SC_SVKey = co.CO_SVKey
			and sc.SC_Code = [cos].COS_CODE
			and scp.SCP_PKKey = co.CO_PKKey
			and SC_PRKey = co.CO_PartnerKey
			-- и только если он ранее был неактивирован или мы его деактивируем
			and (co.CO_State = 0 or co.CO_State = 1)
			--mv 13102012 для индекса	
			and scp.SCP_SvKey = co.CO_SVKey
			--mv 13102012 дата заезда при отборе должна быть ограничена датами заезда в ценах
			and scp.SCP_DateCheckIn between  
						(SELECT MIN(ISNULL(CS_CHECKINDATEBEG,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = co.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = co.CO_SVKey) 
					and (SELECT MAX(ISNULL(CS_CHECKINDATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = co.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = co.CO_SVKey)
			--mv 13102012 дата заезда должна быть больше текущей даты
			and scp.SCP_DateCheckIn >= DATEADD(DAY,-1,GetDate())
			--mv 13102012 дата заезда не можеть быть больше максимальной даты в ценах
			and scp.SCP_DateCheckIn <= (SELECT MAX(ISNULL(CS_DATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = co.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = co.CO_SVKey)
			--mv 13102012 дата заезда + продолжительность тура не можеть быть меньше, чем минимальная дата в ценах
			and DATEADD(DAY, scp.SCP_TourDays, scp.SCP_DateCheckIn) >= (SELECT MIN(ISNULL(CS_DATE,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = co.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = co.CO_SVKey)
		
		-- в ценах которые расчитали на будущее, тоже нужно пересчитать	
		insert into @spndIdTable (spndId)
		select spnd.SPND_Id
		from (dbo.TP_ServicePriceNextDate as spnd with (nolock)
				join dbo.TP_ServiceCalculateParametrs as scp with (nolock) on spnd.SPND_SCPId = scp.SCP_Id
				join dbo.TP_ServiceComponents as sc with (nolock) on scp.SCP_SCId = sc.SC_Id)
				cross join
			(CostOffers as [co] with (nolock)
				join dbo.CostOfferServices as [cos] with (nolock) on [co].CO_Id = [cos].COS_COID
				join dbo.Seasons as seas with (nolock) on [co].CO_SeasonId = seas.SN_Id)
		where	
			[co].CO_Id = @coId		
			and seas.SN_IsActive = 1
			and SC_SVKey = [co].CO_SVKey
			and sc.SC_Code = [cos].COS_CODE
			and scp.SCP_PKKey = [co].CO_PKKey
			and SC_PRKey = [co].CO_PartnerKey
			-- и только если он ранее был неактивирован или мы его деактивировали
			and ([co].CO_State = 0)
			--mv 13102012 для индекса	
			and scp.SCP_SvKey = [co].CO_SVKey
			--mv 13102012 дата заезда при отборе должна быть ограничена датами заезда в ценах
			and scp.SCP_DateCheckIn between  
						(SELECT MIN(ISNULL(CS_CHECKINDATEBEG,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey) 
					and (SELECT MAX(ISNULL(CS_CHECKINDATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			--mv 13102012 дата заезда должна быть больше текущей даты
			and scp.SCP_DateCheckIn >= DATEADD(DAY,-1,GetDate())
			--mv 13102012 дата заезда не можеть быть больше максимальной даты в ценах
			and scp.SCP_DateCheckIn <= (SELECT MAX(ISNULL(CS_DATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			--mv 13102012 дата заезда + продолжительность тура не можеть быть меньше, чем минимальная дата в ценах
			and DATEADD(DAY, scp.SCP_TourDays, scp.SCP_DateCheckIn) >= (SELECT MIN(ISNULL(CS_DATE,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			
		while(exists (select top 1 1 from @spadIdTable))
		begin			
			update top (10000) spad
			set 
			spad.SPAD_NeedApply = 1,
			spad.SPAD_DateLastChange = getdate()
			from dbo.TP_ServicePriceActualDate as spad join @spadIdTable on spad.SPAD_Id = spadId
			
			delete @spadIdTable 
			where exists (	select top 1 1 
							from dbo.TP_ServicePriceActualDate as spad with(nolock) 
							where spad.SPAD_Id = spadId 
							and (spad.SPAD_NeedApply = 1))
		end
			
		while(exists (select top 1 1 from @spndIdTable))
		begin			
			update top (10000) spnd
			set spnd.SPND_NeedApply = 1,
			spnd.SPND_DateLastChange = getdate()
			from dbo.TP_ServicePriceNextDate as spnd join @spndIdTable on spnd.SPND_Id = spndId
			
			delete @spndIdTable 
			where exists (	select top 1 1 
							from dbo.TP_ServicePriceNextDate as spnd with(nolock) 
							where spnd.SPND_Id = spndId
							and spnd.SPND_NeedApply = 1)
		end
		
		-- временная затычка что бы не запускать тригер
		insert into Debug (db_Date, db_Mod, db_n1)
		values (getdate(), 'COS', @coId)

		if (@operationId = 1)
		begin
			-- переводим ЦБ в активное состояние					
			update CostOffers
			set CO_State = 1, CO_DateActive = getdate()
			where CO_Id = @coId
		end
		else if (@operationId = 2)
		begin
			-- переводим ЦБ в закрытое состояние					
			update CostOffers
			set CO_State = 2, CO_DateClose = getdate()
			where CO_Id = @coId
		end
	end	
	-- публикация ценового блока
	else if (@operationId = 3)
	begin
		insert into @spadIdTable (spadId)
		select spad.SPAD_Id
		from (dbo.TP_ServicePriceActualDate as spad with (nolock)
				join dbo.TP_ServiceCalculateParametrs as scp with (nolock) on spad.SPAD_SCPId = scp.SCP_Id
				join dbo.TP_ServiceComponents as sc with (nolock) on scp.SCP_SCId = sc.SC_Id)
				cross join
			(CostOffers as [co] with (nolock)
				join dbo.CostOfferServices as [cos] with (nolock) on [co].CO_Id = [cos].COS_COID
				join dbo.Seasons as seas with (nolock) on [co].CO_SeasonId = seas.SN_Id)
		where
			[co].CO_Id = @coId
			-- должны публиковаться только последние актуальные цены
			and spad.SPAD_SaleDate is null
			and seas.SN_IsActive = 1			
			and SC_SVKey = [co].CO_SVKey
			and sc.SC_Code = [cos].COS_CODE
			and scp.SCP_PKKey = [co].CO_PKKey
			and SC_PRKey = [co].CO_PartnerKey
			-- и дата продажи ценового блока должна быть вокруг текущей даты
			and getdate() between isnull([co].CO_SaleDateBeg, '1900-01-01') and isnull([co].CO_SaleDateEnd, '2072-01-01')
			--mv 13102012 для индекса	
			and scp.SCP_SvKey = [co].CO_SVKey
			--mv 13102012 дата заезда при отборе должна быть ограничена датами заезда в ценах
			and scp.SCP_DateCheckIn between  
						(SELECT MIN(ISNULL(CS_CHECKINDATEBEG,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey) 
					and (SELECT MAX(ISNULL(CS_CHECKINDATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			--mv 13102012 дата заезда должна быть больше текущей даты
			and scp.SCP_DateCheckIn >= DATEADD(DAY,-1,GetDate())
			--mv 13102012 дата заезда не можеть быть больше максимальной даты в ценах
			and scp.SCP_DateCheckIn <= (SELECT MAX(ISNULL(CS_DATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			--mv 13102012 дата заезда + продолжительность тура не можеть быть меньше, чем минимальная дата в ценах
			and DATEADD(DAY, scp.SCP_TourDays, scp.SCP_DateCheckIn) >= (SELECT MIN(ISNULL(CS_DATE,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = [co].CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = [co].CO_SVKey)
			
		while(exists (select top 1 1 from @spadIdTable))
		begin			
			update top (10000) spad
			set 			
			spad.SPAD_AutoOnline = 1,
			spad.SPAD_DateLastChange = getdate()
			from dbo.TP_ServicePriceActualDate as spad join @spadIdTable on spad.SPAD_Id = spadId
			
			delete @spadIdTable 
			where exists (	select top 1 1 
							from dbo.TP_ServicePriceActualDate as spad with(nolock) 
							where spad.SPAD_Id = spadId 
							and (spad.SPAD_AutoOnline = 1))
		end
		
		-- временная затычка что бы не запускать тригер
		insert into Debug (db_Date, db_Mod, db_n1)
		values (getdate(), 'COS', @coId)
		
		-- обновим дату публикации
		update CostOffers
		set CO_DateLastPublish = getdate()
		where CO_Id = @coId
	end
	
END

GO

grant exec on [dbo].[CostOfferChange] to public
go
/*********************************************************************/
/* end sp_CostOfferChange.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_FillMasterWebSearchFields.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FillMasterWebSearchFields]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[FillMasterWebSearchFields]
GO

create procedure [dbo].[FillMasterWebSearchFields](@tokey int, @calcKey int = null, @forceEnable smallint = null, @overwritePrices bit = null)
-- if @forceEnable > 0 (by default) then make call mwEnablePriceTour @calcKey, 1 at the end of the procedure
as
begin
	-- <date>2012-09-18</date>
	-- <version>2009.2.16.1</version>
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

	update dbo.TP_Tours set TO_Progress = 0 where TO_Key = @tokey

	if dbo.mwReplIsSubscriber() > 0
	begin
		--здесь происходит update и delete цен
		if isnull(@calcKey,0) != 0 and @newRecalcPrice = 1
		begin
			declare @tempSql nvarchar(4000)
			declare @source nvarchar(200)
			declare @tempCountryKey int, @tempCityKey int
			create table #cityKeys
			( cnkey int )	
			set @source = '[mt].' + ltrim(rtrim(dbo.mwReplPublisherDB())) + '.'
		
			set @tempSql = 
				'select @tempCountryKey = to_cnkey
				 from ' + @source + 'dbo.TP_Tours with(nolock)
				 where to_key = ' + cast(@tokey as varchar)
			 
			EXEC sp_executesql @tempSql, N'@tempCountryKey int OUTPUT',
			@tempCountryKey = @tempCountryKey output; 
		
			set @tempSql = 
				'insert into #citykeys (cnkey)
				 select distinct isnull(ti_ctkeyfrom,0)
				 from ' + @source + 'dbo.TP_lists with(nolock)
				 where ti_key in (select tp_tikey from ' + @source + 'dbo.tp_prices where tp_calculatingkey = ' + cast(@calcKey as varchar) + ')' +
				 ' or ti_key in (select tpd_tikey from '+ @source + 'dbo.tp_pricesdeleted where tpd_calculatingkey = ' + cast(@calcKey as varchar) + ')'
			 
			exec (@tempSql)

			create table #updateTpPrices 
			(tp_key int, tp_gross money)
		
			set @tempSql = 
				'insert into #updateTpPrices (tp_key, tp_gross)
				 select tp_key, tp_gross
				 from ' + @source + 'dbo.TP_Prices with(nolock)
				 where tp_calculatingkey = ' 
				 + cast(@calcKey as varchar) + ' and tp_updatedate is not null'
			 
			exec (@tempSql)
		
			create table #tpKeysForDelete
			(tp_key int)
		
			set @tempSql = 
				'insert into #tpKeysForDelete (tp_key)
				 select tpd_tpkey
				 from ' + @source + 'dbo.TP_PricesDeleted with(nolock)
				 where tpd_calculatingkey = ' 
				 + cast(@calcKey as varchar)
			
			exec (@tempSql)
		
			set @tempSql = 
				'insert into #tpKeysForDelete (tp_key)
				 select PC_TPKEY
				 from ' + @source + 'dbo.TP_PricesCleaner with(nolock)
				 where PC_CalculatingKey = ' 
				 + cast(@calcKey as varchar)
			
			exec (@tempSql)

			set @tempSql = 
				'delete from' + @source + 'dbo.TP_PricesCleaner
				 where PC_CalculatingKey = ' 
				 + cast(@calcKey as varchar)
			
			exec (@tempSql)
		
			declare @tempPriceTableName varchar (200)
		
			declare curr cursor for select cnkey from #cityKeys
			OPEN curr
			FETCH NEXT FROM curr INTO @tempCityKey
			WHILE @@FETCH_STATUS = 0
			begin
		
			set @tempPriceTableName = dbo.mwGetPriceTableName(@tempCountryKey, @tempCityKey)
		
			/*set @tempSql = 
				'update ' + @tempPriceTableName + ', #updateTpPrices 
				 set pt_price = tp_gross
				 where pt_pricekey = tp_key'*/
			set @tempSql = 'update ' + @tempPriceTableName + ' set pt_price = (select tp_gross from #updateTpPrices where tp_key = pt_pricekey)'
			+ ' where pt_pricekey in (select tp_key from #updateTpPrices)'
			 
			exec (@tempSql)
		
			set @tempSql = 
				'delete ' + @tempPriceTableName + 
				' where pt_pricekey in (select tp_key from #tpKeysForDelete)'
			
			--print @tempSql
			--return
		
			exec (@tempSql)
		
			FETCH NEXT FROM curr INTO @tempCityKey
			end
		
			CLOSE curr
			DEALLOCATE curr
		
			drop table #cityKeys
			drop table #updateTpPrices
			drop table #tpKeysForDelete
		end
		--конец удаления и апдейта

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

	if(@calcKey is not null)
	begin
		insert into #tp_lists
		select
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
		from tp_lists with(nolock)
		where TI_Key in (select distinct tp_tikey from TP_Prices with(nolock) where TP_CalculatingKey = @calcKey)
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
		from tp_lists with(nolock)
		where TI_TOKey = @tokey		
	end

	declare @mwAccomodationPlaces nvarchar(254)
	declare @mwRoomsExtraPlaces nvarchar(254)
	declare @mwSearchType int
	declare @sql nvarchar(4000)
	declare @countryKey int
	declare @cityFromKey int

	declare @firsthdday int
	select @firsthdday = (select min(ts_day) 
				from tp_services with (nolock)
 				where ts_svkey = 3 and ts_tokey = @tokey)

	update #tp_lists with(rowlock)
	set
		ti_firsthotelday = @firsthdday

	update dbo.TP_Tours with(rowlock) set TO_Progress = 7 where TO_Key = @tokey

	update TP_Tours with(rowlock) set TO_MinPrice = (
			select min(TP_Gross) 
			from TP_Prices with(nolock) 
				left join TP_Lists with(nolock) on ti_key = tp_tikey
				left join HotelRooms with(nolock) on hr_key = ti_firsthrkey				
			where TP_TOKey = TO_Key 
					and hr_main > 0 
					and (isnull(HR_AGEFROM, 0) <= 0 or isnull(HR_AGEFROM, 0) > 16)
		)
		where TO_Key = @tokey

	update dbo.TP_Tours with(rowlock) set TO_Progress = 13 where TO_Key = @tokey

	update #tp_lists with(rowlock)
	set
		ti_lasthotelday = (select max(ts_day)
				from tp_servicelists  with (nolock)
					inner join tp_services with (nolock) on tl_tskey = ts_key
				where tl_tikey = ti_key and ts_svkey = 3 and TS_TOKey = @tokey and TL_TOKey = @tokey)

	update dbo.TP_Tours with(rowlock) set TO_Progress = 20 where TO_Key = @tokey

	update #tp_lists with(rowlock)
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
					inner join dbo.tp_servicelists with (nolock) on (tl_tskey = ts_key and TS_TOKey = @tokey and TL_TOKey = @tokey)
				where tl_tikey = ti_key)

	update dbo.TP_Tours with(rowlock) set TO_Progress = 30 where TO_Key = @tokey

	-- MEG00024548 Paul G 11.01.2009
	-- изменил логику подсчёта кол-ва ночей в туре
	-- раньше было сумма ночей проживания по всем отелям в туре
	-- теперь если проживания пересекаются, лишние ночи не суммируются
	update #tp_lists with(rowlock)
	set
		ti_nights = dbo.mwGetTiNights(ti_key)

	--koshelev
	--02.04.2012 MEG00040744
    declare @result nvarchar(256)
    set @result = N''
    select @result = @result + rtrim(ltrim(str(tbl.ti_nights))) + N', ' from (select distinct ti_nights from (select ti_nights from #tp_lists union select ti_nights from tp_lists where ti_tokey = @tokey ) as tbl2) tbl order by tbl.ti_nights
    declare @len int
    set @len = len(@result)
    if(@len > 0)
          set @result = substring(@result, 1, @len - 1)

    update TP_Tours with(rowlock) set TO_HotelNights = @result where TO_Key = @tokey

	update dbo.TP_Tours with(rowlock) set TO_Progress = 40 where TO_Key = @tokey

	update #tp_lists with(rowlock)
		set ti_hotelkeys = dbo.mwGetTiHotelKeys(ti_key),
			ti_hotelroomkeys = dbo.mwGetTiHotelRoomKeys(ti_key),
			ti_hoteldays = dbo.mwGetTiHotelNights(ti_key),
			ti_hotelstars = dbo.mwGetTiHotelStars(ti_key),
			ti_pansionkeys = dbo.mwGetTiPansionKeys(ti_key)

	update #tp_lists with(rowlock)
	set
		ti_hdpartnerkey = ts_oppartnerkey,
		ti_firsthotelpartnerkey = ts_oppartnerkey,
		ti_hdday = ts_day,
		ti_hdnights = ts_days
	from tp_servicelists with (nolock)
		inner join tp_services with (nolock) on (tl_tskey = ts_key and ts_svkey = 3)
	where tl_tikey = ti_key and ts_code = ti_firsthdkey and TS_TOKey = @tokey and TL_TOKey = @tokey

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
	update #tp_lists with(rowlock)
	set 
		ti_chkey = (select top 1 ts_code
			from tp_servicelists with(nolock) 
				inner join tp_services with(nolock) on tl_tskey = ts_key and ts_svkey = 1
			where tl_tikey = ti_key and ts_tokey = @tokey and tl_tokey = @tokey 
				and (ts_day <= ti_firsthotelday or (ts_day = 1 and ti_firsthotelday = 0)) and ts_subcode2 = @ctdeparturekey)

	update dbo.TP_Tours with(rowlock) set TO_Progress = 50 where TO_Key = @tokey

	-- город вылета + прямой перелет
	update #tp_lists with(rowlock)
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

	update #tp_lists with(rowlock)
	set 
		ti_ctkeyfrom = @ctdeparturekey

	-- Проверка наличия перелетов в город вылета
	declare @existBackCharter smallint
	select	@existBackCharter = count(ts_key)
	from	tp_services
	where	ts_tokey = @tokey
		and	ts_svkey = 1
		and ts_ctkey = @ctdeparturekey

	-- город прилета + обратный перелет
	update #tp_lists with(rowlock) 
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
	update #tp_lists with(rowlock)
	set 
		ti_apkeyfrom = (select top 1 ap_key from airport with(nolock), charter with(nolock) 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chkey)

	-- _ключ_ аэропорта прилета
	update #tp_lists with(rowlock)
	set 
		ti_apkeyto = (select top 1 ap_key from airport with(nolock), charter with(nolock) 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chbackkey)

	-- ключ города и ключ курорта + звезды
	update #tp_lists with(rowlock)
	set
		ti_firstctkey = hd_ctkey,
		ti_firstrskey = hd_rskey,
		ti_firsthdstars = hd_stars
	from hoteldictionary with(nolock)
	where 
		ti_firsthdkey = hd_key

	update dbo.TP_Tours with(rowlock) set TO_Progress = 60 where TO_Key = @tokey

	if dbo.mwReplIsPublisher() > 0
	begin
		declare @trkey int
		select @trkey = to_trkey from dbo.tp_tours with(nolock) where to_key = @tokey
		
		insert into dbo.mwReplTours with(rowlock) (rt_trkey, rt_tokey, rt_date, rt_CalcKey)
		values (@trkey, @tokey, getdate(), @calcKey)
		
		update CalculatingPriceLists with(rowlock) set CP_Status = 0 where CP_PriceTourKey = @tokey
		update dbo.TP_Tours with(rowlock) 
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

	--чтобы не перевыставлялись удаленные цены при выставлении тура в он-лайн
	update #tempPriceTable set pt_isenabled = 0 where exists (select 1 from mwdeleted with (nolock) where del_key = pt_pricekey)

	update dbo.TP_Tours set TO_Progress = 80 where TO_Key = @tokey
	
	if dbo.mwReplIsPublisher() <= 0
	begin
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
		from #tp_lists with(nolock) inner join tp_tours with(nolock) on ti_tokey = to_key

		-- Даты в поисковой таблице ставим как в таблице туров - чтобы не было двоений MEG00021274
		update mwspodatatable with(rowlock) 
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
					set @sql = 'delete top (' + ltrim(STR(@deleteCount)) +  ') from mwPriceDataTable with(rowlock) where pt_pricekey in (select tp_key from tp_prices with(nolock) where TP_CalculatingKey = ' + cast(@calcKey as nvarchar(20)) + '); set @counterOut = @@ROWCOUNT'
				else
					set @sql = 'delete top(' + ltrim(STR(@deleteCount)) + ') from mwPriceDataTable with(rowlock) where pt_tourkey = ' + cast(@tokey as nvarchar(20)) + ';set @counterOut = @@ROWCOUNT'
				EXECUTE sp_executesql @sql, @params, @counterOut = @counter output
			end

			-- koshelev TFS 6293
			-- перенес механизм единственной цены Мостравела в хранимку
			-- делаем хранимку стандартной
			if (exists(select 1 from SystemSettings where SS_ParmName like 'mosSinglePrice' and SS_ParmValue = '1'))
			begin
			  -- начало. удаление похожих цен
				if (@overwritePrices = 1)
				begin
					declare @delSql nvarchar(4000)
					declare @delCountry int, @delCtKeyFrom int, @delTableName nvarchar(100)
					select
						@delCountry = to_cnkey,
						@delCtKeyFrom = tl_ctdeparturekey
					from
						tp_tours with(nolock)
						inner join tbl_TurList with(nolock) on to_trkey = tl_key
					where
						to_key = @tokey

					set @delTableName = dbo.mwGetPriceTableName(@delCountry, @delCtKeyFrom)
					if(len(isnull(@delTableName, '')) > 0)
					begin
						create table #delPrices(
							del_key int
						)

						set @delSql = N'
							select pt_pricekey from ' + @delTableName + N' with(nolock) where 
							pt_tourkey <> ' + ltrim(rtrim(str(@tokey))) + ' 
							and exists (
							select top 1 1
							from  tp_lists with(nolock), TP_TurDates with(nolock)
							where ISNULL(TI_CTKEYTO, 0) = isnull(PT_CTKEYTO, 0)
									and TI_FirstHdKey = pt_hdkey and TI_FirstHrKey = pt_hrkey
								   and TI_FirstPnKey = PT_PnKey and TI_TotalDays = PT_Days and TI_Nights = PT_Nights and TI_CtKeyFrom = PT_ctkeyfrom 
								   and TD_TOKey = TI_TOKey	
   								   and TI_TOKey = '	+ ltrim(rtrim(str(@tokey))) + '		
								   and TD_Date = PT_TourDate
								   and PT_TlKey not IN (select tl_key from turlist with(nolock) where tl_tip in (6, 7, 12312230)) 
							)'
					

						insert into #delPrices exec(@delSql)
						create index x_del_key on #delPrices(del_key)

						insert into mwDeleted with(rowlock) (del_key)
						select del_key from #delPrices

						set @counter = -1
						set @params = '@counterOut int output'
						while(@counter <> 0)
						begin
							set @delSql = 'update top (50000) ' + @delTableName + ' with(rowlock) set pt_isenabled = 0 where pt_isenabled > 0 and exists(select 1 from #delPrices where del_key = pt_pricekey); set @counterOut = @@ROWCOUNT'
							EXECUTE sp_executesql @delSql, @params, @counterOut = @counter output
						end

						--exec(@delSql)
					end
				end
				--окончание
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
						set @sql = 'delete top (' + ltrim(rtrim(str(@deleteCount)))  + ') from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' with(rowlock) where pt_pricekey in (select tp_key from tp_prices with(nolock) where TP_CalculatingKey = ' + cast(@calcKey as nvarchar(20)) + '); set @counterOut = @@ROWCOUNT'
					else
						set @sql = 'delete top (' + ltrim(rtrim(str(@deleteCount))) + ') from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' with(rowlock) where pt_tourkey = ' + cast(@tokey as nvarchar(20)) + '; set @counterOut = @@ROWCOUNT'
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

		update dbo.TP_Tours set TO_Progress = 90 where TO_Key = @calcKey

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
			
	end
	
	if dbo.mwReplIsSubscriber() > 0
	begin
		delete from TP_Prices with(rowlock) where tp_tokey = @tokey
		delete from TP_ServiceLists with(rowlock) where tl_tokey = @tokey
		delete from TP_Services with(rowlock) where ts_tokey = @tokey
		delete from TP_Lists with(rowlock) where ti_tokey = @tokey
		-- don't delete from TP_Tours	
	end
	else
	begin
		update tp_lists with(rowlock)
		set
			ti_firsthdkey = ti.ti_firsthdkey,
			ti_lasthotelday = ti.ti_lasthotelday,
			ti_totaldays = ti.ti_totaldays,
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
			(tp_lists.TI_CalculatingKey = @calcKey or @calcKey is null)
			and tp_lists.TI_Key = ti.TI_Key
	end

	if(@forceEnable > 0 and @calcKey is null)
	begin
		exec mwEnablePriceTourNewSinglePrice @tokey, '#tempPriceTable'

		update tp_tours with(rowlock)
		set to_isenabled = 1
		where to_key = @tokey
	end
		
	drop table #tempPriceTable

	update dbo.TP_Tours with(rowlock)
	set TO_Update = 0,
		TO_Progress = 100,
		TO_DateCreated = GetDate(),
		TO_UpdateTime = GetDate()
	where
		TO_Key = @tokey

	EXECUTE mwFillPriceListDetails @tokey

end
GO

GRANT EXEC ON [dbo].[FillMasterWebSearchFields] TO PUBLIC
GO
/*********************************************************************/
/* end sp_FillMasterWebSearchFields.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetPricePage.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetPricePage]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetPricePage]
GO

CREATE PROCEDURE [dbo].[sp_GetPricePage]
(
--<VERSION>2009.2.17.0</VERSION>
--<DATE>2013-02-04</DATE>
     @TurKey   int,
     @MinID     int,
     @SizePage     int
)
AS

DECLARE @TP_PRICES AS TABLE(xTP_Key [int] NOT NULL PRIMARY KEY CLUSTERED, xTP_TIKEY [int])

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
GRANT EXECUTE ON [dbo].[GetServiceList] TO Public
GO

/*********************************************************************/
/* end sp_GetPricePage.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetQuotaLoadListData_N.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetQuotaLoadListData_N]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetQuotaLoadListData_N]
GO

CREATE procedure [dbo].[GetQuotaLoadListData_N]
(
--<VERSION>2009.2.17.2</VERSION>
--<DATE>2012-11-06</DATE>
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
@nGridFilter int = 0              -- фильтр в зависимости от экрана
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

--SELECT * FROM #StopSaleTemp

CREATE TABLE #QuotaLoadList(QL_ID int identity(1,1),
QL_QTID int, QL_QOID int, QL_PRKey int, QL_SubCode1 int, QL_SubCode2 int, QL_PartnerName nvarchar(100) collate Cyrillic_General_CI_AS, QL_Description nvarchar(255) collate Cyrillic_General_CI_AS, 
QL_dataType smallint, QL_Type smallint, QL_TypeQuota smallint, QL_Release int, QL_Durations nvarchar(20) collate Cyrillic_General_CI_AS, QL_FilialKey int, 
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
				and (QP_Durations='' or (@DurationLocal is null or (@DurationLocal is not null and exists (Select QL_QPID From QuotaLimitations (nolock) WHERE QL_Duration=@DurationLocal and QL_QPID=QP_ID))))
				and ISNULL(QP_IsDeleted,0)=0
				and ISNULL(QD_IsDeleted,0)=0			
				and (@DLKey is null or (@DLKey is not null
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
		print @QueryUpdate1
	end
	--если релиз период наступил сегодня
	if DATEADD(DAY,ISNULL(@QD_Release,0),DATEADD(hh,0,GETDATE()- {fn CURRENT_time()})) = @Date
	begin
		set @QueryUpdate1=', QL_DateCheckInMin=''' + CAST(@Date as varchar(250)) + ''''
		print @QueryUpdate1
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
		exec GetSvCode1Name @Service_SVKey, @DL_SubCode1, null, @Temp output, null, null

		Update #QuotaLoadList set QL_Description=ISNULL(QL_Description,'') + @Temp where QL_SubCode1=@DL_SubCode1
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
				EXEC GetRoomName @QO_SubCode, @Temp output, null
				print @Temp
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

CLOSE curQLoadListQO
DEALLOCATE curQLoadListQO


/*
-- 29-03-2012 karimbaeva удаляю строки, чтобы не дублировались при выводе в окне, если стоп стоит по нескольким типам номеров
delete from #QuotaLoadList where ql_qoid <> (select top 1  ql_qoid from #QuotaLoadList) and ql_qoid is not null
*/

If @Service_SVKey=3
BEGIN
	Update #QuotaLoadList set QL_Description = QL_Description + ' - Per person' where QL_ByRoom = 0
END

-- удаляем вспомогательный столбец
alter table #QuotaLoadList drop column QL_QOID
alter table #QuotaLoadList drop column QL_SubCode2
alter table #QuotaLoadList drop column QL_ID

IF @ResultType is null or @ResultType not in (10)
BEGIN
	select *
	from #QuotaLoadList (nolock)
	order by
		(case
		when QL_QTID is not null then 1
		else 0
		end) DESC,
		QL_Description/*Сначала квоты, потом неквоты*/,QL_PartnerName,QL_Type DESC,QL_Release,
		--сортируем по первому числу продолжительности если продолжительность с "-",","," "
		case 
		when CHARINDEX('-',QL_DURATIONS) <>0 then CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX('-',QL_DURATIONS)))
		when CHARINDEX(',',QL_DURATIONS) <>0 then CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX(',',QL_DURATIONS)))
		when CHARINDEX(' ',QL_DURATIONS) <>0 then CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX(' ',QL_DURATIONS)))
		when CHARINDEX('-',QL_DURATIONS) = 0 then CONVERT(int,QL_DURATIONS)
		end,
		QL_CityDepartments,QL_FilialKey,QL_CustomerInfo,QL_QTID,QL_DataType
	RETURN 0
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
grant execute on [dbo].[GetQuotaLoadListData_N] to public
GO
/*********************************************************************/
/* end sp_GetQuotaLoadListData_N.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetServiceList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceList]
GO

CREATE procedure [dbo].[GetServiceList] 
(
--<VERSION>2009.2.17.1</VERSION>
--<DATE>2012-11-19</DATE>
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
@State smallint=null,
@SubCode2 int = null
)
as 

--koshelev
--2012-07-19 TFS 6699 блокировки на базе мешали выполнению хранимки, вынужденная мера
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @Query varchar(8000)
 
CREATE TABLE #Result
(
	DG_Code nvarchar(max), DG_Key int, DG_DiscountSum money, DG_Price money, DG_Payed money,
	DG_PriceToPay money, DG_Rate nvarchar(3), DG_NMen int, PR_Name nvarchar(max), CR_Name nvarchar(max),
	DL_Key int, DL_NDays int, DL_NMen int, DL_Reserved int, DL_CTKeyTo int, DL_CTKeyFrom int, DL_CNKEYFROM int,
	DL_SubCode1 int, TL_Key int, TL_Name nvarchar(max), TUCount int, TU_NameRus nvarchar(max), TU_NameLat nvarchar(max),
	TU_FNameRus nvarchar(max), TU_FNameLat nvarchar(max), TU_Key int, TU_Sex Smallint, TU_PasportNum nvarchar(max),
	TU_PasportType nvarchar(max), TU_PasportDateEnd datetime, TU_BirthDay datetime, TU_Hotels nvarchar(max),
	Request smallint, Commitment smallint, Allotment smallint, Ok smallint, TicketNumber nvarchar(max),
	FlightDepDLKey int, FligthDepDate datetime, FlightDepNumber nvarchar(max), ServiceDescription nvarchar(max),
	ServiceDateBeg datetime, ServiceDateEnd datetime, RM_Name nvarchar(max), RC_Name nvarchar(max), SD_RLID int,
	TU_SNAMERUS nvarchar(max), TU_SNAMELAT nvarchar(max), TU_IDKEY int, OkWait smallint
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
		SD_State int,
		SD_QPIdOld int
	)

	-- вносим все записи которые нам могут подойти
	insert into #TempServiceByDate(SD_Date, SD_DLKey, SD_RLID, SD_QPID,	SD_TUKey, SD_RPID, SD_State, SD_QPIdOld)
	select SD_Date, SD_DLKey, SD_RLID, SD_QPID,	SD_TUKey, SD_RPID, SD_State, SD_QPIdOld
	from ServiceByDate as SSD join Dogovorlist on DL_KEY = SD_DLKey
	where DL_SVKEY = @SVKey
	and DL_CODE = convert(int, @Codes)
	and ((@SubCode1 is null) or (DL_SUBCODE1 = @SubCode1))
	and ((@QPID is null) or (SD_QPID = @QPID))
	and ((@State is null) or (SD_State = @State))
	--mv 24.10.2012 не понячл зачем нужен был подзапрос, но точно он приводил к следущей проблеме
	-- если отбираем с фильтром по статусу, то статус проверял на любой из дней, а не тот на который формируется список
	and SSD.SD_Date = @Date
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


	SET @Query = '
		INSERT INTO #Result (DG_Code, DG_Key, DG_DiscountSum, DG_Price, DG_Payed, 
		DG_PriceToPay, DG_Rate, DG_NMen, 
		PR_Name, CR_Name, 
		DL_Key, DL_NDays, DL_NMen, DL_Reserved, DL_CTKeyTo, DL_CTKeyFrom, DL_SubCode1, ServiceDateBeg, ServiceDateEnd, 
		TL_Key, TUCount, TU_NameRus, TU_NameLat, TU_FNameRus, TU_FNameLat, TU_Key, 
		TU_Sex, TU_PasportNum, TU_PasportType, TU_PasportDateEnd, TU_BirthDay, TicketNumber, TU_SNAMERUS, TU_SNAMELAT, TU_IDKEY)
		SELECT	  DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, 
		(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, 
		DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + '=3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END,
		DG_TRKey, 0, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS, TU_FNAMELAT, SD_TUKey, case when SD_TUKey > 0 then isnull(TU_SEX,0) else null end, TU_PASPORTTYPE + ''№'' + TU_PASPORTNUM, TU_PASPORTTYPE, 
		TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, TU_SNAMERUS, TU_SNAMELAT, TU_IDKEY
		FROM  Dogovor join Dogovorlist on dl_dGKEY = DG_KEY
		left join Partners on dl_agent = pr_key
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
				SET @Query=@Query + 'and exists (SELECT top 1 SD_DLKEY FROM #TempServiceByDate, QuotaParts WHERE SD_QPID=QP_ID and QP_QDID IN (' + CAST(@QDID as varchar(20)) + ') and SD_DLKEY=DL_Key and sd_tukey = tu_tukey)'
		END
				
		if (@SubCode1 != '0')
			SET @Query=@Query + ' AND DL_SUBCODE1 in (' + CAST(@SubCode1 as varchar(20)) + ')'
		IF @State is not null
			SET @Query=@Query + ' and SD_State=' + CAST(@State as varchar(1))
		if (@SubCode2 != '0')
			SET @Query=@Query + ' AND DL_SUBCODE2 in (' + CAST(@SubCode2 as varchar(20)) + ')'
		SET @Query=@Query + ' 
		group by DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, DG_PDTTYPE, DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, DL_DateBeg,
		DL_DateEnd, DG_TRKey, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS,
		TU_FNAMELAT, SD_TUKey, TU_SEX, TU_PASPORTNUM, TU_PASPORTTYPE, TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, TU_SNAMERUS, TU_SNAMELAT, TU_IDKEY'
end
else
begin
	SET @Query = '
		INSERT INTO #Result (DG_Code, SD_RLID, RM_Name, RC_Name, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		DG_PriceToPay, DG_RATE, DG_NMEN,
		PR_NAME, CR_NAME, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKeyTo, DL_SubCode1,
		ServiceDateBeg, ServiceDateEnd, TL_Key, TUCount, DL_Key, DL_CTKeyFrom)
		select DG_CODE, SD_RLID, RM_Name, RC_Name, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		(case when DG_PDTTYPE = 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN,
		PR_NAME, CR_NAME, DL_NDays, 
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
		left join Partners on dl_agent = pr_key
		join Dogovor on dl_dGKEY = DG_KEY
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
		PR_NAME, CR_NAME, DL_NDays, DL_RESERVED, DL_CTKey, DL_SubCode2,
		DL_DateBeg, DL_DateEnd, DG_TRKey, RM_Name, RC_Name, QT_ByRoom, DL_KEY'
end

--PRINT @Query
EXEC (@Query)
 
UPDATE #Result SET #Result.TL_Name=(SELECT TL_Name FROM TurList WHERE #Result.TL_Key=TurList.TL_Key)

--select * from  #Result

if @TypeOfRelult=1
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=1)
	--saifullina 14-11-2012 task 9326 добавлена новая колонка чтобы менеджер имел возможность отличать туристов, которые ждут посадки на квоту, от реально подтвержденных вне квоты
	UPDATE #Result SET #Result.OkWait=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=3 AND SD_QPIDOld is not null)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_DLKey = #Result.DL_Key AND SD_State=3)-#Result.OkWait
END
else
BEGIN
	UPDATE #Result SET #Result.Request=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=4)
	UPDATE #Result SET #Result.Commitment=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=2)
	UPDATE #Result SET #Result.Allotment=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=1)
	--saifullina 14-11-2012 task 9326 добавлена новая колонка чтобы менеджер имел возможность отличать туристов, которые ждут посадки на квоту, от реально подтвержденных вне квоты
	UPDATE #Result SET #Result.OkWait=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=3 AND SD_QPIDOld is not null)
	UPDATE #Result SET #Result.Ok=(SELECT COUNT(*) FROM #TempServiceByDate WHERE SD_DLKey=#Result.DL_Key AND SD_TUKey=#Result.TU_Key and SD_State=3)-#Result.OkWait
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

/*********************************************************************/
/* end sp_GetServiceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetServiceLoadListData.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceLoadListData]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetServiceLoadListData]
GO

create procedure [dbo].[GetServiceLoadListData]
(
--<VERSION>2009.2.19</VERSION>
--<DATE>2013-05-06</DATE>
@SVKey int,
@Code int,
@PRKey int =null,-- @PRKEY=null все
@DateStart smalldatetime = null,
@DaysCount int,
@CityDepartureKey int = null,-- город вылета
@bShowByRoom     bit =null,  -- показывать информацию по номерам (по умолчанию по людям)
@bShowByPartner  bit =null,  -- информацию разделять по партнерам
@bShowState      bit =null,  -- показать статус бронирования (запрос, на квоте, Ok) 
@bShowCommonInfo bit =null  -- показывать общую информацию по загрузке услуги
)
as 
/*
insert into debug (db_date,db_n1,db_n2,db_n3) values (@DateStart,@DaysCount,@SVKey,89)
insert into debug (db_date,db_n1,db_n2,db_n3) values (@DateStart,@PRKey,@bShowByRoom,88)
insert into debug (db_date,db_n1,db_n2,db_n3) values (@DateStart,@bShowByPartner,@bShowState,87)
insert into debug (db_date,db_n1,db_n2,db_n3) values (@DateStart,@bShowCommonInfo,@Code,86)
*/
if @SVKey!=3
	Set @bShowByRoom=0

DECLARE @DateEnd smalldatetime
Set @DateEnd = DATEADD(DAY, @DaysCount-1, @DateStart)

CREATE TABLE #ServiceLoadList
(
SL_ID INT IDENTITY(1,1) NOT NULL, 
SL_ServiceName nvarchar(100), SL_State smallint,
SL_SubCode1 int, SL_SubCode2 int, SL_PRKey int
/*SL_DataType это мнимая колонка, есть только при выводе результата 
содержит тип информации для записей с итогами
(1 - общий итог, 2 - данные по услуге)
*/
)
DECLARE @n int, @nMax int, @str nvarchar(max),@SL_SubCode1 int, @SL_SubCode2 int, @s nvarchar(1), @ServiceName nvarchar(255), @ServiceName_1 nvarchar(255)
set @n=1 

WHILE @n <= @DaysCount
BEGIN
	set @str = 'ALTER TABLE #ServiceLoadList ADD SL_' + CAST(@n as nvarchar(3)) + ' nvarchar(20)'
	exec (@str)
	set @n = @n + 1
END

if @SVKey != 8
begin
	if @bShowByPartner =1 and @bShowState=1
	insert into #ServiceLoadList (SL_SubCode1, SL_PRKey, SL_State)
		select distinct DL_SubCode1, DL_PartnerKey, ISNULL(SD_State,0) from DogovorList, ServiceByDate, Dogovor
		where	SD_DLKey=DL_Key and DG_Key=DL_DGKey and DL_SVKey=@SVKey and DL_Code=@Code and SD_Date between @DateStart and @DateEnd and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
else if @bShowByPartner =0 and @bShowState=1
	insert into #ServiceLoadList (SL_SubCode1, SL_State)
		select distinct DL_SubCode1, ISNULL(SD_State,0) from DogovorList, ServiceByDate, Dogovor
		where	SD_DLKey=DL_Key and DG_Key=DL_DGKey and DL_SVKey=@SVKey and DL_Code=@Code and SD_Date between @DateStart and @DateEnd and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
else if @bShowByPartner =1 and @bShowState=0
	insert into #ServiceLoadList (SL_SubCode1, SL_PRKey)
		select distinct DL_SubCode1, DL_PartnerKey from DogovorList, Dogovor
		where	DL_SVKey=@SVKey and DG_Key=DL_DGKey and DL_Code=@Code and ((DL_DateBeg between @DateStart and @DateEnd) or (DL_DateEnd between @DateStart and @DateEnd)) and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
else
	insert into #ServiceLoadList (SL_SubCode1)
		select distinct DL_SubCode1 from DogovorList, Dogovor
		where	DL_SVKey=@SVKey and DG_Key=DL_DGKey and DL_Code=@Code and ((DL_DateBeg between @DateStart and @DateEnd) or (DL_DateEnd between @DateStart and @DateEnd)) and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
end if @SVKey = 8
begin 
	if @bShowByPartner =1 and @bShowState=1
		insert into #ServiceLoadList (SL_SubCode1, SL_SubCode2, SL_PRKey, SL_State)
			select distinct DL_SubCode1, DL_SubCode2, DL_PartnerKey, ISNULL(SD_State,0) from DogovorList, ServiceByDate, Dogovor
			where	SD_DLKey=DL_Key and DG_Key=DL_DGKey and DL_SVKey=@SVKey and DL_Code=@Code and SD_Date between @DateStart and @DateEnd and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
	else if @bShowByPartner =0 and @bShowState=1
		insert into #ServiceLoadList (SL_SubCode1, SL_SubCode2, SL_State)
			select distinct DL_SubCode1, DL_SubCode2, ISNULL(SD_State,0) from DogovorList, ServiceByDate, Dogovor
			where	SD_DLKey=DL_Key and DG_Key=DL_DGKey and DL_SVKey=@SVKey and DL_Code=@Code and SD_Date between @DateStart and @DateEnd and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
	else if @bShowByPartner =1 and @bShowState=0
		insert into #ServiceLoadList (SL_SubCode1, SL_SubCode2, SL_PRKey)
			select distinct DL_SubCode1, DL_SubCode2, DL_PartnerKey from DogovorList, Dogovor
			where	DL_SVKey=@SVKey and DG_Key=DL_DGKey and DL_Code=@Code and ((DL_DateBeg between @DateStart and @DateEnd) or (DL_DateEnd between @DateStart and @DateEnd)) and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
	else
		insert into #ServiceLoadList (SL_SubCode1, SL_SubCode2)
			select distinct DL_SubCode1, DL_SubCode2 from DogovorList, Dogovor
			where	DL_SVKey=@SVKey and DG_Key=DL_DGKey and DL_Code=@Code and ((DL_DateBeg between @DateStart and @DateEnd) or (DL_DateEnd between @DateStart and @DateEnd)) and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
end
 
while exists(select SL_SubCode1 from #ServiceLoadList where SL_ServiceName is null)
BEGIN
	if @SVKey != 8
	begin
		select @SL_SubCode1=SL_SubCode1 from #ServiceLoadList where SL_ServiceName is null
		exec GetSvCode1Name @SVKey,@SL_SubCode1,@s output,@ServiceName output,@s output,@s output
		UPDATE #ServiceLoadList SET SL_ServiceName = COALESCE(@ServiceName, '') where SL_SubCode1=@SL_SubCode1
	end if @SVKey = 8
	begin
		select @SL_SubCode1=SL_SubCode1, @SL_SubCode2=SL_SubCode2 from #ServiceLoadList where SL_ServiceName is null
		exec GetSvCode1Name @SVKey,@SL_SubCode1,@s output,@ServiceName output,@s output,@s output
		exec dbo.GetSvCode2Name @SVKey, @SL_SubCode2, @ServiceName_1 output, @s output
		UPDATE #ServiceLoadList SET SL_ServiceName = COALESCE(@ServiceName, '') + N',' + COALESCE(@ServiceName_1, '') where SL_SubCode1=@SL_SubCode1 and SL_SubCode2=@SL_SubCode2
	end 
END

If @bShowByRoom=1
begin

	DECLARE curSLoadList CURSOR FOR SELECT
		'UPDATE #ServiceLoadList SET SL_' + CAST(CAST(SD_Date-@DateStart+1 as int) as nvarchar(5)) + '= ISNULL(SL_' + CAST(CAST(SD_Date-@DateStart+1 as int) as nvarchar(5)) + ',0)+' + CAST(Count(Distinct SD_RLID) as nvarchar(5)) + ' WHERE SL_SubCode1=' + CAST(DL_SubCode1 as nvarchar(10)) + CASE WHEN @bShowByPartner=1 THEN ' AND SL_PRKey=' + CAST(DL_PartnerKey as nvarchar(10)) ELSE '' END + CASE WHEN @bShowState=1 THEN ' AND SL_State=' + CAST(ISNULL(SD_STATE,0) as nvarchar(10)) ELSE '' END
		from	DogovorList,ServiceByDate, Dogovor 
		where	SD_DLKey=DL_Key and DG_Key=DL_DGKey
				and DL_SVKey=@SVKey and DL_Code=@Code 
				and DL_DateBeg<=@DateEnd and DL_DateEnd>=@DateStart
				and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
				and SD_Date<=@DateEnd and SD_Date>=@DateStart
		group by SD_Date,DL_SubCode1,DL_PartnerKey,SD_State
end
Else
begin

	DECLARE curSLoadList CURSOR FOR SELECT
		'UPDATE #ServiceLoadList SET SL_' + CAST(CAST(SD_Date-@DateStart+1 as int) as nvarchar(5)) + '= ISNULL(SL_' + CAST(CAST(SD_Date-@DateStart+1 as int) as nvarchar(5)) + ',0)+' + CAST(Count(SD_ID) as nvarchar(5)) + ' WHERE SL_SubCode1=' + CAST(DL_SubCode1 as nvarchar(10)) + CASE WHEN @SVKey=8 THEN 'AND SL_SubCode2=' + CAST(DL_SUBCODE2 as nvarchar(10)) ELSE '' END + CASE WHEN @bShowByPartner=1 THEN ' AND SL_PRKey=' + CAST(DL_PartnerKey as nvarchar(10)) ELSE '' END + CASE WHEN @bShowState=1 THEN ' AND SL_State=' + CAST(ISNULL(SD_STATE,0) as nvarchar(10)) ELSE '' END
		from	DogovorList,ServiceByDate, Dogovor 
		where	SD_DLKey=DL_Key and DG_Key=DL_DGKey
				and DL_SVKey=@SVKey and DL_Code=@Code
				and DL_DateBeg<=@DateEnd and DL_DateEnd>=@DateStart
				and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) 
				and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
				and SD_Date<=@DateEnd and SD_Date>=@DateStart
		group by SD_Date,DL_SubCode1,DL_PartnerKey,SD_State, DL_SVKey, DL_SUBCODE2
end
		

OPEN curSLoadList
FETCH NEXT FROM curSLoadList INTO	@str
WHILE @@FETCH_STATUS = 0
BEGIN
	--print @DateStart
	--print @str
	exec (@str)
	FETCH NEXT FROM curSLoadList INTO	@str
END
CLOSE curSLoadList
DEALLOCATE curSLoadList

Set @str = ''
set @n=1
set @str = @str + 'SELECT SL_ServiceName, SL_State, SL_SubCode1, ' + CASE WHEN @SVKey=8 THEN 'SL_SubCode2, ' ELSE '' END + ' SL_PRKey '
WHILE @n <= @DaysCount
BEGIN
	--print @str
	set @str = @str + ', SL_' + CAST(@n as nvarchar(3)) 
	set @n = @n + 1
END
/*
Set @str = @str + ' from #QuotaLoadList, Numbers where NU_ID between 1 and 3
and QL_IsQD=0
order by QL_Type,QL_Release,QL_Durations,QL_CityDepartments,QL_FilialKey,QL_CustomerInfo,NU_ID'
*/
Set @str = @str + ' from #ServiceLoadList order by SL_ServiceName, SL_SubCode1, ' + CASE WHEN @SVKey=8 THEN 'SL_SubCode2,' ELSE '' END + ' SL_PRKey, SL_State'

exec (@str)
GO

grant execute on [dbo].[GetServiceLoadListData] to public
GO
/*********************************************************************/
/* end sp_GetServiceLoadListData.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetSvCode1Name.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSvCode1Name]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure [dbo].[GetSvCode1Name]
GO
CREATE PROCEDURE [dbo].[GetSvCode1Name]
(
--<VERSION>2009.2.17.1</VERSION>
--<DATA>09.01.2013</DATA>
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
			
			if isnull((select SS_ParmValue from SystemSettings where SS_ParmName = 'CartAccmdMenTypeView'), 0) = 0
			begin
				SELECT @nHrMain = IsNull(HR_Main, 0), @nAgeFrom = IsNull(HR_AgeFrom, 0), @nAgeTo = IsNull(HR_AgeTo, 0), @sAcCode = IsNull(AC_Name, '') FROM dbo.HotelRooms, dbo.AccmdMenType WHERE (HR_Key = @nCode1) AND (HR_AcKey = AC_Key)				
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
		-- Task 10655 09.01.2013 kolbeshkin: исправил задвоение размещения, если оно не основное
		If @nHrMain <= 0 and charindex(isnull(@sAcCode, ''), @sName) = 0
		begin				
			  Set @sName = @sName + ',' + isnull(@sAcCode, '')
              Set @sNameLat = @sNameLat + ',' + isnull(@sAcCode, '')
                      
		END
		ELSE
			-- Task 8610 05.10.2012 kolbeshkin: если возраст уже есть в названии размещения, то второй раз не добавляем
			IF ((@nAgeFrom > 0) or (@nAgeTo > 0)) and charindex('(' + @sTmp + ')', @sName) = 0
			BEGIN
				print @sTmp
				SET @sName =  @sName + ' (' + @sTmp + ')'
				SET @sNameLat = @sNameLat + ' (' + @sTmp + ')'				
			END
	END
GO
GRANT EXECUTE ON [dbo].[GetSvCode1Name] TO PUBLIC
GO
/*********************************************************************/
/* end sp_GetSvCode1Name.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_MarginMonitor_Geographic.sql */
/*********************************************************************/
if  exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].[MarginMonitor_Geographic]') and type in (N'P', N'PC'))
	drop procedure [dbo].[MarginMonitor_Geographic]
go

--<version>2009.2.08</version>
--<data>2012-12-14</data>
-- Заполнение блока География в Маржинальном мониторе.
-- Последовательно загружает содержимое блока и позволяет заполнить весь блок одним запросом со стороны клиента.
-- Если не был передан ключ страны, то загружаются все страны и типы городов.
-- Если была передана страна, то загружаются все города, но список стран уже не загружается.
-- Если была передана страна и город прилета, то грузятся города проживания и вылета, но страны и города прилета не грузятся.
-- Если передан город прилета "Без перелета" (-1), то города вылета не грузятся.

create procedure [dbo].[MarginMonitor_Geographic]
(
	@countryKey      int = null,                    -- ключ выбранной страны
	@flightCityKey   int = null,                    -- ключ выбранного города прилета ('-1' если выбрали "Без перелета")
	@targetCityKeys  xml (dbo.ArrayOfInt) = null    -- ключи выбранных городов проживания
) as begin

set nocount on

declare @beginTime datetime

declare @targetCityKeysTable table (targetCityKey int)
insert into @targetCityKeysTable(targetCityKey)
select tbl.res.value('.', 'int')
from @targetCityKeys.nodes('/ArrayOfInt/int') as tbl(res)


-- таблицы с результатами выборки стран и городов
declare @countriesTable       table (id int, name varchar(200))
declare @flightCitiesTable    table (id int, name varchar(200))
declare @targetCitiesTable    table (id int, name varchar(200))
declare @departureCitiesTable table (id int, name varchar(200))


set @beginTime = GETDATE()
-- выборка стран
if (@countryKey is null) begin
	insert into @countriesTable(id, name)
	select distinct CN_KEY, CN_NAME
	from TP_Tours with(nolock)
	join Country with(nolock) on CN_Key = TO_CNKey
	order by CN_Name asc
	
	-- в качестве выбранной страны берем первую
	set @countryKey = (select top 1 id from @countriesTable)
end
PRINT 'выборка стран: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))


set @beginTime = GETDATE()
-- выборка городов прилета
-- если есть туры без перелетов, то первое значение в выборке будет '-1'
if (@flightCityKey is null) begin
	insert into @flightCitiesTable(id, name)
	select distinct isnull(CT_Key, -1), CT_Name
	from TP_Tours with(nolock)
	left join TurService     with(nolock) on TS_TRKey = TO_TRKey and TS_SVKey = 1
	left join CityDictionary with(nolock) on CT_Key = TS_CTKey
	where (TO_CNKey = @countryKey) and (TS_Key is null or TS_Day = 1)
	order by CT_Name asc
	
	-- в качестве выбранного города прилета берем первый, который не равен значению "Без перелета"
	set @flightCityKey = (select top 1 id from @flightCitiesTable where id != -1)
end
PRINT 'выборка городов прилета: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))


set @beginTime = GETDATE()
-- выборка городов проживания
if (@targetCityKeys is null) begin
	insert into @targetCitiesTable(id, name)
	select distinct CT_Key, CT_Name
	from TP_Tours with(nolock)
	left join TurService c with(nolock) on c.TS_TRKEY = TO_TRKey and c.TS_SVKEY = 1
	join TurService h      with(nolock) on h.TS_TRKEY = TO_TRKey and h.TS_SVKEY = 3
	join CityDictionary    with(nolock) on CT_Key = h.TS_CTKey
	where (TO_CNKey = @countryKey)
	  and ((@flightCityKey != -1 and c.TS_CTKey = @flightCityKey and c.TS_Day = 1) or (@flightCityKey = -1 and c.TS_Key is null))
	order by CT_Name asc
	
	-- в качестве выбранного города проживания берем первый город
	insert into @targetCityKeysTable(targetCityKey)
	select top 1 id from @targetCitiesTable
end
PRINT 'выборка городов проживания: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))


set @beginTime = GETDATE()
-- выборка городов вылета
if (@flightCityKey != -1)
	insert into @departureCitiesTable(id, name)
	select distinct CT_Key, CT_Name
	from TP_Tours with(nolock)
	join TurService ch   with(nolock) on ch.TS_TRKey = TO_TRKey
	join TurService h    with(nolock) on h.TS_TRKEY = TO_TRKey and h.TS_SVKEY = 3
	join HotelDictionary with(nolock) on HD_Key = h.TS_CODE
	join CityDictionary  with(nolock) on CT_Key = ch.TS_SubCode2
	where (TO_CNKey = @countryKey) and
		  (ch.TS_SVKey = 1) and
		  (ch.TS_CTKey = @flightCityKey) and
		  (HD_CTKey in (select targetCityKey from @targetCityKeysTable)) and
		  (ch.TS_Day = 1)
	order by CT_Name asc
PRINT 'выборка городов вылета: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))


-- возвращаем результаты
select * from @countriesTable
select * from @flightCitiesTable
select * from @targetCitiesTable
select * from @departureCitiesTable

end
go

grant exec on [dbo].[MarginMonitor_Geographic] to public
go

/*********************************************************************/
/* end sp_MarginMonitor_Geographic.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_MarginMonitor_GetHotels.sql */
/*********************************************************************/
if  exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].[MarginMonitor_GetHotels]') and type in (N'P', N'PC'))
	drop procedure [dbo].[MarginMonitor_GetHotels]
go

--<version>2009.2.08</version>
--<data>2012-12-14</data>
--РҐСЂР°РЅРёРјРєР° РІРѕР·РІСЂР°С‰Р°РµС‚ РѕС‚РµР»Рё РґР»СЏ РњР°СЂР¶РёРЅР°Р»СЊРЅРѕРіРѕ РјРѕРЅРёС‚РѕСЂР°
create procedure [dbo].[MarginMonitor_GetHotels]
(
	@departureCityKey int,
	@flightCityKey int,
	@targetCitiesKeys xml ([dbo].[ArrayOfInt]),
	@tourDates xml ([dbo].[ArrayOfDatetime]),
	@longs xml ([dbo].[ArrayOfInt]) = null
) as begin

set nocount on

declare @targetCitiesKeysTable table (targetCityKey int)
insert into @targetCitiesKeysTable(targetCityKey)
select tbl.res.value('.', 'int') from @targetCitiesKeys.nodes('/ArrayOfInt/int') as tbl(res)

declare @tourDatesTable table (tourDate datetime)
insert into @tourDatesTable(tourDate)
select tbl.res.value('.', 'datetime') from @tourDates.nodes('/ArrayOfDateTime/dateTime') as tbl(res)

declare @longsTable table (long int)
insert into @longsTable(long)
select tbl.res.value('.', 'int') from @longs.nodes('/ArrayOfInt/int') as tbl(res)

select distinct HD_Key, HD_Name, HD_Stars
from TP_Lists with(nolock)
join TP_PriceComponents with(nolock) on PC_TIKey = TI_Key
join HotelDictionary    with(nolock) on HD_Key = TI_FirstHDKey
join TP_ServiceLists    with(nolock) on TL_TIKey = TI_Key
left join TP_Services   with(nolock) on TS_Key = TL_TSKey and TS_SVKey = 1
where
  (PC_TourDate in (select tourDate from @tourDatesTable))
  and ((@flightCityKey != -1 and TS_CTKey = @flightCityKey and TS_SubCode2 = @departureCityKey and TS_Day = 1)
        or
       (@flightCityKey = -1 and TS_Key is null))
  and (HD_CTKey in (select targetCityKey from @targetCitiesKeysTable))
  and (@longs is null or TI_Days in (select long from @longsTable))
order by HD_Name asc

end
go


grant exec on [dbo].[MarginMonitor_GetHotels] to public
go


/*********************************************************************/
/* end sp_MarginMonitor_GetHotels.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_MarginMonitor_GetRoomCategoriesAndPansions.sql */
/*********************************************************************/
if  exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].[MarginMonitor_GetRoomCategoriesAndPansions]') and type in (N'P', N'PC'))
	drop procedure [dbo].[MarginMonitor_GetRoomCategoriesAndPansions]
go


--<version>2009.2.08</version>
--<data>2012-12-14</data>
--Р’РѕР·РІСЂР°С‰Р°РµС‚ РєР°С‚РµРіРѕСЂРёРё РЅРѕРјРµСЂРѕРІ Рё РїРёС‚Р°РЅРёСЏ РґР»СЏ Р·Р°РґР°РЅРЅРѕРіРѕ РѕС‚РµР»СЏ.
create procedure [dbo].[MarginMonitor_GetRoomCategoriesAndPansions]
(
	@hotelKeys xml ([dbo].[ArrayOfInt]),
	@tourDates xml ([dbo].[ArrayOfDatetime])
) as begin

set nocount on

declare @hotelKeysTable table (hotelKey int)
insert into @hotelKeysTable(hotelKey)
select tbl.res.value('.', 'int') from @hotelKeys.nodes('/ArrayOfInt/int') as tbl(res)

declare @tourDatesTable table (tourDate datetime)
insert into @tourDatesTable(tourDate)
select tbl.res.value('.', 'datetime') from @tourDates.nodes('/ArrayOfDateTime/dateTime') as tbl(res)


-- РІС‹Р±РёСЂР°РµРј РєР°С‚РµРіРѕСЂРёРё РЅРѕРјРµСЂРѕРІ
select distinct RC_Key, RC_Name
from TP_Lists with(nolock)
join TP_TurDates   with(nolock) on TD_TOKey = TI_TOKey
join HotelRooms    with(nolock) on HR_Key = TI_FirstHRKey
join RoomsCategory with(nolock) on RC_Key = HR_RCKey
where
  TI_FirstHDKey in (select hotelKey from @hotelKeysTable)
  and TD_Date in (select tourDate from @tourDatesTable)
order by RC_Name asc


--РІС‹Р±РёСЂР°РµРј С‚РёРїС‹ РїРёС‚Р°РЅРёР№
select distinct PN_Key, PN_Name
from TP_Lists with(nolock)
join TP_TurDates with(nolock) on TD_TOKey = TI_TOKey
join Pansion     with(nolock) on TI_FirstPNKey = PN_Key
where
  TI_FirstHDKey in (select hotelKey from @hotelKeysTable)
  and TD_Date in (select tourDate from @tourDatesTable)
order by PN_Name asc


end
go


grant exec on [dbo].[MarginMonitor_GetRoomCategoriesAndPansions] to public
go



/*********************************************************************/
/* end sp_MarginMonitor_GetRoomCategoriesAndPansions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_MarginMonitor_GetTourDates.sql */
/*********************************************************************/
SET QUOTED_IDENTIFIER ON
GO

if  exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].[MarginMonitor_GetTourDates]') and type in (N'P', N'PC'))
	drop procedure [dbo].[MarginMonitor_GetTourDates]
go

--<version>2009.2.08</version>
--<data>2013-02-12</data>
--Заполнение дат в календаре для Маржинального монитора.
create procedure [dbo].[MarginMonitor_GetTourDates]
(
	@departureCityKey int,
	@flightCityKey int,
	@targetCitiesKeys xml ([dbo].[ArrayOfInt]),
	@longs xml ([dbo].[ArrayOfInt]) = null
) as begin

set nocount on

declare @targetCitiesKeysTable table (targetCityKey int)
insert into @targetCitiesKeysTable(targetCityKey)
select tbl.res.value('.', 'int') from @targetCitiesKeys.nodes('/ArrayOfInt/int') as tbl(res)

declare @longsTable table (long int)
insert into @longsTable(long)
select tbl.res.value('.', 'int') from @longs.nodes('/ArrayOfInt/int') as tbl(res)

declare @toursTable table (toKey int)
if (@flightCityKey != -1) begin
	insert into @toursTable (toKey)
	select distinct TO_Key
	from TP_Tours with(nolock)
	join TurService with(nolock) on TS_TRKey = TO_TRKey and TS_SVKey = 1 and TS_CTKey = @flightCityKey and TS_SubCode2 = @departureCityKey and TS_Day = 1
end
else if (@flightCityKey = -1) begin
	insert into @toursTable (toKey)
	select distinct TO_Key
	from TP_Tours with(nolock)
	left join TurService with(nolock) on TS_TRKey = TO_TRKey and TS_SVKey = 1 and TS_Key is null
end

declare @nowDate datetime
set @nowDate = CONVERT(datetime, dateadd(day, -1, GETDATE()))

select distinct TD_Date
from TP_Lists        with(nolock)
join TP_TurDates     with(nolock) on TD_TOKey = TI_TOKey
join HotelDictionary with(nolock) on HD_Key = TI_FirstHDKey
where
    (TD_Date > @nowDate) and
	(TI_TOKey in (select toKey from @toursTable)) and
	(HD_CTKey in (select targetCityKey from @targetCitiesKeysTable)) and
	(@longs is null or TI_Days in (select long from @longsTable))


end
go

grant exec on [dbo].[MarginMonitor_GetTourDates] to public
go

/*********************************************************************/
/* end sp_MarginMonitor_GetTourDates.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_MarginMonitor_PriceFilter.sql */
/*********************************************************************/
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MarginMonitor_PriceFilter]') AND TYPE IN (N'P', N'PC'))
	DROP PROCEDURE [dbo].[MarginMonitor_PriceFilter]
GO

--реализация основных фильтров Маржинального монитора
--<version>2009.15.1</version>
--<data>2013-03-06</data>
CREATE PROCEDURE [dbo].[MarginMonitor_PriceFilter]
(
	@tourDates                    XML ([dbo].[ArrayOfDateTime]),      -- даты туров
	@hotelKeys                    XML ([dbo].[ArrayOfInt]),			  -- ключи отелей
	@roomCategoryKeys             XML ([dbo].[ArrayOfInt]) = NULL,	  -- ключи категорий комнат
	@pansionKeys                  XML ([dbo].[ArrayOfInt]) = NULL,	  -- ключи питаний
	@longList                     XML ([dbo].[ArrayOfInt]) = NULL,	  -- продолжительности
	@countryKey                   INT,                                -- страна
	@departCityKey                INT = NULL,                         -- город вылета
	@targetFlyCityKey             INT,                                -- город прилета
	@targetCitiesKeys             XML ([dbo].[ArrayOfInt]),           -- список городов проживания
	@priceMin                     MONEY = NULL,                       -- минимальная стоимость тура
	@priceMax                     MONEY = NULL,                       -- максимальная стоимость тура
	@isDeletedPriceOnly           BIT   = NULL,                       -- только снятые цены
	@isMinPrice                   BIT   = NULL,                       -- по минимальным ценам
	@isOnlineOnly                 BIT   = NULL,                       -- только выставленные в интернет туры
	@isModifyPriceOnly            BIT   = NULL,                       -- только измененные цены
	@isAllotment                  BIT   = NULL,                       -- для отелей по квотам элотмент
	@isCommitment                 BIT   = NULL,                       -- для отелей по квотам коммитмент
	@accmdDefaultKey              INT   = NULL,                       -- тип размещения по умолчанию
	@roomTypeDefaultKey           INT   = NULL,                       -- тип комнаты по умолчанию
	@isOnlyActualTourDates        BIT   = 1,                          -- 1-отбор по датам не ниже текущей    0-отбор по всем переданным датам
	@isAccommodationWithAdult     BIT   = 1,                          -- только размещения без доп. мест
	@isWholeHotel                 BIT   = 1,                          -- 1 - поиск по всему отелю, 0 - по категориям номеров
	@priceKeys                    XML ([dbo].[ArrayOfLong]) = NULL	  -- ключи уже отобранных цен (для работы кнопки "Применить фильтр к отобранным турам")
) AS BEGIN

SET ARITHABORT ON;
SET DATEFIRST 1;
SET NOCOUNT ON;

DECLARE @beginTime DATETIME, @debug varchar(255)

DECLARE @tourDatesTable TABLE (tourDate DATETIME)
INSERT INTO @tourDatesTable(tourDate)
SELECT tbl.res.value('.', 'datetime')
FROM @tourDates.nodes('/ArrayOfDateTime/dateTime') AS tbl(res)

IF @isOnlyActualTourDates = 1
BEGIN
	DELETE @tourDatesTable
	WHERE tourDate < CONVERT(datetime, dateadd(day, -1, GETDATE()))
END


DECLARE @targetCitiesKeysTable TABLE (cityKey INT)
INSERT INTO @targetCitiesKeysTable(cityKey)
SELECT tbl.res.value('.', 'int')
FROM @targetCitiesKeys.nodes('/ArrayOfInt/int') AS tbl(res)


DECLARE @hotelKeysTable TABLE (hotelKey INT)
INSERT INTO @hotelKeysTable(hotelKey)
SELECT tbl.res.value('.', 'int')
FROM @hotelKeys.nodes('/ArrayOfInt/int') AS tbl(res)


DECLARE @roomCategoryKeysTable TABLE (rcKey INT)
INSERT INTO @roomCategoryKeysTable(rcKey)
SELECT tbl.res.value('.', 'int')
FROM @roomCategoryKeys.nodes('/ArrayOfInt/int') AS tbl(res)


DECLARE @pansionKeysTable TABLE (pansionKey INT)
INSERT INTO @pansionKeysTable(pansionKey)
SELECT tbl.res.value('.', 'int')
FROM @pansionKeys.nodes('/ArrayOfInt/int') AS tbl(res)


DECLARE @longListTable TABLE (longValue SMALLINT)
INSERT INTO @longListTable(longValue)
SELECT tbl.res.value('.', 'int')
FROM @longList.nodes('/ArrayOfInt/int') AS tbl(res)


DECLARE @priceKeysTable TABLE (priceKey BIGINT)
INSERT INTO @priceKeysTable(priceKey)
SELECT tbl.res.value('.', 'bigint')
FROM @priceKeys.nodes('/ArrayOfLong/long') AS tbl(res)


SET @beginTime = GETDATE()

DECLARE @tmpPriceTable TABLE
(
	xTP_Key INT,
	xTP_TOKey INT,
	xTP_DateBegin DATETIME,
	xTI_Days INT,
	xTP_Gross MONEY,
	xTP_TIKey INT,
	xCH_Key INT,
	xCH_PKKey INT,
	xCH_SubCode1 INT,
	xAS_Group VARCHAR(1000),
	xCH_BackKey INT,
	xCH_BackSubCode1 INT,
	xAS_BackGroup VARCHAR(1000)
)

IF (ISNULL(@isDeletedPriceOnly, 0) = 0) BEGIN
	INSERT INTO @tmpPriceTable(xTP_Key, xTP_TOKey, xTP_DateBegin, xTI_Days, xTP_Gross, xTP_TIKey, xCH_Key, xCH_PKKey, xCH_SubCode1, xAS_Group)
	SELECT TP_Key, TP_TOKey, TP_DateBegin, TI_Days, TP_Gross, TP_TIKey, TS_Code, TS_OpPacketKey, TS_SubCode1, AS_Group
	FROM TP_Prices WITH(NOLOCK)
	JOIN TP_Lists WITH(NOLOCK) ON TP_TIKey = TI_Key
	JOIN TP_ServiceLists WITH(NOLOCK) ON TI_Key = TL_TIKey
	LEFT JOIN TP_Services WITH(NOLOCK) ON TL_TSKey = TS_Key AND TS_SVKey = 1 AND TS_Day = 1
	LEFT JOIN AirService  WITH(NOLOCK) ON AS_Key = TS_SubCode1
	WHERE
		(TP_DateBegin IN (SELECT tourDate FROM @tourDatesTable)) AND
		(TI_FirstHDKey IN (SELECT hotelKey FROM @hotelKeysTable)) AND
		(TI_FirstCTKey IN (SELECT cityKey FROM @targetCitiesKeysTable)) AND
		((@targetFlyCityKey != -1 AND TS_CTKey = @targetFlyCityKey AND TS_SubCode2 = @departCityKey)
		  OR
		 (@targetFlyCityKey = -1 AND TS_Key IS NULL)) AND
		(@longList IS NULL OR TI_DAYS IN (SELECT longValue FROM @longListTable))
END


IF ISNULL(@isOnlineOnly,0) = 0 BEGIN
	INSERT INTO @tmpPriceTable(xTP_Key, xTP_TOKey, xTP_DateBegin, xTI_Days, xTP_Gross, xTP_TIKey, xCH_Key, xCH_PKKey, xCH_SubCode1, xAS_Group)
	SELECT TPD_TPKey, TPD_TOKey, TPD_DateBegin, TI_DAYS, null, TPD_TIKey, TS_Code, TS_OpPacketKey, TS_SubCode1, AS_Group
	FROM TP_PricesDeleted WITH(NOLOCK)
	JOIN TP_Lists WITH(NOLOCK) ON TPD_TIKey = TI_Key
	JOIN TP_ServiceLists WITH(NOLOCK) ON TI_Key = TL_TIKey
	LEFT JOIN TP_Services WITH(NOLOCK) ON TL_TSKey = TS_Key AND TS_SVKey = 1 AND TS_Day = 1
	LEFT JOIN AirService  WITH(NOLOCK) ON AS_Key = TS_SubCode1
	WHERE
		(TPD_DateBegin IN (SELECT tourDate FROM @tourDatesTable)) AND
		(TI_FirstHDKey IN (SELECT hotelKey FROM @hotelKeysTable)) AND
		(TI_FirstCTKey IN (SELECT cityKey FROM @targetCitiesKeysTable)) AND
		((@targetFlyCityKey != -1 AND TS_CTKey = @targetFlyCityKey AND TS_SubCode2 = @departCityKey)
		  OR
		 (@targetFlyCityKey = -1 AND TS_Key IS NULL)) AND
		(@longList IS NULL OR TI_DAYS IN (SELECT longValue FROM @longListTable))
END

PRINT 'предварительный отбор цен: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))

SET @beginTime = GETDATE()

IF (@targetFlyCityKey != -1) BEGIN
	UPDATE pt
	SET pt.xCH_BackKey = TS_Code,
		pt.xCH_BackSubCode1 = TS_SubCode1,
		pt.xAS_BackGroup = AS_Group
	FROM @tmpPriceTable pt
	JOIN TP_ServiceLists WITH(NOLOCK) ON pt.xTP_TIKey = TL_TIKey
	JOIN TP_Services WITH(NOLOCK) ON (TL_TSKey = TS_Key) AND (TS_SVKey = 1) AND (TS_CTKey = @departCityKey) AND (TS_SubCode2 = @targetFlyCityKey)
	JOIN AirService WITH(NOLOCK) ON AS_Key = TS_SubCode1
END

PRINT 'ищим обратные перелеты: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))

SET @beginTime = GETDATE()

-- дополнительные перелеты
DECLARE @chartersTable TABLE
(
	xCH_CityKeyFrom INT,
	xCH_CityKeyTo INT,
	xAddChKey BIGINT,
	xCharterDate DATETIME,
	xTS_SubCode1 BIGINT,
	xAS_Group VARCHAR(1000),
	xTS_PKKey BIGINT,
	xAddFlight VARCHAR(4),
	xAddAirlineCode VARCHAR(3),
	xAS_Week VARCHAR(7),
	xAS_TimeFrom DATETIME,
	xOrder INT,
	xBusyPlaces INT,
	xTotalPlaces INT
)

INSERT INTO @chartersTable(xCH_CityKeyFrom, xCH_CityKeyTo, xAddChKey, xCharterDate, xTS_SubCode1, xAS_Group, xTS_PKKey, xAddFlight, xAddAirlineCode, xAS_Week, xAS_TimeFrom, xOrder)
SELECT DISTINCT CH_CityKeyFrom, CH_CityKeyTo, CH_Key, pt.xTP_DateBegin, CS_SUBCODE1, AS_GROUP, pt.xCH_PKKey, CH_FLIGHT, CH_AIRLINECODE, AS_WEEK, AS_TimeFrom,
	CASE pt.xCH_Key WHEN CH_Key THEN 0 ELSE 1 END
FROM AirSeason WITH(NOLOCK), Charter WITH(NOLOCK), Costs WITH(NOLOCK), @tmpPriceTable pt
JOIN AirService WITH(NOLOCK) ON AS_KEY = pt.xCH_SubCode1
WHERE
    CH_CityKeyFrom = @departCityKey AND
    CH_CityKeyTo = @targetFlyCityKey AND
	CS_Code = CH_Key AND
	AS_CHKey = CH_Key AND
	CS_SVKey = 1 AND
	(AS_GROUP = ISNULL((SELECT TOP 1 a.AS_GROUP FROM AIRSERVICE a WITH(NOLOCK) WHERE a.AS_KEY = CS_SUBCODE1), '')) AND
	CS_PKKey = pt.xCH_PKKey AND
	pt.xTP_DateBegin BETWEEN AS_DateFrom AND AS_DateTo AND
	pt.xTP_DateBegin BETWEEN CS_Date AND CS_DateEnd AND
	AS_Week LIKE '%'+CAST(DATEPART(WEEKDAY, pt.xTP_DateBegin)AS VARCHAR(1))+'%' AND
	(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+CAST(DATEPART(WEEKDAY, pt.xTP_DateBegin) AS VARCHAR(1))+'%')
UNION
SELECT DISTINCT CH_CityKeyFrom, CH_CityKeyTo, CH_Key, pt.xTP_DateBegin + pt.xTI_Days - 1, CS_SUBCODE1, AS_GROUP, pt.xCH_PKKey, CH_FLIGHT, CH_AIRLINECODE, AS_WEEK, AS_TimeFrom,
	CASE pt.xCH_Key WHEN CH_Key THEN 0 ELSE 1 END
FROM AirSeason WITH(NOLOCK), Charter WITH(NOLOCK), Costs WITH(NOLOCK), @tmpPriceTable pt
JOIN AirService WITH(NOLOCK) ON AS_KEY = pt.xCH_BackSubCode1
WHERE
    CH_CityKeyFrom = @targetFlyCityKey AND
    CH_CityKeyTo = @departCityKey AND
	CS_Code = CH_Key AND
	AS_CHKey = CH_Key AND
	CS_SVKey = 1 AND
	(AS_GROUP = ISNULL((SELECT TOP 1 a.AS_GROUP FROM AIRSERVICE a WITH(NOLOCK) WHERE a.AS_KEY = CS_SUBCODE1), '')) AND
	CS_PKKey = pt.xCH_PKKey AND
	(pt.xTP_DateBegin + pt.xTI_Days - 1) BETWEEN AS_DateFrom AND AS_DateTo AND
	(pt.xTP_DateBegin + pt.xTI_Days - 1) BETWEEN CS_Date AND CS_DateEnd AND
	AS_Week LIKE '%'+CAST(DATEPART(WEEKDAY, (pt.xTP_DateBegin + pt.xTI_Days - 1))AS VARCHAR(1))+'%' AND
	(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+CAST(DATEPART(WEEKDAY, (pt.xTP_DateBegin + pt.xTI_Days - 1)) AS VARCHAR(1))+'%')

DECLARE @chartersGroupTable TABLE
(
	xCH_CityKeyFrom INT,
	xCH_CityKeyTo INT,
	xCharterDate DATETIME,
	xAS_Group VARCHAR(1000),
	xTS_PKKey BIGINT,
	xAddChKeyString VARCHAR(5000),
	xAS_Week VARCHAR(7),
	xAS_TimeFrom VARCHAR(5000)
)

-- все доп. перелеты соединяем через запятую в одну строку
insert into @chartersGroupTable(xCH_CityKeyFrom, xCH_CityKeyTo, xCharterDate, xAS_Group, xTS_PKKey, xAddChKeyString, xAS_Week, xAS_TimeFrom)
select distinct xCH_CityKeyFrom, xCH_CityKeyTo, xCharterDate, xAS_Group, xTS_PKKey,
	-- xAddAirlineCode + xAddFlight
	(select t2.xAddAirlineCode + t2.xAddFlight + ', '
	from @chartersTable t2
	where (t2.xCH_CityKeyFrom = ct.xCH_CityKeyFrom) and (t2.xCH_CityKeyTo = ct.xCH_CityKeyTo) and
	      (t2.xCharterDate = ct.xCharterDate) and (t2.xAS_Group = ct.xAS_Group) and (t2.xTS_PKKey = ct.xTS_PKKey)
	order by t2.xOrder asc, t2.xAddAirlineCode + t2.xAddFlight asc
	for xml path('')),
	-- xAS_Week
	(select top 1 t2.xAS_Week
	from @chartersTable t2
	where (t2.xCH_CityKeyFrom = ct.xCH_CityKeyFrom) and (t2.xCH_CityKeyTo = ct.xCH_CityKeyTo) and
	      (t2.xCharterDate = ct.xCharterDate) and (t2.xAS_Group = ct.xAS_Group) and (t2.xTS_PKKey = ct.xTS_PKKey)
	order by len(t2.xAS_Week) - len(replace(t2.xAS_Week, '.', '')) asc),
	-- xAS_TimeFrom
	(select SUBSTRING(CONVERT(VARCHAR(8), t2.xAS_TimeFrom, 108),0,6) + ', '
	from @chartersTable t2
	where (t2.xCH_CityKeyFrom = ct.xCH_CityKeyFrom) and (t2.xCH_CityKeyTo = ct.xCH_CityKeyTo) and
	      (t2.xCharterDate = ct.xCharterDate) and (t2.xAS_Group = ct.xAS_Group) and (t2.xTS_PKKey = ct.xTS_PKKey)
	order by t2.xOrder asc, t2.xAddAirlineCode + t2.xAddFlight asc
	for xml path(''))
from @chartersTable ct

-- избавляемся от хвостовых запятых
update @chartersGroupTable
set xAddChKeyString = LEFT(xAddChKeyString, LEN(xAddChKeyString) - 1),
    xAS_TimeFrom = LEFT(xAS_TimeFrom, LEN(xAS_TimeFrom) - 1)

PRINT 'подбираем подходящие перелеты: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))

SET @beginTime = GETDATE()

-- считаем места на рейсах
UPDATE ct
SET xTotalPlaces = ISNULL(xTotalPlaces,0) + ISNULL(QP_Places,0),
    xBusyPlaces  = ISNULL(xBusyPlaces,0) + ISNULL(QP_Busy,0)
FROM @chartersTable ct
JOIN QuotaObjects WITH(NOLOCK) ON QO_Code = xAddChKey
JOIN QuotaDetails WITH(NOLOCK) ON QD_QTID = QO_QTID
JOIN QuotaParts   WITH(NOLOCK) ON QP_QDID = QD_ID
WHERE
	(QO_SVKey = 1) AND
	(QO_SubCode1 = xTS_SubCode1) AND
	(QD_Date = xCharterDate) AND
	(ISNULL(QP_IsDeleted,0) = 0) AND
	(ISNULL(QP_AgentKey,0) = 0)


PRINT 'считаем места на рейсах: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
--set @debug = 'подбираем подходящие перелеты: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
--insert into Debug (db_Date, db_Mod, db_Text)
--values(GETDATE(), 'MM', substring(@debug, 0, 255))

--SELECT * from @tmpPriceTable
--SELECT * from @chartersTable
--SELECT * from @chartersGroupTable

DECLARE @prices TABLE
(
	TourOldPrice                MONEY,
	TR_Key                      INT,
	TP_Key                      INT,
	IsOnline                    BIT,
	TourName                    VARCHAR(1000),
	TourDate                    DATETIME,
	TourDays                    SMALLINT,
	HotelDays                   SMALLINT,
	AccommodationKey            INT,
	AccommodationName           VARCHAR(1000),
	RoomKey                     INT,
	HotelCityName               VARCHAR(1000),
	HotelKey                    INT,
	HotelName                   VARCHAR(1000),
	HotelRoomKey                INT,
	RoomName                    VARCHAR(1000),
	RoomCategoryKey             INT,
	RoomCategoryName            VARCHAR(1000),
	PansionKey                  INT,
	PansionName                 VARCHAR(1000),
	PansionCode                 VARCHAR(20),
	PartnerKey                  INT,
	Mens                        SMALLINT,
	Airport                     VARCHAR(20),
	Charters                    VARCHAR(2000),
	FlightDays                  VARCHAR(7),
	FlightTime                  VARCHAR(1000),
	CharterBusyPlaces           INT,
	CharterTotalPlaces          INT,
	CharterUnsolidBackPlaces    INT,
	AllotmentDaysCount          INT,
	CommitmentDaysCount         INT,
	HotelAllPlaces              INT,
	HotelBusyPlaces             INT,
	HotelCommitmentPlaces       INT,
	HotelLoadFactor             FLOAT,
	StopSale                    BIT
)

SET @beginTime = GETDATE()

INSERT INTO @prices
(
	TourOldPrice,
	TR_Key,
	TP_Key,
	IsOnline,
	TourName,
	TourDate,
	TourDays,
	HotelDays,
	AccommodationKey,
	AccommodationName,
	RoomKey,
	HotelCityName,
	HotelKey,
	HotelName,
	HotelRoomKey,
	RoomName,
	RoomCategoryKey,
	RoomCategoryName,
	PansionKey,
	PansionName,
	PansionCode,
	PartnerKey,
	Mens,
	Airport,
	Charters,
	FlightDays,
	FlightTime,
	CharterBusyPlaces,
	CharterTotalPlaces,
	CharterUnsolidBackPlaces,
	AllotmentDaysCount,
	CommitmentDaysCount,
	HotelAllPlaces,
	HotelBusyPlaces,
	HotelCommitmentPlaces,
	HotelLoadFactor,
	StopSale
)
SELECT DISTINCT
	pr.xTP_Gross AS TourOldPrice,
	TO_TRKey AS TR_Key,
	pr.xTP_Key AS TP_Key,
	TO_IsEnabled AS IsOnline,
	TO_Name AS TourName,
	pr.xTP_DateBegin AS TourDate,
	lst.TI_DAYS AS TourDays,
	hs.TS_Days AS HotelDays,
	hr.HR_ACKEY AS AccommodationKey,
	ac.AC_CODE AS AccommodationName,
	hr.HR_RMKEY AS RoomKey,
	ct.CT_NAME AS HotelCityName,
	lst.TI_FirstHDKey AS HotelKey,
	hd.HD_NAME AS HotelName,
	hs.TS_SubCode1 AS HotelRoomKey,
	rm.RM_NAME AS RoomName,
	hr.HR_RCKEY AS RoomCategoryKey,
	rc.RC_Name AS RoomCategoryName,
	lst.TI_FirstPNKey AS PansionKey,
	pn.PN_Name AS PansionName,
	pn.PN_Code AS PansionCode,
	hs.TS_OpPartnerKey AS PartnerKey,
	hs.TS_Men AS Mens,
	-- CharterPortCodeFrom
	(SELECT TOP 1 CH_PortCodeFrom FROM Charter WHERE CH_Key = pr.xCH_Key)
	AS Airport,
	-- Charters
	(SELECT TOP 1 xAddChKeyString FROM @chartersGroupTable act
	 WHERE (act.xCharterDate = pr.xTP_DateBegin) and (act.xCH_CityKeyFrom = @departCityKey) and (act.xCH_CityKeyTo = @targetFlyCityKey) and
	       (act.xTS_PKKey = pr.xCH_PKKey) and (act.xAS_Group = pr.xAS_Group))
	AS Charters,
	-- FlightDays
	(SELECT TOP 1 xAS_Week FROM @chartersGroupTable act
	 WHERE (act.xCharterDate = pr.xTP_DateBegin) and (act.xCH_CityKeyFrom = @departCityKey) and (act.xCH_CityKeyTo = @targetFlyCityKey) and
	       (act.xTS_PKKey = pr.xCH_PKKey) and (act.xAS_Group = pr.xAS_Group))
	AS FlightDays,
	-- FlightTime
	(SELECT TOP 1 xAS_TimeFrom FROM @chartersGroupTable act
	 WHERE (act.xCharterDate = pr.xTP_DateBegin) and (act.xCH_CityKeyFrom = @departCityKey) and (act.xCH_CityKeyTo = @targetFlyCityKey) and
	       (act.xTS_PKKey = pr.xCH_PKKey) and (act.xAS_Group = pr.xAS_Group))
	AS FlightTime,
	-- CharterBusyPlaces
	(SELECT SUM(ct.xBusyPlaces) FROM @chartersTable ct
 	 WHERE (ct.xCharterDate = pr.xTP_DateBegin) and (ct.xCH_CityKeyFrom = @departCityKey) and (ct.xCH_CityKeyTo = @targetFlyCityKey) and
	       (ct.xTS_PKKey = pr.xCH_PKKey) and (ct.xAS_Group = pr.xAS_Group))
	AS CharterBusyPlaces,
	-- CharterTotalPlaces
	(SELECT SUM(ct.xTotalPlaces) FROM @chartersTable ct
	 WHERE (ct.xCharterDate = pr.xTP_DateBegin) and (ct.xCH_CityKeyFrom = @departCityKey) and (ct.xCH_CityKeyTo = @targetFlyCityKey) and
	       (ct.xTS_PKKey = pr.xCH_PKKey) and (ct.xAS_Group = pr.xAS_Group))
	AS CharterTotalPlaces,
	-- CharterUnsolidBackPlaces
	(SELECT SUM(ct.xTotalPlaces - ct.xBusyPlaces) FROM @chartersTable ct
	 WHERE (ct.xCharterDate = pr.xTP_DateBegin + lst.TI_DAYS - 1) and (ct.xCH_CityKeyFrom = @targetFlyCityKey) and (ct.xCH_CityKeyTo = @departCityKey) and
	       (ct.xTS_PKKey = pr.xCH_PKKey) and (ct.xAS_Group = pr.xAS_BackGroup))
	AS CharterUnsolidBackPlaces,
	-- AllotmentDaysCount
	CASE @isAllotment WHEN 1 THEN
		dbo.GetHotelDays(DATEADD(DAY, hs.TS_Day - 1, pr.xTP_DateBegin), hs.TS_Days, lst.TI_FirstHDKey, 1)
	ELSE NULL END
	AS AllotmentDaysCount,
	-- CommitmentDaysCount
	CASE @isCommitment WHEN 1 THEN
		dbo.GetHotelDays(DATEADD(DAY, hs.TS_Day - 1, pr.xTP_DateBegin), hs.TS_Days, lst.TI_FirstHDKey, 2)
	ELSE NULL END
	AS CommitmentDaysCount,
	-- HotelAllPlaces
	dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 1, pr.xTP_DateBegin, hs.TS_Code, NULL, lst.TI_Days, hr.HR_RCKEY)
	AS HotelAllPlaces,
	-- HotelBusyPlaces
	dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 0, pr.xTP_DateBegin, hs.TS_Code, NULL, lst.TI_Days, hr.HR_RCKEY)
	AS HotelBusyPlaces,
	-- HotelCommitmentPlaces
	dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 1, pr.xTP_DateBegin, hs.TS_Code, 2, lst.TI_Days, hr.HR_RCKEY)
	AS HotelCommitmentPlaces,
	-- HotelLoadFactor
	dbo.GetHotelLoad (ISNULL(@IsWholeHotel,0), pr.xTP_DateBegin, hs.TS_Code, hr.HR_RCKEY)
	AS HotelLoadFactor,
	-- Stop sale
	(SELECT TOP 1 1 FROM StopSales WITH(NOLOCK)
     INNER JOIN QuotaObjects WITH(NOLOCK) ON QO_ID = SS_QOID
     WHERE
        ISNULL(SS_IsDeleted, 0) = 0
        AND SS_Date BETWEEN (pr.xTP_DateBegin + hs.TS_Day - 1) AND (pr.xTP_DateBegin + hs.TS_Day - 1 + hs.TS_Days - 1)
	    AND QO_SVKey = 3
		AND QO_Code = lst.TI_FirstHDKey
		AND (QO_SubCode1 = HR_RMKEY OR QO_SubCode1 = 0)
		AND (QO_SubCode2 = HR_RCKEY OR QO_SubCode2 = 0))
	AS StopSale
FROM @tmpPriceTable       pr
JOIN TP_Tours             tour    WITH(NOLOCK) ON tour.TO_Key = pr.xTP_TOKey
JOIN TP_Lists             lst     WITH(NOLOCK) ON pr.xTP_TIKey = lst.TI_Key
JOIN HotelRooms           hr      WITH(NOLOCK) ON lst.TI_FirstHRKey = hr.HR_Key
JOIN Rooms                rm      WITH(NOLOCK) ON rm.RM_KEY = hr.HR_RMKey
JOIN RoomsCategory        rc      WITH(NOLOCK) ON hr.HR_RCKEY = rc.RC_Key
JOIN HotelDictionary      hd      WITH(NOLOCK) ON lst.TI_FirstHDKey = hd.HD_Key
JOIN TP_ServiceLists      slhs    WITH(NOLOCK) ON lst.TI_Key = slhs.TL_TIKey
JOIN TP_Services          hs      WITH(NOLOCK) ON slhs.TL_TSKey = hs.TS_Key AND hs.TS_SVKey = 3 AND hs.TS_Code = lst.TI_FirstHDKey
JOIN Pansion              pn      WITH(NOLOCK) ON lst.TI_FirstPNKey = pn.PN_Key
JOIN CityDictionary       ct      WITH(NOLOCK) ON hd.HD_CTKEY = ct.CT_KEY
JOIN Accmdmentype         ac      WITH(NOLOCK) ON hr.HR_ACKEY = ac.AC_KEY
WHERE
	(ISNULL(@isAccommodationWithAdult, 0) = 0 OR (HR_ACKEY IN (SELECT AC_KEY FROM Accmdmentype WHERE (ISNULL(AC_NADMAIN, 0) > 0) AND (ISNULL(AC_NCHMAIN, 0) = 0) AND (ISNULL(AC_NCHISINFMAIN, 0) = 0)))) AND
	-- фильтр по мин. ценам НЕ задан
	((ISNULL(@isMinPrice, 0) = 0 AND
	-- проверяем тур на те категории номеров и питаний, которые были переданы
	hr.HR_RCKEY IN (SELECT rcKey FROM @roomCategoryKeysTable) AND
	lst.TI_FirstPNKey IN (SELECT pansionKey FROM @pansionKeysTable))
	OR
	-- фильтр по мин. ценам задан
	(ISNULL(@isMinPrice, 0) != 0 AND
	-- проверяем по базовым привязкам отеля
	hr.HR_RCKEY = (SELECT TOP 1 ahc.AH_RcKey FROM AssociationHotelCat ahc WHERE ahc.AH_HdKey = lst.TI_FirstHDKey) AND
	lst.TI_FirstPNKey = (SELECT TOP 1 ahc.ah_pnkey FROM AssociationHotelCat ahc WHERE ahc.AH_HdKey = lst.TI_FirstHDKey) AND
	-- если заданы обе настройки с типом размещения и типом комнаты, то отсеиваем по ним
	(ISNULL(@accmdDefaultKey, 0) = 0 OR ISNULL(@roomTypeDefaultKey, 0) = 0 OR
	((hr.HR_ACKEY = @accmdDefaultKey) AND (hr.HR_RMKEY = @roomTypeDefaultKey))))
	) AND
	-- только выставленные в интернет туры
	(@isOnlineOnly IS NULL OR (@isOnlineOnly = CASE WHEN pr.xTP_Gross IS NULL THEN 0 ELSE TO_IsEnabled END)) AND
	-- отсев по ценам за тур
	(ISNULL(@priceMin, 0) = 0 OR (pr.xTP_Gross >= @priceMin)) AND
	(ISNULL(@priceMax, 0) = 0 OR (pr.xTP_Gross <= @priceMax))


-- удаляем цены у которых цисло мест на рейсе 0
-- это означает, что на эти даты были сняты рейсы
DELETE FROM @prices WHERE CharterTotalPlaces = 0

-- только измененные цены
IF ISNULL(@isModifyPriceOnly, 0) != 0 BEGIN
	-- удаляем из @prices все неизмененные цены
	DELETE FROM @prices
	WHERE TP_Key IN (
		SELECT p.TP_Key FROM @prices p
		JOIN TP_PriceComponents pc ON p.TP_Key = pc.PC_TPKey
		WHERE NOT EXISTS(
		             SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_1  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_2  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_3  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_4  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_5  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_6  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_7  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_8  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_9  IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_10 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_11 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_12 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_13 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_14 IS NOT NULL) AND (spad.SPAD_NeedApply != 0)
			   UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_15 IS NOT NULL) AND (spad.SPAD_NeedApply != 0))
	)
END

	       
PRINT 'выбор туров: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
--set @debug = 'выбор туров: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
--insert into Debug (db_Date, db_Mod, db_Text)
--values(GETDATE(), 'MM', substring(@debug, 0, 255))

SET @beginTime = GETDATE()
-- актуализируем цены по отобранным турам
declare @tpKeys nvarchar(max)
set @tpKeys = ''
select @tpKeys = @tpKeys + convert(nvarchar(max), p.TP_Key) + ', '
from @prices p
print 'exec ReCalculate_CheckActualPrice ' + '''' +  @tpKeys + ''''
-- делаем инсерт во веременную таблицу, что бы результата не выводился при запуске этой хранимки
declare @tmp table(tpKey bigint, newPrice money)
insert into @tmp (tpKey, newPrice)
exec ReCalculate_CheckActualPrice @tpKeys
print 'Расчитываем изменения в ценах: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
--set @debug = 'Расчитываем изменения в ценах: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
--insert into Debug (db_Date, db_Mod, db_Text)
--values(GETDATE(), 'MM', substring(@debug, 0, 255))

SELECT p.*,
	pc.PC_Id AS PC_Id,
    pc.PC_Rate AS Rate,
	AddCostIsCommission_1,  AddCostNoCommission_1,  CommissionOnly_1,  Gross_1,  IsCommission_1,  MarginPercent_1,  SCPId_1,  SVKey_1,
	AddCostIsCommission_2,  AddCostNoCommission_2,  CommissionOnly_2,  Gross_2,  IsCommission_2,  MarginPercent_2,  SCPId_2,  SVKey_2,
	AddCostIsCommission_3,  AddCostNoCommission_3,  CommissionOnly_3,  Gross_3,  IsCommission_3,  MarginPercent_3,  SCPId_3,  SVKey_3,
	AddCostIsCommission_4,  AddCostNoCommission_4,  CommissionOnly_4,  Gross_4,  IsCommission_4,  MarginPercent_4,  SCPId_4,  SVKey_4,
	AddCostIsCommission_5,  AddCostNoCommission_5,  CommissionOnly_5,  Gross_5,  IsCommission_5,  MarginPercent_5,  SCPId_5,  SVKey_5,
	AddCostIsCommission_6,  AddCostNoCommission_6,  CommissionOnly_6,  Gross_6,  IsCommission_6,  MarginPercent_6,  SCPId_6,  SVKey_6,
	AddCostIsCommission_7,  AddCostNoCommission_7,  CommissionOnly_7,  Gross_7,  IsCommission_7,  MarginPercent_7,  SCPId_7,  SVKey_7,
	AddCostIsCommission_8,  AddCostNoCommission_8,  CommissionOnly_8,  Gross_8,  IsCommission_8,  MarginPercent_8,  SCPId_8,  SVKey_8,
	AddCostIsCommission_9,  AddCostNoCommission_9,  CommissionOnly_9,  Gross_9,  IsCommission_9,  MarginPercent_9,  SCPId_9,  SVKey_9,
	AddCostIsCommission_10, AddCostNoCommission_10, CommissionOnly_10, Gross_10, IsCommission_10, MarginPercent_10, SCPId_10, SVKey_10,
	AddCostIsCommission_11, AddCostNoCommission_11, CommissionOnly_11, Gross_11, IsCommission_11, MarginPercent_11, SCPId_11, SVKey_11,
	AddCostIsCommission_12, AddCostNoCommission_12, CommissionOnly_12, Gross_12, IsCommission_12, MarginPercent_12, SCPId_12, SVKey_12,
	AddCostIsCommission_13, AddCostNoCommission_13, CommissionOnly_13, Gross_13, IsCommission_13, MarginPercent_13, SCPId_13, SVKey_13,
	AddCostIsCommission_14, AddCostNoCommission_14, CommissionOnly_14, Gross_14, IsCommission_14, MarginPercent_14, SCPId_14, SVKey_14,
	AddCostIsCommission_15, AddCostNoCommission_15, CommissionOnly_15, Gross_15, IsCommission_15, MarginPercent_15, SCPId_15, SVKey_15
	FROM @prices p
	JOIN TP_PriceComponents pc WITH(NOLOCK) ON pc.PC_TPKey = p.TP_Key
	WHERE (@priceKeys IS NULL OR pc.PC_Id IN (SELECT priceKey FROM @priceKeysTable))
END
GO

GRANT EXEC ON [dbo].[MarginMonitor_PriceFilter] TO PUBLIC
GO

/*********************************************************************/
/* end sp_MarginMonitor_PriceFilter.sql */
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
	@requestedPlaces int = 1
as
begin

	--<VERSION>9.2</VERSION>
	--<DATE>2012-11-15</DATE>

	declare @StopSale int, @Release int, @Duration int, @NoPlaces int, @NoQuota int, @QuotaExist int
	set @StopSale = 0
	set @Release = 1
	set @Duration = 2
	set @NoPlaces = 3
	set @NoQuota = 4
	set @QuotaExist = 5

	-- настройки проверки квот через веб-сервис
	declare @checkQuotesOnWebService as bit, @checkQuotesService as nvarchar(150), @wasErrorCallingService bit
	set @checkQuotesOnWebService = 0
	set @wasErrorCallingService = 0
	select top 1 @checkQuotesOnWebService = ss_parmvalue from systemsettings with (nolock) where ss_parmname = 'NewSetToQuota'

	select top 1 @checkQuotesService = ss_parmvalue from systemsettings with (nolock) where ss_parmname = 'CheckQuotesWebService'

	if len(ltrim(rtrim(@checkQuotesService))) = 0 and @checkQuotesOnWebService = 1
		RAISERROR('mwCheckQuotesCycle: check quotes via webservice is enabled, but CheckQuotesWebService setting is not set in SystemSettings', 15, 1)

	declare @DYNAMIC_SPO_PAGING smallint
	set @DYNAMIC_SPO_PAGING=3

	declare @now datetime, @percentPlaces float
	select @now = currentDate from dbo.mwCurrentDate

	if(@aviaQuotaMask is null)
		set @aviaQuotaMask = 0

	declare @correctionResult varchar(128)
	set @result = ''
	set @correctionResult = ''

	declare @gpos int, @pos int, @gplaces int, @gallplaces int, @tmpPlaces int, @checkQuotesResult int, @tmpPlacesAll int, @gStep smallint, @gCorrection int
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
					where @findFlight <> 0
						and CH_CITYKEYFROM = @cityFrom
						and CH_CITYKEYTO = @cityTo
						and (AS_WEEK is null 
								or len(as_week)=0 
								or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
						and @charterDate between as_dateFrom and as_dateto
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
						select @checkQuotesResult = result, @tmpPlaces = freePlaces, @tmpPlacesAll = allPlaces
						from [dbo].WcfQuotaCheckOneResult(1, 1, @altChKey, @nkey, @dateFrom, @dateTo,
							0, @agentKey, @tourDays, @requestedPlaces, null)
						
						set @wasErrorCallingService = 0						
					end try
					begin catch
						set @wasErrorCallingService = 1
						break
					end catch
								
					declare @freePlacesMask as int

					if @checkQuotesResult in (@StopSale, @NoPlaces)
						set @freePlacesMask = 2	-- no places
					else if @checkQuotesResult in (@Release, @Duration, @NoQuota)
					begin
						set @freePlacesMask = 4	-- request
						set @tmpPlaces = -1
					end
					else if @checkQuotesResult = @QuotaExist
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
					@tourDays, @expiredReleaseResult, @linked_day)
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
-- добавление настройки, по которой включается проверка квот через веб-сервис
if (not exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota'))
begin
	insert into SystemSettings (SS_ParmName, SS_ParmValue)
	values ('NewSetToQuota', 0)
end

if (not exists (select top 1 1 from SystemSettings where SS_ParmName = 'CheckQuotesWebService'))
begin
	insert into SystemSettings (SS_ParmName, SS_ParmValue)
	values ('CheckQuotesWebService', '')
end

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCheckQuotesCycle]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwCheckQuotesCycle]
GO

CREATE procedure [dbo].[mwCheckQuotesCycle]
--<VERSION>9.2.17</VERSION>
--<DATE>2012-11-28</DATE>
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
@tableName varchar(256) = null
as
begin
	-- настройки проверки квот через веб-сервис
	declare @checkQuotesOnWebService as bit, @checkQuotesService as nvarchar(150), @wasErrorCallingService bit
	set @checkQuotesOnWebService = 0
	set @wasErrorCallingService = 0
	select top 1 @checkQuotesOnWebService = ss_parmvalue from systemsettings with (nolock) where ss_parmname = 'NewSetToQuota'

	select top 1 @checkQuotesService = ss_parmvalue from systemsettings with (nolock) where ss_parmname = 'CheckQuotesWebService'

	if len(ltrim(rtrim(@checkQuotesService))) = 0 and @checkQuotesOnWebService = 1
		RAISERROR('mwCheckQuotesCycle: check quotes via webservice was enabled, but CheckQuotesWebService setting is not set in SystemSettings', 15, 1)

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
			@ptkey int,@pttourkey int, @ptpricekey bigint, @hdkey int,@rmkey int,@rckey int,@tourdate datetime,@chkey int,@chbackkey int,@hdday int,@hdnights int,@hdprkey int,	@chday int,@chpkkey int,@chprkey int,@chbackday int,
		@chbackpkkey int,@chbackprkey int,@days int, @rowNum int, @hdStep smallint, @reviewed int,@selected int, @hdPriceCorrection int, 
		@pt_directFlightAttribute int, @pt_backFlightAttribute int, @pt_mainplaces int, @pt_hrkey int, @sql varchar(max)

	declare @pt_chdirectkeys varchar(256), @pt_chbackkeys varchar(256)
	declare @tmpAllHotelQuota varchar(128),@pt_hddetails varchar(256)

	set @reviewed= @pageNum
	set @selected=0

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

	while(@@fetch_status=0 and @selected < @pageSize)
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
						@tmpThereAviaQuota OUTPUT, @places output, @step_index output, @price_correction output, @additional output, @findFlight

					if (@tmpThereAviaQuota is null)
					begin		
						
						set @tmpThereAviaQuota = ''

						exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, 
							@requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey,
							@days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @chbackday, @pt_mainplaces

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

							EXEC [dbo].[mwCacheQuotaInsert] 1,@chkey,0,0,@tourdate,@chday,@days,@chprkey,@chpkkey,@tmpThereAviaQuota, @places, 0, 0, @additional, @findFlight
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
							@tmpBackAviaQuota OUTPUT, @places output, @step_index output, @price_correction output, @additional output, @findFlight
							
						if (@tmpBackAviaQuota is null)
						begin

							set @tmpBackAviaQuota = ''												
							
							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chbackkey, @flightGroups, @agentKey, @chbackprkey, @tourdate,
								@chbackday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 
								@findFlight, @chbackpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output, @chday, @pt_mainplaces

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
														
								EXEC [dbo].[mwCacheQuotaInsert] 1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey,@tmpBackAviaQuota, @places, 0, 0, @additional, @findFlight
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
							@tmpHotelQuota OUTPUT, @places output, @hdStep output, @hdPriceCorrection output, @additional output, 0

						if (@tmpHotelQuota is null)
						begin
							if @checkQuotesOnWebService = 1
							begin
								declare @checkQuotesResult as int
								set @dateFrom = dateadd(day, @hdday - 1, @tourdate)
								set @dateTo = dateadd(day, @hdnights - 1, @dateFrom)
								
								-- включена проверка квот через веб-сервис								
								begin try
									select @checkQuotesResult = result, @places = freePlaces, @allPlaces = allPlaces
									from [dbo].WcfQuotaCheckOneResult(
											1, 3, @hdkey, @pt_hrkey, @dateFrom, @dateTo, @hdprkey, 
											@agentKey, @hdnights, 1, null)
								end try
								begin catch
									-- Ошибка при вызове веб-сервиса. Логируем, отправляем письмо и отключаем проверку через сервис
									set @wasErrorCallingService = 1
								end catch
										
								if @checkQuotesResult in (0, 3)
									set @freePlacesMask = 2	-- no places
								else if @checkQuotesResult in (1, 2, 4)
								begin
									set @freePlacesMask = 4	-- request
									set @places = -1
								end
								else if @checkQuotesResult = 5
									set @freePlacesMask = 1	-- yes
								
							end
							
							-- не сделано через else к условию if @checkQuotesOnWebService = 1, чтобы в случае
							-- ошибки работы с веб-сервисом проверки квот
							if @wasErrorCallingService = 1 or @checkQuotesOnWebService = 0
							begin
								select @places=qt_places,@allPlaces=qt_allPlaces,@additional=qt_additional 
								from dbo.mwCheckQuotesEx(3,@hdkey,@rmkey,@rckey, @agentKey, @hdprkey,@tourdate,@hdday,@hdnights, 
									@requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 0, 0, 0, 0, 0,
									@expiredReleaseResult)
									
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

							EXEC [dbo].[mwCacheQuotaInsert] 3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota,@places,@hdStep,@hdPriceCorrection, @additional, 0
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
								@curHotelQuota OUTPUT, @tempPlaces output, @hdStep output, @hdPriceCorrection output, @additional output, 0

							if (@curHotelQuota is null)
							begin								
								if @checkQuotesOnWebService = 1
								begin
									begin try
										set @dateFrom = dateadd(day, @curHotelDay - 1, @tourdate)
										set @dateTo = dateadd(day, @curHotelDays - 1, @dateFrom)
										-- включена проверка квот через веб-сервис
										select @checkQuotesResult = result, @tempPlaces = freePlaces, @tempAllPlaces = allPlaces
										from [dbo].WcfQuotaCheckOneResult(
												1, 3, @curHotelKey, @curHotelRoomKey, @dateFrom, @dateTo, @curHotelPartnerKey, 
												@agentKey, @curHotelDays, 1, null)
												
										-- отдельный случай для статуса "Запрос": сервис возвращает количество мест 0, а ожидается -1
										if @checkQuotesResult in (1, 2, 4)
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
									from dbo.mwCheckQuotesEx(3,@curHotelKey,@curRoomKey,@curRoomCategoryKey, @agentKey, @curHotelPartnerKey,@tourdate,@curHotelDay,@curHotelDays, 
											@requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 0, 0, 0, 0, 0, @expiredReleaseResult)
								end
								
								set @curHotelQuota=ltrim(str(@tempPlaces)) + ':' + ltrim(str(@tempAllPlaces))

								EXEC [dbo].[mwCacheQuotaInsert] 3,@curHotelKey,@curRoomKey,@curRoomCategoryKey,@tourdate,@curHotelDay,@curHotelDays,@curHotelPartnerKey,0,@curHotelQuota,@tempPlaces,0,0, @additional, 0
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
							@days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @pt_chbackkeys
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
	end

	if (@smartSearch=0)
	begin
		select @reviewed
	end
end
GO

grant execute on [dbo].[mwCheckQuotesCycle] to public
GO
/*********************************************************************/
/* end sp_mwCheckQuotesCycle.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCleaner.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCleaner]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[mwCleaner] 
GO

CREATE proc [dbo].[mwCleaner] @priceCount int = 10000, @deleteToday smallint = 0
as
begin
	--<DATE>2012-10-15</DATE>
	--<VERSION>9.2.16.3</VERSION>
	declare @counter bigint
	declare @deletedRowCount bigint

	insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Запуск mwCleaner', 1)

	truncate table CacheQuotas

	declare @today datetime
	set @today = CAST(CONVERT(varchar(20), GETDATE(), 112) as datetime)
	if (@deleteToday = 1)
	begin
		set @today = dateadd(day, 1, @today)
	end
	
	-- Удаляем записи из таблицы TP_ServiceTours, если таких туров больше нету
	-- Тут количество записей будет не большим, поэтому можно не делить на пачки, туры удаляются редко в ДЦ
	delete TP_ServiceTours
	where not exists (select top 1 1 from TP_Tours with(nolock) where TO_Key = ST_TOKey)
	
	-- Удаляем неактуальные цены
	set @counter = 0
	while(1 = 1)
	begin
		delete top (@priceCount * 100) from dbo.tp_prices with(rowlock) where tp_dateend < @today and tp_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
		set @deletedRowCount = @@ROWCOUNT
		if @deletedRowCount = 0
		begin
			insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_prices завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
			break
		end
		else
			set @counter = @counter + @deletedRowCount
	end

	-- Удаляем неактуальные удаленные цены из TP_PricesDeleted (ДЦ)
	set @counter = 0
	while(1 = 1)
	begin
		delete top (@priceCount * 100) from dbo.tp_pricesDeleted with(rowlock) where tpd_dateend < @today and tpd_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
		set @deletedRowCount = @@ROWCOUNT
		if @deletedRowCount = 0
		begin
			insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_pricesDeleted завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
			break
		end
		else
			set @counter = @counter + @deletedRowCount
	end	
	
	-- Удаляем неактуальные удаленные цены из TP_PriceComponents (ДЦ)
	set @counter = 0
	while(1 = 1)
	begin
		delete top (@priceCount * 100) from dbo.TP_PriceComponents with(rowlock) where PC_TourDate < @today
		set @deletedRowCount = @@ROWCOUNT
		if @deletedRowCount = 0
		begin
			insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление TP_PriceComponents завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
			break
		end
		else
			set @counter = @counter + @deletedRowCount
	end	
	
	-- Удаляем неактуальные удаленные цены из TP_ServiceCalculateParametrs (ДЦ)
	set @counter = 0
	while(1 = 1)
	begin
		delete top (@priceCount * 100) from dbo.TP_ServiceCalculateParametrs with(rowlock) where SCP_DateCheckIn < @today
		set @deletedRowCount = @@ROWCOUNT
		if @deletedRowCount = 0
		begin
			insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление TP_ServiceCalculateParametrs завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
			break
		end
		else
			set @counter = @counter + @deletedRowCount
	end	

	if dbo.mwReplIsSubscriber() <= 0
	begin
		set @counter = 0
		while (1 = 1)
		begin
			delete top (@priceCount) from dbo.tp_turdates with(rowlock) where td_date < @today and td_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_turdates завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
				break
			end
			else
				set @counter = @counter + @deletedRowCount
		end
		
		set @counter = 0
		while (1 = 1)
		begin
			delete top (@priceCount) from dbo.tp_servicelists with(rowlock) where tl_tikey not in (select tp_tikey from tp_prices with(nolock) where tp_tokey = tl_tokey union select TPD_TIKey from TP_PricesDeleted with(nolock) where TPD_TOKey = tl_tokey) and tl_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_servicelists завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
				break
			end
			else
				set @counter = @counter + @deletedRowCount
		end
		
		set @counter = 0
		while (1 = 1)
		begin
			delete top (@priceCount) from dbo.tp_lists with(rowlock) where ti_key not in (select tp_tikey from tp_prices with(nolock) where tp_tokey = ti_tokey union select TPD_TIKey from TP_PricesDeleted with(nolock) where TPD_TOKey = ti_tokey) and ti_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_lists завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
				break
			end
			else
				set @counter = @counter + @deletedRowCount
		end
		
		set @counter = 0
		while (1 = 1)
		begin
			delete top (@priceCount) from dbo.tp_services with(rowlock) where ts_key not in (select tl_tskey from tp_servicelists with(nolock) where tl_tokey = ts_tokey) and ts_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
			set @deletedRowCount = @@ROWCOUNT
			if @deletedRowCount = 0
			begin
				insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление tp_services завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
				break
			end
			else
				set @counter = @counter + @deletedRowCount
		end
	end
	else
	begin
		exec dbo.mwCleanerQuotes
	end

	declare @mwSearchType int
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'
	
	-- Удаляем неактуальные туры
	set @counter = 0
	while(1 = 1)
	begin
		delete top (@priceCount / 100) from dbo.TP_Tours with(rowlock) where to_datevalid < @today
		set @deletedRowCount = @@ROWCOUNT
		if @deletedRowCount = 0
		begin
			insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление TP_Tours завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)		
			break
		end
		else
			set @counter = @counter + @deletedRowCount
	end
	
	update top (@priceCount / 100) dbo.tp_tours with(rowlock) set to_pricecount = 
		(select count(1) from dbo.tp_prices with(nolock) where tp_tokey = to_key), to_updatetime = getdate()
	where to_update = 0 and exists(select 1 from dbo.tp_turdates with(nolock) where td_tokey = to_key and td_date < @today)
	set @deletedRowCount = @@ROWCOUNT

	insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Обновление tp_tours завершено. Обновлено ' + ltrim(@deletedRowCount) + ' записей', 1)

	if(@mwSearchType = 0)
	begin
			set @counter = 0
			while(1 = 1)
			begin
				delete top (@priceCount * 100) from dbo.mwPriceDataTable with(rowlock) where pt_tourdate < @today and pt_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
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
				delete top (@priceCount * 100) from dbo.mwSpoDataTable with(rowlock) where sd_tourkey not in (select pt_tourkey from dbo.mwPriceDataTable with(nolock)) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
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
				delete top (@priceCount * 100) from dbo.mwPriceDurations with(rowlock) where not exists(select 1 from dbo.mwPriceDataTable with(nolock) where pt_tourkey = sd_tourkey and pt_days = sd_days and pt_nights = sd_nights) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
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
				set @sql = 'delete top (' + ltrim(rtrim(str(@priceCount * 100))) + ') from ' + @objName + ' with(rowlock) where pt_tourdate < ''' + convert(varchar(20), @today, 120) + ''' and pt_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0); set @counterOut = @@ROWCOUNT'
				set @params = '@counterOut int output'
				
				EXECUTE sp_executesql @sql, @params, @counterOut = @counterPart output
				
				if @counterPart = 0
				begin
					insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление ' + @objName + ' завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)	
					break
				end
				else
					set @counter = @counter + @counterPart
			end
			
			--exec sp_executesql @sql
			--set @objName = dbo.mwGetPriceTableName(@cnkey, @ctkeyfrom)
			set @counter = 0
			while(1 = 1)
			begin
				set @sql = 'delete top (' + ltrim(rtrim(str(@priceCount * 100))) + ') from dbo.mwSpoDataTable with(rowlock) where sd_cnkey = ' + ltrim(rtrim(str(@cnkey))) + ' and sd_ctkeyfrom = ' + ltrim(rtrim(str(@ctkeyfrom))) + ' and sd_tourkey not in (select pt_tourkey from ' + @objName + ' with(nolock)) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0); set @counterOut = @@ROWCOUNT'
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
			--exec sp_executesql @sql
			--set @sql = 'delete from dbo.mwPriceDurations where sd_cnkey = ' + ltrim(rtrim(str(@cnkey))) + ' and sd_ctkeyfrom = ' + ltrim(rtrim(str(@ctkeyfrom))) + ' and not exists(select 1 from ' + @objName + ' where pt_tourkey = sd_tourkey and pt_days = sd_days and pt_nights = sd_nights) and sd_tourkey not in (select to_key from tp_tours where to_update <> 0)'
			--exec sp_executesql @sql
			fetch next from delCursor into @cnkey, @ctkeyfrom
		end
		close delCursor
		deallocate delCursor
	end 

	set @counter = 0
	while(1 = 1)
	begin
		delete top (@priceCount) from dbo.mwPriceHotels with(rowlock) where sd_tourkey not in (select sd_tourkey from dbo.mwSpoDataTable with(nolock)) and sd_tourkey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
		set @deletedRowCount = @@ROWCOUNT
		if @deletedRowCount = 0
		begin
			insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Удаление mwPriceHotels завершено. Удалено ' + ltrim(str(@counter)) + ' записей', 1)
			break
		end
		else
			set @counter = @counter + @deletedRowCount
	end
	
	insert into SystemLog (SL_Type, SL_Date, SL_Message, SL_AppID) values(1, GETDATE(), 'Окончание выполнения mwCleaner', 1)
end
GO

GRANT EXECUTE ON [dbo].[mwCleaner] TO PUBLIC 
GO
/*********************************************************************/
/* end sp_mwCleaner.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCleanerQuotes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCleanerQuotes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mwCleanerQuotes]
GO
CREATE PROCEDURE [dbo].[mwCleanerQuotes]
	(
		-- хранимка удаления устаревших квто на поисковой базе
		-- дата с которой считается что квоты устарели
		@oldDate datetime = null,
		-- размер пачки на удаление
		@countRowDeleted int = 10000
	)
AS
BEGIN

	--<VERSION>2009.2.18</VERSION>
	--<DATE>2012-12-13</DATE>

	if (@oldDate is null)
	begin
		set @oldDate = dateadd(day, -1, getdate());
	end

	-- чистим ServiceByDate
	while (1 = 1)
	begin
		delete top (@countRowDeleted) ServiceByDate
		from ServiceByDate
		where SD_Date < @oldDate
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end
	
	-- чистим quotaLimitation
	while (1 = 1)
	begin
		delete top (@countRowDeleted) QuotaLimitations 
		from QuotaLimitations
		where QL_QPID in (select QP_Id from QuotaParts with (nolock) where QP_Date < @oldDate)
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end
	
	-- чистим QuotaParts
	while (1 = 1)
	begin
		delete top (@countRowDeleted) QuotaParts 
		from QuotaParts
		where QP_Date < @oldDate
		and not exists (select top 1 1 from QuotaLimitations with (nolock) where QL_QPID = QP_ID)
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end
	
	-- чистим StopSales
	while (1 = 1)
	begin
		delete top (@countRowDeleted) StopSales 
		from StopSales
		where SS_Date < @oldDate
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end
	
	-- чистим QuotaDetailes
	while (1 = 1)
	begin
		delete top (@countRowDeleted) QuotaDetails 
		from QuotaDetails
		where QD_Date < @oldDate
		and not exists (select top 1 1 from StopSales with (nolock) where SS_QDID = QD_Id)
		and not exists (select top 1 1 from QuotaParts with (nolock) where QP_QDID = QD_Id)
		
		if (@@ROWCOUNT = 0)
		begin
			break;
		end
	end
END

GO

grant exec on [dbo].[mwCleanerQuotes] to public
go
/*********************************************************************/
/* end sp_mwCleanerQuotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCreateNewPriceTable.sql */
/*********************************************************************/
IF exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCreateNewPriceTable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mwCreateNewPriceTable]
GO

CREATE procedure [dbo].[mwCreateNewPriceTable]
	@countryKey int,
	@cityFromKey int,
	@forceCreate bit = 0		-- определяет, нужно ли создавать таблицы в случае использования сегментирования без репликации. 
								-- Иначе в этом случае будет ждать джоб mwCheckPriceTables, пока он не создаст таблицы
AS	
begin
	--<VERSION>2009.2</VERSION>
	--<DATE>2013-01-22</DATE>

	declare @tableName varchar(1024)
	set @tableName = dbo.mwGetPriceTableName(@countryKey, @cityFromKey)

	declare @divideByCountry as bit
	set @divideByCountry = 0
	select @divideByCountry = SS_ParmValue from SystemSettings where SS_ParmName = 'MWDivideByCountry'

	if (@divideByCountry = 0 or dbo.mwReplIsPublisher() > 0) and @forceCreate = 0
		return 1

	if dbo.mwReplIsSubscriber() > 0 or @forceCreate = 1
	begin
		-- сегментирование ценовых таблиц при репликации. 
		-- необходимо создать ценовые таблицы по новым направлениям
		if exists(select id from sysobjects where id = OBJECT_ID(@tableName) and xtype = 'U ')
			return -1

		--Создаем таблицу
		exec dbo.mwCreatePriceTable @countryKey, @cityFromKey
			
		if exists(select id from sysobjects where id = OBJECT_ID(dbo.mwGetPriceViewName(@countryKey, @cityFromKey)) and xtype = 'V ')
			return -2
		
		exec dbo.mwCreatePriceView @countryKey, @cityFromKey

		exec dbo.mwGrantPermissions @countryKey, @cityFromKey
		
		return 1
	end
	else
	begin
		-- сегментирование ценовых таблиц без репликации		
		if @forceCreate = 0
		begin		
			-- процесс выполняется под пользователем расчетчика, права могут быть ограничены.
			-- Поэтому созданием таблиц занимается джоб mwCheckPriceTables, а тут просто ждем, пока таблицы не создадутся.
			if not exists (select top 1 1 from mwPriceTablesList where ptl_ctFromKey = @cityFromKey and ptl_cnKey = @countryKey)
				and not exists(select id from sysobjects where id = OBJECT_ID(@tableName) and xtype = 'U ')
				insert into mwPriceTablesList (ptl_ctFromKey, ptl_cnKey) values (@cityFromKey, @countryKey)
			
			declare @maxAttempts as int, @attempts as int
			set @maxAttempts = 30
			set @attempts = 0
			
			while 1=1
			begin
			
				if @attempts >= @maxAttempts
				begin
					declare @errMsg as nvarchar(max)
					set @errMsg = 'Исчерпаны попытки ожидания создания ценовой таблицы. Проверьте состояние job mwCheckPriceTables'
					insert into SystemLog (sl_date, sl_message) values (GETDATE(), @errMsg)
				end
				
				if exists(select id from sysobjects where id = OBJECT_ID(@tableName) and xtype = 'U ')
					break

				waitfor DELAY '00:00:05'
				set @attempts = @attempts + 1
			
			end
			return 1
		end
	end

	return 1

end

GO

GRANT EXEC ON [dbo].[mwCreateNewPriceTable] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwCreateNewPriceTable.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCreatePriceTable.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwCreatePriceTable')
	drop proc dbo.mwCreatePriceTable
go

CREATE procedure [dbo].[mwCreatePriceTable] @countryKey int, @cityFromKey int
as
begin
	--<DATE>2013-01-24</DATE>
	--<VERSION>2009.2.18</VERSION>

	declare @sql varchar(8000)
	declare @tableName varchar(1024)
	set @tableName = dbo.mwGetPriceTableName(@countryKey, @cityFromKey)
	set @sql = 
	'CREATE TABLE ' + @tableName + ' (
		[pt_mainplaces] [int] NULL,
		[pt_addplaces] [int] NULL,
		[pt_main] [smallint] NULL,
		[pt_tourvalid] [datetime] NULL,
		[pt_tourcreated] [datetime] NULL,
		[pt_tourdate] [datetime] NULL,
		[pt_days] [int] NULL,
		[pt_nights] [int] NULL,
		[pt_cnkey]  int NOT NULL check(pt_cnkey = ' + cast(isnull(@countryKey, 0) as varchar) + '),
		[pt_ctkeyfrom] int NOT NULL  check(pt_ctkeyfrom = ' + cast(isnull(@cityFromKey, 0) as varchar) + '),
		[pt_apkeyfrom] [int] NULL,
		[pt_ctkeyto] [int] NULL,
		[pt_apkeyto] [int] NULL,
		[pt_ctkeybackfrom] [int] NULL,
		[pt_ctkeybackto] [int] NULL,
		[pt_tourkey] [int] NULL,
		[pt_tourtype] [int] NULL,
		[pt_tlkey] [int] NULL,
		[pt_pricelistkey] [int] NULL,
		[pt_pricekey] [int] NOT NULL,
		[pt_price] [float] NULL,
		[pt_hdkey] [int] NULL,
		[pt_hdpartnerkey] [int] NULL,
		[pt_rskey] [int] NULL,
		[pt_ctkey] [int] NULL,
		[pt_hdstars] [varchar](12) NULL,
		[pt_pnkey] [int] NULL,
		[pt_hrkey] [int] NULL,
		[pt_rmkey] [int] NULL,
		[pt_rckey] [int] NULL,
		[pt_ackey] [int] NULL,
		[pt_childagefrom] [int] NULL,
		[pt_childageto] [int] NULL,
		[pt_childagefrom2] [int] NULL,
		[pt_childageto2] [int] NULL,
		[pt_hdname] [varchar](60) NULL,
		[pt_tourname] [varchar](160) NULL,
		[pt_pnname] [varchar](30) NULL,
		[pt_pncode] [varchar](30) NULL,
		[pt_rmname] [varchar](60) NULL,
		[pt_rmcode] [varchar](60) NULL,
		[pt_rcname] [varchar](60) NULL,
		[pt_rccode] [varchar](40) NULL,
		[pt_acname] [varchar](70) NULL,
		[pt_accode] [varchar](70) NULL,
		[pt_rsname] [varchar](50) NULL,
		[pt_ctname] [varchar](50) NULL,
		[pt_rmorder] [int] NULL,
		[pt_rcorder] [int] NULL,
		[pt_acorder] [int] NULL,
		[pt_rate] [varchar](3) NULL,
		[pt_toururl] [varchar](128) NULL,
		[pt_hotelurl] [varchar](254) NULL,
		[pt_isenabled] [smallint] NULL,
		[pt_chkey] [int] NULL,
		[pt_chbackkey] [int] NULL,
		[pt_hdday] [int] NULL,
		[pt_hdnights] [int] NULL,
		[pt_chday] [int] NULL,
		[pt_chpkkey] [int] NULL,
		[pt_chprkey] [int] NULL,
		[pt_chbackday] [int] NULL,
		[pt_chbackpkkey] [int] NULL,
		[pt_chbackprkey] [int] NULL,
		[pt_hotelkeys] [varchar](256) NULL,
		[pt_hotelroomkeys] [varchar](256) NULL,
		[pt_hotelstars] [varchar](256) NULL,
		[pt_pansionkeys] [varchar](256) NULL,
		[pt_hotelnights] [varchar](256) NULL,
		[pt_key] [int] IDENTITY PRIMARY KEY,
		[pt_chdirectkeys] [varchar](256) NULL,
		[pt_chbackkeys] [varchar](256) NULL,
		[pt_topricefor] [smallint] NOT NULL,
		[pt_AccmdType] [smallint] NULL,
		[pt_hddetails] [varchar](256) NULL,
		[pt_hash] [varchar](1024) NULL,
		[pt_tlattribute] [int] NULL,
		[pt_spo] [int] NULL,
		[pt_autodisabled] [smallint] NULL,
		[pt_directFlightAttribute] [int] NULL,
		[pt_backFlightAttribute] [int] NULL)'
	exec(@sql)
	set @sql='grant select, delete, update, insert, alter on '+@tableName+' to public'
	exec(@sql)
end
GO

grant exec on dbo.mwCreatePriceTable to public
go

/*********************************************************************/
/* end sp_mwCreatePriceTable.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCreatePriceTableIndexes.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCreatePriceTableIndexes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwCreatePriceTableIndexes]
GO

CREATE PROCEDURE [dbo].[mwCreatePriceTableIndexes]
	@countryKey int,
	@cityFromKey int
as
begin
	declare @tableName varchar(50)
	set @tableName = dbo.mwGetPriceTableName(@countryKey, @cityFromKey)
	declare @sql varchar(8000)
	set @sql = '
	if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name not like ''PK[_]%''  and name like ''x[_]%'')
	begin
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_complex'')
			CREATE NONCLUSTERED INDEX [x_complex] ON ' + @tableName + '([pt_cnkey] ASC, [pt_ctkeyfrom] ASC, [pt_tourkey] ASC, [pt_tourdate] ASC) INCLUDE ( [pt_hdkey], [pt_pnkey])
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_date'')
			CREATE NONCLUSTERED INDEX [x_date] ON ' + @tableName + '([pt_tourdate] ASC)
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_enabled'')
			CREATE NONCLUSTERED INDEX [x_enabled] ON ' + @tableName + '([pt_isenabled] DESC)
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_hdkey'')
			CREATE NONCLUSTERED INDEX [x_hdkey] ON ' + @tableName + '([pt_hdkey] ASC)			
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_main_persprice'')
			CREATE NONCLUSTERED INDEX [x_main_persprice] ON ' + @tableName + '([pt_tourdate] ASC,[pt_tourtype] ASC,[pt_rskey] ASC,[pt_ctkey] ASC,[pt_tourkey] ASC,[pt_nights] ASC,[pt_pnkey] ASC,[pt_hdstars] ASC) INCLUDE ([pt_tlkey],[pt_hdkey],[pt_pricekey],[pt_price],[pt_rmkey],[pt_rckey],[pt_days],[pt_isenabled],[pt_hdname],[pt_rcname],[pt_rccode],[pt_chkey],[pt_chbackkey],[pt_hdday],[pt_hdnights],[pt_hdpartnerkey],[pt_chday],[pt_chpkkey],[pt_chprkey],[pt_chbackday],[pt_chbackpkkey],[pt_chbackprkey],[pt_childagefrom],[pt_childageto],[pt_childagefrom2],[pt_childageto2],[pt_main],[pt_tourvalid],[pt_chbackkeys],[pt_chdirectkeys],[pt_hddetails],[pt_topricefor],[pt_directFlightAttribute],[pt_backFlightAttribute],[pt_mainplaces],[pt_hrkey])
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_main_roomprice'')
			CREATE NONCLUSTERED INDEX [x_main_roomprice] ON ' + @tableName + '([pt_mainplaces] ASC,[pt_addplaces] ASC,[pt_tourdate] ASC,[pt_tourtype] ASC,[pt_rskey] ASC,[pt_ctkey] ASC,[pt_tourkey] ASC,[pt_nights] ASC,[pt_pnkey] ASC,[pt_hdstars] ASC) INCLUDE ([pt_tlkey],[pt_hdkey],[pt_pricekey],[pt_price],[pt_rmkey],[pt_rckey],[pt_days],[pt_isenabled],[pt_hdname],[pt_rcname],[pt_rccode],[pt_chkey],[pt_chbackkey],[pt_hdday],[pt_hdnights],[pt_hdpartnerkey],[pt_chday],[pt_chpkkey],[pt_chprkey],[pt_chbackday],[pt_chbackpkkey],[pt_chbackprkey],[pt_childagefrom],[pt_childageto],[pt_childagefrom2],[pt_childageto2],[pt_main],[pt_tourvalid],[pt_chbackkeys],[pt_chdirectkeys],[pt_hddetails],[pt_topricefor],[pt_directFlightAttribute],[pt_backFlightAttribute],[pt_hrkey])
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_mwHotelDetails'')
			CREATE NONCLUSTERED INDEX [x_mwHotelDetails] ON ' + @tableName + '([pt_isenabled] DESC,[pt_tourvalid] ASC,[pt_main] DESC,[pt_hdkey] ASC,[pt_price] ASC,[pt_tourdate] ASC,[pt_rate] ASC)
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_pricekey'')
			CREATE NONCLUSTERED INDEX [x_pricekey] ON ' + @tableName + '([pt_pricekey] ASC)
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_singleprice'')
			CREATE NONCLUSTERED INDEX [x_singleprice] ON ' + @tableName + '([pt_tourdate] ASC,[pt_hdkey] ASC,[pt_rmkey] ASC,[pt_rckey] ASC,[pt_ackey] ASC,[pt_pnkey] ASC,[pt_days] ASC,[pt_nights] ASC) INCLUDE ( [pt_hdpartnerkey],[pt_chprkey],[pt_tourtype],[pt_main],[pt_isenabled],[pt_autodisabled],[pt_tourkey],[pt_price],[pt_ctkeyfrom])
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_singleprice_tour'')
			CREATE NONCLUSTERED INDEX [x_singleprice_tour] ON ' + @tableName + '([pt_tourkey] ASC,[pt_main] ASC) INCLUDE ( [pt_tourdate],[pt_hdkey],[pt_rmkey],[pt_rckey],[pt_ackey],[pt_pnkey],[pt_days],[pt_nights],[pt_hdpartnerkey],[pt_chprkey],[pt_tourtype],[pt_ctkeyfrom])
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_tourkey'')
			CREATE NONCLUSTERED INDEX [x_tourkey] ON ' + @tableName + '([pt_tourkey] ASC)
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_quotacache_flight'')
			CREATE NONCLUSTERED INDEX [x_quotacache_flight] ON ' + @tableName + ' 
				(
					[pt_days] ASC
				)
				INCLUDE ( [pt_tourdate],
				[pt_ctkeyto],
				[pt_pricekey],
				[pt_hdkey],
				[pt_hdpartnerkey],
				[pt_rmkey],
				[pt_rckey],
				[pt_chkey],
				[pt_chbackkey],
				[pt_hdday],
				[pt_hdnights],
				[pt_chday],
				[pt_chpkkey],
				[pt_chprkey],
				[pt_chbackday],
				[pt_chbackpkkey],
				[pt_chbackprkey]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	end
	'
	exec(@sql)
end
GO

GRANT EXEC ON [dbo].[mwCreatePriceTableIndexes] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwCreatePriceTableIndexes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwFillPriceTable.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwFillPriceTable')
	drop proc dbo.mwFillPriceTable
go

create procedure [dbo].[mwFillPriceTable] 
	@dataTableName varchar (1024),
	@countryKey int,
	@cityFromKey int
as
--<VERSION>9.2.18</VERSION>
--<DATE>2012-11-21</DATE>

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
			pt_hddetails,
			pt_directFlightAttribute,
			pt_backFlightAttribute)
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
			pt_hddetails,
			pt_directFlightAttribute,
			pt_backFlightAttribute
		from ' + @dataTableName + ' with (nolock)'
exec (@sql)
go

grant exec on dbo.mwFillPriceTable to public
go

/*********************************************************************/
/* end sp_mwFillPriceTable.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwFillTP.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwFillTP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwFillTP]
GO

CREATE procedure [dbo].[mwFillTP] (@tokey int, @calcKey int = null)
as
begin
	-- <date>2012-11-01</date>
	-- <version>2009.2.17.1</version>
	declare @sql varchar(4000)
	declare @source varchar(200)
	set @source = ''

	declare @tokeyStr varchar (20)
	set @tokeyStr = cast(@tokey as varchar(20))

	declare @calcKeyStr varchar (20)
	set @calcKeyStr = cast(@calcKey as varchar(20))

	if dbo.mwReplIsSubscriber() > 0 and len(dbo.mwReplPublisherDB()) > 0
		set @source = '[mt].' + dbo.mwReplPublisherDB() + '.'
	
	--delete from dbo.tp_tours where to_key = @calcKey	
	if not exists(select 1 from dbo.tp_tours with(nolock) where to_key = @tokey)
	begin
		set @sql = '
		insert into dbo.tp_tours with(rowlock) (
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
	
	if(@calcKey is not null)
		delete from dbo.TP_TurDates where TD_CalculatingKey = @calcKey
	else
		delete from dbo.TP_TurDates where TD_TOKey = @tokey
		
	--if not exists(select 1 from dbo.TP_TurDates with(nolock) where td_tokey = @calcKey)
	begin
		set @sql = 
		'insert into dbo.TP_TurDates with(rowlock) (
			[TD_Key],
			[TD_TOKey],
			[TD_Date],
			[TD_UPDATE],
			[TD_CHECKMARGIN],
			[TD_CalculatingKey]
		)
		select
			r.[TD_Key],
			r.[TD_TOKey],
			r.[TD_Date],
			r.[TD_UPDATE],
			r.[TD_CHECKMARGIN],
			r.[TD_CalculatingKey]
		from
			' + @source + 'dbo.TP_TurDates as r with(nolock)
		where
			'
			
		if(@calcKey is not null)
			set @sql = @sql + 'r.TD_Date in (select TP_DateBegin from ' + @source + 'dbo.TP_Prices where TP_TOKey = TD_TOKey and TP_CalculatingKey = ' + ltrim(str(@calcKey)) + ') and '
			
		set @sql = @sql + ' r.TD_TOKey = ' + @tokeyStr
		set @sql = @sql + ' and r.TD_Key not in (select TD_Key from dbo.TP_TurDates where TD_TOKey = r.TD_TOKey)'

		exec (@sql)		
	end	
	
    delete dbo.tp_services where ts_tokey = @tokey
	--if not exists(select 1 from dbo.tp_services with(nolock) where ts_tokey = @calcKey)
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
			[TS_CHECKMARGIN],
			[TS_CalculatingKey]
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
			[TS_CHECKMARGIN],
			[TS_CalculatingKey]
		from
			' + @source + 'dbo.tp_services with(nolock)
		where
			'

		set @sql = @sql + 'TS_TOKey = ' + @tokeyStr

		exec (@sql)
	end

	delete from dbo.tp_lists where ti_tokey = @tokey
	--if not exists(select 1 from dbo.tp_lists with(nolock) where ti_tokey = @calcKey)
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
			[ti_hotelstars],
			[TI_CalculatingKey]
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
			[ti_hotelstars],
			[TI_CalculatingKey]
		from
			' + @source + 'dbo.tp_lists with(nolock)
		where
			'
		if(@calcKey is not null)
			set @sql = @sql + 'TI_Key in (select TP_TIKey from ' + @source + 'dbo.TP_Prices where TP_TOKey = TI_TOKey and TP_CalculatingKey = ' + ltrim(str(@calcKey)) + ') and '
		
		set @sql = @sql + 'TI_TOKey = ' + @tokeyStr

		exec (@sql)
	end

	delete from dbo.tp_servicelists where tl_tokey = @tokey
	--if not exists(select 1 from dbo.tp_servicelists with(nolock) where tl_tokey = @calcKey)
	begin	
		set @sql = 
		'insert into dbo.tp_servicelists with(rowlock) (
			[TL_Key],
			[TL_TOKey],
			[TL_TSKey],
			[TL_TIKey],
			[TL_CalculatingKey]
		)
		select
			[TL_Key],
			[TL_TOKey],
			[TL_TSKey],
			[TL_TIKey],
			[TL_CalculatingKey]
		from
			' + @source + 'dbo.tp_servicelists with(nolock)
		where
			'

		set @sql = @sql + 'TL_TOKey = ' + @tokeyStr

		exec (@sql)
	end

	delete from dbo.tp_prices where tp_tokey = @tokey
	--if not exists(select 1 from dbo.tp_prices with(nolock) where tp_tokey = @calcKey)
	begin
		set @sql = 
		'insert into dbo.tp_prices with(rowlock) (
			[TP_Key],
			[TP_TOKey],
			[TP_DateBegin],
			[TP_DateEnd],
			[TP_Gross],
			[TP_TIKey],
			[TP_CalculatingKey]
		)
		select
			[TP_Key],
			[TP_TOKey],
			[TP_DateBegin],
			[TP_DateEnd],
			[TP_Gross],
			[TP_TIKey],
			[TP_CalculatingKey]
		from
			' + @source + 'dbo.tp_prices with(nolock)
		where
			'

		if(@calcKey is not null)
			set @sql = @sql + 'TP_CalculatingKey = ' + @calcKeyStr
		else
			set @sql = @sql + 'TP_TOKey = ' + @tokeyStr

		exec (@sql)
	end
end
GO

GRANT EXEC ON [dbo].[mwFillTP] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwFillTP.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetSearchFilterDirectionData.sql */
/*********************************************************************/
if EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[mwGetSearchFilterDirectionData]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[mwGetSearchFilterDirectionData]
GO

--<VERSION>7.2.39.3</VERSION>
--<DATA>2013-01-11</DATA>
CREATE PROCEDURE [dbo].[mwGetSearchFilterDirectionData]
	@datesInterval int = 30,
	@departFromKeys varchar(MAX) = null,
	@countryKeys varchar(MAX) = null,
	@tourTypeKeys varchar(MAX) = null
AS
BEGIN
	SET NOCOUNT ON;	
	declare @whereClause varchar (MAX)
	declare @sql varchar (MAX)
	set @sql = '
SELECT DISTINCT
sd_cnkey AS CountryKey,
CN_NAME AS CountryName, 
sd_ctkeyfrom AS DepartureFromCityKey, 
(CASE WHEN CT_NAME IS NULL OR LEN(CT_NAME)=0 THEN ''-Без перелета-'' ELSE CT_NAME END) AS DepartureFromCityName,
sd_tourtype AS TourTypeKey, 
TP_NAME AS TourTypeName
FROM 
dbo.mwSpoDataTable WITH (nolock) INNER JOIN
dbo.TP_Tours WITH (nolock) ON TO_Key = sd_tourkey INNER JOIN
dbo.tbl_Country WITH (nolock) ON CN_KEY = sd_cnkey INNER JOIN
dbo.HotelDictionary WITH (nolock) ON HD_KEY = sd_hdkey LEFT OUTER JOIN
dbo.CityDictionary WITH (nolock) ON CT_KEY = sd_ctkeyfrom INNER JOIN
dbo.TipTur WITH (nolock) ON TP_KEY = sd_tourtype INNER JOIN
dbo.Pansion WITH (nolock) ON PN_KEY = sd_pnkey
left join rooms with(nolock) on rm_key in (select mwPriceHotels.sd_rmkey from mwPriceHotels with(nolock) where mwPriceHotels.ph_sdkey = sd_key)
 LEFT JOIN
dbo.Resorts WITH (nolock) ON RS_KEY = sd_rskey'
	set @whereClause = '
	WHERE sd_isenabled > 0 AND EXISTS(select TOP (1) 1 from dbo.TP_TurDates WITH (nolock) where TD_TOKey = sd_tourkey
AND TD_Date > DATEADD(DAY, - 1, GETDATE())
AND TD_Date < DATEADD(DAY, '+ str(@datesInterval) +', GETDATE()))'

	
	if (len(@departFromKeys) > 0) 
	begin
		set @whereClause = @whereClause + ' AND ' + 'sd_ctkeyfrom IN ('+@departFromKeys+')'
	end
	if (len(@countryKeys) > 0) 
	begin
		set @whereClause = @whereClause + ' AND ' + 'sd_cnkey IN ('+@countryKeys+')'
	end
	if (len(@tourTypeKeys) > 0) 
	begin
		set @whereClause = @whereClause + ' AND ' + 'sd_tourtype IN ('+@tourTypeKeys+')'
	end
	
	set @sql = @sql + @whereClause + ' ORDER BY sd_ctkeyfrom, sd_cnkey, sd_tourtype'
		
	print (@sql)
	exec(@sql)
END
GO

GRANT EXEC ON [dbo].[mwGetSearchFilterDirectionData] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwGetSearchFilterDirectionData.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetServiceVariants.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwGetServiceVariants')
	drop proc dbo.mwGetServiceVariants
go

--<VERSION>9.2.19</VERSION>
--<DATE>2013-03-20</DATE>

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
			-- Спорный момент, но иначе не работает вариант, когда изначально берется цена с cs_long < @serviceDays, а потом добивается другими квотами с конца
			--set @whereClause = @whereClause + ' AND ' + cast(@serviceDays as varchar) + ' between isnull(cs1.CS_longmin, -1) and isnull(cs1.CS_long, 10000)'
			set @whereClause = @whereClause + ' AND ' + cast(@serviceDays as varchar) + ' >= isnull(cs1.CS_longmin, -1)'
			
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
/* begin sp_mwHotelQuotes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwHotelQuotes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mwHotelQuotes]

GO
CREATE PROCEDURE [dbo].[mwHotelQuotes]
	(
		-- хранимка получает сведения о квотах для отелей
		--<version>2009.2.01</version>
		--<data>2012-11-09</data>
		@Filter varchar(2000),
		@DaysCount int,
		@AgentKey int, 
		@FromDate	datetime,
		@RequestOnRelease smallint,
		@NoPlacesResult int,
		@CheckAgentQuotes smallint,
		@CheckCommonQuotes smallint,
		@ExpiredReleaseResult int
	)
AS
BEGIN

DECLARE @checkQuotesOnWebService as bit, @checkQuotesService as nvarchar(150)
DECLARE @webServiceFailure as bit

-- признак ошибки веб-сервиса
SET @webServiceFailure = 0
-- проверять квоты через веб-сервис
SET @checkQuotesOnWebService = 0
SELECT TOP 1 @checkQuotesOnWebService = ss_parmvalue FROM systemsettings WITH (nolock) WHERE ss_parmname = 'NewSetToQuota'

-- создание временной таблицы
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
	Quotas varchar(2000),
	HotelRoomsKey int,
	HotelRoomsMain int
)

-- формирование данных
DECLARE	@HotelKey int
DECLARE	@RoomKey int 
DECLARE	@RoomCategoryKey int 
DECLARE @HotelRoomsKey int
DECLARE @HotelRoomsMain int
DECLARE @freePlacesMask int

DECLARE @script VARCHAR(4000)
SET @script = 'SELECT DISTINCT SD_CTKEY, SD_CTNAME, mwSpoDataTable.SD_HDKEY, SD_HDNAME  + '' ('' + ISNULL(SD_RSNAME, SD_CTNAME) + '') '' + mwSpoDataTable.SD_HDSTARS as HotelName,
				ISNULL(HD_HTTP, ''''), SD_RMKEY, RM_NAME, SD_RCKEY, RC_NAME, '''', HR_Key, HR_Main 
	FROM mwPriceHotels with(nolock)
		JOIN mwSpoDataTable with(nolock) ON mwPriceHotels.PH_SDKEY = mwSpoDataTable.SD_KEY
		JOIN Rooms with(nolock) ON SD_RMKEY = RM_KEY		
		JOIN RoomsCategory with(nolock) ON SD_RCKEY = RC_KEY
		JOIN HotelDictionary with(nolock) ON mwSpoDataTable.SD_HDKEY = HD_KEY
		JOIN HotelRooms with(nolock) ON (SD_HRKey = HR_Key)
		WHERE ' + @filter + ' ORDER BY HotelName'

INSERT INTO #tmp EXEC(@script)

-- если стоит флаг проверки через веб-сервис
if @checkQuotesOnWebService = 1
BEGIN TRY
	DECLARE hSql CURSOR 
	FOR 
		SELECT HotelKey, RoomKey, RoomCategoryKey, HotelRoomsKey, HotelRoomsMain FROM #tmp
	FOR UPDATE OF Quotas

	OPEN hSql
	FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey, @HotelRoomsKey, @HotelRoomsMain

	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @checkQuotesResult int, @places int, @allPlaces int
		SELECT @checkQuotesResult = result, @places = freePlaces, @allPlaces = allPlaces FROM [dbo].WcfQuotaCheckOneResult(0, 3, @HotelKey, @HotelRoomsKey, @FromDate, @FromDate, -1, @AgentKey, @DaysCount, @HotelRoomsMain, null)
		UPDATE #tmp SET Quotas = '0=' + @places + ':' + @allplaces
			WHERE current of hSql
		FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey, @HotelRoomsKey, @HotelRoomsMain
	END
	CLOSE hSql
	DEALLOCATE hSql
END TRY
BEGIN CATCH
	SET @webServiceFailure = 1
	CLOSE hSql
	DEALLOCATE hSql
END CATCH

-- если произошла ошибка или стоит флаг проверки обычным методом
if @checkQuotesOnWebService = 0 or @webServiceFailure = 1
BEGIN
	DECLARE hSql CURSOR 
	FOR 
		SELECT HotelKey, RoomKey, RoomCategoryKey, HotelRoomsKey, HotelRoomsMain FROM #tmp
	FOR UPDATE OF Quotas

	OPEN hSql
	FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey, @HotelRoomsKey, @HotelRoomsMain

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE #tmp SET Quotas = (select top 1 qt_additional from mwCheckQuotesEx(3, @HotelKey, @RoomKey, @RoomCategoryKey, @AgentKey, -1, @FromDate, 1, @DaysCount, @RequestOnRelease, @NoPlacesResult, @CheckAgentQuotes, @CheckCommonQuotes, 1, 0, 0, 0, 0, -1, @ExpiredReleaseResult))
			WHERE current of hSql
		FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey, @HotelRoomsKey, @HotelRoomsMain
	END
	CLOSE hSql
	DEALLOCATE hSql
END

CREATE TABLE #tmp2
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

-- исключаем данные, для совместимости с прошлыми версиями
SET @script = 'SELECT DISTINCT CityKey, CityName, HotelKey, HotelName, HotelHTTP, RoomKey, RoomName, RoomCategoryKey, RoomCategoryName, Quotas FROM #tmp'
INSERT INTO #tmp2 EXEC(@script)
SELECT * FROM #tmp2

-- удаление временной таблицы
DROP TABLE  #tmp
DROP TABLE  #tmp2

END

GO
grant exec on [dbo].[mwHotelQuotes] to public
go
/*********************************************************************/
/* end sp_mwHotelQuotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwMakeFullSVName.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MWMAKEFULLSVNAME]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mwMakeFullSVName]
GO
CREATE    PROCEDURE [dbo].[mwMakeFullSVName]
(
--<VERSION>2009.2.17.1</VERSION>
--<DATE>2012-12-26</DATE>
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

Set @sTextCity = ISNULL(@sTextCity,'')
Set @sTextCityLat = ISNULL(@sTextCityLat,'')

		If @nCode>0
		      	SELECT	@sText = isnull(HD_Name,'') + '-' + isnull(HD_Stars, ''), @bIsCruise = HD_IsCruise 
			FROM 	dbo.HotelDictionary 
			WHERE	HD_Key = @nCode
		Set @sTextLat = @sText
		If @bIsCruise = 1
			If @nSvKey = @TYPE_HOTEL
			BEGIN
				Set @sName = 'Круиз::'
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
			SELECT 	@sText = TR_Name + (case  when (TR_NMen>0)  then (','+ CAST ( TR_NMen  AS VARCHAR(10) )+ ' чел.')  else ' ' end),
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
			Set @sName = @sName + ',' + isnull(cast(@nNDays as varchar (10)), '') + ' ' + 'дней'
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
/* begin sp_mwParseHotelDetails.sql */
/*********************************************************************/
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
	@HotelPartnerKey int output,
	@HotelRoomKey int output
as
--<VERSION>9.2.18</VERSION>
--<DATE>2012-11-13</DATE>

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
	set @tmpPrevPosition = @tmpCurPosition + 1

	set @tmpCurPosition = charindex(':', @HotelDetailsString, @tmpPrevPosition + 1)
	set @HotelRoomKey = CAST(substring(@HotelDetailsString, @tmpPrevPosition, @tmpCurPosition - @tmpPrevPosition) as int)
go

grant exec on dbo.mwParseHotelDetails to public
go
/*********************************************************************/
/* end sp_mwParseHotelDetails.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplProcessQueueDivide.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwReplProcessQueueDivide')
	drop proc dbo.mwReplProcessQueueDivide
go

-- Параллельная обработка очереди туров
create procedure [dbo].[mwReplProcessQueueDivide]
as
begin
	--<VERSION>2009.2</VERSION>
	--<DATE>2013-01-15</DATE>

	if dbo.mwReplIsSubscriber() <= 0
		return

	declare @rqId int
	declare @rqMode int
	declare @rqToKey int
	declare @rqCalculatingKey int
	declare @rqOverwritePrices bit

	declare @TableUsed table(CNKey int, CTKey int)

	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	begin tran 
	insert into @TableUsed (CNKey, CTKey)
	select distinct to_cnkey, tl_CTDepartureKey
	from mwReplQueue, tp_tours with(nolock), turlist with(nolock)
	where [rq_state] = 3
		and to_key = rq_tokey and to_trkey = tl_key

	select top 1 @rqId = [rq_id], @rqMode = rq_mode, @rqToKey = rq_tokey, @rqCalculatingKey = rq_CalculatingKey, @rqOverwritePrices = RQ_OverwritePrices
	from mwReplQueue LEFT OUTER JOIN tp_tours with(nolock) ON to_key = rq_tokey LEFT OUTER JOIN turlist with(nolock) ON to_trkey = tl_key
	where ([rq_state] = 1 or [rq_state] = 2)
			and not exists (SELECT 1 FROM @TableUsed WHERE to_cnkey = CNKey and  tl_CTDepartureKey = CTKey)
	order by [rq_priority] desc, [rq_crdate]

	update mwReplQueue set [rq_state] = 3, [rq_startdate] = getdate() where [rq_id] = @rqId
	commit tran

	if (@rqId is null or @rqToKey is null or @rqMode is null)
		return
	
	insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
		select @rqId, 'Command start.'
		
	begin try	
		if (@rqMode = 1)
		begin
			exec FillMasterWebSearchFields @tokey = @rqToKey, @calcKey = @rqCalculatingKey, @overwritePrices = @rqOverwritePrices
		end
		else if (@rqMode = 2)
		begin
			exec FillMasterWebSearchFields @tokey = @rqToKey, @calcKey = @rqCalculatingKey, @overwritePrices = @rqOverwritePrices
		end
		else if (@rqMode = 3)
		begin
			exec mwReplDisablePriceTour @rqToKey, @rqId
		end
		else if (@rqMode = 4)
		begin
			exec mwReplDeletePriceTour @rqToKey, @rqId
		end
		else if (@rqMode = 5)
		begin
			exec mwReplUpdatePriceTourDateValid @rqToKey, @rqId
		end
	
	end try
	begin catch
		update mwReplQueue set [rq_state] = 4, [rq_enddate] = getdate() where [rq_id] = @rqId
		
		declare @errMessage varchar(max)
		set @errMessage = 'Error at ' + isnull(ERROR_PROCEDURE(), '[mwReplProcessQueueDivide]') +' : ' + isnull(ERROR_MESSAGE(), '[msg_not_set]')
		
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
		select @rqId, @errMessage
		return
	end catch

	update mwReplQueue set [rq_state] = 5, [rq_enddate] = getdate() where [rq_id] = @rqId
	
	insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
		select @rqId, 'Command complete.'

end
GO

grant exec on [dbo].[mwReplProcessQueueDivide] to public
GO
/*********************************************************************/
/* end sp_mwReplProcessQueueDivide.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculateAddCosts.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculateAddCosts]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculateAddCosts]
GO
CREATE PROCEDURE [dbo].[ReCalculateAddCosts]
	(
		-- хранимка обсчитывает изменившиеся доплаты
		-- <date>2012-08-23</date>
		-- <version>2009.02.26</version>
		-- количество записей из таблицы TP_QueueAddCosts, за 1 обработку
		@amountItem int,
		-- необязательный параметр - ключи туров, если задан то расчитываем доплаты только по ним
		@tourKeys nvarchar(max) = null,
		-- необязательный параметр, ключи из очереди на перерасчет, если заданы то рассчитаваем только по ним
		@xQACIdTable nvarchar(max) = null
	)
AS
BEGIN
	SET ARITHABORT ON;
	set nocount on;
	declare @beginTime datetime
	set @beginTime = getDate()
	
	-- временная таблица для ограничения пачки расчитываемых доплат
	declare @tempQueueAddCosts table
	(
		xQAC_Id int,
		xQAC_ADCId int
	)
	
	insert into @tempQueueAddCosts (xQAC_Id, xQAC_ADCId)
	select top (@amountItem) QAC_Id, QAC_ADCId
	from TP_QueueAddCosts join AddCosts with(nolock) on ADC_Id = QAC_ADCId
	where
	-- если задан ключ тура то выбираем строки только для него
	(@tourKeys is null or ADC_TLKey in (select xt_key from dbo.ParseKeys(@tourKeys)))
	-- если заданы конкретные записи в очереди то расчитываем только по ним
	and ((@xQACIdTable is null) or (QAC_Id in (select xt_key from dbo.ParseKeys(@xQACIdTable))))
	
	-- таблица для храниния результата расчета доплат
	declare @tableResult table
	(
		xSCPId int,
		xTRKey int,
		xDateCheckIn datetime,
		xValueIsCommission money,
		xValueNoCommission money,
		xQAC_Id int,
		xSVKey int,
		xQAC_TourLongMin smallint,
		xQAC_TourLongMax smallint
	)

	-- только проживание
	insert into @tableResult (xQAC_Id, xSCPId, xTRKey, xDateCheckIn, xSVKey, xQAC_TourLongMin, xQAC_TourLongMax)
	select xQAC_Id, SCP_ID, ADC_TLKey, SCP_DateCheckIn, ADC_SVKey, ADC_LongMin, ADC_LongMax
	from @tempQueueAddCosts join AddCosts with(nolock) on ADC_Id = xQAC_ADCId
	join TP_ServiceTours with(nolock) on ADC_TLKey = ST_TRKey and ST_SVKey = ADC_SVKey
	join TP_ServiceComponents with(nolock) on SC_ID = ST_SCId
	join TP_ServiceCalculateParametrs with(nolock) on SCP_SCID = SC_ID
	where 
	ADC_SVKey = 3
	and ADC_SVKey = SC_SVKey
	and (ADC_Code = 0 OR ADC_Code = SC_Code)
	and (ADC_SubCode1 = 0 OR SC_SubCode1 in (SELECT HR_Key FROM HotelRooms WHERE HR_RMKey=ADC_SubCode1))
	and (ADC_SubCode2 = 0 OR SC_SubCode1 in (SELECT HR_Key FROM HotelRooms WHERE HR_RCKey=ADC_SubCode2))
	and (ADC_PansionKey = 0 OR SC_SubCode2=ADC_PansionKey)
	and (ADC_PartnerKey = 0 OR ADC_PartnerKey=SC_PRKey)
	-- нам нужны только доплаты на будующие даты
	and SCP_DateCheckIn >= dateadd(day, 0, datediff(day, 0, getdate()))
	and SCP_DateCheckIn between ADC_CheckInDateBeg and ADC_CheckInDateEnd
	and (SCP_TourDays between case when isnull(ADC_LongMin, 0) = 0 then -100500 else ADC_LongMin end
		and case when isnull(ADC_LongMax, 0) = 0 then 100500 else ADC_LongMax end)
	
	
	print 'Заполнение временной таблицы доплатами на проживание: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	-- остальные услуги
	insert into @tableResult (xQAC_Id, xSCPId, xTRKey, xDateCheckIn, xSVKey, xQAC_TourLongMin, xQAC_TourLongMax)
	select xQAC_Id, SCP_ID, ADC_TLKey, SCP_DateCheckIn, ADC_SVKey, ADC_LongMin, ADC_LongMax
	from @tempQueueAddCosts join AddCosts with(nolock) on ADC_Id = xQAC_ADCId
	join TP_ServiceTours with(nolock) on ADC_TLKey = ST_TRKey and ST_SVKey = ADC_SVKey
	join TP_ServiceComponents with(nolock) on SC_ID = ST_SCId
	join TP_ServiceCalculateParametrs with(nolock) on SCP_SCID = SC_ID
	where 
	ADC_SVKey != 3
	and ADC_SVKey = SC_SVKey
	and (ADC_Code = 0 OR ADC_Code = SC_Code)
	and (ADC_SubCode1 = 0 OR ADC_SubCode1 = SC_SubCode1)
	and (ADC_SubCode2 = 0 OR ADC_SubCode2 = SC_SubCode2)
	and (ADC_PartnerKey = 0 OR ADC_PartnerKey = SC_PRKey)
	-- нам нужны только доплаты на будующие даты
	and SCP_DateCheckIn >= dateadd(day, 0, datediff(day, 0, getdate()))
	and SCP_DateCheckIn between ADC_CheckInDateBeg and ADC_CheckInDateEnd
	and (SCP_TourDays between case when isnull(ADC_LongMin, 0) = 0 then -100500 else ADC_LongMin end
		and case when isnull(ADC_LongMax, 0) = 0 then 100500 else ADC_LongMax end)
	
	print 'Заполнение временной таблицы доплатами на остальные услуги: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()

	declare @SCPId int, @nPacketkey int, @nSvkey int, @nCode int, @nSubcode1 int, @nSubcode2 int, @tourdateCheckIn datetime, @nServiceDays int, @nPrkey int, @men int, @nTourDays int;

	-- нам не нужны дублирующие строки в курсоре, чтобы не вызывать несколько раз один и тот же расчет наценки
	-- поэтому групируем строки по SCP_Id и xTOKey - уникальной паре для расчета
	declare cursorReCalculateAddCosts cursor fast_forward read_only for
	with distinctTableResult as
	(
		select xTRKey, xSCPId,
		case when isnull(xQAC_TourLongMin, 0) = 0 then null else xQAC_TourLongMin end as xQAC_TourLongMin, 
		case when isnull(xQAC_TourLongMax, 0) = 0 then null else xQAC_TourLongMax end as xQAC_TourLongMax
		from @tableResult
		group by xSCPId, xTRKey, xQAC_TourLongMin, xQAC_TourLongMax
	)
	select SCP_Id, xTRKey, SC_SVKey, SC_Code, SC_SubCode1, SC_SubCode2, SCP_DateCheckIn, SCP_Days, SC_PRKey, SCP_Men, SCP_TourDays
		from	distinctTableResult join TP_ServiceCalculateParametrs with(nolock) on xSCPId = SCP_Id
				join TP_ServiceComponents with(nolock) on SCP_SCId = SC_Id
		where	xTRKey is not null
				and isnull(SCP_TourDays, 0) between isnull(xQAC_TourLongMin, -32000) and isnull(xQAC_TourLongMax, 32000)
				and xSCPId in 
				(
					select SCPId_1 from TP_PriceComponents with(nolock) where SVKey_1 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_2 from TP_PriceComponents with(nolock) where SVKey_2 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_3 from TP_PriceComponents with(nolock) where SVKey_3 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_4 from TP_PriceComponents with(nolock) where SVKey_4 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_5 from TP_PriceComponents with(nolock) where SVKey_5 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_6 from TP_PriceComponents with(nolock) where SVKey_6 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_7 from TP_PriceComponents with(nolock) where SVKey_7 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_8 from TP_PriceComponents with(nolock) where SVKey_8 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_9 from TP_PriceComponents with(nolock) where SVKey_9 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_10 from TP_PriceComponents with(nolock) where SVKey_10 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_11 from TP_PriceComponents with(nolock) where SVKey_11 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_12 from TP_PriceComponents with(nolock) where SVKey_12 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_13 from TP_PriceComponents with(nolock) where SVKey_13 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_14 from TP_PriceComponents with(nolock) where SVKey_14 = SC_SVKey and PC_TRKey = xTRKey
					union
					select SCPId_15 from TP_PriceComponents with(nolock) where SVKey_15 = SC_SVKey and PC_TRKey = xTRKey
				)

	print 'Определение курсора: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()				
	declare @count int
	set @count = 0
	
	open cursorReCalculateAddCosts
	fetch next from cursorReCalculateAddCosts into @SCPId, @nPacketkey, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @tourdateCheckIn, @nServiceDays, @nPrkey, @men, @nTourDays
	while (@@FETCH_STATUS = 0)
	begin
		declare @addCostValueIsCommission money, @addCostValueNoCommission money, @addCostFromAdult money, @addCostFromChild money, @tourRate nvarchar(2)

		exec GetServiceAddCosts @nPacketkey, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @tourdateCheckIn,
			@nTourDays, @nServiceDays, @men, null, null, @addCostValueIsCommission output, @addCostValueNoCommission output, @addCostFromAdult output, @addCostFromChild output, @tourRate output

		update @tableResult 
			set xValueIsCommission = @addCostValueIsCommission,
				xValueNoCommission = @addCostValueNoCommission
		where xSCPId=@SCPId
		
		set @count = @count + 1
		
		fetch next from cursorReCalculateAddCosts into @SCPId, @nPacketkey, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @tourdateCheckIn, @nServiceDays, @nPrkey, @men, @nTourDays
	end
	close cursorReCalculateAddCosts
	deallocate cursorReCalculateAddCosts
	
	print 'Работа с курсором: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	print 'Обсчитано доплат: ' + convert(nvarchar(max), @count)
	
	declare @PriceComponentsRows int; set @PriceComponentsRows=0;
	
	/*переносим результат*/
	--	разобьем update по кортежам
	
	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_1 = xValueIsCommission,
		AddCostNoCommission_1 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_1 = xSCPId
	where SVKey_1 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_1, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_1, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
		
	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_2 = xValueIsCommission,
		AddCostNoCommission_2 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_2 = xSCPId
	where SVKey_2 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_2, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_2, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_3 = xValueIsCommission,
		AddCostNoCommission_3 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_3 = xSCPId
	where SVKey_3 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_3, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_3, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_4 = xValueIsCommission,
		AddCostNoCommission_4 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_4 = xSCPId
	where SVKey_4 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_4, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_4, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_5 = xValueIsCommission,
		AddCostNoCommission_5 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_5 = xSCPId
	where SVKey_5 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_5, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_5, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_6 = xValueIsCommission,
		AddCostNoCommission_6 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_6 = xSCPId
	where SVKey_6 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_6, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_6, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_7 = xValueIsCommission,
		AddCostNoCommission_7 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_7 = xSCPId
	where SVKey_7 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_7, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_7, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_8 = xValueIsCommission,
		AddCostNoCommission_8 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_8 = xSCPId
	where SVKey_8 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_8, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_8, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_9 = xValueIsCommission,
		AddCostNoCommission_9 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_9 = xSCPId
	where SVKey_9 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_9, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_9, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_10 = xValueIsCommission,
		AddCostNoCommission_10 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_10 = xSCPId
	where SVKey_10 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_10, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_10, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_11 = xValueIsCommission,
		AddCostNoCommission_11 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_11 = xSCPId
	where SVKey_11 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_11, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_11, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_12 = xValueIsCommission,
		AddCostNoCommission_12 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_12 = xSCPId
	where SVKey_12 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_12, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_12, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_13 = xValueIsCommission,
		AddCostNoCommission_13 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_13 = xSCPId
	where SVKey_13 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_13, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_13, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_14 = xValueIsCommission,
		AddCostNoCommission_14 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_14 = xSCPId
	where SVKey_14 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_14, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_14, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_15 = xValueIsCommission,
		AddCostNoCommission_15 = xValueNoCommission,
		PC_State = 1
	from TP_PriceComponents join @tableResult on SCPId_15 = xSCPId
	where SVKey_15 = xSvKey
	and PC_TRKey = xTRKey
	and (isnull(AddCostIsCommission_15, -100500) != isnull(xValueIsCommission, -100500)
		or isnull(AddCostNoCommission_15, -100500) != isnull(xValueNoCommission, -100500))
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	print 'Количество строк в TP_PriceComponents: ' + convert(nvarchar(max), @PriceComponentsRows)
	
	print 'Перенос результата в TP_PriceComponents: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	/*очистим очередь расчета*/
	delete TP_QueueAddCosts
	where QAC_Id in (select xQAC_Id from @tempQueueAddCosts)
	print 'Количество строк в TP_QueueAddCosts: ' + convert(nvarchar(max), @@rowcount)
	
	print 'Очистка очереди: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
END


GO


grant exec on [dbo].[ReCalculateAddCosts] to public
go

/*********************************************************************/
/* end sp_ReCalculateAddCosts.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_CheckActualPrice.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_CheckActualPrice]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_CheckActualPrice]
GO
CREATE PROCEDURE [dbo].[ReCalculate_CheckActualPrice]
	(
		-- хранимка проверяет на актуальность цены перерасчитывает их и возвращает их актальное состояние
		-- <version>2009.02.02</version>
		-- <data>2012-08-23</data>
		@tpKeys nvarchar(max)
	)
AS
BEGIN
	SET ARITHABORT ON;
	SET DATEFIRST 1;
	set nocount on;
	
	declare @beginTime datetime
	set @beginTime = getDate()
	
	-- таблица ключей
	declare @tpKeysTable table
	(
		xt_key bigint
	)
	
	insert into @tpKeysTable (xt_key)
	select xt_key from dbo.ParseKeys(@tpKeys)	
	
	print 'Парсинг ключей: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()

	-- таблица ключей
	declare @tempPriceComponents table
	(
		xPCId bigint,
		xTPKey bigint,
		xTRKey int,
		xTourDate datetime,
		xDays int,
		
		xSCPId1 bigint,
		xSCPId2 bigint,
		xSCPId3 bigint,
		xSCPId4 bigint,
		xSCPId5 bigint,
		xSCPId6 bigint,
		xSCPId7 bigint,
		xSCPId8 bigint,
		xSCPId9 bigint,
		xSCPId10 bigint,
		xSCPId11 bigint,
		xSCPId12 bigint,
		xSCPId13 bigint,
		xSCPId14 bigint,
		xSCPId15 bigint,
		
		xSvKey1 int,
		xSvKey2 int,
		xSvKey3 int,
		xSvKey4 int,
		xSvKey5 int,
		xSvKey6 int,
		xSvKey7 int,
		xSvKey8 int,
		xSvKey9 int,
		xSvKey10 int,
		xSvKey11 int,
		xSvKey12 int,
		xSvKey13 int,
		xSvKey14 int,
		xSvKey15 int
	)
	
	insert into @tempPriceComponents(xPCId, xTPKey, xTRKey, xTourDate, xDays, xSCPId1, xSCPId2, xSCPId3, xSCPId4, xSCPId5, xSCPId6, xSCPId7, xSCPId8, xSCPId9, xSCPId10, xSCPId11, xSCPId12, xSCPId13, xSCPId14, xSCPId15,
	xSvKey1, xSvKey2, xSvKey3, xSvKey4, xSvKey5, xSvKey6, xSvKey7, xSvKey8, xSvKey9, xSvKey10, xSvKey11, xSvKey12, xSvKey13, xSvKey14, xSvKey15)
	select PC_Id, PC_TPKey, PC_TRKey, PC_TourDate, PC_Days, SCPId_1, SCPId_2, SCPId_3, SCPId_4, SCPId_5, SCPId_6, SCPId_7, SCPId_8, SCPId_9, SCPId_10, SCPId_11, SCPId_12, SCPId_13, SCPId_14, SCPId_15,
	SVKey_1, SVKey_2, SVKey_3, SVKey_4, SVKey_5, SVKey_6, SVKey_7, SVKey_8, SVKey_9, SVKey_10, SVKey_11, SVKey_12, SVKey_13, SVKey_14, SVKey_15
	from TP_PriceComponents with(nolock)
	where PC_TPKey in (select xt_key from @tpKeysTable)
	
	print 'Заполнение вспомогательной таблицы @tempPriceComponents: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	-- Цены
	-- найдем ключи цен которые нам нужно перерасчитать
	declare @xSCPIdTable table
	(
		xSCPId bigint
	)
		
	insert into @xSCPIdTable(xSCPId)
	select SPAD_SCPId as xSCPId
	from @tempPriceComponents join TP_ServicePriceActualDate with(nolock) on 1 = 1
	where SPAD_SaleDate is null
	--and SPAD_NeedApply != 0
	and (
			(isnull(xSCPId1, -100500) = SPAD_SCPId) or
			(isnull(xSCPId2, -100500) = SPAD_SCPId) or
			(isnull(xSCPId3, -100500) = SPAD_SCPId) or
			(isnull(xSCPId4, -100500) = SPAD_SCPId) or
			(isnull(xSCPId5, -100500) = SPAD_SCPId) or
			(isnull(xSCPId6, -100500) = SPAD_SCPId) or
			(isnull(xSCPId7, -100500) = SPAD_SCPId) or
			(isnull(xSCPId8, -100500) = SPAD_SCPId) or
			(isnull(xSCPId9, -100500) = SPAD_SCPId) or
			(isnull(xSCPId10, -100500) = SPAD_SCPId) or
			(isnull(xSCPId11, -100500) = SPAD_SCPId) or
			(isnull(xSCPId12, -100500) = SPAD_SCPId) or
			(isnull(xSCPId13, -100500) = SPAD_SCPId) or
			(isnull(xSCPId14, -100500) = SPAD_SCPId)
	)
	
	print 'Поиск ключей цен которые изменились: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	-- если есть цены которые нужно обсчитать
	if exists(select top 1 1 from @xSCPIdTable)
	begin
		print 'Запускаем расчет цен'
		
		declare @keys nvarchar(max)
		set @keys = ''
		
		select @keys = @keys + convert(nvarchar(max), xSCPId) + ',' from @xSCPIdTable where xSCPId is not null
		
		-- запускаем перерасчет цен, передав в хранимку dbo.ReCalculateCosts список ключей
		exec dbo.ReCalculateCosts 100500, @keys
		-- запускаем перенос цен, передав в хранимку dbo.ReCalculateCosts_GrossMigrate список ключей
		exec dbo.ReCalculateCosts_GrossMigrate 100500, @keys
	end
	
	print 'Расчет изменившихся цен: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	-- Наценки
	-- найдем ключи наценок которые необходимо перерасчитать
	declare @xTMADIdTable table
	(
		xTMADId int
	)
	insert into @xTMADIdTable(xTMADId)
	select TMAD_Id
	from @tempPriceComponents join TP_TourMarginActualDate on xTRKey = TMAD_TRKey
	where  xTourDate = TMAD_DateCheckIn
	and xDays = TMAD_Long
	--and TMAD_NeedApply != 0
	and (	xSVKey1 = TMAD_SvKey
			or xSVKey2 = TMAD_SvKey
			or xSVKey3 = TMAD_SvKey
			or xSVKey4 = TMAD_SvKey
			or xSVKey5 = TMAD_SvKey
			or xSVKey6 = TMAD_SvKey
			or xSVKey7 = TMAD_SvKey
			or xSVKey8 = TMAD_SvKey
			or xSVKey9 = TMAD_SvKey
			or xSVKey10 = TMAD_SvKey
			or xSVKey11 = TMAD_SvKey
			or xSVKey12 = TMAD_SvKey
			or xSVKey13 = TMAD_SvKey
			or xSVKey14 = TMAD_SvKey
			or xSVKey15 = TMAD_SvKey			
		)
	
	print 'Поиск ключей наценок которые изменились: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
		
	
	if (exists (select top  1 1 from @xTMADIdTable))
	begin
		print 'Запускаем перерасчет наценок'
		
		declare @marginKeys nvarchar(max)
		set @marginKeys = ''
		
		select @marginKeys = @marginKeys + convert(nvarchar(max), xTMADId) + ',' from @xTMADIdTable where xTMADId is not null
		
		-- запускаем хранимку dbo.ReCalculateMargin передав ей ключи
		exec dbo.ReCalculateMargin 100500, @marginKeys
		-- запускаем хранимку dbo.ReCalculateCosts_MarginMigrate передав ей ключи
		exec dbo.ReCalculateCosts_MarginMigrate 100500, @marginKeys
	end
	
	print 'Расчет изменившихся наценок: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	-- Доплаты
	-- Найдем ключи доплат которые нам необходимо перерасчитать
	declare @xTRKeyTable table
	(
		xTRKey int
	)
	-- для проживания
	insert into @xTRKeyTable(xTRKey)
	select distinct xTRKey
	from @tempPriceComponents join AddCosts on xTRKey = ADC_TLKey
	where exists (select top 1 1 from TP_QueueAddCosts where QAC_ADCId = ADC_Id)
	and (
		ADC_SVKey = xSvKey1
		or ADC_SVKey = xSvKey2
		or ADC_SVKey = xSvKey3
		or ADC_SVKey = xSvKey4
		or ADC_SVKey = xSvKey5
		or ADC_SVKey = xSvKey6
		or ADC_SVKey = xSvKey7
		or ADC_SVKey = xSvKey8
		or ADC_SVKey = xSvKey9
		or ADC_SVKey = xSvKey10
		or ADC_SVKey = xSvKey11
		or ADC_SVKey = xSvKey12
		or ADC_SVKey = xSvKey13
		or ADC_SVKey = xSvKey14
		or ADC_SVKey = xSvKey15
	)
	-- нам нужны только доплаты на будующие даты
	and xTourDate > getdate()
	and xTourDate between ADC_CheckInDateBeg and ADC_CheckInDateEnd
	
	print 'Поиск ключей туров доплаты в которых изменились: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	if (exists (select top 1 1 from @xTRKeyTable))
	begin
		print 'Запускаем перерасчет доплат'
		
		declare @trKeys nvarchar(max)
		set @trKeys = ''
		
		select @trKeys = @trKeys + convert(nvarchar(max), xTRKey) + ',' from @xTRKeyTable where xTRKey is not null
		
		-- запускаем dbo.ReCalculateAddCosts, передав на вход ключи из очереди которые нужно перерасчитать
		--exec dbo.ReCalculateAddCosts 100500, @trKeys, null
		declare @tmp int
		select @tmp = dbo.WcfReCalculateAddCosts('net.tcp://tui-iis01.tui.local/MasterTourService/AddCostLogic.svc/UserName')
	end
	
	print 'Расчет изменившихся доплат: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	-- После перерасчета всех изменившихся цен, выводим актуальную информацию по ценам
	select PC_TPKey, PC_SummPrice
	from TP_PriceComponents with(nolock)
	where PC_TPKey in (select xt_key from @tpKeysTable)
	
	print 'Вывод результата: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
END
GO
grant exec on [dbo].[ReCalculate_CheckActualPrice] to public
go
/*********************************************************************/
/* end sp_ReCalculate_CheckActualPrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_CreateNextSaleDate.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_CreateNextSaleDate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_CreateNextSaleDate]
GO
CREATE PROCEDURE [dbo].[ReCalculate_CreateNextSaleDate]
	(
		-- хранимка создает новые цены в таблице TP_ServicePriceNextDays
		-- в зависимости от наступившей даты продаж у ценовых блоков
		@daysCount int -- количество дней наперед которые мы будем пересоздавать
	)
AS
BEGIN
	-- временная таблица что бы не делать 2 одинаковых запроса
	declare @tempCostOfferCrossSaleDate table
	(
		xCOId int,
		xCrossDate datetime,
		xSvKey int,
		xCode int,
		xSubCode1 int,
		xSubCode2 int,
		xPKKey int,
		xPRKey int
	)

	;with listCostOffers as 
	(
		--два одинаковых запроса для того что бы слить колонки CO_SaleDateBeg и CO_SaleDateEnd
		select CostOffers.CO_Id, dateadd(day, 0, datediff(day, 0, CO_SaleDateBeg)) as crossDate, COS_SVKEY, COS_CODE, CS_SUBCODE1, CS_SUBCODE2, CS_PKKEY, CS_PRKEY
		from CostOffers with(nolock) join Seasons with(nolock) on CO_SeasonId = SN_Id
		join CostOfferServices with(nolock) on COS_COID = CO_Id
		join tbl_Costs with(nolock) on CS_COID = CO_Id
		where SN_IsActive = 1
		and isnull(CO_SaleDateBeg, '2000-01-01') between getdate() and dateadd(dd, @daysCount, getdate())
		-- ЦБ должен быть активен
		and CO_State = 1
		-- и опубликован
		and CO_DateLastPublish is not null
		group by CostOffers.CO_Id, CO_SaleDateBeg, CO_PKKey, COS_SVKEY, COS_CODE, CS_SUBCODE1, CS_SUBCODE2, CS_PKKEY, CS_PRKEY
		union
		select CostOffers.CO_Id, dateadd(day, 1, datediff(day, 0, CO_SaleDateEnd)) as crossDate, COS_SVKEY, COS_CODE, CS_SUBCODE1, CS_SUBCODE2, CS_PKKEY, CS_PRKEY
		from CostOffers with(nolock) join Seasons with(nolock) on CO_SeasonId = SN_Id
		join CostOfferServices with(nolock) on COS_COID = CO_Id
		join tbl_Costs with(nolock) on CS_COID = CO_Id
		where SN_IsActive = 1
		and isnull(CO_SaleDateEnd, '2000-01-01') between getdate() and dateadd(dd, @daysCount, getdate())
		-- ЦБ должен быть активен
		and CO_State = 1
		-- и опубликован
		and CO_DateLastPublish is not null
		group by CostOffers.CO_Id, CO_SaleDateEnd, CO_PKKey, COS_SVKEY, COS_CODE, CS_SUBCODE1, CS_SUBCODE2, CS_PKKEY, CS_PRKEY
	)

	-- переносим только те костоферы которые на эту дату еще не были перенесены
	insert into @tempCostOfferCrossSaleDate (xCOId, xCrossDate, xSvKey, xCode, xSubCode1, xSubCode2, xPKKey, xPRKey)
	select CO_Id, crossDate, COS_SVKEY, COS_CODE, CS_SUBCODE1, CS_SUBCODE2, CS_PKKEY, CS_PRKEY
	from listCostOffers
	where not exists (	select top 1 1
						from CostOfferCrossSaleDate with(nolock)
						where CSD_COId = CO_Id
						and CSD_CrossDate = crossDate
						and CSD_SvKey = COS_SVKEY
						and CSD_Code = COS_CODE
						and CSD_SubCode1 = CS_SUBCODE1
						and CSD_SubCode2 = CS_SUBCODE2
						and CSD_PKKey = CS_PKKEY
						and CSD_PRKey = CS_PRKEY)


	-- переносим цены в TP_ServicePriceNextDate
	insert into TP_ServicePriceNextDate (SPND_SCPId, SPND_IsCommission, SPND_Rate, SPND_SaleDate, SPND_Gross, SPND_Netto, SPND_DateLastChange, SPND_DateLastCalculate, SPND_NeedApply)
	select SPAD_SCPId, SPAD_IsCommission, SPAD_Rate, xCrossDate, null, null, getdate(), null, 1
	from TP_ServiceComponents with(nolock) join TP_ServiceCalculateParametrs with(nolock) on SC_Id = SCP_SCId
	join TP_ServicePriceActualDate with(nolock) on SCP_Id = SPAD_SCPId and SPAD_SaleDate is null
	join @tempCostOfferCrossSaleDate on SC_SVKey = xSvKey 
										and SC_Code = xCode 
										and SC_SubCode1 = xSubCode1 
										and SC_SubCode2 = xSubCode2
										and SC_PRKey = xPRKey
										and SCP_PKKey = xPKKey
	where not exists (	select top 1 1
						from TP_ServicePriceNextDate with(nolock)
						where SPND_SCPId = SPAD_SCPId
						and SPND_SaleDate = xCrossDate
						and SPND_Rate = SPAD_Rate)
	-- нам нужны только из туров с будующей датой заезда
	and SCP_DateCheckIn >= getdate()

	-- записываем костоферы которые уже перенесли
	insert into CostOfferCrossSaleDate (CSD_COId, CSD_CrossDate, CSD_SvKey, CSD_Code, CSD_SubCode1, CSD_SubCode2, CSD_PKKey, CSD_PRKey)
	select xCOId, xCrossDate, xSvKey, xCode, xSubCode1, xSubCode2, xPKKey, xPRKey
	from @tempCostOfferCrossSaleDate
END

GO

grant exec on [dbo].[ReCalculate_CreateNextSaleDate] to public
go

/*********************************************************************/
/* end sp_ReCalculate_CreateNextSaleDate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_MigrateToPrice.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ReCalculate_MigrateToPrice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[ReCalculate_MigrateToPrice]
GO

CREATE PROCEDURE [dbo].[ReCalculate_MigrateToPrice]	
	(
		-- хранимка суммирует стоимость отдельных услуг и кладет их в TP_Prices		
		--<version>2009.2.08</version>
		--<data>2012-10-19</data>
		-- максимальное количество записей для переноса за 1 раз
		@countItem int
	)
AS
BEGIN
	SET ARITHABORT ON;

	declare @tempGrossTable table
	(
		xPCId int,
		xTPKey int,
		xSummPrice money,
		xSummPriceOld money,
		xToKey int
	)
	
	declare @numRowsInserted int, @numRowsUpdated int, @numRowsDeleted int
	set @numRowsInserted = 0
	set @numRowsUpdated = 0
	set @numRowsDeleted = 0

	-- тут with(nolock) не нужен, иначе в темповую таблицу могут попасть еще не пересчитанные данные
	insert into @tempGrossTable (xPCId, xTPKey, xSummPrice, xToKey)
	select top (@countItem) PC_Id, PC_TPKey, PC_SummPrice, PC_ToKey
	from TP_PriceComponents
	where PC_State = 1
	
	print 'Количество строк в TP_PriceComponents: ' + convert(nvarchar(max), @@rowcount)
	
	declare currReCalculate_MigrateToPrice cursor for select distinct xToKey from @tempGrossTable
	declare @toKey int
	OPEN currReCalculate_MigrateToPrice
		FETCH NEXT FROM currReCalculate_MigrateToPrice INTO @toKey
		WHILE @@FETCH_STATUS = 0
		begin
			
			insert into CalculatingPriceLists (CP_CreateDate,CP_PriceTourKey) values (GETDATE(),@toKey) 
			declare @cpKey int
			set @cpKey = scope_identity()
			
			-- переносим цены в таблицу для удаленных цен
			insert into tp_pricesdeleted (TPD_TPKey, TPD_TOKey, TPD_TIKey, TPD_Gross, TPD_DateBegin, TPD_DateEnd, TPD_CalculatingKey)
			select TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, @cpKey 
			from tp_prices with(nolock)
			where tp_key in (	select xTPKey 
								from @tempgrosstable 
								where xSummPrice is null
								and xToKey = @toKey)
								
			-- удаляем цены из tp_prices
			delete from tp_prices
			where tp_key in (select xTPKey
								from @tempgrosstable
								where xSummPrice is null
								and xToKey = @toKey)
			set @numRowsDeleted = @@ROWCOUNT
			
			--восстанавливаем цены из таблицы удаленных цен
			insert into tp_prices (TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, TP_CalculatingKey)
			select TPD_TPKey, TPD_TOKey, TPD_TIKey, TPD_Gross, TPD_DateBegin, TPD_DateEnd, @cpKey
			from tp_pricesdeleted with(nolock)
			where tpd_tpkey in (select xTPKey
								from @tempgrosstable
								where xSummPrice is not null
								and xToKey = @toKey)
			set @numRowsInserted = @@ROWCOUNT
								
			-- и удаляем из из таблицы удаленных цен
			delete from tp_pricesdeleted
			where tpd_tpkey in (select xTPKey
								from @tempgrosstable
								where xSummPrice is not null
								and xToKey = @toKey)
								
			-- обновляем цены, которые ранее не были удалены и изменились, или ранее были удалены но сейчас востановились
			update TP_Prices
			set TP_Gross = CEILING(xSummPrice),
			tp_updatedate = GetDate(),
			TP_CalculatingKey = @cpKey
			from TP_Prices join @tempGrossTable on TP_Key = xTPKey
			where xSummPrice is not null
			and xToKey = @toKey
			
			set @numRowsUpdated = @@ROWCOUNT
			
			if exists (select top 1 1 from TP_Tours where to_Key = @toKey and to_isEnabled = 1)
			begin
				-- Реплицируем только если тур уже выставлен в online
				if (@numRowsInserted > 0 or @numRowsDeleted > 0)
				begin
					exec FillMasterWebSearchFields @toKey, @cpKey
				end
				else if (@numRowsUpdated > 0)
				begin
					if dbo.mwReplIsPublisher() > 0
					begin
						insert into mwReplTours(rt_trkey, rt_tokey, rt_date, rt_calckey, rt_updateOnlinePrices)
						select TO_TRKey, TO_Key, GETDATE(), @cpKey, 1
						from tp_tours
						where TO_Key = @toKey
					end
					else
					begin
						exec mwReplUpdatePriceEnabledAndValue @toKey, @cpKey
					end
				end
			end
		
		FETCH NEXT FROM currReCalculate_MigrateToPrice INTO @toKey
		end

	CLOSE currReCalculate_MigrateToPrice
	DEALLOCATE currReCalculate_MigrateToPrice
	
	-- отметим что уже перенесли
	update TP_PriceComponents
	set PC_DateLastUpdateToPrice = getdate(),
	PC_State = 0
	where PC_Id in (select xPCId from @tempGrossTable)
END
GO

GRANT EXEC ON [dbo].[ReCalculate_MigrateToPrice] TO PUBLIC
GO

/*********************************************************************/
/* end sp_ReCalculate_MigrateToPrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_ViewHottelCost.sql */
/*********************************************************************/
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_ViewHotelCost]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_ViewHotelCost]
GO
CREATE PROCEDURE [dbo].[ReCalculate_ViewHotelCost]
(
	--хранимка выводит информацию о ценах на отель по набору заданных параметров, либо по ключам цен
	--<version>2009.2.08</version>
	--<data>2013-01-09</data>
	@departureKey int,										-- ключ города вылета
	@tourKey int = null,									-- ключ тура
	@hotelKeys xml ([dbo].[ArrayOfInt]) = null,				-- ключ отеля
	@checkinDateBegin datetime = null,						-- дата начала заезда
	@checkinDateEnd datetime = null,						-- дата начала заезда
	@roomKeys xml ([dbo].[ArrayOfInt]) = null,				-- ключ типа комнаты
	@roomCategoryKeys xml ([dbo].[ArrayOfInt]) = null,		-- ключ категории номера
	@accommodationKeys xml ([dbo].[ArrayOfInt]) = null,		-- ключ размещения
	@pansionKeys xml ([dbo].[ArrayOfInt]) = null,			-- ключ питания
	@longList xml ([dbo].[ArrayOfShort]) = null,			-- продолжительности
	@weekDays nvarchar(7) = null,							-- дни недели
	@agentCommission money = null,							-- процент агентской коммисии
	@IsChangePriceOnly bit = null,							-- только с измененными ценами
	@IsDeletePriceOnly bit = null,							-- только с удаленными ценами
	@isHideAccommodationWithAdult bit = null,				-- только размещения без доп. мест
	@IsOnlineOnly bit = null,								-- только выставленные в интернет туры
	@priceKeys xml ([dbo].[ArrayOfLong]) = null,			-- ключи цен, передаваемые из плагина MarginMonitor
	@IsWholeHotel bit = 1                                   -- 1 - поиск по всему отелю, 0 - по категориям номеров
)
AS
BEGIN
	declare @beginTime datetime
	declare @tpKeys nvarchar(max)

	declare @hotelRoomsTable table
	(
		SC_Id int,
		SC_Code int,
		SC_SubCode1 int,
		SC_SubCode2 int,
		SC_PRKey int,
		HR_RMKEY int,
		HR_ACKEY int,
		HR_RCKEY int
	)

	if (@priceKeys is not null)
	begin
	    SET ARITHABORT OFF;
		SET DATEFIRST 1;
		set nocount on;

		declare @tablePriceKeysTable table (xPriceKey bigint)
		insert into @tablePriceKeysTable(xPriceKey)
		select tbl.res.value('.', 'bigint') 
		from @priceKeys.nodes('/ArrayOfLong/long') as tbl(res)
		
		set @beginTime = getdate()
		-- актуализируем цены по отобранным турам
		set @tpKeys = ''
		select @tpKeys = @tpKeys + convert(nvarchar(max), PC_TPKey) + ', '
		from TP_PriceComponents WITH(NOLOCK)
		where PC_Id in (select xPriceKey from @tablePriceKeysTable)
		declare @tmp table(tpKey bigint, newPrice money)
		-- делаем инсерт во веременную таблицу, что бы результата не выводился при запуске этой хранимки
		insert into @tmp (tpKey, newPrice)
		exec ReCalculate_CheckActualPrice @tpKeys
		print 'exec ReCalculate_CheckActualPrice ' + '''' +  @tpKeys + ''''
		print 'Расчитываем изменения в ценах: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))

		insert into @hotelRoomsTable(SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY)
		select distinct SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY
		from tp_serviceComponents with(nolock)
		inner join hotelRooms with(nolock) on SC_SubCode1 = HR_KEY
		inner join tp_serviceCalculateParametrs with(nolock) on sc_id=scp_scid
		where tp_serviceCalculateParametrs.scp_id in
		(
			select scpid_1  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_2  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_3  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_4  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_5  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_6  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_7  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_8  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_9  as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_10 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_11 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_12 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_13 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_14 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_15 as scpid from tp_priceComponents with(nolock) where pc_id in (select xPriceKey from @tablePriceKeysTable)
		)
		
		-- таблица с перелетами
		declare @chartersTable table
		(
			xIsForward bit,    -- 1-прямой перелет    0-обратный
			xTS_TIKey bigint,
			xCH_Key bigint,
			xTS_SubCode1 bigint,
			xTS_PKKey bigint,
			xTS_CityKeyFrom bigint,
			xTS_CityKeyTo bigint,
			xCharterDate datetime,
			xCH_PortCodeFrom varchar(4)
		)
		
		-- берем прямые и обратные перелеты
		insert into @chartersTable
		(xIsForward, xTS_TIKey, xCH_Key, xTS_SubCode1, xTS_PKKey, xTS_CityKeyFrom, xTS_CityKeyTo, xCharterDate, xCH_PortCodeFrom)
		select distinct
			case TS_Day when 1 then 1 else 0 end,
			PC_TIKey, TS_Code, TS_SubCode1, TS_OpPacketKey, TS_SubCode2, TS_CTKey,
			case TS_Day when 1 then PC_TourDate else PC_TourDate + PC_Days - 1 end,
			CH_PORTCODEFROM
		from TP_PriceComponents with(nolock)
		join TP_ServiceLists sl with(nolock) on sl.TL_TIKey = PC_TIKey
		join TP_Services cs with(nolock) on sl.TL_TSKey = cs.TS_Key and cs.TS_SVKey = 1
		join Charter ch with(nolock) on ch.CH_KEY = TS_Code
		where
		    (PC_Id in (select xPriceKey from @tablePriceKeysTable)) and
		    (TS_SVKey = 1) and ((TS_Day = 1) or (TS_Day = PC_Days))  -- перелеты на первый или последний день
		
		-- подбор подходящих перелетов
        --select * from @chartersTable
		declare @addChartersTable table  -- таблица с дополнительными перелетами
		(
			xCHKey bigint,
			xAddChKey bigint,
			xAddFlight varchar(4),
			xAddAirlineCode varchar(3),
			xCharterDate datetime,
			xTS_SubCode1 bigint,
			xTS_PKKey bigint,
			xOrder int default 1,
			xAS_Week varchar(7),
			xAS_TimeFrom datetime
		)
		
		insert into @addChartersTable(xCHKey, xAddChKey, xAddFlight, xAddAirlineCode, xCharterDate, xTS_SubCode1, xTS_PKKey, xAS_Week, xAS_TimeFrom)
		select distinct xCH_Key, CH_Key, CH_FLIGHT, CH_AIRLINECODE, xCharterDate, xTS_SubCode1, xTS_PKKey, AS_WEEK, AS_TimeFrom
		from AirSeason with(nolock), Charter with(nolock), Costs with(nolock), @chartersTable
		where
			CH_CityKeyFrom = xTS_CityKeyFrom and
			CH_CityKeyTo = xTS_CityKeyTo and
			CS_Code = CH_Key and
			AS_CHKey = CH_Key and
			CS_SVKey = 1 and
			(	isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = CS_SubCode1), '')
				= 
				isnull((select top 1 AS_GROUP from AirService with(nolock) where AS_KEY = xTS_SubCode1), '')
			) and
			CS_PKKey = xTS_PKKey and
			xCharterDate between AS_DateFrom and AS_DateTo and
			xCharterDate between CS_Date and CS_DateEnd and
			AS_Week LIKE '%'+cast(datepart(weekday, xCharterDate)as varchar(1))+'%' and
			(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, xCharterDate)as varchar(1))+'%')
			
		-- для сортировки рейсов
		update @addChartersTable
		set xOrder = 0             -- чтобы рейс тура был первым
		where xCHKey = xAddChKey

        --select * from @addChartersTable

		declare @addChartersTableString table
		(
			xCHKey bigint,                 -- исходный перелет
			xAddChKeyString varchar(5000), -- список доп. перелетов через запятую (включая исходный)
			xCharterDate datetime,
			xTS_SubCode1 bigint,
			xTS_PKKey bigint,
			xAS_Week varchar(7),
			xAS_TimeFrom varchar(5000)
		)

		-- все доп. перелеты соединяем через запятую в одну строку
		insert into @addChartersTableString(xCHKey, xCharterDate, xTS_SubCode1, xTS_PKKey, xAS_Week, xAddChKeyString, xAS_TimeFrom)
		select distinct t1.xCHKey, t1.xCharterDate, t1.xTS_SubCode1, t1.xTS_PKKey,
			-- xAS_Week
			(select top 1 xAS_Week
			from @addChartersTable t2
			where (t2.xCHKey = t1.xCHKey) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
			order by len(xAS_Week) - len(replace(xAS_Week, '.', '')) desc),
		 	-- xAS_TimeFrom
			(select xAddAirlineCode + xAddFlight + ', '
		    from @addChartersTable t2
		    where (t2.xCHKey = t1.xCHKey) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
		    order by xOrder asc, xAddAirlineCode + xAddFlight asc
		    for xml path('')),
		    -- xAddAirlineCode + xAddFlight
		    (select SUBSTRING(CONVERT(VARCHAR(8), xAS_TimeFrom, 108),0,6) + ', '
		    from @addChartersTable t2
		    where (t2.xCHKey = t1.xCHKey) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
		    order by xOrder asc, xAddAirlineCode + xAddFlight asc
		    for xml path(''))
		from @addChartersTable t1
		
		-- избавляемся от хвостовых запятых
		update @addChartersTableString
		set xAddChKeyString = LEFT(xAddChKeyString, LEN(xAddChKeyString) - 1),
		    xAS_TimeFrom = LEFT(xAS_TimeFrom, LEN(xAS_TimeFrom) - 1)

        --select * from @addChartersTableString
        
		SET ANSI_WARNINGS OFF;
		select distinct PC_Id, PC_TPKey, PC_TourDate, SCP_Date, SC_Code, SC_SubCode1, HR_RMKEY, HR_ACKEY, HR_RCKEY, SC_SubCode2, SC_PRKey,
		PC_Days, SCP_Days, SCP_Men, PC_TOKey, PC_SummPrice, TO_TRKey, TO_Name, TO_Rate, TO_IsEnabled,
		AddCostIsCommission_1,  AddCostNoCommission_1,  CommissionOnly_1,  Gross_1,  IsCommission_1,  MarginPercent_1,  SCPId_1,  SVKey_1,
		AddCostIsCommission_2,  AddCostNoCommission_2,  CommissionOnly_2,  Gross_2,  IsCommission_2,  MarginPercent_2,  SCPId_2,  SVKey_2,
		AddCostIsCommission_3,  AddCostNoCommission_3,  CommissionOnly_3,  Gross_3,  IsCommission_3,  MarginPercent_3,  SCPId_3,  SVKey_3,
		AddCostIsCommission_4,  AddCostNoCommission_4,  CommissionOnly_4,  Gross_4,  IsCommission_4,  MarginPercent_4,  SCPId_4,  SVKey_4,
		AddCostIsCommission_5,  AddCostNoCommission_5,  CommissionOnly_5,  Gross_5,  IsCommission_5,  MarginPercent_5,  SCPId_5,  SVKey_5,
		AddCostIsCommission_6,  AddCostNoCommission_6,  CommissionOnly_6,  Gross_6,  IsCommission_6,  MarginPercent_6,  SCPId_6,  SVKey_6,
		AddCostIsCommission_7,  AddCostNoCommission_7,  CommissionOnly_7,  Gross_7,  IsCommission_7,  MarginPercent_7,  SCPId_7,  SVKey_7,
		AddCostIsCommission_8,  AddCostNoCommission_8,  CommissionOnly_8,  Gross_8,  IsCommission_8,  MarginPercent_8,  SCPId_8,  SVKey_8,
		AddCostIsCommission_9,  AddCostNoCommission_9,  CommissionOnly_9,  Gross_9,  IsCommission_9,  MarginPercent_9,  SCPId_9,  SVKey_9,
		AddCostIsCommission_10, AddCostNoCommission_10, CommissionOnly_10, Gross_10, IsCommission_10, MarginPercent_10, SCPId_10, SVKey_10,
		AddCostIsCommission_11, AddCostNoCommission_11, CommissionOnly_11, Gross_11, IsCommission_11, MarginPercent_11, SCPId_11, SVKey_11,
		AddCostIsCommission_12, AddCostNoCommission_12, CommissionOnly_12, Gross_12, IsCommission_12, MarginPercent_12, SCPId_12, SVKey_12,
		AddCostIsCommission_13, AddCostNoCommission_13, CommissionOnly_13, Gross_13, IsCommission_13, MarginPercent_13, SCPId_13, SVKey_13,
		AddCostIsCommission_14, AddCostNoCommission_14, CommissionOnly_14, Gross_14, IsCommission_14, MarginPercent_14, SCPId_14, SVKey_14,
		AddCostIsCommission_15, AddCostNoCommission_15, CommissionOnly_15, Gross_15, IsCommission_15, MarginPercent_15, SCPId_15, SVKey_15,
		-- PortFrom
		xCH_PORTCODEFROM as CH_PORTCODEFROM,
		-- Flight
		(select top 1 act.xAddChKeyString from @addChartersTableString act
		where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1))
		as CH_FLIGHT,
		-- Week
		(select top 1 act.xAS_Week from @addChartersTableString act
		where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1))
		as AS_WEEK,
        -- TimeFrom
        (select top 1 act.xAS_TimeFrom from @addChartersTableString act
		where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1))
		as AS_TIMEFROM,
		-- SeatsFree
		(select sum(qp.QP_Places - qp.QP_Busy)
		from QuotaDetails qd with(nolock)
		join QuotaParts qp with(nolock) on qp.QP_QDID = qd.QD_ID
		join QuotaObjects qo with(nolock) on qo.QO_QTID = qd.QD_QTID
		where (qo.QO_SVKey = 1) and (qo.QO_SubCode1 = xTS_SubCode1) and (qd.QD_Date = PC_TourDate) and (isnull(qp.QP_IsDeleted,0) = 0) and (isnull(qp.QP_AgentKey,0) = 0) and
			   qo.QO_Code in (select act.xAddChKey from @addChartersTable act
			                  where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1)))
		as SeatsFree,
		-- Cax
		(select sum(qp.QP_Places)
		from QuotaDetails qd with(nolock)
		join QuotaParts qp with(nolock) on qp.QP_QDID = qd.QD_ID
		join QuotaObjects qo with(nolock) on qo.QO_QTID = qd.QD_QTID
		where (qo.QO_SVKey = 1) and (qo.QO_SubCode1 = xTS_SubCode1) and (qd.QD_Date = PC_TourDate) and (isnull(qp.QP_IsDeleted,0) = 0) and (isnull(qp.QP_AgentKey,0) = 0) and
			   qo.QO_Code in (select act.xAddChKey from @addChartersTable act
			                  where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1)))
		as Cax,
		-- SeatsFreeBackCharters
		(select sum(qp.QP_Places - qp.QP_Busy)
		from QuotaDetails qd with(nolock)
		join QuotaParts qp with(nolock) on qp.QP_QDID = qd.QD_ID
		join QuotaObjects qo with(nolock) on qo.QO_QTID = qd.QD_QTID
		where (qo.QO_SVKey = 1) and (qo.QO_SubCode1 = xTS_SubCode1) and (qd.QD_Date = PC_TourDate + PC_Days - 1) and (isnull(qp.QP_IsDeleted,0) = 0) and (isnull(qp.QP_AgentKey,0) = 0) and
			   qo.QO_Code in (select act.xAddChKey from @addChartersTable act
			                  where (act.xCharterDate = PC_TourDate + PC_Days - 1) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1) and
			                        (act.xCHKey = (select top 1 xCH_Key from @chartersTable
			                                       where xTS_TIKey = PC_TIKey and xIsForward = 0 and xCharterDate = PC_TourDate + PC_Days - 1))))
		as SeatsFreeBackCharters,
		-- RoomsAll
		dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 1, PC_TourDate, hs.TS_Code, NULL, PC_Days, HR_RCKEY)
		as RoomsAll,
		-- RoomsSold
		dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 0, PC_TourDate, hs.TS_Code, NULL, PC_Days, HR_RCKEY)
		as RoomsSold,
		-- Commitment Rooms
		dbo.GetHotelPlaces (ISNULL(@IsWholeHotel,0), 1, PC_TourDate, hs.TS_Code, 2, PC_Days, HR_RCKEY)
		as CommitmentRooms,
		-- StopSale
		(SELECT TOP 1 'S' FROM StopSales ss with(nolock)
 	     INNER JOIN QuotaObjects qo with(nolock) ON qo.QO_ID = ss.SS_QOID
 	     WHERE
 	       ISNULL(ss.SS_IsDeleted, 0) = 0
 	       AND ss.SS_Date BETWEEN (PC_TourDate + hs.TS_Day - 1) AND (PC_TourDate + hs.TS_Day - 1 + hs.TS_Days - 1)
		   AND qo.QO_SVKey = 3
		   AND qo.QO_Code = SC_Code
		   AND (qo.QO_SubCode1 = HR_RMKEY OR qo.QO_SubCode1 = 0)
		   AND (qo.QO_SubCode2 = HR_RCKEY OR qo.QO_SubCode2 = 0))
		as StopSale
		from TP_PriceComponents with(nolock)
		join TP_Tours with(nolock) on TO_Key = PC_TOKey
		join TP_ServiceCalculateParametrs with(nolock) on SCPId_1 = SCP_Id
		join @hotelRoomsTable on SCP_SCId = SC_Id
		join TP_ServiceLists sl with(nolock) on sl.TL_TIKey = PC_TIKey
		join TP_Services hs with(nolock) on sl.TL_TSKey = hs.TS_Key and hs.TS_SVKey = 3 and hs.TS_Code = SC_Code
		left join @chartersTable on xTS_TIKey = PC_TIKey
		where
			PC_Id in (select xPriceKey from @tablePriceKeysTable) and
			(xIsForward is null or xIsForward = 1 and xCharterDate = PC_TourDate) and
			-- чтобы при обновлении грида (например после снятия цены) выставленные/невыставленные цены корректно обрабатывались, в зависимости от значения фильтра
			(@IsOnlineOnly is null or (@IsOnlineOnly = case when PC_SummPrice is null then 0 else TO_IsEnabled end))
	end
	else
	begin
		SET ARITHABORT ON;
		SET DATEFIRST 1;
		set nocount on;
		
		set @beginTime = getDate()

		declare @hotelService int, @aviaService int
		set @hotelService = 3
		set @aviaService = 1
		
		declare @tableHotelKeys table
		(
			xHotelKey int
		)	
		insert into @tableHotelKeys(xHotelKey)
		select tbl.res.value('.', 'int') 
		from @hotelKeys.nodes('/ArrayOfInt/int') as tbl(res)
		
		print 'Парсинг @hotelKeys: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		declare @tableLongList table
		(
			xLong int
		)
		insert into @tableLongList(xLong)
		select tbl.res.value('.', 'smallint') 
		from @longList.nodes('/ArrayOfShort/short') as tbl(res);
		
		print 'Парсинг @longList: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		set @tpKeys = ''
		
		select @tpKeys = @tpKeys + convert(nvarchar(max), PC_TPKey) + ', '
		from TP_PriceComponents with(nolock)
		where PC_TOKey = isnull(@tourKey, PC_TOKey)
		and PC_HotelKey in (select xHotelKey from @tableHotelKeys)
		and PC_DepartureKey = isnull(@departureKey, 0)
		and PC_TourDate between isnull(@checkinDateBegin, PC_TourDate) and isnull(@checkinDateEnd, PC_TourDate)
		and (@weekDays is null or (@weekDays like '%' + convert(nvarchar(1), datepart(dw, PC_TourDate)) + '%'))
		and (@longList is null or (PC_Days in (select xLong from @tableLongList)))
		group by PC_TPKey
		
		print 'Определяем ключи @tpKeys: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
				
		-- проверяем актуальность цен
		declare @result table
		(
			tpKey bigint,
			newPrice money
		)
		-- делаем инсерт во веременную таблицу, что бы результата не выводился при запуске этой хранимки
		insert into @result (tpKey, newPrice)
		exec ReCalculate_CheckActualPrice @tpKeys
		print 'exec ReCalculate_CheckActualPrice ' + '''' +  @tpKeys + ''''
		
		print 'Расчитываем изменения в ценах: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		insert into @hotelRoomsTable(SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY)
		select SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY
		from HotelRooms join TP_ServiceComponents on SC_SubCode1 = HR_KEY
		where 
			SC_Code in (select xHotelKey from @tableHotelKeys)
		and (@pansionKeys is null or (SC_SubCode2 in	(select tbl.res.value('.', 'int') from @pansionKeys.nodes('/ArrayOfInt/int') as tbl(res))))
		and (isnull(@isHideAccommodationWithAdult, 0) = 0 or (HR_ACKEY in (select AC_KEY from Accmdmentype where (isnull(AC_NADMAIN, 0) > 0) and (isnull(AC_NCHMAIN, 0) = 0) and (isnull(AC_NCHISINFMAIN, 0) = 0))))
		
		print 'Заполнение вспомогательной таблицы: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		delete @hotelRoomsTable
		where 
			(@roomKeys is not null and (HR_RMKEY not in (select tbl.res.value('.', 'int') from @roomKeys.nodes('/ArrayOfInt/int') as tbl(res))))
		or (@roomCategoryKeys is not null and (HR_RCKEY not in	(select tbl.res.value('.', 'int') from @roomCategoryKeys.nodes('/ArrayOfInt/int') as tbl(res))))
		or (@accommodationKeys is not null and (HR_ACKEY not in (select tbl.res.value('.', 'int') from @accommodationKeys.nodes('/ArrayOfInt/int') as tbl(res))))
		
		print 'Очистка вспомогательной таблицы: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		select PC_Id, PC_TPKey, PC_TourDate, SCP_Date, SC_Code, SC_SubCode1, HR_RMKEY, HR_ACKEY, HR_RCKEY, SC_SubCode2, SC_PRKey, PC_Days, SCP_Days, SCP_Men, PC_TOKey, PC_SummPrice, TO_TRKey, TO_Name, TO_Rate, TO_IsEnabled,
		AddCostIsCommission_1, AddCostNoCommission_1, CommissionOnly_1, Gross_1, IsCommission_1, MarginPercent_1, SCPId_1, SVKey_1,
		AddCostIsCommission_2, AddCostNoCommission_2, CommissionOnly_2, Gross_2, IsCommission_2, MarginPercent_2, SCPId_2, SVKey_2,
		AddCostIsCommission_3, AddCostNoCommission_3, CommissionOnly_3, Gross_3, IsCommission_3, MarginPercent_3, SCPId_3, SVKey_3,
		AddCostIsCommission_4, AddCostNoCommission_4, CommissionOnly_4, Gross_4, IsCommission_4, MarginPercent_4, SCPId_4, SVKey_4,
		AddCostIsCommission_5, AddCostNoCommission_5, CommissionOnly_5, Gross_5, IsCommission_5, MarginPercent_5, SCPId_5, SVKey_5,
		AddCostIsCommission_6, AddCostNoCommission_6, CommissionOnly_6, Gross_6, IsCommission_6, MarginPercent_6, SCPId_6, SVKey_6,
		AddCostIsCommission_7, AddCostNoCommission_7, CommissionOnly_7, Gross_7, IsCommission_7, MarginPercent_7, SCPId_7, SVKey_7,
		AddCostIsCommission_8, AddCostNoCommission_8, CommissionOnly_8, Gross_8, IsCommission_8, MarginPercent_8, SCPId_8, SVKey_8,
		AddCostIsCommission_9, AddCostNoCommission_9, CommissionOnly_9, Gross_9, IsCommission_9, MarginPercent_9, SCPId_9, SVKey_9,
		AddCostIsCommission_10, AddCostNoCommission_10, CommissionOnly_10, Gross_10, IsCommission_10, MarginPercent_10, SCPId_10, SVKey_10,
		AddCostIsCommission_11, AddCostNoCommission_11, CommissionOnly_11, Gross_11, IsCommission_11, MarginPercent_11, SCPId_11, SVKey_11,
		AddCostIsCommission_12, AddCostNoCommission_12, CommissionOnly_12, Gross_12, IsCommission_12, MarginPercent_12, SCPId_12, SVKey_12,
		AddCostIsCommission_13, AddCostNoCommission_13, CommissionOnly_13, Gross_13, IsCommission_13, MarginPercent_13, SCPId_13, SVKey_13,
		AddCostIsCommission_14, AddCostNoCommission_14, CommissionOnly_14, Gross_14, IsCommission_14, MarginPercent_14, SCPId_14, SVKey_14,
		AddCostIsCommission_15, AddCostNoCommission_15, CommissionOnly_15, Gross_15, IsCommission_15, MarginPercent_15, SCPId_15, SVKey_15
		from TP_PriceComponents with(nolock) join TP_Tours with(nolock) on TO_Key = PC_TOKey
		join TP_ServiceCalculateParametrs with (nolock) on SCPId_1 = SCP_Id
		join @hotelRoomsTable on SCP_SCId = SC_Id
		where PC_TOKey = isnull(@tourKey, PC_TOKey)
		and PC_HotelKey in (select xHotelKey from @tableHotelKeys)
		and PC_DepartureKey = isnull(@departureKey, 0)
		and PC_TourDate between isnull(@checkinDateBegin, PC_TourDate) and isnull(@checkinDateEnd, PC_TourDate)
		and (@weekDays is null or (@weekDays like '%' + convert(nvarchar(1), datepart(dw, PC_TourDate)) + '%'))
		and (@longList is null or (PC_Days in (select xLong from @tableLongList)))
		and (isnull(@IsDeletePriceOnly, 0) = 0 or PC_SummPrice is null)
		and (@IsOnlineOnly is null or (@IsOnlineOnly = case when PC_SummPrice is null then 0 else TO_IsEnabled end))
		
		print 'Выводим результат: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
	end
END

GO

grant exec on [dbo].[ReCalculate_ViewHotelCost] to public
go

/*********************************************************************/
/* end sp_ReCalculate_ViewHottelCost.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetServiceStatusOK.sql */
/*********************************************************************/
--2009.2.9.4
--2012-12-03
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetServiceStatusOK]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetServiceStatusOK]
GO
CREATE PROCEDURE [dbo].[SetServiceStatusOK]
	(
		-- хранимка определяет какой статус необходимо установить услуги, после изменения статуса квотирования
		@dlkey int,
		@dlcontrol int out -- новый статус
	)
AS
BEGIN
	set @dlcontrol = null
	DECLARE @oldDLControl int
	-- теперь в завмсимости от настроек будем менять статусы на Ок
	-- 0 - все галки сняты
	-- 1 - Все услуги
	-- 2 - Авиаперелет
	-- 3 - Все услуги & Авиаперелет
	-- 4 - Проживание
	-- 5 - Все услуги & Проживание
	-- 6 - Авиаперелет & Проживание
	-- 7 - Все услуги & Авиаперелет & Проживание
	
	-- Если это услуга из Интерлука, ничего не делаем
	DECLARE @dlPartnerKey int
	select @dlPartnerKey=DL_PARTNERKEY from tbl_dogovorList join [service] on dl_svkey = sv_key where dl_key = @dlkey and isnull(SV_QUOTED, 0) = 1
	if (exists (select top 1 1 from dbo.SystemSettings where SS_ParmName = 'IL_SyncILPartners' AND SS_ParmValue LIKE '%/' + convert(nvarchar(max) ,@dlPartnerKey) + '/%'))
		return
	
	-- Авиаперелет
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('2', '3', '6', '7'))
		and isnull((select max(isnull(SD_State, 4)) from ServiceByDate where SD_DLKey = @dlkey),4) < 4
		and exists(select top 1 1 from Dogovorlist where DL_KEY = @dlkey and DL_SvKey = 1 and DL_Control != 0)
	begin
		set @dlcontrol = 0
	end
	
	-- Проживание
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('4', '5', '6', '7'))
		and isnull((select max(isnull(SD_State, 4)) from ServiceByDate where SD_DLKey = @dlkey),4) < 4
		and exists (select top 1 1 from Dogovorlist where DL_KEY = @dlkey and DL_SvKey = 3 and DL_Control != 0)
	begin
		set @dlcontrol = 0
	end
	
	-- Все услуги
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('1', '3', '5', '7'))
		and isnull((select max(isnull(SD_State, 4)) from ServiceByDate where SD_DLKey = @dlkey),4) < 4
		and exists (select top 1 1 from Dogovorlist where DL_KEY = @dlkey and DL_SvKey != 3 and DL_SvKey != 1 and DL_Control != 0)
	begin
		set @dlcontrol = 0
	end

	-- 2012-10-12 tkachuk, task 8473 - добавлено условие
	-- если у квоты есть статус, устанавливаем его услуге
	if exists (select top 1 1 from QuotedState where QS_DLID = @dlkey)
	begin
		DECLARE @QState int
		select @QState = QS_State from QuotedState where QS_DLID = @dlkey
		select @dlControl = 
		(
			Case
			When @QState = 1 or @QState = 2 Then 0
			When @QState = 3 Then 0
			When @QState = 4 Then 1
			End
		)
		PRINT @dlControl
		
		-- 2012-10-12 tkachuk - следующие два блока перенесены из SetServiceStatus
		select @oldDLControl = DL_Control from Dogovorlist
		join [service] on dl_svkey = sv_key
		where dl_key = @dlkey
		and isnull(SV_QUOTED, 0) = 1
	
		-- если статус изменился
		if (@oldDLControl != @dlControl and @dlControl is not null)
			begin
				update Dogovorlist set DL_Control = @dlControl where DL_Key = @dlKey and DL_Control != @dlControl
			end
	end
	
	
	-- MEG00032041
	-- Теперь проверим есть ли на эту квоту запись в таблице QuotaStatuses
	-- которая говорит нам что нужно изменить статус услуги на тот который в этой таблице
	if exists(select 1 from QuotaStatuses join Quotas on QS_QTID = QT_ID						--false
				join QuotaDetails on QT_ID = QD_QTID
				join QuotaParts on QP_QDID = QD_ID
				join ServiceByDate on SD_QPID = QP_ID
				where SD_DLKey = @dlkey and SD_State = QS_Type) 
		and isnull((select max(isnull(SD_State, 4)) from ServiceByDate where SD_DLKey = @dlkey),4) < 4	--true
	begin
		declare @tempDlControl int
	
		select @tempDlControl = QS_CRKey
		from QuotaStatuses join Quotas on QS_QTID = QT_ID 
		join QuotaDetails on QT_ID = QD_QTID
		join QuotaParts on QP_QDID = QD_ID
		join ServiceByDate on SD_QPID = QP_ID
		where SD_DLKey = @dlkey and SD_State = QS_Type
				
		if exists(select top 1 1 from Dogovorlist where DL_KEY = @dlkey and DL_Control != @tempDlControl)
		begin
			update Dogovorlist set DL_Control = @tempDlControl where DL_Key = @dlKey 
		end
	end
	
	-- если наша услуга вне квоты, то установим ей статус из справочника услуг
	if (isnull((select max(isnull(SD_State, 4)) from ServiceByDate where SD_DLKey = @dlkey),4) = 4		--false
		and exists (select top 1 1 from Dogovorlist where DL_KEY = @dlkey and DL_Control != (select top 1 SV_CONTROL from [Service] where DL_SVKEY = SV_KEY)
		and exists (select top 1 1 from [Service] where DL_SVKEY = SV_KEY and isnull(SV_QUOTED, 0) = 1)))
	begin
		select @dlcontrol = SV_CONTROL from Dogovorlist join [Service] on DL_SVKEY = SV_KEY	where DL_KEY = @dlkey
		PRINT @dlControl
		
		-- 2012-10-12 tkachuk - следующие два блока перенесены из SetServiceStatus
		-- получаем старый статус
		select @oldDLControl = DL_Control from Dogovorlist
		join [service] on dl_svkey = sv_key
		where dl_key = @dlkey
		and isnull(SV_QUOTED, 0) = 1
	
		-- если статус изменился
		if (@oldDLControl != @dlControl and @dlControl is not null)
			begin
				update Dogovorlist set DL_Control = @dlControl where DL_Key = @dlKey and DL_Control != @dlControl
			end
		return
	end
END

GO

grant exec on [dbo].[SetServiceStatusOK] to public
go
/*********************************************************************/
/* end sp_SetServiceStatusOK.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SyncProtourQuotes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SyncProtourQuotes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SyncProtourQuotes]
GO
CREATE PROCEDURE [dbo].[SyncProtourQuotes]
(
	--<VERSION>2009.2.12</VERSION>
	--<DATA>02.11.2012</DATA>
	@hotelKey int = null,	-- ключ отеля
	@startDate datetime = null,		-- дата начала интервала, по которому изменялись квоты (для стопов передается null)
	@endDate datetime = null,		-- дата окончания интервала, по которому изменялись квоты (для стопов передается null)
	@quotesUpdate bit = null			-- признак того, что обновлять надо квоты (т.е. 1 - обновление квот, 0 - обновление стопов)
)
AS
BEGIN
	if (dbo.mwReplIsPublisher() = 0)
		return;
		
	declare @qtid int, @qoid int, @qdid int, @qdbusy int, @uskey int, @str nvarchar(max), @hdname varchar(100), 
			@rcname varchar(100), @ss_allotmentAndCommitment int, @email varchar(1000)  
	
	if (@startDate is null)
		set @startDate = '1900-01-01'
	if (@endDate is null)
		set @endDate = '2099-12-01'
	
	set @str = 'Количество квот, полученное из ProTour меньше, чем число занятых мест. Параметры квот:'
				
	--declare @HotelKeysTable as table (HDKey int)
	--if @hotelKeys <> ''
	--begin
	--	insert @HotelKeysTable 
	--	select * from ParseKeys(@hotelKeys) 
	--end
	
	set @uskey = 0 
	select @uskey = ISNULL(US_Key,0) from dbo.UserList where US_USERID = SYSTEM_USER
	
	declare @ptq_Id	int, @ptq_PartnerKey int, @ptq_HotelKey	int, @ptq_RoomCategoryKey int, @ptq_Date datetime,
	@ptq_State smallint, @ptq_CommitmentTotal int, @ptq_AllotmentTotal int, @ptq_Release int, @ptq_StopSale bit, -- 0 - квоты, 1 - стопы 
	@ptq_CancelStopSale bit -- 1 - удаление стопов, 0 - добавление стопов 
	
	if (@quotesUpdate = 1 or @quotesUpdate is null)
	begin
		DECLARE qCur CURSOR FAST_FORWARD READ_ONLY FOR
		SELECT	PTQ_Id, Ptq_PartnerKey, Ptq_HotelKey, Ptq_RoomCategoryKey, Ptq_Date, Ptq_State, Ptq_CommitmentTotal, Ptq_AllotmentTotal, 
				Ptq_Release, Ptq_StopSale, Ptq_CancelStopSale 	
				FROM ProtourQuotes where PTQ_Date between @startDate and @endDate   
											and (PTQ_HotelKey = @hotelKey or @hotelKey is null)
											and PTQ_StopSale=0 
											and PTQ_CancelStopSale is null
		
		OPEN qCur
		FETCH NEXT FROM qCur INTO	@ptq_Id, @ptq_PartnerKey, @ptq_HotelKey, @ptq_RoomCategoryKey, @ptq_Date, @ptq_State, 
							@ptq_CommitmentTotal, @ptq_AllotmentTotal, @ptq_Release, @ptq_StopSale, @ptq_CancelStopSale
						
		WHILE @@FETCH_STATUS = 0
		BEGIN 
			BEGIN TRY
				if ((@ptq_CommitmentTotal > 0 or (@ptq_CommitmentTotal = 0 and @ptq_AllotmentTotal = 0)) and @ptq_State <> 2)
				begin
					-- проверяем если сегодня закачки квот из ProTour не было (SYSExistsProtourQuotesHistory = 0), то если @ptq_State=3 проверяем наличие квоты в МТ 
					if (@ptq_State=1 or @ptq_State=3) -- если квота новая
					begin
						if not exists (select TOP 1 1
									from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
									inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
									where QT_PRKey = @ptq_PartnerKey
									and QO_SVKey = 3
									and QO_Code = @ptq_HotelKey
									and QO_SubCode1 = 0
									and QO_SubCode2 = @ptq_RoomCategoryKey
									and QT_ByRoom = 1
									and QD_Type = 2)
						begin
							insert into Quotas (QT_PRKey, QT_ByRoom, QT_Comment) 
							values (@ptq_PartnerKey, 1, '')
							set @qtid = SCOPE_IDENTITY()
							
							insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
							values (@qtid, 3, @ptq_HotelKey, 0, @ptq_RoomCategoryKey)
							set @qoid = SCOPE_IDENTITY()
							
							insert into QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
							values (@qtid, @ptq_Date, 2, @ptq_CommitmentTotal, 0, GETDATE(), ISNULL(@uskey,0)) 
							set @qdid = SCOPE_IDENTITY()
					
							insert into QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
							values (@qdid, @ptq_Date, @ptq_CommitmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0) 
							
							update QuotaObjects
							set QO_CTKey = (select HD_CTKey from HotelDictionary where HD_Key = QO_Code)
							where QO_SVKey = 3 and QO_ID = @qoid and QO_CTKey is null
						
							update QuotaObjects
							set QO_CNKey= (select CT_CNKey from CityDictionary where CT_Key=QO_CTKey) 
							where QO_CNKey is null and QO_CTKey is not null and QO_ID = @qoid
							
							update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
						end
						else
						begin
							if exists (select TOP 1 1
									from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
									inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
									where QT_PRKey = @ptq_PartnerKey
									and QO_SVKey = 3
									and QO_Code = @ptq_HotelKey
									and QO_SubCode1 = 0
									and QO_SubCode2 = @ptq_RoomCategoryKey
									and QD_Date = @ptq_Date
									and QT_ByRoom = 1
									and QD_Type = 2)
							begin
								select @qdid = QD_ID, @qdbusy = QD_Busy 
									from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
									inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
									where QT_PRKey = @ptq_PartnerKey
									and QO_SVKey = 3
									and QO_Code = @ptq_HotelKey
									and QO_SubCode1 = 0
									and QO_SubCode2 = @ptq_RoomCategoryKey
									and QD_Date = @ptq_Date
									and QT_ByRoom = 1
									and QD_Type = 2
									
								if (@qdbusy > @ptq_CommitmentTotal)
								begin
									-- если число занятых мест в МТ больше числа мест пришедших из Протура, то в Places = Busy
									update QuotaDetails set QD_Places = QD_Busy where QD_ID = @qdid 
									update QuotaParts set QP_Places = QP_Busy where QP_QDID = @qdid
									update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
									
									-- и дальше отправляем письмо
									select @hdname = ISNULL(HD_Name,0) from HotelDictionary where HD_Key = @ptq_HotelKey
									select @rcname = ISNULL(RC_Name,0) from RoomsCategory where RC_key = @ptq_RoomCategoryKey
									set @str = @str + CHAR(13) + CHAR(13) + 'Партнер:' + convert(varchar(100),@ptq_PartnerKey) + CHAR(13) + 
																'Отель:' + convert(varchar(100),@hdname) + '(' + convert(varchar(100),@ptq_HotelKey) + ')' + CHAR(13) +
																'Категория номера:' + convert(varchar(100),@rcname) + CHAR(13) + 
																'Дата:' + convert(varchar(100),@ptq_Date, 105) + CHAR(13)
									print @str
								end 
								else 
								begin
									update QuotaDetails set QD_Places = @ptq_CommitmentTotal where QD_ID = @qdid 
									update QuotaParts set QP_Places = @ptq_CommitmentTotal where QP_QDID = @qdid
									update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
								end 
							end
							else
							begin
								select @qtid = QT_ID, @qoid = QO_ID 
									from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
									inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
									where QT_PRKey = @ptq_PartnerKey
									and QO_SVKey = 3
									and QO_Code = @ptq_HotelKey
									and QO_SubCode1 = 0
									and QO_SubCode2 = @ptq_RoomCategoryKey
									and QT_ByRoom = 1
									and QD_Type = 2
									
								insert into QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
								values (@qtid, @ptq_Date, 2, @ptq_CommitmentTotal, 0, GETDATE(), ISNULL(@uskey,0)) 
								set @qdid = SCOPE_IDENTITY()
					
								insert into QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
								values (@qdid, @ptq_Date, @ptq_CommitmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0)
								
								update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
								
							end
						end
					end
					if (@ptq_State=4) --удаляемая
					begin 
						update QuotaDetails
						set QD_IsDeleted = 4 -- Request
						from Quotas join QuotaDetails on QT_ID = QD_QTID
						join QuotaObjects on QT_ID = QO_QTID
						where QT_PRKey = @ptq_PartnerKey
							and QO_SVKey = 3
							and QO_Code = @ptq_HotelKey
							and QO_SubCode1 = 0
							and QO_SubCode2 = @ptq_RoomCategoryKey
							and QD_Date = @ptq_Date
							and QT_ByRoom = 1
							and QD_Type = 2
			
						exec QuotaDetailAfterDelete
						
						delete QuotaObjects
						from QuotaObjects join Quotas on QO_QTID = QT_ID
						where not exists (select 1 from StopSales where SS_QOID = QO_ID)
						and not exists (select 1 from QuotaDetails where QD_QTID = QT_ID)
						and QO_SVKey = 3
						and QO_Code = @ptq_HotelKey
						and QO_SubCode1 = 0
						and QO_SubCode2 = @ptq_RoomCategoryKey
						and QT_ByRoom = 1
		
						delete Quotas
						from Quotas join QuotaObjects on QT_ID = QO_QTID
						where not exists (select 1 from QuotaObjects where QO_QTID = QT_ID)
						and not exists (select 1 from QuotaDetails where QD_QTID = QT_ID)
						and QT_ByRoom = 1
						
						delete ProtourQuotes where PTQ_Id = @ptq_Id
					end
				end 
			END TRY
			BEGIN CATCH
				DECLARE @errorMessage2 as nvarchar(max)
				SET @errorMessage2 = 'Error in SyncProtourQuotes commitment: ' + ERROR_MESSAGE() + convert(nvarchar(max), @ptq_Id)

				INSERT INTO SystemLog (sl_date, sl_message)
				VALUES (getdate(), @errorMessage2)
			END CATCH
			
			BEGIN TRY
				if ((@ptq_AllotmentTotal > 0 or (@ptq_CommitmentTotal = 0 and @ptq_AllotmentTotal = 0)) and @ptq_State <> 2)
				begin
					-- проверяем если сегодня закачки квот из ProTour не было (SYSExistsProtourQuotesHistory = 0), то если @ptq_State=3 проверяем наличие квоты в МТ 
					if (@ptq_State=1 or @ptq_State=3) -- если квота новая
					begin
						if not exists (select TOP 1 1
									from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
									inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
									where QT_PRKey = @ptq_PartnerKey
									and QO_SVKey = 3
									and QO_Code = @ptq_HotelKey
									and QO_SubCode1 = 0
									and QO_SubCode2 = @ptq_RoomCategoryKey
									and QT_ByRoom = 1
									and QD_Type = 1)
						begin
							insert into Quotas (QT_PRKey, QT_ByRoom, QT_Comment) 
							values (@ptq_PartnerKey, 1, '')
							set @qtid = SCOPE_IDENTITY()
							
							insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
							values (@qtid, 3, @ptq_HotelKey, 0, @ptq_RoomCategoryKey)
							set @qoid = SCOPE_IDENTITY()
							
							insert into QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Release, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
							values (@qtid, @ptq_Date, 1, @ptq_Release, @ptq_AllotmentTotal, 0, GETDATE(), ISNULL(@uskey,0)) 
							set @qdid = SCOPE_IDENTITY()
					
							insert into QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
							values (@qdid, @ptq_Date, @ptq_AllotmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0) 
							
							update QuotaObjects
							set QO_CTKey = (select HD_CTKey from HotelDictionary where HD_Key = QO_Code)
							where QO_SVKey = 3 and QO_ID = @qoid and QO_CTKey is null
						
							update QuotaObjects
							set QO_CNKey= (select CT_CNKey from CityDictionary where CT_Key=QO_CTKey) 
							where QO_CNKey is null and QO_CTKey is not null and QO_ID = @qoid
							
							update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
						end
						else
						begin
							if exists (select TOP 1 1
									from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
									inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
									where QT_PRKey = @ptq_PartnerKey
									and QO_SVKey = 3
									and QO_Code = @ptq_HotelKey
									and QO_SubCode1 = 0
									and QO_SubCode2 = @ptq_RoomCategoryKey
									and QD_Date = @ptq_Date
									and QT_ByRoom = 1
									and QD_Type = 1)
							begin
								select @qdid = QD_ID, @qdbusy = QD_Busy 
									from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
									inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
									where QT_PRKey = @ptq_PartnerKey
									and QO_SVKey = 3
									and QO_Code = @ptq_HotelKey
									and QO_SubCode1 = 0
									and QO_SubCode2 = @ptq_RoomCategoryKey
									and QD_Date = @ptq_Date
									and QT_ByRoom = 1
									and QD_Type = 1
									
								if (@qdbusy > @ptq_AllotmentTotal)
								begin
									-- если число занятых мест в МТ больше числа мест пришедших из Протура, то в Places = Busy
									update QuotaDetails set QD_Places = QD_Busy, QD_Release = @ptq_Release where QD_ID = @qdid 
									update QuotaParts set QP_Places = QP_Busy where QP_QDID = @qdid
									update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
									
									-- и дальше отправляем письмо
									select @hdname = ISNULL(HD_Name,0) from HotelDictionary where HD_Key = @ptq_HotelKey
									select @rcname = ISNULL(RC_Name,0) from RoomsCategory where RC_key = @ptq_RoomCategoryKey
									set @str = @str + CHAR(13) + CHAR(13) + 'Партнер:' + convert(varchar(100),@ptq_PartnerKey) + CHAR(13) + 
																'Отель:' + convert(varchar(100),@hdname) + '(' + convert(varchar(100),@ptq_HotelKey) + ')' + CHAR(13) +
																'Категория номера:' + convert(varchar(100),@rcname) + CHAR(13) + 
																'Дата:' + convert(varchar(100),@ptq_Date, 105) + CHAR(13)
									print @str
								end 
								else 
								begin
									update QuotaDetails set QD_Places = @ptq_AllotmentTotal, QD_Release = @ptq_Release where QD_ID = @qdid 
									update QuotaParts set QP_Places = @ptq_AllotmentTotal where QP_QDID = @qdid
									update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
								end 
							end
							else
							begin
								select @qtid = QT_ID, @qoid = QO_ID 
									from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
									inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
									where QT_PRKey = @ptq_PartnerKey
									and QO_SVKey = 3
									and QO_Code = @ptq_HotelKey
									and QO_SubCode1 = 0
									and QO_SubCode2 = @ptq_RoomCategoryKey
									and QT_ByRoom = 1
									and QD_Type = 1
									
								insert into QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Release, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
								values (@qtid, @ptq_Date, 1, @ptq_Release, @ptq_AllotmentTotal, 0, GETDATE(), ISNULL(@uskey,0)) 
								set @qdid = SCOPE_IDENTITY()
					
								insert into QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
								values (@qdid, @ptq_Date, @ptq_AllotmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0)
								
								update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
								
							end
						end
					end
					
					if (@ptq_State=4) --удаляемая
					begin 
						update QuotaDetails
						set QD_IsDeleted = 4 -- Request
						from Quotas join QuotaDetails on QT_ID = QD_QTID
						join QuotaObjects on QT_ID = QO_QTID
						where QT_PRKey = @ptq_PartnerKey
							and QO_SVKey = 3
							and QO_Code = @ptq_HotelKey
							and QO_SubCode1 = 0
							and QO_SubCode2 = @ptq_RoomCategoryKey
							and QD_Date = @ptq_Date
							and QT_ByRoom = 1
							and QD_Type = 1
			
						exec QuotaDetailAfterDelete
						
						delete QuotaObjects
						from QuotaObjects join Quotas on QO_QTID = QT_ID
						where not exists (select 1 from StopSales where SS_QOID = QO_ID)
						and not exists (select 1 from QuotaDetails where QD_QTID = QT_ID)
						and QO_SVKey = 3
						and QO_Code = @ptq_HotelKey
						and QO_SubCode1 = 0
						and QO_SubCode2 = @ptq_RoomCategoryKey
						and QT_ByRoom = 1
		
						delete Quotas
						from Quotas join QuotaObjects on QT_ID = QO_QTID
						where not exists (select 1 from QuotaObjects where QO_QTID = QT_ID)
						and not exists (select 1 from QuotaDetails where QD_QTID = QT_ID)
						and QT_ByRoom = 1
						
						delete ProtourQuotes where PTQ_Id = @ptq_Id
					end
				end
			END TRY
			BEGIN CATCH
				DECLARE @errorMessage3 as nvarchar(max)
				SET @errorMessage3 = 'Error in SyncProtourQuotes allotment: ' + ERROR_MESSAGE() + convert(nvarchar(max), @ptq_Id)

				INSERT INTO SystemLog (sl_date, sl_message)
				VALUES (getdate(), @errorMessage3)
			END CATCH
			
			if (@ptq_CommitmentTotal <= 0 and @ptq_AllotmentTotal <= 0 and @ptq_State <> 2)
			begin
				update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
			end
		
			FETCH NEXT FROM qCur INTO @ptq_Id, @ptq_PartnerKey, @ptq_HotelKey, @ptq_RoomCategoryKey, @ptq_Date, @ptq_State, 
							@ptq_CommitmentTotal, @ptq_AllotmentTotal, @ptq_Release, @ptq_StopSale, @ptq_CancelStopSale
						
		END
		CLOSE qCur
		DEALLOCATE qCur	
		
		BEGIN TRY
			if exists (select 1 from SystemSettings where SS_ParmName='SYSEmailProtourQuotes')
				select @email = SS_ParmValue from SystemSettings where SS_ParmName='SYSEmailProtourQuotes'
				
			if (@str <> 'Количество квот, полученное из ProTour меньше, чем число занятых мест. Параметры квот:')
			begin
				declare @bkid int
				-- отправка письма, если количество квот, полученное из ProTour меньше, чем число занятых мест
				insert into Blanks (BK_CreateDate, BK_UserKey) values (GETDATE(), ISNULL(@uskey,0))
				set @bkid = SCOPE_IDENTITY()
			
				insert into SendMail (SM_EMAIL, SM_Text, SM_Date, SM_BKID, SM_Creator) values (ISNULL(@email,''), @str, GETDATE(), @bkid, ISNULL(@uskey,0)) 
			end
		END TRY
		BEGIN CATCH
			DECLARE @errorMessage4 as nvarchar(max)
			SET @errorMessage4 = 'Error in SyncProtourQuotes insert Blanks: ' + ERROR_MESSAGE()
			
			INSERT INTO SystemLog (sl_date, sl_message)
			VALUES (getdate(), @errorMessage4)
		END CATCH
	end
	if (@quotesUpdate = 0 or @quotesUpdate is null) --обрабатываем стопы
	begin

		DECLARE qCur CURSOR FAST_FORWARD READ_ONLY FOR
		
		SELECT	PTQ_Id, Ptq_PartnerKey, Ptq_HotelKey, Ptq_RoomCategoryKey, Ptq_Date, Ptq_State, PTQ_CommitmentTotal, PTQ_AllotmentTotal, Ptq_Release, Ptq_StopSale, Ptq_CancelStopSale	
			FROM ProtourQuotes where (PTQ_HotelKey = @hotelKey or @hotelKey is null) and PTQ_StopSale=1
										
		OPEN qCur
		FETCH NEXT FROM qCur INTO	@ptq_Id, @ptq_PartnerKey, @ptq_HotelKey, @ptq_RoomCategoryKey, @ptq_Date, @ptq_State, @ptq_CommitmentTotal, @ptq_AllotmentTotal,
									@ptq_Release, @ptq_StopSale, @ptq_CancelStopSale
						
		WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN TRY
				if (@ptq_CommitmentTotal = 1 and @ptq_AllotmentTotal = 1)
				set @ss_allotmentAndCommitment = 1
				else if (@ptq_AllotmentTotal = 1 and @ptq_CommitmentTotal = 0) 
					set @ss_allotmentAndCommitment = 0
				else 
					set @ss_allotmentAndCommitment = 1
					
				if ((@ptq_State = 1 or @ptq_State = 3) and @ptq_CancelStopSale = 0) -- 0 - добавление стопов, 1 - удаление стопов
				begin
					if exists (select TOP 1 1 from QuotaObjects where QO_Code = @ptq_HotelKey and QO_SVKey = 3 and QO_SubCode1 = 0 and QO_SubCode2 = @ptq_RoomCategoryKey and QO_QTID is null) -- при передаче стопов, здесь лежит RM_Key
					begin
						if not exists (select TOP 1 1 from StopSales join QuotaObjects on SS_QOID=QO_ID
								where SS_PRKey = @ptq_PartnerKey
								and QO_Code = @ptq_HotelKey
								and SS_Date = @ptq_Date
								and QO_SubCode2 = @ptq_RoomCategoryKey
								and SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
								and QO_QTID is null
								and QO_SVKey = 3) -- при передаче стопов, здесь лежит RM_Key
						begin
							select @qoid = QO_ID from QuotaObjects where QO_Code = @ptq_HotelKey and QO_SVKey = 3 and QO_SubCode1 = 0 and QO_SubCode2 = @ptq_RoomCategoryKey and QO_QTID is null 
						end
						else
						begin
							update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id	
							-- временно, для того чтобы отловить ошибку
							if not exists (select TOP 1 1 from StopSales join QuotaObjects on SS_QOID=QO_ID
								where SS_PRKey = @ptq_PartnerKey
								and QO_Code = @ptq_HotelKey
								and SS_Date = @ptq_Date
								and QO_SubCode2 = @ptq_RoomCategoryKey
								and SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
								and QO_QTID is null
								and QO_SVKey = 3)	
							begin
								DECLARE @errorMessage as nvarchar(max)
								SET @errorMessage = 'Error in SyncProtourQuotes stop (not exists):  ' + convert(nvarchar(max), @ptq_Id)

								INSERT INTO SystemLog (sl_date, sl_message)
								VALUES (getdate(), @errorMessage)
								
								update ProtourQuotes set PTQ_State = 3 where PTQ_Id = @ptq_Id	
							end
							--	
						end										
					end
					else
					begin
						insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
						values (null, 3, @ptq_HotelKey, 0, @ptq_RoomCategoryKey)
						set @qoid = SCOPE_IDENTITY()
					end
					
					insert into StopSales(SS_QOID, SS_QDID, SS_PRKey, SS_Date, SS_AllotmentAndCommitment, SS_Comment, SS_CreateDate, SS_CreatorKey)
								values (@qoid, null, @ptq_PartnerKey, @ptq_Date, @ss_allotmentAndCommitment, '', GETDATE(), ISNULL(@uskey,0))
						
					update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
					
					-- временно, для того чтобы отловить ошибку
					if not exists (select TOP 1 1 from StopSales join QuotaObjects on SS_QOID=QO_ID
						where SS_PRKey = @ptq_PartnerKey
						and QO_Code = @ptq_HotelKey
						and SS_Date = @ptq_Date
						and QO_SubCode2 = @ptq_RoomCategoryKey
						and SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
						and QO_QTID is null
						and QO_SVKey = 3)	
					begin
						DECLARE @errorMessage1 as nvarchar(max)
						SET @errorMessage1 = 'Error in SyncProtourQuotes stop (not exists):  ' + convert(nvarchar(max), @ptq_Id)

						INSERT INTO SystemLog (sl_date, sl_message)
						VALUES (getdate(), @errorMessage1)
								
						update ProtourQuotes set PTQ_State = 3 where PTQ_Id = @ptq_Id	
					end
					--
							
					update QuotaObjects
							set QO_CTKEY = (select HD_CTKEY from HotelDictionary where HD_KEY = QO_Code)
							where QO_ID = @qoid
						
					update QuotaObjects
							set QO_CNKey = (select CT_CNKEY from CityDictionary where CT_KEY = QO_CTKey)
							where QO_CNKey is null
							and QO_CTKey is not null
							and QO_ID = @qoid
				end
			END TRY
			BEGIN CATCH
				DECLARE @errorMessage_1 as nvarchar(max)
				SET @errorMessage_1 = 'Error in SyncProtourQuotes stop: ' + ERROR_MESSAGE() + convert(nvarchar(max), @ptq_Id)

				INSERT INTO SystemLog (sl_date, sl_message)
				VALUES (getdate(), @errorMessage_1)
			END CATCH
			BEGIN TRY
				if (((@ptq_State = 1 or @ptq_State = 3) and @ptq_CancelStopSale = 1) or (@ptq_State = 4 and @ptq_CancelStopSale = 0) and @ptq_State <> 2)
				begin
					if exists (select TOP 1 1 from StopSales join QuotaObjects on SS_QOID = QO_ID
					where QO_Code = @ptq_HotelKey
					and QO_SVKey = 3
					and QO_SubCode1 = 0 
					and SS_Date = @ptq_Date
					and SS_PRKey = @ptq_PartnerKey
					and QO_SubCode2 = @ptq_RoomCategoryKey
					and SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
					and QO_QTID is null)
					begin
						delete StopSales
						from StopSales join QuotaObjects on SS_QOID = QO_ID
						where QO_Code = @ptq_HotelKey
						and QO_SVKey = 3
						and QO_SubCode1 = 0 
						and SS_Date = @ptq_Date
						and SS_PRKey = @ptq_PartnerKey
						and QO_SubCode2 = @ptq_RoomCategoryKey
						and SS_AllotmentAndCommitment = @ss_allotmentAndCommitment
						and QO_QTID is null
					
						update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
					end
					else
					begin
						update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
						print 'Стоп-сейл был уже ранее удален'
					end
				end
				if (@ptq_State = 4 and @ptq_CancelStopSale = 1)
				begin
					delete ProtourQuotes where PTQ_Id = @ptq_Id
				end
			END TRY
			BEGIN CATCH
				DECLARE @errorMessage9 as nvarchar(max)
				SET @errorMessage9 = 'Error in SyncProtourQuotes cancel stop: ' + ERROR_MESSAGE() + convert(nvarchar(max), @ptq_Id)

				INSERT INTO SystemLog (sl_date, sl_message)
				VALUES (getdate(), @errorMessage9)
			END CATCH
			
			FETCH NEXT FROM qCur INTO @ptq_Id, @ptq_PartnerKey, @ptq_HotelKey, @ptq_RoomCategoryKey, @ptq_Date, @ptq_State, @ptq_CommitmentTotal, @ptq_AllotmentTotal,
							@ptq_Release, @ptq_StopSale, @ptq_CancelStopSale
		END
		CLOSE qCur
		DEALLOCATE qCur
	end
	
	if not exists (select TOP 1 1 from History where (HI_Date between dateadd(dd,datediff(dd,0,getdate()),0) and getdate()) and HI_Text = 'Произошла закачка квот из ProtourQuotes')
	begin
		insert into History (HI_Date, HI_Text) values (getdate(), 'Произошла закачка квот из ProtourQuotes')
		--update SystemSettings set SS_ParmValue=convert(varchar(100), getdate(), 105) where SS_ParmName = 'SYSProtourQuotesHistory'
	end
															
END
GO
grant exec on [dbo].[SyncProtourQuotes] to public
go



/*********************************************************************/
/* end sp_SyncProtourQuotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_TranslateToProTour.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TranslateToProTour]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[TranslateToProTour]
GO
CREATE PROCEDURE [dbo].[TranslateToProTour]
AS
--<VERSION>2009.2.17.1</VERSION>
--<DATE>2012-11-24</DATE>
--.17 neupokoev Если нет в истории сообщения поставщику после внесенных изменений(не только по отелю), такие брони игнорируются
--.16 neupokoev Если в путевке изменялись туристы, то приравниваем это к изменению отеля. Флаги меняются только при изменении услуг(HI_OAID = 2) в путевке.
--.15 9567 tfs neupokoev Если в путевке не изменяли услугу отель(а изменяли трансфер перелет и т.д.), то нужно ставить Protour flag = 5, если изменялся отель то Protour flag = 1 .
-- Изменять Protour flag = 1 только если после изменений было создано сообщение поставщику
--.14 Gen 17.10.2012 отменить отправку в ProTour туров без размещения 
--.13 Gen 01.10.2012 отменить отправку в ProTour туров в Египет с типом = INFO 
--.12 Gen 29.05.2012 не отправлять Аннуляции заявок, закрепленные за TUI Ukraine в испанский Протур.
--.11 Gen 29.05.2012 отменить отправку в ProTour индивидуальных туров DG_TRKEY <> 0
--.10 (MEG00030676) поиск изменений по истории делается теперь за ПОСЛЕДНИЙ месяц, также могут быть отправлены путевки по которым дата заезда уже месяц как прошла
--.9 добавлено условие = не отправлять путевки, в которых существует ошибка в синхронизации размещений
--.8 устанавливаем признак DG_ProTourFlag=3, даже если путевка не отправлялась в ProTour
--.7 исправил ошибку с отправлением путевки
--.6 отправляю сообщение по всем путевкам, даже если прошла дата заезда
--признаком, отмечаются все путевки предназначенные для передачи в ProTour
--задержка 12 минут, так как точно должны отработать правила проверки дублирования и корректности путевки
DECLARE @StateDouble int, @StateNotConsistent int, @StateSyncError int
SELECT	@StateDouble=CAST(ILR_StatusKeys as int) FROM	ILReferenceNew	WHERE ILR_Key=6
SELECT	@StateNotConsistent=CAST(ILR_StatusKeys as int) FROM	ILReferenceNew	WHERE ILR_Key=7
SET @StateSyncError=16

declare @ProtourCountryKeysSetting nvarchar(max)

set @ProtourCountryKeysSetting = (select SS_ParmValue from SystemSettings
								 where SS_ParmName = 'ProtourCountryKeys')

declare @CountryKeys as table (CNKey int)

if @ProtourCountryKeysSetting <> ''
begin
	insert @CountryKeys 
	select * 
	from ParseKeys(@ProtourCountryKeysSetting)
end


UPDATE Dogovor 
SET DG_ProTourFlag=1 
WHERE DG_ProTourFlag is null 
  and not DG_TRKEY = 0 --11. Gen 29.05.2012 
  and not DG_TRKEY in (select TL_KEY from tbl_TurList where TL_TIP = 12312205) --.13 Gen 01.10.2012 TL_CNKEY = 9 AND 
  and EXISTS(select DL_KEY from dbo.tbl_DogovorList WHERE DL_DGCOD=DG_CODE AND DL_SVKEY=3) --.14 Gen 17.10.2012 
  and DG_TurDate > DATEADD(MONTH,-1,GetDate()) 
  and DG_SOR_Code not in (@StateDouble,@StateNotConsistent,@StateSyncError)
  and (not exists(select * from @CountryKeys) or DG_CNKEY IN (select * from @CountryKeys))
  and NOT EXISTS (SELECT 1 
				  FROM HISTORY with (nolock) 
				  WHERE HI_DGCod=DG_Code 
					AND HI_Date BETWEEN DATEADD(MINUTE,-12,GetDate()) 
					AND GetDate())

UPDATE Dogovor 
SET DG_ProTourFlag=null 
WHERE DG_ProTourFlag=1 
  and DG_TurDate > DATEADD(MONTH,-1,GetDate()) 
  and DG_SOR_Code in (@StateDouble,@StateNotConsistent,@StateSyncError)
  and (not exists(select * from @CountryKeys) or DG_CNKEY IN (select * from @CountryKeys))
  and NOT EXISTS (SELECT 1 
				  FROM HISTORY with (nolock) 
				  WHERE HI_DGCod=DG_Code 
					AND HI_Date BETWEEN DATEADD(MINUTE,-12,GetDate()) 
					AND GetDate())

UPDATE Dogovor 
SET DG_ProTourFlag=3 
WHERE DG_ProTourFlag = 2 
  and DG_TurDate = '30-DEC-1899' 
  and DG_TurDateBfrAnnul > DATEADD(MONTH,-1,GetDate())
  and (not exists(select * from @CountryKeys) or DG_CNKEY IN (select * from @CountryKeys))
  and not (DG_PARTNERKEY = 44516 and DG_CNKEY = 488) --.12 Gen 29.05.2012

UPDATE Dogovor 
SET DG_ProTourFlag=3 
WHERE DG_ProTourFlag = 1 
  and DG_TurDate = '30-DEC-1899' 
  and DG_TurDateBfrAnnul > DATEADD(MONTH,-1,GetDate())
  and (not exists(select * from @CountryKeys) or DG_CNKEY IN (select * from @CountryKeys))
  and not (DG_PARTNERKEY = 44516 and DG_CNKEY = 488) --.12 Gen 29.05.2012

UPDATE Dogovor 
SET DG_ProTourFlag=3 
WHERE DG_ProTourFlag is not null 
  and DG_ProTourFlag not in (3,4)
  and DG_TurDate = '30-DEC-1899'
  and not (DG_PARTNERKEY = 44516 and DG_CNKEY = 488) --.12 Gen 29.05.2012
  and (not exists(select * from @CountryKeys) or DG_CNKEY IN (select * from @CountryKeys))
  and NOT EXISTS (SELECT 1 
				  FROM HISTORY with (nolock) 
				  WHERE HI_DGCod=DG_Code 
					AND HI_Date BETWEEN DATEADD(MINUTE,-12,GetDate()) 
					AND GetDate())
	
DECLARE @DG_Key int, @DG_Code varchar(20), @HIDateMTP datetime

DECLARE cur_1 CURSOR FOR
	SELECT DG_Key,DG_Code,MAX(HI_Date) 
	FROM History as h1,Dogovor as d1 
	WHERE HI_Date BETWEEN DATEADD(MONTH,-1,GetDate()) 
      and DATEADD(MINUTE,-12,GetDate()) 
      AND HI_Mod='MTP'
	  and DG_Code=HI_DGCod and (DG_ProTourFlag!=1 and DG_ProTourFlag is not null) 
	  and DG_SOR_Code not in (@StateDouble,@StateNotConsistent,@StateSyncError)
	GROUP BY DG_Key,DG_Code

OPEN cur_1

	FETCH NEXT FROM cur_1 INTO @DG_Key, @DG_Code, @HIDateMTP
		WHILE @@FETCH_STATUS = 0
			BEGIN 
					--.15 9567 tfs neupokoev 24.11.2012
					-- Если есть запись об изменении отеля после последнего апдейта протурфлага
					IF EXISTS(SELECT 1 FROM History WITH (NOLOCK), HistoryDetail WITH (NOLOCK)
									WHERE HD_ID = HD_HIID AND HI_DGCOD = @DG_Code AND (HI_SVKEY = 3 OR HI_OAID = 3) --.16 HI_OAID = 3 - поменялся турист, изменения туристов приравнивается к изменению отеля
										AND HI_DATE > (SELECT MAX(HI_DATE) FROM History, HistoryDetail 
															WHERE HD_HIID=HI_ID 
																AND hd_oaid=399999 
																AND HI_DGCod=@DG_Code 
																AND HI_Date < @HIDateMTP))
						-- и не было никаких изменений, оставшихся без сообщений об этом партнеру
						AND NOT EXISTS (SELECT 1 FROM HISTORY with (nolock), HistoryDetail with (nolock) 
											WHERE HD_HIID=HI_ID AND HI_DGCod=@DG_Code 
												AND hd_oaid=399999 
												AND HI_Date > @HIDateMTP)
						BEGIN
							--.15 Апдейтим протур флаг единицей 
							UPDATE Dogovor 
								SET DG_ProTourFlag=1 
									WHERE DG_Key=@DG_Key
										AND NOT DG_TRKEY = 0 --11. Gen 29.05.2012 
										AND NOT DG_TRKEY IN (SELECT TL_KEY FROM tbl_TurList WHERE TL_TIP = 12312205) --.13 Gen 01.10.2012 TL_CNKEY = 9 AND 
										AND EXISTS(SELECT DL_KEY FROM dbo.tbl_DogovorList WHERE DL_DGCOD=DG_CODE AND DL_SVKEY=3) --.14 Gen 17.10.2012 
										AND (NOT EXISTS(SELECT * FROM @CountryKeys) OR DG_CNKEY IN (SELECT * FROM @CountryKeys))
										AND NOT EXISTS (SELECT 1 FROM HISTORY with (nolock) 
															WHERE HI_DGCod=@DG_Code 
																AND HI_Date BETWEEN DATEADD(MINUTE,-11,GetDate()) AND GetDate())
						END
					ELSE
						--.15 Если изменяли не отель
						BEGIN
							IF EXISTS(SELECT 1 FROM History WITH (NOLOCK), HistoryDetail WITH (NOLOCK)
									WHERE HD_ID = HD_HIID AND HI_DGCOD = @DG_Code AND ISNULL(HI_SVKEY, -1) != 3 AND HI_OAID = 2 -- .16 И изменяли услуги, а не что-то другое (HI_OAID = 2)
										AND HI_DATE > (SELECT MAX(HI_DATE) FROM History, HistoryDetail 
															WHERE HD_HIID=HI_ID 
																AND hd_oaid=399999 
																AND HI_DGCod=@DG_Code 
																AND HI_Date < @HIDateMTP))
								-- .17 и не было никаких изменений, оставшихся без сообщений об этом партнеру
								AND NOT EXISTS (SELECT 1 FROM HISTORY with (nolock), HistoryDetail with (nolock) 
											WHERE HD_HIID=HI_ID AND HI_DGCod=@DG_Code 
												AND hd_oaid=399999 
												AND HI_Date > @HIDateMTP)
								BEGIN
									--.15 Апдейтим протур флаг пятеркой 
									UPDATE Dogovor 
										SET DG_ProTourFlag=5 
											WHERE DG_Key=@DG_Key
												AND NOT DG_TRKEY = 0 --11. Gen 29.05.2012 
												AND NOT DG_TRKEY IN (SELECT TL_KEY FROM tbl_TurList WHERE TL_TIP = 12312205) --.13 Gen 01.10.2012 TL_CNKEY = 9 AND 
												AND EXISTS(SELECT DL_KEY FROM dbo.tbl_DogovorList WHERE DL_DGCOD=DG_CODE AND DL_SVKEY=3) --.14 Gen 17.10.2012 
												AND (NOT EXISTS(SELECT * FROM @CountryKeys) OR DG_CNKEY IN (SELECT * FROM @CountryKeys))
												AND NOT EXISTS (SELECT 1 FROM HISTORY with (nolock) 
																	WHERE HI_DGCod=@DG_Code 
																		AND HI_Date BETWEEN DATEADD(MINUTE,-11,GetDate()) AND GetDate())
								END 
						END 
				FETCH NEXT FROM cur_1 INTO @DG_Key, @DG_Code, @HIDateMTP
			END
CLOSE cur_1

DEALLOCATE cur_1
GO
grant exec on [dbo].[TranslateToProTour] to public
go
/*********************************************************************/
/* end sp_TranslateToProTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_UpdateReservationMainMan.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UpdateReservationMainMan]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[UpdateReservationMainMan]
GO
CREATE PROCEDURE [dbo].[UpdateReservationMainMan]
(
	@ManName varchar(70), 
	@ManPhone varchar(50), 
	@ManEmail varchar(50), 
	@ManAddress varchar(320), 
	@ManPassport varchar(70),
	@ReservationCode varchar(10)
)
AS
BEGIN
	UPDATE [dbo].[TBL_DOGOVOR]
	   SET DG_MAINMEN = @ManName
	     , DG_MAINMENPHONE = @ManPhone
	     , DG_MAINMENEMAIL = @ManEmail
	     , DG_MAINMENADRESS = @ManAddress
         , DG_MAINMENPASPORT = @ManPassport
	 WHERE DG_CODE = @ReservationCode;
END
GO

grant exec on [dbo].[UpdateReservationMainMan] to public
go
/*********************************************************************/
/* end sp_UpdateReservationMainMan.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_UpdateReservationMainManByPartnerUser.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UpdateReservationMainManByPartnerUser]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[UpdateReservationMainManByPartnerUser]
GO
CREATE PROCEDURE [dbo].[UpdateReservationMainManByPartnerUser]
	@ReservationCode varchar(10)
AS
BEGIN
	DECLARE @PartnerUserKey int
		  , @PartnerUserAddress varchar(250)
		  , @PartnerUserName varchar(70)
		  , @PartnerUserPhone varchar(50)
		  , @PartnerUserEmail varchar(50)
		  , @PartnerUserPassport varchar(18)
		  , @MainManName varchar(70)
		  , @MainManPhone varchar(50)
		  , @MainManEmail varchar(50)
		  , @MainManAddress varchar(320)
		  , @MainManPassport varchar(70);
	SELECT @PartnerUserKey = DG_DUPUSERKEY 
	  FROM [dbo].[TBL_DOGOVOR] 
	 WHERE DG_CODE = @ReservationCode;
	IF(ISNULL(@PartnerUserKey,0)<>0)
	BEGIN
		SELECT @MainManName = DG_MAINMEN
			 , @MainManPhone = DG_MAINMENPHONE
			 , @MainManEmail = DG_MAINMENEMAIL
			 , @MainManAddress = DG_MAINMENADRESS
			 , @MainManPassport = DG_MAINMENPASPORT
		  FROM [dbo].[TBL_DOGOVOR]
		 WHERE DG_CODE = @ReservationCode;
		IF ((ISNULL(@MainManName,'') = '') AND (ISNULL(@MainManPhone,'') = '')
		    AND (ISNULL(@MainManEmail,'') = '') 
			AND (ISNULL(@MainManAddress,'') = '') AND (ISNULL(@MainManPassport,'') = ''))
		BEGIN
			SELECT @PartnerUserName = SUBSTRING(ISNULL(US_FULLNAME,''),1,70)
				 , @PartnerUserPhone = ISNULL(US_PHONE,'')
				 , @PartnerUserEmail = ISNULL(US_EMAIL,'')
				 , @PartnerUserAddress = ISNULL(US_ADDRESS,'')
				 , @PartnerUserPassport = ISNULL(US_PassportCode,'') + ' ' + ISNULL(US_PassportNo,'')
			  FROM [dbo].[DUP_USER]
			 WHERE US_KEY = @PartnerUserKey;
			EXEC [dbo].[UpdateReservationMainMan] @PartnerUserName, @PartnerUserPhone
												, @PartnerUserEmail
												, @PartnerUserAddress, @PartnerUserPassport
												, @ReservationCode;
		END
	END
END

GO

/*********************************************************************/
/* end sp_UpdateReservationMainManByPartnerUser.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_UpdateReservationMainManByTourist.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UpdateReservationMainManByTourist]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[UpdateReservationMainManByTourist]
GO
CREATE PROCEDURE [dbo].[UpdateReservationMainManByTourist]
(
	@Name varchar(35),
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
	@PassportNumber varchar(10),
	@ReservationCode varchar(10)
)
AS
BEGIN
	DECLARE @ManName varchar(70)
		  , @ManPhone varchar(50)
		  , @ManEmail varchar(50)
		  , @ManAddress varchar(320)
		  , @ManPassport varchar(70)
		  , @ManSName char(15);
	SET @ManSName = ISNULL(@SName,'');
	SET @ManName = ISNULL(@Name,'') +' '+ ISNULL(@FName,'') +' '+ @ManSName;
	IF (LEN(ISNULL(@Phone,'')) > 30)
		SET @ManPhone = SUBSTRING(@Phone,1,30);
	ELSE
		SET @ManPhone = ISNULL(@Phone,'');
	IF (LEN(ISNULL(@Email,'')) > 50)
		SET @ManEmail = SUBSTRING(@Email,1,50);
	ELSE
		SET @ManEmail = ISNULL(@Email,'');
	SET @ManAddress = ISNULL(@PostIndex,'');
	IF(LEN(ISNULL(@PostCity,'')) > 0)
		SET @ManAddress = @ManAddress + ', ' + @PostCity;
	IF(LEN(ISNULL(@PostStreet,'')) > 0)
		SET @ManAddress = @ManAddress + ', ' + @PostStreet;
	IF(LEN(ISNULL(@PostBuilding,'')) > 0)
		SET @ManAddress = @ManAddress + ', д. ' + @PostBuilding;
	IF(LEN(ISNULL(@PostFlat,'')) > 0)
		SET @ManAddress = @ManAddress + ',' + ' кв. ' + @PostFlat;
	SET @ManPassport = ISNULL(@PassportSeries,'') +' '+ISNULL(@PassportNumber,'');
	EXEC [dbo].[UpdateReservationMainMan] @ManName, @ManPhone, @ManEmail, @ManAddress
	                                    , @ManPassport, @ReservationCode
END
GO

grant exec on [dbo].[UpdateReservationMainManByTourist] to public
go
/*********************************************************************/
/* end sp_UpdateReservationMainManByTourist.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_CostOffersReCalculate.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CostOffersReCalculate]'))
DROP TRIGGER [dbo].[T_CostOffersReCalculate]
GO
CREATE trigger [dbo].[T_CostOffersReCalculate] on [dbo].[CostOffers]
    after update
as
	--<data>2012-12-20</data>
	--<version>9.18.1</version>
begin
	-- если была запись, то не запускаем тригер
	if exists (select 1 
				from Debug join inserted on db_n1 = CO_Id 
				where db_Mod = 'COS'
				and dateadd(minute, 5, db_Date) >= getdate())
	begin
		return;
	end

	-- временная таблица для цен
	declare @spadIdTable table
	(
		spadId bigint,
		activ bit
	)
	-- временная таблица для цен на будущие даты
	declare @spndIdTable table
	(
		spndId bigint
	)

	-- активация, и деактивация только при изменении поля SO_State на 1 или 2
	if (	exists ( select top 1 1 from inserted where CO_State = 1 or CO_State = 2)
		and exists ( select top 1 1 from deleted) 
		and update(CO_State)
		)
	begin
		insert into @spadIdTable (spadId, activ)
		select spad.SPAD_Id, 1
		from (dbo.TP_ServicePriceActualDate as spad with (nolock)
				join dbo.TP_ServiceCalculateParametrs as scp with (nolock) on spad.SPAD_SCPId = scp.SCP_Id
				join dbo.TP_ServiceComponents as sc with (nolock) on scp.SCP_SCId = sc.SC_Id)
				cross join
			(deleted as d
				join inserted as i on d.CO_Id = i.CO_Id
				join dbo.CostOfferServices as [cos] with (nolock) on i.CO_Id = [cos].COS_COID
				join dbo.Seasons as seas with (nolock) on i.CO_SeasonId = seas.SN_Id)
		where
			-- должны публиковаться только последние актуальные цены
			spad.SPAD_SaleDate is null
			and seas.SN_IsActive = 1			
			and SC_SVKey = i.CO_SVKey
			and sc.SC_Code = [cos].COS_CODE
			and scp.SCP_PKKey = i.CO_PKKey
			and SC_PRKey = i.CO_PartnerKey
			-- и только если он ранее был неактивирован или мы его деактивировали
			and ((d.CO_State = 0 and i.CO_State = 1)
					or (d.CO_State = 1 and i.CO_State = 2))
			--mv 13102012 для индекса	
			and scp.SCP_SvKey = i.CO_SVKey
			--mv 13102012 дата заезда при отборе должна быть ограничена датами заезда в ценах
			and scp.SCP_DateCheckIn between  
						(SELECT MIN(ISNULL(CS_CHECKINDATEBEG,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey) 
					and (SELECT MAX(ISNULL(CS_CHECKINDATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey)
			--mv 13102012 дата заезда должна быть больше текущей даты
			and scp.SCP_DateCheckIn >= DATEADD(DAY,-1,GetDate())
			--mv 13102012 дата заезда не можеть быть больше максимальной даты в ценах
			and scp.SCP_DateCheckIn <= (SELECT MAX(ISNULL(CS_DATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey)
			--mv 13102012 дата заезда + продолжительность тура не можеть быть меньше, чем минимальная дата в ценах
			and DATEADD(DAY, scp.SCP_TourDays, scp.SCP_DateCheckIn) >= (SELECT MIN(ISNULL(CS_DATE,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey)
		
					
		-- в ценах которые расчитали на будущее, тоже нужно пересчитать	
		insert into @spndIdTable (spndId)
		select spnd.SPND_Id
		from (dbo.TP_ServicePriceNextDate as spnd with (nolock)
				join dbo.TP_ServiceCalculateParametrs as scp with (nolock) on spnd.SPND_SCPId = scp.SCP_Id
				join dbo.TP_ServiceComponents as sc with (nolock) on scp.SCP_SCId = sc.SC_Id)
				cross join
			(deleted as d
				join inserted as i on d.CO_Id = i.CO_Id
				join dbo.CostOfferServices as [cos] with (nolock) on i.CO_Id = [cos].COS_COID
				join dbo.Seasons as seas with (nolock) on i.CO_SeasonId = seas.SN_Id)
		where			
			seas.SN_IsActive = 1
			and SC_SVKey = i.CO_SVKey
			and sc.SC_Code = [cos].COS_CODE
			and scp.SCP_PKKey = i.CO_PKKey
			and SC_PRKey = i.CO_PartnerKey
			-- и только если он ранее был неактивирован или мы его деактивировали
			and ((d.CO_State = 0 and i.CO_State = 1)
					or (d.CO_State = 1 and i.CO_State = 2))
			--mv 13102012 для индекса	
			and scp.SCP_SvKey = i.CO_SVKey
			--mv 13102012 дата заезда при отборе должна быть ограничена датами заезда в ценах
			and scp.SCP_DateCheckIn between  
						(SELECT MIN(ISNULL(CS_CHECKINDATEBEG,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey) 
					and (SELECT MAX(ISNULL(CS_CHECKINDATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey)
			--mv 13102012 дата заезда должна быть больше текущей даты
			and scp.SCP_DateCheckIn >= DATEADD(DAY,-1,GetDate())
			--mv 13102012 дата заезда не можеть быть больше максимальной даты в ценах
			and scp.SCP_DateCheckIn <= (SELECT MAX(ISNULL(CS_DATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey)
			--mv 13102012 дата заезда + продолжительность тура не можеть быть меньше, чем минимальная дата в ценах
			and DATEADD(DAY, scp.SCP_TourDays, scp.SCP_DateCheckIn) >= (SELECT MIN(ISNULL(CS_DATE,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey)
			
				
		while(exists (select top 1 1 from @spndIdTable))
		begin			
			update top (10000) spnd
			set spnd.SPND_NeedApply = 1,
			spnd.SPND_DateLastChange = getdate()
			from dbo.TP_ServicePriceNextDate as spnd join @spndIdTable on spnd.SPND_Id = spndId
			
			delete @spndIdTable 
			where exists (	select top 1 1 
							from dbo.TP_ServicePriceNextDate as spnd with(nolock) 
							where spnd.SPND_Id = spndId
							and spnd.SPND_NeedApply = 1)
		end
		
		delete @spndIdTable
	end	
		
	-- публикация, только при изменении поля CO_DateLastPublish и при 
	if (	exists ( select top 1 1 from inserted) 
		and exists ( select top 1 1 from deleted) 
		and update(CO_DateLastPublish)
		)
	begin		
		insert into @spadIdTable (spadId, activ)
		select spad.SPAD_Id, 0
		from (dbo.TP_ServicePriceActualDate as spad with (nolock)
				join dbo.TP_ServiceCalculateParametrs as scp with (nolock) on spad.SPAD_SCPId = scp.SCP_Id
				join dbo.TP_ServiceComponents as sc with (nolock) on scp.SCP_SCId = sc.SC_Id)
				cross join
			(deleted as d
				join inserted as i on d.CO_Id = i.CO_Id
				join dbo.CostOfferServices as [cos] with (nolock) on i.CO_Id = [cos].COS_COID
				join dbo.Seasons as seas with (nolock) on i.CO_SeasonId = seas.SN_Id)
		where
			-- должны публиковаться только последние актуальные цены
			spad.SPAD_SaleDate is null
			and seas.SN_IsActive = 1			
			and SC_SVKey = i.CO_SVKey
			and sc.SC_Code = [cos].COS_CODE
			and scp.SCP_PKKey = i.CO_PKKey
			and SC_PRKey = i.CO_PartnerKey
			-- дата публикации должна измениться
			and isnull(i.CO_DateLastPublish, '1900-01-01') != isnull(d.CO_DateLastPublish, '1900-01-01')
			-- и дата продажи ценового блока должна быть вокруг текущей даты
			and getdate() between isnull(i.CO_SaleDateBeg, '1900-01-01') and isnull(i.CO_SaleDateEnd, '2072-01-01')
			--mv 13102012 для индекса	
			and scp.SCP_SvKey = i.CO_SVKey
			--mv 13102012 дата заезда при отборе должна быть ограничена датами заезда в ценах
			and scp.SCP_DateCheckIn between  
						(SELECT MIN(ISNULL(CS_CHECKINDATEBEG,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey) 
					and (SELECT MAX(ISNULL(CS_CHECKINDATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey)
			--mv 13102012 дата заезда должна быть больше текущей даты
			and scp.SCP_DateCheckIn >= DATEADD(DAY,-1,GetDate())
			--mv 13102012 дата заезда не можеть быть больше максимальной даты в ценах
			and scp.SCP_DateCheckIn <= (SELECT MAX(ISNULL(CS_DATEEND,'01-01-2100')) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey)
			--mv 13102012 дата заезда + продолжительность тура не можеть быть меньше, чем минимальная дата в ценах
			and DATEADD(DAY, scp.SCP_TourDays, scp.SCP_DateCheckIn) >= (SELECT MIN(ISNULL(CS_DATE,DATEADD(DAY,-1,GetDate()))) FROM dbo.tbl_costs with (nolock) WHERE CS_COID = i.CO_Id and CS_CODE = sc.SC_Code and CS_SVKEY = i.CO_SVKey)
	end
	
	while(exists (select top 1 1 from @spadIdTable))
	begin			
		update top (10000) spad
		set 
		spad.SPAD_NeedApply = case when activ = 0 then spad.SPAD_NeedApply else 1 end,
		spad.SPAD_AutoOnline = case when activ = 1 then spad.SPAD_AutoOnline else 1 end,
		spad.SPAD_DateLastChange = getdate()
		from dbo.TP_ServicePriceActualDate as spad join @spadIdTable on spad.SPAD_Id = spadId
		
		delete @spadIdTable 
		where exists (	select top 1 1 
						from dbo.TP_ServicePriceActualDate as spad with(nolock) 
						where spad.SPAD_Id = spadId 
						and ((spad.SPAD_NeedApply = 1 and activ = 1)
								or (spad.SPAD_AutoOnline = 1 and activ = 0)))
	end
end
go
/*********************************************************************/
/* end T_CostOffersReCalculate.sql */
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
--<VERSION>2009.2.17.2</VERSION>
--<DATE>2012-12-12</DATE>
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
			EXEC @nHIID = dbo.InsHistory @NDL_DgCod, @nDGKey, 2, @DL_Key, @sMod, @sHI_Text, '', 0, '', 0, @nSVKey
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
		
		/*Запись о том что нужно квотировать услугу*/
		-- только при измении этих полей нужно перезапустить механиз квотирования
		if ((isnull(@ODL_SvKey, '') != isnull(@NDL_SvKey, '')
			or isnull(@ODL_Code, '') != isnull(@NDL_Code, '')
			or isnull(@ODL_SubCode1, '') != isnull(@NDL_SubCode1, '')
			or isnull(@ODL_PartnerKey, '') != isnull(@NDL_PartnerKey, '')
			or isnull(@ODL_sDateBeg, '') != isnull(@NDL_sDateBeg, '')
			or isnull(@ODL_sDateEnd, '') != isnull(@NDL_sDateEnd, '')
			or isnull(@ODL_NMen, '') != isnull(@NDL_NMen, ''))
			and (exists (select top 1 1 from [Service] where SV_KEY = @NDL_SvKey and SV_QUOTED = 1))
			and (@sMod = 'UPD'))
		begin
			-- создаем запись о необходимости произвести рассадку в квоту
			insert into DogovorListNeedQuoted (DLQ_DLKey, DLQ_Date, DLQ_State, DLQ_Host, DLQ_User)
			values (@DL_Key, getdate(), 0, host_name(), user_name())
		end
		
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
				EXECUTE dbo.InsHistory @NDL_DgCod, @NDL_DGKey, 2, @DL_Key, 'MOD', @ODL_Name, '', 1, '', 0, @nSVKey

			If 	(ISNULL(@ODL_Wait, '') != ISNULL(@NDL_Wait, '')) 
			BEGIN
				If (@NDL_Wait = 1)
					EXECUTE dbo.InsHistory @NDL_DgCod, @NDL_DGKey, 2, @DL_Key, '+WL', @ODL_Name, '', 0, '', 0, @nSVKey
				else
					EXECUTE dbo.InsHistory @NDL_DgCod, @NDL_DGKey, 2, @DL_Key, '-WL', @ODL_Name, '', 0, '', 0, @nSVKey
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
/* begin T_mwDeleteTour.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='TR' and name='mwDeleteTour')
	drop trigger dbo.mwDeleteTour
go

CREATE trigger [dbo].[mwDeleteTour] on [dbo].[TP_Tours]
for delete
as
begin

	--<VERSION>2009.2.17</VERSION>
	--<DATE>2013-01-14</DATE>

	if dbo.mwReplIsSubscriber() > 0
	begin
		insert into [mwReplQueue]([rq_mode], [rq_tokey])
		select 4, to_key
		from deleted
	end
	else if dbo.mwReplIsPublisher() <= 0
	begin

		declare @tableName nvarchar(100), @sql nvarchar(4000), @tokey int, @cnKey int, @ctDepartureKey int
		if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
		begin
			--Используется секционирование ценовых таблиц
			declare disableCursor cursor fast_forward read_only for
			select 
				to_key, dbo.mwGetPriceTableName(to_cnkey, tl_ctdeparturekey), to_cnkey, tl_ctdeparturekey
			from 
				deleted inner join tbl_turlist with(nolock) on to_trkey = tl_key

			open disableCursor
			fetch next from disableCursor into @tokey, @tableName, @cnKey, @ctDepartureKey
		
			while @@fetch_status = 0
			begin
				--koshelev 9454
				exec dbo.mwCreateNewPriceTable @cnKey, @ctDepartureKey
			
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

				fetch next from disableCursor into @tokey, @tableName, @cnKey, @ctDepartureKey
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

end

GO
/*********************************************************************/
/* end T_mwDeleteTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_mwInsertTour.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[mwInsertTour]'))
	DROP TRIGGER [dbo].[mwInsertTour]
GO

CREATE trigger [dbo].[mwInsertTour] on [dbo].[mwReplTours] for insert
as
begin
	--<VERSION>2009.2.18</VERSION>
	--<DATE>2013-01-15</DATE>
	if dbo.mwReplIsSubscriber() > 0
	begin
		SELECT rt_tokey as trkey, RT_CalcKey as calcKey, rt_trkey as tlkey, rt_overwritePrices as overwritePrices, rt_updateOnlinePrices as updateOnlinePrices
		INTO #tmpKeys 
		FROM inserted

		declare replcur cursor fast_forward read_only for
		select trkey, calcKey, tlkey, overwritePrices, updateOnlinePrices from #tmpKeys

		declare @trkey int, @calcKey int, @tlkey int, @overwritePrices bit, @updateOnlinePrices smallint

		open replcur

		fetch next from replcur into @trkey, @calcKey, @tlkey, @overwritePrices, @updateOnlinePrices
		while(@@fetch_status = 0)
		begin
			-- проверка: можно ли выставлять этот тур на этой базе
			-- MEG00040028. 09.02.2012. Golubinsky
			-- вынес проверку в функцию 
			if dbo.mwIsTourAllowedForPublish(@tlkey) = 1
			begin
				if (@calcKey = 0 or @calcKey is null)
				begin
					insert into [mwReplQueue]([rq_mode], [rq_tokey], [RQ_CalculatingKey], [RQ_OverwritePrices])
					values(1, @trkey, @calcKey, @overwritePrices)
				end
				else if (ISNULL(@updateOnlinePrices, 0) <> 2)
				begin
					insert into [mwReplQueue]([rq_mode], [rq_tokey], [RQ_CalculatingKey], [RQ_OverwritePrices])
					values(2, @trkey, @calcKey, @overwritePrices)
				end
				else
				begin
					insert into [mwReplQueue]([rq_mode], [rq_tokey], [RQ_CalculatingKey], [RQ_OverwritePrices])
					values(6, @trkey, @calcKey, @overwritePrices)
				end
			end
			fetch next from replcur into @trkey, @calcKey, @tlkey, @overwritePrices, @updateOnlinePrices
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
/* begin sp_RecreateDependentObjects.sql */
/*********************************************************************/
if exists(select top 1 1 from sys.objects where name = 'RecreateDependentObjects' and type = 'P')
	drop procedure RecreateDependentObjects
go

create procedure RecreateDependentObjects
-- выполняет указанный скрипт после удаления и до создания зависимых от колонки @ColumnName объектов
-- сейчас в качестве зависимых объектов поддерживаются только некластеризованные индексы
--<VERSION>9.2.19</VERSION>
--<DATE>2013-08-26</DATE>
(
	@TableName sysname,				-- имя таблицы, колонка которой удаляется
	@ColumnName sysname,			-- имя удаляемой колонки
	@CustomScript nvarchar(max),	-- скрипт, выполняемый между созданием и удалением зависимых объектов
	@recreateWithoutColumn bit = 0	-- флаг, указывающий, что в зависимые объекты надо пересоздавать без переданной колонки
)
as
begin
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
		if @ixType <> 2
		begin
			set @errmsg = 'Not supported index type is dependent on specified column ' + @ColumnName + '
			This stored procedure supports only nonclustered indexes recreation! Not supported index name: ' 
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
			create nonclustered index [@ixName] on [@TableName]
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
/* begin (2013.03.22)_Alter_Accmdmentype_Recreate_CalculatedColumns.sql */
/*********************************************************************/
-- Task 10657 10.01.2013
exec RecreateDependentObjects 'Accmdmentype', 'AC_NRealPlaces',
'if exists (select top 1 1 from sys.columns col left join sys.tables tab on col.object_id = tab.object_id where col.name = ''AC_NRealPlaces'' and tab.name = ''Accmdmentype'')
ALTER TABLE [dbo].[Accmdmentype]
   DROP COLUMN AC_NRealPlaces 

ALTER TABLE [dbo].[Accmdmentype]
   ADD AC_NRealPlaces AS ( 
   (case when [AC_NADMAIN] IS NULL AND [AC_NCHMAIN] IS NULL then NULL 
   else isnull([AC_NADMAIN],(0))+isnull([AC_NCHMAIN],(0)) end) )
'

exec RecreateDependentObjects 'Accmdmentype', 'AC_NMenExBed', '
if exists (select top 1 1 from sys.columns col left join sys.tables tab on col.object_id = tab.object_id where col.name = ''AC_NMenExBed'' and tab.name = ''Accmdmentype'')
ALTER TABLE [dbo].[Accmdmentype]
   DROP COLUMN AC_NMenExBed 

ALTER TABLE [dbo].[Accmdmentype]
   ADD AC_NMenExBed AS ( 
   (case when [AC_NADEXTRA] IS NULL AND [AC_NCHEXTRA] IS NULL then NULL 
   else isnull([AC_NADEXTRA],(0))+isnull([AC_NCHEXTRA],(0)) end) )
'

if exists (select top 1 1 from sys.fn_listextendedproperty('MS_Description', 'SCHEMA', 'dbo', 'TABLE', 'Accmdmentype', 'COLUMN', 'AC_NRealPlaces'))
	exec sp_dropextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Accmdmentype', @level2type=N'COLUMN',@level2name=N'AC_NRealPlaces'

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Реальное количество основных мест' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Accmdmentype', @level2type=N'COLUMN',@level2name=N'AC_NRealPlaces'
GO

if exists (select top 1 1 from sys.fn_listextendedproperty('MS_Description', 'SCHEMA', 'dbo', 'TABLE', 'Accmdmentype', 'COLUMN', 'AC_NMenExBed'))
	exec sp_dropextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Accmdmentype', @level2type=N'COLUMN',@level2name=N'AC_NMenExBed'

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Количество дополнительных мест' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Accmdmentype', @level2type=N'COLUMN',@level2name=N'AC_NMenExBed'
GO

if dbo.mwReplIsPublisher() > 0
begin
	if exists (select top 1 1 from sys.databases where name = 'distribution')
	begin
		if exists (select * from distribution.dbo.mspublications
								where publication = 'MW_PUB'
									and publisher_db = db_name())
		begin
			if exists (select * 
							from distribution.dbo.msarticles
							where publisher_db = db_name()
								and source_object = 'Accmdmentype'
								and publication_id = (select publication_id from distribution.dbo.mspublications
														where publication = 'MW_PUB')
							)
			begin
				-- если используется репликация, надо добавить новые колонки в синхронизацию
				exec sp_articlecolumn @publication = N'MW_PUB', @article = N'Accmdmentype', @column = N'AC_NADMAIN', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
				exec sp_articlecolumn @publication = N'MW_PUB', @article = N'Accmdmentype', @column = N'AC_NCHMAIN', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
				exec sp_articlecolumn @publication = N'MW_PUB', @article = N'Accmdmentype', @column = N'AC_NADEXTRA', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
				exec sp_articlecolumn @publication = N'MW_PUB', @article = N'Accmdmentype', @column = N'AC_NCHEXTRA', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
				exec sp_articlecolumn @publication = N'MW_PUB', @article = N'Accmdmentype', @column = N'AC_NCHISINFMAIN', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
				exec sp_articlecolumn @publication = N'MW_PUB', @article = N'Accmdmentype', @column = N'AC_NCHISINFEXTRA', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
			end
		end
	end
end
else if dbo.mwReplIsSubscriber() > 0
begin
begin try
	declare @publicationName as varchar(100), @pubDBName as varchar(50)
	declare @sql nvarchar(max)

	set @publicationName = 'MW_PUB'
	set @sql = 'select @pubDBName = publisher_db from mt.distribution.dbo.MSpublications 
						where publication = ''' + ltrim(rtrim(@publicationName)) + ''''

	exec sp_executesql @sql, N'@pubDBName varchar(50) output', @pubDBName output

	set @sql = '
		-- синхронизируем данные
		update Accmdmentype
		set Accmdmentype.AC_CODE = pub.AC_CODE ,Accmdmentype.AC_NAME = pub.AC_NAME ,Accmdmentype.AC_MAIN = pub.AC_MAIN ,Accmdmentype.AC_AGEFROM = pub.AC_AGEFROM ,Accmdmentype.AC_AGETO = pub.AC_AGETO ,Accmdmentype.AC_CREATOR = pub.AC_CREATOR ,Accmdmentype.AC_UPDATEDATE = pub.AC_UPDATEDATE ,Accmdmentype.AC_Order = pub.AC_Order ,Accmdmentype.AC_StdKey = pub.AC_StdKey ,Accmdmentype.AC_CINNUM = pub.AC_CINNUM ,Accmdmentype.AC_AgeFrom2 = pub.AC_AgeFrom2 ,Accmdmentype.AC_AgeTo2 = pub.AC_AgeTo2 ,Accmdmentype.AC_Unicode = pub.AC_Unicode ,Accmdmentype.AC_NAMELAT = pub.AC_NAMELAT ,Accmdmentype.AC_PERROOM = pub.AC_PERROOM ,Accmdmentype.AC_NADMAIN = pub.AC_NADMAIN ,Accmdmentype.AC_NCHMAIN = pub.AC_NCHMAIN ,Accmdmentype.AC_NADEXTRA = pub.AC_NADEXTRA ,Accmdmentype.AC_NCHEXTRA = pub.AC_NCHEXTRA ,Accmdmentype.AC_NCHISINFMAIN = pub.AC_NCHISINFMAIN ,Accmdmentype.AC_NCHISINFEXTRA = pub.AC_NCHISINFEXTRA 
		from mt.[@pubDBName].dbo.Accmdmentype as pub
		where Accmdmentype.AC_KEY = pub.AC_KEY 
		and (ISNULL(Accmdmentype.AC_CODE, 0) <> ISNULL(pub.AC_CODE, 0) OR ISNULL(Accmdmentype.AC_NAME, 0) <> ISNULL(pub.AC_NAME, 0) OR ISNULL(Accmdmentype.AC_MAIN, 0) <> ISNULL(pub.AC_MAIN, 0) OR ISNULL(Accmdmentype.AC_AGEFROM, 0) <> ISNULL(pub.AC_AGEFROM, 0) OR ISNULL(Accmdmentype.AC_AGETO, 0) <> ISNULL(pub.AC_AGETO, 0) OR ISNULL(Accmdmentype.AC_CREATOR, 0) <> ISNULL(pub.AC_CREATOR, 0) OR ISNULL(Accmdmentype.AC_UPDATEDATE, 0) <> ISNULL(pub.AC_UPDATEDATE, 0) OR ISNULL(Accmdmentype.AC_Order, 0) <> ISNULL(pub.AC_Order, 0) OR ISNULL(Accmdmentype.AC_StdKey, 0) <> ISNULL(pub.AC_StdKey, 0) OR ISNULL(Accmdmentype.AC_CINNUM, 0) <> ISNULL(pub.AC_CINNUM, 0) OR ISNULL(Accmdmentype.AC_AgeFrom2, 0) <> ISNULL(pub.AC_AgeFrom2, 0) OR ISNULL(Accmdmentype.AC_AgeTo2, 0) <> ISNULL(pub.AC_AgeTo2, 0) OR ISNULL(Accmdmentype.AC_Unicode, 0) <> ISNULL(pub.AC_Unicode, 0) OR ISNULL(Accmdmentype.AC_NAMELAT, 0) <> ISNULL(pub.AC_NAMELAT, 0) OR ISNULL(Accmdmentype.AC_PERROOM, 0) <> ISNULL(pub.AC_PERROOM, 0) OR ISNULL(Accmdmentype.AC_NADMAIN, 0) <> ISNULL(pub.AC_NADMAIN, 0) OR ISNULL(Accmdmentype.AC_NCHMAIN, 0) <> ISNULL(pub.AC_NCHMAIN, 0) OR ISNULL(Accmdmentype.AC_NADEXTRA, 0) <> ISNULL(pub.AC_NADEXTRA, 0) OR ISNULL(Accmdmentype.AC_NCHEXTRA, 0) <> ISNULL(pub.AC_NCHEXTRA, 0) OR ISNULL(Accmdmentype.AC_NCHISINFMAIN, 0) <> ISNULL(pub.AC_NCHISINFMAIN, 0) OR ISNULL(Accmdmentype.AC_NCHISINFEXTRA, 0) <> ISNULL(pub.AC_NCHISINFEXTRA, 0))
				
		delete from Accmdmentype where AC_KEY not in (select AC_KEY from mt.[@pubDBName].dbo.Accmdmentype)

		insert into Accmdmentype( AC_KEY,AC_CODE,AC_NAME,AC_MAIN,AC_AGEFROM,AC_AGETO,AC_CREATOR,AC_UPDATEDATE,AC_Order,AC_StdKey,AC_CINNUM,AC_AgeFrom2,AC_AgeTo2,AC_Unicode,AC_NAMELAT,AC_PERROOM,AC_Description,AC_NADMAIN,AC_NCHMAIN,AC_NADEXTRA,AC_NCHEXTRA,AC_NCHISINFMAIN,AC_NCHISINFEXTRA ) 
		select AC_KEY,AC_CODE,AC_NAME,AC_MAIN,AC_AGEFROM,AC_AGETO,AC_CREATOR,AC_UPDATEDATE,AC_Order,AC_StdKey,AC_CINNUM,AC_AgeFrom2,AC_AgeTo2,AC_Unicode,AC_NAMELAT,AC_PERROOM,AC_Description,AC_NADMAIN,AC_NCHMAIN,AC_NADEXTRA,AC_NCHEXTRA,AC_NCHISINFMAIN,AC_NCHISINFEXTRA 
		from mt.[@pubDBName].dbo.Accmdmentype pub 
		where pub.AC_KEY not in (select AC_KEY from Accmdmentype) 
		'
	set @sql = replace(@sql, '@pubDBName', @pubDBName)
	exec(@sql)
end try
begin catch
	declare @errMsg as nvarchar(max)
	set @errMsg = 'Произошла ошибка при синхронизации таблицы Accmdmentype: ' + error_message()
	RAISERROR(@errMsg, 16, 1)
end catch
end
GO
/*********************************************************************/
/* end (2013.03.22)_Alter_Accmdmentype_Recreate_CalculatedColumns.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplUpdatePriceEnabledAndValue.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwReplUpdatePriceEnabledAndValue]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwReplUpdatePriceEnabledAndValue]
GO

CREATE proc [dbo].[mwReplUpdatePriceEnabledAndValue] @tokey int, @calcKey int, @rqId int = null
as
begin
	-- <date>2012-09-20</date>
	-- <version>2009.2.16.1</version>
	
	declare @ctFromKey int, @cnKey int
	declare @tableName varchar(500)
	declare @mwSearchType int
	declare @source varchar(200), @sql nvarchar(max)
	set @source = ''
	
	if dbo.mwReplIsSubscriber() > 0 and len(dbo.mwReplPublisherDB()) > 0
		set @source = '[mt].' + dbo.mwReplPublisherDB() + '.'
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start mwReplUpdatePriceEnabledAndValue'
		
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'
	
	if (@mwSearchType = 0)
	begin
		set @tableName = 'mwPriceDataTable'
	end
	else
	begin
		select @ctFromKey = TL_CTDepartureKey, @cnKey = TO_CNKey
		from Turlist join TP_Tours on TL_KEY = TO_TRKey
		where TO_Key = @tokey
		
		set @tableName = dbo.mwGetPriceTableName(@cnKey, @ctFromKey)		
	end
	
	set @sql = 'update ' + @tableName + ' set pt_isenabled = 1, pt_price = tp_gross'
	set @sql = @sql + ' from ' + @source + 'dbo.tp_prices'
	set @sql = @sql + ' where pt_pricekey = tp_key and tp_calculatingkey = ' + ltrim(STR(@calcKey))
	
	print (@sql)
	
	exec (@sql)
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'End mwReplUpdatePriceEnabledAndValue'
end
GO

GRANT EXEC ON [dbo].[mwReplUpdatePriceEnabledAndValue] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwReplUpdatePriceEnabledAndValue.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplProcessQueueUpdate.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwReplProcessQueueUpdate')
	drop proc dbo.mwReplProcessQueueUpdate
go

-- Параллельная обработка очереди туров
create procedure [dbo].[mwReplProcessQueueUpdate]
as
begin
	--<VERSION>2009.2</VERSION>
	--<DATE>2013-01-15</DATE>

	if dbo.mwReplIsSubscriber() <= 0
		return

	declare @tokey int, @calcKey int, @rqId int, @error smallint
	declare curs cursor local fast_forward for
	select rq_tokey, rq_CalculatingKey, rq_id
	from mwReplQueue
	where rq_mode = 6 
	and rq_startdate is null
	order by rq_id asc

	set @error = 0

	open curs

	fetch curs into @tokey, @calcKey, @rqId

	while (@@FETCH_STATUS = 0)
	begin
		print @rqId
		begin try
			update mwReplQueue set rq_startdate = GETDATE() where [rq_id] = @rqId
			exec [dbo].[mwReplUpdatePriceEnabledAndValue] @tokey, @calcKey, @rqId
		end try
		begin catch
			update mwReplQueue set [rq_state] = 4, [rq_enddate] = getdate() where [rq_id] = @rqId
			
			declare @errMessage varchar(max)
			set @errMessage = 'Error at ' + isnull(ERROR_PROCEDURE(), '[mwReplProcessQueueDivide]') +' : ' + isnull(ERROR_MESSAGE(), '[msg_not_set]')
			
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
			select @rqId, @errMessage
			set @error = 1
			
		end catch
		
		if (@error = 0)
		begin
			update mwReplQueue set [rq_state] = 5, [rq_enddate] = getdate() where [rq_id] = @rqId
		
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
			select @rqId, 'Command complete.'
		end
		else
		begin
			set @error = 0
		end
		
		fetch curs into @tokey, @calcKey, @rqId
	end

	close curs
	deallocate curs

end
GO

grant exec on [dbo].[mwReplProcessQueueUpdate] to public
GO
/*********************************************************************/
/* end sp_mwReplProcessQueueUpdate.sql */
/*********************************************************************/

update [dbo].[setting] set st_version = '9.2.17.4', st_moduledate = convert(datetime, '2013-08-23', 120),  st_financeversion = '9.2.17.4', st_financedate = convert(datetime, '2013-08-23', 120) 
 GO
 UPDATE dbo.SystemSettings SET SS_ParmValue='2013-08-23' WHERE SS_ParmName='SYSScriptDate'
 GO 
