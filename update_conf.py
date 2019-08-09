#!/usr/bin/env python

import os
import sys
import ConfigParser


#Setting reporting.conf
reporting_cfg = ConfigParser.ConfigParser()
reporting_cfg.read('/opt/cuckoo/conf/reporting.conf')

with open('/opt/cuckoo/conf/reporting.conf', 'w') as conf_file:

    if os.environ.get('MONGO_HOST'):
        reporting_cfg.set('mongodb', 'enabled', 'yes')
        reporting_cfg.set('mongodb', 'host', os.environ['MONGO_HOST'])
        
    if os.environ.get('MONGO_TCP_PORT'):
        reporting_cfg.set('mongodb', 'port', os.environ['MONGO_TCP_PORT'])
    
    if os.environ.get('MONGO_INITDB_ROOT_USERNAME'):
        reporting_cfg.set('mongodb', 'username', os.environ['MONGO_INITDB_ROOT_USERNAME'])
        
    if os.environ.get('MONGO_INITDB_ROOT_PASSWORD'):
        reporting_cfg.set('mongodb', 'password', os.environ['MONGO_INITDB_ROOT_PASSWORD'])

    reporting_cfg.write(conf_file)

sys.exit(0)
