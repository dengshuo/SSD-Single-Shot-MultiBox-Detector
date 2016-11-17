db_dir = "/media/sda1/Data/PASCAL_VOC/VOCdevkit/"
result_dir = "/media/sda1/Data/PASCAL_VOC/VOCdevkit/results/VOC2012/Main/"
model_dir = result_dir .. "model/"
fig_dir = result_dir .. "fig/"

mode = "train"
continue = false
continue_iter = 0

classNum = 21
negId = 21
inputDim = 3
imgSz = 300
trainSz = 17125 --+ 5011 + 4952
thr = 0.18
classList = {"aeroplane","bicycle","bird","boat","bottle","bus","car","cat","chair","cow","diningtable","dog","horse","motorbike","person","pottedplant","sheep","sofa","train","tvmonitor"}

m = 5
scale_table = {}
for k=1,m do
    table.insert(scale_table,0.2 + (0.95 - 0.2)/(m-1) * (k-1))
end
ar_table = {1,2,3,1/2,1/3}
fmSz = {19,10,5,3,1}
tot_box_num = 0
for lid = 1,m do
    if lid < m then
        ar_num = 6
    else
        ar_num = 5
    end

    tot_box_num = tot_box_num + ar_num*fmSz[lid]*fmSz[lid]
end

lr = 1e-3
wDecay = 5e-4
mmt = 9e-1
batchSz = 32
iterLimit = 6e4 - continue_iter
iterLrDecay = 4e4 - continue_iter

function str_split(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end
  
restored_box = {} --xmax xmin ymax ymin
table.insert(restored_box,torch.Tensor(6,4,fmSz[1],fmSz[1]):zero())
table.insert(restored_box,torch.Tensor(6,4,fmSz[2],fmSz[2]):zero())
table.insert(restored_box,torch.Tensor(6,4,fmSz[3],fmSz[3]):zero())
table.insert(restored_box,torch.Tensor(6,4,fmSz[4],fmSz[4]):zero())
table.insert(restored_box,torch.Tensor(5,4,fmSz[5],fmSz[5]):zero())

for lid = 1,m do
       
   for r = 1,fmSz[lid] do
       for c = 1,fmSz[lid] do
            local xCenter = (c-1+0.5)/fmSz[lid]
            local yCenter = (r-1+0.5)/fmSz[lid]
            for aid = 1,table.getn(ar_table)+1 do

                if lid < m then
                    if aid <= table.getn(ar_table) then
                        ar_factor = ar_table[aid]
                        scale_factor = scale_table[lid]
                    else
                        ar_factor = 1
                        scale_factor = math.sqrt(scale_table[lid] * scale_table[lid+1])
                    end
                else
                    if aid <= table.getn(ar_table) then
                        ar_factor = ar_table[aid]
                        scale_factor = scale_table[lid]
                    else
                        goto nextCell
                    end
                end

                local width = scale_factor*math.sqrt(ar_factor)
                local height = scale_factor/math.sqrt(ar_factor)

                restored_box[lid][aid][1][r][c] = math.min((xCenter + width/2) * (imgSz),imgSz)
                restored_box[lid][aid][2][r][c] = math.max((xCenter - width/2) * (imgSz),1)
                restored_box[lid][aid][3][r][c] = math.min((yCenter + height/2) * (imgSz),imgSz)
                restored_box[lid][aid][4][r][c] = math.max((yCenter - height/2) * (imgSz),1)

                ::nextCell::
            end
        end
    end
end

function parse_idx(idx)
    
    local lid, aid, yid, xid
    idx = idx-1

    for lid = 1,m do
        
        if lid < m then
            ar_num = 6
        else
            ar_num = 5
        end

        if idx < ar_num*fmSz[lid]*fmSz[lid] then
        
            aid = math.floor(idx/(fmSz[lid]*fmSz[lid]))
            yid = math.floor((idx%(fmSz[lid]*fmSz[lid]))/fmSz[lid])
            xid = idx%(fmSz[lid]*fmSz[lid])%fmSz[lid]

            return lid,aid+1,yid+1,xid+1
        end

        idx = idx - ar_num*fmSz[lid]*fmSz[lid]
    end

end

function combine_idx(lid,aid,yid,xid)
    
    aid = aid-1
    yid = yid-1
    xid = xid-1

    if lid == 1 then
        return (aid*fmSz[lid]*fmSz[lid] + yid*fmSz[lid] + xid) + 1
    end
    
    local result = 0
    for l = 1,lid-1 do
        result = result + 6*fmSz[l]*fmSz[l]
    end
    
    result = result + aid*fmSz[lid]*fmSz[lid] + yid*fmSz[lid] + xid

    return result+1

end


function drawRectangle(img,xmin,ymin,xmax,ymax)
    
    img_origin = img:clone()
    img[1][{{ymin,ymax},{xmin,xmax}}] = 255
    img[2][{{ymin,ymax},{xmin,xmax}}] = 0
    img[3][{{ymin,ymax},{xmin,xmax}}] = 0
    
    if ymin+2 < ymax-2 then
        ymin = ymin+2
        ymax = ymax-2
    end

    if xmin+2 < xmax-2 then
        xmin = xmin+2
        xmax = xmax-2
    end

    img[1][{{ymin,ymax},{xmin,xmax}}] = img_origin[1][{{ymin,ymax},{xmin,xmax}}]
    img[2][{{ymin,ymax},{xmin,xmax}}] = img_origin[2][{{ymin,ymax},{xmin,xmax}}]
    img[3][{{ymin,ymax},{xmin,xmax}}] = img_origin[3][{{ymin,ymax},{xmin,xmax}}]

    return img
end


