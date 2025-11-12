"""
Embedding Manager for storing and retrieving face embeddings
"""
import pickle
import os
import numpy as np
from typing import Dict, List, Optional


class EmbeddingManager:
    """
    Manages face embeddings storage and retrieval using pickle
    """
    
    def __init__(self, embeddings_file='embeddings.pickle'):
        """
        Initialize embedding manager
        
        Args:
            embeddings_file: Path to the pickle file storing embeddings
        """
        self.embeddings_file = embeddings_file
        self._ensure_file_exists()
    
    def _ensure_file_exists(self):
        """Create embeddings file if it doesn't exist"""
        if not os.path.exists(self.embeddings_file):
            self._save_embeddings({})
    
    def _load_embeddings_raw(self) -> Dict[str, List[np.ndarray]]:
        """
        Load embeddings from pickle file
        
        Returns:
            Dictionary mapping employee_id to list of embeddings
        """
        try:
            if not os.path.exists(self.embeddings_file):
                return {}
            
            with open(self.embeddings_file, 'rb') as f:
                embeddings = pickle.load(f)
            
            # Ensure all values are lists of numpy arrays
            if isinstance(embeddings, dict):
                return embeddings
            else:
                return {}
                
        except Exception as e:
            print(f"Error loading embeddings: {e}")
            return {}
    
    def _save_embeddings(self, embeddings: Dict[str, List[np.ndarray]]):
        """
        Save embeddings to pickle file
        
        Args:
            embeddings: Dictionary mapping employee_id to list of embeddings
        """
        try:
            with open(self.embeddings_file, 'wb') as f:
                pickle.dump(embeddings, f)
        except Exception as e:
            print(f"Error saving embeddings: {e}")
            raise
    
    def load_embeddings(self) -> Dict[str, List[np.ndarray]]:
        """
        Public method to load embeddings
        
        Returns:
            Dictionary mapping employee_id to list of embeddings
        """
        return self._load_embeddings_raw()
    
    def add_embedding(self, employee_id: str, embedding: np.ndarray):
        """
        Add a single embedding for an employee
        
        Args:
            employee_id: Employee identifier
            embedding: Face embedding vector
        """
        embeddings = self._load_embeddings_raw()
        
        if employee_id not in embeddings:
            embeddings[employee_id] = []
        
        embeddings[employee_id].append(embedding)
        self._save_embeddings(embeddings)
    
    def add_embeddings(self, employee_id: str, embedding_list: List[np.ndarray]):
        """
        Add multiple embeddings for an employee
        
        Args:
            employee_id: Employee identifier
            embedding_list: List of face embedding vectors
        """
        embeddings = self._load_embeddings_raw()
        
        if employee_id not in embeddings:
            embeddings[employee_id] = []
        
        embeddings[employee_id].extend(embedding_list)
        self._save_embeddings(embeddings)
    
    def get_embeddings(self, employee_id: str) -> Optional[List[np.ndarray]]:
        """
        Get all embeddings for a specific employee
        
        Args:
            employee_id: Employee identifier
            
        Returns:
            List of embeddings or None if employee not found
        """
        embeddings = self._load_embeddings_raw()
        return embeddings.get(employee_id)
    
    def delete_employee(self, employee_id: str) -> bool:
        """
        Delete all embeddings for an employee
        
        Args:
            employee_id: Employee identifier
            
        Returns:
            True if deleted, False if not found
        """
        embeddings = self._load_embeddings_raw()
        
        if employee_id in embeddings:
            del embeddings[employee_id]
            self._save_embeddings(embeddings)
            return True
        
        return False
    
    def list_employees(self) -> List[str]:
        """
        List all employee IDs with stored embeddings
        
        Returns:
            List of employee IDs
        """
        embeddings = self._load_embeddings_raw()
        return list(embeddings.keys())
    
    def get_employee_count(self) -> int:
        """
        Get total number of registered employees
        
        Returns:
            Number of employees
        """
        return len(self.list_employees())
    
    def get_total_embeddings_count(self) -> int:
        """
        Get total number of stored embeddings across all employees
        
        Returns:
            Total number of embeddings
        """
        embeddings = self._load_embeddings_raw()
        return sum(len(emb_list) for emb_list in embeddings.values())

