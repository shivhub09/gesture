from flask import Flask, request, jsonify
import torch
from PIL import Image
from transformers import AutoImageProcessor, AutoModelForImageClassification

app = Flask(__name__)

# Load the processor and model for ASL ViT
processor = AutoImageProcessor.from_pretrained("akahana/asl-vit")
model = AutoModelForImageClassification.from_pretrained("akahana/asl-vit")

def inference(image):
    """Perform inference on the provided image."""
    with torch.no_grad():
        inputs = processor(image, return_tensors="pt")
        logits = model(**inputs).logits
        predicted_label = logits.argmax(-1).item()
        return model.config.id2label[predicted_label]

def process_image(image_bytes):
    """Convert image bytes to a PIL image and process it."""
    image = Image.open(image_bytes)
    image = image.convert("RGB")
    return image

@app.route('/landmarks', methods=['POST'])
def detect_landmarks():
    """Endpoint to detect landmarks from the uploaded image and make a prediction."""
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400
    image_file = request.files['image']
    try:
        # Process image and get prediction
        image = process_image(image_file)
        prediction = inference(image)
        return jsonify({
            "received": "success",
            "prediction": prediction
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/check_image', methods=['POST'])
def image_check():
    """Endpoint to check if an image is received and make a prediction."""
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400
    image_file = request.files['image']
    try:
        # Process image and get prediction
        image = process_image(image_file)
        prediction = inference(image)
        return jsonify({
            "received": "success",
            "prediction": prediction
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host="192.168.59.65", port=8080)
