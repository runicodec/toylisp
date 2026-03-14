from enum import StrEnum, auto

NUMBERS = [f'{i}' for i in range(0, 10)]

class InvalidLexemeException(Exception):
    pass

class TokenTypes(StrEnum):
    LPAREN = '('
    RPAREN = ')'
    PLUS = '+'
    MULTIPLY = '*'
    SUBTRACT = '-'
    DIVISION = '/'
    TRUE = 'true'
    FALSE = 'false'
    NUMBER = auto() # compound token, see NUMBERS
    ERROR = auto()

class Token:
    def __init__(self, token_type: TokenTypes, value: int | str | bool = None):
        self.token_type = token_type
        self.value = value

def generate_token(lexeme: str) -> Token:
    new_token = None

    if lexeme in TokenTypes:
        new_token = Token(TokenTypes[lexeme])
    elif lexeme in NUMBERS:
        new_token = Token(TokenTypes.NUMBER, int(lexeme))

    if new_token == None:
        raise InvalidLexemeException

    return new_token


