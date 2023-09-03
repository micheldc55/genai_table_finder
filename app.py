import ast
import json
import os

import openai
from dotenv import load_dotenv

from src.file_parsers.output_parsers import simple_split
from src.llms.openai_models import OpenAiChat, TokenCounter
from src.messages.base_messages import system_message_en
from src.messages.message_templates import sql_query_template
from src.messages.messages import Message, MessageHistory

load_dotenv()

openai.api_key = os.getenv("OPENAI_KEY")

accuracy_entries = []
dict_entries = {}

list_of_files = os.listdir("/workspace/all_inputs/synthetic_queries/files")
num_files = len(list_of_files)

for num in range(1, num_files + 1):
    num = "0" + str(num) if len(str(num)) < 2 else str(num)

    query_text_path = f"/workspace/all_inputs/synthetic_queries/files/query{num}.txt"
    query_json_path = f"/workspace/all_inputs/synthetic_queries/real_table_names/query{num}.json"

    print(f"Looking at file: query{num}.txt")

    with open(query_text_path, "r") as f:
        query_text = f.read()

    with open(query_json_path, "r") as f:
        response_list = json.load(f)

    sql_template = sql_query_template.format(sql_query=query_text)

    system = Message("system", system_message_en)
    user_msg = Message("user", sql_template)

    history = MessageHistory()

    chatbot = OpenAiChat(history, temperature=0.1)

    history.populate_from_list([system, user_msg])
    response = chatbot.predict_on_messages(history)

    table_list_string = response["choices"][0]["message"]["content"]
    try:
        table_list = ast.literal_eval(table_list_string)
    except SyntaxError as e:
        print(e)
        if "unterminated string literal" in str(e):
            table_list_string += '"'
        try:
            table_list = ast.literal_eval(table_list_string)
        except Exception as e:
            print('Adding the " at the end did not fix it')
            table_list = simple_split(table_list_string)

    total_tokens = response["usage"]["total_tokens"]

    output = {"file_name": f"query{num}.txt", "extracted_table": table_list, "real_table": response_list}

    dict_entries[f"query{num}.txt"] = output

    for element in response_list:
        if element in table_list:
            accuracy_entries.append(1)
        else:
            accuracy_entries.append(0)

accuracy = round(sum(accuracy_entries) / len(accuracy_entries) * 100, 3)

dict_entries["accuracy_measures"] = {"accuracy_counts": accuracy_entries, "accuracy_val": accuracy}

print(f"Accuracy is: {accuracy}%")
print(f"Total number of correct elements is: {sum(accuracy_entries)}")
print(f"Total number of elements is: {len(accuracy_entries)}")

with open("/workspace/all_inputs/synthetic_queries/results/results_v4.json", "w") as f:
    json.dump(dict_entries, f)
