--Color for Frames
local OpacityAmount = 0.5

local TopBarColor = {22/255, 26/255, 48/255}
local r1, g1, b1 = unpack(TopBarColor)
local TopBarColorOpaque = {r1, g1, b1, 1}
local TopBarColorTrans = {r1, g1, b1, OpacityAmount}

local SecondaryBarColor = {49/255, 48/255, 77/255}
local r2, g2, b2 = unpack(SecondaryBarColor)
local SecondaryBarColorOpaque = {r2, g2, b2, 1}
local SecondaryBarColorTrans = {r2, g2, b2, OpacityAmount}

local MainWindowBackground = {22/255, 26/255, 48/255}
local r3, g3, b3 = unpack(MainWindowBackground)
local MainWindowBackgroundOpaque = {r3, g3, b3, 1}
local MainWindowBackgroundTrans = {r3, g3, b3, OpacityAmount}

local BottomBarColor = {22/255, 26/255, 48/255}
local r4, g4, b4 = unpack(BottomBarColor)
local BottomBarColorOpaque = {r4, g4, b4, 1}
local BottomBarColorTrans = {r4, g4, b4, OpacityAmount}

local EnchantsButtonColor = {22/255, 26/255, 48/255}
local r5, g5, b5 = unpack(EnchantsButtonColor)
local EnchantsButtonColorOpaque = {r5, g5, b5, 1}
local EnchantsButtonColorTrans = {r5, g5, b5, OpacityAmount}

local EnchantsButtonColorInactive = {71/255, 71/255, 71/255}
local r6, g6, b6 = unpack(EnchantsButtonColorInactive)
local EnchantsButtonColorInactiveOpaque = {r6, g6, b6, 1}
local EnchantsButtonColorInactiveTrans = {r6, g6, b6, OpacityAmount}

local BorderColor = {2/255, 2/255, 2/255}
local r7, g7, b7 = unpack(BorderColor)
local BorderColorOpaque = {r7, g7, b7, 1}
local BorderColorTrans = {r7, g7, b7, OpacityAmount}

local MainButtonColor = {22/255, 26/255, 48/255}
local r8, g8, b8 = unpack(MainButtonColor)
local MainButtonColorOpaque = {r8, g8, b8, 1}
local MainButtonColorTrans = {r8, g8, b8, OpacityAmount}

local SettingsWindowBackground = {49/255, 48/255, 77/255}
local r9, g9, b9 = unpack(SettingsWindowBackground)
local SettingsWindowBackgroundOpaque = {r9, g9, b9, 1}
local SettingsWindowBackgroundTrans = {r9, g9, b9, OpacityAmount}

local ScrollBarColors = {49/255, 48/255, 77/255}
local r10, g10, b10 = unpack(ScrollBarColors)
local ButtonStandardAndThumb = {r10, g10, b10, 1}
local r10P, r10DH = ((r10*255)/4)/255, ((r10*255)/2)/255
local g10P, g10DH = ((g10*255)/4)/255, ((g10*255)/2)/255
local b10P, b10DH = ((b10*255)/4)/255, ((b10*255)/2)/255
local ButtonPushed = {r10 + r10P, g10 + g10P, b10 + b10P, 1}
local ButtonDisabled = {r10 - r10DH, g10 - g10DH, b10 - g10DH, 0.5}
local ButtonHighlight = {r10 + r10DH, g10 + g10DH, b10 + b10DH, 1}




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

	local backdrop = {
        edgeFile = "Interface\\Buttons\\WHITE8x8", -- Path to a 1x1 white pixel texture
        edgeSize = 1, -- Border thickness
    }

	-- Apply the backdrop to the WorkOrderFrame
    ColorsFrame:SetBackdrop(backdrop)
    ColorsFrame:SetBackdropBorderColor(unpack(BorderColorOpaque))

    ColorsFrame:Hide()

    -- Create a full background texture
    local bgTexture = ColorsFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetColorTexture(unpack(SettingsWindowBackgroundOpaque))  -- Set RGBA values for your preferred color and alpha
	bgTexture:SetSize(400, 375)
    bgTexture:SetPoint("TOP", ColorsFrame, "TOP", 0, -25)

    -- Create a title background
    local titleBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
    titleBg:SetColorTexture(unpack(TopBarColorOpaque))  -- Set RGBA values for your preferred color and alpha
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
	instructionsHeader:SetText("~How to change colors~\nEach line below has a Red Green Blue value set between 0-255\nOpacity is a percentage (0-100 percent)\nChange the numbers and then do a /reload")
	instructionsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	-- Extract Colors from Table
	local TopBarColorR, TopBarColorG, TopBarColorB = unpack(ProEnchantersOptions.Colors.TopBarColor)
    local SecondaryBarColorR, SecondaryBarColorG, SecondaryBarColorB = unpack(ProEnchantersOptions.Colors.SecondaryBarColor)
    local MainWindowBackgroundR, MainWindowBackgroundG, MainWindowBackgroundB = unpack(ProEnchantersOptions.Colors.MainWindowBackground)
    local BottomBarColorR, BottomBarColorG, BottomBarColorB = unpack(ProEnchantersOptions.Colors.BottomBarColor)
    local EnchantsButtonColorR, EnchantsButtonColorG, EnchantsButtonColorB = unpack(ProEnchantersOptions.Colors.EnchantsButtonColor)
    local EnchantsButtonColorInactiveR, EnchantsButtonColorInactiveG, EnchantsButtonColorInactiveB = unpack(ProEnchantersOptions.Colors.EnchantsButtonColorInactive)
    local BorderColorR, BorderColorG, BorderColorB = unpack(ProEnchantersOptions.Colors.BorderColor)
    local MainButtonColorR, MainButtonColorG, MainButtonColorB = unpack(ProEnchantersOptions.Colors.MainButtonColor)
    local SettingsWindowBackgroundR, SettingsWindowBackgroundG, SettingsWindowBackgroundB = unpack(ProEnchantersOptions.Colors.SettingsWindowBackground)
    local ScrollBarColorsR, ScrollBarColorsG, ScrollBarColorsB = unpack(ProEnchantersOptions.Colors.ScrollBarColors)
    local OpacityAmountR = ProEnchantersOptions.Colors.OpacityAmount

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
	colorsExamples:SetColorTexture(200, 200, 200, 1)  -- Set RGBA values for your preferred color and alpha
	colorsExamples:SetSize(70, 350)  -- Adjust size as needed
	colorsExamples:SetPoint("TOPLEFT", titleHeader, "TOPLEFT", 165, -90)

	-- Color Examples

    local TopBarColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	TopBarColorExample:SetFontObject("GameFontHighlight")
	TopBarColorExample:SetPoint("TOPLEFT", colorsExamples, "TOPLEFT", 6, -8)
	local TopBarColorHex = RGBToWoWColorCode(TopBarColorR, TopBarColorG, TopBarColorB)
	TopBarColorExample:SetText(TopBarColorHex .. "EXAMPLE" .. ColorClose)
	TopBarColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

    local SecondaryBarColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	SecondaryBarColorExample:SetFontObject("GameFontHighlight")
	SecondaryBarColorExample:SetPoint("TOPLEFT", TopBarColorExample, "BOTTOMLEFT", 0, -25)
	local SecondaryBarColorHex = RGBToWoWColorCode(SecondaryBarColorR, SecondaryBarColorG, SecondaryBarColorB)
	SecondaryBarColorExample:SetText(SecondaryBarColorHex .. "EXAMPLE" .. ColorClose)
	SecondaryBarColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

    local MainWindowBackgroundExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	MainWindowBackgroundExample:SetFontObject("GameFontHighlight")
	MainWindowBackgroundExample:SetPoint("TOPLEFT", SecondaryBarColorExample, "BOTTOMLEFT", 0, -25)
	local MainWindowBackgroundHex = RGBToWoWColorCode(MainWindowBackgroundR, MainWindowBackgroundG, MainWindowBackgroundB)
	MainWindowBackgroundExample:SetText(MainWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	MainWindowBackgroundExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

    local BottomBarColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	BottomBarColorExample:SetFontObject("GameFontHighlight")
	BottomBarColorExample:SetPoint("TOPLEFT", MainWindowBackgroundExample, "BOTTOMLEFT", 0, -25)
	local BottomBarColorHex = RGBToWoWColorCode(BottomBarColorR, BottomBarColorG, BottomBarColorB)
	BottomBarColorExample:SetText(BottomBarColorHex .. "EXAMPLE" .. ColorClose)
	BottomBarColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

    local EnchantsButtonColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	EnchantsButtonColorExample:SetFontObject("GameFontHighlight")
	EnchantsButtonColorExample:SetPoint("TOPLEFT", BottomBarColorExample, "BOTTOMLEFT", 0, -25)
	local EnchantsButtonColorHex = RGBToWoWColorCode(EnchantsButtonColorR, EnchantsButtonColorG, EnchantsButtonColorB)
	EnchantsButtonColorExample:SetText(EnchantsButtonColorHex .. "EXAMPLE" .. ColorClose)
	EnchantsButtonColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

    local EnchantsButtonColorInactiveExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	EnchantsButtonColorInactiveExample:SetFontObject("GameFontHighlight")
	EnchantsButtonColorInactiveExample:SetPoint("TOPLEFT", EnchantsButtonColorExample, "BOTTOMLEFT", 0, -25)
	local EnchantsButtonColorInactiveHex = RGBToWoWColorCode(EnchantsButtonColorInactiveR, EnchantsButtonColorInactiveG, EnchantsButtonColorInactiveB)
	EnchantsButtonColorInactiveExample:SetText(EnchantsButtonColorInactiveHex .. "EXAMPLE" .. ColorClose)
	EnchantsButtonColorInactiveExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

    local BorderColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	BorderColorExample:SetFontObject("GameFontHighlight")
	BorderColorExample:SetPoint("TOPLEFT", EnchantsButtonColorInactiveExample, "BOTTOMLEFT", 0, -25)
	local BorderColorHex = RGBToWoWColorCode(BorderColorR, BorderColorG, BorderColorB)
	BorderColorExample:SetText(BorderColorHex .. "EXAMPLE" .. ColorClose)
	BorderColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")
   
    local MainButtonColorExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	MainButtonColorExample:SetFontObject("GameFontHighlight")
	MainButtonColorExample:SetPoint("TOPLEFT", BorderColorExample, "BOTTOMLEFT", 0, -25)
	local MainButtonColorHex = RGBToWoWColorCode(MainButtonColorR, MainButtonColorG, MainButtonColorB)
	MainButtonColorExample:SetText(MainButtonColorHex .. "EXAMPLE" .. ColorClose)
	MainButtonColorExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

    local SettingsWindowBackgroundExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	SettingsWindowBackgroundExample:SetFontObject("GameFontHighlight")
	SettingsWindowBackgroundExample:SetPoint("TOPLEFT", MainButtonColorExample, "BOTTOMLEFT", 0, -25)
	local SettingsWindowBackgroundHex = RGBToWoWColorCode(SettingsWindowBackgroundR, SettingsWindowBackgroundG, SettingsWindowBackgroundB)
	SettingsWindowBackgroundExample:SetText(SettingsWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	SettingsWindowBackgroundExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")

    local ScrollBarColorsExample = ColorsFrame:CreateFontString(nil, "OVERLAY")
	ScrollBarColorsExample:SetFontObject("GameFontHighlight")
	ScrollBarColorsExample:SetPoint("TOPLEFT", SettingsWindowBackgroundExample, "BOTTOMLEFT", 0, -25)
	local ScrollBarColorsHex = RGBToWoWColorCode(ScrollBarColorsR, ScrollBarColorsG, ScrollBarColorsB)
	ScrollBarColorsExample:SetText(ScrollBarColorsHex .. "EXAMPLE" .. ColorClose)
	ScrollBarColorsExample:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize + 2, "")


    -- Color EditBoxes
    local TopBarColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	TopBarColorHeader:SetFontObject("GameFontHighlight")
	TopBarColorHeader:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 70, -80)
	TopBarColorHeader:SetText("Main Colors")
	TopBarColorHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local TopBarColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	TopBarColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	TopBarColorRBg:SetSize(34, 24)  -- Adjust size as needed
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
	TopBarColorR:SetText(tostring(TopBarColorR*255))
	TopBarColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	TopBarColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	TopBarColorR:SetScript("OnTextChanged", function()
		local new = tonumber(TopBarColorR:GetText())
		if new == nil then
			TopBarColorR = 0
		elseif new > 254 then
			TopBarColorR = 1
		else
			TopBarColorR = new/255
		end
		ProEnchantersOptions.Colors.TopBarColor = {TopBarColorR, TopBarColorG, TopBarColorB}
		local TopBarColorHex = RGBToWoWColorCode(TopBarColorR, TopBarColorG, TopBarColorB)
		TopBarColorExample:SetText(TopBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local TopBarColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	TopBarColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	TopBarColorGBg:SetSize(34, 24)  -- Adjust size as needed
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
	TopBarColorG:SetText(tostring(TopBarColorG*255))
	TopBarColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	TopBarColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	TopBarColorG:SetScript("OnTextChanged", function()
		local new = tonumber(TopBarColorG:GetText())
		if new == nil then
			TopBarColorG = 0
		elseif new > 254 then
			TopBarColorG = 1
		else
			TopBarColorG = new/255
		end
		ProEnchantersOptions.Colors.TopBarColor = {TopBarColorR, TopBarColorG, TopBarColorB}
		local TopBarColorHex = RGBToWoWColorCode(TopBarColorR, TopBarColorG, TopBarColorB)
		TopBarColorExample:SetText(TopBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local TopBarColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	TopBarColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	TopBarColorBBg:SetSize(34, 24)  -- Adjust size as needed
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
	TopBarColorB:SetText(tostring(TopBarColorB*255))
	TopBarColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	TopBarColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	TopBarColorB:SetScript("OnTextChanged", function()
		local new = tonumber(TopBarColorB:GetText())
		if new == nil then
			TopBarColorB = 0
		elseif new > 254 then
			TopBarColorB = 1
		else
			TopBarColorB = new/255
		end
		ProEnchantersOptions.Colors.TopBarColor = {TopBarColorR, TopBarColorG, TopBarColorB}
		local TopBarColorHex = RGBToWoWColorCode(TopBarColorR, TopBarColorG, TopBarColorB)
		TopBarColorExample:SetText(TopBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

    local SecondaryBarColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	SecondaryBarColorHeader:SetFontObject("GameFontHighlight")
	SecondaryBarColorHeader:SetPoint("TOPLEFT", TopBarColorHeader, "BOTTOMLEFT", 0, -25)
	SecondaryBarColorHeader:SetText("Main Colors")
	SecondaryBarColorHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local SecondaryBarColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SecondaryBarColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	SecondaryBarColorRBg:SetSize(34, 24)  -- Adjust size as needed
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
	SecondaryBarColorR:SetText(tostring(SecondaryBarColorR*255))
	SecondaryBarColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SecondaryBarColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SecondaryBarColorR:SetScript("OnTextChanged", function()
		local new = tonumber(SecondaryBarColorR:GetText())
		if new == nil then
			SecondaryBarColorR = 0
		elseif new > 254 then
			SecondaryBarColorR = 1
		else
			SecondaryBarColorR = new/255
		end
		ProEnchantersOptions.Colors.SecondaryBarColor = {SecondaryBarColorR, SecondaryBarColorG, SecondaryBarColorB}
		local SecondaryBarColorHex = RGBToWoWColorCode(SecondaryBarColorR, SecondaryBarColorG, SecondaryBarColorB)
		SecondaryBarColorExample:SetText(SecondaryBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local SecondaryBarColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SecondaryBarColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	SecondaryBarColorGBg:SetSize(34, 24)  -- Adjust size as needed
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
	SecondaryBarColorG:SetText(tostring(SecondaryBarColorG*255))
	SecondaryBarColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SecondaryBarColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SecondaryBarColorG:SetScript("OnTextChanged", function()
		local new = tonumber(SecondaryBarColorG:GetText())
		if new == nil then
			SecondaryBarColorG = 0
		elseif new > 254 then
			SecondaryBarColorG = 1
		else
			SecondaryBarColorG = new/255
		end
		ProEnchantersOptions.Colors.SecondaryBarColor = {SecondaryBarColorR, SecondaryBarColorG, SecondaryBarColorB}
		local SecondaryBarColorHex = RGBToWoWColorCode(SecondaryBarColorR, SecondaryBarColorG, SecondaryBarColorB)
		SecondaryBarColorExample:SetText(SecondaryBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local SecondaryBarColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SecondaryBarColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	SecondaryBarColorBBg:SetSize(34, 24)  -- Adjust size as needed
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
	SecondaryBarColorB:SetText(tostring(SecondaryBarColorB*255))
	SecondaryBarColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SecondaryBarColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SecondaryBarColorB:SetScript("OnTextChanged", function()
		local new = tonumber(SecondaryBarColorB:GetText())
		if new == nil then
			SecondaryBarColorB = 0
		elseif new > 254 then
			SecondaryBarColorB = 1
		else
			SecondaryBarColorB = new/255
		end
		ProEnchantersOptions.Colors.SecondaryBarColor = {SecondaryBarColorR, SecondaryBarColorG, SecondaryBarColorB}
		local SecondaryBarColorHex = RGBToWoWColorCode(SecondaryBarColorR, SecondaryBarColorG, SecondaryBarColorB)
		SecondaryBarColorExample:SetText(SecondaryBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

    local MainWindowBackgroundHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	MainWindowBackgroundHeader:SetFontObject("GameFontHighlight")
	MainWindowBackgroundHeader:SetPoint("TOPLEFT", SecondaryBarColorHeader, "BOTTOMLEFT", 0, -25)
	MainWindowBackgroundHeader:SetText("Main Colors")
	MainWindowBackgroundHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local MainWindowBackgroundRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainWindowBackgroundRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	MainWindowBackgroundRBg:SetSize(34, 24)  -- Adjust size as needed
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
	MainWindowBackgroundR:SetText(tostring(MainWindowBackgroundR*255))
	MainWindowBackgroundR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundR:SetScript("OnTextChanged", function()
		local new = tonumber(MainWindowBackgroundR:GetText())
		if new == nil then
			MainWindowBackgroundR = 0
		elseif new > 254 then
			MainWindowBackgroundR = 1
		else
			MainWindowBackgroundR = new/255
		end
		ProEnchantersOptions.Colors.MainWindowBackground = {MainWindowBackgroundR, MainWindowBackgroundG, MainWindowBackgroundB}
		local MainWindowBackgroundHex = RGBToWoWColorCode(MainWindowBackgroundR, MainWindowBackgroundG, MainWindowBackgroundB)
		MainWindowBackgroundExample:SetText(MainWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainWindowBackgroundGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainWindowBackgroundGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	MainWindowBackgroundGBg:SetSize(34, 24)  -- Adjust size as needed
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
	MainWindowBackgroundG:SetText(tostring(MainWindowBackgroundG*255))
	MainWindowBackgroundG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundG:SetScript("OnTextChanged", function()
		local new = tonumber(MainWindowBackgroundG:GetText())
		if new == nil then
			MainWindowBackgroundG = 0
		elseif new > 254 then
			MainWindowBackgroundG = 1
		else
			MainWindowBackgroundG = new/255
		end
		ProEnchantersOptions.Colors.MainWindowBackground = {MainWindowBackgroundR, MainWindowBackgroundG, MainWindowBackgroundB}
		local MainWindowBackgroundHex = RGBToWoWColorCode(MainWindowBackgroundR, MainWindowBackgroundG, MainWindowBackgroundB)
		MainWindowBackgroundExample:SetText(MainWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainWindowBackgroundBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainWindowBackgroundBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	MainWindowBackgroundBBg:SetSize(34, 24)  -- Adjust size as needed
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
	MainWindowBackgroundB:SetText(tostring(MainWindowBackgroundB*255))
	MainWindowBackgroundB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainWindowBackgroundB:SetScript("OnTextChanged", function()
		local new = tonumber(MainWindowBackgroundB:GetText())
		if new == nil then
			MainWindowBackgroundB = 0
		elseif new > 254 then
			MainWindowBackgroundB = 1
		else
			MainWindowBackgroundB = new/255
		end
		ProEnchantersOptions.Colors.MainWindowBackground = {MainWindowBackgroundR, MainWindowBackgroundG, MainWindowBackgroundB}
		local MainWindowBackgroundHex = RGBToWoWColorCode(MainWindowBackgroundR, MainWindowBackgroundG, MainWindowBackgroundB)
		MainWindowBackgroundExample:SetText(MainWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

    local BottomBarColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	BottomBarColorHeader:SetFontObject("GameFontHighlight")
	BottomBarColorHeader:SetPoint("TOPLEFT", MainWindowBackgroundHeader, "BOTTOMLEFT", 0, -25)
	BottomBarColorHeader:SetText("Main Colors")
	BottomBarColorHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local BottomBarColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BottomBarColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	BottomBarColorRBg:SetSize(34, 24)  -- Adjust size as needed
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
	BottomBarColorR:SetText(tostring(BottomBarColorR*255))
	BottomBarColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BottomBarColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BottomBarColorR:SetScript("OnTextChanged", function()
		local new = tonumber(BottomBarColorR:GetText())
		if new == nil then
			BottomBarColorR = 0
		elseif new > 254 then
			BottomBarColorR = 1
		else
			BottomBarColorR = new/255
		end
		ProEnchantersOptions.Colors.BottomBarColor = {BottomBarColorR, BottomBarColorG, BottomBarColorB}
		local BottomBarColorHex = RGBToWoWColorCode(BottomBarColorR, BottomBarColorG, BottomBarColorB)
		BottomBarColorExample:SetText(BottomBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local BottomBarColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BottomBarColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	BottomBarColorGBg:SetSize(34, 24)  -- Adjust size as needed
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
	BottomBarColorG:SetText(tostring(BottomBarColorG*255))
	BottomBarColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BottomBarColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BottomBarColorG:SetScript("OnTextChanged", function()
		local new = tonumber(BottomBarColorG:GetText())
		if new == nil then
			BottomBarColorG = 0
		elseif new > 254 then
			BottomBarColorG = 1
		else
			BottomBarColorG = new/255
		end
		ProEnchantersOptions.Colors.BottomBarColor = {BottomBarColorR, BottomBarColorG, BottomBarColorB}
		local BottomBarColorHex = RGBToWoWColorCode(BottomBarColorR, BottomBarColorG, BottomBarColorB)
		BottomBarColorExample:SetText(BottomBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local BottomBarColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BottomBarColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	BottomBarColorBBg:SetSize(34, 24)  -- Adjust size as needed
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
	BottomBarColorB:SetText(tostring(BottomBarColorB*255))
	BottomBarColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BottomBarColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BottomBarColorB:SetScript("OnTextChanged", function()
		local new = tonumber(BottomBarColorB:GetText())
		if new == nil then
			BottomBarColorB = 0
		elseif new > 254 then
			BottomBarColorB = 1
		else
			BottomBarColorB = new/255
		end
		ProEnchantersOptions.Colors.BottomBarColor = {BottomBarColorR, BottomBarColorG, BottomBarColorB}
		local BottomBarColorHex = RGBToWoWColorCode(BottomBarColorR, BottomBarColorG, BottomBarColorB)
		BottomBarColorExample:SetText(BottomBarColorHex .. "EXAMPLE" .. ColorClose)
	end)

    local EnchantsButtonColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	EnchantsButtonColorHeader:SetFontObject("GameFontHighlight")
	EnchantsButtonColorHeader:SetPoint("TOPLEFT", MainWindowBackgroundHeader, "BOTTOMLEFT", 0, -25)
	EnchantsButtonColorHeader:SetText("Main Colors")
	EnchantsButtonColorHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local EnchantsButtonColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorRBg:SetSize(34, 24)  -- Adjust size as needed
	EnchantsButtonColorRBg:SetPoint("LEFT", BottomBarColorHeader, "RIGHT", 10, 0)

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
	EnchantsButtonColorR:SetText(tostring(EnchantsButtonColorR*255))
	EnchantsButtonColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorR:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorR:GetText())
		if new == nil then
			EnchantsButtonColorR = 0
		elseif new > 254 then
			EnchantsButtonColorR = 1
		else
			EnchantsButtonColorR = new/255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColor = {EnchantsButtonColorR, EnchantsButtonColorG, EnchantsButtonColorB}
		local EnchantsButtonColorHex = RGBToWoWColorCode(EnchantsButtonColorR, EnchantsButtonColorG, EnchantsButtonColorB)
		EnchantsButtonColorExample:SetText(EnchantsButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorGBg:SetSize(34, 24)  -- Adjust size as needed
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
	EnchantsButtonColorG:SetText(tostring(EnchantsButtonColorG*255))
	EnchantsButtonColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorG:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorG:GetText())
		if new == nil then
			EnchantsButtonColorG = 0
		elseif new > 254 then
			EnchantsButtonColorG = 1
		else
			EnchantsButtonColorG = new/255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColor = {EnchantsButtonColorR, EnchantsButtonColorG, EnchantsButtonColorB}
		local EnchantsButtonColorHex = RGBToWoWColorCode(EnchantsButtonColorR, EnchantsButtonColorG, EnchantsButtonColorB)
		EnchantsButtonColorExample:SetText(EnchantsButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorBBg:SetSize(34, 24)  -- Adjust size as needed
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
	EnchantsButtonColorB:SetText(tostring(EnchantsButtonColorB*255))
	EnchantsButtonColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorB:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorB:GetText())
		if new == nil then
			EnchantsButtonColorB = 0
		elseif new > 254 then
			EnchantsButtonColorB = 1
		else
			EnchantsButtonColorB = new/255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColor = {EnchantsButtonColorR, EnchantsButtonColorG, EnchantsButtonColorB}
		local EnchantsButtonColorHex = RGBToWoWColorCode(EnchantsButtonColorR, EnchantsButtonColorG, EnchantsButtonColorB)
		EnchantsButtonColorExample:SetText(EnchantsButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

    local EnchantsButtonColorInactiveHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	EnchantsButtonColorInactiveHeader:SetFontObject("GameFontHighlight")
	EnchantsButtonColorInactiveHeader:SetPoint("TOPLEFT", EnchantsButtonColorHeader, "BOTTOMLEFT", 0, -25)
	EnchantsButtonColorInactiveHeader:SetText("Main Colors")
	EnchantsButtonColorInactiveHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local EnchantsButtonColorInactiveRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorInactiveRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorInactiveRBg:SetSize(34, 24)  -- Adjust size as needed
	EnchantsButtonColorInactiveRBg:SetPoint("LEFT", BottomBarColorHeader, "RIGHT", 10, 0)

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
	EnchantsButtonColorInactiveR:SetText(tostring(EnchantsButtonColorInactiveR*255))
	EnchantsButtonColorInactiveR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveR:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorInactiveR:GetText())
		if new == nil then
			EnchantsButtonColorInactiveR = 0
		elseif new > 254 then
			EnchantsButtonColorInactiveR = 1
		else
			EnchantsButtonColorInactiveR = new/255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColorInactive = {EnchantsButtonColorInactiveR, EnchantsButtonColorInactiveG, EnchantsButtonColorInactiveB}
		local EnchantsButtonColorInactiveHex = RGBToWoWColorCode(EnchantsButtonColorInactiveR, EnchantsButtonColorInactiveG, EnchantsButtonColorInactiveB)
		EnchantsButtonColorInactiveExample:SetText(EnchantsButtonColorInactiveHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorInactiveGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorInactiveGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorInactiveGBg:SetSize(34, 24)  -- Adjust size as needed
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
	EnchantsButtonColorInactiveG:SetText(tostring(EnchantsButtonColorInactiveG*255))
	EnchantsButtonColorInactiveG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveG:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorInactiveG:GetText())
		if new == nil then
			EnchantsButtonColorInactiveG = 0
		elseif new > 254 then
			EnchantsButtonColorInactiveG = 1
		else
			EnchantsButtonColorInactiveG = new/255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColorInactive = {EnchantsButtonColorInactiveR, EnchantsButtonColorInactiveG, EnchantsButtonColorInactiveB}
		local EnchantsButtonColorInactiveHex = RGBToWoWColorCode(EnchantsButtonColorInactiveR, EnchantsButtonColorInactiveG, EnchantsButtonColorInactiveB)
		EnchantsButtonColorInactiveExample:SetText(EnchantsButtonColorInactiveHex .. "EXAMPLE" .. ColorClose)
	end)

	local EnchantsButtonColorInactiveBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	EnchantsButtonColorInactiveBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	EnchantsButtonColorInactiveBBg:SetSize(34, 24)  -- Adjust size as needed
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
	EnchantsButtonColorInactiveB:SetText(tostring(EnchantsButtonColorInactiveB*255))
	EnchantsButtonColorInactiveB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	EnchantsButtonColorInactiveB:SetScript("OnTextChanged", function()
		local new = tonumber(EnchantsButtonColorInactiveB:GetText())
		if new == nil then
			EnchantsButtonColorInactiveB = 0
		elseif new > 254 then
			EnchantsButtonColorInactiveB = 1
		else
			EnchantsButtonColorInactiveB = new/255
		end
		ProEnchantersOptions.Colors.EnchantsButtonColorInactive = {EnchantsButtonColorInactiveR, EnchantsButtonColorInactiveG, EnchantsButtonColorInactiveB}
		local EnchantsButtonColorInactiveHex = RGBToWoWColorCode(EnchantsButtonColorInactiveR, EnchantsButtonColorInactiveG, EnchantsButtonColorInactiveB)
		EnchantsButtonColorInactiveExample:SetText(EnchantsButtonColorInactiveHex .. "EXAMPLE" .. ColorClose)
	end)

    local BorderColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	BorderColorHeader:SetFontObject("GameFontHighlight")
	BorderColorHeader:SetPoint("TOPLEFT", EnchantsButtonColorInactiveHeader, "BOTTOMLEFT", 0, -25)
	BorderColorHeader:SetText("Main Colors")
	BorderColorHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local BorderColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BorderColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	BorderColorRBg:SetSize(34, 24)  -- Adjust size as needed
	BorderColorRBg:SetPoint("LEFT", BottomBarColorHeader, "RIGHT", 10, 0)

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
	BorderColorR:SetText(tostring(BorderColorR*255))
	BorderColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BorderColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BorderColorR:SetScript("OnTextChanged", function()
		local new = tonumber(BorderColorR:GetText())
		if new == nil then
			BorderColorR = 0
		elseif new > 254 then
			BorderColorR = 1
		else
			BorderColorR = new/255
		end
		ProEnchantersOptions.Colors.BorderColor = {BorderColorR, BorderColorG, BorderColorB}
		local BorderColorHex = RGBToWoWColorCode(BorderColorR, BorderColorG, BorderColorB)
		BorderColorExample:SetText(BorderColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local BorderColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BorderColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	BorderColorGBg:SetSize(34, 24)  -- Adjust size as needed
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
	BorderColorG:SetText(tostring(BorderColorG*255))
	BorderColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BorderColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BorderColorG:SetScript("OnTextChanged", function()
		local new = tonumber(BorderColorG:GetText())
		if new == nil then
			BorderColorG = 0
		elseif new > 254 then
			BorderColorG = 1
		else
			BorderColorG = new/255
		end
		ProEnchantersOptions.Colors.BorderColor = {BorderColorR, BorderColorG, BorderColorB}
		local BorderColorHex = RGBToWoWColorCode(BorderColorR, BorderColorG, BorderColorB)
		BorderColorExample:SetText(BorderColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local BorderColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	BorderColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	BorderColorBBg:SetSize(34, 24)  -- Adjust size as needed
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
	BorderColorB:SetText(tostring(BorderColorB*255))
	BorderColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	BorderColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	BorderColorB:SetScript("OnTextChanged", function()
		local new = tonumber(BorderColorB:GetText())
		if new == nil then
			BorderColorB = 0
		elseif new > 254 then
			BorderColorB = 1
		else
			BorderColorB = new/255
		end
		ProEnchantersOptions.Colors.BorderColor = {BorderColorR, BorderColorG, BorderColorB}
		local BorderColorHex = RGBToWoWColorCode(BorderColorR, BorderColorG, BorderColorB)
		BorderColorExample:SetText(BorderColorHex .. "EXAMPLE" .. ColorClose)
	end)

    local MainButtonColorHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	MainButtonColorHeader:SetFontObject("GameFontHighlight")
	MainButtonColorHeader:SetPoint("TOPLEFT", BorderColorHeader, "BOTTOMLEFT", 0, -25)
	MainButtonColorHeader:SetText("Main Colors")
	MainButtonColorHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local MainButtonColorRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainButtonColorRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	MainButtonColorRBg:SetSize(34, 24)  -- Adjust size as needed
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
	MainButtonColorR:SetText(tostring(MainButtonColorR*255))
	MainButtonColorR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainButtonColorR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainButtonColorR:SetScript("OnTextChanged", function()
		local new = tonumber(MainButtonColorR:GetText())
		if new == nil then
			MainButtonColorR = 0
		elseif new > 254 then
			MainButtonColorR = 1
		else
			MainButtonColorR = new/255
		end
		ProEnchantersOptions.Colors.MainButtonColor = {MainButtonColorR, MainButtonColorG, MainButtonColorB}
		local MainButtonColorHex = RGBToWoWColorCode(MainButtonColorR, MainButtonColorG, MainButtonColorB)
		MainButtonColorExample:SetText(MainButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainButtonColorGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainButtonColorGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	MainButtonColorGBg:SetSize(34, 24)  -- Adjust size as needed
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
	MainButtonColorG:SetText(tostring(MainButtonColorG*255))
	MainButtonColorG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainButtonColorG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainButtonColorG:SetScript("OnTextChanged", function()
		local new = tonumber(MainButtonColorG:GetText())
		if new == nil then
			MainButtonColorG = 0
		elseif new > 254 then
			MainButtonColorG = 1
		else
			MainButtonColorG = new/255
		end
		ProEnchantersOptions.Colors.MainButtonColor = {MainButtonColorR, MainButtonColorG, MainButtonColorB}
		local MainButtonColorHex = RGBToWoWColorCode(MainButtonColorR, MainButtonColorG, MainButtonColorB)
		MainButtonColorExample:SetText(MainButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

	local MainButtonColorBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	MainButtonColorBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	MainButtonColorBBg:SetSize(34, 24)  -- Adjust size as needed
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
	MainButtonColorB:SetText(tostring(MainButtonColorB*255))
	MainButtonColorB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	MainButtonColorB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	MainButtonColorB:SetScript("OnTextChanged", function()
		local new = tonumber(MainButtonColorB:GetText())
		if new == nil then
			MainButtonColorB = 0
		elseif new > 254 then
			MainButtonColorB = 1
		else
			MainButtonColorB = new/255
		end
		ProEnchantersOptions.Colors.MainButtonColor = {MainButtonColorR, MainButtonColorG, MainButtonColorB}
		local MainButtonColorHex = RGBToWoWColorCode(MainButtonColorR, MainButtonColorG, MainButtonColorB)
		MainButtonColorExample:SetText(MainButtonColorHex .. "EXAMPLE" .. ColorClose)
	end)

    local SettingsWindowBackgroundHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	SettingsWindowBackgroundHeader:SetFontObject("GameFontHighlight")
	SettingsWindowBackgroundHeader:SetPoint("TOPLEFT", MainButtonColorHeader, "BOTTOMLEFT", 0, -25)
	SettingsWindowBackgroundHeader:SetText("Main Colors")
	SettingsWindowBackgroundHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local SettingsWindowBackgroundRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SettingsWindowBackgroundRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	SettingsWindowBackgroundRBg:SetSize(34, 24)  -- Adjust size as needed
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
	SettingsWindowBackgroundR:SetText(tostring(SettingsWindowBackgroundR*255))
	SettingsWindowBackgroundR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundR:SetScript("OnTextChanged", function()
		local new = tonumber(SettingsWindowBackgroundR:GetText())
		if new == nil then
			SettingsWindowBackgroundR = 0
		elseif new > 254 then
			SettingsWindowBackgroundR = 1
		else
			SettingsWindowBackgroundR = new/255
		end
		ProEnchantersOptions.Colors.SettingsWindowBackground = {SettingsWindowBackgroundR, SettingsWindowBackgroundG, SettingsWindowBackgroundB}
		local SettingsWindowBackgroundHex = RGBToWoWColorCode(SettingsWindowBackgroundR, SettingsWindowBackgroundG, SettingsWindowBackgroundB)
		SettingsWindowBackgroundExample:SetText(SettingsWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local SettingsWindowBackgroundGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SettingsWindowBackgroundGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	SettingsWindowBackgroundGBg:SetSize(34, 24)  -- Adjust size as needed
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
	SettingsWindowBackgroundG:SetText(tostring(SettingsWindowBackgroundG*255))
	SettingsWindowBackgroundG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundG:SetScript("OnTextChanged", function()
		local new = tonumber(SettingsWindowBackgroundG:GetText())
		if new == nil then
			SettingsWindowBackgroundG = 0
		elseif new > 254 then
			SettingsWindowBackgroundG = 1
		else
			SettingsWindowBackgroundG = new/255
		end
		ProEnchantersOptions.Colors.SettingsWindowBackground = {SettingsWindowBackgroundR, SettingsWindowBackgroundG, SettingsWindowBackgroundB}
		local SettingsWindowBackgroundHex = RGBToWoWColorCode(SettingsWindowBackgroundR, SettingsWindowBackgroundG, SettingsWindowBackgroundB)
		SettingsWindowBackgroundExample:SetText(SettingsWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

	local SettingsWindowBackgroundBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	SettingsWindowBackgroundBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	SettingsWindowBackgroundBBg:SetSize(34, 24)  -- Adjust size as needed
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
	SettingsWindowBackgroundB:SetText(tostring(SettingsWindowBackgroundB*255))
	SettingsWindowBackgroundB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	SettingsWindowBackgroundB:SetScript("OnTextChanged", function()
		local new = tonumber(SettingsWindowBackgroundB:GetText())
		if new == nil then
			SettingsWindowBackgroundB = 0
		elseif new > 254 then
			SettingsWindowBackgroundB = 1
		else
			SettingsWindowBackgroundB = new/255
		end
		ProEnchantersOptions.Colors.SettingsWindowBackground = {SettingsWindowBackgroundR, SettingsWindowBackgroundG, SettingsWindowBackgroundB}
		local SettingsWindowBackgroundHex = RGBToWoWColorCode(SettingsWindowBackgroundR, SettingsWindowBackgroundG, SettingsWindowBackgroundB)
		SettingsWindowBackgroundExample:SetText(SettingsWindowBackgroundHex .. "EXAMPLE" .. ColorClose)
	end)

    local ScrollBarColorsHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	ScrollBarColorsHeader:SetFontObject("GameFontHighlight")
	ScrollBarColorsHeader:SetPoint("TOPLEFT", SettingsWindowBackgroundHeader, "BOTTOMLEFT", 0, -25)
	ScrollBarColorsHeader:SetText("Main Colors")
	ScrollBarColorsHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local ScrollBarColorsRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	ScrollBarColorsRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	ScrollBarColorsRBg:SetSize(34, 24)  -- Adjust size as needed
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
	ScrollBarColorsR:SetText(tostring(ScrollBarColorsR*255))
	ScrollBarColorsR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	ScrollBarColorsR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	ScrollBarColorsR:SetScript("OnTextChanged", function()
		local new = tonumber(ScrollBarColorsR:GetText())
		if new == nil then
			ScrollBarColorsR = 0
		elseif new > 254 then
			ScrollBarColorsR = 1
		else
			ScrollBarColorsR = new/255
		end
		ProEnchantersOptions.Colors.ScrollBarColors = {ScrollBarColorsR, ScrollBarColorsG, ScrollBarColorsB}
		local ScrollBarColorsHex = RGBToWoWColorCode(ScrollBarColorsR, ScrollBarColorsG, ScrollBarColorsB)
		ScrollBarColorsExample:SetText(ScrollBarColorsHex .. "EXAMPLE" .. ColorClose)
	end)

	local ScrollBarColorsGBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	ScrollBarColorsGBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	ScrollBarColorsGBg:SetSize(34, 24)  -- Adjust size as needed
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
	ScrollBarColorsG:SetText(tostring(ScrollBarColorsG*255))
	ScrollBarColorsG:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	ScrollBarColorsG:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	ScrollBarColorsG:SetScript("OnTextChanged", function()
		local new = tonumber(ScrollBarColorsG:GetText())
		if new == nil then
			ScrollBarColorsG = 0
		elseif new > 254 then
			ScrollBarColorsG = 1
		else
			ScrollBarColorsG = new/255
		end
		ProEnchantersOptions.Colors.ScrollBarColors = {ScrollBarColorsR, ScrollBarColorsG, ScrollBarColorsB}
		local ScrollBarColorsHex = RGBToWoWColorCode(ScrollBarColorsR, ScrollBarColorsG, ScrollBarColorsB)
		ScrollBarColorsExample:SetText(ScrollBarColorsHex .. "EXAMPLE" .. ColorClose)
	end)

	local ScrollBarColorsBBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	ScrollBarColorsBBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	ScrollBarColorsBBg:SetSize(34, 24)  -- Adjust size as needed
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
	ScrollBarColorsB:SetText(tostring(ScrollBarColorsB*255))
	ScrollBarColorsB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	ScrollBarColorsB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	ScrollBarColorsB:SetScript("OnTextChanged", function()
		local new = tonumber(ScrollBarColorsB:GetText())
		if new == nil then
			ScrollBarColorsB = 0
		elseif new > 254 then
			ScrollBarColorsB = 1
		else
			ScrollBarColorsB = new/255
		end
		ProEnchantersOptions.Colors.ScrollBarColors = {ScrollBarColorsR, ScrollBarColorsG, ScrollBarColorsB}
		local ScrollBarColorsHex = RGBToWoWColorCode(ScrollBarColorsR, ScrollBarColorsG, ScrollBarColorsB)
		ScrollBarColorsExample:SetText(ScrollBarColorsHex .. "EXAMPLE" .. ColorClose)
	end)

    local OpacityAmountHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	OpacityAmountHeader:SetFontObject("GameFontHighlight")
	OpacityAmountHeader:SetPoint("TOPLEFT", ScrollBarColorsHeader, "BOTTOMLEFT", 0, -25)
	OpacityAmountHeader:SetText("Main Colors")
	OpacityAmountHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	local OpacityAmountRBg = ColorsFrame:CreateTexture(nil, "OVERLAY")
	OpacityAmountRBg:SetColorTexture(unpack(MainWindowBackgroundTrans))  -- Set RGBA values for your preferred color and alpha
	OpacityAmountRBg:SetSize(34, 24)  -- Adjust size as needed
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
	OpacityAmountR:SetText(tostring(OpacityAmountR*100))
	OpacityAmountR:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	OpacityAmountR:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	OpacityAmountR:SetScript("OnTextChanged", function()
		local new = tonumber(OpacityAmountR:GetText())
		if new == nil then
			OpacityAmountR = 0
		elseif new > 99 then
			OpacityAmountR = 1
		else
			OpacityAmountR = new/100
		end
		ProEnchantersOptions.Colors.OpacityAmount = OpacityAmountR
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
        EnchantsButtonColorInactiveR:SetText(tostring(22))
		EnchantsButtonColorInactiveG:SetText(tostring(26))
		EnchantsButtonColorInactiveB:SetText(tostring(48))
        BorderColorR:SetText(tostring(2))
		BorderColorG:SetText(tostring(2))
		BorderColorB:SetText(tostring(2))
        MainButtonColorR:SetText(tostring(22))
		MainButtonColorG:SetText(tostring(26))
		MainButtonColorB:SetText(tostring(48))
        SettingsWindowBackgroundR:SetText(tostring(22))
		SettingsWindowBackgroundG:SetText(tostring(26))
		SettingsWindowBackgroundB:SetText(tostring(48))
        ScrollBarColorsR:SetText(tostring(22))
		ScrollBarColorsG:SetText(tostring(26))
		ScrollBarColorsB:SetText(tostring(48))
        OpacityAmountR:SetText(tostring(50))
	end)

	-- Help Reminder
	local helpReminderHeader = ColorsFrame:CreateFontString(nil, "OVERLAY")
	helpReminderHeader:SetFontObject("GameFontGreen")
	helpReminderHeader:SetPoint("BOTTOM", closeBg, "BOTTOM", 0, 6)
	helpReminderHeader:SetText(STEELBLUE .. "Thanks for using Pro Enchanters!" .. ColorClose)
	helpReminderHeader:SetFont("Interface\\AddOns\\ProEnchanters\\Fonts\\PTSansNarrow.TTF", FontSize, "")

	return ColorsFrame
end


if next(ProEnchantersOptions.Colors.TopBarColor) == nil then
    ProEnchantersOptions.Colors.TopBarColor = {22/255, 26/255, 48/255}
end

if next(ProEnchantersOptions.Colors.SecondaryBarColor) == nil then
    ProEnchantersOptions.Colors.SecondaryBarColor = {49/255, 48/255, 77/255}
end

if next(ProEnchantersOptions.Colors.MainWindowBackground) == nil then
    ProEnchantersOptions.Colors.MainWindowBackground = {22/255, 26/255, 48/255}
end

if next(ProEnchantersOptions.Colors.BottomBarColor) == nil then
    ProEnchantersOptions.Colors.BottomBarColor = {22/255, 26/255, 48/255}
end

if next(ProEnchantersOptions.Colors.EnchantsButtonColor) == nil then
    ProEnchantersOptions.Colors.EnchantsButtonColor = {22/255, 26/255, 48/255}
end

if next(ProEnchantersOptions.Colors.EnchantsButtonColorInactive) == nil then
    ProEnchantersOptions.Colors.EnchantsButtonColorInactive = {22/255, 26/255, 48/255}
end

if next(ProEnchantersOptions.Colors.BorderColor) == nil then
    ProEnchantersOptions.Colors.BorderColor = {2/255, 2/255, 2/255}
end

if next(ProEnchantersOptions.Colors.MainButtonColor) == nil then
    ProEnchantersOptions.Colors.MainButtonColor = {22/255, 26/255, 48/255}
end

if next(ProEnchantersOptions.Colors.SettingsWindowBackground) == nil then
    ProEnchantersOptions.Colors.SettingsWindowBackground = {22/255, 26/255, 48/255}
end

if next(ProEnchantersOptions.Colors.ScrollBarColors) == nil then
    ProEnchantersOptions.Colors.ScrollBarColors = {22/255, 26/255, 48/255}
end

if next(ProEnchantersOptions.Colors.OpacityAmount) == nil then
    ProEnchantersOptions.Colors.OpacityAmount = 0.5
end


--Color for Frames
 OpacityAmount = ProEnchantersOptions.Colors.OpacityAmount or 0.5
 
 TopBarColor = ProEnchantersOptions.Colors.TopBarColor or {22/255, 26/255, 48/255}
 r1, g1, b1 = unpack(TopBarColor)
 TopBarColorOpaque = {r1, g1, b1, 1}
 TopBarColorTrans = {r1, g1, b1, OpacityAmount}

 SecondaryBarColor = ProEnchantersOptions.Colors.SecondaryBarColor or {49/255, 48/255, 77/255}
 r2, g2, b2 = unpack(SecondaryBarColor)
 SecondaryBarColorOpaque = {r2, g2, b2, 1}
 SecondaryBarColorTrans = {r2, g2, b2, OpacityAmount}

 MainWindowBackground = ProEnchantersOptions.Colors.MainWindowBackground or {22/255, 26/255, 48/255}
 r3, g3, b3 = unpack(MainWindowBackground)
 MainWindowBackgroundOpaque = {r3, g3, b3, 1}
 MainWindowBackgroundTrans = {r3, g3, b3, OpacityAmount}

 BottomBarColor = ProEnchantersOptions.Colors.BottomBarColor or {22/255, 26/255, 48/255}
 r4, g4, b4 = unpack(BottomBarColor)
 BottomBarColorOpaque = {r4, g4, b4, 1}
 BottomBarColorTrans = {r4, g4, b4, OpacityAmount}

 EnchantsButtonColor = ProEnchantersOptions.Colors.EnchantsButtonColor or {22/255, 26/255, 48/255}
 r5, g5, b5 = unpack(EnchantsButtonColor)
 EnchantsButtonColorOpaque = {r5, g5, b5, 1}
 EnchantsButtonColorTrans = {r5, g5, b5, OpacityAmount}

 EnchantsButtonColorInactive = ProEnchantersOptions.Colors.EnchantsButtonColorInactive or {71/255, 71/255, 71/255}
 r6, g6, b6 = unpack(EnchantsButtonColorInactive)
 EnchantsButtonColorInactiveOpaque = {r6, g6, b6, 1}
 EnchantsButtonColorInactiveTrans = {r6, g6, b6, OpacityAmount}

 BorderColor = ProEnchantersOptions.Colors.BorderColor or {2/255, 2/255, 2/255}
 r7, g7, b7 = unpack(BorderColor)
 BorderColorOpaque = {r7, g7, b7, 1}
 BorderColorTrans = {r7, g7, b7, OpacityAmount}

 MainButtonColor = ProEnchantersOptions.Colors.MainButtonColor or {22/255, 26/255, 48/255}
 r8, g8, b8 = unpack(MainButtonColor)
 MainButtonColorOpaque = {r8, g8, b8, 1}
 MainButtonColorTrans = {r8, g8, b8, OpacityAmount}

 SettingsWindowBackground = ProEnchantersOptions.Colors.SettingsWindowBackground or {49/255, 48/255, 77/255}
 r9, g9, b9 = unpack(SettingsWindowBackground)
 SettingsWindowBackgroundOpaque = {r9, g9, b9, 1}
 SettingsWindowBackgroundTrans = {r9, g9, b9, OpacityAmount}

 ScrollBarColors = ProEnchantersOptions.Colors.ScrollBarColors or {49/255, 48/255, 77/255}
 r10, g10, b10 = unpack(ScrollBarColors)
 ButtonStandardAndThumb = {r10, g10, b10, 1}
 r10P, r10DH = ((r10*255)/4)/255, ((r10*255)/2)/255
 g10P, g10DH = ((g10*255)/4)/255, ((g10*255)/2)/255
 b10P, b10DH = ((b10*255)/4)/255, ((b10*255)/2)/255
 ButtonPushed = {r10 + r10P, g10 + g10P, b10 + b10P, 1}
 ButtonDisabled = {r10 - r10DH, g10 - g10DH, b10 - g10DH, 0.5}
 ButtonHighlight = {r10 + r10DH, g10 + g10DH, b10 + b10DH, 1}