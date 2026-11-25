extends GutTest
## Runs inteiras jogadas só pela lógica, com sementes hash(i) (SC-003). Em cada casa de luta é
## criada a Batalha real da 001 com o que a Run entrega, para conferir que a luta recebe a vida e
## o baralho da run (FR-003, FR-004, FR-005). As falhas são contadas durante as runs e
## conferidas no fim, como na simulação da 001, para o relatório mostrar a primeira de cada tipo.

const DIFICULDADE: DadosDificuldade = preload("res://dados/dificuldade.tres")
const RUNS := 1000
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
