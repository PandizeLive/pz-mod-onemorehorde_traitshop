local Catalog = {}
Catalog.MAX_PURCHASE_TRAITS = 100
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
local approved = {}
for index = 1, #Catalog.entries do
    approved[Catalog.entries[index].id] = true
end
local registryTypes = {}
local registrySize = -1

---@return ArrayList
function Catalog.definitions()
    local definitions = CharacterTraitDefinition.getTraits()
    registryTypes = {}
    for index = 0, definitions:size() - 1 do
        local trait = definitions:get(index):getType()
        registryTypes[tostring(trait)] = trait
    end
    registrySize = definitions:size()
    return definitions
end

---@param id string
---@return boolean
function Catalog.registerMembershipTrait(id)
    if type(id) ~= "string" or #id > 128
        or not string.match(id, "^[a-z0-9_.%-]+:[a-z0-9_./%-]+$") then return false end
    if approved[id] then return true end
    if #Catalog.entries >= Catalog.MAX_PURCHASE_TRAITS then return false end
    approved[id] = true
    Catalog.entries[#Catalog.entries + 1] = { id = id }
    registrySize = -1
    return true
end

---@nodiscard
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
---@return boolean
function Catalog.supported(definition)
    return definition ~= nil and approved[tostring(definition:getType())] == true
        and not definition:isFree() and definition:getCost() > 0
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
    if not multiplier or not definition or definition:getCost() <= 0 then return nil end
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

---@return nil
local function resetRegistry()
    registryTypes = {}
    registrySize = -1
end

Events.OnInitGlobalModData.Add(resetRegistry)
return Catalog
