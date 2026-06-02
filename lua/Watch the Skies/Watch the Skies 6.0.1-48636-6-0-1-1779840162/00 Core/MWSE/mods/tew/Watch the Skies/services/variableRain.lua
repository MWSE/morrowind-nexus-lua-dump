local variableRain = {}

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

local util = require("tew.Watch the Skies.util")

local defaultGlare = 0.0

local colourKeys = {
    "sunSunriseColor", "sunDayColor", "sunSunsetColor",
    "skySunriseColor", "skyDayColor", "skySunsetColor",
    "fogSunriseColor", "fogDayColor", "fogSunsetColor",
}

-- master rain data
local rainTypes = {
    { threshold = 500,  type = "light",  glare = 1.0, colourSource = 2 },
    { threshold = 1800, type = "medium", glare = 0.7, colourSource = 3 },
    { threshold = 2800, type = "heavy",  glare = 0.0, colourSource = 5 },
}
-- quick lookup by name
local rainLookup = {}
for _, v in ipairs(rainTypes) do
    rainLookup[v.type] = v
end

local defaultColors = nil

function variableRain.getRainType(particleAmount)
    debugLog("Checking rain type for particleAmount = " .. tostring(particleAmount))
    for i = #rainTypes, 1, -1 do
        local r = rainTypes[i]
        if particleAmount >= r.threshold then
            debugLog(string.format("Selected rain type: '%s' (glare: %.2f, threshold: %d)", r.type, r.glare, r.threshold))
            return r.type, r.glare
        end
    end
    local fallback = rainLookup.light
    debugLog(string.format("Fallback to 'light' rain type (glare: %.2f)", fallback.glare))
    return fallback.type, fallback.glare
end

function variableRain.adjustColours(rainType)
    debugLog("Adjusting colours for rainType '" .. rainType .. "'")

    local WtC        = tes3.worldController.weatherController
    local srcIndex   = rainLookup[rainType].colourSource or 5
    local src        = WtC.weathers[srcIndex]
    local dst        = WtC.weathers[5]

    local glare      = rainLookup[rainType].glare or defaultGlare
    local brightness = rainLookup[rainType].brightness or 0.9
    local desat      = rainLookup[rainType].desaturation or 0.72
    local t          = 0.55

    for _, key in ipairs(colourKeys) do
        if src == dst then goto continue end

        local s = src[key]:copy()
        local d = dst[key]:copy()

        local org = d:copy()

        -- === sRGB -> LCh (inline) ===
        local function toLCh(c)
            local lin = {}
            for i = 1, 3 do
                local v = c[i]
                if v > 0.04045 then
                    lin[i] = ((v + 0.055) / 1.055) ^ 2.4
                else
                    lin[i] = v / 12.91
                end
            end

            local x = 0.4123866 * lin[1] + 0.3575915 * lin[2] + 0.1804505 * lin[3]
            local y = 0.2126368 * lin[1] + 0.7151830 * lin[2] + 0.0721802 * lin[3]
            local z = 0.0193306 * lin[1] + 0.1191972 * lin[2] + 0.9503726 * lin[3]

            x = x / 0.95047
            z = z / 1.08883

            local function f(v)
                if v > 0.008856 then
                    return v ^ (1 / 3)
                else
                    return 7.787 * v + 16 / 116
                end
            end

            local fx, fy, fz = f(x), f(y), f(z)

            local L = 116 * fy - 16
            local a = 500 * (fx - fy)
            local b = 200 * (fy - fz)

            local C = math.sqrt(a * a + b * b)
            local H = math.deg(math.atan2(b, a))
            if H < 0 then H = H + 360 end

            return { L, C, H }
        end

        -- === LCh -> sRGB (with chroma containment) ===
        local function toSRGB(LCh)
            local L, C, H = LCh[1], LCh[2], LCh[3]

            local function convert(L, C)
                local a = C * math.cos(math.rad(H))
                local b = C * math.sin(math.rad(H))

                local fy = (L + 16) / 116
                local fx = a / 500 + fy
                local fz = fy - b / 200

                local function f_inv(v)
                    if v ^ 3 > 0.008856 then
                        return v ^ 3
                    else
                        return (v - 16 / 116) / 7.787
                    end
                end

                local x = f_inv(fx) * 0.95047
                local y = f_inv(fy)
                local z = f_inv(fz) * 1.08883

                local r = 3.2410032 * x - 1.5373990 * y - 0.4986159 * z
                local g = -0.9692242 * x + 1.8759300 * y + 0.0415542 * z
                local b2 = 0.0556394 * x - 0.2040112 * y + 1.0571490 * z

                local function gamma(u)
                    if u > 0.0031307 then
                        return 1.055 * u ^ (1 / 2.4) - 0.055
                    else
                        return 12.92 * u
                    end
                end

                return { gamma(r), gamma(g), gamma(b2) }
            end

            -- chroma binary search
            local low, high = 0, C
            local rgb = convert(L, C)

            for _ = 1, 16 do
                local ok = true
                for i = 1, 3 do
                    if rgb[i] < 0 or rgb[i] > 1 then
                        ok = false
                        break
                    end
                end

                if ok then
                    low = C
                else
                    high = C
                end

                if math.abs(high - low) < 0.1 then break end
                C = 0.5 * (low + high)
                rgb = convert(L, C)
            end

            for i = 1, 3 do
                rgb[i] = math.max(0, math.min(1, rgb[i]))
            end

            return rgb
        end

        local sLCh = toLCh({ s.r, s.g, s.b })
        local dLCh = toLCh({ d.r, d.g, d.b })

        -- Hue shortest path
        local h1, h2 = sLCh[3], dLCh[3]
        local dh = h2 - h1
        if dh > 180 then dh = dh - 360 end
        if dh < -180 then dh = dh + 360 end

        -- LCh lerp
        local L = math.lerp(sLCh[1], dLCh[1], t)
        local C = math.lerp(sLCh[2], dLCh[2], t)
        local H = h1 + dh * t

        -- brightness + slight desaturation
        L = L * brightness
        C = C * desat

        local rgb = toSRGB({ L, C, H })

        dst[key].r = rgb[1]
        dst[key].g = rgb[2]
        dst[key].b = rgb[3]

        debugLog(string.format(
            "%s | pre = %.3f %.3f %.3f | post = %.3f %.3f %.3f",
            key,
            org.r, org.g, org.b,
            rgb[1], rgb[2], rgb[3]
        ))

        ::continue::
    end

    dst.glareView = glare

    debugLog(string.format(
        "Applied %s rain colours from weather[%d], glare=%.2f",
        rainType, srcIndex, glare
    ))

    util.updateController()
end

function variableRain.restoreDefaultRainColours()
    local WtC = tes3.worldController.weatherController
    local rainWeather = WtC.weathers[5]
    if not defaultColors then
        debugLog("No default colors saved; nothing to restore")
        return
    end

    debugLog("Restoring default sun, sky, and fog colors")
    for name, col in pairs(defaultColors) do
        rainWeather[name] = col
    end
    rainWeather.glareView = defaultGlare

    util.updateController()
end

function variableRain.storeDefaultRainColours()
    if defaultColors then
        debugLog("Default rain colours already stored")
        return
    end

    local WtC = tes3.worldController.weatherController
    if not WtC then
        debugLog("No weather controller available")
        return
    end

    local rainWeather = WtC.weathers[5]

    defaultColors = {
        glareView = rainWeather.glareView,
    }

    for _, key in ipairs(colourKeys) do
        local c = rainWeather[key]

        defaultColors[key] = {
            r = c.r,
            g = c.g,
            b = c.b,
        }
    end

    debugLog("Stored default rain colours")
end

return variableRain
