import os
import sys

import openai
import pandas as pd
from dotenv import load_dotenv

sys.path.append("/workspace")
from src.file_parsers.output_parsers import simple_split, openai_response_parser
from src.llms.openai_models import OpenAiChat, OpenAiChatWithRetries
from src.messages.base_messages import system_message_en
from src.messages.message_templates import sql_query_template
from src.messages.messages import Message, MessageHistory


load_dotenv()

openai.api_key = os.getenv("OPENAI_KEY")

queries_df = pd.read_csv("/workspace/data_generation/queries/responses_v1.csv")
num_entries = len(queries_df)

system_message = Message("system", system_message_en)

responses = []
prompt_tokens = []
output_tokens = []
total_tokens  = []

for idx, row in queries_df.iterrows():
    message = row["sql_query"]
    
    history = MessageHistory()
    history.add_message(system_message)

    chat = OpenAiChatWithRetries(history)
    response = chat(message, retries=4)
    content, token_dict = openai_response_parser(response)

    responses.append(content)
    prompt_tokens.append(token_dict["prompt_tokens"])
    output_tokens.append(token_dict["completion_tokens"])
    total_tokens.append(token_dict["total_tokens"])

    print(f"Processed: {idx + 1} / {num_entries}")

queries_df["tables"] = responses
queries_df["prompt_tokens_tables"] = prompt_tokens
queries_df["output_tokens_tables"] = output_tokens
queries_df["total_tokens_tables"] = total_tokens

queries_df.to_csv("/workspace/data_generation/queries/complete_prompts.csv", index=False)
