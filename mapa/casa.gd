class_name Casa
extends RefCounted
## Um ponto do mapa de um ato. As casas são criadas pelo GeradorMapa.

enum Tipo { BATALHA, ELITE, DESCANSO, RECOMPENSA, CHEFE }

var tipo: Tipo
## 1 é o primeiro andar; o andar do chefe é o último.
var andar: int
## Posição no andar, da esquerda para a direita, a partir de 0.
var indice: int
## Casas do andar seguinte ligadas a esta, em ordem de índice (vazio no chefe).
var ligacoes: Array[Casa] = []
## O Arthur já passou por ela nesta run.
var visitada: bool = false


func _init(tipo_inicial: Tipo, andar_inicial: int, indice_inicial: int) -> void:
	tipo = tipo_inicial
	andar = andar_inicial
	indice = indice_inicial
