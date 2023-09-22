import ast

import streamlit
import pandas as pd


streamlit.set_page_config(layout="wide")

df = pd.read_csv("/workspace/data_generation/queries/CORRECTED_PROMPTS_FOR_FINE_TUNING.csv")

index = streamlit.number_input("Select the index", min_value=df["ID"].min(), max_value=df["ID"].max())

selected_row = df[df["ID"] == index]

streamlit.dataframe(selected_row)

streamlit.write("This is the output of the model in written format:")
streamlit.write(selected_row["tables"].iloc[0])

prompt = selected_row["sql_query"].iloc[0]
response = selected_row["tables"].iloc[0]
response = ast.literal_eval(response)

col1, col2 = streamlit.columns([4, 3])
col1.code(prompt, language="sql")
col2.write(response)
