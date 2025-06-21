flask_app = Flask(__name__)

@flask_app.route('/')
def flask_home():
    return "Bot activo"

def flask_run():
    flask_app.run(host='0.0.0.0', port=8080)

def start_flask():
    flask_thread = Thread(target=flask_run)
    flask_thread.daemon = True
    flask_thread.start()
    print("✅ Servidor Flask iniciado en segundo plano")