class_name ResultadoConta
extends RefCounted
## O que o MotorContas achou de uma sequência de cartas.

## A sequência é uma conta válida (FR-012).
var valida: bool
## Resultado da conta; só tem sentido se valida.
var valor: int


func _init(valida_inicial: bool, valor_inicial: int = 0) -> void:
	valida = valida_inicial
	valor = valor_inicial
