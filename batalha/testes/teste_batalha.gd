extends GutTest

const BARALHO: DadosBaralho = preload("res://dados/baralhos/baralho_luta_avulsa.tres")
const INIMIGO: DadosInimigo = preload("res://dados/inimigos/inimigo_padrao.tres")
const REGRAS: RegrasBatalha = preload("res://dados/regras_batalha.tres")


func _batalha(semente: int = 1, vida_arthur: int = 40) -> Batalha:
	return Batalha.new(BARALHO.cartas, vida_arthur, INIMIGO, REGRAS, semente)


func _iniciada(semente: int = 1) -> Batalha:
	var batalha := _batalha(semente)
	batalha.iniciar()
	return batalha


func _quantos_do_tipo(cartas: Array[DadosCarta], tipo: DadosCarta.Tipo) -> int:
	var quantidade := 0
	for carta in cartas:
		if carta.tipo == tipo:
			quantidade += 1
	return quantidade


func test_arthur_comeca_com_a_vida_recebida_e_maxima_das_regras() -> void:
	var batalha := _batalha(1, 31)
	batalha.iniciar()
	assert_eq(batalha.arthur.nome, "Arthur")
	assert_eq(batalha.arthur.vida, 31)
	assert_eq(batalha.arthur.vida_maxima, 40)
	assert_eq(batalha.arthur.escudo, 0)
	assert_eq(batalha.arthur.ataque, 0)


func test_inimigo_comeca_com_a_vida_cheia() -> void:
	var batalha := _iniciada()
	assert_eq(batalha.inimigo.nome, "Inimigo")
	assert_eq(batalha.inimigo.vida, 12)
	assert_eq(batalha.inimigo.vida_maxima, 12)
	assert_eq(batalha.inimigo.ataque, 3)
	assert_eq(batalha.inimigo.escudo, 0)


func test_iniciar_comeca_a_rodada_1_montando() -> void:
	var batalha := _batalha()
	watch_signals(batalha)
	batalha.iniciar()
	assert_eq(batalha.rodada, 1)
	assert_eq(batalha.estado, Batalha.Estado.MONTANDO)
	assert_signal_emit_count(batalha, "mudou", 1)


func test_mao_inicial_tem_5_cartas_com_o_minimo() -> void:
	for semente in range(1, 31):
		var mao := _iniciada(semente).baralho.mao
		assert_eq(mao.size(), 5, "semente %d" % semente)
		assert_eq(_quantos_do_tipo(mao, DadosCarta.Tipo.NUMERO), 3, "semente %d" % semente)
		assert_eq(_quantos_do_tipo(mao, DadosCarta.Tipo.SOMA), 1, "semente %d" % semente)
		assert_eq(_quantos_do_tipo(mao, DadosCarta.Tipo.SUBTRACAO), 1, "semente %d" % semente)


func test_alvo_e_alcancavel_com_a_mao() -> void:
	var busca := BuscaAlvo.new(REGRAS.alvo_minimo, REGRAS.alvo_maximo, REGRAS.max_numeros_no_alvo, REGRAS.limite_buscas_alvo)
	for semente in range(1, 31):
		var batalha := _iniciada(semente)
		var alcancaveis := busca.alcancaveis(batalha.baralho.mao)
		assert_true(alcancaveis.has(batalha.alvo), "semente %d, alvo %d" % [semente, batalha.alvo])


func test_lista_de_cartas_recebida_fica_intacta() -> void:
	var cartas: Array[DadosCarta] = BARALHO.cartas.duplicate()
	var batalha := Batalha.new(cartas, 40, INIMIGO, REGRAS, 7)
	batalha.iniciar()
	assert_eq(cartas, BARALHO.cartas)
	assert_eq(batalha.baralho.total(), 21)


func test_mesma_semente_da_mesma_mao_e_mesmo_alvo() -> void:
	for semente in [3, 99, 12345]:
		var primeira := _iniciada(semente)
		var segunda := _iniciada(semente)
		assert_eq(primeira.baralho.mao, segunda.baralho.mao)
		assert_eq(primeira.alvo, segunda.alvo)
