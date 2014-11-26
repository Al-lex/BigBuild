import xml.etree.ElementTree as ET
from distutils import dir_util
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
        """Gets only globals section"""
        #for child in self.GetConfigTree():
        #     print (child.tag, child.attrib)
        files=[]
        for branch in self.GetConfigTree().findall("branch"):
                 files.append((branch.find("pathToLatest").text,branch.find("pathToLocal").text))
                 name = branch.get("name")
                 pathToLatest = branch.find("pathToLatest").text

                 pathToLocal=branch.find("pathToLocal").text
                
                 print (name, pathToLatest,pathToLocal)
        return files

    def GetPlugins(self):
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
       files=[]
       for service in self.GetConfigTree().findall("Services")[0].findall("service"):
           files.append((service.get("name"),service.get("getlocal")))
           name=service.get("name")
           getlocal=service.get("getlocal")
           print(name,getlocal) 
       return files     
    def GetFiles(self):
       files=[]
       for fl in self.GetConfigTree().findall("Files")[0].findall("file"):
           files.append((fl.get("name"),fl.get("getlocal")))
           name=fl.get("name")
           getlocal=fl.get("getlocal")
           print(name,getlocal) 
       return files
          
            
           
           
           
class FileCopyer():
       from DataAdaptor import XMLAdaptor as XA
       @staticmethod
       def CopyFiles(SettingsObj):
          if(isinstance(SettingsObj,XA)):
             for src,dst in SettingsObj.GetBuildPaths():
                          print(src,dst)
                          dir_util.copy_tree(src,dst)
          else:
              raise Exception("Not valid config object")


               
if __name__ == "__main__":
    from DataAdaptor import XMLAdaptor as XA
    conf=XA("MW.config")
    #print(isinstance(conf,XA))
    conf.GetBuildPaths()
    conf.GetPlugins()
    conf.GetServices()
    conf.GetFiles()

    FileCopyer.CopyFiles(conf)



