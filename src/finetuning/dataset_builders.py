# import datasets
import pandas as pd


class InstructionDataFormatterPandas:
    """Create a Data Formatter based on Pandas."""

    def __init__(
            self, 
            csv_path: str, 
            input_col: str, 
            output_col: str, 
            system_message: str, 
            user_prepend: str, 
            assistant_append: str,
            behaviour_modifier: str or None = None
        ):

        self.csv_path = csv_path
        self.input_col = input_col
        self.output_col = output_col
        self.data = pd.read_csv(csv_path)

        self.system_message = system_message 

        if behaviour_modifier:
            user_prepend += "\n" + behaviour_modifier
        
        self.user_prepend = user_prepend
        self.assistant_append = assistant_append   

        self.preprocessed_data = self.preprocess()     
    
    def preprocess(self):
        data = self.data.copy()

        # Add system message and user prep.
        data[self.input_col] = self.system_message + "\n\n" + self.user_prepend + "\n" + self.data[self.input_col]
        # append the assistant token to the input column
        data[self.input_col] = data[self.input_col] + "\n\n" + self.assistant_append + "\n"

        return data


if __name__ == "__main__":
    ## Prompt format taken from: https://github.com/facebookresearch/llama-recipes/blob/main/ft_datasets/alpaca_dataset.py

    formatter = InstructionDataFormatterPandas(
        "/workspace/data_generation/queries/responses_v1.csv", 
        input_col = "initial_query", 
        output_col = "sql_query", 
        system_message = "Below is an instruction that describes a task. Write a response that appropriately completes the request.",
        user_prepend = "###Instruction:", 
        assistant_append = "###Response:", 
        behaviour_modifier = None
    )

    df = formatter.preprocessed_data

    print(df["initial_query"].iloc[0])