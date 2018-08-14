clear; clc; clf;

% addpath('D:/Research/Object Detection and Image Segmentation/Others Code/voc-release3','-end');
% addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOCcode','-end');
% addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/ImageSets/Segmentation','-end');
% addpath('D:/Research/Object Detection and Image Segmentation/My Code/test program 0824/PASCAL','-end');
load initializationresult.mat;

N = length(ids);
K = VOCopts.nclasses;

load trainsegment_fromdevabox.mat;
load stdsegmentsize_fromdevabox.mat;

for k = 1:K
    for v = 1:2
        num(k,v) = length(trainseg{k}{v});
        fgcount{k}{v} = ones(stdh(k,v),stdw(k,v)) * 5;
        for p = 1:6
            pfgcount{k}{v}{p} = ones(stdph{p}(k,v),stdpw{p}(k,v)) * 5;
        end
        for i = 1:num(k,v)
            fgcount{k}{v} = fgcount{k}{v} + trainseg{k}{v}{i};
            for p = 1:6
                pfgcount{k}{v}{p} = pfgcount{k}{v}{p} + trainpartseg{k}{v}{i}{p};
            end
        end
        fgbias{k}{v} = fgcount{k}{v} / (num(k,v)+10);
        for p = 1:6
            pfgbias{k}{v}{p} = pfgcount{k}{v}{p} / (num(k,v)+10);
        end
%         imagesc(fgbias{k}{v}); axis image;
    end
end

save biasfield_fromdevabox.mat fgbias pfgbias;

for k = 1:K
    for v = 1:2
        clf;
        imagesc(fgbias{k}{v}); axis image; axis off;
        saveas(gcf,[VOCopts.classes{k} 'fromdevabox' 'pointview' num2str(v)],'jpg');
        clf;
        for p = 1:6
            subplot(2,3,p);
            imagesc(pfgbias{k}{v}{p}); axis image; axis off;
        end
        saveas(gcf,[VOCopts.classes{k} 'part_fromdevabox' 'pointview' num2str(v)],'jpg');
    end
end