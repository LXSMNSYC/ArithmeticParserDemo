# ArithmeticParserDemo
An Arithmetic Parser Demo using Recursive Descent in Lua

## Features
  * Right-associative addition, subtraction, multiplication and addition.
  * Left-associative exponentiation
  * 'e' notation e.g 1e10
  * Unary
  * Parser error reporting (prints the position of the character error)

## Grammar
This is in ANTLR4 format:
```antlr
expr
  :   sum
  ;
  
sum
  :   prod (('+' | '-')? prod)* 
  ;
  
prod   
  :   pow (('*' | '/')? pow)*
  ;
  
pow
  :   value ('^' pow)*
  ;
  
value:  
  :   digits 
  |   ('(' expr ')')?
  ;
  
digits
  : ('-')? [0-9]* ('.')? [0-9]* ('e' | 'E')? [0-9]*
  ;
```
