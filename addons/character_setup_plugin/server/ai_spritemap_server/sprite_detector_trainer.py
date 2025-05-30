import tensorflow as tf
from tensorflow.keras import layers, models
import pandas as pd
import os
from PIL import Image

# Load dataset
df = pd.read_csv("tile_labels.csv")
images = []
labels = []
for index, row in df.iterrows():
    img = Image.open(row["file_path"]).convert("RGB")
    img = img.resize((64, 64))
    img = tf.keras.preprocessing.image.img_to_array(img) / 255.0
    images.append(img)
    labels.append(1 if row["is_full_sprite"] == "true" else 0)
images = tf.stack(images)
labels = tf.convert_to_tensor(labels)

# Split dataset
dataset = tf.data.Dataset.from_tensor_slices((images, labels)).shuffle(buffer_size=100).batch(32)

# Build model
model = models.Sequential([
    layers.Conv2D(32, (3, 3), activation="relu", input_shape=(64, 64, 3)),
    layers.MaxPooling2D((2, 2)),
    layers.Conv2D(64, (3, 3), activation="relu"),
    layers.MaxPooling2D((2, 2)),
    layers.Flatten(),
    layers.Dense(64, activation="relu"),
    layers.Dense(1, activation="sigmoid")
])

# Compile and train
model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
model.fit(dataset, epochs=10)

# Save model
model.save("sprite_model")