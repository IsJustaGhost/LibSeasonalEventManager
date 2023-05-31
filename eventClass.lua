
local LIB_IDENTIFIER, LIB_VERSION = "LibSeasonalEventManager", 01
if _G[LIB_IDENTIFIER] and _G[LIB_IDENTIFIER].version > LIB_VERSION then
	return
end

local lib = _G[LIB_IDENTIFIER]

---------------------------------------------------------------------------
-- Event locals
---------------------------------------------------------------------------
local var_EVENT_NONE			= lib.constants.currentEventNone
local var_EVENT_TYPE_NONE		= lib.constants.eventTypeNone
local var_REWARDS_BY_NONE		= lib.constants.rewardsByNone

local defaultEventInfo = {
	['index'] 		= var_EVENT_NONE,
	['eventType'] 	= var_EVENT_TYPE_NONE,
	['rewardsBy'] 	= var_REWARDS_BY_NONE,
}

---------------------------------------------------------------------------
-- Event class
---------------------------------------------------------------------------
local event_class = ZO_InitializingObject:Subclass()

function event_class:Initialize(eventInfo)
	zo_mixin(self, eventInfo)
	
	if self.index then
		self.title = zo_strformat('<<1>> <<2>>', GetString('SI_EVENTS_MANAGER_TITLE', self.index), GetString(SI_NOTIFICATIONTYPE19))
		self.description = GetString('SI_EVENTS_MANAGER_DESCRIPTION', self.index)
	end
end

function event_class:GetIndex()
	return self.index
end

function event_class:GetType()
	return self.eventType
end

function event_class:GetRewardsBy()
	return self.rewardsBy
end

function event_class:GetMaxDailyRewards()
	return self.maxDailyRewards or 0
end

function event_class:IsSameEvent(eventIndex)
	return self.index == eventIndex
end

function event_class:GetTitle()
	return self.title
end

function event_class:GetDescription()
	return self.description
end

function event_class:GetInfo()
	return self.title, self.description
end

lib.defaultEvent = event_class:New(defaultEventInfo)
lib.event_class = event_class

--	local newEvent = self.event_class:New(eventInfo)

