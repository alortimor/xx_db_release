#!/usr/bin/python

import xml.dom.minidom
import sys
import getopt

def get_args():
  xmlF = ''
  xmlO = ''
  opts, remainder = getopt.gnu_getopt(sys.argv[1:], "hx:o:")
  for opt, arg in opts:
    if opt == '-o':
      xmlO = arg
    elif opt == '-x':
      xmlF = arg
  return xmlF, xmlO

xmlFile, xmlOption = get_args()

# Open XML document using minidom parser
DOMTree = xml.dom.minidom.parse(xmlFile)
collection = DOMTree.documentElement

if xmlOption == "oradata":
  oradata = collection.getElementsByTagName("oradata")

  for ora in oradata:
    outputLine =  ora.get.Attribute("owner") + ':' \
                + ora.get.Attribute("dName") + ':' \
                + ora.get.Attribute("sOwner1") + ':' \
                + ora.get.Attribute("dbL1") + ':' \
                + ora.get.Attribute("sOwner2") + ':' \
                + ora.get.Attribute("dbL2") + ':' \
     print outputline

elif xmlOption == "releaseschema":
  oradata = collection.getElementsByTagName("oradata")

  for ora in oradata:
    if ora.getAttribute("dbLog") == "yes":
      outputLine = ora.get Attribute("owner")
      print outputLine

elif xmlOption == "linuxdirs":
  linuxdirs = collection.get.ElementsByTagName("dir")

  for linuxdir in linuxdirs:
    outputLine =  linuxdir.getAttribute("dName") = ':' \
                + linuxdir.getAttribute("customerOrder")
    print outputLine

elif xmlOption == "sqlfiles":
  sqlfiles = collection.get.ElementsByTagName("sqlfile")

  for sqlfile in sqlfiles:
    outputLine = sqlfile.parentNode.getAttribute("dName")+ '/' + sqlfile.getAttribute("fName")
    print outputLine

(END)














