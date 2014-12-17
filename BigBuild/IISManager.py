
import os
class IISManager(object):
    """Class to manage sites on IIS"""
    @staticmethod
    def CreateSite(SettingsObj):


         for name,src,dst,conn,plugs,iis in SettingsObj.GetBuildPaths():
        #os.system("net stop w3svc")
        #os.system(r"C:\\Windows\\WinSxS\\amd64_microsoft-windows-iis-sharedlibraries_31bf3856ad364e35_6.3.9600.17088_none_01abb77d88c5e548\\appcmd.exe add app site.name:\"Default Web Site\" path:test_app physicalPath:E:\\MW_develop")
        #PS C:\WINDOWS\system32> New-Item 'IIS:\Sites\Default Web Site\DemoApp' -physicalPath e:\mw_main -type Application
        #DefaultAppPool
                    
                 try:
                   os.system(r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe Remove-WebApplication -Name "+iis["appName"]+" -Site 'Default Web Site'")
                 except:
                  print("Remove impossible")
                  

                 try:
                    comm=r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe New-WebApplication -Name "+iis["appName"]+" -Site 'Default Web Site' -PhysicalPath "+dst+" -ApplicationPool "+iis["appPool"]
                  #print(comm)
                    os.system(comm)
                 except:
                    print("Create site"+iis["appName"]+" impossible - try to do it manually")

if __name__ == "__main__":
    IISManager.CreateSite()
