
import os
class IISManager(object):
    """Class to manage sites on IIS"""
    @staticmethod
    def CreateSite():
        #os.system("net stop w3svc")
        os.system(r"C:\\Windows\\WinSxS\\amd64_microsoft-windows-iis-sharedlibraries_31bf3856ad364e35_6.3.9600.17088_none_01abb77d88c5e548\\appcmd.exe add app site.name:\"Default Web Site\" path:test_app physicalPath:E:\\MW_develop")
        #PS C:\WINDOWS\system32> New-Item 'IIS:\Sites\Default Web Site\DemoApp' -physicalPath e:\mw_main -type Application


if __name__ == "__main__":
    IISManager.CreateSite()
