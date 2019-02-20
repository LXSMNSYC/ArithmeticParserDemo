--[[
    MIT License

    Copyright (c) 2019 Alexis Munsayac

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
--]]

--[[
    Contains the input buffer
--]]
local input
--[[
    Signifies the current character
--]]
local cursor = 1

--[[
    Gets the current character
--]]
local function peek()
    return input:sub(cursor,cursor)
end

--[[
    Checks if there are still characters
    to be read
--]]
local function more()
    return cursor <= #input
end

--[[
    Consumes the current character and 
    moves the next
--]]
local function eat(c)
    if(more() and peek() == c) then
        cursor = cursor + 1
        return true
    end
    return false
end

--[[
    Grammar
    
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
        :   ('-')? [0-9]* (('.')? [0-9]*)? (('e' | 'E')? [0-9]*)?
        ;
    
--]]
local expr, sum, prod, pow, value

local function report(exception)
    error("\n"..exception.." at character "..cursor
          .."\n"..input
          .."\n"..string.rep(" ", cursor - 1).."^"
    , 0)
end

local function digit()
    local r = ""
    
    --[[
        Check for unary operator
        then consume
    --]]
    if(eat("-")) then
        r = "-"
    end
    
    local function digits()
        --[[
            peek and eat until a non-digit character
            is encountered
        --]]
        local n = peek()
        while(n:match("[0-9]") == n) do
            eat(n)
            r = r..n
            n = peek()
        end
    end
    
    --[[
        Get the digits
    --]]
    digits()
    --[[
        Check for decimal notation
    --]]
    if(eat(".")) then
        --[[
            Report for a second decimal point
        --]]
        if(eat(".")) then
            report("malformed number")
        end
        r = r.."."
        --[[
            Get the digits
        --]]
        digits()
        --[[
            Report for another decimal point
        --]]
        if(eat(".")) then
            report("malformed number")
        end
    end
    --[[
        Check for an e notation
    --]]
    if(eat("e") or eat("E")) then
        r = r.."e"
        --[[
            Check if the exponent is a negative
        --]]
        if(eat("-"))then
            r = r.."-"
        end
        --[[
            Report for another e notation
            or a decimal notation
        --]]
        if(eat(".") or eat("e") or eat("E")) then
            report("malformed number")
        end
        --[[
            Get the exponent value
        --]]
        digits()
        --[[
            Report for another e notation
            or a decimal notation
        --]]
        if(eat(".") or eat("e") or eat("E")) then
            report("malformed number")
        end
    end
   
    --[[
        Parse the value
    --]]
    return tonumber(r)
end

value = function ()
    --[[
        Check for grouped expression
    --]]
    if(eat("(")) then
        --[[
            Parse expression
        --]]
        local r = expr()
        --[[
            Close the grouped expression
        --]]
        if(eat(")")) then
            return r
        end
        --[[
            Report if no closing parenthesis
            is detected
        --]]
        report("expected ')'")
    end
    --[[
        otherwise return a value
    --]]
    return digit()
end

pow = function ()
    --[[
        Get the base
    --]]
    local a = value()
    --[[
        Check for the operator
    --]]
    if (eat("^")) then
        --[[
            exponentiation is right-associative, so we need
            to solve first the exponent assuming that it is
            an exponentiaton equation.
        --]]
        local b = pow()
        --[[
            report a malformed equation
        --]]
        if(b == nil) then
            report("malformed equation")
        end
        --[[
            Solve
        --]]
        return a ^ b
    end
    return a
end

product = function ()
    local a = pow()
    
    --[[
        Multiplication and division are left-associative
        so we need to solve a sequence of * and / equations
        
        Peek until the next symbol
        is not a '*' or '/' operators
    --]]
    local n = peek()
    while (n == "*" or n == "/") do
        --[[
            Consume the operator
        --]]
        eat(n)
        --[[
            Assume b as an exponentiation equation
        --]]
        local b = pow()
        --[[
            Report a malformed equation
        --]]
        if(b == nil) then
            report("malformed */ equation")
        end
        --[[
            If the current operator is a division
            operator, do an inverse multiplication
        --]]
        if(n == "/") then
            b = 1/b
        end
        --[[
            Solve
        --]]
        a = a*b
        --[[
            Get the next operator
        --]]
        n = peek()
    end
    return a
end

sum = function()
    local a = product()
    --[[
        Addition and subtraction are left-associative
        so we need to solve a sequence of + and - equations
        
        Peek until the next symbol
        is not a '+' or '-' operators
    --]]
    local n = peek()
    while(n == "+" or n == "-") do
        --[[
            Consume the operator
        --]]
        eat(n)
        --[[
            Assume b as a product equation
        --]]
        local b = product()
        --[[
            Report a malformed equation
        --]]
        if(b == nil) then
            report("malformed +- equation")
        end
        --[[
            If the current operator is a subtraction
            operator, negate the right-hand value
        --]]
        if(n == "-") then
            b = -b
        end
        --[[
            Solve
        --]]
        a = a + b
        --[[
            Get the next operator
        --]]
        n = peek()
    end
    return a
end

expr = function ()
    return sum()
end

local function parse(str)
    --[[
        Clean the input by removing all whitespaces
    --]]
    input = str:gsub("%s", "")
    --[[
        Reset the cursor
    --]]
    cursor = 1
    --[[
        Parse and return
    --]]
    return expr()
end

--[[
    Example
--]]    
print(parse("(17/23e2)*45+-32-2^2.5"))
