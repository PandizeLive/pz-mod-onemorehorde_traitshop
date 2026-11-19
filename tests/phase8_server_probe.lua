local Authority = require("OMHTS_Authority")
local Rewards = require("OMHTS_Rewards")
local Config = require("OMHTS_RewardsConfig")
local Extensions = require("OMH_Extensions")
local Runtime = require("OMH_ExtensionRuntime")

local function verifyHordeRewards()
    assert(Config.hasHordeRewards(), "core reward schema unavailable")
    assert(Extensions.get("OMH.TraitShop.Rewards").apiVersion == 3, "adapter not registered")
    SandboxVars.OMHTraitShop.RewardMode = 3
    SandboxVars.OMHTraitShop.HordeZombieXP = 5
    SandboxVars.OMHTraitShop.HordeSurvivedXP = 100
    local descriptor = SurvivorFactory.CreateSurvivor()
    descriptor:setCharacterProfession(CharacterProfession.UNEMPLOYED)
    descriptor:setID(8801)
    local native = IsoPlayer.new(getCell(), descriptor, 0, 0, 0)
    native:setUsername("HordeProbe")
    native:setHoursSurvived(0)
    Authority.getState(native)
    local store = ModData.getOrCreate("OMHTraitShop_State_v1")
    local probe = ModData.getOrCreate("OMHTS_Checkpoint8Probe")
    local record = store.accounts["user:10:HordeProbe:0"]
    local facts = {rewardSchema=1,eventId="disk-probe",participantId="HordeProbe",killCount=1,eligible=true}
    if not probe.stage then
        assert(Rewards.consumeHordeKill(store,facts))
        assert(Rewards.horde(record,"HordeZombieXP"))
        assert(record.life.xp==5)
        probe.stage=1
        print("[OMHTS TEST] disk stage 1 ready")
    elseif probe.stage==1 then
        assert(record.life.xp==5 and not Rewards.consumeHordeKill(store,facts), "kill receipt lost across disk restart")
        facts.rewardParticipants={}
        assert(Rewards.consumeHordeFinish(store,facts))
        assert(Rewards.horde(record,"HordeSurvivedXP"))
        assert(record.life.level==1 and record.life.xp==5)
        probe.stage=2
        print("[OMHTS TEST] disk stage 2 ready")
    else
        facts.rewardParticipants={}
        assert(not Rewards.consumeHordeFinish(store,facts), "completion receipt lost across disk restart")
        assert(record.life.level==1 and record.life.xp==5)
        local e={eventId="offline-native",outcome="survived",participants={HordeProbe={casualty=false,eligibilityStatus="eligible"}},
            killLedger={participantKills={HordeProbe=1}}}
        Runtime.notifyHordeKill(e,"HordeProbe")
        Runtime.notifyEventFinished(e)
        assert(record.life.xp==5,"offline native player incorrectly rewarded")
        assert(store.rewards.hordes["offline-native"].finished)
        print("[OMHTS TEST] disk stage 3 ready")
    end
    native:removeFromWorld()
end
Events.OnServerStarted.Add(verifyHordeRewards)
