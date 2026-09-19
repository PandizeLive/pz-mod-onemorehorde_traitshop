testSide = "server"
testOptions = { CharacterFreePoints = 0, NegativeTraitsPenalty = 1, ["OMHTraitShop.PositiveCostMultiplier"] = 1 }
function getSandboxOptions()
    return { getOptionByName = function(self, key)
        if testOptions[key] == nil then return nil end
        return { getValue = function() return testOptions[key] end }
    end }
end
testDefinitions = {}
function traitFixture(constant, id, cost)
    CharacterTrait[constant] = id
    local definition = { id = id, cost = cost, free = false, grants = {}, recipes = {}, boosts = {}, excludes = {} }
    function definition:getType() return self.id end
    function definition:getCost() return self.cost end
    function definition:isFree() return self.free end
    function definition:isDisabledInMultiplayer() return self.disabled == true end
    function definition:getXpBoosts() return fixtureList(self.boosts) end
    function definition:getGrantedTraits() return fixtureList(self.grants) end
    function definition:getGrantedRecipes() return fixtureList(self.recipes) end
    function definition:isMutuallyExclusive(other) return self.excludes[other.id] == true end
    function definition:getLabel() return self.id end
    function definition:getDescription() return "Trait effects for " .. self.id end
    function definition:getTexture() return nil end
    testDefinitions[id] = definition
    return definition
end
CharacterTraitDefinition.getCharacterTraitDefinition = function(trait) return testDefinitions[trait] end
CharacterTraitDefinition.getTraits = function()
    local definitions = {}
    for _, definition in pairs(testDefinitions) do definitions[#definitions + 1] = definition end
    return fixtureList(definitions)
end
traitFixture("DEXTROUS", "base:dextrous", 2)
traitFixture("FAST_READER", "base:fastreader", 2)
traitFixture("BRAVE", "base:brave", 4)
traitFixture("OUTDOORSMAN", "base:outdoorsman", 2)
traitFixture("IRON_GUT", "base:irongut", 3)
traitFixture("RESILIENT", "base:resilient", 4)
traitFixture("LIGHT_EATER", "base:lighteater", 4)
traitFixture("LOW_THIRST", "base:lowthirst", 6)
traitFixture("FAST_HEALER", "base:fasthealer", 6)
traitFixture("ORGANIZED", "base:organized", 6)
traitFixture("ALL_THUMBS", "base:allthumbs", -2).excludes["base:dextrous"] = true
traitFixture("NEGATIVE_TWO", "test:negative2", -2)
traitFixture("NEGATIVE_THREE", "test:negative3", -2)
testProfession = { cost = 8, grants = {} }
function testProfession:getCost() return self.cost end
function testProfession:getGrantedTraits() return fixtureList(self.grants) end
CharacterProfessionDefinition.getCharacterProfessionDefinition = function() return testProfession end
testSyncs = {}
function sendSyncPlayerFields(player, flags)
    testSyncs[#testSyncs + 1] = { player = player, flags = flags }
end
local basicPlayer = player
function player(name, slot, characterId, hours)
    local value = basicPlayer(name, slot, characterId, hours)
    value.traits = {}
    value.addCount = 0
    function value:hasTrait(trait) return self.traits[trait] == true end
    function value:getCharacterTraits()
        return {
            getKnownTraits = function()
                local known = {}
                for trait in pairs(value.traits) do known[#known + 1] = trait end
                return fixtureList(known)
            end,
            add = function(self, trait)
                value.traits[trait] = true
                value.addCount = value.addCount + 1
            end,
        }
    end
    return value
end

function transformIntoKahluaTable(map) return map.values end
Perks = { MAX = "MAX", None = "None" }
local fixturePerks = {}
function perkFixture(id)
    local perk = setmetatable({ id = id }, { __tostring = function(self) return self.id end })
    function perk:getName() return self.id end
    function perk:getTotalXpForLevel(level) return level * level * 100 end
    fixturePerks[id] = perk
    return perk
end
function Perks.FromString(id) return fixturePerks[id] or Perks.MAX end
perkFixture("Cooking")
perkFixture("Fitness")
perkFixture("Strength")
testOptions["OMHTraitShop.NegativeCostMultiplier"] = 2
testOptions["OMHTraitShop.AllowNegativeRemoval"] = false
local basicShopPlayer = player
function player(name, slot, characterId, hours)
    local value = basicShopPlayer(name, slot, characterId, hours)
    local getTraits = value.getCharacterTraits
    function value:getCharacterTraits()
        local traits = getTraits(self)
        traits.remove = function(self, id) value.traits[id] = nil end
        return traits
    end
    value.skillXP = {}
    value.boosts = {}
    value.recipes = {}
    value.sleeping = false
    function value:isAsleep() return self.sleeping end
    function value:getKnownRecipes()
        return { contains = function(self, name) return value.recipes[name] == true end }
    end
    function value:learnRecipe(name) self.recipes[name] = true end
    function value:getPerkLevel(perk)
        return math.floor(math.sqrt(self.skillXP[tostring(perk)] or 0) / 10)
    end
    function value:getXp()
        return {
            getXP = function(self, perk) return value.skillXP[tostring(perk)] or 0 end,
            getPerkBoost = function(self, perk) return value.boosts[tostring(perk)] or 0 end,
            setPerkBoost = function(self, perk, boost) value.boosts[tostring(perk)] = boost end,
            AddXP = function(self, perk, amount, callLua, boost, remote)
                check(not callLua and not boost and not remote, "effect recovery never reapplies XP multipliers or sends XP requests")
                local id = tostring(perk)
                value.skillXP[id] = (value.skillXP[id] or 0) + amount
            end,
        }
    end
    return value
end

function addXpNoMultiplier(player, perk, amount)
    check(isServer() and amount == 0, "server refreshes native XP grant baseline without duplicate award")
end
