require("waveguide")

-- valve patterns
keys = {                  -6,-5,-4,-3,-2,-1,
         0,-6,-5,-4,-3,-2,-1, 0,-4,-3,-2,-1,
         0,-3,-2,-1, 0,-2,-1, 0,-4,-3,-2,-1, 0}

param = {
-0.013200667274239,
-0.017510339559265,
-0.022888981499059,
-0.029523198334262,
-0.037736038266239,
-0.047762424301628,
-0.059965722025053,
-0.072371529980717,
-0.091087702147866,
-0.11114586491364,
-0.13416999889321,
-0.1626324836453,
-0.19605287123051,
-0.23787127618823,
-0.28865529935575,
-0.34453017492341,
-0.39876681848583,
-0.46763376195722,
-0.54572131719314,
-0.75191280973749,
-0.86653169379421,
-0.98001317964498,
-1.1159657705301,
-1.1070956955478,
-1.259605579122,
-1.4391258357219,
-1.6716961396856,
-1.9020012612799,
-2.1557265143301,
-2.4422097153421,
-2.7626185367762}

Flute = {}

function Flute:new()
    local new = {}	
    setmetatable(new, self)
    self.__index = self

    new.t = 0

    new.env = 0
    new.env2 = 0
    new.env3 = 0
    new.keyOn = false

    new.x = 0

    new.out = 0.1
    new.pout = 0.1
    new.lastZero = 0
    new.fdetect = 0
    new.pdetect = 0
    new.ptarget = 38

    new.errp = 0
    new.erri = 0
    new.errd = 0
    new.errpp = 0

    new.b = 0

    new.wave = Waveguide:new(400)
    new.wave.length = 44100/233
    new.valve1 = Waveguide:new(30)
    new.valve1.length = 23.19
    new.valve2 = Waveguide:new(20)
    new.valve2.length = 11.145
    new.valve3 = Waveguide:new(40)
    new.valve3.length = 36.028
    new.filter = 0
    new.filter2 = 0
    
    new.sv = 0
    new.sx = 0

    new.pv = 0
    new.px = 0

    new.v1 = 0
    new.v2 = 0
    new.v3 = 0

    new.v1_ = 0
    new.v2_ = 0
    new.v3_ = 0

    return new
end

function Flute:noteOn(note)
    if not note then
        note = self.ptarget
    end

    self.ptarget = note

    self:setValvePattern()

    if self.keyOn == false then
        print("jump")
        --set valves instantly
        self.v1_ = self.v1
        self.v2_ = self.v2
        self.v3_ = self.v3
        --reset env only when not legato
        self.env2 = 0
        self.env3 = 0

        --quadratic fit
        local ftarget = math.pow(2,(self.ptarget-49)/12)*440
        self.b = -8.83e-3 + 6.94e-4*ftarget - 3.94e-6*ftarget*ftarget

        --low notes from array
        if self.ptarget - 32 <= 5 then
            self.b = param[self.ptarget - 31]
        end
    end

    self.keyOn = true
    self.erri = 0
end

function Flute:setValvePattern()
    local p = keys[self.ptarget - 31] or 0

    if p == 0 then
        self.v1 = 0
        self.v2 = 0
        self.v3 = 0
    elseif p == -1 then
        self.v1 = 0
        self.v2 = 1
        self.v3 = 0
    elseif p == -2 then
        self.v1 = 1
        self.v2 = 0
        self.v3 = 0
    elseif p == -3 then
        self.v1 = 1
        self.v2 = 1
        self.v3 = 0
    elseif p == -4 then
        self.v1 = 0
        self.v2 = 1
        self.v3 = 1
    elseif p == -5 then
        self.v1 = 1
        self.v2 = 0
        self.v3 = 1
    elseif p == -6 then
        self.v1 = 1
        self.v2 = 1
        self.v3 = 1
    end
end

function Flute:noteOff(note) 
    self.keyOn = false
end

function Flute:setX(x)
    self.x = x
end

function Flute:update()
    if self.keyOn then
        self.env = self.env*0.99 + 1*0.01
    else
        self.env = self.env*0.99
    end

    self.env2 = self.env2 + 40/44100
    self.env2 = math.min(self.env2, self.x)

    if self.env3 < 1 then
        self.env3 = self.env3 + 0.5/44100
    end

    local dt = 1/44100
    self.t = self.t + dt

    self.px,self.pv = self.sx,self.sv

    local l,r = self.wave:peek()
    l,r = -l,-r

    local x = self.sx
    local y = self.sv
    local a = 0.05-0.20*self.env
    local b = self.b

    --error correction PID
    if self.env3 > 0.2 then
        b = b + (0.04*self.errp + 0.2*self.erri)
        b = math.min(b,1.0)
    end

    self.f = b

    --vibrato
    b = b*(1.0 + self.env3*0.1*math.sin(self.t*25 + 0.3*math.sin(self.t*17)))

    b = b * self.env
    local g = 3500


    for i = 1,1 do
        self.sv = self.sv + (g*g*a + g*g*b*x + g*g*x*x - g*x*y - g*g*x*x*x - g*x*x*y)*dt + love.math.randomNormal(0.1) + 220*l
        self.sx = self.sx + self.sv*dt
    end

    l = self.sx*0.5 + l * self.env2*0.6

    a = 1.0
    self.filter = self.filter*(1-a) + l*a
    a = 0.1 - 0.09*self.env2
    self.filter2 = self.filter2*(1-a) + self.filter*a
    l = (self.filter - self.filter2)

    local spd = 0.002

    self.v1_ = self.v1_*(1.0-spd) + self.v1*spd
    self.v2_ = self.v2_*(1.0-spd) + self.v2*spd
    self.v3_ = self.v3_*(1.0-spd) + self.v3*spd

    local l1,r1 = self.valve1:peek()
    local l2,r2 = self.valve2:peek()
    local l3,r3 = self.valve3:peek()

    local o1 = self.v1_
    local o2 = self.v2_
    local o3 = self.v3_

    local a = r
    local b = a*(1.0-o1) + r1*o1
    local c = b*(1.0-o2) + r2*o2

    local d =  r2*(1.0-o3) + l3*o3
    local e = (r1*(1.0-o3) + l3*o3)*(1.0-o2) + l2*o2
    local f = ((r*(1.0-o3) + l3*o3)*(1.0-o2) + l2*o2)*(1.0-o1) + l1*o1

    self.valve1:put(e, a)
    self.valve2:put(d, b)
    self.valve3:put(r3, c)
    self.wave:put(f, l)

    self.pout = self.out
    self.out = clip(l*0.7)

    if self.out < 0.1 and self.pout > 0.10001 then
        self.fdetect = 1/(self.t - self.lastZero)
        self.pdetect = 12 * math.log(self.fdetect/440)/math.log(2) + 49

        self.errpp = self.errp

        self.errp = self.errp*0.95 + (self.pdetect - self.ptarget)*0.05
        self.erri = self.erri + self.errp*0.01
        self.errd = self.errp - self.errpp

        if self.env3 < 0.2 then
            self.erri = 0
        end
        self.lastZero = self.t
    end

    return self.out
end

function clip(x)
    if(x <= -1) then
        return -2/3
    elseif(x >= 1) then
        return 2/3
    else
        return x-(x^3)/3
    end
end
