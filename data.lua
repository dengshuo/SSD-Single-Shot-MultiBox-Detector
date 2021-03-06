require "torch"
require "image"
require "math"
require "LuaXML"
dofile "etc.lua"

function label_to_num(label)

    if label == "aeroplane" then
        return 1
    elseif label == "bicycle" then
        return 2
    elseif label == "bird" then
        return 3
    elseif label == "boat" then
        return 4
    elseif label == "bottle" then
        return 5
    elseif label == "bus" then
        return 6
    elseif label == "car" then
        return 7
    elseif label == "cat" then
        return 8
    elseif label == "chair" then
        return 9
    elseif label == "cow" then
        return 10
    elseif label == "diningtable" then
        return 11
    elseif label == "dog" then
        return 12
    elseif label == "horse" then
        return 13
    elseif label == "motorbike" then
        return 14
    elseif label == "person" then
        return 15
    elseif label == "pottedplant" then
        return 16
    elseif label == "sheep" then
        return 17
    elseif label == "sofa" then
        return 18
    elseif label == "train" then
        return 19
    elseif label == "tvmonitor" then
        return 20
    end
    
end


function load_data(mode)

    target = {}
    name = {}
    count = torch.Tensor(classNum):zero()

    if mode == "train" then
        print("training data loading...")

        for did = 1,3 do

            if did == 1 then 
                db_dir_ = db_dir .. "VOC2012_trainval/"
                imgDir = db_dir_ .. 'JPEGImages/'
                annotDir = db_dir_ .. 'Annotations/parsed/'
                annotFileList = {}
                for line in io.lines(db_dir .. "VOC2012_trainval/ImageSets/Main/train.txt") do
                    table.insert(annotFileList,line .. ".txt")
                end
            else
                if did == 2 then db_dir_ = db_dir .. "VOC2007_trainval/" end
                if did == 3 then db_dir_ = db_dir .. "VOC2007_test/" end

                imgDir = db_dir_ .. 'JPEGImages/'
                annotDir = db_dir_ .. 'Annotations/parsed/'
                f = io.popen('ls ' .. annotDir)
                annotFileList = {}
                for name in f:lines() do table.insert(annotFileList,name) end
            end
                   
            for fid = 1,#annotFileList do
                
                --img load
                img = image.load(imgDir .. annotFileList[fid]:sub(1,-4) .. "jpg")
                local imgHeight = img:size()[2]
                local imgWidth = img:size()[3]

                --name save
                table.insert(name,imgDir .. annotFileList[fid]:sub(1,-4) .. "jpg")

                --label save
                target_per_sample = {}
                for line in io.lines(annotDir .. annotFileList[fid]) do
                    
                    parsed_line = str_split(line,",")
                    
                    label = label_to_num(parsed_line[1])
                    xmax = tonumber(parsed_line[2])
                    xmin = tonumber(parsed_line[3])
                    ymax = tonumber(parsed_line[4])
                    ymin = tonumber(parsed_line[5])
                    count[label] = count[label] + 1
                    
                    --[===[
                    --for debug
                    img = drawRectangle(img,xmin,ymin,xmax,ymax,"r")
                    image.save(tostring(fid) .. ".jpg",img)
                    --]===]
                    
                    table.insert(target_per_sample,{label,xmax,xmin,ymax,ymin,imgWidth,imgHeight})
                end
               
                table.insert(target,target_per_sample)
            end
        end
        trainSz = table.getn(target)
        return target, name
    
    elseif mode == "test" then
        print("test data loading...")
        db_dir_ = db_dir .. "VOC2012_trainval/"
        imgDir = db_dir_ .. 'JPEGImages/'
        testFileList = {}
        for line in io.lines(db_dir .. "VOC2012_trainval/ImageSets/Main/val.txt") do
            table.insert(testFileList,imgDir .. line .. ".jpg")
        end
        testSz = table.getn(testFileList)
        return {}, testFileList
    end
    
end

