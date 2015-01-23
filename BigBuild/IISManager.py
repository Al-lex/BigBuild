
import os
import subprocess
class IISManager(object):
    """Class to manage sites on IIS"""


    @staticmethod
    def CreateSite(SettingsObj):


         for name,src,dst,conn,plugs,iis,mtdata,isLastBuild in SettingsObj.GetBuildPaths():
        #os.system("net stop w3svc")
        #os.system(r"C:\\Windows\\WinSxS\\amd64_microsoft-windows-iis-sharedlibraries_31bf3856ad364e35_6.3.9600.17088_none_01abb77d88c5e548\\appcmd.exe add app site.name:\"Default Web Site\" path:test_app physicalPath:E:\\MW_develop")
        #PS C:\WINDOWS\system32> New-Item 'IIS:\Sites\Default Web Site\DemoApp' -physicalPath e:\mw_main -type Application
        #DefaultAppPool
                 appcmd="C:\\Windows\\System32\\inetsrv\\appcmd.exe"   
             
                 comm=r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe Remove-WebApplication -Name "+iis["appName"]+" -Site 'Default Web Site'"
                 retcode=subprocess.call(comm, shell=True)
                 if retcode == 0:
                        print ("successfuly removed web-site")
                 else:
                        print ("failure with web site remove -lets try app cmd:")
                        #comm=appcmd+" delete app /site.name:\"Default Web Site\""+"\\"+iis["appName"]
                        #C:\Windows\System32\inetsrv\appcmd.exe delete app "Default Web Site/test1"    delete app "Default Web Site/
                        comm=appcmd+" delete app \"Default Web Site/"+iis["appName"]+"\""
                        print("execute:"+comm)
                        retcode=subprocess.call(comm, shell=True)
                        if retcode == 0:
                               print ("at last successfuly removed web-site")
                        else:
                               print ("well - it seems to be impossible")

                  

               
                 comm=r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe New-WebApplication -Name "+iis["appName"]+" -Site 'Default Web Site' -PhysicalPath "+dst+" -ApplicationPool "+iis["appPool"]
                  #print(comm)
                    #os.system(comm)
                   
                 retcode=subprocess.call(comm, shell=True)
                 if retcode == 0:
                        print ("successfuly installed web-site")
                 else:
                        print ("failure with web site install -lets try app cmd:")
                        comm=appcmd+" add app /site.name:\"Default Web Site\""+" /path:/"+iis["appName"]+" /physicalPath:"+dst
                        print("execute:"+comm)
                        retcode=subprocess.call(comm, shell=True)
                        if retcode == 0:
                               print ("at last successfuly add web-site")
                        else:
                               print ("well - it seems add impossible")

               

if __name__ == "__main__":
    from DataAdaptor import XMLAdaptor as XA
    conf=XA("MW.config")
    IISManager.CreateSite(conf)
