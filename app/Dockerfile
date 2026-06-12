# --- ESTÁGIO 1: O Construtor (Builder) ---
FROM python:3.11-alpine AS builder

WORKDIR /build

# Instala ferramentas essenciais do Alpine para compilar pacotes Python
RUN apk add --no-cache gcc musl-dev libffi-dev

# Cria e isola o ambiente de dependências
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt


# --- ESTÁGIO 2: O Executor Seguro (Runner) ---
FROM python:3.11-alpine AS runner

WORKDIR /app

# Princípio do privilégio mínimo: cria um usuário comum para NÃO rodar como root
RUN addgroup -S fintech && adduser -S arquiteto -G fintech

# Copia APENAS as dependências prontas do estágio anterior (limpando o lixo de compilação)
COPY --from=builder /root/.local /home/arquiteto/.local
COPY --chown=arquiteto:fintech ./src /app

# Configura as variáveis de ambiente para o Python achar os pacotes instalados
ENV PATH=/home/arquiteto/.local/bin:$PATH
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Assume a identidade do usuário seguro antes de ligar o servidor
USER arquiteto

EXPOSE 8080

CMD ["python", "main.py"]
