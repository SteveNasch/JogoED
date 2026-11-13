class_name ResultadoRodada
extends RefCounted
## O que aconteceu numa rodada, para a tela mostrar (FR-025) e os testes conferirem.

enum Tipo { ACERTO, ERRO, INVALIDA, PULO }

var tipo: Tipo
## Alvo da rodada.
var alvo: int
## Valor da conta (em ACERTO e ERRO).
var valor: int = 0
## Dano calculado, mesmo que passe da vida que o inimigo ainda tinha (o aviso mostra esse número).
var dano_causado: int = 0
## Escudo dado ao Arthur.
var escudo_ganho: int = 0
## Vida que o Arthur recuperou de fato.
var cura: int = 0
## Cartas extras que entraram na mão (Foco ou Pular).
var cartas_compradas: int = 0
## Falso só quando o inimigo caiu nesta rodada.
var inimigo_atacou: bool = false
## Vida que o Arthur perdeu no ataque do inimigo (0 se o escudo segurou tudo).
var dano_recebido: int = 0
## Alguém chegou a 0 de vida nesta rodada.
var luta_acabou: bool = false


func _init(tipo_inicial: Tipo, alvo_inicial: int) -> void:
	tipo = tipo_inicial
	alvo = alvo_inicial
