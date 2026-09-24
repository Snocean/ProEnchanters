-- Optional ProEnchanters chat tab (setting "Show ProEnchanters messages in their
-- own chat tab?", ProEnchantersCharOptions.UseChatTab, off by default: a missing
-- value counts as off, so no default needs to be written).
--
-- When enabled, everything ProEnchanters prints goes to a dedicated chat window
-- named "ProEnchanters", docked with the other chat tabs, instead of the main
-- chat frame, so it no longer mixes with regular chat:
--  * The window is created once with FCF_OpenNewWindow(name, true). The "true"
--    means "no default channels": the window receives no chat at all and only
--    shows what ProEnchanters writes into it. The client itself remembers the
--    window between sessions (chat windows are saved per character).
--  * Its tab flashes when a line arrives while another tab is selected, like a
--    whisper tab does, and stops flashing once the tab is shown.
--  * Chat windows are emptied on every /reload or login, so the last lines are
--    kept in ProEnchantersCharOptions.chatTabHistory and written back.
--  * If the player closes the tab, ProEnchanters respects it and prints to the
--    main chat frame again until the setting is switched off and on.
--  * On the mainline UI engine (WoW Forever) addons may not touch chat frames
--    during a chat messaging lockdown (restricted combat), so lines are queued
--    and written once the lockdown ends.
--
-- The rest of the addon only calls PEPrint (the files shadow print with it) and
-- PEChatTabSetEnabled from the settings checkbox.

local TAB_NAME = "ProEnchanters"
local HISTORY_LIMIT = 300
local HISTORY_HEADER = "|cff808080-- ProEnchanters: earlier messages --|r"

local blizzardPrint = print
local chatFrame        -- the ProEnchanters chat frame once found or created
local ready = false    -- chat windows are only restored after PLAYER_ENTERING_WORLD
local pendingLines = {} -- lines waiting for the frame or for the lockdown to end
local flushTicker

-- SavedVariables are loaded before the addon's files run, so this is the number
-- of lines kept from earlier sessions; lines printed during this session's
-- loading come after it and are written from pendingLines instead.
local previousSessionCount = (ProEnchantersCharOptions and ProEnchantersCharOptions.chatTabHistory
	and #ProEnchantersCharOptions.chatTabHistory) or 0

local function IsEnabled()
	return ProEnchantersCharOptions ~= nil and ProEnchantersCharOptions["UseChatTab"] == true
end

-- Chat messaging lockdown only exists on the mainline engine (WoW Forever)
local function IsChatLocked()
	return (C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()) and true or false
end

-- Creating a chat window is also kept out of combat on every client
local function CanCreateWindow()
	return not IsChatLocked() and not (InCombatLockdown and InCombatLockdown())
end

local function MaxChatWindows()
	if Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows then
		return Constants.ChatFrameConstants.MaxChatWindows
	end
	return NUM_CHAT_WINDOWS or 10
end

-- Returns the ProEnchanters chat frame and whether it is currently open (shown
-- or docked). A closed one still exists under the same name until reused.
local function FindTabFrame()
	for index = 1, MaxChatWindows() do
		local name, _, _, _, _, _, isShown, _, isDocked = FCF_GetChatWindowInfo(index)
		if name == TAB_NAME then
			return _G["ChatFrame" .. index], (isShown or isDocked) and true or false
		end
	end
	return nil, false
end

local function StoreInHistory(text)
	local history = ProEnchantersCharOptions.chatTabHistory
	if not history then
		history = {}
		ProEnchantersCharOptions.chatTabHistory = history
	end
	table.insert(history, text)
	while #history > HISTORY_LIMIT do
		table.remove(history, 1)
		-- The oldest lines belong to earlier sessions: keep the boundary right
		if previousSessionCount > 0 then
			previousSessionCount = previousSessionCount - 1
		end
	end
end

local function WriteToTab(text)
	chatFrame:AddMessage(text)
	-- Same idea as ChatFrameUtil.FlashTabIfNotShown for whispers: flash only when
	-- another tab is selected, i.e. our frame is not visible.
	if not chatFrame:IsShown() and FCF_StartAlertFlash then
		FCF_StartAlertFlash(chatFrame)
	end
end

local function FlushPending()
	if not chatFrame or IsChatLocked() then
		return false
	end
	for _, text in ipairs(pendingLines) do
		WriteToTab(text)
	end
	wipe(pendingLines)
	return true
end

-- Retries the queued lines every second until the chat lockdown is over
local function ScheduleFlush()
	if flushTicker then
		return
	end
	flushTicker = C_Timer.NewTicker(1, function()
		if FlushPending() then
			flushTicker:Cancel()
			flushTicker = nil
		end
	end)
end

local function HookTab(frame)
	if frame.proEnchantersHooked then
		return
	end
	frame.proEnchantersHooked = true
	-- Selecting the tab shows the frame: clear the whisper-style alert then
	frame:HookScript("OnShow", function(self)
		if FCF_StopAlertFlash then
			FCF_StopAlertFlash(self)
		end
	end)
end

-- Writes the first lineCount stored lines back, greyed header first
local function ReplayHistory(lineCount)
	local history = ProEnchantersCharOptions.chatTabHistory
	if not history or lineCount == 0 then
		return
	end
	chatFrame:AddMessage(HISTORY_HEADER)
	for index = 1, math.min(lineCount, #history) do
		chatFrame:AddMessage(history[index])
	end
end

-- Finds the tab, or creates it when allowCreate is set and none exists yet, then
-- replays the first replayCount stored lines. Returns true when output can go
-- to the tab.
local function AttachTab(allowCreate, replayCount)
	local frame, isOpen = FindTabFrame()
	if frame and not isOpen then
		-- The player closed the tab: only reopen it on an explicit toggle
		if not allowCreate then
			return false
		end
		frame = nil
	end
	if not frame then
		if not allowCreate or not CanCreateWindow() or not FCF_OpenNewWindow then
			return false
		end
		frame = FCF_OpenNewWindow(TAB_NAME, true)
		if not frame then
			blizzardPrint("|cFF800080ProEnchanters|r: no free chat window for the ProEnchanters tab, using the main chat.")
			return false
		end
	end
	chatFrame = frame
	HookTab(chatFrame)
	ReplayHistory(replayCount)
	return true
end

-- print replacement used by ProEnchanters' files. Same formatting as print.
function PEPrint(...)
	if not IsEnabled() then
		return blizzardPrint(...)
	end

	local parts = {}
	for index = 1, select("#", ...) do
		parts[index] = tostring(select(index, ...))
	end
	local text = table.concat(parts, " ")
	StoreInHistory(text)

	if not ready then
		-- Before the chat windows are restored: queue, written once attached
		table.insert(pendingLines, text)
		return
	end
	if not chatFrame then
		return blizzardPrint(...)
	end
	if IsChatLocked() then
		table.insert(pendingLines, text)
		ScheduleFlush()
		return
	end
	WriteToTab(text)
end

-- Called by the settings checkbox
function PEChatTabSetEnabled(enabled)
	ProEnchantersCharOptions["UseChatTab"] = enabled and true or false
	if enabled then
		-- Nothing is stored while the setting is off, so all of it is "earlier"
		local history = ProEnchantersCharOptions.chatTabHistory
		if ready and AttachTab(true, history and #history or 0) then
			FlushPending()
		end
	else
		chatFrame = nil
		blizzardPrint("|cFF800080ProEnchanters|r: messages go to the main chat again. " ..
			"Right-click the ProEnchanters tab and choose Close Window to remove it.")
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	ready = true
	if not IsEnabled() then
		wipe(pendingLines)
		return
	end
	-- Create the window only if none exists yet (first use, or wiped chat settings)
	if AttachTab(FindTabFrame() == nil, previousSessionCount) then
		-- Lines printed while loading follow the earlier sessions' lines
		if not FlushPending() then
			ScheduleFlush()
		end
	else
		for _, text in ipairs(pendingLines) do
			blizzardPrint(text)
		end
		wipe(pendingLines)
	end
end)
