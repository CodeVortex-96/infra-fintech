from flask import Flask, request, jsonify
import psycopg2
from psycopg2 import pool
import os
import sys
import logging
import time

# Configuração de Log
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configurações
DB_HOST = os.environ.get("DB_HOST", "postgres-service")
DB_NAME = os.environ.get("DB_NAME", "fintech_db")
DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASSWORD")

if not all([DB_USER, DB_PASS]):
    logger.error("Configuração de banco de dados incompleta.")
    sys.exit(1)

# --- INICIALIZAÇÃO RESILIENTE DO POOL ---
# Mantemos o pool aqui porque ele é o coração da conexão.
db_pool = None
retries = 10

while retries > 0:
    try:
        db_pool = psycopg2.pool.SimpleConnectionPool(1, 10, host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS)
        logger.info("Pool de conexões inicializado.")
        break
    except Exception as e:
        retries -= 1
        logger.warning(f"Banco não pronto, tentando em 5s... ({retries} tentativas restantes). Erro: {e}")
        time.sleep(5)

if not db_pool:
    logger.critical("Não foi possível conectar ao banco após várias tentativas.")
    sys.exit(1)

# --- FUNÇÃO DE INICIALIZAÇÃO SEGURA ---
def init_db():
    """Tenta criar a tabela apenas quando o pool estiver pronto."""
    try:
        conn = db_pool.getconn()
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS movimentacoes (
                    id SERIAL PRIMARY KEY,
                    tipo VARCHAR(10) NOT NULL,
                    valor NUMERIC(10, 2) NOT NULL,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
        conn.commit()
        db_pool.putconn(conn)
        logger.info("Schema validado com sucesso.")
    except Exception as e:
        logger.error(f"Erro ao inicializar o schema: {e}")
        # Não damos sys.exit aqui para não matar o pod se for apenas um erro temporário de permissão/lock

init_db()

# --- HEALTH CHECK PARA O KUBERNETES ---
@app.route("/", methods=["GET"])
def health_check():
    """
    O Kubernetes chama isso. Se retornarmos 200, ele sabe que estamos prontos.
    Adicionamos um teste real de conexão para garantir que o banco está respondendo.
    """
    try:
        conn = db_pool.getconn()
        conn.close()
        return jsonify({"status": "ok"}), 200
    except Exception as e:
        return jsonify({"status": "erro", "detalhe": "Banco indisponível"}), 503

@app.route("/transacao", methods=["POST"])
def criar_transacao():
    dados = request.get_json() or {}
    tipo = dados.get("tipo")
    valor_raw = dados.get("valor")

    if not tipo or valor_raw is None:
        return jsonify({"status": "erro", "mensagem": "Campos obrigatórios ausentes."}), 400

    if tipo not in ["credito", "debito"]:
        return jsonify({"status": "erro", "mensagem": "Tipo inválido."}), 400

    try:
        valor = float(valor_raw)
        if valor <= 0:
            return jsonify({"status": "erro", "mensagem": "Valor deve ser positivo."}), 400
    except (ValueError, TypeError):
        return jsonify({"status": "erro", "mensagem": "Valor deve ser numérico."}), 400

    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO movimentacoes (tipo, valor) VALUES (%s, %s) RETURNING id, timestamp;",
                (tipo, valor)
            )
            id_transacao, ts = cur.fetchone()
        conn.commit()
        return jsonify({
            "status": "sucesso",
            "transacao_id": id_transacao,
            "timestamp": ts.isoformat()
        }), 201
    except Exception as e:
        conn.rollback()
        logger.error(f"Erro na transação: {e}")
        return jsonify({"status": "erro", "detalhe": "Erro interno."}), 500
    finally:
        db_pool.putconn(conn)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
