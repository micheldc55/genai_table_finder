import os


def find_sql_files(path) -> list[str]:
    """Parses a directory and gets all the sql files in it.

    :return: A list of files and their path from the workspace
    :rtype: list[str]
    """
    sql_files = []

    for root, _, files in os.walk(path):
        for file in files:
            if file.endswith(".sql"):
                file_path = os.path.join(root, file)
                sql_files.append(file_path)

    return sql_files