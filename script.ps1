# [Build Swift] - Automacao de Compras Digitais
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"

# ============================================================
# 1. CONFIGURACOES DE CAMINHOS
# ============================================================
$BaseDir      = "D:\FLUIG-LOCAL\COMPRAS-DIGITAL\FLUIG"
$AppAngular   = "$BaseDir\APP-COMPRAS-DIGITAL"
$Instalador   = "$BaseDir\INSTALADOR-COMPRAS-DIGITAL"
$DebugRobocopy = $true

# ============================================================
# 2. FUNCOES DE INTERFACE
# ============================================================
function Show-Banner {
    Clear-Host
    $banner = @"
============================================================
    ____        _ _     _   ____            _  __ _ 
   | __ ) _   _(_) | __| | / ___|_      _ _(_)/ _| |_ 
   |  _ \| | | | | |/ _` | \___ \ \ /\ / (_) | |_| __|
   | |_) | |_| | | | (_| |  ___) \ V  V /| | |  _| |_ 
   |____/ \__,_|_|_|\__,_| |____/ \_/\_/ |_|_|_|  \__|

               BUILD | COPY | MAVEN DEPLOY
============================================================
"@
    Write-Host $banner -ForegroundColor Cyan
    Write-Host " Versao: 1.1.0 | Build Swift" -ForegroundColor Cyan
    Write-Host " Autor: Iago Rodrigues" -ForegroundColor Cyan
    Write-Host " Github: https://github.com/IagoRodrig" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor Cyan
}

function Pergunta {
    param ([string]$Msg)
    $res = Read-Host "$Msg (s/n)"
    return ($res.ToLower() -eq 's' -or $res.ToLower() -eq 'y')
}

function Titulo { param ([string]$Texto); Write-Host "`n>>> $Texto" -ForegroundColor Yellow -BackgroundColor Black }
function Sucesso { param ([string]$Texto); Write-Host " [OK] $Texto" -ForegroundColor Green }
function Erro { param ([string]$Texto); Write-Host " [ERRO] $Texto" -ForegroundColor Red }

# ============================================================
# 3. LOOP PRINCIPAL
# ============================================================
do {
    $Relatorio = @()
    $Paginas = @(
        @{ Nome = "Copia: Cotacao";     Src = "$BaseDir\PAGINA-PUBLICA-COTACAO\wcm\widget\XP_CDIG_WGT_COTACAO_FORNECEDOR\src"; Dest = "$Instalador\XP_CDIG_WGT_COTACAO_FORNECEDOR\src"; Executar = $false },
        @{ Nome = "Copia: Aceite";      Src = "$BaseDir\PAGINA-PUBLICA-ACEITE-PEDIDO\wcm\widget\XP_CDIG_WGT_ACEITE_PEDIDO\src";  Dest = "$Instalador\XP_CDIG_WGT_ACEITE_PEDIDO\src";  Executar = $false },
        @{ Nome = "Copia: Nota Fiscal"; Src = "$BaseDir\PAGINA-PUBLICA-NOTA-FISCAL\wcm\widget\XP_CDIG_WGT_RECEBIMENTO_NF\src";   Dest = "$Instalador\XP_CDIG_WGT_RECEBIMENTO_NF\src";   Executar = $false }
    )

    Show-Banner
    $rodarAngular = Pergunta "1. Deseja realizar a build do Angular?"
    for ($i = 0; $i -lt $Paginas.Count; $i++) {
        if (Pergunta "2.$($i+1). Deseja copiar a pagina: $($Paginas[$i].Nome)?") { $Paginas[$i].Executar = $true }
    }
    $rodarMaven = Pergunta "3. Deseja realizar o build do Maven?"

    Write-Host "`n>>> INICIANDO EXECUCAO..." -ForegroundColor Cyan

    # --- EXECUCAO: ANGULAR ---
    if ($rodarAngular) {
        Titulo "BUILD ANGULAR"
        if (Test-Path $AppAngular) {
            Set-Location $AppAngular
            ng build --deploy-url /XP_CDIG_WGT_APP/resources/js/compras-digital/
            $status = if ($LASTEXITCODE -eq 0) { "Sucesso" } else { "Erro" }
        } else { $status = "Caminho nao encontrado" }
        $Relatorio += New-Object PSObject -Property @{ Tarefa = "Build Angular"; Status = $status }
    }

    # --- EXECUCAO: COPIAS ---
    foreach ($Pag in $Paginas) {
        if ($Pag.Executar) {
            Titulo "COPIANDO: $($Pag.Nome)"
            if (Test-Path $Pag.Src) {
                if ($DebugRobocopy) {
                    $srcResolved = Resolve-Path -Path $Pag.Src -ErrorAction SilentlyContinue
                    Write-Host " Origem (raw):      $($Pag.Src)" -ForegroundColor DarkCyan
                    $srcDisplay = if ($null -ne $srcResolved) { $srcResolved } else { "N/A" }
                    Write-Host " Origem (resolvida): $srcDisplay" -ForegroundColor DarkCyan
                }
                # Forcando a criacao da pasta destino se nao existir
                if (!(Test-Path $Pag.Dest)) { New-Item -Path $Pag.Dest -ItemType Directory -Force | Out-Null }
                if ($DebugRobocopy) {
                    $destResolved = Resolve-Path -Path $Pag.Dest -ErrorAction SilentlyContinue
                    Write-Host " Destino (raw):      $($Pag.Dest)" -ForegroundColor DarkCyan
                    $destDisplay = if ($null -ne $destResolved) { $destResolved } else { "N/A" }
                    Write-Host " Destino (resolvida): $destDisplay" -ForegroundColor DarkCyan
                    Write-Host " Comando: robocopy `"$($Pag.Src)`" `"$($Pag.Dest)`" /E /Z /R:2 /W:5 /TBD /NFL /NDL /NJH /NJS" -ForegroundColor DarkCyan
                }
                
                # Execucao do Robocopy com aspas nos caminhos
                robocopy "$($Pag.Src)" "$($Pag.Dest)" /E /Z /R:2 /W:5 /TBD /NFL /NDL /NJH /NJS
                
                # Robocopy codes < 8 sao sucessos
                $status = if ($LASTEXITCODE -lt 8) { "Sucesso" } else { "Erro ($LASTEXITCODE)" }
            } else { $status = "Origem nao encontrada" }
            $Relatorio += New-Object PSObject -Property @{ Tarefa = $Pag.Nome; Status = $status }
        }
    }

    # --- EXECUCAO: MAVEN ---
    if ($rodarMaven) {
        Titulo "MAVEN INSTALL"
        if (Test-Path $Instalador) {
            Set-Location $Instalador
            mvn clean install
            $status = if ($LASTEXITCODE -eq 0) { "Sucesso" } else { "Erro" }
        } else { $status = "Caminho nao encontrado" }
        $Relatorio += New-Object PSObject -Property @{ Tarefa = "Build Maven"; Status = $status }
    }

    # --- GRID DE RESULTADOS ---
    Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
    Write-Host " RESUMO DA EXECUCAO" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    $Relatorio | Select-Object Tarefa, Status | Format-Table -AutoSize
    Write-Host ("=" * 60) -ForegroundColor Cyan

    $repetir = Pergunta "`n>>> Deseja executar novamente?"

} while ($repetir)

# --- FECHAMENTO ---
Write-Host "`nEncerrando..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# Comando para fechar a janela do Windows de forma forcada
(Get-Process -Id $PID).CloseMainWindow()
exit