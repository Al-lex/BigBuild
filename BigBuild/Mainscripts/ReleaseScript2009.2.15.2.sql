/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%% Дата формирования: 26.11.2012 17:39 %%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*********************************************************************/
/* begin CREATE_AssociationHotelCat.sql */
/*********************************************************************/
if not exists ( select * from sysobjects where id = object_id(N'[dbo].[AssociationHotelCat]') and objectproperty(id, N'IsUserTable') = 1 ) 
CREATE TABLE [dbo].[AssociationHotelCat](
	[AH_HdKey] [int] NULL,
	[AH_RcKey] [int] NULL,
	[ah_pnkey] [int] NULL
) ON [PRIMARY]

GO

grant select, update, insert, delete on dbo.AssociationHotelCat to public
go
/*********************************************************************/
/* end CREATE_AssociationHotelCat.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.07.24)_DROP_COLUMNS_History.sql */
/*********************************************************************/

-- удаляем Прочитано ли сообщение
if exists (select 1 from dbo.syscolumns where name = 'HI_IsRead' and id = object_id(N'[dbo].[History]'))
begin
	alter table dbo.History drop column HI_IsRead 
end
go
/*********************************************************************/
/* end (2012.07.24)_DROP_COLUMNS_History.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.07.24)_Insert_SystemSettings.sql */
/*********************************************************************/
if not exists (select * from SystemSettings where SS_ParmName='SYSMEssagesRules')
begin
  insert into SystemSettings(SS_ParmName,SS_ParmValue,SS_Name,SS_NameLat)
  values ('SYSMEssagesRules','/MTM/','Виды сообщений, которые могут иметь статус прочитано/непрочитано','')
end 
go


/*********************************************************************/
/* end (2012.07.24)_Insert_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CheckDoubleDogovor.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='CheckDoubleDogovor')
	drop proc dbo.CheckDoubleDogovor
go

create procedure [dbo].[CheckDoubleDogovor]  
	--<VERSION>2009.2.15<VERSION/>
	--<DATA>2012-07-27<DATA/>
	@TourDate varchar (10),
	@TourDuration int,
	@LastName varchar (25),
	@FirstName varchar (25),
	@Sex int,	
	@HotelKey int,
	@HotelStartDate varchar (10) = null,
	@HotelEndDate varchar (10) = null,
	@Birthday varchar (10) = null,
	@PassportType varchar(5) = null,
	@PassportNum varchar(13) = null
AS
begin
    --CRM01804K4X8 27.07.2012 kolbeshkin: переделал хранимку проверки дублирования туристов
	SET @LastName = REPLACE (@LastName,'''','')
	SET @FirstName = REPLACE (@FirstName,'''','')
	-- проверяем только: 
	-- 1.Взрослых
	-- 2.Если есть отель, т.к. остальные услуги могут быть по 2 и более и разнесены по разным путевкам
	IF @Sex NOT IN (0,1) OR @HotelKey < 0 OR @HotelStartDate IS NULL OR @HotelEndDate IS NULL
		RETURN
	-- Сравнение:
	-- 1.Фамилия
	-- 2.Имя
	-- 3.Пересекаются ли даты тура
	-- 4.Пол
	-- 5.Существует ли проживание и пересекаются ли его даты
	DECLARE @sql nvarchar(max)
	SET @sql = 'SELECT TU_DGCOD, TU_KEY 
			From [dbo].[tbl_turist] 
			where RTRIM(LTRIM((UPPER(TU_NAMERUS)))) = RTRIM(LTRIM((UPPER(''' + @LastName + ''')))) 
			AND RTRIM(LTRIM((UPPER(TU_FNAMERUS)))) = RTRIM(LTRIM((UPPER(''' + @FirstName + ''')))) 
			AND EXISTS (SELECT DG_KEY 
						FROM dogovor 
						where DG_CODE = TU_DGCOD
						and (''' + @TourDate + ''' between DG_TURDATE and DATEADD(DAY, DG_NDAY - 1, DG_TURDATE)
								or DG_TURDATE between ''' + @TourDate + ''' and DATEADD(DAY, ' + CAST(@TourDuration AS varchar(2)) + ' - 1, ''' + @TourDate + '''))) 
			AND ISNULL(TU_SEX,0) in (0,1) AND ISNULL(TU_SEX,0) = ' + CAST(@Sex AS varchar(2)) + '
			AND EXISTS (SELECT 1 FROM DogovorList,TuristService WHERE DL_SVKey=3 and TU_DLKey=DL_Key and DL_DGCOD=TU_DGCOD and TU_TUKey=TU_Key
						AND (''' + @HotelStartDate + ''' between DL_DATEBEG and DATEADD(DAY,-1,DL_DATEEND) 
							OR DL_DATEBEG between ''' + @HotelStartDate + ''' and DATEADD(DAY,-1,''' + @HotelEndDate + ''')) )'
	-- 6.Дата рождения (если задана у бронирующего)						
	IF @Birthday IS NOT NULL
		SET @sql = @sql + '
		 AND (TU_BIRTHDAY IS NULL OR TU_BIRTHDAY = ''' + @Birthday + ''')'
	-- 7.Серия паспорта (если задана у бронирующего)			
	IF @PassportType IS NOT NULL
		SET @sql = @sql + '
		 AND (TU_PASPORTTYPE IS NULL OR TU_PASPORTTYPE = ''' + @PassportType + ''')'
	-- 8.Серия паспорта (если задана у бронирующего)	
	IF @PassportNum IS NOT NULL
		SET @sql = @sql + '
		 AND (TU_PASPORTNUM IS NULL OR TU_PASPORTNUM = ''' + @PassportNum + ''')'
		
 --print @sql
 EXECUTE sp_executesql @sql
end
go

grant exec on [dbo].[CheckDoubleDogovor] to public
go


/*********************************************************************/
/* end sp_CheckDoubleDogovor.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120807)_Insert_ObjectAliases.sql */
/*********************************************************************/
-- CRM02551Z1K8 07.08.2012 kolbeshkin: добавление алиасов для изменения фамилии/имени туриста из онлайна
if not exists (select 1 from objectaliases where oa_id=1148)
insert into objectaliases (OA_ID,OA_Alias,OA_Name)
values (1148,'TU_NameLat_FNameLat_OnlineChange','Изменение фамилии/имени туриста из онлайна')
go
/*********************************************************************/
/* end (20120807)_Insert_ObjectAliases.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120822)_Insert_SystemSettings.sql */
/*********************************************************************/
if not exists (select 1 from SystemSettings where SS_ParmName='SYSAllowInfantBooking')
insert into SystemSettings(SS_ParmName,SS_ParmValue)
values ('SYSAllowInfantBooking','0')
go
/*********************************************************************/
/* end (20120822)_Insert_SystemSettings.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120823)_AlterConstraints_ClientBonuses.sql */
/*********************************************************************/
if exists (select top 1 1 from sys.foreign_keys where object_id = OBJECT_ID(N'[dbo].[FX_CBA_CLKey]') and parent_object_id = OBJECT_ID(N'[dbo].[ClientBonusAccounts]'))
ALTER TABLE dbo.ClientBonusAccounts
	DROP CONSTRAINT FX_CBA_CLKey
GO

ALTER TABLE dbo.ClientBonusAccounts with nocheck ADD CONSTRAINT FX_CBA_CLKey FOREIGN KEY (CBA_CLKey) 
REFERENCES dbo.Clients (CL_KEY) ON DELETE  CASCADE 
GO		 

if exists (select top 1 1 from sys.foreign_keys where object_id = OBJECT_ID(N'[dbo].[FX_CBT_CBAKey]') and parent_object_id = OBJECT_ID(N'[dbo].[ClientBonusTransactions]'))
ALTER TABLE dbo.ClientBonusTransactions
	DROP CONSTRAINT FX_CBT_CBAKey
GO

ALTER TABLE dbo.ClientBonusTransactions with nocheck ADD CONSTRAINT FX_CBT_CBAKey FOREIGN KEY (CBT_CBAKey) 
REFERENCES dbo.ClientBonusAccounts (CBA_KEY) ON DELETE  CASCADE 
GO
/*********************************************************************/
/* end (20120823)_AlterConstraints_ClientBonuses.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120827)_Grant_CostOffers.sql */
/*********************************************************************/
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.CostOffers TO PUBLIC
GO
/*********************************************************************/
/* end (20120827)_Grant_CostOffers.sql */
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
/* begin (2012.07.06)_Alter_Data_Season.sql */
/*********************************************************************/
if (not exists (select top 1 1 from dbo.Seasons where SN_IsActive = 1 and SN_IsMain = 1))
begin
	update dbo.Seasons
	set SN_IsMain = 1, SN_IsActive = 1
	where SN_Id in (select top 1 SN_Id
					from dbo.Seasons
					order by SN_IsMain desc, SN_IsActive desc, SN_CreateDate desc)
end
go
/*********************************************************************/
/* end (2012.07.06)_Alter_Data_Season.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (201200808)_Add_SystemSettings_SYSUseSellPeriod.sql */
/*********************************************************************/
-- Добавление настройки для учета периода продаж
--<DATE>2012-08-08</DATE>
--<VERSION>2009.2.15.1</VERSION>
if not exists (select 1 from SystemSettings where SS_ParmName='SYSUseSellPeriod')
	begin
	insert into SystemSettings (SS_ParmName,SS_ParmValue)
	values ('SYSUseSellPeriod','0')
	end
else
	begin
	update SystemSettings set SS_ParmValue='0' 
	where SS_ParmName='SYSUseSellPeriod' and SS_ParmValue=''
	end
go
/*********************************************************************/
/* end (201200808)_Add_SystemSettings_SYSUseSellPeriod.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120420)_Add_SystemSettings_AnnulatePolicyCodes.sql */
/*********************************************************************/
-- Добавление настроек для аннуляции полисов при изменении услуг страховки - code, subcode1, subcode2
--<DATE>2012-04-20</DATE>
--<VERSION>2007.2.40.1</VERSION>
if not exists (select 1 from SystemSettings where SS_ParmName='SYSAnnulatePolicyCode')
	insert into SystemSettings (SS_ParmName,SS_ParmValue)
	values ('SYSAnnulatePolicyCode','0')
go
if not exists (select 1 from SystemSettings where SS_ParmName='SYSAnnulatePolicySubcode1')
	insert into SystemSettings (SS_ParmName,SS_ParmValue)
	values ('SYSAnnulatePolicySubcode1','0')
go	
if not exists (select 1 from SystemSettings where SS_ParmName='SYSAnnulatePolicySubcode2')
	insert into SystemSettings (SS_ParmName,SS_ParmValue)
	values ('SYSAnnulatePolicySubcode2','0')
go
/*********************************************************************/
/* end (20120420)_Add_SystemSettings_AnnulatePolicyCodes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120811)_Add_Constraint_FK_tbl_Partners_CityDictionary.sql */
/*********************************************************************/
-- Добавление FK связывающего партнеров и города
--<DATE>2012-08-11</DATE>
--<VERSION>2009.2.15.1</VERSION>
if not exists (select top 1 1 from sys.foreign_keys where object_id = OBJECT_ID(N'[dbo].[FK_tbl_Partners_CityDictionary]') and parent_object_id = OBJECT_ID(N'[dbo].[tbl_Partners]'))
begin
	alter table [dbo].[tbl_partners] with nocheck add constraint [FK_tbl_Partners_CityDictionary] foreign key([PR_CTKey])
	references [dbo].[CityDictionary] ([CT_KEY])
end
go
/*********************************************************************/
/* end (20120811)_Add_Constraint_FK_tbl_Partners_CityDictionary.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120821)_Grant_Update_UserList.US_LastLogDate.sql */
/*********************************************************************/
-- Добавление прав на обновление колонки US_LastLogDate таблицы UserList - для записи даты последнего входа
--<DATE>2012-08-21</DATE>
--<VERSION>2009.2.15.1</VERSION>
GRANT UPDATE ON OBJECT::[dbo].[UserList] (US_LastLogDate) TO [avEconomist]
GRANT UPDATE ON OBJECT::[dbo].[UserList] (US_LastLogDate) TO [avSalesManagers]
GRANT UPDATE ON OBJECT::[dbo].[UserList] (US_LastLogDate) TO [avProductManagers]
GRANT UPDATE ON OBJECT::[dbo].[UserList] (US_LastLogDate) TO [avCasher]
GRANT UPDATE ON OBJECT::[dbo].[UserList] (US_LastLogDate) TO [avAdvertiseManagers]
GRANT UPDATE ON OBJECT::[dbo].[UserList] (US_LastLogDate) TO [guests]

go
/*********************************************************************/
/* end (20120821)_Grant_Update_UserList.US_LastLogDate.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120828)_AlterTable_mwReplQueue.sql */
/*********************************************************************/
if not exists (select id from syscolumns where id = OBJECT_ID('mwReplQueue') and name = 'rq_CalculatingKey')
	alter table dbo.mwReplQueue add rq_CalculatingKey int
go

if not exists (select id from syscolumns where id = OBJECT_ID('mwReplQueue') and name = 'rq_OverwritePrices')
	alter table dbo.mwReplQueue add rq_OverwritePrices bit
go
/*********************************************************************/
/* end (20120828)_AlterTable_mwReplQueue.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (20120917)_Update_Descriptions.sql */
/*********************************************************************/
if exists(select 1 from Descriptions where DS_PKKey = 0 and DS_TableId = 43 and DS_DTKey = 128)
begin
	update Descriptions set DS_Value =N'<RegForm><RegFormItem ID="CompanyName" Text="Название агентства (торговая марка):" Required="true" Visible="true" Error="Название агенства должно быть указано." Length="50" /><RegFormItem ID="ChainName" Text="Название сети (если агентство входит в сеть):" Required="false" Visible="false" Error="" Length="50" /><RegFormItem ID="JuridicalName" Text="Полное юридическое название агентства (вместе с юр. статусом: ООО, ЗАО и т.п.):" Required="true" Visible="true" Error="Полное название агенства должно быть указано." Length="160" /><RegFormItem ID="PartnerGroup" Text="Группа партнеров" Required="false" Visible="false" Error="" Length="160" /><RegFormItem ID="CommissionGroup" Text="Группа комиссий"  Required="false" Visible="false" Error="" Length="160" /><RegFormItem ID="ActBased" Text="Договор"  Required="false" Visible="false" Error="" Length="160" /><RegFormItem ID="RepresentativeManagerName" Text="ФИО представителя компании:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="Login" Text="Логин для доступа к системе онлайн (присваевается самостоятельно):" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="Password" Text="Пароль для доступа к системе онлайн (присваевается самостоятельно):" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="ManagerName" Text="ФИО руководителя:" Required="true" Visible="true" Error="" Length="100" /><RegFormItem ID="ManagerPosition" Text="Должность руководителя:" Required="false" Visible="true" Error="" Length="50" /><RegFormItem ID="JuridicalAddress" Text="Юридический адрес:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="Country" Text="Страна:" Required="true" Visible="true" Error="" Length="20" /><RegFormItem ID="City" Text="Город:" Required="true" Visible="true" Error="Город и индекс должны быть указаны." Length="30" /><RegFormItem ID="Address" Text="Адрес местонахождения:" Required="true" Visible="true" Error="" Length="250" /><RegFormItem ID="Phone" Text="Телефон:" Required="true" Visible="true" Error="Телефон и код города должны быть указаны." Length="50" /><RegFormItem ID="Fax" Text="Факс:" Required="false" Visible="true" Error="" Length="20" /><RegFormItem ID="EMail" Text="E-mail:" Required="true" Visible="true" Error="Должен быть указан корректный e-mail." Length="50" /><RegFormItem ID="INN" Text="ИНН:" Required="true" Visible="true" Error="Должен быть указан корректный ИНН." Length="15" /><RegFormItem ID="KPP" Text="КПП:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="UnitarySystem" Text="Система налогообложения:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="SettlementAccount" Text="р/с:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="CorrespondentAccount" Text="к/с:" Required="true" Visible="true" Error="" Length="50" /><RegFormItem ID="BankName" Text="Наименование Банка:" Required="true" Visible="true" Error="" Length="80" /><RegFormItem ID="BIK" Text="БИК:" Required="true" Visible="true" Error="" Length="20" /><RegFormItem ID="OGRN" Text="ОГРН:" Required="true" Visible="false" Error="" Length="50" /><RegFormItem ID="OKATO" Text="ОКАТО:" Required="false" Visible="false" Error="" Length="50" /><RegFormItem ID="OKPO" Text="ОКПО:" Required="false" Visible="false" Error="" Length="20" /><RegFormItem ID="Comment" Text="Комментарий" Required="false" Visible="false" Error="" Length="100" /></RegForm>'  where DS_PKKey = 0 and DS_TableId = 43 and DS_DTKey = 128
end

go

/*********************************************************************/
/* end (20120917)_Update_Descriptions.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20120704_AlterTablesMWPriceDataTables.sql */
/*********************************************************************/
declare @tableName varchar(256), @sql varchar(max), @viewName varchar(256)

declare priceTablesCursor cursor for
SELECT OBJECT_NAME(OBJECT_ID) as name
FROM sys.dm_db_partition_stats st
WHERE index_id < 2 and OBJECT_NAME(OBJECT_ID) like 'mwPriceDataTable%'
ORDER BY st.row_count asc

open priceTablesCursor
fetch priceTablesCursor into @tableName
while @@FETCH_STATUS = 0
begin
	set @sql = '
	if not exists (select * from syscolumns where name=''pt_directFlightAttribute'' and id=object_id(''dbo.' + @tableName + '''))
	begin
		alter table dbo.' + @tableName + ' add pt_directFlightAttribute [int]
	end
	'
	exec (@sql)

	set @sql = '
	if not exists (select * from syscolumns where name=''pt_backFlightAttribute'' and id=object_id(''dbo.' + @tableName + '''))
	begin
		alter table dbo.' + @tableName + ' add pt_backFlightAttribute int
	end
	'
	exec (@sql)

	set @sql = 'grant update on dbo.' + @tableName + ' to public'
	exec(@sql)

	set @viewName = replace(@tableName, 'mwPriceDataTable', 'mwPriceTable')

	set @sql = 'grant update on dbo.' + @viewName + ' to public'
	exec(@sql)

	exec sp_refreshviewforall @viewName

	fetch priceTablesCursor into @tableName
end
close priceTablesCursor
deallocate priceTablesCursor

GO
/*********************************************************************/
/* end 20120704_AlterTablesMWPriceDataTables.sql */
/*********************************************************************/

/*********************************************************************/
/* begin CREATE_XML_SCHEMA_ArrayOfLong.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.xml_schema_collections c, sys.schemas s WHERE c.schema_id = s.schema_id AND (quotename(s.name) + '.' + quotename(c.name)) = N'[dbo].[ArrayOfLong]')
begin
	CREATE XML SCHEMA COLLECTION [dbo].[ArrayOfLong] AS 
	N'<?xml version="1.0" encoding="utf-16"?>
	<xs:schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" attributeFormDefault="unqualified" elementFormDefault="qualified">
	  <xsd:element name="ArrayOfLong">
		<xsd:complexType>
		  <xsd:sequence>
			<xsd:element maxOccurs="unbounded" name="long" type="xsd:unsignedLong" />
		  </xsd:sequence>
		</xsd:complexType>
	  </xsd:element>
	</xs:schema>'
end
GO

grant exec on xml schema collection::[dbo].[ArrayOfLong] to public
GO
/*********************************************************************/
/* end CREATE_XML_SCHEMA_ArrayOfLong.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetQuotaDurationByQuotaPart.sql */
/*********************************************************************/
IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[GetQuotaDurationByQuotaPart]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[GetQuotaDurationByQuotaPart]
GO

--<VERSION>9.2.15.1</VERSION>
--<DATA>2012-11-16</DATA>
CREATE FUNCTION [dbo].[GetQuotaDurationByQuotaPart]
(
	@quotaPartId int
)
RETURNS varchar(20)
AS
BEGIN
	DECLARE @duration varchar(20)

	DECLARE @tempDuration varchar(20)
	SET @tempDuration = (SELECT QP_Durations FROM QuotaParts WHERE QP_ID = @quotaPartId)
	
	IF @tempDuration IS NULL OR @tempDuration = ''
		SET @duration = '0'
	ELSE
		SET @duration = @tempDuration
	
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

--<VERSION>9.2.15.1</VERSION>
--<DATA>2012-11-16</DATA>
CREATE FUNCTION [dbo].[GetQuotaIsByCheckin]
(
	@quotaId int
)
RETURNS bit
AS
BEGIN
	RETURN 0
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
	--<VERSION>ALL</VERSION>
	--<DATE>2012-08-02</DATE>

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
						if((@qtRelease is null or datediff(day, @currentDate, @qtDate) > isnull(@qtRelease, 0))
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
						and TF_CTKey=TS_CTKey and TF_SubCode1=TS_SubCode1 and TF_SubCode2=TS_SubCode2 and TF_Days = TI_Days)	
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
						exec ReCalculate_CreateServiceCalculateParametrs @nSvkey, @nCode, @nSubcode1, @nSubcode2, @nPrkey, @nDay, @turdate, @nMen, @nDays, @nPacketkey, @tiDays, @scId output, @scpId output
											
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
		@Q_SubCode1 int, @Q_SubCode2 int, @Q_QTID_Prev int, @DaysCount int

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

--Проверим на наличие квот
	if not exists (select 1 from #Tbl where TMP_Count > 0)
	begin
		Set @Quota_CheckState = 0
		return
	end
		
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
--Проверим на релиз период
	if not exists(select 1 from #Tbl where TMP_Count > 0 and TMP_Date = @DateBeg and dateadd(day, -1, GETDATE()) < (@DateBeg - ISNULL(TMP_Release, 0)))
	begin
		--declare @release smallint 
		--select @release = TMP_Release from #Tbl where TMP_Count > 0 and TMP_Date = @DateBeg and TMP_Release > 0
		--if (GETDATE() >= @DateBeg - @release)
		--begin
			set @Quota_CheckState = 3	-- наступил РЕЛИЗ-Период
			return 
		--end
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
	update dbo.TP_Tours set TO_Update = 1, TO_Progress = 0 where TO_Key = @tokey

	if(@calcKey is null)
		exec dbo.mwEnablePriceTour @tokey, 0, @calcKey
		
	update dbo.TP_Tours set TO_Progress = 10 where TO_Key = @tokey

	if(@calcKey is not null)
	begin
		while (1 = 1)
		begin
			delete top (100000) from dbo.mwPriceDataTable where pt_pricekey in (select tp_key from tp_prices with(nolock) where tp_calculatingkey = @calcKey)
			if (@@ROWCOUNT = 0)
				break
		end
	end
	else
	begin
		while (1 = 1)
		begin
			delete top(100000) from dbo.mwPriceDataTable where pt_tourkey = @tokey
			if (@@ROWCOUNT = 0)
				break
		end
	end

	update dbo.TP_Tours set TO_Progress = 25 where TO_Key = @tokey

	if(@calcKey is null)		
	begin
		while(1 = 1)
		begin
			delete top(100000) from dbo.mwSpoDataTable where sd_tourkey = @tokey
			if (@@ROWCOUNT = 0)
				break
		end
	end

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
/* begin sp_CollapsePartner.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_CollapsePartner]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[sp_CollapsePartner]
GO
-- Переносит данные с партнера, ключ которого передается в первый параметр
-- на партнера, ключ которого передается во второй параметр.
-- Удаляет партнера, ключ которого передается в первый параметр.
-- Обновляет партнера в поисковых таблицах на сервере, переданном в третьем параметре. 
-- Если параметр не указан - обновляет поисковые таблицы на всех серверах-подписчиках.
CREATE PROCEDURE [dbo].[sp_CollapsePartner]
(

--<VERSION>2007.2.40.1</VERSION>
--<DATE>17.05.2012</DATE>

--Ключ партнера, которого удаляем
	@fromPartnerKey int,
	
--Ключ партнера, на которого переносим записи
	@toPartnerKey int,
	
--Имена поисковых серверов через запятую
	@searchServerNames nvarchar(100) = null
	
) AS

BEGIN
	DECLARE @transactionName varchar(20)
	SET @transactionName = 'MyTransaction'
		
	BEGIN TRY
	
		BEGIN TRANSACTION @transactionName
		-- Переносим данные с первого партнера на второго
		-- Переносим квоты 
		print 'QuotaPriorities'
			update QuotaPriorities set QPR_PRKey = @toPartnerKey where QPR_PRKey = @fromPartnerKey	
			--update QuotaPriorities set QT_AGENT = @toPartnerKey where QT_AGENT = @fromPartnerKey
			
		print 'QuotaParts'
			update QuotaParts set QP_AgentKey = @toPartnerKey where QP_AgentKey = @fromPartnerKey	
			
		print 'Quotas'
			update Quotas set QT_PRKey = @toPartnerKey where QT_PRKey = @fromPartnerKey	
			
		-- Переносим discounts
		print 'Discounts'
			update Discounts set DS_PRKEY = @toPartnerKey where DS_PRKEY = @fromPartnerKey	
			
		-- Переносим dup_users
		print 'DUP_USER'
			update DUP_USER set US_PRKEY = @toPartnerKey where US_PRKEY = @fromPartnerKey	
			
		-- Переносим dogovors
		print '[tbl_Dogovorlist]'
			ALTER TABLE [dbo].[tbl_Dogovorlist] DISABLE TRIGGER [T_UpdDogListQuota] -- MEG00038742 07.12.2011 Kolbeshkin Отключим триггер на договорлисте, иначе поменяется статус услуг
			ALTER TABLE [dbo].[tbl_Dogovorlist] DISABLE TRIGGER [T_DogovorListUpdate]
			update tbl_dogovor set DG_PARTNERKEY = @toPartnerKey where DG_PARTNERKEY = @fromPartnerKey	
			update tbl_dogovor set DG_FilialKey = @toPartnerKey where DG_FilialKey = @fromPartnerKey
			ALTER TABLE [dbo].[tbl_Dogovorlist] ENABLE TRIGGER [T_UpdDogListQuota]	
			ALTER TABLE [dbo].[tbl_Dogovorlist] ENABLE TRIGGER [T_DogovorListUpdate]
			
		-- Переносим partner dogovors
		print 'PrtDogs'
			update PrtDogs set PD_PRKey = @toPartnerKey where PD_PRKey = @fromPartnerKey	
			update PrtDogs set PD_Abonent = @toPartnerKey where PD_Abonent = @fromPartnerKey
			
		-- Переносим partner warnings
		print 'PrtWarns'
			update PrtWarns set PW_PRKey = @toPartnerKey where PW_PRKey = @fromPartnerKey		
			
		-- Переносим price tours 
		print 'TP_Tours'
			update TP_Tours set TO_PRKey = @toPartnerKey where TO_PRKey = @fromPartnerKey	
			
		-- Переносим calls 
		print 'Calls'
			update Calls set CS_PrKey = @toPartnerKey where CS_PrKey = @fromPartnerKey	
			
		-- Переносим bills
		print 'Bills'
			update Bills set BL_PRKEY = @toPartnerKey where BL_PRKEY = @fromPartnerKey	
			
		-- Переносим costs
		print 'tbl_Costs'
			update tbl_Costs set CS_PRKEY = @toPartnerKey where CS_PRKEY = @fromPartnerKey	
			
		-- Переносим mappings
		print 'Mappings'
			update Mappings set MP_PRKey = @toPartnerKey where MP_PRKey = @fromPartnerKey	
			
		-- Переносим partner departments
		print 'PrtDeps'
			update PrtDeps set PDP_PRKey = @toPartnerKey where PDP_PRKey = @fromPartnerKey	
			
		-- Переносим profiles
		print 'Profiles'
			update Profiles set PF_PRKey = @toPartnerKey where PF_PRKey = @fromPartnerKey	
			
		-- Переносим report templates
		print 'reporttemplates'
			update reporttemplates set RT_PRKEY = @toPartnerKey where RT_PRKEY = @fromPartnerKey	
			
		-- Переносим service links
		print 'ServiceLink'
			update ServiceLink set LS_PRKEY = @toPartnerKey where LS_PRKEY = @fromPartnerKey	
			update ServiceLink set LS_PRKE2 = @toPartnerKey where LS_PRKE2 = @fromPartnerKey	
			
		-- Переносим tour service lists
		print 'TourServiceList'
			update TourServiceList set TO_PrKey = @toPartnerKey where TO_PrKey = @fromPartnerKey
			
		-- Переносим userlist
		print 'UserList'
			update UserList set US_PRKEY = @toPartnerKey where US_PRKEY = @fromPartnerKey
			
		-- Переносим visitors
		print 'Visitors'
			update Visitors set VS_PrKey = @toPartnerKey where VS_PrKey = @fromPartnerKey
			
		-- Переносим dogovorlists
		print '[tbl_Dogovorlist]'
			ALTER TABLE [dbo].[tbl_Dogovorlist] DISABLE TRIGGER [T_UpdDogListQuota] -- MEG00038742 07.12.2011 Kolbeshkin Отключим триггер на договорлисте, иначе поменяется статус услуг
			ALTER TABLE [dbo].[tbl_Dogovorlist] DISABLE TRIGGER [T_DogovorListUpdate]
			update tbl_DogovorList set DL_PARTNERKEY = @toPartnerKey where DL_PARTNERKEY = @fromPartnerKey
			ALTER TABLE [dbo].[tbl_Dogovorlist] ENABLE TRIGGER [T_UpdDogListQuota]
			ALTER TABLE [dbo].[tbl_Dogovorlist] ENABLE TRIGGER [T_DogovorListUpdate]
			
		-- Переносим tur service
		print 'TurService'
			update TurService set TS_PARTNERKEY = @toPartnerKey where TS_PARTNERKEY = @fromPartnerKey
			
		-- Переносим payments
		print 'Payments'
			update Payments set PM_PRKey = @toPartnerKey where PM_PRKey = @fromPartnerKey	
			
		-- Переносим blank ranges
		print 'BlankRanges'
			update BlankRanges set BR_PRKEY = @toPartnerKey where BR_PRKEY = @fromPartnerKey	
			
		-- Переносим prt bonuses
		print 'PrtBonuses'
			update PrtBonuses set PB_PRKey = @toPartnerKey where PB_PRKey = @fromPartnerKey	
			
		-- Переносим ins borderaus
		print 'InsBordero'
			update InsBordero set IBR_PRKEY = @toPartnerKey where IBR_PRKEY = @fromPartnerKey	
			
		-- Переносим send mails
		print 'SendMail'
			update SendMail set SM_PRKEY = @toPartnerKey where SM_PRKEY = @fromPartnerKey	
			
		-- Переносим partner accounts
		print 'PrtAccounts'
			update PrtAccounts set PA_PRKey = @toPartnerKey where PA_PRKey = @fromPartnerKey	
			
		-- Переносим cost ships
		print 'COSTSSHIP'
			update COSTSSHIP set CS_PRKEY = @toPartnerKey where CS_PRKEY = @fromPartnerKey	
			
		-- Переносим ins policy
		print 'InsPolicy'
			update InsPolicy set IP_PRKey = @toPartnerKey where IP_PRKey = @fromPartnerKey	
			
		-- Переносим ins agents
		print 'InsAgents'
			update InsAgents set IAG_PRKEY = @toPartnerKey where IAG_PRKEY = @fromPartnerKey	
			update InsAgents set IAG_AGENTKEY = @toPartnerKey where IAG_AGENTKEY = @fromPartnerKey	
			
		-- Переносим prt types to partners (признаки партнера)
		print 'PrtTypesToPartners'
			update PrtTypesToPartners set PTP_PRKey = @toPartnerKey where PTP_PRKey = @fromPartnerKey 
			and not exists (select 1 from PrtTypesToPartners old where old.PTP_PRKey = @toPartnerKey and old.PTP_PTId = PTP_PTId)	

		print 'CostOffers'
			update CostOffers set CO_PartnerKey = @toPartnerKey where CO_PartnerKey = @fromPartnerKey

		-- 06.02.2012. MEG00038742. Golubinsky
		-- обновляем данные в таблицах TP 
		print 'TP_Services'
			update TP_Services set ts_oppartnerkey = @toPartnerKey where ts_oppartnerkey = @fromPartnerKey

		print 'tp_lists'
			update tp_lists set ti_hdpartnerkey = @toPartnerKey where ti_hdpartnerkey = @fromPartnerKey
			update tp_lists set ti_chprkey = @toPartnerKey where ti_chprkey = @fromPartnerKey
			update tp_lists set ti_chbackprkey = @toPartnerKey where ti_chbackprkey = @fromPartnerKey

		print 'tp_flights'
			update tp_flights set tf_prkeyold = @toPartnerKey where tf_prkeyold = @fromPartnerKey
			update tp_flights set tf_prkeynew = @toPartnerKey where tf_prkeynew = @fromPartnerKey

		-- Удаляем первого партнера
		print 'DELETE from tbl_Partners'
			delete from tbl_Partners where PR_KEY = @fromPartnerKey
						
		COMMIT TRANSACTION @transactionName
		
	END TRY	
	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS ErrorNumber
			,ERROR_MESSAGE() AS ErrorMessage;
		ROLLBACK TRANSACTION @transactionName	 
	END CATCH


	BEGIN TRY
	
		-- обновляем данные на поисковых базах
		print 'sp_CollapsePartnerUpdateSearchTables'
			exec sp_CollapsePartnerUpdateSearchTables @fromPartnerKey, @toPartnerKey, @searchServerNames
	
	END TRY	
	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS ErrorNumber
			,ERROR_MESSAGE() AS ErrorMessage;
	END CATCH		
	
END

GO

GRANT EXECUTE ON sp_CollapsePartner TO PUBLIC

GO

/*********************************************************************/
/* end sp_CollapsePartner.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_CreateCostOffer.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CreateCostOffer]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CreateCostOffer]
GO
CREATE PROCEDURE [dbo].[CreateCostOffer]
	(
		-- хранимка создает костофер
		-- <data>2012-07-30</data>
		-- <version>2009.02.05</version>
		@code varchar(254),
		@name varchar(254),
		@partnerKey int,
		@packetKey int,
		@svKey int,
		@saleDateBeg datetime = null,
		@saleDateEnd datetime = null,
		@description varchar(254),
		@coId int output,
		-- сезон к которому прикрепим костофер
		@seasonId int = null
	)
AS
BEGIN

	if @saleDateBeg = ''
		set @saleDateBeg = null
	if @saleDateEnd = ''
		set @saleDateEnd = null
		
	-- если сезон не задан то находим его тут
	if (@seasonId is null)
	begin
		set @seasonId = (select top 1 SN_ID from Seasons where SN_IsActive = 1 order by SN_CreateDate desc)
	end

	insert into CostOffers (CO_Code, CO_Comment, CO_CreateDate, CO_DateActive, CO_Description, CO_State, CO_IsRules, CO_Name,
	CO_PartnerKey, CO_PKKey, CO_SaleDateBeg, CO_SaleDateEnd, CO_SeasonId, CO_SPOTypeId, CO_SVKey)
	values(@code, '', GETDATE(), null, @description, 0, 0, @name,
	@partnerKey, @packetKey, @saleDateBeg, @saleDateEnd, @seasonId, 1, @svKey)
	
	SET @coId = SCOPE_IDENTITY()

END
GO
/*********************************************************************/
/* end sp_CreateCostOffer.sql */
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
			          ,@MessageCountRead = SUM(case when HI_MessEnabled <= 1 then 1 else 0 end)
			          ,@MessageCountUnRead = SUM(case when HI_MessEnabled >= 2 then 1 else 0 end)
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
	
	--koshelev
	--2012-09-18 TFS 8126
	--Дин. ценообразование, экран "изменение цен"
	if (@calcKey is not null)
	begin
		update TP_Lists 
		set TI_CalculatingKey = @calcKey
		where TI_Key in (select TP_TIKey from TP_Prices where TP_TOKey = TI_TOKey and TP_CalculatingKey = @calcKey)
		and TI_TOKey = @tokey
		and TI_CalculatingKey <> @calcKey
		
		update TP_TurDates 
		set TD_CalculatingKey = @calcKey
		where TD_Date in (select TP_DateBegin from TP_Prices where TP_TOKey = TD_TOKey and TP_CalculatingKey = @calcKey)
		and TD_TOKey = @tokey
		and TD_CalculatingKey <> @calcKey
	end

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
		set @source = '[mt].[' + ltrim(rtrim(dbo.mwReplPublisherDB())) + '].'
	
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
/* begin sp_GetQuotaLoadListData_N.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetQuotaLoadListData_N]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetQuotaLoadListData_N]
GO

CREATE procedure [dbo].[GetQuotaLoadListData_N]
(
--<VERSION>2009.2.14</VERSION>
--<DATE>2012-07-13</DATE>
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
QL_dataType smallint, QL_Type smallint, QL_Release int, QL_Durations nvarchar(20) collate Cyrillic_General_CI_AS, QL_FilialKey int, 
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
		set @str = 'ALTER TABLE #QuotaLoadList ADD QL_' + CAST(@n as varchar(3)) + ' smallint'
		exec (@str)
		set @n = @n + 1
	END
END


if @bShowCommonInfo = 1
BEGIN
	insert into #QuotaLoadList 
	(QL_QTID, QL_Type, QL_Release, QL_dataType, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	select	DISTINCT QT_ID, QD_Type, case when QD_Release = 0 then null else QD_Release end, NU_ID, @DateEnd+1,QT_PRKey, QT_ByRoom
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
				and ((QO_SubCode2 = -1) or (QO_SubCode2 in (0,@Object_SubCode2)))
			))


	insert into #QuotaLoadList (QL_QTID, QL_Type, QL_Release, QL_dataType, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom)
	SELECT DISTINCT QL_QTID, QL_Type, QL_Release, NU_ID, QL_Durations, QL_FilialKey, QL_CityDepartments, QL_AgentKey, QL_CustomerInfo, QL_DateCheckinMin, QL_PRKey, QL_ByRoom
	FROM @TempTable2 nolock, Numbers (nolock)
	WHERE NU_ID between @Result_From and @Result_To

END

DECLARE @QD_ID int, @Date smalldatetime, @State smallint, @QD_Release int, @QP_Durations varchar(20), @QP_FilialKey int,
		@QP_CityDepartments int, @QP_AgentKey int, @Quota_Places int, @Quota_Busy int, @QP_IsNotCheckIn bit,
		@QD_QTID int, @QP_ID int, @Quota_Comment varchar(8000), @Stop_Comment varchar(255), @QO_ID int--,	@QT_ID int
DECLARE @ColumnName varchar(10), @QueryUpdate varchar(8000), @QueryUpdate1 varchar(255), @QueryWhere1 varchar(255), @QueryWhere2 varchar(255), 
		@QD_PrevID int, @StopSale_Percent int, @CheckInPlaces smallint, @CheckInPlacesBusy smallint --@QuotaObjects_Count int, 

if @bShowCommonInfo = 1
	DECLARE curQLoadList CURSOR FOR SELECT 
			QT_ID, QD_ID, QD_Date, QD_Type, case when QD_Release = 0 then null else QD_Release end,
			QD_Places, QD_Busy,
			0,'',0,0,0,0, ISNULL(REPLACE(QD_Comment,'''','"'),''),0,0
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
			QP_ID, QP_Durations, QP_FilialKey, QP_CityDepartments, QP_AgentKey, ISNULL(QP_IsNotCheckIn,0), ISNULL(REPLACE(QD_Comment,'''','"'),'') + '' + ISNULL(REPLACE(QP_Comment,'''','"'),''), QP_CheckInPlaces, QP_CheckInPlacesBusy
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
									@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, @QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy
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
										@QP_ID, @QP_Durations, @QP_FilialKey, @QP_CityDepartments, @QP_AgentKey, @QP_IsNotCheckIn, @Quota_Comment, @CheckInPlaces, @CheckInPlacesBusy
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
				Update #QuotaLoadList set QL_Description=LEFT(@ServiceName1 + @ServiceName2,255) where QL_ID=@IDEN_Prev
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
	Update #QuotaLoadList set QL_Description=LEFT(@ServiceName1 + @ServiceName2,255) where QL_ID=@IDEN_Prev

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
	order by ISNULL(QL_QTID,-1)-ISNULL(QL_QTID,-1) DESC /*Сначала квоты, потом неквоты*/,QL_PartnerName,QL_Type DESC,QL_Release,
		QL_CityDepartments,QL_FilialKey,QL_CustomerInfo,QL_QTID,QL_DataType, QL_Description,
		--сортируем по первому числу продолжительности если продолжительность с "-"
		case when CHARINDEX('-',QL_DURATIONS) = 0 
			then CONVERT(int,QL_DURATIONS)
			else CONVERT(int,SUBSTRING(QL_DURATIONS,0,CHARINDEX('-',QL_DURATIONS)))
		end
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
/* begin sp_GetServiceList.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetServiceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetServiceList]
GO

CREATE procedure [dbo].[GetServiceList] 
(
--<VERSION>2009.02.02</VERSION>
--<DATE>2012-07-06</DATE>
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
		where DL_SVKEY=' + CAST(@SVKey as varchar(20)) + ' AND DL_CODE in (' + @Codes + ') AND ''' + CAST(@Date as varchar(20)) + ''' BETWEEN DL_DATEBEG AND DL_DATEEND'
		
	if @QDID is not null
		SET @Query = @Query + ' and qp_qdid = ' + CAST(@QDID as nvarchar(max))
	if @QPID is not null
		SET @Query = @Query + ' and qp_id = ' + CAST(@QPID as nvarchar(max))
	
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
/* begin sp_GetTableQuotaDetails.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetTableQuotaDetails]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[GetTableQuotaDetails]
GO

create procedure [dbo].[GetTableQuotaDetails]
(
--<VERSION>2009.14</VERSION>
--<DATE>2012-07-27</DATE>
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
					and (QO_SVKey = @DL_SVKey or @DL_SVKey is null)
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
						and (QO_SVKey = @DL_SVKey or @DL_SVKey is null)
						and (QO_Code = SST_Code or QO_Code=0)
						and (QO_SubCode1 = SST_SubCode1 or QO_SubCode1 = 0)
						and (QO_SubCode2 = SST_SubCode2 or QO_SubCode2 = 0)
						and isnull(SS_IsDeleted, 0) = 0
						and (SST_Type = 1 or isnull(SS_AllotmentAndCommitment,0) = 1)
					)
END
 --where sst_QDID=2602
--проверка стопов
--окончание
if @GroupByQD=1
	select	SST_QDID, Count(*) as SST_QO_Count, 
			(SELECT count(*) from #StopSaleTemp_Local s2 WHERE s2.SST_QDID = s1.SST_QDID and (SST_State=2 or SST_State=1)) as SST_QO_CountWithStop,
			(SELECT TOP 1 SST_Comment FROM #StopSaleTemp_Local s3 WHERE s3.SST_QDID=s1.SST_QDID and SST_Comment is not null and SST_Comment != '') as SST_Comment
	from #StopSaleTemp_Local s1
	group by SST_QDID	
	having (SELECT count(*) from #StopSaleTemp_Local s2 WHERE s2.SST_QDID = s1.SST_QDID and SST_State is not null) > 0
else
	select * from #StopSaleTemp_Local
GO

grant execute on [dbo].[GetTableQuotaDetails] to public
GO

/*********************************************************************/
/* end sp_GetTableQuotaDetails.sql */
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

	-- настройки проверки квот через веб-сервис
	declare @checkQuotesOnWebService as bit, @checkQuotesService as nvarchar(150)
	set @checkQuotesOnWebService = 0
	select top 1 @checkQuotesOnWebService = ss_parmvalue from systemsettings with (nolock) where ss_parmname = 'NewSetToQuota'

	select top 1 @checkQuotesService = ss_parmvalue from systemsettings with (nolock) where ss_parmname = 'CheckQuotesWebService'

	if len(ltrim(rtrim(@checkQuotesService))) = 0
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
				select top 1 @cityFrom = ch_citykeyfrom, @cityTo = ch_citykeyto from charter with(nolock) where ch_key = @chkey
				
				declare altCharters cursor for
				select ch_key from
				(
					(
					select distinct ch_key, 0 as pr from Charter with (nolock)
					left join AirSeason with (nolock) on AS_CHKEY = CH_KEY
					where CH_CITYKEYFROM = @cityFrom
						and CH_CITYKEYTO = @cityTo
						and CH_KEY <> @chkey
					)
					union 
					(
						select CH_KEY, 1 as pr from Charter with (nolock) where CH_KEY = @chkey
					)
				) as alts
				order by pr desc

				declare @altChKey as int
				open altCharters

				fetch next from altCharters into @altChKey
				while @@FETCH_STATUS = 0
				begin

					declare @dateFrom datetime, @dateTo datetime
					set @dateFrom = dateadd(day, @day-1, @tourdate)
					set @dateTo = dateadd(day, @day-1, @tourdate)

					select @checkQuotesResult = result, @tmpPlaces = freePlaces, @tmpPlacesAll = allPlaces
					from [wcftest].[dbo].WcfQuotaCheckOneResult(1, 1, @altChKey, @nkey, @dateFrom, @dateTo,
						@partnerKey, @agentKey, @tourDays, @requestedPlaces, null)
				
					declare @freePlacesMask as int

					if @checkQuotesResult in (0, 3)
						set @freePlacesMask = 2	-- no places
					else if @checkQuotesResult in (1, 2, 4)
					begin
						set @freePlacesMask = 4	-- request
						set @tmpPlaces = -1
					end
					else if @checkQuotesResult = 5
						set @freePlacesMask = 1	-- yes
					
					if (@aviaQuotaMask & @freePlacesMask) = @freePlacesMask
						break;
				
					fetch next from altCharters into @altChKey
				
				end
				
				close altCharters
				deallocate altCharters
			
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
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCheckQuotesCycle]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwCheckQuotesCycle]
GO

CREATE procedure [dbo].[mwCheckQuotesCycle]
--<VERSION>ALL</VERSION>
--<DATE>2012-06-16</DATE>
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
		@chbackpkkey int,@chbackprkey int,@days int, @rowNum int, @hdStep smallint, @reviewed int,@selected int, @hdPriceCorrection int, @pt_directFlightAttribute int, @pt_backFlightAttribute int, @sql varchar(max)

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
	@pt_backFlightAttribute


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
--						select @tmpThereAviaQuota=res from #checked where svkey=1 and code=@chkey and date=@tourdate 
--										and day=@chday and days=@days and prkey=@chprkey and pkkey=@chpkkey
--										and find_flight = @findFlight
					if (@tmpThereAviaQuota is null)
					begin		
								
						exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @chbackday
						
--							insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res, find_flight) 
--								values(1,@chkey,0,0,@tourdate,@chday,@days,@chprkey, @chpkkey, @tmpThereAviaQuota, @findFlight)

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
							SET @places = @nAviaTariffFirst+@nAviaTariffSecond
						END

						EXEC [dbo].[mwCacheQuotaInsert] 1,@chkey,0,0,@tourdate,@chday,@days,@chprkey,@chpkkey,@tmpThereAviaQuota, @places, 0, 0, @additional, @findFlight
					end		
								
					if((len(@tmpThereAviaQuota)=0) OR (@places=0 and (@aviaQuotaMask & @RED_LABEL) <> @RED_LABEL))
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
--							select @tmpBackAviaQuota=res from #checked where svkey=1 and code=@chbackkey and date=@tourdate 
--											and day=@chbackday and days=@days and prkey=@chbackprkey and pkkey=@chbackpkkey
--											and find_flight = @findFlight
						EXEC [dbo].[mwCacheQuotaSearch] 1, @chbackkey, 0, 0, @tourdate, @chbackday, @days, @chbackprkey, @chbackpkkey, 
							@tmpBackAviaQuota OUTPUT, @places output, @step_index output, @price_correction output, @additional output, @findFlight
							
						if (@tmpBackAviaQuota is null)
						begin

							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chbackkey, @flightGroups, @agentKey, @chbackprkey, @tourdate,@chbackday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chbackpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output, @chday
--							insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res, find_flight) 
--								values(1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey, @tmpBackAviaQuota, @findFlight)

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
								SET @places = @nAviaTariffFirst+@nAviaTariffSecond
							END

							EXEC [dbo].[mwCacheQuotaInsert] 1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey,@tmpBackAviaQuota, @places, 0, 0, @additional, @findFlight
						end

						if((len(@tmpBackAviaQuota)=0) or (@places=0 and (@aviaQuotaMask & @RED_LABEL) <> @RED_LABEL))
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
					set @places = 0
--					select @tmpHotelQuota=res,@places=places,@hdStep=step_index,@hdPriceCorrection=price_correction from #checked where svkey=3 and code=@hdkey and rmkey=@rmkey and rckey=@rckey and date=@tourdate and day=@hdday and days=@hdnights and prkey=@hdprkey
					EXEC [dbo].[mwCacheQuotaSearch] 3, @hdkey, @rmkey, @rckey, @tourdate, @hdday, @hdnights, @hdprkey, 0, 
						@tmpHotelQuota OUTPUT, @places output, @hdStep output, @hdPriceCorrection output, @additional output, 0
					if (@tmpHotelQuota is null)
					begin

						select @places=qt_places,@allPlaces=qt_allPlaces,@additional=qt_additional from dbo.mwCheckQuotesEx(3,@hdkey,@rmkey,@rckey, @agentKey, @hdprkey,@tourdate,@hdday,@hdnights, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 0, 0, 0, 0, 0, @expiredReleaseResult)
						set @tmpHotelQuota=ltrim(str(@places)) + ':' + ltrim(str(@allPlaces))
						if(@pagingType = @DYNAMIC_SPO_PAGING and @places > 0)
						begin
							exec dbo.GetDynamicCorrections @now,@tourdate,3,@hdkey,@rmkey,@rckey,@places, @hdStep output, @hdPriceCorrection output
						end

--						insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res,places,step_index,price_correction) values(3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota,@places,@hdStep,@hdPriceCorrection)
						EXEC [dbo].[mwCacheQuotaInsert] 3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota,@places,@hdStep,@hdPriceCorrection, @additional, 0
					end

					-----------------------------------------------
					--=== Check quotes for all hotels in tour ===--
					--===              [BEGIN]                -----
					if (1 = 1 and @pt_hddetails is not null and charindex(',', @pt_hddetails, 0) > 0)
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
								select @tempPlaces=qt_places,@tempAllPlaces=qt_allPlaces,@additional=qt_additional from dbo.mwCheckQuotesEx(3,@curHotelKey,@curRoomKey,@curRoomCategoryKey, @agentKey, @curHotelPartnerKey,@tourdate, @curHotelDay,@curHotelDays, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, 0, 0, 0, 0, 0, @expiredReleaseResult)
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
		fetch next from quotaCursor into @ptkey,@pttourkey,@ptpricekey,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,@chday,@chpkkey,@chprkey,@chbackday,@chbackpkkey,@chbackprkey,@days,@chkey,@chbackkey,@rowNum, @pt_chdirectkeys, @pt_chbackkeys, @pt_hddetails, @pt_directFlightAttribute, @pt_backFlightAttribute
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
/* begin sp_mwFillTP.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwFillTP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwFillTP]
GO

CREATE procedure [dbo].[mwFillTP] (@tokey int, @calcKey int = null)
as
begin
	-- <date>2012-09-18</date>
	-- <version>2009.2.16.1</version>
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
/* begin sp_mwGetServiceIsEditableAttribute.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CalculatePriceList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[mwGetServiceIsEditableAttribute]
GO

create procedure [dbo].[mwGetServiceIsEditableAttribute]
--<VERSION>2009.2.14.1</VERSION>
--<DATE>2012-07-26</DATE>
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
	set @path = case dbo.mwReplIsSubscriber() when 1
					then 'mt.' + dbo.mwReplPublisherDB() + '.'
					else '' 
				end

	declare @sql varchar(4000)
	set @sql ='declare @tmp bit				
	select @tmp=1 from ' + @path + 'dbo.tp_services
	where ts_svkey = 1 and ts_tokey='+ltrim(rtrim(str(@tokey)))+' and ts_code='+ltrim(rtrim(str(@tscode)))+' and ts_day = ' + ltrim(rtrim(str(@day ))) + ' and ts_days in (0,' + ltrim(rtrim(str(@days))) + ') and ts_oppartnerkey= ' + ltrim(rtrim(str(@prkey))) + ' and ts_oppacketkey= ' + ltrim(rtrim(str(@pkkey))) + ' and (ts_attribute&+'+ltrim(rtrim(str(@editableCode)))+')='+ltrim(rtrim(str(@editableCode)))	
	exec (@sql)	
	set @isEditable = @@ROWCOUNT
end
GO

grant execute on [dbo].[mwGetServiceIsEditableAttribute] to public
GO
/*********************************************************************/
/* end sp_mwGetServiceIsEditableAttribute.sql */
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
/* begin sp_mwReindex.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwReindex]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[mwReindex] 
GO

create procedure [dbo].[mwReindex] as
begin

	ALTER INDEX ALL ON dbo.DogovorQuotes REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: DogovorQuotes', -2)

	ALTER INDEX ALL ON dbo.Mappings REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: Mappings', -2)
	
	ALTER INDEX ALL ON dbo.TurDate REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: TurDate', -2)
	
	ALTER INDEX ALL ON dbo.TuristService REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: TuristService', -2)
	
	ALTER INDEX ALL ON dbo.TurService REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: TurService', -2)

	ALTER INDEX ALL ON dbo.tbl_DogovorList REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: tbl_DogovorList', -2)	
	
	ALTER INDEX ALL ON dbo.tbl_TurList REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: tbl_TurList', -2)

	ALTER INDEX ALL ON dbo.tbl_Costs REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: tbl_Costs', -2)
	
	ALTER INDEX ALL ON dbo.tbl_Partners REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: tbl_Partners', -2)
		
	ALTER INDEX ALL ON dbo.DUP_USER REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: DUP_USER', -2)

	ALTER INDEX ALL ON dbo.HistoryQuote REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: HistoryQuote', -2)
	
	ALTER INDEX ALL ON dbo.History REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: History', -2)

	ALTER INDEX ALL ON dbo.mwSpoDataTable REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: mwSpoDataTable', 1)
	
	ALTER INDEX ALL ON dbo.mwPriceHotels REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: mwPriceHotels', 1)
	
	ALTER INDEX ALL ON dbo.mwPriceDurations REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: mwPriceDurations', 1)
	
	ALTER INDEX ALL ON dbo.TP_Lists REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: TP_Lists', 1)
	
	ALTER INDEX ALL ON dbo.TP_Prices REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: TP_Prices', 1)
	
	ALTER INDEX ALL ON dbo.TP_ServiceLists REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: TP_ServiceLists', 1)
	
	ALTER INDEX ALL ON dbo.TP_Services REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: TP_Services', 1)
	
	ALTER INDEX ALL ON dbo.TP_Tours REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: TP_Tours', 1)
	
	ALTER INDEX ALL ON dbo.TP_TurDates REBUILD WITH (FILLFACTOR = 70)
	insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: TP_TurDates', 1)

	declare @mwSearchType int 
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings 
	where SS_ParmName = 'MWDivideByCountry'

	if @mwSearchType = 0
	begin
		ALTER INDEX ALL ON dbo.mwPriceDataTable REBUILD WITH (FILLFACTOR = 70)
		insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: dbo.mwPriceDataTable', 1)
	end
	else
	begin
		declare @sql varchar(4000)
		declare @tableName varchar(500)
		declare @indexName varchar(500)

		declare cur cursor fast_forward read_only for select tbl.name, ind.name from sysobjects as tbl 
				INNER JOIN sys.indexes as ind on ind.object_id = tbl.id
		where tbl.name like 'mwPriceDataTable[_]%[_]%'
		
		open cur
		fetch next from cur into @tableName, @indexName
		while @@fetch_status = 0
			begin
				set @sql = 'ALTER INDEX ' + @indexName  + ' ON dbo.' + @tableName + ' REBUILD WITH (FILLFACTOR = 70)'
				insert into SystemLog (sl_date, sl_message, SL_AppID) values (getdate(), 'mwReindex: ' + @tableName + ' ' + @indexName, 1)
				--print @sql
				exec(@sql)
				fetch next from cur into @tableName, @indexName
			end		
		close cur
		deallocate cur
	end
end
GO

grant execute on [dbo].[mwReindex] to public
go
/*********************************************************************/
/* end sp_mwReindex.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_Paging.sql */
/*********************************************************************/
--<DATE>2012-07-24</DATE>
---<VERSION>2009.2.15</VERSION>
if exists (select * from [dbo].sysobjects where id = object_id(N'[dbo].[Paging]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    DROP PROCEDURE [dbo].[Paging]
GO

CREATE procedure [dbo].[Paging]
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
@calculateVisaDeadLine smallint = 0,
@noSmartSearch bit = 0
AS
set nocount on

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
				, pt_directFlightAttribute, pt_backFlightAttribute
				from ' + @tableName + ' with(nolock) inner join hotelPriorities with(nolock) on pt_hdkey = hp_hdkey
				where ' + @filter
				-- null не может быть для ВСЕХ одновременно приоритетов присутствующих в фильтах
				-- т.к. по стране фильтруем всегда, то приоритет для страны проверяем на null тоже всегда
				set @sql = @sql + 'and (HP_CountryPriority is not null'
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
		set @sql=@sql + ' , pt_directFlightAttribute, pt_backFlightAttribute from ' + @tableName + ' with(nolock) '

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
									and directCharter.cq_prkey = pt_chprkey
									and directCharter.cq_pkkey = pt_chpkkey
									and directCharter.cq_places <= 0
									and (pt_directFlightAttribute is not null 
											and 
											(
												(directCharter.cq_findFlight = 1 and (pt_directFlightAttribute & 2) = 2)
												or
												(directCharter.cq_findFlight = 0 and (pt_directFlightAttribute & 2) = 2)
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
									and backCharter.cq_prkey = pt_chprkey
									and backCharter.cq_pkkey = pt_chpkkey
									and backCharter.cq_places <= 0
									and (pt_backFlightAttribute is not null 
											and 
											(
												(backCharter.cq_findFlight = 1 and (pt_backFlightAttribute & 2) = 2)
												or
												(backCharter.cq_findFlight = 0 and (pt_backFlightAttribute & 2) = 2)
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
		-- <date>2012-08-21</date>
		-- <version>2009.02.25</version>
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
	
	-- таблица для записей которые не нужно расчитывать
	declare @notCalculatingQAC_Id table
	(
		xQAC_Id int
	)

	insert into @tableResult (xQAC_Id, xSCPId, xTRKey, xDateCheckIn, xSVKey, xQAC_TourLongMin, xQAC_TourLongMax)
	select top (@amountItem) QAC_Id, QAC_SCPID, QAC_TRKey, QAC_DateCheckIn, QAC_SVKey, QAC_TourLongMin, QAC_TourLongMax
	from TP_QueueAddCosts with(nolock)
	where 
	-- если задан ключ тура то выбираем строки только для него
	(@tourKeys is null or QAC_TRKey in (select xt_key from dbo.ParseKeys(@tourKeys)))
	-- если заданы конкретные записи в очереди то расчитываем только по ним
	and ((@xQACIdTable is null) or (QAC_Id in (select xt_key from dbo.ParseKeys(@xQACIdTable))))
	
	print 'Заполнение временной таблицы: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	-- удалим сразу записи которые не нужно расчитывать
	insert into @notCalculatingQAC_Id (xQAC_Id)
	select xQAC_Id
	from @tableResult
	where not exists (select top 1 1 from TP_PriceComponents where SCPId_1 = xSCPId and SVKey_1 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_2 = xSCPId and SVKey_2 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_3 = xSCPId and SVKey_3 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_4 = xSCPId and SVKey_4 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_5 = xSCPId and SVKey_5 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_6 = xSCPId and SVKey_6 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_7 = xSCPId and SVKey_7 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_8 = xSCPId and SVKey_8 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_9 = xSCPId and SVKey_9 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_10 = xSCPId and SVKey_10 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_11 = xSCPId and SVKey_11 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_12 = xSCPId and SVKey_12 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_13 = xSCPId and SVKey_13 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_14 = xSCPId and SVKey_14 = xSvKey and PC_TRKey = xTRKey)
	and not exists (select top 1 1 from TP_PriceComponents where SCPId_15 = xSCPId and SVKey_15 = xSvKey and PC_TRKey = xTRKey)

	delete TP_QueueAddCosts
	where QAC_Id in (select xQAC_Id from @notCalculatingQAC_Id)
	
	delete @tableResult
	where xQAC_Id in (select xQAC_Id from @notCalculatingQAC_Id)

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

	print 'Определение курсора: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()				
	
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
		
		fetch next from cursorReCalculateAddCosts into @SCPId, @nPacketkey, @nSvkey, @nCode, @nSubcode1, @nSubcode2, @tourdateCheckIn, @nServiceDays, @nPrkey, @men, @nTourDays
	end
	close cursorReCalculateAddCosts
	deallocate cursorReCalculateAddCosts
	
	print 'Работа с курсором: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
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
	
	set @PriceComponentsRows = @PriceComponentsRows + @@rowcount;

	print 'Количество строк в TP_PriceComponents: ' + convert(nvarchar(max), @PriceComponentsRows)
	
	print 'Перенос результата в TP_PriceComponents: ' + convert(nvarchar(max), datepart(mi, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ss, convert(datetime, getDate() - @beginTime))) + '.' + convert(nvarchar(max), datepart(ms, convert(datetime, getDate() - @beginTime)))
	set @beginTime = getDate()
	
	/*очистим очередь расчета*/
	delete TP_QueueAddCosts
	where QAC_Id in (select xQAC_Id from @tableResult)
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
/* begin sp_ReCalculate_TakeOff.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_TakeOff]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_TakeOff]
GO
CREATE PROCEDURE [dbo].[ReCalculate_TakeOff]
	(
		-- хранимка удаляет цены из TP_PricesComponents
		--<version>2009.2.03</version>
		--<data>2012-08-21</data>
		-- список ключей @pcIds для удаления цен
		@pcIds xml ([dbo].[ArrayOfLong]) = null
	)
AS
BEGIN	
	SET ARITHABORT ON;
	SET QUOTED_IDENTIFIER ON;
		
	declare @tempIdtable table
	(
		xPC_id bigint
	)
	
	insert into @tempIdtable(xPC_id)
	select tbl.res.value('.', 'bigint') from @pcIds.nodes('/ArrayOfLong/long') as tbl(res)
		
	update TP_PriceComponents
	set Gross_1 = null,
	PC_DateLastChangeGross = getdate(),
	PC_UpdateDate = getdate(),
	PC_State = 1
	where PC_Id in (select xPC_id from @tempIdtable)
END

GO
grant exec on [dbo].[ReCalculate_TakeOff] to public
go
/*********************************************************************/
/* end sp_ReCalculate_TakeOff.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_ReCalculate_ViewHottelCost.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReCalculate_ViewHotelCost]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ReCalculate_ViewHotelCost]
GO
CREATE PROCEDURE [dbo].[ReCalculate_ViewHotelCost]
	(
		-- хранимка выводит информацию о ценах на отель по набору заданных параметров, либо по ключам цен
		--<version>2009.2.08</version>
		--<data>2012-08-02</data>
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
		@priceKeys xml ([dbo].[ArrayOfLong]) = null				-- ключи цен, передаваемые из плагина MarginMonitor
	)
AS
BEGIN
	SET ARITHABORT ON;
	SET DATEFIRST 1;
	set nocount on;
	
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
		declare @tablePriceKeys table
		(
			xPriceKey bigint
		)	
		insert into @tablePriceKeys(xPriceKey)
		select tbl.res.value('.', 'bigint') 
		from @priceKeys.nodes('/ArrayOfLong/long') as tbl(res)
		
		insert into @hotelRoomsTable(SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY)
		select SC_Id, SC_Code, SC_SubCode1, SC_SubCode2, SC_PRKey, HR_RMKEY, HR_ACKEY, HR_RCKEY
		from tp_serviceComponents
		inner join hotelRooms on SC_SubCode1 = HR_KEY
		inner join tp_serviceCalculateParametrs on sc_id=scp_scid
		where tp_serviceCalculateParametrs.scp_id in
		(
			select scpid_1 as scpid from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_2 as scpid	from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_3 as scpid	from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_4 as scpid	from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_5 as scpid	from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_6 as scpid	from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_7 as scpid	from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_8 as scpid	from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_9 as scpid	from tp_priceComponents	where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_10 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_11 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_12 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_13 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_14 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeys)
			union
			select scpid_15 as scpid from tp_priceComponents where pc_id in (select xPriceKey from @tablePriceKeys)
		)
		
		select PC_Id, PC_TPKey, PC_TourDate, SCP_Date, SC_Code, SC_SubCode1, HR_RMKEY, HR_ACKEY, HR_RCKEY, SC_SubCode2, SC_PRKey,
		PC_Days, SCP_Days, SCP_Men, PC_TOKey, PC_SummPrice, TO_TRKey, TO_Name, TO_Rate, TO_IsEnabled,
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
		AddCostIsCommission_15, AddCostNoCommission_15, CommissionOnly_15, Gross_15, IsCommission_15, MarginPercent_15, SCPId_15, SVKey_15,
		AS_WEEK, CH_PORTCODETO, CH_AIRLINECODE, CH_FLIGHT, AS_TIMEFROM, null, null,
		null, null, null, null, null, null,
		null, null, null, null, null
		from TP_PriceComponents with(nolock)
		join TP_Tours with(nolock) on TO_Key = PC_TOKey
		join TP_ServiceCalculateParametrs with (nolock) on SCPId_1 = SCP_Id
		join @hotelRoomsTable on SCP_SCId = SC_Id
		join TP_Services on TS_TOKey = PC_TOKey
		join Charter on TS_Code = CH_KEY
		join AirSeason on AS_CHKEY = CH_KEY
		where PC_Id in (select xPriceKey from @tablePriceKeys)
		and TS_SVKey=1
		and TS_Day in (1,2)
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
	--<data>2012-08-21</data>
	--<version>2009.02.08</version>
begin
	if exists ( select top 1 1 from inserted where ADC_SVKey!=3) 
	begin
	--	3. В противном случае добавим строки в очередь на перерасчет доплат в расчитанных ценах 
	--	(если им соответствуют услуги в TP_Services)
		insert into dbo.TP_QueueAddCosts 
				(QAC_ADCId, QAC_DateCreate, QAC_DateCheckIn, QAC_SVKey, QAC_SCPId, QAC_TRKey, QAC_TourLongMin, QAC_TourLongMax)
		select  ADC_Id, getdate(), SCP_DateCheckIn, ADC_SVKey, SCP_ID, ADC_TLKey, ADC_LongMin, ADC_LongMax
		from    inserted, TP_ServiceComponents, TP_ServiceCalculateParametrs
		where   
				ADC_SVKey != 3
				and SCP_SCID=SC_ID 
				and ADC_SVKey = SC_SVKey
				and (ADC_Code = 0 OR ADC_Code = SC_Code)
				and (ADC_SubCode1 = 0 OR ADC_SubCode1=SC_SubCode1)
				and (ADC_SubCode2 = 0 OR ADC_SubCode2=SC_SubCode2)
				and (ADC_PartnerKey = 0 OR ADC_PartnerKey=SC_PRKey)
				-- нам нужны только доплаты на будующие даты
				and SCP_DateCheckIn > getdate()
				and SCP_DateCheckIn between ADC_CheckInDateBeg and ADC_CheckInDateEnd
				and (SCP_TourDays between case when isnull(ADC_LongMin, 0) = 0 then -100500 else ADC_LongMin end
					and case when isnull(ADC_LongMax, 0) = 0 then 100500 else ADC_LongMax end)
				and (		exists (select top 1 1 from TP_PriceComponents where SCPId_1 = SCP_ID and SVKey_1 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_2 = SCP_ID and SVKey_2 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_3 = SCP_ID and SVKey_3 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_4 = SCP_ID and SVKey_4 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_5 = SCP_ID and SVKey_5 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_6 = SCP_ID and SVKey_6 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_7 = SCP_ID and SVKey_7 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_8 = SCP_ID and SVKey_8 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_9 = SCP_ID and SVKey_9 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_10 = SCP_ID and SVKey_10 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_11 = SCP_ID and SVKey_11 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_12 = SCP_ID and SVKey_12 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_13 = SCP_ID and SVKey_13 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_14 = SCP_ID and SVKey_14 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_15 = SCP_ID and SVKey_15 = ADC_SVKey and PC_TRKey = ADC_TLKey)
					)
	END

	if exists ( select top 1 1 from inserted where ADC_SVKey=3) 
	begin
		insert into dbo.TP_QueueAddCosts 
				(QAC_ADCId, QAC_DateCreate, QAC_DateCheckIn, QAC_SVKey, QAC_SCPId, QAC_TRKey, QAC_TourLongMin, QAC_TourLongMax)
		select  ADC_Id, getdate(), SCP_DateCheckIn, ADC_SVKey, SCP_ID, ADC_TLKey, ADC_LongMin, ADC_LongMax
		from    inserted, TP_ServiceComponents, TP_ServiceCalculateParametrs
		where   
				ADC_SVKey = 3
				and SCP_SCID=SC_ID 
				and ADC_SVKey = SC_SVKey
				and (ADC_Code = 0 OR ADC_Code = SC_Code)
				and (ADC_SubCode1 = 0 OR SC_SubCode1 in (SELECT HR_Key FROM HotelRooms WHERE HR_RMKey=ADC_SubCode1))
				and (ADC_SubCode2 = 0 OR SC_SubCode1 in (SELECT HR_Key FROM HotelRooms WHERE HR_RCKey=ADC_SubCode2))
				and (ADC_PansionKey = 0 OR SC_SubCode2=ADC_PansionKey)
				and (ADC_PartnerKey = 0 OR ADC_PartnerKey=SC_PRKey)
				and SCP_DateCheckIn between ADC_CheckInDateBeg and ADC_CheckInDateEnd
				and (SCP_TourDays between case when isnull(ADC_LongMin, 0) = 0 then -100500 else ADC_LongMin end
					and case when isnull(ADC_LongMax, 0) = 0 then 100500 else ADC_LongMax end)
				and (		exists (select top 1 1 from TP_PriceComponents where SCPId_1 = SCP_ID and SVKey_1 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_2 = SCP_ID and SVKey_2 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_3 = SCP_ID and SVKey_3 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_4 = SCP_ID and SVKey_4 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_5 = SCP_ID and SVKey_5 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_6 = SCP_ID and SVKey_6 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_7 = SCP_ID and SVKey_7 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_8 = SCP_ID and SVKey_8 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_9 = SCP_ID and SVKey_9 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_10 = SCP_ID and SVKey_10 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_11 = SCP_ID and SVKey_11 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_12 = SCP_ID and SVKey_12 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_13 = SCP_ID and SVKey_13 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_14 = SCP_ID and SVKey_14 = ADC_SVKey and PC_TRKey = ADC_TLKey)
						or	exists (select top 1 1 from TP_PriceComponents where SCPId_15 = SCP_ID and SVKey_15 = ADC_SVKey and PC_TRKey = ADC_TLKey)
					)
	END	
end
GO
/*********************************************************************/
/* end T_AddCostsReCalculate.sql */
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
/* begin T_mwDeleteTour.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[mwDeleteTour]'))
	DROP TRIGGER [dbo].[mwDeleteTour]
GO

CREATE trigger [dbo].[mwDeleteTour] on [dbo].[TP_Tours]
for delete
as
begin
	--<DATE>2012-06-27</DATE>
	--<VERSION>9.2.13.4</VERSION>
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

			if(@tableName is not null and len(@tableName) > 0 and exists(select 1 from dbo.sysobjects where id = object_id(@tableName) and OBJECTPROPERTY(id, N'IsUserTable') = 1))
			begin
				set @sql = 'insert into mwDeleted with(rowlock) (del_key) select pt_pricekey from ' + @tableName + ' with(nolock) where pt_tourkey = ' + ltrim(str(@tokey)) + '
							update ' + @tableName + ' with(rowlock) set pt_isenabled = 0 where pt_isenabled > 0 and pt_tourkey = ' + ltrim(str(@tokey)) + '
							update mwSpoDataTable with(rowlock) set sd_isenabled = 0 where sd_isenabled > 0 and sd_tourkey = ' + ltrim(str(@tokey))
				exec (@sql)
			end

			delete from TP_Prices with(rowlock) where tp_tokey = @tokey
			delete from TP_PricesDeleted with(rowlock) where tpd_tokey = @tokey
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
			delete from TP_PricesDeleted with(rowlock) where tpd_tokey = @tokey
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
/* end T_mwDeleteTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_TSToServiceByDate.sql */
/*********************************************************************/
ALTER TRIGGER [T_TSToServiceByDate]
   ON  [dbo].[TuristService]
   AFTER  INSERT,DELETE 
AS 
--<VERSION>2009.2</VERSION>
--<DATE>2012-08-15</DATE>
DECLARE @TUID int,@O_DLKey int,@O_TUKey int,@N_DLKey int,@N_TUKey int,
		@BestPlace int, @BestRL int, @nDelCount smallint, @nInsCount smallint

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED
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

/*********************************************************************/
/* begin Version92.sql */
/*********************************************************************/
-- для версии 2009.2
update [dbo].[setting] set st_version = '9.2.15.2', st_moduledate = convert(datetime, '2012-11-26', 120),  st_financeversion = '9.2.15.2', st_financedate = convert(datetime, '2012-11-26', 120) where st_version like '9.%'
GO
UPDATE dbo.SystemSettings SET SS_ParmValue='2012-11-26' WHERE SS_ParmName='SYSScriptDate'
GO
/*********************************************************************/
/* end Version92.sql */
/*********************************************************************/
