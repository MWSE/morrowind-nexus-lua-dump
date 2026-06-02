local MapTextures = {}

function MapTextures.build(MAP_ROWS,MAP_COLUMNS,MaskInstalledMods,TAMRIEL_REBUILD_ENABLED,CYRODIIL_ENABLED,SKYRIM_ENABLED)

    local baseMapTexture = {}
    local path
    local realpath

    if (MaskInstalledMods) then
        for row = 0, MAP_ROWS - 1 do
            for col = 0, MAP_COLUMNS - 1 do
                path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-" .. row .. "-" .. col .. ".dds"
                realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mask/Base_Map-" .. row .. "-" .. col .. ".dds"
                baseMapTexture[path] = realpath
            end
        end
        --TAMRIEL_REBUILD_ENABLED = false
        --CYRODIIL_ENABLED = false
        --SKYRIM_ENABLED= false
        if(TAMRIEL_REBUILD_ENABLED) then
            path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-0-4.dds"
            realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mods/Base_Map-0-4.dds"
            baseMapTexture[path] = realpath
            path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-0-5.dds"
            realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mods/Base_Map-0-5.dds"
            baseMapTexture[path] = realpath
            path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-1-4.dds"
            realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mods/Base_Map-1-4.dds"
            baseMapTexture[path] = realpath
            path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-1-5.dds"
            realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mods/Base_Map-1-5.dds"
            baseMapTexture[path] = realpath
            path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-2-4.dds"
            realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mods/Base_Map-2-4.dds"
            baseMapTexture[path] = realpath
        end
        if(CYRODIIL_ENABLED) then
            path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-2-1.dds"
            realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mods/Base_Map-2-1.dds"
            baseMapTexture[path] = realpath
            path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-2-2.dds"
            realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mods/Base_Map-2-2.dds"
            baseMapTexture[path] = realpath
        end
        if(SKYRIM_ENABLED) then
            path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-0-2.dds"
            realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mods/Base_Map-0-2.dds"
            baseMapTexture[path] = realpath
            path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-1-2.dds"
            realpath = "textures/DenyingProduct-Dynamic-Map/Base_Map_Mods/Base_Map-1-2.dds"
            baseMapTexture[path] = realpath
        end
    else
        for row = 0, MAP_ROWS - 1 do
            for col = 0, MAP_COLUMNS - 1 do
                path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-" .. row .. "-" .. col .. ".dds"
                baseMapTexture[path] = path
            end
        end
    end

    return baseMapTexture
end

return MapTextures