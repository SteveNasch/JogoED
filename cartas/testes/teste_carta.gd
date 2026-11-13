extends GutTest

const CENA_CARTA: PackedScene = preload("res://cartas/carta.tscn")


func _carta(caminho_dados: String) -> Button:
	var carta: Button = add_child_autofree(CENA_CARTA.instantiate())
	carta.mostrar(load(caminho_dados))
	return carta


func _texto(carta: Button, no: String) -> String:
	return (carta.get_node(no) as Label).text


func test_carta_de_numero_mostra_o_valor_e_o_ataque() -> void:
	var carta := _carta("res://dados/cartas/numero_3.tres")
	assert_eq(_texto(carta, "Simbolo"), "3")
	assert_eq(_texto(carta, "Ataque"), "3")
	assert_eq(_texto(carta, "Nome"), "")
	assert_eq(_texto(carta, "Efeito"), "")


func test_carta_de_operador_mostra_o_simbolo_e_o_ataque() -> void:
	var carta := _carta("res://dados/cartas/quadrado.tres")
	assert_eq(_texto(carta, "Simbolo"), "^2")
	assert_eq(_texto(carta, "Ataque"), "4")
	assert_eq(_texto(carta, "Nome"), "")
	assert_eq(_texto(carta, "Efeito"), "")


func test_carta_especial_mostra_nome_e_efeito() -> void:
	var carta := _carta("res://dados/cartas/chama.tres")
	assert_eq(_texto(carta, "Simbolo"), "5")
	assert_eq(_texto(carta, "Ataque"), "5")
	assert_eq(_texto(carta, "Nome"), "Chama")
	assert_eq(_texto(carta, "Efeito"), "+3 de dano")


func test_dica_da_chama_segue_o_contrato() -> void:
	var carta := _carta("res://dados/cartas/chama.tres")
	assert_eq(carta.tooltip_text, "Chama: +3 de dano. Só vale quando a conta acerta o alvo.")


func test_dica_das_outras_especiais_usa_os_mesmos_textos() -> void:
	assert_eq(_carta("res://dados/cartas/guarda.tres").tooltip_text, "Guarda: +5 de escudo. Só vale quando a conta acerta o alvo.")
	assert_eq(_carta("res://dados/cartas/foco.tres").tooltip_text, "Foco: compra 1. Só vale quando a conta acerta o alvo.")


func test_cartas_sem_efeito_nao_tem_dica() -> void:
	assert_eq(_carta("res://dados/cartas/numero_5.tres").tooltip_text, "")
	assert_eq(_carta("res://dados/cartas/soma.tres").tooltip_text, "")


func test_mostrar_de_novo_troca_os_textos_e_apaga_a_dica() -> void:
	var carta := _carta("res://dados/cartas/vital.tres")
	carta.mostrar(load("res://dados/cartas/divisao.tres"))
	assert_eq(_texto(carta, "Simbolo"), "÷")
	assert_eq(_texto(carta, "Nome"), "")
	assert_eq(carta.tooltip_text, "")


func test_pressionar_emite_clicada() -> void:
	var carta := _carta("res://dados/cartas/numero_1.tres")
	watch_signals(carta)
	carta.pressed.emit()
	assert_signal_emit_count(carta, "clicada", 1)
