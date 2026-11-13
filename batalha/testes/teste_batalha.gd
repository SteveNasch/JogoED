extends GutTest

const BARALHO: DadosBaralho = preload("res://dados/baralhos/baralho_luta_avulsa.tres")
const INIMIGO: DadosInimigo = preload("res://dados/inimigos/inimigo_padrao.tres")
const REGRAS: RegrasBatalha = preload("res://dados/regras_batalha.tres")
const N1: DadosCarta = preload("res://dados/cartas/numero_1.tres")
const N2: DadosCarta = preload("res://dados/cartas/numero_2.tres")
const N3: DadosCarta = preload("res://dados/cartas/numero_3.tres")
const N4: DadosCarta = preload("res://dados/cartas/numero_4.tres")
const N5: DadosCarta = preload("res://dados/cartas/numero_5.tres")
const SOMA: DadosCarta = preload("res://dados/cartas/soma.tres")
const SUBTRACAO: DadosCarta = preload("res://dados/cartas/subtracao.tres")
const MULTIPLICACAO: DadosCarta = preload("res://dados/cartas/multiplicacao.tres")


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


## Batalha iniciada com a mão e o alvo trocados para um cenário conhecido.
func _com_mao(mao: Array[DadosCarta], alvo: int) -> Batalha:
	var batalha := _iniciada()
	batalha.baralho.mao = mao
	batalha.alvo = alvo
	return batalha


## Escolhe as cartas da mão pelos índices de antes de escolher (cada uma sai da mão, então
## os índices seguintes descem).
func _montar(batalha: Batalha, indices: Array[int]) -> void:
	var cartas: Array[DadosCarta] = []
	for i in indices:
		cartas.append(batalha.baralho.mao[i])
	for carta in cartas:
		batalha.escolher_carta(batalha.baralho.mao.find(carta))


func _resultado(batalha: Batalha) -> ResultadoRodada:
	return get_signal_parameters(batalha, "rodada_resolvida")[0]


func test_escolher_carta_move_da_mao_para_a_expressao() -> void:
	var batalha := _com_mao([N3, SOMA, N4], 7)
	watch_signals(batalha)
	batalha.escolher_carta(1)
	assert_eq(batalha.baralho.mao, [N3, N4])
	assert_eq(batalha.baralho.expressao, [SOMA])
	assert_signal_emit_count(batalha, "mudou", 1)


func test_escolher_carta_com_indice_invalido_nao_faz_nada() -> void:
	var batalha := _com_mao([N3, SOMA, N4], 7)
	watch_signals(batalha)
	batalha.escolher_carta(3)
	batalha.escolher_carta(-1)
	assert_eq(batalha.baralho.mao, [N3, SOMA, N4])
	assert_eq(batalha.baralho.expressao.size(), 0)
	assert_signal_not_emitted(batalha, "mudou")


func test_pode_confirmar_so_com_a_expressao_nao_vazia() -> void:
	var batalha := _com_mao([N3, SOMA, N4], 7)
	assert_false(batalha.pode_confirmar())
	batalha.escolher_carta(0)
	assert_true(batalha.pode_confirmar())


func test_confirmar_com_a_expressao_vazia_nao_faz_nada() -> void:
	var batalha := _com_mao([N3, SOMA, N4], 7)
	watch_signals(batalha)
	batalha.confirmar()
	assert_eq(batalha.estado, Batalha.Estado.MONTANDO)
	assert_eq(batalha.arthur.vida, 40)
	assert_signal_not_emitted(batalha, "mudou")
	assert_signal_not_emitted(batalha, "rodada_resolvida")


func test_acerto_tira_do_inimigo_a_soma_do_ataque_das_cartas() -> void:
	# Cenário 2 da história 1: 3 + 4 × 2 vale 11 e tira 3 + 1 + 4 + 3 + 2 = 13.
	var batalha := _com_mao([N3, SOMA, N4, MULTIPLICACAO, N2], 11)
	batalha.inimigo.vida = 20
	batalha.inimigo.vida_maxima = 20
	watch_signals(batalha)
	_montar(batalha, [0, 1, 2, 3, 4])
	batalha.confirmar()
	assert_eq(batalha.inimigo.vida, 7)
	assert_eq(batalha.arthur.vida, 37)
	assert_eq(batalha.baralho.mao.size(), 0)
	assert_eq(batalha.baralho.expressao.size(), 0)
	assert_eq(batalha.baralho.descarte, [N3, SOMA, N4, MULTIPLICACAO, N2])
	assert_eq(batalha.estado, Batalha.Estado.MOSTRANDO_RESULTADO)
	assert_signal_emit_count(batalha, "rodada_resolvida", 1)
	var resultado := _resultado(batalha)
	assert_eq(resultado.tipo, ResultadoRodada.Tipo.ACERTO)
	assert_eq(resultado.alvo, 11)
	assert_eq(resultado.valor, 11)
	assert_eq(resultado.dano_causado, 13)
	assert_true(resultado.inimigo_atacou)
	assert_eq(resultado.dano_recebido, 3)


func test_conta_errada_nao_causa_dano_e_gasta_as_cartas() -> void:
	var batalha := _com_mao([N2, SOMA, N5, N1, SUBTRACAO], 9)
	watch_signals(batalha)
	_montar(batalha, [0, 1, 2])
	batalha.confirmar()
	assert_eq(batalha.inimigo.vida, 12)
	assert_eq(batalha.arthur.vida, 37)
	assert_eq(batalha.baralho.descarte, [N2, SOMA, N5])
	assert_eq(batalha.baralho.mao, [N1, SUBTRACAO])
	var resultado := _resultado(batalha)
	assert_eq(resultado.tipo, ResultadoRodada.Tipo.ERRO)
	assert_eq(resultado.valor, 7)
	assert_eq(resultado.alvo, 9)
	assert_eq(resultado.dano_causado, 0)
	assert_true(resultado.inimigo_atacou)


func test_conta_invalida_nao_causa_dano_e_gasta_as_cartas() -> void:
	var batalha := _com_mao([N3, N4, SOMA], 9)
	watch_signals(batalha)
	_montar(batalha, [0, 1])
	batalha.confirmar()
	assert_eq(batalha.inimigo.vida, 12)
	assert_eq(batalha.arthur.vida, 37)
	assert_eq(batalha.baralho.descarte, [N3, N4])
	var resultado := _resultado(batalha)
	assert_eq(resultado.tipo, ResultadoRodada.Tipo.INVALIDA)
	assert_eq(resultado.dano_causado, 0)
	assert_true(resultado.inimigo_atacou)


func test_acerto_com_uma_carta_so() -> void:
	# Edge case da spec: o 5 sozinho é uma conta válida e tira 5, o ataque dele.
	var batalha := _com_mao([N1, N5, SOMA, N2, SUBTRACAO], 5)
	watch_signals(batalha)
	batalha.escolher_carta(1)
	batalha.confirmar()
	var resultado := _resultado(batalha)
	assert_eq(resultado.tipo, ResultadoRodada.Tipo.ACERTO)
	assert_eq(resultado.dano_causado, 5)
	assert_eq(batalha.inimigo.vida, 7)


func test_acoes_nao_valem_enquanto_o_resultado_esta_na_tela() -> void:
	var batalha := _com_mao([N1, N5, SOMA, N2, SUBTRACAO], 5)
	batalha.escolher_carta(1)
	batalha.confirmar()
	watch_signals(batalha)
	batalha.escolher_carta(0)
	batalha.confirmar()
	assert_eq(batalha.baralho.mao, [N1, SOMA, N2, SUBTRACAO])
	assert_eq(batalha.baralho.expressao.size(), 0)
	assert_eq(batalha.estado, Batalha.Estado.MOSTRANDO_RESULTADO)
	assert_signal_not_emitted(batalha, "mudou")
	assert_signal_not_emitted(batalha, "rodada_resolvida")


func test_avancar_so_vale_mostrando_o_resultado() -> void:
	var batalha := _iniciada()
	var mao := batalha.baralho.mao.duplicate()
	watch_signals(batalha)
	batalha.avancar()
	assert_eq(batalha.rodada, 1)
	assert_eq(batalha.baralho.mao, mao)
	assert_signal_not_emitted(batalha, "mudou")


func test_rodada_seguinte_compra_exatamente_uma_carta() -> void:
	# Cenário 3 da história 1: a mão que sobra já cumpre o mínimo, então entra só 1 carta.
	var batalha := _com_mao([N1, N2, N3, SOMA, SUBTRACAO, N5], 5)
	batalha.inimigo.vida = 30
	batalha.escolher_carta(5)
	batalha.confirmar()
	watch_signals(batalha)
	batalha.avancar()
	assert_eq(batalha.rodada, 2)
	assert_eq(batalha.estado, Batalha.Estado.MONTANDO)
	assert_eq(batalha.baralho.mao.size(), 6)
	assert_eq(batalha.baralho.mao.slice(0, 5), [N1, N2, N3, SOMA, SUBTRACAO])
	assert_signal_emit_count(batalha, "mudou", 1)
	var busca := BuscaAlvo.new(REGRAS.alvo_minimo, REGRAS.alvo_maximo, REGRAS.max_numeros_no_alvo, REGRAS.limite_buscas_alvo)
	assert_true(busca.alcancaveis(batalha.baralho.mao).has(batalha.alvo))
