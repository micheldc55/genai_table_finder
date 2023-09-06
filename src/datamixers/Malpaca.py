import random
import string
from typing import List, Dict



class Malpaca:
    """Create an instance of a Malpaca mixer"""
    def __init__(self, base_string: str):
        self.base_string = base_string
        self.necessary_keys = self._get_key_list(base_string)

    def compose_string(self, values: dict) -> str:
        """Compose the base_string attribute of the class with a dictionary of values"""
        if self._check_dict_is_complete(values):
            return self.base_string.format(**values)
        else:
            raise KeyError(f"You need to pass all keys in your base string, which are: {self.necessary_keys}")
        
    def __call__(self, values: str) -> str:
        return self.compose_string(values)
    
    def print_keys_needed(self) -> str:
        """Prints the keys you need to pass in your dictionary"""
        formatter = string.Formatter()
        print("Necessary keys:")
        for _, key, _, _ in formatter.parse(self.base_string):
            if key:
                print("\t" + str(key))

    def _check_dict_is_complete(self, values: dict) -> bool:
        """Method that checks if the dictionary passed contains all the keys the base_string needs."""
        necessary_keys = set(self.necessary_keys)
        provided_keys  = set(values.keys())

        if len(necessary_keys) == len(provided_keys):  
            intersection = necessary_keys.intersection(provided_keys)
            return intersection == necessary_keys
        else:
            return False

    @staticmethod
    def _get_key_list(base_string: str) -> List[str]:
        """Static method that extracts the list of keys needed"""
        list_output = []
        formatter = string.Formatter()
        for _, key, _, _ in formatter.parse(base_string):
            if key not in list_output:
               list_output.append(key)

        if None in list_output:
            list_output.remove(None)

        return list_output
    

class DataMixer:
    """Create a key data mixer to populate the Malpaca base_string"""
    def __init__(
            self, 
            malpaca_instance: Malpaca,
            constant_keys: Dict[str, List], 
            variable_keys: Dict[str, List], 
            combined_keys: Dict[str, Dict[str, List]]
        ):
        """Create your own datamixer class

        :param malpaca_instance: An instance of the Malpaca class
        :type malpaca_instance: Malpaca
        :param constant_keys: A dictionary of lists assigned to each key (each key is a key in the base_string). 
        Each key has a single element that will not change for all combinations
        :type constant_keys: Dict[str, List]
        :param variable_keys: A dictionary of lists assigned to each key (each key is a key in the base_string). 
        Each key has multiple elements that will be randomly chosen for each combination
        :type variable_keys: Dict[str, List]
        :param combined_keys: A dictionary of lists assigned to each key (each key is a key in the base_string). 
        Each key has multiple elements that will be randomly chosen and joined with a comma ", ". The combined_keys 
        dictionary must have a dictionary with two keys: "values" which shows the list of values to combine.
        :type combined_keys: Dict[str, Dict[str, List]]
        """
        self.constant_keys = constant_keys
        self.variable_keys = variable_keys
        self.combined_keys = combined_keys
        self.malpaca = malpaca_instance

    def create_random_dict_combination(self, random_state: int or None = None) -> dict:
        """Create a random combination of the keys"""
        output_dict = self.constant_keys.copy()

        random.seed(random_state)

        for key, value in self.variable_keys.items():
            output_dict[key] = random.choice(value)

        if self.combined_keys is not None:
            for key, value in self.combined_keys.items():
                k = value["num_combinations"] if value["num_combinations"] is not None else len(value["values"])
                output_string = ", ".join(random.sample(value["values"], k=k))
                output_dict[key] = output_string

        return output_dict
    
    def create_random_string(self, malpaca_instance: Malpaca, random_state: int or None = None) -> str:
        """Create a random string using the Malpaca instance"""
        random_dict = self.create_random_dict_combination(random_state)
        return malpaca_instance(random_dict)
    
    def create_random_combinations(self, n_samples: int, random_state: int or None = None, output: str = "string") -> None:
        """Create a random combination of the keys and append it to the output"""
        for i in range(n_samples):
            random_state = None if random_state is None else random_state + i
            if output.lower() == "string":
                yield self.create_random_string(self.malpaca, random_state)
            elif output.lower() == "dict":
                yield self.create_random_dict_combination(random_state)
            else:
                raise ValueError("The output argument must be either 'string' or 'dict'")



if __name__ == "__main__":
    base_query_generator = """
    Create a complex {file_type} that {description}. Imagine the invented tables are from a {type_of_company}. 
    It must return a {return}. Remember generally tables can be located inside a database, so to make it more real you can also 
    alternate between adding references to named databases and tables inside those, and queries that use 
    local tables with no reference to databases. Try adding {alternative} to the query and whatever you find fit.

    This is extremely important as the data will be used to train a model in the next step. The model will 
    be trained to extract references to tables in the code, so you must make it look as real as possible. 
    The more complex the better.
    """

    sql_file_type = f"""SQL query"""  # and return
    sql_description_no_cte = f"""uses multiple queries, subqueries and references multiple invented tables. The table names must be 
    invented and varied, and the must not have arbitrary names like "table1" or "table2". """
    sql_extra_no_cte = """
    Remember generally tables can be located inside a database, so to make it more real you can also 
    alternate between adding references to named databases and tables inside those, and queries that use 
    local tables with no reference to databases. Try adding {alternative} to the query and whatever you find fit."""

    alternatives = ["", "", "", "", "", ""]

    reference = """
    I need you to invent a complex SQL query in which you alternate between table names and CTEs or 
    subqueries. Remember generally tables can be located inside a database, so to make it more real you can also 
    alternate between adding references to databases and tables inside those, and queries that use local tables 
    with no reference to databases. Use column names, databases name, table names and CTE/subquery names that seem 
    real, as this is part of the challenge. These queries will be used to train a model to list the "real" table 
    names and not the CTEs or subqueries names. You must include the query and also the names of the real tables 
    the model should extract. Add WHERE statements, JOIN statements, GROUP BY, ORDER BY, HAVING, etc. You can also 
    use different formats like SQL, Spark SQL, Azure SQL, etc. Don't use generic element names, make it specific. 
    You can also make operations between the columns, use window functions, partitioning, anything that makes it 
    look complex. The more complex the better.

    Remember, please don't use generic names like "table1, "CTE1" or "database1"."""

    base_string = "This is a {file_type} file. The types of variables in the file are: {variable_types}. Create a SQL query using the following sql functions: {sql_functions}"
    malpaca = Malpaca(base_string)

    test1 = {"file_type": "kk", "variable_types": "posho", "sql_functions": "LATERAL JOIN"}
    test2 = {"variable_types": "", "sql_functions": ""}

    # malpaca.print_keys_needed()

    # print(malpaca._check_dict_is_complete(test1))
    # print(malpaca._check_dict_is_complete(test2))

    # print(malpaca.compose_string(test1))
    # print(malpaca.compose_string(test2))

    constant_keys = {"variable_types": "str, int and float"}
    variable_keys = {"file_type": ["SQL", "Spark SQL", "Azure SQL"]}
    combined_keys = {"sql_functions": {"values": ["JOIN", "LATERAL JOIN", "CROSS JOIN", "LEFT JOIN"], "num_combinations": None}}

    mixer = DataMixer(malpaca, constant_keys, variable_keys, combined_keys)

    # for i in range(3):
    #     print(mixer.create_random_combination(None))

    output = mixer.create_random_combinations(10, None, "string")

    for example in output:
        print(example)