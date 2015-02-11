"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\SQLCMD.EXE" -S s15\mastertour08 -d master -U sa -P sa -i E:\PyProjects\BigBuild\BigBuild\Clear_connect.sql -v dbname='main_del'
timeout 3
"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\SQLCMD.EXE" -S s15\mastertour08 -d master -U sa -P sa -Q "RESTORE DATABASE [main_del] FROM  DISK = N'F:\ALLBASE\mastertour\backup\main_del.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5"
timeout 3
