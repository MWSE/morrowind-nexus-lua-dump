--[[

    Bed Buddies prevents sleeping in owned beds unless
    the NPC who owns it *really* likes you

]]--

local configPath = "bedbuddies"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = { enabled = true }
end


local sNotPermittedMessage = "You do not have permission to sleep in this bed."
local sNotPermLabel = "Not Permitted"
local sPermLabel = "Permitted"

local function getDispositionRequired()
    local personality = math.clamp(tes3.mobilePlayer.personality.current, 0, 100)
    local required = math.remap(personality, 0, 100, 100, 50)
    return required
end

--True if has disposition to sleep
local function checkDisposition(owner)
    if not owner.object.disposition then
        --Not a mobile, so you'll never have permission
        return false
    end
    return owner.object.disposition > getDispositionRequired()
end

local function getIsBed(targetObject)
    return (
        targetObject.objectType == tes3.objectType.activator and
        targetObject.script and
        targetObject.script.id == "Bed_Standard"
    )
end



local function hasPermission(reference)
    local ownerRef
    local ownerObject = tes3.getOwner(reference)
    if ownerObject then
        ownerRef = tes3.getReference(ownerObject.id)
    end

    --no owner or owner is publican
    if not ownerRef or ownerRef.object.class.id == "Publican" then
        return tes3.hasOwnershipAccess{ target = reference}
    --Dead
    elseif ownerRef.mobile and ownerRef.mobile.health.current <= 0 then 
            return true
    --Alive
    else
        return checkDisposition(ownerRef)
    end
end

local function onActivate(e)
    if not config.enabled then return end 

    local targetObject = e.target.object

    if getIsBed(targetObject) then
        if not hasPermission(e.target) then
            tes3.messageBox( sNotPermittedMessage )
        else
            tes3.runLegacyScript{ command = "ShowRestMenu"}
        end
        return false
    end
end
event.register(tes3.event.activate, onActivate)

local function onTooltip(e)
    if not config.enabled then return end 
    
    local targetObject = e.object
    if getIsBed(targetObject) then
        local bedMenu = e.tooltip:findChild(tes3ui.registerID("PartHelpMenu_main"))
        if bedMenu then
            
            local bedLabel = bedMenu.children[2]

            --Check for UI Expansion divider
            if bedMenu.children[2].text == "" then
                bedLabel = bedMenu.children[3]
            end
            --check when there's no existing ownership text
            if not bedLabel then
                
                bedLabel = bedMenu:createLabel()
                bedMenu:reorderChildren(1, bedLabel, 1)
            end
            if bedLabel then
                
                bedLabel.text = sPermLabel
                if hasPermission(e.reference) then
                    bedLabel.text = sPermLabel
                else
                    bedLabel.text = sNotPermLabel
                end
            end
        end
    end
end

event.register(tes3.event.uiObjectTooltip, onTooltip)


--------------------------------------------
--MCM
--------------------------------------------
local mcm = require("easyMCM.EasyMCM")
local function registerMCM()
    local sidebarDefault = (
        "With Bed Buddies, you are only able to sleep in a bed if your disposition with the owner is high enough. " ..
        "Unowned beds are not affected, and beds in inns/taverns can only be slept in if you have paid for it. " ..
        "Attempting to sleep in an owned bed no longer triggers a crime, but you will be prevented from sleeping " ..
        "regardless of whether you were detected or not."
    )

    local template = mcm.createTemplate("Bed Buddies")
    template:saveOnClose(configPath, config)
    local page = template:createSideBarPage{
        description = sidebarDefault
    }
    page:createOnOffButton{
        label = "Enable Bed Buddies",
        variable = mcm.createTableVariable{
            id = "enabled", 
            table = config
        },
        description = "Turn this mod on or off."
    }
    template:register()
end
event.register("modConfigReady", registerMCM)