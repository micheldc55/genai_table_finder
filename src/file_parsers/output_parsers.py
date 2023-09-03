import ast
import re


def simple_split(output_text: str) -> list:
    """Gets the normal output of the model (which should be a list expressed in string format) and
    convert it to a real string.

    :param output_text: String in the format "["table1", "table2", ...]"
    :type output_text: str
    :return: A list in the format ["table1", "table2", ...] (NOTE IT'S NOT a string!)
    :rtype: list
    """

    output_text = output_text[1:-1]
    output_list = output_text.split(", ")

    return [element[1:-1] for element in output_list]


if __name__ == "__main__":
    test = '["table1", "table2", "database.table3"]'

    out = simple_split(test)

    print(out)
    print(type(out))
