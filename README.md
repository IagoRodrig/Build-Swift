# Build-Swift

Automacao local para build e copia de componentes do projeto Compras Digitais.

## O que faz
- Opcionalmente executa a build do Angular em `APP-COMPRAS-DIGITAL`
- Copia (Robocopy) os widgets das paginas publicas para `INSTALADOR-COMPRAS-DIGITAL`
- Opcionalmente executa `mvn clean install` no instalador
- Mostra um resumo com status de cada etapa

## Como executar
1. Na pasta, execute o `arquivo run.ps.bat`
2. Responda as perguntas com s/n

O `run.ps.bat` garante a elevacao e chama o `script.ps1` com `ExecutionPolicy Bypass`.

## Fluxo de execucao
1. Exibe um banner e pergunta se deve rodar:
   - Build do Angular
   - Copia de cada pagina (Cotacao, Aceite, Nota Fiscal)
   - Build do Maven
2. Executa as tarefas selecionadas
3. Exibe o resumo e pergunta se deseja repetir

## Caminhos principais (script.ps1)
Definidos no topo do script:
- `BaseDir`: raiz do workspace
- `AppAngular`: `APP-COMPRAS-DIGITAL`
- `Instalador`: `INSTALADOR-COMPRAS-DIGITAL`

As pastas de origem/destino das copias sao montadas a partir do `BaseDir`.
Ou seja, as pastas de paginas publicas e do instalador precisam estar dentro do `BaseDir`.
Exemplo: `BaseDir` = `D:\FLUIG-LOCAL\COMPRAS-DIGITAL\FLUIG`

## Configuracao via JSON
Na primeira execucao, se nao existir o arquivo de dados, o script pergunta os caminhos e salva em:
- `Build-Swift/data/build-swift.data.json`

O modelo da estrutura esta em:
- `Build-Swift/data/build-swift.model.json`

O arquivo de dados eh ignorado pelo git para nao subir no GitHub.

A versao do produto vem do model e nao eh digitada.

## Copias (Robocopy)
Cada pagina copia a pasta `src` do widget correspondente para o instalador.

Origem:
- `PAGINA-PUBLICA-COTACAO\wcm\widget\XP_CDIG_WGT_COTACAO_FORNECEDOR\src`
- `PAGINA-PUBLICA-ACEITE-PEDIDO\wcm\widget\XP_CDIG_WGT_ACEITE_PEDIDO\src`
- `PAGINA-PUBLICA-NOTA-FISCAL\wcm\widget\XP_CDIG_WGT_RECEBIMENTO_NF\src`

Destino:
- `INSTALADOR-COMPRAS-DIGITAL\XP_CDIG_WGT_COTACAO_FORNECEDOR\src`
- `INSTALADOR-COMPRAS-DIGITAL\XP_CDIG_WGT_ACEITE_PEDIDO\src`
- `INSTALADOR-COMPRAS-DIGITAL\XP_CDIG_WGT_RECEBIMENTO_NF\src`

Comando usado:
```
robocopy "<origem>" "<destino>" /E /Z /R:2 /W:5 /TBD /NFL /NDL /NJH /NJS
```

## Debug do Robocopy
O script possui a flag `DebugRobocopy`:
- Quando `true`, imprime origem/destino (raw e resolvido) e o comando completo antes da copia.

## Requisitos
- Windows com PowerShell
- `ng` (Angular CLI) configurado quando a build do Angular for usada
- `mvn` (Maven) configurado quando o build do instalador for usado
