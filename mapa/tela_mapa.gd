class_name TelaMapa
extends Control
## O mapa de um ato na tela (FR-008, FR-012, FR-013). Cada casa fica numa posição calculada por
## posicao_da_casa(), e só as casas disponíveis podem ser clicadas. As ligações são desenhadas
## no _draw(), por baixo das casas, e o marcador do Arthur fica por cima. As linhas e o marcador
## são placeholders (assets 28 e 29). Não sabe de vida, baralho nem ato. mostrar() só pode ser
## chamado depois que a tela entrou na árvore.

signal casa_escolhida(casa: Casa)

const CENA_CASA: PackedScene = preload("res://mapa/casa_mapa.tscn")

## Disposição da tela de 640×360 (contracts/telas-run.md).
const Y_DO_CHEFE := 48.0
const Y_DO_ANDAR_1 := 312.0
const X_DO_CENTRO := 320.0
const DISTANCIA_ENTRE_CASAS := 96.0
## A posição calculada é o centro; o botão da casa (32×32) começa no canto de cima e da esquerda.
const METADE_DA_CASA := Vector2(16, 16)
## Centro do marcador do Arthur antes do primeiro andar; numa casa, ele fica no canto de cima e
## da esquerda dela.
const MARCADOR_ANTES_DO_ANDAR_1 := Vector2(320, 344)

## Cores das ligações (placeholder da trilha, asset 29).
const COR_COMUM := Color(0.45, 0.45, 0.45)
const COR_PERCORRIDA := Color(0.95, 0.95, 0.95)
const COR_DISPONIVEL := Color(0.95, 0.8, 0.3)
## Largura par: a linha não precisa ser deslocada meio pixel (research D9).
const LARGURA_DA_LIGACAO := 2.0

var _mapa: MapaAto
var _casa_atual: Casa

@onready var _casas: Control = $Casas
@onready var _marcador: ColorRect = $Marcador


## Centro da casa na tela: andar 1 embaixo, chefe no topo, andares do meio divididos por igual;
## as casas de um andar centradas, em x crescente com o índice. Arredondado para o pixel.
static func posicao_da_casa(andar: int, indice: int, casas_no_andar: int, total_de_andares: int) -> Vector2:
	var altura_do_andar := (Y_DO_ANDAR_1 - Y_DO_CHEFE) / (total_de_andares - 1)
	var y := Y_DO_ANDAR_1 - (andar - 1) * altura_do_andar
	var x := X_DO_CENTRO + (indice - (casas_no_andar - 1) / 2.0) * DISTANCIA_ENTRE_CASAS
	return Vector2(x, y).round()


## Cor de uma ligação: amarela da casa atual para uma disponível, branca entre duas casas
## visitadas (o caminho percorrido), cinza nas outras.
static func cor_da_ligacao(de: Casa, para: Casa, casa_atual: Casa) -> Color:
	if de == casa_atual:
		return COR_DISPONIVEL
	if de.visitada and para.visitada:
		return COR_PERCORRIDA
	return COR_COMUM


## Recria as casas do mapa, põe o marcador do Arthur e redesenha as ligações; só as casas
## disponíveis a partir de casa_atual ficam clicáveis.
func mostrar(mapa: MapaAto, casa_atual: Casa) -> void:
	_mapa = mapa
	_casa_atual = casa_atual
	_mostrar_casas(mapa, casa_atual)
	if casa_atual == null:
		_marcador.position = MARCADOR_ANTES_DO_ANDAR_1 - _marcador.size / 2
	else:
		_marcador.position = _centro(casa_atual) - METADE_DA_CASA
	queue_redraw()


func _draw() -> void:
	if _mapa == null:
		return
	for casa in _mapa.casas:
		for outra in casa.ligacoes:
			draw_line(_centro(casa), _centro(outra), cor_da_ligacao(casa, outra, _casa_atual), LARGURA_DA_LIGACAO)


func _mostrar_casas(mapa: MapaAto, casa_atual: Casa) -> void:
	for antiga in _casas.get_children():
		_casas.remove_child(antiga)
		antiga.queue_free()
	var disponiveis := mapa.disponiveis(casa_atual)
	for casa in mapa.casas:
		var no := CENA_CASA.instantiate()
		_casas.add_child(no)
		no.position = _centro(casa) - METADE_DA_CASA
		no.mostrar(casa.tipo, casa in disponiveis)
		no.escolhida.connect(casa_escolhida.emit.bind(casa))


func _centro(casa: Casa) -> Vector2:
	return posicao_da_casa(casa.andar, casa.indice, _mapa.casas_do_andar(casa.andar).size(), _mapa.total_de_andares)
