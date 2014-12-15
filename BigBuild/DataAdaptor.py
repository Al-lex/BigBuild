import xml.etree.ElementTree as ET
from distutils import dir_util
from os import listdir
import shutil 
import os
import zipfile
#https://docs.python.org/2/library/xml.etree.elementtree.html
class XMLAdaptor(object):
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



                 files.append((name, pathToLatest,pathToLocal,connectionData, Plugins))



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
       files=[]
       for service in self.GetConfigTree().findall("Services")[0].findall("service"):
           files.append((service.get("name"),service.get("getlocal")))
           name=service.get("name")
           getlocal=service.get("getlocal")
           print(name,getlocal) 
       return files     
    def GetFiles(self):
       """Gets files list-i.e. MTData sql.ini etc- from MW.config"""
       files=[]
       for fl in self.GetConfigTree().findall("Files")[0].findall("file"):
           files.append((fl.get("name"),fl.get("getlocal")))
           name=fl.get("name")
           getlocal=fl.get("getlocal")
           #print(name,getlocal) 
       return files
    def GetLastBuildNumber(self,path):
       """Method to find name of the last zip build in the branch specified"""
       l=listdir(path)
       l.sort(reverse=True)
       return (l[0])
          
            
           
           
           
class FileFactory():
       """Class for copy operations with different objects of XA type"""
       from DataAdaptor import XMLAdaptor as XA
       @staticmethod
       def CopyFilesBuild(SettingsObj):
          """Static method to get incremental update from last release to last build"""
          #if(isinstance(SettingsObj,XA)):
             
           # try:
          for name,src,dst,conn,plugs in SettingsObj.GetBuildPaths():
                          if os.path.exists(dst):
                                    shutil.rmtree(dst)
                          os.mkdir(dst)
                          print("Branch named "+name+" will be copyed")
                          Zipname=SettingsObj.GetLastBuildNumber(src)
                         
                          src=src+"\\"+Zipname+"\\Release\\Full\\_Zips\\mw-"+Zipname[9:]+".zip"
                         # dst=dst+"\\"+"mw-"+Zipname[9:]+".zip"
                          #print(src)
                          #dir_util.copy_tree(src,dst)
                          if (os.path.exists(src)):
                              shutil.copy2(src,dst)
                              print("Success!")
                          else:
                             print ("Problem with copy, check "+src+"  if file in place")
                             continue
            #except:
                #print("Problem with copy, check "+src+"  if file in place")
                          
          #else:
             # raise Exception("Not valid config object")
       @staticmethod
       def CopyFilesRelease(SettingsObj):
           """Static method to get in case of need files from release"""
           pass
       @staticmethod
       def UnzipFilesBuild(SettingsObj):
           """Static method to unzip getted files"""
           for name,src,dst,conn,plugs in SettingsObj.GetBuildPaths():
                  lst=os.listdir(dst)
                  zip=zipfile.ZipFile(dst+"//"+lst[0])
                  zip.extractall(dst)

       @staticmethod
       def CopyFilesPlugins(SettingsObj):
           for name,src,dst,conn,plugs in SettingsObj.GetBuildPaths():
                    buildNum=SettingsObj.GetLastBuildNumber(src)
                    for plug in plugs:
                  #find zip
                       plugSrcZip=src+"\\"+buildNum+"\\Release\\Full\\_Zips\\mw-"+plug+"-"+buildNum[9:]+".zip"
                       zip=zipfile.ZipFile(plugSrcZip)
                       zip.extractall(dst)
                  #unzip zip in dst



class ConfigFactory():
    """Class to configure configs - web.config sql.ini etc""" 


             
    @staticmethod
    def ChangeConnectString(SettingsObj,FileType):
   
          """Static method to change conn string in ini or web.config file"""

          







          #find pathes to all branches and concatenate
        

          for name,src,dst,conn,plugs in SettingsObj.GetBuildPaths():
             
       
 
             
              if FileType=="sql.ini":
                  connStringEth=r"remotedbname=IL2009,DRIVER=SQL Server;SERVER=s15\interlook08;DATABASE=IL2009;Trusted_Connection=no;APP=Master-Tour"
                  connString="remotedbname="+ conn["remotedbname"]+",DRIVER=SQL Server;SERVER="+conn["SERVER"]+";DATABASE="+conn["DATABASE"]+";Trusted_Connection=no;APP=Master-Tour"
                  
                  print (connStringEth)



                  
              elif FileType=="web.config":

                  connStringEth="Data Source=ip-адрес сервера; Initial Catalog=название базы;User Id=логин пользователя;Password=пароль"
                  connString="Data Source="+conn["SERVER"]+"; Initial Catalog="+conn["DATABASE"]+";User Id="+conn["UserID"]+";Password="+ conn["Password"]
                 



                

              the_file=open(dst+"\\"+FileType,"r+",encoding='UTF8')


              the_file2=open(dst+"\\"+FileType+".new","w",encoding='UTF8')
            

              for line in the_file.readlines(): 
                   print (line.replace(connStringEth,connString),end="",file=the_file2)

  

 
              the_file.close()
              the_file2.close()

              os.remove(dst+"\\"+FileType);
              os.rename(dst+"\\"+FileType+".new",dst+"\\"+FileType)

               
if __name__ == "__main__":
    from DataAdaptor import XMLAdaptor as XA
    conf=XA("MW.config")
 
    FileFactory.CopyFilesPlugins(conf)

  



