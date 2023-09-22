import os
import sys

import openai
import pandas as pd
from dotenv import load_dotenv

sys.path.append("/workspace")
from src.datamixers.Malpaca import Malpaca, DataMixer
from src.llms.openai_models import OpenAiChat, OpenAiChatWithRetries
from src.messages.messages import Message, MessageHistory
from src.file_parsers.output_parsers import openai_response_parser


prompt_csv_path = "/workspace/data_generation/queries/prompt_only_v1.csv"
intermediary_file = "/workspace/data_generation/queries/responses_v1_partial.csv"
save_output_path = "/workspace/data_generation/queries/responses_v1.csv"

load_dotenv()
openai.api_key = os.getenv("OPENAI_KEY")

prompt_df = pd.read_csv(prompt_csv_path, chunksize=1)
response_df = pd.DataFrame()

for mini_batch in prompt_df:
    system_message = Message(role="system", message="You are a helpful SQL query generator. You only output long SQL queries, without any extra text")
    history = MessageHistory()
    history.add_message(system_message)

    index = mini_batch["ID"].iloc[0]
    prompt = mini_batch["initial_query"].iloc[0]

    chat = OpenAiChatWithRetries(history)
    response = chat(prompt, retries=4)
    content, token_dict = openai_response_parser(response)

    mini_batch["sql_query"]     = content
    mini_batch["prompt_tokens"] = token_dict["prompt_tokens"]
    mini_batch["output_tokens"] = token_dict["completion_tokens"]
    mini_batch["total_tokens"]  = token_dict["total_tokens"]

    response_df = pd.concat([response_df, mini_batch])

    if (index + 1 % 10 == 0):
        print(f"{index} / 200")
        response_df.to_csv(intermediary_file, index=False)
        print("Saved Intermediary table")

response_df.to_csv(save_output_path, index=False)
os.remove(intermediary_file)