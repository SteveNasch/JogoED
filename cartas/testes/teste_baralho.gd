extends GutTest


## Cartas de número todas diferentes (objetos distintos), para a ordem ser conferível.
func _cartas_distintas(quantidade: int) -> Array[DadosCarta]:
	var cartas: Array[DadosCarta] = []
	for i in quantidade:
		var carta := DadosCarta.new()
		carta.valor = i + 1
		cartas.append(carta)
	return cartas


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _baralho(cartas: Array[DadosCarta], semente: int = 1) -> Baralho:
	return Baralho.new(cartas, _rng(semente))


func test_comeca_com_todas_as_cartas_na_compra() -> void:
	var cartas := _cartas_distintas(21)
	var baralho := _baralho(cartas)
	assert_eq(baralho.compra.size(), 21)
	assert_eq(baralho.mao.size(), 0)
	assert_eq(baralho.expressao.size(), 0)
	assert_eq(baralho.descarte.size(), 0)
	for carta in cartas:
		assert_true(carta in baralho.compra)


func test_lista_recebida_nao_e_alterada() -> void:
	var cartas := _cartas_distintas(21)
	var copia := cartas.duplicate()
	var baralho := _baralho(cartas)
	baralho.comprar(5)
	baralho.por_na_expressao(0)
	baralho.descartar_expressao()
	assert_eq(cartas, copia)


func test_mesma_semente_da_a_mesma_ordem() -> void:
	var cartas := _cartas_distintas(21)
	assert_eq(_baralho(cartas, 42).compra, _baralho(cartas, 42).compra)


func test_sementes_diferentes_dao_ordens_diferentes() -> void:
	var cartas := _cartas_distintas(21)
	assert_ne(_baralho(cartas, 1).compra, _baralho(cartas, 2).compra)


func test_embaralha_a_lista() -> void:
	var cartas := _cartas_distintas(21)
	assert_ne(_baralho(cartas).compra, cartas)


func test_compra_sai_do_topo_da_pilha() -> void:
	var cartas := _cartas_distintas(3)
	var baralho := _baralho(cartas)
	baralho.compra = cartas.duplicate()
	assert_eq(baralho.comprar(2), 2)
	assert_eq(baralho.mao, [cartas[2], cartas[1]])
	assert_eq(baralho.compra, [cartas[0]])


func test_pilha_vazia_recompra_pelo_descarte() -> void:
	var cartas := _cartas_distintas(6)
	var baralho := _baralho(cartas)
	baralho.comprar(6)
	baralho.por_na_expressao(0)
	baralho.por_na_expressao(0)
	baralho.por_na_expressao(0)
	baralho.descartar_expressao()
	assert_eq(baralho.compra.size(), 0)
	assert_eq(baralho.comprar(2), 2)
	assert_eq(baralho.mao.size(), 5)
	assert_eq(baralho.compra.size() + baralho.descarte.size(), 1)


func test_recompra_embaralha_o_descarte_com_o_gerador() -> void:
	var cartas := _cartas_distintas(12)
	var compras_por_semente: Array = []
	for semente in [5, 5, 6]:
		var baralho := _baralho(cartas, semente)
		baralho.descarte = baralho.compra
		baralho.compra = []
		baralho.comprar(12)
		compras_por_semente.append(baralho.mao)
	assert_eq(compras_por_semente[0], compras_por_semente[1], "mesma semente")
	assert_ne(compras_por_semente[0], compras_por_semente[2], "semente diferente")


func test_compra_com_as_duas_pilhas_vazias_nao_compra_nada() -> void:
	var baralho := _baralho(_cartas_distintas(5))
	assert_eq(baralho.comprar(5), 5)
	assert_eq(baralho.comprar(3), 0)
	assert_eq(baralho.mao.size(), 5)


func test_compra_para_quando_as_cartas_acabam() -> void:
	var baralho := _baralho(_cartas_distintas(4))
	assert_eq(baralho.comprar(10), 4)


func test_expressao_desfazer_e_limpar_mantem_a_ordem() -> void:
	var cartas := _cartas_distintas(5)
	var baralho := _baralho(cartas)
	baralho.compra = []
	baralho.mao = cartas.duplicate()
	var a := cartas[0]
	var b := cartas[1]
	var c := cartas[2]
	var d := cartas[3]
	var e := cartas[4]
	baralho.por_na_expressao(1)
	baralho.por_na_expressao(2)
	baralho.por_na_expressao(0)
	assert_eq(baralho.expressao, [b, d, a])
	assert_eq(baralho.mao, [c, e])
	baralho.desfazer()
	assert_eq(baralho.expressao, [b, d])
	assert_eq(baralho.mao, [c, e, a])
	baralho.limpar()
	assert_eq(baralho.expressao, [])
	assert_eq(baralho.mao, [c, e, a, b, d])


func test_desfazer_com_expressao_vazia_nao_faz_nada() -> void:
	var baralho := _baralho(_cartas_distintas(3))
	baralho.comprar(3)
	var mao := baralho.mao.duplicate()
	baralho.desfazer()
	assert_eq(baralho.mao, mao)


func test_indice_invalido_nao_move_carta() -> void:
	var baralho := _baralho(_cartas_distintas(3))
	baralho.comprar(3)
	baralho.por_na_expressao(3)
	baralho.por_na_expressao(-1)
	assert_eq(baralho.mao.size(), 3)
	assert_eq(baralho.expressao.size(), 0)


func test_descartar_expressao_poe_no_fim_do_descarte_na_ordem() -> void:
	var cartas := _cartas_distintas(4)
	var baralho := _baralho(cartas)
	baralho.compra = []
	baralho.mao = cartas.duplicate()
	baralho.descarte = []
	baralho.por_na_expressao(0)
	baralho.descartar_expressao()
	baralho.por_na_expressao(1)
	baralho.por_na_expressao(0)
	baralho.descartar_expressao()
	assert_eq(baralho.descarte, [cartas[0], cartas[2], cartas[1]])
	assert_eq(baralho.expressao, [])


func test_cartas_iguais_sao_movidas_por_posicao() -> void:
	var tres: DadosCarta = load("res://dados/cartas/numero_3.tres")
	var soma: DadosCarta = load("res://dados/cartas/soma.tres")
	var baralho := _baralho([tres, soma, tres] as Array[DadosCarta])
	baralho.compra = []
	baralho.mao = [tres, soma, tres]
	baralho.por_na_expressao(2)
	assert_eq(baralho.mao, [tres, soma])
	assert_eq(baralho.expressao, [tres])


func test_total_nao_muda_em_nenhuma_sequencia_de_operacoes() -> void:
	var baralho := _baralho(_cartas_distintas(21), 7)
	var rng := _rng(99)
	for passo in 500:
		match rng.randi_range(0, 5):
			0:
				baralho.comprar(rng.randi_range(0, 4))
			1:
				baralho.por_na_expressao(rng.randi_range(-1, baralho.mao.size()))
			2:
				baralho.desfazer()
			3:
				baralho.limpar()
			4, 5:
				baralho.descartar_expressao()
		assert_eq(baralho.total(), 21, "passo %d" % passo)


# --- comprar_com_minimo (FR-006) ---


func _carta(tipo: DadosCarta.Tipo, valor: int = 0) -> DadosCarta:
	var carta := DadosCarta.new()
	carta.tipo = tipo
	carta.valor = valor
	return carta


func _quantos(cartas: Array[DadosCarta], tipo: DadosCarta.Tipo) -> int:
	return cartas.filter(func(carta: DadosCarta) -> bool: return carta.tipo == tipo).size()


## Baralho com as zonas montadas à mão; total() fica igual à soma das zonas.
func _baralho_montado(compra: Array[DadosCarta], mao: Array[DadosCarta], descarte: Array[DadosCarta] = [], semente: int = 1) -> Baralho:
	var baralho := _baralho([], semente)
	baralho.compra = compra
	baralho.mao = mao
	baralho.descarte = descarte
	return baralho


func _mao_completa() -> Array[DadosCarta]:
	return [
		_carta(DadosCarta.Tipo.NUMERO, 1),
		_carta(DadosCarta.Tipo.NUMERO, 2),
		_carta(DadosCarta.Tipo.NUMERO, 3),
		_carta(DadosCarta.Tipo.SOMA),
		_carta(DadosCarta.Tipo.SUBTRACAO),
	]


func test_mao_inicial_sempre_tem_3_numeros_soma_e_subtracao() -> void:
	var cartas: Array[DadosCarta] = load("res://dados/baralhos/baralho_luta_avulsa.tres").cartas
	for semente in 200:
		var baralho := _baralho(cartas, semente)
		baralho.comprar_com_minimo(5, 3, 1, 1)
		assert_eq(baralho.mao.size(), 5, "semente %d" % semente)
		assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.NUMERO), 3, "semente %d" % semente)
		assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.SOMA), 1, "semente %d" % semente)
		assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.SUBTRACAO), 1, "semente %d" % semente)
		assert_eq(baralho.total(), 21)


func test_mao_com_2_cartas_recebe_so_o_que_falta() -> void:
	var compra: Array[DadosCarta] = [
		_carta(DadosCarta.Tipo.SUBTRACAO),
		_carta(DadosCarta.Tipo.SOMA),
		_carta(DadosCarta.Tipo.NUMERO, 4),
		_carta(DadosCarta.Tipo.MULTIPLICACAO),
		_carta(DadosCarta.Tipo.NUMERO, 5),
	]
	var mao: Array[DadosCarta] = [_carta(DadosCarta.Tipo.NUMERO, 1), _carta(DadosCarta.Tipo.NUMERO, 2)]
	var baralho := _baralho_montado(compra, mao)
	baralho.comprar_com_minimo(1, 3, 1, 1)
	assert_eq(baralho.mao.size(), 5)
	assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.NUMERO), 3)
	assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.SOMA), 1)
	assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.SUBTRACAO), 1)
	assert_eq(_quantos(baralho.compra, DadosCarta.Tipo.MULTIPLICACAO), 1, "o × não entra")


func test_mao_completa_recebe_exatamente_a_quantidade_do_topo() -> void:
	var compra: Array[DadosCarta] = [_carta(DadosCarta.Tipo.NUMERO, 4), _carta(DadosCarta.Tipo.DIVISAO)]
	var topo := compra[1]
	var baralho := _baralho_montado(compra, _mao_completa())
	baralho.comprar_com_minimo(1, 3, 1, 1)
	assert_eq(baralho.mao.size(), 6)
	assert_same(baralho.mao[5], topo)


func test_sem_subtracao_fora_da_mao_fica_a_melhor_mao_possivel() -> void:
	var compra: Array[DadosCarta] = []
	for valor in range(1, 6):
		compra.append(_carta(DadosCarta.Tipo.NUMERO, valor))
	compra.append(_carta(DadosCarta.Tipo.SOMA))
	compra.append(_carta(DadosCarta.Tipo.MULTIPLICACAO))
	var baralho := _baralho_montado(compra, [])
	baralho.comprar_com_minimo(5, 3, 1, 1)
	# Sem "−" para buscar, a quinta carta é a do topo (o ×).
	assert_eq(baralho.mao.size(), 5, "não compra extras que não existem")
	assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.NUMERO), 3)
	assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.SOMA), 1)
	assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.MULTIPLICACAO), 1)
	assert_eq(_quantos(baralho.mao, DadosCarta.Tipo.SUBTRACAO), 0)


func test_subtracao_mais_perto_do_topo_sai_primeiro() -> void:
	var subtracao_fundo := _carta(DadosCarta.Tipo.SUBTRACAO)
	var subtracao_topo := _carta(DadosCarta.Tipo.SUBTRACAO)
	var compra: Array[DadosCarta] = [subtracao_fundo, _carta(DadosCarta.Tipo.NUMERO, 4), subtracao_topo, _carta(DadosCarta.Tipo.NUMERO, 5)]
	var mao := _mao_completa()
	mao.pop_back()
	var baralho := _baralho_montado(compra, mao)
	baralho.comprar_com_minimo(1, 3, 1, 1)
	assert_eq(baralho.mao.size(), 5)
	assert_same(baralho.mao[4], subtracao_topo)
	assert_true(baralho.compra.any(func(carta: DadosCarta) -> bool: return is_same(carta, subtracao_fundo)))


func test_sem_subtracao_na_compra_sai_a_descartada_ha_mais_tempo() -> void:
	var subtracao_antiga := _carta(DadosCarta.Tipo.SUBTRACAO)
	var subtracao_recente := _carta(DadosCarta.Tipo.SUBTRACAO)
	var compra: Array[DadosCarta] = [_carta(DadosCarta.Tipo.NUMERO, 4)]
	var descarte: Array[DadosCarta] = [_carta(DadosCarta.Tipo.NUMERO, 5), subtracao_antiga, _carta(DadosCarta.Tipo.SOMA), subtracao_recente]
	var mao := _mao_completa()
	mao.pop_back()
	var baralho := _baralho_montado(compra, mao, descarte)
	baralho.comprar_com_minimo(1, 3, 1, 1)
	assert_eq(baralho.mao.size(), 5)
	assert_same(baralho.mao[4], subtracao_antiga)
	assert_eq(baralho.compra.size(), 1, "a compra continua com a carta dela")
	assert_eq(baralho.descarte.size(), 3)


func test_compra_vazia_refaz_a_pilha_antes_de_buscar_a_subtracao() -> void:
	var descarte: Array[DadosCarta] = [
		_carta(DadosCarta.Tipo.NUMERO, 4),
		_carta(DadosCarta.Tipo.SUBTRACAO),
		_carta(DadosCarta.Tipo.NUMERO, 5),
		_carta(DadosCarta.Tipo.SUBTRACAO),
		_carta(DadosCarta.Tipo.DIVISAO),
		_carta(DadosCarta.Tipo.SUBTRACAO),
	]
	var baralhos: Array[Baralho] = []
	for repeticao in 2:
		var mao := _mao_completa()
		mao.pop_back()
		var baralho := _baralho_montado([], mao, descarte.duplicate(), 3)
		baralho.comprar_com_minimo(1, 3, 1, 1)
		assert_eq(baralho.descarte.size(), 0, "o descarte virou a compra")
		assert_eq(baralho.compra.size(), 5)
		assert_eq(baralho.mao.size(), 5)
		assert_eq(baralho.mao[4].tipo, DadosCarta.Tipo.SUBTRACAO)
		baralhos.append(baralho)
	assert_same(baralhos[0].mao[4], baralhos[1].mao[4], "mesma semente, mesma carta")
	assert_eq(baralhos[0].compra, baralhos[1].compra, "mesma semente, mesma pilha")

	# Gêmeo com a mesma semente: comprar tudo revela a pilha refeita, do topo para o fundo.
	var gemeo := _baralho_montado([], [], descarte.duplicate(), 3)
	gemeo.comprar(descarte.size())
	var subtracao_do_topo: DadosCarta = null
	for carta in gemeo.mao:
		if carta.tipo == DadosCarta.Tipo.SUBTRACAO:
			subtracao_do_topo = carta
			break
	assert_same(baralhos[0].mao[4], subtracao_do_topo, "saiu a subtração mais perto do topo")
