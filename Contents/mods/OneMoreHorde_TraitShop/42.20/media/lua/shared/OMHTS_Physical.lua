local Physical = {}
Physical.families = {
    Strength = { "base:weak", "base:feeble", "base:stout", "base:strong" },
    Fitness = { "base:unfit", "base:out of shape", "base:fit", "base:athletic" },
}

---@nodiscard
---@param id string
---@return string|nil
function Physical.stat(id)
    for stat, family in pairs(Physical.families) do
        for index = 1, #family do
            if family[index] == id then return stat end
        end
    end
    return nil
end

---@nodiscard
---@param stat string
---@param level number
---@return string|nil
function Physical.trait(stat, level)
    local family = Physical.families[stat]
    if level <= 1 then return family[1] end
    if level <= 4 then return family[2] end
    if level == 5 then return nil end
    if level <= 8 then return family[3] end
    return family[4]
end

---@nodiscard
---@param player IsoPlayer
---@param definition CharacterTraitDefinition
---@param startingLevel number|nil
---@return table|nil
---@return string|nil
function Physical.preview(player, definition, startingLevel)
    local id = tostring(definition:getType())
    local stat = Physical.stat(id)
    if not stat then return nil end
    local perk = Perks.FromString(stat)
    local boosts = transformIntoKahluaTable(definition:getXpBoosts())
    local amount = tonumber(tostring(boosts[perk]))
    if not amount or amount == 0 or (amount < 0) ~= (definition:getCost() < 0) then
        return nil, "unsupported"
    end
    local before = player:getPerkLevel(perk)
    if startingLevel ~= nil then
        before = startingLevel
    end
    local after = math.min(10, before + math.abs(amount))
    if amount < 0 then
        after = math.max(5, after)
    end
    if after <= before then return nil, "no_effect" end
    if player:isAsleep() then return nil, "asleep" end
    if stat == "Fitness" and not player:getNutrition():canAddFitnessXp() then return nil, "nutrition" end
    local xp = player:getXp():getXP(perk) + perk:getTotalXpForLevel(after) - perk:getTotalXpForLevel(before)
    return { stat = stat, before = before, after = after, xp = math.min(perk:getTotalXpForLevel(10), xp),
        beforeTrait = Physical.trait(stat, before), afterTrait = Physical.trait(stat, after) }
end

---@param player IsoPlayer
---@param definitions table<string, CharacterTraitDefinition>
---@param changes table<string, boolean>
---@return table|nil
---@return string|nil
function Physical.plan(player, definitions, changes)
    local plans = {}
    for pass = 1, 2 do
        for id, removing in pairs(changes) do
            local stat = Physical.stat(id)
            if stat and removing == (pass == 1) then
                local prior = plans[stat]
                local startingLevel
                if prior then
                    startingLevel = prior.after
                end
                local preview, reason = Physical.preview(player, definitions[id], startingLevel)
                if not preview then return nil, reason end
                if prior then
                    preview.before = prior.before
                    preview.beforeTrait = prior.beforeTrait
                    local perk = Perks.FromString(stat)
                    preview.xp = math.min(perk:getTotalXpForLevel(10), player:getXp():getXP(perk)
                        + perk:getTotalXpForLevel(preview.after) - perk:getTotalXpForLevel(prior.before))
                end
                plans[stat] = preview
            end
        end
    end
    return plans
end

---@nodiscard
---@param targets any
---@return boolean
function Physical.valid(targets)
    if targets == nil then return true end
    if type(targets) ~= "table" then return false end
    for stat, target in pairs(targets) do
        if not Physical.families[stat] or type(target) ~= "table"
            or type(target.xp) ~= "number" or not (target.xp >= 0 and target.xp <= 1000000000)
            or type(target.serial) ~= "number" or not (target.serial >= 1 and target.serial <= 1000000000)
            or target.serial ~= math.floor(target.serial) or type(target.applied) ~= "boolean" then return false end
    end
    return true
end

---@param targets table|nil
---@return table
function Physical.copy(targets)
    local copy = {}
    if targets == nil then return copy end
    for stat, target in pairs(targets) do
        copy[stat] = { xp = target.xp, serial = target.serial, applied = target.applied }
    end
    return copy
end

---@param player IsoPlayer
---@param targets table|nil
---@return boolean
function Physical.apply(player, targets)
    if targets == nil then return false end
    local receipts
    if isClient() then
        local data = player:getModData()
        if type(data.OMHTS_PhysicalReceipts) ~= "table" then
            data.OMHTS_PhysicalReceipts = {}
        end
        receipts = data.OMHTS_PhysicalReceipts
    end
    local changed = false
    for stat, target in pairs(targets) do
        local applied = target.applied
        if receipts then
            applied = type(receipts[stat]) == "number" and receipts[stat] >= target.serial
        end
        if not applied and not player:isAsleep() then
            local perk = Perks.FromString(stat)
            local xp = player:getXp()
            local current = xp:getXP(perk)
            if current < target.xp then
                if stat ~= "Fitness" or player:getNutrition():canAddFitnessXp() then
                    local multiplier = 1
                    if stat == "Strength" then
                        local protein = player:getNutrition():getProteins()
                        if protein > 50 and protein < 300 then
                            multiplier = 1.5
                        elseif protein < -300 then
                            multiplier = 0.7
                        end
                    end
                    xp:AddXP(perk, (target.xp - current) / multiplier, false, false, false)
                    if isServer() then
                        -- The native server grant refreshes its XP anti-cheat baseline.
                        addXpNoMultiplier(player, perk, 0)
                    end
                    changed = true
                end
            end
            if xp:getXP(perk) >= target.xp - 0.1 then
                if receipts then
                    receipts[stat] = target.serial
                else
                    target.applied = true
                end
            end
        end
    end
    return changed
end

return Physical
