import sys
sys.path.append("/workspace")

import faiss
import numpy as np
import pandas as pd

from src.utils.errors import IndexNotDefinedError


class IDMapper:
    """Implements a Mapper that uniquely pairs IDs to elements. The IDs should be the real data you want 
    to keep!"""
    def __init__(self):
        self.ids = np.array([], dtype=np.int64)
        self.used_indexes = np.array([])
        self.mapping = {}

    def update_id_mapping(self, id_array):
        size = id_array.shape[0]
        random_integers = np.random.randint(low=0, high=10_000_000, size=size)
        is_unique = self._check_uniqueness(random_integers)
        is_unused = self._check_unused(random_integers, self.used_indexes)

        while not (is_unique and is_unused):
            random_integers = np.random.randint(low=0, high=10_000_000, size=size)
            is_unique = self._check_uniqueness(random_integers)
            is_unused = self._check_unused(random_integers, self.used_indexes)

        self.mapping.update(dict(zip(random_integers, id_array)))
        self.used_indexes = np.append(self.used_indexes, random_integers)

    def load_mapping_from_csv(self, mapping_path: str):
        mapping_df = pd.read_csv(mapping_path)
        
        # Reconstruct the mapping dictionary
        self.mapping = dict(zip(mapping_df['id'], mapping_df['text']))
        
        # Reconstruct the used_indexes array
        self.used_indexes = np.array(list(self.mapping.keys()))

    def decode(self, indexes):
        if indexes.shape[0] == 1:
            adj_index = indexes.squeeze(0)
        else:
            adj_index = indexes

        return [self.mapping[index] for index in adj_index]
    
    def _convert_mapping_to_df(self):
        dictionary = self.mapping

        id_list = [id for id in dictionary.keys()]
        text_list = [text for text in dictionary.values()]

        return pd.DataFrame({"id": id_list, "text": text_list})

    @staticmethod
    def _check_uniqueness(array1):
        if len(array1) == len(np.unique(array1)):
            return True
        else:
            return False
        
    @staticmethod
    def _check_unused(new_array, array_ref):
        if np.isin(new_array, array_ref).any():
            # At least onw element of "new_array" is present in "array_ref"
            return False
        else:
            # No repeated elements
            return True
        
class FAISSIndexer:
    """Implements a simple FAISS index class that can be used to create and search an index"""
    
    def __init__(self, idx_type: str or None = None):
        self.idx_type = idx_type
        self.index = None

        if idx_type == "idmap":
            self.ids_to_idx_mapping = IDMapper()

    def create_index(self, hidden_dimension):
        if self.idx_type.lower() == "flat":
            self.index = faiss.IndexFlatIP(hidden_dimension)
        elif self.idx_type.lower() == "idmap":
            self.index = faiss.IndexIDMap(faiss.IndexFlatIP(hidden_dimension))
        else:
            raise IndexNotDefinedError()

    def add_vectors(self, vectors, ids: np.ndarray or None = None):
        if self.index is None:
            raise IndexNotDefinedError()
        if self.idx_type.lower() == "idmap":
            self.ids_to_idx_mapping.update_id_mapping(ids)
            int_ids = self.ids_to_idx_mapping.used_indexes
            self.index.add_with_ids(vectors, int_ids)
        else:
            self.index.add(vectors)

    def search_vectors(self, vectors, k: int or None = None):
        if self.index is None:
            raise IndexNotDefinedError()
        distance, ids = self.index.search(vectors, k)
        return distance, ids
    
    def save_index(self, path: str, mapping_path: str or None = None):
        if self.index is None:
            raise IndexNotDefinedError()
        faiss.write_index(self.index, path)

        if self.idx_type.lower() == "idmap":
            mapping_df = self.ids_to_idx_mapping._convert_mapping_to_df()
            mapping_df.to_csv(mapping_path, index=False)

    def load_index(self, path: str, mapping_path: str or None = None):
        # Load FAISS index from the given path
        self.index = faiss.read_index(path)

        if self.idx_type.lower() == "idmap" and mapping_path:
            # Use the IDMapper method to load its state
            self.ids_to_idx_mapping.load_mapping_from_csv(mapping_path)

        elif self.idx_type.lower() == "idmap" and not mapping_path:
            raise ValueError("For 'idmap' type, mapping_path must be provided.")

    


if __name__ == "__main__":
    import os
    from dotenv import load_dotenv
    import openai
    from src.llms.openai_models import OpenAiEmbeddings

    index = FAISSIndexer("idmap")
    index_path = "/workspace/data/indexes/Kullback–Leibler_divergenc.index"
    mapping_path = "/workspace/data/indexes/Kullback–Leibler_divergenc.csv"

    index.load_index(index_path, mapping_path)

    load_dotenv()
    openai.api_key = os.environ.get("OPENAI_KEY")
    embedding = OpenAiEmbeddings(model="text-embedding-ada-002")

    test_text = ["What parallel can we draw from finance and game theory?"]
    test_response = embedding.embed_text(messages=test_text)
    test_np_embeddings = embedding.get_numpy_embeddings(test_response)

    results = index.search_vectors(test_np_embeddings, k=2)

    int_ids = results[1]
    print(index.ids_to_idx_mapping.decode(int_ids))