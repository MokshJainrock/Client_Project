import pandas as pd
from sqlalchemy import create_engine

df = pd.read_csv('/Users/mokshjain/Desktop/Client_Project/online_retail_II.csv')   
print("Raw rows:", len(df))

df.columns = ['invoice','stock_code','description','quantity',
              'invoice_date','price','customer_id','country']


# a) Droppign rows with no customer_id (can't attribute to a client)
df = df.dropna(subset=['customer_id'])
# b) Removing cancellations (invoices starting with 'C')
df = df[~df['invoice'].astype(str).str.startswith('C')]
# c) Removing returns/bad rows (quantity & price must be positive)
df = df[(df['quantity'] > 0) & (df['price'] > 0)]
# d) Fixing data types
df['customer_id'] = df['customer_id'].astype(int).astype(str)
df['invoice'] = df['invoice'].astype(str)
df['stock_code'] = df['stock_code'].astype(str)
df['invoice_date'] = pd.to_datetime(df['invoice_date'])
# e) Dropping exact duplicates
df = df.drop_duplicates()
print("Clean rows:", len(df))

products = (df.sort_values('invoice_date')
              .groupby('stock_code')
              .agg(description=('description','last'), price=('price','last'))
              .reset_index())

# CLIENTS: one row per customer with computed fields
df['line_total'] = df['quantity'] * df['price']
clients = (df.groupby('customer_id')
             .agg(country=('country','last'),
                  first_seen=('invoice_date','min'),
                  last_seen=('invoice_date','max'),
                  total_spend=('line_total','sum'),
                  order_count=('invoice','nunique'))
             .reset_index())
clients['first_seen'] = clients['first_seen'].dt.date
clients['last_seen'] = clients['last_seen'].dt.date
clients['segment'] = None

# TRANSACTIONS: one row per invoice
transactions = (df.groupby('invoice')
                  .agg(customer_id=('customer_id','first'),
                       invoice_date=('invoice_date','first'),
                       total_amount=('line_total','sum'))
                  .reset_index())

# TRANSACTION_ITEMS: one row per product per invoice
transaction_items = df[['invoice','stock_code','quantity','price']].copy()
transaction_items.columns = ['invoice','stock_code','quantity','unit_price']

# LOADING INTO MYSQL 
engine = create_engine('mysql+pymysql://root:Pass%402021@localhost/client_analytics')

products.to_sql('products', engine, if_exists='append', index=False)
clients.to_sql('clients', engine, if_exists='append', index=False)
transactions.to_sql('transactions', engine, if_exists='append', index=False)
transaction_items.to_sql('transaction_items', engine, if_exists='append', index=False)
print("Loaded into MySQL.")