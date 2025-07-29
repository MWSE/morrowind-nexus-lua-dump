local core = require('openmw.core')

local module = {
    MOD_NAME = "FairCare",
    potionScriptPath = "scripts/FairCare/potion.lua",
    isLuaApiRecentEnough = core.API_REVISION >= 68,
    isOpenMW049 = core.API_REVISION > 29,
    interfaceVersion = 1.1,
    saveVersion = 3.9,
}

module.events = {
    -- actor
    hbfs_onActorReady = "hbfs_onActorReady",
    onActorActive = "fairCare_onActorActive",
    addTouchHealSpell = "fairCare_addTouchHealSpell",
    removeTouchHealSpell = "fairCare_removeTouchHealSpell",
    clearPotionsState = "fairCare_clearPotionsState",
    addPotions = "fairCare_addPotions",
    onCombatStart = "fairCare_onCombatStart",
    sendHealRequests = "fairCare_sendHealRequests",
    answerHealMe = "fairCare_answerHealMe",
    applyFakeHealSpell = "fairCare_applyFakeHealSpell",
    clearHealer = "fairCare_clearHealer",
    askHealMe = "fairCare_askHealMe",
    healFriend = "fairCare_healFriend",
    declineHealHelp = "fairCare_declineHealHelp",
    clearHealerState = "fairCare_clearHealerState",
    getFollowRoot = "fairCare_getFollowRoot",
    gatherFollowers = "fairCare_gatherFollowers",
    addFollowTeamMembers = "fairCare_addFollowTeamMembers",
    updateFollowBounds = "fairCare_updateFollowBounds",
    clearFollowing = "fairCare_clearFollowing",
    addFollower = "fairCare_addFollower",
    clearFollower = "fairCare_clearFollower",
    -- global
    addPotions = "fairCare_addPotions",
    clearState = "fairCare_clearState",
    clearActorData = "fairCare_clearActorData",
    -- debug
    testPosition = "fairCare_testPosition",
}

module.renderers = {
    number = module.MOD_NAME .. "Number",
}

return module