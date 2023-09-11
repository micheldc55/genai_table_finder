import logging
import os
import shutil
import subprocess
from abc import ABC, abstractmethod



logging.basicConfig(filename="clone.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

class Repository(ABC):
    def __init__(self, repo_name: str, url: str, username: str, pat: str):
        self.repo_name = repo_name
        self.url = url
        self.username = username
        self.pat = pat

    @abstractmethod
    def _create_connection_string() -> str:
        """Creates the connection string to the repository"""
        pass

    @abstractmethod
    def clone_repository():
        """Clones a repository to a specific file location"""
        pass

    @abstractmethod
    def checkout():
        """Run git checkout in the repository to switch branches"""
        pass


class AzureDevOpsRepo(Repository):
    def __init__(self, repo_name: str, url: str, username: str, pat: str, output_dir: str or None = None):
        super().__init__(repo_name, url, username, pat)
        self.output_dir= output_dir

    def _create_connection_string(self) -> str:
        return f"https://{self.username}:{self.pat}@{self.url}"

    def clone_repository(self):
        """Clones a repository to the output directory set in the class
        """
        conn_string = self._create_connection_string()
        clone_command = ["git", "clone", conn_string]

        if self.output_dir:
            clone_command.append(self.output_dir)
        
        subprocess.run(clone_command)

    def checkout(self, branch_name: str):
        """Run git checkout in the repository to switch branches"""
        subprocess.run(["git", "-C", self.output_dir, "checkout", branch_name])

    def self_destruct(self):
        """Removes the repository from the output directory set in the class attribute (output_dir)
        """
        shutil.rmtree(self.output_dir)

        print(f"Removed repository from: {self.output_dir}")