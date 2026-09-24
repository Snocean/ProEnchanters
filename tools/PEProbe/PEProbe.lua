-- Temporary diagnostic addon for porting ProEnchanters to WoW Forever.
-- On login it records which APIs ProEnchanters relies on exist on this client.
-- When a profession window opens it dumps every recipe (learned or not) with
-- its reagents into SavedVariables, so the enchant tables can be rebuilt from
-- what the live client actually exposes. It also logs blocked/forbidden addon
-- actions, samples of the name formats (target, chat authors, unit menus), since
-- Forever characters have a first and a last name, and whether learned recipes
-- can be read without opening the Professions window. Remove once the port is
-- done. SavedVariables contain character names: never commit them.

PEProbeDB = PEProbeDB or {}

local GLOBALS = {
	-- Used directly by ProEnchanters.lua / Helper_Vanilla.lua
	"ChatFrame_OpenChat", "ChatFrame_SendTell", "CreateFont", "CreateFrame", "DoEmote", "ExpandTradeSkillSubClass",
	"GetCVar", "SetCVar", "GetCoinText", "GetMoneyString", "GetCursorPosition", "GetGameTime",
	"GetItemInfo", "GetLocale", "GetNormalizedRealmName", "GetNumGroupMembers", "GetRaidRosterInfo",
	"GetPlayerTradeMoney", "GetTargetTradeMoney", "GetTradePlayerItemInfo", "GetTradePlayerItemLink",
	"GetTradeTargetItemInfo", "GetTradeTargetItemLink", "GetTime", "GetUnitName", "GetZoneText",
	"IsAltKeyDown", "IsControlKeyDown", "IsShiftKeyDown", "IsInGroup", "IsInInstance", "IsInRaid",
	"PlaySound", "PlaySoundFile", "SendChatMessage", "SetRaidTarget", "StaticPopup_Show",
	"UnitAffectingCombat", "UnitIsGroupAssistant", "UnitIsGroupLeader", "UnitName",
	"strsplit", "tinsert", "wipe", "floor", "date", "Spell", "Menu", "SOUNDKIT", "UISpecialFrames",
	"StaticPopupDialogs", "DEFAULT_CHAT_FRAME", "NUM_BAG_SLOTS", "GameFontHighlight",
	"CALENDAR_FULLDATE_MONTH_NAMES", "CALENDAR_WEEKDAY_NAMES", "ERR_TRADE_BAG_FULL",
	"ERR_TRADE_CANCELLED", "ERR_TRADE_COMPLETE", "ERR_TRADE_TARGET_BAG_FULL",
	"ERR_TRADE_TARGET_MAX_LIMIT_CATEGORY_COUNT_EXCEEDED_IS",
	-- Craft / trade skill API (enchanting window, sync recipes, craft macros)
	"GetNumCrafts", "GetCraftInfo", "GetCraftSkillLine", "GetCraftNumReagents", "GetCraftReagentInfo",
	"GetCraftItemLink", "DoCraft", "CloseCraft", "GetNumTradeSkills", "GetTradeSkillInfo",
	"GetTradeSkillNumReagents", "GetTradeSkillReagentInfo", "GetTradeSkillRecipeLink",
	"DoTradeSkill", "CloseTradeSkill", "ClearFocus",
	-- Used by embedded libraries on older clients
	"SetDesaturation", "UIDropDownMenu_Initialize", "InterfaceOptions_AddCategory",
	-- Mainline-only helpers
	"issecretvalue",
}

local NAMESPACED = {
	"C_Container.GetContainerItemID", "C_Container.GetContainerItemInfo", "C_Container.GetContainerNumSlots",
	"C_DateAndTime.GetCurrentCalendarTime", "C_Item.GetItemInfo", "C_Item.GetItemInfoInstant",
	"C_Item.GetItemNameByID", "C_PartyInfo.ConfirmConvertToRaid", "C_PartyInfo.ConvertToRaid",
	"C_PartyInfo.InviteUnit", "C_Spell.GetSpellCastCount", "C_Spell.GetSpellName",
	"C_Spell.IsSpellUsable", "C_Spell.RequestLoadSpellData", "C_Spell.GetSpellDescription",
	"C_Timer.After", "C_Timer.NewTicker", "C_ChatInfo.SendChatMessage", "C_AddOns.GetAddOnMetadata",
	"C_SpellBook.IsSpellKnown", "C_TradeSkillUI.GetAllRecipeIDs", "C_TradeSkillUI.GetRecipeInfo",
	"C_TradeSkillUI.GetRecipeSchematic", "C_TradeSkillUI.CraftRecipe", "C_TradeSkillUI.OpenTradeSkill",
	"C_TradeSkillUI.GetBaseProfessionInfo", "C_TradeSkillUI.GetChildProfessionInfo",
	"C_TradeSkillUI.GetCategoryInfo", "C_TradeSkillUI.IsTradeSkillReady", "C_TradeSkillUI.CloseTradeSkill",
	"C_Seasons.GetActiveSeason", "Settings.RegisterCanvasLayoutCategory", "ChatFrameUtil.SendTell",
	"C_CurrencyInfo.GetCoinText",
}

local METHODS = {
	{ "GameTooltip", "AddSpellByID" }, { "GameTooltip", "SetSpellByID" }, { "GameTooltip", "SetHyperlink" },
}

-- Frames referenced by name, including from ProEnchanters' macros (/click, /run)
local FRAMES = {
	"TradeFrame", "TradeFrameTradeButton", "TradeRecipientItem7ItemButton", "TradePlayerItem7ItemButton",
	"StaticPopup1", "StaticPopup1Button1", "ChatFrame1EditBox", "CraftFrame", "TradeSkillFrame",
}

local EVENTS = {
	"TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED", "CRAFT_SHOW", "CRAFT_UPDATE",
	"TRADE_SHOW", "TRADE_UPDATE", "TRADE_ACCEPT_UPDATE", "TRADE_REQUEST", "TRADE_REQUEST_CANCEL",
	"GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT", "UI_INFO_MESSAGE", "UI_ERROR_MESSAGE", "CHAT_MSG_LOOT",
}

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

-- Printable form of a value that may be a mainline "secret" (unreadable by addons)
local function SafeString(value)
	if value == nil then
		return nil
	end
	if IsSecret(value) then
		return "<secret>"
	end
	return tostring(value)
end

local function Resolve(path)
	local value = _G
	for part in string.gmatch(path, "[^%.]+") do
		if type(value) ~= "table" then
			return nil
		end
		value = value[part]
	end
	return value
end

local function CopyScalars(source)
	local copy = {}
	if type(source) ~= "table" then
		return copy
	end
	for key, value in pairs(source) do
		local valueType = type(value)
		if (valueType == "string" or valueType == "number" or valueType == "boolean") and not IsSecret(value) then
			copy[key] = value
		end
	end
	return copy
end

local function ProbeApis()
	local report = { missing = {}, present = {} }
	local function Record(name, exists)
		table.insert(exists and report.present or report.missing, name)
	end

	for _, name in ipairs(GLOBALS) do
		Record(name, _G[name] ~= nil)
	end
	for _, path in ipairs(NAMESPACED) do
		Record(path, Resolve(path) ~= nil)
	end
	for _, pair in ipairs(METHODS) do
		local object = _G[pair[1]]
		Record(pair[1] .. ":" .. pair[2], object ~= nil and object[pair[2]] ~= nil)
	end
	for _, name in ipairs(FRAMES) do
		Record("frame " .. name, _G[name] ~= nil)
	end
	if C_EventUtils and C_EventUtils.IsEventValid then
		for _, event in ipairs(EVENTS) do
			Record("event " .. event, C_EventUtils.IsEventValid(event))
		end
	end

	local version, build, buildDate, interface = GetBuildInfo()
	report.client = {
		version = version, build = build, buildDate = buildDate, interface = interface,
		projectId = WOW_PROJECT_ID, projectMainline = WOW_PROJECT_MAINLINE, locale = GetLocale(),
	}
	if StaticPopup1 and StaticPopup1.ButtonContainer and StaticPopup1.ButtonContainer.Button1 then
		report.client.staticPopupButtonContainer = true
	end

	-- Which TOC each addon was loaded from: Questie ships Questie.toc ("11.38.0") and
	-- Questie_Camelot.toc ("... Forever-vNN"), so its version tells whether this
	-- client picks up the _Camelot suffix.
	local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	if GetMetadata then
		report.client.questieVersion = GetMetadata("Questie", "Version")
		report.client.proEnchantersVersion = GetMetadata("ProEnchanters", "Version")
	end

	-- Own character name formats: available at login, no other player needed
	local playerName, playerRealm = UnitName("player")
	report.player = {
		unitName = SafeString(playerName), unitRealm = SafeString(playerRealm),
		getUnitNameWithRealm = SafeString(GetUnitName and GetUnitName("player", true)),
		realmName = SafeString(GetRealmName and GetRealmName()),
		normalizedRealm = SafeString(GetNormalizedRealmName and GetNormalizedRealmName()),
	}
	if UnitFullName then
		local fullName, fullRealm = UnitFullName("player")
		report.player.fullName, report.player.fullRealm = SafeString(fullName), SafeString(fullRealm)
	end

	report.capturedAt = date("%Y-%m-%d %H:%M:%S")
	PEProbeDB.api = report
	print("|cff33ff99PEProbe|r: " .. #report.missing .. " API missing: " .. table.concat(report.missing, ", "))
end

-- Stores name, quality and the client's own item link for every reagent, so the
-- generated enchant table uses links exactly as this client builds them. Item
-- data loads asynchronously; each entry is written when its item is ready.
local function CacheReagentItems(recipes)
	if not (Item and Item.CreateFromItemID) then
		return
	end
	PEProbeDB.items = PEProbeDB.items or {}
	local seen = {}
	for _, entry in pairs(recipes) do
		for _, reagent in ipairs(entry.reagents or {}) do
			for _, itemId in ipairs(reagent.itemIds) do
				if not seen[itemId] then
					seen[itemId] = true
					local item = Item:CreateFromItemID(itemId)
					if not item:IsItemEmpty() then
						item:ContinueOnItemLoad(function()
							PEProbeDB.items[itemId] = {
								name = item:GetItemName(),
								quality = item:GetItemQuality(),
								link = item:GetItemLink(),
							}
						end)
					end
				end
			end
		end
	end
end

-- Modern profession window (C_TradeSkillUI)
local function DumpTradeSkillRecipes()
	if not (C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs) then
		return
	end
	local ok, recipeIds = pcall(C_TradeSkillUI.GetAllRecipeIDs)
	if not ok or type(recipeIds) ~= "table" or #recipeIds == 0 then
		return
	end

	local profession = {}
	if C_TradeSkillUI.GetBaseProfessionInfo then
		local okBase, info = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
		if okBase then
			profession.base = CopyScalars(info)
		end
	end
	if C_TradeSkillUI.GetChildProfessionInfo then
		local okChild, info = pcall(C_TradeSkillUI.GetChildProfessionInfo)
		if okChild then
			profession.child = CopyScalars(info)
		end
	end

	local recipes, categories = {}, {}
	for _, recipeId in ipairs(recipeIds) do
		local entry = {}
		local okInfo, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeId)
		if okInfo and info then
			entry.info = CopyScalars(info)
			local categoryId = info.categoryID
			if categoryId and not categories[categoryId] and C_TradeSkillUI.GetCategoryInfo then
				local okCategory, category = pcall(C_TradeSkillUI.GetCategoryInfo, categoryId)
				if okCategory and category then
					categories[categoryId] = CopyScalars(category)
				end
			end
		end
		if C_TradeSkillUI.GetRecipeSchematic then
			local okSchematic, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeId, false)
			if okSchematic and schematic then
				entry.schematic = CopyScalars(schematic)
				entry.reagents = {}
				for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
					local reagent = {
						quantityRequired = slot.quantityRequired,
						reagentType = slot.reagentType,
						required = slot.required,
						itemIds = {},
					}
					for _, option in ipairs(slot.reagents or {}) do
						table.insert(reagent.itemIds, option.itemID)
					end
					table.insert(entry.reagents, reagent)
				end
			end
		end
		if C_Spell and C_Spell.GetSpellDescription then
			local okDescription, description = pcall(C_Spell.GetSpellDescription, recipeId)
			if okDescription and type(description) == "string" and not IsSecret(description) then
				entry.description = description
			end
		end
		if IsPlayerSpell then
			entry.isPlayerSpell = IsPlayerSpell(recipeId)
		end
		if C_SpellBook and C_SpellBook.IsSpellKnown then
			local okKnown, known = pcall(C_SpellBook.IsSpellKnown, recipeId)
			entry.isSpellKnown = okKnown and known or nil
		end
		recipes[recipeId] = entry
	end

	local name = (profession.base and profession.base.professionName) or "unknown"
	PEProbeDB.professions = PEProbeDB.professions or {}
	PEProbeDB.professions[name] = {
		profession = profession,
		recipes = recipes,
		categories = categories,
		count = #recipeIds,
		capturedAt = date("%Y-%m-%d %H:%M:%S"),
	}
	-- Profession link as the "link" button builds it (only valid while open)
	if C_TradeSkillUI.GetTradeSkillListLink then
		local okLink, link = pcall(C_TradeSkillUI.GetTradeSkillListLink)
		PEProbeDB.professions[name].listLink = okLink and SafeString(link) or nil
	end
	if C_TradeSkillUI.CanTradeSkillListLink then
		local okCan, canLink = pcall(C_TradeSkillUI.CanTradeSkillListLink)
		PEProbeDB.professions[name].canListLink = okCan and canLink or nil
	end
	CacheReagentItems(recipes)
	print("|cff33ff99PEProbe|r: " .. #recipeIds .. " recipes captured for " .. name .. ", /reload to save them")
end

-- Legacy craft window (GetCraftInfo), in case this client still uses it for Enchanting
local function DumpCraftRecipes()
	if not (GetNumCrafts and GetCraftInfo) then
		return
	end
	local recipes = {}
	for index = 1, GetNumCrafts() do
		local craftName, craftSubSpellName, craftType = GetCraftInfo(index)
		local entry = { name = craftName, subName = craftSubSpellName, craftType = craftType, reagents = {} }
		if GetCraftItemLink then
			entry.link = GetCraftItemLink(index)
		end
		if GetCraftNumReagents and GetCraftReagentInfo then
			for reagentIndex = 1, GetCraftNumReagents(index) do
				local reagentName, _, reagentCount = GetCraftReagentInfo(index, reagentIndex)
				table.insert(entry.reagents, { name = reagentName, count = reagentCount })
			end
		end
		table.insert(recipes, entry)
	end
	PEProbeDB.craft = { recipes = recipes, count = #recipes, capturedAt = date("%Y-%m-%d %H:%M:%S") }
	print("|cff33ff99PEProbe|r: " .. #recipes .. " craft recipes captured, /reload to save them")
end

-- Whether learned recipes can be read without opening the Professions window.
-- Runs a few seconds after login on the recipe IDs of the last capture and
-- records what each API answers; ProEnchanters could then sync by itself.
local function ProbeWindowlessKnowledge()
	local capture = PEProbeDB.professions and PEProbeDB.professions["Enchanting"]
	if not capture or not capture.recipes then
		return
	end
	local results = {}
	local summary = {}
	for recipeId, entry in pairs(capture.recipes) do
		local learned = entry.info and entry.info.learned or false
		local result = { learnedWhenOpen = learned }
		if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
			local okInfo, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeId)
			result.recipeInfoLearned = okInfo and info and info.learned or nil
		end
		if IsPlayerSpell then
			result.isPlayerSpell = IsPlayerSpell(recipeId)
		end
		if C_SpellBook and C_SpellBook.IsSpellKnown then
			local okKnown, known = pcall(C_SpellBook.IsSpellKnown, recipeId)
			result.isSpellKnown = okKnown and known or nil
		end
		results[recipeId] = result
		for _, key in ipairs({ "recipeInfoLearned", "isPlayerSpell", "isSpellKnown" }) do
			summary[key] = summary[key] or { match = 0, mismatch = 0 }
			if (result[key] == true) == learned then
				summary[key].match = summary[key].match + 1
			else
				summary[key].mismatch = summary[key].mismatch + 1
			end
		end
	end
	local windowless = { results = results, summary = summary, capturedAt = date("%Y-%m-%d %H:%M:%S") }
	if C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillListLink then
		local okLink, link = pcall(C_TradeSkillUI.GetTradeSkillListLink)
		windowless.listLinkWithoutWindow = okLink and SafeString(link) or nil
	end
	PEProbeDB.windowless = windowless
	local parts = {}
	for key, counts in pairs(summary) do
		table.insert(parts, key .. " " .. counts.match .. "/" .. (counts.match + counts.mismatch))
	end
	print("|cff33ff99PEProbe|r: learned recipes without the window: " .. table.concat(parts, ", "))
end

local pending = false
local function ScheduleTradeSkillDump()
	if pending then
		return
	end
	pending = true
	C_Timer.After(1, function()
		pending = false
		DumpTradeSkillRecipes()
	end)
end

-- Keeps only the most recent entries of a sample list in PEProbeDB.
local function PushSample(listName, sample, limit)
	PEProbeDB[listName] = PEProbeDB[listName] or {}
	local list = PEProbeDB[listName]
	table.insert(list, sample)
	while #list > (limit or 5) do
		table.remove(list, 1)
	end
end


-- Blocked / forbidden actions: the "blocked from an action only available to the
-- Blizzard UI" popup never says which function was refused, these events do.
local function RecordBlockedAction(event, addonName, functionName)
	PushSample("blockedActions", {
		event = event,
		addon = SafeString(addonName),
		func = SafeString(functionName),
		at = date("%Y-%m-%d %H:%M:%S"),
	}, 20)
	print("|cff33ff99PEProbe|r: " .. event .. " " .. tostring(addonName) .. " -> " .. tostring(functionName))
end

-- Forever characters have a first and a last name. Record what each name API
-- returns for a targeted player so ProEnchanters can pick the right one.
local function RecordTargetName()
	if not UnitIsPlayer("target") then
		return
	end
	local name, realm = UnitName("target")
	local sample = { unitName = SafeString(name), unitRealm = SafeString(realm) }
	if UnitFullName then
		local fullName, fullRealm = UnitFullName("target")
		sample.fullName, sample.fullRealm = SafeString(fullName), SafeString(fullRealm)
	end
	if GetUnitName then
		sample.getUnitNameWithRealm = SafeString(GetUnitName("target", true))
	end
	if UnitNameUnmodified then
		sample.unmodified = SafeString(UnitNameUnmodified("target"))
	end
	local guid = UnitGUID and UnitGUID("target")
	if guid and not IsSecret(guid) and GetPlayerInfoByGUID then
		sample.guidName = SafeString(select(6, GetPlayerInfoByGUID(guid)))
		sample.guidRealm = SafeString(select(7, GetPlayerInfoByGUID(guid)))
	end
	PushSample("targetNames", sample)
end

-- Author fields of chat events (arg2 and arg5), which ProEnchanters uses to
-- invite and whisper. Message text is only kept for system messages, where the
-- addon parses "<name> joins the party".
local function RecordChatAuthor(event, ...)
	local sample = { event = event, author = SafeString(select(2, ...)), author2 = SafeString(select(5, ...)) }
	if event == "CHAT_MSG_SYSTEM" then
		sample.text = SafeString(select(1, ...))
	end
	local guid = select(12, ...)
	if guid and guid ~= "" and not IsSecret(guid) and GetPlayerInfoByGUID then
		local _, _, _, _, _, guidName, guidRealm = GetPlayerInfoByGUID(guid)
		sample.guidName, sample.guidRealm = SafeString(guidName), SafeString(guidRealm)
	end
	PushSample("chatAuthors", sample, 10)
end

-- contextData of the unit menus ProEnchanters adds "Create Work Order" to.
if Menu and Menu.ModifyMenu then
	for _, menuName in ipairs({ "MENU_UNIT_PLAYER", "MENU_UNIT_PARTY", "MENU_UNIT_RAID", "MENU_UNIT_FRIEND", "MENU_CHAT" }) do
		Menu.ModifyMenu(menuName, function(_, _, contextData)
			local sample = CopyScalars(contextData)
			sample.menu = menuName
			PushSample("menuContexts", sample)
		end)
	end
end

local CHAT_EVENTS = {
	CHAT_MSG_WHISPER = true, CHAT_MSG_CHANNEL = true, CHAT_MSG_SAY = true, CHAT_MSG_SYSTEM = true,
}

local frame = CreateFrame("Frame")
for _, event in ipairs({
	"PLAYER_LOGIN", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "CRAFT_SHOW",
	"ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "PLAYER_TARGET_CHANGED",
	"CHAT_MSG_WHISPER", "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_SYSTEM",
}) do
	pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		ProbeApis()
		C_Timer.After(5, ProbeWindowlessKnowledge)
	elseif event == "CRAFT_SHOW" then
		DumpCraftRecipes()
	elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
		RecordBlockedAction(event, ...)
	elseif event == "PLAYER_TARGET_CHANGED" then
		RecordTargetName()
	elseif CHAT_EVENTS[event] then
		RecordChatAuthor(event, ...)
	else
		ScheduleTradeSkillDump()
	end
end)
