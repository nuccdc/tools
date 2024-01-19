#!/bin/bash
# ./nmap_html.sh <subnet> <output_file>
if [ $# -ne 2 ]; then
  echo "Usage: $0 <subnet> <output_file>"
  exit 1
fi
# quit if not root
if [ $UID -ne 0 ]; then
  echo "You must be root to run this script."
  exit 2
fi
# quit if nmap is not installed
if [ ! -x /usr/bin/nmap ]; then
  echo "You must install nmap to run this script."
  exit 3
fi
# quit if xsltproc is not installed
if [ ! -x /usr/bin/xsltproc ]; then
  echo "You must install xsltproc to run this script."
  exit 4
fi
nmap -sS -O -oX /tmp/nmap_scan.xml $1
xsltproc /usr/share/nmap/nmap.xsl /tmp/nmap_scan.xml > $2
chmod 777 $2
