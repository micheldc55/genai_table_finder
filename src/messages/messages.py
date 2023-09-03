class Message:
    """Create a message object for an LLM."""

    def __init__(self, role: str, message: str):
        if role not in ["system", "user", "assistant"]:
            raise ValueError("Message role must be either 'system', 'user' or 'assistant'.")
        self.message = message
        self.role = role

    def __repr__(self):
        message_text = self.message if len(self.message) < 20 else self.message[:18] + "..."
        return f"""Message(role={self.role}, message="{message_text}")"""


class MessageHistory:
    def __init__(self):
        self.messages = []

    def add_message(self, message: Message):
        if (len(self.messages) == 0) and (message.role != "system"):
            raise ValueError(f"First message must be from system. Your message's role was: {message.role}")

        self.messages.append(message)

    def to_list(self):
        return [{"role": message.role, "content": message.message} for message in self.messages]

    def populate_from_list(self, message_list: list):
        for message in message_list:
            self.add_message(Message(message.role, message.message))
