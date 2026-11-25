extends GutTest
## Runs inteiras jogadas só pela lógica, com sementes hash(i) (SC-003). Em cada casa de luta é
## criada a Batalha real da 001 com o que a Run entrega, para conferir que a luta recebe a vida e
## o baralho da run (FR-003, FR-004, FR-005). As falhas são contadas durante as runs e
## conferidas no fim, como na simulação da 001, para o relatório mostrar a primeira de cada tipo.

const JogadorAutomatico := preload("res://batalha/testes/jogador_automatico.gd")
const DIFICULDADE: DadosDificuldade = preload("res://dados/dificuldade.tres")
const RUNS := 1000
## Runs com as lutas jogadas de verdade pelo jogador automático da 001.
const RUNS_JOGADAS := 20
## Freio do laço de cada luta jogada (o inimigo ataca toda rodada, então a luta acaba bem antes).
const MAXIMO_DE_RODADAS := 100
## Chance de perder cada luta, em porcentagem: baixa, para muitas runs chegarem ao ato 3.
const CHANCE_DE_DERROTA := 3
## Freio do laço: uma run tem 15 casas, e cada casa abre no máximo duas etapas.
const MAXIMO_DE_PASSOS := 100

## Primeira falha de cada conferência (vazio = nenhuma falha).
var _falhas: Dictionary = {}


func _falhou(conferencia: String, detalhe: String) -> void:
	if not _falhas.has(conferencia):
		_falhas[conferencia] = detalhe


func test_mil_runs_com_escolhas_automaticas_cumprem_as_invariantes() -> void:
	var fins := {Run.Etapa.VITORIA: 0, Run.Etapa.DERROTA: 0}
	for i in RUNS:
		var etapa_final := _jogar_escolhendo(hash(i), "run %d (semente hash(%d))" % [i, i])
		if fins.has(etapa_final):
			fins[etapa_final] += 1
	for conferencia in ["run sem fim", "vida da luta", "baralho da luta", "escudo ou mão na luta", "vida fora da faixa", "baralho da run", "caminho", "cura", "oferta fora da recompensa", "oferta inválida", "lutas vencidas", "ato"]:
		assert_false(_falhas.has(conferencia), "%s: %s" % [conferencia, _falhas.get(conferencia, "")])
	assert_gt(fins[Run.Etapa.VITORIA], 0, "houve runs vencidas")
	assert_gt(fins[Run.Etapa.DERROTA], 0, "houve runs perdidas")
	assert_eq(fins[Run.Etapa.VITORIA] + fins[Run.Etapa.DERROTA], RUNS, "toda run terminou")


## Joga uma run do começo ao fim com as escolhas sorteadas pelo gerador do teste e devolve a
## etapa em que ela terminou.
func _jogar_escolhendo(semente: int, nome: String) -> Run.Etapa:
	var run := Run.new(DIFICULDADE, semente)
	var escolhas := RandomNumberGenerator.new()
	escolhas.seed = semente
	var escolhidas: Array[DadosCarta] = []
	var vencidas := 0
	## Vida com que a próxima luta tem que começar: a que sobrou da anterior mais as curas.
	var vida_esperada := run.vida_maxima
	var passos := 0
	while run.etapa not in [Run.Etapa.VITORIA, Run.Etapa.DERROTA]:
		passos += 1
		if passos > MAXIMO_DE_PASSOS:
			_falhou("run sem fim", nome)
			break
		var onde := "%s, ato %d, andar %d" % [nome, run.ato, run.andar_alcancado()]
		_conferir_invariantes(run, escolhidas, onde)
		match run.etapa:
			Run.Etapa.MAPA:
				var disponiveis := run.casas_disponiveis()
				run.escolher_casa(disponiveis[escolhas.randi_range(0, disponiveis.size() - 1)])
				if run.etapa == Run.Etapa.DESCANSO:
					var cura := mini(run.vida_maxima - vida_esperada, floori(run.vida_maxima * DIFICULDADE.cura_do_descanso / 100.0))
					if run.cura != cura or run.vida_arthur != vida_esperada + cura:
						_falhou("cura", "%s: vida %d, cura %d" % [onde, run.vida_arthur, run.cura])
					vida_esperada += cura
			Run.Etapa.LUTA, Run.Etapa.CHEFE:
				_conferir_batalha(run, escolhidas, vida_esperada, onde)
				if escolhas.randi_range(1, 100) <= CHANCE_DE_DERROTA:
					run.terminar_luta(ResultadoLuta.new(false, 0, 1, 3))
				else:
					vida_esperada = escolhas.randi_range(1, run.vida_arthur)
					run.terminar_luta(ResultadoLuta.new(true, vida_esperada, 0, 3))
					vencidas += 1
				if run.lutas_vencidas != vencidas:
					_falhou("lutas vencidas", "%s: %d, esperado %d" % [onde, run.lutas_vencidas, vencidas])
			Run.Etapa.DESCANSO:
				run.sair_do_descanso()
			Run.Etapa.RECOMPENSA:
				var ato_antes := run.ato
				var do_chefe := run.casa_atual.tipo == Casa.Tipo.CHEFE
				var escolha := escolhas.randi_range(-1, run.oferta.size() - 1)
				var carta: DadosCarta = null if escolha == -1 else run.oferta[escolha]
				run.escolher_recompensa(carta)
				if carta != null:
					escolhidas.append(carta)
				if run.ato != ato_antes + (1 if do_chefe else 0):
					_falhou("ato", "%s: ato %d depois da recompensa" % [onde, run.ato])
	if run.etapa == Run.Etapa.DERROTA and run.vida_arthur != 0:
		_falhou("vida fora da faixa", "%s: derrota com vida %d" % [nome, run.vida_arthur])
	if run.etapa == Run.Etapa.VITORIA and not (run.ultimo_ato() and run.casa_atual.tipo == Casa.Tipo.CHEFE):
		_falhou("ato", "%s: vitória fora do chefe do último ato" % nome)
	return run.etapa


## A Batalha da 001 criada com o que a Run entrega, sem iniciar(): antes dele, todas as cartas
## estão na pilha de compra (FR-005: cada luta começa com o baralho inteiro e sem escudo).
func _conferir_batalha(run: Run, escolhidas: Array[DadosCarta], vida_esperada: int, onde: String) -> void:
	var batalha := Batalha.new(run.baralho, run.vida_arthur, run.inimigo_da_luta(), run.regras_da_luta(), run.semente_da_luta)
	if batalha.arthur.vida != vida_esperada:
		_falhou("vida da luta", "%s: %d, esperado %d" % [onde, batalha.arthur.vida, vida_esperada])
	if _contagem(batalha.baralho.compra) != _contagem(_baralho_esperado(escolhidas)):
		_falhou("baralho da luta", "%s: %d cartas" % [onde, batalha.baralho.compra.size()])
	if batalha.arthur.escudo != 0 or not batalha.baralho.mao.is_empty():
		_falhou("escudo ou mão na luta", onde)


## Invariantes do data-model, conferidas em toda casa.
func _conferir_invariantes(run: Run, escolhidas: Array[DadosCarta], onde: String) -> void:
	if run.vida_arthur < 1 or run.vida_arthur > run.vida_maxima:
		_falhou("vida fora da faixa", "%s: %d" % [onde, run.vida_arthur])
	if run.baralho != _baralho_esperado(escolhidas):
		_falhou("baralho da run", onde)
	if run.etapa != Run.Etapa.RECOMPENSA and not run.oferta.is_empty():
		_falhou("oferta fora da recompensa", onde)
	if run.etapa == Run.Etapa.RECOMPENSA:
		var conjunto := DIFICULDADE.cartas_de_recompensa
		var tamanho := mini(DIFICULDADE.cartas_por_recompensa, conjunto.size())
		if run.oferta.size() != tamanho or run.oferta.any(func(carta: DadosCarta) -> bool: return carta not in conjunto or run.oferta.count(carta) > 1):
			_falhou("oferta inválida", onde)
	var caminho := run.mapa().casas.filter(func(casa: Casa) -> bool: return casa.visitada)
	if caminho.size() != run.andar_alcancado():
		_falhou("caminho", "%s: %d casas visitadas" % [onde, caminho.size()])
		return
	for posicao in caminho.size():
		if caminho[posicao].andar != posicao + 1 or (posicao > 0 and caminho[posicao] not in caminho[posicao - 1].ligacoes):
			_falhou("caminho", onde)
	if not caminho.is_empty() and caminho.back() != run.casa_atual:
		_falhou("caminho", "%s: o caminho não termina na casa atual" % onde)


func _baralho_esperado(escolhidas: Array[DadosCarta]) -> Array[DadosCarta]:
	var esperado := DIFICULDADE.baralho_inicial.duplicate()
	esperado.append_array(escolhidas)
	return esperado


## Quantas vezes cada carta aparece, sem importar a ordem (a Batalha embaralha).
func _contagem(cartas: Array[DadosCarta]) -> Dictionary:
	var contagem := {}
	for carta in cartas:
		contagem[carta] = contagem.get(carta, 0) + 1
	return contagem


# --- Runs com as lutas jogadas de verdade (FR-029, SC-002) ---

func test_vinte_runs_com_lutas_jogadas_cumprem_as_garantias() -> void:
	var lutas := 0
	for i in RUNS_JOGADAS:
		var registro := _jogar_lutando(hash(i), "run jogada %d (semente hash(%d))" % [i, i])
		lutas += registro.filter(func(item: Array) -> bool: return item[0] == "luta").size()
	for conferencia in ["run sem fim", "luta sem fim", "alvo sem conta", "mão sem o mínimo", "ação sem efeito", "vida levada", "baralho mudou na luta", "baralho da run", "vida fora da faixa", "caminho"]:
		assert_false(_falhas.has(conferencia), "%s: %s" % [conferencia, _falhas.get(conferencia, "")])
	assert_gt(lutas, RUNS_JOGADAS, "as runs tiveram mais de uma luta")


func test_mesma_semente_e_mesmas_escolhas_repetem_a_run_rodada_por_rodada() -> void:
	for i in RUNS_JOGADAS:
		var nome := "semente hash(%d)" % i
		var primeira := _jogar_lutando(hash(i), nome)
		assert_gt(primeira.size(), 0, nome)
		assert_eq(_jogar_lutando(hash(i), nome), primeira, nome)


## Joga uma run do ato 1 até a vitória ou a derrota, com cada luta jogada pelo jogador
## automático e as escolhas do mapa e da recompensa sorteadas pelo gerador do teste. Devolve o
## registro da run (casas, rodadas de cada luta e recompensas), para comparar duas runs.
func _jogar_lutando(semente: int, nome: String) -> Array:
	var run := Run.new(DIFICULDADE, semente)
	var escolhas := RandomNumberGenerator.new()
	escolhas.seed = semente
	var escolhidas: Array[DadosCarta] = []
	var registro: Array = []
	var passos := 0
	while run.etapa not in [Run.Etapa.VITORIA, Run.Etapa.DERROTA]:
		passos += 1
		if passos > MAXIMO_DE_PASSOS:
			_falhou("run sem fim", nome)
			break
		var onde := "%s, ato %d, andar %d" % [nome, run.ato, run.andar_alcancado()]
		_conferir_invariantes(run, escolhidas, onde)
		match run.etapa:
			Run.Etapa.MAPA:
				var disponiveis := run.casas_disponiveis()
				var casa := disponiveis[escolhas.randi_range(0, disponiveis.size() - 1)]
				run.escolher_casa(casa)
				registro.append(["casa", run.ato, casa.andar, casa.indice, casa.tipo])
			Run.Etapa.LUTA, Run.Etapa.CHEFE:
				var baralho_antes := run.baralho.duplicate()
				var resultado := _lutar(run, onde, registro)
				if resultado == null:
					break
				run.terminar_luta(resultado)
				if resultado.venceu and run.vida_arthur != resultado.vida_arthur:
					_falhou("vida levada", "%s: run com %d, luta deixou %d" % [onde, run.vida_arthur, resultado.vida_arthur])
				if run.baralho != baralho_antes:
					_falhou("baralho mudou na luta", onde)
			Run.Etapa.DESCANSO:
				registro.append(["descanso", run.cura])
				run.sair_do_descanso()
			Run.Etapa.RECOMPENSA:
				var escolha := escolhas.randi_range(-1, run.oferta.size() - 1)
				var carta: DadosCarta = null if escolha == -1 else run.oferta[escolha]
				registro.append(["recompensa", run.oferta.duplicate(), carta])
				run.escolher_recompensa(carta)
				if carta != null:
					escolhidas.append(carta)
	registro.append(["fim", run.etapa, run.ato, run.andar_alcancado(), run.lutas_vencidas])
	return registro


## Joga a luta da casa atual com a Batalha da 001 e o jogador automático, conferindo o começo
## de cada rodada, e devolve o ResultadoLuta (null se a luta não acabou).
func _lutar(run: Run, onde: String, registro: Array) -> ResultadoLuta:
	var regras := run.regras_da_luta()
	var busca := BuscaAlvo.new(regras.alvo_minimo, regras.alvo_maximo, regras.max_numeros_no_alvo, regras.limite_buscas_alvo)
	var batalha := Batalha.new(run.baralho, run.vida_arthur, run.inimigo_da_luta(), regras, run.semente_da_luta)
	var fim: Array[ResultadoLuta] = []
	var ultimo: Array[ResultadoRodada] = []
	batalha.luta_terminou.connect(func(resultado: ResultadoLuta) -> void: fim.append(resultado))
	batalha.rodada_resolvida.connect(func(resultado: ResultadoRodada) -> void: ultimo.append(resultado))
	batalha.iniciar()
	while batalha.estado != Batalha.Estado.TERMINADA:
		if batalha.rodada > MAXIMO_DE_RODADAS:
			_falhou("luta sem fim", onde)
			return null
		var rodada := "%s, rodada %d" % [onde, batalha.rodada]
		_conferir_rodada(batalha, busca, rodada)
		var mao := JogadorAutomatico.simbolos(batalha.baralho.mao)
		var acao := JogadorAutomatico.jogar_rodada(batalha, busca)
		if batalha.estado == Batalha.Estado.MONTANDO:
			# A conta ficou vazia (não havia carta para ela): falha, e o Pular destrava a luta.
			_falhou("ação sem efeito", rodada)
			batalha.pular()
		var resultado: ResultadoRodada = ultimo.back()
		registro.append(["luta", batalha.alvo, mao, acao, resultado.tipo, resultado.valor, batalha.arthur.vida, batalha.inimigo.vida])
		batalha.avancar()
	return fim.back()


## FR-029: o alvo tem conta de exemplo com as cartas da mão, e a mão tem o mínimo de cada tipo
## quando o baralho permite. Não exige "nenhuma busca no teto" (research D7).
func _conferir_rodada(batalha: Batalha, busca: BuscaAlvo, onde: String) -> void:
	var baralho := batalha.baralho
	var alcancaveis := busca.alcancaveis(baralho.mao)
	if not alcancaveis.has(batalha.alvo) or not JogadorAutomatico.usa_so_a_mao(alcancaveis[batalha.alvo], baralho.mao):
		_falhou("alvo sem conta", "%s: alvo %d, mão %s" % [onde, batalha.alvo, JogadorAutomatico.simbolos(baralho.mao)])
	var minimos := {
		DadosCarta.Tipo.NUMERO: batalha.regras.minimo_numeros,
		DadosCarta.Tipo.SOMA: batalha.regras.minimo_somas,
		DadosCarta.Tipo.SUBTRACAO: batalha.regras.minimo_subtracoes,
	}
	for tipo: DadosCarta.Tipo in minimos:
		var fora_da_mao := JogadorAutomatico.quantos_do_tipo(baralho.compra, tipo) + JogadorAutomatico.quantos_do_tipo(baralho.descarte, tipo)
		if JogadorAutomatico.quantos_do_tipo(baralho.mao, tipo) < minimos[tipo] and fora_da_mao > 0:
			_falhou("mão sem o mínimo", "%s: mão %s" % [onde, JogadorAutomatico.simbolos(baralho.mao)])
