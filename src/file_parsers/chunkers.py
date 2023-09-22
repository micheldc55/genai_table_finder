import re


def find_closest_position(my_list, index, element):
    # Initialize variables to keep track of left and right indexes
    left, right = index, index
    
    # Loop while both left and right are within the bounds of the list
    while left >= 0 or right < len(my_list):
        # Check the right index next, if within bounds
        if right < len(my_list) and my_list[right] == element:
            return right

        # Check the left index first, if within bounds
        if left >= 0 and my_list[left] == element:
            return left
        
        # Decrement the left and increment the right indexes
        left -= 1
        right += 1

    # If we don't find the element, return -1 or some default value
    return -1


def split_sql_into_chunks(sql_text: str, tokenizer, split_at: str = "\n", max_tokens=1500):
    sql_tokens = tokenizer.encode(sql_text)
    num_tokens = len(sql_tokens)
    q, _ = divmod(num_tokens, max_tokens)

    elem_to_find = tokenizer.encode(split_at)[0]

    chunks = []
    pos_before = 0

    for i in range(q):
        index = (i + 1) * max_tokens
        print(sql_tokens)
        pos = find_closest_position(sql_tokens, index, elem_to_find)
        print(index, pos, pos_before)
        print("\n")

        text = tokenizer.decode(sql_tokens[pos_before: pos])
        chunks.append(text)

        pos_before = pos

    text = tokenizer.decode(sql_tokens[pos:])
    chunks.append(text)

    return chunks

# Sample usage
# with open(sql_file, "r") as f:
#     sql_text = f.read()

# sql_text = re.sub(r"--.*$", "", sql_text, flags=re.MULTILINE).lstrip().replace("\n\n\n", "")
# chunks = split_sql_into_chunks(sql_text)

# Now, `chunks` contains the SQL text split into chunks of approximately 1500 tokens.


if __name__ == "__main__":
    # Test
    my_list = ["105"] * 100 + ["100"] + ["95"] * 50

    index = 82
    element = "100"
    print(find_closest_position(my_list, index, element))