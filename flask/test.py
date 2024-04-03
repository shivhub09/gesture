import requests
import json

api_url = "http://192.168.185.65:8080/check_image"

image_path = "WIN_20240402_18_44_47_Pro.jpg"

with open(image_path, 'rb') as f:
  image_bytes = f.read()

files = {'image': (image_path, image_bytes, 'image/jpeg')}

response = requests.post(api_url, files=files)

if response.status_code == 200:
  print(response.json())

else:
  print(f"Error: {response.status_code} - {response.text}")
