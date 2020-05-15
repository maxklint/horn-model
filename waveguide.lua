Waveguide = {}


function Waveguide:new(length)
    local new = {}	
    setmetatable(new, self)
    self.__index = self

    new.len = length

    new.fp = 0
    new.fp2 = 0

    new.r = {}
    new.l = {}
    for i = 0, length-1 do
        new.r[i] = 0
        new.l[i] = 0
    end

    new.writeptr = 0

    new.length = new.len

    return new
end


function Waveguide:peek()
    local l = self:read(self.l,self.length)
    local r = self:read(self.r,self.length)

    return l,r
end


function Waveguide:put(refl_l,refl_r)
    self.l[(self.writeptr)%self.len] = refl_l
    self.r[(self.writeptr)%self.len] = refl_r

    self.writeptr = self.writeptr + 1
end


function Waveguide:read(t,i)
    local int = math.floor(i)
    local fract = i-int

    return t[(self.writeptr-int)%self.len]*(1-fract) + t[(self.writeptr-int-1)%self.len]*fract
end
