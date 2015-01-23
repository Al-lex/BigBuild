-- (091016)IsTourDurationCalculated.sql
-- 7.2 - 9.2
if not exists (select * from desctypes where dt_key = 129)
	insert into desctypes (dt_key, dt_name, dt_tableid, dt_order) values (129,'Возможность изменять продолжительность тура только на обсчитанную', 36, 1)
else
	print 'Внимание! Значение настройки с ключом 129 должно быть Возможность изменять продолжительность тура только на обсчитанную'
go

-- sp_DogListToQuotas.sql
-- 7.2 - 9.2
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
						if exists (select SS_ParmValue from systemsettings where SS_ParmName=''SYSCheckQuotaRelease'' and SS_ParmValue=1)
							SET @DATETEMP=''10-JAN-1900''
						IF @prev=1'
		Set @Query = @Query + '	SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release FROM QuotaParts QP1, QuotaDetails QD1, Quotas QT1, QuotaObjects
								WHERE ' + @SubQuery + ' and QD_Date=DATEADD(DAY,@n1-1,@CurrentDate)
									and (QP_Places-QP_Busy)>0 and QP_Durations=@durations_prev and QD_Release=@release_prev
									and not exists (SELECT SS_ID FROM StopSales WHERE SS_QDID=QD_ID and SS_QOID=QO_ID and SS_Date=DATEADD(DAY,@n1-1,@CurrentDate) and (SS_IsDeleted is null or SS_IsDeleted=0))
									and not exists (SELECT QP_ID FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2 
									WHERE ' + @SubQuery + ' and QD2.QD_Date=''' + CAST(@Q_DateFirst as varchar(20)) + '''
										and ISNULL(QD2.QD_Release,0)=ISNULL(QD1.QD_Release,0) and QP2.QP_Durations=QP1.QP_Durations and (QP_IsNotCheckIn=1 or QP_CheckInPlaces-QP_CheckInPlacesBusy <= 0))
										and QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1)			
								ORDER BY ISNULL(QD_Release,0) DESC
			ELSE'
		Set @Query = @Query + '	SELECT TOP 1 @QP_ID=QP_ID, @durations_prev=QP_Durations, @release_prev=QD_Release FROM QuotaParts QP1, QuotaDetails QD1, Quotas QT1, QuotaObjects
								WHERE ' + @SubQuery + ' and QD_Date=DATEADD(DAY,@n1-1,@CurrentDate)
									and (QP_Places-QP_Busy)>0 
									and not exists (SELECT SS_ID FROM StopSales WHERE SS_QDID=QD_ID and SS_QOID=QO_ID and SS_Date=DATEADD(DAY,@n1-1,@CurrentDate) and (SS_IsDeleted is null or SS_IsDeleted=0))
									and not exists (SELECT QP_ID FROM QuotaParts QP2, QuotaDetails QD2, Quotas QT2 
									WHERE ' + @SubQuery + ' and QD2.QD_Date=''' + CAST(@Q_DateFirst as varchar(20)) + '''
										and ISNULL(QD2.QD_Release,0)=ISNULL(QD1.QD_Release,0) and QP2.QP_Durations=QP1.QP_Durations and (QP_IsNotCheckIn=1 or QP_CheckInPlaces-QP_CheckInPlacesBusy <= 0))
										and QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1)
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

-- 091030(alter_TAble_REPORTBYWIN_add_ORDER).sql
-- 7.2 - 9.2
if not exists (select * from dbo.syscolumns where name = 'RW_ORder' and id = object_id(N'[dbo].[REPORTBYWIN]'))
	ALTER TABLE dbo.REPORTBYWIN ADD RW_ORder int null
GO

-- 091105_AlterTable_DogovorMessages.sql
-- 7.2 - 9.2
if not exists(select * from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'dogovormessages' and TABLE_SCHEMA = 'dbo' and COLUMN_NAME = 'DM_XML')
	ALTER TABLE dbo.dogovormessages ADD DM_XML text NULL
go

if not exists(select * from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'dogovormessages' and TABLE_SCHEMA = 'dbo' and COLUMN_NAME = 'DM_SENDERNAME')
	ALTER TABLE dbo.dogovormessages ADD DM_SENDERNAME nvarchar(40) NULL
go

-- 091103_AlterTableQuotaParts.sql
-- 7.2 - 9.2
if not exists (select id from dbo.syscolumns where id = object_id(N'[dbo].[QuotaParts]') and name = 'QP_LastUpdate')
	alter table dbo.QuotaParts add QP_LastUpdate datetime default GetDate()
go

-- T_ServiceByDateChanged.sql
-- 7.2 - 9.2
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_ServiceByDateChanged]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_ServiceByDateChanged]
GO
CREATE TRIGGER [dbo].[T_ServiceByDateChanged] ON [dbo].[ServiceByDate]
AFTER INSERT, UPDATE, DELETE
AS
--<VERSION>2008.1.00.09a</VERSION>
DECLARE @sMod varchar(3), @nHIID int, @sDGCode varchar(10), @nDGKey int, @sDLName varchar(150), @sTemp varchar(25), @sTemp2 varchar(255), @sTuristName varchar(55)
DECLARE @sOldValue varchar(255), @sNewValue varchar(255), @nOldValue int, @nNewValue int, @SDDate datetime
DECLARE @nRowsCount int, @sServiceStatusToHistory varchar(255)

DECLARE @SDID int, @N_SD_DLKey int, @N_SD_RLID int, @N_SD_TUKEY int, @N_SD_QPID int, @N_SD_State smallint, @N_SD_Date datetime,
		@O_SD_DLKey int, @O_SD_RLID int, @O_SD_TUKEY int, @O_SD_QPID int, @O_SD_State smallint, @O_SD_Date datetime, @QT_ByRoom bit,
		@nDelCount smallint, @nInsCount smallint, @DLDateBeg datetime, @DLNDays smallint

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED
IF (@nInsCount = 0)
BEGIN
    DECLARE cur_ServiceByDateChanged CURSOR FOR 
    SELECT 	O.SD_ID,
			O.SD_DLKey, O.SD_RLID, O.SD_TUKey, O.SD_QPID, O.SD_State, O.SD_Date,
			null, null, null, null, null, null
			--DL_DateBeg, DL_NDays
    FROM DELETED O
	--LEFT OUTER JOIN tbl_DogovorList ON O.SD_DLKey = DL_Key
END
ELSE IF (@nDelCount = 0)
BEGIN
    DECLARE cur_ServiceByDateChanged CURSOR FOR 
    SELECT 	N.SD_ID,
			null, null, null, null, null, null,
			N.SD_DLKey, N.SD_RLID, N.SD_TUKey, N.SD_QPID, N.SD_State, N.SD_Date
			--DL_DateBeg, DL_NDays
    FROM	INSERTED N
	--LEFT OUTER JOIN tbl_DogovorList ON N.SD_DLKey = DL_Key
END
ELSE 
BEGIN
    DECLARE cur_ServiceByDateChanged CURSOR FOR 
    SELECT 	N.SD_ID,
			O.SD_DLKey, O.SD_RLID, O.SD_TUKey, O.SD_QPID, O.SD_State, O.SD_Date,
	  		N.SD_DLKey, N.SD_RLID, N.SD_TUKey, N.SD_QPID, N.SD_State, N.SD_Date
			--DL_DateBeg, DL_NDays
    FROM DELETED O, INSERTED N
	--LEFT OUTER JOIN tbl_DogovorList ON N.SD_DLKey = DL_Key 
    WHERE N.SD_ID = O.SD_ID
END

select @sServiceStatusToHistory = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSServiceStatusToHistory'

OPEN cur_ServiceByDateChanged
FETCH NEXT FROM cur_ServiceByDateChanged 
	INTO @SDID, @O_SD_DLKey, @O_SD_RLID, @O_SD_TUKEY, @O_SD_QPID, @O_SD_State, @O_SD_Date,
				@N_SD_DLKey, @N_SD_RLID, @N_SD_TUKEY, @N_SD_QPID, @N_SD_State, @N_SD_Date
				--@DLDateBeg, @DLNDays
WHILE @@FETCH_STATUS = 0
BEGIN
	IF ISNULL(@O_SD_QPID,0)!=ISNULL(@N_SD_QPID,0) OR ISNULL(@O_SD_RLID,0)!=ISNULL(@N_SD_RLID,0)
	BEGIN
		If @O_SD_QPID is not null
		BEGIN			
			SELECT @QT_ByRoom=QT_ByRoom FROM Quotas,QuotaDetails,QuotaParts WHERE QD_QTID=QT_ID and QD_ID=QP_QDID and QP_ID=@O_SD_QPID
			IF @QT_ByRoom = 1
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate WHERE SD_QPID=@O_SD_QPID) WHERE QP_ID=@O_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate,QuotaParts WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@O_SD_QPID)
				--IF @O_SD_Date = @DLDateBeg
					UPDATE	QuotaParts SET QP_CheckInPlacesBusy=(
						SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate, tbl_DogovorList WHERE SD_QPID=@O_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key) 
					WHERE QP_ID=@O_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID=@O_SD_QPID) WHERE QP_ID=@O_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(*) FROM ServiceByDate,QuotaParts WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@O_SD_QPID)
				--IF @O_SD_Date = @DLDateBeg
					UPDATE	QuotaParts SET QP_CheckInPlacesBusy=(
						SELECT COUNT(*) FROM ServiceByDate, tbl_DogovorList WHERE SD_QPID=@O_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key) 
					WHERE QP_ID=@O_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
		END
		If @N_SD_QPID is not null
		BEGIN
			SELECT @QT_ByRoom=QT_ByRoom FROM Quotas,QuotaDetails,QuotaParts WHERE QD_QTID=QT_ID and QD_ID=QP_QDID and QP_ID=@N_SD_QPID
			IF @QT_ByRoom = 1
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate WHERE SD_QPID=@N_SD_QPID) WHERE QP_ID=@N_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate,QuotaParts WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@N_SD_QPID)
				--IF @N_SD_Date = @DLDateBeg
					UPDATE	QuotaParts SET QP_CheckInPlacesBusy=(
						SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate, tbl_DogovorList WHERE SD_QPID=@N_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key) 
					WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID=@N_SD_QPID) WHERE QP_ID=@N_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(*) FROM ServiceByDate,QuotaParts WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@N_SD_QPID)
				--IF @N_SD_Date = @DLDateBeg
					UPDATE	QuotaParts SET QP_CheckInPlacesBusy=(
						SELECT COUNT(*) FROM ServiceByDate, tbl_DogovorList WHERE SD_QPID=@N_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key) 
					WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
		END
	END
	IF ISNULL(@O_SD_STATE, 0) != ISNULL(@N_SD_STATE, 0) and ISNULL(@sServiceStatusToHistory, '0') != '0'
	BEGIN
		SELECT @sDGCode = DL_DGCod, @nDGKey = DL_DGKey, @sDLName = DL_Name FROM DogovorList WHERE DL_KEY = @N_SD_DLKey
		SELECT @sTuristName = TU_NAMERUS + ' ' + TU_FNAMERUS + ' ' + ISNULL(TU_SNAMERUS, '') FROM Turist WHERE TU_KEY = @N_SD_TUKEY
		set @sTemp2 = rtrim(ltrim(@sDLName)) + ', ' + @sTuristName

		--select @sTemp2 = HI_TEXT, @sDGCode = HI_DGCOD, @nDGKey = HI_DGKEY from History where HI_OAID = 19 and HI_TypeCode = @SDID

		set @sTemp = convert(varchar(25), @N_SD_Date, 104)
		if (@sTemp2 is not null)		
		begin
			set @sMod = 'UPD'
			EXEC @nHIID = dbo.InsHistory @sDGCode, @nDGKey, 19, @SDID, @sMod, @sTemp2, @sTemp, 0, ''
			
			SET @nOldValue = @O_SD_State
			SET @nNewValue = @N_SD_State

			IF ISNULL(@nOldValue, 0) = 0
				SET @sOldValue = ''
			ELSE IF @nOldValue = 1
				SET @sOldValue = 'Allotment'
			ELSE IF @nOldValue = 2
				SET @sOldValue = 'Commitment'
			ELSE IF @nOldValue = 3
				SET @sOldValue = 'Confirmed'
			ELSE IF @nOldValue = 4
				SET @sOldValue = 'Wait'

			IF ISNULL(@nNewValue, 0) = 0
				SET @sNewValue = ''
			ELSE IF @nNewValue = 1
				SET @sNewValue = 'Allotment'
			ELSE IF @nNewValue = 2
				SET @sNewValue = 'Commitment'
			ELSE IF @nNewValue = 3
				SET @sNewValue = 'Confirmed'
			ELSE IF @nNewValue = 4
				SET @sNewValue = 'Wait'

			EXECUTE dbo.InsertHistoryDetail @nHIID , 19001, @sOldValue, @sNewValue, @nOldValue, @nNewValue, null, null, 0
		end
	END
	IF ISNULL(@O_SD_TUKEY,0)!=ISNULL(@N_SD_TUKEY,0) and ISNULL(@sServiceStatusToHistory, '0') != '0'
	BEGIN
		IF (@N_SD_TUKEY is not null)
		BEGIN
			SELECT @sDGCode = DL_DGCod, @nDGKey = DL_DGKey, @sDLName = DL_Name FROM DogovorList WHERE DL_KEY = @N_SD_DLKey
			SELECT @sTuristName = TU_NAMERUS + ' ' + TU_FNAMERUS + ' ' + ISNULL(TU_SNAMERUS, '') FROM Turist WHERE TU_KEY = @N_SD_TUKEY
			SET @SDDate = @N_SD_Date
			set @sTemp2 = rtrim(ltrim(@sDLName)) + ', ' + @sTuristName
			set @sMod = 'INS'
		END
		ELSE
		BEGIN
			SET @SDDate = @O_SD_Date
			SELECT @sDGCode = DL_DGCod, @nDGKey = DL_DGKey, @sDLName = DL_Name FROM DogovorList WHERE DL_KEY = @O_SD_DLKey
			SELECT @sTuristName = TU_NAMERUS + ' ' + TU_FNAMERUS + ' ' + ISNULL(TU_SNAMERUS, '') FROM Turist WHERE TU_KEY = @O_SD_TUKEY
			set @sTemp2 = rtrim(ltrim(@sDLName)) + ', ' + @sTuristName
--			select @sTemp2 = HI_TEXT, @sDGCode = HI_DGCOD, @nDGKey = HI_DGKEY from History where HI_OAID = 19 and HI_TypeCode = @SDID
			set @sMod = 'DEL'
		END

		if (@sTemp2 is not null)
		BEGIN
			set @sTemp = convert(varchar(25), @SDDate, 104)
			EXEC @nHIID = dbo.InsHistory @sDGCode, @nDGKey, 19, @SDID, @sMod, @sTemp2, @sTemp, 0, ''

			SET @nOldValue = @O_SD_State
			SET @nNewValue = @N_SD_State

			IF ISNULL(@nOldValue, 0) = 0
				SET @sOldValue = ''
			ELSE IF @nOldValue = 1
				SET @sOldValue = 'Allotment'
			ELSE IF @nOldValue = 2
				SET @sOldValue = 'Commitment'
			ELSE IF @nOldValue = 3
				SET @sOldValue = 'Confirmed'
			ELSE IF @nOldValue = 4
				SET @sOldValue = 'Wait'

			IF ISNULL(@nNewValue, 0) = 0
				SET @sNewValue = ''
			ELSE IF @nNewValue = 1
				SET @sNewValue = 'Allotment'
			ELSE IF @nNewValue = 2
				SET @sNewValue = 'Commitment'
			ELSE IF @nNewValue = 3
				SET @sNewValue = 'Confirmed'
			ELSE IF @nNewValue = 4
				SET @sNewValue = 'Wait'
			
			IF (@sMod = 'INS')
				EXECUTE dbo.InsertHistoryDetail @nHIID , 19001, '', @sNewValue, null, @nNewValue, null, null, 0
			ELSE IF (@sMod = 'DEL')
				EXECUTE dbo.InsertHistoryDetail @nHIID , 19001, @sOldValue, '', @nOldValue, null, null, null, 0
		END
	END
	FETCH NEXT FROM cur_ServiceByDateChanged 
		INTO @SDID, @O_SD_DLKey, @O_SD_RLID, @O_SD_TUKEY, @O_SD_QPID, @O_SD_State, @O_SD_Date,
					@N_SD_DLKey, @N_SD_RLID, @N_SD_TUKEY, @N_SD_QPID, @N_SD_State, @N_SD_Date
					--@DLDateBeg, @DLNDays
END
IF @O_SD_DLKey is not null and @N_SD_DLKey is null
	IF exists (SELECT 1 FROM RoomNumberLists WHERE RL_ID not in (SELECT SD_RLID FROM ServiceByDate) )
		DELETE FROM RoomNumberLists WHERE RL_ID not in (SELECT SD_RLID FROM ServiceByDate)

CLOSE cur_ServiceByDateChanged
DEALLOCATE cur_ServiceByDateChanged
GO

-- 091105_AlterConstraints.sql
-- 7.2 - 9.2
ALTER TABLE dbo.TurDate DROP CONSTRAINT [TD_TRKEY]
GO
ALTER TABLE dbo.TurDate WITH CHECK ADD CONSTRAINT [TD_TRKEY] FOREIGN KEY([TD_TRKEY])
REFERENCES [dbo].[tbl_TurList] ([TL_KEY])
GO

ALTER TABLE dbo.TurService DROP CONSTRAINT [TS_SVKEY]
GO
ALTER TABLE [dbo].[TurService]  WITH NOCHECK ADD  CONSTRAINT [TS_SVKEY] FOREIGN KEY([TS_SVKEY])
REFERENCES [dbo].[Service] ([SV_KEY])
GO

ALTER TABLE dbo.TurService DROP CONSTRAINT [TS_TRKEY]
GO
ALTER TABLE [dbo].[TurService]  WITH NOCHECK ADD  CONSTRAINT [TS_TRKEY] FOREIGN KEY([TS_TRKEY])
REFERENCES [dbo].[tbl_TurList] ([TL_KEY])
GO

ALTER TABLE dbo.TurMargin DROP CONSTRAINT [FK__TURMARGIN__TM_Tl__11564BB9]
GO
ALTER TABLE [dbo].[TURMARGIN]  WITH NOCHECK ADD  CONSTRAINT [FK__TURMARGIN__TM_Tl__11564BB9] FOREIGN KEY([TM_TlKey])
REFERENCES [dbo].[tbl_TurList] ([TL_KEY])
GO

-- 091106(SystemLogTable).sql
-- 7.2 - 9.2
--------------------------------
--- Create Table [SystemLog] ---
--------------------------------

	if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SystemLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
		CREATE TABLE [dbo].[SystemLog](
			[SL_ID] [int] IDENTITY(1,1) NOT NULL,
			[SL_Type] [smallint] NULL,
			[SL_Date] [datetime] NULL,
			[SL_Message] [varchar](1024) NULL,
			[SL_AppID] [smallint] NULL
		) ON [PRIMARY]
	GO

	grant select, insert, update, delete on [dbo].[SystemLog] to public
	GO

-- 091103_AlterTableCalculatingPriceLists.sql
-- 7.2 - 9.2
if not exists (select id from dbo.syscolumns where id = object_id(N'[dbo].[CalculatingPriceLists]') and name = 'CP_StartTime')
	alter table dbo.CalculatingPriceLists add CP_StartTime datetime null
go

if not exists (select id from dbo.syscolumns where id = object_id(N'[dbo].[CalculatingPriceLists]') and name = 'CP_Status')
	alter table dbo.CalculatingPriceLists add CP_Status smallint default(0)
go

-- 091106(Insert_SystemSettings).sql
-- 7.2 - 9.2
if not exists (select * from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values('SYSTourFilialSecControl', '0')
GO

if not exists (select * from SystemSettings where SS_ParmName like 'SYSCostFilialSecControl')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values('SYSCostFilialSecControl', '0')
GO

-- sp_CheckRoomForQuotes.sql
-- 7.2 - 9.2
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CheckRoomForQuotes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure [dbo].[CheckRoomForQuotes] 
GO
CREATE PROCEDURE CheckRoomForQuotes
(
-- Проверяем нет ли в одном номере servicebydate с разными квотами на номер.
--<VERSION>2009.2.01.01</VERSION>
	@RLID int,
	@DateStart datetime,
	@DateEnd datetime
)
AS
BEGIN
	declare @date datetime, @qpid int, @state smallint, @quotaCounter int

	Set @date = @DateStart

	while @date <= @DateEnd
	BEGIN
		Select @quotaCounter = count(distinct sd_qpid) 
		from ServiceByDate 
		where sd_date = @date and sd_rlid = @RLID

		if(@quotaCounter > 1)
		BEGIN
			Select @qpid = sd_qpid, @state = sd_state
			from Quotas, QuotaDetails, QuotaParts, ServiceByDate
			where qt_id = qd_qtid and qd_id = qp_qdid and sd_qpid = qp_id and sd_date = @date and sd_rlid = @RLID and 
					qt_byroom = 1
			order by sd_state

			if(@qpid is not null)
			BEGIN
				Update ServiceByDate 
				set sd_qpid = @qpid, sd_state = @state
				where sd_date = @date and sd_rlid = @RLID
			END	
		END
		Set @date = @date + 1	
	END
END
GO

GRANT EXEC ON [dbo].[CheckRoomForQuotes] TO PUBLIC
GO

-- sp_CheckServiceForQuotes.sql
-- 7.2 - 9.2
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CheckServiceForQuotes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure [dbo].[CheckServiceForQuotes] 
GO
CREATE PROCEDURE CheckServiceForQuotes
(
-- Проверяем нет ли в одном номере servicebydate с разными квотами на номер.
--<VERSION>2009.2.01.01</VERSION>
	@DLKey int
)
AS
BEGIN
	declare @dateBeg datetime, @dateEnd datetime, @rlid int

	Select @dateBeg = dl_datebeg, @dateEnd = dl_dateend from DogovorList where dl_key = @DLKey

	declare roomsCursor cursor for select distinct sd_rlid from ServiceBydate where sd_dlkey = @DLKey
			
	open roomsCursor
	fetch next from roomsCursor into @rlid
	while @@FETCH_STATUS = 0
	begin
		exec CheckRoomForQuotes @rlid, @dateBeg, @dateEnd
		fetch next from roomsCursor into @rlid
	end
			
	close roomsCursor
	deallocate roomsCursor
END
GO
GRANT EXEC ON [dbo].[CheckServiceForQuotes] TO PUBLIC
GO

-- T_InsteadOfUpdate_Costs.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateCost]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfUpdateCost]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfUpdateCost]
--	ON [dbo].[tbl_Costs]
--	INSTEAD OF UPDATE
--AS
--begin

--	declare @CSSvKey int
--	declare @CSCode int
--	declare @CSSubCode1 int
--	declare @CSSubCode2 int
--	declare @CSPrKey int
--	declare @CSPkKey int
--	declare @CSDate datetime
--	declare @CSDateEnd datetime
--	declare @CSWeek varchar(7)
--	declare @CSCostNetto float
--	declare @CSCost float
--	declare @CSDiscount smallint
--	declare @CSType smallint
--	declare @CSCreator int
--	declare @CSRate varchar(2)
--	declare @CSUpdDate datetime
--	declare @CSLong smallint
--	declare @CSByDay smallint
--	declare @CSFirstDayNetto smallint
--	declare @CSFirstDayBrutto smallint
--	declare @CSProfit float 
--	declare @CSCinNum int
--	declare @CSTypeCalc smallint
--	declare @CSDateSellBeg datetime
--	declare @CSDateSellEnd datetime
--	declare @CSId int
--	declare @CSCheckinDateBeg datetime
--	declare @CSCheckInDateEnd datetime
--	declare @CSLongMin smallint
--	declare @CSTypeDivision smallint
--	declare @CSUpdUser varchar(30)

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSCostFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin

--		DECLARE cur_CostUpdate1 CURSOR FOR
--			SELECT CS_SVKEY, CS_CODE, CS_SUBCODE1, CS_SUBCODE2, CS_PRKEY, CS_PKKEY, CS_DATE, CS_DATEEND, CS_WEEK, CS_COSTNETTO, CS_COST,
--				CS_DISCOUNT, CS_TYPE, CS_CREATOR, CS_RATE, CS_UPDDATE, CS_LONG, CS_BYDAY, CS_FIRSTDAYNETTO, CS_FIRSTDAYBRUTTO, CS_PROFIT,
--				CS_CINNUM, CS_TypeCalc, cs_DateSellBeg, cs_DateSellEnd, CS_CHECKINDATEBEG, CS_CHECKINDATEEND, CS_LONGMIN, CS_TypeDivision,
--				CS_UPDUSER, CS_ID
--			FROM Inserted

--		OPEN cur_CostUpdate1
--		FETCH NEXT FROM cur_CostUpdate1
--		into @CSSvKey, @CSCode, @CSSubCode1, @CSSubCode2, @CSPrKey, @CSPkKey, @CSDate, @CSDateEnd, @CSWeek, @CSCostNetto, @CSCost,
--			@CSDiscount, @CSType, @CSCreator, @CSRate, @CSUpdDate, @CSLong, @CSByDay, @CSFirstDayNetto, @CSFirstDayBrutto, @CSProfit,
--			@CSCinNum, @CSTypeCalc, @CSDateSellBeg, @CSDateSellEnd, @CSCheckinDateBeg, @CSCheckInDateEnd, @CSLongMin, @CSTypeDivision,
--			@CSUpdUser, @CSId

--		WHILE @@FETCH_STATUS = 0
--		BEGIN
--			update tbl_Costs set CS_SVKEY = @CSSvKey, CS_CODE = @CSCode, CS_SUBCODE1 = @CSSubCode1, CS_SUBCODE2 = @CSSubCode2, 
--				CS_PRKEY = @CSPrKey, CS_PKKEY = @CSPkKey, CS_DATE = @CSDate, CS_DATEEND = @CSDateEnd, CS_WEEK = @CSWeek, 
--				CS_COSTNETTO = @CSCostNetto, CS_COST = @CSCost, CS_DISCOUNT = @CSDiscount, CS_TYPE = @CSType, CS_CREATOR = @CSCreator, 
--				CS_RATE = @CSRate, CS_UPDDATE = @CSUpdDate, CS_LONG = @CSLong, CS_BYDAY = @CSByDay, CS_FIRSTDAYNETTO = @CSFirstDayNetto, 
--				CS_FIRSTDAYBRUTTO = @CSFirstDayBrutto, CS_PROFIT = @CSProfit, CS_CINNUM = @CSCinNum, CS_TypeCalc = @CSTypeCalc, 
--				cs_DateSellBeg = @CSDateSellBeg, cs_DateSellEnd = @CSDateSellEnd, CS_CHECKINDATEBEG = @CSCheckinDateBeg, 
--				CS_CHECKINDATEEND = @CSCheckInDateEnd, CS_LONGMIN = @CSLongMin, CS_TypeDivision = @CSTypeDivision, CS_UPDUSER = @CSUpdUser
--			where CS_ID = @CSId

--			FETCH NEXT FROM cur_CostUpdate1
--			into @CSSvKey, @CSCode, @CSSubCode1, @CSSubCode2, @CSPrKey, @CSPkKey, @CSDate, @CSDateEnd, @CSWeek, @CSCostNetto, @CSCost,
--				@CSDiscount, @CSType, @CSCreator, @CSRate, @CSUpdDate, @CSLong, @CSByDay, @CSFirstDayNetto, @CSFirstDayBrutto, @CSProfit,
--				@CSCinNum, @CSTypeCalc, @CSDateSellBeg, @CSDateSellEnd, @CSCheckinDateBeg, @CSCheckInDateEnd, @CSLongMin, @CSTypeDivision,
--				@CSUpdUser, @CSId
--		END

--		CLOSE cur_CostUpdate1
--		DEALLOCATE cur_CostUpdate1
		
--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @costKey int
--	declare @costCreator int
--	declare @costPartnerKey int
--	declare @costFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_CostUpdate CURSOR FOR
--		SELECT D.CS_ID, D.CS_Creator
--		FROM Deleted d

--	OPEN cur_CostUpdate
--	FETCH NEXT FROM cur_CostUpdate
--	INTO @costKey, @costCreator
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @costPartnerKey = US_PRKey from UserList where US_Key = @costCreator
--		select @costFilialKey = PR_Filial from tbl_Partners where PR_Key = @costPartnerKey

--		if (@userFilialKey = @costFilialKey or @userFilialKey = @nOwnerKey)
--		begin

--			SELECT @CSSvKey = CS_SVKEY, @CSCode = CS_CODE, @CSSubCode1 = CS_SUBCODE1, @CSSubCode2 = CS_SUBCODE2, @CSPrKey = CS_PRKEY, 
--				@CSPkKey = CS_PKKEY, @CSDate = CS_DATE, @CSDateEnd = CS_DATEEND, @CSWeek = CS_WEEK, @CSCostNetto = CS_COSTNETTO, @CSCost = CS_COST,
--				@CSDiscount = CS_DISCOUNT, @CSType = CS_TYPE, @CSCreator = CS_CREATOR, @CSRate = CS_RATE, @CSUpdDate = CS_UPDDATE, @CSLong = CS_LONG, 
--				@CSByDay = CS_BYDAY, @CSFirstDayNetto = CS_FIRSTDAYNETTO, @CSFirstDayBrutto = CS_FIRSTDAYBRUTTO, @CSProfit = CS_PROFIT,
--				@CSCinNum = CS_CINNUM, @CSTypeCalc = CS_TypeCalc, @CSDateSellBeg = cs_DateSellBeg, @CSDateSellEnd = cs_DateSellEnd, 
--				@CSCheckinDateBeg = CS_CHECKINDATEBEG, @CSCheckInDateEnd = CS_CHECKINDATEEND, @CSLongMin = CS_LONGMIN, @CSTypeDivision = CS_TypeDivision,
--				@CSUpdUser = CS_UPDUSER
--			FROM Inserted
--			where CS_ID = @costKey

--			update tbl_Costs set CS_SVKEY = @CSSvKey, CS_CODE = @CSCode, CS_SUBCODE1 = @CSSubCode1, CS_SUBCODE2 = @CSSubCode2, 
--				CS_PRKEY = @CSPrKey, CS_PKKEY = @CSPkKey, CS_DATE = @CSDate, CS_DATEEND = @CSDateEnd, CS_WEEK = @CSWeek, 
--				CS_COSTNETTO = @CSCostNetto, CS_COST = @CSCost, CS_DISCOUNT = @CSDiscount, CS_TYPE = @CSType, CS_CREATOR = @CSCreator, 
--				CS_RATE = @CSRate, CS_UPDDATE = @CSUpdDate, CS_LONG = @CSLong, CS_BYDAY = @CSByDay, CS_FIRSTDAYNETTO = @CSFirstDayNetto, 
--				CS_FIRSTDAYBRUTTO = @CSFirstDayBrutto, CS_PROFIT = @CSProfit, CS_CINNUM = @CSCinNum, CS_TypeCalc = @CSTypeCalc, 
--				cs_DateSellBeg = @CSDateSellBeg, cs_DateSellEnd = @CSDateSellEnd, CS_CHECKINDATEBEG = @CSCheckinDateBeg, 
--				CS_CHECKINDATEEND = @CSCheckInDateEnd, CS_LONGMIN = @CSLongMin, CS_TypeDivision = @CSTypeDivision, CS_UPDUSER = @CSUpdUser
--			where CS_ID = @costKey
			
--		end

--		FETCH NEXT FROM cur_CostUpdate
--		INTO @costKey, @costCreator
--	END
--	CLOSE cur_CostUpdate
--	DEALLOCATE cur_CostUpdate
--end
--GO

-- T_InsteadOfDelete_TurMargin.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfDeleteTurMargin]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfDeleteTurMargin]
--	ON [dbo].[TurMargin]
--	INSTEAD OF DELETE
--AS
--begin

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin
--		delete from TurMargin where TM_Key in (select TM_Key from Deleted)
--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @tourMarginKey int
--	declare @tourKey int
--	declare @tourCreator int
--	declare @tourPartnerKey int
--	declare @tourFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_TurMarginDelete CURSOR FOR
--		SELECT D.TM_Key, TL_CREATOR, TL_Key
--		FROM Deleted d join TurList on D.TM_TlKEY = TL_KEY

--	OPEN cur_TurMarginDelete
--	FETCH NEXT FROM cur_TurMarginDelete
--	INTO @tourMarginKey, @tourCreator, @tourKey
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
--		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey

--		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
--		begin
--			delete from TurMargin where TM_KEY = @tourMarginKey
--		end

--		FETCH NEXT FROM cur_TurMarginDelete 
--		INTO @tourMarginKey, @tourCreator, @tourKey
--	END
--	CLOSE cur_TurMarginDelete
--	DEALLOCATE cur_TurMarginDelete
--end
--GO

-- T_InsteadOfDelete_TurService.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurService]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfDeleteTurService]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfDeleteTurService]
--	ON [dbo].[TurService]
--	INSTEAD OF DELETE
--AS
--begin

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin
--		delete from TurService where TS_Key in (select TS_Key from Deleted)
--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @tourServiceKey int
--	declare @tourKey int
--	declare @tourCreator int
--	declare @tourPartnerKey int
--	declare @tourFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_TurServiceDelete CURSOR FOR
--		SELECT D.TS_Key, TL_CREATOR, TL_Key
--		FROM Deleted d join TurList on D.TS_TRKEY = TL_KEY

--	OPEN cur_TurServiceDelete
--	FETCH NEXT FROM cur_TurServiceDelete
--	INTO @tourServiceKey, @tourCreator, @tourKey
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
--		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey

--		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
--		begin
--			delete from TurService where TS_KEY = @tourServiceKey
--		end

--		FETCH NEXT FROM cur_TurServiceDelete 
--		INTO @tourServiceKey, @tourCreator, @tourKey
--	END
--	CLOSE cur_TurServiceDelete
--	DEALLOCATE cur_TurServiceDelete
--end
--GO

-- T_InsteadOfDelete_TurList.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfDeleteTurList]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfDeleteTurList]
--	ON [dbo].[tbl_TurList]
--	INSTEAD OF DELETE
--AS
--begin

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin
--		delete from TurDate where TD_TRKEY in (select TL_Key from Deleted)
--		delete from TurService where TS_TRKEY in (select TL_Key from Deleted)
--		delete from TurMargin where TM_TlKEY in (select TL_Key from Deleted)
--		delete from tbl_TurList where TL_KEY in (select TL_Key from Deleted)
--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @tourKey int
--	declare @tourCreator int
--	declare @tourPartnerKey int
--	declare @tourFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_TurListDelete CURSOR FOR
--		SELECT D.TL_KEY, D.TL_CREATOR
--		FROM Deleted d

--	OPEN cur_TurListDelete
--	FETCH NEXT FROM cur_TurListDelete
--	INTO @tourKey, @tourCreator
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
--		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey

--		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
--		begin
--			delete from TurDate where TD_TRKEY = @tourKey
--			delete from TurService where TS_TRKEY = @tourKey
--			delete from TurMargin where TM_TlKEY = @tourKey
--			delete from tbl_TurList where TL_KEY = @tourKey
--		end

--		FETCH NEXT FROM cur_TurListDelete 
--		INTO @tourKey, @tourCreator
--	END
--	CLOSE cur_TurListDelete
--	DEALLOCATE cur_TurListDelete
--end
--GO

-- T_InsteadOfUpdate_TurMargin.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfUpdateTurMargin]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfUpdateTurMargin]
--	ON [dbo].[TurMargin]
--	INSTEAD OF UPDATE
--AS
--begin

--	declare @tourMarginKey int

--	declare @TMTlKey int
--	declare @TMDateBeg datetime
--	declare @TMDateEnd datetime
--	declare @TMMargin decimal(18,4)
--	declare @TMMarginType smallint
--	declare @TMCreator int
--	declare @TMUpdDate datetime
--	declare @TMDateSellBeg datetime
--	declare @TMDateSellEnd datetime
--	declare @TMLong smallint
--	declare @TMSvKey int
--	declare @TMFromPacket smallint
--	declare @TMKey int

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin

--		DECLARE cur_TurMarginUpdate1 CURSOR FOR
--			SELECT TM_TlKey, TM_DateBeg, TM_DateEnd, TM_Margin, TM_MarginType, TM_Creator, TM_UpdDate, TM_DateSellBeg, 
--				TM_DateSellEnd, TM_LONG, TM_SVKEY, TM_FromPacket, TM_Key
--			FROM Inserted

--		OPEN cur_TurMarginUpdate1
--		FETCH NEXT FROM cur_TurMarginUpdate1
--		into @TMTlKey, @TMDateBeg, @TMDateEnd, @TMMargin, @TMMarginType, @TMCreator, @TMUpdDate, @TMDateSellBeg, @TMDateSellEnd,
--			@TMLong, @TMSvKey, @TMFromPacket, @TMKey

--		WHILE @@FETCH_STATUS = 0
--		BEGIN
--			update TurMargin set TM_TlKey = @TMTlKey, TM_DateBeg = @TMDateBeg, TM_DateEnd = @TMDateEnd, TM_Margin = @TMMargin, 
--				TM_MarginType = @TMMarginType, TM_Creator = @TMCreator, TM_UpdDate = @TMUpdDate, 
--				TM_DateSellBeg = @TMDateSellBeg, TM_DateSellEnd = @TMDateSellEnd, TM_LONG = @TMLong, TM_SVKEY = @TMSvKey, 
--				TM_FromPacket = @TMFromPacket
--			where TM_Key = @TMKey

--			FETCH NEXT FROM cur_TurMarginUpdate1
--			into @TMTlKey, @TMDateBeg, @TMDateEnd, @TMMargin, @TMMarginType, @TMCreator, @TMUpdDate, @TMDateSellBeg, @TMDateSellEnd,
--				@TMLong, @TMSvKey, @TMFromPacket, @TMKey
--		END

--		CLOSE cur_TurMarginUpdate1
--		DEALLOCATE cur_TurMarginUpdate1
		
--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @tourKey int
--	declare @tourCreator int
--	declare @tourPartnerKey int
--	declare @tourFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_TurMarginUpdate CURSOR FOR
--		SELECT D.TM_Key, TL_CREATOR, TL_Key
--		FROM Deleted d join TurList on D.TM_TlKEY = TL_KEY

--	OPEN cur_TurMarginUpdate
--	FETCH NEXT FROM cur_TurMarginUpdate
--	INTO @tourMarginKey, @tourCreator, @tourKey
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
--		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey

--		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
--		begin

--			SELECT @TMTlKey = TM_TlKey, @TMDateBeg = TM_DateBeg, @TMDateEnd = TM_DateEnd, @TMMargin = TM_Margin, 
--				@TMMarginType = TM_MarginType, @TMCreator = TM_Creator, @TMUpdDate = TM_UpdDate, @TMDateSellBeg = TM_DateSellBeg, 
--				@TMDateSellEnd = TM_DateSellEnd, @TMLong = TM_LONG, @TMSvKey = TM_SVKEY, @TMFromPacket = TM_FromPacket
--			FROM Inserted
--			where TM_Key = @tourMarginKey

--			update TurMargin set TM_TlKey = @TMTlKey, TM_DateBeg = @TMDateBeg, TM_DateEnd = @TMDateEnd, TM_Margin = @TMMargin, 
--				TM_MarginType = @TMMarginType, TM_Creator = @TMCreator, TM_UpdDate = @TMUpdDate, TM_DateSellBeg = @TMDateSellBeg, 
--				TM_DateSellEnd = @TMDateSellEnd, TM_LONG = @TMLong, TM_SVKEY = @TMSvKey, TM_FromPacket = @TMFromPacket
--			where TM_Key = @tourMarginKey
			
--		end

--		FETCH NEXT FROM cur_TurMarginUpdate
--		INTO @tourMarginKey, @tourCreator, @tourKey
--	END
--	CLOSE cur_TurMarginUpdate
--	DEALLOCATE cur_TurMarginUpdate
--end
--GO

-- T_InsteadOfUpdate_TurService.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurService]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfUpdateTurService]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfUpdateTurService]
--	ON [dbo].[TurService]
--	INSTEAD OF UPDATE
--AS
--begin

--	declare @tourServiceKey int

--	declare @TSTrKey int
--	declare @TSSvKey int
--	declare @TSPkKey int
--	declare @TSName varchar(150)
--	declare @TSDay int
--	declare @TSCode int
--	declare @TSSubCode1 int
--	declare @TSSubCode2 int
--	declare @TSNDays smallint
--	declare @TSCnKey int
--	declare @TSCtKey int
--	declare @TSPartnerKey int
--	declare @TSCost float
--	declare @TSProfit float
--	declare @TSTimeBeg datetime
--	declare @TSAttribute int
--	declare @TSKey int
--	declare @TSNameLat varchar(150)
--	declare @TSPrtDogKey int
--	declare @TSTaxZoneId int
--	declare @TSWebAttribute int
--	declare @TSWait smallint

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin

--		DECLARE cur_TurServiceUpdate1 CURSOR FOR
--			SELECT TS_TRKEY, TS_SVKEY, TS_PKKEY, TS_NAME, TS_DAY, TS_CODE, TS_SUBCODE1, TS_SUBCODE2, TS_NDAYS, TS_CNKEY,
--					TS_CTKEY, TS_PARTNERKEY, TS_COST, TS_PROFIT, TS_TIMEBEG, TS_ATTRIBUTE, TS_Key, TS_NameLat, TS_PRTDOGKEY,
--					TS_TAXZONEID, TS_WebAttribute, TS_Wait
--			FROM Inserted

--		OPEN cur_TurServiceUpdate1
--		FETCH NEXT FROM cur_TurServiceUpdate1
--		into @TSTrKey, @TSSvKey, @TSPkKey, @TSName, @TSDay, @TSCode, @TSSubCode1, @TSSubCode2, @TSNDays, @TSCnKey,
--			@TSCtKey, @TSPartnerKey, @TSCost, @TSProfit, @TSTimeBeg, @TSAttribute, @TSKey, @TSNameLat, @TSPrtDogKey,
--			@TSTaxZoneId, @TSWebAttribute, @TSWait

--		WHILE @@FETCH_STATUS = 0
--		BEGIN
--			update TurService set TS_TRKEY = @TSTrKey, TS_SVKEY = @TSSvKey, TS_PKKEY = @TSPkKey, TS_NAME = @TSName, TS_DAY = @TSDay, 
--					TS_CODE = @TSCode, TS_SUBCODE1 = @TSSubCode1, TS_SUBCODE2 = @TSSubCode2, TS_NDAYS = @TSNDays, TS_CNKEY = @TSCnKey,
--					TS_CTKEY = @TSCtKey, TS_PARTNERKEY = @TSPartnerKey, TS_COST = @TSCost, TS_PROFIT = @TSProfit, 
--					TS_TIMEBEG = @TSTimeBeg, TS_ATTRIBUTE = @TSAttribute, TS_NameLat = @TSNameLat, TS_PRTDOGKEY = @TSPrtDogKey,
--					TS_TAXZONEID = @TSTaxZoneId, TS_WebAttribute = @TSWebAttribute, TS_Wait = @TSWait
--			where TS_Key = @TSKey

--			FETCH NEXT FROM cur_TurServiceUpdate1
--			into @TSTrKey, @TSSvKey, @TSPkKey, @TSName, @TSDay, @TSCode, @TSSubCode1, @TSSubCode2, @TSNDays, @TSCnKey,
--				@TSCtKey, @TSPartnerKey, @TSCost, @TSProfit, @TSTimeBeg, @TSAttribute, @TSKey, @TSNameLat, @TSPrtDogKey,
--				@TSTaxZoneId, @TSWebAttribute, @TSWait
--		END

--		CLOSE cur_TurServiceUpdate1
--		DEALLOCATE cur_TurServiceUpdate1
		
--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @tourKey int
--	declare @tourCreator int
--	declare @tourPartnerKey int
--	declare @tourFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_TurServiceUpdate CURSOR FOR
--		SELECT D.TS_Key, TL_CREATOR, TL_Key
--		FROM Deleted d join TurList on D.TS_TRKEY = TL_KEY

--	OPEN cur_TurServiceUpdate
--	FETCH NEXT FROM cur_TurServiceUpdate
--	INTO @tourServiceKey, @tourCreator, @tourKey
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
--		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey
		
--		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
--		begin

--			SELECT @TSTrKey = TS_TRKEY, @TSSvKey = TS_SVKEY, @TSPkKey = TS_PKKEY, @TSName = TS_NAME, @TSDay = TS_DAY, 
--					@TSCode = TS_CODE, @TSSubCode1 = TS_SUBCODE1, @TSSubCode2 = TS_SUBCODE2, @TSNDays = TS_NDAYS, @TSCnKey = TS_CNKEY,
--					@TSCtKey = TS_CTKEY, @TSPartnerKey = TS_PARTNERKEY, @TSCost = TS_COST, @TSProfit = TS_PROFIT, 
--					@TSTimeBeg = TS_TIMEBEG, @TSAttribute = TS_ATTRIBUTE, @TSNameLat = TS_NameLat, @TSPrtDogKey = TS_PRTDOGKEY,
--					@TSTaxZoneId = TS_TAXZONEID, @TSWebAttribute = TS_WebAttribute, @TSWait = TS_Wait
--			FROM Inserted
--			where TS_Key = @tourServiceKey

--			update TurService set TS_TRKEY = @TSTrKey, TS_SVKEY = @TSSvKey, TS_PKKEY = @TSPkKey, TS_NAME = @TSName, TS_DAY = @TSDay, 
--					TS_CODE = @TSCode, TS_SUBCODE1 = @TSSubCode1, TS_SUBCODE2 = @TSSubCode2, TS_NDAYS = @TSNDays, TS_CNKEY = @TSCnKey,
--					TS_CTKEY = @TSCtKey , TS_PARTNERKEY = @TSPartnerKey, TS_COST = @TSCost, TS_PROFIT = @TSProfit, 
--					TS_TIMEBEG = @TSTimeBeg, TS_ATTRIBUTE = @TSAttribute, TS_NameLat = @TSNameLat, TS_PRTDOGKEY = @TSPrtDogKey,
--					TS_TAXZONEID = @TSTaxZoneId, TS_WebAttribute = @TSWebAttribute, TS_Wait = @TSWait
--			where TS_Key = @tourServiceKey
			
--		end

--		FETCH NEXT FROM cur_TurServiceUpdate
--		INTO @tourServiceKey, @tourCreator, @tourKey
--	END
--	CLOSE cur_TurServiceUpdate
--	DEALLOCATE cur_TurServiceUpdate
--end
--GO

-- T_InsteadOfUpdate_TurDate.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurDate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfUpdateTurDate]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfUpdateTurDate]
--	ON [dbo].[TurDate]
--	INSTEAD OF UPDATE
--AS
--begin

--	declare @tourDateKey int

--	declare @TDTrKey int
--	declare @TDDate datetime
--	declare @TDId int

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin

--		DECLARE cur_TurDateUpdate1 CURSOR FOR
--			SELECT TD_TRKEY, TD_DATE, TD_ID
--			FROM Inserted

--		OPEN cur_TurDateUpdate1
--		FETCH NEXT FROM cur_TurDateUpdate1
--		into @TDTrKey, @TDDate, @TDId

--		WHILE @@FETCH_STATUS = 0
--		BEGIN
--			update TurDate set TD_TRKEY = @TDTrKey, TD_DATE = @TDDate
--			where TD_ID = @TDId

--			FETCH NEXT FROM cur_TurDateUpdate1
--			into @TDTrKey, @TDDate, @TDId
--		END

--		CLOSE cur_TurDateUpdate1
--		DEALLOCATE cur_TurDateUpdate1
		
--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @tourKey int
--	declare @tourCreator int
--	declare @tourPartnerKey int
--	declare @tourFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_TurDateUpdate CURSOR FOR
--		SELECT D.TD_ID, TL_CREATOR, TL_Key
--		FROM Deleted d join TurList on TD_TRKEY = TL_KEY

--	OPEN cur_TurDateUpdate
--	FETCH NEXT FROM cur_TurDateUpdate
--	INTO @tourDateKey, @tourCreator, @tourKey
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
--		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey

--		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
--		begin

--			SELECT @TDTrKey = TD_TrKey, @TDDate = TD_DATE
--			FROM Inserted
--			where TD_ID = @tourDateKey

--			update TurDate set TD_TrKey = @TDTrKey, TD_DATE = @TDDate
--			where TD_ID = @tourDateKey
			
--		end

--		FETCH NEXT FROM cur_TurDateUpdate
--		INTO @tourDateKey, @tourCreator, @tourKey
--	END
--	CLOSE cur_TurDateUpdate
--	DEALLOCATE cur_TurDateUpdate
--end

-- T_InsteadOfInsert_TurMargin.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfDeleteTurMargin]
--GO

--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfInsertTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfInsertTurMargin]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfInsertTurMargin]
--	ON [dbo].[TurMargin]
--	INSTEAD OF INSERT
--AS
--begin

--	declare @tourMarginKey int

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin

--		insert into TurMargin (TM_TlKey, TM_DateBeg, TM_DateEnd, TM_Margin, TM_MarginType, TM_Creator, TM_UpdDate, TM_DateSellBeg, 
--				TM_DateSellEnd, TM_LONG, TM_SVKEY, TM_FromPacket, TM_Key) 
--		select i.TM_TlKey, i.TM_DateBeg, i.TM_DateEnd, i.TM_Margin, i.TM_MarginType, i.TM_Creator, i.TM_UpdDate, i.TM_DateSellBeg, 
--				i.TM_DateSellEnd, i.TM_LONG, i.TM_SVKEY, i.TM_FromPacket, i.TM_Key from Inserted i
		
--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @tourKey int
--	declare @tourCreator int
--	declare @tourPartnerKey int
--	declare @tourFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_TurMarginInsert CURSOR FOR
--		SELECT i.TM_Key, TL_CREATOR, TL_Key
--		FROM Inserted i join TurList on i.TM_TlKEY = TL_KEY

--	OPEN cur_TurMarginInsert
--	FETCH NEXT FROM cur_TurMarginInsert
--	INTO @tourMarginKey, @tourCreator, @tourKey
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
--		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey

--		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
--		begin

--			insert into TurMargin (TM_TlKey, TM_DateBeg, TM_DateEnd, TM_Margin, TM_MarginType, TM_Creator, TM_UpdDate, TM_DateSellBeg, 
--					TM_DateSellEnd, TM_LONG, TM_SVKEY, TM_FromPacket, TM_Key) 
--			select i.TM_TlKey, i.TM_DateBeg, i.TM_DateEnd, i.TM_Margin, i.TM_MarginType, i.TM_Creator, i.TM_UpdDate, i.TM_DateSellBeg, 
--					i.TM_DateSellEnd, i.TM_LONG, i.TM_SVKEY, i.TM_FromPacket, i.TM_Key from Inserted i 
--			where i.TM_Key = @tourMarginKey

--		end

--		FETCH NEXT FROM cur_TurMarginInsert
--		INTO @tourMarginKey, @tourCreator, @tourKey
--	END
--	CLOSE cur_TurMarginInsert
--	DEALLOCATE cur_TurMarginInsert
--end
--GO

-- T_InsteadOfInsert_TurService.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfInsertTurService]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfInsertTurService]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfInsertTurService]
--	ON [dbo].[TurService]
--	INSTEAD OF INSERT
--AS
--begin

--	declare @tourServiceKey int

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin

--		insert into TurService (TS_TRKEY, TS_SVKEY, TS_PKKEY, TS_NAME, TS_DAY, TS_CODE, TS_SUBCODE1, TS_SUBCODE2, TS_NDAYS, TS_CNKEY,
--					TS_CTKEY, TS_PARTNERKEY, TS_COST, TS_PROFIT, TS_TIMEBEG, TS_ATTRIBUTE, TS_Key, TS_NameLat, TS_PRTDOGKEY,
--					TS_TAXZONEID, TS_WebAttribute, TS_Wait)
--		select i.TS_TRKEY, i.TS_SVKEY, i.TS_PKKEY, i.TS_NAME, i.TS_DAY, i.TS_CODE, i.TS_SUBCODE1, i.TS_SUBCODE2, i.TS_NDAYS, i.TS_CNKEY,
--					i.TS_CTKEY, i.TS_PARTNERKEY, i.TS_COST, i.TS_PROFIT, i.TS_TIMEBEG, i.TS_ATTRIBUTE, i.TS_Key, i.TS_NameLat, i.TS_PRTDOGKEY,
--					i.TS_TAXZONEID, i.TS_WebAttribute, i.TS_Wait from Inserted i

--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @tourKey int
--	declare @tourCreator int
--	declare @tourPartnerKey int
--	declare @tourFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_TurServiceInsert CURSOR FOR
--		SELECT i.TS_Key, TL_CREATOR, TL_Key
--		FROM Inserted i join TurList on i.TS_TRKEY = TL_KEY

--	OPEN cur_TurServiceInsert
--	FETCH NEXT FROM cur_TurServiceInsert
--	INTO @tourServiceKey, @tourCreator, @tourKey
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
--		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey
		
--		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
--		begin

--			insert into TurService (TS_TRKEY, TS_SVKEY, TS_PKKEY, TS_NAME, TS_DAY, TS_CODE, TS_SUBCODE1, TS_SUBCODE2, TS_NDAYS, TS_CNKEY,
--					TS_CTKEY, TS_PARTNERKEY, TS_COST, TS_PROFIT, TS_TIMEBEG, TS_ATTRIBUTE, TS_Key, TS_NameLat, TS_PRTDOGKEY,
--					TS_TAXZONEID, TS_WebAttribute, TS_Wait)
--			select  i.TS_TRKEY, i.TS_SVKEY, i.TS_PKKEY, i.TS_NAME, i.TS_DAY, i.TS_CODE, i.TS_SUBCODE1, i.TS_SUBCODE2, i.TS_NDAYS, i.TS_CNKEY,
--					i.TS_CTKEY, i.TS_PARTNERKEY, i.TS_COST, i.TS_PROFIT, i.TS_TIMEBEG, i.TS_ATTRIBUTE, i.TS_Key, i.TS_NameLat, i.TS_PRTDOGKEY,
--					i.TS_TAXZONEID, i.TS_WebAttribute, i.TS_Wait from Inserted i
--			where i.TS_Key = @tourServiceKey
			
--		end

--		FETCH NEXT FROM cur_TurServiceInsert
--		INTO @tourServiceKey, @tourCreator, @tourKey
--	END
--	CLOSE cur_TurServiceInsert
--	DEALLOCATE cur_TurServiceInsert
--end
--GO

-- T_InsteadOfDelete_TurDate.sql
-- 7.2 - 9.2
--if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurDate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--	drop trigger [dbo].[T_InsteadOfDeleteTurDate]
--GO

--CREATE TRIGGER [dbo].[T_InsteadOfDeleteTurDate]
--	ON [dbo].[TurDate]
--	INSTEAD OF DELETE
--AS
--begin

--	declare @settingValue varchar(254)
--	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
--	if (ISNULL(@settingValue, '0') = '0')
--	begin
--		delete from TurDate where TD_ID in (select TD_ID from Deleted)
--		return
--	end

--	declare @nOwnerKey int
--	declare @nFilialKey int
--	set @nOwnerKey = 1
--	set @nFilialKey = 2

--	declare @userKey int
--	declare @userPartnerKey int
--	declare @userFilialKey int
	
--	declare @tourDateKey int
--	declare @tourKey int
--	declare @tourCreator int
--	declare @tourPartnerKey int
--	declare @tourFilialKey int

--	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
--	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

--	if (@userFilialKey is null)
--		return

--	DECLARE cur_TurDateDelete CURSOR FOR
--		SELECT D.TD_ID, TL_CREATOR, TL_Key
--		FROM Deleted d join TurList on TD_TRKEY = TL_KEY

--	OPEN cur_TurDateDelete
--	FETCH NEXT FROM cur_TurDateDelete
--	INTO @tourDateKey, @tourCreator, @tourKey
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
--		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
--		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey

--		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
--		begin
--			delete from TurDate where TD_ID = @tourDateKey
--		end

--		FETCH NEXT FROM cur_TurDateDelete 
--		INTO @tourDateKey, @tourCreator, @tourKey
--	END
--	CLOSE cur_TurDateDelete
--	DEALLOCATE cur_TurDateDelete
--end
--GO

-- 091013(Groups).sql
-- 7.2 - 9.2
if object_id('dbo.ObjectTypes', 'u') is null
begin
	create table dbo.ObjectTypes(
		ot_id int primary key,
		ot_code nvarchar(250),
		ot_name nvarchar(250),
		ot_namelat nvarchar(250),
		ot_comment nvarchar(500)
	)

	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(1, 'AddDescriptions1', 'Дополнительное описание услуги 1')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(2, 'AddDescriptions2', 'Дополнительное описание услуги 2')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(3, 'Aircrafts', 'Самолеты')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(4, 'Airlines', 'Авиакомпании')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(5, 'Airports', 'Аэропорты')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(6, 'AirSeasons', 'Расписание рейсов')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(7, 'Cities', 'Города')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(8, 'Charters', 'Авиарейсы')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(9, 'Countries', 'Страны')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(10, 'Excursions', 'Экскурсии')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(11, 'Histories', 'История')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(12, 'Hotels', 'Отели')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(13, 'HotelRooms', 'Номера в отеле')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(14, 'AccmdMenTypes', 'Типы размещения в отеле')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(15, 'RoomsCategories', 'Категории проживания в отеле')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(16, 'Rooms', 'Типы номеров в отеле')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(17, 'Partners', 'Партнеры')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(18, 'Pansions', 'Типы питания')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(19, 'Rates', 'Валюты')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(20, 'Services', 'Классы услуг')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(21, 'ServiceLists', 'Услуги')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(22, 'AirServices', 'Тарифы авиаперелетов')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(23, 'Transferts', 'Трансферы')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(24, 'Transports', 'Транспорт')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(25, 'Resorts', 'Курорты')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(26, 'DiscountClients', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(27, 'Clients', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(28, 'Cards', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(29, 'Advertisements', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(30, 'ExchangeRates', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(31, 'Orders', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(32, 'PaymentKinds', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(33, 'PaymentTypes', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(34, 'Descriptions', 'Описания объектов')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(35, 'DescTypes', 'Типы описаний объектов')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(36, 'PriceTours', 'Рассчитанные прайсы')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(37, 'TurLists', 'Туры')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(38, 'CostsInsertNumber', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(39, 'PRConsolidation', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(40, 'IL_IncPartners', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(41, 'PrtDeps', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(42, 'PrtWarns', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(43, 'DupUsers', 'Представители')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(44, 'OrderStatuses', 'Статусы путевок')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(45, 'TipTurs', 'Типы туров')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(46, 'Ships', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(47, 'Cabines', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(48, 'Controls', 'Статусы услуг')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(49, 'Dogovors', 'Путевки')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(50, 'InsRates', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(51, 'InsRegions', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(52, 'InsVariants', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(53, 'InsRestrictedRegionCases', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(54, 'InsAgents', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(55, 'Users', 'Пользователи Мастер-Тур')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(56, 'KindOfPays', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(57, 'PartnerDepartments', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(58, 'Accounts', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(59, 'ObjectAliases', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(60, 'DogovorLists', 'Услуги в путевке')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(61, 'Turists', 'Туристы')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(62, 'VisaTuristServices', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(63, 'Payments', 'Платежи')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(64, 'PaymentDetails', 'Детализация платежей')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(65, 'TuristServices', 'Привязки услуг к туристам')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(66, 'Messages', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(67, 'CategoriesOfHotels', 'Категории отелей')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(68, 'VisaServiceToDocs', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(69, 'ServiceDefinitions', '')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(70, 'TurService', 'Услуги в туре')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(71, 'ServiceByDate', 'Привязка услуги к квоте')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(72, 'RealCourses', 'Реальные курсы')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(73, 'Courses', 'Планируемые курсы')
	--insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(74, 'FileHeaders', 'Файлы')

	grant select on dbo.ObjectTypes to public
end
go

if not exists (select * from dbo.ObjectTypes where ot_id = 74)
	insert into dbo.ObjectTypes(ot_id, ot_code, ot_name) values(74, 'FileHeaders', 'Файлы')

if object_id('dbo.ObjectGroups', 'u') is null
begin
	create table dbo.ObjectGroups(
		og_id int identity primary key,
		og_name nvarchar(250),
		og_comment nvarchar(500),
		og_objtype int foreign key references dbo.ObjectTypes
	)

	insert into dbo.ObjectGroups(og_name, og_comment, og_objtype) values('Files', 'Файловая группа', 74)

	grant select, insert, update, delete on dbo.ObjectGroups to public
end
go

if object_id('dbo.ObjectGroupMembers', 'u') is null
begin
	create table dbo.ObjectGroupMembers(
		ogm_id int identity primary key,
		ogm_parent_group int foreign key references dbo.ObjectGroups on delete cascade,
		ogm_objid int,
		ogm_child_group int foreign key references dbo.ObjectGroups,
		ogm_comment nvarchar(500)
	)

	grant select, insert, update, delete on dbo.ObjectGroupMembers to public
end
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

-- T_DogovorUpdate.sql
-- 7.2 - 9.2
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
		--------Детализация--------------------------------------------------
		if (ISNULL(@ODG_Code, '') != ISNULL(@NDG_Code, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1001, @ODG_Code, @NDG_Code, null, null, null, null, 0, @bNeedCommunicationUpdate output
		if (ISNULL(@ODG_Rate, '') != ISNULL(@NDG_Rate, ''))
			BEGIN
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1002, @ODG_Rate, @NDG_Rate, null, null, null, null, 0, @bNeedCommunicationUpdate output
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
				SET @bUpdateNationalCurrencyPrice = 1
			END
		if (ISNULL(@ODG_DiscountSum, 0) != ISNULL(@NDG_DiscountSum, 0))
		BEGIN
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1007, @ODG_DiscountSum, @NDG_DiscountSum, null, null, null, null, 0, @bNeedCommunicationUpdate output
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
			SET @sAction = 'RECALCULATE_BY_TODAY_CURRENCY_RATE'

			-- See if "variable" is set (with frmDogovor (tour.apl) only)
			IF OBJECT_ID('tempdb..#RecalculateAction') IS NOT NULL
			BEGIN
				SELECT @sAction = [Action] FROM #RecalculateAction
				DROP TABLE #RecalculateAction
			END
	
			EXEC dbo.NationalCurrencyPrice @ODG_Rate, @NDG_Rate, @ODG_Code, @NDG_Price, @ODG_Price, @NDG_DiscountSum, @sAction, @NDG_SOR_Code
	  END
	  END

		-- recalculate if exchange rate changes (another table) & saving from frmDogovor (tour.apl)
		-- + force-drop #RecalculateAction table in case hasn't been
		IF OBJECT_ID('tempdb..#RecalculateAction') IS NOT NULL
		BEGIN
			SELECT @sAction = [Action] FROM #RecalculateAction
			DROP TABLE #RecalculateAction

			-- Нам надо , чтобы пересчет осуществлялся ТОЛЬКО
			-- при создании путевки
			-- при ее подтверждении (переход в статус Ок или ОК)
			-- при изменении валютной стоимости
			-- 00024586
			-- EXEC dbo.NationalCurrencyPrice @ODG_Rate, @NDG_Rate, @ODG_Code, @NDG_Price, @ODG_Price, @NDG_DiscountSum, @sAction, @NDG_SOR_Code
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

-- T_InsteadOfUpdate_TurList.sql
-- 7.2 - 9.2
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfUpdateTurList]
GO

CREATE TRIGGER [dbo].[T_InsteadOfUpdateTurList]
	ON [dbo].[tbl_TurList]
	INSTEAD OF UPDATE
AS
begin

	declare @TLCnKey int
	declare @TLKey int
	declare @TLName varchar(160)
	declare @TLTypeCount smallint
	declare @TLProfit float
	declare @TLPrice float
	declare @TLNDay smallint
	declare @TLCreator int
	declare @TLDescription varchar(1024)
	declare @TLRemark varchar(240)
	declare @TLRate varchar(3)
	declare @TLWEBHTTP varchar(128)
	declare @TLNameWeb varchar(128)
	declare @TLWeb int
	declare @TLDateDoc int
	declare @TLDateDocVisa int
	declare @TLTip int
	declare @TLWebCost varchar(1024)
	declare @TLEMail varchar(255)
	declare @TLDateQuotes int
	declare @TLDatePayed int
	declare @TLDfltPaymentPcnt float
	declare @TLMargin decimal(5,2)
	declare @TLMarginType smallint
	declare @TLPrKey int
	declare @TLOpKey int
	declare @TLIsDisabled smallint
	declare @TLRGKey int
	declare @TLAdvDesc varchar(1024)
	declare @TLAttDesc varchar(1024)
	declare @TLDopDesc varchar(1024)
	declare @TLFullDesc varchar(1024)
	declare @TLSmallDesc varchar(1024)
	declare @TLDeleted smallint
	declare @TLLeadDepartment int
	declare @TLNameLat varchar(160)
	declare @TLCTDepartureKey int
	declare @TLWebHttpPers varchar(128)
	declare @TLAttribute int

	declare @settingValue varchar(254)
	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
	if (ISNULL(@settingValue, '0') = '0')
	begin

		DECLARE cur_TurListUpdate1 CURSOR FOR
			SELECT TL_CNKEY, TL_KEY, TL_NAME, TL_TYPECOUNT, TL_PROFIT, TL_PRICE, TL_NDAY, TL_CREATOR, TL_DESCRIPTION, TL_REMARK,
				   TL_RATE, TL_WEBHTTP, TL_NAMEWEB, TL_WEB, TL_DATEDOC, TL_DATEDOCVISA, TL_TIP, TL_WEBCOST, TL_EMAIL,
				   TL_datequotes, TL_datepayed, TL_DfltPaymentPcnt, TL_Margin, TL_MarginType, TL_PRKey, TL_OpKey,
				   TL_IsDisabled, TL_RGKEY, TL_ADVDESC, TL_ATTDESC, TL_DOPDESC, TL_FULLDESC, TL_SMALLDESC, TL_Deleted,
				   TL_LEADDEPARTMENT, TL_NameLat, TL_CTDepartureKey, tl_webHttpPers, TL_Attribute
			FROM Inserted

		OPEN cur_TurListUpdate1
		FETCH NEXT FROM cur_TurListUpdate1
		into @TLCnKey, @TLKey, @TLName, @TLTypeCount, @TLProfit, @TLPrice, @TLNDay, @TLCreator, @TLDescription, @TLRemark, 
			 @TLRate, @TLWEBHTTP, @TLNameWeb, @TLWeb, @TLDateDoc, @TLDateDocVisa, @TLTip, @TLWebCost, @TLEMail, 
			 @TLDateQuotes, @TLDatePayed, @TLDfltPaymentPcnt, @TLMargin, @TLMarginType, @TLPrKey, @TLOpKey, 
			 @TLIsDisabled, @TLRGKey, @TLAdvDesc, @TLAttDesc, @TLDopDesc, @TLFullDesc, @TLSmallDesc, @TLDeleted, 
			 @TLLeadDepartment, @TLNameLat, @TLCTDepartureKey, @TLWebHttpPers, @TLAttribute

		WHILE @@FETCH_STATUS = 0
		BEGIN
			update tbl_TurList set TL_CNKEY = @TLCnKey, TL_NAME = @TLName, TL_TYPECOUNT = @TLTypeCount, TL_PROFIT = @TLProfit,
				TL_PRICE = @TLPrice, TL_NDAY = @TLNDay, TL_CREATOR = @TLCreator, TL_DESCRIPTION = @TLDescription, TL_REMARK = @TLRemark,
				TL_RATE = @TLRate, TL_WEBHTTP = @TLWEBHTTP, TL_NAMEWEB = @TLNameWeb, TL_WEB = @TLWeb, TL_DATEDOC = @TLDateDoc,
				TL_DATEDOCVISA = @TLDateDocVisa, TL_TIP = @TLTip, TL_WEBCOST = @TLWebCost, TL_EMAIL = @TLEMail,
				TL_datequotes = @TLDateQuotes, TL_datepayed = @TLDatePayed, TL_DfltPaymentPcnt = @TLDfltPaymentPcnt,
				TL_Margin = @TLMargin, TL_MarginType = @TLMarginType, TL_PRKey = @TLPrKey, TL_OpKey = @TLOpKey,
				TL_IsDisabled = @TLIsDisabled, TL_RGKEY = @TLRGKey, TL_ADVDESC = @TLAdvDesc, TL_ATTDESC = @TLAttDesc,
				TL_DOPDESC = @TLDopDesc, TL_FULLDESC = @TLFullDesc, TL_SMALLDESC = @TLSmallDesc, TL_Deleted = @TLDeleted,
				TL_LEADDEPARTMENT = @TLLeadDepartment, TL_NameLat = @TLNameLat, TL_CTDepartureKey = @TLCTDepartureKey,
				tl_webHttpPers = @TLWebHttpPers, TL_Attribute = @TLAttribute
			where TL_Key = @TLKey

			FETCH NEXT FROM cur_TurListUpdate1
			into @TLCnKey, @TLKey, @TLName, @TLTypeCount, @TLProfit, @TLPrice, @TLNDay, @TLCreator, @TLDescription, @TLRemark, 
				@TLRate, @TLWEBHTTP, @TLNameWeb, @TLWeb, @TLDateDoc, @TLDateDocVisa, @TLTip, @TLWebCost, @TLEMail, 
				@TLDateQuotes, @TLDatePayed, @TLDfltPaymentPcnt, @TLMargin, @TLMarginType, @TLPrKey, @TLOpKey, 
				@TLIsDisabled, @TLRGKey, @TLAdvDesc, @TLAttDesc, @TLDopDesc, @TLFullDesc, @TLSmallDesc, @TLDeleted, 
				@TLLeadDepartment, @TLNameLat, @TLCTDepartureKey, @TLWebHttpPers, @TLAttribute
		END

		CLOSE cur_TurListUpdate1
		DEALLOCATE cur_TurListUpdate1
		
		return
	end

	declare @nOwnerKey int
	declare @nFilialKey int
	set @nOwnerKey = 1
	set @nFilialKey = 2

	declare @userKey int
	declare @userPartnerKey int
	declare @userFilialKey int
	
	declare @tourKey int
	declare @tourCreator int
	declare @tourPartnerKey int
	declare @tourFilialKey int

	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

	if (@userFilialKey is null)
		return

	DECLARE cur_TurListUpdate CURSOR FOR
		SELECT D.TL_KEY, D.TL_CREATOR
		FROM Deleted d

	OPEN cur_TurListUpdate
	FETCH NEXT FROM cur_TurListUpdate
	INTO @tourKey, @tourCreator
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey

		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
		begin

			SELECT @TLCnKey = TL_CNKEY, @TLName = TL_NAME, @TLTypeCount = TL_TYPECOUNT, @TLProfit = TL_PROFIT, 
				   @TLPrice = TL_PRICE, @TLNDay = TL_NDAY, @TLCreator = TL_CREATOR, @TLDescription = TL_DESCRIPTION, @TLRemark = TL_REMARK,
				   @TLRate = TL_RATE, @TLWEBHTTP = TL_WEBHTTP, @TLNameWeb = TL_NAMEWEB, @TLWeb = TL_WEB, @TLDateDoc = TL_DATEDOC, 
				   @TLDateDocVisa = TL_DATEDOCVISA, @TLTip = TL_TIP, @TLWebCost = TL_WEBCOST, @TLEMail = TL_EMAIL,
				   @TLDateQuotes = TL_datequotes, @TLDatePayed = TL_datepayed, @TLDfltPaymentPcnt = TL_DfltPaymentPcnt, 
				   @TLMargin = TL_Margin, @TLMarginType = TL_MarginType, @TLPrKey = TL_PRKey, @TLOpKey = TL_OpKey,
				   @TLIsDisabled = TL_IsDisabled, @TLRGKey = TL_RGKEY, @TLAdvDesc = TL_ADVDESC, @TLAttDesc = TL_ATTDESC, 
				   @TLDopDesc = TL_DOPDESC, @TLFullDesc = TL_FULLDESC, @TLSmallDesc = TL_SMALLDESC, @TLDeleted = TL_Deleted,
				   @TLLeadDepartment = TL_LEADDEPARTMENT, @TLNameLat = TL_NameLat, @TLCTDepartureKey = TL_CTDepartureKey, 
				   @TLWebHttpPers = tl_webHttpPers, @TLAttribute = TL_Attribute
			FROM Inserted
			where TL_Key = @tourKey

			update tbl_TurList set TL_CNKEY = @TLCnKey, TL_NAME = @TLName, TL_TYPECOUNT = @TLTypeCount, TL_PROFIT = @TLProfit,
				TL_PRICE = @TLPrice, TL_NDAY = @TLNDay, TL_CREATOR = @TLCreator, TL_DESCRIPTION = @TLDescription, TL_REMARK = @TLRemark,
				TL_RATE = @TLRate, TL_WEBHTTP = @TLWEBHTTP, TL_NAMEWEB = @TLNameWeb, TL_WEB = @TLWeb, TL_DATEDOC = @TLDateDoc,
				TL_DATEDOCVISA = @TLDateDocVisa, TL_TIP = @TLTip, TL_WEBCOST = @TLWebCost, TL_EMAIL = @TLEMail,
				TL_datequotes = @TLDateQuotes, TL_datepayed = @TLDatePayed, TL_DfltPaymentPcnt = @TLDfltPaymentPcnt,
				TL_Margin = @TLMargin, TL_MarginType = @TLMarginType, TL_PRKey = @TLPrKey, TL_OpKey = @TLOpKey,
				TL_IsDisabled = @TLIsDisabled, TL_RGKEY = @TLRGKey, TL_ADVDESC = @TLAdvDesc, TL_ATTDESC = @TLAttDesc,
				TL_DOPDESC = @TLDopDesc, TL_FULLDESC = @TLFullDesc, TL_SMALLDESC = @TLSmallDesc, TL_Deleted = @TLDeleted,
				TL_LEADDEPARTMENT = @TLLeadDepartment, TL_NameLat = @TLNameLat, TL_CTDepartureKey = @TLCTDepartureKey,
				tl_webHttpPers = @TLWebHttpPers, TL_Attribute = @TLAttribute
			where TL_Key = @TLKey
			
		end

		FETCH NEXT FROM cur_TurListUpdate 
		INTO @tourKey, @tourCreator
	END
	CLOSE cur_TurListUpdate
	DEALLOCATE cur_TurListUpdate
end
GO

-- sp_SetServicesToOK.sql
-- 7.2 - 9.2
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetServicesToOK]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure dbo.SetServicesToOK
GO
CREATE procedure [dbo].[SetServicesToOK]
(
	@nDgKey int,
	@nStatus smallint
)
AS

Update ServiceByDate set SD_State = 3 where SD_DLKey IN (Select DL_Key from DogovorList where DL_DGKey = @nDgKey)
Update Dogovor set DG_Sor_Code = @nStatus

GO

GRANT EXECUTE ON dbo.SetServicesToOK TO PUBLIC 
GO

-- T_InsteadOfDelete_Costs.sql
-- 7.2 - 9.2
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteCost]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfDeleteCost]
GO

CREATE TRIGGER [dbo].[T_InsteadOfDeleteCost]
	ON [dbo].[tbl_Costs]
	INSTEAD OF DELETE
AS
begin

	declare @settingValue varchar(254)
	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSCostFilialSecControl'
	if (ISNULL(@settingValue, '0') = '0')
	begin
		delete from tbl_Costs where CS_ID in (select CS_ID from Deleted)
		return
	end

	declare @nOwnerKey int
	declare @nFilialKey int
	set @nOwnerKey = 1
	set @nFilialKey = 2

	declare @userKey int
	declare @userPartnerKey int
	declare @userFilialKey int
	
	declare @costKey int
	declare @costCreator int
	declare @costPartnerKey int
	declare @costFilialKey int

	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

	if (@userFilialKey is null)
		return

	if (@userFilialKey = @nOwnerKey)
	begin
		delete from tbl_Costs where CS_ID in (select CS_ID from Deleted)
		return
	end

	DECLARE cur_CostDelete CURSOR FOR
		SELECT D.CS_ID, D.CS_CREATOR
		FROM Deleted d

	OPEN cur_CostDelete
	FETCH NEXT FROM cur_CostDelete
	INTO @costKey, @costCreator
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		select @costPartnerKey = US_PRKey from UserList where US_Key = @costCreator
		select @costFilialKey = PR_Filial from tbl_Partners where PR_Key = @costPartnerKey

		if (@userFilialKey = @costFilialKey)
		begin
			delete from tbl_Costs where CS_ID = @costKey
		end

		FETCH NEXT FROM cur_CostDelete
		INTO @costKey, @costCreator
	END
	CLOSE cur_CostDelete
	DEALLOCATE cur_CostDelete
end
GO

-- 091110(FileHeaders).sql
-- 7.2 - 9.2
	
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FileHeaders]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[FileHeaders](
	[FH_ID] [int] IDENTITY(1,1) NOT NULL,
	[FH_FileName] [varchar](255) NOT NULL,
	[FH_FileSize] [int] NOT NULL,
	[FH_Date] [datetime] NOT NULL,
	[FH_Md5] [varchar](32) NULL,
	[FH_Guid] [uniqueidentifier] NULL,
	[FH_IsCompressed] [bit] NULL,
	[FH_USKEY] [int] NOT NULL,
	[FH_DocType] [int] NULL,
	[FH_Comment] [varchar](100) NULL
 CONSTRAINT [PK_FileHeaders] PRIMARY KEY CLUSTERED 
(
	[FH_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO

grant select,insert,update,delete on dbo.[FileHeaders] to public
GO 

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FileRepos]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[FileRepos](
	[FR_ID] [int] IDENTITY(1,1) NOT NULL,
	[FR_Data] [image] NOT NULL,
	[FR_FHID] [int] NOT NULL,
 CONSTRAINT [PK_FileRepos] PRIMARY KEY CLUSTERED 
(
	[FR_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_FileRepos_FileHeaders]'))
ALTER TABLE [dbo].[FileRepos]  WITH CHECK ADD  CONSTRAINT [FK_FileRepos_FileHeaders] FOREIGN KEY([FR_FHID])
REFERENCES [dbo].[FileHeaders] ([FH_ID])
ON DELETE CASCADE
Go

grant select,insert,update,delete on dbo.[FileRepos] to public
GO 

-- T_InsteadOfInsert_TurDate.sql
-- 7.2 - 9.2
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfInsertTurDate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfInsertTurDate]
GO

CREATE TRIGGER [dbo].[T_InsteadOfInsertTurDate]
	ON [dbo].[TurDate]
	INSTEAD OF INSERT
AS
begin

	declare @tourDateKey int

	declare @TDTrKey int
	declare @TDDate datetime
	declare @TDId int

	declare @settingValue varchar(254)
	select @settingValue = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSTourFilialSecControl'
	if (ISNULL(@settingValue, '0') = '0')
	begin

		insert into TurDate (TD_TRKEY, TD_DATE)
		select i.TD_TRKEY, i.TD_DATE from Inserted i
		
		return
	end

	declare @nOwnerKey int
	declare @nFilialKey int
	set @nOwnerKey = 1
	set @nFilialKey = 2

	declare @userKey int
	declare @userPartnerKey int
	declare @userFilialKey int
	
	declare @tourKey int
	declare @tourCreator int
	declare @tourPartnerKey int
	declare @tourFilialKey int

	select @userKey = US_Key, @userPartnerKey = US_PRKEY from UserList where US_USERID = SYSTEM_USER
	select @userFilialKey = PR_Filial from tbl_Partners where PR_Key = @userPartnerKey

	if (@userFilialKey is null)
		return

	DECLARE cur_TurDateInsert CURSOR FOR
		SELECT i.TD_ID, TL_CREATOR, TL_Key
		FROM Inserted i join TurList on TD_TRKEY = TL_KEY

	OPEN cur_TurDateInsert
	FETCH NEXT FROM cur_TurDateInsert
	INTO @tourDateKey, @tourCreator, @tourKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		select @tourPartnerKey = US_PRKey from UserList where US_Key = @tourCreator
		select @tourFilialKey = PR_Filial from tbl_Partners where PR_Key = @tourPartnerKey

		if (@userFilialKey = @tourFilialKey or @userFilialKey = @nOwnerKey)
		begin

			insert into TurDate (TD_TRKEY, TD_DATE, TD_ID)
			select i.TD_TRKEY, i.TD_DATE, i.TD_ID from Inserted i where i.TD_ID = @tourDateKey
			
		end

		FETCH NEXT FROM cur_TurDateInsert
		INTO @tourDateKey, @tourCreator, @tourKey
	END
	CLOSE cur_TurDateInsert
	DEALLOCATE cur_TurDateInsert
end
GO

-- 091113(AlterTable_Dogovor).sql
-- 7.2 - 9.2
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[tbl_dogovor]') and name = 'DG_DAKey')
	ALTER TABLE dbo.tbl_dogovor ADD DG_DAKey money NULL
GO

Update dbo.tbl_dogovor set DG_DAKey = 
CAST(ISNULL(HI_TEXT, '0') AS INT)
from History
where HI_DGCOD = DG_Code and HI_OAId = 25
GO

exec sp_RefreshViewForAll 'Dogovor'
GO

-- sp_CalculatePriceList.sql
-- 7.2 - 9.2
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
	@nPLNotDeleted smallint		-- PriceList: 0 - удалять дублирующиеся цены, 1 - не удалять
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

declare @calculatingPriceListsExists smallint -- 0 - CalculatingPriceLists нет, 1 - CalculatingPriceLists есть в базе

BEGIN
	select @TrKey = to_trkey, @userKey = to_opkey from tp_tours where to_key = @nPriceTourKey

	delete from CalculatingPriceLists where CP_PriceTourKey not in (select to_key from tp_tours)

	if not exists (select 1 from CalculatingPriceLists where CP_PriceTourKey = @nPriceTourKey)
	begin
		insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_PriceList2006, CP_PLNotDeleted, CP_TourKey, CP_UserKey, CP_Status)
		values (@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @nPriceList2006, @nPLNotDeleted, @TrKey, @userKey, 1)	
	end
	else
	begin
		update CalculatingPriceLists set CP_Status = 1, CP_StartTime = null where CP_PriceTourKey = @nPriceTourKey
	end

	DECLARE @sHI_Text varchar(254), @nHIID int
	SELECT @sHI_Text=TO_Name FROM tp_tours where to_key = @nPriceTourKey
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

	--delete from CalculatingPriceLists where CP_TourKey = @TrKey
	--insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_PriceList2006, CP_PLNotDeleted, CP_TourKey, CP_UserKey)
	--values (@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @nPriceList2006, @nPLNotDeleted, @TrKey, @userKey)

	Set @nTotalProgress=1
	update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	select @nDateFirst = @@DATEFIRST
	set DATEFIRST 1
	set @SERV_NOTCALCULATE = 32768

	--Настройка (использовать связку обсчитанных цен с текущими ценами, пока не реализована)
	select @sUseServicePrices = SS_ParmValue from systemsettings where SS_ParmName = 'UseServicePrices'

	If @nUpdate=0
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey, 
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2
			From TP_Services, TP_TurDates, TP_Tours
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TO_Key = @nPriceTourKey
	Else
	BEGIN
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey, 
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2
			From TP_Services, TP_TurDates, TP_Tours
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TO_Key = @nPriceTourKey
			and not exists (Select TF_ID From TP_Flights Where TF_TOKey=TO_Key and TF_Date=(TD_Date + TS_Day - 1) 
						and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
						and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2)		
	END

--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld,
				TF_PRKeyNew = TF_PRKeyOld
	Where	(SELECT count(*) FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') > 0 
		and TF_TOKey = @nPriceTourKey

	If @nNoFlight = 2
	BEGIN
		------ проверяем, а есть ли у данного парнера по рейсу, цены на другие рейсы в этом же пакете ----
		IF exists(SELECT TF_ID FROM TP_Flights WHERE TF_TOKey = @nPriceTourKey and TF_CodeNew is Null) 
			Update	TP_Flights Set 	TF_CodeNew = (	SELECT top 1 CH_Key
							FROM AirSeason, Charter, Costs
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

		------ проверяем, а есть ли у кого-нибудь цены на любой рейс в этом же пакете ----
		IF exists(SELECT TF_ID FROM TP_Flights WHERE TF_TOKey = @nPriceTourKey and TF_CodeNew is Null) 
			Update	TP_Flights Set 	TF_CodeNew = (	SELECT top 1 CH_Key
								FROM AirSeason, Charter, Costs
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
								FROM AirSeason, Charter, Costs
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
	END
	-----если перелет так и не найден, то в поле TF_CodeNew будет NULL

	--------------------------------------- закончили поиск подходящего перелета --------------------------------------

	if ISNULL((select to_update from [dbo].tp_tours where to_key = @nPriceTourKey),0) <> 1
	BEGIN
		update [dbo].tp_tours set to_update = 1 where to_key = @nPriceTourKey
		Set @nTotalProgress=4
		update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	
		--------------------------------------- сохраняем цены во временной таблице --------------------------------------
		DECLARE @TP_Prices TABLE (
			[xTP_Key] [int] PRIMARY KEY NOT NULL ,
			[xTP_TOKey] [int] NOT NULL ,
			[xTP_DateBegin] [datetime] NOT NULL ,
			[xTP_DateEnd] [datetime] NULL ,
			[xTP_Gross] [money] NULL ,
			[xTP_TIKey] [int] NOT NULL 
		)
		DELETE FROM @TP_Prices
		--INSERT INTO @TP_Prices (xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey) select tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey from tp_prices where tp_tokey = @nPriceTourKey
		---------------------------------------КОНЕЦ  сохраняем цены во временной таблице --------------------------------------
		
		---------------------------------------разбиваем данные в таблицах tp_prices по датам
		if (select COUNT(TP_Key) from TP_Prices where TP_DateBegin != TP_DateEnd and TP_TOKey = @nPriceTourKey) > 0
		begin
			select @numDates = COUNT(1) from TP_TurDates, TP_Lists, TP_Prices where TP_TIKey = TI_Key and TD_Date between TP_DateBegin and TP_DateEnd and TP_TOKey = @nPriceTourKey and TD_TOKey = @nPriceTourKey and TI_TOKey = @nPriceTourKey
			exec GetNKeys 'TP_PRICES', @numDates, @nTP_PriceKeyMax output
			set @nTP_PriceKeyCurrent = @nTP_PriceKeyMax - @numDates + 1
		
			declare datesCursor cursor local fast_forward for
			select TD_Date, TI_Key, TP_Gross from TP_TurDates, TP_Lists, TP_Prices where TP_TIKey = TI_Key and TD_Date between TP_DateBegin and TP_DateEnd and TP_TOKey = @nPriceTourKey and TD_TOKey = @nPriceTourKey and TI_TOKey = @nPriceTourKey
			
			open datesCursor
			fetch next from datesCursor into @priceDate, @priceListKey, @priceListGross
			while @@FETCH_STATUS = 0
			begin
				insert into @TP_Prices (xTP_Key, xTP_TOKey, xTP_TIKey, xTP_Gross, xTP_DateBegin, xTP_DateEnd) 
				values (@nTP_PriceKeyCurrent, @nPriceTourKey, @priceListKey, @priceListGross, @priceDate, @priceDate)
				set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
				fetch next from datesCursor into @priceDate, @priceListKey, @priceListGross
			end
			
			close datesCursor
			deallocate datesCursor
			
			begin tran tEnd
				delete from TP_Prices where TP_TOKey = @nPriceTourKey
				
				insert into TP_Prices (TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd)
				select xTP_Key, xTP_TOKey, xTP_TIKey, xTP_Gross, xTP_DateBegin, xTP_DateEnd from @TP_Prices  
				where xTP_DateBegin = xTP_DateEnd
				
				delete from @TP_Prices
			commit tran tEnd
		end
		--------------------------------------------------------------------------------------
		
		select @TrKey = to_trkey, @nPriceFor = to_pricefor from tp_tours where to_key = @nPriceTourKey

		--смотрим сколько записей по текущему прайсу уже посчитано	
		Set @NumCalculated = (SELECT COUNT(1) FROM tp_prices where tp_tokey = @nPriceTourKey)
		--считаем сколько записей надо посчитать
		set @NumPrices = ((select count(1) from tp_lists where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) * (select count(1) from tp_turdates where td_tokey = @nPriceTourKey and td_update = @nUpdate))

		if (@NumCalculated + @NumPrices) = 0
			set @NumPrices = 1

		Set @nTotalProgress=@nTotalProgress + (CAST(@NumCalculated as money)/CAST((@NumCalculated+@NumPrices) as money) * (90-@nTotalProgress))
		update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey

		----------------------------------------------------------- Здесь апдейтим TS_CHECKMARGIN и TD_CHECKMARGIN
		update tp_services set ts_checkmargin = 1 where
		(ts_svkey in (select tm_svkey FROM TurMargin, tp_turdates
		WHERE	TM_TlKey = @TrKey and td_tokey = @nPriceTourKey
			and td_date Between TM_DateBeg and TM_DateEnd
			and (@dtSaleDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@dtSaleDate <= TM_DateSellEnd or TM_DateSellEnd is null)
		)
		or
		exists(select 1 FROM TurMargin, tp_turdates
		WHERE	TM_TlKey = @TrKey and td_tokey = @nPriceTourKey
			and td_date Between TM_DateBeg and TM_DateEnd
			and (@dtSaleDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@dtSaleDate <= TM_DateSellEnd or TM_DateSellEnd is null)
			and tm_svkey = 0)
		)and ts_tokey = @nPriceTourKey

		update [dbo].tp_turdates set td_checkmargin = 1 where
			exists(select 1 from TurMargin WHERE TM_TlKey = @TrKey
			and TD_DATE Between TM_DateBeg and TM_DateEnd
			and (@dtSaleDate >= TM_DateSellBeg  or TM_DateSellBeg is null)
			and (@dtSaleDate <= TM_DateSellEnd or TM_DateSellEnd is null)
		)and td_tokey = @nPriceTourKey
		----------------------------------------------------------- Здесь апдейтим TS_CHECKMARGIN и TD_CHECKMARGIN

		update TP_Services set ts_tempgross = null where ts_tokey = @nPriceTourKey
		declare serviceCursor cursor local fast_forward for
			select ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, to_rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_days, ts_ctkey, ts_attribute
			from tp_tours, tp_services, tp_lists, tp_servicelists, tp_turdates
			where to_key = @nPriceTourKey and to_key = ts_tokey and to_key = ti_tokey and to_key = tl_tokey and ts_key = tl_tskey and ti_key = tl_tikey and to_key = td_tokey
				and ti_update = @nUpdate and td_update = @nUpdate
			order by ti_firsthdkey, td_date, ti_key

		open serviceCursor
		SELECT @round = ST_RoundService FROM Setting
		set @nProgressSkipLimit = 50

		set @nProgressSkipCounter = 0
		Set @nTotalProgress = @nTotalProgress + 1
		update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey

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

		fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_DAYS, @TS_CTKEY, @TS_ATTRIBUTE
		set @fetchStatus = @@fetch_status
		While (@fetchStatus = 0)
		BEGIN

			--данных не нашлось, выходим
			if @@fetch_status <> 0 and @nPrevVariant = -1
				break
				
			--очищаем переменные, записываем данные в таблицу @TP_Prices
			if @nPrevVariant <> @variant or @dtPrevDate <> @turdate or @@fetch_status <> 0
			BEGIN
				--записываем данные в таблицу @TP_Prices
				if @nPrevVariant <> -1
				begin
					if @price_brutto is not null
					BEGIN
						exec RoundPriceList @round, @price_brutto output
						
						if exists(select 1 from @TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant)
						begin
							update @TP_Prices set xtp_gross = @price_brutto where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
							
							if @sUseServicePrices = '1'
								delete from TP_PriceDetails where PD_TPKey = @nTP_PriceKeyCurrent
						end
						else
						begin
							insert into @TP_Prices (xtp_key, xtp_tokey, xtp_datebegin, xtp_dateend, xtp_gross, xtp_tikey) 
							values (@nTP_PriceKeyCurrent, @nPriceTourKey, @dtPrevDate, @dtPrevDate, @price_brutto, @nPrevVariant)
							
							if @sUseServicePrices = '1'
								delete from TP_PriceDetails where PD_TPKey = @nTP_PriceKeyCurrent
							
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
					update tp_tours set to_progress = @nTotalProgress, to_updatetime = GetDate() where to_key = @nPriceTourKey
					set @nProgressSkipCounter = 0
				END
				else
					set @nProgressSkipCounter = @nProgressSkipCounter + 1
			END

			--переписываем данные в таблицу tp_prices
			if @hdKey <> @prevHdKey or @@fetch_status <> 0
			begin
				if @prevHdKey <> -1
				begin
					begin tran tEnd
						delete from tp_prices where tp_tokey = @nPriceTourKey and tp_tikey in (select ti_key from tp_lists where ti_tokey = @nPriceTourKey and ti_firsthdkey = @prevHdKey)
						insert into tp_prices (tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey) select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey from @TP_Prices where xtp_tokey = @nPriceTourKey
						delete from @TP_Prices
						update tp_lists set ti_update = 2 where ti_tokey = @nPriceTourKey and ti_firsthdkey = @prevHdKey
					commit tran tEnd
				end
				set @prevHdKey = @hdKey
				
				if @@fetch_status = 0
					insert into @TP_Prices (xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey) select tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey from tp_prices where tp_tokey = @nPriceTourKey and tp_tikey in (select ti_key from tp_lists where ti_tokey = @nPriceTourKey and ti_firsthdkey = @hdKey)
			end
			
			if @@fetch_status <> 0
				break
						
			---------------------------------------------------------------------------------
			
			if @dtPrevDate <> @turdate
				update tp_services set ts_tempgross = null where ts_tokey = @nPriceTourKey
				
			if @nTempGross is not null and @nSvkey <> 1
			begin
				if @sUseServicePrices = '1'
				BEGIN
					select @nBrutto = SP_Price, @nBruttoWithCommission = SP_PriceWithCommission, @nMargin = PD_Margin, @nMarginType = PD_MarginType from dbo.ServicePrices,TP_PaymentDetails where PD_ID = @nPDId and PD_SPID = SP_ID
					exec GetTourMargin @TrKey, @turdate, @nMargin output, @nMarginType output, @nSvkey, @TI_DAYS, @dtSaleDate, @nPacketkey
					If @nMarginType = 0 -- даем наценку, вне зависмости от наличия комиссии по услуге
						Set @nBrutto = @nBrutto + @nBrutto * @nMargin / 100
					Else -- даем наценку, только при наличии комиссии
						Set @nBrutto = @nBrutto + @nBruttoWithCommission * @nMargin / 100

					insert into TP_PriceDetails (PD_SPID, PD_TPKey, PD_Margin, PD_MarginType) values (@nSPId, @nTP_PriceKeyCurrent, @nMargin, @nMarginType)
				END
				else
					set @nBrutto = @nTempGross
			end
			else
			begin
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
						FROM	TP_Flights
						WHERE	TF_TOKey = @nPriceTourKey AND
								TF_CodeOld = @nCode AND
								TF_PRKeyOld = @nPrkey AND
								TF_Date = @servicedate
					END	
					Set @nSPId = null		
					Set @nBrutto = null	
					if @nCode is not null
						exec GetServiceCost @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @servicedate, @nDays, @sRate, @nMen, 0, @nMargin, @nMarginType, @dtSaleDate, @nNetto output, @nBrutto output, @nDiscount output, @sDetailed output, @sBadRate output, @dtBadDate output, @sDetailed output, @nSPId output
					else
						set @nBrutto = null
					--insert into Debug (db_n1, db_n2, db_n3) values (@nTP_PriceKeyCurrent, @nBrutto, @nSPId)

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
				If @nSPId is not null and @sUseServicePrices = '1'
					update tp_services set ts_tempgross = @nPDID where ts_key = @nServiceKey
				else if @sUseServicePrices != '1'
					update tp_services set ts_tempgross = @nBrutto where ts_key = @nServiceKey
			end
			set @price_brutto = @price_brutto + @nBrutto
			---------------------------------------------------------------------------------
			fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_DAYS, @TS_CTKEY, @TS_ATTRIBUTE
		END
		close serviceCursor
		deallocate serviceCursor

		----------------------------------------------------- возвращаем обратно цены ------------------------------------------------------
		--Set @nTotalProgress = 96
		--update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		--delete from tp_prices where tp_tokey = @nPriceTourKey

		Set @nTotalProgress = 97
		update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey

		declare @nRowPart int
		set @nRowPart = 200
		declare @TPkeyMax int
		declare @TPkeyMin int
		--select 	@TPkeyMax = MAX(xtp_key), 
		--		@TPkeyMin = MIN(xtp_key) 
		--from 	@TP_Prices

		--while 	@TPkeyMin <= @TPkeyMax
		--BEGIN
		--	begin tran tEnd
		--	INSERT INTO TP_Prices (tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey) 
		--		select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, xTP_Gross, xTP_TIKey from @TP_Prices where xtp_key between @TPkeyMin and @TPkeyMin + @nRowPart
		--	commit tran tEnd
		--	Set @TPkeyMin = @TPkeyMin + @nRowPart + 1
		--END

		-----------------------------------------------------КОНЕЦ возвращаем обратно цены ------------------------------------------------------

		update tp_lists set ti_update = 0 where ti_tokey = @nPriceTourKey
		update tp_turdates set td_update = 0, td_checkmargin = 0 where td_tokey = @nPriceTourKey
		Set @nTotalProgress = 99
		update tp_tours set to_progress = @nTotalProgress, to_update = 0, to_updatetime = GetDate(),
							TO_CalculateDateEnd = GetDate(), TO_PriceCount = (Select Count(*) 
			From TP_Prices Where TP_ToKey = to_key) where to_key = @nPriceTourKey
		update tp_services set ts_checkmargin = 0 where ts_tokey = @nPriceTourKey
	END

	update CalculatingPriceLists set CP_Status = 0, CP_CreateDate = GetDate() where CP_PriceTourKey = @nPriceTourKey
	--delete from CalculatingPriceLists where CP_PriceTourKey = @nPriceTourKey


	-----------------------------------------------------------------------

	update tp_lists with(rowlock)
	set
		ti_firsthotelday = (select min(ts_day) 
				from tp_services with (nolock)
 				where ts_svkey = 3 and ts_tokey = ti_tokey)
	where
		ti_tokey = @nPriceTourKey

		update TP_Tours set TO_MinPrice = (
			select min(TP_Gross) 
			from TP_Prices 
				left join TP_Lists on ti_key = tp_tikey
				left join HotelRooms on hr_key = ti_firsthrkey
				
			where TP_TOKey = TO_Key and hr_main > 0 and isnull(HR_AGEFROM, 100) > 16
		)
		where TO_Key = @nPriceTourKey

	update TP_Tours set TO_HotelNights = dbo.mwTourHotelNights(TO_Key) where TO_Key = @nPriceTourKey

	update tp_lists with(rowlock)
	set
		ti_lasthotelday = (select max(ts_day)
				from tp_servicelists  with (nolock)
					inner join tp_services with (nolock) on tl_tskey = ts_key
				where tl_tikey = ti_key and ts_svkey = 3)
	where
		ti_tokey = @nPriceTourKey

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
		ti_tokey = @nPriceTourKey

	update tp_lists with(rowlock)
	set
		ti_nights = (select sum(ts_days) 
				from tp_servicelists with (nolock)
					inner join tp_services with (nolock) on tl_tskey = ts_key 
				where tl_tikey = ti_key and ts_svkey = 3)
	where
		ti_tokey = @nPriceTourKey

	update tp_lists with(rowlock)
		set ti_hotelkeys = dbo.mwGetTiHotelKeys(ti_key),
			ti_hotelroomkeys = dbo.mwGetTiHotelRoomKeys(ti_key),
			ti_hoteldays = dbo.mwGetTiHotelNights(ti_key),
			ti_hotelstars = dbo.mwGetTiHotelStars(ti_key),
			ti_pansionkeys = dbo.mwGetTiPansionKeys(ti_key)
	where
		ti_tokey = @nPriceTourKey

	update tp_lists with(rowlock)
	set
		ti_hdpartnerkey = ts_oppartnerkey,
		ti_firsthotelpartnerkey = ts_oppartnerkey,
		ti_hdday = ts_day,
		ti_hdnights = ts_days
	from tp_servicelists with (nolock)
		inner join tp_services with (nolock) on (tl_tskey = ts_key and ts_svkey = 3)
	where tl_tikey = ti_key and ts_code = ti_firsthdkey and ti_tokey = @nPriceTourKey and tl_tokey = @nPriceTourKey
		and ts_tokey = @nPriceTourKey

	-- город вылета
	update tp_lists
	set 
		ti_chkey = (select top 1 ts_code
			from tp_servicelists 
				inner join tp_services on (tl_tskey = ts_key and ts_svkey = 1)
				inner join tp_tours on ts_tokey = to_key inner join tbl_turList on tbl_turList.tl_key = to_trkey
			where tl_tikey = ti_key and ts_day <= tp_lists.ti_firsthotelday and ts_subcode2 = tl_ctdeparturekey)
	where ti_tokey = @nPriceTourKey 

	
	-- город вылета + прямой перелет
	update tp_lists
	set 
		ti_chday = ts_day,
		ti_chpkkey = ts_oppacketkey,
		ti_chprkey = ts_oppartnerkey
	from tp_servicelists inner join tp_services on (tl_tskey = ts_key and ts_svkey = 1)
		inner join tp_tours on ts_tokey = to_key inner join tbl_turList on tbl_turList.tl_key = to_trkey
	where tl_tikey = ti_key and ts_day <= tp_lists.ti_firsthotelday and ts_code = ti_chkey and ts_subcode2 = tl_ctdeparturekey
		and ti_tokey = @nPriceTourKey and tl_tokey = @nPriceTourKey and ts_tokey = @nPriceTourKey

	update tp_lists
	set 
		ti_ctkeyfrom = tl_ctdeparturekey
	from tp_tours inner join tbl_turList on tl_key = to_trkey
	where ti_tokey = to_key and to_key = @nPriceTourKey

	-- Проверка наличия перелетов в город вылета
	declare @existBackCharter smallint
	select	@existBackCharter = count(ts_key)
	from	tp_services
		inner join tp_tours on ts_tokey = to_key inner join tbl_turList on tbl_turList.tl_key = to_trkey
	where	ts_tokey = @nPriceTourKey
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
	from tp_servicelists
		inner join tp_services on (tl_tskey = ts_key and ts_svkey = 1)
		inner join tp_tours on ts_tokey = to_key inner join tbl_turList on tbl_turList.tl_key = to_trkey
	where 
		tl_tikey = ti_key 
		and ts_day > ti_lasthotelday
		and (ts_ctkey = tl_ctdeparturekey or @existBackCharter = 0)
		and ti_tokey = to_key
		and ti_tokey = @nPriceTourKey
		and tl_tokey = @nPriceTourKey
		and ts_tokey = @nPriceTourKey

	-- _ключ_ аэропорта вылета
	update tp_lists with(rowlock)
	set 
		ti_apkeyfrom = (select top 1 ap_key from airport, charter 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chkey)
	where
		ti_tokey = @nPriceTourKey

	-- _ключ_ аэропорта прилета
	update tp_lists with(rowlock)
	set 
		ti_apkeyto = (select top 1 ap_key from airport, charter 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chbackkey)
	where
		ti_tokey = @nPriceTourKey

	-- ключ города и ключ курорта + звезды
	update tp_lists
	set
		ti_firstctkey = hd_ctkey,
		ti_firstrskey = hd_rskey,
		ti_firsthdstars = hd_stars
	from hoteldictionary
	where 
		ti_tokey = @nPriceTourKey and
		ti_firsthdkey = hd_key



	------------------------------------------------------------------------

	if @nPriceList2006 is not null and @nPriceList2006 <> 0
	BEGIN
		-- -- -- -- -- запись в PriceList
		-- insert into History (Hi_date, Hi_text, Hi_SVKey) values (GetDate(), 'Начало расчета', @nPriceTourKey)
		delete from dbo.pricelist where pl_trkey=@TrKey
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
            from  dbo.TP_Lists, 
                        dbo.HotelRooms,
                        dbo.AccmdMenType,
                        dbo.HotelDictionary
            where TI_TOKey = @nPriceTourKey
                        and HR_Key = TI_FirstHrKey
                        and AC_Key = HR_ACKey
                        and HD_Key = TI_FirstHdKey
 
            update @TP_Lists Set xTI_RSName = (Select RS_Name From dbo.Resorts Where RS_Key = xTI_HDRSKey)
            update @TP_Lists Set xTI_PNCode = (Select PN_Code From dbo.Pansion Where PN_Key = xTI_FirstPnKey)
            update @TP_Lists Set xTI_RCName = (Select RC_Name From dbo.RoomsCategory Where RC_Key = xTI_RCKey)
            update @TP_Lists Set xTI_RMName = (Select RM_Name From dbo.Rooms Where RM_Key = xTI_RMKey)
            update @TP_Lists Set xTI_CTName = (Select CT_Name From dbo.CityDictionary Where CT_Key = xTI_HDCTKey)
 
            update @TP_Lists Set xti_su2 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists, dbo.TP_Services Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 1 and TS_Day != 1)

/*
					xti_chbackkey = TS_Code,
					xti_chbackday = TS_Day,
					xti_chbackpkkey = TS_OpPacketKey,
					xti_chbackprkey = TS_OpPartnerKey
*/
 
            update @TP_Lists Set xti_su1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists, dbo.TP_Services Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
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
                  From dbo.TP_ServiceLists, dbo.TP_Services Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 1 and TS_Day = 1)
 
            update @TP_Lists Set xti_sh1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_Days)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists, dbo.TP_Services Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 3)
 
            update @TP_Lists Set xti_st2 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists, dbo.TP_Services Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 2 and TS_Day != 1)
 
            update @TP_Lists Set xti_st1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists, dbo.TP_Services Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 2 and TS_Day = 1)
 
            update @TP_Lists Set xti_ss1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_Days)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists, dbo.TP_Services Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 6)
 
            update @TP_Lists Set xti_sv1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_Days)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists, dbo.TP_Services Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
                  and TS_SvKey = 5)
 
            update @TP_Lists Set xti_sd1 = (
                  Select TOP 1 LTRIM(STR(TS_Day)) + ',' + LTRIM(STR(TS_Code)) + ',' + LTRIM(STR(TS_SubCode1)) + ',' + LTRIM(STR(TS_SubCode2)) + ',' + LTRIM(STR(TS_Days)) + ',' + LTRIM(STR(TS_CtKey)) + ',' + LTRIM(STR(TS_Attribute)) + ',' + LTRIM(STR(TS_OpPacketKey)) + ',' + LTRIM(STR(TS_Men)) + ',' + LTRIM(STR(TS_OpPartnerKey))
                  From dbo.TP_ServiceLists, dbo.TP_Services Where TL_TOKey=@nPriceTourKey and TL_TIKey=xTI_Key and TS_Key=TL_TSKey
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
 
		select      @TPkeyMax = MAX(xtp_key), 
					@TPkeyMin = MIN(xtp_key) 
		from @TP_Prices
 
            Set @NumPrices = @TPkeyMax - @TPkeyMin + 1     -- определяем сколько нам понадобится сделать записей в таблицу pricelist
		declare @nPriceListKeyMax int                  -- максимально возможный ключ PriceList, который можно использовать
            exec GetNKeys 'PRICELIST', @NumPrices, @nPriceListKeyMax output
		declare @nDeltaTP_Price_PriceList int          -- разница в ключах между таблицами TP_Price и PriceList
            Set @nDeltaTP_Price_PriceList = (@nPriceListKeyMax - @NumPrices + 1) - @TPkeyMin
		declare @sURL varchar(250)                           -- ссылка, у Виталия Головченко называлась @u
		declare @sTLName varchar(160)
		declare @sTLWebHTTP varchar(128)
            select @sTLName = TL_Name, @sTLWebHTTP = TL_WebHTTP from dbo.TurList where TL_key = @TrKey
      
      -- начало. удаление похожих цен
		if @nPLNotDeleted = 0
			delete from dbo.pricelist where exists (
                        select      xTI_Key
                        from  @TP_Lists, TP_TurDates
                        where xTI_FirstHdKey = pl_hdkey_first and xTI_FirstHrKey = PL_ROOM
                                   and xTI_FirstPnKey = PL_PNKEY and xTI_Days = PL_NDays and ISNULL(xti_CityArr,-1) = ISNULL(PL_CITYARR,-1) 
                                   and TD_TOKey = @nPriceTourKey
                                   and TD_Date = PL_DATEBEG 
								   and exists (select 1 from @TP_Prices where TD_Date=xTP_DateBegin and xTP_TIKey=xTI_Key) )
		-- конец. удаление похожих цен
 
		while       @TPkeyMin <= @TPkeyMax
		BEGIN
            begin tran tEnd
                  insert into dbo.PRICELIST ( 
                        PL_KEY, PL_TI, PL_TO, PL_TP, 
                        PL_CREATOR, PL_DATEBEG, PL_DATEEND, PL_BRUTTO, 
                        PL_TRKEY, PL_NDays, PL_HDKEY_FIRST, PL_ROOM, 
                        PL_PANSION, PL_Category, PL_Main, PL_ACNMENAD, 
                        PL_ACNMENEXB, PL_ACAGEFROM1, PL_STARS, PL_HDNAME, 
                        PL_CNKEY, PL_HDCTKEY, PL_HDRSKEY, PL_URL, 
                        PL_CITYARR, PL_TLWEBHTTP, PL_HDHTTP, PL_ACNAME, 
                        PL_RCNAME, PL_RMNAME, PL_RSNAME, PL_RMKEY, 
                        PL_PNKEY, PL_TLNAME, PL_CTNAME) 
                  select @nDeltaTP_Price_PriceList + xtp_key, xTP_TIKey, xtp_tokey, xtp_key, 
                        0, xtp_dateBegin, xtp_DateEnd, xTP_Gross, 
                        @TrKey, xTI_Days, xTI_FirstHdKey, xTI_FirstHrKey, --@TrKey объявлена в коде выше
                        xTI_PNCode, xTI_RCKey, xTI_ACMain, xTI_ACNRealPlaces,
                        xTI_ACNMenExBed, xTI_ACAgeFrom, xTI_HDStars, xTI_HDName, 
                        xTI_HDCNKey, xTI_HDCTKey, xTI_HDRSKey, xti_u,
                        xti_CityArr, @sTLWebHTTP, xTI_HDHTTP, xTI_ACName,
                        xTI_RCName, xTI_RMName, xTI_RSName, xTI_RMKey, 
                        xTI_FirstPnKey, @sTLName, xTI_CTName
                        from @TP_Prices, @TP_Lists                           
                        where xTP_TIKey = xTI_Key                                  
                                   and xtp_key between @TPkeyMin and @TPkeyMin + @nRowPart
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
	update tp_tours set to_progress = @nTotalProgress where to_key = @nPriceTourKey
	set DATEFIRST @nDateFirst
	Return 0
END
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

GRANT EXEC ON [dbo].[CalculatePriceList] TO PUBLIC
GO

--/****** Объект:  StoredProcedure [dbo].[mwCheckFlightGroupsQuotes]    Дата сценария: 11/20/2009 11:14:52 ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCheckFlightGroupsQuotes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[mwCheckFlightGroupsQuotes]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[mwCheckFlightGroupsQuotes]
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
	@result varchar(256) output,
	@linked_day int = null
as
begin
	declare @DYNAMIC_SPO_PAGING smallint
	set @DYNAMIC_SPO_PAGING=3

	declare @now datetime, @percentPlaces float
	select @now = currentDate from dbo.mwCurrentDate

	if(@aviaQuotaMask is null)
		set @aviaQuotaMask = 0

	declare @correctionResult varchar(128)
	set @result = ''
	set @correctionResult = ''

	declare @gpos int, @pos int, @gplaces int, @gallplaces int, @tmpPlaces int, @tmpPlacesAll int, @gStep smallint, @gCorrection int
	set @gpos = 1
	
	declare @gseparatorPos int, @separatorPos int,
		@groupKeys varchar(256), @key varchar(256), @nkey int,
		@glen int, @len int

	if (@aviaQuotaMask > 0)
	begin
		declare @quotaMask smallint -- признаки статусов квот, устанавливаются, если хоть в одной группе встретился соответствующий статус
		set @quotaMask = 0
	end

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
			select @tmpPlaces = qt_places, @tmpPlacesAll = qt_allPlaces
			from dbo.mwCheckQuotesEx(1, @chkey, @nkey, 0, @agentKey, @partnerKey, @tourdate,
				@day, 1, @requestOnRelease, @noPlacesResult, @checkAgentQuota,
				@checkCommonQuota, @checkNoLongQuota, @findFlight, 0, 0, @pkkey,
				@tourDays, @expiredReleaseResult)
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

		if (@aviaQuotaMask > 0)
		begin
			if(@gplaces > 0)
				set @quotaMask = @quotaMask | 1
			else if(@gplaces = 0)
				set @quotaMask = @quotaMask | 2
			else if(@gplaces = -1)
				set @quotaMask = @quotaMask | 4
		end

		set @result = @result + cast(@gplaces as varchar) + ':' + cast(@gallplaces as varchar)
		if(@pagingType = @DYNAMIC_SPO_PAGING)
			set @correctionResult = @correctionResult + cast(@gCorrection as varchar) + ':' + cast(@gStep as varchar)
	end

	if (@aviaQuotaMask > 0)
	begin
		if((@aviaQuotaMask & @quotaMask) = 0)
			set @result = ''
	end

	if(@pagingType = @DYNAMIC_SPO_PAGING)
		set @result = @result + '#' + @correctionResult
end
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

GRANT EXEC ON [dbo].[mwCheckFlightGroupsQuotes] TO PUBLIC
GO
 

--Изменение версии

update [dbo].[setting] set st_version = '9.2.5', st_moduledate = convert(datetime, '2009-11-16', 120),  st_financeversion = '7.2.32', st_financedate = convert(datetime, '2009-10-08', 120)
GO
UPDATE dbo.SystemSettings SET SS_ParmValue='2009-11-16' WHERE SS_ParmName='SYSScriptDate'
GO