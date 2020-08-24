#!/usr/bin/env python

import scapy.all import *
conf.verbose = 0

def tping(host,port,pktcount):
  scpin = IP(dst=host)/UDP(dport=port,sport=RandShort())
  waittime = 0.1        # need a waittime, or else srloop runs forever
  t1 = time.time()        # time the echo for RTT
  ans = srloop(scpin,timeout = waittime,count=pktcount)
  t2 = time.time()
  if ans == None:                   # is the host up?
    ret = 'Host is down'
  else:
    ret = 'Host is up'
  RTT = (t2-t1) / pktcount * 1000   # calculate RTT in milliseconds
  print ret," , approximate RTT is ", RTT, "ms"


syntax = "udping.py"+"\n"+"         Syntax: udping.py  desthost  port count"

if len(sys.argv) < 3:         # Did we get an ip and port at least?
  print syntax
  exit()
else:
  ip = sys.argv[1]
  port = int(sys.argv[2])
  if len(sys.argv) == 4:      # read in echo count, default is 5
    pktcount = int(sys.argv[3])
  else:
    pktcount = 5

  tping(ip, port, pktcount)
