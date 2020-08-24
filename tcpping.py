#!/usr/bin/env python
from scapy.all import *
conf.verbose = 0

def tping(host,port,pktcount):
  scpin = IP(dst=host)/TCP(dport=port,sport=RandShort(),seq=RandShort(),flags="S")
  waittime = .1
  t1 = time.time()
  ans = srloop(scpin,timeout = waittime,count=pktcount)
  t2 = time.time()
  if ans == None:
    ret = 'Host is down'
  else:
    ret = 'Host is up'
  RTT = (t2-t1) / pktcount * 1000
  print ret," , approximate RTT is ", RTT, "ms"
syntax = "tcping.py"+"\n"+"         Syntax: tcping.py  desthost  port"
if len(sys.argv) < 3:
  print syntax
  exit()
else:
  ip = sys.argv[1]
  port = int(sys.argv[2])
  if len(sys.argv) == 4:
    pktcount = int(sys.argv[3])
  else:
    pktcount = 5
  tping(ip, port, pktcount)
