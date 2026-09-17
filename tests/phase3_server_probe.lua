local State = require("OMHTS_State")
local Progression = require("OMHTS_Progression")
local Authority = require("OMHTS_Authority")

local function nativePlayer(name, id, hours)
    local descriptor = SurvivorFactory.CreateSurvivor()
    descriptor:setCharacterProfession(CharacterProfession.UNEMPLOYED)
    descriptor:setID(id)
    local player = IsoPlayer.new(getCell(), descriptor, 0, 0, 0)
    player:setUsername(name)
    player:setHoursSurvived(hours)
    return player
end

local function verifyProgression()
    local store = ModData.getOrCreate("OMHTraitShop_State_v1")
    local key = "user:8:XPProbeA:0"
    local record = store.accounts[key]
    local player
    assert(Progression.requiredXP(19) == 2000)
    if not record then
        player = nativePlayer("XPProbeA", 7501, 0)
        triggerEvent("OnNewGame", player, nil)
        player:setHoursSurvived(0.025)
        local snapshot = Authority.getState(player)
        assert(snapshot.creationStatus == "granted" and snapshot.tokens == 8, "native birth capture missed delayed attachment")
        local revision = snapshot.revision
        assert(Authority.awardXP(player, snapshot.lifeId, revision, 3650))
        assert(not Authority.awardXP(player, snapshot.lifeId, revision, 3650), "replayed XP accepted")
        snapshot = Authority.getState(player)
        assert(snapshot.level == 10 and snapshot.tokens == 18 and snapshot.xp == 50 and snapshot.earnedPrestige == 2)
        local waiting = nativePlayer("XPProbeB", 7502, 0)
        triggerEvent("OnNewGame", waiting, nil)
        assert(store.creations["user:8:XPProbeB:7502"] == 8)
        waiting:removeFromWorld()
        print("[OMHTS TEST] native delayed grant, XP milestones and replay rejection passed")
        print("[OMHTS TEST] disk stage 1 ready")
    elseif record.life.characterId == 7501 then
        player = nativePlayer("XPProbeA", 7501, 0.25)
        local snapshot = Authority.getState(player)
        assert(snapshot.level == 10 and snapshot.tokens == 18 and snapshot.xp == 50 and snapshot.earnedPrestige == 2,
            "native disk progression lost or duplicated")
        local waiting = nativePlayer("XPProbeB", 7502, 0.5)
        local resumed = Authority.getState(waiting)
        assert(resumed.tokens == 8 and resumed.creationStatus == "granted", "pending birth proof did not survive disk")
        assert(store.creations["user:8:XPProbeB:7502"] == nil)
        waiting:removeFromWorld()
        assert(State.settleDeath(record, record.life.id))
        local nextPlayer = nativePlayer("XPProbeA", 7503, 0)
        triggerEvent("OnNewGame", nextPlayer, nil)
        nextPlayer:setHoursSurvived(0.05)
        local replacement = Authority.getState(nextPlayer)
        assert(replacement.tokens == 8 and replacement.level == 0 and replacement.xp == 0 and replacement.pendingPrestige == 2)
        nextPlayer:removeFromWorld()
        print("[OMHTS TEST] disk XP, pending creation and death replacement passed")
        print("[OMHTS TEST] disk stage 2 ready")
    else
        player = nativePlayer("XPProbeA", 7503, 0.5)
        local snapshot = Authority.getState(player)
        assert(snapshot.tokens == 8 and snapshot.level == 0 and snapshot.xp == 0 and snapshot.pendingPrestige == 2)
        assert(not State.settleDeath(record, record.life.id - 1), "old death settled new life")
        local old = nativePlayer("XPProbeOld", 7510, 0.01)
        local oldSnapshot = Authority.getState(old)
        assert(oldSnapshot.tokens == 0 and oldSnapshot.creationStatus == "legacy", "old profile received retroactive grant")
        old:removeFromWorld()
        print("[OMHTS TEST] replacement persisted without duplicate grant; existing profile excluded")
        print("[OMHTS TEST] disk stage 3 ready")
    end
    player:removeFromWorld()
end

Events.OnServerStarted.Add(verifyProgression)
