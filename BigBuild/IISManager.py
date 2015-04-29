import os
import subprocess


class IISManager(object):
       """Class to manage sites on IIS"""
       @staticmethod
       def CreateWebServices(SettingsObj):   
             """Method to add web-service on IIS
             -it creates strings to exec via cmd or ps
             
             """ 
             for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
                 for service in servicedetails:
                     if (service[3]=="true"):
                         optype="webservice"
                         #del
                         commcmd=" delete app \"Default Web Site/"+service[1]+"\""
                         commps=" Remove-WebApplication -Name "+service[1]+" -Site 'Default Web Site'"
            
                         IISManager.ProcessSite(commcmd,commps,optype)
                         #create
                         ##TBD first of all need to add poolname!!!!!!!!!!!!!!!!
                         commcmd=" add app /site.name:\"Default Web Site\""+" /path:/"+service[1]+" /physicalPath:"+dst+"\\"+service[1]
                         commps=" New-WebApplication -Name "+service[1]+" -Site 'Default Web Site' -PhysicalPath "+dst+"\\"+service[1]+" -ApplicationPool "+service[2]
                         IISManager.ProcessSite(commcmd,commps,optype)
       @staticmethod
       def CreateWebApp(SettingsObj): 
               """Method to add web-site on IIS
               -it creates strings to exec via cmd or ps
               """ 
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
            """Method to process prepared command strings 
            -it try to exec via appcmd in case of failue it runs via ps 
            """
            appcmd="C:\\Windows\\System32\\inetsrv\\appcmd.exe"
            powershell="C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" 
            retcode=subprocess.call(powershell+commps, shell=False,stderr=subprocess.PIPE)
            if retcode == 0:
                   print ("successfuly "+optype+" web-app")
            else:
                   print ("failure with web app "+optype+" -lets try app cmd:")                              
           
                   print("execute:"+appcmd+commcmd)
                   retcode=subprocess.call(appcmd+commcmd, shell=False,stderr=subprocess.PIPE)
                   if retcode == 0:
                          print ("at last successfuly "+optype+" web-app")
                   else:
                          print ("well failue "+optype+"- it seems to be impossible eather in ps or in appcmd - try add site manually")

   

if __name__ == "__main__":
    from DataAdaptor import Model as XA
    conf=XA("MW.config")
    IISManager.CreateSite(conf)
