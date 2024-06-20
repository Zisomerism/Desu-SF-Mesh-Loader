local OBJFileURL = ""
local meshScale = 10
local zAxisOffset = 0
local objectNames = {}
local textureURLs = {}
local bumpmapURLs = {}
local textureFlags = {}

function loadOBJFromURL(objURL, scale, zOffset)
    OBJFileURL = objURL
    meshScale = scale or 10
    zAxisOffset = zOffset or 0
end

function addObjectTexturePair(objectName, textureURL, bumpmapURLorFlagInt, flagInt)
    local bumpmapURL = bumpmapURL or nil
    flagInt = flagInt or 0
    if isnumber(bumpmapURLorFlagInt) then
        flagInt = bumpmapURLorFlagInt
        bumpmapURL = nil
    else
        bumpmapURL = bumpmapURLorFlagInt
    end
    table.insert(objectNames, objectName)
    table.insert(textureURLs, textureURL)
    table.insert(bumpmapURLs, bumpmapURL)
    table.insert(textureFlags, flagInt)
end

local function createHolo()
    local holo = holograms.create(chip():getPos()+Vector(0,0,zAxisOffset), chip():localToWorldAngles(Angle(0,0,90)), "models/hunter/blocks/cube025x025x025.mdl", Vector(meshScale))
    holo:setParent(chip())
    return holo
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
            local loadMesh = coroutine.wrap(function() meshLoadedFromObj = mesh.createFromObj(objdata, true, true)[objectNames[k]] return true end) 
            hook.add("think",objectNames[k],function()
                while math.max(quotaAverage(), quotaUsed()) < quotaMax() /10 do
                    if loadMesh() then
                        setHoloMesh(createHolo(), meshLoadedFromObj, createTexture(textureURLs[k],bumpmapURLs[k],textureFlags[k]))
                        print("Finished loading:", objectNames[k], "with texture:", textureURLs[k], bumpmapURLs[k])
                        hook.remove("think",objectNames[k])
                        return
                    end
                end
            end)
        end
    end)  
end 
