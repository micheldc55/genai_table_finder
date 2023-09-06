import os
import sys

import openai
import pandas as pd
from dotenv import load_dotenv

sys.path.append("/workspace")
from src.datamixers.Malpaca import Malpaca, DataMixer
from src.llms.openai_models import OpenAiChat
from src.messages.messages import Message, MessageHistory
from base_data import (
    user_text, 
    type_of_join_options, 
    use_of_ctes_options, 
    length_options, 
    industry_options,
    schema_options
)


load_dotenv()
openai.api_key = os.getenv("OPENAI_KEY")

system_message = Message(role="system", message="You are a helpful SQL query generator. You only output SQL queries, without any extra text")
malpaca = Malpaca(user_text)

variable_keys = {
    "naming_schemas": schema_options, "type_of_join": type_of_join_options, "use_of_CTEs": use_of_ctes_options, 
    "length": length_options, "company_type": industry_options
}
mixer = DataMixer(malpaca, constant_keys={}, variable_keys=variable_keys, combined_keys=None)
output = mixer.create_random_combinations(200, None, "string")

output_df = pd.DataFrame()

for idx, result in enumerate(output):
    output_df = pd.concat([output_df, pd.DataFrame({"ID": idx, "initial_query": result}, index=[idx])])

output_df.to_csv("/workspace/data_generation/queries/prompt_only_v1.csv", index=False)

    