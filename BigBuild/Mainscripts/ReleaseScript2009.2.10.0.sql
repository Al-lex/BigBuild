/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%% Дата формирования: 11.11.2011 18:38 Для поисковой: False %%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*********************************************************************/
/* begin AlterTable_TPFlights.sql */
/*********************************************************************/
if not exists(select id from syscolumns where id = OBJECT_ID('TP_Flights') and name = 'TF_TourDate')
	alter table dbo.TP_Flights add TF_TourDate DateTime null
go
/*********************************************************************/
/* end AlterTable_TPFlights.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.04.22)Update_PrtBonuses.sql */
/*********************************************************************/
-- выравниваем состояние в таблицах с бонусами
UPDATE	dbo.PrtBonuses
SET	PB_TotalRating = (SELECT SUM(isnull(PBD_Rating, 0)) FROM dbo.PrtBonusDetails WHERE PBD_PBId = PB_ID),
PB_TotalBonus = (SELECT SUM(isnull(PBD_Bonus, 0)) FROM dbo.PrtBonusDetails WHERE PBD_PBId = PB_ID),
PB_TotalExpense = (SELECT SUM(isnull(PBD_Expense, 0)) FROM dbo.PrtBonusDetails WHERE PBD_PBId = PB_ID)
GO
/*********************************************************************/
/* end (11.04.22)Update_PrtBonuses.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.04.22)UpdateQuotaPartsAndQuotaDetails.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end (11.04.22)UpdateQuotaPartsAndQuotaDetails.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.04.28)Create_Table_Calendar.sql */
/*********************************************************************/
--***************************************Calendars Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Calendars]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[Calendars](
		[CL_Key] [int] IDENTITY(1,1) NOT NULL,
		[CL_DateFrom] [datetime] NULL,
		[CL_DateTo] [datetime] NULL,
		[CL_Comment] [varchar](255) NULL,
	PRIMARY KEY CLUSTERED 
	(
		[CL_Key] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
end
GO
grant select, insert, update, delete on [dbo].[Calendars] to public
go
--***************************************CalendarEventTypes Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalendarEventTypes]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[CalendarEventTypes](
		[CET_Key] [int] IDENTITY(1,1) NOT NULL,
		[CET_Name] [varchar](50) NOT NULL,
		[CET_NameLat] [varchar](50) NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[CET_Key] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
end
GO
grant select, insert, update, delete on [dbo].[CalendarEventTypes] to public
go
if not exists (select 1 from CalendarEventTypes where CET_Name = 'Выходной')
	insert into CalendarEventTypes (CET_Name, CET_NameLat) values ('Выходной', '')
if not exists (select 1 from CalendarEventTypes where CET_Name = 'Прием')
	insert into CalendarEventTypes (CET_Name, CET_NameLat) values ('Прием', '')
if not exists (select 1 from CalendarEventTypes where CET_Name = 'Выдача')
	insert into CalendarEventTypes (CET_Name, CET_NameLat) values ('Выдача', '')
GO
--***************************************CalendarWeekDays Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalendarWeekDays]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[CalendarWeekDays](
		[CWD_Key] [int] IDENTITY(1,1) NOT NULL,
		[CWD_WeekDayNumber] [int] NOT NULL,
		[CWD_WeekDayNameRus] [varchar](30) NOT NULL,
		[CWD_WeekDayNameLat] [varchar](30) NULL,
	PRIMARY KEY CLUSTERED 
	(
		[CWD_Key] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
end
GO

set identity_insert CalendarWeekDays on

if not exists (select 1 from CalendarWeekDays where CWD_WeekDayNameRus = 'Понедельник')
	insert into CalendarWeekDays (CWD_Key, CWD_WeekDayNumber, CWD_WeekDayNameRus, CWD_WeekDayNameLat) 
	values (1,1,'Понедельник','Monday')
if not exists (select 1 from CalendarWeekDays where CWD_WeekDayNameRus = 'Вторник')
	insert into CalendarWeekDays (CWD_Key, CWD_WeekDayNumber, CWD_WeekDayNameRus, CWD_WeekDayNameLat) 
	values (2,2,'Вторник','Tuesday')
if not exists (select 1 from CalendarWeekDays where CWD_WeekDayNameRus = 'Среда')
	insert into CalendarWeekDays (CWD_Key, CWD_WeekDayNumber, CWD_WeekDayNameRus, CWD_WeekDayNameLat) 
	values (3,3,'Среда','Wednesday')
if not exists (select 1 from CalendarWeekDays where CWD_WeekDayNameRus = 'Четверг')
	insert into CalendarWeekDays (CWD_Key, CWD_WeekDayNumber, CWD_WeekDayNameRus, CWD_WeekDayNameLat) 
	values (4,4,'Четверг','Thursday')
if not exists (select 1 from CalendarWeekDays where CWD_WeekDayNameRus = 'Пятница')
	insert into CalendarWeekDays (CWD_Key, CWD_WeekDayNumber, CWD_WeekDayNameRus, CWD_WeekDayNameLat) 
	values (5,5,'Пятница','Friday')
if not exists (select 1 from CalendarWeekDays where CWD_WeekDayNameRus = 'Суббота')
	insert into CalendarWeekDays (CWD_Key, CWD_WeekDayNumber, CWD_WeekDayNameRus, CWD_WeekDayNameLat) 
	values (6,6,'Суббота','Saturday')
if not exists (select 1 from CalendarWeekDays where CWD_WeekDayNameRus = 'Воскресенье')
	insert into CalendarWeekDays (CWD_Key, CWD_WeekDayNumber, CWD_WeekDayNameRus, CWD_WeekDayNameLat) 
	values (7,7,'Воскресенье','Sunday')

set identity_insert CalendarWeekDays off

GO

grant select, insert, update, delete on [dbo].[CalendarWeekDays] to public
go
--***************************************Schedules Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Schedules]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[Schedules](
		[SC_Key] [int] IDENTITY(1,1) NOT NULL,
		[SC_CalendarWeekDaysKey] [int] NULL,
		[SC_CalendarEventTypeKey] [int] NOT NULL,
		[SC_CalendarKey] [int] NULL
	PRIMARY KEY CLUSTERED 
	(
		[SC_Key] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[Schedules]  WITH CHECK ADD  CONSTRAINT [FK_Schedules_Calendars] FOREIGN KEY([SC_CalendarKey])
	REFERENCES [dbo].[Calendars] ([CL_Key])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[Schedules] CHECK CONSTRAINT [FK_Schedules_Calendars]

	ALTER TABLE [dbo].[Schedules]  WITH CHECK ADD  CONSTRAINT [FK_Schedules_CalendarEventTypes] FOREIGN KEY([SC_CalendarEventTypeKey])
	REFERENCES [dbo].[CalendarEventTypes] ([CET_KEY])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[Schedules] CHECK CONSTRAINT [FK_Schedules_CalendarEventTypes]

	ALTER TABLE [dbo].[Schedules]  WITH CHECK ADD  CONSTRAINT [FK_Schedules_CalendarWeekDays] FOREIGN KEY([SC_CalendarWeekDaysKey])
	REFERENCES [dbo].[CalendarWeekDays] ([CWD_KEY])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[Schedules] CHECK CONSTRAINT [FK_Schedules_CalendarWeekDays]
end

grant select, insert, update, delete on [dbo].[Schedules] to public
go
--***************************************CalendarDates Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalendarDates]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[CalendarDates](
		[CD_Key] [int] IDENTITY(1,1) NOT NULL,
		[CD_Date] [datetime] NOT NULL,
		[CD_CalendarKey] [int] NOT NULL,
	 CONSTRAINT [PK__Calendar__9C4D74596D8F833D] PRIMARY KEY CLUSTERED 
	(
		[CD_Key] ASC
	)
	) ON [PRIMARY]

	ALTER TABLE [dbo].[CalendarDates]  WITH CHECK ADD  CONSTRAINT [FK_CalendarDates_Calendars] FOREIGN KEY([CD_CalendarKey])
	REFERENCES [dbo].[Calendars] ([CL_Key])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[CalendarDates] CHECK CONSTRAINT [FK_CalendarDates_Calendars]
end
GO
grant select, insert, update, delete on [dbo].[CalendarDates] to public
go
--***************************************PartnerCalendarLinkers Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PartnerCalendarLinkers]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[PartnerCalendarLinkers](
		[PCL_Key] [int] IDENTITY(1,1) NOT NULL,
		[PCL_PartnerKey] [int] NOT NULL,
		[PCL_CalendarKey] [int] NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[PCL_Key] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[PartnerCalendarLinkers]  WITH CHECK ADD  CONSTRAINT [FK_PartnerCalendarLinkers_Calendars] FOREIGN KEY([PCL_CalendarKey])
	REFERENCES [dbo].[Calendars] ([CL_Key])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[PartnerCalendarLinkers] CHECK CONSTRAINT [FK_PartnerCalendarLinkers_Calendars]

	ALTER TABLE [dbo].[PartnerCalendarLinkers]  WITH CHECK ADD  CONSTRAINT [FK_PartnerCalendarLinkers_tbl_Partners] FOREIGN KEY([PCL_PartnerKey])
	REFERENCES [dbo].[tbl_Partners] ([PR_KEY])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[PartnerCalendarLinkers] CHECK CONSTRAINT [FK_PartnerCalendarLinkers_tbl_Partners]
end
go
grant select, insert, update, delete on [dbo].[PartnerCalendarLinkers] to public
go

--***************************************CalendarExclusions Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalendarExclusions]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[CalendarExclusions](
		[CE_Key] [int] IDENTITY(1,1) NOT NULL,
		[CE_CalendarKey] [int] NOT NULL,
		[CE_Date] [datetime] NOT NULL,
		[CE_Comment] [varchar](255) NULL,
	 CONSTRAINT [PK__Calendar__95FDF390780D11B0] PRIMARY KEY CLUSTERED 
	(
		[CE_Key] ASC
	)
	) ON [PRIMARY]

	ALTER TABLE [dbo].[CalendarExclusions]  WITH CHECK ADD  CONSTRAINT [FK_CalendarExclusions_Calendars] FOREIGN KEY([CE_CalendarKey])
	REFERENCES [dbo].[Calendars] ([CL_Key])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[CalendarExclusions] CHECK CONSTRAINT [FK_CalendarExclusions_Calendars]
end
GO
grant select, insert, update, delete on [dbo].[CalendarExclusions] to public
go
--***************************************CalendarDateEvents Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalendarDateEvents]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[CalendarDateEvents](
		[CDE_Key] [int] IDENTITY(1,1) NOT NULL,
		[CDE_CalendarDateKey] [int] NOT NULL,
		[CDE_CalendarEventTypeKey] [int] NOT NULL,
		[CDE_Comment] [varchar](255) NULL,
	 CONSTRAINT [PK__Calendar__A1772EEF7CD1C6CD] PRIMARY KEY CLUSTERED 
	(
		[CDE_Key] ASC,
		[CDE_CalendarDateKey] ASC,
		[CDE_CalendarEventTypeKey] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[CalendarDateEvents]  WITH CHECK ADD  CONSTRAINT [FK_CalendarDateEvents_CalendarDates] FOREIGN KEY([CDE_CalendarDateKey])
	REFERENCES [dbo].[CalendarDates] ([CD_Key])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[CalendarDateEvents] CHECK CONSTRAINT [FK_CalendarDateEvents_CalendarDates]

	ALTER TABLE [dbo].[CalendarDateEvents]  WITH CHECK ADD  CONSTRAINT [FK_CalendarDateEvents_CalendarEventTypes] FOREIGN KEY([CDE_CalendarEventTypeKey])
	REFERENCES [dbo].[CalendarEventTypes] ([CET_Key])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[CalendarDateEvents] CHECK CONSTRAINT [FK_CalendarDateEvents_CalendarEventTypes]
end
GO
grant select, insert, update, delete on [dbo].[CalendarDateEvents] to public
go
--***************************************CalendarExclusionsEvent Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalendarExclusionsEvent]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[CalendarExclusionsEvent](
		[CEE_CEKey] [int] NOT NULL,
		[CEE_CETKey] [int] NOT NULL,
	 CONSTRAINT [PK_CalendarExclusionsEvent_1] PRIMARY KEY CLUSTERED 
	(
		[CEE_CEKey] ASC,
		[CEE_CETKey] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[CalendarExclusionsEvent]  WITH CHECK ADD  CONSTRAINT [FK_CalendarExclusionsEvent_CalendarEventTypes] FOREIGN KEY([CEE_CETKey])
	REFERENCES [dbo].[CalendarEventTypes] ([CET_Key])

	ALTER TABLE [dbo].[CalendarExclusionsEvent] CHECK CONSTRAINT [FK_CalendarExclusionsEvent_CalendarEventTypes]

	ALTER TABLE [dbo].[CalendarExclusionsEvent]  WITH CHECK ADD  CONSTRAINT [FK_CalendarExclusionsEvent_CalendarExclusions] FOREIGN KEY([CEE_CEKey])
	REFERENCES [dbo].[CalendarExclusions] ([CE_Key])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[CalendarExclusionsEvent] CHECK CONSTRAINT [FK_CalendarExclusionsEvent_CalendarExclusions]
end
GO
grant select, insert, update, delete on [dbo].[CalendarExclusionsEvent] to public
go
--***************************************CalendarRegion Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalendarRegion]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[CalendarRegion](
		[CR_Key] [int] IDENTITY(1,1) NOT NULL,
		[CR_CLKey] [int] NOT NULL,
		[CR_CTKey] [int] NOT NULL,
		[CR_AddDay] [int] NOT NULL,
	 CONSTRAINT [PK_CalendarRegion] PRIMARY KEY CLUSTERED 
	(
		[CR_Key] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[CalendarRegion]  WITH CHECK ADD  CONSTRAINT [FK_CalendarRegion_Calendars] FOREIGN KEY([CR_CLKey])
	REFERENCES [dbo].[Calendars] ([CL_Key])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[CalendarRegion] CHECK CONSTRAINT [FK_CalendarRegion_Calendars]

	ALTER TABLE [dbo].[CalendarRegion]  WITH CHECK ADD  CONSTRAINT [FK_CalendarRegion_CityDictionary] FOREIGN KEY([CR_CTKey])
	REFERENCES [dbo].[CityDictionary] ([CT_KEY])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[CalendarRegion] CHECK CONSTRAINT [FK_CalendarRegion_CityDictionary]
end
GO
grant select, insert, update, delete on [dbo].[CalendarRegion] to public
go
--***************************************CalendarDeadLines Table**********************************************************************
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalendarDeadLines]') AND type in (N'U'))
begin
	CREATE TABLE [dbo].[CalendarDeadLines](
		[CD_Id] [int] IDENTITY(1,1) NOT NULL,
		[CD_CLKey] [int] NOT NULL,
		[CD_CTKey] [int] NOT NULL,
		[CD_SLKey] [int] NOT NULL,
		[CD_ArrivalDate] [datetime] NOT NULL,
		[CD_DeadLineConsulateDate] [datetime] NOT NULL,
		[CD_DeltaAgencyDate] [int] NOT NULL,
		[CD_DeadLineAgencyDate] AS dateadd(day, -CD_DeltaAgencyDate, CD_DeadLineConsulateDate),
		[CD_Description] [nvarchar](max) NULL,
	 CONSTRAINT [PK_CalendarDeadLines] PRIMARY KEY CLUSTERED 
	(
		[CD_Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[CalendarDeadLines]  WITH CHECK ADD  CONSTRAINT [FK_CalendarDeadLines_Calendars] FOREIGN KEY([CD_CLKey])
	REFERENCES [dbo].[Calendars] ([CL_Key])

	ALTER TABLE [dbo].[CalendarDeadLines] CHECK CONSTRAINT [FK_CalendarDeadLines_Calendars]

	ALTER TABLE [dbo].[CalendarDeadLines]  WITH CHECK ADD  CONSTRAINT [FK_CalendarDeadLines_CityDictionary] FOREIGN KEY([CD_CTKey])
	REFERENCES [dbo].[CityDictionary] ([CT_KEY])

	ALTER TABLE [dbo].[CalendarDeadLines] CHECK CONSTRAINT [FK_CalendarDeadLines_CityDictionary]

	ALTER TABLE [dbo].[CalendarDeadLines]  WITH CHECK ADD  CONSTRAINT [FK_CalendarDeadLines_ServiceList] FOREIGN KEY([CD_SLKey])
	REFERENCES [dbo].[ServiceList] ([SL_KEY])

	ALTER TABLE [dbo].[CalendarDeadLines] CHECK CONSTRAINT [FK_CalendarDeadLines_ServiceList]
end
GO
grant select, insert, update, delete on [dbo].[CalendarDeadLines] to public
go



/*********************************************************************/
/* end (11.04.28)Create_Table_Calendar.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (110429)Data_SystemSettings.sql */
/*********************************************************************/
if not exists (select 1 from SystemSettings where SS_ParmName = 'SYSAutoPlaceToQuota')
	insert into SystemSettings (SS_ParmName, SS_ParmValue) values ('SYSAutoPlaceToQuota', 1)
go
/*********************************************************************/
/* end (110429)Data_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (110503)AlterTable_tbl_Dogovor.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end (110503)AlterTable_tbl_Dogovor.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (110510)NewAction.sql */
/*********************************************************************/
if not exists (select 1 from Actions where AC_Key = 74)
	insert into Actions (AC_Key, AC_Name, AC_NameLat) values (74, 'Разрешить работь с надстройкой "График работы консульств"', 'Allow work to add "Schedule Consulates"')
else
	print 'Обратитесь в службу поддержки, Actions с номером 74 занят'
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
/* begin (110511)Create_Table_FileHeadersDocType.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_FileHeaders_FileHeadersDocType]') AND parent_object_id = OBJECT_ID(N'[dbo].[FileHeaders]'))
ALTER TABLE [dbo].[FileHeaders] DROP CONSTRAINT [FK_FileHeaders_FileHeadersDocType]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FileHeadersDocType]') AND type in (N'U'))
DROP TABLE [dbo].[FileHeadersDocType]
GO

CREATE TABLE [dbo].[FileHeadersDocType](
	[FT_Key] [int] IDENTITY(1,1) NOT NULL,
	[FT_Name] [nvarchar](max) NOT NULL,
	[FT_NameLat] [nvarchar](max) NULL,
 CONSTRAINT [PK_FileHeadersDocType] PRIMARY KEY CLUSTERED 
(
	[FT_Key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

grant select, insert, delete, update on [dbo].[FileHeadersDocType] to public
go
insert into FileHeadersDocType(FT_Name, FT_NameLat) values ('Не задан', 'Not set')
insert into FileHeadersDocType(FT_Name, FT_NameLat) values ('Счет', 'Invoice')
go
if (exists (select 1 from FileHeaders where FH_DocType = 0))
	update FileHeaders set FH_DocType = FH_DocType + 1
go

ALTER TABLE [dbo].[FileHeaders]  WITH CHECK ADD  CONSTRAINT [FK_FileHeaders_FileHeadersDocType] FOREIGN KEY([FH_DocType])
REFERENCES [dbo].[FileHeadersDocType] ([FT_Key])
GO

ALTER TABLE [dbo].[FileHeaders] CHECK CONSTRAINT [FK_FileHeaders_FileHeadersDocType]
GO


/*********************************************************************/
/* end (110511)Create_Table_FileHeadersDocType.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20110404)_x_tp_indexes.sql */
/*********************************************************************/
if not exists(select id from syscolumns where id = OBJECT_ID('tp_lists') and name = 'TI_CalculatingKey')
	alter table tp_lists add TI_CalculatingKey int null
go
if  exists (select * from sysindexes where name like 'x_tp_lists_calc')
     drop index tp_lists.x_tp_lists_calc
go
create nonclustered index [x_tp_lists_calc]
	on [dbo].[tp_lists] ([TI_CalculatingKey])
go

if not exists(select id from syscolumns where id = OBJECT_ID('tp_services') and name = 'TS_CalculatingKey')
	alter table tp_services add TS_CalculatingKey int null
go
if  exists (select * from sysindexes where name like 'x_tp_services_calc')
     drop index tp_services.x_tp_services_calc
go
create nonclustered index [x_tp_services_calc]
	on [dbo].[tp_services] ([TS_CalculatingKey])
go

if not exists(select id from syscolumns where id = OBJECT_ID('tp_servicelists') and name = 'TL_CalculatingKey')
	alter table tp_servicelists add TL_CalculatingKey int null
go
if  exists (select * from sysindexes where name like 'x_tp_servicelists_calc')
     drop index tp_servicelists.x_tp_servicelists_calc
go
create nonclustered index [x_tp_servicelists_calc]
	on [dbo].[tp_servicelists] ([TL_CalculatingKey])
go

if not exists(select id from syscolumns where id = OBJECT_ID('tp_turdates') and name = 'TD_CalculatingKey')
	alter table tp_turdates add TD_CalculatingKey int null
go
if  exists (select * from sysindexes where name like 'x_tp_turdates_calc')
     drop index tp_turdates.x_tp_turdates_calc
go
create nonclustered index [x_tp_turdates_calc]
	on [dbo].[tp_turdates] ([TD_CalculatingKey])
go

if not exists(select id from syscolumns where id = OBJECT_ID('tp_prices') and name = 'TP_CalculatingKey')
	alter table tp_prices add TP_CalculatingKey int null
go
if  exists (select * from sysindexes where name like 'x_tp_prices_calc')
     drop index tp_prices.x_tp_prices_calc
go
create nonclustered index [x_tp_prices_calc]
	on [dbo].[tp_prices] ([TP_CalculatingKey])
go

if not exists(select id from syscolumns where id = OBJECT_ID('tp_flights') and name = 'TF_CalculatingKey')
	alter table tp_flights add TF_CalculatingKey int null
go
if  exists (select * from sysindexes where name like 'x_tp_flights_calc')
     drop index tp_flights.x_tp_flights_calc
go
create nonclustered index [x_tp_flights_calc]
	on [dbo].[tp_flights] ([TF_CalculatingKey])
go
/*********************************************************************/
/* end (20110404)_x_tp_indexes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.10.05)Alter_Table_ContactTypeFields.sql */
/*********************************************************************/
if not exists(select id from syscolumns where id = OBJECT_ID('ContactTypeFields') and name = 'CTF_CFVID')
	and exists (select id from syscolumns where id = OBJECT_ID('ContactTypeFields'))
	alter table dbo.ContactTypeFields add [CTF_CFVID] [int] NULL
go
/*********************************************************************/
/* end (11.10.05)Alter_Table_ContactTypeFields.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 100709_create_contacts.sql */
/*********************************************************************/
IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactTypes]') 
									  and OBJECTPROPERTY(id, N'IsUserTable') = 1)									
BEGIN
	declare @ContactTypes table(
	[CT_Id] [int] ,
	[CT_Name] [nvarchar] (255),
	[CT_Comment] [nvarchar] (1024),
	[CT_Icon] [image]
	)

	INSERT @ContactTypes
	select [CT_Id],[CT_Name],[CT_Comment],[CT_Icon] 
	from ContactTypes

	IF (IDENT_SEED('dbo.contactTypes') <> 1000)
	BEGIN
		UPDATE @ContactTypes
		SET CT_Id = CT_Id + 1000
	END
END
IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactFieldValidations]') 
									  and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	declare @ContactFieldValidations table(
		[CFV_Id] [int],
		[CFV_RegexValue] [varchar](1024)
	)

	INSERT @ContactFieldValidations 
	select [CFV_Id],[CFV_RegexValue] 
	from ContactFieldValidations 

	IF (IDENT_SEED('dbo.ContactFieldValidations') <> 10000)
	BEGIN
		UPDATE @ContactFieldValidations
		SET CFV_Id = CFV_Id + 10000
	END
END
IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactTypeFields]') 
									  and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	declare @ContactTypeFields table(
		[CTF_Id] [int],
		[CTF_Name] [nvarchar](255),
		[CTF_Comment] [nvarchar](1024),
		[CTF_CTID] int,
		[CTF_CFVID] int,
		[CTF_Order] int
	)

	INSERT @ContactTypeFields 
	select [CTF_Id],[CTF_Name],[CTF_Comment]
		  ,[CTF_CTID],[CTF_CFVID],[CTF_Order] 
	  from ContactTypeFields 
	
	IF (IDENT_SEED('dbo.ContactTypeFields') <> 10000 )
	BEGIN
		UPDATE @ContactTypeFields
		SET CTF_Id = CTF_Id + 10000, CTF_CFVID = CTF_CFVID + 10000, CTF_CTID = CTF_CTID + 1000
	END
END
IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[Contacts]') 
									  and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	declare @Contacts table(
		[CC_Id] [int],
		[CC_CTID] int
	)

	INSERT @Contacts 
	select [CC_Id],[CC_CTID] 
	from Contacts
	
	IF (IDENT_SEED('dbo.ContactTypes') <> 1000)
	BEGIN
		UPDATE @Contacts
		SET CC_CTID = CC_CTID + 1000
	END
END
IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactFields]') 
									  and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	declare @ContactFields table(
		[CF_Id] [int],
		[CF_CCID] int,
		[CF_CTFValue] [nvarchar](1024),
		[CF_CTFID] int
	)

	INSERT @ContactFields 
	select [CF_Id],[CF_CCID],[CF_CTFValue],[CF_CTFID] 
	from ContactFields
	
	IF (IDENT_SEED('dbo.ContactTypeFields') <> 10000)
	BEGIN
		UPDATE @ContactFields 
		SET CF_CTFID = CF_CTFID + 10000
	END
END

if EXISTS(SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactLinks]') 
										 and OBJECTPROPERTY(id, N'IsUserTable') = 1)
or EXISTS(SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[TouristContactLinks]') 
											  and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	declare @TouristContactLinks table(
	[TCL_Id] [int],
	[TCL_CCID] int,
	[TCL_TouristKey] int
	)
END

if EXISTS(SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactLinks]') 
										 and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	INSERT @TouristContactLinks (TCL_Id,TCL_CCID,TCL_TouristKey)
	select CL_Id, CL_CCID, CL_TUKey 
	from ContactLinks
END
ELSE IF EXISTS(SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[TouristContactLinks]') 
											  and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	INSERT @TouristContactLinks (TCL_Id,TCL_CCID,TCL_TouristKey)
	select TCL_Id, TCL_CCID, TCL_TouristKey 
	from TouristContactLinks
END

if EXISTS(SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[PartnerContactLinks]') 
										 and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	declare @PartnerContactLinks table(
		[PCL_Id] [int],
		[PCL_CCID] int,
		[PCL_PartnerKey] int 
	)
	INSERT @PartnerContactLinks 
	select [PCL_Id],[PCL_CCID],[PCL_PartnerKey] 
	from PartnerContactLinks
END

IF EXISTS(SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ClientContactLinks]') 
										 and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	declare @ClientContactLinks table(
		[CCL_Id] [int],
		[CCL_CCID] int,
		[CCL_ClientKey] int
	)

	INSERT @ClientContactLinks 
	select [CCL_Id],[CCL_CCID],[CCL_ClientKey] 
	from ClientContactLinks
END

IF EXISTS(SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[DupUserContactLinks]') 
										 and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
	declare @DupUserContactLinks table(
		[DUCL_Id] [int],
		[DUCL_CCID] int,
		[DUCL_DupUserKey] int
	)

	INSERT @DupUserContactLinks 
	select [DUCL_Id],[DUCL_CCID],[DUCL_DupUserKey] 
	from DupUserContactLinks
END


IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactLinks]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[ContactLinks]

IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[TouristContactLinks]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[TouristContactLinks]

IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[PartnerContactLinks]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[PartnerContactLinks]

IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ClientContactLinks]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[ClientContactLinks]

IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[DupUserContactLinks]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[DupUserContactLinks]

IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactFields]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[ContactFields]

IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactTypeFields]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[ContactTypeFields]

IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactFieldValidations]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[ContactFieldValidations]

IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[Contacts]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[Contacts]

IF EXISTS (SELECT 1 FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[ContactTypes]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
DROP TABLE [dbo].[ContactTypes]

CREATE TABLE [dbo].[ContactTypes](
	[CT_Id] [int] IDENTITY(1000,1) NOT NULL CONSTRAINT [PK_ContactTypes] PRIMARY KEY CLUSTERED ,
	[CT_Name] [nvarchar](255) NOT NULL,
	[CT_Comment] [nvarchar](1024) NULL,
	[CT_Icon] [image] NULL
)

GRANT select, update, insert, delete on [dbo].[ContactTypes] to public

CREATE TABLE [dbo].[ContactFieldValidations](
	[CFV_Id] [int] IDENTITY(10000,1) NOT NULL CONSTRAINT [PK_ContactFieldValidations] PRIMARY KEY CLUSTERED,
	[CFV_RegexValue] [varchar](1024) NOT NULL
)

GRANT select, update, insert, delete on [dbo].[ContactFieldValidations] to public

CREATE TABLE [dbo].[ContactTypeFields](
	[CTF_Id] [int] IDENTITY(10000,1) NOT NULL CONSTRAINT [PK_ContactTypeFields] PRIMARY KEY CLUSTERED ,
	[CTF_Name] [nvarchar](255) NOT NULL,
	[CTF_Comment] [nvarchar](1024) NULL,
	[CTF_CTID] int NOT NULL CONSTRAINT [FK_ContactTypeFields_ContactTypes] 
	REFERENCES [dbo].[ContactTypes]([CT_Id]) ON DELETE CASCADE,
	[CTF_CFVID] int NULL CONSTRAINT [FK_ContactTypeFields_ContactFieldValidations] 
	REFERENCES [dbo].[ContactFieldValidations]([CFV_Id]) ON DELETE NO ACTION,
	[CTF_Order] int NOT NULL DEFAULT(0)
)

GRANT select, update, insert, delete on [dbo].[ContactTypeFields] to public

CREATE TABLE [dbo].[Contacts](
	[CC_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED ,
	[CC_CTID] int NOT NULL CONSTRAINT [FK_Contacts_ContactTypes] 
	REFERENCES [dbo].[ContactTypes]([CT_Id]) ON DELETE CASCADE
)

GRANT select, update, insert, delete on [dbo].[Contacts] to public

CREATE TABLE [dbo].[ContactFields](
	[CF_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_ContactFields] PRIMARY KEY CLUSTERED ,
	[CF_CCID] int NOT NULL CONSTRAINT [FK_ContactFields_Contacts] 
	REFERENCES [dbo].[Contacts]([CC_Id]) ON DELETE CASCADE,
	[CF_CTFValue] [nvarchar](1024) NULL,
	[CF_CTFID] int NOT NULL CONSTRAINT [FK_ContactFields_ContactTypeFields] 
	REFERENCES [dbo].[ContactTypeFields]([CTF_Id]) ON DELETE NO ACTION
)

GRANT select, update, insert, delete on [dbo].[ContactFields] to public

CREATE TABLE [dbo].[TouristContactLinks](
	[TCL_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_TouristContactLinks] PRIMARY KEY CLUSTERED ,
	[TCL_CCID] int NOT NULL CONSTRAINT [FK_TouristContactLinks_Contacts] 
	REFERENCES [dbo].[Contacts]([CC_Id]) ON DELETE CASCADE,
	[TCL_TouristKey] int NOT NULL CONSTRAINT [FK_TouristContactLinks_TBL_TURIST] 
	REFERENCES [dbo].[TBL_TURIST]([TU_Key]) ON DELETE CASCADE
)

GRANT select, update, insert, delete on [dbo].[TouristContactLinks] to public

CREATE TABLE [dbo].[PartnerContactLinks](
	[PCL_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_PartnerContactLinks] PRIMARY KEY CLUSTERED ,
	[PCL_CCID] int NOT NULL CONSTRAINT [FK_PartnerContactLinks_Contacts] 
	REFERENCES [dbo].[Contacts]([CC_Id]) ON DELETE CASCADE,
	[PCL_PartnerKey] int NOT NULL CONSTRAINT [FK_PartnerContactLinks_tbl_Partners] 
	REFERENCES [dbo].[TBL_PARTNERS]([PR_Key]) ON DELETE CASCADE
)

GRANT select, update, insert, delete on [dbo].[PartnerContactLinks] to public

CREATE TABLE [dbo].[ClientContactLinks](
	[CCL_Id] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_ClientContactLinks] PRIMARY KEY CLUSTERED ,
	[CCL_CCID] int NOT NULL CONSTRAINT [FK_ClientContactLinks_Contacts] 
	REFERENCES [dbo].[Contacts]([CC_Id]) ON DELETE CASCADE,
	[CCL_ClientKey] int NOT NULL CONSTRAINT [FK_ClientContactLinks_CLIENTS] 
	REFERENCES [dbo].[CLIENTS]([CL_Key]) ON DELETE CASCADE
)

GRANT select, update, insert, delete on [dbo].[ClientContactLinks] to public


CREATE TABLE [dbo].[DupUserContactLinks]
	(
		[DUCL_Id] [int] IDENTITY(1,1) NOT NULL,
		[DUCL_CCID] [int] NOT NULL,
		[DUCL_DupUserKey] [int] NOT NULL,
		
	)	ON [PRIMARY]

ALTER TABLE [dbo].[DupUserContactLinks]  WITH CHECK ADD  CONSTRAINT [FK_DupUserContactLinks_Contacts] FOREIGN KEY([DUCL_CCID])
REFERENCES [dbo].[Contacts] ([CC_Id])
ON DELETE CASCADE

ALTER TABLE [dbo].[DupUserContactLinks] CHECK CONSTRAINT [FK_DupUserContactLinks_Contacts]

ALTER TABLE [dbo].[DupUserContactLinks]  WITH CHECK ADD  CONSTRAINT [FK_DupUserContactLinks_DUP_USER] FOREIGN KEY([DUCL_DupUserKey])
REFERENCES [dbo].[DUP_USER] ([US_KEY])
ON DELETE CASCADE

ALTER TABLE [dbo].[DupUserContactLinks] CHECK CONSTRAINT [FK_DupUserContactLinks_DUP_USER]

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.DupUserContactLinks TO PUBLIC


IF(EXISTS(SELECT OBJECT_ID(N'tempdb..@ContactTypes')))
BEGIN
	SET IDENTITY_INSERT dbo.ContactTypes ON
	INSERT dbo.ContactTypes([CT_Id],[CT_Name],[CT_Comment],[CT_Icon])
	SELECT [CT_Id],[CT_Name],[CT_Comment],[CT_Icon] FROM @ContactTypes
	SET IDENTITY_INSERT dbo.ContactTypes OFF
END

IF(EXISTS (SELECT OBJECT_ID(N'tempdb..@ContactFieldValidations')))
BEGIN
	SET IDENTITY_INSERT dbo.ContactFieldValidations ON
	INSERT dbo.ContactFieldValidations ([CFV_Id],[CFV_RegexValue])
	SELECT [CFV_Id],[CFV_RegexValue] FROM @ContactFieldValidations
	SET IDENTITY_INSERT dbo.ContactFieldValidations OFF
END

IF(EXISTS (SELECT OBJECT_ID(N'tempdb..@ContactTypeFields')))
BEGIN
	SET IDENTITY_INSERT dbo.ContactTypeFields ON
	INSERT dbo.ContactTypeFields ([CTF_Id],[CTF_Name],[CTF_Comment],[CTF_CTID],[CTF_CFVID],[CTF_Order])
	SELECT [CTF_Id],[CTF_Name],[CTF_Comment],[CTF_CTID],[CTF_CFVID],[CTF_Order] FROM @ContactTypeFields
	SET IDENTITY_INSERT dbo.ContactTypeFields OFF
END

IF(EXISTS (SELECT OBJECT_ID(N'tempdb..@Contacts')))
BEGIN
	SET IDENTITY_INSERT dbo.Contacts ON
	INSERT dbo.Contacts([CC_Id],[CC_CTID])
	SELECT [CC_Id],[CC_CTID] FROM @Contacts
	SET IDENTITY_INSERT dbo.Contacts OFF
END

IF(EXISTS (SELECT OBJECT_ID(N'tempdb..@ContactFields')))
BEGIN
	SET IDENTITY_INSERT dbo.ContactFields ON
	INSERT dbo.ContactFields([CF_Id],[CF_CCID],[CF_CTFValue],[CF_CTFID])
	SELECT [CF_Id],[CF_CCID],[CF_CTFValue],[CF_CTFID] FROM @ContactFields
	SET IDENTITY_INSERT dbo.ContactFields OFF
END

IF(EXISTS (SELECT OBJECT_ID(N'tempdb..@TouristContactLinks')))
BEGIN
	SET IDENTITY_INSERT dbo.TouristContactLinks ON
	INSERT dbo.TouristContactLinks([TCL_Id],[TCL_CCID],[TCL_TouristKey])
	SELECT [TCL_Id],[TCL_CCID],[TCL_TouristKey] FROM @TouristContactLinks
	SET IDENTITY_INSERT dbo.TouristContactLinks OFF
END

IF(EXISTS (SELECT OBJECT_ID(N'tempdb..@PartnerContactLinks')))
BEGIN
	SET IDENTITY_INSERT dbo.PartnerContactLinks ON
	INSERT dbo.PartnerContactLinks([PCL_Id],[PCL_CCID],[PCL_PartnerKey])
	SELECT [PCL_Id],[PCL_CCID],[PCL_PartnerKey] FROM @PartnerContactLinks
	SET IDENTITY_INSERT dbo.PartnerContactLinks OFF
END

IF(EXISTS (SELECT OBJECT_ID(N'tempdb..@ClientContactLinks')))
BEGIN
	SET IDENTITY_INSERT dbo.ClientContactLinks ON
	INSERT dbo.ClientContactLinks([CCL_Id],[CCL_CCID],[CCL_ClientKey])
	SELECT [CCL_Id],[CCL_CCID],[CCL_ClientKey] FROM @ClientContactLinks
	SET IDENTITY_INSERT dbo.ClientContactLinks OFF
END

IF(EXISTS (SELECT OBJECT_ID(N'tempdb..@DupUserContactLinks')))
BEGIN
	SET IDENTITY_INSERT dbo.DupUserContactLinks ON
	INSERT dbo.DupUserContactLinks([DUCL_Id],[DUCL_CCID],[DUCL_DupUserKey])
	SELECT [DUCL_Id],[DUCL_CCID],[DUCL_DupUserKey] FROM @DupUserContactLinks
	SET IDENTITY_INSERT dbo.DupUserContactLinks OFF
END
GO
/*********************************************************************/
/* end 100709_create_contacts.sql */
/*********************************************************************/

/*********************************************************************/
/* begin AlterTouristsAddEnableSmsNotifications.sql */
/*********************************************************************/
--последняя версия скриптов
if not exists (select * from dbo.syscolumns where name = 'TU_EnableSmsNotifications' and id = object_id(N'[dbo].[tbl_Turist]'))
	ALTER TABLE dbo.tbl_Turist add TU_EnableSmsNotifications smallint not null default 0
GO

exec sp_RefreshViewForAll 'Turist'
go

update tbl_Turist set TU_EnableSmsNotifications = 0 where TU_EnableSmsNotifications is null

if not exists (select * from dbo.syscolumns where name = 'US_EnableSmsNotifications' and id = object_id(N'[dbo].[DUP_USER]'))
	ALTER TABLE dbo.DUP_USER add US_EnableSmsNotifications bit not null default 0
GO

exec sp_RefreshViewForAll 'DUP_USER'
go

update DUP_USER set US_EnableSmsNotifications = 0 where US_EnableSmsNotifications is null
go

if not exists (select * from dbo.syscolumns where name = 'CL_EnableSmsNotifications' and id = object_id(N'[dbo].[Clients]'))
	ALTER TABLE dbo.Clients add CL_EnableSmsNotifications smallint not null	default 0
GO

update clients set CL_EnableSmsNotifications = 0 where CL_EnableSmsNotifications is null
GO

if not exists (select * from dbo.syscolumns where name = 'CFV_Example' and id = object_id(N'[dbo].[ContactFieldValidations]'))
	ALTER TABLE dbo.ContactFieldValidations add CFV_Example varchar(255) null
	
GO

if exists (select 1 from ContactFieldValidations where CFV_Id = 1)
	begin
		update ContactFieldValidations set CFV_RegexValue = '^((8|\+7)[\- ]?)?(\(?\d{3}\)?[\- ]?)?[\d\- ]{7,10}$' where CFV_Id = 1
		update ContactFieldValidations set CFV_Example = 'X (XXX) XXX-XX-XX' where CFV_Id = 1
	end
else
	begin
		set identity_insert ContactFieldValidations on
		insert into ContactFieldValidations (CFV_Id,CFV_RegexValue, CFV_Example) values ('1','^((8|\+7)[\- ]?)?(\(?\d{3}\)?[\- ]?)?[\d\- ]{7,10}$', 'X (XXX) XXX-XX-XX')
		set identity_insert ContactFieldValidations off
	end
go

if exists (select 1 from ContactTypes where CT_Id = 1)
	begin
		update ContactTypes set CT_Name = 'Телефон для SMS-уведомлений' where CT_Id = 1
		update ContactTypes set CT_Comment = 'Предназначен для SMS-шлюза' where CT_Id = 1
	end
else
	begin
		set identity_insert ContactTypes on
		insert into ContactTypes (CT_Id,CT_Name,CT_Comment) values ('1','Телефон для SMS-уведомлений','Предназначен для SMS-шлюза')
		set identity_insert ContactTypes off
	end
go

if exists (select 1 from ContactTypeFields where CTF_Id = 1)
	begin
		update ContactTypeFields set CTF_Name = 'Телефон для SMS-уведомлений' where CTF_Id = 1
		update ContactTypeFields set CTF_Comment = 'Предназначен для SMS-шлюза' where CTF_Id = 1
		update ContactTypeFields set CTF_CTID = '1' where CTF_Id = 1
		update ContactTypeFields set CTF_Order = '0' where CTF_Id = 1
		update ContactTypeFields set CTF_CFVID = '1' where CTF_Id = 1
	end
else
	begin
		set identity_insert ContactTypeFields on
		insert into ContactTypeFields (CTF_Id,CTF_Name,CTF_Comment,CTF_CTID,CTF_Order,CTF_CFVID) values ('1','Телефон для SMS-уведомлений','Предназначен для SMS-шлюза','1','0','1')
		set identity_insert ContactTypeFields off
	end
go

if exists (select * from dbo.syscolumns where name = 'PR_EnableSmsNotifications' and id = object_id(N'[dbo].[tbl_Partners]'))
begin
	IF EXISTS (select * from sysobjects o 
				inner join syscolumns c
				on o.id = c.cdefault
				inner join sysobjects t
				on c.id = t.id
				where o.xtype = 'd'
				and c.name = 'PR_EnableSmsNotifications'
				and t.name = 'tbl_Partners')
    begin  
    declare @default nvarchar(100)
    declare @sql nvarchar(200)
    set @default = (select o.name from sysobjects o 
				inner join syscolumns c
				on o.id = c.cdefault
				inner join sysobjects t
				on c.id = t.id
				where o.xtype = 'd'
				and c.name = 'PR_EnableSmsNotifications'
				and t.name = 'tbl_Partners')
    set @sql = N'alter table tbl_Partners drop constraint ' + @default
	exec sp_executesql @sql      
    end
	ALTER TABLE dbo.tbl_Partners drop column PR_EnableSmsNotifications 
end

exec sp_RefreshViewForAll 'Partners'
go
/*********************************************************************/
/* end AlterTouristsAddEnableSmsNotifications.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 101027_alter_dg_mainmen.sql */
/*********************************************************************/
if((select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS
	where TABLE_SCHEMA='dbo' and TABLE_NAME='tbl_Dogovor' and COLUMN_NAME='DG_MAINMEN')<70)
ALTER TABLE dbo.tbl_Dogovor ALTER COLUMN DG_MAINMEN varchar(70)
GO

/*********************************************************************/
/* end 101027_alter_dg_mainmen.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110415(AlterTable_Accounts).sql */
/*********************************************************************/
-- Kolbeshkin MEG00033107: в таблицу Accounts добавляет столбец AC_ReportNumber
if not exists(select id from syscolumns where id = OBJECT_ID('Accounts') and name = 'AC_ReportNumber')
	alter table dbo.Accounts add AC_ReportNumber int null
go
/*********************************************************************/
/* end 110415(AlterTable_Accounts).sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110420(AlterTable_VisaTouristService).sql */
/*********************************************************************/
-- Kharitonov MEG00033688: удаляем данные пользователей для формы пакетной обратотки
if exists (select 1 from dbo.UserSettings where ST_ParmName = 'GroupVisaForm')
delete from dbo.UserSettings where ST_ParmName = 'GroupVisaForm'
GO

-- Kolbeshkin MEG00033688: в таблицу VisaTouristService добавляет столбцы:
-- VTS_DocToVisaDept - Дата и время получения документов визовым отделом
-- VTS_IsChecked - Проверено или нет
if not exists(select id from syscolumns where id = OBJECT_ID('VisaTouristService') and name = 'VTS_DocToVisaDept')
	alter table dbo.VisaTouristService add VTS_DocToVisaDept smalldatetime null
go

if not exists(select id from syscolumns where id = OBJECT_ID('VisaTouristService') and name = 'VTS_IsChecked')
	alter table dbo.VisaTouristService add VTS_IsChecked smallint null
go

-- Добавляем соответствующие записи в ObjectAliases
if not exists (select * from dbo.ObjectAliases where OA_Alias='VTS_DocToVisaDeprt')
insert into dbo.ObjectAliases (OA_Id,OA_Alias,OA_Name,OA_TABLEID)
values (1141,'VTS_DocToVisaDeprt','Дата и время получения документов визовым отделом',62)
GO
if not exists (select * from dbo.ObjectAliases where OA_Alias='VTS_IsChecked')
insert into dbo.ObjectAliases (OA_Id,OA_Alias,OA_Name,OA_TABLEID)
values (1142,'VTS_IsChecked','Проверено',62)
GO
/*********************************************************************/
/* end 110420(AlterTable_VisaTouristService).sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110522(Create_TPServicesDelete_Log_DeleteTP_ServicesLog).sql */
/*********************************************************************/
-- Данный скрипт создает триггер для логирования удаления строк из таблицы TP_Services 
-- и таблицу DeleteTP_ServicesLog для хранения этого лога


IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteTP_ServicesLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN

	CREATE TABLE [dbo].[DeleteTP_ServicesLog](
		[SL_ID] [int] IDENTITY(1,1) NOT NULL,
		[SL_User] [nvarchar](50) NULL,
		[SL_DateTime] [datetime] NULL,
		[SL_AppName] [nvarchar](100) NULL,
		[SL_HostName] [nvarchar](60) NULL,
		[SL_Query] [nvarchar](max) NULL,
		[SL_Count] [int] NULL,
	 CONSTRAINT [PK_DeleteTP_ServiceLog] PRIMARY KEY CLUSTERED 
	(
		[SL_ID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	
END
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[CalculatingPriceLists] TO PUBLIC
GO

IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TPServicesDelete_Log]'))
DROP TRIGGER [dbo].[TPServicesDelete_Log]
GO

CREATE TRIGGER [dbo].[TPServicesDelete_Log]
   ON  [dbo].[TP_Services] 
   FOR DELETE
AS 
BEGIN	
	-- Данный триггер предназначен для записывание в лог (таблица DeleteTP_ServicesLog)
	-- информации об удалении строк из таблицы TP_Services.
	-- Логгируется следующая информация: дата и время, пользователь, имя приложения, имя компьютера,
	-- тект запроса вызвавшего триггер, количество удаленных строк.
	

	DECLARE @txt nvarchar(max) -- текст запроса вызвавшего триггер (первые 4000 символов)
	
	-- Извлекаем текст запроса вызвавшего триггер 
	-- (код взят отсюда http://sqlblog.com/blogs/jonathan_kehayias/archive/2010/01/12/tsql2sday-using-sys-dm-exec-sql-text-to-get-the-calling-statement.aspx )
	DECLARE @TEMP TABLE 
	(EventType NVARCHAR(30), Parameters INT, EventInfo NVARCHAR(4000)) 
	INSERT INTO @TEMP EXEC('DBCC INPUTBUFFER(@@SPID)') 
	SELECT @txt = EventInfo FROM @TEMP 	

	declare @count int -- Количество удаленных строк
	select @count = COUNT(*) from deleted	
	
	INSERT INTO DeleteTP_ServicesLog
	(
		SL_User,	  SL_DateTime, SL_AppName, SL_HostName, SL_Query, SL_Count
	)
	VALUES
	(
		SUSER_NAME(), GETDATE(),   APP_NAME(), HOST_NAME(), @txt,	  @count
	)		
END

GO
/*********************************************************************/
/* end 110522(Create_TPServicesDelete_Log_DeleteTP_ServicesLog).sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110202_CreateTable_ExternalSystems.sql */
/*********************************************************************/
------------------------------------
-- Create ExternalSystems Table
------------------------------------
IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA ='dbo' AND TABLE_NAME = 'ExternalSystems')
BEGIN
	CREATE TABLE dbo.ExternalSystems
	(
		 ES_ID INT NOT NULL IDENTITY (1, 1) 
		,ES_Name VARCHAR(100) 
		,ES_Code VARCHAR(30)
		,ES_Comment VARCHAR(max)
		,ES_PRKey INT
		,CONSTRAINT PK_ExternalSystems PRIMARY KEY (ES_ID)
		,CONSTRAINT FK_ExternalSystems_tbl_Partners FOREIGN KEY (ES_PRKey) REFERENCES [tbl_Partners](PR_KEY) ON DELETE CASCADE
	);
END
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ExternalSystems TO PUBLIC
GO
-----------------------------
-- Create ExternalSystemsConfig Table
-----------------------------
IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA ='dbo' AND TABLE_NAME = 'ExternalSystemsConfig')
BEGIN
	CREATE TABLE dbo.ExternalSystemsConfig
	(
		 SC_ID INT NOT NULL IDENTITY (1, 1) 
		,SC_ParamName VARCHAR(100) NOT NULL
		,SC_Comment VARCHAR(max)
		,SC_ParamValue VARCHAR(max) NOT NULL
		,SC_ESID INT NOT NULL
		,CONSTRAINT PK_ExternalSystemsConfig PRIMARY KEY (SC_ID)
		,CONSTRAINT FK_ExternalSystemsConfig_ExternalSystems FOREIGN KEY (SC_ESID) REFERENCES dbo.[ExternalSystems](ES_ID) ON DELETE CASCADE
	);
END
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ExternalSystemsConfig TO PUBLIC
GO
---------------------------------
-- Create ExternalSystemRequestTypes Table
---------------------------------
IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA ='dbo' AND TABLE_NAME = 'ExternalSystemRequestTypes')
BEGIN
	CREATE TABLE dbo.ExternalSystemRequestTypes
	(
		 RQ_ID INT NOT NULL IDENTITY (1, 1) 
		,RQ_Name VARCHAR(100)
		,RQ_Code VARCHAR(30)
		,CONSTRAINT PK_ExternalSystemRequestTypes PRIMARY KEY (RQ_ID)
	);
END
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ExternalSystemRequestTypes TO PUBLIC
GO
--------------------------
-- Create ExternalSystemsExchangeData Table
--------------------------
IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA ='dbo' AND TABLE_NAME = 'ExternalSystemsExchangeData')
BEGIN
	CREATE TABLE dbo.ExternalSystemsExchangeData
	(
		 ED_ID INT NOT NULL IDENTITY (1, 1)
		,ED_ESID INT NOT NULL
		,ED_RequestData VARCHAR(max) NOT NULL
		,ED_ResponseData VARCHAR(max) NOT NULL
		,ED_SessionID VARCHAR(100)
		,ED_RequestTime DATETIME NOT NULL
		,ED_ResponseTime DATETIME NOT NULL
		,ED_RQID INT
		,ED_BookingID VARCHAR(100)
		,CONSTRAINT PK_ExternalSystemsExchangeData PRIMARY KEY (ED_ID)
		,CONSTRAINT FK_ExternalSystemsExchangeData_ExternalSystems FOREIGN KEY (ED_ESID) REFERENCES dbo.[ExternalSystems](ES_ID) ON DELETE CASCADE
		,CONSTRAINT FK_ExternalSystemsExchangeData_ExternalSystemRequestTypes FOREIGN KEY (ED_RQID) REFERENCES dbo.[ExternalSystemRequestTypes](RQ_ID) ON DELETE CASCADE
	);
END
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ExternalSystemsExchangeData TO PUBLIC
GO
--------------------------------
-- Create ExternalSystemsExchangeCache Table
--------------------------------
IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA ='dbo' AND TABLE_NAME = 'ExternalSystemsExchangeCache')
BEGIN
	CREATE TABLE dbo.ExternalSystemsExchangeCache
	(
		 EC_ID INT NOT NULL IDENTITY (1, 1) 
		,EC_ParmName VARCHAR(100) NOT NULL
		,EC_ParmValue VARCHAR(max)
		,EC_Comment VARCHAR(256) NOT NULL
		,EC_EDID INT NOT NULL
		,CONSTRAINT PK_ExternalSystemsExchangeCache PRIMARY KEY (EC_ID)
		,CONSTRAINT FK_ExternalSystemsExchangeCache_ExternalSystemsExchangeData FOREIGN KEY (EC_EDID) REFERENCES dbo.[ExternalSystemsExchangeData](ED_ID) ON DELETE CASCADE
	);
END
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ExternalSystemsExchangeCache TO PUBLIC
GO
------------------------------
-- Create ExternalSystemDataToDogovorList Table
------------------------------
IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA ='dbo' AND TABLE_NAME = 'ExternalSystemDataToDogovorList')
BEGIN
	CREATE TABLE dbo.ExternalSystemDataToDogovorList
	(
		 EDL_ID INT NOT NULL IDENTITY (1, 1) 
		,EDL_ESDID INT
		,EDL_DLKey INT
		,EDL_TUKey INT
		,CONSTRAINT PK_ExternalSystemDataToDogovorList PRIMARY KEY (EDL_ID)
		,CONSTRAINT FK_ExternalSystemDataToDogovorList_ExternalSystemsExchangeData FOREIGN KEY (EDL_ESDID) REFERENCES dbo.[ExternalSystemsExchangeData](ED_ID) ON DELETE CASCADE
		,CONSTRAINT FK_ExternalSystemDataToDogovorList_tbl_DogovorList FOREIGN KEY (EDL_DLKey) REFERENCES [tbl_DogovorList](DL_Key) ON DELETE CASCADE
	);
END
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ExternalSystemDataToDogovorList TO PUBLIC
GO
/*********************************************************************/
/* end 20110202_CreateTable_ExternalSystems.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110315_createTable_ApplicationLogs.sql */
/*********************************************************************/

IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA ='dbo' AND TABLE_NAME = 'ApplicationLogs')
BEGIN
	CREATE TABLE [dbo].[ApplicationLogs](
		[AL_ID] [int] IDENTITY(1,1) NOT NULL,
		[AL_CreateDate] [datetime] NOT NULL,
		[AL_ActionID] [int] NOT NULL,
		[AL_Succeed] [bit] NOT NULL,
		[AL_UserID] [nvarchar](50) NOT NULL,
		[AL_Name] [nvarchar](100) NOT NULL,
		[AL_Host] [nvarchar](50) NULL,
	 CONSTRAINT [PK_ApplicationLogs] PRIMARY KEY CLUSTERED 
	(
		[AL_ID] ASC
	) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

grant insert on [dbo].[ApplicationLogs] to public
GO

/*********************************************************************/
/* end 20110315_createTable_ApplicationLogs.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110525AlterCountryAndDogovor.sql */
/*********************************************************************/
if not exists(select 1 from syscolumns where id = OBJECT_ID('tbl_Country') and name = 'CN_RateKey')
begin
	alter table tbl_Country add CN_RateKey int null REFERENCES rates(ra_key);
	exec sp_refreshviewforall Country;
end
go

if not exists(select 1 from syscolumns where id = OBJECT_ID('tbl_dogovor') and name = 'DG_CurrencyKey')
begin
	alter table tbl_dogovor add DG_CurrencyKey int null REFERENCES rates(ra_key);
	exec sp_refreshviewforall Dogovor;
end
go

if not exists(select 1 from syscolumns where id = OBJECT_ID('tbl_dogovor') and name = 'DG_CurrencyRate')
begin
	alter table tbl_dogovor add DG_CurrencyRate money null ;
	exec sp_refreshviewforall Dogovor;
end
go
if not exists(select 1 from tbl_dogovor where DG_CurrencyKey is not null)
BEGIN
	DECLARE @NationalCurrency int
	SELECT @NationalCurrency = RA_Key FROM rates WHERE RA_National = 1
	UPDATE tbl_dogovor
	SET DG_CurrencyKey = @NationalCurrency					 
END
go

if not exists(select 1 from tbl_dogovor where DG_CurrencyRate is not null)
	UPDATE tbl_dogovor
	SET DG_CurrencyRate = (SELECT TOP 1 CAST(HI_TEXT AS MONEY) FROM HISTORY
						    WHERE HI_DGCOD = DG_CODE and HI_OAId = 20 
						 ORDER BY HI_DATE desc)
go




/*********************************************************************/
/* end 20110525AlterCountryAndDogovor.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110531_AlterTable_FileHeaders.sql */
/*********************************************************************/
if not exists(select id from syscolumns where id = OBJECT_ID('FileHeaders') and name = 'FH_FileExtension')
	alter table dbo.FileHeaders add FH_FileExtension nvarchar(50) NULL
go

/*********************************************************************/
/* end 20110531_AlterTable_FileHeaders.sql */
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
/* begin AlterTable_Clients.sql */
/*********************************************************************/
if not exists (select 1 from sysobjects where type='D' and parent_obj = object_id(N'dbo.Clients') and name like '%CL_DATE%')
	ALTER TABLE [dbo].[Clients] ADD  DEFAULT (GetDate()) FOR [CL_DateUpdate]
GO
/*********************************************************************/
/* end AlterTable_Clients.sql */
/*********************************************************************/

/*********************************************************************/
/* begin AlterView_TitleTypePartner.sql */
/*********************************************************************/
ALTER VIEW [dbo].[TitleTypePartner] AS 
	SELECT	PT_Id - 1000 as TL_Key,
			PT_Name as TL_Title,
			PT_NameLat as TL_TitleLat
	FROM PrtTypes
	WHERE PT_Id > 1000
	WITH CHECK OPTION
GO
/*********************************************************************/
/* end AlterView_TitleTypePartner.sql */
/*********************************************************************/

/*********************************************************************/
/* begin InsertVisaTouristFormIntoDotNetWindows.sql */
/*********************************************************************/
if not exists (select * from DotNetWindows where WN_WINDOWNAME = 'VisaTouristForm')
insert into DotNetWindows (WN_WINDOWNAME,WN_EXWINDOWNAME,WN_NAMERUS,WN_NAMELAT) 
values ('VisaTouristForm','','Визы туристов','Visas of tourists')

go
/*********************************************************************/
/* end InsertVisaTouristFormIntoDotNetWindows.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_AutoQuotesPlaces.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end sp_AutoQuotesPlaces.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalculateCalendar.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalculateCalendar]') AND type in (N'P', N'PC'))
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
													and CE_CalendarKey = @calendarKey)
		end
		else -- иначе удаляем запись из CalendarDates
		begin
			-- сначала удалим события
			delete CalendarDateEvents
			where CDE_CalendarDateKey in (	select 1
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
	where CDE_CalendarDateKey in (	select 1
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
/* begin sp_CalculateDogovorCost.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CalculateDogovorCost]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CalculateDogovorCost]
GO
CREATE PROCEDURE [dbo].[CalculateDogovorCost]
  (
	@nDGKey int
  )
AS

-- <VERSION>2007.2.25 (2009.05.19)</VERSION>
-- Подсчёт стоимости путевки сделано по образу функции CalculateCost() класса Megatec.MasterTour.BusinessRules.Dogovor

DECLARE @totalDays int
DECLARE @tourKey int, @agentKey int, @bookingType int, @turDate datetime, @discountKey int,
		@discountValue int, @isPercent int, @createDate datetime, @discountPercent decimal,
		@checkinDate datetime, @resRate varchar(2), @margin float, @marginType int, @dgNDays int
DECLARE @netto decimal(14,2), @brutto decimal(14,2), @discount decimal(14,2)
DECLARE @dlKey int, @dlSvKey int, @dlCode int, @dlSubCode1 int, @dlSubCode2 int, @dlPrKey int, @dlPaketKey int, 
		@dlDateBeg datetime, @dlNDays int, @dlNMen int
DECLARE @price decimal(14,2), @discountSum decimal(14,2)
DECLARE @serviceWithDiscountSum decimal(14,2), @koef float, @calcDiscountSum decimal(14,2)

SET @price = 0
SET @discountSum = 0
SET @serviceWithDiscountSum = 0

select @totalDays = dg_nday from DOGOVOR where DG_Key=@nDGKey

SELECT @tourKey = DG_TRKey, @agentKey = DG_PARTNERKEY, @bookingType = DG_BTKEY, @checkinDate = DG_TURDATE, 
	   @resRate = DG_RATE, @createDate = DG_CRDATE, @dgNDays = DG_NDAY
FROM tbl_dogovor 
WHERE DG_KEY = @nDGKey
 
EXEC dbo.GetPartnerCommission @tourKey, @agentKey, @bookingType, @discountKey output, @discountValue output,
							  @isPercent output, @checkinDate

IF(@isPercent = 1)
	SET @discountPercent = @discountValue
ELSE
	SET @discountPercent = 0

DECLARE cur_Services CURSOR FOR 
SELECT DL_KEY, DL_SVKEY, DL_CODE, DL_SUBCODE1, DL_SUBCODE2, DL_PARTNERKEY, DL_PAKETKEY, DL_DATEBEG, DL_NDAYS, DL_NMEN
FROM tbl_dogovorlist 
WHERE DL_DGKEY = @nDGKey

OPEN cur_Services
FETCH NEXT FROM cur_Services INTO @dlKey, @dlSvKey, @dlCode, @dlSubCode1, @dlSubCode2, @dlPrKey, @dlPaketKey,
								  @dlDateBeg, @dlNDays, @dlNMen
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @dlSvKey = 1
		set @dlNDays = @totalDays

	EXEC dbo.GetTourMargin @tourKey, @checkinDate, @margin output, @marginType output, @dlSvKey, @dgNDays, @createDate, @dlPaketKey

	EXEC dbo.GetServiceCost @dlSvKey, @dlCode, @dlSubCode1, @dlSubCode2, @dlPrKey, @dlPaketKey, @dlDateBeg, 
							@dlNDays, @resRate, @dlNMen, @discountPercent, @margin, @marginType, @createDate,  
							@netto output, @brutto output, @discount output

	UPDATE tbl_dogovorlist SET DL_COST = @netto, DL_BRUTTO = @brutto, DL_DISCOUNT = @discount WHERE DL_KEY = @dlKey

	SET @price = @price + ISNULL(@brutto, 0)
	SET @discountSum = @discountSum + ISNULL(@discount, 0)

	IF(@discount IS NOT NULL)
		SET @serviceWithDiscountSum = @serviceWithDiscountSum + ABS(@brutto)

	FETCH NEXT FROM cur_Services INTO @dlKey, @dlSvKey, @dlCode, @dlSubCode1, @dlSubCode2, @dlPrKey, @dlPaketKey,
									  @dlDateBeg, @dlNDays, @dlNMen
END
CLOSE cur_Services
DEALLOCATE cur_Services

SET @price = @price + @discountSum
EXEC RoundCost @discountSum output, 3
SET @price = @price - @discountSum

IF(@isPercent = 0)
BEGIN
	SET @discountSum = @discountSum - @discountValue
	SET @price = @price + @discountValue
END

EXEC RoundCost @price output, 2

UPDATE tbl_dogovor SET DG_PRICE = @price, DG_DISCOUNT = @discountPercent, DG_DISCOUNTSUM = @discountSum 
WHERE DG_KEY = @nDGKey

IF(@serviceWithDiscountSum <> 0)
BEGIN
	-- Перераспределяем коммиссии по услугам пропорционально их стоимости
	SET @koef = @discountSum / @serviceWithDiscountSum
	SET @calcDiscountSum = 0

	DECLARE cur_Services1 CURSOR FOR 
	SELECT DL_KEY, DL_BRUTTO, DL_DISCOUNT
	FROM tbl_dogovorlist 
	WHERE DL_DGKEY = @nDGKey AND DL_DISCOUNT IS NOT NULL
	OPEN cur_Services1
	FETCH NEXT FROM cur_Services1 INTO @dlKey, @brutto, @discount
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @discount = ABS(@brutto) * @koef
		EXEC RoundCost @discount output, 3
		UPDATE tbl_dogovorlist SET DL_DISCOUNT = @discount where DL_KEY = @dlKey
		SET @calcDiscountSum = @calcDiscountSum + @discount

		FETCH NEXT FROM cur_Services1 INTO @dlKey, @brutto, @discount
	END
	CLOSE cur_Services1
	DEALLOCATE cur_Services1

	-- Увеличиваем коммиссию самой дорогой услуги на остаток, чтобы суммарная коммиссия не изменилась
	SELECT @dlKey = DL_KEY, @discount = DL_DISCOUNT 
	FROM tbl_dogovorlist 
	WHERE DL_DGKEY = @nDGKey AND DL_DISCOUNT IS NOT NULL
	ORDER BY DL_BRUTTO

	UPDATE tbl_dogovorlist SET DL_DISCOUNT = @discount + @discountSum - @calcDiscountSum WHERE DL_KEY = @dlKey
END
GO
GRANT EXEC ON [dbo].[CalculateDogovorCost] TO PUBLIC
GO

/*********************************************************************/
/* end sp_CalculateDogovorCost.sql */
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
			TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days, @nCalculatingKey, TD_Date
			From TP_Services with(nolock), TP_TurDates with(nolock), TP_Tours with(nolock), TP_Lists with(nolock), TP_ServiceLists with(nolock)
			where TS_TOKey = TO_Key and TS_SVKey = 1 and TD_TOKey = TO_Key and TI_TOKey = TO_Key and TL_TOKey = TO_Key and TL_TSKey = TS_Key and TL_TIKey = TI_Key and TO_Key = @nPriceTourKey
	Else
	BEGIN
		select distinct TO_Key, TD_Date + TS_Day - 1 flight_day, TS_Code , TS_OpPartnerKey,	TS_OpPacketKey, TS_CTKey, TS_SubCode1, TS_SubCode2, TI_Days, TD_Date
		into #tp_flights
		from TP_Tours with(nolock) join TP_Services with(nolock) on TO_Key = TS_TOKey and TS_SVKey = 1
			join TP_ServiceLists with(nolock) on TL_TSKey = TS_Key and TS_TOKey = TO_Key
			join TP_Lists with(nolock) on TL_TIKey = TI_Key and TI_TOKey = TO_Key
			join TP_TurDates with(nolock) on TD_TOKey = TO_Key
		where TO_Key = @nPriceTourKey
		
		delete from #tp_flights where exists (Select 1 From TP_Flights with(nolock) Where TF_TOKey=@nPriceTourKey and TF_Date=flight_day
			and TF_CodeOld=TS_Code and TF_PRKeyOld=TS_OpPartnerKey and TF_PKKey=TS_OpPacketKey
			and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = TI_Days)
	
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
								TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') AND
								TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01') AND
								AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
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
									TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') AND
									TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01') AND
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
									TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') AND
									TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01') AND
									AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
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
			select ti_firsthdkey, ts_key, ti_key, td_date, ts_svkey, ts_code, ts_subcode1, ts_subcode2, ts_oppartnerkey, ts_oppacketkey, ts_day, ts_days, to_rate, ts_men, ts_tempgross, ts_checkmargin, td_checkmargin, ti_days, ts_ctkey, ts_attribute
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

		--select tp_key, tp_tokey, tp_dateBegin, tp_DateEnd, TP_Gross, TP_TIKey 
		--from tp_prices with(nolock)
		--where tp_tokey = @nPriceTourKey and 
		--	tp_tikey in (select ti_key from tp_lists with(nolock) where ti_tokey = @nPriceTourKey and ti_update = @nUpdate) and
		--	tp_datebegin in (select td_date from tp_turdates with(nolock) where td_tokey = @nPriceTourKey and td_update = @nUpdate)

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
							update #TP_Prices set xtp_gross = @price_brutto, xtp_calculatingkey = @nCalculatingKey, xtp_key = @nTP_PriceKeyCurrent where xtp_tokey = @nPriceTourKey and xtp_datebegin = @dtPrevDate and xtp_dateend = @dtPrevDate and xtp_tikey = @nPrevVariant and xtp_gross <> @price_brutto
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
		--	EXEC FillMasterWebSearchFields @nPriceTourKey, @nCalculatingKey
		--else
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
/* begin sp_CalculatePriceListFinish.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CalculatePriceListFinish]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[CalculatePriceListFinish]
GO

CREATE PROCEDURE [dbo].[CalculatePriceListFinish]
  (
	@nCalculatingKey int		-- ключ итерации дозаписи
  )
AS
--<DATE>2011-04-04</DATE>
---<VERSION>7.2.40</VERSION>
BEGIN
return
	declare @tourKey int, @priceTourKey int
	
	select @tourKey = CP_TourKey, @priceTourKey = CP_PriceTourKey from CalculatingPriceLists where CP_Key = @nCalculatingKey
	update TP_Tours set TO_UPDATE = 0, TO_PROGRESS = 100 where TO_Key = @priceTourKey
	update tp_lists set ti_nights = (select sum(ts_days) from tp_servicelists with(nolock) inner join tp_services with(nolock) on tl_tskey = ts_key where tl_tikey = ti_key and ts_svkey = 3) WHERE TI_CalculatingKey = @nCalculatingKey

	Return 0
END
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

GRANT EXEC ON [dbo].[CalculatePriceListFinish] TO PUBLIC
GO
/*********************************************************************/
/* end sp_CalculatePriceListFinish.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CalculatePriceListInit.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CalculatePriceListInit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[CalculatePriceListInit]
GO

CREATE PROCEDURE [dbo].[CalculatePriceListInit]
  (
	@nPriceTourKey int,			-- ключ обсчитываемого тура
	@dtSaleDate datetime,		-- дата продажи
	@nNullCostAsZero smallint,	-- считать отсутствующие цены нулевыми (кроме проживания) 0 - нет, 1 - да
	@nNoFlight smallint,		-- при отсутствии перелёта в расписании 0 - ничего не делать, 1 - не обсчитывать тур, 2 - искать подходящий перелёт (если не найдено - не рассчитывать)
	@nUpdate smallint,			-- признак дозаписи 0 - расчет, 1 - дозапись
	@nUseHolidayRule smallint		-- Правило выходного дня: 0 - не использовать, 1 - использовать
  )
AS
--<DATE>2011-04-04</DATE>
---<VERSION>7.2.40</VERSION>
BEGIN
	declare @tourKey int
	declare @userKey int
	declare @nCPKey int
	select @tourKey = TO_TRKey from TP_Tours where TO_Key = @nPriceTourKey
	exec GetUserKey @userKey output
	
	update TP_Tours set TO_UPDATE = 1, TO_PROGRESS = 0 where TO_Key = @nPriceTourKey
	
	insert into CalculatingPriceLists (CP_PriceTourKey, CP_SaleDate, CP_NullCostAsZero, CP_NoFlight, CP_Update, CP_TourKey, CP_UserKey, CP_Status, CP_UseHolidayRule, CP_CreateDate)
	values(@nPriceTourKey, @dtSaleDate, @nNullCostAsZero, @nNoFlight, @nUpdate, @tourKey, @userKey, 1, @nUseHolidayRule, GETDATE())
	
	Set @nCPKey = SCOPE_IDENTITY()

	Return @nCPKey
END
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

GRANT EXEC ON [dbo].[CalculatePriceListInit] TO PUBLIC
GO
/*********************************************************************/
/* end sp_CalculatePriceListInit.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ClearMasterWebSearchFields.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ClearMasterWebSearchFields]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[ClearMasterWebSearchFields]
GO

CREATE PROCEDURE [dbo].[ClearMasterWebSearchFields]
	@tokey int, -- ключ тура
	@calcKey int = null
as
begin
	update dbo.TP_Tours set TO_Update = 1, TO_Progress = 0 where TO_Key = @tokey

	if(@calcKey is null)
		exec dbo.mwEnablePriceTour @tokey, 0, @calcKey

	if(@calcKey is not null)
	begin
		delete from dbo.mwPriceDataTable where pt_pricekey in (select tp_key from tp_prices with(nolock) where tp_calculatingkey = @calcKey)
	end
	else
	begin
		delete from dbo.mwPriceDataTable where pt_tourkey = @tokey
	end

	update dbo.TP_Tours set TO_Progress = 25 where TO_Key = @tokey

	if(@calcKey is null)		
	begin
		delete from dbo.mwSpoDataTable where sd_tourkey = @tokey
	end

	update dbo.TP_Tours set TO_Progress = 50 where TO_Key = @tokey

	if(@calcKey is null)		
	begin
		delete from dbo.mwPriceDurations where sd_tourkey = @tokey
	end

	update dbo.TP_Tours set TO_Progress = 75 where TO_Key = @tokey

	if(@calcKey is null)		
	begin
		delete from dbo.mwPriceHotels where sd_tourkey = @tokey
	end

	update dbo.TP_Tours set TO_Update = 0, TO_Progress = 100, TO_UpdateTime = GetDate() where TO_Key = @tokey
end
GO

GRANT EXEC ON [dbo].[ClearMasterWebSearchFields] TO PUBLIC
GO
/*********************************************************************/
/* end sp_ClearMasterWebSearchFields.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DogListToQuotas.sql */
/*********************************************************************/
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
		@ServiceDateBeg datetime, @ServiceDateEnd datetime, @Pax smallint, @IsWait smallint,@SVQUOTED smallint,
		@SdStateOld int, @SdStateNew int, @nHIID int, @dgCode nvarchar(10), @dlName nvarchar(max)

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
UPDATE ServiceByDate SET SD_State=4 WHERE SD_DLKey=@DLKey and SD_State is null

-- сохраним новое значение квотируемости
select @SdStateNew = MAX(SD_State)
from ServiceByDate
where SD_DLKey = @DLKey

-- запись в историю
if exists(select top 1 1 from SystemSettings where SS_ParmName like 'SYSServiceStatusToHistory' and SS_ParmValue = '1')
begin
	declare @sOldValue nvarchar(max), @sNewValue nvarchar(max)

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

GO
grant exec on [dbo].[DogListToQuotas] to public
go


/*********************************************************************/
/* end sp_DogListToQuotas.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwFillPriceListDetails.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwFillPriceListDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwFillPriceListDetails]
GO

CREATE PROCEDURE [dbo].[mwFillPriceListDetails](@tokey int = null)
AS
BEGIN
	declare @mwNeedFillPriceListDetails varchar(50)
	select @mwNeedFillPriceListDetails = ltrim(rtrim(isnull(SS_ParmValue, '0'))) from dbo.systemsettings with(nolock)
	where SS_ParmName = 'mwFillPriceListDetails'

	if @mwNeedFillPriceListDetails = '0'
		return

	if not @tokey is null
	begin
		-- наполним детализацию только по переданному туру
		if not exists(select 1 from PriceListDetails where pld_tokey = @tokey)
		begin
			insert into PriceListDetails(pld_tokey)
			values(@tokey)
		end

		-- наполним таблицу с детализацией тура
		update PriceListDetails
		set [PLD_HotelCityNames] = dbo.mwTourHotelCtNames(@tokey),
			[PLD_HotelKeys] = dbo.mwTourHotelKeys(@tokey),
			[PLD_HotelCityKeys] = dbo.mwTourHotelCtKeys(@tokey),
			[PLD_AirlineNames] = dbo.mwTourChNames(@tokey),
			[PLD_AirlineKeys] = dbo.mwTourChKeys(@tokey),
			[PLD_ServiceClassesNames] = dbo.mwGetServiceClassesNamesExtended (@tokey, ';', ',')
		where pld_tokey = @tokey
	end
	else
	begin
		-- наполним детализацию только по актульным турам без детализации
		declare @tourKeys table(tokey int)

		insert into @tourKeys(tokey)
		select to_key from tp_tours where to_isenabled = 1 and to_datevalid > getdate()
		and not exists(select 1 from PriceListDetails where pld_tokey = to_key)

		insert into PriceListDetails(pld_tokey)
		select tokey from @tourKeys

		-- наполним таблицу с детализацией тура
		update PriceListDetails
		set [PLD_HotelCityNames] = dbo.mwTourHotelCtNames(@tokey),
			[PLD_HotelKeys] = dbo.mwTourHotelKeys(@tokey),
			[PLD_HotelCityKeys] = dbo.mwTourHotelCtKeys(@tokey),
			[PLD_AirlineNames] = dbo.mwTourChNames(@tokey),
			[PLD_AirlineKeys] = dbo.mwTourChKeys(@tokey),
			[PLD_ServiceClassesNames] = dbo.mwGetServiceClassesNamesExtended (@tokey, ';', ',')
		where pld_tokey in (select tokey from @tourKeys)
	end
END
GO

GRANT EXEC ON [dbo].[mwFillPriceListDetails] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwFillPriceListDetails.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_FillMasterWebSearchFields.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FillMasterWebSearchFields]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[FillMasterWebSearchFields]
GO

CREATE procedure [dbo].[FillMasterWebSearchFields](@tokey int, @calcKey int = null, @forceEnable smallint = null)
-- if @forceEnable > 0 (by default) then make call mwEnablePriceTour @calcKey, 1 at the end of the procedure
as
begin

	set @forceEnable = isnull(@forceEnable, 1)

	if (@tokey is null)
	begin
		print 'Procedure does not support NULL param. You must specify @tokey parameter.'
		return
	end

	update dbo.TP_Tours set TO_Progress = 0 where TO_Key = @tokey

	if dbo.mwReplIsSubscriber() > 0
		exec dbo.mwFillTP @tokey, @calcKey

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
		where TI_CalculatingKey = @calcKey
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
				
			where TP_TOKey = TO_Key and hr_main > 0 and isnull(HR_AGEFROM, 100) > 16
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

	update #tp_lists with(rowlock)
	set
	-- MEG00024548 Paul G 11.01.2009
	-- изменил логику подсчёта кол-ва ночей в туре
	-- раньше было сумма ночей проживания по всем отелям в туре
	-- теперь если проживания пересекаются, лишние ночи не суммируются
		ti_nights = dbo.mwGetTiNights(ti_key)

	update TP_Tours with(rowlock) set TO_HotelNights = dbo.mwTourHotelNights(TO_Key) where TO_Key = @tokey

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
		
		insert into dbo.mwReplTours with(rowlock) (rt_trkey, rt_tokey, rt_add, rt_date)
		values (@trkey, @tokey, @calcKey, getdate())
		
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
		tt_tourhotels varchar(256) collate database_default
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

		-- Переписываем данные из временной таблицы и уничтожаем ее
		if @mwSearchType = 0
		begin
			if (@calcKey is not null)
			begin
				set @sql = 'delete from mwPriceDataTable with(rowlock) where pt_pricekey in (select tp_key from tp_prices with(nolock) where TP_CalculatingKey = ' + cast(@calcKey as nvarchar(20)) + ')'
				exec(@sql)
			end
			else
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

				if (@calcKey is not null)
				begin
					set @sql = 'delete from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' with(rowlock) where pt_pricekey in (select tp_key from tp_prices with(nolock) where TP_CalculatingKey = ' + cast(@calcKey as nvarchar(20)) + ')'
					exec(@sql)
				end
				else
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
		exec dbo.mwEnablePriceTour @tokey, 1, @calcKey

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
/* begin sp_GetCityDepartureKey.sql */
/*********************************************************************/
----------------------------------------------------
--- Create Storage Procedure GetCityDepartureKey ---
----------------------------------------------------

if exists(select id from sysobjects where id = OBJECT_ID('GetCityDepartureKey') and xtype = 'P')
	drop procedure dbo.GetCityDepartureKey
go

CREATE procedure GetCityDepartureKey 
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
			join airseason on as_chkey = ts_code
		where	ts_tokey = @tokey
			and	ts_svkey = 1
			and ts_day = (select min(TS_day) from tp_services where ts_tokey = @tokey and	ts_svkey = 1)

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
go

grant exec on dbo.GetCityDepartureKey to public
go




/*********************************************************************/
/* end sp_GetCityDepartureKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetPartnerCommission.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end sp_GetPartnerCommission.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetPricePage.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[sp_GetPricePage]') AND xtype in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetPricePage]
GO

CREATE PROCEDURE [dbo].[sp_GetPricePage]
     @TurKey   int,
     @MinID     int,
     @SizePage     int
AS

DECLARE @TP_PRICES AS TABLE(xTP_Key [int] NOT NULL PRIMARY KEY CLUSTERED, xTP_TIKEY [int])
insert into @TP_PRICES(xTP_Key,xTP_TIKEY) 
SELECT  TOP (@SizePage) TP_KEY, TP_TIKEY  
FROM TP_PRICES WITH(NOLOCK)
WHERE  TP_TOKEY = @TurKey 
   and TP_KEY > @MinID 
ORDER BY TP_KEY

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
	
	-- отдельно для стопов на объект квотирования только для алотмента
	INSERT INTO @QuotaLoadTemp (QT_ID, QT_PRKey, QT_ByRoom, QO_ID, QO_SubCode1, QO_SubCode2, QD_ID, QD_Date, QD_Type, QD_Release, QP_Places, QP_Busy, QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_IsNotCheckIn, QD_Comment, QP_Comment, QP_CheckInPlaces, QP_CheckInPlacesBusy)
	SELECT 0, 0, -1, QO_ID, QO_SubCode1, QO_SubCode2, -1, SS_Date, 1, NULL, 0, 0, -1, NULL, 0, 0, CASE SS_PRKey WHEN 0 THEN NULL ELSE SS_PRKey END, 0, SS_Comment, SS_Comment, 0, 0
	FROM	QuotaObjects join StopSales on QO_ID = SS_QOID
	WHERE	(QO_Code = @Service_Code and QO_SVKey = @Service_SVKey and QO_QTID is null)		
			and SS_Date between @DateStart and @DateEnd
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey = SS_PRKey or SS_PRKey = 0)))
			and ISNULL(SS_IsDeleted,0) = 0
			and (isnull(SS_AllotmentAndCommitment, 0) = 1 or isnull(SS_AllotmentAndCommitment, 0) = 0)
	ORDER BY SS_Date DESC, SS_ID
	
	-- отдельно для стопов на объект квотирования только для комитмента
	INSERT INTO @QuotaLoadTemp (QT_ID, QT_PRKey, QT_ByRoom, QO_ID, QO_SubCode1, QO_SubCode2, QD_ID, QD_Date, QD_Type, QD_Release, QP_Places, QP_Busy, QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, QP_IsNotCheckIn, QD_Comment, QP_Comment, QP_CheckInPlaces, QP_CheckInPlacesBusy)
	SELECT 0, 0, -1, QO_ID, QO_SubCode1, QO_SubCode2, -1, SS_Date, 2, NULL, 0, 0, -1, NULL, 0, 0, CASE SS_PRKey WHEN 0 THEN NULL ELSE SS_PRKey END, 0, SS_Comment, SS_Comment, 0, 0
	FROM	QuotaObjects join StopSales on QO_ID = SS_QOID
	WHERE	(QO_Code = @Service_Code and QO_SVKey = @Service_SVKey and QO_QTID is null)		
			and SS_Date between @DateStart and @DateEnd
			and (@Service_PRKey is null or (@Service_PRKey is not null and (@Service_PRKey = SS_PRKey or SS_PRKey = 0)))
			and ISNULL(SS_IsDeleted,0) = 0
			and isnull(SS_AllotmentAndCommitment, 0) = 1
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
/*********************************************************************/
/* end sp_GetQuotaLoadListData_N.sql */
/*********************************************************************/

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
		if exists (select SP_ID from dbo.ServicePrices with (nolock) where SP_ID = @nSPId)
			Set @bSPUpdate = 1

	if @bSPUpdate = 0
	BEGIN
		select	@nSPId = SP_ID, @netto = SP_Cost, @brutto = SP_Price, @discount = SP_PriceWithCommission
		from	dbo.ServicePrices
		with (nolock)
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

	SELECT @UseTypeDivisionMode = SS_ParmValue from dbo.SystemSettings with (nolock) where SS_ParmName = 'SYSUseCostTypeDivision'
	IF @UseTypeDivisionMode is not null and @UseTypeDivisionMode > 0
	BEGIN
		SELECT @UseTypeDivisionMode = COUNT(*) FROM tbl_costs
		with (nolock)
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
			with (nolock)              
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
			with (nolock)          
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

	If @FindCostByPeriod = 1 and ((@days between @CS_LongMin and @CS_Long) or @CS_Long is null) and @CS_DateEnd = (@date + @days) -- смотрим может есть цена за период точно совпадает с периодом действия услуги
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
						if @CS_Date <= @TMP_Date_Period and (@CS_Long is null or @CS_Long >= DATEDIFF(DAY,@TMP_Date_Period,@TMP_Date + @TMP_Number)) and (@CS_LongMin is null or @CS_LongMin <= DATEDIFF(DAY,@TMP_Date_Period,@TMP_Date + @TMP_Number))
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
				
				--koshelev MEG00034053
				if 1=1 --and (ISNULL(@CS_LongMin, 0) <= @days and ISNULL(@CS_Long, 999) >= @days) -- временная заглушка, 
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

/*********************************************************************/
/* end sp_GetServiceList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_InsDogList.sql */
/*********************************************************************/
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
	return 0

GO
grant exec on [dbo].[InsDogList] to public 
go

/*********************************************************************/
/* end sp_InsDogList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_InsertHistory.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsertHistory]') AND type in (N'P', N'PC'))
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
		FROM	dbo.tbl_DogovorList with (nolock)
		WHERE	DL_KEY = @nHI_DLKEY
	END

	EXEC dbo.CurrentUser @sHI_WHO output

	IF @nHI_DGKEY IS NULL AND @sHI_DGCOD IS NOT NULL
	BEGIN
		SELECT @nHI_DGKEY = DG_KEY 
		FROM dbo.tbl_Dogovor with (nolock)
		WHERE DG_CODE = @sHI_DGCOD
	END

	INSERT INTO dbo.History with (rowlock) (HI_DGCOD, HI_DGKEY, HI_DATE, HI_WHO, HI_TEXT, HI_MOD, HI_REMARK, HI_DLKEY, HI_SVKEY,
							 HI_CODE, HI_CODE1, HI_CODE2, HI_DAY, HI_NDAYS, HI_NMEN, HI_PRKEY)
	VALUES (@sHI_DGCOD, @nHI_DGKEY, GETDATE(), @sHI_WHO, @sHI_TEXT, @sHI_MOD, @sHI_REMARK, @nHI_DLKEY, @nHI_SVKEY,
			@nHI_CODE,  @nHI_CODE1, @nHI_CODE2, @nHI_DAY, @nHI_NDAYS, @nHI_NMEN, @nHI_PRKEY)

GO
grant exec on [dbo].[InsertHistory] to public
go


/*********************************************************************/
/* end sp_InsertHistory.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_InsertHistoryDetail.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsertHistoryDetail]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[InsertHistoryDetail]
GO
create PROCEDURE [dbo].[InsertHistoryDetail]
(
--<VERSION>2007.2.22.1</VERSION>
	@nHIID int,
	@nOAId int,
	@sValueOld varchar(255),
	@sValueNew varchar(255),
	@nIntValueOld int = null,
	@nIntValueNew int = null,
	@dtDateTimeValueOld datetime = null,
	@dtDateTimeValueNew datetime = null,
	@nInvisible int = 0,
	@bNeedCommunicationUpdate smallint = null output
)
as
	SET CONCAT_NULL_YIELDS_NULL OFF 

	declare @sAlias varchar(32), @sText varchar(255), @nCommunInfo smallint
	select @sAlias = left(OA_Alias, 32), @sText = OA_Name, @nCommunInfo=OA_CommunicationInfo from ObjectAliases with (nolock) where OA_Id = @nOAId
	If @nCommunInfo=1
		SET @bNeedCommunicationUpdate=1
	--print CAST(@nOAId as varchar(10)) + ' = ' + CAST(@nCommunInfo as varchar(10)) + ' / ' + CAST(@bNeedCommunicationUpdate as varchar(10))
	INSERT INTO dbo.HistoryDetail with (rowlock) (HD_HIID, HD_OAId, HD_Alias, HD_Text, HD_ValueOld, HD_ValueNew,
		HD_IntValueOld, HD_IntValueNew, HD_DateTimeValueOld, HD_DateTimeValueNew, HD_Invisible)
	VALUES (@nHIID, @nOAId, @sAlias, @sText, @sValueOld, @sValueNew,
		@nIntValueOld, @nIntValueNew, @dtDateTimeValueOld, @dtDateTimeValueNew, @nInvisible)

	SET CONCAT_NULL_YIELDS_NULL ON

GO
grant exec on [dbo].[InsertHistoryDetail] to public
go


/*********************************************************************/
/* end sp_InsertHistoryDetail.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_InsHistory.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsHistory]') AND type in (N'P', N'PC'))
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
		FROM dbo.tbl_Dogovor with(nolock)
		WHERE DG_CODE = @sDGCod
	END
	
	INSERT INTO dbo.History with(rowlock) (
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
grant exec on [dbo].[InsHistory] to public
go

/*********************************************************************/
/* end sp_InsHistory.sql */
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
/* begin sp_mwAutobusQuotes.sql */
/*********************************************************************/
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
	-- MEG00030302. Golubinsky. 07.06.2011 
	[TourMessage] varchar (1024) null,
	-- MEG00030302 end
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
'select '''' as TourMessage, pt_cnkey,pt_tourdate,
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
declare @TourKey int
declare @TourMessage varchar (1024)
declare @TurListKey int


DECLARE hSql CURSOR 
	FOR 
		SELECT HotelKey, RoomKey, RoomCategoryKey,TourDate,HotelPartnerKey,HotelDay,HotelNights,TourDuration,TourKey,TourMessage,TurListKey FROM #tmp
	FOR UPDATE OF QuotaPlaces, QuotaAllPlaces, TourMessage

OPEN hSql
FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey, @FromDate, @HotelPartnerKey, @HotelDay,@HotelNights,@TourDuration,@TourKey,@TourMessage,@TurListKey


declare @qt_places int
declare @qt_allplaces int
declare @qt_tourMessage varchar (1024)

WHILE @@FETCH_STATUS = 0
BEGIN	
	select top 1 @qt_places = qt_places,@qt_allplaces = qt_allplaces from mwCheckQuotesEx(3, @HotelKey, @RoomKey, @RoomCategoryKey, @AgentKey, @HotelPartnerKey, @FromDate, @HotelDay, @HotelNights, @RequestOnRelease, @NoPlacesResult, @CheckAgentQuotes, @CheckCommonQuotes, 1, 0, 0, 0, 0, @TourDuration, @ExpiredReleaseResult)
	
	-- MEG00030302. Golubinsky. 07.06.2011
	SET @qt_tourMessage = ''
	SELECT TOP 1 @qt_tourMessage = MS_Text
	FROM [Messages] with (nolock) WHERE (( @FromDate between MS_ServiceDateBeg AND MS_ServiceDateEnd) AND MS_IsDeleted IS NULL OR MS_IsDeleted = 0) AND MS_LGId IN
			(SELECT DISTINCT LM_LGId FROM LimitationGroups, Limitations, LimitationTours WITH (NOLOCK)
				WHERE LM_ID = LD_LMId AND LG_ID = LM_LGId AND LD_TRKey = @TurListKey
										--AND (LG_IsDeleted IS NULL OR LG_IsDeleted = 0)
										--AND (LM_IsDeleted IS NULL OR LM_IsDeleted = 0) 
										--AND (LD_IsDeleted IS NULL OR LD_IsDeleted = 0) 
										--AND ((LD_TRKey IN (SELECT TL_KEY FROM TurList WITH (NOLOCK) WHERE TL_TIP = 0)
										--		OR LD_TRKey IS NULL) AND (LD_TRKey = @TurListKey OR LD_TRKey IS NULL))
												)
	ORDER BY MS_ServiceDateBeg, MS_ServiceDateEnd ASC
	-- MEG00030302 end
	
	UPDATE #tmp SET QuotaPlaces = @qt_places, QuotaAllPlaces = @qt_allplaces, TourMessage = @qt_tourMessage
		WHERE current of hSql
		
	FETCH NEXT FROM hSql INTO @HotelKey, @RoomKey, @RoomCategoryKey, @FromDate, @HotelPartnerKey, @HotelDay,@HotelNights,@TourDuration,@TourKey,@TourMessage,@TurListKey
END
CLOSE hSql
DEALLOCATE hSql

select * from #tmp

drop table #tmp
drop table #tmp1

GO

grant exec on [dbo].[mwAutobusQuotes] to public
go
/*********************************************************************/
/* end sp_mwAutobusQuotes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCheckFlightGroupsQuotesWithInnerFlights.sql */
/*********************************************************************/
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
	while (len(@linkedcharters) > 0 and (charindex(',', @linkedcharters, @curPosition + 1) > 0 or @flag = 0))
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
/*********************************************************************/
/* end sp_mwCheckFlightGroupsQuotesWithInnerFlights.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCreatePriceView.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwCreatePriceView')
	drop proc dbo.mwCreatePriceView
go

create procedure [dbo].[mwCreatePriceView] @countryKey int, @cityFromKey int
as
begin
	declare @viewName varchar(50)
	set @viewName = dbo.mwGetPriceViewName(@countryKey, @cityFromKey)
	if not exists(select id from sysobjects where id = OBJECT_ID(@viewName) and xtype = 'V ')
	begin
		declare @sql varchar(8000)
		set @sql = 'create view ' + @viewName + ' as select * from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' with(nolock) where pt_isenabled > 0 and pt_tourvalid >= getdate()'
		exec(@sql)
		set @sql = 'grant select on ' + @viewName + ' to public'
		exec(@sql)
	end
end

grant exec on [dbo].[mwCreatePriceView] to public
go
/*********************************************************************/
/* end sp_mwCreatePriceView.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwEnablePriceTour.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwEnablePriceTour]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwEnablePriceTour]
GO

CREATE procedure [dbo].[mwEnablePriceTour] @tourkey int, @enabled smallint, @calcKey int = null
as
begin

--<VERSION>2009.1</VERSION>
--<DATE>2011-10-04</DATE>

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
					' + @tableName + '.pt_isenabled > 0 and exists(select 1 from ' + @tableName + ' tweb with(nolock)
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
					

				set @sql = 'select distinct pt_tourkey from ' + @tableName + ' with (nolock) ' + @sqlWhere

				insert into #tmpTours exec(@sql)
				create index x_tmptokey on #tmpTours (tourkey)

				-- заполним таблицу с ценами, которые нужно выключить
				create table #tmpPricesOff(pt_pricekey int)
				set @sql = 'select pt_pricekey from ' + @tableName + ' with (nolock) ' + @sqlWhere
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
				where '+ @tableName + '.pt_pricekey in (select pt_pricekey from #tmpPricesOff) and not exists (select 1 from '
				+@tableName + ' where '+@tableName+'.pt_tourdate = updturdates.td_date and '+@tableName+'.pt_isenabled=1 
				and '+@tableName+'.pt_tourkey = updturdates.td_tokey)'


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
GO

GRANT EXEC ON [dbo].[mwEnablePriceTour] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwEnablePriceTour.sql */
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
	declare @sql varchar(4000)
	declare @source varchar(200)
	set @source = ''

	declare @tokeyStr varchar (20)
	set @tokeyStr = cast(@tokey as varchar(20))

	declare @calcKeyStr varchar (20)
	set @calcKeyStr = cast(@calcKey as varchar(20))

	if dbo.mwReplIsSubscriber() > 0 and len(dbo.mwReplPublisherDB()) > 0
		set @source = '[mt].[' + dbo.mwReplPublisherDB() + '].'
	
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
			set @sql = @sql + 'TD_CalculatingKey = ' + @calcKeyStr
		else
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
		if(@calcKey is not null)
			set @sql = @sql + 'TS_CalculatingKey = ' + @calcKeyStr
		else
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
			set @sql = @sql + 'TI_CalculatingKey = ' + @calcKeyStr
		else
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

		if(@calcKey is not null)
			set @sql = @sql + 'TL_CalculatingKey = ' + @calcKeyStr
		else
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
/* begin sp_mwGetSearchFilter.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwGetSearchFilter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[mwGetSearchFilter]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[mwGetSearchFilter]
	@datesInterval int = 30,
	@availableDepartFromCityKeys varchar(100) = '',
	@availableCountryKeys varchar(100) = '',
	@availableTourTypeKeys varchar(100) = '',
	@availableResortKeys varchar(100) = '',
	@availableCityKeys varchar(100) = '',
	@availableTourKeys varchar(100) = '',
	@availableHotelKeys varchar(100) = ''
AS
BEGIN
	SET NOCOUNT ON;
	
	declare @sql varchar (MAX)
	set @sql = '
SELECT 
sd_key AS [Key],
sd_tourkey AS PriceTourKey, 
TO_Name AS PriceTourName, 
sd_cnkey AS CountryKey,
CN_NAME AS CountryName, 
sd_hdkey AS HotelKey, 
HD_NAME + '' '' + HD_STARS AS HotelName, 
HD_STARS AS HotelStars, 
sd_ctkey AS CityKey,
(SELECT TOP (1) CT_NAME FROM dbo.CityDictionary WITH (nolock) WHERE (CT_KEY = sd_ctkey)) AS CityName, 
isnull(sd_rskey,-1) AS ResortKey, 
isnull(RS_NAME,'''') AS ResortName,
sd_tlkey AS TourKey, 
sd_ctkeyfrom AS DepartureFromCityKey, 
ISNULL ((SELECT TOP (1) CT_NAME FROM dbo.CityDictionary WITH (nolock) WHERE CT_KEY = sd_ctkeyfrom), ''-Без перелета-'') AS DepartureFromCityName,
isnull(sd_ctkeyto,-1) AS DepartureToCityKey,
isnull((SELECT TOP (1) CT_NAME FROM dbo.CityDictionary WITH (nolock) WHERE CT_KEY = sd_ctkeyto), '''') AS DepartureToCityName, 
sd_tourtype AS TourTypeKey, 
TP_NAME AS TourTypeName,
sd_pnkey AS PansionKey,
PN_CODE AS PansionCode, 
isnull(HD_HTTP, '''') AS HotelUrl,
isnull(rm_key, -1) as RoomKey,
isnull(rm_name, '''') as RoomName
FROM 
dbo.mwSpoDataTable WITH (nolock) INNER JOIN
dbo.TP_Tours WITH (nolock) ON TO_Key = sd_tourkey INNER JOIN
dbo.tbl_Country WITH (nolock) ON CN_KEY = sd_cnkey INNER JOIN
dbo.HotelDictionary WITH (nolock) ON HD_KEY = sd_hdkey INNER JOIN
dbo.CityDictionary WITH (nolock) ON CT_KEY = sd_ctkey INNER JOIN
dbo.TipTur WITH (nolock) ON TP_KEY = sd_tourtype INNER JOIN
dbo.Pansion WITH (nolock) ON PN_KEY = sd_pnkey
left join rooms with(nolock) on rm_key in (select mwPriceHotels.sd_rmkey from mwPriceHotels with(nolock) where mwPriceHotels.ph_sdkey = sd_key)
 LEFT JOIN
dbo.Resorts WITH (nolock) ON RS_KEY = sd_rskey
WHERE sd_isenabled > 0 AND EXISTS(select TOP (1) 1 from dbo.TP_TurDates WITH (nolock) where TD_TOKey = sd_tourkey
AND TD_Date > DATEADD(DAY, - 1, GETDATE())
AND TD_Date < DATEADD(DAY, '+ str(@datesInterval) +', GETDATE()))'
		
	declare @whereClause varchar (MAX)
	set @whereClause = ''
	
	if (len(@availableDepartFromCityKeys) > 0)
	begin
		set @whereClause = @whereClause + ' sd_ctkeyfrom IN (' + @availableDepartFromCityKeys + ')'
	end
	if (len(@availableCountryKeys) > 0)
	begin
		if (len(@whereClause) > 0)
		begin
			set @whereClause = @whereClause + ' AND '
		end
		set @whereClause = @whereClause + ' sd_cnkey IN (' + @availableCountryKeys + ')'
	end
	if (len(@availableTourTypeKeys) > 0)
	begin
	if (len(@whereClause) > 0)
		begin
			set @whereClause = @whereClause + ' AND '
		end
		set @whereClause = @whereClause + ' sd_tourtype IN (' + @availableTourTypeKeys + ')'
	end
	if (len(@availableCityKeys) > 0)
	begin
	if (len(@whereClause) > 0)
		begin
			set @whereClause = @whereClause + ' AND '
		end
		set @whereClause = @whereClause + ' sd_ctkey IN (' + @availableCityKeys + ')'
	end
	if (len(@availableResortKeys) > 0)
	begin
	if (len(@whereClause) > 0)
		begin
			set @whereClause = @whereClause + ' AND '
		end
		set @whereClause = @whereClause + ' sd_rskey IN (' + @availableResortKeys + ')'
	end
	if (len(@availableTourKeys) > 0)
	begin
	if (len(@whereClause) > 0)
		begin
			set @whereClause = @whereClause + ' AND '
		end
		set @whereClause = @whereClause + ' sd_tourkey IN (' + @availableTourKeys + ')'
	end
	if (len(@availableHotelKeys) > 0)
	begin
	if (len(@whereClause) > 0)
		begin
			set @whereClause = @whereClause + ' AND '
		end
		set @whereClause = @whereClause + ' sd_hdkey IN (' + @availableHotelKeys + ')'
	end
		
	if (len(@whereClause) > 0)
	begin
		set @sql = @sql + ' AND ' +@whereClause
	end
	--print (@whereClause)
	--print '--------------'
	--print (@sql)
	exec(@sql)
END
GO

SET QUOTED_IDENTIFIER OFF
GO

GRANT EXEC ON [dbo].[mwGetSearchFilter] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwGetSearchFilter.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetSearchFilterDates.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[mwGetSearchFilterDates]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mwGetSearchFilterDates]
GO

/****** Object:  StoredProcedure [dbo].[mwGetSearchFilterDates]    Script Date: 10/20/2011 11:17:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[mwGetSearchFilterDates]
	@tourKeys varchar(1000) = '',
	@datesInterval int = 30
AS
BEGIN	
	SET NOCOUNT ON;

    declare @sql varchar(6000)	
	
	set @sql = '
	SELECT DISTINCT convert(varchar(10),td_date, 101) as Date, substring(tourkeys,1,len(tourkeys)-1) as TourKeys
	FROM tp_turdates t1
	CROSS APPLY ( 
		SELECT ltrim(rtrim(str(td_tokey))) + '',''
		FROM tp_turdates t2
		WHERE t2.td_date = t1.td_date '+
		case when len(@tourKeys) > 0 
		then 'and td_tokey in (' + @tourKeys + ') '
		else '' end
		+'
		AND td_date > DATEADD(DAY,-1,GETDATE()) AND td_date <= DATEADD(DAY,'+ str(@datesInterval) + ',GETDATE()) 
		ORDER BY td_tokey 
		FOR XML PATH('''') )  D ( tourkeys )
	WHERE tourkeys is not null
	ORDER BY convert(varchar(10),td_date, 101)'
	print (@sql)
	exec(@sql)
END

GO

GRANT EXECUTE ON [dbo].[mwGetSearchFilterDates] TO [public]
GO
/*********************************************************************/
/* end sp_mwGetSearchFilterDates.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetSearchFilterDirectionData.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwGetSearchFilterDirectionData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[mwGetSearchFilterDirectionData]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[mwGetSearchFilterDirectionData]
	@datesInterval int = 30,
	@departFromKeys varchar(100) = null,
	@countryKeys varchar(100) = null,
	@tourTypeKeys varchar(100) = null
AS
BEGIN
	SET NOCOUNT ON;	
	declare @whereClause varchar (1000)
	declare @sql varchar (2000)
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
dbo.HotelDictionary WITH (nolock) ON HD_KEY = sd_hdkey INNER JOIN
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


SET QUOTED_IDENTIFIER OFF
GO

GRANT EXEC ON [dbo].[mwGetSearchFilterDirectionData] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwGetSearchFilterDirectionData.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetSearchFilterNights.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[mwGetSearchFilterNights]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mwGetSearchFilterNights]
GO

/****** Object:  StoredProcedure [dbo].[mwGetSearchFilterNights]    Script Date: 10/20/2011 11:34:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[mwGetSearchFilterNights]
	@tourKeys varchar(100) = ''
AS
BEGIN	
	SET NOCOUNT ON;
    
	declare @sql varchar(500)	
	
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
		+'ORDER BY sd_tourkey 
		FOR XML PATH('''') )  D ( tourkeys )
	WHERE tourkeys is not null
	ORDER BY sd_nights'
	
	exec(@sql)
END

GO

GRANT EXECUTE ON [dbo].[mwGetSearchFilterNights] TO [public]
GO
/*********************************************************************/
/* end sp_mwGetSearchFilterNights.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetServiceVariants.sql */
/*********************************************************************/
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
	
	if (isnull(@serviceDays, 0)<=0 and @svKey != 3 and @svKey != 8)
		Set @serviceDays = 1
		
	declare @selectClause varchar(300)
	set		@selectClause = ' SELECT cs1.CS_Code, cs1.CS_SubCode1, cs1.CS_SubCode2, cs1.CS_PrKey, cs1.CS_PkKey, cs1.CS_Profit, cs1.CS_Type, cs1.CS_Discount, cs1.CS_Creator, cs1.CS_Rate, cs1.CS_Cost '
	
	declare @fromClause varchar(300)
	set		@fromClause   = ' FROM COSTS cs1 WITH(NOLOCK) '
	set		@additionalFilter = replace(@additionalFilter, 'CS_', 'cs1.CS_')
				
	declare @whereClause varchar(6000)
		set @whereClause  = ''
		
	declare @orderClause varchar(100)
		set @orderClause  =  'cs1.CS_long'
	
	--MEG00027493 Paul G 15.07.2010
	if (@showCalculatedCostsOnly=1)
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
	
	set @whereClause = @whereClause + ' cs1.CS_SVKEY = ' + CAST(@svKey as varchar)
	set @whereClause = @whereClause + ' AND cs1.CS_PKKEY = '+cast(@pkKey as varchar)
	set @whereClause = @whereClause + ' AND ''' + @dateBegin + ''' BETWEEN ISNULL(cs1.CS_CHECKINDATEBEG, ''1900-01-01'') AND ISNULL(cs1.CS_CHECKINDATEEND, ''9000-01-01'') ' + @additionalFilter
	
	if (@svKey=1)
	begin			
		set @whereClause = @whereClause + ' AND ' + cast(@tourNDays as varchar) + ' between isnull(cs1.CS_longmin, -1) and isnull(cs1.CS_LONG, 10000) '-- MEG00029229 Paul G 13.10.2010
				
		set @whereClause = @whereClause + ' AND EXISTS (SELECT CH_KEY FROM CHARTER WITH(NOLOCK)' 
										+ ' WHERE CH_KEY = cs1.CS_CODE AND CH_CITYKEYFROM = ' + cast(@cityFromKey as varchar) + ' AND CH_CITYKEYTO = '+cast(@cityToKey as varchar)+')'
		-- Filter on day of week
		set @whereClause = @whereClause + ' AND (cs1.CS_WEEK is null or cs1.CS_WEEK = '''' or cs1.CS_WEEK like dbo.GetWeekDays(''' + @dateBegin + ''',''' + @dateBegin + '''))'
		-- Filter on CHECKIN DATE		
	end
	else 
	begin
		if (@serviceDays>1)
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
	end
	
	set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATE,    ''1900-01-01'') <= ''' + @dateBegin + ''''
	set @whereClause = @whereClause + ' AND ISNULL(cs1.CS_DATEEND, ''9000-01-01'') >= ''' + @dateBegin + ''''

	exec (@selectClause + @fromClause + ' WHERE ' + @whereClause + ' ORDER BY '+ @orderClause)
end
go

grant exec on dbo.mwGetServiceVariants to public
go

/*********************************************************************/
/* end sp_mwGetServiceVariants.sql */
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
		
	declare @pdtUpdatePackageSize int
	set @pdtUpdatePackageSize = (select count(*) from mwPriceDataTable with(nolock)) * @updatePackageSize / 100.0

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
/* begin sp_NationalCurrencyPrice2.sql */
/*********************************************************************/
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
      declare @currencyKey int
      select top 1 @currencyKey = RA_KEY, @national_currency = RA_CODE from Rates where RA_National = 1

      declare @rc_course money
      declare @rc_courseStr char(30)

	  set @rc_course = -1
	  
	  select top 1 @rc_courseStr = RC_COURSE from RealCourses
	  where RC_RCOD1 = @national_currency and RC_RCOD2 = @sRate
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
                  DG_NATIONALCURRENCYDISCOUNTSUM = @rc_course * @nDiscountSum,
                  DG_CurrencyRate = @rc_course,
                  DG_CurrencyKey = @currencyKey
            where
                  DG_CODE = @sDogovor
      end
      else
      begin
            update dbo.tbl_Dogovor
            set
                  DG_NATIONALCURRENCYPRICE = null,
                  DG_NATIONALCURRENCYDISCOUNTSUM = null/*,
                  DG_CurrencyRate = null,
                  DG_CurrencyKey = @currencyKey*/
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

/*********************************************************************/
/* end sp_NationalCurrencyPrice2.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_QuotaPartsAfterDelete.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotaPartsAfterDelete]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[QuotaPartsAfterDelete]
GO

CREATE PROCEDURE [dbo].[QuotaPartsAfterDelete]
AS
--version 9.2.9.1
--data 2011-10-26
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
				
-- пробуем сажать
DECLARE @SD_DLKey int
DECLARE cur_QuotaPartsDelete CURSOR FORWARD_ONLY FOR
	select distinct SD_DLKey
	from ServiceByDate
	where SD_State in (1, 2)
	and exists (select 1
				from QuotaParts 
				where QP_ID = SD_QPID
				and QP_IsDeleted = 1)
	
OPEN cur_QuotaPartsDelete
FETCH NEXT FROM cur_QuotaPartsDelete INTO @SD_DLKey
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC dbo.DogListToQuotas @SD_DLKey
	FETCH NEXT FROM cur_QuotaPartsDelete INTO @SD_DLKey
END
CLOSE cur_QuotaPartsDelete
DEALLOCATE cur_QuotaPartsDelete


-- ставим на Request
update ServiceByDate
set SD_State = 4, SD_QPID = null
where exists (select 1
				from QuotaParts 
				where QP_ID = SD_QPID
				and QP_IsDeleted = 4)
				
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
delete from StopSales where SS_QDID in (SELECT DQDID FROM @DelQPID)
-- только те QuotaDetails которые есть в нашем списке и на них нету записей в QuotaParts
DELETE FROM QuotaDetails 
WHERE QD_ID in (SELECT DQDID FROM @DelQPID)
and not exists (select 1 from QuotaParts where QP_QDID = QD_ID)

DELETE FROM StopSales 
WHERE SS_QDID in (SELECT DQDID FROM @DelQPID)
and not exists (select 1 from QuotaDetails where QD_ID = SS_QDID)
GO

grant exec on [dbo].[QuotaPartsAfterDelete] to public
go



/*********************************************************************/
/* end sp_QuotaPartsAfterDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetReservationStatus.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end sp_SetReservationStatus.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetServiceQuotasStatus.sql */
/*********************************************************************/
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



/*********************************************************************/
/* end sp_SetServiceQuotasStatus.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetServiceStatusOK.sql */
/*********************************************************************/
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
			where SD_DLKey = @dlkey),4) < 4
		and exists(select top 1 1
					from Dogovorlist 
					where DL_KEY = @dlkey
					and DL_SvKey = 1 and DL_Control != 0)
	begin
		set @dlcontrol = 0
	end
	
	-- Проживание
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('4', '5', '6', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @dlkey),4) < 4
		and exists (select top 1 1
					from Dogovorlist 
					where DL_KEY = @dlkey
					and DL_SvKey = 3 and DL_Control != 0)
	begin
		set @dlcontrol = 0
	end
	
	-- Все услуги
	if exists(select 1 from SystemSettings where SS_ParmName = 'SYS_SET_SERVICE_STATUS_OK' and SS_ParmValue in ('1', '3', '5', '7'))
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @dlkey),4) < 4
		and exists (select top 1 1
					from Dogovorlist 
					where DL_KEY = @dlkey
					and DL_SvKey != 3 
					and DL_SvKey != 1
					and DL_Control != 0)
	begin
		set @dlcontrol = 0
	end
	
	-- MEG00032041
	-- Теперь проверим есть ли на эту квоту запись в таблице QuotaStatuses
	-- которая говорит нам что нужно изменить статус услуги на тот который в этой таблице
	if exists(select 1 
				from QuotaStatuses join Quotas on QS_QTID = QT_ID 
				join QuotaDetails on QT_ID = QD_QTID
				join QuotaParts on QP_QDID = QD_ID
				join ServiceByDate on SD_QPID = QP_ID
				where SD_DLKey = @dlkey and SD_State = QS_Type) 
		and isnull((select max(isnull(SD_State, 4)) 
			from ServiceByDate 
			where SD_DLKey = @dlkey),4) < 4
	begin
		declare @tempDlControl int
	
		select @tempDlControl = QS_CRKey
		from QuotaStatuses join Quotas on QS_QTID = QT_ID 
		join QuotaDetails on QT_ID = QD_QTID
		join QuotaParts on QP_QDID = QD_ID
		join ServiceByDate on SD_QPID = QP_ID
		where SD_DLKey = @dlkey and SD_State = QS_Type
				
		if exists(select top 1 1
					from Dogovorlist 
					where DL_KEY = @dlkey
					and DL_Control != @tempDlControl)
		begin
			set @dlcontrol = @tempDlControl
		end
	end
	
	-- если наша услуга вне квоты, то установим ей статус из справочника услуг
	if (isnull((select max(isnull(SD_State, 4)) 
				from ServiceByDate 
				where SD_DLKey = @dlkey),4) = 4
		and exists (select top 1 1 
					from Dogovorlist 
					where DL_KEY = @dlkey
					and DL_Control != (select top 1 SV_CONTROL from [Service] where DL_SVKEY = SV_KEY)
					and exists (select top 1 1 from [Service] where DL_SVKEY = SV_KEY and isnull(SV_QUOTED, 0) = 1)))
	begin		
		select @dlcontrol = SV_CONTROL
		from Dogovorlist join [Service] on DL_SVKEY = SV_KEY
		where DL_KEY = @dlkey
	end
END
GO
grant exec on [dbo].[SetServiceStatusOK] to public
go

/*********************************************************************/
/* end sp_SetServiceStatusOK.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetStatusInRoom.sql */
/*********************************************************************/
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
	declare @ServiceHotelKey int -- ключ услуги проживание
	set @ServiceHotelKey = 3
	
	create table #DlKeys
	(
		dlKey int
	)
	
	insert into #DLKeys
		select dl_key 
		from dogovorlist 
		where dl_dgkey in (
							select dl_dgkey 
							from dogovorlist 
							where dl_key = @DLKey
						   )
		and dl_svkey = @ServiceHotelKey
	
	update ServiceByDate
	set SD_State = 3
	from ServiceByDate as SBD1 join RoomPlaces as RP1 on SBD1.SD_RPID = RP1.RP_ID
	where RP1.RP_Type = 1 and sd_dlkey in (select dlKey from #DLKeys)
	and ISNULL((select MAX (SD_State)
					from ServiceByDate as SBD2 join RoomPlaces as RP2 on SBD2.SD_RPID = RP2.RP_ID
					where RP2.RP_Type = 0 and sd_dlkey in (select dlKey from #DLKeys) 
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
					where RP2.RP_Type = 0 and sd_dlkey in (select dlKey from #DLKeys)
					and SBD2.SD_RLID = SBD1.SD_RLID), 4) = 4
	and SBD1.SD_RLID in (select SBD3.SD_RLID
							from ServiceByDate as SBD3
							where SBD3.SD_DLKey = @DlKey)
							
	drop table #DLKeys
END

GO

grant exec on [dbo].[SetStatusInRoom] to public
go

/*********************************************************************/
/* end sp_SetStatusInRoom.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_UpdateReservationMainMan.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end sp_UpdateReservationMainMan.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_UpdateReservationMainManByPartnerUser.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end sp_UpdateReservationMainManByPartnerUser.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_UpdateReservationMainManByTourist.sql */
/*********************************************************************/
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

/*********************************************************************/
/* end sp_UpdateReservationMainManByTourist.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_DogovorListRequestStatus.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end fn_DogovorListRequestStatus.sql */
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

/*********************************************************************/
/* end fn_mwCheckQuotesEx2.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwGetVisaDeadlineDate.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='fn' and name='mwGetVisaDeadlineDate')
	drop function dbo.mwGetVisaDeadlineDate
GO

CREATE FUNCTION [dbo].[mwGetVisaDeadlineDate](@tlKey INTEGER, @arrivalDate datetime, @ctKey INTEGER)
RETURNS DATETIME
AS
BEGIN	
	declare @result datetime
	declare @pkkey int
	
	select @pkkey = ts_pkkey
	from turservice (nolock)
	where ts_svkey = 5 and ts_trkey = @tlKey

	select @result = max(CD_DeadLineAgencyDate)
	from costs (nolock)
		inner join CalendarDeadLines (nolock) on cd_slkey = cs_code
	where cs_pkkey = @pkkey and cs_svkey = 5 and cd_arrivaldate = @arrivalDate and cd_ctkey = @ctKey

	return @result
END
GO

grant exec on [dbo].[mwGetVisaDeadlineDate] to public
GO
/*********************************************************************/
/* end fn_mwGetVisaDeadlineDate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin x_calculatingpricelists.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end x_calculatingpricelists.sql */
/*********************************************************************/

/*********************************************************************/
/* begin X_HI_Mod.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[History]') AND name = N'X_HI_Mod')
DROP INDEX [X_HI_Mod] ON [dbo].[History] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [X_HI_Mod] ON [dbo].[History] 
(
	[HI_DGCOD] ASC,	
	[HI_MessEnabled] ASC	 
) include ([HI_MOD], [HI_DATE]) with (fillfactor = 70)
GO

/*********************************************************************/
/* end X_HI_Mod.sql */
/*********************************************************************/

/*********************************************************************/
/* begin x_mappings.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end x_mappings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin x_tp_flights.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_tp_flights_calc1')
     DROP INDEX TP_Flights.x_tp_flights_calc1
GO
CREATE NONCLUSTERED INDEX [x_tp_flights_calc1] ON [dbo].[TP_Flights] 
(
	[TF_TOKey] ASC,
	[TF_CodeOld] ASC,
	[TF_PRKeyOld] ASC,
	[TF_Date] ASC,
	[TF_Days] ASC
)
INCLUDE
(
	[TF_CodeNew],
	[TF_PRKeyNew]
)
GO
/*********************************************************************/
/* end x_tp_flights.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20110624)Alter_Table_TipTur.sql */
/*********************************************************************/
IF NOT EXISTS 
	(SELECT * FROM dbo.sysobjects tbl
		inner join dbo.syscolumns col
		on col.id = tbl.id
		WHERE tbl.id = object_id(N'[dbo].[TipTur]') AND col.name = N'TP_Order')
BEGIN
	
	alter table [dbo].[TipTur]
	add [TP_Order] int null
	
END

GO

if not exists (select 1 from sysobjects where name = 'DF_TP_Order' and xtype = 'D')
ALTER TABLE [dbo].[TipTur] ADD  CONSTRAINT [DF_TP_Order]  DEFAULT ((1000)) FOR [TP_Order]

GO
/*********************************************************************/
/* end (20110624)Alter_Table_TipTur.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110617(AddColumnsTo_VisaTouristService).sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM dbo.syscolumns WHERE id = object_id(N'[dbo].[VisaTouristService]') AND name = 'VTS_ResultChangeDate')
BEGIN
	ALTER TABLE dbo.VisaTouristService ADD
		VTS_ResultChangeDate smalldatetime NULL
END
GO

IF NOT EXISTS (SELECT * FROM dbo.syscolumns WHERE id = object_id(N'[dbo].[VisaTouristService]') AND name = 'VTS_IsCheckedChangeDate')
BEGIN
	ALTER TABLE dbo.VisaTouristService ADD	
		VTS_IsCheckedChangeDate smalldatetime NULL
END
GO
/*********************************************************************/
/* end 110617(AddColumnsTo_VisaTouristService).sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110615_Alter_tbl_DogovorList_add_DL_CreateDate.sql */
/*********************************************************************/
if not exists (select 1 from dbo.syscolumns 
			   where name = 'DL_CreateDate' 
				 and id = object_id(N'[dbo].[tbl_DogovorList]'))
	begin
		ALTER TABLE dbo.tbl_DogovorList add DL_CreateDate datetime not null default getdate()
		exec sp_RefreshViewForAll 'DogovorList'
	end
go

/*********************************************************************/
/* end 110615_Alter_tbl_DogovorList_add_DL_CreateDate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_LogApplicationEvents.sql */
/*********************************************************************/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[LogApplicationEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[LogApplicationEvents]
GO

CREATE PROCEDURE [dbo].[LogApplicationEvents]
-- <Version>1.0.0.0 </Version>
-- <CreateDate> 15.03.2011 </CreateDate>
(
@Actionid int,
@Succeed bit,
@UserId nvarchar(50),
@Name nvarchar(200)  
)
AS
begin
	insert into dbo.ApplicationLogs(AL_CreateDate,AL_ACTionID,AL_Succeed,AL_USERID,AL_NAME,AL_Host)
	values (GETDATE(),@Actionid,@Succeed,@UserId,@Name,HOST_NAME())
end
GO

grant exec on [dbo].[LogApplicationEvents] to public 
GO


/*********************************************************************/
/* end sp_LogApplicationEvents.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.06.27)Create_Index.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotaObjects]') AND name = N'X_QuotaObjects')
DROP INDEX [X_QuotaObjects] ON [dbo].[QuotaObjects] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_QuotaObjects] ON [dbo].[QuotaObjects] 
(
	[QO_SVKey] ASC,
	[QO_Code] ASC
)
INCLUDE ( [QO_SubCode1],
[QO_SubCode2]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Mappings]') AND name = N'X_Mappings')
DROP INDEX [X_Mappings] ON [dbo].[Mappings] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_Mappings] ON [dbo].[Mappings] 
(
	[MP_TableID] ASC,
	[MP_IntKey] ASC,
	[MP_PRKey] ASC
)
INCLUDE ( [MP_Key],
[MP_CharKey],
[MP_Value],
[MP_StrValue],
[MP_CreateDate]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[StopSales]') AND name = N'X_StopSales')
DROP INDEX [X_StopSales] ON [dbo].[StopSales] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_StopSales] ON [dbo].[StopSales] 
(
	[SS_QOID] ASC,
	[SS_QDID] ASC
)
INCLUDE ( [SS_PRKey],
[SS_AllotmentAndCommitment]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[VisaTouristService]') AND name = N'X_VisaTouristService')
DROP INDEX [X_VisaTouristService] ON [dbo].[VisaTouristService] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_VisaTouristService] ON [dbo].[VisaTouristService] 
(
	[VTS_TUIDKEY] ASC
)
INCLUDE ( [VTS_ID],
[VTS_DocCompleteDate],
[VTS_ToEmbassy],
[VTS_FromEmbassy],
[VTS_Result]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO



/*********************************************************************/
/* end (11.06.27)Create_Index.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetMinNearestTourPrices.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwGetMinNearestTourPrices]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mwGetMinNearestTourPrices]
GO

-- =============================================
-- Author:		Golubinsky
-- Create date: 29.06.2011
-- Description:	Возвращает минимальные цены по туру на ближайшую дату
-- =============================================
CREATE PROCEDURE [dbo].[mwGetMinNearestTourPrices] 
(
	@TourListKey int, 
	@RoomTypeKey int = null
)
AS
BEGIN

	CREATE TABLE #result
	(
			[HotelKey] int					-- ключ отеля
			,[HotelName] nvarchar(100)		-- название отеля
			,[HotelCategory] nvarchar(100)	-- категория отеля
			,[TourMinPrice] decimal			-- минимальная цена
			,[Nights] int					-- количество ночей
			,[Days] int						-- количество дней
			,[Pansion] nvarchar(100)		-- питание в отеле
			,[PansionKey] int				-- ключ питания в отеле
			,[TourDate] datetime			-- дата заезда
			,[TourKey] int					-- ключ рассчитанного тура
	)
	
	-- проверка секционированности таблицы цен туров
	DECLARE @mwSearchType AS INT
	SELECT @mwSearchType=isnull(SS_ParmValue,1) FROM dbo.systemsettings 
	WHERE SS_ParmName='MWDivideByCountry'
	
	-- имя таблицы поиска
	DECLARE @searchTableName AS NVARCHAR(25)
	SET @searchTableName = N'mwPriceDataTable'
	
	IF(@mwSearchType <> 0)
	BEGIN
		-- таблица секционирована
		-- поиск ключа страны и города по ключу тура для получения имени
		-- секционированной таблицы цен туров
		DECLARE @CountryKey AS INT
		DECLARE @CityKey AS INT
		
		SELECT top 1 @CountryKey = tpt.TO_CNKey, @CityKey = tl.TL_CTDepartureKey
		FROM TP_Tours tpt
		INNER JOIN tbl_TurList tl
		ON tpt.TO_TRKey = tl.TL_KEY
		WHERE tl.TL_KEY = @TourListKey
		
		SET @searchTableName = dbo.mwGetPriceTableName(@CountryKey, @CityKey)
		
	END
	
	-- построение запроса
	DECLARE @QueryText AS NVARCHAR(MAX)
	
	-- минимальная дата	
	SET @QueryText = 'DECLARE @minTourDate as datetime 	
	select top 1 @minTourDate = p.pt_tourdate from mwPriceDataTable p
	where p.pt_tlkey = ' + CONVERT(NVARCHAR(MAX), @TourListKey) +
	' AND p.pt_tourdate > ''' + CONVERT(NVARCHAR(MAX), GETUTCDATE(), 102) + ''''
	
	IF (@RoomTypeKey IS NOT NULL)
	BEGIN
	
		SET @QueryText = @QueryText + ' AND p.pt_rmkey = ' + CONVERT(NVARCHAR(MAX), @RoomTypeKey)
	
	END
	
	SET @QueryText = @QueryText + ' ORDER BY p.pt_tourdate asc; '
	
	-- цены на эту дату
	SET @QueryText = @QueryText + ' SELECT l.[HotelKey], r.[HotelName]
				, r.[HotelCategory]	
				, case 
					when r.pt_topricefor = 1 then r.[TourMinPrice]/r.[RM_NPLACES]	-- цены за номер, делим на количество мест
				 	else r.[TourMinPrice]											-- цены за человека
				  end as [TourMinPrice]
				, r.[Nights]		
				, r.[Days]		
				, r.[Pansion]		
				, r.[PansionKey]
				, r.[PansionCode]
				, r.[TourDate]
				, r.[PriceKey]
				, r.[Rate]
				, r.[HotelDescriptionUrl]
				, r.[CountryKey]
				, r.[DepartFromCityKey]
				, r.[TourKey]
from
( select pp.pt_HDKEY [HotelKey], min(pp.pt_price) pt_price
				FROM mwPriceDataTable pp WITH (NOLOCK)
				WHERE pp.pt_tourdate = @minTourDate 
				AND pt_tlkey = ' + CONVERT(NVARCHAR(MAX), @TourListKey)
				
	IF (@RoomTypeKey IS NOT NULL)
	BEGIN

		SET @QueryText = @QueryText + ' AND pt_rmkey = ' + CONVERT(NVARCHAR(MAX), @RoomTypeKey) + ' '

	END				
				
			SET @QueryText = @QueryText	 + ' GROUP BY pp.pt_hdkey, pp.pt_tourdate ) as l
left join (
SELECT 
				  h.HD_KEY [HotelKey]
				, hd_name [HotelName]
				, hd_stars [HotelCategory]	
				, p.pt_price [TourMinPrice]
				, pt_nights [Nights]		
				, pt_days [Days]		
				, pt_pnname [Pansion]		
				, p.pt_pnkey [PansionKey]
				, p.pt_pncode [PansionCode]
				, p.pt_tourdate [TourDate]
				, p.pt_pricekey [PriceKey]
				, p.pt_Rate [Rate]
				, p.pt_hotelurl [HotelDescriptionUrl]
				, rr.RM_NPLACES as [RM_NPLACES]
				, p.pt_topricefor as [pt_topricefor]
				, p.pt_cnkey as [CountryKey]
				, p.pt_ctkeyfrom as [DepartFromCityKey]
				, p.pt_tourkey as [TourKey]
			FROM mwPriceDataTable p WITH (NOLOCK)
				LEFT JOIN HotelDictionary h WITH (NOLOCK) ON pt_hdkey = hd_key
				LEFT JOIN Rooms rr on p.pt_rmkey = rr.RM_KEY	
			WHERE p.pt_tourdate = @minTourDate
			AND pt_tlkey = ' + CONVERT(NVARCHAR(MAX), @TourListKey)
			
	IF (@RoomTypeKey IS NOT NULL)
	BEGIN

		SET @QueryText = @QueryText + ' AND pt_rmkey = ' + CONVERT(NVARCHAR(MAX), @RoomTypeKey) + ' '

	END
			
		SET @QueryText = @QueryText + ') as r
on r.[HotelKey] = l.[HotelKey] and l.[pt_price] = r.[TourMinPrice]';
							
	-- выполнение запроса, наполнение выходной таблицы
	exec (@QueryText)
	
END

GO

GRANT EXECUTE ON [dbo].[mwGetMinNearestTourPrices] TO [public]
GO
/*********************************************************************/
/* end sp_mwGetMinNearestTourPrices.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Alter_InsPolicyList_add_IPL_ServiceCreateDate.sql */
/*********************************************************************/
if not exists (select 1 from dbo.syscolumns 
			   where name = 'IPL_ServiceCreateDate' 
				 and id = object_id(N'[dbo].[InsPolicyList]'))
	begin
		ALTER TABLE dbo.InsPolicyList add IPL_ServiceCreateDate datetime null
	end
go
/*********************************************************************/
/* end Alter_InsPolicyList_add_IPL_ServiceCreateDate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 101203(AddConstraint_InsPolicy_IP_PolicyNumber_UNIQUE).sql */
/*********************************************************************/
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InsPolicy_IP_PolicyNumber_UNIQUE]') AND xtype = 'UQ')
begin
if not exists (select IP_PolicyNumber from [dbo].[InsPolicy] group by IP_PolicyNumber having count(IP_PolicyNumber) > 1)
	ALTER TABLE [dbo].[InsPolicy] ADD CONSTRAINT InsPolicy_IP_PolicyNumber_UNIQUE UNIQUE(IP_PolicyNumber)
end
GO
/*********************************************************************/
/* end 101203(AddConstraint_InsPolicy_IP_PolicyNumber_UNIQUE).sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetUniquePolicyNumber.sql */
/*********************************************************************/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_GetUniquePolicyNumber]') 
	and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sp_GetUniquePolicyNumber]
GO 

CREATE PROCEDURE [dbo].[sp_GetUniquePolicyNumber]
    ( @SettingKey int,
      @ReportKey int,
      @CurrentNumber int = 0 output)
AS

SET ARITHABORT ON
SET QUOTED_IDENTIFIER ON

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

/*********************************************************************/
/* end sp_GetUniquePolicyNumber.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110701(Partners_Dud_Users_ChageColumnsLenght).sql */
/*********************************************************************/
IF (select [length] from syscolumns where id = OBJECT_ID('DUP_USER') and name = 'US_CompanyName') < 140
BEGIN
	ALTER TABLE DUP_USER ALTER COLUMN US_CompanyName varchar(140)
END
GO

IF (select [length] from syscolumns where id = OBJECT_ID('DUP_USER') and name = 'US_POST') < 130
BEGIN
	ALTER TABLE DUP_USER ALTER COLUMN US_POST varchar(130)
END
GO

IF (select [length] from syscolumns where id = OBJECT_ID('DUP_USER') and name = 'US_FULLNAME') < 130
BEGIN
	ALTER TABLE DUP_USER ALTER COLUMN US_FULLNAME varchar(130)
END
GO

IF (select [length] from syscolumns where id = OBJECT_ID('DUP_USER') and name = 'US_Email') < 80
BEGIN
	ALTER TABLE DUP_USER ALTER COLUMN US_Email varchar(80)
END
GO

IF (select [length] from syscolumns where id = OBJECT_ID('tbl_Partners') and name = 'PR_NAME') < 140
BEGIN
	ALTER TABLE tbl_Partners ALTER COLUMN PR_NAME varchar(140)
END
GO

IF (select [length] from syscolumns where id = OBJECT_ID('tbl_Partners') and name = 'PR_ADRESS') < 330
BEGIN
	ALTER TABLE tbl_Partners ALTER COLUMN PR_ADRESS varchar(330)
END
GO

IF (select [length] from syscolumns where id = OBJECT_ID('tbl_Partners') and name = 'PR_LEGALADDRESS') < 350
BEGIN
	ALTER TABLE tbl_Partners ALTER COLUMN [PR_LEGALADDRESS] varchar(350)
END
GO

IF (select [length] from syscolumns where id = OBJECT_ID('tbl_Partners') and name = 'PR_FAX') < 120
BEGIN
	ALTER TABLE tbl_Partners ALTER COLUMN PR_FAX varchar(120)
END
GO

exec sp_refreshviewforall 'PARTNERS'
go
/*********************************************************************/
/* end 110701(Partners_Dud_Users_ChageColumnsLenght).sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCreatePriceTableIndexes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCreatePriceTableIndexes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mwCreatePriceTableIndexes]
GO

CREATE proc [dbo].[mwCreatePriceTableIndexes]
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
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_main_roomprice'')
			create index x_main_roomprice on ' + @tableName + '(pt_tourtype, pt_mainplaces, pt_addplaces, pt_tourdate, pt_nights, pt_pnkey, pt_hdstars, pt_rskey, pt_ctkey, pt_tourkey, pt_hdkey)
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_main_persprice'')
			create index x_main_persprice on ' + @tableName + '(pt_tourtype, pt_tourdate, pt_rmkey, pt_nights, pt_pnkey, pt_hdstars, pt_rskey, pt_ctkey, pt_tourkey, pt_hdkey)
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_pricekey'')
			create index x_pricekey on ' + @tableName + '(pt_pricekey) with fillfactor=70
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_date'')
			create index x_date on ' + @tableName + '(pt_tourdate) with fillfactor=70
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_tourkey'')
			create index x_tourkey on ' + @tableName + '(pt_tourkey) with fillfactor=70
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_enabled'')
			create index x_enabled on ' + @tableName + '(pt_isenabled desc) with fillfactor=70
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_hdkey'')
			create index x_hdkey on ' + @tableName + '(pt_hdkey) with fillfactor=70
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_min_tour_price'')
			create index [x_min_tour_price] on ' + @tableName + ' (pt_tourkey ASC, pt_rmkey) include (pt_hdkey, pt_price) with fillfactor=70
	end
	'
	exec(@sql)
end

GO
/*********************************************************************/
/* end sp_mwCreatePriceTableIndexes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.07.04)Create_Table_TP_PricesUpdated.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_TP_PricesUpdated_TPU_DateUpdate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[TP_PricesUpdated] DROP CONSTRAINT [DF_TP_PricesUpdated_TPU_DateUpdate]
END
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TP_PricesUpdated]') AND type in (N'U'))
DROP TABLE [dbo].[TP_PricesUpdated]
GO
CREATE TABLE [dbo].[TP_PricesUpdated](
	[TPU_Key] [int] NOT NULL IDENTITY(1,1),
	[TPU_TPKey] [int] NOT NULL,
	[TPU_IsChangeCostMode] [bit] NOT NULL,
	[TPU_TPGrossOld] [float] NOT NULL,
	[TPU_TPGrossDelta] [float] NOT NULL,
	[TPU_DateUpdate] [datetime] NOT NULL,
 CONSTRAINT [PK_TP_PricesUpdated] PRIMARY KEY CLUSTERED 
(
	[TPU_Key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[TP_PricesUpdated] ADD  CONSTRAINT [DF_TP_PricesUpdated_TPU_DateUpdate]  DEFAULT (getdate()) FOR [TPU_DateUpdate]
GO

grant select, insert, update, delete on [dbo].[TP_PricesUpdated] to public
go

/*********************************************************************/
/* end (11.07.04)Create_Table_TP_PricesUpdated.sql */
/*********************************************************************/

/*********************************************************************/
/* begin I_x_CorrectionCalculatedPrice.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Prices]') AND name = N'x_CorrectionCalculatedPrice')
DROP INDEX [x_CorrectionCalculatedPrice] ON [dbo].[TP_Prices] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_CorrectionCalculatedPrice] ON [dbo].[TP_Prices] 
(
	[TP_DateBegin] ASC
)
INCLUDE ( [TP_TIKey]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO



/*********************************************************************/
/* end I_x_CorrectionCalculatedPrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin I_x_ti_tokey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Lists]') AND name = N'x_ti_tokey')
DROP INDEX [x_ti_tokey] ON [dbo].[TP_Lists] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_ti_tokey] ON [dbo].[TP_Lists] 
(
	[TI_TOKey] ASC
)
INCLUDE ( [ti_ctkeyfrom],
[ti_totaldays]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO



/*********************************************************************/
/* end I_x_ti_tokey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin I_x_tp_services_1.sql */
/*********************************************************************/
--x_tp_services_1
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_1_old')
	DROP INDEX [x_tp_services_1_old] ON [dbo].[TP_Services] WITH ( ONLINE = OFF )
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_1')
	EXEC sp_rename N'dbo.TP_Services.x_tp_services_1', N'x_tp_services_1_old', N'INDEX';
go
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_1')
	DROP INDEX [x_tp_services_1] ON [dbo].[TP_Services] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_tp_services_1] ON [dbo].[TP_Services] 
(
	[TS_TOKey] ASC,
	[TS_SVKey] ASC
)
	INCLUDE ( [TS_Key],
	[TS_Code],
	[TS_SubCode1],
	[TS_SubCode2],
	[TS_CTKey],
	[TS_CNKey],
	[TS_Day],
	[TS_OpPartnerKey],
	[TS_OpPacketKey]) WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_1_old')
	DROP INDEX [x_tp_services_1_old] ON [dbo].[TP_Services] WITH ( ONLINE = OFF )
GO

--x_tp_services_2
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_2_old')
	DROP INDEX [x_tp_services_2_old] ON [dbo].[TP_Services] WITH ( ONLINE = OFF )
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_2')
	EXEC sp_rename N'dbo.TP_Services.x_tp_services_2', N'x_tp_services_2_old', N'INDEX';
go
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_2')
	DROP INDEX [x_tp_services_2] ON [dbo].[TP_Services] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_tp_services_2] ON [dbo].[TP_Services]
(
	[TS_Key] ASC,
	[TS_SVKey] ASC
)WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_2_old')
	DROP INDEX [x_tp_services_2_old] ON [dbo].[TP_Services] WITH ( ONLINE = OFF )
GO

--x_tp_services_3
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_3_old')
	DROP INDEX [x_tp_services_3_old] ON [dbo].[TP_Services] WITH ( ONLINE = OFF )
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_3')
	EXEC sp_rename N'dbo.TP_Services.x_tp_services_3', N'x_tp_services_3_old', N'INDEX';
go
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_3')
	DROP INDEX [x_tp_services_3] ON [dbo].[TP_Services] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_tp_services_3] ON [dbo].[TP_Services] 
(
	[TS_SVKey] ASC
)
	INCLUDE ( [TS_Key],
	[TS_Code],
	[TS_SubCode1],
	[TS_SubCode2],
	[TS_CTKey],
	[TS_Day],
	[TS_OpPartnerKey],
	[TS_OpPacketKey]) WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TP_Services]') AND name = N'x_tp_services_3_old')
	DROP INDEX [x_tp_services_3_old] ON [dbo].[TP_Services] WITH ( ONLINE = OFF )
GO
/*********************************************************************/
/* end I_x_tp_services_1.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_GetHotelRoom.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_GetHotelRoom]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_GetHotelRoom]
GO

CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_GetHotelRoom]
	(
		-- version 2009.9.10.01
		-- date 2011-10-04
		@serviceTypeKey int,
		@turList xml,
		@serviceCodeList xml,
		@dateList xml
	)
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	select TS_SubCode1 as SubCode1
	from dbo.TP_Services with (nolock) join TP_ServiceLists with (nolock) on TL_TSKey = TS_Key
	join TP_Prices with (nolock) on TP_TIKey = TL_TIKey
	where TS_Code in (select tbl.res.value('.', 'int') from @serviceCodeList.nodes('/ArrayOfInt/int') as tbl(res))
	and TS_SVKey = @serviceTypeKey
	and TS_TOKey in (select tbl.res.value('.', 'int') from @turList.nodes('/ArrayOfInt/int') as tbl(res))
	and TP_DateBegin in (select res.value('.', 'datetime') from @dateList.nodes('/ArrayOfDateTime/dateTime') as tbl(res))
END

GO

grant exec on [dbo].[CorrectionCalculatedPrice_GetHotelRoom] to public
go

/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_GetHotelRoom.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_GetServiceTypeKey.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_GetServiceTypeKey]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_GetServiceTypeKey]
GO
CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_GetServiceTypeKey]
	(
		-- version 2009.9.10.01
		-- date 2011-10-04
		@dateList xml
	)
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	select distinct TS_SVKey
	from TP_Services join TP_TurDates on TD_TOKey = TS_TOKey
	where exists (select top 1 1 from @dateList.nodes('/ArrayOfDateTime/dateTime') as tbl(res) where res.value('.', 'datetime') = TD_Date)
	and TS_SVKey is not null
	and TS_Code is not null
	and TS_CNKey is not null
	and TS_CTKey is not null
END

GO

grant exec on [dbo].[CorrectionCalculatedPrice_GetServiceTypeKey] to public
go

/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_GetServiceTypeKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_GetServiceVariant.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_GetServiceVariant]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_GetServiceVariant]
GO
CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_GetServiceVariant]
	(
		-- version 2009.9.10.01
		-- date 2011-10-04
		@serviceTypeKey int,
		@dateList xml
	)
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	select distinct TS_Code, TS_CNKey, TS_CTKey
	from TP_Services join TP_TurDates on TD_TOKey = TS_TOKey
	where exists (select top 1 1 from @dateList.nodes('/ArrayOfDateTime/dateTime') as tbl(res) where res.value('.', 'datetime') = TD_Date)
	and TS_SVKey = @serviceTypeKey
	and TS_Code is not null
	and TS_CNKey is not null
	and TS_CTKey is not null
END

GO

grant exec on [dbo].[CorrectionCalculatedPrice_GetServiceVariant] to public
go
/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_GetServiceVariant.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_GetTurDurationList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_GetTurDurationList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_GetTurDurationList]
GO
CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_GetTurDurationList]
	(
		-- version 2009.9.10.01
		-- date 2011-10-03
		@serviceTypeKey int,
		@serviceCodeList xml,
		@turList xml,
		@dateList xml
	)
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	select TL_TIKey
	into #tmp_services
	from dbo.TP_Services join TP_ServiceLists on TL_TSKey = TS_Key
	where TS_Code in (select tbl.res.value('.', 'int') from @serviceCodeList.nodes('/ArrayOfInt/int') as tbl(res))
	and TS_SVKey = @serviceTypeKey
	and TS_TOKey in (select tbl.res.value('.', 'int') from @turList.nodes('/ArrayOfInt/int') as tbl(res))

	select TP_TIKey
	into #tmp_Prices
	from TP_Prices
	where exists (	select top 1 1
					from #tmp_services
					where TP_TIKey = TL_TIKey
					and TP_DateBegin in (select res.value('.', 'datetime') from @dateList.nodes('/ArrayOfDateTime/dateTime') as tbl(res)))

	select distinct ti_totaldays as TurDuration
    from TP_Lists with (nolock)    
    where TI_Key in (select TP_TIKey from #tmp_Prices)
    and ti_totaldays is not null
END

GO
grant exec on [dbo].[CorrectionCalculatedPrice_GetTurDurationList] to public
go

/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_GetTurDurationList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_GetTurList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_GetTurList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_GetTurList]
GO
CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_GetTurList]
	(
		-- version 2009.9.10.01
		-- date 2011-10-03
		@serviceTypeKey int,
		@serviceCodeList xml,
		@dateList xml,
		@filterString nvarchar(max)
	)
AS
begin
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	select distinct TS_TOKey
	into #tmpTours
	from dbo.TP_Services with (nolock) 
	where TS_SVKey = @serviceTypeKey
	and TS_Code in (select tbl.res.value('.', 'int') from @serviceCodeList.nodes('/ArrayOfInt/int') as tbl(res))
		
	if (isnull(@filterString, '') = '')
	begin
		select distinct TO_Key as TurKey, TO_Name + ' (' + TL_Name + ')' as TurName
		from TP_Tours with (nolock) join tbl_TurList with (nolock) on TO_TRKey = TL_Key
		join dbo.TP_TurDates with (nolock) on TD_TOKey = TO_Key 
		where TO_Key in (select TS_TOKey from #tmpTours)
		and exists (select top 1 1 from @dateList.nodes('/ArrayOfDateTime/dateTime') as tbl(res) where res.value('.', 'datetime') = TD_Date)
		and TO_UPDATE != 1
	end
	else
	begin
		select distinct TO_Key as TurKey, TO_Name + ' (' + TL_Name + ')' as TurName
		from TP_Tours with (nolock) join tbl_TurList with (nolock) on TO_TRKey = TL_Key
		join dbo.TP_TurDates with (nolock) on TD_TOKey = TO_Key 
		where TO_Key in (select TS_TOKey from #tmpTours)
		and exists (select top 1 1 from @dateList.nodes('/ArrayOfDateTime/dateTime') as tbl(res) where res.value('.', 'datetime') = TD_Date)
		and TO_Name + ' (' + TL_Name + ')' like '%' + @filterString + '%'
		and TO_UPDATE != 1
	end
END

GO
grant exec on [dbo].[CorrectionCalculatedPrice_GetTurList] to public
go
/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_GetTurList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_Run.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_Run]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_Run]
GO

CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_Run]
	(
		-- version 2009.9.10.01
		-- date 2011-10-04
		@deltaCost decimal(14,2),
		@itogCostMin decimal(14,2),
		@operation bit, -- 1 - изменяем цену, 0 - удаляем цену
		@costInPercent bit, -- 1 - цена в процентах, 0 - цена в у.е.
		@perPerson bit, -- 1 - за человека, 0 - нет
		@serviceTypeKey int,
		@serviceCodeList xml,
		@dateList xml,
		@turList xml,
		@durationList xml,
		@hotelKeys xml
	)
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	declare @cost decimal(14,2)
	set @cost = @deltaCost;
	
	if (@operation = 0)
	begin
		set @cost = 0;
	end
	
	declare @partUpdate int
	
	set @partUpdate = 100000
	select @partUpdate = SS_ParmValue from SystemSettings where SS_ParmName = 'PartCorrectionPrice'
	
	declare @divide int, @mwReplIsPublisher int, @mwReplIsSubscriber int
	
	set @mwReplIsPublisher = dbo.mwReplIsPublisher()
	set @mwReplIsSubscriber = dbo.mwReplIsSubscriber()

	set @divide = 0

	select @divide = CONVERT(int, isnull(SS_ParmValue, '0'))
	from SystemSettings
	where SS_ParmName = 'MWDivideByCountry'

	select TI_Key
	into #tmp_CorrectionCalculatedPrice_Run
	from TP_ServiceLists with (nolock) join TP_Services with (nolock) on TL_TSKey = TS_Key
	join TP_Lists with (nolock) on TL_TIKey = TI_Key
	where TI_TOKey in (select tbl.res.value('.', 'int') from @turList.nodes('/ArrayOfInt/int') as tbl(res) join TP_Tours on tbl.res.value('.', 'int') = TO_Key where TO_UPDATE != 1)
	and TS_Code in (select tbl.res.value('.', 'int') from @serviceCodeList.nodes('/ArrayOfInt/int') as tbl(res))
	and (@serviceTypeKey != 3 or (TS_SubCode1 in (select tbl.res.value('.', 'int') from @hotelKeys.nodes('/ArrayOfInt/int') as tbl(res))))
	and TS_SVKey = @serviceTypeKey
	and ti_totaldays in (select tbl.res.value('.', 'int') from @durationList.nodes('/ArrayOfInt/int') as tbl(res))
	
	while ((select COUNT(*) from #tmp_CorrectionCalculatedPrice_Run) > 0)
	begin
		-- выборка цен
		select TP_Key as TPU_TPKey, TP_Gross as TPU_TPGrossOld, case when @costInPercent = 0 then
																									case when @perPerson = 1 then
																										@cost * (	select top 1 TS_Men
																										from TP_Services with (nolock) join TP_ServiceLists with (nolock) on TS_Key = TL_TSKey 
																										where TS_SVKey = 3
																										and TL_TIKey = TP_TIKey)
																									else 
																										@cost 
																									end
																								else
																									 case when @perPerson = 1 then 
																										TP_Gross * (@cost / 100) * (	select top 1 TS_Men
																																		from TP_Services with (nolock) join TP_ServiceLists with (nolock) on TS_Key = TL_TSKey 
																																		where TS_SVKey = 3
																																		and TL_TIKey = TP_TIKey)
																									else 
																										TP_Gross * (@cost / 100)
																									end
																								end as TPU_TPGrossDelta
		into #tmp_tpPricesUpdated
		from TP_Prices with (nolock)
		where TP_TIKey in ( select top (@partUpdate) TI_Key from #tmp_CorrectionCalculatedPrice_Run)
		and TP_DateBegin in (select res.value('.', 'datetime') from @dateList.nodes('/ArrayOfDateTime/dateTime') as tbl(res))
				
		if (@operation = 1)
		begin
			-- если изменяем цены
			update TP_Prices with (rowlock)
			set TP_Gross = TPU_TPGrossOld + TPU_TPGrossDelta
			from TP_Prices join #tmp_tpPricesUpdated on TP_Key = TPU_TPKey
		end
		else
		begin
			-- если удаляем цены
			delete TP_Prices with (rowlock)
			from TP_Prices join #tmp_tpPricesUpdated on TP_Key = TPU_TPKey
		end

		-- запишем время изменения в туре
		update TP_Tours
		set to_updatetime = getdate()
		from TP_Tours join @turList.nodes('/ArrayOfInt/int') as tbl(res) on tbl.res.value('.', 'int') = to_key
		
		if (@mwReplIsPublisher <= 0 and @mwReplIsSubscriber <= 0)
		begin
			if (@divide = 0)
			begin
				update mwPriceDataTable with (rowlock)
				set pt_price = TPU_TPGrossOld + TPU_TPGrossDelta
				from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
			end
			else
			begin
				declare @sql nvarchar(4000), @tableName nvarchar(100)
				declare cur cursor fast_forward read_only for
				select name
				from sysobjects
				where xtype = 'U' and name like 'mwPriceDataTable[_]%'

				open cur
				fetch next from cur into @tableName
				while (@@FETCH_STATUS = 0)
				begin
					if (@operation = 1)
					begin
						set @sql = 'update ' + @tableName + ' with (rowlock)
									set pt_price = TPU_TPGrossOld + TPU_TPGrossDelta
									from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey'
					end
					else
					begin
						set @sql = 'delete ' + @tableName + ' with (rowlock)
									from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey'
					end
					
					exec (@sql)
					fetch next from cur into @tableName
				end
				
				close cur
				deallocate cur
			end
		end
		
		insert into TP_PricesUpdated(TPU_TPKey, TPU_TPGrossDelta, TPU_TPGrossOld, TPU_IsChangeCostMode)
		select TPU_TPKey, TPU_TPGrossDelta, TPU_TPGrossOld, @operation
		from #tmp_tpPricesUpdated

		delete top (@partUpdate) #tmp_CorrectionCalculatedPrice_Run
		drop table #tmp_tpPricesUpdated
	end
	
END

GO

grant exec on [dbo].[CorrectionCalculatedPrice_Run] to public
go
/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_Run.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CorrectionCalculatedPrice_RunSubscriber.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_RunSubscriber]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_RunSubscriber]
GO
CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_RunSubscriber]
AS
BEGIN
	declare @partUpdate int
	
	set @partUpdate = 100000
	select @partUpdate = SS_ParmValue from SystemSettings where SS_ParmName = 'PartCorrectionPrice'
	
	declare @divide int, @mwReplIsSubscriber int
	
	set @mwReplIsSubscriber = dbo.mwReplIsSubscriber()

	set @divide = 0

	select @divide = CONVERT(int, isnull(SS_ParmValue, '0'))
	from SystemSettings
	where SS_ParmName = 'MWDivideByCountry'

	-- копируем таблицу TP_PricesUpdated
	select *
	into #tmp_CorrectionCalculatedPrice_Run
	from TP_PricesUpdated
	
	while ((select COUNT(*) from #tmp_CorrectionCalculatedPrice_Run) > 0)
	begin
		-- берем порцию
		select top (@partUpdate) *
		into #tmp_tpPricesUpdated
		from #tmp_CorrectionCalculatedPrice_Run
	
		if (@mwReplIsSubscriber > 0)
		begin
			if (@divide = 0)
			begin
				update mwPriceDataTable with (rowlock)
				set pt_price = TPU_TPGrossOld + TPU_TPGrossDelta
				from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
				where TPU_IsChangeCostMode = 1
				
				delete mwPriceDataTable with (rowlock)
				from mwPriceDataTable join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
				where TPU_IsChangeCostMode = 0
			end
			else
			begin
				declare @sql nvarchar(4000), @tableName nvarchar(100)
				declare cur cursor fast_forward read_only for
				select name
				from sysobjects
				where xtype = 'U' and name like 'mwPriceDataTable[_]%'

				open cur
				fetch next from cur into @tableName
				while (@@FETCH_STATUS = 0)
				begin
					set @sql = 'update ' + @tableName + ' with (rowlock)
								set pt_price = TPU_TPGrossOld + TPU_TPGrossDelta
								from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
								where TPU_IsChangeCostMode = 1
								
								delete ' + @tableName + ' with (rowlock)
								from ' + @tableName + ' join #tmp_tpPricesUpdated on pt_pricekey = TPU_TPKey
								where TPU_IsChangeCostMode = 0'
					exec (@sql)
					fetch next from cur into @tableName
				end
				
				close cur
				deallocate cur
			end
		end
		
		-- очищаем временную таблицу #tmp_CorrectionCalculatedPrice_Run
		delete #tmp_CorrectionCalculatedPrice_Run
		from #tmp_CorrectionCalculatedPrice_Run 
		where exists (select top 1 1 
						from #tmp_tpPricesUpdated
						where #tmp_CorrectionCalculatedPrice_Run.TPU_Key = #tmp_tpPricesUpdated.TPU_Key)
		-- очищаем основнцю таблмцу TP_PricesUpdated
		delete TP_PricesUpdated
		from TP_PricesUpdated 
		where exists (select top 1 1 
						from #tmp_tpPricesUpdated
						where TP_PricesUpdated.TPU_Key = #tmp_tpPricesUpdated.TPU_Key)
		-- удаляем таблицу порцию
		drop table #tmp_tpPricesUpdated
	end
	
END


GO

grant exec on [dbo].[CorrectionCalculatedPrice_RunSubscriber] to public
go
/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_RunSubscriber.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110705_Insert_Actions_TPD.sql */
/*********************************************************************/
if not exists(select 1 from [dbo].[Actions] where AC_Key = 76)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(76, 'Разрешить просмотр списка ПДн', 'Allow viewing list of TPD')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 77)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(77, 'Разрешить добавление ПДн', 'Allow adding TPD')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 78)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(78, 'Разрешить редактирование ПДн', 'Allow editing TPD')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 79)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(79, 'Разрешить удаление ПДн', 'Allow deleting TPD')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 80)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(80, 'Разрешить просмотр обращений к ПДн', 'Allow viewing TPD access list')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 81)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(81, 'Разрешить удаление обращений к ПДн', 'Allow deleting TPD access')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 82)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(82, 'Разрешить преобразование записи в ПДн'
	     , 'Allow record conversion into TPD')
end 
go
/*********************************************************************/
/* end 20110705_Insert_Actions_TPD.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110705_Create_TPDAccess_TPDOperations_ApplicationTypes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TPDAccesses]') AND type in (N'U'))
begin
	DROP TABLE [dbo].[TPDAccesses]
end
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ApplicationTypes]') AND type in (N'U'))
begin
	DROP TABLE [dbo].[ApplicationTypes]
end
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TPDOperations]') AND type in (N'U'))
begin
	DROP TABLE [dbo].[TPDOperations]
end
GO

CREATE TABLE [dbo].[ApplicationTypes]
(
	AT_Id int not null primary key,
	AT_Name nvarchar(30) not null,
	AT_NameLat nvarchar(30) not null
)
go
grant select, insert, update, delete on [dbo].[ApplicationTypes] to public
go
--МТ/MW/вебсервис/ вебсервис TourML и т.д.
insert [dbo].[ApplicationTypes](AT_Id, AT_Name, AT_NameLat)
values(1,'Мастер-Тур','MasterTour')
insert [dbo].[ApplicationTypes](AT_Id, AT_Name, AT_NameLat)
values(2,'Мастер-Веб','MasterWeb')
insert [dbo].[ApplicationTypes](AT_Id, AT_Name, AT_NameLat)
values(3,'Вебсервис','Webservice')
insert [dbo].[ApplicationTypes](AT_Id, AT_Name, AT_NameLat)
values(4,'ТурМЛ','TourML')
go
CREATE TABLE [dbo].[TPDOperations]
(
	TO_Id int not null primary key,
	TO_Name nvarchar(30) not null,
	TO_NameLat nvarchar(30) not null
)
go
grant select, insert, update, delete on [dbo].[TPDOperations] to public
go
-- чтение полное / чтение минимальное / открытие карточки на редактирование 
-- / изменение / удаление/ добавилась / преобразование записи в экране Постоянные клиенты в ПДн
insert [dbo].[TPDOperations](TO_Id, TO_Name, TO_NameLat)
values(1,'Полное чтение','Full read')
insert [dbo].[TPDOperations](TO_Id, TO_Name, TO_NameLat)
values(2,'Минимальное чтение', 'Min read')
insert [dbo].[TPDOperations](TO_Id, TO_Name, TO_NameLat)
values(3,'Открытие на редактирование','Opened to edit')
insert [dbo].[TPDOperations](TO_Id, TO_Name, TO_NameLat)
values(4,'Изменение','Modify')
insert [dbo].[TPDOperations](TO_Id, TO_Name, TO_NameLat)
values(5,'Добавление','Add')
insert [dbo].[TPDOperations](TO_Id, TO_Name, TO_NameLat)
values(6,'Удаление','Delete')
insert [dbo].[TPDOperations](TO_Id, TO_Name, TO_NameLat)
values(7,'Преобразование в пдн','Conversion to TPD')
insert [dbo].[TPDOperations](TO_Id, TO_Name, TO_NameLat)
values(8,'Просмотр списка пдн','Viewing TPD list')
go

CREATE TABLE [dbo].[TPDAccesses]
(
	TA_Id bigint identity(1,1) not null primary key,
	TA_Date datetime not null default(getdate()),
	TA_UserName nvarchar(128) not null default(SUSER_NAME()),
	TA_Host nvarchar(128) not null default(HOST_NAME()),
	TA_OperationId int not null FOREIGN KEY REFERENCES [dbo].[TPDOperations] ([TO_Id]),
	TA_TPDKey int not null,
	TA_TPD nvarchar(35) not null, -- наименование объекта пдн 
	TA_ApplicationTypeId int not null FOREIGN KEY REFERENCES [dbo].[ApplicationTypes]([AT_Id]), -- тип приложения (МТ/MW/вебсервис/ вебсервис TourML и т.д.)
	TA_Success bit not null	
)
grant select, insert, update, delete on [dbo].[TPDAccesses] to public
go

/*********************************************************************/
/* end 20110705_Create_TPDAccess_TPDOperations_ApplicationTypes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110712_Insert_SystemSettings_EnableTPD.sql */
/*********************************************************************/
if not exists(select 1 from systemsettings where ss_parmName like 'SYSEnableTPD')
begin
	insert systemSettings(SS_Parmname, SS_ParmValue)
	values('SYSEnableTPD','0')
end
go

/*********************************************************************/
/* end 20110712_Insert_SystemSettings_EnableTPD.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110711_AddSystemSetting.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM dbo.SystemSettings WHERE SS_ParmName = 'SYSAutoBlockMWDogovors')
	INSERT INTO dbo.SystemSettings (SS_ParmName, SS_ParmValue) VALUES ('SYSAutoBlockMWDogovors', '0')
GO
/*********************************************************************/
/* end 20110711_AddSystemSetting.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (110608)CreateTable_ReportsPermissions.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ReportsPermissionsUsers_reporttemplates]') AND parent_object_id = OBJECT_ID(N'[dbo].[ReportsPermissionsUsers]'))
ALTER TABLE [dbo].[ReportsPermissionsUsers] DROP CONSTRAINT [FK_ReportsPermissionsUsers_reporttemplates]
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ReportsPermissionsUsers_UserList]') AND parent_object_id = OBJECT_ID(N'[dbo].[ReportsPermissionsUsers]'))
ALTER TABLE [dbo].[ReportsPermissionsUsers] DROP CONSTRAINT [FK_ReportsPermissionsUsers_UserList]
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ReportsPermissionsGroups_reporttemplates]') AND parent_object_id = OBJECT_ID(N'[dbo].[ReportsPermissionsGroups]'))
ALTER TABLE [dbo].[ReportsPermissionsGroups] DROP CONSTRAINT [FK_ReportsPermissionsGroups_reporttemplates]
GO
/****************************************** Удаляем таблицы ***********************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReportsPermissionsUsers]') AND type in (N'U'))
DROP TABLE [dbo].[ReportsPermissionsUsers]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReportsPermissionsGroups]') AND type in (N'U'))
DROP TABLE [dbo].[ReportsPermissionsGroups]
GO
/****************************************** Создаем таблицы ***********************************************/
CREATE TABLE [dbo].[ReportsPermissionsGroups](
	[RPG_GroupKey] [int] NOT NULL,
	[RPG_RPKey] [int] NOT NULL,
	[RPG_Allow] [bit] NOT NULL,
 CONSTRAINT [PK_ReportsPermissionsGroups] PRIMARY KEY CLUSTERED 
(
	[RPG_GroupKey] ASC,
	[RPG_RPKey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ReportsPermissionsGroups]  WITH CHECK ADD  CONSTRAINT [FK_ReportsPermissionsGroups_Rep_Profiles] FOREIGN KEY([RPG_RPKey])
REFERENCES [dbo].[Rep_Profiles] ([RP_KEY])
GO
ALTER TABLE [dbo].[ReportsPermissionsGroups] CHECK CONSTRAINT [FK_ReportsPermissionsGroups_Rep_Profiles]
GO

CREATE TABLE [dbo].[ReportsPermissionsUsers](
	[RPU_UserKey] [int] NOT NULL,
	[RPU_RPKey] [int] NOT NULL,
	[RPU_Allow] [bit] NOT NULL,
 CONSTRAINT [PK_ReportsPermissionsUsers] PRIMARY KEY CLUSTERED 
(
	[RPU_UserKey] ASC,
	[RPU_RPKey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ReportsPermissionsUsers]  WITH CHECK ADD  CONSTRAINT [FK_ReportsPermissionsUsers_Rep_Profiles] FOREIGN KEY([RPU_RPKey])
REFERENCES [dbo].[Rep_Profiles] ([RP_KEY])
GO
ALTER TABLE [dbo].[ReportsPermissionsUsers] CHECK CONSTRAINT [FK_ReportsPermissionsUsers_Rep_Profiles]
GO
ALTER TABLE [dbo].[ReportsPermissionsUsers]  WITH CHECK ADD  CONSTRAINT [FK_ReportsPermissionsUsers_UserList] FOREIGN KEY([RPU_UserKey])
REFERENCES [dbo].[UserList] ([US_KEY])
GO
ALTER TABLE [dbo].[ReportsPermissionsUsers] CHECK CONSTRAINT [FK_ReportsPermissionsUsers_UserList]
GO
/****************************************** Раздаем права ***********************************************/
grant select, insert, update, delete on [dbo].[ReportsPermissionsUsers] to public
go
grant select, insert, update, delete on [dbo].[ReportsPermissionsGroups] to public
go
/*********************************************************************/
/* end (110608)CreateTable_ReportsPermissions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (110614)Create_View_UserGroup.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[UserGroup]'))
DROP VIEW [dbo].[UserGroup]
GO
CREATE VIEW [dbo].[UserGroup]
AS 
	SELECT US_KEY as UserId, su.name as UserName, GroupUID as GroupId, sg.name as GroupName
	FROM SysUsers su join SysMembers sm on su.UID = sm.MemberUID join SysUsers sg on sm.GroupUID = sg.UID
	join master.dbo.SysLogins sl on su.name COLLATE Latin1_General_CI_AS = sl.name COLLATE Latin1_General_CI_AS
	join UserList on US_USERID = su.name
	WHERE su.hasdbaccess = 1
	and su.uid != 1
	and (su.isntuser = 1 or su.issqluser = 1)
	and (sg.issqlrole = 1)
GO
grant select, insert, update, delete on [dbo].[UserGroup] to public
go
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[DataBaseGroups]'))
DROP VIEW [dbo].[DataBaseGroups]
GO
CREATE VIEW [dbo].[DataBaseGroups]
AS 
	select [uid], [name]
	from [SysUsers]
	WHERE [issqlrole] = 1
GO
grant select, insert, update, delete on [dbo].[DataBaseGroups] to public
go
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[ReportsPermissions]'))
DROP VIEW [dbo].[ReportsPermissions]
GO
CREATE VIEW [dbo].[ReportsPermissions]
AS
	select US_KEY, RP_RepKey as ReportListKey, ReportList.RP_Name as ReportListName, Rep_Profiles.RP_Key as ReportProfileKey, Rep_Profiles.RP_NAME as ReportProfileName
	from UserList join Rep_Profiles on 1 = 1
	join ReportList on RP_RepKey = RP_FNKEY
	where
	-- если есть разрешение и это разрешение на пользователе
	(exists (	select 1
				from ReportsPermissionsUsers as perUS
				where perUS.RPU_UserKey = US_KEY
				and perUS.RPU_RPKey = Rep_Profiles.RP_Key)
		and exists (	select 1
						from ReportsPermissionsUsers as perUS
						where perUS.RPU_UserKey = US_KEY
						and perUS.RPU_RPKey = Rep_Profiles.RP_Key
						and perUS.RPU_Allow = 1))
	-- если нету запрещения ни в пользователях ни в группах
	or (not exists (	select 1
					from ReportsPermissionsUsers as perUS
					where perUS.RPU_UserKey = US_KEY
					and perUS.RPU_RPKey = Rep_Profiles.RP_Key)
		and not exists (	select 1
							from ReportsPermissionsGroups as perGR
							join UserGroup on RPG_GroupKey = GroupId
							where UserId = US_KEY
							and perGR.RPG_RPKey = Rep_Profiles.RP_Key))
	-- если нету запрещения на пользователе и хоть в одной группе стоит разрешить
	or (not exists (	select 1
					from ReportsPermissionsUsers as perUS
					where perUS.RPU_UserKey = US_KEY
					and perUS.RPU_RPKey = Rep_Profiles.RP_Key)
		and exists (	select 1
						from (	select CONVERT(tinyint, isnull(perGR.RPG_Allow, 1)) as Allow
								from ReportsPermissionsGroups as perGR right join UserGroup on RPG_GroupKey = GroupId
								where UserId = US_KEY
								and isnull(perGR.RPG_RPKey, Rep_Profiles.RP_Key) = Rep_Profiles.RP_Key) as tbl
						group by Allow
						having MAX(Allow) = 1))
GO
grant select, insert, update, delete on [dbo].[ReportsPermissions] to public
go
/*********************************************************************/
/* end (110614)Create_View_UserGroup.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (110616)Create_Index_X_Communications.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Communications]') AND name = N'X_Communications')
DROP INDEX [X_Communications] ON [dbo].[Communications] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_Communications] ON [dbo].[Communications] 
(
	[CM_DGKey] ASC,
	[CM_PRKey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO



/*********************************************************************/
/* end (110616)Create_Index_X_Communications.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (110616)Create_Index_X_QuotedState.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[QuotedState]') AND name = N'X_QuotedState')
DROP INDEX [X_QuotedState] ON [dbo].[QuotedState] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_QuotedState] ON [dbo].[QuotedState] 
(
	[QS_DLID] ASC,
	[QS_TUID] ASC
)
INCLUDE ( [QS_STATE]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO



/*********************************************************************/
/* end (110616)Create_Index_X_QuotedState.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20110722)mwReplTours.sql */
/*********************************************************************/
if exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwReplTours]') AND type in (N'U'))
begin
	alter table dbo.mwReplTours alter column rt_add int null
end
else
begin
	CREATE TABLE [dbo].[mwReplTours](
		[rt_key] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[rt_trkey] [int] NULL,
		[rt_tokey] [int] NULL,
		[rt_calckey] [int] NULL,
		[rt_date] [datetime] NULL,
	PRIMARY KEY CLUSTERED 
	(
		[rt_key] ASC
	) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[mwReplTours]  WITH CHECK ADD FOREIGN KEY([rt_tokey])
	REFERENCES [dbo].[TP_Tours] ([TO_Key])
	ON DELETE CASCADE

	ALTER TABLE [dbo].[mwReplTours]  WITH CHECK ADD FOREIGN KEY([rt_trkey])
	REFERENCES [dbo].[tbl_TurList] ([TL_KEY])
end
go
/*********************************************************************/
/* end (20110722)mwReplTours.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110621_Insert_ObjectAliases.sql */
/*********************************************************************/
if not exists(select 1 from objectaliases where OA_id = 1143)
begin
	insert objectaliases(OA_id, OA_Alias, OA_Name, OA_NameLat, OA_TableId)
	values(1143, 'TU_IsAnketa','Турист заполнил анкету','Tourist filled the form',61)
end
go

/*********************************************************************/
/* end 110621_Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110701_Alter_Clients_Add_CL_CHECKED.sql */
/*********************************************************************/
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Clients]') 
											  and name = 'CL_CHECKED')
begin
	ALTER TABLE dbo.Clients ADD CL_CHECKED bit not null default(0) 
end
GO


/*********************************************************************/
/* end 20110701_Alter_Clients_Add_CL_CHECKED.sql */
/*********************************************************************/

/*********************************************************************/
/* begin CreateTable_PriceListDetails.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PriceListDetails]') AND type in (N'U'))
DROP TABLE [dbo].[PriceListDetails]
GO
CREATE TABLE [dbo].[PriceListDetails](
	[PLD_Key] [int] IDENTITY(1,1) NOT NULL,
	[PLD_ToKey] [int] NOT NULL,
	[PLD_HotelCityNames] nvarchar(256) NULL,
	[PLD_HotelKeys] nvarchar(256) NULL,
	[PLD_HotelCityKeys] nvarchar(256) NULL,
	[PLD_AirlineNames] nvarchar(256) NULL,
	[PLD_AirlineKeys] nvarchar(256) NULL,
	[PLD_ServiceClassesNames] varchar(8000) NULL
PRIMARY KEY CLUSTERED 
(
	[PLD_Key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/*********************************************************************/
/* end CreateTable_PriceListDetails.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwTourChKeys.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='fn' and name='mwTourChKeys')
	drop function dbo.mwTourChKeys
GO

create function [dbo].[mwTourChKeys] (@tourkey int) returns nvarchar(256)
as
begin
     declare @result nvarchar(256)
     set @result = N''
     select @result = @result + rtrim(ltrim(str(tbl.ti_chkey))) + N', ' from (select distinct ti_chkey from tp_lists with(nolock) where ti_tokey = @tourkey) 
tbl 
     declare @len int
     set @len = len(@result)
     if(@len > 0)
          set @result = substring(@result, 1, @len - 1)
	return @result
end
go

grant exec on [dbo].[mwTourChKeys] to public
GO
/*********************************************************************/
/* end fn_mwTourChKeys.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwTourChNames.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='fn' and name='mwTourChNames')
	drop function dbo.mwTourChNames
GO

create function [dbo].[mwTourChNames] (@tourkey int) returns nvarchar(256)
as
begin
     declare @result nvarchar(256)
     set @result = N''
     select @result = @result + rtrim(ltrim((select top 1 al_name from dbo.charter  with(nolock), dbo.airline  with(nolock) where al_code=ch_airlinecode and 
		ch_key=ti_chkey))) + N', ' from (select distinct ti_chkey from tp_lists  with(nolock) where ti_tokey = @tourkey) tbl 
     declare @len int
     set @len = len(@result)
     if(@len > 0)
          set @result = substring(@result, 1, @len - 1)
	return @result
end
go

grant exec on [dbo].[mwTourChNames] to public
GO
/*********************************************************************/
/* end fn_mwTourChNames.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwTourHotelCtKeys.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='fn' and name='mwTourHotelCtKeys')
	drop function dbo.mwTourHotelCtKeys
GO

create function [dbo].[mwTourHotelCtKeys] (@tourkey int) returns nvarchar(256)
as
begin
	declare @result nvarchar(256)
	set @result = N''

	select @result = @result + rtrim(ltrim(str(tbl.ti_firstctkey))) + N', ' from (select distinct ti_firstctkey from tp_lists with(nolock) where ti_tokey = @tourkey) tbl 

	declare @len int
	set @len = len(@result)
	if(@len > 0)
		set @result = substring(@result, 1, @len - 1)

return @result
end
go

grant exec on [dbo].[mwTourHotelCtKeys] to public
GO
/*********************************************************************/
/* end fn_mwTourHotelCtKeys.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwTourHotelCtNames.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='fn' and name='mwTourHotelCtNames')
	drop function dbo.mwTourHotelCtNames
GO

create function [dbo].[mwTourHotelCtNames] (@tourkey int) returns nvarchar(256)
as
begin
            declare @result varchar(256)
            set @result = N''
            select @result = @result + rtrim(ltrim(ct_name)) + N', ' from (select distinct ct_name from tp_lists  with(nolock) left join hoteldictionary  with(nolock) on hd_key 
= ti_firsthdkey left join dbo.CityDictionary  with(nolock) on hd_ctkey = ct_key where ti_tokey = @tourkey) as tbl order by tbl.ct_name
            declare @len int
            set @len = len(@result)
            if(@len > 0)
                        set @result = substring(@result, 1, @len - 1)
return @result
end
go

grant exec on [dbo].[mwTourHotelCtNames] to public
GO
/*********************************************************************/
/* end fn_mwTourHotelCtNames.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwTourHotelKeys.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='fn' and name='mwTourHotelKeys')
	drop function dbo.mwTourHotelKeys
GO

create function [dbo].[mwTourHotelKeys] (@tourkey int) returns nvarchar(256)
as
begin
	declare @result nvarchar(256)
	set @result = N''

	select @result = @result + rtrim(ltrim(str(tbl.ti_firsthdkey))) + N', ' from (select distinct ti_firsthdkey from tp_lists with(nolock) where ti_tokey = @tourkey) tbl 

	declare @len int
	set @len = len(@result)
	if(@len > 0)
		set @result = substring(@result, 1, @len - 1)

return @result
end
go

grant exec on [dbo].[mwTourHotelKeys] to public
GO
/*********************************************************************/
/* end fn_mwTourHotelKeys.sql */
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
									where CD_CLKey = @calendarKey), 0)
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
/* begin sp_CheckDoubleDogovor.sql */
/*********************************************************************/
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
	SET @FirstName = REPLACE (@FirstName,'''','')
	
	if (@HotelKey > 0)
		BEGIN
			SELECT TU_DGCOD, TU_KEY From dbo.tbl_turist where TU_TURDATE = @TourDate AND RTRIM(LTRIM((UPPER(TU_NAMERUS)))) = RTRIM(LTRIM((UPPER(@LastName)))) AND RTRIM(LTRIM((UPPER(TU_FNAMERUS)))) = RTRIM(LTRIM((UPPER(@FirstName)))) AND EXISTS (SELECT DG_KEY FROM dogovor WHERE DG_CODE = TU_DGCOD ) 
				AND EXISTS (SELECT DL_KEY FROM [dbo].[tbl_dogovorlist] WHERE DL_DGCOD = TU_DGCOD AND DL_SVKEY = 3 AND DL_CODE = @HotelKey)
		END
	else
		BEGIN
			SELECT TU_DGCOD, TU_KEY From [dbo].[tbl_turist] where TU_TURDATE = @TourDate AND RTRIM(LTRIM((UPPER(TU_NAMERUS)))) = RTRIM(LTRIM((UPPER(@LastName)))) AND RTRIM(LTRIM((UPPER(TU_FNAMERUS)))) = RTRIM(LTRIM((UPPER(@FirstName)))) AND EXISTS (SELECT DG_KEY FROM dogovor where DG_CODE = TU_DGCOD) 
		END  
end
go

grant exec on [dbo].[CheckDoubleDogovor] to public
go

/*********************************************************************/
/* end sp_CheckDoubleDogovor.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCheckQuotesCycle.sql */
/*********************************************************************/
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
					select @isEditableService = count(*) from dbo.tp_services with(nolock) where ts_svkey = 3 and ts_tokey=@pttourkey and  ts_code=@chkey and ts_day = @chday and ts_days=@days and ts_oppartnerkey=@chprkey and ts_oppacketkey=@chpkkey and (ts_attribute & @editableCode)=@editableCode
					if (@isEditableService = 0)
							set @findFlight = 0
					select @tmpThereAviaQuota=res from #checked where svkey=1 and code=@chkey and date=@tourdate and day=@chday and days=@days and prkey=@chprkey and pkkey=@chpkkey and findflight = @findflight
					--begin try
					--	if (@chkey = 727)
					--	begin
					--		print rtrim(str(@pagingType,5)) + '-' + rtrim(str(@chkey,5)) + '-' +  rtrim(@flightGroups) + '-' +  rtrim(str(@agentKey,5)) + '-' +  rtrim(str(@chprkey,5)) + '-' +  rtrim(CAST(@tourdate as nvarchar(50))) + '-' +  rtrim(str(@chday,5)) + '-' +  rtrim(str(@requestOnRelease,5)) + '-' +  rtrim(str(@noPlacesResult,5)) + '-' +  rtrim(str(@checkAgentQuota,5)) + '-' +  rtrim(str(@checkCommonQuota,5)) + '-' +  rtrim(str(@checkNoLongQuota,5)) + '-' +  rtrim(str(@findFlight,5)) + '-' +  rtrim(str(@chpkkey,5)) + '-' +  rtrim(str(@days,5)) + '-' +  rtrim(str(@expiredReleaseResult,5)) + '-' +  rtrim(str(@aviaQuotaMask,5)) + '-' +  rtrim(str(@chbackday,5))
					--	end
					--end try						
					--begin catch
					--	print error_message()
					--end catch
					if (@tmpThereAviaQuota is null)
					begin
						--kadraliev MEG00025990 03.11.2010 Если в туре запрещено менять рейс, устанавливаем @findFlight = 0
						--select @isEditableService = count(*) from dbo.tp_services where ts_tokey=@pttourkey and ts_code=@chbackkey and (ts_attribute & @editableCode)=@editableCode
						
						exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @chbackday
						insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res, findflight) values(1,@chkey,0,0,@tourdate,@chday,@days,@chprkey, @chpkkey, @tmpThereAviaQuota, @findflight)
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
						--select @isEditableService = count(*) from dbo.tp_services where ts_tokey=@pttourkey and ts_code=@chbackkey and (ts_attribute & @editableCode)=@editableCode
						select @isEditableService = count(*) from dbo.tp_services with(nolock) where ts_svkey = 3 and ts_tokey=@pttourkey and  ts_code=@chbackkey and ts_day = @chbackday and ts_days=@days and ts_oppartnerkey=@chbackprkey and ts_oppacketkey=@chbackpkkey and (ts_attribute & @editableCode)=@editableCode
						if (@isEditableService = 0)
							set @findFlight = 0
						select @tmpBackAviaQuota=res from #checked where svkey=1 and code=@chbackkey and date=@tourdate and day=@chbackday and days=@days and prkey=@chbackprkey and pkkey=@chbackpkkey and findflight = @findflight
						if (@tmpBackAviaQuota is null)
						begin
						--	print @chday
							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chbackkey, @flightGroups, @agentKey, @chbackprkey, @tourdate,@chbackday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chbackpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output, @chday
							insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res, findflight) values(1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey, @tmpBackAviaQuota, @findflight)
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
/*********************************************************************/
/* end sp_mwCheckQuotesCycle.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetCalculatedPriceInfo.sql */
/*********************************************************************/
if exists(select id from sysobjects where name='mwGetCalculatedPriceInfo' and xtype='p')
	drop procedure [dbo].[mwGetCalculatedPriceInfo]
go

create procedure [dbo].[mwGetCalculatedPriceInfo] 
	@priceKey	int,
	@includeTourDescriptionText	tinyint,
	@includeBookingConditionsText	tinyint
AS
begin
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
		,  dbo.mwGetServiceClassesNames(TI_Key, 1,', ', 1) as IncludedServices
	from TP_Prices
		join TP_Lists on TP_TIKey = TI_Key
		join TP_Tours on TP_TOKey = TO_Key
		join tbl_TurList on TO_TRKey = TL_Key
		join tbl_Country on TO_CNKey = CN_Key
	where TP_Key = @priceKey
end
go

grant exec on [dbo].[mwGetCalculatedPriceInfo] to public
go

/*********************************************************************/
/* end sp_mwGetCalculatedPriceInfo.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetServiceIsEditableAttribute.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwGetServiceIsEditableAttribute')
	drop proc dbo.mwGetServiceIsEditableAttribute
go

create procedure [dbo].[mwGetServiceIsEditableAttribute]
	@tokey int,
	@tscode int,
	@day int,
	@days int,
	@prkey int,
	@pkkey int,
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
	where ts_svkey = 3 and ts_tokey='+ltrim(rtrim(str(@tokey)))+' and ts_code='+ltrim(rtrim(str(@tscode)))+' and ts_day = ' + ltrim(rtrim(str(@day ))) + ' and ts_days= ' + ltrim(rtrim(str(@days))) + ' and ts_oppartnerkey= ' + ltrim(rtrim(str(@prkey))) + ' and ts_oppacketkey= ' + ltrim(rtrim(str(@pkkey))) + ' and (ts_attribute&+'+ltrim(rtrim(str(@editableCode)))+')='+ltrim(rtrim(str(@editableCode)))	
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
/* begin sp_mwTourInfo.sql */
/*********************************************************************/
if exists(select id from sysobjects where id = OBJECT_ID('mwTourInfo') and xtype = 'P')
	drop procedure dbo.mwTourInfo
go

create proc [dbo].[mwTourInfo](@onlySpo smallint = null, @tourKey int = null, @countryKey int = null, @cityFromKey int = null)
as
begin
	select to_cnkey as pt_cnkey, 
		cn_name, 
		isnull(tl_ctdeparturekey,0) as pt_ctkeyfrom, 
		isnull(ct_name, '-Без перелета-') as ct_name, 
		pld_HotelCityNames as ct_name1,
		to_key as pt_tourkey,
		to_name as pt_tourname, 
		tl_webhttp as pt_toururl, 
		tl_rate as pt_rate,
		dbo.mwTop5TourDates(to_cnkey, to_key, tl_key, 0) as dates, 
		TO_HotelNights as nights,
		TO_MinPrice as min_price,
		to_DateCreated pt_tourcreated,
		to_trkey pt_trkey,
		pld_HotelKeys as hotelkeys,
		pld_HotelCityKeys as ctkeys,
		tp_name as pttourtype,
		tl_tip as pt_tourtype,
		to_attribute,
		pld_AirlineNames as airline,
		pld_AirlineKeys as airlinekeys,
		replace(replace(pld_ServiceClassesNames, ';', '<br/>'), ',', ' ') as tourdescr 
	from tp_tours with(nolock)
		left join PriceListDetails with(nolock) on pld_tokey = to_key
		left join turlist with(nolock) on tl_key = to_trkey
		left join tiptur with(nolock) on tp_key=tl_tip
		left join dbo.Country with(nolock) on to_cnkey = cn_key
		left join dbo.CityDictionary with(nolock) on tl_ctdeparturekey = ct_key
	where TO_IsEnabled > 0 
			and TO_DateValid >= getdate() 
			and (isnull(@onlySpo, 0) = 0 or (to_attribute & 1) > 0 )
			and (isnull(@tourKey, 0) in (0, to_key))
			and (isnull(@countryKey, 0) in (0, to_cnkey))
			and (isnull(@cityFromKey, 0) in (0, ct_key))
end
go

grant exec on dbo.mwTourInfo to public
go

/*********************************************************************/
/* end sp_mwTourInfo.sql */
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
			pt_actual smallint,
			pt_visadeadline datetime
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
/* begin sp_RowHasChild.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RowHasChild]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[RowHasChild] 
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
else if @sTableName='UserList'
begin
	IF OBJECT_ID('FIN_CHECK_KEY') IS NOT NULL
	BEGIN
		execute FIN_CHECK_KEY 'USERLIST', 'US_KEY', @nKey, @nHasChild OUTPUT
	END
end
GO

GRANT EXECUTE ON [dbo].[RowHasChild] TO PUBLIC 
GO
/*********************************************************************/
/* end sp_RowHasChild.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_SetDogovorState.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetDogovorState]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SetDogovorState]
GO

CREATE PROCEDURE [dbo].[SetDogovorState]
	(
		@dg_key int
	)
AS
BEGIN	
	DECLARE @sUpdateMainDogovorStatuses varchar(254)	
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

	select @sUpdateMainDogovorStatuses = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSUpdateMainDogStatuses'
	IF @new_dg_sor_code is not null and @old_dg_sor_code != @new_dg_sor_code
	BEGIN	
		if (ISNULL(@sUpdateMainDogovorStatuses, '0') = '0')
		begin
			UPDATE dbo.tbl_Dogovor
				SET dg_sor_code = @new_dg_sor_code
			WHERE dg_key = @dg_key 
			and DG_TURDATE != '18991230'
			and dg_sor_code != @new_dg_sor_code
		end
		else
		begin
			UPDATE dbo.tbl_Dogovor
				SET dg_sor_code = @new_dg_sor_code
			WHERE dg_key = @dg_key 
			and DG_Sor_Code in (1, 2, 3, 7) 
			and DG_TURDATE != '18991230'
			and dg_sor_code != @new_dg_sor_code
		end
		
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
/* begin T_BillsDelete.sql */
/*********************************************************************/
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



/*********************************************************************/
/* end T_BillsDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_CalendarsCalculateCalendar.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CalendarsCalculateCalendar]'))
DROP TRIGGER [dbo].[T_CalendarsCalculateCalendar]
GO

CREATE TRIGGER [dbo].[T_CalendarsCalculateCalendar]
   ON [dbo].[Calendars]
   AFTER INSERT, DELETE, UPDATE
AS 
BEGIN
	
	DECLARE @OCL_DateFrom datetime
	DECLARE @OCL_DateTo datetime
	DECLARE @NCL_DateFrom datetime
	DECLARE @NCL_DateTo datetime
	DECLARE @sHI_Text varchar(255)
	DECLARE @nHIID int
	DECLARE @OtempDate varchar(20)
	DECLARE @NtempDate varchar(20)
	
	declare @clKey int

	declare cur_CalendarsCalculateCalendar cursor local fast_forward for
	select ins.CL_KEY, ins.CL_DateFrom, ins.CL_DateTo, del.CL_DateFrom, del.CL_DateTo
	from inserted as ins join deleted as del on ins.CL_Key = del.CL_Key
	where (ins.CL_DateFrom != del.CL_DateFrom or ins.CL_DateTo != del.CL_DateTo)

	open cur_CalendarsCalculateCalendar
	
	fetch next from cur_CalendarsCalculateCalendar into @clKey, @NCL_DateFrom, @NCL_DateTo, @OCL_DateFrom, @OCL_DateTo
	while @@FETCH_STATUS = 0
	begin
		-- запись в историю
		SET @sHI_Text = 'Изменение даты календаря'

		EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 35,
							@nTypeCode = @clKey,
							@sMod = 'UPD',
							@sText = @sHI_Text,
							@sRemark = '',
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = null,
							@nCode = null
		set @OtempDate = convert(nvarchar(max), @OCL_DateFrom, 104)
		set @NtempDate = convert(nvarchar(max), @NCL_DateFrom, 104)
		EXECUTE dbo.InsertHistoryDetail @nHIID, 35001, @OtempDate, @NtempDate, null, null, @OCL_DateFrom, @NCL_DateFrom, 0
		
		set @OtempDate = convert(nvarchar(max), @OCL_DateTo, 104)
		set @NtempDate = convert(nvarchar(max), @NCL_DateTo, 104)
		EXECUTE dbo.InsertHistoryDetail @nHIID, 35002, @OtempDate, @NtempDate, null, null, @OCL_DateTo, @NCL_DateTo, 0
		
		exec CalculateCalendar @clKey
		exec CalculateCalendarDeadLines @clKey
		fetch next from cur_CalendarsCalculateCalendar into @clKey, @NCL_DateFrom, @NCL_DateTo, @OCL_DateFrom, @OCL_DateTo
	end
	
	close cur_CalendarsCalculateCalendar
	deallocate cur_CalendarsCalculateCalendar
END

GO



/*********************************************************************/
/* end T_CalendarsCalculateCalendar.sql */
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
/* begin T_mwDeletePrice.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwDeletePrice]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[mwDeletePrice]
GO

CREATE trigger [dbo].[mwDeletePrice] on [dbo].[TP_Prices] for delete as
begin	
	if dbo.mwReplIsPublisher() > 0
		insert into dbo.mwDeleted with(rowlock) (del_key) select tp_key from deleted
end
GO
/*********************************************************************/
/* end T_mwDeletePrice.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_PrtBonusDetailsChange.sql */
/*********************************************************************/
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



/*********************************************************************/
/* end T_PrtBonusDetailsChange.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_QuotaDetailsChange.sql */
/*********************************************************************/
if not exists (select 1 from ObjectAliases where OA_Id = 34)
	insert into ObjectAliases(OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (34, 'QuotaDetails', 'Квоты', 0)	
if not exists (select 1 from ObjectAliases where OA_Id = 34001)
	insert into ObjectAliases(OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (34001, 'QD_Type', 'Тип квоты', 0)
if not exists (select 1 from ObjectAliases where OA_Id = 34002)
	insert into ObjectAliases(OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (34002, 'QD_Date', 'Дата квоты', 0)
if not exists (select 1 from ObjectAliases where OA_Id = 34003)
	insert into ObjectAliases(OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (34003, 'QD_Places', 'Места в квоте', 0)
if not exists (select 1 from ObjectAliases where OA_Id = 34004)
	insert into ObjectAliases(OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (34004, 'QD_Busy', 'Занятые места в квоте', 0)
if not exists (select 1 from ObjectAliases where OA_Id = 34005)
	insert into ObjectAliases(OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (34005, 'QD_Release', 'Релиз период в квоте', 0)
if not exists (select 1 from ObjectAliases where OA_Id = 34006)
	insert into ObjectAliases(OA_Id, OA_Alias, OA_Name, OA_TABLEID)
	values (34006, 'QD_IsDeleted', 'Удаление квоты', 0)


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_QuotaDetailsChange]'))
DROP TRIGGER [dbo].[T_QuotaDetailsChange]
GO

CREATE TRIGGER [dbo].[T_QuotaDetailsChange]
ON [dbo].[QuotaDetails]
FOR UPDATE, INSERT, DELETE
AS
--<VERSION>2008.1.01.03a</VERSION>
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
/* begin T_ServiceByDateChanged.sql */
/*********************************************************************/
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
    FROM DELETED O	
END
ELSE IF (@nDelCount = 0)
BEGIN
    DECLARE cur_ServiceByDateChanged CURSOR FOR 
    SELECT 	N.SD_ID,
			null, null, null, null, null, null,
			N.SD_DLKey, N.SD_RLID, N.SD_TUKey, N.SD_QPID, N.SD_State, N.SD_Date			
    FROM	INSERTED N
END
ELSE 
BEGIN
    DECLARE cur_ServiceByDateChanged CURSOR FOR 
    SELECT 	N.SD_ID,
			O.SD_DLKey, O.SD_RLID, O.SD_TUKey, O.SD_QPID, O.SD_State, O.SD_Date,
	  		N.SD_DLKey, N.SD_RLID, N.SD_TUKey, N.SD_QPID, N.SD_State, N.SD_Date			
    FROM DELETED O, INSERTED N
    WHERE N.SD_ID = O.SD_ID
END

select @sServiceStatusToHistory = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSServiceStatusToHistory'

OPEN cur_ServiceByDateChanged
FETCH NEXT FROM cur_ServiceByDateChanged 
	INTO @SDID, @O_SD_DLKey, @O_SD_RLID, @O_SD_TUKEY, @O_SD_QPID, @O_SD_State, @O_SD_Date,
				@N_SD_DLKey, @N_SD_RLID, @N_SD_TUKEY, @N_SD_QPID, @N_SD_State, @N_SD_Date
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
				
				UPDATE	QuotaParts SET QP_CheckInPlacesBusy=(
					SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate, tbl_DogovorList join [Service] on DL_SVKey = SV_KEY WHERE SD_QPID=@O_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1) 
				WHERE QP_ID=@O_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID = @O_SD_QPID) WHERE QP_ID = @O_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(*) FROM QuotaParts, ServiceByDate WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@O_SD_QPID)
				
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
				
				UPDATE	QuotaParts SET QP_CheckInPlacesBusy=(
					SELECT COUNT(DISTINCT SD_RLID) FROM ServiceByDate, tbl_DogovorList join [Service] on DL_SVKey = SV_KEY WHERE SD_QPID=@N_SD_QPID AND SD_DATE=DL_DATEBEG AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1) 
				WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
			ELSE
			BEGIN
				UPDATE	QuotaParts SET QP_LastUpdate = GetDate(), QP_Busy=(SELECT COUNT(*) FROM ServiceByDate WHERE SD_QPID=@N_SD_QPID) WHERE QP_ID=@N_SD_QPID
				UPDATE  QuotaDetails SET QD_Busy=(SELECT COUNT(*) FROM QuotaParts, ServiceByDate WHERE SD_QPID=QP_ID and QP_QDID=QD_ID) WHERE QD_ID in (SELECT QP_QDID FROM QuotaParts WHERE QP_ID=@N_SD_QPID)
				
				UPDATE	QuotaParts 
				SET QP_CheckInPlacesBusy=(	SELECT COUNT(*) 
											FROM ServiceByDate,
											tbl_DogovorList join [Service] on DL_SVKey = SV_KEY
											WHERE SD_QPID=@N_SD_QPID AND SD_DATE=DL_DATEBEG 
											AND SD_DLKey = DL_Key and isnull(SV_IsDuration, 0) = 1)
				WHERE QP_ID=@N_SD_QPID AND QP_CheckInPlaces IS NOT NULL
			END
		END
	END
	if (ISNULL(@sServiceStatusToHistory, '0') != '0')
	begin
		declare @dlKey int
		
		if (@O_SD_DLKey is not null)
		begin
			set @dlKey = @O_SD_DLKey
		end
		else
		begin
			set @dlKey = @N_SD_DLKey
		end
		
		-- изменилась состояние квотирования
		if (ISNULL(@O_SD_STATE, 0) != ISNULL(@N_SD_STATE, 0))
		begin
			insert into QuotedStateHistory(QSH_DlKey, QSH_StateOld, QSH_StateNew)
			values (@dlKey, @O_SD_STATE, @N_SD_STATE)
		end
		-- изменилась квота
		if (ISNULL(@O_SD_QPID, 0) != ISNULL(@N_SD_QPID, 0))
		begin
			insert into QuotedStateHistory(QSH_DlKey, QSH_QPIdOld, QSH_QPIdNew)
			values (@dlKey, @O_SD_QPID, @N_SD_QPID)
		end
		-- изменился турист
		if (ISNULL(@O_SD_TUKEY, 0) != ISNULL(@N_SD_TUKEY, 0))
		begin
			insert into QuotedStateHistory(QSH_DlKey, QSH_TUKeyOld, QSH_TUKeyNew)
			values (@dlKey, @O_SD_TUKEY, @N_SD_TUKEY)
		end
	end
	FETCH NEXT FROM cur_ServiceByDateChanged 
		INTO @SDID, @O_SD_DLKey, @O_SD_RLID, @O_SD_TUKEY, @O_SD_QPID, @O_SD_State, @O_SD_Date,
					@N_SD_DLKey, @N_SD_RLID, @N_SD_TUKEY, @N_SD_QPID, @N_SD_State, @N_SD_Date
END
IF @O_SD_DLKey is not null and @N_SD_DLKey is null
	IF exists (SELECT 1 FROM RoomNumberLists WHERE RL_ID not in (SELECT SD_RLID FROM ServiceByDate) )
		DELETE FROM RoomNumberLists WHERE RL_ID not in (SELECT SD_RLID FROM ServiceByDate)

CLOSE cur_ServiceByDateChanged
DEALLOCATE cur_ServiceByDateChanged


GO



/*********************************************************************/
/* end T_ServiceByDateChanged.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_ServiceListCalculateCalendarDeadLines.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_ServiceListCalculateCalendarDeadLines]'))
DROP TRIGGER [dbo].[T_ServiceListCalculateCalendarDeadLines]
GO

CREATE TRIGGER [dbo].[T_ServiceListCalculateCalendarDeadLines]
   ON [dbo].[ServiceList]
   AFTER UPDATE
AS 
BEGIN
	declare @clKey int

	declare cur_CalendarsCalculateCalendarDeadLines cursor local fast_forward for
	select distinct CD_CLKey
	from inserted as ins join deleted as del on ins.sl_key = del.sl_key
	join CalendarDeadLines on CD_SLKey = ins.sl_key
	where ins.SL_DaysCountMin != del.SL_DaysCountMin

	open cur_CalendarsCalculateCalendarDeadLines
	
	fetch next from cur_CalendarsCalculateCalendarDeadLines into @clKey
	while @@FETCH_STATUS = 0
	begin
		exec CalculateCalendarDeadLines @clKey
		fetch next from cur_CalendarsCalculateCalendarDeadLines into @clKey
	end
	
	close cur_CalendarsCalculateCalendarDeadLines
	deallocate cur_CalendarsCalculateCalendarDeadLines
END

GO



/*********************************************************************/
/* end T_ServiceListCalculateCalendarDeadLines.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TuristUpdate.sql */
/*********************************************************************/
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
	DECLARE @OTU_ISANKETA smallint
    
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
	DECLARE @NTU_ISANKETA smallint

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
				N.TU_ISANKETA
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
				O.TU_ISANKETA,
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
				O.TU_ISANKETA,
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
				N.TU_ISANKETA
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
				@OTU_ISANKETA,
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
				@NTU_ISANKETA
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
			ISNULL(@OTU_ISMAIN, 0) != ISNULL(@NTU_ISMAIN, 0) OR
			ISNULL(@OTU_ISANKETA, -1) != ISNULL(@NTU_ISANKETA, -1)
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
		IF (ISNULL(@OTU_ISANKETA, -1) != ISNULL(@NTU_ISANKETA, -1))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1143, @OTU_ISANKETA, @NTU_ISANKETA, null, null, null, null, 0, @bNeedCommunicationUpdate output
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
				@OTU_ISANKETA,
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
				@NTU_ISANKETA
    END
  CLOSE cur_Turist
  DEALLOCATE cur_Turist
END
GO
/*********************************************************************/
/* end T_TuristUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_VisaTSChange.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_VisaTSChange]'))
	DROP TRIGGER [dbo].[T_VisaTSChange]
GO

CREATE TRIGGER [dbo].[T_VisaTSChange] ON [dbo].[VisaTouristService]
FOR UPDATE
AS
IF @@ROWCOUNT > 0
BEGIN
    DECLARE @VTS_ID int
    DECLARE @VTS_TUIDKEY int
    DECLARE @OVTS_Result int
    DECLARE @OVTS_Comment varchar(255)
    DECLARE @OVTS_DocCompleteDate varchar(16)
    DECLARE @OVTS_FromEmbassy varchar(16)
    DECLARE @OVTS_GetVisaDate varchar(16)
    DECLARE @OVTS_InterviewDate varchar(16)
    DECLARE @OVTS_ToEmbassy varchar(16)
    DECLARE @OVTS_DocToVisaDept varchar(16)
    DECLARE @OVTS_IsChecked int

    DECLARE @OVTS_IsCheckedChangeDate varchar(16)
    DECLARE @OVTS_ResultChangeDate varchar(16)

    DECLARE @NVTS_Result int
    DECLARE @NVTS_Comment varchar(255)
    DECLARE @NVTS_DocCompleteDate varchar(16)
    DECLARE @NVTS_FromEmbassy varchar(16)
    DECLARE @NVTS_GetVisaDate varchar(16)
    DECLARE @NVTS_InterviewDate varchar(16)
    DECLARE @NVTS_ToEmbassy varchar(16)
    DECLARE @NVTS_DocToVisaDept varchar(16)
    DECLARE @NVTS_IsChecked int

    DECLARE @NVTS_IsCheckedChangeDate varchar(16)
    DECLARE @NVTS_ResultChangeDate varchar(16)

    DECLARE @sText_Old varchar(255)
    DECLARE @sText_New varchar(255)
/*
	DECLARE @TU_IDKey int
	DECLARE @nDLKey int
	DECLARE @nTUKey int
*/	DECLARE @nHIID int
	DECLARE @sDGCode varchar(10)
	DECLARE @nDGKey		int
	DECLARE @sTUName varchar(32)
	DECLARE @sDLName varchar(170)

	DECLARE @sMod varchar(3)
	DECLARE @nDelCount int
	DECLARE @nInsCount int

  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED
 -- IF (@nDelCount = 0)
 -- BEGIN
	--SET @sMod = 'INS'
 --   DECLARE cur_VisaTouristService CURSOR FOR 
 --     SELECT	N.VTS_ID, N.VTS_TUIDKEY,
	--			null, null, null, null, 
	--			null, null, null,				
	--			N.VTS_Result, N.VTS_Comment, N.VTS_IsChecked,
	--			CONVERT( char(11), N.VTS_DocCompleteDate, 104) + CONVERT( char(5), N.VTS_DocCompleteDate, 108),
	--			CONVERT( char(11), N.VTS_FromEmbassy, 104) + CONVERT( char(5), N.VTS_FromEmbassy, 108),
	--			CONVERT( char(11), N.VTS_GetVisaDate, 104) + CONVERT( char(5), N.VTS_GetVisaDate, 108),
	--			CONVERT( char(11), N.VTS_InterviewDate, 104) + CONVERT( char(5), N.VTS_InterviewDate, 108),
	--			CONVERT( char(11), N.VTS_ToEmbassy, 104) + CONVERT( char(5), N.VTS_ToEmbassy, 108),  
	--			CONVERT( char(11), N.VTS_DocToVisaDept, 104) + CONVERT( char(5), N.VTS_DocToVisaDept, 108)    
	--FROM INSERTED N 
 -- END
 -- ELSE IF (@nInsCount = 0)
 -- BEGIN
	--SET @sMod = 'DEL'
 --   DECLARE cur_VisaTouristService CURSOR FOR 
 --     SELECT	O.VTS_ID, O.VTS_TUIDKEY, 
	--			O.VTS_Result, O.VTS_Comment, O.VTS_IsChecked,
	--			CONVERT( char(11), O.VTS_DocCompleteDate, 104) + CONVERT( char(5), O.VTS_DocCompleteDate, 108),
	--			CONVERT( char(11), O.VTS_FromEmbassy, 104) + CONVERT( char(5), O.VTS_FromEmbassy, 108),
	--			CONVERT( char(11), O.VTS_GetVisaDate, 104) + CONVERT( char(5), O.VTS_GetVisaDate, 108),
	--			CONVERT( char(11), O.VTS_InterviewDate, 104) + CONVERT( char(5), O.VTS_InterviewDate, 108),
	--			CONVERT( char(11), O.VTS_ToEmbassy, 104) + CONVERT( char(5), O.VTS_ToEmbassy, 108),
	--			CONVERT( char(11), O.VTS_DocToVisaDept, 104) + CONVERT( char(5), O.VTS_DocToVisaDept, 108),
	--			null, null, null, null, 
	--			null, null, null
 --     FROM DELETED O 
 -- END
 -- ELSE 
 -- BEGIN
	SET @sMod = 'UPD'
    DECLARE cur_VisaTouristService CURSOR FOR 
      SELECT	N.VTS_ID, N.VTS_TUIDKEY,
				O.VTS_Result, O.VTS_Comment, O.VTS_IsChecked,
				CONVERT( char(11), O.VTS_DocCompleteDate, 104) + CONVERT( char(5), O.VTS_DocCompleteDate, 108),
				CONVERT( char(11), O.VTS_FromEmbassy, 104) + CONVERT( char(5), O.VTS_FromEmbassy, 108),
				CONVERT( char(11), O.VTS_GetVisaDate, 104) + CONVERT( char(5), O.VTS_GetVisaDate, 108),
				CONVERT( char(11), O.VTS_InterviewDate, 104) + CONVERT( char(5), O.VTS_InterviewDate, 108),
				CONVERT( char(11), O.VTS_ToEmbassy, 104) + CONVERT( char(5), O.VTS_ToEmbassy, 108),
				CONVERT( char(11), O.VTS_DocToVisaDept, 104) + CONVERT( char(5), O.VTS_DocToVisaDept, 108),
				CONVERT( char(11), O.VTS_ResultChangeDate, 104) + CONVERT( char(5), O.VTS_ResultChangeDate, 108),
				CONVERT( char(11), O.VTS_IsCheckedChangeDate, 104) + CONVERT( char(5), O.VTS_IsCheckedChangeDate, 108),
				N.VTS_Result, N.VTS_Comment, N.VTS_IsChecked,
				CONVERT( char(11), N.VTS_DocCompleteDate, 104) + CONVERT( char(5), N.VTS_DocCompleteDate, 108),
				CONVERT( char(11), N.VTS_FromEmbassy, 104) + CONVERT( char(5), N.VTS_FromEmbassy, 108),
				CONVERT( char(11), N.VTS_GetVisaDate, 104) + CONVERT( char(5), N.VTS_GetVisaDate, 108),
				CONVERT( char(11), N.VTS_InterviewDate, 104) + CONVERT( char(5), N.VTS_InterviewDate, 108),
				CONVERT( char(11), N.VTS_ToEmbassy, 104) + CONVERT( char(5), N.VTS_ToEmbassy, 108),
				CONVERT( char(11), N.VTS_DocToVisaDept, 104) + CONVERT( char(5), N.VTS_DocToVisaDept, 108),
				CONVERT( char(11), N.VTS_ResultChangeDate, 104) + CONVERT( char(5), N.VTS_ResultChangeDate, 108),
				CONVERT( char(11), N.VTS_IsCheckedChangeDate, 104) + CONVERT( char(5), N.VTS_IsCheckedChangeDate, 108)
      FROM DELETED O, INSERTED N 
      WHERE N.VTS_ID = O.VTS_ID
  --END

  OPEN cur_VisaTouristService
    FETCH NEXT FROM cur_VisaTouristService 
				INTO @VTS_ID, @VTS_TUIDKEY,
				@OVTS_Result, @OVTS_Comment, @OVTS_IsChecked, @OVTS_DocCompleteDate, @OVTS_FromEmbassy, @OVTS_GetVisaDate, 
				@OVTS_InterviewDate, @OVTS_ToEmbassy, @OVTS_DocToVisaDept, @OVTS_ResultChangeDate, @OVTS_IsCheckedChangeDate,
				@NVTS_Result, @NVTS_Comment, @NVTS_IsChecked, @NVTS_DocCompleteDate, @NVTS_FromEmbassy, @NVTS_GetVisaDate, 
				@NVTS_InterviewDate, @NVTS_ToEmbassy, @NVTS_DocToVisaDept, @NVTS_ResultChangeDate, @NVTS_IsCheckedChangeDate

    WHILE @@FETCH_STATUS = 0
    BEGIN 
	  ------------Проверка, надо ли что-то писать в историю-------------------------------------------   
	  If (	@sMod = 'INS' OR @sMod = 'DEL' OR
			ISNULL(@OVTS_Result, 0) != ISNULL(@NVTS_Result, 0) OR
			ISNULL(@OVTS_Comment, '') != ISNULL(@NVTS_Comment, '') OR
			ISNULL(@OVTS_IsChecked, '') != ISNULL(@NVTS_IsChecked, '') OR
			ISNULL(@OVTS_DocCompleteDate, '') != ISNULL(@NVTS_DocCompleteDate, '') OR
			ISNULL(@OVTS_FromEmbassy, '') != ISNULL(@NVTS_FromEmbassy, '') OR
			ISNULL(@OVTS_GetVisaDate, '') != ISNULL(@NVTS_GetVisaDate, '') OR
			ISNULL(@OVTS_InterviewDate, '') != ISNULL(@NVTS_InterviewDate, '') OR
			ISNULL(@OVTS_ToEmbassy, '') != ISNULL(@NVTS_ToEmbassy, '') OR
			ISNULL(@OVTS_DocToVisaDept, '') != ISNULL(@NVTS_DocToVisaDept, '') OR
			ISNULL(@OVTS_ResultChangeDate, '') != ISNULL(@NVTS_ResultChangeDate, '') OR
			ISNULL(@OVTS_IsCheckedChangeDate, '') != ISNULL(@NVTS_IsCheckedChangeDate, '')
		)
	  BEGIN
	  	------------Запись в историю--------------------------------------------------------------------

		SELECT 	@sTUName = LEFT(ISNULL(TU_NAMERUS, '') + ' ' + ISNULL(TU_SHORTNAME, ''),25), @sDLName = DL_NAME,  @sDGCode = DL_DGCOD, @nDGKey = DL_DGKEY
		FROM tbl_Turist,TuristService,tbl_DogovorList 
		WHERE TU_Key = TU_TUKey and  TU_IDKey = @VTS_TUIDKEY and TU_DLKey = DL_Key
		
		EXEC @nHIID = dbo.InsHistory @sDGCode, @nDGKey, 4, @VTS_TUIDKEY, @sMod, @sDLName, @sTUName, 0, ''
		--SELECT @nHIID = IDENT_CURRENT('History')
		--------Детализация--------------------------------------------------

			EXECUTE dbo.InsertHistoryDetail @nHIID , 1076, null, null, @VTS_ID, @VTS_ID, null, null, 1
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1077, null, null, @VTS_TUIDKEY, @VTS_TUIDKEY, null, null, 1
		if (ISNULL(@OVTS_Result, 0) != ISNULL(@NVTS_Result, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1078, @OVTS_Result, @NVTS_Result, @OVTS_Result, @NVTS_Result, null, null, 0
		if (ISNULL(@OVTS_Comment, '') != ISNULL(@NVTS_Comment, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1079, @OVTS_Comment, @NVTS_Comment, null, null, null, null, 0
		if (ISNULL(@OVTS_DocCompleteDate, '') != ISNULL(@NVTS_DocCompleteDate, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1080, @OVTS_DocCompleteDate, @NVTS_DocCompleteDate, null, null, null, null, 0
		if (ISNULL(@OVTS_FromEmbassy, '') != ISNULL(@NVTS_FromEmbassy, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1081, @OVTS_FromEmbassy, @NVTS_FromEmbassy, null, null, null, null, 0
		if (ISNULL(@OVTS_GetVisaDate, '') != ISNULL(@NVTS_GetVisaDate, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1082, @OVTS_GetVisaDate, @NVTS_GetVisaDate, null, null, null, null, 0
		if (ISNULL(@OVTS_InterviewDate, '') != ISNULL(@NVTS_InterviewDate, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1083, @OVTS_InterviewDate, @NVTS_InterviewDate, null, null, null, null, 0
		if (ISNULL(@OVTS_ToEmbassy, '') != ISNULL(@NVTS_ToEmbassy, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1084, @OVTS_ToEmbassy, @NVTS_ToEmbassy, null, null, null, null, 0
		if (ISNULL(@OVTS_IsChecked, '') != ISNULL(@NVTS_IsChecked, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1142, @OVTS_IsChecked, @NVTS_IsChecked, null, null, null, null, 0
		if (ISNULL(@OVTS_DocToVisaDept, '') != ISNULL(@NVTS_DocToVisaDept, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1141, @OVTS_DocToVisaDept, @NVTS_DocToVisaDept, null, null, null, null, 0
		if (ISNULL(@OVTS_ResultChangeDate, '') != ISNULL(@NVTS_ResultChangeDate, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1144, @OVTS_ResultChangeDate, @NVTS_ResultChangeDate, null, null, null, null, 0
		if (ISNULL(@OVTS_IsCheckedChangeDate, '') != ISNULL(@NVTS_IsCheckedChangeDate, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 1145, @OVTS_IsCheckedChangeDate, @NVTS_IsCheckedChangeDate, null, null, null, null, 0
	  ------------------------------------------------------------------------------------------------
	  END
		 FETCH NEXT FROM cur_VisaTouristService 
				INTO @VTS_ID, @VTS_TUIDKEY,
				@OVTS_Result, @OVTS_Comment, @OVTS_IsChecked, @OVTS_DocCompleteDate, @OVTS_FromEmbassy, @OVTS_GetVisaDate, 
				@OVTS_InterviewDate, @OVTS_ToEmbassy, @OVTS_DocToVisaDept, @OVTS_ResultChangeDate, @OVTS_IsCheckedChangeDate,
				@NVTS_Result, @NVTS_Comment, @NVTS_IsChecked, @NVTS_DocCompleteDate, @NVTS_FromEmbassy, @NVTS_GetVisaDate, 
				@NVTS_InterviewDate, @NVTS_ToEmbassy, @NVTS_DocToVisaDept, @NVTS_ResultChangeDate, @NVTS_IsCheckedChangeDate
    END
  CLOSE cur_VisaTouristService
  DEALLOCATE cur_VisaTouristService
END

GO



/*********************************************************************/
/* end T_VisaTSChange.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Trigger_CalendarDeadlines.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CalendarDeadlinesChange]'))
DROP TRIGGER [dbo].[T_CalendarDeadlinesChange]
GO

CREATE TRIGGER [dbo].[T_CalendarDeadlinesChange]
ON [dbo].[CalendarDeadLines] 
FOR UPDATE, INSERT, DELETE
AS
IF @@ROWCOUNT > 0
BEGIN

DECLARE @OCD_Id int        
DECLARE @OCD_CLKey int
DECLARE @OCD_CTKey int
DECLARE @OCD_SLKey int
DECLARE @OCD_ArrivalDate datetime
DECLARE @OCD_DeadLineConsulateDate datetime
DECLARE @OCD_DeadLineAgencyDate datetime
DECLARE @OCD_Description varchar(255)
DECLARE @OCT_Name varchar(255)
DECLARE @OSL_Name varchar(255)

DECLARE @NCD_Id int              
DECLARE @NCD_CLKey int
DECLARE @NCD_CTKey int
DECLARE @NCD_SLKey int
DECLARE @NCD_ArrivalDate datetime
DECLARE @NCD_DeadLineConsulateDate datetime
DECLARE @NCD_DeadLineAgencyDate datetime
DECLARE @NCD_Description varchar(255)
DECLARE @NCT_Name varchar(255)
DECLARE @NSL_Name varchar(255)

DECLARE @SC_Key int

DECLARE @sMod varchar(3)
DECLARE @sHI_CalendarDeadlinesText varchar(255)
DECLARE @sHI_Text varchar(255)
DECLARE @nHIID int
DECLARE @nDelCount int
DECLARE @nInsCount int

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED

IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_CalendarDeadlines CURSOR LOCAL FOR 
		select null,null,null,null,null,null,null,null,null,null,
		CD_Id,CD_CLKey,CD_CTKey,CD_SLKey,CD_ArrivalDate,CD_DeadLineConsulateDate,CD_DeadLineAgencyDate, CD_Description, CT_Name, SL_Name
		from inserted, Citydictionary, ServiceList
		where CD_CTKey = CT_key and CD_SLKey = SL_Key
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_CalendarDeadlines CURSOR LOCAL FOR 
		select CD_Id,CD_CLKey,CD_CTKey,CD_SLKey,CD_ArrivalDate,CD_DeadLineConsulateDate,CD_DeadLineAgencyDate, CD_Description, CT_Name, SL_Name,
		null,null,null,null,null,null,null,null,null,null
		from deleted, Citydictionary, ServiceList
		where CD_CTKey = CT_key and CD_SLKey = SL_Key
  END
  ELSE
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_CalendarDeadlines CURSOR LOCAL FOR 
		select O.CD_Id,O.CD_CLKey,O.CD_CTKey,O.CD_SLKey,O.CD_ArrivalDate,O.CD_DeadLineConsulateDate,O.CD_DeadLineAgencyDate, O.CD_Description, Oct.CT_Name, Osl.SL_Name,
			N.CD_Id,N.CD_CLKey,N.CD_CTKey,N.CD_SLKey,N.CD_ArrivalDate,N.CD_DeadLineConsulateDate,N.CD_DeadLineAgencyDate, N.CD_Description, Nct.CT_Name, Nsl.SL_Name
		from Deleted O, Inserted N, Citydictionary Oct, ServiceList Osl, Citydictionary Nct, ServiceList Nsl
		where O.CD_Id = N.CD_Id and O.CD_CTKey = Oct.CT_Key and O.CD_SLKey = Osl.SL_Key
		and N.CD_CTKey = Nct.CT_Key and N.CD_SLKey = Nsl.SL_Key
  END
  
  OPEN cur_CalendarDeadlines
	FETCH NEXT FROM cur_CalendarDeadlines INTO @OCD_Id,@OCD_CLKey,@OCD_CTKey,@OCD_SLKey,@OCD_ArrivalDate,@OCD_DeadLineConsulateDate,@OCD_DeadLineAgencyDate,@OCD_Description,@OCT_Name,@OSL_Name,       
      @NCD_Id,@NCD_CLKey,@NCD_CTKey,@NCD_SLKey,@NCD_ArrivalDate,@NCD_DeadLineConsulateDate,@NCD_DeadLineAgencyDate,@NCD_Description,@NCT_Name,@NSL_Name
	WHILE @@FETCH_STATUS = 0
	
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OCD_CTKey, 0) != ISNULL(@NCD_CTKey, 0) OR
			ISNULL(@OCD_CLKey, 0) != ISNULL(@NCD_CLKey, 0) OR
			ISNULL(@OCD_ArrivalDate, 0) != ISNULL(@NCD_ArrivalDate, 0) OR
			ISNULL(@OCD_DeadLineConsulateDate, 0) != ISNULL(@NCD_DeadLineConsulateDate, 0) OR
			ISNULL(@OCD_DeadLineAgencyDate, 0) != ISNULL(@NCD_DeadLineAgencyDate, 0) OR
			ISNULL(@OCD_Description, 0) != ISNULL(@NCD_Description, 0)
			)
		BEGIN
		------------Запись в историю--------------------------------------------------------------------
		if (@sMod = 'DEL')
		begin
			select @sHI_CalendarDeadlinesText = ISNULL(PR_NAME,'')
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from Deleted,Partners,PartnerCalendarLinkers,Calendars where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CL_key and CD_CLKey = CL_key and CD_CLKey = @OCD_CLKey
			set @SC_Key = @OCD_CLKey
		end
		else
		begin
			select @sHI_CalendarDeadlinesText = ISNULL(PR_NAME,'') 
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from Inserted,Partners,PartnerCalendarLinkers,Calendars where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CL_key and CD_CLKey = CL_key and CD_CLKey = @NCD_CLKey
			set @SC_Key = @NCD_CLKey
		end

	    if (@sMod = 'Del')
		SET @sHI_Text = 'Удаление из крайних сроков ' + @sHI_CalendarDeadlinesText
		else if (@sMod = 'Ins')
		SET @sHI_Text = 'Добавление в крайние сроки ' + @sHI_CalendarDeadlinesText
		else
		SET @sHI_Text = 'Изменение в крайних сроках ' + @sHI_CalendarDeadlinesText

		EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 39,
							@nTypeCode = @SC_Key,
							@sMod = @sMod,
							@sText = @sHI_Text,
							@sRemark = '',
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = null,
							@nCode = null
							
		--------Детализация--------------------------------------------------
			if ISNULL(@OCD_ArrivalDate, 0) != ISNULL(@NCD_ArrivalDate, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 39001, @OCD_ArrivalDate, @NCD_ArrivalDate, null, null, @OCD_ArrivalDate, @NCD_ArrivalDate, 0
			end
			if ISNULL(@OCD_DeadLineConsulateDate, 0) != ISNULL(@NCD_DeadLineConsulateDate, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 39002, @OCD_DeadLineConsulateDate, @NCD_DeadLineConsulateDate, null, null, @OCD_DeadLineConsulateDate, @NCD_DeadLineConsulateDate, 0
			end
			if ISNULL(@OCD_DeadLineAgencyDate, 0) != ISNULL(@NCD_DeadLineAgencyDate, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 39003, @OCD_DeadLineAgencyDate, @NCD_DeadLineAgencyDate, null, null, @OCD_DeadLineAgencyDate, @NCD_DeadLineAgencyDate, 0
			end
			if ISNULL(@OCD_Description, 0) != ISNULL(@NCD_Description, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 39004, @OCD_Description, @NCD_Description, null, null, null, null, 0
			end
			if ISNULL(@OCD_CTKey, 0) != ISNULL(@NCD_CTKey, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 39005, @OCT_Name, @NCT_Name, @OCD_CTKey, @NCD_CTKey, null, null, 0
			end
			if ISNULL(@OCD_SLKey, 0) != ISNULL(@NCD_SLKey, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 39006, @OSL_Name, @NSL_Name, @OCD_SLKey, @NCD_SLKey, null, null, 0
			end
			
			-- запустим перерасчет крайних сроков
			if (@sMod != 'Del')
			begin
				if (ISNULL(@OCD_ArrivalDate, 0) != ISNULL(@NCD_ArrivalDate, 0))
					or (ISNULL(@OCD_DeadLineAgencyDate, 0) != ISNULL(@NCD_DeadLineAgencyDate, 0))
					or (ISNULL(@OCD_CTKey, 0) != ISNULL(@NCD_CTKey, 0))
					or (ISNULL(@OCD_SLKey, 0) != ISNULL(@NCD_SLKey, 0))
				begin
					exec CalculateCalendarDeadLines @NCD_CLKey
				end
			end
		
		END	
		
		FETCH NEXT FROM cur_CalendarDeadlines INTO @OCD_Id,@OCD_CLKey,@OCD_CTKey,@OCD_SLKey,@OCD_ArrivalDate,@OCD_DeadLineConsulateDate,@OCD_DeadLineAgencyDate,@OCD_Description,@OCT_Name,@OSL_Name,       
      @NCD_Id,@NCD_CLKey,@NCD_CTKey,@NCD_SLKey,@NCD_ArrivalDate,@NCD_DeadLineConsulateDate,@NCD_DeadLineAgencyDate,@NCD_Description,@NCT_Name,@NSL_Name
		
	END
	
	CLOSE cur_CalendarDeadlines
	DEALLOCATE cur_CalendarDeadlines
	
END
GO



/*********************************************************************/
/* end Trigger_CalendarDeadlines.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Trigger_CalendarExclusionEvent.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CalendarExclusionsEventChange]'))
DROP TRIGGER [dbo].[T_CalendarExclusionsEventChange]
GO

CREATE TRIGGER [dbo].[T_CalendarExclusionsEventChange]
ON [dbo].[CalendarExclusionsEvent] 
FOR UPDATE, INSERT, DELETE
AS
IF @@ROWCOUNT > 0
BEGIN

DECLARE @OCEE_CEKey int
DECLARE @OCE_CalendarKey int
DECLARE @OCE_Date datetime
DECLARE @OCE_Comment varchar(255)
DECLARE @OCET_Name varchar(255)
DECLARE @OCEE_CETKey int

DECLARE @NCEE_CEKey int
DECLARE @NCE_CalendarKey int
DECLARE @NCE_Date datetime
DECLARE @NCE_Comment varchar(255)
DECLARE @NCET_Name varchar(255)
DECLARE @NCEE_CETKey int

DECLARE @SC_Key int

DECLARE @sMod varchar(3)
DECLARE @sHI_ScheduleText varchar(255)
DECLARE @sHI_Text varchar(255)
DECLARE @nHIID int
DECLARE @nDelCount int
DECLARE @nInsCount int

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED

IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_CalendarExclusionsEvent CURSOR LOCAL FOR 
		SELECT null,null,null,null,null,null,CEE_CEKey,CE_CalendarKey,CE_Date,CE_Comment,CET_Name,CEE_CETKey 
		FROM INSERTED, CalendarEventTypes, CalendarExclusions
		WHERE CEE_CETKey = CET_Key and CEE_CEKey = CE_Key
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_CalendarExclusionsEvent CURSOR LOCAL FOR 
		SELECT CEE_CEKey,CE_CalendarKey,CE_Date,CE_Comment,CET_Name,CEE_CETKey,null,null,null,null,null,null 
		FROM DELETED, CalendarEventTypes, CalendarExclusions
		WHERE CEE_CETKey = CET_Key and CEE_CEKey = CE_Key
  END
  ELSE
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_CalendarExclusionsEvent CURSOR LOCAL FOR 
		SELECT O.CEE_CEKey,Oce.CE_CalendarKey,Oce.CE_Date,Oce.CE_Comment,Ocet.CET_Name,O.CEE_CETKey,
			N.CEE_CEKey,Nce.CE_CalendarKey,Nce.CE_Date,Nce.CE_Comment,Ncet.CET_Name,N.CEE_CETKey
		FROM DELETED O, INSERTED N, CalendarEventTypes Ocet, CalendarExclusions Oce, CalendarEventTypes Ncet, CalendarExclusions Nce
		WHERE O.CEE_CEKey = N.CEE_CEKey and O.CEE_CETKey = N.CEE_CETKey and O.CEE_CETKey = Ocet.CET_Key and O.CEE_CEKey = Oce.CE_Key
		and N.CEE_CETKey = Ncet.CET_Key and N.CEE_CEKey = Nce.CE_Key
  END
  
  OPEN cur_CalendarExclusionsEvent
	FETCH NEXT FROM cur_CalendarExclusionsEvent INTO @OCEE_CEKey,@OCE_CalendarKey,@OCE_Date,@OCE_Comment,@OCET_Name,@OCEE_CETKey,
      @NCEE_CEKey,@NCE_CalendarKey,@NCE_Date,@NCE_Comment,@NCET_Name,@NCEE_CETKey
	WHILE @@FETCH_STATUS = 0
	
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OCEE_CEKey, 0) != ISNULL(@NCEE_CEKey, 0) OR
			ISNULL(@OCEE_CETKey, 0) != ISNULL(@NCEE_CETKey, 0)
			)
		BEGIN
		------------Запись в историю--------------------------------------------------------------------
		if (@sMod = 'DEL')
		begin
			select @sHI_ScheduleText = ISNULL(PR_NAME,'') 
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from Deleted,Partners,CalendarExclusions,PartnerCalendarLinkers,Calendars where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CE_CalendarKey and PCL_CalendarKey = CL_key and CEE_CEKey = CE_Key and CE_CalendarKey = @OCE_CalendarKey
			set @SC_Key = @OCE_CalendarKey
		end
		else
		begin
			select @sHI_ScheduleText = ISNULL(PR_NAME,'') 
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from INSERTED,Partners,CalendarExclusions,PartnerCalendarLinkers,Calendars where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CE_CalendarKey and PCL_CalendarKey = CL_key and CEE_CEKey = CE_Key and CE_CalendarKey = @NCE_CalendarKey
			set @SC_Key = @NCE_CalendarKey
		end

	    if (@sMod = 'Del')
		SET @sHI_Text = 'Удаление из исключений ' + @sHI_ScheduleText
		else
		SET @sHI_Text = 'Добавление в исключения ' + @sHI_ScheduleText

		EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 37,
							@nTypeCode = @SC_Key,
							@sMod = @sMod,
							@sText = @sHI_Text,
							@sRemark = '',
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = null,
							@nCode = null
							
		--------Детализация--------------------------------------------------
			if ISNULL(@OCE_Date, 0) != ISNULL(@NCE_Date, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 37001, @OCE_Date, @NCE_Date, null, null, @OCE_Date, @NCE_Date, 0
			end
			if ISNULL(@OCE_Comment, 0) != ISNULL(@NCE_Comment, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 37002, @OCE_Comment, @NCE_Comment, null, null, null, null, 0
			end
			if ISNULL(@OCET_Name, 0) != ISNULL(@NCET_Name, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 37003, @OCET_Name, @NCET_Name, null, null, null, null, 0
			end
		END
				
		-- запустим пересчет CalendarDates и CalendarDeadLines
		if @NCE_CalendarKey is not null
		begin
			exec CalculateCalendar @NCE_CalendarKey, @NCE_Date, @NCE_Date
			exec CalculateCalendarDeadLines @NCE_CalendarKey
		end
		-- при удалении тоже
		if @OCE_CalendarKey is not null
		begin
			exec CalculateCalendar @OCE_CalendarKey, @NCE_Date, @NCE_Date
			exec CalculateCalendarDeadLines @OCE_CalendarKey
		end
		
		FETCH NEXT FROM cur_CalendarExclusionsEvent INTO @OCEE_CEKey,@OCE_CalendarKey,@OCE_Date,@OCE_Comment,@OCET_Name,@OCEE_CETKey,
      @NCEE_CEKey,@NCE_CalendarKey,@NCE_Date,@NCE_Comment,@NCET_Name,@NCEE_CETKey
		
	END
	
	CLOSE cur_CalendarExclusionsEvent
	DEALLOCATE cur_CalendarExclusionsEvent
	
END
GO



/*********************************************************************/
/* end Trigger_CalendarExclusionEvent.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Trigger_CalendarRegion.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_CalendarRegionChange]'))
DROP TRIGGER [dbo].[T_CalendarRegionChange]
GO

CREATE TRIGGER [dbo].[T_CalendarRegionChange]
ON [dbo].[CalendarRegion] 
FOR UPDATE, INSERT, DELETE
AS
IF @@ROWCOUNT > 0
BEGIN

DECLARE @OCR_CLKey int              
DECLARE @OCR_CTKey int
DECLARE @OCR_AddDay int
DECLARE @OCT_Name varchar(255)

DECLARE @NCR_CLKey int
DECLARE @NCR_CTKey int
DECLARE @NCR_AddDay int
DECLARE @NCT_Name varchar(255)

DECLARE @SC_Key int

DECLARE @sMod varchar(3)
DECLARE @sHI_CalendarRegionText varchar(255)
DECLARE @sHI_Text varchar(255)
DECLARE @nHIID int
DECLARE @nDelCount int
DECLARE @nInsCount int

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED

IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_CalendarRegion CURSOR LOCAL FOR 
		select null,null,null,null,CR_CLKey,CR_CTKey,CR_AddDay,CT_Name 
		from inserted,citydictionary
		where CR_CTKey = CT_Key
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_CalendarRegion CURSOR LOCAL FOR 
		select CR_CLKey,CR_CTKey,CR_AddDay,CT_Name,null,null,null,null 
		from deleted,citydictionary
		where CR_CTKey = CT_Key
  END
  ELSE
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_CalendarRegion CURSOR LOCAL FOR 
		SELECT O.CR_CLKey,O.CR_CTKey,O.CR_AddDay,Oct.CT_Name,
			N.CR_CLKey,N.CR_CTKey,N.CR_AddDay,Nct.CT_Name
		FROM DELETED O, INSERTED N, Citydictionary Oct, Citydictionary Nct
		WHERE O.CR_CLKey = N.CR_CLKey
		and O.CR_CTKey = Oct.CT_Key 
		and N.CR_CTKey = Nct.CT_Key 
  END
  
  OPEN cur_CalendarRegion
	FETCH NEXT FROM cur_CalendarRegion INTO @OCR_CLKey,@OCR_CTKey,@OCR_AddDay,@OCT_Name,
      @NCR_CLKey,@NCR_CTKey,@NCR_AddDay,@NCT_Name
	WHILE @@FETCH_STATUS = 0
	
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OCR_CTKey, 0) != ISNULL(@NCR_CTKey, 0) OR
			ISNULL(@OCR_CLKey, 0) != ISNULL(@NCR_CLKey, 0)
			)
		BEGIN
		------------Запись в историю--------------------------------------------------------------------
		if (@sMod = 'DEL')
		begin
			select @sHI_CalendarRegionText = ISNULL(PR_NAME,'') 
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from Deleted,Partners,PartnerCalendarLinkers,Calendars where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CL_key and CR_CLKey = CL_key and CR_CLKey = @OCR_CLKey
			set @SC_Key = @OCR_CLKey
		end
		else
		begin
			select @sHI_CalendarRegionText = ISNULL(PR_NAME,'') 
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from Inserted,Partners,PartnerCalendarLinkers,Calendars where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CL_key and CR_CLKey = CL_key and CR_CLKey = @NCR_CLKey
			set @SC_Key = @NCR_CLKey
		end

	    if (@sMod = 'Del')
		SET @sHI_Text = 'Удаление из регионов ' + @sHI_CalendarRegionText
		else if (@sMod = 'Ins')
		SET @sHI_Text = 'Добавление в регионы ' + @sHI_CalendarRegionText
		else
		SET @sHI_Text = 'Изменение в регионах ' + @sHI_CalendarRegionText

		EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 38,
							@nTypeCode = @SC_Key,
							@sMod = @sMod,
							@sText = @sHI_Text,
							@sRemark = '',
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = null,
							@nCode = null
							
		--------Детализация--------------------------------------------------
			if ISNULL(@OCR_AddDay, 0) != ISNULL(@NCR_AddDay, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 38001, @OCR_AddDay, @NCR_AddDay, @OCR_AddDay, @NCR_AddDay, null, null, 0
			end
			if ISNULL(@OCR_CTKey, 0) != ISNULL(@NCR_CTKey, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 38002, @OCT_Name, @NCT_Name, null, null, null, null, 0
			end
		
		END	

		exec CalculateCalendarDeadLines @OCR_CLKey
		exec CalculateCalendarDeadLines @NCR_CLKey

		FETCH NEXT FROM cur_CalendarRegion INTO @OCR_CLKey,@OCR_CTKey,@OCR_AddDay,@OCT_Name,
      @NCR_CLKey,@NCR_CTKey,@NCR_AddDay,@NCT_Name
		
	END
	
	CLOSE cur_CalendarRegion
	DEALLOCATE cur_CalendarRegion
	
END

go
/*********************************************************************/
/* end Trigger_CalendarRegion.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Trigger_PartnerCalendarLinker.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_PartnerCalendarLinkerChange]'))
DROP TRIGGER [dbo].[T_PartnerCalendarLinkerChange]
GO

CREATE TRIGGER [dbo].[T_PartnerCalendarLinkerChange]
ON [dbo].[PartnerCalendarLinkers] 
FOR UPDATE, INSERT, DELETE
AS
IF @@ROWCOUNT > 0
BEGIN

DECLARE @PCL_Key int

DECLARE @OPCL_Key int
DECLARE @OPCL_PartnerKey int
DECLARE @OPCL_PartnerName varchar(255)
DECLARE @OPCL_CalendarKey int
DECLARE @OCL_DateFrom datetime
DECLARE @OCL_DateTo datetime
DECLARE @OCL_Comment varchar(255)

DECLARE @NPCL_Key int
DECLARE @NPCL_PartnerKey int
DECLARE @NPCL_PartnerName varchar(255)
DECLARE @NPCL_CalendarKey int
DECLARE @NCL_DateFrom datetime
DECLARE @NCL_DateTo datetime
DECLARE @NCL_Comment varchar(255)

DECLARE @sMod varchar(3)
DECLARE @sHI_CalendarText varchar(255)
DECLARE @sHI_Text varchar(255)
DECLARE @nHIID int
DECLARE @nDelCount int
DECLARE @nInsCount int

DECLARE @OtempDate varchar(20)
DECLARE @NtempDate varchar(20)

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED

IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_PartnerCalendarLinkers CURSOR LOCAL FOR 
      SELECT null,null,null,null,null,null,PCL_Key,PCL_PartnerKey,PCL_CalendarKey,CL_DateFrom,CL_DateTo,CL_Comment
      FROM INSERTED N, Calendars
      WHERE N.PCL_CalendarKey = CL_Key
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_PartnerCalendarLinkers CURSOR LOCAL FOR 
      SELECT PCL_Key,PCL_PartnerKey,PCL_CalendarKey,CL_DateFrom,CL_DateTo,CL_Comment,null,null,null,null,null,null
      FROM DELETED O, Calendars
      WHERE O.PCL_CalendarKey = CL_Key
  END
  ELSE
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_PartnerCalendarLinkers CURSOR LOCAL FOR 
      SELECT O.PCL_Key,O.PCL_PartnerKey,O.PCL_CalendarKey,CL_DateFrom,CL_DateTo,CL_Comment,
      N.PCL_Key,N.PCL_PartnerKey,N.PCL_CalendarKey,CL_DateFrom,CL_DateTo,CL_Comment
      FROM DELETED O, INSERTED N, Calendars
      WHERE N.PCL_CalendarKey = CL_Key and N.PCL_Key = O.PCL_Key
  END
  
  OPEN cur_PartnerCalendarLinkers
	FETCH NEXT FROM cur_PartnerCalendarLinkers INTO @OPCL_Key, @OPCL_PartnerKey, @OPCL_CalendarKey, @OCL_DateFrom, @OCL_DateTo, @OCL_Comment, 
					@NPCL_Key, @NPCL_PartnerKey, @NPCL_CalendarKey, @NCL_DateFrom, @NCL_DateTo, @NCL_Comment
	WHILE @@FETCH_STATUS = 0
	
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OPCL_PartnerKey, 0) != ISNULL(@NPCL_PartnerKey, 0) OR
			ISNULL(@OPCL_CalendarKey, 0) != ISNULL(@NPCL_CalendarKey, 0) OR
			ISNULL(@OCL_DateFrom, 0) != ISNULL(@NCL_DateFrom, 0) OR
			ISNULL(@OCL_DateTo, 0) != ISNULL(@NCL_DateTo, 0) OR
			ISNULL(@OCL_Comment, 0) != ISNULL(@NCL_Comment, 0)
			)
		BEGIN
		------------Запись в историю--------------------------------------------------------------------
		if (@sMod = 'DEL')
		begin
			select @sHI_CalendarText = ISNULL(PR_NAME,'') 
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from Deleted,Partners,Calendars where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CL_Key and PCL_Key = @OPCL_Key
			set @PCL_Key = @OPCL_CalendarKey
		end
		else
		begin
			select @sHI_CalendarText = ISNULL(PR_NAME,'') 
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from PartnerCalendarLinkers,Partners,Calendars where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CL_Key and PCL_Key = @NPCL_Key
			set @PCL_Key = @NPCL_CalendarKey
		end


		SET @sHI_Text = 'Календарь ' + @sHI_CalendarText

		EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 35,
							@nTypeCode = @PCL_Key,
							@sMod = @sMod,
							@sText = @sHI_Text,
							@sRemark = '',
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = null,
							@nCode = null
							
		--------Детализация--------------------------------------------------
			if ISNULL(@OCL_DateFrom, 0) != ISNULL(@NCL_DateFrom, 0)
			begin
				set @OtempDate = convert(nvarchar(max), @OCL_DateFrom, 104)
				set @NtempDate = convert(nvarchar(max), @NCL_DateFrom, 104)
				EXECUTE dbo.InsertHistoryDetail @nHIID, 35001, @OtempDate, @NtempDate, null, null, @OCL_DateFrom, @NCL_DateFrom, 0
			end
			if ISNULL(@OCL_DateTo, 0) != ISNULL(@NCL_DateTo, 0)
			begin
				set @OtempDate = convert(nvarchar(max), @OCL_DateTo, 104)
				set @NtempDate = convert(nvarchar(max), @NCL_DateTo, 104)
				EXECUTE dbo.InsertHistoryDetail @nHIID, 35002, @OtempDate, @NtempDate, null, null, @OCL_DateTo, @NCL_DateTo, 0
			end
			if ISNULL(@OCL_Comment, 0) != ISNULL(@NCL_Comment, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 35003, @OCL_Comment, @NCL_Comment, null, null, null, null, 0
			end
		
		END	
		
		FETCH NEXT FROM cur_PartnerCalendarLinkers INTO @OPCL_Key, @OPCL_PartnerKey, @OPCL_CalendarKey, @OCL_DateFrom, @OCL_DateTo, @OCL_Comment, 
					@NPCL_Key, @NPCL_PartnerKey, @NPCL_CalendarKey, @NCL_DateFrom, @NCL_DateTo, @NCL_Comment
		
	END
	
	CLOSE cur_PartnerCalendarLinkers
	DEALLOCATE cur_PartnerCalendarLinkers
	
END

GO
/*********************************************************************/
/* end Trigger_PartnerCalendarLinker.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Trigger_Schedule.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[T_SchedulesChange]'))
DROP TRIGGER [dbo].[T_SchedulesChange]
GO

CREATE TRIGGER [dbo].[T_SchedulesChange]
ON [dbo].[Schedules] 
FOR UPDATE, INSERT, DELETE
AS
IF @@ROWCOUNT > 0
BEGIN

DECLARE @OSC_Key int
DECLARE @OSC_CalendarWeekDaysKey int
DECLARE @OSC_CalendarWeekDaysName varchar(255)
DECLARE @OSC_CalendarEventTypeKey int
DECLARE @OSC_CalendarEventTypeName varchar(255)
DECLARE @OSC_CalendarKey int

DECLARE @NSC_Key int
DECLARE @NSC_CalendarWeekDaysKey int
DECLARE @NSC_CalendarWeekDaysName varchar(255)
DECLARE @NSC_CalendarEventTypeKey int
DECLARE @NSC_CalendarEventTypeName varchar(255)
DECLARE @NSC_CalendarKey int

DECLARE @SC_Key int

DECLARE @sMod varchar(3)
DECLARE @sHI_ScheduleText varchar(255)
DECLARE @sHI_Text varchar(255)
DECLARE @nHIID int
DECLARE @nDelCount int
DECLARE @nInsCount int

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED

IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_Schedules CURSOR LOCAL FOR 
      SELECT null,null,null,null,null,null,SC_Key,SC_CalendarWeekDaysKey,SC_CalendarEventTypeKey,SC_CalendarKey,CWD_WeekDayNameRus,CET_Name
      FROM INSERTED N, CalendarWeekDays, CalendarEventTypes
      where sc_CalendarWeekDaysKey = CWD_Key and sc_CalendarEventTypeKey = CET_Key
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_Schedules CURSOR LOCAL FOR 
      SELECT SC_Key,SC_CalendarWeekDaysKey,SC_CalendarEventTypeKey,SC_CalendarKey,CWD_WeekDayNameRus,CET_Name,null,null,null,null,null,null
      FROM DELETED O, CalendarWeekDays, CalendarEventTypes
      where sc_CalendarWeekDaysKey = CWD_Key and sc_CalendarEventTypeKey = CET_Key
  END
  ELSE
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_Schedules CURSOR LOCAL FOR 
		SELECT O.SC_Key,O.SC_CalendarWeekDaysKey,O.SC_CalendarEventTypeKey,O.SC_CalendarKey,Ocwd.CWD_WeekDayNameRus,Ocet.CET_Name,
			N.SC_Key,N.SC_CalendarWeekDaysKey,N.SC_CalendarEventTypeKey,N.SC_CalendarKey,Ncwd.CWD_WeekDayNameRus,Ncet.CET_Name
		FROM DELETED O, INSERTED N, CalendarWeekDays Ocwd, CalendarEventTypes Ocet, CalendarWeekDays Ncwd, CalendarEventTypes Ncet
		WHERE N.SC_Key = O.SC_Key and O.SC_CalendarWeekDaysKey = Ocwd.CWD_Key and O.SC_CalendarEventTypeKey = Ocet.CET_Key 
		and N.SC_CalendarWeekDaysKey = Ncwd.CWD_Key and N.SC_CalendarEventTypeKey = Ncet.CET_Key
  END
  
  OPEN cur_Schedules
	FETCH NEXT FROM cur_Schedules INTO @OSC_Key,@OSC_CalendarWeekDaysKey,@OSC_CalendarEventTypeKey,@OSC_CalendarKey,@OSC_CalendarWeekDaysName,@OSC_CalendarEventTypeName,
      @NSC_Key,@NSC_CalendarWeekDaysKey,@NSC_CalendarEventTypeKey,@NSC_CalendarKey,@NSC_CalendarWeekDaysName,@NSC_CalendarEventTypeName
	WHILE @@FETCH_STATUS = 0
	
	BEGIN 
		------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		If (
			ISNULL(@OSC_CalendarWeekDaysKey, 0) != ISNULL(@NSC_CalendarWeekDaysKey, 0) OR
			ISNULL(@OSC_CalendarEventTypeKey, 0) != ISNULL(@NSC_CalendarEventTypeKey, 0)
			)
		BEGIN
		------------Запись в историю--------------------------------------------------------------------
		if (@sMod = 'DEL')
		begin
			select @sHI_ScheduleText = ISNULL(PR_NAME,'') 
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from Deleted,Partners,Calendars,PartnerCalendarLinkers where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CL_Key and SC_CalendarKey = CL_Key and SC_CalendarKey = @OSC_CalendarKey
			set @SC_Key = @OSC_CalendarKey
		end
		else
		begin
			select @sHI_ScheduleText = ISNULL(PR_NAME,'') 
			+ ' ' + CONVERT(nvarchar(max), isnull(cl_dateFrom, ''), 104) + ' - '
			+ CONVERT(nvarchar(max), isnull(cl_dateTo, ''), 104)
			from Inserted,Partners,Calendars,PartnerCalendarLinkers where PCL_PartnerKey = PR_Key and PCL_CalendarKey = CL_Key and SC_CalendarKey = CL_Key and SC_CalendarKey = @NSC_CalendarKey
			set @SC_Key = @NSC_CalendarKey
		end

	    if (@sMod = 'Del')
		SET @sHI_Text = 'Удаление из расписания ' + @sHI_ScheduleText
		else
		SET @sHI_Text = 'Добавление в расписание ' + @sHI_ScheduleText

		EXEC @nHIID = dbo.InsHistory 
							@sDGCod = '',
							@nDGKey = null,
							@nOAId = 36,
							@nTypeCode = @SC_Key,
							@sMod = @sMod,
							@sText = @sHI_Text,
							@sRemark = '',
							@nInvisible = 0,
							@sDocumentNumber  = '',
							@bMessEnabled = 0,
							@nSVKey = null,
							@nCode = null
							
		--------Детализация--------------------------------------------------
			if ISNULL(@OSC_CalendarWeekDaysKey, 0) != ISNULL(@NSC_CalendarWeekDaysKey, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 36001, @OSC_CalendarWeekDaysName, @NSC_CalendarWeekDaysName, @OSC_CalendarWeekDaysKey, @NSC_CalendarWeekDaysKey, null, null, 0
			end
			if ISNULL(@OSC_CalendarEventTypeKey, 0) != ISNULL(@NSC_CalendarEventTypeKey, 0)
			begin
				EXECUTE dbo.InsertHistoryDetail @nHIID, 36002, @OSC_CalendarEventTypeName, @NSC_CalendarEventTypeName, @OSC_CalendarEventTypeKey, @NSC_CalendarEventTypeKey, null, null, 0
			end
		END
		
		-- запустим пересчет CalendarDates и CalendarDeadLines
		if @NSC_CalendarKey is not null
		begin
			exec CalculateCalendar @NSC_CalendarKey
			exec CalculateCalendarDeadLines @NSC_CalendarKey
		end
		-- при удалении тоже
		if @OSC_CalendarKey is not null
		begin
			exec CalculateCalendar @OSC_CalendarKey
			exec CalculateCalendarDeadLines @OSC_CalendarKey
		end
		
		FETCH NEXT FROM cur_Schedules INTO @OSC_Key,@OSC_CalendarWeekDaysKey,@OSC_CalendarEventTypeKey,@OSC_CalendarKey,@OSC_CalendarWeekDaysName,@OSC_CalendarEventTypeName,
      @NSC_Key,@NSC_CalendarWeekDaysKey,@NSC_CalendarEventTypeKey,@NSC_CalendarKey,@NSC_CalendarWeekDaysName,@NSC_CalendarEventTypeName
		
	END
	
	CLOSE cur_Schedules
	DEALLOCATE cur_Schedules
	
END
GO



/*********************************************************************/
/* end Trigger_Schedule.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckQuotaExist.sql */
/*********************************************************************/
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

/*********************************************************************/
/* end sp_CheckQuotaExist.sql */
/*********************************************************************/

/*********************************************************************/
/* begin I_DogListToQuotas.sql */
/*********************************************************************/
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





/*********************************************************************/
/* end I_DogListToQuotas.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110801(AddTable_TourFilial).sql */
/*********************************************************************/
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[TourFilial]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
begin
	CREATE TABLE [dbo].[TourFilial](
		[TF_ID] [int] IDENTITY(1,1) NOT NULL,
		[TF_PRKEY] [int] NOT NULL,
		[TF_TLKEY] [int] NOT NULL,
	 CONSTRAINT [PK_TourFilial] PRIMARY KEY CLUSTERED 
	(
		[TF_ID] ASC
	) ON [PRIMARY]
	) ON [PRIMARY]
end
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_TourFilial_tbl_Partners]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
begin
	ALTER TABLE [dbo].[TourFilial]  WITH CHECK ADD  CONSTRAINT [FK_TourFilial_tbl_Partners] FOREIGN KEY([TF_PRKEY])
	REFERENCES [dbo].[tbl_Partners] ([PR_KEY])
end
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_TourFilial_tbl_TurList]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
begin
	ALTER TABLE [dbo].[TourFilial]  WITH CHECK ADD  CONSTRAINT [FK_TourFilial_tbl_TurList] FOREIGN KEY([TF_TLKEY])
	REFERENCES [dbo].[tbl_TurList] ([TL_KEY])
end
GO

Grant SELECT,INSERT,UPDATE,DELETE on [dbo].[TourFilial] to public
GO
/*********************************************************************/
/* end 110801(AddTable_TourFilial).sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110808(AddRows_ObjectAliases).sql */
/*********************************************************************/
if (SELECT COUNT(*) FROM [ObjectAliases] WHERE [OA_Id] = 1144) = 0
BEGIN
	INSERT INTO [ObjectAliases]
			   ([OA_Id]
			   ,[OA_Alias]
			   ,[OA_Name]
			   ,[OA_NameLat]
			   ,[OA_TABLEID]
			   ,[OA_CommunicationInfo])
	 VALUES
		  (1144
		   ,'VTS_ResultChangeDate'
		   ,'Дата изменения поля "Отказ"'
		   ,'Date of change in the field "Cancel"'
		   ,62
		   ,null)
END
GO

if (SELECT COUNT(*) FROM [ObjectAliases] WHERE [OA_Id] = 1145) = 0
BEGIN
	INSERT INTO [ObjectAliases]
			   ([OA_Id]
			   ,[OA_Alias]
			   ,[OA_Name]
			   ,[OA_NameLat]
			   ,[OA_TABLEID]
			   ,[OA_CommunicationInfo])
	 VALUES
		  (1145
		   ,'VTS_IsCheckedChangeDate'
		   ,'Дата изменения поля "Проверено"'
		   ,'Date of change in the field "Checked"'
		   ,62
		   ,null)
END
GO
/*********************************************************************/
/* end 110808(AddRows_ObjectAliases).sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_InsDogovor.sql */
/*********************************************************************/
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

-- AleXK обнуляем статус путевки. При создани путевки он должен быть "В работе" т.е 0
set @nStatus = 0

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

	declare @sHI_WHO varchar(25)
	exec dbo.CurrentUser @sHI_WHO output

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
/*********************************************************************/
/* end sp_InsDogovor.sql */
/*********************************************************************/

/*********************************************************************/
/* begin AlterCountryAddCN_PassportMinDurCheckFrom.sql */
/*********************************************************************/
if not exists (select * from dbo.syscolumns where name = 'CN_PassportMinDurCheckFrom' and id = object_id(N'[dbo].[tbl_Country]'))
	ALTER TABLE dbo.tbl_Country add CN_PassportMinDurCheckFrom int not null	default 0
GO

exec sp_RefreshViewForAll 'Country'
go
/*********************************************************************/
/* end AlterCountryAddCN_PassportMinDurCheckFrom.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110812(Delete_VisaTouristGridSettingsRows).sql */
/*********************************************************************/
DELETE FROM UserSettings
WHERE ST_ParmName IN ('GroupVisaForm', 'DogovorMainForm.visaTouristServicesGrid', 'VisaTouristForm.visaTouristServicesGrid')

GO
/*********************************************************************/
/* end 110812(Delete_VisaTouristGridSettingsRows).sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110817(Delete_BonusDetailGrid_Settings).sql */
/*********************************************************************/
delete from UserSettings
where ST_ParmName = 'PrtBonusDetailsForm.prtBonusDetailsGrid'
GO

delete UserSettings
where ST_ParmName = 'PrtBonusesForm.prtBonusesGrid'
GO
/*********************************************************************/
/* end 110817(Delete_BonusDetailGrid_Settings).sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20110815_Alter_DUP_USER_Add_US_EnableViewMTBooking.sql */
/*********************************************************************/
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[DUP_USER]') 
											  and name = 'US_EnableViewMTBooking')
begin
	ALTER TABLE dbo.DUP_USER ADD US_EnableViewMTBooking bit null default(0) 
end
GO
/*********************************************************************/
/* end 20110815_Alter_DUP_USER_Add_US_EnableViewMTBooking.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Create_table_PROVIDERSTATUSES.sql */
/*********************************************************************/

if not exists (select 1 from 
sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProviderStatuses]') AND type in (N'U')
			
			)
begin			
CREATE TABLE [dbo].[ProviderStatuses](
	[PS_KEY] [int] NOT NULL identity(1,1),
	[PS_NAME] [varchar](100) NULL,
	[PS_NAMELAT] [varchar](100) NULL,
 CONSTRAINT [PK_ProviderStatuses] PRIMARY KEY CLUSTERED 
(
	[PS_KEY] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
end
GO


grant select on [dbo].[ProviderStatuses] to public
go
grant insert on [dbo].[ProviderStatuses] to public
go
grant delete on [dbo].[ProviderStatuses] to public
go
grant update on [dbo].[ProviderStatuses] to public
go

if not exists(select PS_NAME from dbo.ProviderStatuses where PS_NAME='NEW')
begin 
insert into ProviderStatuses(PS_NAME,PS_NAMELAT)
values('NEW','NEW')
end
go

if not exists(select PS_NAME from dbo.ProviderStatuses where PS_NAME='OK')
begin 
insert into ProviderStatuses(PS_NAME,PS_NAMELAT)
values('OK','OK')
end
GO

if not exists(select PS_NAME from dbo.ProviderStatuses where PS_NAME='NOTCONFIRM')
begin 
insert into ProviderStatuses(PS_NAME,PS_NAMELAT)
values('NOTCONFIRM','NOTCONFIRM')
end
GO

if not exists(select PS_NAME from dbo.ProviderStatuses where PS_NAME='CHANGE')
begin 
insert into ProviderStatuses(PS_NAME,PS_NAMELAT)
values('CHANGE','CHANGE')
end
GO

if not exists(select PS_NAME from dbo.ProviderStatuses where PS_NAME='CANCEL')
begin 
insert into ProviderStatuses(PS_NAME,PS_NAMELAT)
values('CANCEL','CANCEL')
end
GO
if not exists(select PS_NAME from dbo.ProviderStatuses where PS_NAME='OKCANCEL')
begin 
insert into ProviderStatuses(PS_NAME,PS_NAMELAT)
values('OKCANCEL','OKCANCEL')
end
GO



/*********************************************************************/
/* end Create_table_PROVIDERSTATUSES.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Alter_Table_tbl_DogovorList.sql */
/*********************************************************************/
GO
if not exists (select 1 from dbo.syscolumns 
			   where name = 'DL_ISSENDPARTNER' and id = OBJECT_ID('tbl_DogovorList') )
				 
	begin
		ALTER TABLE dbo.tbl_DogovorList add DL_ISSENDPARTNER  bit 
		ALTER TABLE [dbo].[tbl_DogovorList] ADD  DEFAULT (0) FOR [DL_ISSENDPARTNER]
	end
go

GO
if not exists (select 1 from dbo.syscolumns 
			   where name = 'DL_DOGCODEPARTNER' and id = OBJECT_ID('tbl_DogovorList') )
				 
	begin
		ALTER TABLE dbo.tbl_DogovorList add DL_DOGCODEPARTNER  nvarchar(255) 
		
	end
go


GO
if not exists (select 1 from dbo.syscolumns  
			   where name = 'DL_PROVIDERSTATUSEKEY' and id = OBJECT_ID('tbl_DogovorList'))
begin
		ALTER TABLE dbo.tbl_DogovorList add DL_PROVIDERSTATUSEKEY  int 
		ALTER TABLE [dbo].[tbl_DogovorList] ADD  DEFAULT (1) FOR [DL_PROVIDERSTATUSEKEY]
	    
		
end 
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_tbl_DogovorList_ProviderStatuses]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_DogovorList]'))
begin
	ALTER TABLE [dbo].[tbl_DogovorList]  WITH CHECK ADD  CONSTRAINT [FK_tbl_DogovorList_ProviderStatuses] FOREIGN KEY(DL_PROVIDERSTATUSEKEY)
		REFERENCES [dbo].ProviderStatuses ([PS_KEY])
end		
GO

exec sp_refreshviewforall 'DogovorList'
go





/*********************************************************************/
/* end Alter_Table_tbl_DogovorList.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_ParseKeys.sql */
/*********************************************************************/
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
/*********************************************************************/
/* end fn_ParseKeys.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110830(AlterTable_Dogovor_AddColumn_DG_ProTourFlag).sql */
/*********************************************************************/
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[tbl_Dogovor]') and name = 'DG_ProTourFlag')
	alter table dbo.tbl_Dogovor 
	add [DG_ProTourFlag] [tinyint] NULL
go

exec sp_RefreshViewForAll 'Dogovor'
go
/*********************************************************************/
/* end 110830(AlterTable_Dogovor_AddColumn_DG_ProTourFlag).sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_TranslateToProTourNew.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[TranslateToProTourNew]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[TranslateToProTourNew]
GO

CREATE PROCEDURE [dbo].[TranslateToProTourNew]
AS
-- MEG00037199 30.08.11 fomin
-- Данная хранимка создана на основе TranslateToProTour и отличается от нее фильтрацией 
-- путевок по стране. Страны указаны в настройке ProtorCountryKeys в таблице SystemSettings.

--<VERSION>2007.2.35.10</VERSION>
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
  and DG_TurDate > DATEADD(MONTH,-1,GetDate()) 
  and DG_SOR_Code not in (@StateDouble,@StateNotConsistent,@StateSyncError)
  and (not exists(select * from @CountryKeys) or DG_CNKEY IN (select * from @CountryKeys))
  and NOT EXISTS (SELECT 1 
				  FROM HISTORY with (nolock) 
				  WHERE HI_DGCod=DG_Code 
					AND HI_Date BETWEEN DATEADD(MINUTE,-12,GetDate()) 
					AND GetDate() )

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

UPDATE Dogovor 
SET DG_ProTourFlag=3 
WHERE DG_ProTourFlag = 1 
  and DG_TurDate = '30-DEC-1899' 
  and DG_TurDateBfrAnnul > DATEADD(MONTH,-1,GetDate())
  and (not exists(select * from @CountryKeys) or DG_CNKEY IN (select * from @CountryKeys))

UPDATE Dogovor 
SET DG_ProTourFlag=3 
WHERE DG_ProTourFlag is not null 
  and DG_ProTourFlag not in (3,4)
  and DG_TurDate = '30-DEC-1899'
  and (not exists(select * from @CountryKeys) or DG_CNKEY IN (select * from @CountryKeys))
  and NOT EXISTS (SELECT 1 
				  FROM HISTORY with (nolock) 
				  WHERE HI_DGCod=DG_Code 
					AND HI_Date BETWEEN DATEADD(MINUTE,-12,GetDate()) 
					AND GetDate())

DECLARE @DG_Key int, @DG_Code varchar(20), @HIDateMTP datetime
DECLARE cur_5 CURSOR FOR
	SELECT DG_Key,DG_Code,MAX(HI_Date) 
	FROM History as h1,Dogovor as d1 
	WHERE HI_Date BETWEEN DATEADD(MONTH,-1,GetDate()) 
      and DATEADD(MINUTE,-12,GetDate()) 
      AND HI_Mod='MTP'
	  and DG_Code=HI_DGCod and (DG_ProTourFlag!=1 and DG_ProTourFlag is not null) 
	  and DG_SOR_Code not in (@StateDouble,@StateNotConsistent,@StateSyncError)
	GROUP BY DG_Key,DG_Code

OPEN cur_5

FETCH NEXT FROM cur_5 INTO @DG_Key, @DG_Code, @HIDateMTP

WHILE @@FETCH_STATUS = 0
BEGIN 
	IF NOT EXISTS (SELECT 1 
				   FROM HISTORY with (nolock), HistoryDetail with (nolock) 
				   WHERE HD_HIID=HI_ID 
					 and hd_oaid=399999 
					 AND HI_DGCod=@DG_Code 
					 AND HI_Date > @HIDateMTP)
	BEGIN
		UPDATE Dogovor 
		SET DG_ProTourFlag=1 
		WHERE DG_Key=@DG_Key
		  and (not exists(select * from @CountryKeys) or DG_CNKEY IN (select * from @CountryKeys))
		  and NOT EXISTS (SELECT 1 
						  FROM HISTORY with (nolock) 
						  WHERE HI_DGCod=DG_Code 
							AND HI_Date BETWEEN DATEADD(MINUTE,-11,GetDate()) 
							AND GetDate())
	END
	FETCH NEXT FROM cur_5 INTO @DG_Key, @DG_Code, @HIDateMTP
END

CLOSE cur_5

DEALLOCATE cur_5

GO

GRANT EXEC ON [dbo].[TranslateToProTourNew] TO PUBLIC
GO
/*********************************************************************/
/* end sp_TranslateToProTourNew.sql */
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
/* end T_UpdDogListQuota.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_DogovorListUpdate.sql */
/*********************************************************************/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_DogovorListUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_DogovorListUpdate]
GO


CREATE TRIGGER [dbo].[T_DogovorListUpdate]
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
  DECLARE @ODL_PROVIDERSTATUSEKEY int

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
  DECLARE @NDL_PROVIDERSTATUSEKEY int
  
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
			null, null, null, null, null, null, null,null,
			N.DL_DgCod, N.DL_DGKey, N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_SubCode2, N.DL_CnKey, N.DL_CtKey, N.DL_NMen, N.DL_Day, N.DL_NDays, 
			N.DL_PartnerKey, N.DL_Cost, N.DL_Brutto, N.DL_Discount, N.DL_Wait, N.DL_Control, N.DL_DateBeg, N.DL_DateEnd,
			N.DL_RealNetto, N.DL_Attribute, N.DL_PaketKey, N.DL_Name, N.DL_Payed, N.DL_QuoteKey, N.DL_TimeBeg,N.DL_PROVIDERSTATUSEKEY
			
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_DogovorList CURSOR FOR 
    SELECT 	O.DL_Key,
			O.DL_DgCod, O.DL_DGKey, O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_SubCode2, O.DL_CnKey, O.DL_CtKey, O.DL_NMen, O.DL_Day, O.DL_NDays, 
			O.DL_PartnerKey, O.DL_Cost, O.DL_Brutto, O.DL_Discount, O.DL_Wait, O.DL_Control, O.DL_DateBeg, O.DL_DateEnd,
			O.DL_RealNetto, O.DL_Attribute, O.DL_PaketKey, O.DL_Name, O.DL_Payed, O.DL_QuoteKey, O.DL_TimeBeg, O.DL_PROVIDERSTATUSEKEY,
			null, null, null, null, null, null, null, null, null, null, null,
			null, null, null, null, null, null, null, null, 
			null, null, null, null, null, null, null,null
    FROM DELETED O
  END
  ELSE 
  BEGIN
  	SET @sMod = 'UPD'
    DECLARE cur_DogovorList CURSOR FOR 
    SELECT 	N.DL_Key,
			O.DL_DgCod, O.DL_DGKey, O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_SubCode2, O.DL_CnKey, O.DL_CtKey, O.DL_NMen, O.DL_Day, O.DL_NDays, 
			O.DL_PartnerKey, O.DL_Cost, O.DL_Brutto, O.DL_Discount, O.DL_Wait, O.DL_Control, O.DL_DateBeg, O.DL_DateEnd,
			O.DL_RealNetto, O.DL_Attribute, O.DL_PaketKey, O.DL_Name, O.DL_Payed, O.DL_QuoteKey, O.DL_TimeBeg,O.DL_PROVIDERSTATUSEKEY,
	  		N.DL_DgCod, N.DL_DGKey, N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_SubCode2, N.DL_CnKey, N.DL_CtKey, N.DL_NMen, N.DL_Day, N.DL_NDays, 
			N.DL_PartnerKey, N.DL_Cost, N.DL_Brutto, N.DL_Discount, N.DL_Wait, N.DL_Control, N.DL_DateBeg, N.DL_DateEnd,
			N.DL_RealNetto, N.DL_Attribute, N.DL_PaketKey, N.DL_Name, N.DL_Payed, N.DL_QuoteKey, N.DL_TimeBeg,N.DL_PROVIDERSTATUSEKEY
    FROM DELETED O, INSERTED N 
    WHERE N.DL_Key = O.DL_Key
  END

    OPEN cur_DogovorList
    FETCH NEXT FROM cur_DogovorList INTO 
		@DL_Key, 
			@ODL_DgCod, @ODL_DGKey, @ODL_SvKey, @ODL_Code, @ODL_SubCode1, @ODL_SubCode2, @ODL_CnKey, @ODL_CtKey, @ODL_NMen, @ODL_Day, @ODL_NDays, 
			@ODL_PartnerKey, @ODL_Cost, @ODL_Brutto, @ODL_Discount, @ODL_Wait, @ODL_Control, @ODL_DateBeg, @ODL_DateEnd, 
			@ODL_RealNetto, @ODL_Attribute, @ODL_PaketKey, @ODL_Name, @ODL_Payed, @ODL_QuoteKey, @ODL_TimeBeg,@ODL_PROVIDERSTATUSEKEY,
			@NDL_DgCod, @NDL_DGKey, @NDL_SvKey, @NDL_Code, @NDL_SubCode1, @NDL_SubCode2, @NDL_CnKey, @NDL_CtKey, @NDL_NMen, @NDL_Day, @NDL_NDays, 
			@NDL_PartnerKey, @NDL_Cost, @NDL_Brutto, @NDL_Discount, @NDL_Wait, @NDL_Control, @NDL_DateBeg, @NDL_DateEnd, 
			@NDL_RealNetto, @NDL_Attribute, @NDL_PaketKey, @NDL_Name, @NDL_Payed, @NDL_QuoteKey, @NDL_TimeBeg,@NDL_PROVIDERSTATUSEKEY
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
			ISNULL(@ODL_TimeBeg, 0) != ISNULL(@NDL_TimeBeg, 0) OR
			ISNULL(@ODL_PROVIDERSTATUSEKEY,0)!=ISNULL(@NDL_PROVIDERSTATUSEKEY,0)
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
					ELSE IF (@NDL_SvKey = 6)
						EXECUTE dbo.InsertHistoryDetail @nHIID , 1146, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
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
			--12/09/2011 oksana add Проверка на изменение пакета
			
			If ISNULL(@ODL_PaketKey,0)!=ISNULL(@NDL_PaketKey,0)
			BEGIN
				Select  @sText_Old=ISNULL( TL_NAME, '') from dbo.TurList where TL_KEY = @ODL_PaketKey
				Select  @sText_New=ISNULL( TL_NAME, '') from dbo.TurList where TL_KEY = @NDL_PaketKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 2, @sText_Old, @sText_New, @ODL_PaketKey,@NDL_PaketKey, null, null, 0, @bNeedCommunicationUpdate output
			END
			--Проверка на изменение статуса бронирования
			If ISNULL(@ODL_PROVIDERSTATUSEKEY,0)!=ISNULL(@NDL_PROVIDERSTATUSEKEY,0)
			BEGIN
				Select  @sText_Old=ISNULL( PS_NAME, '') from dbo.ProviderStatuses where PS_KEY = ISNULL(@ODL_PROVIDERSTATUSEKEY,0)
				Select  @sText_New=ISNULL( PS_NAME, '') from dbo.ProviderStatuses where PS_KEY = ISNULL(@NDL_PROVIDERSTATUSEKEY,0)
				EXECUTE dbo.InsertHistoryDetail @nHIID , 2, @sText_Old, @sText_New, @ODL_PROVIDERSTATUSEKEY,@NDL_PROVIDERSTATUSEKEY, null, null, 0, @bNeedCommunicationUpdate output
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
			--12/09/2011 oksana add
			
			If @ODL_PaketKey!=@NDL_PaketKey
			BEGIN			    
				Select  @sText_Old=ISNULL( TL_NAME, '') from dbo.TurList where TL_KEY = @ODL_PaketKey
				Select  @sText_New=ISNULL( TL_NAME, '') from dbo.TurList where TL_KEY = @NDL_PaketKey
				EXECUTE dbo.InsertHistoryDetail @nHIID , 2, @sText_Old, @sText_New, @ODL_PaketKey,@NDL_PaketKey, null, null, 1, @bNeedCommunicationUpdate output
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
			@ODL_RealNetto, @ODL_Attribute, @ODL_PaketKey, @ODL_Name, @ODL_Payed, @ODL_QuoteKey, @ODL_TimeBeg,@ODL_PROVIDERSTATUSEKEY,
			@NDL_DgCod, @NDL_DGKey, @NDL_SvKey, @NDL_Code, @NDL_SubCode1, @NDL_SubCode2, @NDL_CnKey, @NDL_CtKey, @NDL_NMen, @NDL_Day, @NDL_NDays, 
			@NDL_PartnerKey, @NDL_Cost, @NDL_Brutto, @NDL_Discount, @NDL_Wait, @NDL_Control, @NDL_DateBeg, @NDL_DateEnd, 
			@NDL_RealNetto, @NDL_Attribute, @NDL_PaketKey, @NDL_Name, @NDL_Payed, @NDL_QuoteKey, @NDL_TimeBeg,@NDL_PROVIDERSTATUSEKEY
	END
  CLOSE cur_DogovorList
  DEALLOCATE cur_DogovorList
 END
GO
/*********************************************************************/
/* end T_DogovorListUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetDogovorState.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetDogovorState]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetDogovorState]
GO
CREATE PROCEDURE [dbo].[GetDogovorState]
	(
		@dg_key int
	)
AS
BEGIN
	declare @new_dg_sor_code int, @new_dg_sor_code_double_dogovor int

	exec GetDogovorStateId @dg_key, @new_dg_sor_code output, @new_dg_sor_code_double_dogovor output
	
	select OS_CODE, OS_NAME_RUS, OS_NameLat, OS_GLOBAL
	from Order_Status
	where OS_CODE = isnull(@new_dg_sor_code_double_dogovor, -100500)
	union all
	select OS_CODE, OS_NAME_RUS, OS_NameLat, OS_GLOBAL
	from Order_Status
	where OS_CODE = @new_dg_sor_code
	union all
	select OS_CODE, OS_NAME_RUS, OS_NameLat, OS_GLOBAL
	from Order_Status as OS1
	where OS_CODE != @new_dg_sor_code
	and OS_CODE != isnull(@new_dg_sor_code_double_dogovor, -100500)
	and	exists (select top 1 1
				from Order_Status as OS2
				where OS1.OS_GLOBAL = OS2.OS_GLOBAL
				and OS2.OS_CODE = @new_dg_sor_code)
END

GO
grant exec on [dbo].[GetDogovorState] to public
go
/*********************************************************************/
/* end sp_GetDogovorState.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_GetDogovorStateId.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetDogovorStateId]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetDogovorStateId]
GO

CREATE PROCEDURE [dbo].[GetDogovorStateId]
	(
		@dg_key int,
		@ReservationStatusId int output,
		@ReservationStatusIdFromDoubleDogovor int output
	)
AS
BEGIN
	declare @StatusRuleId int
	declare @id int, @typeid int, @onWaitList int, @serviceStatusId int, @excludeServiceId int
	declare @dlCount1 int, @dlCount2 int, @dlCount3 int, @dlWaitCount int
	declare @sUpdateMainDogovorStatuses varchar(254)
	
	-- определим сначала есть ли дублирующая путевка и в случа если стоит настройка то покажим ее статус
	set @ReservationStatusIdFromDoubleDogovor = null
	
	select @ReservationStatusIdFromDoubleDogovor = convert(int, SS_ParmValue) from SystemSettings where SS_ParmName = 'ResStatFromDoubDog' and len(ltrim(RTRIM(SS_ParmValue))) > 0
	
	-- если настройка установлена
	if (@ReservationStatusIdFromDoubleDogovor is not null)
	begin
		-- то проверим есть ли дублирующие путевки 
		declare @doubledogovorKey int
		exec CheckDoubleReservation @dg_key, @doubledogovorKey output
		
		-- если их нету то менять статус не нужно
		if (@doubledogovorKey is null)
		begin 
			set @ReservationStatusIdFromDoubleDogovor = null
		end
	end	

	-- теперь определим статус услуги по правилам
	declare ruleCursor cursor read_only fast_forward for
	select sr_id, sr_typeid, sr_onwaitlist, sr_servicestatusid, sr_excludeserviceid
	from dbo.StatusRules
	order by sr_priority asc

	open ruleCursor
	fetch next from ruleCursor into @id, @typeid, @onWaitList, @serviceStatusId, @excludeServiceId
	while @@fetch_status = 0 and @StatusRuleId is null
	begin
		
		-- Статус путёвки = ХХХХ, если все услуги находится в статусе УУУУ, кроме услуг типа ZZZZ / Reservation status = XXXX if all services have YYYY status, except for services of ZZZZ type
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
		else
		-- Статус путёвки = ХХХХ, если хотя бы одна услуга находится в статусе YYYY, кроме услуг типа ZZZZ / Reservation status = XXXX if at least one service has YYYY status, except for services of ZZZZ type
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
		else
		-- Статус путёвки = ХХХХ, если хотя бы одна услуга не находится в статусе YYYY, кроме услуг типа ZZZZ / Reservation status = XXXX if no at least one service has YYYY status, except for services of ZZZZ type
		if @typeid = 3
		begin
			SELECT @dlCount1 = count(dl_key) FROM dbo.tbl_DogovorList 
				WHERE 
					dl_dgkey = @dg_key 
				AND (dl_control != @serviceStatusId OR @serviceStatusId IS NULL)
				AND ((dbo.DogovorListRequestStatus(DL_Key) = 4 and ISNULL(@onWaitList, 0) = 1) or ISNULL(@onWaitList, 0) = 0)
				AND dl_svkey != ISNULL(@excludeServiceId, 0)

			if @dlCount1 > 0
				set @StatusRuleId = @id
		end

		fetch next from ruleCursor into @id, @typeid, @onWaitList, @serviceStatusId, @excludeServiceId
	end

	close ruleCursor
	deallocate ruleCursor
	
	IF @StatusRuleId IS NOT NULL
	begin
		SELECT @ReservationStatusId = sr_ReservationStatusId FROM dbo.StatusRules WHERE sr_id = @StatusRuleId
	end
	else
	begin
		set @ReservationStatusId = null
	end
END

GO
grant exec on [dbo].[GetDogovorStateId] to public
go
/*********************************************************************/
/* end sp_GetDogovorStateId.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckDoubleReservation.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckDoubleReservation]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CheckDoubleReservation]
GO

create procedure [dbo].[CheckDoubleReservation]
(	
	-- процедура определяет есть ли дублирующая путевка
	-- ключ договора
	@dogovorKey int,
	-- ключ дублирующего договора, если значение null то дублирующего договора не найдено
	@doubledogovorKey int output
)
AS
begin
	declare @tur_duration int, @TourDate datetime
	
	set @doubledogovorKey = null
	
	select @tur_duration = DG_NDAY,
	@TourDate = DG_TURDATE
	from tbl_Dogovor join tbl_turist on DG_CODE = TU_DGCOD
	where DG_Key = @dogovorKey

	select @doubledogovorKey = DG_Key
	from tbl_turist as TU1 join tbl_Dogovor as DG1 on DG1.DG_CODE = TU1.TU_DGCOD
	where DG1.DG_TURDATE between @TourDate and DATEADD(DAY, @tur_duration, @TourDate)
	AND DG1.DG_Key != @dogovorKey
	and exists (select top 1 1
				from tbl_turist as TU2 join tbl_Dogovor as DG2 on DG2.DG_CODE = TU2.TU_DGCOD
				where DG2.DG_Key = @dogovorKey
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
/* begin (11.09.14)Insert_SystemSettings.sql */
/*********************************************************************/
if not exists (select top 1 1 from SystemSettings where SS_ParmName = 'ResStatFromDoubDog')
begin
	insert SystemSettings (SS_ParmValue, SS_ParmName)
	values ('', 'ResStatFromDoubDog')
end
go
/*********************************************************************/
/* end (11.09.14)Insert_SystemSettings.sql */
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
		@dg_key int -- ключ путевки
	)
AS
BEGIN
	declare @dlKey int, @dlControl int

	declare setDogovorListStatusCursor cursor read_only fast_forward for
	select DL_Key, DL_Control
	from tbl_dogovorList join [service] on dl_svkey = sv_key
	where dl_dgkey = @dg_key
	and isnull(SV_QUOTED, 0) = 1
	
	open setDogovorListStatusCursor
	fetch next from setDogovorListStatusCursor into @dlKey, @dlControl
	while @@fetch_status = 0
	begin
		declare @newdlControl int
		
		exec SetServiceStatusOK @dlKey, @newdlControl out
		
		if (@newdlControl != @dlControl)
		begin
			update tbl_dogovorList
			set DL_Control = @newdlControl
			where DL_Key = @dlKey
			and DL_Control != @newdlControl
		end	
		
		fetch next from setDogovorListStatusCursor into @dlKey, @dlControl
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
/* begin (110907)Insert_ObjectAliases.sql */
/*********************************************************************/
-- MEG00037288 06.09.2011 Kolbeshkin: добавление ObjectAlias'ов для поиска битых путевок
DECLARE @tableID int
SET @tableID = 49 -- Таблица путевки

IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 41))
INSERT INTO dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_NameLat, OA_TABLEID) 
VALUES (41, 'ReservationWithoutServices', 'Без услуг', 'Without services', @tableID)

IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 42))
INSERT INTO dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_NameLat, OA_TABLEID) 
VALUES (42, 'ReservationWithoutTourists', 'Без туристов', 'Without tourists', @tableID)

IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 43))
INSERT INTO dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_NameLat, OA_TABLEID) 
VALUES (43, 'ServicesWithoutTourists', 'Услуги с непривязанными туристами', 'Services without tourists', @tableID)

IF (NOT EXISTS(SELECT 1 FROM [dbo].[ObjectAliases] WHERE OA_ID = 1146))
INSERT INTO dbo.ObjectAliases (OA_Id, OA_Alias, OA_Name, OA_TABLEID, OA_CommunicationInfo) 
VALUES (1146, 'DL_Code', 'Название страховки', 60, 1)

GO

-- Добавление фильтра битых путевок
declare @dsKey int 
set @dsKey = (select MAX(DS_Key) from dbo.Descriptions) + 1
if not exists (select 1 from dbo.Descriptions where DS_Value like 'Некорректные путевки')
begin
	declare @dtKey int
	select @dtKey = DT_Key from dbo.DescTypes where DT_Name like 'Фильтр в плагине "Мониторинг путевок"'
	insert into dbo.Descriptions (DS_Key, DS_Value, DS_DTKey) values (@dsKey, 'Некорректные путевки', @dtKey)
end

if not exists (select 1 from dbo.ObjectAliasFilters where OF_OAId = 41)
insert into dbo.ObjectAliasFilters (OF_DSKey, OF_OAId) values (@dsKey, 41)

if not exists (select 1 from dbo.ObjectAliasFilters where OF_OAId = 42)
insert into dbo.ObjectAliasFilters (OF_DSKey, OF_OAId) values (@dsKey, 42)

if not exists (select 1 from dbo.ObjectAliasFilters where OF_OAId = 43)
insert into dbo.ObjectAliasFilters (OF_DSKey, OF_OAId) values (@dsKey, 43)

GO
/*********************************************************************/
/* end (110907)Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin AlterInsPolicyAdd_XMLValue.sql */
/*********************************************************************/
if not exists (select 1 from dbo.syscolumns where name = 'IP_XMLValue' and id = object_id(N'[dbo].[InsPolicy]'))
	begin
		ALTER TABLE dbo.InsPolicy add IP_XMLValue ntext null
	end
go
/*********************************************************************/
/* end AlterInsPolicyAdd_XMLValue.sql */
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
		[pt_key] [int] IDENTITY PRIMARY KEY,
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
/* begin (11.08.02)CreateTable_FlightBalance.sql */
/*********************************************************************/
/****** Object:  Table [dbo].[FlightBalance]    Script Date: 04/29/2011 11:38:28 ******/

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FlightBalance]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
begin

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[FlightBalance](
	[FB_Key] [bigint] NOT NULL,
	[FB_CHKey] [int] NULL,
	[FB_PRKey] [int] NULL,
	[FB_Date] [datetime] NULL,
	[FB_DateCreate] [datetime] NULL,
	--[FB_Tariff] [int] NULL,
	-- MEG00035735 Kolbeshkin закомментил FB_Tariff, FB_SeatRate, FB_SeatPrice, FB_GroupID за ненадобностью
	[FB_Seats] [int] NULL,
	--[FB_SeatRate] [int] NULL,
	--[FB_SeatPrice] [money] NULL,
	[FB_FlightRate] [int] NULL,
	[FB_FlightPrice] [money] NULL,
	--[FB_GroupID] [int] NULL,
 CONSTRAINT [PK_FlightBalance] PRIMARY KEY CLUSTERED 
(
	[FB_Key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]


ALTER TABLE [dbo].[FlightBalance] ADD  CONSTRAINT [DF__FlightBal__FB_Da__5C793A7D]  DEFAULT (getdate()) FOR [FB_DateCreate]
end
GO


grant select, update, delete, insert on [dbo].[FlightBalance] to public
go

if not exists(select * from DotNetWindows where WN_WindowName='FlightBalanceForm')
insert into DotNetWindows (WN_WindowName,WN_NameRus,WN_NameLat,WN_ExWindowName)
values ('FlightBalanceForm','Баланс рейсов','FlightBalance','')
go
/*********************************************************************/
/* end (11.08.02)CreateTable_FlightBalance.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.08.10)Insert_Order_Status.sql */
/*********************************************************************/
if not exists (select top 1 1 from Order_Status where OS_CODE = 0)
begin
	insert into Order_Status (OS_CODE, OS_NAME_RUS, OS_GLOBAL, OS_NameLat)
	values (0, 'В работе', 0, 'In work')
end
go
/*********************************************************************/
/* end (11.08.10)Insert_Order_Status.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.08.24)Alter_table_TP_TurDates.sql */
/*********************************************************************/
if not exists (select * from dbo.syscolumns where name = 'TD_CalculatingKey' and id = object_id(N'[dbo].[TP_TurDates]'))
begin
	alter table [dbo].[TP_TurDates] add TD_CalculatingKey int null
end
go
/*********************************************************************/
/* end (11.08.24)Alter_table_TP_TurDates.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.08.24)Update_Status_Rules.sql */
/*********************************************************************/
if exists (select top 1 1 from SystemSettings where SS_ParmName in ('IL_SERVICE_CANCEL', 'IL_DOGOVOR_CANCEL', 'IL_DOGOVOR_WAIT', 'IL_DOGOVOR_CONFIRM'))
begin
	DECLARE @SERVICE_CANCEL int, @DOGOVOR_CANCEL int, @DOGOVOR_WAIT int, @DOGOVOR_CONFIRM int
	
	SELECT @SERVICE_CANCEL=CR_Key FROM SystemSettings,Controls WHERE SS_ParmValue=CR_Key and SS_ParmName='IL_SERVICE_CANCEL'
	SELECT @DOGOVOR_CANCEL=OS_Code FROM SystemSettings,Order_Status WHERE SS_ParmValue=OS_Code and SS_ParmName='IL_DOGOVOR_CANCEL'
	SELECT @DOGOVOR_WAIT=OS_Code FROM SystemSettings,Order_Status WHERE SS_ParmValue=OS_Code and SS_ParmName='IL_DOGOVOR_WAIT'
	SELECT @DOGOVOR_CONFIRM=OS_Code FROM SystemSettings,Order_Status WHERE SS_ParmValue=OS_Code and SS_ParmName='IL_DOGOVOR_CONFIRM'
	
	-- если не все параметры указаны то выходим
	if @SERVICE_CANCEL is null or @DOGOVOR_CANCEL is null or @DOGOVOR_WAIT is null or @DOGOVOR_CONFIRM is null
	begin
		return;
	end
	
	-- "OK", все услуги "OK" --> путевка "OK"
	if not exists (select top 1 1 from StatusRules where SR_TypeId = 2 and SR_OnWaitList = 0 and SR_ReservationStatusId = @DOGOVOR_CONFIRM and SR_ServiceStatusId = 0 and SR_ExcludeServiceId is null)
	begin
		-- понизим приоретет старых правил
		update StatusRules
		set SR_Priority = SR_Priority + 1
		where SR_Priority != 777
	
		insert into StatusRules (SR_TypeId, SR_OnWaitList, SR_ReservationStatusId, SR_ServiceStatusId, SR_ExcludeServiceId, SR_Priority)
		values (2, 0, @DOGOVOR_CONFIRM, 0, null, 1)
	end
	
	--"Ждет подтверждения", если хоть у одной услуги статус "не OK"
	-- заменим на если хоть одна из услуг в статусе отличном от OK, то @DOGOVOR_WAIT
	if not exists (select top 1 1 from StatusRules where SR_TypeId = 3 and SR_OnWaitList = 0 and SR_ReservationStatusId = @DOGOVOR_WAIT and SR_ServiceStatusId = 0 and SR_ExcludeServiceId is null)
	begin
		-- понизим приоретет старых правил
		update StatusRules
		set SR_Priority = SR_Priority + 1
		where SR_Priority != 777
		
		insert into StatusRules (SR_TypeId, SR_OnWaitList, SR_ReservationStatusId, SR_ServiceStatusId, SR_ExcludeServiceId, SR_Priority)
		values (3, 0, @DOGOVOR_WAIT, 0, null, 1)
	end
	
	-- если хоть у одной услуги ключ статуса @SERVICE_CANCEL, значит надо поставить статус @DOGOVOR_CANCEL по путевке
	if not exists (select top 1 1 from StatusRules where SR_TypeId = 1 and SR_OnWaitList = 0 and SR_ReservationStatusId = @DOGOVOR_CANCEL and SR_ServiceStatusId = @SERVICE_CANCEL and SR_ExcludeServiceId is null)
	begin
		-- понизим приоретет старых  правил
		update StatusRules
		set SR_Priority = SR_Priority + 1
		where SR_Priority != 777
	
		insert into StatusRules (SR_TypeId, SR_OnWaitList, SR_ReservationStatusId, SR_ServiceStatusId, SR_ExcludeServiceId, SR_Priority)
		values (1, 0, @DOGOVOR_CANCEL, @SERVICE_CANCEL, null, 1)
	end
end
go
/*********************************************************************/
/* end (11.08.24)Update_Status_Rules.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.08.31)Data_StatusRuleTypes.sql */
/*********************************************************************/
if (not exists (select top 1 1 from StatusRuleTypes where SRT_Id = 3))
begin
	insert into StatusRuleTypes(SRT_Id, SRT_Name, SRT_NameLat, SRT_Description)
	values (3, 'Одна услуга -> Путёвка', 'Single Service -> Reservation', 'Статус путёвки = ХХХХ, если хотя бы одна услуга не находится в статусе YYYY, кроме услуг типа ZZZZ / Reservation status = XXXX if no at least one service has YYYY status, except for services of ZZZZ type')
end
go
/*********************************************************************/
/* end (11.08.31)Data_StatusRuleTypes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CreatePPaymentdate.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CreatePPaymentdate]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[CreatePPaymentdate]
GO

CREATE PROCEDURE [dbo].[CreatePPaymentdate]
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

if exists (select top 1 1 from Dogovor join Order_Status on DG_SOR_CODE = OS_CODE where DG_CODE = @sDogovor and (DG_TURDATE = '18991230' or OS_GLOBAL != 0))
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

grant exec on [dbo].[CreatePPaymentdate] to public
go
/*********************************************************************/
/* end sp_CreatePPaymentdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_QuotaDetailsAfterDelete.sql */
/*********************************************************************/
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


/*********************************************************************/
/* end sp_QuotaDetailsAfterDelete.sql */
/*********************************************************************/

/*********************************************************************/
/* begin X_DOGOVORLIST_MANAGER.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_DogovorList]') AND name = N'X_DOGOVORLIST_MANAGER')
	DROP INDEX [X_DOGOVORLIST_MANAGER] ON [dbo].[tbl_DogovorList] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [X_DOGOVORLIST_MANAGER] ON [dbo].[tbl_DogovorList] 
(
	[dl_turdate] ASC
)
include
(
	[DL_CTKEY],
	[DL_SubCode2],
	[dl_svKey]
) ON [PRIMARY]
GO
/*********************************************************************/
/* end X_DOGOVORLIST_MANAGER.sql */
/*********************************************************************/

/*********************************************************************/
/* begin Version92.sql */
/*********************************************************************/
-- для версии 2009.2
update [dbo].[setting] set st_version = '9.2.10', st_moduledate = convert(datetime, '2011-11-09', 120),  st_financeversion = '9.2.10', st_financedate = convert(datetime, '2011-11-09', 120) where st_version like '9.%'
GO
UPDATE dbo.SystemSettings SET SS_ParmValue='2011-11-09' WHERE SS_ParmName='SYSScriptDate'
GO
/*********************************************************************/
/* end Version92.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_PartnerUpdate.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_PartnerUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_PartnerUpdate]
GO

CREATE TRIGGER [T_PartnerUpdate]
ON [dbo].[tbl_Partners] 
FOR UPDATE, INSERT, DELETE
AS
---<VERSION>9.2.10</VERSION>
--<DATE>2011-10-31</DATE>
IF @@ROWCOUNT > 0
BEGIN
    DECLARE 
		@PR_Key int,
		@OPR_FullName varchar(160), @OPR_Name varchar(50), @OPR_NameEng varchar(80), @OPR_BossName varchar(40), @OPR_Boss varchar(50), @OPR_Adress varchar(160), 
		@OPR_Phones varchar(254), @OPR_Fax varchar(20), @OPR_Email varchar(50), @OPR_CTKey int, @OPR_Cod varchar(6), @OPR_Filial int, 
		@OPR_Owner int, @OPR_Deleted smallint, @OPR_LicenseNumber varchar(50), @OPR_AdditionalInfo varchar(50), @OPR_LegalAddress varchar(160), @OPR_INN varchar(30), 
		@OPR_KPP varchar(30), @OPR_CodeOKONH varchar(30), @OPR_CodeOKPO varchar(30), @OPR_HomePage varchar(100), @OPR_LegalPostIndex varchar(6), @OPR_PostIndex varchar(6), 
		@OPR_RegisterNumber varchar(50), @OPR_RegisterSeries varchar(10),

		@NPR_FullName varchar(160), @NPR_Name varchar(50), @NPR_NameEng varchar(80), @NPR_BossName varchar(40), @NPR_Boss varchar(50), @NPR_Adress varchar(160), 
		@NPR_Phones varchar(254), @NPR_Fax varchar(20), @NPR_Email varchar(50), @NPR_CTKey int, @NPR_Cod varchar(6), @NPR_Filial int, 
		@NPR_Owner int, @NPR_Deleted smallint, @NPR_LicenseNumber varchar(50), @NPR_AdditionalInfo varchar(50), @NPR_LegalAddress varchar(160), @NPR_INN varchar(30), 
		@NPR_KPP varchar(30), @NPR_CodeOKONH varchar(30), @NPR_CodeOKPO varchar(30), @NPR_HomePage varchar(100), @NPR_LegalPostIndex varchar(6), @NPR_PostIndex varchar(6), 
		@NPR_RegisterNumber varchar(50), @NPR_RegisterSeries varchar(10),
    
		@sMod varchar(3), @nDelCount int, @nInsCount int, @nHIID int, @sHI_Text varchar(254), @sText_Old varchar(254), @sText_New varchar(254)

  SELECT @nDelCount = COUNT(*) FROM DELETED
  SELECT @nInsCount = COUNT(*) FROM INSERTED
  IF (@nDelCount = 0)
  BEGIN
	SET @sMod = 'INS'
    DECLARE cur_Partner CURSOR FOR 
		SELECT N.PR_Key, 
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null,
			N.PR_FullName, N.PR_Name, N.PR_NameEng, N.PR_BossName, N.PR_Boss, N.PR_Adress, 
			N.PR_Phones, N.PR_Fax, N.PR_Email, N.PR_CTKey, N.PR_Cod, N.PR_Filial, 
			N.PR_Owner, N.PR_Deleted, N.PR_LicenseNumber, N.PR_AdditionalInfo, N.PR_LegalAddress, N.PR_INN, 
			N.PR_KPP, N.PR_CodeOKONH, N.PR_CodeOKPO, N.PR_HomePage, N.PR_LegalPostIndex, N.PR_PostIndex, 
			N.PR_RegisterNumber, N.PR_RegisterSeries
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_Partner CURSOR FOR 
		SELECT O.PR_Key, 
			O.PR_FullName, O.PR_Name, O.PR_NameEng, O.PR_BossName, O.PR_Boss, O.PR_Adress, 
			O.PR_Phones, O.PR_Fax, O.PR_Email, O.PR_CTKey, O.PR_Cod, O.PR_Filial, 
			O.PR_Owner, O.PR_Deleted, O.PR_LicenseNumber, O.PR_AdditionalInfo, O.PR_LegalAddress, O.PR_INN, 
			O.PR_KPP, O.PR_CodeOKONH, O.PR_CodeOKPO, O.PR_HomePage, O.PR_LegalPostIndex, O.PR_PostIndex, 
			O.PR_RegisterNumber, O.PR_RegisterSeries, 
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null, null, null, null, null,
			null, null
      FROM DELETED O 
  END
  ELSE 
  BEGIN
	SET @sMod = 'UPD'
    DECLARE cur_Partner CURSOR FOR 
		SELECT N.PR_Key, 
			O.PR_FullName, O.PR_Name, O.PR_NameEng, O.PR_BossName, O.PR_Boss, O.PR_Adress, 
			O.PR_Phones, O.PR_Fax, O.PR_Email, O.PR_CTKey, O.PR_Cod, O.PR_Filial, 
			O.PR_Owner, O.PR_Deleted, O.PR_LicenseNumber, O.PR_AdditionalInfo, O.PR_LegalAddress, O.PR_INN, 
			O.PR_KPP, O.PR_CodeOKONH, O.PR_CodeOKPO, O.PR_HomePage, O.PR_LegalPostIndex, O.PR_PostIndex, 
			O.PR_RegisterNumber, O.PR_RegisterSeries, 
		  	N.PR_FullName, N.PR_Name, N.PR_NameEng, N.PR_BossName, N.PR_Boss, N.PR_Adress, 
			N.PR_Phones, N.PR_Fax, N.PR_Email, N.PR_CTKey, N.PR_Cod, N.PR_Filial, 
			N.PR_Owner, N.PR_Deleted, N.PR_LicenseNumber, N.PR_AdditionalInfo, N.PR_LegalAddress, N.PR_INN, 
			N.PR_KPP, N.PR_CodeOKONH, N.PR_CodeOKPO, N.PR_HomePage, N.PR_LegalPostIndex, N.PR_PostIndex, 
			N.PR_RegisterNumber, N.PR_RegisterSeries
      FROM DELETED O, INSERTED N 
      WHERE N.PR_Key = O.PR_Key
  END

  OPEN cur_Partner
    FETCH NEXT FROM cur_Partner INTO
		@PR_Key,
		@OPR_FullName, @OPR_Name, @OPR_NameEng, @OPR_BossName, @OPR_Boss, @OPR_Adress, 
		@OPR_Phones, @OPR_Fax, @OPR_Email, @OPR_CTKey, @OPR_Cod, @OPR_Filial, 
		@OPR_Owner, @OPR_Deleted, @OPR_LicenseNumber, @OPR_AdditionalInfo, @OPR_LegalAddress, @OPR_INN, 
		@OPR_KPP, @OPR_CodeOKONH, @OPR_CodeOKPO, @OPR_HomePage, @OPR_LegalPostIndex, @OPR_PostIndex, 
		@OPR_RegisterNumber, @OPR_RegisterSeries,
		@NPR_FullName, @NPR_Name, @NPR_NameEng, @NPR_BossName, @NPR_Boss, @NPR_Adress, 
		@NPR_Phones, @NPR_Fax, @NPR_Email, @NPR_CTKey, @NPR_Cod, @NPR_Filial, 
		@NPR_Owner, @NPR_Deleted, @NPR_LicenseNumber, @NPR_AdditionalInfo, @NPR_LegalAddress, @NPR_INN, 
		@NPR_KPP, @NPR_CodeOKONH, @NPR_CodeOKPO, @NPR_HomePage, @NPR_LegalPostIndex, @NPR_PostIndex, 
		@NPR_RegisterNumber, @NPR_RegisterSeries

    WHILE @@FETCH_STATUS = 0
    BEGIN 
	 -- Если поменялось название партнера, то апдейтим и US_COMPANYNAME для представителей этого партнера
		IF @sMod = 'UPD' AND ISNULL(@OPR_Name, '') != ISNULL(@NPR_Name, '')
		UPDATE DBO.DUP_USER SET US_COMPANYNAME = ISNULL(@NPR_Name, '') WHERE US_PRKEY = @PR_Key
	  ------------Проверка, надо ли что-то писать в историю-------------------------------------------   
		IF	(
			ISNULL(@OPR_FullName, '')	!= ISNULL(@NPR_FullName, '') OR
			ISNULL(@OPR_Name, '')		!= ISNULL(@NPR_Name, '') OR
			ISNULL(@OPR_NameEng, '')	!= ISNULL(@NPR_NameEng, '') OR
			ISNULL(@OPR_BossName, '')	!= ISNULL(@NPR_BossName, '') OR
			ISNULL(@OPR_Boss, '')		!= ISNULL(@NPR_Boss, '') OR
			ISNULL(@OPR_Adress, '')		!= ISNULL(@NPR_Adress, '') OR
			ISNULL(@OPR_Phones, '')		!= ISNULL(@NPR_Phones, '') OR
			ISNULL(@OPR_Fax, '')		!= ISNULL(@NPR_Fax, '') OR
			ISNULL(@OPR_Email, '')		!= ISNULL(@NPR_Email, '') OR
			ISNULL(@OPR_CTKey, 0)		!= ISNULL(@NPR_CTKey, 0) OR
			ISNULL(@OPR_Cod, '')			!= ISNULL(@NPR_Cod, '') OR
			ISNULL(@OPR_Filial, 0)		!= ISNULL(@NPR_Filial, 0) OR
			ISNULL(@OPR_Owner, 0)		!= ISNULL(@NPR_Owner, 0) OR
			ISNULL(@OPR_Deleted, 0)		!= ISNULL(@NPR_Deleted, 0) OR
			ISNULL(@OPR_LicenseNumber, '')  != ISNULL(@NPR_LicenseNumber, '') OR
			ISNULL(@OPR_AdditionalInfo, '') != ISNULL(@NPR_AdditionalInfo, '') OR
			ISNULL(@OPR_LegalAddress, '')   != ISNULL(@NPR_LegalAddress, '')  OR
			ISNULL(@OPR_INN, '')			!= ISNULL(@NPR_INN, '')  OR
			ISNULL(@OPR_KPP, '')			!= ISNULL(@NPR_KPP, '')  OR
			ISNULL(@OPR_CodeOKONH, '')	!= ISNULL(@NPR_CodeOKONH, '')  OR
			ISNULL(@OPR_CodeOKPO, '')	!= ISNULL(@NPR_CodeOKPO, '')  OR
			ISNULL(@OPR_HomePage, '')	!= ISNULL(@NPR_HomePage, '')  OR
			ISNULL(@OPR_LegalPostIndex, '') != ISNULL(@NPR_LegalPostIndex, '')  OR
			ISNULL(@OPR_PostIndex, '')	!= ISNULL(@NPR_PostIndex, '')  OR
			ISNULL(@OPR_RegisterNumber, '') != ISNULL(@NPR_RegisterNumber, '')  OR
			ISNULL(@OPR_RegisterSeries, '') != ISNULL(@NPR_RegisterSeries, '') 
		)
	  BEGIN
	  	------------Запись в историю--------------------------------------------------------------------
		
		if (@sMod = 'INS') or (@sMod = 'UPD')
			SET @sHI_Text = ISNULL(@NPR_Name, '')
		else if (@sMod = 'DEL')
			SET @sHI_Text = ISNULL(@OPR_Name, '')
		EXEC @nHIID = dbo.InsHistory '', null, 10, @PR_Key, @sMod, @sHI_Text, '', 0, ''

		--------Детализация--------------------------------------------------
		if (ISNULL(@OPR_FullName, '')	!= ISNULL(@NPR_FullName, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10001, @OPR_FullName, @NPR_FullName, null, null, null, null, 0
		if (ISNULL(@OPR_Name, '')		!= ISNULL(@NPR_Name, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10002, @OPR_Name, @NPR_Name, null, null, null, null, 0
		if (ISNULL(@OPR_NameEng, '')	!= ISNULL(@NPR_NameEng, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10003, @OPR_NameEng, @NPR_NameEng, null, null, null, null, 0
		if (ISNULL(@OPR_BossName, '')	!= ISNULL(@NPR_BossName, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10004, @OPR_BossName, @NPR_BossName, null, null, null, null, 0
		if (ISNULL(@OPR_Boss, '')		!= ISNULL(@NPR_Boss, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10005, @OPR_Boss, @NPR_Boss, null, null, null, null, 0
		if (ISNULL(@OPR_Adress, '')		!= ISNULL(@NPR_Adress, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10006, @OPR_Adress, @NPR_Adress, null, null, null, null, 0
		if (ISNULL(@OPR_Phones, '')		!= ISNULL(@NPR_Phones, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10007, @OPR_Phones, @NPR_Phones, null, null, null, null, 0
		if (ISNULL(@OPR_Fax, '')		!= ISNULL(@NPR_Fax, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10008, @OPR_Fax, @NPR_Fax, null, null, null, null, 0
		if (ISNULL(@OPR_Email, '')		!= ISNULL(@NPR_Email, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10009, @OPR_Email, @NPR_Email, null, null, null, null, 0
		if (ISNULL(@OPR_CTKey, 0)		!= ISNULL(@NPR_CTKey, 0))
		BEGIN
			Set @sText_Old = null
			Set @sText_New = null
			SELECT @sText_Old=CT_Name FROM dbo.CityDictionary WHERE CT_Key=@OPR_CTKey
			SELECT @sText_New=CT_Name FROM dbo.CityDictionary WHERE CT_Key=@NPR_CTKey
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10010, @sText_Old, @sText_New, @OPR_CTKey, @NPR_CTKey, null, null, 0
		END
		if (ISNULL(@OPR_Cod, '')			!= ISNULL(@NPR_Cod, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10011, @OPR_Cod, @NPR_Cod, null, null, null, null, 0
		if (ISNULL(@OPR_Filial, 0)		!= ISNULL(@NPR_Filial, 0))
		BEGIN
			Set @sText_Old = null
			Set @sText_New = null
			SELECT @sText_Old=CASE WHEN @OPR_Filial=1 THEN 'Фирма-владелец' WHEN @OPR_Filial=2 THEN 'Филиал' ELSE '' END
			SELECT @sText_New=CASE WHEN @NPR_Filial=1 THEN 'Фирма-владелец' WHEN @NPR_Filial=2 THEN 'Филиал' ELSE '' END
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10012, @sText_Old, @sText_New, @OPR_Filial, @NPR_Filial, null, null, 0
		END
		if (ISNULL(@OPR_Owner, 0)		!= ISNULL(@NPR_Owner, 0))
		BEGIN
			Set @sText_Old = null
			Set @sText_New = null
			SELECT @sText_Old=US_FullName FROM dbo.UserList WHERE US_Key=@OPR_Owner
			SELECT @sText_New=US_FullName FROM dbo.UserList WHERE US_Key=@NPR_Owner
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10013, @sText_Old, @sText_New, @OPR_Owner, @NPR_Owner, null, null, 0
		END
		if (ISNULL(@OPR_Deleted, 0)		!= ISNULL(@NPR_Deleted, 0))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10014, @OPR_Deleted, @NPR_Deleted, @OPR_Deleted, @NPR_Deleted, null, null, 0
		if (ISNULL(@OPR_LicenseNumber, '')  != ISNULL(@NPR_LicenseNumber, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10015, @OPR_LicenseNumber, @NPR_LicenseNumber, null, null, null, null, 0
		if (ISNULL(@OPR_AdditionalInfo, '') != ISNULL(@NPR_AdditionalInfo, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10016, @OPR_AdditionalInfo, @NPR_AdditionalInfo, null, null, null, null, 0
		if (ISNULL(@OPR_LegalAddress, '')   != ISNULL(@NPR_LegalAddress, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10017, @OPR_LegalAddress, @NPR_LegalAddress, null, null, null, null, 0
		if (ISNULL(@OPR_INN, '')			!= ISNULL(@NPR_INN, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10018, @OPR_INN, @NPR_INN, null, null, null, null, 0
		if (ISNULL(@OPR_KPP, '')			!= ISNULL(@NPR_KPP, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10019, @OPR_KPP, @NPR_KPP, null, null, null, null, 0
		if (ISNULL(@OPR_CodeOKONH, '')	!= ISNULL(@NPR_CodeOKONH, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10020, @OPR_CodeOKONH, @NPR_CodeOKONH, null, null, null, null, 0
		if (ISNULL(@OPR_CodeOKPO, '')	!= ISNULL(@NPR_CodeOKPO, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10021, @OPR_CodeOKPO, @NPR_CodeOKPO, null, null, null, null, 0
		if (ISNULL(@OPR_HomePage, '')	!= ISNULL(@NPR_HomePage, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10022, @OPR_HomePage, @NPR_HomePage, null, null, null, null, 0
		if (ISNULL(@OPR_LegalPostIndex, '') != ISNULL(@NPR_LegalPostIndex, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10023, @OPR_LegalPostIndex, @NPR_LegalPostIndex, null, null, null, null, 0
		if (ISNULL(@OPR_PostIndex, '')	!= ISNULL(@NPR_PostIndex, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10024, @OPR_PostIndex, @NPR_PostIndex, null, null, null, null, 0
		if (ISNULL(@OPR_RegisterNumber, '') != ISNULL(@NPR_RegisterNumber, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10025, @OPR_RegisterNumber, @NPR_RegisterNumber, null, null, null, null, 0
		if (ISNULL(@OPR_RegisterSeries, '') != ISNULL(@NPR_RegisterSeries, ''))
			EXECUTE dbo.InsertHistoryDetail @nHIID , 10026, @OPR_RegisterSeries, @NPR_RegisterSeries, null, null, null, null, 0
	  END
    FETCH NEXT FROM cur_Partner INTO
		@PR_Key,
		@OPR_FullName, @OPR_Name, @OPR_NameEng, @OPR_BossName, @OPR_Boss, @OPR_Adress, 
		@OPR_Phones, @OPR_Fax, @OPR_Email, @OPR_CTKey, @OPR_Cod, @OPR_Filial, 
		@OPR_Owner, @OPR_Deleted, @OPR_LicenseNumber, @OPR_AdditionalInfo, @OPR_LegalAddress, @OPR_INN, 
		@OPR_KPP, @OPR_CodeOKONH, @OPR_CodeOKPO, @OPR_HomePage, @OPR_LegalPostIndex, @OPR_PostIndex, 
		@OPR_RegisterNumber, @OPR_RegisterSeries,
		@NPR_FullName, @NPR_Name, @NPR_NameEng, @NPR_BossName, @NPR_Boss, @NPR_Adress, 
		@NPR_Phones, @NPR_Fax, @NPR_Email, @NPR_CTKey, @NPR_Cod, @NPR_Filial, 
		@NPR_Owner, @NPR_Deleted, @NPR_LicenseNumber, @NPR_AdditionalInfo, @NPR_LegalAddress, @NPR_INN, 
		@NPR_KPP, @NPR_CodeOKONH, @NPR_CodeOKPO, @NPR_HomePage, @NPR_LegalPostIndex, @NPR_PostIndex, 
		@NPR_RegisterNumber, @NPR_RegisterSeries
    END
  CLOSE cur_Partner
  DEALLOCATE cur_Partner
END
GO
/*********************************************************************/
/* end T_PartnerUpdate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.09.23)_Create_Table_QuotedStateHistory.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_QuotedStateHistory_QSH_Date]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[QuotedStateHistory] DROP CONSTRAINT [DF_QuotedStateHistory_QSH_Date]
END
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotedStateHistory]') AND type in (N'U'))
DROP TABLE [dbo].[QuotedStateHistory]
GO
CREATE TABLE [dbo].[QuotedStateHistory](
	[QSH_Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QSH_DlKey] [int] NOT NULL,
	[QSH_Date] [datetime] NOT NULL,
	[QSH_StateOld] [int] NULL,
	[QSH_StateNew] [int] NULL,
	[QSH_QPIdOld] [int] NULL,
	[QSH_QPIdNew] [int] NULL,
	[QSH_TUKeyOld] [int] NULL,
	[QSH_TUKeyNew] [int] NULL,
 CONSTRAINT [PK_QuotedStateHistory] PRIMARY KEY CLUSTERED 
(
	[QSH_Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[QuotedStateHistory] ADD  CONSTRAINT [DF_QuotedStateHistory_QSH_Date]  DEFAULT (getdate()) FOR [QSH_Date]
GO
grant select, insert, update, delete on [dbo].[QuotedStateHistory] to public
go
/*********************************************************************/
/* end (11.09.23)_Create_Table_QuotedStateHistory.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.10.17)alter table TP_ServiceLists add TL_CalculatingKey.sql */
/*********************************************************************/
if not exists (select top 1 1 from syscolumns where name = 'TL_CalculatingKey' and id = OBJECT_ID(N'TP_ServiceLists'))
begin
 alter table TP_ServiceLists add TL_CalculatingKey int null
end

go

/*********************************************************************/
/* end (11.10.17)alter table TP_ServiceLists add TL_CalculatingKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.10.17)alter table tp_services add TS_CalculatingKey.sql */
/*********************************************************************/
if not exists(select top 1 1 from syscolumns where name = N'TS_CalculatingKey' and id = OBJECT_ID(N'tp_services'))
begin
	alter table tp_services add TS_CalculatingKey int null
end

go

/*********************************************************************/
/* end (11.10.17)alter table tp_services add TS_CalculatingKey.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (11.10.27)AlterTableService.sql */
/*********************************************************************/
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Service]') and name = 'SV_LittlePercent')
begin
	alter table dbo.[Service] 
	add [SV_LittlePercent] [decimal](18,2) NULL
end
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Service]') and name = 'SV_LittlePlace')
begin
	alter table dbo.[Service] 
	add [SV_LittlePlace] [smallint] NULL
end
if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Service]') and name = 'SV_LittleAnd')
begin
	alter table dbo.[Service] 
	add [SV_LittleAnd] [bit] NULL
end
go
/*********************************************************************/
/* end (11.10.27)AlterTableService.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 110715(addcolumn_TU_InsuredEvent).sql */
/*********************************************************************/

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[tbl_Turist]') and name = 'TU_InsuredEvent')
BEGIN
	ALTER TABLE dbo.tbl_Turist ADD
		TU_InsuredEvent bit NOT NULL CONSTRAINT DF_tbl_Turist_TU_InsuredEvent DEFAULT 0
END
GO

exec sp_RefreshViewForAll 'Turist'
go
/*********************************************************************/
/* end 110715(addcolumn_TU_InsuredEvent).sql */
/*********************************************************************/

/*********************************************************************/
/* begin 13102011_X_DogovorMonitor.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Dogovor]') AND name = N'x_dogovormonitor')
	DROP INDEX [x_dogovormonitor] ON [dbo].[tbl_Dogovor] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [x_dogovormonitor] ON [dbo].[tbl_Dogovor] 
(
      [DG_CNKEY] ASC,
      [DG_CTKEY] ASC,
      [DG_CTDepartureKey] ASC,
      [DG_CREATOR] ASC,
      [DG_OWNER] ASC,
      [DG_FilialKey] ASC,
      [DG_BTKEY] ASC
)
INCLUDE ( [DG_CODE],
[DG_TURDATE],
[DG_PRICE],
[DG_PAYED],
[DG_DISCOUNTSUM],
[DG_PDTType],
[DG_TRKEY],
[DG_PARTNERKEY],
[DG_ARKey]) WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[HistoryDetail]') AND name = N'x_alias')
	DROP INDEX [x_alias] ON [dbo].[HistoryDetail] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [x_alias] ON [dbo].[HistoryDetail] 
(
      [HD_Alias] ASC
)
INCLUDE ( [HD_HIID]) WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[History]') AND name = N'x_date')
	DROP INDEX [x_date] ON [dbo].[History] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [x_date] ON [dbo].[History] 
(
      [HI_DATE] ASC
)
INCLUDE ( [HI_MOD],
[HI_DGCOD]) WITH (FILLFACTOR = 70) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[History]') AND name = N'x_dgcode')
	DROP INDEX [x_dgcode] ON [dbo].[History] WITH ( ONLINE = OFF )
GO

CREATE NONCLUSTERED INDEX [x_dgcode] ON [dbo].[History] 
(
      [HI_DGCOD] ASC,
      [HI_MOD] ASC
)
INCLUDE ( [HI_TEXT],
[HI_OAId],
[HI_DATE]) WITH (FILLFACTOR = 70) ON [PRIMARY]
GO
/*********************************************************************/
/* end 13102011_X_DogovorMonitor.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_DogovorMonitor.sql */
/*********************************************************************/
-- MEG00037288 06.09.2011 Kolbeshkin: 1) добавил фильтр по DG_BTKey 2) селект полей NameLat, если язык = En
-- 3) поиск битых путевок (без услуг/без туристов/услуги без туристов)
/****** Object:  StoredProcedure [dbo].[DogovorMonitor]    Script Date: 09/05/2011 17:17:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DogovorMonitor]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DogovorMonitor]
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
/* begin sp_GetHotelStopSale.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetHotelStopSale]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetHotelStopSale]
GO

CREATE procedure [dbo].[GetHotelStopSale]
(
	-- скрипт запускается из MasterWebStandard.Extra.StopSale, возвращает список отелей на которые устанвлены стопсайлы
	--date 2011-10-27
	--version 2009.2.10
	@hotelKey int,
	@dateBegin datetime
)
as
begin
	declare @ssKeys table (ssk_id int)
	
	insert into @ssKeys (ssk_id)
	select SS_Id
	from StopSales
	where 
	SS_Date >= @dateBegin
	and isnull(SS_IsDeleted, 0) = 0
	and	(exists (	select top 1 1
					from QuotaObjects
					where QO_ID = SS_QOID
					and QO_SVKey = 3
					and QO_Code = @hotelKey)
	or exists (select top 1 1
				from QuotaDetails
				where QD_ID = SS_QDID
				and exists (select top 1 1
							from QuotaObjects							
							where QO_QTID = QD_QTID
							and QO_SVKey = 3
							and QO_Code = @hotelKey))
							)
	
	select SS_ID,
	QO_ID,
	QO_Code,
	QO_SubCode1,
	QO_SubCode2,
	SS_Date,
	CT_NAME,
	HD_NAME,
	RM_NAME,
	RC_NAME
	from StopSales as SS1 join QuotaObjects QO1 on SS1.SS_QOID = QO1.QO_ID or exists(select top 1 1
																						from QuotaDetails
																						where SS1.SS_QDID = QD_ID
																						and QD_QTID = QO1.QO_QTID)
	join HotelDictionary on HD_KEY = QO_Code
	join CityDictionary on CT_KEY = HD_CTKEY
	left join Rooms on RM_KEY = QO_SubCode1
	left join RoomsCategory on RC_KEY = QO_SubCode2
	where SS_ID in (select ssk_id from @ssKeys)
	and QO_SVKey = 3
	order by QO_Code, QO_SubCode1, QO_SubCode2, SS_Date
end

GO


grant exec on [dbo].[GetHotelStopSale] to public
go
/*********************************************************************/
/* end sp_GetHotelStopSale.sql */
/*********************************************************************/
