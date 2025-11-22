#!/usr/bin/env python3
"""
Benchmark script for live video face detection
Tests the performance of the face recognition engine in live video mode
"""

import cv2
import numpy as np
import time
from pathlib import Path
import sys

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from face_recognition_engine import FaceRecognitionEngine
from config import Config

def generate_test_frame(width=640, height=480):
    """Generate a test frame with random content"""
    return np.random.randint(0, 255, (height, width, 3), dtype=np.uint8)

def benchmark_detection(engine, num_frames=100, fast_mode=True):
    """Benchmark face detection on video frames"""
    print(f"\nBenchmarking Detection (fast_mode={fast_mode})...")
    print("=" * 60)
    
    total_time = 0
    frames_with_faces = 0
    
    for i in range(num_frames):
        frame = generate_test_frame()
        
        start = time.time()
        faces = engine.detect_faces(frame, fast_mode=fast_mode)
        elapsed = time.time() - start
        
        total_time += elapsed
        if len(faces) > 0:
            frames_with_faces += 1
        
        if (i + 1) % 10 == 0:
            avg_time = total_time / (i + 1)
            fps = 1.0 / avg_time if avg_time > 0 else 0
            print(f"Processed {i + 1}/{num_frames} frames | "
                  f"Avg: {avg_time*1000:.1f}ms | FPS: {fps:.1f}")
    
    avg_time = total_time / num_frames
    fps = 1.0 / avg_time if avg_time > 0 else 0
    
    print(f"\nResults:")
    print(f"  Total frames: {num_frames}")
    print(f"  Total time: {total_time:.2f}s")
    print(f"  Average time per frame: {avg_time*1000:.1f}ms")
    print(f"  Frames per second: {fps:.1f} FPS")
    print(f"  Frames with faces: {frames_with_faces}")
    
    return avg_time, fps

def benchmark_recognition(engine, num_frames=100):
    """Benchmark face recognition on video frames"""
    print(f"\nBenchmarking Recognition (with caching)...")
    print("=" * 60)
    
    total_time = 0
    recognized_faces = 0
    
    for i in range(num_frames):
        frame = generate_test_frame()
        
        start = time.time()
        faces = engine.recognize_face(frame, fast_mode=True)
        elapsed = time.time() - start
        
        total_time += elapsed
        recognized_faces += sum(1 for f in faces if f['recognized'])
        
        if (i + 1) % 10 == 0:
            avg_time = total_time / (i + 1)
            fps = 1.0 / avg_time if avg_time > 0 else 0
            print(f"Processed {i + 1}/{num_frames} frames | "
                  f"Avg: {avg_time*1000:.1f}ms | FPS: {fps:.1f} | "
                  f"Recognized: {recognized_faces}")
    
    avg_time = total_time / num_frames
    fps = 1.0 / avg_time if avg_time > 0 else 0
    
    print(f"\nResults:")
    print(f"  Total frames: {num_frames}")
    print(f"  Total time: {total_time:.2f}s")
    print(f"  Average time per frame: {avg_time*1000:.1f}ms")
    print(f"  Frames per second: {fps:.1f} FPS")
    print(f"  Total recognized faces: {recognized_faces}")
    
    return avg_time, fps

def benchmark_cache_effectiveness(engine, num_frames=50):
    """Test cache effectiveness with simulated temporal consistency"""
    print(f"\nBenchmarking Cache Effectiveness...")
    print("=" * 60)
    
    # Generate base frame
    base_frame = generate_test_frame()
    
    cache_hits = 0
    total_time_with_cache = 0
    
    for i in range(num_frames):
        # Simulate slight camera movement by adding noise
        noise = np.random.randint(-5, 5, base_frame.shape, dtype=np.int16)
        frame = np.clip(base_frame.astype(np.int16) + noise, 0, 255).astype(np.uint8)
        
        start = time.time()
        faces = engine.recognize_face(frame, fast_mode=True)
        elapsed = time.time() - start
        
        total_time_with_cache += elapsed
        
        # Estimate cache hits (rough approximation)
        if i > 0 and elapsed < 0.02:  # Very fast responses likely cache hits
            cache_hits += 1
    
    avg_time = total_time_with_cache / num_frames
    cache_hit_rate = (cache_hits / num_frames) * 100
    
    print(f"\nResults:")
    print(f"  Average time: {avg_time*1000:.1f}ms")
    print(f"  Estimated cache hit rate: {cache_hit_rate:.1f}%")
    print(f"  Performance gain from caching: ~{cache_hits * 20}ms saved")

def main():
    """Run all benchmarks"""
    print("=" * 60)
    print("Live Video Face Detection Benchmark")
    print("=" * 60)
    
    print("\nConfiguration:")
    print(f"  GPU Enabled: {Config.USE_GPU}")
    print(f"  Detection Threshold: {Config.FACE_DETECTION_THRESHOLD}")
    print(f"  Matching Threshold: {Config.FACE_MATCHING_THRESHOLD}")
    print(f"  Cache Duration: {Config.STREAM_CACHE_DURATION}s")
    
    try:
        # Initialize engine
        print("\nInitializing face recognition engine...")
        engine = FaceRecognitionEngine()
        print("✓ Engine initialized")
        
        # Run benchmarks
        benchmark_detection(engine, num_frames=50, fast_mode=False)
        benchmark_detection(engine, num_frames=50, fast_mode=True)
        benchmark_recognition(engine, num_frames=50)
        benchmark_cache_effectiveness(engine, num_frames=50)
        
        print("\n" + "=" * 60)
        print("Benchmark Complete!")
        print("=" * 60)
        
        # Recommendations
        print("\nRecommendations:")
        if Config.USE_GPU:
            print("  ✓ GPU is enabled - optimal for live video")
        else:
            print("  ⚠ GPU is disabled - consider enabling for better performance")
        
        print("\nFor live video streaming:")
        print("  • Use fast_mode=True for best performance")
        print("  • Enable face tracking cache (ENABLE_FACE_TRACKING=True)")
        print("  • Send frames every 1-2 seconds from frontend")
        print("  • Monitor cache hit rate for optimal settings")
        
    except Exception as e:
        print(f"\n✗ Benchmark failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()

