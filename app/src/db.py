import psycopg2.pool
import os
import sys
import logging

logger = logging.getLogger(__name__)

# Configurações do Banco
DB_HOST = os.environ.get("DB_HOST", "postgres-service")
DB_NAME = os.environ.get("DB_NAME", "fintech_db")
DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASSWORD")

# Inicialização do Pool
db_pool = None

try:
    db_pool = psycopg2.pool.SimpleConnectionPool(
        1, 10, 
        host=DB_HOST, 
        database=DB_NAME, 
        user=DB_USER, 
        password=DB_PASS
    )
    logger.info("Pool de conexões inicializado com sucesso no db.py.")
except Exception as e:
    logger.critical(f"Erro fatal ao inicializar o pool: {e}")
    sys.exit(1)

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
