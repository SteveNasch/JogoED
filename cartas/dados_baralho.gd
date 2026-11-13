class_name DadosBaralho
extends Resource
## Lista de cartas de um baralho. Carta repetida aparece duas vezes, apontando para o mesmo
## arquivo de dados/cartas/.

@export var cartas: Array[DadosCarta] = []
