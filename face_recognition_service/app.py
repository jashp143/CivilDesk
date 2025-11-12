"""
Flask application for face recognition service using InsightFace
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from services.face_detector import FaceDetector
from services.face_recognizer import FaceRecognizer
from services.embedding_manager import EmbeddingManager
from services.video_processor import VideoProcessor

app = Flask(__name__)
CORS(app)

# Initialize services
face_detector = FaceDetector()
face_recognizer = FaceRecognizer()
embedding_manager = EmbeddingManager()
video_processor = VideoProcessor(face_detector, face_recognizer, embedding_manager)

# Configuration
UPLOAD_FOLDER = 'uploads'
EMBEDDINGS_FILE = 'embeddings.pickle'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'face-recognition'})


@app.route('/face/register', methods=['POST'])
def register_face():
    """
    Register a face by processing a 10-second video
    Expected: multipart/form-data with 'video' file and 'employee_id' field
    """
    try:
        if 'video' not in request.files:
            return jsonify({'error': 'No video file provided'}), 400
        
        if 'employee_id' not in request.form:
            return jsonify({'error': 'No employee_id provided'}), 400
        
        video_file = request.files['video']
        employee_id = request.form['employee_id']
        
        if video_file.filename == '':
            return jsonify({'error': 'Empty video file'}), 400
        
        # Save video temporarily
        video_path = os.path.join(UPLOAD_FOLDER, f'{employee_id}_temp.mp4')
        video_file.save(video_path)
        
        # Process video and extract embeddings
        result = video_processor.process_registration_video(video_path, employee_id)
        
        # Clean up temporary file
        if os.path.exists(video_path):
            os.remove(video_path)
        
        if result['success']:
            return jsonify({
                'success': True,
                'message': 'Face registered successfully',
                'employee_id': employee_id,
                'embeddings_count': result['embeddings_count']
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': result['error']
            }), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/face/detect', methods=['POST'])
def detect_faces():
    """
    Detect and recognize faces in an image
    Returns bounding boxes and recognized employee IDs
    Expected: multipart/form-data with 'image' file
    """
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        image_file = request.files['image']
        
        if image_file.filename == '':
            return jsonify({'error': 'Empty image file'}), 400
        
        # Save image temporarily
        image_path = os.path.join(UPLOAD_FOLDER, 'temp_detect.jpg')
        image_file.save(image_path)
        
        # Detect and recognize faces
        result = face_recognizer.detect_and_recognize(image_path)
        
        # Clean up temporary file
        if os.path.exists(image_path):
            os.remove(image_path)
        
        return jsonify({
            'success': True,
            'faces': result
        }), 200
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/face/embeddings/list', methods=['GET'])
def list_embeddings():
    """List all registered employee IDs"""
    try:
        employee_ids = embedding_manager.list_employees()
        return jsonify({
            'success': True,
            'employees': employee_ids,
            'count': len(employee_ids)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/face/embeddings/<employee_id>', methods=['DELETE'])
def delete_embeddings(employee_id):
    """Delete embeddings for a specific employee"""
    try:
        success = embedding_manager.delete_employee(employee_id)
        if success:
            return jsonify({
                'success': True,
                'message': f'Embeddings deleted for employee {employee_id}'
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': f'Employee {employee_id} not found'
            }), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    print("Starting Face Recognition Service...")
    print("Loading models...")
    app.run(host='0.0.0.0', port=8000, debug=True)

