extends Button
## Uma casa na tela do mapa (FR-012). A cor e a letra são placeholders do ícone da casa (asset
## 27). Os filhos não pegam o mouse, para o clique e a dica chegarem ao botão (research D9).
## mostrar() só pode ser chamado depois que a casa entrou na árvore.

signal escolhida

const LETRAS := {
	Casa.Tipo.BATALHA: "B",
	Casa.Tipo.ELITE: "E",
	Casa.Tipo.DESCANSO: "D",
	Casa.Tipo.RECOMPENSA: "R",
	Casa.Tipo.CHEFE: "C",
}
const CORES := {
	Casa.Tipo.BATALHA: Color(0.55, 0.3, 0.3),
	Casa.Tipo.ELITE: Color(0.75, 0.2, 0.2),
	Casa.Tipo.DESCANSO: Color(0.3, 0.6, 0.35),
	Casa.Tipo.RECOMPENSA: Color(0.75, 0.6, 0.25),
	Casa.Tipo.CHEFE: Color(0.5, 0.2, 0.55),
}
## As dicas não citam números do equilíbrio, que vêm dos dados (FR-027).
const DICAS := {
	Casa.Tipo.BATALHA: "Batalha",
	Casa.Tipo.ELITE: "Elite: inimigo mais forte, dá carta",
	Casa.Tipo.DESCANSO: "Descanso: cura parte da vida",
	Casa.Tipo.RECOMPENSA: "Recompensa: escolha uma carta",
	Casa.Tipo.CHEFE: "Chefe do ato",
}
## Casa que não pode ser escolhida agora.
const ESCURECIDA := Color(0.5, 0.5, 0.5)

@onready var _cor: ColorRect = $Cor
@onready var _moldura: ReferenceRect = $Moldura
@onready var _letra: Label = $Letra


func _ready() -> void:
	pressed.connect(escolhida.emit)


## Disponível: cor cheia e moldura clara; senão, desabilitada e escurecida.
func mostrar(tipo: Casa.Tipo, disponivel: bool) -> void:
	_letra.text = LETRAS[tipo]
	_cor.color = CORES[tipo]
	tooltip_text = DICAS[tipo]
	disabled = not disponivel
	_moldura.visible = disponivel
	modulate = Color.WHITE if disponivel else ESCURECIDA
