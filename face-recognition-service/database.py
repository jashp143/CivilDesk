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
    
    @staticmethod
    def update_punch_time(attendance_id: int, punch_type: str, new_time: str):
        """
        Update punch time for an attendance record (admin function)
        
        Args:
            attendance_id: Attendance record ID
            punch_type: Type of punch (check_in, lunch_out, lunch_in, check_out)
            new_time: New timestamp in ISO format (YYYY-MM-DD HH:MM:SS)
        """
        try:
            with Database.get_connection() as conn:
                with conn.cursor() as cursor:
                    # Validate punch type
                    valid_punch_types = ['check_in', 'lunch_out', 'lunch_in', 'check_out']
                    if punch_type not in valid_punch_types:
                        raise ValueError(f"Invalid punch type. Must be one of: {', '.join(valid_punch_types)}")
                    
                    # Check if attendance record exists
                    cursor.execute(
                        """
                        SELECT id FROM attendance WHERE id = %s
                        """,
                        (attendance_id,)
                    )
                    existing = cursor.fetchone()
                    
                    if not existing:
                        raise ValueError(f"Attendance record with ID {attendance_id} not found")
                    
                    # Update the appropriate punch time
                    if punch_type == 'check_in':
                        cursor.execute(
                            """
                            UPDATE attendance 
                            SET check_in_time = %s
                            WHERE id = %s
                            """,
                            (new_time, attendance_id)
                        )
                    elif punch_type == 'lunch_out':
                        cursor.execute(
                            """
                            UPDATE attendance 
                            SET lunch_out_time = %s
                            WHERE id = %s
                            """,
                            (new_time, attendance_id)
                        )
                    elif punch_type == 'lunch_in':
                        cursor.execute(
                            """
                            UPDATE attendance 
                            SET lunch_in_time = %s
                            WHERE id = %s
                            """,
                            (new_time, attendance_id)
                        )
                    elif punch_type == 'check_out':
                        cursor.execute(
                            """
                            UPDATE attendance 
                            SET check_out_time = %s
                            WHERE id = %s
                            """,
                            (new_time, attendance_id)
                        )
                    
                    logger.info(f"Updated {punch_type} time for attendance ID {attendance_id} to {new_time}")
                    return True
                    
        except Exception as e:
            logger.error(f"Error updating punch time: {str(e)}")
            raise
    
    @staticmethod
    def get_attendance_by_id(attendance_id: int):
        """Get attendance record by ID"""
        try:
            with Database.get_connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(
                        """
                        SELECT a.id, a.employee_id, a.date, 
                               a.check_in_time, a.lunch_out_time, 
                               a.lunch_in_time, a.check_out_time,
                               a.status, a.recognition_method,
                               a.face_recognition_confidence,
                               e.first_name, e.last_name
                        FROM attendance a
                        JOIN employees e ON a.employee_id = e.employee_id
                        WHERE a.id = %s
                        """,
                        (attendance_id,)
                    )
                    return cursor.fetchone()
        except Exception as e:
            logger.error(f"Error fetching attendance {attendance_id}: {str(e)}")
            return None

