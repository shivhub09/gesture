from flask import Flask, request, jsonify
import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf
import cv2
import numpy as np
import random  # for generating noise
app = Flask(__name__)

# Initialize drawing and holistic models
mp_drawing = mp.solutions.drawing_utils
mp_holistic = mp.solutions.holistic




def process_image(image_bytes):
  # Read image from bytes
  img = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
  img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
  
  all_landmarks_list = []
  # Process the image
  all_landmarks = []
  
  with mp_holistic.Holistic(static_image_mode=True, min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:

    results = holistic.process(image=img_rgb)
    
    # Extract and format landmark data
    landmarks = {}
    if results.pose_landmarks:
        pose_landmarks = [[lm.x, lm.y, lm.z] for lm in results.pose_landmarks.landmark]
        all_landmarks.extend(pose_landmarks)

    # Extract face landmarks
    if results.face_landmarks:
        face_landmarks = [[lm.x, lm.y, lm.z] for lm in results.face_landmarks.landmark]
        all_landmarks.extend(face_landmarks)

    # Extract left hand landmarks
    if results.left_hand_landmarks:
        left_hand_landmarks = [[lm.x, lm.y, lm.z] for lm in results.left_hand_landmarks.landmark]
        all_landmarks.extend(left_hand_landmarks)

    # Extract right hand landmarks
    if results.right_hand_landmarks:
        right_hand_landmarks = [[lm.x, lm.y, lm.z] for lm in results.right_hand_landmarks.landmark]
        all_landmarks.extend(right_hand_landmarks)

    # Append the landmarks of this frame to the list
    all_landmarks_list.append(all_landmarks)
    max_landmarks = max(len(landmarks) for landmarks in all_landmarks_list)
# Ensure that the shape is (100, 543, 3) by padding with NaN values
    padded_landmarks = []
    for landmarks in all_landmarks_list:
        padded_landmarks.append(landmarks + [[np.nan, np.nan, np.nan]] * (543 - len(landmarks)))
    print("padding")
    # Convert the list of landmarks to a TensorFlow tensor
    all_landmarks_tensor = tf.convert_to_tensor(padded_landmarks, dtype=tf.float32)
    all_landmarks_tensor2 = [all_landmarks_tensor for _ in range(100)]
    print("Shape of all landmarks tensor before reshaping:", all_landmarks_tensor.shape)

    # Reshape the tensor to have shape (100, 1629)
    all_landmarks_tensor_reshaped = tf.reshape(all_landmarks_tensor2, (100, -1))

    print("Shape of all landmarks tensor after reshaping:", all_landmarks_tensor_reshaped.shape)

    # shape_before_reshaping = tuple(all_landmarks_tensor.shape.as_list())
    # shape_after_reshaping = tuple(all_landmarks_tensor_reshaped.shape.as_list())

    return all_landmarks_tensor_reshaped

@app.route('/landmarks', methods=['POST'])
def detect_landmarks():
  # Get uploaded image
  if 'image' not in request.files:
    return jsonify({'error': 'No image uploaded'}), 400
  image = request.files['image'].read()

  # Process image and get landmarks
  try:
    landmarks = process_image(image)
    print(landmarks)
    return jsonify({
       "recived":"success",
       "landmarks":landmarks.numpy().tolist()
    })
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