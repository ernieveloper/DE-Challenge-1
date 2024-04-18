#EXERCISE 1

#!pip install pandas
#!pip install sqlalchemy

import pandas as pd
from sqlalchemy import create_engine

df_covid = pd.read_json('https://opendata.ecdc.europa.eu/covid19/nationalcasedeath/json/')
df_countries = pd.read_csv('C:/1/Countries of the world.csv')

#I developed this project on my work laptop where I don't have admin rights, I worked with postgresql docker container in a VM. 
db_engine = create_engine('postgresql://postgres:limewire@192.168.5.233:5432/case_challenge')
df_covid.to_sql('covid_data', db_engine, if_exists='replace', index=False)
df_countries.to_sql('countries', db_engine, if_exists='replace', index=False)

#To close the DB connection
db_engine.dispose()