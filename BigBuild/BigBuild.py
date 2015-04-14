import logging
logging.basicConfig(format='%(asctime)s %(message)s',filename='UpdateLog.log',level=logging.DEBUG)
from DataAdaptor import Model as XA
from DataAdaptor import Controller
from DataAdaptor import ConfigFactory
from IISManager import IISManager
from DBManager import DBUpdater
import os
import shutil
import sys
import subprocess
#import subprocess

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
##http://kawaikunee.blogspot.ru/2013/04/python.html
class View():
    """Class representing top level calls for inner functionality"""
    @staticmethod
    def Go(args):
        """Method to build up sequence of operations"""
        logging.info("Started update session")
        conf=XA("MW.config")
        if '1' in args:
         
            #print("Kill IE seesion")
            #os.system("taskkill /im iexplore.exe")
       
            #print ('\033[36mCYANCOLOR\033[0m')
            print(bcolors.WARNING + "Begin work with database"+ bcolors.ENDC)
            #logging.info('Begin update DB')
            DBUpdater.execUpdateFilesForBranches(conf)

            
            #logging.info('DB update finished - see details in log.txt')
   
        if '2' in args:
            #logging.info('Begin file copy')
            #some temporary nail in the ass - need refactoring after payment service will be in build
            print("Begin remove payment service")
            is_stop=Controller.StopPaymentService()


            print("Begin work with web files")
            Controller.CopyFilesBuild(conf)
            #logging.info('Begin unzip files')
            #Controller.UnzipFilesBuild(conf)
            print("Begin work with static files")
            Controller.CopyStaticDir(conf)

            print("Begin work with payment config")

            ConfigFactory.ChangeConnectString(conf,"Megatec.PaymentSignatureServiceHost.exe.config",False)
            #another temp nail in the ass - need refactoring after payment service will be in build
            print("Begin install and start payment service")
            if not(is_stop):       
                Controller.InstallPaymentService(conf)
            else:
                Controller.StartPaymentService()
        
            print("Begin work with config for web")

            #logging.info('Begin update web.config')
            ConfigFactory.ChangeConnectString(conf,"web.config",False)
            #logging.info('Finish update web.config')
        if '3' in args:
            print("Begin work with plugins")
            #logging.info('Begin get plugins')
            Controller.CopyFilesPlugins(conf)
            #logging.info('Finish get plugins')
        if '4' in args:
            print("Begin work with extra files")
            #logging.info('Begin get extra files')
            Controller.CopyFilesExtraForMW(conf)
            #logging.info('Finish get extra files')

            #logging.info('Set up site on IIS')
        if '5' in args:
            print("Begin install web app on IIS")
            #IISManager.CreateSite(conf)
            IISManager.CreateWebApp(conf)
        
            #logging.info('Finish set up site on IIS')
        if '6' in args:
            #logging.info('Set up web-services')
            print("Begin install web services on IIS")
            Controller.ProcessFilesServices(conf)
            IISManager.CreateWebServices(conf)
            print("Begin work with  web services configs")
            ConfigFactory.ChangeConnectString(conf,"web.config",True)
            #logging.info('Finished web services')

            logging.info('Finished update session')

            print("All is finished!!!")
        if 'a' in args:
            #run selenium autotests
            retcode=subprocess.call(os.getcwd()+"\\run_functional_avtotests.bat", shell=True)
            if retcode == 0:
                 print ("successfuly func launch autotests")
            else:
                 print ("failure launch func autotests")   
        if 't' in args:
            print("Start test procedures")
            #run SoapUI tests
            for line in os.listdir("E:\\SoapUI"):
                if (line[-3:]=="txt"):
                    os.remove("E:\\SoapUI\\"+line)

            services_under_test=[]
            ##Finance
            services_under_test.append("FinanceService-soapui-project")
            ##FilterBinding
            services_under_test.append("FilterBindingService-soapui-project")
            ##megatecwebservices
            #search
            services_under_test.append("Search-soapui-project")
            #rates
            services_under_test.append("Rates-soapui-project")
            #Booking manager
            services_under_test.append("BookingManager-soapui-project")
            ##authservice
            services_under_test.append("Auth-soapui-project")
            ##aviasearch
            services_under_test.append("TicketSearchService-soapui-project")
            ##checkquotes
            services_under_test.append("CheckQuotesService-soapui-project")


            for serv in services_under_test:

                 print ("Check "+serv+" web-service")
                 os.system("\"C:\\Program Files (x86)\\SmartBear\\SoapUI-5.0.0\\bin\\testrunner.bat\" -r E:\\SoapUI\\"+serv+".xml")

      
            #check if err report has been created
            for line in os.listdir("E:\\SoapUI"):
                if (line[-3:]=="txt"):
                    print("Some tests are failed - see details in E:\SoapUI")




if __name__ == "__main__":
    #change codepage for cyrillic complience
    #retcode=subprocess.call("chcp 857", shell=False,stderr=subprocess.PIPE)
    #if retcode == 0:
    #    print ("Successfuly changed encoding")
    #else:
    #    print ("Failure change encoding") 
    os.system("chcp 857")
    if len (sys.argv) > 1:
         print ("Will be exexuted following steps: {}!".format (sys.argv) )
         View().Go(sys.argv)
    else:
         print ("All steps will be executed")
         View().Go(['1','2','3','4','5','6'])

    

    




