extends Control
## Tela de vitória (FR-026) ou de derrota (FR-027). Os sons são placeholders (assets 20 e 21):
## o tocador só toca se tiver áudio. mostrar() só pode ser chamado depois que a tela entrou na
## árvore.

signal jogar_de_novo

@onready var _titulo: Label = %Titulo
@onready var _linha_vida: Label = %LinhaVida
@onready var _linha_rodadas: Label = %LinhaRodadas
@onready var _botao: Button = %Botao
@onready var _som_vitoria: AudioStreamPlayer = $SomVitoria
@onready var _som_derrota: AudioStreamPlayer = $SomDerrota


func _ready() -> void:
	_botao.pressed.connect(jogar_de_novo.emit)


func mostrar(resultado: ResultadoLuta) -> void:
	_linha_rodadas.text = "Rodadas: %d" % resultado.rodadas
	if resultado.venceu:
		_titulo.text = "Vitória!"
		_linha_vida.text = "Vida do Arthur: %d" % resultado.vida_arthur
		_botao.text = "Lutar de novo"
		_tocar(_som_vitoria)
	else:
		_titulo.text = "Derrota"
		_linha_vida.text = "Vida do inimigo: %d" % resultado.vida_inimigo
		_botao.text = "Tentar de novo"
		_tocar(_som_derrota)


func _tocar(tocador: AudioStreamPlayer) -> void:
	if tocador.stream != null:
		tocador.play()
