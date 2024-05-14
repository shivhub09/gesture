import requests

api_url = "http://192.168.59.65:8080/check_image"
image_path = "a.jpeg"

with open(image_path, 'rb') as f:
    files = {'image': (image_path, f, 'image/jpeg')}
    response = requests.post(api_url, files=files)

if response.status_code == 200:
    print(response.json())
else:
    print(f"Error: {response.status_code} - {response.text}")
