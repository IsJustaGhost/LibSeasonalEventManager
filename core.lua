
local LIB_IDENTIFIER, LIB_VERSION = "LibSeasonalEventManager", 01
if _G[LIB_IDENTIFIER] and _G[LIB_IDENTIFIER].version > LIB_VERSION then
	return
end

local lib = _G[LIB_IDENTIFIER]

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
		
		
		
		---------------------------------------------------------------------------------
		
		For comparing events with quests.
		The questIds are converted to names on load. 
		Then, on quest pickup, it compares the questNames if the event has not been identified.
		
		Since events can have quests in different zones, each zone's quests are added separately under it's zoneIndex
		['quests'] = {
			[zoneIndex] = {questId},
		},
		
		EVENTS_TO_INDEX_MAP
			Allows dynamically generate an index for all events to be used across loading for event lookup.
			EVENTS_TO_INDEX_MAP[eventIndex] = eventInfo
		
		ITEM_TO_INDEX_MAP
			Allows simplifying event lookup by itemId.
			ITEM_TO_INDEX_MAP[itemId] = eventIndex
		
		QUEST_TO_INDEX_MAP
			Allows simplifying event lookup by questName.
			QUEST_TO_INDEX_MAP[zoneIdex][questName] = eventIndex
		
		EVENTS_TO_INDEX_MAP[ ITEM_TO_INDEX_MAP[itemId] ]
		EVENTS_TO_INDEX_MAP[ QUEST_TO_INDEX_MAP[zoneIdex][questName] ]
]]
---------------------------------------------------------------------------
-- Locals
---------------------------------------------------------------------------

local var_TICKETS_MAX			= lib.constants.maxTickets

local var_EVENT_NONE			= lib.constants.currentEventNone
local var_EVENT_UNKNOWN		= lib.constants.currentEventUnknown

local var_EVENT_TYPE_NONE		= lib.constants.eventTypeNone
local var_EVENT_TYPE_UNKNOWN	= lib.constants.eventTypeUnknown
local var_EVENT_TYPE_TICKETS	= lib.constants.eventTypeTickets
local var_EVENT_TYPE_BG		= lib.constants.eventTypeBG

local var_REWARDS_BY_NONE		= lib.constants.rewardsByNone
local var_REWARDS_BY_UNKNOWN	= lib.constants.rewardsByUnknown
local var_REWARDS_BY_QUEST	= lib.constants.rewardsByQuest
local var_REWARDS_BY_LOOT		= lib.constants.rewardsByLoot
local var_REWARDS_BY_TARGET	= lib.constants.rewardsByTarget

local var_EmptyString 		= lib.constants.stringEmpty

local getString 			= lib.GetString

local defaultEventInfo = {
	['index'] 		= var_EVENT_NONE,
	['eventType'] 	= var_EVENT_TYPE_NONE,
	['rewardsBy'] 	= var_REWARDS_BY_NONE,
}

local questTypes = {
	[QUEST_TYPE_NONE] = true,
	[QUEST_TYPE_GROUP] = true,
	[QUEST_TYPE_HOLIDAY_EVENT] = true,
}


local standardBatlegrounds = {
	[1] = true,		-- Group Random Battleground
	[2] = true,		-- Group Random Battleground
	[67] = true,	-- Solo Random Battleground
	[68] = true,	-- Solo Random Battleground
}

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
local function selectSubzone(zoneIndex, subzoneIndex)
	local normalizedX, normalizedZ = GetPOIMapInfo(zoneIndex, subzoneIndex)
	if ProcessMapClick(normalizedX, normalizedZ) == SET_MAP_RESULT_MAP_CHANGED then
		CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged", true)
		return SET_MAP_RESULT_MAP_CHANGED
	end
end

local function isMapLocationVisible(zoneIndex, subzoneIndex, locIndex)
	local currentZoneIndex = GetCurrentMapZoneIndex()
	-- make sure the map is currently displaying the correct zone
	WORLD_MAP_MANAGER:SetMapById((GetMapIdByIndex(zoneIndex)))
	
	if subzoneIndex > 0 then
		if selectSubzone(zoneIndex, subzoneIndex) ~= SET_MAP_RESULT_MAP_CHANGED then
			return false
		end
	end

	local isVisible = IsMapLocationVisible(locIndex)
	
	-- Lets change the map back to the previously selected map or player's position.
	jo_callLater(LIB_IDENTIFIER .. '_ResetMap', function()
		if currentZoneIndex > 0 then
			WORLD_MAP_MANAGER:SetMapById((GetMapIdByIndex(currentZoneIndex)))
		elseif SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
			CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged", true)
		end
	end, 100)

	return isVisible
end

local function doesEventHaveVisiblePin(locationInfo)
	return isMapLocationVisible(locationInfo.zoneIndex, locationInfo.subzoneIndex, locationInfo.locationIndex)
end

---------------------------------------------------------------------------
-- lib
---------------------------------------------------------------------------
local svVersion = 1
local svDefaults = {
	eventData = {
		eventIndex = var_EVENT_NONE,
		eventType = var_EVENT_TYPE_NONE,
	}
}

function lib:Initialize()
	local function OnLoaded(_, name)
		if name ~= LIB_IDENTIFIER then return end
		EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED)
		
		self.savedVars = ZO_SavedVars:NewAccountWide('LibSesonalEventManager_SV_Data', svVersion, nil, svDefaults, GetWorldName(), "$AllAccounts")
		self.eventData = self.savedVars.eventData
		
		self:SetActiveEventType(var_EVENT_TYPE_NONE)
		
		local function onPlayerActivated()
			EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED)
		--	d( '|cFF00FF' .. LIB_IDENTIFIER '|r' .. " version: " .. LIB_VERSION)
		end
		EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_PLAYER_ACTIVATED, onPlayerActivated)
	end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED, OnLoaded)
end

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
function lib:RegisterEvents()
	local function onEventAnnouncementsUpdated(event)
		d( '--- ' .. event .. ' ---')
		-- refresh
	end
	-- I want to see if these will be usefull.
    EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_MARKET_ANNOUNCEMENT_UPDATED, function() onEventAnnouncementsUpdated('EVENT_MARKET_ANNOUNCEMENT_UPDATED') end)
    EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_EVENT_ANNOUNCEMENTS_UPDATED, function() onEventAnnouncementsUpdated('EVENT_EVENT_ANNOUNCEMENTS_UPDATED') end)
    EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_EVENT_ANNOUNCEMENTS_RECEIVED, function() onEventAnnouncementsUpdated('EVENT_EVENT_ANNOUNCEMENTS_RECEIVED') end)
end

function lib:RegisterLookupEvents()
	local function onQuestAdded(eventId, questIndex, questName)
		local rewardDataList = SYSTEMS:GetObject(ZO_INTERACTION_SYSTEM_NAME):GetRewardData(questIndex)
		
		if #rewardDataList == 0 then return end
		-- We only need to refresh the interaction if event tickets are present.
		for i, data in ipairs(rewardDataList) do
			if data.rewardType == REWARD_TYPE_EVENT_TICKETS then
			
				if self:GetActiveEventIndex() == var_EVENT_UNKNOWN then
					local eventIndex = self:GetEventIndexByQuestName(questName)
					if eventIndex then
						self:UpdateActiveEventIndex(eventIndex)
					end
				end
				return 
			end
		end
	end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_QUEST_ADDED, onQuestAdded)
	
    local function onInventorySingleSlotUpdate(eventId, bagId, slotId, isNewItem, itemIdsoundCategory, updateReason, stackCountChange)
		if stackCountChange > 0 then
			if self:GetActiveEventIndex() > var_EVENT_UNKNOWN then
				local itemId = GetItemId(bagId, slotId)
				local eventIndex = self:GetEventIndexByItemId(itemId)
				if eventIndex then
					EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
					self:UpdateActiveEventIndex(eventIndex)
				end
			end
		end
    end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, onInventorySingleSlotUpdate)
end

function lib:UnregisterEvents()
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_MARKET_ANNOUNCEMENT_UPDATED)
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_EVENT_ANNOUNCEMENTS_UPDATED)
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_EVENT_ANNOUNCEMENTS_RECEIVED)
	self:UnregisterLookupEvents()
end

function lib:UnregisterLookupEvents()
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_QUEST_ADDED)
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------

function lib:RegisterOnDailyReset()
	EVENT_MANAGER:UnregisterForUpdate(self.name .. '_OnUpdate')
	
	local secondsRemaining = self.GetDailyResetTimeRemainingSeconds()
	if secondsRemaining <= 0 then
		zo_callLater(function()
			self:RegisterOnDailyReset()
		end, 100)
		return
	end
	
	local function onUpdate()
		if self.isUpdating then
			-- In the case UpdateEventData was called by another function, we will run onUpdate again.
			-- It can overwrite changes made if UpdateEventData was called with a new eventIndex.
			zo_callLater(onUpdate, 100)
			return
		end
		self:OnUpdate()
	end
	EVENT_MANAGER:RegisterForUpdate(self.name .. '_OnUpdate', (secondsRemaining * 1000) + 1, onUpdate)
end

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
function lib:GetImresarioFromMap()
	local zoneIndex = 2
	local subzoneIndex = 68
	local locIndex = 24
	
	local isTicketEvent = isMapLocationVisible(zoneIndex, subzoneIndex, locIndex)
	return isTicketEvent, var_EVENT_TYPE_TICKETS
end

function lib:GetActiveBattlegound()
	for _, activityType in pairs({LFG_ACTIVITY_BATTLE_GROUND_CHAMPION,LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION,LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL}) do
		for id, location in pairs(ZO_ACTIVITY_FINDER_ROOT_MANAGER.locationSetsLookupData[activityType]) do
			if not standardBatlegrounds[id] then
				if location.isActive then
					return id
				end
			end
		end
	end
end

function lib:CheckForAndGetActiveEventType()
	if self:GetImresarioFromMap() then
		return var_EVENT_TYPE_TICKETS
	elseif self:GetActiveBattlegound() ~= nil then
		return var_EVENT_TYPE_BG
	end
	
	return var_EVENT_TYPE_NONE
end

function lib:CheckForActiveEvent()
	local activeType = self:CheckForAndGetActiveEventType()
	
	self:SetActiveEventType(activeType)
	if activeType == var_EVENT_TYPE_BG then
		local bgId = self:GetActiveBattlegound()
		self.eventData.eventIndex = self:GetEventIndexByBattleGroundId(bgId)
	end
	
	return activeType ~= var_EVENT_TYPE_NONE
end

function lib:Activate()
	self:ResetToSavedEvent()
	
	if self:GetActiveEventIndex() == var_EVENT_UNKNOWN then
		if self.eventData.eventType == var_EVENT_TYPE_BG then
		else
			for questIndex = 1, GetNumJournalQuests() do
				local questName, _, _, _, _, _, _, _, _, questType = GetJournalQuestInfo(questIndex)
				if questTypes[questType] then
					local eventIndex = self:GetEventIndexByQuestName(questName)
					if eventIndex then
						self:UpdateActiveEventIndex(eventIndex)
						return
					end
				end
			end
		end
	end
end

function lib:Deactivate()
	self:SetActiveEventType(var_EVENT_TYPE_NONE)
	self.eventData.eventIndex = var_EVENT_NONE
	
	self.currentEvent = self.defaultEvent
	self:UnregisterEvents()
end

function lib:SetActive(isEventActive)
	self.active = isEventActive
end

function lib:OnUpdate()
	if self.isUpdating then return end
	self.isUpdating = true
	
	local isEventActive = self:CheckForActiveEvent()
	
	if isEventActive then
		if not self.active then
			-- activate
			self:Activate()
		end
		self:UpdateActiveEventIndex(self.eventData.eventIndex)
	elseif self.active then
		-- deactivate
		self:Deactivate()
	end
	
	self:SetActive(isEventActive)
	self:RegisterOnDailyReset()
	CALLBACK_MANAGER:FireCallbacks('On_Seasonal_Event_Updated', isEventActive, self.currentEvent)
	self.isUpdating = false
end

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
function lib:ResetToSavedEvent()
	local eventIndex = self.eventData.eventIndex
	if eventIndex then
		self:UpdateActiveEventIndex(eventIndex)
	end
end

function lib:SetActiveEventType(eventType)
	self.eventData.eventType = eventType
end

function lib:UpdateActiveEvent(eventIndex)
	local eventInfo = self:GetEventInfoByIndex(eventIndex)
	
	if eventInfo ~= nil then
		local newEvent = self.event_class:New(eventInfo)
		self.currentEvent = newEvent
		self:SetActiveEventType(eventInfo.eventType)
	else
		self.currentEvent = self.defaultEvent
	end
	
	-- Need to register events if the event was not detected.
	if self:GetActiveEventIndex() > var_EVENT_UNKNOWN then
		self:UnregisterLookupEvents()
	else
		self:RegisterLookupEvents()
	end
end

function lib:UpdateActiveEventIndex(eventIndex)
	local function isNewEvent(eventIndex)
	--	return self.eventData.eventIndex ~= eventIndex
		return self:GetActiveEventIndex() ~= eventIndex
	end
	
	if eventIndex == var_EVENT_NONE then
		eventIndex = self:GetEventIndexByVisibleLocation()
	end
	if isNewEvent(eventIndex) then
		self.eventData.eventIndex = eventIndex
		self:UpdateActiveEvent(eventIndex)
	end
end

---------------------------------------------------------------------------
-- Event info parsing
---------------------------------------------------------------------------
function lib:GetEventInfoByIndex(eventIndex)
	return self.eventsToIndexMap[eventIndex]
end

function lib:GetEventIndexByQuestName(questName)
	return self.indexToQuestNameMap[questName]
end

function lib:GetEventIndexByItemId(itemId)
	return self.indexToItemIdMap[itemId]
end

function lib:GetEventIndexByBattleGroundId(bgId)
	return self.indexToBattlegroundIdMap[bgId]
end

function lib:GetEventIndexByVisibleLocation()
	for eventIndex, location in pairs(self.locationToIndexMap) do
		if doesEventHaveVisiblePin(location) then
			return eventIndex
		end
	end

	return var_EVENT_UNKNOWN
end

---------------------------------------------------------------------------
-- Deferred initialization
---------------------------------------------------------------------------
-- Mapping the event data allow for simplifying lookup.
do
	local function mapIndexByKey(self, key, eventIndex, source, indexFunc)
		for k, v in pairs(source) do
			self[key][indexFunc(v)] = eventIndex
		end
	end
	
	local function mapIndexToQuestName(self, eventIndex, quests)
		mapIndexByKey(self, 'indexToQuestNameMap', eventIndex, quests, function(questId) return GetQuestName(questId) end)
	end
	local function mapIndexToItemId(self, eventIndex, items)
		mapIndexByKey(self, 'indexToItemIdMap', eventIndex, items, function(itemId) return itemId end)
	end
	local function mapIndexToTargetName(self, eventIndex, targets)
		mapIndexByKey(self, 'indexToTargetNameMap', eventIndex, targets, function(target) return getString(target) end)
	end
	local function mapIndexToBattlegroundId(self, eventIndex, battlegrounds)
		mapIndexByKey(self, 'indexToBattlegroundIdMap', eventIndex, battlegrounds, function(bgId) return bgId end)
	end

	local function mapLocationToIndex(self, eventIndex, location)
		self.locationToIndexMap[eventIndex] = location
	end
	
	function lib:MapEventInfo()
		local eventsToIndexMap = self.eventsToIndexMap
		
		for _, eventInfo in ipairs(self.events) do
			table.insert(eventsToIndexMap, eventInfo)
			eventInfo.index = #eventsToIndexMap
			
			if eventInfo.quests then
				mapIndexToQuestName(self, eventInfo.index, eventInfo.quests)
			end
			if eventInfo.items then
				mapIndexToItemId(self, eventInfo.index, eventInfo.items)
			end
			if eventInfo.targets then
				mapIndexToTargetName(self, eventInfo.index, eventInfo.targets)
			end
			if eventInfo.location then
				mapLocationToIndex(self, eventInfo.index, eventInfo.location)
			end
			if eventInfo.battlegrounds then
				mapIndexToBattlegroundId(self, eventInfo.index, eventInfo.battlegrounds)
			end
		end

		self.eventsToIndexMap = eventsToIndexMap
	end
end

function lib:RegisterStrings()
	-- Dynamically generate string ids and register strings
	local strings = {}

	for i, _string in ipairs(self.strings.titles) do
		strings['SI_EVENTS_MANAGER_TITLE' .. i] = _string
	end
	for i, _string in ipairs(self.strings.descriptions) do
		strings['SI_EVENTS_MANAGER_DESCRIPTION' .. i] = _string
	end
	
	for stringId, stringValue in pairs(strings) do
		ZO_CreateStringId(stringId, stringValue)
		SafeAddVersion(stringId, 1)
	end
end

function lib:OnDeferredInitialize()
	if self.initialized then return end
	self.initialized = true
	
	self:RegisterStrings()
	self:MapEventInfo()
	self:OnUpdate()
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
function lib.GetDailyResetTimeRemainingSeconds()
	return GetTimeUntilNextDailyLoginRewardClaimS()
end

function lib:IsEventActive()
	return self.eventData.eventType ~= var_EVENT_TYPE_NONE
end

function lib:GetActiveEventIndex()
	if self.currentEvent then
		return self.currentEvent:GetIndex()
	end
	return var_EVENT_NONE
end

function lib:GetActiveEventType()
	return self.eventData.eventType or var_EVENT_TYPE_NONE
end

function lib:GetCurrentEvent()
	return self.currentEvent or self.defaultEvent
end

function lib:GetEventIndexByFilter(eventType)
	
end

function lib:WouldTicketsExcedeMax(eventTickets)
	return ZO_SharedInteraction:WouldCurrencyExceedMax(REWARD_TYPE_EVENT_TICKETS, eventTickets)
end

function lib:RegisterUpdateCallback(callback)
	self:OnDeferredInitialize()
	-- We want to fire the callback immediately so the addon gets updated without having to wait for event updates.
	if self.eventData then
		zo_callLater(function()
			callback(self.active, self:GetCurrentEvent())
		end, 500)
	end
	CALLBACK_MANAGER:RegisterCallback('On_Seasonal_Event_Updated', callback)
end

---------------------------------------------------------------------------
-- currentEvent info
---------------------------------------------------------------------------
function lib:GetEventTitle()
	if self.currentEvent then
		return self.currentEvent:GetTitle()
	end
	return var_EmptyString
end

function lib:GetEventDescription()
	if self.currentEvent then
		return self.currentEvent:GetDescription()
	end
	return var_EmptyString
end

function lib:GetEventInfo()
	if self.currentEvent then
		return self.currentEvent:GetInfo()
	end
	return var_EmptyString, var_EmptyString
end

function lib:GetEventMaxDailyRewards()
	if self.currentEvent then
		return self.currentEvent:GetMaxDailyRewards()
	end
	return var_EVENT_NONE
end

function lib:IsImpresarioVisible()
	return self.impresario or false
end

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
IJA_Seasonal_Event_Manager = lib:New()

if not jo_callLater then
	function jo_callLater(id, func, ms, ...)
		local params = {...}
		if ms == nil then ms = 0 end
		local name = "JO_CallLater_".. id
		EVENT_MANAGER:UnregisterForUpdate(name)
		
		EVENT_MANAGER:RegisterForUpdate(name, ms,
			function()
				EVENT_MANAGER:UnregisterForUpdate(name)
				func(unpack(params))
			end)
		return id
	end
end
--[[

--	/script d( IJA_Seasonal_Event_Manager:GetActiveBattlegound())
function lib:GetActiveBattlegound()
	local activeBattleground = 0
	
	for _, activityType in pairs({LFG_ACTIVITY_BATTLE_GROUND_CHAMPION,LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION,LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL}) do
		for i, location in pairs(ZO_ACTIVITY_FINDER_ROOT_MANAGER.locationSetsLookupData[activityType]) do
			if location.isActive then
				--activeBattleground = 
			end
			d( zo_strformat('Id: <<1>>, Name: <<2>>', location.id, location.description))
		end
	end
end
/script IJA_Seasonal_Event_Manager.savedVars = {}

/script d( IJA_Seasonal_Event_Manager:GetEventTitle())
/script d( IJA_Seasonal_Event_Manager:GetEventDescription())
/script d( IJA_Seasonal_Event_Manager:GetEventInfo())
/script d( IJA_Seasonal_Event_Manager:GetEventMaxDailyRewards())




        for questIndex = 1, GetNumJournalQuests() do
			local questName, _, _, _, _, _, _, _, _, questType = GetJournalQuestInfo(questIndex)
			if questType == then
				local eventIndex = self:GetEventIndexByQuestName(questName)
				if eventIndex then
					self:UpdateActiveEventIndex(eventIndex)
				end
			end
        end
]]

--[[ Example usage
local wouldTicketsExcedeMax = IJA_Seasonal_Event_Manager:WouldTicketsExcedeMax(eventTickets)


	local function onSeasonalEventUpdate(active, eventObject)
		if eventObject == nil then return end
		
		if eventObject:GetRewardsBy() > l_REWARDS_BY_NONE then
			if active then
				local lastEventIndex = self.savedVars.eventInfo.eventIndex
				if not eventObject:IsSameEvent(lastEventIndex) then
					-- start new event
					self:SetUpEvent(eventObject)
				else
					-- reset for dailies?
					self:ResetDailyInfo()
				end
				self:UpdateDailyIconTexture()
			end
			
			self:RefreshGamepadMenu()
			self:ChangeState(active)
		end
	end
	
	IJA_Seasonal_Event_Manager:RegisterUpdateCallback(onSeasonalEventUpdate)
]]




