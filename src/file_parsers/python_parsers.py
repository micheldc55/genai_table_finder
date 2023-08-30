import ast


class PythonParser:
    def __init__(self, file_path):
        with open(file_path, "r") as file:
            source_code = file.read()

        self.full_source_code = source_code  # Keep the original string intact
        self.source_code = source_code.splitlines(True)  # Split by lines but keep end-of-line characters
        self.tree = ast.parse(self.full_source_code)  # Parse the original string
        self.functions = {}
        self.classes = {}
        self.undented_code = []

    def get_code(self, node):
        return "".join(self.source_code[node.lineno - 1 : node.end_lineno])

    def extract(self):
        for node in self.tree.body:
            if isinstance(node, ast.FunctionDef):
                self.functions[node.name] = self.get_code(node)
            elif isinstance(node, ast.ClassDef):
                self.classes[node.name] = {
                    n.name: self.get_code(n) for n in node.body if isinstance(n, ast.FunctionDef)
                }
            else:
                self.undented_code.append(self.get_code(node))

    def report(self):
        print("Functions:")
        for function, code in self.functions.items():
            print(f"\nFunction - {function}:\n{code}")

        print("\nClasses and Methods:")
        for class_name, methods in self.classes.items():
            print(f"\nClass - {class_name}:")
            for method, code in methods.items():
                print(f"\nMethod - {method}:\n{code}")

        print("\nUndented Code:")
        for code in self.undented_code:
            print(code, end="")


if __name__ == "__main__":
    parser = PythonParser("example.py")
    parser.extract()
    # parser.report()
    print(parser.functions)
