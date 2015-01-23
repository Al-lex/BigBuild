-- добавление скрипта не вошедшего в скрипты обновления раньше
-- (090629)mwPriceDataTable.sql
if not exists(select * from syscolumns where name = 'pt_topricefor')
	alter table mwPriceDataTable add [pt_topricefor] [smallint] NOT NULL DEFAULT (0)

GO
update mwPriceDataTable set pt_topricefor = to_pricefor from tp_tours where pt_tourkey = to_key
GO
sp_refreshviewforall mwPriceTable
GO

if exists (select * from sysobjects where name like 'mwFillPriceTable')
	drop procedure [dbo].[mwFillPriceTable] 
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
			pt_topricefor)
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
			pt_topricefor
		from ' + @dataTableName
exec (@sql)
GO
grant exec on mwFillPriceTable to public

GO

if exists (select * from sysobjects where name like 'FillMasterWebSearchFields')
	drop procedure [dbo].[FillMasterWebSearchFields] 
GO
CREATE procedure [dbo].[FillMasterWebSearchFields](@tokey int, @add smallint = null)
as
begin
	if @tokey is null
	begin
		print 'Procedure does not support NULL param'
		return
	end

	update dbo.TP_Tours set TO_Update = 1, TO_Progress = 0 where TO_Key = @tokey

	create table #tmpHotelData (
		thd_tourkey int, 
		thd_firsthdkey int,
		thd_firstpnkey int, 
		thd_cnkey int, 
		thd_tlkey int, 
		thd_isenabled smallint, 
		thd_tourcreated datetime, 
		thd_hdstars varchar(15), 
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
		thd_cnname varchar(200),
		thd_tourname varchar(200),
		thd_hdname varchar(200),
		thd_ctname varchar(200),
		thd_rsname varchar(200),
		thd_ctfromname varchar(200),
		thd_cttoname varchar(200),
		thd_tourtypename varchar(200),
		thd_pncode varchar(50),
		thd_hdorder int,
		thd_hotelkeys varchar(256),
		thd_pansionkeys varchar(256),
		thd_hotelnights varchar(256),
		thd_tourvalid datetime
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
		[pt_hdstars] [varchar] (12) NULL ,
		[pt_pnkey] [int] NULL ,
		[pt_hrkey] [int] NULL ,
		[pt_rmkey] [int] NULL ,
		[pt_rckey] [int] NULL ,
		[pt_ackey] [int] NULL ,
		[pt_childagefrom] [int] NULL ,
		[pt_childageto] [int] NULL ,
		[pt_childagefrom2] [int] NULL ,
		[pt_childageto2] [int] NULL ,
		[pt_hdname] [varchar] (60),
		[pt_tourname] [varchar] (128),
		[pt_pnname] [varchar] (30),
		[pt_pncode] [varchar] (3),
		[pt_rmname] [varchar] (60),
		[pt_rmcode] [varchar] (60),
		[pt_rcname] [varchar] (60),
		[pt_rccode] [varchar] (40),
		[pt_acname] [varchar] (30),
		[pt_accode] [varchar] (30),
		[pt_rsname] [varchar] (50),
		[pt_ctname] [varchar] (50),
		[pt_rmorder] [int] NULL ,
		[pt_rcorder] [int] NULL ,
		[pt_acorder] [int] NULL ,
		[pt_rate] [varchar] (3),
		[pt_toururl] [varchar] (128),
		[pt_hotelurl] [varchar] (254),
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
		pt_hotelkeys varchar(256),
		pt_hotelroomkeys varchar(256),
		pt_hotelstars varchar(256),
		pt_pansionkeys varchar(256),
		pt_hotelnights varchar(256),
		pt_chdirectkeys varchar(50) null,
		pt_chbackkeys varchar(50) null,		
		[pt_topricefor] [smallint] NOT NULL DEFAULT (0)
	)

	declare @mwAccomodationPlaces varchar(254)
	declare @mwRoomsExtraPlaces varchar(254)
	declare @mwSearchType int
	declare @sql varchar(8000)
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
			where tp_tokey = @toKey and tp_dateend >= getdate() and tp_key not in (select pt_pricekey from mwPriceDataTable with(nolock))
	end

---=                         =---
---===                     ===---
---===========================---

	update tp_lists with(rowlock)
	set
		ti_firsthotelday = (select min(ts_day) 
				from tp_services with (nolock)
 				where ts_svkey = 3 and ts_tokey = ti_tokey)
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours set TO_Progress = 7 where TO_Key = @tokey

	update TP_Tours set TO_MinPrice = (
			select min(TP_Gross) 
			from TP_Prices 
				left join TP_Lists on ti_key = tp_tikey
				left join HotelRooms on hr_key = ti_firsthrkey
				
			where TP_TOKey = TO_Key and hr_main > 0
		)
		where TO_Key = @toKey

	update TP_Tours set TO_HotelNights = dbo.mwTourHotelNights(TO_Key) where TO_Key = @toKey


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
		ti_nights = (select sum(ts_days) 
				from tp_servicelists with (nolock)
					inner join tp_services with (nolock) on tl_tskey = ts_key 
				where tl_tikey = ti_key and ts_svkey = 3)
	where
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

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

	-- город вылета
	update tp_lists
	set 
		ti_chkey = (select top 1 ts_code
			from tp_servicelists 
				inner join tp_services on (tl_tskey = ts_key and ts_svkey = 1)
				inner join tp_tours on ts_tokey = to_key inner join tbl_turList on tbl_turList.tl_key = to_trkey
			where tl_tikey = ti_key and ts_day <= tp_lists.ti_firsthotelday and ts_subcode2 = tl_ctdeparturekey)
	where ti_tokey = @tokey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	update dbo.TP_Tours set TO_Progress = 50 where TO_Key = @tokey

	-- город вылета + прямой перелет
	update tp_lists
	set 
		ti_chday = ts_day,
		ti_chpkkey = ts_oppacketkey,
		ti_chprkey = ts_oppartnerkey
	from tp_servicelists inner join tp_services on (tl_tskey = ts_key and ts_svkey = 1)
		inner join tp_tours on ts_tokey = to_key inner join tbl_turList on tbl_turList.tl_key = to_trkey
	where tl_tikey = ti_key and ts_day <= tp_lists.ti_firsthotelday and ts_code = ti_chkey and ts_subcode2 = tl_ctdeparturekey
		and ti_tokey = @tokey and tl_tokey = @tokey and ts_tokey = @tokey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	update tp_lists
	set 
		ti_ctkeyfrom = tl_ctdeparturekey
	from tp_tours inner join tbl_turList on tl_key = to_trkey
	where ti_tokey = to_key and to_key = @tokey
		and (@add <= 0 or ti_key in (select tikey from #tmpPrices))

	-- Проверка наличия перелетов в город вылета
	declare @existBackCharter smallint
	select	@existBackCharter = count(ts_key)
	from	tp_services
		inner join tp_tours on ts_tokey = to_key inner join tbl_turList on tbl_turList.tl_key = to_trkey
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
	from tp_servicelists
		inner join tp_services on (tl_tskey = ts_key and ts_svkey = 1)
		inner join tp_tours on ts_tokey = to_key inner join tbl_turList on tbl_turList.tl_key = to_trkey
	where 
		tl_tikey = ti_key 
		and ts_day > ti_lasthotelday
		and (ts_ctkey = tl_ctdeparturekey or @existBackCharter = 0)
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

	-- ключ города и ключ курорта
	update tp_lists
	set
		ti_firstctkey = hd_ctkey,
		ti_firstrskey = hd_rskey
	from hoteldictionary
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
		thd_tourvalid
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
		to_datevalid
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
		[pt_topricefor]
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
		tl_nameweb, 
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
		dbo.mwGetTourCharters(ti_key, 1),
		dbo.mwGetTourCharters(ti_key, 0),
		to_pricefor
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
			set @sql = 'delete from mwPriceDataTable with(rowlock) where pt_tourkey = ' + cast(@tokey as varchar(20))
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
				set @sql = 'delete from ' + dbo.mwGetPriceTableName(@countryKey, @cityFromKey) + ' with(rowlock) where pt_tourkey = ' + cast(@tokey as varchar(20))
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
		sd_tourvalid
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
		thd_tourvalid 
	from #tmpHotelData 
	where thd_hdmain > 0

	update dbo.TP_Tours set TO_Update = 0, TO_Progress = 100 where TO_Key = @tokey
end
GO
grant exec on [dbo].[FillMasterWebSearchFields] to public
GO


if exists (select * from sysindexes where name = 'x_main_persprice')
	drop index [dbo].[mwPriceDataTable].[x_main_persprice]
GO
/****** Object:  Index [x_main_persprice]    Script Date: 06/29/2009 15:49:00 ******/
CREATE NONCLUSTERED INDEX [x_main_persprice] ON [dbo].[mwPriceDataTable] 
(
	[pt_cnkey] ASC,
	[pt_ctkeyfrom] ASC,
	[pt_tourdate] ASC,
	[pt_tourkey] ASC,
	[pt_rmkey] ASC,
	[pt_nights] ASC,
	[pt_pnkey] ASC,
	[pt_hdstars] ASC,
	[pt_rskey] ASC,
	[pt_ctkey] ASC,
	[pt_hdkey] ASC,
	[pt_tourtype] ASC,
	[pt_isenabled] ASC,
	[pt_main] ASC,
	[pt_childageto] ASC,
	[pt_topricefor] ASC
)

GO

if exists (select * from sysindexes where name = 'x_main_roomprice')
	drop index [dbo].[mwPriceDataTable].[x_main_roomprice]
GO
CREATE NONCLUSTERED INDEX [x_main_roomprice] ON [dbo].[mwPriceDataTable] 
(
	[pt_cnkey] ASC,
	[pt_ctkeyfrom] ASC,
	[pt_mainplaces] ASC,
	[pt_addplaces] ASC,
	[pt_tourdate] ASC,
	[pt_tourkey] ASC,
	[pt_nights] ASC,
	[pt_pnkey] ASC,
	[pt_hdstars] ASC,
	[pt_rskey] ASC,
	[pt_ctkey] ASC,
	[pt_hdkey] ASC,
	[pt_tourtype] ASC,
	[pt_isenabled] ASC,
	[pt_topricefor] ASC
)
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
@sMainMenAdress varchar (70) = null,	-- контактное лицо. адрес
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

-- 090715(AddAction).sql

if NOT exists(select ac_key from dbo.actions where ac_key = 64)
	insert into dbo.actions (AC_KEY, AC_NAME, AC_NAMELAT) values (64, 'Турпутевка->Запретить снимать запрет на ограничения по редактированию услуг', 'Reservation->Deny dogovor attribute edit')
GO

insert into dbo.ActionsAuth (ACA_ACKey, ACA_USKey) select 64, US_KEY from UserList where not exists (select 1 from dbo.ActionsAuth where ACA_ACKey = 64 and ACA_USKey = US_KEY)
GO

-- 091113(AlterTable_Dogovor).sql

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[tbl_dogovor]') and name = 'DG_DAKey')
	ALTER TABLE dbo.tbl_dogovor ADD DG_DAKey int NULL
GO

Update dbo.tbl_dogovor set DG_DAKey = 
CAST(ISNULL(HI_TEXT, '0') AS INT)
from History
where HI_DGCOD = DG_Code and HI_OAId = 25
GO

exec sp_RefreshViewForAll 'Dogovor'
GO




-- 091110(Insert_ObjectAliases).sql

IF NOT EXISTS (SELECT 1 FROM OBJECTALIASES WHERE OA_ID = 27)
	INSERT INTO OBJECTALIASES (OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID) VALUES (27, 'MasterService', 'Задания MasterService', 0)
GO
	
IF NOT EXISTS (SELECT 1 FROM OBJECTALIASES WHERE OA_ID = 200000)
	INSERT INTO OBJECTALIASES (OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID) VALUES (200000, 'MS_ProTourServicePriceImport', 'Импорт нетто по счетам партнёра из ProTour', 0)
GO

IF NOT EXISTS (SELECT 1 FROM OBJECTALIASES WHERE OA_ID = 200001)
	INSERT INTO OBJECTALIASES (OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID) VALUES (200001, 'MS_PaymentControl_PaymentDateSet', 'Контроль оплат - установка даты оплаты', 0)
GO

IF NOT EXISTS (SELECT 1 FROM OBJECTALIASES WHERE OA_ID = 200002)
	INSERT INTO OBJECTALIASES (OA_ID, OA_ALIAS, OA_NAME, OA_TABLEID) VALUES (200002, 'MS_SendMail_Added', 'Отправка email-сообщения', 0)
GO

-- 091005_DropTriggerToursIsEnabled.sql

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_PTToursIsEnabledUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_PTToursIsEnabledUpdate]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_TPToursIsEnabledUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_TPToursIsEnabledUpdate]
GO

-- 091127_AlterTableLOContents.sql

if not exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_LOC_LOKEY]'))
	ALTER TABLE [dbo].[LOContents]  WITH NOCHECK ADD  CONSTRAINT [FK_LOC_LOKEY] FOREIGN KEY([LOC_LOKEY])
	REFERENCES [dbo].[LogicalObjects] ([LO_KEY])
	ON DELETE CASCADE
Go

-- 091201_AlterTableService.sql

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[service]') and name = 'SV_IsIndividual')
	ALTER TABLE dbo.service ADD SV_IsIndividual smallint NULL
GO

-- sp_CalculateDogovorCost.sql

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

SELECT @totalDays = MAX(ISNULL(DL_DAY, 0) + ISNULL(DL_NDAYS, 0) - CASE DL_SVKEY WHEN 3 THEN 1 ELSE 0 END) 
FROM tbl_dogovorlist 
WHERE dl_dgkey = @nDGKey

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


-- 091202(DescTypes_AdjustToParentQuote).sql

if not exists (select 1 from desctypes where dt_key = 100)
     insert into desctypes (dt_key, dt_name, dt_tableid, dt_order) values (100,'Проверять наличие мест по основному размещению', 9, 1)
go

-- 091202(alter_mwSpoDataTable).sql

if not exists(select id from syscolumns where id = OBJECT_ID('mwSpoDataTable') and name = 'sd_hotelurl')
					ALTER TABLE mwSpoDataTable ADD sd_hotelurl varchar(254) null
go

exec sp_refreshviewforall mwSpoData
go

update mwSpoDataTable set sd_hotelurl = hd_http
	from HotelDictionary
	where sd_hdkey = hd_key
go


-- update_prtdogkey.sql

update tbl_dogovor set dg_prtdogkey = 0 where dg_prtdogkey < 0

-- 091207(mwGetTourCharters).sql

if exists(select id from sysobjects where name='mwGetTourCharters' and xtype='fn')
	drop function dbo.mwGetTourCharters
go

create function [dbo].[mwGetTourCharters](@tikey int, @isDirectFlight smallint)
returns varchar(256)
as
begin
	declare @result varchar(256)
	set		@result = ''

	select 
		@result = @result + isnull(ltrim(str(ts_code)),'') + ':' + isnull(ltrim(str(ts_day)),'') + ':' + isnull(ltrim(str(TS_OpPartnerKey)),'') + ':' + isnull(ltrim(str(TS_OpPacketKey)),'') + ','
	from 
		tp_services 
			inner join tp_servicelists on tl_tskey = ts_key
			inner join tp_lists on ti_key = tl_tikey
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
go

grant exec on dbo.mwGetTourCharters to public
go



-- sp_mwCheckQuotesCycle.sql

if object_id('dbo.mwCheckQuotesCycle', 'p') is not null
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

	set @reviewed= @pageNum
	set @selected=0

	declare @now datetime, @percentPlaces float, @pos int
	set @now = getdate()

	fetch next from quotaCursor into @ptkey,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,@chday,@chpkkey,@chprkey,@chbackday,@chbackpkkey,@chbackprkey,@days,@chkey,@chbackkey,@rowNum, @pt_chdirectkeys, @pt_chbackkeys
	while(@@fetch_status=0 and @selected < @pageSize)
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
			insert into #Paging(ptKey,pt_hdquota,pt_chtherequota,pt_chbackquota,chkey,chbackkey,stepId,priceCorrection)
			values(@ptkey,@tmpHotelQuota,@tmpThereAviaQuota,@tmpBackAviaQuota,@chkey,@chbackkey,@hdStep,@hdPriceCorrection)
		end

		set @reviewed=@reviewed + 1

		fetch next from quotaCursor into @ptkey,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,@chday,@chpkkey,@chprkey,@chbackday,@chbackpkkey,@chbackprkey,@days,@chkey,@chbackkey,@rowNum, @pt_chdirectkeys, @pt_chbackkeys
	end

	select @reviewed
end
go

grant exec on dbo.mwCheckQuotesCycle to public
go

-- 091210(Tbl_Events_EventProcessings).sql


if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Events]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[Events](
	[EV_ID] [int] IDENTITY(1,1) NOT NULL,
	[EV_ExternalID] [int] NULL,
	[EV_SystemType] [smallint] NOT NULL,
	[EV_PRKEY] [int] NOT NULL,
	[EV_ObjectType] [nvarchar](20) NOT NULL,
	[EV_ObjectID] [int] NOT NULL,
	[EV_Type] [int] NOT NULL,
	[EV_CreateDate] [datetime] NOT NULL CONSTRAINT [DF_Events_EV_CreateDate]  DEFAULT (getdate()),
	[EV_Value] [nvarchar](50) NULL,
 CONSTRAINT [PK_Events] PRIMARY KEY CLUSTERED 
(
	[EV_ID] ASC
) ON [PRIMARY]
)
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[EventProcessings]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[EventProcessings](
	[EP_ID] [int] IDENTITY(1,1) NOT NULL,
	[EP_EVID] [int] NOT NULL,
	[EP_Status] [smallint] NOT NULL,
	[EP_AppName] [nvarchar](50) NOT NULL,
	[EP_CreateDate] [datetime] NOT NULL CONSTRAINT [DF_EventProcessings_EP_CreateDate]  DEFAULT (getdate()),
 CONSTRAINT [PK_EventProcessings] PRIMARY KEY CLUSTERED 
(
	[EP_ID] ASC
) ON [PRIMARY]
) 
GO

-- T_DogovorListUpdate.sql

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_DogovorListUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_DogovorListUpdate]
GO

CREATE TRIGGER [dbo].[T_DogovorListUpdate]
ON [dbo].[tbl_DogovorList]
FOR UPDATE, INSERT, DELETE
AS
IF @@ROWCOUNT > 0
BEGIN
--<VERSION>2007.2.33.0</VERSION>
--<DATE>2009-10-19</DATE>
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
  DECLARE @ODL_sDateEnd varchar(10)
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
  DECLARE @NDL_sDateEnd varchar(10)
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
			N.DL_PartnerKey, N.DL_Cost, N.DL_Brutto, N.DL_Discount, N.DL_Wait, N.DL_Control, CONVERT( char(10), N.DL_DateBeg, 104), CONVERT( char(10), N.DL_DateEnd, 104),
			N.DL_RealNetto, N.DL_Attribute, N.DL_PaketKey, N.DL_Name, N.DL_Payed, N.DL_QuoteKey, N.DL_TimeBeg
			
      FROM INSERTED N 
  END
  ELSE IF (@nInsCount = 0)
  BEGIN
	SET @sMod = 'DEL'
    DECLARE cur_DogovorList CURSOR FOR 
    SELECT 	O.DL_Key,
			O.DL_DgCod, O.DL_DGKey, O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_SubCode2, O.DL_CnKey, O.DL_CtKey, O.DL_NMen, O.DL_Day, O.DL_NDays, 
			O.DL_PartnerKey, O.DL_Cost, O.DL_Brutto, O.DL_Discount, O.DL_Wait, O.DL_Control, CONVERT( char(10), O.DL_DateBeg, 104), CONVERT( char(10), O.DL_DateEnd, 104),
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
			O.DL_PartnerKey, O.DL_Cost, O.DL_Brutto, O.DL_Discount, O.DL_Wait, O.DL_Control, CONVERT( char(10), O.DL_DateBeg, 104), CONVERT( char(10), O.DL_DateEnd, 104),
			O.DL_RealNetto, O.DL_Attribute, O.DL_PaketKey, O.DL_Name, O.DL_Payed, O.DL_QuoteKey, O.DL_TimeBeg,
	  		N.DL_DgCod, N.DL_DGKey, N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_SubCode2, N.DL_CnKey, N.DL_CtKey, N.DL_NMen, N.DL_Day, N.DL_NDays, 
			N.DL_PartnerKey, N.DL_Cost, N.DL_Brutto, N.DL_Discount, N.DL_Wait, N.DL_Control, CONVERT( char(10), N.DL_DateBeg, 104), CONVERT( char(10), N.DL_DateEnd, 104),
			N.DL_RealNetto, N.DL_Attribute, N.DL_PaketKey, N.DL_Name, N.DL_Payed, N.DL_QuoteKey, N.DL_TimeBeg
    FROM DELETED O, INSERTED N 
    WHERE N.DL_Key = O.DL_Key
  END

    OPEN cur_DogovorList
    FETCH NEXT FROM cur_DogovorList INTO 
		@DL_Key, 
			@ODL_DgCod, @ODL_DGKey, @ODL_SvKey, @ODL_Code, @ODL_SubCode1, @ODL_SubCode2, @ODL_CnKey, @ODL_CtKey, @ODL_NMen, @ODL_Day, @ODL_NDays, 
			@ODL_PartnerKey, @ODL_Cost, @ODL_Brutto, @ODL_Discount, @ODL_Wait, @ODL_Control, @ODL_sDateBeg, @ODL_sDateEnd, 
			@ODL_RealNetto, @ODL_Attribute, @ODL_PaketKey, @ODL_Name, @ODL_Payed, @ODL_QuoteKey, @ODL_TimeBeg,
			@NDL_DgCod, @NDL_DGKey, @NDL_SvKey, @NDL_Code, @NDL_SubCode1, @NDL_SubCode2, @NDL_CnKey, @NDL_CtKey, @NDL_NMen, @NDL_Day, @NDL_NDays, 
			@NDL_PartnerKey, @NDL_Cost, @NDL_Brutto, @NDL_Discount, @NDL_Wait, @NDL_Control, @NDL_sDateBeg, @NDL_sDateEnd, 
			@NDL_RealNetto, @NDL_Attribute, @NDL_PaketKey, @NDL_Name, @NDL_Payed, @NDL_QuoteKey, @NDL_TimeBeg
    WHILE @@FETCH_STATUS = 0
	BEGIN
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
				exec dbo.GetSVCodeName @ODL_SvKey, @ODL_Code, @sText_Old, null
				exec dbo.GetSVCodeName @NDL_SvKey, @NDL_Code, @sText_New, null
				IF @NDL_SvKey=1
					EXECUTE dbo.InsertHistoryDetail @nHIID , 1027, @sText_Old, @sText_New, @ODL_Code, @NDL_Code, null, null, 0, @bNeedCommunicationUpdate output
				ELSE IF @NDL_SvKey = 2
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
			@ODL_PartnerKey, @ODL_Cost, @ODL_Brutto, @ODL_Discount, @ODL_Wait, @ODL_Control, @ODL_sDateBeg, @ODL_sDateEnd, 
			@ODL_RealNetto, @ODL_Attribute, @ODL_PaketKey, @ODL_Name, @ODL_Payed, @ODL_QuoteKey, @ODL_TimeBeg,
			@NDL_DgCod, @NDL_DGKey, @NDL_SvKey, @NDL_Code, @NDL_SubCode1, @NDL_SubCode2, @NDL_CnKey, @NDL_CtKey, @NDL_NMen, @NDL_Day, @NDL_NDays, 
			@NDL_PartnerKey, @NDL_Cost, @NDL_Brutto, @NDL_Discount, @NDL_Wait, @NDL_Control, @NDL_sDateBeg, @NDL_sDateEnd, 
			@NDL_RealNetto, @NDL_Attribute, @NDL_PaketKey, @NDL_Name, @NDL_Payed, @NDL_QuoteKey, @NDL_TimeBeg
	END
  CLOSE cur_DogovorList
  DEALLOCATE cur_DogovorList
 END
GO

-- 091111(mwSyncDictionaryData).sql

if object_id('dbo.mwSyncDictionaryData', 'p') is not null
	drop proc dbo.mwSyncDictionaryData
go

create proc dbo.mwSyncDictionaryData @update_search_table smallint = 0
as
begin
	update dbo.mwSpoDataTable
	set
		sd_cnname = cn_name
	from
		tbl_country
	where
		sd_cnkey = cn_key
		and sd_cnname <> cn_name


	update dbo.mwSpoDataTable
	set
		sd_ctfromname = ct_name
	from
		dbo.citydictionary
	where
		sd_ctkeyfrom = ct_key
		and sd_ctfromname <> ct_name


	update dbo.mwSpoDataTable
	set
		sd_hdstars = hd_stars,
		sd_ctkey = hd_ctkey,
		sd_rskey = hd_rskey,
		sd_hdname = hd_name
	from
		dbo.hoteldictionary
	where
		sd_hdkey = hd_key
		and (
			sd_hdstars <> hd_stars
			or sd_ctkey <> hd_ctkey
			or sd_rskey <> hd_rskey
			or sd_hdname <> hd_name
		)

	update dbo.mwSpoDataTable
	set
		sd_ctname = ct_name
	from
		dbo.citydictionary
	where
		sd_ctkey = ct_key
		and sd_ctname <> ct_name


	update dbo.mwSpoDataTable
	set
		sd_rsname = rs_name
	from
		dbo.resorts
	where
		sd_rskey = rs_key
		and sd_rsname <> rs_name

	update dbo.mwSpoDataTable
	set
		sd_tourname = tl_nameweb,
		sd_tourtype = tl_tip
	from
		dbo.tbl_turlist
	where
		sd_tlkey = tl_key
		and (
			sd_tourname <> tl_nameweb
			or sd_tourtype <> tl_tip
		)

	update dbo.mwSpoDataTable
	set
		sd_tourtypename = tp_name
	from
		dbo.tiptur
	where
		sd_tourtype = tp_key
		and sd_tourtypename <> tp_name

	update dbo.mwSpoDataTable
	set
		sd_tourcreated = to_datecreated,
		sd_tourvalid = to_datevalid
	from
		dbo.tp_tours
	where
		sd_tourkey = to_key
		and (
			sd_tourcreated <> to_datecreated
			or sd_tourvalid <> to_datevalid
		)

	update dbo.mwSpoDataTable
	set
		sd_pncode = pn_code
	from
		dbo.pansion
	where
		sd_pnkey = pn_key
		and sd_pncode <> pn_code

	-- mwPriceDataTable

	if @update_search_table > 0
	begin
		while exists(select 1 from dbo.mwPriceDataTable with(nolock) 
			where exists(select 1 from hoteldictionary with(nolock) where
				pt_hdkey = hd_key
				and (
					pt_hdstars <> hd_stars
					or pt_ctkey <> hd_ctkey
					or pt_rskey <> hd_rskey
					or pt_hdname <> hd_name
					or pt_hotelurl <> hd_http
				)
			)
		)
		begin
			update top (100000) dbo.mwPriceDataTable
			set
				pt_hdstars = hd_stars,
				pt_ctkey = hd_ctkey,
				pt_rskey = hd_rskey,
				pt_hdname = hd_name,
				pt_hotelurl = hd_http
			from
				dbo.hoteldictionary
			where
				pt_hdkey = hd_key
				and (
					pt_hdstars <> hd_stars
					or pt_ctkey <> hd_ctkey
					or pt_rskey <> hd_rskey
					or pt_hdname <> hd_name
					or pt_hotelurl <> hd_http
				)
		end

		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.citydictionary with(nolock) where
				pt_ctkey = ct_key
				and pt_ctname <> ct_name
			)
		)
		begin
			update top (100000) dbo.mwPriceDataTable
			set
				pt_ctname = ct_name
			from
				dbo.citydictionary
			where
				pt_ctkey = ct_key
				and pt_ctname <> ct_name
		end

		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.resorts with(nolock) where
				pt_rskey = rs_key
				and pt_rsname <> rs_name
			)
		)
		begin
			update top (100000) dbo.mwPriceDataTable
			set
				pt_rsname = rs_name
			from
				dbo.resorts
			where
				pt_rskey = rs_key
				and pt_rsname <> rs_name
		end

		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.tbl_turlist with(nolock) where
				pt_tlkey = tl_key
				and (
					pt_tourname <> tl_nameweb or
					pt_toururl <> tl_webhttp or
					pt_tourtype <> tl_tip
				)
			)
		)
		begin
			update top (100000) dbo.mwPriceDataTable
			set
				pt_tourname = tl_nameweb,
				pt_toururl = tl_webhttp,
				pt_tourtype = tl_tip
			from
				dbo.tbl_turlist
			where
				pt_tlkey = tl_key
				and (
					pt_tourname <> tl_nameweb or
					pt_toururl <> tl_webhttp or
					pt_tourtype <> tl_tip
				)
		end

		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.tp_tours with(nolock) where
				pt_tourkey = to_key
				and (
					pt_tourcreated <> to_datecreated
					or pt_tourvalid <> to_datevalid
					or pt_rate COLLATE DATABASE_DEFAULT <> to_rate COLLATE DATABASE_DEFAULT
				)
			)
		)
		begin
			update top (100000) dbo.mwPriceDataTable
			set
				pt_tourcreated = to_datecreated,
				pt_tourvalid = to_datevalid,
				pt_rate = to_rate
			from
				dbo.tp_tours
			where
				pt_tourkey = to_key
				and (
					pt_tourcreated <> to_datecreated
					or pt_tourvalid <> to_datevalid
					or pt_rate COLLATE DATABASE_DEFAULT <> to_rate COLLATE DATABASE_DEFAULT
				)
		end

		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.pansion with(nolock) where
				pt_pnkey = pn_key
				and (
					pt_pnname <> pn_name
					or pt_pncode <> pn_code
				)
			)
		)
		begin
			update top (100000) dbo.mwPriceDataTable
			set
				pt_pnname = pn_name,
				pt_pncode = pn_code
			from
				dbo.pansion
			where
				pt_pnkey = pn_key
				and (
					pt_pnname <> pn_name
					or pt_pncode <> pn_code
				)
		end

		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.rooms with(nolock) where
				pt_rmkey = rm_key
				and (
					pt_rmname <> rm_name
					or pt_rmcode <> rm_code
					or pt_rmorder <> rm_order
				)
			)
		)
		begin
			update top (100000) dbo.mwPriceDataTable
			set
				pt_rmname = rm_name,
				pt_rmcode = rm_code,
				pt_rmorder = rm_order
			from
				dbo.rooms
			where
				pt_rmkey = rm_key
				and (
					pt_rmname <> rm_name
					or pt_rmcode <> rm_code
					or pt_rmorder <> rm_order
				)
		end

		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.roomscategory with(nolock) where
				pt_rckey = rc_key
				and (
					pt_rcname <> rc_name
					or pt_rccode <> rc_code
					or pt_rcorder <> rc_order
				)
			)
		)
		begin
			update top (100000) dbo.mwPriceDataTable
			set
				pt_rcname = rc_name,
				pt_rccode = rc_code,
				pt_rcorder = rc_order
			from
				dbo.roomscategory
			where
				pt_rckey = rc_key
				and (
					pt_rcname <> rc_name
					or pt_rccode <> rc_code
					or pt_rcorder <> rc_order
				)
		end

		while exists(select 1 from dbo.mwPriceDataTable with(nolock)
			where exists(select 1 from dbo.accmdmentype with(nolock) where
				pt_ackey = ac_key
				and (
					pt_acname <> ac_name
					or pt_accode <> ac_code
					or pt_acorder <> ac_order
				)
			)
		)
		begin
			update top (100000) dbo.mwPriceDataTable
			set
				pt_acname = ac_name,
				pt_accode = ac_code,
				pt_acorder = ac_order
			from
				dbo.accmdmentype
			where
				pt_ackey = ac_key
				and (
					pt_acname <> ac_name
					or pt_accode <> ac_code
					or pt_acorder <> ac_order
				)
		end
	end
end
go

grant exec on dbo.mwSyncDictionaryData to public
go

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
            DECLARE @AlwaysRecalcPrice int 
            SELECT  @AlwaysRecalcPrice = isnull(SS_ParmValue,0) FROM dbo.systemsettings  
            WHERE SS_ParmName = 'SYSAlwaysRecalcNational' 

			SELECT @sAction = [Action] FROM #RecalculateAction
			DROP TABLE #RecalculateAction

			-- Нам надо , чтобы пересчет осуществлялся ТОЛЬКО
			-- при создании путевки
			-- при ее подтверждении (переход в статус Ок или ОК)
			-- при изменении валютной стоимости
			-- 00024586
            if @AlwaysRecalcPrice > 0
			  EXEC dbo.NationalCurrencyPrice @ODG_Rate, @NDG_Rate, @ODG_Code, @NDG_Price, @ODG_Price, @NDG_DiscountSum, @sAction, @NDG_SOR_Code
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

-- (091215)Paging.sql

if exists(select id from sysobjects where xtype='p' and name='PagingPax')
	drop proc dbo.[PagingPax]

GO

CREATE procedure  [dbo].[PagingPax]
	@countryKey	int,			
	@departFromKey	int,		
	@filter		varchar(4000),	
	@sortExpr	varchar(1024),	
	@pageNum	int=0,			
	@pageSize	int=9999,		
	@agentKey	int=0,			
	@hotelQuotaMask smallint=0,	
	@aviaQuotaMask smallint=0,	
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

declare @pagingType int
	set @pagingType = 0

-- Move @countryKey and @departFromKey to filter
set @filter=' pt_cnkey= ' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom= ' + LTRIM(STR(@departFromKey)) + ' and ' + @filter

declare @MAX_ROWCOUNT int
	set @MAX_ROWCOUNT=1000 

declare @sortType smallint
	set @sortType = 1	

declare @spageNum varchar(30)		
	set @spageNum=LTRIM(STR(@pageNum))

declare @spageSize varchar(30)		
	set @spageSize=LTRIM(STR(@pageSize))

declare @sql varchar(8000)
	set @sql=''

declare @zptPos int
declare @prefix varchar(1024)
set @zptPos = charindex(',',@sortExpr)
if(@zptPos > 0)
	set @prefix = substring(@sortExpr, 1, @zptPos)
else
	set @prefix = @sortExpr

if(charindex('desc', @prefix) > 0)
	set @sortType=-1

declare @viewName varchar(256)
if(@sortType <= 0)
	set @viewName='mwPriceTablePaxViewDesc'
else
	set @viewName='mwPriceTablePaxViewAsc'


CREATE TABLE #days
(
	days int,
	nights int
)

SET @sql='
	select		distinct pt_days,pt_nights 
	from		dbo.mwPriceTable t1 with(nolock) 
---- Берем только последние цены
--	inner join 
--	(	
--		select	pt_ctkeyfrom ctkeyfrom,	pt_cnkey cnkey, 		pt_tourtype tourtype,	pt_mainplaces mainplaces, 
--				pt_addplaces addplaces,	pt_tourdate tourdate,	pt_pnkey pnkey, 		pt_pansionkeys pansionkeys,
--				pt_days days,			pt_nights nights,		pt_hdkey hdkey,			pt_hotelkeys hotelkeys,
--				pt_hrkey hrkey,			max(pt_key) ptkey 
--		from	dbo.mwPriceTable with(nolock) 
--		group by 
--				pt_ctkeyfrom,			pt_cnkey,				pt_tourtype,			pt_mainplaces,
--				pt_addplaces,			pt_tourdate,			pt_pnkey,				pt_pansionkeys,
--				pt_nights,				pt_hotelnights,			pt_days,				pt_hdkey,
--				pt_hotelkeys,			pt_hrkey
--	) t2
--	on			t1.pt_ctkeyfrom=t2.ctkeyfrom 		and			t1.pt_cnkey=t2.cnkey 
--		and		t1.pt_tourtype = t2.tourtype 		and			t1.pt_mainplaces=t2.mainplaces 
--		and		t1.pt_addplaces=t2.addplaces 		and			t1.pt_tourdate=t2.tourdate
--		and		t1.pt_pnkey=t2.pnkey				and			t1.pt_nights=t2.nights
--		and		t1.pt_days=t2.days					and			t1.pt_hdkey=t2.hdkey 
--		and		t1.pt_hrkey=t2.hrkey				and			t1.pt_key=t2.ptkey 
	where ' + @filter + ' and pt_days is not null and pt_nights is not null
	order by pt_days,pt_nights'
--print @sql
--print ' Before Execute GetDurationsScript: ' + CONVERT(VARCHAR(20), getdate(),114 )
INSERT INTO #days EXEC(@sql)
--print ' After  Execute GetDurationsScript: ' + CONVERT(VARCHAR(20), getdate(),114 )

	create table #checked(
		svkey int,		code int,
		rmkey int,		rckey int,
		date datetime,	[day] int,
		days int,		prkey int,
		pkkey int,		res varchar(256),
		places int,		step_index smallint,
		price_correction int
	)

	create table #resultsTable(
		paging_id int, 
		pt_ctkey int, 
		pt_ctname varchar(50), 
		pt_hdkey int, 
		pt_hdname varchar(60), 
		pt_hdstars varchar(12), 
		pt_hotelurl varchar(254),
		pt_pnkey int, 
		pt_pncode varchar(30), 
		pt_rate varchar(3), 
		pt_rmkey int, 
		pt_rmname varchar(35), 
		pt_rckey int, 
		pt_rcname varchar(35),
		pt_tourdate datetime
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
		pt_chbackquota varchar(256)		
	)

declare @d int
declare @n int
declare @sdays varchar(10)

declare @sKeysSelect varchar(2024)
	set @sKeysSelect=''

declare @sAlter varchar(2024)
	set @sAlter=''

declare @sWhere varchar(5000)
	set @sWhere=''

--declare @sAddSelect varchar(3950)
--	set @sAddSelect=''
--
--declare @sJoin varchar(3950)
--	set @sJoin=''

declare @sJoinTable varchar(20)
	set @sJoinTable=''

declare @sTmp varchar(8000)
	set @sTmp=''

declare @rowCount int

declare @priceFilter nvarchar(512)
	set @priceFilter = N''

declare @priceKeyFilter nvarchar(512)
	set @priceKeyFilter = N''

declare @nightsPart nvarchar(256)
declare @hotelNightsPart nvarchar(256)

declare @dml varchar(7950)
	set @dml = N''

DECLARE dCur CURSOR FOR SELECT days,nights FROM #days
OPEN dCur
FETCH NEXT FROM dCur INTO @d,@n
WHILE (@@fetch_status=0)
BEGIN
	set @sdays=LTRIM(STR(@d)) + '_' + LTRIM(STR(@n))
	if(substring(@sortExpr, 1, 1) = '*')
	begin
		set @sortExpr = 'p_' + @sdays + '_DBL' + substring(@sortExpr, 2, len(@sortExpr) - 1)
	end
	
----------------------------------------------------------
-- Prepare script for add quota columns to result table --
----------------------------------------------------------
 	if(len(@dml) > 0) 
		set @dml = @dml + ','

	set @dml = @dml + 'prk_' + @sdays + '_DBL varchar(256), hq_' + @sdays + '_DBL varchar(10), cq_' + @sdays + '_DBL varchar(256), cbq_' + @sdays + '_DBL varchar(256), ' +
		'prk_' + @sdays + '_SGL varchar(256), hq_' + @sdays + '_SGL varchar(10), cq_' + @sdays + '_SGL varchar(256), cbq_' + @sdays + '_SGL varchar(256), ' +
		'prk_' + @sdays + '_EXB varchar(256), hq_' + @sdays + '_EXB varchar(10), cq_' + @sdays + '_EXB varchar(256), cbq_' + @sdays + '_EXB varchar(256), ' +
		'prk_' + @sdays + '_CHD varchar(256), hq_' + @sdays + '_CHD varchar(10), cq_' + @sdays + '_CHD varchar(256), cbq_' + @sdays + '_CHD varchar(256)'

---------------------------------------------------------------------------------------
-- Prepare script for select price-duration columns values from View to result table --
---------------------------------------------------------------------------------------
 	if(len(@sKeysSelect) > 0)
		set @sKeysSelect=@sKeysSelect + ', '
	
	set @sKeysSelect=@sKeysSelect 
		+ '  p_' + @sdays + '_DBL' + ', pk_' + @sdays + '_DBL'
		+ ', p_' + @sdays + '_SGL' + ', pk_' + @sdays + '_SGL'
		+ ', p_' + @sdays + '_EXB' + ', pk_' + @sdays + '_EXB'
		+ ', p_' + @sdays + '_CHD' + ', pk_' + @sdays + '_CHD'

-------------------------------------------------------------------
-- Prepare script for add price-duration columns to result table --
-------------------------------------------------------------------
	if(len(@sAlter) > 0)
		set @sAlter=@sAlter + ','

	set @sAlter=@sAlter + 'p_' + @sdays + '_DBL float,pk_' + @sdays + '_DBL int'
		+ ',p_' + @sdays + '_SGL float,pk_' + @sdays + '_SGL int'
		+ ',p_' + @sdays + '_EXB float,pk_' + @sdays + '_EXB int'
		+ ',p_' + @sdays + '_CHD float,pk_' + @sdays + '_CHD int'

-----------------------------------------------
-- Prepare filter predicate for quotas table --
-----------------------------------------------
	if(len(@sWhere) > 0)
		set @sWhere=@sWhere + ' or '

	set @sWhere=@sWhere + 'pt_key in (select pk_' + @sdays + '_DBL from #resultsTable)'
		+ ' or pt_key in (select pk_' + @sdays + '_SGL from #resultsTable)'
		+ ' or pt_key in (select pk_' + @sdays + '_EXB from #resultsTable)'
		+ ' or pt_key in (select pk_' + @sdays + '_CHD from #resultsTable)'

--	if(len(@sAddSelect) > 0)
--		set @sAddSelect=@sAddSelect + ','
--
--	set @sAddSelect=@sAddSelect + ' t_' + @sdays + '_DBL.pt_pricekey prk_' + @sdays + '_DBL, t_' + @sdays + '_DBL.pt_hdquota hq_' + @sdays + '_DBL, t_' + @sdays + '_DBL.pt_chtherequota cq_' + @sdays + '_DBL, t_' + @sdays + '_DBL.pt_chbackquota cbq_' + @sdays + '_DBL'
--								+ ',t_' + @sdays + '_SGL.pt_pricekey prk_' + @sdays + '_SGL, t_' + @sdays + '_SGL.pt_hdquota hq_' + @sdays + '_SGL, t_' + @sdays + '_SGL.pt_chtherequota cq_' + @sdays + '_SGL, t_' + @sdays + '_SGL.pt_chbackquota cbq_' + @sdays + '_SGL'
--								+ ',t_' + @sdays + '_EXB.pt_pricekey prk_' + @sdays + '_EXB, t_' + @sdays + '_EXB.pt_hdquota hq_' + @sdays + '_EXB, t_' + @sdays + '_EXB.pt_chtherequota cq_' + @sdays + '_EXB, t_' + @sdays + '_EXB.pt_chbackquota cbq_' + @sdays + '_EXB'
--								+ ',t_' + @sdays + '_CHD.pt_pricekey prk_' + @sdays + '_CHD, t_' + @sdays + '_CHD.pt_hdquota hq_' + @sdays + '_CHD, t_' + @sdays + '_CHD.pt_chtherequota cq_' + @sdays + '_CHD, t_' + @sdays + '_CHD.pt_chbackquota cbq_' + @sdays + '_CHD'
--
--
--	set @sJoin=@sJoin + ' left outer join #quotaCheckTable t_' + @sdays + '_DBL on t.pk_' + @sdays + '_DBL = t_' + @sdays + '_DBL.pt_key'
--		+ ' left outer join #quotaCheckTable t_' + @sdays + '_SGL on t.pk_' + @sdays + '_SGL = t_' + @sdays + '_SGL.pt_key'
--		+ ' left outer join #quotaCheckTable t_' + @sdays + '_EXB on t.pk_' + @sdays + '_EXB = t_' + @sdays + '_EXB.pt_key'
--		+ ' left outer join #quotaCheckTable t_' + @sdays + '_CHD on t.pk_' + @sdays + '_CHD = t_' + @sdays + '_CHD.pt_key'

	FETCH NEXT FROM dCur INTO @d,@n
END
CLOSE dCur
DEALLOCATE dCur

if(len(@sKeysSelect) > 0)
begin
	set @sTmp = 'alter table #resultsTable add ' + @sAlter
	exec(@sTmp)

	declare @daysPart varchar(50)
	set @daysPart = dbo.mwGetFilterPart(@filter, 'pt_days')

	if(@daysPart is not null)
		set @filter = REPLACE(@filter, @daysPart, '1 = 1')

	--print ' Before Execute PagingSelect: ' + CONVERT(VARCHAR(20), getdate(),114 )

	declare @nSql nvarchar(4000)
	set @nSql=N'
	DECLARE @firstRecord int,@lastRecord int
	SET @firstRecord=('+ @spageNum + ' - 1) * ' + @spageSize+ ' + 1
	SET @lastRecord=('+ @spageNum +' *'+ @spageSize + ')
	select top 250 identity(int,1,1) paging_id, pt_ctkey, pt_ctname, pt_hdkey, pt_hdname, pt_hdstars, hd_http as pt_hotelurl, pt_pnkey, pt_pncode, pt_rate, pt_rmkey, pt_rmname, pt_rckey, pt_rcname, pt_tourdate' 
	
	if(len(@sKeysSelect) > 0)
		set @nSql=@nSql + ',' + @sKeysSelect 
	
	set @nSql=@nSql + '
		into #pg from ' + @viewName + ' inner join hoteldictionary with(nolock) on pt_hdkey = hd_key where ' + @filter

	if(len(isnull(@sortExpr,'')) > 0)
		set @nSql=@nSql + '		order by ' + @sortExpr 

	if(@rowCount is not null)
		set @nSql = @nSql + '
	select @@RowCount as RowsCount'
	else
		set @nSql = @nSql + '
	set @rowCountOUT = @@RowCount'

	set @nSql=@nSql + ' 
	select paging_id, pt_ctkey, pt_ctname, pt_hdkey, pt_hdname, pt_hdstars, pt_hotelurl, pt_pnkey, pt_pncode, pt_rate, pt_rmkey, pt_rmname, pt_rckey, pt_rcname, pt_tourdate'
	if(len(@sKeysSelect) > 0)
		set @nSql=@nSql + ',' + @sKeysSelect 
	set @nSql = @nSql +
	'
	from #pg WHERE #pg.paging_id BETWEEN @firstRecord and @lastRecord order by paging_id
	'

	declare @ParamDef nvarchar(100)
	set @ParamDef = '@rowCountOUT int output'
	
--	print @nSql
	INSERT INTO #resultsTable
		exec sp_executesql @nSql, @ParamDef, @rowCountOUT = @rowCount output
	SELECT @rowCount

--print ' After Filling #resultTable: ' + CONVERT(VARCHAR(20), getdate(), 114)
--print @nSql

	-- Add quota columns to result table
	set @dml = 'ALTER TABLE #resultsTable ADD  ' + @dml
	exec (@dml)

	SET @sTmp = 'select pt_key, pt_pricekey, pt_tourdate, pt_days,	pt_nights, pt_hdkey, pt_hdday,
						pt_hdnights, (case when ' + ltrim(str(isnull(@checkAllPartnersQuota, 0))) + ' > 0 then -1 else pt_hdpartnerkey end), pt_rmkey,	pt_rckey, pt_chkey,	pt_chday, pt_chpkkey,
						pt_chprkey, pt_chbackkey, pt_chbackday, pt_chbackpkkey, pt_chbackprkey, null, null, null
				from dbo.mwPriceTablePax
				where ' + @sWhere
--print ' Before Execute GetQuotaCheckTableScript: ' + CONVERT(VARCHAR(20), getdate(),114 )
--	print @sTmp
	INSERT INTO #quotaCheckTable exec(@sTmp)
--print ' After  Execute GetQuotaCheckTableScript: ' + CONVERT(VARCHAR(20), getdate(),114 )

	declare quotaCursor cursor for
	select pt_hdkey,pt_rmkey,pt_rckey,pt_tourdate,
		pt_chkey,pt_chbackkey,
		pt_hdday,pt_hdnights,pt_hdpartnerkey,pt_chday,(case when @checkFlightPacket > 0 then pt_chpkkey else -1 end) as pt_chpkkey,pt_chprkey,
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
		if(@hotelQuotaMask > 0)
		begin
			set @tmpHotelQuota=null
			select @tmpHotelQuota=res from #checked where svkey=3 and code=@hdkey and rmkey=@rmkey and rckey=@rckey and date=@tourdate and day=@hdday and days=@hdnights and prkey=@hdprkey
			if (@tmpHotelQuota is null)
			begin
				select @places=qt_places,@allPlaces=qt_allPlaces from dbo.mwCheckQuotesEx(3,@hdkey,@rmkey,@rckey, @agentKey,@hdprkey,@tourdate,@hdday,@hdnights,@requestOnRelease,@noPlacesResult,@checkAgentQuota,@checkCommonQuota,@checkNoLongQuota,0,0,0,0,0,@expiredReleaseResult)
				set @tmpHotelQuota=ltrim(str(@places)) + ':' + ltrim(str(@allPlaces))

				insert into #checked(svkey,code,rmkey,rckey,date,[day],days,prkey,pkkey,res) values(3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota)
			end
		end

		update #quotaCheckTable set pt_hdquota=@tmpHotelQuota,
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

------------------------------------------------------------------------------------------
------------------------- Fill #resultsTable with data of quotes -------------------------
--																						--
	DECLARE @UpdateQuotesSQL varchar(8000)												--
		SET @UpdateQuotesSQL = N''														--
																						--
	DECLARE daysCursor CURSOR FOR SELECT days,nights FROM #days							--
	OPEN daysCursor																		--
	FETCH NEXT FROM daysCursor INTO @d,@n												--
	WHILE (@@fetch_status=0)															--
	BEGIN																				--
		SET @sdays = LTRIM(STR(@d)) + '_' + LTRIM(STR(@n))								--
																						--
		SET @UpdateQuotesSQL =															--
			'UPDATE #resultsTable SET ' +												--
				'prk_' + @sdays + '_DBL = pt_pricekey, ' +								--
				'hq_' + @sdays + '_DBL = pt_hdquota, ' +								--
				'cq_' + @sdays + '_DBL = pt_chtherequota, ' +							--
				'cbq_' + @sdays + '_DBL = pt_chbackquota ' +							--
			'FROM #quotaCheckTable WHERE pk_' + @sdays + '_DBL = pt_key '				--
		EXEC (@UpdateQuotesSQL)															--
																						--
		SET @UpdateQuotesSQL =															--
			'UPDATE #resultsTable SET ' +												--
				'prk_' + @sdays + '_SGL = pt_pricekey, ' +								--
				'hq_' + @sdays + '_SGL = pt_hdquota, ' +								--
				'cq_' + @sdays + '_SGL = pt_chtherequota, ' +							--
				'cbq_' + @sdays + '_SGL = pt_chbackquota ' +							--
			'FROM #quotaCheckTable WHERE pk_' + @sdays + '_SGL = pt_key '				--
		EXEC (@UpdateQuotesSQL)															--
																						--
		SET @UpdateQuotesSQL =															--
			'UPDATE #resultsTable SET ' +												--
				'prk_' + @sdays + '_EXB = pt_pricekey, ' +								--
				'hq_' + @sdays + '_EXB = pt_hdquota, ' +								--
				'cq_' + @sdays + '_EXB = pt_chtherequota, ' +							--
				'cbq_' + @sdays + '_EXB = pt_chbackquota ' +							--
			'FROM #quotaCheckTable WHERE pk_' + @sdays + '_EXB = pt_key '				--
		EXEC (@UpdateQuotesSQL)															--
																						--
		SET @UpdateQuotesSQL =															--
			'UPDATE #resultsTable SET ' +												--
				'prk_' + @sdays + '_CHD = pt_pricekey, ' +								--
				'hq_' + @sdays + '_CHD = pt_hdquota, ' +								--
				'cq_' + @sdays + '_CHD = pt_chtherequota, ' +							--
				'cbq_' + @sdays + '_CHD = pt_chbackquota ' +							--
			'FROM #quotaCheckTable WHERE pk_' + @sdays + '_CHD = pt_key '				--
		EXEC (@UpdateQuotesSQL)															--
																						--
		FETCH NEXT FROM daysCursor INTO @d,@n											--
	END																					--
	CLOSE daysCursor																	--
	DEALLOCATE daysCursor																--
--																						--
-------------------------										 -------------------------
------------------------------------------------------------------------------------------

select * from #resultsTable

end
else 
begin
	select 0
	select * from #resultsTable
end

GO

grant exec on dbo.PagingPax to public

GO

if exists(select id from sysobjects where xtype='p' and name='Paging')
	drop proc dbo.[Paging]

GO

CREATE Procedure [dbo].[Paging]
@pagingType	smallint=2,
@countryKey	int,
@departFromKey	int,
@filter		varchar(4000),
@sortExpr	varchar(1024),
@pageNum	int=0,
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

declare @tableName varchar(256)
declare @viewName varchar(256)
if(@mwSearchType=0)
begin
	set @tableName='mwPriceTable'
	set @viewName='mwPriceTableView'
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
if @pagingType=0
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

	set @sql='select distinct top 5 pt_days,pt_nights from '
	if(@mwSearchType=0)
		set @sql=@sql + @tableName +  ' t1 with(nolock) inner join (select pt_ctkeyfrom ctkeyfrom,pt_cnkey cnkey, pt_tourtype tourtype,pt_mainplaces mainplaces, pt_addplaces addplaces, pt_tourdate tourdate,pt_pnkey pnkey,pt_pansionkeys pansionkeys,pt_days days,pt_nights nights,pt_hdkey hdkey,pt_hotelkeys hotelkeys,pt_hrkey hrkey,max(pt_key) ptkey from ' + @tableName + ' with(nolock) group by pt_ctkeyfrom,pt_cnkey,pt_tourtype,pt_mainplaces, pt_addplaces,pt_tourdate,pt_pnkey,pt_pansionkeys,pt_nights,pt_hotelnights,pt_days,pt_hdkey,pt_hotelkeys,pt_hrkey) t2
	on t1.pt_ctkeyfrom=t2.ctkeyfrom and t1.pt_cnkey=t2.cnkey and t1.pt_tourtype = t2.tourtype and t1.pt_mainplaces=t2.mainplaces and t1.pt_addplaces=t2.addplaces and t1.pt_tourdate=t2.tourdate
		and t1.pt_pnkey=t2.pnkey and t1.pt_nights=t2.nights and t1.pt_days=t2.days and
			t1.pt_hdkey=t2.hdkey and t1.pt_hrkey=t2.hrkey and t1.pt_key=t2.ptkey where pt_cnkey=' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom=' + LTRIM(STR(@departFromKey)) + ' and ' + @filter
	else
		set @sql=@sql + @tableName + ' t1 with(nolock) inner join (select pt_ctkeyfrom ctkeyfrom,pt_cnkey cnkey, pt_tourtype tourtype,pt_mainplaces mainplaces, pt_addplaces addplaces, pt_tourdate tourdate,pt_pnkey pnkey,pt_pansionkeys pansionkeys,pt_days days,pt_nights nights,pt_hdkey hdkey,pt_hotelkeys hotelkeys,,pt_hrkey hrkey,max(pt_key) ptkey from ' + @tableName + ' with(nolock) group by pt_ctkeyfrom,pt_cnkey,pt_tourtype,pt_mainplaces, pt_addplaces,pt_tourdate,pt_pnkey,pt_pansionkeys,pt_nights,pt_hotelnights,pt_days,pt_hdkey,pt_hotelkeys,pt_hrkey) t2
	on t1.pt_ctkeyfrom=t2.ctkeyfrom and t1.pt_cnkey=t2.cnkey and t1.pt_tourtype = t2.tourtype and t1.pt_mainplaces=t2.mainplaces and t1.pt_addplaces=t2.addplaces and t1.pt_tourdate=t2.tourdate
		and t1.pt_pnkey=t2.pnkey and t1.pt_nights=t2.nights and t1.pt_days=t2.days and
			t1.pt_hdkey=t2.hdkey and t1.pt_hrkey=t2.hrkey and t1.pt_key=t2.ptkey where ' + @filter

	set @sql=@sql + ' order by pt_days,pt_nights'
	print @sql
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
			pt_cnname varchar(50),
			pt_ctname varchar(50),
			pt_rsname varchar(20),		
			pt_rmname varchar(35),
			pt_rcname varchar(35),
			pt_acname varchar(30),
			pt_chkey int,
			pt_chbackkey int,
			pt_hotelkeys varchar(256),
			pt_hotelroomkeys varchar(256),
			pt_hotelnights varchar(256),
			pt_hotelstars varchar(256),
			pt_pansionkeys varchar(256)
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
			pt_chbackquota varchar(256)		
		)

	end

	declare @d int
	declare @n int
	declare @sdays varchar(10)
	declare @sWhere varchar(2024)
	set @sWhere=''
	declare @sAddSelect varchar(2024)
	set @sAddSelect=''
	declare @sJoin varchar(2024)
	set @sJoin=''
	declare @sJoinTable varchar(20)
	set @sJoinTable=''
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

			set @sAlter=@sAlter + 'p_' + @sdays + ' float,pk_' + @sdays + ' int'

			if(len(@sWhere) > 0)
				set @sWhere=@sWhere + ' or '

			set @sWhere=@sWhere + 'pt_key in (select pk_' + @sdays + ' from #resultsTable)'

			if(len(@sAddSelect) > 0)
				set @sAddSelect=@sAddSelect + ','

			set @sAddSelect=@sAddSelect + ' t_' + @sdays + '.pt_pricekey prk_' + @sdays + ', t_' + @sdays + '.pt_hdquota hq_' + @sdays + ', t_' + @sdays + '.pt_chtherequota cq_' + @sdays + ', t_' + @sdays + '.pt_chbackquota cbq_' + @sdays

			set @sJoin=@sJoin + ' left outer join #quotaCheckTable t_' + @sdays + ' on t.pk_' + @sdays + ' = t_' + @sdays + '.pt_key'

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

		insert into #resultsTable exec PagingSelect @sKeysSelect,@spageNum,@spageSize,@filter,@sortExpr,@tableName,@viewName, @rowCount output
		select @rowCount
		set @sTmp = 'select pt_key, pt_pricekey, pt_tourdate, pt_days,	pt_nights, pt_hdkey, pt_hdday,
							pt_hdnights, pt_hdpartnerkey, pt_rmkey,	pt_rckey, pt_chkey,	pt_chday, pt_chpkkey,
							pt_chprkey, pt_chbackkey, pt_chbackday, pt_chbackpkkey, pt_chbackprkey, null, null, null
					from ' + @tableName + '
					where ' + @sWhere

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
			if(@hotelQuotaMask > 0)
			begin
				set @tmpHotelQuota=null
				select @tmpHotelQuota=res from #checked where svkey=3 and code=@hdkey and rmkey=@rmkey and rckey=@rckey and date=@tourdate and day=@hdday and days=@hdnights and prkey=@hdprkey
				if (@tmpHotelQuota is null)
				begin
					select @places=qt_places,@allPlaces=qt_allPlaces from dbo.mwCheckQuotesEx(3,@hdkey,@rmkey,@rckey, @agentKey,@hdprkey,@tourdate,@hdday,@hdnights,@requestOnRelease,@noPlacesResult,@checkAgentQuota,@checkCommonQuota,@checkNoLongQuota,0,0,0,0,0,@expiredReleaseResult)
					set @tmpHotelQuota=ltrim(str(@places)) + ':' + ltrim(str(@allPlaces))
					insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(3,@hdkey,@rmkey,@rckey,@tourdate,@hdday,@hdnights,@hdprkey,0,@tmpHotelQuota)
				end
			end
			if(@aviaQuotaMask > 0)
			begin				
				set @tmpThereAviaQuota=null
				select @tmpThereAviaQuota=res from #checked where svkey=1 and code=@chkey and date=@tourdate and day=@chday and days=@days and prkey=@chprkey and pkkey=@chpkkey
				if (@tmpThereAviaQuota is null)
				begin
					exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @days, @expiredReleaseResult,null, @tmpThereAviaQuota output
					insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(1,@chkey,0,0,@tourdate,@chday,@days,@chprkey,@chpkkey,@tmpThereAviaQuota)
				end

				set @tmpBackAviaQuota=null
				select @tmpBackAviaQuota=res from #checked where svkey=1 and code=@chbackkey and date=@tourdate and day=@chbackday and days=@days and prkey=@chbackprkey and pkkey=@chbackpkkey
				if (@tmpBackAviaQuota is null)
				begin
					exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chbackkey, @flightGroups,@agentKey,@chbackprkey, @tourdate,@chbackday,@requestOnRelease,@noPlacesResult,@checkAgentQuota,@checkCommonQuota,@checkNoLongQuota,@findFlight,@chbackpkkey,@days,@expiredReleaseResult,null, @tmpBackAviaQuota output
					insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res) values(1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey,@tmpBackAviaQuota)
				end
			end
			update #quotaCheckTable set pt_hdquota=@tmpHotelQuota,
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

		set @sTmp = 'select t.*, ' + @sAddSelect + ' from #resultsTable t ' + @sJoin
		exec(@sTmp)
	end
	else if(len(@sKeysSelect) > 0)
		exec PagingSelect @sKeysSelect,@spageNum,@spageSize,@filter,@sortExpr,@tableName,@viewName, 1
	else
	begin
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
			priceCorrection float
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
				set @sql = @sql + ' pt_chkey, pt_chbackkey, 0, pt_chdirectkeys, pt_chbackkeys '
			else
				set @sql = @sql + ' ch_key as pt_chkey, chb_key as pt_chbackkey, row_number() over(order by ' + @sortExpr + ') as rowNum, pt_chdirectkeys, pt_chbackkeys '
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
			--и еще добавим невключающее условие по количеству предварительно просмотренных записей
			set @sql=@sql + ' and pt_key not in (select top '+@spageNum+' pt_key '

			if (@mwSearchType=0)
				set @sql=@sql + ' from mwPriceTable  with(nolock) where pt_cnkey=' + LTRIM(STR(@countryKey)) + ' and pt_ctkeyfrom=' + LTRIM(STR(@departFromKey)) + ' and ' + @filter
			else
				set @sql=@sql + ' from ' + dbo.mwGetPriceViewName (@countryKey,@departFromKey) + ' with(nolock) where ' + @filter

			if len(isnull(@sortExpr,'')) > 0
				set @sql=@sql + ' order by '+ @sortExpr
			set @sql=@sql + ') '
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
		pt_key,'

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
		set @sql=@sql + ',pt_hdquota'
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

GO

grant exec on dbo.Paging to public

GO


if not exists(select id from syscolumns where id = OBJECT_ID('mwPriceDataTable') and name = 'pt_topricefor')
	alter TABLE [dbo].[mwPriceDataTable] add [pt_topricefor] [smallint] NOT NULL DEFAULT (0)

if not exists(select id from syscolumns where id = OBJECT_ID('mwPriceDataTable') and name = 'pt_AccmdType')
	alter TABLE [dbo].[mwPriceDataTable] add [pt_AccmdType] [smallint] NULL

GO

-- 091216(mwSinglePrice_AllDepartsFrom).sql

if not exists(select ss_parmname from dbo.systemsettings where ss_parmname = 'mwSinglePriceAllDeparts')
	insert into systemsettings(ss_parmname, ss_parmvalue) values('mwSinglePriceAllDeparts', '0')
go

-- sp_mwCleaner.sql

if exists(select id from sysobjects where name='mwCleaner' and xtype='p')
	drop procedure [dbo].[mwCleaner]
go

create proc [dbo].[mwCleaner] as
begin
	delete from dbo.tp_turdates where td_date < getdate() and td_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_prices where tp_dateend < getdate() and tp_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_servicelists where tl_tikey not in (select tp_tikey from tp_prices) and tl_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_lists where ti_key not in (select tp_tikey from tp_prices) and ti_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_services where ts_key not in (select tl_tskey from tp_servicelists) and ts_tokey not in (select to_key from tp_tours where to_update <> 0)
	delete from dbo.tp_tours where to_key not in (select ti_tokey from tp_lists) and to_update = 0

	declare @mwSearchType int
	select @mwSearchType = isnull(SS_ParmValue, 1) from dbo.systemsettings with(nolock) 
	where SS_ParmName = 'MWDivideByCountry'

	if(@mwSearchType = 0)
	begin
			delete from dbo.mwPriceDataTable where pt_tourdate < getdate() and pt_tourkey not in (select to_key from tp_tours where to_update <> 0)
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
			set @sql = 'delete from ' + @objName + ' where pt_tourdate < getdate() and pt_tourkey not in (select to_key from tp_tours where to_update <> 0)'
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

-- (091217)AlterTable_DupUser.sql

if not exists(select id from syscolumns where id = OBJECT_ID('dup_user') and name = 'us_advertisement')
     alter TABLE [dbo].[dup_user] add [us_advertisement] varchar(256) NULL


-- fn_mwConcatFlightsGroupsQuotas.sql

if exists(select id from sysobjects where name='mwConcatFlightsGroupsQuotas' and xtype='fn')
	drop function [dbo].[mwConcatFlightsGroupsQuotas]
go

create function [dbo].[mwConcatFlightsGroupsQuotas](@groupQuota1 varchar(256), @groupQuota2 varchar(256))
returns varchar(256)
as
begin
	if (@groupQuota1 is null or len(@groupQuota1) = 0)
		return @groupQuota2

	declare @result varchar(256)
	set		@result = ''

	declare @curPosition1 int
		set @curPosition1 = 0
	declare @curPosition2 int
		set @curPosition2 = 0

	declare @prevPosition1 int
		set @prevPosition1 = 1
	declare @prevPosition2 int
		set @prevPosition2 = 1

	declare @emptyPlaces1 float, @allPlaces1 float
	declare @emptyPlaces2 float, @allPlaces2 float

	declare @subQuota1 varchar(50)
		set @subQuota1  = ''

	declare @subQuota2 varchar(50)
		set @subQuota2  = ''

	declare @flag smallint
		set @flag = 0

	while (charindex(',', @groupQuota1, @curPosition1 + 1) > 0 or @flag = 0)
	begin
		set @curPosition1 = charindex('|', @groupQuota1, @curPosition1 + 1)
		set @curPosition2 = charindex('|', @groupQuota2, @curPosition2 + 1)
		if (@curPosition1 = 0)
		begin
			set @subQuota1  = substring(@groupQuota1, @prevPosition1, len(@groupQuota1))
			set @curPosition1 = len(@groupQuota1)
			set @subQuota2  = substring(@groupQuota2, @prevPosition2, len(@groupQuota2))
			set @curPosition2 = len(@groupQuota2)
			set @flag = 1
		end 
		else
		begin
			set @subQuota1  = substring(@groupQuota1, @prevPosition1, @curPosition1 - @prevPosition1)
			set @subQuota2  = substring(@groupQuota2, @prevPosition2, @curPosition2 - @prevPosition2)
		end
		
		set @prevPosition1 = @curPosition1 + 1
		set @prevPosition2 = @curPosition2 + 1

		set @emptyPlaces1 = CAST(substring(@subQuota1, 0, charindex(':', @subQuota1, 0)) as float)
		set @allPlaces1 = CAST(substring(@subQuota1, charindex(':', @subQuota1, 0) + 1, len(@subQuota1) + 1 - charindex(':', @subQuota1, 0)) as float)

		set @emptyPlaces2 = CAST(substring(@subQuota2, 0, charindex(':', @subQuota2, 0)) as float)
		set @allPlaces2 = CAST(substring(@subQuota2, charindex(':', @subQuota2, 0) + 1, len(@subQuota2) + 1 - charindex(':', @subQuota2, 0)) as float)

		if (@emptyPlaces1 = 0)
			set @result = @result + @subQuota1
		else if (@emptyPlaces2 = 0)
			set @result = @result + @subQuota2
		else if (@emptyPlaces1 = -1)
			set @result = @result + @subQuota1
		else if (@emptyPlaces2 = -1)
			set @result = @result + @subQuota2
-- сделать криведение к float		
		else if (@emptyPlaces1 / @allPlaces1 < @emptyPlaces2 / @allPlaces2)
			set @result = @result + @subQuota1
		else
			set @result = @result + @subQuota2
			
		set @result = @result + '|'
	end

	return substring(@result, 1, len(@result) - 1)
end
go

grant exec on [dbo].[mwConcatFlightsGroupsQuotas] to public
go


-- shop_tour.sql

if not exists (select 1 from service where sv_name = 'Условие-ДА')
BEGIN
	declare @svKEY int
	exec getnkey 'Service', @svKEY  output
	insert into service (sv_key, sv_name, sv_namelat, sv_issubcode1, sv_issubcode2) values(@svKEY, 'Условие-ДА', 'Condition-YES', 1, 1)

	declare @a1KEY int
	exec getnkey 'AddDescript1', @a1KEY  output
	Insert into AddDescript1 (A1_KEY, A1_SVKEY, A1_NAME, A1_NAMELAT) values (@a1KEY, @svKEY, 'Выполнено', 'en_Выполнено')
	exec getnkey 'AddDescript1', @a1KEY output 
	Insert into AddDescript1 (A1_KEY, A1_SVKEY, A1_NAME, A1_NAMELAT) values (@a1KEY, @svKEY, 'Не выполнено', 'en_Не выполнено')
	exec getnkey 'AddDescript1', @a1KEY output 
	Insert into AddDescript1 (A1_KEY, A1_SVKEY, A1_NAME, A1_NAMELAT) values (@a1KEY, @svKEY, 'Не выполнено, но заплачен штраф', 'en_Не выполнено, но заплачен штраф')
END	
GO
-- Чтобы модуль заработал необходимо установить в значение этой настройки SV_KEY услуги "Условие-ДА" 
delete from  [dbo].systemsettings where ss_parmname='SYSShopTourService'
	insert into [dbo].systemsettings values('SYSShopTourService', '', null, null, null, null)
GO
/*
if not exists (select 1 from prttypes where pt_name = 'Комиссия 300 евро')
BEGIN
	declare @a2KEY int, @name varchar(50), @nameLat varchar(50)
	exec getnkey 'AddDescript2', @a2KEY  output
	set @name = 'Комиссия 300 евро'
	set @nameLat = 'en_Комиссия 300 евро'
	Insert into AddDescript2 (A2_KEY, A2_SVKEY, A2_NAME, A2_NAMELAT) values (@a2KEY, @svKEY, @name, @nameLat)
	Insert into prttypes (pt_name, pt_namelat) values (@name, @nameLat)
	
	exec getnkey 'AddDescript2', @a2KEY  output
	set @name = 'Комиссия 310 евро'
	set @nameLat = 'en_Комиссия 310 евро'
	Insert into AddDescript2 (A2_KEY, A2_SVKEY, A2_NAME, A2_NAMELAT) values (@a2KEY, @svKEY, @name, @nameLat)
	Insert into prttypes (pt_name, pt_namelat) values (@name, @nameLat)

	exec getnkey 'AddDescript2', @a2KEY  output
	set @name = 'Комиссия 320 евро'
	set @nameLat = 'en_Комиссия 320 евро'
	Insert into AddDescript2 (A2_KEY, A2_SVKEY, A2_NAME, A2_NAMELAT) values (@a2KEY, @svKEY, @name, @nameLat)
	Insert into prttypes (pt_name, pt_namelat) values (@name, @nameLat)

	exec getnkey 'AddDescript2', @a2KEY  output
	set @name = 'Комиссия 330 евро'
	set @nameLat = 'en_Комиссия 330 евро'
	Insert into AddDescript2 (A2_KEY, A2_SVKEY, A2_NAME, A2_NAMELAT) values (@a2KEY, @svKEY, @name, @nameLat)
	Insert into prttypes (pt_name, pt_namelat) values (@name, @nameLat)
	
	exec getnkey 'AddDescript2', @a2KEY  output
	set @name = 'Комиссия 340 евро'
	set @nameLat = 'en_Комиссия 340 евро'
	Insert into AddDescript2 (A2_KEY, A2_SVKEY, A2_NAME, A2_NAMELAT) values (@a2KEY, @svKEY, @name, @nameLat)
	Insert into prttypes (pt_name, pt_namelat) values (@name, @nameLat)
	
	exec getnkey 'AddDescript2', @a2KEY  output
	set @name = 'Комиссия 350 евро'
	set @nameLat = 'en_Комиссия 350 евро'
	Insert into AddDescript2 (A2_KEY, A2_SVKEY, A2_NAME, A2_NAMELAT) values (@a2KEY, @svKEY, @name, @nameLat)
	Insert into prttypes (pt_name, pt_namelat) values (@name, @nameLat)

	exec getnkey 'AddDescript2', @a2KEY  output
	set @name = 'Комиссия не определена'
	set @nameLat = 'en_Комиссия не определена'
	Insert into AddDescript2 (A2_KEY, A2_SVKEY, A2_NAME, A2_NAMELAT) values (@a2KEY, @svKEY, @name, @nameLat)
	Insert into prttypes (pt_name, pt_namelat) values (@name, @nameLat)
END
GO */

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
END
GO

-- 091221(CreateFRMConnect).sql

if not exists (select * from sysobjects where name = 'FrmConnect' and xtype = 'U')

CREATE TABLE [dbo].[FrmConnect](
	[FC_FORM] [varchar](25) NULL,
	[FC_CONNECTDATE] [datetime] NOT NULL,
	[FC_IP] [varchar](15) NULL,
	[FC_USER] [varchar](40) NULL,
	[FC_PASSWORD] [varchar](16) NULL,
	[FC_USE] [varchar](200) NULL,
	[FC_NAME] [varchar](128) NULL,
	[FC_PHONES] [varchar](128) NULL,
	[FC_EMAIL] [varchar](128) NULL,
	[FC_FIO] [varchar](30) NULL,
	[FC_ID] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_FrmConnect] PRIMARY KEY 
(
	[FC_ID] ASC
)

)

GO

grant select, update, insert, delete on [dbo].[FrmConnect] to public

GO

-- sp_GetCityDepartureKey.sql

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
		from tp_services
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





-- 091224_AlterInsteadTriggers.sql

if not exists(select 1 from dbo.SystemSettings where SS_ParmName like 'SYSTourFilialSecControl' and SS_ParmValue like '1')
begin
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfUpdateTurList]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfDeleteTurList]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfInsertTurDate ]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfInsertTurDate]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurDate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfUpdateTurDate]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurDate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfDeleteTurDate]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfDeleteTurMargin]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfUpdateTurMargin]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfInsertTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfInsertTurMargin]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurService]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfDeleteTurService]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurService]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfUpdateTurService]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfInsertTurService]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfInsertTurService]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfUpdateTurList]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfDeleteTurList]
end
go

if not exists(select 1 from dbo.SystemSettings where SS_ParmName like 'SYSCostFilialSecControl' and SS_ParmValue like '1')
begin
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteCost]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfDeleteCost]
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateCost]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
		drop trigger [dbo].[T_InsteadOfUpdateCost]
end
go

-- T_mwUpdateHotel.sql

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwUpdateHotel]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[mwUpdateHotel]
GO

CREATE TRIGGER [mwUpdateHotel] ON [dbo].[HotelDictionary] 
FOR UPDATE 
AS
IF @@ROWCOUNT > 0
begin
	if (UPDATE(HD_RSKEY) or UPDATE(HD_STARS) or UPDATE(HD_HTTP))
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
			sd_hotelurl = hd_http
		from inserted where sd_hdkey = hd_key

	end
end
GO


-- 091228(AddSetting).sql

if not exists( select 1 from dbo.SystemSettings where ss_parmname= 'SYSAllowNegativeCost' )
	insert into [dbo].SystemSettings (ss_parmname,ss_parmvalue) values ('SYSAllowNegativeCost','0')
GO

-- 091229_UpdateSynonyms.sql

update Synonyms set SY_Synonym = 'Список возможного сервиса в отелях', SY_SynonymLat = 'en_Список возможного сервиса в отелях' 
where SY_Name like 'ALLHOTELOPTION'
GO

update Synonyms set SY_Synonym = 'Расчеты с партнерами по услугам', SY_SynonymLat = 'en_Расчеты с партнерами по услугам' 
where SY_Name like 'BILLSDOGOVOR'
GO

update Synonyms set SY_Synonym = 'Вид проживания', SY_SynonymLat = 'en_Вид проживания' 
where SY_Name like 'HOTELROOMS'
GO

update Synonyms set SY_Synonym = 'Курорты', SY_SynonymLat = 'en_Курорты' 
where SY_Name like 'RESORTS'
GO

update Synonyms set SY_Synonym = 'Типы номеров', SY_SynonymLat = 'en_Типы номеров' 
where SY_Name like 'ROOMS'
GO

update Synonyms set SY_Synonym = 'Типы размещения', SY_SynonymLat = 'en_Типы размещения' 
where SY_Name like 'ROOMSCATEGORY'
GO

update Synonyms set SY_Synonym = 'Связанные услуги', SY_SynonymLat = 'en_Связанные услуги' 
where SY_Name like 'SERVICELINK'
GO

update Synonyms set SY_Synonym = 'Названия услуг', SY_SynonymLat = 'en_Названия услуг' 
where SY_Name like 'SERVICELIST'
GO

update Synonyms set SY_Synonym = 'Типы туров', SY_SynonymLat = 'en_Типы туров' 
where SY_Name like 'TIPTUR'
GO

update Synonyms set SY_Synonym = 'Даты туров', SY_SynonymLat = 'en_Даты туров' 
where SY_Name like 'TURDATE'
GO

update Synonyms set SY_Synonym = 'Туристы по услуге', SY_SynonymLat = 'en_Туристы по услуге' 
where SY_Name like 'TURISTSERVICE'
GO

update Synonyms set SY_Synonym = 'Список туров', SY_SynonymLat = 'en_Список туров'
where SY_Name like 'TURLIST'
GO

update Synonyms set SY_Synonym = 'Услуги в турах', SY_SynonymLat = 'en_Услуги в турах'
where SY_Name like 'TURSERVICE'
GO

update Synonyms set SY_Synonym = 'Транспорт', SY_SynonymLat = 'en_Транспорт'
where SY_Name like 'VEHICLE'
GO

update Synonyms set SY_Synonym = 'Схема транспорта', SY_SynonymLat = 'en_Схема транспорта'
where SY_Name like 'VEHICLEPLAN'
GO

update Synonyms set SY_Synonym = 'Профили отчетов', SY_SynonymLat = 'en_Профили отчетов'
where SY_Name like 'REP_PROFILES'
GO

update Synonyms set SY_Synonym = 'Опции профилей отчетов', SY_SynonymLat = 'en_Профили отчетов'
where SY_Name like 'REP_OPTIONS'
GO

update Synonyms set SY_Synonym = 'Список настроек отчетов', SY_SynonymLat = 'en_Список настроек отчетов'
where SY_Name like 'REP_OPTIONLIST'
GO

update Synonyms set SY_Synonym = 'Список значений настроек 2000-х отчетов', SY_SynonymLat = 'en_Список значений настроек 2000-х отчетов'
where SY_Name like 'REP_VALUELIST'
GO

update Synonyms set SY_Synonym = 'Словарь', SY_SynonymLat = 'en_Словарь'
where SY_Name like 'DICTIONARY'
GO

update Synonyms set SY_Synonym = 'Рассчитанные цены PriceList', SY_SynonymLat = 'en_Рассчитанные цены PriceList'
where SY_Name like 'PRICELIST'
GO

update Synonyms set SY_Synonym = 'Рассчитанные цены PriceList1', SY_SynonymLat = 'en_Рассчитанные цены PriceList1'
where SY_Name like 'PRICELIST1'
GO

update Synonyms set SY_Synonym = 'Рассчитанные цены PriceList2', SY_SynonymLat = 'en_Рассчитанные цены PriceList2'
where SY_Name like 'PRICELIST2'
GO

update Synonyms set SY_Synonym = 'Рассчитанные цены PriceList3', SY_SynonymLat = 'en_Рассчитанные цены PriceList3'
where SY_Name like 'PRICELIST3'
GO

update Synonyms set SY_Synonym = 'Представители', SY_SynonymLat = 'en_Представители'
where SY_Name like 'DUP_USER'
GO

update Synonyms set SY_Synonym = 'Ключи представителей', SY_SynonymLat = 'en_Ключи представителей'
where SY_Name like 'DUP_KEY_USER'
GO

update Synonyms set SY_Synonym = 'Информация о бронировании путевки', SY_SynonymLat = 'en_Информация о бронировании путевки'
where SY_Name like 'BRON_USER'
GO

update Synonyms set SY_Synonym = 'Статистика посетителям', SY_SynonymLat = 'en_Статистика посетителям'
where SY_Name like 'VISITORS'
GO

update Synonyms set SY_Synonym = 'Наценки на тур', SY_SynonymLat = 'en_Наценки на тур'
where SY_Name like 'TURMARGIN'
GO

update Synonyms set SY_Synonym = 'Списки услуг для EasyConstructora', SY_SynonymLat = 'en_Списки услуг для EasyConstructora'
where SY_Name like 'TOURSERVICELIST'
GO

update Synonyms set SY_Synonym = 'Привязка услуг для EasyConstructorа', SY_SynonymLat = 'en_Привязка услуг для EasyConstructorа'
where SY_Name like 'TOURSERVICELINK'
GO

update Synonyms set SY_Synonym = 'Привязка услуг для EasyConstructorа', SY_SynonymLat = 'en_Привязка услуг для EasyConstructorа'
where SY_Name like 'TOURSERVICELINK'
GO

update Synonyms set SY_Synonym = 'Рассчитанные цены PriceList4', SY_SynonymLat = 'en_Рассчитанные цены PriceList4'
where SY_Name like 'PRICELIST4'
GO

update Synonyms set SY_Synonym = 'Рассчитанные цены PriceList5', SY_SynonymLat = 'en_Рассчитанные цены PriceList5'
where SY_Name like 'PRICELIST5'
GO

update Synonyms set SY_Synonym = 'Таблица изображений', SY_SynonymLat = 'en_Таблица изображений'
where SY_Name like 'PICTURES'
GO

update Synonyms set SY_Synonym = 'Таблица сопоставлений', SY_SynonymLat = 'en_Таблица сопоставлений'
where SY_Name like 'MAPPINGS'
GO

update Synonyms set SY_Synonym = 'Типы описаний', SY_SynonymLat = 'en_Типы описаний'
where SY_Name like 'DESCTYPES'
GO

update Synonyms set SY_Synonym = 'Описания', SY_SynonymLat = 'en_Описания'
where SY_Name like 'DESCRIPTIONS'
GO

update Synonyms set SY_Synonym = 'Учет звонков', SY_SynonymLat = 'en_Учет звонков'
where SY_Name like 'CALLS'
GO

update Synonyms set SY_Synonym = 'Схемы размещения для зон (палуб) круизных судов и отелей', SY_SynonymLat = 'en_Схемы размещения для зон (палуб) круизных судов и отелей'
where SY_Name like 'VEHICLESCHEME'
GO

update Synonyms set SY_Synonym = 'Таблица размещений для зон круизных судов и отелей', SY_SynonymLat = 'en_Таблица размещений для зон круизных судов и отелей'
where SY_Name like 'VEHICLEAREA'
GO

update Synonyms set SY_Synonym = 'Новости на Web-сайте', SY_SynonymLat = 'en_Новости на Web-сайте'
where SY_Name like 'WWW_NEWS'
GO

update Synonyms set SY_Synonym = 'Таблица блокировки кают', SY_SynonymLat = 'en_Таблица блокировки кают'
where SY_Name like 'SCHEMEDESCRIPTIONS'
GO

update Synonyms set SY_Synonym = 'Кредитные карты', SY_SynonymLat = 'en_Кредитные карты'
where SY_Name like 'CREDITCARDS'
GO

update Synonyms set SY_Synonym = 'История занесения цен для отелей (InterLook)', SY_SynonymLat = 'en_История занесения цен для отелей (InterLook)'
where SY_Name like 'COSTSINSERTNUMBER'
GO

update Synonyms set SY_Synonym = 'Справочник статусов документов', SY_SynonymLat = 'en_Справочник статусов документов'
where SY_Name like 'DOCUMENTSTATUS'
GO

update Synonyms set SY_Synonym = 'Банки', SY_SynonymLat = 'en_Банки'
where SY_Name like 'BANKS'
GO

update Synonyms set SY_Synonym = 'Онлайн-штрафы', SY_SynonymLat = 'en_Онлайн-штрафы'
where SY_Name like 'ONLINEPENALTY'
GO

-- T_UpdDogListQuota.sql

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_UpdDogListQuota]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_UpdDogListQuota]
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
    DECLARE cur_DogovorListChanged CURSOR FOR 
    SELECT 	O.DL_Key, O.DL_DGKey,
			O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_DateBeg, O.DL_DateEnd, O.DL_NMen, O.DL_PartnerKey, O.DL_Control, 
			null, null, null, null, null, null, null, null
    FROM DELETED O
	SET @Mod = 'DEL'
END
ELSE IF (@nDelCount = 0)
BEGIN
    DECLARE cur_DogovorListChanged CURSOR FOR 
    SELECT 	N.DL_Key, N.DL_DGKey,
			null, null, null, null, null, null, null, null,
			N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_DateBeg, N.DL_DateEnd, N.DL_NMen, N.DL_PartnerKey, N.DL_Control
    FROM	INSERTED N 
	SET @Mod = 'INS'
END
ELSE 
BEGIN
    DECLARE cur_DogovorListChanged CURSOR FOR 
    SELECT 	N.DL_Key, N.DL_DGKey, 
			O.DL_SvKey, O.DL_Code, O.DL_SubCode1, O.DL_DateBeg, O.DL_DateEnd, O.DL_NMen, O.DL_PartnerKey, O.DL_Control, 
			N.DL_SvKey, N.DL_Code, N.DL_SubCode1, N.DL_DateBeg, N.DL_DateEnd, N.DL_NMen, N.DL_PartnerKey, N.DL_Control
    FROM DELETED O, INSERTED N 
    WHERE N.DL_Key = O.DL_Key
	SET @Mod = 'UPD'
END

OPEN cur_DogovorListChanged
FETCH NEXT FROM cur_DogovorListChanged 
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

	If @Mod='UPD' and (ISNULL(@O_DLControl, '') != ISNULL(@N_DLControl, ''))
	BEGIN
		If(@N_DLControl = 0)
			Update ServiceByDate set SD_State = 3 where SD_DLKey = @DLKey and SD_State = 4
	END

	--изменился период действия услуги
	IF @Mod='UPD' and (@SetToNewQuota!=1 and ((@O_DLDateBeg != @N_DLDateBeg) or (@O_DLDateEnd != @N_DLDateEnd)))
	BEGIN
		IF @N_DLDateBeg>@O_DLDateEnd OR @N_DLDateEnd<@O_DLDateBeg
		BEGIN
			DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey
			SET @SetToNewQuota=1
		END
		--для услуг имеющих продолжительность сохраняем информацию о квотировании в рамках периода
		ELSE
		BEGIN	
			IF @N_DLDateBeg<@O_DLDateBeg
			BEGIN
				IF @N_DLDateEnd<@O_DLDateBeg  --если теперь услуга заканчивается раньше, чем до этого начиналась
					Set @Days=DATEDIFF(DAY,@N_DLDateBeg,@N_DLDateEnd)+1
				ELSE
					Set @Days=DATEDIFF(DAY,@N_DLDateBeg,@O_DLDateBeg)
				INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, SD_State)
					SELECT DATEADD(DAY,NU_ID-1,@N_DLDateBeg), SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, @SVQUOTED + 3 FROM ServiceByDate,Numbers WHERE (NU_ID between 1 and @Days) and SD_Date=@O_DLDateBeg and SD_DLKey=@DLKey
			END
			IF @N_DLDateEnd>@O_DLDateEnd
			BEGIN
				IF @N_DLDateBeg>@O_DLDateEnd  --если теперь услуга начинается позже, чем до этого заканчивалась
					Set @Days=DATEDIFF(DAY,@N_DLDateBeg,@N_DLDateEnd)+1
				ELSE
					Set @Days=DATEDIFF(DAY,@O_DLDateEnd,@N_DLDateEnd)
				INSERT INTO ServiceByDate (SD_Date, SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, SD_State)
					SELECT DATEADD(DAY,-NU_ID+1,@N_DLDateEnd), SD_DLKey, SD_RLID, SD_TUKey, SD_RPID, @SVQUOTED + 3 FROM ServiceByDate,Numbers WHERE (NU_ID between 1 and @Days) and SD_Date=@O_DLDateEnd and SD_DLKey=@DLKey
			END
			IF @N_DLDateBeg>@O_DLDateBeg
				DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_Date < @N_DLDateBeg
			IF @N_DLDateEnd<@O_DLDateEnd
				DELETE FROM ServiceByDate WHERE SD_DLKey=@DLKey and SD_Date > @N_DLDateEnd
		END
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
	FETCH NEXT FROM cur_DogovorListChanged 
		INTO	@DLKey, @DGKey,
				@O_DLSVKey, @O_DLCode, @O_DLSubCode1, @O_DLDateBeg, @O_DLDateEnd, @O_DLNMen, @O_DLPartnerKey, @O_DLControl,
				@N_DLSVKey, @N_DLCode, @N_DLSubCode1, @N_DLDateBeg, @N_DLDateEnd, @N_DLNMen, @N_DLPartnerKey, @N_DLControl
END
CLOSE cur_DogovorListChanged
DEALLOCATE cur_DogovorListChanged
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

	declare @replicationSetting nvarchar(254)
	select @replicationSetting = SS_ParmValue from SystemSettings where SS_ParmName like 'SYSUseWebReplication'
	if IsNull(@replicationSetting, '0') = '1'
	begin
		update dbo.TP_Tours set TO_Update = 0, TO_Progress = 100 where TO_Key = @tokey
		return
	end

	if @tokey is null
	begin
		print 'Procedure does not support NULL param'
		return
	end

	update dbo.TP_Tours set TO_Update = 1, TO_Progress = 0 where TO_Key = @tokey

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
		[pt_tourname] [nvarchar] (128),
		[pt_pnname] [nvarchar] (30),
		[pt_pncode] [nvarchar] (3),
		[pt_rmname] [nvarchar] (60),
		[pt_rmcode] [nvarchar] (60),
		[pt_rcname] [nvarchar] (60),
		[pt_rccode] [nvarchar] (40),
		[pt_acname] [nvarchar] (30),
		[pt_accode] [nvarchar] (30),
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
		[pt_topricefor] [smallint] NOT NULL DEFAULT (0)
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
			where tp_tokey = @toKey and tp_dateend >= getdate() and tp_key not in (select pt_pricekey from mwPriceDataTable with(nolock))
	end

---=                         =---
---===                     ===---
---===========================---

	update tp_lists with(rowlock)
	set
		ti_firsthotelday = (select min(ts_day) 
				from tp_services with (nolock)
 				where ts_svkey = 3 and ts_tokey = ti_tokey)
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
	from tp_servicelists inner join tp_services on tl_tskey = ts_key and ts_svkey = 1
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
	from tp_tours 
		inner join tbl_turList on tl_key = to_trkey
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
	from tp_servicelists
		inner join tp_services on (tl_tskey = ts_key and ts_svkey = 1)
		inner join tp_tours on ts_tokey = to_key 
		inner join tbl_turList on tbl_turList.tl_key = to_trkey
	where 
		tl_tikey = ti_key 
		and ts_day > ti_lasthotelday
		and (ts_ctkey = tl_ctdeparturekey or @existBackCharter = 0)
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
	from hoteldictionary
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
		[pt_topricefor]
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
		tl_nameweb, 
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
		dbo.mwGetTourCharters(ti_key, 1),
		dbo.mwGetTourCharters(ti_key, 0),
		to_pricefor
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
		sd_hotelurl
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
		thd_hotelurl
	from #tmpHotelData 
	where thd_hdmain > 0

	if(@forceEnable > 0)
		exec dbo.mwEnablePriceTour @tokey, 1

	update dbo.TP_Tours set TO_Update = 0, TO_Progress = 100, TO_DateCreated = GetDate() where TO_Key = @tokey
end
go

grant exec on dbo.FillMasterWebSearchFields to public
go

-- sp_SetCurrencyRateManual.sql

if EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[SetCurrencyRateManual]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[SetCurrencyRateManual]
GO
CREATE PROCEDURE [dbo].[SetCurrencyRateManual]
@dogovor_code varchar(10),
@course money
as
begin
	declare @sHI_WHO varchar(25)
	exec dbo.CurrentUser @sHI_WHO output

	declare @currency varchar(10)
	select @currency = DG_RATE from tbl_dogovor where DG_CODE = @dogovor_code

	insert into dbo.history
	(HI_DGCOD, HI_WHO, HI_TEXT, HI_REMARK, HI_MOD, HI_TYPE, HI_OAId)
	values
	(@dogovor_code, @sHI_WHO, cast(@course as nvarchar(25)), @currency, 'UPD', 'DG_COURSEEDIT', 20)

	UPDATE tbl_dogovor SET DG_NATIONALCURRENCYPRICE = DG_PRICE * @course, DG_NATIONALCURRENCYDISCOUNTSUM = DG_DISCOUNTSUM*@course
	WHERE DG_CODE = @dogovor_code
end
GO
GRANT EXECUTE ON [dbo].[SetCurrencyRateManual] TO Public
GO






-- 091105_AlterConstraints.sql

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfUpdateTurList]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfDeleteTurList]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfInsertTurDate ]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfInsertTurDate]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurDate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfUpdateTurDate]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurDate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfDeleteTurDate]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfDeleteTurMargin]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfUpdateTurMargin]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfInsertTurMargin]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfInsertTurMargin]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurService]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfDeleteTurService]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurService]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfUpdateTurService]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfInsertTurService]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfInsertTurService]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfUpdateTurList]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteTurList]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfDeleteTurList]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfDeleteCost]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfDeleteCost]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_InsteadOfUpdateCost]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
	drop trigger [dbo].[T_InsteadOfUpdateCost]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[TD_TRKEY]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
	ALTER TABLE dbo.TurDate DROP CONSTRAINT [TD_TRKEY]
GO
ALTER TABLE dbo.TurDate WITH CHECK ADD CONSTRAINT [TD_TRKEY] FOREIGN KEY([TD_TRKEY])
REFERENCES [dbo].[tbl_TurList] ([TL_KEY]) ON DELETE CASCADE
GO

if exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[TD_TRKEY]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
	ALTER TABLE dbo.TurService DROP CONSTRAINT [TS_SVKEY]
GO
ALTER TABLE [dbo].[TurService]  WITH NOCHECK ADD  CONSTRAINT [TS_SVKEY] FOREIGN KEY([TS_SVKEY])
REFERENCES [dbo].[Service] ([SV_KEY])
GO

if exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[TS_TRKEY]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
	ALTER TABLE dbo.TurService DROP CONSTRAINT [TS_TRKEY]
GO
ALTER TABLE [dbo].[TurService]  WITH NOCHECK ADD  CONSTRAINT [TS_TRKEY] FOREIGN KEY([TS_TRKEY])
REFERENCES [dbo].[tbl_TurList] ([TL_KEY]) ON DELETE CASCADE
GO

if exists(select * from dbo.sysobjects where id = object_id(N'[dbo].[FK__TURMARGIN__TM_Tl__11564BB9]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
	ALTER TABLE dbo.TurMargin DROP CONSTRAINT [FK__TURMARGIN__TM_Tl__11564BB9]
GO
ALTER TABLE [dbo].[TURMARGIN]  WITH NOCHECK ADD  CONSTRAINT [FK__TURMARGIN__TM_Tl__11564BB9] FOREIGN KEY([TM_TlKey])
REFERENCES [dbo].[tbl_TurList] ([TL_KEY]) ON DELETE CASCADE
GO

-- mwCheckQuotesEx.sql

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mwCheckQuotesEx]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[mwCheckQuotesEx]
GO

CREATE FUNCTION [dbo].[mwCheckQuotesEx]
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
					end

					if(@dateRes = 0 /* and (@stopSale <= 0 or ((@prevSubCode1 = @qtSubcode1 and @prevSubCode2 = @qtSubcode2) or @prevQtType <> @qtType)) */ and isnull(@qtStop, 0) = 0 and not(@agentKey > 0 and @qtAgent = 0 and @wasAgentQuota > 0 and (@checkCommonQuotes <= 0))
								and not(@long > 0 and @qtLong = 0 and @wasLongQuota > 0 and (@checkNoLongQuotes <= 0)))
					begin
						if(@qtRelease is null or datediff(day, @currentDate, @qtDate) > isnull(@qtRelease, 0))
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
							if(@qtPlaces > 0)
								set @dateRes = @expiredReleaseResult -- no or request (0 or -1)
							else
							begin
								set @dateRes = 0 -- stop sale
							end
						end
						set @bycheckinRes = 0

						set @stopSale = 0
					end
					else if(@dateRes = 0 and @checkNoLongQuotes <> @ALLDAYS_CHECK)
					begin
						close qCur
						deallocate qCur
						insert into @tmpResQuotes(qt_svkey, qt_code, qt_subcode1, qt_subcode2, qt_agent,
							qt_prkey, qt_bycheckin, qt_byroom, qt_places, qt_allPlaces, qt_type, qt_long)
						values(0, 0, 0, 0, 0, 0, 0, 0, case when @stopSale > 0 then 0 else @noPlacesResult end, 0, 0, 0)
						return 
					end

					if(@wasAgentQuota <= 0 and @qtAgent > 0) -- признак того, что агентская квота заведена, но закончилась
						set @wasAgentQuota = 1
					if(@wasLongQuota <= 0 and @qtLong > 0)  -- признак того, что квота на продолжительность заведена, но закончилась
						set @wasLongQuota = 1
				end

				
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

GRANT SELECT ON [dbo].[mwCheckQuotesEx] TO PUBLIC
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
		select @mwSinglePriceAllDeparts = ltrim(isnull(ss_parmvalue, N'0'))
		from dbo.SystemSettings
		where ss_parmname = 'mwSinglePriceAllDeparts' -- single price for depart from
	end

	declare @sql nvarchar(4000)
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

		if(@mwSinglePrice != '0')
		begin
			if(@enabled > 0 and @mwSinglePriceAllTours != '0') -- turn the tour on
			begin	
				-- disable all prices for main places that greater than new prices (setting = min) or
				-- than are more old than new prices (setting = last)


					set @sql = '
			update ' + @tableName + ' with(rowlock) 
			set pt_isenabled = 0
			where
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
						set @sql = @sql + ' and
				' + @tableName + '.pt_hdpartnerkey = tweb.pt_hdpartnerkey'		
					
					if(@mwSinglePriceAllFlightPrt = '0') -- single price for flight partner
						set @sql = @sql + ' and
				' + @tableName + '.pt_chprkey = tweb.pt_chprkey'

					if(@mwSinglePriceAllTourTypes = '0') -- single price for tour type
						set @sql = @sql + ' and
				' + @tableName + '.pt_tourtype = tweb.pt_tourtype'

					if(@mwSinglePriceAllDeparts = '0') -- single price for departfrom
						set @sql = @sql + ' and
				' + @tableName + '.pt_ctkeyfrom = tweb.pt_ctkeyfrom'

					if(@mwSinglePriceType = 'min')
						set @sql = @sql + ' and
				' + @tableName + '.pt_price > tweb.pt_price'
					
				set @sql = @sql + ')'

					if(@mwSinglePriceAllTours = '0')
						set @sql = @sql + ' and
				' + @tableName + '.pt_tourkey = ' + ltrim(str(@tourkey))
					else
						set @sql = @sql + ' and
				' + @tableName + '.pt_tourkey != '+ ltrim(str(@tourkey))
					
--					print @sql
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
--		print @sql
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
--				print @sql
				exec(@sql)
			end
		end
	end

	update dbo.mwSpoDataTable
	set sd_isenabled = 0
	where not exists(select 1 from dbo.mwPriceTable
		where pt_cnkey = sd_cnkey
			and pt_ctkeyfrom = sd_ctkeyfrom
			and pt_tourkey = sd_tourkey
			and pt_hdkey = sd_hdkey
			and pt_pnkey = sd_pnkey)

	update dbo.mwSpoDataTable set sd_isenabled = @enabled where sd_tourkey = @tourkey	
end
go

grant exec on dbo.mwEnablePriceTour to public
go

-- T_ServiceByDateChanged.sql

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


-- 170109(CreateTable_QuotedState).sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[QuotedState]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
CREATE TABLE [dbo].[QuotedState](
	[QS_ID] [int] IDENTITY(1,1) NOT NULL,
	[QS_DLID] [int] NOT NULL,
	[QS_TUID] [int] NULL,
	[QS_STATE] [smallint] NOT NULL,
	[QS_LASTUPDATE] [datetime] NOT NULL CONSTRAINT [DF_QuotedState_QS_LASTUPDATE]  DEFAULT (getdate()),
 CONSTRAINT [PK_QuotedState] PRIMARY KEY CLUSTERED 
(
	[QS_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

-- T_QuotedStateUpdate.sql

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[T_QuotedStateUpdate]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[T_QuotedStateUpdate]
GO

CREATE TRIGGER [dbo].[T_QuotedStateUpdate]
ON [dbo].[QuotedState]
FOR UPDATE, INSERT, DELETE
AS
IF @@ROWCOUNT > 0
BEGIN
--<VERSION>2009.2.6</VERSION>
--<DATE>2010-01-17</DATE>

DECLARE @N_QS_DLID int, @N_QS_TUID int, @N_QS_State smallint,
		@O_QS_DLID int, @O_QS_TUID int, @O_QS_State smallint,
		@QSID int, @nDelCount smallint, @nInsCount smallint
		
DECLARE @sMod varchar(3), @nHIID int, @sDGCode varchar(10), @nDGKey int, @sDLName varchar(150), @sTemp varchar(25), 
		@sTemp2 varchar(255), @sTuristName varchar(55)
DECLARE @sOldValue varchar(255), @sNewValue varchar(255), @nOldValue int, @nNewValue int

SELECT @nDelCount = COUNT(*) FROM DELETED
SELECT @nInsCount = COUNT(*) FROM INSERTED
IF (@nInsCount = 0)
BEGIN
    DECLARE cur_QuotedStateChanged CURSOR FOR 
    SELECT 	O.QS_ID,
			O.QS_DLID, O.QS_TUID, O.QS_State,
			null, null, null
    FROM DELETED O
END
ELSE IF (@nDelCount = 0)
BEGIN
    DECLARE cur_QuotedStateChanged CURSOR FOR 
    SELECT 	N.QS_ID,
			null, null, null,
			N.QS_DLID, N.QS_TUID, N.QS_State
    FROM	INSERTED N
END
ELSE 
BEGIN
    DECLARE cur_QuotedStateChanged CURSOR FOR 
    SELECT 	N.QS_ID,
			O.QS_DLID, O.QS_TUID, O.QS_State,
	  		N.QS_DLID, N.QS_TUID, N.QS_State
    FROM DELETED O, INSERTED N
    WHERE N.QS_ID = O.QS_ID
END
OPEN cur_QuotedStateChanged
FETCH NEXT FROM cur_QuotedStateChanged 
	INTO @QSID, @O_QS_DLID, @O_QS_TUID, @O_QS_State,
				@N_QS_DLID, @N_QS_TUID, @N_QS_State

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF ISNULL(@O_QS_STATE,0)!=ISNULL(@N_QS_STATE,0)
		BEGIN
			SELECT @sDGCode = DL_DGCod, @nDGKey = DL_DGKey, @sDLName = DL_Name FROM DogovorList WHERE DL_KEY = @N_QS_DLID
			SELECT @sTuristName = TU_NAMERUS + ' ' + TU_FNAMERUS + ' ' + ISNULL(TU_SNAMERUS, '') FROM Turist WHERE TU_KEY = @N_QS_TUID
			set @sTemp2 = rtrim(ltrim(@sDLName)) + ', ' + @sTuristName

			if (@sTemp2 is not null)		
			begin
				set @sMod = 'UPD'
				EXEC @nHIID = dbo.InsHistory @sDGCode, @nDGKey, 19, @QSID, @sMod, @sTemp2, '', 0, ''
			
				SET @nOldValue = @O_QS_State
				SET @nNewValue = @N_QS_State

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
		IF ISNULL(@O_QS_TUID,0)!=ISNULL(@N_QS_TUID,0)
		BEGIN
			IF (@N_QS_TUID is not null)
			BEGIN
				SELECT @sDGCode = DL_DGCod, @nDGKey = DL_DGKey, @sDLName = DL_Name FROM DogovorList WHERE DL_KEY = @N_QS_DLID
				SELECT @sTuristName = TU_NAMERUS + ' ' + TU_FNAMERUS + ' ' + ISNULL(TU_SNAMERUS, '') FROM Turist WHERE TU_KEY = @N_QS_TUID
				set @sTemp2 = rtrim(ltrim(@sDLName)) + ', ' + @sTuristName
				set @sMod = 'INS'
			END
			ELSE
			BEGIN
				SELECT @sDGCode = DL_DGCod, @nDGKey = DL_DGKey, @sDLName = DL_Name FROM DogovorList WHERE DL_KEY = @O_QS_DLID
				SELECT @sTuristName = TU_NAMERUS + ' ' + TU_FNAMERUS + ' ' + ISNULL(TU_SNAMERUS, '') FROM Turist WHERE TU_KEY = @O_QS_TUID
				set @sTemp2 = rtrim(ltrim(@sDLName)) + ', ' + @sTuristName
				set @sMod = 'DEL'
			END

			if (@sTemp2 is not null)
			BEGIN
				EXEC @nHIID = dbo.InsHistory @sDGCode, @nDGKey, 19, @QSID, @sMod, @sTemp2, @sTemp, 0, ''

				SET @nOldValue = @O_QS_State
				SET @nNewValue = @N_QS_State

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

	FETCH NEXT FROM cur_QuotedStateChanged 
		INTO @QSID, @O_QS_DLID, @O_QS_TUID, @O_QS_State,
					@N_QS_DLID, @N_QS_TUID, @N_QS_State
	END
	CLOSE cur_QuotedStateChanged
	DEALLOCATE cur_QuotedStateChanged
END
GO

-- 092001(update_systemsettings).sql

update systemsettings set ss_parmvalue = 1 where ss_parmname='SYSServiceStatusToHistory'
GO

-- 091215AddSettings.sql

if not exists( select 1 from dbo.SystemSettings where ss_parmname= 'SYSAlwaysRecalcNational' )
insert into [dbo].SystemSettings (ss_parmname,ss_parmvalue) values 
('SYSAlwaysRecalcNational','0')
GO

-- 100121(mwSinglePrice).sql

if exists(select 1 from sysindexes where id = object_id('dbo.mwPriceDataTable') and name = 'x_singleprice')
	drop index mwPriceDataTable.x_singleprice
go

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
pt_ctkeyfrom)

go

if exists(select 1 from sysindexes where id = object_id('dbo.mwPriceDataTable') and name = 'x_singleprice_tour')
	drop index mwPriceDataTable.x_singleprice_tour
go

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

go

-- 20100122(AlterTable_Turist).sql 

if not exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[tbl_Turist]') and name = 'TU_EMAIL')
	alter table dbo.tbl_Turist add TU_EMAIL varchar(50)
GO

exec sp_refreshviewforall 'Turist'
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

--Изменение версии

update [dbo].[setting] set st_version = '9.2.6', st_moduledate = convert(datetime, '2010-01-22', 120),  st_financeversion = '9.2.6', st_financedate = convert(datetime, '2010-01-22', 120)
GO
UPDATE dbo.SystemSettings SET SS_ParmValue='2010-01-22' WHERE SS_ParmName='SYSScriptDate'
GO