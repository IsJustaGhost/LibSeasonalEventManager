
local LIB_IDENTIFIER, LIB_VERSION = "LibSeasonalEventManager", 01
if _G[LIB_IDENTIFIER] and _G[LIB_IDENTIFIER].version > LIB_VERSION then
	return
end

local lib = ZO_InitializingObject:Subclass()
lib.name = LIB_IDENTIFIER
lib.version = LIB_VERSION
_G[LIB_IDENTIFIER] = lib

local function getCurrentYear()
	return os.date("*t").year
end

lib.GetCurrentYear = getCurrentYear

-- Need to set up this before "events.lua".
lib.GetString = function(str)
	if type(str) == 'function' then
		return str()
	end
	return str
end

lib.eventsToIndexMap = {}
lib.locationToIndexMap = {}
lib.indexToQuestNameMap = {}
lib.indexToItemIdMap = {}
lib.indexToTargetNameMap = {}
lib.indexToBattlegroundIdMap = {}

lib.constants = {}

-- Get language specific collectible name for current year
local jubileeCake2016 = GetCollectibleName(356)
lib.constants.currentJubileeCakeName = function()
	-- How will this work on jp and other nonstandard text?
	return zo_strformat(jubileeCake2016:gsub('[%d]+', '<<1>>'), select(3, getCurrentYear()))
end

lib.constants.maxTickets			= 12
lib.constants.currentEventNone		= 0
lib.constants.currentEventUnknown	= 1

lib.constants.eventTypeNone			= 0
lib.constants.eventTypeUnknown		= 1
lib.constants.eventTypeTickets		= 2
lib.constants.eventTypeBG			= 3

lib.constants.rewardsByNone			= 0
lib.constants.rewardsByUnknown		= 1
lib.constants.rewardsByQuest		= 2
lib.constants.rewardsByLoot			= 3
lib.constants.rewardsByTarget		= 4
lib.constants.stringEmpty			= ''

--[[
local var_EVENT_ANNIVERSARY		= 2
local var_EVENT_JESTER			= 3
local var_EVENT_MAYHEM			= 4
local var_EVENT_WITCHES			= 5
local var_EVENT_MAX_KNOWN		= 5

local var_EVENT_NEWLIFE			= 6
local var_EVENT_UNDAUNTED		= 7
local var_EVENT_TRIBUNAL		= 8
local var_EVENT_ZENITHAR		= 9
local var_EVENT_DARKHEART		= 10
local var_EVENT_STEADFAST		= 11
]]
