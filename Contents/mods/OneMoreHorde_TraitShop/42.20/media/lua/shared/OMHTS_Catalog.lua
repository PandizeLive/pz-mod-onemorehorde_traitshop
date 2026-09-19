local Physical = require("OMHTS_Physical")
local Catalog = {}
Catalog.MAX_PURCHASE_TRAITS = 192
Catalog.MAX_CART = 64
Catalog.entries = {}
local registryTypes = {}
local registrySize = -1
local exclusions = {
    ["base:emaciated"] = "body", ["base:very underweight"] = "body",
    ["base:underweight"] = "body", ["base:overweight"] = "body", ["base:obese"] = "body",
}

---@nodiscard
---@param id any
---@return boolean
function Catalog.validId(id)
    if type(id) ~= "string" or #id == 0 or #id > 128 then return false end
    local bytes = 0
    for index = 1, #id do
        local unit = string.byte(id, index)
        if unit < 128 then
            bytes = bytes + 1
        elseif unit < 2048 then
            bytes = bytes + 2
        else
            bytes = bytes + 3
        end
    end
    return bytes <= 128
end

---@param definitions ArrayList|nil
---@return ArrayList
function Catalog.definitions(definitions)
    if not definitions then
        definitions = CharacterTraitDefinition.getTraits()
    end
    registryTypes = {}
    Catalog.entries = {}
    local ids = {}
    for index = 0, definitions:size() - 1 do
        local definition = definitions:get(index)
        local id = tostring(definition:getType())
        registryTypes[id] = definition:getType()
        if definition:getCost() ~= 0 and not definition:isFree() and Catalog.validId(id) then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    for index = 1, math.min(#ids, Catalog.MAX_PURCHASE_TRAITS) do
        Catalog.entries[index] = { id = ids[index] }
    end
    registrySize = definitions:size()
    return definitions
end

---@param id string
---@return boolean
function Catalog.registerMembershipTrait(id)
    if type(id) ~= "string" or #id > 128
        or not string.match(id, "^[a-z0-9_.%-]+:[a-z0-9_./%-]+$") then return false end
    registrySize = -1
    return true
end

---@param id string
---@return boolean
function Catalog.excludeTrait(id)
    if type(id) ~= "string" or #id > 128 then return false end
    exclusions[id] = "excluded"
    return true
end

---@param id string
---@return CharacterTraitDefinition|nil
function Catalog.definition(id)
    if registrySize < 0 then
        Catalog.definitions()
    end
    local trait = registryTypes[id]
    if not trait then return nil end
    return CharacterTraitDefinition.getCharacterTraitDefinition(trait)
end

---@nodiscard
---@param definition CharacterTraitDefinition|nil
---@return string|nil
function Catalog.exclusion(definition)
    if not definition then return "unsupported" end
    if not Catalog.validId(tostring(definition:getType())) then return "unsupported" end
    local reason = exclusions[tostring(definition:getType())]
    if reason then return reason end
    if (isClient() or isServer()) and definition:isDisabledInMultiplayer() then return "multiplayer" end
    local boosts = transformIntoKahluaTable(definition:getXpBoosts())
    for perk, value in pairs(boosts) do
        value = tonumber(tostring(value))
        if (tostring(perk) == "Fitness" or tostring(perk) == "Strength")
            and Physical.stat(tostring(definition:getType())) ~= tostring(perk) then return "body" end
        if type(value) ~= "number" or value ~= math.floor(value) or value < -10 or value > 10 then
            return "unsupported"
        end
    end
    return nil
end

---@nodiscard
---@param definition CharacterTraitDefinition|nil
---@return boolean
function Catalog.supported(definition)
    return definition ~= nil and not definition:isFree() and definition:getCost() > 0
        and Catalog.exclusion(definition) == nil
end

---@nodiscard
---@param removing boolean|nil
---@return number|nil
function Catalog.multiplier(removing)
    local key = "OMHTraitShop.PositiveCostMultiplier"
    if removing then
        key = "OMHTraitShop.NegativeCostMultiplier"
    end
    local option = getSandboxOptions():getOptionByName(key)
    if not option then return nil end
    local value = option:getValue()
    if type(value) ~= "number" or not (value >= 0.1 and value <= 100) then return nil end
    return value
end

---@nodiscard
---@return boolean
function Catalog.removalEnabled()
    local option = getSandboxOptions():getOptionByName("OMHTraitShop.AllowNegativeRemoval")
    return option ~= nil and option:getValue() == true
end

---@nodiscard
---@param definition CharacterTraitDefinition|nil
---@return number|nil
function Catalog.price(definition)
    if not definition or definition:getCost() == 0 then return nil end
    local multiplier = Catalog.multiplier(definition:getCost() < 0)
    if not multiplier then return nil end
    local price = math.ceil(math.abs(definition:getCost()) * multiplier)
    if price < 1 or price > 1000000000 then return nil end
    return price
end

---@nodiscard
---@param player IsoPlayer
---@param definition CharacterTraitDefinition
---@return boolean
function Catalog.conflicts(player, definition)
    local known = player:getCharacterTraits():getKnownTraits()
    for index = 0, known:size() - 1 do
        local other = CharacterTraitDefinition.getCharacterTraitDefinition(known:get(index))
        if other and (definition:isMutuallyExclusive(other) or other:isMutuallyExclusive(definition)) then
            return true
        end
    end
    return false
end

---@return nil
local function resetRegistry()
    registrySize = -1
end

Events.OnInitGlobalModData.Add(resetRegistry)
return Catalog
