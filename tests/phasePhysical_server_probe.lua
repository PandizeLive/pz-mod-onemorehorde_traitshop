local State = require("OMHTS_State")
local Shop = require("OMHTS_Shop")
local Catalog = require("OMHTS_Catalog")
local Effects = require("OMHTS_Effects")
local Physical = require("OMHTS_Physical")

local function actor(id)
    local descriptor = SurvivorFactory.CreateSurvivor()
    descriptor:setCharacterProfession(CharacterProfession.UNEMPLOYED)
    descriptor:setID(id)
    local player = IsoPlayer.new(getCell(), descriptor, 0, 0, 0)
    player:setUsername("PhysicalProbe" .. id)
    return player
end

local function level(player, perk, target)
    while player:getPerkLevel(perk) < target do player:LevelPerk(perk) end
    while player:getPerkLevel(perk) > target do player:LoseLevel(perk) end
    player:getXp():setXPToLevel(perk, target)
end

local function recordFor(store, player, key)
    local record = State.attach(store, key, player:getDescriptor():getID(), 0)
    record.life.creation.status = "granted"
    record.life.tokens = 1000
    return record
end

local function buy(player, record, ids)
    local items = {}
    for index = 1, #ids do
        local definition = Catalog.definition(ids[index])
        items[index] = { id = ids[index], price = Catalog.price(definition), remove = definition:getCost() < 0 }
    end
    return Shop.purchase(player, record, {lifeId=record.life.id, revision=record.revision, items=items})
end

local function verify()
    getSandboxOptions():getOptionByName("OMHTraitShop.AllowNegativeRemoval"):setValue(true)
    local store = ModData.getOrCreate("OMHTraitShop_State_v1")
    local probe = ModData.getOrCreate("OMHTS_PhysicalProbe")
    local p = actor(8901)
    if not probe.stage then
        local r = recordFor(store, p, "physical")
        local matrix = actor(8903)
        for _, protein in pairs({-400,0,100}) do
            matrix:getNutrition():setProteins(protein)
            for starting = 0, 9 do
                level(matrix, Perks.Strength, starting)
                matrix:getXp():AddXP(Perks.Strength, 17.5, false, false, false)
                local planned = Physical.preview(matrix, Catalog.definition("base:stout"))
                local receipt = {Strength={xp=planned.xp,serial=1,applied=false}}
                assert(Physical.apply(matrix,receipt) and receipt.Strength.applied
                    and matrix:getPerkLevel(Perks.Strength)==planned.after
                    and math.abs(matrix:getXp():getXP(Perks.Strength)-planned.xp)<0.15,
                    "native protein/start-level matrix missed promised level or XP")
            end
        end
        matrix:removeFromWorld()
        level(p, Perks.Strength, 5)
        level(p, Perks.Fitness, 5)
        p:getNutrition():setProteins(100)
        p:getXp():AddXP(Perks.Strength, 17, false, false, false)
        local before = p:getXp():getXP(Perks.Strength)
        local expected = before + Perks.Strength:getTotalXpForLevel(7) - Perks.Strength:getTotalXpForLevel(5)
        assert(buy(p, r, {"base:stout"}) == "purchased", "Stout purchase rejected")
        assert(p:getPerkLevel(Perks.Strength) == 7 and p:hasTrait(CharacterTrait.STOUT), "native Stout strength/trait wrong")
        assert(math.abs(p:getXp():getXP(Perks.Strength) - expected) < 0.1, "protein multiplied stat purchase or partial XP lost")
        assert(r.life.effects.traits["base:stout"] == nil and r.life.effects.physical.Strength.applied, "physical entitlement pins trait")
        assert(buy(p, r, {"base:strong"}) == "conflict", "creator conflict bypassed")
        assert(buy(p, r, {"base:fit"}) == "purchased" and p:getPerkLevel(Perks.Fitness) == 7
            and p:hasTrait(CharacterTrait.FIT), "native Fit failed")
        level(p, Perks.Strength, 6)
        level(p, Perks.Fitness, 6)
        assert(not Shop.reconcile(p, r, false) and p:getPerkLevel(Perks.Strength) == 6, "physical grant became permanent XP floor")
        level(p, Perks.Strength, 9)
        assert(p:hasTrait(CharacterTrait.STRONG) and Shop.offer(p, r, "base:stout") == "already_purchased",
            "purchase history fabricates old tier ownership")
        local negative = actor(8902)
        local nr = recordFor(store, negative, "negative")
        level(negative, Perks.Strength, 1)
        level(negative, Perks.Strength, 0)
        level(negative, Perks.Fitness, 1)
        level(negative, Perks.Fitness, 0)
        negative:getNutrition():setProteins(-400)
        assert(buy(negative, nr, {"base:weak", "base:strong"}) == "purchased", "negative + positive cart failed")
        assert(negative:getPerkLevel(Perks.Strength) == 9 and negative:hasTrait(CharacterTrait.STRONG)
            and not negative:hasTrait(CharacterTrait.WEAK), "mixed cart did not remove penalty then grant stat increase")
        assert(buy(negative, nr, {"base:unfit"}) == "purchased" and negative:getPerkLevel(Perks.Fitness) == 5
            and not negative:hasTrait(CharacterTrait.UNFIT) and not negative:hasTrait(CharacterTrait.OUT_OF_SHAPE),
            "negative removal left physical penalty active")
        level(negative, Perks.Fitness, 9)
        negative:getCharacterTraits():add(CharacterTrait.OBESE)
        local effect, reason = Effects.plan(negative, nr.life.effects, {["base:fit"]=false})
        assert(effect == nil and (reason == "conflict" or reason == "nutrition"), "weight blocked Fitness was charged")
        negative:getCharacterTraits():remove(CharacterTrait.OBESE)
        level(negative, Perks.Fitness, 10)
        local preview, cap = Physical.preview(negative, Catalog.definition("base:fit"))
        assert(preview == nil and cap == "no_effect", "level cap no-op allowed")
        negative:removeFromWorld()
        assert(State.isRecord(r) and Effects.valid(Shop.snapshot(p,r).effects))
        probe.stage = 1
        print("[OMHTS TEST] native physical stats, nutrition, creator conflicts, mixed cart, penalties, cap and no XP floor passed")
        print("[OMHTS TEST] disk stage 1 ready")
    elseif probe.stage == 1 then
        local r = store.accounts.physical
        assert(State.isRecord(r) and r.life.effects.physical.Strength.applied and r.life.effects.physical.Fitness.applied,
            "physical receipt lost across disk restart")
        level(p, Perks.Strength, 6)
        level(p, Perks.Fitness, 6)
        assert(not Shop.reconcile(p,r,false) and p:getPerkLevel(Perks.Strength) == 6, "restart regrants spent physical reward")
        assert(State.settleDeath(r,r.life.id))
        probe.stage = 2
        print("[OMHTS TEST] disk physical completion receipts preserve natural later stat loss")
        print("[OMHTS TEST] disk stage 2 ready")
    else
        local r = store.accounts.physical
        assert(r.life.status == "dead" and r.life.effects.physical == nil, "death inherited physical grant")
        print("[OMHTS TEST] physical grants and receipts clear on death")
        print("[OMHTS TEST] disk stage 3 ready")
    end
    p:removeFromWorld()
end

Events.OnServerStarted.Add(verify)
