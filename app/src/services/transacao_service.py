class TransacaoService:
    def __init__(self, repo):
        self.repo = repo

    def validar_e_criar(self, dados):
        tipo = dados.get("tipo")
        valor_raw = dados.get("valor")

        # Regras de Negócio (Isoladas aqui)
        if not tipo or valor_raw is None:
            raise ValueError("Campos obrigatórios ausentes.")

        if tipo not in ["credito", "debito"]:
            raise ValueError("Tipo inválido.")

        try:
            valor = float(valor_raw)
            if valor <= 0:
                raise ValueError("Valor deve ser positivo.")
        except (ValueError, TypeError):
            raise ValueError("Valor deve ser numérico.")

        # Se passou, chama o repositório
        return self.repo.inserir_movimentacao(tipo, valor)
