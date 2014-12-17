import os
from os import listdir
from os.path import isfile
from os.path import join as joinpath
import shutil

import zipfile
import pymssql


class DBUpdater(object):
    """Class to update db up to the chosen version"""
    @staticmethod
    def GetCurrentDBVersion():
        
        conn = pymssql.connect(host='localhost', user='sa', password='sa', database='avalon')
        cursor = conn.cursor()
        sql = "select st_version from setting"
        cursor.execute(sql)
        results = cursor.fetchall()
                     
        return results[0]
      



    @staticmethod
    def CreateScriptsForDBUpdateServicePack(pathbase,foldername,server,database,userid,password):
                    """Method to update local DB with scripts from servicepack 
                     -pathbase -path to the branch
                     -pathtempscripts - path to the local folder for scripts
                     returns path to the bat file with update"""
                   # pathbase = r"\\bg\Builds\Master-Tour\Release"
                    
                   #search 
                    l=listdir(pathbase)
                    l2=[]
                    for i in l:
                        if "Release9.2.20." in i:
                            if i[:16][-1]=="(":
                                 i=i[:14]+"0"+i[14]
                                 l2.append (i[:16])
                                
                            else:
                                 l2.append (i[:16])

                    l2.sort()


                    #??????????? ? ?????????? ? ?????????? ???? ? ?????? 
                    for i2 in l:
                        if l2[-1] in i2:
                           # pathtozips=r'\\bg\\Builds\\Master-Tour\\Release\\'+i2
                           pathtozips=pathbase+i2


                    #path to zip
                    l3=listdir(pathtozips)

                    for i3 in l3:
                       if "scripts" in i3:
                           fullpathtozip=pathtozips+r"\\"+i3

                    #unzip ? ???????? ?????
                    #tempscrpts='E:\TEMPSCRPTS'
                    pathtempscripts=os.getcwd()+"\\"+foldername+"scripts"

                    if os.path.exists( pathtempscripts):
                     shutil.rmtree(pathtempscripts)


                    os.mkdir(pathtempscripts)



                    zip=zipfile.ZipFile(fullpathtozip)
                    zip.extractall(pathtempscripts)

                    #??????? ????

       

                    l4=[ln1 for ln1 in listdir(pathtempscripts) if "ReleaseScript2009.2.20." in ln1]



               

                    l5=[]
                    for ln2 in l4:
                        if ln2[-6]==".":
                            ln2=ln2[:-5]+"0"+ln2[-5:]
                            l5.append(ln2)

                        else:
                            l5.append(ln2)  


                    l6=[ln2 for ln2 in l5 if ln2[-6:-4]>"21"]

          
                    print(l6)



                    #Create temp bat file
                    tempfolder=os.getcwd()+"\\"+foldername
                    if os.path.exists(tempfolder):
                      shutil.rmtree(tempfolder)


                    os.mkdir(tempfolder)

                    ##
                    updstring1="\"C:\\Program Files (x86)\\Microsoft SQL Server\\100\\Tools\\Binn\S\QLCMD.EXE\" -S "+server+" -d "+database+" -U "+userid+" -P "+password+" -i "+os.getcwd()+"\\"+foldername+"scripts\\"
                    upddstring2=" -o \""+os.getcwd()+"\\"+foldername+"\\resultrestor.txt\""


                    l7=[]
                    for line in l6:
                       l7.append(updstring1+line+upddstring2)
                    ##
                    ##print(l5)
                    finalfile=open(os.getcwd()+"\\"+foldername+"\\ready.bat","w")
                    for line in l7:
                            finalfile.writelines(line)
                            finalfile.writelines("\n")
                            finalfile.writelines("timeout 3")
                            finalfile.writelines("\n")



                    finalfile.close() 
                   #returns path to executable for update of sql
                    return os.getcwd()+"\\"+foldername+"\\ready.bat"      
    @staticmethod
    def execUpdateFilesForBranches(SettingsObj):
         
         for name,src,dst,conn,plugs,iis,mtdata in SettingsObj.GetBuildPaths():
                       print(src)
                       os.system(DBUpdater.CreateScriptsForDBUpdateServicePack(mtdata["MTpathToLatest"],name,conn["SERVER"],conn["DATABASE"],"sa",mtdata["saPassword"]))

if __name__ == "__main__":
    from DataAdaptor import XMLAdaptor as XA
    conf=XA("MW.config")
    DBUpdater.execUpdateFilesForBranches(conf)