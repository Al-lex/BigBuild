
import os
class IISManager(object):
    """Class to manage sites on IIS"""
    @staticmethod
    def CreateSite():
        #os.system("net stop w3svc")
        os.system(r"C:\\Windows\\WinSxS\\amd64_microsoft-windows-iis-sharedlibraries_31bf3856ad364e35_6.3.9600.16384_none_01a7d2cf88c95dc0\\appcmd.exe add app site.name:\"Default Web Site\" path:test_app physicalPath:E:\\MW_develop")


if __name__ == "__main__":
    IISManager.CreateSite()
