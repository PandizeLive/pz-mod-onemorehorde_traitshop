__modules = {}
pairs = table.pairs
testChecks = 0
testSide = "singleplayer"
testClock = 10000
testPlayers = {}
testPackets = {}
testTables = {}

function require(name) return __modules[name] end
function isClient() return testSide == "client" end
function isServer() return testSide == "server" end
function getTimestampMs() return testClock end
function fixtureList(values)
    return { size = function() return #values end, get = function(self, index) return values[index + 1] end,
        isEmpty = function() return #values == 0 end }
end
CharacterTrait = {}
CharacterTraitDefinition = { getCharacterTraitDefinition = function() return nil end,
    getTraits = function() return fixtureList({}) end }
CharacterProfessionDefinition = { getCharacterProfessionDefinition = function()
    return { getCost = function() return 0 end, getGrantedTraits = function() return fixtureList({}) end }
end }
function getSandboxOptions()
    return { getOptionByName = function(self, key)
        return { getValue = function()
            if key == "CharacterFreePoints" then return 0 end
            return 1
        end }
    end }
end
function sendSyncPlayerFields(player, flags) end
function instanceof(object, name) return object.kind == name end
function getNumActivePlayers() return #testPlayers end
function getSpecificPlayer(index) return testPlayers[index + 1] end
function getOnlinePlayers()
    return { size = function() return #testPlayers end, get = function(self, index) return testPlayers[index + 1] end }
end
function sendServerCommand(player, module, command, args)
    testPackets[#testPackets + 1] = { player = player, module = module, command = command, args = nativeRoundTrip(args) }
end
function sendClientCommand(player, module, command, args)
    testPackets[#testPackets + 1] = { player = player, module = module, command = command, args = args }
end
function check(value, label)
    testFailure = label
    if not value then error(label) end
    testChecks = testChecks + 1
end
function event()
    local handlers = {}
    return {
        Add = function(handler) handlers[#handlers + 1] = handler end,
        fire = function(...)
            for index = 1, #handlers do handlers[index](...) end
        end,
    }
end
Events = {}
local names = { "OnInitGlobalModData", "OnCreatePlayer", "OnCharacterDeath", "OnTick", "OnSave", "OnClientCommand", "OnDisconnect", "OnGameStart", "OnServerCommand" }
for index = 1, #names do Events[names[index]] = event() end
ModData = {}
function ModData.getOrCreate(key)
    if not testTables[key] then testTables[key] = {} end
    return testTables[key]
end
function player(name, slot, characterId, hours)
    local value = { kind = "IsoPlayer", name = name, slot = slot, characterId = characterId, hours = hours, dead = false, modData = {} }
    function value:getPlayerNum() return self.slot end
    function value:getUsername() return self.name end
    function value:getDescriptor() return { getID = function() return self.characterId end,
        getCharacterProfession = function() return "unemployed" end } end
    function value:getCharacterTraits() return { getKnownTraits = function() return fixtureList({}) end } end
    function value:hasTrait(trait) return false end
    function value:getHoursSurvived() return self.hours end
    function value:isDead() return self.dead end
    function value:getModData() return self.modData end
    return value
end
