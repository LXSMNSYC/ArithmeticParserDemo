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
    
    expr:   sum
    sum:    prod (('+' | '-')? prod)* 
    prod:   pow (('*' | '/')? pow)*
    pow:    value ('^' pow)*
    value:  digits | ('(' expr ')')?
    digits: ('-')? [0-9]* ('.')? [0-9]* ('e' | 'E')? [0-9]*
    
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
    if(eat("-")) then
        r = "-"
    end
    
    local function digits()
        local n = peek()
        while(n:match("[0-9]") == n) do
            eat(n)
            r = r..n
            n = peek()
        end
    end
    
    digits()
    if(eat(".")) then
        if(eat(".")) then
            report("malformed number")
        end
        r = r.."."
        digits()
        if(eat(".")) then
            report("malformed number")
        end
    end
    if(eat("e") or eat("E")) then
        r = r.."e"
        if(eat("-"))then
            r = r.."-"
        end
        if(eat(".") or eat("e") or eat("E")) then
            report("malformed number")
        end
        digits()
        if(eat(".") or eat("e") or eat("E")) then
            report("malformed number")
        end
        
    end
   
    return tonumber(r)
end

value = function ()
    if(eat("(")) then
        local r = expr()
        if(eat(")")) then
            return r
        end
        report("expected ')'")
    end
    return digit()
end

pow = function ()
    local a = value()
    if (eat("^")) then
        local b = pow()
        if(b == nil) then
            report("malformed equation")
        end
        return a ^ b
    end
    return a
end

product = function ()
    local a = pow()
    local n = peek()
    while (n == "*" or n == "/") do
        eat(n)
        local b = pow()
        if(b == nil) then
            report("malformed */ equation")
        end
        if(n == "/") then
            b = 1/b
        end
        a = a*b
        n = peek()
    end
    return a
end

sum = function()
    local a = product()
    local n = peek()
    while(n == "+" or n == "-") do
        eat(n)
        local b = product()
        if(b == nil) then
            report("malformed +- equation")
        end
        if(n == "-") then
            b = -b
        end
        a = a + b
        n = peek()
    end
    return a
end

expr = function ()
    return sum()
end

local function parse(str)
    input = str:gsub("%s", "")
    cursor = 1
    return expr()
end

print(parse("(17/23)*45+32 - 2^2e2"))
