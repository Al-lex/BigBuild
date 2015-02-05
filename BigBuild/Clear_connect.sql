IF  NOT EXISTS (select *
   from tempdb..sysobjects o
where o.name like '#sp_who%' AND type in (N'U'))
create table #sp_who
(
spid int null,
ecid int null,
status varchar(30) null,
loginname sysname null,
hostname sysname null,
blk int null,
dbname sysname null,
cmd varchar(16) null,
request_id int null
)

insert #sp_who
exec sp_who 


--очищаем коннекты
declare @spid int
declare @db varchar(10)
declare @host varchar(10)
set @db=$(dbname)
--set @host='s15'


DECLARE c_columns CURSOR FOR

select spid from #sp_who where dbname=@db 
--and hostname!=@host
OPEN c_columns
FETCH NEXT FROM c_columns INTO  @spid
WHILE @@FETCH_STATUS = 0
BEGIN

declare @query varchar(512)
set @query='kill '+  cast(@spid as varchar(10))

print @query
exec (@query)
    FETCH NEXT
    FROM c_columns
    INTO @spid

END
CLOSE c_columns
DEALLOCATE c_columns
--конец внутреннего курсора
IF  EXISTS (select *
   from tempdb..sysobjects o
where o.name like '#sp_who%' AND type in (N'U'))
drop table #sp_who
GO