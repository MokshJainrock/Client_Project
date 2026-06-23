import pandas as pd
from sqlalchemy import create_engine
from urllib.parse import quote_plus
engine = create_engine(f'mysql+pymysql://root:{quote_plus("Pass@2021")}@localhost/client_analytics')
clients = pd.read_sql("SELECT * FROM clients", engine)
clients['days_since_last'] = (pd.Timestamp('2011-12-09') - pd.to_datetime(clients['last_seen'])).dt.days
clients.to_csv('/Users/mokshjain/Desktop/Client_Project/clients_for_powerbi.csv')
df = pd.read_csv('/Users/mokshjain/Desktop/Client_Project/clients_for_powerbi.csv')
print("Excel version saved to Desktop")
df.to_excel('/Users/mokshjain/Desktop/Client_Project/clients_for_powerbi.xlsx', index=False)
print("Excel version saved to Desktop")
print("Exported")