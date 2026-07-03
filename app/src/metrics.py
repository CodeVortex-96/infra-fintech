from prometheus_flask_exporter import PrometheusMetrics
from flask import request

# Instancia o objeto sem vincular ao app ainda
metrics = PrometheusMetrics(app=None)

def init_metrics(app):
    """Inicializa as métricas com o app já criado."""
    metrics.init_app(app)
    
    # Adiciona informações globais
    metrics.info('app_info', 'Fintech API', version='1.0.0')

    # Registra labels fixas para monitoramento refinado
    metrics.register_default(
        metrics.counter(
            'by_path_counter', 'Request count by request paths',
            labels={
                'path': lambda: request.path, 
                'method': lambda: request.method, 
                'status': lambda resp: resp.status_code
            }
        )
    )
