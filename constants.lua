
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

lib.GetString = function getString(str)
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

lib.constants = {}

-- Get language specific collectible name for current year
local jubileeCake2016 = GetCollectibleName(356)
function getCurrentJubileeCakeName()
	return zo_strformat(jubileeCake2016:gsub('[%d]+', '<<1>>'), select(3, getCurrentYear()))
end

lib.constants.currentJubileeCakeName = getCurrentJubileeCakeName

lib.constants.maxTickets = 12
lib.constants.currentEventNone = 0
lib.constants.currentEventUnknown = 1
lib.constants.eventTypeNone = 0
lib.constants.eventTypeUnknown = 1
lib.constants.eventTypeTickets = 2
lib.constants.rewardsByNone = 0
lib.constants.rewardsByUnknown = 1
lib.constants.rewardsByQuest = 2
lib.constants.rewardsByLoot = 3
lib.constants.rewardsByTarget = 4
lib.constants.stringEmpty = ''

--[[
local l_EVENT_ANNIVERSARY		= 2
local l_EVENT_JESTER			= 3
local l_EVENT_MAYHEM			= 4
local l_EVENT_WITCHES			= 5
local l_EVENT_MAX_KNOWN		= 5

local l_EVENT_NEWLIFE			= 6
local l_EVENT_UNDAUNTED		= 7
local l_EVENT_TRIBUNAL		= 8
local l_EVENT_ZENITHAR		= 9
local l_EVENT_DARKHEART		= 10
local l_EVENT_STEADFAST		= 11
]]
