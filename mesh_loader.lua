local OBJFileURL = ""
local meshScale = 10
local objectNames = {}
local textureURLs = {}
local textureFlags = {}

function loadOBJFromURL(objURL,scale)
    OBJFileURL = objURL
    meshScale = scale or 10
end

function addObjectTexturePair(objectName, textureURL, flagInt)
    flagInt = flagInt or 0
    table.insert(objectNames, objectName)
    table.insert(textureURLs, textureURL)
    table.insert(textureFlags, flagInt)
end

local function createHolo()
    local holo = holograms.create(chip():getPos(), chip():getAngles()+Angle(0,0,0), "models/sprops/rectangles_superthin/size_1/rect_3x3.mdl", Vector(1)*meshScale)
    holo:setColor(Color(255,255,255))
    holo:setParent(chip())
    holo:setAngles(chip():localToWorldAngles(Angle(0,0,90)))  
    holo:setPos(chip():getPos())
    return holo
end

local function createTexture(textureURL, flagInt) 
    flagInt = flagInt or 0
    local texture = material.create("VertexLitGeneric")
    texture:setTextureURL("$basetexture", textureURL)
    if flagInt > 0 then
        texture:setInt("$flags", flagInt)
    end
    return texture
end

local function setHoloMesh(holo, mesh_, texture)
    holo:setMesh(mesh_)
    holo:setMeshMaterial(texture)
    holo:setRenderBounds(Vector(-1000),Vector(1000)) --adjust if you're loading something huge or something with massively offset meshes (which you probably shouldn't be doing), otherwise this should be fine.
end

function createMeshFromOBJ()
    http.get(OBJFileURL,function(objdata)  
        for k,v in ipairs(objectNames) do
            local loadMesh = coroutine.wrap(function() meshLoadedFromObj = mesh.createFromObj(objdata, true, true)[objectNames[k]] return true end) 
            hook.add("think",objectNames[k],function()
                while math.max(quotaAverage(), quotaUsed()) < quotaMax() /10 do
                    if loadMesh() then
                        setHoloMesh(createHolo(), meshLoadedFromObj, createTexture(textureURLs[k],textureFlags[k]))
                        print("Finished loading:", objectNames[k], "with texture:", textureURLs[k])
                        hook.remove("think",objectNames[k])
                        return
                    end
                end
            end)
        end
    end)  
end 
