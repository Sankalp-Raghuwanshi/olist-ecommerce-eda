import pandas as pd
from sqlalchemy import create_engine

df = pd.read_csv(
    "/Users/sankalpsingh/Downloads/olist_order_reviews_dataset.csv",
    quotechar='"',
    escapechar='\\',
    on_bad_lines='warn'
)

engine = create_engine("postgresql://sankalpsingh@localhost:5432/olist_db")
df.to_sql("order_reviews", engine, if_exists="append", index=False)

print(f"Inserted {len(df)} rows")