local State = require("OMHTS_State")
local Authority = require("OMHTS_Authority")
local Prestige = require("OMHTS_Prestige")

local function nativePlayer(id)
    local descriptor = SurvivorFactory.CreateSurvivor()
    descriptor:setCharacterProfession(CharacterProfession.UNEMPLOYED)
    descriptor:setID(id)
    local value = IsoPlayer.new(getCell(), descriptor, 0, 0, 0)
    value:setUsername("PrestigeProbe")
    value:setHoursSurvived(0)
    return value
end

local function verifyPrestige()
    local store = ModData.getOrCreate("OMHTraitShop_State_v1")
    local probe = ModData.getOrCreate("OMHTS_Checkpoint7Probe")
    local key = "user:13:PrestigeProbe:0"
    local player
    if not probe.stage then
        player = nativePlayer(7701)
        local initial = Authority.getState(player)
        assert(Authority.awardXP(player, initial.lifeId, initial.revision, 8700))
        local record = store.accounts[key]
        record.prestige.earned = 3
        assert(State.settleDeath(record, record.life.id))
        Prestige.publish(key, record)
        assert(ModData.get(Prestige.tag(key)).bonus == 3)
        probe.stage = 1
        print("[OMHTS TEST] disk stage 1 ready")
    elseif probe.stage == 1 then
        assert(store.accounts[key].prestige.pending == 3)
        assert(ModData.get(Prestige.tag(key)).bonus == 3, "creation preview lost on server restart")
        player = nativePlayer(7702)
        player:getCharacterTraits():add(CharacterTrait.FAST_READER)
        triggerEvent("OnNewGame", player, nil)
        player:setHoursSurvived(0.05)
        local state = Authority.getState(player)
        assert(state.creationPrestige == 3 and state.prestigeTokens == 3)
        assert(state.startingTokens == 9 and state.retainedPrestige == 1 and state.pendingPrestige == 0)
        assert(state.level == 0 and state.xp == 0)
        assert(Authority.hasUnofficialPrestigeForIdentity("PrestigeProbe") == true)
        assert(Authority.hasUnofficialPrestigeForIdentity("Unrelated") == false)
        triggerEvent("OnNewGame", player, nil)
        assert(Authority.getState(player).tokens == 9, "duplicate birth regranted")
        probe.stage = 2
        print("[OMHTS TEST] disk stage 2 ready")
    else
        player = nativePlayer(7702)
        player:setHoursSurvived(0.2)
        local state = Authority.getState(player)
        assert(state.tokens == 9 and state.retainedPrestige == 1 and state.creationPrestige == 3)
        local record = store.accounts[key]
        assert(State.settleDeath(record, record.life.id))
        local replacement = nativePlayer(7703)
        triggerEvent("OnNewGame", replacement, nil)
        replacement:setHoursSurvived(0.1)
        state = Authority.getState(replacement)
        assert(state.creationPrestige == 1 and state.retainedPrestige == 0 and state.tokens == 9)
        assert(State.settleDeath(record, record.life.id) and record.prestige.pending == 0)
        replacement:removeFromWorld()
        print("[OMHTS TEST] disk stage 3 ready")
    end
    player:removeFromWorld()
end

Events.OnServerStarted.Add(verifyPrestige)
