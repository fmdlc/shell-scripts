#!/usr/bin/env python
# Send mail using Google account.

import os
import sys
import smtplib
import mimetypes
import ConfigParser
import syslog
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText

def Log(priority,event):
  syslog.openlog('python mail',syslog.LOG_PID,syslog.LOG_DAEMON) 
  syslog.syslog(priority,event)
  syslog.closelog()


def sendMail(dst, subject, text):
  # Read configuration from config file.  
  filename = os.path.expanduser('~/alertas.conf')
  config = ConfigParser.ConfigParser()
  config.read([filename])
  
  if config.has_section('options'):
    gMailUser = config.get('options', 'username')
    gMailPass = config.get('options', 'password')
    gMailSMTP = config.get('options', 'smtp')
    gMailPort = config.get('options', 'smtp_port')
    gMailName = config.get('options', 'name')
  
  # Generate the message.
  msg = MIMEMultipart()
  msg['From'] = gMailName
  msg['Subject'] = subject
  msg.attach(MIMEText(text))
  
  # Connect to the SMTP and send mail.
  try:
    mailServer = smtplib.SMTP(gMailSMTP, gMailPort)
    mailServer.ehlo()
    mailServer.starttls()
    mailServer.ehlo()
    mailServer.login(gMailUser, gMailPass)
    mailServer.sendmail(gMailUser,list(sys.argv[1].split('\n')),msg.as_string())
    mailServer.close()
    
    Log(syslog.LOG_NOTICE,'UPS Event - An email was sent informing this.')

  except smtplib.SMTPAuthenticationError: 
    Log(syslog.LOG_NOTICE,'ERROR: Username or password not accepted. Learn more at http://mail.google.com/support/bin/answer.py?answer=14257.')

  except smtplib.SMTPHeloError:
    Log(syslog.LOG_NOTICE,'ERROR: The server didnt reply properly to the helo greeting.')

  except smtplib.SMTPRecipientsRefused:
    Log(syslog.LOG_NOTICE,'ERROR: The server rejected ALL recipients (no mail was sent).')

  except smtplib.SMTPSenderRefused:
    Log(syslog.LOG_NOTICE,'ERROR: The server didnt accept the from_addr.0')
  
  except smtplib.SMTPDataError:
    Log(syslog.LOG_NOTICE,'ERROR: The server replied with an unexpected error code (other than a refusal of a recipient).')  
  
  except:     
    Log(syslog.LOG_NOTICE,'ERROR: Generic connection error has success.')  

  else: 
    sys.exit(0) 

if __name__ == '__main__':
  connector = sendMail(sys.argv[1],sys.argv[2],sys.argv[3])
