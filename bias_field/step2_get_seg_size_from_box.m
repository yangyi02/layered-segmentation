clear; clc; clf;

% addpath('D:/Research/Object Detection and Image Segmentation/Others Code/voc-release3','-end');
% addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOCcode','-end');
% addpath('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/ImageSets/Segmentation','-end');
% addpath('D:/Research/Object Detection and Image Segmentation/My Code/test program 0824/PASCAL','-end');
addpath('D://Research/Object Detection and Image Segmentation/My Code/test program 0910/PASCAL/initialization/','-end');

load initializationresult.mat;

N = length(ids);
K = VOCopts.nclasses;

load trainsegment_fromdevabox.mat;

% split to 2 point of views for each class
for k = 1:K
    num(k) = length(trainseg{k});
    m(k,1) = 0;
    m(k,2) = 0;
    for i = 1:num(k)
        viewind = trainbox{k}(i,4+6*4+1);
        m(k,viewind) = m(k,viewind) + 1;
        trainsegview{k}{viewind}{m(k,viewind)} = trainseg{k}{i};
        for p = 1:6
            trainpartsegview{k}{viewind}{m(k,viewind)}{p} = trainpartseg{k}{i}{p};
        end
    end    
end

save trainsegment_fromdevabox.mat -append trainsegview trainpartsegview;

for k = 1:K
    for v = 1:2
        num2(k,v) = length(trainsegview{k}{v});
        for i = 1:num2(k,v)
            [h{k}{v}(i), w{k}{v}(i)] = size(trainsegview{k}{v}{i});
            ratio{k}{v}(i) = h{k}{v}(i)/w{k}{v}(i);
            totalpix{k}{v}(i) = h{k}{v}(i) * w{k}{v}(i);
            for p = 1:6
                [ph{k}{v}{p}(i), pw{k}{v}{p}(i)] = size(trainpartsegview{k}{v}{i}{p});
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
        stdtotalpix(k,v) = quantile(totalpix{k}{v},0.05);        

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
            stdptotalpix{p}(k,v) = quantile(totalppix{k}{v}{p},0.05);            
            
            stdpw{p}(k,v) = round(sqrt(stdptotalpix{p}(k,v)/stdpratio{p}(k,v)));
            stdph{p}(k,v) = round(sqrt(stdptotalpix{p}(k,v)*stdpratio{p}(k,v)));
        end
        
    end
end

save stdsegmentsize_fromdevabox.mat stdw stdh stdpw stdph;