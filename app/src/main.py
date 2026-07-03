import logging
from flask import Flask
from db import db_pool, init_db
from routes.transacao_routes import transacao_bp
from metrics import init_metrics

# Configuração de Log
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def create_app():
    app = Flask(__name__)

    # 1. Monitoramento (Prometheus)
    init_metrics(app)

    # 2. Banco de Dados (Inicializa pool e cria tabela)
    init_db()

    # 3. Rotas (Blueprints)
    app.register_blueprint(transacao_bp)

    # 4. Health Check (Mantido aqui por ser a raiz do status da app)
    @app.route("/", methods=["GET"])
    def health_check():
        try:
            conn = db_pool.getconn()
            conn.close()
            return {"status": "ok"}, 200
        except Exception:
            return {"status": "erro", "detalhe": "Banco indisponível"}, 503

    return app

if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=8080)
