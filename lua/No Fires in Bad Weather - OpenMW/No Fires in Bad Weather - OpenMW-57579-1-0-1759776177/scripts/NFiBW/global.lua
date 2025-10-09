-- Importa los módulos necesarios de OpenMW
local types = require('openmw.types')      -- Acceso a tipos de objetos del juego (como luces)
local world = require('openmw.world')      -- Manipulación del mundo del juego (crear, mover, eliminar objetos)

-- Lista de luces activas en exteriores que serán evaluadas en cada ciclo
local activeLights = {}

-- Índice de iteración para recorrer la lista de luces activas
local iterateLights = nil

-- Tabla que define los tipos de clima considerados "malos"
-- Estos climas provocarán el apagado de ciertas luces
local badWeather = {
    [4] = true,  -- Lluvia
    [5] = true,  -- Tormenta eléctrica
--  [6] = true,  -- Tormenta de ceniza (no creo que debería apagar un fuego)
--  [7] = true,  -- Plaga (no veo como podria apagar un fuego)
--  [8] = true,  -- Nieve (al ser ligera probablemente no apague el fuego)
    [9] = true   -- Ventisca
}

-- Lista de patrones que identifican luces que deben apagarse en mal clima
-- Ejemplo: antorchas, fogatas, braseros
local whitelistPatterns = {
	"torch",
	"candle",
	"pitfire",
	"firepit",
	"Light_Fire_300",
}

-- Función que obtiene el clima actual desde el script global 'wetfire_weather_monitor'
-- Retorna un número que representa el tipo de clima
local function getCurrentWeather()
    return world.mwscript.getGlobalScript("wetfire_weather_monitor").variables.actweather
end

-- Función que se ejecuta cada frame del motor
-- Procesa una luz activa por ciclo, evaluando si debe apagarse o encenderse según el clima
local function onUpdate(dt)
    if dt == 0 then return end  -- Ignora actualizaciones sin avance de tiempo

    -- Avanza al siguiente objeto en la lista de luces activas
    iterateLights, light = next(activeLights, iterateLights)

    if light then
        -- Si la luz ya no es válida o ha sido eliminada, se remueve de la lista
        if not light:isValid() or light.count == 0 then
            table.remove(activeLights, iterateLights)
        else
            -- Obtiene el clima actual y determina si es considerado "malo"
            local isBad = badWeather[getCurrentWeather()] == true

            -- Si el clima es bueno y la luz está apagada, se restaura su versión original
            if not isBad and saveData.reverseRecordLookup[light.recordId] then
                local pos, cell, rot, count = light.position, light.cell, light.rotation, light.count
                light:remove()
                world.createObject(saveData.reverseRecordLookup[light.recordId], count)
                    :teleport(cell, pos, { rotation = rot })

            -- Si el clima es malo y la luz aún no ha sido apagada, se reemplaza por una versión apagada
            elseif isBad and not saveData.reverseRecordLookup[light.recordId] then
                -- Si no existe aún un registro apagado para esta luz, se crea
                if not saveData.generatedRecords[light.recordId] then
                    local original = types.Light.record(light)
                    local draft = { template = original, isOffByDefault = true }

                    local newRecord = world.createRecord(types.Light.createRecordDraft(draft))
                    saveData.generatedRecords[light.recordId] = newRecord.id
                    saveData.reverseRecordLookup[newRecord.id] = light.recordId
                end

                -- Se reemplaza la luz por su versión apagada
                local pos, cell, rot, count = light.position, light.cell, light.rotation, light.count
                light:remove()
                world.createObject(saveData.generatedRecords[light.recordId], count)
                    :teleport(cell, pos, { rotation = rot })
            end
        end
    end
end

-- Función que se ejecuta cuando un objeto se activa en el mundo
-- Evalúa si el objeto es una luz válida para ser procesada por el sistema
local function onObjectActive(object)
    if types.Light.objectIsInstance(object) then
        -- Verifica si el objeto coincide con alguno de los patrones permitidos
        local validRecord = false
        for _, pattern in pairs(whitelistPatterns) do
            if object.recordId:find(pattern) then
                validRecord = true
                break
            end
        end

        -- Si no es una luz permitida ni una luz previamente apagada, se ignora
        if not saveData.reverseRecordLookup[object.recordId] and not validRecord then return end

        -- Solo se procesan luces en exteriores o cuasi-exteriores
        if object.cell.isExterior or object.cell.isQuasiExterior then
            table.insert(activeLights, object)
        end
    end
end

-- Función que se ejecuta al cargar el módulo
-- Inicializa o restaura los datos persistentes del sistema
local function onLoad(data)
    saveData = data or {
        generatedRecords = {},        -- Registros creados para versiones apagadas
        reverseRecordLookup = {}      -- Mapeo inverso para restaurar luces originales
    }
end

-- Función que guarda los datos persistentes del sistema
local function onSave()
    return saveData
end

-- Registro de funciones que el motor de OpenMW debe ejecutar
return {
    engineHandlers = {
        onUpdate = onUpdate,               -- Ciclo de actualización por frame
        onObjectActive = onObjectActive,   -- Activación de objetos en el mundo
        onLoad = onLoad,                   -- Carga de datos persistentes
        onInit = onLoad,                   -- Inicialización (usa misma lógica que onLoad)
        onSave = onSave,                   -- Guardado de datos persistentes
    },
}