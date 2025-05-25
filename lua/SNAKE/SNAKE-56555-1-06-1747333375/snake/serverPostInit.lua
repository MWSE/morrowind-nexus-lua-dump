local serverPostInit = {}

local gamestate = SnakeGame.gamestate
local cfg = SnakeGame.cfg
local createObjects = SnakeGame.helpers.createObjects
local degToRad = SnakeGame.helpers.degToRad

-- Function to save backups of the cells used by the game (only if they don't exist)
function serverPostInit.SaveCellBackups()
    local cells = {
        cfg.roomCell, -- The main game room cell
        "-3, -2"      -- The entrance cell in Balmora
    }

    for _, cellDescription in ipairs(cells) do
        -- Create a backup filename
        local backupFilename = "custom/snake_backup_" .. cellDescription .. ".json"

        -- Check if the backup already exists
        if jsonInterface.load(backupFilename) == nil then
            -- Backup doesn't exist, create it

            -- Check if the cell is loaded
            local unloadCellAtEnd = false
            if not logicHandler.IsCellLoaded(cellDescription) then
                logicHandler.LoadCell(cellDescription)
                unloadCellAtEnd = true
            end

            -- Save the cell data
            if LoadedCells[cellDescription] then
                local cellData = tableHelper.deepCopy(LoadedCells[cellDescription].data)

                -- Save to JSON
                if jsonInterface.save(backupFilename, cellData) then
                    tes3mp.LogMessage(enumerations.log.INFO,
                        "[SnakeGame] Successfully saved backup of cell " .. cellDescription ..
                        " to " .. backupFilename)
                else
                    tes3mp.LogMessage(enumerations.log.ERROR,
                        "[SnakeGame] Failed to save backup of cell " .. cellDescription)
                end
            else
                tes3mp.LogMessage(enumerations.log.ERROR,
                    "[SnakeGame] Failed to create backup of cell " .. cellDescription ..
                    " - cell data not available")
            end

            -- Unload the cell if it wasn't already loaded
            if unloadCellAtEnd then
                logicHandler.UnloadCell(cellDescription)
            end
        else
            tes3mp.LogMessage(enumerations.log.INFO,
                "[SnakeGame] Backup for cell " .. cellDescription ..
                " already exists")
        end
    end
end

local function InitializeGameObjects()
    local cellDescription = cfg.roomCell
    local objectsCreated = {}

    -- Set up a staging area outside the game room for pre-created objects
    local stagingLocation = cfg.stagingLocation

    tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Initializing game objects in staging area")

    -- Create one of each food type
    objectsCreated.food = {}
    for _, foodRefId in ipairs(cfg.objects.food) do
        local foodLocation = {
            posX = stagingLocation.x,
            posY = stagingLocation.y,
            posZ = stagingLocation.z,
            rotX = 0,
            rotY = 0,
            rotZ = 0
        }
        -- Special height adjustment for rotating_skooma
        if foodRefId == cfg.objects.food[1] then
            foodLocation.posZ = foodLocation.posZ + cfg.rotating_skooma_height_offset
        end
        local foodObject = {
            refId = foodRefId,
            count = 1,
            charge = -1,
            enchantmentCharge = -1,
            soul = "",
            location = foodLocation
        }
        local foodIndex = createObjects(cellDescription, { foodObject }, "place")

        -- Store the food object reference
        table.insert(objectsCreated.food, {
            refId = foodRefId,
            uniqueIndex = foodIndex
        })

        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Placed food " .. foodRefId .. " at staging area with index " .. foodIndex)
    end

    local centerX = math.floor(cfg.roomSize / 2)
    local centerY = math.floor(cfg.roomSize / 2)

    -- Place head
    local headLocation = {
        posX = 120.0,
        posY = 120.0,
        posZ = cfg.roomPosition.z + 9.5,
        rotX = math.rad(cfg.headRotations.right.rotX),
        rotY = math.rad(cfg.headRotations.right.rotY),
        rotZ = math.rad(cfg.headRotations.right.rotZ)
    }
    local headObject = {
        refId = cfg.objects.snakeHead,
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = headLocation
    }
    local headIndex = createObjects(cellDescription, { headObject }, "place")

    objectsCreated.head = {
        refId = cfg.objects.snakeHead,
        uniqueIndex = headIndex
    }

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Placed snake head at staging area with index " .. headIndex)

    -- Create maximum number of potential snake body segments
    -- Based on room size, maximum snake length would be roomSize * roomSize
    local maxSegments = cfg.roomSize * cfg.roomSize
    objectsCreated.body = {}

    for i = 1, maxSegments do
        local segmentLocation = {
            posX = stagingLocation.x,
            posY = stagingLocation.y,
            posZ = stagingLocation.z,
            rotX = 0,
            rotY = 0,
            rotZ = 0
        }
        local segmentObject = {
            refId = cfg.objects.snakeBody,
            count = 1,
            charge = -1,
            enchantmentCharge = -1,
            soul = "",
            location = segmentLocation
        }
        local segmentIndex = createObjects(cellDescription, { segmentObject }, "place")

        table.insert(objectsCreated.body, {
            refId = cfg.objects.snakeBody,
            uniqueIndex = segmentIndex
        })

        -- Log every 10 segments to avoid spam
        if i % 10 == 0 or i == 1 or i == maxSegments then
            tes3mp.LogMessage(enumerations.log.INFO,
                "[SnakeGame] Placed snake body segment " .. i .. "/" .. maxSegments ..
                " at staging area with index " .. segmentIndex)
        end
    end

    -- Create wall
    local wallLocation = {
        posX = cfg.wallPosition.x,
        posY = cfg.wallPosition.y,
        posZ = cfg.wallPosition.z,
        rotX = degToRad(-180),
        rotY = 0,
        rotZ = 0
    }
    local wallObject = {
        refId = cfg.objects.wall,
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = wallLocation,
        scale = cfg.wallScale
    }
    local wallIndex = createObjects(cellDescription, { wallObject }, "place")

    objectsCreated.wall = {
        refId = cfg.objects.wall,
        uniqueIndex = wallIndex
    }

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Placed " .. cfg.objects.wall .. " with index: " .. wallIndex)

    -- Create floor...currently set to lava
    local floorLocation = {
        posX = cfg.roomPosition.x,
        posY = cfg.roomPosition.y,
        posZ = cfg.roomPosition.z - 23, -- Slightly below ground
        rotX = 0,
        rotY = 0,
        rotZ = 0
    }
    local floorObject = {
        refId = cfg.objects.floor,
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = floorLocation,
        scale = cfg.floorScale
    }
    local floorIndex = createObjects(cellDescription, { floorObject }, "place")

    objectsCreated.floor = {
        refId = cfg.objects.floor,
        uniqueIndex = floorIndex
    }

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Placed  " .. cfg.objects.floor)

    -- Create border markers in their final position
    objectsCreated.borders = {}
    local size = cfg.roomSize
    local step = 1 -- step size in grid units

    tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Creating game border in final position")

    for x = -1, size, step do
        for y = -1, size, step do
            -- Check if the current point is on the border
            if x == -1 or x == size or y == -1 or y == size then
                local borderLocation = {
                    posX = cfg.roomPosition.x + (x * 16),
                    posY = cfg.roomPosition.y + (y * 16),
                    posZ = cfg.roomPosition.z + 8,
                    rotX = 0,
                    rotY = 0,
                    rotZ = 0
                }

                local borderObject = {
                    refId = cfg.objects.border,
                    count = 1,
                    charge = -1,
                    enchantmentCharge = -1,
                    soul = "",
                    location = borderLocation
                }

                -- Set scale for border
                if cfg.borderScale ~= 1 then
                    local pid = 0 -- Use server PID for initialization
                    borderObject.scale = cfg.borderScale
                    -- setScale(pid, cellDescription, borderIndex, borderObject.refId, cfg.borderScale)
                end

                -- local borderIndex = createObjects(cellDescription, { borderObject }, "place")
                -- no reason to store these as they should never move.
                createObjects(cellDescription, { borderObject }, "place")

                -- table.insert(objectsCreated.borders, {
                --     refId = cfg.objects.border,
                --     uniqueIndex = borderIndex,
                --     position = { x = x, y = y }
                -- })
            end
        end
    end

    -- Add the special custom marker for the large floor panel
    local customMarkerLocation = {
        posX = 120.0,
        posY = 120.0,
        posZ = -128.0,
        rotX = degToRad(270.0),
        rotY = degToRad(0.0),
        rotZ = degToRad(90.0)
    }
    local customBorderObject = {
        refId = cfg.objects.border,
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        scale = 32,
        location = customMarkerLocation
    }
    -- local customMarkerIndex = createObjects(cellDescription, { customBorderObject }, "place")
    createObjects(cellDescription, { customBorderObject }, "place")

    -- table.insert(objectsCreated.borders, {
    --     refId = cfg.objects.border,
    --     uniqueIndex = customMarkerIndex,
    --     position = { x = "custom", y = "custom" } -- Special identifier
    -- })

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Created border with " .. #objectsCreated.borders .. " markers in final position")

    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Building entrance...")

    --place first lava vent
    local lava_vent_1_location = {
        posX = -17390.0,
        posY = -10890.0,
        posZ = 220,
        rotX = math.rad(355),
        rotY = math.rad(0),
        rotZ = math.rad(169)
    }
    local lava_vent_1_object = {
        refId = "act_terrain_lava_ventlg",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = lava_vent_1_location,
    }
    -- local skoomaRuinsIndex = createObjects("-3, -2", { lava_vent_1_object }, "place")
    createObjects("-3, -2", { lava_vent_1_object }, "place")

    --place second lava vent
    local lava_vent_2_location = {
        posX = -17040.0,
        posY = -10600.0,
        posZ = 390,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(180)
    }
    local lava_vent_2_object = {
        refId = "act_terrain_lava_ventlg",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = lava_vent_2_location,
    }
    createObjects("-3, -2", { lava_vent_2_object }, "place")

    --place chimney smoke green
    local green_smoke_location = {
        posX = -17100.0,
        posY = -10988.0,
        posZ = 956,
        rotX = math.rad(75),
        rotY = math.rad(345),
        rotZ = math.rad(0),
    }
    local green_smoke_object = {
        refId = "chimney_smoke_green",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = green_smoke_location,
        scale = 1.6
    }
    createObjects("-3, -2", { green_smoke_object }, "place")

    --place skooma pipe chimney
    local skoomaPipe_chimney_location = {
        posX = -17110.0,
        posY = -11360.0,
        posZ = 696,
        rotX = math.rad(180),
        rotY = math.rad(310),
        rotZ = math.rad(92),
    }
    local skoomaPipe_chimney_object = {
        refId = "sg_skooma_chimney",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = skoomaPipe_chimney_location,
        scale = 25
    }
    createObjects("-3, -2", { skoomaPipe_chimney_object }, "place")

    --place vos dungeon building mesh
    local building_location = {
        posX = -17100.0,
        posY = -11220.0,
        posZ = -1040,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(330),
    }
    local building_object = {
        refId = "ex_imp_guardtower_02",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = building_location,
        scale = 1.3,
    }
    createObjects("-3, -2", { building_object }, "place")

    --place door for building
    local door_location = {
        posX = -17100.0,
        posY = -11567.0,
        posZ = 270,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(0),
    }
    local door_object = {
        refId = "sg_cryptic_building",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = door_location,
    }
    local sg_cryptic_building_door = createObjects("-3, -2", { door_object }, "place")

    --keep track of door index for checking if cell has reset..
    objectsCreated.sg_cryptic_building_door = {
        refId = "sg_cryptic_building",
        uniqueIndex = sg_cryptic_building_door
    }

    --place place threshhold for door in balmora
    local threshold_location = {
        posX = -17100.0,
        posY = -11598.0,
        posZ = 199,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(270),
    }
    local threshold_object = {
        refId = "ex_imp_wallent_02",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = threshold_location,
    }
    createObjects("-3, -2", { threshold_object }, "place")

    --place place threshhold for door inside the balmora entrance
    local threshold_inside_location = {
        posX = 2768.0,
        posY = -3616.0,
        posZ = 11360,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(32),
    }
    local threshold_inside_object = {
        refId = "ex_imp_wallent_02",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = threshold_inside_location,
    }
    createObjects(cfg.roomCell, { threshold_inside_object }, "place")

    --place door inside the balmora entrance
    local door_inside_location = {
        posX = 2778.0,
        posY = -3624.0,
        posZ = 11436,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(122),
    }
    local door_inside_object = {
        refId = "sg_door_to_balmora",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = door_inside_location,
    }
    createObjects(cfg.roomCell, { door_inside_object }, "place")

    --place place door to snake room
    local game_hall_door_location = {
        posX = 1710.0,
        posY = -2866.0,
        posZ = 11369,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(294),
    }
    local game_hall_door_object = {
        refId = "sg_dwemer_game_hall",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = game_hall_door_location,
        scale = 1.8
    }
    local sg_dwemer_game_hall_door = createObjects(cfg.roomCell, { game_hall_door_object }, "place")

    --index tracked to check if cell has been reset
    objectsCreated.sg_dwemer_game_hall_door = {
        refId = "sg_dwemer_game_hall",
        uniqueIndex = sg_dwemer_game_hall_door
    }

    --place giant skooma dwemer door is on
    local skooma_room_top_location = {
        posX = 1090.0,
        posY = -2610.0,
        posZ = 7190,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(330),
    }
    local skooma_room_top_object = {
        refId = cfg.objects.wall,
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = skooma_room_top_location,
        scale = 500
    }
    createObjects(cfg.roomCell, { skooma_room_top_object }, "place")

    --place floor in small room
    local imperial_floor_location = {
        posX = 1750.0,
        posY = -2790.0,
        posZ = 13893,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(0),
    }
    local imperial_floor_object = {
        refId = "in_impbig_4way_01",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = imperial_floor_location,
        scale = 10
    }
    createObjects(cfg.roomCell, { imperial_floor_object }, "place")

    --place inside buildihng mesh
    local imperial_tower_location = {
        posX = 1760.0,
        posY = -2912.0,
        posZ = 6656,
        rotX = math.rad(180),
        rotY = math.rad(0),
        rotZ = math.rad(0),
    }
    local imperial_tower_object = {
        refId = "ex_imp_guardtower_02",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = imperial_tower_location,
        scale = -5
    }
    createObjects(cfg.roomCell, { imperial_tower_object }, "place")

    --daedric platform under game board
    local daedric_platform_location = {
        posX = 110.0,
        posY = 110.0,
        posZ = -20,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(0),
    }
    local daedric_platform_object = {
        refId = "ex_dae_ruin_platform_01",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = daedric_platform_location,
        scale = 2
    }
    createObjects(cfg.roomCell, { daedric_platform_object }, "place")

    --snake poster
    local snake_poster_location = {
        posX = 90,
        posY = 1540,
        posZ = 1130,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(90),
    }
    local snake_poster_object = {
        refId = "in_dwe_slate06",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = snake_poster_location,
        scale = 5
    }
    createObjects(cfg.roomCell, { snake_poster_object }, "place")

    --door platform back up to balmora
    local daedric_door_platform_location = {
        posX = 130,
        posY = -1750,
        posZ = 8,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(180),
    }
    local daedric_door_platform_object = {
        refId = "ex_dae_ruin_entry.max",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = daedric_door_platform_location,
        scale = 1.5
    }
    createObjects(cfg.roomCell, { daedric_door_platform_object }, "place")

    --daedric door
    local daedric_door_location = {
        posX = 130,
        posY = -1760,
        posZ = 10,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(180),
    }
    local daedric_door_object = {
        refId = "sg_daedric_door",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = daedric_door_location,
        scale = 1.5
    }
    createObjects(cfg.roomCell, { daedric_door_object }, "place")

    --headless caius
    local headless_caius_location = {
        posX = 381,
        posY = -1,
        posZ = -19,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(-168),
    }
    local headless_caius_object = {
        refId = "sg_snake_caius",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = headless_caius_location,
    }
    createObjects(cfg.roomCell, { headless_caius_object }, "place")

    --snake_yagrum
    local snake_yagrum_location = {
        posX = -172,
        posY = 27.5,
        posZ = -19,
        rotX = math.rad(90),
        rotY = math.rad(0),
        rotZ = math.rad(150),
    }
    local snake_yagrum_object = {
        refId = "sg_snake_yagrum",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = snake_yagrum_location,
    }
    local yagrumIndex = createObjects(cfg.roomCell, { snake_yagrum_object }, "place")

    --store yagrums index for use in the onGUIAction handler
    objectsCreated.yagrum = {
        refId = "sg_snake_yagrum",
        uniqueIndex = yagrumIndex
    }

    --leaderboard book
    local leaderboard_location = {
        posX = stagingLocation.x,
        posY = stagingLocation.y,
        posZ = stagingLocation.z,
        rotX = 0,
        rotY = 0,
        rotZ = 0
    }
    local leaderboard_object = {
        refId = "sg_leaderboard_book",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = leaderboard_location,
    }
    local leaderboardIndex = createObjects(cfg.roomCell, { leaderboard_object }, "place")
    tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Created " .. leaderboard_object.count .. " leaderboard_object")

    --store index for use in the objectdelete handler
    objectsCreated.leaderboard = {
        refId = "sg_leaderboard_book",
        uniqueIndex = leaderboardIndex
    }

    --dwemer piping
    local dwemer_piping_location = {
        posX = 3864,
        posY = 22,
        posZ = -56580,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(90),
    }
    local dwemer_piping_object = {
        refId = "in_akulakhan00",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = dwemer_piping_location,
        scale = 11.2
    }
    createObjects(cfg.roomCell, { dwemer_piping_object }, "place")
    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Created " .. dwemer_piping_object.count .. " dwemer_piping_object")

    -- brazier 1
    local brazier_1_location = {
        posX = -956,
        posY = 107,
        posZ = -21,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(0),
    }
    local brazier_1_object = {
        refId = "light_dae_brazier00",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = brazier_1_location,
        scale = 2
    }
    createObjects(cfg.roomCell, { brazier_1_object }, "place")
    tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Created " .. brazier_1_object.count .. " brazier_1_object")

    -- brazier 2
    local brazier_2_location = {
        posX = 1171,
        posY = 109,
        posZ = -21,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(0),
    }
    local brazier_2_object = {
        refId = "light_dae_brazier00",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = brazier_2_location,
        scale = 2
    }
    createObjects(cfg.roomCell, { brazier_2_object }, "place")
    tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Created " .. brazier_2_object.count .. " brazier_2_object")

    -- 4 way steam fitting 1
    local steam_fitting_1_location = {
        posX = 1130,
        posY = -840,
        posZ = 980,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(206),
    }
    local steam_fitting_1_object = {
        refId = "furn_dwrv_fitting40",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = steam_fitting_1_location,
        scale = .4
    }
    createObjects(cfg.roomCell, { steam_fitting_1_object }, "place")
    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Created " .. steam_fitting_1_object.count .. " steam_fitting_1_object")

    -- 4 way steam fitting 2
    local steam_fitting_2_location = {
        posX = -330,
        posY = -40,
        posZ = 960,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(0),
    }
    local steam_fitting_2_object = {
        refId = "furn_dwrv_fitting40",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = steam_fitting_2_location,
        scale = .4
    }
    createObjects(cfg.roomCell, { steam_fitting_2_object }, "place")
    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Created " .. steam_fitting_2_object.count .. " steam_fitting_2_object")

    -- lava vent
    local inside_lava_vent_location = {
        posX = -760,
        posY = -1070,
        posZ = -220,
        rotX = math.rad(0),
        rotY = math.rad(0),
        rotZ = math.rad(280),
    }
    local inside_lava_vent_object = {
        refId = "act_terrain_lava_ventlg",
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        location = inside_lava_vent_location,
        scale = 2
    }
    createObjects(cfg.roomCell, { inside_lava_vent_object }, "place")
    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Created " .. inside_lava_vent_object.count .. " inside_lava_vent_object")

    -- Save all the created object references to a global table or to disk
    SnakeGame.preCreatedObjects = objectsCreated

    -- Save the data to a JSON file for persistence across server restarts
    local jsonData = jsonInterface.save(gamestate.SNAKEGAMEJSONPATH, SnakeGame.preCreatedObjects)

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Initialized and saved " .. (1 + 1 + 1 + 1 + #cfg.objects.food + maxSegments) ..
        " game objects to " .. gamestate.SNAKEGAMEJSONPATH)

    return objectsCreated
end

function serverPostInit.OnServerPostInitHandler()
    local scriptStore = RecordStores["script"]
    scriptStore.data.permanentRecords["sg_test_RotateScript"] = {
        scriptText =
        "begin test_RotateScript\n\tshort RotatingItem\n\tset RotatingItem to 1\n\tif ( OnActivate == 1 )\n\t\tReturn\n\tendif\n\tif ( RotatingItem == 1 )\n\t\trotate, Z, 180\n\tendif\nend"
    }
    scriptStore.data.permanentRecords["sg_door_to_building_script"] = {
        scriptText =
            'begin door_to_buildin_script\nif (OnActivate == 1)\n\tPlayer->PositionCell, 2680, -3576, 11334, -56, "' ..
            cfg.roomCell .. '"\n\tPlaySound, "Door Heavy Open"\nendif\nend\n'
    }
    scriptStore.data.permanentRecords["sg_skooma_hatch_script"] = {
        scriptText =
            'begin skooma_hatch_script\nif (OnActivate == 1)\n\tPlayer->PositionCell, 135, -1373, -10, 0, "' ..
            cfg.roomCell .. '"\n\tPlaySound, "Door Stone Open"\nendif\nend\n'
    }
    scriptStore.data.permanentRecords["sg_door_to_balmora_script"] = {
        scriptText =
        'begin door_to_balmora_script\nif (OnActivate == 1)\n\tPlayer->PositionCell, -17104, -11707, 161, -180, "-3, -2"\n\tPlaySound, "Door Heavy Close"\nendif\nend\n'
    }
    scriptStore.data.permanentRecords["sg_daedric_door_script"] = {
        scriptText =
            'begin daedric_door_script\nif (OnActivate == 1)\n\tPlayer->PositionCell, 1955, -3000, 11334, 115, "' ..
            cfg.roomCell .. '"\n\tPlaySound, "Door Heavy Close"\nendif\nend\n'
    }
    scriptStore.data.permanentRecords["sg_snake_caius_script"] = {
        scriptText =
        'begin sg_snake_caius_script\nshort OnPCHitMe\nshort doOnce\nif doOnce == 0\n\tsetagility 1000000\n\tsethealth 1000000\n\taddspell sg_calm_human\n\tset doOnce to 1\nendif\nif (OnPCHitMe == 1)\n\tsetangle z 210\nset OnPCHitMe to 0\nendif\nend\n'
    }
    scriptStore.data.permanentRecords["sg_snake_yagrum_script"] = {
        scriptText =
        'begin sg_snake_yagrum_script\nshort OnPCHitMe\nshort doOnce\nif doOnce == 0\n\tsetagility 1000000\n\tsethealth 1000000\n\taddspell sg_calm_creature\n\tset doOnce to 1\nendif\nif (OnPCHitMe == 1)\n\tsetangle z 150\nset OnPCHitMe to 0\nendif\nend\n'
    }
    --TODO on ubuntu server:
    -- Warning: sg_snake_head_script line 12, column 34 (snakegameactive): Parsing a non-variable string as a number: 0
    --  and the sound doens't play
    scriptStore.data.permanentRecords["sg_snake_head_script"] = {
        scriptText =
            'begin sg_snake_head_script\nfloat fTimer\nfloat updateInterval\nshort gameActive\n\n; Initialize variables\nif ( fTimer == 0 )\n\tset updateInterval to ' ..
            SnakeGame.cfg.updateInterval ..
            '\nendif\n\n; Assign the global value to our local variable first\nset gameActive to snakegameactive\n\n; Now use the local variable for the check\nif ( gameActive )\n\tset fTimer to fTimer + GetSecondsPassed\n\tif ( fTimer >= updateInterval )\n\t\tPlaySound3DVP "corpDRAG", 1.0, 1.0\n\t\tset fTimer to 0\n\tendif\nendif\n\nend'
    }
    scriptStore:QuicksaveToDrive()

    local miscStore = RecordStores["miscellaneous"]
    miscStore.data.permanentRecords["sg_cryptic_building"] = {
        model = "d\\Ex_imp_loaddoor_02.NIF",
        script = "sg_door_to_building_script",
        name = "Cryptic Building"
    }
    miscStore.data.permanentRecords["sg_dwemer_game_hall"] = {
        model = "d\\door_dwrv_loaddown00.NIF",
        script = "sg_skooma_hatch_script",
        name = "Abandoned Skooma Distillery"
    }
    miscStore.data.permanentRecords["sg_door_to_balmora"] = {
        model = "d\\Ex_imp_loaddoor_02.NIF",
        script = "sg_door_to_balmora_script",
        name = "Balmora"
    }
    miscStore.data.permanentRecords["sg_daedric_door"] = {
        model = "d\\Ex_DAE_door_load_oval.NIF",
        script = "sg_daedric_door_script",
    }
    miscStore.data.permanentRecords["sg_snake_head"] = {
        model = "b\\B_N_Imperial_M_Head_01.nif",
        script = "sg_snake_head_script",
        name = "Caius Cosades Head"
    }
    miscStore:QuicksaveToDrive()

    --TODO make statics for the snake body and dwemer cube
    local staticStore = RecordStores["static"]
    staticStore.data.permanentRecords["sg_skooma_ruins"] = {
        model = "n\\Potion_Skooma_01.NIF"
    }
    staticStore.data.permanentRecords["sg_skooma_chimney"] = {
        model = "m\\Apparatus_A_Spipe_01.nif"
    }
    staticStore.data.permanentRecords["sg_snake_body"] = {
        model = "n\\Ingred_6th_Corpusmeat_07.NIF"
    }
    staticStore.data.permanentRecords["sg_dwemer_cube"] = {
        model = "m\\misc_dwrv_Ark_cube00.nif"
    }
    staticStore:QuicksaveToDrive()

    local potionStore = RecordStores["potion"]
    potionStore.data.permanentRecords["sg_rotating_skooma"] = {
        baseId = "potion_skooma_01",
        script = "sg_test_RotateScript"
    }
    potionStore:QuicksaveToDrive()

    local apparatusStore = RecordStores["apparatus"]
    apparatusStore.data.permanentRecords["sg_rotating_skooma_pipe"] = {
        baseId = "apparatus_a_spipe_01",
        script = "sg_test_RotateScript"
    }
    apparatusStore:QuicksaveToDrive()

    local ingredientStore = RecordStores["ingredient"]
    ingredientStore.data.permanentRecords["sg_rotating_moonsugar"] = {
        baseId = "ingred_moon_sugar_01",
        script = "sg_test_RotateScript"
    }
    ingredientStore:QuicksaveToDrive()

    local npcStore = RecordStores["npc"]
    npcStore.data.permanentRecords["sg_snake_caius"] = {
        baseId = "teruise girvayne",
        name = "Caius Cosades",
        gender = 1,
        race = "imperial",
        hair = "no hair",
        head = "no head",
        health = 99999999999,
        level = 1,
        fatigue = 9999999999,
        inventoryBaseId = "caius cosades",
        magicka = 99999999,
        script = "sg_snake_caius_script"
    }
    npcStore:QuicksaveToDrive()

    local creatureStore = RecordStores["creature"]
    creatureStore.data.permanentRecords["sg_snake_yagrum"] = {
        baseId = "yagrum bagarn",
        script = "sg_snake_yagrum_script"
    }
    creatureStore:QuicksaveToDrive()

    local spellStore = RecordStores["spell"]
    spellStore.data.permanentRecords["sg_calm_human"] = {
        name = "Chilln",
        subtype = 1,
        cost = 1,
        flags = 0,
        effects = {
            {
                id = enumerations.effects.CALM_HUMANOID,
                attribute = -1,
                skill = -1,
                rangeType = 1,
                area = 0,
                duration = -1,
                magnitudeMax = 100,
                magnitudeMin = 100
            }
        }
    }
    spellStore.data.permanentRecords["sg_calm_creature"] = {
        name = "Chilln",
        subtype = 1,
        cost = 1,
        flags = 0,
        effects = {
            {
                id = enumerations.effects.CALM_CREATURE,
                attribute = -1,
                skill = -1,
                rangeType = 1,
                area = 0,
                duration = -1,
                magnitudeMax = 100,
                magnitudeMin = 100
            }
        }
    }
    spellStore.data.permanentRecords["sg_levitate"] = {
        name = "Gravity Displacement",
        subtype = 1,
        cost = 1,
        flags = 0,
        effects = {
            {
                id = enumerations.effects.LEVITATE,
                attribute = -1,
                skill = -1,
                rangeType = 1,
                area = 0,
                duration = -1,
                magnitudeMax = 100,
                magnitudeMin = 100
            }
        }
    }
    spellStore.data.permanentRecords["sg_light"] = {
        name = "Gravity Displacement",
        subtype = 1,
        cost = 1,
        flags = 0,
        effects = {
            {
                id = enumerations.effects.LIGHT,
                attribute = -1,
                skill = -1,
                rangeType = 0,
                area = 0,
                duration = -1,
                magnitudeMax = 100,
                magnitudeMin = 100
            }
        }
    }
    spellStore:QuicksaveToDrive()

    -- QuickKeys for moving the snake ( 1, 2, 3, 4)
    local quickKeys = { "up", "down", "left", "right" }
    local bookStore = RecordStores["book"]
    for i = 1, #quickKeys do
        bookStore.data.permanentRecords["sg_" .. quickKeys[i]] = {
            name = quickKeys[i],
            text = "",
            icon = "m\\tx_scroll_03.dds",
            scrollState = true,
            enchantmentId = "",
            enchantmentCharge = 0,
            skillId = -1,
            weight = 0,
            value = 0,
            soul = "",
            count = 1,
            charge = -1
        }
    end

    bookStore.data.permanentRecords["sg_leaderboard_book"] = {
        name = "Leaderboard",
        text = "",
        icon = "m\\tx_scroll_03.dds",
        scrollState = true,
        enchantmentId = "",
        enchantmentCharge = 0,
        skillId = -1,
        weight = 0,
        value = 0,
        soul = "",
        count = 1,
        charge = -1
    }
    bookStore:QuicksaveToDrive()

    --custom cell for the snake room
    local cellStore = RecordStores["cell"]
    cellStore.data.permanentRecords["Abandoned Skooma Distillery"] = {
        baseId = SnakeGame.cfg.cellBaseId
    }
    cellStore:QuicksaveToDrive()

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Records Created.")

    -- Initialize leaderboard
    SnakeGame.leaderboard.initialize()
    tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Leaderboard initialized")

    -- Then initialize all the game objects
    -- Check if we have saved objects from previous server runs
    if jsonInterface.load(gamestate.SNAKEGAMEJSONPATH) ~= nil then
        SnakeGame.preCreatedObjects = jsonInterface.load(gamestate.SNAKEGAMEJSONPATH)
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Loaded " .. tableHelper.getCount(SnakeGame.preCreatedObjects.body) +
            tableHelper.getCount(SnakeGame.preCreatedObjects.food) + 3 ..
            " pre-created objects from " .. gamestate.SNAKEGAMEJSONPATH)
    else
        -- If not, create all objects and save them
        cfg.initializing = true
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Initializing value before: " .. tostring(cfg.initializing))
        InitializeGameObjects()
        cfg.initializing = false
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Initializing value after: " .. tostring(cfg.initializing))
    end

    -- Save backups of the cells used by the Snake Game
    serverPostInit.SaveCellBackups()

    -- add snakegameactive client global to clientVariableScopes personal table
    if not tableHelper.containsValue(clientVariableScopes.globals.personal, "snakegameactive", true) then
        table.insert(clientVariableScopes.globals.personal, "snakegameactive")
    end
end

return serverPostInit

-- customEventHooks.registerHandler("OnServerPostInit", OnServerPostInitHandler)
