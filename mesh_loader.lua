local OBJFileURL = ""
local meshScale = 10
local zAxisOffset = 0
local objectNames = {}
local textureURLs = {}
local textureFlags = {}

function loadOBJFromURL(objURL, scale, zOffset)
    OBJFileURL = objURL
    meshScale = scale or 10
    zAxisOffset = zOffset or 0
end

function addObjectTexturePair(objectName, textureURL, flagInt)
    flagInt = flagInt or 0
    table.insert(objectNames, objectName)
    table.insert(textureURLs, textureURL)
    table.insert(textureFlags, flagInt)
end

local function createHolo()
    local holo = holograms.create(chip():getPos()+Vector(0,0,zAxisOffset), chip():localToWorldAngles(Angle(0,0,90)), "models/hunter/blocks/cube025x025x025.mdl", Vector(meshScale))
    holo:setParent(chip())
    return holo
end

local function createTexture(textureURL, flagInt) 
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
    holo:setRenderBounds(Vector(-500),Vector(500))
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
