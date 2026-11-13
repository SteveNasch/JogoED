<!--
Sync Impact Report
- Versão: 1.0.0 → 1.0.1 (PATCH: correção de um fato, sem mudar princípio nem regra)
- Princípios modificados: nenhum
- Restrições Técnicas: "Equipe" passa de 5 para 6 estudantes, com a lista em docs/equipe.md
- Seções adicionadas: nenhuma
- Seções removidas: nenhuma
- Templates (.specify/templates/*): não alterados; leem esta constituição em tempo de execução.
- Pendência fora da constituição: specs/001-nucleo-batalha/research.md ainda cita "cinco"
  (D1 e D6).
- TODOs adiados: nenhum
-->

# JogoED Constitution

## Core Principles

### I. Código Limpo e Minimalista

- O código MUST seguir os princípios do Clean Code: nomes que revelam a intenção, funções
  pequenas com uma única responsabilidade, sem duplicação e sem código morto ou comentado.
- Cada mudança MUST implementar só o que a especificação pede (YAGNI). Abstração, padrão de
  projeto ou camada extra só entra quando resolve um problema que já existe no código.
- Minimalismo não justifica perder qualidade: tipagem estática do GDScript, tratamento de
  casos de erro e legibilidade MUST ser mantidos mesmo quando aumentam um pouco o código.

Motivo: o projeto é mantido por estudantes; quanto menos código e mais claro, mais fácil
para todos entenderem, revisarem e apresentarem.

### II. Testes Reais para Cada Área (INEGOCIÁVEL)

- Toda área do código com lógica (scripts de jogo, sistemas, cenas com comportamento) MUST
  ter testes automatizados com GUT que rodem pela linha de comando.
- Os testes MUST ser reais: exercitam o comportamento de verdade (instanciando a cena ou o
  script e conferindo o resultado). São proibidos testes que só passam por construção
  (`assert_true(true)`), que testam o mock no lugar do código ou que foram ajustados para
  esconder um defeito.
- Uma tarefa só está pronta quando seus testes passam e a suíte inteira continua verde.
- Bug corrigido MUST ganhar um teste que falhava antes da correção.

Motivo: testes são a prova de que o jogo funciona sem depender de abrir o editor e jogar
cada mudança à mão.

### III. Cenas Pequenas e Separadas

- Cada área do jogo (menu, fase, jogador, inimigo, HUD, diálogo etc.) MUST ser uma cena
  própria (`.tscn`) com o seu script, pequena e com uma responsabilidade clara.
- Cenas MUST se comunicar por sinais ou por uma interface explícita, sem buscar nós de outras
  cenas por caminhos longos (`get_node("../../..")`).
- Uma cena MUST poder ser aberta e testada sozinha.
- O projeto MUST ser organizado em pastas por área do jogo, com a cena, o script e os testes
  da área fáceis de achar juntos.

Motivo: cenas pequenas reduzem conflitos entre os integrantes e deixam a manutenção local.

### IV. Assets Vêm da Equipe (INEGOCIÁVEL)

- O agente de IA MUST NOT criar sprites, músicas, efeitos sonoros ou qualquer outro asset
  artístico por conta própria.
- Quando precisar de um asset, o agente MUST pedir à equipe, dizendo o que precisa (tipo,
  tamanho, quantidade de quadros, formato) e onde ele será usado. A equipe pesquisa e
  disponibiliza o arquivo.
- Só se a equipe não encontrar o asset, o agente MAY gerar um com base nos sprites que já
  estão no projeto, e somente depois de autorização explícita para aquele asset.
- Enquanto o asset não chega, o código MAY usar um placeholder neutro do próprio Godot (por
  exemplo `ColorRect` ou o ícone padrão), que MUST ser registrado como pendência.
- A origem e a licença de cada asset MUST ficar registradas no projeto.

Motivo: a direção de arte e o uso legal dos arquivos são decisões da equipe.

### V. Tudo em Português, no Estilo da Equipe

- O jogo (textos, menus, diálogos) e o código (nomes, comentários, mensagens de commit,
  documentação) MUST estar em português.
- Identificadores e nomes de arquivo MUST ser escritos sem acento e em `snake_case`, seguindo
  o guia de estilo do GDScript (ex.: `vida_maxima`, `cena_batalha.tscn`); classes em
  `PascalCase` (ex.: `class_name Jogador`). Acentos ficam nos textos do jogo e nos
  comentários. Nomes da própria API do Godot (`_ready`, `Node2D`) continuam em inglês.
- O código MUST parecer escrito por estudantes de Ciência da Computação do IFSP: simples e
  direto, nomes claros, comentários curtos só onde explicam o porquê, sem padrões rebuscados
  nem jargão que a equipe não usaria.

Motivo: o projeto é uma entrega da disciplina e precisa ser entendido e defendido pela equipe.

## Restrições Técnicas

- **Motor:** a última versão estável do Godot 4 (hoje 4.7.2-stable). Versões dev, beta ou RC
  MUST NOT ser usadas. Quando sair uma versão estável nova, a atualização MUST ser feita numa
  tarefa própria, com a suíte de testes passando antes e depois.
- **Linguagem:** GDScript com tipagem estática.
- **Testes:** GUT, na versão compatível com o Godot em uso, executável pela linha de comando.
- **Equipe:** 6 estudantes de Bacharelado em Ciência da Computação do IFSP Salto (lista em
  `docs/equipe.md`).

## Fluxo de Desenvolvimento

- Toda funcionalidade passa pelo Spec Kit: especificar → esclarecer → planejar → tarefas →
  implementar.
- O plano de cada funcionalidade MUST conferir os cinco princípios ("Constitution Check") e
  justificar por escrito qualquer exceção.
- Antes de dar uma tarefa como concluída, MUST: rodar a suíte GUT inteira, conferir que não
  sobrou código morto e listar os assets pedidos e ainda pendentes.

## Governance

- Esta constituição prevalece sobre qualquer outra prática do projeto. Em conflito, ela vence
  até ser emendada.
- Emendas MUST ser propostas por escrito, aprovadas pela equipe e registradas neste arquivo,
  com o relatório de impacto atualizado no topo.
- Versionamento semântico: MAJOR para remover ou redefinir princípio; MINOR para princípio
  ou seção nova ou regra ampliada; PATCH para redação e correções sem mudar o sentido.
- Toda revisão de código e todo `/speckit-analyze` MUST verificar a conformidade com estes
  princípios.

**Version**: 1.0.1 | **Ratified**: 2026-11-13 | **Last Amended**: 2026-11-13
