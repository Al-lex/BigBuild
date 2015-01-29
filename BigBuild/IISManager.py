
import os
import subprocess
class IISManager(object):
       """Class to manage sites on IIS"""
       @staticmethod
       def CreateWebServices(SettingsObj):    
             for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
                 for service in servicedetails:
                     if (service[2]):
                         optype="webservice"
                         #del
                         commcmd=" delete app \"Default Web Site/"+service[0]+"\""
                         commps=" Remove-WebApplication -Name "+service[0]+" -Site 'Default Web Site'"
            
                         IISManager.ProcessSite(commcmd,commps,optype)
                         #create
                         ##TBD first of all need to add poolname!!!!!!!!!!!!!!!!
                         commcmd=" add app /site.name:\"Default Web Site\""+" /path:/"+service[0]+" /physicalPath:"+dst+"\\"+service[0]
                         commps=" New-WebApplication -Name "+service[0]+" -Site 'Default Web Site' -PhysicalPath "+dst+"\\"+service[0]+" -ApplicationPool "+service[1]
                         IISManager.ProcessSite(commcmd,commps,optype)
       @staticmethod
       def CreateWebApp(SettingsObj):  
               for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
                         optype="webapp"
                         #del
                         commcmd=" delete app \"Default Web Site/"+iis["appName"]+"\""
                         commps=" Remove-WebApplication -Name "+iis["appName"]+" -Site 'Default Web Site'"
            
                         IISManager.ProcessSite(commcmd,commps,optype)
                         #create
                         ##TBD need to add poolname!!!!!!!!!!!!!!!!
                         commcmd=" add app /site.name:\"Default Web Site\""+" /path:/"+iis["appName"]+" /physicalPath:"+dst

                         commps=" New-WebApplication -Name "+iis["appName"]+" -Site 'Default Web Site' -PhysicalPath "+dst+" -ApplicationPool "+iis["appPool"]
                         IISManager.ProcessSite(commcmd,commps,optype)
       
       def ProcessSite(commcmd,commps,optype):
            appcmd="C:\\Windows\\System32\\inetsrv\\appcmd.exe"
            powershell="C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" 
            retcode=subprocess.call(powershell+commps, shell=True)
            if retcode == 0:
                   print ("successfuly "+optype+" web-app")
            else:
                   print ("failure with web app "+optype+" -lets try app cmd:")                              
           
                   print("execute:"+appcmd+commcmd)
                   retcode=subprocess.call(appcmd+commcmd, shell=True)
                   if retcode == 0:
                          print ("at last successfuly "+optype+" web-app")
                   else:
                          print ("well failue"+optype+"- it seems to be impossible")

    #@staticmethod
    #def CreateSite(SettingsObj):


    #     for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
       
    #             appcmd="C:\\Windows\\System32\\inetsrv\\appcmd.exe"   
             
    #             comm=r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe Remove-WebApplication -Name "+iis["appName"]+" -Site 'Default Web Site'"
    #             retcode=subprocess.call(comm, shell=True)
    #             if retcode == 0:
    #                    print ("successfuly removed web-site")
    #             else:
    #                    print ("failure with web site remove -lets try app cmd:")
    #                    #comm=appcmd+" delete app /site.name:\"Default Web Site\""+"\\"+iis["appName"]
    #                    #C:\Windows\System32\inetsrv\appcmd.exe delete app "Default Web Site/test1"    delete app "Default Web Site/
    #                    comm=appcmd+" delete app \"Default Web Site/"+iis["appName"]+"\""
    #                    print("execute:"+comm)
    #                    retcode=subprocess.call(comm, shell=True)
    #                    if retcode == 0:
    #                           print ("at last successfuly removed web-site")
    #                    else:
    #                           print ("well - it seems to be impossible")

                  

               
    #             comm=r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe New-WebApplication -Name "+iis["appName"]+" -Site 'Default Web Site' -PhysicalPath "+dst+" -ApplicationPool "+iis["appPool"]
                
                   
    #             retcode=subprocess.call(comm, shell=True)
    #             if retcode == 0:
    #                    print ("successfuly installed web-site")
    #             else:
    #                    print ("failure with web site install -lets try app cmd:")
    #                    comm=appcmd+" add app /site.name:\"Default Web Site\""+" /path:/"+iis["appName"]+" /physicalPath:"+dst
    #                    print("execute:"+comm)
    #                    retcode=subprocess.call(comm, shell=True)
    #                    if retcode == 0:
    #                           print ("at last successfuly add web-site")
    #                    else:
    #                           print ("well - it seems add impossible")
      





                          

if __name__ == "__main__":
    from DataAdaptor import Model as XA
    conf=XA("MW.config")
    IISManager.CreateSite(conf)
