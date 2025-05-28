import librosa
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub
import sys
import json
import os

def load_yamnet():
    """Load YAMNet model from TensorFlow Hub."""
    model = hub.load('https://tfhub.dev/google/yamnet/1')
    return model

def load_class_map():
    """Load YAMNet class map from CSV."""
    # YAMNet class map (simplified, from AudioSet ontology)
    # Using a local mapping for common game audio classes
    class_map = {
        0: "Speech",
        1: "Footsteps",
        2: "Explosion",
        3: "Thunder",
        4: "Gunshot",
        5: "Wind",
        6: "Water",
        7: "Fire",
        8: "Vehicle",
        9: "Music",
        # Add more as needed (YAMNet has 521 classes)
    }
    return class_map

def analyze_audio(file_path):
    """Analyze audio file and return metadata with tags."""
    try:
        # Check if file exists
        if not os.path.exists(file_path):
            return {"error": f"File not found: {file_path}"}

        # Load audio with librosa
        y, sr = librosa.load(file_path, sr=None, mono=True)
        
        # Basic metadata
        duration = librosa.get_duration(y=y, sr=sr)
        file_size = os.path.getsize(file_path)
        channels = 1 if len(y.shape) == 1 else y.shape[0]
        
        # Resample to 16 kHz for YAMNet
        if sr != 16000:
            y = librosa.resample(y, orig_sr=sr, target_sr=16000)
            sr = 16000
        
        # Load YAMNet model
        yamnet = load_yamnet()
        class_map = load_class_map()
        
        # Run YAMNet inference
        scores, _, _ = yamnet(y)
        scores_np = scores.numpy()
        mean_scores = np.mean(scores_np, axis=0)
        
        # Get top 3 tags
        top_indices = np.argsort(mean_scores)[-3:][::-1]
        tags = [
            {
                "label": class_map.get(idx, f"Unknown_{idx}"),
                "score": float(mean_scores[idx])
            }
            for idx in top_indices if idx in class_map
        ]
        
        # Compile metadata
        metadata = {
            "duration": float(duration),
            "file_size": int(file_size),
            "sample_rate": int(sr),
            "channels": int(channels),
            "last_modified": float(os.path.getmtime(file_path)),
            "tags": tags
        }
        
        return metadata
    
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(json.dumps({"error": "Usage: python audio_analyzer.py <file_path>"}))
        sys.exit(1)
    
    file_path = sys.argv[1]
    result = analyze_audio(file_path)
    print(json.dumps(result, indent=2))