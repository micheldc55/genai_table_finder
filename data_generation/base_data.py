user_text = """Generate an intricate SQL query without any preceding or trailing explanations or comments. 
Ensure the query meets the following criteria:

Tables & Columns: Include tables with different naming schemas, like {naming_schemas}, substituting each for a valid and creative table name. Each table should have columns fitting its purpose.
Joins: Use a mix of {type_of_join}. The join conditions should represent realistic relationships between the tables.
Filtering: Use WHERE{other_clauses} clauses with meaningful conditions related to the provided table names and columns.
Grouping: Incorporate GROUP BY on certain columns and accompany it with aggregate functions such as SUM(), AVG(), or COUNT().
Functions: Utilize functions like DATE_FORMAT(), CONCAT(), or UPPER() where they fit naturally.
Column Renaming: Rename some of the output columns using the AS keyword, e.g., SUM(orders.total_price) AS TotalSales.
Subqueries & CTEs: Integrate multiple subqueries within the main query {use_of_CTEs}. Names have to be relevant.
Creativity: Add any other SQL clauses or functions to enhance complexity, but ensure all table and column names remain realistic.
Length: Make it a {length}.

Create the query as if it was for {company_type}. You must make up the name of the company for the database names, and also for the table names if necessary.

The resulting output should strictly be the SQL query without any surrounding text."""

schema_options = [
    "<table>, <database>.<schema>.<table> or <database>.<table>", 
    "<database>.<schema>.<table>, <schema>.<table> or [database].[table]", 
    "<project>.<dataset>.<table>, <table>, <database>.<schema>.<table>", 
    "<table>, <schema>.<table> or <database>.<schema>.<table>",
    "[database].[table], <table>, <database>.<schema>.<table>",
    "<database>.<schema>.<table>, <project>.<dataset>.<table>, <table>", 
    "[database].[table], <database>.<schema>.<table>, <database>.<table>"
]
type_of_join_options = [
    "INNER, LEFT and OUTER JOINS", "regular joins and a final CROSS JOIN", 
    "intricate CROSS JOINS and LATERAL JOINS", "the most frequent joins", 
    "some creative JOIN operations", "a long list of JOIN operations on the tables"
]
clauses = [
    "", " and HAVING", ", LIKE and HAVING", " and LIKE", "", ", LIKE, BETWEEN, IN, and other",
    "", ", HAVING and a mix of other", ""
]
use_of_ctes_options = [
    "and include a Common Table Expression (CTE)", "include multiple Common Table Expressions (CTE)", 
    "don't include any Common Table Expression (CTE)"
]
length_options = ["very long and intricate query"] * 8 + ["medium length but intricate query"] * 2
industry_options = [
    "an e-commerce site", "an entertainment company", "a healthcare company", "an education institution", 
    "a bank", "a travel agency", "a retail company", "a manufacturing company", "a telecommunications company", 
    "a pharmaceutical company", "a small shop", "a logistics company", "a company in the energy sector", 
    "a real estate business", "an insurance company", "a marketing company", "a news site", "an airline company"
]
