from google.cloud.exceptions import NotFound
from util_query import crux_query
import logging
import json
import re
import os
import datetime

class Crux:
    
    def __init__(self, bigquery_client,crux_table,bigquery,storage_client):
        self.bigquery_client = bigquery_client
        self.crux_table = crux_table      
        self.bigquery = bigquery
        self.storage_client = storage_client

    def table_suffix(self):

        today = datetime.date.today()
        first = today.replace(day=1)
        lastMonth = first - datetime.timedelta(days=1)
        return lastMonth.strftime("%Y%m")

    def check_rows(self):
      
        table = self.bigquery_client.get_table(self.crux_table)
        return table.num_rows 


    def check_table_crux(self):
        try:
            full_table = "chrome-ux-report.all." + self.table_suffix()
            query_job = self.bigquery_client.get_table(full_table)
            return True

        except NotFound:
            return False        
        
    def check_last_month(self):
        try:
            response = self.bigquery_client.query("""
                SELECT if(count(*) > 0,true,false) as check_rows FROM `{table}`
                where year_month = '{year_month}'

                """.format(year_month = self.table_suffix(), table = self.crux_table)
            )
            return list(response.result())[0].values()[0]
        except NotFound:
            schema_json = json.load(open("schema_json.json"))
            schema = []
            for obj in schema_json:
                schema.append(self.bigquery.SchemaField(obj["field_path"], obj["data_type"], mode=obj["mode"]))
            
            table = self.bigquery.Table(self.crux_table, schema = schema)
            table = self.bigquery_client.create_table(table)
            logging.info("CRUX database created successfully.")       
            return False
        
   
    def get_domains(self):
        
        bucket_gcs = os.environ.get('PROJECT_BUCKET_GCS')
        bucket = self.storage_client.get_bucket(bucket_gcs)
        blob = bucket.blob('config/config.json')
        domains_json = json.loads(blob.download_as_string())
        domains = []
        for ind,value in enumerate(domains_json["URLS"]):
            if value["page"] == "Home":
                url = "'" + re.sub(r'(\/)$','',value["URL"]) + "'"
                domains.append(url)
        return ",".join(domains)




    def update_crux_table(self):
        try:
            job_config = self.bigquery.QueryJobConfig()
            job_config.destination = self.crux_table
            job_config.write_disposition = 'WRITE_APPEND'
            job_config.allow_large_results = True

            domains = self.get_domains()
            table_suffix = self.table_suffix()
            sql_query = crux_query(domains,table_suffix)
            
            rows_before_response = self.check_rows()
            response = self.bigquery_client.query(sql_query,job_config = job_config)  
            rows_after_response = response.result().total_rows
            table_loaded = rows_after_response > rows_before_response           
            if(table_loaded == False):
                logging.error("CRUX table loading error.")

            return table_loaded 
        except Exception as error:
            logging.error(error)
            
            return False
