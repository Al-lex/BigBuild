
from DataAdaptor import XMLAdaptor as XA

def Main():
    conf=XA("MW.config")

    conf.GetGlobalSettings()
    conf.GetPlugins()
    #config = configparser.ConfigParser()
    #config.read('MW.ini')
    
   
    #connection = config['WEBCONFIG']['connection']
    #email = config['WEBCONFIG']['email']
    #smtp_server = config['WEBCONFIG']['smtp_server']

    #settings=connection,email,smtp_server
    #print (type(connection))
  
   
Main()

    




