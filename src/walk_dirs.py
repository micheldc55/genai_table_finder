import json
import os
import pickle


def get_immediate_path_after(base_path: str, full_path: str) -> str:
    """Function to parse the immediate path after the base path and get only the folder right after the base path

    :param base_path: the base path
    :param full_path: the full path
    :return: the immediate path after the base path
    """
    relative_path = os.path.relpath(full_path, base_path)
    folder = os.path.basename(os.path.dirname(relative_path))

    return folder


def read_file(path: str) -> str:
    """Reads a file in text format

    :param path: _description_
    :type path: str
    """
    with open(path, "r") as file:
        return file.read()


if __name__ == "__main__":
    path = "/Users/davidovichm/Desktop/Michel/genai_table_finder/files"

    file_dict = {}

    for root, dirs, files in os.walk(path):
        for file in files:
            full_path = os.path.join(root, file)
            repository = get_immediate_path_after(path, full_path)

            file_text = read_file(full_path)

            if repository not in file_dict:
                file_dict[repository] = {file: file_text}
            else:
                file_dict[repository][file] = file_text

    # for key in file_dict.keys():
    #     print(key)
    #     for file in file_dict[key].keys():
    #         print(f"\t{file}")

    with open("/Users/davidovichm/Desktop/Michel/genai_table_finder/outputs/file_struct.pickle", "wb") as file:
        pickle.dump(file_dict, file)

    with open("/Users/davidovichm/Desktop/Michel/genai_table_finder/outputs/file_struct.json", "w") as file:
        json.dump(file_dict, file)
