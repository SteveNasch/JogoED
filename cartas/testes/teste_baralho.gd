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
