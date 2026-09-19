testStage = "Checkpoint 8 core callbacks through Trait Shop authority"
local Extensions = require("OMH_Extensions")
local Runtime = require("OMH_ExtensionRuntime")
local Ownership = require("OMH_Phase4Ownership")
local Authority = require("OMHTS_Authority")
local Rewards = require("OMHTS_Rewards")
local Config = require("OMHTS_RewardsConfig")
local State = require("OMHTS_State")
local settings = SandboxVars.OMHTraitShop
settings.RewardMode = 4
check(Extensions.get("OMH.TraitShop.Rewards").apiVersion == 3, "actual adapter registration uses API 3")
check(Extensions.register({id="legacy",apiVersion=1,version="1",capabilities={hordeEvents=true},eventHooks={onFinished=function() end}}), "API 1 hooks stay compatible")
check(Extensions.register({id="legacy2",apiVersion=2,version="1",capabilities={hordeEvents=true},eventHooks={onStarted=function() end}}), "API 2 hooks stay compatible")
check(not Extensions.register({id="bad",apiVersion=2,version="1",capabilities={hordeEvents=true},eventHooks={onKill=function() end}}), "kill hook requires reviewed API 3")
local alice = player("Alice",0,100,0)
local bob = player("Bob",0,101,0)
local outsider = player("Outside",0,102,0)
function alice:getVehicle() return nil end
function alice:getPrimaryHandItem() return nil end
function bob:getVehicle() return nil end
function bob:getPrimaryHandItem() return nil end
testPlayers = {alice,bob,outsider}
Events.OnInitGlobalModData.fire()
Authority.getState(alice)
Authority.getState(bob)
Authority.getState(outsider)
local function record(name) return testTables.OMHTraitShop_State_v1.accounts["user:"..#name..":"..name..":0"] end
local function participant() return {casualty=false,eligibilityStatus="eligible",membershipStatus="active"} end
local function horde(id)
    return {eventId=id,ownerType="faction",ownerId="team",outcome="survived",completionReason="end-hour",
        participants={Alice=participant(),Bob=participant()},killLedger={participantKills={}}}
end
local function zombie(killer, event)
    return {kind="IsoZombie", data={OMHEventId=event.eventId},isDead=function() return true end,
        isOnKillDone=function() return false end,getAttackedBy=function() return killer end,
        getModData=function(self) return self.data end}
end
local e=horde("event-1")
local runtime={event=e,execution={confirmedHordeDeaths=0,status="active"}}
local z=zombie(alice,e)
Events.OnZombieDead.fire(z)
check(record("Alice").life.xp==0,"ordinary handler reserves tagged death before core credit")
testEngineDeath(z,runtime)
check(record("Alice").life.xp==5 and record("Bob").life.xp==0,"real engine credit awards only killer 5 XP")
Events.OnZombieDead.fire(z)
testEngineDeath(z,runtime)
check(record("Alice").life.xp==5 and runtime.execution.confirmedHordeDeaths==1,"duplicate native death cannot repeat core or addon credit")
z=zombie(alice,e)
testEngineDeath(z,runtime)
Events.OnZombieDead.fire(z)
check(record("Alice").life.xp==10,"reversed event handler order cannot double-pay")
local retiring=zombie(alice,e)
retiring.data.OMHQuotaRetirementJobId="cleanup"
testEngineDeath(retiring,runtime)
check(record("Alice").life.xp==10,"quota retirement is not a rewarded kill")
runtime.execution.status="complete"
testEngineDeath(zombie(alice,e),runtime)
runtime.execution.status="active"
check(record("Alice").life.xp==10,"post-event cleanup death is not rewarded")
local noOwner=zombie(outsider,e)
function outsider:getVehicle() return nil end
function outsider:getPrimaryHandItem() return nil end
testEngineDeath(noOwner,runtime)
check(record("Outside").life.xp==0,"unrelated attacker cannot collect another horde's kill reward")
local packets=#testPackets
local facts={rewardSchema=1,eventId=e.eventId,participantId="Alice",killCount=2,eligible=true}
Authority.onHordeKill(facts)
check(record("Alice").life.xp==10,"replayed callback sequence ignored")
settings.RewardMode=2
facts.killCount=3
Authority.onHordeKill(facts)
settings.RewardMode=4
Authority.onHordeKill(facts)
check(record("Alice").life.xp==10,"disabled kill consumed before mode switch")
check(#testPackets==packets,"no immediate catalog packets per horde kill")
e.participants.Bob.casualty=true
e.participants.Bob.eligibilityStatus="casualty"
Ownership.finalizeEvent(e,"survived","end-hour",testWorldHours)
Runtime.notifyEventFinished(e)
check(record("Alice").life.level==1 and record("Alice").life.xp==10,"survivor receives 100 XP once")
check(record("Bob").life.xp==0,"connected casualty receives no completion reward")
Runtime.notifyEventFinished(e)
check(record("Alice").life.xp==10,"completion replay blocked")
local saved=nativeRoundTrip(testTables.OMHTraitShop_State_v1)
testTables.OMHTraitShop_State_v1=saved
Events.OnInitGlobalModData.fire()
Runtime.notifyEventFinished(e)
Authority.onHordeKill(facts)
check(record("Alice").life.xp==10,"native save roundtrip and reinitialization preserve kill and finish receipts")
local e2=horde("event-2")
e2.participants.Alice.membershipStatus="left"
Runtime.notifyEventFinished(e2)
check(record("Alice").life.xp==10 and record("Bob").life.level==1,"left faction excluded; connected late member qualifies")
local e3=horde("event-3")
testPlayers={alice,outsider}
Runtime.notifyEventFinished(e3)
testPlayers={alice,bob,outsider}
Runtime.notifyEventFinished(e3)
check(record("Bob").life.xp==0,"disconnect at completion cannot be claimed on reconnect")
local e4=horde("event-4")
e4.outcome="loss"
local before=record("Alice").revision
Runtime.notifyEventFinished(e4)
e4.outcome="survived"
Runtime.notifyEventFinished(e4)
check(record("Alice").revision==before,"loss terminal cannot later replay as survival")
for _,reason in pairs({"manual-run-reset","faction-disbanded"}) do
    local terminal=horde(reason)
    terminal.completionReason=reason
    Runtime.notifyEventFinished(terminal)
end
check(record("Alice").revision==before,"administrative terminals do not award survival")
local e5=horde("event-5")
e5.participants.Alice.role="vigilante"
e5.participants.Bob.casualty=true
e5.participants.Bob.eligibilityStatus="casualty"
bob.dead=true
Events.OnCharacterDeath.fire(bob)
bob=player("Bob",0,201,0)
testPlayers={alice,bob,outsider}
Authority.getState(bob)
Runtime.notifyEventFinished(e5)
check(record("Bob").life.xp==0 and record("Alice").revision==before,"respawn does not erase event casualty; outsider vigilante excluded")
local oldLife={rewardSchema=1,eventId="old-life",outcome="survived",rewardParticipants={Bob={characterId=101}}}
Authority.onHordeFinished(oldLife)
check(record("Bob").life.xp==0,"completion recipient character identity must still match")
settings.HordeZombieXP=0
Authority.onHordeKill({rewardSchema=1,eventId="zero",participantId="Bob",killCount=1,eligible=true})
settings.HordeZombieXP=5
Authority.onHordeKill({rewardSchema=1,eventId="zero",participantId="Bob",killCount=1,eligible=true})
check(record("Bob").life.xp==0,"zero rate cannot be replayed after enabling")
for mode=1,4 do
    settings.RewardMode=mode
    check((Config.amount(Config.read(),"HordeZombieXP")==5)==(mode==3 or mode==4),"horde kill mode routing "..mode)
    check((Config.amount(Config.read(),"HordeSurvivedXP")==100)==(mode==3 or mode==4),"horde survival mode routing "..mode)
end
settings.RewardMode=4
testHorde=false
check(Config.amount(Config.read(),"HordeZombieXP")==0 and Config.amount(Config.read(),"ZombieXP")==2,"dependency removal preserves Hybrid and standalone rewards")
testHorde=true
local schema=Extensions.HORDE_REWARD_SCHEMA
Extensions.HORDE_REWARD_SCHEMA=nil
check(Config.amount(Config.read(),"HordeSurvivedXP")==0,"older core fails closed")
Extensions.HORDE_REWARD_SCHEMA=schema
check(Authority.getState(alice).hordeRewards=="none","supported adapter no longer displays upcoming warning")
local bad={rewards={schema=1,cooldowns={},deaths={},hordes={bad={finished=false,kills={Alice=-1}}}}}
check(not Rewards.initialize(bad) and bad.rewards.hordes.bad.kills.Alice==-1,"invalid saved receipt preserved and rewards disabled")
Events.OnInitGlobalModData.fire()
local revised=record("Alice").revision
Events.OnClientCommand.fire("OMHTraitShop","hordeKill",alice,{amount=100000})
check(record("Alice").revision==revised,"client cannot submit horde rewards")
testSide="singleplayer"
testPlayers={player("Local",0,500,0)}
Events.OnInitGlobalModData.fire()
local sp={eventId="sp-horde",outcome="survived",participants={["singleplayer:0"]=participant()},killLedger={participantKills={["singleplayer:0"]=1}}}
Runtime.notifyHordeKill(sp,"singleplayer:0")
Runtime.notifyEventFinished(sp)
local localRecord=testTables.OMHTraitShop_State_v1.accounts["local:0"]
check(localRecord.life.level==1 and localRecord.life.xp==5,"SP identity and both core reward callbacks work")
testTransportPackets={Authority.getState(testPlayers[1])}
testOutput=tostring(testChecks).." Checkpoint 8 assertions passed."
