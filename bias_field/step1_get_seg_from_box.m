clear; clc;

% addpath('D:/Research/Object Detection and Image Segmentation/Others Code/voc-release3','-end');
addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOCcode','-end');
addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/ImageSets/Segmentation','-end');
addpath('D://Research/Object Detection and Image Segmentation/My Code/test program 0910/PASCAL/initialization/','-end');
load initializationresult.mat;

N = length(ids);
K = VOCopts.nclasses;

% extract useful groundtruth segmentations from the detection
m = zeros(20,1);
for i = 1:N
    im = imread(sprintf(VOCopts.imgpath,ids{i}));
    resdir = sprintf('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/SegmentationClass_Novoid/');
    imsegcls = double(imread(sprintf([resdir,'%s.png'],ids{i})));
    resdir = sprintf('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/SegmentationObject_Novoid/');
    imsegobj = double(imread(sprintf([resdir,'%s.png'],ids{i})));
    
    [H, W] = size(imsegcls);
    
%     imagesc(im); axis image;
%     D = length(objboxind{i});
%     if D > 0
%         boxdetind{i} = ones(1,D);
%     else
%         boxdetind{i} = [];
%     end
%     showboundingbox(im,objbox{i},objboxind{i},boxdetind{i},clscolor,VOCopts);

    for k = 1:K
        % get box detection
        if isempty(box{i}{k})
            continue;
        end
        clear x1 y1 x2 y2;
        for j = 1:size(box{i}{k},1)
            x1(j) = round(box{i}{k}(j,1));
            y1(j) = round(box{i}{k}(j,2));
            x2(j) = round(box{i}{k}(j,3));
            y2(j) = round(box{i}{k}(j,4));
            
            w = x2(j) - x1(j) + 1; h = y2(j) - y1(j) + 1;
            x10(j) = x1(j) - round(w/3); x20(j) = x2(j) + round(w/3);
            y10(j) = y1(j) - round(h/3); y20(j) = y2(j) + round(h/3);
        end
        
        % get ground truth segmentation
        indcls = imsegcls == k;
        if max(indcls(:)) == 0 % no such class, wrong bounding box
            continue;
        end
        indobj = imsegobj(indcls);
        objlabel = unique(indobj); % number of true objects
        clear left top right down;
        for l = 1:length(objlabel)
            ind = imsegobj == objlabel(l);
            [Islid, left(l), top(l), right(l), down(l)] = findslidingwindow(ind);
        end           
            
        for j = 1:size(box{i}{k},1)
            % see if this bounding box match an object very well
            clear overlap proboverlap;
            for l = 1:length(objlabel)
                overlap(l) = countoverlap(x1(j),y1(j),x2(j),y2(j),left(l),top(l),right(l),down(l));
                union(l) = (x2(j)-x1(j)+1)*(y2(j)-y1(j)+1)+(down(l)-top(l)+1)*(right(l)-left(l)+1)-overlap(l);
                proboverlap(l) = overlap(l) / union(l);
            end
            [probmax, maxind] = max(proboverlap);              
            maxind = maxind(1);

            if probmax > 0.4
                m(k) = m(k)+1;

                ind = imsegobj == objlabel(maxind);
                trainseg{k}{m(k)} = zeros(y20(j)-y10(j)+1,x20(j)-x10(j)+1);
                tmp = ind(max(y10(j),1):min(y20(j),H),max(x10(j),1):min(x20(j),W));
                trainseg{k}{m(k)}(max(y10(j),1)-y10(j)+1:min(y20(j),H)-y10(j)+1,max(x10(j),1)-x10(j)+1:min(x20(j),W)-x10(j)+1) = tmp;
                
                trainbox{k}(m(k),:) = box{i}{k}(j,:);

                for p = 1:6
                    px1 = box{i}{k}(j,1+4+(p-1)*4);
                    py1 = box{i}{k}(j,2+4+(p-1)*4);
                    px2 = box{i}{k}(j,3+4+(p-1)*4);
                    py2 = box{i}{k}(j,4+4+(p-1)*4);
                    px3 = max(round(x1),1);
                    px4 = min(round(x2),W);
                    py3 = max(round(y1),1);
                    py4 = min(round(y2),H);
                    indbbobj = imsegobj(py3:py4,px3:px4);
                    ind = indbbobj == objlabel(maxind);
                    trainpartseg{k}{m(k)}{p} = ind;
                end
            end
        end
    end 
    fprintf('finish image %d\n',i);
end

save trainsegment_fromdevabox.mat trainseg trainbox trainpartseg;
