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

def openai_response_parser(response: dict) -> tuple:
    """Function that takes an openai dict response and parses it.

    :param response: The response dictionary directly obtained from the openai.ChatCompletion.create endpoint.
    :type response: dict
    :return: Returns a tuple of single response (str) and the dictionary of token counts.
    :rtype: tuple
    """
    text_response = response["choices"][0]["message"]["content"]
    token_dict = response["usage"]

    return text_response, token_dict


if __name__ == "__main__":
    test = '["table1", "table2", "database.table3"]'

    out = simple_split(test)

    print(out)
    print(type(out))

    test_dict = {
        "id": "chatcmpl-7vT67cQ5Xug1jZUxVZliwCvhmZBed",
        "object": "chat.completion",
        "created": 1693930903,
        "model": "gpt-3.5-turbo-0613",
        "choices": [
            {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "WITH cte AS (\n  SELECT\n    CONCAT(c.customer_name, ' - ', c.customer_id) AS customer_info,\n    o.order_id,\n    o.order_date,\n    o.total_price\n  FROM\n    energy_company.customers c\n  JOIN\n    energy_company.orders o ON c.customer_id = o.customer_id\n  WHERE\n    o.order_date >= DATE_FORMAT(CURRENT_DATE(), '%Y-%m-01')\n),\nsubquery1 AS (\n  SELECT\n    customer_info,\n    COUNT(DISTINCT order_id) AS total_orders\n  FROM\n    cte\n  GROUP BY\n    customer_info\n  HAVING\n    total_orders > 5\n),\nsubquery2 AS (\n  SELECT\n    customer_info,\n    SUM(total_price) AS total_sales\n  FROM\n    cte\n  GROUP BY\n    customer_info\n),\nsubquery3 AS (\n  SELECT\n    customer_info,\n    AVG(total_price) AS avg_sale\n  FROM\n    cte\n  GROUP BY\n    customer_info\n),\nsubquery4 AS (\n  SELECT\n    customer_info,\n    MAX(total_price) AS max_sale\n  FROM\n    cte\n  GROUP BY\n    customer_info\n),\nsubquery5 AS (\n  SELECT\n    customer_info,\n    MIN(total_price) AS min_sale\n  FROM\n    cte\n  GROUP BY\n    customer_info\n)\nSELECT\n  s1.customer_info,\n  s1.total_orders,\n  s2.total_sales,\n  s3.avg_sale,\n  s4.max_sale,\n  s5.min_sale\nFROM\n  subquery1 s1\nJOIN\n  subquery2 s2 ON s1.customer_info = s2.customer_info\nJOIN\n  subquery3 s3 ON s1.customer_info = s3.customer_info\nJOIN\n  subquery4 s4 ON s1.customer_info = s4.customer_info\nJOIN\n  subquery5 s5 ON s1.customer_info = s5.customer_info\nORDER BY\n  s2.total_sales DESC;"
            },
            "finish_reason": "stop"
            }
        ],
        "usage": {
            "prompt_tokens": 320,
            "completion_tokens": 421,
            "total_tokens": 741
        }
    }

    output = openai_response_parser(test_dict)
    for out in output:
        print(out)