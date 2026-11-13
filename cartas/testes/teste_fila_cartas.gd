extends GutTest

const CENA_FILA: PackedScene = preload("res://cartas/fila_cartas.tscn")
const BARALHO: DadosBaralho = preload("res://dados/baralhos/baralho_luta_avulsa.tres")
const N1: DadosCarta = preload("res://dados/cartas/numero_1.tres")
const N4: DadosCarta = preload("res://dados/cartas/numero_4.tres")
const SOMA: DadosCarta = preload("res://dados/cartas/soma.tres")
const DOBRO: DadosCarta = preload("res://dados/cartas/dobro.tres")


func _fila(cartas: Array[DadosCarta], clicavel: bool = true) -> HBoxContainer:
	var fila: HBoxContainer = CENA_FILA.instantiate()
	fila.clicavel = clicavel
	add_child_autofree(fila)
	fila.mostrar(cartas)
	return fila


func _simbolos(fila: HBoxContainer) -> Array[String]:
	var simbolos: Array[String] = []
	for carta in fila.get_children():
		simbolos.append((carta.get_node("Simbolo") as Label).text)
	return simbolos


func test_mostra_as_cartas_na_ordem() -> void:
	var fila := _fila([N4, SOMA, N1, DOBRO])
	assert_eq(_simbolos(fila), ["4", "+", "1", "x2"] as Array[String])


func test_mostrar_de_novo_troca_as_cartas() -> void:
	var fila := _fila([N4, SOMA, N1, DOBRO])
	fila.mostrar([N1] as Array[DadosCarta])
	assert_eq(_simbolos(fila), ["1"] as Array[String])
	fila.mostrar([] as Array[DadosCarta])
	assert_eq(fila.get_child_count(), 0)


func test_clicar_emite_o_indice_da_carta() -> void:
	var fila := _fila([N4, SOMA, N1, DOBRO])
	watch_signals(fila)
	fila.get_child(2).pressed.emit()
	assert_signal_emitted_with_parameters(fila, "carta_escolhida", [2])
	fila.get_child(0).pressed.emit()
	assert_signal_emitted_with_parameters(fila, "carta_escolhida", [0])
	assert_signal_emit_count(fila, "carta_escolhida", 2)


func test_indice_continua_certo_depois_de_mostrar_de_novo() -> void:
	var fila := _fila([N4, SOMA, N1, DOBRO])
	fila.mostrar([SOMA, N1] as Array[DadosCarta])
	watch_signals(fila)
	fila.get_child(1).pressed.emit()
	assert_signal_emitted_with_parameters(fila, "carta_escolhida", [1])
	assert_signal_emit_count(fila, "carta_escolhida", 1)


func test_fila_nao_clicavel_nao_emite_nada() -> void:
	var fila := _fila([N4, SOMA, N1], false)
	watch_signals(fila)
	for carta in fila.get_children():
		carta.pressed.emit()
	assert_signal_not_emitted(fila, "carta_escolhida")


func test_poucas_cartas_ficam_separadas() -> void:
	var fila := _fila([N4, SOMA, N1])
	await wait_physics_frames(2)
	assert_gt(fila.get_child(1).position.x, fila.get_child(0).position.x + 48)


func test_21_cartas_cabem_em_600_px_sobrepostas() -> void:
	var fila := _fila(BARALHO.cartas)
	await wait_physics_frames(2)
	assert_eq(fila.get_child_count(), 21)
	assert_lte(fila.get_combined_minimum_size().x, 600.0)
	var primeira: Control = fila.get_child(0)
	var ultima: Control = fila.get_child(20)
	assert_lte(ultima.position.x + ultima.size.x - primeira.position.x, 600.0)
	var passo: float = fila.get_child(1).position.x - primeira.position.x
	assert_lt(passo, 48.0, "as cartas se sobrepõem")
	assert_gte(passo, 20.0, "o canto com o símbolo continua à vista")
