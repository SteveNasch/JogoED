class_name DadosMapa
extends Resource
## Tamanho do mapa de um ato e quantas casas de cada tipo ele tem (FR-008, FR-011). Fica dentro
## de cada DadosAto, em dados/dificuldade.tres. erros() diz quais valores são impossíveis
## (FR-028).

## O que cabe na tela do mapa (contracts/telas-run.md). Não é equilíbrio: vem da disposição.
const MAXIMO_CASAS_POR_ANDAR := 7
const MAXIMO_ANDARES_COMUNS := 8

## Andares antes do chefe.
@export var andares_comuns: int = 4
## Menor e maior número de casas de um andar comum.
@export var casas_minimas_por_andar: int = 2
@export var casas_maximas_por_andar: int = 3
## Casas do andar 1, todas de batalha.
@export var batalhas_primeiro_andar: int = 3
## Casas do andar 2 em diante, por tipo.
@export var batalhas: int = 3
## Só do andar 3 em diante.
@export var elites: int = 1
## Pelo menos um fica no último andar comum.
@export var descansos: int = 2
@export var recompensas: int = 2


func casas_acima_do_primeiro() -> int:
	return batalhas + elites + descansos + recompensas


## Uma frase por valor impossível, com o nome do campo como aparece no Inspector. As regras de
## distribuição dependem das básicas, por isso só são conferidas quando as básicas passam.
func erros() -> Array[String]:
	var lista := _erros_basicos()
	if lista.is_empty():
		lista.append_array(_erros_de_distribuicao())
	lista.append_array(_erros_de_tela())
	return lista


func _erros_basicos() -> Array[String]:
	var lista: Array[String] = []
	# O andar 1 só tem batalhas e o último andar comum precisa de um descanso: são dois andares.
	if andares_comuns < 2:
		lista.append("andares_comuns (%d) é menor que 2." % andares_comuns)
	if casas_minimas_por_andar < 1:
		lista.append("casas_minimas_por_andar (%d) é menor que 1." % casas_minimas_por_andar)
	if casas_minimas_por_andar > casas_maximas_por_andar:
		lista.append("casas_minimas_por_andar (%d) é maior que casas_maximas_por_andar (%d)." % [casas_minimas_por_andar, casas_maximas_por_andar])
	# Com menos de 2 casas no andar 1 não há dois caminhos (FR-010).
	var menor_primeiro_andar := maxi(2, casas_minimas_por_andar)
	if batalhas_primeiro_andar < menor_primeiro_andar or batalhas_primeiro_andar > casas_maximas_por_andar:
		lista.append("batalhas_primeiro_andar (%d) precisa ficar entre %d e %d." % [batalhas_primeiro_andar, menor_primeiro_andar, casas_maximas_por_andar])
	for campo in ["batalhas", "elites", "descansos", "recompensas"]:
		if get(campo) < 0:
			lista.append("%s (%d) é negativo." % [campo, get(campo)])
	if descansos == 0:
		lista.append("descansos (0) precisa ser pelo menos 1: o ato precisa de uma casa de descanso.")
	return lista


func _erros_de_distribuicao() -> Array[String]:
	var lista: Array[String] = []
	var total := casas_acima_do_primeiro()
	var menor_total := (andares_comuns - 1) * casas_minimas_por_andar
	var maior_total := (andares_comuns - 1) * casas_maximas_por_andar
	if total < menor_total or total > maior_total:
		lista.append("batalhas + elites + descansos + recompensas (%d) precisa ficar entre %d e %d para caber nos andares 2 a %d." % [total, menor_total, maior_total, andares_comuns])
	if elites > 0 and andares_comuns < 3:
		lista.append("elites (%d) precisa de um andar acima do 2, mas andares_comuns é %d." % [elites, andares_comuns])
	elif elites > 0 and elites > _vagas_para_elites():
		lista.append("elites (%d) é maior que as vagas do andar 3 em diante com o andar 2 cheio (%d)." % [elites, _vagas_para_elites()])
	return lista


## Vagas do andar 3 em diante no pior caso, que é o andar 2 sair com o máximo de casas; o −1 é
## o descanso reservado no último andar comum.
func _vagas_para_elites() -> int:
	var total := casas_acima_do_primeiro()
	var andar_2_cheio := mini(casas_maximas_por_andar, total - (andares_comuns - 2) * casas_minimas_por_andar)
	return total - andar_2_cheio - 1


func _erros_de_tela() -> Array[String]:
	var lista: Array[String] = []
	if casas_maximas_por_andar > MAXIMO_CASAS_POR_ANDAR:
		lista.append("casas_maximas_por_andar (%d) é maior que %d, o máximo que cabe na tela." % [casas_maximas_por_andar, MAXIMO_CASAS_POR_ANDAR])
	if andares_comuns > MAXIMO_ANDARES_COMUNS:
		lista.append("andares_comuns (%d) é maior que %d, o máximo que cabe na tela." % [andares_comuns, MAXIMO_ANDARES_COMUNS])
	return lista
