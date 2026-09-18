testStage="Checkpoint 6 sandbox mode visibility"
local UI=require("OMHTS_SandboxUI")
local Config=require("OMHTS_RewardsConfig")
local function control()
    return {height=24,y=11,visible=true,getHeight=function(self) return self.height end,
        setVisible=function(self,value) self.visible=value end,setY=function(self,value) self.y=value end}
end
local function panel()
    local value={settingNames={},controls={},labels={},joypadButtonsY={},
        prerender=function(self) self.originalCalled=true end,
        setYScroll=function(self,value) self.scroll=value end,
        setScrollHeight=function(self,value) self.scrollHeight=value end,
        insertNewLineOfButtons=function(self,value) self.joypadButtonsY[#self.joypadButtonsY+1]={value} end}
    local keys={"RewardMode","PositiveCostMultiplier","NegativeCostMultiplier","AllowNegativeRemoval",
        "ZombieXP","PlayerKillXP","PlayerKillCooldownDays","DayXP","NightXP","HordeZombieXP","HordeSurvivedXP"}
    for i=1,#keys do
        local name="OMHTraitShop."..keys[i]
        value.settingNames[i]=name
        value.labels[name]=control()
        value.controls[name]=control()
    end
    value.controls["OMHTraitShop.RewardMode"].selected=4
    return value
end
local p=SandboxOptionsScreen:createPanel(panel())
for mode=1,4 do
    p.controls["OMHTraitShop.RewardMode"].selected=mode
    p:prerender()
    local count=0
    for i=1,#p.settingNames do
        local name=p.settingNames[i]
        local key=string.match(name,"%.(.+)$")
        local expected=Config.defaults[key]==nil or Config.visible(mode,key)
        check(p.controls[name].visible==expected and p.labels[name].visible==expected,"control and label mode visibility "..mode..":"..key)
        if expected then
            check(p.controls[name].y==11+count*34,"visible rows compact without holes")
            count=count+1
        end
    end
    check(p.scrollHeight==11+count*34 and #p.joypadButtonsY==count,"scroll and keyboard rows match visible mode")
end
check(p.originalCalled,"native panel render still called")
local previous=p.prerender
UI.attach(p)
check(previous==p.prerender,"panel hook is not installed twice")
local admin=ISServerSandboxOptionsUI:createPanel(panel())
check(admin.omhRewardLayout,"live admin sandbox panel receives visibility rules")
local host=setmetatable({}, {__index=ServerSettingsScreen})
host:create()
check(host.pageEdit:createPanel({},panel()).omhRewardLayout,"host settings editor receives visibility rules")
testHorde=true
local presets=setmetatable({presets={}}, {__index=SandboxOptionsScreen})
presets:addPresetToList("Apocalypse","Apocalypse",false)
check(testPresetMode==3,"built-in preset uses dependency default")
testPresetMode=4
presets:addPresetToList("Mine","Mine",true)
check(testPresetMode==4,"user presets are never overwritten by default selection")
testOutput=tostring(testChecks).." Checkpoint 6 reward and sandbox UI checks passed."
