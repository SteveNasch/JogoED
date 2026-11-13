extends GutTest
## 1.000 lutas jogadas só pela lógica, com sementes diferentes (SC-002, SC-003, SC-008). Um
## jogador automático alterna, em ciclo, entre acertar com a conta de exemplo da busca, errar
## de propósito e pular. As falhas são contadas durante as lutas e conferidas no fim, para o
## relatório mostrar a primeira de cada tipo em vez de milhares de linhas.

const BARALHO: DadosBaralho = preload("res://dados/baralhos/baralho_luta_avulsa.tres")
const INIMIGO: DadosInimigo = preload("res://dados/inimigos/inimigo_padrao.tres")
const REGRAS: RegrasBatalha = preload("res://dados/regras_batalha.tres")
const LUTAS := 1000
const SEMENTES_REPETIDAS := 20
## Freio do laço: nenhuma luta pode chegar perto disso (40 de vida, 3 de ataque por rodada).
const MAXIMO_DE_RODADAS := 100

enum Acao { ACERTAR, ERRAR, PULAR }

## As ações em ciclo, uma por rodada.
const CICLO: Array[Acao] = [Acao.ACERTAR, Acao.ERRAR, Acao.PULAR]

var _busca := BuscaAlvo.new(REGRAS.alvo_minimo, REGRAS.alvo_maximo, REGRAS.max_numeros_no_alvo, REGRAS.limite_buscas_alvo)
## Primeira falha de cada conferência (vazio = nenhuma falha).
var _falhas: Dictionary = {}


func _falhou(conferencia: String, detalhe: String) -> void:
	if not _falhas.has(conferencia):
		_falhas[conferencia] = detalhe


func test_mil_lutas_cumprem_as_garantias() -> void:
	var rodadas := 0
	for semente in LUTAS:
		rodadas += _jogar(semente).size()
	for conferencia in ["alvo sem conta", "mão sem o mínimo", "total mudou", "luta sem fim", "busca no teto", "acerto não acertou", "ação sem efeito"]:
		assert_false(_falhas.has(conferencia), "%s: %s" % [conferencia, _falhas.get(conferencia, "")])
	assert_gt(rodadas, LUTAS, "as lutas tiveram mais de uma rodada")


func test_mesma_semente_e_mesmas_acoes_dao_a_mesma_luta() -> void:
	# SC-008. As sementes ficam longe das do outro teste, para não repetir as mesmas lutas.
	for semente in range(50_000, 50_000 + SEMENTES_REPETIDAS):
		var primeira := _jogar(semente)
		var segunda := _jogar(semente)
		assert_gt(primeira.size(), 0, "semente %d" % semente)
		assert_eq(primeira, segunda, "semente %d" % semente)


## Joga uma luta inteira e devolve o registro de cada rodada (alvo, mão, ação e resultado),
## que serve para comparar duas lutas com a mesma semente.
func _jogar(semente: int) -> Array:
	var batalha := Batalha.new(BARALHO.cartas, REGRAS.vida_maxima_arthur, INIMIGO, REGRAS, semente)
	var registro: Array = []
	var ultimo: Array[ResultadoRodada] = []
	batalha.rodada_resolvida.connect(func(resultado: ResultadoRodada) -> void: ultimo.append(resultado))
	batalha.iniciar()
	while batalha.estado != Batalha.Estado.TERMINADA:
		if batalha.rodada > MAXIMO_DE_RODADAS:
			_falhou("luta sem fim", "semente %d" % semente)
			break
		var onde := "semente %d, rodada %d" % [semente, batalha.rodada]
		_conferir_comeco_de_rodada(batalha, onde)
		var alcancaveis := _busca.alcancaveis(batalha.baralho.mao)
		var acao := CICLO[(batalha.rodada - 1) % CICLO.size()]
		var mao := _simbolos(batalha.baralho.mao)
		match acao:
			Acao.ACERTAR:
				_montar(batalha, alcancaveis.get(batalha.alvo, []))
				batalha.confirmar()
			Acao.ERRAR:
				_montar(batalha, [_carta_errada(batalha)])
				batalha.confirmar()
			Acao.PULAR:
				batalha.pular()
		if batalha.estado == Batalha.Estado.MONTANDO:
			# A conta ficou vazia (não havia carta para ela): falha, e o Pular destrava a luta.
			_falhou("ação sem efeito", onde)
			batalha.pular()
		var resultado: ResultadoRodada = ultimo.back()
		if acao == Acao.ACERTAR and resultado.tipo != ResultadoRodada.Tipo.ACERTO:
			_falhou("acerto não acertou", onde)
		if batalha.baralho.total() != BARALHO.cartas.size():
			_falhou("total mudou", onde)
		registro.append([batalha.alvo, mao, acao, resultado.tipo, resultado.valor, batalha.arthur.vida, batalha.inimigo.vida])
		batalha.avancar()
	return registro


## SC-002, SC-003, total constante e teto da busca, conferidos no começo de cada rodada.
func _conferir_comeco_de_rodada(batalha: Batalha, onde: String) -> void:
	var baralho := batalha.baralho
	if baralho.total() != BARALHO.cartas.size():
		_falhou("total mudou", onde)
	var alcancaveis := _busca.alcancaveis(baralho.mao)
	if _busca.avaliacoes >= REGRAS.limite_buscas_alvo:
		_falhou("busca no teto", "%s: %d avaliações" % [onde, _busca.avaliacoes])
	if not alcancaveis.has(batalha.alvo) or not _usa_so_a_mao(alcancaveis[batalha.alvo], baralho.mao):
		_falhou("alvo sem conta", "%s: alvo %d, mão %s" % [onde, batalha.alvo, _simbolos(baralho.mao)])
	var minimos := {
		DadosCarta.Tipo.NUMERO: REGRAS.minimo_numeros,
		DadosCarta.Tipo.SOMA: REGRAS.minimo_somas,
		DadosCarta.Tipo.SUBTRACAO: REGRAS.minimo_subtracoes,
	}
	for tipo: DadosCarta.Tipo in minimos:
		var fora_da_mao := _quantos_do_tipo(baralho.compra, tipo) + _quantos_do_tipo(baralho.descarte, tipo)
		if _quantos_do_tipo(baralho.mao, tipo) < minimos[tipo] and fora_da_mao > 0:
			_falhou("mão sem o mínimo", "%s: mão %s" % [onde, _simbolos(baralho.mao)])


## A conta usa cada carta no máximo tantas vezes quanto ela aparece na mão.
func _usa_so_a_mao(conta: Array, mao: Array[DadosCarta]) -> bool:
	var sobra := mao.duplicate()
	for carta in conta:
		var i := sobra.find(carta)
		if i == -1:
			return false
		sobra.remove_at(i)
	return true


## Para cada carta, acha o índice dela na mão atual (os índices mudam quando uma carta sai).
## Procurar por referência é seguro aqui porque cartas iguais são intercambiáveis; quem move a
## carta continua sendo o Baralho, por posição.
func _montar(batalha: Batalha, conta: Array) -> void:
	for carta in conta:
		batalha.escolher_carta(batalha.baralho.mao.find(carta))


## Uma carta de número com valor diferente do alvo; se todas valem o alvo, o "+" sozinho
## (conta inválida).
func _carta_errada(batalha: Batalha) -> DadosCarta:
	var soma: DadosCarta = null
	for carta in batalha.baralho.mao:
		if carta.eh_numero() and carta.valor != batalha.alvo:
			return carta
		if carta.tipo == DadosCarta.Tipo.SOMA:
			soma = carta
	return soma


func _quantos_do_tipo(cartas: Array[DadosCarta], tipo: DadosCarta.Tipo) -> int:
	var quantidade := 0
	for carta in cartas:
		if carta.tipo == tipo:
			quantidade += 1
	return quantidade


func _simbolos(cartas: Array[DadosCarta]) -> Array[String]:
	var simbolos: Array[String] = []
	for carta in cartas:
		simbolos.append(carta.simbolo())
	return simbolos
