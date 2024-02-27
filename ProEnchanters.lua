-- ProEnchanters.lua localization
--local _, L = ...;
 --print(L["Hello World!"]);
function test8utf()
	local line = ""
	for k, v in pairs(utf8_lc_uc) do
		line = line .. ", " .. k .. " = " .. v
	end
	print(line)
end

function CapFirstLetter(word)
    if word == nil or word == "" then return word end  -- Check for empty or nil word
    local firstLetter = string.sub(word, 1, 1)
    local mappedLetter = utf8_lc_uc[firstLetter]  -- Direct lookup
    if mappedLetter then
        firstLetter = mappedLetter
    end
    local restOfWord = string.sub(word, 2)
    return firstLetter .. restOfWord
end


-- First Initilizations
ProEnchantersOptions = ProEnchantersOptions or {}
ProEnchantersOptions.filters = {}
WorkOrderFrames = {}
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
local useAllMats = false
local maxPartySizeReached = false
local debugLevel = 0


function MaxPartySizeCheck()
	local maxPartySize = tonumber(ProEnchantersOptions["MaxPartySize"]) or 40
	local currentPartySize = 0
	local isInGroup = IsInGroup()

	if isInGroup == true then
		currentPartySize = tonumber(GetNumGroupMembers())
	end

	if maxPartySize > currentPartySize then
		return false
	elseif maxPartySize <= currentPartySize then
		return true
	end
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

local AllChannels = ProEnchantersOptions["AllChannels"] or false
--[[local WelcomeMsg = ""
local TipMsg = ""
local AutoInvMsg = ""]]

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
    preferredIndex = 3,  -- Avoid taint issues
}

StaticPopupDialogs["AUTO_INVITE_POPUP"] = {
	text = "Enter text for Auto Invite Message",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnShow = function(self)
		self.editBox:SetText(AutoInviteMsg)
	end,
	OnAccept = function(self)
		ProEnchantersOptions["AutoInviteMsg"] = (self.editBox:GetText())
		if AutoInviteMsg ~= ProEnchantersOptions["AutoInviteMsg"] then
		AutoInviteMsg = ProEnchantersOptions["AutoInviteMsg"]
		else
		end
	end,
	EditBoxOnEnterPressed = function(self)	
		ProEnchantersOptions["AutoInviteMsg"] = (self.editBox:GetText())
		if AutoInviteMsg ~= ProEnchantersOptions["AutoInviteMsg"] then
			AutoInviteMsg = ProEnchantersOptions["AutoInviteMsg"]
		else
		end
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	hasEditBox = true,
	editBoxWidth = 500,
	maxLetters = 250,
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
    preferredIndex = 3,  -- Avoid taint issues
}

-- Function to reposition WorkOrderEnchantsFrame next to WorkOrderFrame
local function RepositionEnchantsFrame(WorkOrderEnchantsFrame)
    if WorkOrderEnchantsFrame then
        WorkOrderEnchantsFrame:ClearAllPoints()
        WorkOrderEnchantsFrame:SetPoint("TOPLEFT", ProEnchantersWorkOrderFrame, "TOPRIGHT", 0, 0)
    end
end

local function ResetFrames()
    --ProEnchantersWorkOrderFrame:ClearAllPoints()
    --ProEnchantersWorkOrderFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    RepositionEnchantsFrame(WorkOrderEnchantsFrame)
end

local function FullResetFrames()
    ProEnchantersWorkOrderFrame:ClearAllPoints()
    ProEnchantersWorkOrderFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    RepositionEnchantsFrame(WorkOrderEnchantsFrame)
end

-- PopUp Menu to create work order
local function WorkOrderButton(self)
	if self.value == "WorkOrderButton" then
		local dropdownMenu = _G["UIDROPDOWNMENU_INIT_MENU"]
			if(dropdownMenu.name ~= UnitName("player")) then
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

--[[hooksecurefunc("SetItemRef", function(link)
	local linkType, addon, param1, param2 = strsplit(":", link)
	print(linkType .. " " .. addon .. " " .. param1 .. " " .. param2)
	if linkType == "addon" and addon == "ProEnchanters" then
		local enchRemove = param1
		local customerName = param2
		RemoveRequestedEnchant(customerName, enchRemove)
	end
end)]]

--yOffset's for frame generation

local yOffset = -5
local yOffsetoriginal = -80
local enchyOffset = 5
local enchyOffsetoriginal = -40


--Color for Frames
local HeaderColor = {22/255, 26/255, 48/255}
local r1, g1, b1 = unpack(HeaderColor)
local HeaderOpaque = {r1, g1, b1, 1}
local HeaderTrans = {r1, g1, b1, 0.5}

local TitleColor = {182/255, 187/255, 196/255}
local r2, g2, b2 = unpack(TitleColor)
local TitleOpaque = {r2, g2, b2, 1}
local TitleTrans = {r2, g2, b2, 0.5}

local LightBgColor = {240/255, 236/255, 229/255}
local r3, g3, b3 = unpack(LightBgColor)
local LightBgOpaque = {r3, g3, b3, 1}
local LightBgTrans = {r3, g3, b3, 0.5}

local DarkBgColor = {49/255, 48/255, 77/255}
local r4, g4, b4 = unpack(DarkBgColor)
local DarkBgOpaque = {r4, g4, b4, 1}
local DarkBgTrans = {r4, g4, b4, 0.5}

local GreyedColor = {71/255, 71/255, 71/255}
local r5, g5, b5 = unpack(GreyedColor)
local GreyedOpaque = {r5, g5, b5, 1}
local GreyedTrans = {r5, g5, b5, 0.5}

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
ProEnchantersCreditsFrame = nil
ProEnchantersGoldLogFrame = nil

-- Trigger Words Table
PESupporters = {
	"Lurrx",
	"Pen",
	"Braa",
	"Emoree",
	"Sechmann",
	"Okazaki"
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
		["!help"] = "Hello! Try using !info or !addon for more infomation. You can also request the mats for an enchant by whispering me the enchant name with a ! infront, example: !enchant boots - stamina"
	},
	[2] = {
		["!info"] = "As I am using the Pro Enchanter's add-on (!addon for more info) I am able to create large Enchant lists with required mats quickly to share with you. If you have any questions or requests feel free to ask :) check out !help for some other commands"
	},
	[3] = {
		["!addon"] = "I am using the Pro Enchanter's add-on on curseforge: https://www.curseforge.com/wow/addons/pro-enchanters :)"
	}
}

-- Enchants Names
EnchantsName = {
	ENCH1="Enchant 2H Weapon - Agility",
	ENCH2="Enchant 2H Weapon - Greater Impact",
	ENCH3="Enchant 2H Weapon - Major Intellect",
	ENCH4="Enchant 2H Weapon - Major Spirit",
	ENCH5="Enchant 2H Weapon - Superior Impact",
	ENCH6="Enchant Boots - Agility",
	ENCH7="Enchant Boots - Greater Agility",
	ENCH8="Enchant Boots - Greater Stamina",
	ENCH9="Enchant Boots - Spirit",
	ENCH10="Enchant Bracer - Deflection",
	ENCH11="Enchant Bracer - Greater Intellect",
	ENCH12="Enchant Bracer - Greater Stamina",
	ENCH13="Enchant Bracer - Greater Strength",
	ENCH14="Enchant Bracer - Healing Power",
	ENCH15="Enchant Bracer - Mana Regeneration",
	ENCH16="Enchant Bracer - Superior Spirit",
	ENCH17="Enchant Bracer - Superior Stamina",
	ENCH18="Enchant Bracer - Superior Strength",
	ENCH19="Enchant Chest - Greater Stats",
	ENCH20="Enchant Chest - Major Health",
	ENCH21="Enchant Chest - Major Mana",
	ENCH22="Enchant Chest - Stats",
	ENCH23="Enchant Chest - Superior Mana",
	ENCH24="Enchant Cloak - Dodge",
	ENCH25="Enchant Cloak - Greater Fire Resistance",
	ENCH26="Enchant Cloak - Greater Nature Resistance",
	ENCH27="Enchant Cloak - Greater Resistance",
	ENCH28="Enchant Cloak - Stealth",
	ENCH29="Enchant Cloak - Subtlety",
	ENCH30="Enchant Cloak - Superior Defense",
	ENCH31="Enchant Gloves - Fire Power",
	ENCH32="Enchant Gloves - Frost Power",
	ENCH33="Enchant Gloves - Greater Agility",
	ENCH34="Enchant Gloves - Greater Strength",
	ENCH35="Enchant Gloves - Healing Power",
	ENCH36="Enchant Gloves - Minor Haste",
	ENCH37="Enchant Gloves - Riding Skill",
	ENCH38="Enchant Gloves - Shadow Power",
	ENCH39="Enchant Gloves - Superior Agility",
	ENCH40="Enchant Gloves - Threat",
	ENCH41="Enchant Shield - Frost Resistance",
	ENCH42="Enchant Shield - Greater Spirit",
	ENCH43="Enchant Shield - Greater Stamina",
	ENCH44="Enchant Shield - Superior Spirit",
	ENCH45="Enchant Weapon - Agility",
	ENCH46="Enchant Weapon - Crusader",
	ENCH47="Enchant Weapon - Demonslaying",
	ENCH48="Enchant Weapon - Fiery Weapon",
	ENCH49="Enchant Weapon - Greater Striking",
	ENCH50="Enchant Weapon - Healing Power",
	ENCH51="Enchant Weapon - Icy Chill",
	ENCH52="Enchant Weapon - Lifestealing",
	ENCH53="Enchant Weapon - Mighty Intellect",
	ENCH54="Enchant Weapon - Mighty Spirit",
	ENCH55="Enchant Weapon - Spell Power",
	ENCH56="Enchant Weapon - Strength",
	ENCH57="Enchant Weapon - Superior Striking",
	ENCH58="Enchant Weapon - Unholy Weapon",
	ENCH59="Enchant Boots - Minor Speed",
	ENCH60="Enchant Boots - Stamina",
	ENCH61="Enchant Bracer - Greater Spirit",
	ENCH62="Enchant Bracer - Intellect",
	ENCH63="Enchant Chest - Superior Health",
	ENCH64="Enchant Cloak - Lesser Agility",
	ENCH65="Enchant Gloves - Advanced Herbalism",
	ENCH66="Enchant Gloves - Advanced Mining",
	ENCH67="Enchant Gloves - Agility",
	ENCH68="Enchant Gloves - Strength",
	ENCH69="Enchant Shield - Stamina",
	ENCH70="Enchant 2H Weapon - Impact",
	ENCH71="Enchant Weapon - Lesser Beastslayer",
	ENCH72="Enchant Weapon - Lesser Elemental Slayer",
	ENCH73="Enchant Boots - Lesser Spirit",
	ENCH74="Enchant Chest - Lesser Stats",
	ENCH75="Enchant Chest - Retricutioner",
	ENCH76="Enchant Cloak - Greater Defense",
	ENCH77="Enchant Cloak - Resistance",
	ENCH78="Enchant Gloves - Skinning",
	ENCH79="Enchant Shield - Lesser Block",
	ENCH80="Enchant Weapon - Dismantle",
	ENCH81="Enchant Weapon - Striking",
	ENCH82="Enchant Weapon - Winter's Might",
	ENCH83="Enchant Boots - Lesser Stamina",
	ENCH84="Enchant Bracer - Lesser Deflection",
	ENCH85="Enchant Bracer - Stamina",
	ENCH86="Enchant Bracer - Strength",
	ENCH87="Enchant Chest - Greater Mana",
	ENCH88="Enchant Cloak - Fire Resistance",
	ENCH89="Enchant Shield - Spirit",
	ENCH90="Enchant 2H Weapon - Lesser Impact",
	ENCH91="Enchant 2H Weapon - Lesser Intellect",
	ENCH92="Enchant 2H Weapon - Lesser Spirit",
	ENCH93="Enchant 2H Weapon - Minor Impact",
	ENCH94="Enchant Weapon - Lesser Striking",
	ENCH95="Enchant Weapon - Minor Beastslayer",
	ENCH96="Enchant Weapon - Minor Striking",
	ENCH97="Enchant Boots - Lesser Agility",
	ENCH98="Enchant Boots - Minor Agility",
	ENCH99="Enchant Boots - Minor Stamina",
	ENCH100="Enchant Bracer - Lesser Intellect",
	ENCH101="Enchant Bracer - Lesser Spirit",
	ENCH102="Enchant Bracer - Lesser Stamina",
	ENCH103="Enchant Bracer - Lesser Strength",
	ENCH104="Enchant Bracer - Minor Agility",
	ENCH105="Enchant Bracer - Minor Deflect",
	ENCH106="Enchant Bracer - Minor Health",
	ENCH107="Enchant Bracer - Minor Spirit",
	ENCH108="Enchant Bracer - Minor Stamina",
	ENCH109="Enchant Bracer - Minor Strength",
	ENCH110="Enchant Bracer - Spirit",
	ENCH111="Enchant Chest - Greater Health",
	ENCH112="Enchant Chest - Health",
	ENCH113="Enchant Chest - Lesser Absorption",
	ENCH114="Enchant Chest - Lesser Health",
	ENCH115="Enchant Chest - Lesser Mana",
	ENCH116="Enchant Chest - Mana",
	ENCH117="Enchant Chest - Minor Absorption",
	ENCH118="Enchant Chest - Minor Health",
	ENCH119="Enchant Chest - Minor Mana",
	ENCH120="Enchant Chest - Minor Stats",
	ENCH121="Enchant Cloak - Defense",
	ENCH122="Enchant Cloak - Lesser Fire Resistance",
	ENCH123="Enchant Cloak - Lesser Protection",
	ENCH124="Enchant Cloak - Lesser Shadow Resistance",
	ENCH125="Enchant Cloak - Minor Agility",
	ENCH126="Enchant Cloak - Minor Protection",
	ENCH127="Enchant Cloak - Minor Resistance",
	ENCH128="Enchant Gloves - Fishing",
	ENCH129="Enchant Gloves - Herbalism",
	ENCH130="Enchant Gloves - Mining",
	ENCH131="Enchant Shield - Lesser Protection",
	ENCH132="Enchant Shield - Lesser Spirit",
	ENCH133="Enchant Shield - Lesser Stamina",
	ENCH134="Enchant Shield - Minor Stamina"
}

-- Enchants Slots
EnchantsSlot = {
	ENCH1="Weapon",
	ENCH2="Weapon",
	ENCH3="Weapon",
	ENCH4="Weapon",
	ENCH5="Weapon",
	ENCH6="Boots",
	ENCH7="Boots",
	ENCH8="Boots",
	ENCH9="Boots",
	ENCH10="Bracer",
	ENCH11="Bracer",
	ENCH12="Bracer",
	ENCH13="Bracer",
	ENCH14="Bracer",
	ENCH15="Bracer",
	ENCH16="Bracer",
	ENCH17="Bracer",
	ENCH18="Bracer",
	ENCH19="Chest",
	ENCH20="Chest",
	ENCH21="Chest",
	ENCH22="Chest",
	ENCH23="Chest",
	ENCH24="Cloak",
	ENCH25="Cloak",
	ENCH26="Cloak",
	ENCH27="Cloak",
	ENCH28="Cloak",
	ENCH29="Cloak",
	ENCH30="Cloak",
	ENCH31="Gloves",
	ENCH32="Gloves",
	ENCH33="Gloves",
	ENCH34="Gloves",
	ENCH35="Gloves",
	ENCH36="Gloves",
	ENCH37="Gloves",
	ENCH38="Gloves",
	ENCH39="Gloves",
	ENCH40="Gloves",
	ENCH41="Shield",
	ENCH42="Shield",
	ENCH43="Shield",
	ENCH44="Shield",
	ENCH45="Weapon",
	ENCH46="Weapon",
	ENCH47="Weapon",
	ENCH48="Weapon",
	ENCH49="Weapon",
	ENCH50="Weapon",
	ENCH51="Weapon",
	ENCH52="Weapon",
	ENCH53="Weapon",
	ENCH54="Weapon",
	ENCH55="Weapon",
	ENCH56="Weapon",
	ENCH57="Weapon",
	ENCH58="Weapon",
	ENCH59="Boots",
	ENCH60="Boots",
	ENCH61="Bracer",
	ENCH62="Bracer",
	ENCH63="Chest",
	ENCH64="Cloak",
	ENCH65="Gloves",
	ENCH66="Gloves",
	ENCH67="Gloves",
	ENCH68="Gloves",
	ENCH69="Shield",
	ENCH70="Weapon",
	ENCH71="Weapon",
	ENCH72="Weapon",
	ENCH73="Boots",
	ENCH74="Chest",
	ENCH75="Chest",
	ENCH76="Cloak",
	ENCH77="Cloak",
	ENCH78="Gloves",
	ENCH79="Shield",
	ENCH80="Weapon",
	ENCH81="Weapon",
	ENCH82="Weapon",
	ENCH83="Boots",
	ENCH84="Bracer",
	ENCH85="Bracer",
	ENCH86="Bracer",
	ENCH87="Chest",
	ENCH88="Cloak",
	ENCH89="Shield",
	ENCH90="Weapon",
	ENCH91="Weapon",
	ENCH92="Weapon",
	ENCH93="Weapon",
	ENCH94="Weapon",
	ENCH95="Weapon",
	ENCH96="Weapon",
	ENCH97="Boots",
	ENCH98="Boots",
	ENCH99="Boots",
	ENCH100="Bracer",
	ENCH101="Bracer",
	ENCH102="Bracer",
	ENCH103="Bracer",
	ENCH104="Bracer",
	ENCH105="Bracer",
	ENCH106="Bracer",
	ENCH107="Bracer",
	ENCH108="Bracer",
	ENCH109="Bracer",
	ENCH110="Bracer",
	ENCH111="Chest",
	ENCH112="Chest",
	ENCH113="Chest",
	ENCH114="Chest",
	ENCH115="Chest",
	ENCH116="Chest",
	ENCH117="Chest",
	ENCH118="Chest",
	ENCH119="Chest",
	ENCH120="Chest",
	ENCH121="Cloak",
	ENCH122="Cloak",
	ENCH123="Cloak",
	ENCH124="Cloak",
	ENCH125="Cloak",
	ENCH126="Cloak",
	ENCH127="Cloak",
	ENCH128="Gloves",
	ENCH129="Gloves",
	ENCH130="Gloves",
	ENCH131="Shield",
	ENCH132="Shield",
	ENCH133="Shield",
	ENCH134="Shield"
}

-- Enchants SpellID
EnchantsSpellID = {
	ENCH1=27837,
	ENCH2=13937,
	ENCH3=20036,
	ENCH4=20035,
	ENCH5=20030,
	ENCH6=13935,
	ENCH7=20023,
	ENCH8=20020,
	ENCH9=20024,
	ENCH10=13931,
	ENCH11=20008,
	ENCH12=13945,
	ENCH13=13939,
	ENCH14=23802,
	ENCH15=23801,
	ENCH16=20009,
	ENCH17=20011,
	ENCH18=20010,
	ENCH19=20025,
	ENCH20=20026,
	ENCH21=20028,
	ENCH22=13941,
	ENCH23=13917,
	ENCH24=25086,
	ENCH25=25081,
	ENCH26=25082,
	ENCH27=20014,
	ENCH28=25083,
	ENCH29=25084,
	ENCH30=20015,
	ENCH31=25078,
	ENCH32=25074,
	ENCH33=20012,
	ENCH34=20013,
	ENCH35=25079,
	ENCH36=13948,
	ENCH37=13947,
	ENCH38=25073,
	ENCH39=25080,
	ENCH40=25072,
	ENCH41=13933,
	ENCH42=13905,
	ENCH43=20017,
	ENCH44=20016,
	ENCH45=23800,
	ENCH46=20034,
	ENCH47=13915,
	ENCH48=13898,
	ENCH49=13943,
	ENCH50=22750,
	ENCH51=20029,
	ENCH52=20032,
	ENCH53=23804,
	ENCH54=23803,
	ENCH55=22749,
	ENCH56=23799,
	ENCH57=20031,
	ENCH58=20033,
	ENCH59=13890,
	ENCH60=13836,
	ENCH61=13846,
	ENCH62=13822,
	ENCH63=13858,
	ENCH64=13882,
	ENCH65=13868,
	ENCH66=13841,
	ENCH67=13815,
	ENCH68=13887,
	ENCH69=13817,
	ENCH70=13695,
	ENCH71=13653,
	ENCH72=13655,
	ENCH73=13687,
	ENCH74=13700,
	ENCH75=435903,
	ENCH76=13746,
	ENCH77=13794,
	ENCH78=13698,
	ENCH79=13689,
	ENCH80=435481,
	ENCH81=13693,
	ENCH82=21931,
	ENCH83=13644,
	ENCH84=13646,
	ENCH85=13648,
	ENCH86=13661,
	ENCH87=13663,
	ENCH88=13657,
	ENCH89=13659,
	ENCH90=13529,
	ENCH91=7793,
	ENCH92=13380,
	ENCH93=7745,
	ENCH94=13503,
	ENCH95=7786,
	ENCH96=7788,
	ENCH97=13637,
	ENCH98=7867,
	ENCH99=7863,
	ENCH100=13622,
	ENCH101=7859,
	ENCH102=13501,
	ENCH103=13536,
	ENCH104=7779,
	ENCH105=7428,
	ENCH106=7418,
	ENCH107=7766,
	ENCH108=7457,
	ENCH109=7782,
	ENCH110=13642,
	ENCH111=13640,
	ENCH112=7857,
	ENCH113=13538,
	ENCH114=7748,
	ENCH115=7776,
	ENCH116=13607,
	ENCH117=7426,
	ENCH118=7420,
	ENCH119=7443,
	ENCH120=13626,
	ENCH121=13635,
	ENCH122=7861,
	ENCH123=13421,
	ENCH124=13522,
	ENCH125=13419,
	ENCH126=7771,
	ENCH127=7454,
	ENCH128=13620,
	ENCH129=13617,
	ENCH130=13612,
	ENCH131=13464,
	ENCH132=13485,
	ENCH133=13631,
	ENCH134=13378
}

-- Enchants Stats
EnchantsStats = {
	ENCH1=" (+25 Agi)",
	ENCH2=" (+7 Dmg)",
	ENCH3=" (+9 Int)",
	ENCH4=" (+9 Spirit)",
	ENCH5=" (+9 Dmg)",
	ENCH6=" (+5 Agi)",
	ENCH7=" (+7 Agi)",
	ENCH8=" (+7 Stam)",
	ENCH9=" (+5 Spirit)",
	ENCH10=" (+3 Defense)",
	ENCH11=" (+7 Int)",
	ENCH12=" (+7 Stam)",
	ENCH13=" (+7 Str)",
	ENCH14=" (+24 Heal Power)",
	ENCH15=" (+4 Mana every 5s)",
	ENCH16=" (+9 Spirit)",
	ENCH17=" (+9 Stamina)",
	ENCH18=" (+9 Strength)",
	ENCH19=" (+4 All Stats)",
	ENCH20=" (+100 Health)",
	ENCH21=" (+100 Mana)",
	ENCH22=" (+3 All Stats)",
	ENCH23=" (+65 Mana)",
	ENCH24=" (+1% Dodge )",
	ENCH25=" (+15 Fire Res)",
	ENCH26=" (+15 Nature Res)",
	ENCH27=" (+5 All Res)",
	ENCH28=" (+1 Stealth)",
	ENCH29=" (-2% Threat Gen)",
	ENCH30=" (+70 Armor)",
	ENCH31=" (+20 Fire Dmg)",
	ENCH32=" (+20 Frost Dmg)",
	ENCH33=" (+7 Agi)",
	ENCH34=" (+7 Str)",
	ENCH35=" (+30 Heal Power)",
	ENCH36=" (+1% Attack Spd)",
	ENCH37=" (2% Mount Movespeed)",
	ENCH38=" (+20 Shadow Dmg)",
	ENCH39=" (+15 Agi)",
	ENCH40=" (+2% Threat Gen)",
	ENCH41=" (+8 Frost Res)",
	ENCH42=" (+7 Spirit)",
	ENCH43=" (+7 Stam)",
	ENCH44=" (+9 Spirit)",
	ENCH45=" (+15 Agi)",
	ENCH46=" (+100 Str and Heal Chance)",
	ENCH47=" (+100 Dmg to Demon)",
	ENCH48=" (+40 Fire Dmg On Melee Hit)",
	ENCH49=" (+4 Dmg)",
	ENCH50=" (+55 Heal Power)",
	ENCH51=" (Chill On Hit Chance)",
	ENCH52=" (+30 Heal Proc Chance)",
	ENCH53=" (+22 Int)",
	ENCH54=" (+20 Spirit)",
	ENCH55=" (+30 Spell Dmg)",
	ENCH56=" (+15 Str)",
	ENCH57=" (+5 Dmg)",
	ENCH58=" (-15 Dmg Curse Chance)",
	ENCH59=" (8% Movespeed)",
	ENCH60=" (+5 Stam)",
	ENCH61=" (+7 Spirit)",
	ENCH62=" (+5 Int)",
	ENCH63=" (+50 Health)",
	ENCH64=" (+3 Agi)",
	ENCH65=" (+5 Herbalism)",
	ENCH66=" (+5 Mining)",
	ENCH67=" (+5 Agi)",
	ENCH68=" (+5 Str)",
	ENCH69=" (+5 Stam)",
	ENCH70=" (+5 Dmg)",
	ENCH71=" (+6 Dmg to Beast)",
	ENCH72=" (+6 Dmg to Ele)",
	ENCH73=" (+3 Spirit)",
	ENCH74=" (+2 All Stats)",
	ENCH75=" (9 Dmg Melee Reflect)",
	ENCH76=" (+50 Armor)",
	ENCH77=" (+3 All Res)",
	ENCH78=" (+5 Skinning)",
	ENCH79=" (+2% Block)",
	ENCH80=" (+75 All Dmg to Mech)",
	ENCH81=" (+3 Dmg)",
	ENCH82=" (+7 Frost Dmg)",
	ENCH83=" (+3 Stam)",
	ENCH84=" (+2 Def)",
	ENCH85=" (+5 Stam)",
	ENCH86=" (+5 Str)",
	ENCH87=" (+50 Mana)",
	ENCH88=" (+7 Fire Res)",
	ENCH89=" (+5 Spirit)",
	ENCH90=" (+3 Dmg)",
	ENCH91=" (+3 Int)",
	ENCH92=" (+3 Spirit)",
	ENCH93=" (+2 Dmg)",
	ENCH94=" (+2 Dmg)",
	ENCH95=" (+2 Dmg to Beast)",
	ENCH96=" (+1 Dmg)",
	ENCH97=" (+3 Agi)",
	ENCH98=" (+1 Agi)",
	ENCH99=" (+1 Stam)",
	ENCH100=" (+3 Int)",
	ENCH101=" (+3 Spirit)",
	ENCH102=" (+3 Stam)",
	ENCH103=" (+3 Str)",
	ENCH104=" (+1 Agi)",
	ENCH105=" (+1 Def)",
	ENCH106=" (+5 Health)",
	ENCH107=" (+1 Spirit)",
	ENCH108=" (+1 Stam)",
	ENCH109=" (+1 Str)",
	ENCH110=" (+5 Spirit)",
	ENCH111=" (+35 Health)",
	ENCH112=" (+25 Health)",
	ENCH113=" (5% Chance 25 Dmg Absorb)",
	ENCH114=" (+15 Health)",
	ENCH115=" (+20 Mana)",
	ENCH116=" (+30 Mana)",
	ENCH117=" (2% Chance 10 Dmg Absorb)",
	ENCH118=" (+5 Health)",
	ENCH119=" (+5 Mana)",
	ENCH120=" (+1 All Stats)",
	ENCH121=" (+30 Armor)",
	ENCH122=" (+5 Fire)",
	ENCH123=" (+20 Armor)",
	ENCH124=" (+10 Shadow Res)",
	ENCH125=" (+1 Agi)",
	ENCH126=" (+10 Armor)",
	ENCH127=" (+1 All Res)",
	ENCH128=" (+2 Fishing)",
	ENCH129=" (+2 Herbalism)",
	ENCH130=" (+2 Mining)",
	ENCH131=" (+30 Armor)",
	ENCH132=" (+3 Spirit)",
	ENCH133=" (+3 Stam)",
	ENCH134=" (+1 Stam)"
}

local ItemCacheTable = {
-- Dust
	strangedust="10940",
	souldust = "11083",
	visiondust = "11137",
	dreamdust = "11176",
	illusiondust = "16204",

-- Shards
	smallglimmeringshard = "10978",
	largeglimmeringshard = "11084",
	smallglowingshard = "11138",
	largeglowingshard = "11139",
	smallbrilliantshard = "14343",
	largebrilliantshard = "14344",
	smallradiantshard = "11177",
	largeradiantshard = "11178",

-- Essence
	lessermagicessence = "10938",
	greatermagicessence = "10939",
	lesserastralessence = "10998",
	greaterastralessence = "11082",
	lessermysticessence = "11134",
	greatermysticessence = "11135",
	lessereternalessence = "16202",
	greatereternalessence = "16203",
	lessernetheressence = "11174",
	greaternetheressence = "11175",

-- Misc
	aquamarine = "7909",
	blackdiamond = "11754",
	blacklotus = "13468",
	blackmouthoil = "6370",
	breathofwind = "7081",
 	coreofearth = "7075",
 	--crystalvial = "8925",
	elementalearth = "7067",
	elementalfire = "7068",
	elixirofdemonslayer = "9224",
	emptyvial = "3371",
	essenceofair = "7082",
	essenceofearth = "7076",
	essenceoffire = "7078",
	essenceofundeath = "12808",
	essenceofwater = "7080",
	fireoil = "6371",
	--firebloom = "4625",
	frostoil = "3829",
	globeofwater = "7079",
	goldenpearl = "13926",
	greenwhelpscale = "7392",
	guardianstone = "12809",
	heartoffire = "7077",
	icecap = "13467",
	ichorofundeath = "7972",
	imbuedvial = "18256",
	ironore = "2772",
	kingsblood = "3356",
	largefang = "5637",
	larvalacid = "18512",
	leadedvial = "3372",
	livingessence = "12803",
	mapleseed = "17034",
	nexuscrystal = "20725",
	--purplelotus = "8831",
	righteousorb = "12811",
	--ruggedleather = "8170",
	shadowprotectionpotion = "6048",
	--simplewood = "4470",
	--starwood = "11291",
	--stranglethornseed = "17035",
	sungrass = "8838",
	--thoriumbar = "12359",
	truesilverbar = "6037",
	wildvine = "8153",
	wintersbite = "3819"
}

---- MATERIAL ITEMLINKS
-- Dust
local strangedust = "\124cffffffff\124Hitem:10940::::::::60:::::\124h[Strange Dust]\124h\124r"
local souldust = "\124cffffffff\124Hitem:11083::::::::60:::::\124h[Soul Dust]\124h\124r"
local visiondust = "\124cffffffff\124Hitem:11137::::::::60:::::\124h[Vision Dust]\124h\124r"
local dreamdust = "\124cffffffff\124Hitem:11176::::::::60:::::\124h[Dream Dust]\124h\124r"
local illusiondust = "\124cffffffff\124Hitem:16204::::::::60:::::\124h[Illusion Dust]\124h\124r"

-- Shards
local smallglimmeringshard = "\124cff0070dd\124Hitem:10978::::::::60:::::\124h[Small Glimmering Shard]\124h\124r"
local largeglimmeringshard = "\124cff0070dd\124Hitem:11084::::::::60:::::\124h[Large Glimmering Shard]\124h\124r"
local smallglowingshard = "\124cff0070dd\124Hitem:11138::::::::60:::::\124h[Small Glowing Shard]\124h\124r"
local largeglowingshard = "\124cff0070dd\124Hitem:11139::::::::60:::::\124h[Large Glowing Shard]\124h\124r"
local smallbrilliantshard = "\124cff0070dd\124Hitem:14343::::::::60:::::\124h[Small Brilliant Shard]\124h\124r"
local largebrilliantshard = "\124cff0070dd\124Hitem:14344::::::::60:::::\124h[Large Brilliant Shard]\124h\124r"
local smallradiantshard = "\124cff0070dd\124Hitem:11177::::::::60:::::\124h[Small Radiant Shard]\124h\124r"
local largeradiantshard = "\124cff0070dd\124Hitem:11178::::::::60:::::\124h[Large Radiant Shard]\124h\124r"

-- Essence
local lessermagicessence = "\124cff1eff00\124Hitem:10938::::::::60:::::\124h[Lesser Magic Essence]\124h\124r"
local greatermagicessence = "\124cff1eff00\124Hitem:10939::::::::60:::::\124h[Greater Magic Essence]\124h\124r"
local lesserastralessence = "\124cff1eff00\124Hitem:10998::::::::60:::::\124h[Lesser Astral Essence]\124h\124r"
local greaterastralessence = "\124cff1eff00\124Hitem:11082::::::::60:::::\124h[Greater Astral Essence]\124h\124r"
local lessermysticessence = "\124cff1eff00\124Hitem:11134::::::::60:::::\124h[Lesser Mystic Essence]\124h\124r"
local greatermysticessence = "\124cff1eff00\124Hitem:11135::::::::60:::::\124h[Greater Mystic Essence]\124h\124r"
local lessereternalessence = "\124cff1eff00\124Hitem:16202::::::::60:::::\124h[Lesser Eternal Essence]\124h\124r"
local greatereternalessence = "\124cff1eff00\124Hitem:16203::::::::60:::::\124h[Greater Eternal Essence]\124h\124r"
local lessernetheressence = "\124cff1eff00\124Hitem:11174::::::::60:::::\124h[Lesser Nether Essence]\124h\124r"
local greaternetheressence = "\124cff1eff00\124Hitem:11175::::::::60:::::\124h[Greater Nether Essence]\124h\124r"

-- Misc
local aquamarine = "\124cff1eff00\124Hitem:7909::::::::60:::::\124h[Aquamarine]\124h\124r"
local blackdiamond = "\124cff1eff00\124Hitem:11754::::::::60:::::\124h[Black Diamond]\124h\124r"
local blacklotus = "\124cff1eff00\124Hitem:13468::::::::60:::::\124h[Black Lotus]\124h\124r"
local blackmouthoil = "\124cffffffff\124Hitem:6370::::::::60:::::\124h[Blackmouth Oil]\124h\124r"
local breathofwind = "\124cffffffff\124Hitem:7081::::::::60:::::\124h[Breath of Wind]\124h\124r"
local coreofearth = "\124cffffffff\124Hitem:7075::::::::60:::::\124h[Core of Earth]\124h\124r"
local crystalvial = "\124cffffffff\124Hitem:8925::::::::60:::::\124h[Crystal Vial]\124h\124r"
local elementalearth = "\124cffffffff\124Hitem:7067::::::::60:::::\124h[Elemental Earth]\124h\124r"
local elementalfire = "\124cffffffff\124Hitem:7068::::::::60:::::\124h[Elemental Fire]\124h\124r"
local elixirofdemonslayer = "\124cffffffff\124Hitem:9224::::::::60:::::\124h[Elixir of Demonslaying]\124h\124r"
local emptyvial = "\124cffffffff\124Hitem:3371::::::::60:::::\124h[Empty Vial]\124h\124r"
local essenceofair = "\124cff1eff00\124Hitem:7082::::::::60:::::\124h[Essence of Air]\124h\124r"
local essenceofearth = "\124cff1eff00\124Hitem:7076::::::::60:::::\124h[Essence of Earth]\124h\124r"
local essenceoffire = "\124cff1eff00\124Hitem:7078::::::::60:::::\124h[Essence of Fire]\124h\124r"
local essenceofundeath = "\124cff1eff00\124Hitem:12808::::::::60:::::\124h[Essence of Undeath]\124h\124r"
local essenceofwater = "\124cff1eff00\124Hitem:7080::::::::60:::::\124h[Essence of Water]\124h\124r"
local fireoil = "\124cffffffff\124Hitem:6371::::::::60:::::\124h[Fire Oil]\124h\124r"
local firebloom = "\124cffffffff\124Hitem:4625::::::::60:::::\124h[Firebloom]\124h\124r"
local frostoil = "\124cffffffff\124Hitem:3829::::::::60:::::\124h[Frost Oil]\124h\124r"
local globeofwater = "\124cffffffff\124Hitem:7079::::::::60:::::\124h[Globe of Water]\124h\124r"
local goldenpearl = "\124cff1eff00\124Hitem:13926::::::::60:::::\124h[Golden Pearl]\124h\124r"
local greenwhelpscale = "\124cffffffff\124Hitem:7392::::::::60:::::\124h[Green Whelp Scale]\124h\124r"
local guardianstone = "\124cff1eff00\124Hitem:12809::::::::60:::::\124h[Guardian Stone]\124h\124r"
local heartoffire = "\124cffffffff\124Hitem:7077::::::::60:::::\124h[Heart of Fire]\124h\124r"
local icecap = "\124cffffffff\124Hitem:13467::::::::60:::::\124h[Icecap]\124h\124r"
local ichorofundeath = "\124cffffffff\124Hitem:7972::::::::60:::::\124h[Ichor of Undeath]\124h\124r"
local imbuedvial = "\124cffffffff\124Hitem:18256::::::::60:::::\124h[Imbued Vial]\124h\124r"
local ironore = "\124cffffffff\124Hitem:2772::::::::60:::::\124h[Iron Ore]\124h\124r"
local kingsblood = "\124cffffffff\124Hitem:3356::::::::60:::::\124h[Kingsblood]\124h\124r"
local largefang = "\124cffffffff\124Hitem:5637::::::::60:::::\124h[Large Fang]\124h\124r"
local larvalacid = "\124cffffffff\124Hitem:18512::::::::60:::::\124h[Larval Acid]\124h\124r"
local leadedvial = "\124cffffffff\124Hitem:3372::::::::60:::::\124h[Leaded Vial]\124h\124r"
local livingessence = "\124cff1eff00\124Hitem:12803::::::::60:::::\124h[Living Essence]\124h\124r"
local mapleseed = "\124cffffffff\124Hitem:17034::::::::60:::::\124h[Maple Seed]\124h\124r"
local nexuscrystal = "\124cffa335ee\124Hitem:20725::::::::60:::::\124h[Nexus Crystal]\124h\124r"
local purplelotus = "\124cffffffff\124Hitem:8831::::::::60:::::\124h[Purple Lotus]\124h\124r"
local righteousorb = "\124cff1eff00\124Hitem:12811::::::::60:::::\124h[Righteous Orb]\124h\124r"
local ruggedleather = "\124cffffffff\124Hitem:8170::::::::60:::::\124h[Rugged Leather]\124h\124r"
local shadowprotectionpotion = "\124cffffffff\124Hitem:6048::::::::60:::::\124h[Shadow Protection Potion]\124h\124r"
local simplewood = "\124cffffffff\124Hitem:4470::::::::60:::::\124h[Simple Wood]\124h\124r"
local starwood = "\124cffffffff\124Hitem:11291::::::::60:::::\124h[Star Wood]\124h\124r"
local stranglethornseed = "\124cffffffff\124Hitem:17035::::::::60:::::\124h[Stranglethorn Seed]\124h\124r"
local sungrass = "\124cffffffff\124Hitem:8838::::::::60:::::\124h[Sungrass]\124h\124r"
local thoriumbar = "\124cffffffff\124Hitem:12359::::::::60:::::\124h[Thorium Bar]\124h\124r"
local truesilverbar = "\124cff1eff00\124Hitem:6037::::::::60:::::\124h[Truesilver Bar]\124h\124r"
local wildvine = "\124cffffffff\124Hitem:8153::::::::60:::::\124h[Wildvine]\124h\124r"
local wintersbite = "\124cffffffff\124Hitem:3819::::::::60:::::\124h[Wintersbite]\124h\124r"



-- Enchanting Recipe Lists
MaterialsForEnchanting = {
	["ENCH1"]={
		"10x " .. largebrilliantshard,
		"6x " .. greatereternalessence,
		"14x " .. illusiondust,
		"4x " .. essenceofair
		},
		["ENCH2"]={
		"2x " .. largeradiantshard,
		"2x " .. dreamdust
		},
		["ENCH3"]={
		"12x " .. greatereternalessence,
		"2x " .. largebrilliantshard
		},
		["ENCH4"]={
		"12x " .. greatereternalessence,
		"2x " .. largebrilliantshard
		},
		["ENCH5"]={
		"4x " .. largebrilliantshard,
		"10x " .. illusiondust
		},
		["ENCH6"]={
		"2x " .. greaternetheressence
		},
		["ENCH7"]={
		"8x " .. greatereternalessence
		},
		["ENCH8"]={
		"10x " .. dreamdust
		},
		["ENCH9"]={
		"2x " .. greatereternalessence,
		"1x " .. lessereternalessence
		},
		["ENCH10"]={
		"1x " .. greaternetheressence,
		"2x " .. dreamdust
		},
		["ENCH11"]={
		"3x " .. lessereternalessence
		},
		["ENCH12"]={
		"5x " .. dreamdust
		},
		["ENCH13"]={
		"2x " .. dreamdust,
		"1x " .. greaternetheressence
		},
		["ENCH14"]={
		"2x " .. largebrilliantshard,
		"20x " .. illusiondust,
		"4x " .. greatereternalessence,
		"6x " .. livingessence
		},
		["ENCH15"]={
		"16x " .. illusiondust,
		"4x " .. greatereternalessence,
		"2x " .. essenceofwater
		},
		["ENCH16"]={
		"3x " .. lessereternalessence,
		"10x " .. dreamdust
		},
		["ENCH17"]={
		"15x " .. illusiondust
		},
		["ENCH18"]={
		"6x " .. illusiondust,
		"6x " .. greatereternalessence
		},
		["ENCH19"]={
		"4x " .. largebrilliantshard,
		"15x " .. illusiondust,
		"10x " .. greatereternalessence
		},
		["ENCH20"]={
		"6x " .. illusiondust,
		"1x " .. smallbrilliantshard
		},
		["ENCH21"]={
		"3x " .. greatereternalessence,
		"1x " .. smallbrilliantshard
		},
		["ENCH22"]={
		"1x " .. largeradiantshard,
		"3x " .. dreamdust,
		"2x " .. greaternetheressence
		},
		["ENCH23"]={
		"1x " .. greaternetheressence,
		"2x " .. lessernetheressence
		},
		["ENCH24"]={
		"3x " .. nexuscrystal,
		"8x " .. largebrilliantshard,
		"8x " .. guardianstone
		},
		["ENCH25"]={
		"3x " .. nexuscrystal,
		"8x " .. largebrilliantshard,
		"4x " .. essenceoffire
		},
		["ENCH26"]={
		"2x " .. nexuscrystal,
		"8x " .. largebrilliantshard,
		"4x " .. livingessence
		},
		["ENCH27"]={
		"2x " .. lessereternalessence,
		"1x " .. heartoffire,
		"1x " .. coreofearth,
		"1x " .. globeofwater,
		"1x " .. breathofwind,
		"1x " .. ichorofundeath
		},
		["ENCH28"]={
		"3x " .. nexuscrystal,
		"8x " .. largebrilliantshard,
		"2x " .. blacklotus
		},
		["ENCH29"]={
		"4x " .. nexuscrystal,
		"6x " .. largebrilliantshard,
		"2x " .. blackdiamond
		},
		["ENCH30"]={
		"8x " .. illusiondust
		},
		["ENCH31"]={
		"2x " .. nexuscrystal,
		"10x " .. largebrilliantshard,
		"4x " .. essenceoffire
		},
		["ENCH32"]={
		"3x " .. nexuscrystal,
		"10x " .. largebrilliantshard,
		"4x " .. essenceofwater
		},
		["ENCH33"]={
		"3x " .. lessereternalessence,
		"3x " .. illusiondust
		},
		["ENCH34"]={
		"4x " .. greatereternalessence,
		"4x " .. illusiondust
		},
		["ENCH35"]={
		"3x " .. nexuscrystal,
		"8x " .. largebrilliantshard,
		"1x " .. righteousorb
		},
		["ENCH36"]={
		"2x " .. largeradiantshard,
		"2x " .. wildvine
		},
		["ENCH37"]={
		"2x " .. largeradiantshard,
		"3x " .. dreamdust
		},
		["ENCH38"]={
		"3x " .. nexuscrystal,
		"10x " .. largebrilliantshard,
		"6x " .. essenceofundeath
		},
		["ENCH39"]={
		"3x " .. nexuscrystal,
		"8x " .. largebrilliantshard,
		"4x " .. essenceofair
		},
		["ENCH40"]={
		"4x " .. nexuscrystal,
		"6x " .. largebrilliantshard,
		"8x " .. larvalacid
		},
		["ENCH41"]={
		"1x " .. largeradiantshard,
		"1x " .. frostoil
		},
		["ENCH42"]={
		"1x " .. greaternetheressence,
		"2x " .. dreamdust
		},
		["ENCH43"]={
		"10x " .. dreamdust
		},
		["ENCH44"]={
		"2x " .. greatereternalessence,
		"4x " .. illusiondust
		},
		["ENCH45"]={
		"6x " .. largebrilliantshard,
		"6x " .. greatereternalessence,
		"4x " .. illusiondust,
		"2x " .. essenceofair
		},
		["ENCH46"]={
		"4x " .. largebrilliantshard,
		"2x " .. righteousorb
		},
		["ENCH47"]={
		"1x " .. smallradiantshard,
		"2x " .. dreamdust,
		"1x " .. elixirofdemonslayer
		},
		["ENCH48"]={
		"4x " .. smallradiantshard,
		"1x " .. essenceoffire
		},
		["ENCH49"]={
		"2x " .. largeradiantshard,
		"2x " .. greaternetheressence
		},
		["ENCH50"]={
		"4x " .. largebrilliantshard,
		"8x " .. greatereternalessence,
		"6x " .. livingessence,
		"6x " .. essenceofwater,
		"1x " .. righteousorb
		},
		["ENCH51"]={
		"4x " .. smallbrilliantshard,
		"1x " .. essenceofwater,
		"1x " .. essenceofair,
		"1x " .. icecap
		},
		["ENCH52"]={
		"6x " .. largebrilliantshard,
		"6x " .. essenceofundeath,
		"6x " .. livingessence
		},
		["ENCH53"]={
		"15x " .. largebrilliantshard,
		"12x " .. greatereternalessence,
		"20x " .. illusiondust
		},
		["ENCH54"]={
		"10x " .. largebrilliantshard,
		"8x " .. greatereternalessence,
		"15x " .. illusiondust
		},
		["ENCH55"]={
		"4x " .. largebrilliantshard,
		"12x " .. greatereternalessence,
		"4x " .. essenceoffire,
		"4x " .. essenceofwater,
		"4x " .. essenceofair,
		"2x " .. goldenpearl
		},
		["ENCH56"]={
		"6x " .. largebrilliantshard,
		"6x " .. greatereternalessence,
		"4x " .. illusiondust,
		"2x " .. essenceofearth
		},
		["ENCH57"]={
		"2x " .. largebrilliantshard,
		"10x " .. greatereternalessence
		},
		["ENCH58"]={
		"4x " .. largebrilliantshard,
		"4x " .. essenceofundeath
		},
		["ENCH59"]={
		"1x " .. smallradiantshard,
		"1x " .. aquamarine,
		"1x " .. lessernetheressence
		},
		["ENCH60"]={
		"5x " .. visiondust
		},
		["ENCH61"]={
		"3x " .. lessernetheressence,
		"1x " .. visiondust
		},
		["ENCH62"]={
		"2x " .. lessernetheressence
		},
		["ENCH63"]={
		"6x " .. visiondust
		},
		["ENCH64"]={
		"2x " .. lessernetheressence
		},
		["ENCH65"]={
		"3x " .. visiondust,
		"3x " .. sungrass
		},
		["ENCH66"]={
		"3x " .. visiondust,
		"3x " .. truesilverbar
		},
		["ENCH67"]={
		"1x " .. lessernetheressence,
		"1x " .. visiondust
		},
		["ENCH68"]={
		"2x " .. lessernetheressence,
		"3x " .. visiondust
		},
		["ENCH69"]={
		"5x " .. visiondust
		},
		["ENCH70"]={
		"4x " .. visiondust,
		"1x " .. largeglowingshard
		},
		["ENCH71"]={
		"1x " .. lessermysticessence,
		"2x " .. largefang,
		"1x " .. smallglowingshard
		},
		["ENCH72"]={
		"1x " .. lessermysticessence,
		"1x " .. elementalearth,
		"1x " .. smallglowingshard
		},
		["ENCH73"]={
		"1x " .. greatermysticessence,
		"2x " .. lessermysticessence
		},
		["ENCH74"]={
		"2x " .. greatermysticessence,
		"2x " .. visiondust,
		"1x " .. largeglowingshard
		},
		["ENCH75"]={
		"1x " .. smallradiantshard,
		"2x " .. dreamdust
		},
		["ENCH76"]={
		"3x " .. visiondust
		},
		["ENCH77"]={
		"1x " .. lessernetheressence
		},
		["ENCH78"]={
		"1x " .. visiondust,
		"3x " .. greenwhelpscale
		},
		["ENCH79"]={
		"2x " .. greatermysticessence,
		"2x " .. visiondust,
		"1x " .. largeglowingshard
		},
		["ENCH80"]={
		"4x " .. lessernetheressence,
		"2x " .. largefang,
		"2x " .. smallradiantshard
		},
		["ENCH81"]={
		"2x " .. greatermysticessence,
		"1x " .. largeglowingshard
		},
		["ENCH82"]={
		"3x " .. greatermysticessence,
		"3x " .. visiondust,
		"1x " .. largeglowingshard,
		"2x " .. wintersbite
		},
		["ENCH83"]={
		"4x " .. souldust
		},
		["ENCH84"]={
		"1x " .. lessermysticessence,
		"2x " .. souldust
		},
		["ENCH85"]={
		"6x " .. souldust
		},
		["ENCH86"]={
		"1x " .. visiondust
		},
		["ENCH87"]={
		"1x " .. greatermysticessence
		},
		["ENCH88"]={
		"1x " .. lessermysticessence,
		"1x " .. elementalfire
		},
		["ENCH89"]={
		"1x " .. greatermysticessence,
		"1x " .. visiondust
		},
		["ENCH90"]={
		"3x " .. souldust,
		"1x " .. largeglimmeringshard
		},
		["ENCH91"]={
		"3x " .. greatermagicessence
		},
		["ENCH92"]={
		"1x " .. lesserastralessence,
		"6x " .. strangedust
		},
		["ENCH93"]={
		"4x " .. strangedust,
		"1x " .. smallglimmeringshard
		},
		["ENCH94"]={
		"2x " .. souldust,
		"1x " .. largeglimmeringshard
		},
		["ENCH95"]={
		"4x " .. strangedust,
		"2x " .. greatermagicessence
		},
		["ENCH96"]={
		"2x " .. strangedust,
		"1x " .. greatermagicessence,
		"1x " .. smallglimmeringshard
		},
		["ENCH97"]={
		"1x " .. souldust,
		"1x " .. lessermysticessence
		},
		["ENCH98"]={
		"6x " .. strangedust,
		"2x " .. lesserastralessence
		},
		["ENCH99"]={
		"8x " .. strangedust
		},
		["ENCH100"]={
		"2x " .. greaterastralessence
		},
		["ENCH101"]={
		"2x " .. lesserastralessence
		},
		["ENCH102"]={
		"2x " .. souldust
		},
		["ENCH103"]={
		"2x " .. souldust
		},
		["ENCH104"]={
		"2x " .. strangedust,
		"1x " .. greatermagicessence
		},
		["ENCH105"]={
		"1x " .. lessermagicessence,
		"1x " .. strangedust
		},
		["ENCH106"]={
		"1x " .. strangedust
		},
		["ENCH107"]={
		"2x " .. lessermagicessence
		},
		["ENCH108"]={
		"3x " .. strangedust
		},
		["ENCH109"]={
		"5x " .. strangedust
		},
		["ENCH110"]={
		"1x " .. lessermysticessence
		},
		["ENCH111"]={
		"3x " .. souldust
		},
		["ENCH112"]={
		"4x " .. strangedust,
		"1x " .. lesserastralessence
		},
		["ENCH113"]={
		"2x " .. strangedust,
		"1x " .. greaterastralessence,
		"1x " .. largeglimmeringshard
		},
		["ENCH114"]={
		"2x " .. strangedust,
		"2x " .. lessermagicessence
		},
		["ENCH115"]={
		"1x " .. greatermagicessence,
		"1x " .. lessermagicessence
		},
		["ENCH116"]={
		"1x " .. greaterastralessence,
		"2x " .. lesserastralessence
		},
		["ENCH117"]={
		"2x " .. strangedust,
		"1x " .. lessermagicessence
		},
		["ENCH118"]={
		"1x " .. strangedust
		},
		["ENCH119"]={
		"1x " .. lessermagicessence
		},
		["ENCH120"]={
		"1x " .. greaterastralessence,
		"1x " .. souldust,
		"1x " .. largeglimmeringshard
		},
		["ENCH121"]={
		"1x " .. smallglowingshard,
		"3x " .. souldust
		},
		["ENCH122"]={
		"1x " .. fireoil,
		"1x " .. lesserastralessence
		},
		["ENCH123"]={
		"6x " .. strangedust,
		"1x " .. smallglimmeringshard
		},
		["ENCH124"]={
		"1x " .. greaterastralessence,
		"1x " .. shadowprotectionpotion
		},
		["ENCH125"]={
		"1x " .. lesserastralessence
		},
		["ENCH126"]={
		"3x " .. strangedust,
		"1x " .. greatermagicessence
		},
		["ENCH127"]={
		"1x " .. strangedust,
		"2x " .. lessermagicessence
		},
		["ENCH128"]={
		"1x " .. souldust,
		"3x " .. blackmouthoil
		},
		["ENCH129"]={
		"1x " .. souldust,
		"3x " .. kingsblood
		},
		["ENCH130"]={
		"1x " .. souldust,
		"3x " .. ironore
		},
		["ENCH131"]={
		"1x " .. lesserastralessence,
		"1x " .. strangedust,
		"1x " .. smallglimmeringshard
		},
		["ENCH132"]={
		"2x " .. lesserastralessence,
		"4x " .. strangedust
		},
		["ENCH133"]={
		"1x " .. lessermysticessence,
		"1x " .. souldust
		},
		["ENCH134"]={
		"1x " .. lesserastralessence,
		"2x " .. strangedust
		}
}

function PEItemCache()
    local NoneCachedItems = ""
    local CachedItems = ""
    for _, itemID in pairs(ItemCacheTable) do
            local itemLink = select(2, GetItemInfo(itemID))
            if not itemLink then
                NoneCachedItems = NoneCachedItems .. itemID .. ", "
			elseif itemLink then
                CachedItems = CachedItems .. itemLink .. ", "
            end
    end
	print("Item Cache complete")
end

-- Get total mats required for a tradeskill
function ProEnchants_GetReagentList(SpellID, reqQuantity)
    local id = SpellID
    local AllMatsReq = ""
	if reqQuantity == nil then
		reqQuantity = 1
	end
	local reqQuantity = reqQuantity

    if MaterialsForEnchanting[id] then
        for _, matsReq in ipairs(MaterialsForEnchanting[id]) do
            -- Extract quantity and material name
            local quantity, material = matsReq:match("(%d+)x (.+)")
			local itemId = material:match(":(%d+):")
			local material = select(2, GetItemInfo(itemId))
            quantity = tonumber(quantity) * reqQuantity

            -- Append to the AllMatsReq string
            if AllMatsReq ~= "" then
                AllMatsReq = AllMatsReq .. ", " .. quantity .. "x " .. material
            else
                AllMatsReq = quantity .. "x " .. material
            end
        end
    end
    return AllMatsReq
end

function ProEnchants_GetReagentListNoLink(SpellID, reqQuantity)
    local id = SpellID
    local AllMatsReq = ""
	if reqQuantity == nil then
		reqQuantity = 1
	end
	local reqQuantity = reqQuantity

    if MaterialsForEnchanting[id] then
        for _, matsReq in ipairs(MaterialsForEnchanting[id]) do
            -- Extract quantity and material name
            local quantity, material = matsReq:match("(%d+)x (.+)")
			material = material:match("%[(.-)%]")
            quantity = tonumber(quantity) * reqQuantity

            -- Append to the AllMatsReq string
            if AllMatsReq ~= "" then
                AllMatsReq = AllMatsReq .. ", " .. quantity .. "x " .. material
            else
                AllMatsReq = quantity .. "x " .. material
            end
        end
    end
    return AllMatsReq
end

function GetAllReqMats(customerName)
    -- Count the occurrences of each enchantment
	local customerName = string.lower(customerName)
    local enchantCounts = {}
	for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
    		for _, enchantID in ipairs(frameInfo.Enchants) do
       			enchantCounts[enchantID] = (enchantCounts[enchantID] or 0) + 1
    		end

    -- Get the total materials required for each enchantment
    local totalMaterials = {}
	local AllMatsReq = {}
	local currentString = ""
    for enchantID, count in pairs(enchantCounts) do
        local materials = ProEnchants_GetReagentList(enchantID, count)
        -- Split materials string into individual materials and sum up
        for quantity, material in string.gmatch(materials, "(%d+)x ([^,]+)") do
            quantity = tonumber(quantity)
            totalMaterials[material] = (totalMaterials[material] or 0) + quantity
        end
    end

    -- Convert the totalMaterials table back into a string
	local itemcount = 1
	currentString = ""
    for material, quantity in pairs(totalMaterials) do
		local itemId = material:match(":(%d+):")
		local material = select(2, GetItemInfo(itemId))
		local addition = quantity .. "x " .. material
			if itemcount == 6 then
				table.insert(AllMatsReq, currentString)
				currentString = addition
				itemcount = 2
			else
				if itemcount >= 2 then
					currentString = currentString .. ", "
				end
				currentString = currentString .. addition
				itemcount = itemcount + 1
				end
			end
			if itemcount > 0 then
				table.insert(AllMatsReq, currentString)
			end
			return AllMatsReq
		end
	end
	return {}
end

function GetAllReqMatsNoLink(customerName)
	local customerName = string.lower(customerName)
    local enchantCounts = {}
    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            for _, enchantID in ipairs(frameInfo.Enchants) do
                enchantCounts[enchantID] = (enchantCounts[enchantID] or 0) + 1
            end

            local totalMaterials = {}
            for enchantID, count in pairs(enchantCounts) do
                local materials = ProEnchants_GetReagentList(enchantID, count)
                for quantity, material in string.gmatch(materials, "(%d+)x ([^,]+)") do
                    quantity = tonumber(quantity)
                    material = material:match("%[(.-)%]")
                    totalMaterials[material] = (totalMaterials[material] or 0) + quantity
                end
            end

            local AllMatsReq = {}
            local currentString = ""
            for material, quantity in pairs(totalMaterials) do
                local addition = quantity .. "x " .. material
                if #currentString + #addition + 2 > 200 then  -- +2 for potential comma and space
                    table.insert(AllMatsReq, currentString)
                    currentString = addition
                else
                    if #currentString > 0 then
                        currentString = currentString .. ", "
                    end
                    currentString = currentString .. addition
                end
            end
            if #currentString > 0 then
                table.insert(AllMatsReq, currentString)
            end

            return AllMatsReq
        end
    end
    return {}
end


function stringshorten(enchName)
    local shortened = enchName:match("^Enchant%s+(%w+)")
    return shortened or enchName
end

--- DropDown Menu Creation by Jordan Benge
--- Opts:
---     name (string): Name of the dropdown (lowercase)
---     parent (Frame): Parent frame of the dropdown.
---     items (Table): String table of the dropdown options.
---     defaultVal (String): String value for the dropdown to default to (empty otherwise).
---     changeFunc (Function): A custom function to be called, after selecting a dropdown option.
local function createDropdown(opts)
    local dropdown_name = '$parent_' .. opts['name'] .. '_dropdown'
    local menu_items = opts['items'] or {}
    local title_text = opts['title'] or ''
    local dropdown_width = 0
    local default_val = opts['defaultVal'] or ''
    local change_func = opts['changeFunc'] or function (dropdown_val) end

    local dropdown = CreateFrame("Frame", dropdown_name, opts['parent'], 'UIDropDownMenuTemplate')
	dropdown:SetWidth(120)
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
            info.menuList= key
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


function GetAllReqEnchNoLink(customerName)
	local customerName = string.lower(customerName)
    -- Count the occurrences of each enchantment
    local enchantCounts = {}
	local AllEnchsReq = ""
	for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
    for _, enchantID in ipairs(frameInfo.Enchants) do
        enchantCounts[enchantID] = (enchantCounts[enchantID] or 0) + 1
    end

    -- Get the total materials required for each enchantment
	local AllEnchReq = {}
	local currentString = ""
    for enchantID, count in pairs(enchantCounts) do
        local enchName, enchStats = GetEnchantName(enchantID)
		local enchNameShort = stringshorten(enchName)
		local enchComplete = enchNameShort .. enchStats
		local count = count
		local addition = count .. "x " .. enchComplete
		if #currentString + #addition + 2 > 200 then
			table.insert(AllEnchReq, currentString)
			currentString = addition
		else
			if #currentString > 0 then
				currentString = currentString .. ", "
			end
			currentString = currentString .. addition
		end
	end
	if #currentString > 0 then
		table.insert(AllEnchReq, currentString)
	end

	return AllEnchReq
end
end
return {}
end

--[[function GetAllReqMatsNoLink(customerName)
    local enchantCounts = {}
    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            for _, enchantID in ipairs(frameInfo.Enchants) do
                enchantCounts[enchantID] = (enchantCounts[enchantID] or 0) + 1
            end

            local totalMaterials = {}
            for enchantID, count in pairs(enchantCounts) do
                local materials = ProEnchants_GetReagentList(enchantID, count)
                for quantity, material in string.gmatch(materials, "(%d+)x ([^,]+)") do
                    quantity = tonumber(quantity)
                    material = material:match("%[(.-)%]")
                    totalMaterials[material] = (totalMaterials[material] or 0) + quantity
                end
            end

            local AllMatsReq = {}
            local currentString = ""
            for material, quantity in pairs(totalMaterials) do
                local addition = quantity .. "x " .. material
                if #currentString + #addition + 2 > 200 then  -- +2 for potential comma and space
                    table.insert(AllMatsReq, currentString)
                    currentString = addition
                else
                    if #currentString > 0 then
                        currentString = currentString .. ", "
                    end
                    currentString = currentString .. addition
                end
            end
            if #currentString > 0 then
                table.insert(AllMatsReq, currentString)
            end

            return AllMatsReq
        end
    end
    return {}
end]]


function CheckIfPartyMember(customerName)
	local customerName = string.lower(customerName)
    local inRaid = IsInRaid()
    local groupSize = GetNumGroupMembers()
    
    if inRaid then
        for i = 1, groupSize do
            local name, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
			name = string.lower(name)
            if name and strsplit("-", name) == customerName then
                return true
            end
        end
    else
        for i = 1, groupSize do
            local name = GetUnitName("party" .. i, true)
			name = string.lower(name)
            if name and strsplit("-", name) == customerName then
                return true
            end
        end
    end

    return false
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

    for id, frameInfo in pairs(WorkOrderFrames) do

		local frameInfoString = tostring(frameInfo)
		local cusFrameCheck = string.lower(frameInfo.Frame.customerName)

        if frameInfo.Completed == false then
            if cusName == cusFrameCheck then
				break
                -- Found the active work order, break the loop
			elseif frameInfo.Frame.minimized == false then
				scrollPosition = scrollPosition + 222
			elseif frameInfo.Frame.minimized == true then
				scrollPosition = scrollPosition + 22
			end
        end
    end
    -- Set the scroll position to bring the active work order into view
    scrollFrame:SetVerticalScroll(scrollPosition)
end

function ProEnchantersCreateWorkOrderFrame()
    local WorkOrderFrame = CreateFrame("Frame", "ProEnchantersWorkOrderFrame", UIParent, "BackdropTemplate")
    WorkOrderFrame:SetFrameStrata("DIALOG")
    WorkOrderFrame:SetSize(440, 630)  -- Adjust height as needed
    WorkOrderFrame:SetPoint("TOP", 0, -200)
    WorkOrderFrame:SetMovable(true)
    WorkOrderFrame:EnableMouse(true)
    WorkOrderFrame:RegisterForDrag("LeftButton")
    WorkOrderFrame:SetScript("OnDragStart", WorkOrderFrame.StartMoving)
	WorkOrderFrame:SetScript("OnDragStop", function()
		WorkOrderFrame:StopMovingOrSizing()
	end)

    WorkOrderFrame:Hide()

    -- Create a full background texture
    local bgTexture = WorkOrderFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(440, 545)
    bgTexture:SetPoint("TOP", WorkOrderFrame, "TOP", 0, -60)

    -- Create a title background
    local titleBg = WorkOrderFrame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    titleBg:SetSize(440, 25)  -- Adjust size as needed
    titleBg:SetPoint("TOP", WorkOrderFrame, "TOP", 0, 0)
	
	-- Auto Invite Checkbox
	local autoInviteCb = CreateFrame("CheckButton", nil, WorkOrderFrame, "ChatConfigCheckButtonTemplate")
	autoInviteCb:SetPoint("TOPRIGHT", WorkOrderFrame, "TOPRIGHT", -6, 0)
	autoInviteCb:SetFrameLevel(9001)
	autoInviteCb:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	autoInviteCb:SetHitRectInsets(0, 0, 0, 0)
	autoInviteCb:SetChecked(ProEnchantersOptions["AutoInvite"])
	autoInviteCb:SetScript("OnClick", function(self)
		ProEnchantersOptions["AutoInvite"] = self:GetChecked()
		AutoInvite = ProEnchantersOptions["AutoInvite"]
	end)

	-- Auto Invite text
	local autoinviteHeader = WorkOrderFrame:CreateFontString(nil, "OVERLAY")
	autoinviteHeader:SetFontObject("GameFontHighlight")
	autoinviteHeader:SetPoint("RIGHT", autoInviteCb, "LEFT", -5, 0)
	autoinviteHeader:SetText("Auto Invite?")
	autoinviteHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local newcustomerBg = WorkOrderFrame:CreateTexture(nil, "BACKGROUND")
    newcustomerBg:SetColorTexture(unpack(DarkBgOpaque))  -- Set RGBA values for your preferred color and alpha
    newcustomerBg:SetSize(440, 35)  -- Adjust size as needed
    newcustomerBg:SetPoint("TOP", WorkOrderFrame, "TOP", 0, -25)

	local newcustomerBorder = WorkOrderFrame:CreateTexture(nil, "OVERLAY")
    newcustomerBorder:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    newcustomerBorder:SetSize(440, 1)  -- Adjust size as needed
    newcustomerBorder:SetPoint("BOTTOM", newcustomerBg, "BOTTOM", 0, 0)

	--[[local customerNameEditBoxBg = WorkOrderFrame:CreateTexture(nil, "BACKGROUND")
    customerNameEditBoxBg:SetColorTexture(unpack(LightBgOpaque))  -- Set RGBA values for your preferred color and alpha
    customerNameEditBoxBg:SetSize(160, 22)  -- Adjust size as needed
    customerNameEditBoxBg:SetPoint("TOP", newcustomerBg, "TOP", -5, -9)]]

	-- Create an EditBox for the customer name
	local customerNameEditBox = CreateFrame("EditBox", "ProEnchantersCustomerNameEditBox", WorkOrderFrame, "InputBoxTemplate")
	customerNameEditBox:SetSize(156, 20)
	customerNameEditBox:SetFrameLevel(9001)
	customerNameEditBox:SetPoint("TOP", newcustomerBg, "TOP", -5, -10)
	customerNameEditBox:SetAutoFocus(false)
	customerNameEditBox:SetFontObject("GameFontHighlight")
	customerNameEditBox:SetScript("OnEnterPressed", function()
		OnCreateWorkorderButtonClick()  -- Call your existing function
		customerNameEditBox:ClearFocus()  -- Remove focus from the edit box
		local customerName = ProEnchantersCustomerNameEditBox:GetText()
		UpdateTradeHistory(customerName)
	end)

	-- Create a header for the customer name input
	local customerHeader = WorkOrderFrame:CreateFontString(nil, "OVERLAY")
	customerHeader:SetFontObject("GameFontHighlight")
	customerHeader:SetPoint("RIGHT", customerNameEditBox, "LEFT", -10, 0)
	customerHeader:SetText("Customer:")
	customerHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local createBg = WorkOrderFrame:CreateTexture(nil, "ARTWORK")
    createBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    createBg:SetSize(60, 20)  -- Adjust size as needed
    createBg:SetPoint("LEFT", customerNameEditBox, "RIGHT", 10, 0)

	-- Create a "Create" button
	local createButton = CreateFrame("Button", nil, WorkOrderFrame)--, "GameMenuButtonTemplate")
	createButton:SetSize(60, 20)
	createButton:SetFrameLevel(9001)
	createButton:SetPoint("LEFT", customerNameEditBox, "RIGHT", 10, 0)
	createButton:SetText("Create")
	local createButtonText = createButton:GetFontString()
	createButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	createButton:SetNormalFontObject("GameFontHighlight")
	createButton:SetHighlightFontObject("GameFontNormal")
	createButton:SetScript("OnClick", function()
		OnCreateWorkorderButtonClick()  -- Call your existing function
		customerNameEditBox:ClearFocus()  -- Remove focus from the edit box
		local customerName = ProEnchantersCustomerNameEditBox:GetText()
		UpdateTradeHistory(customerName)
	end)

    -- Scroll frame setup...
    local WorkOrderScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersWorkOrderScrollFrame", WorkOrderFrame, "UIPanelScrollFrameTemplate")
    WorkOrderScrollFrame:SetSize(415, 545)
    WorkOrderScrollFrame:SetPoint("TOP", newcustomerBg, "BOTTOM", -10, 0)

		-- Create a scroll background
		local scrollBg = WorkOrderFrame:CreateTexture(nil, "ARTWORK")
		scrollBg:SetColorTexture(unpack(LightBgTrans))  -- Set RGBA values for your preferred color and alpha
		scrollBg:SetSize(18, 545)  -- Adjust size as needed
		scrollBg:SetPoint("TOPRIGHT", WorkOrderFrame, "TOPRIGHT", 0, -60)
	
	-- Access the Scroll Bar
	local scrollBar = WorkOrderScrollFrame.ScrollBar
	scrollBar:SetFrameLevel(9000)

	-- Customize Thumb Texture
local thumbTexture = scrollBar:GetThumbTexture()
thumbTexture:SetTexture(nil)  -- Clear existing texture
thumbTexture:SetColorTexture(unpack(DarkBgOpaque))
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
upButton:GetNormalTexture():SetColorTexture(unpack(DarkBgOpaque)) -- Replace RGBA values as needed

-- Set solid color for pushed state
upButton:GetPushedTexture():SetColorTexture(unpack(LightBgOpaque)) -- Replace RGBA values as needed

-- Set solid color for disabled state
upButton:GetDisabledTexture():SetColorTexture(unpack(DarkBgTrans)) -- Replace RGBA values as needed

-- Set solid color for highlight state
upButton:GetHighlightTexture():SetColorTexture(unpack(LightBgTrans)) -- Replace RGBA values as needed

-- Repeat for Scroll Down Button
local downButton = scrollBar.ScrollDownButton

-- Clear existing textures
downButton:GetNormalTexture():SetTexture(nil)
downButton:GetPushedTexture():SetTexture(nil)
downButton:GetDisabledTexture():SetTexture(nil)
downButton:GetHighlightTexture():SetTexture(nil)

-- Set solid color for normal state
downButton:GetNormalTexture():SetColorTexture(unpack(DarkBgOpaque)) -- Adjust colors as needed

-- Set solid color for pushed state
downButton:GetPushedTexture():SetColorTexture(unpack(LightBgOpaque)) -- Adjust colors as needed

-- Set solid color for disabled state
downButton:GetDisabledTexture():SetColorTexture(unpack(DarkBgTrans)) -- Adjust colors as needed

-- Set solid color for highlight state
downButton:GetHighlightTexture():SetColorTexture(unpack(LightBgTrans)) -- Adjust colors as needed

local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
upButtonText:SetText("-") -- Set the text for the up button
upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
downButtonText:SetText("-") -- Set the text for the down button
downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed


    -- Scroll child frame where elements are actually placed
    local ScrollChild = CreateFrame("Frame")
	ScrollChild:SetFrameLevel(8890)
    ScrollChild:SetSize(425, 545)  -- Adjust height based on the number of elements
    WorkOrderScrollFrame:SetScrollChild(ScrollChild)
	
	-- local yOffset = -15

	-- Create a close button background
    local closeBg = WorkOrderFrame:CreateTexture(nil, "BACKGROUND")
    closeBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    closeBg:SetSize(440, 25)  -- Adjust size as needed
    closeBg:SetPoint("BOTTOMLEFT", WorkOrderFrame, "BOTTOMLEFT", 0, 0)

	-- Create a close button at the bottom
	local closeButton = CreateFrame("Button", nil, WorkOrderFrame)
	closeButton:SetSize(35, 25)  -- Adjust size as needed
	closeButton:SetFrameLevel(9001)
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 5, 0)  -- Adjust position as needed
	closeButton:SetText("Close")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")
	closeButton:SetScript("OnClick", function()
		WorkOrderFrame:Hide()
	end)

	local settingsButton = CreateFrame("Button", nil, WorkOrderFrame)
	settingsButton:SetSize(46, 25)  -- Adjust size as needed
	settingsButton:SetFrameLevel(9001)
	settingsButton:SetPoint("LEFT", closeButton, "RIGHT", 2, 0)  -- Adjust position as needed
	settingsButton:SetText("Settings")
	local settingsButtonText = settingsButton:GetFontString()
	settingsButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	settingsButton:SetNormalFontObject("GameFontHighlight")
	settingsButton:SetHighlightFontObject("GameFontNormal")
	settingsButton:SetScript("OnClick", function()
		ProEnchantersOptionsFrame:Show()
	end)

	local ClearAllButton = CreateFrame("Button", nil, WorkOrderFrame)
	ClearAllButton:SetSize(110, 20)  -- Adjust size as needed
	ClearAllButton:SetFrameLevel(9001)
	ClearAllButton:SetPoint("LEFT", settingsButton, "RIGHT", 8, 0)  -- Adjust position as needed
	ClearAllButton:SetText("Finish All Work Orders")
	local ClearAllButtonText = ClearAllButton:GetFontString()
	ClearAllButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	ClearAllButton:SetNormalFontObject("GameFontHighlight")
	ClearAllButton:SetHighlightFontObject("GameFontNormal")
	ClearAllButton:SetScript("OnClick", function()
		for id, frameInfo in pairs(WorkOrderFrames) do
			if frameInfo.Completed == false then
				frameInfo.Completed = true
				frameInfo.Frame:Hide()
				local customerName = frameInfo.Frame.customerName
				local tradeLine = LIGHTGREEN .. "---- End of Workorder# " .. frameInfo.Frame.frameID .. " ----" .. ColorClose
				table.insert(ProEnchantersTradeHistory[customerName], tradeLine)
			end
		end
		ProEnchantersCustomerNameEditBox:SetText("")
		ProEnchantersCustomerNameEditBox:ClearFocus(ProEnchantersCustomerNameEditBox)
		yOffset = -5
	end)

	-- GoldTraded Display
	local GoldTradedDisplay = WorkOrderFrame:CreateFontString(nil, "OVERLAY")
	GoldTradedDisplay:SetFontObject("GameFontHighlight")
	GoldTradedDisplay:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 7)
	GoldTradedDisplay:SetText("Gold Traded: " .. GetMoneyString(GoldTraded))
	GoldTradedDisplay:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	WorkOrderFrame.GoldTradedDisplay = GoldTradedDisplay
	
	WorkOrderFrame:SetScript("OnHide", function()
		ProEnchantersOptionsFrame:Hide()
		ProEnchantersTriggersFrame:Hide()
		ProEnchantersWhisperTriggersFrame:Hide()
		--ProEnchantersGoldLogFrame:Hide()
		ProEnchantersCreditsFrame:Hide()
		ProEnchantersColorsFrame:Hide()
	end)

	--WorkOrderFrame:SetScript("OnShow", function() end)

	-- Top Title Minimizes Frame
	local titleButton = CreateFrame("Button", nil, WorkOrderFrame)
	titleButton:SetSize(150, 25)  -- Adjust size as needed
	titleButton:SetFrameLevel(9001)
	titleButton:SetPoint("TOP", titleBg, "TOP", 0, 0)  -- Adjust position as needed
	titleButton:SetText("Pro Enchanters - Work Orders")
	local titleButtonText = titleButton:GetFontString()
	titleButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	titleButton:SetNormalFontObject("GameFontHighlight")
	titleButton:SetHighlightFontObject("GameFontNormal")
	titleButton:SetScript("OnClick", function()
        local isVisible = ScrollChild:IsVisible()
		bgTexture:SetShown(not isVisible)
        ScrollChild:SetShown(not isVisible)
        closeBg:SetShown(not isVisible)
		ClearAllButton:SetShown(not isVisible)
        closeButton:SetShown(not isVisible)
		settingsButton:SetShown(not isVisible)
		GoldTradedDisplay:SetShown(not isVisible)
        scrollBg:SetShown(not isVisible)
		local isVisible2 = WorkOrderScrollFrame:IsVisible()
		WorkOrderScrollFrame:SetShown(not isVisible2)
		local currentWidth, currentHeight = WorkOrderFrame:GetSize()
		local point, relativeTo, relativePoint, xOfs, yOfs = WorkOrderFrame:GetPoint()
		local x, y = GetCursorPosition()
    	local scale = UIParent:GetEffectiveScale()
		x, y = x / scale, y / scale
		if currentHeight == 630 then
        WorkOrderFrame:ClearAllPoints()
        WorkOrderFrame:SetPoint("TOP", relativeTo, "BOTTOMLEFT", x, 10 + y)
        WorkOrderFrame:SetSize(440, 60)
    else
        WorkOrderFrame:ClearAllPoints()
        WorkOrderFrame:SetPoint("TOP", relativeTo, "BOTTOMLEFT", x, 10 + y)
        WorkOrderFrame:SetSize(440, 630)
    end
    end)
	return WorkOrderFrame
end



function ProEnchantersCreateWorkOrderEnchantsFrame(ProEnchantersWorkOrderFrame)
    local WorkOrderEnchantsFrame = CreateFrame("Frame", "ProEnchantersWorkOrderEnchantsFrame", ProEnchantersWorkOrderFrame)
    WorkOrderEnchantsFrame:SetSize(180, 630)  -- Adjust height as needed
    WorkOrderEnchantsFrame:SetFrameStrata("DIALOG")
    WorkOrderEnchantsFrame:SetPoint("TOPLEFT", ProEnchantersWorkOrderFrame, "TOPRIGHT", 0, 0)
	WorkOrderEnchantsFrame:SetMovable(true)
    WorkOrderEnchantsFrame:EnableMouse(true)
    WorkOrderEnchantsFrame:RegisterForDrag("LeftButton")
    WorkOrderEnchantsFrame:SetScript("OnDragStart", WorkOrderEnchantsFrame.StartMoving)
    WorkOrderEnchantsFrame:Hide()

	local EnchantsFrameConnectingBoarder = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
    EnchantsFrameConnectingBoarder:SetColorTexture(0,0,0,0)  -- Set RGBA values for your preferred color and alpha
    EnchantsFrameConnectingBoarder:SetSize(2, 630)  -- Adjust size as needed
    EnchantsFrameConnectingBoarder:SetPoint("TOPRIGHT", WorkOrderEnchantsFrame, "TOPLEFT", 0, 0)
	EnchantsFrameConnectingBoarder:Show()

    -- Create a full background texture
    local bgTexture = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(180, 570)
    bgTexture:SetPoint("TOP", WorkOrderEnchantsFrame, "TOP", 0, -60)

    -- Create a title background
    local titleBg = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    titleBg:SetSize(180, 25)  -- Adjust size as needed
    titleBg:SetPoint("TOP", WorkOrderEnchantsFrame, "TOP", 0, 0)


	local filterBg = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
    filterBg:SetColorTexture(unpack(DarkBgOpaque))  -- Set RGBA values for your preferred color and alpha
    filterBg:SetSize(180, 35)  -- Adjust size as needed
    filterBg:SetPoint("TOP", WorkOrderEnchantsFrame, "TOP", 0, -25)

	local filterBgBorder = WorkOrderEnchantsFrame:CreateTexture(nil, "OVERLAY")
    filterBgBorder:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    filterBgBorder:SetSize(180, 1)  -- Adjust size as needed
    filterBgBorder:SetPoint("BOTTOM", filterBg, "BOTTOM", 0, 0)


	-- Create an EditBox for the customer name
	local filterEditBox = CreateFrame("EditBox", "ProEnchantersCustomerNameEditBox", WorkOrderEnchantsFrame, "InputBoxTemplate")
	filterEditBox:SetSize(65, 20)
	filterEditBox:SetPoint("TOP", filterBg, "TOP", 0, -10)
	filterEditBox:SetAutoFocus(false)
	-- Set Text
	filterEditBox:SetFontObject("GameFontHighlight")
	-- Scripts
	filterEditBox:SetScript("OnEnterPressed", filterEditBox.ClearFocus)

	local filterEditBoxBg = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
    filterEditBoxBg:SetColorTexture(0.4, 0.4, 0.4, 0)  -- Set RGBA values for your preferred color and alpha
    filterEditBoxBg:SetSize(70, 22)  -- Adjust size as needed
    filterEditBoxBg:SetPoint("TOP", filterBg, "TOP", 0, -9)

	filterEditBox:SetScript("OnTextChanged", function()
		FilterEnchantButtons()
	end)

	-- Create a header for the customer name input
	local filterHeader = WorkOrderEnchantsFrame:CreateFontString(nil, "OVERLAY")
	filterHeader:SetFontObject("GameFontHighlight")
	filterHeader:SetPoint("RIGHT", filterEditBox, "LEFT", -10, 0)
	filterHeader:SetText("Filter:")
	filterHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local clearBg = WorkOrderEnchantsFrame:CreateTexture(nil, "OVERLAY")
    clearBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    clearBg:SetSize(40, 20)  -- Adjust size as needed
    clearBg:SetPoint("LEFT", filterEditBox, "RIGHT", 10, 0)

	-- Create a "Create" button
	local clearButton = CreateFrame("Button", nil, WorkOrderEnchantsFrame)--, "GameMenuButtonTemplate")
	clearButton:SetSize(40, 20)
	clearButton:SetPoint("LEFT", filterEditBox, "RIGHT", 10, 0)
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
    local WorkOrderEnchantsScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersWorkOrderEnchantsScrollFrame", WorkOrderEnchantsFrame, "UIPanelScrollFrameTemplate")
    WorkOrderEnchantsScrollFrame:SetSize(150, 570)
    WorkOrderEnchantsScrollFrame:SetPoint("TOP", filterBg, "BOTTOM", -8, 0)

	-- Create a scroll background
	local scrollBg = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
	scrollBg:SetColorTexture(unpack(LightBgTrans))  -- Set RGBA values for your preferred color and alpha
	scrollBg:SetSize(18, 570)  -- Adjust size as needed
	scrollBg:SetPoint("TOPRIGHT", WorkOrderEnchantsFrame, "TOPRIGHT", 0, -60)

	-- Access the Scroll Bar
	local scrollBar = WorkOrderEnchantsScrollFrame.ScrollBar

	-- Customize Thumb Texture
local thumbTexture = scrollBar:GetThumbTexture()
thumbTexture:SetTexture(nil)  -- Clear existing texture
thumbTexture:SetColorTexture(unpack(DarkBgOpaque))
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
upButton:GetNormalTexture():SetColorTexture(unpack(DarkBgOpaque)) -- Replace RGBA values as needed

-- Set solid color for pushed state
upButton:GetPushedTexture():SetColorTexture(unpack(LightBgOpaque)) -- Replace RGBA values as needed

-- Set solid color for disabled state
upButton:GetDisabledTexture():SetColorTexture(unpack(DarkBgTrans)) -- Replace RGBA values as needed

-- Set solid color for highlight state
upButton:GetHighlightTexture():SetColorTexture(unpack(LightBgTrans)) -- Replace RGBA values as needed

-- Repeat for Scroll Down Button
local downButton = scrollBar.ScrollDownButton

-- Clear existing textures
downButton:GetNormalTexture():SetTexture(nil)
downButton:GetPushedTexture():SetTexture(nil)
downButton:GetDisabledTexture():SetTexture(nil)
downButton:GetHighlightTexture():SetTexture(nil)

-- Set solid color for normal state
downButton:GetNormalTexture():SetColorTexture(unpack(DarkBgOpaque)) -- Adjust colors as needed

-- Set solid color for pushed state
downButton:GetPushedTexture():SetColorTexture(unpack(LightBgOpaque)) -- Adjust colors as needed

-- Set solid color for disabled state
downButton:GetDisabledTexture():SetColorTexture(unpack(DarkBgTrans)) -- Adjust colors as needed

-- Set solid color for highlight state
downButton:GetHighlightTexture():SetColorTexture(unpack(LightBgTrans)) -- Adjust colors as needed

local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
upButtonText:SetText("-") -- Set the text for the up button
upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
downButtonText:SetText("-") -- Set the text for the down button
downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed

    -- Scroll child frame where elements are actually placed
    local ScrollChild = CreateFrame("Frame")
    ScrollChild:SetSize(150, 565)  -- Adjust height based on the number of elements
    WorkOrderEnchantsScrollFrame:SetScrollChild(ScrollChild)

	-- Using "for _, Enchants in ipairs(EnchantsName) do", create a clickable button that is 120x30, uses the key from enchants as the ID of the button and uses the value of the key as the text on the button. When this button is pressed, update the table CusEnchant in the current focus CusWorkOrder ENCHANTS frame by adding +1 to the value of the key. As an example, the start of the CusEnchant table should be ENCH1=0, update this to be ENCH1=1. When pressed again, add +1 again so that it is now ENCH1=2, and so forth as buttons are pressed.
	local enchyOffset = 5 -- Initial vertical offset for the first button
	
	local function alphanumericSort(a, b)
		-- Extract number from the string
		local numA = tonumber(a:match("%d+"))
		local numB = tonumber(b:match("%d+"))
		
		if numA and numB then  -- If both strings have numbers, then compare numerically
			return numA < numB
		else
			return a < b  -- If one or both strings don't have numbers, sort lexicographically
		end
	end
	
	-- Get and sort the keys
	local keys = {}
	for k in pairs(EnchantsName) do
		table.insert(keys, k)
	end
	table.sort(keys, alphanumericSort)  -- Sorts the keys in natural alphanumeric order
	
	enchantButtons = {}
	function FilterEnchantButtons()
		local filterText = filterEditBox:GetText():lower()
		local enchyOffset = 5
		local enchxOffset = 5

		for _, key in ipairs(keys) do
			if ProEnchantersOptions.filters[key] == true then
			local enchantInfo = enchantButtons[key]
				local enchantName = EnchantsName[key]:lower()
				local enchantStats1 = EnchantsStats[key]
				local enchantStats2 = string.gsub(enchantStats1, "%(", "")
				local enchantStats3 = string.gsub(enchantStats2, "%)", "")
				local filterCheck = string.lower(enchantName .. enchantStats3)
				if filterText == "" or filterCheck:find(filterText, 1, true) then
					-- Show and position the button
					enchantInfo.button:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)
					enchantInfo.button:Show()
					enchantInfo.background:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)
					enchantInfo.background:Show()
					enchyOffset = enchyOffset + 50
				else
					-- Hide the button
					enchantInfo.button:Hide()
					enchantInfo.background:Hide()
				end
			end
		end
	
		-- Adjust the height of ScrollChild based on the yOffset
		ScrollChild:SetHeight(enchyOffset)
	end


    for _, key in ipairs(keys) do
		local value = EnchantsName[key]
		local enchantStats1 = EnchantsStats[key]
		local enchantStats2 = string.gsub(enchantStats1, "%(", "")
		local enchantStats3 = string.gsub(enchantStats2, "%)", "")
		local enchantStats = string.gsub(enchantStats3, "%+", "")
        -- Split the enchantment name at the dash
        local enchantTitleText1 = string.gsub(value, " %- ", "\n")
		local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats
        local ench = key
        local enchName = value

        -- Create button Bg
        local enchantButtonBg = ScrollChild:CreateTexture(nil, "OVERLAY")
        enchantButtonBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
        enchantButtonBg:SetSize(145, 45)  -- Adjust size as needed
        enchantButtonBg:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)

        -- Create a button
        local enchantButton = CreateFrame("Button", key, ScrollChild)
        enchantButton:SetSize(145, 45) -- Adjust the size as needed
        enchantButton:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", enchxOffset, -enchyOffset)
        enchantButton:SetText(enchantTitleText)
		local enchantButtonText = enchantButton:GetFontString()
		enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
        enchantButton:SetNormalFontObject("GameFontHighlight")
        enchantButton:SetHighlightFontObject("GameFontNormal")

        -- Set the script for the button's OnClick event
        enchantButton:SetScript("OnClick", function(self, button)
			local customerName = ProEnchantersCustomerNameEditBox:GetText()
			customerName = string.lower(customerName)
			customerName = CapFirstLetter(customerName)
			local reqEnchant = ench
			local enchName, enchStats = GetEnchantName(reqEnchant)
			filterEditBox.ClearFocus(filterEditBox)
			if IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown() then
				ProEnchantersOptions.filters[reqEnchant] = false
				enchantButton:Hide()
				enchantButtonBg:Hide()
				FilterEnchantButtons()
				UpdateCheckboxesBasedOnFilters()
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
				if confirmTradeTarget == currentTradeTarget then
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
		end)

        -- Increase yOffset for the next button
        enchyOffset = enchyOffset + 50 -- Adjust the offset increment as needed
		
		-- Store the button and its background in the table
		enchantButtons[key] = { button = enchantButton, background = enchantButtonBg }
		if ProEnchantersOptions.filters[key] == false then
			enchantButton:Hide()
			enchantButtonBg:Hide()
		end
    end


	-- Adjust the height of ScrollChild based on the yOffset
	ScrollChild:SetHeight(enchyOffset)

	-- Create a Snap button background
    local snapBg = WorkOrderEnchantsFrame:CreateTexture(nil, "BACKGROUND")
    snapBg:SetColorTexture(0.14, 0.05, 0.2, 0)  -- Set RGBA values for your preferred color and alpha
    snapBg:SetSize(25, 25)  -- Adjust size as needed
    snapBg:SetPoint("TOPRIGHT", WorkOrderEnchantsFrame, "TOPRIGHT", 0, 0)
	snapBg:Hide()
	-- Create a Snap button at the bottom
	local snapButton = CreateFrame("Button", nil, WorkOrderEnchantsFrame)
	snapButton:SetSize(25, 25)  -- Adjust size as needed
	snapButton:SetPoint("BOTTOM", snapBg, "BOTTOM", 1, 0)  -- Adjust position as needed
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
		EnchantsFrameConnectingBoarder:Show()
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

	local titleButton = CreateFrame("Button", nil, WorkOrderEnchantsFrame)
	titleButton:SetSize(60, 25)  -- Adjust size as needed
	titleButton:SetPoint("BOTTOM", titleBg, "BOTTOM", 1, 0)  -- Adjust position as needed
	titleButton:SetText("Enchants")
	local titleButtonText = titleButton:GetFontString()
	titleButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	titleButton:SetNormalFontObject("GameFontHighlight")
	titleButton:SetHighlightFontObject("GameFontNormal")
	titleButton:SetScript("OnClick", function()
        local isVisible = ScrollChild:IsVisible()
		bgTexture:SetShown(not isVisible)
        ScrollChild:SetShown(not isVisible)
        snapBg:SetShown(not isVisible)
        snapButton:SetShown(not isVisible)

		-- Rest of logic
        scrollBg:SetShown(not isVisible)
		local isVisible2 = WorkOrderEnchantsScrollFrame:IsVisible()
		WorkOrderEnchantsScrollFrame:SetShown(not isVisible2)
		local currentWidthBoarder, currentHeightBoarder = EnchantsFrameConnectingBoarder:GetSize()
    	if currentHeightBoarder == 630 then
        	EnchantsFrameConnectingBoarder:SetSize(2, 60)
    	else
        	EnchantsFrameConnectingBoarder:SetSize(2, 630)
   		end
		   local currentWidth, currentHeight = WorkOrderEnchantsFrame:GetSize()
		if currentHeight == 630 then
			WorkOrderEnchantsFrame:SetSize(180, 60)
			RepositionEnchantsFrame(WorkOrderEnchantsFrame)
	   else
			WorkOrderEnchantsFrame:SetSize(180, 630)
			--RepositionEnchantsFrame(WorkOrderEnchantsFrame)
	   end
	end)

	RepositionEnchantsFrame(WorkOrderEnchantsFrame)
	return WorkOrderEnchantsFrame
end


function ProEnchantersCreateOptionsFrame()
    local OptionsFrame = CreateFrame("Frame", "ProEnchantersOptionsFrame", UIParent, "BackdropTemplate")
    OptionsFrame:SetFrameStrata("FULLSCREEN")
    OptionsFrame:SetSize(800, 350)  -- Adjust height as needed
    OptionsFrame:SetPoint("TOP", 0, -300)
    OptionsFrame:SetMovable(true)
    OptionsFrame:EnableMouse(true)
    OptionsFrame:RegisterForDrag("LeftButton")
    OptionsFrame:SetScript("OnDragStart", OptionsFrame.StartMoving)
	OptionsFrame:SetScript("OnDragStop", function()
		OptionsFrame:StopMovingOrSizing()
	end)

    OptionsFrame:Hide()

    -- Create a full background texture
    local bgTexture = OptionsFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetColorTexture(unpack(DarkBgOpaque))  -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(800, 325)
    bgTexture:SetPoint("TOP", OptionsFrame, "TOP", 0, -25)

    -- Create a title background
    local titleBg = OptionsFrame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    titleBg:SetSize(800, 25)  -- Adjust size as needed
    titleBg:SetPoint("TOP", OptionsFrame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = OptionsFrame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject("GameFontHighlight")
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Settings")
	titleHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")


    -- Scroll frame setup...
    local OptionsScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersOptionsScrollFrame", OptionsFrame, "UIPanelScrollFrameTemplate")
    OptionsScrollFrame:SetSize(775, 300)
    OptionsScrollFrame:SetPoint("TOP", titleBg, "BOTTOM", -10, 0)

		-- Create a scroll background
		local scrollBg = OptionsFrame:CreateTexture(nil, "BACKGROUND")
		scrollBg:SetColorTexture(unpack(LightBgTrans))  -- Set RGBA values for your preferred color and alpha
		scrollBg:SetSize(17, 300)  -- Adjust size as needed
		scrollBg:SetPoint("TOPRIGHT", OptionsFrame, "TOPRIGHT", 0, -25)
	
	-- Access the Scroll Bar
	local scrollBar = OptionsScrollFrame.ScrollBar

	-- Customize Thumb Texture
local thumbTexture = scrollBar:GetThumbTexture()
thumbTexture:SetTexture(nil)  -- Clear existing texture
thumbTexture:SetColorTexture(unpack(HeaderOpaque))
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
upButton:GetNormalTexture():SetColorTexture(unpack(DarkBgOpaque)) -- Replace RGBA values as needed
upButton:GetPushedTexture():SetColorTexture(unpack(LightBgOpaque)) -- Replace RGBA values as needed
upButton:GetDisabledTexture():SetColorTexture(unpack(DarkBgTrans)) -- Replace RGBA values as needed
upButton:GetHighlightTexture():SetColorTexture(unpack(LightBgTrans)) -- Replace RGBA values as needed

-- Repeat for Scroll Down Button
local downButton = scrollBar.ScrollDownButton

-- Clear existing textures
downButton:GetNormalTexture():SetTexture(nil)
downButton:GetPushedTexture():SetTexture(nil)
downButton:GetDisabledTexture():SetTexture(nil)
downButton:GetHighlightTexture():SetTexture(nil)

-- Set colors
downButton:GetNormalTexture():SetColorTexture(unpack(DarkBgOpaque)) -- Adjust colors as needed
downButton:GetPushedTexture():SetColorTexture(unpack(LightBgOpaque)) -- Adjust colors as needed
downButton:GetDisabledTexture():SetColorTexture(unpack(DarkBgTrans)) -- Adjust colors as needed
downButton:GetHighlightTexture():SetColorTexture(unpack(LightBgTrans)) -- Adjust colors as needed

local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
upButtonText:SetText("-") -- Set the text for the up button
upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
downButtonText:SetText("-") -- Set the text for the down button
downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed


    -- Scroll child frame where elements are actually placed
    local ScrollChild = CreateFrame("Frame")
    ScrollChild:SetSize(800, 300)  -- Adjust height based on the number of elements
    OptionsScrollFrame:SetScrollChild(ScrollChild)

-- Scroll child items below

	-- Create a header for Work While Closed
	local WorkWhileClosedHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	WorkWhileClosedHeader:SetFontObject("GameFontHighlight")
	WorkWhileClosedHeader:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 30, -10)
	WorkWhileClosedHeader:SetText("Work while closed? (Auto invite, potential customer alerts, welcome msg's, etc)")
	WorkWhileClosedHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

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

	-- ProEnchantersOptions["MaxPartySize"]

	local maxPartySizeHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	maxPartySizeHeader:SetFontObject("GameFontHighlight")
	maxPartySizeHeader:SetPoint("TOPLEFT", WorkWhileClosedHeader, "TOPLEFT", 0, -30)
	maxPartySizeHeader:SetText("Party size limit to temporarily stop add-on invites? (Including yourself)")
	maxPartySizeHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local maxPartySizeEditBoxBg = ScrollChild:CreateTexture(nil, "OVERLAY")
	maxPartySizeEditBoxBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	maxPartySizeEditBoxBg:SetSize(25, 25)  -- Adjust size as needed
	maxPartySizeEditBoxBg:SetPoint("LEFT", maxPartySizeHeader, "RIGHT", 10, 0)

	local maxPartySizeEditBox = CreateFrame("EditBox", nil, ScrollChild)
	maxPartySizeEditBox:SetSize(30, 20)
	maxPartySizeEditBox:SetPoint("LEFT", maxPartySizeHeader, "RIGHT", 14, 0)
	maxPartySizeEditBox:SetAutoFocus(false)
	maxPartySizeEditBox:SetNumeric(true)
	maxPartySizeEditBox:SetMaxLetters(2)
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

	-- Create a header for AutoInviteAllChannels
	local DelayWorkOrderHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	DelayWorkOrderHeader:SetFontObject("GameFontHighlight")
	DelayWorkOrderHeader:SetPoint("TOPLEFT", maxPartySizeHeader, "TOPLEFT", 0, -30)
	DelayWorkOrderHeader:SetText("Delay work order creation on non-addon invited players?")
	DelayWorkOrderHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

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
	WhisperMatsHeader:SetFontObject("GameFontHighlight")
	WhisperMatsHeader:SetPoint("TOPLEFT", DelayWorkOrderHeader, "TOPLEFT", 0, -30)
	WhisperMatsHeader:SetText("Always whisper the players mats and requested enchants instead of party chat?")
	WhisperMatsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

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
	filtersButtonBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    filtersButtonBg:SetSize(270, 24)  -- Adjust size as needed
	filtersButtonBg:SetPoint("TOPLEFT", WhisperMatsHeader, "TOPLEFT", -4, -25)

	-- Create a Trigger and Filters for invites button
	local filtersButton2 = CreateFrame("Button", nil, ScrollChild)
	filtersButton2:SetSize(270, 25)  -- Adjust size as needed
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
	whisperTriggersBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    whisperTriggersBg:SetSize(250, 24)  -- Adjust size as needed
	whisperTriggersBg:SetPoint("TOPLEFT", filtersButtonBg, "TOPRIGHT", 15, 0)

	-- Create a Trigger and Filters for invites button
	local whisperTriggersButton = CreateFrame("Button", nil, ScrollChild)
	whisperTriggersButton:SetSize(250, 25)  -- Adjust size as needed
	whisperTriggersButton:SetPoint("CENTER", whisperTriggersBg, "CENTER", 0, 0)  -- Adjust position as needed
	whisperTriggersButton:SetText("Click here to set custom whisper !commands")
	local whisperTriggersButtonText = whisperTriggersButton:GetFontString()
	whisperTriggersButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	whisperTriggersButton:SetNormalFontObject("GameFontHighlight")
	whisperTriggersButton:SetHighlightFontObject("GameFontNormal")
	whisperTriggersButton:SetScript("OnClick", function()
		ProEnchantersWhisperTriggersFrame:Show()
		OptionsFrame:Hide()
	end)


	-- Create a header for AutoInviteAllChannels
	local AutoInviteAllChannelsHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	AutoInviteAllChannelsHeader:SetFontObject("GameFontHighlight")
	AutoInviteAllChannelsHeader:SetPoint("TOPLEFT", filtersButtonBg, "BOTTOMLEFT", 0, -10)
	AutoInviteAllChannelsHeader:SetText("Search all channels for potential Customers?")
	AutoInviteAllChannelsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	-- Auto Invite Checkbox
	local AutoInviteAllChannels = CreateFrame("CheckButton", nil, ScrollChild, "ChatConfigCheckButtonTemplate")
	AutoInviteAllChannels:SetPoint("LEFT", AutoInviteAllChannelsHeader, "RIGHT", 10, 0)
	AutoInviteAllChannels:SetSize(24, 24) -- Set the size of the checkbox to 24x24 pixels
	AutoInviteAllChannels:SetHitRectInsets(0, 0, 0, 0)
	AutoInviteAllChannels:SetChecked(ProEnchantersOptions["AllChannels"])
	AutoInviteAllChannels:SetScript("OnClick", function(self)
		ProEnchantersOptions["AllChannels"] = self:GetChecked()
		AllChannels = ProEnchantersOptions["AllChannels"]
	end)



	-- Create a header for AutoInv Msg
	local AutoInviteMsgEditBoxHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	AutoInviteMsgEditBoxHeader:SetFontObject("GameFontHighlight")
	AutoInviteMsgEditBoxHeader:SetPoint("TOPLEFT", AutoInviteAllChannelsHeader, "TOPLEFT", 0, -30)
	AutoInviteMsgEditBoxHeader:SetText("Auto Invite Msg:")
	AutoInviteMsgEditBoxHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

		-- Create an EditBox for AutoInv Msg
		local AutoInviteMsgEditBox = CreateFrame("EditBox", "ProEnchantersAutoInviteMsgEditBox", ScrollChild, "InputBoxTemplate")
		AutoInviteMsgEditBox:SetSize(600, 20)
		AutoInviteMsgEditBox:SetPoint("TOPLEFT", AutoInviteAllChannels, "TOPLEFT", -105, -30)
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
	FailInviteMsgEditBoxHeader:SetFontObject("GameFontHighlight")
	FailInviteMsgEditBoxHeader:SetPoint("TOPLEFT", AutoInviteMsgEditBoxHeader, "TOPLEFT", 0, -30)
	FailInviteMsgEditBoxHeader:SetText("Failed Invite Msg:")
	FailInviteMsgEditBoxHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

		-- Create an EditBox for Failed Inv Msg
		local FailInviteMsgEditBox = CreateFrame("EditBox", "ProEnchantersAutoInviteMsgEditBox", ScrollChild, "InputBoxTemplate")
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
	FullInviteMsgEditBoxHeader:SetFontObject("GameFontHighlight")
	FullInviteMsgEditBoxHeader:SetPoint("TOPLEFT", FailInviteMsgEditBoxHeader, "TOPLEFT", 0, -30)
	FullInviteMsgEditBoxHeader:SetText("Full Group Inv Msg:")
	FullInviteMsgEditBoxHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	-- Create an EditBox for Full Inv Msg
		local FullInviteMsgEditBox = CreateFrame("EditBox", "ProEnchantersAutoInviteMsgEditBox", ScrollChild, "InputBoxTemplate")
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
	WelcomeMsgEditBoxHeader:SetFontObject("GameFontHighlight")
	WelcomeMsgEditBoxHeader:SetPoint("TOPLEFT", FullInviteMsgEditBoxHeader, "TOPLEFT", 0, -30)
	WelcomeMsgEditBoxHeader:SetText("Party Welcome Msg:")
	WelcomeMsgEditBoxHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	
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
	TradeMsgEditBoxHeader:SetFontObject("GameFontHighlight")
	TradeMsgEditBoxHeader:SetPoint("TOPLEFT", WelcomeMsgEditBoxHeader, "TOPLEFT", 0, -30)
	TradeMsgEditBoxHeader:SetText("Trade Started Msg:")
	TradeMsgEditBoxHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	
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
		TipMsgEditBoxHeader:SetFontObject("GameFontHighlight")
		TipMsgEditBoxHeader:SetPoint("TOPLEFT", TradeMsgEditBoxHeader, "TOPLEFT", 0, -30)
		TipMsgEditBoxHeader:SetText("Tip Received Msg:")
		TipMsgEditBoxHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

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
	local RaidIconHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	RaidIconHeader:SetFontObject("GameFontHighlight")
	RaidIconHeader:SetPoint("TOPLEFT", TipMsgEditBoxHeader, "TOPLEFT", 0, -30)
	RaidIconHeader:SetText("Auto Raid Icon:")
	RaidIconHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

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
		['name']='raidicon',
		['parent']=ScrollChild,
		['title']='',
		['items']= {"None","Star","Circle","Diamond","Triangle","Moon","Square","Cross","Skull"},
		['defaultVal']=defaultVal,
		['changeFunc']=function(dropdown_frame, dropdown_val)
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
	RaidIconDD:SetPoint("TOPLEFT", TipMsgEditBox, "TOPLEFT", -21, -30)


	-- Create checkboxes for every available enchant to hard filter them out from being available
	-- Create a header for enchant filter
	local enchantFilterHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
	enchantFilterHeader:SetFontObject("GameFontHighlight")
	enchantFilterHeader:SetPoint("TOPLEFT", RaidIconHeader, "TOPLEFT", 30, -30)
	enchantFilterHeader:SetText("Permanently filter the below enchants by unchecking them to stop them from displaying in other parts of the add-on")
	enchantFilterHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local enchantToggleYoffset = 60

	local function alphanumericSort(a, b)
		-- Extract number from the string
		local numA = tonumber(a:match("%d+"))
		local numB = tonumber(b:match("%d+"))
		
		if numA and numB then  -- If both strings have numbers, then compare numerically
			return numA < numB
		else
			return a < b  -- If one or both strings don't have numbers, sort lexicographically
		end
	end

	local keys = {}
	for k in pairs(EnchantsName) do
		table.insert(keys, k)
	end
	table.sort(keys, alphanumericSort)  -- Sorts the keys in natural alphanumeric order

	for _, sortedKey in ipairs(keys) do
			local key = sortedKey
			local enchantName = EnchantsName[sortedKey]
			local enchantStats = EnchantsStats[sortedKey]
			-- Create a header for enchant filter
			local enchantFilterName = ScrollChild:CreateFontString(nil, "OVERLAY")
			enchantFilterName:SetFontObject("GameFontHighlight")
			enchantFilterName:SetPoint("TOPLEFT", RaidIconHeader, "TOPLEFT", 0, -enchantToggleYoffset)
			enchantFilterName:SetText(enchantName .. enchantStats)
			enchantFilterName:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

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
		closeBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
		closeBg:SetSize(800, 25)  -- Adjust size as needed
		closeBg:SetPoint("BOTTOMLEFT", OptionsFrame, "BOTTOMLEFT", 0, 0)


	-- Create a reset button at the bottom
	local resetButton = CreateFrame("Button", nil, OptionsFrame)
	resetButton:SetSize(80, 25)  -- Adjust size as needed
	resetButton:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0)  -- Adjust position as needed
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
	syncButton:SetSize(80, 25)  -- Adjust size as needed
	syncButton:SetPoint("RIGHT", resetButton, "LEFT", -10, 0)  -- Adjust position as needed
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
	closeButton:SetSize(50, 25)  -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0)  -- Adjust position as needed
	closeButton:SetText("Close")
	local closeButtonText = closeButton:GetFontString()
	closeButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	closeButton:SetNormalFontObject("GameFontHighlight")
	closeButton:SetHighlightFontObject("GameFontNormal")
	closeButton:SetScript("OnClick", function()
		OptionsFrame:Hide()
	end)

	local creditsButton = CreateFrame("Button", nil, OptionsFrame)
	creditsButton:SetSize(60, 25)  -- Adjust size as needed
	creditsButton:SetPoint("LEFT", closeButton, "RIGHT", 10, 0)  -- Adjust position as needed
	creditsButton:SetText("Credits")
	local creditsButtonText = creditsButton:GetFontString()
	creditsButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	creditsButton:SetNormalFontObject("GameFontHighlight")
	creditsButton:SetHighlightFontObject("GameFontNormal")
	creditsButton:SetScript("OnClick", function()
		ProEnchantersCreditsFrame:Show()
	end)

	local colorsButton = CreateFrame("Button", nil, OptionsFrame)
	colorsButton:SetSize(60, 25)  -- Adjust size as needed
	colorsButton:SetPoint("LEFT", creditsButton, "RIGHT", 10, 0)  -- Adjust position as needed
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
	end)

	return OptionsFrame
end

function ProEnchantersCreateCreditsFrame()
    local CreditsFrame = CreateFrame("Frame", "ProEnchantersCreditsFrame", UIParent, "BackdropTemplate")
    CreditsFrame:SetFrameStrata("TOOLTIP")
    CreditsFrame:SetSize(400, 400)  -- Adjust height as needed
    CreditsFrame:SetPoint("TOP", 0, -300)
    CreditsFrame:SetMovable(true)
    CreditsFrame:EnableMouse(true)
    CreditsFrame:RegisterForDrag("LeftButton")
    CreditsFrame:SetScript("OnDragStart", CreditsFrame.StartMoving)
	CreditsFrame:SetScript("OnDragStop", function()
		CreditsFrame:StopMovingOrSizing()
	end)

    CreditsFrame:Hide()

    -- Create a full background texture
    local bgTexture = CreditsFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetColorTexture(unpack(DarkBgOpaque))  -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(400, 375)
    bgTexture:SetPoint("TOP", CreditsFrame, "TOP", 0, -25)

    -- Create a title background
    local titleBg = CreditsFrame:CreateTexture(nil, "OVERLAY")
    titleBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    titleBg:SetSize(400, 25)  -- Adjust size as needed
    titleBg:SetPoint("TOP", CreditsFrame, "TOP", 0, 0)

	local PFP = CreditsFrame:CreateTexture(nil, "OVERLAY")
    --PFP:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
	PFP:SetTexture("Interface\\AddOns\\ProEnchanters\\Media\\PFP.tga")
    PFP:SetSize(128, 128)  -- Adjust size as needed
    PFP:SetPoint("TOP", titleBg, "BOTTOM", 0, -5)

	-- Create a title for Options
	local titleHeader = CreditsFrame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject("GameFontHighlight")
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Credits")
	titleHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local MainCreditsHeader = CreditsFrame:CreateFontString(nil, "OVERLAY")
	MainCreditsHeader:SetFontObject("GameFontHighlight")
	MainCreditsHeader:SetPoint("TOP", PFP, "BOTTOM", 0, -10)
	MainCreditsHeader:SetText("Pro Enchanters add-on created by" .. STEELBLUE .. " EffinOwen" .. ColorClose .. ".\nCome say Hello on discord!")
	MainCreditsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local discordButton = CreateFrame("Button", nil, CreditsFrame)
	discordButton:SetSize(150, 25)  -- Adjust size as needed
	discordButton:SetPoint("TOP", MainCreditsHeader, "BOTTOM", 0, -2)  -- Adjust position as needed
	discordButton:SetText("https://discord.gg/qT6bRk4eUa")
	local discordButtonText = discordButton:GetFontString()
	discordButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	discordButton:SetNormalFontObject("GameFontHighlight")
	discordButton:SetHighlightFontObject("GameFontNormal")
	discordButton:SetScript("OnClick", function()
		ChatFrame1EditBox:Show()
		ChatFrame1EditBox:SetFocus()
		print(SEAGREEN .. "Highlight and hit control+C to copy the discord link and then paste it into any web browser" .. ColorClose)
		ChatFrame1EditBox:SetText("https://discord.gg/qT6bRk4eUa")
	end)

	local SupportersHeader = CreditsFrame:CreateFontString(nil, "OVERLAY")
	SupportersHeader:SetFontObject("GameFontHighlight")
	SupportersHeader:SetPoint("TOP", discordButton, "BOTTOM", 0, -10)
	SupportersHeader:SetText(SEAGREEN .. "~" .. ColorClose .. DARKGOLDENROD .. " Supporters " .. ColorClose .. SEAGREEN .. "~" .. ColorClose)
	SupportersHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 4, "")

	-- Create a close button background
	local CreditsScrollBg = CreditsFrame:CreateTexture(nil, "OVERLAY")
	CreditsScrollBg:SetSize(380, 110)
	CreditsScrollBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	CreditsScrollBg:SetPoint("TOP", SupportersHeader, "TOP", 0, -25)

	local CreditsScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersCreditsScrollFrame", CreditsFrame, "UIPanelScrollFrameTemplate")
	CreditsScrollFrame:SetSize(372, 102)
	CreditsScrollFrame:SetPoint("TOPLEFT", CreditsScrollBg, "TOPLEFT", 4, -4)

	local scrollChild = CreateFrame("Frame", nil, CreditsScrollFrame)
	scrollChild:SetSize(372, 102)  -- Adjust height dynamically based on content
	CreditsScrollFrame:SetScrollChild(scrollChild)

	local scrollBar = CreditsScrollFrame.ScrollBar
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil)  -- Clear existing texture
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
		closeBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
		closeBg:SetSize(400, 25)  -- Adjust size as needed
		closeBg:SetPoint("BOTTOM", CreditsFrame, "BOTTOM", 0, 0)

	local closeButton = CreateFrame("Button", nil, CreditsFrame)
	closeButton:SetSize(50, 25)  -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0)  -- Adjust position as needed
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

	return CreditsFrame
end

function ProEnchantersCreateColorsFrame()
    local ColorsFrame = CreateFrame("Frame", "ProEnchantersColorsFrame", UIParent, "BackdropTemplate")
    ColorsFrame:SetFrameStrata("TOOLTIP")
    ColorsFrame:SetSize(400, 400)  -- Adjust height as needed
    ColorsFrame:SetPoint("TOP", 0, -300)
    ColorsFrame:SetMovable(true)
    ColorsFrame:EnableMouse(true)
    ColorsFrame:RegisterForDrag("LeftButton")
    ColorsFrame:SetScript("OnDragStart", ColorsFrame.StartMoving)
	ColorsFrame:SetScript("OnDragStop", function()
		ColorsFrame:StopMovingOrSizing()
	end)

    ColorsFrame:Hide()

    -- Create a full background texture
    local bgTexture = ColorsFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetColorTexture(unpack(DarkBgOpaque))  -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(400, 375)
    bgTexture:SetPoint("TOP", ColorsFrame, "TOP", 0, -25)

    -- Create a title background
    local titleBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
    titleBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    titleBg:SetSize(400, 25)  -- Adjust size as needed
    titleBg:SetPoint("TOP", ColorsFrame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject("GameFontHighlight")
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Colors Settings")
	titleHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	-- Create Instructions text
	local instructionsHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	instructionsHeader:SetFontObject("GameFontHighlight")
	instructionsHeader:SetPoint("TOP", titleBg, "BOTTOM", 0, -10)
	instructionsHeader:SetText("~How to change colors~\nEach line below has a Red Green Blue value set between 0-255\nChange the numbers and then do a /reload")
		instructionsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	-- Extract Colors from Table
	local headerR, headerG, headerB = unpack(ProEnchantersOptions.Colors.HeaderColor)
	local titleR, titleG, titleB = unpack(ProEnchantersOptions.Colors.TitleColor)
	local lightR, lightG, lightB = unpack(ProEnchantersOptions.Colors.LightBgColor)
	local darkR, darkG, darkB = unpack(ProEnchantersOptions.Colors.DarkBgColor)
	local greyR, greyG, greyB = unpack(ProEnchantersOptions.Colors.GreyedColor)

	local function RGBToWoWColorCode(red, green, blue)
		-- Ensure alpha is set to FF for fully opaque
		local alpha = "FF"
		local red = red*255
		local green = green*255
		local blue = blue*255
		
		-- Convert RGB values to a hexadecimal string
		local colorCode = string.format("|c%s%02x%02x%02x", alpha, red, green, blue)
		
		return colorCode
	end

	local colorsExamples = ColorsFrame:CreateTexture(nil, "OVERLAY")
	colorsExamples:SetColorTexture(unpack(TitleOpaque))  -- Set RGBA values for your preferred color and alpha
	colorsExamples:SetSize(70, 150)  -- Adjust size as needed
	colorsExamples:SetPoint("TOPLEFT", titleHeader, "TOPLEFT", 240, -60)

	local mainColorsExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	mainColorsExample:SetFontObject("GameFontHighlight")
	mainColorsExample:SetPoint("TOPLEFT", colorsExamples, "TOPLEFT", 6, -8)
	local mainColorsHex = RGBToWoWColorCode(headerR, headerG, headerB)
	mainColorsExample:SetText(mainColorsHex .. "EXAMPLE" .. ColorClose)
	mainColorsExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local lightColorsExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	lightColorsExample:SetFontObject("GameFontHighlight")
	lightColorsExample:SetPoint("TOP", mainColorsExample, "BOTTOM", 0, -25)
	local lightColorsHex = RGBToWoWColorCode(lightR, lightG, lightB)
	lightColorsExample:SetText(lightColorsHex .. "EXAMPLE" .. ColorClose)
	lightColorsExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local darkColorsExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	darkColorsExample:SetFontObject("GameFontHighlight")
	darkColorsExample:SetPoint("TOP", lightColorsExample, "BOTTOM", 0, -25)
	local darkColorsHex = RGBToWoWColorCode(darkR, darkG, darkB)
	darkColorsExample:SetText(darkColorsHex .. "EXAMPLE" .. ColorClose)
	darkColorsExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

	local greyColorsExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	greyColorsExample:SetFontObject("GameFontHighlight")
	greyColorsExample:SetPoint("TOP", darkColorsExample, "BOTTOM", 0, -25)
	local greyColorsHex = RGBToWoWColorCode(greyR, greyG, GetParryChance())
	greyColorsExample:SetText(greyColorsHex .. "EXAMPLE" .. ColorClose)
	greyColorsExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")


	-- Color Settings start
	local mainColorsHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	mainColorsHeader:SetFontObject("GameFontHighlight")
	mainColorsHeader:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 70, -80)
	mainColorsHeader:SetText("Main Colors")
	mainColorsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local mainColorsRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	mainColorsRBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	mainColorsRBg:SetSize(34, 24)  -- Adjust size as needed
	mainColorsRBg:SetPoint("LEFT", mainColorsHeader, "RIGHT", 10, 0)

	local mainColorsR = CreateFrame("EditBox", nil, ColorsFrame)
	mainColorsR:SetSize(30, 20)
	mainColorsR:SetPoint("LEFT", mainColorsHeader, "RIGHT", 14, 0)
	mainColorsR:SetAutoFocus(false)
	mainColorsR:SetNumeric(true)
	mainColorsR:SetMaxLetters(3)
	mainColorsR:SetMultiLine(false)
	mainColorsR:EnableMouse(true)
    mainColorsR:EnableKeyboard(true)
	mainColorsR:SetFontObject("GameFontHighlight")
	mainColorsR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	mainColorsR:SetText(tostring(headerR*255))
	mainColorsR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	mainColorsR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	mainColorsR:SetScript("OnTextChanged", function()
		local new = tonumber(mainColorsR:GetText())
		if new == nil then
			headerR = 0
		elseif new > 254 then
			headerR = 1
		else
			headerR = new/255
		end
		ProEnchantersOptions.Colors.HeaderColor = {headerR, headerG, headerB}
		local mainColorsHex = RGBToWoWColorCode(headerR, headerG, headerB)
		mainColorsExample:SetText(mainColorsHex .. "EXAMPLE" .. ColorClose)
	end)

	local mainColorsGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	mainColorsGBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	mainColorsGBg:SetSize(34, 24)  -- Adjust size as needed
	mainColorsGBg:SetPoint("LEFT", mainColorsR, "RIGHT", 10, 0)

	local mainColorsG = CreateFrame("EditBox", nil, ColorsFrame)
	mainColorsG:SetSize(30, 20)
	mainColorsG:SetPoint("LEFT", mainColorsR, "RIGHT", 14, 0)
	mainColorsG:SetAutoFocus(false)
	mainColorsG:SetNumeric(true)
	mainColorsG:SetMaxLetters(3)
	mainColorsG:SetMultiLine(false)
	mainColorsG:EnableMouse(true)
    mainColorsG:EnableKeyboard(true)
	mainColorsG:SetFontObject("GameFontHighlight")
	mainColorsG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	mainColorsG:SetText(tostring(headerG*255))
	mainColorsG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	mainColorsG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	mainColorsG:SetScript("OnTextChanged", function()
		local new = tonumber(mainColorsG:GetText())
		if new == nil then
			headerG = 0
		elseif new > 254 then
			headerG = 1
		else
			headerG = new/255
		end
		ProEnchantersOptions.Colors.HeaderColor = {headerR, headerG, headerB}
		local mainColorsHex = RGBToWoWColorCode(headerR, headerG, headerB)
		mainColorsExample:SetText(mainColorsHex .. "EXAMPLE" .. ColorClose)
	end)

	local mainColorsBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	mainColorsBBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	mainColorsBBg:SetSize(34, 24)  -- Adjust size as needed
	mainColorsBBg:SetPoint("LEFT", mainColorsG, "RIGHT", 10, 0)

	local mainColorsB = CreateFrame("EditBox", nil, ColorsFrame)
	mainColorsB:SetSize(30, 20)
	mainColorsB:SetPoint("LEFT", mainColorsG, "RIGHT", 14, 0)
	mainColorsB:SetAutoFocus(false)
	mainColorsB:SetNumeric(true)
	mainColorsB:SetMaxLetters(3)
	mainColorsB:SetMultiLine(false)
	mainColorsB:EnableMouse(true)
    mainColorsB:EnableKeyboard(true)
	mainColorsB:SetFontObject("GameFontHighlight")
	mainColorsB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	mainColorsB:SetText(tostring(headerB*255))
	mainColorsB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	mainColorsB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	mainColorsB:SetScript("OnTextChanged", function()
		local new = tonumber(mainColorsB:GetText())
		if new == nil then
			headerB = 0
		elseif new > 254 then
			headerB = 1
		else
			headerB = new/255
		end
		ProEnchantersOptions.Colors.HeaderColor = {headerR, headerG, headerB}
		local mainColorsHex = RGBToWoWColorCode(headerR, headerG, headerB)
		mainColorsExample:SetText(mainColorsHex .. "EXAMPLE" .. ColorClose)
	end)

	-- Color Settings End
	-- Color Settings start
	local lightColorsRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	lightColorsRBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	lightColorsRBg:SetSize(34, 24)  -- Adjust size as needed
	lightColorsRBg:SetPoint("TOP", mainColorsR, "BOTTOM", -2, -15)
	
	local lightColorsR = CreateFrame("EditBox", nil, ColorsFrame)
	lightColorsR:SetSize(30, 20)
	lightColorsR:SetPoint("TOP", mainColorsR, "BOTTOM", 0, -20)
	lightColorsR:SetAutoFocus(false)
	lightColorsR:SetNumeric(true)
	lightColorsR:SetMaxLetters(3)
	lightColorsR:SetMultiLine(false)
	lightColorsR:EnableMouse(true)
	lightColorsR:EnableKeyboard(true)
	lightColorsR:SetFontObject("GameFontHighlight")
	lightColorsR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	lightColorsR:SetText(tostring(lightR*255))
	lightColorsR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	lightColorsR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	lightColorsR:SetScript("OnTextChanged", function()
		local new = tonumber(lightColorsR:GetText())
		if new == nil then
			lightR = 0
		elseif new > 254 then
			lightR = 1
		else
			lightR = new/255
		end
		ProEnchantersOptions.Colors.LightBgColor = {lightR, lightG, lightB}
		local lightColorsHex = RGBToWoWColorCode(lightR, lightG, lightB)
		lightColorsExample:SetText(lightColorsHex .. "EXAMPLE" .. ColorClose)
	end)
	
	local lightColorsHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	lightColorsHeader:SetFontObject("GameFontHighlight")
	lightColorsHeader:SetPoint("RIGHT", lightColorsR, "LEFT", -15, 0)
	lightColorsHeader:SetText("Scroll Bar Backgrounds")
	lightColorsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	
	local lightColorsGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	lightColorsGBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	lightColorsGBg:SetSize(34, 24)  -- Adjust size as needed
	lightColorsGBg:SetPoint("LEFT", lightColorsRBg, "RIGHT", 10, 0)
	
	local lightColorsG = CreateFrame("EditBox", nil, ColorsFrame)
	lightColorsG:SetSize(30, 20)
	lightColorsG:SetPoint("LEFT", lightColorsR, "RIGHT", 14, 0)
	lightColorsG:SetAutoFocus(false)
	lightColorsG:SetNumeric(true)
	lightColorsG:SetMaxLetters(3)
	lightColorsG:SetMultiLine(false)
	lightColorsG:EnableMouse(true)
	lightColorsG:EnableKeyboard(true)
	lightColorsG:SetFontObject("GameFontHighlight")
	lightColorsG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	lightColorsG:SetText(tostring(lightG*255))
	lightColorsG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	lightColorsG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	lightColorsG:SetScript("OnTextChanged", function()
		local new = tonumber(lightColorsG:GetText())
		if new == nil then
			lightG = 0
		elseif new > 254 then
			lightG = 1
		else
			lightG = new/255
		end
		ProEnchantersOptions.Colors.LightBgColor = {lightR, lightG, lightB}
		local lightColorsHex = RGBToWoWColorCode(lightR, lightG, lightB)
		lightColorsExample:SetText(lightColorsHex .. "EXAMPLE" .. ColorClose)
	end)
	
	local lightColorsBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	lightColorsBBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	lightColorsBBg:SetSize(34, 24)  -- Adjust size as needed
	lightColorsBBg:SetPoint("LEFT", lightColorsGBg, "RIGHT", 10, 0)
	
	local lightColorsB = CreateFrame("EditBox", nil, ColorsFrame)
	lightColorsB:SetSize(30, 20)
	lightColorsB:SetPoint("LEFT", lightColorsG, "RIGHT", 14, 0)
	lightColorsB:SetAutoFocus(false)
	lightColorsB:SetNumeric(true)
	lightColorsB:SetMaxLetters(3)
	lightColorsB:SetMultiLine(false)
	lightColorsB:EnableMouse(true)
	lightColorsB:EnableKeyboard(true)
	lightColorsB:SetFontObject("GameFontHighlight")
	lightColorsB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	lightColorsB:SetText(tostring(lightB*255))
	lightColorsB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	lightColorsB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	lightColorsB:SetScript("OnTextChanged", function()
		local new = tonumber(lightColorsB:GetText())
		if new == nil then
			lightB = 0
		elseif new > 254 then
			lightB = 1
		else
			lightB = new/255
		end
		ProEnchantersOptions.Colors.LightBgColor = {lightR, lightG, lightB}
		local lightColorsHex = RGBToWoWColorCode(lightR, lightG, lightB)
		lightColorsExample:SetText(lightColorsHex .. "EXAMPLE" .. ColorClose)
	end)

		-- Color Settings start
local darkColorsRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
darkColorsRBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
darkColorsRBg:SetSize(34, 24)  -- Adjust size as needed
darkColorsRBg:SetPoint("TOP", lightColorsR, "BOTTOM", -2, -15)

local darkColorsR = CreateFrame("EditBox", nil, ColorsFrame)
darkColorsR:SetSize(30, 20)
darkColorsR:SetPoint("TOP", lightColorsR, "BOTTOM", 0, -20)
darkColorsR:SetAutoFocus(false)
darkColorsR:SetNumeric(true)
darkColorsR:SetMaxLetters(3)
darkColorsR:SetMultiLine(false)
darkColorsR:EnableMouse(true)
darkColorsR:EnableKeyboard(true)
darkColorsR:SetFontObject("GameFontHighlight")
darkColorsR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
darkColorsR:SetText(tostring(darkR*255))
darkColorsR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
darkColorsR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
darkColorsR:SetScript("OnTextChanged", function()
	local new = tonumber(darkColorsR:GetText())
	if new == nil then
		darkR = 0
	elseif new > 254 then
		darkR = 1
	else
		darkR = new/255
	end
	ProEnchantersOptions.Colors.DarkBgColor = {darkR, darkG, darkB}
	local darkColorsHex = RGBToWoWColorCode(darkR, darkG, darkB)
	darkColorsExample:SetText(darkColorsHex .. "EXAMPLE" .. ColorClose)
end)

local darkColorsHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
darkColorsHeader:SetFontObject("GameFontHighlight")
darkColorsHeader:SetPoint("RIGHT", darkColorsR, "LEFT", -15, 0)
darkColorsHeader:SetText("Accent Colors")
darkColorsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

local darkColorsGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
darkColorsGBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
darkColorsGBg:SetSize(34, 24)  -- Adjust size as needed
darkColorsGBg:SetPoint("LEFT", darkColorsRBg, "RIGHT", 10, 0)

local darkColorsG = CreateFrame("EditBox", nil, ColorsFrame)
darkColorsG:SetSize(30, 20)
darkColorsG:SetPoint("LEFT", darkColorsR, "RIGHT", 14, 0)
darkColorsG:SetAutoFocus(false)
darkColorsG:SetNumeric(true)
darkColorsG:SetMaxLetters(3)
darkColorsG:SetMultiLine(false)
darkColorsG:EnableMouse(true)
darkColorsG:EnableKeyboard(true)
darkColorsG:SetFontObject("GameFontHighlight")
darkColorsG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
darkColorsG:SetText(tostring(darkG*255))
darkColorsG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
darkColorsG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
darkColorsG:SetScript("OnTextChanged", function()
	local new = tonumber(darkColorsG:GetText())
	if new == nil then
		darkG = 0
	elseif new > 254 then
		darkG = 1
	else
		darkG = new/255
	end
	ProEnchantersOptions.Colors.DarkBgColor = {darkR, darkG, darkB}
	local darkColorsHex = RGBToWoWColorCode(darkR, darkG, darkB)
	darkColorsExample:SetText(darkColorsHex .. "EXAMPLE" .. ColorClose)
end)

local darkColorsBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
darkColorsBBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
darkColorsBBg:SetSize(34, 24)  -- Adjust size as needed
darkColorsBBg:SetPoint("LEFT", darkColorsGBg, "RIGHT", 10, 0)

local darkColorsB = CreateFrame("EditBox", nil, ColorsFrame)
darkColorsB:SetSize(30, 20)
darkColorsB:SetPoint("LEFT", darkColorsG, "RIGHT", 14, 0)
darkColorsB:SetAutoFocus(false)
darkColorsB:SetNumeric(true)
darkColorsB:SetMaxLetters(3)
darkColorsB:SetMultiLine(false)
darkColorsB:EnableMouse(true)
darkColorsB:EnableKeyboard(true)
darkColorsB:SetFontObject("GameFontHighlight")
darkColorsB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
darkColorsB:SetText(tostring(darkB*255))
darkColorsB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
darkColorsB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
darkColorsB:SetScript("OnTextChanged", function()
	local new = tonumber(darkColorsB:GetText())
	if new == nil then
		darkB = 0
	elseif new > 254 then
		darkB = 1
	else
		darkB = new/255
	end
	ProEnchantersOptions.Colors.DarkBgColor = {darkR, darkG, darkB}
	local darkColorsHex = RGBToWoWColorCode(darkR, darkG, darkB)
	darkColorsExample:SetText(darkColorsHex .. "EXAMPLE" .. ColorClose)
end)

-- Color Settings start
local greyColorsRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
greyColorsRBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
greyColorsRBg:SetSize(34, 24)  -- Adjust size as needed
greyColorsRBg:SetPoint("TOP", darkColorsR, "BOTTOM", -2, -15)

local greyColorsR = CreateFrame("EditBox", nil, ColorsFrame)
greyColorsR:SetSize(30, 20)
greyColorsR:SetPoint("TOP", darkColorsR, "BOTTOM", 0, -20)
greyColorsR:SetAutoFocus(false)
greyColorsR:SetNumeric(true)
greyColorsR:SetMaxLetters(3)
greyColorsR:SetMultiLine(false)
greyColorsR:EnableMouse(true)
greyColorsR:EnableKeyboard(true)
greyColorsR:SetFontObject("GameFontHighlight")
greyColorsR:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
greyColorsR:SetText(tostring(greyR*255))
greyColorsR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
greyColorsR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
greyColorsR:SetScript("OnTextChanged", function()
	local new = tonumber(greyColorsR:GetText())
	if new == nil then
		greyR = 0
	elseif new > 254 then
		greyR = 1
	else
		greyR = new/255
	end
	ProEnchantersOptions.Colors.GreyBgColor = {greyR, greyG, greyB}
	local greyColorsHex = RGBToWoWColorCode(greyR, greyG, greyB)
	greyColorsExample:SetText(greyColorsHex .. "EXAMPLE" .. ColorClose)
end)

local greyColorsHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
greyColorsHeader:SetFontObject("GameFontHighlight")
greyColorsHeader:SetPoint("RIGHT", greyColorsR, "LEFT", -15, 0)
greyColorsHeader:SetText("Disabled Buttons Color")
greyColorsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

local greyColorsGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
greyColorsGBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
greyColorsGBg:SetSize(34, 24)  -- Adjust size as needed
greyColorsGBg:SetPoint("LEFT", greyColorsRBg, "RIGHT", 10, 0)

local greyColorsG = CreateFrame("EditBox", nil, ColorsFrame)
greyColorsG:SetSize(30, 20)
greyColorsG:SetPoint("LEFT", greyColorsR, "RIGHT", 14, 0)
greyColorsG:SetAutoFocus(false)
greyColorsG:SetNumeric(true)
greyColorsG:SetMaxLetters(3)
greyColorsG:SetMultiLine(false)
greyColorsG:EnableMouse(true)
greyColorsG:EnableKeyboard(true)
greyColorsG:SetFontObject("GameFontHighlight")
greyColorsG:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
greyColorsG:SetText(tostring(greyG*255))
greyColorsG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
greyColorsG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
greyColorsG:SetScript("OnTextChanged", function()
	local new = tonumber(greyColorsG:GetText())
	if new == nil then
		greyG = 0
	elseif new > 254 then
		greyG = 1
	else
		greyG = new/255
	end
	ProEnchantersOptions.Colors.GreyBgColor = {greyR, greyG, greyB}
	local greyColorsHex = RGBToWoWColorCode(greyR, greyG, greyB)
	greyColorsExample:SetText(greyColorsHex .. "EXAMPLE" .. ColorClose)
end)

local greyColorsBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
greyColorsBBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
greyColorsBBg:SetSize(34, 24)  -- Adjust size as needed
greyColorsBBg:SetPoint("LEFT", greyColorsGBg, "RIGHT", 10, 0)

local greyColorsB = CreateFrame("EditBox", nil, ColorsFrame)
greyColorsB:SetSize(30, 20)
greyColorsB:SetPoint("LEFT", greyColorsG, "RIGHT", 14, 0)
greyColorsB:SetAutoFocus(false)
greyColorsB:SetNumeric(true)
greyColorsB:SetMaxLetters(3)
greyColorsB:SetMultiLine(false)
greyColorsB:EnableMouse(true)
greyColorsB:EnableKeyboard(true)
greyColorsB:SetFontObject("GameFontHighlight")
greyColorsB:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
greyColorsB:SetText(tostring(greyB*255))
greyColorsB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
greyColorsB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
greyColorsB:SetScript("OnTextChanged", function()
	local new = tonumber(greyColorsB:GetText())
	if new == nil then
		greyB = 0
	elseif new > 254 then
		greyB = 1
	else
		greyB = new/255
	end
	ProEnchantersOptions.Colors.GreyBgColor = {greyR, greyG, greyB}
	local greyColorsHex = RGBToWoWColorCode(greyR, greyG, greyB)
	greyColorsExample:SetText(greyColorsHex .. "EXAMPLE" .. ColorClose)
end)

	-- Create a close button
	local closeBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	closeBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
	closeBg:SetSize(400, 25)  -- Adjust size as needed
	closeBg:SetPoint("BOTTOM", ColorsFrame, "BOTTOM", 0, 0)

	local closeButton = CreateFrame("Button", nil, ColorsFrame)
	closeButton:SetSize(50, 25)  -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0)  -- Adjust position as needed
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
	resetButton:SetSize(50, 25)  -- Adjust size as needed
	resetButton:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0)  -- Adjust position as needed
	resetButton:SetText("Reset")
	local resetButtonText = resetButton:GetFontString()
	resetButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	resetButton:SetNormalFontObject("GameFontHighlight")
	resetButton:SetHighlightFontObject("GameFontNormal")
	resetButton:SetScript("OnClick", function()
		mainColorsR:SetText(tostring(22))
		mainColorsG:SetText(tostring(26))
		mainColorsB:SetText(tostring(48))
		lightColorsR:SetText(tostring(240))
		lightColorsG:SetText(tostring(236))
		lightColorsB:SetText(tostring(229))
		darkColorsR:SetText(tostring(49))
		darkColorsG:SetText(tostring(48))
		darkColorsB:SetText(tostring(77))
		greyColorsR:SetText(tostring(71))
		greyColorsG:SetText(tostring(71))
		greyColorsB:SetText(tostring(71))
	end)

	-- Help Reminder
	local helpReminderHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject("GameFontGreen")
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 6)
	helpReminderHeader:SetText(STEELBLUE .. "Thanks for using Pro Enchanters!" .. ColorClose)
	helpReminderHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	return ColorsFrame
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
    TriggersFrame:SetSize(800, 350)  -- Adjust height as needed
    TriggersFrame:SetPoint("TOP", 0, -300)
    TriggersFrame:SetMovable(true)
    TriggersFrame:EnableMouse(true)
    TriggersFrame:RegisterForDrag("LeftButton")
    TriggersFrame:SetScript("OnDragStart", TriggersFrame.StartMoving)
	TriggersFrame:SetScript("OnDragStop", function()
		TriggersFrame:StopMovingOrSizing()
	end)

    TriggersFrame:Hide()

    -- Create a full background texture
    local bgTexture = TriggersFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetColorTexture(unpack(DarkBgOpaque))  -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(800, 325)
    bgTexture:SetPoint("TOP", TriggersFrame, "TOP", 0, -25)

    -- Create a title background
    local titleBg = TriggersFrame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    titleBg:SetSize(800, 25)  -- Adjust size as needed
    titleBg:SetPoint("TOP", TriggersFrame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = TriggersFrame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject("GameFontHighlight")
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Triggers and Filters")
	titleHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local InstructionsHeader = TriggersFrame:CreateFontString(nil, "OVERLAY")
	InstructionsHeader:SetFontObject("GameFontHighlight")
	InstructionsHeader:SetPoint("TOPLEFT", titleBg, "TOPLEFT", 90, -30)
	InstructionsHeader:SetText("Add words below separated by commas to enable new trigger words for the auto invites or words that will filter others messages.\nYou can also set players names in the Filter section to filter that player from triggering the auto invite.\nMake sure words or phrases to filter are in lower case and player names start with a Capital letter.")
	InstructionsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local FilteredWordsHeader = TriggersFrame:CreateFontString(nil, "OVERLAY")
	FilteredWordsHeader:SetFontObject("GameFontHighlight")
	FilteredWordsHeader:SetPoint("TOPLEFT", InstructionsHeader, "TOPLEFT", -70, -55)
	FilteredWordsHeader:SetText("Filtered Words:")
	FilteredWordsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	-- Create a close button background
	local FilteredScrollBg = TriggersFrame:CreateTexture(nil, "OVERLAY")
	FilteredScrollBg:SetSize(610, 80)
	FilteredScrollBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	FilteredScrollBg:SetPoint("TOPLEFT", FilteredWordsHeader, "TOPRIGHT", 15, 5)

	local FilteredScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersFilteredScrollFrame", TriggersFrame, "UIPanelScrollFrameTemplate")
	FilteredScrollFrame:SetSize(602, 72)
	FilteredScrollFrame:SetPoint("TOPLEFT", FilteredScrollBg, "TOPLEFT", 4, -4)

	local scrollChild = CreateFrame("Frame", nil, FilteredScrollFrame)
	scrollChild:SetSize(602, 70)  -- Adjust height dynamically based on content
	FilteredScrollFrame:SetScrollChild(scrollChild)

	local scrollBar = FilteredScrollFrame.ScrollBar
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil)  -- Clear existing texture
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
	TriggerWordsHeader:SetFontObject("GameFontHighlight")
	TriggerWordsHeader:SetPoint("TOPLEFT", InstructionsHeader, "TOPLEFT", -70, -155)
	TriggerWordsHeader:SetText("Trigger Words:")
	TriggerWordsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	
	-- Create a close button background
	local TriggerScrollBg = TriggersFrame:CreateTexture(nil, "OVERLAY")
	TriggerScrollBg:SetSize(610, 60)
	TriggerScrollBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	TriggerScrollBg:SetPoint("TOP", FilteredScrollFrame, "BOTTOM", 0, -25)

	local TriggerScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersFilteredScrollFrame", TriggersFrame, "UIPanelScrollFrameTemplate")
	TriggerScrollFrame:SetSize(602, 52)
	TriggerScrollFrame:SetPoint("TOPLEFT", TriggerScrollBg, "TOPLEFT", 4, -4)

	local scrollChild2 = CreateFrame("Frame", nil, TriggerScrollFrame)
	scrollChild2:SetSize(602, 50)  -- Adjust height dynamically based on content
	TriggerScrollFrame:SetScrollChild(scrollChild2)

	local scrollBar2 = TriggerScrollFrame.ScrollBar
	local thumbTexture2 = scrollBar2:GetThumbTexture()
	thumbTexture2:SetTexture(nil)  -- Clear existing texture
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
	InvWordsHeader:SetFontObject("GameFontHighlight")
	InvWordsHeader:SetPoint("TOPLEFT", InstructionsHeader, "TOPLEFT", -70, -235)
	InvWordsHeader:SetText("Inv Words:")
	InvWordsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
	
	-- Create a close button background
	local InvScrollBg = TriggersFrame:CreateTexture(nil, "OVERLAY")
	InvScrollBg:SetSize(610, 40)
	InvScrollBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	InvScrollBg:SetPoint("TOP", TriggerScrollFrame, "BOTTOM", 0, -25)

	local InvScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersInvScrollFrame", TriggersFrame, "UIPanelScrollFrameTemplate")
	InvScrollFrame:SetSize(602, 32)
	InvScrollFrame:SetPoint("TOPLEFT", InvScrollBg, "TOPLEFT", 4, -4)

	local scrollChild3 = CreateFrame("Frame", nil, InvScrollFrame)
	scrollChild3:SetSize(602, 30)  -- Adjust height dynamically based on content
	InvScrollFrame:SetScrollChild(scrollChild3)

	local scrollBar2 = InvScrollFrame.ScrollBar
	local thumbTexture2 = scrollBar2:GetThumbTexture()
	thumbTexture2:SetTexture(nil)  -- Clear existing texture
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
		closeBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
		closeBg:SetSize(800, 25)  -- Adjust size as needed
		closeBg:SetPoint("BOTTOMLEFT", TriggersFrame, "BOTTOMLEFT", 0, 0)


	-- Create a reset button at the bottom
	local resetButton2 = CreateFrame("Button", nil, TriggersFrame)
	resetButton2:SetSize(150, 25)  -- Adjust size as needed
	resetButton2:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0)  -- Adjust position as needed
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
	closeButton2:SetSize(50, 25)  -- Adjust size as needed
	closeButton2:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0)  -- Adjust position as needed
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
	helpReminderHeader:SetFontObject("GameFontGreen")
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 5)
	helpReminderHeader:SetText(STEELBLUE .. "Use /pehelp for more info" .. ColorClose)
	helpReminderHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

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
    frame:SetSize(800, 350)  -- Adjust height as needed
    frame:SetPoint("TOP", 0, -300)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
	end)

    frame:Hide()

    -- Create a full background texture
    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetColorTexture(unpack(DarkBgOpaque))  -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(800, 325)
    bgTexture:SetPoint("TOP", frame, "TOP", 0, -25)

    -- Create a title background
    local titleBg = frame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    titleBg:SetSize(800, 25)  -- Adjust size as needed
    titleBg:SetPoint("TOP", frame, "TOP", 0, 0)

	-- Create a title for Options
	local titleHeader = frame:CreateFontString(nil, "OVERLAY")
	titleHeader:SetFontObject("GameFontHighlight")
	titleHeader:SetPoint("TOP", titleBg, "TOP", 0, -8)
	titleHeader:SetText("Pro Enchanters Whisper Trigger Commands")
	titleHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")


	-- Scroll frame setup...
    local WhisperTriggerScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersOptionsScrollFrame", frame, "UIPanelScrollFrameTemplate")
    WhisperTriggerScrollFrame:SetSize(775, 300)
    WhisperTriggerScrollFrame:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 0, 0)

	--Create a scroll background
	local scrollBg = frame:CreateTexture(nil, "BACKGROUND")
	scrollBg:SetColorTexture(unpack(LightBgTrans))  -- Set RGBA values for your preferred color and alpha
	scrollBg:SetSize(17, 300)  -- Adjust size as needed
	scrollBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -25)
	
	-- Access the Scroll Bar
	local scrollBar = WhisperTriggerScrollFrame.ScrollBar

	-- Customize Thumb Texture
local thumbTexture = scrollBar:GetThumbTexture()
thumbTexture:SetTexture(nil)  -- Clear existing texture
thumbTexture:SetColorTexture(unpack(HeaderOpaque))
thumbTexture:SetSize(15, 15)
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
upButton:GetNormalTexture():SetColorTexture(unpack(DarkBgOpaque)) -- Replace RGBA values as needed
upButton:GetPushedTexture():SetColorTexture(unpack(LightBgOpaque)) -- Replace RGBA values as needed
upButton:GetDisabledTexture():SetColorTexture(unpack(DarkBgTrans)) -- Replace RGBA values as needed
upButton:GetHighlightTexture():SetColorTexture(unpack(LightBgTrans)) -- Replace RGBA values as needed

-- Repeat for Scroll Down Button
local downButton = scrollBar.ScrollDownButton

-- Clear existing textures
downButton:GetNormalTexture():SetTexture(nil)
downButton:GetPushedTexture():SetTexture(nil)
downButton:GetDisabledTexture():SetTexture(nil)
downButton:GetHighlightTexture():SetTexture(nil)

-- Set colors
downButton:GetNormalTexture():SetColorTexture(unpack(DarkBgOpaque)) -- Adjust colors as needed
downButton:GetPushedTexture():SetColorTexture(unpack(LightBgOpaque)) -- Adjust colors as needed
downButton:GetDisabledTexture():SetColorTexture(unpack(DarkBgTrans)) -- Adjust colors as needed
downButton:GetHighlightTexture():SetColorTexture(unpack(LightBgTrans)) -- Adjust colors as needed

local upButtonText = upButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
upButtonText:SetText("-") -- Set the text for the up button
upButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
upButtonText:SetPoint("CENTER", upButton, "CENTER", 0, 0) -- Adjust position as needed

local downButtonText = downButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
downButtonText:SetText("-") -- Set the text for the down button
downButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
downButtonText:SetPoint("CENTER", downButton, "CENTER", 0, 0) -- Adjust position as needed


    -- Scroll child frame where elements are actually placed
    local ScrollChild = CreateFrame("Frame")
    ScrollChild:SetSize(800, 300)  -- Adjust height based on the number of elements
    WhisperTriggerScrollFrame:SetScrollChild(ScrollChild)

-- Scroll child items below

-- Create a title for Options

local InstructionsHeader = frame:CreateFontString(nil, "OVERLAY")
InstructionsHeader:SetFontObject("GameFontHighlight")
InstructionsHeader:SetPoint("TOP", ScrollChild, "TOP", 0, -10)
InstructionsHeader:SetText(DARKORANGE .. "Add !commands and their responses below, hit enter on a line to save the line.\nBoth lines must have information. Commands do have to start with a ! to work.\nResponses need to be under 250 characters to fit within WoW's character limitations, character counter is on the right beside each line.\nYou can include item links in your message by adding the items ID encased in [], example: [11083] will return as Soul Dust (max 5 item links in a message)\nLook up item ID's on wowhead, soul dust as an example: https://www.wowhead.com/classic/item=" .. ColorClose .. YELLOWGREEN .. 11083 .. ColorClose .. DARKORANGE .. "/soul-dust\nTo modify a command, change either its command box and hit enter or its response box and hit enter.\nTo delete a line, delete BOTH fields before hitting enter, blank commands with blank responses are removed.\nPlayer's can also whisper you for the required mats by whispering you the !enchant, it must match the enchant name exactly.\nExample - Player whispers: !enchant boots - stamina" .. ColorClose)
InstructionsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

-- Create a reset button at the bottom
local hideButton = CreateFrame("Button", nil, frame)
hideButton:SetSize(100, 25)  -- Adjust size as needed
hideButton:SetPoint("TOP", InstructionsHeader, "BOTTOM", 0, -2)  -- Adjust position as needed
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
		InstructionsHeader:SetText(DARKORANGE .. "Add !commands and their responses below, hit enter on a line to save the line.\nBoth lines must have information. Commands do have to start with a ! to work.\nResponses need to be under 250 characters to fit within WoW's character limitations, character counter is on the right beside each line.\nYou can include item links in your message by adding the items ID encased in [], example: [11083] will return as Soul Dust (max 5 item links in a message)\nLook up item ID's on wowhead, soul dust as an example: https://www.wowhead.com/classic/item=" .. ColorClose .. YELLOWGREEN .. 11083 .. ColorClose .. DARKORANGE .. "/soul-dust\nTo modify a command, change either its command box and hit enter or its response box and hit enter.\nTo delete a line, delete BOTH fields before hitting enter, blank commands with blank responses are removed.\nPlayer's can also whisper you for the required mats by whispering you the !enchant, it must match the enchant name exactly.\nExample - Player whispers: !enchant boots - stamina" .. ColorClose)
	elseif hideButtonStatus == false then
		hideButtonStatus = true
		hideButton:SetText(GRAY .. "Show Instructions" .. ColorClose)
		InstructionsHeader:SetText(DARKORANGE .. "Add !commands and their responses below, hit enter on a line to save the line." .. ColorClose)
	end
end)


local scrollHeader = ScrollChild:CreateFontString(nil, "OVERLAY")
scrollHeader:SetFontObject("GameFontHighlight")
scrollHeader:SetPoint("TOP", hideButton, "BOTTOM", -230, -5)
scrollHeader:SetText("Enter new Command name and Command response")
scrollHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

-- Initialize the buttons table if it doesn't exist
if not frame.fieldscmd then
	frame.fieldscmd = {}
	frame.fieldsmsg = {}
end

local wtYvalue = wtYvalue or 0


local function createWhisperTriggers()
	RemoveWhisperTriggers()
	wtYvalue = -25
	--[[if frame.fieldscmd then
		for _, button in ipairs(frame.fieldscmd) do
			button:Hide()
			button:SetParent(nil)
			button:ClearAllPoints()
		end
		for _, buttonBg in ipairs(frame.fieldsmsg) do
			buttonBg:Hide()
			buttonBg:SetParent(nil)
			buttonBg:ClearAllPoints()
		end
		wipe(frame.fieldscmd)  -- Clear the table
		wipe(frame.fieldsmsg)
	end]]
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
			if msgLength >= 251 then
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
							ProEnchantersOptions.whispertriggers[i] = {[newcmdBox] = newmsgBox}
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
							ProEnchantersOptions.whispertriggers[i] = {[newcmdBox] = newmsgBox}
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
			table.insert(ProEnchantersOptions.whispertriggers, {[newcmdBox] = newmsgBox})
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
			table.insert(ProEnchantersOptions.whispertriggers, {[newcmdBox] = newmsgBox})
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
existingHeader:SetFontObject("GameFontHighlight")
existingHeader:SetPoint("TOPLEFT", cmdBoxMain, "BOTTOMLEFT", -10, -15)
existingHeader:SetText("Existing Commands")
existingHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

createWhisperTriggers()

	-- Create a close button background
		local closeBg = frame:CreateTexture(nil, "OVERLAY")
		closeBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
		closeBg:SetSize(800, 25)  -- Adjust size as needed
		closeBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)


	-- Create a reset button at the bottom
	local clearAllButton = CreateFrame("Button", nil, frame)
	clearAllButton:SetSize(100, 25)  -- Adjust size as needed
	clearAllButton:SetPoint("BOTTOMRIGHT", closeBg, "BOTTOMRIGHT", -10, 0)  -- Adjust position as needed
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


	local closeButton = CreateFrame("Button", nil, frame)
	closeButton:SetSize(50, 25)  -- Adjust size as needed
	closeButton:SetPoint("BOTTOMLEFT", closeBg, "BOTTOMLEFT", 10, 0)  -- Adjust position as needed
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
	helpReminderHeader:SetFontObject("GameFontGreen")
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 5)
	helpReminderHeader:SetText(STEELBLUE .. "Use /pehelp for more info" .. ColorClose)
	helpReminderHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	-- frame On Show Script
	frame:SetScript("OnShow", function()
		-- Stuff
	end)

	frame:SetScript("OnHide", function()
		-- Stuff
	end)

	return frame
end
-- Whisper Triggers Frame End

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
function CreateCusWorkOrder(customerName)
	local customerName = string.lower(customerName)
	--customerName = string.utf8upper2(string.sub(customerName2, 1, 1)) .. string.sub(customerName2, 2)
	if customerName == "" or customerName == nil then
		print(RED .. "Invalid customer name" .. ColorClose)
		return
	end
	local frameID = #WorkOrderFrames + 1
    local framename = "CusWorkOrder" .. frameID
	for id, frameInfo in pairs(WorkOrderFrames) do
		local lowerFrameCheck = string.lower(frameInfo.Frame.customerName)
		local lowerCusName = string.lower(customerName)
		if lowerFrameCheck == lowerCusName and not frameInfo.Completed then
			print(YELLOW .. "A work order for " .. customerName .. " is already open." .. ColorClose)
			if ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
				ScrollToActiveWorkOrder(customerName)
				UpdateTradeHistory(customerName)
			end
			return frameInfo.Frame
        end
	end

	local frame = CreateFrame("Frame", framename, ProEnchantersWorkOrderScrollFrame:GetScrollChild())
	frame.customerName = customerName
	frame.frameID = frameID
    frame:SetSize(420, 220)
    frame.yOffset = yOffset
    frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0, frame.yOffset)

	local customerBg = frame:CreateTexture(nil, "BACKGROUND")
    customerBg:SetColorTexture(unpack(DarkBgOpaque))  -- Set RGBA values for your preferred color and alpha
    customerBg:SetSize(420, 220)
    customerBg:SetPoint("TOP", frame, "TOP", 0, 0)

	local customerTextBg = frame:CreateTexture(nil, "OVERLAY")
    customerTextBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
    customerTextBg:SetSize(420, 20)  -- Adjust size as needed
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
			for _, frameInfo in pairs(WorkOrderFrames) do
				if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
					RemoveAllRequestedEnchant(customerName)
				end
			end
				local currentCusFocus = ProEnchantersCustomerNameEditBox:GetText()
				local currentTradeTarget = UnitName("NPC")
				if currentCusFocus == currentTradeTarget then
					ProEnchantersUpdateTradeWindowButtons(currentTradeTarget)
					ProEnchantersUpdateTradeWindowText(currentTradeTarget)
				end
		--[[elseif IsAltKeyDown() then -- Whisper all requested enchants
				local allmatsReq = GetAllReqMatsNoLink(customerName)
			for i, matsString in ipairs(allmatsReq) do
				if i == 1 then
					local msgReq = "All Mats Needed: " .. matsString
					SendChatMessage(customerName .. " " .. msgReq, "WHISPER", nil, cusName)
				elseif i > 1 then
					local msgReq = "All Mats Needed: " .. matsString
					SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, cusName)
				end
			end]]
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
local tradeHistoryScrollFrame = CreateFrame("ScrollFrame", framename .. "ScrollFrame", frame, "UIPanelScrollFrameTemplate")
tradeHistoryScrollFrame:SetSize(400, 180)
tradeHistoryScrollFrame:SetPoint("TOPLEFT", customerTextBg, "BOTTOMLEFT", 10, -5)

local scrollChild = CreateFrame("Frame", nil, tradeHistoryScrollFrame)
scrollChild:SetSize(400, 180)  -- Adjust height dynamically based on content
tradeHistoryScrollFrame:SetScrollChild(scrollChild)

local tradehistoryEditBox = CreateFrame("EditBox", frameID .. "TradeHistory", scrollChild)
tradehistoryEditBox:SetSize(380, 160)  -- Adjust size as needed
tradehistoryEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
tradehistoryEditBox:SetMultiLine(true)
tradehistoryEditBox:SetAutoFocus(false)
tradehistoryEditBox:SetHyperlinksEnabled(true)
tradehistoryEditBox:EnableMouse(true)
tradehistoryEditBox:SetFontObject("GameFontHighlight")
tradehistoryEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
tradehistoryEditBox:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMRIGHT", 0, 0)  -- Anchor bottom right to scrollChild
tradehistoryEditBox:SetScript("OnEditFocusGained", function(self)
	customerName = string.lower(customerName)
	customerName = CapFirstLetter(customerName)
	ProEnchantersCustomerNameEditBox:SetText(customerName)
end)
tradehistoryEditBox:SetScript("OnTextChanged", function(self)
	scrollChild:SetHeight(self:GetHeight())
end)
tradehistoryEditBox:SetScript("OnHyperlinkClick", function(self, linkData, link, button)
    local linkType, addon, param1, param2 = strsplit(":", linkData)
    if linkType == "addon" and addon == "ProEnchanters" then
        local enchKey = param1
		local customerName = param2
			if IsControlKeyDown() then
			RemoveRequestedEnchant(customerName, enchKey)
			local currentTradeTarget = UnitName("NPC")
				if customerName == currentTradeTarget then
					ProEnchantersUpdateTradeWindowButtons(currentTradeTarget)
					ProEnchantersUpdateTradeWindowText(currentTradeTarget)
				end
			elseif IsShiftKeyDown() then
				local reqEnchant = enchKey
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
		table.insert(ProEnchantersTradeHistory[customerName], firstline)
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
            customerBg:SetSize(420, 20)
            frame:SetSize(420, 20)
            -- Move all existing frames up if they are lower than the frame being deleted
            for id, frameInfo in pairs(WorkOrderFrames) do
                if id > frameID and not frameInfo.Completed then
                    local newYOffset = frameInfo.Frame.yOffset + 200
                    frameInfo.Frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0, newYOffset)
                    frameInfo.Frame.yOffset = newYOffset
                end
            end

            yOffset = yOffset + 200 -- Increase for the next frame
		    UpdateScrollChildHeight() -- Call a function to update the height of ScrollChild
			minButton:SetText("Maximize")
			minimized = true
			frame.minimized = minimized
        elseif minimized == true then
            tradeHistoryScrollFrame:SetSize(400, 180)
            scrollChild:SetSize(400, 180)
            customerBg:SetSize(420, 220)
            frame:SetSize(420, 220)

        -- Move all existing frames up if they are lower than the frame being deleted
        for id, frameInfo in pairs(WorkOrderFrames) do
            if id > frameID and not frameInfo.Completed then
                local newYOffset = frameInfo.Frame.yOffset - 200
                frameInfo.Frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0, newYOffset)
                frameInfo.Frame.yOffset = newYOffset
            end
        end

        yOffset = yOffset - 200  -- Increase for the next frame
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
            tradeHistoryScrollFrame:SetSize(400, 180)
            scrollChild:SetSize(400, 180)
            customerBg:SetSize(420, 220)
            frame:SetSize(420, 220)

        -- Move all existing frames up if they are lower than the frame being deleted
        for id, frameInfo in pairs(WorkOrderFrames) do
            if id > frameID and not frameInfo.Completed then
                local newYOffset = frameInfo.Frame.yOffset - 200
                frameInfo.Frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0, newYOffset)
                frameInfo.Frame.yOffset = newYOffset
            end
        end

        yOffset = yOffset - 200  -- Increase for the next frame
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
        WorkOrderFrames[frameID].Completed = true
		PEPlayerInvited[customerName] = nil

        -- Move all existing frames up if they are lower than the frame being deleted
        for id, frameInfo in pairs(WorkOrderFrames) do
            if id > frameID and not frameInfo.Completed then
                local newYOffset = frameInfo.Frame.yOffset + 222
                frameInfo.Frame:SetPoint("TOP", ProEnchantersWorkOrderScrollFrame:GetScrollChild(), "TOP", 0, newYOffset)
                frameInfo.Frame.yOffset = newYOffset
            end
        end

        yOffset = yOffset + 222  -- Increase for the next frame
		UpdateScrollChildHeight() -- Call a function to update the height of ScrollChild
		local CurrentCustomer = ProEnchantersCustomerNameEditBox:GetText()
		if CurrentCustomer == customerName then
			ProEnchantersCustomerNameEditBox:SetText("")
			ProEnchantersCustomerNameEditBox:ClearFocus(ProEnchantersCustomerNameEditBox)
		end

    end)

    yOffset = yOffset - 222  -- Decrease for a new frame
    WorkOrderFrames[frameID] = { Frame = frame, Completed = false, Enchants = {}}
	UpdateScrollChildHeight()
	UpdateTradeHistory(customerName)
	if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
		customerName = string.lower(customerName)
		customerName = CapFirstLetter(customerName)
		ProEnchantersCustomerNameEditBox:SetText(customerName)
	end
    return frame
end

-- Create Trade Order on Trade Frame

-- Function to update the height of ScrollChild based on the number of CusWorkOrder frames
function UpdateScrollChildHeight()
    local totalHeight = 0
    for id, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed then
			if frameInfo.Frame.minimized == false then
            totalHeight = totalHeight + 222 -- Add height of each frame
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
	if PEtradeWho then
		customerName = PEtradeWho
	end
	local tradeFrame = TradeFrame
	-- local tradewindowHeight = tradeFrame:GetHeight()
	local tradewindowWidth, tradewindowHeight = tradeFrame:GetSize()
	local frame = CreateFrame("Frame", "ProEnchantersTradeWindowFrame", TradeFrame)
	frame:SetFrameStrata("DIALOG")
	frame:SetSize(180, tradewindowHeight)
	frame:SetPoint("BOTTOMLEFT", tradeFrame, "BOTTOMRIGHT", 0, 0)

	local customerBg = frame:CreateTexture(nil, "BACKGROUND")
	customerBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
	customerBg:SetSize(tradewindowWidth, 180)
	customerBg:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", 0, 0)

	local customerTextBg = frame:CreateTexture(nil, "BACKGROUND")
	customerTextBg:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
	customerTextBg:SetSize(tradewindowWidth, 20)  -- Adjust size as needed
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
	

	-- Use Mats from Inventory Checkbox
	frame.useAllMatsCb = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
	frame.useAllMatsCb:SetPoint("TOPRIGHT", customerTextBg, "TOPRIGHT", -6, 0)
	frame.useAllMatsCb:SetFrameLevel(9001)
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
	useAllMatsHeader:SetFontObject("GameFontHighlight")
	useAllMatsHeader:SetPoint("RIGHT", frame.useAllMatsCb, "LEFT", 0, 0)
	useAllMatsHeader:SetText("Use all mats?")
	useAllMatsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local ScrollFrame = CreateFrame("ScrollFrame", "ProEnchantersTradeWindowFrameScrollFrame", frame, "UIPanelScrollFrameTemplate")
	ScrollFrame:SetSize(tradewindowWidth - 10, 155)
	ScrollFrame:SetPoint("TOP", customerTextBg, "BOTTOM", 0, -3)

	local scrollBar = ScrollFrame.ScrollBar
	local thumbTexture = scrollBar:GetThumbTexture()
	thumbTexture:SetTexture(nil)  -- Clear existing texture
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
		scrollChild:SetSize(tradewindowWidth - 10, 155)  -- Adjust height dynamically based on content
		ScrollFrame:SetScrollChild(scrollChild)

	local tradewindowEditBox = CreateFrame("EditBox", customerName .. "TradeWindow", scrollChild)
	tradewindowEditBox:SetSize(tradewindowWidth - 10, 155)  -- Adjust size as needed
	tradewindowEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
	tradewindowEditBox:SetMultiLine(true)
	tradewindowEditBox:SetAutoFocus(false)
	tradewindowEditBox:EnableMouse(true)
	tradewindowEditBox:SetFontObject("GameFontHighlight")
	tradewindowEditBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
	tradewindowEditBox:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMRIGHT", 0, 0)  -- Anchor bottom right to scrollChild
	tradewindowEditBox:SetScript("OnTextChanged", function(self)
	scrollChild:SetHeight(self:GetHeight())
end)

-- Make EditBox non-editable
tradewindowEditBox:EnableKeyboard(false)

-- Store the trade history EditBox in the frame
frame.tradewindowEditBox = tradewindowEditBox

	return frame
end

function ProEnchantersLoadTradeWindowFrame(PEtradeWho)

	local PEtradeWho = string.lower(PEtradeWho)
	local enchyOffset = -39
	local enchxOffset = 15
	local frame = _G["ProEnchantersTradeWindowFrame"]
	local ScrollFrame = _G["ProEnchantersTradeWindowFrameScrollFrame"]
	local scrollChild = ScrollFrame:GetScrollChild()
	local customerName = PEtradeWho or ""
	local line = ""


	frame.customerTitleButton:SetText(PEtradeWho)
	frame.customerTitleButton:SetScript("OnClick", function()
		local customerName = PEtradeWho
		customerName = string.lower(customerName)
		ProEnchantersUpdateTradeWindowButtons(customerName)
		ProEnchantersUpdateTradeWindowText(customerName)
		customerName = CapFirstLetter(customerName)
		ProEnchantersCustomerNameEditBox:SetText(customerName)
 end)
 	frame.useAllMatsCb:SetScript("OnClick", function(self)
	ProEnchantersOptions["UseAllMats"] = self:GetChecked()
	useAllMats = ProEnchantersOptions["UseAllMats"]
	ProEnchantersUpdateTradeWindowText(customerName)
	ProEnchantersUpdateTradeWindowButtons(customerName)
end)

	--[[ Set Req Enchant Window
    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            for _, enchantID in ipairs(frameInfo.Enchants) do
                local enchantName = EnchantsName[enchantID]
                line = line .. enchantName .. "\n"
            end
        end
    end]]

	--[[local tradewindowline = ""
	local matsDiff = ProEnchantersGetMatsDiff(customerName)
	for _, line in ipairs(matsDiff) do
		tradewindowline = tradewindowline .. line .. "\n"
	end
    frame.tradewindowEditBox:SetText(tradewindowline)]]

	ProEnchantersUpdateTradeWindowText(customerName)

 for _, frameInfo in pairs(WorkOrderFrames) do
		if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
			for _, enchantID in ipairs(frameInfo.Enchants) do
				local enchantName = EnchantsName[enchantID]
				local enchantStats1 = EnchantsStats[enchantID]
				local enchantStats2 = string.gsub(enchantStats1, "%(", "")
				local enchantStats3 = string.gsub(enchantStats2, "%)", "")
				local enchantStats = string.gsub(enchantStats3, "%+", "")
				local enchantTitleText1 = enchantName:gsub(" %- ", "\n")  -- Corrected from 'value' to 'enchantName'
				local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats
				local enchValue = PEenchantingLocales["Enchants"][enchantID][LocalLanguage]

				-- Initialize the buttons table if it doesn't exist
				if not frame.buttons then
					frame.buttons = {}
					frame.buttonBgs = {}
				end

				-- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
				local matsDiff = {}
				local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, enchantID)
				if matsMissingCheck ~= true then
					-- Create button background
					local enchantButtonBg = frame:CreateTexture(nil, "OVERLAY")
					enchantButtonBg:SetColorTexture(unpack(HeaderOpaque))
					enchantButtonBg:SetSize(145, 45)
					enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)
					-- Create a button
					local enchantButton = CreateFrame("Button", enchantID .. "button", frame, "SecureActionButtonTemplate")
					enchantButton:SetSize(145, 45)
					enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)
					enchantButton:SetText(enchantTitleText)
					local enchantButtonText = enchantButton:GetFontString()
					enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
					enchantButton:SetNormalFontObject("GameFontHighlight")
					enchantButton:SetHighlightFontObject("GameFontNormal")
					enchantButton:SetAttribute("type", "spell")
					enchantButton:SetAttribute("spell", enchValue)

					-- Increase yOffset for the next button
					enchyOffset = enchyOffset - 50

					table.insert(frame.buttons, enchantButton)
					table.insert(frame.buttonBgs, enchantButtonBg)
				else
					-- Create button background
					local enchantButtonBg = frame:CreateTexture(nil, "BACKGROUND")
					enchantButtonBg:SetColorTexture(unpack(GreyedOpaque))
					enchantButtonBg:SetSize(145, 45)
					enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)

					-- Create a button
					local enchantButton = CreateFrame("Button", nil, frame)
					enchantButton:SetSize(145, 45)
					enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)
					enchantButton:SetText(enchantTitleText)
					local enchantButtonText = enchantButton:GetFontString()
					enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
					enchantButton:SetNormalFontObject("GameFontHighlight")
					enchantButton:SetHighlightFontObject("GameFontNormal")
					enchantButton:SetScript("OnClick", function()
						LinkMissingMats(enchantID, customerName)
					end)

					-- Create a Announce icon
					local enchantMatsMissingDisplay = frame:CreateTexture(nil, "OVERLAY")
					--enchantMatsMissingDisplay:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
					enchantMatsMissingDisplay:SetTexture("Interface\\COMMON\\VOICECHAT-SPEAKER.BLP")
					enchantMatsMissingDisplay:SetSize(16, 16)  -- Adjust size as needed
					enchantMatsMissingDisplay:SetPoint("TOPRIGHT", enchantButton, "TOPRIGHT", 10, 5)

					-- Increase yOffset for the next button
					enchyOffset = enchyOffset - 50

					table.insert(frame.buttons, enchantButton)
					table.insert(frame.buttonBgs, enchantButtonBg)
					table.insert(frame.buttonBgs, enchantMatsMissingDisplay)
				end
			end
		end
	end
	-- Update the height of scrollChild based on the yOffset
-- scrollChild:SetHeight(enchyOffset)

end

--[[function ProEnchantersGetPrintTradedMats(customerName)
	local matsNeeded = ""
	local reqQuantity = 1
    -- Assuming ProEnchantersTradeHistory[customerName] is a list (table in Lua) of items
    if ProEnchantersTradeHistory[customerName] == nil then
        print("No trade history found for:", customerName)
        return
    end

    -- Get the list of items traded by the customer
    local tradedItems = ProEnchantersTradeHistory[customerName]

    -- Count number of indexed items
    local itemCount = #tradedItems -- '#' operator gives the length of the table when used on a sequence

    -- Printing items from the last to the first
    for i = itemCount, 1, -1 do
		if string.find(tradedItems[i], "End of workorder", 1, true) then
			print("end of workorder found")
			return matsNeeded
		elseif string.find(tradedItems[i], LIGHTYELLOW .. "IN: ", 1, true) then
			-- Extract quantity and material name
			local tradedItem = tradedItems[i]
            local quantity, material = tradedItem:match("(%d+)x (.+)")
			material = material:match("|h(.-)|h|r")
            quantity = tonumber(quantity) * reqQuantity

            -- Append to the AllMatsReq string
            if matsNeeded ~= "" then
                matsNeeded = matsNeeded .. ", " .. quantity .. "x " .. material
            else
                matsNeeded = quantity .. "x " .. material
            end
   		else
		print("found no item traded matches")
		end
	end
	return matsNeeded
end]]

-- Forwarded Scan to Parse entire area (like AH, but more frequent in idle)
function PESearchInventoryForItems()
    local availableMats = {}
    for bag = 0, NUM_BAG_SLOTS do -- Start from 0 to include the backpack
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                for nickname, idString in pairs(ItemCacheTable) do
                    if tostring(itemID) == idString then
                        local info = C_Container.GetContainerItemInfo(bag, slot)
                        if info and info.stackCount then
                            local quantity = info.stackCount
                            local itemName = select(2, GetItemInfo(itemID)) or "Unknown Item"
                            if availableMats[itemName] then
                                availableMats[itemName] = availableMats[itemName] + quantity
                            else
                                availableMats[itemName] = quantity
                            end
                        end
                    end
                end
            end
        end
    end
    return availableMats
end

function ProEnchantersGetMatsDiff(customerName)
	local customerName = string.lower(customerName)
	local matsNeeded = {}
    local matsNeededQuantity = 0
    local matsRemaining = {}
	local matsRemainingQuantity = 1
    local matsDiff = {}
    local enchantCounts = {}
    local topline = SEAGREEN .. "Mats Required for all remaining requested enchants" .. ColorClose
    -- Assuming ProEnchantersTradeHistory[customerName] is a list (table in Lua) of items
    if ProEnchantersTradeHistory[customerName] == nil then
       			local line = "No customer name found"
				table.insert(matsDiff, line)
			return matsDiff
    end

    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
				frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}

			-- Create Mats Remaining table
			if useAllMats == true then
				local allMatsAvailable = PESearchInventoryForItems()
				for material, quantity in pairs(allMatsAvailable) do -- change this to check inventory
            	    matsRemaining[material] = quantity
            	end
			else
           		for material, quantity in pairs(frameInfo.ItemsTradedIn) do
            	    local itemId = material:match(":(%d+):")
            	    local itemName = select(2, GetItemInfo(itemId)) or "Unknown Item"
            	    matsRemaining[itemName] = quantity
            	end
			end

			-- Check if the Enchants table is empty
			if next(frameInfo.Enchants) == nil then
				-- The Enchants table is empty, return or break as needed
				local line = "No requested enchants detected"
				local spacerline = " "
          		local midline = SEAGREEN .. "Other Mats Available" .. ColorClose
				table.insert(matsDiff, line)
            	table.insert(matsDiff, spacerline)
            	table.insert(matsDiff, midline)
				for mat, quantity in pairs(matsRemaining) do
					if not matsNeeded[mat] then
						local line = quantity .. "x " .. mat
						table.insert(matsDiff, line)
					end
				end
				return matsDiff
			end
	
	table.insert(matsDiff, topline)
    local totalMaterials = {}

	-- Get the total materials required for each enchantment
	for _, enchantID in ipairs(frameInfo.Enchants) do
		enchantCounts[enchantID] = (enchantCounts[enchantID] or 0) + 1
 	end

    for enchantID, count in pairs(enchantCounts) do
        local materials = ProEnchants_GetReagentList(enchantID, count)
        -- Split materials string into individual materials and sum up
        for quantity, material in string.gmatch(materials, "(%d+)x ([^,]+)") do
            quantity = tonumber(quantity)
            totalMaterials[material] = (totalMaterials[material] or 0) + quantity
        end
    end
    
    -- Convert the totalMaterials table back into a string and add to matsNeeded table
            for material, quantity in pairs(totalMaterials) do
                local itemId = material:match(":(%d+):")
                local itemName = select(2, GetItemInfo(itemId)) or "Unknown Item"
                matsNeeded[itemName] = quantity
            end

    -- Do Math for Mats Diff
            for mat, quantity in pairs(matsNeeded) do
                local matReqName = mat
                matsNeededQuantity = quantity
				matsRemainingQuantity = 0
                if matsRemaining[mat] then
                    matsRemainingQuantity = tonumber(matsRemaining[mat])
                end

                    if matsRemainingQuantity == 0 then
                        local line = RED .. matsRemainingQuantity .. " / " .. matsNeededQuantity .. ColorClose .. " " .. matReqName
                        table.insert(matsDiff, line)
                    elseif matsRemainingQuantity < matsNeededQuantity then
                        local line = YELLOW .. matsRemainingQuantity .. " / " .. matsNeededQuantity .. ColorClose .. " " .. matReqName
                        table.insert(matsDiff, line)
                    elseif matsRemainingQuantity == matsNeededQuantity then
                        local line = GREEN .. matsRemainingQuantity .. " / " .. matsNeededQuantity .. ColorClose .. " " .. matReqName
                        table.insert(matsDiff, line)
                    elseif matsRemainingQuantity > matsNeededQuantity then
                        local line = VIOLET .. matsRemainingQuantity .. " / " .. matsNeededQuantity .. ColorClose .. " " .. matReqName
                        table.insert(matsDiff, line)
                    else
                        local line = matsRemainingQuantity .. " / " .. matsNeededQuantity .. " " .. matReqName
                        table.insert(matsDiff, line)
                    end

		    end
            local spacerline = " "
            local midline = SEAGREEN .. "Other Mats Available" .. ColorClose
            table.insert(matsDiff, spacerline)
            table.insert(matsDiff, midline)

            for mat, quantity in pairs(matsRemaining) do
                if not matsNeeded[mat] then
                    local line = quantity .. "x " .. mat
                    table.insert(matsDiff, line)
                end
            end
			return matsDiff
		end
	end
end

function ProEnchantersGetSingleMatsDiff(customerName, enchantID)
	local customerName = string.lower(customerName)
	local matsNeeded = {}
    local matsRemaining = {}
    local matsDiff = {}
	local matsMissingCheck = false
    -- Assuming ProEnchantersTradeHistory[customerName] is a list (table in Lua) of items
    if ProEnchantersTradeHistory[customerName] == nil then
        --print("No trade history for customer:", customerName)
        return {}, false  -- Return an empty table and false if no trade history exists
    end

    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
				frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}

			-- Create Mats Remaining table
			if useAllMats == true then
				local allMatsAvailable = PESearchInventoryForItems()
				for material, quantity in pairs(allMatsAvailable) do -- change this to check inventory
            	    matsRemaining[material] = quantity
            	end
			else
           		for material, quantity in pairs(frameInfo.ItemsTradedIn) do
            	    local itemId = material:match(":(%d+):")
            	    local itemName = select(2, GetItemInfo(itemId)) or "Unknown Item"
            	    matsRemaining[itemName] = quantity
            	end
			end

   		local totalMaterials = {}
		local count = 1
        local materials = ProEnchants_GetReagentList(enchantID, count)
        -- Split materials string into individual materials and sum up
        for quantity, material in string.gmatch(materials, "(%d+)x ([^,]+)") do
            quantity = tonumber(quantity)
            totalMaterials[material] = (totalMaterials[material] or 0) + quantity
        end
    
    
    -- Convert the totalMaterials table back into a string and add to matsNeeded table
            for material, quantity in pairs(totalMaterials) do
                local itemId = material:match(":(%d+):")
				local itemName = select(2, GetItemInfo(itemId)) or "Unknown Item"
                matsNeeded[itemName] = quantity
            end

    -- Do Math for Mats Diff
		for mat, quantity in pairs(matsNeeded) do
			local matsRemainingQuantity = matsRemaining[mat] or 0
			if matsRemainingQuantity < quantity then
				local missingAmt = quantity - matsRemainingQuantity
				matsDiff[mat] = missingAmt
				matsMissingCheck = true
			end
		end
		return matsDiff, matsMissingCheck
		end
	end
	return {}, false  -- Return an empty table and false if no matching frameInfo found
end

function LinkMissingMats(enchantID, customerName)
	local customerName = string.lower(customerName)
	local enchantID = enchantID
	local enchantName = EnchantsName[enchantID]
	local missingMats = {}
	local currentString = ""
	local AllMatsMissing = {}

	-- For each in missingMats do the 1-5 max per line then new line etc before whispering or sending message, also figure out a way to include a button or hook last pressed secureaction button and if enchant click failed generate the linkmissingmats based on the enchantID of the spell button?
	missingMats = ProEnchantersGetSingleMatsDiff(customerName, enchantID) or {}

	-- Convert the totalMaterials table back into a string
	local itemcount = 1
	currentString = ""
    for material, quantity in pairs(missingMats) do
		local itemId = material:match(":(%d+):")
		local material = select(2, GetItemInfo(itemId))
		local addition = quantity .. "x " .. material
			if itemcount == 6 then
				table.insert(AllMatsMissing, currentString)
				currentString = addition
				itemcount = 2
			else
				if itemcount >= 2 then
					currentString = currentString .. ", "
				end
				currentString = currentString .. addition
				itemcount = itemcount + 1
			end
		end

		if itemcount > 0 then
				table.insert(AllMatsMissing, currentString)
		end


	if customerName then
		if ProEnchantersOptions["WhisperMats"] == true and customerName and customerName ~= "" then
			for i, matsString in ipairs(AllMatsMissing) do
				if i == 1 then
					local msgReq = "Mat's Missing for " .. enchantName ..  ": " .. matsString
					SendChatMessage(msgReq, "WHISPER", nil, customerName)
				elseif i > 1 then
					local msgReq = "Mat's Missing: " .. matsString
					SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, customerName)
				end
			end
		elseif CheckIfPartyMember(customerName) == true then
			local capPlayerName = CapFirstLetter(customerName)
			for i, matsString in ipairs(AllMatsMissing) do
				if i == 1 then
					local msgReq = "Mat's Missing for " .. enchantName ..  ": " .. matsString
					SendChatMessage(capPlayerName .. " " .. msgReq, IsInRaid() and "RAID" or "PARTY")
				elseif i > 1 then
					local msgReq = "Mat's Missing: " .. matsString
					SendChatMessage(capPlayerName .. " cont'd " .. msgReq, IsInRaid() and "RAID" or "PARTY")
				end
			end
		elseif customerName and customerName ~= "" then
			for i, matsString in ipairs(AllMatsMissing) do
				if i == 1 then
					local msgReq = "Mat's Missing for " .. enchantName ..  ": " .. matsString
					SendChatMessage(msgReq, "WHISPER", nil, customerName)
				elseif i > 1 then
					local msgReq = "Mat's Missing: " .. matsString
					SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, customerName)
				end
			end
		else
			for i, matsString in ipairs(AllMatsMissing) do
				if i == 1 then
					local msgReq = "Mat's Missing for " .. enchantName ..  ": " .. matsString
					SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
				elseif i > 1 then
					local msgReq = "Mat's Missing: " .. matsString
					SendChatMessage("Cont'd " .. msgReq, IsInRaid() and "RAID" or "PARTY")
				end
			end
		end
	else
		print("No Customer Name found")
		--Whisper/say trade target Missing Mats
	end
end

function ProEnchantersUpdateTradeWindowButtons(customerName)
	local customerName = string.lower(customerName)
	local SlotTypeInput = ""
	local tItemLink = GetTradeTargetItemLink(7)

		if tItemLink then
    	local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(tItemLink)

    	local tEQLoc = {
        ['INVTYPE_CHEST'] = "Chest",
        ['INVTYPE_ROBE'] = "Chest",
        ['INVTYPE_FEET'] = "Boots",
        ['INVTYPE_WRIST'] = "Bracer",
        ['INVTYPE_HAND'] = "Gloves",
        ['INVTYPE_CLOAK'] = "Cloak",
        ['INVTYPE_WEAPON'] = "Weapon",
        ['INVTYPE_SHIELD'] = "Shield",
        ['INVTYPE_2HWEAPON'] = "Weapon",
        ['INVTYPE_WEAPONMAINHAND'] = "Weapon",
        ['INVTYPE_WEAPONOFFHAND'] = "Weapon"
   		}

    SlotTypeInput = tEQLoc[itemEquipLoc] or "Unknown"
	end

	if SlotTypeInput == "Unknown" or SlotTypeInput == nil then
		return
	end

	RemoveTradeWindowInfo()
	local enchyOffset = -39
	local enchxOffset = 15
	local frame = _G["ProEnchantersTradeWindowFrame"]
	local slotType = SlotTypeInput
	local enchantType = ""
	local enchantName = ""

	if not frame.buttons then
		frame.buttons = {}
		frame.buttonBgs = {}
	end

 for _, frameInfo in pairs(WorkOrderFrames) do
	if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
		for _, enchantID in ipairs(frameInfo.Enchants) do
			enchantName = EnchantsName[enchantID]
			if string.find(enchantName, slotType, 1, true) then
				local enchantStats1 = EnchantsStats[enchantID]
				local enchantStats2 = string.gsub(enchantStats1, "%(", "")
				local enchantStats3 = string.gsub(enchantStats2, "%)", "")
				local enchantStats = string.gsub(enchantStats3, "%+", "")
				local enchantTitleText1 = enchantName:gsub(" %- ", "\n")  -- Corrected from 'value' to 'enchantName'
				local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats
				local enchValue = PEenchantingLocales["Enchants"][enchantID][LocalLanguage]

				-- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
				local matsDiff = {}
				local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, enchantID)
				if matsMissingCheck ~= true then
				-- Create button background
				local enchantButtonBg = frame:CreateTexture(nil, "OVERLAY")
				enchantButtonBg:SetColorTexture(unpack(HeaderOpaque))
				enchantButtonBg:SetSize(145, 45)
				enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)

				-- Create a button
				local enchantButton = CreateFrame("Button", enchantID .. "button", frame, "SecureActionButtonTemplate")
				enchantButton:SetSize(145, 45)
				enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)
				enchantButton:SetText(enchantTitleText)
				local enchantButtonText = enchantButton:GetFontString()
				enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
				enchantButton:SetNormalFontObject("GameFontHighlight")
				enchantButton:SetHighlightFontObject("GameFontNormal")
				enchantButton:SetAttribute("type", "spell")
				enchantButton:SetAttribute("spell", enchValue)

				-- Increase yOffset for the next button
				enchyOffset = enchyOffset - 50

				table.insert(frame.buttons, enchantButton)
				table.insert(frame.buttonBgs, enchantButtonBg)
				else
				-- Create button background
				local enchantButtonBg = frame:CreateTexture(nil, "BACKGROUND")
				enchantButtonBg:SetColorTexture(unpack(GreyedOpaque))
				enchantButtonBg:SetSize(145, 45)
				enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)

				-- Create a button
				local enchantButton = CreateFrame("Button", nil, frame)
				enchantButton:SetSize(145, 45)
				enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)
				enchantButton:SetText(enchantTitleText)
				local enchantButtonText = enchantButton:GetFontString()
				enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
				enchantButton:SetNormalFontObject("GameFontHighlight")
				enchantButton:SetHighlightFontObject("GameFontNormal")
				enchantButton:SetScript("OnClick", function()
					LinkMissingMats(enchantID, customerName)
				end)

				-- Create a Announce icon
				local enchantMatsMissingDisplay = frame:CreateTexture(nil, "OVERLAY")
				--enchantMatsMissingDisplay:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
				enchantMatsMissingDisplay:SetTexture("Interface\\COMMON\\VOICECHAT-SPEAKER.BLP")
				enchantMatsMissingDisplay:SetSize(16, 16)  -- Adjust size as needed
				enchantMatsMissingDisplay:SetPoint("TOPRIGHT", enchantButton, "TOPRIGHT", 10, 5)

				-- Increase yOffset for the next button
				enchyOffset = enchyOffset - 50

				table.insert(frame.buttons, enchantButton)
				table.insert(frame.buttonBgs, enchantButtonBg)
				table.insert(frame.buttonBgs, enchantMatsMissingDisplay)
				end
			end
		end

				-- Add a Spacer
				local otherEnchantsBg = frame:CreateTexture(nil, "OVERLAY")
				otherEnchantsBg:SetColorTexture(unpack(HeaderTrans))  -- Set RGBA values for your preferred color and alpha
				otherEnchantsBg:SetSize(140, 20)
				otherEnchantsBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)
			
				local otherEnchants = frame:CreateFontString(nil, "OVERLAY")
				otherEnchants:SetFontObject("GameFontHighlight")
				otherEnchants:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset + 3)
				otherEnchants:SetText("Additional Enchants")
				otherEnchants:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

				table.insert(frame.buttons, otherEnchantsBg)
				table.insert(frame.buttonBgs, otherEnchants)
				enchyOffset = enchyOffset - 25

				local function alphanumericSort(a, b)
					-- Extract number from the string
					local numA = tonumber(a:match("%d+"))
					local numB = tonumber(b:match("%d+"))
				
					if numA and numB then  -- If both strings have numbers, then compare numerically
						return numA < numB  -- Reverse numerical order
					else
						return a < b  -- Reverse lexicographical order
					end
				end
				
				-- Get and sort the keys
				local keys = {}
				for k in pairs(EnchantsName) do
					table.insert(keys, k)
				end
				table.sort(keys, alphanumericSort)  -- Sorts the keys in natural alphanumeric order

				-- Load rest of Relevant Enchant Buttons that are Available
			for _, key in ipairs(keys) do
				if ProEnchantersOptions.filters[key] == true then
				enchantName = EnchantsName[key]
					if string.find(enchantName, slotType, 1, true) then
					local enchantTitleText1 = enchantName:gsub(" %- ", "\n")  -- Corrected from 'value' to 'enchantName'
					local enchantStats1 = EnchantsStats[key]
					local enchantStats2 = string.gsub(enchantStats1, "%(", "")
					local enchantStats3 = string.gsub(enchantStats2, "%)", "")
					local enchantStats = string.gsub(enchantStats3, "%+", "")
					local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats
					local enchValue = PEenchantingLocales["Enchants"][key][LocalLanguage]
					
					local matsDiff = {}
					local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, key)
					if matsMissingCheck ~= true then
					-- Create button background
					local enchantButtonBg = frame:CreateTexture(nil, "OVERLAY")
					enchantButtonBg:SetColorTexture(unpack(HeaderOpaque))
					enchantButtonBg:SetSize(145, 45)
					enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)
	
					-- Create a button
					local enchantButton = CreateFrame("Button", key .. "button", frame, "SecureActionButtonTemplate")
					enchantButton:SetSize(145, 45)
					enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)
					enchantButton:SetText(enchantTitleText)
					local enchantButtonText = enchantButton:GetFontString()
					enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
					enchantButton:SetNormalFontObject("GameFontHighlight")
					enchantButton:SetHighlightFontObject("GameFontNormal")
					enchantButton:SetAttribute("type", "spell")
					enchantButton:SetAttribute("spell", enchValue)

	
					-- Increase yOffset for the next button
					enchyOffset = enchyOffset - 50
	
					table.insert(frame.buttons, enchantButton)
					table.insert(frame.buttonBgs, enchantButtonBg)
					end
					end
				end
			end

				-- Load rest of Relevant Enchant Buttons that are Not Available
			for _, key in ipairs(keys) do
				if ProEnchantersOptions.filters[key] == true then
				enchantName = EnchantsName[key]
					if string.find(enchantName, slotType, 1, true) then
					local enchantTitleText1 = enchantName:gsub(" %- ", "\n")  -- Corrected from 'value' to 'enchantName'
					local enchantStats1 = EnchantsStats[key]
					local enchantStats2 = string.gsub(enchantStats1, "%(", "")
					local enchantStats3 = string.gsub(enchantStats2, "%)", "")
					local enchantStats = string.gsub(enchantStats3, "%+", "")
					local enchantTitleText = enchantTitleText1 .. "\n" .. enchantStats
					local enchValue = PEenchantingLocales["Enchants"][key][LocalLanguage]
					
					local matsDiff = {}
					local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, key)
					if matsMissingCheck == true then
					-- Create button background
					local enchantButtonBg = frame:CreateTexture(nil, "BACKGROUND")
					enchantButtonBg:SetColorTexture(unpack(GreyedOpaque))
					enchantButtonBg:SetSize(145, 45)
					enchantButtonBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)

					-- Create a button
					local enchantButton = CreateFrame("Button", nil, frame)
					enchantButton:SetSize(145, 45)
					enchantButton:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, -enchyOffset)
					enchantButton:SetText(enchantTitleText)
					local enchantButtonText = enchantButton:GetFontString()
					enchantButtonText:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")
					enchantButton:SetNormalFontObject("GameFontHighlight")
					enchantButton:SetHighlightFontObject("GameFontNormal")
					enchantButton:SetScript("OnClick", function()
						LinkMissingMats(key, customerName)
					end)

					-- Create a Announce icon
					local enchantMatsMissingDisplay = frame:CreateTexture(nil, "OVERLAY")
					--enchantMatsMissingDisplay:SetColorTexture(unpack(HeaderOpaque))  -- Set RGBA values for your preferred color and alpha
					enchantMatsMissingDisplay:SetTexture("Interface\\COMMON\\VOICECHAT-SPEAKER.BLP")
					enchantMatsMissingDisplay:SetSize(16, 16)  -- Adjust size as needed
					enchantMatsMissingDisplay:SetPoint("TOPRIGHT", enchantButton, "TOPRIGHT", 10, 5)

					-- Increase yOffset for the next button
					enchyOffset = enchyOffset - 50

					table.insert(frame.buttons, enchantButton)
					table.insert(frame.buttonBgs, enchantButtonBg)
					table.insert(frame.buttonBgs, enchantMatsMissingDisplay)
					end
					end
				end
			end
		end
	end
end

function ProEnchantersUpdateTradeWindowText(customerName)
	local customerName = string.lower(customerName)
	local tradewindowline = ""
	-- Get Trade Window Frame
	local frame = _G["ProEnchantersTradeWindowFrame"]
	local matsDiff = {}
	local currentTradeTarget = UnitName("NPC")

	matsDiff = ProEnchantersGetMatsDiff(currentTradeTarget)
		for _, line in ipairs(matsDiff) do
			tradewindowline = tradewindowline .. line .. "\n"
		end
	frame.tradewindowEditBox:SetText(tradewindowline)

--[[ Set Req Enchant Window
	for _, frameInfo in pairs(WorkOrderFrames) do
		if not frameInfo.Completed and frameInfo.Frame.customerName == cusName then
			matsDiff = ProEnchantersGetMatsDiff(customerName)
			for _, line in ipairs(matsDiff) do
				tradewindowline = tradewindowline .. line .. "\n"
			end
		frame.tradewindowEditBox:SetText(tradewindowline)
		elseif currentTradeTarget then
			matsDiff = ProEnchantersGetMatsDiff(currentTradeTarget)
			for _, line in ipairs(matsDiff) do
				tradewindowline = tradewindowline .. line .. "\n"
			end
		frame.tradewindowEditBox:SetText(tradewindowline)
		else
		local noline = "No information found to display"
		frame.tradewindowEditBox:SetText(noline)
		end
	end]]
end

function RemoveWhisperTriggers()

	local frame = _G["ProEnchantersWhisperTriggersFrame"]

	if frame.fieldscmd then
		for _, f in ipairs(frame.fieldscmd) do
			f:Hide()
			f:SetParent(nil)
			f:ClearAllPoints()
		end
		for _, f in ipairs(frame.fieldsmsg) do
			f:Hide()
			f:SetParent(nil)
			f:ClearAllPoints()
		end
		wipe(frame.fieldscmd)  -- Clear the table
		wipe(frame.fieldsmsg)
	end
end

function RemoveTradeWindowInfo()

	local frame = _G["ProEnchantersTradeWindowFrame"]

	if frame.buttons then
		for _, button in ipairs(frame.buttons) do
			button:Hide()
			button:SetParent(nil)
			button:ClearAllPoints()
		end
		for _, buttonBg in ipairs(frame.buttonBgs) do
			buttonBg:Hide()
			buttonBg:SetParent(nil)
			buttonBg:ClearAllPoints()
		end
		wipe(frame.buttons)  -- Clear the table
		wipe(frame.buttonBgs)
	end
end


-- End trade order on trade frame
local function OnAddonLoaded()
	-- Cache Items
	PEItemCache()

	-- Ensure the ProEnchantersOptions and its filters sub-table are properly initialized
    ProEnchantersOptions = ProEnchantersOptions or {}
    ProEnchantersOptions.filters = ProEnchantersOptions.filters or {}
	ProEnchantersOptions.whispertriggers = ProEnchantersOptions.whispertriggers or {}

	if ProEnchantersOptions["Colors"] == nil or ProEnchantersOptions["Colors"] == {} then
		ProEnchantersOptions["Colors"] = {
			HeaderColor = {22/255, 26/255, 48/255},
			TitleColor = {182/255, 187/255, 196/255},
			LightBgColor = {240/255, 236/255, 229/255},
			DarkBgColor = {49/255, 48/255, 77/255},
			GreyedColor = {71/255, 71/255, 71/255}
		}
	else
		ProEnchantersOptions["Colors"] = ProEnchantersOptions["Colors"]
	end

	if next(ProEnchantersOptions.Colors.HeaderColor) == nil then
		ProEnchantersOptions.Colors.HeaderColor = {22/255, 26/255, 48/255}
	end

	if next(ProEnchantersOptions.Colors.TitleColor) == nil then
		ProEnchantersOptions.Colors.TitleColor = {22/255, 26/255, 48/255}
	end

	if next(ProEnchantersOptions.Colors.LightBgColor) == nil then
		ProEnchantersOptions.Colors.LightBgColor = {22/255, 26/255, 48/255}
	end

	if next(ProEnchantersOptions.Colors.DarkBgColor) == nil then
		ProEnchantersOptions.Colors.DarkBgColor = {22/255, 26/255, 48/255}
	end

	if next(ProEnchantersOptions.Colors.GreyedColor) == nil then
		ProEnchantersOptions.Colors.GreyedColor = {22/255, 26/255, 48/255}
	end

	--Color for Frames
	HeaderColor = ProEnchantersOptions.Colors.HeaderColor or {22/255, 26/255, 48/255}
	r1, g1, b1 = unpack(HeaderColor)
	HeaderOpaque = {r1, g1, b1, 1}
	HeaderTrans = {r1, g1, b1, 0.5}

	TitleColor = ProEnchantersOptions.Colors.TitleColor or {182/255, 187/255, 196/255}
	r2, g2, b2 = unpack(TitleColor)
	TitleOpaque = {r2, g2, b2, 1}
	TitleTrans = {r2, g2, b2, 0.5}

	LightBgColor = ProEnchantersOptions.Colors.LightBgColor or {240/255, 236/255, 229/255}
	r3, g3, b3 = unpack(LightBgColor)
	LightBgOpaque = {r3, g3, b3, 1}
	LightBgTrans = {r3, g3, b3, 0.5}

	DarkBgColor = ProEnchantersOptions.Colors.DarkBgColor or {49/255, 48/255, 77/255}
	r4, g4, b4 = unpack(DarkBgColor)
	DarkBgOpaque = {r4, g4, b4, 1}
	DarkBgTrans = {r4, g4, b4, 0.5}

	GreyedColor = ProEnchantersOptions.Colors.GreyedColor or {71/255, 71/255, 71/255}
	r5, g5, b5 = unpack(GreyedColor)
	GreyedOpaque = {r5, g5, b5, 1}
	GreyedTrans = {r5, g5, b5, 0.5}
    
    -- Now safe to register the events that use ProEnchantersWorkOrderFrame
    ProEnchanters.frame:RegisterEvent("CHAT_MSG_SAY")
    ProEnchanters.frame:RegisterEvent("CHAT_MSG_YELL")
    ProEnchanters.frame:RegisterEvent("CHAT_MSG_CHANNEL")
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
		if ProEnchantersOptions.filters[key] == nil or ProEnchantersOptions.filters[key] == "" then
			ProEnchantersOptions.filters[key] = true
		else
			ProEnchantersOptions.filters[key] = ProEnchantersOptions.filters[key]
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

	-- Setting AutoInviteOptions
	if ProEnchantersOptions["RaidIcon"] == nil or ProEnchantersOptions["RaidIcon"] == "" then
		ProEnchantersOptions["RaidIcon"] = 0
		PESetRaidIcon = ProEnchantersOptions["RaidIcon"]
	else
		ProEnchantersOptions["RaidIcon"] = ProEnchantersOptions["RaidIcon"]
		PESetRaidIcon = ProEnchantersOptions["RaidIcon"]
	end

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

	if ProEnchantersOptions["AllChannels"] ~= true then
		AllChannels = false
		ProEnchantersOptions["AllChannels"] = false
		
	else
		AllChannels = ProEnchantersOptions["AllChannels"]
	end

	-- Now safe to create the frames
    ProEnchantersWorkOrderFrame = ProEnchantersCreateWorkOrderFrame()
	ProEnchantersTradeWindowFrame = ProEnchantersTradeWindowCreateFrame()
	ProEnchantersOptionsFrame = ProEnchantersCreateOptionsFrame()
	ProEnchantersTriggersFrame = ProEnchantersCreateTriggersFrame()
	ProEnchantersWhisperTriggersFrame = ProEnchantersCreateWhisperTriggersFrame()
	ProEnchantersCreditsFrame = ProEnchantersCreateCreditsFrame()
	ProEnchantersColorsFrame = ProEnchantersCreateColorsFrame()
    ProEnchantersWorkOrderEnchantsFrame = ProEnchantersCreateWorkOrderEnchantsFrame(ProEnchantersWorkOrderFrame)


    print("|cff00ff00Thank's for using Pro Enchanters! Type /pehelp or /proenchantershelp for more info!|r")

end

-- Move the ADDON_LOADED event registration to the top
ProEnchanters.frame:RegisterEvent("ADDON_LOADED")

ProEnchanters.frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and select(1, ...) == "ProEnchanters" then
		print("ProEnchanters Addon Loaded Event Registered")
        OnAddonLoaded()
	elseif event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_SYSTEM" or event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
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

-- Ensure ProEnchantersWorkOrderFrame is not nil before accessing it in your functions
SlashCmdList["PROENCHANTERS"] = function(msg)
	if msg == "reset" then
		FullResetFrames()
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
		debugLevel = convertedNumber
		if convertedNumber == 0 then
			print(GREENYELLOW .. "Debugging turned onto 0, either /reload or do /pedebug 0 to disable." .. ColorClose)
		elseif convertedNumber == 1 then
			print(ORANGE .. "Debugging turned onto 1 (mainly for whisper debugging), either /reload or do /pedebug 0 to disable." .. ColorClose)
		elseif convertedNumber == 2 then
			print(ORANGERED .. "Debugging turned onto 2 (mainly for potential customer debugging), either /reload or do /pedebug 0 to disable." .. ColorClose)
		elseif convertedNumber >= 3 then
			print(RED .. "Debugging turned onto max, all debugging commands will flow, either /reload or do /pedebug 0 to disable." .. ColorClose)
		end
	elseif debugLevel >= 0 then
		print(ORANGE .. "Current debugging set to " .. ColorClose .. debugLevel)
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
		print(ORANGE .. "Use /pe reset if you manage to get the main window completely off screen and need to reset its position" .. ColorClose)
		print(ORANGE .. "Available help sections: main, enchants, trade, settings, credits" .. ColorClose)
		print(ORANGE .. "use '/pehelp section' for more specific information" .. ColorClose)
		print(ORANGE .. "If this is your first time loading the addon it is recommended to do a recipe sync, check out the setings section for more info " .. ColorClose)
		print(ORANGE .. "~ Generic Info ~" .. ColorClose)
		print(ORANGE .. "Right click on a player to create a work order without using the main window" .. ColorClose)
		print(ORANGE .. "If auto invite is disabled, hitting Invite on the pop up will invite them to your party and create a work order for them" .. ColorClose)
		print(ORANGE .. "Any text that you hover that goes from white to yellow is a button, and some buttons have multiple functions based on if a modifier key (Alt, Ctrl, Shift) is held" .. ColorClose)
		print(ORANGE .. "Top of the main windows when clicked will minimize the window to a smaller bar" .. ColorClose)
		print(ORANGE .. "You can disconnect the Enchants window and drag it to a different portion of your screen, click the < in the top right corner to rejoin to main window" .. ColorClose)
		print(ORANGE .. "Whenever you invite a player to your party through an Addons Action it will send a message to the potential customer. Manually inviting players does not send any messages" .. ColorClose)
	elseif msg == "main" then
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "~ Main Window Info ~" .. ColorClose)
		print(ORANGE .. "Enter a customer into the top text field and hit create to start a work order" .. ColorClose)
		print(ORANGE .. "The customer name in the top text field is considered the Focused customer, adding or removing enchants from the side panel will do so for the Focused customers work order" .. ColorClose)
		print(ORANGE .. "Work orders will log enchant requests when added or removed, any currency traded, items traded, and enchants completed" .. ColorClose)
		print(ORANGE .. "If you have many work orders open and need to find one quickly enter the customers name and his Create one more time, it will focus an open work order if one exists" .. ColorClose)
		print(ORANGE .. "Clicking on the work orders Customer Name will set that work order as the Focused work order" .. ColorClose)
		print(ORANGE .. "Clicking the Req Mats button will send a message with all the required mats added together for the requested enchants" .. ColorClose)
		print(ORANGE .. "Shift+Clicking the Req Mats button will send a message with all the requested enchants in short form" .. ColorClose)
		print(ORANGE .. "Ctrl+Clicking will remove all requested enchants so you can start fresh if needed" .. ColorClose)
		print(ORANGE .. "Clicking the X will mark the work order as completed, it is recommended to close work orders after your service is done and the player has left" .. ColorClose)
		print(ORANGE .. "The 'Auto Invite' Checkbox will automatically invite players that are found to be potential customers, if unchecked you will receive a popup notification instead" .. ColorClose)
		print(ORANGE .. "The Gold Traded readout is for your current active session, if you do a /reload, close the game, or change zones with a loading screen it will reset" .. ColorClose)
			print(ORANGE .. "Settings button opens the options" .. ColorClose)
		print(ORANGE .. "Hitting the Close button will close the window, hitting escape will close the window as well" .. ColorClose)
	elseif msg == "enchants" then
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "~ Enchants Info ~" .. ColorClose)
		print(ORANGE .. "Type into the Filter box to search for a specific enchant, any letters or numbers on the enchant button can be used for the search (ie Stam will show all enchants with Stam in the name)" .. ColorClose)
		print(ORANGE .. "Clicking on an enchant will add it as a request to the current Focused work order" .. ColorClose)
		print(ORANGE .. "You can add multiple of the same enchant as well (ie player wants 2x 1H weapon enchants, adding both will allow the rest of the addon to do the math for required mats, etc)" .. ColorClose)
		print(ORANGE .. "Shift+Clicking on an enchant will send the enchants name and mats required" .. ColorClose)
		print(ORANGE .. "Ctrl+Clicking on an enchant will remove it as a request from the current Focused work order" .. ColorClose)
		print(ORANGE .. "Alt+Clicking on an enchant will add it as a requested enchant to your current trade partners open work order (This allows you to add enchants on the fly without having to change your Focused work order)" .. ColorClose)
		print(ORANGE .. "Ctrl+Alt+Clicking on an enchant will remove it as a requested enchant from your current trade partner" .. ColorClose)
		print(ORANGE .. "Ctrl+Alt+Shift+Clicking on an enchant will remove it from the enchants window in the same way that unchecking it in the Settings window does, will have to re-check it off in the settings if you want it back" .. ColorClose)
	elseif msg == "trade" then
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "~ Trade Info ~" .. ColorClose)
		print(ORANGE .. "Requested enchants will show in the small window below the trade screen" .. ColorClose)
		print(ORANGE .. "Clicking the customers name on the small window below the trade screen will set the work order as the focus in the main window" .. ColorClose)
		print(ORANGE .. "Enchant buttons for the requested enchants will populate on the right hand side of the trade window, clicking on them will 'cast' the enchant spell for that enchant" .. ColorClose)
		print(ORANGE .. "When a player puts an item into the trade window, if it is in the Non Trade slot for enchanting, the enchant buttons will filter the buttons to match the gear slot type and prioritize the requested enchants as the first button at the bottom" .. ColorClose)
		print(ORANGE .. "When a trade is successful it will record any money traded, any items traded, and it will mark any enchants as completed to remove them from the outstanding requested enchants" .. ColorClose)
	elseif msg == "settings" then
		print(ORANGE .. "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~" .. ColorClose)
		print(ORANGE .. "~ Settings Info ~" .. ColorClose)
		print(ORANGE .. "use /pefontsize to set a new font size for most text within the addon" .. ColorClose)
		print(ORANGE .. "Alert potential customers while closed: If this is checked off you will still get notified of potential customers or auto invite them if you have the main window closed, otherwise the main window must be open for features to work" .. ColorClose)
		print(ORANGE .. "Include all channels: By default only the current City's chat and any /say or /yell messages will trigger potential customers, however checking this off will search all chat channels for potential customers such as Trade or LFG" .. ColorClose)
		print(ORANGE .. "Msg Settings: Setup the automatic messages based on the listed event (player invited, trade started, tip received, etc)" .. ColorClose)
		print(ORANGE .. "Msg Settings: Adding the word CUSTOMER in all caps will be replaced by the relevant customers name" .. ColorClose)
		print(ORANGE .. "Tip Msg Settings: Adding the word MONEY will be replaced by the amount of money received from a trade" .. ColorClose)
		print(ORANGE .. "Auto Raid Icon: When a player joins your party it will set your raid icon to the selected icon so customers can spot you easier" .. ColorClose)
		print(ORANGE .. "Enchant List Check Boxes: Checking an enchant off will display it in the main enchants window, unchecking will hide it" .. ColorClose)
		print(ORANGE .. "This way if you want to hide irrelevant enchants to lower the amount of buttons in the enchants window you can (ie hide minor striking weapon enchant so that when filtering for striking you only see lesser and above)" .. ColorClose)
		print(ORANGE .. "Reset Msgs button: This will reset all of the Msg text to their originals included with the addon" .. ColorClose)
		print(ORANGE .. "Sync Recipes button: With the default Enchanting window open, this will allow you to sync the available enchant buttons to your learned recipes (Really handy for season of discovery as available recipes are limited per phase)" .. ColorClose)
		print(ORANGE .. "It's recommended to start off by doing a recipe sync so that you can see only valid available enchants, and then modifying the remaining checked off recipes to meet your goals and preferences" .. ColorClose)
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
	if event == "CHAT_MSG_SYSTEM" then
		local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
			if string.find(text, "to join your group.", 1, true) then
				if AddonInvite == false then
					NonAddonInvite = true
				end
				if AddonInvite == true then
				AddonInvite = false
				local playerName = string.match(text, "You have invited (.+) to join your group.")
				local autoInvMsg = AutoInviteMsg
				local autoInvMsg2 = string.gsub(autoInvMsg, "CUSTOMER", playerName)
					if ProEnchantersOptions["WorkWhileClosed"] == true then
							if autoInvMsg2 == "" then
								print("Inviting " .. playerName)
							else
								SendChatMessage(autoInvMsg2, "WHISPER", nil, playerName)
							end
					elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
							if autoInvMsg2 == "" then
								print("Inviting " .. playerName)
							else
								SendChatMessage(autoInvMsg2, "WHISPER", nil, playerName)
							end
					end
			end
		elseif string.find(text, "joins the party.", 1, true) then
			local playerName = string.match(text, "(.+) joins the party.")
			if ProEnchantersOptions["WorkWhileClosed"] == true then
				local unit = GetUnitName("player")
				SetRaidTarget(unit, PESetRaidIcon)
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
					SendChatMessage("Hello there " .. capPlayerName .. " o/, let me know what you need and trade when ready!", IsInRaid() and "RAID" or "PARTY")
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
					SendChatMessage("Hello there " .. capPlayerName .. " o/, let me know what you need and trade when ready!", IsInRaid() and "RAID" or "PARTY")
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
		elseif string.find(text, "has joined the raid group", 1, true) then
			local playerName = string.match(text, "(.+) has joined the raid group")
			if ProEnchantersOptions["WorkWhileClosed"] == true then
				local unit = GetUnitName("player")
				SetRaidTarget(unit, PESetRaidIcon)
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
					SendChatMessage("Hello there " .. capPlayerName .. " o/, let me know what you need and trade when ready!", IsInRaid() and "RAID" or "PARTY")
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
					SendChatMessage("Hello there " .. capPlayerName .. " o/, let me know what you need and trade when ready!", IsInRaid() and "RAID" or "PARTY")
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
		elseif string.find(text, "is already in a group.", 1, true) then
			if AddonInvite == false then
				NonAddonInvite = true
			end
			if AddonInvite == true then
			AddonInvite = false
			local playerName = string.match(text, "(.+) is already in a group.")
			local FailInvMsg = ProEnchantersOptions["FailInvMsg"]
			local FailInvMsg2 = string.gsub(FailInvMsg, "CUSTOMER", playerName)
				if ProEnchantersOptions["WorkWhileClosed"] == true then
						if FailInvMsg2 == "" then
							print("Invite failed for " .. playerName)
						else
							SendChatMessage(FailInvMsg2, "WHISPER", nil, playerName)
						end
				elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
						if FailInvMsg2 == "" then
							print("Invite failed for " .. playerName)
						else
							SendChatMessage(FailInvMsg2, "WHISPER", nil, playerName)
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
		local channelCheck = "General - " .. city
		if ProEnchantersOptions["AllChannels"] == true then
			for _, tword in pairs(ProEnchantersOptions.triggerwords) do
				local check1 = false
				local check2 = false
				local check3 = false
				local check4 = false
				local startPos, endPos = string.find(msg2, tword)
				if string.find(msg2, tword, 1, true) then
					check1 = true
					if debugLevel >= 2 then
						print("Potential Customer " .. author2 .. " trigger found: " .. tword .. " found within " .. msg2)
					end
				end


				if startPos then
					-- Check if "ench" is at the start of the string or preceded by a space
					if startPos == 1 or string.sub(msg2, startPos - 1, startPos - 1) == " " then
						check2 = true
						if debugLevel >= 2 then
							print(tword .. " does not have any leading characters, returning check2 as true")
						end
					else
						if debugLevel >= 2 then
							print(tword .. " is contained within a word, check2 returned as false")
						end
					end
				end

				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(msg2, filteredWord, 1, true) then
						check3 = true
						if debugLevel >= 2 then
							print("Potential Customer " .. author2 .. " filter found: " .. word .. " found within " .. msg2 .. ", check 3 returning false")
						end
						break
					end
				end
				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(author, filteredWord, 1, true) then
						check4 = true
						if debugLevel >= 2 then
							print("Potential Customer " .. author2 .. " name found in filter list, check 3 returning false")
						end
						break
					end
				end

				if check1 == true and check2 == true and check3 == false and check4 == false then
					if debugLevel >= 2 then
						print("All checks passed, continuing with potential customer invite or pop-up")
					end
				local playerName = author3
				local AutoInviteFlag = ProEnchantersOptions["AutoInvite"]
				if ProEnchantersOptions["WorkWhileClosed"] == true then
					if AutoInviteFlag == true then
						AddonInvite = true
						if AddonInvite == true then
							InviteUnitPEAddon(author2)
							PEPlayerInvited[playerName] = msg2
						end
						PlaySound(SOUNDKIT.MAP_PING)
						elseif AutoInviteFlag == false then
						StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
						end
				elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
					if AutoInviteFlag == true then
						AddonInvite = true
						if AddonInvite == true then
							InviteUnitPEAddon(author2)
							PEPlayerInvited[playerName] = msg2
						end
					PlaySound(SOUNDKIT.MAP_PING)
					elseif AutoInviteFlag == false then
					StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
					end
				end
			end
			end
		elseif channelName == channelCheck then
			if debugLevel >= 2 then
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
					if debugLevel >= 2 then
						print("Potential Customer " .. author2 .. " trigger found: " .. tword .. " found within " .. msg2)
					end
				end


				if startPos then
					-- Check if "ench" is at the start of the string or preceded by a space
					if startPos == 1 or string.sub(msg2, startPos - 1, startPos - 1) == " " then
						check2 = true
						if debugLevel >= 2 then
							print(tword .. " does not have any leading characters, returning check2 as true")
						end
					else
						if debugLevel >= 2 then
							print(tword .. " is contained within a word, check2 returned as false")
						end
					end
				end

				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(msg2, filteredWord, 1, true) then
						check3 = true
						if debugLevel >= 2 then
							print("Potential Customer " .. author2 .. " filter found: " .. word .. " found within " .. msg2 .. ", check 3 returning false")
						end
						break
					end
				end
				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(author, filteredWord, 1, true) then
						check4 = true
						if debugLevel >= 2 then
							print("Potential Customer " .. author2 .. " name found in filter list, check 3 returning false")
						end
						break
					end
				end

				if check1 == true and check2 == true and check3 == false and check4 == false then
					if debugLevel >= 2 then
						print("All checks passed, continuing with potential customer invite or pop-up")
					end
				local playerName = author3
				local AutoInviteFlag = ProEnchantersOptions["AutoInvite"]
				if ProEnchantersOptions["WorkWhileClosed"] == true then
					if AutoInviteFlag == true then
						AddonInvite = true
						if AddonInvite == true then
							InviteUnitPEAddon(author2)
							PEPlayerInvited[playerName] = msg2
						end
						PlaySound(SOUNDKIT.MAP_PING)
						elseif AutoInviteFlag == false then
						StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
						end
				elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
					if AutoInviteFlag == true then
						AddonInvite = true
						if AddonInvite == true then
							InviteUnitPEAddon(author2)
							PEPlayerInvited[playerName] = msg2
						end
					PlaySound(SOUNDKIT.MAP_PING)
					elseif AutoInviteFlag == false then
					StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
					end
				end
			end
			end
		elseif channelName == "" or channelName == nil then
			for _, tword in pairs(ProEnchantersOptions.triggerwords) do
				local check1 = false
				local check2 = false
				local check3 = false
				local check4 = false
				local startPos, endPos = string.find(msg2, tword)
				if string.find(msg2, tword, 1, true) then
					check1 = true
					if debugLevel >= 2 then
						print("Potential Customer " .. author2 .. " trigger found: " .. tword .. " found within " .. msg2)
					end
				end


				if startPos then
					-- Check if "ench" is at the start of the string or preceded by a space
					if startPos == 1 or string.sub(msg2, startPos - 1, startPos - 1) == " " then
						check2 = true
						if debugLevel >= 2 then
							print(tword .. " does not have any leading characters, returning check2 as true")
						end
					else
						if debugLevel >= 2 then
							print(tword .. " is contained within a word, check2 returned as false")
						end
					end
				end

				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(msg2, filteredWord, 1, true) then
						check3 = true
						if debugLevel >= 2 then
							print("Potential Customer " .. author2 .. " filter found: " .. word .. " found within " .. msg2 .. ", check 3 returning false")
						end
						break
					end
				end
				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(author, filteredWord, 1, true) then
						check4 = true
						if debugLevel >= 2 then
							print("Potential Customer " .. author2 .. " name found in filter list, check 3 returning false")
						end
						break
					end
				end

				if check1 == true and check2 == true and check3 == false and check4 == false then
					if debugLevel >= 2 then
						print("All checks passed, continuing with potential customer invite or pop-up")
					end
				local playerName = author3
				local AutoInviteFlag = ProEnchantersOptions["AutoInvite"]
				if ProEnchantersOptions["WorkWhileClosed"] == true then
					if AutoInviteFlag == true then
						AddonInvite = true
						if AddonInvite == true then
							InviteUnitPEAddon(author2)
							PEPlayerInvited[playerName] = msg2
						end
						PlaySound(SOUNDKIT.MAP_PING)
						elseif AutoInviteFlag == false then
						StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
						end
				elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
					if AutoInviteFlag == true then
						AddonInvite = true
						if AddonInvite == true then
							InviteUnitPEAddon(author2)
							PEPlayerInvited[playerName] = msg2
						end
					PlaySound(SOUNDKIT.MAP_PING)
					elseif AutoInviteFlag == false then
					StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
					end
				end
			end
		end
		end
	elseif event == "CHAT_MSG_WHISPER" then
        -- Check for matching Emote
		local msg, author2 = ...
		local msg2 = "Whispered: " .. string.lower(msg)
		local author = string.gsub(author2, "%-.*", "")
		local author3 = string.lower(author)
		local cmdFound = false
		local startPos, endPos = string.find(msg, "!")
		local isPartyFull = MaxPartySizeCheck()
		if debugLevel >= 1 then
			print("Whisper received")
		end
			if string.find(msg, "!", 1, true) then
				if debugLevel >= 1 then
					print("Possible whisper command found from " .. author2 .. ": ! found within " .. msg)
				end

				if startPos then
					if debugLevel >= 3 then
					print("startPos listed as: " .. tostring(startPos))
					end
					if startPos == 1 or string.sub(msg, startPos - 1, startPos - 1) == " " then
						if debugLevel >= 1 then
							print("found at start of message, setting cmdFound to true")
						end
						cmdFound = true
					else
						if debugLevel >= 1 then
							print("! is not at the start of the sentence, ignoring")
						end	
					end
				end
			end

			if cmdFound == true then
				for i, v in ipairs(ProEnchantersOptions.whispertriggers) do
					for cmd, rmsg in pairs(v) do
						local wmsg = tostring(rmsg)
						if debugLevel >= 1 then
						print("comparing: " .. msg .. " to " .. cmd)
						end
							if tostring(msg) == tostring(cmd) then
								if debugLevel >= 1 then
									print("Found matching !command")
								end	
								for itemID, _ in string.gmatch(wmsg, "%[(%d+)%]") do
									if debugLevel >= 1 then
										print("itemID returned as " .. itemID)
									end
									local newitemLink = select(2, GetItemInfo(itemID))
									if debugLevel >= 1 then
										print(newitemLink)
									end
									-- Escape the square brackets in the replacement pattern
									wmsg = string.gsub(wmsg, "%[" .. itemID .. "%]", newitemLink)
								end
								SendChatMessage(wmsg, "WHISPER", nil, author2)
								return
							end
					end
				end
				if debugLevel >= 1 then
					print("No matching command found, continuing to possible enchant lookup")
				end
				for key, name in pairs(EnchantsName) do
				local name2 = string.lower(name)
				local enchantlookup = "!" .. name2
				local enchantlookup2 = string.gsub(enchantlookup, " ", "")
				local msglower = string.lower(msg)
				local msglower2 = string.gsub(msglower, " ", "")
					if enchantlookup2 == msglower2 then
						if ProEnchantersOptions.filters[key] == true then
							local enchName, enchStats = GetEnchantName(key)
							local matsReq = ProEnchants_GetReagentList(key)
							local msgReq = enchName .. enchStats .. " Mats Required: " .. matsReq
							SendChatMessage(msgReq, "WHISPER", nil, author2)
							return
						elseif ProEnchantersOptions.filters[key] == false then
							local enchName, enchStats = GetEnchantName(key)
							local enchType = string.match(enchName, "%-%s*(.+)")
							local enchTypeSpecific = string.match(enchName, ".+%s(%w+)$")
							local enchSlot = string.match(enchName, "^Enchant%s+([%w%s-]-)%s-%s")
							local recommendations = {} -- Use a table to store unique recommendations
						
							for k, v in pairs(EnchantsName) do
								if string.find(v, enchSlot, 1, true) then
									if string.find(v, enchTypeSpecific, 1, true) then
									local eName, eStats = GetEnchantName(k)
									local enchKey = k
									local eType = string.match(eName, "%-%s*(.+)")
									local recommendation = eType .. eStats -- Create a unique identifier for the recommendation
										if not recommendations[recommendation] and ProEnchantersOptions.filters[k] == true then
										-- Only add if not already in the table and filter is true
											recommendations[recommendation] = eStats
										end
									end
								end
							end
							
								local sortableRecommendations = {}
								for rec, k in pairs(recommendations) do
									local numPart = tonumber(k:match("(%d+)"))
									if numPart then
										table.insert(sortableRecommendations, {key = numPart, rec = rec})
									end
								end

								-- Sort the table based on the numerical part of the enchKey
								table.sort(sortableRecommendations, function(a, b) return a.key > b.key end)

								-- Now, build your enchRecommends string in sorted order
								local enchRecommends = ""
								for _, v in ipairs(sortableRecommendations) do
									if enchRecommends == "" then
										enchRecommends = v.rec
									else
										enchRecommends = enchRecommends .. ", " .. v.rec
									end
								end
							if enchRecommends ~= "" then
								local msgReq = enchName .. enchStats .. " not available, here's some similar enchants for " .. enchSlot .. "'s:"
								local msgRecs = enchRecommends
								SendChatMessage(msgReq, "WHISPER", nil, author2)
								SendChatMessage(msgRecs, "WHISPER", nil, author2)
								--C_Timer.After(.2, function()  end)
							else
								local msgReq = enchName .. enchStats .. " not available and I couldn't find anything similar, would you like something else?"
								SendChatMessage(msgReq, "WHISPER", nil, author2)
							end
						else
							local msgReq = "No Enchant with that name found, please make sure you're using the specific enchant name such as !enchant chest - lesser stats"
							SendChatMessage(msgReq, "WHISPER", nil, author2)
						end
						cmdFound = true
						return
					end
				end
				cmdFound = false
			end

				if debugLevel >= 1 then
					print("cmdFound is false, continuing")
				end	

			if cmdFound == false then
				for _, tword in pairs(ProEnchantersOptions.invwords) do
				local check1 = false
				local check2 = false
				local startPos, endPos = string.find(msg2, tword)
				if string.find(msg2, tword, 1, true) then
					if debugLevel >= 1 then
						print(tword .. " found in msg: " .. msg2)
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
								PEPlayerInvited[playerName] = msg2
								PlaySound(SOUNDKIT.MAP_PING)
							--elseif AutoInviteFlag == false then
							--	StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
							--end
						elseif playerName and ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
							--if AutoInviteFlag == true then
								InviteUnitPEAddon(author2)
								PlaySound(SOUNDKIT.MAP_PING)
								PEPlayerInvited[playerName] = msg2
							--elseif AutoInviteFlag == false then
							--	StaticPopup_Show("INVITE_PLAYER_POPUP", playerName, msg).data = {playerName, msg, author2}
							--end
						end
					elseif isPartyFull == true then
						PlaySound(SOUNDKIT.MAP_PING)
						local playerName = author3
						PEPlayerInvited[playerName] = msg2
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
        -- Check for matching Emote
		local msg, author2 = ...
		local msg2 = "Whispered: " .. string.lower(msg)
		local author = string.gsub(author2, "%-.*", "")
		local author3 = string.lower(author)
		local cmdFound = false
		local startPos, endPos = string.find(msg, "!")
		local isPartyFull = MaxPartySizeCheck()
		if debugLevel >= 1 then
			print("Whisper received")
		end
			if string.find(msg, "!", 1, true) then
				if debugLevel >= 1 then
					print("Possible whisper command found from self: ! found within " .. msg)
				end

				if startPos then
					if debugLevel >= 3 then
					print("startPos listed as: " .. tostring(startPos))
					end
					if startPos == 1 or string.sub(msg, startPos - 1, startPos - 1) == " " then
						if debugLevel >= 1 then
							print("found at start of message, setting cmdFound to true")
						end
						cmdFound = true
					else
						if debugLevel >= 1 then
							print("! is not at the start of the sentence, ignoring")
						end	
					end
				end
			end

			if cmdFound == true then
				for i, v in ipairs(ProEnchantersOptions.whispertriggers) do
					for cmd, rmsg in pairs(v) do
						local wmsg = tostring(rmsg)
						if debugLevel >= 1 then
						print("comparing: " .. msg .. " to " .. cmd)
						end
							if tostring(msg) == tostring(cmd) then
								if debugLevel >= 1 then
									print("Found matching !command")
								end	
								for itemID, _ in string.gmatch(wmsg, "%[(%d+)%]") do
									if debugLevel >= 1 then
										print("itemID returned as " .. itemID)
									end

									local newitemLink = select(2, GetItemInfo(itemID))

									if debugLevel >= 1 then
										print(newitemLink)
									end
									-- Escape the square brackets in the replacement pattern
									wmsg = string.gsub(wmsg, "%[" .. itemID .. "%]", newitemLink)
								end
								SendChatMessage(wmsg, "WHISPER", nil, author2)
								return
							end
					end
				end
				if debugLevel >= 1 then
					print("No matching command found, continuing to possible enchant lookup")
				end
				for key, name in pairs(EnchantsName) do
				local name2 = string.lower(name)
				local enchantlookup = "!" .. name2
				local enchantlookup2 = string.gsub(enchantlookup, " ", "")
				local msglower = string.lower(msg)
				local msglower2 = string.gsub(msglower, " ", "")
					if enchantlookup2 == msglower2 then
						if ProEnchantersOptions.filters[key] == true then
							local enchName, enchStats = GetEnchantName(key)
							local matsReq = ProEnchants_GetReagentList(key)
							local msgReq = enchName .. enchStats .. " Mats Required: " .. matsReq
							SendChatMessage(msgReq, "WHISPER", nil, author2)
							return
						elseif ProEnchantersOptions.filters[key] == false then
							local enchName, enchStats = GetEnchantName(key)
							local enchType = string.match(enchName, "%-%s*(.+)")
							local enchTypeSpecific = string.match(enchName, ".+%s(%w+)$")
							local enchSlot = string.match(enchName, "^Enchant%s+([%w%s-]-)%s-%s")
							local recommendations = {} -- Use a table to store unique recommendations
						
							for k, v in pairs(EnchantsName) do
								if string.find(v, enchSlot, 1, true) then
									if string.find(v, enchTypeSpecific, 1, true) then
									local eName, eStats = GetEnchantName(k)
									local enchKey = k
									local eType = string.match(eName, "%-%s*(.+)")
									local recommendation = eType .. eStats -- Create a unique identifier for the recommendation
										if not recommendations[recommendation] and ProEnchantersOptions.filters[k] == true then
										-- Only add if not already in the table and filter is true
											recommendations[recommendation] = eStats
										end
									end
								end
							end
							
								local sortableRecommendations = {}
								for rec, k in pairs(recommendations) do
									local numPart = tonumber(k:match("(%d+)"))
									if numPart then
										table.insert(sortableRecommendations, {key = numPart, rec = rec})
									end
								end

								-- Sort the table based on the numerical part of the enchKey
								table.sort(sortableRecommendations, function(a, b) return a.key > b.key end)

								-- Now, build your enchRecommends string in sorted order
								local enchRecommends = ""
								for _, v in ipairs(sortableRecommendations) do
									if enchRecommends == "" then
										enchRecommends = v.rec
									else
										enchRecommends = enchRecommends .. ", " .. v.rec
									end
								end
							if enchRecommends ~= "" then
								local msgReq = enchName .. enchStats .. " not available, here's some similar enchants for " .. enchSlot .. "'s:"
								local msgRecs = enchRecommends
								SendChatMessage(msgReq, "WHISPER", nil, author2)
								SendChatMessage(msgRecs, "WHISPER", nil, author2)
								--C_Timer.After(.2, function()  end)
							else
								local msgReq = enchName .. enchStats .. " not available and I couldn't find anything similar, would you like something else?"
								SendChatMessage(msgReq, "WHISPER", nil, author2)
							end
						else
							local msgReq = "No Enchant with that name found, please make sure you're using the specific enchant name such as !enchant chest - lesser stats"
							SendChatMessage(msgReq, "WHISPER", nil, author2)
						end
						cmdFound = true
						return
					end
				end
				cmdFound = false
			end

		if debugLevel >= 1 then
			print("cmdFound is false, end of check for sent whisper")
		end	
	end
end


-- Add a new line to the trade history for a specific customer
function AddTradeLine(customerName, tradeLine)
	local customerName = string.lower(customerName)
    if not ProEnchantersTradeHistory[customerName] then
        ProEnchantersTradeHistory[customerName] = {}
		CreateCusWorkOrder(customerName)
    end
	local tradeLine = string.gsub(tradeLine, "%[", "") -- Remove '['
	tradeLine = string.gsub(tradeLine, "%]", "")
    table.insert(ProEnchantersTradeHistory[customerName], tradeLine)
    UpdateTradeHistory(customerName)
end

function AddRequestedEnchant(customerName, reqEnchant)
	local customerName = string.lower(customerName)
    if not ProEnchantersTradeHistory[customerName] then
        ProEnchantersTradeHistory[customerName] = {}
        CreateCusWorkOrder(customerName)
    end
    local reqEnchantName = EnchantsName[reqEnchant]
    reqEnchantName = LIGHTSEAGREEN .. "REQ ENCH: " .. ColorClose .. "|cFFDA70D6|Haddon:ProEnchanters:" .. reqEnchant .. ":" .. customerName .. ":1234|h[" .. reqEnchantName .. "]|h|r"
    table.insert(ProEnchantersTradeHistory[customerName], reqEnchantName)
	
    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            -- Ensure that Enchants is initialized as a table
            frameInfo.Enchants = frameInfo.Enchants or {}

            -- Now safely add the enchantment
            table.insert(frameInfo.Enchants, reqEnchant)
            break
        end
    end

    UpdateTradeHistory(customerName)
end

function RemoveRequestedEnchant(customerName, reqEnchant)
	local customerName = string.lower(customerName)
    if not ProEnchantersTradeHistory[customerName] then
        ProEnchantersTradeHistory[customerName] = {}
        CreateCusWorkOrder(customerName)
    end
    --[[local reqEnchantName = EnchantsName[reqEnchant]
    reqEnchantName = TOMATO .. "REMOVE REQ ENCH: " .. ColorClose .. ORCHID .. reqEnchantName .. ColorClose
    table.insert(ProEnchantersTradeHistory[customerName], reqEnchantName)]]
	
	local reqEnchantName = EnchantsName[reqEnchant] -- Assuming this is defined somewhere

local count = #ProEnchantersTradeHistory[customerName]

for i = count, 1, -1 do -- Iterate backwards to safely remove items
    local entry = ProEnchantersTradeHistory[customerName][i]
    if string.find(entry, reqEnchantName, 1, true) then
		if string.find(entry, "REQ ENCH:", 1, true) then
       		table.remove(ProEnchantersTradeHistory[customerName], i)
			break
		end
    end
end

    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            -- Ensure that Enchants is initialized as a table
            frameInfo.Enchants = frameInfo.Enchants or {}

            -- Find the index of the enchantment to remove
            local indexToRemove = nil
            for index, enchInfo in ipairs(frameInfo.Enchants) do
                if enchInfo == reqEnchant then
                    indexToRemove = index
                    break
                end
            end

            -- If the enchantment was found, remove it
            if indexToRemove then
                table.remove(frameInfo.Enchants, indexToRemove)
            end
        end
    end
	UpdateTradeHistory(customerName)
end
function FinishedEnchant(customerName, reqEnchant)
	local customerName = string.lower(customerName)
    if not ProEnchantersTradeHistory[customerName] then
        ProEnchantersTradeHistory[customerName] = {}
        CreateCusWorkOrder(customerName)
    end

    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            -- Ensure that tables are initialized
            frameInfo.Enchants = frameInfo.Enchants or {}
			frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
       		frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}

            -- Find the index of the enchantment to remove
            local indexToRemove = nil
			local itemsRemoved = false
			-- Check if the Enchants table is empty
			if next(frameInfo.Enchants) ~= nil then
           		for index, enchInfo in ipairs(frameInfo.Enchants) do
                	if enchInfo == reqEnchant then
                	    indexToRemove = index
                	    break
					else
                	end
				end
            end

			if indexToRemove then
				local enchCompleted = frameInfo.Enchants[indexToRemove]
				local reqQuantity = 1
				local matsUsed = ProEnchants_GetReagentList(enchCompleted, reqQuantity)
				for quantity, material in string.gmatch(matsUsed, "(%d+)x ([^,]+)") do
					quantity = tonumber(quantity)
					local itemId = material:match(":(%d+):")
					local material = select(2, GetItemInfo(itemId))
					if frameInfo.ItemsTradedIn[material] ~= nil then
							local tradedQuantity = frameInfo.ItemsTradedIn[material]
							local newQuantity = tradedQuantity - quantity

						if newQuantity <= 0 then
							frameInfo.ItemsTradedIn[material] = nil  -- Remove the item if quantity becomes 0 or negative
					
							local deficitQuantity = math.abs(newQuantity)
							if deficitQuantity > 0 then  -- Handle case where tradeQuantity exceeds currentQuantity
								frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
								frameInfo.ItemsTradedOut[material] = (frameInfo.ItemsTradedOut[material] or 0) + deficitQuantity
							end
						else
							frameInfo.ItemsTradedIn[material] = newQuantity  -- Update with the new quantity
						end
					elseif frameInfo.ItemsTradedOut[material] ~= nil then
						local currentQuantity = frameInfo.ItemsTradedOut[material]
						local newTradeQuantity = quantity
						local newQuantity = currentQuantity + newTradeQuantity
						frameInfo.ItemsTradedOut[material] = newQuantity
					else
						frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
						frameInfo.ItemsTradedOut[material] = quantity
					end
				end
				itemsRemoved = true
			else
				local enchCompleted = reqEnchant
				local reqQuantity = 1
				local matsUsed = ProEnchants_GetReagentList(enchCompleted, reqQuantity)
				for quantity, material in string.gmatch(matsUsed, "(%d+)x ([^,]+)") do
					quantity = tonumber(quantity)
					local itemId = material:match(":(%d+):")
					local material = select(2, GetItemInfo(itemId))
					if frameInfo.ItemsTradedIn[material] ~= nil then
							local tradedQuantity = frameInfo.ItemsTradedIn[material]
							local newQuantity = tradedQuantity - quantity

						if newQuantity <= 0 then
							frameInfo.ItemsTradedIn[material] = nil  -- Remove the item if quantity becomes 0 or negative
					
							local deficitQuantity = math.abs(newQuantity)
							if deficitQuantity > 0 then  -- Handle case where tradeQuantity exceeds currentQuantity
								frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
								frameInfo.ItemsTradedOut[material] = (frameInfo.ItemsTradedOut[material] or 0) + deficitQuantity
							end
						else
							frameInfo.ItemsTradedIn[material] = newQuantity  -- Update with the new quantity
						end
					elseif frameInfo.ItemsTradedOut[material] ~= nil then
						local currentQuantity = frameInfo.ItemsTradedOut[material]
						local newTradeQuantity = quantity
						local newQuantity = currentQuantity + newTradeQuantity
						frameInfo.ItemsTradedOut[material] = newQuantity
					else
						frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
						frameInfo.ItemsTradedOut[material] = quantity
					end
				end
			end
            -- If the enchantment was found, remove it
            if indexToRemove and itemsRemoved == true then
                table.remove(frameInfo.Enchants, indexToRemove)
            end
        end
    end
	UpdateTradeHistory(customerName)
end

function RemoveAllRequestedEnchant(customerName)
	local customerName = string.lower(customerName)
    if not ProEnchantersTradeHistory[customerName] then
        ProEnchantersTradeHistory[customerName] = {}
        CreateCusWorkOrder(customerName)
    end

    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            -- Ensure that Enchants is initialized as a table
            frameInfo.Enchants = frameInfo.Enchants or {}
            -- Find the index of the enchantment to remove
            local count1 = #ProEnchantersTradeHistory[customerName]
			local count2 = #frameInfo.Enchants
			local entry = ""
			local reqEnchantName = ""
			local enchInfo = ""
                for i = count1, 1, -1 do -- Iterate backwards to safely remove items
					enchInfo = frameInfo.Enchants[count2]
                    entry = ProEnchantersTradeHistory[customerName][i]
					reqEnchantName = EnchantsName[enchInfo]
						if count2 < 1 then
							break
						end
					count2 = count2 - 1
                    if string.find(entry, reqEnchantName, 1, true) then
                        if string.find(entry, "REQ ENCH:", 1, true) then
                               table.remove(ProEnchantersTradeHistory[customerName], i)
                        end
                    end
                end
            frameInfo.Enchants = {}
        end
    end
	UpdateTradeHistory(customerName)
end

--[[function RemoveAllRequestedEnchant(customerName)
    if not ProEnchantersTradeHistory[customerName] then
        ProEnchantersTradeHistory[customerName] = {}
        CreateCusWorkOrder(customerName)
    end

    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            -- Ensure that Enchants is initialized as a table
            frameInfo.Enchants = frameInfo.Enchants or {}
            -- Find the index of the enchantment to remove
            for _, enchInfo in ipairs(frameInfo.Enchants) do
				local reqEnchantName = EnchantsName[enchInfo]
    			reqEnchantName = TOMATO .. "REMOVE REQ ENCH: " .. ColorClose .. ORCHID .. reqEnchantName .. ColorClose
   				table.insert(ProEnchantersTradeHistory[customerName], reqEnchantName)
            end
            frameInfo.Enchants = {}
        end
    end
	UpdateTradeHistory(customerName)
end]]

-- Get name of Ench
function GetEnchantName(reqEnchant)
	local enchName = EnchantsName[reqEnchant]
	local enchStats = EnchantsStats[reqEnchant]
	return enchName, enchStats
end


-- Function to get the trade history edit box for a given customer
function GetTradeHistoryEditBox(customerName)
	local customerName = string.lower(customerName)
    for _, frameInfo in pairs(WorkOrderFrames) do
        if not frameInfo.Completed then
            local frameCustomerName = frameInfo.Frame.customerName -- Assuming each frame has a 'customerName' property
            if frameCustomerName == customerName then
                return frameInfo.Frame.tradeHistoryEditBox -- Assuming each frame has a 'tradeHistoryEditBox' property
            end
        end
    end
    return nil -- Return nil if no matching frame is found
end


-- Function to update trade history in EditBox
function UpdateTradeHistory(customerName)
	local customerName = string.lower(customerName)
    local tradeHistoryText = ""
    for _, frameInfo in pairs(WorkOrderFrames) do
        if frameInfo.Frame.customerName == customerName and not frameInfo.Completed then
			if ProEnchantersTradeHistory[customerName] then
				-- Iterate from the end to the start of the history
				for i = #ProEnchantersTradeHistory[customerName], 1, -1 do
					local line = ProEnchantersTradeHistory[customerName][i]
					if i == #ProEnchantersTradeHistory[customerName] then
						tradeHistoryText = line  -- Start with the last (newest) line
					else
						tradeHistoryText = tradeHistoryText .. "\n" .. line  -- Prepend each line
					end
				end
			end
			frameInfo.Frame.tradeHistoryEditBox:SetText(tradeHistoryText)
            break  -- Exit the loop once the correct frame is updated
        end
    end
end


function UpdateGoldTraded()
	if GoldTraded < 0 then
		local deficitAmount = -GoldTraded
		ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetText("Gold Sent: " .. GetMoneyString(deficitAmount))
	else
    ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetText("Gold Received: " .. GetMoneyString(GoldTraded))
	end
end

function PEgetItemIDFromLink(itemLink)
	if (not itemLink
		or type(itemLink) ~= "string"
		or itemLink == ""
	) then
		return false;
	end

	local _, itemID = strsplit(":", itemLink);
	itemID = tonumber(itemID);

	if (not itemID) then
		return false;
	end

	return itemID;
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
		if ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
			if not ProEnchantersTradeHistory[customerName] then
            CreateCusWorkOrder(customerName)
				if ProEnchantersCustomerNameEditBox:GetText() == nil or ProEnchantersCustomerNameEditBox:GetText() == "" then
				local capCustomerName = CapFirstLetter(customerName)
				ProEnchantersCustomerNameEditBox:SetText(capCustomerName)
				end
			elseif ProEnchantersTradeHistory[customerName] then
				for id, frameInfo in pairs(WorkOrderFrames) do
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
			PEtradeWhoItems.player[slot] = {link = playerItemLink, quantity = playerQuantity, enchant = playerEnchant}
			ItemsTraded = true
		elseif slot < 7 then
			PEtradeWhoItems.player[slot] = {link = playerItemLink, quantity = playerQuantity}
			ItemsTraded = true
		end

		-- Target Items Traded
		if targetEnchant ~= nil then
			PEtradeWhoItems.target[slot] = {link = targetItemLink, quantity = targetQuantity, enchant = targetEnchant}
			ItemsTraded = true
		elseif slot < 7 then
			PEtradeWhoItems.target[slot] = {link = targetItemLink, quantity = targetQuantity}
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
			PEtradeWhoItems.player[slot] = {link = playerItemLink, quantity = playerQuantity, enchant = playerEnchant}
			ItemsTraded = true
		elseif slot < 7 then
			PEtradeWhoItems.player[slot] = {link = playerItemLink, quantity = playerQuantity}
			ItemsTraded = true
		end

		-- Target Items Traded
		if slot < 7 then
		PEtradeWhoItems.target[slot] = {link = targetItemLink, quantity = targetQuantity}
		ItemsTraded = true
		elseif targetEnchant ~= nil then
		PEtradeWhoItems.target[slot] = {link = targetItemLink, quantity = targetQuantity, enchant = targetEnchant}
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

function PEdoTrade()
	local traded = false
	local customerName = PEtradeWho
	customerName = string.lower(customerName)
	local Time = date()

	-- Checks for if Traded
	if PlayerMoney > 0 or TargetMoney > 0 then
		traded = true
	end

	if ItemsTraded == true then
		traded = true
	end


	if traded then
		-- Trade Log Start Line
		-- AddTradeLine(customerName, IVORY .. "-- Trade at " .. Time .. " --" .. ColorClose)
		local OnTheClock = false
		if not ProEnchantersTradeHistory[customerName] then
            CreateCusWorkOrder(customerName)
        end
		if ProEnchantersOptions["WorkWhileClosed"] == true then
			OnTheClock = true
		elseif ProEnchantersWorkOrderFrame and ProEnchantersWorkOrderFrame:IsVisible() then
			OnTheClock = true
		end

		if PlayerMoney > 0 then
		AddTradeLine(customerName, RED .. "OUT: " .. ColorClose .. GetCoinText(PlayerMoney))
		GoldTraded = GoldTraded - PlayerMoney
		UpdateTradeHistory(customerName)
		end

		if TargetMoney > 0 then
		AddTradeLine(customerName, YELLOW .. "IN: " .. ColorClose .. GetCoinText(TargetMoney))
		GoldTraded = GoldTraded + TargetMoney
		UpdateTradeHistory(customerName)
			if OnTheClock == true then
			DoEmote("THANK", PEtradeWho)
				if ProEnchantersOptions["TipMsg"] then
					local tip = tostring(GetCoinText(TargetMoney))
					local tipMsg = ProEnchantersOptions["TipMsg"]
					local capPlayerName = CapFirstLetter(PEtradeWho)
					local newTipMsg1 = string.gsub(tipMsg, "CUSTOMER", capPlayerName)
					local newTipMsg2 = string.gsub(newTipMsg1, "MONEY", tip)
					--string.gsub(meResponseSender, "PLAYER", function(mePlayer2) table.insert(mePlayer, mePlayer2) return sender end)
					if tipMsg == "" then
						print(PEtradeWho .. " tipped " .. tip)
					else
						if CheckIfPartyMember(PEtradeWho) == true then
							SendChatMessage(newTipMsg2, IsInRaid() and "RAID" or "PARTY")
						else
							SendChatMessage(newTipMsg2,"WHISPER", nil, PEtradeWho)
						end
					end
				else
					local tip = tostring(GetCoinText(TargetMoney))
					local capPlayerName = CapFirstLetter(PEtradeWho)
					if CheckIfPartyMember(PEtradeWho) == true then
						SendChatMessage("Thanks for the " .. tip ..  " tip " .. capPlayerName .. " <3", IsInRaid() and "RAID" or "PARTY")
					else
						SendChatMessage("Thanks for the " .. tip ..  " tip " .. capPlayerName .. " <3", "WHISPER", nil, PEtradeWho)
					end
				end
			end
		end

	if ItemsTraded == true then

			-- Add Lines for Self traded items
		if PEtradeWhoItems.player then
			for slot, item in pairs(PEtradeWhoItems.player) do
				if item and item.link then
					if item.enchant then
						AddTradeLine(customerName, MAGENTA .. "ENCH: " .. ColorClose .. item.enchant)
						AddTradeLine(customerName, MAGENTA .. "On My: " .. ColorClose .. item.link)
					elseif item.link then
						AddTradeLine(customerName, LIGHTYELLOW .. "OUT: " .. item.quantity .. "x " .. ColorClose .. item.link)
						for _, frameInfo in pairs(WorkOrderFrames) do
							if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
								frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
								frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}
								if frameInfo.ItemsTradedIn[item.link] ~= nil then
									local currentQuantity = frameInfo.ItemsTradedIn[item.link]
									local newTradeQuantity = item.quantity
									local newQuantity = currentQuantity - newTradeQuantity
									
									if newQuantity <= 0 then
										frameInfo.ItemsTradedIn[item.link] = nil  -- Remove the item if quantity becomes 0 or negative
										
										local deficitQuantity = math.abs(newQuantity)
										if deficitQuantity > 0 then  -- Handle case where tradeQuantity exceeds currentQuantity
											frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
											frameInfo.ItemsTradedOut[item.link] = (frameInfo.ItemsTradedOut[item.link] or 0) + deficitQuantity
										end
									else
										frameInfo.ItemsTradedIn[item.link] = newQuantity  -- Update with the new quantity
									end
								elseif frameInfo.ItemsTradedOut[item.link] ~= nil then
									local currentQuantity = frameInfo.ItemsTradedOut[item.link]
									local newTradeQuantity = item.quantity
									local newQuantity = currentQuantity + newTradeQuantity
									frameInfo.ItemsTradedOut[item.link] = newQuantity
								else
									frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
									frameInfo.ItemsTradedOut[item.link] = item.quantity
								end
							end
						end
					end
				end
			end
		end

			-- Add Lines for Target traded items
		if PEtradeWhoItems.target then
			for slot, item in pairs(PEtradeWhoItems.target) do
				if item and item.link then
					if item.enchant then
						--[[for id, frameInfo in pairs(WorkOrderFrames) do
							local lowerFrameCheck = string.lower(frameInfo.Frame.customerName)
							local lowerCusName = string.lower(customerName)
								if lowerFrameCheck == lowerCusName and not frameInfo.Completed then
									for _, enchantID in ipairs(frameInfo.Enchants) do
										local enchantName = EnchantsName[enchantID]
											if enchantName == item.enchant then
												FinishedEnchant(customerName, enchantID)
											end
										end
									end
								end]]
							local enchantId = ""
							for key, name in pairs(EnchantsName) do
								if name == item.enchant then
									enchantId = key
								end
							end
						FinishedEnchant(customerName, enchantId)
						AddTradeLine(customerName, MAGENTA .. "ENCH: " .. ColorClose .. item.enchant .. MAGENTA .. " ON: " .. ColorClose .. item.link)
						--AddTradeLine(customerName, MAGENTA .. "ON: " .. ColorClose .. item.link)
					else
						AddTradeLine(customerName, LIGHTYELLOW .. "IN: " .. item.quantity .. "x " .. ColorClose .. item.link)
						for _, frameInfo in pairs(WorkOrderFrames) do
							if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
								frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
								frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}
								if frameInfo.ItemsTradedOut[item.link] ~= nil then
									local currentQuantity = frameInfo.ItemsTradedOut[item.link]
									local newTradeQuantity = item.quantity
									local newQuantity = currentQuantity - newTradeQuantity
									
									if newQuantity <= 0 then
										frameInfo.ItemsTradedOut[item.link] = nil  -- Remove the item if quantity becomes 0 or negative
										
										local deficitQuantity = math.abs(newQuantity)
										if deficitQuantity > 0 then  -- Handle case where tradeQuantity exceeds currentQuantity
											frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}
											frameInfo.ItemsTradedIn[item.link] = (frameInfo.ItemsTradedIn[item.link] or 0) + deficitQuantity
										end
									else
										frameInfo.ItemsTradedOut[item.link] = newQuantity  -- Update with the new quantity
									end
								elseif frameInfo.ItemsTradedIn[item.link] ~= nil then
									local currentQuantity = frameInfo.ItemsTradedIn[item.link]
									local newTradeQuantity = item.quantity
									local newQuantity = currentQuantity + newTradeQuantity
									frameInfo.ItemsTradedIn[item.link] = newQuantity
								else
									frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}
									frameInfo.ItemsTradedIn[item.link] = item.quantity
								end
							end
						end
					end
				end
			end
		end
	end
end
	-- Trade Log End Line
	-- AddTradeLine(customerName, IVORY .. "-- Trade Completed --" .. ColorClose)
	PEresetCurrentTradeData()
	UpdateGoldTraded()
end
---- OnTradeEventCurrentEnd


function PEresetCurrentTradeData()
	PlayerMoney, TargetMoney, PEtradeWho = 0, 0, ""
	PEtradeWhoItems = {player = {}, target = {}}
    ItemsTraded = false
    -- reset other trade-related variables as needed
end

-- Enable close on Escape pressed
tinsert(UISpecialFrames, "ProEnchantersWorkOrderFrame")
