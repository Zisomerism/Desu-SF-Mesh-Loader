if SERVER then
    
    local function createWireInputs(objectNameTable)
        local t = {}
        for k,v in pairs(objectNameTable) do
            t[k] = "entity"
        end
        wire.adjustInputs(objectNameTable,t)
    end
    
    hook.add("net","handlewireinputcreation",function(name, len, pl)
        local objectNamesTable = net.readTable()
        createWireInputs(objectNamesTable)
    end)
    
    hook.add("Input", "entinputs", function(name, value)
        if value:isValid() then
            net.start("handleholoparenting")
            net.writeString(name)
            net.writeEntity(value)
            net.send(owner())
        end
    end)

else
    
    local OBJFileURL = ""
    local meshScale = 10
    local zAxisOffset = 0
    local objectNames = {}
    local textureURLs = {}
    local textureFlags = {}
    local bumpmapURLs = {}
    local holoTable = {}
    
    function loadOBJFromURL(objURL, scale, zOffset)
        OBJFileURL = objURL
        meshScale = scale or 10
        zAxisOffset = zOffset or 0
    end
    
    function addObjectTexturePair(objectName, textureURL, bumpmapURLorFlagInt, flagInt)
        flagInt = flagInt or 0
        if isnumber(bumpmapURLorFlagInt) then
            flagInt = bumpmapURLorFlagInt
            local bumpmapURL = nil
        else
            local bumpmapURL = bumpmapURLorFlagInt
        end
        table.insert(objectNames, objectName)
        table.insert(textureURLs, textureURL)
        table.insert(bumpmapURLs, bumpmapURL)
        table.insert(textureFlags, flagInt)
    end
    
    local function createHolo(objectName)
        local holo = holograms.create(chip():getPos()+Vector(0,0,zAxisOffset), chip():localToWorldAngles(Angle(0,0,90)), "models/hunter/blocks/cube025x025x025.mdl", Vector(0))
        holo:setParent(chip())
        local objectNameCapitalized = string.gsub(string.gsub(objectName,"^%l",string.upper),"[%p%c%s]","")
        holoTable[objectNameCapitalized] = holo
        return holo
    end
    
    local function parentHolo(objectName, parentEnt)
        local holo = holoTable[objectName]
        holo:setParent(parentEnt)
    end
    
    local function createTexture(textureURL, bumpmapURL, flagInt)
        local texture = material.create("VertexLitGeneric")
        texture:setTextureURL("$basetexture", textureURL)
        if bumpmapURL != nil then
            texture:setTextureURL("$bumpmap", bumpmapURL)
            texture:setTexture("$envmap", "env_cubemap")
            texture:setFloat("$envmapcontrast", 1)
            texture:setFloat("$envmapsaturation", 0.20000000298023)
            texture:setVector("$envmaptint", Vector(0.006585, 0.006585, 0.006585))
            texture:setInt("$phong", 1)
            texture:setFloat("$phongboost", 1)
            texture:setFloat("$phongexponent", 200)
            texture:setVector("$phongfresnelranges", Vector(0.2, 0.6, 1))
        end
        if flagInt > 0 then
            texture:setInt("$flags", flagInt)
        end
        return texture
    end
    
    local function setHoloMesh(holo, mesh_, texture)
        holo:setMesh(mesh_)
        holo:setMeshMaterial(texture)
        holo:setRenderBounds(Vector(-500),Vector(500))
    end
    
    function createMeshFromOBJ()
        http.get(OBJFileURL,function(objdata)  
            for k,v in ipairs(objectNames) do
                local holo = createHolo(objectNames[k])
                local texture = createTexture(textureURLs[k],bumpmapURLs[k],textureFlags[k])
                local loadMesh = coroutine.wrap(function() meshLoadedFromObj = mesh.createFromObj(objdata, true, true)[objectNames[k]] return true end) 
                hook.add("think",objectNames[k],function()
                    while math.max(quotaAverage(), quotaUsed()) < quotaMax() /10 do
                        if loadMesh() then
                            setHoloMesh(holo, meshLoadedFromObj, texture)
                            holo:setScale(Vector(meshScale))
                            print("Finished loading:", objectNames[k], "with texture:", textureURLs[k], bumpmapURLs[k])
                            hook.remove("think",objectNames[k])
                            return
                        end
                    end
                end)
            end
            net.start("handlewireinputcreation")
            net.writeTable(table.getKeys(holoTable))
            net.send() 
        end) 
    end 
    
    hook.add("net","handleholoparenting",function(name, len, pl)
        local objectName = net.readString()
        local parentEnt = net.readEntity()
        parentHolo(objectName, parentEnt)
    end)
    
end
