extends GutTest
## A cena principal da run. A dificuldade é trocada, antes de pôr a cena na árvore, por uma
## cópia com a própria cópia das regras (o duplicate(true) não copia arquivos apontados,
## research D12), aviso de rodada curto e 1 de vida no inimigo comum do ato 1.

const CENA: PackedScene = preload("res://run/tela_run.tscn")
const DIFICULDADE: DadosDificuldade = preload("res://dados/dificuldade.tres")
const N1: DadosCarta = preload("res://dados/cartas/numero_1.tres")
const N2: DadosCarta = preload("res://dados/cartas/numero_2.tres")
const N5: DadosCarta = preload("res://dados/cartas/numero_5.tres")
const SOMA: DadosCarta = preload("res://dados/cartas/soma.tres")
const SUBTRACAO: DadosCarta = preload("res://dados/cartas/subtracao.tres")

var _tela: Control


func before_each() -> void:
	var dados := DIFICULDADE.duplicate(true) as DadosDificuldade
	dados.regras_base = dados.regras_base.duplicate()
	dados.regras_base.tempo_resultado = 0.05
	dados.atos[0].comum.vida = 1
	_tela = CENA.instantiate()
	_tela.dificuldade = dados
	add_child_autofree(_tela)


func _run() -> Run:
	return _tela.run


func _texto(no: String) -> String:
	return (_tela.get_node("%" + no) as Label).text


func _no_da_casa(casa: Casa) -> Button:
	return _tela.get_node("%Mapa/Casas").get_child(_run().mapa().casas.find(casa))


## As cenas de etapa abertas (tudo que não é fixo da cena principal).
func _cenas_de_etapa() -> Array[Node]:
	return _tela.get_children().filter(func(no: Node) -> bool: return no.name not in ["Mapa", "Barra", "ErroDados"])


func _luta() -> TelaBatalha:
	for no in _cenas_de_etapa():
		if no is TelaBatalha:
			return no
	return null


func _clicar_na_batalha_do_andar_1() -> Casa:
	var casa := _run().mapa().casas_do_andar(1)[0]
	_no_da_casa(casa).pressed.emit()
	return casa


## Mão e alvo conhecidos; clica no 5 e em Confirmar e espera o fim da luta (o inimigo tem 1 de
## vida). O Arthur fica com `vida_arthur`.
func _vencer(vida_arthur: int) -> void:
	var luta := _luta()
	luta.batalha.arthur.vida = vida_arthur
	luta.batalha.baralho.mao = [N2, SOMA, N5, N1, SUBTRACAO] as Array[DadosCarta]
	luta.batalha.alvo = 5
	luta.batalha.mudou.emit()
	(luta.get_node("%Mao").get_child(2) as Button).pressed.emit()
	(luta.get_node("%Confirmar") as Button).pressed.emit()
	await wait_for_signal(luta.luta_terminou, 1.0)


# --- História 1, cenário 1 ---

func test_ao_abrir_mostra_a_barra_e_so_o_andar_1_clicavel() -> void:
	assert_not_null(_run())
	assert_eq(_texto("Ato"), "Ato 1: Calabouço")
	assert_eq(_texto("Vida"), "Vida 40/40")
	assert_eq(_texto("Baralho"), "Baralho: 13 cartas")
	assert_true(_tela.get_node("%Barra").visible)
	assert_true(_tela.get_node("%Mapa").visible)
	assert_false(_tela.get_node("%ErroDados").visible)
	for casa in _run().mapa().casas:
		assert_eq(_no_da_casa(casa).disabled, casa.andar != 1)
	assert_eq(_cenas_de_etapa(), [] as Array[Node])


# --- Abrir a luta ---

func test_clicar_numa_batalha_abre_a_luta_e_esconde_mapa_e_barra() -> void:
	_clicar_na_batalha_do_andar_1()
	var luta := _luta()
	assert_not_null(luta)
	if luta == null:
		return
	assert_eq(luta.batalha.arthur.vida, 40)
	assert_eq(luta.batalha.inimigo.nome, "Inimigo do calabouço")
	assert_eq(luta.batalha.inimigo.vida, 1)
	assert_eq(luta.batalha.regras.alvo_maximo, 12)
	assert_false(_tela.get_node("%Barra").visible)
	assert_false(_tela.get_node("%Mapa").visible)


func test_casa_do_chefe_abre_a_luta_com_o_chefe() -> void:
	var mapa := _run().mapa()
	_run().casa_atual = mapa.casas_do_andar(mapa.total_de_andares - 1)[0]
	_tela.get_node("%Mapa").casa_escolhida.emit(mapa.casas_do_andar(mapa.total_de_andares)[0])
	assert_eq(_run().etapa, Run.Etapa.CHEFE)
	var luta := _luta()
	assert_not_null(luta)
	if luta != null:
		assert_eq(luta.batalha.inimigo.nome, "Chefe do calabouço")
		assert_eq(luta.batalha.inimigo.vida, 26)


# --- História 1, cenário 4 ---

func test_vencer_mostra_a_vitoria_com_a_vida() -> void:
	_clicar_na_batalha_do_andar_1()
	await _vencer(31)
	assert_null(_luta(), "a luta saiu da árvore")
	var abertas := _cenas_de_etapa()
	assert_eq(abertas.size(), 1)
	if abertas.size() != 1:
		return
	assert_eq(abertas[0].get_node("%Titulo").text, "Vitória!")
	assert_eq(abertas[0].get_node("%LinhaVida").text, "Vida do Arthur: 31/40")
	assert_false(_tela.get_node("%Mapa").visible)


func test_continuar_volta_ao_mapa_com_a_vida_nova_e_a_casa_visitada() -> void:
	var casa := _clicar_na_batalha_do_andar_1()
	await _vencer(31)
	(_cenas_de_etapa()[0].get_node("%Botao") as Button).pressed.emit()
	assert_eq(_cenas_de_etapa(), [] as Array[Node], "nenhuma cena de etapa ficou na árvore")
	assert_true(_tela.get_node("%Barra").visible)
	assert_true(_tela.get_node("%Mapa").visible)
	assert_eq(_texto("Vida"), "Vida 31/40")
	assert_eq(_texto("Baralho"), "Baralho: 13 cartas")
	assert_true(casa.visitada)
	assert_eq(_run().casa_atual, casa)
	for outra in _run().mapa().casas:
		assert_eq(_no_da_casa(outra).disabled, outra not in casa.ligacoes)
	await wait_process_frames(1)
