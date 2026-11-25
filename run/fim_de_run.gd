extends Control
## Fim da run, por vitória ou derrota (FR-024): até onde o Arthur chegou e quantas lutas venceu,
## lidos da Run. mostrar() só pode ser chamado depois que a tela entrou na árvore.

signal jogar_de_novo

@onready var _titulo: Label = %Titulo
@onready var _onde: Label = %Onde
@onready var _lutas: Label = %Lutas
@onready var _botao: Button = %Botao


func _ready() -> void:
	_botao.pressed.connect(jogar_de_novo.emit)


func mostrar(run: Run) -> void:
	var lugar := "ato %d (%s), andar %d" % [run.ato, run.dados_do_ato().nome, run.andar_alcancado()]
	if run.etapa == Run.Etapa.VITORIA:
		_titulo.text = "Vitória!"
		_onde.text = "Arthur venceu o chefe do %s." % lugar
	else:
		_titulo.text = "Fim da run"
		_onde.text = "Arthur caiu no %s." % lugar
	_lutas.text = "Lutas vencidas: %d" % run.lutas_vencidas
