#script to get all available services and plugins in branch
from DataAdaptor import Model as XA
import os
import zipfile
import shutil
conf=XA("MW.config")
#1/ Search services in LastBuild

for name,src,dst,conn,plugs,iis,mtdata,isLastBuild,servicedetails  in conf.GetBuildPaths():
    buildNum=conf.GetLastBuildNumber(src)
    services=[]
    plugins=[]
    src=src+"\\"+buildNum+"\\Release\\Full\\_Zips\\"
    for name1 in os.listdir(src):
         tempfolder=os.getcwd()+"\\"+name1[:-4]
         if os.path.exists(tempfolder):
                      shutil.rmtree(tempfolder)
         os.mkdir(tempfolder) 
         zip=zipfile.ZipFile(src+name1)
         zip.extractall(tempfolder) 
         if (("web.config" in os.listdir(tempfolder)) or ("Web.config" in os.listdir(tempfolder))):
                  services.append(name1)
                  #print(name)
         else:
                  plugins.append(name1)
                 # print(name)
         shutil.rmtree(tempfolder)
    print("Services:")
    print (services)
    print("Plugins:")
    print (plugins)

    finalfile=open(os.getcwd()+"\\"+name+"_servplag.txt","w+")  
    finalfile.writelines("<Services>")
    finalfile.writelines("\n")
    for line in services:
         if (line[0:5]=="mw-ws"):
             finalfile.writelines("<Service name=\""+line[6:-17]+"\" localname=\""+line[6:-17]+"\" apppool=\"DefaultAppPool\" getlocal=\"true\"/>")
             finalfile.writelines("\n")
         elif((line[0:3]=="mw-") or (line[0:3]=="ws-")):
             finalfile.writelines("<Service name=\""+line[3:-17]+"\" localname=\""+line[3:-17]+"\" apppool=\"DefaultAppPool\" getlocal=\"true\"/>")
             finalfile.writelines("\n")
         else:
             finalfile.writelines("<Service name=\""+line[0:-17]+"\" localname=\""+line[0:-17]+"\" apppool=\"DefaultAppPool\" getlocal=\"true\"/>")
             finalfile.writelines("\n")
    finalfile.writelines("</Services>")
    finalfile.writelines("\n")
    finalfile.writelines("<Plugins>")
    finalfile.writelines("\n")
    for line in plugins:
        if (line[0:5]=="mw-ws"):
              finalfile.writelines("<plugin name=\""+line[5:-17]+"\" getlocal=\"true\"/>")
              finalfile.writelines("\n")
        elif((line[0:3]=="mw-") or (line[0:3]=="ws-")):
              finalfile.writelines("<plugin name=\""+line[3:-17]+"\" getlocal=\"true\"/>")
              finalfile.writelines("\n")
        else:
              finalfile.writelines("<plugin name=\""+line[0:-17]+"\" getlocal=\"true\"/>")
              finalfile.writelines("\n")

    finalfile.writelines("</Plugins>")
    finalfile.close()
    print("Ready!")
         

      
#2/ Search plugins in LastBuild