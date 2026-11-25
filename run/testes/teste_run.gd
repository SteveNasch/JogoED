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


# --- História 1, cenário 4, e a subida pelo mapa ---

## Invariantes do data-model: vida entre 1 e a máxima, e as casas visitadas do ato formam um
## caminho, uma por andar, do andar 1 até a casa atual, cada uma ligada à seguinte.
func _conferir_invariantes(onde: String) -> void:
	assert_between(run.vida_arthur, 1, run.vida_maxima, "%s: vida" % onde)
	var caminho := run.mapa().casas.filter(func(casa: Casa) -> bool: return casa.visitada)
	assert_eq(caminho.size(), run.andar_alcancado(), "%s: uma casa visitada por andar" % onde)
	for posicao in caminho.size():
		assert_eq(caminho[posicao].andar, posicao + 1, "%s: andar da casa visitada" % onde)
		if posicao > 0:
			assert_has(caminho[posicao - 1].ligacoes, caminho[posicao], "%s: casas visitadas ligadas" % onde)
	if not caminho.is_empty():
		assert_eq(caminho.back(), run.casa_atual, "%s: o caminho termina na casa atual" % onde)


func test_vitoria_numa_batalha_volta_ao_mapa_com_a_vida_que_sobrou() -> void:
	var casa := run.mapa().casas_do_andar(1)[1]
	run.escolher_casa(casa)
	run.terminar_luta(ResultadoLuta.new(true, 24, 0, 5))
	assert_eq(run.etapa, Run.Etapa.MAPA)
	assert_eq(run.casa_atual, casa)
	assert_true(casa.visitada)
	assert_eq(run.vida_arthur, 24)
	assert_eq(run.lutas_vencidas, 1)
	assert_eq(run.oferta, [] as Array[DadosCarta])
	assert_eq(run.casas_disponiveis(), casa.ligacoes)


func test_terminar_luta_fora_da_luta_nao_faz_nada() -> void:
	var antes := _estado()
	run.terminar_luta(ResultadoLuta.new(true, 10, 0, 5))
	assert_eq(_estado(), antes)
	assert_eq(run.lutas_vencidas, 0)


func test_subida_do_andar_1_ao_4_por_batalhas_mantem_o_caminho() -> void:
	for i in 20:
		run = Run.new(DIFICULDADE, hash(i))
		var vida := run.vida_maxima
		var vencidas := 0
		for andar in range(1, 5):
			var disponiveis := run.casas_disponiveis()
			var batalhas := disponiveis.filter(func(casa: Casa) -> bool: return casa.tipo == Casa.Tipo.BATALHA)
			if batalhas.is_empty():
				# Sem batalha ligada à atual: a run é posicionada numa casa ligada a ela.
				_posicionar(disponiveis[0])
			else:
				assert_true(run.escolher_casa(batalhas[0]), "semente hash(%d), andar %d" % [i, andar])
				vida -= 4
				run.terminar_luta(ResultadoLuta.new(true, vida, 0, 3))
				vencidas += 1
			_conferir_invariantes("semente hash(%d), andar %d" % [i, andar])
		assert_eq(run.andar_alcancado(), 4)
		assert_eq(run.lutas_vencidas, vencidas)
		assert_eq(run.vida_arthur, vida)


# --- História 2: derrota ---

## Entra numa batalha do ato atual, do andar 2 em diante, a partir de uma casa ligada a ela.
func _entrar_numa_batalha_acima_do_andar_1() -> Casa:
	var achada := _casa_acima_do_andar_1(Casa.Tipo.BATALHA)
	if achada.is_empty():
		return null
	_posicionar(achada[1])
	assert_true(run.escolher_casa(achada[0]))
	return achada[0]


func test_derrota_no_ato_2_acaba_a_run_com_o_resumo() -> void:
	run.ato = 2
	for nome in ["chama", "foco", "guarda"]:
		run.baralho.append(load("res://dados/cartas/%s.tres" % nome))
	run.lutas_vencidas = 7
	var casa := _entrar_numa_batalha_acima_do_andar_1()
	assert_not_null(casa, "todo mapa padrão tem uma batalha acima do andar 1")
	if casa == null:
		return
	assert_eq(run.baralho.size(), 16)
	run.terminar_luta(ResultadoLuta.new(false, 0, 5, 4))
	assert_eq(run.etapa, Run.Etapa.DERROTA)
	assert_eq(run.vida_arthur, 0)
	assert_eq(run.ato, 2)
	assert_eq(run.andar_alcancado(), casa.andar)
	assert_eq(run.lutas_vencidas, 7)
	assert_eq(run.casas_disponiveis(), [] as Array[Casa])


func test_derrota_zera_a_vida_mesmo_se_o_resultado_diz_outra() -> void:
	run.escolher_casa(run.mapa().casas_do_andar(1)[0])
	run.terminar_luta(ResultadoLuta.new(false, 3, 5, 4))
	assert_eq(run.vida_arthur, 0)


func test_run_nova_depois_da_derrota_comeca_do_zero_com_outro_mapa() -> void:
	run.ato = 2
	run.baralho.append(load("res://dados/cartas/chama.tres"))
	_entrar_numa_batalha_acima_do_andar_1()
	run.terminar_luta(ResultadoLuta.new(false, 0, 5, 4))
	var nova := Run.new(DIFICULDADE, SEMENTE + 1)
	var tamanho_ato_1 := run.mapas[0].casas.size()
	assert_ne(_descricao_dos_mapas(nova).slice(0, nova.mapas[0].casas.size()),
		_descricao_dos_mapas(run).slice(0, tamanho_ato_1), "o mapa do ato 1 da run nova é outro")
	assert_eq(nova.ato, 1)
	assert_eq(nova.etapa, Run.Etapa.MAPA)
	assert_eq([nova.vida_arthur, nova.vida_maxima], [40, 40])
	assert_eq(nova.baralho, DIFICULDADE.baralho_inicial)
	assert_eq(nova.baralho.size(), 13)
	assert_eq(nova.lutas_vencidas, 0)
	assert_null(nova.casa_atual)
	assert_false(nova.mapas.any(func(mapa_ato: MapaAto) -> bool: return mapa_ato.casas.any(func(casa: Casa) -> bool: return casa.visitada)))


func test_derrota_no_chefe_e_igual_a_qualquer_derrota() -> void:
	var chefe := run.mapa().casas_do_andar(run.mapa().total_de_andares)[0]
	_posicionar(run.mapa().casas_do_andar(run.mapa().total_de_andares - 1)[0])
	run.lutas_vencidas = 4
	assert_true(run.escolher_casa(chefe))
	run.terminar_luta(ResultadoLuta.new(false, 0, 10, 6))
	assert_eq(run.etapa, Run.Etapa.DERROTA)
	assert_eq(run.vida_arthur, 0)
	assert_eq(run.ato, 1)
	assert_eq(run.andar_alcancado(), 5)
	assert_eq(run.lutas_vencidas, 4)


func test_depois_da_derrota_nenhum_metodo_muda_nada() -> void:
	var casa := run.mapa().casas_do_andar(1)[0]
	run.escolher_casa(casa)
	run.terminar_luta(ResultadoLuta.new(false, 0, 5, 4))
	var antes := _estado()
	for outra in casa.ligacoes:
		assert_false(run.escolher_casa(outra))
	run.terminar_luta(ResultadoLuta.new(true, 30, 0, 2))
	assert_eq(_estado(), antes)
	assert_eq(run.lutas_vencidas, 0)


# --- História 3: descanso ---

## Uma casa do tipo pedido do andar 2 em diante e a casa anterior ligada a ela, ou [].
func _casa_acima_do_andar_1(tipo: Casa.Tipo) -> Array:
	for andar in range(2, run.mapa().total_de_andares):
		var achada := _casa_e_anterior(tipo, andar)
		if not achada.is_empty():
			return achada
	return []


## Põe o Arthur com `vida` na casa antes de um descanso e entra nele. Devolve o descanso.
func _descansar_com(vida: int) -> Casa:
	var achada := _casa_acima_do_andar_1(Casa.Tipo.DESCANSO)
	assert_false(achada.is_empty(), "todo mapa padrão tem descanso")
	if achada.is_empty():
		return null
	_posicionar(achada[1])
	run.vida_arthur = vida
	assert_true(run.escolher_casa(achada[0]))
	return achada[0]


func test_descanso_com_20_cura_12_e_fica_com_32() -> void:
	var descanso := _descansar_com(20)
	assert_eq(run.etapa, Run.Etapa.DESCANSO)
	assert_eq(run.casa_atual, descanso)
	assert_true(descanso.visitada)
	assert_eq(run.vida_arthur, 32)
	assert_eq(run.cura, 12)
	assert_eq(run.casas_disponiveis(), [] as Array[Casa])
	run.sair_do_descanso()
	assert_eq(run.etapa, Run.Etapa.MAPA)
	assert_eq(run.vida_arthur, 32)
	assert_eq(run.casas_disponiveis(), descanso.ligacoes)


func test_descanso_com_35_nao_passa_da_maxima_e_cura_5() -> void:
	_descansar_com(35)
	assert_eq(run.vida_arthur, 40)
	assert_eq(run.cura, 5)


func test_descanso_com_vida_cheia_cura_0() -> void:
	_descansar_com(40)
	assert_eq(run.vida_arthur, 40)
	assert_eq(run.cura, 0)


func test_descanso_nao_sorteia_luta() -> void:
	var semente_antes := run.semente_da_luta
	_descansar_com(20)
	assert_eq(run.semente_da_luta, semente_antes)
	assert_null(run.inimigo_da_luta())


func test_cura_vem_do_arquivo_de_dificuldade_sem_mudar_o_carregado() -> void:
	var copia := DIFICULDADE.duplicate(true) as DadosDificuldade
	copia.cura_do_descanso = 50
	run = Run.new(copia, SEMENTE)
	_descansar_com(20)
	assert_eq(run.cura, 20)
	assert_eq(run.vida_arthur, 40)
	assert_eq(DIFICULDADE.cura_do_descanso, 30)


func test_sair_do_descanso_fora_do_descanso_nao_faz_nada() -> void:
	run.sair_do_descanso()
	assert_eq(run.etapa, Run.Etapa.MAPA)
	run.escolher_casa(run.mapa().casas_do_andar(1)[0])
	run.sair_do_descanso()
	assert_eq(run.etapa, Run.Etapa.LUTA)


func test_sair_do_descanso_depois_da_derrota_nao_faz_nada() -> void:
	run.escolher_casa(run.mapa().casas_do_andar(1)[0])
	run.terminar_luta(ResultadoLuta.new(false, 0, 5, 4))
	var antes := _estado()
	run.sair_do_descanso()
	assert_eq(_estado(), antes)


# --- História 3: recompensa ---

## Põe o Arthur na casa antes de uma recompensa e entra nela. Devolve a recompensa.
func _entrar_numa_recompensa() -> Casa:
	var achada := _casa_acima_do_andar_1(Casa.Tipo.RECOMPENSA)
	assert_false(achada.is_empty(), "todo mapa padrão tem recompensa")
	if achada.is_empty():
		return null
	_posicionar(achada[1])
	assert_true(run.escolher_casa(achada[0]))
	return achada[0]


## Cópia dos dados com outro conjunto de recompensas; o arquivo carregado não muda.
func _dados_com_recompensas(nomes: Array[String]) -> DadosDificuldade:
	var copia := DIFICULDADE.duplicate(true) as DadosDificuldade
	var conjunto: Array[DadosCarta] = []
	for nome in nomes:
		conjunto.append(load("res://dados/cartas/%s.tres" % nome))
	copia.cartas_de_recompensa = conjunto
	return copia


func test_recompensa_abre_3_cartas_diferentes_do_conjunto() -> void:
	var casa := _entrar_numa_recompensa()
	assert_eq(run.etapa, Run.Etapa.RECOMPENSA)
	assert_eq(run.casa_atual, casa)
	assert_true(casa.visitada)
	assert_eq(run.oferta.size(), 3)
	for carta in run.oferta:
		assert_has(DIFICULDADE.cartas_de_recompensa, carta)
		assert_eq(run.oferta.count(carta), 1, "carta repetida na oferta")
	assert_eq(run.casas_disponiveis(), [] as Array[Casa])


func test_escolher_a_chama_poe_ela_no_fim_do_baralho() -> void:
	var chama: DadosCarta = load("res://dados/cartas/chama.tres")
	var quantas := 0
	for i in 50:
		run = Run.new(DIFICULDADE, hash(i))
		var casa := _entrar_numa_recompensa()
		if chama not in run.oferta:
			continue
		quantas += 1
		run.escolher_recompensa(chama)
		assert_eq(run.etapa, Run.Etapa.MAPA)
		assert_eq(run.baralho.size(), 14)
		assert_eq(run.baralho.back(), chama)
		assert_eq(run.baralho.slice(0, 13), DIFICULDADE.baralho_inicial)
		assert_eq(run.oferta, [] as Array[DadosCarta])
		assert_eq(run.casas_disponiveis(), casa.ligacoes)
	assert_gt(quantas, 0, "a Chama aparece em alguma oferta de 50 runs")


func test_nao_pegar_nenhuma_deixa_o_baralho_igual() -> void:
	_entrar_numa_recompensa()
	run.escolher_recompensa(null)
	assert_eq(run.etapa, Run.Etapa.MAPA)
	assert_eq(run.baralho, DIFICULDADE.baralho_inicial)
	assert_eq(run.oferta, [] as Array[DadosCarta])


func test_carta_fora_da_oferta_nao_faz_nada() -> void:
	_entrar_numa_recompensa()
	var fora: DadosCarta = null
	for carta in DIFICULDADE.cartas_de_recompensa:
		if carta not in run.oferta:
			fora = carta
	var oferta_antes := run.oferta.duplicate()
	var antes := _estado()
	run.escolher_recompensa(fora)
	assert_eq(_estado(), antes)
	assert_eq(run.oferta, oferta_antes)


func test_elite_vencida_abre_a_recompensa() -> void:
	var achada: Array = []
	for andar in range(3, run.mapa().total_de_andares):
		if achada.is_empty():
			achada = _casa_e_anterior(Casa.Tipo.ELITE, andar)
	assert_false(achada.is_empty(), "todo mapa padrão tem uma elite do andar 3 em diante")
	if achada.is_empty():
		return
	_posicionar(achada[1])
	run.escolher_casa(achada[0])
	run.terminar_luta(ResultadoLuta.new(true, 22, 0, 6))
	assert_eq(run.etapa, Run.Etapa.RECOMPENSA)
	assert_eq(run.vida_arthur, 22)
	assert_eq(run.lutas_vencidas, 1)
	assert_eq(run.oferta.size(), 3)
	run.escolher_recompensa(run.oferta[0])
	assert_eq(run.etapa, Run.Etapa.MAPA)
	assert_eq(run.ato, 1)
	assert_eq(run.casa_atual, achada[0])
	assert_eq(run.baralho.size(), 14)


func test_batalha_vencida_nao_abre_a_recompensa() -> void:
	_entrar_numa_batalha_acima_do_andar_1()
	run.terminar_luta(ResultadoLuta.new(true, 30, 0, 4))
	assert_eq(run.etapa, Run.Etapa.MAPA)
	assert_eq(run.oferta, [] as Array[DadosCarta])


func test_carta_repetida_no_conjunto_conta_uma_vez() -> void:
	run = Run.new(_dados_com_recompensas(["chama", "chama", "foco"] as Array[String]), SEMENTE)
	_entrar_numa_recompensa()
	assert_eq(run.oferta.size(), 2)
	assert_eq(run.oferta.count(run.oferta[0]), 1)
	assert_eq(DIFICULDADE.cartas_de_recompensa.size(), 14)


func test_conjunto_de_2_cartas_da_oferta_de_2() -> void:
	run = Run.new(_dados_com_recompensas(["guarda", "vital"] as Array[String]), SEMENTE)
	_entrar_numa_recompensa()
	assert_eq(run.oferta.size(), 2)


func test_conjunto_vazio_da_oferta_vazia_e_volta_ao_mapa() -> void:
	run = Run.new(_dados_com_recompensas([] as Array[String]), SEMENTE)
	_entrar_numa_recompensa()
	assert_eq(run.etapa, Run.Etapa.RECOMPENSA)
	assert_eq(run.oferta, [] as Array[DadosCarta])
	run.escolher_recompensa(null)
	assert_eq(run.etapa, Run.Etapa.MAPA)
	assert_eq(run.baralho, DIFICULDADE.baralho_inicial)


func test_baralho_e_o_inicial_mais_as_escolhidas_na_ordem() -> void:
	var escolhidas: Array[DadosCarta] = []
	for vez in 3:
		run.etapa = Run.Etapa.RECOMPENSA
		run.oferta = [DIFICULDADE.cartas_de_recompensa[vez * 2], DIFICULDADE.cartas_de_recompensa[vez * 2 + 1]]
		run.escolher_recompensa(run.oferta[1])
		escolhidas.append(DIFICULDADE.cartas_de_recompensa[vez * 2 + 1])
	var esperado := DIFICULDADE.baralho_inicial.duplicate()
	esperado.append_array(escolhidas)
	assert_eq(run.baralho, esperado)


func test_mesma_semente_da_as_mesmas_ofertas() -> void:
	_entrar_numa_recompensa()
	var oferta := run.oferta.duplicate()
	run = Run.new(DIFICULDADE, SEMENTE)
	_entrar_numa_recompensa()
	assert_eq(run.oferta, oferta)


func test_escolher_recompensa_fora_da_recompensa_nao_faz_nada() -> void:
	run.escolher_recompensa(DIFICULDADE.cartas_de_recompensa[0])
	assert_eq(run.etapa, Run.Etapa.MAPA)
	assert_eq(run.baralho, DIFICULDADE.baralho_inicial)


func test_escolher_recompensa_depois_da_derrota_nao_faz_nada() -> void:
	run.escolher_casa(run.mapa().casas_do_andar(1)[0])
	run.terminar_luta(ResultadoLuta.new(false, 0, 5, 4))
	var antes := _estado()
	run.escolher_recompensa(null)
	run.escolher_recompensa(DIFICULDADE.cartas_de_recompensa[0])
	assert_eq(_estado(), antes)
