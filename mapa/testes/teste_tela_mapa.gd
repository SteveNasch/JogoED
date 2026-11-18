extends GutTest
## A tela do mapa: posições do contrato, casas clicáveis, clique repassado e os limites de
## DadosMapa que cabem na tela (FR-028).

const CENA: PackedScene = preload("res://mapa/tela_mapa.tscn")
const LARGURA_DA_TELA := 640.0
const TAMANHO_DA_CASA := 32.0

var tela: TelaMapa


func before_each() -> void:
	tela = add_child_autofree(CENA.instantiate())


func _mapa(semente: int) -> MapaAto:
	return GeradorMapa.gerar(DadosMapa.new(), semente)


## As casas na tela, na ordem de mapa.casas.
func _nos_das_casas() -> Array[Node]:
	return tela.get_node("Casas").get_children()


func test_posicoes_do_contrato_com_5_andares() -> void:
	assert_eq(TelaMapa.posicao_da_casa(1, 0, 3, 5), Vector2(224, 312))
	assert_eq(TelaMapa.posicao_da_casa(1, 1, 3, 5), Vector2(320, 312))
	assert_eq(TelaMapa.posicao_da_casa(1, 2, 3, 5), Vector2(416, 312))
	assert_eq(TelaMapa.posicao_da_casa(2, 0, 2, 5), Vector2(272, 246))
	assert_eq(TelaMapa.posicao_da_casa(2, 1, 2, 5), Vector2(368, 246))
	assert_eq(TelaMapa.posicao_da_casa(3, 0, 3, 5).y, 180.0)
	assert_eq(TelaMapa.posicao_da_casa(4, 0, 3, 5).y, 114.0)
	assert_eq(TelaMapa.posicao_da_casa(5, 0, 1, 5), Vector2(320, 48))


func test_x_cresce_com_o_indice_em_todo_andar() -> void:
	# É o que faz "sem cruzamento nos dados" virar "sem cruzamento na tela" (FR-010).
	for i in 200:
		var mapa := _mapa(hash(i))
		for andar in range(1, mapa.total_de_andares + 1):
			var casas := mapa.casas_do_andar(andar)
			for posicao in range(1, casas.size()):
				var antes := TelaMapa.posicao_da_casa(andar, casas[posicao - 1].indice, casas.size(), mapa.total_de_andares)
				var depois := TelaMapa.posicao_da_casa(andar, casas[posicao].indice, casas.size(), mapa.total_de_andares)
				assert_lt(antes.x, depois.x, "semente hash(%d), andar %d" % [i, andar])


func test_cada_casa_fica_centrada_na_posicao_calculada() -> void:
	var mapa := _mapa(7)
	tela.mostrar(mapa, null)
	var nos := _nos_das_casas()
	assert_eq(nos.size(), mapa.casas.size())
	for i in mapa.casas.size():
		var casa := mapa.casas[i]
		var centro := TelaMapa.posicao_da_casa(casa.andar, casa.indice, mapa.casas_do_andar(casa.andar).size(), mapa.total_de_andares)
		assert_eq((nos[i] as Control).position + Vector2(16, 16), centro)
		assert_eq((nos[i].get_node("Letra") as Label).text, nos[i].LETRAS[casa.tipo])


func test_sem_casa_atual_so_o_andar_1_e_clicavel() -> void:
	var mapa := _mapa(7)
	tela.mostrar(mapa, null)
	var nos := _nos_das_casas()
	for i in mapa.casas.size():
		assert_eq((nos[i] as Button).disabled, mapa.casas[i].andar != 1, "casa %d" % i)


func test_com_casa_atual_so_as_ligacoes_dela_sao_clicaveis() -> void:
	var mapa := _mapa(7)
	var atual := mapa.casas_do_andar(2)[0]
	tela.mostrar(mapa, atual)
	var nos := _nos_das_casas()
	for i in mapa.casas.size():
		assert_eq((nos[i] as Button).disabled, mapa.casas[i] not in atual.ligacoes, "casa %d" % i)


func test_clicar_numa_disponivel_emite_casa_escolhida_com_ela() -> void:
	var mapa := _mapa(7)
	tela.mostrar(mapa, null)
	watch_signals(tela)
	var casa := mapa.casas_do_andar(1)[1]
	(_nos_das_casas()[mapa.casas.find(casa)] as Button).pressed.emit()
	assert_signal_emit_count(tela, "casa_escolhida", 1)
	assert_signal_emitted_with_parameters(tela, "casa_escolhida", [casa])


func test_casa_nao_disponivel_fica_desabilitada() -> void:
	# Um Button desabilitado não emite pressed, então o clique não chega a casa_escolhida.
	var mapa := _mapa(7)
	tela.mostrar(mapa, null)
	var chefe := mapa.casas_do_andar(mapa.total_de_andares)[0]
	assert_true((_nos_das_casas()[mapa.casas.find(chefe)] as Button).disabled)


func test_segundo_mostrar_nao_deixa_casas_sobrando() -> void:
	var mapa := _mapa(7)
	tela.mostrar(_mapa(8), null)
	tela.mostrar(mapa, mapa.casas_do_andar(1)[0])
	assert_eq(_nos_das_casas().size(), mapa.casas.size())
	watch_signals(tela)
	var ligada := mapa.casas_do_andar(1)[0].ligacoes[0]
	(_nos_das_casas()[mapa.casas.find(ligada)] as Button).pressed.emit()
	assert_signal_emitted_with_parameters(tela, "casa_escolhida", [ligada])
	# As casas antigas saem da árvore na hora e são liberadas no fim do quadro.
	await wait_process_frames(1)


## As casas das pontas de um andar com `casas` casas ficam inteiras entre x = 0 e x = 640.
func _andar_cabe(casas: int) -> bool:
	var esquerda := TelaMapa.posicao_da_casa(1, 0, casas, 5).x - TAMANHO_DA_CASA / 2
	var direita := TelaMapa.posicao_da_casa(1, casas - 1, casas, 5).x + TAMANHO_DA_CASA / 2
	return esquerda >= 0 and direita <= LARGURA_DA_TELA


## Andares vizinhos ficam a pelo menos uma casa de distância, com `comuns` andares comuns.
func _andares_cabem(comuns: int) -> bool:
	var total := comuns + 1
	for andar in range(1, total):
		var distancia := TelaMapa.posicao_da_casa(andar, 0, 1, total).y - TelaMapa.posicao_da_casa(andar + 1, 0, 1, total).y
		if distancia < TAMANHO_DA_CASA:
			return false
	return true


func test_maximo_de_casas_por_andar_cabe_na_tela_e_um_a_mais_nao() -> void:
	assert_true(_andar_cabe(DadosMapa.MAXIMO_CASAS_POR_ANDAR))
	assert_false(_andar_cabe(DadosMapa.MAXIMO_CASAS_POR_ANDAR + 1))


func test_maximo_de_andares_comuns_cabe_na_tela_e_um_a_mais_nao() -> void:
	assert_true(_andares_cabem(DadosMapa.MAXIMO_ANDARES_COMUNS))
	assert_false(_andares_cabem(DadosMapa.MAXIMO_ANDARES_COMUNS + 1))


# --- Ligações e marcador (T022) ---

## Mapa montado à mão: 3 batalhas, descanso e recompensa no andar 2, chefe no andar 3. O Arthur
## passou pela batalha do meio e está no descanso.
##
##        chefe
##       /     \
##   descanso  recompensa
##    /   \     /   \
##   b0    b1       b2
func _mapa_percorrido() -> MapaAto:
	var mapa := MapaAto.new()
	mapa.total_de_andares = 3
	for indice in 3:
		mapa.casas.append(Casa.new(Casa.Tipo.BATALHA, 1, indice))
	mapa.casas.append(Casa.new(Casa.Tipo.DESCANSO, 2, 0))
	mapa.casas.append(Casa.new(Casa.Tipo.RECOMPENSA, 2, 1))
	mapa.casas.append(Casa.new(Casa.Tipo.CHEFE, 3, 0))
	var c := mapa.casas
	c[0].ligacoes.assign([c[3]])
	c[1].ligacoes.assign([c[3], c[4]])
	c[2].ligacoes.assign([c[4]])
	c[3].ligacoes.assign([c[5]])
	c[4].ligacoes.assign([c[5]])
	c[1].visitada = true
	c[3].visitada = true
	return mapa


func test_cor_de_cada_tipo_de_ligacao() -> void:
	var mapa := _mapa_percorrido()
	var c := mapa.casas
	var atual := c[3]
	assert_eq(TelaMapa.cor_da_ligacao(c[1], c[3], atual), Color(0.95, 0.95, 0.95), "percorrida")
	assert_eq(TelaMapa.cor_da_ligacao(c[3], c[5], atual), Color(0.95, 0.8, 0.3), "da atual para uma disponível")
	assert_eq(TelaMapa.cor_da_ligacao(c[0], c[3], atual), Color(0.45, 0.45, 0.45), "de casa não visitada")
	assert_eq(TelaMapa.cor_da_ligacao(c[1], c[4], atual), Color(0.45, 0.45, 0.45), "para casa não visitada")
	assert_eq(TelaMapa.cor_da_ligacao(c[4], c[5], atual), Color(0.45, 0.45, 0.45), "de outra casa do andar")


func test_antes_do_andar_1_todas_as_ligacoes_sao_comuns() -> void:
	var mapa := _mapa(7)
	for casa in mapa.casas:
		for outra in casa.ligacoes:
			assert_eq(TelaMapa.cor_da_ligacao(casa, outra, null), Color(0.45, 0.45, 0.45))


func test_marcador_antes_do_andar_1_fica_centrado_em_320_344() -> void:
	tela.mostrar(_mapa(7), null)
	var marcador := tela.get_node("Marcador") as ColorRect
	assert_eq(marcador.position + marcador.size / 2, Vector2(320, 344))


func test_marcador_fica_no_canto_de_cima_e_da_esquerda_da_casa_atual() -> void:
	var mapa := _mapa_percorrido()
	var atual := mapa.casas[3]
	tela.mostrar(mapa, atual)
	var marcador := tela.get_node("Marcador") as ColorRect
	var no_da_casa := _nos_das_casas()[3] as Control
	assert_eq(marcador.position, no_da_casa.position)


func test_marcador_e_o_placeholder_do_asset_28() -> void:
	var marcador := tela.get_node("Marcador") as ColorRect
	assert_eq(marcador.size, Vector2(8, 8))
	assert_eq(marcador.color, Color(0.25, 0.4, 0.8))
	assert_eq(marcador.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_marcador_fica_por_cima_das_casas() -> void:
	assert_gt(tela.get_node("Marcador").get_index(), tela.get_node("Casas").get_index())
