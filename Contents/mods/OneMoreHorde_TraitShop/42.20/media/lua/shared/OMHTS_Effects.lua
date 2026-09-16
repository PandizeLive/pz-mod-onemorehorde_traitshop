local Catalog = require("OMHTS_Catalog")
local Effects = {}

---@nodiscard
---@param value any
---@param limit number
---@return boolean
local function bounded(value, limit)
    return type(value) == "number" and value >= 0 and value <= limit
end

---@nodiscard
---@param effects any
---@return boolean
function Effects.valid(effects)
    if type(effects) ~= "table" or type(effects.traits) ~= "table"
        or type(effects.recipes) ~= "table" or type(effects.perks) ~= "table" then return false end
    local count = 0
    for id, enabled in pairs(effects.traits) do
        if not Catalog.validId(id) or type(enabled) ~= "boolean" then return false end
        count = count + 1
    end
    if count > 256 then return false end
    count = 0
    for recipe, enabled in pairs(effects.recipes) do
        if type(recipe) ~= "string" or #recipe > 256 or enabled ~= true then return false end
        count = count + 1
    end
    if count > 512 then return false end
    count = 0
    for id, target in pairs(effects.perks) do
        if not Catalog.validId(id) or type(target) ~= "table"
            or not bounded(target.xp, 1000000000) or not bounded(target.boost, 10)
            or not bounded(target.beforeBoost, 10) or target.boost ~= math.floor(target.boost)
            or target.beforeBoost ~= math.floor(target.beforeBoost) then return false end
        count = count + 1
    end
    return count <= 64
end

---@param effects table
---@return table
function Effects.copy(effects)
    local copy = { traits = {}, recipes = {}, perks = {} }
    for id, enabled in pairs(effects.traits) do
        copy.traits[id] = enabled
    end
    for recipe in pairs(effects.recipes) do
        copy.recipes[recipe] = true
    end
    for id, target in pairs(effects.perks) do
        copy.perks[id] = { xp = target.xp, boost = target.boost, beforeBoost = target.beforeBoost }
    end
    return copy
end

---@param player IsoPlayer
---@param effects table
---@return boolean
function Effects.apply(player, effects)
    local changed = false
    for id, enabled in pairs(effects.traits) do
        local definition = Catalog.definition(id)
        if definition and player:hasTrait(definition:getType()) ~= enabled then
            if enabled then
                player:getCharacterTraits():add(definition:getType())
            else
                player:getCharacterTraits():remove(definition:getType())
            end
            changed = true
        end
        if id == "base:smoker" and not enabled then
            local stats = player:getStats()
            if stats:get(CharacterStat.NICOTINE_WITHDRAWAL) ~= 0 then
                stats:set(CharacterStat.NICOTINE_WITHDRAWAL, 0)
                changed = true
            end
            if player:getTimeSinceLastSmoke() ~= 0 then
                player:setTimeSinceLastSmoke(0)
                changed = true
            end
        end
    end
    for recipe in pairs(effects.recipes) do
        if not player:getKnownRecipes():contains(recipe) then
            player:learnRecipe(recipe)
            changed = true
        end
    end
    for id, target in pairs(effects.perks) do
        local perk = Perks.FromString(id)
        if perk and perk ~= Perks.MAX and perk ~= Perks.None then
            local xp = player:getXp()
            local current = xp:getXP(perk)
            if current < target.xp and not player:isAsleep() then
                xp:AddXP(perk, target.xp - current, false, false, false)
                changed = true
            end
            local boost = xp:getPerkBoost(perk)
            if (target.boost >= target.beforeBoost and boost < target.boost)
                or (target.boost < target.beforeBoost and boost == target.beforeBoost) then
                xp:setPerkBoost(perk, target.boost)
                changed = true
            end
        end
    end
    return changed
end

---@param player IsoPlayer
---@param previous table
---@param changes table
---@return table|nil
---@return string|nil
function Effects.plan(player, previous, changes)
    local effects = Effects.copy(previous)
    local final = {}
    local known = player:getCharacterTraits():getKnownTraits()
    for index = 0, known:size() - 1 do
        final[tostring(known:get(index))] = true
    end
    local queue = {}
    local processed = {}
    for id, removing in pairs(changes) do
        if removing then
            final[id] = nil
            effects.traits[id] = false
            processed[id] = true
        else
            queue[#queue + 1] = id
        end
    end
    local additions = {}
    local cursor = 1
    while cursor <= #queue do
        if #queue > 256 then return nil, "limit" end
        local id = queue[cursor]
        cursor = cursor + 1
        if not processed[id] then
            processed[id] = true
            local definition = Catalog.definition(id)
            local reason = Catalog.exclusion(definition)
            if reason then return nil, reason end
            if not final[id] then
                final[id] = true
                effects.traits[id] = true
                additions[#additions + 1] = definition
                local granted = definition:getGrantedTraits()
                for index = 0, granted:size() - 1 do
                    local child = tostring(granted:get(index))
                    if changes[child] ~= nil then return nil, "conflict" end
                    queue[#queue + 1] = child
                end
            end
        end
    end
    for index = 1, #additions do
        local definition = additions[index]
        for id in pairs(final) do
            local other = Catalog.definition(id)
            if other and other ~= definition and (definition:isMutuallyExclusive(other)
                or other:isMutuallyExclusive(definition)) then return nil, "conflict" end
        end
        local recipes = definition:getGrantedRecipes()
        for recipeIndex = 0, recipes:size() - 1 do
            effects.recipes[recipes:get(recipeIndex)] = true
        end
    end
    local deltas = {}
    for index = 1, #additions do
        local boosts = transformIntoKahluaTable(additions[index]:getXpBoosts())
        for perk, value in pairs(boosts) do
            value = tonumber(tostring(value))
            local id = tostring(perk)
            if not deltas[id] then
                deltas[id] = { perk = perk, levels = 0, boost = 0 }
            end
            deltas[id].levels = deltas[id].levels + math.max(0, value)
            deltas[id].boost = deltas[id].boost + value
        end
    end
    for id, removing in pairs(changes) do
        if removing then
            local boosts = transformIntoKahluaTable(Catalog.definition(id):getXpBoosts())
            for perk, value in pairs(boosts) do
                value = tonumber(tostring(value))
                local key = tostring(perk)
                if not deltas[key] then
                    deltas[key] = { perk = perk, levels = 0, boost = 0 }
                end
                deltas[key].boost = deltas[key].boost - value
            end
        end
    end
    for id, delta in pairs(deltas) do
        local perk = delta.perk
        local level = player:getPerkLevel(perk)
        local xp = player:getXp()
        local boost = xp:getPerkBoost(perk)
        if boost < 0 or boost > 10 then return nil, "unsupported" end
        local targetXP = xp:getXP(perk) + perk:getTotalXpForLevel(math.min(10, level + delta.levels))
            - perk:getTotalXpForLevel(level)
        effects.perks[id] = { xp = math.min(perk:getTotalXpForLevel(10), targetXP), beforeBoost = boost,
            boost = math.max(0, math.min(10, boost + delta.boost)) }
    end
    if not Effects.valid(effects) then return nil, "limit" end
    return effects
end

return Effects
