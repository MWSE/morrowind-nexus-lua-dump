--[[Designed for Whom
	Meant as a tool to warn when you are equiping an item
    that doesn't appear to match your body mesh

	authors = {
        ["C89C"] = {Initial Creator}
	}

	in case of bugs, please ping Rory on Discord
]]--

local config = require("DesignedForWhom.config")
local logger = require("logging.logger")
local log = logger.new{
    name = "DesignedForWhom",
    logLevel = "TRACE",
    logToConsole = false,
    outputFile = tes3.installDirectory .. "\\Data Files\\DesignedForWhom.log"
}

local function logMessage(message)
    if config.separateLog then
        log:info(message .. "\n")
    else
        mwse.log("\n[Designed for Whom] " .. message .. "\n")
    end
end

-- Clear out unloaded plugins in the blocklist
local function cleanUpPlugins()

    local listPlugins = tes3.dataHandler.nonDynamicData.activeMods
    local activePlugins = {}

    logMessage("Cleaning Plugin List")

    for _,v in pairs(listPlugins) do
        
        if config.blocklist[v.filename:lower()] then
            
            activePlugins[v.filename:lower()] = true

        end

    end

    config.blocklist = activePlugins

end

local function designedForWhomCheck(e)

    local showMessagebox = false

    if e.reference.mobile and e.reference.mobile.actorType == tes3.actorType.player then

        if e.bodyPart then
    
            if config.blocklistToggle and config.blocklist[e.bodyPart.sourceMod:lower()] then
        
                if config.alwaysLog then
            
                    logMessage(
                        string.format(
                            config.stringTable["bodyPartSkip"],
                            e.bodyPart.id,
                            e.bodyPart.sourceMod:lower(),
                            e.object
                        )
                    )
            
                end
            
            elseif e.bodyPart.female and not e.reference.mobile.object.female then
        
                -- have bodypart, male equipping female
                logMessage(
                    string.format(
                        config.stringTable["bodyPartMEF"],
                        e.bodyPart.id,
                        e.bodyPart.sourceMod:lower(),
                        e.object
                    )
                )
            
                if config.showInGame then showMessagebox = true end
            
            elseif not e.bodyPart.female and e.reference.mobile.object.female then
        
                -- have bodypart, female equipping male
                logMessage(
                    string.format(
                        config.stringTable["bodyPartFEM"],
                        e.bodyPart.id,
                        e.bodyPart.sourceMod:lower(),
                        e.object
                    )
                )
                            
                if config.showInGame then showMessagebox = true end
            
            end
    
        elseif e.object then
    
            if config.blocklistToggle and config.blocklist[e.object.sourceMod:lower()] then
        
                -- no bodypart, in blocklist
                if config.alwaysLog then
            
                    logMessage(
                        string.format(
                            config.stringTable["objectskip"],
                            e.object.id,
                            e.object.sourceMod:lower()
                        )
                    )
                
                end
            
            else
        
                -- no bodypart, not in blocklist
                logMessage(
                    string.format(
                        config.stringTable["objectEquip"],
                        e.object.id,
                        e.object.sourceMod:lower()
                    )
                )
            
                if config.showInGame then showMessagebox = true end
            
            end
        
        end

        if showMessagebox then

            tes3.messageBox({
                message = "It seems like the item you equipped isn't made to fit your body mesh. You might experience missing or distorted textures.",
                buttons = {"Ok"}
            })
        
        end

    end

end

local function initialized(e)

    -- Register the event to check the items
    event.register("bodyPartAssigned", designedForWhomCheck)

    print("[Designed for Whom] Loaded into MWSE")

end

local function createModConfig(e)

    -- Clean up Plugins
    if config.cleanPlugins then cleanUpPlugins() end

    dofile("DesignedForWhom.mcm")

end

event.register("initialized", initialized)
event.register("modConfigReady", createModConfig)