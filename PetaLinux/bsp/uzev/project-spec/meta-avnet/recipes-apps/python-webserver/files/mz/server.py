#!/usr/bin/python3

"""
Save this file as server.py
>>> python3 server.py
Serving on localhost:80
You can use this to test GET and POST methods.
"""

import http.server
import socketserver
import logging
import cgi
import sys
import re
import subprocess
import time, struct


###
# There is just one user LED (D3) on the MicroZed SOM and it is mapped to MIO47 on the PS (Zynq pin B14)
# PS GPIO is at base 906
# PS LED is at base + 47, so 906 + 47 = 953
###

# add path helper script
import sys
sys.path.insert(1, '/usr/local/bin/gpio')
from gpio_common import gpio_map

LED1Portnumber = gpio_map['PL_LED1'].gpio
LED1Path = '/sys/class/gpio/gpio' + LED1Portnumber + '/value'

if len(sys.argv) > 2:
    PORT = int(sys.argv[2])
    I = sys.argv[1]
elif len(sys.argv) > 1:
    PORT = int(sys.argv[1])
    I = ""
else:
    PORT = 80
    I = ""

class ServerHandler(http.server.SimpleHTTPRequestHandler):

    def do_GET(self):
        logging.warning("======= GET STARTED =======")
        logging.warning(self.headers)
	
        http.server.SimpleHTTPRequestHandler.do_GET(self)

    def do_POST(self):
        logging.warning("======= POST STARTED =======")
        logging.warning(self.headers)
        form = cgi.FieldStorage(
            fp=self.rfile,
            headers=self.headers,
            environ={'REQUEST_METHOD':'POST',
                     'CONTENT_TYPE':self.headers['Content-Type'],
                     })
        logging.warning("Host: %s", form.getvalue('Host'));

        if (form.getvalue('SETPLLED')):
            ledChosen = form.getvalue('PLledSel')
            logging.warning("PL LED Setting is %s", ledChosen)
            with open(LED1Path,'w') as LEDFile:
                LEDFile.write('1' if int(ledChosen) == 1 else '0')

        #if (form.getvalue('GETPLSW')):
            #SW0Portnumber = str(504)
            #SW1Portnumber = str(505)
            #SW2Portnumber = str(506)
            #SW3Portnumber = str(507)
            #SW4Portnumber = str(508)
            #SW5Portnumber = str(509)
            #SW6Portnumber = str(510)
            #SW7Portnumber = str(511)
            #SW0Path = '/sys/class/gpio/gpio' + SW0Portnumber + '/value'
            #SW1Path = '/sys/class/gpio/gpio' + SW1Portnumber + '/value'
            #SW2Path = '/sys/class/gpio/gpio' + SW2Portnumber + '/value'
            #SW3Path = '/sys/class/gpio/gpio' + SW3Portnumber + '/value'
            #SW4Path = '/sys/class/gpio/gpio' + SW4Portnumber + '/value'
            #SW5Path = '/sys/class/gpio/gpio' + SW5Portnumber + '/value'
            #SW6Path = '/sys/class/gpio/gpio' + SW6Portnumber + '/value'
            #SW7Path = '/sys/class/gpio/gpio' + SW7Portnumber + '/value'
            #SW0File= open (SW0Path,'r')
            #SW1File= open (SW1Path,'r')
            #SW2File= open (SW2Path,'r')
            #SW3File= open (SW3Path,'r')
            #SW4File= open (SW4Path,'r')
            #SW5File= open (SW5Path,'r')
            #SW6File= open (SW6Path,'r')
            #SW7File= open (SW7Path,'r')
            ##time.sleep(0.5)
            #SW0VAL = SW0File.read()
            #SW1VAL = SW1File.read()
            #SW2VAL = SW2File.read()
            #SW3VAL = SW3File.read()
            #SW4VAL = SW4File.read()
            #SW5VAL = SW5File.read()
            #SW6VAL = SW6File.read()
            #SW7VAL = SW7File.read()
            #SW8BITS = str(SW7VAL) + str(SW6VAL) + str(SW5VAL) + str(SW4VAL) + str(SW3VAL) + str(SW2VAL) + str(SW1VAL) + str(SW0VAL)
            #return SW8BITS
            #SW0File.close()
            #SW1File.close()
            #SW2File.close()
            #SW3File.close()
            #SW4File.close()
            #SW5File.close()
            #SW6File.close()
            #SW7File.close()
			

Handler = ServerHandler
httpd = socketserver.TCPServer(("", PORT), Handler)
httpd.serve_forever()
