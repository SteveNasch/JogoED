extends Control
## A luta solta da 001, hoje cena de teste da luta: abre no editor com F6 (o F5 abre a run da
## 002). Entrega à tela da luta os dados de dados/, mostra o fim de luta e recomeça do zero com
## semente nova (FR-026, FR-027).

const CENA_TELA: PackedScene = preload("res://batalha/tela_batalha.tscn")

@export var baralho: DadosBaralho
@export var inimigo: DadosInimigo
@export var regras: RegrasBatalha

## A tela da luta em andamento; null enquanto o fim de luta está na tela.
var tela: TelaBatalha

@onready var _fim_de_luta: Control = $FimDeLuta


func _ready() -> void:
	_fim_de_luta.jogar_de_novo.connect(_comecar_luta)
	_comecar_luta()


func _comecar_luta() -> void:
	_fim_de_luta.hide()
	tela = CENA_TELA.instantiate()
	add_child(tela)
	tela.luta_terminou.connect(_ao_terminar_luta)
	tela.iniciar(baralho.cartas, regras.vida_maxima_arthur, inimigo, regras, randi())


func _ao_terminar_luta(resultado: ResultadoLuta) -> void:
	tela.queue_free()
	tela = null
	_fim_de_luta.mostrar(resultado)
	_fim_de_luta.show()
