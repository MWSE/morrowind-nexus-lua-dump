---@type table<string, fun(factor: number):number>
local this = {}


local function springOutGeneric(x, lambda, w)
    -- Higher lambda = lower swing amplitude. 1 = 150% swing amplitude.
    -- W corresponds to the amount of overswings, more = more. 4.71 = 1 overswing, 7.82 = 2
    return 1 - math.exp(-lambda * x) * math.cos(w * x)
end


function this.linear(x)
    return x
end


function this.sineOut(x)
    return math.sin((x * 3.14) / 2)
end


function this.sineIn(x)
    return 1 - math.cos((x * 3.14) / 2)
end


function this.sineInOut(x)
    return -(math.cos(3.14 * x) - 1) / 2
end


function this.cubicOut(t)
    return 1 - math.pow(1 - t, 3)
end


function this.cubicIn(x)
    return math.pow(x, 3)
end


function this.cubicInOut(x)
    return (x < 0.5) and (4 * x * x * x) or (1 - math.pow(-2 * x + 2, 3) / 2)
end


function this.quartOut(t)
    return 1 - math.pow(1 - t, 4)
end


function this.quartIn(t)
    return math.pow(t, 4)
end


function this.quartInOut(x)
    return (x < 0.5) and (8 * x * x * x * x) or (1 - math.pow(-2 * x + 2, 4) / 2)
end


function this.springOutWeak(x)
    return springOutGeneric(x, 4, 4.71)
end


function this.springOutMed(x)
    return springOutGeneric(x, 3, 4.71)
end


function this.springOutStrong(x)
    return springOutGeneric(x, 2, 4.71)
end


function this.springOutTooMuch(x)
    return springOutGeneric(x, 1, 4.71)
end


return this
