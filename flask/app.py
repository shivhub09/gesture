from flask import Flask, request, jsonify
import cv2
import mediapipe as mp
import numpy as np
app = Flask(__name__)

# Initialize drawing and holistic models
mp_drawing = mp.solutions.drawing_utils
mp_holistic = mp.solutions.holistic

def process_image(image_bytes):
  # Read image from bytes
  img = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
  img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

  # Process the image
  with mp_holistic.Holistic(static_image_mode=True, min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:

    results = holistic.process(image=img_rgb)

    # Extract and format landmark data
    landmarks = {}
    if results.pose_landmarks:
      landmarks["pose"] = []
      for landmark in results.pose_landmarks.landmark:
        landmarks["pose"].append((landmark.x, landmark.y))
    if results.face_landmarks:
      landmarks["face"] = []
      for landmark in results.face_landmarks.landmark:
        landmarks["face"].append((landmark.x, landmark.y))
    if results.left_hand_landmarks:
      landmarks["left_hand"] = []
      for landmark in results.left_hand_landmarks.landmark:
        landmarks["left_hand"].append((landmark.x, landmark.y))
    if results.right_hand_landmarks:
      landmarks["right_hand"] = []
      for landmark in results.right_hand_landmarks.landmark:
        landmarks["right_hand"].append((landmark.x, landmark.y))

    return landmarks

@app.route('/landmarks', methods=['POST'])
def detect_landmarks():
  # Get uploaded image
  if 'image' not in request.files:
    return jsonify({'error': 'No image uploaded'}), 400
  image = request.files['image'].read()

  # Process image and get landmarks
  try:
    landmarks = process_image(image)
    return jsonify(landmarks)
  except Exception as e:
    return jsonify({'error': str(e)}), 500


def check_image_received():
    """Checks if an image has been received in the request."""
    if 'image' in request.files:
        return jsonify({'message': 'Image received'}), 200
    else:
        return jsonify({'error': 'No image found in request'}), 400

@app.route('/check_image', methods=['POST'])
def image_check():
    """Route for checking if an image is received."""
    return check_image_received()



if __name__ == '__main__':
  app.run(debug=True, host="192.168.189.65", port=8080)