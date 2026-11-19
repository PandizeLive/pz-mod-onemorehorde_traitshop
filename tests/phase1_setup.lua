__modules = {}
pairs = table.pairs
testChecks = 0
testSide = "singleplayer"
testClock = 10000
testPlayers = {}
testPackets = {}
testTables = {}
testWorldHours = 7
testHorde = false
SandboxVars = { DayNightCycle = 1, OMHTraitShop = { RewardMode = 4, ZombieXP = 2,
    PlayerKillXP = 75, PlayerKillCooldownDays = 2, DayXP = 0, NightXP = 25,
    HordeZombieXP = 5, HordeSurvivedXP = 100 } }
function getActivatedMods() return { contains = function(self, id) return testHorde end } end
function getGameTime()
    return { getWorldAgeHours = function() return testWorldHours end,
        getTimeOfDay = function() return testWorldHours % 24 end,
        getYear = function() return 1993 end, getMonth = function() return 6 end,
        getDayPlusOne = function() return 9 end,
        daysInMonth = function(self, year, month) return 31 end }
end
function fixtureSeason()
    return { clone = function() return fixtureSeason() end, setDay = function() end,
        getDawn = function() return 5 end, getDusk = function() return 23 end }
end
function getClimateManager()
    return { getSeason = function() return fixtureSeason() end,
        getCurrentDay = function() return { getYear = function() return 1993 end,
            getMonth = function() return 6 end, getDay = function() return 9 end } end }
end
Faction = { isInSameFaction = function(a, b) return a.faction ~= nil and a.faction == b.faction end }

function require(name) return __modules[name] end
function isClient() return testSide == "client" end
function isServer() return testSide == "server" end
function getTimestampMs() return testClock end
function fixtureList(values)
    return { values = values, size = function() return #values end, get = function(self, index) return values[index + 1] end,
        isEmpty = function() return #values == 0 end,
        contains = function(self, value) for i=1,#values do if values[i] == value then return true end end return false end }
end
CharacterTrait = {}
CharacterTraitDefinition = { getCharacterTraitDefinition = function() return nil end,
    getTraits = function() return fixtureList({}) end }
CharacterProfessionDefinition = { getCharacterProfessionDefinition = function()
    return { getCost = function() return 0 end, getGrantedTraits = function() return fixtureList({}) end }
end }
function getSandboxOptions()
    return { getOptionByName = function(self, key)
        if key == "OMHTraitShop.RewardMode" then
            return { setValue = function() end, setDefaultToCurrentValue = function() end }
        end
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
    return fixtureList(testPlayers)
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
Events.OnSGlobalObjectSystemInit = event()
Events.OnConnected = event()
local names = { "OnInitGlobalModData", "OnNewGame", "OnCreatePlayer", "OnCharacterDeath", "OnZombieDead", "OnZombieCreate", "OnTick", "OnSave", "OnClientCommand", "OnDisconnect", "OnGameStart", "OnServerCommand", "OnWeaponHitCharacter", "OnWeaponHitXp" }
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
    function value:getAttackedBy() return self.killer end
    return value
end

testFiles = {}
function getWorld() return {getGameMode=function() return "Sandbox" end,getWorld=function() return "Fixture" end} end
function getFileWriter(path)
    return {write=function(self,value) testFiles[path]=value end,close=function() end}
end
function getFileReader(path)
    if not testFiles[path] then return nil end
    return {readLine=function() return testFiles[path] end,close=function() end}
end
Events.OnReceiveGlobalModData = event()
