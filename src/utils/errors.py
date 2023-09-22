
class IndexNotDefinedError(Exception):
    def __init__(self):
        super().__init__("Indexer Class has been instanciated, but no Index has been created. Please execute the create_index method on your class instance")