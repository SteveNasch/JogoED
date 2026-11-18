class_name GeradorMapa
## Gera o mapa de um ato a partir dos dados e de uma semente (research D4). Mesma semente e
## mesmos dados, mesmo mapa. Todo sorteio usa o mesmo gerador, criado aqui.


## Pré-condição: dados.erros() vazio.
static func gerar(dados: DadosMapa, semente: int) -> MapaAto:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var mapa := MapaAto.new()
	mapa.total_de_andares = dados.andares_comuns + 1
	var tamanhos := _tamanhos_dos_andares(dados, rng)
	for andar in range(1, tamanhos.size() + 1):
		for indice in tamanhos[andar - 1]:
			# O andar 1 é todo de batalhas; o tipo das outras casas é sorteado logo abaixo.
			mapa.casas.append(Casa.new(Casa.Tipo.BATALHA, andar, indice))
	_sortear_tipos(dados, mapa.casas.filter(func(casa: Casa) -> bool: return casa.andar > 1), rng)
	mapa.casas.append(Casa.new(Casa.Tipo.CHEFE, mapa.total_de_andares, 0))
	return mapa


## Passo 1: o andar 1 tem as batalhas dele; cada andar seguinte começa com o mínimo, e as casas
## que sobram vão, uma a uma, para um andar sorteado que ainda não chegou no máximo.
static func _tamanhos_dos_andares(dados: DadosMapa, rng: RandomNumberGenerator) -> Array[int]:
	var tamanhos: Array[int] = [dados.batalhas_primeiro_andar]
	for i in dados.andares_comuns - 1:
		tamanhos.append(dados.casas_minimas_por_andar)
	var sobra := dados.casas_acima_do_primeiro() - (dados.andares_comuns - 1) * dados.casas_minimas_por_andar
	for i in sobra:
		var abertos: Array[int] = []
		for posicao in range(1, tamanhos.size()):
			if tamanhos[posicao] < dados.casas_maximas_por_andar:
				abertos.append(posicao)
		tamanhos[abertos[rng.randi_range(0, abertos.size() - 1)]] += 1
	return tamanhos


## Passo 2 (FR-011): um descanso no último andar comum, as elites do andar 3 em diante e o resto
## nas vagas que sobraram, nesta ordem.
static func _sortear_tipos(dados: DadosMapa, livres: Array[Casa], rng: RandomNumberGenerator) -> void:
	var do_ultimo_andar := livres.filter(func(casa: Casa) -> bool: return casa.andar == dados.andares_comuns)
	_ocupar(livres, do_ultimo_andar, Casa.Tipo.DESCANSO, rng)
	for i in dados.elites:
		var do_andar_3_em_diante := livres.filter(func(casa: Casa) -> bool: return casa.andar >= 3)
		_ocupar(livres, do_andar_3_em_diante, Casa.Tipo.ELITE, rng)
	var resto: Array[Casa.Tipo] = []
	for i in dados.batalhas:
		resto.append(Casa.Tipo.BATALHA)
	for i in dados.descansos - 1:
		resto.append(Casa.Tipo.DESCANSO)
	for i in dados.recompensas:
		resto.append(Casa.Tipo.RECOMPENSA)
	for tipo in resto:
		_ocupar(livres, livres, tipo, rng)


## Sorteia uma casa entre as candidatas, dá a ela o tipo e a tira das livres.
static func _ocupar(livres: Array[Casa], candidatas: Array[Casa], tipo: Casa.Tipo, rng: RandomNumberGenerator) -> void:
	var casa: Casa = candidatas.pop_at(rng.randi_range(0, candidatas.size() - 1))
	casa.tipo = tipo
	livres.erase(casa)
