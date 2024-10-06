-- First Initilizations
local version = "v6.7.5"
ProEnchantersOptions = ProEnchantersOptions or {}
ProEnchantersLog = ProEnchantersLog or {}
ProEnchantersTradeHistory = ProEnchantersTradeHistory or {}
ProEnchantersOptions.filters = {}
ProEnchantersWorkOrderFrames = {}
ProEnchantersOptions.favorites = {}
local enchantButtons = {}
local enchantFilterCheckboxes = {}
PEFilteredWords = {}
PETriggerWords = {}
PEtradeWhoItems = PEtradeWhoItems or {}
PEtradeWhoItems.player = PEtradeWhoItems.player or {}
PEtradeWhoItems.target = PEtradeWhoItems.target or {}
local AddonInvite = false
local selfPlayerName = GetUnitName("player")
local NonAddonInvite = true
local LocalLanguage = PELocales[GetLocale()]
local FontSize = 12
PEPlayerInvited = {}
useAllMats = false
local maxPartySizeReached = false
local normHeight = 630
local tradeYoffset = 0
local target = ""
local isConnected = true
local LSM = LibStub("LibSharedMedia-3.0")

-- Minimap Stuff done through Ace ?? NO CLUE WHAT I'M DOIN THO
local addon = LibStub("AceAddon-3.0"):NewAddon("ProEnchanters")
local icon = LibStub("LibDBIcon-1.0", true)
local PELDB = LibStub("LibDataBroker-1.1"):NewDataObject("ProEnchanters", {
	type = "data source",
	text = "Pro Enchanters",
	icon = "Interface\\AddOns\\ProEnchanters\\custom_icon",
	OnClick = function(self, button)
		if button == "LeftButton" then
			if IsControlKeyDown() then
				addon.db.profile.minimap.hide = true
				icon:Hide("ProEnchanters")
			elseif ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsShown() then
				ProEnchantersWorkOrderFrame:Hide()
				ProEnchantersWorkOrderEnchantsFrame:Hide()
			elseif ProEnchantersWorkOrderFrame then
				ProEnchantersWorkOrderFrame:Show()
				ProEnchantersWorkOrderEnchantsFrame:Show()
				--ResetFrames()
			end
		elseif button == "RightButton" then
			if IsShiftKeyDown() then
				-- Reset frame position and size
				if ProEnchantersWorkOrderFrame then
					ProEnchantersWorkOrderFrame:ClearAllPoints()
					ProEnchantersWorkOrderFrame:SetPoint("CENTER", UIParent, "CENTER")
					ProEnchantersWorkOrderFrame:SetSize(455, 630) -- Set to default size
				end
				if ProEnchantersWorkOrderEnchantsFrame then
					ProEnchantersWorkOrderEnchantsFrame:ClearAllPoints()
					ProEnchantersWorkOrderEnchantsFrame:SetPoint("TOPLEFT", ProEnchantersWorkOrderFrame, "TOPRIGHT", -1,
						0)
					ProEnchantersWorkOrderEnchantsFrame:SetPoint("BOTTOMLEFT", ProEnchantersWorkOrderFrame, "BOTTOMRIGHT",
						-1,
						0)
				end
				print("|cFF800080ProEnchanters|r: Frame position and size have been reset.")
			else
				ProEnchantersOptions["WorkWhileClosed"] = not ProEnchantersOptions["WorkWhileClosed"]
				print("|cFF800080ProEnchanters|r: \"Work while closed\" is now " ..
					(ProEnchantersOptions["WorkWhileClosed"] and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
				-- Update the checkbox state
				if ProEnchantersSettingsFrame and ProEnchantersSettingsFrame.WorkWhileClosedCheckbox then
					ProEnchantersSettingsFrame.WorkWhileClosedCheckbox:SetChecked(ProEnchantersOptions
						["WorkWhileClosed"])
				end
			end
		end
	end,
	OnEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("|cFF800080ProEnchanters|r")
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("|cFFFFFFFFLeftclick:|r |cFFFFFF00Open|r")
		local workClosedColor = ProEnchantersOptions["WorkWhileClosed"] and "|cFF00FF00" or "|cFFFF0000"
		GameTooltip:AddLine("|cFFFFFFFFRightclick:|r " .. workClosedColor .. "Toggle: Work Closed|r")
		GameTooltip:AddLine("|cFFFFFFFFShift-Rightclick:|r |cFFFFFF00Reset Frame Pos and Size|r")
		GameTooltip:AddLine("|cFFFFFFFFCtrl-Leftclick:|r |cFFFFFF00Hide button, use /pe minimap to re-enable|r")
		GameTooltip:Show()
	end,
	OnLeave = function(self)
		GameTooltip:Hide()
	end,
})

function addon:OnInitialize()
	-- Assuming you have a ## SavedVariables: BunniesDB line in your TOC
	self.db = LibStub("AceDB-3.0"):New("ProEnchantersDB", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})

	if self.db.profile.minimap.hide == nil then
		self.db.profile.minimap.hide = false -- Set default to false
	end

	icon:Register("ProEnchanters", PELDB, self.db.profile.minimap)
end

-- Sound Register
local sounds = {
	{ "Orc Work work",              "workwork.ogg" },
	{ "Orc I can do that",          "icandothat.ogg" },
	{ "Orc Be happy to",            "behappyto.ogg" },
	{ "Orc Me busy",                "mebusyleavemealone.ogg" },
	{ "Orc Ready to work",          "readytowork.ogg" },
	{ "Orc Something need doing",   "somethingneeddoing.ogg" },
	{ "Orc What you want",          "whatyouwant.ogg" },
	{ "Cyberpunk Alert",            "cyberpunkalert.ogg" },
	{ "Druid At once",              "druidatonce.ogg" },
	{ "Druid Ill make short work",  "druidillmakeshortworkofthem.ogg" },
	{ "Druid Im awake",             "druidimawake.ogg" },
	{ "Dwarf Who wants some",       "dwarfalrightwhowantssome.ogg" },
	{ "Dwarf Aye sir",              "dwarfayesir.ogg" },
	{ "Dwarf For Ironforge",        "dwarfforironforge.ogg" },
	{ "Dwarf Give me something",    "dwarfgjvemesomethingtodo.ogg" },
	{ "Dwarf Ill take care of it",  "dwarfilltakecareofit.ogg" },
	{ "Dwarf What do you need",     "dwarftwhatdoyouneed.ogg" },
	{ "Dwarf Whats this",           "dwarfwhatsthis.ogg" },
	{ "Human I guess I can",        "humaniguessican.ogg" },
	{ "Human More work",            "humanmorework.ogg" },
	{ "Human Ready for action",     "humanreadyforaction.ogg" },
	{ "Human Ready to work",        "humanreadytowork.ogg" },
	{ "Human What do you need",     "humanwhatdoyouneed.ogg" },
	{ "Human What is it",           "humanwhatisit.ogg" },
	{ "Human Yes mi lord",          "humanyesmilord.ogg" },
	{ "Human Yes my liege",         "humanyesmyliege.ogg" },
	{ "Tauren Bring it on",         "taurenbringiton.ogg" },
	{ "Tauren For the tribes",      "taurenforthetribes.ogg" },
	{ "Tauren I am able to help",   "taureniamabletohelp.ogg" },
	{ "Troll How may I serve",      "trollhowmayiserve.ogg" },
	{ "Troll I do it now",          "trollidoitnow.ogg" },
	{ "Troll I hear the summons",   "trollihearthesummons.ogg" },
	{ "Troll I may have something", "trollimayhavesomethingforya.ogg" },
	{ "Troll you need me help",     "trollyouneedmehelp.ogg" }
}

for _, sound in ipairs(sounds) do
	LSM:Register("sound", sound[1], "Interface\\AddOns\\ProEnchanters\\Media\\" .. sound[2])
end

local workwork = "Orc Work work"
local icandothat = "Orc I can do that"
local behappyto = "Orc Be happy to"
local mebusy = "Orc Me busy"
local readytowork = "Orc Ready to work"
local somethingneeddoing = "Orc Something need doing"
local whatyouwant = "Orc What you want"

function PESound(soundname)
	if ProEnchantersOptions["EnableSounds"] == true then
		local sound = LSM:Fetch('sound', soundname)
		PlaySoundFile(sound, "Master")
	end
end

-- Fonts
local UIFontBasic = CreateFont("ProEnchantersUIFont")
UIFontBasic:CopyFontObject(GameFontHighlight)
UIFontBasic:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
UIFontBasic:SetTextColor(1, 1, 1)

function CreatePEMacros()
	if not GetMacroInfo("PEMacro1") then
		CreateMacro("PEMacro1", "Spell_holy_healingaura",
			"/run TradeRecipientItem7ItemButton:Click()\n/click StaticPopup1Button1")
	end
end

local function findEnchantByKeyAndLanguage(msg)
	local msglower = string.lower(msg)
	if ProEnchantersOptions["DebugLevel"] >= 9 then
		print("msglower set to " .. msglower)
	end
	local msgNoExclamation = msglower:sub(2) -- Remove '!' from the start
	if ProEnchantersOptions["DebugLevel"] >= 9 then
		print("msgNoExclamation set to " .. msgNoExclamation)
	end
	local msgProcessed = string.gsub(msgNoExclamation, " ", "") -- Remove spaces
	if ProEnchantersOptions["DebugLevel"] >= 9 then
		print("msgProcessed set to " .. msgProcessed)
	end

	for enchID, langs in pairs(PEenchantingLocales["Enchants"]) do
		-- Improved print statement to avoid attempting to concatenate the 'langs' table
		if ProEnchantersOptions["DebugLevel"] >= 9 then
			print("checking enchant ID: " .. enchID)
		end
		for langID, name in pairs(langs) do
			if ProEnchantersOptions["DebugLevel"] >= 9 then
				print("checking language " .. langID .. " for enchID " .. enchID)
			end
			local nameProcessed = string.gsub(string.lower(name), " ", "")
			if ProEnchantersOptions["DebugLevel"] >= 9 then
				print("Comparing enchant names: " .. nameProcessed .. " with " .. msgProcessed)
			end
			if nameProcessed == msgProcessed then
				return enchID, langID
			end
		end
	end

	return nil, nil -- Return nil if no match is found
end


function InviteUnitPEAddon(name)
	local nameCheck = string.lower(name)
	local selfnameCheck = string.lower(selfPlayerName)
	local maxPartySize = tonumber(ProEnchantersOptions["MaxPartySize"]) or 40
	local currentPartySize = 0
	local isInGroup = IsInGroup()
	local raidConvert = false

	if isInGroup == true then
		currentPartySize = tonumber(GetNumGroupMembers())
	end

	if ProEnchantersOptions["DelayInviteTime"] > 0 then
		C_Timer.After(ProEnchantersOptions["DelayInviteTime"], function()
			if maxPartySize > currentPartySize then
				if not IsInRaid() then
					if currentPartySize >= 4 then
						ConvertToRaid()
						print("Converting party to raid")
						raidConvert = true
					end
				end
				if raidConvert == true then
					if not string.find(selfnameCheck, nameCheck, 1, true) then
						C_Timer.After(1, function() InviteUnit(name) end)
					end
				else
					if not string.find(selfnameCheck, nameCheck, 1, true) then
						InviteUnit(name)
					end
				end
			elseif maxPartySize <= currentPartySize then
				print("Party size limit reached, consider increasing the size of your maximum party within the options")
			end
		end)
	else
		if maxPartySize > currentPartySize then
			if not IsInRaid() then
				if currentPartySize >= 4 then
					ConvertToRaid()
					print("Converting party to raid")
					raidConvert = true
				end
			end
			if raidConvert == true then
				if not string.find(selfnameCheck, nameCheck, 1, true) then
					C_Timer.After(1, function() InviteUnit(name) end)
				end
			else
				if not string.find(selfnameCheck, nameCheck, 1, true) then
					InviteUnit(name)
				end
			end
		elseif maxPartySize <= currentPartySize then
			print("Party size limit reached, consider increasing the size of your maximum party within the options")
		end
	end
end

local AllChannels = false

ProEnchantersTradeHistory = ProEnchantersTradeHistory or {}
GoldTraded = 0
StaticPopupDialogs["INVITE_PLAYER_POPUP"] = {
	text = "Player %s potential customer: %s",
	button1 = "Invite",
	button2 = "Cancel",
	OnAccept = function(self, data)
		local playerName, msg, author2 = unpack(data)
		AddonInvite = true
		PEPlayerInvited[playerName] = msg
		if AddonInvite == true then
			InviteUnitPEAddon(author2)
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3, -- Avoid taint issues
}

StaticPopupDialogs["CUS_REQ_POPUP"] = {
	text = "Enter text for custom request",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnShow = function(self)
		self.editBox:SetText("")
		self.editBox:SetFocus()
	end,
	OnAccept = function(self)
		local cusreq = (self.editBox:GetText())
		local cusName = string.lower(ProEnchantersCustomerNameEditBox:GetText())
		local cusreqHyperlink = "|cFFF5F5F5|Haddon:ProEnchanters:" ..
			"cusreq" .. ":" .. cusreq .. ":" .. cusName .. ":1234|h" .. cusreq .. "|h|r"
		AddTradeLine(cusName, MEDIUMSPRINGGREEN .. "Custom Request: " .. ColorClose .. cusreqHyperlink)
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	hasEditBox = true,
	editBoxWidth = 500,
	maxLetters = 500,
	timeout = 0,
	exclusive = true,
	whileDead = true,
	hideOnEscape = true
}


local function WorkOrderPopup(playerName)
	StaticPopup_Show("CREATE_WORKORDER_POPUP", playerName).data = playerName
end

local function DelayedWorkOrder(playerName)
	local capPlayerName = CapFirstLetter(playerName)
	if ProEnchantersOptions["WelcomeMsg"] then
		local WelcomeMsg = ProEnchantersOptions["WelcomeMsg"]
		local FullWelcomeMsg = string.gsub(WelcomeMsg, "CUSTOMER", capPlayerName)
		if FullWelcomeMsg == "" then
			CreateCusWorkOrder(playerName)
		else
			SendChatMessage(FullWelcomeMsg, IsInRaid() and "RAID" or "PARTY")
			CreateCusWorkOrder(playerName)
		end
	end
end

StaticPopupDialogs["CREATE_WORKORDER_POPUP"] = {
	text = "Create work order for %s ?",
	button1 = "Create",
	button2 = "Cancel",
	OnAccept = function(self, playerName)
		local playerName = playerName
		DelayedWorkOrder(playerName)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3, -- Avoid taint issues
}

local function RepositionEnchantsFrame(WorkOrderEnchantsFrame)
	if WorkOrderEnchantsFrame then
		WorkOrderEnchantsFrame:ClearAllPoints()
		local _, wofSize = ProEnchantersWorkOrderFrame:GetSize()
		if wofSize < 250 then
			--WorkOrderEnchantsFrame:SetSize(230, 630)
			WorkOrderEnchantsFrame:SetPoint("TOPLEFT", ProEnchantersWorkOrderFrame, "TOPRIGHT", -1, 0)
		else
			WorkOrderEnchantsFrame:SetSize(230, 630)
			WorkOrderEnchantsFrame:SetPoint("TOPLEFT", ProEnchantersWorkOrderFrame, "TOPRIGHT", -1, 0)
			WorkOrderEnchantsFrame:SetPoint("BOTTOMLEFT", ProEnchantersWorkOrderFrame, "BOTTOMRIGHT", -1, 0)
		end
		WorkOrderEnchantsFrame:SetFrameLevel(1)
	end
end

local function ResetFrames()
	RepositionEnchantsFrame(ProEnchantersWorkOrderEnchantsFrame)
end

local function FullResetFrames()
	ProEnchantersWorkOrderFrame:ClearAllPoints()
	ProEnchantersWorkOrderFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
	local ScrollChild = ProEnchantersWorkOrderFrame.ScrollFrame:GetScrollChild()
	ScrollChild.bgTexture:Show()
	ScrollChild:Show()
	ScrollChild.closeBg:Show()
	ScrollChild.ClearAllButton:Show()
	ScrollChild.resizeButton:Show()
	ScrollChild.closeButton:Show()
	ScrollChild.settingsButton:Show()
	ScrollChild.GoldTradedDisplay:Show()
	ScrollChild.scrollBg:Show()
	ProEnchantersWorkOrderFrame.ScrollFrame:Show()
	--local currentWidth, currentHeight = ProEnchantersWorkOrderFrame:GetSize()
	--local point, relativeTo, relativePoint, xOfs, yOfs = ProEnchantersWorkOrderFrame:GetPoint()
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	x, y = x / scale, y / scale
	ProEnchantersWorkOrderFrame:SetSize(455, 630)
	RepositionEnchantsFrame(ProEnchantersWorkOrderEnchantsFrame)
end

--[[ PopUp Menu to create work order
local function WorkOrderButton(self)
	if self.value == "WorkOrderButton" then
		local dropdownMenu = _G["UIDROPDOWNMENU_INIT_MENU"]
		if (dropdownMenu.name ~= UnitName("player")) then
			CreateCusWorkOrder(dropdownMenu.name)
			ProEnchantersCustomerNameEditBox:SetText(dropdownMenu.name)
			if ProEnchantersWorkOrderFrame and not ProEnchantersWorkOrderFrame:IsVisible() then
				ProEnchantersWorkOrderFrame:Show()
				ProEnchantersWorkOrderEnchantsFrame:Show()
				ResetFrames()
			end
		end
	else
	end
end
]]

--[[ this one was confirmed working
local menuButton = Menu.ModifyMenu("MENU_UNIT_PLAYER", function(_, menuButton)
	menuButton:CreateButton("Create Work Order", function()
		local target = UnitName("target")
		CreateCusWorkOrder(target)
		ProEnchantersCustomerNameEditBox:SetText(target)
		if ProEnchantersWorkOrderFrame and not ProEnchantersWorkOrderFrame:IsVisible() then
			ProEnchantersWorkOrderFrame:Show()
			ProEnchantersWorkOrderEnchantsFrame:Show()
			ResetFrames()
		end
	end)
end)
]]

-- Function to create the work order button
local function createWorkOrderButton(menuButton, contextData)
	menuButton:CreateButton("Create Work Order", function()
		CreateCusWorkOrder(contextData.name)
		ProEnchantersCustomerNameEditBox:SetText(contextData.name)
		if ProEnchantersWorkOrderFrame and not ProEnchantersWorkOrderFrame:IsVisible() then
			ProEnchantersWorkOrderFrame:Show()
			ProEnchantersWorkOrderEnchantsFrame:Show()
			ResetFrames()
		end
	end)
end

-- Add custom Pro Enchanters options to various menus
local function addProEnchantersMenu(menuName)
	Menu.ModifyMenu(menuName, function(_, menuButton, contextData)
		menuButton:CreateDivider()
		menuButton:CreateTitle("Pro Enchanters")
		createWorkOrderButton(menuButton, contextData)
	end)
end

-- Modify menus for different unit types
addProEnchantersMenu("MENU_UNIT_SELF")   -- Right-click on Self
addProEnchantersMenu("MENU_UNIT_PLAYER") -- Right-click on players
addProEnchantersMenu("MENU_UNIT_PARTY")  -- Right-click on party members
addProEnchantersMenu("MENU_UNIT_RAID")   -- Right-click on raid members
addProEnchantersMenu("MENU_UNIT_FRIEND") -- Right-click on friends
addProEnchantersMenu("MENU_CHAT")        -- Right-click in chat messages
addProEnchantersMenu("MENU_VEHICLE")     -- Right-click on vehicles
addProEnchantersMenu("MENU_NAMEPLATE")   -- Right-click on nameplates

--[[ this one doesn't
local menuButton2 = Menu.ModifyMenu("MENU_UNIT_CHAT_ROSTER", function(menuButton, contextData)
	menuButton:CreateDivider()
	menuButton:CreateTitle("Pro Enchanters")
	menuButton:CreateButton("Create Work Order", function()
		CreateCusWorkOrder(contextData.name)
		ProEnchantersCustomerNameEditBox:SetText(contextData.name)
		if ProEnchantersWorkOrderFrame and not ProEnchantersWorkOrderFrame:IsVisible() then
			ProEnchantersWorkOrderFrame:Show()
			ProEnchantersWorkOrderEnchantsFrame:Show()
			ResetFrames()
		end
	end)
end)]]

--[[ Temporarily removed due to UnitPopup_ShowMenu being removed, WoW now uses UnitPopup_OpenMenu and no longer allows hooking the secure function to add menu items but now lets you add menu items through menu.modifymenu

-- Old Function
hooksecurefunc("UnitPopup_ShowMenu", function()
	if (UIDROPDOWNMENU_MENU_LEVEL > 1) then
		return
	end
	local info = UIDropDownMenu_CreateInfo()
	info.text = "Create Work Order"
	info.owner = which
	info.notCheckable = 1
	info.func = WorkOrderButton
	info.colorCode = "|cFF20B2AA"
	info.value = "WorkOrderButton"
	UIDropDownMenu_AddButton(info)
end)

-- Potential New Function for "target" only
local menuButton = Menu.ModifyMenu("MENU_UNIT_PLAYER", function(_, menuButton)
        menuButton:CreateButton("Create Work Order", function()
            local target = UnitName("target")
            CreateCusWorkOrder(target)
            ProEnchantersCustomerNameEditBox:SetText(target)
            if ProEnchantersWorkOrderFrame and not ProEnchantersWorkOrderFrame:IsVisible() then
                ProEnchantersWorkOrderFrame:Show()
                ProEnchantersWorkOrderEnchantsFrame:Show()
                ResetFrames()
            end
        end)
end)

-- Need to figure out the MENU_ for chat based context menus, not sure if it uses UNIT_TARGET or something else, putting CHAT_SENDER in-place of it for now
local menuButton = Menu.ModifyMenu("MENU_CHAT_SENDER", function(_, menuButton)
        menuButton:CreateButton("Create Work Order", function()
            local target = CHAT_SENDER?
            CreateCusWorkOrder(target)
            ProEnchantersCustomerNameEditBox:SetText(target)
            if ProEnchantersWorkOrderFrame and not ProEnchantersWorkOrderFrame:IsVisible() then
                ProEnchantersWorkOrderFrame:Show()
                ProEnchantersWorkOrderEnchantsFrame:Show()
                ResetFrames()
            end
        end)
end)


-- This is the WoW UI MENU_UNIT_ section:
local menuParent = nil;
	MenuUtil.CreateContextMenu(menuParent, function(owner, rootDescription)
		rootDescription:SetTag("MENU_UNIT_"..which, contextData);

		-- Create a class colored title atop every menu.
		local elementDescription = rootDescription:CreateTitle();
		elementDescription:AddInitializer(function(frame, description, menu)
			local title, class = GetNameAndClass(contextData.unit, contextData.name);
			frame.fontString:SetText(title);

			if class and not IsOnGlueScreen() then
				local colorCode = select(4, GetClassColor(class));
				local color = CreateColorFromHexString(colorCode);
				frame.fontString:SetTextColor(color:GetRGBA());
			end
		end);

		-- Section data for state relevant to each menu.
		local sectionData = {};
		local menu = self:GetMenu(which);
		for index, entry in ipairs(menu:AssembleMenuEntries(contextData)) do
			CreateEntries(entry, rootDescription, sectionData, contextData);
		end
	end);

Based on the 'swarm' addon on curseforge and based on this thread that seemed to have ran into a similar issue, here are relevant links:
https://www.wowinterface.com/forums/showthread.php?p=344204
https://www.curseforge.com/wow/addons/swarm
https://warcraft.wiki.gg/wiki/Patch_11.0.0/API_changes#New_menu_system
https://www.townlong-yak.com/framexml/latest/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua

I attempted to use the same formatting as the Swarm addon for adding the context menu but having someone test in-game for me since I do not have WoW anymore did not produce favorable results, needs more testing to get it working
Should be something similar to above though to get it working, in the swarm addon I do not see any call to the local menuButton to activate it so it seemed like just being a local variable was enough but I'm not sure, might have to add menuButton to somewhere else

]]

local yOffset = -5
local yOffsetoriginal = -80
local enchyOffset = 5
local enchyOffsetoriginal = -40


--Color for Frames
local OpacityAmount = 0.5

local TopBarColor = { 22 / 255, 26 / 255, 48 / 255 }
local r1, g1, b1 = unpack(TopBarColor)
local TopBarColorOpaque = { r1, g1, b1, 1 }
local TopBarColorTrans = { r1, g1, b1, OpacityAmount }

local SecondaryBarColor = { 49 / 255, 48 / 255, 77 / 255 }
local r2, g2, b2 = unpack(SecondaryBarColor)
local SecondaryBarColorOpaque = { r2, g2, b2, 1 }
local SecondaryBarColorTrans = { r2, g2, b2, OpacityAmount }

local MainWindowBackground = { 22 / 255, 26 / 255, 48 / 255 }
local r3, g3, b3 = unpack(MainWindowBackground)
local MainWindowBackgroundOpaque = { r3, g3, b3, 1 }
local MainWindowBackgroundTrans = { r3, g3, b3, OpacityAmount }

local BottomBarColor = { 22 / 255, 26 / 255, 48 / 255 }
local r4, g4, b4 = unpack(BottomBarColor)
local BottomBarColorOpaque = { r4, g4, b4, 1 }
local BottomBarColorTrans = { r4, g4, b4, OpacityAmount }

local EnchantsButtonColor = { 22 / 255, 26 / 255, 48 / 255 }
local r5, g5, b5 = unpack(EnchantsButtonColor)
local EnchantsButtonColorOpaque = { r5, g5, b5, 1 }
local EnchantsButtonColorTrans = { r5, g5, b5, OpacityAmount }

local EnchantsButtonColorInactive = { 71 / 255, 71 / 255, 71 / 255 }
local r6, g6, b6 = unpack(EnchantsButtonColorInactive)
local EnchantsButtonColorInactiveOpaque = { r6, g6, b6, 1 }
local EnchantsButtonColorInactiveTrans = { r6, g6, b6, OpacityAmount }

local BorderColor = { 2 / 255, 2 / 255, 2 / 255 }
local r7, g7, b7 = unpack(BorderColor)
local BorderColorOpaque = { r7, g7, b7, 1 }
local BorderColorTrans = { r7, g7, b7, OpacityAmount }

local MainButtonColor = { 22 / 255, 26 / 255, 48 / 255 }
local r8, g8, b8 = unpack(MainButtonColor)
local MainButtonColorOpaque = { r8, g8, b8, 1 }
local MainButtonColorTrans = { r8, g8, b8, OpacityAmount }

local SettingsWindowBackground = { 49 / 255, 48 / 255, 77 / 255 }
local r9, g9, b9 = unpack(SettingsWindowBackground)
local SettingsWindowBackgroundOpaque = { r9, g9, b9, 1 }
local SettingsWindowBackgroundTrans = { r9, g9, b9, OpacityAmount }

local ScrollBarColors = { 49 / 255, 48 / 255, 77 / 255 }
local r10, g10, b10 = unpack(ScrollBarColors)
local ButtonStandardAndThumb = { r10, g10, b10, 1 }
local r10P, r10DH = ((r10 * 255) / 4) / 255, ((r10 * 255) / 2) / 255
local g10P, g10DH = ((g10 * 255) / 4) / 255, ((g10 * 255) / 2) / 255
local b10P, b10DH = ((b10 * 255) / 4) / 255, ((b10 * 255) / 2) / 255
local ButtonPushed = { r10 + r10P, g10 + g10P, b10 + b10P, 1 }
local ButtonDisabled = { r10 - r10DH, g10 - g10DH, b10 - g10DH, 0.5 }
local ButtonHighlight = { r10 + r10DH, g10 + g10DH, b10 + b10DH, 1 }

-- Color Test
local ColorsTable = {
	GREY = "|cff888888",
	SUBWHITE = "|cffbbbbbb",
	ALICEBLUE = "|cFFF0F8FF",
	ANTIQUEWHITE = "|cFFFAEBD7",
	AQUA = "|cFF00FFFF",
	AQUAMARINE = "|cFF7FFFD4",
	AZURE = "|cFFF0FFFF",
	BEIGE = "|cFFF5F5DC",
	BISQUE = "|cFFFFE4C4",
	BLACK = "|cFF000000",
	BLANCHEDALMOND = "|cFFFFEBCD",
	BLUE = "|cFF0000FF",
	BLUEVIOLET = "|cFF8A2BE2",
	BROWN = "|cFFA52A2A",
	BURLYWOOD = "|cFFDEB887",
	CADETBLUE = "|cFF5F9EA0",
	CHARTREUSE = "|cFF7FFF00",
	CHOCOLATE = "|cFFD2691E",
	CORAL = "|cFFFF7F50",
	CORNFLOWERBLUE = "|cFF6495ED",
	CORNSILK = "|cFFFFF8DC",
	CRIMSON = "|cFFDC143C",
	CYAN = "|cFF00FFFF",
	DARKBLUE = "|cFF00008B",
	DARKCYAN = "|cFF008B8B",
	DARKGOLDENROD = "|cFFB8860B",
	DARKGRAY = "|cFFA9A9A9",
	DARKGREEN = "|cFF006400",
	DARKKHAKI = "|cFFBDB76B",
	DARKMAGENTA = "|cFF8B008B",
	DARKOLIVEGREEN = "|cFF556B2F",
	DARKORANGE = "|cFFFF8C00",
	DARKORCHID = "|cFF9932CC",
	DARKRED = "|cFF8B0000",
	DARKSALMON = "|cFFE9967A",
	DARKSEAGREEN = "|cFF8FBC8B",
	DARKSLATEBLUE = "|cFF483D8B",
	DARKSLATEGRAY = "|cFF2F4F4F",
	DARKTURQUOISE = "|cFF00CED1",
	DARKVIOLET = "|cFF9400D3",
	DEEPPINK = "|cFFFF1493",
	DEEPSKYBLUE = "|cFF00BFFF",
	DIMGRAY = "|cFF696969",
	DODGERBLUE = "|cFF1E90FF",
	FIREBRICK = "|cFFB22222",
	FLORALWHITE = "|cFFFFFAF0",
	FORESTGREEN = "|cFF228B22",
	FUCHSIA = "|cFFFF00FF",
	GAINSBORO = "|cFFDCDCDC",
	GHOSTWHITE = "|cFFF8F8FF",
	GOLD = "|cFFFFD700",
	GOLDENROD = "|cFFDAA520",
	GRAY = "|cFF808080",
	GREEN = "|cFF008000",
	GREENYELLOW = "|cFFADFF2F",
	HONEYDEW = "|cFFF0FFF0",
	HOTPINK = "|cFFFF69B4",
	INDIANRED = "|cFFCD5C5C",
	INDIGO = "|cFF4B0082",
	IVORY = "|cFFFFFFF0",
	KHAKI = "|cFFF0E68C",
	LAVENDER = "|cFFE6E6FA",
	LAVENDERBLUSH = "|cFFFFF0F5",
	LAWNGREEN = "|cFF7CFC00",
	LEMONCHIFFON = "|cFFFFFACD",
	LIGHTBLUE = "|cFFADD8E6",
	LIGHTCORAL = "|cFFF08080",
	LIGHTCYAN = "|cFFE0FFFF",
	LIGHTGRAY = "|cFFD3D3D3",
	LIGHTGREEN = "|cFF90EE90",
	LIGHTPINK = "|cFFFFB6C1",
	LIGHTRED = "|cFFFF6060",
	LIGHTSALMON = "|cFFFFA07A",
	LIGHTSEAGREEN = "|cFF20B2AA",
	LIGHTSKYBLUE = "|cFF87CEFA",
	LIGHTSLATEGRAY = "|cFF778899",
	LIGHTSTEELBLUE = "|cFFB0C4DE",
	LIGHTYELLOW = "|cFFFFFFE0",
	LIME = "|cFF00FF00",
	LIMEGREEN = "|cFF32CD32",
	LINEN = "|cFFFAF0E6",
	MAGENTA = "|cFFFF00FF",
	MAROON = "|cFF800000",
	MEDIUMAQUAMARINE = "|cFF66CDAA",
	MEDIUMBLUE = "|cFF0000CD",
	MEDIUMORCHID = "|cFFBA55D3",
	MEDIUMPURPLE = "|cFF9370DB",
	MEDIUMSEAGREEN = "|cFF3CB371",
	MEDIUMSLATEBLUE = "|cFF7B68EE",
	MEDIUMSPRINGGREEN = "|cFF00FA9A",
	MEDIUMTURQUOISE = "|cFF48D1CC",
	MEDIUMVIOLETRED = "|cFFC71585",
	MIDNIGHTBLUE = "|cFF191970",
	MINTCREAM = "|cFFF5FFFA",
	MISTYROSE = "|cFFFFE4E1",
	MOCCASIN = "|cFFFFE4B5",
	NAVAJOWHITE = "|cFFFFDEAD",
	NAVY = "|cFF000080",
	OLDLACE = "|cFFFDF5E6",
	OLIVE = "|cFF808000",
	OLIVEDRAB = "|cFF6B8E23",
	ORANGE = "|cFFFFA500",
	ORANGERED = "|cFFFF4500",
	ORCHID = "|cFFDA70D6",
	PALEGOLDENROD = "|cFFEEE8AA",
	PALEGREEN = "|cFF98FB98",
	PALETURQUOISE = "|cFFAFEEEE",
	PALEVIOLETRED = "|cFFDB7093",
	PAPAYAWHIP = "|cFFFFEFD5",
	PEACHPUFF = "|cFFFFDAB9",
	PERU = "|cFFCD853F",
	PINK = "|cFFFFC0CB",
	PLUM = "|cFFDDA0DD",
	POWDERBLUE = "|cFFB0E0E6",
	PURPLE = "|cFF800080",
	RED = "|cFFFF0000",
	ROSYBROWN = "|cFFBC8F8F",
	ROYALBLUE = "|cFF4169E1",
	SADDLEBROWN = "|cFF8B4513",
	SALMON = "|cFFFA8072",
	SANDYBROWN = "|cFFF4A460",
	SEAGREEN = "|cFF2E8B57",
	SEASHELL = "|cFFFFF5EE",
	SIENNA = "|cFFA0522D",
	SILVER = "|cFFC0C0C0",
	SKYBLUE = "|cFF87CEEB",
	SLATEBLUE = "|cFF6A5ACD",
	SLATEGRAY = "|cFF708090",
	SNOW = "|cFFFFFAFA",
	SPRINGGREEN = "|cFF00FF7F",
	STEELBLUE = "|cFF4682B4",
	TAN = "|cFFD2B48C",
	TEAL = "|cFF008080",
	THISTLE = "|cFFD8BFD8",
	TOMATO = "|cFFFF6347",
	TRANSPARENT = "|c00FFFFFF",
	TURQUOISE = "|cFF40E0D0",
	VIOLET = "|cFFEE82EE",
	WHEAT = "|cFFF5DEB3",
	WHITE = "|cFFFFFFFF",
	WHITESMOKE = "|cFFF5F5F5",
	YELLOW = "|cFFFFFF00",
	YELLOWGREEN = "|cFF9ACD32"
}

function PEColorTest()
	local line = ""
	for k, v in pairs(ColorsTable) do
		line = line .. v .. k .. ColorClose .. ", "
	end
	print(line)
end

--Color for Text

GREY = "|cff888888"
WHITE = "|cffffffff"
SUBWHITE = "|cffbbbbbb"
MAGENTA = "|cffff00ff"
YELLOW = "|cffffff00"
CYAN = "|cff00ffff"
LIGHTRED = "|cffff6060"
LIGHTBLUE = "|cff00ccff"
BLUE = "|cff0000ff"
GREEN = "|cff00ff00"
RED = "|cffff0000"
GOLD = "|cffffcc00"
ALICEBLUE = "|cFFF0F8FF"
ANTIQUEWHITE = "|cFFFAEBD7"
AQUA = "|cFF00FFFF"
AQUAMARINE = "|cFF7FFFD4"
AZURE = "|cFFF0FFFF"
BEIGE = "|cFFF5F5DC"
BISQUE = "|cFFFFE4C4"
BLACK = "|cFF000000"
BLANCHEDALMOND = "|cFFFFEBCD"
BLUE = "|cFF0000FF"
BLUEVIOLET = "|cFF8A2BE2"
BROWN = "|cFFA52A2A"
BURLYWOOD = "|cFFDEB887"
CADETBLUE = "|cFF5F9EA0"
CHARTREUSE = "|cFF7FFF00"
CHOCOLATE = "|cFFD2691E"
CORAL = "|cFFFF7F50"
CORNFLOWERBLUE = "|cFF6495ED"
CORNSILK = "|cFFFFF8DC"
CRIMSON = "|cFFDC143C"
CYAN = "|cFF00FFFF"
DARKBLUE = "|cFF00008B"
DARKCYAN = "|cFF008B8B"
DARKGOLDENROD = "|cFFB8860B"
DARKGRAY = "|cFFA9A9A9"
DARKGREEN = "|cFF006400"
DARKKHAKI = "|cFFBDB76B"
DARKMAGENTA = "|cFF8B008B"
DARKOLIVEGREEN = "|cFF556B2F"
DARKORANGE = "|cFFFF8C00"
DARKORCHID = "|cFF9932CC"
DARKRED = "|cFF8B0000"
DARKSALMON = "|cFFE9967A"
DARKSEAGREEN = "|cFF8FBC8B"
DARKSLATEBLUE = "|cFF483D8B"
DARKSLATEGRAY = "|cFF2F4F4F"
DARKTURQUOISE = "|cFF00CED1"
DARKVIOLET = "|cFF9400D3"
DEEPPINK = "|cFFFF1493"
DEEPSKYBLUE = "|cFF00BFFF"
DIMGRAY = "|cFF696969"
DODGERBLUE = "|cFF1E90FF"
FIREBRICK = "|cFFB22222"
FLORALWHITE = "|cFFFFFAF0"
FORESTGREEN = "|cFF228B22"
FUCHSIA = "|cFFFF00FF"
GAINSBORO = "|cFFDCDCDC"
GHOSTWHITE = "|cFFF8F8FF"
GOLD = "|cFFFFD700"
GOLDENROD = "|cFFDAA520"
GRAY = "|cFF808080"
GREEN = "|cFF008000"
GREENYELLOW = "|cFFADFF2F"
HONEYDEW = "|cFFF0FFF0"
HOTPINK = "|cFFFF69B4"
INDIANRED = "|cFFCD5C5C"
INDIGO = "|cFF4B0082"
IVORY = "|cFFFFFFF0"
KHAKI = "|cFFF0E68C"
LAVENDER = "|cFFE6E6FA"
LAVENDERBLUSH = "|cFFFFF0F5"
LAWNGREEN = "|cFF7CFC00"
LEMONCHIFFON = "|cFFFFFACD"
LIGHTBLUE = "|cFFADD8E6"
LIGHTCORAL = "|cFFF08080"
LIGHTCYAN = "|cFFE0FFFF"
LIGHTGRAY = "|cFFD3D3D3"
LIGHTGREEN = "|cFF90EE90"
LIGHTPINK = "|cFFFFB6C1"
LIGHTRED = "|cFFFF6060"
LIGHTSALMON = "|cFFFFA07A"
LIGHTSEAGREEN = "|cFF20B2AA"
LIGHTSKYBLUE = "|cFF87CEFA"
LIGHTSLATEGRAY = "|cFF778899"
LIGHTSTEELBLUE = "|cFFB0C4DE"
LIGHTYELLOW = "|cFFFFFFE0"
LIME = "|cFF00FF00"
LIMEGREEN = "|cFF32CD32"
LINEN = "|cFFFAF0E6"
MAGENTA = "|cFFFF00FF"
MAROON = "|cFF800000"
MEDIUMAQUAMARINE = "|cFF66CDAA"
MEDIUMBLUE = "|cFF0000CD"
MEDIUMORCHID = "|cFFBA55D3"
MEDIUMPURPLE = "|cFF9370DB"
MEDIUMSEAGREEN = "|cFF3CB371"
MEDIUMSLATEBLUE = "|cFF7B68EE"
MEDIUMSPRINGGREEN = "|cFF00FA9A"
MEDIUMTURQUOISE = "|cFF48D1CC"
MEDIUMVIOLETRED = "|cFFC71585"
MIDNIGHTBLUE = "|cFF191970"
MINTCREAM = "|cFFF5FFFA"
MISTYROSE = "|cFFFFE4E1"
MOCCASIN = "|cFFFFE4B5"
NAVAJOWHITE = "|cFFFFDEAD"
NAVY = "|cFF000080"
OLDLACE = "|cFFFDF5E6"
OLIVE = "|cFF808000"
OLIVEDRAB = "|cFF6B8E23"
ORANGE = "|cFFFFA500"
ORANGERED = "|cFFFF4500"
ORCHID = "|cFFDA70D6"
PALEGOLDENROD = "|cFFEEE8AA"
PALEGREEN = "|cFF98FB98"
PALETURQUOISE = "|cFFAFEEEE"
PALEVIOLETRED = "|cFFDB7093"
PAPAYAWHIP = "|cFFFFEFD5"
PEACHPUFF = "|cFFFFDAB9"
PERU = "|cFFCD853F"
PINK = "|cFFFFC0CB"
PLUM = "|cFFDDA0DD"
POWDERBLUE = "|cFFB0E0E6"
PURPLE = "|cFF800080"
RED = "|cFFFF0000"
ROSYBROWN = "|cFFBC8F8F"
ROYALBLUE = "|cFF4169E1"
SADDLEBROWN = "|cFF8B4513"
SALMON = "|cFFFA8072"
SANDYBROWN = "|cFFF4A460"
SEAGREEN = "|cFF2E8B57"
SEASHELL = "|cFFFFF5EE"
SIENNA = "|cFFA0522D"
SILVER = "|cFFC0C0C0"
SKYBLUE = "|cFF87CEEB"
SLATEBLUE = "|cFF6A5ACD"
SLATEGRAY = "|cFF708090"
SNOW = "|cFFFFFAFA"
SPRINGGREEN = "|cFF00FF7F"
STEELBLUE = "|cFF4682B4"
TAN = "|cFFD2B48C"
TEAL = "|cFF008080"
THISTLE = "|cFFD8BFD8"
TOMATO = "|cFFFF6347"
TRANSPARENT = "|c00FFFFFF"
TURQUOISE = "|cFF40E0D0"
VIOLET = "|cFFEE82EE"
WHEAT = "|cFFF5DEB3"
WHITE = "|cFFFFFFFF"
WHITESMOKE = "|cFFF5F5F5"
YELLOW = "|cFFFFFF00"
YELLOWGREEN = "|cFF9ACD32"
ColorClose = "|r"

-- At the top of your script file
ProEnchantersWorkOrderFrame = nil
ProEnchantersWorkOrderEnchantsFrame = nil
ProEnchantersOptionsFrame = nil
ProEnchantersTriggersFrame = nil
ProEnchantersWhisperTriggersFrame = nil
ProEnchantersImportFrame = nil
ProEnchantersCreditsFrame = nil
ProEnchantersGoldLogFrame = nil

-- Trigger Words Table
PESupporters = {
	"Lurrx",
	"Pen",
	"Braa",
	"Emoree",
	"Sechmann",
	"Okazaki",
	"JR004",
	"CoreOverload",
	"Fichek",
	"Chenice",
	"Ath",
	"Paulallen",
	"Artyrus",
	"Grrgg"
}

-- Filtered Words Table
PEFilteredWordsOriginal = {
	"{rt1}",
	"{rt2}",
	"{rt3}",
	"{rt4}",
	"{rt5}",
	"{rt6}",
	"{rt7}",
	"{rt8}",
	"{star}",
	"{circle}",
	"{coin}",
	"{diamond}",
	"{triangle}",
	"{moon}",
	"{square}",
	"{cross}",
	"{skull}",
	"wts",
	"sell",
	"service",
	"needs",
	"lfw",
	"tips",
	"all",
	"free",
	"lfm",
	"lfg",
	"your mats",
	"recipe",
	"every",
	"work",
	"sham"
}

-- Trigger Words Table
PETriggerWordsOriginal = {
	"ench",
	"chanter"
}

-- Inv Words Table
PEInvWordsOriginal = {
	"inv"
}

-- Whisper Triggers Table
PEWhisperTriggersOriginal = {
	[1] = {
		["!help"] =
		"Hello! Try using !info or !addon for more infomation. You can also request the mats for an enchant by whispering me the enchant name with a ! infront, example: !enchant boots - stamina"
	},
	[2] = {
		["!info"] =
		"As I am using the Pro Enchanter's add-on (!addon for more info) I am able to create large Enchant lists with required mats quickly to share with you. If you have any questions or requests feel free to ask :) check out !help for some other commands"
	},
	[3] = {
		["!addon"] =
		"I am using the Pro Enchanter's add-on on curseforge: https://www.curseforge.com/wow/addons/pro-enchanters :)"
	}
}

-- Enchants Names
EnchantsName = {}

for key, enchant in pairs(CombinedEnchants) do
	EnchantsName[key] = enchant.name
end

-- Function to extract stat value and type from enchant stats
local function extractStatValue(stats)
	local value = tonumber(stats:match("(%d+)"))
	local type = stats:match("%+%d+ ([%a%s]+)")
	return value or 0, type or ""
end

-- Function to get sorted keys
local function getSortedKeys(sortFunction)
	local keys = {}
	for key in pairs(CombinedEnchants) do
		table.insert(keys, key)
	end
	table.sort(keys, sortFunction)
	return keys
end

-- Sorting function for slot view
local function slotSort(a, b)
	local slotA, slotB = CombinedEnchants[a].slot, CombinedEnchants[b].slot
	if slotA ~= slotB then return slotA < slotB end

	local valueA, typeA = extractStatValue(CombinedEnchants[a].stats)
	local valueB, typeB = extractStatValue(CombinedEnchants[b].stats)

	if typeA ~= typeB then
		return typeA < typeB
	elseif valueA ~= valueB then
		return valueA > valueB
	else
		return a < b
	end
end

-- Sorting function for stat view
local function statSort(a, b)
	local valueA, typeA = extractStatValue(CombinedEnchants[a].stats)
	local valueB, typeB = extractStatValue(CombinedEnchants[b].stats)

	if typeA ~= typeB then
		return typeA < typeB
	elseif valueA ~= valueB then
		return valueA > valueB
	else
		return a < b
	end
end

-- Table for sorting by slot
EnchantsSortedSlot = getSortedKeys(slotSort)

-- Table for sorting by stat
EnchantsSortedStat = getSortedKeys(statSort)

-- PE Convertables
PEConvertablesName = {
	"Lesser Magic Essence",
	"Greater Magic Essence",
	"Lesser Astral Essence",
	"Greater Astral Essence",
	"Lesser Mystic Essence",
	"Greater Mystic Essence",
	"Lesser Eternal Essence",
	"Greater Eternal Essence",
	"Lesser Nether Essence",
	"Greater Nether Essence"
}

PEConvertablesId = {
	"10938",
	"10939",
	"10998",
	"11082",
	"11134",
	"11135",
	"16202",
	"16203",
	"11174",
	"11175"
}

--- DropDown Menu Creation by Jordan Benge
--- Opts:
---     name (string): Name of the dropdown (lowercase)
---     parent (Frame): Parent frame of the dropdown.
---     items (Table): String table of the dropdown options.
---     defaultVal (String): String value for the dropdown to default to (empty otherwise).
---     changeFunc (Function): A custom function to be called, after selecting a dropdown option.

local function hideTextureRegions(frame)
	local regions = { frame:GetRegions() }
	for _, region in ipairs(regions) do
		if region:IsObjectType("Texture") then
			region:Hide()
		end
	end
end
local function createDropdown(opts)
	local dropdown_name = '$parent_' .. opts['name'] .. '_dropdown'
	local menu_items = opts['items'] or {}
	local title_text = opts['title'] or ''
	local dropdown_width = 0
	local default_val = opts['defaultVal'] or ''
	local change_func = opts['changeFunc'] or function(dropdown_val) end

	local dropdown = CreateFrame("Frame", dropdown_name, opts['parent'], 'UIDropDownMenuTemplate')
	dropdown:SetWidth(120)
	local children = { dropdown:GetChildren() }
	for _, child in ipairs(children) do
		-- Hide textures of the dropdown button itself
		if child:GetName() then
			--hideTextureRegions(child)
			print(tostring(child:GetName()))
			-- Additionally, if you want to access and modify the child of this button, you can do so here
		end
	end

	-- Hide textures of the dropdown frame
	hideTextureRegions(dropdown)

	-- Create a new background texture
	local bg = dropdown:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(unpack(MainButtonColorOpaque)) -- RGBA color
	bg:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 30, -3)
	bg:SetSize(65, 20)
	local dd_title = dropdown:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	dd_title:SetPoint("TOPLEFT", 20, 10)

	for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
		dd_title:SetText(item)
		local text_width = dd_title:GetStringWidth() + 20
		if text_width > dropdown_width then
			dropdown_width = text_width
		end
	end

	UIDropDownMenu_SetWidth(dropdown, dropdown_width)
	UIDropDownMenu_SetText(dropdown, default_val)
	dd_title:SetText(title_text)

	UIDropDownMenu_Initialize(dropdown, function(self, level, _)
		local info = UIDropDownMenu_CreateInfo()
		for key, val in pairs(menu_items) do
			info.text = val;
			info.checked = false
			info.menuList = key
			info.hasArrow = false
			info.func = function(b)
				UIDropDownMenu_SetSelectedValue(dropdown, b.value, b.value)
				UIDropDownMenu_SetText(dropdown, b.value)
				b.checked = true
				change_func(dropdown, b.value)
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	return dropdown
end

local function createScrollableDropdown(opts)
	local dropdown_name = '$parent_' .. opts['name'] .. '_dropdown'
	local menu_items = opts['items'] or {}
	local title_text = opts['title'] or 'Select Option'  -- Default title if none provided
	local default_val = opts['defaultVal'] or menu_items[1] -- Use the first item as default if none provided
	local change_func = opts['changeFunc']
	local itemHeight = 20
	local displayItems = 10
	local scrollFrameHeight = displayItems * itemHeight

	local dropdown = CreateFrame("Frame", dropdown_name, opts['parent'])
	dropdown:SetSize(250, scrollFrameHeight + 30)

	-- Title or Selected Value Display
	local dd_title = dropdown:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	dd_title:SetPoint("TOP", dropdown, "TOP", 15, -8)
	dd_title:SetText(title_text) -- Set to default value or title

	-- Scroll Frame
	local scrollFrame = CreateFrame("ScrollFrame", nil, dropdown, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOP", dd_title, "BOTTOM", 0, -4)
	scrollFrame:SetSize(250, scrollFrameHeight)

	-- Access the Scroll Bar
	local scrollBar = scrollFrame.ScrollBar

	-- Customize Thumb Texture
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	thumbTexture:SetColorTexture(unpack(ButtonStandardAndThumb))
	--thumbTexture:SetAllPoints(thumbTexture)

	-- Customize Scroll Up Button Textures
	local upButton = scrollBar.ScrollUpButton

	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)

	-- Customize Scroll Up Button Textures with Solid Colors
	local upButton = scrollBar.ScrollUpButton

	-- Set colors
	upButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Replace RGBA values as needed
	upButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Replace RGBA values as needed
	upButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Replace RGBA values as needed
	upButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Replace RGBA values as needed

	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton

	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	-- Set colors
	downButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Adjust colors as needed
	downButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Adjust colors as needed
	downButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Adjust colors as needed
	downButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Adjust colors as needed

	local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	upButtonText:SetText("-")                              -- Set the text for the up button
	upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

	local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	downButtonText:SetText("-")                                -- Set the text for the down button
	downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetSize(scrollFrame:GetWidth(), #menu_items * itemHeight)

	for i, item in ipairs(menu_items) do
		local buttonBg = scrollChild:CreateTexture(nil, "OVERLAY")
		buttonBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
		buttonBg:SetSize(222, itemHeight - 2)             -- Adjust size as needed
		buttonBg:SetPoint("TOP", scrollChild, "TOP", 10, -(i - 1) * itemHeight)

		local button = CreateFrame("Button", nil, scrollChild)
		button:SetSize(220, itemHeight)
		button:SetPoint("TOP", scrollChild, "TOP", 10, -(i - 1) * itemHeight)
		button:SetText(item)
		local buttonText = button:GetFontString()
		buttonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
		button:SetNormalFontObject("GameFontHighlight")
		button:SetHighlightFontObject("GameFontNormal")
		button:SetScript("OnClick", function()
			dd_title:SetText(item) -- Update title/display to show selected item
			change_func(dropdown, item)
		end)
	end

	return dropdown
end

-- Initialize the ProEnchanters tables
ProEnchanters = {}
ProEnchanters.UIElements = {}
ProEnchanters.frame = CreateFrame("Frame")
ProEnchantersSettings = ProEnchantersSettings or {}


local function ScrollToActiveWorkOrder(customerName)
	local customerName = string.lower(customerName)
	local scrollFrame = ProEnchantersWorkOrderScrollFrame

	local scrollPosition = 0
	scrollFrame:SetVerticalScroll(scrollPosition)

	local cusName = "test"

	if customerName ~= nil or customerName ~= "" then
		cusName = string.lower(customerName)
	else
		cusName = string.lower(ProEnchantersCustomerNameEditBox:GetText())
	end

	for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
		local frameInfoString = tostring(frameInfo)
		local cusFrameCheck = string.lower(frameInfo.Frame.customerName)

		if frameInfo.Completed == false then
			if cusName == cusFrameCheck then
				break
				-- Found the active work order, break the loop
			elseif frameInfo.Frame.minimized == false then
				scrollPosition = scrollPosition + 162
			elseif frameInfo.Frame.minimized == true then
				scrollPosition = scrollPosition + 22
			end
		end
	end
	-- Set the scroll position to bring the active work order into view
	scrollFrame:SetVerticalScroll(scrollPosition)
end

-- Function to check if the frames are connected
local function CheckIfConnected()
	-- Example condition to check if frames are connected
	-- This is a simplistic check; you might need a more sophisticated method
	local point, relativeTo = ProEnchantersWorkOrderEnchantsFrame:GetPoint()
	if relativeTo == ProEnchantersWorkOrderFrame then
		isConnected = true
	else
		isConnected = false
	end
end

function ProEnchantersCreateWorkOrderFrame()
	local WorkOrderFrame = CreateFrame("Frame", "ProEnchantersWorkOrderFrame", UIParent, "BackdropTemplate")
	WorkOrderFrame:SetFrameStrata("DIALOG")
	WorkOrderFrame:SetSize(455, 630) -- Adjust height as needed
	WorkOrderFrame:SetPoint("TOP", 0, -200)
	WorkOrderFrame:SetResizable(true)
	WorkOrderFrame:SetResizeBounds(455, 250, 455, 2000)
	WorkOrderFrame:SetMovable(true)
	WorkOrderFrame:EnableMouse(true)
	WorkOrderFrame:RegisterForDrag("LeftButton")
	WorkOrderFrame:SetScript("OnDragStart", WorkOrderFrame.StartMoving)
	WorkOrderFrame:SetScript("OnDragStop", function()
		WorkOrderFrame:StopMovingOrSizing()
	end)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	WorkOrderFrame:SetBackdrop(backdrop)
	WorkOrderFrame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	WorkOrderFrame:Hide()

	-- Create a full background texture
	local bgTexture = WorkOrderFrame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(440, 545)
	bgTexture:SetPoint("TOPLEFT", WorkOrderFrame, "TOPLEFT", 0, -60)
	bgTexture:SetPoint("BOTTOMRIGHT", WorkOrderFrame, "BOTTOMRIGHT", 0, 25)
	local _, wofSize = WorkOrderFrame:GetSize()
	if wofSize < 240 then
		bgTexture:Hide()
	end

	-- Create a title background
	local titleBg = WorkOrderFrame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(440, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOPLEFT", WorkOrderFrame, "TOPLEFT", 0, 0)
	titleBg:SetPoint("TOPRIGHT", WorkOrderFrame, "TOPRIGHT", 0, 0)

	-- Auto Invite Checkbox
	local autoInviteCb = CreateFrame("CheckButton", nil, WorkOrderFrame, "ChatConfigCheckButtonTemplate")
	autoInviteCb:SetPoint("TOPRIGHT", WorkOrderFrame, "TOPRIGHT", -6, 0)
	--autoInviteCb:SetFrameLevel(9001)
	autoInviteCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	autoInviteCb:SetHitRectInsets(0, 0, 0, 0)
	autoInviteCb:SetChecked(ProEnchantersOptions["AutoInvite"])
	autoInviteCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["AutoInvite"] = self:GetChecked()
		AutoInvite = ProEnchantersOptions["AutoInvite"]
	end)

	-- Expand enchants button
	local enchantsShowButton = CreateFrame("Button", nil, WorkOrderFrame) --, "GameMenuButtonTemplate")
	enchantsShowButton:SetSize(15, 25)
	--enchantsShowButton:SetFrameLevel(9001)
	enchantsShowButton:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT", 0, -5)
	enchantsShowButton:SetText(">")
	local enchantsShowButtonText = enchantsShowButton:GetFontString()
	enchantsShowButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 4, "")
	enchantsShowButton:SetNormalFontObject("GameFontHighlight")
	enchantsShowButton:SetHighlightFontObject("GameFontNormal")
	enchantsShowButton:SetScript("OnClick", function()
		enchantsShowButton:Hide()
		ProEnchantersWorkOrderEnchantsFrame:Show()
		RepositionEnchantsFrame(ProEnchantersWorkOrderEnchantsFrame)
	end)
	enchantsShowButton:Hide()

	ProEnchantersWorkOrderFrame.enchantsShowButton = enchantsShowButton

	-- Auto Invite text
	local autoinviteHeader = WorkOrderFrame:CreateFontString(nil, "OVERLAY")
	autoinviteHeader:SetFontObject(UIFontBasic)
	autoinviteHeader:SetPoint("RIGHT", autoInviteCb, "LEFT", -5, 0)
	autoinviteHeader:SetText("Auto Invite?")

	local newcustomerBg = WorkOrderFrame:CreateTexture(nil, "BACKGROUND")
	newcustomerBg:SetColorTexture(unpack(SecondaryBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	newcustomerBg:SetSize(440, 35)                              -- Adjust size as needed
	newcustomerBg:SetPoint("TOPLEFT", WorkOrderFrame, "TOPLEFT", 0, -25)
	newcustomerBg:SetPoint("TOPRIGHT", WorkOrderFrame, "TOPRIGHT", 0, -25)

	local newcustomerBorder = WorkOrderFrame:CreateTexture(nil, "OVERLAY")
	newcustomerBorder:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	newcustomerBorder:SetSize(440, 1)                         -- Adjust size as needed
	newcustomerBorder:SetPoint("BOTTOMLEFT", newcustomerBg, "BOTTOMLEFT", 0, 0)
	newcustomerBorder:SetPoint("BOTTOMRIGHT", newcustomerBg, "BOTTOMRIGHT", 0, 0)

	local targetButton = CreateFrame("Button", "targetbutton", WorkOrderFrame, "SecureActionButtonTemplate")
	targetButton:SetSize(60, 25)
	targetButton:SetPoint("TOPRIGHT", WorkOrderFrame, "TOPRIGHT", -15, -33)
	targetButton:SetText("Target")
	local targetButtonText = targetButton:GetFontString()
	targetButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	targetButton:SetNormalFontObject("GameFontHighlight")
	targetButton:SetHighlightFontObject("GameFontNormal")
	targetButton:SetAttribute("type", "macro")
	targetButton:SetAttribute("macrotext", "/tar " .. target)

	-- Create an EditBox for the customer name
	local customerNameEditBox = CreateFrame("EditBox", "ProEnchantersCustomerNameEditBox", WorkOrderFrame,
		"InputBoxTemplate")
	customerNameEditBox:SetSize(156, 20)
	--customerNameEditBox:SetFrameLevel(9001)
	customerNameEditBox:SetPoint("TOP", newcustomerBg, "TOP", -5, -10)
	customerNameEditBox:SetAutoFocus(false)
	customerNameEditBox:SetFontObject("GameFontHighlight")
	customerNameEditBox:SetScript("OnEnterPressed", function()
		OnCreateWorkorderButtonClick() -- Call your existing function
		customerNameEditBox:ClearFocus() -- Remove focus from the edit box
		local customerName = ProEnchantersCustomerNameEditBox:GetText()
		UpdateTradeHistory(customerName)
	end)
	customerNameEditBox:SetScript("OnTextChanged", function()
		target = customerNameEditBox:GetText()
		targetButton:SetAttribute("macrotext", "/tar " .. target)
	end)

	-- Create a header for the customer name input
	local customerHeader = WorkOrderFrame:CreateFontString(nil, "OVERLAY")
	customerHeader:SetFontObject(UIFontBasic)
	customerHeader:SetPoint("RIGHT", customerNameEditBox, "LEFT", -10, 0)
	customerHeader:SetText("Customer:")

	local createBg = WorkOrderFrame:CreateTexture(nil, "ARTWORK")
	createBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	createBg:SetSize(60, 20)                             -- Adjust size as needed
	createBg:SetPoint("LEFT", customerNameEditBox, "RIGHT", 10, 0)

	-- Create a "Create" button
	local createButton = CreateFrame("Button", nil, WorkOrderFrame) --, "GameMenuButtonTemplate")
	createButton:SetSize(60, 20)
	--createButton:SetFrameLevel(9001)
	createButton:SetPoint("LEFT", customerNameEditBox, "RIGHT", 10, 0)
	createButton:SetText("Create")
	local createButtonText = createButton:GetFontString()
	createButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	createButton:SetNormalFontObject("GameFontHighlight")
	createButton:SetHighlightFontObject("GameFontNormal")
	createButton:SetScript("OnClick", function()
		OnCreateWorkorderButtonClick() -- Call your existing function
		customerNameEditBox:ClearFocus() -- Remove focus from the edit box
		local customerName = ProEnchantersCustomerNameEditBox:GetText()
		UpdateTradeHistory(customerName)
	end)

	--local targetmacro = "/say test"--"/tar " .. customerName

	--local macro2 = string.gsub(macro1, "enchValue", enchValue)

	local targetBg = WorkOrderFrame:CreateTexture(nil, "ARTWORK")
	targetBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	targetBg:SetSize(60, 20)                             -- Adjust size as needed
	targetBg:SetPoint("LEFT", createBg, "RIGHT", 10, 0)


	-- Scroll frame setup...
	local WorkOrderScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersWorkOrderScrollFrame", WorkOrderFrame,
		"UIPanelScrollFrameTemplate")
	WorkOrderScrollFrame:SetSize(415, 545)
	WorkOrderScrollFrame:SetPoint("TOPLEFT", newcustomerBg, "BOTTOMLEFT", 5, -1)
	WorkOrderScrollFrame:SetPoint("BOTTOMRIGHT", WorkOrderFrame, "BOTTOMRIGHT", -23, 25)
	WorkOrderFrame.ScrollFrame = WorkOrderScrollFrame
	if wofSize < 240 then
		WorkOrderScrollFrame:Hide()
	end

	-- Create a scroll background
	local scrollBg = WorkOrderFrame:CreateTexture(nil, "ARTWORK")
	scrollBg:SetColorTexture(unpack(ButtonDisabled)) -- Set RGBA values for your preferred color and alpha
	scrollBg:SetSize(18, 545)                     -- Adjust size as needed
	scrollBg:SetPoint("TOPRIGHT", WorkOrderFrame, "TOPRIGHT", 0, -60)
	scrollBg:SetPoint("BOTTOMRIGHT", WorkOrderFrame, "BOTTOMRIGHT", 0, 25)
	if wofSize < 240 then
		scrollBg:Hide()
	end
	-- Access the Scroll Bar
	local scrollBar = WorkOrderScrollFrame.ScrollBar
	--scrollBar:SetFrameLevel(9000)

	-- Customize Thumb Texture
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	thumbTexture:SetColorTexture(unpack(ButtonStandardAndThumb))
	--thumbTexture:SetAllPoints(thumbTexture)

	-- Customize Scroll Up Button Textures
	local upButton = scrollBar.ScrollUpButton

	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)

	-- Customize Scroll Up Button Textures with Solid Colors
	local upButton = scrollBar.ScrollUpButton

	-- Set solid color for normal state
	upButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Replace RGBA values as needed

	-- Set solid color for pushed state
	upButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed)) -- Replace RGBA values as needed

	-- Set solid color for disabled state
	upButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled)) -- Replace RGBA values as needed

	-- Set solid color for highlight state
	upButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight)) -- Replace RGBA values as needed

	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton

	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	-- Set solid color for normal state
	downButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Adjust colors as needed

	-- Set solid color for pushed state
	downButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed)) -- Adjust colors as needed

	-- Set solid color for disabled state
	downButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled)) -- Adjust colors as needed

	-- Set solid color for highlight state
	downButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight)) -- Adjust colors as needed

	local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	upButtonText:SetText("-")                              -- Set the text for the up button
	upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

	local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	downButtonText:SetText("-")                                -- Set the text for the down button
	downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed


	-- Scroll child frame where elements are actually placed
	local ScrollChild = CreateFrame("Frame")
	--ScrollChild:SetFrameLevel(8890)
	ScrollChild:SetSize(425, 545) -- Adjust height based on the number of elements
	WorkOrderScrollFrame:SetScrollChild(ScrollChild)
	if wofSize < 240 then
		ScrollChild:Hide()
	end

	-- local yOffset = -15

	-- Create a close button background
	local closeBg = WorkOrderFrame:CreateTexture(nil, "BACKGROUND")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(440, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOMLEFT", WorkOrderFrame, "BOTTOMLEFT", 0, 0)
	closeBg:SetPoint("BOTTOMRIGHT", WorkOrderFrame, "BOTTOMRIGHT", 0, 0)
	if wofSize < 240 then
		closeBg:Hide()
	end

	WorkOrderFrame.closeBg = closeBg

	-- Create a close button at the bottom
	local closeButton = CreateFrame("Button", nil, WorkOrderFrame)
	closeButton:SetSize(35, 25)                                  -- Adjust size as needed
	--closeButton:SetFrameLevel(9001)
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 5, 0) -- Adjust position as needed
	closeButton:SetText("Close")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")
	closeButton:SetScript("OnClick", function()
		WorkOrderFrame:Hide()
	end)
	if wofSize < 240 then
		closeButton:Hide()
	end

	local settingsButton = CreateFrame("Button", nil, WorkOrderFrame)
	settingsButton:SetSize(46, 25)                           -- Adjust size as needed
	--settingsButton:SetFrameLevel(9001)
	settingsButton:SetPoint("LEFT", closeButton, "RIGHT", 2, 0) -- Adjust position as needed
	settingsButton:SetText("Settings")
	local settingsButtonText = settingsButton:GetFontString()
	settingsButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	settingsButton:SetNormalFontObject("GameFontHighlight")
	settingsButton:SetHighlightFontObject("GameFontNormal")
	settingsButton:SetScript("OnClick", function()
		ProEnchantersOptionsFrame:Show()
	end)
	if wofSize < 240 then
		settingsButton:Hide()
	end

	local ClearAllButton = CreateFrame("Button", nil, WorkOrderFrame)
	ClearAllButton:SetSize(110, 20)                             -- Adjust size as needed
	--ClearAllButton:SetFrameLevel(9001)
	ClearAllButton:SetPoint("LEFT", settingsButton, "RIGHT", 8, 0) -- Adjust position as needed
	ClearAllButton:SetText("Finish All Work Orders")
	local ClearAllButtonText = ClearAllButton:GetFontString()
	ClearAllButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	ClearAllButton:SetNormalFontObject("GameFontHighlight")
	ClearAllButton:SetHighlightFontObject("GameFontNormal")
	if wofSize < 240 then
		ClearAllButton:Hide()
	end
	ClearAllButton:SetScript("OnClick", function()
		for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
			if frameInfo.Completed == false then
				frameInfo.Completed = true
				frameInfo.Frame:Hide()
				local customerName = frameInfo.Frame.customerName
				local tradeLine = LIGHTGREEN ..
					"---- End of Workorder# " .. frameInfo.Frame.frameID .. " ----" .. ColorClose
				table.insert(ProEnchantersTradeHistory[customerName], tradeLine)
			end
		end
		ProEnchantersCustomerNameEditBox:SetText("")
		ProEnchantersCustomerNameEditBox:ClearFocus(ProEnchantersCustomerNameEditBox)
		filterEditBox:SetText("")
		FilterEnchantButtons()
		filterEditBox.ClearFocus(filterEditBox)
		yOffset = -5
	end)

	-- GoldTraded Display
	local GoldTradedDisplay = CreateFrame("Button", nil, WorkOrderFrame)
	GoldTradedDisplay:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -15, 0)
	GoldTradedDisplay:SetText("Gold Traded: " .. GetMoneyString(GoldTraded))
	GoldTradedDisplay:SetSize(string.len(GoldTradedDisplay:GetText()) + 25, 25) -- Adjust size as needed
	local GoldTradedDisplayText = GoldTradedDisplay:GetFontString()
	GoldTradedDisplayText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	GoldTradedDisplay:SetNormalFontObject("GameFontHighlight")
	GoldTradedDisplay:SetHighlightFontObject("GameFontNormal")
	if wofSize < 240 then
		GoldTradedDisplay:Hide()
	end
	GoldTradedDisplay:SetScript("OnClick", function()
		ProEnchantersGoldFrame:Show()
	end)

	WorkOrderFrame.GoldTradedDisplay = GoldTradedDisplay

	WorkOrderFrame:SetScript("OnHide", function()
		ProEnchantersOptionsFrame:Hide()
		ProEnchantersTriggersFrame:Hide()
		ProEnchantersWhisperTriggersFrame:Hide()
		ProEnchantersImportFrame:Hide()
		ProEnchantersGoldFrame:Hide()
		ProEnchantersCreditsFrame:Hide()
		ProEnchantersColorsFrame:Hide()
	end)

	local resizeButton = CreateFrame("Button", nil, WorkOrderFrame)
	resizeButton:SetSize(16, 16)
	resizeButton:SetPoint("BOTTOMRIGHT")
	resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	if wofSize < 240 then
		resizeButton:Hide()
	end
	resizeButton:SetScript("OnMouseDown", function(self, button)
		WorkOrderFrame:StartSizing("BOTTOMRIGHT")
		WorkOrderFrame:SetUserPlaced(true)
	end)

	resizeButton:SetScript("OnMouseUp", function(self, button)
		WorkOrderFrame:StopMovingOrSizing()
	end)

	function toggleWorkOrderFrameMinimize()
		local currentHeight = WorkOrderFrame:GetHeight()
		local isMinimized = currentHeight < 240
		CheckIfConnected()
		local function maximizeFrame()
			WorkOrderFrame:SetSize(455, normHeight)
			bgTexture:Show()
			ScrollChild:Show()
			closeBg:Show()
			ClearAllButton:Show()
			resizeButton:Show()
			closeButton:Show()
			settingsButton:Show()
			GoldTradedDisplay:Show()
			scrollBg:Show()
			WorkOrderScrollFrame:Show()

			if isConnected then
				ProEnchantersWorkOrderEnchantsFrame:Show()
			end
		end

		local function minimizeFrame()
			_, normHeight = WorkOrderFrame:GetSize()
			WorkOrderFrame:SetSize(455, 60)
			bgTexture:Hide()
			ScrollChild:Hide()
			closeBg:Hide()
			ClearAllButton:Hide()
			resizeButton:Hide()
			closeButton:Hide()
			settingsButton:Hide()
			GoldTradedDisplay:Hide()
			scrollBg:Hide()
			WorkOrderScrollFrame:Hide()

			if isConnected then
				ProEnchantersWorkOrderEnchantsFrame:Hide()
			end
		end

		if isMinimized then
			maximizeFrame()
		else
			minimizeFrame()
		end
	end

	-- Top Title Minimizes Frame
	local titleButton = CreateFrame("Button", nil, WorkOrderFrame)
	titleButton:SetSize(150, 25)                   -- Adjust size as needed
	--titleButton:SetFrameLevel(9001)
	titleButton:SetPoint("TOP", titleBg, "TOP", 0, 0) -- Adjust position as needed
	titleButton:SetText("Pro Enchanters - Work Orders")
	local titleButtonText = titleButton:GetFontString()
	titleButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	titleButton:SetNormalFontObject("GameFontHighlight")
	titleButton:SetHighlightFontObject("GameFontNormal")

	WorkOrderFrame:SetScript("OnShow", function()
		local currentHeight = WorkOrderFrame:GetHeight()
		if currentHeight < 240 then -- If the work order frame is minimized, show it maximized
			toggleWorkOrderFrameMinimize()
		end
	end)

	titleButton:SetScript("OnClick", function()
		toggleWorkOrderFrameMinimize()
	end)

	ScrollChild.bgTexture = bgTexture
	ScrollChild.closeBg = closeBg
	ScrollChild.ClearAllButton = ClearAllButton
	ScrollChild.resizeButton = resizeButton
	ScrollChild.closeButton = closeButton
	ScrollChild.settingsButton = settingsButton
	ScrollChild.GoldTradedDisplay = GoldTradedDisplay
	ScrollChild.scrollBg = scrollBg


	return WorkOrderFrame
end

function ProEnchantersCreateWorkOrderEnchantsFrame(ProEnchantersWorkOrderFrame)
	local WorkOrderEnchantsFrame = CreateFrame("Frame", "ProEnchantersWorkOrderEnchantsFrame",
		ProEnchantersWorkOrderFrame, "BackdropTemplate")
	WorkOrderEnchantsFrame:SetSize(230, 630) -- Adjust height as needed
	WorkOrderEnchantsFrame:SetFrameStrata("DIALOG")
	WorkOrderEnchantsFrame:SetFrameLevel(1)
	WorkOrderEnchantsFrame:SetPoint("TOPLEFT", ProEnchantersWorkOrderFrame, "TOPRIGHT", -1, 0)
	WorkOrderEnchantsFrame:SetPoint("BOTTOMLEFT", ProEnchantersWorkOrderFrame, "BOTTOMLEFT", -1, 0)
	WorkOrderEnchantsFrame:SetResizable(true)
	WorkOrderEnchantsFrame:SetResizeBounds(230, 250, 230, 1000)
	WorkOrderEnchantsFrame:SetMovable(true)
	WorkOrderEnchantsFrame:EnableMouse(true)
	WorkOrderEnchantsFrame:RegisterForDrag("LeftButton")
	WorkOrderEnchantsFrame:SetScript("OnDragStart", WorkOrderEnchantsFrame.StartMoving)
	WorkOrderEnchantsFrame:Hide()

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	WorkOrderEnchantsFrame:SetBackdrop(backdrop)
	WorkOrderEnchantsFrame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	-- Create a full background texture
	local bgTexture = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(230, 570)
	bgTexture:SetPoint("TOP", WorkOrderEnchantsFrame, "TOP", 0, -60)
	bgTexture:SetPoint("BOTTOM", WorkOrderEnchantsFrame, "BOTTOM", 0, 25)

	-- Create a title background
	local titleBg = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(230, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOP", WorkOrderEnchantsFrame, "TOP", 0, 0)


	local filterBg = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
	filterBg:SetColorTexture(unpack(SecondaryBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	filterBg:SetSize(230, 35)                              -- Adjust size as needed
	filterBg:SetPoint("TOP", WorkOrderEnchantsFrame, "TOP", 0, -25)

	local filterBgBorder = WorkOrderEnchantsFrame:CreateTexture(nil, "OVERLAY")
	filterBgBorder:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	filterBgBorder:SetSize(230, 1)                         -- Adjust size as needed
	filterBgBorder:SetPoint("BOTTOM", filterBg, "BOTTOM", 0, 0)

	-- Create a header for the customer name input
	local filterHeader = WorkOrderEnchantsFrame:CreateFontString(nil, "OVERLAY")
	filterHeader:SetFontObject(UIFontBasic)
	filterHeader:SetPoint("TOPLEFT", filterBg, "TOPLEFT", 10, -15)
	filterHeader:SetText("Filter:")

	local defaultVal = ProEnchantersOptions["SortBy"]

	local sortby_opts = {
		['name'] = 'sortby',
		['parent'] = WorkOrderEnchantsFrame,
		['title'] = '',
		['items'] = { "Default", "Slot View", "Stat View" },
		['defaultVal'] = defaultVal,
		['changeFunc'] = function(dropdown_frame, dropdown_val)
			ProEnchantersOptions["SortBy"] = dropdown_val
			FilterEnchantButtons()
		end
	}

	local SortByDD = createDropdown(sortby_opts)
	-- Don't forget to set your dropdown's points, we don't do this in the creation method for simplicities sake.
	SortByDD:SetPoint("LEFT", filterHeader, "RIGHT", -25, -2)

	-- Create an EditBox for the customer name
	filterEditBox = CreateFrame("EditBox", "ProEnchantersCustomerNameEditBox", WorkOrderEnchantsFrame,
		"InputBoxTemplate")
	filterEditBox:SetSize(50, 20)
	filterEditBox:SetPoint("LEFT", SortByDD, "RIGHT", -8, 3)
	filterEditBox:SetAutoFocus(false)
	-- Set Text
	filterEditBox:SetFontObject("GameFontHighlight")
	-- Scripts
	filterEditBox:SetScript("OnEnterPressed", filterEditBox.ClearFocus)
	filterEditBox:SetScript("OnTextChanged", function()
		FilterEnchantButtons()
	end)

	local clearBg = WorkOrderEnchantsFrame:CreateTexture(nil, "OVERLAY")
	clearBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	clearBg:SetSize(40, 20)                             -- Adjust size as needed
	clearBg:SetPoint("LEFT", filterEditBox, "RIGHT", 5, 0)

	-- Create a "Create" button
	local clearButton = CreateFrame("Button", nil, WorkOrderEnchantsFrame) --, "GameMenuButtonTemplate")
	clearButton:SetSize(40, 20)
	clearButton:SetPoint("LEFT", filterEditBox, "RIGHT", 5, 0)
	clearButton:SetText("Clear")
	local clearButtonText = clearButton:GetFontString()
	clearButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	clearButton:SetNormalFontObject("GameFontHighlight")
	clearButton:SetHighlightFontObject("GameFontNormal")
	clearButton:SetScript("OnClick", function()
		filterEditBox:SetText("")
		FilterEnchantButtons()
		filterEditBox.ClearFocus(filterEditBox)
	end)

	-- Setup for the scroll frame
	local WorkOrderEnchantsScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersWorkOrderEnchantsScrollFrame",
		WorkOrderEnchantsFrame, "UIPanelScrollFrameTemplate")
	WorkOrderEnchantsScrollFrame:SetSize(200, 570)
	WorkOrderEnchantsScrollFrame:SetPoint("TOP", filterBg, "BOTTOM", -8, -1)
	WorkOrderEnchantsScrollFrame:SetPoint("BOTTOM", WorkOrderEnchantsFrame, "BOTTOM", -8, 25)

	-- Create a scroll background
	local scrollBg = WorkOrderEnchantsFrame:CreateTexture(nil, "ARTWORK")
	scrollBg:SetColorTexture(unpack(ButtonDisabled)) -- Set RGBA values for your preferred color and alpha
	scrollBg:SetSize(18, 570)                     -- Adjust size as needed
	scrollBg:SetPoint("TOPRIGHT", WorkOrderEnchantsFrame, "TOPRIGHT", 0, -60)
	scrollBg:SetPoint("BOTTOMRIGHT", WorkOrderEnchantsFrame, "BOTTOMRIGHT", 0, 25)

	-- Access the Scroll Bar
	local scrollBar = WorkOrderEnchantsScrollFrame.ScrollBar

	-- Customize Thumb Texture
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	thumbTexture:SetColorTexture(unpack(ButtonStandardAndThumb))
	--thumbTexture:SetAllPoints(thumbTexture)

	-- Customize Scroll Up Button Textures
	local upButton = scrollBar.ScrollUpButton

	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)

	-- Customize Scroll Up Button Textures with Solid Colors
	local upButton = scrollBar.ScrollUpButton

	-- Set solid color for normal state
	upButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Replace RGBA values as needed

	-- Set solid color for pushed state
	upButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed)) -- Replace RGBA values as needed

	-- Set solid color for disabled state
	upButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled)) -- Replace RGBA values as needed

	-- Set solid color for highlight state
	upButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight)) -- Replace RGBA values as needed

	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton

	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	-- Set solid color for normal state
	downButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Adjust colors as needed

	-- Set solid color for pushed state
	downButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed)) -- Adjust colors as needed

	-- Set solid color for disabled state
	downButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled)) -- Adjust colors as needed

	-- Set solid color for highlight state
	downButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight)) -- Adjust colors as needed

	local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	upButtonText:SetText("-")                              -- Set the text for the up button
	upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

	local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	downButtonText:SetText("-")                                -- Set the text for the down button
	downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed

	-- Scroll child frame where elements are actually placed
	local ScrollChild = CreateFrame("Frame")
	ScrollChild:SetSize(200, 565) -- Adjust height based on the number of elements
	WorkOrderEnchantsScrollFrame:SetScrollChild(ScrollChild)

	-- Using "for _, Enchants in ipairs(EnchantsName) do", create a clickable button that is 120x30, uses the key from enchants as the ID of the button and uses the value of the key as the text on the button. When this button is pressed, update the table CusEnchant in the current focus CusWorkOrder ENCHANTS frame by adding +1 to the value of the key. As an example, the start of the CusEnchant table should be ENCH1=0, update this to be ENCH1=1. When pressed again, add +1 again so that it is now ENCH1=2, and so forth as buttons are pressed.
	local enchyOffset = 5 -- Initial vertical offset for the first button

	local function alphanumericSort(a, b)
		-- Extract number from the string
		local numA = tonumber(a:match("%d+"))
		local numB = tonumber(b:match("%d+"))

		if numA and numB then -- If both strings have numbers, then compare numerically
			return numA < numB
		else
			return a < b -- If one or both strings don't have numbers, sort lexicographically
		end
	end

	-- Get and sort the keys
	local keys = {}
	for k in pairs(CombinedEnchants) do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		local numA = tonumber(a:match("%d+"))
		local numB = tonumber(b:match("%d+"))
		return numA < numB
	end)
	-- Sorts the keys numerically based on the number in the ENCH key

	enchantButtons = {}
	function FilterEnchantButtons()
		local sortby = ProEnchantersOptions["SortBy"]
		local filterText = filterEditBox:GetText():lower()
		local enchyOffset = 5
		local enchxOffset = 5
		local keys = keys
		if sortby == "Stat View" then
			keys = EnchantsSortedStat
		elseif sortby == "Slot View" then
			keys = EnchantsSortedSlot
		end

		for _, key in ipairs(keys) do
			if ProEnchantersOptions.filters[key] == true then
				if ProEnchantersOptions.favorites[key] == true then
					local enchantInfo = enchantButtons[key]
					local enchantName = CombinedEnchants[key].name:lower()
					local enchantStats1 = CombinedEnchants[key].stats
					local enchantStats2 = string.gsub(enchantStats1, "%(", "")
					local enchantStats3 = string.gsub(enchantStats2, "%)", "")
					local filterCheck = string.lower(enchantName .. enchantStats3)
					if filterText == "" or filterCheck:find(filterText, 1, true) then
						-- Show and position the button
						enchantInfo.button:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)
						enchantInfo.button:Show()
						enchantInfo.background:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)
						enchantInfo.background:Show()
						enchantInfo.favicon:Show()
						enchyOffset = enchyOffset + 35
					else
						-- Hide the button
						enchantInfo.button:Hide()
						enchantInfo.background:Hide()
						enchantInfo.favicon:Hide()
					end
				end
			end
		end

		for _, key in ipairs(keys) do
			if ProEnchantersOptions.filters[key] == true then
				if ProEnchantersOptions.favorites[key] ~= true then
					local enchantInfo = enchantButtons[key]
					local enchantName = CombinedEnchants[key].name:lower()
					local enchantStats1 = CombinedEnchants[key].stats
					local enchantStats2 = string.gsub(enchantStats1, "%(", "")
					local enchantStats3 = string.gsub(enchantStats2, "%)", "")
					local filterCheck = string.lower(enchantName .. enchantStats3)
					if filterText == "" or filterCheck:find(filterText, 1, true) then
						-- Show and position the button
						enchantInfo.button:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)
						enchantInfo.button:Show()
						enchantInfo.background:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)
						enchantInfo.background:Show()
						enchantInfo.favicon:Hide()
						enchyOffset = enchyOffset + 35
					else
						-- Hide the button
						enchantInfo.button:Hide()
						enchantInfo.background:Hide()
						enchantInfo.favicon:Hide()
					end
				end
			end
		end

		-- Adjust the height of ScrollChild based on the yOffset
		ScrollChild:SetHeight(enchyOffset)
	end

	for _, key in ipairs(keys) do
		local value = CombinedEnchants[key].name
		local enchantStats1 = CombinedEnchants[key].stats
		local enchantStats2 = string.gsub(enchantStats1, "%(", "")
		local enchantStats3 = string.gsub(enchantStats2, "%)", "")
		local enchantStats = string.gsub(enchantStats3, "%+", "")
		-- Split the enchantment name at the dash
		local enchantTitleText1 = string.gsub(value, "Enchant ", "")
		local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats
		local ench = key
		local enchName = value

		-- Create button Bg
		local enchantButtonBg = ScrollChild:CreateTexture(nil, "ARTWORK")
		enchantButtonBg:SetColorTexture(unpack(EnchantsButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
		enchantButtonBg:SetSize(195, 30)                             -- Adjust size as needed
		enchantButtonBg:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)

		-- Create a button
		local enchantButton = CreateFrame("Button", key, ScrollChild)
		enchantButton:SetSize(195, 30) -- Adjust the size as needed
		enchantButton:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)
		enchantButton:SetText(enchantTitleText)
		local enchantButtonText = enchantButton:GetFontString()
		enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
		enchantButton:SetNormalFontObject("GameFontHighlight")
		enchantButton:SetHighlightFontObject("GameFontNormal")

		-- Create a Announce icon
		local enchantFavIcon = ScrollChild:CreateTexture(nil, "OVERLAY")
		--enchantMatsMissingDisplay:SetColorTexture(unpack(EnchantsButtonColorOpaque))  -- Set RGBA values for your preferred color and alpha
		enchantFavIcon:SetTexture("Interface\\COMMON\\FavoritesIcon.blp")
		enchantFavIcon:SetSize(24, 24) -- Adjust size as needed
		enchantFavIcon:SetPoint("TOPRIGHT", enchantButtonBg, "TOPRIGHT", 6, 3)
		if ProEnchantersOptions.favorites[ench] == true then
			enchantFavIcon:Show()
		else
			enchantFavIcon:Hide()
		end

		-- Set the script for the button's OnClick event
		enchantButton:RegisterForClicks("RightButtonUp", "LeftButtonUp")
		enchantButton:SetScript("OnMouseUp", function(self, button)
			local customerName = ProEnchantersCustomerNameEditBox:GetText()
			customerName = string.lower(customerName)
			customerName = CapFirstLetter(customerName)
			local reqEnchant = ench
			local enchName, enchStats = GetEnchantName(reqEnchant)
			filterEditBox.ClearFocus(filterEditBox)
			if button == "RightButton" then
				if ProEnchantersOptions.favorites[ench] == true then
					ProEnchantersOptions.favorites[ench] = false
					enchantFavIcon:Hide()
				else
					ProEnchantersOptions.favorites[ench] = true
					enchantFavIcon:Show()
				end
				FilterEnchantButtons()
			elseif button == "LeftButton" then
				if IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown() then
					ProEnchantersOptions.filters[reqEnchant] = false
					enchantButton:Hide()
					enchantButtonBg:Hide()
					FilterEnchantButtons()
					UpdateCheckboxesBasedOnFilters()
				elseif IsShiftKeyDown() and IsControlKeyDown() then -- force whisper link
					local matsReq = ProEnchants_GetReagentList(reqEnchant)
					local msgReq = enchName .. enchStats .. " Mats Required: " .. matsReq
					local cusName = tostring(customerName)
					if cusName and cusName ~= "" then
						SendChatMessage(msgReq, "WHISPER", nil, cusName)
					else
						print("no whisper target for enchant link")
					end
				elseif IsShiftKeyDown() then -- Link to player via party or whisper
					--local matsReq = ProEnchants_GetReagentListNoLink(reqEnchant)
					local matsReq = ProEnchants_GetReagentList(reqEnchant)
					local msgReq = enchName .. enchStats .. " Mats Required: " .. matsReq
					local cusName = tostring(customerName)
					if ProEnchantersOptions["WhisperMats"] == true and cusName and cusName ~= "" then
						SendChatMessage(msgReq, "WHISPER", nil, cusName)
					elseif CheckIfPartyMember(customerName) == true then
						local capPlayerName = CapFirstLetter(customerName)
						SendChatMessage(capPlayerName .. ": " .. msgReq, IsInRaid() and "RAID" or "PARTY")
					elseif cusName and cusName ~= "" then
						SendChatMessage(msgReq, "WHISPER", nil, cusName)
					else
						SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
					end
				elseif IsControlKeyDown() and IsAltKeyDown() then -- Remove from current trade target
					local currentCusFocus = ProEnchantersCustomerNameEditBox:GetText()
					local currentTradeTarget = UnitName("NPC")
					if currentTradeTarget ~= nil then
						RemoveRequestedEnchant(currentTradeTarget, reqEnchant)
						ProEnchantersCustomerNameEditBox:SetText(currentCusFocus)
					end
					local confirmTradeTarget = UnitName("NPC")
					if confirmTradeTarget == currentTradeTarget then
						ProEnchantersUpdateTradeWindowButtons(confirmTradeTarget)
						ProEnchantersUpdateTradeWindowText(confirmTradeTarget)
					end
				elseif IsControlKeyDown() then -- Remove from current customer
					RemoveRequestedEnchant(customerName, reqEnchant)
					local currentCusFocus = ProEnchantersCustomerNameEditBox:GetText()
					local currentTradeTarget = UnitName("NPC")
					if currentCusFocus == currentTradeTarget then
						ProEnchantersUpdateTradeWindowButtons(currentTradeTarget)
						ProEnchantersUpdateTradeWindowText(currentTradeTarget)
					end
				elseif IsAltKeyDown() then -- Add to current trade target
					local currentCusFocus = ProEnchantersCustomerNameEditBox:GetText()
					local currentTradeTarget = UnitName("NPC")
					if currentTradeTarget ~= nil then
						AddRequestedEnchant(currentTradeTarget, reqEnchant)
						ProEnchantersCustomerNameEditBox:SetText(currentCusFocus)
					end
					local confirmTradeTarget = UnitName("NPC")
					if confirmTradeTarget and confirmTradeTarget ~= "Player" and confirmTradeTarget == currentTradeTarget then
						ProEnchantersUpdateTradeWindowButtons(confirmTradeTarget)
						ProEnchantersUpdateTradeWindowText(confirmTradeTarget)
					end
				else
					-- Actions to perform if no modifier is held down
					AddRequestedEnchant(customerName, reqEnchant)
					local currentCusFocus = ProEnchantersCustomerNameEditBox:GetText()
					local currentTradeTarget = UnitName("NPC")
					if currentCusFocus == currentTradeTarget then
						ProEnchantersUpdateTradeWindowButtons(currentTradeTarget)
						ProEnchantersUpdateTradeWindowText(currentTradeTarget)
					end
				end
			end
		end)

		-- Increase yOffset for the next button
		enchyOffset = enchyOffset + 35 -- Adjust the offset increment as needed

		-- Store the button and its background in the table
		enchantButtons[key] = { button = enchantButton, background = enchantButtonBg, favicon = enchantFavIcon }
		if ProEnchantersOptions.filters[key] == false then
			enchantButton:Hide()
			enchantButtonBg:Hide()
		end
	end


	-- Adjust the height of ScrollChild based on the yOffset
	ScrollChild:SetHeight(enchyOffset)

	-- Create a Snap button background
	local snapBg = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
	snapBg:SetColorTexture(0.14, 0.05, 0.2, 0) -- Set RGBA values for your preferred color and alpha
	snapBg:SetSize(25, 25)                  -- Adjust size as needed
	snapBg:SetPoint("TOPRIGHT", WorkOrderEnchantsFrame, "TOPRIGHT", 0, 0)
	snapBg:Hide()
	-- Create a Snap button at the bottom
	local snapButton = CreateFrame("Button", nil, WorkOrderEnchantsFrame)
	snapButton:SetSize(25, 25)                         -- Adjust size as needed
	snapButton:SetPoint("BOTTOM", snapBg, "BOTTOM", 1, 0) -- Adjust position as needed
	snapButton:SetText("<")
	local snapButtonText = snapButton:GetFontString()
	snapButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	snapButton:SetNormalFontObject("GameFontHighlight")
	snapButton:SetHighlightFontObject("GameFontNormal")
	snapButton:Hide()
	snapButton:SetScript("OnClick", function()
		RepositionEnchantsFrame(WorkOrderEnchantsFrame)
		snapBg:Hide()
		snapButton:Hide()
	end)

	WorkOrderEnchantsFrame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if not bgTexture:IsVisible() then
			snapBg:Hide()
			snapButton:Hide()
		else
			snapBg:Show()
			snapButton:Show()
		end
	end)

	WorkOrderEnchantsFrame:SetScript("OnShow", function()
		RepositionEnchantsFrame(WorkOrderEnchantsFrame)
	end)

	isConnected = false -- Variable to store connection status



	local resizeButton = CreateFrame("Button", nil, WorkOrderEnchantsFrame)
	resizeButton:SetSize(16, 16)
	resizeButton:SetPoint("BOTTOMRIGHT")
	resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

	resizeButton:SetScript("OnMouseDown", function(self, button)
		CheckIfConnected() -- Check and store the connection status
		WorkOrderEnchantsFrame:StartSizing("BOTTOMRIGHT")
		WorkOrderEnchantsFrame:SetUserPlaced(true)
	end)

	resizeButton:SetScript("OnMouseUp", function(self, button)
		WorkOrderEnchantsFrame:StopMovingOrSizing()
		if isConnected then
			RepositionEnchantsFrame(WorkOrderEnchantsFrame)
		end
	end)

	-- Create a close button background
	local closeBg = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(230, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOMLEFT", WorkOrderEnchantsFrame, "BOTTOMLEFT", 0, 0)
	closeBg:SetPoint("BOTTOMRIGHT", WorkOrderEnchantsFrame, "BOTTOMRIGHT", 0, 0)

	local cusreqButton = CreateFrame("Button", nil, WorkOrderEnchantsFrame)
	cusreqButton:SetSize(100, 25)                         -- Adjust size as needed
	--closeButton:SetFrameLevel(9001)
	cusreqButton:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 0) -- Adjust position as needed
	cusreqButton:SetText("Custom Request")
	local cusreqButtonText = cusreqButton:GetFontString()
	cusreqButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	cusreqButton:SetNormalFontObject("GameFontHighlight")
	cusreqButton:SetHighlightFontObject("GameFontNormal")
	cusreqButton:SetScript("OnClick", function()
		StaticPopup_Show("CUS_REQ_POPUP")
	end)

	local titleButton = CreateFrame("Button", nil, WorkOrderEnchantsFrame)
	titleButton:SetSize(60, 25)                          -- Adjust size as needed
	titleButton:SetPoint("BOTTOM", titleBg, "BOTTOM", 1, 0) -- Adjust position as needed
	titleButton:SetText("Enchants")
	local titleButtonText = titleButton:GetFontString()
	titleButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	titleButton:SetNormalFontObject("GameFontHighlight")
	titleButton:SetHighlightFontObject("GameFontNormal")
	local _, normHeight = WorkOrderEnchantsFrame:GetSize()
	titleButton:SetScript("OnClick", function()
		WorkOrderEnchantsFrame:Hide()
		ProEnchantersWorkOrderFrame.enchantsShowButton:Show()
	end)

	RepositionEnchantsFrame(WorkOrderEnchantsFrame)
	return WorkOrderEnchantsFrame
end

function ProEnchantersCreateOptionsFrame()
	local OptionsFrame = CreateFrame("Frame", "ProEnchantersOptionsFrame", UIParent, "BackdropTemplate")
	OptionsFrame:SetFrameStrata("FULLSCREEN")
	OptionsFrame:SetSize(800, 350) -- Adjust height as needed
	OptionsFrame:SetPoint("TOP", 0, -300)
	OptionsFrame:SetMovable(true)
	OptionsFrame:EnableMouse(true)
	OptionsFrame:RegisterForDrag("LeftButton")
	OptionsFrame:SetScript("OnDragStart", OptionsFrame.StartMoving)
	OptionsFrame:SetScript("OnDragStop", function()
		OptionsFrame:StopMovingOrSizing()
	end)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	OptionsFrame:SetBackdrop(backdrop)
	OptionsFrame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	OptionsFrame:Hide()

	-- Create a full background texture
	local bgTexture = OptionsFrame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(SettingsWindowBackgroundOpaque)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(800, 325)
	bgTexture:SetPoint("TOP", OptionsFrame, "TOP", 0, -25)

	-- Create a title background
	local titleBg = OptionsFrame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(800, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOP", OptionsFrame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader3 = OptionsFrame:CreateFontString(nil, "OVERLAY")
	titleHeader3:SetFontObject(UIFontBasic)
	titleHeader3:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader3:SetText("Pro Enchanters Settings")

	-- Scroll frame setup...
	local OptionsScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersOptionsScrollFrame", OptionsFrame,
		"UIPanelScrollFrameTemplate")
	OptionsScrollFrame:SetSize(775, 300)
	OptionsScrollFrame:SetPoint("TOP", titleBg, "BOTTOM", -12, 0)

	-- Create a scroll background
	local scrollBg = OptionsFrame:CreateTexture(nil, "ARTWORK")
	scrollBg:SetColorTexture(unpack(ButtonDisabled)) -- Set RGBA values for your preferred color and alpha
	scrollBg:SetSize(20, 300)                     -- Adjust size as needed
	scrollBg:SetPoint("TOPRIGHT", OptionsFrame, "TOPRIGHT", 0, -25)

	-- Access the Scroll Bar
	local scrollBar = OptionsScrollFrame.ScrollBar

	-- Customize Thumb Texture
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	thumbTexture:SetColorTexture(unpack(ButtonStandardAndThumb))
	--thumbTexture:SetAllPoints(thumbTexture)

	-- Customize Scroll Up Button Textures
	local upButton = scrollBar.ScrollUpButton

	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)

	-- Customize Scroll Up Button Textures with Solid Colors
	local upButton = scrollBar.ScrollUpButton

	-- Set colors
	upButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Replace RGBA values as needed
	upButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Replace RGBA values as needed
	upButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Replace RGBA values as needed
	upButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Replace RGBA values as needed

	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton

	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	-- Set colors
	downButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Adjust colors as needed
	downButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Adjust colors as needed
	downButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Adjust colors as needed
	downButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Adjust colors as needed

	local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	upButtonText:SetText("-")                              -- Set the text for the up button
	upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

	local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	downButtonText:SetText("-")                                -- Set the text for the down button
	downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed


	-- Scroll child frame where elements are actually placed
	local ScrollChild = CreateFrame("Frame")
	ScrollChild:SetSize(800, 300) -- Adjust height based on the number of elements
	OptionsScrollFrame:SetScrollChild(ScrollChild)

	-- Scroll child items below

	-- Create a header for Work While Closed
	local WorkWhileClosedHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	WorkWhileClosedHeader:SetFontObject(UIFontBasic)
	WorkWhileClosedHeader:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 30, -10)
	WorkWhileClosedHeader:SetText("Work while closed? (Auto invite, potential customer alerts, welcome msg's, etc)")

	-- Work While Closed Checkbox
	local WorkWhileClosedCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	WorkWhileClosedCb:SetPoint("LEFT", WorkWhileClosedHeader, "RIGHT", 10, 0)
	WorkWhileClosedCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	WorkWhileClosedCb:SetHitRectInsets(0, 0, 0, 0)
	WorkWhileClosedCb:SetChecked(ProEnchantersOptions["WorkWhileClosed"])
	WorkWhileClosedCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["WorkWhileClosed"] = self:GetChecked()
		WorkWhileClosed = ProEnchantersOptions["WorkWhileClosed"]
	end)
	-- Store the checkbox in the settings frame for later reference
	ProEnchantersSettingsFrame = ProEnchantersSettingsFrame or {}
	ProEnchantersSettingsFrame.WorkWhileClosedCheckbox = WorkWhileClosedCb

	-- Create a header for Work While Closed
	local EnableSoundsHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	EnableSoundsHeader:SetFontObject(UIFontBasic)
	EnableSoundsHeader:SetPoint("TOPLEFT", WorkWhileClosedHeader, "BOTTOMLEFT", 0, -10)
	EnableSoundsHeader:SetText("Enable custom sound for when players join your party? (Volume tied to 'Master' channel)")

	-- Work While Closed Checkbox
	local EnableSoundsCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	EnableSoundsCb:SetPoint("LEFT", EnableSoundsHeader, "RIGHT", 10, 0)
	EnableSoundsCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	EnableSoundsCb:SetHitRectInsets(0, 0, 0, 0)
	EnableSoundsCb:SetChecked(ProEnchantersOptions["EnableSounds"])
	EnableSoundsCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["EnableSounds"] = self:GetChecked()
	end)

	local soundsButtonBg = ScrollChild:CreateTexture(nil, "BACKGROUND")
	soundsButtonBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	soundsButtonBg:SetSize(150, 25)                            -- Adjust size as needed
	soundsButtonBg:SetPoint("TOPLEFT", EnableSoundsCb, "TOPRIGHT", 10, 2)

	-- Create a Trigger and Filters for invites button
	local soundsButton = CreateFrame("Button", nil, ScrollChild)
	soundsButton:SetSize(150, 25)                                -- Adjust size as needed
	soundsButton:SetPoint("CENTER", soundsButtonBg, "CENTER", 0, 0) -- Adjust position as needed
	soundsButton:SetText("Click here to set sounds")
	local soundsButtonText = soundsButton:GetFontString()
	soundsButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	soundsButton:SetNormalFontObject("GameFontHighlight")
	soundsButton:SetHighlightFontObject("GameFontNormal")
	soundsButton:SetScript("OnClick", function()
		ProEnchantersSoundsFrame:Show()
		OptionsFrame:Hide()
	end)

	-- Create a header for Channel Searches for Customers
	local AutoInviteAllChannelsHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	AutoInviteAllChannelsHeader:SetFontObject(UIFontBasic)
	AutoInviteAllChannelsHeader:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 40, -55)
	AutoInviteAllChannelsHeader:SetText(DARKORANGE .. "Channels to search for potential customers" .. ColorClose)

	-- Create a header for SAY/YELL
	local SayYellChannelsHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	SayYellChannelsHeader:SetFontObject(UIFontBasic)
	SayYellChannelsHeader:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 30, -70)
	SayYellChannelsHeader:SetText("Say and Yell")

	-- Create a header for Local City
	local LocalCityChannelHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	LocalCityChannelHeader:SetFontObject(UIFontBasic)
	LocalCityChannelHeader:SetPoint("LEFT", SayYellChannelsHeader, "RIGHT", 15, 0)
	LocalCityChannelHeader:SetText("Current City")

	-- Create a header for Trade - City
	local TradeChannelHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	TradeChannelHeader:SetFontObject(UIFontBasic)
	TradeChannelHeader:SetPoint("LEFT", LocalCityChannelHeader, "RIGHT", 15, 0)
	TradeChannelHeader:SetText("Trade Chat")

	-- Create a header for LookingForGroup
	local LFGChannelHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	LFGChannelHeader:SetFontObject(UIFontBasic)
	LFGChannelHeader:SetPoint("LEFT", TradeChannelHeader, "RIGHT", 15, 0)
	LFGChannelHeader:SetText("LFG Chat")

	-- Create a header for Local Defense
	local LocalDefenseChannelHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	LocalDefenseChannelHeader:SetFontObject(UIFontBasic)
	LocalDefenseChannelHeader:SetPoint("LEFT", LFGChannelHeader, "RIGHT", 15, 0)
	LocalDefenseChannelHeader:SetText("Local City Defense")

	-- Checkboxes
	local SayYellChannelCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	SayYellChannelCb:SetPoint("TOP", SayYellChannelsHeader, "TOP", 0, -15)
	SayYellChannelCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	SayYellChannelCb:SetHitRectInsets(0, 0, 0, 0)
	SayYellChannelCb:SetChecked(ProEnchantersOptions["AllChannels"]["SayYell"])
	SayYellChannelCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["AllChannels"]["SayYell"] = self:GetChecked()
	end)

	local LocalCityChannelCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	LocalCityChannelCb:SetPoint("TOP", LocalCityChannelHeader, "TOP", 0, -15)
	LocalCityChannelCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	LocalCityChannelCb:SetHitRectInsets(0, 0, 0, 0)
	LocalCityChannelCb:SetChecked(ProEnchantersOptions["AllChannels"]["LocalCity"])
	LocalCityChannelCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["AllChannels"]["LocalCity"] = self:GetChecked()
	end)

	local TradeChannelCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	TradeChannelCb:SetPoint("TOP", TradeChannelHeader, "TOP", 0, -15)
	TradeChannelCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	TradeChannelCb:SetHitRectInsets(0, 0, 0, 0)
	TradeChannelCb:SetChecked(ProEnchantersOptions["AllChannels"]["TradeChannel"])
	TradeChannelCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["AllChannels"]["TradeChannel"] = self:GetChecked()
	end)

	local LFGChannelCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	LFGChannelCb:SetPoint("TOP", LFGChannelHeader, "TOP", 0, -15)
	LFGChannelCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	LFGChannelCb:SetHitRectInsets(0, 0, 0, 0)
	LFGChannelCb:SetChecked(ProEnchantersOptions["AllChannels"]["LFGChannel"])
	LFGChannelCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["AllChannels"]["LFGChannel"] = self:GetChecked()
	end)

	local LocalDefenseChannelCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	LocalDefenseChannelCb:SetPoint("TOP", LocalDefenseChannelHeader, "TOP", 0, -15)
	LocalDefenseChannelCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	LocalDefenseChannelCb:SetHitRectInsets(0, 0, 0, 0)
	LocalDefenseChannelCb:SetChecked(ProEnchantersOptions["AllChannels"]["LocalDefense"])
	LocalDefenseChannelCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["AllChannels"]["LocalDefense"] = self:GetChecked()
	end)


	local maxPartySizeHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	maxPartySizeHeader:SetFontObject(UIFontBasic)
	maxPartySizeHeader:SetPoint("TOPLEFT", SayYellChannelsHeader, "TOPLEFT", 0, -50)
	maxPartySizeHeader:SetText("Party size limit to temporarily stop add-on invites?")

	local maxPartySizeEditBoxBg = ScrollChild:CreateTexture(nil, "OVERLAY")
	maxPartySizeEditBoxBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	maxPartySizeEditBoxBg:SetSize(35, 25)                                 -- Adjust size as needed
	maxPartySizeEditBoxBg:SetPoint("LEFT", maxPartySizeHeader, "RIGHT", 10, 0)

	local maxPartySizeEditBox = CreateFrame("EditBox", nil, ScrollChild)
	maxPartySizeEditBox:SetSize(35, 20)
	maxPartySizeEditBox:SetPoint("LEFT", maxPartySizeHeader, "RIGHT", 14, 0)
	maxPartySizeEditBox:SetAutoFocus(false)
	maxPartySizeEditBox:SetNumeric(true)
	maxPartySizeEditBox:SetMaxLetters(4)
	maxPartySizeEditBox:SetMultiLine(false)
	maxPartySizeEditBox:EnableMouse(true)
	maxPartySizeEditBox:EnableKeyboard(true)
	maxPartySizeEditBox:SetFontObject("GameFontHighlight")
	maxPartySizeEditBox:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	maxPartySizeEditBox:SetText(tostring(ProEnchantersOptions["MaxPartySize"]))
	maxPartySizeEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	maxPartySizeEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	maxPartySizeEditBox:SetScript("OnTextChanged", function()
		local newMaxSize = tonumber(maxPartySizeEditBox:GetText())
		if newMaxSize == nil then
			newMaxSize = 1
		elseif newMaxSize > 40 then
			newMaxSize = 40
		elseif newMaxSize < 0 then
			newMaxSize = 1
		end
		ProEnchantersOptions["MaxPartySize"] = newMaxSize
	end)

	local DelayInviteHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	DelayInviteHeader:SetFontObject(UIFontBasic)
	DelayInviteHeader:SetPoint("TOPLEFT", maxPartySizeHeader, "TOPLEFT", 0, -30)
	DelayInviteHeader:SetText(
		"Time delay before sending invites? (9.999 second max, enter in milliseconds, 1000 is 1 second)")

	local DelayInviteEditBoxBg = ScrollChild:CreateTexture(nil, "OVERLAY")
	DelayInviteEditBoxBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	DelayInviteEditBoxBg:SetSize(35, 25)                                 -- Adjust size as needed
	DelayInviteEditBoxBg:SetPoint("LEFT", DelayInviteHeader, "RIGHT", 10, 0)

	local DelayInviteEditBox = CreateFrame("EditBox", nil, ScrollChild)
	DelayInviteEditBox:SetSize(35, 20)
	DelayInviteEditBox:SetPoint("LEFT", DelayInviteHeader, "RIGHT", 14, 0)
	DelayInviteEditBox:SetAutoFocus(false)
	DelayInviteEditBox:SetNumeric(true)
	DelayInviteEditBox:SetMaxLetters(4)
	DelayInviteEditBox:SetMultiLine(false)
	DelayInviteEditBox:EnableMouse(true)
	DelayInviteEditBox:EnableKeyboard(true)
	DelayInviteEditBox:SetFontObject("GameFontHighlight")
	DelayInviteEditBox:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	DelayInviteEditBox:SetText(tostring(ProEnchantersOptions["DelayInviteTime"] * 1000))
	DelayInviteEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	DelayInviteEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	DelayInviteEditBox:SetScript("OnTextChanged", function()
		local newTime = tonumber(DelayInviteEditBox:GetText())
		if newTime == nil then
			newTime = 0
		elseif newTime > 9999 then
			newTime = 9999
		elseif newTime < 0 then
			newTime = 0
		end
		local convertednewTime = newTime / 1000
		ProEnchantersOptions["DelayInviteTime"] = convertednewTime
	end)

	local DelayInviteMsgHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	DelayInviteMsgHeader:SetFontObject(UIFontBasic)
	DelayInviteMsgHeader:SetPoint("TOPLEFT", DelayInviteHeader, "TOPLEFT", 0, -30)
	DelayInviteMsgHeader:SetText("Delay AFTER invite sent before a follow up message is sent?")

	local DelayInviteMsgEditBoxBg = ScrollChild:CreateTexture(nil, "OVERLAY")
	DelayInviteMsgEditBoxBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	DelayInviteMsgEditBoxBg:SetSize(35, 25)                                 -- Adjust size as needed
	DelayInviteMsgEditBoxBg:SetPoint("LEFT", DelayInviteMsgHeader, "RIGHT", 10, 0)

	local DelayInviteMsgEditBox = CreateFrame("EditBox", nil, ScrollChild)
	DelayInviteMsgEditBox:SetSize(35, 20)
	DelayInviteMsgEditBox:SetPoint("LEFT", DelayInviteMsgHeader, "RIGHT", 14, 0)
	DelayInviteMsgEditBox:SetAutoFocus(false)
	DelayInviteMsgEditBox:SetNumeric(true)
	DelayInviteMsgEditBox:SetMaxLetters(4)
	DelayInviteMsgEditBox:SetMultiLine(false)
	DelayInviteMsgEditBox:EnableMouse(true)
	DelayInviteMsgEditBox:EnableKeyboard(true)
	DelayInviteMsgEditBox:SetFontObject("GameFontHighlight")
	DelayInviteMsgEditBox:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	DelayInviteMsgEditBox:SetText(tostring(ProEnchantersOptions["DelayInviteMsgTime"] * 1000))
	DelayInviteMsgEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	DelayInviteMsgEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	DelayInviteMsgEditBox:SetScript("OnTextChanged", function()
		local newTime = tonumber(DelayInviteMsgEditBox:GetText())
		if newTime == nil then
			newTime = 0
		elseif newTime > 9999 then
			newTime = 9999
		elseif newTime < 0 then
			newTime = 0
		end
		local convertednewTime = newTime / 1000
		ProEnchantersOptions["DelayInviteMsgTime"] = convertednewTime
	end)

	-- Create a header for AutoInviteAllChannels
	local DelayWorkOrderHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	DelayWorkOrderHeader:SetFontObject(UIFontBasic)
	DelayWorkOrderHeader:SetPoint("TOPLEFT", DelayInviteMsgHeader, "TOPLEFT", 0, -30)
	DelayWorkOrderHeader:SetText("Delay work order creation on non-addon invited players?")

	-- Auto Invite Checkbox
	local DelayWorkOrderCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	DelayWorkOrderCb:SetPoint("LEFT", DelayWorkOrderHeader, "RIGHT", 10, 0)
	DelayWorkOrderCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	DelayWorkOrderCb:SetHitRectInsets(0, 0, 0, 0)
	DelayWorkOrderCb:SetChecked(ProEnchantersOptions["DelayWorkorder"])
	DelayWorkOrderCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["DelayWorkOrder"] = self:GetChecked()
	end)

	-- Create a header for AutoInviteAllChannels
	local WhisperMatsHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	WhisperMatsHeader:SetFontObject(UIFontBasic)
	WhisperMatsHeader:SetPoint("TOPLEFT", DelayWorkOrderHeader, "TOPLEFT", 0, -30)
	WhisperMatsHeader:SetText("Always whisper the players mats and requested enchants instead of party chat?")

	-- Auto Invite Checkbox
	local WhisperMatsCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	WhisperMatsCb:SetPoint("LEFT", WhisperMatsHeader, "RIGHT", 10, 0)
	WhisperMatsCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	WhisperMatsCb:SetHitRectInsets(0, 0, 0, 0)
	WhisperMatsCb:SetChecked(ProEnchantersOptions["WhisperMats"])
	WhisperMatsCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["WhisperMats"] = self:GetChecked()
	end)

	local filtersButtonBg = ScrollChild:CreateTexture(nil, "BACKGROUND")
	filtersButtonBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	filtersButtonBg:SetSize(270, 24)                            -- Adjust size as needed
	filtersButtonBg:SetPoint("TOPLEFT", WhisperMatsHeader, "TOPLEFT", -4, -25)

	-- Create a Trigger and Filters for invites button
	local filtersButton2 = CreateFrame("Button", nil, ScrollChild)
	filtersButton2:SetSize(270, 25)                                 -- Adjust size as needed
	filtersButton2:SetPoint("CENTER", filtersButtonBg, "CENTER", 0, 0) -- Adjust position as needed
	filtersButton2:SetText("Click here to set triggered words and filtered words")
	local filtersButtonText2 = filtersButton2:GetFontString()
	filtersButtonText2:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	filtersButton2:SetNormalFontObject("GameFontHighlight")
	filtersButton2:SetHighlightFontObject("GameFontNormal")
	filtersButton2:SetScript("OnClick", function()
		ProEnchantersTriggersFrame:Show()
		OptionsFrame:Hide()
	end)

	local whisperTriggersBg = ScrollChild:CreateTexture(nil, "BACKGROUND")
	whisperTriggersBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	whisperTriggersBg:SetSize(250, 24)                            -- Adjust size as needed
	whisperTriggersBg:SetPoint("TOPLEFT", filtersButtonBg, "TOPRIGHT", 15, 0)

	-- Create a Trigger and Filters for invites button
	local whisperTriggersButton = CreateFrame("Button", nil, ScrollChild)
	whisperTriggersButton:SetSize(250, 25)                                   -- Adjust size as needed
	whisperTriggersButton:SetPoint("CENTER", whisperTriggersBg, "CENTER", 0, 0) -- Adjust position as needed
	whisperTriggersButton:SetText("Click here to set custom whisper !commands")
	local whisperTriggersButtonText = whisperTriggersButton:GetFontString()
	whisperTriggersButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	whisperTriggersButton:SetNormalFontObject("GameFontHighlight")
	whisperTriggersButton:SetHighlightFontObject("GameFontNormal")
	whisperTriggersButton:SetScript("OnClick", function()
		ProEnchantersWhisperTriggersFrame:Show()
		OptionsFrame:Hide()
	end)

	-- Create a header for Disable !commands
	local DisableWhisperCommandsHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	DisableWhisperCommandsHeader:SetFontObject(UIFontBasic)
	DisableWhisperCommandsHeader:SetPoint("TOPLEFT", filtersButtonBg, "BOTTOMLEFT", 4, -10)
	DisableWhisperCommandsHeader:SetText("Disable whisper !commands? (Stops any commands that start with a !)")

	-- Auto Invite Checkbox
	local DisableWhisperCommandsCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	DisableWhisperCommandsCb:SetPoint("LEFT", DisableWhisperCommandsHeader, "RIGHT", 10, 0)
	DisableWhisperCommandsCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	DisableWhisperCommandsCb:SetHitRectInsets(0, 0, 0, 0)
	DisableWhisperCommandsCb:SetChecked(ProEnchantersOptions["DisableWhisperCommands"])
	DisableWhisperCommandsCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["DisableWhisperCommands"] = self:GetChecked()
	end)



	-- Create a header for AutoInv Msg
	local AutoInviteMsgEditBoxHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	AutoInviteMsgEditBoxHeader:SetFontObject(UIFontBasic)
	AutoInviteMsgEditBoxHeader:SetPoint("TOPLEFT", DisableWhisperCommandsHeader, "TOPLEFT", 0, -30)
	AutoInviteMsgEditBoxHeader:SetText("Auto Invite Msg:")

	-- Create an EditBox for AutoInv Msg
	local AutoInviteMsgEditBox = CreateFrame("EditBox", "ProEnchantersAutoInviteMsgEditBox", ScrollChild,
		"InputBoxTemplate")
	AutoInviteMsgEditBox:SetSize(600, 20)
	AutoInviteMsgEditBox:SetPoint("TOPLEFT", AutoInviteMsgEditBoxHeader, "TOPRIGHT", 30, 5)
	AutoInviteMsgEditBox:SetAutoFocus(false)
	AutoInviteMsgEditBox:SetFontObject("GameFontHighlight")
	AutoInviteMsgEditBox:SetText("")
	AutoInviteMsgEditBox:SetScript("OnTextChanged", function()
		local newAutoInvMsg = AutoInviteMsgEditBox:GetText()
		ProEnchantersOptions["AutoInviteMsg"] = newAutoInvMsg
		AutoInviteMsg = newAutoInvMsg
	end)
	AutoInviteMsgEditBox:SetScript("OnEnterPressed", function()
		AutoInviteMsgEditBox:ClearFocus()
	end)

	-- Create a header for Failed Inv Msg
	local FailInviteMsgEditBoxHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	FailInviteMsgEditBoxHeader:SetFontObject(UIFontBasic)
	FailInviteMsgEditBoxHeader:SetPoint("TOPLEFT", AutoInviteMsgEditBoxHeader, "TOPLEFT", 0, -30)
	FailInviteMsgEditBoxHeader:SetText("Failed Invite Msg:")

	-- Create an EditBox for Failed Inv Msg
	local FailInviteMsgEditBox = CreateFrame("EditBox", "ProEnchantersAutoInviteMsgEditBox", ScrollChild,
		"InputBoxTemplate")
	FailInviteMsgEditBox:SetSize(600, 20)
	FailInviteMsgEditBox:SetPoint("TOP", AutoInviteMsgEditBox, "TOP", 0, -30)
	FailInviteMsgEditBox:SetAutoFocus(false)
	FailInviteMsgEditBox:SetFontObject("GameFontHighlight")
	FailInviteMsgEditBox:SetText("")
	FailInviteMsgEditBox:SetScript("OnTextChanged", function()
		local newFailInvMsg = FailInviteMsgEditBox:GetText()
		ProEnchantersOptions["FailInvMsg"] = newFailInvMsg
		FailInvMsg = newFailInvMsg
	end)
	FailInviteMsgEditBox:SetScript("OnEnterPressed", function()
		FailInviteMsgEditBox:ClearFocus()
	end)

	-- Create a header for Full Inv Msg
	local FullInviteMsgEditBoxHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	FullInviteMsgEditBoxHeader:SetFontObject(UIFontBasic)
	FullInviteMsgEditBoxHeader:SetPoint("TOPLEFT", FailInviteMsgEditBoxHeader, "TOPLEFT", 0, -30)
	FullInviteMsgEditBoxHeader:SetText("Full Group Inv Msg:")

	-- Create an EditBox for Full Inv Msg
	local FullInviteMsgEditBox = CreateFrame("EditBox", "ProEnchantersAutoInviteMsgEditBox", ScrollChild,
		"InputBoxTemplate")
	FullInviteMsgEditBox:SetSize(600, 20)
	FullInviteMsgEditBox:SetPoint("TOP", FailInviteMsgEditBox, "TOP", 0, -30)
	FullInviteMsgEditBox:SetAutoFocus(false)
	FullInviteMsgEditBox:SetFontObject("GameFontHighlight")
	FullInviteMsgEditBox:SetText("")
	FullInviteMsgEditBox:SetScript("OnTextChanged", function()
		local newFullInvMsg = FullInviteMsgEditBox:GetText()
		ProEnchantersOptions["FullInvMsg"] = newFullInvMsg
		FullInvMsg = newFullInvMsg
	end)
	FullInviteMsgEditBox:SetScript("OnEnterPressed", function()
		FullInviteMsgEditBox:ClearFocus()
	end)

	-- Create a header for Welcome Msg
	local WelcomeMsgEditBoxHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	WelcomeMsgEditBoxHeader:SetFontObject(UIFontBasic)
	WelcomeMsgEditBoxHeader:SetPoint("TOPLEFT", FullInviteMsgEditBoxHeader, "TOPLEFT", 0, -30)
	WelcomeMsgEditBoxHeader:SetText("Party Welcome Msg:")

	-- Create an EditBox for Welcome Msg
	local WelcomeMsgEditBox = CreateFrame("EditBox", "ProEnchantersWelcomeMsgEditBox", ScrollChild, "InputBoxTemplate")
	WelcomeMsgEditBox:SetSize(600, 20)
	WelcomeMsgEditBox:SetPoint("TOP", FullInviteMsgEditBox, "TOP", 0, -30)
	WelcomeMsgEditBox:SetAutoFocus(false)
	WelcomeMsgEditBox:SetFontObject("GameFontHighlight")
	WelcomeMsgEditBox:SetText("")
	WelcomeMsgEditBox:SetScript("OnTextChanged", function()
		local newWelcomeMsg = WelcomeMsgEditBox:GetText()
		ProEnchantersOptions["WelcomeMsg"] = newWelcomeMsg
		WelcomeMsg = newWelcomeMsg
	end)
	WelcomeMsgEditBox:SetScript("OnEnterPressed", function()
		WelcomeMsgEditBox:ClearFocus()
	end)

	-- Create a header for Trade msg
	local TradeMsgEditBoxHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	TradeMsgEditBoxHeader:SetFontObject(UIFontBasic)
	TradeMsgEditBoxHeader:SetPoint("TOPLEFT", WelcomeMsgEditBoxHeader, "TOPLEFT", 0, -30)
	TradeMsgEditBoxHeader:SetText("Trade Started Msg:")

	-- Create an EditBox for Trade msg
	local TradeMsgEditBox = CreateFrame("EditBox", "ProEnchantersTradeMsgEditBox", ScrollChild, "InputBoxTemplate")
	TradeMsgEditBox:SetSize(600, 20)
	TradeMsgEditBox:SetPoint("TOP", WelcomeMsgEditBox, "TOP", 0, -30)
	TradeMsgEditBox:SetAutoFocus(false)
	TradeMsgEditBox:SetFontObject("GameFontHighlight")
	TradeMsgEditBox:SetText("")
	TradeMsgEditBox:SetScript("OnTextChanged", function()
		local newtradeMsg = TradeMsgEditBox:GetText()
		ProEnchantersOptions["TradeMsg"] = newtradeMsg
	end)
	TradeMsgEditBox:SetScript("OnEnterPressed", function()
		TradeMsgEditBox:ClearFocus()
	end)

	-- Create a header for Tip Msg
	local TipMsgEditBoxHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	TipMsgEditBoxHeader:SetFontObject(UIFontBasic)
	TipMsgEditBoxHeader:SetPoint("TOPLEFT", TradeMsgEditBoxHeader, "TOPLEFT", 0, -30)
	TipMsgEditBoxHeader:SetText("Tip Received Msg:")

	-- Create an EditBox for Tip Msg
	local TipMsgEditBox = CreateFrame("EditBox", "ProEnchantersTipMsgEditBox", ScrollChild, "InputBoxTemplate")
	TipMsgEditBox:SetSize(600, 20)
	TipMsgEditBox:SetPoint("TOP", TradeMsgEditBox, "TOP", 0, -30)
	TipMsgEditBox:SetAutoFocus(false)
	TipMsgEditBox:SetFontObject("GameFontHighlight")
	TipMsgEditBox:SetText("")
	TipMsgEditBox:SetScript("OnTextChanged", function()
		local newTipMsg = TipMsgEditBox:GetText()
		ProEnchantersOptions["TipMsg"] = newTipMsg
		TipMsg = newTipMsg
	end)
	TipMsgEditBox:SetScript("OnEnterPressed", function()
		TipMsgEditBox:ClearFocus()
	end)

	-- Create a header for Tip Msg
	local TipResponsesHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	TipResponsesHeader:SetFontObject(UIFontBasic)
	TipResponsesHeader:SetPoint("TOPLEFT", TipMsgEditBoxHeader, "TOPLEFT", 0, -30)
	TipResponsesHeader:SetText("Tip Emote:\n(Blank to Disable)")

	-- Create an EditBox for Tip Msg
	local TipResponseEditBox = CreateFrame("EditBox", "ProEnchantersTipResponseEditBox", ScrollChild, "InputBoxTemplate")
	TipResponseEditBox:SetSize(120, 20)
	TipResponseEditBox:SetPoint("TOPLEFT", TipMsgEditBox, "TOPLEFT", 0, -30)
	TipResponseEditBox:SetAutoFocus(false)
	TipResponseEditBox:SetFontObject("GameFontHighlight")
	TipResponseEditBox:SetText(ProEnchantersOptions["TipEmote"])
	TipResponseEditBox:SetScript("OnTextChanged", function()
		local newEmote = TipResponseEditBox:GetText()
		ProEnchantersOptions["TipEmote"] = newEmote
	end)
	TipResponseEditBox:SetScript("OnEnterPressed", function()
		TipResponseEditBox:ClearFocus()
	end)

	-- Create a header for Tip Msg
	local RaidIconHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	RaidIconHeader:SetFontObject(UIFontBasic)
	RaidIconHeader:SetPoint("TOPLEFT", TipResponsesHeader, "TOPLEFT", 0, -45)
	RaidIconHeader:SetText("Auto Raid Icon:")

	local defaultVal = "None"
	if ProEnchantersOptions["RaidIcon"] == 0 then
		defaultVal = "None"
	elseif ProEnchantersOptions["RaidIcon"] == 1 then
		defaultVal = "Star"
	elseif ProEnchantersOptions["RaidIcon"] == 2 then
		defaultVal = "Circle"
	elseif ProEnchantersOptions["RaidIcon"] == 3 then
		defaultVal = "Diamond"
	elseif ProEnchantersOptions["RaidIcon"] == 4 then
		defaultVal = "Triangle"
	elseif ProEnchantersOptions["RaidIcon"] == 5 then
		defaultVal = "Moon"
	elseif ProEnchantersOptions["RaidIcon"] == 6 then
		defaultVal = "Square"
	elseif ProEnchantersOptions["RaidIcon"] == 7 then
		defaultVal = "Cross"
	elseif ProEnchantersOptions["RaidIcon"] == 8 then
		defaultVal = "Skull"
	end

	local raidicon_opts = {
		['name'] = 'raidicon',
		['parent'] = ScrollChild,
		['title'] = '',
		['items'] = { "None", "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull" },
		['defaultVal'] = defaultVal,
		['changeFunc'] = function(dropdown_frame, dropdown_val)
			local seticon = 0
			if dropdown_val == "None" then
				seticon = 0
			elseif dropdown_val == "Star" then
				seticon = 1
			elseif dropdown_val == "Circle" then
				seticon = 2
			elseif dropdown_val == "Diamond" then
				seticon = 3
			elseif dropdown_val == "Triangle" then
				seticon = 4
			elseif dropdown_val == "Moon" then
				seticon = 5
			elseif dropdown_val == "Square" then
				seticon = 6
			elseif dropdown_val == "Cross" then
				seticon = 7
			elseif dropdown_val == "Skull" then
				seticon = 8
			end
			ProEnchantersOptions["RaidIcon"] = seticon
		end
	}

	local RaidIconDD = createDropdown(raidicon_opts)
	-- Don't forget to set your dropdown's points, we don't do this in the creation method for simplicities sake.
	RaidIconDD:SetPoint("LEFT", RaidIconHeader, "RIGHT", 3, 0)


	-- Create checkboxes for every available enchant to hard filter them out from being available
	-- Create a header for enchant filter
	local enchantFilterHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	enchantFilterHeader:SetFontObject(UIFontBasic)
	enchantFilterHeader:SetPoint("TOPLEFT", RaidIconHeader, "TOPLEFT", 30, -30)
	enchantFilterHeader:SetText(DARKORANGE ..
		"Filter the below enchants by unchecking them to stop them from displaying in other parts of the add-on" ..
		ColorClose)

	local enchantToggleYoffset = 60

	local function alphanumericSort(a, b)
		-- Extract number from the string
		local numA = tonumber(a:match("%d+"))
		local numB = tonumber(b:match("%d+"))

		if numA and numB then -- If both strings have numbers, then compare numerically
			return numA < numB
		else
			return a < b -- If one or both strings don't have numbers, sort lexicographically
		end
	end

	local keys = {}
	for k in pairs(EnchantsName) do
		table.insert(keys, k)
	end
	table.sort(keys, alphanumericSort) -- Sorts the keys in natural alphanumeric order

	for _, sortedKey in ipairs(keys) do
		local key = sortedKey
		local enchantName = CombinedEnchants[sortedKey].name
		local enchantStats = CombinedEnchants[sortedKey].stats
		-- Create a header for enchant filter
		local enchantFilterName = ScrollChild:CreateFontString(nil, "OVERLAY")
		enchantFilterName:SetFontObject(UIFontBasic)
		enchantFilterName:SetPoint("TOPLEFT", RaidIconHeader, "TOPLEFT", 0, -enchantToggleYoffset)
		enchantFilterName:SetText(enchantName .. enchantStats)

		-- Create a checkbox for enchant filter
		local enchantFilterCb = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
		enchantFilterCb:SetPoint("LEFT", enchantFilterName, "RIGHT", 10, 0)
		enchantFilterCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
		enchantFilterCb:SetHitRectInsets(0, 0, 0, 0)
		enchantFilterCb:SetChecked(ProEnchantersOptions.filters[key])
		enchantFilterCb:SetScript("OnClick", function(self)
			ProEnchantersOptions.filters[key] = self:GetChecked()
			local enchantButton = enchantButtons[key]
			if ProEnchantersOptions.filters[key] == false then
				enchantButton.button:Hide()
				enchantButton.background:Hide()
				FilterEnchantButtons()
			else
				enchantButton.button:Show()
				enchantButton.background:Show()
				FilterEnchantButtons()
			end
		end)
		enchantFilterCheckboxes[key] = enchantFilterCb
		enchantToggleYoffset = enchantToggleYoffset + 30
	end


	-- Create a close button background
	local closeBg = OptionsFrame:CreateTexture(nil, "OVERLAY")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(800, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOMLEFT", OptionsFrame, "BOTTOMLEFT", 0, 0)


	-- Create a reset button at the bottom
	local resetButton = CreateFrame("Button", nil, OptionsFrame)
	resetButton:SetSize(80, 25)                                      -- Adjust size as needed
	resetButton:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0) -- Adjust position as needed
	resetButton:SetText("Reset Msgs")
	local resetButtonText = resetButton:GetFontString()
	resetButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	resetButton:SetNormalFontObject("GameFontHighlight")
	resetButton:SetHighlightFontObject("GameFontNormal")
	resetButton:SetScript("OnClick", function()
		local AutoInvMsg = "Enchanter here! Let me know what you need, sending an invite now :)"
		local WelcomeMsg = "Hello there CUSTOMER o/, let me know what you need and feel free to trade when ready!"
		local TipMsg = "Thanks for the MONEY tip CUSTOMER <3"
		local TradeMsg = "Now trading with CUSTOMER"
		local FailInvMsg = "Enchanter here! Let me know what you need :)"
		local FullInvMsg = "Hey CUSTOMER, my group seems to be full at the moment, I'll invite you once I am able to :)"
		FailInviteMsgEditBox:SetText(FailInvMsg)
		FullInviteMsgEditBox:SetText(FullInvMsg)
		AutoInviteMsgEditBox:SetText(AutoInvMsg)
		WelcomeMsgEditBox:SetText(WelcomeMsg)
		TipMsgEditBox:SetText(TipMsg)
		TradeMsgEditBox:SetText(TradeMsg)
	end)

	-- Create a sync skills button at the bottom
	local syncButton = CreateFrame("Button", nil, OptionsFrame)
	syncButton:SetSize(80, 25)                             -- Adjust size as needed
	syncButton:SetPoint("RIGHT", resetButton, "LEFT", -10, 0) -- Adjust position as needed
	syncButton:SetText("Sync Recipes")
	local syncButtonText = syncButton:GetFontString()
	syncButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	syncButton:SetNormalFontObject("GameFontHighlight")
	syncButton:SetHighlightFontObject("GameFontNormal")
	syncButton:SetScript("OnClick", function()
		if CraftFrame and CraftFrame:IsVisible() then
			local name, _, _ = IsCurrentTradeSkillEnchanting()
			if LocalLanguage == nil then
				LocalLanguage = "English"
			end
			local localEnchantingName = PEenchantingLocales["Enchanting"][LocalLanguage]
			if name == localEnchantingName then
				-- Assume all enchantments are not available initially
				for enchKey, _ in pairs(EnchantsName) do
					ProEnchantersOptions.filters[enchKey] = false
					local enchantButton = enchantButtons[enchKey]
					if enchantButton then
						enchantButton.button:Hide()
						enchantButton.background:Hide()
						FilterEnchantButtons()
					end
				end

				local count = GetNumCrafts()
				for i = 1, count do
					local skillName = GetCraftInfo(i)
					local enchantCheck = PEenchantingLocales["EnchantSearch"][LocalLanguage]
					if string.find(skillName, enchantCheck, 1, true) then
						for enchKey, _ in pairs(EnchantsName) do
							local enchValue = PEenchantingLocales["Enchants"][enchKey][LocalLanguage]
							if enchValue == skillName then
								print(enchValue .. " found, setting to true")
								ProEnchantersOptions.filters[enchKey] = true
								local enchantButton = enchantButtons[enchKey]
								if enchantButton then
									enchantButton.button:Show()
									enchantButton.background:Show()
									FilterEnchantButtons()
								end
								break -- Stop checking once a match is found
							end
						end
					end
				end

				-- Print out enchantments that are set to false (not found)
				for enchKey, isVisible in pairs(ProEnchantersOptions.filters) do
					if not isVisible then
						local enchValue = PEenchantingLocales["Enchants"][enchKey][LocalLanguage]
						print(enchValue .. " not found, set to false")
					end
				end
			else
				print(RED .. "Enchanting Trade Skill Window needs to be open to sync to skill list." .. ColorClose)
			end
		else
			print(RED .. "Enchanting Trade Skill Window needs to be open to sync to skill list." .. ColorClose)
		end
		UpdateCheckboxesBasedOnFilters()
	end)

	local closeButton = CreateFrame("Button", nil, OptionsFrame)
	closeButton:SetSize(50, 25)                                   -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0) -- Adjust position as needed
	closeButton:SetText("Close")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")
	closeButton:SetScript("OnClick", function()
		OptionsFrame:Hide()
	end)

	local creditsButton = CreateFrame("Button", nil, OptionsFrame)
	creditsButton:SetSize(60, 25)                            -- Adjust size as needed
	creditsButton:SetPoint("LEFT", closeButton, "RIGHT", 10, 0) -- Adjust position as needed
	creditsButton:SetText("Credits")
	local creditsButtonText = creditsButton:GetFontString()
	creditsButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	creditsButton:SetNormalFontObject("GameFontHighlight")
	creditsButton:SetHighlightFontObject("GameFontNormal")
	creditsButton:SetScript("OnClick", function()
		ProEnchantersCreditsFrame:Show()
	end)

	local colorsButton = CreateFrame("Button", nil, OptionsFrame)
	colorsButton:SetSize(60, 25)                              -- Adjust size as needed
	colorsButton:SetPoint("LEFT", creditsButton, "RIGHT", 10, 0) -- Adjust position as needed
	colorsButton:SetText("Colors")
	local colorsButtonText = colorsButton:GetFontString()
	colorsButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	colorsButton:SetNormalFontObject("GameFontHighlight")
	colorsButton:SetHighlightFontObject("GameFontNormal")
	colorsButton:SetScript("OnClick", function()
		ProEnchantersColorsFrame:Show()
	end)

	-- Help Reminder
	local helpReminderHeader = OptionsFrame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject("GameFontGreen")
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 5)
	helpReminderHeader:SetText(STEELBLUE .. "Use /pehelp for more info" .. ColorClose)
	helpReminderHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	-- OptionsFrame On Show Script
	OptionsFrame:SetScript("OnShow", function()
		local AutoInvMsg = ProEnchantersOptions["AutoInviteMsg"]
		local welcomeMsg = ProEnchantersOptions["WelcomeMsg"]
		local tipMsg = ProEnchantersOptions["TipMsg"]
		local tradeMsg = ProEnchantersOptions["TradeMsg"]
		local failMsg = ProEnchantersOptions["FailInvMsg"]
		local fullMsg = ProEnchantersOptions["FullInvMsg"]
		FailInviteMsgEditBox:SetText(failMsg)
		FullInviteMsgEditBox:SetText(fullMsg)
		AutoInviteMsgEditBox:SetText(AutoInvMsg)
		WelcomeMsgEditBox:SetText(welcomeMsg)
		TipMsgEditBox:SetText(tipMsg)
		TradeMsgEditBox:SetText(tradeMsg)
		AutoInviteMsg = AutoInvMsg
		WelcomeMsg = welcomeMsg
		TipMsg = tipMsg
		TradeMsg = tradeMsg
		FailInvMsg = failMsg
		FullInvMsg = fullMsg
		ProEnchantersTriggersFrame:Hide()
		ProEnchantersWhisperTriggersFrame:Hide()
		ProEnchantersImportFrame:Hide()
	end)

	return OptionsFrame
end

function ProEnchantersCreateCreditsFrame()
	local CreditsFrame = CreateFrame("Frame", "ProEnchantersCreditsFrame", UIParent, "BackdropTemplate")
	CreditsFrame:SetFrameStrata("TOOLTIP")
	CreditsFrame:SetSize(400, 400) -- Adjust height as needed
	CreditsFrame:SetPoint("TOP", 0, -300)
	CreditsFrame:SetMovable(true)
	CreditsFrame:EnableMouse(true)
	CreditsFrame:RegisterForDrag("LeftButton")
	CreditsFrame:SetScript("OnDragStart", CreditsFrame.StartMoving)
	CreditsFrame:SetScript("OnDragStop", function()
		CreditsFrame:StopMovingOrSizing()
	end)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	CreditsFrame:SetBackdrop(backdrop)
	CreditsFrame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	CreditsFrame:Hide()

	-- Create a full background texture
	local bgTexture = CreditsFrame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(SettingsWindowBackgroundOpaque)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(400, 375)
	bgTexture:SetPoint("TOP", CreditsFrame, "TOP", 0, -25)

	-- Create a title background
	local titleBg = CreditsFrame:CreateTexture(nil, "OVERLAY")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(400, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOP", CreditsFrame, "TOP", 0, 0)

	local PFP = CreditsFrame:CreateTexture(nil, "OVERLAY")
	--PFP:SetColorTexture(unpack(TopBarColorOpaque))  -- Set RGBA values for your preferred color and alpha
	PFP:SetTexture("Interface\\AddOns\\ProEnchanters\\Media\\PFP.tga")
	PFP:SetSize(128, 128) -- Adjust size as needed
	PFP:SetPoint("TOP", titleBg, "BOTTOM", 0, -5)

	-- Create a title for Options
	local titleHeader = CreditsFrame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject(UIFontBasic)
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Credits")

	local MainCreditsHeader = CreditsFrame:CreateFontString(nil, "OVERLAY")
	MainCreditsHeader:SetFontObject("GameFontHighlight")
	MainCreditsHeader:SetPoint("TOP", PFP, "BOTTOM", 0, -10)
	MainCreditsHeader:SetText("Pro Enchanters add-on created by" ..
		STEELBLUE .. " EffinOwen" .. ColorClose .. ".\nCome say Hello on discord!")
	MainCreditsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local discordButton = CreateFrame("Button", nil, CreditsFrame)
	discordButton:SetSize(150, 25)                                 -- Adjust size as needed
	discordButton:SetPoint("TOP", MainCreditsHeader, "BOTTOM", 0, -2) -- Adjust position as needed
	discordButton:SetText("https://discord.gg/qT6bRk4eUa")
	local discordButtonText = discordButton:GetFontString()
	discordButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	discordButton:SetNormalFontObject("GameFontHighlight")
	discordButton:SetHighlightFontObject("GameFontNormal")
	discordButton:SetScript("OnClick", function()
		ChatFrame1EditBox:Show()
		ChatFrame1EditBox:SetFocus()
		print(SEAGREEN ..
			"Highlight and hit control+C to copy the discord link and then paste it into any web browser" .. ColorClose)
		ChatFrame1EditBox:SetText("https://discord.gg/qT6bRk4eUa")
	end)

	local SupportersHeader = CreditsFrame:CreateFontString(nil, "OVERLAY")
	SupportersHeader:SetFontObject("GameFontHighlight")
	SupportersHeader:SetPoint("TOP", discordButton, "BOTTOM", 0, -10)
	SupportersHeader:SetText(SEAGREEN ..
		"~" .. ColorClose .. DARKGOLDENROD .. " Supporters " .. ColorClose .. SEAGREEN .. "~" .. ColorClose)
	SupportersHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 4, "")

	-- Create a close button background
	local CreditsScrollBg = CreditsFrame:CreateTexture(nil, "OVERLAY")
	CreditsScrollBg:SetSize(380, 110)
	CreditsScrollBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	CreditsScrollBg:SetPoint("TOP", SupportersHeader, "TOP", 0, -25)

	local CreditsScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersCreditsScrollFrame", CreditsFrame,
		"UIPanelScrollFrameTemplate")
	CreditsScrollFrame:SetSize(372, 102)
	CreditsScrollFrame:SetPoint("TOPLEFT", CreditsScrollBg, "TOPLEFT", 4, -4)

	local scrollChild = CreateFrame("Frame", nil, CreditsScrollFrame)
	scrollChild:SetSize(372, 102) -- Adjust height dynamically based on content
	CreditsScrollFrame:SetScrollChild(scrollChild)

	local scrollBar = CreditsScrollFrame.ScrollBar
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	--thumbTexture:SetColorTexture(0.3, 0.1, 0.4, 0.8)
	local upButton = scrollBar.ScrollUpButton
	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)
	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton
	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	-- Create an EditBox for Filtered Words
	local SupportersEditBox = CreateFrame("EditBox", "ProEnchantersSupportersEditBox", scrollChild)
	SupportersEditBox:SetSize(372, 20)
	SupportersEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
	SupportersEditBox:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMRIGHT", 0, 0)
	SupportersEditBox:SetAutoFocus(false)
	SupportersEditBox:SetMultiLine(true)
	SupportersEditBox:EnableMouse(false)
	SupportersEditBox:EnableKeyboard(false)
	SupportersEditBox:SetFontObject("GameFontHighlight")
	SupportersEditBox:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 4, "")
	SupportersEditBox:SetText(SetSupportersEditBox())



	-- Create a close button background
	local closeBg = CreditsFrame:CreateTexture(nil, "OVERLAY")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(400, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOM", CreditsFrame, "BOTTOM", 0, 0)

	local closeButton = CreateFrame("Button", nil, CreditsFrame)
	closeButton:SetSize(50, 25)                                   -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0) -- Adjust position as needed
	closeButton:SetText("Close")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")
	closeButton:SetScript("OnClick", function()
		CreditsFrame:Hide()
	end)

	-- Help Reminder
	local helpReminderHeader = CreditsFrame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject("GameFontGreen")
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 6)
	helpReminderHeader:SetText(STEELBLUE .. "Thanks for using Pro Enchanters!" .. ColorClose)
	helpReminderHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	-- version number
	local versionHeader = CreditsFrame:CreateFontString(nil, "OVERLAY")
	versionHeader:SetFontObject("GameFontGreen")
	versionHeader:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 6)
	versionHeader:SetText(STEELBLUE .. version .. ColorClose)
	versionHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	return CreditsFrame
end

function ProEnchantersCreateColorsFrame()
	local ColorsFrame = CreateFrame("Frame", "ProEnchantersColorsFrame", UIParent, "BackdropTemplate")
	ColorsFrame:SetFrameStrata("TOOLTIP")
	ColorsFrame:SetSize(400, 600) -- Adjust height as needed
	ColorsFrame:SetPoint("TOP", 0, -300)
	ColorsFrame:SetMovable(true)
	ColorsFrame:EnableMouse(true)
	ColorsFrame:RegisterForDrag("LeftButton")
	ColorsFrame:SetScript("OnDragStart", ColorsFrame.StartMoving)
	ColorsFrame:SetScript("OnDragStop", function()
		ColorsFrame:StopMovingOrSizing()
	end)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	ColorsFrame:SetBackdrop(backdrop)
	ColorsFrame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	ColorsFrame:Hide()

	-- Create a full background texture
	local bgTexture = ColorsFrame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(SettingsWindowBackgroundOpaque)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(400, 575)
	bgTexture:SetPoint("TOP", ColorsFrame, "TOP", 0, -25)

	-- Create a title background
	local titleBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(400, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOP", ColorsFrame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject(UIFontBasic)
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Colors Settings")

	-- Create Instructions text
	local instructionsHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	instructionsHeader:SetFontObject(UIFontBasic)
	instructionsHeader:SetPoint("TOP", titleBg, "BOTTOM", 0, -10)
	instructionsHeader:SetText(
		"~How to change colors~\nEach line below has a Red Green Blue value set between 0-255\nOpacity is a percentage (0-100 percent)\nChange the numbers and then do a /reload")

	-- Extract Colors from Table
	local TopBarColorR1, TopBarColorG1, TopBarColorB1 = unpack(ProEnchantersOptions.Colors.TopBarColor)
	local SecondaryBarColorR1, SecondaryBarColorG1, SecondaryBarColorB1 = unpack(ProEnchantersOptions.Colors
		.SecondaryBarColor)
	local MainWindowBackgroundR1, MainWindowBackgroundG1, MainWindowBackgroundB1 = unpack(ProEnchantersOptions.Colors
		.MainWindowBackground)
	local BottomBarColorR1, BottomBarColorG1, BottomBarColorB1 = unpack(ProEnchantersOptions.Colors.BottomBarColor)
	local EnchantsButtonColorR1, EnchantsButtonColorG1, EnchantsButtonColorB1 = unpack(ProEnchantersOptions.Colors
		.EnchantsButtonColor)
	local EnchantsButtonColorInactiveR1, EnchantsButtonColorInactiveG1, EnchantsButtonColorInactiveB1 = unpack(
		ProEnchantersOptions.Colors.EnchantsButtonColorInactive)
	local BorderColorR1, BorderColorG1, BorderColorB1 = unpack(ProEnchantersOptions.Colors.BorderColor)
	local MainButtonColorR1, MainButtonColorG1, MainButtonColorB1 = unpack(ProEnchantersOptions.Colors.MainButtonColor)
	local SettingsWindowBackgroundR1, SettingsWindowBackgroundG1, SettingsWindowBackgroundB1 = unpack(
		ProEnchantersOptions.Colors.SettingsWindowBackground)
	local ScrollBarColorsR1, ScrollBarColorsG1, ScrollBarColorsB1 = unpack(ProEnchantersOptions.Colors.ScrollBarColors)
	local OpacityAmountR1 = ProEnchantersOptions.Colors.OpacityAmount

	local function RGBToWoWColorCode(red, green, blue)
		-- Ensure alpha is set to FF for fully opaque
		local alpha = "FF"
		local red = red * 255
		local green = green * 255
		local blue = blue * 255

		-- Convert RGB values to a hexadecimal string
		local colorCode = string.format("|c%s%02x%02x%02x", alpha, red, green, blue)

		return colorCode
	end

	local colorsExamples = ColorsFrame:CreateTexture(nil, "OVERLAY")
	colorsExamples:SetColorTexture(200, 200, 200, 1) -- Set RGBA values for your preferred color and alpha
	colorsExamples:SetSize(70, 400)               -- Adjust size as needed
	colorsExamples:SetPoint("TOPLEFT", titleHeader, "TOPLEFT", 165, -90)

	-- Color Examples

	local TopBarColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	TopBarColorExample:SetFontObject("GameFontHighlight")
	TopBarColorExample:SetPoint("TOPLEFT", colorsExamples, "TOPLEFT", 6, -8)
	local TopBarColorHex = RGBToWoWColorCode(TopBarColorR1, TopBarColorG1, TopBarColorB1)
	TopBarColorExample:SetText(TopBarColorHex .. "EXAMPLE" .. ColorClose)
	TopBarColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local SecondaryBarColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	SecondaryBarColorExample:SetFontObject("GameFontHighlight")
	SecondaryBarColorExample:SetPoint("TOPLEFT", TopBarColorExample, "BOTTOMLEFT", 0, -23)
	local SecondaryBarColorHex = RGBToWoWColorCode(SecondaryBarColorR1, SecondaryBarColorG1, SecondaryBarColorB1)
	SecondaryBarColorExample:SetText(SecondaryBarColorHex .. "EXAMPLE" .. ColorClose)
	SecondaryBarColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local MainWindowBackgroundExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	MainWindowBackgroundExample:SetFontObject("GameFontHighlight")
	MainWindowBackgroundExample:SetPoint("TOPLEFT", SecondaryBarColorExample, "BOTTOMLEFT", 0, -23)
	local MainWindowBackgroundHex = RGBToWoWColorCode(MainWindowBackgroundR1, MainWindowBackgroundG1,
		MainWindowBackgroundB1)
	MainWindowBackgroundExample:SetText(MainWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	MainWindowBackgroundExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local BottomBarColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	BottomBarColorExample:SetFontObject("GameFontHighlight")
	BottomBarColorExample:SetPoint("TOPLEFT", MainWindowBackgroundExample, "BOTTOMLEFT", 0, -23)
	local BottomBarColorHex = RGBToWoWColorCode(BottomBarColorR1, BottomBarColorG1, BottomBarColorB1)
	BottomBarColorExample:SetText(BottomBarColorHex .. "EXAMPLE" .. ColorClose)
	BottomBarColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local EnchantsButtonColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	EnchantsButtonColorExample:SetFontObject("GameFontHighlight")
	EnchantsButtonColorExample:SetPoint("TOPLEFT", BottomBarColorExample, "BOTTOMLEFT", 0, -23)
	local EnchantsButtonColorHex = RGBToWoWColorCode(EnchantsButtonColorR1, EnchantsButtonColorG1, EnchantsButtonColorB1)
	EnchantsButtonColorExample:SetText(EnchantsButtonColorHex .. "EXAMPLE" .. ColorClose)
	EnchantsButtonColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local EnchantsButtonColorInactiveExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	EnchantsButtonColorInactiveExample:SetFontObject("GameFontHighlight")
	EnchantsButtonColorInactiveExample:SetPoint("TOPLEFT", EnchantsButtonColorExample, "BOTTOMLEFT", 0, -23)
	local EnchantsButtonColorInactiveHex = RGBToWoWColorCode(EnchantsButtonColorInactiveR1, EnchantsButtonColorInactiveG1,
		EnchantsButtonColorInactiveB1)
	EnchantsButtonColorInactiveExample:SetText(EnchantsButtonColorInactiveHex .. "EXAMPLE" .. ColorClose)
	EnchantsButtonColorInactiveExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2,
		"")

	local BorderColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	BorderColorExample:SetFontObject("GameFontHighlight")
	BorderColorExample:SetPoint("TOPLEFT", EnchantsButtonColorInactiveExample, "BOTTOMLEFT", 0, -23)
	local BorderColorHex = RGBToWoWColorCode(BorderColorR1, BorderColorG1, BorderColorB1)
	BorderColorExample:SetText(BorderColorHex .. "EXAMPLE" .. ColorClose)
	BorderColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local MainButtonColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	MainButtonColorExample:SetFontObject("GameFontHighlight")
	MainButtonColorExample:SetPoint("TOPLEFT", BorderColorExample, "BOTTOMLEFT", 0, -23)
	local MainButtonColorHex = RGBToWoWColorCode(MainButtonColorR1, MainButtonColorG1, MainButtonColorB1)
	MainButtonColorExample:SetText(MainButtonColorHex .. "EXAMPLE" .. ColorClose)
	MainButtonColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local SettingsWindowBackgroundExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	SettingsWindowBackgroundExample:SetFontObject("GameFontHighlight")
	SettingsWindowBackgroundExample:SetPoint("TOPLEFT", MainButtonColorExample, "BOTTOMLEFT", 0, -23)
	local SettingsWindowBackgroundHex = RGBToWoWColorCode(SettingsWindowBackgroundR1, SettingsWindowBackgroundG1,
		SettingsWindowBackgroundB1)
	SettingsWindowBackgroundExample:SetText(SettingsWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	SettingsWindowBackgroundExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local ScrollBarColorsExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	ScrollBarColorsExample:SetFontObject("GameFontHighlight")
	ScrollBarColorsExample:SetPoint("TOPLEFT", SettingsWindowBackgroundExample, "BOTTOMLEFT", 0, -23)
	local ScrollBarColorsHex = RGBToWoWColorCode(ScrollBarColorsR1, ScrollBarColorsG1, ScrollBarColorsB1)
	ScrollBarColorsExample:SetText(ScrollBarColorsHex .. "EXAMPLE" .. ColorClose)
	ScrollBarColorsExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")


	-- Color EditBoxes
	local TopBarColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	TopBarColorHeader:SetFontObject(UIFontBasic)
	TopBarColorHeader:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 10, -80)
	TopBarColorHeader:SetText("Top Bar")

	local TopBarColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	TopBarColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	TopBarColorRBg:SetSize(34, 24)                                 -- Adjust size as needed
	TopBarColorRBg:SetPoint("LEFT", TopBarColorHeader, "RIGHT", 10, 0)

	local TopBarColorR = CreateFrame("EditBox", nil, ColorsFrame)
	TopBarColorR:SetSize(30, 20)
	TopBarColorR:SetPoint("LEFT", TopBarColorHeader, "RIGHT", 14, 0)
	TopBarColorR:SetAutoFocus(false)
	TopBarColorR:SetNumeric(true)
	TopBarColorR:SetMaxLetters(3)
	TopBarColorR:SetMultiLine(false)
	TopBarColorR:EnableMouse(true)
	TopBarColorR:EnableKeyboard(true)
	TopBarColorR:SetFontObject("GameFontHighlight")
	TopBarColorR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	TopBarColorR:SetText(tostring(TopBarColorR1 * 255))
	TopBarColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	TopBarColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	TopBarColorR:SetScript("OnTextChanged", function()
		local new = tonumber(TopBarColorR:GetText())
		if new == nil then
			TopBarColorR1 = 0
		elseif new > 254 then
			TopBarColorR1 = 1
		else
			TopBarColorR1 = new / 255
		end
		ProEnchantersOptions.Colors.TopBarColor = { TopBarColorR1, TopBarColorG1, TopBarColorB1 }
		local TopBarColorHex = RGBToWoWColorCode(TopBarColorR1, TopBarColorG1, TopBarColorB1)
		TopBarColorExample:SetText(TopBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local TopBarColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	TopBarColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	TopBarColorGBg:SetSize(34, 24)                                 -- Adjust size as needed
	TopBarColorGBg:SetPoint("LEFT", TopBarColorR, "RIGHT", 10, 0)

	local TopBarColorG = CreateFrame("EditBox", nil, ColorsFrame)
	TopBarColorG:SetSize(30, 20)
	TopBarColorG:SetPoint("LEFT", TopBarColorR, "RIGHT", 14, 0)
	TopBarColorG:SetAutoFocus(false)
	TopBarColorG:SetNumeric(true)
	TopBarColorG:SetMaxLetters(3)
	TopBarColorG:SetMultiLine(false)
	TopBarColorG:EnableMouse(true)
	TopBarColorG:EnableKeyboard(true)
	TopBarColorG:SetFontObject("GameFontHighlight")
	TopBarColorG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	TopBarColorG:SetText(tostring(TopBarColorG1 * 255))
	TopBarColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	TopBarColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	TopBarColorG:SetScript("OnTextChanged", function()
		local new = tonumber(TopBarColorG:GetText())
		if new == nil then
			TopBarColorG1 = 0
		elseif new > 254 then
			TopBarColorG1 = 1
		else
			TopBarColorG1 = new / 255
		end
		ProEnchantersOptions.Colors.TopBarColor = { TopBarColorR1, TopBarColorG1, TopBarColorB1 }
		local TopBarColorHex = RGBToWoWColorCode(TopBarColorR1, TopBarColorG1, TopBarColorB1)
		TopBarColorExample:SetText(TopBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local TopBarColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	TopBarColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	TopBarColorBBg:SetSize(34, 24)                                 -- Adjust size as needed
	TopBarColorBBg:SetPoint("LEFT", TopBarColorG, "RIGHT", 10, 0)

	local TopBarColorB = CreateFrame("EditBox", nil, ColorsFrame)
	TopBarColorB:SetSize(30, 20)
	TopBarColorB:SetPoint("LEFT", TopBarColorG, "RIGHT", 14, 0)
	TopBarColorB:SetAutoFocus(false)
	TopBarColorB:SetNumeric(true)
	TopBarColorB:SetMaxLetters(3)
	TopBarColorB:SetMultiLine(false)
	TopBarColorB:EnableMouse(true)
	TopBarColorB:EnableKeyboard(true)
	TopBarColorB:SetFontObject("GameFontHighlight")
	TopBarColorB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	TopBarColorB:SetText(tostring(TopBarColorB1 * 255))
	TopBarColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	TopBarColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	TopBarColorB:SetScript("OnTextChanged", function()
		local new = tonumber(TopBarColorB:GetText())
		if new == nil then
			TopBarColorB1 = 0
		elseif new > 254 then
			TopBarColorB1 = 1
		else
			TopBarColorB1 = new / 255
		end
		ProEnchantersOptions.Colors.TopBarColor = { TopBarColorR1, TopBarColorG1, TopBarColorB1 }
		local TopBarColorHex = RGBToWoWColorCode(TopBarColorR1, TopBarColorG1, TopBarColorB1)
		TopBarColorExample:SetText(TopBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local SecondaryBarColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	SecondaryBarColorHeader:SetFontObject(UIFontBasic)
	SecondaryBarColorHeader:SetPoint("TOPLEFT", TopBarColorHeader, "BOTTOMLEFT", 0, -25)
	SecondaryBarColorHeader:SetText("Secondary Bars")

	local SecondaryBarColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SecondaryBarColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	SecondaryBarColorRBg:SetSize(34, 24)                                 -- Adjust size as needed
	SecondaryBarColorRBg:SetPoint("LEFT", SecondaryBarColorHeader, "RIGHT", 10, 0)

	local SecondaryBarColorR = CreateFrame("EditBox", nil, ColorsFrame)
	SecondaryBarColorR:SetSize(30, 20)
	SecondaryBarColorR:SetPoint("LEFT", SecondaryBarColorHeader, "RIGHT", 14, 0)
	SecondaryBarColorR:SetAutoFocus(false)
	SecondaryBarColorR:SetNumeric(true)
	SecondaryBarColorR:SetMaxLetters(3)
	SecondaryBarColorR:SetMultiLine(false)
	SecondaryBarColorR:EnableMouse(true)
	SecondaryBarColorR:EnableKeyboard(true)
	SecondaryBarColorR:SetFontObject("GameFontHighlight")
	SecondaryBarColorR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	SecondaryBarColorR:SetText(tostring(SecondaryBarColorR1 * 255))
	SecondaryBarColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SecondaryBarColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SecondaryBarColorR:SetScript("OnTextChanged", function()
		local new = tonumber(SecondaryBarColorR:GetText())
		if new == nil then
			SecondaryBarColorR1 = 0
		elseif new > 254 then
			SecondaryBarColorR1 = 1
		else
			SecondaryBarColorR1 = new / 255
		end
		ProEnchantersOptions.Colors.SecondaryBarColor = { SecondaryBarColorR1, SecondaryBarColorG1, SecondaryBarColorB1 }
		local SecondaryBarColorHex = RGBToWoWColorCode(SecondaryBarColorR1, SecondaryBarColorG1, SecondaryBarColorB1)
		SecondaryBarColorExample:SetText(SecondaryBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local SecondaryBarColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SecondaryBarColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	SecondaryBarColorGBg:SetSize(34, 24)                                 -- Adjust size as needed
	SecondaryBarColorGBg:SetPoint("LEFT", SecondaryBarColorR, "RIGHT", 10, 0)

	local SecondaryBarColorG = CreateFrame("EditBox", nil, ColorsFrame)
	SecondaryBarColorG:SetSize(30, 20)
	SecondaryBarColorG:SetPoint("LEFT", SecondaryBarColorR, "RIGHT", 14, 0)
	SecondaryBarColorG:SetAutoFocus(false)
	SecondaryBarColorG:SetNumeric(true)
	SecondaryBarColorG:SetMaxLetters(3)
	SecondaryBarColorG:SetMultiLine(false)
	SecondaryBarColorG:EnableMouse(true)
	SecondaryBarColorG:EnableKeyboard(true)
	SecondaryBarColorG:SetFontObject("GameFontHighlight")
	SecondaryBarColorG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	SecondaryBarColorG:SetText(tostring(SecondaryBarColorG1 * 255))
	SecondaryBarColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SecondaryBarColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SecondaryBarColorG:SetScript("OnTextChanged", function()
		local new = tonumber(SecondaryBarColorG:GetText())
		if new == nil then
			SecondaryBarColorG1 = 0
		elseif new > 254 then
			SecondaryBarColorG1 = 1
		else
			SecondaryBarColorG1 = new / 255
		end
		ProEnchantersOptions.Colors.SecondaryBarColor = { SecondaryBarColorR1, SecondaryBarColorG1, SecondaryBarColorB1 }
		local SecondaryBarColorHex = RGBToWoWColorCode(SecondaryBarColorR1, SecondaryBarColorG1, SecondaryBarColorB1)
		SecondaryBarColorExample:SetText(SecondaryBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local SecondaryBarColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SecondaryBarColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	SecondaryBarColorBBg:SetSize(34, 24)                                 -- Adjust size as needed
	SecondaryBarColorBBg:SetPoint("LEFT", SecondaryBarColorG, "RIGHT", 10, 0)

	local SecondaryBarColorB = CreateFrame("EditBox", nil, ColorsFrame)
	SecondaryBarColorB:SetSize(30, 20)
	SecondaryBarColorB:SetPoint("LEFT", SecondaryBarColorG, "RIGHT", 14, 0)
	SecondaryBarColorB:SetAutoFocus(false)
	SecondaryBarColorB:SetNumeric(true)
	SecondaryBarColorB:SetMaxLetters(3)
	SecondaryBarColorB:SetMultiLine(false)
	SecondaryBarColorB:EnableMouse(true)
	SecondaryBarColorB:EnableKeyboard(true)
	SecondaryBarColorB:SetFontObject("GameFontHighlight")
	SecondaryBarColorB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	SecondaryBarColorB:SetText(tostring(SecondaryBarColorB1 * 255))
	SecondaryBarColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SecondaryBarColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SecondaryBarColorB:SetScript("OnTextChanged", function()
		local new = tonumber(SecondaryBarColorB:GetText())
		if new == nil then
			SecondaryBarColorB1 = 0
		elseif new > 254 then
			SecondaryBarColorB1 = 1
		else
			SecondaryBarColorB1 = new / 255
		end
		ProEnchantersOptions.Colors.SecondaryBarColor = { SecondaryBarColorR1, SecondaryBarColorG1, SecondaryBarColorB1 }
		local SecondaryBarColorHex = RGBToWoWColorCode(SecondaryBarColorR1, SecondaryBarColorG1, SecondaryBarColorB1)
		SecondaryBarColorExample:SetText(SecondaryBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainWindowBackgroundHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	MainWindowBackgroundHeader:SetFontObject(UIFontBasic)
	MainWindowBackgroundHeader:SetPoint("TOPLEFT", SecondaryBarColorHeader, "BOTTOMLEFT", 0, -25)
	MainWindowBackgroundHeader:SetText("Main Windows Backgrounds")

	local MainWindowBackgroundRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainWindowBackgroundRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	MainWindowBackgroundRBg:SetSize(34, 24)                                 -- Adjust size as needed
	MainWindowBackgroundRBg:SetPoint("LEFT", MainWindowBackgroundHeader, "RIGHT", 10, 0)

	local MainWindowBackgroundR = CreateFrame("EditBox", nil, ColorsFrame)
	MainWindowBackgroundR:SetSize(30, 20)
	MainWindowBackgroundR:SetPoint("LEFT", MainWindowBackgroundHeader, "RIGHT", 14, 0)
	MainWindowBackgroundR:SetAutoFocus(false)
	MainWindowBackgroundR:SetNumeric(true)
	MainWindowBackgroundR:SetMaxLetters(3)
	MainWindowBackgroundR:SetMultiLine(false)
	MainWindowBackgroundR:EnableMouse(true)
	MainWindowBackgroundR:EnableKeyboard(true)
	MainWindowBackgroundR:SetFontObject("GameFontHighlight")
	MainWindowBackgroundR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	MainWindowBackgroundR:SetText(tostring(MainWindowBackgroundR1 * 255))
	MainWindowBackgroundR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundR:SetScript("OnTextChanged", function()
		local new = tonumber(MainWindowBackgroundR:GetText())
		if new == nil then
			MainWindowBackgroundR1 = 0
		elseif new > 254 then
			MainWindowBackgroundR1 = 1
		else
			MainWindowBackgroundR1 = new / 255
		end
		ProEnchantersOptions.Colors.MainWindowBackground = { MainWindowBackgroundR1, MainWindowBackgroundG1,
			MainWindowBackgroundB1 }
		local MainWindowBackgroundHex = RGBToWoWColorCode(MainWindowBackgroundR1, MainWindowBackgroundG1,
			MainWindowBackgroundB1)
		MainWindowBackgroundExample:SetText(MainWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainWindowBackgroundGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainWindowBackgroundGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	MainWindowBackgroundGBg:SetSize(34, 24)                                 -- Adjust size as needed
	MainWindowBackgroundGBg:SetPoint("LEFT", MainWindowBackgroundR, "RIGHT", 10, 0)

	local MainWindowBackgroundG = CreateFrame("EditBox", nil, ColorsFrame)
	MainWindowBackgroundG:SetSize(30, 20)
	MainWindowBackgroundG:SetPoint("LEFT", MainWindowBackgroundR, "RIGHT", 14, 0)
	MainWindowBackgroundG:SetAutoFocus(false)
	MainWindowBackgroundG:SetNumeric(true)
	MainWindowBackgroundG:SetMaxLetters(3)
	MainWindowBackgroundG:SetMultiLine(false)
	MainWindowBackgroundG:EnableMouse(true)
	MainWindowBackgroundG:EnableKeyboard(true)
	MainWindowBackgroundG:SetFontObject("GameFontHighlight")
	MainWindowBackgroundG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	MainWindowBackgroundG:SetText(tostring(MainWindowBackgroundG1 * 255))
	MainWindowBackgroundG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundG:SetScript("OnTextChanged", function()
		local new = tonumber(MainWindowBackgroundG:GetText())
		if new == nil then
			MainWindowBackgroundG1 = 0
		elseif new > 254 then
			MainWindowBackgroundG1 = 1
		else
			MainWindowBackgroundG1 = new / 255
		end
		ProEnchantersOptions.Colors.MainWindowBackground = { MainWindowBackgroundR1, MainWindowBackgroundG1,
			MainWindowBackgroundB1 }
		local MainWindowBackgroundHex = RGBToWoWColorCode(MainWindowBackgroundR1, MainWindowBackgroundG1,
			MainWindowBackgroundB1)
		MainWindowBackgroundExample:SetText(MainWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainWindowBackgroundBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainWindowBackgroundBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	MainWindowBackgroundBBg:SetSize(34, 24)                                 -- Adjust size as needed
	MainWindowBackgroundBBg:SetPoint("LEFT", MainWindowBackgroundG, "RIGHT", 10, 0)

	local MainWindowBackgroundB = CreateFrame("EditBox", nil, ColorsFrame)
	MainWindowBackgroundB:SetSize(30, 20)
	MainWindowBackgroundB:SetPoint("LEFT", MainWindowBackgroundG, "RIGHT", 14, 0)
	MainWindowBackgroundB:SetAutoFocus(false)
	MainWindowBackgroundB:SetNumeric(true)
	MainWindowBackgroundB:SetMaxLetters(3)
	MainWindowBackgroundB:SetMultiLine(false)
	MainWindowBackgroundB:EnableMouse(true)
	MainWindowBackgroundB:EnableKeyboard(true)
	MainWindowBackgroundB:SetFontObject("GameFontHighlight")
	MainWindowBackgroundB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	MainWindowBackgroundB:SetText(tostring(MainWindowBackgroundB1 * 255))
	MainWindowBackgroundB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundB:SetScript("OnTextChanged", function()
		local new = tonumber(MainWindowBackgroundB:GetText())
		if new == nil then
			MainWindowBackgroundB1 = 0
		elseif new > 254 then
			MainWindowBackgroundB1 = 1
		else
			MainWindowBackgroundB1 = new / 255
		end
		ProEnchantersOptions.Colors.MainWindowBackground = { MainWindowBackgroundR1, MainWindowBackgroundG1,
			MainWindowBackgroundB1 }
		local MainWindowBackgroundHex = RGBToWoWColorCode(MainWindowBackgroundR1, MainWindowBackgroundG1,
			MainWindowBackgroundB1)
		MainWindowBackgroundExample:SetText(MainWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local BottomBarColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	BottomBarColorHeader:SetFontObject(UIFontBasic)
	BottomBarColorHeader:SetPoint("TOPLEFT", MainWindowBackgroundHeader, "BOTTOMLEFT", 0, -25)
	BottomBarColorHeader:SetText("Bottom Bar")

	local BottomBarColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BottomBarColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	BottomBarColorRBg:SetSize(34, 24)                                 -- Adjust size as needed
	BottomBarColorRBg:SetPoint("LEFT", BottomBarColorHeader, "RIGHT", 10, 0)

	local BottomBarColorR = CreateFrame("EditBox", nil, ColorsFrame)
	BottomBarColorR:SetSize(30, 20)
	BottomBarColorR:SetPoint("LEFT", BottomBarColorHeader, "RIGHT", 14, 0)
	BottomBarColorR:SetAutoFocus(false)
	BottomBarColorR:SetNumeric(true)
	BottomBarColorR:SetMaxLetters(3)
	BottomBarColorR:SetMultiLine(false)
	BottomBarColorR:EnableMouse(true)
	BottomBarColorR:EnableKeyboard(true)
	BottomBarColorR:SetFontObject("GameFontHighlight")
	BottomBarColorR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	BottomBarColorR:SetText(tostring(BottomBarColorR1 * 255))
	BottomBarColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BottomBarColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BottomBarColorR:SetScript("OnTextChanged", function()
		local new = tonumber(BottomBarColorR:GetText())
		if new == nil then
			BottomBarColorR1 = 0
		elseif new > 254 then
			BottomBarColorR1 = 1
		else
			BottomBarColorR1 = new / 255
		end
		ProEnchantersOptions.Colors.BottomBarColor = { BottomBarColorR1, BottomBarColorG1, BottomBarColorB1 }
		local BottomBarColorHex = RGBToWoWColorCode(BottomBarColorR1, BottomBarColorG1, BottomBarColorB1)
		BottomBarColorExample:SetText(BottomBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local BottomBarColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BottomBarColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	BottomBarColorGBg:SetSize(34, 24)                                 -- Adjust size as needed
	BottomBarColorGBg:SetPoint("LEFT", BottomBarColorR, "RIGHT", 10, 0)

	local BottomBarColorG = CreateFrame("EditBox", nil, ColorsFrame)
	BottomBarColorG:SetSize(30, 20)
	BottomBarColorG:SetPoint("LEFT", BottomBarColorR, "RIGHT", 14, 0)
	BottomBarColorG:SetAutoFocus(false)
	BottomBarColorG:SetNumeric(true)
	BottomBarColorG:SetMaxLetters(3)
	BottomBarColorG:SetMultiLine(false)
	BottomBarColorG:EnableMouse(true)
	BottomBarColorG:EnableKeyboard(true)
	BottomBarColorG:SetFontObject("GameFontHighlight")
	BottomBarColorG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	BottomBarColorG:SetText(tostring(BottomBarColorG1 * 255))
	BottomBarColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BottomBarColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BottomBarColorG:SetScript("OnTextChanged", function()
		local new = tonumber(BottomBarColorG:GetText())
		if new == nil then
			BottomBarColorG1 = 0
		elseif new > 254 then
			BottomBarColorG1 = 1
		else
			BottomBarColorG1 = new / 255
		end
		ProEnchantersOptions.Colors.BottomBarColor = { BottomBarColorR1, BottomBarColorG1, BottomBarColorB1 }
		local BottomBarColorHex = RGBToWoWColorCode(BottomBarColorR1, BottomBarColorG1, BottomBarColorB1)
		BottomBarColorExample:SetText(BottomBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local BottomBarColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BottomBarColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	BottomBarColorBBg:SetSize(34, 24)                                 -- Adjust size as needed
	BottomBarColorBBg:SetPoint("LEFT", BottomBarColorG, "RIGHT", 10, 0)

	local BottomBarColorB = CreateFrame("EditBox", nil, ColorsFrame)
	BottomBarColorB:SetSize(30, 20)
	BottomBarColorB:SetPoint("LEFT", BottomBarColorG, "RIGHT", 14, 0)
	BottomBarColorB:SetAutoFocus(false)
	BottomBarColorB:SetNumeric(true)
	BottomBarColorB:SetMaxLetters(3)
	BottomBarColorB:SetMultiLine(false)
	BottomBarColorB:EnableMouse(true)
	BottomBarColorB:EnableKeyboard(true)
	BottomBarColorB:SetFontObject("GameFontHighlight")
	BottomBarColorB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	BottomBarColorB:SetText(tostring(BottomBarColorB1 * 255))
	BottomBarColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BottomBarColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BottomBarColorB:SetScript("OnTextChanged", function()
		local new = tonumber(BottomBarColorB:GetText())
		if new == nil then
			BottomBarColorB1 = 0
		elseif new > 254 then
			BottomBarColorB1 = 1
		else
			BottomBarColorB1 = new / 255
		end
		ProEnchantersOptions.Colors.BottomBarColor = { BottomBarColorR1, BottomBarColorG1, BottomBarColorB1 }
		local BottomBarColorHex = RGBToWoWColorCode(BottomBarColorR1, BottomBarColorG1, BottomBarColorB1)
		BottomBarColorExample:SetText(BottomBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	EnchantsButtonColorHeader:SetFontObject(UIFontBasic)
	EnchantsButtonColorHeader:SetPoint("TOPLEFT", BottomBarColorHeader, "BOTTOMLEFT", 0, -25)
	EnchantsButtonColorHeader:SetText("Enchant Buttons")


	local EnchantsButtonColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorRBg:SetSize(34, 24)                                 -- Adjust size as needed
	EnchantsButtonColorRBg:SetPoint("LEFT", EnchantsButtonColorHeader, "RIGHT", 10, 0)

	local EnchantsButtonColorR = CreateFrame("EditBox", nil, ColorsFrame)
	EnchantsButtonColorR:SetSize(30, 20)
	EnchantsButtonColorR:SetPoint("LEFT", EnchantsButtonColorHeader, "RIGHT", 14, 0)
	EnchantsButtonColorR:SetAutoFocus(false)
	EnchantsButtonColorR:SetNumeric(true)
	EnchantsButtonColorR:SetMaxLetters(3)
	EnchantsButtonColorR:SetMultiLine(false)
	EnchantsButtonColorR:EnableMouse(true)
	EnchantsButtonColorR:EnableKeyboard(true)
	EnchantsButtonColorR:SetFontObject("GameFontHighlight")
	EnchantsButtonColorR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	EnchantsButtonColorR:SetText(tostring(EnchantsButtonColorR1 * 255))
	EnchantsButtonColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorR:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorR:GetText())
		if new == nil then
			EnchantsButtonColorR1 = 0
		elseif new > 254 then
			EnchantsButtonColorR1 = 1
		else
			EnchantsButtonColorR1 = new / 255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColor = { EnchantsButtonColorR1, EnchantsButtonColorG1,
			EnchantsButtonColorB1 }
		local EnchantsButtonColorHex = RGBToWoWColorCode(EnchantsButtonColorR1, EnchantsButtonColorG1,
			EnchantsButtonColorB1)
		EnchantsButtonColorExample:SetText(EnchantsButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorGBg:SetSize(34, 24)                                 -- Adjust size as needed
	EnchantsButtonColorGBg:SetPoint("LEFT", EnchantsButtonColorR, "RIGHT", 10, 0)

	local EnchantsButtonColorG = CreateFrame("EditBox", nil, ColorsFrame)
	EnchantsButtonColorG:SetSize(30, 20)
	EnchantsButtonColorG:SetPoint("LEFT", EnchantsButtonColorR, "RIGHT", 14, 0)
	EnchantsButtonColorG:SetAutoFocus(false)
	EnchantsButtonColorG:SetNumeric(true)
	EnchantsButtonColorG:SetMaxLetters(3)
	EnchantsButtonColorG:SetMultiLine(false)
	EnchantsButtonColorG:EnableMouse(true)
	EnchantsButtonColorG:EnableKeyboard(true)
	EnchantsButtonColorG:SetFontObject("GameFontHighlight")
	EnchantsButtonColorG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	EnchantsButtonColorG:SetText(tostring(EnchantsButtonColorG1 * 255))
	EnchantsButtonColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorG:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorG:GetText())
		if new == nil then
			EnchantsButtonColorG1 = 0
		elseif new > 254 then
			EnchantsButtonColorG1 = 1
		else
			EnchantsButtonColorG1 = new / 255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColor = { EnchantsButtonColorR1, EnchantsButtonColorG1,
			EnchantsButtonColorB1 }
		local EnchantsButtonColorHex = RGBToWoWColorCode(EnchantsButtonColorR1, EnchantsButtonColorG1,
			EnchantsButtonColorB1)
		EnchantsButtonColorExample:SetText(EnchantsButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorBBg:SetSize(34, 24)                                 -- Adjust size as needed
	EnchantsButtonColorBBg:SetPoint("LEFT", EnchantsButtonColorG, "RIGHT", 10, 0)

	local EnchantsButtonColorB = CreateFrame("EditBox", nil, ColorsFrame)
	EnchantsButtonColorB:SetSize(30, 20)
	EnchantsButtonColorB:SetPoint("LEFT", EnchantsButtonColorG, "RIGHT", 14, 0)
	EnchantsButtonColorB:SetAutoFocus(false)
	EnchantsButtonColorB:SetNumeric(true)
	EnchantsButtonColorB:SetMaxLetters(3)
	EnchantsButtonColorB:SetMultiLine(false)
	EnchantsButtonColorB:EnableMouse(true)
	EnchantsButtonColorB:EnableKeyboard(true)
	EnchantsButtonColorB:SetFontObject("GameFontHighlight")
	EnchantsButtonColorB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	EnchantsButtonColorB:SetText(tostring(EnchantsButtonColorB1 * 255))
	EnchantsButtonColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorB:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorB:GetText())
		if new == nil then
			EnchantsButtonColorB1 = 0
		elseif new > 254 then
			EnchantsButtonColorB1 = 1
		else
			EnchantsButtonColorB1 = new / 255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColor = { EnchantsButtonColorR1, EnchantsButtonColorG1,
			EnchantsButtonColorB1 }
		local EnchantsButtonColorHex = RGBToWoWColorCode(EnchantsButtonColorR1, EnchantsButtonColorG1,
			EnchantsButtonColorB1)
		EnchantsButtonColorExample:SetText(EnchantsButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorInactiveHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	EnchantsButtonColorInactiveHeader:SetFontObject(UIFontBasic)
	EnchantsButtonColorInactiveHeader:SetPoint("TOPLEFT", EnchantsButtonColorHeader, "BOTTOMLEFT", 0, -25)
	EnchantsButtonColorInactiveHeader:SetText("Disabled Enchant Buttons")

	local EnchantsButtonColorInactiveRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorInactiveRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorInactiveRBg:SetSize(34, 24)                                 -- Adjust size as needed
	EnchantsButtonColorInactiveRBg:SetPoint("LEFT", EnchantsButtonColorInactiveHeader, "RIGHT", 10, 0)

	local EnchantsButtonColorInactiveR = CreateFrame("EditBox", nil, ColorsFrame)
	EnchantsButtonColorInactiveR:SetSize(30, 20)
	EnchantsButtonColorInactiveR:SetPoint("LEFT", EnchantsButtonColorInactiveHeader, "RIGHT", 14, 0)
	EnchantsButtonColorInactiveR:SetAutoFocus(false)
	EnchantsButtonColorInactiveR:SetNumeric(true)
	EnchantsButtonColorInactiveR:SetMaxLetters(3)
	EnchantsButtonColorInactiveR:SetMultiLine(false)
	EnchantsButtonColorInactiveR:EnableMouse(true)
	EnchantsButtonColorInactiveR:EnableKeyboard(true)
	EnchantsButtonColorInactiveR:SetFontObject("GameFontHighlight")
	EnchantsButtonColorInactiveR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	EnchantsButtonColorInactiveR:SetText(tostring(EnchantsButtonColorInactiveR1 * 255))
	EnchantsButtonColorInactiveR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveR:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorInactiveR:GetText())
		if new == nil then
			EnchantsButtonColorInactiveR1 = 0
		elseif new > 254 then
			EnchantsButtonColorInactiveR1 = 1
		else
			EnchantsButtonColorInactiveR1 = new / 255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColorInactive = { EnchantsButtonColorInactiveR1,
			EnchantsButtonColorInactiveG1, EnchantsButtonColorInactiveB1 }
		local EnchantsButtonColorInactiveHex = RGBToWoWColorCode(EnchantsButtonColorInactiveR1,
			EnchantsButtonColorInactiveG1, EnchantsButtonColorInactiveB1)
		EnchantsButtonColorInactiveExample:SetText(EnchantsButtonColorInactiveHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorInactiveGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorInactiveGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorInactiveGBg:SetSize(34, 24)                                 -- Adjust size as needed
	EnchantsButtonColorInactiveGBg:SetPoint("LEFT", EnchantsButtonColorInactiveR, "RIGHT", 10, 0)

	local EnchantsButtonColorInactiveG = CreateFrame("EditBox", nil, ColorsFrame)
	EnchantsButtonColorInactiveG:SetSize(30, 20)
	EnchantsButtonColorInactiveG:SetPoint("LEFT", EnchantsButtonColorInactiveR, "RIGHT", 14, 0)
	EnchantsButtonColorInactiveG:SetAutoFocus(false)
	EnchantsButtonColorInactiveG:SetNumeric(true)
	EnchantsButtonColorInactiveG:SetMaxLetters(3)
	EnchantsButtonColorInactiveG:SetMultiLine(false)
	EnchantsButtonColorInactiveG:EnableMouse(true)
	EnchantsButtonColorInactiveG:EnableKeyboard(true)
	EnchantsButtonColorInactiveG:SetFontObject("GameFontHighlight")
	EnchantsButtonColorInactiveG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	EnchantsButtonColorInactiveG:SetText(tostring(EnchantsButtonColorInactiveG1 * 255))
	EnchantsButtonColorInactiveG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveG:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorInactiveG:GetText())
		if new == nil then
			EnchantsButtonColorInactiveG1 = 0
		elseif new > 254 then
			EnchantsButtonColorInactiveG1 = 1
		else
			EnchantsButtonColorInactiveG1 = new / 255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColorInactive = { EnchantsButtonColorInactiveR1,
			EnchantsButtonColorInactiveG1, EnchantsButtonColorInactiveB1 }
		local EnchantsButtonColorInactiveHex = RGBToWoWColorCode(EnchantsButtonColorInactiveR1,
			EnchantsButtonColorInactiveG1, EnchantsButtonColorInactiveB1)
		EnchantsButtonColorInactiveExample:SetText(EnchantsButtonColorInactiveHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorInactiveBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorInactiveBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorInactiveBBg:SetSize(34, 24)                                 -- Adjust size as needed
	EnchantsButtonColorInactiveBBg:SetPoint("LEFT", EnchantsButtonColorInactiveG, "RIGHT", 10, 0)

	local EnchantsButtonColorInactiveB = CreateFrame("EditBox", nil, ColorsFrame)
	EnchantsButtonColorInactiveB:SetSize(30, 20)
	EnchantsButtonColorInactiveB:SetPoint("LEFT", EnchantsButtonColorInactiveG, "RIGHT", 14, 0)
	EnchantsButtonColorInactiveB:SetAutoFocus(false)
	EnchantsButtonColorInactiveB:SetNumeric(true)
	EnchantsButtonColorInactiveB:SetMaxLetters(3)
	EnchantsButtonColorInactiveB:SetMultiLine(false)
	EnchantsButtonColorInactiveB:EnableMouse(true)
	EnchantsButtonColorInactiveB:EnableKeyboard(true)
	EnchantsButtonColorInactiveB:SetFontObject("GameFontHighlight")
	EnchantsButtonColorInactiveB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	EnchantsButtonColorInactiveB:SetText(tostring(EnchantsButtonColorInactiveB1 * 255))
	EnchantsButtonColorInactiveB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveB:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorInactiveB:GetText())
		if new == nil then
			EnchantsButtonColorInactiveB1 = 0
		elseif new > 254 then
			EnchantsButtonColorInactiveB1 = 1
		else
			EnchantsButtonColorInactiveB1 = new / 255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColorInactive = { EnchantsButtonColorInactiveR1,
			EnchantsButtonColorInactiveG1, EnchantsButtonColorInactiveB1 }
		local EnchantsButtonColorInactiveHex = RGBToWoWColorCode(EnchantsButtonColorInactiveR1,
			EnchantsButtonColorInactiveG1, EnchantsButtonColorInactiveB1)
		EnchantsButtonColorInactiveExample:SetText(EnchantsButtonColorInactiveHex .. "EXAMPLE" .. ColorClose)
	end)

	local BorderColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	BorderColorHeader:SetFontObject(UIFontBasic)
	BorderColorHeader:SetPoint("TOPLEFT", EnchantsButtonColorInactiveHeader, "BOTTOMLEFT", 0, -25)
	BorderColorHeader:SetText("Border Colors")

	local BorderColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BorderColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	BorderColorRBg:SetSize(34, 24)                                 -- Adjust size as needed
	BorderColorRBg:SetPoint("LEFT", BorderColorHeader, "RIGHT", 10, 0)

	local BorderColorR = CreateFrame("EditBox", nil, ColorsFrame)
	BorderColorR:SetSize(30, 20)
	BorderColorR:SetPoint("LEFT", BorderColorHeader, "RIGHT", 14, 0)
	BorderColorR:SetAutoFocus(false)
	BorderColorR:SetNumeric(true)
	BorderColorR:SetMaxLetters(3)
	BorderColorR:SetMultiLine(false)
	BorderColorR:EnableMouse(true)
	BorderColorR:EnableKeyboard(true)
	BorderColorR:SetFontObject("GameFontHighlight")
	BorderColorR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	BorderColorR:SetText(tostring(BorderColorR1 * 255))
	BorderColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BorderColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BorderColorR:SetScript("OnTextChanged", function()
		local new = tonumber(BorderColorR:GetText())
		if new == nil then
			BorderColorR1 = 0
		elseif new > 254 then
			BorderColorR1 = 1
		else
			BorderColorR1 = new / 255
		end
		ProEnchantersOptions.Colors.BorderColor = { BorderColorR1, BorderColorG1, BorderColorB1 }
		local BorderColorHex = RGBToWoWColorCode(BorderColorR1, BorderColorG1, BorderColorB1)
		BorderColorExample:SetText(BorderColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local BorderColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BorderColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	BorderColorGBg:SetSize(34, 24)                                 -- Adjust size as needed
	BorderColorGBg:SetPoint("LEFT", BorderColorR, "RIGHT", 10, 0)

	local BorderColorG = CreateFrame("EditBox", nil, ColorsFrame)
	BorderColorG:SetSize(30, 20)
	BorderColorG:SetPoint("LEFT", BorderColorR, "RIGHT", 14, 0)
	BorderColorG:SetAutoFocus(false)
	BorderColorG:SetNumeric(true)
	BorderColorG:SetMaxLetters(3)
	BorderColorG:SetMultiLine(false)
	BorderColorG:EnableMouse(true)
	BorderColorG:EnableKeyboard(true)
	BorderColorG:SetFontObject("GameFontHighlight")
	BorderColorG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	BorderColorG:SetText(tostring(BorderColorG1 * 255))
	BorderColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BorderColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BorderColorG:SetScript("OnTextChanged", function()
		local new = tonumber(BorderColorG:GetText())
		if new == nil then
			BorderColorG1 = 0
		elseif new > 254 then
			BorderColorG1 = 1
		else
			BorderColorG1 = new / 255
		end
		ProEnchantersOptions.Colors.BorderColor = { BorderColorR1, BorderColorG1, BorderColorB1 }
		local BorderColorHex = RGBToWoWColorCode(BorderColorR1, BorderColorG1, BorderColorB1)
		BorderColorExample:SetText(BorderColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local BorderColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BorderColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	BorderColorBBg:SetSize(34, 24)                                 -- Adjust size as needed
	BorderColorBBg:SetPoint("LEFT", BorderColorG, "RIGHT", 10, 0)

	local BorderColorB = CreateFrame("EditBox", nil, ColorsFrame)
	BorderColorB:SetSize(30, 20)
	BorderColorB:SetPoint("LEFT", BorderColorG, "RIGHT", 14, 0)
	BorderColorB:SetAutoFocus(false)
	BorderColorB:SetNumeric(true)
	BorderColorB:SetMaxLetters(3)
	BorderColorB:SetMultiLine(false)
	BorderColorB:EnableMouse(true)
	BorderColorB:EnableKeyboard(true)
	BorderColorB:SetFontObject("GameFontHighlight")
	BorderColorB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	BorderColorB:SetText(tostring(BorderColorB1 * 255))
	BorderColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BorderColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BorderColorB:SetScript("OnTextChanged", function()
		local new = tonumber(BorderColorB:GetText())
		if new == nil then
			BorderColorB1 = 0
		elseif new > 254 then
			BorderColorB1 = 1
		else
			BorderColorB1 = new / 255
		end
		ProEnchantersOptions.Colors.BorderColor = { BorderColorR1, BorderColorG1, BorderColorB1 }
		local BorderColorHex = RGBToWoWColorCode(BorderColorR1, BorderColorG1, BorderColorB1)
		BorderColorExample:SetText(BorderColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainButtonColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	MainButtonColorHeader:SetFontObject(UIFontBasic)
	MainButtonColorHeader:SetPoint("TOPLEFT", BorderColorHeader, "BOTTOMLEFT", 0, -25)
	MainButtonColorHeader:SetText("Main Buttons")

	local MainButtonColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainButtonColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	MainButtonColorRBg:SetSize(34, 24)                                 -- Adjust size as needed
	MainButtonColorRBg:SetPoint("LEFT", MainButtonColorHeader, "RIGHT", 10, 0)

	local MainButtonColorR = CreateFrame("EditBox", nil, ColorsFrame)
	MainButtonColorR:SetSize(30, 20)
	MainButtonColorR:SetPoint("LEFT", MainButtonColorHeader, "RIGHT", 14, 0)
	MainButtonColorR:SetAutoFocus(false)
	MainButtonColorR:SetNumeric(true)
	MainButtonColorR:SetMaxLetters(3)
	MainButtonColorR:SetMultiLine(false)
	MainButtonColorR:EnableMouse(true)
	MainButtonColorR:EnableKeyboard(true)
	MainButtonColorR:SetFontObject("GameFontHighlight")
	MainButtonColorR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	MainButtonColorR:SetText(tostring(MainButtonColorR1 * 255))
	MainButtonColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainButtonColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainButtonColorR:SetScript("OnTextChanged", function()
		local new = tonumber(MainButtonColorR:GetText())
		if new == nil then
			MainButtonColorR1 = 0
		elseif new > 254 then
			MainButtonColorR1 = 1
		else
			MainButtonColorR1 = new / 255
		end
		ProEnchantersOptions.Colors.MainButtonColor = { MainButtonColorR1, MainButtonColorG1, MainButtonColorB1 }
		local MainButtonColorHex = RGBToWoWColorCode(MainButtonColorR1, MainButtonColorG1, MainButtonColorB1)
		MainButtonColorExample:SetText(MainButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainButtonColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainButtonColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	MainButtonColorGBg:SetSize(34, 24)                                 -- Adjust size as needed
	MainButtonColorGBg:SetPoint("LEFT", MainButtonColorR, "RIGHT", 10, 0)

	local MainButtonColorG = CreateFrame("EditBox", nil, ColorsFrame)
	MainButtonColorG:SetSize(30, 20)
	MainButtonColorG:SetPoint("LEFT", MainButtonColorR, "RIGHT", 14, 0)
	MainButtonColorG:SetAutoFocus(false)
	MainButtonColorG:SetNumeric(true)
	MainButtonColorG:SetMaxLetters(3)
	MainButtonColorG:SetMultiLine(false)
	MainButtonColorG:EnableMouse(true)
	MainButtonColorG:EnableKeyboard(true)
	MainButtonColorG:SetFontObject("GameFontHighlight")
	MainButtonColorG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	MainButtonColorG:SetText(tostring(MainButtonColorG1 * 255))
	MainButtonColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainButtonColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainButtonColorG:SetScript("OnTextChanged", function()
		local new = tonumber(MainButtonColorG:GetText())
		if new == nil then
			MainButtonColorG1 = 0
		elseif new > 254 then
			MainButtonColorG1 = 1
		else
			MainButtonColorG1 = new / 255
		end
		ProEnchantersOptions.Colors.MainButtonColor = { MainButtonColorR1, MainButtonColorG1, MainButtonColorB1 }
		local MainButtonColorHex = RGBToWoWColorCode(MainButtonColorR1, MainButtonColorG1, MainButtonColorB1)
		MainButtonColorExample:SetText(MainButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainButtonColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainButtonColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	MainButtonColorBBg:SetSize(34, 24)                                 -- Adjust size as needed
	MainButtonColorBBg:SetPoint("LEFT", MainButtonColorG, "RIGHT", 10, 0)

	local MainButtonColorB = CreateFrame("EditBox", nil, ColorsFrame)
	MainButtonColorB:SetSize(30, 20)
	MainButtonColorB:SetPoint("LEFT", MainButtonColorG, "RIGHT", 14, 0)
	MainButtonColorB:SetAutoFocus(false)
	MainButtonColorB:SetNumeric(true)
	MainButtonColorB:SetMaxLetters(3)
	MainButtonColorB:SetMultiLine(false)
	MainButtonColorB:EnableMouse(true)
	MainButtonColorB:EnableKeyboard(true)
	MainButtonColorB:SetFontObject("GameFontHighlight")
	MainButtonColorB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	MainButtonColorB:SetText(tostring(MainButtonColorB1 * 255))
	MainButtonColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainButtonColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainButtonColorB:SetScript("OnTextChanged", function()
		local new = tonumber(MainButtonColorB:GetText())
		if new == nil then
			MainButtonColorB1 = 0
		elseif new > 254 then
			MainButtonColorB1 = 1
		else
			MainButtonColorB1 = new / 255
		end
		ProEnchantersOptions.Colors.MainButtonColor = { MainButtonColorR1, MainButtonColorG1, MainButtonColorB1 }
		local MainButtonColorHex = RGBToWoWColorCode(MainButtonColorR1, MainButtonColorG1, MainButtonColorB1)
		MainButtonColorExample:SetText(MainButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local SettingsWindowBackgroundHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	SettingsWindowBackgroundHeader:SetFontObject(UIFontBasic)
	SettingsWindowBackgroundHeader:SetPoint("TOPLEFT", MainButtonColorHeader, "BOTTOMLEFT", 0, -25)
	SettingsWindowBackgroundHeader:SetText("Settings Window Background")

	local SettingsWindowBackgroundRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SettingsWindowBackgroundRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	SettingsWindowBackgroundRBg:SetSize(34, 24)                                 -- Adjust size as needed
	SettingsWindowBackgroundRBg:SetPoint("LEFT", SettingsWindowBackgroundHeader, "RIGHT", 10, 0)

	local SettingsWindowBackgroundR = CreateFrame("EditBox", nil, ColorsFrame)
	SettingsWindowBackgroundR:SetSize(30, 20)
	SettingsWindowBackgroundR:SetPoint("LEFT", SettingsWindowBackgroundHeader, "RIGHT", 14, 0)
	SettingsWindowBackgroundR:SetAutoFocus(false)
	SettingsWindowBackgroundR:SetNumeric(true)
	SettingsWindowBackgroundR:SetMaxLetters(3)
	SettingsWindowBackgroundR:SetMultiLine(false)
	SettingsWindowBackgroundR:EnableMouse(true)
	SettingsWindowBackgroundR:EnableKeyboard(true)
	SettingsWindowBackgroundR:SetFontObject("GameFontHighlight")
	SettingsWindowBackgroundR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	SettingsWindowBackgroundR:SetText(tostring(SettingsWindowBackgroundR1 * 255))
	SettingsWindowBackgroundR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundR:SetScript("OnTextChanged", function()
		local new = tonumber(SettingsWindowBackgroundR:GetText())
		if new == nil then
			SettingsWindowBackgroundR1 = 0
		elseif new > 254 then
			SettingsWindowBackgroundR1 = 1
		else
			SettingsWindowBackgroundR1 = new / 255
		end
		ProEnchantersOptions.Colors.SettingsWindowBackground = { SettingsWindowBackgroundR1, SettingsWindowBackgroundG1,
			SettingsWindowBackgroundB1 }
		local SettingsWindowBackgroundHex = RGBToWoWColorCode(SettingsWindowBackgroundR1, SettingsWindowBackgroundG1,
			SettingsWindowBackgroundB1)
		SettingsWindowBackgroundExample:SetText(SettingsWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local SettingsWindowBackgroundGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SettingsWindowBackgroundGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	SettingsWindowBackgroundGBg:SetSize(34, 24)                                 -- Adjust size as needed
	SettingsWindowBackgroundGBg:SetPoint("LEFT", SettingsWindowBackgroundR, "RIGHT", 10, 0)

	local SettingsWindowBackgroundG = CreateFrame("EditBox", nil, ColorsFrame)
	SettingsWindowBackgroundG:SetSize(30, 20)
	SettingsWindowBackgroundG:SetPoint("LEFT", SettingsWindowBackgroundR, "RIGHT", 14, 0)
	SettingsWindowBackgroundG:SetAutoFocus(false)
	SettingsWindowBackgroundG:SetNumeric(true)
	SettingsWindowBackgroundG:SetMaxLetters(3)
	SettingsWindowBackgroundG:SetMultiLine(false)
	SettingsWindowBackgroundG:EnableMouse(true)
	SettingsWindowBackgroundG:EnableKeyboard(true)
	SettingsWindowBackgroundG:SetFontObject("GameFontHighlight")
	SettingsWindowBackgroundG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	SettingsWindowBackgroundG:SetText(tostring(SettingsWindowBackgroundG1 * 255))
	SettingsWindowBackgroundG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundG:SetScript("OnTextChanged", function()
		local new = tonumber(SettingsWindowBackgroundG:GetText())
		if new == nil then
			SettingsWindowBackgroundG1 = 0
		elseif new > 254 then
			SettingsWindowBackgroundG1 = 1
		else
			SettingsWindowBackgroundG1 = new / 255
		end
		ProEnchantersOptions.Colors.SettingsWindowBackground = { SettingsWindowBackgroundR1, SettingsWindowBackgroundG1,
			SettingsWindowBackgroundB1 }
		local SettingsWindowBackgroundHex = RGBToWoWColorCode(SettingsWindowBackgroundR1, SettingsWindowBackgroundG1,
			SettingsWindowBackgroundB1)
		SettingsWindowBackgroundExample:SetText(SettingsWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local SettingsWindowBackgroundBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SettingsWindowBackgroundBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	SettingsWindowBackgroundBBg:SetSize(34, 24)                                 -- Adjust size as needed
	SettingsWindowBackgroundBBg:SetPoint("LEFT", SettingsWindowBackgroundG, "RIGHT", 10, 0)

	local SettingsWindowBackgroundB = CreateFrame("EditBox", nil, ColorsFrame)
	SettingsWindowBackgroundB:SetSize(30, 20)
	SettingsWindowBackgroundB:SetPoint("LEFT", SettingsWindowBackgroundG, "RIGHT", 14, 0)
	SettingsWindowBackgroundB:SetAutoFocus(false)
	SettingsWindowBackgroundB:SetNumeric(true)
	SettingsWindowBackgroundB:SetMaxLetters(3)
	SettingsWindowBackgroundB:SetMultiLine(false)
	SettingsWindowBackgroundB:EnableMouse(true)
	SettingsWindowBackgroundB:EnableKeyboard(true)
	SettingsWindowBackgroundB:SetFontObject("GameFontHighlight")
	SettingsWindowBackgroundB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	SettingsWindowBackgroundB:SetText(tostring(SettingsWindowBackgroundB1 * 255))
	SettingsWindowBackgroundB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundB:SetScript("OnTextChanged", function()
		local new = tonumber(SettingsWindowBackgroundB:GetText())
		if new == nil then
			SettingsWindowBackgroundB1 = 0
		elseif new > 254 then
			SettingsWindowBackgroundB1 = 1
		else
			SettingsWindowBackgroundB1 = new / 255
		end
		ProEnchantersOptions.Colors.SettingsWindowBackground = { SettingsWindowBackgroundR1, SettingsWindowBackgroundG1,
			SettingsWindowBackgroundB1 }
		local SettingsWindowBackgroundHex = RGBToWoWColorCode(SettingsWindowBackgroundR1, SettingsWindowBackgroundG1,
			SettingsWindowBackgroundB1)
		SettingsWindowBackgroundExample:SetText(SettingsWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local ScrollBarColorsHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	ScrollBarColorsHeader:SetFontObject(UIFontBasic)
	ScrollBarColorsHeader:SetPoint("TOPLEFT", SettingsWindowBackgroundHeader, "BOTTOMLEFT", 0, -25)
	ScrollBarColorsHeader:SetText("Scroll Bar Buttons")

	local ScrollBarColorsRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	ScrollBarColorsRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	ScrollBarColorsRBg:SetSize(34, 24)                                 -- Adjust size as needed
	ScrollBarColorsRBg:SetPoint("LEFT", ScrollBarColorsHeader, "RIGHT", 10, 0)

	local ScrollBarColorsR = CreateFrame("EditBox", nil, ColorsFrame)
	ScrollBarColorsR:SetSize(30, 20)
	ScrollBarColorsR:SetPoint("LEFT", ScrollBarColorsHeader, "RIGHT", 14, 0)
	ScrollBarColorsR:SetAutoFocus(false)
	ScrollBarColorsR:SetNumeric(true)
	ScrollBarColorsR:SetMaxLetters(3)
	ScrollBarColorsR:SetMultiLine(false)
	ScrollBarColorsR:EnableMouse(true)
	ScrollBarColorsR:EnableKeyboard(true)
	ScrollBarColorsR:SetFontObject("GameFontHighlight")
	ScrollBarColorsR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	ScrollBarColorsR:SetText(tostring(ScrollBarColorsR1 * 255))
	ScrollBarColorsR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	ScrollBarColorsR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	ScrollBarColorsR:SetScript("OnTextChanged", function()
		local new = tonumber(ScrollBarColorsR:GetText())
		if new == nil then
			ScrollBarColorsR1 = 0
		elseif new > 254 then
			ScrollBarColorsR1 = 1
		else
			ScrollBarColorsR1 = new / 255
		end
		ProEnchantersOptions.Colors.ScrollBarColors = { ScrollBarColorsR1, ScrollBarColorsG1, ScrollBarColorsB1 }
		local ScrollBarColorsHex = RGBToWoWColorCode(ScrollBarColorsR1, ScrollBarColorsG1, ScrollBarColorsB1)
		ScrollBarColorsExample:SetText(ScrollBarColorsHex .. "EXAMPLE" .. ColorClose)
	end)

	local ScrollBarColorsGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	ScrollBarColorsGBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	ScrollBarColorsGBg:SetSize(34, 24)                                 -- Adjust size as needed
	ScrollBarColorsGBg:SetPoint("LEFT", ScrollBarColorsR, "RIGHT", 10, 0)

	local ScrollBarColorsG = CreateFrame("EditBox", nil, ColorsFrame)
	ScrollBarColorsG:SetSize(30, 20)
	ScrollBarColorsG:SetPoint("LEFT", ScrollBarColorsR, "RIGHT", 14, 0)
	ScrollBarColorsG:SetAutoFocus(false)
	ScrollBarColorsG:SetNumeric(true)
	ScrollBarColorsG:SetMaxLetters(3)
	ScrollBarColorsG:SetMultiLine(false)
	ScrollBarColorsG:EnableMouse(true)
	ScrollBarColorsG:EnableKeyboard(true)
	ScrollBarColorsG:SetFontObject("GameFontHighlight")
	ScrollBarColorsG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	ScrollBarColorsG:SetText(tostring(ScrollBarColorsG1 * 255))
	ScrollBarColorsG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	ScrollBarColorsG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	ScrollBarColorsG:SetScript("OnTextChanged", function()
		local new = tonumber(ScrollBarColorsG:GetText())
		if new == nil then
			ScrollBarColorsG1 = 0
		elseif new > 254 then
			ScrollBarColorsG1 = 1
		else
			ScrollBarColorsG1 = new / 255
		end
		ProEnchantersOptions.Colors.ScrollBarColors = { ScrollBarColorsR1, ScrollBarColorsG1, ScrollBarColorsB1 }
		local ScrollBarColorsHex = RGBToWoWColorCode(ScrollBarColorsR1, ScrollBarColorsG1, ScrollBarColorsB1)
		ScrollBarColorsExample:SetText(ScrollBarColorsHex .. "EXAMPLE" .. ColorClose)
	end)

	local ScrollBarColorsBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	ScrollBarColorsBBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	ScrollBarColorsBBg:SetSize(34, 24)                                 -- Adjust size as needed
	ScrollBarColorsBBg:SetPoint("LEFT", ScrollBarColorsG, "RIGHT", 10, 0)

	local ScrollBarColorsB = CreateFrame("EditBox", nil, ColorsFrame)
	ScrollBarColorsB:SetSize(30, 20)
	ScrollBarColorsB:SetPoint("LEFT", ScrollBarColorsG, "RIGHT", 14, 0)
	ScrollBarColorsB:SetAutoFocus(false)
	ScrollBarColorsB:SetNumeric(true)
	ScrollBarColorsB:SetMaxLetters(3)
	ScrollBarColorsB:SetMultiLine(false)
	ScrollBarColorsB:EnableMouse(true)
	ScrollBarColorsB:EnableKeyboard(true)
	ScrollBarColorsB:SetFontObject("GameFontHighlight")
	ScrollBarColorsB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	ScrollBarColorsB:SetText(tostring(ScrollBarColorsB1 * 255))
	ScrollBarColorsB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	ScrollBarColorsB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	ScrollBarColorsB:SetScript("OnTextChanged", function()
		local new = tonumber(ScrollBarColorsB:GetText())
		if new == nil then
			ScrollBarColorsB1 = 0
		elseif new > 254 then
			ScrollBarColorsB1 = 1
		else
			ScrollBarColorsB1 = new / 255
		end
		ProEnchantersOptions.Colors.ScrollBarColors = { ScrollBarColorsR1, ScrollBarColorsG1, ScrollBarColorsB1 }
		local ScrollBarColorsHex = RGBToWoWColorCode(ScrollBarColorsR1, ScrollBarColorsG1, ScrollBarColorsB1)
		ScrollBarColorsExample:SetText(ScrollBarColorsHex .. "EXAMPLE" .. ColorClose)
	end)

	local OpacityAmountHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	OpacityAmountHeader:SetFontObject(UIFontBasic)
	OpacityAmountHeader:SetPoint("TOPLEFT", ScrollBarColorsHeader, "BOTTOMLEFT", 0, -25)
	OpacityAmountHeader:SetText("Opacity Amount for Transparent Colors")

	local OpacityAmountRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	OpacityAmountRBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	OpacityAmountRBg:SetSize(34, 24)                                 -- Adjust size as needed
	OpacityAmountRBg:SetPoint("LEFT", OpacityAmountHeader, "RIGHT", 10, 0)

	local OpacityAmountR = CreateFrame("EditBox", nil, ColorsFrame)
	OpacityAmountR:SetSize(30, 20)
	OpacityAmountR:SetPoint("LEFT", OpacityAmountHeader, "RIGHT", 14, 0)
	OpacityAmountR:SetAutoFocus(false)
	OpacityAmountR:SetNumeric(true)
	OpacityAmountR:SetMaxLetters(3)
	OpacityAmountR:SetMultiLine(false)
	OpacityAmountR:EnableMouse(true)
	OpacityAmountR:EnableKeyboard(true)
	OpacityAmountR:SetFontObject("GameFontHighlight")
	OpacityAmountR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	OpacityAmountR:SetText(tostring(OpacityAmountR1 * 100))
	OpacityAmountR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	OpacityAmountR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	OpacityAmountR:SetScript("OnTextChanged", function()
		local new = tonumber(OpacityAmountR:GetText())
		if new == nil then
			OpacityAmountR1 = 0
		elseif new > 99 then
			OpacityAmountR1 = 1
		else
			OpacityAmountR1 = new / 100
		end
		ProEnchantersOptions.Colors.OpacityAmount = OpacityAmountR1
	end)

	-- Create Bottom Bar	
	local closeBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(400, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOM", ColorsFrame, "BOTTOM", 0, 0)

	-- Create Color Theme Buttons
	local redTheme = CreateFrame("Button", nil, ColorsFrame)
	redTheme:SetPoint("BOTTOMLEFT", closeBg, "TOPLEFT", 20, 15)
	redTheme:SetText("Red")
	redTheme:SetSize(50, 25) -- Adjust size as needed
	local redThemeText = redTheme:GetFontString()
	redThemeText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	redTheme:SetNormalFontObject("GameFontHighlight")
	redTheme:SetHighlightFontObject("GameFontNormal")
	redTheme:SetScript("OnClick", function()
		TopBarColorR:SetText(tostring(100))
		TopBarColorG:SetText(tostring(2))
		TopBarColorB:SetText(tostring(2))
		SecondaryBarColorR:SetText(tostring(140))
		SecondaryBarColorG:SetText(tostring(48))
		SecondaryBarColorB:SetText(tostring(48))
		MainWindowBackgroundR:SetText(tostring(80))
		MainWindowBackgroundG:SetText(tostring(26))
		MainWindowBackgroundB:SetText(tostring(22))
		BottomBarColorR:SetText(tostring(80))
		BottomBarColorG:SetText(tostring(2))
		BottomBarColorB:SetText(tostring(2))
		EnchantsButtonColorR:SetText(tostring(80))
		EnchantsButtonColorG:SetText(tostring(2))
		EnchantsButtonColorB:SetText(tostring(2))
		EnchantsButtonColorInactiveR:SetText(tostring(70))
		EnchantsButtonColorInactiveG:SetText(tostring(70))
		EnchantsButtonColorInactiveB:SetText(tostring(70))
		BorderColorR:SetText(tostring(2))
		BorderColorG:SetText(tostring(2))
		BorderColorB:SetText(tostring(2))
		MainButtonColorR:SetText(tostring(100))
		MainButtonColorG:SetText(tostring(26))
		MainButtonColorB:SetText(tostring(22))
		SettingsWindowBackgroundR:SetText(tostring(140))
		SettingsWindowBackgroundG:SetText(tostring(48))
		SettingsWindowBackgroundB:SetText(tostring(50))
		ScrollBarColorsR:SetText(tostring(100))
		ScrollBarColorsG:SetText(tostring(2))
		ScrollBarColorsB:SetText(tostring(2))
		OpacityAmountR:SetText(tostring(50))
	end)

	local greenTheme = CreateFrame("Button", nil, ColorsFrame)
	greenTheme:SetPoint("LEFT", redTheme, "RIGHT", 10, 0)
	greenTheme:SetText("Green")
	greenTheme:SetSize(50, 25) -- Adjust size as needed
	local greenThemeText = greenTheme:GetFontString()
	greenThemeText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	greenTheme:SetNormalFontObject("GameFontHighlight")
	greenTheme:SetHighlightFontObject("GameFontNormal")
	greenTheme:SetScript("OnClick", function()
		TopBarColorR:SetText(tostring(2))
		TopBarColorG:SetText(tostring(100))
		TopBarColorB:SetText(tostring(2))
		SecondaryBarColorR:SetText(tostring(48))
		SecondaryBarColorG:SetText(tostring(140))
		SecondaryBarColorB:SetText(tostring(48))
		MainWindowBackgroundR:SetText(tostring(22))
		MainWindowBackgroundG:SetText(tostring(80))
		MainWindowBackgroundB:SetText(tostring(22))
		BottomBarColorR:SetText(tostring(2))
		BottomBarColorG:SetText(tostring(80))
		BottomBarColorB:SetText(tostring(2))
		EnchantsButtonColorR:SetText(tostring(2))
		EnchantsButtonColorG:SetText(tostring(80))
		EnchantsButtonColorB:SetText(tostring(2))
		EnchantsButtonColorInactiveR:SetText(tostring(70))
		EnchantsButtonColorInactiveG:SetText(tostring(70))
		EnchantsButtonColorInactiveB:SetText(tostring(70))
		BorderColorR:SetText(tostring(2))
		BorderColorG:SetText(tostring(2))
		BorderColorB:SetText(tostring(2))
		MainButtonColorR:SetText(tostring(22))
		MainButtonColorG:SetText(tostring(100))
		MainButtonColorB:SetText(tostring(22))
		SettingsWindowBackgroundR:SetText(tostring(50))
		SettingsWindowBackgroundG:SetText(tostring(140))
		SettingsWindowBackgroundB:SetText(tostring(50))
		ScrollBarColorsR:SetText(tostring(2))
		ScrollBarColorsG:SetText(tostring(100))
		ScrollBarColorsB:SetText(tostring(2))
		OpacityAmountR:SetText(tostring(50))
	end)

	local blueTheme = CreateFrame("Button", nil, ColorsFrame)
	blueTheme:SetPoint("LEFT", greenTheme, "RIGHT", 10, 0)
	blueTheme:SetText("Blue")
	blueTheme:SetSize(50, 25) -- Adjust size as needed
	local blueThemeText = blueTheme:GetFontString()
	blueThemeText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	blueTheme:SetNormalFontObject("GameFontHighlight")
	blueTheme:SetHighlightFontObject("GameFontNormal")
	blueTheme:SetScript("OnClick", function()
		TopBarColorR:SetText(tostring(2))
		TopBarColorG:SetText(tostring(2))
		TopBarColorB:SetText(tostring(100))
		SecondaryBarColorR:SetText(tostring(50))
		SecondaryBarColorG:SetText(tostring(50))
		SecondaryBarColorB:SetText(tostring(140))
		MainWindowBackgroundR:SetText(tostring(22))
		MainWindowBackgroundG:SetText(tostring(22))
		MainWindowBackgroundB:SetText(tostring(80))
		BottomBarColorR:SetText(tostring(2))
		BottomBarColorG:SetText(tostring(2))
		BottomBarColorB:SetText(tostring(80))
		EnchantsButtonColorR:SetText(tostring(2))
		EnchantsButtonColorG:SetText(tostring(2))
		EnchantsButtonColorB:SetText(tostring(80))
		EnchantsButtonColorInactiveR:SetText(tostring(70))
		EnchantsButtonColorInactiveG:SetText(tostring(70))
		EnchantsButtonColorInactiveB:SetText(tostring(70))
		BorderColorR:SetText(tostring(2))
		BorderColorG:SetText(tostring(2))
		BorderColorB:SetText(tostring(2))
		MainButtonColorR:SetText(tostring(22))
		MainButtonColorG:SetText(tostring(22))
		MainButtonColorB:SetText(tostring(100))
		SettingsWindowBackgroundR:SetText(tostring(50))
		SettingsWindowBackgroundG:SetText(tostring(50))
		SettingsWindowBackgroundB:SetText(tostring(140))
		ScrollBarColorsR:SetText(tostring(2))
		ScrollBarColorsG:SetText(tostring(2))
		ScrollBarColorsB:SetText(tostring(100))
		OpacityAmountR:SetText(tostring(50))
	end)

	local purpleTheme = CreateFrame("Button", nil, ColorsFrame)
	purpleTheme:SetPoint("LEFT", blueTheme, "RIGHT", 10, 0)
	purpleTheme:SetText("Purple")
	purpleTheme:SetSize(50, 25) -- Adjust size as needed
	local purpleThemeText = purpleTheme:GetFontString()
	purpleThemeText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	purpleTheme:SetNormalFontObject("GameFontHighlight")
	purpleTheme:SetHighlightFontObject("GameFontNormal")
	purpleTheme:SetScript("OnClick", function()
		TopBarColorR:SetText(tostring(50))
		TopBarColorG:SetText(tostring(0))
		TopBarColorB:SetText(tostring(50))
		SecondaryBarColorR:SetText(tostring(30))
		SecondaryBarColorG:SetText(tostring(0))
		SecondaryBarColorB:SetText(tostring(30))
		MainWindowBackgroundR:SetText(tostring(0))
		MainWindowBackgroundG:SetText(tostring(0))
		MainWindowBackgroundB:SetText(tostring(0))
		BottomBarColorR:SetText(tostring(30))
		BottomBarColorG:SetText(tostring(0))
		BottomBarColorB:SetText(tostring(30))
		EnchantsButtonColorR:SetText(tostring(70))
		EnchantsButtonColorG:SetText(tostring(0))
		EnchantsButtonColorB:SetText(tostring(70))
		EnchantsButtonColorInactiveR:SetText(tostring(20))
		EnchantsButtonColorInactiveG:SetText(tostring(20))
		EnchantsButtonColorInactiveB:SetText(tostring(20))
		BorderColorR:SetText(tostring(90))
		BorderColorG:SetText(tostring(0))
		BorderColorB:SetText(tostring(90))
		MainButtonColorR:SetText(tostring(90))
		MainButtonColorG:SetText(tostring(0))
		MainButtonColorB:SetText(tostring(90))
		SettingsWindowBackgroundR:SetText(tostring(20))
		SettingsWindowBackgroundG:SetText(tostring(0))
		SettingsWindowBackgroundB:SetText(tostring(20))
		ScrollBarColorsR:SetText(tostring(90))
		ScrollBarColorsG:SetText(tostring(0))
		ScrollBarColorsB:SetText(tostring(90))
		OpacityAmountR:SetText(tostring(80))
	end)

	local lightTheme = CreateFrame("Button", nil, ColorsFrame)
	lightTheme:SetPoint("LEFT", purpleTheme, "RIGHT", 10, 0)
	lightTheme:SetText("Light")
	lightTheme:SetSize(50, 25) -- Adjust size as needed
	local lightThemeText = lightTheme:GetFontString()
	lightThemeText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	lightTheme:SetNormalFontObject("GameFontHighlight")
	lightTheme:SetHighlightFontObject("GameFontNormal")
	lightTheme:SetScript("OnClick", function()
		TopBarColorR:SetText(tostring(160))
		TopBarColorG:SetText(tostring(160))
		TopBarColorB:SetText(tostring(160))
		SecondaryBarColorR:SetText(tostring(190))
		SecondaryBarColorG:SetText(tostring(190))
		SecondaryBarColorB:SetText(tostring(190))
		MainWindowBackgroundR:SetText(tostring(255))
		MainWindowBackgroundG:SetText(tostring(255))
		MainWindowBackgroundB:SetText(tostring(255))
		BottomBarColorR:SetText(tostring(140))
		BottomBarColorG:SetText(tostring(140))
		BottomBarColorB:SetText(tostring(140))
		EnchantsButtonColorR:SetText(tostring(160))
		EnchantsButtonColorG:SetText(tostring(160))
		EnchantsButtonColorB:SetText(tostring(160))
		EnchantsButtonColorInactiveR:SetText(tostring(70))
		EnchantsButtonColorInactiveG:SetText(tostring(70))
		EnchantsButtonColorInactiveB:SetText(tostring(70))
		BorderColorR:SetText(tostring(2))
		BorderColorG:SetText(tostring(2))
		BorderColorB:SetText(tostring(2))
		MainButtonColorR:SetText(tostring(160))
		MainButtonColorG:SetText(tostring(160))
		MainButtonColorB:SetText(tostring(160))
		SettingsWindowBackgroundR:SetText(tostring(190))
		SettingsWindowBackgroundG:SetText(tostring(190))
		SettingsWindowBackgroundB:SetText(tostring(190))
		ScrollBarColorsR:SetText(tostring(255))
		ScrollBarColorsG:SetText(tostring(255))
		ScrollBarColorsB:SetText(tostring(255))
		OpacityAmountR:SetText(tostring(50))
	end)

	local darkTheme = CreateFrame("Button", nil, ColorsFrame)
	darkTheme:SetPoint("LEFT", lightTheme, "RIGHT", 10, 0)
	darkTheme:SetText("Dark")
	darkTheme:SetSize(50, 25) -- Adjust size as needed
	local darkThemeText = darkTheme:GetFontString()
	darkThemeText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	darkTheme:SetNormalFontObject("GameFontHighlight")
	darkTheme:SetHighlightFontObject("GameFontNormal")
	darkTheme:SetScript("OnClick", function()
		TopBarColorR:SetText(tostring(25))
		TopBarColorG:SetText(tostring(25))
		TopBarColorB:SetText(tostring(25))
		SecondaryBarColorR:SetText(tostring(40))
		SecondaryBarColorG:SetText(tostring(40))
		SecondaryBarColorB:SetText(tostring(40))
		MainWindowBackgroundR:SetText(tostring(0))
		MainWindowBackgroundG:SetText(tostring(0))
		MainWindowBackgroundB:SetText(tostring(0))
		BottomBarColorR:SetText(tostring(10))
		BottomBarColorG:SetText(tostring(10))
		BottomBarColorB:SetText(tostring(10))
		EnchantsButtonColorR:SetText(tostring(25))
		EnchantsButtonColorG:SetText(tostring(25))
		EnchantsButtonColorB:SetText(tostring(25))
		EnchantsButtonColorInactiveR:SetText(tostring(0))
		EnchantsButtonColorInactiveG:SetText(tostring(0))
		EnchantsButtonColorInactiveB:SetText(tostring(0))
		BorderColorR:SetText(tostring(2))
		BorderColorG:SetText(tostring(2))
		BorderColorB:SetText(tostring(2))
		MainButtonColorR:SetText(tostring(25))
		MainButtonColorG:SetText(tostring(25))
		MainButtonColorB:SetText(tostring(25))
		SettingsWindowBackgroundR:SetText(tostring(40))
		SettingsWindowBackgroundG:SetText(tostring(40))
		SettingsWindowBackgroundB:SetText(tostring(40))
		ScrollBarColorsR:SetText(tostring(50))
		ScrollBarColorsG:SetText(tostring(50))
		ScrollBarColorsB:SetText(tostring(50))
		OpacityAmountR:SetText(tostring(75))
	end)

	-- Create Color Theme Bg's	
	local redBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	redBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	redBg:SetPoint("TOPLEFT", redTheme, "TOPLEFT", 0, 0)
	redBg:SetPoint("BOTTOMRIGHT", redTheme, "BOTTOMRIGHT", 0, 0)

	local greenBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	greenBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	greenBg:SetPoint("TOPLEFT", greenTheme, "TOPLEFT", 0, 0)
	greenBg:SetPoint("BOTTOMRIGHT", greenTheme, "BOTTOMRIGHT", 0, 0)

	local blueBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	blueBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	blueBg:SetPoint("TOPLEFT", blueTheme, "TOPLEFT", 0, 0)
	blueBg:SetPoint("BOTTOMRIGHT", blueTheme, "BOTTOMRIGHT", 0, 0)

	local purpleBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	purpleBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	purpleBg:SetPoint("TOPLEFT", purpleTheme, "TOPLEFT", 0, 0)
	purpleBg:SetPoint("BOTTOMRIGHT", purpleTheme, "BOTTOMRIGHT", 0, 0)

	local lightBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	lightBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	lightBg:SetPoint("TOPLEFT", lightTheme, "TOPLEFT", 0, 0)
	lightBg:SetPoint("BOTTOMRIGHT", lightTheme, "BOTTOMRIGHT", 0, 0)

	local darkBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	darkBg:SetColorTexture(unpack(MainButtonColorOpaque)) -- Set RGBA values for your preferred color and alpha
	darkBg:SetPoint("TOPLEFT", darkTheme, "TOPLEFT", 0, 0)
	darkBg:SetPoint("BOTTOMRIGHT", darkTheme, "BOTTOMRIGHT", 0, 0)


	-- Create a close button

	local closeButton = CreateFrame("Button", nil, ColorsFrame)
	closeButton:SetSize(50, 25)                                   -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0) -- Adjust position as needed
	closeButton:SetText("Close")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")
	closeButton:SetScript("OnClick", function()
		ColorsFrame:Hide()
	end)

	-- Create a reset button
	local resetButton = CreateFrame("Button", nil, ColorsFrame)
	resetButton:SetSize(90, 25)                                      -- Adjust size as needed
	resetButton:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0) -- Adjust position as needed
	resetButton:SetText("Reset to Default")
	local resetButtonText = resetButton:GetFontString()
	resetButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	resetButton:SetNormalFontObject("GameFontHighlight")
	resetButton:SetHighlightFontObject("GameFontNormal")
	resetButton:SetScript("OnClick", function()
		TopBarColorR:SetText(tostring(22))
		TopBarColorG:SetText(tostring(26))
		TopBarColorB:SetText(tostring(48))
		SecondaryBarColorR:SetText(tostring(49))
		SecondaryBarColorG:SetText(tostring(48))
		SecondaryBarColorB:SetText(tostring(77))
		MainWindowBackgroundR:SetText(tostring(22))
		MainWindowBackgroundG:SetText(tostring(26))
		MainWindowBackgroundB:SetText(tostring(48))
		BottomBarColorR:SetText(tostring(22))
		BottomBarColorG:SetText(tostring(26))
		BottomBarColorB:SetText(tostring(48))
		EnchantsButtonColorR:SetText(tostring(22))
		EnchantsButtonColorG:SetText(tostring(26))
		EnchantsButtonColorB:SetText(tostring(48))
		EnchantsButtonColorInactiveR:SetText(tostring(70))
		EnchantsButtonColorInactiveG:SetText(tostring(70))
		EnchantsButtonColorInactiveB:SetText(tostring(70))
		BorderColorR:SetText(tostring(2))
		BorderColorG:SetText(tostring(2))
		BorderColorB:SetText(tostring(2))
		MainButtonColorR:SetText(tostring(22))
		MainButtonColorG:SetText(tostring(26))
		MainButtonColorB:SetText(tostring(48))
		SettingsWindowBackgroundR:SetText(tostring(49))
		SettingsWindowBackgroundG:SetText(tostring(48))
		SettingsWindowBackgroundB:SetText(tostring(77))
		ScrollBarColorsR:SetText(tostring(22))
		ScrollBarColorsG:SetText(tostring(26))
		ScrollBarColorsB:SetText(tostring(48))
		OpacityAmountR:SetText(tostring(50))
	end)

	-- Help Reminder
	local helpReminderHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject(UIFontBasic)
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 6)
	helpReminderHeader:SetText(STEELBLUE .. "Thanks for using Pro Enchanters!" .. ColorClose)

	return ColorsFrame
end

function ProEnchantersCreateSoundsFrame()
	local SoundsFrame = CreateFrame("Frame", "ProEnchantersSoundsFrame", UIParent, "BackdropTemplate")
	SoundsFrame:SetFrameStrata("FULLSCREEN")
	SoundsFrame:SetSize(800, 350) -- Adjust height as needed
	SoundsFrame:SetPoint("TOP", 0, -300)
	SoundsFrame:SetMovable(true)
	SoundsFrame:EnableMouse(true)
	SoundsFrame:RegisterForDrag("LeftButton")
	SoundsFrame:SetScript("OnDragStart", SoundsFrame.StartMoving)
	SoundsFrame:SetScript("OnDragStop", function()
		SoundsFrame:StopMovingOrSizing()
	end)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	SoundsFrame:SetBackdrop(backdrop)
	SoundsFrame:SetBackdropBorderColor(unpack(BorderColorOpaque))
	SoundsFrame:Hide()

	-- Create a full background texture
	local bgTexture = SoundsFrame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(SettingsWindowBackgroundOpaque)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(800, 325)
	bgTexture:SetPoint("TOP", SoundsFrame, "TOP", 0, -25)

	-- Create a title background
	local titleBg = SoundsFrame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(800, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOP", SoundsFrame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = SoundsFrame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject(UIFontBasic)
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Sound Settings")

	local InstructionsHeader = SoundsFrame:CreateFontString(nil, "OVERLAY")
	InstructionsHeader:SetFontObject(UIFontBasic)
	InstructionsHeader:SetPoint("TOP", titleBg, "BOTTOM", 0, -10)
	InstructionsHeader:SetText(DARKORANGE .. "All sounds are played through the 'Master' channel." .. ColorClose)

	local PartyJoinHeader = SoundsFrame:CreateFontString(nil, "OVERLAY")
	PartyJoinHeader:SetFontObject(UIFontBasic)
	PartyJoinHeader:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 85, -40)
	PartyJoinHeader:SetText("Party Join Sound")

	-- Work While Closed Checkbox
	local EnablePartyJoinSoundCb = CreateFrame("CheckButton", nil, SoundsFrame, "ChatConfigCheckButtonTemplate")
	EnablePartyJoinSoundCb:SetPoint("LEFT", PartyJoinHeader, "RIGHT", 10, 0)
	EnablePartyJoinSoundCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	EnablePartyJoinSoundCb:SetHitRectInsets(0, 0, 0, 0)
	EnablePartyJoinSoundCb:SetChecked(ProEnchantersOptions["EnablePartyJoinSound"])
	EnablePartyJoinSoundCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["EnablePartyJoinSound"] = self:GetChecked()
	end)

	local PotentialCustomerHeader = SoundsFrame:CreateFontString(nil, "OVERLAY")
	PotentialCustomerHeader:SetFontObject(UIFontBasic)
	PotentialCustomerHeader:SetPoint("LEFT", PartyJoinHeader, "RIGHT", 150, 0)
	PotentialCustomerHeader:SetText("Potential Customer Sound")

	-- Work While Closed Checkbox
	local EnablePotentialCustomerSoundCb = CreateFrame("CheckButton", nil, SoundsFrame, "ChatConfigCheckButtonTemplate")
	EnablePotentialCustomerSoundCb:SetPoint("LEFT", PotentialCustomerHeader, "RIGHT", 10, 0)
	EnablePotentialCustomerSoundCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	EnablePotentialCustomerSoundCb:SetHitRectInsets(0, 0, 0, 0)
	EnablePotentialCustomerSoundCb:SetChecked(ProEnchantersOptions["EnablePotentialCustomerSound"])
	EnablePotentialCustomerSoundCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["EnablePotentialCustomerSound"] = self:GetChecked()
	end)

	local NewTradeHeader = SoundsFrame:CreateFontString(nil, "OVERLAY")
	NewTradeHeader:SetFontObject(UIFontBasic)
	NewTradeHeader:SetPoint("LEFT", PotentialCustomerHeader, "RIGHT", 150, 0)
	NewTradeHeader:SetText("New Trade Sound")

	-- Work While Closed Checkbox
	local EnableNewTradeSoundCb = CreateFrame("CheckButton", nil, SoundsFrame, "ChatConfigCheckButtonTemplate")
	EnableNewTradeSoundCb:SetPoint("LEFT", NewTradeHeader, "RIGHT", 10, 0)
	EnableNewTradeSoundCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	EnableNewTradeSoundCb:SetHitRectInsets(0, 0, 0, 0)
	EnableNewTradeSoundCb:SetChecked(ProEnchantersOptions["EnableNewTradeSound"])
	EnableNewTradeSoundCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["EnableNewTradeSound"] = self:GetChecked()
	end)

	-- Create drop down selector for sound

	local allSounds = LSM:List('sound')
	--[[for i, v in ipairs(allSounds) do
	print(tostring(i) .. " index is: " .. tostring(v))
	end]]

	local defaultValPartyJoin = ProEnchantersOptions["PartyJoinSound"]

	local partyjoin_opts = {
		['name'] = 'partyjoinsound',
		['parent'] = SoundsFrame,
		['title'] = defaultValPartyJoin,
		['items'] = allSounds,
		['defaultVal'] = defaultValPartyJoin,
		['changeFunc'] = function(dropdown_frame, dropdown_val)
			ProEnchantersOptions["PartyJoinSound"] = dropdown_val
			PESound(ProEnchantersOptions["PartyJoinSound"])
		end
	}

	local PartyJoinDD = createScrollableDropdown(partyjoin_opts)
	PartyJoinDD:SetPoint("TOP", PartyJoinHeader, "BOTTOM", -20, -5)

	local defaultValPotentialCustomer = ProEnchantersOptions["PotentialCustomerSound"]

	local potentialcustomer_opts = {
		['name'] = 'partyjoinsound',
		['parent'] = SoundsFrame,
		['title'] = defaultValPotentialCustomer,
		['items'] = allSounds,
		['defaultVal'] = defaultValPotentialCustomer,
		['changeFunc'] = function(dropdown_frame, dropdown_val)
			ProEnchantersOptions["PotentialCustomerSound"] = dropdown_val
			PESound(ProEnchantersOptions["PotentialCustomerSound"])
		end
	}

	local PotentialCustomerDD = createScrollableDropdown(potentialcustomer_opts)
	PotentialCustomerDD:SetPoint("TOP", PotentialCustomerHeader, "BOTTOM", -20, -5)

	local defaultValNewTrade = ProEnchantersOptions["NewTradeSound"]

	local newtrade_opts = {
		['name'] = 'newtradesound',
		['parent'] = SoundsFrame,
		['title'] = defaultValNewTrade,
		['items'] = allSounds,
		['defaultVal'] = defaultValNewTrade,
		['changeFunc'] = function(dropdown_frame, dropdown_val)
			ProEnchantersOptions["NewTradeSound"] = dropdown_val
			PESound(ProEnchantersOptions["NewTradeSound"])
		end
	}

	local NewTradeDD = createScrollableDropdown(newtrade_opts)
	NewTradeDD:SetPoint("TOP", NewTradeHeader, "BOTTOM", -20, -5)


	-- Create a close button background
	local closeBg = SoundsFrame:CreateTexture(nil, "OVERLAY")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(800, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOMLEFT", SoundsFrame, "BOTTOMLEFT", 0, 0)


	local closeButton2 = CreateFrame("Button", nil, SoundsFrame)
	closeButton2:SetSize(50, 25)                                   -- Adjust size as needed
	closeButton2:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0) -- Adjust position as needed
	closeButton2:SetText("Close")
	local closeButtonText2 = closeButton2:GetFontString()
	closeButtonText2:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton2:SetNormalFontObject("GameFontHighlight")
	closeButton2:SetHighlightFontObject("GameFontNormal")
	closeButton2:SetScript("OnClick", function()
		SoundsFrame:Hide()
		ProEnchantersOptionsFrame:Show()
	end)

	-- Help Reminder
	local helpReminderHeader = SoundsFrame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject(UIFontBasic)
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 5)
	helpReminderHeader:SetText(STEELBLUE .. "Thanks for using Pro Enchanters!" .. ColorClose)

	-- SoundsFrame On Show Script
	SoundsFrame:SetScript("OnShow", function()
	end)

	SoundsFrame:SetScript("OnHide", function()
	end)

	return SoundsFrame
end

function SetSupportersEditBox()
	local line = ""
	for _, name in ipairs(PESupporters) do
		if line ~= "" then
			line = line .. ", " .. DARKGOLDENROD .. name .. ColorClose
		else
			line = DARKGOLDENROD .. name .. ColorClose
		end
	end
	return line
end

function SetTriggerEditBox()
	local concatTriggers = ""
	for _, word in ipairs(ProEnchantersOptions.triggerwords) do
		if word ~= "" then
			if concatTriggers ~= "" then
				concatTriggers = concatTriggers .. ", " .. word
			else
				concatTriggers = word
			end
		end
	end
	return concatTriggers
end

function SetInvEditBox()
	local concatTriggers = ""
	for _, word in ipairs(ProEnchantersOptions.invwords) do
		if word ~= "" then
			if concatTriggers ~= "" then
				concatTriggers = concatTriggers .. ", " .. word
			else
				concatTriggers = word
			end
		end
	end
	return concatTriggers
end

function SetFilteredEditBox()
	local concatFilters = ""
	for _, word in ipairs(ProEnchantersOptions.filteredwords) do
		if word ~= "" then
			if concatFilters ~= "" then
				concatFilters = concatFilters .. ", " .. word
			else
				concatFilters = word
			end
		end
	end
	return concatFilters
end

function ResetTriggers()
	ProEnchantersOptions.triggerwords = {}
	for _, word in ipairs(PETriggerWordsOriginal) do
		table.insert(ProEnchantersOptions.triggerwords, word)
	end
end

function ResetInvs()
	ProEnchantersOptions.invwords = {}
	for _, word in ipairs(PEInvWordsOriginal) do
		table.insert(ProEnchantersOptions.invwords, word)
	end
end

function ResetFiltered()
	ProEnchantersOptions.filteredwords = {}
	for _, word in ipairs(PEFilteredWordsOriginal) do
		table.insert(ProEnchantersOptions.filteredwords, word)
	end
end

function ProEnchantersCreateTriggersFrame()
	local TriggersFrame = CreateFrame("Frame", "ProEnchantersTriggersFrame", UIParent, "BackdropTemplate")
	TriggersFrame:SetFrameStrata("FULLSCREEN")
	TriggersFrame:SetSize(800, 350) -- Adjust height as needed
	TriggersFrame:SetPoint("TOP", 0, -300)
	TriggersFrame:SetMovable(true)
	TriggersFrame:EnableMouse(true)
	TriggersFrame:RegisterForDrag("LeftButton")
	TriggersFrame:SetScript("OnDragStart", TriggersFrame.StartMoving)
	TriggersFrame:SetScript("OnDragStop", function()
		TriggersFrame:StopMovingOrSizing()
	end)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	TriggersFrame:SetBackdrop(backdrop)
	TriggersFrame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	TriggersFrame:Hide()

	-- Create a full background texture
	local bgTexture = TriggersFrame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(SettingsWindowBackgroundOpaque)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(800, 325)
	bgTexture:SetPoint("TOP", TriggersFrame, "TOP", 0, -25)

	-- Create a title background
	local titleBg = TriggersFrame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(800, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOP", TriggersFrame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = TriggersFrame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject(UIFontBasic)
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Triggers and Filters")

	local InstructionsHeader = TriggersFrame:CreateFontString(nil, "OVERLAY")
	InstructionsHeader:SetFontObject(UIFontBasic)
	InstructionsHeader:SetPoint("TOPLEFT", titleBg, "TOPLEFT", 90, -30)
	InstructionsHeader:SetText(
		"Add words below separated by commas to enable new trigger words for the auto invites or words that will filter others messages.\nYou can also set players names in the Filter section to filter that player from triggering the auto invite.\nMake sure words or phrases to filter are in lower case and player names start with a Capital letter.")

	local FilteredWordsHeader = TriggersFrame:CreateFontString(nil, "OVERLAY")
	FilteredWordsHeader:SetFontObject(UIFontBasic)
	FilteredWordsHeader:SetPoint("TOPLEFT", InstructionsHeader, "TOPLEFT", -70, -55)
	FilteredWordsHeader:SetText("Filtered Words:")

	-- Create a close button background
	local FilteredScrollBg = TriggersFrame:CreateTexture(nil, "OVERLAY")
	FilteredScrollBg:SetSize(610, 80)
	FilteredScrollBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	FilteredScrollBg:SetPoint("TOPLEFT", FilteredWordsHeader, "TOPRIGHT", 15, 5)

	local FilteredScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersFilteredScrollFrame", TriggersFrame,
		"UIPanelScrollFrameTemplate")
	FilteredScrollFrame:SetSize(602, 72)
	FilteredScrollFrame:SetPoint("TOPLEFT", FilteredScrollBg, "TOPLEFT", 4, -4)

	local scrollChild = CreateFrame("Frame", nil, FilteredScrollFrame)
	scrollChild:SetSize(602, 70) -- Adjust height dynamically based on content
	FilteredScrollFrame:SetScrollChild(scrollChild)

	local scrollBar = FilteredScrollFrame.ScrollBar
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	--thumbTexture:SetColorTexture(0.3, 0.1, 0.4, 0.8)
	local upButton = scrollBar.ScrollUpButton
	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)
	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton
	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	-- Create an EditBox for Filtered Words
	local FilteredWordsEditBox = CreateFrame("EditBox", "ProEnchantersFilteredWordsEditBox", scrollChild)

	FilteredWordsEditBox:SetSize(602, 20)
	FilteredWordsEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
	FilteredWordsEditBox:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMRIGHT", 0, 0)
	FilteredWordsEditBox:SetAutoFocus(false)
	FilteredWordsEditBox:SetMultiLine(true)
	FilteredWordsEditBox:EnableMouse(true)
	FilteredWordsEditBox:SetFontObject("GameFontHighlight")
	FilteredWordsEditBox:SetText(SetFilteredEditBox())
	FilteredWordsEditBox:SetScript("OnTextChanged", function()
		scrollChild:SetHeight(FilteredWordsEditBox:GetHeight())
	end)
	FilteredWordsEditBox:SetScript("OnEnterPressed", function()
		local newFiltered = FilteredWordsEditBox:GetText()
		if newFiltered == "" then
			newFiltered = "potential customer filters disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.filteredwords = {}
		for word in newFiltered:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.filteredwords, word)
		end
		FilteredWordsEditBox:ClearFocus()
	end)
	FilteredWordsEditBox:SetScript("OnEscapePressed", function()
		local newFiltered = FilteredWordsEditBox:GetText()
		if newFiltered == "" then
			newFiltered = "potential customer filters disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.filteredwords = {}
		for word in newFiltered:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.filteredwords, word)
		end
		FilteredWordsEditBox:ClearFocus()
	end)


	local TriggerWordsHeader = TriggersFrame:CreateFontString(nil, "OVERLAY")
	TriggerWordsHeader:SetFontObject(UIFontBasic)
	TriggerWordsHeader:SetPoint("TOPLEFT", InstructionsHeader, "TOPLEFT", -70, -155)
	TriggerWordsHeader:SetText("Trigger Words:")

	-- Create a close button background
	local TriggerScrollBg = TriggersFrame:CreateTexture(nil, "OVERLAY")
	TriggerScrollBg:SetSize(610, 60)
	TriggerScrollBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	TriggerScrollBg:SetPoint("TOP", FilteredScrollFrame, "BOTTOM", 0, -25)

	local TriggerScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersFilteredScrollFrame", TriggersFrame,
		"UIPanelScrollFrameTemplate")
	TriggerScrollFrame:SetSize(602, 52)
	TriggerScrollFrame:SetPoint("TOPLEFT", TriggerScrollBg, "TOPLEFT", 4, -4)

	local scrollChild2 = CreateFrame("Frame", nil, TriggerScrollFrame)
	scrollChild2:SetSize(602, 50) -- Adjust height dynamically based on content
	TriggerScrollFrame:SetScrollChild(scrollChild2)

	local scrollBar2 = TriggerScrollFrame.ScrollBar
	local thumbTexture2 = scrollBar2:GetThumbTexture()
	thumbTexture2:SetTexture(nil) -- Clear existing texture
	--thumbTexture:SetColorTexture(0.3, 0.1, 0.4, 0.8)
	local upButton2 = scrollBar2.ScrollUpButton
	-- Clear existing textures
	upButton2:GetNormalTexture():SetTexture(nil)
	upButton2:GetPushedTexture():SetTexture(nil)
	upButton2:GetDisabledTexture():SetTexture(nil)
	upButton2:GetHighlightTexture():SetTexture(nil)
	-- Repeat for Scroll Down Button
	local downButton2 = scrollBar2.ScrollDownButton
	-- Clear existing textures
	downButton2:GetNormalTexture():SetTexture(nil)
	downButton2:GetPushedTexture():SetTexture(nil)
	downButton2:GetDisabledTexture():SetTexture(nil)
	downButton2:GetHighlightTexture():SetTexture(nil)

	-- Create an EditBox for Filtered Words
	local TriggerWordsEditBox = CreateFrame("EditBox", "ProEnchantersTriggerWordsEditBox", scrollChild2)
	TriggerWordsEditBox:SetSize(602, 20)
	TriggerWordsEditBox:SetPoint("TOPLEFT", scrollChild2, "TOPLEFT", 0, 0)
	TriggerWordsEditBox:SetPoint("BOTTOMRIGHT", scrollChild2, "BOTTOMRIGHT", 0, 0)
	TriggerWordsEditBox:SetAutoFocus(false)
	TriggerWordsEditBox:SetMultiLine(true)
	TriggerWordsEditBox:EnableMouse(true)
	TriggerWordsEditBox:SetFontObject("GameFontHighlight")
	TriggerWordsEditBox:SetText(SetTriggerEditBox())
	TriggerWordsEditBox:SetScript("OnTextChanged", function()
		scrollChild2:SetHeight(TriggerWordsEditBox:GetHeight())
	end)
	TriggerWordsEditBox:SetScript("OnEnterPressed", function()
		local newTriggers = TriggerWordsEditBox:GetText()
		if newTriggers == "" then
			newTriggers = "potential customer triggers disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.triggerwords = {}
		for word in newTriggers:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.triggerwords, word)
		end
		TriggerWordsEditBox:ClearFocus()
	end)
	TriggerWordsEditBox:SetScript("OnEscapePressed", function()
		local newTriggers = TriggerWordsEditBox:GetText()
		if newTriggers == "" then
			newTriggers = "potential customer triggers disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.triggerwords = {}
		for word in newTriggers:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.triggerwords, word)
		end
		TriggerWordsEditBox:ClearFocus()
	end)

	local InvWordsHeader = TriggersFrame:CreateFontString(nil, "OVERLAY")
	InvWordsHeader:SetFontObject(UIFontBasic)
	InvWordsHeader:SetPoint("TOPLEFT", InstructionsHeader, "TOPLEFT", -70, -235)
	InvWordsHeader:SetText("Inv Words:")

	-- Create a close button background
	local InvScrollBg = TriggersFrame:CreateTexture(nil, "OVERLAY")
	InvScrollBg:SetSize(610, 40)
	InvScrollBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	InvScrollBg:SetPoint("TOP", TriggerScrollFrame, "BOTTOM", 0, -25)

	local InvScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersInvScrollFrame", TriggersFrame,
		"UIPanelScrollFrameTemplate")
	InvScrollFrame:SetSize(602, 32)
	InvScrollFrame:SetPoint("TOPLEFT", InvScrollBg, "TOPLEFT", 4, -4)

	local scrollChild3 = CreateFrame("Frame", nil, InvScrollFrame)
	scrollChild3:SetSize(602, 30) -- Adjust height dynamically based on content
	InvScrollFrame:SetScrollChild(scrollChild3)

	local scrollBar2 = InvScrollFrame.ScrollBar
	local thumbTexture2 = scrollBar2:GetThumbTexture()
	thumbTexture2:SetTexture(nil) -- Clear existing texture
	--thumbTexture:SetColorTexture(0.3, 0.1, 0.4, 0.8)
	local upButton2 = scrollBar2.ScrollUpButton
	-- Clear existing textures
	upButton2:GetNormalTexture():SetTexture(nil)
	upButton2:GetPushedTexture():SetTexture(nil)
	upButton2:GetDisabledTexture():SetTexture(nil)
	upButton2:GetHighlightTexture():SetTexture(nil)
	-- Repeat for Scroll Down Button
	local downButton2 = scrollBar2.ScrollDownButton
	-- Clear existing textures
	downButton2:GetNormalTexture():SetTexture(nil)
	downButton2:GetPushedTexture():SetTexture(nil)
	downButton2:GetDisabledTexture():SetTexture(nil)
	downButton2:GetHighlightTexture():SetTexture(nil)

	-- Create an EditBox for Filtered Words
	local InvWordsEditBox = CreateFrame("EditBox", "ProEnchantersInvWordsEditBox", scrollChild3)
	InvWordsEditBox:SetSize(602, 20)
	InvWordsEditBox:SetPoint("TOPLEFT", scrollChild3, "TOPLEFT", 0, 0)
	InvWordsEditBox:SetPoint("BOTTOMRIGHT", scrollChild3, "BOTTOMRIGHT", 0, 0)
	InvWordsEditBox:SetAutoFocus(false)
	InvWordsEditBox:SetMultiLine(true)
	InvWordsEditBox:EnableMouse(true)
	InvWordsEditBox:SetFontObject("GameFontHighlight")
	InvWordsEditBox:SetText(SetInvEditBox())
	InvWordsEditBox:SetScript("OnTextChanged", function()
		scrollChild3:SetHeight(InvWordsEditBox:GetHeight())
	end)
	InvWordsEditBox:SetScript("OnEnterPressed", function()
		local newInvs = InvWordsEditBox:GetText()
		if newInvs == "" then
			newInvs = "whisper invites disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.invwords = {}
		for word in newInvs:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.invwords, word)
		end
		InvWordsEditBox:ClearFocus()
	end)
	InvWordsEditBox:SetScript("OnEscapePressed", function()
		local newInvs = InvWordsEditBox:GetText()
		if newInvs == "" then
			newInvs = "whisper invites disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.invwords = {}
		for word in newInvs:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.invwords, word)
		end
		InvWordsEditBox:ClearFocus()
	end)

	-- Create a close button background
	local closeBg = TriggersFrame:CreateTexture(nil, "OVERLAY")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(800, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOMLEFT", TriggersFrame, "BOTTOMLEFT", 0, 0)


	-- Create a reset button at the bottom
	local resetButton2 = CreateFrame("Button", nil, TriggersFrame)
	resetButton2:SetSize(150, 25)                                     -- Adjust size as needed
	resetButton2:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0) -- Adjust position as needed
	resetButton2:SetText("Reset Triggers and Filters?")
	local resetButtonText2 = resetButton2:GetFontString()
	resetButtonText2:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	resetButton2:SetNormalFontObject("GameFontHighlight")
	resetButton2:SetHighlightFontObject("GameFontNormal")
	resetButton2:SetScript("OnClick", function()
		ResetTriggers()
		ResetFiltered()
		ResetInvs()
		TriggerWordsEditBox:SetText(SetTriggerEditBox())
		FilteredWordsEditBox:SetText(SetFilteredEditBox())
		InvWordsEditBox:SetText(SetInvEditBox())
	end)


	local closeButton2 = CreateFrame("Button", nil, TriggersFrame)
	closeButton2:SetSize(50, 25)                                   -- Adjust size as needed
	closeButton2:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0) -- Adjust position as needed
	closeButton2:SetText("Close")
	local closeButtonText2 = closeButton2:GetFontString()
	closeButtonText2:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton2:SetNormalFontObject("GameFontHighlight")
	closeButton2:SetHighlightFontObject("GameFontNormal")
	closeButton2:SetScript("OnClick", function()
		local newTriggers = TriggerWordsEditBox:GetText()
		if newTriggers == "" then
			newTriggers = "potential customer triggers disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.triggerwords = {}
		for word in newTriggers:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.triggerwords, word)
		end
		local newFiltered = FilteredWordsEditBox:GetText()
		if newFiltered == "" then
			newFiltered = "potential customer filters disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.filteredwords = {}
		for word in newFiltered:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.filteredwords, word)
		end
		local newInvs = InvWordsEditBox:GetText()
		if newInvs == "" then
			newInvs = "whisper invites disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.invwords = {}
		for word in newInvs:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.invwords, word)
		end
		TriggersFrame:Hide()
		ProEnchantersOptionsFrame:Show()
	end)

	-- Help Reminder
	local helpReminderHeader = TriggersFrame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject(UIFontBasic)
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 5)
	helpReminderHeader:SetText(STEELBLUE .. "Thanks for using Pro Enchanters!" .. ColorClose)

	-- TriggersFrame On Show Script
	TriggersFrame:SetScript("OnShow", function()
		TriggerWordsEditBox:SetText(SetTriggerEditBox())
		FilteredWordsEditBox:SetText(SetFilteredEditBox())
	end)

	TriggersFrame:SetScript("OnHide", function()
		local newTriggers = TriggerWordsEditBox:GetText()
		if newTriggers == "" then
			newTriggers = "potential customer triggers disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.triggerwords = {}
		for word in newTriggers:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.triggerwords, word)
		end
		local newFiltered = FilteredWordsEditBox:GetText()
		if newFiltered == "" then
			newFiltered = "potential customer filters disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.filteredwords = {}
		for word2 in newFiltered:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word2 = word2:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.filteredwords, word2)
		end
		local newInvs = InvWordsEditBox:GetText()
		if newInvs == "" then
			newInvs = "whisper invites disabled - remove this sentence and add a word to re-enable"
		end
		ProEnchantersOptions.invwords = {}
		for word in newInvs:gmatch("[^,]+") do
			-- Trim spaces from the beginning and end of the item
			word = word:match("^%s*(.-)%s*$")
			table.insert(ProEnchantersOptions.invwords, word)
		end
		InvWordsEditBox:ClearFocus()
	end)

	return TriggersFrame
end

function ProEnchantersCreateWhisperTriggersFrame()
	local frame = CreateFrame("Frame", "ProEnchantersWhisperTriggersFrame", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("FULLSCREEN")
	frame:SetSize(800, 350) -- Adjust height as needed
	frame:SetPoint("TOP", 0, -300)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
	end)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	frame:SetBackdrop(backdrop)
	frame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	frame:Hide()

	-- Create a full background texture
	local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(SettingsWindowBackgroundOpaque)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(800, 325)
	bgTexture:SetPoint("TOP", frame, "TOP", 0, -25)

	-- Create a title background
	local titleBg = frame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(800, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOP", frame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = frame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject(UIFontBasic)
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Whisper Trigger Commands")


	-- Scroll frame setup...
	local WhisperTriggerScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersOptionsScrollFrame", frame,
		"UIPanelScrollFrameTemplate")
	WhisperTriggerScrollFrame:SetSize(775, 300)
	WhisperTriggerScrollFrame:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 1, 0)

	--Create a scroll background
	local scrollBg = frame:CreateTexture(nil, "ARTWORK")
	scrollBg:SetColorTexture(unpack(ButtonDisabled)) -- Set RGBA values for your preferred color and alpha
	scrollBg:SetSize(20, 300)                     -- Adjust size as needed
	scrollBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -25)

	-- Access the Scroll Bar
	local scrollBar = WhisperTriggerScrollFrame.ScrollBar

	-- Customize Thumb Texture
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	thumbTexture:SetColorTexture(unpack(ButtonStandardAndThumb))
	thumbTexture:SetSize(18, 27)
	--thumbTexture:SetAllPoints(thumbTexture)

	-- Customize Scroll Up Button Textures
	local upButton = scrollBar.ScrollUpButton

	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)

	-- Customize Scroll Up Button Textures with Solid Colors
	local upButton = scrollBar.ScrollUpButton

	-- Set colors
	upButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Replace RGBA values as needed
	upButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Replace RGBA values as needed
	upButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Replace RGBA values as needed
	upButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Replace RGBA values as needed

	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton

	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	-- Set colors
	downButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Adjust colors as needed
	downButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Adjust colors as needed
	downButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Adjust colors as needed
	downButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Adjust colors as needed

	local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	upButtonText:SetText("-")                              -- Set the text for the up button
	upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

	local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	downButtonText:SetText("-")                                -- Set the text for the down button
	downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed


	-- Scroll child frame where elements are actually placed
	local ScrollChild = CreateFrame("Frame")
	ScrollChild:SetSize(800, 300) -- Adjust height based on the number of elements
	WhisperTriggerScrollFrame:SetScrollChild(ScrollChild)

	-- Scroll child items below

	-- Create a title for Options

	local InstructionsHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	InstructionsHeader:SetFontObject(UIFontBasic)
	InstructionsHeader:SetPoint("TOP", ScrollChild, "TOP", 0, -10)
	InstructionsHeader:SetText(DARKORANGE ..
		"Add !commands and their responses below, hit enter on a line to save the line.\nBoth lines must have information. Commands do have to start with a ! to work.\nResponses need to be under 256 characters to fit within WoW's character limitations, character counter is on the right beside each line.\nYou can include item links in your message by adding the items ID encased in [], example: [11083] will return as Soul Dust (max 5 item links in a message)\nLook up item ID's on wowhead, soul dust as an example: https://www.wowhead.com/classic/item=" ..
		ColorClose ..
		YELLOWGREEN ..
		11083 ..
		ColorClose ..
		DARKORANGE ..
		"/soul-dust\nTo modify a command, change either its command box and hit enter or its response box and hit enter.\nTo delete a line, delete BOTH fields before hitting enter, blank commands with blank responses are removed.\nPlayer's can also whisper you for the required mats by whispering you the !enchant, it must match the enchant name exactly.\nExample - Player whispers: !enchant boots - stamina" ..
		ColorClose)

	-- Create a reset button at the bottom
	local hideButton = CreateFrame("Button", nil, ScrollChild)
	hideButton:SetSize(100, 25)                                  -- Adjust size as needed
	hideButton:SetPoint("TOP", InstructionsHeader, "BOTTOM", 0, -2) -- Adjust position as needed
	hideButton:SetText(GRAY .. "Hide Instructions" .. ColorClose)
	local hideButtonText = hideButton:GetFontString()
	hideButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	hideButton:SetNormalFontObject("GameFontHighlight")
	hideButton:SetHighlightFontObject("GameFontNormal")
	local hideButtonStatus = false
	hideButton:SetScript("OnClick", function()
		if hideButtonStatus == true then
			hideButtonStatus = false
			hideButton:SetText(GRAY .. "Hide Instructions" .. ColorClose)
			InstructionsHeader:SetText(DARKORANGE ..
				"Add !commands and their responses below, hit enter on a line to save the line.\nBoth lines must have information. Commands do have to start with a ! to work.\nResponses need to be under 250 characters to fit within WoW's character limitations, character counter is on the right beside each line.\nYou can include item links in your message by adding the items ID encased in [], example: [11083] will return as Soul Dust (max 5 item links in a message)\nLook up item ID's on wowhead, soul dust as an example: https://www.wowhead.com/classic/item=" ..
				ColorClose ..
				YELLOWGREEN ..
				11083 ..
				ColorClose ..
				DARKORANGE ..
				"/soul-dust\nTo modify a command, change either its command box and hit enter or its response box and hit enter.\nTo delete a line, delete BOTH fields before hitting enter, blank commands with blank responses are removed.\nPlayer's can also whisper you for the required mats by whispering you the !enchant, it must match the enchant name exactly.\nExample - Player whispers: !enchant boots - stamina" ..
				ColorClose)
		elseif hideButtonStatus == false then
			hideButtonStatus = true
			hideButton:SetText(GRAY .. "Show Instructions" .. ColorClose)
			InstructionsHeader:SetText(DARKORANGE ..
				"Add !commands and their responses below, hit enter on a line to save the line." .. ColorClose)
		end
	end)


	local scrollHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	scrollHeader:SetFontObject(UIFontBasic)
	scrollHeader:SetPoint("TOP", hideButton, "BOTTOM", -230, -5)
	scrollHeader:SetText("Enter new Command name and Command response")

	-- Initialize the buttons table if it doesn't exist
	if not frame.fieldscmd then
		frame.fieldscmd = {}
		frame.fieldsmsg = {}
	end

	local wtYvalue = wtYvalue or 0


	local function createWhisperTriggers()
		RemoveWhisperTriggers()
		wtYvalue = -25

		for i, v in ipairs(ProEnchantersOptions.whispertriggers) do
			for cmd, msg in pairs(v) do
				-- Create Cmd Box
				local cmdBox = CreateFrame("EditBox", "cmdBox" .. i, ScrollChild, "InputBoxTemplate")
				cmdBox:SetSize(100, 20)
				cmdBox:SetPoint("TOPLEFT", cmdBoxMain, "BOTTOMLEFT", 0, wtYvalue - 15)
				cmdBox:SetAutoFocus(false)
				cmdBox:SetFontObject("GameFontHighlight")
				cmdBox:SetText(tostring(cmd))
				local defaultCmd = tostring(cmd)

				-- Create Cmd Box
				local msgBox = CreateFrame("EditBox", "msgBox" .. i, ScrollChild, "InputBoxTemplate")
				msgBox:SetSize(550, 20)
				msgBox:SetPoint("TOPLEFT", cmdBox, "TOPRIGHT", 20, 0)
				msgBox:SetAutoFocus(false)
				msgBox:SetFontObject("GameFontHighlight")
				msgBox:SetText(tostring(msg))
				msgBox:SetScript("OnTabPressed", function() cmdBox:SetFocus() end)
				cmdBox:SetScript("OnTabPressed", function() msgBox:SetFocus() end)
				local defaultMsg = tostring(msg)

				local charLimit = CreateFrame("EditBox", "charLimitBox" .. i, ScrollChild)
				charLimit:SetSize(40, 20)
				charLimit:SetPoint("TOPLEFT", msgBox, "TOPRIGHT", 15, 0)
				charLimit:SetAutoFocus(false)
				charLimit:EnableMouse(false)
				charLimit:EnableKeyboard(false)
				charLimit:SetFontObject("GameFontHighlight")
				local msgLength = string.len(tostring(msgBox:GetText()))
				local msgLengthText = GRAY .. tostring(msgLength) .. ColorClose
				if msgLength >= 256 then
					msgLengthText = RED .. tostring(msgLength) .. ColorClose
				end
				charLimit:SetText(msgLengthText)

				table.insert(frame.fieldscmd, cmdBox)
				table.insert(frame.fieldsmsg, msgBox)
				table.insert(frame.fieldsmsg, charLimit)

				msgBox:SetScript("OnEnterPressed", function(Self)
					local newcmdBox = cmdBox:GetText()
					local newmsgBox = msgBox:GetText()
					local startPos, endPos = string.find(newcmdBox, "!")
					if newmsgBox == "" then
						if newcmdBox == "" then
							ProEnchantersOptions.whispertriggers[i] = nil

							-- Create a new table to hold the reordered elements
							local reorderedTriggers = {}
							for _, v in pairs(ProEnchantersOptions.whispertriggers) do
								table.insert(reorderedTriggers, v)
							end

							-- Replace the old table with the new, reordered table
							ProEnchantersOptions.whispertriggers = reorderedTriggers

							createWhisperTriggers()
							Self:ClearFocus()
						else
							createWhisperTriggers()
							Self:ClearFocus()
						end
					elseif newmsgBox ~= "" then
						if startPos then
							if startPos == 1 then
								ProEnchantersOptions.whispertriggers[i] = { [newcmdBox] = newmsgBox }
								createWhisperTriggers()
								Self:ClearFocus()
							else
								print("Command must start with !")
							end
						else
							print("Command must start with !")
						end
					end
				end)

				cmdBox:SetScript("OnEnterPressed", function(Self)
					local newcmdBox = cmdBox:GetText()
					local newmsgBox = msgBox:GetText()
					local startPos, endPos = string.find(newcmdBox, "!")
					if newcmdBox == "" then
						if newmsgBox == "" then
							ProEnchantersOptions.whispertriggers[i] = nil

							-- Create a new table to hold the reordered elements
							local reorderedTriggers = {}
							for _, v in pairs(ProEnchantersOptions.whispertriggers) do
								table.insert(reorderedTriggers, v)
							end

							-- Replace the old table with the new, reordered table
							ProEnchantersOptions.whispertriggers = reorderedTriggers

							createWhisperTriggers()
							Self:ClearFocus()
						else
							createWhisperTriggers()
							Self:ClearFocus()
						end
					elseif newcmdBox ~= "" then
						if startPos then
							if startPos == 1 then
								ProEnchantersOptions.whispertriggers[i] = { [newcmdBox] = newmsgBox }
								createWhisperTriggers()
								Self:ClearFocus()
							else
								print("Command must start with !")
							end
						else
							print("Command must start with !")
						end
					end
				end)
			end
			wtYvalue = wtYvalue - 25
		end
	end

	-- Create Cmd Box
	local cmdBoxMain = CreateFrame("EditBox", "cmdBoxMain", ScrollChild, "InputBoxTemplate")
	cmdBoxMain:SetSize(100, 20)
	cmdBoxMain:SetPoint("TOPLEFT", scrollHeader, "BOTTOMLEFT", 10, wtYvalue - 10)
	cmdBoxMain:SetAutoFocus(false)
	cmdBoxMain:SetFontObject("GameFontHighlight")
	cmdBoxMain:SetText("")
	cmdBoxMain:SetScript("OnTextChanged", function()
		local newcmdBox = cmdBoxMain:GetText()
		--stuff
	end)
	cmdBoxMain:SetScript("OnEnterPressed", function(Self)
		local newcmdBox = cmdBoxMain:GetText()
		local newmsgBox = msgBoxMain:GetText()
		local startPos, endPos = string.find(newcmdBox, "!")
		if newcmdBox == "" then
			return
		elseif newmsgBox == "" then
			return
		end
		for i, v in ipairs(ProEnchantersOptions.whispertriggers) do
			for cmd, msg in pairs(v) do
				if tostring(newcmdBox) == tostring(cmd) then
					print("Duplicate found")
					Self:ClearFocus()
					return
				end
			end
		end
		if startPos then
			if startPos == 1 then
				table.insert(ProEnchantersOptions.whispertriggers, { [newcmdBox] = newmsgBox })
				createWhisperTriggers()
				cmdBoxMain:SetText("")
				msgBoxMain:SetText("")
				Self:ClearFocus()
			else
				print("Command must start with !")
			end
		else
			print("Command must start with !")
		end
	end)

	-- Create Cmd Box
	local msgBoxMain = CreateFrame("EditBox", "msgBoxMain", ScrollChild, "InputBoxTemplate")
	msgBoxMain:SetSize(550, 20)
	msgBoxMain:SetPoint("TOPLEFT", cmdBoxMain, "TOPRIGHT", 20, 0)
	msgBoxMain:SetAutoFocus(false)
	msgBoxMain:SetFontObject("GameFontHighlight")
	msgBoxMain:SetText("")
	msgBoxMain:SetScript("OnEnterPressed", function(Self)
		local newcmdBox = cmdBoxMain:GetText()
		local newmsgBox = msgBoxMain:GetText()
		local startPos, endPos = string.find(newcmdBox, "!")
		if newcmdBox == "" then
			return
		elseif newmsgBox == "" then
			return
		end
		for i, v in ipairs(ProEnchantersOptions.whispertriggers) do
			for cmd, msg in pairs(v) do
				if tostring(newcmdBox) == tostring(cmd) then
					print("Duplicate found")
					Self:ClearFocus()
					return
				end
			end
		end
		if startPos then
			if startPos == 1 then
				table.insert(ProEnchantersOptions.whispertriggers, { [newcmdBox] = newmsgBox })
				createWhisperTriggers()
				cmdBoxMain:SetText("")
				msgBoxMain:SetText("")
				Self:ClearFocus()
			else
				print("Command must start with !")
			end
		else
			print("Command must start with !")
		end
	end)

	msgBoxMain:SetScript("OnTabPressed", function() cmdBoxMain:SetFocus() end)
	cmdBoxMain:SetScript("OnTabPressed", function() msgBoxMain:SetFocus() end)

	local existingHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	existingHeader:SetFontObject(UIFontBasic)
	existingHeader:SetPoint("TOPLEFT", cmdBoxMain, "BOTTOMLEFT", -10, -15)
	existingHeader:SetText("Existing Commands")

	createWhisperTriggers()

	-- Create a close button background
	local closeBg = frame:CreateTexture(nil, "OVERLAY")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(800, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)


	-- Create a reset button at the bottom
	local clearAllButton = CreateFrame("Button", nil, frame)
	clearAllButton:SetSize(100, 25)                                     -- Adjust size as needed
	clearAllButton:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0) -- Adjust position as needed
	clearAllButton:SetText("Reset commands?")
	local clearAllButtonText = clearAllButton:GetFontString()
	clearAllButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	clearAllButton:SetNormalFontObject("GameFontHighlight")
	clearAllButton:SetHighlightFontObject("GameFontNormal")
	clearAllButton:SetScript("OnClick", function()
		for k, v in ipairs(ProEnchantersOptions.whispertriggers) do
			wipe(ProEnchantersOptions.whispertriggers)
		end
		for _, t in ipairs(PEWhisperTriggersOriginal) do
			table.insert(ProEnchantersOptions.whispertriggers, t)
		end
		createWhisperTriggers()
	end)

	local importButton = CreateFrame("Button", nil, frame)
	importButton:SetSize(80, 25)                                -- Adjust size as needed
	importButton:SetPoint("RIGHT", clearAllButton, "LEFT", -10, 0) -- Adjust position as needed
	importButton:SetText("Import/Export")
	local importButtonText = importButton:GetFontString()
	importButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	importButton:SetNormalFontObject("GameFontHighlight")
	importButton:SetHighlightFontObject("GameFontNormal")
	importButton:SetScript("OnClick", function()
		frame:Hide()
		ProEnchantersImportFrame:Show()
	end)


	local closeButton = CreateFrame("Button", nil, frame)
	closeButton:SetSize(50, 25)                                   -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0) -- Adjust position as needed
	closeButton:SetText("Close")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")
	closeButton:SetScript("OnClick", function()
		frame:Hide()
		ProEnchantersOptionsFrame:Show()
	end)

	-- Help Reminder
	local helpReminderHeader = frame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject(UIFontBasic)
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 5)
	helpReminderHeader:SetText(STEELBLUE .. "Thanks for using Pro Enchanters!" .. ColorClose)

	-- frame On Show Script
	frame:SetScript("OnShow", function()
		RemoveWhisperTriggers()
		createWhisperTriggers()
	end)

	frame:SetScript("OnHide", function()
		-- Stuff
	end)

	return frame
end

function ProEnchantersCreateImportFrame()
	local frame = CreateFrame("Frame", "ProEnchantersImportFrame", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("FULLSCREEN")
	frame:SetSize(800, 700) -- Adjust height as needed
	frame:SetPoint("TOP", 0, -300)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
	end)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	frame:SetBackdrop(backdrop)
	frame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	frame:Hide()

	-- Create a full background texture
	local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(SettingsWindowBackgroundOpaque)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(800, 675)
	bgTexture:SetPoint("TOP", frame, "TOP", 0, -25)

	-- Create a title background
	local titleBg = frame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(800, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOP", frame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = frame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject(UIFontBasic)
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Commands Import/Export")


	-- Scroll frame setup...
	local ImportScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersImportScrollFrame", frame,
		"UIPanelScrollFrameTemplate")
	ImportScrollFrame:SetSize(775, 650)
	ImportScrollFrame:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 1, 0)

	--Create a scroll background
	local scrollBg = frame:CreateTexture(nil, "ARTWORK")
	scrollBg:SetColorTexture(unpack(ButtonDisabled)) -- Set RGBA values for your preferred color and alpha
	scrollBg:SetSize(20, 650)                     -- Adjust size as needed
	scrollBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -25)

	-- Access the Scroll Bar
	local scrollBar = ImportScrollFrame.ScrollBar

	-- Customize Thumb Texture
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	thumbTexture:SetColorTexture(unpack(ButtonStandardAndThumb))
	thumbTexture:SetSize(18, 27)
	--thumbTexture:SetAllPoints(thumbTexture)

	-- Customize Scroll Up Button Textures
	local upButton = scrollBar.ScrollUpButton

	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)

	-- Customize Scroll Up Button Textures with Solid Colors
	local upButton = scrollBar.ScrollUpButton

	-- Set colors
	upButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Replace RGBA values as needed
	upButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Replace RGBA values as needed
	upButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Replace RGBA values as needed
	upButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Replace RGBA values as needed

	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton

	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	-- Set colors
	downButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Adjust colors as needed
	downButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Adjust colors as needed
	downButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Adjust colors as needed
	downButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Adjust colors as needed

	local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	upButtonText:SetText("-")                              -- Set the text for the up button
	upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

	local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	downButtonText:SetText("-")                                -- Set the text for the down button
	downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed


	-- Scroll child frame where elements are actually placed
	local ScrollChild = CreateFrame("Frame")
	ScrollChild:SetSize(800, 650) -- Adjust height based on the number of elements
	ImportScrollFrame:SetScrollChild(ScrollChild)

	-- Scroll child items below

	-- Create a title for Options

	local InstructionsHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	InstructionsHeader:SetFontObject(UIFontBasic)
	InstructionsHeader:SetPoint("TOP", ScrollChild, "TOP", 0, -10)
	InstructionsHeader:SetText(DARKORANGE ..
		"Copy the text below and save it to a file for exporting.\nAdd or replace the text below and hit import to bulk change commands." ..
		ColorClose)

	-- Create a reset button at the bottom
	local hideButton = CreateFrame("Button", nil, ScrollChild)
	hideButton:SetSize(100, 25)                                  -- Adjust size as needed
	hideButton:SetPoint("TOP", InstructionsHeader, "BOTTOM", 0, -2) -- Adjust position as needed
	hideButton:SetText(GRAY .. "Show Instructions" .. ColorClose)
	local hideButtonText = hideButton:GetFontString()
	hideButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	hideButton:SetNormalFontObject("GameFontHighlight")
	hideButton:SetHighlightFontObject("GameFontNormal")
	local hideButtonStatus = true
	hideButton:SetScript("OnClick", function()
		if hideButtonStatus == true then
			hideButtonStatus = false
			hideButton:SetText(GRAY .. "Hide Instructions" .. ColorClose)
			InstructionsHeader:SetText(DARKORANGE ..
				"Copy the text below and save it to a file for exporting.\nAdd or replace the text below and hit import to bulk change commands.\nFormat needs to stay the same where it is a '!command,response' and then a new line.\nThis will overwrite your commands so make sure you backup first by copying the text and saving it somewhere.\nUse Ctrl+A, Ctrl+C, and Ctrl+V to Select All, Copy, and Paste text into the box easily.\nPre-made import lists can be found on the Supporters discord channel: https://discord.gg/9CMhszeJfu" ..
				ColorClose)
		elseif hideButtonStatus == false then
			hideButtonStatus = true
			hideButton:SetText(GRAY .. "Show Instructions" .. ColorClose)
			InstructionsHeader:SetText(DARKORANGE ..
				"Copy the text below and save it to a file for exporting.\nAdd or replace the text below and hit import to bulk change commands." ..
				ColorClose)
		end
	end)


	local scrollHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	scrollHeader:SetFontObject(UIFontBasic)
	scrollHeader:SetPoint("TOP", hideButton, "BOTTOM", -230, -5)
	scrollHeader:SetText("Modify the text below in the same format presented")

	-- Initialize the buttons table if it doesn't exist
	if not frame.fieldscmd then
		frame.fieldscmd = {}
		frame.fieldsmsg = {}
	end

	local function getWhisperTriggers()
		local lines = {} -- Table to hold each cmd,msg pair
		for i, v in ipairs(ProEnchantersOptions.whispertriggers) do
			for cmd, msg in pairs(v) do
				-- Insert the cmd,msg pair as a string into the lines table
				table.insert(lines, cmd .. "," .. msg)
			end
		end
		-- Concatenate all the lines with a newline separator
		local whisperTriggersLine = table.concat(lines, "\n")
		return whisperTriggersLine
	end

	-- Create Cmd Box
	local cmdBoxMain = CreateFrame("EditBox", "cmdBoxMain", ScrollChild)
	cmdBoxMain:SetSize(700, 625)
	cmdBoxMain:SetPoint("TOPLEFT", scrollHeader, "BOTTOMLEFT", -15, -10)
	cmdBoxMain:SetAutoFocus(false)
	cmdBoxMain:SetMultiLine(true)
	cmdBoxMain:SetFontObject("GameFontHighlight")
	cmdBoxMain:SetText(getWhisperTriggers())
	cmdBoxMain:SetScript("OnTextChanged", function()
		--stuff
	end)
	cmdBoxMain:SetScript("OnEscapePressed", function(Self)
		Self:ClearFocus()
	end)

	-- Create a close button background
	local cmdBoxMainBg = ScrollChild:CreateTexture(nil, "OVERLAY")
	cmdBoxMainBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	cmdBoxMainBg:SetPoint("TOPLEFT", cmdBoxMain, "TOPLEFT", -5, 5)
	cmdBoxMainBg:SetPoint("BOTTOMRIGHT", cmdBoxMain, "BOTTOMRIGHT", 5, -20)

	local function importWhisperTriggers()
		ProEnchantersOptions.whispertriggers = {}
		local newTriggers = cmdBoxMain:GetText()
		-- Iterate over each line in the input string
		for line in string.gmatch(newTriggers, "[^\n]+") do
			-- Split the line by a comma to separate the command and the message
			local cmd, msg = line:match("([^,]+),(.+)")
			if cmd and msg then
				-- Insert the command and message into the table
				table.insert(ProEnchantersOptions.whispertriggers, { [cmd] = msg })
			end
		end
	end


	-- Create a close button background
	local closeBg = frame:CreateTexture(nil, "OVERLAY")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(800, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)


	local importButton = CreateFrame("Button", nil, frame)
	importButton:SetSize(80, 25)                                      -- Adjust size as needed
	importButton:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0) -- Adjust position as needed
	importButton:SetText("Import/Export")
	local importButtonText = importButton:GetFontString()
	importButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	importButton:SetNormalFontObject("GameFontHighlight")
	importButton:SetHighlightFontObject("GameFontNormal")
	importButton:SetScript("OnClick", function()
		importWhisperTriggers()
		print(YELLOWGREEN .. "Commands Imported." .. ColorClose)
	end)


	local closeButton = CreateFrame("Button", nil, frame)
	closeButton:SetSize(50, 25)                                   -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0) -- Adjust position as needed
	closeButton:SetText("Close")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")
	closeButton:SetScript("OnClick", function()
		frame:Hide()
		ProEnchantersWhisperTriggersFrame:Show()
	end)

	-- Help Reminder
	local helpReminderHeader = frame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject(UIFontBasic)
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 5)
	helpReminderHeader:SetText(STEELBLUE .. "Thanks for using Pro Enchanters!" .. ColorClose)

	-- frame On Show Script
	frame:SetScript("OnShow", function()
		print(RED .. "Make sure you copy the text and save it somewhere first to act as a backup before doing an import!")
		cmdBoxMain:SetText(getWhisperTriggers())
	end)

	frame:SetScript("OnHide", function()
		-- Stuff
	end)

	return frame
end

function ProEnchantersCreateGoldFrame()
	local frame = CreateFrame("Frame", "ProEnchantersGoldFrame", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("FULLSCREEN")
	frame:SetSize(500, 600) -- Adjust height as needed
	frame:SetPoint("TOP", 0, -300)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
	end)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	frame:SetBackdrop(backdrop)
	frame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	frame:Hide()

	-- Create a full background texture
	local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetColorTexture(unpack(SettingsWindowBackgroundOpaque)) -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(500, 575)
	bgTexture:SetPoint("TOP", frame, "TOP", 0, -25)

	-- Create a title background
	local titleBg = frame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	titleBg:SetSize(500, 25)                        -- Adjust size as needed
	titleBg:SetPoint("TOP", frame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = frame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject(UIFontBasic)
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Gold Log")


	-- Scroll frame setup...
	local GoldScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersGoldScrollFrame", frame,
		"UIPanelScrollFrameTemplate")
	GoldScrollFrame:SetSize(475, 550)
	GoldScrollFrame:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 1, 0)

	--Create a scroll background
	local scrollBg = frame:CreateTexture(nil, "ARTWORK")
	scrollBg:SetColorTexture(unpack(ButtonDisabled)) -- Set RGBA values for your preferred color and alpha
	scrollBg:SetSize(20, 550)                     -- Adjust size as needed
	scrollBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -25)

	-- Access the Scroll Bar
	local scrollBar = GoldScrollFrame.ScrollBar

	-- Customize Thumb Texture
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	thumbTexture:SetColorTexture(unpack(ButtonStandardAndThumb))
	thumbTexture:SetSize(18, 27)
	--thumbTexture:SetAllPoints(thumbTexture)

	-- Customize Scroll Up Button Textures
	local upButton = scrollBar.ScrollUpButton

	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)

	-- Customize Scroll Up Button Textures with Solid Colors
	local upButton = scrollBar.ScrollUpButton

	-- Set colors
	upButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Replace RGBA values as needed
	upButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Replace RGBA values as needed
	upButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Replace RGBA values as needed
	upButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Replace RGBA values as needed

	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton

	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	-- Set colors
	downButton:GetNormalTexture():SetColorTexture(unpack(ButtonStandardAndThumb)) -- Adjust colors as needed
	downButton:GetPushedTexture():SetColorTexture(unpack(ButtonPushed))        -- Adjust colors as needed
	downButton:GetDisabledTexture():SetColorTexture(unpack(ButtonDisabled))    -- Adjust colors as needed
	downButton:GetHighlightTexture():SetColorTexture(unpack(ButtonHighlight))  -- Adjust colors as needed

	local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	upButtonText:SetText("-")                              -- Set the text for the up button
	upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

	local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	downButtonText:SetText("-")                                -- Set the text for the down button
	downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed


	-- Scroll child frame where elements are actually placed
	local ScrollChild = CreateFrame("Frame")
	ScrollChild:SetSize(475, 550) -- Adjust height based on the number of elements
	GoldScrollFrame:SetScrollChild(ScrollChild)

	-- Scroll child items below

	-- Create a title for Options

	local InstructionsHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	InstructionsHeader:SetFontObject(UIFontBasic)
	InstructionsHeader:SetPoint("TOP", ScrollChild, "TOP", 0, -10)
	InstructionsHeader:SetText(DARKORANGE ..
		"Gold traded to your by players while you have the add-on window open.\nThis number may be slightly inaccurate but should give a rough idea\nof how much gold has been made while enchanting." ..
		ColorClose)

	-- Input gold logs
	local function GetGoldLogs()
		local goldlog = {}
		local check = true
		if next(ProEnchantersLog) == nil then
			check = false
			return {}, check
		end
		for name, amounts in pairs(ProEnchantersLog) do
			local gold = 0
			for _, amount in ipairs(amounts) do -- Corrected to iterate over amounts
				gold = gold + tonumber(amount)
			end
			goldlog[name] = gold
		end
		local goldsorttable = {}
		for name, gold in pairs(goldlog) do
			table.insert(goldsorttable, { name = name, gold = gold })
		end

		-- Sort the table based on the gold values
		table.sort(goldsorttable, function(a, b) return a.gold > b.gold end)
		return goldsorttable, check
	end

	local function GoldLogText()
		local messageboxtext = ""
		local goldlogs, check = GetGoldLogs()
		local totalgold = 0
		if not check then
			return "No text to display" -- Ensures a string is always returned
		end

		for _, t in ipairs(goldlogs) do -- Simplified loop
			local gold = t.gold
			totalgold = totalgold + gold
			local tradeMessage = gold < 0 and "You have traded " or (t.name .. " has traded you ")
			messageboxtext = messageboxtext ..
				(messageboxtext == "" and "" or "\n") .. tradeMessage .. GetMoneyString(math.abs(gold))
		end

		messageboxtext = "Total gold from all logged trades: " .. GetMoneyString(totalgold) .. "\n" .. messageboxtext
		return messageboxtext
	end

	-- Create Cmd Box
	local goldLogEditBox = CreateFrame("EditBox", "cmdBoxMain", ScrollChild)
	goldLogEditBox:SetSize(450, 525)
	goldLogEditBox:SetPoint("TOP", ScrollChild, "TOP", 0, -65)
	goldLogEditBox:SetAutoFocus(false)
	goldLogEditBox:SetMultiLine(true)
	goldLogEditBox:EnableMouse(false)
	goldLogEditBox:EnableKeyboard(false)
	goldLogEditBox:SetFontObject("GameFontHighlight")
	goldLogEditBox:SetText(GoldLogText())
	goldLogEditBox:SetScript("OnTextChanged", function()
		--stuff
	end)
	goldLogEditBox:SetScript("OnEscapePressed", function(Self)
		Self:ClearFocus()
	end)

	-- Create a close button background
	local goldLogEditBoxBg = ScrollChild:CreateTexture(nil, "OVERLAY")
	goldLogEditBoxBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	goldLogEditBoxBg:SetPoint("TOPLEFT", goldLogEditBox, "TOPLEFT", -5, 5)
	goldLogEditBoxBg:SetPoint("BOTTOMRIGHT", goldLogEditBox, "BOTTOMRIGHT", 5, -20)


	-- Create a close button background
	local closeBg = frame:CreateTexture(nil, "OVERLAY")
	closeBg:SetColorTexture(unpack(BottomBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(500, 25)                           -- Adjust size as needed
	closeBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)


	local closeButton = CreateFrame("Button", nil, frame)
	closeButton:SetSize(50, 25)                                   -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0) -- Adjust position as needed
	closeButton:SetText("Close")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")
	closeButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	---- Reset Button
	local resetButton = CreateFrame("Button", nil, frame)
	resetButton:SetSize(80, 25)                                      -- Adjust size as needed
	resetButton:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0) -- Adjust position as needed
	resetButton:SetText("Reset")
	local resetButtonText = resetButton:GetFontString()
	resetButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	resetButton:SetNormalFontObject("GameFontHighlight")
	resetButton:SetHighlightFontObject("GameFontNormal")
	resetButton:SetScript("OnClick", function()
		ProEnchantersLog = {}
		goldLogEditBox:SetText(GoldLogText())
		print(YELLOWGREEN .. "Trade history has been reset." .. ColorClose)
	end)

	-- Help Reminder
	local helpReminderHeader = frame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject(UIFontBasic)
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 5)
	helpReminderHeader:SetText(STEELBLUE .. "Thanks for using Pro Enchanters!" .. ColorClose)

	-- frame On Show Script
	frame:SetScript("OnShow", function()
		goldLogEditBox:SetText(GoldLogText())
	end)

	frame:SetScript("OnHide", function()
		-- Stuff
	end)

	return frame
end

function UpdateCheckboxesBasedOnFilters()
	for key, checkbox in pairs(enchantFilterCheckboxes) do
		local isChecked = ProEnchantersOptions.filters[key]
		if isChecked ~= nil then
			checkbox:SetChecked(isChecked)
		end
	end
end

function IsCurrentTradeSkillEnchanting()
	if CreateFrame then
		local name, clevel, mlevel = GetCraftSkillLine(1)
		return name, clevel, mlevel
	end
end

-- Function to create a CusWorkOrder frame
function CreateCusWorkOrder(customerName, bypass)
	local customerName = string.lower(customerName)
	--customerName = string.utf8upper2(string.sub(customerName2, 1, 1)) .. string.sub(customerName2, 2)
	if customerName == "" or customerName == nil then
		print(RED .. "Invalid customer name" .. ColorClose)
		return
	end
	local frameID = #ProEnchantersWorkOrderFrames + 1
	local framename = "CusWorkOrder" .. frameID
	if bypass ~= true then
		for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
			local lowerFrameCheck = string.lower(frameInfo.Frame.customerName)
			local lowerCusName = string.lower(customerName)
			if lowerFrameCheck == lowerCusName and not frameInfo.Completed then
				if frameInfo.ExistingWOWarning == nil then
					print(YELLOW .. "A work order for " .. customerName .. " is already open." .. ColorClose)
					frameInfo.ExistingWOWarning = true
				end
				if ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
					ScrollToActiveWorkOrder(customerName)
					UpdateTradeHistory(customerName)
				end
				return frameInfo.Frame
			end
		end
	end

	local frame = CreateFrame("Frame", framename, ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "BackdropTemplate")
	frame.customerName = customerName
	frame.frameID = frameID
	frame:SetSize(410, 160)
	frame.yOffset = yOffset
	frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0, frame.yOffset)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	frame:SetBackdrop(backdrop)
	frame:SetBackdropBorderColor(unpack(BorderColorOpaque))

	local customerBg = frame:CreateTexture(nil, "BACKGROUND")
	customerBg:SetColorTexture(unpack(SecondaryBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	customerBg:SetSize(410, 160)
	customerBg:SetPoint("TOP", frame, "TOP", 0, 0)

	local customerTextBg = frame:CreateTexture(nil, "OVERLAY")
	customerTextBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	customerTextBg:SetSize(410, 20)                        -- Adjust size as needed
	customerTextBg:SetPoint("TOP", frame, "TOP", 0, 0)

	local customerTitleButton = CreateFrame("Button", nil, frame)
	customerTitleButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 0)
	customerTitleButton:SetText(customerName .. " - Work Order#" .. frameID)
	local customerTitleButtonText = customerTitleButton:GetFontString()
	customerTitleButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	frame.TitleText = customerName .. " - Work Order#" .. frameID
	customerTitleButton:SetNormalFontObject("GameFontHighlight")
	customerTitleButton:SetHighlightFontObject("GameFontNormal")
	-- Measure the text width
	local textWidth = customerTitleButton:GetFontString():GetStringWidth()
	-- Add some padding to the width for aesthetics
	customerTitleButton:SetSize(textWidth + 10, 20) -- Adjust the height as needed and add some padding to width
	customerTitleButton:SetScript("OnClick", function()
		customerName = string.lower(customerName)
		customerName = CapFirstLetter(customerName)
		ProEnchantersCustomerNameEditBox:SetText(customerName)
	end)

	-- All Mats Msg Button
	local customerAllMats = CreateFrame("Button", nil, frame)
	customerAllMats:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -50, 0)
	customerAllMats:SetText("Req Mats")
	local customerAllMatsText = customerAllMats:GetFontString()
	customerAllMatsText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	customerAllMats:SetNormalFontObject("GameFontHighlight")
	customerAllMats:SetHighlightFontObject("GameFontNormal")
	customerAllMats:SetSize(50, 20) -- Adjust the height as needed and add some padding to width
	customerAllMats:SetScript("OnClick", function()
		local cusName = tostring(customerName)
		local lowercusName = string.lower(cusName)
		if IsShiftKeyDown() then -- Link All Enchants Requested to player via party or whisper
			local allEnchReq = GetAllReqEnchNoLink(customerName)
			if ProEnchantersOptions["WhisperMats"] == true and cusName and cusName ~= "" then
				for i, enchsString in ipairs(allEnchReq) do
					if i == 1 then
						local msgReq = "All Enchants Req: " .. enchsString
						SendChatMessage(msgReq, "WHISPER", nil, cusName)
					elseif i > 1 then
						local msgReq = "All Enchants Req: " .. enchsString
						SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, cusName)
					end
				end
			elseif CheckIfPartyMember(customerName) == true then
				local capPlayerName = CapFirstLetter(customerName)
				for i, enchsString in ipairs(allEnchReq) do
					if i == 1 then
						local msgReq = "All Enchants Req: " .. enchsString
						SendChatMessage(capPlayerName .. " " .. msgReq, IsInRaid() and "RAID" or "PARTY")
					elseif i > 1 then
						local msgReq = "All Enchants Req: " .. enchsString
						SendChatMessage(capPlayerName .. " cont'd " .. msgReq, IsInRaid() and "RAID" or "PARTY")
					end
				end
			elseif cusName and cusName ~= "" then
				for i, enchsString in ipairs(allEnchReq) do
					if i == 1 then
						local msgReq = "All Enchants Req: " .. enchsString
						SendChatMessage(msgReq, "WHISPER", nil, cusName)
					elseif i > 1 then
						local msgReq = "All Enchants Req: " .. enchsString
						SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, cusName)
					end
				end
			else
				for i, enchsString in ipairs(allEnchReq) do
					if i == 1 then
						local msgReq = "All Enchants Req: " .. enchsString
						SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
					elseif i > 1 then
						local msgReq = "All Enchants Req: " .. enchsString
						SendChatMessage("Cont'd " .. msgReq, IsInRaid() and "RAID" or "PARTY")
					end
				end
			end
		elseif IsControlKeyDown() then -- delete all requested enchants
			for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
				if not frameInfo.Completed and frameInfo.Frame.customerName == lowercusName then
					RemoveAllRequestedEnchant(customerName)
				end
			end
			local currentCusFocus = ProEnchantersCustomerNameEditBox:GetText()
			local currentTradeTarget = UnitName("NPC")
			if currentCusFocus == currentTradeTarget then
				ProEnchantersUpdateTradeWindowButtons(currentTradeTarget)
				ProEnchantersUpdateTradeWindowText(currentTradeTarget)
			end
		else -- Link All Mats Requested to player via party or whisper
			local allmatsReq = GetAllReqMats(customerName)
			if allmatsReq == "" then
				return
			end
			if ProEnchantersOptions["WhisperMats"] == true and cusName and cusName ~= "" then
				for i, matsString in ipairs(allmatsReq) do
					if i == 1 then
						local msgReq = "All Mats Needed: " .. matsString
						SendChatMessage(msgReq, "WHISPER", nil, cusName)
					elseif i > 1 then
						local msgReq = "All Mats Needed: " .. matsString
						SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, cusName)
					end
				end
			elseif CheckIfPartyMember(customerName) == true then
				local capPlayerName = CapFirstLetter(customerName)
				for i, matsString in ipairs(allmatsReq) do
					if i == 1 then
						local msgReq = "All Mats Needed: " .. matsString
						SendChatMessage(capPlayerName .. " " .. msgReq, IsInRaid() and "RAID" or "PARTY")
					elseif i > 1 then
						local msgReq = "All Mats Needed: " .. matsString
						SendChatMessage(capPlayerName .. " cont'd " .. msgReq, IsInRaid() and "RAID" or "PARTY")
					end
				end
			elseif cusName and cusName ~= "" then
				for i, matsString in ipairs(allmatsReq) do
					if i == 1 then
						local msgReq = "All Mats Needed: " .. matsString
						SendChatMessage(msgReq, "WHISPER", nil, cusName)
					elseif i > 1 then
						local msgReq = "All Mats Needed: " .. matsString
						SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, cusName)
					end
				end
			else
				for i, matsString in ipairs(allmatsReq) do
					if i == 1 then
						local msgReq = "All Mats Needed: " .. matsString
						SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
					elseif i > 1 then
						local msgReq = "All Mats Needed: " .. matsString
						SendChatMessage("Cont'd " .. msgReq, IsInRaid() and "RAID" or "PARTY")
					end
				end
			end
		end
	end)

	-- Create Scroll Frame for trade history
	local tradeHistoryScrollFrame = CreateFrame("ScrollFrame", framename .. "ScrollFrame", frame,
		"UIPanelScrollFrameTemplate")
	tradeHistoryScrollFrame:SetSize(400, 130)
	tradeHistoryScrollFrame:SetPoint("TOPLEFT", customerTextBg, "BOTTOMLEFT", 10, -5)

	-- Access the Scroll Bar
	local scrollBar = tradeHistoryScrollFrame.ScrollBar
	--scrollBar:SetFrameLevel(9000)

	-- Customize Thumb Texture
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture

	-- Customize Scroll Up Button Textures
	local upButton = scrollBar.ScrollUpButton

	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)

	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton

	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)


	local scrollChild = CreateFrame("Frame", nil, tradeHistoryScrollFrame)
	scrollChild:SetSize(400, 130) -- Adjust height dynamically based on content
	tradeHistoryScrollFrame:SetScrollChild(scrollChild)

	local tradehistoryEditBox = CreateFrame("EditBox", frameID .. "TradeHistory", scrollChild)
	tradehistoryEditBox:SetSize(380, 110) -- Adjust size as needed
	tradehistoryEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
	tradehistoryEditBox:SetMultiLine(true)
	tradehistoryEditBox:SetAutoFocus(false)
	tradehistoryEditBox:SetHyperlinksEnabled(true)
	tradehistoryEditBox:EnableMouse(true)
	tradehistoryEditBox:SetFontObject("GameFontHighlight")
	tradehistoryEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
	tradehistoryEditBox:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMRIGHT", 0, 0) -- Anchor bottom right to scrollChild
	tradehistoryEditBox:SetScript("OnEditFocusGained", function(self)
		customerName = string.lower(customerName)
		customerName = CapFirstLetter(customerName)
		ProEnchantersCustomerNameEditBox:SetText(customerName)
	end)
	tradehistoryEditBox:SetScript("OnTextChanged", function(self)
		scrollChild:SetHeight(self:GetHeight())
	end)
	tradehistoryEditBox:SetScript("OnHyperlinkClick", function(self, linkData, link, button)
		local linkType, addon, param1, param2, param3 = strsplit(":", linkData)
		if linkType == "addon" and addon == "ProEnchanters" then
			local hlType = param1 -- type
			local hlInfo = param2 -- info
			local customerName = param3 -- name
			if IsControlKeyDown() then
				if hlType == "cusreq" then
					RemoveRequestedTradeLine(customerName, hlInfo)
					return
				end
				RemoveRequestedEnchant(customerName, hlInfo)
				local currentTradeTarget = UnitName("NPC")
				if customerName == currentTradeTarget then
					ProEnchantersUpdateTradeWindowButtons(currentTradeTarget)
					ProEnchantersUpdateTradeWindowText(currentTradeTarget)
				end
			elseif IsShiftKeyDown() then
				if hlType == "cusreq" then
					local msgReq = "Custom Request: " .. hlInfo
					if ProEnchantersOptions["WhisperMats"] == true and customerName and customerName ~= "" then
						SendChatMessage(msgReq, "WHISPER", nil, customerName)
					elseif CheckIfPartyMember(customerName) == true then
						local capPlayerName = CapFirstLetter(customerName)
						SendChatMessage(capPlayerName .. " " .. msgReq, IsInRaid() and "RAID" or "PARTY")
					elseif customerName and customerName ~= "" then
						SendChatMessage(msgReq, "WHISPER", nil, customerName)
					else
						SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
					end
					return
				end
				local reqEnchant = hlInfo
				local enchName, enchStats = GetEnchantName(reqEnchant)
				local matsReq = ProEnchants_GetReagentList(reqEnchant)
				local msgReq = enchName .. enchStats .. " Mats Required: " .. matsReq
				local cusName = tostring(customerName)
				if ProEnchantersOptions["WhisperMats"] == true and cusName and cusName ~= "" then
					SendChatMessage(msgReq, "WHISPER", nil, cusName)
				elseif CheckIfPartyMember(customerName) == true then
					local cusName = string.lower(customerName)
					local capPlayerName = CapFirstLetter(cusName)
					SendChatMessage(capPlayerName .. ": " .. msgReq, IsInRaid() and "RAID" or "PARTY")
				elseif cusName and cusName ~= "" then
					SendChatMessage(msgReq, "WHISPER", nil, cusName)
				else
					SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
				end
			end
		end
	end)

	-- Make EditBox non-editable
	tradehistoryEditBox:EnableKeyboard(false)

	-- Store the trade history EditBox in the frame
	frame.tradeHistoryEditBox = tradehistoryEditBox

	-- Initialize the customer's trade history table
	ProEnchantersTradeHistory[customerName] = ProEnchantersTradeHistory[customerName] or {}
	--Input auto invite message if applicable
	if PEPlayerInvited[customerName] then
		local firstline = PEPlayerInvited[customerName]
		firstline = ORANGE .. "Invited from message: " .. ColorClose .. firstline
		local formattedLine = string.gsub(firstline, "%[", "") -- Remove '['
		formattedLine = string.gsub(formattedLine, "%]", "")
		table.insert(ProEnchantersTradeHistory[customerName], formattedLine)
	end

	local minButton = CreateFrame("Button", nil, frame)
	minButton:SetSize(80, 25)
	minButton:SetPoint("TOP", frame, "TOP", 70, 2)
	minButton:SetText("Minimize")
	local minButtonText = minButton:GetFontString()
	minButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	minButton:SetNormalFontObject("GameFontHighlight")
	minButton:SetHighlightFontObject("GameFontNormal")
	local minimized = false
	frame.minimized = minimized
	minButton:SetScript("OnClick", function()
		if minimized == false then
			tradehistoryEditBox:SetText("")
			tradeHistoryScrollFrame:SetSize(400, 0)
			scrollChild:SetSize(400, 0)
			customerBg:SetSize(410, 20)
			frame:SetSize(410, 20)
			-- Move all existing frames up if they are lower than the frame being deleted
			for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
				if id > frameID and not frameInfo.Completed then
					local newYOffset = frameInfo.Frame.yOffset + 140
					frameInfo.Frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0,
						newYOffset)
					frameInfo.Frame.yOffset = newYOffset
				end
			end

			yOffset = yOffset + 140 -- Increase for the next frame
			UpdateScrollChildHeight() -- Call a function to update the height of ScrollChild
			minButton:SetText("Maximize")
			minimized = true
			frame.minimized = minimized
		elseif minimized == true then
			tradeHistoryScrollFrame:SetSize(400, 130)
			scrollChild:SetSize(400, 130)
			customerBg:SetSize(410, 160)
			frame:SetSize(410, 160)


			-- Move all existing frames up if they are lower than the frame being deleted
			for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
				if id > frameID and not frameInfo.Completed then
					local newYOffset = frameInfo.Frame.yOffset - 140
					frameInfo.Frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0,
						newYOffset)
					frameInfo.Frame.yOffset = newYOffset
				end
			end

			yOffset = yOffset - 140 -- Increase for the next frame
			UpdateScrollChildHeight() -- Call a function to update the height of ScrollChild
			customerName = string.lower(customerName)
			customerName = CapFirstLetter(customerName)
			ProEnchantersCustomerNameEditBox:SetText(customerName)
			ProEnchantersCustomerNameEditBox:ClearFocus(ProEnchantersCustomerNameEditBox)
			minButton:SetText("Minimize")
			minimized = false
			frame.minimized = minimized
			UpdateTradeHistory(customerName)
		end
	end)


	-- close Button
	local closeButton = CreateFrame("Button", nil, frame)
	closeButton:SetSize(25, 25)
	closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, 2)
	closeButton:SetText("X")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")

	--Close Frame Functions
	local tradeLine = LIGHTGREEN .. "---- End of Workorder# " .. frameID .. " ----" .. ColorClose
	closeButton:SetScript("OnClick", function()
		if minimized == true then
			tradeHistoryScrollFrame:SetSize(400, 130)
			scrollChild:SetSize(400, 130)
			customerBg:SetSize(410, 160)
			frame:SetSize(410, 160)

			-- Move all existing frames up if they are lower than the frame being deleted
			for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
				if id > frameID and not frameInfo.Completed then
					local newYOffset = frameInfo.Frame.yOffset - 140
					frameInfo.Frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0,
						newYOffset)
					frameInfo.Frame.yOffset = newYOffset
				end
			end

			yOffset = yOffset - 140 -- Increase for the next frame
			UpdateScrollChildHeight() -- Call a function to update the height of ScrollChild
			local CurrentCustomer = ProEnchantersCustomerNameEditBox:GetText()
			if CurrentCustomer == customerName then
				ProEnchantersCustomerNameEditBox:SetText("")
				ProEnchantersCustomerNameEditBox:ClearFocus(ProEnchantersCustomerNameEditBox)
			end
			minButton:SetText("Minimize")
			minimized = false
			frame.minimized = minimized
			UpdateTradeHistory(customerName)
		end

		frame:Hide()
		local customerNameLower = string.lower(customerName)
		table.insert(ProEnchantersTradeHistory[customerNameLower], tradeLine)
		ProEnchantersWorkOrderFrames[frameID].Completed = true
		PEPlayerInvited[customerName] = nil

		-- Move all existing frames up if they are lower than the frame being deleted
		for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
			if id > frameID and not frameInfo.Completed then
				local newYOffset = frameInfo.Frame.yOffset + 162
				frameInfo.Frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0, newYOffset)
				frameInfo.Frame.yOffset = newYOffset
			end
		end

		yOffset = yOffset + 162 -- Increase for the next frame
		UpdateScrollChildHeight() -- Call a function to update the height of ScrollChild
		local CurrentCustomer = ProEnchantersCustomerNameEditBox:GetText()
		if CurrentCustomer == customerName then
			ProEnchantersCustomerNameEditBox:SetText("")
			ProEnchantersCustomerNameEditBox:ClearFocus(ProEnchantersCustomerNameEditBox)
		end
	end)

	yOffset = yOffset - 162 -- Decrease for a new frame
	ProEnchantersWorkOrderFrames[frameID] = { Frame = frame, Completed = false, Enchants = {} }
	UpdateScrollChildHeight()
	UpdateTradeHistory(customerName)
	if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
		customerName = string.lower(customerName)
		customerName = CapFirstLetter(customerName)
		ProEnchantersCustomerNameEditBox:SetText(customerName)
	end
	return frame
end

function ShowOpenWorkOrders()
	for i, t in ipairs(ProEnchantersWorkOrderFrames) do
		if t.Completed == false then
			t.Completed = true
			AddTradeLine(t.Frame.customerName, "--Work order closed on session end--")
			--local cusName = t.Frame.customerName  -- Use the correct case and remove :Show()
			--local bypass = true
			--CreateCusWorkOrder(cusName, bypass)
		end
	end
end

-- Create Trade Order on Trade Frame
-- Function to update the height of ScrollChild based on the number of CusWorkOrder frames
function UpdateScrollChildHeight()
	local totalHeight = 0
	for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
		if not frameInfo.Completed then
			if frameInfo.Frame.minimized == false then
				totalHeight = totalHeight + 162 -- Add height of each frame
			elseif frameInfo.Frame.minimized == true then
				totalHeight = totalHeight + 20
			end
		end
	end
	ProEnchantersWorkOrderScrollFrame:GetScrollChild():SetHeight(totalHeight)
end

-- Function to handle "Create Workorder" button press
function OnCreateWorkorderButtonClick()
	local customerName = ProEnchantersCustomerNameEditBox:GetText()
	customerName = string.lower(customerName)
	CreateCusWorkOrder(customerName)
end

-- Trade Window Frame Stuff
function ProEnchantersTradeWindowCreateFrame()
	local customerName = "temp"
	local tradeFrame = TradeFrame
	local tradeFrameSlot7 = TradeRecipientItem7ItemButton
	local tradeFrameTradeButton = TradeFrameTradeButton
	-- local tradewindowHeight = tradeFrame:GetHeight()
	local tradewindowWidth, tradewindowHeight = tradeFrame:GetSize()
	local frame = CreateFrame("Frame", "ProEnchantersTradeWindowFrame", TradeFrame)
	frame:SetFrameStrata("DIALOG")
	frame:SetSize(180, tradewindowHeight)
	frame:SetPoint("BOTTOMLEFT", tradeFrame, "BOTTOMRIGHT", 0, 0)

	local lowerframe = CreateFrame("Frame", "ProEnchantersTradeWindowLowerFrame", TradeFrame, "BackdropTemplate")
	lowerframe:SetFrameStrata("DIALOG")
	lowerframe:SetSize(tradewindowWidth, 180)
	lowerframe:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", 0, 0)

	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
		edgeSize = 1,                        -- Border thickness
	}

	-- Apply the backdrop to the WorkOrderFrame
	lowerframe:SetBackdrop(backdrop)
	lowerframe:SetBackdropBorderColor(unpack(BorderColorOpaque))

	local customerBg = frame:CreateTexture(nil, "BACKGROUND")
	customerBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	customerBg:SetSize(tradewindowWidth, 180)
	customerBg:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", 0, 0)

	local customerTextBg = frame:CreateTexture(nil, "BACKGROUND")
	customerTextBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	customerTextBg:SetSize(tradewindowWidth, 20)           -- Adjust size as needed
	customerTextBg:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", 0, 0)

	frame.customerTitleButton = CreateFrame("Button", nil, frame)
	frame.customerTitleButton:SetPoint("TOP", customerTextBg, "TOP", 5, 0)
	frame.customerTitleButton:SetText("Placeholder")
	local customerTitleButtonText = frame.customerTitleButton:GetFontString()
	customerTitleButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	frame.customerTitleButton:SetNormalFontObject("GameFontHighlight")
	frame.customerTitleButton:SetHighlightFontObject("GameFontNormal")
	frame.customerTitleButton:SetSize(100, 20) -- Adjust the height as needed and add some padding to width
	frame.customerTitleButton:SetScript("OnClick", function()
		customerName = string.lower(customerName)
		customerName = CapFirstLetter(customerName)
		ProEnchantersCustomerNameEditBox:SetText(customerName)
	end)

	local announceMissingButtonBg = frame:CreateTexture(nil, "BACKGROUND")
	announceMissingButtonBg:SetColorTexture(unpack(TopBarColorOpaque)) -- Set RGBA values for your preferred color and alpha
	announceMissingButtonBg:SetSize(tradewindowWidth, 20)           -- Adjust size as needed
	announceMissingButtonBg:SetPoint("TOPRIGHT", customerBg, "BOTTOMRIGHT", 0, 0)

	frame.announceMissingButton = CreateFrame("Button", nil, frame)
	frame.announceMissingButton:SetPoint("TOP", announceMissingButtonBg, "TOP", 0, 0)
	frame.announceMissingButton:SetText("Announce current missing mats")
	local announceMissingButtonText = frame.announceMissingButton:GetFontString()
	announceMissingButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	frame.announceMissingButton:SetNormalFontObject("GameFontHighlight")
	frame.announceMissingButton:SetHighlightFontObject("GameFontNormal")
	frame.announceMissingButton:SetSize(175, 20) -- Adjust the height as needed and add some padding to width
	frame.announceMissingButton:SetScript("OnClick", function()
		customerName = string.lower(customerName)
		LinkAllMissingMats(customerName)
	end)


	-- Use Mats from Inventory Checkbox
	frame.useAllMatsCb = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
	frame.useAllMatsCb:SetPoint("TOPRIGHT", customerTextBg, "TOPRIGHT", -6, 0)
	--frame.useAllMatsCb:SetFrameLevel(9001)
	frame.useAllMatsCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	frame.useAllMatsCb:SetHitRectInsets(0, 0, 0, 0)
	frame.useAllMatsCb:SetChecked(ProEnchantersOptions["UseAllMats"])
	frame.useAllMatsCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["UseAllMats"] = self:GetChecked()
		useAllMats = ProEnchantersOptions["UseAllMats"]
		ProEnchantersUpdateTradeWindowText(customerName)
		ProEnchantersUpdateTradeWindowButtons(customerName)
	end)

	-- Use Mats from Inventory Text
	local useAllMatsHeader = frame:CreateFontString(nil, "OVERLAY")
	useAllMatsHeader:SetFontObject(UIFontBasic)
	useAllMatsHeader:SetPoint("RIGHT", frame.useAllMatsCb, "LEFT", 0, 2)
	useAllMatsHeader:SetText("Use all mats?")

	local ScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersTradeWindowFrameScrollFrame", frame,
		"UIPanelScrollFrameTemplate")
	ScrollFrame:SetSize(tradewindowWidth - 10, 155)
	ScrollFrame:SetPoint("TOP", customerTextBg, "BOTTOM", 0, -3)

	local scrollBar = ScrollFrame.ScrollBar
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil) -- Clear existing texture
	--thumbTexture:SetColorTexture(0.3, 0.1, 0.4, 0.8)
	local upButton = scrollBar.ScrollUpButton
	-- Clear existing textures
	upButton:GetNormalTexture():SetTexture(nil)
	upButton:GetPushedTexture():SetTexture(nil)
	upButton:GetDisabledTexture():SetTexture(nil)
	upButton:GetHighlightTexture():SetTexture(nil)
	-- Repeat for Scroll Down Button
	local downButton = scrollBar.ScrollDownButton
	-- Clear existing textures
	downButton:GetNormalTexture():SetTexture(nil)
	downButton:GetPushedTexture():SetTexture(nil)
	downButton:GetDisabledTexture():SetTexture(nil)
	downButton:GetHighlightTexture():SetTexture(nil)

	local scrollChild = CreateFrame("Frame", nil, ScrollFrame)
	scrollChild:SetSize(tradewindowWidth - 10, 155) -- Adjust height dynamically based on content
	ScrollFrame:SetScrollChild(scrollChild)

	local tradewindowEditBox = CreateFrame("EditBox", customerName .. "TradeWindow", scrollChild)
	tradewindowEditBox:SetSize(tradewindowWidth - 10, 155) -- Adjust size as needed
	tradewindowEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
	tradewindowEditBox:SetMultiLine(true)
	tradewindowEditBox:SetAutoFocus(false)
	tradewindowEditBox:EnableMouse(true)
	tradewindowEditBox:SetFontObject("GameFontHighlight")
	tradewindowEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
	tradewindowEditBox:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMRIGHT", 0, 0) -- Anchor bottom right to scrollChild
	tradewindowEditBox:SetScript("OnTextChanged", function(self)
		scrollChild:SetHeight(self:GetHeight())
	end)

	-- Make EditBox non-editable
	tradewindowEditBox:EnableKeyboard(false)

	-- Store the trade history EditBox in the frame
	frame.tradewindowEditBox = tradewindowEditBox

	-- Create All Buttons
	local enchyOffset = 0
	local convertyOffset = -10
	local enchxOffset = 15
	local frame = _G["ProEnchantersTradeWindowFrame"]
	local slotType = SlotTypeInput
	local enchantType = ""
	local enchantName = ""

	if not frame.buttons then
		frame.buttons = {}
		frame.buttonBgs = {}
	end

	if not frame.namedButtons then
		frame.namedButtons = {}
	end

	local function alphanumericSort(a, b)
		-- Extract number from the string
		local numA = tonumber(a:match("%d+"))
		local numB = tonumber(b:match("%d+"))

		if numA and numB then -- If both strings have numbers, then compare numerically
			return numA < numB -- Reverse numerical order
		else
			return a < b -- Reverse lexicographical order
		end
	end

	-- Get and sort the keys
	local keys = {}
	for k in pairs(EnchantsName) do
		table.insert(keys, k)
	end
	table.sort(keys, alphanumericSort) -- Sorts the keys in natural alphanumeric order

	-- Customer Requested Buttons
	for _, key in ipairs(keys) do
		enchantName = CombinedEnchants[key].name
		local enchantTitleText1 = enchantName:gsub(" %- ", "\n") -- Corrected from 'value' to 'enchantName'
		local enchantStats1 = CombinedEnchants[key].stats
		local enchantStats2 = string.gsub(enchantStats1, "%(", "")
		local enchantStats3 = string.gsub(enchantStats2, "%)", "")
		local enchantStats = string.gsub(enchantStats3, "%+", "")
		local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats
		local enchValue = PEenchantingLocales["Enchants"][key][LocalLanguage]


		-- Create button background
		local enchantButtonBg = frame:CreateTexture(nil, "OVERLAY")
		local buttonNameBg = key .. "cusbuttonactivebg"
		enchantButtonBg:SetColorTexture(unpack(EnchantsButtonColorOpaque))
		enchantButtonBg:SetSize(145, 45)
		enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
		enchantButtonBg:Hide()

		-- Create a Macro

		local macro1 = [=[
/cast enchValue
/run TradeRecipientItem7ItemButton:Click()
/click StaticPopup1Button1
]=]

		local macro2 = string.gsub(macro1, "enchValue", enchValue)

		-- Create a button
		local buttonName = key .. "cusbuttonactive"
		local enchantButton = CreateFrame("Button", buttonName, frame, "SecureActionButtonTemplate")
		enchantButton:SetSize(145, 45)
		enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
		enchantButton:SetText(enchantTitleText)
		local enchantButtonText = enchantButton:GetFontString()
		enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
		enchantButton:SetNormalFontObject("GameFontHighlight")
		enchantButton:SetHighlightFontObject("GameFontNormal")
		enchantButton:SetMouseClickEnabled(true)
		enchantButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
		enchantButton:SetAttribute("type", "macro")
		enchantButton:SetAttribute("macrotext", macro2)
		--enchantButton:SetAttribute("type", "spell")
		--enchantButton:SetAttribute("spell", enchValue)
		--[[enchantButton:SetScript("PostClick", function(self, btn, down)
				if (down) then
					--acceptButtonBg:Show()
					--macroButton:Show()
				print("Down on enchant button")
				end
			end)]]
		enchantButton:Hide()

		-- Increase yOffset for the next button
		enchyOffset = enchyOffset - 50

		frame.namedButtons[buttonName] = enchantButton
		frame.namedButtons[buttonNameBg] = enchantButtonBg
		--table.insert(frame.buttons, enchantButton)
		--table.insert(frame.buttonBgs, enchantButtonBg)
	end

	-- Load rest of Relevant Enchant Buttons that are Not Available
	for _, key in ipairs(keys) do
		enchantName = CombinedEnchants[key].name

		local enchantTitleText1 = enchantName:gsub(" %- ", "\n") -- Corrected from 'value' to 'enchantName'
		local enchantStats1 = CombinedEnchants[key].stats
		local enchantStats2 = string.gsub(enchantStats1, "%(", "")
		local enchantStats3 = string.gsub(enchantStats2, "%)", "")
		local enchantStats = string.gsub(enchantStats3, "%+", "")
		local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats

		-- Create button background
		local enchantButtonBg = frame:CreateTexture(nil, "BACKGROUND")
		local buttonNameBg1 = key .. "cusbuttondisabledbg1"
		enchantButtonBg:SetColorTexture(unpack(EnchantsButtonColorInactiveOpaque))
		enchantButtonBg:SetSize(145, 45)
		enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
		enchantButtonBg:Hide()

		-- Create a button
		local buttonName = key .. "cusbuttondisabled"
		local enchantButton = CreateFrame("Button", buttonName, frame)
		enchantButton:SetSize(145, 45)
		enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
		enchantButton:SetText(enchantTitleText)
		local enchantButtonText = enchantButton:GetFontString()
		enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
		enchantButton:SetNormalFontObject("GameFontHighlight")
		enchantButton:SetHighlightFontObject("GameFontNormal")
		enchantButton:SetScript("OnClick", function()
			local customerName = string.lower(UnitName("NPC"))
			LinkMissingMats(key, customerName)
		end)
		enchantButton:Hide()

		-- Create a Announce icon
		local enchantMatsMissingDisplay = frame:CreateTexture(nil, "OVERLAY")
		--enchantMatsMissingDisplay:SetColorTexture(unpack(EnchantsButtonColorOpaque))  -- Set RGBA values for your preferred color and alpha
		enchantMatsMissingDisplay:SetTexture("Interface\\COMMON\\VOICECHAT-SPEAKER.BLP")
		enchantMatsMissingDisplay:SetSize(16, 16) -- Adjust size as needed
		enchantMatsMissingDisplay:SetPoint("TOPRIGHT", enchantButton, "TOPRIGHT", 10, 5)
		enchantMatsMissingDisplay:Hide()
		local buttonNameBg2 = key .. "cusbuttondisabledbg2"

		-- Increase yOffset for the next button
		enchyOffset = enchyOffset - 50

		frame.namedButtons[buttonName] = enchantButton
		frame.namedButtons[buttonNameBg1] = enchantButtonBg
		frame.namedButtons[buttonNameBg2] = enchantMatsMissingDisplay
	end


	-- Add a Spacer
	local otherEnchantsBg = frame:CreateTexture(nil, "OVERLAY")
	otherEnchantsBg:SetColorTexture(unpack(MainWindowBackgroundTrans)) -- Set RGBA values for your preferred color and alpha
	otherEnchantsBg:SetSize(140, 20)
	otherEnchantsBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)

	local otherEnchants = CreateFrame("Button", nil, frame)
	otherEnchants:SetSize(140, 20)
	otherEnchants:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
	otherEnchants:SetText("Refresh Buttons")
	local otherEnchantsText = otherEnchants:GetFontString()
	otherEnchantsText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	otherEnchants:SetNormalFontObject("GameFontHighlight")
	otherEnchants:SetHighlightFontObject("GameFontNormal")

	frame.otherEnchantsBg = otherEnchantsBg
	frame.otherEnchants = otherEnchants

	--table.insert(frame.buttons, otherEnchantsBg)
	--table.insert(frame.buttonBgs, otherEnchants)
	enchyOffset = enchyOffset - 25

	-- Load rest of Relevant Enchant Buttons that are Available
	for _, key in ipairs(keys) do
		enchantName = CombinedEnchants[key].name
		local enchantTitleText1 = enchantName:gsub(" %- ", "\n") -- Corrected from 'value' to 'enchantName'
		local enchantStats1 = CombinedEnchants[key].stats
		local enchantStats2 = string.gsub(enchantStats1, "%(", "")
		local enchantStats3 = string.gsub(enchantStats2, "%)", "")
		local enchantStats = string.gsub(enchantStats3, "%+", "")
		local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats
		local enchValue = PEenchantingLocales["Enchants"][key][LocalLanguage]


		-- Create button background
		local enchantButtonBg = frame:CreateTexture(nil, "OVERLAY")
		local buttonNameBg = key .. "buttonactivebg"
		enchantButtonBg:SetColorTexture(unpack(EnchantsButtonColorOpaque))
		enchantButtonBg:SetSize(145, 45)
		enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
		enchantButtonBg:Hide()

		local macro1 = [=[
/cast enchValue
/run TradeRecipientItem7ItemButton:Click()
/click StaticPopup1Button1
]=]

		local macro2 = string.gsub(macro1, "enchValue", enchValue)

		-- Create a button
		local buttonName = key .. "buttonactive"
		local enchantButton = CreateFrame("Button", buttonName, frame, "SecureActionButtonTemplate")
		enchantButton:SetSize(145, 45)
		enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
		enchantButton:SetText(enchantTitleText)
		local enchantButtonText = enchantButton:GetFontString()
		enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
		enchantButton:SetNormalFontObject("GameFontHighlight")
		enchantButton:SetHighlightFontObject("GameFontNormal")
		enchantButton:SetMouseClickEnabled(true)
		enchantButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")

		enchantButton:SetAttribute("type", "macro")
		enchantButton:SetAttribute("macrotext", macro2)
		--[[enchantButton:SetAttribute("type", "spell")
			enchantButton:SetAttribute("spell", enchValue)
			enchantButton:SetScript("PostClick", function(self, btn, down)
				if (down) then
					acceptButtonBg:Show()
					macroButton:Show()
				end
			end)]]
		enchantButton:Hide()


		-- Increase yOffset for the next button
		enchyOffset = enchyOffset - 50

		frame.namedButtons[buttonName] = enchantButton
		frame.namedButtons[buttonNameBg] = enchantButtonBg
		--table.insert(frame.buttons, enchantButton)
		--table.insert(frame.buttonBgs, enchantButtonBg)
	end

	-- Load rest of Relevant Enchant Buttons that are Not Available
	for _, key in ipairs(keys) do
		enchantName = CombinedEnchants[key].name

		local enchantTitleText1 = enchantName:gsub(" %- ", "\n") -- Corrected from 'value' to 'enchantName'
		local enchantStats1 = CombinedEnchants[key].stats
		local enchantStats2 = string.gsub(enchantStats1, "%(", "")
		local enchantStats3 = string.gsub(enchantStats2, "%)", "")
		local enchantStats = string.gsub(enchantStats3, "%+", "")
		local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats


		-- Create button background
		local enchantButtonBg = frame:CreateTexture(nil, "BACKGROUND")
		local buttonNameBg1 = key .. "buttondisabledbg1"
		enchantButtonBg:SetColorTexture(unpack(EnchantsButtonColorInactiveOpaque))
		enchantButtonBg:SetSize(145, 45)
		enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
		enchantButtonBg:Hide()

		-- Create a button
		local buttonName = key .. "buttondisabled"
		local enchantButton = CreateFrame("Button", buttonName, frame)
		enchantButton:SetSize(145, 45)
		enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
		enchantButton:SetText(enchantTitleText)
		local enchantButtonText = enchantButton:GetFontString()
		enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
		enchantButton:SetNormalFontObject("GameFontHighlight")
		enchantButton:SetHighlightFontObject("GameFontNormal")
		enchantButton:SetScript("OnClick", function()
			local customerName = string.lower(UnitName("NPC"))
			LinkMissingMats(key, customerName)
		end)
		enchantButton:Hide()

		-- Create a Announce icon
		local enchantMatsMissingDisplay = frame:CreateTexture(nil, "OVERLAY")
		--enchantMatsMissingDisplay:SetColorTexture(unpack(EnchantsButtonColorOpaque))  -- Set RGBA values for your preferred color and alpha
		enchantMatsMissingDisplay:SetTexture("Interface\\COMMON\\VOICECHAT-SPEAKER.BLP")
		enchantMatsMissingDisplay:SetSize(16, 16) -- Adjust size as needed
		enchantMatsMissingDisplay:SetPoint("TOPRIGHT", enchantButton, "TOPRIGHT", 10, 5)
		local buttonNameBg2 = key .. "buttondisabledbg2"
		enchantMatsMissingDisplay:Hide()

		-- Increase yOffset for the next button
		enchyOffset = enchyOffset - 50

		frame.namedButtons[buttonName] = enchantButton
		frame.namedButtons[buttonNameBg1] = enchantButtonBg
		frame.namedButtons[buttonNameBg2] = enchantMatsMissingDisplay
	end

	for i, name in ipairs(PEConvertablesName) do
		-- Create button background
		local convertButtonBg = frame:CreateTexture(nil, "BACKGROUND")
		local buttonNameBg = name .. "bg"
		convertButtonBg:SetColorTexture(unpack(EnchantsButtonColorOpaque))
		convertButtonBg:SetSize(145, 30)
		convertButtonBg:SetPoint("TOP", frame, "BOTTOM", -enchxOffset, convertyOffset)
		convertButtonBg:Hide()
		-- Create a button
		local buttonName = name .. "button"
		local convertButton = CreateFrame("Button", buttonName, frame, "SecureActionButtonTemplate")
		convertButton:SetSize(145, 30)
		convertButton:SetPoint("TOP", frame, "BOTTOM", -enchxOffset, convertyOffset)
		convertButton:SetText("Convert \n" .. name)
		local convertButtonText = convertButton:GetFontString()
		convertButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
		convertButton:SetNormalFontObject("GameFontHighlight")
		convertButton:SetHighlightFontObject("GameFontNormal")
		convertButton:SetMouseClickEnabled(true)
		convertButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
		convertButton:SetAttribute("type", "item")
		convertButton:SetAttribute("item", name)
		convertButton:Hide()

		-- Increase yOffset for the next button
		convertyOffset = convertyOffset - 35

		frame.namedButtons[buttonName] = convertButton
		frame.namedButtons[buttonNameBg] = convertButtonBg
		--table.insert(frame.buttons, convertButton)
		--table.insert(frame.buttonBgs, convertButtonBg)
	end


	frame:SetScript("OnHide", function()
		--acceptButtonBg:Hide()
		--macroButton:Hide()
	end)



	local minButton = CreateFrame("Button", nil, frame)
	minButton:SetSize(80, 25)
	minButton:SetPoint("TOPLEFT", customerTextBg, "TOPLEFT", 5, 2)
	minButton:SetText("Minimize")
	local minButtonText = minButton:GetFontString()
	minButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	minButton:SetNormalFontObject("GameFontHighlight")
	minButton:SetHighlightFontObject("GameFontNormal")
	local minimized = false
	frame.minimized = minimized
	minButton:SetScript("OnClick", function()
		if frame.minimized == false then
			ScrollFrame:Hide()
			--ScrollFrame:SetSize(tradewindowWidth - 10, 155)
			announceMissingButtonBg:Hide()
			frame.announceMissingButton:Hide()
			customerBg:SetSize(tradewindowWidth, 20)
			lowerframe:SetSize(tradewindowWidth, 20)
			minButton:SetText("Maximize")
			minimized = true
			frame.minimized = minimized
			--UpdateTradeHistory(customerName)
		elseif frame.minimized == true then
			ScrollFrame:Show()
			--ScrollFrame:SetSize(tradewindowWidth - 10, 155)
			announceMissingButtonBg:Show()
			frame.announceMissingButton:Show()
			customerBg:SetSize(tradewindowWidth, 180)
			lowerframe:SetSize(tradewindowWidth, 180)
			minButton:SetText("Minimize")
			minimized = false
			frame.minimized = minimized
			--UpdateTradeHistory(customerName)
		end
	end)


	return frame
end

function ProEnchantersLoadTradeWindowFrame(PEtradeWho)
	RemoveTradeWindowInfo()
	local PEtradeWho = string.lower(PEtradeWho)
	local enchyOffset = 0
	local enchxOffset = 15
	local frame = _G["ProEnchantersTradeWindowFrame"]
	local ScrollFrame = _G["ProEnchantersTradeWindowFrameScrollFrame"]
	local scrollChild = ScrollFrame:GetScrollChild()
	local customerName = PEtradeWho or ""
	local line = ""
	local buttoncount = 0


	frame.customerTitleButton:SetText(PEtradeWho)
	frame.customerTitleButton:SetScript("OnClick", function()
		local customerName = PEtradeWho
		customerName = string.lower(customerName)
		if not ProEnchantersTradeHistory[customerName] then
			ProEnchantersTradeHistory[customerName] = {}
			CreateCusWorkOrder(customerName)
			if ProEnchantersTradeHistory[customerName] then
				ProEnchantersLoadTradeWindowFrame(customerName)
			end
		end
		ProEnchantersUpdateTradeWindowButtons(customerName)
		ProEnchantersUpdateTradeWindowText(customerName)
		customerName = CapFirstLetter(customerName)
		ProEnchantersCustomerNameEditBox:SetText(customerName)
	end)

	frame.announceMissingButton:SetScript("OnClick", function()
		local customerName = PEtradeWho
		customerName = string.lower(customerName)
		ProEnchantersUpdateTradeWindowButtons(customerName)
		ProEnchantersUpdateTradeWindowText(customerName)
		LinkAllMissingMats(customerName)
	end)

	frame.useAllMatsCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["UseAllMats"] = self:GetChecked()
		useAllMats = ProEnchantersOptions["UseAllMats"]
		ProEnchantersUpdateTradeWindowText(customerName)
		ProEnchantersUpdateTradeWindowButtons(customerName)
	end)

	ProEnchantersUpdateTradeWindowText(customerName)

	if customerName then
		for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
			if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
				local function alphanumericSort(a, b)
					-- Extract number from the string
					local numA = tonumber(a:match("%d+"))
					local numB = tonumber(b:match("%d+"))

					if numA and numB then -- If both strings have numbers, then compare numerically
						return numA < numB
					else
						return a < b -- If one or both strings don't have numbers, sort lexicographically
					end
				end

				-- Get and sort the keys
				local keys = {}
				for k in pairs(EnchantsName) do
					table.insert(keys, k)
				end
				table.sort(keys, alphanumericSort) -- Sorts the keys in natural alphanumeric order

				for _, enchantID in ipairs(frameInfo.Enchants) do
					local enchantName = CombinedEnchants[enchantID].name
					local key = enchantID
					local enchantStats1 = CombinedEnchants[enchantID].stats
					local enchantStats2 = string.gsub(enchantStats1, "%(", "")
					local enchantStats3 = string.gsub(enchantStats2, "%)", "")
					local enchantStats = string.gsub(enchantStats3, "%+", "")
					local enchantTitleText1 = enchantName:gsub(" %- ", "\n") -- Corrected from 'value' to 'enchantName'



					-- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
					local matsDiff = {}
					local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, enchantID)
					if matsMissingCheck ~= true then
						if ProEnchantersOptions.filters[key] == true then
							if buttoncount >= 10 then
								break
							end

							local buttonName = key .. "cusbuttonactive"
							local buttonNameBg = key .. "cusbuttonactivebg"
							if matsMissingCheck ~= true then
								if frame.namedButtons[buttonName] then
									if not frame.namedButtons[buttonName]:IsVisible() then
										frame.namedButtons[buttonName]:Show()
										frame.namedButtons[buttonNameBg]:Show()
										frame.namedButtons[buttonName]:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset,
											enchyOffset)
										frame.namedButtons[buttonNameBg]:SetPoint("BOTTOM", frame, "BOTTOM", -
											enchxOffset, enchyOffset)
										-- Additional logic here
										enchyOffset = enchyOffset + 50
										buttoncount = buttoncount + 1
									end
								else
									print("button not found")
								end
							elseif matsMissingCheck == true then
								if frame.namedButtons[buttonName] then
									frame.namedButtons[buttonName]:Hide()
									frame.namedButtons[buttonNameBg]:Hide()
								end
							end
						end
						--enchyOffset = enchyOffset + 50
					end
				end

				for _, enchantID in ipairs(frameInfo.Enchants) do
					local enchantName = CombinedEnchants[enchantID].name
					local key = enchantID
					local enchantStats1 = CombinedEnchants[enchantID].stats
					local enchantStats2 = string.gsub(enchantStats1, "%(", "")
					local enchantStats3 = string.gsub(enchantStats2, "%)", "")

					-- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
					if matsMissingCheck == true then
						if ProEnchantersOptions.filters[key] == true then
							if buttoncount >= 10 then
								break
							end

							local buttonName = key .. "cusbuttondisabled"
							local buttonNameBg1 = key .. "cusbuttondisabledbg1"
							local buttonNameBg2 = key .. "cusbuttondisabledbg2"
							if matsMissingCheck ~= true then
								if frame.namedButtons[buttonName] then
									frame.namedButtons[buttonName]:Hide()
									frame.namedButtons[buttonNameBg1]:Hide()
									frame.namedButtons[buttonNameBg2]:Hide()
								end
							elseif matsMissingCheck == true then
								if frame.namedButtons[buttonName] then
									if not frame.namedButtons[buttonName]:IsVisible() then
										frame.namedButtons[buttonName]:Show()
										frame.namedButtons[buttonNameBg1]:Show()
										frame.namedButtons[buttonNameBg2]:Show()
										frame.namedButtons[buttonName]:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset,
											enchyOffset)
										frame.namedButtons[buttonNameBg1]:SetPoint("BOTTOM", frame, "BOTTOM",
											-enchxOffset, enchyOffset)
										frame.namedButtons[buttonNameBg2]:SetPoint("TOPRIGHT",
											frame.namedButtons[buttonName], "TOPRIGHT", 10, 5)
										enchyOffset = enchyOffset + 50
										buttoncount = buttoncount + 1
									end
								else
									print("button not found")
								end
							end
						end
						-- insert show/hide from below for cusbuttonactive and disabled etc
						-- Increase yOffset for the next button
						--enchyOffset = enchyOffset + 50
					end
				end

				frame.otherEnchantsBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
				frame.otherEnchants:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset + 3)
				frame.otherEnchants:SetScript("OnClick", function()
					local customerName = PEtradeWho
					customerName = string.lower(customerName)
					ProEnchantersUpdateTradeWindowButtons(customerName)
					ProEnchantersUpdateTradeWindowText(customerName)
					customerName = CapFirstLetter(customerName)
					ProEnchantersCustomerNameEditBox:SetText(customerName)
				end)

				enchyOffset = enchyOffset + 25



				for _, key in ipairs(keys) do
					if buttoncount >= 10 then
						break
					end
					if ProEnchantersOptions.filters[key] == true then
						-- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
						local matsDiff = {}
						local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, key)
						local buttonName = key .. "buttonactive"
						local buttonNameBg = key .. "buttonactivebg"
						if matsMissingCheck ~= true then
							if frame.namedButtons[buttonName] then
								if not frame.namedButtons[buttonName]:IsVisible() then
									frame.namedButtons[buttonName]:Show()
									frame.namedButtons[buttonNameBg]:Show()
									frame.namedButtons[buttonName]:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset,
										enchyOffset)
									frame.namedButtons[buttonNameBg]:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset,
										enchyOffset)
									-- Additional logic here
									enchyOffset = enchyOffset + 50
									buttoncount = buttoncount + 1
								end
							else
								print("button not found")
							end
						elseif matsMissingCheck == true then
							if frame.namedButtons[buttonName] then
								frame.namedButtons[buttonName]:Hide()
								frame.namedButtons[buttonNameBg]:Hide()
							end
						end
					end
				end

				for _, key in ipairs(keys) do
					if buttoncount >= 10 then
						break
					end
					if ProEnchantersOptions.filters[key] == true then
						-- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
						local matsDiff = {}
						local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, key)
						local buttonName = key .. "buttondisabled"
						local buttonNameBg1 = key .. "buttondisabledbg1"
						local buttonNameBg2 = key .. "buttondisabledbg2"
						if matsMissingCheck ~= true then
							if frame.namedButtons[buttonName] then
								frame.namedButtons[buttonName]:Hide()
								frame.namedButtons[buttonNameBg1]:Hide()
								frame.namedButtons[buttonNameBg2]:Hide()
							end
						elseif matsMissingCheck == true then
							if frame.namedButtons[buttonName] then
								if not frame.namedButtons[buttonName]:IsVisible() then
									frame.namedButtons[buttonName]:Show()
									frame.namedButtons[buttonNameBg1]:Show()
									frame.namedButtons[buttonNameBg2]:Show()
									frame.namedButtons[buttonName]:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset,
										enchyOffset)
									frame.namedButtons[buttonNameBg1]:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset,
										enchyOffset)
									frame.namedButtons[buttonNameBg2]:SetPoint("TOPRIGHT", frame.namedButtons
										[buttonName], "TOPRIGHT", 10, 5)
									enchyOffset = enchyOffset + 50
									buttoncount = buttoncount + 1
								end
							else
								print("button not found")
							end
						end
					end
				end

				for i, id in ipairs(PEConvertablesId) do
					local name = PEConvertablesName[i]
					local buttonName = name .. "button"
					local buttonNameBg = name .. "bg"
					frame.namedButtons[buttonName]:SetScript("PostClick", function(self, btn, down)
						if (down) then
							frame.namedButtons[buttonName]:Hide()
							frame.namedButtons[buttonNameBg]:Hide()
							local customerName = PEtradeWho
							customerName = string.lower(customerName)
							print("Pressed: " .. name)
							C_Timer.After(1.2, function()
								ProEnchantersConvertMats(customerName, i)
								ProEnchantersUpdateTradeWindowButtons(customerName)
								ProEnchantersUpdateTradeWindowText(customerName)
							end)
						end
					end)
				end
			end
		end
	end
end

-- Forwarded Scan to Parse entire area (like AH, but more frequent in idle)
function PESearchInventoryForItems()
	local availableMats = {}
	local availableMatsIds = {}
	for bag = 0, NUM_BAG_SLOTS do -- Start from 0 to include the backpack
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemID = C_Container.GetContainerItemID(bag, slot)
			if itemID then
				for nickname, idString in pairs(ProEnchantersItemCacheTable) do
					if tostring(itemID) == idString then
						local info = C_Container.GetContainerItemInfo(bag, slot)
						if info and info.stackCount then
							local quantity = info.stackCount
							local itemName = select(2, GetItemInfo(itemID)) or "Unknown Item"
							if availableMats[itemName] then
								availableMats[itemName] = availableMats[itemName] + quantity
								availableMatsIds[itemID] = availableMatsIds[itemID] + quantity
							else
								availableMats[itemName] = quantity
								availableMatsIds[itemID] = quantity
							end
						end
					end
				end
			end
		end
	end
	return availableMats, availableMatsIds
end

-- End trade order on trade frame

--[[NEW MINIMAP ICON
-- For Leatrix and other addons that modify the minimap button it eventually should be changed to https://www.wowace.com/projects/libdbicon-1-0
-- Create a minimap button
local minimapButton = CreateFrame("Button", "ProEnchantersMinimapButton", Minimap)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetSize(32, 32)
minimapButton:SetFrameLevel(8)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Set the button's icon
local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\AddOns\\ProEnchanters\\custom_icon")
icon:SetSize(20, 20)
icon:SetPoint("CENTER")

-- Set the button's border
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT")

-- Position the button around the minimap
local function UpdateMinimapButtonPosition()
	local x = ProEnchantersOptions.minimapX or (Minimap:GetRight() - minimapButton:GetWidth() / 2)
	local y = ProEnchantersOptions.minimapY or (Minimap:GetTop() - minimapButton:GetHeight() / 2)
	minimapButton:ClearAllPoints()
	minimapButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetMovable(true)

minimapButton:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)

minimapButton:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local x, y = self:GetLeft(), self:GetTop()
	ProEnchantersOptions.minimapX = x
	ProEnchantersOptions.minimapY = y
	UpdateMinimapButtonPosition()
end)

UpdateMinimapButtonPosition()

minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:SetScript("OnClick", function(self, button)
	if button == "LeftButton" then
		if IsControlKeyDown() then
			--hide minimap button
			minimapButton:Hide()
		elseif ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsShown() then
			ProEnchantersWorkOrderFrame:Hide()
			ProEnchantersWorkOrderEnchantsFrame:Hide()
		elseif ProEnchantersWorkOrderFrame then
			ProEnchantersWorkOrderFrame:Show()
			ProEnchantersWorkOrderEnchantsFrame:Show()
			ResetFrames()
		end
	elseif button == "RightButton" then
		if IsShiftKeyDown() then
			-- Reset frame position and size
			if ProEnchantersWorkOrderFrame then
				ProEnchantersWorkOrderFrame:ClearAllPoints()
				ProEnchantersWorkOrderFrame:SetPoint("CENTER", UIParent, "CENTER")
				ProEnchantersWorkOrderFrame:SetSize(455, 630) -- Set to default size
			end
			if ProEnchantersWorkOrderEnchantsFrame then
				ProEnchantersWorkOrderEnchantsFrame:ClearAllPoints()
				ProEnchantersWorkOrderEnchantsFrame:SetPoint("TOPLEFT", ProEnchantersWorkOrderFrame, "TOPRIGHT", -1, 0)
				ProEnchantersWorkOrderEnchantsFrame:SetPoint("BOTTOMLEFT", ProEnchantersWorkOrderFrame, "BOTTOMRIGHT", -1,
					0)
			end
			print("|cFF800080ProEnchanters|r: Frame position and size have been reset.")
		else
			ProEnchantersOptions["WorkWhileClosed"] = not ProEnchantersOptions["WorkWhileClosed"]
			print("|cFF800080ProEnchanters|r: \"Work while closed\" is now " ..
				(ProEnchantersOptions["WorkWhileClosed"] and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
			-- Update the checkbox state
			if ProEnchantersSettingsFrame and ProEnchantersSettingsFrame.WorkWhileClosedCheckbox then
				ProEnchantersSettingsFrame.WorkWhileClosedCheckbox:SetChecked(ProEnchantersOptions["WorkWhileClosed"])
			end
		end
	end
end)

minimapButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine("|cFF800080ProEnchanters|r")
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cFFFFFFFFLeftclick:|r |cFFFFFF00Open|r")
	local workClosedColor = ProEnchantersOptions["WorkWhileClosed"] and "|cFF00FF00" or "|cFFFF0000"
	GameTooltip:AddLine("|cFFFFFFFFRightclick:|r " .. workClosedColor .. "Toggle: Work Closed|r")
	GameTooltip:AddLine("|cFFFFFFFFShift-Rightclick:|r |cFFFFFF00Reset Frame Pos and Size|r")
	GameTooltip:AddLine("|cFFFFFFFFCtrl-Leftclick:|r |cFFFFFF00Hide button, use /pe minimap to re-enable|r")
	GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)

icon:SetDrawLayer("ARTWORK")

if minimapButton.border then
	minimapButton.border:SetTexture(nil)
end

if not ProEnchantersOptions.minimapAngle then
	ProEnchantersOptions.minimapAngle = 45
end]]


local function LoadColorTables()
	-- Initialize ProEnchantersOptions as a table if it's nil
	if not ProEnchantersOptions then
		ProEnchantersOptions = {}
	end

	-- Ensure ProEnchantersOptions["Colors"] is a table
	if type(ProEnchantersOptions["Colors"]) ~= "table" then
		ProEnchantersOptions["Colors"] = {}
	end

	-- Now safely initialize Colors if it hasn't been done
	if not ProEnchantersOptions.Colors then
		ProEnchantersOptions.Colors = {}
	end

	-- Function to safely initialize color tables if they aren't already set
	local function initializeColorTable(colorPropertyName, defaultColor)
		if type(ProEnchantersOptions.Colors[colorPropertyName]) ~= "table" or next(ProEnchantersOptions.Colors[colorPropertyName]) == nil then
			ProEnchantersOptions.Colors[colorPropertyName] = defaultColor
		end
	end

	-- Initialize TopBarColor if it's not already set
	initializeColorTable("TopBarColor", { 22 / 255, 26 / 255, 48 / 255 })
	initializeColorTable("SecondaryBarColor", { 49 / 255, 48 / 255, 77 / 255 })
	initializeColorTable("MainWindowBackground", { 22 / 255, 26 / 255, 48 / 255 })
	initializeColorTable("BottomBarColor", { 22 / 255, 26 / 255, 48 / 255 })
	initializeColorTable("EnchantsButtonColor", { 22 / 255, 26 / 255, 48 / 255 })
	initializeColorTable("EnchantsButtonColorInactive", { 22 / 255, 26 / 255, 48 / 255 })
	initializeColorTable("BorderColor", { 49 / 255, 48 / 255, 77 / 255 })
	initializeColorTable("MainButtonColor", { 22 / 255, 26 / 255, 48 / 255 })
	initializeColorTable("SettingsWindowBackground", { 22 / 255, 26 / 255, 48 / 255 })
	initializeColorTable("ScrollBarColors", { 22 / 255, 26 / 255, 48 / 255 })

	if ProEnchantersOptions.Colors.OpacityAmount == nil then
		ProEnchantersOptions.Colors.OpacityAmount = 0.5
	end
end

local function LoadColorVariables1()
	--Color for Frames
	OpacityAmount = ProEnchantersOptions.Colors.OpacityAmount or 0.5

	TopBarColor = ProEnchantersOptions.Colors.TopBarColor or { 22 / 255, 26 / 255, 48 / 255 }
	r1, g1, b1 = unpack(TopBarColor)
	TopBarColorOpaque = { r1, g1, b1, 1 }
	TopBarColorTrans = { r1, g1, b1, OpacityAmount }

	SecondaryBarColor = ProEnchantersOptions.Colors.SecondaryBarColor or { 49 / 255, 48 / 255, 77 / 255 }
	r2, g2, b2 = unpack(SecondaryBarColor)
	SecondaryBarColorOpaque = { r2, g2, b2, 1 }
	SecondaryBarColorTrans = { r2, g2, b2, OpacityAmount }

	MainWindowBackground = ProEnchantersOptions.Colors.MainWindowBackground or { 22 / 255, 26 / 255, 48 / 255 }
	r3, g3, b3 = unpack(MainWindowBackground)
	MainWindowBackgroundOpaque = { r3, g3, b3, 1 }
	MainWindowBackgroundTrans = { r3, g3, b3, OpacityAmount }
end
local function LoadColorVariables2()
	OpacityAmount = ProEnchantersOptions.Colors.OpacityAmount or 0.5

	BottomBarColor = ProEnchantersOptions.Colors.BottomBarColor or { 22 / 255, 26 / 255, 48 / 255 }
	r4, g4, b4 = unpack(BottomBarColor)
	BottomBarColorOpaque = { r4, g4, b4, 1 }
	BottomBarColorTrans = { r4, g4, b4, OpacityAmount }

	EnchantsButtonColor = ProEnchantersOptions.Colors.EnchantsButtonColor or { 22 / 255, 26 / 255, 48 / 255 }
	r5, g5, b5 = unpack(EnchantsButtonColor)
	EnchantsButtonColorOpaque = { r5, g5, b5, 1 }
	EnchantsButtonColorTrans = { r5, g5, b5, OpacityAmount }

	EnchantsButtonColorInactive = ProEnchantersOptions.Colors.EnchantsButtonColorInactive or { 71 / 255, 71 / 255, 71 /
	255 }
	r6, g6, b6 = unpack(EnchantsButtonColorInactive)
	EnchantsButtonColorInactiveOpaque = { r6, g6, b6, 1 }
	EnchantsButtonColorInactiveTrans = { r6, g6, b6, OpacityAmount }

	BorderColor = ProEnchantersOptions.Colors.BorderColor or { 2 / 255, 2 / 255, 2 / 255 }
	r7, g7, b7 = unpack(BorderColor)
	BorderColorOpaque = { r7, g7, b7, 1 }
	BorderColorTrans = { r7, g7, b7, OpacityAmount }
end

local function LoadColorVariables3()
	OpacityAmount = ProEnchantersOptions.Colors.OpacityAmount or 0.5

	MainButtonColor = ProEnchantersOptions.Colors.MainButtonColor or { 22 / 255, 26 / 255, 48 / 255 }
	r8, g8, b8 = unpack(MainButtonColor)
	MainButtonColorOpaque = { r8, g8, b8, 1 }
	MainButtonColorTrans = { r8, g8, b8, OpacityAmount }

	SettingsWindowBackground = ProEnchantersOptions.Colors.SettingsWindowBackground or { 49 / 255, 48 / 255, 77 / 255 }
	r9, g9, b9 = unpack(SettingsWindowBackground)
	SettingsWindowBackgroundOpaque = { r9, g9, b9, 1 }
	SettingsWindowBackgroundTrans = { r9, g9, b9, OpacityAmount }

	ScrollBarColors = ProEnchantersOptions.Colors.ScrollBarColors or { 49 / 255, 48 / 255, 77 / 255 }
	r10, g10, b10 = unpack(ScrollBarColors)
	ButtonStandardAndThumb = { r10, g10, b10, 1 }
	r10P, r10DH = ((r10 * 255) / 4) / 255, ((r10 * 255) / 2) / 255
	g10P, g10DH = ((g10 * 255) / 4) / 255, ((g10 * 255) / 2) / 255
	b10P, b10DH = ((b10 * 255) / 4) / 255, ((b10 * 255) / 2) / 255
	ButtonPushed = { r10 + r10P, g10 + g10P, b10 + b10P, 1 }
	ButtonDisabled = { r10 - r10DH, g10 - g10DH, b10 - g10DH, 0.5 }
	ButtonHighlight = { r10 + r10DH, g10 + g10DH, b10 + b10DH, 1 }
end

local function OnAddonLoaded()
	-- Cache Items
	PEItemCache()

	-- Ensure the ProEnchantersOptions and its filters sub-table are properly initialized
	ProEnchantersOptions = ProEnchantersOptions or {}
	ProEnchantersOptions.filters = ProEnchantersOptions.filters or {}
	ProEnchantersOptions.favorites = ProEnchantersOptions.favorites or {}
	ProEnchantersOptions.whispertriggers = ProEnchantersOptions.whispertriggers or {}

	LoadColorTables()
	LoadColorVariables1()
	LoadColorVariables2()
	LoadColorVariables3()

	-- Now safe to register the events that use ProEnchantersWorkOrderFrame
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_SAY")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_YELL")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_CHANNEL")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_GUILD")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_PARTY")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_RAID")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_SYSTEM")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_WHISPER")
	ProEnchanters.frame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
	ProEnchanters.frame:RegisterEvent("TRADE_SHOW")
	ProEnchanters.frame:RegisterEvent("TRADE_CLOSED")
	ProEnchanters.frame:RegisterEvent("TRADE_REQUEST")
	ProEnchanters.frame:RegisterEvent("TRADE_MONEY_CHANGED")
	ProEnchanters.frame:RegisterEvent("TRADE_ACCEPT_UPDATE")
	ProEnchanters.frame:RegisterEvent("TRADE_REQUEST_CANCEL")
	ProEnchanters.frame:RegisterEvent("TRADE_UPDATE")
	ProEnchanters.frame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
	ProEnchanters.frame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
	ProEnchanters.frame:RegisterEvent("UI_INFO_MESSAGE")
	ProEnchanters.frame:RegisterEvent("UI_ERROR_MESSAGE")

	-- Create Filter Enchants Options Table
	for key, _ in pairs(EnchantsName) do
		-- Create Filters table
		if ProEnchantersOptions.filters[key] == nil or ProEnchantersOptions.filters[key] == "" then
			ProEnchantersOptions.filters[key] = true
		else
			ProEnchantersOptions.filters[key] = ProEnchantersOptions.filters[key]
		end
		-- Create Favorites table
		if ProEnchantersOptions.favorites[key] == nil or ProEnchantersOptions.favorites[key] == "" then
			ProEnchantersOptions.favorites[key] = false
		else
			ProEnchantersOptions.favorites[key] = ProEnchantersOptions.favorites[key]
		end
	end

	-- Ensure ProEnchantersOptions.invwords is initialized as a table
	if type(ProEnchantersOptions.invwords) ~= "table" then
		ProEnchantersOptions.invwords = {}
	end

	-- Check if the table is empty by attempting to iterate over it
	local isEmpty = true
	for _ in pairs(ProEnchantersOptions.invwords) do
		isEmpty = false
		break
	end

	-- If the table is empty, fill it with words from PEFilteredWordsOriginal
	if isEmpty then
		for _, word in ipairs(PEInvWordsOriginal) do
			table.insert(ProEnchantersOptions.invwords, word)
		end
	end

	-- Ensure ProEnchantersOptions.whispertriggers is initialized as a table
	if type(ProEnchantersOptions.whispertriggers) ~= "table" then
		ProEnchantersOptions.whispertriggers = {}
	end

	-- Check if the table is empty by attempting to iterate over it
	local isEmpty = true
	for _ in pairs(ProEnchantersOptions.whispertriggers) do
		isEmpty = false
		break
	end

	-- If the table is empty, fill it with words from PEFilteredWordsOriginal
	if isEmpty then
		for _, t in ipairs(PEWhisperTriggersOriginal) do
			table.insert(ProEnchantersOptions.whispertriggers, t)
		end
	end

	-- Ensure ProEnchantersOptions.filteredwords is initialized as a table
	if type(ProEnchantersOptions.filteredwords) ~= "table" then
		ProEnchantersOptions.filteredwords = {}
	end

	-- Check if the table is empty by attempting to iterate over it
	local isEmpty = true
	for _ in pairs(ProEnchantersOptions.filteredwords) do
		isEmpty = false
		break
	end

	-- If the table is empty, fill it with words from PEFilteredWordsOriginal
	if isEmpty then
		for _, word in ipairs(PEFilteredWordsOriginal) do
			-- Adding word to ProEnchantersOptions.filteredwords with the word as both the key and the value
			-- This is a common pattern for quick lookups to check if a word exists in the table
			table.insert(ProEnchantersOptions.filteredwords, word)
		end
	end

	-- Ensure ProEnchantersOptions.triggerwords is initialized as a table
	if type(ProEnchantersOptions.triggerwords) ~= "table" then
		ProEnchantersOptions.triggerwords = {}
	end

	-- Check if the table is empty by attempting to iterate over it
	local isEmpty = true
	for _ in pairs(ProEnchantersOptions.triggerwords) do
		isEmpty = false
		break
	end

	-- If the table is empty, fill it with words from PETriggerWordsOriginal
	if isEmpty then
		for _, word in ipairs(PETriggerWordsOriginal) do
			-- Adding word to ProEnchantersOptions.triggerwords with the word as both the key and the value
			-- This is a common pattern for quick lookups to check if a word exists in the table
			table.insert(ProEnchantersOptions.triggerwords, word)
		end
	end

	-- Setting Font Size
	if ProEnchantersOptions["FontSize"] == nil or ProEnchantersOptions["FontSize"] == "" then
		ProEnchantersOptions["FontSize"] = 12
		FontSize = 12
	else
		ProEnchantersOptions["FontSize"] = ProEnchantersOptions["FontSize"]
		FontSize = ProEnchantersOptions["FontSize"]
	end

	-- Setting max party size
	if ProEnchantersOptions["MaxPartySize"] == nil or ProEnchantersOptions["MaxPartySize"] == "" then
		ProEnchantersOptions["MaxPartySize"] = 40
	end

	-- Setting Invite Delays
	if ProEnchantersOptions["DelayInviteTime"] == nil or ProEnchantersOptions["DelayInviteTime"] == "" then
		ProEnchantersOptions["DelayInviteTime"] = 0
	end

	if ProEnchantersOptions["DelayInviteMsgTime"] == nil or ProEnchantersOptions["DelayInviteMsgTime"] == "" then
		ProEnchantersOptions["DelayInviteMsgTime"] = 0
	end


	-- Setting AutoInviteOptions
	if ProEnchantersOptions["RaidIcon"] == nil or ProEnchantersOptions["RaidIcon"] == "" then
		ProEnchantersOptions["RaidIcon"] = 0
		PESetRaidIcon = ProEnchantersOptions["RaidIcon"]
	else
		ProEnchantersOptions["RaidIcon"] = ProEnchantersOptions["RaidIcon"]
		PESetRaidIcon = ProEnchantersOptions["RaidIcon"]
	end


	if ProEnchantersOptions["AcceptGoldPopups"] ~= true then
		ProEnchantersOptions["AcceptGoldPopups"] = false
	end

	if ProEnchantersOptions["PartyJoinSound"] == nil then
		ProEnchantersOptions["PartyJoinSound"] = workwork
	end

	if ProEnchantersOptions["PotentialCustomerSound"] == nil then
		ProEnchantersOptions["PotentialCustomerSound"] = somethingneeddoing
	end

	if ProEnchantersOptions["NewTradeSound"] == nil then
		ProEnchantersOptions["NewTradeSound"] = whatyouwant
	end

	if ProEnchantersOptions["EnableSounds"] == nil then
		ProEnchantersOptions["EnableSounds"] = true
	end

	if ProEnchantersOptions["DebugLevel"] ~= 0 then
		ProEnchantersOptions["DebugLevel"] = 0
	end

	if ProEnchantersOptions["EnablePartyJoinSound"] == nil then
		ProEnchantersOptions["EnablePartyJoinSound"] = true
	end

	if ProEnchantersOptions["EnablePotentialCustomerSound"] == nil then
		ProEnchantersOptions["EnablePotentialCustomerSound"] = true
	end

	if ProEnchantersOptions["EnableNewTradeSound"] == nil then
		ProEnchantersOptions["EnableNewTradeSound"] = false
	end

	--[[if ProEnchantersOptions["DisplayMinimapButton"] == nil then
		ProEnchantersOptions["DisplayMinimapButton"] = true
	end]]

	if ProEnchantersOptions["WorkWhileClosed"] ~= true then
		WorkWhileClosed = false
		ProEnchantersOptions["WorkWhileClosed"] = WorkWhileClosed
	else
		WorkWhileClosed = ProEnchantersOptions["WorkWhileClosed"]
	end

	if ProEnchantersOptions["UseAllMats"] ~= true then
		useAllMats = false
		ProEnchantersOptions["UseAllMats"] = useAllMats
	else
		useAllMats = ProEnchantersOptions["UseAllMats"]
	end

	if ProEnchantersOptions["DelayWorkOrder"] ~= true then
		ProEnchantersOptions["DelayWorkOrder"] = false
	else
		ProEnchantersOptions["DelayWorkOrder"] = ProEnchantersOptions["DelayWorkOrder"]
	end

	if ProEnchantersOptions["WhisperMats"] ~= true then
		ProEnchantersOptions["WhisperMats"] = false
	else
		ProEnchantersOptions["WhisperMats"] = ProEnchantersOptions["WhisperMats"]
	end

	if ProEnchantersOptions["DisableWhisperCommands"] ~= true then
		ProEnchantersOptions["DisableWhisperCommands"] = false
	else
		ProEnchantersOptions["DisableWhisperCommands"] = ProEnchantersOptions["DisableWhisperCommands"]
	end

	if ProEnchantersOptions["AutoInvite"] ~= true then
		AutoInvite = false
		ProEnchantersOptions["AutoInvite"] = AutoInvite
	else
		AutoInvite = ProEnchantersOptions["AutoInvite"]
	end

	if ProEnchantersOptions["AutoInviteMsg"] == nil then
		AutoInviteMsg = "Enchanter here! Let me know what you need, sending an invite now :)"
		if AutoInviteMsg then
			ProEnchantersOptions["AutoInviteMsg"] = AutoInviteMsg
		end
	else
		AutoInviteMsg = ProEnchantersOptions["AutoInviteMsg"]
	end

	if ProEnchantersOptions["FailInvMsg"] == nil then
		FailInvMsg = "Enchanter here! Let me know what you need :)"
		if FailInvMsg then
			ProEnchantersOptions["FailInvMsg"] = FailInvMsg
		end
	else
		FailInveMsg = ProEnchantersOptions["FailInvMsg"]
	end

	if ProEnchantersOptions["FullInvMsg"] == nil then
		FullInvMsg = "Hey CUSTOMER, my group seems to be full at the moment, I'll invite you once I am able to :)"
		if FullInvMsg then
			ProEnchantersOptions["FullInvMsg"] = FullInvMsg
		end
	else
		FullInvMsg = ProEnchantersOptions["FullInvMsg"]
	end

	if ProEnchantersOptions["WelcomeMsg"] == nil then
		WelcomeMsg = "Hello there CUSTOMER o/, let me know what you need and feel free to trade when ready!"
		if WelcomeMsg then
			ProEnchantersOptions["WelcomeMsg"] = WelcomeMsg
		end
	else
		WelcomeMsg = ProEnchantersOptions["WelcomeMsg"]
		-- WelcomeMsg = "Hello there " .. playerName .. " o/, let me know what you need and feel free to trade when ready!"
	end

	if ProEnchantersOptions["TradeMsg"] == nil then
		TradeMsg = "Now trading CUSTOMER"
		if TradeMsg then
			ProEnchantersOptions["TradeMsg"] = TradeMsg
		end
	else
		TradeMsg = ProEnchantersOptions["TradeMsg"]
	end

	if ProEnchantersOptions["TipMsg"] == nil then
		TipMsg = "Thanks for the MONEY tip CUSTOMER <3"
		if TipMsg then
			ProEnchantersOptions["TipMsg"] = TipMsg
		end
	else
		-- TipMsg = "Enchanter here! Let me know what you need, sending an invite now :)"
		TipMsg = ProEnchantersOptions["TipMsg"]
	end

	if ProEnchantersOptions["TipEmote"] == nil then
		ProEnchantersOptions["TipEmote"] = "thank"
	end

	-- Ensure ProEnchantersOptions["AllChannels"] is a table
	if type(ProEnchantersOptions["AllChannels"]) ~= "table" then
		ProEnchantersOptions["AllChannels"] = {}
	end

	-- Check if ProEnchantersOptions.AllChannels is empty
	local allChannelsIsEmpty = true
	for _ in pairs(ProEnchantersOptions.AllChannels) do
		allChannelsIsEmpty = false
		break
	end

	-- If the table is empty, initialize it with default settings
	if allChannelsIsEmpty then
		ProEnchantersOptions.AllChannels["SayYell"] = true
		ProEnchantersOptions.AllChannels["LocalCity"] = true
		ProEnchantersOptions.AllChannels["TradeChannel"] = true
		ProEnchantersOptions.AllChannels["LFGChannel"] = true
		ProEnchantersOptions.AllChannels["LocalDefense"] = true
	end

	if ProEnchantersOptions["SortBy"] == nil then
		ProEnchantersOptions["SortBy"] = "Default"
	end


	-- Now safe to create the frames
	ProEnchantersWorkOrderFrame = ProEnchantersCreateWorkOrderFrame()
	ProEnchantersTradeWindowFrame = ProEnchantersTradeWindowCreateFrame()
	ProEnchantersOptionsFrame = ProEnchantersCreateOptionsFrame()
	ProEnchantersTriggersFrame = ProEnchantersCreateTriggersFrame()
	ProEnchantersWhisperTriggersFrame = ProEnchantersCreateWhisperTriggersFrame()
	ProEnchantersImportFrame = ProEnchantersCreateImportFrame()
	ProEnchantersCreditsFrame = ProEnchantersCreateCreditsFrame()
	ProEnchantersColorsFrame = ProEnchantersCreateColorsFrame()
	ProEnchantersGoldFrame = ProEnchantersCreateGoldFrame()
	ProEnchantersWorkOrderEnchantsFrame = ProEnchantersCreateWorkOrderEnchantsFrame(ProEnchantersWorkOrderFrame)
	ProEnchantersSoundsFrame = ProEnchantersCreateSoundsFrame()

	--[[Show or Hide minimap button
	if ProEnchantersOptions["DisplayMinimapButton"] == true then
		ProEnchantersMinimapButton:Show()
	elseif ProEnchantersOptions["DisplayMinimapButton"] == false then
		ProEnchantersMinimapButton:Hide()
	end]]

	print("|cff00ff00Thank's for using Pro Enchanters! Type /pehelp or /proenchantershelp for more info!|r")
	--CreatePEMacros()
	--FullResetFrames()
	ShowOpenWorkOrders()
end

-- Move the ADDON_LOADED event registration to the top
ProEnchanters.frame:RegisterEvent("ADDON_LOADED")

ProEnchanters.frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and select(1, ...) == "ProEnchanters" then
		print("ProEnchanters Addon Loaded Event Registered")
		OnAddonLoaded()
	elseif event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_SYSTEM" or event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		ProEnchanters_OnChatEvent(self, event, ...)
	elseif event == "TRADE_SHOW" or event == "TRADE_CLOSED" or event == "TRADE_REQUEST" or event == "TRADE_MONEY_CHANGED" or event == "TRADE_ACCEPT_UPDATE" or event == "TRADE_REQUEST_CANCEL" or event == "UI_INFO_MESSAGE" or event == "UI_ERROR_MESSAGE" or event == "TRADE_UPDATE" or event == "TRADE_PLAYER_ITEM_CHANGED" or event == "TRADE_TARGET_ITEM_CHANGED" then
		ProEnchanters_OnTradeEvent(self, event, ...)
		--print(event .. " triggered detected")
	end
end)

-- Slash Command Registration
SLASH_PROENCHANTERS1 = "/proenchanters"
SLASH_PROENCHANTERS2 = "/pe"
SLASH_PROENCHANTERSHELP1 = "/pehelp"
SLASH_PROENCHANTERSHELP2 = "/proenchantershelp"
SLASH_PROENCHANTERSFS1 = "/pefontsize"
SLASH_PROENCHANTERSFS2 = "/proenchantersfontsize"
SLASH_PROENCHANTERSDBG1 = "/pedebug"
SLASH_PROENCHANTERSDBG2 = "/proenchantersdebug"
SLASH_PROENCHANTERSCLEAR1 = "/peclearhistory"

-- Ensure ProEnchantersWorkOrderFrame is not nil before accessing it in your functions
SlashCmdList["PROENCHANTERS"] = function(msg)
	if msg == "reset" then
		FullResetFrames()
	elseif msg == "goldreset" then
		ResetGoldTraded()
	elseif msg == "minimap" then -- bookmark, can do icon:Hide("PELDB") or icon:Show("PELDB") to show icon, would need to pull the hide status from the new ProEnchantersDB saved variables something like self.db.profile.minimap.hide == true or false maybe
		if addon.db.profile.minimap.hide then
			icon:Show("ProEnchanters")
			addon.db.profile.minimap.hide = false
		else
			icon:Hide("ProEnchanters")
			addon.db.profile.minimap.hide = true
		end
	else
		if ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsShown() then
			ProEnchantersWorkOrderFrame:Hide()
			ProEnchantersWorkOrderEnchantsFrame:Hide()
		elseif ProEnchantersWorkOrderFrame then
			ProEnchantersWorkOrderFrame:Show()
			ProEnchantersWorkOrderEnchantsFrame:Show()
			ResetFrames()
		end
	end
end

SlashCmdList["PROENCHANTERSCLEAR"] = function(msg)
	if msg == "yes" then
		ProEnchantersTradeHistory = {}
		print(GREEN .. "Trade history has been cleared." .. ColorClose)
	else
		print(RED ..
			"This will completely NUKE your trade history and is not reversible. Please back up the ProEnchanters.lua and ProEnchanters.lua.bak in the WTF Account folder before continuing if you wish to be able to revert." ..
			ColorClose)
		print(RED ..
			"This will wipe currently open work order information as well and may cause issues, please do this before or after you are finished your work orders and a /reload is highly recommended after doing this." ..
			ColorClose)
		print(RED .. "To proceed with the data wipe, please do: /peclearhistory yes" .. ColorClose)
	end
end

SlashCmdList["PROENCHANTERSFS"] = function(msg)
	local NewFontSize = 12
	local convertedNumber = tonumber(msg)
	if convertedNumber then
		NewFontSize = convertedNumber
		ProEnchantersOptions["FontSize"] = NewFontSize
		FontSize = NewFontSize
		print(RED .. "Please do a /reload to enable the new font size" .. ColorClose)
	else
		print("Please use a regular number when trying to set a font size, default is 12")
	end
end

SlashCmdList["PROENCHANTERSDBG"] = function(msg)
	local convertedNumber = tonumber(msg)
	if type(convertedNumber) == "number" then
		ProEnchantersOptions["DebugLevel"] = convertedNumber
		if convertedNumber == 0 then
			print(GREENYELLOW .. "Debugging disabled. Set to 1 or higher to re-enable." .. ColorClose)
		elseif convertedNumber == 7 then
			print(ORANGE ..
				"Debugging set to 7 (mainly for whisper debugging), either /reload or do /pedebug 0 to disable." ..
				ColorClose)
		elseif convertedNumber == 8 then
			print(ORANGERED ..
				"Debugging set to 8 (mainly for potential customer debugging), either /reload or do /pedebug 0 to disable." ..
				ColorClose)
		elseif convertedNumber >= 9 then
			print(RED ..
				"Debugging set to max, all debugging commands will flow, either /reload or do /pedebug 0 to disable." ..
				ColorClose)
		else
			print(ORANGE ..
				"Debugging set to " .. ColorClose .. convertedNumber)
		end
	elseif ProEnchantersOptions["DebugLevel"] >= 0 then
		print(ORANGE .. "Current debugging set to " .. ColorClose .. convertedNumber)
	else
		print("Please input a number")
	end
end

SlashCmdList["PROENCHANTERSHELP"] = function(msg)
	local msg = string.lower(msg)
	if msg == nil or msg == "" then
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "Use /pe or /proenchanters to open the main window" .. ColorClose)
		print(ORANGE .. "You can also make a macro with the command as /pe to bind it to a key" .. ColorClose)
		print(ORANGE ..
			"Use /pe reset if you manage to get the main window completely off screen and need to reset its position" ..
			ColorClose)
		print(ORANGE ..
			"Use /pe goldreset if you want to reset the current sessions displayed gold traded in the main window to 0" ..
			ColorClose)
		print(ORANGE .. "Available help sections: main, enchants, trade, settings, credits" .. ColorClose)
		print(ORANGE .. "use '/pehelp section' for more specific information" .. ColorClose)
		print(ORANGE ..
			"If this is your first time loading the addon it is recommended to do a recipe sync, check out the setings section for more info " ..
			ColorClose)
		print(ORANGE .. "~ Generic Info ~" .. ColorClose)
		print(ORANGE .. "Right click on a player to create a work order without using the main window" .. ColorClose)
		print(ORANGE ..
			"If auto invite is disabled, hitting Invite on the pop up will invite them to your party and create a work order for them" ..
			ColorClose)
		print(ORANGE ..
			"Any text that you hover that goes from white to yellow is a button, and some buttons have multiple functions based on if a modifier key (Alt, Ctrl, Shift) is held" ..
			ColorClose)
		print(ORANGE .. "Top of the main windows when clicked will minimize the window to a smaller bar" .. ColorClose)
		print(ORANGE ..
			"You can disconnect the Enchants window and drag it to a different portion of your screen, click the < in the top right corner to rejoin to main window" ..
			ColorClose)
		print(ORANGE ..
			"Whenever you invite a player to your party through an Addons Action it will send a message to the potential customer. Manually inviting players does not send any messages" ..
			ColorClose)
	elseif msg == "main" then
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "~ Main Window Info ~" .. ColorClose)
		print(ORANGE .. "Enter a customer into the top text field and hit create to start a work order" .. ColorClose)
		print(ORANGE ..
			"The customer name in the top text field is considered the Focused customer, adding or removing enchants from the side panel will do so for the Focused customers work order" ..
			ColorClose)
		print(ORANGE ..
			"Work orders will log enchant requests when added or removed, any currency traded, items traded, and enchants completed" ..
			ColorClose)
		print(ORANGE ..
			"If you have many work orders open and need to find one quickly enter the customers name and his Create one more time, it will focus an open work order if one exists" ..
			ColorClose)
		print(ORANGE ..
			"Clicking on the work orders Customer Name will set that work order as the Focused work order" .. ColorClose)
		print(ORANGE ..
			"Clicking the Req Mats button will send a message with all the required mats added together for the requested enchants" ..
			ColorClose)
		print(ORANGE ..
			"Shift+Clicking the Req Mats button will send a message with all the requested enchants in short form" ..
			ColorClose)
		print(ORANGE .. "Ctrl+Clicking will remove all requested enchants so you can start fresh if needed" .. ColorClose)
		print(ORANGE ..
			"Clicking the X will mark the work order as completed, it is recommended to close work orders after your service is done and the player has left" ..
			ColorClose)
		print(ORANGE ..
			"The 'Auto Invite' Checkbox will automatically invite players that are found to be potential customers, if unchecked you will receive a popup notification instead" ..
			ColorClose)
		print(ORANGE ..
			"The Gold Traded readout is for your current active session, if you do a /reload, close the game, or change zones with a loading screen it will reset" ..
			ColorClose)
		print(ORANGE .. "Settings button opens the options" .. ColorClose)
		print(ORANGE ..
			"Hitting the Close button will close the window, hitting escape will close the window as well" .. ColorClose)
	elseif msg == "enchants" then
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "~ Enchants Info ~" .. ColorClose)
		print(ORANGE ..
			"Type into the Filter box to search for a specific enchant, any letters or numbers on the enchant button can be used for the search (ie Stam will show all enchants with Stam in the name)" ..
			ColorClose)
		print(ORANGE .. "Clicking on an enchant will add it as a request to the current Focused work order" .. ColorClose)
		print(ORANGE ..
			"You can add multiple of the same enchant as well (ie player wants 2x 1H weapon enchants, adding both will allow the rest of the addon to do the math for required mats, etc)" ..
			ColorClose)
		print(ORANGE .. "Shift+Clicking on an enchant will send the enchants name and mats required" .. ColorClose)
		print(ORANGE ..
			"Ctrl+Clicking on an enchant will remove it as a request from the current Focused work order" .. ColorClose)
		print(ORANGE ..
			"Alt+Clicking on an enchant will add it as a requested enchant to your current trade partners open work order (This allows you to add enchants on the fly without having to change your Focused work order)" ..
			ColorClose)
		print(ORANGE ..
			"Ctrl+Alt+Clicking on an enchant will remove it as a requested enchant from your current trade partner" ..
			ColorClose)
		print(ORANGE ..
			"Ctrl+Alt+Shift+Clicking on an enchant will remove it from the enchants window in the same way that unchecking it in the Settings window does, will have to re-check it off in the settings if you want it back" ..
			ColorClose)
	elseif msg == "trade" then
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "~ Trade Info ~" .. ColorClose)
		print(ORANGE .. "Requested enchants will show in the small window below the trade screen" .. ColorClose)
		print(ORANGE ..
			"Clicking the customers name on the small window below the trade screen will set the work order as the focus in the main window" ..
			ColorClose)
		print(ORANGE ..
			"Enchant buttons for the requested enchants will populate on the right hand side of the trade window, clicking on them will 'cast' the enchant spell for that enchant" ..
			ColorClose)
		print(ORANGE ..
			"When a player puts an item into the trade window, if it is in the Non Trade slot for enchanting, the enchant buttons will filter the buttons to match the gear slot type and prioritize the requested enchants as the first button at the bottom" ..
			ColorClose)
		print(ORANGE ..
			"When a trade is successful it will record any money traded, any items traded, and it will mark any enchants as completed to remove them from the outstanding requested enchants" ..
			ColorClose)
	elseif msg == "settings" then
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "~ Settings Info ~" .. ColorClose)
		print(ORANGE .. "use /pefontsize to set a new font size for most text within the addon" .. ColorClose)
		print(ORANGE ..
			"Alert potential customers while closed: If this is checked off you will still get notified of potential customers or auto invite them if you have the main window closed, otherwise the main window must be open for features to work" ..
			ColorClose)
		print(ORANGE ..
			"Include all channels: By default only the current City's chat and any /say or /yell messages will trigger potential customers, however checking this off will search all chat channels for potential customers such as Trade or LFG" ..
			ColorClose)
		print(ORANGE ..
			"Msg Settings: Setup the automatic messages based on the listed event (player invited, trade started, tip received, etc)" ..
			ColorClose)
		print(ORANGE ..
			"Msg Settings: Adding the word CUSTOMER in all caps will be replaced by the relevant customers name" ..
			ColorClose)
		print(ORANGE ..
			"Tip Msg Settings: Adding the word MONEY will be replaced by the amount of money received from a trade" ..
			ColorClose)
		print(ORANGE ..
			"Auto Raid Icon: When a player joins your party it will set your raid icon to the selected icon so customers can spot you easier" ..
			ColorClose)
		print(ORANGE ..
			"Enchant List Check Boxes: Checking an enchant off will display it in the main enchants window, unchecking will hide it" ..
			ColorClose)
		print(ORANGE ..
			"This way if you want to hide irrelevant enchants to lower the amount of buttons in the enchants window you can (ie hide minor striking weapon enchant so that when filtering for striking you only see lesser and above)" ..
			ColorClose)
		print(ORANGE ..
			"Reset Msgs button: This will reset all of the Msg text to their originals included with the addon" ..
			ColorClose)
		print(ORANGE ..
			"Sync Recipes button: With the default Enchanting window open, this will allow you to sync the available enchant buttons to your learned recipes (Really handy for season of discovery as available recipes are limited per phase)" ..
			ColorClose)
		print(ORANGE ..
			"It's recommended to start off by doing a recipe sync so that you can see only valid available enchants, and then modifying the remaining checked off recipes to meet your goals and preferences" ..
			ColorClose)
	elseif msg == "credits" then
		ProEnchantersCreditsFrame:Show()
		--[[print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "~ Credits ~" .. ColorClose)
		print(ORANGE .. "Created by EffinOwen" .. ColorClose)
		print(ORANGE .. "Check out my discord server for anything related to this addon or any of my other addons" .. ColorClose)
		print(ORANGE .. "https://discord.gg/qT6bRk4eUa" .. ColorClose)]]
	else
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "Help section not recognized" .. ColorClose)
		print(ORANGE .. "Available help sections: main, enchants, trade, settings, credits" .. ColorClose)
	end
end

-- Event handler function for chat and TRADES
function ProEnchanters_OnChatEvent(self, event, ...)
	local cmdFound = false
	if event == "CHAT_MSG_SYSTEM" then
		local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
		if LocalLanguage == nil then
			LocalLanguage = "English"
		end
		local localInvitedText = PEenchantingLocales["PlayerInvitedText"][LocalLanguage]
		local localInvitedTextSpecific = PEenchantingLocales["PlayerInvitedSpecificText"][LocalLanguage]
		local localPlayerJoinsParty = PEenchantingLocales["PlayerJoinsPartyText"][LocalLanguage]
		local localPlayerJoinsRaid = PEenchantingLocales["PlayerJoinsRaidText"][LocalLanguage]
		local localPlayerInGroup = PEenchantingLocales["PlayerAlreadyInGroupText"][LocalLanguage]
		if string.find(text, localInvitedText, 1, true) then
			if AddonInvite == false then
				NonAddonInvite = true
			end
			if AddonInvite == true then
				AddonInvite = false
				local matchString = string.gsub(localInvitedTextSpecific, "PLAYER", "(.+)")
				local playerName = string.match(text, matchString)
				local autoInvMsg = AutoInviteMsg
				local autoInvMsg2 = string.gsub(autoInvMsg, "CUSTOMER", playerName)
				if ProEnchantersOptions["WorkWhileClosed"] == true then
					if autoInvMsg2 == "" then
						print("Inviting " .. playerName)
					else
						if ProEnchantersOptions["DelayInviteMsgTime"] > 0 then
							C_Timer.After(ProEnchantersOptions["DelayInviteMsgTime"], function()
								SendChatMessage(autoInvMsg2, "WHISPER", nil, playerName)
							end)
						else
							SendChatMessage(autoInvMsg2, "WHISPER", nil, playerName)
						end
					end
				elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
					if autoInvMsg2 == "" then
						print("Inviting " .. playerName)
					else
						if ProEnchantersOptions["DelayInviteMsgTime"] > 0 then
							C_Timer.After(ProEnchantersOptions["DelayInviteMsgTime"], function()
								SendChatMessage(autoInvMsg2, "WHISPER", nil, playerName)
							end)
						else
							SendChatMessage(autoInvMsg2, "WHISPER", nil, playerName)
						end
					end
				end
			end
		elseif string.find(text, localPlayerJoinsParty, 1, true) then
			local matchString = ""
			if LocalLanguage == "Korean" or LocalLanguage == "Taiwanese" or LocalLanguage == "Chinese" then
				matchString = "(.+)" .. localPlayerJoinsParty
			else
				matchString = "(.+) " .. localPlayerJoinsParty
			end
			local playerName = string.match(text, matchString)
			if ProEnchantersOptions["WorkWhileClosed"] == true then
				local unit = GetUnitName("player")
				SetRaidTarget(unit, PESetRaidIcon)
				if ProEnchantersOptions["EnablePartyJoinSound"] == true then
					PESound(ProEnchantersOptions["PartyJoinSound"])
				end
				if ProEnchantersOptions["DelayWorkOrder"] == true and NonAddonInvite == true then
					NonAddonInvite = false
					WorkOrderPopup(playerName)
				elseif ProEnchantersOptions["WelcomeMsg"] then
					local WelcomeMsg = ProEnchantersOptions["WelcomeMsg"]
					local capPlayerName = CapFirstLetter(playerName)
					local FullWelcomeMsg = string.gsub(WelcomeMsg, "CUSTOMER", capPlayerName)
					if FullWelcomeMsg == "" then
						local playerName = string.lower(playerName)
						CreateCusWorkOrder(playerName)
					else
						SendChatMessage(FullWelcomeMsg, IsInRaid() and "RAID" or "PARTY")
						local playerName = string.lower(playerName)
						CreateCusWorkOrder(playerName)
					end
				else
					local capPlayerName = CapFirstLetter(playerName)
					SendChatMessage(
						"Hello there " .. capPlayerName .. " o/, let me know what you need and trade when ready!",
						IsInRaid() and "RAID" or "PARTY")
					local playerName = string.lower(playerName)
					CreateCusWorkOrder(playerName)
				end
				if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
					local playerName = string.lower(playerName)
					playerName = CapFirstLetter(playerName)
					ProEnchantersCustomerNameEditBox:SetText(playerName)
				end
			elseif ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
				local unit = GetUnitName("player")
				SetRaidTarget(unit, PESetRaidIcon)
				if ProEnchantersOptions["EnablePartyJoinSound"] == true then
					PESound(ProEnchantersOptions["PartyJoinSound"])
				end
				if ProEnchantersOptions["DelayWorkOrder"] == true and NonAddonInvite == true then
					NonAddonInvite = false
					WorkOrderPopup(playerName)
				elseif ProEnchantersOptions["WelcomeMsg"] then
					local WelcomeMsg = ProEnchantersOptions["WelcomeMsg"]
					local capPlayerName = CapFirstLetter(playerName)
					local FullWelcomeMsg = string.gsub(WelcomeMsg, "CUSTOMER", capPlayerName)
					if FullWelcomeMsg == "" then
						local playerName = string.lower(playerName)
						CreateCusWorkOrder(playerName)
					else
						SendChatMessage(FullWelcomeMsg, IsInRaid() and "RAID" or "PARTY")
						local playerName = string.lower(playerName)
						CreateCusWorkOrder(playerName)
					end
				else
					local capPlayerName = CapFirstLetter(playerName)
					SendChatMessage(
						"Hello there " .. capPlayerName .. " o/, let me know what you need and trade when ready!",
						IsInRaid() and "RAID" or "PARTY")
					local playerName = string.lower(playerName)
					CreateCusWorkOrder(playerName)
				end
				if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
					local playerName = string.lower(playerName)
					playerName = CapFirstLetter(playerName)
					ProEnchantersCustomerNameEditBox:SetText(playerName)
				end
			end
			NonAddonInvite = false
		elseif string.find(text, localPlayerJoinsRaid, 1, true) then
			local matchString = ""
			if LocalLanguage == "Korean" or LocalLanguage == "Taiwanese" or LocalLanguage == "Chinese" then
				matchString = "(.+)" .. localPlayerJoinsRaid
			else
				matchString = "(.+) " .. localPlayerJoinsRaid
			end
			local playerName = string.match(text, matchString)
			if ProEnchantersOptions["WorkWhileClosed"] == true then
				local unit = GetUnitName("player")
				SetRaidTarget(unit, PESetRaidIcon)
				if ProEnchantersOptions["EnablePartyJoinSound"] == true then
					PESound(ProEnchantersOptions["PartyJoinSound"])
				end
				if ProEnchantersOptions["DelayWorkOrder"] == true and NonAddonInvite == true then
					NonAddonInvite = false
					WorkOrderPopup(playerName)
				elseif ProEnchantersOptions["WelcomeMsg"] then
					local WelcomeMsg = ProEnchantersOptions["WelcomeMsg"]
					local capPlayerName = CapFirstLetter(playerName)
					local FullWelcomeMsg = string.gsub(WelcomeMsg, "CUSTOMER", capPlayerName)
					if FullWelcomeMsg == "" then
						local playerName = string.lower(playerName)
						CreateCusWorkOrder(playerName)
					else
						SendChatMessage(FullWelcomeMsg, IsInRaid() and "RAID" or "PARTY")
						local playerName = string.lower(playerName)
						CreateCusWorkOrder(playerName)
					end
				else
					local capPlayerName = CapFirstLetter(playerName)
					SendChatMessage(
						"Hello there " .. capPlayerName .. " o/, let me know what you need and trade when ready!",
						IsInRaid() and "RAID" or "PARTY")
					local playerName = string.lower(playerName)
					CreateCusWorkOrder(playerName)
				end
				if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
					local playerName = string.lower(playerName)
					playerName = CapFirstLetter(playerName)
					ProEnchantersCustomerNameEditBox:SetText(playerName)
				end
			elseif ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
				local unit = GetUnitName("player")
				SetRaidTarget(unit, PESetRaidIcon)
				if ProEnchantersOptions["EnablePartyJoinSound"] == true then
					PESound(ProEnchantersOptions["PartyJoinSound"])
				end
				if ProEnchantersOptions["DelayWorkOrder"] == true and NonAddonInvite == true then
					NonAddonInvite = false
					WorkOrderPopup(playerName)
				elseif ProEnchantersOptions["WelcomeMsg"] then
					local WelcomeMsg = ProEnchantersOptions["WelcomeMsg"]
					local capPlayerName = CapFirstLetter(playerName)
					local FullWelcomeMsg = string.gsub(WelcomeMsg, "CUSTOMER", capPlayerName)
					if FullWelcomeMsg == "" then
						local playerName = string.lower(playerName)
						CreateCusWorkOrder(playerName)
					else
						SendChatMessage(FullWelcomeMsg, IsInRaid() and "RAID" or "PARTY")
						local playerName = string.lower(playerName)
						CreateCusWorkOrder(playerName)
					end
				else
					local capPlayerName = CapFirstLetter(playerName)
					SendChatMessage(
						"Hello there " .. capPlayerName .. " o/, let me know what you need and trade when ready!",
						IsInRaid() and "RAID" or "PARTY")
					local playerName = string.lower(playerName)
					CreateCusWorkOrder(playerName)
				end
				if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
					local playerName = string.lower(playerName)
					playerName = CapFirstLetter(playerName)
					ProEnchantersCustomerNameEditBox:SetText(playerName)
				end
			end
			NonAddonInvite = false
		elseif string.find(text, localPlayerInGroup, 1, true) then
			if AddonInvite == false then
				NonAddonInvite = true
			end
			if AddonInvite == true then
				AddonInvite = false
				local matchString = ""
				if LocalLanguage == "Korean" or LocalLanguage == "Taiwanese" or LocalLanguage == "Chinese" then
					matchString = "(.+)" .. localPlayerInGroup
				else
					matchString = "(.+) " .. localPlayerInGroup
				end
				local playerName = string.match(text, matchString)
				local FailInvMsg = ProEnchantersOptions["FailInvMsg"]
				local FailInvMsg2 = string.gsub(FailInvMsg, "CUSTOMER", playerName)
				if ProEnchantersOptions["WorkWhileClosed"] == true then
					if FailInvMsg2 == "" then
						print("Invite failed for " .. playerName)
					else
						if ProEnchantersOptions["DelayInviteMsgTime"] > 0 then
							C_Timer.After(ProEnchantersOptions["DelayInviteMsgTime"], function()
								SendChatMessage(FailInvMsg2, "WHISPER", nil, playerName)
							end)
						else
							SendChatMessage(FailInvMsg2, "WHISPER", nil, playerName)
						end
					end
				elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
					if FailInvMsg2 == "" then
						print("Invite failed for " .. playerName)
					else
						if ProEnchantersOptions["DelayInviteMsgTime"] > 0 then
							C_Timer.After(ProEnchantersOptions["DelayInviteMsgTime"], function()
								SendChatMessage(FailInvMsg2, "WHISPER", nil, playerName)
							end)
						else
							SendChatMessage(FailInvMsg2, "WHISPER", nil, playerName)
						end
					end
				end
			end
		end
	elseif event == "CHAT_MSG_SAY" or event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_YELL" then
		-- Check for matching Emote
		local msg, author2, language, channelNameWithNumber, target, flags, unknown, channelNumber, channelName = ...
		local msg2 = string.lower(msg)
		local city = GetZoneText()
		local author = string.gsub(author2, "%-.*", "")
		local author3 = string.lower(author)
		if LocalLanguage == nil then
			LocalLanguage = "English"
		end
		local localGeneralChannel = PEenchantingLocales["GeneralChannelName"][LocalLanguage]
		local localLFGChannel = PEenchantingLocales["LFGChannelName"][LocalLanguage]
		local localTradeChannel = PEenchantingLocales["TradeChannelName"][LocalLanguage]
		local localDefenseChannel = PEenchantingLocales["DefenseChannelName"][LocalLanguage]
		local channelCheck = "General - " .. city
		local defenseCheck = "LocalDefense - " .. city
		local guildrecruitCheck = "GuildRecruitment - City"
		if ProEnchantersOptions["DebugLevel"] >= 9 then
			print("channelName/channelNumber/channelNameWithNumber from " ..
				author2 .. ": " .. channelName .. "/" .. channelNumber .. "/" .. channelNameWithNumber)
		end
		if ProEnchantersOptions.AllChannels["TradeChannel"] == true and string.find(channelName, localTradeChannel, 1, true) then
			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("Message found in Trade Channel: " .. channelName)
			end
			for _, tword in pairs(ProEnchantersOptions.triggerwords) do
				local check1 = false
				local check2 = false
				local check3 = false
				local check4 = false
				local startPos, endPos = string.find(msg2, tword)
				if string.find(msg2, tword, 1, true) then
					check1 = true
					if ProEnchantersOptions["DebugLevel"] >= 8 then
						print("Potential Customer " .. author2 .. " trigger found: " .. tword .. " found within " .. msg2)
					end
				end


				if startPos then
					-- Check if "ench" is at the start of the string or preceded by a space
					if startPos == 1 or string.sub(msg2, startPos - 1, startPos - 1) == " " then
						check2 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print(tword .. " does not have any leading characters, returning check2 as true")
						end
					else
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print(tword .. " is contained within a word, check2 returned as false")
						end
					end
				end

				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(msg2, filteredWord, 1, true) then
						check3 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("Potential Customer " ..
								author2 ..
								" filter found: " .. word .. " found within " .. msg2 .. ", check 3 returning false")
						end
						break
					end
				end
				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(author, filteredWord, 1, true) then
						check4 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("Potential Customer " ..
								author2 .. " name found in filter list, check 3 returning false")
						end
						break
					end
				end

				if check1 == true and check2 == true and check3 == false and check4 == false then
					if ProEnchantersOptions["DebugLevel"] >= 8 then
						print("All checks passed, continuing with potential customer invite or pop-up")
					end
					local playerName = author3
					local AutoInviteFlag = ProEnchantersOptions["AutoInvite"]
					if ProEnchantersOptions["WorkWhileClosed"] == true then
						if AutoInviteFlag == true then
							AddonInvite = true
							if AddonInvite == true then
								InviteUnitPEAddon(author2)
								PEPlayerInvited[playerName] = msg
							end
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
							PlaySound(SOUNDKIT.MAP_PING)
						elseif AutoInviteFlag == false then
							StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg, author2 }
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						end
					elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
						if AutoInviteFlag == true then
							AddonInvite = true
							if AddonInvite == true then
								InviteUnitPEAddon(author2)
								PEPlayerInvited[playerName] = msg
							end
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
							PlaySound(SOUNDKIT.MAP_PING)
						elseif AutoInviteFlag == false then
							StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg, author2 }
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						end
					end
				end
			end
		elseif ProEnchantersOptions.AllChannels["LFGChannel"] == true and string.find(channelName, localLFGChannel, 1, true) then
			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("Message found in LFG Channel: " .. channelName)
			end
			for _, tword in pairs(ProEnchantersOptions.triggerwords) do
				local check1 = false
				local check2 = false
				local check3 = false
				local check4 = false
				local startPos, endPos = string.find(msg2, tword)
				if string.find(msg2, tword, 1, true) then
					check1 = true
					if ProEnchantersOptions["DebugLevel"] >= 8 then
						print("Potential Customer " .. author2 .. " trigger found: " .. tword .. " found within " .. msg2)
					end
				end


				if startPos then
					-- Check if "ench" is at the start of the string or preceded by a space
					if startPos == 1 or string.sub(msg2, startPos - 1, startPos - 1) == " " then
						check2 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print(tword .. " does not have any leading characters, returning check2 as true")
						end
					else
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print(tword .. " is contained within a word, check2 returned as false")
						end
					end
				end

				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(msg2, filteredWord, 1, true) then
						check3 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("Potential Customer " ..
								author2 ..
								" filter found: " .. word .. " found within " .. msg2 .. ", check 3 returning false")
						end
						break
					end
				end
				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(author, filteredWord, 1, true) then
						check4 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("Potential Customer " ..
								author2 .. " name found in filter list, check 3 returning false")
						end
						break
					end
				end

				if check1 == true and check2 == true and check3 == false and check4 == false then
					if ProEnchantersOptions["DebugLevel"] >= 8 then
						print("All checks passed, continuing with potential customer invite or pop-up")
					end
					local playerName = author3
					local AutoInviteFlag = ProEnchantersOptions["AutoInvite"]
					if ProEnchantersOptions["WorkWhileClosed"] == true then
						if AutoInviteFlag == true then
							AddonInvite = true
							if AddonInvite == true then
								InviteUnitPEAddon(author2)
								PEPlayerInvited[playerName] = msg
							end
							PlaySound(SOUNDKIT.MAP_PING)
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						elseif AutoInviteFlag == false then
							StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg, author2 }
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						end
					elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
						if AutoInviteFlag == true then
							AddonInvite = true
							if AddonInvite == true then
								InviteUnitPEAddon(author2)
								PEPlayerInvited[playerName] = msg
							end
							PlaySound(SOUNDKIT.MAP_PING)
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						elseif AutoInviteFlag == false then
							StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg, author2 }
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						end
					end
				end
			end
		elseif ProEnchantersOptions.AllChannels["LocalDefense"] == true and string.find(channelName, localDefenseChannel, 1, true) then
			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("Message found in LFG Channel: " .. channelName)
			end
			for _, tword in pairs(ProEnchantersOptions.triggerwords) do
				local check1 = false
				local check2 = false
				local check3 = false
				local check4 = false
				local startPos, endPos = string.find(msg2, tword)
				if string.find(msg2, tword, 1, true) then
					check1 = true
					if ProEnchantersOptions["DebugLevel"] >= 8 then
						print("Potential Customer " .. author2 .. " trigger found: " .. tword .. " found within " .. msg2)
					end
				end


				if startPos then
					-- Check if "ench" is at the start of the string or preceded by a space
					if startPos == 1 or string.sub(msg2, startPos - 1, startPos - 1) == " " then
						check2 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print(tword .. " does not have any leading characters, returning check2 as true")
						end
					else
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print(tword .. " is contained within a word, check2 returned as false")
						end
					end
				end

				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(msg2, filteredWord, 1, true) then
						check3 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("Potential Customer " ..
								author2 ..
								" filter found: " .. word .. " found within " .. msg2 .. ", check 3 returning false")
						end
						break
					end
				end
				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(author, filteredWord, 1, true) then
						check4 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("Potential Customer " ..
								author2 .. " name found in filter list, check 3 returning false")
						end
						break
					end
				end

				if check1 == true and check2 == true and check3 == false and check4 == false then
					if ProEnchantersOptions["DebugLevel"] >= 8 then
						print("All checks passed, continuing with potential customer invite or pop-up")
					end
					local playerName = author3
					local AutoInviteFlag = ProEnchantersOptions["AutoInvite"]
					if ProEnchantersOptions["WorkWhileClosed"] == true then
						if AutoInviteFlag == true then
							AddonInvite = true
							if AddonInvite == true then
								InviteUnitPEAddon(author2)
								PEPlayerInvited[playerName] = msg
							end
							PlaySound(SOUNDKIT.MAP_PING)
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						elseif AutoInviteFlag == false then
							StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg, author2 }
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						end
					elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
						if AutoInviteFlag == true then
							AddonInvite = true
							if AddonInvite == true then
								InviteUnitPEAddon(author2)
								PEPlayerInvited[playerName] = msg
							end
							PlaySound(SOUNDKIT.MAP_PING)
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						elseif AutoInviteFlag == false then
							StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg, author2 }
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						end
					end
				end
			end
		elseif ProEnchantersOptions.AllChannels["LocalCity"] == true and string.find(channelName, localGeneralChannel, 1, true) then
			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("Message found in local city channel: " .. channelName)
			end
			for _, tword in pairs(ProEnchantersOptions.triggerwords) do
				local check1 = false
				local check2 = false
				local check3 = false
				local check4 = false
				local startPos, endPos = string.find(msg2, tword)
				if string.find(msg2, tword, 1, true) then
					check1 = true
					if ProEnchantersOptions["DebugLevel"] >= 8 then
						print("Potential Customer " .. author2 .. " trigger found: " .. tword .. " found within " .. msg2)
					end
				end


				if startPos then
					-- Check if "ench" is at the start of the string or preceded by a space
					if startPos == 1 or string.sub(msg2, startPos - 1, startPos - 1) == " " then
						check2 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print(tword .. " does not have any leading characters, returning check2 as true")
						end
					else
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print(tword .. " is contained within a word, check2 returned as false")
						end
					end
				end

				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(msg2, filteredWord, 1, true) then
						check3 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("Potential Customer " ..
								author2 ..
								" filter found: " .. word .. " found within " .. msg2 .. ", check 3 returning false")
						end
						break
					end
				end
				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(author, filteredWord, 1, true) then
						check4 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("Potential Customer " ..
								author2 .. " name found in filter list, check 3 returning false")
						end
						break
					end
				end

				if check1 == true and check2 == true and check3 == false and check4 == false then
					if ProEnchantersOptions["DebugLevel"] >= 8 then
						print("All checks passed, continuing with potential customer invite or pop-up")
					end
					local playerName = author3
					local AutoInviteFlag = ProEnchantersOptions["AutoInvite"]
					if ProEnchantersOptions["WorkWhileClosed"] == true then
						if AutoInviteFlag == true then
							AddonInvite = true
							if AddonInvite == true then
								InviteUnitPEAddon(author2)
								PEPlayerInvited[playerName] = msg
							end
							PlaySound(SOUNDKIT.MAP_PING)
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						elseif AutoInviteFlag == false then
							StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg, author2 }
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						end
					elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
						if AutoInviteFlag == true then
							AddonInvite = true
							if AddonInvite == true then
								InviteUnitPEAddon(author2)
								PEPlayerInvited[playerName] = msg
							end
							PlaySound(SOUNDKIT.MAP_PING)
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						elseif AutoInviteFlag == false then
							StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg, author2 }
							if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
								PESound(ProEnchantersOptions["PotentialCustomerSound"])
							end
						end
					end
				end
			end
		elseif ProEnchantersOptions.AllChannels["SayYell"] == true then
			if channelName == "" or channelName == nil then
				if ProEnchantersOptions["DebugLevel"] >= 7 then
					print("Message found in local say/yell chat")
				end
				for _, tword in pairs(ProEnchantersOptions.triggerwords) do
					local check1 = false
					local check2 = false
					local check3 = false
					local check4 = false
					local startPos, endPos = string.find(msg2, tword)
					if string.find(msg2, tword, 1, true) then
						check1 = true
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("Potential Customer " ..
								author2 .. " trigger found: " .. tword .. " found within " .. msg2)
						end
					end


					if startPos then
						-- Check if "ench" is at the start of the string or preceded by a space
						if startPos == 1 or string.sub(msg2, startPos - 1, startPos - 1) == " " then
							check2 = true
							if ProEnchantersOptions["DebugLevel"] >= 8 then
								print(tword .. " does not have any leading characters, returning check2 as true")
							end
						else
							if ProEnchantersOptions["DebugLevel"] >= 8 then
								print(tword .. " is contained within a word, check2 returned as false")
							end
						end
					end

					for _, word in pairs(ProEnchantersOptions.filteredwords) do
						local filteredWord = word
						if string.find(msg2, filteredWord, 1, true) then
							check3 = true
							if ProEnchantersOptions["DebugLevel"] >= 8 then
								print("Potential Customer " ..
									author2 ..
									" filter found: " .. word .. " found within " .. msg2 .. ", check 3 returning false")
							end
							break
						end
					end
					for _, word in pairs(ProEnchantersOptions.filteredwords) do
						local filteredWord = word
						if string.find(author, filteredWord, 1, true) then
							check4 = true
							if ProEnchantersOptions["DebugLevel"] >= 8 then
								print("Potential Customer " ..
									author2 .. " name found in filter list, check 3 returning false")
							end
							break
						end
					end

					if check1 == true and check2 == true and check3 == false and check4 == false then
						if ProEnchantersOptions["DebugLevel"] >= 8 then
							print("All checks passed, continuing with potential customer invite or pop-up")
						end
						local playerName = author3
						local AutoInviteFlag = ProEnchantersOptions["AutoInvite"]
						if ProEnchantersOptions["WorkWhileClosed"] == true then
							if AutoInviteFlag == true then
								AddonInvite = true
								if AddonInvite == true then
									InviteUnitPEAddon(author2)
									PEPlayerInvited[playerName] = msg
								end
								PlaySound(SOUNDKIT.MAP_PING)
								if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
									PESound(ProEnchantersOptions["PotentialCustomerSound"])
								end
							elseif AutoInviteFlag == false then
								StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg,
									author2 }
								if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
									PESound(ProEnchantersOptions["PotentialCustomerSound"])
								end
							end
						elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
							if AutoInviteFlag == true then
								AddonInvite = true
								if AddonInvite == true then
									InviteUnitPEAddon(author2)
									PEPlayerInvited[playerName] = msg
								end
								PlaySound(SOUNDKIT.MAP_PING)
								if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
									PESound(ProEnchantersOptions["PotentialCustomerSound"])
								end
							elseif AutoInviteFlag == false then
								StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = { playerName, msg,
									author2 }
								if ProEnchantersOptions["EnablePotentialCustomerSound"] == true then
									PESound(ProEnchantersOptions["PotentialCustomerSound"])
								end
							end
						end
					end
				end
			end
		end
	elseif event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" then
		local msg, author2 = ...
		local msgLower = string.lower(msg)
		local author = string.gsub(author2, "%-.*", "")
		local author3 = string.lower(author)
		cmdFound = false
		local startPos, endPos = string.find(msg, "!")
		local enchantKey = ""
		local languageId = ""
		if string.find(msg, "!", 1, true) then
			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("Possible !command found from " .. author2 .. ": ! found within " .. msg)
			end

			if startPos then
				if ProEnchantersOptions["DebugLevel"] >= 9 then
					print("startPos listed as: " .. tostring(startPos))
				end
				if startPos == 1 or string.sub(msg, startPos - 1, startPos - 1) == " " then
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print("found at start of message, setting cmdFound to true")
					end
					cmdFound = true
				else
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print("! is not at the start of the sentence, ignoring")
					end
				end
			end
		end
		local customcmdFound = 0
		if cmdFound == true then
			if ProEnchantersOptions["DisableWhisperCommands"] == true then
				if ProEnchantersOptions["DebugLevel"] >= 7 then
					print("!commands currently disabled, ending checks")
				end
				return
			end
			customcmdFound = 1
			for i, v in ipairs(ProEnchantersOptions.whispertriggers) do
				for cmd, rmsg in pairs(v) do
					local cmd = string.lower(cmd)
					local wmsg = tostring(rmsg)
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print("comparing: " .. msgLower .. " to " .. cmd)
					end
					if tostring(msgLower) == tostring(cmd) then
						if ProEnchantersOptions["DebugLevel"] >= 7 then
							print("Found matching !command")
						end
						for itemID, _ in string.gmatch(wmsg, "%[(%d+)%]") do
							if ProEnchantersOptions["DebugLevel"] >= 7 then
								print("itemID returned as " .. itemID)
							end
							local newitemLink = select(2, GetItemInfo(itemID))
							if ProEnchantersOptions["DebugLevel"] >= 7 then
								print(newitemLink)
							end
							-- Escape the square brackets in the replacement pattern
							wmsg = string.gsub(wmsg, "%[" .. itemID .. "%]", newitemLink)
						end
						if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" then
							SendChatMessage(wmsg, IsInRaid() and "RAID" or "PARTY")
							customcmdFound = 2
							return
						elseif event == "CHAT_MSG_GUILD" then
							SendChatMessage(wmsg, "GUILD")
							customcmdFound = 2
							return
						end
					end
				end
			end
		end

		if ProEnchantersOptions["DebugLevel"] >= 7 then
			print("No matching command found, continuing to possible enchant lookup")
		end

		if customcmdFound == 1 then
			enchantKey, languageId = findEnchantByKeyAndLanguage(msg)
		end

		if cmdFound == true and customcmdFound == 1 then
			if ProEnchantersOptions["DisableWhisperCommands"] == true then
				if ProEnchantersOptions["DebugLevel"] >= 7 then
					print("!commands currently disabled, ending checks")
				end
				return
			end
			if enchantKey then
				--enchantKey, languageId
				if ProEnchantersOptions.filters[enchantKey] == true then
					local enchName, enchStats = GetEnchantName(enchantKey, languageId)
					local matsReq = ProEnchants_GetReagentList(enchantKey)
					local msgReq = enchName .. enchStats .. " Mats Required: " .. matsReq
					if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" then
						SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
						customcmdFound = 2
						return
					elseif event == "CHAT_MSG_GUILD" then
						SendChatMessage(msgReq, "GUILD")
						customcmdFound = 2
						return
					end
				elseif ProEnchantersOptions.filters[enchantKey] == false then
					local enchName, enchStats = GetEnchantName(enchantKey)
					local enchNameLocalized, _ = GetEnchantName(enchantKey)
					local enchType = string.match(enchName, "%-%s*(.+)")
					local enchTypeSpecific = string.match(enchType, ".+%s(%w+)$")
					local enchSlot = string.match(enchName, "^Enchant%s+([%w%s-]-)%s-%s")
					local recommendations = {} -- Use a table to store unique recommendations

					for k, v in pairs(EnchantsName) do
						if string.find(v, enchSlot, 1, true) then
							if string.find(v, enchTypeSpecific, 1, true) then
								local eName, eStats = GetEnchantName(k)
								local enchKey = k
								local eType = string.match(eName, "%-%s*(.+)")
								local recommendation = eType ..
									eStats -- Create a unique identifier for the recommendation
								if not recommendations[k] and ProEnchantersOptions.filters[k] == true then
									-- Only add if not already in the table and filter is true
									recommendations[k] = eStats
								end
							end
						end
					end

					local sortableRecommendations = {}
					for rec, k in pairs(recommendations) do
						local numPart = tonumber(k:match("(%d+)"))
						if numPart then
							table.insert(sortableRecommendations, { key = numPart, rec = rec })
						end
					end

					-- Sort the table based on the numerical part of the enchKey
					table.sort(sortableRecommendations, function(a, b) return a.key > b.key end)

					-- Now, build your enchRecommends string in sorted order
					local enchRecommends = ""
					for _, t in ipairs(sortableRecommendations) do
						local enchKey = t
							.rec                                      -- This should be t.rec based on your table structure
						local numPart = t
							.key                                      -- This is not directly used below but corrected for clarity
						local enchName, enchStats = GetEnchantName(enchKey, languageId) -- Assuming GetEnchantName function uses enchKey correctly
						if enchRecommends == "" then
							enchRecommends = enchName .. enchStats
						else
							enchRecommends = enchRecommends .. ", " .. enchName .. enchStats
						end
					end

					if enchRecommends ~= "" then
						local msgReq = enchNameLocalized ..
							enchStats .. " not available, here's some similar enchants for " .. enchSlot .. "'s:"
						local msgRecs = enchRecommends
						if string.len(msgRecs) <= 255 then
							if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" then
								SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
								SendChatMessage(msgRecs, IsInRaid() and "RAID" or "PARTY")
								customcmdFound = 2
								return
							elseif event == "CHAT_MSG_GUILD" then
								SendChatMessage(msgReq, "GUILD")
								SendChatMessage(msgRecs, "GUILD")
								customcmdFound = 2
								return
							end
						elseif string.len(msgRecs) >= 256 and string.len(msgRecs) <= 510 then
							local msgRecs1 = string.sub(msgRecs, 1, 255)
							local msgRecs2 = string.sub(msgRecs, 256, 510)
							if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" then
								SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
								SendChatMessage(msgRecs1, IsInRaid() and "RAID" or "PARTY")
								SendChatMessage(msgRecs2, IsInRaid() and "RAID" or "PARTY")
								customcmdFound = 2
								return
							elseif event == "CHAT_MSG_GUILD" then
								SendChatMessage(msgReq, "GUILD")
								SendChatMessage(msgRecs1, "GUILD")
								SendChatMessage(msgRecs2, "GUILD")
								customcmdFound = 2
								return
							end
						elseif string.len(msgRecs) > 510 then
							local msgRecs1 = string.sub(msgRecs, 1, 255)
							local msgRecs2 = string.sub(msgRecs, 256, 510)
							local msgRecs3 = string.sub(msgRecs, 511, 765)
							if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" then
								SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
								SendChatMessage(msgRecs1, IsInRaid() and "RAID" or "PARTY")
								SendChatMessage(msgRecs2, IsInRaid() and "RAID" or "PARTY")
								SendChatMessage(msgRecs3, IsInRaid() and "RAID" or "PARTY")
								customcmdFound = 2
								return
							elseif event == "CHAT_MSG_GUILD" then
								SendChatMessage(msgReq, "GUILD")
								SendChatMessage(msgRecs1, "GUILD")
								SendChatMessage(msgRecs2, "GUILD")
								SendChatMessage(msgRecs3, "GUILD")
								customcmdFound = 2
								return
							end
						end
					else
						local msgReq = enchNameLocalized ..
							enchStats ..
							" not available and I couldn't find anything similar, would you like something else?"
						if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" then
							SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
							customcmdFound = 2
							return
						elseif event == "CHAT_MSG_GUILD" then
							SendChatMessage(msgReq, "GUILD")
							customcmdFound = 2
							return
						end
					end
				else
					local msgReq =
					"No Enchant with that name found, please make sure you're using the specific enchant name such as !enchant chest - lesser stats"
					if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" then
						SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
						customcmdFound = 2
						return
					elseif event == "CHAT_MSG_GUILD" then
						SendChatMessage(msgReq, "GUILD")
						customcmdFound = 2
						return
					end
				end
				cmdFound = true
				return
			end
			cmdFound = false
			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("cmdFound is false, end of check")
			end
		end
	elseif event == "CHAT_MSG_WHISPER" then
		local msg, author2 = ...
		local msgLower = string.lower(msg)
		local msg2 = "Whispered: " .. msgLower
		local author = string.gsub(author2, "%-.*", "")
		local author3 = string.lower(author)
		cmdFound = false
		local startPos, endPos = string.find(msg, "!")
		local isPartyFull = MaxPartySizeCheck()
		local enchantKey = ""
		local languageId = ""
		if ProEnchantersOptions["DebugLevel"] >= 7 then
			print("Whisper received")
		end
		if string.find(msg, "!", 1, true) then
			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("Possible whisper command found from " .. author2 .. ": ! found within " .. msg)
			end

			if startPos then
				if ProEnchantersOptions["DebugLevel"] >= 9 then
					print("startPos listed as: " .. tostring(startPos))
				end
				if startPos == 1 or string.sub(msg, startPos - 1, startPos - 1) == " " then
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print("found at start of message, setting cmdFound to true")
					end
					cmdFound = true
				else
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print("! is not at the start of the sentence, ignoring")
					end
				end
			end
		end
		local customcmdFound = 0
		if cmdFound == true then
			if ProEnchantersOptions["DisableWhisperCommands"] == true then
				if ProEnchantersOptions["DebugLevel"] >= 7 then
					print("!whisper commands currently disabled, ending checks")
				end
				return
			end
			customcmdFound = 1
			for i, v in ipairs(ProEnchantersOptions.whispertriggers) do
				for cmd, rmsg in pairs(v) do
					local cmd = string.lower(cmd)
					local wmsg = tostring(rmsg)
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print("comparing: " .. msgLower .. " to " .. cmd)
					end
					if tostring(msgLower) == tostring(cmd) then
						if ProEnchantersOptions["DebugLevel"] >= 7 then
							print("Found matching !command")
						end
						for itemID, _ in string.gmatch(wmsg, "%[(%d+)%]") do
							if ProEnchantersOptions["DebugLevel"] >= 7 then
								print("itemID returned as " .. itemID)
							end
							local newitemLink = select(2, GetItemInfo(itemID))
							if ProEnchantersOptions["DebugLevel"] >= 7 then
								print(newitemLink)
							end
							-- Escape the square brackets in the replacement pattern
							wmsg = string.gsub(wmsg, "%[" .. itemID .. "%]", newitemLink)
						end
						SendChatMessage(wmsg, "WHISPER", nil, author2)
						customcmdFound = 2
						return
					end
				end
			end
		end

		if ProEnchantersOptions["DebugLevel"] >= 7 then
			print("No matching command found, continuing to possible enchant lookup")
		end

		if customcmdFound == 1 then
			enchantKey, languageId = findEnchantByKeyAndLanguage(msg)
		end

		if cmdFound == true and customcmdFound == 1 then
			if ProEnchantersOptions["DisableWhisperCommands"] == true then
				if ProEnchantersOptions["DebugLevel"] >= 7 then
					print("!whisper commands currently disabled, ending checks")
				end
				return
			end
			if enchantKey then
				--enchantKey, languageId
				if ProEnchantersOptions.filters[enchantKey] == true then
					local enchName, enchStats = GetEnchantName(enchantKey, languageId)
					local matsReq = ProEnchants_GetReagentList(enchantKey)
					local msgReq = enchName .. enchStats .. " Mats Required: " .. matsReq
					SendChatMessage(msgReq, "WHISPER", nil, author2)
					return
				elseif ProEnchantersOptions.filters[enchantKey] == false then
					local enchName, enchStats = GetEnchantName(enchantKey)
					local enchNameLocalized, _ = GetEnchantName(enchantKey)
					local enchType = string.match(enchName, "%-%s*(.+)")
					local enchTypeSpecific = string.match(enchType, ".+%s(%w+)$")
					local enchSlot = string.match(enchName, "^Enchant%s+([%w%s-]-)%s-%s")
					local recommendations = {} -- Use a table to store unique recommendations

					for k, v in pairs(EnchantsName) do
						if string.find(v, enchSlot, 1, true) then
							if string.find(v, enchTypeSpecific, 1, true) then
								local eName, eStats = GetEnchantName(k)
								local enchKey = k
								local eType = string.match(eName, "%-%s*(.+)")
								local recommendation = eType ..
									eStats -- Create a unique identifier for the recommendation
								if not recommendations[k] and ProEnchantersOptions.filters[k] == true then
									-- Only add if not already in the table and filter is true
									recommendations[k] = eStats
								end
							end
						end
					end

					local sortableRecommendations = {}
					for rec, k in pairs(recommendations) do
						local numPart = tonumber(k:match("(%d+)"))
						if numPart then
							table.insert(sortableRecommendations, { key = numPart, rec = rec })
						end
					end

					-- Sort the table based on the numerical part of the enchKey
					table.sort(sortableRecommendations, function(a, b) return a.key > b.key end)

					-- Now, build your enchRecommends string in sorted order
					local enchRecommends = ""
					for _, t in ipairs(sortableRecommendations) do
						local enchKey = t
							.rec                                      -- This should be t.rec based on your table structure
						local numPart = t
							.key                                      -- This is not directly used below but corrected for clarity
						local enchName, enchStats = GetEnchantName(enchKey, languageId) -- Assuming GetEnchantName function uses enchKey correctly
						if enchRecommends == "" then
							enchRecommends = enchName .. enchStats
						else
							enchRecommends = enchRecommends .. ", " .. enchName .. enchStats
						end
					end

					if enchRecommends ~= "" then
						local msgReq = enchNameLocalized ..
							enchStats .. " not available, here's some similar enchants for " .. enchSlot .. "'s:"
						local msgRecs = enchRecommends
						if string.len(msgRecs) <= 255 then
							SendChatMessage(msgReq, "WHISPER", nil, author2)
							SendChatMessage(msgRecs, "WHISPER", nil, author2)
						elseif string.len(msgRecs) >= 256 and string.len(msgRecs) <= 510 then
							local msgRecs1 = string.sub(msgRecs, 1, 255)
							local msgRecs2 = string.sub(msgRecs, 256, 510)
							SendChatMessage(msgReq, "WHISPER", nil, author2)
							SendChatMessage(msgRecs1, "WHISPER", nil, author2)
							SendChatMessage(msgRecs2, "WHISPER", nil, author2)
						elseif string.len(msgRecs) > 510 then
							local msgRecs1 = string.sub(msgRecs, 1, 255)
							local msgRecs2 = string.sub(msgRecs, 256, 510)
							local msgRecs3 = string.sub(msgRecs, 511, 765)
							SendChatMessage(msgReq, "WHISPER", nil, author2)
							SendChatMessage(msgRecs1, "WHISPER", nil, author2)
							SendChatMessage(msgRecs2, "WHISPER", nil, author2)
							SendChatMessage(msgRecs3, "WHISPER", nil, author2)
						end
					else
						local msgReq = enchNameLocalized ..
							enchStats ..
							" not available and I couldn't find anything similar, would you like something else?"
						SendChatMessage(msgReq, "WHISPER", nil, author2)
					end
				else
					local msgReq =
					"No Enchant with that name found, please make sure you're using the specific enchant name such as !enchant chest - lesser stats"
					SendChatMessage(msgReq, "WHISPER", nil, author2)
				end
				cmdFound = true
				return
			end
			cmdFound = false

			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("cmdFound is false, end of check")
			end
		end

		if cmdFound == false then
			for _, tword in pairs(ProEnchantersOptions.invwords) do
				local check1 = false
				local check2 = false
				local startPos, endPos = string.find(msgLower, tword)
				if string.find(msgLower, tword, 1, true) then
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print(tword .. " found in msg: " .. msgLower)
					end
					check1 = true
				end

				if check1 == true then -- and check2 == true then
					if isPartyFull ~= true then
						local playerName = author3
						local AutoInviteFlag = ProEnchantersOptions["AutoInvite"]
						if ProEnchantersOptions["WorkWhileClosed"] == true then
							--if AutoInviteFlag == true then
							InviteUnitPEAddon(author2)
							PEPlayerInvited[playerName] = msg
							PlaySound(SOUNDKIT.MAP_PING)
							--elseif AutoInviteFlag == false then
							--	StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
							--end
						elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
							--if AutoInviteFlag == true then
							InviteUnitPEAddon(author2)
							PlaySound(SOUNDKIT.MAP_PING)
							PEPlayerInvited[playerName] = msg
							--elseif AutoInviteFlag == false then
							--	StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
							--end
						end
					elseif isPartyFull == true then
						PlaySound(SOUNDKIT.MAP_PING)
						local playerName = author3
						PEPlayerInvited[playerName] = msg
						local partyFullMsg = string.gsub(FullInvMsg, "CUSTOMER", playerName)
						if ProEnchantersOptions["WorkWhileClosed"] == true then
							if partyFullMsg == "" then
								print("Party full, cannot invite " .. playerName)
							else
								SendChatMessage(partyFullMsg, "WHISPER", nil, playerName)
							end
						elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
							if partyFullMsg == "" then
								print("Party full, cannot invite " .. playerName)
							else
								SendChatMessage(partyFullMsg, "WHISPER", nil, playerName)
							end
						end
					end
					return
				end
			end
		end
	elseif event == "CHAT_MSG_WHISPER_INFORM" then
		local msg, author2 = ...
		local msgLower = string.lower(msg)
		local msg2 = "Whispered: " .. msgLower
		local author = string.gsub(author2, "%-.*", "")
		local author3 = string.lower(author)
		cmdFound = false
		local startPos, endPos = string.find(msg, "!")
		local isPartyFull = MaxPartySizeCheck()
		local enchantKey = ""
		local languageId = ""
		if ProEnchantersOptions["DebugLevel"] >= 7 then
			print("Whisper received")
		end
		if string.find(msg, "!", 1, true) then
			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("Possible whisper command found from " .. author2 .. ": ! found within " .. msg)
			end

			if startPos then
				if ProEnchantersOptions["DebugLevel"] >= 9 then
					print("startPos listed as: " .. tostring(startPos))
				end
				if startPos == 1 or string.sub(msg, startPos - 1, startPos - 1) == " " then
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print("found at start of message, setting cmdFound to true")
					end
					cmdFound = true
				else
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print("! is not at the start of the sentence, ignoring")
					end
				end
			end
		end
		local customcmdFound = 0
		if cmdFound == true then
			if ProEnchantersOptions["DisableWhisperCommands"] == true then
				if ProEnchantersOptions["DebugLevel"] >= 7 then
					print("!whisper commands currently disabled, ending checks")
				end
				return
			end
			customcmdFound = 1
			for i, v in ipairs(ProEnchantersOptions.whispertriggers) do
				for cmd, rmsg in pairs(v) do
					local cmd = string.lower(cmd)
					local wmsg = tostring(rmsg)
					if ProEnchantersOptions["DebugLevel"] >= 7 then
						print("comparing: " .. msgLower .. " to " .. cmd)
					end
					if tostring(msgLower) == tostring(cmd) then
						if ProEnchantersOptions["DebugLevel"] >= 7 then
							print("Found matching !command")
						end
						for itemID, _ in string.gmatch(wmsg, "%[(%d+)%]") do
							if ProEnchantersOptions["DebugLevel"] >= 7 then
								print("itemID returned as " .. itemID)
							end
							local newitemLink = select(2, GetItemInfo(itemID))
							if ProEnchantersOptions["DebugLevel"] >= 7 then
								print(newitemLink)
							end
							-- Escape the square brackets in the replacement pattern
							wmsg = string.gsub(wmsg, "%[" .. itemID .. "%]", newitemLink)
						end
						SendChatMessage(wmsg, "WHISPER", nil, author2)
						customcmdFound = 2
						return
					end
				end
			end
		end

		if ProEnchantersOptions["DebugLevel"] >= 7 then
			print("No matching command found, continuing to possible enchant lookup")
		end

		if customcmdFound == 1 then
			enchantKey, languageId = findEnchantByKeyAndLanguage(msg)
		end

		if cmdFound == true and customcmdFound == 1 then
			if ProEnchantersOptions["DisableWhisperCommands"] == true then
				if ProEnchantersOptions["DebugLevel"] >= 7 then
					print("!whisper commands currently disabled, ending checks")
				end
				return
			end
			if enchantKey then
				--enchantKey, languageId
				if ProEnchantersOptions.filters[enchantKey] == true then
					local enchName, enchStats = GetEnchantName(enchantKey, languageId)
					local matsReq = ProEnchants_GetReagentList(enchantKey)
					local msgReq = enchName .. enchStats .. " Mats Required: " .. matsReq
					SendChatMessage(msgReq, "WHISPER", nil, author2)
					return
				elseif ProEnchantersOptions.filters[enchantKey] == false then
					local enchName, enchStats = GetEnchantName(enchantKey)
					local enchNameLocalized, _ = GetEnchantName(enchantKey)
					local enchType = string.match(enchName, "%-%s*(.+)")
					local enchTypeSpecific = string.match(enchType, ".+%s(%w+)$")
					local enchSlot = string.match(enchName, "^Enchant%s+([%w%s-]-)%s-%s")
					local recommendations = {} -- Use a table to store unique recommendations

					for k, v in pairs(EnchantsName) do
						if string.find(v, enchSlot, 1, true) then
							if string.find(v, enchTypeSpecific, 1, true) then
								local eName, eStats = GetEnchantName(k)
								local enchKey = k
								local eType = string.match(eName, "%-%s*(.+)")
								local recommendation = eType ..
									eStats -- Create a unique identifier for the recommendation
								if not recommendations[k] and ProEnchantersOptions.filters[k] == true then
									-- Only add if not already in the table and filter is true
									recommendations[k] = eStats
								end
							end
						end
					end

					local sortableRecommendations = {}
					for rec, k in pairs(recommendations) do
						local numPart = tonumber(k:match("(%d+)"))
						if numPart then
							table.insert(sortableRecommendations, { key = numPart, rec = rec })
						end
					end

					-- Sort the table based on the numerical part of the enchKey
					table.sort(sortableRecommendations, function(a, b) return a.key > b.key end)

					-- Now, build your enchRecommends string in sorted order
					local enchRecommends = ""
					for _, t in ipairs(sortableRecommendations) do
						local enchKey = t
							.rec                                      -- This should be t.rec based on your table structure
						local numPart = t
							.key                                      -- This is not directly used below but corrected for clarity
						local enchName, enchStats = GetEnchantName(enchKey, languageId) -- Assuming GetEnchantName function uses enchKey correctly
						if enchRecommends == "" then
							enchRecommends = enchName .. enchStats
						else
							enchRecommends = enchRecommends .. ", " .. enchName .. enchStats
						end
					end

					if enchRecommends ~= "" then
						local msgReq = enchNameLocalized ..
							enchStats .. " not available, here's some similar enchants for " .. enchSlot .. "'s:"
						local msgRecs = enchRecommends
						if string.len(msgRecs) <= 255 then
							SendChatMessage(msgReq, "WHISPER", nil, author2)
							SendChatMessage(msgRecs, "WHISPER", nil, author2)
						elseif string.len(msgRecs) >= 256 and string.len(msgRecs) <= 510 then
							local msgRecs1 = string.sub(msgRecs, 1, 255)
							local msgRecs2 = string.sub(msgRecs, 256, 510)
							SendChatMessage(msgReq, "WHISPER", nil, author2)
							SendChatMessage(msgRecs1, "WHISPER", nil, author2)
							SendChatMessage(msgRecs2, "WHISPER", nil, author2)
						elseif string.len(msgRecs) > 510 then
							local msgRecs1 = string.sub(msgRecs, 1, 255)
							local msgRecs2 = string.sub(msgRecs, 256, 510)
							local msgRecs3 = string.sub(msgRecs, 511, 765)
							SendChatMessage(msgReq, "WHISPER", nil, author2)
							SendChatMessage(msgRecs1, "WHISPER", nil, author2)
							SendChatMessage(msgRecs2, "WHISPER", nil, author2)
							SendChatMessage(msgRecs3, "WHISPER", nil, author2)
						end
					else
						local msgReq = enchNameLocalized ..
							enchStats ..
							" not available and I couldn't find anything similar, would you like something else?"
						SendChatMessage(msgReq, "WHISPER", nil, author2)
					end
				else
					local msgReq =
					"No Enchant with that name found, please make sure you're using the specific enchant name such as !enchant chest - lesser stats"
					SendChatMessage(msgReq, "WHISPER", nil, author2)
				end
				cmdFound = true
				return
			end
			cmdFound = false

			if ProEnchantersOptions["DebugLevel"] >= 7 then
				print("cmdFound is false, end of check")
			end
		end
	end
	cmdFound = false
end

---- OnTradeEventCurrent
function ProEnchanters_OnTradeEvent(self, event, ...)
	if event == "TRADE_REQUEST" then
		local playerName = ...
		--: Get players name that requested the trade
		--: Target Player and update WorkOrderFrame
	elseif event == "TRADE_SHOW" then
		PEtradeWho = UnitName("NPC")
		LastTradedPlayer = UnitName("NPC")
		local customerName = PEtradeWho
		customerName = string.lower(customerName)
		-- AddTradeLine() to generate a work order for all trades? Optional
		if ProEnchantersOptions["WorkWhileClosed"] == true then
			if ProEnchantersOptions["EnableNewTradeSound"] == true then
				PESound(ProEnchantersOptions["NewTradeSound"])
			end
			if not ProEnchantersTradeHistory[customerName] then
				CreateCusWorkOrder(customerName)
				if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
					local capCustomerName = CapFirstLetter(customerName)
					ProEnchantersCustomerNameEditBox:SetText(capCustomerName)
				end
			elseif ProEnchantersTradeHistory[customerName] then
				for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
					local lowerFrameCheck = string.lower(frameInfo.Frame.customerName)
					local lowerCusName = string.lower(customerName)
					if lowerFrameCheck == lowerCusName and frameInfo.Completed then
						CreateCusWorkOrder(customerName)
						if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
							local capCustomerName = CapFirstLetter(customerName)
							ProEnchantersCustomerNameEditBox:SetText(capCustomerName)
						end
					end
				end
			end
		elseif ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
			if ProEnchantersOptions["EnableNewTradeSound"] == true then
				PESound(ProEnchantersOptions["NewTradeSound"])
			end
			if not ProEnchantersTradeHistory[customerName] then
				CreateCusWorkOrder(customerName)
				if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
					local capCustomerName = CapFirstLetter(customerName)
					ProEnchantersCustomerNameEditBox:SetText(capCustomerName)
				end
			elseif ProEnchantersTradeHistory[customerName] then
				for id, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
					local lowerFrameCheck = string.lower(frameInfo.Frame.customerName)
					local lowerCusName = string.lower(customerName)
					if lowerFrameCheck == lowerCusName and frameInfo.Completed then
						CreateCusWorkOrder(customerName)
						if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
							local capCustomerName = CapFirstLetter(customerName)
							ProEnchantersCustomerNameEditBox:SetText(capCustomerName)
						end
					end
				end
			end
			if ProEnchantersOptions["TradeMsg"] then
				if ProEnchantersOptions["TradeMsg"] == "" then
					print("Now trading " .. customerName)
				else
					local tradeMsg = ProEnchantersOptions["TradeMsg"]
					local capPlayerName = CapFirstLetter(customerName)
					local newtradeMsg = string.gsub(tradeMsg, "CUSTOMER", capPlayerName)
					SendChatMessage(newtradeMsg, IsInRaid() and "RAID" or "PARTY")
				end
			else
				local capPlayerName = CapFirstLetter(customerName)
				SendChatMessage("Now trading with " .. capPlayerName, IsInRaid() and "RAID" or "PARTY")
			end
		end
		ProEnchantersLoadTradeWindowFrame(customerName)
		ProEnchantersUpdateTradeWindowText(customerName)
	elseif (event == "TRADE_MONEY_CHANGED") then
		PlayerMoney = GetPlayerTradeMoney()
		TargetMoney = GetTargetTradeMoney()
		--Items Traded Start
	elseif (event == "TRADE_PLAYER_ITEM_CHANGED") or (event == "TRADE_TARGET_ITEM_CHANGED") then
		PEtradeWho = UnitName("NPC")
		local customerName = PEtradeWho
		customerName = string.lower(customerName)
		local target = customerName
		local player = UnitName("player")
		player = string.lower(player)
		local SlotTypeInput = ""

		PEtradeWhoItems.player = {}
		PEtradeWhoItems.target = {}
		ItemsTraded = false

		for slot = 1, 7 do
			local _, _, playerQuantity = GetTradePlayerItemInfo(slot)
			local playerItemLink = GetTradePlayerItemLink(slot)
			local _, _, targetQuantity = GetTradeTargetItemInfo(slot)
			local targetItemLink = GetTradeTargetItemLink(slot)

			-- Enchants
			local _, _, _, _, _, targetEnchant = GetTradeTargetItemInfo(7);
			local _, _, _, _, playerEnchant = GetTradePlayerItemInfo(7);

			-- Self Items Traded

			if playerEnchant ~= nil then
				PEtradeWhoItems.player[slot] = {
					link = playerItemLink,
					quantity = playerQuantity,
					enchant =
						playerEnchant
				}
				ItemsTraded = true
			elseif slot < 7 then
				PEtradeWhoItems.player[slot] = { link = playerItemLink, quantity = playerQuantity }
				ItemsTraded = true
			end

			-- Target Items Traded
			if targetEnchant ~= nil then
				PEtradeWhoItems.target[slot] = {
					link = targetItemLink,
					quantity = targetQuantity,
					enchant =
						targetEnchant
				}
				ItemsTraded = true
			elseif slot < 7 then
				PEtradeWhoItems.target[slot] = { link = targetItemLink, quantity = targetQuantity }
				ItemsTraded = true
			end
		end

		ProEnchantersUpdateTradeWindowButtons(customerName)
		ProEnchantersUpdateTradeWindowText(customerName)

		-- ItemsTraded = true
		-- Items Traded End
	elseif (event == "TRADE_ACCEPT_UPDATE") then
		local customerName = PEtradeWho
		customerName = string.lower(customerName)
		local target = customerName
		local player = UnitName("player")
		player = string.lower(player)
		PlayerMoney = GetPlayerTradeMoney()
		TargetMoney = GetTargetTradeMoney()
		local SlotTypeInput = ""

		PEtradeWhoItems.player = {}
		PEtradeWhoItems.target = {}
		ItemsTraded = false

		for slot = 1, 7 do
			local _, _, playerQuantity = GetTradePlayerItemInfo(slot)
			local playerItemLink = GetTradePlayerItemLink(slot)
			local _, _, targetQuantity = GetTradeTargetItemInfo(slot)
			local targetItemLink = GetTradeTargetItemLink(slot)

			-- Enchants
			local _, _, _, _, _, targetEnchant = GetTradeTargetItemInfo(7);
			local _, _, _, _, playerEnchant = GetTradePlayerItemInfo(7);

			-- Self Items Traded
			if playerEnchant ~= nil then
				PEtradeWhoItems.player[slot] = {
					link = playerItemLink,
					quantity = playerQuantity,
					enchant =
						playerEnchant
				}
				ItemsTraded = true
			elseif slot < 7 then
				PEtradeWhoItems.player[slot] = { link = playerItemLink, quantity = playerQuantity }
				ItemsTraded = true
			end

			-- Target Items Traded
			if slot < 7 then
				PEtradeWhoItems.target[slot] = { link = targetItemLink, quantity = targetQuantity }
				ItemsTraded = true
			elseif targetEnchant ~= nil then
				PEtradeWhoItems.target[slot] = {
					link = targetItemLink,
					quantity = targetQuantity,
					enchant =
						targetEnchant
				}
				ItemsTraded = true
			end
		end
		ProEnchantersUpdateTradeWindowButtons(customerName)
		ProEnchantersUpdateTradeWindowText(customerName)


		-- ItemsTraded = true
		-- Items Traded End
	elseif (event == "TRADE_REQUEST_CANCEL") then
		PEresetCurrentTradeData();
	elseif (event == "UI_INFO_MESSAGE" or event == "UI_ERROR_MESSAGE") then
		local type, msg = ...;
		if (msg == ERR_TRADE_BAG_FULL or msg == ERR_TRADE_TARGET_BAG_FULL or msg == ERR_TRADE_CANCELLED
				or msg == ERR_TRADE_TARGET_MAX_LIMIT_CATEGORY_COUNT_EXCEEDED_IS) then
			PEresetCurrentTradeData()
		elseif (msg == ERR_TRADE_COMPLETE) then
			PEdoTrade()
		end
	elseif event == "TRADE_CLOSED" then
		RemoveTradeWindowInfo()
	end
end

-- Enable close on Escape pressed
tinsert(UISpecialFrames, "ProEnchantersWorkOrderFrame")

-- Function to hide all frames
local function HideAllFrames()
	ProEnchantersWorkOrderFrame:Hide()
	ProEnchantersWorkOrderEnchantsFrame:Hide()
	ProEnchantersOptionsFrame:Hide()
	ProEnchantersTriggersFrame:Hide()
	ProEnchantersWhisperTriggersFrame:Hide()
	ProEnchantersImportFrame:Hide()
	ProEnchantersGoldFrame:Hide()
	ProEnchantersCreditsFrame:Hide()
	ProEnchantersColorsFrame:Hide()
end

-- Register the PLAYER_REGEN_DISABLED event
ProEnchanters.frame:RegisterEvent("PLAYER_REGEN_DISABLED")

-- Add the event handler
ProEnchanters.frame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_REGEN_DISABLED" then
		HideAllFrames()
	elseif event == "ADDON_LOADED" and select(1, ...) == "ProEnchanters" then
		print("ProEnchanters Addon Loaded Event Registered")
		OnAddonLoaded()
	elseif event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_SYSTEM" or event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		ProEnchanters_OnChatEvent(self, event, ...)
	elseif event == "TRADE_SHOW" or event == "TRADE_CLOSED" or event == "TRADE_REQUEST" or event == "TRADE_MONEY_CHANGED" or event == "TRADE_ACCEPT_UPDATE" or event == "TRADE_REQUEST_CANCEL" or event == "UI_INFO_MESSAGE" or event == "UI_ERROR_MESSAGE" or event == "TRADE_UPDATE" or event == "TRADE_PLAYER_ITEM_CHANGED" or event == "TRADE_TARGET_ITEM_CHANGED" then
		ProEnchanters_OnTradeEvent(self, event, ...)
	end
end)
