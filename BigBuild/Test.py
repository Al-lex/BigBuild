#import os
#import re
import unittest
from DataAdaptor import ConfigFactory
from DBManager import DBUpdater
class AllOfTheTests(unittest.TestSuite):
    def suite():
         
         suite = unittest.TestSuite()
         
         suite.addTests (unittest.makeSuite (ConfigFactory))#addtests from ConfigFactory
         suite.addTests (unittest.makeSuite (DBUpdater))#addtests from ConfigFactory

         return suite


#class ConfigFactory():
#    """Class to configure configs - web.config sql.ini etc""" 
             
#    @staticmethod
#    def ChangeConnectString(searchpattern):
   
#        for line in searchpattern:
                  
#                           filepath="C:\\TMP\\web.config"
#                           connString="abracadabra"
#                           the_file1=open(filepath,"r",encoding='UTF8')

#                           for line1 in the_file1.readlines():
#                               #connStringEth=re.search("Data Source=(.*)/>",line1)#??? ??????
#                               #connStringEth=re.search("Data Source=.*?;",line1)
#                               connStringEth=re.search(line,line1)
#                               #connStringEth2=re.search("[ ]Initial Catalog=.*?;",line1)

                              
#                               if not (connStringEth==None):
#                                  connStringEth1=connStringEth.group(0)
                                
#                                  #connStringEth=connStringEth1+connStringEth2

#                                  print(connStringEth1)
#                                  break
#                           the_file1.close()

#                           the_file=open(filepath,"r+",encoding='UTF8')
#                           the_file2=open(filepath+".new","w",encoding='UTF8')
                                                          
#                           for line in the_file.readlines():                                                             
#                               print (line.replace(connStringEth1,connString),end="",file=the_file2)  
                                              
#                           the_file.close()
#                           the_file2.close()
#                           os.remove(filepath);
#                           os.rename(filepath+".new",filepath)





if __name__ == "__main__":
    runner = unittest.TextTestRunner()

    test_suite = AllOfTheTests.suite()

    runner.run(test_suite)


   #searchpattern=[]
   #searchpattern.append("Data Source=.*?;")
   #searchpattern.append("[ ]Initial Catalog=.*?;")
   #ConfigFactory.ChangeConnectString(searchpattern)