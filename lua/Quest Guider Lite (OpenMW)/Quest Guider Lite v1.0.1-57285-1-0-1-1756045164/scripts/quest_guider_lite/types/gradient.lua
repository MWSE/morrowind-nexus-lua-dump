-- Функция для преобразования из HSL в RGB
local function hslToRgb(h, s, l)
    if s == 0 then
        return l, l, l
    end

    local function hueToRgb(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1/6 then return p + (q - p) * 6 * t end
        if t < 1/2 then return q end
        if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
        return p
    end

    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q

    local r = hueToRgb(p, q, h + 1/3)
    local g = hueToRgb(p, q, h)
    local b = hueToRgb(p, q, h - 1/3)

    return r, g, b
end


local numColors = 40
local gradient = {}

for i = 0, numColors - 1 do
    local hue = i / numColors
    local r, g, b = hslToRgb(hue, 0.7, 0.5)
    table.insert(gradient, {r, g, b})
end

return gradient