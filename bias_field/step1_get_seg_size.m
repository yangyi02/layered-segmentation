clear; clc;

% addpath('D:/Research/Object Detection and Image Segmentation/Others Code/voc-release3','-end');
addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOCcode','-end');
addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/ImageSets/Segmentation','-end');
addpath('D://Research/Object Detection and Image Segmentation/My Code/test program 0910/PASCAL/initialization/','-end');
load initializationresult.mat;

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
            
            wj = x2(j) - x1(j) + 1; hj = y2(j) - y1(j) + 1;
            x10(j) = x1(j) - round(wj/2); x20(j) = x2(j) + round(wj/2);
            y10(j) = y1(j) - round(hj/2); y20(j) = y2(j) + round(hj/2);
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
                
                h{k}{v}(m(k,v)) = y20(j) - y10(j) + 1;
                w{k}{v}(m(k,v)) = x20(j) - x10(j) + 1;
                
                for p = 1:6
                    px1 = box{i}{k}(j,1+4+(p-1)*4);
                    py1 = box{i}{k}(j,2+4+(p-1)*4);
                    px2 = box{i}{k}(j,3+4+(p-1)*4);
                    py2 = box{i}{k}(j,4+4+(p-1)*4);
                         
                    ph{k}{v}{p}(m(k,v)) = py2 - py1 + 1;
                    pw{k}{v}{p}(m(k,v)) = px2 - px1 + 1;
                end
            end
        end
    end
    fprintf('finish image %d\n',i);
end

save stdsegmentsize_fromdevabox.mat h w ph pw m;

load stdsegmentsize_fromdevabox.mat;

for k = 1:K
    for v = 1:2
        for i = 1:m(k,v)
            ratio{k}{v}(i) = h{k}{v}(i)/w{k}{v}(i);
            totalpix{k}{v}(i) = h{k}{v}(i) * w{k}{v}(i);
            for p = 1:6
                if pw{k}{v}{p}(i) == 0
                    pw{k}{v}{p}(i) =  1;
                end
                pratio{k}{v}{p}(i) = ph{k}{v}{p}(i)/pw{k}{v}{p}(i);
                totalppix{k}{v}{p}(i) = ph{k}{v}{p}(i) * pw{k}{v}{p}(i);
            end
        end
        [n, bin] = hist(ratio{k}{v});
        hist(ratio{k}{v});
        [maxn, ind] = max(n);
        stdratio(k,v) = bin(ind(1));
        
        [n, bin] = hist(totalpix{k}{v});
        hist(totalpix{k}{v});
        [maxn, ind] = max(n);
        stdtotalpix(k,v) = quantile(totalpix{k}{v},0.1);        

        stdw(k,v) = round(sqrt(stdtotalpix(k,v)/stdratio(k,v)));
        stdh(k,v) = round(sqrt(stdtotalpix(k,v)*stdratio(k,v)));
        
        for p = 1:6
            [n, bin] = hist(pratio{k}{v}{p});
            hist(pratio{k}{v}{p});
            [maxn, ind] = max(n);
            stdpratio{p}(k,v) = bin(ind(1));

            [n, bin] = hist(totalppix{k}{v}{p});
            hist(totalppix{k}{v}{p});
            [maxn, ind] = max(n);
            stdptotalpix{p}(k,v) = quantile(totalppix{k}{v}{p},0.1);            
            
            stdpw{p}(k,v) = round(sqrt(stdptotalpix{p}(k,v)/stdpratio{p}(k,v)));
            stdph{p}(k,v) = round(sqrt(stdptotalpix{p}(k,v)*stdpratio{p}(k,v)));
        end
    end
end

save stdsegmentsize_fromdevabox.mat -append stdw stdh stdpw stdph;
