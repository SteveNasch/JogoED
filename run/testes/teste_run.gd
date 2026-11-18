extends GutTest
## A Run transição por transição, com dados/dificuldade.tres. Os cenários montam a run pelos
## campos públicos (por exemplo, casa_atual numa casa do andar anterior e etapa MAPA, como se
## a luta dela tivesse sido vencida).

const DIFICULDADE: DadosDificuldade = preload("res://dados/dificuldade.tres")
const SEMENTE := 1234

var run: Run


func before_each() -> void:
	run = Run.new(DIFICULDADE, SEMENTE)


## Põe o Arthur em `casa` com a run no mapa, como depois de vencer a luta dela.
func _posicionar(casa: Casa) -> void:
	run.casa_atual = casa
	casa.visitada = true
	run.etapa = Run.Etapa.MAPA


## Uma casa do tipo pedido no andar pedido e uma casa do andar anterior ligada a ela (null se
## o andar é o 1), ou [] se o mapa sorteado não tem.
func _casa_e_anterior(tipo: Casa.Tipo, andar: int) -> Array:
	for casa in run.mapa().casas_do_andar(andar):
		if casa.tipo != tipo:
			continue
		if andar == 1:
			return [casa, null]
		for anterior in run.mapa().casas_do_andar(andar - 1):
			if casa in anterior.ligacoes:
				return [casa, anterior]
	return []


## O que muda numa escolha de casa, para conferir que nada mudou.
func _estado() -> Array:
	var visitadas: Array = []
	for mapa_ato in run.mapas:
		visitadas.append(mapa_ato.casas.map(func(casa: Casa) -> bool: return casa.visitada))
	return [run.etapa, run.casa_atual, run.ato, run.vida_arthur, run.semente_da_luta, run.baralho.duplicate(), visitadas]


func _descricao_dos_mapas(alvo: Run) -> Array:
	var descricao: Array = []
	for mapa_ato in alvo.mapas:
		for casa in mapa_ato.casas:
			descricao.append([casa.andar, casa.indice, casa.tipo, casa.ligacoes.map(func(outra: Casa) -> int: return outra.indice)])
	return descricao


# --- História 1, cenário 1 ---

func test_run_nova_comeca_no_ato_1_com_vida_cheia_e_baralho_inicial() -> void:
	assert_eq(run.ato, 1)
	assert_eq(run.dados_do_ato().nome, "Calabouço")
	assert_eq(run.vida_arthur, 40)
	assert_eq(run.vida_maxima, 40)
	assert_eq(run.baralho, DIFICULDADE.baralho_inicial)
	assert_eq(run.baralho.size(), 13)
	assert_eq(run.etapa, Run.Etapa.MAPA)
	assert_null(run.casa_atual)
	assert_eq(run.andar_alcancado(), 0)
	assert_eq(run.lutas_vencidas, 0)
	assert_false(run.ultimo_ato())


func test_run_nova_tem_um_mapa_por_ato() -> void:
	assert_eq(run.mapas.size(), 3)
	for i in run.mapas.size():
		assert_eq(run.mapas[i].total_de_andares, DIFICULDADE.atos[i].mapa.andares_comuns + 1)
	assert_eq(run.mapa(), run.mapas[0])


func test_so_o_andar_1_esta_disponivel_no_comeco() -> void:
	var disponiveis := run.casas_disponiveis()
	assert_eq(disponiveis, run.mapa().casas_do_andar(1))
	assert_gt(disponiveis.size(), 1)


# --- História 1, cenário 2 ---

func test_casa_de_outro_andar_no_comeco_nao_vale() -> void:
	var antes := _estado()
	assert_false(run.escolher_casa(run.mapa().casas_do_andar(2)[0]))
	assert_eq(_estado(), antes)


func test_casa_nao_ligada_a_atual_nao_vale() -> void:
	# Procura uma casa do andar 1 que não liga para todas do andar 2.
	var atual: Casa = null
	var nao_ligada: Casa = null
	for casa in run.mapa().casas_do_andar(1):
		for acima in run.mapa().casas_do_andar(2):
			if acima not in casa.ligacoes:
				atual = casa
				nao_ligada = acima
	assert_not_null(nao_ligada, "o mapa da semente %d precisa de uma casa não ligada" % SEMENTE)
	if nao_ligada == null:
		return
	_posicionar(atual)
	var antes := _estado()
	assert_false(run.escolher_casa(nao_ligada))
	assert_eq(_estado(), antes)


func test_casa_de_andar_abaixo_ou_dois_acima_nao_vale() -> void:
	var atual := run.mapa().casas_do_andar(2)[0]
	_posicionar(atual)
	var antes := _estado()
	assert_false(run.escolher_casa(run.mapa().casas_do_andar(1)[0]), "andar abaixo")
	assert_false(run.escolher_casa(run.mapa().casas_do_andar(4)[0]), "dois andares acima")
	assert_false(run.escolher_casa(atual), "a própria casa")
	assert_eq(_estado(), antes)


func test_fora_da_etapa_mapa_nenhuma_casa_vale() -> void:
	assert_true(run.escolher_casa(run.mapa().casas_do_andar(1)[0]))
	assert_eq(run.casas_disponiveis(), [] as Array[Casa])
	var antes := _estado()
	assert_false(run.escolher_casa(run.mapa().casas_do_andar(1)[1]))
	assert_eq(_estado(), antes)


# --- História 1, cenário 3 ---

func test_batalha_do_andar_1_abre_a_luta_com_a_vida_da_run() -> void:
	run.vida_arthur = 31
	var casa := run.mapa().casas_do_andar(1)[0]
	assert_true(run.escolher_casa(casa))
	assert_eq(run.etapa, Run.Etapa.LUTA)
	assert_eq(run.casa_atual, casa)
	assert_true(casa.visitada)
	assert_eq(run.andar_alcancado(), 1)
	assert_eq(run.vida_arthur, 31)
	var inimigo := run.inimigo_da_luta()
	var esperado := run.dados_do_ato().inimigo(Casa.Tipo.BATALHA, 1)
	assert_eq([inimigo.nome, inimigo.vida, inimigo.ataque], [esperado.nome, esperado.vida, esperado.ataque])
	assert_eq(inimigo.vida, 12)
	var regras := run.regras_da_luta()
	assert_eq([regras.alvo_minimo, regras.alvo_maximo], [5, 12])
	assert_eq(regras.vida_maxima_arthur, 40)


func test_elite_tem_o_inimigo_do_andar_dela() -> void:
	var achada: Array = []
	for andar in range(3, run.mapa().total_de_andares):
		if achada.is_empty():
			achada = _casa_e_anterior(Casa.Tipo.ELITE, andar)
	assert_false(achada.is_empty(), "todo mapa padrão tem uma elite do andar 3 em diante")
	if achada.is_empty():
		return
	var elite: Casa = achada[0]
	_posicionar(achada[1])
	assert_true(run.escolher_casa(elite))
	assert_eq(run.etapa, Run.Etapa.LUTA)
	var inimigo := run.inimigo_da_luta()
	var esperado := run.dados_do_ato().inimigo(Casa.Tipo.ELITE, elite.andar)
	assert_eq([inimigo.nome, inimigo.vida, inimigo.ataque], [esperado.nome, esperado.vida, esperado.ataque])


func test_casa_do_chefe_abre_a_etapa_chefe_com_o_chefe_do_ato() -> void:
	var chefe := run.mapa().casas_do_andar(run.mapa().total_de_andares)[0]
	_posicionar(run.mapa().casas_do_andar(run.mapa().total_de_andares - 1)[0])
	assert_true(run.escolher_casa(chefe))
	assert_eq(run.etapa, Run.Etapa.CHEFE)
	assert_eq(run.andar_alcancado(), 5)
	var inimigo := run.inimigo_da_luta()
	assert_eq([inimigo.nome, inimigo.vida, inimigo.ataque], ["Chefe do calabouço", 26, 5])


# --- Dados só leitura e semente ---

func test_mudar_o_baralho_da_run_nao_muda_o_baralho_inicial() -> void:
	run.baralho.append(load("res://dados/cartas/chama.tres"))
	run.baralho.remove_at(0)
	assert_eq(DIFICULDADE.baralho_inicial.size(), 13)
	assert_eq(Run.new(DIFICULDADE, SEMENTE).baralho.size(), 13)


func test_inimigo_da_luta_nao_e_o_objeto_dos_dados() -> void:
	run.escolher_casa(run.mapa().casas_do_andar(1)[0])
	run.inimigo_da_luta().vida = 99
	assert_eq(DIFICULDADE.atos[0].comum.vida, 12)
	assert_ne(run.regras_da_luta(), DIFICULDADE.regras_base)


func test_mesma_semente_da_os_mesmos_mapas_e_a_mesma_semente_da_luta() -> void:
	var outra := Run.new(DIFICULDADE, SEMENTE)
	assert_eq(_descricao_dos_mapas(outra), _descricao_dos_mapas(run))
	assert_true(run.escolher_casa(run.mapa().casas_do_andar(1)[1]))
	assert_true(outra.escolher_casa(outra.mapa().casas_do_andar(1)[1]))
	assert_eq(outra.semente_da_luta, run.semente_da_luta)


func test_sementes_diferentes_dao_mapas_diferentes() -> void:
	var mapas := {}
	for i in 20:
		mapas[_descricao_dos_mapas(Run.new(DIFICULDADE, hash(i)))] = true
	assert_gt(mapas.size(), 1)
