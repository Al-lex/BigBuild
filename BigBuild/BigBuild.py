import logging
logging.basicConfig(format='%(asctime)s %(message)s',filename='UpdateLog.log',level=logging.DEBUG)
from DataAdaptor import XMLAdaptor as XA
from DataAdaptor import FileFactory
from DataAdaptor import ConfigFactory
from IISManager import IISManager
from DBManager import DBUpdater




def Go():
    logging.info('Begin update process')
    conf=XA("MW.config")

    logging.info('Begin update DB')
    DBUpdater.execUpdateFilesForBranches(conf)
    logging.info('DB update finished - see details in log.txt')


    logging.info('Begin file copy')
    FileFactory.CopyFilesBuild(conf)
    logging.info('Begin unzip files')
    FileFactory.UnzipFilesBuild(conf)

    logging.info('Begin update web.config')
    ConfigFactory.ChangeConnectString(conf,"web.config")
    logging.info('Finish update web.config')
    
    logging.info('Begin get plugins')
    FileFactory.CopyFilesPlugins(conf)
    logging.info('Finish get plugins')

    logging.info('Set up site on IIS')

    
    IISManager.CreateSite(conf)
    logging.info('Finish set up site on IIS')

    logging.info('Finished all')








if __name__ == "__main__":
     Go()
    

    




