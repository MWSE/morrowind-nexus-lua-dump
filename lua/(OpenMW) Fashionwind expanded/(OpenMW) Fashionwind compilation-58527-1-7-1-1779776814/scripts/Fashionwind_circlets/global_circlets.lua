local I     = require('openmw.interfaces')
local types = require('openmw.types')

local CIRCLETS_RECORD_IDS = {
    ['_kd_bandcopper']     = true,
    ['_kd_bandgold']       = true,
    ['_kd_bandmithril']    = true,
    ['_kd_bandorc']        = true,
    ['_kd_chainblack']     = true,
    ['_kd_chainblackgems'] = true,
    ['_kd_chaingold']      = true,
    ['_kd_chaingoldgems']  = true,
    ['_kd_chainsilver']    = true,
    ['_kd_chainsilvergems']= true,
    ['_kd_circletbblue']   = true,
    ['_kd_circletbgreen']  = true,
    ['_kd_circletbpearl']  = true,
    ['_kd_circletbred']    = true,
    ['_kd_circletbtopaz']  = true,
    ['_kd_circletgblue']   = true,
    ['_kd_circletggreen']  = true,
    ['_kd_circletgpearl']  = true,
    ['_kd_circletgred']    = true,
    ['_kd_circletgtopaz']  = true,
    ['_kd_circletsblue']   = true,
    ['_kd_circletsgreen']  = true,
    ['_kd_circletspearl']  = true,
    ['_kd_circletsred']    = true,
    ['_kd_circletstopaz']  = true,
    ['_kd_crownceltic']    = true,
    ['_kd_crowncross']     = true,
    ['_kd_crownleather']   = true,
    ['_kd_diag']           = true,
    ['_kd_diagdia']        = true,
    ['_kd_diagem']         = true,
    ['_kd_diagru']         = true,
    ['_kd_diagsa']         = true,
    ['_kd_dias']           = true,
    ['_kd_diasdia']        = true,
    ['_kd_diasem']         = true,
    ['_kd_diasru']         = true,
    ['_kd_diassa']         = true,
    ['_kd_elvdia']         = true,
    ['_kd_elvem']          = true,
    ['_kd_elvru']          = true,
    ['_kd_twin']           = true,
    ['_kd_twins']          = true,
    ['_kd_wedia']          = true,
    ['_kd_wegreen']        = true,
    ['_kd_wered']          = true,
}

local function isCircletItem(item)
    if types.Armor.objectIsInstance(item) then
        local ok, rec = pcall(types.Armor.record, item)
        if ok and rec and rec.id then
            return CIRCLETS_RECORD_IDS[rec.id:lower()] == true
        end
    elseif types.Clothing.objectIsInstance(item) then
        local ok, rec = pcall(types.Clothing.record, item)
        if ok and rec and rec.id then
            return CIRCLETS_RECORD_IDS[rec.id:lower()] == true
        end
    end
    return false
end

local function circletHandler(item, actor)
    if not isCircletItem(item) then return end
    if not types.Player.objectIsInstance(actor) then return end
    actor:sendEvent('Circlets_PromptEquip', { itemId = item.recordId })
    return false  -- cancel the actual equip
end

local registered = false
local function register()
    if registered then return end
    if not I.ItemUsage then
        print('[CosmeticCirclets] ItemUsage unavailable')
        return
    end
    registered = true
    I.ItemUsage.addHandlerForType(types.Clothing, circletHandler)
    I.ItemUsage.addHandlerForType(types.Armor,    circletHandler)
    print('[CosmeticCirclets] handler registered via ItemUsage')
end

return {
    engineHandlers = {
        onInit = register,
        onLoad = register,
    },
}
