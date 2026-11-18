extends GutTest
## GeradorMapa em 1.000 sementes por configuração (SC-001, SC-002). As conferências não usam o
## algoritmo do gerador: contam e olham o mapa pronto. As falhas são contadas durante as
## sementes e conferidas no fim, para o relatório mostrar a primeira de cada tipo.

const SEMENTES := 1000

## Primeira falha de cada conferência (vazio = nenhuma falha).
var _falhas: Dictionary = {}


func _falhou(conferencia: String, detalhe: String) -> void:
	if not _falhas.has(conferencia):
		_falhas[conferencia] = detalhe


func _assert_sem_falhas() -> void:
	assert_eq(_falhas, {}, "primeira falha de cada conferência")


func _dados_com(mudancas: Dictionary) -> DadosMapa:
	var dados := DadosMapa.new()
	for campo: String in mudancas:
		dados.set(campo, mudancas[campo])
	return dados


## Os padrões e configurações válidas diferentes deles.
func _configuracoes() -> Array[DadosMapa]:
	var lista: Array[DadosMapa] = [
		DadosMapa.new(),
		_dados_com({"andares_comuns": 2, "elites": 0, "batalhas": 1, "descansos": 1, "recompensas": 1}),
		_dados_com({"andares_comuns": 6, "batalhas": 4, "elites": 2, "descansos": 2, "recompensas": 3}),
		_dados_com({"casas_minimas_por_andar": 3, "casas_maximas_por_andar": 3, "batalhas": 4}),
	]
	return lista


func test_configuracoes_do_teste_sao_validas() -> void:
	var configuracao := 0
	for dados in _configuracoes():
		configuracao += 1
		assert_eq(dados.erros(), [] as Array[String], "configuração %d" % configuracao)


func test_mil_sementes_cumprem_as_regras_do_mapa() -> void:
	var configuracao := 0
	for dados in _configuracoes():
		configuracao += 1
		for i in SEMENTES:
			_conferir_mapa(GeradorMapa.gerar(dados, hash(i)), dados, "configuração %d, semente hash(%d)" % [configuracao, i])
	_assert_sem_falhas()


func test_padroes_so_dividem_os_andares_em_3_3_2_3_2_3_e_2_3_3() -> void:
	var divisoes := {}
	for i in SEMENTES:
		var mapa := GeradorMapa.gerar(DadosMapa.new(), hash(i))
		var divisao := []
		for andar in range(2, mapa.total_de_andares):
			divisao.append(mapa.casas_do_andar(andar).size())
		divisoes[divisao] = true
	var achadas := divisoes.keys()
	achadas.sort()
	assert_eq(achadas, [[2, 3, 3], [3, 2, 3], [3, 3, 2]])


func test_mesma_semente_da_o_mesmo_mapa() -> void:
	for dados in _configuracoes():
		for i in 50:
			assert_eq(_descricao(GeradorMapa.gerar(dados, hash(i))), _descricao(GeradorMapa.gerar(dados, hash(i))), "semente hash(%d)" % i)


func test_sementes_diferentes_dao_mapas_diferentes() -> void:
	var mapas := {}
	for i in 50:
		mapas[_descricao(GeradorMapa.gerar(DadosMapa.new(), hash(i)))] = true
	assert_gt(mapas.size(), 1)


## Andar, índice, tipo e ligações (pelo índice) de cada casa, na ordem da lista.
func _descricao(mapa: MapaAto) -> Array:
	var descricao: Array = [mapa.total_de_andares]
	for casa in mapa.casas:
		descricao.append([casa.andar, casa.indice, casa.tipo, casa.ligacoes.map(func(outra: Casa) -> int: return outra.indice)])
	return descricao


func _conferir_mapa(mapa: MapaAto, dados: DadosMapa, onde: String) -> void:
	_conferir_andares(mapa, dados, onde)
	_conferir_tipos(mapa, dados, onde)
	_conferir_ligacoes(mapa, onde)
	_conferir_alcance(mapa, onde)


## Andares no lugar, tamanhos entre o mínimo e o máximo, índices em ordem e a lista ordenada.
func _conferir_andares(mapa: MapaAto, dados: DadosMapa, onde: String) -> void:
	if mapa.total_de_andares != dados.andares_comuns + 1:
		_falhou("total de andares", onde)
	var contadas := 0
	for andar in range(1, mapa.total_de_andares + 1):
		var casas := mapa.casas_do_andar(andar)
		contadas += casas.size()
		for posicao in casas.size():
			if casas[posicao].indice != posicao:
				_falhou("índice fora de ordem", "%s, andar %d" % [onde, andar])
		if andar == 1 and casas.size() != dados.batalhas_primeiro_andar:
			_falhou("tamanho do andar 1", onde)
		if andar > 1 and andar < mapa.total_de_andares and (casas.size() < dados.casas_minimas_por_andar or casas.size() > dados.casas_maximas_por_andar):
			_falhou("andar fora do mínimo e do máximo", "%s, andar %d com %d casas" % [onde, andar, casas.size()])
	if contadas != mapa.casas.size():
		_falhou("casa fora dos andares", onde)
	for posicao in range(1, mapa.casas.size()):
		var antes := mapa.casas[posicao - 1]
		var depois := mapa.casas[posicao]
		if antes.andar > depois.andar or (antes.andar == depois.andar and antes.indice >= depois.indice):
			_falhou("lista fora de ordem", onde)


## Quantidade de cada tipo e onde cada tipo pode ficar (FR-011).
func _conferir_tipos(mapa: MapaAto, dados: DadosMapa, onde: String) -> void:
	var quantidades := {}
	for casa in mapa.casas:
		quantidades[casa.tipo] = quantidades.get(casa.tipo, 0) + 1
		if casa.andar == 1 and casa.tipo != Casa.Tipo.BATALHA:
			_falhou("andar 1 com casa que não é batalha", onde)
		if casa.tipo == Casa.Tipo.ELITE and casa.andar < 3:
			_falhou("elite antes do andar 3", "%s, andar %d" % [onde, casa.andar])
	var esperadas := {
		Casa.Tipo.BATALHA: dados.batalhas_primeiro_andar + dados.batalhas,
		Casa.Tipo.ELITE: dados.elites,
		Casa.Tipo.DESCANSO: dados.descansos,
		Casa.Tipo.RECOMPENSA: dados.recompensas,
		Casa.Tipo.CHEFE: 1,
	}
	for tipo: Casa.Tipo in esperadas:
		if quantidades.get(tipo, 0) != esperadas[tipo]:
			_falhou("quantidade de um tipo", "%s, tipo %d: %d em vez de %d" % [onde, tipo, quantidades.get(tipo, 0), esperadas[tipo]])
	var topo := mapa.casas_do_andar(mapa.total_de_andares)
	if topo.size() != 1 or topo[0].tipo != Casa.Tipo.CHEFE:
		_falhou("chefe não está sozinho no topo", onde)
	var ultimo_comum := mapa.casas_do_andar(dados.andares_comuns)
	if not ultimo_comum.any(func(casa: Casa) -> bool: return casa.tipo == Casa.Tipo.DESCANSO):
		_falhou("último andar comum sem descanso", onde)


## Ligações só para o andar seguinte, sem repetição, em ordem de índice e sem cruzamento
## (FR-010); o chefe não liga para ninguém.
func _conferir_ligacoes(mapa: MapaAto, onde: String) -> void:
	for casa in mapa.casas:
		for posicao in casa.ligacoes.size():
			var outra := casa.ligacoes[posicao]
			if outra.andar != casa.andar + 1 or not outra in mapa.casas:
				_falhou("ligação fora do andar seguinte", "%s, andar %d" % [onde, casa.andar])
			if posicao > 0 and casa.ligacoes[posicao - 1].indice >= outra.indice:
				_falhou("ligações repetidas ou fora de ordem", "%s, andar %d" % [onde, casa.andar])
	if not mapa.casas_do_andar(mapa.total_de_andares)[0].ligacoes.is_empty():
		_falhou("chefe com ligação", onde)
	for andar in range(1, mapa.total_de_andares):
		var pares: Array = []
		for casa in mapa.casas_do_andar(andar):
			for outra in casa.ligacoes:
				pares.append([casa.indice, outra.indice])
		for primeiro in pares:
			for segundo in pares:
				if primeiro[0] < segundo[0] and primeiro[1] > segundo[1]:
					_falhou("ligações cruzadas", "%s, andar %d: %s e %s" % [onde, andar, primeiro, segundo])


## Busca em largura do andar 1 para cima e do chefe para baixo: toda casa é alcançada nos dois
## sentidos (FR-009). Contagem de caminhos do andar 1 ao chefe, andar a andar: pelo menos 2.
func _conferir_alcance(mapa: MapaAto, onde: String) -> void:
	var de_baixo := _alcancadas(mapa.casas_do_andar(1), func(casa: Casa) -> Array[Casa]: return casa.ligacoes)
	if de_baixo.size() != mapa.casas.size():
		_falhou("casa que o andar 1 não alcança", onde)
	var chegam_em := {}
	for casa in mapa.casas:
		for outra in casa.ligacoes:
			if not chegam_em.has(outra):
				chegam_em[outra] = [] as Array[Casa]
			chegam_em[outra].append(casa)
	var chefe := mapa.casas_do_andar(mapa.total_de_andares)[0]
	var de_cima := _alcancadas([chefe] as Array[Casa], func(casa: Casa) -> Array[Casa]: return chegam_em.get(casa, [] as Array[Casa]))
	if de_cima.size() != mapa.casas.size():
		_falhou("casa sem caminho até o chefe", onde)
	var caminhos := {}
	for casa in mapa.casas:
		if casa.andar == 1:
			caminhos[casa] = 1
		for outra in casa.ligacoes:
			caminhos[outra] = caminhos.get(outra, 0) + caminhos.get(casa, 0)
	if caminhos.get(chefe, 0) < 2:
		_falhou("menos de dois caminhos até o chefe", "%s: %d" % [onde, caminhos.get(chefe, 0)])


func _alcancadas(inicio: Array[Casa], vizinhas: Callable) -> Dictionary:
	var vistas := {}
	var fila: Array[Casa] = inicio.duplicate()
	while not fila.is_empty():
		var casa: Casa = fila.pop_front()
		if vistas.has(casa):
			continue
		vistas[casa] = true
		fila.append_array(vizinhas.call(casa))
	return vistas
