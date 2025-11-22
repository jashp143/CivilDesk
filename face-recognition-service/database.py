import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from config import Config
import logging

logger = logging.getLogger(__name__)

class Database:
    """Database connection handler for PostgreSQL"""
    
    @staticmethod
    @contextmanager
    def get_connection():
        """Get a database connection context manager"""
        conn = None
        try:
            conn = psycopg2.connect(
                host=Config.DB_HOST,
                port=Config.DB_PORT,
                database=Config.DB_NAME,
                user=Config.DB_USER,
                password=Config.DB_PASSWORD,
                cursor_factory=RealDictCursor
            )
            yield conn
            conn.commit()
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"Database error: {str(e)}")
            raise
        finally:
            if conn:
                conn.close()
    
    @staticmethod
    def get_employee_by_id(employee_id: str):
        """Get employee details by employee_id"""
        try:
            with Database.get_connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(
                        """
                        SELECT id, employee_id, first_name, last_name, email, 
                               phone_number, department, designation, is_active
                        FROM employees 
                        WHERE employee_id = %s AND is_active = true
                        """,
                        (employee_id,)
                    )
                    return cursor.fetchone()
        except Exception as e:
            logger.error(f"Error fetching employee {employee_id}: {str(e)}")
            return None
    
    @staticmethod
    def get_all_active_employees():
        """Get all active employees"""
        try:
            with Database.get_connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(
                        """
                        SELECT id, employee_id, first_name, last_name, email
                        FROM employees 
                        WHERE is_active = true
                        ORDER BY first_name, last_name
                        """
                    )
                    return cursor.fetchall()
        except Exception as e:
            logger.error(f"Error fetching employees: {str(e)}")
            return []
    
    @staticmethod
    def mark_attendance(employee_id: str, punch_type: str, confidence: float):
        """Mark attendance for an employee"""
        try:
            with Database.get_connection() as conn:
                with conn.cursor() as cursor:
                    # Check if attendance record exists for today
                    cursor.execute(
                        """
                        SELECT id FROM attendance 
                        WHERE employee_id = %s AND DATE(date) = CURRENT_DATE
                        """,
                        (employee_id,)
                    )
                    existing = cursor.fetchone()
                    
                    if existing:
                        # Update existing attendance record
                        if punch_type == 'check_in':
                            cursor.execute(
                                """
                                UPDATE attendance 
                                SET check_in_time = CURRENT_TIMESTAMP,
                                    recognition_method = 'FACE_RECOGNITION',
                                    face_recognition_confidence = %s,
                                    status = 'PRESENT'
                                WHERE id = %s
                                """,
                                (confidence, existing['id'])
                            )
                        elif punch_type == 'lunch_out':
                            cursor.execute(
                                """
                                UPDATE attendance 
                                SET lunch_out_time = CURRENT_TIMESTAMP
                                WHERE id = %s
                                """,
                                (existing['id'],)
                            )
                        elif punch_type == 'lunch_in':
                            cursor.execute(
                                """
                                UPDATE attendance 
                                SET lunch_in_time = CURRENT_TIMESTAMP
                                WHERE id = %s
                                """,
                                (existing['id'],)
                            )
                        elif punch_type == 'check_out':
                            cursor.execute(
                                """
                                UPDATE attendance 
                                SET check_out_time = CURRENT_TIMESTAMP
                                WHERE id = %s
                                """,
                                (existing['id'],)
                            )
                    else:
                        # Create new attendance record
                        cursor.execute(
                            """
                            INSERT INTO attendance 
                            (employee_id, date, check_in_time, recognition_method, 
                             face_recognition_confidence, status)
                            VALUES (%s, CURRENT_DATE, CURRENT_TIMESTAMP, 'FACE_RECOGNITION', %s, 'PRESENT')
                            RETURNING id
                            """,
                            (employee_id, confidence)
                        )
                        return cursor.fetchone()['id']
                    
                    return existing['id'] if existing else None
        except Exception as e:
            logger.error(f"Error marking attendance for {employee_id}: {str(e)}")
            raise

