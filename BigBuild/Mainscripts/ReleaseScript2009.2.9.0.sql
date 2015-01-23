set nocount on
-- 081114(alter_TurList).sql
-- Increase size of column 'TL_DESCRIPTION ' to 1024 characters
if (select [length] from dbo.syscolumns where name = 'TL_DESCRIPTION' and id = OBJECT_ID('tbl_TurList')) < 1024
alter table tbl_Turlist alter column TL_DESCRIPTION varchar(1024) null
GO

-- 101019(AlterTables_HotelTypes).sql
-- add column HTT_CssClass
if not exists (select 1 from dbo.syscolumns where id = object_id(N'[dbo].[HotelTypes]') and name = 'HTT_CssClass')
	alter table [dbo].[HotelTypes] add HTT_CssClass varchar(30) 
GO


-- 101027 alter dg_mainmen.sql
ALTER TABLE dbo.tbl_Dogovor ALTER COLUMN DG_MAINMEN varchar(70)
GO


-- 20101029_Alter_Profiles.sql
if not exists (select * from syscolumns where name like '%PF_Plugin%' and id = OBJECT_ID('Profiles'))
ALTER TABLE dbo.Profiles 
ADD PF_Plugin smallint NOT NULL CONSTRAINT DF_Profiles_PF_Plugin DEFAULT 0
GO

if not exists (select * from syscolumns where name like '%PF_XSKey%' and id = OBJECT_ID('Profiles'))
ALTER TABLE dbo.Profiles 
ADD PF_XSKey int NULL
GO


-- 031110_AlterTable_CalculatingPriceLists.sql
if exists (select * from dbo.syscolumns where name = 'CP_PriceList2006' and id = object_id(N'[dbo].[CalculatingPriceLists]'))
	ALTER TABLE dbo.CalculatingPriceLists drop column CP_PriceList2006
GO

if exists (select * from dbo.syscolumns where name = 'CP_PLNotDeleted' and id = object_id(N'[dbo].[CalculatingPriceLists]'))
	ALTER TABLE dbo.CalculatingPriceLists drop column CP_PLNotDeleted
GO

-- 101105_AlterTableApprovedPrintDocuments.sql
IF NOT EXISTS(SELECT * FROM dbo.syscolumns WHERE id = object_id(N'[dbo].[ApprovedPrintDocuments]') and name = 'AD_Type')
	ALTER TABLE [dbo].[ApprovedPrintDocuments] ADD [AD_Type] smallint not null default(0)
GO

-- 091110_AlterTable_TPFlights.sql
IF NOT EXISTS(SELECT 1 FROM dbo.syscolumns WHERE id = object_id(N'[dbo].[tp_flights]') and name = 'tf_days')
	ALTER TABLE [dbo].[tp_flights] ADD [tf_days] int null
GO

-- 101110_Insert_ObjectAliases.sql
IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 33))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(33, 'GenerateStartCode', 'Скрипт при старте', 0)
GO

IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 33001))
	insert into [dbo].[ObjectAliases] 
	(OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID)
	VALUES(33001, 'SP_CheckQuotes', 'Проверка квот', 0)
GO

-- 101110(Alter_DS_Priority).sql
if not exists (select 1 from dbo.syscolumns where id = object_id(N'[dbo].[Discounts]') and name = 'DS_Priority')
ALTER TABLE dbo.Discounts ADD
	DS_Priority int NOT NULL CONSTRAINT DF_Discounts_DS_Priority DEFAULT 0
GO

-- (101116)Insert_SystemSettings.sql
if not exists (select 1 from dbo.SystemSettings where SS_ParmName = 'CartAccmdMenTypeView')
insert into dbo.SystemSettings (SS_ParmName, SS_ParmValue)
values ('CartAccmdMenTypeView', 0)
GO

-- 101117(CreateTable_FileHeadersSettings).sql
IF not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FileHeadersSettings]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	CREATE TABLE [dbo].[FileHeadersSettings](
		[FS_Key] [int] IDENTITY(1,1) NOT NULL,
		[FS_FHID] [int] NOT NULL,
		[FS_Value] [text] NOT NULL,
		[FS_SettingTypeKey] [int] NOT NULL,
	 CONSTRAINT [PK_FileHeadersSettings] PRIMARY KEY CLUSTERED 
	([FS_Key] ASC))

	ALTER TABLE [dbo].[FileHeadersSettings]  WITH CHECK ADD  CONSTRAINT [FK_FileHeadersSettings_FileHeaders] FOREIGN KEY([FS_FHID])
	REFERENCES [dbo].[FileHeaders] ([FH_ID])
	ON UPDATE CASCADE
	ON DELETE CASCADE

	ALTER TABLE [dbo].[FileHeadersSettings] CHECK CONSTRAINT [FK_FileHeadersSettings_FileHeaders]
END
GO

grant select, insert, update, delete on [dbo].[FileHeadersSettings] to public
GO

-- (26112010)InsertIntoObjectAliases.sql
if ((select COUNT(*) from ObjectAliases where OA_Id in (11009)) = 0)
insert into ObjectAliases (OA_Id,OA_Alias,OA_Name,OA_TABLEID) values (11009,'','Запуск CalculatePiceList',0)

if ((select COUNT(*) from ObjectAliases where OA_Id in (11010)) = 0)
insert into ObjectAliases (OA_Id,OA_Alias,OA_Name,OA_TABLEID) values (11010,'','Завершение CalculatePiceList',0)

if ((select COUNT(*) from ObjectAliases where OA_Id in (11011)) = 0)
insert into ObjectAliases (OA_Id,OA_Alias,OA_Name,OA_TABLEID) values (11011,'','Кол-во рассчитанных цен',0)

if ((select COUNT(*) from ObjectAliases where OA_Id in (11012)) = 0)
insert into ObjectAliases (OA_Id,OA_Alias,OA_Name,OA_TABLEID) values (11012,'','Скорость расчета цен',0)
GO

-- 101130(INSERT_ACTIONS_AllowFilesForTour).sql
IF NOT EXISTS (SELECT * FROM Actions WHERE AC_Key = 73)
	INSERT INTO Actions (AC_Key, AC_Name, AC_NameLat)
		 VALUES (73, 'Разрешить работу с надстройкой "Файлы по туру"', 'Allow to work with the plugin "Files for tour"')
GO


-- 101219_AlterTable_QuotaParts.sql
if not exists(select id from syscolumns where id = OBJECT_ID('QuotaParts') and name = 'QP_Date')
     alter TABLE [dbo].[QuotaParts] add [QP_Date] smalldatetime NULL
GO

update [dbo].[QuotaParts]
set QP_Date = QD_Date
from [dbo].[QuotaDetails]
where QD_ID = QP_QDID
GO

-- 101219_CreateIndexes_QDQPQL.sql
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


-- 101223_AlterTable_UserList.sql
if not exists(select id from syscolumns where id = OBJECT_ID('UserList') and name = 'US_PassExpireTime')
	alter table UserList add US_PassExpireTime smallint null
go

if not exists(select id from syscolumns where id = OBJECT_ID('UserList') and name = 'US_LastPassChange')
	alter table UserList add US_LastPassChange DateTime null
go

if not exists(select id from syscolumns where id = OBJECT_ID('UserList') and name = 'US_PassMinLength')
	alter table UserList add US_PassMinLength smallint null
go

-- 21122010_AlterTables_Ank.sql
if not exists(select id from syscolumns where id = OBJECT_ID('Ank_Country') and name = 'AC_Comment')
	alter table dbo.Ank_Country add AC_Comment varchar(256) null
go

if not exists(select id from syscolumns where id = OBJECT_ID('Ank_Country') and name = 'AC_Required')
	alter table dbo.Ank_Country add AC_Required smallint not null default 0
go

if not exists(select id from syscolumns where id = OBJECT_ID('Ank_Country') and name = 'AC_XMLTag')
	alter table dbo.Ank_Country add AC_XMLTag varchar(100) null
go

if not exists(select id from syscolumns where id = OBJECT_ID('Ank_Country') and name = 'AC_Description')
	alter table dbo.Ank_Country add AC_Description varchar(256) null
go

if not exists(select id from syscolumns where id = OBJECT_ID('Ank_Country') and name = 'AC_Format')
	alter table dbo.Ank_Country add AC_Format varchar(256) null
go


if not exists(select * from dbo.sysobjects where id = OBJECT_ID(N'[dbo].[VisaDocumentContents]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	CREATE TABLE [dbo].[VisaDocumentContents](
		[VC_ID] [int] IDENTITY(1,1) NOT NULL,
		[VC_TUKEY] [int] NOT NULL,
		[VC_VDID] [int] NOT NULL,
		[VC_Contents] [image] NULL,
	) ON [PRIMARY]
GO

if not exists(select id from syscolumns where id = OBJECT_ID('VisaDocuments') and name = 'VD_Type')
	alter table dbo.VisaDocuments add VD_Type smallint not null default 0
go

-- 21122010_AlterTable_AnkCases.sql
if not exists(select id from syscolumns where id = OBJECT_ID('Ank_Cases') and name = 'AC_Type')
	alter table dbo.Ank_Cases add AC_Type int null default 0 with values
go

-- 110120_Delete_UserSettings.sql
delete UserSettings WHERE ST_PARMNAME = 'ServiceListForm.dataGridView'
GO

-- 101203(AddConstraint_InsPolicy_IP_PolicyNumber_UNIQUE).sql
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InsPolicy_IP_PolicyNumber_UNIQUE]') AND xtype = 'UQ')
begin
if not exists (select IP_PolicyNumber from [dbo].[InsPolicy] group by IP_PolicyNumber having count(IP_PolicyNumber) > 1)
	ALTER TABLE [dbo].[InsPolicy] ADD CONSTRAINT InsPolicy_IP_PolicyNumber_UNIQUE UNIQUE(IP_PolicyNumber)
end
GO

-- 110124_Index_InsPolicy.sql
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[InsPolicy]') AND name = N'x_IP_Object')
DROP INDEX [x_IP_Object] ON [dbo].[InsPolicy] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_IP_Object] ON [dbo].[InsPolicy] 
(
	[IP_DLKey] ASC
)
INCLUDE ( [IP_ARKEY],
[IP_AnnulDate]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

-- 110203_Create_Table_QuotaStatuses.sql
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_QuotaStatuses_Controls]') AND parent_object_id = OBJECT_ID(N'[dbo].[QuotaStatuses]'))
ALTER TABLE [dbo].[QuotaStatuses] DROP CONSTRAINT [FK_QuotaStatuses_Controls]
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_QuotaStatuses_Quotas]') AND parent_object_id = OBJECT_ID(N'[dbo].[QuotaStatuses]'))
ALTER TABLE [dbo].[QuotaStatuses] DROP CONSTRAINT [FK_QuotaStatuses_Quotas]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotaStatuses]') AND type in (N'U'))
DROP TABLE [dbo].[QuotaStatuses]
GO
CREATE TABLE [dbo].[QuotaStatuses](
	[QS_ID] [int] IDENTITY(1,1) NOT NULL,
	[QS_QTID] [int] NOT NULL,
	[QS_Type] [int] NOT NULL,
	[QS_CRKey] [int] NOT NULL,
 CONSTRAINT [PK_QuotaStatuses] PRIMARY KEY CLUSTERED 
(
	[QS_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[QuotaStatuses]  WITH CHECK ADD  CONSTRAINT [FK_QuotaStatuses_Controls] FOREIGN KEY([QS_CRKey])
REFERENCES [dbo].[Controls] ([CR_KEY])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QuotaStatuses] CHECK CONSTRAINT [FK_QuotaStatuses_Controls]
GO
ALTER TABLE [dbo].[QuotaStatuses]  WITH CHECK ADD  CONSTRAINT [FK_QuotaStatuses_Quotas] FOREIGN KEY([QS_QTID])
REFERENCES [dbo].[Quotas] ([QT_ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QuotaStatuses] CHECK CONSTRAINT [FK_QuotaStatuses_Quotas]
GO
GRANT select, insert, update, delete on [dbo].[QuotaStatuses] to public
GO



-- 1010228(CreateIndex_tp_servicelist).sql
IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_tp_servicelist_1')
     DROP INDEX TP_ServiceLists.x_tp_servicelist_1
GO
CREATE NONCLUSTERED INDEX [x_tp_servicelist_1]
	ON [dbo].[TP_ServiceLists] ([TL_TIKey])
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_tp_servicelist_2')
     DROP INDEX TP_ServiceLists.x_tp_servicelist_2
GO
CREATE NONCLUSTERED INDEX [x_tp_servicelist_2]
	ON [dbo].[TP_ServiceLists] ([TL_TOKey])
	INCLUDE ([TL_TSKey],[TL_TIKey])
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_tp_services_1')
     DROP INDEX TP_Services.x_tp_services_1
GO
CREATE NONCLUSTERED INDEX [x_tp_services_1]
	ON [dbo].[TP_Services] ([TS_TOKey],[TS_SVKey])
	INCLUDE ([TS_Key],[TS_Code],[TS_SubCode1],[TS_SubCode2],[TS_CTKey],[TS_Day],[TS_OpPartnerKey],[TS_OpPacketKey])
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_tp_services_2')
     DROP INDEX TP_Services.x_tp_services_2
GO
CREATE NONCLUSTERED INDEX [x_tp_services_2]
	ON [dbo].[TP_Services] ([TS_Key],[TS_SVKey])
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_tp_lists_2')
     DROP INDEX TP_Lists.x_tp_lists_2
GO
CREATE NONCLUSTERED INDEX [x_tp_lists_2]
	ON [dbo].[TP_Lists] ([TI_TOKey])
	INCLUDE ([TI_Key],[TI_DAYS])
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_tp_services_3')
     DROP INDEX TP_Services.x_tp_services_3
GO
CREATE NONCLUSTERED INDEX [x_tp_services_3]
	ON [dbo].[TP_Services] ([TS_SVKey])
	INCLUDE ([TS_Key],[TS_Code],[TS_SubCode1],[TS_SubCode2],[TS_CTKey],[TS_Day],[TS_OpPartnerKey],[TS_OpPacketKey])
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_tp_flights1')
     DROP INDEX TP_Flights.x_tp_flights1
GO
CREATE NONCLUSTERED INDEX [x_tp_flights1]
	ON [dbo].[TP_Flights] (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days)
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'tp_servicelist_3')
     DROP INDEX TP_ServiceLists.tp_servicelist_3
GO
CREATE NONCLUSTERED INDEX [tp_servicelist_3]
	ON [dbo].[TP_ServiceLists] ([TL_TSKey])
	INCLUDE ([TL_TIKey])
GO

-- 110302_Create_View_IndexUseView.sql
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[IndexUseView]') and xtype like N'%V%')
DROP VIEW [dbo].[IndexUseView]
GO

-- nkharitonov 2011-02-03
-- В представлениях невозможно использовать ORDER BY, поэтому в начале с помощью TOP 100 PERCENT сортируем всю выборку внутри селекта. 
-- Для корректной работы необходимо наличие kb926292 или kb956717, для разных версий серверов. 
-- Поэтому гарантировать вывод по полю USED по убыванию в общем случае нельзя, лучше сортировать представление принудительно.

CREATE VIEW [dbo].[IndexUseView] AS
	SELECT top 100 percent o.name AS TABLE_NAME, i.name AS INDEX_NAME , si.used AS USED, us.user_seeks,
	us.user_scans,us.user_lookups ,us.user_updates ,us.last_user_seek,us.last_user_scan, 
	us.last_user_lookup ,us.last_user_update ,us.system_seeks ,us.system_scans ,
	us.system_lookups ,us.system_updates ,us.last_system_seek ,
	us.last_system_scan ,us.last_system_lookup ,us.last_system_update 
	FROM sys.allocation_units AS au
		JOIN sys.partitions AS p ON au.container_id = p.partition_id
		JOIN sys.objects AS o ON p.object_id = o.object_id
		JOIN sys.indexes AS i ON p.index_id = i.index_id AND i.object_id = p.object_id
		JOIN sysindexes AS si ON i.name = si.name
		JOIN sys.dm_db_index_usage_stats AS us ON i.object_id = us.object_id AND i.index_id = us.index_id
	WHERE o.name = 'mwPriceDataTable' AND us.database_id = DB_ID()
	ORDER BY USED DESC
GO




-- AlterTable_HotelDictionary.sql
if not exists(select id from syscolumns where id = OBJECT_ID('HotelDictionary') and name = 'HD_HTTPAdditional')
	alter table HotelDictionary add HD_HTTPAdditional nvarchar(254)
go

-- CreateTableDotNetWindowsInsertValues.sql
--------------------------
-- Create DotNetWindows Table
--------------------------
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA ='dbo' AND TABLE_NAME = 'DotNetWindows')
BEGIN
CREATE TABLE dbo.DotNetWindows
( 
	 WN_Key int NOT NULL identity(1,1)
	,WN_WindowName varchar(50) NOT NULL
	,WN_ExWindowName varchar(50) NOT NULL
	,WN_NameRus varchar(50) NOT NULL
	,WN_NameLat varchar(50) NOT NULL
	,CONSTRAINT PK_DotNetWindows PRIMARY KEY (WN_Key)
);
END
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.DotNetWindows TO PUBLIC
GO

if not exists (select 1 from dbo.DotNetWindows)
begin
	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('PaymentsForm','','Журнал учета движения денежных средств','Log-book of movement of money resources')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('PaymentDetailForm','','Платеж','Payment')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('FinReportForm','','Финансовые отчеты','Financial reports')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('BorderoForm','','Бордеро','Bordero')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('DogovorMainForm','','Туристы','Tourists')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('MasterService','','Мастер-Сервис','Master-Service')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('DictsMasterTourForm','AccountsTableStyle','Счета','Accounts')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('PolicyForm','','Оформление полиса','Registration of the policy')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('DictsInsuranceForm','InsFinReportsTableStyle','Список финансовых отчетов','Financial reports list')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('DictsInsuranceForm','InsPoliciesTableStyle','Список полисов','List of the policies')

	insert into DotNetWindows (WN_WindowName,WN_ExWindowName,WN_NameRus,WN_NameLat) 
	values ('DictsInsuranceForm','InsBorderoesTableStyle','Список бордеро','List of Bordereaus')
end
go

-- InsertIntoSystemSettingsForbAnnPayDogs.sql
if (select COUNT(*) from SystemSettings where SS_ParmName = 'SYSForbidAnnulPayedDogs') = 0
insert into SystemSettings (SS_ParmName,SS_ParmValue) values ('SYSForbidAnnulPayedDogs',0)
GO

-- sp_AutoQuotesPlaces.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AutoQuotesPlaces]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AutoQuotesPlaces]
GO


create PROCEDURE [dbo].[AutoQuotesPlaces]
	(
		@pSv_key int
		,@pCode int
		,@pSub_code1 int
		,@pSub_code2 int
		,@datestart smalldatetime
		,@dateend smalldatetime
	)
as
begin
	-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
					and dl_svkey = @pSv_key
					and dl_code = @pCode
					and ((@pSub_code1 = 0) or (dl_subcode1 = @pSub_code1))
					and ((@pSub_code2 = 0) or (dl_subcode2 = @pSub_code2))
					and exists (select 1 from [service] where SV_QUOTED = 1 and dl_svkey = sv_key)
					and DL_DateBeg between @datestart and @dateend
					and exists (select 1
								from QuotaDetails join QuotaObjects on QO_QTID = QD_QTID
								where QD_Date between DL_DateBeg and DL_DateEnd
								and QO_SVKey = DL_SVKey
								and (DL_SubCode1 = QO_SubCode1 OR QO_SubCode1 = 0)
								and (DL_SubCode2 = QO_SubCode2 OR QO_SubCode2 = 0)
								and isnull(QD_Busy, 0) < isnull(QD_Places, 0)
								and QD_IsDeleted is null
								and QD_Date > @datestart)
		-- and dl_cnkey=6221
		OPEN cur_DogovorList
		FETCH NEXT FROM cur_DogovorList
			INTO @DLKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey
		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- находим на скольких туристов еще не заведена квота
			SET @NeedPlacesForMen = ISNULL(@DLNMen, 0) - ISNULL((	SELECT count(SD_TUKey)
																	FROM ServiceByDate
																	WHERE SD_DLKey = @DLKey), 0)
			SET @From = CAST(@DLDateBeg as int)

			-- добавляем недостающих туристов			
			while(@NeedPlacesForMen > 0)
			BEGIN
				set @TUKey = null
				
				SELECT @TUKey = TU_TUKey
				FROM dbo.TuristService
				WHERE TU_DLKey = @DLKey
				and TU_TUKey not in (SELECT SD_TUKey
										FROM ServiceByDate
										WHERE SD_DLKey = @DLKey)
										
				INSERT INTO RoomPlaces(RP_RLID, RP_Type) values (0,0)
				
				set @RPID=SCOPE_IDENTITY()
				
				INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RPID, SD_TUKey)
				SELECT CAST((N1.NU_ID + @From - 1) as datetime), @DLKey, @RPID, @TUKey
				FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@DLDateEnd as int) - @From + 1

				set @NeedPlacesForMen = @NeedPlacesForMen - 1
			END
			
			SET @QuoteType=null
						
			--в этой хранимке будет выполнена попытка постановки услуги на квоту
			EXEC DogListToQuotas @DLKey,null,null,null,null,@DLDateBeg, @DLDateEnd,null,null
					
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
			and dl_svkey = @pSv_key
			and dl_code = @pCode
			and ((@pSub_code1 = 0) or (dl_subcode1 = @pSub_code1))
			and ((@pSub_code2 = 0) or (dl_subcode2 = @pSub_code2))
			and exists (select 1 from [service] where SV_QUOTED = 1 and dl_svkey = sv_key)
			and DL_DateBeg between @datestart and @dateend
			and exists (select 1
						from QuotaDetails join QuotaObjects on QO_QTID = QD_QTID
						where QD_Date between DL_DateBeg and DL_DateEnd
						and QO_SVKey = DL_SVKey
						and (DL_SubCode1 = QO_SubCode1 OR QO_SubCode1 = 0)
						and (DL_SubCode2 = QO_SubCode2 OR QO_SubCode2 = 0)
						and isnull(QD_Busy, 0) < isnull(QD_Places, 0)
						and QD_IsDeleted is null
						and QD_Date > @datestart)
	order by HR_Main desc, dl_key
OPEN cur_DogovorListhotel
FETCH NEXT FROM cur_DogovorListhotel
	INTO @DLKey, @DGKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey, @HRMain

WHILE @@FETCH_STATUS = 0
BEGIN
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
				
				-- находим на скольких туристов еще не заведена квота
			SET @NeedPlacesForMen = ISNULL(@DLNMen, 0) - ISNULL((	SELECT count(SD_TUKey)
																	FROM ServiceByDate
																	WHERE SD_DLKey = @DLKey), 0)
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
				
				
				set @TUKey = null
				-- найдем туристов без квоты
				SELECT @TUKey = TU_TUKey 
				FROM dbo.TuristService 
				WHERE TU_DLKey = @DLKey 
				and TU_TUKey not in (	SELECT SD_TUKey 
										FROM ServiceByDate
										WHERE SD_DLKey = @DLKey)
				
				INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_RPID, SD_TUKey)
					SELECT CAST((N1.NU_ID + @From - 1) as datetime), @DLKey, @RLID, @RPID, @TUKey
					FROM NUMBERS as N1 WHERE N1.NU_ID between 1 and CAST(@DLDateEnd as int) - @From + 1
				
				SET @NeedPlacesForMen = @NeedPlacesForMen - 1
				SET @RPID=@RPID+1

				End
		SET @QuoteType=null
		
		--в этой хранимке будет выполнена попытка постановки услуги на квоту
		EXEC DogListToQuotas @DLKey,null,null,null,null,@DLDateBeg, @DLDateEnd,null,null
		
	FETCH NEXT FROM cur_DogovorListhotel
		INTO @DLKey, @DGKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey, @HRMain

END

CLOSE cur_DogovorListhotel
DEALLOCATE cur_DogovorListhotel;

end
GO

GRANT EXECUTE ON [dbo].[AutoQuotesPlaces] TO PUBLIC 

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

declare @nUsed int
SET @nUsed = 0
if @sTableName='tbl_Partners' OR @sTableName='Partners'
begin
	IF OBJECT_ID('FIN_CHECKPARTNER') IS NOT NULL AND
		OBJECT_ID('FIN_CHANGEPARTNER') IS NOT NULL 
	BEGIN
		execute FIN_CHECKPARTNER @nKey, @nUsed OUTPUT
		if @nUsed = 1
			execute FIN_CHANGEPARTNER @nKey, @nNewKey
	END
end

SET @nUsed = 0
if @sTableName='UserList'
begin
	IF OBJECT_ID('FIN_CHECK_KEY') IS NOT NULL AND
		OBJECT_ID('FIN_CHANGE_KEY') IS NOT NULL
	BEGIN
		execute FIN_CHECK_KEY 'USERLIST', 'US_KEY', @nKey, @nUsed OUTPUT
		if @nUsed = 1
			exec FIN_CHANGE_KEY 'USERLIST', 'US_KEY', @nKey, @nNewKey
	END
end
GO

GRANT EXEC ON [dbo].[BeforeDeleteRow] TO PUBLIC
GO

-- sp_CheckDoubleDogovor.sql
if exists(select id from sysobjects where xtype='p' and name='CheckDoubleDogovor')
	drop proc dbo.CheckDoubleDogovor
go

create procedure [dbo].[CheckDoubleDogovor]  
	@TourDate varchar (12),
	@LastName varchar (25),
	@FirstName varchar (25),	
	@HotelKey int
AS
begin
	SET @LastName = REPLACE (@LastName,'''','')
	
	if (@HotelKey > 0)
		BEGIN
			SELECT TU_DGCOD, TU_KEY From dbo.tbl_turist where TU_TURDATE = @TourDate AND TU_NAMERUS = @LastName AND TU_FNAMERUS = @FirstName AND EXISTS (SELECT DG_KEY FROM dogovor WHERE DG_CODE = TU_DGCOD ) 
				AND EXISTS (SELECT DL_KEY FROM [dbo].[tbl_dogovorlist] WHERE DL_DGCOD = TU_DGCOD AND DL_SVKEY = 3 AND DL_CODE = @HotelKey)
		END
	else
		BEGIN
			SELECT TU_DGCOD, TU_KEY From [dbo].[tbl_turist] where TU_TURDATE = @TourDate AND TU_NAMERUS = @LastName AND TU_FNAMERUS = @FirstName AND EXISTS (SELECT DG_KEY FROM dogovor where DG_CODE = TU_DGCOD) 
		END  
end
go

grant exec on [dbo].[CheckDoubleDogovor] to public
go


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

select @nPaymentDetailsSum = ROUND(sum(PD_SumInDogovorRate),8), @nPaymentDetailsSumNational = ROUND(sum(PD_SumNational),8)
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



-- sp_GetPricePage.sql
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[sp_GetPricePage]') AND xtype in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetPricePage]
GO

CREATE PROCEDURE [dbo].[sp_GetPricePage]
     @TurKey   int,
     @MinID     int,
     @SizePage     int
AS
-- TourML
SET NOCOUNT ON
CREATE TABLE #tab ([ID] [int] IDENTITY (1, 1) NOT NULL, PriceID [int])
DECLARE @Query varchar(200)
set @Query = 'insert into #tab(PriceID) SELECT  TOP ' 
           + CAST(@SizePage AS VARCHAR(10)) 
           + ' TP_KEY  FROM TP_PRICES WHERE  TP_TOKEY = '
           + CAST(@TurKey AS VARCHAR(10)) 
           + ' and TP_KEY > '
           + CAST(@MinID AS VARCHAR(10))
           + ' ORDER BY TP_KEY'
exec (@Query)
--get output results
select TP_PRICES.* from TP_PRICES  inner join (select * from #tab) as Sub
on TP_PRICES.TP_KEY = Sub.PriceID order by TP_PRICES.TP_KEY 
-- Получаем все ServiceSet (варианты набора услуг).
select DISTINCT tbl.TP_TIKey from  (select TP_PRICES.* from TP_PRICES  inner join (select * from #tab) as Sub
on TP_PRICES.TP_KEY = Sub.PriceID) tbl
--Console.WriteLine("||  Получаем все связи услуг");
SELECT * 
FROM TP_SERVICELISTS 
WHERE  TL_TOKEY =  @TurKey and 
      TL_TIKEY in (select DISTINCT tbl.TP_TIKey 
				   from (select TP_PRICES.* 
					     from TP_PRICES  
                         inner join (select * from #tab) as Sub 
                         on TP_PRICES.TP_KEY = Sub.PriceID) as tbl)
order by TL_TIKEY 
DROP TABLE #tab
GO


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
		  , @PartnerUserName varchar(70)
		  , @PartnerUserPhone varchar(50)
		  , @PartnerUserPassport varchar(18)
		  , @MainManName varchar(70)
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
			SELECT @PartnerUserName = SUBSTRING(ISNULL(US_FULLNAME,''),1,70)
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

-- sp_UpdateReservationMainMan.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateReservationMainMan]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateReservationMainMan] 
GO

CREATE PROCEDURE [dbo].[UpdateReservationMainMan]
	@ManName varchar(70), 
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
	DECLARE @ManName varchar(70)
		  , @ManPhone varchar(50)
		  , @ManAddress varchar(320)
		  , @ManPassport varchar(70)
		  , @ManSName char(15);
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

-- sp_GetServiceList.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceList]
GO

CREATE procedure [dbo].[GetServiceList] 
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
	DG_Code nvarchar(max), DG_Key int, DG_DiscountSum money, DG_Price money, DG_Payed money,
	DG_PriceToPay money, DG_Rate nvarchar(3), DG_NMen int, PR_Name nvarchar(max), CR_Name nvarchar(max),
	DL_Key int, DL_NDays int, DL_NMen int, DL_Reserved int, DL_CTKeyTo int, DL_CTKeyFrom int, DL_CNKEYFROM int,
	DL_SubCode1 int, TL_Key int, TL_Name nvarchar(max), TUCount int, TU_NameRus nvarchar(max), TU_NameLat nvarchar(max),
	TU_FNameRus nvarchar(max), TU_FNameLat nvarchar(max), TU_Key int, TU_Sex Smallint, TU_PasportNum nvarchar(max),
	TU_PasportType nvarchar(max), TU_PasportDateEnd datetime, TU_BirthDay datetime, TU_Hotels nvarchar(max),
	Request smallint, Commitment smallint, Allotment smallint, Ok smallint, TicketNumber nvarchar(max),
	FlightDepDLKey int, FligthDepDate datetime, FlightDepNumber nvarchar(max), ServiceDescription nvarchar(max),
	ServiceDateBeg datetime, ServiceDateEnd datetime, RM_Name nvarchar(max), RC_Name nvarchar(max), SD_RLID int,
	TU_SNAMERUS nvarchar(max), TU_SNAMELAT nvarchar(max)
)
 
if @TypeOfRelult = 2
begin
	--- создаем таблицу в которой пронгумируем незаполненых туристов
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
	and exists (select 1 from ServiceByDate as SSD2 where SSD.SD_DLKey = SSD2.SD_DLKey and SSD2.SD_Date = @Date)

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
		TU_Sex, TU_PasportNum, TU_PasportType, TU_PasportDateEnd, TU_BirthDay, TicketNumber, TU_SNAMERUS, TU_SNAMELAT) 
		SELECT	  DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, 
		(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, 
		DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + '=3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END,
		DG_TRKey, 0, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS, TU_FNAMELAT, SD_TUKey, case when SD_TUKey > 0 then isnull(TU_SEX,0) else null end, TU_PASPORTTYPE + '' '' + TU_PASPORTNUM, TU_PASPORTTYPE, 
		TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, TU_SNAMERUS, TU_SNAMELAT
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
		SET @Query=@Query + ' 
		group by DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, DG_PDTTYPE, DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, DL_DateBeg,
		DL_DateEnd, DG_TRKey, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS,
		TU_FNAMELAT, SD_TUKey, TU_SEX, TU_PASPORTNUM, TU_PASPORTTYPE, TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, SD_RPID, TU_SNAMERUS, TU_SNAMELAT'
end
else
begin
	SET @Query = '
		INSERT INTO #Result (DG_Code, SD_RLID, RM_Name, RC_Name, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		DG_PriceToPay, DG_RATE, DG_NMEN,
		PR_NAME, CR_NAME, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKeyTo, DL_SubCode1,
		ServiceDateBeg, ServiceDateEnd, TL_Key, TUCount, DL_Key)
		select DG_CODE, SD_RLID, RM_Name, RC_Name, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		(case when DG_PDTTYPE = 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN,
		PR_NAME, CR_NAME, DL_NDays, case when QT_ByRoom = 1 then count(distinct SD_RLID) else count(distinct SD_RPID) end as DL_NMEN,
		DL_RESERVED, DL_CTKey, DL_SubCode2, DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + ' = 3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END, DG_TRKey, Count(distinct SD_TUKey), DL_KEY
		from ServiceByDate left join RoomNumberLists on sd_rlid = rl_id
		left join Rooms on rl_rmkey = rm_key
		left join RoomsCategory on rl_rckey = rc_key
		join QuotaParts on sd_qpid = qp_id
		join QuotaDetails on QP_QDID = QD_ID
		join Quotas on QT_ID = QD_QTID
		join Dogovorlist on sd_dlkey = dl_key
		join Controls on dl_control = cr_key
		left join Partners on dl_agent = pr_key
		join Dogovor on dl_dGKEY = DG_KEY
		left join Turistservice on tu_dlkey=dl_key
		where DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' AND DL_CODE in (' + @Codes + ') AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND'
		
	if @QDID is not null
		SET @Query = @Query + ' and qp_qdid = ' + CAST(@QDID as nvarchar(max))
	if @QPID is not null
		SET @Query = @Query + ' and qp_id = ' + CAST(@QPID as nvarchar(max))
	
	SET @Query = @Query + '
		group by DG_CODE, SD_RLID, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		DG_PDTTYPE, DG_PRICE, DG_DISCOUNTSUM, DG_PRICE, DG_RATE, DG_NMEN,
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
	DM_MessageCount int,
	DM_AnnulReason varchar(60),
	DM_AnnulDate datetime,
	DM_PriceToPay money,
	DM_Payed money
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
				(HD_OAId = ' + str(@nObjectAliasFilter) + ') and
				(''' + @sFilterType + '''= '''' OR HI_MOD = ''' + @sFilterType + ''') and
				(' + str(@nFilialKey) + ' < 0 OR DG_FILIALKEY = ' + str(@nFilialKey) + ') and
				(AR_Key = DG_ARKEY)'
		
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
						VALUES (@dogovorCreateDate, @firstDogovorProcessDate, @lastDogovorProcessDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @sFilterName, @notesCount, @sPaymentStatus, @isBilled, @messageCount, @AnnulReason, @AnnulDate, @PriceToPay, @Payed);
					END
				END
				-------------------

			--end
			fetch next from dogovorsCursor into @dogovorCreateDate, @lastDogovorActionDate, @sDGCode, @sCreator, @dtTurDate, @sTurName, @sPartnerName, @nDGKey, @sPaymentStatus, @AnnulReason, @PriceToPay, @Payed
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

-- sp_GetQuotaLoadListData_N.sql
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
		set @QO_SubCode2 = -1
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
		FROM	Quotas join QuotaObjects on QO_QTID = QT_ID
				join QuotaDetails on QD_QTID = QT_ID
		WHERE QD_Date between @DateStart and @DateEnd
		and QO_SVKey = @DL_SVKey 
		and QO_Code = @DL_Code
END

		--AleXK добавил чтобы есл есть квота на SST_SubCode1 = все, то создавалиь бы все квоты по признакам
		insert into #StopSaleTemp_Local (SST_Code,SST_SubCode1,SST_SubCode2,SST_QOID,SST_PRKey,SST_Date,SST_QDID,SST_Type)
		select QO_Code, QO_SubCode1, QO_SubCode2, QO_ID, SS_PRKey, SS_Date, SST_QDID, SST_Type
		from QuotaObjects join StopSales on QO_ID = SS_QOID
		join #StopSaleTemp_Local on QO_Code = SST_Code and QO_SubCode2 = SST_SubCode2 and SS_PRKey = SST_PRKey and SS_Date = SST_Date
		where not exists (select 1 from #StopSaleTemp_Local where SST_QOID = QO_ID)
		and SST_SubCode1 = 0
		
		--AleXK добавил чтобы есл есть квота на SST_SubCode2 = все, то создавалиь бы все квоты по признакам
		insert into #StopSaleTemp_Local (SST_Code,SST_SubCode1,SST_SubCode2,SST_QOID,SST_PRKey,SST_Date,SST_QDID,SST_Type)
		select QO_Code, QO_SubCode1, QO_SubCode2, QO_ID, SS_PRKey, SS_Date, SST_QDID, SST_Type
		from QuotaObjects join StopSales on QO_ID = SS_QOID
		join #StopSaleTemp_Local on QO_Code = SST_Code and QO_SubCode1 = SST_SubCode1 and SS_PRKey = SST_PRKey and SS_Date = SST_Date
		where not exists (select 1 from #StopSaleTemp_Local where SST_QOID = QO_ID)
		and SST_SubCode2 = 0
		
		--AleXK добавил чтобы есл есть квота на SST_SubCode1 = все и SST_SubCode2 = все, то создавалиь бы все квоты по признакам
		insert into #StopSaleTemp_Local (SST_Code,SST_SubCode1,SST_SubCode2,SST_QOID,SST_PRKey,SST_Date,SST_QDID,SST_Type)
		select QO_Code, QO_SubCode1, QO_SubCode2, QO_ID, SS_PRKey, SS_Date, SST_QDID, SST_Type
		from QuotaObjects join StopSales on QO_ID = SS_QOID
		join #StopSaleTemp_Local on QO_Code = SST_Code and SS_PRKey = SST_PRKey and SS_Date = SST_Date
		where not exists (select 1 from #StopSaleTemp_Local where SST_QOID = QO_ID)
		and SST_SubCode1 = 0 and SST_SubCode2 = 0

--if exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSCheckQuotaRelease' and SS_ParmValue=1) OR exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSAddQuotaPastPermit' and SS_ParmValue=1)
BEGIN
	-- оборобатываем стопы которые висят на QuotaDetails
	IF @DL_Key is not null --значит по услуге, значит не надо смотреть в QuotaObjects, так как объекты уже отобраны
	begin
		Update #StopSaleTemp_Local Set SST_State=1, SST_Comment= (SELECT TOP 1 REPLACE(SS_Comment,'''','"') FROM StopSales,QuotaObjects WHERE SS_QOID=QO_ID and SS_QDID=SST_QDID and QO_Code=@DL_Code and SS_Date between @DateStart and @DateEnd and (SS_IsDeleted is null or SS_IsDeleted=0)
				and (QO_SubCode1=SST_SubCode1 or QO_SubCode1=0)	and (QO_SubCode2=SST_SubCode2 or QO_SubCode2=0))
			WHERE exists (SELECT SS_ID FROM StopSales,QuotaObjects WHERE SS_QOID=QO_ID and SS_QDID=SST_QDID and QO_Code=@DL_Code and SS_Date between @DateStart and @DateEnd and (SS_IsDeleted is null or SS_IsDeleted=0)
				and (QO_SubCode1=SST_SubCode1 or QO_SubCode1=0)	and (QO_SubCode2=SST_SubCode2 or QO_SubCode2=0))
	end
	Else
	begin
		Update #StopSaleTemp_Local
		Set SST_State=1, SST_Comment = (SELECT TOP 1 REPLACE(SS_Comment,'''','"') 
										FROM StopSales 
										WHERE SS_QDID = SST_QDID 
										and SS_QOID = SST_QOID 
										and SS_Date between @DateStart and @DateEnd 
										and isnull(SS_IsDeleted, 0) = 0)
		WHERE exists (SELECT SS_ID 
						FROM StopSales 
						WHERE SS_QDID = SST_QDID 
						and SS_QOID = SST_QOID 
						and SS_Date between @DateStart and @DateEnd 
						and isnull(SS_IsDeleted, 0) = 0)
	end
		
	-- обрабатывались так же стопы которые висят не на QuotaDetails
	Update #StopSaleTemp_Local Set SST_State = 2, SST_Comment = 
		(
			SELECT TOP 1 REPLACE(SS_Comment,'''','"') 
			FROM StopSales,QuotaObjects
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
		WHERE exists ( SELECT 1
						FROM QuotaObjects join StopSales on QO_ID = SS_QOID
						WHERE SS_QDID is null
						and SS_Date between @DateStart and @DateEnd
						and (SS_PRKey = SST_PRKey or SS_PRKey = 0)
						and SS_Date = SST_Date
						and (QO_Code = SST_Code or QO_Code=0)
						and (QO_SubCode1 = SST_SubCode1 or QO_SubCode1 = 0)
						and (QO_SubCode2 = SST_SubCode2 or QO_SubCode2 = 0)
						and isnull(SS_IsDeleted, 0) = 0
						and (SST_Type = 1 or isnull(SS_AllotmentAndCommitment,0) = 1)
					)
END
 --where sst_QDID=2602
--GO
--проверка стопов
--окончание
if @GroupByQD=1
	select	SST_QDID, Count(*) as SST_QO_Count, 
			(SELECT count(*) from #StopSaleTemp_Local s2 WHERE s2.SST_QDID = s1.SST_QDID and SST_State is not null) as SST_QO_CountWithStop,
			(SELECT TOP 1 SST_Comment FROM #StopSaleTemp_Local s3 WHERE s3.SST_QDID=s1.SST_QDID and SST_Comment is not null and SST_Comment != '') as SST_Comment
	from #StopSaleTemp_Local s1
	group by SST_QDID	
	having (SELECT count(*) from #StopSaleTemp_Local s2 WHERE s2.SST_QDID = s1.SST_QDID and SST_State is not null) > 0
else
	select * from #StopSaleTemp_Local
GO
GRANT EXECUTE ON [dbo].[GetTableQuotaDetails] TO PUBLIC 
GO

-- sp_GetSvCode1Name.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSvCode1Name]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure [dbo].[GetSvCode1Name]
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
		If @nHrMain <= 0
		begin				
			SET @sName = @sName + ' доп(' + @sTmp + ')'
			SET @sNameLat = @sNameLat + ' ex(' + @sTmp + ')'
		END
		ELSE
			IF (@nAgeFrom > 0) or (@nAgeTo > 0)
			BEGIN
				print @sTmp
				SET @sName =  @sName + ' (' + @sTmp + ')'
				SET @sNameLat = @sNameLat + ' (' + @sTmp + ')'				
			END
	END
GO
GRANT EXECUTE ON [dbo].[GetSvCode1Name] TO PUBLIC
GO

-- sp_GetUniquePolicyNumber.sql

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_GetUniquePolicyNumber]') 
	and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sp_GetUniquePolicyNumber]
GO 

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_GetUniquePolicyNumber]
    ( @SettingKey int,
      @ReportKey int,
      @CurrentNumber int = 0 output)
AS

SET ARITHABORT ON

begin
 
begin tran

DECLARE @text nvarchar(MAX)
SElect @text = xs_value from xmlsettings WITH (UPDLOCK) where xs_key = @SettingKey

DECLARE @settingsXML xml
SET @settingsXML = @text

declare @NodeString nvarchar(100)
set @NodeString = '(/Report' + cast(@ReportKey as nvarchar(10)) + 'Settings/Numblank/text())[1]'

DECLARE @sql Nvarchar(100)
set @sql = 'SET @CurrentNumber = @settingsXML.value(''' + @NodeString + ''',''int'')'

EXEC sp_executesql @sql, N'@CurrentNumber int OUTPUT, @settingsXML xml output',
@currentnumber = @currentnumber output, @settingsXML = @settingsXML output; 

declare @NewNumber int
set @NewNumber = @CurrentNumber + 1

set @sql = 'SET @settingsXML.modify(''replace value of ' + @NodeString + 
' with ' + cast(@NewNumber as nvarchar(50)) + ''')'

EXEC sp_executesql @sql, N'@settingsXML xml OUTPUT',
@settingsXML = @settingsXML output; 

update xmlsettings set xs_value = cast(@settingsXML as nvarchar(max)) where xs_key = @SettingKey
 
commit tran

end

go

grant execute on sp_GetUniquePolicyNumber to public
go

SET QUOTED_IDENTIFIER OFF
GO

-- sp_RowHasChild.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RowHasChild]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[RowHasChild]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE procedure [dbo].[RowHasChild]
	@sTableName varchar(256),
	@nKey int,
	@nHasChild int output
AS

SET @nHasChild = 0
if @sTableName='tbl_Partners' OR @sTableName='Partners'
begin
	IF OBJECT_ID('FIN_CHECKPARTNER') IS NOT NULL AND
		OBJECT_ID('FIN_CHANGEPARTNER') IS NOT NULL 
	BEGIN
		execute FIN_CHECKPARTNER @nKey, @nHasChild OUTPUT
	END
end
SET @nHasChild = 0
if @sTableName='UserList'
begin
	IF OBJECT_ID('FIN_CHECK_KEY') IS NOT NULL
	BEGIN
		execute FIN_CHECK_KEY 'USERLIST', 'US_KEY', @nKey, @nHasChild OUTPUT
	END
end

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT EXEC ON [dbo].[RowHasChild] TO PUBLIC
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
				where tl_tikey = ti_key and ts_svkey = 3 and ts_tokey = @toKey and tl_tokey = @toKey)
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
					inner join dbo.tp_servicelists with (nolock) on tl_tskey = ts_key  and ts_tokey = @toKey and tl_tokey = @toKey
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
			where tl_tikey = ti_key and ts_tokey = @toKey and tl_tokey = @toKey and (ts_day <= tp_lists.ti_firsthotelday or (ts_day = 1 and tp_lists.ti_firsthotelday = 0)) and ts_subcode2 = @ctdeparturekey)
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

-- sp_GetPartnerCommission.sql
if EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[GetPartnerCommission]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[GetPartnerCommission]
GO

CREATE PROCEDURE [dbo].[GetPartnerCommission] 
     @nTLKey int,
     @nPRKey int,
     @nBTKey int,
     @nDSKey int output,
     @nValue money output,
     @nIsPercent int output, 
	 @dCheckinDate datetime,
	 @nCNKey int=0,
	 @DGCreateDate datetime = null,
	 @nDepartureCity int = 0,
	 @sDiscountCode varchar(5) = null,
	 @sDiscountNumber varchar(10) = null,
	 @price decimal(16,6) = null,
	 @rate varchar(3) = null,
	 @dogovorCode varchar(10) = null
AS
	declare @discountSettingValue varchar(256)
	select @discountSettingValue = ISNULL(SS_ParmValue, '0') from dbo.SystemSettings where SS_ParmName like 'SYSUseDiscountCards'
	if @discountSettingValue = '1' and ISNULL(@sDiscountCode, '') != '' and ISNULL(@sDiscountNumber, '') != ''
	begin
		
		declare @discountCode varchar(5)
		declare @discountNumber varchar(10)
		declare @reservationsCount int, @cardKey int
		declare @reservationsPrice decimal(16,6)
		declare @nationalRate varchar(3)
		declare @discount money
		declare @discountId int

		if (ISNULL(@dogovorCode, '') = '')
		begin
			set @sDiscountCode = rtrim(ltrim(@sDiscountCode))
			set @sDiscountNumber = rtrim(ltrim(@sDiscountNumber))
				
			select @cardKey = CD_Key from Cards where ISNULL(CD_Code, '') = ISNULL(@sDiscountCode, '') and ISNULL(CD_Number, '') = ISNULL(@sDiscountNumber, '')
			select @reservationsCount = count(RR_ID) from ReservationsRegister where RR_CardKey = @cardKey
			select @reservationsPrice = sum(DG_NationalCurrencyPrice) from Dogovor where DG_CODE in (select RR_DGCODE  COLLATE Cyrillic_General_CI_AS from ReservationsRegister where RR_CardKey = @cardKey)
			select @nationalRate = RA_Code from dbo.Rates where RA_National = 1
			exec ExchangeCost @price output, @rate, @nationalRate, @dCheckinDate

			set @reservationsPrice = ISNULL(@reservationsPrice, 0)
		
			select top 1 @discount = cast(ISNULL(DS_DISCOUNT, 0) as money), @discountId = DS_ID  
				from dbo.DiscountScheme, dbo.TurList, dbo.TurService where 
				TL_Key = @nTLKey and 
				TS_TRKey = TL_Key and
				DS_Series like @sDiscountCode and
				((DS_CityFromKey is not null and DS_CityFromKey = TL_CTDepartureKey) or (DS_CityFromKey is null)) and
				((DS_CountryKey is not null and DS_CountryKey = TL_CNKey) or (DS_CountryKey is null)) and
				((DS_CityKey is not null and DS_CityKey = TS_CTKey) or (DS_CityKey is null)) and
				((DS_TourTypeKey is not null and DS_TourTypeKey = TL_TIP) or (DS_TourTypeKey is null)) and
				((DS_ReservationsFrom is not null and DS_ReservationsFrom <= (@reservationsCount + 1)) or (DS_ReservationsFrom is null)) and
				((DS_ReservationsTo is not null and DS_ReservationsTo >= (@reservationsCount + 1)) or (DS_ReservationsTo is null)) and
				((DS_TotalCostFrom is not null and DS_TotalCostFrom <= (@reservationsPrice + @price)) or (DS_TotalCostFrom is null)) and
				((DS_TotalCostTo is not null and DS_TotalCostTo >= (@reservationsPrice + @price)) or (DS_TotalCostTo is null)) and
				((DS_MinPrice is not null and DS_MinPrice <= @price) or (DS_MinPrice is null))
			order by DS_ID DESC

			set @nDSKey = -1
			set @nValue = @discount
			set @nIsPercent = 1
			return 1
		end
		else
		begin
			
			select @discount = DD_DiscountPercent from dbo.DogovorDetails where DD_DGCODE like @dogovorCode
			set @discount = ISNULL(@discount, 0)
			set @nDSKey = -1
			set @nValue = @discount
			set @nIsPercent = 1
			return 1
		end
		
	end

     if @nPRKey = 0
     begin
          set @nDSKey = -1     
          set @nValue = 0     
          set @nIsPercent = 1     
		  return 0
     end

	declare @nPGKey int, @nTpKey int, @nAttr int, @nCTDepartureKey int
	set @nTpKey=0
	if 	@nPRKey>0
		select @nPGKey = PR_PGKey from Partners where PR_Key = @nPRKey
	else
		set @nPGKey=0
	if @nTLKey>0
		select @nCNKey = TL_CNKey, @nTpKey=TL_TIP, @nAttr = isnull(TL_Attribute, 0) 
		from TurList where TL_Key = @nTLKey

	declare @discountAction int
	set @discountAction = 0
	if @nAttr & 16 > 0
		set @discountAction = 1

	if @dCheckinDate is null
		SET @dCheckinDate=ISNULL(@dCheckinDate,GetDate())
     if @nBTKey = 0 or @nBTKey is null
     begin
          select @nDSKey = DS_Key, @nValue = DS_Value, @nIsPercent = DS_IsPercent from Discounts
          where DS_PRKey IN(0, @nPRKey) AND DS_BTKey IN (0, @nBTKey) AND DS_PGKey IN (0, @nPGKey) 
				AND DS_TLKey IN (0, @nTLKey) AND DS_CNKey IN (0, @nCNKey) AND DS_TPKEY IN (0,@nTpKey)
				AND @dCheckinDate between ISNULL(DS_CheckInFrom,'30-DEC-1899') and ISNULL(DS_CheckInTo,'30-DEC-2200')
				AND DATEDIFF(d, GetDate(), @dCheckinDate) <= ISNULL(DS_DaysBeforeCheckIn, 99999)
				AND ISNULL(@DGCreateDate, ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899')) between ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899') and ISNULL(DS_DogovorCreateDateTo,'30-DEC-2200')
				AND (CASE WHEN @discountAction = 0 THEN ISNULL(DS_DAKey, 0) ELSE 0 END) = 0
				AND DS_DepartureCityKey IN (0, @nDepartureCity)
          order by DS_Priority, DS_BTKey desc, DS_TLKey, DS_CNKey,DS_TPKEY, DS_PRKey, DS_PGKey, DS_DepartureCityKey, @dCheckinDate - ISNULL(DS_DaysBeforeCheckIn, 77777) asc, DS_DogovorCreateDateFrom asc, DS_DogovorCreateDateTo asc, DS_DAKey asc
     end
     else
     begin
          select @nDSKey = DS_Key, @nValue = DS_Value, @nIsPercent = DS_IsPercent from Discounts
          where DS_PRKey IN(0, @nPRKey) AND DS_BTKey IN (0, @nBTKey) AND DS_PGKey IN (0, @nPGKey) 
				AND DS_TLKey IN (0, @nTLKey) AND DS_CNKey IN (0, @nCNKey) AND DS_TPKEY IN (0,@nTpKey)
				AND @dCheckinDate between ISNULL(DS_CheckInFrom,'30-DEC-1899') and ISNULL(DS_CheckInTo,'30-DEC-2200')
				AND DATEDIFF(d, GetDate(), @dCheckinDate) <= ISNULL(DS_DaysBeforeCheckIn, 99999)
				AND ISNULL(@DGCreateDate, ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899')) between ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899') and ISNULL(DS_DogovorCreateDateTo,'30-DEC-2200')
				AND (CASE WHEN @discountAction = 0 THEN ISNULL(DS_DAKey, 0) ELSE 0 END) = 0
				AND DS_DepartureCityKey IN (0, @nDepartureCity)
          order by DS_Priority, DS_BTKey, DS_TLKey, DS_CNKey, DS_TPKEY,DS_PRKey, DS_PGKey, DS_DepartureCityKey, @dCheckinDate - ISNULL(DS_DaysBeforeCheckIn, 77777) asc, DS_DogovorCreateDateFrom asc, DS_DogovorCreateDateTo asc, DS_DAKey asc
     end

     if @nDSKey is null
     begin
          set @nDSKey = -1     
          set @nValue = 0     
          set @nIsPercent = 1     
     end
GO

grant execute on [dbo].[GetPartnerCommission] to public
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
	@nUseHolidayRule smallint		-- Правило выходного дня: 0 - не использовать, 1 - использовать
  )
AS
--<DATE>2010-11-03</DATE>
---<VERSION>7.2.39.1</VERSION>
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
		insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_TourKey, CP_UserKey, CP_Status, CP_UseHolidayRule)
		values (@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @TrKey, @userKey, 1, @nUseHolidayRule)
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

	--Настройка (использовать связку обсчитанных цен с текущими ценами, пока не реализована)
	select @sUseServicePrices = SS_ParmValue from systemsettings with(nolock) where SS_ParmName = 'UseServicePrices'

	If @nUpdate=0
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey,
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock), TP_Lists with(nolock), TP_ServiceLists with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TI_TOKey = TO_Key and TL_TOKey = TO_Key and TL_TSKey = TS_Key and TL_TIKey = TI_Key and TO_Key = @nPriceTourKey
	Else
	BEGIN
		select distinct TO_Key, TD_Date + TS_Day - 1 flight_day, TS_Code , TS_OpPartnerKey,	TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days
		into #tp_flights
		from TP_Tours with(nolock) join TP_Services with(nolock) on TO_Key = TS_TOKey and TS_SVKey = 1
			join TP_ServiceLists with(nolock) on TL_TSKey = TS_Key and TS_TOKey = TO_Key
			join TP_Lists with(nolock) on TL_TIKey = TI_Key and TI_TOKey = TO_Key
			join TP_TurDates with(nolock) on TD_TOKey = TO_Key
		where TO_Key = @nPriceTourKey
		
		delete from #tp_flights where exists (Select 1 From TP_Flights with(nolock) Where TF_TOKey=@nPriceTourKey and TF_Date=flight_day
			and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
			and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = TI_Days)
	
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days)
		select * from #tp_flights
	END

--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
	--Update	TP_Flights with(rowlock) Set 	TF_CodeNew = TF_CodeOld,
	--			TF_PRKeyNew = TF_PRKeyOld
	--Where	(SELECT count(*) FROM AirSeason  with(nolock) WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') > 0 
	--	and TF_TOKey = @nPriceTourKey	
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey and TF_Date BETWEEN CS_Date AND  CS_DateEnd and (ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long))
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
								AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
								(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and
								(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long)
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
									AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
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
									TF_Date BETWEEN CS_Date AND  CS_DateEnd AND
									AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
									(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and
									(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long)
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

		declare @calcPricesCount int, @calcPriceListCount int, @calcTurDates int
		select @calcPriceListCount = COUNT(1) from TP_Lists with(nolock) where TI_TOKey = @nPriceTourKey and TI_UPDATE = @nUpdate
		select @calcTurDates = COUNT(1) from TP_TurDates with(nolock) where TD_TOKey = @nPriceTourKey and TD_UPDATE = @nUpdate
		select @calcPricesCount = @calcPriceListCount * @calcTurDates

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
					ELSE
					BEGIN
						delete from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
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
								TF_Date = @servicedate AND
								TF_Days = @TI_DAYS
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
inner join tiptur with(nolock) on pt_tourtype = tp_key
inner join turlist with(nolock) on pt_tlkey = tl_key
inner join roomscategory  with(nolock) with (nolock) on pt_rckey = rc_key
inner join tp_servicelists with(nolock) on tl_tikey = pt_pricelistkey
inner join tp_services with(nolock) on ts_key = tl_tskey and ts_svkey = 2
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

-- sp_mwGetUsers.sql
if exists(select id from sysobjects where xtype='p' and name='mwGetUsers')
	drop proc dbo.mwGetUsers
go

create procedure [dbo].[mwGetUsers]
as
begin
	select us_key, IsNull(pr_name + '-','') + us_id as us_name
	from dup_user
		left join tbl_partners on us_prkey=pr_key
	where US_BTKEY > 0 and isnull(us_type,0) = 0 and US_REG > 0
	order by US_COMPANYNAME, US_ID
end
go

grant exec on [dbo].[mwGetUsers] to public
go


-- sp_mwSyncDictionaryData.sql
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
	declare @updatePackageSize smallint
	set @updatePackageSize = 10	

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
				where sd_cnkey = cn_key and isnull(sd_cnname, '') <> isnull(cn_name, '')))
		begin
			update top (@updatePackageSize) percent dbo.mwSpoDataTable
			set
				sd_cnname = isnull(cn_name, '')
			from
				tbl_country
			where
				sd_cnkey = cn_key and 
				isnull(sd_cnname, '') <> isnull(cn_name, '')
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
					isnull(sd_hdstars, '') <> isnull(hd_stars, '') or 
					isnull(sd_ctkey, 0) <> isnull(hd_ctkey, 0) or 
					isnull(sd_rskey, 0) <> isnull(hd_rskey, 0) or 
					isnull(sd_hdname, '') <> isnull(hd_name, '') or 
					isnull(sd_hotelurl, '') <> isnull(hd_http, '')
				)
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwSpoDataTable
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
					isnull(sd_hdstars, '') <> isnull(hd_stars, '') or 
					isnull(sd_ctkey, 0) <> isnull(hd_ctkey, 0) or 
					isnull(sd_rskey, 0) <> isnull(hd_rskey, 0) or 
					isnull(sd_hdname, '') <> isnull(hd_name, '') or 
					isnull(sd_hotelurl, '') <> isnull(hd_http, '')
				)
		end
		
		-- mwPriceDataTable	
		if @update_search_table > 0
		begin
			while exists(select top 1 pt_hdkey from dbo.mwPriceDataTable with(nolock) 
				where exists(select top 1 hd_key from dbo.hoteldictionary with(nolock) where
					pt_hdkey = hd_key
					and (
						isnull(pt_hdstars, '') <> isnull(hd_stars, '') or 
						isnull(pt_ctkey, 0) <> isnull(hd_ctkey, 0) or
						isnull(pt_rskey, 0) <> isnull(hd_rskey, 0) or
						isnull(pt_hdname, '') <> isnull(hd_name, '') or
						isnull(pt_hotelurl, '') <> isnull(hd_http, '')
					)
				)
			)
			begin
				update top (@updatePackageSize) percent dbo.mwPriceDataTable
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
						isnull(pt_hdstars, '') <> isnull(hd_stars, '') or 
						isnull(pt_ctkey, 0) <> isnull(hd_ctkey, 0) or
						isnull(pt_rskey, 0) <> isnull(hd_rskey, 0) or
						isnull(pt_hdname, '') <> isnull(hd_name, '') or
						isnull(pt_hotelurl, '') <> isnull(hd_http, '')
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
				where ct_key <> 0 and sd_ctkeyfrom = ct_key and isnull(sd_ctfromname, '') <> isnull(ct_name, '')))
		begin
			update top (@updatePackageSize) percent dbo.mwSpoDataTable
			set
				sd_ctfromname = isnull(ct_name,'')
			from
				dbo.citydictionary
			where
				ct_key <> 0 and
				sd_ctkeyfrom = ct_key and 
				isnull(sd_ctfromname, '') <> isnull(ct_name, '')
		end

		while exists(select top 1 sd_ctkey from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 ct_key from citydictionary with(nolock) 
				where ct_key <> 0 and sd_ctkey = ct_key and isnull(sd_ctname, '') <> isnull(ct_name, '')
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwSpoDataTable
			set
				sd_ctname = isnull(ct_name,'')
			from
				dbo.citydictionary
			where
				ct_key <> 0 and
				sd_ctkey = ct_key and 
				isnull(sd_ctname, '') <> isnull(ct_name, '')
		end
		
		-- mwPriceDataTable
		if @update_search_table > 0
		begin
			while exists(select top 1 pt_ctkey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 ct_key from dbo.citydictionary with(nolock) where
					ct_key <> 0 and pt_ctkey = ct_key and isnull(pt_ctname, '') <> isnull(ct_name, '')
				)
			)
			begin
				update top (@updatePackageSize) percent dbo.mwPriceDataTable
				set
					pt_ctname = isnull(ct_name,'')
				from
					dbo.citydictionary
				where
					ct_key <> 0 and
					pt_ctkey = ct_key and 
					isnull(pt_ctname, '') <> isnull(ct_name, '')
			end
		end
	end
	
	--курорт
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='RESORT')
	begin
		-- mwSpoDataTable
		while exists(select top 1 sd_rskey from dbo.mwSpoDataTable with(nolock)
			where exists(select top 1 rs_key from dbo.resorts with(nolock) where
				sd_rskey = rs_key and isnull(sd_rsname, '') <> isnull(rs_name, '')
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwSpoDataTable
			set
				sd_rsname = isnull(rs_name,'')
			from
				dbo.resorts
			where
				sd_rskey = rs_key and 
				isnull(sd_rsname, '') <> isnull(rs_name, '')
		end
		
		-- mwPriceDataTable	
		if @update_search_table > 0
		begin
			while exists(select top 1 pt_rskey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 rs_key from dbo.resorts with(nolock) where
					pt_rskey = rs_key and isnull(pt_rsname, '') <> isnull(rs_name, '')
				)
			)		
			begin
				update top (@updatePackageSize) percent dbo.mwPriceDataTable
				set
					pt_rsname = isnull(rs_name, '')
				from
					dbo.resorts
				where
					pt_rskey = rs_key and 
					isnull(pt_rsname, '') <> isnull(rs_name, '')
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
					isnull(sd_tourname, '') <> isnull(tl_nameweb, '') or 
					isnull(sd_tourtype, 0) <> isnull(tl_tip, 0)
				)
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwSpoDataTable
			set
				sd_tourname = isnull(tl_nameweb, ''),
				sd_tourtype = isnull(tl_tip, 0)
			from
				dbo.tbl_turlist
			where
				sd_tlkey = tl_key
				and (
					isnull(sd_tourname, '') <> isnull(tl_nameweb, '') or 
					isnull(sd_tourtype, 0) <> isnull(tl_tip, 0)
				)
		end
		
		-- mwPriceDataTable	
		if @update_search_table > 0
		begin			
			while exists(select top 1 pt_tlkey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 tl_key from dbo.tbl_turlist with(nolock) where
					pt_tlkey = tl_key
					and (
						isnull(pt_tourname, '') <> isnull(tl_nameweb, '') or
						isnull(pt_toururl, '') <> isnull(tl_webhttp, '') or
						isnull(pt_tourtype, 0) <> isnull(tl_tip, 0)
					)
				)
			)
			begin
				update top (@updatePackageSize) percent dbo.mwPriceDataTable
				set
					pt_tourname = isnull(tl_nameweb, ''),
					pt_toururl = isnull(tl_webhttp, ''),
					pt_tourtype = isnull(tl_tip, 0)
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
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='TOURTYPE')
	begin
		while exists(select top 1 sd_tourtype from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 tp_key from dbo.tiptur with(nolock) 
				where sd_tourtype = tp_key and isnull(sd_tourtypename, '') <> isnull(tp_name, '')
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwSpoDataTable
			set
				sd_tourtypename = isnull(tp_name, '')
			from
				dbo.tiptur
			where
				sd_tourtype = tp_key
				and isnull(sd_tourtypename, '') <> isnull(tp_name, '')
		end
	end

	-- питание
	if (@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='PANSION')
	begin
		while exists(select top 1 sd_pnkey from dbo.mwSpoDataTable with(nolock) 
			where exists(select top 1 pn_key from dbo.pansion with(nolock) 
				where sd_pnkey = pn_key and isnull(sd_pncode, '') <> isnull(pn_code, '')
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwSpoDataTable
			set
				sd_pncode = isnull(pn_code, '')
			from
				dbo.pansion
			where
				sd_pnkey = pn_key and 
				isnull(sd_pncode, '') <> isnull(pn_code, '')
		end	
		
		if @update_search_table > 0
		begin
			while exists(select top 1 pt_pnkey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 pn_key from dbo.pansion with(nolock) where
					pt_pnkey = pn_key
					and (
						isnull(pt_pnname, '') <> isnull(pn_name, '') or
						isnull(pt_pncode, '') <> isnull(pn_code, '')
					)
				)
			)
			begin
				update top (@updatePackageSize) percent dbo.mwPriceDataTable
				set 
					pt_pnname = isnull(pn_name, ''),
					pt_pncode = isnull(pn_code, '')
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
	if ((@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='ROOM')) and @update_search_table > 0
	begin
		while exists(select top 1 pt_rmkey from dbo.mwPriceDataTable with(nolock)
			where exists(select top 1 rm_key from dbo.rooms with(nolock) where
				pt_rmkey = rm_key
				and (
					isnull(pt_rmname, '') <> isnull(rm_name, '') or 
					isnull(pt_rmcode, '') <> isnull(rm_code, '') or 
					isnull(pt_rmorder, 0) <> isnull(rm_order, 0)
				)
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwPriceDataTable
			set
				pt_rmname = isnull(rm_name, ''),
				pt_rmcode = isnull(rm_code, ''),
				pt_rmorder = isnull(rm_order, 0)
			from
				dbo.rooms
			where
				pt_rmkey = rm_key
				and (
					isnull(pt_rmname, '') <> isnull(rm_name, '') or 
					isnull(pt_rmcode, '') <> isnull(rm_code, '') or 
					isnull(pt_rmorder, 0) <> isnull(rm_order, 0)
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
					isnull(pt_rcname, '') <> isnull(rc_name, '') or 
					isnull(pt_rccode, '') <> isnull(rc_code, '') or 
					isnull(pt_rcorder, 0) <> isnull(rc_order, 0)
				)
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwPriceDataTable
			set
				pt_rcname = isnull(rc_name, ''),
				pt_rccode = isnull(rc_code, ''),
				pt_rcorder = isnull(rc_order, 0)
			from
				dbo.roomscategory
			where
				pt_rckey = rc_key
				and (
					isnull(pt_rcname, '') <> isnull(rc_name, '') or 
					isnull(pt_rccode, '') <> isnull(rc_code, '') or 
					isnull(pt_rcorder, 0) <> isnull(rc_order, 0)
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
					isnull(pt_acname, '') <> isnull(ac_name, '') or
					isnull(pt_accode, '') <> isnull(ac_code, '') or
					isnull(pt_acorder, 0) <> isnull(ac_order, 0) or
					isnull(pt_main, 0) <> isnull(ac_main, 0) or
					isnull(pt_childagefrom, 0) <> isnull(ac_agefrom, 0) or
					isnull(pt_childageto, 0) <> isnull(ac_ageto, 0) or
					isnull(pt_childagefrom2, 0) <> isnull(ac_agefrom2, 0) or
					isnull(pt_childageto2, 0) <> isnull(ac_ageto2, 0)					
				)
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwPriceDataTable
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
					isnull(pt_acname, '') <> isnull(ac_name, '') or
					isnull(pt_accode, '') <> isnull(ac_code, '') or
					isnull(pt_acorder, 0) <> isnull(ac_order, 0) or
					isnull(pt_main, 0) <> isnull(ac_main, 0) or
					isnull(pt_childagefrom, 0) <> isnull(ac_agefrom, 0) or
					isnull(pt_childageto, 0) <> isnull(ac_ageto, 0) or
					isnull(pt_childagefrom2, 0) <> isnull(ac_agefrom2, 0) or
					isnull(pt_childageto2, 0) <> isnull(ac_ageto2, 0)	
				)
		end
	end

	--kadraliev MEG00029412 29.09.2010 номер и размещение (количество основных и дополнительных мест)
	if ((@blUpdateAllFields = 1) or exists(select top 1 * from @fields where fname='ROOM' or fname='ACCOMODATION')) and @update_search_table > 0
	begin	
		while exists(select top 1 pt_key 
					 from mwPriceDataTable
					 inner join rooms with(nolock) on pt_rmkey = rm_key
					 inner join accmdmentype with(nolock) on pt_ackey = ac_key
					 where
						pt_main > 0 and isnull(pt_mainplaces,0) <> (case when @isMainPlacesFromAccomodation = 1
								then isnull(ac_nrealplaces,0)
								else isnull(rm_nplaces,0) end) or
						isnull(pt_addplaces,0) <> (case isnull(ac_nmenexbed, -1) when -1 
								then (case when @isAddPlacesFromRooms = 1 
										then isnull(rm_nplacesex, 0)
										else isnull(ac_nmenexbed, 0) end)
								else isnull(ac_nmenexbed, 0) end ))
		begin									
			update top (@updatePackageSize) percent dbo.mwPriceDataTable
			set
				pt_mainplaces = (case when pt_main > 0
								then (case when @isMainPlacesFromAccomodation = 1
									then isnull(ac_nrealplaces,0)
									else isnull(rm_nplaces,0) end)
								else pt_mainplaces end),
				pt_addplaces =	(case isnull(ac_nmenexbed, -1) when -1 
									then (case when @isAddPlacesFromRooms = 1 
											then isnull(rm_nplacesex, 0)
											else isnull(ac_nmenexbed, 0) end)
									else isnull(ac_nmenexbed, 0) end )
			from dbo.mwPriceDataTable orig
				inner join rooms with(nolock) on orig.pt_rmkey = rm_key
				inner join accmdmentype with(nolock) on orig.pt_ackey = ac_key
			where
				pt_main > 0 and isnull(pt_mainplaces,0) <> (case when @isMainPlacesFromAccomodation = 1
						then isnull(ac_nrealplaces,0)
						else isnull(rm_nplaces,0) end) or
				isnull(pt_addplaces,0) <> (case isnull(ac_nmenexbed, -1) when -1 
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
					isnull(sd_tourcreated, '1900-01-01') <> isnull(to_datecreated, '1900-01-01') or 
					isnull(sd_tourvalid, '1900-01-01') <> isnull(to_datevalid, '1900-01-01')
				)
			)
		)
		begin
			update top (@updatePackageSize) percent dbo.mwSpoDataTable
			set
				sd_tourcreated = isnull(to_datecreated, '1900-01-01'),
				sd_tourvalid = isnull(to_datevalid, '1900-01-01')
			from
				dbo.tp_tours
			where
				sd_tourkey = to_key
				and (
					isnull(sd_tourcreated, '1900-01-01') <> isnull(to_datecreated, '1900-01-01') or 
					isnull(sd_tourvalid, '1900-01-01') <> isnull(to_datevalid, '1900-01-01')
				)
		end
		
		-- mwPriceDataTable
		if @update_search_table > 0
		begin			
			while exists(select top 1 pt_tourkey from dbo.mwPriceDataTable with(nolock)
				where exists(select top 1 to_key from dbo.tp_tours with(nolock) where
					pt_tourkey = to_key
					and (
						isnull(pt_tourcreated, '1900-01-01') <> isnull(to_datecreated, '1900-01-01') or 
						isnull(pt_tourvalid, '1900-01-01') <> isnull(to_datevalid, '1900-01-01') or 
						isnull(pt_rate, '') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '') COLLATE DATABASE_DEFAULT
					)
				)
			)
			begin
				update top (@updatePackageSize) percent dbo.mwPriceDataTable
				set
					pt_tourcreated = isnull(to_datecreated, '1900-01-01'),
					pt_tourvalid = isnull(to_datevalid, '1900-01-01'),
					pt_rate = isnull(to_rate, '')
				from
					dbo.tp_tours
				where
					pt_tourkey = to_key
					and (
						isnull(pt_tourcreated, '1900-01-01') <> isnull(to_datecreated, '1900-01-01') or 
						isnull(pt_tourvalid, '1900-01-01') <> isnull(to_datevalid, '1900-01-01') or 
						isnull(pt_rate, '') COLLATE DATABASE_DEFAULT <> isnull(to_rate, '') COLLATE DATABASE_DEFAULT
					)
			end			
		end
	end
end
go

grant exec on dbo.mwSyncDictionaryData to public
go

-- fn_mwGetNotCalculatedSvNames.sql
if exists(select id from sysobjects where xtype='fn' and name='mwGetNotCalculatedSvNames')
	drop function dbo.mwGetNotCalculatedSvNames
GO

CREATE FUNCTION [dbo].[mwGetNotCalculatedSvNames](@tiKey INTEGER, @delimeter VARCHAR(5))
RETURNS VARCHAR(256)
AS
BEGIN
	declare @Result varchar(256)
	set @Result = ''

	
	select @Result = @Result + 
		CASE WHEN CHARINDEX ( @Result , ltrim(rtrim(sv_name))) = 0
			 THEN  @delimeter + ltrim(rtrim(sv_name)) 
			 ELSE ''
		END
	from
		(select distinct sv_name
		from tp_lists with(nolock) 
		inner join tp_tours with(nolock) on to_key=ti_tokey
		inner join turlist with(nolock) on tl_key=to_trkey
		inner join turservice with(nolock) on ts_trkey=tl_key
		inner join service with(nolock) on sv_key = ts_svkey
		where ti_key = @tiKey and  not ts_svkey in 
			(
				select  distinct ts_svkey
				from tp_services with(nolock)
					inner join tp_servicelists with(nolock) on tl_tskey = ts_key 
				where tl_tikey=@tiKey
			)
		) as tbl

	if @Result != ''
		set @Result = substring(@Result, len(@delimeter) + 1, len(@Result) - 1)
 
	return (@Result)
END

GO

grant exec on [dbo].[mwGetNotCalculatedSvNames] to public
GO


-- fn_mwGetServiceClassesNames.sql
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
	
if exists(select id from sysobjects where xtype='fn' and name='mwGetServiceClassesNames')
	drop function dbo.mwGetServiceClassesNames
GO

CREATE FUNCTION [dbo].[mwGetServiceClassesNames](@tiKey INTEGER, @addPansionInfo SMALLINT, @delimeter VARCHAR(5), @addHotelInfo SMALLINT)
RETURNS VARCHAR(256)
AS
BEGIN	
	
	declare @Result varchar(256)
	set @Result = ''
	
	select @Result = @Result + 
		CASE WHEN CHARINDEX ( @Result , ( @delimeter + ltrim(rtrim(sv_name)) + CASE WHEN @addHotelInfo = 1 and sv_key = 3 THEN ' ' + ltrim(rtrim(hd_name)) + ' ' ELSE '' END + CASE WHEN @addPansionInfo = 1 and sv_key = 3 THEN '(питание: ' + ltrim(rtrim(pn_name)) + ')' ELSE '' END)) = 0
			 THEN  @delimeter + ltrim(rtrim(sv_name)) + CASE WHEN @addHotelInfo = 1 and sv_key = 3 THEN ' ' + ltrim(rtrim(hd_name)) + ' ' ELSE '' END + CASE WHEN @addPansionInfo = 1 and sv_key = 3 THEN '(питание: ' + ltrim(rtrim(pn_name)) + ')' ELSE '' END
			 ELSE ''
		END
	from (select distinct 
			sv_name, sv_key, pn_name, hd_name, CASE WHEN sv_key < 3 THEN 0 ELSE (CASE WHEN sv_key > 3 THEN 9999 ELSE ts_day END) END ts_day
		from tp_services with(nolock)
			inner join tp_servicelists with(nolock) on tl_tskey = ts_key 
			inner join service with(nolock) on sv_key = ts_svkey
			left  join pansion with(nolock) on ts_SubCode2 = pn_key
			left  join hoteldictionary with(nolock) on ts_code = hd_key and ts_svkey=3
		where tl_tikey = @tiKey and ((ts_attribute & 32832) = 0)) tbl
	order by ts_day

	if @Result != ''
		set @Result =substring(@Result, len(@delimeter) + 1, len(@Result) - 1)
 
	return (@Result)
END
GO

grant exec on [dbo].[mwGetServiceClassesNames] to public
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
			and isnull(qo_subcode2, 0) in (0, @subcode2)
			and ((@checkAgentQuotes > 0 and @checkCommonQuotes > 0 and isnull(qp_agentkey, 0) in (0, @agentKey)) or
				(@checkAgentQuotes <= 0 and isnull(qp_agentkey, 0) = 0) or
				(@checkAgentQuotes > 0 and @checkCommonQuotes <= 0 and isnull(qp_agentkey, 0) in (0, @agentKey)))
			and (@partnerKey < 0 or isnull(qt_prkey, 0) in (0, @partnerKey))
			and ((@days = 1 and qd_date = @dateFrom) or (@days > 1 and qd_date between @dateFrom and @dateTo))
			and (@tourDuration < 0 or (@checkNoLongQuotes <> @ALLDAYS_CHECK and isnull(ql_duration, 0) in (0, @long)) or (@checkNoLongQuotes = @ALLDAYS_CHECK and isnull(ql_duration, 0) = @long))
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
				0,null,0,ss_date,null,null,0,0,1
			from StopSales
				inner join QuotaObjects on qo_id=ss_qoid
			where ((@days = 1 and ss_date = @dateFrom) or (@days > 1 and ss_date between @dateFrom and @dateTo))
					and ss_qdid is null
					and qo_svkey = @svkey
					and qo_code = @code
					and isnull(qo_subcode1, 0) in (0, @subcode1)
					and isnull(qo_subcode2, 0) in (0, @subcode2)
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
end
GO

GRANT SELECT ON [dbo].[mwCheckQuotesEx2] TO PUBLIC
GO


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

-- T_Service.sql
--/****** Объект:  Trigger [T_Service]    Дата сценария: 08/02/2010 17:58:07 ******/
--IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[T_Service]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
--DROP TRIGGER [dbo].[T_Service]
--GO

--SET QUOTED_IDENTIFIER ON
--GO
---- =============================================
---- Author:		<Author,,Name>
---- Create date: 30.07.2010
---- Description:	Запрещает изменять поле SV_ISCITYб SV_ISSUBCODE1 и SV_ISSUBCODE2  Если по этому классу услуг есть связи
---- =============================================
--CREATE TRIGGER [dbo].[T_Service]
--   ON  [dbo].[Service]
--   AFTER UPDATE
--AS 
--BEGIN
--	if (EXISTS (SELECT * FROM deleted join inserted on deleted.sv_key = inserted.sv_key AND (deleted.SV_ISCITY <> inserted.SV_ISCITY OR deleted.SV_ISSUBCODE1 <> inserted.SV_ISSUBCODE1 OR deleted.SV_ISSUBCODE2 <> inserted.SV_ISSUBCODE2) AND (dbo.fn_GetServiceLink(inserted.sv_key) = 1)))
--		BEGIN
--			ROLLBACK TRANSACTION
--			RAISERROR('Нельзя изменить привязку местоположения и описание, если по классу услуг есть зависимости',16,1)
--		END
--END
--GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_Service]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	alter table [dbo].[Service] disable trigger [T_Service]
GO

-- T_QuotaDetails_QuotaPartsDate.sql
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

-- x_ti_tokey(tp_lists).sql
if exists (select 1 from sysindexes where name='x_ti_tokey' and id = object_id(N'TP_Lists'))
	drop index [tp_lists].[x_ti_tokey]
go

declare @sql nvarchar (1000)
if @@Version like '%SQL%Server%2000%' 
 set @sql = 'create index [x_ti_tokey] on dbo.tp_lists (ti_tokey, ti_ctkeyfrom)'
else
 set @sql = 'create nonclustered index [x_ti_tokey] on dbo.tp_lists (ti_tokey) include(ti_ctkeyfrom)'

exec sp_executesql @sql
go

-- x_mp_prkey(Mappings).sql
if exists (select 1 from sysindexes where name='IX_MP_PRKEY' and id = object_id(N'Mappings'))
	drop index [Mappings].[IX_MP_PRKEY]
go

declare @sql nvarchar (1000)
if @@Version like '%SQL%Server%2000%'
  set @sql = 'CREATE INDEX [IX_MP_PRKEY] ON dbo.Mappings(
	MP_PRKey, MP_Key, MP_TableID, MP_IntKey, MP_CharKey, MP_Value, MP_StrValue, MP_CreateDate)'
else
  set @sql = 'CREATE NONCLUSTERED INDEX [IX_MP_PRKEY] ON dbo.Mappings (MP_PRKey ASC)
  INCLUDE (MP_Key, MP_TableID, MP_IntKey, MP_CharKey, MP_Value, MP_StrValue, MP_CreateDate)'
GO

-- Index_mwPriceDataTable_x_singleprice.sql
if exists(select 1 from sysindexes where name='x_singleprice' and id = object_id(N'mwPriceDataTable'))
	drop index [dbo].[mwPriceDataTable].[x_singleprice]
go

declare @sql nvarchar (4000)
if @@Version like '%SQL%Server%2000%' 
 set @sql = 'CREATE INDEX [x_singleprice] ON [dbo].[mwPriceDataTable](
	[pt_tourdate],
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
	[pt_main],
	[pt_isenabled],
	[pt_tourkey],
	[pt_price],
	[pt_ctkeyfrom])'
else 
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
	[pt_autodisabled],
	[pt_tourkey],
	[pt_price],
	[pt_ctkeyfrom])'

exec sp_executesql @sql

go

-- T_PriceChange.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_PriceChange]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_PriceChange]
GO

CREATE TRIGGER [T_PriceChange] ON [dbo].[tbl_Costs] for Insert,Update,Delete
AS
if @@ROWCOUNT > 0
begin
	declare @CS_SVKey int, @CS_Code int, @CS_SubCode1 int, @CS_SubCode2 int, @CS_PRKey int, @CS_PKKey int

	declare @OCS_DateBeg datetime, @OCS_DateEnd datetime, @OCS_Netto decimal(12,2), @OCS_Cost decimal(12,2)
	declare @OCS_Week varchar(7), @OCS_Discount smallint, @OCS_Type smallint, @OCS_Rate varchar(2)
	declare @OCS_Long smallint, @OCS_LongMin smallint, @OCS_ByDay smallint, @OCS_Profit decimal(12,2)
	declare @OCS_CheckInDateBeg datetime, @OCS_CheckInDateEnd datetime
	
	declare @NCS_DateBeg datetime, @NCS_DateEnd datetime, @NCS_Netto decimal(12,2), @NCS_Cost decimal(12,2)
	declare @NCS_Week varchar(7), @NCS_Discount smallint, @NCS_Type smallint, @NCS_Rate varchar(2)
	declare @NCS_Long smallint, @NCS_LongMin smallint, @NCS_ByDay smallint, @NCS_Profit decimal(12,2)
	declare @NCS_CheckInDateBeg datetime, @NCS_CheckInDateEnd datetime, @CS_ID int

	declare @minDate datetime, @maxDate datetime
	declare @sMod varchar(3), @nDelCount int, @nInsCount int
	
	declare @sWho varchar(25)

	SELECT @nDelCount = COUNT(*) FROM DELETED
	SELECT @nInsCount = COUNT(*) FROM INSERTED
	IF (@nDelCount = 0)
	BEGIN
		SET @sMod = 'INS'
		DECLARE cursorCostUpdateFull CURSOR FOR 
		select	N.CS_ID, N.CS_SVKey, N.CS_Code, N.CS_SubCode1, N.CS_SubCode2, N.CS_PRKey, N.CS_PKKey,
				null, null, null, null,
				null, null, null, null,
				null, null, null, null,
				null, null,
				N.CS_Date, N.CS_DateEnd, N.CS_CostNetto, N.CS_Cost,
				N.CS_Week, N.CS_Discount, N.CS_Type, N.CS_Rate,
				N.CS_Long, N.CS_LongMin, N.CS_ByDay, N.CS_Profit,
				N.CS_CheckInDateBeg, N.CS_CheckInDateEnd
		from	inserted N
	END
	ELSE IF (@nInsCount = 0)
	BEGIN
		SET @sMod = 'DEL'
		DECLARE cursorCostUpdateFull CURSOR FOR 
		select	O.CS_ID, O.CS_SVKey, O.CS_Code, O.CS_SubCode1, O.CS_SubCode2, O.CS_PRKey, O.CS_PKKey,
				O.CS_Date, O.CS_DateEnd, O.CS_CostNetto, O.CS_Cost,
				O.CS_Week, O.CS_Discount, O.CS_Type, O.CS_Rate,
				O.CS_Long, O.CS_LongMin, O.CS_ByDay, O.CS_Profit,
				O.CS_CheckInDateBeg, O.CS_CheckInDateEnd,
				null, null, null, null,
				null, null, null, null,
				null, null, null, null,
				null, null
		from	deleted O
	END
	ELSE 
	BEGIN
  		SET @sMod = 'UPD'
		declare cursorCostUpdateFull cursor for
		select	O.CS_ID, O.CS_SVKey, O.CS_Code, O.CS_SubCode1, O.CS_SubCode2, O.CS_PRKey, O.CS_PKKey,
				O.CS_Date, O.CS_DateEnd, O.CS_CostNetto, O.CS_Cost,
				O.CS_Week, O.CS_Discount, O.CS_Type, O.CS_Rate,
				O.CS_Long, O.CS_LongMin, O.CS_ByDay, O.CS_Profit,
				O.CS_CheckInDateBeg, O.CS_CheckInDateEnd,
				N.CS_Date, N.CS_DateEnd, N.CS_CostNetto, N.CS_Cost,
				N.CS_Week, N.CS_Discount, N.CS_Type, N.CS_Rate,
				N.CS_Long, N.CS_LongMin, N.CS_ByDay, N.CS_Profit,
				N.CS_CheckInDateBeg, N.CS_CheckInDateEnd
		from	deleted O, inserted N
		where	O.CS_ID = N.CS_ID
	END	

	open cursorCostUpdateFull
	fetch next from cursorCostUpdateFull into 
				@CS_ID, @CS_SVKey, @CS_Code, @CS_SubCode1, @CS_SubCode2, @CS_PRKey, @CS_PKKey,
				@OCS_DateBeg, @OCS_DateEnd, @OCS_Netto, @OCS_Cost,
				@OCS_Week, @OCS_Discount, @OCS_Type, @OCS_Rate,
				@OCS_Long, @OCS_LongMin, @OCS_ByDay, @OCS_Profit,
				@OCS_CheckInDateBeg, @OCS_CheckInDateEnd,
				@NCS_DateBeg, @NCS_DateEnd, @NCS_Netto, @NCS_Cost,
				@NCS_Week, @NCS_Discount, @NCS_Type, @NCS_Rate,
				@NCS_Long, @NCS_LongMin, @NCS_ByDay, @NCS_Profit,
				@NCS_CheckInDateBeg, @NCS_CheckInDateEnd

	while @@FETCH_STATUS = 0
	begin
		If @sMod = 'INS'
		BEGIN
			Set @minDate = @NCS_DateBeg
			Set @maxDate = @NCS_DateEnd
		END

		If @sMod = 'DEL'
		BEGIN
			Set @minDate = @OCS_DateBeg
			Set @maxDate = @OCS_DateEnd
		END

		If @sMod = 'UPD'
		BEGIN
			if @NCS_DateBeg <= @OCS_DateBeg and @NCS_DateBeg is not null
				Set @minDate = @NCS_DateBeg
			else if @NCS_DateBeg > @OCS_DateBeg and @OCS_DateBeg is not null
				Set @minDate = @OCS_DateBeg
			else
				Set @minDate = @OCS_CheckInDateBeg 
		
			if @NCS_DateEnd <= @OCS_DateEnd and @NCS_DateEnd is not null
				Set @maxDate = @NCS_DateEnd
			else if @NCS_DateEnd > @OCS_DateEnd and @OCS_DateEnd is not null
				Set @maxDate = @OCS_DateEnd
			else
				Set @maxDate = @OCS_CheckInDateEnd
		END

		EXEC dbo.CostChange @CS_SVKey, @CS_Code, @CS_SubCode1, @CS_SubCode2, @CS_PRKey, @CS_PKKey, @minDate, @maxDate
		
		if @sMod = 'INS' or @sMod = 'UPD'
		begin
			EXEC dbo.CurrentUser @sWho output
			update tbl_Costs set CS_UPDDATE = GETDATE(), CS_UPDUSER = @sWho where CS_ID = @CS_ID
		end

		fetch next from cursorCostUpdateFull into 
				@CS_ID, @CS_SVKey, @CS_Code, @CS_SubCode1, @CS_SubCode2, @CS_PRKey, @CS_PKKey,
				@OCS_DateBeg, @OCS_DateEnd, @OCS_Netto, @OCS_Cost,
				@OCS_Week, @OCS_Discount, @OCS_Type, @OCS_Rate,
				@OCS_Long, @OCS_LongMin, @OCS_ByDay, @OCS_Profit,
				@OCS_CheckInDateBeg, @OCS_CheckInDateEnd,
				@NCS_DateBeg, @NCS_DateEnd, @NCS_Netto, @NCS_Cost,
				@NCS_Week, @NCS_Discount, @NCS_Type, @NCS_Rate,
				@NCS_Long, @NCS_LongMin, @NCS_ByDay, @NCS_Profit,
				@NCS_CheckInDateBeg, @NCS_CheckInDateEnd
	end
	close cursorCostUpdateFull
	deallocate cursorCostUpdateFull
end
GO

-- sp_GetUserKey.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetUserKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[GetUserKey]
GO

CREATE PROCEDURE [dbo].[GetUserKey]
	@nUserKey int output
AS
	SELECT @nUserKey = US_Key FROM UserList WHERE US_UserID = dbo.fn_GetUserAlias(SYSTEM_USER) 
	IF @nUserKey IS NULL SET @nUserKey = 0
GO

GRANT EXEC ON [dbo].[GetUserKey] TO PUBLIC
GO

-- T_UpdDogListQuota.sql
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_UpdDogListQuota]'))
DROP TRIGGER [dbo].[T_UpdDogListQuota]
GO
CREATE TRIGGER [dbo].[T_UpdDogListQuota] 
ON [dbo].[tbl_DogovorList]
AFTER INSERT, UPDATE, DELETE
AS
--<VERSION>2008.1.01.12a</VERSION>
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
					SELECT TOP 1 @RPID=SD_RPID FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_TUKey is null
					DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_RPID=@RPID and SD_TUKey is null
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
									WHERE SD_DLKey=DL_Key and DL_DGKey=@DGKey and RL_ID=SD_RLID
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



-- sp_CheckQuotaExist.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckQuotaExist]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckQuotaExist]
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
	
-- создаем таблицу со стопами
CREATE TABLE #StopSaleTemp
(SST_Code int, SST_SubCode1 int, SST_SubCode2 int, SST_QOID int, SST_PRKey int, SST_Date smalldatetime,
SST_QDID int, SST_Type smallint, SST_State smallint, SST_Comment varchar(255)
)

INSERT INTO #StopSaleTemp exec dbo.GetTableQuotaDetails NULL, @Q_QTID, @DateBeg, @DaysCount, null, null, @SVKey, @Code, @SubCode1, @PRKey

IF @SVKey=3
BEGIN
	declare CheckQuotaExistСursor cursor for 
		select	DISTINCT QT_ID, QT_PRKey, QT_ByRoom, 
				QD_Type, 
				QP_FilialKey, QP_CityDepartments, QP_AgentKey, CASE WHEN QP_Durations='' THEN 0 ELSE @TourDuration END, QP_FilialKey, QP_CityDepartments, 
				QO_SubCode1, QO_SubCode2
		from	QuotaObjects, Quotas, QuotaDetails, QuotaParts, HotelRooms
		where	QO_SVKey=@SVKey and QO_Code=@Code and HR_Key=@SubCode1 and (QO_SubCode1=HR_RMKey or QO_SubCode1=0) and (QO_SubCode2=HR_RCKey or QO_SubCode2=0) and QO_QTID=QT_ID
			and QD_QTID=QT_ID and QD_Date between @DateBeg and @DateEnd
			and QP_QDID = QD_ID
			and (QP_AgentKey=@AgentKey or QP_AgentKey is null) 
			and (QT_PRKey=@PRKey or QT_PRKey=0)
			and QP_IsDeleted is null and QD_IsDeleted is null	
			and (QP_Durations = '' or @TourDuration in (Select QL_Duration From QuotaLimitations Where QL_QPID=QP_ID))
			and not exists(select 1
							from #StopSaleTemp 
							where SST_PRKey = QT_PRKey
							and SST_QOID = QO_ID
							and SST_QDID = QD_ID
							and SST_Date = QD_Date
							and SST_State is not null)
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
			QO_SVKey = @SVKey and QO_Code = @Code and (QO_SubCode1=@SubCode1 or QO_SubCode1=0) and QO_QTID=QT_ID
			and QD_QTID = QT_ID and QD_Date between @DateBeg and @DateEnd
			and QP_QDID = QD_ID
			and (QP_AgentKey=@AgentKey or QP_AgentKey is null) 
			and (QT_PRKey=@PRKey or QT_PRKey=0)
			and QP_IsDeleted is null and QD_IsDeleted is null	
			and (QP_Durations = '' or @TourDuration in (Select QL_Duration From QuotaLimitations Where QL_QPID=QP_ID))
			and not exists(select 1
							from #StopSaleTemp 
							where SST_PRKey = QT_PRKey
							and SST_QOID = QO_ID
							and SST_QDID = QD_ID
							and SST_Date = QD_Date
							and SST_State is not null)
		group by QT_ID, QT_PRKey, QT_ByRoom, QD_Type, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_Durations, QO_SubCode1, QO_SubCode2
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

	declare @SubCode2 int

	SET @Query = 
	'
	INSERT INTO #Tbl (	TMP_Count, TMP_QTID, TMP_AgentKey, TMP_Type, TMP_Date, 
						TMP_ByRoom, TMP_Release, TMP_Partner, TMP_Durations, TMP_FilialKey, 
						TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2)
		SELECT	DISTINCT QP_Places-QP_Busy as d1, QT_ID, QP_AgentKey, QD_Type, QD_Date, 
				QT_ByRoom, QD_Release, QT_PRKey, QP_Durations, QP_FilialKey,
				QP_CityDepartments, QO_SubCode1, QO_SubCode2
		FROM	Quotas QT1, QuotaDetails QD1, QuotaParts QP1, QuotaObjects QO1, #StopSaleTemp
		WHERE	QO_ID = SST_QOID and QD_ID = SST_QDID and SST_State is null and ' + @SubQuery
	print @Query

	exec (@Query)
	
	SET @Q_QTID_Prev=@Q_QTID
	fetch CheckQuotaExistСursor into	@Q_QTID, @Q_Partner, @Q_ByRoom, 
										@Q_Type, 
										@Q_FilialKey, @Q_CityDepartments, @Q_AgentKey, @Q_Duration, @Q_FilialKey, @Q_CityDepartments, 
										@Q_SubCode1, @Q_SubCode2	
END

--select * from #Tbl

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

DECLARE @Tbl_DQ Table 
 		(TMP_Count smallint, TMP_AgentKey int, TMP_Type smallint, TMP_ByRoom bit, 
				TMP_Partner int, TMP_Duration smallint, TMP_FilialKey int, TMP_CityDepartments int,
				TMP_SubCode1 int, TMP_SubCode2 int, TMP_ReleaseIgnore bit)

DECLARE @DATETEMP datetime
SET @DATETEMP = GetDate()
-- Разрешим посадить в квоту с релиз периодом 0 текущим числом
set @DATETEMP = DATEADD(day, -1, @DATETEMP)
if exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSCheckQuotaRelease' and SS_ParmValue=1) OR exists (select SS_ParmValue from systemsettings where SS_ParmName='SYSAddQuotaPastPermit' and SS_ParmValue=1)
	SET @DATETEMP='01-JAN-1900'
INSERT INTO @Tbl_DQ
	SELECT	MIN(d1) as TMP_Count, TMP_AgentKey, TMP_Type, TMP_ByRoom, TMP_Partner, 
			d2 as TMP_Duration, TMP_FilialKey, TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2,0 as TMP_ReleaseIgnore FROM
		(SELECT	SUM(TMP_Count) as d1, TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner, 
				TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END as d2, TMP_SubCode1, TMP_SubCode2
		FROM	#Tbl
		WHERE	(TMP_Date >= @DATETEMP + ISNULL(TMP_Release,0) OR (TMP_Date < GETDATE() - 1))
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
			@Places_Count_ReleaseIgnore int, @Rooms_Count_ReleaseIgnore int,		 --доступное количество мест/номеров в квотах
			@PlacesNeed_Count smallint,					-- количество мест, которых недостаточно для оформления услуги
			@PlacesNeed_Count_ReleaseIgnore smallint					-- количество мест, которых недостаточно для оформления услуги

	If exists (SELECT * FROM @Tbl_DQ)
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
	
		--проверяем достаточно ли будет текущего кол-ва мест для бронирования
		declare @nPlaces smallint, @nRoomsService smallint
		If @SVKey=3 and @Rooms_Count>0
		BEGIN
			exec GetServiceRoomsCount @Code, @SubCode1, @Pax, @nRoomsService output
			
			If @nRoomsService > @Rooms_Count
				Set @PlacesNeed_Count = @nRoomsService - @Rooms_Count
				
			If @nRoomsService > @Rooms_Count_ReleaseIgnore
				Set @PlacesNeed_Count_ReleaseIgnore = @nRoomsService - @Rooms_Count_ReleaseIgnore
		END
		ELSE
		begin
			If @Pax > @Places_Count
				Set @PlacesNeed_Count = @Pax - @Places_Count
				
			If @Pax > @Places_Count_ReleaseIgnore
				Set @PlacesNeed_Count_ReleaseIgnore = @Pax - @Places_Count_ReleaseIgnore
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
	
	-- Проверим на стоп
	If @StopExist > 0
	BEGIN
		Set @Quota_CheckState = 2						--Возвращаем "Внимание STOP"
		Set @Quota_CheckDate = @StopDate
	END
END

GO
grant exec on [dbo].[CheckQuotaExist] to public
go


-- x_tp_services_1(tp_services).sql
if exists (select 1 from sysindexes where name='X_TP_SERVICES_1' and id = object_id(N'TP_Services'))
	drop index [TP_Services].[X_TP_SERVICES_1]
go

declare @sql nvarchar (4000)
if @@Version like '%SQL%Server%2000%' 
 set @sql = 'create index [X_TP_SERVICES_1] on [dbo].[TP_Services] 
	([TS_TOKey]
	,[TS_SVKey]
	,[TS_Key]
	,[TS_Code]
	,[TS_SubCode1]
	,[TS_SubCode2]
	,[TS_CTKey]
	,[TS_Day]
	,[TS_OpPartnerKey]
	,[TS_OpPacketKey]
	)'
else
 set @sql = 'CREATE NONCLUSTERED INDEX [X_TP_SERVICES_1] ON [dbo].[TP_Services] 
(
     [TS_TOKey] ASC,
     [TS_SVKey] ASC
)
INCLUDE ( [TS_Key],
[TS_Code],
[TS_SubCode1],
[TS_SubCode2],
[TS_CTKey],
[TS_Day],
[TS_OpPartnerKey],
[TS_OpPacketKey]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'

exec sp_executesql @sql
go

-- x_tp_lists_2(tp_lists).sql
if exists (select 1 from sysindexes where name='X_TP_LISTS_2' and id = object_id(N'TP_Lists'))
	drop index [TP_Lists].[X_TP_LISTS_2]
go

declare @sql nvarchar (2000)
if @@Version like '%SQL%Server%2000%' 
 set @sql = 'create index [X_TP_LISTS_2] on [dbo].[TP_Lists] 
	([TI_TOKey]
	,[TI_Key]
	,[TI_DAYS]
	)'
else
 set @sql = 'CREATE NONCLUSTERED INDEX [X_TP_LISTS_2] ON [dbo].[TP_Lists] 
(
     [TI_TOKey] ASC
)
INCLUDE ( [TI_Key],
[TI_DAYS]) 
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'

exec sp_executesql @sql
go

-- sp_SetServiceStatusOK.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetServiceStatusOK]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetServiceStatusOK]
GO
CREATE PROCEDURE [dbo].[SetServiceStatusOK]
	(
		@DLKEY int
	)
AS
BEGIN
	-- теперь в завмсимости от настроек будем менять статусы на Ок
	-- <item>1 - Все услуги</item>
	-- <item>2 - Только перелет</item>
	-- <item>4 - Только отель</item>
	-- <item>7 - То же все</item>
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('1', '2', '3', '5', '6', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		update Dogovorlist
		set DL_CONTROL = 0
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_SvKey = 1 and DL_Control != 0
	end
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('1', '3', '4', '5', '6', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		update Dogovorlist
		set DL_CONTROL = 0
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_SvKey = 3 and DL_Control != 0
	end
	
	
	-- MEG00032041
	-- Теперь проверим есть ли на эту квоту запись в таблице QuotaStatuses
	-- которая говорит нам что нужно изменить статус услуги на тот который в этой таблице
	if exists(select 1 
				from QuotaStatuses join Quotas on QS_QTID = QT_ID 
				join QuotaDetails on QT_ID = QD_QTID
				join QuotaParts on QP_QDID = QD_ID
				join ServiceByDate on SD_QPID = QP_ID
				where SD_DLKey = @DLKEY and SD_State = QS_Type) 
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		declare @DLCONTROL int
		
		select @DLCONTROL = QS_CRKey
		from QuotaStatuses join Quotas on QS_QTID = QT_ID 
		join QuotaDetails on QT_ID = QD_QTID
		join QuotaParts on QP_QDID = QD_ID
		join ServiceByDate on SD_QPID = QP_ID
		where SD_DLKey = @DLKEY and SD_State = QS_Type
	
		update Dogovorlist
		set DL_CONTROL = @DLCONTROL
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_Control != @DLCONTROL
	end
END
GO
grant exec on [dbo].[SetServiceStatusOK] to public
go


-- sp_InsDogList.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsDogList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[InsDogList]
GO
CREATE PROCEDURE [dbo].[InsDogList]
(
--<VERSION>2008.1.003</VERSION>
	@sDogovor varchar(10),
	@dTour datetime,
	@nSvKey int,
	@sService varchar(8000),
	@nDay int,
	@nCode int,
	@nCode1 int,
	@nCode2 int,
	@nNDays int,
	@nCountry int,
	@nCity int,
	@nPartner int,
	@nAgent int,
	@nMen int,
	@nNetto money,
	@nBrutto money,
	@nDiscount money,
	@nPaket int,
	@nTour int,
	@nAttribute int,
	@nControl int,
	@nCreator int,
	@nOwner int,
	@dBeg datetime,
	@dEnd datetime,
	@tTime datetime,
	@p_nIsComtmntFirst int,
	@bRet int OUTPUT,
	@nPrmPlaceNoHave money OUTPUT,
	@dPrmBadDate datetime OUTPUT,
	@nNewKey int OUTPUT,
	@nDGKey int = NULL,
	@sComment varchar(254) = NULL,
	@sFormulaNetto varchar(254) = NULL,
	@sFormulaBrutto varchar(254) = NULL,
	@sFormulaDiscount varchar(254) = NULL,
	@sServiceLat varchar(8000) = NULL,
	@nPrtDog int = NULL,
	@nTaxZone int = NULL,
	@bWait bit = NULL
) AS	
	DECLARE @nKey int
	DECLARE @n int
	DECLARE @nID int
	DECLARE @pName varchar(8000)
	DECLARE @sValue varchar(8000)
	DECLARE @nMain int
	--DECLARE @nWait int
	DECLARE @nLong SMALLint
	-- mv 18-11-2005 MEG00006142 

	select @sComment = case when len(@sComment)> 0 then substring(@sComment,1, len(@sComment)) else null end
	select @sFormulaNetto = case when len(@sFormulaNetto)> 0 then substring(@sFormulaNetto,1, len(@sFormulaNetto)) else null end
	select @sFormulaBrutto = case when len(@sFormulaBrutto)> 0 then substring(@sFormulaBrutto,1, len(@sFormulaBrutto)) else null end
	select @sFormulaDiscount = case when len(@sFormulaDiscount)> 0 then substring(@sFormulaDiscount,1, len(@sFormulaDiscount)) else null end

	If @nDGKey is NULL
		SELECT @nDGKey = DG_KEY FROM tbl_Dogovor where DG_Code = @sDogovor ORDER BY DG_CRDATE DESC
	SELECT @nLong = ISNULL(DG_NDAY,0) FROM tbl_Dogovor where DG_Code = @sDogovor ORDER BY DG_CRDATE DESC
	
	DECLARE @NDL_TimeEnd datetime
	IF @nSvKey=1
		exec [dbo].[MakeFullSVName]
			@nCountry, @nCity, @nSvKey, @nCode, null, 
			@nCode1, @nCode2, 0, @dBeg, null, 
			@sService output, @sServiceLat output, @tTime output, @NDL_TimeEnd output
	
  	set @nPrmPlaceNoHave = 0
	UPDATE KEY_DOGOVORLIST set ID= ID + 1 
	SELECT @nKey = (ID - 1), @nID = ID from KEY_DOGOVORLIST
	IF @@ERROR = 0
	BEGIN
		If @nID >= 2147483646
			Update KEY_DOGOVORLIST set ID = 1
		set @bRet = 1
		set @nNewKey = @nKey
		if @nAgent <= 0
			set @nAgent = 0
		
		--Set @nWait=null --SS_ParmValue from SystemSettings where SS_ParmName = 'SYSSetServiceInWait'
		Insert into tbl_DogovorList (	DL_DgCod,DL_Key,DL_TurDate,DL_DateBeg,DL_DateEnd,
										DL_TimeBeg,DL_SVKey,DL_Name,DL_NameLat,DL_Day,
										DL_Code,DL_SubCode1,DL_SubCode2,DL_NDays,DL_CnKey,
										DL_CtKey,DL_PartnerKey,DL_Agent,DL_Cost,DL_PaketKey,
										DL_Warning,DL_Control,DL_Creator,DL_Owner,DL_Brutto,
										DL_Discount,DL_NMen,DL_Wait,DL_Attribute,DL_TrKey,
										DL_QuoteKey,DL_DGKey, DL_Comment, DL_FormulaNetto, DL_FormulaBrutto, DL_FormulaDiscount,
										DL_Long, DL_PrtDogKey, DL_TaxZoneId)
							Values	(	@sDogovor,@nKey,@dTour,@dBeg,@dEnd,
										@tTime,@nSvKey,@sService,@sServiceLat,@nDay,
										@nCode,@nCode1,@nCode2,@nNDays,@nCountry,
										@nCity,@nPartner,@nAgent,@nNetto,@nPaket,
										0,@nControl,@nCreator,@nOwner,@nBrutto,
										@nDiscount,@nMen,@bWait,@nAttribute,@nTour,
										0,@nDGKey,@sComment,@sFormulaNetto, @sFormulaBrutto, @sFormulaDiscount,
										@nLong,	@nPrtDog, @nTaxZone)
		IF @@ERROR <>0
		BEGIN
			set @bRet = 0
			Return 1
		END
	END	
	return 0

GO
grant exec on [dbo].[InsDogList] to public 
go


-- sp_GenerateStartCode.sql
if not exists (select * from dbo.SystemSettings where SS_ParmName = 'GS_CriticalChanges')
	insert into dbo.SystemSettings (SS_ParmName, SS_ParmValue) values ('GS_CriticalChanges', CAST(FLOOR(CAST(GetDate() as float)) as varchar(20)) )
GO
if not exists (select * from dbo.SystemSettings where SS_ParmName = 'GS_MasterEvents')
	insert into dbo.SystemSettings (SS_ParmName, SS_ParmValue) values ('GS_MasterEvents', CAST(FLOOR(CAST(GetDate() as float)) as varchar(20)) )
GO
if not exists (select * from dbo.SystemSettings where SS_ParmName = 'GS_HistoryPartner')
	insert into dbo.SystemSettings (SS_ParmName, SS_ParmValue) values ('GS_HistoryPartner', CAST(FLOOR(CAST(GetDate() as float)) as varchar(20)) )
GO
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

exec [dbo].[GenerateStartCode]
GO

-- 110222_Create_Table_ReportSettingsByWeb.sql

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReportSettingsByWeb]') AND type in (N'U'))
begin

CREATE TABLE [dbo].[ReportSettingsByWeb](
	[RSW_ID] [int] IDENTITY(1,1) NOT NULL,
	[RSW_ALKEY] [int] NOT NULL,
	[RSW_CHKEY] [int] NULL,
	[RSW_PRKEY] [int] NULL,
	[RSW_RPKEY] [int] NOT NULL,
	[RSW_RPPKEY] [int] NOT NULL,
	[RSW_ViewMode] [int] NOT NULL,
 CONSTRAINT [PK_ReportSettingsByWeb] PRIMARY KEY CLUSTERED 
(
	[RSW_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

end
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ReportSettingsByWeb_Airline]') AND parent_object_id = OBJECT_ID(N'[dbo].[ReportSettingsByWeb]'))
ALTER TABLE [dbo].[ReportSettingsByWeb]  WITH CHECK ADD  CONSTRAINT [FK_ReportSettingsByWeb_Airline] FOREIGN KEY([RSW_ALKEY])
REFERENCES [dbo].[Airline] ([al_key])
GO

ALTER TABLE [dbo].[ReportSettingsByWeb] CHECK CONSTRAINT [FK_ReportSettingsByWeb_Airline]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ReportSettingsByWeb_Charter]') AND parent_object_id = OBJECT_ID(N'[dbo].[ReportSettingsByWeb]'))
ALTER TABLE [dbo].[ReportSettingsByWeb]  WITH CHECK ADD  CONSTRAINT [FK_ReportSettingsByWeb_Charter] FOREIGN KEY([RSW_CHKEY])
REFERENCES [dbo].[Charter] ([CH_KEY])
GO

ALTER TABLE [dbo].[ReportSettingsByWeb] CHECK CONSTRAINT [FK_ReportSettingsByWeb_Charter]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ReportSettingsByWeb_Rep_Profiles]') AND parent_object_id = OBJECT_ID(N'[dbo].[ReportSettingsByWeb]'))
ALTER TABLE [dbo].[ReportSettingsByWeb]  WITH CHECK ADD  CONSTRAINT [FK_ReportSettingsByWeb_Rep_Profiles] FOREIGN KEY([RSW_RPPKEY])
REFERENCES [dbo].[Rep_Profiles] ([RP_Key])
GO

ALTER TABLE [dbo].[ReportSettingsByWeb] CHECK CONSTRAINT [FK_ReportSettingsByWeb_Rep_Profiles]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ReportSettingsByWeb_ReportList]') AND parent_object_id = OBJECT_ID(N'[dbo].[ReportSettingsByWeb]'))
ALTER TABLE [dbo].[ReportSettingsByWeb]  WITH CHECK ADD  CONSTRAINT [FK_ReportSettingsByWeb_ReportList] FOREIGN KEY([RSW_RPKEY])
REFERENCES [dbo].[ReportList] ([RP_KEY])
GO

ALTER TABLE [dbo].[ReportSettingsByWeb] CHECK CONSTRAINT [FK_ReportSettingsByWeb_ReportList]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ReportSettingsByWeb_tbl_Partners]') AND parent_object_id = OBJECT_ID(N'[dbo].[ReportSettingsByWeb]'))
ALTER TABLE [dbo].[ReportSettingsByWeb]  WITH CHECK ADD  CONSTRAINT [FK_ReportSettingsByWeb_tbl_Partners] FOREIGN KEY([RSW_PRKEY])
REFERENCES [dbo].[tbl_Partners] ([PR_KEY])
GO

ALTER TABLE [dbo].[ReportSettingsByWeb] CHECK CONSTRAINT [FK_ReportSettingsByWeb_tbl_Partners]
GO

grant select on [dbo].[ReportSettingsByWeb] to public
go
grant insert on [dbo].[ReportSettingsByWeb] to public
go
grant delete on [dbo].[ReportSettingsByWeb] to public
go
grant update on [dbo].[ReportSettingsByWeb] to public
go



-- sp_RefreshViewForAll.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_RefreshViewForAll]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[sp_RefreshViewForAll]
GO

CREATE PROCEDURE [dbo].[sp_RefreshViewForAll]
@ViewName varchar(50)
AS
BEGIN
	DECLARE @UserName		varchar(128)
	DECLARE @UserID		smallint
	DECLARE @ViewFullName	varchar(128)

	DECLARE curSelectUser CURSOR FOR SELECT UID, Name FROM SYSUsers ORDER BY UID
	OPEN curSelectUser

	FETCH NEXT FROM curSelectUser INTO @UserID, @UserName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (SELECT * FROM SYSObjects WHERE Name = @ViewName AND UID=@UserID AND XType='V')
		BEGIN
			SET @ViewFullName = @UserName + '.' + @ViewName
			if OBJECT_ID(@ViewFullName) is not null
				EXEC sp_refreshview @ViewFullName
		END

		FETCH NEXT FROM curSelectUser INTO @UserID, @UserName
	END

	CLOSE curSelectUser
	DEALLOCATE curSelectUser
END
GO

GRANT EXEC ON [dbo].[sp_RefreshViewForAll] TO PUBLIC
GO

-- sp_RenameDogovor.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RenameDogovor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure dbo.RenameDogovor
GO
CREATE procedure [dbo].[RenameDogovor]
(
	@nReturn int output,
	@sOldDogovor varchar (10),
	@sDogovor varchar (10)
)
AS
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
GO

GRANT EXECUTE ON dbo.RenameDogovor TO PUBLIC 
GO

-- sp_SetServiceQuotasStatus.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetServiceQuotasStatus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetServiceQuotasStatus]
GO

CREATE PROCEDURE [dbo].[SetServiceQuotasStatus]
	(
		@DLKey int
	)
AS
BEGIN
	declare @N_DLSVKey int, @N_DLDateBeg datetime, @N_DLDateEnd datetime, @N_GlobalControl int
	
	select @N_DLSVKey = DL_SVKEY, @N_DLDateBeg = DL_DATEBEG, @N_DLDateEnd = DL_DATEEND, @N_GlobalControl = CR_GlobalState
	from Dogovorlist join Controls on DL_CONTROL = CR_KEY
	where DL_KEY = @DLKey
	
	-- если глобальный статус услуги не Ок, то выходим
	if @N_GlobalControl != 1
	begin
		return 0
	end

	declare @serviceKeys nvarchar(max)	
			
	select @serviceKeys = SS_ParmValue
	from SystemSettings 
	where SS_ParmName = 'SYSNoSetToQuotaIfStatusOk'
	
	if exists (select 1 from [service] where sv_key = @N_DLSVKey) 
		and not exists (select 1 from ParseKeys(@serviceKeys))
	begin
		if isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKey),4) = 4
		begin
			EXEC DogListToQuotas @DLKey, null, null, null, null, @N_DLDateBeg, @N_DLDateEnd, null, null, @SetOkIfRequest = 1
		end
	end
				
	if exists (select 1 from DogovorList where DL_KEY = @DLKey and DL_CONTROL = 0)
	begin
		update ServiceByDate set SD_State = 3 where SD_DLKey = @DLKey and SD_State = 4
	end	
END
GO
grant exec on [dbo].[SetServiceQuotasStatus] to public
go




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
			--set @sql = 'delete from dbo.mwPriceDurations where sd_cnkey = ' + ltrim(rtrim(str(@cnkey))) + ' and sd_ctkeyfrom = ' + ltrim(rtrim(str(@ctkeyfrom))) + ' and not exists(select 1 from ' + @objName + ' where pt_tourkey = sd_tourkey and pt_days = sd_days and pt_nights = sd_nights) and sd_tourkey not in (select to_key from tp_tours where to_update <> 0)'
			--exec sp_executesql @sql
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

-- sp_mwGetServiceIsEditableAttribute.sql
if exists(select id from sysobjects where xtype='p' and name='mwGetServiceIsEditableAttribute')
	drop proc dbo.mwGetServiceIsEditableAttribute
go

create procedure [dbo].[mwGetServiceIsEditableAttribute]
	@tokey int,
	@tscode int,
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
	where ts_tokey='+ltrim(rtrim(str(@tokey)))+' and ts_code='+ltrim(rtrim(str(@tscode)))+' and (ts_attribute&+'+ltrim(rtrim(str(@editableCode)))+')='+ltrim(rtrim(str(@editableCode)))	
	exec (@sql)	
	set @isEditable = @@ROWCOUNT
end

go

grant exec on dbo.[mwGetServiceIsEditableAttribute] to public
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
	while(@@fetch_status=0 and @selected < @pageSize)
	begin
		if @pos >= @pageNum
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
					select @tmpThereAviaQuota=res from #checked where svkey=1 and code=@chkey and date=@tourdate and day=@chday and days=@days and prkey=@chprkey and pkkey=@chpkkey
					if (@tmpThereAviaQuota is null)
					begin
						--kadraliev MEG00025990 03.11.2010 Если в туре запрещено менять рейс, устанавливаем @findFlight = 0
						--kadraliev MEG00032887 10.03.2011 Вынес логику определения признака возможности редактирования услуги
						--в хранимую процедуру mwGetServiceIsEditableAttribute, логика работы которой определяется в момент ее создания с учетом включенной репликации						
						exec dbo.mwGetServiceIsEditableAttribute @pttourkey, @chkey, @isEditableService output
						if (@isEditableService = 0)
							set @findFlight = 0
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
						--kadraliev MEG00025990 03.11.2010 Если в туре запрещено менять рейс, устанавливаем @findFlight = 0						
						--kadraliev MEG00032887 10.03.2011 Вынес логику определения признака возможности редактирования услуги
						exec dbo.mwGetServiceIsEditableAttribute @pttourkey, @chbackkey, @isEditableService output
						if (@isEditableService = 0)
							set @findFlight = 0
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

-- sp_GetServiceLoadListData.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceLoadListData]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceLoadListData]
GO
CREATE procedure [dbo].[GetServiceLoadListData]
(
--<VERSION>2008.1.00.11a</VERSION>
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
SL_SubCode1 int, SL_PRKey int
/*SL_DataType это мнимая колонка, есть только при выводе результата 
содержит тип информации для записей с итогами
(1 - общий итог, 2 - данные по услуге)
*/
)
DECLARE @n int, @nMax int, @str nvarchar(max),@SL_SubCode1 int, @s nvarchar(1), @ServiceName nvarchar(255)
set @n=1 

WHILE @n <= @DaysCount
BEGIN
	set @str = 'ALTER TABLE #ServiceLoadList ADD SL_' + CAST(@n as nvarchar(3)) + ' nvarchar(20)'
	exec (@str)
	set @n = @n + 1
END

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


while exists(select SL_SubCode1 from #ServiceLoadList where SL_ServiceName is null)
BEGIN
	select @SL_SubCode1=SL_SubCode1 from #ServiceLoadList where SL_ServiceName is null
	exec GetSvCode1Name @SVKey,@SL_SubCode1,@s output,@ServiceName output,@s output,@s output
	UPDATE #ServiceLoadList SET SL_ServiceName=@ServiceName where SL_SubCode1=@SL_SubCode1
END

If @bShowByRoom=1
	DECLARE curSLoadList CURSOR FOR SELECT
		'UPDATE #ServiceLoadList SET SL_' + CAST(CAST(SD_Date-@DateStart+1 as int) as nvarchar(5)) + '= ISNULL(SL_' + CAST(CAST(SD_Date-@DateStart+1 as int) as nvarchar(5)) + ',0)+' + CAST(Count(Distinct SD_RLID) as nvarchar(5)) + ' WHERE SL_SubCode1=' + CAST(DL_SubCode1 as nvarchar(10)) + CASE WHEN @bShowByPartner=1 THEN ' AND SL_PRKey=' + CAST(DL_PartnerKey as nvarchar(10)) ELSE '' END + CASE WHEN @bShowState=1 THEN ' AND SL_State=' + CAST(ISNULL(SD_STATE,0) as nvarchar(10)) ELSE '' END
		from	DogovorList,ServiceByDate, Dogovor 
		where	SD_DLKey=DL_Key and DG_Key=DL_DGKey
				and DL_SVKey=@SVKey and DL_Code=@Code 
				and DL_DateBeg<=@DateEnd and DL_DateEnd>=@DateStart
				and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
				and SD_Date<=@DateEnd and SD_Date>=@DateStart
		group by SD_Date,DL_SubCode1,DL_PartnerKey,SD_State
Else
	DECLARE curSLoadList CURSOR FOR SELECT
		'UPDATE #ServiceLoadList SET SL_' + CAST(CAST(SD_Date-@DateStart+1 as int) as nvarchar(5)) + '= ISNULL(SL_' + CAST(CAST(SD_Date-@DateStart+1 as int) as nvarchar(5)) + ',0)+' + CAST(Count(SD_ID) as nvarchar(5)) + ' WHERE SL_SubCode1=' + CAST(DL_SubCode1 as nvarchar(10)) + CASE WHEN @bShowByPartner=1 THEN ' AND SL_PRKey=' + CAST(DL_PartnerKey as nvarchar(10)) ELSE '' END + CASE WHEN @bShowState=1 THEN ' AND SL_State=' + CAST(ISNULL(SD_STATE,0) as nvarchar(10)) ELSE '' END
		from	DogovorList,ServiceByDate, Dogovor 
		where	SD_DLKey=DL_Key and DG_Key=DL_DGKey
				and DL_SVKey=@SVKey and DL_Code=@Code
				and DL_DateBeg<=@DateEnd and DL_DateEnd>=@DateStart
				and ((DL_PartnerKey=@PRKEY) or (@PRKEY is null)) and ((DG_CTDepartureKey=@CityDepartureKey) or (@CityDepartureKey is null))
				and SD_Date<=@DateEnd and SD_Date>=@DateStart
		group by SD_Date,DL_SubCode1,DL_PartnerKey,SD_State

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
set @str = @str + 'SELECT SL_ServiceName, SL_State, SL_SubCode1, SL_PRKey '
WHILE @n <= @DaysCount
BEGIN
	print @str
	set @str = @str + ', SL_' + CAST(@n as nvarchar(3)) 
	set @n = @n + 1
END
/*
Set @str = @str + ' from #QuotaLoadList, Numbers where NU_ID between 1 and 3
and QL_IsQD=0
order by QL_Type,QL_Release,QL_Durations,QL_CityDepartments,QL_FilialKey,QL_CustomerInfo,NU_ID'
*/
Set @str = @str + ' from #ServiceLoadList order by SL_ServiceName, SL_SubCode1, SL_PRKey, SL_State'
exec (@str)
GO
grant exec on GetServiceLoadListData to public
go



-- sp_DogListToQuotas.sql
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
	@SetQuotaDateFirst datetime = null,
	@SetOkIfRequest bit = 0 -- запуск из тригера T_UpdDogListQuota
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

-- сбрасываем статус услуги на тот который указан в справочнике, если хотя бы одна
-- для всех квотируемых услуг
if @SetOkIfRequest = 0
begin
	update Dogovorlist
	set DL_CONTROL = (select top 1 SV_CONTROL from [Service] where DL_SVKEY = SV_KEY)
	from Dogovorlist 
	where DL_KEY = @DLKey
	and DL_Control <> (select top 1 SV_CONTROL from [Service] where DL_SVKEY = SV_KEY)
	and exists (select 1 from [Service] where DL_SVKEY = SV_KEY and SV_QUOTED = 1)
end

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
	begin
		if @SetQuotaType=3
		begin
			exec SetServiceStatusOK @dlkey
		end
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
						-- Разрешим посадить в квоту с релиз периодом 0 текущим числом
						set @DATETEMP = DATEADD(day, -1, @DATETEMP)
						if exists (select SS_ParmValue from systemsettings where SS_ParmName=''SYSCheckQuotaRelease'' and SS_ParmValue=1) OR exists (select SS_ParmValue from systemsettings where SS_ParmName=''SYSAddQuotaPastPermit'' and SS_ParmValue=1)
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
										and (QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1) OR (QD1.QD_Date < getdate() - 1))
								ORDER BY ISNULL(QD_Release,0) DESC, (select count(distinct QD_QTID) 
																	from QuotaDetails as QDP join QuotaParts as QPP on QDP.QD_ID = QPP.QP_QDID
																	where exists (select 1 from @ServiceKeys as SKP where SKP.SK_QPID = QPP.QP_ID)
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
										and (QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1) OR (QD1.QD_Date < getdate() - 1))
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
	--print @Query	
	exec (@Query)
	
	exec SetServiceStatusOK @dlkey

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



-- T_QuotaPartsChange.sql
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_QuotaPartsChange]'))
DROP TRIGGER [dbo].[T_QuotaPartsChange]
GO
CREATE TRIGGER [dbo].[T_QuotaPartsChange]
ON [dbo].[QuotaParts] 
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2008.1.01.03a</VERSION>
IF @@ROWCOUNT > 0
BEGIN
	DECLARE @QO_SVKey int, @QO_Code int, @QT_Id int, @QT_ByRoom bit, @QT_PRKey int, @QT_PrtDogsKey int, @QP_ID int,
			@QD_Type smallint, @QD_Date smalldatetime, @QD_Release smallint,
			@OQP_Places smallint, @OQP_IsDeleted smallint, @OQP_AgentKey int, @OQP_Durations varchar(20), @OQP_IsNotCheckIn bit,
			@NQP_Places smallint, @NQP_IsDeleted smallint, @NQP_AgentKey int, @NQP_Durations varchar(20), @NQP_IsNotCheckIn bit
    DECLARE @sText_Old varchar(255), @sText_New varchar(255), @sHI_Text varchar(255)
    DECLARE @sMod varchar(3), @nDelCount int, @nInsCount int, @nHIID int

	SELECT @nDelCount = COUNT(*) FROM DELETED
	SELECT @nInsCount = COUNT(*) FROM INSERTED
	IF (@nDelCount = 0)
	BEGIN
		SET @sMod = 'INS'
		DECLARE cur_QuotaParts CURSOR LOCAL FOR 
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, 
					QD_Type, QD_Date, QD_Release, N.QP_ID,
					null, null, null, null, null,
					N.QP_Places, N.QP_IsDeleted, N.QP_AgentKey, N.QP_Durations, N.QP_IsNotCheckIn
			FROM	INSERTED N, dbo.Quotas, dbo.QuotaDetails
			WHERE	N.QP_QDID=QD_ID and QD_QTID=QT_ID
	END
	ELSE IF (@nInsCount = 0)
	BEGIN
		SET @sMod = 'DEL'
		DECLARE cur_QuotaParts CURSOR LOCAL FOR 
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, 
					QD_Type, QD_Date, QD_Release, O.QP_ID,
					O.QP_Places, O.QP_IsDeleted, O.QP_AgentKey, O.QP_Durations, O.QP_IsNotCheckIn,
					null, null, null, null, null
			FROM	DELETED O, dbo.Quotas, dbo.QuotaDetails
			WHERE	O.QP_QDID=QD_ID and QD_QTID=QT_ID
	END
	ELSE 
	BEGIN
		SET @sMod = 'UPD'
		DECLARE cur_QuotaParts CURSOR LOCAL FOR
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, 
					QD_Type, QD_Date, QD_Release, N.QP_ID,
					O.QP_Places, O.QP_IsDeleted, O.QP_AgentKey, O.QP_Durations, O.QP_IsNotCheckIn,
					N.QP_Places, N.QP_IsDeleted, N.QP_AgentKey, N.QP_Durations, N.QP_IsNotCheckIn
			FROM	DELETED O, INSERTED N, dbo.Quotas, dbo.QuotaDetails
			WHERE	N.QP_QDID=QD_ID and QT_ID=QD_QTID and O.QP_Id=N.QP_Id
	END

	OPEN cur_QuotaParts
	FETCH NEXT FROM cur_QuotaParts INTO @QT_Id, @QT_ByRoom, @QT_PRKey, @QT_PrtDogsKey, 
					@QD_Type, @QD_Date, @QD_Release, @QP_ID,
					@OQP_Places, @OQP_IsDeleted, @OQP_AgentKey, @OQP_Durations, @OQP_IsNotCheckIn,
					@NQP_Places, @NQP_IsDeleted, @NQP_AgentKey, @NQP_Durations, @NQP_IsNotCheckIn
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OQP_Places, 0) != ISNULL(@NQP_Places, 0) OR
			ISNULL(@OQP_AgentKey, 0) != ISNULL(@NQP_AgentKey, 0) OR
			ISNULL(@OQP_Durations, 0) != ISNULL(@NQP_Durations, 0) OR
			ISNULL(@OQP_IsNotCheckIn, 0) != ISNULL(@NQP_IsNotCheckIn, 0) OR
			ISNULL(@OQP_IsDeleted, 0) != ISNULL(@NQP_IsDeleted, 0)
			)
		BEGIN
			------------Запись в историю--------------------------------------------------------------------
			If @QT_PRKey=0
				Set @sHI_Text='All partners'
			Else
				Select @sHI_Text = PR_Name from Partners where PR_Key=@QT_PRKey
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
			If @QD_Type=2
				SET @sHI_Text='C'
			Else If @QD_Type=1
				SET @sHI_Text='A'
			If @QD_Release is not null
				SET @sHI_Text=@sHI_Text+'('+CAST(@QD_Release as varchar(4))+')'
			Set @sHI_Text=@sHI_Text+' (' + CONVERT(varchar(20),@QD_Date,104)+')'

			IF @NQP_IsDeleted=1 and @OQP_IsDeleted=0
				SET @sMod='DEL'
			EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 13,
							@nTypeCode = @QP_ID,
							@sMod = @sMod,
							@sText = @sText_New,
							@sRemark = @sHI_Text,
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = @QO_SVKey,
							@nCode = @QO_Code
--'', null, 13, @QP_ID, @sMod, @sText_New, '', 0, @sHI_Text, 0, @QO_SVKey, @QO_Code
			SET @sText_Old=''
			SET @sText_New=''

			--------Детализация--------------------------------------------------
			if ISNULL(@OQP_Places, 0) != ISNULL(@NQP_Places, 0)
			begin
				if exists (select 1 from [Service] where SV_Key = @QO_SVKey and isnull(SV_IsDuration, 0) = 0)
				begin
					update QuotaParts
					set QP_CheckInPlaces = @NQP_Places
					where QP_ID = @QP_ID
				end
				EXECUTE dbo.InsertHistoryDetail @nHIID, 13001, @OQP_Places, @NQP_Places, @OQP_Places, @NQP_Places, null, null, 0
			end
			if ISNULL(@OQP_AgentKey, 0) != ISNULL(@NQP_AgentKey, 0)
			BEGIN
				If @OQP_AgentKey is not null
					Select @sText_Old = PR_Name from Partners where PR_Key=@OQP_AgentKey
				If @NQP_AgentKey is not null
					Select @sText_Old = PR_Name from Partners where PR_Key=@NQP_AgentKey
				EXECUTE dbo.InsertHistoryDetail @nHIID, 13002, @sText_Old, @sText_New, @OQP_AgentKey, @NQP_AgentKey, null, null, 0
				SET @sText_Old=''
				SET @sText_New=''
			END
			if ISNULL(@OQP_Durations, 0) != ISNULL(@NQP_Durations, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 13003, @OQP_Durations, @NQP_Durations, null, null, null, null, 0
				SET @sText_Old=''
				SET @sText_New=''
			END
			if ISNULL(@OQP_IsNotCheckIn, 0) != ISNULL(@NQP_IsNotCheckIn, 0)
			BEGIN
				Set @sText_Old=CAST(@OQP_IsNotCheckIn as varchar(1))
				Set @sText_New=CAST(@NQP_IsNotCheckIn as varchar(1))
				EXECUTE dbo.InsertHistoryDetail @nHIID, 13004, @sText_Old, @sText_New, @OQP_IsNotCheckIn, @NQP_IsNotCheckIn, null, null, 0
				SET @sText_Old=''
				SET @sText_New=''
			END
		END
		FETCH NEXT FROM cur_QuotaParts INTO @QT_Id, @QT_ByRoom, @QT_PRKey, @QT_PrtDogsKey, 
					@QD_Type, @QD_Date, @QD_Release, @QP_ID,
					@OQP_Places, @OQP_IsDeleted, @OQP_AgentKey, @OQP_Durations, @OQP_IsNotCheckIn,
					@NQP_Places, @NQP_IsDeleted, @NQP_AgentKey, @NQP_Durations, @NQP_IsNotCheckIn
    END
	CLOSE cur_QuotaParts
	DEALLOCATE cur_QuotaParts
END


GO




-- sp_CleanQuotaDetail.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CleanQuotaDetail]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CleanQuotaDetail]
GO
CREATE PROCEDURE [dbo].[CleanQuotaDetail] 
	(
		@qtId int,
		@dateBeg datetime,
		@dateEnd datetime
	)
AS
BEGIN
	-- сначала удаляем ненужные QuotaDetails на которые нет записи в QuotaParts
	delete StopSales
	from StopSales join QuotaDetails on QD_ID = SS_QDID
	where QD_QTID = @qtId
	and QD_Date between @dateBeg and @dateEnd
	and not exists (select 1 
					from QuotaParts
					where QP_QDID = QD_ID)
					
	delete QuotaDetails
	where QD_QTID = @qtId
	and QD_Date between @dateBeg and @dateEnd
	and not exists (select 1 
					from QuotaParts
					where QP_QDID = QD_ID)
	
	declare @curQdId int
	-- теперь нужно пересчитать количество свободных и занятых мест
	declare curCleanQuotaDetail cursor FORWARD_ONLY for
										select QD_ID
										from QuotaDetails
										where QD_QTID = @qtId
										and QD_Date between @dateBeg and @dateEnd
	OPEN curCleanQuotaDetail
	FETCH NEXT FROM curCleanQuotaDetail INTO @curQdId
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		update QuotaDetails
		set QD_Places = isnull((select SUM(QP_Places) from QuotaParts where QP_QDID = @curQdId),0),
		QD_Busy = isnull((select SUM(QP_Busy) from QuotaParts where QP_QDID = @curQdId),0)
		where QD_ID = @curQdId
		
		
		FETCH NEXT FROM curCleanQuotaDetail INTO @curQdId
	END
	CLOSE curCleanQuotaDetail
	DEALLOCATE curCleanQuotaDetail
END

GO
grant exec on [dbo].[CleanQuotaDetail] to public
go



-- T_ServiceByDateChanged.sql
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_ServiceByDateChanged]'))
DROP TRIGGER [dbo].[T_ServiceByDateChanged]
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
		@nDelCount smallint, @nInsCount smallint, @DLDateBeg datetime, @DLNDays smallint, @QState smallint, @NewQState smallint

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
						SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate, tbl_DogovorList join [Service] on DL_SVKey = SV_KEY WHERE SD_QPID=@O_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1) 
					WHERE QP_ID=@O_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID=@O_SD_QPID) WHERE QP_ID=@O_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(*) FROM ServiceByDate,QuotaParts WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@O_SD_QPID)
				--IF @O_SD_Date = @DLDateBeg
					UPDATE	QuotaParts SET QP_CheckInPlacesBusy=(
						SELECT COUNT(*) FROM ServiceByDate, tbl_DogovorList join [Service] on DL_SVKey = SV_KEY WHERE SD_QPID=@O_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1) 
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
						SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate, tbl_DogovorList join [Service] on DL_SVKey = SV_KEY WHERE SD_QPID=@N_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1) 
					WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID=@N_SD_QPID) WHERE QP_ID=@N_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(*) FROM ServiceByDate,QuotaParts WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@N_SD_QPID)
				--IF @N_SD_Date = @DLDateBeg
					UPDATE	QuotaParts SET QP_CheckInPlacesBusy=(
						SELECT COUNT(*) FROM ServiceByDate, tbl_DogovorList join [Service] on DL_SVKey = SV_KEY WHERE SD_QPID=@N_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1) 
					WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
		END
	END
	IF (ISNULL(@O_SD_STATE, 0) != ISNULL(@N_SD_STATE, 0) or 
		ISNULL(@O_SD_TUKEY,0)!=ISNULL(@N_SD_TUKEY,0)) and ISNULL(@sServiceStatusToHistory, '0') != '0'
	BEGIN
		Select @QState = QS_STATE from QuotedState 
		where QS_DLID = @N_SD_DLKey and ISNULL(QS_TUID,0) = ISNULL(@N_SD_TUKEY,0)
		IF @QState is NULL and @N_SD_DLKey is not NULL
		BEGIN
			Set @QState = 4
			Insert into QuotedState (QS_DLID, QS_TUID, QS_STATE) values (@N_SD_DLKey, @N_SD_TUKEY, @QState)
		END

		Select @NewQState = MAX(SD_STATE) from ServiceByDate 
		where SD_DLKey = @N_SD_DLKey and ISNULL(SD_TUKEY,0) = ISNULL(@N_SD_TUKEY,0)
		
		if @NewQState is null
		 	set @NewQState = 4
		IF @QState <> @NewQState
			IF @N_SD_DLKey is not NULL
				Update QuotedState set QS_STATE = @NewQState where QS_DLID=@N_SD_DLKey and ISNULL(QS_TUID,0)=ISNULL(@N_SD_TUKEY,0)
			ELSE
				IF @O_SD_DLKey is not NULL
					Update QuotedState set QS_STATE = @NewQState where QS_DLID=@O_SD_DLKey and ISNULL(QS_TUID,0)=ISNULL(@N_SD_TUKEY,0)
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




-- sp_QuotaPartsAfterDelete.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotaPartsAfterDelete]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[QuotaPartsAfterDelete]
GO

CREATE PROCEDURE [dbo].[QuotaPartsAfterDelete]
AS
--Процедура освобождает удаленные квоты
--QD_IsDeleted хранит статус, в который требуется поставить услуги, на данный момент находящиеся на данной квоте
--QD_IsDeleted=3 - подтвердить (ВАЖНО подтверждается только те даты которые удаляются)
--QD_IsDeleted=4 - Request (ВАЖНО на Request только те даты которые удаляются)
--QD_IsDeleted=1 - попытка поставить на квоту (ВАЖНО на квоту пробуем поставить место, на всем протяжении услуги, то есть - если это проживание и только один день удаляем из квоты, то место снимается с квоты целиком и пытается сесть снова)

-- ставим внеквоты
update ServiceByDate
set SD_State = 3, SD_QPID = null
where exists (select 1
				from QuotaParts 
				where QP_ID = SD_QPID
				and QP_IsDeleted = 3)
-- ставим на Request
update ServiceByDate
set SD_State = 4, SD_QPID = null
where exists (select 1
				from QuotaParts 
				where QP_ID = SD_QPID
				and QP_IsDeleted in (1, 4))
				
-- запомним ключи которые необходимо удалить
declare @DelQPID table
(
	DQPID int,
	DQDID int,
	DQD_IsDeleted int,
	DQ_DLKey int
)

insert into @DelQPID (DQPID, DQDID, DQD_IsDeleted, DQ_DLKey)
select QP_ID, QP_QDID, QP_IsDeleted, SD_DLKey
from QuotaParts left join ServiceByDate on SD_QPID = QP_ID
where QP_IsDeleted in (1,3,4)

-- удаляем
DELETE FROM QuotaLimitations WHERE QL_QPID in (SELECT DQPID FROM @DelQPID)
DELETE FROM QuotaParts WHERE QP_ID in (SELECT DQPID FROM @DelQPID)
-- только те QuotaDetails которые есть в нашем списке и на них нету записей в QuotaParts
DELETE FROM QuotaDetails 
WHERE QD_ID in (SELECT DQDID FROM @DelQPID)
and not exists (select 1 from QuotaParts where QP_QDID = QD_ID)

DELETE FROM StopSales 
WHERE SS_QDID in (SELECT DQDID FROM @DelQPID)
and not exists (select 1 from QuotaDetails where QD_ID = SS_QDID)

-- пробуем сажать
DECLARE @SD_DLKey int
DECLARE cur_QuotaPartsDelete CURSOR FORWARD_ONLY FOR
	select distinct DQ_DLKey
	from @DelQPID
	where DQD_IsDeleted = 1
	and DQ_DLKey is not null
	
OPEN cur_QuotaPartsDelete
FETCH NEXT FROM cur_QuotaPartsDelete INTO @SD_DLKey
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC dbo.DogListToQuotas @SD_DLKey, 1
	FETCH NEXT FROM cur_QuotaPartsDelete INTO @SD_DLKey
END
CLOSE cur_QuotaPartsDelete
DEALLOCATE cur_QuotaPartsDelete
GO

grant exec on [dbo].[QuotaPartsAfterDelete] to public
go




-- T_RoomNumberLists.sql
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_RoomNumberLists]'))
DROP TRIGGER [dbo].[T_RoomNumberLists]
GO

CREATE TRIGGER [dbo].[T_RoomNumberLists]
   ON  [dbo].[RoomNumberLists]
   AFTER INSERT, UPDATE
AS 
BEGIN
	update dbo.TuristService
	set TU_NUMROOM = RL_Number
	from TuristService join ServiceByDate on SD_DLKey = TU_DLKEY and SD_TUKey = TU_TUKEY
	join inserted on SD_RLID = RL_ID
	where TU_NUMROOM != RL_Number
END
GO


-- sp_SetDogovorRequest.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetDogovorRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[SetDogovorRequest]
GO

CREATE procedure [dbo].[SetDogovorRequest] @dgKey int
as
begin
	declare @dlKey int, @dlDateBeg datetime, @dlDateEnd datetime
	declare dogovorListsCursor cursor local fast_forward for
	select DL_Key, DL_DateBeg, DL_DateEnd from tbl_DogovorList with(nolock) where DL_DGKey = @dgKey
	
	open dogovorListsCursor
	fetch next from dogovorListsCursor into @dlKey, @dlDateBeg, @dlDateEnd
	while @@FETCH_STATUS = 0
	begin
		print @dlKey
		EXEC DogListToQuotas @dlKey, null, null, null, null, @dlDateBeg, @dlDateEnd, null, 4
		fetch next from dogovorListsCursor into @dlKey, @dlDateBeg, @dlDateEnd
	end
	close dogovorListsCursor
	deallocate dogovorListsCursor
end
GO

grant execute on [dbo].[SetDogovorRequest] to public 
GO

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

		if(@mwSinglePrice != '0' and @enabled > 0)
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
		end -- if(@mwSinglePrice != '0' and @enabled > 0)


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
						set @sql = @sql + ' and ((pt.pt_isenabled > 0 and
				pt_tourkey != ' + ltrim(str(@tourkey)) + ') or pt_tourkey = ' + ltrim(str(@tourkey)) + ')'

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
		declare @viewName nvarchar(100)
		if (@mwSearchType = 0)
			set @viewName = 'dbo.mwPriceTable'
		else
			set @viewName = dbo.mwGetPriceViewName(@countryKey, @cityFromKey)

		set @sql = '
		update dbo.mwSpoDataTable with (rowlock)
		set sd_isenabled = 0
		where sd_cnkey = ' + ltrim(rtrim(str(@countryKey))) + ' and sd_ctkeyfrom = ' + ltrim(rtrim(str(@cityFromKey))) + ' and 
			(exists (select 1 from #tmpTours where sd_tourkey = tourkey) or sd_tourkey = ' + ltrim(str(@tourkey)) + ') and not exists(select 1 from ' + @viewName + '
			where pt_cnkey = sd_cnkey
				and pt_ctkeyfrom = sd_ctkeyfrom
				and pt_tourkey = sd_tourkey
				and pt_hdkey = sd_hdkey
				and pt_pnkey = sd_pnkey
				and (exists (select 1 from #tmpTours where sd_tourkey = tourkey) or sd_tourkey = ' + ltrim(str(@tourkey)) + '))'
		exec(@sql)
	end
end
go

grant exec on dbo.mwEnablePriceTour to public
go

-- (110311)Insert_Descriptions.sql
declare @dskey int
select @dskey = ((select max(ds_key) from descriptions)+1)

if not exists(select ds_key from descriptions where ds_dtkey = 128)
begin
insert into descriptions (ds_key,ds_pkkey,ds_value,ds_tableid,ds_dtkey) 
	values (@dskey,0,'<RegForm><RegFormItem ID="CompanyName" Text="Название агентства (торговая марка):" Required="true" Visible="true" Error="Название агенства должно быть указано." Length="50" /><RegFormItem ID="ChainName" Text="Название сети (если агентство входит в сеть):" Required="false" Visible="false" Error="" Length="50" /><RegFormItem ID="JuridicalName" Text="Полное юридическое название агентства (вместе с юр. статусом: ООО, ЗАО и т.п.):" Required="true" Visible="true" Error="Полное название агенства должно быть указано." Length="50" /><RegFormItem ID="RepresentativeManagerName" Text="ФИО представителя компании:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="Login" Text="Логин для доступа к системе онлайн (присваевается самостоятельно):" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="Password" Text="Пароль для доступа к системе онлайн (присваевается самостоятельно):" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="ManagerName" Text="ФИО руководителя:" Required="true" Visible="true" Error="" Length="100" /><RegFormItem ID="ManagerPosition" Text="Должность руководителя:" Required="false" Visible="true" Error="" Length="50" /><RegFormItem ID="JuridicalAddress" Text="Юридический адрес:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="Country" Text="Страна:" Required="true" Visible="true" Error="" Length="20" /><RegFormItem ID="City" Text="Город:" Required="true" Visible="true" Error="Город и индекс должны быть указаны." Length="30" /><RegFormItem ID="Address" Text="Адрес местонахождения:" Required="true" Visible="true" Error="" Length="250" /><RegFormItem ID="Phone" Text="Телефон:" Required="true" Visible="true" Error="Телефон и код города должны быть указаны." Length="50" /><RegFormItem ID="Fax" Text="Факс:" Required="false" Visible="true" Error="" Length="20" /><RegFormItem ID="EMail" Text="E-mail:" Required="true" Visible="true" Error="Должен быть указан корректный e-mail." Length="50" /><RegFormItem ID="INN" Text="ИНН:" Required="true" Visible="true" Error="Должен быть указан корректный ИНН." Length="15" /><RegFormItem ID="KPP" Text="КПП:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="UnitarySystem" Text="Система налогообложения:" Required="true" Visible="false" Error="" Length="50" /><RegFormItem ID="SettlementAccount" Text="р/с:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="CorrespondentAccount" Text="к/с:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="BankName" Text="Наименование Банка:" Required="true" Visible="true" Error="" Length="80" /><RegFormItem ID="BIK" Text="БИК:" Required="true" Visible="true" Error="" Length="20" /><RegFormItem ID="OGRN" Text="ОГРН:" Required="true" Visible="false" Error="" Length="50" /><RegFormItem ID="OKATO" Text="ОКАТО:" Required="false" Visible="false" Error="" Length="50" /><RegFormItem ID="OKPO" Text="ОКПО:" Required="false" Visible="false" Error="" Length="20" /></RegForm>',43,128)
end
GO

-- q_mwUpdatePrttypesToParners.sql
declare @ptid smallint
select @ptid = pt_id from prttypes with (nolock) where pt_name = 'Дает клиентов'

insert into prttypestopartners(ptp_prkey, ptp_ptid)
select distinct us_prkey, @ptid 
from dup_user with(nolock)
inner join tbl_partners with(nolock) on us_prkey = pr_key 
where us_reg > 0 and us_turagent > 0 
	  and not exists(select top (1) 1 from prttypestopartners where ptp_prkey = pr_key and ptp_ptid = @ptid)
GO

-- sp_mwGetFullHotelNames.sql
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

if exists(select id from sysobjects where name='mwGetFullHotelNames' and xtype='fn')
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
					else '<a href=''' + ltrim(rtrim(hd_http)) + ''' target=''_blank''>' + isnull(hd_name, '') + '&nbsp;' + (case @showStars when 0 then '' else isnull(hd_stars, '') end) + '</a>'
					end
				+ case @hotelOnly 
					when 0 then '&nbsp;(' + isnull(rs_name, ct_name) + '),&nbsp;' + (case @fullPansionName when 0 then isnull(pn_code, '') else isnull(pn_name, '') end) 
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

-- alter_view_Quotes.sql
--MEG00029352 kadraliev 26.01.2011 Изменил выборку данных о квотах
GO

/****** Object:  View [dbo].[Quotes]    Script Date: 01/26/2011 12:17:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[Quotes]
AS
SELECT   
	q.QT_PRKey,
	qo.QO_SVKey AS qt_svkey, qo.QO_SubCode1 AS qt_subcode1, qo.QO_SubCode2 AS subcode2, qo.QO_Code AS qt_code,
	qd.QD_Date AS qt_date, qd.QD_Places AS qt_places, qd.QD_Busy AS qt_busy,
	qp.QP_AgentKey AS qt_agent
FROM        Quotas q
INNER JOIN QuotaObjects qo ON qo.QO_QTID = q.QT_ID
INNER JOIN QuotaDetails qd ON qd.QD_QTID = q.QT_ID 
INNER JOIN QuotaParts qp ON qp.QP_QDID = qd.QD_ID
GO




-- sp_MakePutName.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MakePutName]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[MakePutName]
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
	
	declare @format varchar(50), @constFormat varchar(50)
	select @format = REPLACE(ST_FormatDogovor, ' ', '(') from Setting
	set @constFormat = @format
	
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
	
	declare @temp varchar(50), @ch varchar(1), @str varchar(50)		
	set @ch = substring(@format, 1, 1)
	
	while @ch != ''
	begin
		set @str = ''
		
		set @ch = substring(@format, 1, 1)
		--select substring(@format, 1, 1), LEN(substring(@format, 1, 1))
		
		if @format != ''
			set @format = substring(@format, 2, len(@format) - 1)
		
		set @temp = @temp + @chPrev
		
		if (@ch != @chPrev or @format = '') and (LEN(@ch) > 0 or (@chPrev = '9' or @chPrev = '#'))
		begin
			--select @temp, @format, @chPrev, @ch, LEN(@ch)
			
			if @format = '' and (@ch = @chPrev) and (@ch != '9' and @ch != '#')
				set @len = LEN(@temp) + 1
			else
				set @len = LEN(@temp)
			
			if @chPrev = 'N'
			begin
				select @str = UPPER(LEFT(LTRIM(TL_Name), @len)) from tbl_TurList where TL_Key = @tourKey
				exec dbo.FillString @str output, @len, 'n'
			end 
			else if @chPrev = 'T'
			begin
				select @str = UPPER(isnull(LEFT(CT_Code, @len), '')) from CityDictionary where CT_Key = @cityKey
				exec dbo.FillString @str output, @len, 't'				
			end
			else if @chPrev = 'C'
			begin
				select @str = UPPER(isnull(LEFT(CN_Code, @len),isnull(LEFT(CN_NameLat, @len), ''))) from Country where CN_Key = @countryKey
				exec dbo.FillString @str output, @len, 'c'
			end
			else if @chPrev = 'P'
			begin
				select @str = UPPER(isnull(LEFT(PR_Cod, @len),'')) from Partners where PR_Key = @partnerKey
				exec dbo.FillString @str output, @len, 'p'
			end
			else if @chPrev = 'Y'
				set @str = RIGHT(STR(YEAR(@date)), @len)
			else if @chPrev = 'D'
			begin
				set @temp = LTRIM(STR(DATEPART(dd, @date)))
				if LEN(@temp) < 2
					set @temp = '0' + @temp
				set @str = @temp
			end
			else if @chPrev = 'M'
			begin
				set @temp = LTRIM(STR(DATEPART(mm, @date)))
				if LEN(@temp) < 2
					set @temp = '0' + @temp
				set @str = @temp	
			end
			else if @chPrev = '('
			begin
				set @str = ' '
			end
			if @chPrev = '9' or @chPrev = '#'
			begin
				if(@chPrev = '9')
					set @temp = REPLICATE('[0-9]', @len)
				else
					set @temp = REPLICATE('_', @len)
				declare @searchName varchar(50)
				
				set @searchName = @name + @temp + '%'

				select @str = max(DG_Code) from tbl_Dogovor where LEN(DG_Code) = LEN(@constFormat) and upper(DG_Code) like upper(@searchName) and ((DG_TurDate >= @selectDate) or (DG_TurDate is null) or (DG_TurDate = @nullDate))
				if @str is null
					set @str = ''
				--select @str
				if @str != ''
				begin
					set @str = substring(@str, LEN(@name) + 1, @len)
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
					set @str = Upper(dbo.NextStr(@str, @len))
				end
			end
			
			set @temp = ''
		end
		
		set @name = @name + @str
		set @chPrev = @ch
		--select @name
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
grant exec on [dbo].[MakePutName] to public
go



-- Version92.sql
-- для версии 2009.2
update [dbo].[setting] set st_version = '9.2.9', st_moduledate = convert(datetime, '2011-01-22', 120),  st_financeversion = '9.2.9', st_financedate = convert(datetime, '2011-01-22', 120) where st_version like '9.%'
GO
UPDATE dbo.SystemSettings SET SS_ParmValue='2011-01-22' WHERE SS_ParmName='SYSScriptDate'
GO

set nocount on
-- (11.04.22)Update_PrtBonuses.sql
-- выравниваем состояние в таблицах с бонусами
UPDATE	dbo.PrtBonuses
SET	PB_TotalRating = (SELECT SUM(isnull(PBD_Rating, 0)) FROM dbo.PrtBonusDetails WHERE PBD_PBId = PB_ID),
PB_TotalBonus = (SELECT SUM(isnull(PBD_Bonus, 0)) FROM dbo.PrtBonusDetails WHERE PBD_PBId = PB_ID),
PB_TotalExpense = (SELECT SUM(isnull(PBD_Expense, 0)) FROM dbo.PrtBonusDetails WHERE PBD_PBId = PB_ID)
GO

-- (11.04.22)UpdateQuotaPartsAndQuotaDetails.sql
ALTER TABLE [dbo].[QuotaParts] DISABLE TRIGGER [T_QuotaPartsChange]
GO
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_QuotaDetailsChange]'))
	ALTER TABLE [dbo].[QuotaDetails] DISABLE TRIGGER [T_QuotaDetailsChange]
GO

UPDATE	QuotaParts 
SET QP_Busy = (SELECT COUNT(*) 
				FROM ServiceByDate join RoomPlaces on RP_ID = SD_RPID 
				WHERE SD_QPID = QP_ID and RP_Type = 0)
GO			
			
UPDATE  QuotaDetails 
SET QD_Busy = (SELECT COUNT(*) 
				FROM QuotaParts, ServiceByDate join RoomPlaces on RP_ID = SD_RPID  
				WHERE SD_QPID = QP_ID and QP_QDID = QD_ID and RP_Type = 0)
GO
				
UPDATE	QuotaParts 
SET QP_CheckInPlacesBusy = (SELECT COUNT(*) 
							FROM ServiceByDate join RoomPlaces on RP_ID = SD_RPID,
							tbl_DogovorList join [Service] on DL_SVKey = SV_KEY
							WHERE SD_QPID = QP_ID
							and SD_DATE = DL_DATEBEG
							AND SD_DLKey = DL_Key 
							and isnull(SV_IsDuration, 0) = 1
							and RP_Type = 0)
WHERE QP_CheckInPlaces IS NOT NULL
GO
ALTER TABLE [dbo].[QuotaParts] ENABLE TRIGGER [T_QuotaPartsChange]
GO
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_QuotaDetailsChange]'))
	ALTER TABLE [dbo].[QuotaDetails] ENABLE TRIGGER [T_QuotaDetailsChange]
GO

-- fn_DogovorListRequestStatus.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogovorListRequestStatus]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[DogovorListRequestStatus]
GO

CREATE function [dbo].[DogovorListRequestStatus](@dlKey int) returns int
begin
	--	1,2  на квоте 		- зеленый
	--	3     если на OK целиком	- голубой
	--	4     на RQ целиком	- розовый
	declare @status int

	-- если партнер по этой услуги закачивается из интерлука, то возвращаем статус Ок
	declare @PartnertKeys nvarchar(max)	
	select @PartnertKeys = SS_ParmValue
	from SystemSettings
	where SS_ParmName = 'IL_SyncILPartners'
						
	if ( exists (select 1
					from DogovorList
					where DL_Key = @dlKey
					and PATINDEX('%/' + convert(nvarchar(max), DL_PARTNERKEY) + '/%', @PartnertKeys) > 0))
	begin
			set @status = 1
	end
	else
	begin
		select @status = max(isnull(SD_State,4))
		from ServiceByDate with(nolock)
		where SD_DLKey = @dlKey
		--SELECT  @status =	CASE (SELECT 	COUNT(DISTINCT ISNULL(NULLIF(SD_State,2),1)) 
		--				FROM 	ServiceByDate with(nolock)
		--				WHERE 	SD_DLKey = @dlKey)
		--		WHEN 	1  THEN (SELECT TOP 1 SD_State FROM ServiceByDate WHERE SD_DLKey = @dlKey)
		--		ELSE 	0	
		--		END
	end

	return @status
end

GO

grant exec on [dbo].[DogovorListRequestStatus] to public
go

-- sp_SetStatusInRoom.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetStatusInRoom]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetStatusInRoom]
GO

CREATE PROCEDURE [dbo].[SetStatusInRoom] 
	(
		@DlKey int
	)
AS
BEGIN
	/*
	Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	1. Если "Осн" в состоянии "Ок", "А", или "С" - тогда "доп" - в "Ок".
	2. Если "Осн" в "RQ" - тогда доп - в "RQ".
	*/
	update ServiceByDate
	set SD_State = 3
	from ServiceByDate as SBD1 join RoomPlaces as RP1 on SBD1.SD_RPID = RP1.RP_ID
	where RP1.RP_Type = 1
	and ISNULL((select MAX (SD_State)
					from ServiceByDate as SBD2 join RoomPlaces as RP2 on SBD2.SD_RPID = RP2.RP_ID
					where RP2.RP_Type = 0
					and SBD2.SD_RLID = SBD1.SD_RLID), 4) < 4
	and SBD1.SD_RLID in (select SBD3.SD_RLID
							from ServiceByDate as SBD3
							where SBD3.SD_DLKey = @DlKey)

	update ServiceByDate
	set SD_State = 4
	from ServiceByDate as SBD1 join RoomPlaces as RP1 on SBD1.SD_RPID = RP1.RP_ID
	where RP1.RP_Type = 1
	and ISNULL((select MAX (SD_State)
					from ServiceByDate as SBD2 join RoomPlaces as RP2 on SBD2.SD_RPID = RP2.RP_ID
					where RP2.RP_Type = 0
					and SBD2.SD_RLID = SBD1.SD_RLID), 4) = 4
	and SBD1.SD_RLID in (select SBD3.SD_RLID
							from ServiceByDate as SBD3
							where SBD3.SD_DLKey = @DlKey)
END

GO

grant exec on [dbo].[SetStatusInRoom] to public
go


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
	@nUseHolidayRule smallint		-- Правило выходного дня: 0 - не использовать, 1 - использовать
  )
AS
--<DATE>2010-11-03</DATE>
---<VERSION>7.2.39.1</VERSION>
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
declare @tpPricesCount int
declare @isPriceListPluginRecalculation smallint
select @tpPricesCount = count(1) from tp_prices with(nolock) where tp_tokey = @nPriceTourKey
if (@tpPricesCount <> 0 and @nUpdate = 0)
begin
	set @isPriceListPluginRecalculation = 1
	update tp_turdates set td_update = 0 where td_tokey = @nPriceTourKey
	update tp_lists set ti_update = 0 where ti_tokey = @nPriceTourKey
end
else
	set @isPriceListPluginRecalculation = 0

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
		insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_TourKey, CP_UserKey, CP_Status, CP_UseHolidayRule)
		values (@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @TrKey, @userKey, 1, @nUseHolidayRule)
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

	--Настройка (использовать связку обсчитанных цен с текущими ценами, пока не реализована)
	select @sUseServicePrices = SS_ParmValue from systemsettings with(nolock) where SS_ParmName = 'UseServicePrices'

	If @nUpdate=0
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days)
		select distinct TO_Key, TD_Date + TS_Day - 1, TS_Code, TS_OpPartnerKey,
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock), TP_Lists with(nolock), TP_ServiceLists with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TI_TOKey = TO_Key and TL_TOKey = TO_Key and TL_TSKey = TS_Key and TL_TIKey = TI_Key and TO_Key = @nPriceTourKey
	Else
	BEGIN
		select distinct TO_Key, TD_Date + TS_Day - 1 flight_day, TS_Code , TS_OpPartnerKey,	TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days
		into #tp_flights
		from TP_Tours with(nolock) join TP_Services with(nolock) on TO_Key = TS_TOKey and TS_SVKey = 1
			join TP_ServiceLists with(nolock) on TL_TSKey = TS_Key and TS_TOKey = TO_Key
			join TP_Lists with(nolock) on TL_TIKey = TI_Key and TI_TOKey = TO_Key
			join TP_TurDates with(nolock) on TD_TOKey = TO_Key
		where TO_Key = @nPriceTourKey
		
		delete from #tp_flights where exists (Select 1 From TP_Flights with(nolock) Where TF_TOKey=@nPriceTourKey and TF_Date=flight_day
			and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
			and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = TI_Days)
	
		insert into dbo.TP_Flights (TF_TOKey, TF_Date, TF_CodeOld, TF_PRKeyOld, TF_PKKey, TF_CTKey, TF_SubCode1, TF_SubCode2, TF_Days)
		select * from #tp_flights
	END

--------------------------------------- ищем подходящий перелет, если стоит настройка подбора перелета --------------------------------------

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
	--Update	TP_Flights with(rowlock) Set 	TF_CodeNew = TF_CodeOld,
	--			TF_PRKeyNew = TF_PRKeyOld
	--Where	(SELECT count(*) FROM AirSeason  with(nolock) WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') > 0 
	--	and TF_TOKey = @nPriceTourKey	
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey and TF_Date BETWEEN CS_Date AND  CS_DateEnd and (ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long))
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
								AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
								(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and
								(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long)
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
									AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
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
									TF_Date BETWEEN CS_Date AND  CS_DateEnd AND
									AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
									(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and
									(CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long)
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

		declare @calcPricesCount int, @calcPriceListCount int, @calcTurDates int
		select @calcPriceListCount = COUNT(1) from TP_Lists with(nolock) where TI_TOKey = @nPriceTourKey and TI_UPDATE = @nUpdate
		select @calcTurDates = COUNT(1) from TP_TurDates with(nolock) where TD_TOKey = @nPriceTourKey and TD_UPDATE = @nUpdate
		select @calcPricesCount = @calcPriceListCount * @calcTurDates

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
						else if (@isPriceListPluginRecalculation = 0)
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
					ELSE
					BEGIN
						delete from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant
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
								TF_Date = @servicedate AND
								TF_Days = @TI_DAYS
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

	Return 0
END

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

GRANT EXEC ON [dbo].[CalculatePriceList] TO PUBLIC
GO

-- sp_DogListToQuotas.sql
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
	@SetQuotaDateFirst datetime = null,
	@SetOkIfRequest bit = 0 -- запуск из тригера T_UpdDogListQuota
) AS

--insert into Debug (db_n1, db_n2, db_n3) values (@DLKey, @SetQuotaType, 999)
declare @SVKey int, @Code int, @SubCode1 int, @PRKey int, @AgentKey int, @DgKey int,
		@TourDuration int, @FilialKey int, @CityDepartment int,
		@ServiceDateBeg datetime, @ServiceDateEnd datetime, @Pax smallint, @IsWait smallint,@SVQUOTED smallint

SELECT	@SVKey=DL_SVKey, @Code=DL_Code, @SubCode1=DL_SubCode1, @PRKey=DL_PartnerKey, 
		@ServiceDateBeg=DL_DateBeg, @ServiceDateEnd=DL_DateEnd, @Pax=DL_NMen,
		@AgentKey=DG_PartnerKey, @TourDuration=DG_NDay, @FilialKey=DG_FilialKey, @CityDepartment=DG_CTDepartureKey, @IsWait=ISNULL(DL_Wait,0),
		@DgKey = DL_DGKEY
FROM	DogovorList, Dogovor 
WHERE	DL_DGKey=DG_Key and DL_Key=@DLKey

if @IsWait=1 and (@SetQuotaType in (1,2) or @SetQuotaType is null)  --Установлен признак "Не снимать квоту при бронировании". На квоту не ставим
BEGIN
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
		exec SetStatusInRoom @dlkey
	-- запускае хранимку на установку статуса путевки
	exec SetReservationStatus @DgKey
	return 0
END
SELECT @SVQUOTED=isnull(SV_Quoted,0) from service where sv_key=@SVKEY
if @SVQUOTED=0
BEGIN
	UPDATE ServiceByDate SET SD_State=3 WHERE SD_DLKey=@DLKey	
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
		exec SetStatusInRoom @dlkey
	-- запускае хранимку на установку статуса путевки
	exec SetReservationStatus @DgKey
	return 0
END

-- ДОБАВЛЕНА НАСТРОЙКА ЗАПРЕЩАЮЩАЯ СНЯТИЕ КВОТЫ ДЛЯ УСЛУГИ, 
-- ТАК КАК В КВОТАХ НЕТ РЕАЛЬНОЙ ИНФОРМАЦИИ, А ТОЛЬКО ПРИЗНАК ИХ НАЛИЧИЯ (ПЕРЕДАЕТСЯ ИЗ INTERLOOK)
IF (@SetQuotaType in (1,2) or @SetQuotaType is null) and  EXISTS (SELECT 1 FROM dbo.SystemSettings WHERE SS_ParmName='IL_SyncILPartners' and SS_ParmValue LIKE '%/' + CAST(@PRKey as varchar(20)) + '/%')
BEgin
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
		exec SetStatusInRoom @dlkey
	-- запускае хранимку на установку статуса путевки
	exec SetReservationStatus @DgKey
	return 0
End

-- сбрасываем статус услуги на тот который указан в справочнике, если хотя бы одна
-- для всех квотируемых услуг
if @SetOkIfRequest = 0
begin
	update Dogovorlist
	set DL_CONTROL = (select top 1 SV_CONTROL from [Service] where DL_SVKEY = SV_KEY)
	from Dogovorlist 
	where DL_KEY = @DLKey
	and DL_Control <> (select top 1 SV_CONTROL from [Service] where DL_SVKEY = SV_KEY)
	and exists (select 1 from [Service] where DL_SVKEY = SV_KEY and SV_QUOTED = 1)
end
-- проверим если это доп место в комнате, то ее нельзя посадить в квоты, сажаем внеквоты и эта квота за человека
if ( exists (select 1 from ServiceByDate join RoomPlaces on SD_RPID = RP_ID where SD_DLKey = @DLKey and RP_Type = 1) and (@SetQuotaByRoom = 0))
begin
	set @SetQuotaType = 3
end

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
	begin
		if @SetQuotaType=3
		begin
			exec SetServiceStatusOK @dlkey
		end
		-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
		if @SetQuotaByRoom = 0
			exec SetStatusInRoom @dlkey
		-- запускае хранимку на установку статуса путевки
		exec SetReservationStatus @DgKey
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
						-- Разрешим посадить в квоту с релиз периодом 0 текущим числом
						set @DATETEMP = DATEADD(day, -1, @DATETEMP)
						if exists (select SS_ParmValue from systemsettings where SS_ParmName=''SYSCheckQuotaRelease'' and SS_ParmValue=1) OR exists (select SS_ParmValue from systemsettings where SS_ParmName=''SYSAddQuotaPastPermit'' and SS_ParmValue=1)
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
										and (QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1) OR (QD1.QD_Date < getdate() - 1))
								ORDER BY ISNULL(QD_Release,0) DESC, (select count(distinct QD_QTID) 
																	from QuotaDetails as QDP join QuotaParts as QPP on QDP.QD_ID = QPP.QP_QDID
																	where exists (select 1 from @ServiceKeys as SKP where SKP.SK_QPID = QPP.QP_ID)
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
										and (QD1.QD_Date > @DATETEMP+ISNULL(QD1.QD_Release,-1) OR (QD1.QD_Date < getdate() - 1))
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
	--print @Query	
	exec (@Query)
	
	exec SetServiceStatusOK @dlkey
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
		exec SetStatusInRoom @dlkey

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
-- запускае хранимку на установку статуса путевки
exec SetReservationStatus @DgKey
GO
grant exec on [dbo].[DogListToQuotas] to public
go



-- sp_GetPartnerCommission.sql
if EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[GetPartnerCommission]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[GetPartnerCommission]
GO

CREATE PROCEDURE [dbo].[GetPartnerCommission] 
     @nTLKey int,
     @nPRKey int,
     @nBTKey int,
     @nDSKey int output,
     @nValue money output,
     @nIsPercent int output, 
	 @dCheckinDate datetime,
	 @nCNKey int=0,
	 @DGCreateDate datetime = null,
	 @nDepartureCity int = 0,
	 @sDiscountCode varchar(5) = null,
	 @sDiscountNumber varchar(10) = null,
	 @price decimal(16,6) = null,
	 @rate varchar(3) = null,
	 @dogovorCode varchar(10) = null
AS
	declare @discountSettingValue varchar(256)
	select @discountSettingValue = ISNULL(SS_ParmValue, '0') from dbo.SystemSettings where SS_ParmName like 'SYSUseDiscountCards'
	if @discountSettingValue = '1' and ISNULL(@sDiscountCode, '') != '' and ISNULL(@sDiscountNumber, '') != ''
	begin
		
		declare @discountCode varchar(5)
		declare @discountNumber varchar(10)
		declare @reservationsCount int, @cardKey int
		declare @reservationsPrice decimal(16,6)
		declare @nationalRate varchar(3)
		declare @discount money
		declare @discountId int

		if (ISNULL(@dogovorCode, '') = '')
		begin
			set @sDiscountCode = rtrim(ltrim(@sDiscountCode))
			set @sDiscountNumber = rtrim(ltrim(@sDiscountNumber))
				
			select @cardKey = CD_Key from Cards where ISNULL(CD_Code, '') = ISNULL(@sDiscountCode, '') and ISNULL(CD_Number, '') = ISNULL(@sDiscountNumber, '')
			select @reservationsCount = count(RR_ID) from ReservationsRegister where RR_CardKey = @cardKey
			select @reservationsPrice = sum(DG_NationalCurrencyPrice) from Dogovor where DG_CODE in (select RR_DGCODE  COLLATE Cyrillic_General_CI_AS from ReservationsRegister where RR_CardKey = @cardKey)
			select @nationalRate = RA_Code from dbo.Rates where RA_National = 1
			exec ExchangeCost @price output, @rate, @nationalRate, @dCheckinDate

			set @reservationsPrice = ISNULL(@reservationsPrice, 0)
		
			select top 1 @discount = cast(ISNULL(DS_DISCOUNT, 0) as money), @discountId = DS_ID  
				from dbo.DiscountScheme, dbo.TurList, dbo.TurService where 
				TL_Key = @nTLKey and 
				TS_TRKey = TL_Key and
				DS_Series like @sDiscountCode and
				((DS_CityFromKey is not null and DS_CityFromKey = TL_CTDepartureKey) or (DS_CityFromKey is null)) and
				((DS_CountryKey is not null and DS_CountryKey = TL_CNKey) or (DS_CountryKey is null)) and
				((DS_CityKey is not null and DS_CityKey = TS_CTKey) or (DS_CityKey is null)) and
				((DS_TourTypeKey is not null and DS_TourTypeKey = TL_TIP) or (DS_TourTypeKey is null)) and
				((DS_ReservationsFrom is not null and DS_ReservationsFrom <= (@reservationsCount + 1)) or (DS_ReservationsFrom is null)) and
				((DS_ReservationsTo is not null and DS_ReservationsTo >= (@reservationsCount + 1)) or (DS_ReservationsTo is null)) and
				((DS_TotalCostFrom is not null and DS_TotalCostFrom <= (@reservationsPrice + @price)) or (DS_TotalCostFrom is null)) and
				((DS_TotalCostTo is not null and DS_TotalCostTo >= (@reservationsPrice + @price)) or (DS_TotalCostTo is null)) and
				((DS_MinPrice is not null and DS_MinPrice <= @price) or (DS_MinPrice is null))
			order by DS_ID DESC

			set @nDSKey = -1
			set @nValue = @discount
			set @nIsPercent = 1
			return 1
		end
		else
		begin
			
			select @discount = DD_DiscountPercent from dbo.DogovorDetails where DD_DGCODE like @dogovorCode
			set @discount = ISNULL(@discount, 0)
			set @nDSKey = -1
			set @nValue = @discount
			set @nIsPercent = 1
			return 1
		end
		
	end

     if @nPRKey = 0
     begin
          set @nDSKey = -1     
          set @nValue = 0     
          set @nIsPercent = 1     
		  return 0
     end

	declare @nPGKey int, @nTpKey int, @nAttr int, @nCTDepartureKey int
	set @nTpKey=0
	if 	@nPRKey>0
		select @nPGKey = PR_PGKey from Partners where PR_Key = @nPRKey
	else
		set @nPGKey=0
	if @nTLKey>0
		select @nCNKey = TL_CNKey, @nTpKey=TL_TIP, @nAttr = isnull(TL_Attribute, 0) 
		from TurList where TL_Key = @nTLKey

	declare @discountAction int
	set @discountAction = 0
	if @nAttr & 16 > 0
		set @discountAction = 1

	if @dCheckinDate is null
		SET @dCheckinDate=ISNULL(@dCheckinDate,GetDate())
     if @nBTKey = 0 or @nBTKey is null
     begin
          select @nDSKey = DS_Key, @nValue = DS_Value, @nIsPercent = DS_IsPercent from Discounts
          where DS_PRKey IN(0, @nPRKey) AND DS_BTKey IN (0, @nBTKey) AND DS_PGKey IN (0, @nPGKey) 
				AND DS_TLKey IN (0, @nTLKey) AND DS_CNKey IN (0, @nCNKey) AND DS_TPKEY IN (0,@nTpKey)
				AND @dCheckinDate between ISNULL(DS_CheckInFrom,'30-DEC-1899') and ISNULL(DS_CheckInTo,'30-DEC-2200')
				AND DATEDIFF(d, GetDate(), @dCheckinDate) <= ISNULL(DS_DaysBeforeCheckIn, 99999)
				AND ISNULL(@DGCreateDate, ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899')) between ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899') and ISNULL(DS_DogovorCreateDateTo,'30-DEC-2200')
				AND (CASE WHEN @discountAction = 0 THEN ISNULL(DS_DAKey, 0) ELSE 0 END) = 0
				AND DS_DepartureCityKey IN (0, @nDepartureCity)
          order by DS_Priority, DS_BTKey desc, DS_TLKey, DS_CNKey,DS_TPKEY, DS_PRKey, DS_PGKey, DS_DepartureCityKey, @dCheckinDate - ISNULL(DS_DaysBeforeCheckIn, 77777) asc, DS_DogovorCreateDateFrom asc, DS_DogovorCreateDateTo asc, DS_DAKey asc
     end
     else
     begin
          select @nDSKey = DS_Key, @nValue = DS_Value, @nIsPercent = DS_IsPercent from Discounts
          where DS_PRKey IN(0, @nPRKey) AND DS_BTKey IN (0, @nBTKey) AND DS_PGKey IN (0, @nPGKey) 
				AND DS_TLKey IN (0, @nTLKey) AND DS_CNKey IN (0, @nCNKey) AND DS_TPKEY IN (0,@nTpKey)
				AND @dCheckinDate between ISNULL(DS_CheckInFrom,'30-DEC-1899') and ISNULL(DS_CheckInTo,'30-DEC-2200')
				AND DATEDIFF(d, GetDate(), @dCheckinDate) <= ISNULL(DS_DaysBeforeCheckIn, 99999)
				AND ISNULL(@DGCreateDate, ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899')) between ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899') and ISNULL(DS_DogovorCreateDateTo,'30-DEC-2200')
				AND (CASE WHEN @discountAction = 0 THEN ISNULL(DS_DAKey, 0) ELSE 0 END) = 0
				AND DS_DepartureCityKey IN (0, @nDepartureCity)
          order by DS_Priority, DS_BTKey, DS_TLKey, DS_CNKey, DS_TPKEY,DS_PRKey, DS_PGKey, DS_DepartureCityKey, @dCheckinDate - ISNULL(DS_DaysBeforeCheckIn, 77777) asc, DS_DogovorCreateDateFrom asc, DS_DogovorCreateDateTo asc, DS_DAKey asc
     end

     if @nDSKey is null
     begin
          set @nDSKey = -1     
          set @nValue = 0     
          set @nIsPercent = 1     
     end
GO

grant execute on [dbo].[GetPartnerCommission] to public
GO

-- sp_GetServiceList.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceList]
GO

CREATE procedure [dbo].[GetServiceList] 
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
	DG_Code nvarchar(max), DG_Key int, DG_DiscountSum money, DG_Price money, DG_Payed money,
	DG_PriceToPay money, DG_Rate nvarchar(3), DG_NMen int, PR_Name nvarchar(max), CR_Name nvarchar(max),
	DL_Key int, DL_NDays int, DL_NMen int, DL_Reserved int, DL_CTKeyTo int, DL_CTKeyFrom int, DL_CNKEYFROM int,
	DL_SubCode1 int, TL_Key int, TL_Name nvarchar(max), TUCount int, TU_NameRus nvarchar(max), TU_NameLat nvarchar(max),
	TU_FNameRus nvarchar(max), TU_FNameLat nvarchar(max), TU_Key int, TU_Sex Smallint, TU_PasportNum nvarchar(max),
	TU_PasportType nvarchar(max), TU_PasportDateEnd datetime, TU_BirthDay datetime, TU_Hotels nvarchar(max),
	Request smallint, Commitment smallint, Allotment smallint, Ok smallint, TicketNumber nvarchar(max),
	FlightDepDLKey int, FligthDepDate datetime, FlightDepNumber nvarchar(max), ServiceDescription nvarchar(max),
	ServiceDateBeg datetime, ServiceDateEnd datetime, RM_Name nvarchar(max), RC_Name nvarchar(max), SD_RLID int,
	TU_SNAMERUS nvarchar(max), TU_SNAMELAT nvarchar(max)
)
 
if @TypeOfRelult = 2
begin
	--- создаем таблицу в которой пронгумируем незаполненых туристов
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
	and exists (select 1 from ServiceByDate as SSD2 where SSD.SD_DLKey = SSD2.SD_DLKey and SSD2.SD_Date = @Date)

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
		TU_Sex, TU_PasportNum, TU_PasportType, TU_PasportDateEnd, TU_BirthDay, TicketNumber, TU_SNAMERUS, TU_SNAMELAT) 
		SELECT	  DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, 
		(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, 
		DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + '=3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END,
		DG_TRKey, 0, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS, TU_FNAMELAT, SD_TUKey, case when SD_TUKey > 0 then isnull(TU_SEX,0) else null end, TU_PASPORTTYPE + '' '' + TU_PASPORTNUM, TU_PASPORTTYPE, 
		TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, TU_SNAMERUS, TU_SNAMELAT
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
		SET @Query=@Query + ' 
		group by DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, DG_PDTTYPE, DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, DL_DateBeg,
		DL_DateEnd, DG_TRKey, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS,
		TU_FNAMELAT, SD_TUKey, TU_SEX, TU_PASPORTNUM, TU_PASPORTTYPE, TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, SD_RPID, TU_SNAMERUS, TU_SNAMELAT'
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
		PR_NAME, CR_NAME, DL_NDays, case when QT_ByRoom = 1 then count(distinct SD_RLID) else count(distinct SD_RPID) end as DL_NMEN,
		DL_RESERVED, DL_CTKey, DL_SubCode2, DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + ' = 3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END, DG_TRKey, Count(distinct SD_TUKey), DL_KEY, DL_SubCode2
		from ServiceByDate left join RoomNumberLists on sd_rlid = rl_id
		left join Rooms on rl_rmkey = rm_key
		left join RoomsCategory on rl_rckey = rc_key
		left join QuotaParts on sd_qpid = qp_id
		left join QuotaDetails on QP_QDID = QD_ID
		left join Quotas on QT_ID = QD_QTID
		join Dogovorlist on sd_dlkey = dl_key
		join Controls on dl_control = cr_key
		left join Partners on dl_agent = pr_key
		join Dogovor on dl_dGKEY = DG_KEY
		left join Turistservice on tu_dlkey=dl_key
		where DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' AND DL_CODE in (' + @Codes + ') AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND'
		
	if @QDID is not null
		SET @Query = @Query + ' and qp_qdid = ' + CAST(@QDID as nvarchar(max))
	if @QPID is not null
		SET @Query = @Query + ' and qp_id = ' + CAST(@QPID as nvarchar(max))
	
	SET @Query = @Query + '
		group by DG_CODE, SD_RLID, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		DG_PDTTYPE, DG_PRICE, DG_DISCOUNTSUM, DG_PRICE, DG_RATE, DG_NMEN,
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


-- sp_InsDogList.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsDogList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[InsDogList]
GO
CREATE PROCEDURE [dbo].[InsDogList]
(
--<VERSION>2008.1.003</VERSION>
	@sDogovor varchar(10),
	@dTour datetime,
	@nSvKey int,
	@sService varchar(8000),
	@nDay int,
	@nCode int,
	@nCode1 int,
	@nCode2 int,
	@nNDays int,
	@nCountry int,
	@nCity int,
	@nPartner int,
	@nAgent int,
	@nMen int,
	@nNetto money,
	@nBrutto money,
	@nDiscount money,
	@nPaket int,
	@nTour int,
	@nAttribute int,
	@nControl int,
	@nCreator int,
	@nOwner int,
	@dBeg datetime,
	@dEnd datetime,
	@tTime datetime,
	@p_nIsComtmntFirst int,
	@bRet int OUTPUT,
	@nPrmPlaceNoHave money OUTPUT,
	@dPrmBadDate datetime OUTPUT,
	@nNewKey int OUTPUT,
	@nDGKey int = NULL,
	@sComment varchar(254) = NULL,
	@sFormulaNetto varchar(254) = NULL,
	@sFormulaBrutto varchar(254) = NULL,
	@sFormulaDiscount varchar(254) = NULL,
	@sServiceLat varchar(8000) = NULL,
	@nPrtDog int = NULL,
	@nTaxZone int = NULL,
	@bWait bit = NULL
) AS	
	DECLARE @nKey int
	DECLARE @n int
	DECLARE @nID int
	DECLARE @pName varchar(8000)
	DECLARE @sValue varchar(8000)
	DECLARE @nMain int
	--DECLARE @nWait int
	DECLARE @nLong SMALLint
	-- mv 18-11-2005 MEG00006142 
	
	--koshelev MEG00034729
	declare @isCity int
	select @isCity = SV_ISCITY from Service where SV_KEY = @nSvKey
	if (@isCity = 0)
		set @nCity = 0

	select @sComment = case when len(@sComment)> 0 then substring(@sComment,1, len(@sComment)) else null end
	select @sFormulaNetto = case when len(@sFormulaNetto)> 0 then substring(@sFormulaNetto,1, len(@sFormulaNetto)) else null end
	select @sFormulaBrutto = case when len(@sFormulaBrutto)> 0 then substring(@sFormulaBrutto,1, len(@sFormulaBrutto)) else null end
	select @sFormulaDiscount = case when len(@sFormulaDiscount)> 0 then substring(@sFormulaDiscount,1, len(@sFormulaDiscount)) else null end

	If @nDGKey is NULL
		SELECT @nDGKey = DG_KEY FROM tbl_Dogovor where DG_Code = @sDogovor ORDER BY DG_CRDATE DESC
	SELECT @nLong = ISNULL(DG_NDAY,0) FROM tbl_Dogovor where DG_Code = @sDogovor ORDER BY DG_CRDATE DESC
	
	DECLARE @NDL_TimeEnd datetime
	IF @nSvKey=1
		exec [dbo].[MakeFullSVName]
			@nCountry, @nCity, @nSvKey, @nCode, null, 
			@nCode1, @nCode2, 0, @dBeg, null, 
			@sService output, @sServiceLat output, @tTime output, @NDL_TimeEnd output
	
  	set @nPrmPlaceNoHave = 0
	UPDATE KEY_DOGOVORLIST set ID= ID + 1 
	SELECT @nKey = (ID - 1), @nID = ID from KEY_DOGOVORLIST
	IF @@ERROR = 0
	BEGIN
		If @nID >= 2147483646
			Update KEY_DOGOVORLIST set ID = 1
		set @bRet = 1
		set @nNewKey = @nKey
		if @nAgent <= 0
			set @nAgent = 0
		
		--Set @nWait=null --SS_ParmValue from SystemSettings where SS_ParmName = 'SYSSetServiceInWait'
		Insert into tbl_DogovorList (	DL_DgCod,DL_Key,DL_TurDate,DL_DateBeg,DL_DateEnd,
										DL_TimeBeg,DL_SVKey,DL_Name,DL_NameLat,DL_Day,
										DL_Code,DL_SubCode1,DL_SubCode2,DL_NDays,DL_CnKey,
										DL_CtKey,DL_PartnerKey,DL_Agent,DL_Cost,DL_PaketKey,
										DL_Warning,DL_Control,DL_Creator,DL_Owner,DL_Brutto,
										DL_Discount,DL_NMen,DL_Wait,DL_Attribute,DL_TrKey,
										DL_QuoteKey,DL_DGKey, DL_Comment, DL_FormulaNetto, DL_FormulaBrutto, DL_FormulaDiscount,
										DL_Long, DL_PrtDogKey, DL_TaxZoneId)
							Values	(	@sDogovor,@nKey,@dTour,@dBeg,@dEnd,
										@tTime,@nSvKey,@sService,@sServiceLat,@nDay,
										@nCode,@nCode1,@nCode2,@nNDays,@nCountry,
										@nCity,@nPartner,@nAgent,@nNetto,@nPaket,
										0,@nControl,@nCreator,@nOwner,@nBrutto,
										@nDiscount,@nMen,@bWait,@nAttribute,@nTour,
										0,@nDGKey,@sComment,@sFormulaNetto, @sFormulaBrutto, @sFormulaDiscount,
										@nLong,	@nPrtDog, @nTaxZone)
		IF @@ERROR <>0
		BEGIN
			set @bRet = 0
			Return 1
		END
	END	
	return 0

GO
grant exec on [dbo].[InsDogList] to public 
go


-- sp_MakePutName.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MakePutName]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[MakePutName]
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
	
	declare @format varchar(50), @constFormat varchar(50)
	select @format = REPLACE(ST_FormatDogovor, ' ', '(') from Setting
	set @constFormat = @format
	
	declare @curPos int
	set @curPos = 1

	set @format = @format

	declare @chPrev varchar(1)
	set @chPrev = substring(@format, 1, 1)
	set @format = substring(@format, 2, len(@format) - 1)

	declare @number_part_length int
	set @number_part_length = 0
	declare @number_part_start_point int
	set @number_part_start_point = -1
	declare @len int
	set @len = 1
	
	declare @temp varchar(50), @ch varchar(1), @str varchar(50)		
	set @ch = substring(@format, 1, 1)
	
	while @ch != ''
	begin
		set @str = ''
		
		set @ch = substring(@format, 1, 1)
		
		if @format != ''
			set @format = substring(@format, 2, len(@format) - 1)
		
		set @temp = @temp + @chPrev
		
		if (@ch != @chPrev or @format = '') and (LEN(@ch) > 0 or (@chPrev = '9' or @chPrev = '#'))
		begin
			if @format = '' and (@ch = @chPrev) and (@ch != '9' and @ch != '#')
				set @len = LEN(@temp) + 1
			else
				set @len = LEN(@temp)
			
			if @chPrev = 'N'
			begin
				select @str = UPPER(LEFT(LTRIM(TL_Name), @len)) from tbl_TurList where TL_Key = @tourKey
				exec dbo.FillString @str output, @len, 'n'
			end 
			else if @chPrev = 'T'
			begin
				select @str = UPPER(isnull(LEFT(CT_Code, @len), '')) from CityDictionary where CT_Key = @cityKey
				exec dbo.FillString @str output, @len, 't'				
			end
			else if @chPrev = 'C'
			begin
				select @str = UPPER(isnull(LEFT(CN_Code, @len),isnull(LEFT(CN_NameLat, @len), ''))) from Country where CN_Key = @countryKey
				exec dbo.FillString @str output, @len, 'c'
			end
			else if @chPrev = 'P'
			begin
				select @str = UPPER(isnull(LEFT(PR_Cod, @len),'')) from Partners where PR_Key = @partnerKey
				exec dbo.FillString @str output, @len, 'p'
			end
			else if @chPrev = 'Y'
				set @str = RIGHT(STR(YEAR(@date)), @len)
			else if @chPrev = 'D'
			begin
				set @temp = LTRIM(STR(DATEPART(dd, @date)))
				if LEN(@temp) < 2
					set @temp = '0' + @temp
				set @str = @temp
			end
			else if @chPrev = 'M'
			begin
				set @temp = LTRIM(STR(DATEPART(mm, @date)))
				if LEN(@temp) < 2
					set @temp = '0' + @temp
				set @str = @temp	
			end
			else if @chPrev = '('
			begin
				set @str = ' '
			end
			if @chPrev = '9' or @chPrev = '#'
			begin
				if(@chPrev = '9')
					set @temp = REPLICATE('[0-9]', @len)
				else
					set @temp = REPLICATE('_', @len)
				declare @searchName varchar(50)
				
				set @searchName = @name + @temp + '%'

				select @str = max(DG_Code) from tbl_Dogovor where LEN(DG_Code) = LEN(@constFormat) and upper(DG_Code) like upper(@searchName) and ((DG_TurDate >= @selectDate) or (DG_TurDate is null) or (DG_TurDate = @nullDate))
				if @str is null
					set @str = ''
				if @str != ''
				begin
					set @str = substring(@str, LEN(@name) + 1, @len)
				end
				
				set @number_part_length = @number_part_length + 1
				if (@number_part_start_point < 0)
					set @number_part_start_point = LEN(@name) + 1

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
					set @str = Upper(dbo.NextStr(@str, @len))
				end
			end
			
			set @temp = ''
		end
		
		set @name = @name + @str
		set @chPrev = @ch
		--select @name
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
grant exec on [dbo].[MakePutName] to public
go



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
			WHERE dg_key = @dg_key and DG_TURDATE <> '1899-12-31'
			and dg_sor_code != (SELECT sr_ReservationStatusId FROM dbo.StatusRules WHERE sr_id = @StatusRuleId)
		end
		else
		begin
			UPDATE dbo.tbl_Dogovor 
				SET dg_sor_code = (SELECT sr_ReservationStatusId FROM dbo.StatusRules WHERE sr_id = @StatusRuleId)
			WHERE dg_key = @dg_key and DG_Sor_Code in (1,2,3,7) and DG_TURDATE <> '1899-12-31'
			and dg_sor_code != (SELECT sr_ReservationStatusId FROM dbo.StatusRules WHERE sr_id = @StatusRuleId)
		end
	END
END
GO

GRANT EXECUTE ON [dbo].[SetReservationStatus] TO Public
GO

-- sp_SetServiceQuotasStatus.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetServiceQuotasStatus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetServiceQuotasStatus]
GO

CREATE PROCEDURE [dbo].[SetServiceQuotasStatus]
	(
		@DLKey int
	)
AS
BEGIN
	declare @N_DLSVKey int, @N_DLDateBeg datetime, @N_DLDateEnd datetime, @N_GlobalControl int
	
	select @N_DLSVKey = DL_SVKEY, @N_DLDateBeg = DL_DATEBEG, @N_DLDateEnd = DL_DATEEND, @N_GlobalControl = CR_GlobalState
	from Dogovorlist join Controls on DL_CONTROL = CR_KEY
	where DL_KEY = @DLKey
	
	-- если глобальный статус услуги не Ок, то выходим
	if @N_GlobalControl != 1 or exists (select 1 from Dogovorlist where DL_KEY = @DLKey and DL_DATEBEG < '1950-01-01')
	begin
		return 0
	end

	declare @serviceKeys nvarchar(max)	
			
	select @serviceKeys = SS_ParmValue
	from SystemSettings 
	where SS_ParmName = 'SYSNoSetToQuotaIfStatusOk'
	
	if exists (select 1 from [service] where sv_key = @N_DLSVKey) 
		and not exists (select 1 from ParseKeys(@serviceKeys))
	begin
		if isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKey),4) = 4
		begin
			EXEC DogListToQuotas @DLKey, null, null, null, null, @N_DLDateBeg, @N_DLDateEnd, null, null, @SetOkIfRequest = 1
		end
	end
				
	if exists (select 1 from DogovorList where DL_KEY = @DLKey and DL_CONTROL = 0)
	begin
		update ServiceByDate set SD_State = 3 where SD_DLKey = @DLKey and SD_State = 4
	end	
END
GO
grant exec on [dbo].[SetServiceQuotasStatus] to public
go




-- sp_SetServiceStatusOK.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetServiceStatusOK]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetServiceStatusOK]
GO
CREATE PROCEDURE [dbo].[SetServiceStatusOK]
	(
		@DLKEY int
	)
AS
BEGIN
	-- теперь в завмсимости от настроек будем менять статусы на Ок
	-- 0 - все галки сняты
	-- 1 - Все услуги
	-- 2 - Авиаперелет
	-- 3 - Все услуги & Авиаперелет
	-- 4 - Проживание
	-- 5 - Все услуги & Проживание
	-- 6 - Авиаперелет & Проживание
	-- 7 - Все услуги & Авиаперелет & Проживание
	
	-- Авиаперелет
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('2', '3', '6', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		update Dogovorlist
		set DL_CONTROL = 0
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_SvKey = 1 and DL_Control != 0
	end
	
	-- Проживание
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('4', '5', '6', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		update Dogovorlist
		set DL_CONTROL = 0
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_SvKey = 3 and DL_Control != 0
	end
	
	-- Все услуги
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('1', '3', '5', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		update Dogovorlist
		set DL_CONTROL = 0
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_SvKey != 3 
		and DL_SvKey != 1
		and DL_Control != 0
	end
	
	
	-- MEG00032041
	-- Теперь проверим есть ли на эту квоту запись в таблице QuotaStatuses
	-- которая говорит нам что нужно изменить статус услуги на тот который в этой таблице
	if exists(select 1 
				from QuotaStatuses join Quotas on QS_QTID = QT_ID 
				join QuotaDetails on QT_ID = QD_QTID
				join QuotaParts on QP_QDID = QD_ID
				join ServiceByDate on SD_QPID = QP_ID
				where SD_DLKey = @DLKEY and SD_State = QS_Type) 
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		declare @DLCONTROL int
		
		select @DLCONTROL = QS_CRKey
		from QuotaStatuses join Quotas on QS_QTID = QT_ID 
		join QuotaDetails on QT_ID = QD_QTID
		join QuotaParts on QP_QDID = QD_ID
		join ServiceByDate on SD_QPID = QP_ID
		where SD_DLKey = @DLKEY and SD_State = QS_Type
	
		update Dogovorlist
		set DL_CONTROL = @DLCONTROL
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_Control != @DLCONTROL
	end
END
GO
grant exec on [dbo].[SetServiceStatusOK] to public
go


-- T_BillsDelete.sql
ALTER TABLE dbo.BillsToBills
	DROP CONSTRAINT BB_BLIN
GO

ALTER TABLE dbo.BillsToBills WITH NOCHECK ADD CONSTRAINT
	BB_BLIN FOREIGN KEY
	(
	BB_BLIN
	) REFERENCES dbo.Bills
	(
	BL_KEY
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_BillsDelete]'))
DROP TRIGGER [dbo].[T_BillsDelete]
GO

CREATE TRIGGER [dbo].[T_BillsDelete]
   ON [dbo].[Bills]
   AFTER DELETE
AS 
BEGIN
	delete BillsToBills
	from BillsToBills join deleted on BL_KEY = BB_BLIN
	
	delete BillsToBills
	from BillsToBills join deleted on BL_KEY = BB_BLOUT
END

GO




-- T_PrtBonusDetailsChange.sql
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_PrtBonusDetailsChange]'))
DROP TRIGGER [dbo].[T_PrtBonusDetailsChange]
GO

CREATE TRIGGER [dbo].[T_PrtBonusDetailsChange] ON [dbo].[PrtBonusDetails] 
FOR INSERT, UPDATE, DELETE 
AS

IF @@ROWCOUNT > 0
BEGIN
	DECLARE 	@nPBId int

	DECLARE CursorCurent cursor for
		
		SELECT	O.PBD_PBId		
		FROM		deleted O
		UNION 
		SELECT	N.PBD_PBId
		FROM		inserted N

	open CursorCurent

	fetch next from CursorCurent into @nPBId
	while @@FETCH_STATUS = 0
	BEGIN
		UPDATE	dbo.PrtBonuses 
			SET	PB_TotalRating = (SELECT SUM(PBD_Rating) FROM dbo.PrtBonusDetails WHERE PBD_PBId = @nPBId),
				PB_TotalBonus = (SELECT SUM(PBD_Bonus) FROM dbo.PrtBonusDetails WHERE PBD_PBId = @nPBId),
				PB_TotalExpense = (SELECT SUM(PBD_Expense) FROM dbo.PrtBonusDetails WHERE PBD_PBId = @nPBId)
		WHERE 	PB_Id = @nPBId
		fetch next from CursorCurent into @nPBId
	END

	close CursorCurent
	deallocate CursorCurent
END

GO




-- T_ServiceByDateChanged.sql
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_ServiceByDateChanged]'))
DROP TRIGGER [dbo].[T_ServiceByDateChanged]
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
		@nDelCount smallint, @nInsCount smallint, @DLDateBeg datetime, @DLNDays smallint, @QState smallint, @NewQState smallint

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
						SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate, tbl_DogovorList join [Service] on DL_SVKey = SV_KEY WHERE SD_QPID=@O_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1) 
					WHERE QP_ID=@O_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID = @O_SD_QPID) WHERE QP_ID = @O_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(*) FROM QuotaParts, ServiceByDate WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@O_SD_QPID)
				--IF @O_SD_Date = @DLDateBeg
					UPDATE	QuotaParts 
					SET QP_CheckInPlacesBusy = (SELECT COUNT(*) 
												FROM ServiceByDate,
												tbl_DogovorList join [Service] on DL_SVKey = SV_KEY
												WHERE SD_QPID = @O_SD_QPID AND SD_DATE=DL_DATEBEG
												AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1)
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
						SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate, tbl_DogovorList join [Service] on DL_SVKey = SV_KEY WHERE SD_QPID=@N_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1) 
					WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID=@N_SD_QPID) WHERE QP_ID=@N_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(*) FROM QuotaParts, ServiceByDate WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@N_SD_QPID)
				--IF @N_SD_Date = @DLDateBeg
					UPDATE	QuotaParts 
					SET QP_CheckInPlacesBusy=(SELECT COUNT(*) 
												FROM ServiceByDate,
												tbl_DogovorList join [Service] on DL_SVKey = SV_KEY
												WHERE SD_QPID=@N_SD_QPID AND SD_DATE=DL_DATEBEG 
												AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1)
					WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
		END
	END
	IF (ISNULL(@O_SD_STATE, 0) != ISNULL(@N_SD_STATE, 0) or 
		ISNULL(@O_SD_TUKEY,0)!=ISNULL(@N_SD_TUKEY,0)) and ISNULL(@sServiceStatusToHistory, '0') != '0'
	BEGIN
		Select @QState = QS_STATE from QuotedState 
		where QS_DLID = @N_SD_DLKey and ISNULL(QS_TUID,0) = ISNULL(@N_SD_TUKEY,0)
		IF @QState is NULL and @N_SD_DLKey is not NULL
		BEGIN
			Set @QState = 4
			Insert into QuotedState (QS_DLID, QS_TUID, QS_STATE) values (@N_SD_DLKey, @N_SD_TUKEY, @QState)
		END

		Select @NewQState = MAX(SD_STATE) from ServiceByDate 
		where SD_DLKey = @N_SD_DLKey and ISNULL(SD_TUKEY,0) = ISNULL(@N_SD_TUKEY,0)
		
		if @NewQState is null
		 	set @NewQState = 4
		IF @QState <> @NewQState
			IF @N_SD_DLKey is not NULL
				Update QuotedState set QS_STATE = @NewQState where QS_DLID=@N_SD_DLKey and ISNULL(QS_TUID,0)=ISNULL(@N_SD_TUKEY,0)
			ELSE
				IF @O_SD_DLKey is not NULL
					Update QuotedState set QS_STATE = @NewQState where QS_DLID=@O_SD_DLKey and ISNULL(QS_TUID,0)=ISNULL(@N_SD_TUKEY,0)
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




-- x_calculatingpricelists.sql
IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_PriceTourKey')
     DROP INDEX CalculatingPriceLists.x_PriceTourKey
GO
CREATE NONCLUSTERED INDEX [x_PriceTourKey] ON [dbo].[CalculatingPriceLists] 
(
	[CP_Key] ASC
)
INCLUDE 
( 
	[CP_TourKey],
	[CP_PriceTourKey],
	[CP_CreateDate]
) 
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_PriceTourKey2')
     DROP INDEX CalculatingPriceLists.x_PriceTourKey2
GO
CREATE NONCLUSTERED INDEX [x_PriceTourKey2] ON [dbo].[CalculatingPriceLists] 
(
	[CP_PriceTourKey] ASC
)
INCLUDE
(
	[CP_CreateDate]
)
GO

IF NOT EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'PK_CalculatingPriceLists')
BEGIN
	ALTER TABLE [dbo].[CalculatingPriceLists]  ADD CONSTRAINT [PK_CalculatingPriceLists]
	PRIMARY KEY CLUSTERED
	(
		[CP_Key] ASC
	)
END
GO

-- x_mappings.sql
IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'IX_MP_Oblect1')
     DROP INDEX Mappings.IX_MP_Oblect1
GO
CREATE NONCLUSTERED INDEX [IX_MP_Oblect1] ON [dbo].[Mappings] 
(
      [MP_TableID] ASC,
      [MP_IntKey] ASC,
      [MP_StrValue] ASC
) ON [PRIMARY]
GO

-- (110503)AlterTable_tbl_Dogovor.sql
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_tbl_Dogovor_InternalStatuses]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_Dogovor]'))
ALTER TABLE [dbo].[tbl_Dogovor] DROP CONSTRAINT [FK_tbl_Dogovor_InternalStatuses]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InternalStatuses]') AND type in (N'U'))
DROP TABLE [dbo].[InternalStatuses]
GO
CREATE TABLE [dbo].[InternalStatuses](
	[IS_Id] [int] IDENTITY(1,1) NOT NULL,
	[IS_Name] [nvarchar](50) NOT NULL,
	[IS_NameLat] [nvarchar](50) NULL,
 CONSTRAINT [PK_InternalStatuses] PRIMARY KEY CLUSTERED 
(
	[IS_Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

if not exists (select 1 from InternalStatuses where IS_Id = 1)
	insert into InternalStatuses( IS_Name, IS_NameLat) values ('Не определен', 'Not defined')
go
if not exists (select 1 from InternalStatuses where IS_Id = 2)
	insert into InternalStatuses( IS_Name, IS_NameLat) values ('Создан', 'Created')
go
if not exists(select id from syscolumns where id = OBJECT_ID('tbl_Dogovor') and name = 'DG_InternalStatusId')
	alter table tbl_Dogovor add DG_InternalStatusId int not null default(1)
go
ALTER TABLE [dbo].[tbl_Dogovor]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Dogovor_InternalStatuses] FOREIGN KEY([DG_InternalStatusId])
REFERENCES [dbo].[InternalStatuses] ([IS_Id])
GO
ALTER TABLE [dbo].[tbl_Dogovor] CHECK CONSTRAINT [FK_tbl_Dogovor_InternalStatuses]
GO
exec sp_RefreshViewForAll 'Dogovor'
go
ALTER TABLE [dbo].[tbl_Dogovor] DISABLE TRIGGER [T_DogovorUpdate]
go
update tbl_Dogovor
set DG_InternalStatusId = 2
go
ALTER TABLE [dbo].[tbl_Dogovor] ENABLE TRIGGER [T_DogovorUpdate]
go

set nocount on
-- (110503)AlterTable_tbl_Dogovor.sql
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_tbl_Dogovor_InternalStatuses]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_Dogovor]'))
ALTER TABLE [dbo].[tbl_Dogovor] DROP CONSTRAINT [FK_tbl_Dogovor_InternalStatuses]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InternalStatuses]') AND type in (N'U'))
DROP TABLE [dbo].[InternalStatuses]
GO

if exists (select * from dbo.syscolumns where name = 'DG_InternalStatusId' and id = object_id(N'[dbo].[tbl_Dogovor]'))
begin
	IF EXISTS (select * from sysobjects o 
						inner join syscolumns c
                        on o.id = c.cdefault
                        inner join sysobjects t
                        on c.id = t.id
                        where o.xtype = 'd'
                        and c.name = 'DG_InternalStatusId'
                        and t.name = 'tbl_Dogovor')
    begin  
		declare @default nvarchar(100)
		declare @sql nvarchar(200)
		set @default = (select o.name from sysobjects o 
										inner join syscolumns c
                                        on o.id = c.cdefault
                                        inner join sysobjects t
                                        on c.id = t.id
                                        where o.xtype = 'd'
                                        and c.name = 'DG_InternalStatusId'
                                        and t.name = 'tbl_Dogovor')
		set @sql = N'alter table tbl_Dogovor drop constraint ' + @default
        exec sp_executesql @sql
    end
	alter table tbl_Dogovor drop column DG_InternalStatusId
end

exec sp_RefreshViewForAll 'Dogovor'
go

-- 110812(Delete_VisaTouristGridSettingsRows).sql
DELETE FROM UserSettings
WHERE ST_ParmName IN ('GroupVisaForm', 'DogovorMainForm.visaTouristServicesGrid', 'VisaTouristForm.visaTouristServicesGrid')

GO

-- 110817(Delete_BonusDetailGrid_Settings).sql
delete from UserSettings
where ST_ParmName = 'PrtBonusDetailsForm.prtBonusDetailsGrid'
GO

delete UserSettings
where ST_ParmName = 'PrtBonusesForm.prtBonusesGrid'
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

		if isnull((select max(stopSale) 
					from (	select min(qt_stop) as stopSale
							from @tmpQuotes
							where qt_qoid = (select top 1 qt_qoid from @tmpQuotes where qt_date = @dateFrom)
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
		
if(@bycheckinRes > 0 and @checkNoLongQuotes <> @ALLDAYS_CHECK)
							break

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
						set @bycheckinRes =  1 - @qtNotcheckin
						
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
				(case when (isnull(ss_id, 0) > 0 and isnull(ss_isdeleted, 0) = 0) then 1 else 0 end) as qt_stop,
				qo_id as qt_qoid
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
			--	and isnull(QP_IsNotCheckin, 0) = 0
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


-- I_DogListToQuotas.sql
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[ServiceByDate]') AND name = N'X_ServiceByDate_History')
DROP INDEX [X_ServiceByDate_History] ON [dbo].[ServiceByDate] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_ServiceByDate_History] ON [dbo].[ServiceByDate] 
(
	[SD_DLKey] ASC,
	[SD_TUKey] ASC
)
INCLUDE ( [SD_State]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetails]') AND name = N'IDX_QuotaDetails_PAC1')
DROP INDEX [IDX_QuotaDetails_PAC1] ON [dbo].[QuotaDetails] WITH ( ONLINE = OFF )
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetails]') AND name = N'x_QuotaDetails_DogListToQuotas')
DROP INDEX [x_QuotaDetails_DogListToQuotas] ON [dbo].[QuotaDetails] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_QuotaDetails_DogListToQuotas] ON [dbo].[QuotaDetails] 
(
	[QD_ID] ASC,
	[QD_Date] ASC,
	[QD_QTID] ASC,
	[QD_Type] ASC,
	[QD_Release] ASC,
	[QD_IsDeleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaParts]') AND name = N'x_QuotaParts_DogListToQuotas')
DROP INDEX [x_QuotaParts_DogListToQuotas] ON [dbo].[QuotaParts] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_QuotaParts_DogListToQuotas] ON [dbo].[QuotaParts] 
(
	[QP_IsDeleted] ASC,
	[QP_FilialKey] ASC,
	[QP_AgentKey] ASC,
	[QP_CityDepartments] ASC,
	[QP_Date] ASC,
	[QP_IsNotCheckIn] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaParts]') AND name = N'X_QO_Object_1')
DROP INDEX [X_QO_Object_1] ON [dbo].[QuotaParts] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_QO_Object_1] ON [dbo].[QuotaParts] 
(
	[QP_QDID] ASC,
	[QP_AgentKey] ASC,
	[QP_Durations] ASC,
	[QP_Places] ASC,
	[QP_Busy] ASC,
	[QP_IsNotCheckIn] ASC,
	[QP_CheckInPlaces] ASC,
	[QP_CheckInPlacesBusy] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO






-- sp_CheckQuotaExist.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckQuotaExist]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckQuotaExist]
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
	
-- создаем таблицу со стопами
CREATE TABLE #StopSaleTemp
(SST_Code int, SST_SubCode1 int, SST_SubCode2 int, SST_QOID int, SST_PRKey int, SST_Date smalldatetime,
SST_QDID int, SST_Type smallint, SST_State smallint, SST_Comment varchar(255)
)

INSERT INTO #StopSaleTemp exec dbo.GetTableQuotaDetails NULL, @Q_QTID, @DateBeg, @DaysCount, null, null, @SVKey, @Code, @SubCode1, @PRKey

IF @SVKey=3
BEGIN
	declare CheckQuotaExistСursor cursor for 
		select	DISTINCT QT_ID, QT_PRKey, QT_ByRoom, 
				QD_Type, 
				QP_FilialKey, QP_CityDepartments, QP_AgentKey, CASE WHEN QP_Durations='' THEN 0 ELSE @TourDuration END, QP_FilialKey, QP_CityDepartments, 
				QO_SubCode1, QO_SubCode2
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
		group by QT_ID, QT_PRKey, QT_ByRoom, QD_Type, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_Durations, QO_SubCode1, QO_SubCode2
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

	declare @SubCode2 int

	SET @Query = 
	'
	INSERT INTO #Tbl (	TMP_Count, TMP_QTID, TMP_AgentKey, TMP_Type, TMP_Date, 
						TMP_ByRoom, TMP_Release, TMP_Partner, TMP_Durations, TMP_FilialKey, 
						TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2)
		SELECT	DISTINCT QP_Places-QP_Busy as d1, QT_ID, QP_AgentKey, QD_Type, QD_Date, 
				QT_ByRoom, QD_Release, QT_PRKey, QP_Durations, QP_FilialKey,
				QP_CityDepartments, QO_SubCode1, QO_SubCode2
		FROM	Quotas QT1, QuotaDetails QD1, QuotaParts QP1, QuotaObjects QO1, #StopSaleTemp
		WHERE	QO_ID = SST_QOID and QD_ID = SST_QDID and SST_State is null and ' + @SubQuery
	print @Query

	exec (@Query)
	
	SET @Q_QTID_Prev=@Q_QTID
	fetch CheckQuotaExistСursor into	@Q_QTID, @Q_Partner, @Q_ByRoom, 
										@Q_Type, 
										@Q_FilialKey, @Q_CityDepartments, @Q_AgentKey, @Q_Duration, @Q_FilialKey, @Q_CityDepartments, 
										@Q_SubCode1, @Q_SubCode2	
END

--select * from #Tbl

--DELETE FROM #Tbl WHERE 

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
				TMP_SubCode1 int, TMP_SubCode2 int, TMP_ReleaseIgnore bit)

DECLARE @DATETEMP datetime
SET @DATETEMP = GetDate()
-- Разрешим посадить в квоту с релиз периодом 0 текущим числом
set @DATETEMP = DATEADD(day, -1, @DATETEMP)
if exists (select top 1 1 from systemsettings where SS_ParmName='SYSCheckQuotaRelease' and SS_ParmValue=1) OR exists (select top 1 1 from systemsettings where SS_ParmName='SYSAddQuotaPastPermit' and SS_ParmValue=1)
	SET @DATETEMP='01-JAN-1900'
INSERT INTO @Tbl_DQ
	SELECT	MIN(d1) as TMP_Count, TMP_AgentKey, TMP_Type, TMP_ByRoom, TMP_Partner, 
			d2 as TMP_Duration, TMP_FilialKey, TMP_CityDepartments, TMP_SubCode1, TMP_SubCode2,0 as TMP_ReleaseIgnore FROM
		(SELECT	SUM(TMP_Count) as d1, TMP_Type, TMP_ByRoom, TMP_AgentKey, TMP_Partner, 
				TMP_FilialKey, TMP_CityDepartments, TMP_Date, CASE WHEN TMP_Durations='' THEN 0 ELSE @TourDuration END as d2, TMP_SubCode1, TMP_SubCode2
		FROM	#Tbl
		WHERE	(TMP_Date >= @DATETEMP + ISNULL(TMP_Release,0) OR (TMP_Date < GETDATE() - 1))
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
	
		--проверяем достаточно ли будет текущего кол-ва мест для бронирования
		declare @nPlaces smallint, @nRoomsService smallint
		If @SVKey=3 and @Rooms_Count>0
		BEGIN
			exec GetServiceRoomsCount @Code, @SubCode1, @Pax, @nRoomsService output
			
			If @nRoomsService > @Rooms_Count
				Set @PlacesNeed_Count = @nRoomsService - @Rooms_Count
				
			If @nRoomsService > @Rooms_Count_ReleaseIgnore
				Set @PlacesNeed_Count_ReleaseIgnore = @nRoomsService - @Rooms_Count_ReleaseIgnore
		END
		ELSE
		begin
			If @Pax > @Places_Count
				Set @PlacesNeed_Count = @Pax - @Places_Count
				
			If @Pax > @Places_Count_ReleaseIgnore
				Set @PlacesNeed_Count_ReleaseIgnore = @Pax - @Places_Count_ReleaseIgnore
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
	
	-- Проверим на стоп
	If @StopExist > 0
	BEGIN
		Set @Quota_CheckState = 2						--Возвращаем "Внимание STOP"
		Set @Quota_CheckDate = @StopDate
	END
END

GO
grant exec on [dbo].[CheckQuotaExist] to public
go


-- sp_DogListToQuotas.sql
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
	@SetQuotaDateFirst datetime = null,
	@SetOkIfRequest bit = 0 -- запуск из тригера T_UpdDogListQuota
) AS

--insert into Debug (db_n1, db_n2, db_n3) values (@DLKey, @SetQuotaType, 999)
declare @SVKey int, @Code int, @SubCode1 int, @PRKey int, @AgentKey int, @DgKey int,
		@TourDuration int, @FilialKey int, @CityDepartment int,
		@ServiceDateBeg datetime, @ServiceDateEnd datetime, @Pax smallint, @IsWait smallint,@SVQUOTED smallint

SELECT	@SVKey=DL_SVKey, @Code=DL_Code, @SubCode1=DL_SubCode1, @PRKey=DL_PartnerKey, 
		@ServiceDateBeg=DL_DateBeg, @ServiceDateEnd=DL_DateEnd, @Pax=DL_NMen,
		@AgentKey=DG_PartnerKey, @TourDuration=DG_NDay, @FilialKey=DG_FilialKey, @CityDepartment=DG_CTDepartureKey, @IsWait=ISNULL(DL_Wait,0),
		@DgKey = DL_DGKEY
FROM	DogovorList, Dogovor 
WHERE	DL_DGKey=DG_Key and DL_Key=@DLKey

if @IsWait=1 and (@SetQuotaType in (1,2) or @SetQuotaType is null)  --Установлен признак "Не снимать квоту при бронировании". На квоту не ставим
BEGIN
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
		exec SetStatusInRoom @dlkey
	-- запускае хранимку на установку статуса путевки
	exec SetReservationStatus @DgKey
	return 0
END
SELECT @SVQUOTED=isnull(SV_Quoted,0) from service where sv_key=@SVKEY
if @SVQUOTED=0
BEGIN
	UPDATE ServiceByDate SET SD_State=3 WHERE SD_DLKey=@DLKey	
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
		exec SetStatusInRoom @dlkey
	-- запускае хранимку на установку статуса путевки
	exec SetReservationStatus @DgKey
	return 0
END

-- ДОБАВЛЕНА НАСТРОЙКА ЗАПРЕЩАЮЩАЯ СНЯТИЕ КВОТЫ ДЛЯ УСЛУГИ, 
-- ТАК КАК В КВОТАХ НЕТ РЕАЛЬНОЙ ИНФОРМАЦИИ, А ТОЛЬКО ПРИЗНАК ИХ НАЛИЧИЯ (ПЕРЕДАЕТСЯ ИЗ INTERLOOK)
IF (@SetQuotaType in (1,2) or @SetQuotaType is null) and  EXISTS (SELECT 1 FROM dbo.SystemSettings WHERE SS_ParmName='IL_SyncILPartners' and SS_ParmValue LIKE '%/' + CAST(@PRKey as varchar(20)) + '/%')
BEgin
	UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
		exec SetStatusInRoom @dlkey
	-- запускае хранимку на установку статуса путевки
	exec SetReservationStatus @DgKey
	return 0
End

-- сбрасываем статус услуги на тот который указан в справочнике, если хотя бы одна
-- для всех квотируемых услуг
if @SetOkIfRequest = 0
begin
	update Dogovorlist
	set DL_CONTROL = (select top 1 SV_CONTROL from [Service] where DL_SVKEY = SV_KEY)
	from Dogovorlist 
	where DL_KEY = @DLKey
	and DL_Control <> (select top 1 SV_CONTROL from [Service] where DL_SVKEY = SV_KEY)
	and exists (select top 1 1 from [Service] where DL_SVKEY = SV_KEY and SV_QUOTED = 1)
end
-- проверим если это доп место в комнате, то ее нельзя посадить в квоты, сажаем внеквоты и эта квота за человека
if ( exists (select top 1 1 from ServiceByDate join RoomPlaces on SD_RPID = RP_ID where SD_DLKey = @DLKey and RP_Type = 1) and (@SetQuotaByRoom = 0))
begin
	set @SetQuotaType = 3
end

/*
If @SVKey=3
	SELECT TOP 1 @Quota_SubCode1=HR_RMKey, @Quota_SubCode2=HR_RCKey FROM HotelRooms WHERE HR_Key=@SubCode1
Else
	Set @Quota_SubCode1=@SubCode1
*/
declare @Q_Count smallint, @Q_AgentKey int, @Q_Type smallint, @Q_ByRoom bit, 
		@Q_PRKey int, @Q_FilialKey int, @Q_CityDepartments int, @Q_Duration smallint, @Q_DateBeg datetime, @Q_DateEnd datetime, @Q_DateFirst datetime, @Q_SubCode1 int, @Q_SubCode2 int,
		@Query nvarchar(max), @SubQuery varchar(1500), @Current int, @CurrentString varchar(50), @QTCount_Need smallint, @n smallint, @n2 smallint, @Result_Exist bit, @nTemp smallint, @dTemp datetime
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
		if @SetQuotaType=3
		begin
			exec SetServiceStatusOK @dlkey
		end
		-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
		if @SetQuotaByRoom = 0
			exec SetStatusInRoom @dlkey
		-- запускае хранимку на установку статуса путевки
		exec SetReservationStatus @DgKey
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
						if exists (select top 1 1 from systemsettings where SS_ParmName=''SYSCheckQuotaRelease'' and SS_ParmValue=1) OR exists (select top 1 1 from systemsettings where SS_ParmName=''SYSAddQuotaPastPermit'' and SS_ParmValue=1)
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
	
	exec SetServiceStatusOK @dlkey
	-- Хранимка в зависисмости от статусов, основных мест в комнате устанавливает статус квотирования на доп местах
	if @SetQuotaByRoom = 0
		exec SetStatusInRoom @dlkey

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
UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null
-- запускае хранимку на установку статуса путевки
exec SetReservationStatus @DgKey
GO
grant exec on [dbo].[DogListToQuotas] to public
go



-- sp_GetQuotaLoadListData_N.sql
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
QL_QTID int, QL_QOID int, QL_PRKey int, QL_SubCode1 int, QL_PartnerName nvarchar(100) collate Cyrillic_General_CI_AS, QL_Description nvarchar(255) collate Cyrillic_General_CI_AS, 
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
	,QO_ID int
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
	
	-- отдельно для стопов на объект квотирования
	INSERT INTO @QuotaLoadTemp (QT_ID, QT_PRKey, QT_ByRoom, QO_ID, QO_SubCode1, QO_SubCode2, QD_ID, QD_Date, QD_Type, QD_Release, QP_Places, QP_Busy, QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_IsNotCheckIn, QD_Comment, QP_Comment, QP_CheckInPlaces, QP_CheckInPlacesBusy)
	SELECT 0, 0, -1, QO_ID, QO_SubCode1, QO_SubCode2, -1, SS_Date, case when isnull(SS_AllotmentAndCommitment, 0) = 1 then 2 else 1 end, NULL, 0, 0, -1, NULL, 0, 0, CASE SS_PRKey WHEN 0 THEN NULL ELSE SS_PRKey END, 0, SS_Comment, SS_Comment, 0, 0
	FROM	QuotaObjects join StopSales on QO_ID = SS_QOID
	WHERE	(QO_Code = @Service_Code and QO_SVKey = @Service_SVKey and QO_QTID is null)		
			and SS_Date between @DateStart and @DateEnd
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey = SS_PRKey or SS_PRKey = 0)))
			and ISNULL(SS_IsDeleted,0) = 0
	ORDER BY SS_Date DESC, SS_ID


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

	with Dist (QL_QTID, QL_QOID, QL_Type, QL_Release, QL_dataType, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom, RowNum) AS
	(
		select DISTINCT QT_ID, QO_ID, QD_Type, QD_Release, NU_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, '', @DateEnd+1,QT_PRKey,QT_ByRoom,
						ROW_NUMBER() OVER (PARTITION BY QT_ID, QD_Type, QD_Release, NU_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, '', @DateEnd+1,QT_PRKey,QT_ByRoom ORDER BY QO_ID)
		from @QuotaLoadTemp, Numbers
		where NU_ID between @Result_From and @Result_To
	)
	insert into #QuotaLoadList (QL_QTID, QL_QOID, QL_Type, QL_Release, QL_dataType, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	select QL_QTID, QL_QOID, QL_Type, QL_Release, QL_dataType, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom from Dist
	where RowNum = 1
END

--update #QuotaLoadList set QL_CustomerInfo = (Select PR_Name from Partners where PR_Key = QL_FilialKey and QL_FilialKey > 0)

DECLARE @QD_ID int, @Date smalldatetime, @State smallint, @QD_Release int, @QP_Durations varchar(20), @QP_FilialKey int,
		@QP_CityDepartments int, @QP_AgentKey int, @Quota_Places int, @Quota_Busy int, @QP_IsNotCheckIn bit,
		@QD_QTID int, @QP_ID int, @Quota_Comment varchar(8000), @Stop_Comment varchar(255), @QO_ID int--,	@QT_ID int
DECLARE @ColumnName varchar(10), @QueryUpdate varchar(8000), @QueryUpdate1 varchar(255), @QueryWhere1 varchar(255), @QueryWhere2 varchar(255), 
		@QD_PrevID int, @StopSale_Percent int, @CheckInPlaces smallint, @CheckInPlacesBusy smallint --@QuotaObjects_Count int, 

if @bShowCommonInfo = 1
	DECLARE curQLoadList CURSOR FOR SELECT
			QT_ID, QD_ID, QD_Date, QD_Type, QD_Release,
			QD_Places, QD_Busy,
			0,'',0,0,0,0, ISNULL(REPLACE(QD_Comment,'''','"'),''),0,0, QO_ID
	FROM	Quotas, QuotaObjects, QuotaDetails
	WHERE	QT_ID=QO_QTID and QD_QTID=QT_ID
			and ((QO_Code=@Service_Code and QO_SVKey=@Service_SVKey and QO_QTID is not null and @QT_ID is null) or (@QT_ID is not null and @QT_ID=QT_ID))
			and (QD_Type = @nShowQuotaTypes or @nShowQuotaTypes = 0) and QD_Date between @DateStart and @DateEnd
			and (QD_IsDeleted = 0 or QD_IsDeleted is null)
	ORDER BY QD_Date DESC, QD_ID
else
	DECLARE curQLoadList CURSOR FOR 
	SELECT QT_ID, QD_ID, QD_Date, QD_Type, QD_Release, QP_Places, QP_Busy, QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, ISNULL(QP_IsNotCheckIn,0), ISNULL(REPLACE(QD_Comment,'''','"'),'') + '' + ISNULL(REPLACE(QP_Comment,'''','"'),''), QP_CheckInPlaces, QP_CheckInPlacesBusy, QO_ID
	FROM	@QuotaLoadTemp
	ORDER BY QD_Date DESC, QD_ID

OPEN curQLoadList
FETCH NEXT FROM curQLoadList INTO	@QT_IDLocal,
									@QD_ID, @Date, @State, @QD_Release, @Quota_Places, @Quota_Busy,
									@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, @QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy, @QO_ID
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
		
		IF @QO_ID IS NOT NULL
		BEGIN
			SET @StopSale_Percent = 100;
		END
		
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
			BEGIN
				-- @StopSaleOrPlaces служит для показывания буквы 'S' для стопов на объекты квотирования вместо 0
				DECLARE @StopSaleOrPlaces varchar(255)
				if @QO_ID is not null
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
										@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, @QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy, @QO_ID
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
	SELECT DISTINCT 0, QO_SubCode1, 1, null FROM QuotaObjects (nolock) WHERE QO_ID in (SELECT QL_QOID FROM #QuotaLoadList (nolock) WHERE QL_QOID is not null)
	UNION
	SELECT DISTINCT 0, QO_SubCode2, 2, null FROM QuotaObjects (nolock) WHERE QO_ID in (SELECT QL_QOID FROM #QuotaLoadList (nolock) WHERE QL_QOID is not null)
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

-- удаляем вспомогательный столбец
alter table #QuotaLoadList drop column QL_QOID

IF @ResultType is null or @ResultType not in (10)
BEGIN
	select * 
	from #QuotaLoadList (nolock)
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

-- sp_GetServiceList.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceList]
GO

CREATE procedure [dbo].[GetServiceList] 
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
	DG_Code nvarchar(max), DG_Key int, DG_DiscountSum money, DG_Price money, DG_Payed money,
	DG_PriceToPay money, DG_Rate nvarchar(3), DG_NMen int, PR_Name nvarchar(max), CR_Name nvarchar(max),
	DL_Key int, DL_NDays int, DL_NMen int, DL_Reserved int, DL_CTKeyTo int, DL_CTKeyFrom int, DL_CNKEYFROM int,
	DL_SubCode1 int, TL_Key int, TL_Name nvarchar(max), TUCount int, TU_NameRus nvarchar(max), TU_NameLat nvarchar(max),
	TU_FNameRus nvarchar(max), TU_FNameLat nvarchar(max), TU_Key int, TU_Sex Smallint, TU_PasportNum nvarchar(max),
	TU_PasportType nvarchar(max), TU_PasportDateEnd datetime, TU_BirthDay datetime, TU_Hotels nvarchar(max),
	Request smallint, Commitment smallint, Allotment smallint, Ok smallint, TicketNumber nvarchar(max),
	FlightDepDLKey int, FligthDepDate datetime, FlightDepNumber nvarchar(max), ServiceDescription nvarchar(max),
	ServiceDateBeg datetime, ServiceDateEnd datetime, RM_Name nvarchar(max), RC_Name nvarchar(max), SD_RLID int,
	TU_SNAMERUS nvarchar(max), TU_SNAMELAT nvarchar(max)
)
 
if @TypeOfRelult = 2
begin
	--- создаем таблицу в которой пронгумируем незаполненых туристов
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
	and exists (select 1 from ServiceByDate as SSD2 where SSD.SD_DLKey = SSD2.SD_DLKey and SSD2.SD_Date = @Date)

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
		TU_Sex, TU_PasportNum, TU_PasportType, TU_PasportDateEnd, TU_BirthDay, TicketNumber, TU_SNAMERUS, TU_SNAMELAT) 
		SELECT	  DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, 
		(case DG_PDTTYPE when 1 then DG_PRICE+DG_DISCOUNTSUM else DG_PRICE end ), DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, 
		DL_DateBeg, CASE WHEN ' + CAST(@SVKey as varchar(10)) + '=3 THEN DATEADD(DAY,1,DL_DateEnd) ELSE DL_DateEnd END,
		DG_TRKey, 0, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS, TU_FNAMELAT, SD_TUKey, case when SD_TUKey > 0 then isnull(TU_SEX,0) else null end, TU_PASPORTTYPE + '' '' + TU_PASPORTNUM, TU_PASPORTTYPE, 
		TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, TU_SNAMERUS, TU_SNAMELAT
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
		SET @Query=@Query + ' 
		group by DG_CODE, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED, DG_PDTTYPE, DG_RATE, DG_NMEN, 
		PR_NAME, CR_NAME, DL_KEY, DL_NDays, DL_NMEN, DL_RESERVED, DL_CTKey, DL_SubCode2, DL_SubCode1, DL_DateBeg,
		DL_DateEnd, DG_TRKey, TU_NAMERUS, TU_NAMELAT, TU_FNAMERUS,
		TU_FNAMELAT, SD_TUKey, TU_SEX, TU_PASPORTNUM, TU_PASPORTTYPE, TU_PASPORTDATEEND, TU_BIRTHDAY, TU_NumDoc, SD_RPID, TU_SNAMERUS, TU_SNAMELAT'
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
		PR_NAME, CR_NAME, DL_NDays, case when QT_ByRoom = 1 then count(distinct SD_RLID) else count(distinct SD_RPID) end as DL_NMEN,
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
		left join Turistservice on tu_dlkey=dl_key
		where DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' AND DL_CODE in (' + @Codes + ') AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND'
		
	if @QDID is not null
		SET @Query = @Query + ' and qp_qdid = ' + CAST(@QDID as nvarchar(max))
	if @QPID is not null
		SET @Query = @Query + ' and qp_id = ' + CAST(@QPID as nvarchar(max))
	
	SET @Query = @Query + '
		group by DG_CODE, SD_RLID, DG_KEY, DG_DISCOUNTSUM, DG_PRICE, DG_PAYED,
		DG_PDTTYPE, DG_PRICE, DG_DISCOUNTSUM, DG_PRICE, DG_RATE, DG_NMEN,
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


-- sp_mwEnablePriceTour.sql
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwEnablePriceTour]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwEnablePriceTour]
GO

CREATE procedure [dbo].[mwEnablePriceTour] @tourkey int, @enabled smallint, @calcKey int = null
as
begin
	update tp_tours with(rowlock)
	set to_isenabled = @enabled
	where to_key = @tourkey


	declare @cityFromKey int
	declare @countryKey int

	select @countryKey = sd_cnkey, @cityFromKey = sd_ctkeyfrom from dbo.mwSpoDataTable where sd_tourkey = @tourkey 

	declare @today varchar(10)
	set @today = '''' + convert(varchar(10),getdate(), 112 ) + ''''

	declare @mwSinglePrice nvarchar(10)
	select @mwSinglePrice = isnull(dbo.GetCountrySetting(@countryKey, 'mwSinglePrice'), N'0')
	
	if (dbo.mwReplIsPublisher() > 0)
		set @mwSinglePrice = '0'

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
			where pt_tourdate >= ' + @today +' and pt_tourkey = ' + CAST(@tourkey as varchar)

			exec (@sql)
		end

		if(@calcKey is null)
		begin
			set @sql = '
			update ' + @tableName + ' with(rowlock)
			set pt_isenabled = ' + CAST(@enabled as varchar) + ', pt_autodisabled = 0
			where pt_tourkey = ' + CAST(@tourkey as varchar)
		end
		else
		begin
			set @sql = '
			update ' + @tableName + ' with(rowlock)
			set pt_isenabled = ' + CAST(@enabled as varchar) + ', pt_autodisabled = 0
			where pt_pricekey in (select tp_key from tp_prices with(nolock) where TP_CalculatingKey = ' + CAST(@calcKey as varchar) + ') '
		end

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
			where pt_tourdate >= ' + @today +'
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
			where pt_tourdate >= ' + @today +'
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
GO

GRANT EXEC ON [dbo].[mwEnablePriceTour] TO PUBLIC
GO

-- sp_SetServiceStatusOK.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetServiceStatusOK]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetServiceStatusOK]
GO
CREATE PROCEDURE [dbo].[SetServiceStatusOK]
	(
		@DLKEY int
	)
AS
BEGIN
	-- теперь в завмсимости от настроек будем менять статусы на Ок
	-- 0 - все галки сняты
	-- 1 - Все услуги
	-- 2 - Авиаперелет
	-- 3 - Все услуги & Авиаперелет
	-- 4 - Проживание
	-- 5 - Все услуги & Проживание
	-- 6 - Авиаперелет & Проживание
	-- 7 - Все услуги & Авиаперелет & Проживание
	
	-- Авиаперелет
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('2', '3', '6', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		update Dogovorlist
		set DL_CONTROL = 0
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_SvKey = 1 and DL_Control != 0
	end
	
	-- Проживание
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('4', '5', '6', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		update Dogovorlist
		set DL_CONTROL = 0
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_SvKey = 3 and DL_Control != 0
	end
	
	-- Все услуги
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('1', '3', '5', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		update Dogovorlist
		set DL_CONTROL = 0
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_SvKey != 3 
		and DL_SvKey != 1
		and DL_Control != 0
	end
	
	
	-- MEG00032041
	-- Теперь проверим есть ли на эту квоту запись в таблице QuotaStatuses
	-- которая говорит нам что нужно изменить статус услуги на тот который в этой таблице
	if exists(select 1 
				from QuotaStatuses join Quotas on QS_QTID = QT_ID 
				join QuotaDetails on QT_ID = QD_QTID
				join QuotaParts on QP_QDID = QD_ID
				join ServiceByDate on SD_QPID = QP_ID
				where SD_DLKey = @DLKEY and SD_State = QS_Type) 
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @DLKEY),4) < 4
	begin
		declare @DLCONTROL int
		
		select @DLCONTROL = QS_CRKey
		from QuotaStatuses join Quotas on QS_QTID = QT_ID 
		join QuotaDetails on QT_ID = QD_QTID
		join QuotaParts on QP_QDID = QD_ID
		join ServiceByDate on SD_QPID = QP_ID
		where SD_DLKey = @DLKEY and SD_State = QS_Type
	
		update Dogovorlist
		set DL_CONTROL = @DLCONTROL
		from Dogovorlist 
		where DL_KEY = @DLKey
		and DL_Control != @DLCONTROL
	end
END
GO
grant exec on [dbo].[SetServiceStatusOK] to public
go


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
	DECLARE @ManName varchar(70)
		  , @ManPhone varchar(50)
		  , @ManAddress varchar(320)
		  , @ManPassport varchar(70)
		  , @ManSName char(15);
	SET @ManSName = ISNULL(@SName,'');
	SET @ManName = ISNULL(@Name,'') +' '+ ISNULL(@FName,'') +' '+ @ManSName;
	IF (LEN(ISNULL(@Phone,'')) > 30)
		SET @ManPhone = SUBSTRING(@Phone,1,30);
	ELSE
		SET @ManPhone = ISNULL(@Phone,'');
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
	EXEC [dbo].[UpdateReservationMainMan] @ManName, @ManPhone, @ManAddress
	                                    , @ManPassport, @ReservationCode
END
go
GRANT EXECUTE ON [dbo].[UpdateReservationMainManByTourist] TO PUBLIC
go


-- sp_GetPartnerCommission.sql
if EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[GetPartnerCommission]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[GetPartnerCommission]
GO

CREATE PROCEDURE [dbo].[GetPartnerCommission] 
     @nTLKey int,
     @nPRKey int,
     @nBTKey int,
     @nDSKey int output,
     @nValue money output,
     @nIsPercent int output, 
       @dCheckinDate datetime,
      @nCNKey int=0,
      @DGCreateDate datetime = null,
      @nDepartureCity int = 0,
      @sDiscountCode varchar(5) = null,
      @sDiscountNumber varchar(10) = null,
      @price decimal(16,6) = null,
      @rate varchar(3) = null,
      @dogovorCode varchar(10) = null
AS
-- mv 26.08.2011 Изменил условие в ORDER (DS_Priority --> DS_Priority desc)
      declare @discountSettingValue varchar(256)
      select @discountSettingValue = ISNULL(SS_ParmValue, '0') from dbo.SystemSettings where SS_ParmName like 'SYSUseDiscountCards'
      if @discountSettingValue = '1' and ISNULL(@sDiscountCode, '') != '' and ISNULL(@sDiscountNumber, '') != ''
      begin
            
            declare @discountCode varchar(5)
            declare @discountNumber varchar(10)
            declare @reservationsCount int, @cardKey int
            declare @reservationsPrice decimal(16,6)
            declare @nationalRate varchar(3)
            declare @discount money
            declare @discountId int

            if (ISNULL(@dogovorCode, '') = '')
            begin
                  set @sDiscountCode = rtrim(ltrim(@sDiscountCode))
                  set @sDiscountNumber = rtrim(ltrim(@sDiscountNumber))
                        
                  select @cardKey = CD_Key from Cards where ISNULL(CD_Code, '') = ISNULL(@sDiscountCode, '') and ISNULL(CD_Number, '') = ISNULL(@sDiscountNumber, '')
                  select @reservationsCount = count(RR_ID) from ReservationsRegister where RR_CardKey in (select CD_Key from dbo.Cards where CD_Code like ISNULL(@sDiscountCode, ''))
                  select @reservationsPrice = sum(DG_NationalCurrencyPrice) from Dogovor where DG_CODE in (select RR_DGCODE  COLLATE Cyrillic_General_CI_AS from ReservationsRegister where RR_CardKey in (select CD_Key from dbo.Cards where CD_Code like ISNULL(@sDiscountCode, '')))
                  select @nationalRate = RA_Code from dbo.Rates where RA_National = 1
                  exec ExchangeCost @price output, @rate, @nationalRate, @dCheckinDate

                  set @reservationsPrice = ISNULL(@reservationsPrice, 0)
            
                  select top 1 @discount = cast(ISNULL(DS_DISCOUNT, 0) as money), @discountId = DS_ID  
                        from dbo.DiscountScheme, dbo.TurList, dbo.TurService where 
                        TL_Key = @nTLKey and 
                        TS_TRKey = TL_Key and
                        DS_Series like @sDiscountCode and
                        ((DS_CityFromKey is not null and DS_CityFromKey = TL_CTDepartureKey) or (DS_CityFromKey is null)) and
                        ((DS_CountryKey is not null and DS_CountryKey = TL_CNKey) or (DS_CountryKey is null)) and
                        ((DS_CityKey is not null and DS_CityKey = TS_CTKey) or (DS_CityKey is null)) and
                        ((DS_TourTypeKey is not null and DS_TourTypeKey = TL_TIP) or (DS_TourTypeKey is null)) and
                        ((DS_ReservationsFrom is not null and DS_ReservationsFrom <= (@reservationsCount + 1)) or (DS_ReservationsFrom is null)) and
                        ((DS_ReservationsTo is not null and DS_ReservationsTo >= (@reservationsCount + 1)) or (DS_ReservationsTo is null)) and
                        ((DS_TotalCostFrom is not null and DS_TotalCostFrom <= (@reservationsPrice + @price)) or (DS_TotalCostFrom is null)) and
                        ((DS_TotalCostTo is not null and DS_TotalCostTo >= (@reservationsPrice + @price)) or (DS_TotalCostTo is null)) and
                        ((DS_TotalCostTo is not null and DS_TotalCostTo >= (@reservationsPrice + @price)) or (DS_TotalCostTo is null)) and
                        ((DS_MinPrice is not null and DS_MinPrice <= @price) or (DS_MinPrice is null))
                  order by DS_ID DESC

                  set @nDSKey = -1
                  set @nValue = @discount
                  set @nIsPercent = 1
                  return 1
            end
            else
            begin
                  
                  select @discount = DD_DiscountPercent from dbo.DogovorDetails where DD_DGCODE like @dogovorCode
                  set @discount = ISNULL(@discount, 0)
                  set @nDSKey = -1
                  set @nValue = @discount
                  set @nIsPercent = 1
                  return 1
            end
            
      end

     if @nPRKey = 0
     begin
          set @nDSKey = -1     
          set @nValue = 0     
          set @nIsPercent = 1     
              return 0
     end

      declare @nPGKey int, @nTpKey int, @nAttr int, @nCTDepartureKey int
      set @nTpKey=0
      if    @nPRKey>0
            select @nPGKey = PR_PGKey from Partners where PR_Key = @nPRKey
      else
            set @nPGKey=0
      if @nTLKey>0
            select @nCNKey = TL_CNKey, @nTpKey=TL_TIP, @nAttr = isnull(TL_Attribute, 0) 
            from TurList where TL_Key = @nTLKey

      declare @discountAction int
      set @discountAction = 0
      if @nAttr & 16 > 0
            set @discountAction = 1
      
      if @dCheckinDate is null
            SET @dCheckinDate=ISNULL(@dCheckinDate,GetDate())
     if @nBTKey = 0 or @nBTKey is null
     begin
          select @nDSKey = DS_Key, @nValue = DS_Value, @nIsPercent = DS_IsPercent from Discounts
          where DS_PRKey IN(0, @nPRKey) AND DS_BTKey IN (0, @nBTKey) AND DS_PGKey IN (0, @nPGKey) 
                        AND DS_TLKey IN (0, @nTLKey) AND DS_CNKey IN (0, @nCNKey) AND DS_TPKEY IN (0,@nTpKey)
                        AND @dCheckinDate between ISNULL(DS_CheckInFrom,'30-DEC-1899') and ISNULL(DS_CheckInTo,'30-DEC-2200')
                        AND DATEDIFF(d, GetDate(), @dCheckinDate) <= ISNULL(DS_DaysBeforeCheckIn, 99999)
                        AND ISNULL(@DGCreateDate, ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899')) between ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899') and ISNULL(DS_DogovorCreateDateTo,'30-DEC-2200')
                        AND (CASE WHEN @discountAction = 0 THEN ISNULL(DS_DAKey, 0) ELSE 0 END) = 0
                        AND DS_DepartureCityKey IN (0, @nDepartureCity)
          order by DS_Priority desc, DS_BTKey desc, DS_TLKey, DS_CNKey,DS_TPKEY, DS_PRKey, DS_PGKey, DS_DepartureCityKey, @dCheckinDate - ISNULL(DS_DaysBeforeCheckIn, 77777) asc, DS_DogovorCreateDateFrom asc, DS_DogovorCreateDateTo asc, DS_DAKey asc
     end
     else
     begin
          select @nDSKey = DS_Key, @nValue = DS_Value, @nIsPercent = DS_IsPercent from Discounts
          where DS_PRKey IN(0, @nPRKey) AND DS_BTKey IN (0, @nBTKey) AND DS_PGKey IN (0, @nPGKey) 
                        AND DS_TLKey IN (0, @nTLKey) AND DS_CNKey IN (0, @nCNKey) AND DS_TPKEY IN (0,@nTpKey)
                        AND @dCheckinDate between ISNULL(DS_CheckInFrom,'30-DEC-1899') and ISNULL(DS_CheckInTo,'30-DEC-2200')
                        AND DATEDIFF(d, GetDate(), @dCheckinDate) <= ISNULL(DS_DaysBeforeCheckIn, 99999)
                        AND ISNULL(@DGCreateDate, ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899')) between ISNULL(DS_DogovorCreateDateFrom,'30-DEC-1899') and ISNULL(DS_DogovorCreateDateTo,'30-DEC-2200')
                        AND (CASE WHEN @discountAction = 0 THEN ISNULL(DS_DAKey, 0) ELSE 0 END) = 0
                        AND DS_DepartureCityKey IN (0, @nDepartureCity)
          order by DS_Priority desc, DS_BTKey, DS_TLKey, DS_CNKey, DS_TPKEY,DS_PRKey, DS_PGKey, DS_DepartureCityKey, @dCheckinDate - ISNULL(DS_DaysBeforeCheckIn, 77777) asc, DS_DogovorCreateDateFrom asc, DS_DogovorCreateDateTo asc, DS_DAKey asc
     end

     if @nDSKey is null
     begin
          set @nDSKey = -1     
          set @nValue = 0     
          set @nIsPercent = 1     
     end

GO

grant execute on [dbo].[GetPartnerCommission] to public
GO

-- sp_AutoQuotesPlaces.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AutoQuotesPlaces]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[AutoQuotesPlaces]
GO

CREATE PROCEDURE [dbo].[AutoQuotesPlaces]
	(
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
	declare @Date datetime, @RLID int 
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

	DECLARE cur_DogovorListAutoQuotesPlaces CURSOR FOR
		SELECT 	DL_Key,DL_SvKey, DL_Code, DL_SubCode1, DL_DateBeg, DL_DateEnd, DL_NMen, DL_QuoteKey
		FROM	Dogovorlist join @dlKeyList on dl_key = dlKey
		
	OPEN cur_DogovorListAutoQuotesPlaces
	FETCH NEXT FROM cur_DogovorListAutoQuotesPlaces
		INTO @DLKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		--в этой хранимке будет выполнена попытка постановки услуги на квоту
		EXEC DogListToQuotas @DLKey,null,null,null,null,@DLDateBeg, @DLDateEnd,null,null
				
		FETCH NEXT FROM cur_DogovorListAutoQuotesPlaces
		INTO @DLKey, @DLSVKey, @DLCode, @DLSubCode1, @DLDateBeg, @DLDateEnd, @DLNMen, @QuoteKey
	
	ENd
	CLOSE cur_DogovorListAutoQuotesPlaces
	DEALLOCATE   cur_DogovorListAutoQuotesPlaces

end

GO

grant exec on [dbo].[AutoQuotesPlaces] to public
go

-- sp_QuotaDetailsAfterDelete.sql
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotaDetailAfterDelete]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[QuotaDetailAfterDelete]
GO

CREATE PROCEDURE [dbo].[QuotaDetailAfterDelete]
AS
--<VERSION>2008.1.01.05a</VERSION>
--Процедура освобождает удаленные квоты
--QD_IsDeleted хранит статус, в который требуется поставить услуги, на данный момент находящиеся на данной квоте
--QD_IsDeleted=3 - подтвердить (ВАЖНО подтверждается только те даты которые удаляются)
--QD_IsDeleted=4 - Request (ВАЖНО на Request только те даты которые удаляются)
--QD_IsDeleted=1 - попытка поставить на квоту (ВАЖНО на квоту пробуем поставить место, на всем протяжении услуги, то есть - если это проживание и только один день удаляем из квоты, то место снимается с квоты целиком и пытается сесть снова)

IF Exists (SELECT top 1 1 FROM QuotaDetails with (nolock),QuotaParts with (nolock),ServiceByDate with (nolock) WHERE QP_QDID=QD_ID and SD_QPID=QP_ID and QD_IsDeleted in (3,4))
BEGIN
	UPDATE ServiceByDate with (rowlock) SET SD_State=3,SD_QPID=null WHERE SD_QPID in (SELECT QP_ID FROM QuotaDetails with (nolock),QuotaParts with (nolock) WHERE QP_QDID=QD_ID and QD_IsDeleted=3)
	UPDATE ServiceByDate with (rowlock) SET SD_State=4,SD_QPID=null WHERE SD_QPID in (SELECT QP_ID FROM QuotaDetails with (nolock),QuotaParts with (nolock) WHERE QP_QDID=QD_ID and QD_IsDeleted=4)
END
IF Exists (SELECT top 1 1 FROM QuotaDetails with (nolock),QuotaParts with (nolock),ServiceByDate with (nolock) WHERE QP_QDID=QD_ID and SD_QPID=QP_ID and QD_IsDeleted in (1))
BEGIN
	DECLARE @SD_DLKey int
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

update QuotaParts
set QP_IsDeleted = 1
from QuotaParts join QuotaDetails on QP_QDID = QD_ID
where QD_IsDeleted in (1,3,4)

DELETE FROM QuotaLimitations with (rowlock) WHERE QL_QPID in (SELECT QP_ID FROM QuotaParts with (nolock), QuotaDetails with (nolock) WHERE QD_ID=QP_QDID and QD_IsDeleted in (1,3,4))
delete QuotaParts with (rowlock) 
where exists(select top 1 1 from QuotaDetails with (nolock) WHERE QD_IsDeleted in (1,3,4) and QD_ID = QP_QDID)
	and not exists(select top 1 1 from ServiceByDate with(nolock) where SD_QPID=QP_ID)
and QP_IsDeleted = 1
DELETE FROM StopSales with (rowlock) WHERE SS_QDID in (SELECT QD_ID FROM QuotaDetails with (nolock) WHERE QD_IsDeleted in (1,3,4))
DELETE FROM QuotaDetails with (rowlock) WHERE QD_IsDeleted in (1,3,4)
		and QD_ID not in (Select QP_QDID from ServiceByDate with (nolock), QuotaParts with (nolock) where SD_QPID=QP_ID and QP_QDID=QD_ID)

GO

grant exec on [dbo].[QuotaDetailAfterDelete] to public
go