@echo off
REM Start Face Recognition Service on Windows

echo ========================================
echo Face Recognition Service Startup
echo ========================================
echo.

REM Check if virtual environment exists
if not exist "venv\" (
    echo ERROR: Virtual environment not found!
    echo Please run: python -m venv venv
    echo Then run: venv\Scripts\activate
    echo Then run: pip install -r requirements.txt
    pause
    exit /b 1
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate

REM Check if .env exists
if not exist ".env" (
    echo WARNING: .env file not found!
    echo Creating .env file...
    python setup_env.py
    echo.
    echo Please update .env with your database credentials
    pause
    exit /b 1
)

REM Start the service
echo.
echo Starting Face Recognition Service...
echo Service will be available at: http://localhost:8000
echo.
echo Press Ctrl+C to stop the service
echo.

python main.py

pause

