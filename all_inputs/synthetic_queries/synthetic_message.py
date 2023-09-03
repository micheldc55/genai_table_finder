gpt_message = """I need you to invent a complex SQL query in which you alternate between table names and CTEs 
or subqueries. Remember generally tables can be located inside a database, so to make it more real you can 
also alternate between adding references to databases and tables inside those, and queries that use local 
tables with no reference to databases. Use column names, databases name, table names and CTE/subquery names 
that seem real, as this is part of the challenge. These queries will be used to train a model to list the "real" 
table names and not the CTEs or subqueries names. You must include the query and also the names of the real 
tables the model should extract. Add WHERE statements, JOIN statements, GROUP BY, ORDER BY, HAVING, etc. You can 
also use different formats like SQL, Spark SQL, Azure SQL, etc. Don't use generic element names, make it specific."""
