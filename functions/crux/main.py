from google.cloud import bigquery
from google.cloud import storage
from util_class import Crux
import logging
import os

logging.basicConfig(level=logging.INFO)

storage_client = storage.Client()
bigquery_client = bigquery.Client()


project = os.environ.get('PROJECT_NAME')
dataset = os.environ.get('PROJECT_DATASET_BQ')

crux_table = "{project}.{dataset}.crux_table".format(project=project,dataset=dataset)
crux = Crux(bigquery_client,crux_table,bigquery,storage_client)

def main(context):

    log = ""
    if(crux.check_last_month()):
        log = "Previously updated CRUX table."
    else:
         
        if(crux.check_table_crux()):
            response = crux.update_crux_table()
            if(response == True):
                log = "CRUX table updated successfully."
        else:
            log = "CRUX table not available."
    
    logging.info(log)
    return log
