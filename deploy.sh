#!/bin/bash

# 1. Cluster management
if ! k3d cluster list | grep -q "fintech-cluster"; then
    echo "--- Criando cluster do zero... ---"
    k3d cluster create fintech-cluster
else
    echo "--- Cluster detectado, garantindo que está rodando... ---"
    k3d cluster start fintech-cluster
fi

echo "--- Buildando a imagem... ---"
docker build -t fintech-app:latest ./app

echo "--- Importando para o cluster... ---"
k3d image import fintech-app:latest -c fintech-cluster

echo "--- Aplicando todas as configs (k8s/)... ---"
# Aplica a pasta inteira para garantir que secrets/services/PVCs sejam atualizados
kubectl apply -f k8s/

echo "--- Reiniciando o pod para pegar a nova imagem... ---"
kubectl rollout restart deployment/fintech-api-deployment

echo "--- Pronto! Status atual: ---"
kubectl rollout status deployment/fintech-api-deployment
