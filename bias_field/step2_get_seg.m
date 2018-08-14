clear; clc;

% addpath('D:/Research/Object Detection and Image Segmentation/Others Code/voc-release3','-end');
% addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOCcode','-end');
% addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/ImageSets/Segmentation','-end');
% addpath('D://Research/Object Detection and Image Segmentation/My Code/test program 0910/PASCAL/initialization/','-end');
load initializationresult.mat;
load stdsegmentsize_fromdevabox.mat;

N = length(ids);
K = VOCopts.nclasses;

% extract useful groundtruth segmentations from the detection
m = zeros(20,2);
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
            x10(j) = x1(j) - round(w/2); x20(j) = x2(j) + round(w/2);
            y10(j) = y1(j) - round(h/2); y20(j) = y2(j) + round(h/2);
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
                v = box{i}{k}(j,4+6*4+1);
                m(k,v) = m(k,v)+1;

                ind = imsegobj == objlabel(maxind);
                trainseg{k}{v}{m(k,v)} = zeros(y20(j)-y10(j)+1,x20(j)-x10(j)+1);
                tmp = ind(max(y10(j),1):min(y20(j),H),max(x10(j),1):min(x20(j),W));
                trainseg{k}{v}{m(k,v)}(max(y10(j),1)-y10(j)+1:min(y20(j),H)-y10(j)+1,max(x10(j),1)-x10(j)+1:min(x20(j),W)-x10(j)+1) = tmp;
                
                trainseg{k}{v}{m(k,v)} = imresize(trainseg{k}{v}{m(k,v)},[stdh(k,v),stdw(k,v)],'nearest');
                
                trainbox{k}{v}(m(k,v),:) = box{i}{k}(j,:);

                for p = 1:6
                    px1 = round(box{i}{k}(j,1+4+(p-1)*4));
                    py1 = round(box{i}{k}(j,2+4+(p-1)*4));
                    px2 = round(box{i}{k}(j,3+4+(p-1)*4));
                    py2 = round(box{i}{k}(j,4+4+(p-1)*4));
                    
                    trainpartseg{k}{v}{m(k,v)}{p} = zeros(py2-py1+1,px2-px1+1);
                    
                    px3 = max(px1,1);
                    px4 = min(px2,W);
                    py3 = max(py1,1);
                    py4 = min(py2,H);
                    
                    if px3 < px4 && py3 < py4           
                        indbbobj = imsegobj(py3:py4,px3:px4);
                        ind = indbbobj == objlabel(maxind);
                        
                        trainpartseg{k}{v}{m(k,v)}{p}(py3-py1+1:py4-py1+1,px3-px1+1:px4-px1+1) = ind;
                    end
                    trainpartseg{k}{v}{m(k,v)}{p} = imresize(trainpartseg{k}{v}{m(k,v)}{p},[stdph{p}(k,v),stdpw{p}(k,v)],'nearest');
                end
            end
        end
    end 
    fprintf('finish image %d\n',i);
end

save trainsegment_fromdevabox.mat trainseg trainbox trainpartseg;
