# Quickstart: Núcleo da batalha (001)

Guia para rodar os testes e conferir, jogando, que a funcionalidade está pronta. Regras em
[spec.md](spec.md); interfaces em [contracts/](contracts/); dados em
[data-model.md](data-model.md).

## Pré-requisitos

- **Godot 4.7.2-stable** (versão padrão, não a .NET). Nesta máquina:
  `~/Apps/AppImages/Godot_v4.7.2-stable_linux.x86_64`.
- **GUT 9.7.1** já vem no repositório, em `addons/gut/` (não precisa instalar).
- Um terminal na raiz do projeto (a pasta que tem o `project.godot`).

Para não repetir o caminho do Godot, defina um apelido uma vez por terminal:

```bash
# Linux
alias godot=~/Apps/AppImages/Godot_v4.7.2-stable_linux.x86_64
```

```powershell
# Windows (PowerShell), ajustando o caminho
Set-Alias godot "C:\Godot\Godot_v4.7.2-stable_win64.exe"
```

## Rodar a suíte inteira de testes

```bash
godot --headless --path . --import
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

- O primeiro comando importa o projeto e registra as classes (`class_name`). Rode na
  primeira vez, depois de um `git pull` e sempre que criar ou renomear uma classe ou um
  arquivo de dados.
- O segundo roda todos os `teste_*.gd` das pastas listadas no `.gutconfig.json` e fecha
  sozinho. Não abre janela.
- **Resultado esperado**: a última linha é `---- All tests passed! ----` e o resumo mostra
  0 testes falhando. O comando devolve 0 quando tudo passa e 1 quando algo falha.

Rodar só uma área ou um teste:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=motor_contas
godot --headless --path . -s addons/gut/gut_cmdln.gd -gunit_test_name=escudo
```

Pelo editor: abra o projeto, painel **GUT** na parte de baixo, botão **Run All**.

## Abrir o jogo

```bash
godot --path .
```

Ou, pelo editor, F5. A cena principal é `luta_avulsa/luta_avulsa.tscn`. A janela abre em
1280×720 (o jogo em 640×360 ampliado 2×).

## Cenários de validação

Marque cada um ao conferir. Os números entre parênteses são os da spec.

### 1. A suíte passa (SC-002, SC-003, SC-004, SC-008)

Rode a suíte inteira. Ela precisa conter e passar, no mínimo:
- as 30 ou mais contas de referência do motor (precedência, unários, divisão, negativos,
  inválidas);
- a comparação da busca do alvo com a força bruta;
- a simulação de 1.000 lutas (alvo sempre alcançável, mão mínima cumprida, mesma semente
  dando a mesma luta);
- quem recebe cada efeito especial (Arthur ou inimigo).

### 2. Vencer uma luta (história 1)

1. Abra o jogo. **Esperado**: Arthur com 40 de vida, inimigo com 12 de vida e 3 de ataque,
   5 cartas na mão (3 números, um + e um −) e um alvo entre 5 e 12.
2. Monte uma conta que dê o alvo e confirme. **Esperado**: o aviso mostra o dano, a vida do
   inimigo cai na soma do ataque das cartas usadas, o Arthur perde 3 de vida e, depois de
   cerca de 1,5 s, aparecem uma carta nova e um alvo novo sem você clicar.
3. Repita até a vida do inimigo zerar. **Esperado**: no golpe final o Arthur não perde vida;
   aparece "Vitória!" com a vida restante e o número de rodadas.
4. Clique em "Lutar de novo". **Esperado**: luta nova, tudo de volta ao começo.

### 3. Errar e perder (história 2)

1. Confirme uma conta que não dá o alvo. **Esperado**: "Errou: a conta deu X, o alvo era Y",
   cartas gastas, inimigo sem dano, Arthur perde 3.
2. Confirme `número número` (sem operador). **Esperado**: "Conta inválida", mesmo efeito.
3. Continue errando ou pulando até a vida do Arthur zerar. **Esperado**: "Derrota" com a
   vida restante do inimigo e as rodadas; "Tentar de novo" recomeça.

### 4. Desfazer, limpar e Pular (história 3)

1. Ponha três cartas na expressão e clique em Desfazer. **Esperado**: a última volta para a
   mão; nada mais muda.
2. Clique em Limpar. **Esperado**: todas voltam; o botão Confirmar fica desabilitado.
3. Conte as cartas da mão e clique em Pular. **Esperado**: Arthur perde 3 de vida e, quando
   a rodada seguinte começa, a mão tem 2 cartas a mais (uma do Pular e uma da rodada).
4. Enquanto o aviso da rodada está na tela, clique em cartas e botões. **Esperado**: nada
   acontece.

### 5. Cartas especiais (história 4)

Jogue até ter cada especial na mão e acerte uma conta com ela:
- **Chama**: o dano mostrado é a soma do ataque das cartas mais 3.
- **Foco**: uma carta entra na mão na hora.
- **Guarda**: o painel do Arthur passa a mostrar escudo 5, o ataque do inimigo não tira vida
  e, na rodada seguinte, o escudo some do painel (voltou a 0). O inimigo nunca mostra escudo.
- **Vital**: a vida do Arthur sobe 2, sem passar de 40. A vida do inimigo não sobe.
- Erre uma conta com uma especial: nenhum efeito acontece.

### 6. Pixel art e leitura (research D3)

1. Com a janela em 1280×720, veja de perto as bordas dos retângulos e das cartas.
   **Esperado**: bordas retas e nítidas, sem borrão.
2. Redimensione a janela para um tamanho quebrado (por exemplo 1500×800). **Esperado**: o
   jogo continua em 2× com barras pretas em volta, sem pixels de tamanhos diferentes.
3. Maximize a janela. **Esperado**: a escala continua inteira (2×, ou 3× se a área útil do
   monitor tiver pelo menos 1920×1080), com barras pretas no que sobrar.
4. Leia o texto de uma carta especial e do aviso da rodada. **Esperado**: dá para ler sem
   esforço. Se não der, anote: é o risco registrado no research (fonte placeholder).

### 7. Mudar o equilíbrio sem mexer em código (SC-007)

1. No editor, abra `dados/inimigos/inimigo_padrao.tres` e mude a vida de 12 para 30. Salve.
2. Rode o jogo. **Esperado**: o inimigo começa com 30 de vida.
3. Desfaça a mudança (`git checkout dados/inimigos/inimigo_padrao.tres`).

### 8. Placeholders listados (SC-006)

Confira que cada retângulo, texto provisório e som ausente que aparece (ou deveria tocar) no
jogo tem uma linha em `docs/assets-pendentes.md` (inclusive o ícone da janela, que é o padrão
do Godot), e que o repositório não tem nenhum arquivo de imagem ou som criado para o jogo.

## Pelo MCP do Godot (para o Claude)

Durante a implementação, o Claude usa `run_project` e `get_debug_output` do MCP para abrir
o jogo e ler erros, e os comandos de linha acima para a suíte de testes.
