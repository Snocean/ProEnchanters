function PEClearCompletedWOs()
    -- if work order number history ~= then count number of work orders
    -- if number == 0 or nil set to 0, else set to count
    if ProEnchantersOptions["CurrentWOs"] == nil then
        ProEnchantersOptions["CurrentWOs"] = 0
        local count = 0
        local currentWOs = #ProEnchantersWorkOrderFrames
        if currentWOs then
        --print(currentWOs .. " work orders found")
        end
        if currentWOs == nil or currentWOs < 1 then
            if currentWOs == nil then
                ProEnchantersOptions["CurrentWOs"] = count
                return
            elseif currentWOs == 0 then
                ProEnchantersOptions["CurrentWOs"] = count
                return
            end
        else
            --print("setting CurrentWOs to " .. currentWOs)
            ProEnchantersOptions["CurrentWOs"] = currentWOs
        end
        local newcount = ProEnchantersOptions["CurrentWOs"]
        --print(newcount .. " set for CurrentWOs")
    end

    -- For i, #workorders, 1, -1 do
    -- if completed then table.remove i
    --print("Attempting to clear closed WOs")
    local currentWOs = #ProEnchantersWorkOrderFrames
    local countRemoved = 0
    for i, t in pairs(ProEnchantersWorkOrderFrames) do
        if t and t.Completed == true then
            ProEnchantersWorkOrderFrames[i] = nil
        end
    end
    --print(countRemoved .. " work orders found as completed and have been removed")
end
