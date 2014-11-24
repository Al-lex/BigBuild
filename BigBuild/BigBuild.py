import configparser

def Main():
    config = configparser.ConfigParser()
    config.read('MW.ini')
    
    #?????????? ?? ??????? ????????? ??? web.config
    connection = config['WEBCONFIG']['connection']
    email = config['WEBCONFIG']['email']
    smtp_server = config['WEBCONFIG']['smtp_server']

    settings=connection,email,smtp_server
    print (type(connection))
  
   
Main()

    




