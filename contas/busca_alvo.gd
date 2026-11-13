class_name BuscaAlvo
extends RefCounted
## Acha os valores que a mão consegue montar, cada um com uma conta de exemplo, para o alvo da
## rodada ser sempre alcançável (FR-007, research D10). As contas são avaliadas pelo mesmo
## MotorContas que julga o jogador. Recebe os números da faixa e dos freios, e não a
## RegrasBatalha, para a área contas não depender da área batalha.

## Quantas contas a última busca avaliou (para os testes de custo).
var avaliacoes: int = 0

var _alvo_minimo: int
var _alvo_maximo: int
var _max_numeros_no_alvo: int
var _limite_buscas_alvo: int

# Estado da busca em andamento.
var _grupos: Array = []  # cada grupo: Array[DadosCarta] de cartas com a mesma chave_conta()
var _usados: Array[int] = []  # quantas cartas de cada grupo estão na conta
var _conta: Array[DadosCarta] = []
var _achados: Dictionary = {}
var _achados_na_faixa: int = 0


func _init(alvo_minimo: int, alvo_maximo: int, max_numeros_no_alvo: int, limite_buscas_alvo: int) -> void:
	_alvo_minimo = alvo_minimo
	_alvo_maximo = alvo_maximo
	_max_numeros_no_alvo = max_numeros_no_alvo
	_limite_buscas_alvo = limite_buscas_alvo


## Valor (int) → conta de exemplo (Array[DadosCarta]) feita só com cartas da mão.
func alcancaveis(mao: Array[DadosCarta]) -> Dictionary:
	avaliacoes = 0
	_agrupar(mao)
	_conta = []
	_achados = {}
	_achados_na_faixa = 0
	# Primeiro contas de 1 número, depois de 2, até o máximo; para cedo se a faixa já está toda.
	for numeros in range(1, _max_numeros_no_alvo + 1):
		if _deve_parar():
			break
		_buscar(0, numeros)
	return _achados


## O alvo da rodada: sempre um valor que a mão alcança.
func sortear(mao: Array[DadosCarta], rng: RandomNumberGenerator) -> int:
	return escolher_alvo(alcancaveis(mao), rng)


## Sorteia entre os valores achados dentro da faixa, em ordem crescente. Sem nenhum na faixa,
## fica com o positivo mais próximo dela (empate entre um abaixo e um acima: sorteia entre os
## dois). Sem nenhum valor positivo (mão sem números), devolve o mínimo da faixa.
func escolher_alvo(valores: Dictionary, rng: RandomNumberGenerator) -> int:
	var candidatos: Array[int] = []
	for valor: int in valores:
		if valor >= _alvo_minimo and valor <= _alvo_maximo:
			candidatos.append(valor)
	if candidatos.is_empty():
		candidatos = _mais_perto_da_faixa(valores)
	if candidatos.is_empty():
		return _alvo_minimo
	candidatos.sort()
	return candidatos[rng.randi_range(0, candidatos.size() - 1)]


func _mais_perto_da_faixa(valores: Dictionary) -> Array[int]:
	var mais_perto: Array[int] = []
	var menor_distancia := -1
	for valor: int in valores:
		if valor <= 0:
			continue
		var distancia := _alvo_minimo - valor if valor < _alvo_minimo else valor - _alvo_maximo
		if menor_distancia == -1 or distancia < menor_distancia:
			mais_perto = [valor]
			menor_distancia = distancia
		elif distancia == menor_distancia:
			mais_perto.append(valor)
	return mais_perto


## Cartas com a mesma chave dão as mesmas contas: a busca escolhe o grupo, não a carta, e assim
## não repete contas iguais. O grupo guarda as cartas reais para a conta de exemplo usá-las.
func _agrupar(mao: Array[DadosCarta]) -> void:
	_grupos = []
	_usados = []
	var grupo_da_chave := {}
	for carta in mao:
		var chave := carta.chave_conta()
		if not grupo_da_chave.has(chave):
			grupo_da_chave[chave] = _grupos.size()
			_grupos.append([] as Array[DadosCarta])
			_usados.append(0)
		_grupos[grupo_da_chave[chave]].append(carta)


## Monta a conta carta por carta, só pelos caminhos da gramática (FR-012), e avalia as contas
## com exatamente `numeros_da_conta` números (as menores já foram avaliadas antes).
func _buscar(numeros_usados: int, numeros_da_conta: int) -> void:
	if _deve_parar():
		return
	var espera_numero: bool = _conta.is_empty() or _conta.back().eh_binario()
	if not espera_numero and numeros_usados == numeros_da_conta:
		_avaliar()
	for g in _grupos.size():
		if _usados[g] == _grupos[g].size():
			continue
		var carta: DadosCarta = _grupos[g][_usados[g]]
		if carta.eh_numero() != espera_numero:
			continue
		if carta.eh_binario() and numeros_usados == numeros_da_conta:
			continue
		_usados[g] += 1
		_conta.append(carta)
		_buscar(numeros_usados + (1 if carta.eh_numero() else 0), numeros_da_conta)
		_conta.pop_back()
		_usados[g] -= 1


func _avaliar() -> void:
	avaliacoes += 1
	var resultado := MotorContas.avaliar(_conta)
	if not resultado.valida or _achados.has(resultado.valor):
		return
	_achados[resultado.valor] = _conta.duplicate()
	if resultado.valor >= _alvo_minimo and resultado.valor <= _alvo_maximo:
		_achados_na_faixa += 1


## Para quando a faixa inteira já foi achada ou quando chega ao teto de avaliações.
func _deve_parar() -> bool:
	return avaliacoes >= _limite_buscas_alvo or _achados_na_faixa == _alvo_maximo - _alvo_minimo + 1
