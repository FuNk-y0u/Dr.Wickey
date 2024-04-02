from inc import *
from init import app

from views.view_aimodel import ai_model

app.add_url_rule("/ai", view_func=ai_model, methods=["POST"])

if __name__ == "__main__":
    app.run(host="192.168.11.123", port=8000, debug=True)