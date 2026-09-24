-- Extra variables for ProEnchanters' configurable chat messages.
--
-- The message settings (auto invite, welcome, party full, failed invite, trade,
-- tip) already replace the all-caps word CUSTOMER with the customer's name, and
-- MONEY with the tip amount. This file adds, in the same all-caps style:
--
--   LOCATION  Where the player stands, e.g. "Trade District, Stormwind City".
--
--   MAPPIN    A clickable map pin link on the player's position ("[Map Pin
--             Location]"): the customer clicks it and gets a waypoint to the
--             enchanter. The client only builds this link for the player's own
--             map pin, so using MAPPIN moves that pin to the current position.
--             Where no pin can be placed (instances, clients without user
--             waypoints) the location text is used instead. On WoW Forever this
--             replaces the automatic raid icon, which addons may no longer set.
--
--   PROFLINK  A link to the player's Enchanting recipe list, like the one the
--             Professions window's link button inserts. The client only builds
--             it while that window is open, so the last one seen is kept in
--             ProEnchantersCharOptions.EnchantingProfessionLink. It stays empty
--             until Enchanting has been opened once on the character (mainline
--             UI engine only, i.e. WoW Forever).
--
-- ProEnchanters.lua and the Helper files shadow SendChatMessage with
-- PESendChatMessage, so every message the addon sends goes through
-- PEExpandMessageVariables. Text without these words is sent unchanged.

local ENCHANTING_SKILL_LINE_ID = 333

local blizzardSendChatMessage = SendChatMessage
local professionLinkHintShown = false -- the "open Enchanting once" hint, once per session

local function IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value) or false
end

local function GetLocationText()
	local zone = GetZoneText and GetZoneText() or ""
	local subZone = GetSubZoneText and GetSubZoneText() or ""
	if subZone ~= "" and subZone ~= zone then
		return subZone .. ", " .. zone
	end
	return zone
end

-- Places the player's own map pin on their position and returns its chat link,
-- or nil when the client cannot do it here.
local function GetMapPinLink()
	if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition and C_Map.SetUserWaypoint
		and C_Map.GetUserWaypointHyperlink and UiMapPoint) then
		return nil
	end
	local mapId = C_Map.GetBestMapForUnit("player")
	if not mapId or IsSecret(mapId) then
		return nil
	end
	if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(mapId) then
		return nil
	end
	local position = C_Map.GetPlayerMapPosition(mapId, "player")
	if not position or IsSecret(position.x) or IsSecret(position.y) then
		return nil
	end
	C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(mapId, position))
	return C_Map.GetUserWaypointHyperlink()
end

-- Replaces LOCATION, MAPPIN and PROFLINK in text. Function replacements keep any
-- "%" in the inserted text literal.
function PEExpandMessageVariables(text)
	if type(text) ~= "string" then
		return text
	end
	if string.find(text, "MAPPIN", 1, true) then
		local ok, link = pcall(GetMapPinLink)
		local replacement = (ok and link) or GetLocationText()
		text = string.gsub(text, "MAPPIN", function() return replacement end)
	end
	if string.find(text, "LOCATION", 1, true) then
		local replacement = GetLocationText()
		text = string.gsub(text, "LOCATION", function() return replacement end)
	end
	if string.find(text, "PROFLINK", 1, true) then
		local replacement = ProEnchantersCharOptions and ProEnchantersCharOptions["EnchantingProfessionLink"] or ""
		if replacement == "" and not professionLinkHintShown then
			professionLinkHintShown = true
			print("|cFF800080ProEnchanters|r: PROFLINK stays empty until you open your Enchanting window once on this character.")
		end
		text = string.gsub(text, "PROFLINK", function() return replacement end)
	end
	return text
end

-- SendChatMessage with the variables above expanded
function PESendChatMessage(text, ...)
	return blizzardSendChatMessage(PEExpandMessageVariables(text), ...)
end

-- Keeps the link of the player's own Enchanting whenever the Professions window
-- shows it (not a linked profession from chat, not a guild crafter list).
local function RememberProfessionLink()
	if not (C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillListLink and C_TradeSkillUI.GetBaseProfessionInfo) then
		return
	end
	if (C_TradeSkillUI.IsTradeSkillLinked and C_TradeSkillUI.IsTradeSkillLinked())
		or (C_TradeSkillUI.IsTradeSkillGuild and C_TradeSkillUI.IsTradeSkillGuild()) then
		return
	end
	local professionInfo = C_TradeSkillUI.GetBaseProfessionInfo()
	if not professionInfo or professionInfo.professionID ~= ENCHANTING_SKILL_LINE_ID then
		return
	end
	local ok, link = pcall(C_TradeSkillUI.GetTradeSkillListLink)
	if ok and type(link) == "string" and link ~= "" and not IsSecret(link) and ProEnchantersCharOptions then
		ProEnchantersCharOptions["EnchantingProfessionLink"] = link
	end
end

local eventFrame = CreateFrame("Frame")
for _, event in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE" }) do
	pcall(eventFrame.RegisterEvent, eventFrame, event)
end
eventFrame:SetScript("OnEvent", RememberProfessionLink)
