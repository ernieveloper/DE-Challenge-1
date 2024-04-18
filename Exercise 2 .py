#Exercise 2 - Pipeline

import pandas as pd
from sqlalchemy import create_engine, text
import datetime

df_covid_new = pd.read_json('https://opendata.ecdc.europa.eu/covid19/nationalcasedeath/json/')

db_engine = create_engine('postgresql://postgres:limewire@192.168.38.128:5432/case_challenge')
connection = db_engine.connect()

query_max_date = "SELECT MAX(year_week) FROM covid_data"
latest_date = connection.execute(text(query_max_date)).fetchone()[0]

if latest_date is not None:
    df_covid_new = df_covid_new[df_covid_new['year_week'] > latest_date]

df_covid_new.to_sql('covid_data', db_engine, if_exists='append', index=False)