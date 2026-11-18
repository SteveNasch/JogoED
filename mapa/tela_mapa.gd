class_name TelaMapa
extends Control
## O mapa de um ato na tela (FR-008, FR-012, FR-013). Cada casa fica numa posição calculada por
## posicao_da_casa(), e só as casas disponíveis podem ser clicadas. Não sabe de vida, baralho
## nem ato. mostrar() só pode ser chamado depois que a tela entrou na árvore.

signal casa_escolhida(casa: Casa)

const CENA_CASA: PackedScene = preload("res://mapa/casa_mapa.tscn")

## Disposição da tela de 640×360 (contracts/telas-run.md).
const Y_DO_CHEFE := 48.0
const Y_DO_ANDAR_1 := 312.0
const X_DO_CENTRO := 320.0
const DISTANCIA_ENTRE_CASAS := 96.0
## A posição calculada é o centro; o botão da casa (32×32) começa no canto de cima e da esquerda.
const METADE_DA_CASA := Vector2(16, 16)

@onready var _casas: Control = $Casas


## Centro da casa na tela: andar 1 embaixo, chefe no topo, andares do meio divididos por igual;
## as casas de um andar centradas, em x crescente com o índice. Arredondado para o pixel.
static func posicao_da_casa(andar: int, indice: int, casas_no_andar: int, total_de_andares: int) -> Vector2:
	var altura_do_andar := (Y_DO_ANDAR_1 - Y_DO_CHEFE) / (total_de_andares - 1)
	var y := Y_DO_ANDAR_1 - (andar - 1) * altura_do_andar
	var x := X_DO_CENTRO + (indice - (casas_no_andar - 1) / 2.0) * DISTANCIA_ENTRE_CASAS
	return Vector2(x, y).round()


## Recria as casas do mapa; só as disponíveis a partir de casa_atual ficam clicáveis.
func mostrar(mapa: MapaAto, casa_atual: Casa) -> void:
	for antiga in _casas.get_children():
		_casas.remove_child(antiga)
		antiga.queue_free()
	var disponiveis := mapa.disponiveis(casa_atual)
	for casa in mapa.casas:
		var no := CENA_CASA.instantiate()
		_casas.add_child(no)
		var casas_no_andar := mapa.casas_do_andar(casa.andar).size()
		no.position = posicao_da_casa(casa.andar, casa.indice, casas_no_andar, mapa.total_de_andares) - METADE_DA_CASA
		no.mostrar(casa.tipo, casa in disponiveis)
		no.escolhida.connect(casa_escolhida.emit.bind(casa))
