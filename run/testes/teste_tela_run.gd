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


# --- História 1, cenário 4 (e história 3, cenário 6: batalha vencida volta direto ao mapa) ---

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


# --- História 2: derrota e recomeço ---

## Pula a rodada e espera o fim da luta (com 1 de vida, o ataque do inimigo derruba o Arthur).
func _perder_pelo_pular() -> void:
	var luta := _luta()
	(luta.get_node("%Pular") as Button).pressed.emit()
	await wait_for_signal(luta.luta_terminou, 1.0)


func _botao_da_cena_aberta() -> Button:
	return _cenas_de_etapa()[0].get_node("%Botao")


func test_perder_mostra_o_fim_da_run_sem_o_aviso_de_vitoria() -> void:
	_run().vida_arthur = 1
	_clicar_na_batalha_do_andar_1()
	await _perder_pelo_pular()
	assert_eq(_run().etapa, Run.Etapa.DERROTA)
	var abertas := _cenas_de_etapa()
	assert_eq(abertas.size(), 1, "só o fim de run, sem a luta nem o aviso de vitória")
	if abertas.size() != 1:
		return
	assert_eq(abertas[0].get_node("%Titulo").text, "Fim da run")
	assert_eq(abertas[0].get_node("%Onde").text, "Arthur caiu no ato 1 (Calabouço), andar 1.")
	assert_eq(abertas[0].get_node("%Lutas").text, "Lutas vencidas: 0")
	assert_false(_tela.get_node("%Mapa").visible)
	assert_false(_tela.get_node("%Barra").visible)


func test_comecar_de_novo_cria_uma_run_nova_no_ato_1() -> void:
	var antiga := _run()
	antiga.baralho.append(preload("res://dados/cartas/chama.tres"))
	antiga.vida_arthur = 1
	_clicar_na_batalha_do_andar_1()
	await _perder_pelo_pular()
	_botao_da_cena_aberta().pressed.emit()
	assert_eq(_cenas_de_etapa(), [] as Array[Node], "nenhuma cena de etapa ficou na árvore")
	assert_ne(_run(), antiga, "a run é outro objeto")
	assert_ne(_run().semente, antiga.semente)
	assert_eq(_run().etapa, Run.Etapa.MAPA)
	assert_eq(_texto("Ato"), "Ato 1: Calabouço")
	assert_eq(_texto("Vida"), "Vida 40/40")
	assert_eq(_texto("Baralho"), "Baralho: 13 cartas")
	assert_true(_tela.get_node("%Mapa").visible)
	for casa in _run().mapa().casas:
		assert_eq(_no_da_casa(casa).disabled, casa.andar != 1)
	await wait_process_frames(1)


# --- História 4, cenário 4: vitória da run ---

func test_vencer_o_chefe_da_torre_mostra_o_aviso_e_depois_a_vitoria_da_run() -> void:
	_run().ato = 3
	var mapa := _run().mapa()
	_run().casa_atual = mapa.casas_do_andar(mapa.total_de_andares - 1)[0]
	_run().lutas_vencidas = 13
	_tela.get_node("%Mapa").casa_escolhida.emit(mapa.casas_do_andar(mapa.total_de_andares)[0])
	_luta().batalha.inimigo.vida = 1
	await _vencer(20)
	assert_eq(_run().etapa, Run.Etapa.VITORIA)
	assert_eq(_cenas_de_etapa()[0].get_node("%LinhaVida").text, "Vida do Arthur: 20/40")
	_botao_da_cena_aberta().pressed.emit()
	var abertas := _cenas_de_etapa()
	assert_eq(abertas.size(), 1)
	if abertas.size() != 1:
		return
	assert_eq(abertas[0].get_node("%Titulo").text, "Vitória!")
	assert_eq(abertas[0].get_node("%Onde").text, "Arthur venceu o chefe do ato 3 (Torre), andar 5.")
	assert_eq(abertas[0].get_node("%Lutas").text, "Lutas vencidas: 14")
	await wait_process_frames(1)


# --- História 3, cenário 1: descanso ---

## Uma casa do tipo pedido do andar 2 em diante, com a run posicionada na casa anterior ligada a
## ela (null se o mapa não tem).
func _posicionar_antes_de(tipo: Casa.Tipo) -> Casa:
	var mapa := _run().mapa()
	for andar in range(2, mapa.total_de_andares):
		for casa in mapa.casas_do_andar(andar):
			if casa.tipo != tipo:
				continue
			for anterior in mapa.casas_do_andar(andar - 1):
				if casa in anterior.ligacoes:
					_run().casa_atual = anterior
					anterior.visitada = true
					return casa
	return null


func test_descanso_mostra_a_cura_e_volta_ao_mapa_com_a_vida_nova() -> void:
	var descanso := _posicionar_antes_de(Casa.Tipo.DESCANSO)
	assert_not_null(descanso, "todo mapa padrão tem descanso")
	if descanso == null:
		return
	_run().vida_arthur = 20
	_tela.get_node("%Mapa").casa_escolhida.emit(descanso)
	var abertas := _cenas_de_etapa()
	assert_eq(abertas.size(), 1)
	if abertas.size() != 1:
		return
	assert_eq(abertas[0].get_node("%Frase").text, "Arthur descansou e recuperou 12 de vida.")
	assert_eq(abertas[0].get_node("%Vida").text, "Vida: 32/40")
	assert_false(_tela.get_node("%Mapa").visible)
	_botao_da_cena_aberta().pressed.emit()
	assert_eq(_cenas_de_etapa(), [] as Array[Node], "nenhuma cena de etapa ficou na árvore")
	assert_eq(_run().etapa, Run.Etapa.MAPA)
	assert_true(_tela.get_node("%Mapa").visible)
	assert_eq(_texto("Vida"), "Vida 32/40")
	for casa in _run().mapa().casas:
		assert_eq(_no_da_casa(casa).disabled, casa not in descanso.ligacoes)
	await wait_process_frames(1)


# --- História 3, cenários 2 a 5, e história 4, cenário 1: recompensa ---

func _cartas_da_recompensa() -> Array[Node]:
	return _cenas_de_etapa()[0].get_node("%Cartas").get_children()


func _entrar_na_recompensa() -> Casa:
	var casa := _posicionar_antes_de(Casa.Tipo.RECOMPENSA)
	assert_not_null(casa, "todo mapa padrão tem recompensa")
	if casa != null:
		_tela.get_node("%Mapa").casa_escolhida.emit(casa)
	return casa


func test_casa_de_recompensa_mostra_3_cartas_e_escolher_uma_aumenta_o_baralho() -> void:
	if _entrar_na_recompensa() == null:
		return
	assert_eq(_cartas_da_recompensa().size(), 3)
	assert_false(_tela.get_node("%Mapa").visible)
	var segunda: DadosCarta = _run().oferta[1]
	(_cartas_da_recompensa()[1] as Button).pressed.emit()
	assert_eq(_cenas_de_etapa(), [] as Array[Node], "nenhuma cena de etapa ficou na árvore")
	assert_eq(_texto("Baralho"), "Baralho: 14 cartas")
	assert_eq(_run().baralho.back(), segunda)
	assert_true(_tela.get_node("%Mapa").visible)
	await wait_process_frames(1)


func test_nao_pegar_nenhuma_mantem_o_baralho() -> void:
	if _entrar_na_recompensa() == null:
		return
	_botao_da_cena_aberta().pressed.emit()
	assert_eq(_run().etapa, Run.Etapa.MAPA)
	assert_eq(_texto("Baralho"), "Baralho: 13 cartas")
	assert_true(_tela.get_node("%Mapa").visible)
	await wait_process_frames(1)


func test_elite_vencida_abre_a_recompensa_depois_do_aviso() -> void:
	var elite := _posicionar_antes_de(Casa.Tipo.ELITE)
	assert_not_null(elite, "todo mapa padrão tem elite")
	if elite == null:
		return
	_tela.get_node("%Mapa").casa_escolhida.emit(elite)
	_luta().batalha.inimigo.vida = 1
	await _vencer(25)
	assert_eq(_cenas_de_etapa()[0].get_node("%Titulo").text, "Vitória!")
	_botao_da_cena_aberta().pressed.emit()
	assert_eq(_cenas_de_etapa().size(), 1)
	assert_eq(_cartas_da_recompensa().size(), 3)
	_botao_da_cena_aberta().pressed.emit()
	assert_eq(_run().etapa, Run.Etapa.MAPA)
	assert_eq(_texto("Vida"), "Vida 25/40")
	await wait_process_frames(1)


func test_chefe_do_ato_1_vencido_abre_a_recompensa_e_depois_o_ato_2() -> void:
	var mapa := _run().mapa()
	_run().casa_atual = mapa.casas_do_andar(mapa.total_de_andares - 1)[0]
	_run().baralho.append(preload("res://dados/cartas/chama.tres"))
	_run().baralho.append(preload("res://dados/cartas/foco.tres"))
	_tela.get_node("%Mapa").casa_escolhida.emit(mapa.casas_do_andar(mapa.total_de_andares)[0])
	_luta().batalha.inimigo.vida = 1
	await _vencer(18)
	_botao_da_cena_aberta().pressed.emit()
	assert_eq(_cartas_da_recompensa().size(), 3, "o chefe do ato 1 abre a recompensa")
	_botao_da_cena_aberta().pressed.emit()
	assert_eq(_cenas_de_etapa(), [] as Array[Node], "nenhuma cena de etapa ficou na árvore")
	assert_eq(_run().ato, 2)
	assert_eq(_texto("Ato"), "Ato 2: Salões")
	assert_eq(_texto("Vida"), "Vida 18/40")
	assert_eq(_texto("Baralho"), "Baralho: 15 cartas")
	assert_true(_tela.get_node("%Mapa").visible)
	for casa in _run().mapa().casas:
		assert_eq(_no_da_casa(casa).disabled, casa.andar != 1)
	await wait_process_frames(1)


# --- História 4, cenário 5: dados errados ---

func test_dados_errados_nao_comecam_a_run_e_mostram_o_valor_errado() -> void:
	var dados := DIFICULDADE.duplicate(true) as DadosDificuldade
	dados.atos[0].alvo_minimo = 13
	var tela: Control = CENA.instantiate()
	tela.dificuldade = dados
	add_child_autofree(tela)
	var frase := "Ato 1 (Calabouço): alvo_minimo (13) é maior que alvo_maximo (12)."
	assert_push_error(frase)
	assert_null(tela.run)
	assert_false(tela.get_node("%Mapa").visible)
	assert_false(tela.get_node("%Barra").visible)
	var erro := tela.get_node("%ErroDados") as Label
	assert_true(erro.visible)
	assert_eq(erro.text, "O arquivo de dificuldade tem valores errados. A run não começou.\n- " + frase)
	assert_eq(DIFICULDADE.atos[0].alvo_minimo, 5, "o arquivo carregado não mudou")


# --- FR-001: o jogo abre na run ---

func test_cena_principal_do_projeto() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://run/tela_run.tscn")
