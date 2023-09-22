import timeit

def check_keys(keys, my_list):
  return all(key in my_list for key in keys)

keys = ["file_type", "variable_types", "sql_functions"] * 100
my_list = ["file_type", "variable_types", "sql_functions", "other_key"] * 100

set1 = set(keys)
set2 = set(my_list)

# Test the all() function
time1 = timeit.timeit(lambda: check_keys(keys, my_list), number=100000)
print(f"Time for all() function: {time1}")

# Test the set intersection
function = lambda: len(set1) == len(set2) and set1.intersection(set2) == set1
time2 = timeit.timeit(lambda: function, number=100000)
print(f"Time for set intersection: {time2}")
