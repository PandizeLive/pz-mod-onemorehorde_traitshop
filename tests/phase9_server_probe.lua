local Authority = require("OMHTS_Authority")
local Ledger = require("OMH_CharacterIntegrity")
local Persistence = require("OMH_Phase3Persistence")
local Runtime = require("OMH_DifficultyRuntime")
local Flags = require("OMH_RunFlags")

local function nativePlayer(id)
    local descriptor = SurvivorFactory.CreateSurvivor()
    descriptor:setCharacterProfession(CharacterProfession.UNEMPLOYED)
    descriptor:setID(id)
    local player = IsoPlayer.new(getCell(), descriptor, 0, 0, 0)
    player:setUsername("RunOptionsProbe")
    player:setHoursSurvived(0)
    return player
end

local function verifyRunOptions()
    local probe = ModData.getOrCreate("OMHTS_Checkpoint9Probe")
    local player = nativePlayer(9901)
    Persistence.getOrCreatePlayerRecord(player, "isolated CP9 probe")
    local owner = Persistence.getPersonalOwnerRecord("RunOptionsProbe")
    assert(owner, "native personal owner missing")
    if not probe.stage then
        Ledger.observe(player)
        assert(Ledger.summary(owner).unverified, "existing character marked clean")
        triggerEvent("OnNewGame", player, nil)
        assert(not Ledger.summary(owner).unverified, "native creation not verified")
        local state = Authority.getState(player)
        owner.traitShopEnabled = false
        assert(not Runtime.isTraitShopEnabled(player), "disabled native access")
        assert(Authority.purchase(player, {lifeId=state.lifeId,revision=state.revision,items={}})=="disabled",
            "server purchase bypassed disabled access")
        assert(not Authority.awardXP(player,state.lifeId,state.revision,5), "disabled native XP awarded")
        owner.traitShopEnabled = true
        local record = ModData.get("OMHTraitShop_State_v1").accounts["user:15:RunOptionsProbe:0"]
        record.life.purchases["base:fastreader"] = 2
        record.life.creation.prestigeBonus = 3
        record.life.creation.prestigeUnofficial = true
        assert(Ledger.summary(owner).forced==1 and Ledger.summary(owner).prestige==1, "native receipts not recognized")
        owner.traitShopEnabled = false
        assert(Runtime.isTraitShopEnabled(player), "native benefit lock bypassed")
        probe.stage = 1
    elseif probe.stage == 1 then
        player:setHoursSurvived(0.1)
        Ledger.observe(player)
        assert(not Ledger.summary(owner).unverified and Ledger.summary(owner).forced==1, "creation/benefits lost on disk")
        assert(Ledger.summary(owner).flags[Flags.TRAIT_SHOP_LESSENED], "unofficial Prestige lost on disk")
        ModData.get("OMHTraitShop_State_v1").accounts["user:15:RunOptionsProbe:0"] = nil
        owner.runClassification = nil
        local classification = Runtime.getClassification(owner)
        assert(classification.integrityFlags[Flags.TRAIT_SHOP_USED], "addon data removal cleared score modifier")
        assert(classification.leaderboardEligibility=="modified", "reset erased inherited restriction")
        probe.stage = 2
    else
        Ledger.observe(player)
        assert(Ledger.summary(owner).forced==1, "durable benefit marker depended on addon account")
        local fresh = nativePlayer(9902)
        triggerEvent("OnNewGame", fresh, nil)
        assert(not Ledger.summary(owner).unverified and Ledger.summary(owner).forced==0,
            "fresh life did not get a fresh verification record")
        fresh:removeFromWorld()
        probe.stage = 3
    end
    player:removeFromWorld()
    print("[OMHTS TEST] disk stage " .. probe.stage .. " ready")
end
Events.OnServerStarted.Add(verifyRunOptions)
