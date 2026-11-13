extends GutTest

const CENA_LUTA: PackedScene = preload("res://luta_avulsa/luta_avulsa.tscn")
const N1: DadosCarta = preload("res://dados/cartas/numero_1.tres")
const N2: DadosCarta = preload("res://dados/cartas/numero_2.tres")
const N5: DadosCarta = preload("res://dados/cartas/numero_5.tres")
const SOMA: DadosCarta = preload("res://dados/cartas/soma.tres")
const SUBTRACAO: DadosCarta = preload("res://dados/cartas/subtracao.tres")

var _luta: Control


func before_each() -> void:
	_luta = CENA_LUTA.instantiate()
	var regras: RegrasBatalha = _luta.regras.duplicate()
	regras.tempo_resultado = 0.05
	_luta.regras = regras
	add_child_autofree(_luta)


func _fim_de_luta() -> Control:
	return _luta.get_node("FimDeLuta")


## Inimigo com 1 de vida, mão e alvo conhecidos; clica no 5 e em Confirmar e espera a vitória.
func _vencer() -> void:
	var tela: TelaBatalha = _luta.tela
	tela.batalha.inimigo.vida = 1
	tela.batalha.baralho.mao = [N2, SOMA, N5, N1, SUBTRACAO] as Array[DadosCarta]
	tela.batalha.alvo = 5
	tela.batalha.mudou.emit()
	(tela.get_node("%Mao").get_child(2) as Button).pressed.emit()
	(tela.get_node("%Confirmar") as Button).pressed.emit()
	await wait_for_signal(tela.luta_terminou, 1.0)


## Arthur com 3 de vida, mão e alvo conhecidos; confirma o 2 sozinho (alvo 9) e espera a derrota.
func _perder() -> void:
	var tela: TelaBatalha = _luta.tela
	tela.batalha.arthur.vida = 3
	tela.batalha.baralho.mao = [N2, SOMA, N5, N1, SUBTRACAO] as Array[DadosCarta]
	tela.batalha.alvo = 9
	tela.batalha.mudou.emit()
	(tela.get_node("%Mao").get_child(0) as Button).pressed.emit()
	(tela.get_node("%Confirmar") as Button).pressed.emit()
	await wait_for_signal(tela.luta_terminou, 1.0)


func test_luta_comeca_ao_abrir() -> void:
	assert_not_null(_luta.tela)
	assert_true(_luta.tela.is_inside_tree())
	assert_eq(_luta.tela.batalha.rodada, 1)
	assert_eq(_luta.tela.batalha.arthur.vida, 40)
	assert_eq(_luta.tela.batalha.inimigo.vida, 12)
	assert_eq(_luta.tela.batalha.baralho.mao.size(), 5)
	assert_false(_fim_de_luta().visible)


func test_ao_vencer_aparece_o_fim_de_luta() -> void:
	var tela: TelaBatalha = _luta.tela
	await _vencer()
	assert_null(_luta.tela)
	assert_true(_fim_de_luta().visible)
	assert_eq(_fim_de_luta().get_node("%Titulo").text, "Vitória!")
	assert_eq(_fim_de_luta().get_node("%LinhaVida").text, "Vida do Arthur: 40")
	assert_eq(_fim_de_luta().get_node("%LinhaRodadas").text, "Rodadas: 1")
	await wait_physics_frames(2)
	assert_false(is_instance_valid(tela), "a tela da luta saiu")


func test_lutar_de_novo_recomeca_do_zero() -> void:
	await _vencer()
	(_fim_de_luta().get_node("%Botao") as Button).pressed.emit()
	assert_not_null(_luta.tela)
	assert_true(_luta.tela.is_inside_tree())
	assert_false(_fim_de_luta().visible)
	assert_eq(_luta.tela.batalha.rodada, 1)
	assert_eq(_luta.tela.batalha.arthur.vida, 40)
	assert_eq(_luta.tela.batalha.inimigo.vida, 12)
	assert_eq(_luta.tela.batalha.baralho.mao.size(), 5)
	assert_eq(_luta.tela.batalha.baralho.total(), 21)


func test_cena_principal_do_projeto() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://luta_avulsa/luta_avulsa.tscn")


func test_ao_perder_aparece_a_derrota() -> void:
	var tela: TelaBatalha = _luta.tela
	await _perder()
	assert_null(_luta.tela)
	assert_true(_fim_de_luta().visible)
	assert_eq(_fim_de_luta().get_node("%Titulo").text, "Derrota")
	assert_eq(_fim_de_luta().get_node("%LinhaVida").text, "Vida do inimigo: 12")
	assert_eq(_fim_de_luta().get_node("%LinhaRodadas").text, "Rodadas: 1")
	assert_eq(_fim_de_luta().get_node("%Botao").text, "Tentar de novo")
	await wait_physics_frames(2)
	assert_false(is_instance_valid(tela), "a tela da luta saiu")


func test_tentar_de_novo_recomeca_do_zero() -> void:
	await _perder()
	(_fim_de_luta().get_node("%Botao") as Button).pressed.emit()
	assert_not_null(_luta.tela)
	assert_true(_luta.tela.is_inside_tree())
	assert_false(_fim_de_luta().visible)
	assert_eq(_luta.tela.batalha.rodada, 1)
	assert_eq(_luta.tela.batalha.arthur.vida, 40)
	assert_eq(_luta.tela.batalha.inimigo.vida, 12)
	assert_eq(_luta.tela.batalha.baralho.mao.size(), 5)
	assert_eq(_luta.tela.batalha.baralho.total(), 21)
