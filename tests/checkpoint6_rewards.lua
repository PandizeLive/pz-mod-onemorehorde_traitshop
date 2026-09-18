testStage = "Checkpoint 6 reward attribution and persistence"
local State = require("OMHTS_State")
local Rewards = require("OMHTS_Rewards")
local Config = require("OMHTS_RewardsConfig")
local Authority = require("OMHTS_Authority")
local settings = SandboxVars.OMHTraitShop
testSide = "server"
testPlayers = { player("Killer",0,900,0), player("Victim",0,901,0), player("Other",0,902,0) }
local killer, victim, other = testPlayers[1], testPlayers[2], testPlayers[3]
Events.OnInitGlobalModData.fire()
local baseline = Authority.getState(killer)
Authority.getState(victim)
Authority.getState(other)
local store = testTables.OMHTraitShop_State_v1
local record = store.accounts["user:6:Killer:0"]
local function zombie(attacker, tagged)
    return { kind = "IsoZombie", dead = true, done = false, data = { OMHEventId = tagged },
        isDead = function(self) return self.dead end,
        isOnKillDone = function(self) return self.done end,
        getAttackedBy = function() return attacker end,
        getModData = function(self) return self.data end }
end
local z = zombie(killer)
local packetsBefore = #testPackets
Events.OnZombieDead.fire(z)
check(record.life.xp == 2, "native zombie death handler awards approved 2 XP")
Events.OnZombieDead.fire(z)
check(record.life.xp == 2, "duplicate zombie death cannot pay twice")
z.dead = false
Events.OnZombieCreate.fire(z)
z.dead = true
Events.OnZombieDead.fire(z)
check(record.life.xp == 4, "pooled zombie may pay for its new life")
Events.OnZombieDead.fire(zombie(nil))
local outsider = player("Disconnected",0,903,0)
Events.OnZombieDead.fire(zombie(outsider))
check(record.life.xp == 4 and store.accounts["user:12:Disconnected:0"] == nil, "unknown or disconnected killer gains nothing")
for i=1,48 do Events.OnZombieDead.fire(zombie(killer)) end
check(#testPackets == packetsBefore, "rapid kills do not send a catalog snapshot per kill")
testClock=testClock+1001
Events.OnTick.fire()
check(#testPackets == packetsBefore+1, "reward snapshots batched by the authority scan")
check(record.life.level == 1 and record.life.xp == 0 and record.life.tokens == baseline.tokens+1,
    "50 zombie kills reach Level 1 and grant one Token")
check(Authority.getState(other).xp == 0, "other player never receives killer reward")
settings.RewardMode = 2
local disabled = zombie(killer)
Events.OnZombieDead.fire(disabled)
settings.RewardMode = 4
Events.OnZombieDead.fire(disabled)
check(record.life.xp == 0, "mode switching cannot replay a disabled death")
settings.ZombieXP = 0
Events.OnZombieDead.fire(zombie(killer))
check(record.life.xp == 0, "zero reward disabled")
settings.ZombieXP = 2
testHorde = true
Events.OnZombieDead.fire(zombie(killer,"test-horde"))
check(record.life.xp == 0, "tagged horde kill reserved, never double-paid as ordinary zombie")
testHorde = false
local now = testWorldHours
victim.killer = killer
victim.dead = true
Events.OnCharacterDeath.fire(victim)
check(record.life.xp == 75, "enemy factionless player kill awards 75 XP")
Events.OnCharacterDeath.fire(victim)
check(record.life.xp == 75, "repeated player death never pays twice")
check(store.rewards.cooldowns.Killer.Victim == now+48, "default cooldown expires after 48 game hours")
local sameFaction = player("Friend",0,904,0)
testPlayers[#testPlayers+1] = sameFaction
Authority.getState(sameFaction)
killer.faction = "Team"
sameFaction.faction = "Team"
sameFaction.dead = true
sameFaction.killer = killer
Events.OnCharacterDeath.fire(sameFaction)
check(record.life.xp == 75, "same faction cannot pay even when friendly fire kills")
killer.faction = nil
testWorldHours = now+47.99
check(not Rewards.player(store,killer,victim,record), "same victim blocked just before cooldown expiry")
testTables = nativeRoundTrip(testTables)
Events.OnInitGlobalModData.fire()
store = testTables.OMHTraitShop_State_v1
record = store.accounts["user:6:Killer:0"]
check(not Rewards.player(store,killer,victim,record), "cooldown survives native serialization and authority reload")
testWorldHours = now+48
check(Rewards.player(store,killer,victim,record), "same victim can pay at exact cooldown expiry")
check(record.life.level == 2 and record.life.xp == 0, "two 75 XP player rewards consume Level 2 threshold")
local killerLife = record.life.id
State.settleDeath(record,killerLife)
local replacement = player("Killer",0,910,0)
testPlayers[1] = replacement
Authority.getState(replacement)
record = store.accounts["user:6:Killer:0"]
check(not Rewards.player(store,replacement,victim,record), "killer respawn cannot reset account-pair cooldown")
settings.PlayerKillCooldownDays = 0
check(not Rewards.player(store,replacement,victim,record), "lowering setting cannot erase active cooldown")
settings.PlayerKillCooldownDays = 2
Events.OnClientCommand.fire("OMHTraitShop","awardXP",replacement,{amount=1000})
Events.OnClientCommand.fire("OMHTraitShop","kill",replacement,{victim="Victim"})
check(record.life.xp == 0, "client reward claims rejected by authority dispatch")

testStage = "Survival seasonal cycle, time skips and reward settings"
local function fresh()
    local s = {}
    State.initialize(s)
    return State.attach(s,"local:0",999,0)
end
local function step(r,session,hour,cfg)
    return Rewards.survival(r,session,hour,hour%24,cfg)
end
settings.RewardMode = 4
local config = Config.read()
local r = fresh()
local session = Rewards.session(22,22,config)
session = step(r,session,23,config)
check(r.life.xp == 0, "partial daytime on join is not rewarded")
session = step(r,session,29,config)
check(r.life.xp == 25, "full connected dusk-to-dawn night pays 25")
session = step(r,session,29,config)
check(r.life.xp == 25, "same sunrise replay cannot pay twice")
session = step(r,session,47,config)
check(r.life.xp == 25, "zero-rate full day does not pay")
local late = fresh()
local lateSession = Rewards.session(24,0,config)
lateSession = step(late,lateSession,29,config)
check(late.life.xp == 0, "joining after dusk excludes current night")
lateSession = step(late,lateSession,53,config)
check(late.life.xp == 25, "following complete night qualifies")
lateSession = Rewards.session(48,0,config)
lateSession = step(late,lateSession,53,config)
check(late.life.xp == 25, "reconnect cannot backfill an incomplete night")
local small, large = fresh(), fresh()
local a,b = Rewards.session(22,22,config), Rewards.session(22,22,config)
for hour=23,22+24*15 do a=step(small,a,hour,config) end
for i=1,5 do b=step(large,b,22+24*15,config) end
check(large.life.level == small.life.level and large.life.xp == small.life.xp
    and large.life.tokens == small.life.tokens, "bounded catch-up equals many small steps across 15 days")
local before = large.life.xp
b=step(large,b,22+24*15,config)
check(large.life.xp == before, "drained catch-up cannot award again")
local calendar = Rewards.session(22,22,config)
calendar.date=31
calendar.month=11
calendar.year=1999
calendar=step(fresh(),calendar,30,config)
check(calendar.date==1 and calendar.month==0 and calendar.year==2000,"catch-up crosses year boundary")
local variable=Rewards.session(22,22,config)
variable.season={setDay=function(self,date) self.date=date end,
    getDawn=function(self) if self.date==10 then return 6 end return 5 end,
    getDusk=function() return 23 end}
variable.season:setDay(9)
local seasonal=fresh()
variable=step(seasonal,variable,29,config)
check(seasonal.life.xp==0,"next day seasonal dawn can move later")
variable=step(seasonal,variable,30,config)
check(seasonal.life.xp==25,"night pays at the new actual seasonal dawn")
local rewind=step(seasonal,variable,10,config)
rewind=step(seasonal,rewind,11,config)
check(seasonal.life.xp==25,"clock rewind cannot replay completed survival")
settings.NightXP=50
local changed=Config.read()
session=step(r,session,50,changed)
session=step(r,session,53,changed)
check(r.life.xp==25, "changing rates mid-night does not pay a partial period")
settings.NightXP=25
for mode=1,4 do
    settings.RewardMode=mode
    local c=Config.read()
    check((Config.amount(c,"ZombieXP")>0)==(mode==1 or mode==4),"kill mode routing "..mode)
    check((Config.amount(c,"NightXP")>0)==(mode==2 or mode==4),"survival mode routing "..mode)
    check(Config.amount(c,"HordeZombieXP")==0 and Config.amount(c,"HordeSurvivedXP")==0,
        "unimplemented horde adapter never pays "..mode)
end
settings.RewardMode=4
SandboxVars.DayNightCycle=2
check(Config.amount(Config.read(),"NightXP")==0,"endless day has no completed night")
SandboxVars.DayNightCycle=3
check(Config.amount(Config.read(),"NightXP")==0,"endless night has no completed night")
SandboxVars.DayNightCycle=1
settings.ZombieXP=0/0
check(not Config.read().ready,"invalid reward config fails closed")
settings.ZombieXP=2
local bad={rewards={schema=99,cooldowns={},deaths={}}}
check(not Rewards.initialize(bad) and bad.rewards.schema==99,"unsupported reward schema preserved")
local applied
Config.applyDefault({getOptionByName=function() return {setValue=function(self,value) applied=value end,
    setDefaultToCurrentValue=function() end} end})
check(applied==4,"standalone default Hybrid")
testHorde=true
Config.applyDefault({getOptionByName=function() return {setValue=function(self,value) applied=value end,
    setDefaultToCurrentValue=function() end} end})
check(applied==3,"Horde Night dependency default")
testHorde=false
testTransportPackets={Authority.getState(replacement)}
testOutput=tostring(testChecks).." Checkpoint 6 reward checks passed."
