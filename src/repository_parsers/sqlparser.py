import re

import sqlparse
import sql_metadata



def sanitize_sql(sql_text):
    # Remove MAGIC commands
    sanitized_sql = re.sub(r'-- MAGIC %.*?$', '', sql_text, flags=re.MULTILINE)
    
    # Remove comments
    sanitized_sql = re.sub(r'--.*?$', '', sanitized_sql, flags=re.MULTILINE)
    
    return sanitized_sql

def extract_tables_from_sql(sql_text):
    """
    Extracts table names from given SQL text.
    """
    sanitized_sql = sanitize_sql(sql_text)
    parser = sql_metadata.Parser(sanitized_sql)
    tables = parser.tables
    return tables

def extract_tables_from_file(file_path):
    """
    Extracts table names from given SQL file.
    """
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
    return extract_tables_from_sql(content)


def extract_tables_from_sql(sql_text):
    table_names = set()

    # Parse the SQL text
    parsed = sqlparse.parse(sql_text)

    # Iterate through the parsed statements
    for statement in parsed:
        # Get the list of tokens in the current statement
        tokens = statement.tokens

        # Filter the tokens to get only the ones we're interested in
        # This can include tables, subqueries, aliases, etc.
        for token in tokens:
            if token.ttype is None and isinstance(token, sqlparse.sql.Identifier):
                table_names.add(token.get_real_name())
            elif token.ttype is None and isinstance(token, sqlparse.sql.IdentifierList):
                for identifier in token.get_identifiers():
                    table_names.add(identifier._get_repr_name())

    return table_names

if __name__ == "__main__":
    import pandas as pd
    df = pd.read_csv("/workspace/repositories/parsed_results/parsed_sql_tables.csv")

    file_path = "/workspace/src/repository_parsers/stg_additional_tables_queries.sql"
    tables = extract_tables_from_file(file_path)
    print(tables)

    # sql_content = df["sql_query"].iloc[0]
    # tables = extract_tables_from_sql("/workspace/src/repository_parsers/stg_additional_tables_queries.sql")
    # print(tables)
