---@meta

--- Represents a line of dialog to be spoken by an NPC in a conversation
--- @class dialog
--- @field public soundPath filePath The file path to the sound file for the dialog line
--- @field public subtitle string The subtitle text for the dialog line
--- @field public animation animation|nil The animation to be played during the dialog line
--- @field public template dialogTemplateName|nil Optionally, the name of the dialog template to use for this dialog line
--- @field public duration number The duration of the dialog line in seconds

--- A condition for quest index checks
--- @class questIndexCondition
--- @field public value questIndex The quest index value to check against
--- @field public operator operator The operator to use for the comparison

--- A time of day condition for conversations
---@class timeOfDayCondition
---@field public from number The starting hour (0-23) for the time of day condition
---@field public to number The ending hour (0-23) for the time of day condition

--- Encapsulates the various conditions that can be applied to a conversation configuration
--- @class conversationConditions
--- @field public dependsOn conversationId[]|nil The IDs of previous conversations that this conversation depends on
--- @field public raceAndSex string[]|nil The race and sex of NPCs eligible for the conversation
--- @field public blacklistNpcs objectId[]|nil NPC object IDs that are excluded from the conversation
--- @field public whitelistNpcs objectId[]|nil NPC object IDs that are included in the conversation
--- @field public blacklistFactions factionId[]|nil Faction IDs that are excluded from the conversation
--- @field public whitelistFactions factionId[]|nil Faction IDs that are included in the conversation
--- @field public blacklistClass classId[]|nil NPC class IDs that are excluded from the conversation
--- @field public whitelistClass classId[]|nil NPC class IDs that are included in the conversation
--- @field public blacklistCells cellId[]|nil Cell IDs that are excluded from the conversation
--- @field public whitelistCells cellId[]|nil Cell IDs that are included in the conversation
--- @field public questIndex { [questId]: questIndexCondition }|nil Quest index conditions for specific quests
--- @field public exteriorsOnly boolean|nil Whether the conversation is restricted to exterior cells
--- @field public interiorsOnly boolean|nil Whether the conversation is restricted to interior cells
--- @field public timeOfDay timeOfDayCondition|nil Time of day condition for the conversation
--- @field public blacklistWeathers weather[]|nil Weather types that are excluded from the conversation
--- @field public whitelistWeathers weather[]|nil Weather types that are included in the conversation
--- @field public whitelistProvinces string[]|nil Provinces that are included in the conversation
--- @field public blacklistProvinces string[]|nil Provinces that are excluded from the conversation
--- @field public whitelistRegions string[]|nil Regions that are included in the conversation
--- @field public blacklistRegions string[]|nil Regions that are excluded from the conversation

--- Configuration for actions to take upon conversation completion
--- @class onCompletionConfiguration
--- @field public journalEntry string|nil A journal entry to add upon completion
--- @field public questIndex  { [questId]: questIndex }|nil Quest index updates upon completion
--- @field public startCombat boolean|nil Whether the two participants should enter combat upon completion
--- @field public customCallbacks filePath[]|nil Paths to custom callback Lua scripts to execute upon completion

--- Represents the priority of a conversation when selecting between multiple configurations
---@class conversationPriority
---@field public value number The priority value (higher values indicate higher priority)
---@field public weight? number *Optional* The weight of the priority. A number between 0 and 1 representing the chance that a priority will be honored during selection. If not set, defaults to 1 (always honored).

--- Represents a conversation configuration
--- @class conversationConfiguration
--- @field public name string The display name of the conversation
--- @field public id string The unique identifier for the conversation represented by the relative file path of the configuration file
--- @field public participants objectId[]|nil The object IDs of NPCs participating in the conversation
--- @field public repeatable boolean Whether the conversation can be repeated
--- @field public static boolean Whether the conversation is static (between non-moving NPCs) or not (between wandering NPCs)
--- @field public conditions conversationConditions|nil The conditions that must be met for the conversation to occur
--- @field public onCompletion onCompletionConfiguration|nil Actions to take upon conversation completion
--- @field public dialog dialog[] The dialog lines that make up the conversation
--- @field public priority conversationPriority|nil The priority of the conversation (higher values indicate higher priority)
--- @field public callbacks conversationCallback[] The callbacks to execute upon completion (dynamically created when the configurations are loaded)
