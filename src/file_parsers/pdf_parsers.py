import logging
from dataclasses import dataclass

import pypdf

@dataclass
class PdfReader:
    """Initialize a PDF reader with pypdf"""

    path: str

    def __post_init__(self, **kwargs):
        reader = pypdf.PdfReader(self.path, **kwargs)
        self.reader = reader
        self.pages = self.reader.pages

    def __len__(self):
        return len(self.reader.pages)
    
    def __getitem__(self, index):
        return self.reader.pages[index].extract_text()
    
    def _collect_text_with_overlap(self, index, overlap):
        num_pages = len(self)
        if index == num_pages - 1:
            text = self[index]
        else:
            text = self[index] + self[index + 1][:overlap]
        
        return text
    
    def _split_page(self, text, num_characters, overlap):
        step = num_characters - overlap
        chunks = [text[i:i+num_characters] for i in range(0, len(text), step)]
        return chunks
    
    def chunk_split(self, index, num_characters, overlap):
        text = self._collect_text_with_overlap(index, overlap=overlap)
        chunks = self._split_page(text, num_characters=num_characters, overlap=overlap)
        return chunks
    
    def chunk_text(self, num_characters, overlap):
        chunks = []
        for idx in range(len(self)):
            chunks += self.chunk_split(idx, num_characters, overlap)
        
        return chunks



if __name__ == "__main__":
    doc = PdfReader("/workspace/data/test_pdf.pdf")

    text_overlapping = doc._collect_text_with_overlap(0, 7)
    # print(text_overlapping)

    split_text = doc._split_page(text_overlapping, 40, 5)
    # print(split_text)

    chunk_text = doc.chunk_split(0, 20, 5)
    print(chunk_text)

    multi_chunk = doc.chunk_text(25, 5)
    print(multi_chunk)