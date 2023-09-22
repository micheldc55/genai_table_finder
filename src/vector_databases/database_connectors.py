import logging
from typing import List

import numpy as np
import pinecone  
import torch
import faiss

from src.utils.errors import IndexNotDefinedError


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

class PineConnector:
    def __init__(self, api_key: str, env: str, index_name: str):
        pinecone.init(      
            api_key=api_key,      
            environment=env   
        )      
        self.index = pinecone.Index(index_name)
        logging.info(f"SUCCESS: Connected to Pinecone index: {index_name}")

    def describe(self):
        return self.index.describe_index_stats()
    
    def fetch(self, ids: List[str], namespace: str or None):
        return self.index.fetch(ids=ids, namespace=namespace)
    
    def multi_query(self, queries: np.ndarray, **kwargs):
        pass
    
    def _query(
            self, 
            vector: list, 
            top_k: int = 1, 
            output_vectors: bool = False, 
            output_metadata: bool = False,
            namespace: str or None = None,
            filter_obj: object = None,
        ):
        return self.index.query(vector=vector, 
                                    top_k=top_k,
                                    include_values=output_vectors,
                                    include_metadata=output_metadata,
                                    namespace=namespace,
                                    filter=filter_obj)
    
    def insert_emebeddings_torch(self, 
               embeddings: torch.Tensor or np.ndarray, 
               ids: List[str], 
               metadata: List[str] or None,
               batch_size: int):
        num_embeddings = embeddings.shape[0]
        
        num_batches, remainder = divmod(num_embeddings, batch_size)

        if remainder != 0:
            num_batches += 1

        for i in range(num_batches):
            start, end = i * batch_size, (i+1) * batch_size

            ids_batch = ids[start:end]
            embedding_batch = embeddings[start:end]

            if metadata:
                metadata_batch = metadata[start:end]
                to_upsert = zip(ids_batch, embedding_batch, metadata)
                self.index.upsert(vectors=list(to_upsert))
  
            else:
                to_upsert = zip(ids_batch, embedding_batch)
                self.index.upsert(vectors=list(to_upsert))
