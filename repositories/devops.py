import os
import re
import sys

import pandas as pd
import openai
import tiktoken
from dotenv import load_dotenv

sys.path.append("/workspace")
from src.repository_parsers.azDevOps import AzureDevOpsRepo
from src.file_parsers.folder_parsers import find_sql_files
from src.messages.messages import Message, MessageHistory
from src.messages.base_messages import system_message_en
from src.llms.openai_models import OpenAiChatWithRetries
from src.file_parsers.output_parsers import openai_response_parser


load_dotenv()
openai.api_key = os.getenv("OPENAI_KEY")

# os.environ["NODE_EXTRA_CA_CERTS"] = "/workspace/.devcontainer/zscaler.pem"
os.environ["GIT_SSL_NO_VERIFY"] = "true"

repo_name = "NetworkPlanning"
url = "ryanairbi.visualstudio.com/DataScience/_git/NetworkPlanning"
username = "davidovichm"
pat = os.getenv("DEVOPS_PAT")
output_dir = f"/workspace/repositories/{repo_name}"

repo = AzureDevOpsRepo(repo_name, url, username, pat, output_dir)

repo.clone_repository()
repo.checkout("development")

sql_files = find_sql_files(output_dir)
num_files = len(sql_files)

# print(sql_files)

system_message = Message("system", system_message_en)

responses = []
sql_paths = []
prompt_tokens = []
output_tokens = []
total_tokens  = []

model = "gpt-3.5-turbo"
base_model = "gpt-3.5-turbo-0613"
model_16k  = "gpt-3.5-turbo-16k"

for idx, sql_file in enumerate(sql_files):
    used_model = base_model
    
    with open(sql_file, "r") as f:
        sql_text = f.read()

    encoder = tiktoken.encoding_for_model(model)
    num_tokens = len(encoder.encode(sql_text))

    if num_tokens > 4096:
        sql_text = re.sub(r"--.*$", "", sql_text, flags=re.MULTILINE).lstrip()
        used_model = base_model

    if num_tokens > 4096:
        used_model = model_16k

    history = MessageHistory()
    history.add_message(system_message)

    chat = OpenAiChatWithRetries(history, model=used_model)
    response = chat(sql_text, retries=4)
    print(f"Parsed {idx + 1} / {num_files} SQL files")
    content, token_dict = openai_response_parser(response)

    responses.append(content)
    sql_paths.append(sql_file)
    prompt_tokens.append(token_dict["prompt_tokens"])
    output_tokens.append(token_dict["completion_tokens"])
    total_tokens.append(token_dict["total_tokens"])


sql_df = pd.DataFrame({
    "sql_paths": sql_paths, 
    "tables": responses, 
    "prompt_tokens": prompt_tokens, 
    "output_tokens": output_tokens, 
    "total_tokens": total_tokens
})

sql_df.to_csv("/workspace/repositories/parsed_results/parsed_sql_tables.csv", index=False)

repo.self_destruct()