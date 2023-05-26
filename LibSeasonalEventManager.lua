
local LIB_IDENTIFIER, LIB_VERSION = "LibSeasonalEventManager", 01

if _G[LIB_IDENTIFIER] and _G[LIB_IDENTIFIER].version > LIB_VERSION then
	return
end

---------------------------------------------------------------------------
-- Locals
---------------------------------------------------------------------------
-- returns [int]day, [int]month, [int]year
local function getCurrentDate()
	local date = os.date ("*t")
	return tonumber(date.day), tonumber(date.month), tonumber(date.year)
end

-- Get language specific collectible name
local jubileeCake2016 = GetCollectibleName(356)
local currentYearJubileeCake = zo_strformat(jubileeCake2016:gsub('[%d]+', '<<1>>'), select(3, getCurrentDate()))

local VAR_TICKETS_MAX	= 12

local VAR_EVENT_NONE			= 0
local VAR_EVENT_UNKNOWN			= 1
--local VAR_EVENT_ANNIVERSARY		= 2
--local VAR_EVENT_JESTER			= 3
--local VAR_EVENT_MAYHEM			= 4
--local VAR_EVENT_WITCHES			= 5
--local VAR_EVENT_MAX_KNOWN		= 5

local VAR_EVENT_NEWLIFE			= 6
local VAR_EVENT_UNDAUNTED		= 7
local VAR_EVENT_TRIBUNAL		= 8
local VAR_EVENT_ZENITHAR		= 9
local VAR_EVENT_DARKHEART		= 10
local VAR_EVENT_STEADFAST		= 11

local VAR_EVENT_TYPE_NONE		= 0
local VAR_EVENT_TYPE_UNKNOWN	= 1
local VAR_EVENT_TYPE_TICKETS	= 2

local VAR_EVENT_TICKETS_NONE	= 0
local VAR_EVENT_TICKETS_UNKNOWN	= 1
local VAR_EVENT_TICKETS_QUEST	= 2
local VAR_EVENT_TICKETS_LOOT	= 3
local VAR_EVENT_TICKETS_TARGET	= 4


local var_defaultEvent = {
	['index'] 		= VAR_EVENT_UNKNOWN,
	['eventType'] = VAR_EVENT_TYPE_UNKNOWN,
	['rewardsBy'] = VAR_EVENT_TICKETS_NONE,
}

local var_blankEvent = {
	active = false,
	eventIndex = VAR_EVENT_NONE,
}

local defaultEventInfo = {
	['index'] 		= VAR_EVENT_UNKNOWN,
	['eventType'] 	= VAR_EVENT_UNKNOWN,
	['rewardsBy'] 	= VAR_EVENT_UNKNOWN,
}

local EVENTS_TO_INDEX_MAP = {
	[VAR_EVENT_UNKNOWN] = defaultEventInfo
}


local VAR_EVENT_HAS_MAP_LOCATION = 'has_map_location'
local VAR_EVENT_NO_MAP_LOCATION = 'no_map_location'

local EVENTS = {
	[VAR_EVENT_TYPE_TICKETS] = {
		[VAR_EVENT_HAS_MAP_LOCATION] = {
			{ -- Anniversary Jubilee
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TICKETS_TARGET,
				['maxDailyRewards'] = 3,
				['location'] = {
					-- set use interaction on item
					["zoneIndex"] = 2,
					["subzoneIndex"] = 68,
					["locationIndex"] = 23,
				},
			},
			{ -- Jester's Festival
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TICKETS_QUEST,
				['maxDailyRewards'] = 3,
				['location'] = {
					["zoneIndex"] = 2,
					["subzoneIndex"] = 68,
					["locationIndex"] = 22,
				},
			},
			{ -- Whitestrake's Mayhem Celebration
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TICKETS_QUEST,
				['maxDailyRewards'] = 3,
				['location'] = {
					["zoneIndex"] = 2,
					["subzoneIndex"] = 68,
					["locationIndex"] = 27,
				},
			},
			{ -- Witch's Festival
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TICKETS_LOOT,
				['maxDailyRewards'] = 2,
				['location'] = {
					["zoneIndex"] = 2,
					["subzoneIndex"] = 0,
					["locationIndex"] = 4,
				},
			},
		},
		[VAR_EVENT_NO_MAP_LOCATION] = {
			{ -- New Life Festival
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
				['maxDailyRewards'] = 3,
				['itemIds'] = {
					96390, 133557, 141823, 156779, 182494, 171327, 19236896390
				},
			},
			{ -- Undaunted Celebration
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_LOOT,
				['maxDailyRewards'] = 2,
				['itemIds'] = {
					171268,156717,156679
				},
			},
			-- discarded?
			{ -- Season of the Dragon Celebration
				['eventType'] = VAR_EVENT_TYPE_UNKNOWN,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
				['maxDailyRewards'] = 3,
				['itemIds'] = {-- Elsweyr Coffer
					175580, 193735, 175579, 193734
				},
			},
			{ -- Daedric War Celebration Event
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
				['maxDailyRewards'] = 3,
				['itemIds'] = {
					182592,182599,171480,171476
				},
				['quests'] = {
					-- Vvardenfell
					[849] = {
						5912, 5913, 5907, 5916, 5918, 5865, 5866, 5904, 5906, 5956, 5962, 5961, 5934, 
						5915, 5958, 5927, 5928, 5924, 5925, 5929, 5930, 5926, 5910, 5911, 5908, 5909, 
					},
					-- Clockwork City
					[980] = {
						6089, 6081, 6088, 6073, 6080, 6079, 6076, 6077, 6039, 6037, 
						6041, 2952, 2975, 6042, 6070, 6071, 6024, 6106, 6072, 6107
					},
					-- Summerset
					[1011] = {
						6159, 6152, 6158, 6157, 6156, 6160, 6084, 6085, 6086, 6087, 6082, 6083
					},
				},
			},
			{ -- Zeal of Zenithar
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
				['maxDailyRewards'] = 3,
				['itemIds'] = { 
					187746,187701,187700
				},
				['quests'] = {
					[888] = {6750 }-- Honest Toil
					
				},
			},
			{ -- VAR_EVENT_DARKHEART
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
				['maxDailyRewards'] = 2,
				['itemIds'] = {
					167226, 193761, 167227, 193762
				},
			},
			{ -- VAR_EVENT_STEADFAST
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
				['maxDailyRewards'] = 2,
				['itemIds'] = {
					190059, 190058,188255, 188251, 188254, 188252, 188256, 188253
				},
			},
			
			{ -- Season of the Dragon Celebration
				['eventType'] = VAR_EVENT_TYPE_UNKNOWN,
				['rewardsBy'] = VAR_EVENT_TYPE_LOOT,
				['maxDailyRewards'] = 2,
				['itemIds'] = {-- Elsweyr Coffer
					175580, 193735, 175579, 193734
				},
				['quests'] = {
					[1086] = { -- Northern Elsweyr
						6357, 6378, 6382, 6377, 6380, 6379, 6381, 6359, 6362, 6361, 6363, 6360, 6356
					},
					[1133] = { -- Southern Elsweyr
						6435, 3442, 6405, 6433, 6429, 6428, 6430, 6406
					},
					
				},
			},
		},
	},
	[VAR_EVENT_TYPE_UNKNOWN] = {
	}
}

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------

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
	if currentZoneIndex ~= zoneIndex then
	end
	WORLD_MAP_MANAGER:SetMapById((GetMapIdByIndex(zoneIndex)))
	
	if subzoneIndex > 0 then
		if selectSubzone(zoneIndex, subzoneIndex) ~= SET_MAP_RESULT_MAP_CHANGED then
			return false
		end
	end

	local isVisible = IsMapLocationVisible(locIndex)
	
	-- Lets change the map back to the previously selected map or player's position.
	currentZoneIndex = currentZoneIndex > 0 and currentZoneIndex or GetUnitZoneIndex("player")
	WORLD_MAP_MANAGER:SetMapById((GetMapIdByIndex(currentZoneIndex)))
		
	return isVisible
end

local function doesEventHaveVisiblePin(locationInfo)
	return isMapLocationVisible(locationInfo.zoneIndex, locationInfo.subzoneIndex, locationInfo.locationIndex)
end

local function isImpresarioVisible()
	local zoneIndex = 2
	local subzoneIndex = 68
	local locIndex = 24
	
	local isTicketEvent = isMapLocationVisible(zoneIndex, subzoneIndex, locIndex)
	return isTicketEvent, VAR_EVENT_TYPE_TICKETS
end

local function checkForActiveEvent(self)
	local isActive = isImpresarioVisible()
	
	if isActive then
		self:SetActiveEventType(VAR_EVENT_TYPE_TICKETS)
	else
		self:SetActiveEventType(VAR_EVENT_TYPE_NONE)
	end
	
	return isActive
end

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
local function isItemForEvent(itemIds, lootItemId)
	for i, itemId in pairs(itemIds) do
		if itemId == lootItemId then
			return true
		end
	end
end

local function isQuestForEvent(quests, questName)
	local zoneQuests = quests[GetUnitZone('player')]
	for k, questId in pairs(zoneQuests) do
		if GetQuestName(questId) == questName then
			return true
		end
	end
end

local function getDailyResetTimeRemainingSeconds()
	return GetTimeUntilNextDailyLoginRewardClaimS()
end

---------------------------------------------------------------------------
-- Dev debug
---------------------------------------------------------------------------
local dev = true
-- Enabling dev allows testing event changes by collecting various raw crating materials.
-- Useful when events are not running.
-- It lowers the reset time to 1 minute and, has an event active for 5 minutes and 1 minute off,
-- to simulate daily resets and, event ending and starting.
if dev then
	EVENTS[VAR_EVENT_TYPE_UNKNOWN] = {
		{ -- Woodwork Raw Material
			['eventType'] = VAR_EVENT_TYPE_TICKETS,
			['rewardsBy'] = VAR_EVENT_TYPE_TARGET,
			['maxDailyRewards'] = 2,
			['itemIds'] = {
				4439, 23117, 818, 23118, 23137, 802, 23138, 521, 71199, 23119
			},
		},
		{ -- Blacksmith Raw Material
			['eventType'] = VAR_EVENT_TYPE_TICKETS,
			['rewardsBy'] = VAR_EVENT_TICKETS_LOOT,
			['maxDailyRewards'] = 2,
			['itemIds'] = {
				4482, 23104, 23105, 23133, 5820, 808, 23103, 23134, 71198, 23135
			},
		},
		{ -- Clothier Raw Material
			['eventType'] = VAR_EVENT_TYPE_TICKETS,
			['rewardsBy'] = VAR_EVENT_TICKETS_LOOT,
			['maxDailyRewards'] = 2,
			['itemIds'] = {
				723097, 4448, 23143, 23095, 71200, 23129, 23131, 4464, 33218, 812,
				33217, 33219, 23130, 33220, 793, 71239, 4478, 800, 6020, 23142
			},
		},
		{ -- Reagents
			['eventType'] = VAR_EVENT_TYPE_TICKETS,
			['rewardsBy'] = VAR_EVENT_TICKETS_LOOT,
			['maxDailyRewards'] = 2,
			['itemIds'] = {
				77583, 30157, 30148, 30160, 77585, 150669, 139020, 30164, 30161,
				150672, 150671, 150789, 150731, 30162, 30151, 77587, 30156, 30158,
				30155, 30163, 77591, 30153, 77590, 30165, 139019, 77589, 77584,
				0149, 77581, 150670, 30152, 30166, 30154, 0159
			},
		},
	}

	local counter = 0
	local lastTime = 0
	getDailyResetTimeRemainingSeconds = function()
		local frameTimeSeconds = GetFrameTimeSeconds()
		if lastTime < frameTimeSeconds then
			lastTime = frameTimeSeconds + 60
			if counter == 5 then
				counter = 0
			end
			counter = counter + 1
		end
		
		return math.floor(lastTime - frameTimeSeconds)
	end
	
	-- the event will become inactive after 5 minutes
	checkForActiveEvent = function(self)
		local isActive = counter <= 5
		if isActive then
			self:SetActiveEventType(VAR_EVENT_TYPE_UNKNOWN)
		else
			self:SetActiveEventType(VAR_EVENT_TYPE_NONE)
		end
	
		return isActive
	end
end

do
	local function mapEventByIndex(eventTable)
		for _, eventInfo in ipairs(eventTable) do
			table.insert(EVENTS_TO_INDEX_MAP, eventInfo)
			eventInfo.index = #EVENTS_TO_INDEX_MAP
		end
	end
	mapEventByIndex(EVENTS[VAR_EVENT_TYPE_TICKETS][VAR_EVENT_HAS_MAP_LOCATION])
	mapEventByIndex(EVENTS[VAR_EVENT_TYPE_TICKETS][VAR_EVENT_NO_MAP_LOCATION])
	mapEventByIndex(EVENTS[VAR_EVENT_TYPE_UNKNOWN])
end

---------------------------------------------------------------------------
-- Event class
---------------------------------------------------------------------------
local event = ZO_InitializingObject:Subclass()

function event:Initialize(eventInfo)
	zo_mixin(self, eventInfo)
end

function event:Update(newData)
end

function event:GetIndex()
	return self.index
end
function event:GetType()
	return self.eventType
end
function event:GetRewardsBy()
	return self.rewardsBy
end
function event:GetMaxDailyRewards()
	return self.maxDailyRewards or 0
end

function event:IsSameEvent(eventIndex)
	return self.index == eventIndex
end



function event:ReplaceMe()
end



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
		
		self:ChangeState(self:CheckForActiveEvent())
		
	--	self:RegisterHooks()
	end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED, OnLoaded)
end

function lib:ChangeState(eventActive)
	if eventActive then
		if not self.active then
			-- activate
			self:Activate()
		end
	elseif self.active then
		-- deactivate
		self:Deactivate()
	end
	
	self:SetActive(eventActive)
end

function lib:OnUpdate()
	local eventActive = self:CheckForActiveEvent()
	self:ChangeState(eventActive)
	
	self:UpdateEventData()
	self:RegisterOnDailyReset()
end

function lib:SetActiveEventType(eventType)
	self.eventData.eventType = eventType
end

function lib:SetActive(active)
	self.active = active
end

--[[
-- This is used to automate the process of resetting
function lib:RegisterHooks()
    local function onInventorySingleSlotUpdate(eventId, bagId, slotId, isNewItem, itemIdsoundCategory, updateReason, stackCountChange)
		if stackCountChange > 0 then
			local itemId = GetItemId(bagId, slotId)
			local eventIndex = getKnownEventByLootItem(itemId)
			
			local eventIndex, eventInfo self:GetEventInfoByItemId(itemId)
			if eventIndex then
				EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
				self:UpdateEventData(eventIndex)
			end
		end
    end
	
	local function updateList()
		local lootData = LOOT_SHARED:GetSortedLootData()
		for _, data in ipairs(lootData) do
			if dev or data.currencyType == CURT_EVENT_TICKETS then
				-- register inventory update if the event type is unknown
				if self:GetActiveEventType() == VAR_EVENT_TYPE_UNKNOWN then
					EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, onInventorySingleSlotUpdate)
				end
			end
		end
	end
	
	-- We'll watch for loot that has Event Tickets
	for k, systemObject in pairs({LOOT_WINDOW, LOOT_WINDOW_GAMEPAD}) do
		SecurePostHook(systemObject, "UpdateList", function()
			updateList()
		end)
	end
end
]]

function lib:RegisterEvents()
	local function onQuestAdded(eventId, questIndex, questName)
		if self:GetActiveEventType() == VAR_EVENT_TYPE_UNKNOWN then
			local eventIndex, eventInfo self:GetEventInfoByQuestName(itemId)
			if eventIndex then
				self:UpdateEventData(eventIndex)
			end
		end
	end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_QUEST_ADDED, onQuestAdded)
	
    local function onInventorySingleSlotUpdate(eventId, bagId, slotId, isNewItem, itemIdsoundCategory, updateReason, stackCountChange)
		if stackCountChange > 0 then
			if self:GetActiveEventType() == VAR_EVENT_TYPE_UNKNOWN then
				local itemId = GetItemId(bagId, slotId)
				local eventIndex, eventInfo = self:GetEventInfoByItemId(itemId)
				if eventIndex then
					EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
					self:UpdateEventData(eventIndex)
				end
			end
		end
    end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, onInventorySingleSlotUpdate)
end

function lib:UnregisterEvents()
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_QUEST_ADDED)
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

function lib:RegisterOnDailyReset()
	EVENT_MANAGER:UnregisterForUpdate(self.name .. '_OnUpdate')
	local function onUpdate()
		if self.isUpdating then
			-- In the case UpdateEventData was called by another function, we will run onUpdate again.
			-- It can overwrite changes made if UpdateEventData was called with a new eventIndex.
			zo_callLater(onUpdate, 100)
			return
		end
		self:OnUpdate()
	end
	EVENT_MANAGER:RegisterForUpdate(self.name .. '_OnUpdate', getDailyResetTimeRemainingSeconds() * 1000, onUpdate)
end

function lib:Activate()
	-- I need to process savedVars to populate eventInfo
	-- or do I load those up and save active state to savedVars
	local eventIndex = self.eventData.eventIndex
	
--	if not eventIndex or self:GetActiveEventType() == VAR_EVENT_TYPE_UNKNOWN then
	if not eventIndex or eventIndex == VAR_EVENT_NONE then
		eventIndex = self:GetEventInfoByLocation()
	end
	
	if eventIndex > VAR_EVENT_NONE then
	--	self:CreateEvent(eventIndex)
		self:UpdateEventData(eventIndex)
	end
end

function lib:Deactivate()
	self:SetActiveEventType(VAR_EVENT_TYPE_NONE)
end

function lib:CreateEvent(eventIndex)
--	d( '------ CreateEvent')
	self.eventData.eventIndex = eventIndex
	local eventInfo = self:GetEventInfoByIndex(eventIndex)

	local newEvent = event:New(eventInfo)
	
--	d( newEvent)
	
	self.currentEvent = newEvent
	self:SetActiveEventType(eventInfo.eventType)
end

function lib:UpdateEventData(eventIndex)
	self.isUpdating = true
	
	if eventIndex then
		self:CreateEvent(eventIndex)
	else
		-- Handled in Deactivate
	end
	
	CALLBACK_MANAGER:FireCallbacks('On_Seasonal_Event_Updated', self:IsEventActive(), self.currentEvent)
	
	-- Need to set up events if the event was not detected.
	if self.currentEvent:GetType() > VAR_EVENT_TYPE_UNKNOWN then
		self:UnregisterEvents()
	else
		self:RegisterEvents()
	end
	self.isUpdating = false
end

function lib:GetEventInfoByLocation()
	local knownEvents = EVENTS[VAR_EVENT_TYPE_TICKETS][VAR_EVENT_HAS_MAP_LOCATION]
	for eventIndex, eventInfo in pairs(knownEvents) do
		if doesEventHaveVisiblePin(eventInfo.location) then
			return eventInfo.index, eventInfo
		end
	end
--[[
	for eventIndex, eventInfo in pairs(EVENTS_TO_INDEX_MAP) do
		if eventInfo.location and doesEventHaveVisiblePin(eventInfo.location) then
			return eventIndex, eventInfo
		end
	end
]]
		
	return VAR_EVENT_UNKNOWN
end

lib.CheckForActiveEvent = checkForActiveEvent

---------------------------------------------------------------------------
-- ADI
---------------------------------------------------------------------------
function lib:GetEventInfoByIndex(eventIndex)
	return EVENTS_TO_INDEX_MAP[eventIndex]
end

function lib:GetEventInfoByItemId(itemId)
	for eventIndex, eventInfo in pairs(EVENTS_TO_INDEX_MAP) do
		if eventInfo.itemIds and isItemForEvent(eventInfo.itemIds, itemId) then
			return eventIndex, eventInfo
		end
	end
end

function lib:GetEventInfoByQuestName(questName)
	for eventIndex, eventInfo in pairs(EVENTS_TO_INDEX_MAP) do
		if eventInfo.quests and isQuestForEvent(eventInfo.quests, questName) then
			return eventIndex, eventInfo
		end
	end
end

function lib:IsEventActive()
	return self.eventType ~= VAR_EVENT_TYPE_NONE
end

function lib:GetActiveEventIndex()
	return self.currentEvent:GetIndex()
end

function lib:GetActiveEventType()
	return self.eventData.eventType
end

function lib:GetEventData()
	return self.eventData
end

function lib:CurrentEvent()
	return self.currentEvent
end

function lib:GetEventIndexByFilter(eventType)
	
end

function lib:WouldTicketsExcedeMax(eventTickets)
	return ZO_SharedInteraction:WouldCurrencyExceedMax(REWARD_TYPE_EVENT_TICKETS, eventTickets)
end

function lib:RegisterUpdateCallback(callback)
	-- We want to fire the callback immediately so the addon gets updated without having to wait for event updates.
	if self.eventData then
		callback(self:IsEventActive(), self.currentEvent)
	end
	CALLBACK_MANAGER:RegisterCallback('On_Seasonal_Event_Updated', callback)
end

lib.GetDailyResetTimeRemainingSeconds = getDailyResetTimeRemainingSeconds
---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
IJA_Seasonal_Event_Manager = lib:New()



--[[
/script IJA_Seasonal_Event_Manager.savedVars = {}



]]
--[[ Example usage
IJA_Seasonal_Event_Manager:WouldTicketsExcedeMax(eventTickets)


	local function hasEventChanged(eventIndex)
	-- compare with the eventIndex saved in the add-on's savedvariables
		return self:GetEventIndex() ~= eventIndex
	end
	
	local function onSeasonalEventUpdate(eventData)
		if eventData.active then
			if hasEventChanged(eventData.eventIndex) then
				-- start new event
				self.savedVars.eventInfo = eventData.eventInfo
				self:UpdateResetTime()
			else
				-- reset for dailies?
				self:ResetDailyInfo()
			end
			self:UpdateDailyIconTexture()
		end
		
		self:ChangeState(eventData.active)
		self:RefreshGamepadMenu()
	end
	IJA_Seasonal_Event_Manager:RegisterUpdateCallback(onSeasonalEventUpdate)
]]




