from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
from PIL import Image
import io

app = Flask(__name__)
model = tf.keras.models.load_model("sprite_model")

@app.route("/predict", methods=["POST"])
def predict():
    file = request.files["image"]
    img = Image.open(io.BytesIO(file.read())).convert("RGB").resize((64, 64))
    img_array = tf.keras.preprocessing.image.img_to_array(img) / 255.0
    img_array = tf.expand_dims(img_array, 0)
    prediction = model.predict(img_array)[0][0]
    return jsonify({"is_full_sprite": bool(prediction > 0.5)})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)