Scope = {}


function Scope:new(width, height)
    local new = {}	
    setmetatable(new, self)
    self.__index = self

    new.input = {}
    for i = 1,1024 do
        new.input[i] = 0
    end
    new.index = 1
    new.wait = false
    new.length = 44100 / 235

    new.width = width
    new.height = height/2

    return new
end


function Scope:update(a)
    self.input[self.index] = a
    self.index = self.index + 1
    if(self.index > self.length*3) then
        self.index = 1
    end
end


function Scope:draw()
    love.graphics.setColor(0.5,1.0,0.5)
    for i=2, self.length*3 do
        local xscale = self.width/(self.length*3)
        love.graphics.line((i-1)*xscale,self.height+self.input[i-1]*self.height/2,i*xscale,self.height+self.input[i]*self.height/2)
    end
end
