/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 29.11.2012 15:19 %%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*********************************************************************/
/* begin (20120123)_CreateTable_PrintDocumentsRules.sql */
/*********************************************************************/
-- MEG00038973 23.01.2012 Создание таблицы Правила печати документов
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PrintDocumentsRules]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PrintDocumentsRules](
	[PDR_ID] [int] IDENTITY(1,1) NOT NULL,
	[PDR_DepCTKey] [int] NULL,
	[PDR_CNKey] [int] NULL,
	[PDR_CTKey] [int] NULL,
	[PDR_TourTypeKey] [int] NULL,
	[PDR_TourKey] [int] NULL,
	[PDR_FilialKey] [int] NULL,
	[PDR_AgentKey] [int] NULL,
	[PDR_TourDateFrom] [DateTime] NULL,
	[PDR_TourDateTo] [DateTime] NULL,
	[PDR_Priority] [int] NULL,
	[PDR_Disabled] [int] NULL
 CONSTRAINT [PK_PrintDocumentsRules] PRIMARY KEY CLUSTERED 
(
	[PDR_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.PrintDocumentsRules TO PUBLIC


ALTER TABLE [dbo].[PrintDocumentsRules] ADD CONSTRAINT [FK_PrintDocumentsRules_DepCityDictionary] 
FOREIGN KEY([PDR_DepCTKey]) REFERENCES [dbo].[CityDictionary] ([CT_KEY]) 
--ON DELETE CASCADE

ALTER TABLE [dbo].[PrintDocumentsRules] ADD CONSTRAINT [FK_PrintDocumentsRules_tbl_Country] 
FOREIGN KEY([PDR_CNKey]) REFERENCES [dbo].[tbl_Country] ([CN_KEY])

ALTER TABLE [dbo].[PrintDocumentsRules] ADD CONSTRAINT [FK_PrintDocumentsRules_CityDictionary] 
FOREIGN KEY([PDR_CTKey]) REFERENCES [dbo].[CityDictionary] ([CT_KEY]) ON DELETE CASCADE

ALTER TABLE [dbo].[PrintDocumentsRules] ADD CONSTRAINT [FK_PrintDocumentsRules_TipTur] 
FOREIGN KEY([PDR_TourTypeKey]) REFERENCES [dbo].[TipTur] ([TP_KEY]) ON DELETE CASCADE

ALTER TABLE [dbo].[PrintDocumentsRules] ADD CONSTRAINT [FK_PrintDocumentsRules_tbl_TurList] 
FOREIGN KEY([PDR_TourKey]) REFERENCES [dbo].[tbl_TurList] ([TL_KEY]) ON DELETE CASCADE

ALTER TABLE [dbo].[PrintDocumentsRules] ADD CONSTRAINT [FK_PrintDocumentsRules_tbl_Partners_Filial] 
FOREIGN KEY([PDR_FilialKey]) REFERENCES [dbo].[tbl_Partners] ([PR_KEY]) ON DELETE CASCADE

ALTER TABLE [dbo].[PrintDocumentsRules]  WITH CHECK ADD CONSTRAINT [FK_PrintDocumentsRules_tbl_Partners_Agent] 
FOREIGN KEY([PDR_AgentKey]) REFERENCES [dbo].[tbl_Partners] ([PR_KEY]) 
--ON DELETE CASCADE

END
GO
/*********************************************************************/
/* end (20120123)_CreateTable_PrintDocumentsRules.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120123)_CreateTable_DocumentGroups.sql */
/*********************************************************************/
-- MEG00038973 23.01.2012 Создание таблицы Группы документов
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DocumentGroups]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DocumentGroups](
	[DCG_ID] [int] IDENTITY(1,1) NOT NULL,
	[DCG_Name] [nvarchar](250) NULL,
	[DCG_NameLat] [nvarchar](250) NULL
 CONSTRAINT [PK_DocumentGroups] PRIMARY KEY CLUSTERED 
(
	[DCG_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.DocumentGroups TO PUBLIC
END
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentGroups] WHERE DCG_Name LIKE '%Не задано%')
INSERT INTO [dbo].[DocumentGroups](DCG_Name,DCG_NameLat)
VALUES ('Не задано','Not set')

IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentGroups] WHERE DCG_Name LIKE '%Авиа%')
INSERT INTO [dbo].[DocumentGroups](DCG_Name,DCG_NameLat)
VALUES ('Авиа','Air')

IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentGroups] WHERE DCG_Name LIKE '%Документы по туру%')
INSERT INTO [dbo].[DocumentGroups](DCG_Name,DCG_NameLat)
VALUES ('Документы по туру','Documents for tour')

IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentGroups] WHERE DCG_Name LIKE '%Финансовые%')
INSERT INTO [dbo].[DocumentGroups](DCG_Name,DCG_NameLat)
VALUES ('Финансовые','Financial')

GO
/*********************************************************************/
/* end (20120123)_CreateTable_DocumentGroups.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120123)_CreateTable_Documents.sql */
/*********************************************************************/
-- MEG00038973 23.01.2012 Создание таблицы Документы
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Documents]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Documents](
	[DC_ID] [int] IDENTITY(1,1) NOT NULL,
	[DC_PDRID] [int] NULL,
	[DC_DCGID] [int] NULL,
	[DC_ReportFormat] [int] NULL,
	[DC_RepProfileKey] [int] NULL,
	[DC_WebName] [nvarchar](250) NULL,
	[DC_PartnerKey] [int] NULL,
	[DC_SVKeyRequired] [int] NULL,
	[DC_PrintConditionsXML] [nvarchar](max) NULL,
 CONSTRAINT [PK_Documents] PRIMARY KEY CLUSTERED 
(
	[DC_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Documents TO PUBLIC

ALTER TABLE [dbo].[Documents] ADD CONSTRAINT [FK_Documents_PrintDocumentsRules] 
FOREIGN KEY([DC_PDRID]) REFERENCES [dbo].[PrintDocumentsRules] ([PDR_ID]) ON DELETE CASCADE

ALTER TABLE [dbo].[Documents] ADD CONSTRAINT [FK_Documents_DocumentGroups] 
FOREIGN KEY([DC_DCGID]) REFERENCES [dbo].[DocumentGroups] ([DCG_ID]) ON DELETE CASCADE

ALTER TABLE [dbo].[Documents] ADD CONSTRAINT [FK_Documents_Rep_Profiles] 
FOREIGN KEY([DC_RepProfileKey]) REFERENCES [dbo].[Rep_Profiles] ([RP_KEY]) ON DELETE CASCADE

ALTER TABLE [dbo].[Documents] ADD CONSTRAINT [FK_Documents_tbl_Partners] 
FOREIGN KEY([DC_PartnerKey]) REFERENCES [dbo].[tbl_Partners] ([PR_KEY]) --ON DELETE CASCADE

ALTER TABLE [dbo].[Documents] ADD CONSTRAINT [FK_Documents_Service] 
FOREIGN KEY([DC_SVKeyRequired]) REFERENCES [dbo].[Service] ([SV_KEY]) ON DELETE CASCADE

-- Добавляем null запись - в ней будут храниться общие настройки для всех документов
INSERT INTO [dbo].[Documents] (DC_PrintConditionsXML) VALUES (NULL)

END
GO
/*********************************************************************/
/* end (20120123)_CreateTable_Documents.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120207)_CreateTable_PrintDocumentStatuses.sql */
/*********************************************************************/
-- MEG00038973 23.01.2012 Создание таблицы Группы документов
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PrintDocumentStatuses]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PrintDocumentStatuses](
	[PDS_ID] [int] IDENTITY(1,1) NOT NULL,
	[PDS_Name] [nvarchar](250) NULL,
	[PDS_NameLat] [nvarchar](250) NULL
 CONSTRAINT [PK_PrintDocumentStatuses] PRIMARY KEY CLUSTERED 
(
	[PDS_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.PrintDocumentStatuses TO PUBLIC

INSERT INTO PrintDocumentStatuses(PDS_Name,PDS_NameLat) VALUES ('Не распечатан','Not printed')
INSERT INTO PrintDocumentStatuses(PDS_Name,PDS_NameLat) VALUES ('Распечатан','Printed')
INSERT INTO PrintDocumentStatuses (PDS_Name,PDS_NameLat) VALUES ('Распечатан с ошибкой','Printed with error')

END
GO
/*********************************************************************/
/* end (20120207)_CreateTable_PrintDocumentStatuses.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120207)_CreateTable_DogovorDocuments.sql */
/*********************************************************************/
-- MEG00038973 10.02.2012 Создание таблицы связи путевок и документов
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogovorDocuments]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DogovorDocuments](
	[DD_ID] [int] IDENTITY(1,1) NOT NULL,
	[DD_DGKey] [int] NULL,
	[DD_DCID] [int] NULL,
	[DD_FHID] [int] NULL,
	[DD_PDSID] [int] NULL,
	[DD_MarkedForPrint] [int] NULL,
	[DD_MarkedForEmail] [int] NULL,
	[DD_IssuedToCourier] [int] NULL,
 CONSTRAINT [PK_DogovorDocuments] PRIMARY KEY CLUSTERED 
(
	[DD_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.DogovorDocuments TO PUBLIC

ALTER TABLE [dbo].[DogovorDocuments] ADD CONSTRAINT [FK_DogovorDocuments_Dogovor] 
FOREIGN KEY([DD_DGKey]) REFERENCES [dbo].[tbl_Dogovor] ([DG_KEY]) ON DELETE CASCADE

ALTER TABLE [dbo].[DogovorDocuments] ADD CONSTRAINT [FK_DogovorDocuments_Documents] 
FOREIGN KEY([DD_DCID]) REFERENCES [dbo].[Documents] ([DC_ID]) ON DELETE CASCADE

ALTER TABLE [dbo].[DogovorDocuments] ADD CONSTRAINT [FK_DogovorDocuments_FileHeaders] 
FOREIGN KEY([DD_FHID]) REFERENCES [dbo].[FileHeaders] ([FH_ID]) ON DELETE CASCADE

ALTER TABLE [dbo].[DogovorDocuments] ADD CONSTRAINT [FK_DogovorDocuments_PrintDocumentStatuses] 
FOREIGN KEY([DD_PDSID]) REFERENCES [dbo].[PrintDocumentStatuses] ([PDS_ID]) ON DELETE CASCADE

END
GO
/*********************************************************************/
/* end (20120207)_CreateTable_DogovorDocuments.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120222)_Insert_ObjectAliases.sql */
/*********************************************************************/
-- MEG00038973 22.02.2012 Kolbeshkin добавление алиаса для записи в историю при ошибке в шаблоне отчетов
IF NOT EXISTS (SELECT 1 FROM ObjectAliases WHERE OA_Id=45)
INSERT INTO ObjectAliases (OA_Id,OA_Alias,OA_Name,OA_TABLEID) VALUES (45,'ErrorInReportTemplate','Ошибка в шаблоне при печати отчета',0)
GO
/*********************************************************************/
/* end (20120222)_Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120312)_AlterTable_FileHeaders_AlterConstraint_FH_DocType.sql */
/*********************************************************************/
-- MEG00038973 12.03.2012 Kolbeshkin перевешиваем Тип прикрепленного файла на Группу документов
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_FileHeaders_FileHeadersDocType]') AND parent_object_id = OBJECT_ID(N'[dbo].[FileHeaders]'))
ALTER TABLE [dbo].[FileHeaders] DROP CONSTRAINT [FK_FileHeaders_FileHeadersDocType]
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FileHeadersDocType]') AND type in (N'U'))
BEGIN
UPDATE [dbo].[FileHeaders] SET FH_DocType = (SELECT DCG_ID FROM [dbo].[DocumentGroups] WHERE DCG_Name LIKE '%Не задано%') 
WHERE FH_DocType IN (SELECT FT_Key FROM [dbo].[FileHeadersDocType] WHERE FT_Name LIKE '%Не задан%')

UPDATE [dbo].[FileHeaders] SET FH_DocType = (SELECT DCG_ID FROM [dbo].[DocumentGroups] WHERE DCG_Name LIKE '%Финансовые%') 
WHERE FH_DocType IN (SELECT FT_Key FROM [dbo].[FileHeadersDocType] WHERE FT_Name LIKE '%Счет%')
END
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_FileHeaders_DocumentGroups]') AND parent_object_id = OBJECT_ID(N'[dbo].[FileHeaders]'))
	ALTER TABLE [dbo].[FileHeaders]  WITH NOCHECK ADD CONSTRAINT [FK_FileHeaders_DocumentGroups] 
	FOREIGN KEY([FH_DocType]) REFERENCES [dbo].[DocumentGroups] ([DCG_ID]) 
GO




/*********************************************************************/
/* end (20120312)_AlterTable_FileHeaders_AlterConstraint_FH_DocType.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120328)_AlterTable_PrintDocumentRules_DropConstraint_DepCity.sql */
/*********************************************************************/
-- MEG00038973 28.03.2012 Kolbeshkin удаление FK_PrintDocumentsRules_DepCityDictionary,
-- чтобы можно было сохранить город вылета "Не выбрано" (ключ=0), которого нет в таблице городов
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PrintDocumentsRules_DepCityDictionary]') AND parent_object_id = OBJECT_ID(N'[dbo].[PrintDocumentsRules]'))
ALTER TABLE [dbo].[PrintDocumentsRules] DROP CONSTRAINT [FK_PrintDocumentsRules_DepCityDictionary]
GO



/*********************************************************************/
/* end (20120328)_AlterTable_PrintDocumentRules_DropConstraint_DepCity.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ChangeIvalidReservationState.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[sp_ChangeIvalidReservationState]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_ChangeIvalidReservationState]
GO

-- =============================================
-- Author:		Shtuber
-- Create date: 17.08.2012
-- Description:	Переводит заявки со статусом -1 в указанный статус. Нужна для запуска из джоба.
-- WorkAround для ситуации, когда вследствие большой нагрузки на базу, заявка ложиться не полностью и с кривым статусом.
-- Джоб запускается, меняется статус на вменяемый, менеджеры могут такие заявки отслеживать в экране "работа менеджеров".
-- =============================================
CREATE PROCEDURE [dbo].[sp_ChangeIvalidReservationState] 
(
	@stateId int
)
AS
BEGIN

--<VERSION>ALL</VERSION>
--<DATE>2011-10-13</DATE>

update tbl_Dogovor set DG_SOR_CODE = @stateId where DG_SOR_CODE = -1
	
END

GO

GRANT EXECUTE ON [dbo].[sp_ChangeIvalidReservationState] TO [public]
GO
/*********************************************************************/
/* end sp_ChangeIvalidReservationState.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120828)_Insert_ObjectAliases.sql */
/*********************************************************************/
-- CRM02730P9D9 26.08.2012 kolbeshkin: добавление алиаса для фиксации изменения услуг из OptionalServiceBooking
if not exists (select 1 from objectaliases where oa_id=1149)
insert into objectaliases (OA_ID,OA_Alias,OA_Name)
values (1149,'OptionalServiceBooking_ServicesChange','Изменение услуг в путевке из модуля OptionalServiceBooking')
go
/*********************************************************************/
/* end (20120828)_Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20120829_Insert_ProviderStatuses.sql */
/*********************************************************************/
if not exists(select 1 from ProviderStatuses where PS_KEY = 0)
begin
set identity_insert ProviderStatuses on

insert into ProviderStatuses (PS_KEY,PS_NAME,PS_NAMELAT) values (0,'','')

set identity_insert ProviderStatuses off
end

go
/*********************************************************************/
/* end 20120829_Insert_ProviderStatuses.sql */
/*********************************************************************/

/*********************************************************************/
/* begin CREATE_Table_CostOfferCrossSaleDate.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CostOfferCrossSaleDate]') AND type in (N'U'))
begin
	IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CostOfferCrossSaleDate_CostOffers]') AND parent_object_id = OBJECT_ID(N'[dbo].[CostOfferCrossSaleDate]'))
		ALTER TABLE [dbo].[CostOfferCrossSaleDate] DROP CONSTRAINT [FK_CostOfferCrossSaleDate_CostOffers]

	IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CostOfferCrossSaleDate_Service]') AND parent_object_id = OBJECT_ID(N'[dbo].[CostOfferCrossSaleDate]'))
		ALTER TABLE [dbo].[CostOfferCrossSaleDate] DROP CONSTRAINT [FK_CostOfferCrossSaleDate_Service]
	
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CostOfferCrossSaleDate]') AND type in (N'U'))
		DROP TABLE [dbo].[CostOfferCrossSaleDate]
	
	CREATE TABLE [dbo].[CostOfferCrossSaleDate](
		[CSD_Id] [int] IDENTITY(1,1) NOT NULL,
		[CSD_COId] [int] NOT NULL,
		[CSD_CrossDate] [datetime] NOT NULL,
		[CSD_SvKey] [int] NOT NULL,
		[CSD_Code] [int] NOT NULL,
		[CSD_SubCode1] [int] NOT NULL,
		[CSD_SubCode2] [int] NOT NULL,
		[CSD_PKKey] [int] NOT NULL,
		[CSD_PRKey] [int] NOT NULL
	 CONSTRAINT [PK_CostOfferCrossSaleDate] PRIMARY KEY CLUSTERED 
	(
		[CSD_Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]	

	ALTER TABLE [dbo].[CostOfferCrossSaleDate]  WITH CHECK ADD  CONSTRAINT [FK_CostOfferCrossSaleDate_CostOffers] FOREIGN KEY([CSD_COId])
	REFERENCES [dbo].[CostOffers] ([CO_Id])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[CostOfferCrossSaleDate] CHECK CONSTRAINT [FK_CostOfferCrossSaleDate_CostOffers]

	ALTER TABLE [dbo].[CostOfferCrossSaleDate]  WITH CHECK ADD  CONSTRAINT [FK_CostOfferCrossSaleDate_Service] FOREIGN KEY([CSD_SvKey])
	REFERENCES [dbo].[Service] ([SV_KEY])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[CostOfferCrossSaleDate] CHECK CONSTRAINT [FK_CostOfferCrossSaleDate_Service]
end
go
grant select, insert, delete, update on [dbo].[CostOfferCrossSaleDate] to public
go

/*********************************************************************/
/* end CREATE_Table_CostOfferCrossSaleDate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin CREATE_Table_TP_ServicePriceNextDate.sql */
/*********************************************************************/
if not exists ( select * from sysobjects where id = object_id(N'[dbo].[TP_ServicePriceNextDate]') and objectproperty(id, N'IsUserTable') = 1 ) 
    CREATE TABLE [dbo].[TP_ServicePriceNextDate](
		[SPND_Id] [int] IDENTITY(1,1) NOT NULL,
		[SPND_SCPId] [bigint] NULL,
		[SPND_IsCommission] [bit] NULL,
		[SPND_Rate] [nvarchar](2) NULL,
		[SPND_SaleDate] [datetime] NULL,
		[SPND_Gross] [money] NULL,
		[SPND_Netto] [money] NULL,
		[SPND_DateLastChange] [datetime] NOT NULL,
		[SPND_DateLastCalculate] [datetime] NULL,
		[SPND_NeedApply] [smallint] NOT NULL		
	 CONSTRAINT [PK_TP_ServicePriceNextDate] PRIMARY KEY CLUSTERED 
	(
		[SPND_Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
go

if not exists( select 1 from dbo.sysobjects  where id = object_id(N'[dbo].[FK_TP_ServicePriceNextDate_TP_ServiceCalculateParametrs]')  and OBJECTPROPERTY(id, N'IsForeignKey') = 1) 
	ALTER TABLE [dbo].[TP_ServicePriceNextDate]  WITH CHECK ADD  CONSTRAINT [FK_TP_ServicePriceNextDate_TP_ServiceCalculateParametrs] FOREIGN KEY([SPND_SCPId])
	REFERENCES [dbo].[TP_ServiceCalculateParametrs] ([SCP_Id])
	ON DELETE CASCADE
GO

ALTER TABLE [dbo].[TP_ServicePriceNextDate] CHECK CONSTRAINT [FK_TP_ServicePriceNextDate_TP_ServiceCalculateParametrs]
GO

grant select, update, insert, delete on dbo.TP_ServicePriceNextDate to public
go

/*********************************************************************/
/* end CREATE_Table_TP_ServicePriceNextDate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplUpdatePriceTourDateValid.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwReplUpdatePriceTourDateValid')
	drop proc dbo.[mwReplUpdatePriceTourDateValid]
go

create proc [dbo].[mwReplUpdatePriceTourDateValid] @tokey int, @rqId int
as
begin
	-- <date>2012-09-20</date>
	-- <version>2009.2.16.1</version>

	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwSpoDataTable.'
	
	update mwSpoDataTable
	set sd_tourvalid  = TO_DateValid
	from TP_Tours where sd_tourkey = to_key and to_key = @tokey

	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwPriceDataTable.'
		
	update mwPriceDataTable
	set pt_tourvalid  = TO_DateValid
	from TP_Tours where pt_tourkey = to_key and to_key = @tokey
end
GO

grant exec on [dbo].[mwReplUpdatePriceTourDateValid] to public

GO
/*********************************************************************/
/* end sp_mwReplUpdatePriceTourDateValid.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplDisablePriceTour.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwReplDisablePriceTour')
	drop proc dbo.[mwReplDisablePriceTour]
go

create proc [dbo].[mwReplDisablePriceTour] @tourkey int, @rqId int
as
begin
	-- <date>2012-09-20</date>
	-- <version>2009.2.16.1</version>

	declare @mwSearchType int
	select @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
		where SS_ParmName = 'MWDivideByCountry'

	if @mwSearchType = 0
	begin
		if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwPriceDataTable.'
			
		update mwPriceDataTable with (rowlock)
		set pt_isenabled = 0
		where pt_tourkey = @tourkey
	end
	else
	begin
		declare @tableName varchar(100), @tokey int, @cnkey int, @ctkey int
		declare @sql varchar(8000)

		select 
			@tokey = to_key, 
			@cnkey = to_cnkey, 
			@ctkey = tl_ctdeparturekey
		from 
			tp_tours with(nolock)
			inner join tbl_TurList with(nolock) on to_trkey = tl_key
		where
			to_key = @tourkey

		set @tableName = dbo.mwGetPriceTableName(@cnkey, @ctkey)
		
		if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwPriceDataTable.'
			
		set @sql = 'update ' + @tableName + ' with(rowlock) set pt_isenabled = 0 where pt_tourkey = ' + ltrim(str(@tokey))
		exec (@sql)
	end

	if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwSpoDataTable.'
			
	update mwSpoDataTable with(rowlock)
	set sd_isenabled = 0	
	where sd_tourkey = @tourkey
end
GO

grant exec on [dbo].[mwReplDisablePriceTour] to public

GO
/*********************************************************************/
/* end sp_mwReplDisablePriceTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplProcessQueueDivide.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReplProcessQueueDivide]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mwReplProcessQueueDivide]
GO
create procedure [dbo].[mwReplProcessQueueDivide]
as
begin
	--<VERSION>2009.01.01</VERSION>
	--<DATE>2012-09-17</DATE>
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
go
/*********************************************************************/
/* end sp_mwReplProcessQueueDivide.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.09.20)_ADD_COLUMN_PrtDogs.sql */
/*********************************************************************/
if not exists (select * from dbo.syscolumns where name = 'PD_OriginalDate' and id = object_id(N'[dbo].[PrtDogs]'))
	alter table PrtDogs Add PD_OriginalDate  datetime null
GO



/*********************************************************************/
/* end (2012.09.20)_ADD_COLUMN_PrtDogs.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.08.24)_Create_Table_TP_ServiceTours.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceTours]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[TP_ServiceTours](
		[ST_Id] [bigint] IDENTITY(1,1) NOT NULL,
		[ST_SCId] [int] NOT NULL,
		[ST_TOKey] [int] NOT NULL,
		[ST_TRKey] [int] NOT NULL,
		[ST_SVKey] [int] NOT NULL,
	 CONSTRAINT [PK_TP_ServiceTours] PRIMARY KEY CLUSTERED 
	(
		[ST_Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
end
GO
grant select, insert, update, delete on [dbo].[TP_ServiceTours] to public
go
/*********************************************************************/
/* end (2012.08.24)_Create_Table_TP_ServiceTours.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.10.21)_delete_SystemSettings.sql */
/*********************************************************************/
delete from SystemSettings
where SS_ParmName = 'SYSMEssagesRules'
GO
/*********************************************************************/
/* end (2012.10.21)_delete_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetServiceStatusOK.sql */
/*********************************************************************/
--2009.2.9.3
--2012-11-28
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
			set @dlcontrol = @tempDlControl
		end
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
/* begin sp_DogListToQuotas.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogListToQuotas]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogListToQuotas]
GO
CREATE PROCEDURE [dbo].[DogListToQuotas]
(
	--<VERSION>2009.2.32</VERSION>
	--<DATA>12.10.2012</DATA>
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
) 
AS

--insert into Debug (db_n1, db_n2, db_n3) values (@DLKey, @SetQuotaType, 999)
declare @SVKey int, @Code int, @SubCode1 int, @PRKey int, @AgentKey int, @DgKey int,
		@TourDuration int, @FilialKey int, @CityDepartment int,
		@ServiceDateBeg datetime, @ServiceDateEnd datetime, @Pax smallint, @IsWait smallint,@SVQUOTED smallint,
		@SdStateOld int, @SdStateNew int, @nHIID int, @dgCode nvarchar(10), @dlName nvarchar(max)
		
declare @sOldValue nvarchar(max), @sNewValue nvarchar(max)

-- если включена настройка то отрабатывает новый метод посадки и рассадки в квоту
if exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota' and SS_ParmValue = 1)
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
DECLARE @dlControl int
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
--<VERSION>2008.1.01.13</VERSION>
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
	-- если выключена настройка то запускаем всю эту дребедень, иначе только DogListToQuotas
	if exists (select top 1 1 from SystemSettings where SS_ParmName = 'NewSetToQuota' and SS_ParmValue = 0)
	begin
		print 'Старая рассадка'
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
		exec dbo.DogListToQuotas @DLKey --в этой хранимке будет выполнена попытка постановки услуги на квоту
		END
	end
	else
	begin
		print 'Новая рассадка'
		print 'exec dbo.DogListToQuotas ' + convert(nvarchar(max), @DLKey)

		-- если была произведена вставка, либо были обновлены важные поля и услугу необходимо пересадить, вызываем пересадку
		IF @Mod='INS' or (@Mod='UPD' and @SetToNewQuota=1)
		begin
			exec dbo.DogListToQuotas @DLKey
		end
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
/* begin sp_QuotaPartsAfterDelete.sql */
/*********************************************************************/
--<VERSION>2009.2.1</VERSION>
--<DATE>2012-10-26</DATE>

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotaPartsAfterDelete]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[QuotaPartsAfterDelete]
GO

Create PROCEDURE [dbo].[QuotaPartsAfterDelete] 

AS
BEGIN
	--version 9.2.9.1
	--data 2011-10-26
	--Процедура освобождает удаленные квоты
	--QD_IsDeleted хранит статус, в который требуется поставить услуги, на данный момент находящиеся на данной квоте
	--QD_IsDeleted=3 - подтвердить (ВАЖНО подтверждается только те даты которые удаляются)
	--QD_IsDeleted=4 - Request (ВАЖНО на Request только те даты которые удаляются)
	--QD_IsDeleted=1 - попытка поставить на квоту (ВАЖНО на квоту пробуем поставить место, на всем протяжении услуги, то есть - если это проживание и только один день удаляем из квоты, то место снимается с квоты целиком и пытается сесть снова)

	-- ставим вне квоты
	update ServiceByDate set SD_State = 3, SD_QPID = null where exists (select 1 from QuotaParts where QP_ID = SD_QPID and QP_IsDeleted = 3)

	-- пробуем сажать услуги, квоты которых помечены как alot/commit
	DECLARE @SD_DLKey int
	DECLARE cur_QuotaPartsDelete CURSOR FORWARD_ONLY FOR
		select distinct SD_DLKey
		from ServiceByDate
		where SD_State in (1, 2)
		and exists (select 1 from QuotaParts where QP_ID = SD_QPID and QP_IsDeleted = 1)

	-- вызываем пересадку
	OPEN cur_QuotaPartsDelete
	FETCH NEXT FROM cur_QuotaPartsDelete INTO @SD_DLKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC dbo.DogListToQuotas @SD_DLKey
		FETCH NEXT FROM cur_QuotaPartsDelete INTO @SD_DLKey
	END
	CLOSE cur_QuotaPartsDelete
	DEALLOCATE cur_QuotaPartsDelete

	declare @DLKeysForUpdare table
	(
		DL_Key int
	)

	-- ключи услуг, которые должны быть посажены на Request
	insert into @DLKeysForUpdare(DL_Key) select SD_DLKey from ServiceByDate,QuotaParts where QP_ID = SD_QPID and QP_IsDeleted = 4
	
	-- ставим на Request
	update ServiceByDate set SD_State = 4, SD_QPID = null where exists (select 1 from QuotaParts where QP_ID = SD_QPID and QP_IsDeleted = 4)
	
	DECLARE cur_QuotaPartsDelete2 CURSOR FORWARD_ONLY FOR
		select distinct DL_Key
		from @DLKeysForUpdare

	OPEN cur_QuotaPartsDelete2
	FETCH NEXT FROM cur_QuotaPartsDelete2 INTO @SD_DLKey
	WHILE @@FETCH_STATUS = 0
	BEGIN
		declare @dlControlNull int
		EXEC SetServiceStatusOk @SD_DLKey,@dlControlNull output
		FETCH NEXT FROM cur_QuotaPartsDelete2 INTO @SD_DLKey
	END
	CLOSE cur_QuotaPartsDelete2
	DEALLOCATE cur_QuotaPartsDelete2

	-- запомним ключи, которые необходимо удалить
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
	delete from StopSales where SS_QDID in (SELECT DQDID FROM @DelQPID)
	-- только те QuotaDetails которые есть в нашем списке и на них нету записей в QuotaParts
	DELETE FROM QuotaDetails WHERE QD_ID in (SELECT DQDID FROM @DelQPID) and not exists (select 1 from QuotaParts where QP_QDID = QD_ID)
	DELETE FROM StopSales WHERE SS_QDID in (SELECT DQDID FROM @DelQPID) and not exists (select 1 from QuotaDetails where QD_ID = SS_QDID)
END

go 

grant exec on QuotaPartsAfterDelete to public 

go

/*********************************************************************/
/* end sp_QuotaPartsAfterDelete.sql */
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


/*********************************************************************/
/* end (2012.02.13)Insert_Action.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.08.12)_ADD_COLUMNS_Quotas_QuotaDetails.sql */
/*********************************************************************/
if not exists (select 1 from dbo.syscolumns where name = 'QT_IsByCheckIn' and id = object_id(N'[dbo].[Quotas]'))
	alter table dbo.Quotas add QT_IsByCheckIn bit not null default(0)
go
if not exists (select 1 from dbo.syscolumns where name = 'QD_LongMin' and id = object_id(N'[dbo].[QuotaDetails]'))
	alter table dbo.QuotaDetails add QD_LongMin smallint
go
if not exists (select 1 from dbo.syscolumns where name = 'QD_LongMax' and id = object_id(N'[dbo].[QuotaDetails]'))
	alter table dbo.QuotaDetails add QD_LongMax smallint
go
/*********************************************************************/
/* end (2012.08.12)_ADD_COLUMNS_Quotas_QuotaDetails.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.08.23)ReCreate_TP_QueueAddCosts.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_TP_QueueAddCosts_AddCosts]') AND parent_object_id = OBJECT_ID(N'[dbo].[TP_QueueAddCosts]'))
ALTER TABLE [dbo].[TP_QueueAddCosts] DROP CONSTRAINT [FK_TP_QueueAddCosts_AddCosts]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TP_QueueAddCosts]') AND type in (N'U'))
DROP TABLE [dbo].[TP_QueueAddCosts]
GO
CREATE TABLE [dbo].[TP_QueueAddCosts](
	[QAC_Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QAC_ADCId] [int] NOT NULL,
 CONSTRAINT [PK_TP_QueueAddCosts] PRIMARY KEY CLUSTERED 
(
	[QAC_Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[TP_QueueAddCosts]  WITH CHECK ADD  CONSTRAINT [FK_TP_QueueAddCosts_AddCosts] FOREIGN KEY([QAC_ADCId])
REFERENCES [dbo].[AddCosts] ([ADC_Id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[TP_QueueAddCosts] CHECK CONSTRAINT [FK_TP_QueueAddCosts_AddCosts]
GO

grant select, insert, update, delete on [dbo].[TP_QueueAddCosts] to public
go

/*********************************************************************/
/* end (2012.08.23)ReCreate_TP_QueueAddCosts.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.08.28)_ADD_COLUMN_PrtWarns.sql */
/*********************************************************************/
if not exists (select 1 from dbo.syscolumns where name = 'PW_IsAddToHistory' and id = object_id(N'[dbo].[PrtWarns]'))
	alter table dbo.PrtWarns add PW_IsAddToHistory bit not null default(0)
go

/*********************************************************************/
/* end (2012.08.28)_ADD_COLUMN_PrtWarns.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.08.29)_Create_Table_QuotaСheckLogs.sql */
/*********************************************************************/
IF not EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotaCheckLogs]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[QuotaCheckLogs](
		[Id] [int] IDENTITY(1,1) NOT NULL,
		[Date] [datetime] NOT NULL,
		[Success] [bit] NOT NULL,
		[Message] [nvarchar](max) NULL,
	 CONSTRAINT [PK_QuotaCheckLogs] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
end

GO
grant select, insert, update, delete on [dbo].[QuotaCheckLogs] to public
go

/*********************************************************************/
/* end (2012.08.29)_Create_Table_QuotaСheckLogs.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.08.29)_Delete_Actions.sql */
/*********************************************************************/
--<VERSION>9.2.16</VERSION>
--<DATE>2012-08-29</DATE>	
-- скрипт для удаления Actions по ПДН
delete from Actions
where AC_Name like 'Персональные данные%'
GO
/*********************************************************************/
/* end (2012.08.29)_Delete_Actions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.08.29)_Delete_SystemSettings.sql */
/*********************************************************************/
--<VERSION>9.2.16</VERSION>
--<DATE>2012-08-29</DATE>	
-- скрипт для удаления настройки SYSEnableTPD из таблицы [SystemSettings], предназначенная для вкл./откл. ПДН
delete from SystemSettings
where SS_ParmName like 'SYSEnableTPD'
GO
/*********************************************************************/
/* end (2012.08.29)_Delete_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.09.05)_CreateTable_Tokens.sql */
/*********************************************************************/
--<VERSION>9.2</VERSION>
--<DATE>2012-09-05</DATE>
--Создание таблицы для хранения токенов после авторизации на веб-сервисе
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Tokens]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Tokens](
	[T_ID] [int] IDENTITY(1,1) NOT NULL,
	[T_Token] [nvarchar](500) NOT NULL,
	[T_ExpireDate] datetime NOT NULL
 CONSTRAINT [PK_Tokens] PRIMARY KEY CLUSTERED 
(
	[T_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[Tokens] TO PUBLIC
END
GO
/*********************************************************************/
/* end (2012.09.05)_CreateTable_Tokens.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.09.19)_Add_Column_TP_QueueAddCosts.sql */
/*********************************************************************/
--<VERSION>2009.2.16.1</VERSION>
--<DATE>2012-10-02</DATE>
if not exists (select 1 from dbo.syscolumns where name = 'QAC_CalculateDate' and id = object_id(N'[dbo].[TP_QueueAddCosts]'))
	alter table dbo.TP_QueueAddCosts add QAC_CalculateDate datetime null
go
if not exists (select 1 from dbo.syscolumns where name = 'QAC_TRKey' and id = object_id(N'[dbo].[TP_QueueAddCosts]'))
	alter table dbo.TP_QueueAddCosts add QAC_TRKey int not null
go
/*********************************************************************/
/* end (2012.09.19)_Add_Column_TP_QueueAddCosts.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.09.25)_Delete_UserSettings.sql.sql */
/*********************************************************************/
--<VERSION>9.2.1</VERSION>
--<DATE>2012-09-25</DATE>	
delete from UserSettings
where ST_ParmName like '%Quota%'
GO



/*********************************************************************/
/* end (2012.09.25)_Delete_UserSettings.sql.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.10.01)_Create_Table_TP_TourParametrs.sql */
/*********************************************************************/
IF not EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TP_TourParametrs]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[TP_TourParametrs](
		[TP_Id] [int] IDENTITY(1,1) NOT NULL,
		[TP_TOKey] [int] NOT NULL,
		[TP_TourDays] [smallint] NOT NULL,
		[TP_DateCheckIn] [datetime] NOT NULL,
	 CONSTRAINT [PK_TP_TourParametrs] PRIMARY KEY CLUSTERED 
	(
		[TP_Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[TP_TourParametrs]  WITH CHECK ADD  CONSTRAINT [FK_TP_TourParametrs_TP_TourParametrs] FOREIGN KEY([TP_TOKey])
	REFERENCES [dbo].[TP_Tours] ([TO_Key])
	ON DELETE CASCADE
end

ALTER TABLE [dbo].[TP_TourParametrs] CHECK CONSTRAINT [FK_TP_TourParametrs_TP_TourParametrs]
GO

grant select, update, delete, insert on [dbo].[TP_TourParametrs] to public
go
/*********************************************************************/
/* end (2012.10.01)_Create_Table_TP_TourParametrs.sql */
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

--2. Добавить US_USKEY (пользователь-создатель) в таблицу dup_user
IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[dup_user]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1) and  
		NOT EXISTS (select * from syscolumns where name='US_USKEY' and id=object_id('dup_user'))
	ALTER table dup_user ADD  US_USKEY int null;
GO

--3. Создаем таблицу UserRole
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

--4. Создаем таблицу Role
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

--5. Создаем таблицу ActionRole
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

--6. Создаем констрейнт DUP_USER.US_USKEY - DUP_USER.US_KEY
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_DUP_USER_DUP_USER]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.DUP_USER ADD CONSTRAINT
	FK_DUP_USER_DUP_USER FOREIGN KEY
	(
	US_USKEY
	) REFERENCES dbo.DUP_USER
	(
	US_KEY
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

--7. Создаем констрейнт tbl_Partners.PR_KEY - Role.RL_PRKEY
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

--8. Создаем констрейнт DUP_USER.US_KEY - Role.RL_USKEY
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_Role_DUP_USER]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.Role ADD CONSTRAINT
	FK_Role_DUP_USER FOREIGN KEY
	(
	RL_USKEY
	) REFERENCES dbo.DUP_USER
	(
	US_KEY
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO

--9. Создаем констрейнт tbl_Partners.PK_RLID - Role.RL_ID
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
GO

--10. Создаем констрейнт ActionRole.AR_RLID - Role.RL_ID
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

--11. Создаем констрейнт UserRole.UR_RLID - Role.RL_ID
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

--12. Создаем констрейнт UserRole.UR_USKEY - DUP_USER.US_KEY
IF NOT  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[FK_UserRole_DUP_USER]') AND OBJECTPROPERTY(id, N'CnstIsColumn') = 1)
ALTER TABLE dbo.UserRole ADD CONSTRAINT
	FK_UserRole_DUP_USER FOREIGN KEY
	(
	UR_USKEY
	) REFERENCES dbo.DUP_USER
	(
	US_KEY
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
GO
/*********************************************************************/
/* end (2012.10.15)_CREATE_Role_UserRole_ActionRole.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.10.16)_Alter_Data_SystemSettings.sql */
/*********************************************************************/
if (not exists (select top 1 1 from SystemSettings where SS_ParmName = 'CheckQuotesWebService'))
begin
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values ('CheckQuotesWebService', '')
end
go
/*********************************************************************/
/* end (2012.10.16)_Alter_Data_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.11.20)_CreateTable_AddCostsNewYearDinner.sql */
/*********************************************************************/
IF not EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AddCostsNewYearDinner]') AND type in (N'U'))
begin
	--<VERSION>2009.2.16.1</VERSION>
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
/* end (2012.11.20)_CreateTable_AddCostsNewYearDinner.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.11.27)_Delete_Actions.sql */
/*********************************************************************/
--<VERSION>9.2.16</VERSION>
--<DATE>2012-11-27</DATE>	
-- скрипт для удаления Actions на разрешение числа мест в квоте на количество мест меньшее, чем на квоте сидит туристов
delete from Actions
where ac_key = 143
GO
/*********************************************************************/
/* end (2012.11.27)_Delete_Actions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.11.27)_delete_ChangeQuotaPlaces.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ChangeQuotaPlaces]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ChangeQuotaPlaces]
GO
/*********************************************************************/
/* end (2012.11.27)_delete_ChangeQuotaPlaces.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120811)_Add_Constraint_FK_Dup_User_tbl_Partners.sql */
/*********************************************************************/
-- Добавление FK связывающего представителя и партнера
--<DATE>2012-08-14</DATE>
--<VERSION>2009.2.15.1</VERSION>
if not exists (select top 1 1 from sys.foreign_keys where object_id = OBJECT_ID(N'[dbo].[FK_Dup_User_tbl_Partners]') and parent_object_id = OBJECT_ID(N'[dbo].[Dup_User]'))
begin
	update [dbo].[Dup_User] set [US_PRKey] = null where not exists (select top 1 1 from [tbl_Partners] where [PR_Key] = [US_PRKey])
	alter table [dbo].[Dup_User] with check add constraint [FK_Dup_User_tbl_Partners] foreign key([US_PRKey])
	references [dbo].[tbl_Partners] ([PR_Key])
end
go
/*********************************************************************/
/* end (20120811)_Add_Constraint_FK_Dup_User_tbl_Partners.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120811)_Add_Constraint_FK_tbl_Partners_CityDictionary.sql */
/*********************************************************************/
-- Добавление FK связывающего партнеров и города
--<DATE>2012-08-14</DATE>
--<VERSION>2009.2.15.2</VERSION>
if not exists (select top 1 1 from sys.foreign_keys where object_id = OBJECT_ID(N'[dbo].[FK_tbl_Partners_CityDictionary]') and parent_object_id = OBJECT_ID(N'[dbo].[tbl_Partners]'))
begin
	update [dbo].[tbl_partners] set [PR_CTKey] = null where not exists (select top 1 1 from [CityDictionary] where [CT_KEY] = [PR_CTKey])
	alter table [dbo].[tbl_partners] with check add constraint [FK_tbl_Partners_CityDictionary] foreign key([PR_CTKey])
	references [dbo].[CityDictionary] ([CT_KEY])
end
go
/*********************************************************************/
/* end (20120811)_Add_Constraint_FK_tbl_Partners_CityDictionary.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120817)_Add_Constraint_FK_tbl_Dogovor_tbl_Partner.sql */
/*********************************************************************/
-- Добавление FK связывающего договор с партнером, оформившим договор
--<DATE>2012-08-17</DATE>
--<VERSION>2009.2.15.1</VERSION>
if not exists (select top 1 1 from sys.foreign_keys where object_id = OBJECT_ID(N'[dbo].[FK_tbl_Dogovor_tbl_Partner]') and parent_object_id = OBJECT_ID(N'[dbo].[tbl_Dogovor]'))
begin
	update [dbo].[tbl_Dogovor] set [DG_PartnerKey] = null where [DG_PartnerKey] is not null and not exists (select top 1 1 from [tbl_Partners] where [PR_Key] = [DG_PartnerKey])
	alter table [dbo].[tbl_Dogovor] with check add constraint [FK_tbl_Dogovor_tbl_Partner] foreign key([DG_PartnerKey])
	references [dbo].[tbl_Partners] ([PR_Key])
end
go
/*********************************************************************/
/* end (20120817)_Add_Constraint_FK_tbl_Dogovor_tbl_Partner.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120817)_Alter_Constraint_FK_tbl_Partners_CityDictionary.sql */
/*********************************************************************/
-- Изменение FK связывающего партнеров и города
-- Т.к. в первой версии скрипта не было обновление таблицы tbl_Partners (обNULLуния ключей несуществующих городов), добавил этот скрипт чтобы поправить ситуацию
--<DATE>2012-08-17</DATE>
--<VERSION>2009.2.15.1</VERSION>
if exists (select top 1 1 from sys.foreign_keys where object_id = OBJECT_ID(N'[dbo].[FK_tbl_Partners_CityDictionary]') and parent_object_id = OBJECT_ID(N'[dbo].[tbl_Partners]'))
begin
	update [dbo].[tbl_partners] set [PR_CTKey] = null where PR_CTKey is not null and not exists (select top 1 1 from [CityDictionary] where [CT_KEY] = [PR_CTKey])
	alter table [dbo].[tbl_partners] check constraint [FK_tbl_Partners_CityDictionary]
end
go
/*********************************************************************/
/* end (20120817)_Alter_Constraint_FK_tbl_Partners_CityDictionary.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120829)_Update_Descriptions.sql */
/*********************************************************************/
if exists(select 1 from Descriptions where DS_PKKey = 0 and DS_TableId = 43 and DS_DTKey = 128)
begin
	update Descriptions set DS_Value =N'<RegForm><RegFormItem ID="CompanyName" Text="Название агентства (торговая марка):" Required="true" Visible="true" Error="Название агенства должно быть указано." Length="50" /><RegFormItem ID="ChainName" Text="Название сети (если агентство входит в сеть):" Required="false" Visible="false" Error="" Length="50" /><RegFormItem ID="JuridicalName" Text="Полное юридическое название агентства (вместе с юр. статусом: ООО, ЗАО и т.п.):" Required="true" Visible="true" Error="Полное название агенства должно быть указано." Length="160" /><RegFormItem ID="PartnerGroup" Text="Группа партнеров" Required="false" Visible="false" Error="" Length="160" /><RegFormItem ID="CommissionGroup" Text="Группа комиссий"  Required="false" Visible="false" Error="" Length="160" /><RegFormItem ID="ActBased" Text="Договор"  Required="false" Visible="false" Error="" Length="160" /><RegFormItem ID="RepresentativeManagerName" Text="ФИО представителя компании:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="Login" Text="Логин для доступа к системе онлайн (присваевается самостоятельно):" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="Password" Text="Пароль для доступа к системе онлайн (присваевается самостоятельно):" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="ManagerName" Text="ФИО руководителя:" Required="true" Visible="true" Error="" Length="100" /><RegFormItem ID="ManagerPosition" Text="Должность руководителя:" Required="false" Visible="true" Error="" Length="50" /><RegFormItem ID="JuridicalAddress" Text="Юридический адрес:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="Country" Text="Страна:" Required="true" Visible="true" Error="" Length="20" /><RegFormItem ID="City" Text="Город:" Required="true" Visible="true" Error="Город и индекс должны быть указаны." Length="30" /><RegFormItem ID="Address" Text="Адрес местонахождения:" Required="true" Visible="true" Error="" Length="250" /><RegFormItem ID="Phone" Text="Телефон:" Required="true" Visible="true" Error="Телефон и код города должны быть указаны." Length="50" /><RegFormItem ID="Fax" Text="Факс:" Required="false" Visible="true" Error="" Length="20" /><RegFormItem ID="EMail" Text="E-mail:" Required="true" Visible="true" Error="Должен быть указан корректный e-mail." Length="50" /><RegFormItem ID="INN" Text="ИНН:" Required="true" Visible="true" Error="Должен быть указан корректный ИНН." Length="15" /><RegFormItem ID="KPP" Text="КПП:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="UnitarySystem" Text="Система налогообложения:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="SettlementAccount" Text="р/с:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="CorrespondentAccount" Text="к/с:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="BankName" Text="Наименование Банка:" Required="true" Visible="true" Error="" Length="80" /><RegFormItem ID="BIK" Text="БИК:" Required="true" Visible="true" Error="" Length="20" /><RegFormItem ID="OGRN" Text="ОГРН:" Required="true" Visible="false" Error="" Length="50" /><RegFormItem ID="OKATO" Text="ОКАТО:" Required="false" Visible="false" Error="" Length="50" /><RegFormItem ID="OKPO" Text="ОКПО:" Required="false" Visible="false" Error="" Length="20" /><RegFormItem ID="Comment" Text="Комментарий" Required="false" Visible="false" Error="" Length="100" /></RegForm>'  where DS_PKKey = 0 and DS_TableId = 43 and DS_DTKey = 128
end

go

/*********************************************************************/
/* end (20120829)_Update_Descriptions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120927)_Update_Keys.sql */
/*********************************************************************/
declare @dskey int
select @dskey = ((select max(ds_key) from descriptions)+1)

update dbo.Keys
set ID = @dskey
where key_table = 'DESCRIPTIONS'

GO
/*********************************************************************/
/* end (20120927)_Update_Keys.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20121001)_AlterTable_Keys.sql */
/*********************************************************************/
--<VERSION>2009.2.16.1</VERSION>
--<DATE>2012-10-02</DATE>
if exists (select top 1 1 from sys.indexes where object_id = object_id(N'[dbo].[Keys]') AND name = N'Idx1')
	drop index [Idx1] on [dbo].[Keys] with ( online = off )
go

if exists (select top 1 1 from sys.columns where object_id = object_id('Keys') and name = 'Key_Table' and is_nullable = 1)
	alter table Keys alter column Key_Table varchar(40) not null
go

if exists (select top 1 1 from information_schema.referential_constraints where constraint_name ='PK_Keys')		
	alter table Keys add constraint [PK_Keys] primary key clustered
	(
		[Key_Table] asc
	)with (pad_index  = off, statistics_norecompute  = off, Ignore_dup_key = off, allow_row_locks  = on, allow_page_locks  = on) on [primary]
go
/*********************************************************************/
/* end (20121001)_AlterTable_Keys.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20121003)_AlterTable_ProTourQuotes.sql */
/*********************************************************************/
--<DATE>2012-10-03</DATE>
--<VERSION>2009.2.16.1</VERSION>
if exists (select top 1 1 from sys.columns where object_id = object_id('ProTourQuotes') and name = 'PTQ_CommitmentFree' and is_nullable = 0)
	alter table ProTourQuotes alter column PTQ_CommitmentFree int null
go

if exists (select top 1 1 from sys.columns where object_id = object_id('PTQ_CommitmentSold') and name = 'PTQ_CommitmentFree' and is_nullable = 0)
	alter table ProTourQuotes alter column PTQ_CommitmentSold int null
go

if exists (select top 1 1 from sys.columns where object_id = object_id('PTQ_AllotmentFree') and name = 'PTQ_CommitmentFree' and is_nullable = 0)
	alter table ProTourQuotes alter column PTQ_AllotmentFree int null
go

if exists (select top 1 1 from sys.columns where object_id = object_id('PTQ_AllotmentSold') and name = 'PTQ_CommitmentFree' and is_nullable = 0)
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
/* begin (20121003)_CreateTable_ProTourEntries.sql */
/*********************************************************************/
-- 03.10.2012 gorshkov диапазон квот полученный от сервиса ProTour-а
--<DATE>2012-10-03</DATE>
--<VERSION>2009.2.16.1</VERSION>
if not exists (select * from sys.objects where object_id = object_id(N'[dbo].[ProTourEntries]') and type in (N'U'))
	create table [dbo].[ProTourEntries](
		[PTE_Id] [int] identity(1,1) not null,
		[PTE_ServiceHost] varchar(256) not null,
		[PTE_EntryId] [int] not null,
		[PTE_RecordDate] [datetime] not null,
		[PTE_UpdateDate] [datetime] null,
		[PTE_OperatorCode] varchar(64) not null,
		[PTE_HotelKey] [int] not null,
		[PTE_RoomCategoryKey] [int] not null,
		[PTE_StartDate] [datetime] not null,
		[PTE_EndDate] [datetime] not null,
		[PTE_Type] varchar(10) not null,
		[PTE_Sign] varchar(1) null,
		[PTE_CommitmentRoomCount] [int] not null,
		[PTE_AllotmentRoomCount] [int] not null,
		[PTE_Release] [int] not null
	 constraint [PK_ProTourEntries] primary key clustered
	(
		[PTE_Id] asc
	)with (pad_index  = off, statistics_norecompute  = off, ignore_dup_key = off, allow_row_locks  = on, allow_page_locks  = on) on [primary]
	) on [primary]
go

if not exists (select * from sys.foreign_keys where object_id = object_id(N'[dbo].[FK_ProTourEntries_HotelDictionary]') and parent_object_id = object_id(N'[dbo].[ProTourEntries]'))
	alter table [dbo].[ProTourEntries] with nocheck add constraint [FK_ProTourEntries_HotelDictionary] foreign key([PTE_HotelKey])
	references [dbo].[HotelDictionary] ([HD_Key])
	on delete cascade
	not for replication
go

grant select, insert, update, delete on [dbo].[ProTourEntries] to public
go
/*********************************************************************/
/* end (20121003)_CreateTable_ProTourEntries.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20120704_AlterTablesMWPriceDataTables.sql */
/*********************************************************************/
declare @cnKey int, @ctKey int, @tempPriceTableName varchar (256), @sql nvarchar(max), @viewName varchar(256)

declare @mwSearchType int
select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
where SS_ParmName = 'MWDivideByCountry'

--10743 tkachuk имя таблиц для изменения теперь формируется динамически, с помощью курсора, на основе ключей города вылета и страны назначения

if (dbo.mwReplIsPublisher() = 0)
begin

	--есть сегментирование
	if (@mwSearchType = 1)
	begin

		declare tourCursor cursor local fast_forward for
			select distinct TO_CNKey, TL_CTDepartureKey from TP_Tours with(nolock) join Turlist with(nolock) on TL_KEY = TO_TRKey
			where TO_IsEnabled = 1 order by TO_CNKey, TL_CTDepartureKey

		open tourCursor
		fetch tourCursor into @cnKey, @ctKey
		while @@FETCH_STATUS = 0
		begin
			set @tempPriceTableName = dbo.mwGetPriceTableName(@cnKey, @ctKey)
			fetch tourCursor into @cnKey, @ctKey

			set @sql = '
			if not exists (select * from syscolumns where name=''pt_directFlightAttribute'' and id=object_id(''' + @tempPriceTableName + '''))
			begin
				alter table ' + @tempPriceTableName + ' add pt_directFlightAttribute int
			end
			'
			exec (@sql)

			set @sql = '
			if not exists (select * from syscolumns where name=''pt_backFlightAttribute'' and id=object_id(''' + @tempPriceTableName + '''))
			begin
				alter table ' + @tempPriceTableName + ' add pt_backFlightAttribute int
			end
			'
			exec (@sql)

			set @sql = 'grant update on ' + @tempPriceTableName + ' to public'
			exec(@sql)

			set @viewName = replace(@tempPriceTableName, 'mwPriceDataTable', 'mwPriceTable')

			set @sql = 'grant update on ' + @viewName + ' to public'
			exec(@sql)

			exec sp_refreshviewforall @viewName

			fetch tourCursor into @cnKey, @ctKey
		end
		close tourCursor
		deallocate tourCursor
	end
	else
	begin
		set @sql = '
		if not exists (select * from syscolumns where name=''pt_directFlightAttribute'' and id=object_id(''dbo.mwPriceDataTable''))
		begin
			alter table dbo.mwPriceDataTable add pt_directFlightAttribute int
		end
		'
		exec (@sql)

		set @sql = '
		if not exists (select * from syscolumns where name=''pt_backFlightAttribute'' and id=object_id(''dbo.mwPriceDataTable''))
		begin
			alter table dbo.mwPriceDataTable add pt_backFlightAttribute int
		end
		'
		exec (@sql)

		set @sql = 'grant update on dbo.mwPriceDataTable to public'
		exec(@sql)

		set @sql = 'grant update on dbo.mwPriceTable to public'
		exec(@sql)

		exec sp_refreshviewforall 'mwPriceTable'
	end

end

GO
/*********************************************************************/
/* end 20120704_AlterTablesMWPriceDataTables.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20120814_Create_VehicleIllegalPlan.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VehicleIllegalPlan]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[VehicleIllegalPlan](
	[VI_KEY] [int] IDENTITY(1,1) NOT NULL,
	[VI_HOSTKEY] [int] NULL,
	[VI_GROUP] [int] NULL,
	[VI_GROUPTYPE] [int] NULL,
	[VI_AREA] [int] NULL,
	[VI_COLUMN] [int] NULL,
	[VI_ROW] [int] NULL,
 CONSTRAINT [PK_VehicleIllegalPlan_1] PRIMARY KEY CLUSTERED 
(
	[VI_KEY] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
end
GO

grant select, update, insert, delete on dbo.VehicleIllegalPlan to public
go

/*********************************************************************/
/* end 20120814_Create_VehicleIllegalPlan.sql */
/*********************************************************************/

/*********************************************************************/
/* begin CREATE_Table_ReCalculateAddCostResults.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculateAddCostResults]') AND type in (N'U'))
begin
	--<VERSION>2009.2.16.1</VERSION>
	--<DATE>2012-10-02</DATE>
	CREATE TABLE [dbo].[ReCalculateAddCostResults](
		[ACR_Id] [int] IDENTITY(1,1) NOT NULL,
		[ACR_TrKey] [int] NOT NULL,
		[ACR_SvKey] [int] NOT NULL,
		[ACR_ScpId] [bigint] NOT NULL,
		[ACR_AddCostIsCommission] [money] NOT NULL,
		[ACR_AddCostNoCommission] [money] NOT NULL,
		[ACR_CalculatingKey] [int] NOT NULL
	 CONSTRAINT [PK_ReCalculateAddCostResults] PRIMARY KEY CLUSTERED 
	(
		[ACR_Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
end
go

grant select, insert, delete, update on [dbo].[ReCalculateAddCostResults] to public
go
/*********************************************************************/
/* end CREATE_Table_ReCalculateAddCostResults.sql */
/*********************************************************************/

/*********************************************************************/
/* begin CREATE_XML_SCHEMA_ArrayOfDateTime.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.xml_schema_collections c, sys.schemas s WHERE c.schema_id = s.schema_id AND (quotename(s.name) + '.' + quotename(c.name)) = N'[dbo].[ArrayOfDateTime]')
begin
CREATE XML SCHEMA COLLECTION [dbo].[ArrayOfDateTime] AS 
N'<?xml version="1.0" encoding="utf-16"?>
<xs:schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" attributeFormDefault="unqualified" elementFormDefault="qualified">
  <xsd:element name="ArrayOfDateTime">
	<xsd:complexType>
	  <xsd:sequence>
		<xsd:element maxOccurs="unbounded" name="dateTime" type="xsd:dateTime" />
	  </xsd:sequence>
	</xsd:complexType>
  </xsd:element>
</xs:schema>'
end
GO

grant exec on xml schema collection::[dbo].[ArrayOfDateTime] to public
GO

/*********************************************************************/
/* end CREATE_XML_SCHEMA_ArrayOfDateTime.sql */
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
	--<VERSION>9.2.16.0</VERSION>
	--<DATE>2012-11-02</DATE>

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
									and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
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
					and (@partnerkey < 0 or isnull(ss_prkey, 0) in (isnull(@partnerkey, 0), 0))
		) as innerQuotas
		order by
			qd_date, qp_agentkey DESC, QD_Release desc, qd_type DESC, QT_PrKey DESC, qp_isnotcheckin, ql_duration DESC, qo_subcode1 DESC, qo_subcode2 DESC

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
								and quotasIn.qt_subcode1 = quotasOut.qt_subcode1
								and quotasIn.qt_subcode2 = quotasOut.qt_subcode2
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

				if(@qtStop > 0) -- stop sale
				begin
					close qCur
					deallocate qCur

					insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
						qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
					values(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
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
									qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
								values(0, 0, 0, 0, 0, 0, 0, 0, case when @qtStop > 0 then 0 else @noPlacesResult end, 0, 0, 0)
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
/* begin INDEX_ADD_on_TP_ServiceTours.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceTours]') AND name = N'x_ST_TRKey')
DROP INDEX [x_ST_TRKey] ON [dbo].[TP_ServiceTours] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_ST_TRKey] ON [dbo].[TP_ServiceTours] 
(
	[ST_TRKey] ASC
)
INCLUDE 
(	[ST_SCId],
	[ST_TOKey],
	[ST_SVKey],
	[ST_Id]
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_ServiceTours]') AND name = N'x_All_TP_ServiceTours')
DROP INDEX [x_All_TP_ServiceTours] ON [dbo].[TP_ServiceTours] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_All_TP_ServiceTours] ON [dbo].[TP_ServiceTours] 
(
	[ST_TRKey] ASC,
	[ST_TOKey] ASC,
	[ST_SVKey] ASC,
	[ST_SCId] ASC
)
INCLUDE 
(
	[ST_Id]
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


/*********************************************************************/
/* end INDEX_ADD_on_TP_ServiceTours.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_x_TP_PriceComponents_State_TP_PriceComponents.sql.sql */
/*********************************************************************/
IF NOT  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_PriceComponents]') AND name = N'X_TP_PriceComponents_PC_State')
CREATE NONCLUSTERED INDEX [X_TP_PriceComponents_PC_State] ON [dbo].[TP_PriceComponents] 
(		
	PC_State
)
include
(	
	PC_Id, PC_TPKey, PC_ToKey
)
 WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO



/*********************************************************************/
/* end INDEX_ADD_x_TP_PriceComponents_State_TP_PriceComponents.sql.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_x_TP_PriceComponents_TourDate_TP_PriceComponents.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_PriceComponents]') AND name = N'X_TP_PriceComponents_TourDate')
	drop INDEX [X_TP_PriceComponents_TourDate] ON [dbo].[TP_PriceComponents] 
go
IF NOT  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_PriceComponents]') AND name = N'X_TP_PriceComponents_TourDate')
CREATE NONCLUSTERED INDEX [X_TP_PriceComponents_TourDate] ON [dbo].[TP_PriceComponents] 
(		
	PC_TourDate,
	PC_Rate,
	PC_TOKey,
	PC_Days	
)
include
(	
	[PC_Id],
	[Gross_1],[SCPId_1],[SVKey_1],
	[Gross_2],[SCPId_2],[SVKey_2],
	[Gross_3],[SCPId_3],[SVKey_3],
	[Gross_4],[SCPId_4],[SVKey_4],
	[Gross_5],[SCPId_5],[SVKey_5],
	[Gross_6],[SCPId_6],[SVKey_6],
	[Gross_7],[SCPId_7],[SVKey_7],
	[Gross_8],[SCPId_8],[SVKey_8],
	[Gross_9],[SCPId_9],[SVKey_9],
	[Gross_10],[SCPId_10],[SVKey_10],
	[Gross_11],[SCPId_11],[SVKey_11],
	[Gross_12],[SCPId_12],[SVKey_12],
	[Gross_13],[SCPId_13],[SVKey_13],
	[Gross_14],[SCPId_14],[SVKey_14],
	[Gross_15],[SCPId_15],[SVKey_15]
)
 WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO



/*********************************************************************/
/* end INDEX_ADD_x_TP_PriceComponents_TourDate_TP_PriceComponents.sql */
/*********************************************************************/

/*********************************************************************/
/* begin INDEX_ADD_X_TP_ServicePriceNextDate_NeedApply_TP_ServicePriceNextDate.sql */
/*********************************************************************/
if not exists (select 1 from sysindexes where name='X_TP_ServicePriceNextDate_NeedApply' and id = object_id(N'TP_ServicePriceNextDate'))
	CREATE NONCLUSTERED INDEX [X_TP_ServicePriceNextDate_NeedApply] ON [dbo].[TP_ServicePriceNextDate] 
	(
		[SPND_NeedApply] ASC
	)
	INCLUDE ( 
	[SPND_SaleDate],
	[SPND_Id],
	[SPND_SCPId],
	[SPND_IsCommission],
	[SPND_Rate],
	[SPND_Gross],
	[SPND_DateLastChange],
	[SPND_DateLastCalculate]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/*********************************************************************/
/* end INDEX_ADD_X_TP_ServicePriceNextDate_NeedApply_TP_ServicePriceNextDate.sql */
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
					inner join dbo.tp_servicelists with (nolock) on (tl_tskey = ts_key and TS_TOKey = @nPriceTourKey and TL_TOKey = @nPriceTourKey and (TI_CalculatingKey = @nCalculatingKey or @isPriceListPluginRecalculation = 1))
				where tl_tikey = ti_key)
	where ti_tokey = @nPriceTourKey

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
/* begin sp_CalculatePriceListDynamic.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalculatePriceListDynamic]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CalculatePriceListDynamic]
GO

CREATE PROCEDURE [dbo].[CalculatePriceListDynamic]
(
	--<data>2012-05-21</data>
	--<version>2009.02.18</version>
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
--select @nIsEnabled = TO_IsEnabled from TP_Tours where TO_Key = @nPriceTourKey
--set @nIsEnabled = 0
---------------------------------------------
declare @tpPricesCount int
declare @isPriceListPluginRecalculation smallint
select @tpPricesCount = count(1) from tp_prices with(nolock) where tp_tokey = @nPriceTourKey

if (@nCalculatingKey is null)
begin
	select top 1 @nCalculatingKey = CP_Key from CalculatingPriceLists where CP_PriceTourKey = @nPriceTourKey and CP_Update = 0
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

	------ проверяем, а подходит ли текущий рейс, указанный в туре ----
	Update	TP_Flights Set 	TF_CodeNew = TF_CodeOld, TF_PRKeyNew = TF_PRKeyOld, TF_SubCode1New = TF_SubCode1
	Where	exists (SELECT 1 FROM AirSeason WHERE AS_CHKey = TF_CodeOld AND TF_Date BETWEEN AS_DateFrom AND AS_DateTo AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%')
			and exists (select 1 from Costs where CS_Code = TF_CodeOld and CS_SVKey = 1 and CS_SubCode1 = TF_Subcode1 and CS_PRKey = TF_PRKeyOld and CS_PKKey = TF_PKKey and TF_Date BETWEEN CS_Date AND  CS_DateEnd and (ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%') and (CS_Long is null or CS_LongMin is null or TF_Days between CS_LongMin and CS_Long))
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
			[xTP_Key] [int] PRIMARY KEY NOT NULL ,
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

		--смотрим сколько записей по текущему прайсу уже посчитано
		Set @NumCalculated = (SELECT COUNT(1) FROM tp_prices with(nolock) where tp_tokey = @nPriceTourKey)
		--считаем сколько записей надо посчитать
		set @NumPrices = (	(select count(1) from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) * 
							(select count(1) from tp_turdates with(nolock) where td_tokey = @nPriceTourKey and td_update = @nUpdate));

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
		
		print 'Инициализация расчета цен: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
		
		declare @tempTO_Rate nvarchar(3), @tempTO_TRKey int
		
		select @tempTO_Rate = TO_Rate, @tempTO_TRKey = TO_TRKey from tp_tours with(nolock) where TO_Key = @nPriceTourKey

		declare serviceCursor cursor local fast_forward for
			select ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, @tempTO_Rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_days, ts_ctkey, ts_attribute, (select TL_CTDepartureKey from tbl_TurList with(nolock) where @tempTO_TRKey = TL_KEY), SV_IsDuration
			from tp_services with(nolock), tp_lists with(nolock), tp_servicelists with(nolock), tp_turdates with(nolock), [Service]
			where @nPriceTourKey = ts_tokey and @nPriceTourKey = ti_tokey and @nPriceTourKey = tl_tokey and ts_key = tl_tskey and ti_key = tl_tikey and @nPriceTourKey = td_tokey
				and ti_update = @nUpdate and td_update = @nUpdate and (@nUseHolidayRule = 0 or (case cast(datepart(weekday, td_date) as int) when 7 then 0 else cast(datepart(weekday, td_date) as int) end + ti_days) >= 8)
				and ts_svkey = SV_KEY
			order by ti_firsthdkey, td_date, ti_key, case when ti_firsthdkey = ts_code and TS_SVKey = 3 then 0 else 1 end

		open serviceCursor
		
		SELECT @round = ST_RoundService FROM Setting
		--MEG00036108 увеличил значение
		set @nProgressSkipLimit = 100

		set @nProgressSkipCounter = 0
		
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
		declare @calcPricesCount int, @calcPriceListCount int, @calcTurDates int, @oldPriceKeyCurrent int
		
		declare @IsDuration smallint
		declare @tiCtKeyFrom int, @tiDays int
		declare @tsKey_1 int, @tsKey_2 int, @tsKey_3 int, @tsKey_4 int, @tsKey_5 int, @tsKey_6 int, @tsKey_7 int, @tsKey_8 int, @tsKey_9 int, @tsKey_10 int, @tsKey_11 int, @tsKey_12 int, @tsKey_13 int, @tsKey_14 int, @tsKey_15 int
		declare @tsSVKey_1 int, @tsSVKey_2 int, @tsSVKey_3 int, @tsSVKey_4 int, @tsSVKey_5 int, @tsSVKey_6 int, @tsSVKey_7 int, @tsSVKey_8 int, @tsSVKey_9 int, @tsSVKey_10 int, @tsSVKey_11 int, @tsSVKey_12 int, @tsSVKey_13 int, @tsSVKey_14 int, @tsSVKey_15 int
		declare @tsGross_1 money, @tsGross_2 money, @tsGross_3 money, @tsGross_4 money, @tsGross_5 money, @tsGross_6 money, @tsGross_7 money, @tsGross_8 money, @tsGross_9 money, @tsGross_10 money, @tsGross_11 money, @tsGross_12 money, @tsGross_13 money, @tsGross_14 money, @tsGross_15 money
		declare @tsAddIsCommission_1 money, @tsAddIsCommission_2 money, @tsAddIsCommission_3 money, @tsAddIsCommission_4 money, @tsAddIsCommission_5 money, @tsAddIsCommission_6 money, @tsAddIsCommission_7 money, @tsAddIsCommission_8 money, @tsAddIsCommission_9 money, @tsAddIsCommission_10 money, @tsAddIsCommission_11 money, @tsAddIsCommission_12 money, @tsAddIsCommission_13 money, @tsAddIsCommission_14 money, @tsAddIsCommission_15 money
		declare @tsAddNoCommission_1 money, @tsAddNoCommission_2 money, @tsAddNoCommission_3 money, @tsAddNoCommission_4 money, @tsAddNoCommission_5 money, @tsAddNoCommission_6 money, @tsAddNoCommission_7 money, @tsAddNoCommission_8 money, @tsAddNoCommission_9 money, @tsAddNoCommission_10 money, @tsAddNoCommission_11 money, @tsAddNoCommission_12 money, @tsAddNoCommission_13 money, @tsAddNoCommission_14 money, @tsAddNoCommission_15 money
		declare @tsMarginPercent_1 money, @tsMarginPercent_2 money, @tsMarginPercent_3 money, @tsMarginPercent_4 money, @tsMarginPercent_5 money, @tsMarginPercent_6 money, @tsMarginPercent_7 money, @tsMarginPercent_8 money, @tsMarginPercent_9 money, @tsMarginPercent_10 money, @tsMarginPercent_11 money, @tsMarginPercent_12 money, @tsMarginPercent_13 money, @tsMarginPercent_14 money, @tsMarginPercent_15 money
		declare @tsCommissionOnly_1 money, @tsCommissionOnly_2 money, @tsCommissionOnly_3 money, @tsCommissionOnly_4 money, @tsCommissionOnly_5 money, @tsCommissionOnly_6 money, @tsCommissionOnly_7 money, @tsCommissionOnly_8 money, @tsCommissionOnly_9 money, @tsCommissionOnly_10 money, @tsCommissionOnly_11 money, @tsCommissionOnly_12 money, @tsCommissionOnly_13 money, @tsCommissionOnly_14 money, @tsCommissionOnly_15 money
		declare @tsIsCommission_1 bit, @tsIsCommission_2 bit, @tsIsCommission_3 bit, @tsIsCommission_4 bit, @tsIsCommission_5 bit, @tsIsCommission_6 bit, @tsIsCommission_7 bit, @tsIsCommission_8 bit, @tsIsCommission_9 bit, @tsIsCommission_10 bit, @tsIsCommission_11 bit, @tsIsCommission_12 bit, @tsIsCommission_13 bit, @tsIsCommission_14 bit, @tsIsCommission_15 bit
		
		select @calcPriceListCount = COUNT(1) from TP_Lists with(nolock) where TI_TOKey = @nPriceTourKey and TI_UPDATE = @nUpdate
		select @calcTurDates = COUNT(1) from TP_TurDates with(nolock) where TD_TOKey = @nPriceTourKey and TD_UPDATE = @nUpdate
		select @calcPricesCount = @calcPriceListCount * @calcTurDates

		fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_DAYS, @TS_CTKEY, @TS_ATTRIBUTE, @tiCtKeyFrom, @IsDuration
		
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
					if exists(select 1 from #TP_Prices where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant)
					begin
						--select @nCalculatingKey
						update #TP_Prices set xtp_calculatingkey = @nCalculatingKey, xtp_key = @nTP_PriceKeyCurrent where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant and xtp_gross <> @price_brutto
						set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
						
					end
					else if (@isPriceListPluginRecalculation = 0)
					begin
						--select @nCalculatingKey
						insert into #TP_Prices (xtp_key, xtp_tokey, xtp_datebegin, xtp_dateend, xtp_tikey, xTP_CalculatingKey, xTP_Days, xTP_Rate, xTP_HotelKey, xTP_DepartureKey
						, xSCPId_1, xSCPId_2, xSCPId_3, xSCPId_4, xSCPId_5, xSCPId_6, xSCPId_7, xSCPId_8, xSCPId_9, xSCPId_10, xSCPId_11, xSCPId_12, xSCPId_13, xSCPId_14, xSCPId_15
						, xSvKey_1, xSvKey_2, xSvKey_3, xSvKey_4, xSvKey_5, xSvKey_6, xSvKey_7, xSvKey_8, xSvKey_9, xSvKey_10, xSvKey_11, xSvKey_12, xSvKey_13, xSvKey_14, xSvKey_15
						, xGross_1, xGross_2, xGross_3, xGross_4, xGross_5, xGross_6, xGross_7, xGross_8, xGross_9, xGross_10, xGross_11, xGross_12, xGross_13, xGross_14, xGross_15
						, xAddCostIsCommission_1, xAddCostIsCommission_2, xAddCostIsCommission_3, xAddCostIsCommission_4, xAddCostIsCommission_5, xAddCostIsCommission_6, xAddCostIsCommission_7, xAddCostIsCommission_8, xAddCostIsCommission_9, xAddCostIsCommission_10, xAddCostIsCommission_11, xAddCostIsCommission_12, xAddCostIsCommission_13, xAddCostIsCommission_14, xAddCostIsCommission_15
						, xAddCostNoCommission_1, xAddCostNoCommission_2, xAddCostNoCommission_3, xAddCostNoCommission_4, xAddCostNoCommission_5, xAddCostNoCommission_6, xAddCostNoCommission_7, xAddCostNoCommission_8, xAddCostNoCommission_9, xAddCostNoCommission_10, xAddCostNoCommission_11, xAddCostNoCommission_12, xAddCostNoCommission_13, xAddCostNoCommission_14, xAddCostNoCommission_15
						, xMarginPercent_1, xMarginPercent_2, xMarginPercent_3, xMarginPercent_4, xMarginPercent_5, xMarginPercent_6, xMarginPercent_7, xMarginPercent_8, xMarginPercent_9, xMarginPercent_10, xMarginPercent_11, xMarginPercent_12, xMarginPercent_13, xMarginPercent_14, xMarginPercent_15
						, xCommissionOnly_1, xCommissionOnly_2, xCommissionOnly_3, xCommissionOnly_4, xCommissionOnly_5, xCommissionOnly_6, xCommissionOnly_7, xCommissionOnly_8, xCommissionOnly_9, xCommissionOnly_10, xCommissionOnly_11, xCommissionOnly_12, xCommissionOnly_13, xCommissionOnly_14, xCommissionOnly_15
						, xIsCommission_1, xIsCommission_2, xIsCommission_3, xIsCommission_4, xIsCommission_5, xIsCommission_6, xIsCommission_7, xIsCommission_8, xIsCommission_9, xIsCommission_10, xIsCommission_11, xIsCommission_12, xIsCommission_13, xIsCommission_14, xIsCommission_15)
						values (@nTP_PriceKeyCurrent, @nPriceTourKey, @dtPrevDate, @dtPrevDate, @nPrevVariant, @nCalculatingKey, @tiDays, @sRate, @hdKey, @tiCtKeyFrom
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
						
						set @nTP_PriceKeyCurrent = @nTP_PriceKeyCurrent + 1
					end
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
										
				declare @margin float, @marginType int, @addCostValueIsCommission money, @addCostValueNoCommission money
				declare @scId int -- ключ найденой записи в таблице TP_ServiceComponents
				declare @scpId int -- ключ найденой записи в таблице TP_ServiceCalculateParametrs
				declare @spadId  int -- ключ найденой записи в тиблице TP_ServiePriceActualDate
				
				-- gorshkov поднял дату сюда т.к. она нужна при замене дефолтного перелета на подобранный
				set @servicedate = dateAdd(dd, @nDay-1, @turdate)
				
				-- gorshkov проверка на то что данную услугу вообще нужно расчитывать
				if @TS_ATTRIBUTE & @SERV_NOTCALCULATE = @SERV_NOTCALCULATE
				begin
					set @nNetto = 0
					set @nBrutto = 0
					set @nDiscount = 0
					set @nPDID = 0
					
				end
				else
				begin
					-- gorshkov здесь нужно проверить, что если это перелет, 
					-- то для него мы подменим параметры из TP_Services соответсвующие TF_TSKeyNew
					-- если перелет не дефолтный, т.е. TF_TSKeyNew != TF_TSKeyOld
					if (@nSvkey=1)
					begin	
						select
							@nCode = TF_CodeNew,
							@nPrKey = TF_PRKeyNew,
							@nSubCode1 = TF_SubCode1New
						from TP_Flights
						where TF_TOKey = @nPriceTourKey
						and TF_CalculatingKey = @nCalculatingKey
						and TF_CodeOld = @nCode
						and TF_PRKeyOld = @nPrKey
						and TF_SubCode1 = @nSubCode1
						and TF_SubCode2 = @nSubcode2
						and tf_days = @TI_DAYS
						and TF_Date = @servicedate
					end
					
					-- если есть ключ услуги то расчитываем, иначе проставляем null
					if (@nCode is not null)
					begin					
						set @tiDays = @TI_DAYS
						
						/*создадим структуру таблиц если ее нету*/
						exec ReCalculate_CreateServiceCalculateParametrs @TrKey, @nPriceTourKey, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nDay, @turdate, @nMen, @nDays, @nPacketkey, @tiDays, @scId output, @scpId output
											
						declare @gross money, @addCostIsCommission money, @addCostNoCommission money, @addCostFromAdult money, @addCostFromChild money, @marginPercent money, @CommissionOnly bit, @isCommission bit, @tourRate varchar(2)
						
						/*Производим расчет стоимости услуги*/
						exec ReCalculateCosts_CalculatePriceList @scpId, @nBrutto output, @isCommission output, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @servicedate, @nDays, @sRate, @nMen, 0, @nMargin, @nMarginType, null, @nNetto, @nDiscount, @sDetailed, @sBadRate, @dtBadDate, @sDetailed, @nSPId, @TrKey, @turdate, @TI_DAYS, @IsDuration
						
						-- проверям считать ли null цены = 0					
						if @nNullCostAsZero = 1 and @nBrutto is null and @nSvkey not in (1,3)
							set @nBrutto = 0
						if @nNullCostAsZero = 1 and @nBrutto is null and @nSvkey = 1 and @nNoFlight = 0
							set @nBrutto = 0
							
						set @gross = @nBrutto
						
						/*Производим расчет наценки*/
						-- промежуточная хранимка для работы с кэшем (TP_TourMarginActualDate)
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
			fetch next from serviceCursor into @hdKey, @nServiceKey, @variant, @turdate, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nPacketkey, @nDay, @nDays, @sRate, @nMen, @nTempGross, @tsCheckMargin, @tdCheckMargin, @TI_DAYS, @TS_CTKEY, @TS_ATTRIBUTE, @tiCtKeyFrom, @IsDuration
		END
		close serviceCursor
		deallocate serviceCursor
		
		print 'Расчет цен END: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()

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

		-- удаляем старые цены
		
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
			
		INSERT INTO TP_Prices with(rowlock) (tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey, TP_CalculatingKey) 
		select xtp_key, xtp_tokey, xtp_dateBegin, xtp_DateEnd, CEILING(xTP_Gross), xTP_TIKey, xTP_CalculatingKey 
		from #TP_Prices
		
		-- заносим детализацию по посчитанному туру	
		
		insert into TP_PriceComponents with(rowlock) (PC_TIKey, PC_TOKey, PC_TRKey, PC_TourDate, PC_TPKey, PC_Days, PC_Rate, PC_HotelKey, PC_DepartureKey
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
		from #TP_Prices join CalculatingPriceLists on xTP_CalculatingKey = CP_Key
				
		-----------------------------------------------------КОНЕЦ возвращаем обратно цены ------------------------------------------------------
		Set @nTotalProgress = 97
		update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey

		update tp_lists with(rowlock) set ti_update = 0 where ti_tokey = @nPriceTourKey
		update tp_turdates with(rowlock) set td_update = 0, td_checkmargin = 0 where td_tokey = @nPriceTourKey
		Set @nTotalProgress = 99
		update tp_tours with(rowlock) set to_progress = @nTotalProgress, to_update = 0, to_updatetime = GetDate(),
							TO_CalculateDateEnd = GetDate(), TO_PriceCount = (Select Count(*) 
			From TP_Prices with(nolock) Where TP_ToKey = to_key) where to_key = @nPriceTourKey
		update tp_services with(rowlock) set ts_checkmargin = 0 where ts_tokey = @nPriceTourKey
		
		print 'Запись результатов: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
	END

	update CalculatingPriceLists with(rowlock) set CP_Status = 0, CP_CreateDate = GetDate(), CP_StartTime = null where CP_PriceTourKey = @nPriceTourKey

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
	
	print 'Выставление а инет: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()

	Return 0
END

go 

grant exec on CalculatePriceListDynamic to public

go
/*********************************************************************/
/* end sp_CalculatePriceListDynamic.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckQuotaExist.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckQuotaExist]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckQuotaExist]
GO

CREATE PROCEDURE [dbo].[CheckQuotaExist]
(
--<DATE>2012-10-31</VERSION>
--<VERSION>2009.2.16.1</VERSION>
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
if exists (select top 1 1 from systemsettings where SS_ParmName='SYSCheckQuotaRelease' and SS_ParmValue=1) OR exists (select top 1 1 from systemsettings where SS_ParmName='SYSAddQuotaPastPermit' and SS_ParmValue=1 and @DateBeg < @DATETEMP)
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
		Set @Quota_CheckState = 2						--Возвращаем "Внимание STOP"
		Set @Quota_CheckDate = @StopDate
		return
	END
	If @StopExist > 0 and not exists (select 1 from #Tbl where TMP_Count >0 and TMP_Date = @DateBeg)
	BEGIN
		Set @Quota_CheckState = 2						--Возвращаем "Внимание STOP"
		Set @Quota_CheckDate = @StopDate
		return
	END
	--select * from #Tbl
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
/* begin sp_FillMasterWebSearchFields.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FillMasterWebSearchFields]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[FillMasterWebSearchFields]
GO

CREATE procedure [dbo].[FillMasterWebSearchFields](@tokey int, @calcKey int = null, @forceEnable smallint = null, @overwritePrices bit = null)
-- if @forceEnable > 0 (by default) then make call mwEnablePriceTour @calcKey, 1 at the end of the procedure
as
begin
	-- <date>2012-09-18</date>
	-- <version>2009.2.16.1</version>
	set @forceEnable = isnull(@forceEnable, 1)
	
	declare @findByAdultChild int
	
	declare @counter int, @deleteCount int, @params nvarchar(500)
	
	set @findByAdultChild = isnull((select top 1 convert(int, SS_ParmValue) from SystemSettings where SS_ParmName = 'OnlineFindByAdultChild'), 0)

	if (@tokey is null)
	begin
		print 'Procedure does not support NULL param. You must specify @tokey parameter.'
		return
	end

	update dbo.TP_Tours set TO_Progress = 0 where TO_Key = @tokey

	if dbo.mwReplIsSubscriber() > 0
	begin
		--здесь происходит update и delete цен
		if isnull(@calcKey,0) != 0
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

grant execute on [dbo].[FillMasterWebSearchFields] to public
GO

/*********************************************************************/
/* end sp_FillMasterWebSearchFields.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetAddCostsForReCalculate.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetAddCostsForReCalculate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetAddCostsForReCalculate]
GO
CREATE PROCEDURE [dbo].[GetAddCostsForReCalculate]
-- хранимка возвращает данные для расчета доплат
AS
BEGIN
	--<VERSION>9.2.16.4</VERSION>
	--<DATE>2012-10-10</DATE>
	SET ARITHABORT ON;
	set nocount on;
	
	-- ключ тура, который мы будем расчитывать
	declare @tlKey int
	
	begin tran
		-- берем перый попавшийся тур
		select top 1 @tlKey = ADC_TLKey 
		from TP_QueueAddCosts join AddCosts with(nolock) on ADC_Id = QAC_ADCId 
		-- который еще не расчитывается
		where QAC_CalculateDate is null
		
		-- проставим дату расчета для записей которые мы возьмем, что бы этот тур не взял другой процесс
		update TP_QueueAddCosts
		set QAC_CalculateDate = getdate()
		from TP_QueueAddCosts join AddCosts with(nolock) on ADC_Id = QAC_ADCId 
		where QAC_CalculateDate is null
		and ADC_TLKey = @tlKey
	commit tran
	
	-- только проживание
	select QAC_Id as xQAC_Id, SCP_Id, ADC_TLKey as xTRKey, SC_SVKey, SC_Code, SC_SubCode1, SC_SubCode2, SCP_DateCheckIn, SCP_Days, SC_PRKey, SCP_Men, SCP_TourDays
	from TP_ServiceTours with(nolock)
	join TP_ServiceComponents with(nolock) on SC_ID = ST_SCId
	join TP_ServiceCalculateParametrs with(nolock) on SCP_SCID = SC_ID
	join AddCosts with(nolock) on ADC_TLKey = ST_TRKey
	join TP_QueueAddCosts on QAC_ADCId = ADC_Id and ST_SVKey = ADC_SVKey
	where 
	ADC_SVKey = 3
	and ST_TRKey = @tlKey
	and ADC_SVKey = SC_SVKey
	and (ADC_Code = 0 OR ADC_Code = SC_Code)
	and (ADC_SubCode1 = 0 OR SC_SubCode1 in (SELECT HR_Key FROM HotelRooms WHERE HR_RMKey=ADC_SubCode1))
	and (ADC_SubCode2 = 0 OR SC_SubCode1 in (SELECT HR_Key FROM HotelRooms WHERE HR_RCKey=ADC_SubCode2))
	and (ADC_PansionKey = 0 OR SC_SubCode2=ADC_PansionKey)
	and (ADC_PartnerKey = 0 OR ADC_PartnerKey=SC_PRKey)
	-- нам нужны только доплаты на будующие даты
	and SCP_DateCheckIn > getdate()
	and SCP_DateCheckIn between ADC_CheckInDateBeg and ADC_CheckInDateEnd
	and (SCP_TourDays between case when isnull(ADC_LongMin, 0) = 0 then -100500 else ADC_LongMin end
		and case when isnull(ADC_LongMax, 0) = 0 then 100500 else ADC_LongMax end)
	union
	-- остальные услуги
	select QAC_Id as xQAC_Id, SCP_Id, ADC_TLKey as xTRKey, SC_SVKey, SC_Code, SC_SubCode1, SC_SubCode2, SCP_DateCheckIn, SCP_Days, SC_PRKey, SCP_Men, SCP_TourDays
	from TP_ServiceTours with(nolock)
	join TP_ServiceComponents with(nolock) on SC_ID = ST_SCId
	join TP_ServiceCalculateParametrs with(nolock) on SCP_SCID = SC_ID
	join AddCosts with(nolock) on ADC_TLKey = ST_TRKey
	join TP_QueueAddCosts on QAC_ADCId = ADC_Id and ST_SVKey = ADC_SVKey
	where 
	ADC_SVKey != 3
	and ST_TRKey = @tlKey
	and ADC_SVKey = SC_SVKey
	and (ADC_Code = 0 OR ADC_Code = SC_Code)
	and (ADC_SubCode1 = 0 OR ADC_SubCode1 = SC_SubCode1)
	and (ADC_SubCode2 = 0 OR ADC_SubCode2 = SC_SubCode2)
	and (ADC_PartnerKey = 0 OR ADC_PartnerKey = SC_PRKey)
	-- нам нужны только доплаты на будующие даты
	and SCP_DateCheckIn > getdate()
	and SCP_DateCheckIn between ADC_CheckInDateBeg and ADC_CheckInDateEnd
	and (SCP_TourDays between case when isnull(ADC_LongMin, 0) = 0 then -100500 else ADC_LongMin end
		and case when isnull(ADC_LongMax, 0) = 0 then 100500 else ADC_LongMax end);
END
GO

grant exec on [dbo].[GetAddCostsForReCalculate] to public
go
/*********************************************************************/
/* end sp_GetAddCostsForReCalculate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetPricePage_VP.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[sp_GetPricePage_VP]') AND xtype in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_GetPricePage_VP]
GO

--<VERSION>ALL</VERSION>
--<DATE>2012-10-10</DATE>

-- Версия sp_GetPricePage для динамического ценообразования
CREATE PROCEDURE [dbo].[sp_GetPricePage_VP]
     @TourKey		int,			-- ключ тура (из таблицы TP_Tours)
     @calcKeyFrom	bigint,			-- начальный ключ calculatingKey
     @calcKeyTo		bigint			-- конечный ключ calculatingKey
AS

DECLARE @TP_PRICES AS TABLE
	(
		xTP_Key [int] NOT NULL PRIMARY KEY CLUSTERED, 
		xTP_TIKEY [int]
	)

INSERT INTO @TP_PRICES(xTP_Key,xTP_TIKEY) 
SELECT TP_KEY, TP_TIKEY  
FROM TP_PRICES WITH(NOLOCK)
WHERE  TP_TOKEY = @TourKey 
   and TP_CalculatingKey between @calcKeyFrom and @calcKeyTo
ORDER BY TP_KEY

--get output results
SELECT * 
FROM TP_PRICES WITH(NOLOCK) 
WHERE TP_Key IN (SELECT xTP_Key FROM @TP_PRICES)
ORDER BY TP_KEY 

-- Получаем все ServiceSet (варианты набора услуг).
SELECT DISTINCT xTP_TIKEY AS 'TP_TIKey' FROM @TP_PRICES 

--Console.WriteLine("||  Получаем все связи услуг");
SELECT * FROM TP_SERVICELISTS WITH(NOLOCK)
WHERE TL_TIKEY in (SELECT DISTINCT xTP_TIKEY FROM @TP_PRICES)
ORDER BY TL_TIKEY

-- Получаем список удаленных цен
SELECT * FROM TP_PricesDeleted WITH(NOLOCK)
WHERE TPD_TOKey = @TourKey
	and TPD_CalculatingKey between @calcKeyFrom and @calcKeyTo

GO
/*********************************************************************/
/* end sp_GetPricePage_VP.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetQuotaLoadListData_N.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetQuotaLoadListData_N]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetQuotaLoadListData_N]
GO

CREATE procedure [dbo].[GetQuotaLoadListData_N]
(
--<VERSION>2009.2.20</VERSION>
--<DATE>2012-10-30</DATE>
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
	order by ISNULL(QL_QTID,-1)-ISNULL(QL_QTID,-1) DESC /*Сначала квоты, потом неквоты*/,QL_PartnerName,QL_Type DESC,QL_Release,QL_Description,
		--сортируем по первому числу продолжительности если продолжительность с "-"
		case when CHARINDEX('-',QL_DURATIONS) = 0 
			then CONVERT(int,QL_DURATIONS)
			else CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX('-',QL_DURATIONS)))
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
/* begin sp_GetServiceAddCosts.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceAddCosts]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceAddCosts]
GO
CREATE PROCEDURE [dbo].[GetServiceAddCosts]
	(
		-- хранимка расчитывает доплаты по услуге
		--<date>2012-09-21</date>
		--<version>2009.2.16.1</version>
		/*mv 27.01.2012 : Внимание!
			в хранимке [dbo].[GetServiceAddCosts] 
			добавил параметр @days - новый обязательный параметр
			передача ключа партнера теперь идет сразу за SubCode2 (по аналогии с GetServiceCosts)
			переименовал параметр, возвращающий валюту @addCostRate
		  mv 27.01.2012_2 Добавил учет типа доплаты (за взрослого/ребенка и т.д.)
		  mv 27.01.2012_3 Добавил параметр "дата расчета" - @sellDate
		  AleXK 31.01.2012 Добавил 2 выходных параметра доплата за ребенка и доплата за взрослого
		  Gorshkov 10.02.2012 Добавил необязательный параметр - тип доплаты (@addCostType)
		  Gorshkov 10.02.2012_2 Теперь хранимка возвращает не сумму всех доплат, а только сумму последних доплат по каждому классу доплат
		*/
		@tourKey int,
		@svKey int,
		@code int,
		@SubCode1 int,
		@SubCode2 int,
		@partnerKey int,
		@tourDate datetime,
		@tourDays int,
		@serviceDays int,
		@men int,
		@sellDate datetime = null,
		@addCostClass int = null,
		@addCostValueIsCommission money output,
		@addCostValueNoCommission money output,
		-- тут доплата только за 1 взрослого
		@addCostFromAdult money output,
		-- тут доплата только за 1 ребенка
		@addCostFromChild money output,
		@addCostRate nvarchar(2) output
	)
AS
BEGIN
	set @addCostValueIsCommission = null
	set @addCostValueNoCommission = null
	set @addCostFromAdult = null
	set @addCostFromChild = null
	set	@addCostRate=null

	if @tourKey is null
	begin
		return 0
	end

	declare @internal_pansionKey int, @internal_subCode1 int, @internal_subCode2 int, @internal_subCode3 int,
			@internal_Main_Count int, @internal_ExB_Count int
	-- отдельно обработаем отель
	if (@svKey = 3)
	begin
		set @internal_pansionKey = @SubCode2
		
		select @internal_subCode1 = HR_RMKEY, @internal_subCode2 = HR_RCKEY, @internal_subCode3=HR_ACKEY
		from HotelRooms with(nolock)
		where HR_KEY = @SubCode1
		
		if @internal_subCode1 is null
		begin
			return 0
		end
		
		select @internal_Main_Count=IsNull(AC_NRealPlaces,0), @internal_ExB_Count=IsNull(AC_NMenExBed,0) 
		from Accmdmentype with(nolock)
		where AC_Key=@internal_subCode3
		
		-- если доплата за человека то берем количество людей из Accmdmentype
		set @men = @internal_Main_Count
		
		If @internal_Main_Count=0 and @internal_ExB_Count=0
		begin
			set @internal_Main_Count=1
		end
	end
	else
	begin
		set @internal_pansionKey = null
		set @internal_subCode1=@SubCode1 
		set @internal_subCode2=@SubCode2
	end
	
	-- если наща услуга без продолжительности то устанавливаем ей продолжительность равную продолжительности тура
	-- что бы доплата не обнылялась если она за сутки
	if (exists (select top 1 1 from [Service] with(nolock) where SV_KEY = @svKey and SV_IsDuration != 1))
	begin
		set @serviceDays = @tourDays
	end;
	
	with onlyNeededAddCosts as
	(
		select *
		from dbo.AddCosts with(nolock)
		where 
			ADC_TLKey = @tourKey
			and ADC_SVKey = @svKey
			and (ADC_Code = 0 or ADC_Code = @code)
			and (ADC_SubCode1=0 or ADC_SubCode1 = @internal_subCode1)
			and (ADC_SubCode2=0 or ADC_SubCode2 = @internal_subCode2)
			and (ADC_PartnerKey=0 or ADC_PartnerKey = @partnerKey)
			and ((@internal_pansionKey is not null and (ADC_PansionKey=0 or ADC_PansionKey = @internal_pansionKey)) or (@internal_pansionKey is null))	
			and @tourDate between ADC_CheckinDateBeg and ADC_CheckinDateEnd
			and ((isnull(ADC_LongMin, 0) = 0 and isnull(ADC_LongMax, 0) = 0) or (@tourDays between ADC_LongMin and ADC_LongMax))
			and ((@sellDate is not null and @sellDate >= ADC_CreateDate) or (@sellDate is null))
			and ((ADC_DisableDate is null) or (ADC_DisableDate is not null and @sellDate < ADC_DisableDate))
			and (@addCostClass is null or ADC_ACNId = @addCostClass)
	),
	theLatestInEachAddCostType as
	(
		select ADC_TypeId, ADC_Value, ADC_ValueChild, ADC_CreateDate, ADC_Rate, ADC_IsCommission, ADC_IsDay
		from onlyNeededAddCosts as onac
		where ADC_CreateDate = (select max(ac.ADC_CreateDate)
								from onlyNeededAddCosts as ac 
								where ac.ADC_ACNId = onac.ADC_ACNId)
	)
	
	select top 1
		@addCostValueIsCommission = sum(case when ADC_IsCommission = 1 then isnull(ADC_Value * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END) * (CASE ADC_TypeID WHEN 1 THEN 1 WHEN 3 THEN @internal_Main_Count ELSE @men END), 0) else 0 end) +
									sum(case when ADC_IsCommission = 1 then isnull(isnull(ADC_ValueChild, 0) * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END) * (CASE ADC_TypeID WHEN 1 THEN 0 when 2 then 0 WHEN 3 THEN @internal_ExB_Count END), 0) else 0 end),
		@addCostValueNoCommission = sum(case when ADC_IsCommission = 0 then isnull(ADC_Value * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END) * (CASE ADC_TypeID WHEN 1 THEN 1 WHEN 3 THEN @internal_Main_Count ELSE @men END), 0) else 0 end) +
									sum(case when ADC_IsCommission = 0 then isnull(isnull(ADC_ValueChild, 0) * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END) * (CASE ADC_TypeID WHEN 1 THEN 0 when 2 then 0 WHEN 3 THEN @internal_ExB_Count END), 0) else 0 end),
		@addCostFromAdult = sum(isnull(ADC_Value * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END), 0)),
		@addCostFromChild = sum(isnull((case when ADC_TypeID = 3 then isnull(ADC_ValueChild, 0) else ADC_Value end) * (CASE WHEN ADC_IsDay = 0 THEN @serviceDays ELSE 1 END), 0)),
		@addCostRate = ADC_Rate
	from theLatestInEachAddCostType
	group by ADC_Rate;
END

GO



grant exec on [dbo].[GetServiceAddCosts] to public
go
/*********************************************************************/
/* end sp_GetServiceAddCosts.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetServiceCost.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetServiceCost]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[GetServiceCost] 
GO

CREATE PROCEDURE [dbo].[GetServiceCost] 
	(
		--<date>2012-09-21</date>
		--<version>2009.2.16.1</version>
		--.18 gorshkov 12.03.2012 - для динамического ценообразования @CS_Profit заполняется нулями
		--.17 mv 06.02.2012 (MEG00040397) обработка продолжительности а/п
		--.15 mv 27.01.2012: Изменил обвязку рядом вокруг sp "GetServiceAddCosts"
		@svKey int, @code int, @code1 int, @code2 int, @prKey int, @packetKey int, @date datetime, @days int,
		@resRate varchar(2), @men int, @discountPercent decimal(14,2), @margin decimal(14,2) = 0, @marginType int =0,
		@sellDate dateTime, @netto decimal(14,2) output, @brutto decimal(14,2) output, @discount decimal(14,2) output, 
		@nettoDetail varchar(100) = '' output, @sBadRate varchar(2) = '' output, @dtBadDate DateTime = '' output,
		@sDetailed varchar(100) = '' output,  @nSPId int = null output, @useDiscountDays int = 0 output,
		@tourKey int = 0, @tourDate datetime, @tourDays int, @includeAddCost bit = 1
	)
as
SET DATEFIRST 1
DECLARE @tourlong int


If @svKey = 1 and @days > 0
BEGIN
	Set @tourlong = @days
	Set @days = 0
END
else
	set @tourlong = 0
If ((((@days <= 0) or (@days is null)) and (@svKey != 3 and @svKey != 8)) or (@svKey = 1 and isnull(@tourDays,0) > 0))
	Set @days = 1

/*
Новый код!!!!!!
НАЧАЛО
*/
declare @rakey int, @marginCalcValue decimal(14,2), @bSPUpdate bit, @sUseServicePrices varchar(1)
Select @rakey = RA_Key from dbo.Rates with(nolock) where RA_Code = @resRate

select @sUseServicePrices = SS_ParmValue from systemsettings with(nolock) where SS_ParmName = 'UseServicePrices'
if @sUseServicePrices = '1'
BEGIN
	SET @bSPUpdate = 0
	set @netto = null

	if @nSPId is not null 
		if exists (select SP_ID from dbo.ServicePrices with(nolock) where SP_ID = @nSPId)
			Set @bSPUpdate = 1

	if @bSPUpdate = 0
	BEGIN
		select	@nSPId = SP_ID, @netto = SP_Cost, @brutto = SP_Price, @discount = SP_PriceWithCommission
		from	dbo.ServicePrices with(nolock)
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

	SELECT @UseTypeDivisionMode = SS_ParmValue from dbo.SystemSettings with(nolock) where SS_ParmName = 'SYSUseCostTypeDivision'
	IF @UseTypeDivisionMode is not null and @UseTypeDivisionMode > 0
	BEGIN
		SELECT @UseTypeDivisionMode = COUNT(*) FROM tbl_costs with(nolock)
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
				from tbl_costs with(nolock)           
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
		else if ( exists( select top 1 1 from SystemSettings with(nolock) where SS_ParmName = 'NewReCalculatePrice' and SS_ParmValue = 1))
			declare costCursor cursor local fast_forward for
			select 
			CS_DATE, CS_DATEEND, CS_WEEK, CS_COSTNETTO, CAST(CS_COST as decimal(14,2)),
			CS_DISCOUNT, isnull(CS_TYPE,0), CS_RATE, CS_LONGMIN, CS_LONG,
			CS_BYDAY, 0 /* т.к. профиты конвертнулись в AddCosts */, CS_ID, CS_CheckInDateBEG, CS_CheckInDateEND, 
			ISNULL(CO_SaleDateBeg, '1900-01-01'), ISNULL(CO_SaleDateEnd, '2072-01-01')
				from tbl_costs with(nolock) join CostOffers with(nolock) on CS_COID = CO_Id
				join Seasons with(nolock) on CO_SeasonId = SN_Id
				WHERE	isnull(SN_IsActive, 0) = 1
						-- проверим активность костофера на нужную нам дату продажи
						and ((@sellDate is null and CO_State = 1) 
							or (CO_State in (1,2) and @sellDate is not null and @sellDate between isnull(CO_DateActive, '1900-01-01') and isnull(CO_DateClose, '2072-01-01')))
						-- проверим период продажи ценового блока
						and isnull(@sellDate, getdate()) between isnull(CO_SaleDateBeg, '1900-01-01') and isnull(CO_SaleDateEnd, '2072-01-01')
						and CS_SVKey = @svKey
						and CS_Code = @code
						and CS_SubCode1 = @code1
						and CS_SubCode2 = @code2
						and CS_PrKey = @prKey
						and CS_PkKey = @packetKey
						and @date between isnull(CS_CheckInDateBEG, '1900-01-01') and isnull(CS_CheckInDateEnd, '2072-01-01')
						-- либо дата начала услуги лежит между началом и концом цены,
						-- либо дата начала цены лежит между датой начала и концом услуги
						and (CS_DATE is null 
								or @date between CS_DATE and CS_DATEEND
								or CS_DATE between @date and dateadd(dd, isnull(@days,0), @date))
				ORDER BY
						-- если не задана дата продажи то смотрим по текущему полю последней даты активации
						-- иначе смотрим по истории активации
						isnull(CO_DateActive,'1900-01-01') desc,
						CS_CheckInDateBEG Desc, CS_CheckInDateEnd, CS_Date Desc, CS_DATEEND, CS_LONGMIN desc, 
						CS_LONG, CS_DateSellBeg Desc, CS_DateSellEnd, CS_BYDAY,	CS_WEEK ASC
		else
			declare costCursor cursor local fast_forward for
			select
			CS_DATE, CS_DATEEND, CS_WEEK, CS_COSTNETTO, CAST(CS_COST as decimal(14,2)),
			CS_DISCOUNT, isnull(CS_TYPE,0), CS_RATE, CS_LONGMIN, CS_LONG,
			CS_BYDAY, CS_PROFIT, CS_ID, CS_CheckInDateBEG, CS_CheckInDateEND,
			ISNULL(CS_DateSellBeg, '19000101'), ISNULL(CS_DateSellEnd, '99980101')
				from tbl_costs with(nolock)
				WHERE	CS_SVKey = @svKey and CS_Code = @code and CS_SubCode1 = @code1 and CS_SubCode2 = @code2 and
					    CS_PrKey = @prKey and CS_PkKey = @packetKey
						and ((@date between CS_CheckInDateBEG and CS_CheckInDateEnd) or (CS_CheckInDateBEG is null and CS_CheckInDateEnd is null))
					    and (CS_DateEnd >= @date and CS_DATE <= @date+isnull(@days,0) or (CS_DATE is null and CS_DateEnd is null))
			    ORDER BY
						CS_CheckInDateBEG Desc, CS_CheckInDateEnd, CS_Date Desc, CS_DATEEND, CS_LONGMIN desc,
						CS_LONG, CS_DateSellBeg Desc, CS_DateSellEnd, CS_BYDAY,	CS_WEEK ASC				

	Set @sellDate = ISNULL(@sellDate,GetDate())
	open costCursor
	set @nCostByDayExists = 0

	fetch next from costCursor 
		into	@CS_Date, @CS_DateEnd, @CS_Week, @CS_CostNetto, @CS_Cost, 
				@CS_Discount, @CS_Type, @CS_Rate, @CS_LongMin, @CS_Long, 
				@CS_ByDay, @CS_Profit, @CS_ID, @CS_CheckInDateBEG, @CS_CheckInDateEND, @CS_DateSellBeg, @CS_DateSellEnd

		If @days > 1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)
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
			If (@days > 1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)) and @IsFetchNormal = 1 	-- fetch нам подходит
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

					--mv 06.02.2012 (MEG00040397) Сделал проверку только НЕ для а/п
					If @svKey != 1
					begin
						if @CS_Long is not null and @CS_Long < @TMP_Number
							set @TMP_Number = @CS_Long
					end

					--mv 06.02.2012 (MEG00040397) отдельная проверка на продолжительность а/п
					if @CS_LongMin is null or @CS_LongMin <= @TMP_Number 
						or (@svKey=1 and (@CS_LongMin is null or @tourDays >= @CS_LongMin) and (@CS_Long is null or @tourDays <= @CS_Long))
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

		If (@days > 1 or (@CS_ByDay = 2 and (@svKey = 3 or @svKey = 8) and @days=1)) or @IsFetchNormal = 0
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

/*Посчитаем доплату*/
if (@includeAddCost = 1 and exists( select top 1 1 from SystemSettings where SS_ParmName = 'NewReCalculatePrice' and SS_ParmValue = 1))
begin
	declare @addCostValueIsCommission money, @addCostValueNoCommission money, @addCostFromAdult money, @addCostFromChild money, @addCostRate nvarchar(2)
	--print @tourKey
	exec GetServiceAddCosts @tourKey, @svKey, @code, @code1, @code2, @prKey, @tourDate, @tourDays, @days, @men, @sellDate, null, @addCostValueIsCommission output, @addCostValueNoCommission output, @addCostFromAdult output, @addCostFromChild output, @addCostRate output
	/*
	print @addCostValueIsCommission
	print @addCostValueNoCommission
	*/
	--конвертируем доплаты в валюту расчета из валюты тура (в которой они задавались)
	If @addCostValueIsCommission is not null
		exec ExchangeCost @addCostValueIsCommission output, @addCostRate, @resRate, @date
	If @addCostValueNoCommission is not null
		exec ExchangeCost @addCostValueNoCommission output, @addCostRate, @resRate, @date
	
	if @addCostValueIsCommission is not null
		set @sum_with_commission = isnull(@sum_with_commission,0) + isnull(@addCostValueIsCommission, 0)
	set @brutto = @brutto + isnull(@addCostValueIsCommission, 0) + isnull(@addCostValueNoCommission, 0)
end

If @marginType = 0 -- даем наценку, вне зависмости от наличия комиссии по услуге
	Set @brutto = ISNULL(@brutto,0) * (100 + @margin) / 100 
Else -- даем наценку, только при наличии комиссии
	Set @brutto = ISNULL(@brutto,0) - ISNULL(@sum_with_commission,0) + ISNULL(@sum_with_commission,0) * (100 + @margin) / 100 

--теперь @discount это именно сумма скидки
Set @discount = @sum_with_commission * ((100 + @margin) / 100) * @discountPercent / 100

exec RoundCost @brutto output, 1

Set @brutto = ISNULL(@brutto,0) - ISNULL(@discount,0)

if (not exists( select top 1 1 from SystemSettings with(nolock) where SS_ParmName = 'NewReCalculatePrice' and SS_ParmValue = 1))
begin
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
end
GO
GRANT EXECUTE ON [dbo].[GetServiceCost] TO PUBLIC 
GO
/*********************************************************************/
/* end sp_GetServiceCost.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetServiceList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceList]
GO

CREATE procedure [dbo].[GetServiceList] 
(
--<VERSION>2009.2.16.0</VERSION>
--<DATE>2012-10-24</DATE>
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

/*********************************************************************/
/* end sp_GetServiceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetSvCode1Name.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSvCode1Name]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP procedure [dbo].[GetSvCode1Name]
GO
CREATE PROCEDURE [dbo].[GetSvCode1Name]
(
--<VERSION>2009.2.16.1</VERSION>
--<DATA>05.10.2012</DATA>
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
/* begin sp_GetTourMargin.sql */
/*********************************************************************/
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
			and (TM_LONG <= @days - 1 or TM_LONG = 0)
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
/*********************************************************************/
/* end sp_GetTourMargin.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_InsDogList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsDogList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[InsDogList]
GO
CREATE PROCEDURE [dbo].[InsDogList]
(
--<DATE>2012-10-24</DATE>
--<VERSION>2009.2.16.0</VERSION>
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
	
	DECLARE @isIndividual smallint
	DECLARE @nCounter int
	
	--koshelev MEG00034729
	declare @isCity int
	select @isCity = SV_ISCITY from Service where SV_KEY = @nSvKey
	if (@isCity = 0)
		set @nCity = 0

	select @sComment = case when len(@sComment)> 0 then substring(@sComment,1, len(@sComment)) else null end
	select @sFormulaNetto = case when len(@sFormulaNetto)> 0 then substring(@sFormulaNetto,1, len(@sFormulaNetto)) else null end
	select @sFormulaBrutto = case when len(@sFormulaBrutto)> 0 then substring(@sFormulaBrutto,1, len(@sFormulaBrutto)) else null end
	select @sFormulaDiscount = case when len(@sFormulaDiscount)> 0 then substring(@sFormulaDiscount,1, len(@sFormulaDiscount)) else null end

	-- установим статус в зависимости от настроек в справочнике услуг
	select @nControl = sv_control from [service] where sv_key = @nSvKey

	If @nDGKey is NULL
		SELECT @nDGKey = DG_KEY FROM tbl_Dogovor with (nolock) where DG_Code = @sDogovor ORDER BY DG_CRDATE DESC
	SELECT @nLong = ISNULL(DG_NDAY,0) FROM tbl_Dogovor with (nolock) where DG_Code = @sDogovor ORDER BY DG_CRDATE DESC
	
	DECLARE @NDL_TimeEnd datetime
	IF @nSvKey=1
		exec [dbo].[MakeFullSVName]
			@nCountry, @nCity, @nSvKey, @nCode, null, 
			@nCode1, @nCode2, 0, @dBeg, null, 
			@sService output, @sServiceLat output, @tTime output, @NDL_TimeEnd output
	set @nPrmPlaceNoHave = 0
	
	select @isIndividual = ISNULL(SV_IsIndividual, 0) from dbo.Service where SV_Key = @nSvKey	
	if @isIndividual = 0
	begin
  		begin tran;
		
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
			Insert into tbl_DogovorList with(updlock) (	DL_DgCod,DL_Key,DL_TurDate,DL_DateBeg,DL_DateEnd,
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
				rollback tran;
				Return 1
			END
		commit tran;
		END	
	end
	else -- Task 8984 24.10.2012 kolbeshkin множим по кол-ву туристов услуги с классом, 
	begin -- у которого проставлен признак "Индивидуальное бронирование"
		set @nCounter = 0
		while @nCounter < @nMen
		begin
			begin tran;
			
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
				Insert into tbl_DogovorList with(updlock) (	DL_DgCod,DL_Key,DL_TurDate,DL_DateBeg,DL_DateEnd,
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
															@nCity,@nPartner,@nAgent,@nNetto/@nMen,@nPaket,
															0,@nControl,@nCreator,@nOwner,@nBrutto/@nMen,
															@nDiscount,1,@bWait,@nAttribute,@nTour,
															0,@nDGKey,@sComment,@sFormulaNetto, @sFormulaBrutto, @sFormulaDiscount,
															@nLong,	@nPrtDog, @nTaxZone)
				IF @@ERROR <>0
				BEGIN
					set @bRet = 0
					rollback tran;
					Return 1
				END
			commit tran;
			END
			set @nCounter = @nCounter + 1
		end
	end
	return 0
GO
grant exec on [dbo].[InsDogList] to public 
go

/*********************************************************************/
/* end sp_InsDogList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_MakeFullSVName.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MAKEFULLSVNAME]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MakeFullSVName]
GO
CREATE    PROCEDURE [dbo].[MakeFullSVName]
(
--<VERSION>2005.2.41 (2007.2.17)</VERSION>
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
	@sResultLat VARCHAR(800) OUTPUT,
	@dTimeBeg DateTime =null OUTPUT,
	@dTimeEnd DateTime =null OUTPUT
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

/*
       	DECLARE @n INT
	DECLARE @sSelect VARCHAR(800)
	DECLARE @sTempString2 VARCHAR(800)
	DECLARE @sTempString3 VARCHAR(800)

	DECLARE @nTmp INT
	DECLARE @sTmp VARCHAR(800)
*/
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
	Set @dTimeBeg=null
	Set @dTimeEnd=null

	Set @nTempNumber = 1
	EXEC dbo.GetServiceName @nSvKey, @nTempNumber, @sName output, @sNameLat output

	If @sName != ''
		Set @sName = @sName + '::'
	If @sNameLat != ''
		Set @sNameLat = @sNameLat + '::'

	If @nSvKey = @TYPE_FLIGHT
	BEGIN
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

		-- День недели в формате 1 - пон, 7 - вс
		Declare @nday int
		Set @nday = DATEPART(dw, @dServDate)  + @@DATEFIRST - 1
		If @nday > 7 
	    		set @nday = @nday - 7
	
		If @nCode>0
		BEGIN
			SELECT	@sText = isnull(CH_AirLineCode, '') + CH_Flight + ', ' + isnull(CH_PortCodeFrom, '') + '-' + isnull(CH_PortCodeTo, ''),
					@sTextLat = isnull(CH_AirLineCode, '') + CH_Flight + ', ' + isnull(CH_PortCodeFrom, '') + '-' + isnull(CH_PortCodeTo, '')
			FROM 	dbo.Charter
			WHERE 	CH_Key=@nCode

			SELECT	TOP 1 
					@dTimeBeg=AS_TimeFrom,
					@dTimeEnd=AS_TimeTo
			FROM 	dbo.AirSeason
			WHERE 	AS_CHKey=@nCode 
					and CHARINDEX(CAST(@nday as varchar(1)),AS_Week)>0
					and @dServDate between AS_DateFrom and AS_DateTo
			ORDER BY AS_TimeFrom DESC
			IF @dTimeBeg is not null and @dTimeEnd is not null
			BEGIN
				Set @sText=@sText+', '+LEFT(CONVERT(varchar, @dTimeBeg, 8),5) + '-' + LEFT(CONVERT(varchar, @dTimeEnd, 8),5)
				Set @sTextLat=@sTextLat+', '+LEFT(CONVERT(varchar, @dTimeBeg, 8),5) + '-' + LEFT(CONVERT(varchar, @dTimeEnd, 8),5)
			END
		END
		
		Set @sName = @sName + @sText + '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'

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
	ELSE If (@nSvKey = @TYPE_HOTEL or @nSvKey = @TYPE_HOTELADDSRV)
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

		Set @sText = '  '
		Set @sTextLat = '  '

/*
		SELECT  @sText = RM_Name + ',' + RC_Name + ',' + isnull(AC_Code, ''), 
			@sTextLat = isnull(RM_NameLat,RM_Name) + ',' + isnull(RC_NameLat,RC_Name) + ',' + isnull(AC_Code, ''),
			@nMain = AC_Main, 
			@nAgeFrom = AC_AgeFrom, 
			@nAgeTo = AC_AgeTo 
		FROM 	dbo.HotelRooms,dbo.Rooms,dbo.RoomsCategory,dbo.AccmdMenType 
		WHERE	HR_Key = @nCode1 and RM_Key = HR_RmKey and RC_Key = HR_RcKey and AC_Key = HR_AcKey
				
		If @nMain > 0
		BEGIN
			Set @sText = @sText + ',Осн'
			Set @sTextLat = @sTextLat + ',Main'
		END
		ELSE
		BEGIN
			Set @sText = @sText + ',доп.'
			Set @sTextLat = @sTextLat + ',ex.b'
			If @nAgeFrom >= 0
			BEGIN
	       	        	     Set @sTempString = '(' + isnull(cast(@nAgeFrom as varchar (10)), '')  + '-' +  isnull(cast(@nAgeTo as varchar(10)), '')  + ')'
       			             Set @sText = @sText + @sTempString
       			             Set @sTextLat = @sTextLat + @sTempString
			END
		END
*/

	      	EXEC dbo.GetSvCode1Name @nSvKey, @nCode1, @sText output, @sTempString output, @sTextLat output, @sTempStringLat output
       		Set @sName = @sName + isnull(@sTempString, '') + '/'
		Set @sNameLat = @sNameLat + isnull(@sTempStringLat, '') + '/'

		Set @sText = '  '
              	EXEC dbo.GetSvCode2Name @nSvKey, @nCode2, @sTempString output, @sTempStringLat output
             
             	Set @sName = @sName + isnull(@sTempString, '') + '/'
		Set @sNameLat = @sNameLat + isnull(@sTempStringLat, '') + '/'
	END
	ELSE If (@nSvKey = @TYPE_EXCUR or @nSvKey = @TYPE_TRANSFER)
	BEGIN
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

		Set @sText = '  '
		Set @sTextLat = '  '
		If @nCode1>0
			SELECT 	@sText = TR_Name + (case  when (TR_NMen>0)  then (','+ CAST ( TR_NMen  AS VARCHAR(10) )+ ' чел.')  else ' ' end),
				@sTextLat = isnull(TR_NameLat,TR_Name) + (case  when (TR_NMen>0)  then (','+ CAST ( TR_NMen  AS VARCHAR(10) )+ ' pax.')  else ' ' end) 
			FROM	dbo.Transport  
			WHERE	TR_Key = @nCode1
		Set @sName = @sName + @sText + '/'
		Set @sNameLat = @sNameLat + @sTextLat + '/'
	END
	ELSE If (@nSvKey = @TYPE_SHIP or @nSvKey = @TYPE_SHIPADDSRV)
	BEGIN
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

		Set @sText = '  '
		Set @sTextLat = '  '
		
	      	EXEC dbo.GetSvCode1Name @nSvKey, @nCode1, @sText output, @sTempString output, @sTextLat output, @sTempStringLat output
		Set @sName = @sName + isnull(@sTempString, '') + '/'
		Set @sNameLat = @sNameLat + isnull(@sTempStringLat, '') + '/'

		Set @sText = '  '
              	EXEC dbo.GetSvCode2Name @nSvKey, @nCode2, @sTempString output, @sTempStringLat output
		
		Set @sName = @sName + isnull(@sTempString, '') + '/'
		Set @sNameLat = @sNameLat + isnull(@sTempStringLat, '') + '/'
	END
	ELSE
	BEGIN
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
/*
			if @nSvKey = @TYPE_HOTELADDSRV
			BEGIN
				SELECT	@sText = HD_Name + '-' + isnull(HD_Stars, '') 
				FROM	dbo.HotelDictionary 
				WHERE	HD_Key = @nCode
				Set @sTextLat = @sText
			END
			ELSE if @nSvKey = @TYPE_SHIPADDSRV
			BEGIN
				SELECT	@sText = SH_Name + '-' + isnull(SH_Stars, '') 
				FROM	dbo.Ship
				WHERE	SH_Key = @nCode
				Set @sTextLat = @sText
			END
			ELSE 
*/
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

		Set @sText = '  '
		Set @sTextLat = '  '
		Set @sTempString = 'CODE1'
		exec dbo.GetSvListParm @nSvKey, @sTempString, @nTempNumber output

		If @nTempNumber>0
		BEGIN
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
		END
	END
	Set @sResult = @sName
	Set @sResultLat = @sNameLat
GO
GRANT EXECUTE ON dbo.MakeFullSVName TO PUBLIC 
GO
/*********************************************************************/
/* end sp_MakeFullSVName.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_MakePutName.sql */
/*********************************************************************/
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
--<VERSION>2009.2.2</VERSION>
--<DATE>2012-10-10</DATE>
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

		--if (@ch != @chPrev or @format = '') and (LEN(@ch) > 0 or (@chPrev = '9' or @chPrev = '#'))
		if (@ch != @chPrev)
		begin
			if @format = '' and (@ch = @chPrev) --and (@ch != '9' and @ch != '#')
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
			if (@chPrev = '9' or @chPrev = '#') 
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
				
				--set @number_part_length = @number_part_length + 1
				set @number_part_length = @len
				
				if (@number_part_start_point < 0)
					set @number_part_start_point = LEN(@name) + 1

				if @chPrev = '9'
				begin
					if dbo.IsStrNumber(LTRIM(RTRIM(@str))) > 0
					begin
						set @str = dbo.NextNumber(@notAllowedSymbols, LTRIM(STR(CAST(@str as bigint) + 1)))
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
				-- чтобы номер не увеличивался сверх длины шаблона, когда заканчиваются числа для нумерации
				set @str = substring(@str, 1, @len)
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
			set @str = RIGHT(dbo.NextNumber(@notAllowedSymbols, LTRIM(STR(CAST(@str as bigint) + 1))),@number_part_length)
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


/*********************************************************************/
/* end sp_MakePutName.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_MarginMonitor_PriceFilter.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MarginMonitor_PriceFilter]') AND TYPE IN (N'P', N'PC'))
	DROP PROCEDURE [dbo].[MarginMonitor_PriceFilter]
GO

--реализация основных фильтров Маржинального монитора
--<version>2009.15.1</version>
--<data>2012-10-12</data>
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
	@isDeletedPriceOnly           BIT   = NULL,                       -- только удаленные туры
	@isMinPrice                   BIT   = NULL,                       -- по минимальным ценам
	@isOnlineOnly                 BIT   = NULL,                       -- только выставленные в интернет туры
	@isModifyPriceOnly            BIT   = NULL,                       -- только измененные цены
	@isAllotment                  BIT   = NULL,                       -- для отелей по квотам элотмент
	@isCommitment                 BIT   = NULL,                       -- для отелей по квотам коммитмент
	@hideStopSale                 BIT   = NULL,                       -- скрывать отели на Stop-Sale
	@accmdDefaultKey              INT   = NULL,                       -- тип размещения по умолчанию
	@roomTypeDefaultKey           INT   = NULL,                       -- тип комнаты по умолчанию
	@isOnlyActualTourDates        BIT   = 1,                          -- 1-отбор по датам не ниже текущей    0-отбор по всем переданным датам
	@isHideAccommodationWithAdult BIT   = 1,                          -- только размещения без доп. мест
	@needFlightStatistic          BIT   = 0                           -- загружать места по рейсам или нет
) AS BEGIN

DECLARE @beginTime DATETIME

SET ARITHABORT ON;
SET DATEFIRST 1;
SET NOCOUNT ON;


DECLARE @toutDatesTable TABLE (tourDate DATETIME)
INSERT INTO @toutDatesTable(tourDate)
SELECT tbl.res.value('.', 'datetime')
FROM @tourDates.nodes('/ArrayOfDateTime/dateTime') AS tbl(res)

IF @isOnlyActualTourDates = 1
BEGIN
	DELETE @toutDatesTable
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


-- прямые перелеты
DECLARE @chartersTable TABLE
(
	xCH_Key BIGINT,
	xCharterDate DATETIME,
	xTS_PKKey BIGINT,
	xTS_SubCode1 BIGINT,
	xTS_Days INT,
	xBusyPlaces INT,
	xTotalPlaces INT
)

-- выборка прямых перелетов
IF @needFlightStatistic = 1
BEGIN
	SET @beginTime = GETDATE()
	
	INSERT INTO @chartersTable(xCH_Key, xCharterDate, xTS_PKKey, xTS_SubCode1, xTS_Days)
	SELECT DISTINCT sv.TS_Code, pc.PC_TourDate, sv.TS_OpPacketKey, sv.TS_SubCode1, sv.TS_Days
	FROM TP_PriceComponents pc
	INNER JOIN TP_Tours tour WITH(NOLOCK) ON tour.TO_Key = pc.PC_TOKey
	INNER JOIN TP_Services sv WITH(NOLOCK) ON sv.TS_TOKey = pc.PC_TOKey
	INNER JOIN Charter ch WITH(NOLOCK) ON ch.CH_KEY = sv.TS_Code
	INNER JOIN AirSeason air WITH(NOLOCK) ON air.AS_CHKEY = ch.CH_KEY
	WHERE
		(pc.PC_TourDate IN (SELECT tourDate FROM @toutDatesTable)) AND
		(sv.TS_Day = 1) AND (sv.TS_SVKey = 1) AND (sv.TS_CTKey = @targetFlyCityKey) AND (sv.TS_SubCode2 = @departCityKey) AND
		(tour.TO_CNKey = @countryKey) AND
		(pc.PC_TourDate BETWEEN air.AS_DATEFROM AND air.AS_DATETO) AND
		(AS_WEEK LIKE '%'+CAST(DATEPART(WEEKDAY, pc.PC_TourDate) AS VARCHAR(1))+'%')
		
	PRINT 'грузим прямые перелеты: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))

	SET @beginTime = GETDATE()

	-- дополнительные перелеты
	DECLARE @addChartersTable TABLE
	(
		xCH_Key BIGINT,
		xAddChKey BIGINT,
		xCharterDate DATETIME,
		xTS_SubCode1 BIGINT,
		xTS_PKKey BIGINT,
		xTS_Days INT
	)

	INSERT INTO @addChartersTable(xCH_Key, xAddChKey, xCharterDate, xTS_SubCode1, xTS_PKKey, xTS_Days)
	SELECT DISTINCT xCH_Key, CH_Key, xCharterDate, xTS_SubCode1, xTS_PKKey, xTS_Days
	FROM AirSeason WITH(NOLOCK), Charter WITH(NOLOCK), Costs WITH(NOLOCK), @chartersTable
	WHERE
		CH_CityKeyFrom = @departCityKey AND
		CH_CityKeyTo = @targetFlyCityKey AND
		CS_Code = CH_Key AND
		AS_CHKey = CH_Key AND
		CS_SVKey = 1 AND
		(ISNULL((SELECT TOP 1 AS_GROUP FROM AIRSERVICE WITH(NOLOCK) WHERE AS_KEY = CS_SubCode1), '')
		 =
		 ISNULL((SELECT TOP 1 AS_GROUP FROM AIRSERVICE WITH(NOLOCK) WHERE AS_KEY = xTS_SubCode1), '')
		) AND
		CS_PKKey = xTS_PKKey AND
		xCharterDate BETWEEN AS_DateFrom AND AS_DateTo AND
		xCharterDate BETWEEN CS_Date AND CS_DateEnd AND
		AS_Week LIKE '%'+CAST(DATEPART(WEEKDAY, xCharterDate)AS VARCHAR(1))+'%' AND
		(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+CAST(DATEPART(WEEKDAY, xCharterDate)AS VARCHAR(1))+'%') AND
		(CS_Long IS NULL OR CS_LongMin IS NULL OR xTS_Days BETWEEN CS_LongMin AND CS_Long)

	UPDATE @chartersTable
	SET xTotalPlaces = q.TotalPlaces, xBusyPlaces = q.BusyPlaces
	FROM
	   (SELECT ct.xCH_Key AS CH_Key, SUM(qp.QP_Places) AS TotalPlaces, SUM(qp.QP_Busy) AS BusyPlaces
		FROM @chartersTable ct, QuotaDetails qd
		INNER JOIN QuotaParts qp ON qp.QP_QDID = qd.QD_ID
		INNER JOIN QuotaObjects qo ON qo.QO_QTID = qd.QD_QTID
		WHERE
			(qo.QO_SVKey = 1) AND
			(qo.QO_SubCode1 = ct.xTS_SubCode1) AND
			(qd.QD_Date = ct.xCharterDate) AND
			(ISNULL(qp.QP_IsDeleted,0) = 0) AND
			(ISNULL(qp.QP_AgentKey,0) = 0) AND
			 qo.QO_Code IN (SELECT act.xAddChKey FROM @addChartersTable act
							WHERE (act.xCharterDate = ct.xCharterDate) AND
								  (act.xCH_Key = ct.xCH_Key) AND
								  (act.xTS_PKKey = ct.xTS_PKKey) AND
								  (act.xTS_SubCode1 = ct.xTS_SubCode1) AND
								  (act.xTS_Days = ct.xTS_Days))
		GROUP BY ct.xCH_Key) AS q
	WHERE xCH_Key = q.CH_Key

	PRINT 'подбираем подходящие перелеты: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))

	--SELECT * from @chartersTable
END

SET @beginTime = GETDATE()

SELECT
	pc.PC_Id AS PC_Id,
	pc.PC_SummPrice AS TourOldPrice,
	pc.PC_TourDate AS TourDate,
	tpLists.TI_DAYS AS TourDays,
	hr.HR_ACKEY AS AccmdKey,
	hr.HR_RMKEY AS RoomKey,
	tpLists.TI_FirstHDKey AS HotelKey,
	hd.HD_Code AS HotelCode,
	hr.HR_RCKEY AS RoomCategoryKey,
	tpLists.TI_FirstPNKey AS PansionKey,
	SCP_Men AS Mens,
	-- CharterBusyPlaces
	(SELECT TOP 1 xBusyPlaces FROM @chartersTable
	 WHERE (xCharterDate = pc.PC_TourDate) AND (xTS_PKKey = TS_OpPacketKey) AND (xTS_SubCode1 = TS_SubCode1) AND (xTS_Days = TS_Days))
	AS CharterBusyPlaces,
	-- CharterTotalPlaces
	(SELECT TOP 1 xTotalPlaces FROM @chartersTable
	 WHERE (xCharterDate = pc.PC_TourDate) AND (xTS_PKKey = TS_OpPacketKey) AND (xTS_SubCode1 = TS_SubCode1) AND (xTS_Days = TS_Days))
	AS CharterTotalPlaces,
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
FROM TP_PriceComponents pc
INNER JOIN TP_Tours tour WITH(NOLOCK) ON tour.TO_Key = pc.PC_TOKey
INNER JOIN TP_Lists tpLists WITH(NOLOCK) ON pc.PC_TIKey = tpLists.TI_Key
INNER JOIN HotelRooms hr WITH(NOLOCK) ON tpLists.TI_FirstHRKey = hr.HR_Key
INNER JOIN HotelDictionary hd WITH(NOLOCK) ON tpLists.TI_FirstHDKey = hd.HD_Key
INNER JOIN TP_ServiceLists sl WITH(NOLOCK) ON tpLists.TI_Key = sl.TL_TIKey
INNER JOIN TP_Services tpService WITH(NOLOCK) ON sl.TL_TSKey = tpService.TS_Key
INNER JOIN TP_ServiceCalculateParametrs WITH(NOLOCK) ON SCPId_1 = SCP_Id
WHERE
	(tpService.TS_SVKey = 1) AND (tpService.TS_Day = 1) AND (tpService.TS_CTKey = @targetFlyCityKey) AND (tpService.TS_SubCode2 = @departCityKey) AND
	(tour.TO_CNKey = @countryKey) AND
	(pc.PC_TourDate IN (SELECT tourDate FROM @toutDatesTable)) AND
	(pc.PC_HotelKey IN (SELECT hotelKey FROM @hotelKeysTable)) AND
	(hd.HD_CTKEY IN (SELECT cityKey FROM @targetCitiesKeysTable)) AND
	(ISNULL(@isHideAccommodationWithAdult, 0) = 0 OR (HR_ACKEY IN (SELECT AC_KEY FROM Accmdmentype WHERE (ISNULL(AC_NADMAIN, 0) > 0) AND (ISNULL(AC_NCHMAIN, 0) = 0) AND (ISNULL(AC_NCHISINFMAIN, 0) = 0)))) AND
	-- фильтр по мин. ценам НЕ задан
	((ISNULL(@isMinPrice, 0) = 0 AND
	-- проверяем тур на те категории номеров и питаний, которые были переданы
	hr.HR_RCKEY IN (SELECT rcKey FROM @roomCategoryKeysTable) AND
	tpLists.TI_FirstPNKey IN (SELECT pansionKey FROM @pansionKeysTable))
	OR
	-- фильтр по мин. ценам задан
	(ISNULL(@isMinPrice, 0) != 0 AND
	-- проверяем по базовым привязкам отеля
	hr.HR_RCKEY = (SELECT TOP 1 ahc.AH_RcKey FROM AssociationHotelCat ahc WHERE ahc.AH_HdKey = tpLists.TI_FirstHDKey) AND
	tpLists.TI_FirstPNKey = (SELECT TOP 1 ahc.ah_pnkey FROM AssociationHotelCat ahc WHERE ahc.AH_HdKey = tpLists.TI_FirstHDKey) AND
	-- если заданы обе настройки с типом размещения и типом комнаты, то отсеиваем по ним
	(ISNULL(@accmdDefaultKey, 0) = 0 OR ISNULL(@roomTypeDefaultKey, 0) = 0 OR
	((hr.HR_ACKEY = @accmdDefaultKey) AND (hr.HR_RMKEY = @roomTypeDefaultKey))))
	) AND
	-- только удаленные туры
	(ISNULL(@isDeletedPriceOnly, 0) = 0 OR pc.PC_SummPrice IS NULL) AND
	-- только выставленные в интернет туры
	(@isOnlineOnly IS NULL OR (@isOnlineOnly = CASE WHEN PC_SummPrice IS NULL THEN 0 ELSE TO_IsEnabled END)) AND
	-- отсев по ценам за тур
	(ISNULL(@priceMin, 0) = 0 OR (pc.PC_SummPrice >= @priceMin)) AND
	(ISNULL(@priceMax, 0) = 0 OR (pc.PC_SummPrice <= @priceMax)) AND
	-- отсев по продолжительностям
	(tpLists.TI_DAYS IN (SELECT longValue FROM @longListTable)) AND
	-- отсев по квотам элотмент по отелю
	(ISNULL(@isAllotment, 0) = 0 OR (SELECT COUNT(*) FROM (SELECT DISTINCT qd.QD_Date FROM QuotaDetails qd
								     INNER JOIN QuotaObjects qo ON qo.QO_QTID = qd.QD_QTID
							 	     WHERE qd.QD_Date BETWEEN pc.PC_TourDate AND pc.PC_TourDate + pc.PC_Days
										AND qd.QD_Type  = 1 -- элотмент
										AND qo.QO_SVKey = 3
										AND qo.QO_Code  = tpLists.TI_FirstHDKey)t) = pc.PC_Days + 1) AND
	-- отсев по квотам коммитмент по отелю
	(ISNULL(@isCommitment, 0) = 0 OR (SELECT COUNT(*) FROM (SELECT DISTINCT qd.QD_Date FROM QuotaDetails qd
								      INNER JOIN QuotaObjects qo ON qo.QO_QTID = qd.QD_QTID
							 	      WHERE qd.QD_Date BETWEEN pc.PC_TourDate AND pc.PC_TourDate + pc.PC_Days
									    AND qd.QD_Type  = 2 -- коммитмент
										AND qo.QO_SVKey = 3
										AND qo.QO_Code  = tpLists.TI_FirstHDKey)t) = pc.PC_Days + 1) AND
	-- скрыть отели на Stop-Sale
	(ISNULL(@hideStopSale, 0) = 0 OR NOT EXISTS(SELECT 1 FROM StopSales ss
								     INNER JOIN QuotaObjects qo ON qo.QO_ID = ss.SS_QOID
							 	     WHERE ss.SS_IsDeleted IS NULL
							 	        AND ss.SS_Date BETWEEN pc.PC_TourDate AND pc.PC_TourDate + pc.PC_Days
									    AND qo.QO_SVKey = 3
										AND qo.QO_Code = tpLists.TI_FirstHDKey
										AND (qo.QO_SubCode1 = 0 OR qo.QO_SubCode1 = tpLists.TI_FIRSTHRKEY))) AND
	-- только измененные цены
	(ISNULL(@isModifyPriceOnly, 0) = 0 OR
	-- пробуем найти в таблице TP_ServicePriceActualDate услугу с измененной ценой
	EXISTS(      SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_1  IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_1)  AND (spad.SPAD_Gross != pc.Gross_1)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_2  IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_2)  AND (spad.SPAD_Gross != pc.Gross_2)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_3  IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_3)  AND (spad.SPAD_Gross != pc.Gross_3)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_4  IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_4)  AND (spad.SPAD_Gross != pc.Gross_4)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_5  IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_5)  AND (spad.SPAD_Gross != pc.Gross_5)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_6  IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_6)  AND (spad.SPAD_Gross != pc.Gross_6)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_7  IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_7)  AND (spad.SPAD_Gross != pc.Gross_7)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_8  IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_8)  AND (spad.SPAD_Gross != pc.Gross_8)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_9  IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_9)  AND (spad.SPAD_Gross != pc.Gross_9)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_10 IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_10) AND (spad.SPAD_Gross != pc.Gross_10)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_11 IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_11) AND (spad.SPAD_Gross != pc.Gross_11)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_12 IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_12) AND (spad.SPAD_Gross != pc.Gross_12)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_13 IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_13) AND (spad.SPAD_Gross != pc.Gross_13)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_14 IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_14) AND (spad.SPAD_Gross != pc.Gross_14)
	       UNION SELECT 1 FROM TP_ServicePriceActualDate spad WHERE (pc.SCPId_15 IS NOT NULL) AND (spad.SPAD_SCPId = pc.SCPId_15) AND (spad.SPAD_Gross != pc.Gross_15)))
	       
	PRINT 'выбор туров: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
END
GO

GRANT EXEC ON [dbo].[MarginMonitor_PriceFilter] TO PUBLIC
GO

/*********************************************************************/
/* end sp_MarginMonitor_PriceFilter.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwAddToken.sql */
/*********************************************************************/
--<VERSION>9.2</VERSION>
--<DATE>2012-09-05</DATE>
--Хранимка добавляет новый токен в таблицу для авторизации пользователя в веб-сервисах. После чего чистит старые токены.

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwAddNewToken]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwAddNewToken]
GO

CREATE PROCEDURE [dbo].[mwAddNewToken]
	(
		@token varchar(500),
		@expireDate datetime
	)
AS
BEGIN
	INSERT INTO [dbo].[Tokens]([T_Token],[T_ExpireDate])VALUES(@token,@expireDate)
	delete from [dbo].[Tokens]
	where DATEDIFF(MINUTE, T_ExpireDate, GETDATE()) > 0
END
GO

GRANT EXECUTE ON [dbo].[mwAddNewToken] TO PUBLIC 
GO

/*********************************************************************/
/* end sp_mwAddToken.sql */
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
	--<DATE>2012-10-24</DATE>

	declare @StopSale int, @Release int, @Duration int, @NoPlaces int, @NoQuota int, @QuotaExist int
	set @StopSale = 0
	set @Release = 1
	set @Duration = 2
	set @NoPlaces = 3
	set @NoQuota = 4
	set @QuotaExist = 5

	-- настройки проверки квот через веб-сервис
	declare @checkQuotesOnWebService as bit, @checkQuotesService as nvarchar(150)
	set @checkQuotesOnWebService = 0
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
				
				set @dayOfWeek = datepart(dw, @charterDate) - 1
				if(@dayOfWeek = 0)
					set @dayOfWeek = 7
				
				declare altCharters cursor for
				select ch_key from
				(
					(
					select distinct ch_key, 0 as pr 
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
						and CH_KEY <> @chkey
						and (AS_WEEK is null 
								or len(as_week)=0 
								or as_week like ('%' + cast(@dayOfWeek as varchar) + '%'))
						and @charterDate between as_dateFrom and as_dateto
					)
					union 
					(
						select CH_KEY, 1 as pr from Charter with (nolock) where CH_KEY = @chkey
					)
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

					select @checkQuotesResult = result, @tmpPlaces = freePlaces, @tmpPlacesAll = allPlaces
					from [dbo].WcfQuotaCheckOneResult(1, 1, @altChKey, @nkey, @dateFrom, @dateTo,
						@partnerKey, @agentKey, @tourDays, @requestedPlaces, null)
				
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
				
				close altCharters
				deallocate altCharters
				
				select top 1 @tmpPlaces = xPlaces, @tmpPlacesAll = xPlacesAll from #charterPlacesResult order by xPriority asc
				
				drop table #charterPlacesResult
			
			end
			else
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
--<VERSION>ALL</VERSION>
--<DATE>2012-10-22</DATE>
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
	declare @checkQuotesOnWebService as bit, @checkQuotesService as nvarchar(150)
	set @checkQuotesOnWebService = 0
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
							set @pt_directFlightAttribute = 1
						if (@tableName is not null)
						begin
							set @sql = 'update ' + @tableName + ' set pt_directFlightAttribute = ' + ltrim(str(@pt_directFlightAttribute*2)) + ' where pt_key = ' + ltrim(str(@ptkey))
							exec (@sql)
						end
					end
					set @findFlight = @pt_directFlightAttribute
					
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
								set @pt_backFlightAttribute = 1
							if (@tableName is not null)
							begin
								set @sql = 'update ' + @tableName + ' set pt_backFlightAttribute = ' + ltrim(str(@pt_backFlightAttribute*2)) + ' where pt_key = ' + ltrim(str(@ptkey))
								exec (@sql)
							end
		
						end	

						set @findFlight = @pt_backFlightAttribute

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
								set @dateTo = dateadd(day, @hdnights - 1, @tourdate)
								-- включена проверка квот через веб-сервис
								select @checkQuotesResult = result, @places = freePlaces, @allPlaces = allPlaces
								from [dbo].WcfQuotaCheckOneResult(
										0, 3, @hdkey, @pt_hrkey, @dateFrom, @dateTo, @hdprkey, 
										@agentKey, @days, @pt_mainplaces, null)
										
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
							else
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
								exec mwParseHotelDetails @curHotelDetails, @curHotelKey output, @curRoomKey output, @curRoomCategoryKey output, @curHotelDay output, @curHotelDays output, @curHotelPartnerKey output
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
									set @dateFrom = dateadd(day, @hdday - 1, @tourdate)
									set @dateTo = dateadd(day, @hdnights - 1, @tourdate)
									-- включена проверка квот через веб-сервис
									select @checkQuotesResult = result, @tempPlaces = freePlaces, @tempAllPlaces = allPlaces
									from [dbo].WcfQuotaCheckOneResult(
											0, 3, @curHotelKey, @curRoomKey, @dateFrom, @dateTo, @hdprkey, 
											@agentKey, @days, @pt_mainplaces, null)								
								end
								else
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
/* begin sp_mwCheckToken.sql */
/*********************************************************************/
--<VERSION>9.2</VERSION>
--<DATE>2012-10-04</DATE>
--Хранимка проверяет токен для авторизации пользователя в веб-сервисах

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCheckToken]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwCheckToken]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCheckToken]') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	drop function [dbo].[mwCheckToken]
GO

CREATE FUNCTION [dbo].[mwCheckToken]
	(
		@token varchar(500)
	)
RETURNS INT		-- 0 - invalid token; 1 - token expired; 2 -  OK
AS
BEGIN
	
	if exists (select top 1 1 
				from Tokens
				where T_Token = @token and 
					DATEDIFF(MINUTE, T_ExpireDate, GETDATE()) <= 0)
		return 2
		
	if exists (select top 1 1 
				from Tokens
				where T_Token = @token and	
					DATEDIFF(MINUTE, T_ExpireDate, GETDATE()) > 0)
		return 1

	return 0
END
GO

GRANT EXECUTE ON [dbo].[mwCheckToken] TO PUBLIC 
GO
/*********************************************************************/
/* end sp_mwCheckToken.sql */
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
		set @today = dateadd(day, 1, @today)
	
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
			delete top (@priceCount) from dbo.tp_servicelists with(rowlock) where tl_tikey not in (select tp_tikey from tp_prices with(nolock) where tp_tokey = tl_tokey) and tl_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
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
			delete top (@priceCount) from dbo.tp_lists with(rowlock) where ti_key not in (select tp_tikey from tp_prices with(nolock) where tp_tokey = ti_tokey) and ti_tokey not in (select to_key from tp_tours with(nolock) where to_update <> 0)
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
/* begin sp_mwCreatePriceTable.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwCreatePriceTable')
	drop proc dbo.mwCreatePriceTable
go

CREATE procedure [dbo].[mwCreatePriceTable] @countryKey int, @cityFromKey int
as
begin
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
	set @sql='grant select, delete, update, insert on '+@tableName+' to public'
	exec(@sql)
end
GO

grant exec on dbo.mwCreatePriceTable to public
go

/*********************************************************************/
/* end sp_mwCreatePriceTable.sql */
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
	-- <date>2012-10-02</date>
	-- <version>2009.2.16.2</version>
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
			[TD_Key],
			[TD_TOKey],
			[TD_Date],
			[TD_UPDATE],
			[TD_CHECKMARGIN],
			[TD_CalculatingKey]
		from
			' + @source + 'dbo.TP_TurDates with(nolock)
		where
			'
			
		if(@calcKey is not null)
			set @sql = @sql + 'TD_Date in (select TP_DateBegin from ' + @source + 'dbo.TP_Prices where TP_TOKey = TD_TOKey and TP_CalculatingKey = ' + ltrim(str(@calcKey)) + ') and '
			
		set @sql = @sql + 'TD_TOKey = ' + @tokeyStr

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
/* begin sp_mwGetSearchFilterNights.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwGetSearchFilterNights]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[mwGetSearchFilterNights]
GO

CREATE PROCEDURE [dbo].[mwGetSearchFilterNights]
	@tourKeys varchar(500) = ''
AS
BEGIN	
	SET NOCOUNT ON;
    
	declare @sql varchar(max)
	
	set @sql = '
	SELECT DISTINCT sd_nights as Nights, substring(tourkeys,1,len(tourkeys)-1) as TourKeys
	FROM mwpricedurations p1
	CROSS APPLY ( 
		SELECT ltrim(rtrim(str(sd_tourkey))) + '',''
		FROM mwpricedurations p2
		WHERE p2.sd_nights = p1.sd_nights '+
		case when len(@tourKeys) > 0 
		then 'and sd_tourkey in (' + @tourKeys + ')'
		else '' end
		+' ORDER BY sd_tourkey 
		FOR XML PATH('''') )  D ( tourkeys )
	WHERE tourkeys is not null
	ORDER BY sd_nights'

	exec(@sql)
END
GO

grant exec on [dbo].[mwGetSearchFilterNights] to public
go
/*********************************************************************/
/* end sp_mwGetSearchFilterNights.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetServiceVariants.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwGetServiceVariants')
	drop proc dbo.mwGetServiceVariants
go

--<VERSION>9.2.1</VERSION>
--<DATE>2012-09-19</DATE>

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
		set	@selectClause = ' SELECT cs1.CS_Code, cs1.CS_SubCode1, cs1.CS_SubCode2, cs1.CS_PrKey, cs1.CS_PkKey, cs1.CS_Profit, cs1.CS_Type, cs1.CS_Discount, cs1.CS_Creator, cs1.CS_Rate, cs1.CS_Cost '
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
		set @orderClause  = 'cs1.CS_long'
	
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
			set @orderClause = @orderClause + 'cs1.CS_UPDDATE DESC'
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
			exec (@selectClause + @fromClause + ' WHERE ' + @whereClause + ' ORDER BY '+ @orderClause)
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
/* begin sp_mwGrantPermissions.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwGrantPermissions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[mwGrantPermissions]
GO

create procedure [dbo].[mwGrantPermissions]
	@countryKey int,
	@cityFromKey int
AS	
	declare @tableName varchar(1024)
	declare @sql varchar(8000)
	set @tableName = dbo.mwGetPriceViewName(@countryKey, @cityFromKey)
	set @sql = 'grant select, update on ' + @tableName + ' to public'
	exec (@sql)
	set @tableName = dbo.mwGetPriceTableName(@countryKey, @cityFromKey)
	set @sql = 'grant select, delete, insert, update on ' + @tableName + ' to public'
	exec (@sql)
GO

GRANT EXECUTE ON dbo.mwGrantPermissions TO PUBLIC 
GO
/*********************************************************************/
/* end sp_mwGrantPermissions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwMakeFullSVName.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MWMAKEFULLSVNAME]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mwMakeFullSVName]
GO
CREATE    PROCEDURE [dbo].[mwMakeFullSVName]
(
--<VERSION>2009.2.2</VERSION>
--<DATE>2012-09-17</DATE>
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
/* begin sp_Paging.sql */
/*********************************************************************/
if exists (select * from [dbo].sysobjects where id = object_id(N'[dbo].[Paging]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    DROP PROCEDURE [dbo].[Paging]
GO

CREATE procedure [dbo].[Paging]
@pagingType	smallint=2,
@countryKey	int,
@departFromKey	int,
@filter		varchar(4000),
@sortExpr	varchar(1024),
@pageNum	int=0,						-- номер страницы(начиная с 1 или количество уже просмотренных записей для исключения при @pagingType=@ACTUALPLACES_PAGING)
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
@calculateVisaDeadLine smallint = 0,
@noSmartSearch bit = 0,
@HideWithNotStartedSaleDate bit = 0		-- не показывать цены по турам, дата продажи которых еще не наступила.
AS
set nocount on

--<DATE>2012-11-02</DATE>
---<VERSION>2009.2.16</VERSION>

--koshelev
--@noPlacesResult должен быть больше 0
--2012-08-17
if (@noPlacesResult > 0 or @filter like '%in ()%')
	return

/******************************************************************************
**		Parameters:

		@filter		varchar(1024),	 - поисковый фильтр (where-фраза)
		@sortExpr	varchar(1024),	 - выражение сортировки
		@pageNum	int=1,	 - № страницы
		@pageSize	int=9999	 - размер страницы
		@transform	smallint=0	 - преобразовывать ли полученные данные для расположения продолжительностей по горизонтали
		@noSmartSearch bit = 0	- запрещает подмешивать варианты в поиск (приоритетней чем настройка в SystemSettings) - используется при недефолтной сортировке
*******************************************************************************/

-- vinge 9.08.2012 перенес в начало файла объявление таблицы с результатами
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


-- vinge 9.08.2012 без этой проверки хранимка вылетает с ошибкой
if (@hotelQuotaMask = 0) and (@aviaQuotaMask = 0)
begin
	select 0
	select 0
	select * from #resultsTable

	return
end

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

-- настройка включающая SmartSearch
declare @mwUseSmartSearch int
select @mwUseSmartSearch=isnull(SS_ParmValue,0) from dbo.systemsettings 
where SS_ParmName='mwUseSmartSearch'
-- пока SmartSearch работает с только с ACTUALPLACES_PAGING
-- параметр @noSmartSearch - блокирует подмешивание
if (@pagingType <> @ACTUALPLACES_PAGING or @noSmartSearch = 1)
begin
	set @mwUseSmartSearch = 0
end

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
			find_flight bit default(0)	-- 07.02.2012. Golubinsky. Для правильного кеширования результатов при подборе перелета
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
	insert into #days exec(@sql)

	declare @sKeysSelect varchar(2024)
	set @sKeysSelect=''
	declare @sAlter varchar(2024)
	set @sAlter=''

	if(@hotelQuotaMask > 0 or @aviaQuotaMask > 0)
	begin
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
		
		--MEG00038933 Tkachuk 16-02-2012
		--вызываем с последним параметром=null, иначе пытается записать в #resultsTable доп.столбец, и падает с ошибкой
		insert into #resultsTable exec PagingSelect @pagingType,@sKeysSelect,@spageNum,@spageSize,@filter,@sortExpr,@tableName,@viewName, null
		
		--MEG00038933 Tkachuk 16-02-2012
		--получаем количество строк не через output-переменную в предыдущей строке, а через select в результирующей таблице
		Set @rowCount = (select COUNT(*) from #resultsTable)
		Select @rowCount

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
							from ' + @tableName + ' with(nolock)
							where pt_key in (' + @sAddIN + ')'
			end
			else if (@pagingType = 0)
			begin
				set @sTmp = 'select pt_key, pt_pricekey, pt_tourdate, pt_days,	pt_nights, pt_hdkey, pt_hdday,
									pt_hdnights, pt_hdpartnerkey, pt_rmkey,	pt_rckey, pt_chkey,	pt_chday, pt_chpkkey,
									pt_chprkey, pt_chbackkey, pt_chbackday, pt_chbackpkkey, pt_chbackprkey, null, null, null, null
							from ' + @tableName + ' with(nolock)
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
							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @days, @expiredReleaseResult, @aviaMask, @tmpThereAviaQuota output
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
			ptpricekey bigint,
			newPrice money,
			pt_hdquota varchar(10),
			pt_chtherequota varchar(256),
			pt_chbackquota varchar(256),
			chkey int,
			chbackkey int,
			stepId int,
			priceCorrection float,
			pt_hdallquota varchar(256),
			-- признак того что вариант был подмешан (нужно для выделения)
			pt_smartSearch bit default 0
		)
		
		if((@pagingType <> @ACTUALPLACES_PAGING and @pagingType <> @DYNAMIC_SPO_PAGING) or (@hotelQuotaMask <= 0 and @aviaQuotaMask <= 0))
			set @sql=@sql + ' 
			insert into #Paging(ptkey) select ' 
		else
		begin

			-- Подмешивание отелей (SmartSearch) работает только для первой страницы
			if (@mwUseSmartSearch = 1 and @pageNum = 0)
			begin
				-- максимально возможное количество результов, которые могут быть подмешаны
				declare @maxSmartSearchResult tinyint; set @maxSmartSearchResult = 3;
				declare @smaxSmartSearchResult varchar(3); set @smaxSmartSearchResult=LTRIM(STR(@maxSmartSearchResult))
				
				-- количество реально подмешанных вариантов
				declare @realDashVariantsNumber smallint;
				
				set @sql=@sql + '
				declare quotaCursor cursor fast_forward read_only for
				select pt_key,pt_tourkey,pt_pricekey
				,pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,pt_hdday,pt_hdnights, (case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chpkkey else -1 end) as pt_chpkkey,pt_chprkey,pt_chbackday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey,pt_chbackprkey,pt_days, 
				pt_chkey, pt_chbackkey, 0, '''' pt_chdirectkeys, '''' pt_chbackkeys, '''' pt_hddetails
				, pt_directFlightAttribute, pt_backFlightAttribute, pt_mainplaces, pt_hrkey
				from ' + @tableName + ' with(nolock) inner join hotelPriorities with(nolock) on pt_hdkey = hp_hdkey'
				
				if @HideWithNotStartedSaleDate = 1
					set @sql = @sql + ' inner join tp_tours with (nolock) on pt_tourkey = to_key and (TO_DateValidBegin IS NULL OR getdate() >= TO_DateValidBegin) AND (TO_DateValid IS NULL OR getdate() <= TO_DateValid) '
					
				set @sql = @sql + ' where (' + @filter
				-- null не может быть для ВСЕХ одновременно приоритетов присутствующих в фильтах
				-- т.к. по стране фильтруем всегда, то приоритет для страны проверяем на null тоже всегда
				set @sql = @sql + ') and (HP_CountryPriority is not null'
				-- если есть фильтр для города, то проверяем на null приоритет для города
				if (charindex('pt_ctkey',@filter) > 0)
				begin
					set @sql = @sql + ' or HP_CityPriority is not null '
				end
				-- если есть фильтр для курорта, то проверяем на null приоритет для курорта
				if (charindex('pt_rskey',@filter) > 0)
				begin
					set @sql = @sql + ' or HP_ResortPriority is not null '
				end
				set @sql = @sql + ') '
				set @sql = @sql + '
				-- фильтр по отсутсвию инфанта
				and not exists (select top 1 1 from accmdmentype where ac_key=pt_ackey and ac_name like ''%инфант%'')
				order by '
				
				-- если в фильтре есть город
				if (charindex('pt_ctkey',@filter) > 0)
				begin
					set @sql = @sql + 'case when HP_CityPriority is null then 1 else 0 end, hp_cityPriority, '
				end
				
				-- если в фильтре есть курорт
				if (charindex('pt_rskey',@filter) > 0)
				begin
					set @sql = @sql + 'case when HP_ResortPriority is null then 1 else 0 end, hp_resortPriority, '
				end
				
				-- по стране и стандартной сортировке сортируем в любом случае
				set @sql = @sql + 'case when HP_CountryPriority is null then 1 else 0 end, hp_countryPriority, ' + @sortExpr

				-- запустим mwCheckQuotesCycle с последним параметром = 1 (индикатор того, что ищем подмешанные варианты)
				-- маски квот для подмешанных вариантов:
				-- отель: 1 - есть
				-- перелет: 1 - есть
				set @sql=@sql + '
				open quotaCursor

				exec dbo.mwCheckQuotesCycle ' + ltrim(str(@pagingType))+ ', ' + @spageNum + ', ' + @smaxSmartSearchResult + ', ' + ltrim(str(@agentKey)) + ', 1, 1, ''' + @flightGroups + ''', ' + ltrim(str(@checkAgentQuota)) + ', ' + ltrim(str(@checkCommonQuota)) + ', ' + ltrim(str(@checkNoLongQuota)) + ', ' + ltrim(str(@requestOnRelease)) + ', ' + ltrim(str(@expiredReleaseResult)) + ', ' + ltrim(str(@noPlacesResult)) + ', ' + ltrim(str(@findFlight)) + ', 1

				close quotaCursor
				deallocate quotaCursor
				'
				--print @sql;
				exec (@sql);
				set @sql = '';
				-- после этого в #Paginge - хранится столько строк сколько мы подмешали (0-3)
				-- уменьшим pageSize на это число, чтобы сохранить общее кол-во выводимых строк
				select @realDashVariantsNumber = count(1) from #Paging;
				set @pageSize = @pageSize - @realDashVariantsNumber;
				set @spageSize=ltrim(str(@pageSize));
			end

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
	
		set @sql=@sql + ' pt_key,pt_tourkey, pt_pricekey '
		if((@pagingType=@ACTUALPLACES_PAGING or @pagingType=@DYNAMIC_SPO_PAGING) and (@hotelQuotaMask > 0 or @aviaQuotaMask > 0))
		begin
			set @sql=@sql + ',pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,pt_hdday,pt_hdnights, (case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_hdpartnerkey end),pt_chday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chpkkey else -1 end) as pt_chpkkey,pt_chprkey,pt_chbackday,(case when ' + ltrim(str(@checkFlightPacket)) + ' > 0 then pt_chbackpkkey else -1 end) as pt_chbackpkkey,pt_chbackprkey,pt_days, '
			if(@pagingType <> @DYNAMIC_SPO_PAGING)
				set @sql = @sql + ' pt_chkey, pt_chbackkey, 0, pt_chdirectkeys, pt_chbackkeys, pt_hddetails '
			else
				set @sql = @sql + ' ch_key as pt_chkey, chb_key as pt_chbackkey, row_number() over(order by ' + @sortExpr + ') as rowNum '
		end
		set @sql=@sql + ' , pt_directFlightAttribute, pt_backFlightAttribute, pt_mainplaces, pt_hrkey from ' + @tableName + ' with(nolock) '
		
		if @HideWithNotStartedSaleDate = 1
			set @sql = @sql + ' inner join tp_tours with (nolock) on pt_tourkey = to_key and (TO_DateValidBegin IS NULL OR getdate() >= TO_DateValidBegin) AND (TO_DateValid IS NULL OR getdate() <= TO_DateValid) '

		if(@pagingType = @DYNAMIC_SPO_PAGING)
			set @sql = @sql + ' left outer join 
			(select pt_tourdate as tourdate, pt_chbackday as chbackday, pt_chkey as chkey, pt_chbackkey as chbackkey, ch.ch_key as ch_key, chb.ch_key as chb_key 
				from (select distinct pt_tourdate, pt_chbackday, pt_chkey, pt_chbackkey from ' + @tableName + ' where ' + @filter + ') ptd 
				left outer join charter ptch with(nolock) on (ptch.ch_key = pt_chkey) left outer join charter ptchb with(nolock) on (ptchb.ch_key = pt_chbackkey)
				left outer join charter ch with(nolock) on (ptch.ch_citykeyfrom = ch.ch_citykeyfrom and ptch.ch_citykeyto = ch.ch_citykeyto) left outer join charter chb with(nolock) on (ptchb.ch_citykeyto = chb.ch_citykeyto and ptchb.ch_citykeyfrom = chb.ch_citykeyfrom and chb.ch_airlinecode = ch.ch_airlinecode) 
			left outer join airseason a with(nolock) on (a.as_chkey = ch.ch_key and ptd.pt_tourdate between a.as_datefrom and a.as_dateto and a.as_week like (''%'' +  ltrim(str(datepart(dw, dateadd(day, -1, ptd.pt_tourdate))))+ ''%'')) left outer join airseason ab with(nolock) on (ab.as_chkey = chb.ch_key and dateadd(day, pt_chbackday - 1, ptd.pt_tourdate) between ab.as_datefrom and ab.as_dateto and ab.as_week like (''%'' +  ltrim(str(datepart(dw, dateadd(day, pt_chbackday - 2, ptd.pt_tourdate)))) + ''%''))) pt1
		on (pt_tourdate = tourdate and pt_chkey = chkey and pt_chbackkey = chbackkey and pt_chbackday = chbackday)'

		if @aviaQuotaMask = 5 or @aviaQuotaMask = 1
		begin
			-- Соединим выборку курсора квот с кешем квот, чтобы отсеять туры с закончившимися перелетами
			set @filter = @filter + '
			and not exists 
								(
								select top 1 1 
								from CacheQuotas as directCharter with (nolock) 
								where 
									directCharter.cq_svkey = 1
									and directCharter.cq_code = pt_chkey
									and directCharter.cq_date = pt_tourdate
									and directCharter.cq_day = pt_chday
									and directCharter.cq_days = pt_days
									and directCharter.cq_prkey = pt_chprkey
									and directCharter.cq_pkkey = pt_chpkkey
									and directCharter.cq_places = 0
									and (pt_directFlightAttribute is not null 
											and 
											(
												(directCharter.cq_findFlight = 1 and (pt_directFlightAttribute & 2) = 2)
												or
												(directCharter.cq_findFlight = 0 and (pt_directFlightAttribute & 2) = 0)
											)
										)
								)
			and not exists 
								(
								select top 1 1 
								from CacheQuotas as backCharter  with (nolock) 
								where
									backCharter.cq_svkey = 1
									and backCharter.cq_code = pt_chbackkey
									and backCharter.cq_date = pt_tourdate
									and backCharter.cq_day = pt_chbackday
									and backCharter.cq_days = pt_days
									and backCharter.cq_prkey = pt_chprkey
									and backCharter.cq_pkkey = pt_chpkkey
									and backCharter.cq_places = 0
									and (pt_backFlightAttribute is not null 
											and 
											(
												(backCharter.cq_findFlight = 1 and (pt_backFlightAttribute & 2) = 2)
												or
												(backCharter.cq_findFlight = 0 and (pt_backFlightAttribute & 2) = 0)
											)
									)
								)
			'
		end

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
		
		if(substring(@sortExpr, 1, 1) = '*')					-- begin tkachuk 21.02.2012 Исправлена ошибка, возникающая при некотором наборе параметров
		begin
			set @sortExpr = SUBSTRING(@sortExpr, 2, LEN(@sortExpr) - 1)
			set @sortExpr = LTRIM(@sortExpr)
			
			if(SUBSTRING(@sortExpr, 1, 1) = ',')
			begin
				set @sortExpr = SUBSTRING(@sortExpr, 2, LEN(@sortExpr) - 1)
				set @sortExpr = LTRIM(@sortExpr)
			end
		end														-- end tkachuk 21.02.2012

		if (len(isnull(@sortExpr,'')) > 0 and @pagingType <> @DYNAMIC_SPO_PAGING)
			set @sql=@sql + ' order by '+ @sortExpr
	
		if(@pagingType=@ACTUALPLACES_PAGING or @pagingType=@DYNAMIC_SPO_PAGING)
		begin
			if (@pageNum=0) -- количество записей возвращаем только при запросе первой страницы
			begin
				set @sql=@sql + ' 
				select count(*) from ' + @tableName + ' with(nolock) '
				
				if @HideWithNotStartedSaleDate = 1
					set @sql = @sql + ' inner join tp_tours with (nolock) on pt_tourkey = to_key and (TO_DateValidBegin IS NULL OR getdate() >= TO_DateValidBegin) AND (TO_DateValid IS NULL OR getdate() <= TO_DateValid)'
				
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

				exec dbo.mwCheckQuotesCycle ' + ltrim(str(@pagingType))+ ', ' + @spageNum + ', ' + @spageSize + ', ' + ltrim(str(@agentKey)) + ', ' + ltrim(str(@hotelQuotaMask)) + ', ' + ltrim(str(@aviaQuotaMask)) + ', ''' + @flightGroups + ''', ' + ltrim(str(@checkAgentQuota)) + ', ' + ltrim(str(@checkCommonQuota)) + ', ' + ltrim(str(@checkNoLongQuota)) + ', ' + ltrim(str(@requestOnRelease)) + ', ' + ltrim(str(@expiredReleaseResult)) + ', ' + ltrim(str(@noPlacesResult)) + ', ' + ltrim(str(@findFlight)) + ', 0, ''' + @tableName + '''

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

		declare @newpricesetting varchar(max)

		select @newpricesetting = rtrim(ltrim(SS_ParmValue)) from systemsettings where ss_parmname = 'NewReCalculatePrice'

		if isnull(@newpricesetting,'') = '1'
		begin

			SET QUOTED_IDENTIFIER OFF
		
			declare @tpPriceKeys nvarchar(4000)
			set @tpPriceKeys = ''
			-- запишем ключи tp_Price с которыми мы будем работать
			select @tpPriceKeys = @tpPriceKeys + convert(nvarchar(4000), ptpricekey) + ','
			from #Paging with(nolock)
		
			-- отправим запрос в основную базу и узнаем новое значение ключей
			--exec [mt].[avalon20120306main].[dbo].[ReCalculate_CheckActualPrice] @tpPriceKeys
			declare @dbName varchar(255)

			if ([dbo].[mwReplIsSubscriber]()=1) begin
				set @dbName = '[mt].'+ltrim(rtrim(dbo.mwReplPublisherDB()))+'.'
			end
			else begin
				set @dbName=''
			end
			
			set @tpPriceKeys = 'exec ' + @dbName + 'dbo.ReCalculate_CheckActualPrice ' + '''' + @tpPriceKeys + ''''
		
			declare @newPriceTable table
			(
				xTpKey bigint,
				xNewSummPrice money			
			)
			
			-- запишем результат в таблицу
			insert into @newPriceTable(xTpKey, xNewSummPrice)			
			exec (@tpPriceKeys)
				
			-- изменим цены в вебе, на те что к нам пришли, если пришли
			update #Paging
			set newPrice = convert(int, xNewSummPrice)
			from #Paging join @newPriceTable on xTpKey = ptpricekey
			where xNewSummPrice is not null
		
			-- удалим цены если они удалились в основной базе
			-- так делать нельзя потому что туры расчитанные по старой схеме удаляться
			if (exists (select top 1 1 from @newPriceTable where xNewSummPrice is null))
			begin
				delete #Paging
				where (	exists(select top 1 1 from @newPriceTable where xTpKey = ptpricekey and xNewSummPrice is null)
						or not exists (select top 1 1 from @newPriceTable where xTpKey = ptpricekey))
			end
		
			SET QUOTED_IDENTIFIER OFF

		end

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
		pt_pricekey,'
	if (@pagingType = 1)
	begin
		set @sql=@sql + 'pt_price,'
	end
	else
	begin
		set @sql=@sql + 'case when newPrice is not null then newPrice else pt_price end as pt_price,'
	end		
	set @sql=@sql + 'pt_hdkey,
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

	if (@pagingType = @ACTUALPLACES_PAGING)
	begin
		set @sql = @sql + '
		,[pt_smartSearch]
	'
	end

	if(@getServices > 0)
		set @sql=@sql + ',dbo.mwGetServiceClasses(pt_pricelistkey) pt_srvClasses'
	if (@pagingType <> @SIMPLE_PAGING)
	begin
		if(@hotelQuotaMask > 0)
			set @sql=@sql + ',pt_hdquota,pt_hdallquota '
		if(@aviaQuotaMask > 0)
			set @sql=@sql + ',pt_chtherequota,pt_chbackquota '
	end
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

		if(@pagingType=@SIMPLE_PAGING)
		begin
			set @sql=@sql + '
			select * from #resultsTable
			'
		end
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
Go

GRANT  exec ON [dbo].[Paging] TO PUBLIC
GO

/*********************************************************************/
/* end sp_Paging.sql */
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
	and (AddCostIsCommission_1 != xValueIsCommission
		or AddCostNoCommission_1 != xValueNoCommission)
	
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
	and (AddCostIsCommission_2 != xValueIsCommission
		or AddCostNoCommission_2 != xValueNoCommission)
	
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
	and (AddCostIsCommission_3 != xValueIsCommission
		or AddCostNoCommission_3 != xValueNoCommission)
	
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
	and (AddCostIsCommission_4 != xValueIsCommission
		or AddCostNoCommission_4 != xValueNoCommission)
	
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
	and (AddCostIsCommission_5 != xValueIsCommission
		or AddCostNoCommission_5 != xValueNoCommission)
	
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
	and (AddCostIsCommission_6 != xValueIsCommission
		or AddCostNoCommission_6 != xValueNoCommission)
	
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
	and (AddCostIsCommission_7 != xValueIsCommission
		or AddCostNoCommission_7 != xValueNoCommission)
	
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
	and (AddCostIsCommission_8 != xValueIsCommission
		or AddCostNoCommission_8 != xValueNoCommission)
	
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
	and (AddCostIsCommission_9 != xValueIsCommission
		or AddCostNoCommission_9 != xValueNoCommission)
	
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
	and (AddCostIsCommission_10 != xValueIsCommission
		or AddCostNoCommission_10 != xValueNoCommission)
	
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
	and (AddCostIsCommission_11 != xValueIsCommission
		or AddCostNoCommission_11 != xValueNoCommission)
	
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
	and (AddCostIsCommission_12 != xValueIsCommission
		or AddCostNoCommission_12 != xValueNoCommission)
	
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
	and (AddCostIsCommission_13 != xValueIsCommission
		or AddCostNoCommission_13 != xValueNoCommission)
	
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
	and (AddCostIsCommission_14 != xValueIsCommission
		or AddCostNoCommission_14 != xValueNoCommission)
	
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
	and (AddCostIsCommission_15 != xValueIsCommission
		or AddCostNoCommission_15 != xValueNoCommission)
	
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
/* begin sp_ReCalculateCosts.sql */
/*********************************************************************/
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculateCosts]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculateCosts]
GO
CREATE PROCEDURE [dbo].[ReCalculateCosts]
	(
		-- хранимка перерасчитывает услуги из очереди перерасчета
		--<version>2009.02.04</version>
		--<data>2012-02-22</data>
		@countReCalculateItems int,
		-- ключи тех записей которые нужно расчитать
		@xSCPIdTable nvarchar(max) = null
	)
AS
BEGIN
	SET ARITHABORT ON;
	SET DATEFIRST 1;
	set nocount on;
	
	declare @beginTime datetime
	set @beginTime = getDate()

	declare @tempGrossTable table
	(
		xSPADId int,
		xSPADGross money,
		xSPADNetto money,
		xSPADIsCommission bit
	)

	declare @svKey int, @code int, @code1 int, @code2 int, @prKey int, @packetKey int, @date datetime, @days int,
	@resRate varchar(2), @men int, @discountPercent decimal(14,2), @margin decimal(14,2), @marginType int,
	@sellDate dateTime, @netto decimal(14,2), @brutto decimal(14,2), @discount decimal(14,2),
	@nettoDetail varchar(100), @sBadRate varchar(2), @dtBadDate dateTime,
	@sDetailed varchar(100),  @nSPId int, @useDiscountDays int,
	@spadId int, @spadIsCommission bit,
	@tourKey int, @tourDate datetime, @tourDays int, @includeAddCost bit, @IsDuration smallint
	
	declare cursorReCalculateCosts cursor fast_forward read_only for
	select top (@countReCalculateItems) SC_SVKey, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, SCP_PKKey, SCP_Date, SCP_Days,
	SPAD_Rate, SCP_Men, 0, 0, 0,
	SPAD_SaleDate, 0, 0, 0,
	'', '', '' ,
	'', null, 0,
	SPAD_Id, SV_IsDuration, SCP_TourDays
	from TP_ServicePriceActualDate with(nolock) join TP_ServiceCalculateParametrs with(nolock) on SPAD_SCPId = SCP_Id
	join TP_ServiceComponents with(nolock) on SCP_SCId = SC_Id
	join [Service] on SC_SVKey = SV_Key
	where SPAD_SaleDate is null
	and SPAD_NeedApply = 1
	and ((@xSCPIdTable is null) or (SCP_Id in (select xt_key from dbo.ParseKeys(@xSCPIdTable))))

	open cursorReCalculateCosts
	fetch next from cursorReCalculateCosts into @svKey, @code, @code1, @code2, @prKey, @packetKey, @date, @days,
	@resRate, @men, @discountPercent, @margin, @marginType,
	@sellDate, @netto, @brutto, @discount,
	@nettoDetail, @sBadRate, @dtBadDate,
	@sDetailed,  @nSPId, @useDiscountDays,
	@spadId, @IsDuration, @tourDays
	
	print 'Открываем курсор: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	while (@@FETCH_STATUS = 0)
	begin
		
		set @netto = null;
		set @brutto = null;
		
		-- тут нам не нужно считать доплату, поэтому передаем фейковые значения
		set @tourKey = -100500
		set @tourDate = '1900-01-01'
		set @includeAddCost = 0
		
		-- если наща услуга без продолжительности то устанавливаем ей продолжительность равную продолжительности тура
		if (@IsDuration != 1)
		begin
			set @days = @tourDays
		end
		
		exec GetServiceCost @svKey, @code, @code1, @code2, @prKey, @packetKey, @date, @days,
		@resRate, @men, @discountPercent, @margin, @marginType,
		@sellDate, @netto output, @brutto output, @discount output,
		@nettoDetail output, @sBadRate output, @dtBadDate output,
		@sDetailed output,  @nSPId output, @useDiscountDays output,		
		@tourKey, @tourDate, @tourDays, @includeAddCost
		
		if (@discount is null)
			set @spadIsCommission = 0
		else
			set @spadIsCommission = 1
		
		/*после того как получили стоимость услуги запишем ее значение в о временную таблицу*/
		insert into @tempGrossTable (xSPADId, xSPADGross, xSPADNetto, xSPADIsCommission)
		values (@spadId, @brutto, @netto, @spadIsCommission)
						
		fetch next from cursorReCalculateCosts into @svKey, @code, @code1, @code2, @prKey, @packetKey, @date, @days,
		@resRate, @men, @discountPercent, @margin, @marginType,
		@sellDate, @netto, @brutto, @discount,
		@nettoDetail, @sBadRate, @dtBadDate,
		@sDetailed,  @nSPId, @useDiscountDays,
		@spadId, @IsDuration, @tourDays
	end
	close cursorReCalculateCosts
	deallocate cursorReCalculateCosts
	
	print 'Расчет цен: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	/*закончили расчет теперь обновим основную таблицу*/
	update TP_ServicePriceActualDate
	set SPAD_Gross = xSPADGross,
	SPAD_Netto = xSPADNetto,
	SPAD_IsCommission = xSPADIsCommission,
	SPAD_DateLastCalculate = getdate(),
	SPAD_NeedApply = 0
	from TP_ServicePriceActualDate join @tempGrossTable on xSPADId = SPAD_Id
		
	print 'Количество строк: ' + convert(nvarchar(max), @@rowcount)
	print 'Запись результата: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
END

GO
grant exec on [dbo].[ReCalculateCosts] to public
go
/*********************************************************************/
/* end sp_ReCalculateCosts.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculateCosts_GrossMigrate.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculateCosts_GrossMigrate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculateCosts_GrossMigrate]
GO
CREATE PROCEDURE [dbo].[ReCalculateCosts_GrossMigrate]
	(
		-- хранимка переносит цены из таблицы TP_PriceActualDate в TP_PriceComponents
		-- <version>2009.02.10</version>
		-- <data>2012-09-22</data>
		@countItems int,
		-- ключи тех записей которые нужно расчитать
		@xSCPIdTable nvarchar(max) = null,
		-- ключи тех записей которые нужно расчитать, если задан этот параметр, то SPAD_AutoOnline игнорируется
		@xOnlySCPIdTable nvarchar(max) = null,
		-- так же публиковать остальные цены по этому отелю, отличающихся от выбранной только комнатой, категорией и питанием
		-- работает только если задан параметр @xOnlySCPIdTable
		@xPublichAllRoomAllCategoryAllPansion bit = null,
		-- список продолжительностей цены на которые нужно опубликовать
		@xLongList nvarchar(max) = null
	)
AS
BEGIN
	set nocount on;
	declare @beginTime datetime
	set @beginTime = getDate()
	
	print '1: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	create table #tpServicePriceActualDateTable
	(
		SPAD_SCPId bigint,
		SPAD_Id bigint,
		SPAD_Gross money,
		SPAD_Rate nvarchar(2),
		SPAD_IsCommission bit,
		SPAD_AutoOnline int,
		SCP_DateCheckIn datetime,
		SCP_SvKey int
	)
	
	create index x_tpServicePriceActualDateTable on #tpServicePriceActualDateTable
	(
		SCP_DateCheckIn,
		SPAD_Rate,
		SPAD_SCPId,
		SCP_SvKey,
		SPAD_Gross
	) include (SPAD_Id, SPAD_IsCommission, SPAD_AutoOnline)
	
	if (@xOnlySCPIdTable is not null)
	begin
		-- этот кусок кода вызывается только из экранов "Маржинальный монитор" и "Перерасчет расчитанных цен"		
		-- поэтому перед публикацией нужно найти 
		if (isnull(@xPublichAllRoomAllCategoryAllPansion, 0) = 1)
		begin
			update TP_ServicePriceActualDate
			set SPAD_AutoOnline = 1
			from TP_ServicePriceActualDate as spad1 join TP_ServiceCalculateParametrs as scp1 with(nolock) on SPAD_SCPId = SCP_Id
			join TP_ServiceComponents as sc1 with(nolock) on SCP_SCId = SC_Id
			where SPAD_SaleDate is null
			and exists (	select top 1 1
							from TP_ServiceCalculateParametrs as scp2 with(nolock) join TP_ServiceComponents as sc2 with(nolock) on SCP_SCId = SC_Id
							where 
							scp2.SCP_Id in (select xt_key from dbo.ParseKeys(@xOnlySCPIdTable))
							and scp1.SCP_Date = scp2.SCP_Date
							and scp1.SCP_DateCheckIn = scp2.SCP_DateCheckIn
							and scp1.SCP_PKKey = scp2.SCP_PKKey
							and scp1.SCP_SvKey = scp2.SCP_SvKey
							and (@xLongList is null or (scp1.SCP_TourDays in (select xt_key from dbo.ParseKeys(@xLongList))))
							and sc1.SC_Code = sc2.SC_Code
							and sc1.SC_PRKey = sc2.SC_PRKey
							and sc1.SC_SVKey = sc2.SC_SVKey
							)
		end
	
		insert into #tpServicePriceActualDateTable (SPAD_SCPId, SPAD_Id, SPAD_Gross, SPAD_Rate, SPAD_IsCommission, SPAD_AutoOnline, SCP_DateCheckIn, SCP_SvKey)
		select top (@countItems) SPAD_SCPId, SPAD_Id, SPAD_Gross, SPAD_Rate, SPAD_IsCommission, SPAD_AutoOnline, SCP_DateCheckIn, SCP_SvKey
		from TP_ServicePriceActualDate with(nolock) join TP_ServiceCalculateParametrs with(nolock) on SPAD_SCPId = SCP_Id
		where SPAD_SaleDate is null
		and SPAD_NeedApply = 0
		and SCP_Id in (select xt_key from dbo.ParseKeys(@xOnlySCPIdTable))
		
		print '1.1: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
	end
	else if (@xSCPIdTable is not null)
	begin
		insert into #tpServicePriceActualDateTable (SPAD_SCPId, SPAD_Id, SPAD_Gross, SPAD_Rate, SPAD_IsCommission, SPAD_AutoOnline, SCP_DateCheckIn, SCP_SvKey)
		select top (@countItems) SPAD_SCPId, SPAD_Id, SPAD_Gross, SPAD_Rate, SPAD_IsCommission, SPAD_AutoOnline, SCP_DateCheckIn, SCP_SvKey
		from TP_ServicePriceActualDate with(nolock) join TP_ServiceCalculateParametrs with(nolock) on SPAD_SCPId = SCP_Id
		where SPAD_SaleDate is null
		and SPAD_NeedApply = 0
		and SPAD_AutoOnline = 1
		and SCP_Id in (select xt_key from dbo.ParseKeys(@xSCPIdTable))
		
		print '1.2: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
	end
	else
	begin
		insert into #tpServicePriceActualDateTable (SPAD_SCPId, SPAD_Id, SPAD_Gross, SPAD_Rate, SPAD_IsCommission, SPAD_AutoOnline, SCP_DateCheckIn, SCP_SvKey)
		select top (@countItems) SPAD_SCPId, SPAD_Id, SPAD_Gross, SPAD_Rate, SPAD_IsCommission, SPAD_AutoOnline, SCP_DateCheckIn, SCP_SvKey
		from TP_ServicePriceActualDate with(nolock) join TP_ServiceCalculateParametrs with(nolock) on SPAD_SCPId = SCP_Id
		where SPAD_SaleDate is null
		and SPAD_NeedApply = 0
		and SPAD_AutoOnline = 1
		
		print '1.3: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
		set @beginTime = getDate()
	end	
	
	print '2: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()

	declare @PriceComponentsRows int;
	set @PriceComponentsRows = 0;
		
	-- разобьем апдейт на 15 - по каждому картежу свой
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_1 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_1
	where SCP_SvKey = SvKey_1
	and isnull(SPAD_Gross, -100500) != isnull(Gross_1, -100500)
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_2 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_2
	where SCP_SvKey = SvKey_2
	and isnull(SPAD_Gross, -100500) != isnull(Gross_2, -100500)
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_3 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_3
	where SCP_SvKey = SvKey_3
	and isnull(SPAD_Gross, -100500) != isnull(Gross_3, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_4 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_4
	where SCP_SvKey = SvKey_4
	and isnull(SPAD_Gross, -100500) != isnull(Gross_4, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_5 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_5
	where SCP_SvKey = SvKey_5
	and isnull(SPAD_Gross, -100500) != isnull(Gross_5, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_6 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_6
	where SCP_SvKey = SvKey_6
	and isnull(SPAD_Gross, -100500) != isnull(Gross_6, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_7 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_7
	where SCP_SvKey = SvKey_7
	and isnull(SPAD_Gross, -100500) != isnull(Gross_7, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_8 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_8
	where SCP_SvKey = SvKey_8
	and isnull(SPAD_Gross, -100500) != isnull(Gross_8, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_9 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_9
	where SCP_SvKey = SvKey_9
	and isnull(SPAD_Gross, -100500) != isnull(Gross_9, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_10 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_10
	where SCP_SvKey = SvKey_10
	and isnull(SPAD_Gross, -100500) != isnull(Gross_10, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_11 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_11
	where SCP_SvKey = SvKey_11
	and isnull(SPAD_Gross, -100500) != isnull(Gross_11, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_12 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_12
	where SCP_SvKey = SvKey_12
	and isnull(SPAD_Gross, -100500) != isnull(Gross_12, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_13 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_13
	where SCP_SvKey = SvKey_13
	and isnull(SPAD_Gross, -100500) != isnull(Gross_13, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_14 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_14
	where SCP_SvKey = SvKey_14
	and isnull(SPAD_Gross, -100500) != isnull(Gross_14, -100500)
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	update TP_PriceComponents
	set 
	PC_DateLastChangeGross = getdate(), 
	PC_UpdateDate = getdate(),
	Gross_15 = SPAD_Gross,
	PC_State = 1
	from TP_PriceComponents join #tpServicePriceActualDateTable on SPAD_SCPId = SCPId_15
	where SCP_SvKey = SvKey_15
	and isnull(SPAD_Gross, -100500) != isnull(Gross_15, -100500)
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
	
	print '3: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
		
	print 'Количество строк в TP_PriceComponents: ' + convert(nvarchar(max), @PriceComponentsRows)
	
	/*обновим галку о необходимости переноса цены*/
	update TP_ServicePriceActualDate
	set SPAD_AutoOnline = 0
	where SPAD_Id in (select SPAD_Id from #tpServicePriceActualDateTable)
	
	print '4: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	print 'Количество строк в TP_ServicePriceActualDate: ' + convert(nvarchar(max), @@rowcount)
END

GO

grant exec on [dbo].[ReCalculateCosts_GrossMigrate] to public
go
/*********************************************************************/
/* end sp_ReCalculateCosts_GrossMigrate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculateCosts_MarginMigrate.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculateCosts_MarginMigrate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculateCosts_MarginMigrate]
GO
CREATE PROCEDURE [dbo].[ReCalculateCosts_MarginMigrate]
	(
		-- хранимка переносит цены из таблицы TP_PriceActualDate в TP_PriceComponents
		-- <version>2009.02.09</version>
		-- <data>2012-09-22</data>
		@countItems int,
		-- ключи записей из кеша которые нам нужно расчитать
		@xTMADIdTable nvarchar(max) = null
	)
AS
BEGIN
	SET ARITHABORT ON;
	SET DATEFIRST 1;
	set nocount on;
	
	declare @beginTime datetime
	set @beginTime = getDate()	
	
	/*таблица первоночальной выборки*/
	declare @tableForMigrate table
	(
		TMAD_Id int,
		TMAD_TRKey int,
		TMAD_DateCheckIn datetime,
		TMAD_SvKey int,
		TMAD_Long smallint,
		TMAD_Percent money,
		TMAD_IsCommission bit
	)
	
	insert into @tableForMigrate (TMAD_Id, TMAD_TRKey, TMAD_DateCheckIn, TMAD_SvKey, TMAD_Long, TMAD_Percent, TMAD_IsCommission)
	select top (@countItems) TMAD_Id, TMAD_TRKey, TMAD_DateCheckIn, TMAD_SvKey, TMAD_Long, TMAD_Percent, TMAD_IsCommission
	from TP_TourMarginActualDate with(nolock)
	where TMAD_NeedApply = 2
	and ((@xTMADIdTable is null) or (TMAD_Id in (select xt_key from dbo.ParseKeys(@xTMADIdTable))))
	
	print 'выборка записей из очереди: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	
	declare @PriceComponentsRows int; set @PriceComponentsRows=0;
	
	/*перенесем изменения в основную таблицу*/
	-- разобьем апдейт по кортежам
	
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_1 = TMAD_IsCommission,
		MarginPercent_1 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_1 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_2 = TMAD_IsCommission,
		MarginPercent_2 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_2 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_3 = TMAD_IsCommission,
		MarginPercent_3 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_3 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_4 = TMAD_IsCommission,
		MarginPercent_4 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_4 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_5 = TMAD_IsCommission,
		MarginPercent_5 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_5 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_6 = TMAD_IsCommission,
		MarginPercent_6 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_6 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_7 = TMAD_IsCommission,
		MarginPercent_7 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_7 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_8 = TMAD_IsCommission,
		MarginPercent_8 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_8 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_9 = TMAD_IsCommission,
		MarginPercent_9 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_9 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_10 = TMAD_IsCommission,
		MarginPercent_10 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_10 = TMAD_SvKey	
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_11 = TMAD_IsCommission,
		MarginPercent_11 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_11 = TMAD_SvKey		
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_12 = TMAD_IsCommission,
		MarginPercent_12 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_12 = TMAD_SvKey	
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_13 = TMAD_IsCommission,
		MarginPercent_13 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_13 = TMAD_SvKey	
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_14 = TMAD_IsCommission,
		MarginPercent_14 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_14 = TMAD_SvKey	
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;
			
	update TP_PriceComponents
	set	PC_DateLastChangeMargin = getdate(), 
		PC_UpdateDate = getdate(),
		CommissionOnly_15 = TMAD_IsCommission,
		MarginPercent_15 = TMAD_Percent,
		PC_State = 1
	from TP_PriceComponents join @tableForMigrate on PC_TRKey = TMAD_TRKey
	where PC_TourDate = TMAD_DateCheckIn
	and PC_Days = TMAD_Long
	and SVKey_15 = TMAD_SvKey
		
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	print 'Переносим записи: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()	

	print 'Количество строк в TP_PriceComponents: ' + convert(nvarchar(max), @PriceComponentsRows)
		
	/*обновим галку о необходимости переноса цены*/
	update TP_TourMarginActualDate
	set TMAD_NeedApply = 0
	where TMAD_Id in (select TMAD_Id from @tableForMigrate)
	print 'Количество строк в TP_TourMarginActualDate: ' + convert(nvarchar(max), @@rowcount)
END

GO

grant exec on [dbo].[ReCalculateCosts_MarginMigrate] to public
go
/*********************************************************************/
/* end sp_ReCalculateCosts_MarginMigrate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculateMargin.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculateMargin]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculateMargin]
GO
CREATE PROCEDURE [dbo].[ReCalculateMargin]
	(
		--Хранимка перерасчитывает наценки из очереди
		--<version>2009.2.04</version>
		--<data>2012-02-22</data>
		-- максимальное количество наценок для расчета за 1 запуск
		@countMargionItems int,
		-- ключи записей из кеша которые нам нужно расчитать
		@xTMADIdTable nvarchar(max) = null
	)
AS
BEGIN	
	declare @tempMarginTable table
	(
		xTMADId int,
		xMarginPercent money,
		xMarginIsCommission bit
	)	
	declare @TMADId int, @TrKey int, @Date datetime, @margin float, @marginType int, @svKey int, @days int, @sellDate dateTime, @packetKey int
	
	declare cursorReCalculateMargin cursor fast_forward read_only for
	select top (@countMargionItems) TMAD_Id, TMAD_TRKey, TMAD_DateCheckIn, 0, 0, TMAD_SvKey, TMAD_Long, '1900-01-01', 0
	from TP_TourMarginActualDate with(nolock)
	where TMAD_NeedApply=1
	and ((@xTMADIdTable is null) or (TMAD_Id in (select xt_key from dbo.ParseKeys(@xTMADIdTable))))
	
	open cursorReCalculateMargin
	fetch next from cursorReCalculateMargin into @TMADId, @TrKey, @Date, @margin, @marginType, @svKey, @days, @sellDate, @packetKey
	while (@@FETCH_STATUS = 0)
	begin
		exec GetTourMargin @TrKey, @Date, @margin output, @marginType output, @svKey, @days, @sellDate, @packetKey
		
		insert into @tempMarginTable (xTMADId, xMarginPercent, xMarginIsCommission)
		values (@TMADId, @margin, @marginType)
		
		fetch next from cursorReCalculateMargin into @TMADId, @TrKey, @Date, @margin, @marginType, @svKey, @days, @sellDate, @packetKey
	end
	close cursorReCalculateMargin
	deallocate cursorReCalculateMargin
	
	--теперь перенесем значения в таблицу
	update TP_TourMarginActualDate
	set TMAD_DateLastCalculate = getdate(),
	TMAD_NeedApply = 2,
	TMAD_Percent = xMarginPercent,
	TMAD_IsCommission = xMarginIsCommission
	from TP_TourMarginActualDate join @tempMarginTable on xTMADId = TMAD_Id
	print 'Количество строк в TP_TourMarginActualDate: ' + convert(nvarchar(max), @@rowcount)
END

GO
grant exec on [dbo].[ReCalculateMargin] to public
go
/*********************************************************************/
/* end sp_ReCalculateMargin.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculateNextCosts.sql */
/*********************************************************************/
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculateNextCosts]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculateNextCosts]
GO
CREATE PROCEDURE [dbo].[ReCalculateNextCosts]
	(
		-- хранимка перерасчитывает услуги из очереди перерасчета на будующие даты
		--<version>2009.02.01</version>
		--<data>2012-08-30</data>
		@countReCalculateItems int
	)
AS
BEGIN
	declare @tempGrossTable table
	(
		xSPADId int,
		xSPADGross money,
		xSPADNetto money,
		xSPADIsCommission bit
	)

	declare @svKey int, @code int, @code1 int, @code2 int, @prKey int, @packetKey int, @date datetime, @days int,
	@resRate varchar(2), @men int, @discountPercent decimal(14,2), @margin decimal(14,2), @marginType int,
	@sellDate dateTime, @netto decimal(14,2), @brutto decimal(14,2), @discount decimal(14,2),
	@nettoDetail varchar(100), @sBadRate varchar(2), @dtBadDate dateTime,
	@sDetailed varchar(100),  @nSPId int, @useDiscountDays int,
	@spadId int, @spadIsCommission bit,
	@tourKey int, @tourDate datetime, @tourDays int, @includeAddCost bit, @IsDuration smallint
	
	declare cursorReCalculateNextCosts cursor fast_forward read_only for
	select top (@countReCalculateItems) SC_SVKey, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, SCP_PKKey, SCP_Date, SCP_Days,
	SPND_Rate, SCP_Men, 0, 0, 0,
	SPND_SaleDate, 0, 0, 0,
	'', '', '' ,
	'', null, 0,
	SPND_Id, SV_IsDuration, SCP_TourDays
	from TP_ServicePriceNextDate with(nolock) join TP_ServiceCalculateParametrs with(nolock) on SPND_SCPId = SCP_Id
	join TP_ServiceComponents with(nolock) on SCP_SCId = SC_Id
	join [Service] on SC_SVKey = SV_Key
	where SPND_NeedApply = 1
	and SCP_DateCheckIn >= getdate()
	order by SPND_SaleDate, SCP_DateCheckIn

	open cursorReCalculateNextCosts
	fetch next from cursorReCalculateNextCosts into @svKey, @code, @code1, @code2, @prKey, @packetKey, @date, @days,
	@resRate, @men, @discountPercent, @margin, @marginType,
	@sellDate, @netto, @brutto, @discount,
	@nettoDetail, @sBadRate, @dtBadDate,
	@sDetailed,  @nSPId, @useDiscountDays,
	@spadId, @IsDuration, @tourDays
	
	while (@@FETCH_STATUS = 0)
	begin
		
		set @netto = null;
		set @brutto = null;
		
		-- тут нам не нужно считать доплату, поэтому передаем фейковые значения
		set @tourKey = -100500
		set @tourDate = '1900-01-01'
		set @includeAddCost = 0
		
		-- если наща услуга без продолжительности то устанавливаем ей продолжительность равную продолжительности тура
		if (@IsDuration != 1)
		begin
			set @days = @tourDays
		end
		
		exec GetServiceCost @svKey, @code, @code1, @code2, @prKey, @packetKey, @date, @days,
		@resRate, @men, @discountPercent, @margin, @marginType,
		@sellDate, @netto output, @brutto output, @discount output,
		@nettoDetail output, @sBadRate output, @dtBadDate output,
		@sDetailed output,  @nSPId output, @useDiscountDays output,		
		@tourKey, @tourDate, @tourDays, @includeAddCost
		
		if (@discount is null)
			set @spadIsCommission = 0
		else
			set @spadIsCommission = 1
		
		/*после того как получили стоимость услуги запишем ее значение в о временную таблицу*/
		insert into @tempGrossTable (xSPADId, xSPADGross, xSPADNetto, xSPADIsCommission)
		values (@spadId, @brutto, @netto, @spadIsCommission)
						
		fetch next from cursorReCalculateNextCosts into @svKey, @code, @code1, @code2, @prKey, @packetKey, @date, @days,
		@resRate, @men, @discountPercent, @margin, @marginType,
		@sellDate, @netto, @brutto, @discount,
		@nettoDetail, @sBadRate, @dtBadDate,
		@sDetailed,  @nSPId, @useDiscountDays,
		@spadId, @IsDuration, @tourDays
	end
	close cursorReCalculateNextCosts
	deallocate cursorReCalculateNextCosts
	
	/*закончили расчет теперь обновим основную таблицу*/
	update TP_ServicePriceNextDate
	set SPND_Gross = xSPADGross,
	SPND_Netto = xSPADNetto,
	SPND_IsCommission = xSPADIsCommission,
	SPND_DateLastCalculate = getdate(),
	SPND_NeedApply = 0
	from TP_ServicePriceNextDate join @tempGrossTable on xSPADId = SPND_Id
	
	print 'Количество строк: ' + convert(nvarchar(max), @@rowcount)
END

GO
grant exec on [dbo].[ReCalculateNextCosts] to public
go
/*********************************************************************/
/* end sp_ReCalculateNextCosts.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculateSaleDate.sql */
/*********************************************************************/
if exists ( select * from sys.objects where object_id = object_id(N'[dbo].[ReCalculateSaleDate]') and type in (N'P', N'PC') ) 
    drop procedure [dbo].[ReCalculateSaleDate]
go

create procedure [dbo].[ReCalculateSaleDate] 
	(
		-- хранимка переносит цены расчитанные на определенную дату, в текущие цены
		-- количество записей для переноса за раз
		@countItem int,
		-- для отладочных целей - указываем дату, которая будет считаться текущей
		@virtualCurrentDate datetime = null		
	)
as 
	if @virtualCurrentDate is null
	begin
		set @virtualCurrentDate = getdate()
	end
	
	declare @tempServicePriceNextDate table
	(
		xSPNDId bigint,
		xSCPId bigint,
		xIsCommission bit,
		xRate nvarchar(2),
		xGross money,
		xNetto money,
		xDateLastCalculate datetime,
		xNeedApply smallint
	)
	
	-- выгружаем цены которые нужно перенести
	insert into @tempServicePriceNextDate (xSPNDId, xSCPId, xIsCommission, xRate, xGross, xNetto, xDateLastCalculate, xNeedApply)
	select top (@countItem) SPND_Id, SPND_SCPId, SPND_IsCommission, SPND_Rate, SPND_Gross, SPND_Netto, SPND_DateLastCalculate, SPND_NeedApply
	from TP_ServicePriceNextDate
	where SPND_SaleDate <= @virtualCurrentDate
	
	-- обновим цены в основном кеше
	update TP_ServicePriceActualDate
	set 
	SPAD_Gross = xGross,
	SPAD_Netto = xNetto,
	SPAD_IsCommission = xIsCommission,
	SPAD_DateLastCalculate = xDateLastCalculate,
	-- перенесем признак расчета, если цена еще не успела пересчитаться то она пересчитается в основном потоке
	SPAD_NeedApply = xNeedApply,
	-- всегда публикуем такие цены
	SPAD_AutoOnline = 1,
	-- пометим дату последнего изменения
	SPAD_DateLastChange = @virtualCurrentDate
	from TP_ServicePriceActualDate join @tempServicePriceNextDate on SPAD_SCPId = xSCPId
	where SPAD_Rate = xRate
	
	-- удалим перенесенные цены
	delete TP_ServicePriceNextDate
	where exists (	select top 1 1
					from @tempServicePriceNextDate
					where xSPNDId = SPND_Id)
go

grant exec on [dbo].[ReCalculateSaleDate] to public
go

/*********************************************************************/
/* end sp_ReCalculateSaleDate.sql */
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
		exec dbo.ReCalculateAddCosts 100500, @trKeys, null
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
		from CostOffers join Seasons on CO_SeasonId = SN_Id
		join CostOfferServices on COS_COID = CO_Id
		join tbl_Costs on CS_COID = CO_Id
		where SN_IsActive = 1
		and isnull(CO_SaleDateBeg, '2000-01-01') between getdate() and dateadd(dd, @daysCount, getdate())
		-- ЦБ должен быть активен
		and CO_State = 1
		-- и опубликован
		and CO_DateLastPublish is not null
		group by CostOffers.CO_Id, CO_SaleDateBeg, CO_PKKey, COS_SVKEY, COS_CODE, CS_SUBCODE1, CS_SUBCODE2, CS_PKKEY, CS_PRKEY
		union
		select CostOffers.CO_Id, dateadd(day, 1, datediff(day, 0, CO_SaleDateEnd)) as crossDate, COS_SVKEY, COS_CODE, CS_SUBCODE1, CS_SUBCODE2, CS_PKKEY, CS_PRKEY
		from CostOffers join Seasons on CO_SeasonId = SN_Id
		join CostOfferServices on COS_COID = CO_Id
		join tbl_Costs on CS_COID = CO_Id
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
						from CostOfferCrossSaleDate
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
	from TP_ServiceComponents join TP_ServiceCalculateParametrs on SC_Id = SCP_SCId
	join TP_ServicePriceActualDate on SCP_Id = SPAD_SCPId and SPAD_SaleDate is null
	join @tempCostOfferCrossSaleDate on SC_SVKey = xSvKey 
										and SC_Code = xCode 
										and SC_SubCode1 = xSubCode1 
										and SC_SubCode2 = xSubCode2
										and SC_PRKey = xPRKey
										and SCP_PKKey = xPKKey
	where not exists (	select top 1 1
						from TP_ServicePriceNextDate
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
/* begin sp_ReCalculate_CreateServiceCalculateParametrs.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_CreateServiceCalculateParametrs]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_CreateServiceCalculateParametrs]
GO

CREATE PROCEDURE [dbo].[ReCalculate_CreateServiceCalculateParametrs]
	(
		-- хранимка создает структуру детализации цены по услугам
		--<data>2012-08-24</data>
		--<version>2009.02.05</version>
		@trKey int,
		@toKey int,
		@nSvkey int,
		@nCode int,
		@nSubcode1 int,
		@nSubcode2 int,
		@nPrkey int,
		@nDay int,
		@turdate datetime,
		@nMen int,
		@nServiceDays int,
		@nPacketkey int,
		@nTourDays int,
		@scId int output, -- ключ найденой записи в таблице TP_ServiceComponents
		@scpId int output -- ключ найденой записи в таблице TP_ServiceCalculateParametrs
	)
AS
BEGIN
	declare @stId bigint

	-- обнулим значение
	set @scId = null
	set @stId = null
	set @scpId = null

	-- проверим есть ли на запись в TP_Services записи в TP_ServiceComponents
	-- пробуем найти запись под нашу услугу
	set @scId = isnull((select top 1 SC_Id
						from TP_ServiceComponents with (nolock)
						where SC_SVKey = @nSvkey
						and SC_Code = @nCode
						and SC_SubCode1 = @nSubcode1
						and SC_SubCode2 = @nSubcode2
						and SC_PRKey = @nPrkey), null)
						
	-- если не нашли то добавим новую
	if (@scId is null)
	begin
		insert into TP_ServiceComponents (SC_SVKey, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey)
		values (@nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey)
		
		set @scId = SCOPE_IDENTITY()
	end
	
	-- проверим есть ли запись в таблице TP_ServiceTours
	set @stId = isnull((select top 1 ST_Id
						from TP_ServiceTours with (nolock)
						where ST_SVKey = @nSvkey
						and ST_SCId = @scId
						and ST_TRKey = @trKey
						and ST_TOKey = @toKey), null)
	if (@stId is null)
	begin
		insert into TP_ServiceTours (ST_SVKey, ST_SCId, ST_TRKey, ST_TOKey)
		values (@nSvkey, @scId, @trKey, @toKey)
		
		set @stId = SCOPE_IDENTITY()
	end
	
	-- проверим есть ли подходящая запись в таблице TP_ServiceCalculateParametrs
	set @scpId = isnull((	select top 1 SCP_Id
							from TP_ServiceCalculateParametrs with (nolock)
							where SCP_SCId = @scId
							and SCP_Date = dateAdd(dd, @nDay-1, @turdate)
							and SCP_DateCheckIn = @turdate
							and SCP_Men = @nMen
							and SCP_Days = @nServiceDays
							and SCP_TourDays = @nTourDays
							and SCP_PKKey = @nPacketkey
							and SCP_DeleteDate is null), null)
							
	-- если не нашли, то добавим новую
	if (@scpId is null)
	begin
		insert into TP_ServiceCalculateParametrs(SCP_SCId, SCP_Date, SCP_DateCheckIn, SCP_Men, SCP_Days, SCP_PKKey, SCP_TourDays, SCP_SvKey)
		values (@scId, dateAdd(dd, @nDay-1, @turdate), @turdate, @nMen, @nServiceDays, @nPacketkey, @nTourDays, @nSvkey)
		
		set @scpId = SCOPE_IDENTITY()
	end
	
	-- создадим вспомогательную таблицу
	if not exists(select top 1 1 from TP_TourParametrs where TP_TOKey = @toKey and TP_TourDays = @nTourDays and TP_DateCheckIn = @turdate)
	begin
		insert into TP_TourParametrs(TP_TOKey, TP_TourDays, TP_DateCheckIn)
		values (@toKey, @nTourDays, @turdate)
	end
END


GO
grant exec on [dbo].[ReCalculate_CreateServiceCalculateParametrs] to public
go
/*********************************************************************/
/* end sp_ReCalculate_CreateServiceCalculateParametrs.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_Delete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_Delete]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_Delete]
GO
CREATE PROCEDURE [dbo].[ReCalculate_Delete]
	(
		-- хранимка удаляет цены из TP_PricesComponents
		--<version>2009.2.02</version>
		--<data>2012-08-22</data>
		-- список ключей @pcIds для удаления цен
		@pcIds xml ([dbo].[ArrayOfLong]) = null
	)
AS
BEGIN	
	SET ARITHABORT ON;
	set nocount on;
	declare @beginTime datetime
	set @beginTime = getDate()
	
	declare @tempGrossTable table
	(
		xPCId int,
		xTPKey int,
		xToKey int
	)
	
	declare @tempPCId table
	(
		xPCId int
	)
	
	insert into @tempPCId (xPCId)
	select tbl.res.value('.', 'bigint') from @pcIds.nodes('/ArrayOfLong/long') as tbl(res)
	
	insert into @tempGrossTable (xPCId,  xTPKey, xToKey)
	select PC_Id, PC_TPKey, PC_TOKey
	from TP_PriceComponents with(nolock)
	where PC_Id in (select xPCId from @tempPCId)
	
	print 'Заполнение временной таблицы: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	declare currReCalculate_MigrateToPrice cursor for select distinct xToKey from @tempGrossTable
	declare @toKey int
	OPEN currReCalculate_MigrateToPrice
		FETCH NEXT FROM currReCalculate_MigrateToPrice INTO @toKey
		WHILE @@FETCH_STATUS = 0
		begin
	
			-- вставляем запись в CalculatingPriceLists
			insert into CalculatingPriceLists (CP_CreateDate,CP_PriceTourKey) values (GETDATE(),@toKey) 
			declare @cpKey int
			set @cpKey = scope_identity()
			
			print 'вставляем запись в CalculatingPriceLists' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
			set @beginTime = getDate()
			
			-- переносим цены в таблицу для удаленных цен
			insert into tp_pricesdeleted (TPD_TPKey, TPD_TOKey, TPD_TIKey, TPD_Gross, TPD_DateBegin, TPD_DateEnd, TPD_CalculatingKey)
			select TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, @cpKey 
			from tp_prices with(nolock)
			where tp_key in (	select xTPKey
								from @tempGrossTable
								where xToKey = @toKey)
								
			print 'переносим цены в таблицу для удаленных цен' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
			set @beginTime = getDate()
								
			-- удаляем цены из tp_prices
			delete from tp_prices
			where tp_key in (	select xTPKey
								from @tempgrosstable
								where xToKey = @toKey)
								
			print 'удаляем цены из tp_prices' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
			set @beginTime = getDate()
								
			-- удаляем из TP_PriceComponents
			delete TP_PriceComponents
			where PC_Id in (	select xPCId
								from @tempgrosstable
								where xToKey = @toKey)
								
			print 'удаляем из TP_PriceComponents' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
			set @beginTime = getDate()
								
			if exists (select top 1 1 from TP_Tours where to_Key = @toKey and to_isEnabled = 1)
			begin
				-- Реплицируем только если тур уже выставлен в online
				exec FillMasterWebSearchFields @toKey, @cpKey
				print 'Реплицируем только если тур уже выставлен в online' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
			set @beginTime = getDate()
			end
								
		FETCH NEXT FROM currReCalculate_MigrateToPrice INTO @toKey
		end

	CLOSE currReCalculate_MigrateToPrice
	DEALLOCATE currReCalculate_MigrateToPrice
END

GO
grant exec on [dbo].[ReCalculate_Delete] to public
go
/*********************************************************************/
/* end sp_ReCalculate_Delete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_MigrateToPrice.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_MigrateToPrice]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_MigrateToPrice]
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
			
			--восстанавливаем цены из таблицы удаленных цен
			insert into tp_prices (TP_Key, TP_TOKey, TP_TIKey, TP_Gross, TP_DateBegin, TP_DateEnd, TP_CalculatingKey)
			select TPD_TPKey, TPD_TOKey, TPD_TIKey, TPD_Gross, TPD_DateBegin, TPD_DateEnd, @cpKey
			from tp_pricesdeleted with(nolock)
			where tpd_tpkey in (select xTPKey
								from @tempgrosstable
								where xSummPrice is not null
								and xToKey = @toKey)
								
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
			
			if exists (select top 1 1 from TP_Tours where to_Key = @toKey and to_isEnabled = 1)
			begin
				-- Реплицируем только если тур уже выставлен в online
				exec FillMasterWebSearchFields @toKey, @cpKey
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

grant exec on [dbo].[ReCalculate_MigrateToPrice] to public
go
/*********************************************************************/
/* end sp_ReCalculate_MigrateToPrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_ViewHottelCost.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_ViewHotelCost]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_ViewHotelCost]
GO
CREATE PROCEDURE [dbo].[ReCalculate_ViewHotelCost]
(
	--хранимка выводит информацию о ценах на отель по набору заданных параметров, либо по ключам цен
	--<version>2009.2.08</version>
	--<data>2012-10-10</data>
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
		
		-- проверяем актуальность цен
		declare @tpKeys1 nvarchar(max)
		set @tpKeys1 = ''
		select @tpKeys1 = @tpKeys1 + convert(nvarchar(max), PC_TPKey) + ', '
		from TP_PriceComponents with(nolock)
		where PC_Id in (select xPriceKey from @tablePriceKeysTable)
		
		declare @result1 table(tpKey bigint,newPrice money)
        -- делаем инсерт во веременную таблицу, что бы результата не выводился при запуске этой хранимки
		insert into @result1 (tpKey, newPrice)
		exec ReCalculate_CheckActualPrice @tpKeys1
		
		-- здесь нужен distinct обязательно !
		insert into @hotelRoomsTable(SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY)
		select distinct SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY
		from tp_serviceComponents
		inner join hotelRooms on SC_SubCode1 = HR_KEY
		inner join tp_serviceCalculateParametrs on sc_id=scp_scid
		where
		(isnull(@isHideAccommodationWithAdult, 0) = 0 or (HR_ACKEY in (select AC_KEY from Accmdmentype where (isnull(AC_NADMAIN, 0) > 0) and (isnull(AC_NCHMAIN, 0) = 0) and (isnull(AC_NCHISINFMAIN, 0) = 0))))
		and tp_serviceCalculateParametrs.scp_id in
		(
			select scpid_1 as scpid from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_2  as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_3  as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_4  as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_5  as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_6  as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_7  as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_8  as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_9  as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_10 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_11 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_12 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_13 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_14 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
			union select scpid_15 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeysTable)
		)
		
		-- таблица с перелетами по нужный нам турам
		declare @chartersTable table
		(
			xIsForward bit,    -- 1-прямой перелет    0-обратный
			xTS_TOKey bigint,
			xCH_Key bigint,
			xTS_SubCode1 bigint,
			xTS_PKKey bigint,
			xTS_Days int,
			xTS_CityKeyFrom bigint,
			xTS_CityKeyTo bigint,
			xCharterDate datetime,
			xCH_PortCodeFrom varchar(4),
			xAS_Week varchar(7),
			xAS_TimeFrom datetime
		)
		
		-- берем прямые и обратные перелеты
		insert into @chartersTable
		(xIsForward, xTS_TOKey, xCH_Key, xTS_SubCode1, xTS_PKKey, xTS_Days, xTS_CityKeyFrom, xTS_CityKeyTo, xCharterDate, xCH_PortCodeFrom, xAS_Week, xAS_TimeFrom)
		select distinct
			case TS_Day when 1 then 1 else 0 end,
			TS_TOKey, TS_Code, TS_SubCode1, TS_OpPacketKey, TS_Days, TS_SubCode2, TS_CTKey,
			case TS_Day when 1 then PC_TourDate else PC_TourDate + PC_Days - 1 end,
			CH_PORTCODEFROM, AS_WEEK, AS_TIMEFROM
		from TP_PriceComponents
		join TP_Services on TS_TOKey = PC_TOKey
		join Charter ch on ch.CH_KEY = TS_Code
		join AirSeason air on air.AS_CHKEY = ch.CH_KEY
		where
		    PC_Id in (select xPriceKey from @tablePriceKeysTable) and
			(case TS_Day when 1 then PC_TourDate else PC_TourDate + PC_Days - 1 end) between air.AS_DATEFROM AND air.AS_DATETO and
		    (TS_SVKey = 1) and ((TS_Day = 1) or (TS_Day = PC_Days)) and  -- перелеты на первый или последний день
		    (AS_WEEK LIKE '%'+cast(datepart(weekday, (case TS_Day when 1 then PC_TourDate else PC_TourDate + PC_Days - 1 end))as varchar(1))+'%')
		
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
			xTS_Days int,
			xOrder int default 1
		)
		
		insert into @addChartersTable(xCHKey, xAddChKey, xAddFlight, xAddAirlineCode, xCharterDate, xTS_SubCode1, xTS_PKKey, xTS_Days)
		select distinct xCH_Key, CH_Key, CH_FLIGHT, CH_AIRLINECODE, xCharterDate, xTS_SubCode1, xTS_PKKey, xTS_Days
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
			(ISNULL(CS_Week, '') = '' or CS_Week LIKE '%'+cast(datepart(weekday, xCharterDate)as varchar(1))+'%') and
			(CS_Long is null or CS_LongMin is null or xTS_Days between CS_LongMin and CS_Long)
			
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
			xTS_Days int
		)

		-- все доп. перелеты соединяем через запятую в одну строку
		insert into @addChartersTableString(xCHKey, xCharterDate, xTS_SubCode1, xTS_PKKey, xTS_Days, xAddChKeyString)
		select distinct t1.xCHKey, t1.xCharterDate, t1.xTS_SubCode1, t1.xTS_PKKey, xTS_Days,
			(select xAddAirlineCode + xAddFlight + ', '
		     from @addChartersTable t2
		     where (t2.xCHKey = t1.xCHKey) and (t2.xCharterDate = t1.xCharterDate) and (t2.xTS_SubCode1 = t1.xTS_SubCode1) and (t2.xTS_PKKey = t1.xTS_PKKey)
		     order by xOrder asc, xAddAirlineCode + xAddFlight asc
		     for xml path(''))
		from @addChartersTable t1
		
		-- избавляемся от хвостовых запятых
		update @addChartersTableString
		set xAddChKeyString = LEFT(xAddChKeyString, LEN(xAddChKeyString) - 1)

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
		xAS_WEEK as AS_WEEK, xCH_PORTCODEFROM as CH_PORTCODEFROM,
		(select top 1 act.xAddChKeyString from @addChartersTableString act
		where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1) and (act.xTS_Days = xTS_Days))
		as CH_FLIGHT,
        xAS_TIMEFROM as AS_TIMEFROM,
		-- SeatsFree
		(select sum(qp.QP_Places - qp.QP_Busy)
		from QuotaDetails qd
		join QuotaParts qp on qp.QP_QDID = qd.QD_ID
		join QuotaObjects qo on qo.QO_QTID = qd.QD_QTID
		where (qo.QO_SVKey = 1) and (qo.QO_SubCode1 = xTS_SubCode1) and (qd.QD_Date = PC_TourDate) and (isnull(qp.QP_IsDeleted,0) = 0) and (isnull(qp.QP_AgentKey,0) = 0) and
			   qo.QO_Code in (select act.xAddChKey from @addChartersTable act
			                  where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1) and (act.xTS_Days = xTS_Days)))
		as SeatsFree,
		-- Cax
		(select sum(qp.QP_Places)
		from QuotaDetails qd
		join QuotaParts qp on qp.QP_QDID = qd.QD_ID
		join QuotaObjects qo on qo.QO_QTID = qd.QD_QTID
		where (qo.QO_SVKey = 1) and (qo.QO_SubCode1 = xTS_SubCode1) and (qd.QD_Date = PC_TourDate) and (isnull(qp.QP_IsDeleted,0) = 0) and (isnull(qp.QP_AgentKey,0) = 0) and
			   qo.QO_Code in (select act.xAddChKey from @addChartersTable act
			                  where (act.xCharterDate = PC_TourDate) and (act.xCHKey = xCH_Key) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1) and (act.xTS_Days = xTS_Days)))
		as Cax,
		-- SeatsFreeBackCharters
		(select sum(qp.QP_Places - qp.QP_Busy)
		from QuotaDetails qd
		join QuotaParts qp on qp.QP_QDID = qd.QD_ID
		join QuotaObjects qo on qo.QO_QTID = qd.QD_QTID
		where (qo.QO_SVKey = 1) and (qo.QO_SubCode1 = xTS_SubCode1) and (qd.QD_Date = PC_TourDate + PC_Days - 1) and (isnull(qp.QP_IsDeleted,0) = 0) and (isnull(qp.QP_AgentKey,0) = 0) and
			   qo.QO_Code in (select act.xAddChKey from @addChartersTable act
			                  where (act.xCharterDate = PC_TourDate + PC_Days - 1) and (act.xTS_PKKey = xTS_PKKey) and (act.xTS_SubCode1 = xTS_SubCode1) and
			                        (act.xCHKey = (select top 1 xCH_Key from @chartersTable
			                                       where xTS_TOKey = PC_TOKey and xIsForward = 0 and xCharterDate = PC_TourDate + PC_Days - 1))))
		as SeatsFreeBackCharters
		-- Commitment Level
		--(select cast(min(qd1.QD_Places) as float)
		--from QuotaDetails qd1
		--join QuotaObjects qo1 on qo1.QO_QTID = qd1.QD_QTID
		--where (qo1.QO_SVKey = 3) and (qo1.QO_Code = PC_HotelKey) and (qd1.QD_Type = 2) and (qd1.QD_Date between PC_TourDate and PC_TourDate + PC_Days - 1))
		--/
		--(select cast(min(qd1.QD_Places) as float)
		--from QuotaDetails qd1
		--join QuotaObjects qo1 on qo1.QO_QTID = qd1.QD_QTID
		--where (qo1.QO_SVKey = 3) and (qo1.QO_Code = PC_HotelKey) and (qd1.QD_Date between PC_TourDate and PC_TourDate + PC_Days - 1))
		--as CL,
		-- RoomsAll
		--(select min(qd1.QD_Places)
		--from QuotaDetails qd1
		--join QuotaObjects qo1 on qo1.QO_QTID = qd1.QD_QTID
		--where (qo1.QO_SVKey = 3) and (qo1.QO_Code = PC_HotelKey) and (qd1.QD_Date between PC_TourDate and PC_TourDate + PC_Days - 1))
		--as RoomsAll,
		-- RoomsSold
		--(select sum(qd1.QD_Busy)
		--from QuotaDetails qd1
		--join QuotaObjects qo1 on qo1.QO_QTID = qd1.QD_QTID
		--where (qo1.QO_SVKey = 3) and
		--		(@IsWholeHotel=1 or (qo1.QO_SubCode2 in (select distinct HR_RCKEY
		--												from TP_Lists
		--												inner join HotelRooms on HR_KEY = TI_FIRSTHRKEY
		--												where TI_TOKey = PC_TOKey)))
		--		and
		--		(qo1.QO_Code = PC_HotelKey) and
		--		(qd1.QD_Date between PC_TourDate and PC_TourDate + PC_Days - 1))
		--as RoomsSold,
		-- RoomsFree
		--(select min(qd1.QD_Places - qd1.QD_Busy)
		--from QuotaDetails qd1
		--join QuotaObjects qo1 on qo1.QO_QTID = qd1.QD_QTID
		--where (qo1.QO_SVKey = 3) and
		--		(@IsWholeHotel=1 or (qo1.QO_SubCode2 in (select distinct HR_RCKEY
		--												from TP_Lists
		--												inner join HotelRooms on HR_KEY = TI_FIRSTHRKEY
		--												where TI_TOKey = PC_TOKey)))
		--		and
		--		(qo1.QO_Code = PC_HotelKey) and
		--		(qd1.QD_Date between PC_TourDate and PC_TourDate + PC_Days - 1))
		--as RoomsFree,
		-- LoadPercent
		--(select ( (100.0 * cast(sum(qd1.QD_Busy) as float)) /
		--			cast(min(qd1.QD_Places) as float) )
		--from QuotaDetails qd1
		--join QuotaObjects qo1 on qo1.QO_QTID = qd1.QD_QTID
		--where (qo1.QO_SVKey = 3) and
		--		(@IsWholeHotel=1 or (qo1.QO_SubCode2 in (select distinct HR_RCKEY
		--												from TP_Lists
		--												inner join HotelRooms on HR_KEY = TI_FIRSTHRKEY
		--												where TI_TOKey = PC_TOKey)))
		--		and
		--		(qo1.QO_Code = PC_HotelKey) and
		--		(qd1.QD_Date between PC_TourDate and PC_TourDate + PC_Days - 1))
		--as LoadPercent
		-- StopSale
		--(SELECT TOP 1 'S' FROM StopSales ss
		--INNER JOIN QuotaObjects qo ON qo.QO_ID = ss.SS_QOID
		--WHERE ss.SS_IsDeleted IS NULL
		--	AND ss.SS_Date BETWEEN PC_TourDate AND PC_TourDate + PC_Days
		--	AND qo.QO_SVKey = 3
		--	AND qo.QO_Code = SC_Code
		--	AND (qo.QO_SubCode1 = 0 OR qo.QO_SubCode1 = HR_RMKEY)) as StopSale
		from TP_PriceComponents with(nolock)
		join TP_Tours with(nolock) on TO_Key = PC_TOKey
		join TP_ServiceCalculateParametrs with (nolock) on SCPId_1 = SCP_Id
		join @hotelRoomsTable on SCP_SCId = SC_Id
		join @chartersTable on xTS_TOKey = PC_TOKey
		where
			PC_Id in (select xPriceKey from @tablePriceKeysTable) and
			xIsForward = 1 and
			xCharterDate = PC_TourDate and
			xTS_TOKey = PC_TOKey
	end
	else
	begin
		SET ARITHABORT ON;
		SET DATEFIRST 1;
		set nocount on;
		
		declare @beginTime datetime
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
		
		declare @tpKeys nvarchar(max)
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
/* begin sp_SetServiceStatus.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetServiceStatus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetServiceStatus]
GO
CREATE PROCEDURE [dbo].[SetServiceStatus]
	(
		-- хранимка устанавливает статусы услуг в путевке в зависимости от статусов квотирования		
		--<version>2009.2.02</version>
		--<data>2012-10-15</data>
		@dg_key int -- ключ путевки
	)
AS
BEGIN
	declare @dlKey int

	declare setDogovorListStatusCursor cursor read_only fast_forward for
	select DL_Key
	from tbl_dogovorList join [service] on dl_svkey = sv_key
	where dl_dgkey = @dg_key
	and isnull(SV_QUOTED, 0) = 1
	
	open setDogovorListStatusCursor
	fetch next from setDogovorListStatusCursor into @dlKey
	while @@fetch_status = 0
	begin
		declare @newdlControl int
		set @newdlControl = null
		
		exec SetServiceStatusOK @dlKey, @newdlControl out
		
		fetch next from setDogovorListStatusCursor into @dlKey
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
/* begin sp_SPOListResults.sql */
/*********************************************************************/
--<VERSION>2009.2</VERSION>
--<DATE>2012-06-21</DATE>

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPOListResults]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SPOListResults]
GO

Create PROCEDURE [dbo].[SPOListResults] 
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

SELECT distinct top '+ @top +' sd_tourkey, SD_TOURCREATED into #tempSpoTable from MWSPoDataTable ' + @filter +' '+ @additionalQuery + ' ORDER BY SD_TOURCREATED DESC 

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

exec (@command)


go 

grant exec on SPOListResults to public 

go

/*********************************************************************/
/* end sp_SPOListResults.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SyncProtourQuotes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SyncProtourQuotes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SyncProtourQuotes]
GO
CREATE PROCEDURE [dbo].[SyncProtourQuotes]
(
	--<VERSION>2009.2.10</VERSION>
	--<DATA>02.10.2012</DATA>
	@hotelKey int = null,	-- ключ отеля
	@startDate datetime = null,		-- дата начала интервала, по которому изменялись квоты (для стопов передается null)
	@endDate datetime = null,		-- дата окончания интервала, по которому изменялись квоты (для стопов передается null)
	@quotesUpdate bit = null			-- признак того, что обновлять надо квоты (т.е. 1 - обновление квот, 0 - обновление стопов)
)
AS
BEGIN
	if (dbo.mwReplIsPublisher() = 0)
		return;
		
	declare @qtid int, @qoid int, @qdid int, @qdbusy int, @uskey int, @str nvarchar(max), @hdname varchar(100), @rcname varchar(100), @ss_allotmentAndCommitment int 
	
	if (@startDate is null)
		set @startDate = '1900-01-01'
	if (@endDate is null)
		set @endDate = '2099-12-01'
	
	set @str = 'Количество квот, полученное из ProTour меньше, чем число занятых мест. 
				Обновление информации в Мастер-Туре невозможно. Параметры квот:'
				
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
			if (@ptq_CommitmentTotal > 0 and @ptq_State <> 2)
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
								select @hdname = ISNULL(HD_Name,0) from HotelDictionary where HD_Key = @ptq_HotelKey
								select @rcname = ISNULL(RC_Name,0) from RoomsCategory where RC_key = @ptq_RoomCategoryKey
								set @str = @str + CHAR(13) + 'Партнер:' + convert(varchar(100),@ptq_PartnerKey) + CHAR(13) + 
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
				--if (@ptq_State=3 and exists(select 1 from systemsettings where ss_parmname='SYSExistsProtourQuotesHistory' and SS_ParmValue = convert(varchar(100), getdate(), 105))) 
				--begin
				--	if exists (select TOP 1 1
				--				from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
				--				inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
				--				where QT_PRKey = @ptq_PartnerKey
				--				and QO_SVKey = 3
				--				and QO_Code = @ptq_HotelKey
				--				and QO_SubCode1 = 0
				--				and QO_SubCode2 = @ptq_RoomCategoryKey
				--				and QD_Date = @ptq_Date
				--				and QT_ByRoom = 1
				--				and QD_Type = 2)
				--	begin
				--		select @qdid = QD_ID, @qdbusy = QD_Busy 
				--			from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
				--			inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
				--			where QT_PRKey = @ptq_PartnerKey
				--			and QO_SVKey = 3
				--			and QO_Code = @ptq_HotelKey
				--			and QO_SubCode1 = 0
				--			and QO_SubCode2 = @ptq_RoomCategoryKey
				--			and QD_Date = @ptq_Date
				--			and QT_ByRoom = 1
				--			and QD_Type = 2
								
				--		if (@qdbusy > @ptq_CommitmentTotal)
				--		begin
				--			select @hdname = ISNULL(HD_Name,0) from HotelDictionary where HD_Key = @ptq_HotelKey
				--			select @rcname = ISNULL(RC_Name,0) from RoomsCategory where RC_key = @ptq_RoomCategoryKey
				--			set @str = @str + CHAR(13) + 'Партнер:' + convert(varchar(100),@ptq_PartnerKey) + CHAR(13) + 
				--										'Отель:' + convert(varchar(100),@hdname) + '(' + convert(varchar(100),@ptq_HotelKey) + ')' + CHAR(13) +
				--										'Категория номера:' + convert(varchar(100),@rcname) + CHAR(13) + 
				--										'Дата:' + convert(varchar(100),@ptq_Date, 105) + CHAR(13)
				--			print @str
				--		end 
				--		else 
				--		begin
				--			update QuotaDetails set QD_Places = @ptq_CommitmentTotal where QD_ID = @qdid 
				--			update QuotaParts set QP_Places = @ptq_CommitmentTotal where QP_QDID = @qdid
				--			update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
				--		end 
				--	end
				--	else
				--	begin
				--		select @qtid = QT_ID, @qoid = QO_ID 
				--			from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
				--			inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
				--			where QT_PRKey = @ptq_PartnerKey
				--			and QO_SVKey = 3
				--			and QO_Code = @ptq_HotelKey
				--			and QO_SubCode1 = 0
				--			and QO_SubCode2 = @ptq_RoomCategoryKey
				--			and QT_ByRoom = 1
				--			and QD_Type = 2
								
				--		insert into QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
				--		values (@qtid, @ptq_Date, 2, @ptq_CommitmentTotal, 0, GETDATE(), ISNULL(@uskey,0)) 
				--		set @qdid = SCOPE_IDENTITY()
				
				--		insert into QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
				--		values (@qdid, @ptq_Date, @ptq_CommitmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0)
							
				--		update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
							
				--	end
				--end
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
			
			if (@ptq_AllotmentTotal > 0 and @ptq_State <> 2)
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
								select @hdname = ISNULL(HD_Name,0) from HotelDictionary where HD_Key = @ptq_HotelKey
								select @rcname = ISNULL(RC_Name,0) from RoomsCategory where RC_key = @ptq_RoomCategoryKey
								set @str = @str + CHAR(13) + 'Партнер:' + convert(varchar(100),@ptq_PartnerKey) + CHAR(13) + 
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
				--if (@ptq_State=3 and exists(select 1 from systemsettings where ss_parmname='SYSExistsProtourQuotesHistory' and SS_ParmValue = convert(varchar(100), getdate(), 105))) 
				--begin
				--	if exists (select TOP 1 1
				--				from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
				--				inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
				--				where QT_PRKey = @ptq_PartnerKey
				--				and QO_SVKey = 3
				--				and QO_Code = @ptq_HotelKey
				--				and QO_SubCode1 = 0
				--				and QO_SubCode2 = @ptq_RoomCategoryKey
				--				and QD_Date = @ptq_Date
				--				and QT_ByRoom = 1
				--				and QD_Type = 1)
				--	begin
				--		select @qdid = QD_ID, @qdbusy = QD_Busy 
				--			from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
				--			inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
				--			where QT_PRKey = @ptq_PartnerKey
				--			and QO_SVKey = 3
				--			and QO_Code = @ptq_HotelKey
				--			and QO_SubCode1 = 0
				--			and QO_SubCode2 = @ptq_RoomCategoryKey
				--			and QD_Date = @ptq_Date
				--			and QT_ByRoom = 1
				--			and QD_Type = 1
								
				--		if (@qdbusy > @ptq_AllotmentTotal)
				--		begin
				--			select @hdname = ISNULL(HD_Name,0) from HotelDictionary where HD_Key = @ptq_HotelKey
				--			select @rcname = ISNULL(RC_Name,0) from RoomsCategory where RC_key = @ptq_RoomCategoryKey
				--			set @str = @str + CHAR(13) + 'Партнер:' + convert(varchar(100),@ptq_PartnerKey) + CHAR(13) + 
				--										'Отель:' + convert(varchar(100),@hdname) + '(' + convert(varchar(100),@ptq_HotelKey) + ')' + CHAR(13) +
				--										'Категория номера:' + convert(varchar(100),@rcname) + CHAR(13) + 
				--										'Дата:' + convert(varchar(100),@ptq_Date, 105) + CHAR(13)
				--			print @str
				--		end 
				--		else 
				--		begin
				--			update QuotaDetails set QD_Places = @ptq_AllotmentTotal, QD_Release = @ptq_Release where QD_ID = @qdid 
				--			update QuotaParts set QP_Places = @ptq_AllotmentTotal where QP_QDID = @qdid
				--			update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
				--		end 
				--	end
				--	else
				--	begin
				--		select @qtid = QT_ID, @qoid = QO_ID 
				--			from Quotas with(nolock) inner join QuotaDetails with(nolock) on QT_ID = QD_QTID 
				--			inner join QuotaObjects with(nolock) on QT_ID = QO_QTID
				--			where QT_PRKey = @ptq_PartnerKey
				--			and QO_SVKey = 3
				--			and QO_Code = @ptq_HotelKey
				--			and QO_SubCode1 = 0
				--			and QO_SubCode2 = @ptq_RoomCategoryKey
				--			and QT_ByRoom = 1
				--			and QD_Type = 1
								
				--		insert into QuotaDetails (QD_QTID, QD_Date, QD_Type, QD_Release, QD_Places, QD_Busy, QD_CreateDate, QD_CreatorKey)
				--		values (@qtid, @ptq_Date, 1, @ptq_Release, @ptq_AllotmentTotal, 0, GETDATE(), ISNULL(@uskey,0)) 
				--		set @qdid = SCOPE_IDENTITY()
				
				--		insert into QuotaParts (QP_QDID, QP_Date, QP_Places, QP_Busy, QP_IsNotCheckIn, QP_Durations, QP_CreateDate, QP_CreatorKey, QP_Limit)
				--		values (@qdid, @ptq_Date, @ptq_AllotmentTotal, 0, 0, '', GETDATE(), ISNULL(@uskey,0), 0)
							
				--		update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
							
				--	end
				--end
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
			
			if (@ptq_CommitmentTotal <= 0 and @ptq_AllotmentTotal <= 0 and @ptq_State <> 2)
			begin
				update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
			end
		
			FETCH NEXT FROM qCur INTO @ptq_Id, @ptq_PartnerKey, @ptq_HotelKey, @ptq_RoomCategoryKey, @ptq_Date, @ptq_State, 
							@ptq_CommitmentTotal, @ptq_AllotmentTotal, @ptq_Release, @ptq_StopSale, @ptq_CancelStopSale
						
		END
		CLOSE qCur
		DEALLOCATE qCur	
		
		if (@str <> 'Количество квот, полученное из ProTour меньше, чем число занятых мест. 
				Обновление информации в Мастер-Туре невозможно. Параметры квот:')
		begin
			declare @bkid int
			-- отправка письма, если количество квот, полученное из ProTour меньше, чем число занятых мест
			insert into Blanks (BK_CreateDate, BK_UserKey) values (GETDATE(), ISNULL(@uskey,0))
			set @bkid = SCOPE_IDENTITY()
		
			insert into SendMail (SM_Text, SM_Date, SM_BKID, SM_Creator) values (@str, GETDATE(), @bkid, ISNULL(@uskey,0)) 
		end
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
			if (@ptq_CommitmentTotal = 1 and @ptq_AllotmentTotal = 1)
				set @ss_allotmentAndCommitment = 1
			else if (@ptq_AllotmentTotal = 1 and @ptq_CommitmentTotal = 0) 
				set @ss_allotmentAndCommitment = 0
			else 
				set @ss_allotmentAndCommitment = 1
				
			if ((@ptq_State = 1  or @ptq_State = 3) and @ptq_CancelStopSale = 0 and @ptq_State <> 2) -- 0 - добавление стопов, 1 - удаление стопов
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
						update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id					
				end
				else
				begin
					insert into QuotaObjects (QO_QTID, QO_SVKey, QO_Code, QO_SubCode1, QO_SubCode2)
					values (null, 3, @ptq_HotelKey, 0, @ptq_RoomCategoryKey)
					set @qoid = SCOPE_IDENTITY()
				end
				
				if (@ss_allotmentAndCommitment = 1)
				begin
					insert into StopSales(SS_QOID, SS_QDID, SS_PRKey, SS_Date, SS_AllotmentAndCommitment, SS_Comment, SS_CreateDate, SS_CreatorKey)
							values (@qoid, null, @ptq_PartnerKey, @ptq_Date, 1, '', GETDATE(), ISNULL(@uskey,0))
					
					update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
				end 
				else if (@ss_allotmentAndCommitment = 0)
				begin
					insert into StopSales(SS_QOID, SS_QDID, SS_PRKey, SS_Date, SS_AllotmentAndCommitment, SS_Comment, SS_CreateDate, SS_CreatorKey)
							values (@qoid, null, @ptq_PartnerKey, @ptq_Date, 0, '', GETDATE(), ISNULL(@uskey,0))
							
					update ProtourQuotes set PTQ_State = 2 where PTQ_Id = @ptq_Id
				end
				
				update QuotaObjects
						set QO_CTKEY = (select HD_CTKEY from HotelDictionary where HD_KEY = QO_Code)
						where QO_ID = @qoid
					
				update QuotaObjects
						set QO_CNKey = (select CT_CNKEY from CityDictionary where CT_KEY = QO_CTKey)
						where QO_CNKey is null
						and QO_CTKey is not null
						and QO_ID = @qoid
			end
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
/* begin sp_UpdateTpPriceComponentsFromAddCostsResult.sql */
/*********************************************************************/
if exists (select * from sys.objects where object_id = object_id(N'[dbo].[UpdateTpPriceComponentsFromAddCostsResult]') and type in (N'P', N'PC'))
drop procedure [dbo].[UpdateTpPriceComponentsFromAddCostsResult]
go

create procedure [dbo].[UpdateTpPriceComponentsFromAddCostsResult]
	-- хранимка переливает результаты расчета доплат из ReCalculateAddCostResults в TP_PricaComponents
as
begin
	--<VERSION>2009.2.16.3</VERSION>
	--<DATE>2012-10-11</DATE>
	declare @calculatingKey int
	
	-- записываем ключ расчета,
	-- нужен для того что бы удалить из очереди те записи которые мы уже перелили
	-- и переливать будем только по этому ключу
	-- (P.S. что бы не использовать временную таблицу)
	begin tran	
		select @calculatingKey = ID from Keys where KEY_TABLE = 'ReCalculateAddCostResults'
		
		if (@calculatingKey is null)
		begin
			set @calculatingKey = 0

			insert into Keys (KEY_TABLE, ID)
			values ('ReCalculateAddCostResults', @calculatingKey)
		end
		
		set @calculatingKey = @calculatingKey + 1
		
		update ReCalculateAddCostResults
		set ACR_CalculatingKey = @calculatingKey
		where ACR_CalculatingKey = 0
				
		update Keys
		set ID = @calculatingKey
		where KEY_TABLE = 'ReCalculateAddCostResults'
	commit tran
	
	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_1 = ACR_AddCostIsCommission,
		AddCostNoCommission_1 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_1 = ACR_ScpId
	where SVKey_1 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey
		
	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_2 = ACR_AddCostIsCommission,
		AddCostNoCommission_2 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_2 = ACR_ScpId
	where SVKey_2 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey
	
	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_3 = ACR_AddCostIsCommission,
		AddCostNoCommission_3 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_3 = ACR_ScpId
	where SVKey_3 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey
	
	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_4 = ACR_AddCostIsCommission,
		AddCostNoCommission_4 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_4 = ACR_ScpId
	where SVKey_4 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_5 = ACR_AddCostIsCommission,
		AddCostNoCommission_5 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_5 = ACR_ScpId
	where SVKey_5 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_6 = ACR_AddCostIsCommission,
		AddCostNoCommission_6 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_6 = ACR_ScpId
	where SVKey_6 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_7 = ACR_AddCostIsCommission,
		AddCostNoCommission_7 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_7 = ACR_ScpId
	where SVKey_7 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_8 = ACR_AddCostIsCommission,
		AddCostNoCommission_8 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_8 = ACR_ScpId
	where SVKey_8 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_9 = ACR_AddCostIsCommission,
		AddCostNoCommission_9 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_9 = ACR_ScpId
	where SVKey_9 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_10 = ACR_AddCostIsCommission,
		AddCostNoCommission_10 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_10 = ACR_ScpId
	where SVKey_10 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_11 = ACR_AddCostIsCommission,
		AddCostNoCommission_11 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_11 = ACR_ScpId
	where SVKey_11 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_12 = ACR_AddCostIsCommission,
		AddCostNoCommission_12 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_12 = ACR_ScpId
	where SVKey_12 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_13 = ACR_AddCostIsCommission,
		AddCostNoCommission_13 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_13 = ACR_ScpId
	where SVKey_13 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_14 = ACR_AddCostIsCommission,
		AddCostNoCommission_14 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_14 = ACR_ScpId
	where SVKey_14 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	update TP_PriceComponents
	set	PC_DateLastChangeAddCost = getdate(),
		PC_UpdateDate = getdate(),
		AddCostIsCommission_15 = ACR_AddCostIsCommission,
		AddCostNoCommission_15 = ACR_AddCostNoCommission,
		PC_State = 1
	from TP_PriceComponents join ReCalculateAddCostResults on SCPId_15 = ACR_ScpId
	where SVKey_15 = ACR_SvKey
	and PC_TRKey = ACR_TrKey
	and ACR_CalculatingKey = @calculatingKey

	-- очистим результаты, которые были перелиты в TP_PriceComponents
	delete ReCalculateAddCostResults where ACR_CalculatingKey = @calculatingKey
end
go

grant exec on [dbo].[UpdateTpPriceComponentsFromAddCostsResult] to public
go

/*********************************************************************/
/* end sp_UpdateTpPriceComponentsFromAddCostsResult.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_AddCostsReCalculate.sql */
/*********************************************************************/
if exists ( select  *
            from    sys.triggers
            where   object_id = object_id(N'[dbo].[T_AddCostsReCalculate]') ) 
    drop trigger [dbo].[T_AddCostsReCalculate]
GO

CREATE trigger [dbo].[T_AddCostsReCalculate] on [dbo].[AddCosts]
    after insert, update
as
	--<data>2012-08-23</data>
	--<version>2009.02.09</version>
begin
	-- делаем запись какая доплата изменилась
	insert into dbo.TP_QueueAddCosts(QAC_ADCId, QAC_TRKey)
	select ADC_Id, ADC_TLKey
	from inserted
end
GO
/*********************************************************************/
/* end T_AddCostsReCalculate.sql */
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
	--<data>2012-10-15</data>
	--<version>9.16.1</version>
begin
	-- активация, и деактивация только при изменении поля SO_State на 1 или 2
	if (	exists ( select top 1 1 from inserted where CO_State = 1 or CO_State = 2)
		and exists ( select top 1 1 from deleted) 
		and update(CO_State)
		)
	begin
		update spad
		set spad.SPAD_NeedApply = 1,
		spad.SPAD_DateLastChange = getdate()
		from (dbo.TP_ServicePriceActualDate as spad 
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
		update spnd
		set spnd.SPND_NeedApply = 1,
		spnd.SPND_DateLastChange = getdate()
		from (dbo.TP_ServicePriceNextDate as spnd 
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
	end	
		
	-- публикация, только при изменении поля CO_DateLastPublish и при 
	if (	exists ( select top 1 1 from inserted) 
		and exists ( select top 1 1 from deleted) 
		and update(CO_DateLastPublish)
		)
	begin
		update spad
		set spad.SPAD_AutoOnline = 1,
		spad.SPAD_DateLastChange = getdate()
		from (dbo.TP_ServicePriceActualDate as spad 
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
end

GO



/*********************************************************************/
/* end T_CostOffersReCalculate.sql */
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
		@ODG_LEADDEPARTMENT, @ODG_DupUserKey, @ODG_MainMen, @ODG_MainMenEMail, @ODG_MAINMENPHONE, @ODG_CodePartner, @ODG_Creator, @ODG_CTDepartureKey, @ODG_Payed,
		@NDG_Code, @NDG_Price, @NDG_Rate, @NDG_DiscountSum, @NDG_PartnerKey, @NDG_TRKey, @NDG_TurDate, @NDG_CTKEY, @NDG_NMEN, @NDG_NDAY, 
		@NDG_PPaymentDate, @NDG_PaymentDate, @NDG_RazmerP, @NDG_Procent, @NDG_Locked, @NDG_SOR_Code, @NDG_IsOutDoc, @NDG_VisaDate, @NDG_CauseDisc, @NDG_OWNER, 
		@NDG_LEADDEPARTMENT, @NDG_DupUserKey, @NDG_MainMen, @NDG_MainMenEMail, @NDG_MAINMENPHONE, @NDG_CodePartner, @NDG_Creator, @NDG_CTDepartureKey, @NDG_Payed
    END
  CLOSE cur_Dogovor
  DEALLOCATE cur_Dogovor
END
GO
/*********************************************************************/
/* end T_DogovorUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_mwInsertTour.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[mwInsertTour]'))
DROP TRIGGER [dbo].[mwInsertTour]
GO
create trigger [dbo].[mwInsertTour] on [dbo].[mwReplTours] for insert
as
begin
	--<VERSION>ALL</VERSION>
	--<DATE>2012-09-17</DATE>
	if dbo.mwReplIsSubscriber() > 0
	begin
		SELECT rt_tokey as trkey, RT_CalcKey as calcKey, rt_trkey as tlkey, rt_overwritePrices as overwritePrices 
		INTO #tmpKeys 
		FROM inserted

		declare replcur cursor fast_forward read_only for
		select trkey, calcKey, tlkey, overwritePrices from #tmpKeys

		declare @trkey int, @calcKey int, @tlkey int, @overwritePrices bit

		open replcur

		fetch next from replcur into @trkey, @calcKey, @tlkey, @overwritePrices
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
				else
				begin
					insert into [mwReplQueue]([rq_mode], [rq_tokey], [RQ_CalculatingKey], [RQ_OverwritePrices])
					values(2, @trkey, @calcKey, @overwritePrices)
				end
			end
			fetch next from replcur into @trkey, @calcKey, @tlkey, @overwritePrices
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
/* begin T_QuotaDetailsChange.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_QuotaDetailsChange]'))
DROP TRIGGER [dbo].[T_QuotaDetailsChange]
GO

CREATE TRIGGER [dbo].[T_QuotaDetailsChange]
ON [dbo].[QuotaDetails]
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2008.1.01.05</VERSION>
--<DATE>2012-07-04</DATE>
IF @@ROWCOUNT > 0
BEGIN
	DECLARE @QO_SVKey int, @QO_Code int, @QT_Id int, @QT_ByRoom bit, @QT_PRKey int, @QT_PrtDogsKey int, @QD_ID int,
			@OQD_Type smallint, @OQD_Date smalldatetime, @OQD_Places smallint, @OQD_Busy smallint, @OQD_Release smallint, @OQD_IsDeleted smallint,
			@NQD_Type smallint, @NQD_Date smalldatetime, @NQD_Places smallint, @NQD_Busy smallint, @NQD_Release smallint, @NQD_IsDeleted smallint
    DECLARE @sText_Old varchar(255), @sText_New varchar(255), @sHI_Text varchar(255)
    DECLARE @sMod varchar(3), @nDelCount int, @nInsCount int, @nHIID int

	SELECT @nDelCount = COUNT(*) FROM DELETED
	SELECT @nInsCount = COUNT(*) FROM INSERTED
	IF (@nDelCount = 0)
	BEGIN
		SET @sMod = 'INS'
		DECLARE cur_QuotaDetails CURSOR LOCAL FOR 
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, N.QD_ID,
					null, null, null, null, null, null,
					N.QD_Type, N.QD_Date, N.QD_Places, N.QD_Busy, N.QD_Release, N.QD_IsDeleted
			FROM	INSERTED N join dbo.Quotas on N.QD_QTID = QT_ID
	END
	ELSE IF (@nInsCount = 0)
	BEGIN
		SET @sMod = 'DEL'
		DECLARE cur_QuotaDetails CURSOR LOCAL FOR
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, O.QD_ID,
					O.QD_Type, O.QD_Date, O.QD_Places, O.QD_Busy, O.QD_Release, O.QD_IsDeleted,
					null, null, null, null, null, null
			FROM	DELETED O join dbo.Quotas on O.QD_QTID = QT_ID
	END
	ELSE 
	BEGIN
		SET @sMod = 'UPD'
		DECLARE cur_QuotaDetails CURSOR LOCAL FOR
			SELECT	QT_ID, QT_ByRoom, QT_PRKey, QT_PrtDogsKey, N.QD_ID,
					O.QD_Type, O.QD_Date, O.QD_Places, O.QD_Busy, O.QD_Release, O.QD_IsDeleted,
					N.QD_Type, N.QD_Date, N.QD_Places, N.QD_Busy, N.QD_Release, N.QD_IsDeleted
			FROM	DELETED O join dbo.Quotas on O.QD_QTID = QT_ID
					join INSERTED N on N.QD_QTID = QT_ID
	END

	OPEN cur_QuotaDetails
	FETCH NEXT FROM cur_QuotaDetails INTO @QT_Id, @QT_ByRoom, @QT_PRKey, @QT_PrtDogsKey, @QD_ID,
					@OQD_Type, @OQD_Date, @OQD_Places, @OQD_Busy, @OQD_Release, @OQD_IsDeleted,
					@NQD_Type, @NQD_Date, @NQD_Places, @NQD_Busy, @NQD_Release, @NQD_IsDeleted
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OQD_Type, 0) !=			ISNULL(@NQD_Type, 0) OR
			ISNULL(@OQD_Date, 0) !=			ISNULL(@NQD_Date, 0) OR
			ISNULL(@OQD_Places, 0) !=		ISNULL(@NQD_Places, 0) OR
			ISNULL(@OQD_Busy, 0) !=			ISNULL(@NQD_Busy, 0) OR
			ISNULL(@OQD_Release, 0) !=		ISNULL(@NQD_Release, 0) OR
			ISNULL(@OQD_IsDeleted, 0) !=	ISNULL(@NQD_IsDeleted, 0)
			)
		BEGIN
			------------Запись в историю--------------------------------------------------------------------
			If @QT_PRKey = 0
				Set @sHI_Text = 'All partners'
			Else
				Select @sHI_Text = PR_Name from Partners where PR_Key = @QT_PRKey
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

			EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 34,
							@nTypeCode = @QD_ID,
							@sMod = @sMod,
							@sText = @sText_New,
							@sRemark = @sHI_Text,
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = @QO_SVKey,
							@nCode = @QO_Code
			SET @sText_Old = ''
			SET @sText_New = ''
			
			-- 04-07-2012 karimbaeva если изменился тип квоты, то меняем статус квоты и в путевках, которые сидят в этой квоте
			if ISNULL(@OQD_Type, 0) != ISNULL(@NQD_Type, 0) and @sMod = 'UPD'
			begin	
				update ServiceByDate
								set SD_State = QD_Type
								from QuotaDetails with(nolock) join QuotaParts with(nolock) on QD_ID=QP_QDID 
								where SD_QPID=QP_ID and SD_State <> QD_Type and QD_ID = @QD_ID
			end
			
			--------Детализация--------------------------------------------------
			if ISNULL(@OQD_Type, 0) != ISNULL(@NQD_Type, 0)
			begin				
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34001, @OQD_Type, @NQD_Type, @OQD_Type, @NQD_Type, null, null, 0
			end
			if ISNULL(@OQD_Date, 0) != ISNULL(@NQD_Date, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34002, @OQD_Date, @NQD_Date, null, null, null, null, 0
			END
			if ISNULL(@OQD_Places, 0) != ISNULL(@NQD_Places, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34003, @OQD_Places, @NQD_Places, @OQD_Places, @NQD_Places, null, null, 0
			END
			if ISNULL(@OQD_Busy, 0) != ISNULL(@NQD_Busy, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34004, @OQD_Busy, @NQD_Busy, @OQD_Busy, @NQD_Busy, null, null, 0
			END
			if ISNULL(@OQD_Release, 0) != ISNULL(@NQD_Release, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34005, @OQD_Release, @NQD_Release, @OQD_Release, @NQD_Release, null, null, 0
			END
			if ISNULL(@OQD_IsDeleted, 0) != ISNULL(@NQD_IsDeleted, 0)
			BEGIN
				EXECUTE dbo.InsertHistoryDetail @nHIID, 34006, @OQD_IsDeleted, @NQD_IsDeleted, @OQD_IsDeleted, @NQD_IsDeleted, null, null, 0
			END
		END
		
		FETCH NEXT FROM cur_QuotaDetails INTO @QT_Id, @QT_ByRoom, @QT_PRKey, @QT_PrtDogsKey, @QD_ID,
					@OQD_Type, @OQD_Date, @OQD_Places, @OQD_Busy, @OQD_Release, @OQD_IsDeleted,
					@NQD_Type, @NQD_Date, @NQD_Places, @NQD_Busy, @NQD_Release, @NQD_IsDeleted
    END
	CLOSE cur_QuotaDetails
	DEALLOCATE cur_QuotaDetails
END
GO



/*********************************************************************/
/* end T_QuotaDetailsChange.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TSToServiceByDate.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_TSToServiceByDate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_TSToServiceByDate]
GO

CREATE TRIGGER [T_TSToServiceByDate]
   ON  [dbo].[TuristService]
   AFTER  INSERT,DELETE 
AS 
--<VERSION>2009.2.16.0</VERSION>
--<DATE>2012-10-24</DATE>
DECLARE @TUID int,@O_DLKey int,@O_TUKey int,@N_DLKey int,@N_TUKey int,
		@BestPlace int, @BestRL int, @nDelCount smallint, @nInsCount smallint

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED

-- Task 8984 24.10.2012 kolbeshkin
-- Перераспределение туристов по услугам, класс которых имеет признак "Индивидуальное бронирование":
-- в каждой услуге должно быть не более 1 туриста.
IF (@nDelCount = 0)
begin
	DECLARE @isIndividualService smallint
    DECLARE @newTU_DLKEY int
    DECLARE @DL_DGKEY int
    DECLARE @DL_SVKEY int
        
	DECLARE cur_individual CURSOR FOR 
    SELECT 	N.TU_IDKey,	N.TU_DLKey
    FROM	INSERTED N 
    OPEN cur_individual
    FETCH NEXT FROM cur_individual 
	INTO @TUID, @O_DLKey

	WHILE @@FETCH_STATUS = 0
	BEGIN
		select @isIndividualService = ISNULL(SV_IsIndividual, 0),@DL_SVKEY=DL_SVKEY,@DL_DGKEY=DL_DGKEY  
		from dbo.Service,dbo.Dogovorlist where DL_KEY = @O_DLKey and SV_Key = DL_SVKEY 
		if @isIndividualService > 0 and (select COUNT(*) from TuristService where TU_DLKEY = @O_DLKey) > 1
		begin
				set @newTU_DLKEY = (select top 1 DL_KEY from dbo.Dogovorlist where DL_DGKEY = @DL_DGKEY
					and DL_SVKEY = @DL_SVKEY and not exists (select 1 from TuristService where TU_DLKEY = DL_KEY))
				if @newTU_DLKEY is not null
					update TuristService set TU_DLKEY = @newTU_DLKEY where TU_IDKEY = @TUID
		end
		FETCH NEXT FROM cur_individual 
		INTO @TUID, @O_DLKey
	end
	CLOSE cur_individual
	DEALLOCATE cur_individual
end
set @TUID=null
set @O_DLKey=null
-- 

IF (@nInsCount = 0)
BEGIN
    DECLARE cur_T_TSToServiceByDate CURSOR FOR 
    SELECT 	O.TU_IDKey,
			O.TU_DLKey, O.TU_TUKey,
			null, null
    FROM DELETED O
END
ELSE IF (@nDelCount = 0)
BEGIN
    DECLARE cur_T_TSToServiceByDate CURSOR FOR 
    SELECT 	N.TU_IDKey,
			null, null,
			N.TU_DLKey, N.TU_TUKey
    FROM	INSERTED N 
END

OPEN cur_T_TSToServiceByDate
FETCH NEXT FROM cur_T_TSToServiceByDate 
	INTO @TUID, @O_DLKey, @O_TUKey, @N_DLKey, @N_TUKey
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @N_TUKey is not null
	BEGIN
		SET @BestRL = 0
		SET @BestPlace = 0
		SELECT @BestRL=Min(SD_RLID),@BestPlace=Max(SD_RPID) FROM ServiceByDate WHERE SD_DLKey=@N_DLKey and SD_TUKey is null
		If @BestRL is null
			UPDATE ServiceByDate SET SD_TUKey=@N_TUKey WHERE SD_DLKey=@N_DLKey and SD_RPID=@BestPlace and SD_RLID is null
		Else
		BEGIN
			SELECT @BestPlace=Max(SD_RPID) FROM ServiceByDate WHERE SD_DLKey=@N_DLKey and SD_RLID=@BestRL and SD_TUKey is null
			UPDATE ServiceByDate SET SD_TUKey=@N_TUKey WHERE SD_DLKey=@N_DLKey and SD_RPID=@BestPlace and SD_RLID=@BestRL
		END
	END
	ELSE IF @O_TUKey is not null
		UPDATE ServiceByDate SET SD_TUKey=null WHERE SD_DLKey=@O_DLKey AND SD_TUKey=@O_TUKey

	-- Golubinsky. 11.08.2012. 
	-- TFS 7219: бронирование авиаперелетов для инфантов: перелеты садятся на подтверждение вне квоты
	UPDATE ServiceByDate SET SD_State=3
	WHERE SD_DLKey = @N_DLKey
			AND SD_TUKey = @N_TUKey
			AND EXISTS (SELECT TOP 1 1 FROM tbl_DogovorList WHERE DL_KEY = SD_DLKey AND DL_SVKEY = 1)
			AND EXISTS (SELECT TOP 1 1 FROM tbl_Turist WHERE TU_KEY = SD_TUKey AND TU_SEX=3)

	FETCH NEXT FROM cur_T_TSToServiceByDate
		INTO @TUID, @O_DLKey, @O_TUKey, @N_DLKey, @N_TUKey
END
CLOSE cur_T_TSToServiceByDate
DEALLOCATE cur_T_TSToServiceByDate
GO
/*********************************************************************/
/* end T_TSToServiceByDate.sql */
/*********************************************************************/
update [dbo].[setting] set st_version = '9.2.16.34236', st_moduledate = convert(datetime, '2012-11-27', 120),  st_financeversion = '9.2.16.34236', st_financedate = convert(datetime, '2012-11-27', 120) 
 GO
 UPDATE dbo.SystemSettings SET SS_ParmValue='2012-11-27' WHERE SS_ParmName='SYSScriptDate'
 GO