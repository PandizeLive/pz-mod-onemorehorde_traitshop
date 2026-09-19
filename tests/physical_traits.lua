testStage = "physical trait transactions and client receipt persistence"
local Physical = require("OMHTS_Physical")
local Catalog = require("OMHTS_Catalog")
local Effects = require("OMHTS_Effects")
local Shop = require("OMHTS_Shop")
local State = require("OMHTS_State")
local Presentation = require("OMHTS_Presentation")
local amounts = {-4,-2,2,4}
local costs = {-10,-6,6,10}
for stat, family in pairs(Physical.families) do
    for index=1,#family do
        local definition = traitFixture(stat .. index, family[index], costs[index])
        definition.boosts[Perks.FromString(stat)] = amounts[index]
        for other=1,#family do
            if other ~= index then definition.excludes[family[other]] = true end
        end
    end
end
Catalog.definitions()
testSide = "server"
testOptions["OMHTraitShop.AllowNegativeRemoval"] = true
local p = player("Physical",0,9001,0)
p.nutritionAllowed = true
function p:getNutrition()
    return {getProteins=function() return 0 end,canAddFitnessXp=function() return p.nutritionAllowed end}
end
local store = {}
State.initialize(store)
local r = State.attach(store,"Physical",9001,0)
r.life.creation.status = "granted"
r.life.tokens = 1000
local function buy(ids)
    local items={}
    for index=1,#ids do
        local d=Catalog.definition(ids[index])
        items[index]={id=ids[index],price=Catalog.price(d),remove=d:getCost()<0}
    end
    return Shop.purchase(p,r,{lifeId=r.life.id,revision=r.revision,items=items})
end
p.skillXP.Strength = 2555
p.skillXP.Fitness = 2500
check(buy({"base:stout"}) == "purchased" and p.skillXP.Strength == 4955, "Stout preserves partial XP and grants two levels")
check(r.life.effects.physical.Strength.applied and r.life.effects.traits["base:stout"] == nil,
    "physical receipt completes without pinning trait membership")
local tokens = r.life.tokens
check(buy({"base:stout"}) == "already_purchased" and r.life.tokens == tokens, "physical purchase cannot repeat after tier disappears")
r=nativeRoundTrip(r)
p.skillXP.Strength=3600
check(not Shop.reconcile(p,r,false) and p.skillXP.Strength == 3600, "disk receipt does not restore later natural XP loss")
p.traits["base:stout"]=true
check(buy({"base:strong"}) == "conflict", "owned Stout blocks Strong using creator exclusions")
p.traits={ ["base:weak"]=true }
p.skillXP.Strength=55
local changes={["base:weak"]=true,["base:strong"]=false}
local plans,reason=Effects.plan(p,r.life.effects,changes)
check(plans and plans.physical.Strength.xp == 8155, "cart restores weak penalty before adding four Strength levels")
check(plans.traits["base:weak"] == nil and plans.traits["base:strong"] == nil, "both cart sides leave dynamic traits to vanilla")
check(buy({"base:strong","base:weak"}) == "purchased" and p.skillXP.Strength == 8155, "cart result independent of item order")
p.traits={ ["base:unfit"]=true }
p.skillXP.Fitness=0
check(buy({"base:unfit"}) == "purchased" and p.skillXP.Fitness == 2500, "removing Unfit reaches neutral level five")
p.traits={}
p.skillXP.Fitness=10000
tokens=r.life.tokens
check(buy({"base:fit"}) == "no_effect" and r.life.tokens == tokens, "level ten purchase blocked without charge")
p.skillXP.Fitness=2500
p.nutritionAllowed=false
check(buy({"base:fit"}) == "nutrition" and r.life.tokens == tokens, "native fitness nutrition gate checked before payment")
p.nutritionAllowed=true
p.sleeping=true
check(buy({"base:fit"}) == "asleep" and r.life.tokens == tokens, "sleep cannot consume a stat purchase")
p.sleeping=false
check(buy({"base:fit"}) == "purchased" and p.skillXP.Fitness == 4900, "Fit grants two Fitness levels")
local malformed=Effects.copy(r.life.effects)
malformed.physical.Fitness.serial=0
check(not Effects.valid(malformed), "physical receipt sequence validated")
malformed=Effects.copy(r.life.effects)
malformed.physical.Strength.xp=0/0
check(not Effects.valid(malformed), "physical target rejects NaN")
testSide="client"
p.skillXP.Strength=55
p.skillXP.Fitness=2500
local packet=Effects.copy(r.life.effects)
check(Effects.apply(p,packet) and p.skillXP.Strength==8155 and p.skillXP.Fitness==4900,
    "client applies server-completed targets once")
check(not Effects.apply(p,Effects.copy(r.life.effects)), "duplicate snapshot cannot replay physical bonus")
p.modData=nativeRoundTrip(p.modData)
p.skillXP.Strength=3600
check(not Effects.apply(p,Effects.copy(r.life.effects)) and p.skillXP.Strength==3600,
    "saved client receipt survives reconnect and preserves natural loss")
packet.physical.Strength.serial=packet.physical.Strength.serial+1
packet.physical.Strength.xp=6400
check(Effects.apply(p,packet) and p.skillXP.Strength==6400, "new receipt sequence can grant subsequent physical purchase")
check(not Effects.apply(p,Effects.copy(r.life.effects)) and p.skillXP.Strength==6400,
    "older receipt cannot rewind or reapply")
local row={id="base:strong",name="Strong",description="Description",definition=Catalog.definition("base:strong"),group="catalog",status="available"}
p.skillXP.Strength=2500
local tooltip=Presentation.physicalTooltip(p,row,{[row.id]=row},{})
check(string.find(tooltip,"5 -> 9",1,true) ~= nil, "tooltip previews exact stat increase")
check(string.find(tooltip,"Grants base:strong",1,true) ~= nil, "tooltip shows resulting vanilla trait")
local owned,signature=Presentation.ownership(p,Shop.snapshot(p,r))
check(not owned["base:stout"], "old purchase receipt does not add obsolete trait to owned list")
testSide="server"
p.skillXP.Fitness=2500
local athletic=Catalog.definition("base:athletic")
athletic.boosts[Perks.FromString("Cooking")]=1
check(buy({"base:athletic"}) == "purchased" and p.skillXP.Fitness==8100 and p.skillXP.Cooking==100,
    "extra standard skill metadata on a physical definition is still processed")
check(athletic.boosts[Perks.FromString("Fitness")]==4, "effect planning does not mutate trait metadata")
testOutput=tostring(testChecks) .. " shop, UI and physical trait assertions passed."
