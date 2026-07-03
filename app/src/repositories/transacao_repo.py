class TransacaoRepository:
    def __init__(self, pool):
        self.pool = pool

    def inserir_movimentacao(self, tipo, valor):
        conn = self.pool.getconn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO movimentacoes (tipo, valor) VALUES (%s, %s) RETURNING id, timestamp;", 
                    (tipo, valor)
                )
                resultado = cur.fetchone()
            conn.commit()  # Garante a persistência no banco
            return resultado
        except Exception as e:
            conn.rollback() # Garante rollback em caso de erro
            raise e
        finally:
            self.pool.putconn(conn)
