import ConfigParser, logging, glob
import numpy as np

config = ConfigParser.ConfigParser()
config.read('gsm/config/config.cfg')

def host():
    return config.get("database", "host")

def dbname():
    return config.get("database", "dbname")

def port():
    return int(config.get("database", "port"))

def uname():
    return config.get("database", "uname")

def pword():
    return config.get("database", "pword")
