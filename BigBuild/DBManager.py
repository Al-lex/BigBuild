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
   
    def GetCurrentDBVersion(host,user,password,database):
        """Method to return version of db from config - it runs dynamic script on db"""   
        conn = pymssql.connect(host=host, user=user, password=password, database=database)
        cursor = conn.cursor()
        sql = "select st_version from setting"
        cursor.execute(sql)
        results = cursor.fetchall()
        version=""
        if (results[0][0][-2]=="."):
            version=results[0][0][0:-2]+".0"+results[0][0][-1]
            print(version)
        else:
            version=results[0][0]
            print("Current db version is "+version)
              
        return version

    #@staticmethod
    #def UpdateLast(SettingsObj):
    #    """Updates db on last build script"""
    #    lastBuildScripts={}
    #    for name,src,dst,conn,plugs,iis,mtdata in SettingsObj.GetBuildPaths():
    #       pathToLastBuildScript="\\\\bg\\builds\\Master-Tour\\"+branchname+"_MasterTour\\LastBuild\\Scripts\\ReleaseScript.sql"
    #       lastBuildScripts[name]=pathToLastBuildScript
    #    retu

        

      



    @staticmethod
    def CreateScriptsForDBUpdateServicePack(pathbase,foldername,server,database,userid,password,release,isupdatelast):
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

       

                    l4=[ln1 for ln1 in listdir(pathtempscripts) if "ReleaseScript"+release+"." in ln1]#2009.2.20



               

                    l5=[]
                    for ln2 in l4:
                        if ln2[-6]==".":
                            ln2=ln2[:-5]+"0"+ln2[-5:]
                            l5.append(ln2)

                        else:
                            l5.append(ln2)  


                    #l6=[ln2 for ln2 in l5 if ln2[-6:-4]>"21"]#take only scripts to update from current db
                    currentServicePackVersion=DBUpdater.GetCurrentDBVersion(server,userid,password,database)[-2:]
                    #print(currentServicePackVersion)
                    #insert only version numbers higher then current
                    l6=[ln2 for ln2 in l5 if int(ln2[-6:-4])>int(currentServicePackVersion)]
                    l6.sort(reverse=False)
                    #print (l6)

                    #print(l6)
                    #return
                    #l6sorted=[]
                    #numbr=l6.count
                    #while numbr!=0:
                    #    l6sorted.append(( numbr,str(numbr)))
                    #    numbr=numbr-1
                  

                    
                   
                    


                    #Create temp bat file
                    tempfolder=os.getcwd()+"\\"+foldername
                    if os.path.exists(tempfolder):
                      shutil.rmtree(tempfolder)


                    os.mkdir(tempfolder)

                    ##
                    updstring1="\"C:\\Program Files\\Microsoft SQL Server\\110\\Tools\\Binn\SQLCMD.EXE\" -S "+server+" -d "+database+" -U "+userid+" -P "+password+" -i "+os.getcwd()+"\\"+foldername+"scripts\\"
                    upddstring2=" >> \""+os.getcwd()+"\\"+foldername+"\\resultrestor.txt\""


                    l7=[]
                    for line in l6:
                       #if release script number ends on 01 02 03 etc then change 1 2 3 etc 
                       if (line[-6]=="0"):
                           line2=line[0:-6]+line[-5:]
                           #print(line2)
                           l7.append(updstring1+line2+upddstring2)
                       else:
                           l7.append(updstring1+line+upddstring2)

                    ##
                    ##print(l5)
                    print("following servicepack scripts will be included in update:")
                    print(l7)
                    finalfile=open(os.getcwd()+"\\"+foldername+"\\ready.bat","w")
                    
                    for line in l7:
                            finalfile.writelines(line)
                            finalfile.writelines("\n")
                            finalfile.writelines("timeout 3")
                            finalfile.writelines("\n")
                    if (isupdatelast):
                      line2="\\\\bg\\builds\\Master-Tour\\"+foldername+"_MasterTour\\LastBuild\\Scripts\\ReleaseScript.sql"
                      updstring3="\"C:\\Program Files\\Microsoft SQL Server\\110\\Tools\\Binn\SQLCMD.EXE\" -S "+server+" -d "+database+" -U "+userid+" -P "+password+" -i "
                      
                      finalfile.writelines( updstring3+line2+upddstring2)

                    finalfile.close() 
                   #returns path to executable for update of sql
                    return os.getcwd()+"\\"+foldername+"\\ready.bat"      
    @staticmethod
    def execUpdateFilesForBranches(SettingsObj):
         
         for name,src,dst,conn,plugs,iis,mtdata,isLastBuild  in SettingsObj.GetBuildPaths():
                       #print(src)
                       os.system(DBUpdater.CreateScriptsForDBUpdateServicePack(mtdata["MTpathToLatest"],name,conn["SERVER"],conn["DATABASE"],"sa",mtdata["saPassword"],mtdata["Release"],isLastBuild))
                       print("See details on dbupdate in "+os.getcwd()+"\\"+name+"\\"+"resultrestor.txt")

if __name__ == "__main__":
    from DataAdaptor import XMLAdaptor as XA
    conf=XA("MW.config")
    
    DBUpdater.execUpdateFilesForBranches(conf)
     

    #DBUpdater.GetCurrentDBVersion('localhost','sa','sa','avalon')
