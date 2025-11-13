# Script para configurar Grafana com Dashboard UniFIAP Pay SPB

Write-Host "`n=== CONFIGURACAO DO GRAFANA ===" -ForegroundColor Cyan
Write-Host "`nPasso 1: Acesse o Grafana" -ForegroundColor Yellow
Write-Host "URL: http://localhost:30300"
Write-Host "Login: admin / admin"
Write-Host "`n(Na primeira vez, você será solicitado a alterar a senha. Use 'admin' novamente para simplificar)`n"

Write-Host "Passo 2: Adicionar Datasource Prometheus" -ForegroundColor Yellow
Write-Host "1. Clique no ícone de engrenagem (⚙️) no menu lateral esquerdo"
Write-Host "2. Selecione 'Data Sources'"
Write-Host "3. Clique em 'Add data source'"
Write-Host "4. Selecione 'Prometheus'"
Write-Host "5. Em 'HTTP URL', digite: http://prometheus-service:9090"
Write-Host "6. Clique em 'Save & Test'`n"

Write-Host "Passo 3: Importar Dashboard" -ForegroundColor Yellow
Write-Host "1. Clique no ícone '+' no menu lateral esquerdo"
Write-Host "2. Selecione 'Import'"
Write-Host "3. Clique em 'Upload JSON file'"
Write-Host "4. Selecione o arquivo: monitoring/grafana/dashboards/unifiap-complete.json"
Write-Host "5. Selecione o datasource 'Prometheus'"
Write-Host "6. Clique em 'Import'`n"

Write-Host "=== DASHBOARDS PRONTOS ===" -ForegroundColor Green
Write-Host "`nVocê verá os seguintes painéis:"
Write-Host "- CPU Usage (Gauge)"
Write-Host "- Memory Usage (Gauge)"
Write-Host "- Kubernetes Pods Status (Time Series)"
Write-Host "- Total Pods, Deployments, Services (Stats)"
Write-Host "- Pod Memory Usage (Time Series)"
Write-Host "- Pod CPU Usage (Time Series)"
Write-Host "- Pod Restarts (Time Series)"
Write-Host "- Network Traffic (Time Series)"
Write-Host "`n✨ Dashboard atualiza automaticamente a cada 5 segundos!`n"

Write-Host "Pressione qualquer tecla para abrir o Grafana no navegador..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Start-Process "http://localhost:30300"
