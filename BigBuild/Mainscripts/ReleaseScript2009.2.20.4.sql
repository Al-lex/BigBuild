/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 23.12.2013 19:35 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.3'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.4'

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
/* begin (2013.12.14)T_INS_HISTORY.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[INS_HISTORY]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[INS_HISTORY]
GO

CREATE TRIGGER [INS_HISTORY]
ON [dbo].[History] 
AFTER INSERT
AS
--<VERSION>2009.2.20.4</VERSION>
--<DATE>2013-12-14</DATE>
	DECLARE @nInsCount int
	SELECT @nInsCount = COUNT(*) FROM INSERTED
	IF (@nInsCount > 0)
	BEGIN
		DECLARE	@sDGCode VARCHAR(11)
		DECLARE	@sMode VARCHAR(3)
		DECLARE @sNotes VARCHAR(250)
		DECLARE	@nTransferred SMALLINT
	
		IF (@nInsCount > 1)
		BEGIN
			DECLARE cur_Ins_History CURSOR FOR
				SELECT N.HI_DGCod, N.HI_Mod, N.HI_Text
				FROM INSERTED N

			OPEN cur_Ins_History
    			FETCH NEXT FROM cur_Ins_History INTO @sDGCode, @sMode, @sNotes
			WHILE @@FETCH_STATUS = 0
			BEGIN 
				SET	@nTransferred = ( SELECT DG_Transferred FROM Dogovor WHERE DG_Code = @sDGCode )

				If @sMode = 'MTP' and ( @nTransferred = 0 or @nTransferred IS NULL or @nTransferred = 1 or @nTransferred = 4 )
				BEGIN
					--Примечания передаются только для кода MTP
					If  @sMode = 'MTP' and ( @nTransferred = 0 or @nTransferred IS NULL )
						UPDATE 	Dogovor 
						SET 	DG_Notes = @sNotes
						WHERE	DG_Code = @sDGCode
					Else If @sMode = 'MTP'
						UPDATE 	Dogovor 
						SET 	DG_Transferred = 2, DG_Notes = @sNotes
						WHERE	DG_Code = @sDGCode
					Else If @nTransferred > 0
				   		UPDATE 	Dogovor 
						SET 	DG_Transferred = 2
						WHERE	DG_Code = @sDGCode
				END

				FETCH NEXT FROM cur_Ins_History INTO @sDGCode, @sMode, @sNotes
			END
			CLOSE cur_Ins_History
			DEALLOCATE cur_Ins_History
		END
		ELSE BEGIN
			SELECT TOP(1) @sDGCode = HI_DGCod, @sMode = HI_MOD, @sNotes = HI_TEXT FROM INSERTED

			SET	@nTransferred = ( SELECT DG_Transferred FROM Dogovor WHERE DG_Code = @sDGCode )

			If @sMode = 'MTP' and ( @nTransferred = 0 or @nTransferred IS NULL or @nTransferred = 1 or @nTransferred = 4 )
			BEGIN
				--Примечания передаются только для кода MTP
				If  @sMode = 'MTP' and ( @nTransferred = 0 or @nTransferred IS NULL )
					UPDATE 	Dogovor 
					SET 	DG_Notes = @sNotes
					WHERE	DG_Code = @sDGCode
				Else If @sMode = 'MTP'
					UPDATE 	Dogovor 
					SET 	DG_Transferred = 2, DG_Notes = @sNotes
					WHERE	DG_Code = @sDGCode
				Else If @nTransferred > 0
			   		UPDATE 	Dogovor 
					SET 	DG_Transferred = 2
					WHERE	DG_Code = @sDGCode
			END
		END
	END



GO
/*********************************************************************/
/* end (2013.12.14)T_INS_HISTORY.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013-12-09)_Alter_Data_Keys.sql */
/*********************************************************************/
truncate table Key_TPTurDates
go
insert into Key_TPTurDates (ID)
values (isnull((select max(TD_Key) from TP_TurDates), 1))
go

truncate table Key_TPLists
go
insert into Key_TPLists (ID)
values (isnull((select max(TI_Key) from TP_Lists), 1))
go

truncate table Key_TPServices
go
insert into Key_TPServices (ID)
values (isnull((select max(TS_Key) from TP_Services), 1))
go

truncate table Key_TPTours
go
insert into Key_TPTours (ID)
values (isnull((select max(TO_Key) from TP_Tours), 1))
go

truncate table Key_TPServiceLists
go
insert into Key_TPServiceLists (ID)
values (isnull((select max(TL_Key) from TP_ServiceLists), 1))
go

truncate table Key_TPPrices
go
insert into Key_TPPrices (ID)
values (isnull((select max(TP_Key) from TP_Prices), 1))
go

truncate table Key_TURSERVICE
go
insert into Key_TURSERVICE (ID)
values (isnull((select max(TS_Key) from TurService), 1))
go

truncate table Key_TURIST
go
insert into Key_TURIST (ID)
values (isnull((select max(TU_KEY) from tbl_Turist), 1))
go

truncate table Key_TURLIST
go
insert into Key_TURLIST (ID)
values (isnull((select max(TL_KEY) from tbl_TurList), 1))
go

truncate table Key_TurMargin
go
insert into Key_TurMargin (ID)
values (isnull((select max(TM_Key) from TURMARGIN), 1))
go

truncate table Key_PRICELIST
go
insert into Key_PRICELIST (ID)
values (isnull((select max(PL_KEY) from PriceList), 1))
go

truncate table Key_PRICESERVICELINK
go
insert into Key_PRICESERVICELINK (ID)
values (isnull((select max(PS_Key) from PriceServiceLink), 1))
go

truncate table Key_PARTNERS
go
insert into Key_PARTNERS (ID)
values (isnull((select max(PR_KEY) from tbl_Partners), 1))
go

truncate table Key_DogovorList
go
insert into Key_DogovorList (ID)
values (isnull((select max(DL_Key) from tbl_DogovorList), 1))
go

/*Удалим значения из таблицы Keys*/
delete Keys
where KEY_TABLE in 
(
'TP_TurDates',
'TP_Lists',
'TP_Services',
'TP_Tours',
'TP_ServiceLists',
'TP_Prices',
'TurService',
'Turist',
'TURMARGIN',
'PriceList',
'PriceServiceLink',
'Partners',
'DogovorList'
)
go
/*********************************************************************/
/* end (2013-12-09)_Alter_Data_Keys.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.12.05)_ALTER_SetDogovorState_AND_T_DogovorUpdate.sql */
/*********************************************************************/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SetDogovorState]
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
					
		-- 20611:CRM05885G9M9 Вызов перенесен в триггрер T_DogovorUpdate
		-- exec dbo.CreatePPaymentDate @dg_code, @dTour, @dtCurrentDate
	END
END
GO


ALTER TRIGGER [dbo].[T_DogovorUpdate]
ON [dbo].[tbl_Dogovor] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2009.2.17.2</VERSION>
--<DATE>2012-12-10</DATE>
IF @@ROWCOUNT > 0
BEGIN
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
    
    DECLARE @sMod varchar(3)
    DECLARE @nDelCount int
    DECLARE @nInsCount int
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
		N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, N.DG_TurDate, N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
		CONVERT( char(11), N.DG_PPaymentDate, 104) + CONVERT( char(5), N.DG_PPaymentDate, 108), CONVERT( char(10), N.DG_PaymentDate, 104), N.DG_RazmerP, N.DG_Procent, N.DG_Locked, N.DG_SOR_Code, N.DG_IsOutDoc, CONVERT( char(10), N.DG_VisaDate, 104), N.DG_CauseDisc, N.DG_OWNER, 
		N.DG_LEADDEPARTMENT, N.DG_DupUserKey, N.DG_MainMen, N.DG_MainMenEMail, N.DG_MAINMENPHONE, N.DG_CodePartner, N.DG_Creator, N.DG_CTDepartureKey, N.DG_Payed, N.DG_ProTourFlag
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_Dogovor CURSOR LOCAL FOR 
      SELECT O.DG_Key,
		O.DG_Code, O.DG_Price, O.DG_Rate, O.DG_DiscountSum, O.DG_PartnerKey, O.DG_TRKey, O.DG_TurDate, O.DG_CTKEY, O.DG_NMEN, O.DG_NDAY, 
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
		O.DG_Code, O.DG_Price, O.DG_Rate, O.DG_DiscountSum, O.DG_PartnerKey, O.DG_TRKey, O.DG_TurDate, O.DG_CTKEY, O.DG_NMEN, O.DG_NDAY, 
		CONVERT( char(11), O.DG_PPaymentDate, 104) + CONVERT( char(5), O.DG_PPaymentDate, 108), CONVERT( char(10), O.DG_PaymentDate, 104), O.DG_RazmerP, O.DG_Procent, O.DG_Locked, O.DG_SOR_Code, O.DG_IsOutDoc, CONVERT( char(10), O.DG_VisaDate, 104), O.DG_CauseDisc, O.DG_OWNER, 
		O.DG_LEADDEPARTMENT, O.DG_DupUserKey, O.DG_MainMen, O.DG_MainMenEMail, O.DG_MAINMENPHONE, O.DG_CodePartner, O.DG_Creator, O.DG_CTDepartureKey, O.DG_Payed, O.DG_ProTourFlag,
		N.DG_Code, N.DG_Price, N.DG_Rate, N.DG_DiscountSum, N.DG_PartnerKey, N.DG_TRKey, N.DG_TurDate, N.DG_CTKEY, N.DG_NMEN, N.DG_NDAY, 
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
					if (@bCurrencyChangedPrevFixDate > 0)
						set @changedDate = ISNULL(dbo.GetFirstDogovorStatusDate (@DG_Key, @NDG_SOR_Code), GetDate())
					
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
/* end (2013.12.05)_ALTER_SetDogovorState_AND_T_DogovorUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.12.11)_ALTER_CreatePPaymentdate.sql */
/*********************************************************************/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CreatePPaymentdate]
(
	@sDogovor varchar (10) = null,
	@dtTurDate datetime = null,
	@dtSysDate datetime = null
)
as

declare @sValue varchar(254)

Select @sValue = SS_ParmValue from dbo.SystemSettings where SS_ParmName = 'SYSUseTimeLimit'
if (@sValue != '1')
begin
	-- хранимка выполняется только если настройка SYSUseTimeLimit = 1
	return;
end

if exists (select top 1 1 from Dogovor join Order_Status on DG_SOR_CODE = OS_CODE where DG_CODE = @sDogovor and (DG_TURDATE = '18991230' or OS_GLOBAL = 2 or OS_GLOBAL != 7))
begin
	-- если путевка анулированна или глобальный статус не Ок то выходим
	return;
end

declare @dtPPaymentDate datetime
declare @nHour smallint

if (@dtTurDate - @dtSysDate) < 3 
begin
	SELECT @dtPPaymentDate = DATEADD(Hour,20 -DATEPART(hour,GETDATE()), DATEADD(minute, -DATEPART(minute,GETDATE()), DATEADD(second, -DATEPART(second,GETDATE()), GETDATE())))
	if @dtSysDate < @dtPPaymentDate
	begin
		SELECT @dtPPaymentDate = DATEADD(Hour,15 -DATEPART(hour,GETDATE()), DATEADD(minute, -DATEPART(minute,GETDATE()), DATEADD(second, -DATEPART(second,GETDATE()), DATEADD(Day,1,GETDATE()))))
	end
end
else 
begin
	SELECT @nHour = DATEPART(hour,GETDATE())
	if @nHour < 15
	begin
		SELECT @dtPPaymentDate = DATEADD(Hour,20 -DATEPART(hour,GETDATE()), DATEADD(minute, -DATEPART(minute,GETDATE()), DATEADD(second, -DATEPART(second,GETDATE()), GETDATE())))
	end
	else
	begin
		SELECT @dtPPaymentDate = DATEADD(Hour,15 -DATEPART(hour,GETDATE()), DATEADD(minute, -DATEPART(minute,GETDATE()), DATEADD(second, -DATEPART(second,GETDATE()), DATEADD(Day,1,GETDATE()))))
	end
end
-- если полученная дата меньше текушей, то установим текущую дату
if (@dtPPaymentDate < GETDATE())
begin
	set @dtPPaymentDate = GETDATE()
end

Update Dogovor set DG_PPaymentDate = @dtPPaymentDate where DG_Code = @sDogovor

return 0
GO

/*********************************************************************/
/* end (2013.12.11)_ALTER_CreatePPaymentdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2013.12.19)_InsertNullable_mwReplDirections.sql */
/*********************************************************************/
if (not exists(select 1 from mwReplDirections where RD_CNKey = 0 and RD_CTKeyFrom = 0))
begin
	insert into mwReplDirections(RD_CNKey, RD_CTKeyFrom, RD_IsUsed)
	values (0, 0, 0)
end
GO
/*********************************************************************/
/* end (2013.12.19)_InsertNullable_mwReplDirections.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwGetTiHotelStars.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwGetTiHotelStars]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwGetTiHotelStars]
GO

CREATE function [dbo].[mwGetTiHotelStars] (@tikey int) returns varchar(100) 	
as
begin
declare @res varchar(100)
set @res = ''
select 
	@res = @res + isnull(hd_stars,'') + ','
from 
	tp_services with(nolock) inner join tp_servicelists with(nolock) on tl_tskey = ts_key 
		inner join hoteldictionary with(nolock) on (ts_svkey = 3 and ts_code = hd_key) 
where
	tl_tikey = @tikey
order by
	ts_day

if(len(@res) > 0)
	set @res = substring(@res, 1, len(@res) - 1)

return @res
end
GO

GRANT EXEC ON [dbo].[mwGetTiHotelStars] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwGetTiHotelStars.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwGetTiNights.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwGetTiNights]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwGetTiNights]
GO

CREATE function [dbo].[mwGetTiNights] (@tikey int) returns int 	
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
	from tp_servicelists with(nolock)
		inner join tp_services with(nolock) on tl_tskey = ts_key 
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

GRANT EXEC ON [dbo].[mwGetTiNights] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwGetTiNights.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwGetTourCharterAttribute.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwGetTourCharterAttribute]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwGetTourCharterAttribute]
GO

CREATE function [dbo].[mwGetTourCharterAttribute](@tikey int, @isDirectFlight smallint)
returns int
as
--<VERSION>9.2.13.1</VERSION>
--<DATE>04-07-2012</DATE>
begin
	declare @result int
	set		@result = null

	select TOP 1 
		@result = ts_attribute
	from 
		tp_services with(nolock)
			inner join dbo.tp_servicelists with(nolock) on tl_tskey = ts_key
			inner join dbo.tp_lists with(nolock) on ti_key = tl_tikey
	where
		ts_svkey = 1 and
		tl_tikey = @tikey and
		(
			(@isDirectFlight > 0 and ts_day <= ti_days / 2)
			or
			(@isDirectFlight = 0 and ts_day > ti_days / 2)
		)
	order by
		ts_day

	return @result
end
GO

GRANT EXEC ON [dbo].[mwGetTourCharterAttribute] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwGetTourCharterAttribute.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwGetTourCharters.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwGetTourCharters]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwGetTourCharters]
GO

CREATE function [dbo].[mwGetTourCharters](@tikey int, @isDirectFlight smallint)
returns varchar(256)
as
begin
	declare @result varchar(256)
	set		@result = ''

	select 
		@result = @result + isnull(ltrim(str(ts_code)),'') + ':' + isnull(ltrim(str(ts_day)),'') + ':' + isnull(ltrim(str(TS_OpPartnerKey)),'') + ':' + isnull(ltrim(str(TS_OpPacketKey)),'') + ','
	from 
		tp_services with(nolock)
			inner join tp_servicelists with(nolock) on tl_tskey = ts_key
			inner join tp_lists with(nolock) on ti_key = tl_tikey
	where
		ts_svkey = 1 and
		tl_tikey = @tikey and
		(
			(@isDirectFlight > 0 and ts_day <= ti_days / 2)
			or
			(@isDirectFlight = 0 and ts_day > ti_days / 2)
		)
	order by
		ts_day

	-- Remove comma at the end of string
	if(len(@result) > 0)
		set @result = substring(@result, 1, len(@result) - 1)

	return @result
end
GO

GRANT EXEC ON [dbo].[mwGetTourCharters] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwGetTourCharters.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwGetTourHotels.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwGetTourHotels]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[mwGetTourHotels]
GO

CREATE function [dbo].[mwGetTourHotels](@tiKey int)
returns varchar(256)
as
begin
	declare @result varchar(256)
	set		@result = ''

	select 
		@result = @result + 
			CASE WHEN 
			(
				len(@result) + len(
					isnull(ltrim(str(ts_code)),'') + ':' 
					+ isnull(ltrim(str(hr_rmkey)),'') + ':' 
					+ isnull(ltrim(str(hr_rckey)),'') + ':' 
					+ isnull(ltrim(str(ts_day)),'') + ':' 
					+ isnull(ltrim(str(ts_days)),'') + ':' 
					+ isnull(ltrim(str(TS_OpPartnerKey)),'') + ':' 
					+ isnull(ltrim(str(TS_subcode1)),'') + ':' 
					+ isnull(ltrim(str(TS_subcode2)),'') + ','
				) <= 256
			)
			THEN
			(
				  isnull(ltrim(str(ts_code)),'') + ':' 
				+ isnull(ltrim(str(hr_rmkey)),'') + ':' 
				+ isnull(ltrim(str(hr_rckey)),'') + ':' 
				+ isnull(ltrim(str(ts_day)),'') + ':' 
				+ isnull(ltrim(str(ts_days)),'') + ':' 
				+ isnull(ltrim(str(TS_OpPartnerKey)),'') + ':' 
				+ isnull(ltrim(str(TS_subcode1)),'') + ':' 
				+ isnull(ltrim(str(TS_subcode2)),'') + ','
			)
			ELSE ''
			END
	from 
		tp_services with(nolock)
			inner join tp_servicelists with(nolock) on tl_tskey = ts_key
			inner join tp_lists with(nolock) on ti_key = tl_tikey
			inner join HotelRooms with(nolock) on  hr_key = ts_subcode1
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
GO

GRANT EXEC ON [dbo].[mwGetTourHotels] TO PUBLIC
GO

/*********************************************************************/
/* end fn_mwGetTourHotels.sql */
/*********************************************************************/

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
--<DATE>2013-12-20</DATE>
---<VERSION>9.2.20.4</VERSION>

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

Set @nTotalProgress = 1
update tp_tours with(rowlock) set to_progress = @nTotalProgress, TO_UPDATETIME = GetDate() where to_key = @nPriceTourKey

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

declare @calculatingPriceListsExists smallint -- 0 - CalculatingPriceLists нет, 1 - CalculatingPriceLists есть в базе

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

--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
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
		------ проверяем, а есть ли у данного парнера по рейсу, цены на другие рейсы в этом же пакете ----
		IF exists(SELECT TF_ID FROM TP_Flights with(nolock) WHERE TF_TOKey = @nPriceTourKey and TF_CodeNew is Null)
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
			-- подбираем подходящие нам перелеты
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
			
			print ''Закончили подбор перелетов''
		end
	END
	', N'@nPriceTourKey int, @nCalculatingKey int, @nNoFlight smallint', @nPriceTourKey, @nCalculatingKey, @nNoFlight
	
	-----если перелет так и не найден, то в поле TF_CodeNew будет NULL

	--------------------------------------- закончили поиск подходящего перелета --------------------------------------
	--if ISNULL((select to_update from [dbo].tp_tours with(nolock) where to_key = @nPriceTourKey),0) <> 1
	
	declare @calcPricesCount int
	
	exec sp_executesql			
	N'	
	
	if (1 = 1)
	BEGIN

		update [dbo].tp_tours with(rowlock) set to_update = 1 where to_key = @nPriceTourKey
		Set @nTotalProgress = 4
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

		SELECT @round = ST_RoundService FROM Setting
		--MEG00036108 увеличил значение
		set @nProgressSkipLimit = 10000

		set @nProgressSkipCounter = 0
		--Set @nTotalProgress = @nTotalProgress + 1
		--update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
		
		--считаем сколько записей надо посчитать
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

grant execute on [dbo].[CalculatePriceList] to public
GO
/*********************************************************************/
/* end sp_CalculatePriceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_FillMasterWebSearchFields.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FillMasterWebSearchFields]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[FillMasterWebSearchFields]
GO

CREATE procedure [dbo].[FillMasterWebSearchFields](@tokey int, @calcKey int = null, @forceEnable smallint = null, @overwritePrices bit = null)
-- if @forceEnable > 0 (by default) then make call mwEnablePriceTour @calcKey, 1 at the end of the procedure
as
begin
	--<VERSION>2009.2.20.4</VERSION>
	--<DATE>2013-12-12</DATE>
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

	DECLARE @departFromKey INT
	SELECT top 1 @departFromKey = TL_CTDepartureKey FROM tbl_TurList 
	INNER JOIN tp_Tours 
	ON TL_KEY = TO_TRKey
	WHERE TO_Key = @tokey
	
	IF EXISTS(SELECT 1 FROM mwSpoDataTable WHERE sd_tourkey = @tokey AND sd_ctkeyfrom <> @departFromKey)
	BEGIN
		SET @calcKey = null
		EXEC mwReplDisablePriceTour @tokey
	END

	update dbo.TP_Tours set TO_Progress = 0 where TO_Key = @tokey

	if dbo.mwReplIsSubscriber() > 0
	begin
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

	declare @firsthdday int
	select @firsthdday = (select min(ts_day) 
				from tp_services with (nolock)
 				where ts_svkey = 3 and ts_tokey = @tokey)

	declare @count_ts_code int

	select @count_ts_code = count(distinct ts_code)
	from tp_services with(nolock)
	where ts_svkey = 1 and ts_tokey = @tokey 
	and (ts_day <= @firsthdday or (ts_day = 1 and @firsthdday = 0)) 
	and ts_subcode2 = @ctdeparturekey

	if (@count_ts_code > 1)
	begin
		if(@calcKey is not null)
		begin
			insert into #tp_lists
			select
				ti_key,
				ti_tokey,
				ti_firsthdkey,
				ti_firstpnkey,
				ti_firsthrkey,
				@firsthdday as ti_firsthotelday,
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
				(
					select top 1 ts_code
					from tp_servicelists with(nolock) 
					inner join tp_services with(nolock) on tl_tskey = ts_key and ts_svkey = 1
					where tl_tikey = ti_key and ts_tokey = @tokey and tl_tokey = @tokey 
					and (ts_day <= @firsthdday or (ts_day = 1 and @firsthdday = 0)) and ts_subcode2 = @ctdeparturekey
				) as ti_chkey,
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
			where TI_Key in (select TP_TIKey from TP_Prices with(nolock) where TP_TOKey = TI_TOKey and TP_CalculatingKey = @calcKey) 
			and TI_TOKey = @tokey
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
				@firsthdday as ti_firsthotelday,
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
				(
					select top 1 ts_code
					from tp_servicelists with(nolock) 
					inner join tp_services with(nolock) on tl_tskey = ts_key and ts_svkey = 1
					where tl_tikey = ti_key and ts_tokey = @tokey and tl_tokey = @tokey 
					and (ts_day <= @firsthdday or (ts_day = 1 and @firsthdday = 0)) and ts_subcode2 = @ctdeparturekey
				) as ti_chkey,	
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
	end
	else
	begin

		declare @ts_code int
		declare @ti_key int
		select top 1 @ti_key = ti_key
		from tp_lists with(nolock)
		where TI_TOKey = @tokey	

		select top 1 @ts_code = ts_code
		from tp_services with(nolock)
		where ts_svkey = 1 and ts_tokey = @tokey
		and (ts_day <= @firsthdday or (ts_day = 1 and @firsthdday = 0)) 
		and ts_subcode2 = @ctdeparturekey

		if(@calcKey is not null)
		begin
			insert into #tp_lists
			select
				ti_key,
				ti_tokey,
				ti_firsthdkey,
				ti_firstpnkey,
				ti_firsthrkey,
				@firsthdday as ti_firsthotelday,
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
				@ts_code as ti_chkey,			
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
			where TI_Key in (select TP_TIKey from TP_Prices with(nolock) where TP_TOKey = TI_TOKey and TP_CalculatingKey = @calcKey) 
			and TI_TOKey = @tokey
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
				@firsthdday as ti_firsthotelday,
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
				@ts_code as ti_chkey,			
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
	end

	declare @mwAccomodationPlaces nvarchar(254)
	declare @mwRoomsExtraPlaces nvarchar(254)
	declare @mwSearchType int
	declare @sql nvarchar(4000)
	declare @countryKey int
	declare @cityFromKey int

	update dbo.TP_Tours set TO_Progress = 7 where TO_Key = @tokey

	update TP_Tours set TO_MinPrice = (
			select min(TP_Gross) 
			from TP_Prices with(nolock) 
				left join TP_Lists with(nolock) on ti_key = tp_tikey
				left join HotelRooms with(nolock) on hr_key = ti_firsthrkey				
			where TP_TOKey = TO_Key 
					and hr_main > 0 
					and (isnull(HR_AGEFROM, 0) <= 0 or isnull(HR_AGEFROM, 0) > 16)
		)
		where TO_Key = @tokey

	update dbo.TP_Tours set TO_Progress = 13 where TO_Key = @tokey

	update #tp_lists
	set
		ti_lasthotelday = (select max(ts_day)
				from tp_servicelists  with (nolock)
					inner join tp_services with (nolock) on tl_tskey = ts_key
				where tl_tikey = ti_key and ts_svkey = 3 and TS_TOKey = @tokey and TL_TOKey = @tokey)

	update dbo.TP_Tours set TO_Progress = 20 where TO_Key = @tokey	

	update dbo.TP_Tours set TO_Progress = 30 where TO_Key = @tokey

	-- MEG00024548 Paul G 11.01.2009
	-- изменил логику подсчёта кол-ва ночей в туре
	-- раньше было сумма ночей проживания по всем отелям в туре
	-- теперь если проживания пересекаются, лишние ночи не суммируются
	update #tp_lists 
	set
		ti_nights = dbo.mwGetTiNights(ti_key)

	--koshelev
	--02.04.2012 MEG00040744
    declare @result nvarchar(256)
    set @result = N''
    select @result = @result + rtrim(ltrim(str(tbl.ti_nights))) + N', ' from (select distinct ti_nights from (select ti_nights from #tp_lists union select ti_nights from tp_lists with(nolock) where ti_tokey = @tokey ) as tbl2) tbl order by tbl.ti_nights
    declare @len int
    set @len = len(@result)
    if(@len > 0)
          set @result = substring(@result, 1, @len - 1)

    update TP_Tours set TO_HotelNights = @result where TO_Key = @tokey

	update dbo.TP_Tours set TO_Progress = 40 where TO_Key = @tokey

	update #tp_lists 
		set ti_hotelkeys = dbo.mwGetTiHotelKeys(ti_key),
			ti_hotelroomkeys = dbo.mwGetTiHotelRoomKeys(ti_key),
			ti_hoteldays = dbo.mwGetTiHotelNights(ti_key),
			ti_hotelstars = dbo.mwGetTiHotelStars(ti_key),
			ti_pansionkeys = dbo.mwGetTiPansionKeys(ti_key)

	update #tp_lists
	set
		ti_hdpartnerkey = ts_oppartnerkey,
		ti_firsthotelpartnerkey = ts_oppartnerkey,
		ti_hdday = ts_day,
		ti_hdnights = ts_days
	from tp_servicelists with (nolock)
		inner join tp_services with (nolock) on (tl_tskey = ts_key and ts_svkey = 3)
	where tl_tikey = ti_key and ts_code = ti_firsthdkey and TS_TOKey = @tokey and TL_TOKey = @tokey

	update dbo.TP_Tours set TO_Progress = 50 where TO_Key = @tokey

	-- город вылета + прямой перелет
	update #tp_lists
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

	update #tp_lists
	set 
		ti_ctkeyfrom = @ctdeparturekey

	-- Проверка наличия перелетов в город вылета
	declare @existBackCharter smallint
	select	@existBackCharter = count(ts_key)
	from	tp_services with(nolock)
	where	ts_tokey = @tokey
		and	ts_svkey = 1
		and ts_ctkey = @ctdeparturekey

	-- город прилета + обратный перелет
	update #tp_lists
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
	update #tp_lists 
	set 
		ti_apkeyfrom = (select top 1 ap_key from airport with(nolock), charter with(nolock) 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chkey)

	-- _ключ_ аэропорта прилета
	update #tp_lists
	set 
		ti_apkeyto = (select top 1 ap_key from airport with(nolock), charter with(nolock) 
				where ch_portcodefrom = ap_code 
					and ch_key = ti_chbackkey)

	-- ключ города и ключ курорта + звезды
	update #tp_lists
	set
		ti_firstctkey = hd_ctkey,
		ti_firstrskey = hd_rskey,
		ti_firsthdstars = hd_stars
	from hoteldictionary with(nolock)
	where 
		ti_firsthdkey = hd_key

	update dbo.TP_Tours set TO_Progress = 60 where TO_Key = @tokey

	if dbo.mwReplIsPublisher() > 0
	begin
		declare @trkey int
		select @trkey = to_trkey from dbo.tp_tours with(nolock) where to_key = @tokey
		
		insert into dbo.mwReplTours (rt_trkey, rt_tokey, rt_date, rt_CalcKey)
		values (@trkey, @tokey, getdate(), @calcKey)
		
		update CalculatingPriceLists set CP_Status = 0 where CP_PriceTourKey = @tokey
		update dbo.TP_Tours 
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
		delete from dbo.mwSpoDataTable where sd_tourkey = @tokey
		delete from dbo.mwPriceHotels where sd_tourkey = @tokey
		delete from dbo.mwPriceDurations where sd_tourkey = @tokey
	end
	else
	begin
		--saifullina 16.01.2013 если мы изменили название и дозаписываем тур, то должны дозаписать с новым названием
		update dbo.mwSpoDataTable set sd_tourname=(select to_name from TP_Tours with(nolock) where TO_Key=@tokey) where sd_tourkey = @tokey
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
		from #tp_lists with(nolock) inner join tp_tours with(nolock) on ti_tokey = to_key

		-- Даты в поисковой таблице ставим как в таблице туров - чтобы не было двоений MEG00021274
		update mwspodatatable 
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
					set @sql = 'delete top (' + ltrim(STR(@deleteCount)) +  ') from mwPriceDataTable where pt_pricekey in (select tp_key from tp_prices with(nolock) where TP_CalculatingKey = ' + cast(@calcKey as nvarchar(20)) + '); set @counterOut = @@ROWCOUNT'
				else
					set @sql = 'delete top(' + ltrim(STR(@deleteCount)) + ') from mwPriceDataTable where pt_tourkey = ' + cast(@tokey as nvarchar(20)) + ';set @counterOut = @@ROWCOUNT'
				EXECUTE sp_executesql @sql, @params, @counterOut = @counter output
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
						set @sql = 'delete top (' + ltrim(rtrim(str(@deleteCount)))  + ') from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' where pt_pricekey in (select tp_key from tp_prices with(nolock) where TP_CalculatingKey = ' + cast(@calcKey as nvarchar(20)) + '); set @counterOut = @@ROWCOUNT'
					else
						set @sql = 'delete top (' + ltrim(rtrim(str(@deleteCount))) + ') from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' where pt_tourkey = ' + cast(@tokey as nvarchar(20)) + '; set @counterOut = @@ROWCOUNT'
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
		insert into mwSpoDataTable (
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
			from mwSpoDataTable mwsdt with(nolock)
			where mwsdt.sd_tourkey = mwPriceHotels.sd_tourkey and mwsdt.sd_hdkey = mwPriceHotels.sd_mainhdkey
				and mwsdt.sd_tourkey = @tokey
				and mwPriceHotels.sd_tourkey = @tokey

		-- Указываем на необходимость обновления в таблице минимальных цен отеля
		update mwHotelDetails 
			set htd_needupdate = 1
			where htd_hdkey in (select thd_hdkey from #tmpHotelData)
			
	end
	
	if dbo.mwReplIsSubscriber() > 0
	begin
		while 1=1
		begin
			delete top (10000) from TP_Prices where tp_tokey = @tokey
			if @@rowcount = 0
				break
		end
	
		while 1=1
		begin
			delete top (10000) from TP_ServiceLists where tl_tokey = @tokey
			if @@rowcount = 0
				break
		end
		
		while 1=1
		begin
			delete top (10000) from TP_Services where ts_tokey = @tokey
			if @@rowcount = 0
				break
		end
		
		while 1=1
		begin
			delete top (10000) from TP_Lists where ti_tokey = @tokey
			if @@rowcount = 0
				break
		end
		-- don't delete from TP_Tours	
	end
	else
	begin
		update tp_lists
		set
			ti_firsthdkey = ti.ti_firsthdkey,
			ti_lasthotelday = ti.ti_lasthotelday,			
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
			and
			(
				isnull(tp_lists.ti_firsthdkey, 0) <> isnull(ti.ti_firsthdkey , 0)
				or isnull(tp_lists.ti_lasthotelday, 0) <> isnull(ti.ti_lasthotelday, 0)
				or isnull(tp_lists.ti_nights, 0) <> isnull(ti.ti_nights, 0)
				or isnull(tp_lists.ti_hotelkeys, 0) <> isnull(ti.ti_hotelkeys, 0)
				or isnull(tp_lists.ti_hotelroomkeys, 0) <> isnull(ti.ti_hotelroomkeys, 0)
				or isnull(tp_lists.ti_hoteldays, 0) <> isnull(ti.ti_hoteldays, 0)
				or isnull(tp_lists.ti_hotelstars, 0) <> isnull(ti.ti_hotelstars, 0)
				or isnull(tp_lists.ti_pansionkeys, 0) <> isnull(ti.ti_pansionkeys, 0)
				or isnull(tp_lists.ti_hdpartnerkey, 0) <> isnull(ti.ti_hdpartnerkey, 0)
				or isnull(tp_lists.ti_firsthotelpartnerkey, 0) <> isnull(ti.ti_firsthotelpartnerkey, 0)
				or isnull(tp_lists.ti_hdday, 0) <> isnull(ti.ti_hdday, 0)
				or isnull(tp_lists.ti_hdnights, 0) <> isnull(ti.ti_hdnights, 0)
				or isnull(tp_lists.ti_chkey, 0) <> isnull(ti.ti_chkey, 0)
				or isnull(tp_lists.ti_chday, 0) <> isnull(ti.ti_chday, 0)
				or isnull(tp_lists.ti_chpkkey, 0) <> isnull(ti.ti_chpkkey, 0)
				or isnull(tp_lists.ti_chprkey, 0) <> isnull(ti.ti_chprkey, 0)
				or isnull(tp_lists.ti_ctkeyfrom, 0) <> isnull(ti.ti_ctkeyfrom, 0)
				or isnull(tp_lists.ti_chbackkey, 0) <> isnull(ti.ti_chbackkey, 0)
				or isnull(tp_lists.ti_chbackday, 0) <> isnull(ti.ti_chbackday, 0)
				or isnull(tp_lists.ti_chbackpkkey, 0) <> isnull(ti.ti_chbackpkkey, 0)
				or isnull(tp_lists.ti_chbackprkey, 0) <> isnull(ti.ti_chbackprkey, 0)
				or isnull(tp_lists.ti_ctkeyto, 0) <> isnull(ti.ti_ctkeyto, 0)
				or isnull(tp_lists.ti_apkeyfrom, 0) <> isnull(ti.ti_apkeyfrom, 0)
				or isnull(tp_lists.ti_apkeyto, 0) <> isnull(ti.ti_apkeyto, 0)
				or isnull(tp_lists.ti_firstctkey, 0) <> isnull(ti.ti_firstctkey, 0)
				or isnull(tp_lists.ti_firstrskey, 0) <> isnull(ti.ti_firstrskey, 0)
				or isnull(tp_lists.ti_firsthdstars, 0) <> isnull(ti.ti_firsthdstars, 0)
			)
	end

	if(@forceEnable > 0 and @calcKey is null)
	begin
		exec mwEnablePriceTourNewSinglePrice @tokey, '#tempPriceTable'

		update tp_tours
		set to_isenabled = 1
		where to_key = @tokey
	end

	drop table #tempPriceTable

	update dbo.TP_Tours
	set TO_Update = 0,
		TO_Progress = 100,
		TO_DateCreated = GetDate()
	where
		TO_Key = @tokey

	if dbo.mwReplIsSubscriber() <= 0
	begin
		update dbo.TP_Tours 
		set TO_UpdateTime = GetDate()
		where
			TO_Key = @tokey
	end

	EXECUTE mwFillPriceListDetails @tokey

end
GO

GRANT EXECUTE on [dbo].[FillMasterWebSearchFields] to public
GO
/*********************************************************************/
/* end sp_FillMasterWebSearchFields.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetCityDepartureKey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetCityDepartureKey]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetCityDepartureKey]
GO

CREATE procedure [dbo].[GetCityDepartureKey] 
	@tokey int,
	@ctdeparturekey	int output
as
	create table #charters
	(
		TS_CTKEY int, 
		TS_SUBCODE2 int, 
		TS_day int
	)

	insert into #charters
	select distinct TS_CTKEY, TS_SUBCODE2, TS_day
		from tp_services with (nolock)
			join airseason with(nolock) on as_chkey = ts_code
		where	ts_tokey = @tokey
			and	ts_svkey = 1
			and ts_day = (select min(TS_day) from tp_services with(nolock) where ts_tokey = @tokey and	ts_svkey = 1)

	declare @count int
		set @count = @@rowCount

	if @count = 1
	begin
		select @ctdeparturekey = TS_SUBCODE2
		from #charters
	end
	else if @count = 2
	begin
		select @ctdeparturekey = c1.TS_SUBCODE2
		from #charters c1
			join #charters c2 on c1.TS_CTKEY = c2.TS_SUBCODE2
	end
	else if @count = 3
	begin
		select @ctdeparturekey = c1.TS_SUBCODE2
		from #charters c1
			join #charters c2 on c1.TS_CTKEY = c2.TS_SUBCODE2
			join #charters c3 on c2.TS_CTKEY = c3.TS_SUBCODE2
	end

	drop table #charters
GO

GRANT EXECUTE ON [dbo].[GetCityDepartureKey] TO PUBLIC
GO
/*********************************************************************/
/* end sp_GetCityDepartureKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetNKey.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetNKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[GetNKey]
GO
CREATE PROCEDURE [dbo].[GetNKey]
  (
	  @sTable varchar(50) = null,
	  @nNewKey int = null output
  )
AS
	--<VERSION>9.2.20.4</VERSION>
	--<DATE>2013-12-10</DATE>
	--<SUMMARY>Возвращает ключ для таблицы</SUMMARY>
	exec GetNKeys @sTable, 1, @nNewKey out	
GO
GRANT EXECUTE ON [dbo].[GetNKey] TO Public
GO
/*********************************************************************/
/* end sp_GetNKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetNKeys.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetNKeys]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetNKeys]
GO

create PROCEDURE [dbo].[GetNKeys]
(
	@sTable varchar(50) = null,
	@nKeyCount int,
	@nNewKey int = null output
)
AS
--<VERSION>9.2.20.4</VERSION>
--<DATE>2013-12-10</DATE>
--<SUMMARY>Возвращает опред. количество ключей для таблицы</SUMMARY>
declare @nID int
declare @keyTable varchar(100)
declare @query nvarchar (600)
declare @transactionIsolationLevel int

SELECT @transactionIsolationLevel = transaction_isolation_level 
FROM sys.dm_exec_sessions 
where session_id = @@spid

SET TRANSACTION ISOLATION LEVEL serializable;

set nocount on

if @nKeyCount is null
	set @nKeyCount = 0
	
if @sTable like 'TP_TOURDATES'
	set @sTable = 'TP_TURDATES'

set nocount on

select @keyTable = 
	case 
		when @sTable like 'TP_TURDATES' then 'Key_TPTurDates'
		when @sTable like 'TP_Lists' then 'Key_TPLists'
		when @sTable like 'TP_Services' then 'Key_TPServices'
		when @sTable like 'TP_Tours' then 'Key_TPTours'
		when @sTable like 'TP_ServiceLists' then 'Key_TPServiceLists'
		when @sTable like 'TP_Prices' then 'Key_TPPrices'
		when @sTable like 'TURSERVICE' then 'Key_TURSERVICE'
		when @sTable like 'TURIST' then 'Key_TURIST'
		when @sTable like 'TURLIST' then 'Key_TURLIST'
		when @sTable like 'TurMargin' then 'Key_TurMargin'
		when @sTable like 'PRICELIST' then 'Key_PRICELIST'
		when @sTable like 'PRICESERVICELINK' then 'Key_PRICESERVICELINK'
		when @sTable like 'PARTNERS' then 'Key_PARTNERS'
		when @sTable like 'DOGOVORLIST' then 'Key_DogovorList'
	end

if @keyTable is not null
begin
	set @query = N'
	declare @maxKeyFromTable int
	set @maxKeyFromTable = isnull((Select id from @keyTable (updlock)), 1)
	Set @nNewKeyOut = @maxKeyFromTable + @nKeyCount

	update @keyTable set Id = @nNewKeyOut
	'
	set @query = REPLACE(@query, '@keyTable', @keyTable)
	begin tran
		EXECUTE sp_executesql @query, N'@nNewKeyOut int output, @nKeyCount int', @nNewKeyOut = @nNewKey  output,  @nKeyCount = @nKeyCount
	commit tran
end
else
begin	
	begin tran
		if exists (select top 1 1 from Keys where Key_Table = @sTable)
		begin
			Select @nNewKey = id + @nKeyCount from Keys WITH (UPDLOCK) where Key_Table = @sTable
			update Keys set Id = @nNewKey where Key_Table = @sTable
		end
		else
		begin
			insert into Keys (Key_Table, Id) values (@sTable, @nKeyCount)
			set @nNewKey=@nKeyCount
		end
	commit tran
end

if (@transactionIsolationLevel = 1) SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
if (@transactionIsolationLevel = 2) SET TRANSACTION ISOLATION LEVEL READ COMMITTED
if (@transactionIsolationLevel = 3) SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
if (@transactionIsolationLevel = 4) SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
if (@transactionIsolationLevel = 5) SET TRANSACTION ISOLATION LEVEL SNAPSHOT

return 0
GO
grant exec on [dbo].[GetNKeys] to public
GO
/*********************************************************************/
/* end sp_GetNKeys.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwRemoveDeleted.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwRemoveDeleted]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwRemoveDeleted]
GO

create proc [dbo].[mwRemoveDeleted] 
	@remove tinyint = 0
as
begin
	--<VERSION>9.2.20.3</VERSION>
	--<DATE>2013-12-11</DATE>

	set nocount on
	if (dbo.mwReplIsPublisher() = 1)
	begin
		delete from dbo.mwDeleted
		return
	end
	
	declare @name varchar(50)
	declare @sql varchar(8000)
		
	if object_id('tempdb..#tmpDeleted') is not null
	begin
		drop table #tmpDeleted
	end
	create table #tmpDeleted(
		del_key int
	)
	declare @pubdb nvarchar(50)
	set @pubdb = dbo.mwReplPublisherDB()
	
	declare delCur cursor fast_forward read_only 
			for select [name] from sysobjects with(nolock) where name like 'mwPriceDataTable[_]%' and xtype = 'u'			
	
	while exists(select top (1) 1 from dbo.mwDeleted with (nolock))
	begin

		insert into #tmpDeleted
		select top (100000) del_key 
		from dbo.mwDeleted with(nolock)				

		open delCur
		fetch next from delCur into @name	
		while(@@fetch_status = 0)
		begin
			while 1=1
			begin
				set @sql = 'delete top (10000) from dbo.' + ltrim(rtrim(@name)) + ' where pt_pricekey in (select del_key from #tmpDeleted)'
				exec(@sql)
				if @@rowcount = 0
					break
			end

			fetch next from delCur into @name
		end
		close delCur

		delete from dbo.mwDeleted where del_key in (select del_key from #tmpDeleted)

		delete from #tmpDeleted	
	end

	deallocate delCur

	truncate table #tmpDeleted
	set @sql = 'insert into #tmpDeleted (del_key) select sd_key from dbo.mwSpoDataTable with(nolock) where not exists(select top (1) 1 from mt.' + @pubdb + '.dbo.tp_prices with(nolock) where tp_tokey = sd_tourkey)'
	exec (@sql)
	delete from dbo.mwSpoDataTable where sd_key in (select del_key from #tmpDeleted)

	truncate table #tmpDeleted
	set @sql = 'insert into #tmpDeleted (del_key) select ph_key from dbo.mwPriceHotels with(nolock) where not exists(select top (1) 1 from mt.' + @pubdb + '.dbo.tp_prices with(nolock) where tp_tokey = sd_tourkey)'
	exec (@sql)
	delete from dbo.mwPriceHotels where ph_key in (select del_key from #tmpDeleted)

	truncate table #tmpDeleted
	set @sql = 'insert into #tmpDeleted (del_key) select pd_key from dbo.mwPriceDurations with(nolock) where not exists(select top (1) 1 from mt.' + @pubdb + '.dbo.tp_prices with(nolock) where tp_tokey = sd_tourkey)'
	exec (@sql)
	delete from dbo.mwPriceDurations where pd_key in (select del_key from #tmpDeleted)
	
	drop table #tmpDeleted

	set nocount off
end
GO

GRANT EXECUTE on [dbo].[mwRemoveDeleted] to public
GO
/*********************************************************************/
/* end sp_mwRemoveDeleted.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplDisableDeletedPrices.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReplDisableDeletedPrices]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwReplDisableDeletedPrices]
GO

CREATE procedure [dbo].[mwReplDisableDeletedPrices]
--<DATE>2013-12-12</DATE>
--<VERSION>9.2.20.3</VERSION>
as
begin
	declare @cnKey int
	declare @ctKeyFrom int
	declare @sql varchar (500)
	declare @wasError as bit
	declare @errorText as nvarchar(max)

	set @wasError = 0

	select top 100000 * into #mwReplDeletedPricesTemp from dbo.mwReplDeletedPricesTemp with(nolock);
	create index x_pricekey on #mwReplDeletedPricesTemp(rdp_pricekey);

	begin try
	if (dbo.mwReplIsSubscriber() > 0 or (dbo.mwReplIsPublisher() <= 0 and dbo.mwReplIsSubscriber() <= 0))
		and (exists(select top 1 1 from #mwReplDeletedPricesTemp))
	begin
		insert into dbo.mwDeleted (del_key)
		select rdp_pricekey from #mwReplDeletedPricesTemp;

		if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
		begin
			declare @wasErrorInCycle as bit
			set @wasErrorInCycle = 0

			begin try
				--Используется секционирование ценовых таблиц
				declare mwPriceDataTableNameCursor cursor for
					select distinct dbo.mwGetPriceTableName(rdp_cnkey, rdp_ctdeparturekey) as ptn_tablename
					from #mwReplDeletedPricesTemp with(nolock);

				declare @mwPriceDataTableName varchar(200);
				open mwPriceDataTableNameCursor;
				fetch next from mwPriceDataTableNameCursor into @mwPriceDataTableName;

				while @@FETCH_STATUS = 0
				begin
					if exists (select * from sys.tables where @mwPriceDataTableName like '%' + name)
					begin
						set @sql='
							update ' + @mwPriceDataTableName + ' 
							set pt_isenabled = 0
							where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey)';

						exec (@sql)
					end

					fetch next from mwPriceDataTableNameCursor into @mwPriceDataTableName
				end
			end try
			begin catch
				set @wasErrorInCycle = 1
				set @errorText = ERROR_MESSAGE()
			end catch

			-- release resources
			close mwPriceDataTableNameCursor
			deallocate mwPriceDataTableNameCursor

			if @wasError = 1
			begin
				-- rethrow error after resources release
				raiserror(@errorText, 16, 1)
			end
		end
		else
		begin
			--Секционирование не используется
			update dbo.mwPriceDataTable 
			set pt_isenabled = 0
			where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey);
		end
	end

	end try
	begin catch
		set @wasError = 1
		set @errorText = ERROR_MESSAGE()
	end catch

	if @wasError = 0
	begin
		-- delete from source table only if processing was successful
		delete from mwReplDeletedPricesTemp
		where exists(select top 1 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = mwReplDeletedPricesTemp.rdp_pricekey)
	end

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

GRANT EXECUTE ON [dbo].[mwReplDisableDeletedPrices]	TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwReplDisableDeletedPrices.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplProcessQueueDivide.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReplProcessQueueDivide]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwReplProcessQueueDivide]
GO

create procedure [dbo].[mwReplProcessQueueDivide] (@jobId smallint = null)
as
begin
	--<VERSION>2009.2.20</VERSION>
	--<DATE>2013-08-12</DATE>

	if dbo.mwReplIsSubscriber() <= 0
		return

	-- обновляем инфу о стране и городе вылета по туру
	if exists(select 1 from mwReplQueue with(nolock) where rq_state = 1 and rq_cnkey is null)
	begin
		update mwReplQueue
		set rq_cnkey = TO_CNKey,
		rq_ctkeyfrom = TL_CTDepartureKey
		from tp_tours
		join tbl_TurList on tl_key = to_trkey
		where to_key = rq_tokey
		and rq_cnkey is null
		and rq_state = 1
	end
		
	if (@jobId is null)
		set @jobId = @@SPID
		
	-- такое может происходить только, если произошла аварийная остановка джоба и его повторный запуск
	-- апдейтим таблицу направлений и таблицу очереди
	if exists(select 1 from mwReplDirections where RD_IsUsed = @jobId)
	begin
		update mwReplQueue 
		set rq_state = 4 
		from mwReplDirections
		where RD_CNKey = rq_cnkey
		and RD_CTKeyFrom = rq_ctkeyfrom
		and rq_state = 3
		and RD_IsUsed = @jobId
		
		update mwReplDirections set RD_IsUsed = 0 where RD_IsUsed = @jobId
		
	end
		
	declare @mwSearchType int
	declare @cnKey int, @ctKey int
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'

	declare @rqId int
	declare @rqMode int
	declare @rqToKey int
	declare @rqCalculatingKey int
	declare @rqOverwritePrices bit	

	declare @directions table(CNKey int, CTKey int, IsUsed int default(0))
	declare @currentQueue table(xrq_id int, xrq_mode int, xrq_tokey int, xrq_CalculatingKey int, xRQ_OverwritePrices bit, xrq_state int, xrq_enddate datetime)

	select top 1 @cnKey = isnull(rq_cnkey, 0), @ctKey = isnull(rq_ctkeyfrom, 0)
	from mwReplQueue with(nolock)
	join mwReplDirections with(nolock) on rd_cnkey = isnull(rq_cnkey, 0) and rd_ctkeyfrom = isnull(rq_ctkeyfrom, 0)
	where rd_isUsed = 0
	and (rq_state = 1 or rq_state = 2)
	and rq_mode <= 5
	order by rq_priority desc, rq_crdate
	
	update mwReplDirections set RD_IsUsed = @jobId where RD_IsUsed = 0 and rd_cnkey = @cnKey and RD_CTKeyFrom = @ctkey
	if not exists(select 1 from mwReplDirections where RD_IsUsed = @jobId)
		return
		
	insert into @currentQueue (xrq_id, xrq_mode, xrq_tokey, xrq_CalculatingKey, xRQ_OverwritePrices)
	select top 10 rq_id, rq_mode, rq_tokey, rq_CalculatingKey, RQ_OverwritePrices
	from mwReplQueue 
	where (rq_state = 1 or rq_state = 2)
	and isnull(rq_cnkey, 0) = @cnKey
	and isnull(rq_ctkeyfrom, 0) = @ctKey
	and rq_mode <= 5
	order by rq_priority desc, rq_crdate
	
	update mwReplQueue set [rq_state] = 3, [rq_startdate] = getdate() where rq_id in (select xrq_id from @currentQueue)
	
	declare queueCursor cursor local fast_forward for
	select xrq_id, xrq_mode, xrq_tokey, xrq_CalculatingKey, xRQ_OverwritePrices
	from @currentQueue
	
	open queueCursor
	fetch queueCursor into @rqId, @rqMode, @rqToKey, @rqCalculatingKey, @rqOverwritePrices
	
	while (@@FETCH_STATUS = 0)
	begin
		
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
			
			update mwReplQueue set rq_state = 5, rq_enddate = getdate() where rq_id = @rqId
			
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
			select @rqId, 'Command complete.'
		
		end try
		begin catch
			update mwReplQueue set rq_state = 4, rq_enddate = getdate() where rq_id = @rqId
			
			declare @errMessage varchar(max)
			set @errMessage = 'Error at ' + isnull(ERROR_PROCEDURE(), '[mwReplProcessQueueDivide]') +' : ' + isnull(ERROR_MESSAGE(), '[msg_not_set]')
			
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text])
			select @rqId, @errMessage
		end catch
		
		fetch queueCursor into @rqId, @rqMode, @rqToKey, @rqCalculatingKey, @rqOverwritePrices
		
	end
	
	close queueCursor
	deallocate queueCursor
	
	update mwReplDirections set rd_isUsed = 0 where rd_isUsed = @jobId
	
	if exists(select top 1 1 from mwReplQueue with(nolock) where rq_state = 4 and DATEDIFF(MINUTE, rq_enddate, GETDATE()) > 10 and rq_priority > 0)
	begin
		delete from mwReplQueue where rq_tokey not in (select to_key from TP_Tours) and rq_mode <> 4 and (rq_startdate is null or rq_state = 4)
		
		update mwReplQueue set rq_state = 1, rq_startdate = null, rq_enddate = null, rq_priority = rq_priority - 1
		where rq_state = 4 
		and DATEDIFF(MINUTE, rq_enddate, GETDATE()) > 10
		and rq_priority > 0

	end
end
GO

grant exec on [dbo].[mwReplProcessQueueDivide] to public
GO
/*********************************************************************/
/* end sp_mwReplProcessQueueDivide.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_QuotaDetailAfterDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetailAfterDelete]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[QuotaDetailAfterDelete]
GO

CREATE PROCEDURE [dbo].[QuotaDetailAfterDelete]
AS
	--<VERSION>9.2.20.3</VERSION>
	--<DATE>2013-12-10</DATE>
	--Процедура освобождает удаленные квоты
	--QD_IsDeleted хранит статус, в который требуется поставить услуги, на данный момент находящиеся на данной квоте
	--QD_IsDeleted=3 - подтвердить (ВАЖНО подтверждается только те даты которые удаляются)
	--QD_IsDeleted=4 - Request (ВАЖНО на Request только те даты которые удаляются)
	--QD_IsDeleted=1 - попытка поставить на квоту (ВАЖНО на квоту пробуем поставить место, на всем протяжении услуги, то есть - если это проживание и только один день удаляем из квоты, то место снимается с квоты целиком и пытается сесть снова)

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @SD_DLKey int
	DECLARE @ServiceByDateState int
	DECLARE @dateFrom datetime
	DECLARE @dateTo datetime

	IF Exists (SELECT top 1 1 
			   FROM QuotaDetails
			   join QuotaParts on QP_QDID = QD_ID
			   join ServiceByDate on SD_QPID=QP_ID
			   WHERE QD_IsDeleted in (3,4))
	BEGIN
		declare @DLKeysForUpdare table
		(
			DL_Key int,
			ServiceByDateState INT,
			DateFrom DATETIME,
			DateTo DATETIME
		)
		
		insert into @DLKeysForUpdare(DL_Key, ServiceByDateState, DateFrom, DateTo) 
		select SD_DLKey, 
			   MAX(QP_IsDeleted) AS ServiceByDateState,
			   MIN(QP_Date) as DateFrom,
			   MAX(QP_Date) as DateTo
		from ServiceByDate
		join QuotaParts on QP_ID = SD_QPID
		join QuotaDetails on QD_ID = QP_QDID
		where QD_IsDeleted in (3,4) GROUP BY SD_DLKey

		UPDATE ServiceByDate 
		SET SD_State = 3, SD_QPID = null 
		WHERE SD_QPID in (SELECT QP_ID 
						  FROM QuotaDetails
						  join QuotaParts on QP_QDID = QD_ID
						  WHERE QD_IsDeleted = 3)
						  
		UPDATE ServiceByDate 
		SET SD_State = 4, SD_QPID = null 
		WHERE SD_QPID in (SELECT QP_ID 
						  FROM QuotaDetails
						  join QuotaParts on QP_QDID = QD_ID
						  WHERE QD_IsDeleted=4)
		
		DECLARE cur_QuotaDetailDelete CURSOR local fast_forward FOR 
		SELECT DISTINCT DL_Key, ServiceByDateState, DateFrom, DateTo FROM @DLKeysForUpdare
		
		OPEN cur_QuotaDetailDelete
		FETCH NEXT FROM cur_QuotaDetailDelete INTO @SD_DLKey, @ServiceByDateState, @dateFrom, @dateTo
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC dbo.DogListToQuotas @SD_DLKey, 1, @SetQuotaType = @ServiceByDateState, @ToSetQuotaDateFrom = @dateFrom, @ToSetQuotaDateTo = @dateTo
			FETCH NEXT FROM cur_QuotaDetailDelete INTO @SD_DLKey, @ServiceByDateState, @dateFrom, @dateTo
		END
		CLOSE cur_QuotaDetailDelete
		DEALLOCATE cur_QuotaDetailDelete
	END

	IF Exists (SELECT top 1 1 
			   FROM QuotaDetails
			   join QuotaParts on QP_QDID = QD_ID
			   join ServiceByDate on SD_QPID = QP_ID 
			   WHERE QD_IsDeleted in (1))
	BEGIN
		DECLARE cur_QuotaDetailDelete CURSOR local fast_forward FOR 
			SELECT DISTINCT SD_DLKey 
			FROM ServiceByDate 
			WHERE SD_QPID in (SELECT QP_ID 
							  FROM QuotaDetails
							  join QuotaParts on QP_QDID = QD_ID
							  WHERE QD_IsDeleted=1)
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

	update QuotaParts 
	set QP_IsDeleted = 1 
	from QuotaParts 
	join QuotaDetails on QP_QDID = QD_ID 
	where QD_IsDeleted in (1,3,4)

	DELETE FROM QuotaLimitations WHERE QL_QPID in (SELECT QP_ID FROM QuotaParts join QuotaDetails on QD_ID = QP_QDID WHERE QD_IsDeleted in (1,3,4))				  
	DELETE QuotaParts where exists(select top 1 1 from QuotaDetails WHERE QD_IsDeleted in (1,3,4) and QD_ID = QP_QDID) and not exists(select top 1 1 from ServiceByDate where SD_QPID=QP_ID) and QP_IsDeleted = 1
	DELETE FROM StopSales WHERE SS_QDID in (SELECT QD_ID FROM QuotaDetails with (nolock) WHERE QD_IsDeleted in (1,3,4))
	DELETE FROM QuotaDetails WHERE QD_IsDeleted in (1,3,4) and QD_ID not in (Select QP_QDID from ServiceByDate with (nolock), QuotaParts with (nolock) where SD_QPID=QP_ID and QP_QDID=QD_ID)
GO

GRANT EXECUTE on [dbo].[QuotaDetailAfterDelete] to public
GO
/*********************************************************************/
/* end sp_QuotaDetailAfterDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_RecalculatePriceListScheduler.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RecalculatePriceListScheduler]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[RecalculatePriceListScheduler]
GO

CREATE PROCEDURE [dbo].[RecalculatePriceListScheduler]
AS
--<DATE>2013-09-11</DATE>
---<VERSION>9.2.0</VERSION>
BEGIN

	declare @cpkey int
	declare @priceTOKey int
	declare @saleDate datetime
	declare @nullCostAsZero smallint
	declare @noFlight smallint
	declare @update smallint
	declare @useHolidayRule smallint
		
	begin tran
		select top 1 @cpkey = CP_Key 
		from CalculatingPriceLists 
		where CP_StartTime is not null and (CP_Status = 3 and CP_StartTime<=GETDATE()) order by CP_StartTime asc
		UPDATE CalculatingPriceLists WITH (ROWLOCK) Set CP_Status=1 where CP_Key=@cpkey
	commit tran
	if (@cpkey is not null)
	begin
		select @priceTOKey = CP_PriceTourKey, @saleDate = CP_SaleDate, @update = CP_Update,
			 @nullCostAsZero = CP_NullCostAsZero, @noFlight = CP_NoFlight, @useHolidayRule = CP_UseHolidayRule
		from CalculatingPriceLists where CP_Key = @cpkey
		begin try
			exec CalculatePriceList @priceTOKey, @cpkey, @saleDate, @nullCostAsZero, @noFlight, @update,@useHolidayRule
			UPDATE CalculatingPriceLists WITH (ROWLOCK) Set CP_Status=0, CP_StartTime=null where CP_Key=@cpkey
		end try
		begin catch
			UPDATE CalculatingPriceLists with (rowlock) set CP_Status=2 where CP_Key=@cpkey
		end catch
	end
END
GO

GRANT EXEC ON [dbo].[RecalculatePriceListScheduler] TO PUBLIC
GO
/*********************************************************************/
/* end sp_RecalculatePriceListScheduler.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_mwDeleteTour.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[mwDeleteTour]'))
	DROP TRIGGER [dbo].[mwDeleteTour]
GO

CREATE trigger [dbo].[mwDeleteTour] on [dbo].[TP_Tours]
for delete
as
begin

	--<VERSION>2009.2.20.4</VERSION>
	--<DATE>2013-12-18</DATE>

	if dbo.mwReplIsSubscriber() > 0
	begin
		insert into mwReplQueue(rq_mode, rq_tokey)
		select 4, to_key
		from deleted
	end
	else if dbo.mwReplIsPublisher() <= 0
	begin
		declare @sql nvarchar(max), @params nvarchar(max), @tourExists int

		declare @tableName nvarchar(100), @tokey int, @cnKey int, @ctDepartureKey int
		if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
		begin
			declare tourCursor cursor fast_forward read_only for
			select to_key from deleted
			open tourCursor
			fetch tourCursor into @tokey
			while (@@FETCH_STATUS = 0)
			begin
				--Используется секционирование ценовых таблиц
				declare disableCursor cursor fast_forward read_only for
				select name from sysobjects with(nolock) where name like 'mwPriceDataTable[_]%' and xtype = 'u'
				
				open disableCursor
				fetch next from disableCursor into @tableName
				while (@@FETCH_STATUS = 0)
				begin
					set @sql = 'if exists (select 1 from ' + @tableName + ' with(nolock) where pt_tourkey = ' + ltrim(str(@toKey)) + ')
					begin
						set @tourExistsOut = 1
					end
					else
					begin
						set @tourExistsOut = 0
					end'
					set @params = '@tourExistsOut int output'
					EXECUTE sp_executesql @sql, @params, @tourExistsOut = @tourExists output

					if (@tourExists = 1)
					begin
						set @sql = 'insert into mwDeleted (del_key) select pt_pricekey from ' + @tableName + ' with(nolock) where pt_tourkey = ' + ltrim(str(@toKey)) + '
									update ' + @tableName + ' set pt_isenabled = 0 where pt_isenabled > 0 and pt_tourkey = ' + ltrim(str(@toKey)) + '
									update mwSpoDataTable set sd_isenabled = 0 where sd_isenabled > 0 and sd_tourkey = ' + ltrim(str(@toKey))
						exec (@sql)
					end
					fetch next from disableCursor into @tableName
				end

				close disableCursor
				deallocate disableCursor
				
				delete from TP_Prices where tp_tokey = @tokey
				delete from TP_ServiceLists where tl_tokey = @tokey
				delete from TP_Services where ts_tokey = @tokey
				delete from TP_Lists where ti_tokey = @tokey

				fetch tourCursor into @tokey
			end
			close tourCursor
			deallocate tourCursor
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
				set @sql = 'insert into mwDeleted (del_key) select pt_pricekey from ' + @tableName + ' with(nolock) where pt_tourkey = ' + ltrim(str(@tokey)) + '
							update ' + @tableName + ' set pt_isenabled = 0 where pt_isenabled > 0 and pt_tourkey = ' + ltrim(str(@tokey)) + '
							update mwSpoDataTable set sd_isenabled = 0 where sd_isenabled > 0 and sd_tourkey = ' + ltrim(str(@tokey))
				exec (@sql)

				delete from TP_Prices where tp_tokey = @tokey
				delete from TP_ServiceLists where tl_tokey = @tokey
				delete from TP_Services where ts_tokey = @tokey
				delete from TP_Lists where ti_tokey = @tokey

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
update [dbo].[setting] set st_version = '9.2.20.4', st_moduledate = convert(datetime, '2013-12-20', 120),  st_financeversion = '9.2.20.4', st_financedate = convert(datetime, '2013-12-20', 120) 
 GO
 UPDATE dbo.SystemSettings SET SS_ParmValue='2013-12-20' WHERE SS_ParmName='SYSScriptDate'
 GO