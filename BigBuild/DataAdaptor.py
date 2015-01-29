import xml.etree.ElementTree as ET
from distutils import dir_util
from os import listdir
import shutil 
import os
import zipfile
import glob
import subprocess
#https://docs.python.org/2/library/xml.etree.elementtree.html
class Model(object):
    """Class is used as middle layer for working with external config"""
    pathToFile=""

    def __init__(self,pathToFile):
        self.pathToFile=pathToFile
    def GetConfigTree(self):
        tree = ET.parse(self.pathToFile)
        root = tree.getroot()
        return root
    def GetBuildPaths(self):
        """Gets branches with names list from MW.config"""
        #for child in self.GetConfigTree():
        #     print (child.tag, child.attrib)
        files=[]
        for branch in self.GetConfigTree().findall("branch"):


                 servicedetails=[]

                 brservices=branch.findall("Services")
                 for services in brservices:
                              #print(services.findall("Service")[0].get("name"))
                              for service in services.findall("Service"):
                                  servicedetails.append([service.get("name"),service.get("apppool"),service.get("getlocal")])
                 #print(servicedetails)






                
                 name = branch.get("name")
                 pathToLatest = branch.find("pathToLatest").text

                 pathToLocal=branch.find("pathToLocal").text

#add connections for the branch
                 connectionData={}
                
                 connectionData["remotedbname"]=branch.find("dbconnection").get("remotedbname")
                 connectionData["SERVER"]=branch.find("dbconnection").get("SERVER")
                 connectionData["DATABASE"]=branch.find("dbconnection").get("DATABASE")
                 connectionData["UserID"]=branch.find("dbconnection").get("UserID")
                 connectionData["Password"]=branch.find("dbconnection").get("Password")







                 #add plugins from global plugin list - mast be set getLocal=true 
        #print (name, pathToLatest,pathToLocal,connectionData)
                 Plugins=[]
                 
                 for pluginName in self.GetPlugins():
                      Plugins.append(pluginName)
                      #print (pathToLatest+self.GetLastBuildNumber(pathToLatest)+pluginName)

                 iisData={}
                 iisData["appName"]=branch.find("iisAppSettings").get("appName")
                 iisData["appPool"]=branch.find("iisAppSettings").get("appPool")

                 MTData={}
                 MTData["MTpathToLatest"]=branch.find("MT").get("MTpathToLatest")
                 MTData["MTpathToLocal"]=branch.find("MT").get("MTpathToLocal")
                 MTData["saPassword"]=branch.find("MT").get("saPassword")
                 MTData["MTUserID"]=branch.find("MT").get("MTUserID")
                 MTData["MTPassword"]=branch.find("MT").get("MTPassword")

                 MTData["Release"]=branch.find("MT").get("Release")




                 isLastBuild = branch.find("isLastBuild").text

              



                 files.append((name, pathToLatest,pathToLocal,connectionData, Plugins, iisData,MTData,isLastBuild,servicedetails))

                 

               

        return files

    def GetPlugins(self):
       """Gets plugins list from MW.config. Added only those with True for GetLocal"""
       files=[]
       for plugin in self.GetConfigTree().findall("Plugins")[0].findall("plugin"):

           if (plugin.get("getlocal")):

            files.append(plugin.get("name"))
           
       return files
    def GetServices(self):
       """Gets services list from MW.config"""
       services=[]
       for service in self.GetConfigTree().findall("branch").findall("Services").findall("Service"):
           services.append((service.get("name"),service.get("apppool"), service.get("getlocal")))
           name=service.get("name")
           apppool=service.get("apppool")
           getlocal=service.get("getlocal")
           print(name,apppool,getlocal) 
       return services  
   
     
    def GetFiles(self):
       """Gets files list-i.e. MTData sql.ini etc- from MW.config"""
       files=[]
       for fl in self.GetConfigTree().findall("Files")[0].findall("file"):
           files.append((fl.get("name"),fl.get("getlocal")))
           #name=fl.get("name")
           #getlocal=fl.get("getlocal")
           #print(name,getlocal) 
       return files
    def GetDirectories(self):
       """Gets static directories -may be used for temporary pathches using permanent location of files- for example Release folder"""
       directories=[]
       for dr in self.GetConfigTree().findall("Directories")[0].findall("directory"):
           directories.append((dr.get("path"),dr.get("getlocal")))
           #name=fl.get("name")
           #getlocal=fl.get("getlocal")
           #print(name,getlocal) 
       return directories


    def GetLastBuildNumber(self,path):
       """Method to find name of the last zip build in the branch specified"""
       l=listdir(path)
       l.sort(reverse=True)
       return (l[0])

   
          
            
           
           
           
class Controller():
       """Class for copy operations with different objects of XA type"""
       from DataAdaptor import Model as XA
       #@staticmethod     
       #def GetFilesToTempSubfolder(SettingsObj):
       #    """Static method to get web service files from static location """
       #    for name,src,dst,conn,plugs,iis,mtdata,isLastBuild in SettingsObj.GetBuildPaths():
       #      # if(SettingsObj.GetDirectories[0][1]=="true"):
       #           dirpath=SettingsObj.GetDirectories()[0][0]
       #           #create tempdir in branch
       #           tempdir=dst+"\\Tmp"
       #           if not os.path.exists(tempdir):
       #              os.mkdir(tempdir)
       #           shutil.copy2(dirpath,tempdir)


       @staticmethod
       def CopyFilesBuild(SettingsObj):
          """Static method to get incremental update from last release to last build"""
          #if(isinstance(SettingsObj,XA)):
          
          
           # try:
          for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
                          if os.path.exists(dst):
                                    shutil.rmtree(dst)
                          os.mkdir(dst)
                          print("Branch named "+name+" will be copyed")
                          dirname=SettingsObj.GetLastBuildNumber(src)
                         
                          src2=src+"\\"+dirname+"\\Release\\Full\\_Zips\\mw-"+dirname[9:]+".zip"

                          if (os.path.exists(src2)):
                              shutil.copy2(src2,dst)
                              
                              print("Success with copy of "+dirname+"!")
                              return False
                          else:
                             print ("Problem with copy last build from, "+src+"  it will be taken last good build")
                             relFolders=os.listdir(src)
                             relFolders.sort()
                             for dirname in relFolders:
                                 if (os.path.exists(src+"\\"+dirname+"\\Release")):

                                   
                                      src2=src+"\\"+dirname+"\\Release\\Full\\_Zips\\mw-"+dirname[9:]+".zip"
                                      if (os.path.exists(src2)):
                                         shutil.copy2(src2,dst)


                                      print("Success with last good(not latest)-it was"+dirname+"!")
                                      return True
#if getstatic turned true in config get in Tmp folder static files
                         # if(SettingsObj.GetDirectories[0][1]=="true"):
                       
            #except:
                #print("Problem with copy, check "+src+"  if file in place")
                          
          #else:
             # raise Exception("Not valid config object")
      
       @staticmethod 
       def StopPaymentService():    
             comm1=r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe get-service \"Служба подписи путевок и платежей\">tmp.txt"
             retcode=subprocess.call(comm1, shell=True)
             if retcode == 0:
                            path=os.getcwd()+"\\tmp.txt"
                            #print (path)
                            file=open(path,"r")

                            

                           
                            #print(file.readlines())
                            #if any(word.find("Running") for word in file.readlines()):
                            for line in file.readlines():
                                print(line)
                                if line.find("Running"):
                         
                                    print ("check service - payment service is Running -try to stop to update catalog")
                                    #stop service to remove catalog)
                                    comm2=(r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe stop-service \"Служба подписи путевок и платежей\">tmp.txt")
                                    retcode=subprocess.call(comm2, shell=True)
                                    if retcode == 0:
                                               print ("Successfuly stopped payment service")
                                    else:
                                               print ("Failure with stop payment service")
                                    file.close()
                                    os.remove(os.getcwd()+"\\tmp.txt")
                                    return True
                                elif line.find("Stopped"):
                               #any(word.find("Stopped") for word in file.readlines()):
                                     print ("service is already stopped")
                                     file.close()
                                     os.remove(os.getcwd()+"\\tmp.txt")
                                     return True

                                else:
                                    print("Payment service is not running - will be tried install")
                                    file.close()
                                    os.remove(os.getcwd()+"\\tmp.txt")
                                    return False
                            
             else:
                  print("Somthing wrong with check service running")
       @staticmethod
       def StartPaymentService():
            comm=(r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe start-service \"Служба подписи путевок и платежей\"")
            retcode=subprocess.call(comm, shell=True)
            if retcode == 0:
                       print ("successfuly start payment service")
            else:
                       print ("failure with start payment service")           
            
       
       @staticmethod
       def InstallPaymentService(SettingsObj):
           for name,src,dst,conn,plugs,iis,mtdata,isLastBuild in SettingsObj.GetBuildPaths():
                  if(SettingsObj.GetDirectories()[0][1]=="true"):
                                 tmp=dst+"\\Tmp"
                                 comm3=tmp+"\\_Install.bat"
                                 retcode=subprocess.call(comm3, shell=True)
                                 if retcode == 0:
                                    print ("successfuly installed payment service")
                                 else:
                                    print ("failure with payment service")                 
                       
       @staticmethod
       def CopyStaticDir(SettingsObj):
              pathtofilestatic=SettingsObj.GetDirectories()[0][0] 
              for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
                  if(SettingsObj.GetDirectories()[0][1]=="true"):
                                 tmp=dst+"\\Tmp"
                                 os.mkdir(tmp)
                                 shutil.copy2(pathtofilestatic,tmp)
                                 lst=os.listdir(tmp)
                                 zip=zipfile.ZipFile(tmp+"//"+lst[0])
                                 zip.extractall(tmp)
                                 print("Copy payments service from static location finished")
                               

                   
                           





                
      


       @staticmethod
       def CopyFilesRelease(SettingsObj):
           """Static method to get in case of need files from release"""
           pass
       @staticmethod
       def UnzipFilesBuild(SettingsObj):
           """Static method to unzip getted files"""
           for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
                  lst=os.listdir(dst)
                  zip=zipfile.ZipFile(dst+"//"+lst[0])
                  zip.extractall(dst)

       @staticmethod
       def CopyFilesPlugins(SettingsObj):
           for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
                    buildNum=SettingsObj.GetLastBuildNumber(src)
                    for plug in plugs:
                  #find zip
                       plugSrcZip=src+"\\"+buildNum+"\\Release\\Full\\_Zips\\mw-"+plug+"-"+buildNum[9:]+".zip"
                       zip=zipfile.ZipFile(plugSrcZip)
                       zip.extractall(dst)
                  #unzip zip in dst
       @staticmethod
       def CopyFilesExtraForMW(SettingsObj):
          for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
              if(SettingsObj.GetFiles()[0][1]=="true"):
                  filename=SettingsObj.GetFiles()[0][0]
                  shutil.copy2(os.getcwd()+"\\Extra\\"+filename,dst)
       @staticmethod
       def ProcessFilesServices(SettingsObj):
          for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in SettingsObj.GetBuildPaths():
              
              buildNum=SettingsObj.GetLastBuildNumber(src)
            
              services=[]
              src=src+"\\"+buildNum+"\\Release\\Full\\_Zips\\"
              srcfull=src+"\\"+buildNum+"\\Release\\Full\\_Zips\\mw-"+buildNum[9:]+".zip"
              #if build is not made then we search last goo and take its number
              if not(os.path.exists(srcfull)):
                  relFolders=os.listdir(src)
                  relFolders.sort()
                  for dirname in relFolders:
                                 
                             if (os.path.exists(srcfull)):
                                               buildNum=dirname
                                               print("Build was broken - it will be found last good build")
                                               break

        
              for root, dirs, files in os.walk(src):
                      for file in files:
                          for service in servicedetails: 
                              if (service[2]):
                                  if service[0] in file:
                                      print (service[0])
                                      src2=src+file
                                      zip=zipfile.ZipFile(src2)
                                      dst2=dst+"\\"+service[0]
                                      if not (os.path.exists(dst2)):
                                                       os.mkdir(dst2)
                                      zip.extractall(dst2)
                                      servicePool=service[1]
                                      services.append([dst2,servicePool])

           
              print(services) 
              return services



class ConfigFactory():
    """Class to configure configs - web.config sql.ini etc""" 


             
    @staticmethod
    def ChangeConnectString(SettingsObj,FileType):
   
          """Static method to change conn string in ini or web.config file"""

          







          #find pathes to all branches and concatenate
        

          for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails  in SettingsObj.GetBuildPaths():
             
              
 
             
              if FileType=="sql.ini":
                  connStringEth=r"remotedbname=IL2009,DRIVER=SQL Server;SERVER=s15\interlook08;DATABASE=IL2009;Trusted_Connection=no;APP=Master-Tour"
                  connString="remotedbname="+ conn["remotedbname"]+",DRIVER=SQL Server;SERVER="+conn["SERVER"]+";DATABASE="+conn["DATABASE"]+";Trusted_Connection=no;APP=Master-Tour" 
                  filepath=   dst+"\\MT\\"+FileType                                
                  the_file=open(filepath,"r+",encoding='UTF8')
                  the_file2=open(dst+filepath+".new","w",encoding='UTF8') 
                  
                     
                  
                           
              elif FileType=="web.config":
                  connStringEth="Data Source=ip-адрес сервера; Initial Catalog=название базы;User Id=логин пользователя;Password=пароль"
                  connString="Data Source="+conn["SERVER"]+"; Initial Catalog="+conn["DATABASE"]+";User Id="+conn["UserID"]+";Password="+ conn["Password"]
                  filepath=dst+"\\"+FileType
                  the_file=open(filepath,"r+",encoding='UTF8')
                  the_file2=open(filepath+".new","w",encoding='UTF8')

              elif FileType=="Megatec.PaymentSignatureServiceHost.exe.config":
                  connStringEth="Data Source=DataSource; Initial Catalog=InitialCatalog;User Id=UserId;Password=Password"
                  connString="Data Source="+conn["SERVER"]+"; Initial Catalog="+conn["DATABASE"]+";User Id="+conn["UserID"]+";Password="+ conn["Password"]
                  #different path -needs add Tmp subfolder
                  filepath=dst+"\\Tmp\\"+FileType
                  the_file=open(filepath,"r+",encoding='UTF8')
                  the_file2=open(filepath+".new","w",encoding='UTF8')



                

              
            

              for line in the_file.readlines(): 
                   print (line.replace(connStringEth,connString),end="",file=the_file2)

  

 
              the_file.close()
              the_file2.close()

              os.remove(filepath);
              os.rename(filepath+".new",filepath)

               
if __name__ == "__main__":
    from DataAdaptor import Model as XA
    conf=XA("MW.config")
 
    Controller.ProcessFilesServices(conf)
  



