--- Game Flavor
ProEnchantersWoWFlavor = "Cata"

--[[function PEMsgCheck(msg, author2, tword) -- To be worked on
	local msg2 = string.lower(msg)
	local author = string.gsub(author2, "%-.*", "")
	local author3 = string.lower(author)
	local finalcheck = false
	local printout = msg .. " contains no trigger word"
	
	if LocalLanguage == nil then
		LocalLanguage = "English"
	end
				
	local check1 = false
	local check2 = false
	local check3 = false
	local check4 = false

				local startPos, endPos = string.find(msg2, tword)
				if string.find(msg2, tword, 1, true) then
					check1 = true
					if ProEnchantersOptions["DebugLevel"] == 1 then
						printout = "trigger: " .. GREEN .. tword .. ColorClose .. " found within " .. LIGHTBLUE .. author2 .. ColorClose .. ": " .. msg2
					end
					if startPos then
						-- Check if "ench" is at the start of the string or preceded by a space
						if startPos == 1 or string.sub(msg2, startPos - 1, startPos - 1) == " " then
							check2 = true
							if ProEnchantersOptions["DebugLevel"] == 88 then
								printout = tword .. " does not have any leading characters, returning check2 as true"
							end
						else
							if ProEnchantersOptions["DebugLevel"] == 1 then
								printout = tword .. " is contained within a word, check2 returned as false"
							end
							return finalcheck, printout
						end
					end
					
				--else
					--return
				--end


				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					
					if string.find(msg2, filteredWord, 1, true) then
						check3 = true
						if ProEnchantersOptions["DebugLevel"] == 1 then
							printout = "filter: " .. RED .. word .. ColorClose .. " found within " .. LIGHTBLUE .. author2 .. ColorClose .. ": " .. msg2 .. " - trade channel"
		
						end
						return finalcheck, printout
					end
				end
				for _, word in pairs(ProEnchantersOptions.filteredwords) do
					local filteredWord = word
					if string.find(author, filteredWord, 1, true) then
						check4 = true
						if ProEnchantersOptions["DebugLevel"] == 1 then
							printout = "Sender: " .. author2 .. " name found in filter list, check 3 returning false"
								
						end
						return finalcheck, printout
					end
				end
				if check1 == true and check2 == true and check3 == false and check4 == false then
					finalcheck = true
					printout = "All checks passed, proceeding with invites/messages"
				end
			return finalcheck, printout
			end
	return finalcheck, printout
end]]

function GroupLeaderCheck()
    if UnitIsGroupAssistant("player") == true then
        return false
    end
    local check = UnitIsGroupLeader("player")
    return check
end

function CapFirstLetter(word)
    if word == nil or word == "" then return word end -- Check for empty or nil word
    local firstLetter = string.sub(word, 1, 1)
    local mappedLetter = utf8_lc_uc[firstLetter]      -- Direct lookup
    if mappedLetter then
        firstLetter = mappedLetter
    end
    local restOfWord = string.sub(word, 2)
    return firstLetter .. restOfWord
end

function stringshorten(enchName)
    local shortened = enchName:match("^Enchant%s+(%w+)")
    return shortened or enchName
end

function Test8utf()
    local line = ""
    for k, v in pairs(utf8_lc_uc) do
        line = line .. ", " .. k .. " = " .. v
    end
    print(line)
end

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

-- Get total mats required for a tradeskill
function ProEnchants_GetReagentList(SpellID, reqQuantity)
    --print(tostring(SpellID))
    local id = SpellID
    local AllMatsReq = ""
    if SpellID == nil then
        --print("SpellID is nil")
        AllMatsReq = "0x Unknown"
        return AllMatsReq
    end
    --print(tostring(SpellID))
    if reqQuantity == nil then
        reqQuantity = 1
    end
    local reqQuantity = reqQuantity
    
    
    if CombinedEnchants[id].materials then
        for _, matsReq in ipairs(CombinedEnchants[id].materials) do
            -- Extract quantity and material name
            local quantity, material = matsReq:match("(%d+)x (.+)")
           --print(quantity .. " x " .. material)
           --print(tostring(quantity) .. " " .. tostring(material))
            local itemId = material:match(":(%d+):")
            --print(tostring(itemId))
            --local test = PEItemCache(itemId)
            --print(test)
            local material = select(2, C_Item.GetItemInfo(itemId))
            --print(tostring(material))
            quantity = tonumber(quantity) * reqQuantity
            --print(tostring(quantity))

            -- Append to the AllMatsReq string
            if material == nil then
                material = "Unknown"
            end
            if AllMatsReq ~= "" then
                AllMatsReq = AllMatsReq .. ", " .. quantity .. "x " .. material
            else
                AllMatsReq = quantity .. "x " .. material
            end
        end
    end
    --print(tostring(AllMatsReq))
    return AllMatsReq
end

function ProEnchants_GetReagentListNoLink(SpellID, reqQuantity)
    local id = SpellID
    local AllMatsReq = ""
    if reqQuantity == nil then
        reqQuantity = 1
    end
    local reqQuantity = reqQuantity

    if CombinedEnchants[id].materials then
        for _, matsReq in ipairs(CombinedEnchants[id].materials) do
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
    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
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
                local material = select(2, C_Item.GetItemInfo(itemId))
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
    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
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
                if #currentString + #addition + 2 > 200 then -- +2 for potential comma and space
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

function GetAllReqEnchNoLink(customerName)
    local customerName = string.lower(customerName)
    -- Count the occurrences of each enchantment
    local enchantCounts = {}
    local AllEnchsReq = ""
    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
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

function CheckIfPartyMember(customerName)
    local customerName = string.lower(customerName)
    local inRaid = IsInRaid()
    local groupSize = GetNumGroupMembers()

    if inRaid then
        for i = 1, groupSize do
            local name, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
            if name ~= nil then
                name = string.lower(name)
                if name and strsplit("-", name) == customerName then
                    return true
                end
            end
        end
    else
        for i = 1, groupSize do
            local name = GetUnitName("party" .. i, true)
            if name ~= nil then
                name = string.lower(name)
                if name and strsplit("-", name) == customerName then
                    return true
                end
            end
        end
    end

    return false
end

function PEStripColourCodes(txt)
	local txt = txt or ""
	txt = string.gsub( txt, "|c%x%x%x%x%x%x%x%x", "" )
	txt = string.gsub( txt, "|c%x%x %x%x%x%x%x", "" ) -- the trading parts colour has a space instead of a zero for some weird reason
	txt = string.gsub( txt, "|r", "" )
	return txt
end

function PEItemCache()
    local NoneCachedItems = ""
    local CachedItems = ""
    local CachedSpells = ""
    local itemLink = ""
    local itemName = ""
    local cachedCount = 0
    local uncachedCount = 0
    for _, itemID in pairs(ProEnchantersItemCacheTable) do
        itemLink = select(2, C_Item.GetItemInfoInstant(itemID))
        itemName, itemLink = GetItemInfo(itemID)
        --print(itemLink)
        if not itemLink then
            uncachedCount = uncachedCount + 1
            NoneCachedItems = NoneCachedItems .. itemID .. ", "
        elseif itemLink then
            cachedCount = cachedCount + 1
            CachedItems = CachedItems .. itemLink .. ", "
        end
    end
    local totalCount = cachedCount + uncachedCount
    --[[if uncachedCount > 0 then
        print("Consider doing a /pe recache," .. cachedCount .. " out of " .. totalCount .. " reagents cached")
    end]]
    if uncachedCount == 0 then
        return true
    else 
        return false
    end
    for _, profType in ipairs(PEProfessionsOrder) do
        for _, spellId in ipairs(PEProfessionsCombined[profType].craftIds) do
            GameTooltip:AddSpellByID(spellId)
        end
    end
    --[[cachedCount = 0
    uncachedCount = 0
    for _, id in pairs(PEReagentItems) do
        itemName, itemLink = GetItemInfo(id)
        if not itemLink then
            uncachedCount = uncachedCount + 1
            NoneCachedItems = NoneCachedItems .. id .. ", "
        elseif itemLink then
            cachedCount = cachedCount + 1
            CachedItems = CachedItems .. itemLink .. ", "
        end
        --local itemInfo = C_Item.GetItemInfoInstant(id)
    end
    print("All Reagents: " .. cachedCount .. " items cached, " .. uncachedCount .. " uncached")
    -- print("Item Cache complete")]]
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
                            local itemName = select(2, C_Item.GetItemInfo(itemID)) or "Unknown Item"
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

    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
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
                    local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                    matsRemaining[itemName] = quantity
                end
            end

            -- For each slot 1,6 in trade window, get item and itemcount
            --
            --[[local tradetargetName = UnitName("NPC")
			if PEtradeWho == nil then
				return {"No info to display"}
			end
			local tradetargetloweredName = string.lower(tradetargetName)
			local SlotTypeInput = ""]]

            for slot = 1, 6 do
                local _, _, targetQuantity = GetTradeTargetItemInfo(slot)
                local targetItemLink = GetTradeTargetItemLink(slot)

                if targetItemLink ~= nil then
                    local itemId = targetItemLink:match(":(%d+):")
                    local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                    if matsRemaining[itemName] then
                        local currentAmount = tonumber(matsRemaining[itemName])
                        local newAmount = currentAmount + targetQuantity
                        matsRemaining[itemName] = newAmount
                    else
                        matsRemaining[itemName] = targetQuantity
                    end
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
                local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
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
                    local line = RED ..
                        matsRemainingQuantity .. " / " .. matsNeededQuantity .. ColorClose .. " " .. matReqName
                    table.insert(matsDiff, line)
                elseif matsRemainingQuantity < matsNeededQuantity then
                    local line = YELLOW ..
                        matsRemainingQuantity .. " / " .. matsNeededQuantity .. ColorClose .. " " .. matReqName
                    table.insert(matsDiff, line)
                elseif matsRemainingQuantity == matsNeededQuantity then
                    local line = GREEN ..
                        matsRemainingQuantity .. " / " .. matsNeededQuantity .. ColorClose .. " " .. matReqName
                    table.insert(matsDiff, line)
                elseif matsRemainingQuantity > matsNeededQuantity then
                    local line = VIOLET ..
                        matsRemainingQuantity .. " / " .. matsNeededQuantity .. ColorClose .. " " .. matReqName
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
    if matsDiff == nil then
        return { "No info to display" }
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
        return {}, false -- Return an empty table and false if no trade history exists
    end

    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
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
                    local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                    matsRemaining[itemName] = quantity
                end
            end

            for slot = 1, 6 do
                local _, _, targetQuantity = GetTradeTargetItemInfo(slot)
                local targetItemLink = GetTradeTargetItemLink(slot)

                if targetItemLink ~= nil then
                    local itemId = targetItemLink:match(":(%d+):")
                    local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                    if matsRemaining[itemId] then
                        local currentAmount = tonumber(matsRemaining[itemId])
                        local newAmount = currentAmount + targetQuantity
                        matsRemaining[itemId] = newAmount
                    else
                        matsRemaining[itemId] = targetQuantity
                    end
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
            local itemName
            for material, quantity in pairs(totalMaterials) do
                local itemId = material:match(":(%d+):")
                if itemId then
                    itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                else
                    itemName = "Unknown Item"
                end
                matsNeeded[itemName] = quantity
            end

            -- Do Math for Mats Diff
            for mat, quantity in pairs(matsNeeded) do
                local matsRemainingQuantity = matsRemaining[mat] or 0
                if matsRemainingQuantity < quantity then
                    local missingAmt = quantity - matsRemainingQuantity
                    matsDiff[mat] = { q = missingAmt, r = matsRemainingQuantity }
                    matsMissingCheck = true
                end
            end
            return matsDiff, matsMissingCheck
        end
    end
    return {}, false -- Return an empty table and false if no matching frameInfo found
end

function LinkMissingMats(enchantID, customerName)
    local customerName = string.lower(customerName)
    local enchantID = enchantID
    local enchantName = CombinedEnchants[enchantID].name
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
        local material = select(2, C_Item.GetItemInfo(itemId))
        local addition = quantity.q .. "x " .. material .. "(" .. quantity.r .. " received)"
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
                    local msgReq = "Mat's Missing for " .. enchantName .. ": " .. matsString
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
                    local msgReq = "Mat's Missing for " .. enchantName .. ": " .. matsString
                    SendChatMessage(capPlayerName .. " " .. msgReq, IsInRaid() and "RAID" or "PARTY")
                elseif i > 1 then
                    local msgReq = "Mat's Missing: " .. matsString
                    SendChatMessage(capPlayerName .. " cont'd " .. msgReq, IsInRaid() and "RAID" or "PARTY")
                end
            end
        elseif customerName and customerName ~= "" then
            for i, matsString in ipairs(AllMatsMissing) do
                if i == 1 then
                    local msgReq = "Mat's Missing for " .. enchantName .. ": " .. matsString
                    SendChatMessage(msgReq, "WHISPER", nil, customerName)
                elseif i > 1 then
                    local msgReq = "Mat's Missing: " .. matsString
                    SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, customerName)
                end
            end
        else
            for i, matsString in ipairs(AllMatsMissing) do
                if i == 1 then
                    local msgReq = "Mat's Missing for " .. enchantName .. ": " .. matsString
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

function ProEnchantersGetAnnounceMatsDiff(customerName)
    local customerName = string.lower(customerName)
    local matsNeeded = {}
    local matsNeededQuantity = 0
    local matsRemaining = {}
    local matsRemainingQuantity = 1
    local matsDiff = {}
    local matsMissingCheck = 0
    local enchantCounts = {}
    -- Assuming ProEnchantersTradeHistory[customerName] is a list (table in Lua) of items
    if ProEnchantersTradeHistory[customerName] == nil then
        local line = "No customer name found"
        matsMissingCheck = 1
        table.insert(matsDiff, line)
        return matsDiff, matsMissingCheck
    end

    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}

            -- Create Mats Remaining table
            if useAllMats == true then
                local _, allMatsAvailable = PESearchInventoryForItems()
                for itemID, quantity in pairs(allMatsAvailable) do -- change this to check inventory
                    matsRemaining[itemID] = quantity
                end
            else
                for material, quantity in pairs(frameInfo.ItemsTradedIn) do
                    local itemId = material:match(":(%d+):")
                    local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                    matsRemaining[itemId] = quantity
                end
            end

            -- For each slot 1,6 in trade window, get item and itemcount
            --
            --[[local tradetargetName = UnitName("NPC")
			if PEtradeWho == nil then
				return {"No info to display"}
			end
			local tradetargetloweredName = string.lower(tradetargetName)
			local SlotTypeInput = ""]]

            for slot = 1, 6 do
                local _, _, targetQuantity = GetTradeTargetItemInfo(slot)
                local targetItemLink = GetTradeTargetItemLink(slot)

                if targetItemLink ~= nil then
                    local itemId = targetItemLink:match(":(%d+):")
                    local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                    if matsRemaining[itemId] then
                        local currentAmount = tonumber(matsRemaining[itemId])
                        local newAmount = currentAmount + targetQuantity
                        matsRemaining[itemId] = newAmount
                    else
                        matsRemaining[itemId] = targetQuantity
                    end
                end
            end

            -- Check if the Enchants table is empty
            if next(frameInfo.Enchants) == nil then
                -- The Enchants table is empty, return or break as needed
                local line = "No requested enchants detected"
                matsMissingCheck = 2
                table.insert(matsDiff, line)
                return matsDiff, matsMissingCheck
            end

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
                local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                matsNeeded[itemId] = quantity
            end

            -- Do Math for Mats Diff
            for mat, quantity in pairs(matsNeeded) do
                local matReqName = mat
                matsNeededQuantity = quantity
                matsRemainingQuantity = 0
                if matsRemaining[mat] then
                    matsRemainingQuantity = tonumber(matsRemaining[mat])
                end
                if matsRemainingQuantity < matsNeededQuantity then
                    local missingAmount = matsNeededQuantity - matsRemainingQuantity
                    matsDiff[mat] = { q = missingAmount, r = matsRemainingQuantity }
                end
            end
            if next(matsDiff) == nil then
                matsMissingCheck = 1
                return { "No missing mats found" }, matsMissingCheck
            end
            return matsDiff, matsMissingCheck
        end
    end
    if matsDiff == nil then
        matsMissingCheck = 1
        return { "No info to display" }, matsMissingCheck
    end
end

function LinkAllMissingMats(customerName)
    local customerName = string.lower(customerName)
    local missingMats = {}
    local currentString = ""
    local AllMatsMissing = {}
    local itemcount = 1
    local check = 0

    -- For each in missingMats do the 1-5 max per line then new line etc before whispering or sending message, also figure out a way to include a button or hook last pressed secureaction button and if enchant click failed generate the linkmissingmats based on the enchantID of the spell button?
    missingMats, check = ProEnchantersGetAnnounceMatsDiff(customerName)
    missingMats = missingMats or {}

    if check >= 1 then
        --print(missingMats[1])
        return
    end

    -- Convert table into line for sending

    for itemId, quantity in pairs(missingMats) do
        --local itemId = material:match(":(%d+):")
        local material = select(2, C_Item.GetItemInfo(itemId))
        local addition = quantity.q .. "x " .. material .. "(" .. quantity.r .. " received)"
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
                    local msgReq = "Mat's still missing: " .. matsString
                    SendChatMessage(msgReq, "WHISPER", nil, customerName)
                elseif i > 1 then
                    local msgReq = "Mat's still missing: " .. matsString
                    SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, customerName)
                end
            end
        elseif CheckIfPartyMember(customerName) == true then
            local capPlayerName = CapFirstLetter(customerName)
            for i, matsString in ipairs(AllMatsMissing) do
                if i == 1 then
                    local msgReq = "Mat's still missing: " .. matsString
                    SendChatMessage(capPlayerName .. " " .. msgReq, IsInRaid() and "RAID" or "PARTY")
                elseif i > 1 then
                    local msgReq = "Mat's still missing: " .. matsString
                    SendChatMessage(capPlayerName .. " cont'd " .. msgReq, IsInRaid() and "RAID" or "PARTY")
                end
            end
        elseif customerName and customerName ~= "" then
            for i, matsString in ipairs(AllMatsMissing) do
                if i == 1 then
                    local msgReq = "Mat's still missing: " .. matsString
                    SendChatMessage(msgReq, "WHISPER", nil, customerName)
                elseif i > 1 then
                    local msgReq = "Mat's still missing: " .. matsString
                    SendChatMessage("Cont'd " .. msgReq, "WHISPER", nil, customerName)
                end
            end
        else
            for i, matsString in ipairs(AllMatsMissing) do
                if i == 1 then
                    local msgReq = "Mat's still missing: " .. matsString
                    SendChatMessage(msgReq, IsInRaid() and "RAID" or "PARTY")
                elseif i > 1 then
                    local msgReq = "Mat's still missing: " .. matsString
                    SendChatMessage("Cont'd " .. msgReq, IsInRaid() and "RAID" or "PARTY")
                end
            end
        end
    else
        print("No Customer Name found")
        --Whisper/say trade target Missing Mats
    end
end

function ProEnchantersGetConvertableMats(customerName)
    local customerName = string.lower(customerName)
    local matsConvertable = {}
    local matsRemaining = {}
    -- Assuming ProEnchantersTradeHistory[customerName] is a list (table in Lua) of items
    if ProEnchantersTradeHistory[customerName] == nil then
        --print("No trade history for customer:", customerName)
        return {}, false -- Return an empty table and false if no trade history exists
    end

    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}

            -- Create Mats Remaining table
            if useAllMats == true then
                local _, allMatsAvailable = PESearchInventoryForItems()
                for itemID, quantity in pairs(allMatsAvailable) do -- change this to check inventory
                    matsRemaining[itemID] = quantity
                    --print(itemID .. " added to matsRemaining table with quantity " .. quantity)
                end
            else
                for material, quantity in pairs(frameInfo.ItemsTradedIn) do
                    local itemId = material:match(":(%d+):")
                    local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                    matsRemaining[itemId] = quantity
                    --print(itemId .. " added to matsRemaining table with quantity " .. quantity)
                end
            end

            for index, cId in ipairs(PEConvertablesId) do
                for id, quantity in pairs(matsRemaining) do
                    --print("comparing " .. id .. " to " .. cId)
                    if string.find(id, cId, 1, true) then
                        --print("id matches cId in GetConvertableMats")
                        matsConvertable[cId] = { name = PEConvertablesName[index], quantity = quantity, id = id }
                        --print("adding " .. cId .. " to table with values: name- " .. PEConvertablesName[index] .. " quantity- " .. quantity)
                        break
                    end
                end
            end
            return matsConvertable, true
        end
    end
    return {}, false
end

function ProEnchantersConvertMats(customerName, index)
    local customerName = string.lower(customerName)
    local matsRemaining = {}
    -- Assuming ProEnchantersTradeHistory[customerName] is a list (table in Lua) of items
    if ProEnchantersTradeHistory[customerName] == nil then
        --print("No trade history for customer:", customerName)
        return {}, false -- Return an empty table and false if no trade history exists
    end

    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
        if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
            frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}

            -- Create Mats Remaining table
            if useAllMats == true then
                return
            else
                for material, quantity in pairs(frameInfo.ItemsTradedIn) do
                    local itemId = material:match(":(%d+):")
                    local itemName = select(2, C_Item.GetItemInfo(itemId)) or "Unknown Item"
                    matsRemaining[itemId] = quantity
                end
            end

            local itemConvertedName = PEConvertablesName[index]
            local itemConvertedId = PEConvertablesId[index]
            --print("itemConverted set to name/id: " .. itemConvertedName .. "/" .. itemConvertedId)

            local _, itemsAvailable = PESearchInventoryForItems()
            local currentQuantity = 0
            for itemID, quantity in pairs(itemsAvailable) do -- change this to check inventory
                if string.find(itemID, itemConvertedId, 1, true) then
                    currentQuantity = quantity
                    --print(itemID .. " added to matsRemaining table with quantity " .. quantity)
                    break
                end
            end
            --print("current quantity set to " .. currentQuantity)

            for id, quantityRemaining in pairs(matsRemaining) do
                if string.find(itemConvertedId, id, 1, true) then
                    --print("essence found in matsRemaining")
                    if string.find(itemConvertedName, "Lesser", 1, true) then
                        --print("Lesser essence found")
                        for link, quantity in pairs(frameInfo.ItemsTradedIn) do
                            if string.find(link, itemConvertedId, 1, true) then
                                --print("found lesser in ItemsTradedIn, comparing quantities initial / current: " .. currentQuantity .. " / " .. quantity)
                                if currentQuantity == quantity then
                                    --print("Item not converted, either not enough to convert or bag is full")
                                elseif quantityRemaining < 3 then
                                    --print("Not enough to convert")
                                else
                                    local _, converted = C_Item.GetItemInfo(PEConvertablesId[index + 1])
                                    --print("converting to " .. converted)
                                    frameInfo.ItemsTradedIn[link] = quantityRemaining - 3
                                    local newQuantity = frameInfo.ItemsTradedIn[link]
                                    if newQuantity < 1 then
                                        frameInfo.ItemsTradedIn[link] = nil
                                    end
                                    if frameInfo.ItemsTradedIn[converted] then
                                        local quant = frameInfo.ItemsTradedIn[converted]
                                        frameInfo.ItemsTradedIn[converted] = quant + 1 or 1
                                    else
                                        frameInfo.ItemsTradedIn[converted] = 1
                                    end
                                    AddTradeLine(customerName,
                                        TAN ..
                                        "Converted 3 " ..
                                        itemConvertedName .. " to 1 " .. PEConvertablesName[index + 1] .. ColorClose)
                                end
                            end
                        end
                    elseif string.find(itemConvertedName, "Greater", 1, true) then
                        for link, quantity in pairs(frameInfo.ItemsTradedIn) do
                            if string.find(link, itemConvertedId, 1, true) then
                                --print("found greater in ItemsTradedIn")
                                if currentQuantity == quantity then
                                    --print("Item not converted, either not enough to convert or bag is full")
                                elseif quantityRemaining < 1 then
                                    --print("Not enough to convert")
                                else
                                    local _, converted = C_Item.GetItemInfo(PEConvertablesId[index - 1])
                                    --print("converting to " .. converted)
                                    frameInfo.ItemsTradedIn[link] = quantityRemaining - 1
                                    local newQuantity = frameInfo.ItemsTradedIn[link]
                                    if newQuantity < 1 then
                                        frameInfo.ItemsTradedIn[link] = nil
                                    end
                                    if frameInfo.ItemsTradedIn[converted] then
                                        local quant = frameInfo.ItemsTradedIn[converted]
                                        frameInfo.ItemsTradedIn[converted] = quant + 3 or 3
                                    else
                                        frameInfo.ItemsTradedIn[converted] = 3
                                    end
                                    AddTradeLine(customerName,
                                        TAN ..
                                        "Converted 1 " ..
                                        itemConvertedName .. " to 3 " .. PEConvertablesName[index - 1] .. ColorClose)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function ProEnchantersUpdateTradeWindowButtons(customerName)
    if customerName == nil then
        return
    end
    local customerName = string.lower(customerName)
    ProEnchantersUpdateTradeWindowText(customerName)
    local SlotTypeInput = ""
    local tItemLink = GetTradeTargetItemLink(7)

    if not tItemLink then
        return
    end

    if tItemLink then
        local _, _, _, _, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(tItemLink)

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
    local enchyOffset = 0
    local convertyOffset = -30
    local enchxOffset = 15
    local frame = _G["ProEnchantersTradeWindowFrame"]
    local slotType = SlotTypeInput
    local enchantType = ""
    local enchantName = ""
    local buttoncount = 0

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
                    if ProEnchantersOptions.filters[enchantID] == true then
                        if buttoncount >= 10 then
                            break
                        end
                        local enchantName = CombinedEnchants[enchantID].name
                        local key = enchantID
                        if string.find(enchantName, slotType, 1, true) then
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
                                    -- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
                                    local matsDiff = {}
                                    local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, key)
                                    local buttonName = key .. "cusbuttonactive"
                                    local buttonNameBg = key .. "cusbuttonactivebg"
                                    if matsMissingCheck ~= true then
                                        if frame.namedButtons[buttonName] then
                                            if not frame.namedButtons[buttonName]:IsVisible() then
                                                frame.namedButtons[buttonName]:Show()
                                                frame.namedButtons[buttonNameBg]:Show()
                                                frame.namedButtons[buttonName]:SetPoint("BOTTOM", frame, "BOTTOM",
                                                    -enchxOffset, enchyOffset)
                                                frame.namedButtons[buttonNameBg]:SetPoint("BOTTOM", frame, "BOTTOM",
                                                    -enchxOffset, enchyOffset)
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
                    end
                end

                for _, enchantID in ipairs(frameInfo.Enchants) do
                    if ProEnchantersOptions.filters[enchantID] == true then
                        if buttoncount >= 10 then
                            break
                        end
                        local enchantName = CombinedEnchants[enchantID].name
                        local key = enchantID
                        if string.find(enchantName, slotType, 1, true) then
                            local enchantStats1 = CombinedEnchants[enchantID].stats
                            local enchantStats2 = string.gsub(enchantStats1, "%(", "")
                            local enchantStats3 = string.gsub(enchantStats2, "%)", "")
                            local enchantStats = string.gsub(enchantStats3, "%+", "")
                            local enchantTitleText1 = enchantName:gsub(" %- ", "\n") -- Corrected from 'value' to 'enchantName'

                            -- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
                            local matsDiff = {}
                            local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, enchantID)
                            if matsMissingCheck == true then
                                if ProEnchantersOptions.filters[key] == true then
                                    -- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
                                    local matsDiff = {}
                                    local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, key)
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
                                                frame.namedButtons[buttonName]:SetPoint("BOTTOM", frame, "BOTTOM",
                                                    -enchxOffset, enchyOffset)
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
                    end
                end

                frame.otherEnchantsBg:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset)
                frame.otherEnchants:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset, enchyOffset + 3)
                frame.otherEnchants:SetScript("OnEnter", function(self)
                    if ProEnchantersOptions["EnableTooltips"] == true then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine("|cFF800080ProEnchanters|r")
                        GameTooltip:AddLine(" ");
                        GameTooltip:AddLine("|cFFFFFFFFClick to refresh enchant buttons|r")
                        GameTooltip:Show()
                    end
                end)
                    
                frame.otherEnchants:SetScript("OnLeave", function(self)
                        if ProEnchantersOptions["EnableTooltips"] == true then
                            GameTooltip:Hide()
                        end
                    end)
                frame.otherEnchants:SetScript("OnClick", function()
                    local customerName = PEtradeWho
                    customerName = string.lower(customerName)
                    ProEnchantersUpdateTradeWindowButtons(customerName)
                end)

                enchyOffset = enchyOffset + 25


                for _, key in ipairs(keys) do
                    if buttoncount >= 10 then
                        break
                    end
                    if ProEnchantersOptions.filters[key] == true then
                        local enchantName = CombinedEnchants[key].name
                        if string.find(enchantName, slotType, 1, true) then
                            local enchantStats1 = CombinedEnchants[key].stats
                            local enchantStats2 = string.gsub(enchantStats1, "%(", "")
                            local enchantStats3 = string.gsub(enchantStats2, "%)", "")
                            local enchantStats = string.gsub(enchantStats3, "%+", "")
                            local enchantTitleText1 = enchantName:gsub(" %- ", "\n") -- Corrected from 'value' to 'enchantName'


                            -- if Mats Not Available, create additional small button with "Missing\nMats" button, else create button
                            local matsDiff = {}
                            local matsDiff, matsMissingCheck = ProEnchantersGetSingleMatsDiff(customerName, key)
                            local buttonName = key .. "buttonactive"
                            local buttonNameBg = key .. "buttonactivebg"
                            if matsMissingCheck ~= true then
                                if frame.namedButtons[buttonName] then
                                    frame.namedButtons[buttonName]:Show()
                                    frame.namedButtons[buttonNameBg]:Show()
                                    frame.namedButtons[buttonName]:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset,
                                        enchyOffset)
                                    frame.namedButtons[buttonNameBg]:SetPoint("BOTTOM", frame, "BOTTOM", -enchxOffset,
                                        enchyOffset)
                                    -- Additional logic here
                                    enchyOffset = enchyOffset + 50
                                    buttoncount = buttoncount + 1
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
                end

                for _, key in ipairs(keys) do
                    if buttoncount >= 10 then
                        break
                    end
                    if ProEnchantersOptions.filters[key] == true then
                        local enchantName = CombinedEnchants[key].name
                        if string.find(enchantName, slotType, 1, true) then
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
                                else
                                    print("button not found")
                                end
                            end
                        end
                    end
                end

                local matsConvertable, check = ProEnchantersGetConvertableMats(customerName)
                for i, id in ipairs(PEConvertablesId) do
                    local name = PEConvertablesName[i]
                    local buttonName = name .. "button"
                    local buttonNameBg = name .. "bg"
                    --print("hiding " .. buttonName)
                    frame.namedButtons[buttonNameBg]:Hide()
                    frame.namedButtons[buttonName]:Hide()
                end

                for i, id in ipairs(PEConvertablesId) do
                    for index, cid in pairs(matsConvertable) do
                        --print("comparing " .. id .. " to " .. cid.id .. " for showing buttons")
                        if string.find(id, cid.id, 1, true) then
                            local name = PEConvertablesName[i]
                            local buttonName = name .. "button"
                            --print("match found, showing button " .. buttonName)
                            local buttonNameBg = name .. "bg"
                            frame.namedButtons[buttonNameBg]:Show()
                            frame.namedButtons[buttonName]:Show()
                            frame.namedButtons[buttonName]:SetPoint("TOP", frame, "BOTTOM", -enchxOffset, convertyOffset)
                            frame.namedButtons[buttonNameBg]:SetPoint("TOP", frame, "BOTTOM", -enchxOffset,
                                convertyOffset)
                            convertyOffset = convertyOffset - 35
                        end
                    end
                end
            end
        end
    end
end

function ProEnchantersUpdateTradeWindowText(customerName)
    if customerName == nil then
        return
    end
    local customerName = string.lower(customerName)
    local tradewindowline = ""
    -- Get Trade Window Frame
    local frame = _G["ProEnchantersTradeWindowFrame"]
    local matsDiff = {}
    local currentTradeTarget = UnitName("NPC")

    matsDiff = ProEnchantersGetMatsDiff(currentTradeTarget)
    if type(matsDiff) ~= "table" then
        frame.tradewindowEditBox:SetText("No information found to display")
        return
    end
    if next(matsDiff) == nil then
        frame.tradewindowEditBox:SetText("No information found to display")
        return
    end

    for _, line in ipairs(matsDiff) do
        tradewindowline = tradewindowline .. line .. "\n"
    end
    frame.tradewindowEditBox:SetText(tradewindowline)
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
        wipe(frame.fieldscmd) -- Clear the table
        wipe(frame.fieldsmsg)
    end
end

function RemoveTradeWindowInfo()
    local frame = _G["ProEnchantersTradeWindowFrame"]
    for k, v in pairs(frame.namedButtons) do
        frame.namedButtons[k]:Hide()
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
    local reqEnchantName = CombinedEnchants[reqEnchant].name
    reqEnchantName = LIGHTSEAGREEN ..
        "REQ ENCH: " ..
        ColorClose ..
        "|cFFDA70D6|Haddon:ProEnchanters:" ..
        "reqench" .. ":" .. reqEnchant .. ":" .. customerName .. ":1234|h[" .. reqEnchantName .. "]|h|r"
    table.insert(ProEnchantersTradeHistory[customerName], reqEnchantName)

    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
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

function RemoveRequestedTradeLine(customerName, linetext)
    local customerName = string.lower(customerName)
    if not ProEnchantersTradeHistory[customerName] then
        ProEnchantersTradeHistory[customerName] = {}
        CreateCusWorkOrder(customerName)
    end

    local count = #ProEnchantersTradeHistory[customerName]

    for i = count, 1, -1 do -- Iterate backwards to safely remove items
        local entry = ProEnchantersTradeHistory[customerName][i]
        if string.find(entry, linetext, 1, true) then
            table.remove(ProEnchantersTradeHistory[customerName], i)
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

    local reqEnchantName = CombinedEnchants[reqEnchant].name -- Assuming this is defined somewhere

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

    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
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

    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
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
                    local material = select(2, C_Item.GetItemInfo(itemId))
                    if frameInfo.ItemsTradedIn[material] ~= nil then
                        local tradedQuantity = frameInfo.ItemsTradedIn[material]
                        local newQuantity = tradedQuantity - quantity

                        if newQuantity <= 0 then
                            frameInfo.ItemsTradedIn[material] = nil -- Remove the item if quantity becomes 0 or negative

                            local deficitQuantity = math.abs(newQuantity)
                            if deficitQuantity > 0 then -- Handle case where tradeQuantity exceeds currentQuantity
                                frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
                                frameInfo.ItemsTradedOut[material] = (frameInfo.ItemsTradedOut[material] or 0) +
                                    deficitQuantity
                            end
                        else
                            frameInfo.ItemsTradedIn[material] = newQuantity -- Update with the new quantity
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
                if ProEnchantersOptions["DebugLevel"] == 99 then
                    if enchCompleted ~= nil or "" then
                        print("enchCompleted set to " .. tostring(enchCompleted))
                    else
                        print("enchCompleted returned nil or blank")
                    end
                end
                if enchCompleted ~= nil then
                    local matsUsed = ProEnchants_GetReagentList(enchCompleted, reqQuantity)
                    for quantity, material in string.gmatch(matsUsed, "(%d+)x ([^,]+)") do
                        quantity = tonumber(quantity)
                        local itemId = material:match(":(%d+):")
                        local material = select(2, C_Item.GetItemInfo(itemId))
                        if frameInfo.ItemsTradedIn[material] ~= nil then
                            local tradedQuantity = frameInfo.ItemsTradedIn[material]
                            local newQuantity = tradedQuantity - quantity

                            if newQuantity <= 0 then
                                frameInfo.ItemsTradedIn[material] = nil -- Remove the item if quantity becomes 0 or negative

                                local deficitQuantity = math.abs(newQuantity)
                                if deficitQuantity > 0 then -- Handle case where tradeQuantity exceeds currentQuantity
                                    frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
                                    frameInfo.ItemsTradedOut[material] = (frameInfo.ItemsTradedOut[material] or 0) +
                                        deficitQuantity
                                end
                            else
                                frameInfo.ItemsTradedIn[material] = newQuantity -- Update with the new quantity
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

    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
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
                if enchInfo then     -- Ensure enchInfo is not nil
                    entry = ProEnchantersTradeHistory[customerName][i]
                    reqEnchantName = CombinedEnchants[enchInfo].name
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
            end
            frameInfo.Enchants = {}
        end
    end
    UpdateTradeHistory(customerName)
end

-- Get name of Ench
function GetEnchantName(reqEnchant, languageId)
    local language = ""
    if languageId == nil then
        language = "English"
    elseif languageId == "" then
        language = "English"
    else
        language = languageId
    end
    local enchName = ProEnchantersTables.Locales[reqEnchant] -- bookmark
    local enchStats = CombinedEnchants[reqEnchant].stats
    return enchName, enchStats
end

-- Function to get the trade history edit box for a given customer
function GetTradeHistoryEditBox(customerName)
    local customerName = string.lower(customerName)
    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
        if not frameInfo.Completed then
            local frameCustomerName = frameInfo.Frame.customerName -- Assuming each frame has a 'customerName' property
            if frameCustomerName == customerName then
                return frameInfo.Frame
                    .tradeHistoryEditBox -- Assuming each frame has a 'tradeHistoryEditBox' property
            end
        end
    end
    return nil -- Return nil if no matching frame is found
end

-- Function to update trade history in EditBox
function UpdateTradeHistory(customerName)
    local customerName = string.lower(customerName)
    local tradeHistoryText = ""
    for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
        if frameInfo.Frame.customerName == customerName and not frameInfo.Completed then
            if ProEnchantersTradeHistory[customerName] then
                -- Iterate from the end to the start of the history
                for i = #ProEnchantersTradeHistory[customerName], 1, -1 do
                    local line = ProEnchantersTradeHistory[customerName][i]
                    if i == #ProEnchantersTradeHistory[customerName] then
                        tradeHistoryText = line                             -- Start with the last (newest) line
                    else
                        tradeHistoryText = tradeHistoryText .. "\n" .. line -- Prepend each line
                    end
                end
            end
            if tradeHistoryText == nil then
                tradeHistoryText = "No trade history to display"
            end
            frameInfo.Frame.tradeHistoryEditBox:SetText(tradeHistoryText)
            break -- Exit the loop once the correct frame is updated
        end
    end
end

function UpdateGoldTraded()
    if GoldTraded < 0 then
        local deficitAmount = -GoldTraded
        ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetText("Gold Traded: -" .. GetMoneyString(deficitAmount))
        ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetSize(
            string.len(ProEnchantersWorkOrderFrame.GoldTradedDisplay:GetText()) + 22, 25) -- Adjust size as needed
        ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetPoint("BOTTOMRIGHT", ProEnchantersWorkOrderFrame.closeBg,
            "BOTTOMRIGHT", -15, 0)
    else
        ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetText("Gold Traded: " .. GetMoneyString(GoldTraded))
        ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetSize(
            string.len(ProEnchantersWorkOrderFrame.GoldTradedDisplay:GetText()) + 20, 25) -- Adjust size as needed
        ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetPoint("BOTTOMRIGHT", ProEnchantersWorkOrderFrame.closeBg,
            "BOTTOMRIGHT", -15, 0)
    end
end

function ResetGoldTraded()
    GoldTraded = 0
    ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetText("Gold Traded: " .. GetMoneyString(GoldTraded))
    ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetSize(
        string.len(ProEnchantersWorkOrderFrame.GoldTradedDisplay:GetText()) + 20, 25) -- Adjust size as needed
    ProEnchantersWorkOrderFrame.GoldTradedDisplay:SetPoint("BOTTOMRIGHT", ProEnchantersWorkOrderFrame.closeBg,
        "BOTTOMRIGHT", -15, 0)
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

    --[[if type(ProEnchantersLog[customerName]) ~= table then
		ProEnchantersLog[customerName] = {}
	end]]

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
                if ProEnchantersLog[customerName] == nil then
                    ProEnchantersLog[customerName] = {}
                end
                table.insert(ProEnchantersLog[customerName], TargetMoney)
                if ProEnchantersOptions["TipMsg"] then
                    local tip = ""
                    if ProEnchantersOptions["SimplifyTips"] == true then
                        local gold = floor(TargetMoney / 1e4)
                        local silver = floor(TargetMoney / 100 % 100)
                        local copper = TargetMoney % 100
                        if copper > 0 then
                            tip = tostring(copper) .. "c"
                        end
                        if silver > 0 then
                            if tip == "" then
                                tip = tostring(silver) .. "s"
                            else
                                tip = tostring(silver) .. "s, " .. tip
                            end
                        end
                        if gold > 0 then
                            if tip == "" then
                                tip = tostring(gold) .. "g"
                            else
                                tip = tostring(gold) .. "g, " .. tip
                            end
                        end
                    else
                        tip = tostring(GetCoinText(TargetMoney))
                    end
                    local tipMsg = ProEnchantersOptions["TipMsg"]
                    local capPlayerName = CapFirstLetter(PEtradeWho)
                    local newTipMsg1 = string.gsub(tipMsg, "CUSTOMER", capPlayerName)
                    local newTipMsg2 = string.gsub(newTipMsg1, "MONEY", tip)
                    DoEmote(ProEnchantersOptions["TipEmote"], PEtradeWho)
                    --string.gsub(meResponseSender, "PLAYER", function(mePlayer2) table.insert(mePlayer, mePlayer2) return sender end)
                    if tipMsg == "" then
                        --print(PEtradeWho .. " tipped " .. tip)
                    else
                        if CheckIfPartyMember(PEtradeWho) == true then
                            SendChatMessage(newTipMsg2, IsInRaid() and "RAID" or "PARTY")
                        else
                            SendChatMessage(newTipMsg2, "WHISPER", nil, PEtradeWho)
                        end
                    end
                else
                    DoEmote(ProEnchantersOptions["TipEmote"], PEtradeWho)
                    local tip = tostring(GetCoinText(TargetMoney))
                    local capPlayerName = CapFirstLetter(PEtradeWho)
                    if CheckIfPartyMember(PEtradeWho) == true then
                        SendChatMessage("Thanks for the " .. tip .. " tip " .. capPlayerName .. " <3",
                            IsInRaid() and "RAID" or "PARTY")
                    else
                        SendChatMessage("Thanks for the " .. tip .. " tip " .. capPlayerName .. " <3", "WHISPER", nil,
                            PEtradeWho)
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
                            AddTradeLine(customerName,
                                LIGHTYELLOW .. "OUT: " .. item.quantity .. "x " .. ColorClose .. item.link)
                            for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
                                if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
                                    frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
                                    frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}
                                    if frameInfo.ItemsTradedIn[item.link] ~= nil then
                                        local currentQuantity = frameInfo.ItemsTradedIn[item.link]
                                        local newTradeQuantity = item.quantity
                                        local newQuantity = currentQuantity - newTradeQuantity

                                        if newQuantity <= 0 then
                                            frameInfo.ItemsTradedIn[item.link] = nil -- Remove the item if quantity becomes 0 or negative

                                            local deficitQuantity = math.abs(newQuantity)
                                            if deficitQuantity > 0 then -- Handle case where tradeQuantity exceeds currentQuantity
                                                frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
                                                frameInfo.ItemsTradedOut[item.link] = (frameInfo.ItemsTradedOut[item.link] or 0) +
                                                    deficitQuantity
                                            end
                                        else
                                            frameInfo.ItemsTradedIn[item.link] =
                                                newQuantity -- Update with the new quantity
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
                            local enchantId = ""
                            for key, table in pairs(CombinedEnchants) do
                                if table.name == item.enchant then
                                    enchantId = key
                                end
                            end
                            --bookmark
                            if ProEnchantersOptions["DebugLevel"] == 99 then
                                if enchantId ~= nil or "" then
                                    print("item.enchant set to " .. tostring(item.enchant))
                                    print("enchantId set to " .. tostring(enchantId))
                                else
                                    print("enchantId returned nil or blank")
                                end
                            end
                            
                            FinishedEnchant(customerName, enchantId)
                            AddTradeLine(customerName,
                                MAGENTA ..
                                "ENCH: " .. ColorClose .. item.enchant .. MAGENTA .. " ON: " .. ColorClose .. item.link)
                            --AddTradeLine(customerName, MAGENTA .. "ON: " .. ColorClose .. item.link)
                        else
                            AddTradeLine(customerName,
                                LIGHTYELLOW .. "IN: " .. item.quantity .. "x " .. ColorClose .. item.link)
                            for _, frameInfo in pairs(ProEnchantersWorkOrderFrames) do
                                if not frameInfo.Completed and frameInfo.Frame.customerName == customerName then
                                    frameInfo.ItemsTradedOut = frameInfo.ItemsTradedOut or {}
                                    frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}
                                    if frameInfo.ItemsTradedOut[item.link] ~= nil then
                                        local currentQuantity = frameInfo.ItemsTradedOut[item.link]
                                        local newTradeQuantity = item.quantity
                                        local newQuantity = currentQuantity - newTradeQuantity

                                        if newQuantity <= 0 then
                                            frameInfo.ItemsTradedOut[item.link] = nil -- Remove the item if quantity becomes 0 or negative

                                            local deficitQuantity = math.abs(newQuantity)
                                            if deficitQuantity > 0 then -- Handle case where tradeQuantity exceeds currentQuantity
                                                frameInfo.ItemsTradedIn = frameInfo.ItemsTradedIn or {}
                                                frameInfo.ItemsTradedIn[item.link] = (frameInfo.ItemsTradedIn[item.link] or 0) +
                                                    deficitQuantity
                                            end
                                        else
                                            frameInfo.ItemsTradedOut[item.link] =
                                                newQuantity -- Update with the new quantity
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

function PEresetCurrentTradeData()
    PlayerMoney, TargetMoney, PEtradeWho = 0, 0, ""
    PEtradeWhoItems = { player = {}, target = {} }
    ItemsTraded = false
    -- reset other trade-related variables as needed
end

-- Check for Recent Msg - timepassed is 10 seconds, GetTime is seconds.miliseconds (60.100)
-- timepassed in seconds, add 10 seconds, compare current time in seconds
function CheckRecentlyWhispered(name)

        if ProEnchantersOptions["recentwhisperscheck"] ~= true then
            return false
        end

        for playername, timesent in pairs(ProEnchantersOptions["recentwhispers"]) do
            if ((name == playername) and (GetTime() < timesent+180)) then
                return true
            end
        end
    return false
end

-- Add counted whisper with current system time
function AddWhisperCount()
    table.insert(ProEnchantersOptions["whispercount"], GetTime())
end

-- Check for amount of whispers sent and return integer when whisper sent
function GetWhisperCount()
local whispercount = 0
    for i, timesent in ipairs(ProEnchantersOptions["whispercount"]) do
        if GetTime() < timesent+300 then
            whispercount = whispercount + 1
        else
            table.remove(ProEnchantersOptions["whispercount"], i)
        end
        return whispercount
    end
end

function WarnWhisperCounter()
    if ProEnchantersOptions["whispercountwarn"] == true then
        print("You have sent " .. string(GetWhisperCount()) .. " whispers in the last 5 minutes")
    end
end

-- Temp Ignore Functions

function ClearTempIgnored(name)
	for i, n in ipairs(ProEnchantersOptions.tempignore) do
		if name == n then
			table.remove(ProEnchantersOptions.tempignore, i)
		end
	end
	for i, n in ipairs(ProEnchantersOptions.filteredwords) do
		if name == n then
			table.remove(ProEnchantersOptions.filteredwords, i)
		end
	end
    ProEnchantersTriggersFrame.FilteredWords:SetText(SetFilteredEditBox())
end

function ClearAllTempIgnored()
    if ProEnchantersOptions["DebugLevel"] == 6 then
        print("Attempting to clear all temp ignored")
    end
    if type(ProEnchantersOptions["tempignore"]) == "table" then
        for i = #ProEnchantersOptions.tempignore, 1, -1 do  -- Iterate backwards
            local name = ProEnchantersOptions.tempignore[i]
            if ProEnchantersOptions["DebugLevel"] == 6 then
                print("index " .. i .. " Attempting to clear " .. name .. " from temp ignore and filtered words")
            end
            for i2, n2 in pairs(ProEnchantersOptions.filteredwords) do
                if name == n2 then
                    if ProEnchantersOptions["DebugLevel"] == 6 then
                        print("index " .. i2 .. " " .. name .. " found, removing from filtered words")
                    end
                    table.remove(ProEnchantersOptions.filteredwords, i2)
                    if ProEnchantersOptions["DebugLevel"] == 6 then
                        print("index " .. i .. " " .. name .. " found, removing from tempignore")
                    end
                    table.remove(ProEnchantersOptions.tempignore, i)
                    --break -- Exit the inner loop after removal to avoid issues
                end
            end
        end
    end
    -- Clear any leftover entries (if not removed in the loop above)
    ProEnchantersOptions["tempignore"] = {}
    ProEnchantersTriggersFrame.FilteredWords:SetText(SetFilteredEditBox())
end


function AddToTempIgnored(name)
    if type(ProEnchantersOptions["tempignore"]) ~= "table" then
        ProEnchantersOptions["tempignore"] = {}
    end
	table.insert(ProEnchantersOptions.filteredwords, name)
	table.insert(ProEnchantersOptions.tempignore, name)
    ProEnchantersTriggersFrame.FilteredWords:SetText(SetFilteredEditBox())
end

function CheckIfTempIgnored(name)
    if ProEnchantersOptions.tempignore then
        for i, n in ipairs(ProEnchantersOptions.tempignore) do
            if n == name then
                return true
            end
        end
    end
	return false
end

-- Addon Invite Functions

function RemoveFromAddonInvited(name)
    if ProEnchantersOptions["DebugLevel"] == 6 then
        print("Checking to remove " .. name .. " from addon invited table")
    end
    for n, _ in pairs(ProEnchantersOptions.addoninvited) do
        if n == name then
            if ProEnchantersOptions["DebugLevel"] == 6 then
                print("Removing " .. name .. " from addon invited table")
            end
            ProEnchantersOptions.addoninvited[n] = nil
        end
    end
end

function AddToAddonInvited(name, invtype)
    if ProEnchantersOptions["DebugLevel"] == 6 then
        print("adding " .. name .. " to addon invited table")
    end
    if invtype == nil then
        invtype = "customerinvite"
    end
    if ProEnchantersOptions.addoninvited[name] then
	    return
    else
        ProEnchantersOptions.addoninvited[name] = invtype
    end
    if ProEnchantersOptions["DebugLevel"] == 6 then
        for n, t in pairs(ProEnchantersOptions.addoninvited) do
            if n == name then
                print(name .. " added with reason " .. t)
            end
        end
    end
end

function UpdateAddonInvited(name, invtype)
    if ProEnchantersOptions["DebugLevel"] == 6 then
        print("updating " .. name .. " with invtype " .. invtype)
    end
    if invtype == nil then
        invtype = "customerinvite"
    end
    if ProEnchantersOptions.addoninvited[name] then
        ProEnchantersOptions.addoninvited[name] = invtype
    else
        if ProEnchantersOptions["DebugLevel"] == 6 then
            print(name .. " not found")
        end
    end
end

function ClearAllAddonInvited()
	ProEnchantersOptions["addoninvited"] = {}
end

function CheckIfAddonInvited(name)
    if ProEnchantersOptions["DebugLevel"] == 6 then
        print("checking to remove " .. name .. " from addon invited table")
    end
    if ProEnchantersOptions.addoninvited then
        if ProEnchantersOptions["DebugLevel"] == 6 then
            print("starting check loop")
        end
        for n, t in pairs(ProEnchantersOptions.addoninvited) do
            if n == name then
                if ProEnchantersOptions["DebugLevel"] == 6 then
                    print(name .. " found, returning true with type " .. t)
                end
                return true, t
            end
        end
    end
    if ProEnchantersOptions["DebugLevel"] == 6 then
        print(name .. " not found, returning false")
    end
	return false
end

-- afk sound setting mode

local function GetCVarSafe(cvarname)
    return tonumber(GetCVar(cvarname))
end

local function GetCVarSafeBool(cvarname)
    if GetCVarSafe(cvarname) then
        return true
    end
    return false
end

function PEafkMode(volume)
    if type(ProEnchantersOptions["soundsettings"]) ~= "table" then
        ProEnchantersOptions["soundsettings"] = {}
    end

    local vol = 1
    if volume ~= nil then
        vol = tonumber(volume)
        if type(vol) == "number" then
            vol = vol / 100
        else
            print("invalid number, setting volume to 100 percent, please choose between 1-100 next time")
            vol = 1
        end
    end

    if ProEnchantersOptions.soundsettings["afk"] == nil then
        ProEnchantersOptions.soundsettings["afk"] = false
    end

    if ProEnchantersOptions.soundsettings["afk"] == false then
        PESoundSettings = {
        se = GetCVar("Sound_EnableAllSound"),
        mv = GetCVarSafe("Sound_MasterVolume"),
        msv = GetCVarSafe("Sound_MusicVolume"),
        av = GetCVarSafe("Sound_AmbienceVolume"),
        ev = GetCVarSafe("Sound_SFXVolume"),
        dv = GetCVarSafe("Sound_DialogVolume"),
        sib = GetCVar("Sound_EnableSoundWhenGameIsInBG"),
        afk = true
        }

        if ProEnchantersOptions["DebugLevel"] == 7 then
            for n, v in pairs(PESoundSettings) do
                print(n .. ": " .. tostring(v))
            end
        end

        for n, v in pairs(PESoundSettings) do
            ProEnchantersOptions.soundsettings[n] = v
        end

        SetCVar("Sound_EnableAllSound", true)
        SetCVar("Sound_MasterVolume", vol)
        SetCVar("Sound_MusicVolume", 0)
        SetCVar("Sound_AmbienceVolume", 0)
        SetCVar("Sound_SFXVolume", 0)
        SetCVar("Sound_DialogVolume", 0)
        SetCVar("Sound_EnableSoundWhenGameIsInBG", true)

    elseif ProEnchantersOptions.soundsettings["afk"] == true then
        if ProEnchantersOptions["DebugLevel"] == 7 then
            for n, v in pairs(ProEnchantersOptions.soundsettings) do
                print(n .. ": " .. tostring(v))
            end
        end
        SetCVar("Sound_EnableAllSound", ProEnchantersOptions.soundsettings.se)
        SetCVar("Sound_MasterVolume", ProEnchantersOptions.soundsettings.mv)
        SetCVar("Sound_MusicVolume", ProEnchantersOptions.soundsettings.msv)
        SetCVar("Sound_AmbienceVolume", ProEnchantersOptions.soundsettings.av)
        SetCVar("Sound_SFXVolume", ProEnchantersOptions.soundsettings.ev)
        SetCVar("Sound_DialogVolume", ProEnchantersOptions.soundsettings.dv)
        SetCVar("Sound_EnableSoundWhenGameIsInBG", ProEnchantersOptions.soundsettings.sib)
        ProEnchantersOptions.soundsettings.afk = false

    end
end


-- Craftables Stuff

function PEGetSpellName(id) -- Getting Localized Names
    local name = C_Spell.GetSpellName(id)
    if ProEnchantersOptions["DebugLevel"] == 8 then
        if name ~= nil then
            print(name .. " found for spell name")
        else
            print("spell not found")
        end
    end
    return name
end

function PECreateLocaleProfessionsTable()
	local professions = {}
	for i = 1, #PEProfessionsOrder do
		local key = PEProfessionsOrder[i]
		local profData = PEProfessionsCombined[key]
		local profLocalizedName = PEGetSpellName(profData.profSpellId)
        if profLocalizedName ~= nil then
            professions[profLocalizedName] = {}
            professions[profLocalizedName]["LocalizedNames"] = {}
            professions[profLocalizedName]["SpellIDs"] = {}
        else
            print("create locale for professions failed")
        end
	
		for craftIndex = 1, #profData.craftIds do
			local spellLocalizedName = PEGetSpellName(profData.craftIds[craftIndex])
            if spellLocalizedName ~= nil then
                if profLocalizedName ~= spellLocalizedName then
                    table.insert(professions[profLocalizedName]["LocalizedNames"], spellLocalizedName)
                    table.insert(professions[profLocalizedName]["SpellIDs"], profData.craftIds[craftIndex])
                else
                    if ProEnchantersOptions["DebugLevel"] == 8 then
                        print(spellLocalizedName .. " matches profession name, skipping")
                    end
                end
            end
		end
	end

	return professions
end



--[[function PEGetSpellUsable(id) -- Worthless always returns true, not sure why
    local boolean, _ = C_Spell.IsSpellUsable(id)
    if ProEnchantersOptions["DebugLevel"] == 5 then
        print(tostring(boolean) .. " returned for usable")
    end
    return boolean
end]]

function PETestCastable(id) -- Counts how many times the spell could be cast currently, great for checking how many times you can do an enchant or craft an item
    local count = C_Spell.GetSpellCastCount(id)
    local name = PEGetSpellName(id)
    if ProEnchantersOptions["DebugLevel"] == 8 then
        print(tostring(count) .. " available casts on " .. name)
    end
    return name, count
end

function PECreateItemLocalizations()
    if not ProEnchantersOptions.reagents then
        ProEnchantersOptions["reagents"] = {}
    end
    local freshSync = false
    local LocalLanguage = PELocales[GetLocale()]
    if not ProEnchantersOptions.reagents["SyncLanguage"] then
        ProEnchantersOptions.reagents["SyncLanguage"] = LocalLanguage
        freshSync = true
    elseif ProEnchantersOptions.reagents["SyncLanguage"] ~= LocalLanguage then
        ProEnchantersOptions.reagents["SyncLanguage"] = LocalLanguage
        freshSync = true
    else
    end

    if freshSync == false then
        for _, id in pairs(PEReagentItems) do
                if ProEnchantersOptions.reagents[id] and ProEnchantersOptions.reagents[id].itemLink ~= nil then
                else
                local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(id)
                ProEnchantersOptions["reagents"][id] = { ["itemName"] = itemName, ["itemLink"] = itemLink, ["itemSubType"] = itemSubType }
                end
        end
    else
        for _, id in pairs(PEReagentItems) do
            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(id)
            ProEnchantersOptions["reagents"][id] = { ["itemName"] = itemName, ["itemLink"] = itemLink, ["itemSubType"] = itemSubType }
        end
    end
    --return true
end


-- Unused by maybe helpful in the future
function PEExpandTSHeaders()
    for index = GetNumTradeSkills(), 1, -1 do
        local _, skillType, _, isExpanded, _, _ = GetTradeSkillInfo(index)
        if skillType == "header" then
            ExpandTradeSkillSubClass(index)
        end
    end
end

function PEReplaceItemNamesWithLinks(spellId, amtreq)
    local craftmsg = ""
    local msg = ""
    local tempitemName = ""
    local spell = Spell:CreateFromSpellID(spellId)
    local spellName = spell:GetSpellName()
    local LocalLanguage = PELocales[GetLocale()]
    
    
        spell:ContinueOnSpellLoad(function()
        GameTooltip:AddSpellByID(spellId)end)

        if ProEnchantersOptions["DevMode"] == true then
            ProEnchantersTables.CombinedEnchants["ENCH" .. spellId] = {}
            ProEnchantersTables.CombinedEnchants["ENCH" .. spellId]["name"] = spellName
            --print(spellName)
            ProEnchantersTables.CombinedEnchants["ENCH" .. spellId]["slot"] = "temp"
            ProEnchantersTables.CombinedEnchants["ENCH" .. spellId]["spell_id"] = tonumber(spellId)
            ProEnchantersTables.CombinedEnchants["ENCH" .. spellId]["stats"] = spell:GetSpellDescription()
            ProEnchantersTables.CombinedEnchants["ENCH" .. spellId]["materials"] = {}
        end

        if ProEnchantersOptions["DebugLevel"] == 56 then
            print(LocalLanguage)
        end
        
        for i=1, GameTooltip:NumLines() do
            local text = _G["GameTooltipTextLeft"..i]:GetText()
            
            if text ~= nil then
                --print(i .. " " .. text)
            -- Reagent Section
            local filterCheck = PEenchantingLocales["Reagents"][LocalLanguage]
            --print(string.lower(filterCheck))
            
            local filtertext = string.lower(text)
            if ProEnchantersOptions["DebugLevel"] == 56 then
                print(filtertext .. i)
            end
                    if filtertext:find(string.lower(filterCheck), 1, true) then
                        --print("filtercheck matched: " .. filterCheck .. " in " .. filtertext)
                        msg = PEStripColourCodes(text)
                        msg = string.gsub(msg, filterCheck, "" )
                        msg = string.sub(msg, 3)
                        --local firstCharPos = string.find(msg, "%S")
                        --msg = string.sub(msg, firstCharPos)
                        if ProEnchantersOptions["DebugLevel"] == 56 then
                            print("msg: " .. msg)
                        end
                        local newmsg = ""
                        local items = {}
                        -- Create Table of each Reagent
                        for item in string.gmatch(msg, '([^,]+)') do
                            -- Trim whitespace from start and end
                            item = item:gsub("^%s*(.-)%s*$", "%1")
                            table.insert(items, item)
                            if ProEnchantersOptions["DebugLevel"] == 56 then
                                print("item: " .. item)
                            end
                            
                        end

                        --[[for i, v in ipairs(items) do
                            print(v)
                        end]]

                        local function parseItem(str)
                            -- Extract item name and quantity inside parentheses
                            local name, quantity = string.match(str, "^(.-)%s*%((%d+)%)%s*$")
                            
                            if name then
                                -- Trim whitespace from name
                                name = name:gsub("^%s*(.-)%s*$", "%1")
                                quantity = tonumber(quantity) -- Convert quantity to number
                            else
                                -- No quantity found, name is entire string
                                name = str:gsub("^%s*(.-)%s*$", "%1")
                                quantity = nil
                            end
                            
                            return name, quantity
                        end
                        
                        for i = 1, #items do 
                            local reagent, quantity = parseItem(items[i])
                            if ProEnchantersOptions["DebugLevel"] == 56 then
                                print("reagent: " .. reagent)
                            end
                            for id , t in pairs(ProEnchantersOptions.reagents) do
                            --print(t.itemName)
                                if t.itemName then
                                    tempitemName = t.itemName
                                    --print(tempitemName)
                                else
                                    tempitemName = "skipthisone"
                                end
                                if quantity == nil then
                                    quantity = 1
                                end
                               
                                if reagent == tempitemName then -- Need to find a way to not replace Enchanted Iron Bar with Iron Bar during the check
                                if ProEnchantersOptions["DebugLevel"] == 56 then
                                        print("tempitemName: " .. tempitemName .. " matches " .. reagent)
                                    end
                                    --print(t.itemName .. " found in " .. msg)
                                    local material = select(2, C_Item.GetItemInfo(id))
                                    local quant = tonumber(quantity) * tonumber(amtreq)
                                    if ProEnchantersOptions["DebugLevel"] == 56 then
                                        if material ~= nil then
                                            print("material: " .. material)
                                        else
                                            print("material is nil")
                                        end
                                    end
                                    --print(material)
                                    if ProEnchantersOptions["DevMode"] == true then
                                        print(tostring(quant) .. "x " .. material)
                                        table.insert(ProEnchantersTables.CombinedEnchants["ENCH" .. spellId]["materials"], tostring(quant) .. "x " .. material)
                                    end

                                    if newmsg == "" then
                                        newmsg = material .. " x " .. quant
                                    else
                                        newmsg = newmsg .. ", " .. material .. " x " .. quant
                                    end
                                    if ProEnchantersOptions["DebugLevel"] == 56 then
                                        print("newmsg: " .. newmsg)
                                    end
                                    --print(msg)
                                end
                            end
                        end
                        return newmsg
                    end
                end
            end
        end


function PECreateLocalesAllEnchants()
    if ProEnchantersTables == nil then
        ProEnchantersTables = {}
    else
        --print("ProEnchantersTables exists")
    end
    if ProEnchantersTables.Locales == nil then
        ProEnchantersTables.Locales = {}
    else
        --print("ProEnchantersTables.Locales exists")
    end
    --print("starting loop")
    for i, t in pairs(CombinedEnchants) do
    --print(tostring(i))
    local enchKey = tostring(i)
    --print(enchKey)
    local profLocalizedName = PEGetSpellName(t.spell_id)
    --print(profLocalizedName)
    ProEnchantersTables.Locales[enchKey] = profLocalizedName
    end
end