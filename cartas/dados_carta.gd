class_name DadosCarta
extends Resource
## Um tipo de carta (número ou operador). Cada tipo é um arquivo .tres em dados/cartas/;
## duas cartas iguais no baralho apontam para o mesmo arquivo.

enum Tipo { NUMERO, SOMA, SUBTRACAO, MULTIPLICACAO, DIVISAO, DOBRO, METADE, QUADRADO }
enum Efeito { NENHUM, DANO_EXTRA, COMPRAR, ESCUDO, CURA }

## Nome mostrado nas cartas especiais ("Chama"); vazio nas comuns.
@export var nome: String = ""
@export var tipo: Tipo = Tipo.NUMERO
## Valor na conta; só vale para cartas de número.
@export var valor: int = 0
## Dano que a carta soma num acerto.
@export var ataque: int = 0
@export var efeito: Efeito = Efeito.NENHUM
## Força do efeito (3 de dano, 1 carta, 5 de escudo, 2 de cura).
@export var intensidade: int = 0


func eh_numero() -> bool:
	return tipo == Tipo.NUMERO


## Operadores de duas parcelas: +, −, × e ÷.
func eh_binario() -> bool:
	return tipo in [Tipo.SOMA, Tipo.SUBTRACAO, Tipo.MULTIPLICACAO, Tipo.DIVISAO]


## Operadores de uma parcela, aplicados ao número antes deles: x2, /2 e ^2.
func eh_unario() -> bool:
	return tipo in [Tipo.DOBRO, Tipo.METADE, Tipo.QUADRADO]


func simbolo() -> String:
	match tipo:
		Tipo.SOMA:
			return "+"
		Tipo.SUBTRACAO:
			return "−"
		Tipo.MULTIPLICACAO:
			return "×"
		Tipo.DIVISAO:
			return "÷"
		Tipo.DOBRO:
			return "x2"
		Tipo.METADE:
			return "/2"
		Tipo.QUADRADO:
			return "^2"
	return str(valor)


func texto_efeito() -> String:
	match efeito:
		Efeito.DANO_EXTRA:
			return "+%d de dano" % intensidade
		Efeito.COMPRAR:
			return "compra %d" % intensidade
		Efeito.ESCUDO:
			return "+%d de escudo" % intensidade
		Efeito.CURA:
			return "cura %d" % intensidade
	return ""


## Cartas com a mesma chave dão as mesmas contas (o Foco vale o mesmo que um "4"), e a busca
## do alvo as trata como uma só. Números usam o próprio valor (sempre positivo); operadores,
## o tipo com sinal trocado, para nunca coincidir com um número.
func chave_conta() -> int:
	if eh_numero():
		return valor
	return -int(tipo)
