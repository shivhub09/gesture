from flask import Flask, request, jsonify
import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf
import cv2
import numpy as np
import json

app = Flask(__name__)

###############################################################################333
mp_drawing = mp.solutions.drawing_utils
mp_holistic = mp.solutions.holistic

interpreter = tf.lite.Interpreter("model.tflite")

REQUIRED_SIGNATURE = "serving_default"
REQUIRED_OUTPUT = "outputs"

prediction_fn = interpreter.get_signature_runner(REQUIRED_SIGNATURE)


with open ("character_to_prediction_index.json", "r") as f:
        character_map = json.load(f)
        rev_character_map = {j:i for i,j in character_map.items()}
###############################################################################



def process_image(image_bytes):
  img = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
  img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
  
  all_landmarks_list = []
  all_landmarks = []
  
  with mp_holistic.Holistic(static_image_mode=True, min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:

    results = holistic.process(image=img_rgb)
    
    landmarks = {}
    if results.pose_landmarks:
        pose_landmarks = [[lm.x, lm.y, lm.z] for lm in results.pose_landmarks.landmark]
        all_landmarks.extend(pose_landmarks)

    if results.face_landmarks:
        face_landmarks = [[lm.x, lm.y, lm.z] for lm in results.face_landmarks.landmark]
        all_landmarks.extend(face_landmarks)

    if results.left_hand_landmarks:
        left_hand_landmarks = [[lm.x, lm.y, lm.z] for lm in results.left_hand_landmarks.landmark]
        all_landmarks.extend(left_hand_landmarks)

    if results.right_hand_landmarks:
        right_hand_landmarks = [[lm.x, lm.y, lm.z] for lm in results.right_hand_landmarks.landmark]
        all_landmarks.extend(right_hand_landmarks)

    all_landmarks_list.append(all_landmarks)
    max_landmarks = max(len(landmarks) for landmarks in all_landmarks_list)

# Ensure that the shape is (100, 543, 3) by padding with NaN values
    padded_landmarks = []
    for landmarks in all_landmarks_list:
        padded_landmarks.append(landmarks + [[np.nan, np.nan, np.nan]] * (543 - len(landmarks)))
    print("padding")

    all_landmarks_tensor = tf.convert_to_tensor(padded_landmarks, dtype=tf.float32)


    #  imp line
    all_landmarks_tensor2 = [all_landmarks_tensor for _ in range(100)]


    
    print("Shape of all landmarks tensor before reshaping:", all_landmarks_tensor.shape)

    # Reshape the tensor to have shape (100, 1629)
    all_landmarks_tensor_reshaped = tf.reshape(all_landmarks_tensor2, (100, -1))

    print("Shape of all landmarks tensor after reshaping:", all_landmarks_tensor_reshaped.shape)


    return all_landmarks_tensor_reshaped

@app.route('/landmarks', methods=['POST'])
def detect_landmarks():
  if 'image' not in request.files:
    return jsonify({'error': 'No image uploaded'}), 400
  image = request.files['image'].read()

  # Process image and get landmarks
  try:
    
    landmarks = process_image(image)
    output = prediction_fn(inputs=landmarks)
    prediction_str = "".join([rev_character_map.get(s, "") for s in np.argmax(output[REQUIRED_OUTPUT], axis=1)])
    print(prediction_str)

    return jsonify({
       "recived":"success",
       "prediction":prediction_str
    })
  except Exception as e:
    return jsonify({'error': str(e)}), 500


def check_image_received():
    """Checks if an image has been received in the request."""
    # if 'image' in request.files:

    #     return jsonify({'message': 'Image received'}), 200
    # else:
    #     return jsonify({'error': 'No image found in request'}), 400
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400
    image = request.files['image'].read()

    # Process image and get landmarks
    try:
        
        landmarks = process_image(image)
        output = prediction_fn(inputs=landmarks)
        prediction_str = "".join([rev_character_map.get(s, "") for s in np.argmax(output[REQUIRED_OUTPUT], axis=1)])
        print(prediction_str)

        return jsonify({
        "recived":"success",
        "prediction":prediction_str
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

    

@app.route('/check_image', methods=['POST'])
def image_check():
    """Route for checking if an image is received."""
    return check_image_received()



if __name__ == '__main__':
  app.run(debug=True, host="192.168.185.65", port=8080)