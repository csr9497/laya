#!/usr/bin/env bash
# ==============================================================================
# Laya Studio - Automated Deployment Script for Azure Linux VMs
# Supports: Ubuntu 20.04 / 22.04 / 24.04, Debian, Azure E-series / D-series VMs
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "  🚀 Iniciando despliegue automatizado de Laya Studio en Azure"
echo "================================================================="

# 1. Identificar usuario y rutas
CURRENT_USER="${SUDO_USER:-$(whoami)}"
USER_HOME=$(eval echo "~${CURRENT_USER}")
PROJECT_DIR="${USER_HOME}/laya"
PORT=8000

echo "📌 Usuario de ejecución: ${CURRENT_USER}"
echo "📌 Directorio de despliegue: ${PROJECT_DIR}"

# 2. Instalar paquetes esenciales del sistema
echo "📦 Verificando paquetes base del sistema (git, curl, python3)..."
if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -qq -y git curl python3 ufw >/dev/null
fi

# 3. Asegurar instalación de uv
echo "⚡ Verificando herramienta uv..."
if ! command -v uv &>/dev/null && [ ! -f "${USER_HOME}/.local/bin/uv" ]; then
    echo "⬇️ Instalando uv para ${CURRENT_USER}..."
    sudo -u "${CURRENT_USER}" curl -LsSf https://astral.sh/uv/install.sh | sudo -u "${CURRENT_USER}" sh
fi

UV_BIN="${USER_HOME}/.local/bin/uv"
if [ ! -f "${UV_BIN}" ]; then
    UV_BIN=$(command -v uv || echo "uv")
fi
echo "✅ uv detectado en: ${UV_BIN}"

# 4. Clonar o actualizar el repositorio
if [ -d "${PROJECT_DIR}/.git" ]; then
    echo "🔄 Actualizando repositorio existente (git pull)..."
    cd "${PROJECT_DIR}"
    sudo -u "${CURRENT_USER}" git fetch origin main
    sudo -u "${CURRENT_USER}" git reset --hard origin/main
else
    echo "📥 Clonando repositorio desde GitHub..."
    sudo -u "${CURRENT_USER}" git clone https://github.com/csr9497/laya.git "${PROJECT_DIR}"
    cd "${PROJECT_DIR}"
fi

# 5. Pre-calentar entorno con uv
echo "⏳ Sincronizando dependencias con uv..."
sudo -u "${CURRENT_USER}" "${UV_BIN}" sync || true

# 6. Configurar reglas de firewall local (ufw) si está activo
if command -v ufw &>/dev/null; then
    if sudo ufw status | grep -q "Status: active"; then
        echo "🛡️ Habilitando puerto ${PORT} en el firewall ufw..."
        sudo ufw allow "${PORT}/tcp" || true
    fi
fi

# 7. Crear / Actualizar servicio systemd optimizado para CPU
echo "⚙️ Configurando servicio systemd (laya.service)..."
SERVICE_FILE="/etc/systemd/system/laya.service"

sudo tee "${SERVICE_FILE}" > /dev/null <<EOF
[Unit]
Description=Laya Studio Web Service (Automated Production)
After=network.target

[Service]
Type=simple
User=${CURRENT_USER}
WorkingDirectory=${PROJECT_DIR}
ExecStart=${UV_BIN} run app.py --no-browser --host 0.0.0.0 --port ${PORT}
Restart=always
RestartSec=3
LimitNOFILE=65536
Environment=PATH=${USER_HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# 8. Recargar y reiniciar el servicio
echo "🔄 Reiniciando servicio laya en systemd..."
sudo systemctl daemon-reload
sudo systemctl enable laya
sudo systemctl restart laya

# 9. Healthcheck / Validación en vivo
echo "🔍 Esperando a que el servicio responda en el puerto ${PORT}..."
RETRIES=15
SUCCESS=false
for i in $(seq 1 $RETRIES); do
    if curl -s "http://127.0.0.1:${PORT}/api/status" | grep -q '"ready":true' 2>/dev/null; then
        SUCCESS=true
        break
    fi
    sleep 1
done

if [ "$SUCCESS" = true ]; then
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "IP_PUBLICA_DE_AZURE")
    echo "================================================================="
    echo "  🎉 ¡DESPLIEGUE COMPLETADO CON ÉXITO!"
    echo "  👉 Acceso local:   http://localhost:${PORT}"
    echo "  👉 Acceso público: http://${PUBLIC_IP}:${PORT}"
    echo "================================================================="
    sudo systemctl status laya --no-pager -n 3
else
    echo "⚠️ El servicio tardó en responder. Verificando estado:"
    sudo systemctl status laya --no-pager -n 10
fi
