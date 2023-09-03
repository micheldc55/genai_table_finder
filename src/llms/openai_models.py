import logging
from typing import List

import numpy as np
import openai
import pandas as pd
import tiktoken
import torch

from src.messages.messages import Message, MessageHistory


class TokenCounter:
    def __init__(self, model: str = "gpt-3.5-turbo"):
        self.encoding = tiktoken.encoding_for_model(model)

    def encode(self, messages: List[str] or str) -> List[List[int]]:
        if isinstance(messages, str):
            messages = [messages]

        return self.encoding.encode_batch(messages)

    def decode(self, tokens: List[List[int]] or List[int]):
        if isinstance(tokens[0], int):
            tokens = [tokens]

        return self.encoding.decode_batch(tokens)


class OpenAiChat:
    def __init__(self, history: MessageHistory, model: str = "gpt-3.5-turbo-0613", temperature: float = 0.0):
        self.model = model
        self.history = history
        self.temperature = temperature

    def __call__(self, prompt: str, temperature: float or None = None):
        """Call the OpenAI chat API with the prompt and return the response."""
        new_message = Message("user", prompt)
        self.history.add_message(new_message)

        if temperature is None:
            temperature = self.temperature

        response = openai.ChatCompletion.create(
            messages=self.history.to_list(),
            model=self.model,
            temperature=temperature,
        )
        return response

    def predict_on_messages(self, message_history: MessageHistory, temperature: float or None = None):
        """Call the OpenAI model on a Message History instead of a message"""
        if temperature is None:
            temperature = self.temperature

        response = openai.ChatCompletion.create(
            messages=message_history.to_list(),
            model=self.model,
            temperature=temperature,
        )

        return response


class OpenAiCompletion:
    pass


class OpenAiEmbeddings:
    def __init__(self, model: str = "text-embedding-ada-002"):
        self.model = model
        # self.embedding = openai.Embeddings(model)

    def embed_text(self, messages: List[str] or str):
        model = self.model

        if isinstance(messages, str):
            messages = [messages.replace("\n", " ")]
        else:
            messages = [message.replace("\n", " ") for message in messages]

        return openai.Embedding.create(input=messages, model=model)

    @staticmethod
    def get_embeddings_list(openai_response: dict):
        data = openai_response["data"]  # list
        return [item["embedding"] for item in data]

    @staticmethod
    def get_torch_embeddings(openai_response: dict):
        data = openai_response["data"]  # list
        return torch.stack([torch.tensor(item["embedding"]) for item in data])

    @staticmethod
    def get_numpy_embeddings(openai_response: dict):
        data = openai_response["data"]
        list_arrays = [np.array(item["embedding"]) for item in data]
        return np.array(list_arrays)


def get_openai_models(name_contains: str = "gpt-3.5-turbo-0613"):
    """List all models with name containing `name_contains` in openai.Model.list()

    Note: you must run the following commands first for an API key stored in a .env file:
    import os
    import openai
    from dotenv import load_dotenv
    load_dotenv()
    """
    model_list = openai.Model.list()
    model_list_out = []

    for model in model_list["data"]:
        if name_contains in model["id"]:
            model_list_out.append(model)

    return model_list_out


if __name__ == "__main__":
    import os

    import openai
    from dotenv import load_dotenv

    load_dotenv()

    openai.api_key = os.getenv("OPENAI_KEY")

    models = get_openai_models("3.5")

    print(models)
