import xml.etree.ElementTree as ET
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
    def GetGlobalSettings(self):
        """Gets only globals section"""
        #for child in self.GetConfigTree():
        #     print (child.tag, child.attrib)
        for branch in self.GetConfigTree().findall("branch"):
                 name = branch.get('name')
                 pathToLatest = branch.find('pathToLatest').text

                 pathToLocal=branch.find('pathToLocal').text
                
                 print (name, pathToLatest,pathToLocal)

    def GetPlugins(self):
        for plugin in self.GetConfigTree().findall("Plugins"):
                 pluginname=plugin.find('plugin').get('name')

                 print(pluginname)




