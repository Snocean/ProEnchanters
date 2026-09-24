-- Temporary diagnostic addon for porting ProEnchanters to WoW Forever.
-- On login it records which APIs ProEnchanters relies on exist on this client.
-- When a profession window opens it dumps every recipe (learned or not) with
-- its reagents into SavedVariables, so the enchant tables can be rebuilt from
-- what the live client actually exposes. Remove once the port is done.

PEProbeDB = PEProbeDB or {}

local GLOBALS = {
	-- Used directly by ProEnchanters.lua / Helper_Vanilla.lua
	"ChatFrame_OpenChat", "CreateFont", "CreateFrame", "DoEmote", "ExpandTradeSkillSubClass",
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
	"C_Seasons.GetActiveSeason", "Settings.RegisterCanvasLayoutCategory",
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

	report.capturedAt = date("%Y-%m-%d %H:%M:%S")
	PEProbeDB.api = report
	print("|cff33ff99PEProbe|r: " .. #report.missing .. " API missing: " .. table.concat(report.missing, ", "))
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

local frame = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "CRAFT_SHOW" }) do
	pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		ProbeApis()
	elseif event == "CRAFT_SHOW" then
		DumpCraftRecipes()
	else
		ScheduleTradeSkillDump()
	end
end)
