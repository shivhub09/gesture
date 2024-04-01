from flask import Flask


app = Flask(__name__)


@app.route('/testing', methods=["GET"])
def main():
    return "The backend is running"



if __name__ == '__main__':
    app.run()