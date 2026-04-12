-- Data Files/MWSE/mods/RegionLoadingMod/main.lua

local MOD_NAME = "RegionLoadingMod"
local configPath = "RegionLoadingMod_config"
local config = mwse.loadConfig(configPath, { saves = {} })
local lfs = require("lfs")

local regionSplashMap = {
--Name of Region			Folder

--Morrowind Basegame
["ascadian isles region"] = "01_Morrowind_Basegame",
["ashlands region"] = "01_Morrowind_Basegame",
["azura's coast region"] = "01_Morrowind_Basegame",
["bitter coast region"] = "01_Morrowind_Basegame",
["molag amur region"] = "01_Morrowind_Basegame",
["red mountain region"] = "01_Morrowind_Basegame",
["sheogorad region"] = "01_Morrowind_Basegame",
["grazelands region"] = "01_Morrowind_Basegame",
["west gash region"] = "01_Morrowind_Basegame",
["sea of ghosts"] = "01_Morrowind_Basegame",
--Morrowind Tribunal
["mournhold region"] = "02_Morrowind_Tribunal",
--Morrowind Bloodmoon
["solstheim, brodir grove region"] = "03_Morrowind_Bloodmoon",
["solstheim, felsaad coast region"] = "03_Morrowind_Bloodmoon",
["solstheim, hirstaang forest"] = "03_Morrowind_Bloodmoon",
["solstheim, isinfier plains"] = "03_Morrowind_Bloodmoon",
["solstheim, moesring mountains"] = "03_Morrowind_Bloodmoon",
["thirsk region"] = "03_Morrowind_Bloodmoon",
--Tamriel Rebuilt Telvannis
["telvanni isles"] = "04_Tamriel_Rebuilt_Telvannis",
["dagon urul region"] = "04_Tamriel_Rebuilt_Telvannis",
["sunad mora region"] = "04_Tamriel_Rebuilt_Telvannis",
--Tamriel Rebuilt Antediluvian Secrets
["boethiah's spine region"] = "05_Tamriel_Rebuilt_Antediluvian_Secrets",
["molag ruhn region"] = "05_Tamriel_Rebuilt_Antediluvian_Secrets",
--Tamriel Rebuilt Sacred East
["sacred lands region"] = "06_Tamriel_Rebuilt_Sacred_East",
["mephalan vales region"] = "06_Tamriel_Rebuilt_Sacred_East",
["sundered scar region"] = "06_Tamriel_Rebuilt_Sacred_East",
--Tamriel Rebuilt Aanthirin
["aanthirin region"]      = "08_Tamriel_Rebuilt_Aanthirin",
--Tamriel Rebuilt Dominions of Dusk
["roth roryn region"] = "09_Tamriel_Rebuilt_Dominions_of_Dusk",
["armun ashlands region"] = "09_Tamriel_Rebuilt_Dominions_of_Dusk",
--Tamriel Rebuilt Andaram
["othreleth woods region"] = "11_Tamriel_Rebuilt_Andaram",
--Tamriel Rebuilt Grasping Fortune
["coronati basin region"] = "13_Tamriel_Rebuilt_Grasping_Fortune",
["shipal-shin region"]    = "13_Tamriel_Rebuilt_Grasping_Fortune",
--Skyrim Home of the Nords Karthwasten
["lorchwuir heath region"]    = "20_Skyrim_Home_of_the_Nords_Karthwasten",
["vorndgad forest region"]    = "20_Skyrim_Home_of_the_Nords_Karthwasten",
--Skyrim Home of the Nords Dragonstar
["druadach highlands region"]    = "21_Skyrim_Home_of_the_Nords_Dragonstar",
--Project Cyrodiil Abecean_Shores
["stirk isle region"]    = "30_Project_Cyrodiil_Abecean_Shores",
["abecean sea region"]    = "30_Project_Cyrodiil_Abecean_Shores",
["dasek marsh region"]    = "30_Project_Cyrodiil_Abecean_Shores",
["strident coast region"]    = "30_Project_Cyrodiil_Abecean_Shores",
}

local cellSplashMap = {
--Morrowind Tribunal
["mournhold"] = "02_Morrowind_Tribunal",
["sotha sil"] = "02_Morrowind_Tribunal",
--Morrowind Bloodmoon
["mortrag glacier"] = "03_Morrowind_Bloodmoon",
--Tamriel Rebuilt Old Ebonheart
["old ebonheart"] = "07_Tamriel_Rebuilt_Old_Ebonheart",
--Tamriel Rebuilt Firemoth
["firemoth"] = "10_Tamriel_Rebuilt_Firemoth",
--Tamriel Rebuilt Andaram
["almas thirr"] = "11_Tamriel_Rebuilt_Andaram",
--Tamriel Rebuilt Embers of Empire
["firewatch"] = "12_Tamriel_Rebuilt_Embers_of_Empire",
["helnim"] = "12_Tamriel_Rebuilt_Embers_of_Empire",
}

-- Zustandsvariablen
local imageCache = {}
local currentSessionFolder = nil
local pendingFolder = nil
local isSaving = false
local enforceTimer = nil
local slideshowTimer = nil

-------------------------------------------------------------------------
-- Hilfsfunktionen
-------------------------------------------------------------------------

-- Bilder beim Start einmalig einlesen (Pre-Caching), anstatt bei jedem Laden!
local function cacheImages()
    local basePath = "Data Files\\Splash\\"
    
    local function scanFolder(folder)
        if not imageCache[folder] then imageCache[folder] = {} end
        local path = basePath .. folder
        if lfs.directoryexists(path) then
            for file in lfs.dir(path) do
                if file:lower():match("%.tga$") then
                    table.insert(imageCache[folder], "Splash\\" .. folder .. "\\" .. file)
                end
            end
        end
    end

    for _, folder in pairs(regionSplashMap) do scanFolder(folder) end
    for _, folder in pairs(cellSplashMap) do scanFolder(folder) end
end

-- Sucht die nächste Außenzelle (Breitensuche)
local function findLinkedRegion(startCell)
    if not startCell.isInterior then
        return startCell.region and startCell.region.name:lower() or nil
    end

    local visited = {}
    local queue = { startCell }
    local foundRegions = {}
    local steps = 0

    while #queue > 0 and steps < 50 do
        steps = steps + 1
        local current = table.remove(queue, 1)
        visited[current.id:lower()] = true

        for ref in current:iterateReferences(tes3.objectType.door) do
            if ref.destination and ref.destination.cell then
                local dest = ref.destination.cell
                if not dest.isInterior then
                    if dest.region then
                        local r = dest.region.name:lower()
                        if not table.find(foundRegions, r) then 
                            table.insert(foundRegions, r) 
                        end
                    end
                elseif not visited[dest.id:lower()] then
                    table.insert(queue, dest)
                    visited[dest.id:lower()] = true
                end
            end
        end
    end
    
    if #foundRegions > 0 then
        return foundRegions[math.random(#foundRegions)]
    end
    return nil
end

local function stopTimers()
    if enforceTimer then enforceTimer:cancel(); enforceTimer = nil end
    if slideshowTimer then slideshowTimer:cancel(); slideshowTimer = nil end
end

-------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------

-- UI Activated: Hier wird der Ladebildschirm manipuliert
event.register(tes3.event.uiActivated, function(e)
    -- Wenn das Spiel gerade speichert, wollen wir keinen Ladebildschirm
    if isSaving then return end

    local folder = pendingFolder or currentSessionFolder
    if not folder or not imageCache[folder] or #imageCache[folder] == 0 then 
        return 
    end

    -- Pending-Ordner nach Nutzung leeren, damit wir wieder auf Session zurückfallen
    pendingFolder = nil 

    local menu = e.element
    local vx, vy = tes3ui.getViewportSize()
    local files = imageCache[folder]
    local chosen = files[math.random(#files)]

    -- 🔹 Menü manipulieren (Vollbild)
    menu.absolutePosAlignX = 0
    menu.absolutePosAlignY = 0
    menu.width = vx
    menu.height = vy
    menu.minWidth = vx
    menu.minHeight = vy
    menu.flowDirection = "none"
    menu.alpha = 1
    menu.paddingAllSides = 0

    -- Alter Hintergrund & Bild entfernen falls vorhanden
    local oldBg = menu:findChild("CustomRegionSplash_bg")
    if oldBg then oldBg:destroy() end
    local oldImg = menu:findChild("CustomRegionSplash")
    if oldImg then oldImg:destroy() end

    -- Neues schwarzes Layout drunter legen
    local bg = menu:createRect({ id = "CustomRegionSplash_bg" })
    bg.width = vx
    bg.height = vy
    bg.color = { 0, 0, 0 }
    bg.absolutePosAlignX = 0
    bg.absolutePosAlignY = 0

    -- Splash-Bild drüber legen
    local img = menu:createImage({ id = "CustomRegionSplash", path = chosen })
    img.width = vx
    img.height = vy
    img.scaleMode = true
    img.absolutePosAlignX = 0
    img.absolutePosAlignY = 0
    img.consumeMouseEvents = false

    menu:updateLayout()
    stopTimers()

    local menuLoadingId = tes3ui.registerID("MenuLoading")
    
    -- 🔹 Overlay-Stabilisierung (Vanilla-Ladebalken nach vorne holen)
    enforceTimer = timer.start({
        type = timer.real,
        duration = 0.1,
        iterations = -1,
        callback = function(te)
            local m = tes3ui.findMenu(menuLoadingId)
            if not m then
                stopTimers()
                return
            end
            
            local customImg = m:findChild("CustomRegionSplash")
            if customImg then
                customImg:bringToFront()
                customImg.width = m.width
                customImg.height = m.height
            end

            -- UI-Elemente nach vorne zwingen
            local elementsToFront = { "MenuLoading_progressBar", "MenuLoading_statusText" }
            for _, id in ipairs(elementsToFront) do
                local el = m:findChild(tes3ui.registerID(id))
                if el then
                    el.absolutePosAlignX = 0.5
                    el.absolutePosAlignY = (id == "MenuLoading_progressBar") and 0.9 or 0.86
                    el:bringToFront()
                end
            end
            
            m:updateLayout()
        end
    })

    -- 🔹 Slideshow (nur wenn mehr als 1 Bild vorhanden)
    if #files > 1 then
        slideshowTimer = timer.start({
            type = timer.real,
            duration = 10.0,
            iterations = -1,
            callback = function(te)
                local m = tes3ui.findMenu(menuLoadingId)
                if not m then
                    stopTimers()
                    return
                end
                local customImg = m:findChild("CustomRegionSplash")
                if customImg then
                    customImg.contentPath = files[math.random(#files)]
                    m:updateLayout()
                end
            end
        })
    end

end, { filter = "MenuLoading" })


event.register(tes3.event.cellChanged, function(e)
    if not e.cell then return end
    
    local folder = nil
    -- Zuerst direkten Zellnamen prüfen
    if e.cell.name then
        local cellNameLower = e.cell.name:lower()
        for key, f in pairs(cellSplashMap) do
            if cellNameLower:find(key, 1, true) then 
                folder = f 
                break 
            end
        end
    end

    -- Falls nicht gefunden, Region ermitteln
    if not folder then
        local regionName = findLinkedRegion(e.cell)
        if regionName then folder = regionSplashMap[regionName] end
    end

    if folder then
        currentSessionFolder = folder
    end
end)


-- Speicher-Logik (Flag setzen, damit der UI-Hook nicht feuert)
event.register(tes3.event.save, function(e)
    isSaving = true
    if currentSessionFolder and e.filename then
        config.saves[e.filename] = currentSessionFolder
        mwse.saveConfig(configPath, config)
    end
end)

event.register(tes3.event.saved, function(e)
    isSaving = false
end)


-- Lade-Logik (Ziel-Ordner aus Savegame holen)
event.register(tes3.event.load, function(e)
    if e.filename and config.saves[e.filename] then
        pendingFolder = config.saves[e.filename]
        currentSessionFolder = pendingFolder 
    end
end)


event.register(tes3.event.initialized, function()
    cacheImages()
    mwse.log("[%s] Mod bereit. Ordner-Bilder gecached.", MOD_NAME)
end)