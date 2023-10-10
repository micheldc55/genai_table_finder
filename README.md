# GenAI Table Finder

This project is meant to be an experiment to fine-tune different LLMs to be able to find references to SQL tables in .sql text files. The idea is that the model is given a string containing a SQL query and a set of tokens that work as a trigger. The models are then fine tuned to be able to identify the references to tables in the SQL query.

## Introduction and Problem Statement:

The objective of this project is to be able to identify references to **novel** tables in SQL queries. By **novel** tables I mean tables that have not been referenced before and that refer to real tables outside the scope of the SQL query. This means that tables should not be CTEs or subqueries, but only those that are actually storing tabular data in some kind of SQL cloud or on-premise server. The final objective is to be able to identify tables that might be candidates to failure or crashing when they are modified or eliminated.

Most changed to tables affect some process that uses them. If a SQL query calls a table, the query assumes certain qualities of the table, and also assumes the table exists. So most people experience issues when dropping tables if they don't know which scripts or repositories refer to them. This project aims to parse entire github repositories and extract relevant tables from .sql files.

I tried different approaches to solve this problem, going from simpler to more complex. But ended up realizing that using an LLM ran locally for extracting the SQL table references was a good way of getting the job done and keeping data privacy without resorting to API based LLMs like chatGPT. So I decided to go the fine-tuning route. I fine-tuned Llama 2 and CodeLlama models so that the could be triggered to find the tables when a set of tokens (####FINDTABLES) was used before the SQL query.

## Previous iterations:

A couple approaches I have tried before this one are stated below:

1) **Using a Python Library built for this purpose:** Python's sqlparse allows to identify tables in SQL queries, but I couldn't get consistent results across different SQL flavours, and it worked terribly with Azure's bracket syntax for tables, which is pretty common in most references to cloud databases in Azure. Accuracy was below 20% and even worse in cloud SQL flavours.

2) **Using regular expressions:** I also tested building a huge regular expression that could extract all the tables. I came to realize that in most SQL flavours, table references are all the names after the FROM or JOIN statement that were not previously mentioned. This worked a little better for most cases, but any case that was different from the format I had thought of would cause errors and regular expressions are very difficult to interpret and debug. The results with this method was around 72% accuracy. Accuracy is defined as total number of tables guessed correctly vs total number of tables in the queries.

3) **Using ChatGPT (zero-shot):** ChatGPT already knows how to work with code, so I expected it to do really well on this task. I used the GPT-3.5-turbo version and a simple system message and requested it to return a list of tables that would be compared to the correct ones. This approach already got almost 100% accuracy (99.7%) and only messed up in a tricky case in which it removed the brackets from a table, but extracted the table correctly. The main issue with OpenAI's models in this is data privacy. In order to do this well you would need to have the model look at all your code base, or at the very least your production code base. It's not something that a company would like to give to another company as training data.

## Evaluation: 

Evaluation is straightforward. I used two metrics for estimating how the models were doing:

1) **Accuracy:** Accuracy is defined as total number of tables guessed correctly vs total number of tables in the queries. The comparisons are made in sets instead of lists to account for tables that are ordered differently. It's a simple metric that measures overall capacity to capture tables, independently of their order. This is what we want, when the model messes up and doesn't retrieve a table, it has a lower score. When it extracts the table, the result is better.

2) **Correctness:** This metric is a more demanding way of measuring accuracy, in which you only take the result as good if it has all the tables in it. This is more demanding as all the tables have to be correct, so you get a smaller denominator in accuracy, which means that each mistake impacts the metric in a stronger way.

## Dataset:

I used a dataset that I gathered from personal data that I have gathered during the years of working with SQL, but I could only get 107 unique queries. This isn't a lot so I wanted to expand that, but found out that there isn't a lot of data available on the internet that uses this format. So I decided to use the [Alpaca method](https://crfm.stanford.edu/2023/03/13/alpaca.html) and *manufacture* a lot of training examples using GPT-3.5 and GPT-4. 

The Alpaca method is a really interesting and easy way of generating data using language models. Although it is unclear whether this way of generating data is sustainable in practice ([check this out if you are interested]([“Synthetic Data and LLMs: Use Cases and Implications”](https://unimatrixz.com/topics/ai-text/nlp-tasks/reasoning/content-generation/create-synthetic-data/)https://unimatrixz.com/topics/ai-text/nlp-tasks/reasoning/content-generation/create-synthetic-data/)) when data is lacking, this method is a very good way of generating data. Authors in the paper point out that this data may be biased and will cause the model trained on it to be unable to handle out of ditribution data, but it's better than nothing and it's a good way to start iterating.

The method itself is based on what I call a "pinwheel rotation". You select a set of topics and a set of templates, and substitute the key words in the template to change the tone and topic of the instruction. You then ask a much larger model like GPT-3.5 or GPT-4 to create the response to that instruction. This way, if you have two words to substitute in the template and 5 options in each, you can quickly generate 25 instruction-response pairs. Of course, it's hard to imagine that the model will outperform a larger model with this method in all areas, but a case can be made for making a smaller model much more competitive in the topic areas selected. This was the entire point of the Alpaca paper.

The code for generating the dataset of queries can be obtained from this repository.





