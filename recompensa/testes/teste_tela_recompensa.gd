extends GutTest
## Tela da recompensa (FR-021): as cartas da oferta com os textos da carta.tscn da 001, a
## escolha de uma carta, o "Não pegar nenhuma" e a oferta vazia.

const CENA: PackedScene = preload("res://recompensa/tela_recompensa.tscn")
const N6: DadosCarta = preload("res://dados/cartas/numero_6.tres")
const MULTIPLICACAO: DadosCarta = preload("res://dados/cartas/multiplicacao.tres")
const CHAMA: DadosCarta = preload("res://dados/cartas/chama.tres")

var _recompensa: Control


func before_each() -> void:
	_recompensa = add_child_autofree(CENA.instantiate())


func _texto(no: String) -> String:
	return _recompensa.get_node("%" + no).text


func _cartas() -> Array[Node]:
	return _recompensa.get_node("%Cartas").get_children()


func test_oferta_de_3_mostra_as_3_cartas_com_os_textos_da_carta() -> void:
	_recompensa.mostrar([N6, MULTIPLICACAO, CHAMA] as Array[DadosCarta])
	assert_eq(_texto("Titulo"), "Escolha uma carta para o baralho")
	assert_eq(_texto("Botao"), "Não pegar nenhuma")
	assert_true(_recompensa.get_node("%Cartas").visible)
	var cartas := _cartas()
	assert_eq(cartas.size(), 3)
	if cartas.size() != 3:
		return
	var esperadas: Array[DadosCarta] = [N6, MULTIPLICACAO, CHAMA]
	for i in 3:
		assert_eq(cartas[i].get_node("Simbolo").text, esperadas[i].simbolo())
		assert_eq(cartas[i].get_node("Ataque").text, str(esperadas[i].ataque))
	assert_eq(cartas[0].get_node("Simbolo").text, "6")
	assert_eq(cartas[2].get_node("Nome").text, CHAMA.nome)
	assert_eq(cartas[2].get_node("Efeito").text, CHAMA.texto_efeito())
	assert_string_contains((cartas[2] as Button).tooltip_text, CHAMA.nome)


func test_clicar_na_segunda_carta_emite_carta_escolhida_com_ela() -> void:
	_recompensa.mostrar([N6, MULTIPLICACAO, CHAMA] as Array[DadosCarta])
	watch_signals(_recompensa)
	(_cartas()[1] as Button).pressed.emit()
	assert_signal_emit_count(_recompensa, "carta_escolhida", 1)
	assert_signal_emitted_with_parameters(_recompensa, "carta_escolhida", [MULTIPLICACAO])
	assert_signal_not_emitted(_recompensa, "nenhuma_escolhida")


func test_botao_emite_nenhuma_escolhida() -> void:
	_recompensa.mostrar([N6, MULTIPLICACAO, CHAMA] as Array[DadosCarta])
	watch_signals(_recompensa)
	(_recompensa.get_node("%Botao") as Button).pressed.emit()
	assert_signal_emit_count(_recompensa, "nenhuma_escolhida", 1)
	assert_signal_not_emitted(_recompensa, "carta_escolhida")


func test_oferta_de_2_mostra_2_cartas() -> void:
	_recompensa.mostrar([N6, CHAMA] as Array[DadosCarta])
	assert_eq(_cartas().size(), 2)


func test_oferta_vazia_troca_os_textos_e_esconde_a_fileira() -> void:
	_recompensa.mostrar([] as Array[DadosCarta])
	assert_eq(_texto("Titulo"), "Não há cartas para escolher.")
	assert_eq(_texto("Botao"), "Continuar")
	assert_false(_recompensa.get_node("%Cartas").visible)
	assert_eq(_cartas().size(), 0)
	watch_signals(_recompensa)
	(_recompensa.get_node("%Botao") as Button).pressed.emit()
	assert_signal_emit_count(_recompensa, "nenhuma_escolhida", 1)


func test_segundo_mostrar_nao_deixa_cartas_sobrando() -> void:
	_recompensa.mostrar([N6, MULTIPLICACAO, CHAMA] as Array[DadosCarta])
	_recompensa.mostrar([CHAMA] as Array[DadosCarta])
	assert_eq(_cartas().size(), 1)
	assert_eq(_cartas()[0].get_node("Simbolo").text, CHAMA.simbolo())
	await wait_process_frames(1)
