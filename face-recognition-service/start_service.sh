#!/bin/bash
# Start Face Recognition Service on Linux/Mac

echo "========================================"
echo "Face Recognition Service Startup"
echo "========================================"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "ERROR: Virtual environment not found!"
    echo "Please run: python3 -m venv venv"
    echo "Then run: source venv/bin/activate"
    echo "Then run: pip install -r requirements.txt"
    exit 1
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "WARNING: .env file not found!"
    echo "Creating .env file..."
    python setup_env.py
    echo ""
    echo "Please update .env with your database credentials"
    exit 1
fi

# Start the service
echo ""
echo "Starting Face Recognition Service..."
echo "Service will be available at: http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop the service"
echo ""

python main.py

