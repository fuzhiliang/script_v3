#!/usr/bin/python3

import smtplib
sender='fuzhl4317@berryoncology.com'
receivers=['fuzhl4317@berryoncology.com']

message = """From: From Person <sender>
To: To Person <receivers>
MIME-Version: 1.0
Content-type: text/html
Subject: SMTP HTML e-mail test

This is an e-mail message to be sent in HTML format

<b>This is HTML message.</b>
<h1>This is headline.</h1>
"""

try:
   smtpObj = smtplib.SMTP('mail.berryoncology.com')
   smtpObj.sendmail(sender, receivers, message)         
   print ("Successfully sent email")
except SMTPException:
   print ("Error: unable to send email")

##参考https://www.yiibai.com/python/python_sending_email.html

