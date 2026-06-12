from flask import Flask, request, jsonify
from psycopg2 import pool
import os
import sys

app = Flask(__name__)

# --- CONFIGURAÇÃO CONSCIENTE VIA VARIÁVEIS DE AMBIENTE ---
DB_HOST = os.environ.get("DB_HOST", "postgres-service")
DB_NAME = os.environ.get("DB_NAME", "fintech_db")
DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASSWORD") # Puxado do K8s Secret de forma oculta

if not DB_USER or not DB_PASS:
    print("ERRO CRÍTICO: Variáveis de ambiente de banco de dados não configuradas!")
    sys.exit(1)

# --- CONFIGURAÇÃO DO CONNECTION POOL (Piscina de Conexões) ---
# Mantém entre 1 e 10 conexões abertas e prontas para uso, economizando CPU
try:
    db_pool = pool.SimpleConnectionPool(
        1, 10,
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )
    print("Pool de conexões com o PostgreSQL criado com sucesso!")
except Exception as e:
    print(f"Erro ao criar o pool de conexões: {e}")
    sys.exit(1)

def init_db():
    """Garante que a tabela de transações imutáveis exista"""
    conn = db_pool.getconn()
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS movimentacoes (
                id SERIAL PRIMARY KEY,
                tipo VARCHAR(10) NOT NULL,
                valor NUMERIC(10, 2) NOT NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        cur.close()
        print("Tabela 'movimentacoes' validada com sucesso.")
    except Exception as e:
        print(f"Erro ao inicializar tabelas: {e}")
    finally:
        db_pool.putconn(conn) # Devolve a conexão para a piscina

init_db()

@app.route("/")
def home():
    return {"status": "Fintech API ativa", "seguranca": "maxima", "arquitetura": "ConnectionPool"}

@app.route("/transacao", methods=["POST"])
def criar_transacao():
    """Registra movimentações financeiras de forma resiliente"""
    dados = request.get_json() or {}
    tipo = dados.get("tipo")
    valor = dados.get("valor")

    if not tipo or not valor:
        return jsonify({"status": "erro", "mensagem": "Campos 'tipo' e 'valor' sao obrigatorios."}), 400

    if tipo not in ["credito", "debito"]:
        return jsonify({"status": "erro", "mensagem": "Tipo invalido. Use 'credito' ou 'debito'."}), 400

    # Pega uma conexão limpa do Pool
    conn = db_pool.getconn()
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO movimentacoes (tipo, valor) VALUES (%s, %s) RETURNING id, timestamp;",
            (tipo, valor)
        )
        id_transacao, ts = cur.fetchone()
        conn.commit()
        cur.close()
        
        return jsonify({
            "status": "sucesso",
            "transacao_id": id_transacao,
            "timestamp": str(ts),
            "mensagem": f"Movimentacao de {tipo} de R$ {valor} computada com persistencia."
        }), 201
        
    except Exception as e:
        conn.rollback() # Cancela a operação em caso de falha para não corromper os dados
        return jsonify({"status": "erro", "detalhe": str(e)}), 500
    finally:
        db_pool.putconn(conn) # Garante que a conexão volte pro pool, evitando vazamentos
        
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
