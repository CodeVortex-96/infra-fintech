from flask import Blueprint, request, jsonify
from repositories.transacao_repo import TransacaoRepository
from services.transacao_service import TransacaoService
from db import db_pool

# Define o Blueprint
transacao_bp = Blueprint('transacao_bp', __name__)

# Instancia as dependências
repo = TransacaoRepository(db_pool)
service = TransacaoService(repo)

@transacao_bp.route("/transacao", methods=["POST"])
def criar_transacao():
    dados = request.get_json() or {}
    
    try:
        # Chama o serviço para validar e processar
        id_transacao, ts = service.validar_e_criar(dados)
        return jsonify({
            "status": "sucesso",
            "transacao_id": id_transacao,
            "timestamp": ts.isoformat()
        }), 201
    except ValueError as e:
        # Se a validação do service falhar, retorna 400
        return jsonify({"status": "erro", "mensagem": str(e)}), 400
    except Exception as e:
        # Se algo der pau no banco ou servidor, retorna 500
        return jsonify({"status": "erro", "detalhe": "Erro interno."}), 500
