extends Node
## Os sons da luta (assets 15 a 19 e 22). Os tocadores ainda não têm áudio: cada um só toca
## se tiver um, e o arquivo é atribuído no editor quando a equipe entregar (research D15).
## A música toca sozinha pelo autoplay do próprio tocador.

@onready var _carta: AudioStreamPlayer = $Carta
@onready var _acerto: AudioStreamPlayer = $Acerto
@onready var _erro: AudioStreamPlayer = $Erro
@onready var _pulo: AudioStreamPlayer = $Pulo
@onready var _dano_recebido: AudioStreamPlayer = $DanoRecebido


func tocar_carta() -> void:
	_tocar(_carta)


## O som do tipo da rodada e, se o Arthur perdeu vida, também o do dano.
func tocar_rodada(resultado: ResultadoRodada) -> void:
	match resultado.tipo:
		ResultadoRodada.Tipo.ACERTO:
			_tocar(_acerto)
		ResultadoRodada.Tipo.ERRO, ResultadoRodada.Tipo.INVALIDA:
			_tocar(_erro)
		ResultadoRodada.Tipo.PULO:
			_tocar(_pulo)
	if resultado.dano_recebido > 0:
		_tocar(_dano_recebido)


func _tocar(tocador: AudioStreamPlayer) -> void:
	if tocador.stream != null:
		tocador.play()
