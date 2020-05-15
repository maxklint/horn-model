require("waveguide")
require("horn")
require("scope")
require("qaudio")

--print console directly
io.stdout:setvbuf("no")

width = 800
height = 640

mouseX_ = 0

-- MIDI - 20 (Bb3 = MIDI 58)
keyboardToMidi = { ["q"] = 38, ["2"] = 39, ["w"] = 40, ["3"] = 41, ["e"] = 42, ["r"] = 43,
       ["5"] = 44, ["t"] = 45, ["6"] = 46, ["y"] = 47, ["7"] = 48, ["u"] = 49, ["i"] = 50}

-- love.window.setMode(width,height,{vsync=true,fullscreen=true,fullscreentype = "desktop",borderless = true, y=0}) 
love.window.setMode(width,height,{vsync=true,fullscreen=false,fullscreentype = "desktop",borderless = false}) 

-- audio callback
function dsp(time)
    mouseX_ = mouseX_*0.99 + (mouseX/width)*0.01
    horn:setX(mouseX_)

    out = horn:update()

    scope:update(out)

    return out
end


function love.load()
    math.randomseed(os.time())
    love.math.setRandomSeed(os.time())

    love.graphics.setLineWidth(1)

    horn = Flute:new()

    scope = Scope:new(width, height)

    Quadio.load()
    Quadio.setCallback(dsp)
end


function love.update(dt)
    mouseX,mouseY = love.mouse.getPosition()

    Quadio.update()

    if not love.keyboard.isDown('q','w','e','r','t','y','u','i','2','3','5','6','7','space') then
        horn:noteOff()
    end
end


function love.draw()
    love.graphics.setBackgroundColor(0,0,0)
    scope:draw()
end


function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    local midi = keyboardToMidi[key]
    if midi then
        horn:noteOn(midi)

        local ftarget = math.pow(2,(midi-49)/12)*440
        scope.length = 44100/ftarget
    end
end
