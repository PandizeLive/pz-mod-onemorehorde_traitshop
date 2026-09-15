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
