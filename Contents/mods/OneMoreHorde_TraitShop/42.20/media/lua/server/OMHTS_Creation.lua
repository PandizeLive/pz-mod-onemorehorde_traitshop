if isClient() then return end

local State = require("OMHTS_State")
local Creation = {}

---@nodiscard
---@param player IsoPlayer
---@return number|nil
function Creation.remainingPoints(player)
    local profession = CharacterProfessionDefinition.getCharacterProfessionDefinition(
        player:getDescriptor():getCharacterProfession()
    )
    local free = getSandboxOptions():getOptionByName("CharacterFreePoints")
    local penalty = getSandboxOptions():getOptionByName("NegativeTraitsPenalty")
    if not profession or not free or not penalty then return nil end
    local points = profession:getCost() + free:getValue()
    local penaltyValue = penalty:getValue()
    if penaltyValue < 1 or penaltyValue > 4 then return nil end
    local granted = {}
    local queue = {}
    local professionTraits = profession:getGrantedTraits()
    for index = 0, professionTraits:size() - 1 do
        local trait = professionTraits:get(index)
        granted[trait] = true
        queue[#queue + 1] = trait
    end
    local known = player:getCharacterTraits():getKnownTraits()
    for index = 0, known:size() - 1 do
        queue[#queue + 1] = known:get(index)
    end
    local visited = {}
    local index = 1
    while index <= #queue do
        if index > 1000 then return nil end
        local trait = queue[index]
        if not visited[trait] then
            visited[trait] = true
            local definition = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
            if not definition then return nil end
            local children = definition:getGrantedTraits()
            for childIndex = 0, children:size() - 1 do
                local child = children:get(childIndex)
                granted[child] = true
                queue[#queue + 1] = child
            end
        end
        index = index + 1
    end
    local negatives = 0
    local counted = {}
    for knownIndex = 0, known:size() - 1 do
        local trait = known:get(knownIndex)
        if not counted[trait] then
            counted[trait] = true
            local definition = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
            if not definition then return nil end
            if not granted[trait] and not definition:isFree() then
                local cost = definition:getCost()
                points = points - cost
                if cost < 0 then
                    negatives = negatives + 1
                end
            end
        end
    end
    local offset = 0
    if penaltyValue == 2 then
        offset = math.floor(negatives / 3)
    elseif penaltyValue == 3 then
        offset = math.floor(negatives / 2)
    elseif penaltyValue == 4 and negatives > 0 then
        offset = negatives - 1
    end
    points = points - offset
    if not State.isCounter(points) then return nil end
    return points
end

---@param player IsoPlayer
---@param record table
---@param capturedPoints number|nil
---@return boolean
function Creation.settle(player, record, capturedPoints)
    if record.life.creation.status ~= "pending" then return false end
    if record.revision >= State.LIMIT then return false end
    local points = capturedPoints
    if points == nil then
        points = Creation.remainingPoints(player)
    end
    if not State.isCounter(points) or not State.isCounter(record.life.tokens + points) then
        record.life.creation.status = "invalid"
    else
        record.life.tokens = record.life.tokens + points
        record.life.creation.tokens = points
        record.life.creation.status = "granted"
    end
    record.revision = record.revision + 1
    return true
end

return Creation
