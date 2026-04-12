local function onInfoFilter(e)
    if not e.passes then return end

    -- ID диалога
    if e.info.id ~= "8832282682589010235" then return end
    -- Блокируем этот диалог у Греющегося-на-солнце
    if e.reference.baseObject.id == "basks_in_the_sun" then
        e.passes = false
        return
    end
end

local function onInitialized()
    event.register("infoFilter", onInfoFilter)
end
event.register("initialized", onInitialized)