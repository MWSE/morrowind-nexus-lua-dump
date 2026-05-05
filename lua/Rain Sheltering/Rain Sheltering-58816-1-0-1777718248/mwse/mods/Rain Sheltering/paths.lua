--- Строит полный маршрут с учетом ручных путей

local M = {}

local balmoraSouthmostY = -20525
local balmoraEastmostX = -14297

local balmoraSouthGates = {
    {   -- rooftop, силтстрайдер. И между ними
        minX = -21560, maxX = -21035,
        minY = -17906, maxY = -16224,
        points = {
            {x = -20881, y = -16907, z = 443}, -- вниз по лестнице
            {x = -20863, y = -16285, z = 315},
            {x = -20258, y = -16312, z = 162},
        }
    },
    {   -- перед тюрягой
        minX = -22878, maxX = -21560,
        minY = -17906, maxY = -16867,
        points = {
            {x = -23149, y = -16867, z = 506},  -- обход тюряги по площади
            {x = -23113, y = -15866, z = 503},
        }
    },
    {   -- восточнее лестницы силтстрайдера, и до реки
        minX = -20872, maxX = -19550,
        minY = -17510, maxY = -16777,
        points = {
            {x = -20040, y = -16226, z = 162},  -- точка между лестницей и рекой
        }
    },
}

local pelagiadTavern = {
    {
        minX = 1880, maxX = 2860,
        minY = -56400, maxY = -55700,
        points = {
            {x = 2384, y = -56753, z = 1498},
        },
        notInRange = true,
    },
}

local gnisisPavilion = {
    {   -- южнее павильона
        minX = -89566, maxX = -79840,
        minY = 96354, maxY = 85000,
        points = {
            {x = -86750, y = 96469, z = 1556},
        },
    },
}

local function inRange(val, min, max)
    return val > min and val < max
end

local function notInRange(val, min, max)
    return val < min or val > max
end

-- Маршрут подхода к укрытию, если NPC выбрал его, и находится в указанном range
local shelterZones = {
    -- Balmora
    ["nalcarya"] = {
        {   -- площадка вниз по лестнице
            minX = -23810, maxX = -22280,
            minY = -11650, maxY = -9750,
            points = {
                {x = -23350, y = -10600, z = 719},
                {x = -24226, y = -10580, z = 962},
               {x = -24842, y = -10599, z = 962}
            }
        },
    },
    ["raVirr_alley"] = {
        {   -- rooftop, силтстрайдер, южные врата. И все что между ними
            minX = -22878, maxX = -21035,
            minY = -17906, maxY = -16224,
            points = {
                {x = -23149, y = -16867, z = 506},  -- обход тюряги по площади
                {x = -23113, y = -15866, z = 503},
            }
        },
    },
    ["mages_guild"] = balmoraSouthGates,
    ["fighters_guild"] = balmoraSouthGates,
    ["alley_1"] = balmoraSouthGates,
    ["alley_2"] = balmoraSouthGates,
    ["alley_4"] = {
        {
            minX = -20867, maxX = balmoraEastmostX, -- восточнее выхода с лестницы в проулок
            minY = balmoraSouthmostY, maxY = -12102, -- южнее двери в дом Итана
            points = {
                {x = -21030, y = -12654, z = 274},
            }
        },
    },
    ["rararyn_house"] = {   -- надо проход по лестницам здесь тоже перенести в middle-зоны
        {   -- с крайней восточной улицы (вверх по лестницам)
            minX = -16038, maxX = balmoraEastmostX,
            minY = -16120, maxY = -12172,
            points = {
                {x = -15816, y = -12988, z = 411},  -- вниз по северным лестницам
                {x = -16689, y = -13016, z = 170},
            }
        },
    },
    ["drarayne_alley"] = {
        {   -- с крайней восточной улицы (вверх по лестницам)
            minX = -16038, maxX = balmoraEastmostX,
            minY = -16120, maxY = -12172,
            points = {
                {x = -15752, y = -15316, z = 418},  -- вниз по южным лестницам
                {x = -16674, y = -15311, z = 170},
            }
        },
    },
    -- Pelagiad
    ["tavern_1"] = pelagiadTavern,
    ["tavern_2"] = pelagiadTavern,
    -- Gnisis
    ["pavilion_1"] = gnisisPavilion,
    ["pavilion_2"] = gnisisPavilion,
    ["pavilion_3"] = gnisisPavilion,
}

---@param originPoint tes3vector3
---@param shelterName string
---@return {x: number, y: number, z: number}[]|nil
M.getShelterZonePath = function(originPoint, shelterName)
    local zones = shelterZones[shelterName]
    if not zones then
        return nil -- если записи по этому имени нет
    end

    -- Перебираем все зоны, зарегистрированные для данного shelterName
    for _, zone in ipairs(zones) do
        local check = zone.notInRange and notInRange or inRange
        local inX = check(originPoint.x, zone.minX, zone.maxX)
        local inY = check(originPoint.y, zone.minY, zone.maxY)

        if inX and inY then
            return zone.points
        end
    end

    return nil
end

-- Маршрут выхода NPC, если origin находится в range
local originZones = {
    -- Balmora
    ["rooftop_dranas"] = {
        {   -- rooftop за столом
            minX = -21337, maxX = -21035,
            minY = -16719, maxY = -16480,
            points = {
                {x = -21242, y = -16379, z = 834},
                {x = -21498, y = -16442, z = 834},
                {x = -21650, y = -16950, z = 490}
            }
        },
    },
    ["rooftop_tedryn"] = {
        {
            minX = -21337, maxX = -21035,
            minY = -16480, maxY = -16224,
            points = {
                {x = -21650, y = -16950, z = 490}
            }
        },
    },
    ["rooftop_rest"] = {
        {   -- оставшаяся часть, левее от них. Включая лестницу.
            minX = -21783, maxX = -21337,
            minY = -16719, maxY = -16224,
            points = {
                {x = -21650, y = -16950, z = 490}
            }
        },
    },
    ["south_of_the_gate"] = {
        {   -- южнее ворот силтстрайдера
            minX = -23796, maxX = balmoraEastmostX,
            minY = -17640, maxY = balmoraSouthmostY,
            points = {
                {x = -22793, y = -17640, z = 394}
            }
        },
    },
    --[[ Sadrith Mora
    ["rolis_garvon_house"] = {
        {
            minX = 150525, maxX = 150793,
            minY = 39973, maxY = 40165,
            points = {
                {x = 150238, y = 39665, z = 842},
            }
        },
    } ]]--
}

---@param originPoint tes3vector3
---@return {x: number, y: number, z: number}[]|nil
M.getOriginZonePath = function(originPoint)
    for _, data in pairs(originZones) do
        for _, zone in ipairs(data) do
            local check = zone.notInRange and notInRange or inRange
            local inX = check(originPoint.x, zone.minX, zone.maxX)
            local inY = check(originPoint.y, zone.minY, zone.maxY)

            if inX and inY then
                return zone.points
            end
        end
    end
    return nil -- Возвращается, если точка не попала ни в одну зону
end

--- Пути через мосты

-- Таблицы берегов (Y, X)
local westBank = {
    ["Balmora"] = {
	    {-10429, -18704},
        {-11096, -18772},
        {-12057, -19210},
        {-12803, -19712},
        {-14743, -19815},
        {-16620, -19562},
        {-17506, -19556},
    },
    ["Ebonheart"] = {
        {-99000, 16044},
        {-105000, 16044},
    },
}
local eastBank = {
    ["Balmora"] = {
	    {-10430, -17733},
        {-12803, -18843},
        {-13743, -18939},
        {-15012, -18893},
        {-16418, -18711},
        {-17505, -18606},
    },
    ["Ebonheart"] = {
        {-99000, 17142},
        {-105000, 17142},
    },
}

M.hasBridge = function(cellKey)
    return westBank[cellKey] ~= nil
end

-- Функция линейной интерполяции для поиска X границы берега в точке Y
local function getBoundaryX(points, y)
    -- Быстрая проверка краев
    local first, last = points[1], points[#points]
    if y >= first[1] then return first[2] end
    if y <= last[1] then return last[2] end

    -- Ищем нужный сегмент
    for i = 1, #points - 1 do
        local p1, p2 = points[i], points[i+1]
        local y1, y2 = p1[1], p2[1]
        if y <= y1 and y >= y2 then
            -- Линейная интерполяция
            return p1[2] + (p2[2] - p1[2]) * (y - y1) / (y2 - y1)
        end
    end
end

M.onWhichSideOfRiver = function(cellKey, x, y)
	local westX = getBoundaryX(westBank[cellKey], y)
	local eastX = getBoundaryX(eastBank[cellKey], y)
	-- Сравнение (учитывая, что координаты отрицательные: чем "меньше" число, тем западнее берег)
	if x <= westX then
		return "west"
	elseif x >= eastX then
		return "east"
	else
		return "on bridge"
	end
end

-- Западная точка входа на каждый мост
M.westBridges = {
    ["Balmora"] = {
        {x = -19960, y = -12941, z = 184},
        {x = -19993, y = -14890, z = 184},
        {x = -19785, y = -16522, z = 184}
    },
    ["Ebonheart"] = {
        {x = 15596, y = -101929, z = 613}
    },
}
M.eastBridges = {
    ["Balmora"] = {
        {x = -18657, y = -12961, z = 184},
        {x = -18686, y = -14912, z = 184},
        {x = -18492, y = -16540, z = 184},
    },
    ["Ebonheart"] = {
        {x = 17267, y = -101928, z = 450}
    },
}

return M