import logging
logging.basicConfig(format='%(asctime)s %(message)s',filename='UpdateLog.log',level=logging.DEBUG)
from DataAdaptor import Model as XA
from DataAdaptor import Controller
from DataAdaptor import ConfigFactory
from IISManager import IISManager
from DBManager import DBUpdater



class View():
    @staticmethod
    def Go():
        logging.info('Begin update process')
        conf=XA("MW.config")

        logging.info('Begin update DB')
        DBUpdater.execUpdateFilesForBranches(conf)
        logging.info('DB update finished - see details in log.txt')
   

        logging.info('Begin file copy')
        #some temporary nail in the ass - need refactoring after payment service will be in build

        is_stop=Controller.StopPaymentService()

        Controller.CopyFilesBuild(conf)
        #logging.info('Begin unzip files')
        #Controller.UnzipFilesBuild(conf)
   
        Controller.CopyStaticDir(conf)
        ConfigFactory.ChangeConnectString(conf,"Megatec.PaymentSignatureServiceHost.exe.config",False)
        #another temp nail in the ass - need refactoring after payment service will be in build
        if not(is_stop):       
            Controller.InstallPaymentService(conf)
        else:
            Controller.StartPaymentService()
    
    

    

        logging.info('Begin update web.config')
        ConfigFactory.ChangeConnectString(conf,"web.config",False)
        logging.info('Finish update web.config')
    
        logging.info('Begin get plugins')
        Controller.CopyFilesPlugins(conf)
        logging.info('Finish get plugins')


        logging.info('Begin get extra files')
        Controller.CopyFilesExtraForMW(conf)
        logging.info('Finish get extra files')

        logging.info('Set up site on IIS')

    
        #IISManager.CreateSite(conf)
        IISManager.CreateWebApp(conf)
        
        logging.info('Finish set up site on IIS')

        logging.info('Set up web-services')
        Controller.ProcessFilesServices(conf)
        IISManager.CreateWebServices(conf)
        ConfigFactory.ChangeConnectString(conf,"web.config",True)
        logging.info('Finished web services')

        logging.info('Finished all')

        print("All is finished!!!")








if __name__ == "__main__":
     View().Go()
    

    




