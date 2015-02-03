1. Установить приреквизиты  в следующем порядке:
 1. python-3.4.2.msi
 2.pymssql-2.1.1.win-amd64-py3.4.exe (если не будет ставиться то pymssql-2.1.1.win32-py3.4)
 3.sqlncli.msi
 4.SqlCmdLnUtils.msi
2. В файле MW.config прописать настройки
3.Запустить PS от администратора и выполнить команду Set-ExecutionPolicy Unrestricted
4.Запустить командную строку от имени администратора -выполнить в ней команду chcp 857
5.Перейти в каталог со скриптом BigBuild.py и запустить его
6.Лог выполнения пишется в UpdateLog.log
7.Лог sql скриптов пишется в resultrestor.txt в папке с названием ветки



\\bg\Builds\Master-Web\main_MasterWeb\main_MasterWeb\MasterWeb9.2.21.59668\Release\Full\_Zips\mw-ws-aviasearch-9.2.21.59668.zip  название и пул приложений


short conn string 