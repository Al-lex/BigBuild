"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\SQLCMD.EXE" -S s15\mastertour08 -d master -U sa -P sa -Q "RESTORE DATABASE [main_del] FROM  DISK = N'F:\ALLBASE\mastertour\backup\main_del.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5"
timeout 3
"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\SQLCMD.EXE" -S s15\mastertour08 -d main_del -U sa -P sa -i \\bg\builds\Master-Tour\Main_MasterTour\LastBuild\Scripts\ReleaseScript.sql -I -R >> "E:\PyProjects\BigBuild\BigBuild\Main\resultrestor.txt" -f i:65001