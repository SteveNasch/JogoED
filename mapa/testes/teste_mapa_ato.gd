extends GutTest
## MapaAto com um mapa montado à mão: 3 batalhas no andar 1, descanso e recompensa no andar 2 e
## o chefe no andar 3.
##
##        chefe
##       /     \
##   descanso  recompensa
##    /   \     /   \
##   b0    b1       b2

var mapa: MapaAto


func before_each() -> void:
	mapa = MapaAto.new()
	mapa.total_de_andares = 3
	var tipos := [
		[Casa.Tipo.BATALHA, 1], [Casa.Tipo.BATALHA, 1], [Casa.Tipo.BATALHA, 1],
		[Casa.Tipo.DESCANSO, 2], [Casa.Tipo.RECOMPENSA, 2],
		[Casa.Tipo.CHEFE, 3],
	]
	var indice_no_andar := {}
	for linha in tipos:
		var andar: int = linha[1]
		mapa.casas.append(Casa.new(linha[0], andar, indice_no_andar.get(andar, 0)))
		indice_no_andar[andar] = indice_no_andar.get(andar, 0) + 1
	var c := mapa.casas
	c[0].ligacoes.assign([c[3]])
	c[1].ligacoes.assign([c[3], c[4]])
	c[2].ligacoes.assign([c[4]])
	c[3].ligacoes.assign([c[5]])
	c[4].ligacoes.assign([c[5]])


func _indices(casas: Array[Casa]) -> Array[int]:
	var lista: Array[int] = []
	for casa in casas:
		lista.append(casa.indice)
	return lista


func test_casas_do_andar_vem_em_ordem_de_indice() -> void:
	assert_eq(_indices(mapa.casas_do_andar(1)), [0, 1, 2] as Array[int])
	assert_eq(_indices(mapa.casas_do_andar(2)), [0, 1] as Array[int])
	for casa in mapa.casas_do_andar(2):
		assert_eq(casa.andar, 2)


func test_ultimo_andar_e_so_o_chefe() -> void:
	var topo := mapa.casas_do_andar(mapa.total_de_andares)
	assert_eq(topo.size(), 1)
	assert_eq(topo[0].tipo, Casa.Tipo.CHEFE)


func test_sem_casa_atual_estao_disponiveis_as_do_andar_1() -> void:
	assert_eq(mapa.disponiveis(null), mapa.casas_do_andar(1))


func test_com_casa_atual_estao_disponiveis_as_ligacoes_dela() -> void:
	var b1 := mapa.casas[1]
	assert_eq(mapa.disponiveis(b1), [mapa.casas[3], mapa.casas[4]] as Array[Casa])
	assert_eq(mapa.disponiveis(mapa.casas[3]), [mapa.casas[5]] as Array[Casa])


func test_chefe_nao_tem_casas_disponiveis_depois_dele() -> void:
	assert_eq(mapa.disponiveis(mapa.casas[5]), [] as Array[Casa])


func test_mudar_a_lista_de_disponiveis_nao_muda_as_ligacoes() -> void:
	var lista := mapa.disponiveis(mapa.casas[1])
	lista.clear()
	assert_eq(mapa.casas[1].ligacoes.size(), 2)


func test_andar_inexistente_devolve_lista_vazia() -> void:
	assert_eq(mapa.casas_do_andar(0), [] as Array[Casa])
	assert_eq(mapa.casas_do_andar(4), [] as Array[Casa])
