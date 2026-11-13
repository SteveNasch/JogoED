extends GutTest

const CENA_TELA: PackedScene = preload("res://batalha/tela_batalha.tscn")
const BARALHO: DadosBaralho = preload("res://dados/baralhos/baralho_luta_avulsa.tres")
const INIMIGO: DadosInimigo = preload("res://dados/inimigos/inimigo_padrao.tres")
const REGRAS: RegrasBatalha = preload("res://dados/regras_batalha.tres")
const N1: DadosCarta = preload("res://dados/cartas/numero_1.tres")
const N2: DadosCarta = preload("res://dados/cartas/numero_2.tres")
const N5: DadosCarta = preload("res://dados/cartas/numero_5.tres")
const SOMA: DadosCarta = preload("res://dados/cartas/soma.tres")
const SUBTRACAO: DadosCarta = preload("res://dados/cartas/subtracao.tres")

var _tela: TelaBatalha


func before_each() -> void:
	var regras: RegrasBatalha = REGRAS.duplicate()
	regras.tempo_resultado = 0.05
	_tela = add_child_autofree(CENA_TELA.instantiate())
	_tela.iniciar(BARALHO.cartas, regras.vida_maxima_arthur, INIMIGO, regras, 1)


## Troca a mão e o alvo pela batalha e avisa a tela para redesenhar (contracts/batalha.md).
func _preparar(mao: Array[DadosCarta], alvo: int) -> void:
	_tela.batalha.baralho.mao = mao
	_tela.batalha.alvo = alvo
	_tela.batalha.mudou.emit()


func _no(nome: String) -> Node:
	return _tela.get_node("%" + nome)


func _clicar_carta_da_mao(indice: int) -> void:
	(_no("Mao").get_child(indice) as Button).pressed.emit()


func _confirmar() -> void:
	(_no("Confirmar") as Button).pressed.emit()


## Textos de todos os Label e Button visíveis na tela.
func _textos_visiveis(no: Node = _tela) -> Array[String]:
	var textos: Array[String] = []
	if (no is Label or no is Button) and (no as CanvasItem).is_visible_in_tree():
		textos.append(no.text)
	for filho in no.get_children():
		textos.append_array(_textos_visiveis(filho))
	return textos


func test_tela_mostra_o_comeco_da_luta() -> void:
	assert_eq((_no("Alvo") as Label).text, str(_tela.batalha.alvo))
	assert_eq(_no("Mao").get_child_count(), 5)
	assert_eq(_no("Expressao").get_child_count(), 0)
	assert_has(_textos_visiveis(), "Vida: 40 / 40")
	assert_has(_textos_visiveis(), "Vida: 12 / 12")
	assert_has(_textos_visiveis(), "Ataque: 3")


func test_clicar_carta_da_mao_a_move_para_a_expressao() -> void:
	_preparar([N2, SOMA, N5, N1, SUBTRACAO], 9)
	_clicar_carta_da_mao(1)
	assert_eq(_tela.batalha.baralho.expressao, [SOMA])
	assert_eq(_no("Mao").get_child_count(), 4)
	assert_eq(_no("Expressao").get_child_count(), 1)
	assert_eq((_no("Expressao").get_child(0).get_node("Simbolo") as Label).text, "+")


func test_clicar_carta_toca_o_som_da_carta() -> void:
	var tocador: AudioStreamPlayer = _no("Sons").get_node("Carta")
	tocador.stream = AudioStreamWAV.new()
	_clicar_carta_da_mao(0)
	assert_true(tocador.playing)


func test_confirmar_desabilitado_com_a_expressao_vazia() -> void:
	var confirmar: Button = _no("Confirmar")
	assert_true(confirmar.disabled)
	_clicar_carta_da_mao(0)
	assert_false(confirmar.disabled)


func test_valor_da_conta_em_montagem_nao_aparece() -> void:
	# FR-010: 2 + 5 dá 7, que não pode aparecer em lugar nenhum antes de confirmar.
	_preparar([N2, SOMA, N5, N1, SUBTRACAO], 9)
	_clicar_carta_da_mao(0)
	_clicar_carta_da_mao(0)
	_clicar_carta_da_mao(0)
	assert_eq(_tela.batalha.baralho.expressao, [N2, SOMA, N5])
	assert_false((_no("Aviso") as Label).visible)
	for texto in _textos_visiveis():
		assert_false("7" in texto, "texto visível: \"%s\"" % texto)


func test_aviso_aparece_logo_depois_de_confirmar() -> void:
	# SC-005: sem esperar nenhum quadro nem o Timer.
	_preparar([N2, SOMA, N5, N1, SUBTRACAO], 9)
	_clicar_carta_da_mao(1)
	_confirmar()
	var aviso: Label = _no("Aviso")
	assert_true(aviso.visible)
	assert_eq(aviso.text, "Conta inválida. O alvo era 9.\nO inimigo tirou 3 de vida.")
	assert_has(_textos_visiveis(), "Vida: 37 / 40")


func test_acoes_desligadas_durante_o_aviso() -> void:
	_preparar([N2, SOMA, N5, N1, SUBTRACAO], 9)
	_clicar_carta_da_mao(0)
	_confirmar()
	var mao := _tela.batalha.baralho.mao.duplicate()
	assert_true((_no("Confirmar") as Button).disabled)
	assert_false(_no("Mao").clicavel)
	_clicar_carta_da_mao(0)
	_confirmar()
	assert_eq(_tela.batalha.baralho.mao, mao)
	assert_eq(_tela.batalha.baralho.expressao.size(), 0)
	assert_eq(_tela.batalha.estado, Batalha.Estado.MOSTRANDO_RESULTADO)


func test_rodada_seguinte_aparece_sozinha_depois_do_aviso() -> void:
	_preparar([N2, SOMA, N5, N1, SUBTRACAO], 9)
	_clicar_carta_da_mao(0)
	_confirmar()
	await wait_for_signal(_tela.batalha.mudou, 1.0)
	assert_eq(_tela.batalha.rodada, 2)
	assert_eq(_tela.batalha.estado, Batalha.Estado.MONTANDO)
	assert_false((_no("Aviso") as Label).visible)
	assert_true(_no("Mao").clicavel)
	assert_eq(_no("Mao").get_child_count(), _tela.batalha.baralho.mao.size())
	assert_eq((_no("Alvo") as Label).text, str(_tela.batalha.alvo))


func test_repassa_luta_terminou_ao_vencer() -> void:
	_tela.batalha.inimigo.vida = 1
	_preparar([N2, SOMA, N5, N1, SUBTRACAO], 5)
	watch_signals(_tela)
	_clicar_carta_da_mao(2)
	_confirmar()
	assert_signal_not_emitted(_tela, "luta_terminou")
	await wait_for_signal(_tela.luta_terminou, 1.0)
	assert_signal_emit_count(_tela, "luta_terminou", 1)
	var resultado: ResultadoLuta = get_signal_parameters(_tela, "luta_terminou")[0]
	assert_true(resultado.venceu)
	assert_eq(resultado.vida_arthur, 40)
