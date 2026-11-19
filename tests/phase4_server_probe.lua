local Authority = require("OMHTS_Authority")
local Rewards = require("OMHTS_Rewards")
local Config = require("OMHTS_RewardsConfig")
local State = require("OMHTS_State")

local function nativePlayer(name, id)
    local descriptor = SurvivorFactory.CreateSurvivor()
    descriptor:setCharacterProfession(CharacterProfession.UNEMPLOYED)
    descriptor:setID(id)
    local value = IsoPlayer.new(getCell(), descriptor, 0, 0, 0)
    value:setUsername(name)
    return value
end

local function verifyRewards()
    local store = ModData.getOrCreate("OMHTraitShop_State_v1")
    local probe = ModData.getOrCreate("OMHTS_Checkpoint6Probe")
    local config = Config.read()
    assert(config.ready and config.mode == 4 and config.PlayerKillXP == 75, "native sandbox defaults failed")
    local characterId = 7601
    if probe.stage == 2 then
        characterId = 7603
    end
    local killer = nativePlayer("RewardProbeA",characterId)
    local victim = nativePlayer("RewardProbeB",7602)
    local online = getOnlinePlayers()
    online:add(killer)
    online:add(victim)
    getOnlinePlayers = function() return online end
    local initial = Authority.getState(killer)
    Authority.getState(victim)
    local record = store.accounts["user:12:RewardProbeA:0"]
    local now = getGameTime():getWorldAgeHours()
    if not probe.stage then
        local z = IsoZombie.new(getCell())
        z:Kill(killer)
        assert(record.life.xp == 2, "real native Kill did not award zombie XP")
        triggerEvent("OnZombieDead",z)
        assert(record.life.xp == 2, "native duplicate zombie reward")
        z:removeFromWorld()
        victim:Kill(killer)
        assert(record.life.xp == 77, "native PvP amount")
        local season = getClimateManager():getSeason()
        local dusk = season:getDusk()
        local session = Rewards.session(now,dusk-0.1,config)
        session = Rewards.survival(record,session,now+24,(dusk-0.1)%24,config)
        assert(record.life.level == 1 and record.life.xp == 2, "native seasonal night conversion failed")
        probe.expectedXP = record.life.xp
        probe.expectedTokens = record.life.tokens
        probe.expiry = store.rewards.cooldowns.RewardProbeA.RewardProbeB
        assert(probe.expiry == now+48, "native cooldown hours")
        probe.stage = 1
        print("[OMHTS TEST] native zombie Kill, PvP eligibility and seasonal survival passed")
        print("[OMHTS TEST] disk stage 1 ready")
    elseif probe.stage == 1 then
        assert(record.life.xp == probe.expectedXP and record.life.tokens == probe.expectedTokens,
            "reward progression failed disk reload")
        assert(store.rewards.cooldowns.RewardProbeA.RewardProbeB == probe.expiry, "cooldown lost on disk")
        assert(not Rewards.player(store,killer,victim,record), "repeat victim paid after restart")
        assert(State.settleDeath(record, record.life.id))
        local replacement = nativePlayer("RewardProbeA",7603)
        local nextState = Authority.getState(replacement)
        record = store.accounts["user:12:RewardProbeA:0"]
        assert(nextState.xp == 0 and nextState.level == 0)
        assert(not Rewards.player(store,replacement,victim,record), "respawn bypassed PvP cooldown")
        replacement:removeFromWorld()
        probe.stage = 2
        print("[OMHTS TEST] native reward persistence and respawn cooldown passed")
        print("[OMHTS TEST] disk stage 2 ready")
    else
        assert(store.rewards.cooldowns.RewardProbeA.RewardProbeB == probe.expiry, "cooldown lost after second restart")
        assert(not Rewards.player(store,killer,victim,record), "second restart bypassed cooldown")
        assert(record.life.xp == 0 and record.life.level == 0, "old-life XP returned")
        print("[OMHTS TEST] repeated restart retained cooldown and death reset")
        print("[OMHTS TEST] disk stage 3 ready")
    end
    killer:removeFromWorld()
    victim:removeFromWorld()
end
Events.OnServerStarted.Add(verifyRewards)
