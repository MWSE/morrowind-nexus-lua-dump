


local spawners = {
    "GVEA_T1_Fighters",
    "GVEA_T2_Fighters",
    "GVEA_T0_Rank01",
    "GVEA_T0_Rank02",
    "GVEA_T0_Rank03",
    "GVEA_T0_Rank04",
    "GVEA_T0_Rank05",
    "GVEA_T0_Rank06",
    "GVEA_T0_Rank07",
    "GVEA_T0_Rank08",
    "GVEA_T0_Rank09",
    "GVEA_T0_Rank10",
}



---@param list tes3referenceList
---@return fun(): tes3reference
local function iterRefs(list)
    local function iterator()
        local ref = list.head

        if list.size ~= 0 then
            coroutine.yield(ref)
        end

        while ref.nextNode do
            ref = ref.nextNode
            coroutine.yield(ref)
        end
    end
    return coroutine.wrap(iterator)
end


local function startSpawn(obj, spot, rot)
    --mwse.log("[Roaring Arena]: fighter spawn started!")
    tes3.createReference({
        object = obj,
        position = spot,
        orientation = rot,
        cell = tes3.getPlayerCell(),
    })
end


local function startScripts(e)

    if e.script.id == "GVEA_NpcVNpcDeSpawn" or e.script.id == "GVEA_T0_Cleanup_s" then

        for _, id in ipairs(spawners) do
            local spawn = tes3.getReference(id)
            if spawn then
                spawn:delete()
                mwse.log("[Roaring Arena]: Fight Leveled Spawn %s deleted", spawn.object.id)
            end
        end
        return false
       
    elseif e.script.id == "GVEA_T2_Attack_T1" then
        local npcs = tes3.player.cell.actors
        local spawn1, spawn2
        if npcs ~= nil then
            mwse.log("[Roaring Arena]: NPC reference list loaded")
        end
        for ref in iterRefs(npcs) do
            if string.startswith(ref.object.id, "GVEA_T1_") then
                spawn1 = ref.mobile
                mwse.log("[Roaring Arena] T1 fighter = %s", spawn1.reference.baseObject.id)
            elseif string.startswith(ref.object.id, "GVEA_T2_") then
                spawn2 = ref.mobile
                mwse.log("[Roaring Arena] T2 fighter = %s", spawn2.reference.baseObject.id)
            end

        end
        if spawn1 and spawn2 then
            spawn1:startCombat(spawn2)
            spawn2:startCombat(spawn1)
            mwse.log("[Roaring Arena]: NPC fight started between %s and %s!", spawn1.object.reference.id, spawn2.object.reference.id)
            --return
       end
       return false
    elseif e.script.id == "GVEA_T1_Attack_T2" then
        return false
    end
end


local function spawnFight(e)
    
    if e.reference.baseObject.objectType ~= tes3.objectType.leveledCreature or string.startswith(e.reference.object.id, "GVEA_") == false then
        return
    end
    local spawn = e.reference.object:pickFrom()
    local spawner = tes3.getReference("GVEA_ArenaSpawner")
   -- local pos1, pos2, pos3 = spawner.position, spawner.position, spawner.position

    
    if string.startswith(e.reference.object.id, "GVEA_T1_") then
        local pos = tes3vector3.new(spawner.position.x, spawner.position.y + 400, spawner.position.z)
        --pos.y = spawner.position.y + 400
       -- pos1.y = pos1.y + 400
        startSpawn(spawn, pos, tes3vector3.new(0, 0, -90))
    elseif string.startswith(e.reference.object.id, "GVEA_T2_") then
        local pos = tes3vector3.new(spawner.position.x, spawner.position.y - 400, spawner.position.z)
        --pos.y = spawner.position.y - 800
     --   pos2.y = pos2.y - 800
        startSpawn(spawn, pos, tes3vector3.new(0, 0, -90))
    elseif string.startswith(e.reference.object.id, "GVEA_T0_") then
    --    pos3.x = pos3.x + 400
        local pos = tes3vector3.new(spawner.position.x + 400, spawner.position.y, spawner.position.z)
     --   pos.x = spawner.position.x + 400
        startSpawn(spawn, pos, tes3vector3.new(0, 0, 180))
    end
end
local function onInitialized(e)
    if tes3.isModActive("RoaringArena.esp") or tes3.isModActive("RoaringArena.esm") then -- change to RoaringArena.esm after testing is done
        mwse.log("[Roaring Arena]: RoaringArena.esm is active. Mod Content is enabled")
        event.register("referenceActivated", spawnFight)
        event.register("startGlobalScript", startScripts)
    else
        mwse.log("[Roaring Arena]: RoaringArena.esm is not active. Mod content is disabled")
    end
end 


event.register("initialized", onInitialized)