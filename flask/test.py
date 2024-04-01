import requests
import json

# Replace with the actual URL of your running API
api_url = "http://192.168.189.65:8080/landmarks"

# Path to your test image
image_path = "WIN_20240401_21_22_34_Pro.jpg"

# Read the image as bytes
with open(image_path, 'rb') as f:
  image_bytes = f.read()

# Prepare the request data
files = {'image': (image_path, image_bytes, 'image/jpeg')}

# Send POST request to the API
response = requests.post(api_url, files=files)

# Check for successful response
if response.status_code == 200:
  # Print the JSON response directly
  print(response.json())
#   for text in response.json():

#     print(text, len(response.json()[text]))
else:
  print(f"Error: {response.status_code} - {response.text}")
