/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 08.08.2014 10:03 %%%%%%%%%%%%%%%%%%%%%%%%*/
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
	DECLARE @PrevVersion nvarchar(128) = '9.2.20.18'
	DECLARE @CurrentVersion nvarchar(128) = (SELECT TOP 1 ST_VERSION FROM SETTING)
	DECLARE @NewVersion nvarchar(128) = '9.2.20.19'

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
/* begin (2014_07_23)_CreateTable_QuestionnaireDataQuery.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT TOP 1 1 FROM SYS.TABLES WHERE NAME = 'QuestionnaireDataQuery')
BEGIN
	CREATE TABLE [dbo].[QuestionnaireDataQuery](
		[QDQ_Key] [int] IDENTITY(1,1) NOT NULL,
		[QDQ_Name] [nvarchar](100) NULL,
		[QDQ_Text] [varchar](800) NULL,
	 CONSTRAINT [PK_QuestionnaireDataQuery] PRIMARY KEY CLUSTERED 
	(
		[QDQ_Key] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
	) ON [PRIMARY]
END

GRANT SELECT ON [dbo].[QuestionnaireDataQuery] TO PUBLIC

GO
/*********************************************************************/
/* end (2014_07_23)_CreateTable_QuestionnaireDataQuery.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_QuestionnaireFieldUpdate.sql */
/*********************************************************************/
if exists (select id from sysobjects where xtype = 'TR' and name='T_QuestionnaireFieldUpdate')
	drop trigger dbo.T_QuestionnaireFieldUpdate
go

CREATE TRIGGER [dbo].[T_QuestionnaireFieldUpdate] ON [dbo].[QuestionnaireField]
AFTER INSERT, UPDATE, DELETE
AS
--<DATE>2013-07-08</DATE>
--<VERSION>2009.2.20.0</VERSION>
  DECLARE @QF_Key int
  
  DECLARE @OQF_QUKey int
  DECLARE @OQF_QFTKey int
  DECLARE @OQF_Name nvarchar(200)
  DECLARE @OQF_NameLat nvarchar(200)
  DECLARE @OQF_Order int
  DECLARE @OQF_BitAttributes int
  DECLARE @OQF_DefaultValue nvarchar(200)
  DECLARE @OQF_RelatedTableId int
  DECLARE @OQF_RelatedColumnId int
  DECLARE @OQF_Comment nvarchar(200)
  DECLARE @OQF_TagXML nvarchar(50)
  DECLARE @OQF_Format nvarchar(50)
  DECLARE @OQF_Example nvarchar(200)
  DECLARE @OQF_Bookmark nvarchar(50)
  
  DECLARE @NQF_QUKey int
  DECLARE @NQF_QFTKey int
  DECLARE @NQF_Name nvarchar(200)
  DECLARE @NQF_NameLat nvarchar(200)
  DECLARE @NQF_Order int
  DECLARE @NQF_BitAttributes int
  DECLARE @NQF_DefaultValue nvarchar(200)
  DECLARE @NQF_RelatedTableId int
  DECLARE @NQF_RelatedColumnId int
  DECLARE @NQF_Comment nvarchar(200)
  DECLARE @NQF_TagXML nvarchar(50)
  DECLARE @NQF_Format nvarchar(50)
  DECLARE @NQF_Example nvarchar(200)
  DECLARE @NQF_Bookmark nvarchar(50)
  
  DECLARE @sMod varchar(3)
  DECLARE @nDelCount int
  DECLARE @nInsCount int
  DECLARE @nHIID int
  DECLARE @sHI_Text varchar(254)
  
  DECLARE @bNeedCommunicationUpdate smallint
	  
  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED
  
  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
	DECLARE cur_QuestionnaireFields CURSOR FOR 
	SELECT 	N.QF_Key,
	        null, null, null, null, null, null, null, null, null, null, null, 
	            null, null, null, 
			N.QF_QUKey, N.QF_QFTKey, N.QF_Name, N.QF_NameLat, N.QF_Order, N.QF_BitAttributes, N.QF_DefaultValue, N.QF_RelatedTableId, N.QF_RelatedColumnId, N.QF_Comment, N.QF_TagXML, 
				N.QF_Format, N.QF_Example, N.QF_Bookmark
	FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
	DECLARE cur_QuestionnaireFields CURSOR FOR 
	SELECT 	O.QF_Key,
			O.QF_QUKey, O.QF_QFTKey, O.QF_Name, O.QF_NameLat, O.QF_Order, O.QF_BitAttributes, O.QF_DefaultValue, O.QF_RelatedTableId, O.QF_RelatedColumnId, O.QF_Comment, O.QF_TagXML, 
				O.QF_Format, O.QF_Example, O.QF_Bookmark,
	        null, null, null, null, null, null, null, null, null, null, null, 
	            null, null, null
	FROM DELETED O
  END
  ELSE 
  BEGIN
	SET @sMod = 'UPD'
	DECLARE cur_QuestionnaireFields CURSOR FOR 
	SELECT 	N.QF_Key,
			O.QF_QUKey, O.QF_QFTKey, O.QF_Name, O.QF_NameLat, O.QF_Order, O.QF_BitAttributes, O.QF_DefaultValue, O.QF_RelatedTableId, O.QF_RelatedColumnId, O.QF_Comment, O.QF_TagXML, 
				O.QF_Format, O.QF_Example, O.QF_Bookmark,
			N.QF_QUKey, N.QF_QFTKey, N.QF_Name, N.QF_NameLat, N.QF_Order, N.QF_BitAttributes, N.QF_DefaultValue, N.QF_RelatedTableId, N.QF_RelatedColumnId, N.QF_Comment, N.QF_TagXML, 
				N.QF_Format, N.QF_Example, N.QF_Bookmark
	FROM DELETED O, INSERTED N 
	WHERE N.QF_Key = O.QF_Key
  END
  
  OPEN cur_QuestionnaireFields
	FETCH NEXT FROM cur_QuestionnaireFields INTO 
		@QF_Key,
		@OQF_QUKey, @OQF_QFTKey, @OQF_Name, @OQF_NameLat, @OQF_Order, @OQF_BitAttributes, @OQF_DefaultValue, @OQF_RelatedTableId, @OQF_RelatedColumnId, @OQF_Comment, 
			@OQF_TagXML, @OQF_Format, @OQF_Example, @OQF_Bookmark, 
		@NQF_QUKey, @NQF_QFTKey, @NQF_Name, @NQF_NameLat, @NQF_Order, @NQF_BitAttributes, @NQF_DefaultValue, @NQF_RelatedTableId, @NQF_RelatedColumnId, @NQF_Comment, 
			@NQF_TagXML, @NQF_Format, @NQF_Example, @NQF_Bookmark
	WHILE @@FETCH_STATUS = 0
	BEGIN
	------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OQF_QUKey, '') != ISNULL(@NQF_QUKey, '') OR
			ISNULL(@OQF_QFTKey, '') != ISNULL(@NQF_QFTKey, '') OR
			ISNULL(@OQF_Name, '') != ISNULL(@NQF_Name, '') OR
			ISNULL(@OQF_NameLat, '') != ISNULL(@NQF_NameLat, '') OR
			ISNULL(@OQF_Order, '') != ISNULL(@NQF_Order, '') OR
			ISNULL(@OQF_BitAttributes, '') != ISNULL(@NQF_BitAttributes, '') OR
			ISNULL(@OQF_DefaultValue, '') != ISNULL(@NQF_DefaultValue, '') OR
			ISNULL(@OQF_RelatedTableId, '') != ISNULL(@NQF_RelatedTableId, '') OR
			ISNULL(@OQF_RelatedColumnId, '') != ISNULL(@NQF_RelatedColumnId, '') OR
			ISNULL(@OQF_Comment, '') != ISNULL(@NQF_Comment, '') OR
			ISNULL(@OQF_TagXML, '') != ISNULL(@NQF_TagXML, '') OR
			ISNULL(@OQF_Format, '') != ISNULL(@NQF_Format, '') OR
			ISNULL(@OQF_Example, '') != ISNULL(@NQF_Example, '') OR
			ISNULL(@OQF_Bookmark, '') != ISNULL(@NQF_Bookmark, '')
			)
		BEGIN
			------------Запись в историю--------------------------------------------------------------------
			if (@sMod = 'INS')
			BEGIN
				SET @sHI_Text = ISNULL(@NQF_Name, '')
			END
			else if (@sMod = 'DEL')
				BEGIN
					SET @sHI_Text = ISNULL(@OQF_Name, '')
				END
			else if (@sMod = 'UPD')
			BEGIN
				SET @sHI_Text = ISNULL(@NQF_Name, '')
			END
			
			EXEC @nHIID = dbo.InsHistory null, null, 52, @QF_Key, @sMod, @sHI_Text, '', 0, ''
			
			--------Детализация--------------------------------------------------
	
			If (ISNULL(@OQF_QUKey, '') != ISNULL(@NQF_QUKey, ''))
				BEGIN	
					declare @OQF_QU varchar(200), @NQF_QU varchar(200)
					
					If(@OQF_QUKey is not null)
						select @OQF_QU = QU_Name from Questionnaire where QU_Key = @OQF_QUKey
					else
						set @OQF_QU = null
						
					If(@NQF_QUKey is not null)
						select @NQF_QU = QU_Name from Questionnaire where QU_Key = @NQF_QUKey
					else
						set @NQF_QU = null
					
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52001, null, null, @OQF_QUKey, @NQF_QUKey, null, null, 0, @bNeedCommunicationUpdate output
				END
			
			If (ISNULL(@OQF_QFTKey, '') != ISNULL(@NQF_QFTKey, ''))
				BEGIN	
					declare @OQF_QFT varchar(200), @NQF_QFT varchar(200)
					
					If(@OQF_QFTKey is not null)
						select @OQF_QFT = QFT_Name from QuestionnaireFieldTemplate where QFT_Key = @OQF_QFTKey
					else
						set @OQF_QFT = null
						
					If(@NQF_QFTKey is not null)
						select @NQF_QFT = QFT_Name from QuestionnaireFieldTemplate where QFT_Key = @NQF_QFTKey
					else
						set @NQF_QFT = null
					
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52002, @OQF_QFT, @NQF_QFT, @OQF_QFTKey, @NQF_QFTKey, null, null, 0, @bNeedCommunicationUpdate output
				END	
			
			If (ISNULL(@OQF_Name, '') != ISNULL(@NQF_Name, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52003, @OQF_Name, @NQF_Name, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END
				
			If (ISNULL(@OQF_NameLat, '') != ISNULL(@NQF_NameLat, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52004, @OQF_NameLat, @NQF_NameLat, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END
			
			If (ISNULL(@OQF_Order, '') != ISNULL(@NQF_Order, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52005,  null, null, @OQF_Order, @NQF_Order, null, null, 0, @bNeedCommunicationUpdate output
				END	
			
			If (ISNULL(@OQF_BitAttributes, '') != ISNULL(@NQF_BitAttributes, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52006, null, null, @OQF_BitAttributes, @NQF_BitAttributes, null, null, 0, @bNeedCommunicationUpdate output
				END
				
			If (ISNULL(@OQF_DefaultValue, '') != ISNULL(@NQF_DefaultValue, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52007, @OQF_DefaultValue, @NQF_DefaultValue, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END
			
			If (ISNULL(@OQF_RelatedTableId, '') != ISNULL(@NQF_RelatedTableId, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52008, null, null, @OQF_RelatedTableId, @NQF_RelatedTableId, null, null, 0, @bNeedCommunicationUpdate output
				END	
			
			If (ISNULL(@OQF_RelatedColumnId, '') != ISNULL(@NQF_RelatedColumnId, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52009, null, null, @OQF_RelatedColumnId, @NQF_RelatedColumnId, null, null, 0, @bNeedCommunicationUpdate output
				END
				
			If (ISNULL(@OQF_Comment, '') != ISNULL(@NQF_Comment, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52010, @OQF_Comment, @NQF_Comment, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END
			
			If (ISNULL(@OQF_TagXML, '') != ISNULL(@NQF_TagXML, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52011, @OQF_TagXML, @NQF_TagXML, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END	
			
			If (ISNULL(@OQF_Format, '') != ISNULL(@NQF_Format, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52012, @OQF_Format, @NQF_Format, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END
				
			If (ISNULL(@OQF_Example, '') != ISNULL(@NQF_Example, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52013, @OQF_Example, @NQF_Example, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END
			
			If (ISNULL(@OQF_Bookmark, '') != ISNULL(@NQF_Bookmark, ''))
				BEGIN	
					EXECUTE dbo.InsertHistoryDetail @nHIID , 52015, @OQF_Bookmark, @NQF_Bookmark, null, null, null, null, 0, @bNeedCommunicationUpdate output
				END

		END
		FETCH NEXT FROM cur_QuestionnaireFields INTO 
		@QF_Key,
		@OQF_QUKey, @OQF_QFTKey, @OQF_Name, @OQF_NameLat, @OQF_Order, @OQF_BitAttributes, @OQF_DefaultValue, @OQF_RelatedTableId, @OQF_RelatedColumnId, @OQF_Comment, 
			@OQF_TagXML, @OQF_Format, @OQF_Example, @OQF_Bookmark, 
		@NQF_QUKey, @NQF_QFTKey, @NQF_Name, @NQF_NameLat, @NQF_Order, @NQF_BitAttributes, @NQF_DefaultValue, @NQF_RelatedTableId, @NQF_RelatedColumnId, @NQF_Comment, 
			@NQF_TagXML, @NQF_Format, @NQF_Example, @NQF_Bookmark
	END
  CLOSE cur_QuestionnaireFields
  DEALLOCATE cur_QuestionnaireFields
GO



/*********************************************************************/
/* end T_QuestionnaireFieldUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014_07_23)_AlterTable_QuestionnaireField.sql */
/*********************************************************************/
if exists(select top 1 1 from sys.columns col
				inner join sys.tables tab on col.object_id=tab.object_id
				where tab.name = 'QuestionnaireField'
				and col.name = 'QF_QuerySQL')
begin
	ALTER TABLE dbo.QuestionnaireField DROP COLUMN QF_QuerySQL
end

GO
/*********************************************************************/
/* end (2014_07_23)_AlterTable_QuestionnaireField.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-08-04)_AlterTable_Transfer_AlterColumn_PLACEFROM_PLACETO.sql */
/*********************************************************************/
BEGIN TRY
    alter table [Transfer] alter column [TF_PLACEFROM] [varchar](300) NULL
END TRY
BEGIN CATCH
		DECLARE @ErrorSeverityF INT;
		DECLARE @ErrorStateF INT;
		
		SELECT 
			@ErrorSeverityF = ERROR_SEVERITY(),
			@ErrorStateF = ERROR_STATE();
		RAISERROR ('Произошла ошибка при изменении столбца [TF_PLACEFROM] таблицы [Transfer]. Обратитесь в техподдержку.',
               @ErrorSeverityF,@ErrorStateF); 
END CATCH

GO

BEGIN TRY
    alter table [Transfer] alter column [TF_PLACETO] [varchar](300) NULL
END TRY
BEGIN CATCH
		DECLARE @ErrorSeverityT INT;
		DECLARE @ErrorStateT INT;
		
		SELECT 
			@ErrorSeverityT = ERROR_SEVERITY(),
			@ErrorStateT = ERROR_STATE();
		RAISERROR ('Произошла ошибка при изменении столбца [TF_PLACETO] таблицы [Transfer]. Обратитесь в техподдержку.',
               @ErrorSeverityT,@ErrorStateT); 
END CATCH

GO
/*********************************************************************/
/* end (2014-08-04)_AlterTable_Transfer_AlterColumn_PLACEFROM_PLACETO.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014-08-04_AlterTable)CommunicationServices_DropAndCreateConstraint_FKDogovorList.sql */
/*********************************************************************/
declare @cName nvarchar(100)
select @cName = CONSTRAINT_NAME from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME like 'FK__Communica__CMS_D_%' and UNIQUE_CONSTRAINT_NAME = 'X_DOGOVORLISTKEY'

declare @sql nvarchar(200)
set @sql = 'alter table CommunicationServices drop constraint ' + @cName

execute (@sql)

if not exists (select 1 from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = 'FK_CommunicationServices_DogovorList')
alter table CommunicationServices add constraint FK_CommunicationServices_DogovorList foreign key (CMS_DlKey) references tbl_DogovorList (DL_Key) on delete cascade

go
/*********************************************************************/
/* end (2014-08-04_AlterTable)CommunicationServices_DropAndCreateConstraint_FKDogovorList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2014_07_31)_Insert_Actions.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT 1 FROM Actions WHERE ac_key = 167) 
BEGIN
	INSERT INTO Actions (AC_Key, AC_Name, AC_Description, AC_NameLat, AC_IsActionForRestriction) 
	VALUES (167, 'Посольские анкеты -> Разрешить редактирование анкетных запросов выборки данных', 
		'Разрешить пользователю редактировать SQL-запросы, выполняющиеся для выборки данных в поля визовых анкет при автозаполнении', 
		'Visa Questionnaires -> Allow edit field data queries', 0)
END
GO

/*********************************************************************/
/* end (2014_07_31)_Insert_Actions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReindex.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReindex]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwReindex]
GO

CREATE procedure [dbo].[mwReindex] as
begin

	--<DATE>2014-08-01</DATE>
	--<VERSION>9.2.20.18</VERSION>
	
	DECLARE @objectid int;
	DECLARE @indexid int;
	DECLARE @partitioncount bigint;
	DECLARE @schemaname nvarchar(130); 
	DECLARE @objectname nvarchar(130); 
	DECLARE @indexname nvarchar(130); 
	DECLARE @partitionnum bigint;
	DECLARE @partitions bigint;
	DECLARE @frag float;
	DECLARE @db_id int;
	DECLARE @fillfactor int;

	set @db_id = DB_ID()

	DECLARE @command nvarchar(4000); 
	SELECT
		object_id AS objectid,
		index_id AS indexid,
		partition_number AS partitionnum,
		MAX(avg_fragmentation_in_percent) AS frag
	INTO #work_to_do
	FROM sys.dm_db_index_physical_stats (@db_id, NULL, NULL , NULL, 'DETAILED')
	WHERE avg_fragmentation_in_percent > 10.0 AND index_id > 0 AND (index_level = 0 OR page_count > 1000)
	GROUP BY object_id, index_id, partition_number

	DECLARE partitions CURSOR READ_ONLY FAST_FORWARD LOCAL FOR SELECT * FROM #work_to_do;
	OPEN partitions;
	WHILE (1 = 1)
		BEGIN
			FETCH NEXT
			   FROM partitions
			   INTO @objectid, @indexid, @partitionnum, @frag;
			IF @@FETCH_STATUS < 0 BREAK;
			SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name)
			FROM sys.objects AS o
			JOIN sys.schemas as s ON s.schema_id = o.schema_id
			WHERE o.object_id = @objectid;
			SELECT @indexname = QUOTENAME(name), @fillfactor = fill_factor
			FROM sys.indexes
			WHERE  object_id = @objectid AND index_id = @indexid;
			SELECT @partitioncount = count (*)
			FROM sys.partitions
			WHERE object_id = @objectid AND index_id = @indexid;
			IF @frag >= 30.0 OR @fillfactor <> 80 
				SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD WITH (FILLFACTOR = 80)';
			ELSE
				SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';

			IF @partitioncount > 1
				SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));
			EXEC (@command);
			PRINT N'Executed: ' + @command;
		END;
	CLOSE partitions;
	DEALLOCATE partitions;
	DROP TABLE #work_to_do;

end
GO

grant exec on dbo.mwReindex to public
GO
/*********************************************************************/
/* end sp_mwReindex.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwSimpleTourInfo.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwSimpleTourInfo]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwSimpleTourInfo]
GO

CREATE PROCEDURE [dbo].[mwSimpleTourInfo]
(
	--<VERSION>9.20</VERSION>
	--<DATA>30.07.2014</DATA>
	@roomKeys varchar(50), 
	@onlySpo smallint, 
	@priceFromTpTours smallint = 0, 
	@countryKey int = null, 
	@tourType int = null
)
as
begin
	declare @sql varchar(3000)

	if (@priceFromTpTours = 0)
	begin
		set @sql = '      
		select     pt_cnkey, cn_name, pt_ctkeyfrom, ct_name, pt_tourkey, pt_tourname, pt_toururl, pt_rate,
				   dbo.mwTop5TourDates(pt_cnkey, pt_tourkey, pt_tlkey, 0) as dates, 
				   dbo.mwTourHotelNights(pt_tourkey) as nights, min_price, CONVERT(varchar(10), pt_tourdate, 21) as pt_firsttourdate, pt_tourcreated, 			
				   tl_tip as tourtype, tl_dopdesc as note
		from 
		(
			  select max(pt_cnkey) pt_cnkey, max(pt_ctkeyfrom) pt_ctkeyfrom, pt_tourkey, max(pt_tourname) pt_tourname, max(pt_toururl) pt_toururl, max(pt_tlkey) pt_tlkey, max(pt_rate) pt_rate, min(pt_price) min_price, min(pt_tourdate) pt_tourdate, max(pt_tourcreated) pt_tourcreated
			  from dbo.mwPriceTable with(nolock)
			  where pt_main > 0 and pt_rmkey in (' + @roomKeys + ') and pt_tourdate >= getdate()
			  group by pt_tourkey
		 ) as prices
			  join tbl_turlist on tl_key = pt_tlkey
			  join dbo.Country on pt_cnkey = cn_key
			  join dbo.CityDictionary on pt_ctkeyfrom = ct_key
		where (' + ltrim(str(isnull(@onlySpo, 0))) + ' = 0 or exists(select 1 from tp_tours with(nolock) where (to_attribute & 1) > 0 and to_key = pt_tourkey))'

		if @countryKey is not null
			set @sql = @sql + ' and pt_cnkey = ' + ltrim(str(@countryKey))
		if @tourtype is not null
			set @sql = @sql + ' and tl_tip = ' + ltrim(str(@tourtype))
		set @sql = @sql + ' order by pt_tourcreated desc'
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
			to_key pt_tourkey,
			tl_tip as tourtype,
			tl_dopdesc as note
		from tp_tours
			left join tbl_turlist on tl_key = to_trkey
			left join dbo.Country on to_cnkey = cn_key
			left join dbo.CityDictionary on tl_ctdeparturekey = ct_key
		where TO_IsEnabled > 0 and TO_DateValid >= getdate() and (' + ltrim(str(isnull(@onlySpo, 0))) + ' = 0 or (to_attribute & 1) > 0 )'

		if @countryKey is not null
			set @sql = @sql + ' and to_cnkey = ' + ltrim(str(@countryKey))
		if @tourtype is not null
			set @sql = @sql + ' and tl_tip = ' + ltrim(str(@tourtype))
		set @sql = @sql + ' order by ct_name, cn_name, to_DateCreated'
	end

	exec(@sql)
end
GO

GRANT EXEC on [dbo].[mwSimpleTourInfo] to public
GO
/*********************************************************************/
/* end sp_mwSimpleTourInfo.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SpoListResults.sql */
/*********************************************************************/
--<VERSION>9.2.20.18</VERSION>
--<DATE>2014-07-25</DATE>

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPOListResults]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SPOListResults]
GO

CREATE PROCEDURE [dbo].[SPOListResults] 
( 
	@searchType varchar (10),
	@dateFrom DATETIME,
	@dateTo DATETIME,
	@top nvarchar(10),
	@cityFromKeyParam INT = 0,
	@countryKeyParam INT = 0,
	@resortKeyParam INT = 0,
	@cityKeyParam INT = 0,
	@hotelKeyParam INT = 0
)
AS

DECLARE @dateFromStr VARCHAR(10)
SET @dateFromStr = LEFT(CONVERT(VARCHAR, @dateFrom, 120), 10)

DECLARE @dateToStr VARCHAR(10)
SET @dateToStr = LEFT(CONVERT(VARCHAR, @dateTo, 120), 10)

DECLARE @filter VARCHAR(2048)
SET @filter = ''

IF @cityFromKeyParam > 0
	SET @filter += ' WHERE SD_CTKEYFROM = ' + ltrim(str(@cityFromKeyParam)) + ' '

IF @countryKeyParam > 0
BEGIN
	IF @filter = ''
		SET @filter += ' WHERE SD_CNKEY = ' + ltrim(str(@countryKeyParam)) + ' '
	ELSE 
		SET @filter += ' AND SD_CNKEY = ' + ltrim(str(@countryKeyParam)) + ' '
END

IF @resortKeyParam > 0
BEGIN
	IF @filter = ''
		SET @filter += ' WHERE SD_RSKEY = ' + ltrim(str(@resortKeyParam)) + ' '
	ELSE 
		SET @filter += ' AND SD_RSKEY = ' + ltrim(str(@resortKeyParam)) + ' '
END

IF @cityKeyParam > 0
BEGIN
	IF @filter = ''
		SET @filter += ' WHERE SD_CTKEY = ' + ltrim(str(@cityKeyParam)) + ' '
	ELSE 
		SET @filter += ' AND SD_CTKEY = ' + ltrim(str(@cityKeyParam)) + ' '
END

IF @hotelKeyParam > 0
BEGIN
	IF @filter = ''
		SET @filter += ' WHERE SD_HDKEY = ' + ltrim(str(@hotelKeyParam)) + ' '
	ELSE 
		SET @filter += ' AND SD_HDKEY = ' + ltrim(str(@hotelKeyParam)) + ' '
END

IF @filter = ''
	SET @filter += ' WHERE exists (select td_date from tp_turdates where td_tokey=sd_tourkey and td_DATE >= ''' + @dateFromStr + ''' and td_DATE <= ''' + @dateToStr + ''') '  
ELSE 
	SET @filter += ' AND exists (select td_date from tp_turdates where td_tokey=sd_tourkey and td_DATE >= ''' + @dateFromStr + ''' and td_DATE <= ''' + @dateToStr + ''') '

IF (@searchType = 'SPO')
	BEGIN
		IF @filter = ''
			SET @filter += ' WHERE SD_TOURKEY IN (SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE (TO_ATTRIBUTE & 1) > 0) '
		ELSE
			SET @filter += ' AND SD_TOURKEY IN (SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE (TO_ATTRIBUTE & 1) > 0) '
	END
ELSE IF (@searchType = 'Leader')
	BEGIN
		IF @filter = ''
			SET @filter += ' WHERE SD_TOURKEY IN (SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE (TO_ATTRIBUTE & 2) > 0) '
		ELSE
			SET @filter += ' AND SD_TOURKEY IN (SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE (TO_ATTRIBUTE & 2) > 0) '
	END
ELSE
	BEGIN
		IF @filter = ''
			SET @filter += ' WHERE SD_TOURKEY IN (SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE (TO_ATTRIBUTE & 3) > 0) '
		ELSE
			SET @filter += ' AND SD_TOURKEY IN (SELECT TO_KEY FROM TP_TOURS WITH(NOLOCK) WHERE (TO_ATTRIBUTE & 3) > 0) '
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
	[tourListKey] int,
	[minTourPrice] decimal,	-- минимальная цена тура
	[Rate] varchar(3)		-- валюта цены тура
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

SELECT distinct top ' + @top + ' sd_tourkey, SD_TOURCREATED into #tempSpoTable from MWSPoDataTable ' + @filter + ' ORDER BY SD_TOURCREATED DESC 

DECLARE SPO_Cursor CURSOR FOR
SELECT SD_TOURCREATED, SD_TOURKEY, SD_HDKEY, td_date, SD_RSKEY, SD_CTKEY, SD_CNKEY, SD_TLKEY
FROM MWSPoDataTable inner join tp_turdates on (sd_tourkey = td_tokey)
WHERE sd_tourkey in (select sd_tourkey from  #tempSpoTable) ORDER BY sd_CNKEY,sd_tourkey, sd_hdkey, sd_rskey

OPEN SPO_Cursor

if (@@CURSOR_ROWS > 0)
Begin'	
	set @command = replace(@command, '	', '')
		
	set @command = @command + '
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
			set @rsName = ''''						

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
						if @resortKey > 0 and len(@resorts) > 0 and @resorts != ''нет''
							set @resorts = @resorts + '',''
						if @resorts != ''нет''
							SET @resorts = @resorts + @rsName
						else
							SET @resorts = @rsName
					END
			END

		END'	
	set @command = replace(@command, '	', '')
		
	set @command = @command + '
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

	Set @lastResortKey = @resortkey
		
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
		WHERE td_tokey = @lastTourkey AND td_date >= ''' + @dateFromStr + ''' AND td_date <= ''' + @dateToStr + ''' ORDER BY td_date
		
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
		DEALLOCATE SPODate_Cursor'	
	set @command = replace(@command, '	', '')
		
	set @command = @command + '

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

		if len(@resorts) = 0 
			set @resorts = ''нет'' 

		INSERT #resultsTable 
					([createdate] ,
					[tourname],
					[tourhttp],
					[resort],
					[city],
					[hotels],
					[tourdates],
					[countryName],
					[countryNameLat],
					[countryKey],
					[tourKey],
					[tourListKey])
		Values (@lastCreateDate, @tourName, @tourHttp, @resorts, @cities, @hotelNames, @tourDates, @countryName, @countryNameLat, @lastCountrykey,  @lastTourkey, @lastTourListKey)
		
		if (@exit = 1)
			BREAK
		
		if @lastResortKey = 0
			begin 
				set @resorts = ''''
				set @resortKeys = ''''
			end

		SELECT @hdName = (isnull (HD_NAME,'''') + '' '' + ltrim(rtrim(isnull(HD_STARS,'''')))), @hdUrl = isnull (HD_HTTP,'''') from hoteldictionary where HD_KEY = @hotelkey
		SET @hotelNames = @hdName + ''|'' + @hdUrl
		if (@resortkey is not NULL and @resortkey != 0)
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

		SET @lastResortKey = @resortkey
	
	END'	
	set @command = replace(@command, '	', '')
		
	set @command = @command + '
	
	SET @lastTourkey = @tourkey
	
	FETCH NEXT FROM SPO_Cursor INTO @createdate, @tourkey, @hotelkey, @tourdate, @resortkey, @citykey, @countrykey, @tourlistkey
END
end

CLOSE SPO_Cursor
DEALLOCATE SPO_Cursor

update #resultsTable 
set [minTourPrice] = TO_MinPrice,
[Rate] = TO_Rate
from tp_tours r
where r.to_key = [tourKey]

SELECT * FROM #resultsTable order by [countryName],[createdate]
DROP TABLE #tempSpoTable
DROP TABLE  #resultsTable'

EXEC(@command)

GO

GRANT EXEC ON SPOListResults TO PUBLIC 

go
/*********************************************************************/
/* end sp_SpoListResults.sql */
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
-- =====================   Обновление версии БД. 9.2.20.19 - номер версии, 2014-08-08 - дата версии ===================== 
BEGIN TRY
	DECLARE @SUSER_NAME nvarchar(128) = (SELECT SUSER_NAME())
	DECLARE @HOST_NAME nvarchar(128) = (SELECT HOST_NAME())	

	UPDATE [dbo].[SETTING] 
	SET st_version = '9.2.20.19', st_moduledate = convert(datetime, '2014-08-08', 120),  st_financeversion = '9.2.20.19', st_financedate = convert(datetime, '2014-08-08', 120)
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
	SET SS_ParmValue='2014-08-08' WHERE SS_ParmName='SYSScriptDate'
END TRY
BEGIN CATCH
	DECLARE @ERROR_MESSAGE nvarchar(500) = (SELECT ERROR_MESSAGE())	
	INSERT INTO ScriptsSetupLogs(RC_Creator, RC_Text, RC_Status, RC_Computer, RC_LOG) VALUES(@SUSER_NAME, 'Ошибка при обновлении даты прогона релизного скрипта', 'ERR', @HOST_NAME, @ERROR_MESSAGE)
END CATCH
GO