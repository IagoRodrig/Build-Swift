# [Build Swift] - Automacao de Compras Digitais
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"

# ============================================================
# 1. CONFIGURACOES DE CAMINHOS
# ============================================================
$ScriptVersion = "1.1.0"
$DefaultProductVersion = "1.1.0"
$DefaultBaseDir = "D:\FLUIG-LOCAL\COMPRAS-DIGITAL\FLUIG"
$DefaultAppAngular = "$DefaultBaseDir\APP-COMPRAS-DIGITAL"
$DefaultInstalador = "$DefaultBaseDir\INSTALADOR-COMPRAS-DIGITAL"
$DebugRobocopy = $true

$DataDir = Join-Path $PSScriptRoot "data"
$DataFile = Join-Path $DataDir "build-swift.data.json"
$ModelFile = Join-Path $DataDir "build-swift.model.json"

function Pergunta-Texto {
    param (
        [string]$Msg,
        [string]$Default
    )
    $res = Read-Host "$Msg [$Default]"
    if ([string]::IsNullOrWhiteSpace($res)) { return $Default }
    return $res
}

function Ler-Config {
    if (!(Test-Path $DataFile)) { return $null }
    try {
        return (Get-Content $DataFile -Raw | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Ler-Model {
    if (!(Test-Path $ModelFile)) { return $null }
    try {
        return (Get-Content $ModelFile -Raw | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Config-Valida {
    param ($Config)
    return (
        $null -ne $Config -and
        -not [string]::IsNullOrWhiteSpace($Config.versaoProduto) -and
        $null -ne $Config.caminhos -and
        -not [string]::IsNullOrWhiteSpace($Config.caminhos.baseDir) -and
        -not [string]::IsNullOrWhiteSpace($Config.caminhos.appAngular) -and
        -not [string]::IsNullOrWhiteSpace($Config.caminhos.instalador)
    )
}

function Salvar-Config {
    param ($Config)
    if (!(Test-Path $DataDir)) { New-Item -Path $DataDir -ItemType Directory -Force | Out-Null }
    $Config | ConvertTo-Json -Depth 5 | Set-Content -Path $DataFile -Encoding UTF8
}

function Garantir-Config {
    $configAtual = Ler-Config
    if (!(Config-Valida $configAtual)) {
        Write-Host "`n>>> CONFIGURACAO INICIAL" -ForegroundColor Yellow
        $model = Ler-Model
        $produtoVersao = if ($null -ne $model -and -not [string]::IsNullOrWhiteSpace($model.versaoProduto)) {
            $model.versaoProduto
        } else {
            $DefaultProductVersion
        }
        $baseDir = Pergunta-Texto "Informe o caminho do BaseDir (Pasta onde está todos os projetos)" $DefaultBaseDir
        $appAngular = Pergunta-Texto "Informe o caminho do AppAngular" "$baseDir\APP-COMPRAS-DIGITAL"
        $instalador = Pergunta-Texto "Informe o caminho do Instalador" "$baseDir\INSTALADOR-COMPRAS-DIGITAL"

        $configAtual = [PSCustomObject]@{
            versaoProduto = $produtoVersao
            caminhos = [PSCustomObject]@{
                baseDir = $baseDir
                appAngular = $appAngular
                instalador = $instalador
            }
        }
        Salvar-Config $configAtual
        Write-Host " Configuracao salva em: $DataFile" -ForegroundColor Green
    }
    return $configAtual
}

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
    Write-Host " Versao produto: $ProdutoVersao | Build Swift $ScriptVersion" -ForegroundColor Cyan
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
$Config = Garantir-Config
$ProdutoVersao = $Config.versaoProduto
$BaseDir = $Config.caminhos.baseDir
$AppAngular = $Config.caminhos.appAngular
$Instalador = $Config.caminhos.instalador

do {
    $Relatorio = @()
    $Paginas = @(
        @{ 
            Nome = "Copia: Cotacao";     
            Src = "$BaseDir\PAGINA-PUBLICA-COTACAO\wcm\widget\XP_CDIG_WGT_COTACAO_FORNECEDOR\src";  # Origem da copia da pagina publica
            Dest = "$Instalador\XP_CDIG_WGT_COTACAO_FORNECEDOR\src";  # Destino da copia da pagina publica
            Executar = $false 
        },
        @{ 
            Nome = "Copia: Aceite";      
            Src = "$BaseDir\PAGINA-PUBLICA-ACEITE-PEDIDO\wcm\widget\XP_CDIG_WGT_ACEITE_PEDIDO\src";  # Origem da copia da pagina publica
            Dest = "$Instalador\XP_CDIG_WGT_ACEITE_PEDIDO\src";  # Destino da copia da pagina publica
            Executar = $false 
        },
        @{ 
            Nome = "Copia: Nota Fiscal"; 
            Src = "$BaseDir\PAGINA-PUBLICA-NOTA-FISCAL\wcm\widget\XP_CDIG_WGT_RECEBIMENTO_NF\src";   
            Dest = "$Instalador\XP_CDIG_WGT_RECEBIMENTO_NF\src";   # Destino da copia da pagina publica
            Executar = $false 
        }
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