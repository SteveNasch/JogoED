class_name MapaAto
extends RefCounted
## As casas de um ato, geradas pelo GeradorMapa.

## Todas as casas, por andar e, dentro do andar, por índice. É uma lista só porque o GDScript
## ainda não aceita lista tipada dentro de lista tipada (research D5).
var casas: Array[Casa] = []
## Andares comuns mais o andar do chefe.
var total_de_andares: int


func casas_do_andar(andar: int) -> Array[Casa]:
	return casas.filter(func(casa: Casa) -> bool: return casa.andar == andar)


## Para onde o Arthur pode ir (FR-013): sem casa atual (antes do primeiro andar), as casas do
## andar 1; senão, as ligações da casa atual. A Run e a tela do mapa usam esta função.
func disponiveis(atual: Casa) -> Array[Casa]:
	if atual == null:
		return casas_do_andar(1)
	return atual.ligacoes.duplicate()
