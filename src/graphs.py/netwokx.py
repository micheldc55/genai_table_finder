import os

import networkx
import pandas as pd
import matplotlib.pyplot as plt


df = pd.read_csv("/workspace/repositories/parsed_results/parsed_sql_tables.csv")
print(df.head(2))

print(df.iloc[1]["sql_paths"])

class GraphNX:
    def __init__(self, data_dir: str):
        self.graph = networkx.Graph()

# def create_graph():
#     G = nx.Graph()  # Create an undirected graph. Use nx.DiGraph() for directed graph.

#     # Add nodes (representing files/tables)
#     files_and_tables = ['file1', 'file2', 'table1', 'table2']
#     for item in files_and_tables:
#         G.add_node(item)

#     # Add edges (connections between files/tables)
#     connections = [('file1', 'table1'), ('file2', 'table2'), ('file1', 'file2')]
#     for connection in connections:
#         G.add_edge(*connection)

#     return G

# def visualize_graph(G):
#     pos = nx.spring_layout(G)  # Positioning of nodes. You can use other layouts too.
#     nx.draw(G, pos, with_labels=True, node_size=3000, node_color='skyblue', font_size=15, width=2, edge_color='gray')
#     plt.title('Files and Tables Connections')
#     plt.show()

# if __name__ == "__main__":
#     G = create_graph()
#     visualize_graph(G)
