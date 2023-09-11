import pandas as pd 


df = pd.read_csv("/workspace/data_generation/queries/complete_prompts.csv")

test = pd.read_csv("/workspace/data_generation/queries/tables_to_correct.csv", sep=";").drop(["Unnamed: 0", "Unnamed: 5", "Unnamed: 6"], axis=1)
test['Index'] = test["Index"].astype(int)
test = test.sort_values("Index")

df.loc[df['ID'].isin(test['Index']), 'sql_query'] = test.set_index('Index').loc[:, 'SQL_query'].values
df.loc[df['ID'].isin(test['Index']), 'tables'] = test.set_index('Index').loc[:, 'corrected_output'].values

df.to_csv("/workspace/data_generation/queries/CORRECTED_PROMPTS_FOR_FINE_TUNING.csv", index=False)