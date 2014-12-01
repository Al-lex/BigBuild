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
                 files.append((name, pathToLatest,pathToLocal))
                 print (name, pathToLatest,pathToLocal)
        return files

    def GetPlugins(self):
       """Gets plugins list from MW.config"""
       files=[]
       #print (self.GetConfigTree().findall("Plugins")[0].findall("plugin")[0].get("name"))
       #print (self.GetConfigTree().findall("Plugins")[0].findall("plugin")[1].get("name"))
       for plugin in self.GetConfigTree().findall("Plugins")[0].findall("plugin"):
           files.append((plugin.get("name"),plugin.get("getlocal")))
           name=plugin.get("name")
           getlocal=plugin.get("getlocal")
           print(name,getlocal)
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
           print(name,getlocal) 
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
          if(isinstance(SettingsObj,XA)):
             
           # try:
             for name,src,dst in SettingsObj.GetBuildPaths():
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
                          
          else:
              raise Exception("Not valid config object")
       @staticmethod
       def CopyFilesRelease(SettingsObj):
           """Static method to get in case of need files from release"""
           pass
       @staticmethod
       def UnzipFilesBuild(SettingsObj):
           """Static method to unzip getted files"""
           for name,src,dst in SettingsObj.GetBuildPaths():
                  lst=os.listdir(dst)
                  zip=zipfile.ZipFile(dst+"//"+lst[0])
                  zip.extractall(dst)


           


               
if __name__ == "__main__":
    from DataAdaptor import XMLAdaptor as XA
    conf=XA("MW.config")
    #print(isinstance(conf,XA))
    conf.GetBuildPaths()
    conf.GetPlugins()
    conf.GetServices()
    conf.GetFiles()
    FileFactory.CopyFilesBuild(conf)
    FileFactory.UnzipFilesBuild(conf)




