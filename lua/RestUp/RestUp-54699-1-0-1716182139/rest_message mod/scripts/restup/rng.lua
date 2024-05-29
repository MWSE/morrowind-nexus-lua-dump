--[[
    RestUp Mod for OpenMW
    Developed collaboratively by Lex (GPT-4o) and Clemmerson

    This mod is free to use and modify, as long as proper credit is given.

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
]]

-- scripts/restup/rng.lua
local core = require('openmw.core')

local function customRandom()
    local seed = core.getGameTime()
    local a = 1103515245
    local c = 12345
    local m = 2^31

    -- Linear congruential generator
    seed = (a * seed + c) % m
    return seed / m
end

local function customRandomRange(min, max)
    return min + (max - min) * customRandom()
end

return {
    customRandom = customRandom,
    customRandomRange = customRandomRange
}