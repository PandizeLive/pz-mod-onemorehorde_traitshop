testSide = "client"
UIFont = { Large = "Large" }
function getText(key) return key end
function getTextManager() return { getFontHeight = function() return 24 end } end
ISLabel = { new = function(self, x, y, height, text, r, g, b, a, font)
    return { x=x, y=y, height=height, width=200, text=text, font=font,
        getHeight=function(self) return self.height end,
        getWidth=function(self) return self.width end,
        setVisible=function(self,value) self.visible=value end,
        setY=function(self,value) self.y=value end,
        setX=function(self,value) self.x=value end }
end }
SandboxOptionsScreen = { createPanel = function(self,page) return page end,
    addPresetToList = function(self,name,text,userDefined)
        self.presets[#self.presets+1]={options={getOptionByName=function()
            return {setValue=function(self,value) testPresetMode=value end,setDefaultToCurrentValue=function() end}
        end}}
    end }
ISServerSandboxOptionsUI = {createPanel=function(self,page) return page end}
ServerSettingsScreen = {create=function(self)
    self.pageEdit={createPanel=function(self,category,page) return page end}
end}
