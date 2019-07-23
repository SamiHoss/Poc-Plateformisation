from flask import Flask
import requests

app = Flask(__name__)

@app.route('/', methods=['GET'])
def call_remote_panorama():

    url = 'http://34.77.0.121:8080/services/carrefour-banque/v1/panoramas/606'
    response = requests.get(url)

    return response.json()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)