local Catalog = {}
Catalog.entries = {
    { id = "base:dextrous", constant = "DEXTROUS" },
    { id = "base:fastreader", constant = "FAST_READER" },
    { id = "base:brave", constant = "BRAVE" },
    { id = "base:outdoorsman", constant = "OUTDOORSMAN" },
    { id = "base:irongut", constant = "IRON_GUT" },
    { id = "base:resilient", constant = "RESILIENT" },
    { id = "base:lighteater", constant = "LIGHT_EATER" },
    { id = "base:lowthirst", constant = "LOW_THIRST" },
    { id = "base:fasthealer", constant = "FAST_HEALER" },
    { id = "base:organized", constant = "ORGANIZED" },
}

---@nodiscard
---@param id string
---@return CharacterTraitDefinition|nil
function Catalog.definition(id)
    for index = 1, #Catalog.entries do
        local entry = Catalog.entries[index]
        if entry.id == id then
            local trait = CharacterTrait[entry.constant]
            if not trait then return nil end
            return CharacterTraitDefinition.getCharacterTraitDefinition(trait)
        end
    end
    return nil
end

---@nodiscard
---@param definition CharacterTraitDefinition|nil
---@return boolean
function Catalog.supported(definition)
    return definition ~= nil and not definition:isFree() and definition:getCost() > 0
        and definition:getXpBoosts():isEmpty() and definition:getGrantedTraits():isEmpty()
        and definition:getGrantedRecipes():isEmpty()
        and (not (isClient() or isServer()) or not definition:isDisabledInMultiplayer())
end

---@nodiscard
---@return number|nil
function Catalog.multiplier()
    local option = getSandboxOptions():getOptionByName("OMHTraitShop.PositiveCostMultiplier")
    if not option then return nil end
    local value = option:getValue()
    if type(value) ~= "number" or not (value >= 0.1 and value <= 100) then return nil end
    return value
end

---@nodiscard
---@param definition CharacterTraitDefinition
---@return number|nil
function Catalog.price(definition)
    local multiplier = Catalog.multiplier()
    if not multiplier or not Catalog.supported(definition) then return nil end
    local price = math.ceil(definition:getCost() * multiplier)
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

return Catalog
