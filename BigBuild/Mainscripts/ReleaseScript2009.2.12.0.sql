/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*%%%%%%%%%% Дата формирования: 17.02.2012 15:11 Для поисковой: False %%%%%%%%%%%%*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

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
/* begin (2012.01.23)_Drop_table_PartnersNetworks.sql */
/*********************************************************************/

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FX_PR_PNKEY]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_Partners]'))
ALTER TABLE [dbo].[tbl_Partners] DROP CONSTRAINT [FX_PR_PNKEY]
GO

IF  EXISTS (SELECT * FROM sys.columns c WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Partners]') AND name = N'PR_PNKEY')
ALTER TABLE [dbo].[tbl_Partners] DROP COLUMN PR_PNKEY
go

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FX_PN_MAINPRID]') AND parent_object_id = OBJECT_ID(N'[dbo].[PartnersNetworks]'))
ALTER TABLE [dbo].[PartnersNetworks] DROP CONSTRAINT [FX_PN_MAINPRID]
GO


GO

/****** Object:  Table [dbo].[PartnersNetworks]    Script Date: 01/23/2012 16:24:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PartnersNetworks]') AND type in (N'U'))
DROP TABLE [dbo].[PartnersNetworks]
GO

sp_RefreshViewForAll 'Partners'
GO
/*********************************************************************/
/* end (2012.01.23)_Drop_table_PartnersNetworks.sql */
/*********************************************************************/

/*********************************************************************/
/* begin 20111221_AlterTable_WebServiceLog.sql */
/*********************************************************************/
--<VERSION>ALL</VERSION>
--<DATE>2012-01-26</DATE>

IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'webservicelog')  
      create table dbo.Webservicelog (name nvarchar(50), date datetime  DEFAULT  GETDATE(), host nvarchar(15),Duration float,Params nvarchar(1024))
IF NOT EXISTS(SELECT id FROM syscolumns WHERE id = OBJECT_ID('webservicelog') AND name = 'UserName')
      ALTER TABLE dbo.Webservicelog ADD UserName nvarchar(60) NULL

GRANT INSERT ON [dbo].[Webservicelog] TO [public]
GO
GRANT REFERENCES ON [dbo].[Webservicelog] TO [public]
GO
GRANT SELECT ON [dbo].[Webservicelog] TO [public]
GO
GRANT UPDATE ON [dbo].[Webservicelog] TO [public]
GO
GRANT DELETE ON [dbo].[Webservicelog] TO [public]
GO
GRANT VIEW DEFINITION ON [dbo].[Webservicelog] TO [public]
GO

-- if webservicelog table exists in non-dbo schema,
-- then create same table in dbo schema, fill data to it and drop
-- non-dbo schema table
IF EXISTS(SELECT * 
			FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'webservicelog'
				AND TABLE_SCHEMA <> 'dbo')
BEGIN

	print 'webservicelog processing...'

	declare @otherSchema as nvarchar(50)
	SELECT top 1 @otherSchema = TABLE_SCHEMA 
			FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'webservicelog'
				AND TABLE_SCHEMA <> 'dbo'
				
	declare @sql as nvarchar(max)
	set @sql = '
				INSERT INTO dbo.webservicelog 
				SELECT * from ' + @otherSchema + '.webservicelog 
				'
	
	set @sql = @sql + '
				DROP TABLE ' + @otherSchema + '.webservicelog 
				'
	
	exec (@sql)
	
	print 'webservicelog processing complete'

END 

GO
/*********************************************************************/
/* end 20111221_AlterTable_WebServiceLog.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCheckQuotesCycle.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwCheckQuotesCycle')
	drop proc dbo.mwCheckQuotesCycle
go

create procedure [dbo].[mwCheckQuotesCycle]
--<VERSION>ALL</VERSION>
--<DATE>2012-02-07</DATE>
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

	-- Golubinsky. 15.12.2011. Переменная, сохраняющая начальное значение параметра @findFlight
	-- для установки в начале каждой итерации и до поиска обратного перелета, чтобы не учитывался результат предыдущей итерации
	declare @initialFindflight as int
	set @initialFindflight = @findFlight

	while(@@fetch_status=0 and @selected < @pageSize)
	begin
	
		set @findFlight = @initialFindflight 
	
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
					set @findFlight = @initialFindflight 
					
					--kadraliev MEG00025990 03.11.2010 Если в туре запрещено менять рейс, устанавливаем @findFlight = 0
					exec [dbo].[mwGetServiceIsEditableAttribute] 1, @pttourkey, @chkey, @chday, @isEditableService output
					if (@isEditableService = 0)
							set @findFlight = 0
					
					select @tmpThereAviaQuota=res from #checked where svkey=1 and code=@chkey and date=@tourdate 
										and day=@chday and days=@days and prkey=@chprkey and pkkey=@chpkkey
										and find_flight = @findFlight
					if (@tmpThereAviaQuota is null)
					begin		
								
						exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chkey, @flightGroups, @agentKey, @chprkey, @tourdate, @chday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpThereAviaQuota output, @chbackday
						
						insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res, find_flight) 
							values(1,@chkey,0,0,@tourdate,@chday,@days,@chprkey, @chpkkey, @tmpThereAviaQuota, @findFlight)
					end		
								
					if(len(@tmpThereAviaQuota)=0)
						set @actual=0
						
					set @findFlight = @initialFindflight
						
				end
				if(@actual > 0)
				begin
					set @tmpBackAviaQuota=null
					if(@chbackkey > 0)
					begin
						set @findFlight = @initialFindflight 
						--karimbaeva MEG00038768 17.11.2011 получаем редактируемый атрибут услуги
						exec [dbo].[mwGetServiceIsEditableAttribute] 1, @pttourkey, @chbackkey, @chbackday, @isEditableService output
						if (@isEditableService = 0)
							set @findFlight = 0
												
						select @tmpBackAviaQuota=res from #checked where svkey=1 and code=@chbackkey and date=@tourdate 
										and day=@chbackday and days=@days and prkey=@chbackprkey and pkkey=@chbackpkkey
										and find_flight = @findFlight
						
						if (@tmpBackAviaQuota is null)
						begin

							exec dbo.mwCheckFlightGroupsQuotes @pagingType, @chbackkey, @flightGroups, @agentKey, @chbackprkey, @tourdate,@chbackday, @requestOnRelease, @noPlacesResult, @checkAgentQuota, @checkCommonQuota, @checkNoLongQuota, @findFlight, @chbackpkkey, @days, @expiredReleaseResult, @aviaQuotaMask, @tmpBackAviaQuota output, @chday
							insert into #checked(svkey,code,rmkey,rckey,date,day,days,prkey,pkkey,res, find_flight) 
								values(1,@chbackkey,0,0,@tourdate,@chbackday,@days,@chbackprkey,@chbackpkkey, @tmpBackAviaQuota, @findFlight)
						end

						if(len(@tmpBackAviaQuota)=0)
							set @actual=0
							
						set @findFlight = @initialFindflight
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
/* begin CREATE_XML_SCHEMA_ArrayOfInt.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.xml_schema_collections c, sys.schemas s WHERE c.schema_id = s.schema_id AND (quotename(s.name) + '.' + quotename(c.name)) = N'[dbo].[ArrayOfInt]')
begin
	CREATE XML SCHEMA COLLECTION [dbo].[ArrayOfInt] AS 
	N'<?xml version="1.0" encoding="utf-16"?>
	<xs:schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" attributeFormDefault="unqualified" elementFormDefault="qualified">
	  <xsd:element name="ArrayOfInt">
		<xsd:complexType>
		  <xsd:sequence>
			<xsd:element maxOccurs="unbounded" name="int" type="xsd:unsignedShort" />
		  </xsd:sequence>
		</xsd:complexType>
	  </xsd:element>
	</xs:schema>'
end
GO

grant exec on xml schema collection::[dbo].[ArrayOfInt] to public
go
/*********************************************************************/
/* end CREATE_XML_SCHEMA_ArrayOfInt.sql */
/*********************************************************************/

/*********************************************************************/
/* begin CREATE_XML_SCHEMA_ArrayOfShort.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.xml_schema_collections c, sys.schemas s WHERE c.schema_id = s.schema_id AND (quotename(s.name) + '.' + quotename(c.name)) = N'[dbo].[ArrayOfShort]')
begin
	CREATE XML SCHEMA COLLECTION [dbo].[ArrayOfShort] AS 
	N'<?xml version="1.0" encoding="utf-16"?>
	<xs:schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" attributeFormDefault="unqualified" elementFormDefault="qualified">
	  <xsd:element name="ArrayOfShort">
		<xsd:complexType>
		  <xsd:sequence>
			<xsd:element maxOccurs="unbounded" name="short" type="xsd:unsignedShort" />
		  </xsd:sequence>
		</xsd:complexType>
	  </xsd:element>
	</xs:schema>'
end
GO

grant exec on xml schema collection::[dbo].[ArrayOfShort] to public
go
/*********************************************************************/
/* end CREATE_XML_SCHEMA_ArrayOfShort.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_BindBranchesToTour.sql */
/*********************************************************************/
--<VERSION>ALL</VERSION>
--<DATE>2012-02-15</DATE>

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[BindBranchesToTour]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[BindBranchesToTour] 
GO

CREATE PROCEDURE BindBranchesToTour
	@CountryKey int,
	@DepartureCityKey int,
	@TourKey int,
	@Branches xml ([dbo].[ArrayOfInt])	-- MEG00036888. 15.02.2012. Golubinsky. Переделал с Table valued parameter на 
										-- xml schema collection для поддержки в SQL Server 2005
AS
BEGIN
	DELETE TourFilial
	FROM TourFilial
	JOIN tbl_TurList ON TF_TLKEY = TL_KEY
	WHERE (TL_CTDepartureKey = @DepartureCityKey OR @DepartureCityKey IS NULL)
	  AND (TL_CNKEY = @CountryKey OR @CountryKey IS NULL)
	  AND (TL_KEY = @TourKey OR @TourKey IS NULL)	 

	INSERT INTO TourFilial(TF_PRKEY, TF_TLKEY)
	SELECT DISTINCT b.value, 0
	FROM (select tbl.res.value('.', 'int') as value 
			from @Branches.nodes('/ArrayOfInt/int') as tbl(res)) as b
	CROSS JOIN tbl_TurList t
	WHERE (TL_CTDepartureKey = @DepartureCityKey OR @DepartureCityKey IS NULL)
	  AND (TL_CNKEY = @CountryKey OR @CountryKey IS NULL)
	  AND (t.TL_KEY = @TourKey OR @TourKey IS NULL)
	  AND NOT EXISTS(SELECT 1 FROM TourFilial WHERE TF_PRKEY = b.value AND TF_TLKEY = t.TL_KEY)	  
END
GO

GRANT EXEC ON [dbo].[BindBranchesToTour] TO PUBLIC
GO
/*********************************************************************/
/* end sp_BindBranchesToTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_GetPrtTypesSortedNumbersLast.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_GetPrtTypesSortedNumbersLast]') and type = 'TF')
	drop function [dbo].[fn_GetPrtTypesSortedNumbersLast]
GO

--Сортирует признаки партнеров по алфавиту, при этом начинающиеся с цифры выводятся в конце
CREATE FUNCTION [dbo].[fn_GetPrtTypesSortedNumbersLast]()
--<VERSION>2007.2.40</VERSION>
--<DATE>16.11.2011</DATE>	
returns @t1 TABLE (PT_Id int, PT_Name varchar(100))
AS

BEGIN
	
	INSERT INTO @t1
		Select PT_Id, PT_Name 
		from PrtTypes
		where PT_Name not like '[0-9]%' order by PT_Name
	INSERT INTO @t1
		Select PT_Id, PT_Name 
		from PrtTypes
		where PT_Name like '[0-9]%' order by PT_Name
	return
	
END;

GO

grant select on fn_GetPrtTypesSortedNumbersLast to public
go
/*********************************************************************/
/* end fn_GetPrtTypesSortedNumbersLast.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwReplDeletePriceTour.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwReplDeletePriceTour')
	drop proc dbo.[mwReplDeletePriceTour]
go

create proc [dbo].[mwReplDeletePriceTour] @tokey int, @rqId int
as
begin
	declare @mwSearchType int
	select @mwSearchType = ltrim(rtrim(isnull(SS_ParmValue, ''))) from dbo.systemsettings 
		where SS_ParmName = 'MWDivideByCountry'

	if @mwSearchType = 0
	begin
		if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start insert into mwDeleted.'
		
		insert into mwDeleted with(rowlock) (del_key) 
			select pt_pricekey 
			from mwPriceDataTable with(nolock) 
			where pt_tourkey = @tokey

		if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwPriceDataTable.'
								
		update mwPriceDataTable with(rowlock) 
		set pt_isenabled = 0 
		where pt_isenabled > 0 and pt_tourkey = @tokey
	end
	else
	begin
		declare @tablename varchar(100), @sql varchar(8000)
		declare dCur cursor for select name from sysobjects with(nolock) where name like 'mwPriceDataTable%' and xtype = 'u'
		open dCur

		if (@rqId is not null)
			insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start insert into mwDeleted and update mwPriceDataTables.'

		fetch next from dCur into @tablename

		while (@@fetch_status=0)
		begin
			set @sql = 'insert into mwDeleted with(rowlock) (del_key) 
				select pt_pricekey 
				from ' + @tableName + ' with(nolock) 
				where pt_tourkey = ' + ltrim(str(@tokey))
			exec (@sql)

			set @sql = 'update ' + @tableName + ' with(rowlock) 
				set pt_isenabled = 0 
				where pt_isenabled > 0 and pt_tourkey = ' + ltrim(str(@tokey))
			exec (@sql)

			fetch next from dCur into @tablename
		end

		close dCur
		deallocate dCur
	end
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start update mwSpoDataTable.'
			
	update mwSpoDataTable with(rowlock) 
	set sd_isenabled = 0 
	where sd_isenabled > 0 and sd_tourkey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_Prices.'
	delete from TP_Prices with(rowlock) where tp_tokey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_ServiceLists.'
	delete from TP_ServiceLists with(rowlock) where tl_tokey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_Services.'
	delete from TP_Services with(rowlock) where ts_tokey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_Lists.'
	delete from TP_Lists with(rowlock) where ti_tokey = @tokey
	
	if (@rqId is not null)
		insert into mwReplQueueHistory([rqh_rqid], [rqh_text]) select @rqId, 'Start delete from TP_Tours.'
	delete from TP_Tours with(rowlock) where to_key = @tokey
end
GO

grant exec on [dbo].[mwReplDeletePriceTour] to public
GO
/*********************************************************************/
/* end sp_mwReplDeletePriceTour.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwGetServiceIsEditableAttribute.sql */
/*********************************************************************/
if exists(select id from sysobjects where xtype='p' and name='mwGetServiceIsEditableAttribute')
	drop proc dbo.mwGetServiceIsEditableAttribute
go

create procedure [dbo].[mwGetServiceIsEditableAttribute]
--<VERSION>2007.2.41.3</VERSION>
--<DATE>2011-11-17</DATE>
	@tssvkey int,
	@tokey int,
	@tscode int,
	@tsday int,
	@isEditable bit output

as
begin	
	declare @editableCode int
	set @editableCode = 2
	
	declare @path varchar(50)
	set @path = case dbo.mwReplIsSubscriber() 
					when 1 then 'mt.' + dbo.mwReplPublisherDB() + '.'
					else ''
				end

	declare @sql varchar(4000)
	set @sql ='declare @tmp bit				
				select @tmp=1 from ' + @path + 'dbo.tp_services
				where ts_svkey= '+ltrim(rtrim(str(@tssvkey)))
				+ ' and ts_tokey= '+ltrim(rtrim(str(@tokey)))
				+ ' and ts_code='+ltrim(rtrim(str(@tscode)))
				+ ' and ts_day='+ltrim(rtrim(str(@tsday)))
				+ 'and (ts_attribute&+'+ltrim(rtrim(str(@editableCode)))+')='+ltrim(rtrim(str(@editableCode)))	
	
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
/* begin fn_mwReplPublisherDB.sql */
/*********************************************************************/
if object_id('dbo.mwReplPublisherDB', 'fn') is not null
	drop function dbo.mwReplPublisherDB
go

create function dbo.mwReplPublisherDB()
returns varchar (254)
as
begin
	--возвращаем имя базы с первого поискового сервера, будем считать на остальных серверах данные одинаковые
	declare @repl_setting varchar(254)

	select @repl_setting = lower(isnull(ss_parmvalue, ''))
	from SystemSettings with(nolock)
	where ss_parmname = 'mwReplPublisherDB'

	if @repl_setting is null
	begin
		set @repl_setting = ''
	end
	
	return @repl_setting
end
go

grant exec on dbo.mwReplPublisherDB to public
go
/*********************************************************************/
/* end fn_mwReplPublisherDB.sql */
/*********************************************************************/

/*********************************************************************/
/* begin fn_mwReplSubscriberDB.sql */
/*********************************************************************/
if object_id('dbo.mwReplSubscriberDB', 'fn') is not null
	drop function dbo.mwReplSubscriberDB
go

create function dbo.mwReplSubscriberDB()
returns varchar (254)
as
begin
	--возвращает имя базы с первого поискового сервера, будем считать на остальных серверах данные одинаковые
	declare @repl_setting varchar(254)
	
	select @repl_setting = lower(isnull(ss_parmvalue, ''))
	from SystemSettings with(nolock)
	where ss_parmname = 'MWReplSubscriberDB'
	
	if @repl_setting is null
	begin
		set @repl_setting = ''
	end

	return @repl_setting
end
go

grant exec on dbo.mwReplSubscriberDB to public
go
/*********************************************************************/
/* end fn_mwReplSubscriberDB.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.01.16)_Alter_Table_Costs.sql */
/*********************************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPOTypes]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[SPOTypes](
	[ST_Id] [int] NOT NULL,
	[ST_Name] [nvarchar](20) NOT NULL,
	[ST_NameLat] [nvarchar](20) NOT NULL,
	CONSTRAINT [PK_SPOType] PRIMARY KEY CLUSTERED 
	(
		[ST_Id] ASC
	)
	) ON [PRIMARY]
	
	--values for SPOTypes
	insert into SPOTypes (ST_Id, ST_Name, ST_NameLat) values (0, 'Ordinary', 'Базовые')
	insert into SPOTypes (ST_Id, ST_Name, ST_NameLat) values (1, 'SPO', 'СПО')
END
GO

-- create table Seasons
if not exists (select * from sysobjects where id = object_id(N'[dbo].[Seasons]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
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

if not exists(select * from Seasons where SN_Id = 0)
begin
	SET IDENTITY_INSERT [dbo].[Seasons] ON	
	insert into [dbo].[Seasons] (SN_Id, SN_Name, SN_NameLat, SN_IsActive) values(0, '<All>', '<All>', 0)
	SET IDENTITY_INSERT [dbo].[Seasons] OFF
end
GO
--rights for Seasons
grant select, update, insert, delete on dbo.Seasons to public
go

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CostOffers]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
begin
	CREATE TABLE [dbo].[CostOffers](
		[CO_Id] [int] IDENTITY(1,1) NOT NULL,
		[CO_PKKey] [int] NOT NULL,
		[CO_PartnerKey] [int] NOT NULL CONSTRAINT FK_CostOffers_Partners REFERENCES tbl_Partners(PR_KEY),
		[CO_SVKey] [int] NOT NULL,
		[CO_Name] [nvarchar](255) NOT NULL,
		[CO_Code] [nvarchar](255) NOT NULL,
		[CO_Description] [nvarchar](255) NOT NULL default(''),
		[CO_SaleDateBeg] [smalldatetime] NULL,
		[CO_SaleDateEnd] [smalldatetime] NULL,
		[CO_SPOTypeId] [int] NOT NULL,
		[CO_SeasonId] [int] NOT NULL,
		[CO_CreateDate] [datetime] NOT NULL CONSTRAINT [DF_CostOffers_CreateDate]  DEFAULT (getdate()),
		[CO_Comment] [nvarchar](1024) NULL,
		[CO_IsActive] [bit] NOT NULL CONSTRAINT [DF_CostOffers_Active] DEFAULT((0)),
		[CO_IsRules] [bit] NOT NULL CONSTRAINT [DF_CostOffers_IsRules]  DEFAULT ((0)),
	 CONSTRAINT [PK_CostOffers] PRIMARY KEY CLUSTERED 
	(
		[CO_Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
end
GO

--<VERSION>9.2.8</VERSION>
--<DATE>2010-04-21</DATE>
IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CostOfferActivations]') AND type in (N'U'))
CREATE TABLE [dbo].[CostOfferActivations](
	[COA_ID] [int] IDENTITY(1,1) NOT NULL,
	[COA_COID] [int] NOT NULL,
	[COA_DateFrom] [datetime] NOT NULL,
	[COA_DateTo] [datetime] NULL,
	[COA_ActivateCreator] nvarchar(100) NOT NULL,
	[COA_DeActivateCreator] nvarchar(100) NULL,
 CONSTRAINT [PK_CostOfferActivations] PRIMARY KEY CLUSTERED 
(
	[COA_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

IF  NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CostOfferActivations_CostOffers]') AND parent_object_id = OBJECT_ID(N'[dbo].[CostOfferActivations]'))
ALTER TABLE [dbo].[CostOfferActivations]  WITH CHECK ADD  CONSTRAINT [FK_CostOfferActivations_CostOffers] FOREIGN KEY([COA_COID])
REFERENCES [dbo].[CostOffers] ([CO_Id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[CostOfferActivations] CHECK CONSTRAINT [FK_CostOfferActivations_CostOffers]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CostOfferServices]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
begin
	--Create table CostOfferServices
	CREATE TABLE [dbo].[CostOfferServices](
		[COS_Id] [int] IDENTITY(1,1) NOT NULL,
		[COS_COID] [int] NOT NULL,
		[COS_SVKEY] [int] NOT NULL,
		[COS_CODE] [int] NOT NULL,
		[COS_IsDisable] [bit] NOT NULL,
		[COS_DisableDate] [datetime] NULL,
	 CONSTRAINT [PK_CostOfferServices] PRIMARY KEY CLUSTERED 
	(
		[COS_Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	--FK_CostOfferServices_CostOffers
	ALTER TABLE [dbo].[CostOfferServices]  WITH CHECK ADD  CONSTRAINT [FK_CostOfferServices_CostOffers] FOREIGN KEY([COS_COID])
	REFERENCES [dbo].[CostOffers] ([CO_Id])
	ON DELETE CASCADE
	
	ALTER TABLE [dbo].[CostOfferServices] CHECK CONSTRAINT [FK_CostOfferServices_CostOffers]
end
GO

--rights for CostOfferServices
grant select, update, insert, delete on CostOfferServices to public
GO

if not exists(select id from syscolumns where id = OBJECT_ID('tbl_Costs') and name = 'CS_COID')
	begin
		alter table dbo.tbl_Costs add CS_COID [int] NULL 
			
		IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'FX_CS_COID' AND type in (N'F'))	
		ALTER TABLE [dbo].[tbl_Costs]  WITH CHECK ADD  CONSTRAINT [FX_CS_COID] FOREIGN KEY([CS_COID])
		REFERENCES [dbo].[CostOffers] ([CO_Id])	
	end
GO

exec sp_RefreshViewForAll 'Costs'
go

IF  NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Costs_CostOffers]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_Costs]'))
ALTER TABLE [dbo].[tbl_Costs]  WITH CHECK ADD  CONSTRAINT [FK_Costs_CostOffers] FOREIGN KEY([CS_COID])
REFERENCES [dbo].[CostOffers] ([CO_Id])
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CostOffersPublications]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
begin
	CREATE TABLE [dbo].[CostOffersPublications](
		[COP_ID] [int] IDENTITY(1,1) NOT NULL,
		[COP_PRKEY] [int] NOT NULL,
		[COP_PKKey] [int] NOT NULL,
		[COP_COID] [int] NOT NULL,
		[COP_Code] [int] NOT NULL,
		[COP_CostCount] [int] NOT NULL,
		[COP_CostLastUpdate] [datetime] NULL,
		[COP_MaxDateCost] [datetime] NULL,
		[COP_SVKey] [int] NULL,
	 CONSTRAINT [PK_CostOffersPublications] PRIMARY KEY CLUSTERED 
	(
		[COP_ID] ASC
	)) ON [PRIMARY]


	ALTER TABLE [dbo].[CostOffersPublications]  WITH CHECK ADD  CONSTRAINT [FK_CostOffersPublications_CostOffers] FOREIGN KEY([COP_COID])
	REFERENCES [dbo].[CostOffers] ([CO_Id])

	ALTER TABLE [dbo].[CostOffersPublications] CHECK CONSTRAINT [FK_CostOffersPublications_CostOffers]

	ALTER TABLE [dbo].[CostOffersPublications] ADD  DEFAULT ((0)) FOR [COP_CostCount]
end
go
-- добавили колонку с датой расчета цены на услугу
if not exists (select * from dbo.syscolumns where name = 'DL_CalculatePriceDate' and id = object_id(N'[dbo].[tbl_dogovorList]'))
begin
	alter table dbo.tbl_dogovorList add DL_CalculatePriceDate datetime default(getdate())
end
GO

exec sp_refreshViewForAll 'DogovorList'
go
/*********************************************************************/
/* end (2012.01.16)_Alter_Table_Costs.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.01.19)_Delete_Insert_Actions_TPD.sql */
/*********************************************************************/
go
delete from actions where AC_Key in (76,77,78,79,80,81,82,83)
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 76)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(76, 'Персональные данные->Разрешить просмотр списка ПДн', 'Personal data->Allow viewing list of TPD')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 77)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(77, 'Персональные данные->Разрешить добавление ПДн', 'Personal data->Allow adding TPD')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 78)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(78, 'Персональные данные->Разрешить редактирование ПДн', 'Personal data->Allow editing TPD')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 79)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(79, 'Персональные данные->Разрешить удаление ПДн', 'Personal data->Allow deleting TPD')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 80)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(80, 'Персональные данные->Разрешить просмотр обращений к ПДн', 'Personal data->Allow viewing TPD access list')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 81)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(81, 'Персональные данные->Разрешить удаление обращений к ПДн', 'Personal data->Allow deleting TPD access')
end
go
if not exists(select 1 from [dbo].[Actions] where AC_Key = 82)
begin
	insert actions(AC_Key, AC_NAME, AC_NAMELat)
	values(82, 'Персональные данные->Разрешить преобразование записи в ПДн', 'Personal data->Allow record conversion into TPD')
end 
go
IF NOT EXISTS (select 1 from actions where AC_Key = 83)
BEGIN
	insert Actions (AC_Key, AC_Name, AC_NameLat)
	VALUES(83, 'Персональные данные->Разрешить управление правами доступа к ПДН','Personal data->Allow manage access to TPD')
END
GO
/*********************************************************************/
/* end (2012.01.19)_Delete_Insert_Actions_TPD.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.01.19)_Update_TPDOperations_ApplicationTypes.sql */
/*********************************************************************/
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ApplicationTypes]') AND type in (N'U'))
begin
  update [dbo].[ApplicationTypes] set AT_Name='Мастер-Web' where  AT_Id=2
  update [dbo].[ApplicationTypes] set AT_Name='Веб-сервис' where  AT_Id=3
end
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TPDOperations]') AND type in (N'U'))
begin
	update [dbo].[TPDOperations] set TO_Name = 'Преобразование в ПДн' where TO_Id=7
	update [dbo].[TPDOperations] set TO_Name = 'Просмотр списка ПДн' where TO_Id=8
end
GO





/*********************************************************************/
/* end (2012.01.19)_Update_TPDOperations_ApplicationTypes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.01.19)_x_Quota_indexes.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_QO_web_1')
     DROP INDEX QuotaObjects.x_QO_web_1
GO
CREATE NONCLUSTERED INDEX [x_QO_web_1] ON [dbo].[QuotaObjects] 
(
	[QO_SVKey] ASC,
	[QO_Code] ASC
)
GO

IF  EXISTS (SELECT * FROM SYSINDEXES WHERE NAME LIKE 'x_SS_web_1')
     DROP INDEX StopSales.x_SS_web_1
GO
CREATE NONCLUSTERED INDEX [x_SS_web_1] ON [dbo].[StopSales] 
(
	[SS_QDID] ASC,
	[SS_Date] ASC,
	[SS_ID] ASC,
	[SS_QOID] ASC
)
INCLUDE ( [SS_IsDeleted])
GO
/*********************************************************************/
/* end (2012.01.19)_x_Quota_indexes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.01.25)_INSERT_ObjectTypes.sql */
/*********************************************************************/
  
  if(not exists(select * from ObjectTypes where ot_code = 'ManagerGroups'))
  insert into ObjectTypes (ot_id,ot_code,ot_name,ot_namelat,ot_comment)
  values(1001,'ManagerGroups','Группы менеджеров по туру','Manager Groups','Группы менеджеров по туру')
  GO
  
  
/*********************************************************************/
/* end (2012.01.25)_INSERT_ObjectTypes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin (2012.02.06)_Alter_Table_TP_Flights.sql */
/*********************************************************************/
--if not exists(select id from syscolumns where id = OBJECT_ID('TP_Flights') and name = 'TF_TIKey')
--	begin
--		alter table dbo.TP_Flights add TF_TIKey [int] NULL
--	end
--GO


/*********************************************************************/
/* end (2012.02.06)_Alter_Table_TP_Flights.sql */
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

--<DATE>2011-12-15</DATE>
---<VERSION>9.2.10.1</VERSION>
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
					inner join dbo.tp_servicelists with (nolock) on (tl_tskey = ts_key and TS_TOKey = @nPriceTourKey and TL_TOKey = @nPriceTourKey and TI_CalculatingKey = @nCalculatingKey)
				where tl_tikey = ti_key)
	where ti_tokey = @nPriceTourKey

	Set @nTotalProgress=1
	update tp_tours with(rowlock) set to_progress = @nTotalProgress where to_key = @nPriceTourKey
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
								TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') 
								AND TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01') 
								AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
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
									TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') 
									AND TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01') 
									AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
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
									TF_Date BETWEEN ISNULL(CS_Date, '1900-01-01') AND ISNULL(CS_DateEnd, '2053-01-01') 
									AND TF_TourDate BETWEEN ISNULL(CS_CHECKINDATEBEG, '1900-01-01') AND ISNULL(CS_CHECKINDATEEND, '2053-01-01') 
									AND AS_Week LIKE '%'+cast(datepart(weekday, TF_Date)as varchar(1))+'%' and
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
	set
		ti_nights = dbo.mwGetTiNights(ti_key)
	where 
		ti_tokey = @toKey and (@add <= 0 or ti_key in (select tikey from #tmpPrices))
	
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
/* begin sp_CorrectionCalculatedPrice_Run.sql */
/*********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CorrectionCalculatedPrice_Run]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CorrectionCalculatedPrice_Run]
GO

SET QUOTED_IDENTIFIER ON 
GO

CREATE PROCEDURE [dbo].[CorrectionCalculatedPrice_Run]
	(
		-- version 2009.9.10.02
		-- date 2012-02-10
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
			set TP_Gross = Ceiling(TPU_TPGrossOld + TPU_TPGrossDelta)
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
				set pt_price = Ceiling(TPU_TPGrossOld + TPU_TPGrossDelta)
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
									set pt_price = Ceiling(TPU_TPGrossOld + TPU_TPGrossDelta)
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

SET QUOTED_IDENTIFIER OFF
GO

grant exec on [dbo].[CorrectionCalculatedPrice_Run] to public
go
/*********************************************************************/
/* end sp_CorrectionCalculatedPrice_Run.sql */
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
		@sDetailed varchar(100) = '' output,  @nSPId int = null output, @useDiscountDays int = 0 output,
		@tourKey int = null
as
--<DATE>2012-01-11</DATE>
---<VERSION>2009.2.9.8</VERSION>

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
GO
GRANT EXECUTE ON [dbo].[GetServiceCost] TO PUBLIC 
GO
/*********************************************************************/
/* end sp_GetServiceCost.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCleaner.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCleaner]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[mwCleaner] 
GO

CREATE proc [dbo].[mwCleaner] as
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
			fetch next from delCursor into @cnkey, @ctkeyfrom
		end
		close delCursor
		deallocate delCursor
	end 

	delete from dbo.mwPriceHotels where sd_tourkey not in (select sd_tourkey from dbo.mwSpoDataTable) and sd_tourkey not in (select to_key from tp_tours where to_update <> 0)
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
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCreatePriceTable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[mwCreatePriceTable] 
GO

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
	[pt_autodisabled] [smallint] NULL)'
exec(@sql)
set @sql='grant select, delete, update, insert on '+@tableName+' to public'
exec(@sql)
end
GO

GRANT EXECUTE ON [dbo].[mwCreatePriceTable] TO PUBLIC 
GO
/*********************************************************************/
/* end sp_mwCreatePriceTable.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwCreatePriceTableIndexes.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwCreatePriceTable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
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
			create index x_main_roomprice on ' + @tableName + '([pt_mainplaces] ASC,[pt_addplaces] ASC,[pt_tourdate] ASC,[pt_tourtype] ASC,[pt_rskey] ASC,[pt_ctkey] ASC,[pt_tourkey] ASC,[pt_nights] ASC,[pt_pnkey] ASC,[pt_hdstars] ASC)INCLUDE ( [pt_tlkey],[pt_hdkey],[pt_pricekey],[pt_price],[pt_rmkey],[pt_rckey],[pt_days],[pt_isenabled],[pt_hdname],[pt_rcname],[pt_rccode],[pt_chkey],[pt_chbackkey],[pt_hdday],[pt_hdnights],[pt_hdpartnerkey],[pt_chday],[pt_chpkkey],[pt_chprkey],[pt_chbackday],[pt_chbackpkkey],[pt_chbackprkey],[pt_childagefrom],[pt_childageto],[pt_childagefrom2],[pt_childageto2],[pt_main],[pt_tourvalid],[pt_chbackkeys],[pt_chdirectkeys],[pt_hddetails],[pt_topricefor])
		if not exists(select id from sysindexes where id = object_id(''' + @tableName + ''') and indid > 0 and indid < 255 and name = ''x_main_persprice'')
			create index x_main_persprice on ' + @tableName + '([pt_tourdate] ASC,[pt_tourtype] ASC,[pt_rskey] ASC,[pt_ctkey] ASC,[pt_tourkey] ASC,[pt_nights] ASC,[pt_pnkey] ASC,[pt_hdstars] ASC)INCLUDE ( [pt_tlkey],[pt_hdkey],[pt_pricekey],[pt_price],[pt_rmkey],[pt_rckey],[pt_days],[pt_isenabled],[pt_hdname],[pt_rcname],[pt_rccode],[pt_chkey],[pt_chbackkey],[pt_hdday],[pt_hdnights],[pt_hdpartnerkey],[pt_chday],[pt_chpkkey],[pt_chprkey],[pt_chbackday],[pt_chbackpkkey],[pt_chbackprkey],[pt_childagefrom],[pt_childageto],[pt_childagefrom2],[pt_childageto2],[pt_main],[pt_tourvalid],[pt_chbackkeys],[pt_chdirectkeys],[pt_hddetails],[pt_topricefor])
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
	end
	'
	exec(@sql)
end
GO

GRANT EXECUTE ON [dbo].[mwCreatePriceTableIndexes] TO PUBLIC 
GO
/*********************************************************************/
/* end sp_mwCreatePriceTableIndexes.sql */
/*********************************************************************/

/*********************************************************************/
/* begin sp_mwMakeFullSVName.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MWMAKEFULLSVNAME]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mwMakeFullSVName]
GO
CREATE    PROCEDURE [dbo].[mwMakeFullSVName]
(
--<VERSION>2009.2.1</VERSION>
--<DATE>2012-1-30</DATE>
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
/* begin sp_mwReplDisableDeletedPrices.sql */
/*********************************************************************/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mwReplDisableDeletedPrices]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[mwReplDisableDeletedPrices]
GO

CREATE procedure [dbo].[mwReplDisableDeletedPrices]
as
begin
	declare @cnKey int
	declare @ctKeyFrom int

	select * into #mwReplDeletedPricesTemp from dbo.mwReplDeletedPricesTemp with(nolock);
	create index x_pricekey on #mwReplDeletedPricesTemp(rdp_pricekey);
	
	delete from dbo.mwReplDeletedPricesTemp with(rowlock)
	where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = mwReplDeletedPricesTemp.rdp_pricekey);
	
	if dbo.mwReplIsPublisher() > 0 
	begin
		declare @sql varchar (500);
		declare @source varchar(200);
		set @source = '';
		
		if len(dbo.mwReplSubscriberDB()) > 0
			set @source = '[mw].[' + dbo.mwReplSubscriberDB() + '].';

		if exists(select 1 from #mwReplDeletedPricesTemp)
		begin
			set @sql = '
			insert into ' + @source + 'dbo.mwReplDeletedPricesTemp with(rowlock) (rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey)
			select rdp_pricekey, rdp_cnkey, rdp_ctdeparturekey from #mwReplDeletedPricesTemp';
			
			exec (@sql);
		end
	end
	else if dbo.mwReplIsSubscriber() > 0
	begin
		if exists(select 1 from #mwReplDeletedPricesTemp)
		begin
			insert into dbo.mwDeleted with(rowlock) (del_key)
			select rdp_pricekey from #mwReplDeletedPricesTemp;
			
			if exists(select 1 from SystemSettings where SS_ParmName = 'MWDivideByCountry' and SS_ParmValue = 1)
			begin
				--Используется секционирование ценовых таблиц			
				declare mwPriceDataTableNameCursor cursor for
					select distinct dbo.mwGetPriceTableName(rdp_cnkey, rdp_ctdeparturekey) as ptn_tablename
					from
						#mwReplDeletedPricesTemp with(nolock);
					
				declare @mwPriceDataTableName varchar(200);
				open mwPriceDataTableNameCursor;
				fetch next from mwPriceDataTableNameCursor into @mwPriceDataTableName;

				while @@FETCH_STATUS = 0
					begin
					if exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].[' + @mwPriceDataTableName + ']') AND type in (N'U'))
						begin
						set @sql='
							update [dbo].[' + @mwPriceDataTableName + '] with(rowlock)
							set pt_isenabled = 0
							where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey)';
							
							exec (@sql);
							
							set @sql = '
							declare @cnKey int
							declare @ctKeyFrom int
							select top 1 @cnKey = pt_cnkey, @ctKeyFrom = pt_ctkeyfrom from [dbo].[' + @mwPriceDataTableName + '] with(nolock);
							update mwSpoDataTable set sd_isenabled = -1 where sd_isenabled = 1 and sd_cnkey = @cnKey and sd_ctkeyfrom = @ctKeyFrom and sd_hdkey not in (select distinct pt_hdkey from [dbo].[' + @mwPriceDataTableName + '] with(nolock) where pt_isenabled = 1 and pt_tourkey = sd_tourkey)';
							--print @sql
							exec (@sql);
							
							fetch next from mwPriceDataTableNameCursor into @mwPriceDataTableName;
						end
					end
				close mwPriceDataTableNameCursor;
				deallocate mwPriceDataTableNameCursor;
			end
			else
			begin
				--Секционирование не используется
				update dbo.mwPriceDataTable with(rowlock)
				set pt_isenabled = 0
				where exists(select 1 from #mwReplDeletedPricesTemp r where r.rdp_pricekey = pt_pricekey);
			end
		end
	end
	
	drop index x_pricekey on #mwReplDeletedPricesTemp;
	drop table #mwReplDeletedPricesTemp;
end
GO

GRANT EXECUTE ON [dbo].[mwReplDisableDeletedPrices] TO PUBLIC
GO
/*********************************************************************/
/* end sp_mwReplDisableDeletedPrices.sql */
/*********************************************************************/

/*********************************************************************/
/* begin T_mwUpdateHotel.sql */
/*********************************************************************/
--<VERSION>ALL</VERSION>
--<DATE>2012-01-30</DATE>


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

			select hd_key, hd_rskey, hd_stars, hd_name, HD_HTTP into #temp from inserted

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

/*********************************************************************/
/* end T_mwUpdateHotel.sql */
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
--<VERSION>2009.2.10.4</VERSION>
--<DATE>2012-02-17</DATE>
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
/* begin Version92.sql */
/*********************************************************************/
-- для версии 2009.2
update [dbo].[setting] set st_version = '9.2.12', st_moduledate = convert(datetime, '2012-02-16', 120),  st_financeversion = '9.2.12', st_financedate = convert(datetime, '2012-02-16', 120) where st_version like '9.%'
GO
UPDATE dbo.SystemSettings SET SS_ParmValue='2012-02-16' WHERE SS_ParmName='SYSScriptDate'
GO
/*********************************************************************/
/* end Version92.sql */
/*********************************************************************/
