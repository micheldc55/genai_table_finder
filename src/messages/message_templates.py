from messages import Message


class MessageWithContext(Message):
    """Create a Message from a User that gets context fed to it to answer the question."""

    def __init__(self, prompt: str, context: str):
        self.prompt = prompt
        self.role = "user"
        self.context = context
        self.message = self._build_full_message(context)

    def _build_full_message(self, context: str):
        user_start = "Answer the question based on the context below.\n\n" + "Context:\n"

        user_end = f"\n\nQuestion: {self.prompt}\nAnswer:"

        return user_start + context + "\n\n---\n\n" + user_end


class MensajeConContexto(Message):
    """Genera un mensaje que contiene el contexto de la pregunta y la pregunta en sí misma."""

    def __init__(self, prompt: str, context: str):
        self.prompt = prompt
        self.role = "user"
        self.context = context
        self.message = self._build_full_message(context)

    def _build_full_message(self, context: str):
        user_start = "Responde la pregunta basándote en el contexto que se muestra a continuación.\n\n" + "Contexto:\n"

        user_end = f"\n\nPregunta: {self.prompt}\nRespuesta:"

        return user_start + context + "\n\n---\n\n" + user_end


if __name__ == "__main__":
    context = """The Lord of the Rings is a fantasy novel by J. R. R. Tolkien. It tells the story of"""

    prompt = "What is the name of the novel?"

    message = MessageWithContext(prompt, context)

    print(message)
