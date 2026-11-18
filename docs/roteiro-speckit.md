# Roteiro do Spec Kit: do fim da 001 até a entrega

Passo a passo para seguir sozinho, sem consultar o Claude a cada etapa. Os prompts estão
prontos para colar. A visão do jogo e os prompts do `specify` ficam em
[visao-do-jogo.md](visao-do-jogo.md); este arquivo cobre o resto do ciclo.

Escrito em 13/11/2026, com a 001 implementada (falta só o T035).

## Calendário

Replanejado em 17/11: a 001 não fechou até 17/11 e de 23 a 27/11 não sobra hora livre (provas,
aulas, trabalho e apresentações). Por isso a 004 e a 005 viraram uma funcionalidade só, e a 003
ficou enxuta (chefes dos atos 1 e 2 como elites reforçadas; prova com até 3 questões). Os blocos
estão na agenda como "JOGOED" em 20, 22, 28 e 29/11.

| Data | Meta |
|---|---|
| sex 20/11 (feriado) | 001 fechada (T035 jogado, converge sem pendência) e 002 Run e mapa |
| dom 22/11, manhã | 003 Chefes e a prova: specify, clarify, plan e tasks |
| 23 a 27/11 | Sem hora livre |
| sáb 28/11, tarde | 003 implement; 004 Telas, história e tutorial: specify, clarify, plan e tasks |
| dom 29/11 | 004 implement; trocar placeholders pela arte, corrigir, exportar e ensaiar |
| seg 30/11 | Entrega |

Se uma funcionalidade atrasar mais de um dia, corte escopo na próxima (por exemplo, menos
regras de questão na prova) em vez de empurrar todas.

## Regras gerais (valem para toda etapa)

- **Trocar modelo:** `/model opus`.
- **Trocar esforço só na sessão:** `/effort`, escolher o nível e apertar `s`.
- **`/clear` entre etapas.** Sessão longa gasta mais token a cada mensagem. Exceção: a
  correção do analyze fica na mesma sessão do analyze, porque o relatório não é salvo.
- **Uma funcionalidade só começa** com a anterior com os testes passando, commit feito e
  converge sem pendência.
- **Opus `xhigh` no lugar do Fable 5.2** (sem acesso desde 18/11): plan e analyze da 002,
  bug que o Opus `high` não resolveu em duas tentativas e revisão visual por print do jogo.
- **Se o Claude errar com contexto suficiente:** troque para um modelo maior. **Se pular
  arquivo ou largar a tarefa no meio:** suba o esforço.
- **Se o Claude decidir uma regra do jogo sozinho** (aparece na spec como "Q (no analyze)"
  ou nas mensagens de commit), confira se você concorda antes de seguir.

## Modelo e esforço por etapa

| Etapa | 002 | 003 e 004 |
|---|---|---|
| specify | Opus `high` | Opus `high` |
| clarify | Opus `high` (repetir até não sobrar dúvida) | Opus `high` |
| plan | Opus `xhigh` | Opus `xhigh` |
| tasks | Opus `medium` | Opus `medium` |
| analyze (1ª vez) | Opus `xhigh` | Opus `xhigh` |
| correção do analyze | Opus `high` (mesma sessão) | Opus `high` (mesma sessão) |
| analyze (2ª vez) | Opus `xhigh` | Opus `xhigh` |
| implement | Opus `high` | Opus `high` |
| converge | Opus `high` | Opus `high` |

Analyze no máximo duas vezes. Se a segunda só achar LOW ou MEDIUM de redação, siga para o
implement.

---

## Parte 1: fechar a 001

1. **T035, jogar:** `godot --path .` na pasta do projeto e percorrer os cenários 2 a 7 de
   `specs/001-nucleo-batalha/quickstart.md`. Anotar no fim do quickstart a data, quem jogou
   e o resultado de cada cenário, marcar o T035 como `[X]` no `tasks.md` e fazer commit.
2. **Se algo falhou:** sessão nova, Opus `high`, e colar:

```text
Joguei o cenário N do quickstart da 001 e aconteceu isto: <descreva o que viu e o que esperava>. Crie no tasks.md uma tarefa de correção, escreva primeiro um teste que reproduz o defeito, corrija, rode a suíte inteira e faça o commit.
```

3. **Converge** (Opus `high`, sessão nova): `/speckit-converge` sem argumento. Se ele
   acrescentar tarefas, rode `/speckit-implement Execute só as tarefas novas que o converge acrescentou.`
   Se não acrescentar nada, a 001 está fechada.

---

## Parte 2: ciclo de cada funcionalidade (002 a 004)

Repita os passos abaixo para cada funcionalidade. Os prompts do `plan` mudam por
funcionalidade e estão na Parte 3.

### Passo 1: specify

Sessão nova, Opus `high`. Colar o prompt da funcionalidade em
[visao-do-jogo.md](visao-do-jogo.md), seção "Prompts prontos".

### Passo 2: clarify

Mesmo modelo, `/speckit-clarify` sem argumento. Responda às perguntas; rode de novo até ele
dizer que não há ambiguidade relevante. Os pontos em aberto da visão que entram aqui:

- **002:** quantas casas tem cada ato; quanto o descanso cura (no jogo antigo, 8); se existe
  registro entre runs (melhor resultado).
- **003:** a regra de cada questão da prova (até 3, decidido em 17/11). Os chefes dos atos 1
  e 2 são elites reforçadas: só mudam vida e ataque.
- **004:** o clarify encontra sozinho.

Depois do clarify, atualize a seção "Pontos em aberto" de `docs/visao-do-jogo.md` riscando o
que foi decidido (como foi feito com a divisão na 001).

### Passo 3: plan

Sessão nova, modelo da tabela. Colar o prompt da Parte 3.

### Passo 4: tasks

Sessão nova, Opus `medium`:

```text
/speckit-tasks Siga a ordem de construção do plan.md. Cada tarefa deve ser pequena o bastante para virar um commit só, com a suíte inteira passando ao final. Agrupe as tarefas por área do jogo e marque com [P] as que podem ser feitas em paralelo por pessoas diferentes da equipe. Os testes de cada área vêm junto do código que testam, nunca depois de tudo pronto. A penúltima tarefa é a validação automática do quickstart.md pelo agente e a conferência do docs/assets-pendentes.md; a última é a validação jogada por uma pessoa da equipe.
```

### Passo 5: analyze e correção

Sessão nova, modelo da tabela: `/speckit-analyze` sem argumento. Na **mesma sessão**, troque
para Opus `high` e cole:

```text
Corrija todos os problemas que o analyze apontou, do mais grave para o menos grave. Para cada um, altere todos os arquivos afetados (spec.md, plan.md, research.md, data-model.md, contracts/ e tasks.md) para que continuem coerentes entre si. Se um achado exigir decidir alguma regra do jogo, pare e me pergunte em vez de escolher. Faça um commit por problema corrigido, em português. No fim, liste cada achado com o que foi feito.
```

Depois, sessão nova, Opus `xhigh`, analyze de novo. Achado CRITICAL ou HIGH: corrija com o
mesmo prompt. Só LOW: siga.

### Passo 6: implement, em três partes

Uma sessão nova para cada parte, Opus `high`. Antes, abra o `tasks.md` e veja os números
das fases (Setup, Foundational, a história P1 e o resto).

Parte A, a base:

```text
/speckit-implement Execute só as fases de Setup e Foundational do tasks.md, até o checkpoint da fundação. Uma tarefa por commit, com a suíte inteira do GUT passando antes de cada commit. Marque cada tarefa como [X] no tasks.md no mesmo commit. Se um teste falhar e a correção exigir mudar a spec, o plan ou um contrato, pare e me pergunte. Ao terminar, mostre o resultado da suíte e pare no checkpoint.
```

Parte B, o MVP:

```text
/speckit-implement Execute só a fase da história 1 (prioridade P1) do tasks.md, até o checkpoint dela. Uma tarefa por commit, com a suíte inteira do GUT passando antes de cada commit. Marque cada tarefa como [X] no tasks.md no mesmo commit. Se um teste falhar e a correção exigir mudar a spec, o plan ou um contrato, pare e me pergunte. Ao terminar, rode o jogo pelo MCP do Godot, confira a saída de depuração sem erros e pare no checkpoint.
```

Depois da parte B, **jogue** (`godot --path .`) antes de seguir.

Parte C, o resto:

```text
/speckit-implement Execute as fases restantes do tasks.md até o fim. Uma tarefa por commit, com a suíte inteira do GUT passando antes de cada commit. Marque cada tarefa como [X] no tasks.md no mesmo commit. Se um teste falhar e a correção exigir mudar a spec, o plan ou um contrato, pare e me pergunte. Na validação do quickstart, faça a parte que o agente consegue fazer e deixe para a equipe a parte jogada.
```

### Passo 7: conferir sozinho (sem chamar o Claude)

Na pasta do projeto, num terminal comum:

```bash
git status --short                      # vazio = tudo commitado
git log --oneline -20                   # um commit por tarefa, com o número (T0xx)
grep -c '^- \[ \]' specs/<pasta>/tasks.md   # tarefas abertas (só deve sobrar a jogada)
godot --headless --path . --import
godot --headless --path . -s addons/gut/gut_cmdln.gd   # fim deve dizer "All tests passed!"
```

Sinais de alerta (aí vale chamar o Claude para revisar):

- teste falhando ou pulado ("Pending" na suíte);
- commit que mexe em spec ou plan durante o implement sem você ter respondido pergunta;
- commit sem número de tarefa que não seja de correção óbvia;
- tarefa marcada `[X]` sem commit correspondente;
- arquivo de imagem ou som criado pelo Claude (proibido pela constituição, princípio IV).

### Passo 8: jogar, converge e fechar

1. Jogar os cenários do quickstart da funcionalidade e registrar no fim dele (igual ao T035).
2. `/speckit-converge` com Opus `high`, sessão nova.
3. Sem pendência: a funcionalidade está fechada. Comece a próxima pelo Passo 1.

---

## Parte 3: prompts do plan

Cada prompt já pede para atualizar a seção "Funcionalidade atual" do `CLAUDE.md`.

### 002, run e mapa (Opus `xhigh`)

```text
/speckit-plan Siga a constituição e reaproveite a 001 sem reescrevê-la: a batalha entra pela interface tela_batalha.iniciar(cartas, vida_arthur, dados_inimigo, regras, semente) e devolve o sinal luta_terminou(resultado); a luta avulsa da 001 sai de cena principal e o mapa entra no lugar. Orientações: (1) o estado da run (ato, casa atual, vida do Arthur, baralho) fica numa classe RefCounted sem cena, testável sozinha; (2) a geração do mapa usa um único RandomNumberGenerator com semente vinda de fora, e os testes provam com muitas sementes que todo mapa tem caminho do início até o chefe e que toda casa é alcançável; (3) toda a dificuldade por profundidade (faixa do alvo, vida e ataque dos inimigos, quantas casas de cada tipo, quanto o descanso cura) fica num único arquivo .tres em dados/, editável sem mexer no código; (4) recompensa (1 de 3 cartas) e descanso são cenas pequenas e separadas, que avisam por sinal; (5) a casa de chefe usa por enquanto uma batalha comum mais forte, com um ponto claro para a 003 trocar; (6) derrota recomeça do calabouço com mapa novo e baralho inicial; (7) pixel art em 640x360 como na 001, com placeholders listados em docs/assets-pendentes.md; (8) diga a ordem de construção e o que dá para fazer em paralelo pela equipe de 6; (9) atualize a seção "Funcionalidade atual" do CLAUDE.md para a 002.
```

### 003, chefes e a prova (Opus `xhigh`)

```text
/speckit-plan Siga a constituição e reaproveite a 001 e a 002 sem reescrevê-las. Orientações: (1) os chefes dos atos 1 e 2 são elites reforçadas, sem regra própria: só valores de vida e ataque em dados (.tres em dados/), na casa de chefe que a 002 deixou preparada; (2) a prova é uma sequência de no máximo 3 questões, cada uma uma fase com regra própria; as regras ficam em dados, e a Batalha recebe a regra da fase sem virar uma classe gigante (prefira um modificador pequeno por tipo de regra, com enum + match como os efeitos das cartas); (3) a busca do alvo continua garantindo alvo alcançável também sob cada regra de questão, com teste comparando com força bruta; (4) vencer a última questão encerra a run com vitória e devolve o resultado por sinal, para a 004 mostrar a cena final; (5) cada regra de questão tem teste próprio, e há simulação de muitas provas com sementes diferentes provando que toda questão tem solução; (6) placeholders dos chefes em docs/assets-pendentes.md; (7) ordem de construção e trabalho em paralelo pela equipe; (8) atualize a seção "Funcionalidade atual" do CLAUDE.md para a 003.
```

### 004, telas, história e tutorial (Opus `xhigh`; as antigas 004 e 005, juntas em 17/11)

```text
/speckit-plan Siga a constituição e reaproveite a 001 a 003 sem reescrevê-las. Orientações: (1) a troca entre telas (menu, abertura, run, derrota, cena final, créditos) passa por um único ponto simples e testável, sem cada cena conhecer as outras; (2) volume separado de música e de efeitos com dois barramentos de áudio, e a escolha do jogador salva em user:// com ConfigFile; (3) pausa com get_tree().paused, sem a lógica da luta depender da pausa; (4) abertura e cena final são telas de texto com imagem fixa, com o texto em dados para a equipe trocar sem mexer no código; (5) os créditos leem um arquivo de dados com a equipe (docs/equipe.md) e a origem e a licença de cada asset; (6) o tutorial é uma sequência de dicas de texto em dados na primeira batalha da primeira run, com semente e mão fixas para as dicas sempre fazerem sentido; a lógica da Batalha não muda (o tutorial só observa os sinais) e "pular tutorial" fica sempre disponível; (7) a explicação de cada símbolo na primeira vez é uma dica curta em dados (símbolo, texto, exemplo), e o registro de quais já foram explicados é salvo em user:// junto com as opções de volume; (8) todos os textos em português; placeholders em docs/assets-pendentes.md; (9) testes de cada transição de tela, do volume salvo, do pular tutorial e de cada símbolo explicado uma vez só; (10) ordem de construção e trabalho em paralelo; (11) atualize a seção "Funcionalidade atual" do CLAUDE.md para a 004.
```

---

## Parte 4: arte, som e entrega (tarde de 29/11)

### Trocar placeholders

Quando chegarem arquivos da equipe, ponha-os numa pasta `arte/` ou `sons/` e, sessão nova,
Opus `medium`:

```text
Chegaram estes assets: <lista de arquivos, de onde vieram e a licença de cada um>. Troque os placeholders correspondentes de docs/assets-pendentes.md por eles, sem criar nem editar imagem ou som. Registre a origem e a licença de cada um nos créditos, tire a linha da pendência, rode a suíte inteira e faça um commit por asset trocado.
```

Para conferir o visual com print do jogo: Opus `xhigh`, mandando o print e perguntando o que
está desalinhado, ilegível ou fora da pixel art.

### Exportar

O Godot precisa dos modelos de exportação da versão 4.7.2 (menu Editor → Gerenciar Modelos
de Exportação, baixar). Depois, sessão nova, Opus `high`:

```text
Configure a exportação do jogo para Windows e Linux em export_presets.cfg, exporte as duas versões para a pasta build/ (que deve ficar no .gitignore) pela linha de comando com --export-release, abra a versão Linux para conferir que inicia sem erro e liste o que precisa ser conferido jogando no Windows.
```

### Ensaio e entrega

- Jogar uma run inteira do menu até a cena final, cronometrando (meta: 20 a 30 min).
- Conferir os créditos com a lista da equipe em [equipe.md](equipe.md).
- Conferir que `docs/assets-pendentes.md` está vazio ou só com o que foi aceito como
  placeholder.
- Commit final e tag: `git tag v1.0`.

---

## Quando vale chamar o Claude (revisão)

- Um sinal de alerta do Passo 7.
- O analyze apontou algo que você não entendeu.
- Bug que o Opus não resolveu em duas tentativas (tente antes o Opus `xhigh`).
- Fim de cada funcionalidade, se quiser uma segunda opinião antes da próxima.
