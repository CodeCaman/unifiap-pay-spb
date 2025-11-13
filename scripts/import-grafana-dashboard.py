import requests
import json

# Configuração
GRAFANA_URL = "http://localhost:30300"
GRAFANA_USER = "admin"
GRAFANA_PASS = "admin"
DASHBOARD_FILE = "monitoring/grafana/dashboards/unifiap-complete.json"

# Carregar dashboard
with open(DASHBOARD_FILE, 'r') as f:
    dashboard = json.load(f)

# Preparar payload
payload = {
    "dashboard": dashboard,
    "overwrite": True,
    "message": "Imported by script"
}

# Importar dashboard
response = requests.post(
    f"{GRAFANA_URL}/api/dashboards/db",
    json=payload,
    auth=(GRAFANA_USER, GRAFANA_PASS),
    headers={"Content-Type": "application/json"}
)

if response.status_code == 200:
    result = response.json()
    print(f"✅ Dashboard importado com sucesso!")
    print(f"📊 URL: {GRAFANA_URL}{result.get('url', '')}")
    print(f"🆔 UID: {result.get('uid', 'N/A')}")
else:
    print(f"❌ Erro ao importar: {response.status_code}")
    print(f"📝 Detalhes: {response.text}")
