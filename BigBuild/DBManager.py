import os
from os import listdir
from os.path import isfile
from os.path import join as joinpath
import shutil
import zipfile
import pymssql
import unittest


class DBUpdater(unittest.TestCase):
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
    def test_GetCurrentDBVersion(self):
        from DataAdaptor import Model as XA
        conf=XA("MW.config")
        #TBD take settings from XA and validate version format in DB
        for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in conf.GetBuildPaths():
            version=self.GetCurrentDBVersion(conn["SERVER"],conn["UserID"],conn["Password"],conn["DATABASE"])
            self.assertEqual(mtdata["Release"][-6:],version[0:6],"Check database version of Main_del - must be release "+mtdata["Release"][-6:])
    
    @staticmethod
    def create_scripts_between_releases(conf):
        """Method need to find out intermediate release scripts
        """
        release_scripts={}
        for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails in conf.GetBuildPaths():
                version=DBUpdater.GetCurrentDBVersion(conn["SERVER"],conn["UserID"],conn["Password"],conn["DATABASE"]) #get current db version and compare with those in settings file
            #if (mtdata["Release"][-6:]!=version[0:6]):#means that database is behind of current release
                #\\bg\Builds\Master-Tour\Release\Release9.2.20.26(150303)\MasterTour9.2.20.60486-scripts.zip
                #need to find all releases except version
                releases=os.listdir("\\\\bg\\Builds\\Master-Tour\\Release")
                releasescorrected=[]
                #correct names if one digit number i.e. if 1 then 01
                for line in releases:
                  if line[0:8]=="Release9":#take 9.2 releases only
                    if line[-10]==".":
                        releasescorrected.append(line[0:-9]+"0"+line[-9:])
                        print (line[0:-9]+"0"+line[-9:])
                    else:
                        releasescorrected.append(line)

                releasescorrected.sort()
                templine=""
                #find splititem
                for line in releasescorrected:
                    if version in line:
                        templine=line
                        break
                split_index=releasescorrected.index(templine)


                release_scripts[name]=releasescorrected[split_index:]
                print (release_scripts)
        #need to find out the right way - in the current state it does not work
        return release_scripts
    @staticmethod
    def CreateScriptToRestoreDB(pathbase,foldername,server,database,sauserid,sapassword,pathToBak,isRestore,release,isupdatelast):
        if isRestore=="true":
            line_kill_conn="\"C:\\Program Files\\Microsoft SQL Server\\110\\Tools\\Binn\SQLCMD.EXE\" -S "+server+" -d master -U "+sauserid+" -P "+sapassword+" -i "+os.getcwd()+"\\Clear_connect.sql -v dbname='"+database+"'"
            line="\"C:\\Program Files\\Microsoft SQL Server\\110\\Tools\\Binn\\SQLCMD.EXE\" -S "+server+" -d master -U sa -P "+sapassword+ " -Q \""+"RESTORE DATABASE ["+database+"] FROM  DISK = N\'"+pathToBak+"\' WITH  FILE = 1,  NOUNLOAD,  STATS = 5\"" #-I -R >> \""+os.getcwd()+"\\"+foldername+"\\resultrestor.txt\" -f i:65001"
            
            finalfile=open(os.getcwd()+"\\"+foldername+"\\readyDB.bat","w") 
            finalfile.writelines(line_kill_conn)
            finalfile.writelines("\n")
            finalfile.writelines("timeout 3")
            finalfile.writelines("\n")
            finalfile.writelines(line)
            finalfile.writelines("\n")
            finalfile.writelines("timeout 3")
            finalfile.writelines("\n")
            finalfile.close()           
        else:
            finalfile=open(os.getcwd()+"\\"+foldername+"\\readyDB.bat","w")
            lune="echo It was false setting for DB Restore - restore is aborted"
            finalfile.writelines(line)
            finalfile.close()  
        return os.getcwd()+"\\"+foldername+"\\readyDB.bat"

    @staticmethod
    def CreateScriptsForDBUpdateServicePack(pathbase,foldername,server,database,sauserid,sapassword,pathToBak,isRestore,release,isupdatelast):
                    """Method to update local DB with scripts from servicepack 
                     -pathbase -path to the branch
                     -pathtempscripts - path to the local folder for scripts
                     returns path to the bat file with update"""
                                                                  
                    l=listdir(pathbase)

                    l2=[]
                    for i in l:
                        if release[-6:] in i:
                            if i[:16][-1]=="(":
                                 i=i[:14]+"0"+i[14]
                                 l2.append (i[:16])
                                
                            else:
                                 l2.append (i[:16])
                    l2.sort()
        
                    l_new=[]
                    part_of_name_folder=l2[-1]
                    if  part_of_name_folder[-2]=="0":
                        part_of_name_folder=part_of_name_folder[:-3]+"."+part_of_name_folder[-1:]                

                    for i in l:                                                           
                        if part_of_name_folder in i:
                            l_new.append(i)
                    print(l_new)
                    pathtozips=pathbase+l_new[0]#i2

                    #path to zip
                    l3=listdir(pathtozips)
                    for i3 in l3:
                        if "scripts" in i3:
                            fullpathtozip=pathtozips+r"\\"+i3
                    #unzip 
                    #tempscrpts='E:\TEMPSCRPTS'
                    pathtempscripts=os.getcwd()+"\\"+foldername+"scripts"
                    if os.path.exists( pathtempscripts):
                        shutil.rmtree(pathtempscripts)
                    os.mkdir(pathtempscripts)
                    zip=zipfile.ZipFile(fullpathtozip)
                    zip.extractall(pathtempscripts)

                    l4=[ln1 for ln1 in listdir(pathtempscripts) if "ReleaseScript"+release+"." in ln1]#2009.2.20
                    l5=[]
                    for ln2 in l4:
                        if ln2[-6]==".":
                            ln2=ln2[:-5]+"0"+ln2[-5:]
                            l5.append(ln2)
                        else:
                            l5.append(ln2)  

                    #l6=[ln2 for ln2 in l5 if ln2[-6:-4]>"21"]#take only scripts to update from current db
                    currentServicePackVersion=DBUpdater.GetCurrentDBVersion(server,sauserid,sapassword,database)[-2:]


                    print("Current db:"+currentServicePackVersion)
                    #insert only version numbers higher then current
                    l6=[ln2 for ln2 in l5 if int(ln2[-6:-4])>int(currentServicePackVersion)]
                    l6.sort(reverse=False)
                     
                    #Create temp bat file
                    tempfolder=os.getcwd()+"\\"+foldername
                    if os.path.exists(tempfolder):
                      shutil.rmtree(tempfolder)
                    os.mkdir(tempfolder)                  
                    ##
                    
                    updstring1="\"C:\\Program Files\\Microsoft SQL Server\\110\\Tools\\Binn\SQLCMD.EXE\" -S "+server+" -d "+database+" -U "+sauserid+" -P "+sapassword+" -i "+os.getcwd()+"\\"+foldername+"scripts\\"
                    upddstring2=" -I -R >> \""+os.getcwd()+"\\"+foldername+"\\resultrestor.txt\" -f i:65001"

                    l7=[]
                    #if(isRestore=="true"):
                    updstring="\"C:\\Program Files\\Microsoft SQL Server\\110\\Tools\\Binn\SQLCMD.EXE\" -S "+server+" -d master -U "+sauserid+" -P "+sapassword+" -i "+os.getcwd()+"\\Clear_connect.sql -v dbname='"+database+"'"
                        #updstring0="\"C:\\Program Files\\Microsoft SQL Server\\110\\Tools\\Binn\\SQLCMD.EXE\" -S "+server+" -d master -U sa -P "+sapassword+ " -Q \""+"RESTORE DATABASE ["+database+"] FROM  DISK = N\'"+pathToBak+"\' WITH  FILE = 1,  NOUNLOAD,  STATS = 5\"" #-I -R >> \""+os.getcwd()+"\\"+foldername+"\\resultrestor.txt\" -f i:65001"
                    l7.append(updstring)
                        #l7.append(updstring0)

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
                    #if(isRestore=="true"):
                    #    print(l7[2:])
                    #else:
                    print(l7)
                    finalfile=open(os.getcwd()+"\\"+foldername+"\\ready.bat","w")                    
                    for line in l7:
                            finalfile.writelines(line)
                            finalfile.writelines("\n")
                            finalfile.writelines("timeout 3")
                            finalfile.writelines("\n")
                    if (isupdatelast=="true"):
                      #line2="\\\\bg\\builds\\Master-Tour\\"+foldername+"_MasterTour\\LastBuild\\Scripts\\ReleaseScript.sql"
                      line2=pathbase[:-9]+"\\"+foldername+"_MasterTour\\LastBuild\\Scripts\\ReleaseScript.sql"
                      updstring3="\"C:\\Program Files\\Microsoft SQL Server\\110\\Tools\\Binn\SQLCMD.EXE\" -S "+server+" -d "+database+" -U "+sauserid+" -P "+sapassword+" -i "                      
                      finalfile.writelines( updstring3+line2+upddstring2)
                    finalfile.close() 
                
                   #returns path to executable for update of sql
                    return os.getcwd()+"\\"+foldername+"\\ready.bat" 
                     
    @staticmethod
    def execUpdateFilesForBranches(SettingsObj):
         
         for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails  in SettingsObj.GetBuildPaths():
                       #print(src)
                       #if (conn["isRestore"]):
                       #    DBUpdater.RestoreDB(conn["SERVER"],conn["sapassword"],conn["DATABASE"],conn["pathToBak"])
                       os.system(DBUpdater.CreateScriptToRestoreDB(mtdata["MTpathToLatest"],name,conn["SERVER"],conn["DATABASE"],"sa",mtdata["saPassword"],conn["pathToBak"],conn["isRestore"],mtdata["Release"],isLastBuild))
                       os.system(DBUpdater.CreateScriptsForDBUpdateServicePack(mtdata["MTpathToLatest"],name,conn["SERVER"],conn["DATABASE"],"sa",mtdata["saPassword"],conn["pathToBak"],conn["isRestore"],mtdata["Release"],isLastBuild))
                    
                       print("See details on dbupdate in "+os.getcwd()+"\\"+name+"\\"+"resultrestor.txt")
                       logfile=open(os.getcwd()+"\\"+name+"\\resultrestor.txt","r") 
                       for line in logfile.readlines():
                                    print(line)
                       logfile.close()

    

if __name__ == "__main__":
    from DataAdaptor import Model as XA
    conf=XA("MW.config")

    DBUpdater.create_scripts_between_releases(conf)
    #unittest.main()
    #DBUpdater.GetCurrentDBVersion('localhost','sa','sa','avalon')
