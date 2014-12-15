import logging
logging.basicConfig(format='%(asctime)s %(message)s',filename='UpdateLog.log',level=logging.DEBUG)
from DataAdaptor import XMLAdaptor as XA
from DataAdaptor import FileFactory
from DataAdaptor import ConfigFactory




def Go():
    logging.info('Begin update process')
    logging.info('Begin copy files')
    conf=XA("MW.config")
    FileFactory.CopyFilesBuild(conf)
    logging.info('Begin unzip files')
    FileFactory.UnzipFilesBuild(conf)

    logging.info('Begin update web.config')
    ConfigFactory.ChangeConnectString(conf,"web.config")
    logging.info('Finished')




if __name__ == "__main__":
     Go()
    

    




