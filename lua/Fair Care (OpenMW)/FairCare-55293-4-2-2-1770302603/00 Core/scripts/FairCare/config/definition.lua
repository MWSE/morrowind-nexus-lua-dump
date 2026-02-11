local core = require('openmw.core')

local module = {
    MOD_NAME = "FairCare",
    potionScriptPath = "scripts/FairCare/potion.lua",
    isLuaApiRecentEnough = core.API_REVISION >= 68,
    isOpenMW049 = core.API_REVISION > 29,
    interfaceVersion = 1.1,
    saveVersion = 4.2,
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.events = {
    -- actor
    hbfs_onActorReady = "HBFS_on_actor_ready",
    onActorActive = key("on_actor_active"),
    addTouchHealSpell = key("add_touch_heal_spell"),
    removeTouchHealSpell = key("remove_touch_heal_spell"),
    clearPotionsState = key("clear_potions_state"),
    addPotions = key("add_potions"),
    onCombatStart = key("on_combat_start"),
    sendHealRequests = key("send_heal_requests"),
    answerHealMe = key("answer_heal_me"),
    applyFakeHealSpell = key("apply_fake_heal_spell"),
    clearHealer = key("clear_healer"),
    askHealMe = key("ask_heal_me"),
    healFriend = key("heal_friend"),
    declineHealHelp = key("decline_heal_help"),
    clearHealerState = key("clear_healer_state"),
    getFollowRoot = key("get_follow_root"),
    gatherFollowers = key("gather_followers"),
    addFollowTeamMembers = key("add_follow_team_members"),
    updateFollowBounds = key("update_follow_bounds"),
    clearFollowing = key("clear_following"),
    addFollower = key("add_follower"),
    clearFollower = key("clear_follower"),
    -- global
    addPotions = key("add_potions"),
    clearState = key("clear_state"),
    clearActorData = key("clear_actor_data"),
    -- debug
    testPosition = key("test_position"),
}

module.renderers = {
    number = module.MOD_NAME .. "Number",
}

return module