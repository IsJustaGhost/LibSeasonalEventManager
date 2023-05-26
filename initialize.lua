
local LIB_IDENTIFIER, LIB_VERSION = "LibSeasonalEventManager", 01

if _G[LIB_IDENTIFIER] and _G[LIB_IDENTIFIER].version > LIB_VERSION then
	return
end

--[[
	This lib is self running.
	Using it normally should only require registering the update callback.
	
	The callback returns ([bool]eventActive, [object]eventOject)
		eventActive (true or false)
		
		
	This lib checks for running events on load and, on daily reset. 
	then, if an event is active, creates the eventObject based on 1 of the 4 detectable events, 
	or default info to be updated later by quest or item loot.
		
	eventOject:GetIndex()
		Used mainly by the lib to get the event info or saving by the add-on to compare later.
	eventOject:GetType()
		Currently, eventType is none, unknown, tickets
	eventOject:GetRewardsBy()
		Loot, quest, target (Jubilee Cake)
	eventOject:GetMaxDailyRewards()
		Last known amount of special rewards. Number of tickets per day
	eventOject:IsSameEvent(eventIndex)
		Used in add-ons to see if it's the same event that was previously running
		if add-on is saving eventIndex
		
		
		May add more eventOject functions later for descriptions and other event info.
]]

---------------------------------------------------------------------------
-- lib
---------------------------------------------------------------------------
local lib = ZO_InitializingObject:Subclass()
lib.name = LIB_IDENTIFIER
lib.version = LIB_VERSION
_G[LIB_IDENTIFIER] = lib

local svVersion = 1
local svDefaults = {
	eventData = var_blankEvent
}

function lib:Initialize()
	local function OnLoaded(_, name)
		if name ~= LIB_IDENTIFIER then return end
		EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED)
		
		self.savedVars = ZO_SavedVars:NewAccountWide('LibSesonalEventManager_SV_Data', svVersion, nil, svDefaults, GetWorldName(), "$AllAccounts")
		self.eventData = self.savedVars.eventData
		
		self:UpdateStrings()
		self:ChangeState(self:CheckForActiveEvent())
	end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED, OnLoaded)
end
