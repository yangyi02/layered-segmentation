% use multi class segmentation with all bounding box and detection
% score at the same time;
function segmentation_show(n,objbox,objboxind,VOCopts,ids,clscolor,Para)
fprintf('image %d ',n);

% figure(1);
% clf;
% figure(2);
% clf;

bbox = objbox{n};
bboxind = objboxind{n};

load initializationresult.mat;
load biasfield_fromdevabox.mat;
% load samboxscoretoprobresult.mat;
load noclassjdet_prob.mat;
% load bgbiasfield_fromgroundtruth.mat;

%% get parameters
MaxIter = 100;
nbins{1} = 0:8:256;
nbins{2} = 0:8:256;
nbins{3} = 0:8:256;

im = imread(sprintf(VOCopts.imgpath,ids{n}));

load([ids{n} '_t=16.mat']); % load superpixels
imsuper = labels;
clear labels;

[H W c] = size(im); % get image size
WH = H*W;

M = max(imsuper(:)); % get number of superpixels

D = length(bboxind); % get number of detections

if D == 0
    indshow = zeros(H,W);
    segresult = uint8(indshow);   
%     resdir = sprintf(VOCopts.seg.clsresdir, id, 'trainval');
    resdir = sprintf(VOCopts.seg.clsresdir, id, 'bboxset');
    if ~exist(resdir, 'dir'), mkdir(resdir); end
%     respath = sprintf(VOCopts.seg.clsrespath, id, 'trainval', ids{n});
    respath = sprintf(VOCopts.seg.clsrespath, id, 'bboxset', ids{n});
    cmap = VOClabelclscolorormap(256);
    imwrite(segresult, cmap, respath);
    
%     figure(1);
%     subplot(2,5,1);
%     imagesc(im); axis image; axis off;
% 
%     figure(1);
%     saveas(gcf,['r' num2str(n)],'jpg');
    return;
end

% calculate prior probability for detections
% for d = 1:D
%     prior(d) = glmval(beta{bboxind(d)},bbox(d,30),'logit');
% end

cform = makecform('srgb2lab'); % transfer image data from RGB to Lab
Ilab = applycform(im,cform);
Ilab = double(Ilab);
Data = reshape(Ilab,WH,3);

% figure(1);
% subplot(2,5,1);
% imagesc(im); axis image; axis off;
% 
% subplot(2,5,2);
% imagesc(imsuper); axis image; axis off;
% 
boxdetind = ones(1,D); % initial solution for all detections
% 
% subplot(2,5,3);
% showboundingbox(im,bbox,bboxind,boxdetind,clscolor,VOCopts);

% get biasfield for each detection

% sort by ascending
[segscoresort,sortind] = sort(bbox(:,30),'descend');

leftprob = ones(H,W);

for d = 1:D
    lef = round(bbox(sortind(d),1)); top = round(bbox(sortind(d),2)); 
    rig = round(bbox(sortind(d),3)); bot = round(bbox(sortind(d),4));

    h = bot - top + 1; w = rig - lef + 1;

    lef0 = lef - round(w/2); top0 = top - round(h/2);
    rig0 = rig + round(w/2); bot0 = bot + round(h/2);
    
    h0 = bot0 - top0 + 1; w0 = rig0 - lef0 + 1;
    
    biasfield = fgbias{bboxind(sortind(d))}{bbox(sortind(d),4+6*4+1)};

    biasfield = imresize(biasfield,[h0,w0],'bilinear');

    bf = ones(H,W) * noclassjdet_probs(bboxind(sortind(d)));
    % refine bias field for outside bounding box
    
    tmp = biasfield(max(top0,1)-top0+1:min(bot0,H)-top0+1,max(lef0,1)-lef0+1:min(rig0,W)-lef0+1);
    
    bf(max(top0,1):min(bot0,H),max(lef0,1):min(rig0,W)) = tmp;
    
    % use part bias field
    for p = 1:6
        lef = round(bbox(sortind(d),4+(p-1)*4+1)); top = round(bbox(sortind(d),4+(p-1)*4+2)); 
        rig = round(bbox(sortind(d),4+(p-1)*4+3)); bot = round(bbox(sortind(d),4+(p-1)*4+4));
        
        h = bot - top + 1; w = rig - lef + 1;
        
        pbiasfield = pfgbias{bboxind(sortind(d))}{bbox(sortind(d),4+6*4+1)}{p};
        pbiasfield = imresize(pbiasfield,[h,w],'bilinear');
        
        tmp = pbiasfield(max(top,1)-top+1:min(bot,H)-top+1,max(lef,1)-lef+1:min(rig,W)-lef+1);
        
        bf(max(top,1):min(bot,H),max(lef,1):min(rig,W)) = tmp;
    end
    
    biasfield = leftprob .* bf;
    
    leftprob = leftprob - biasfield;
    
    biasfieldvec(sortind(d),:) = reshape(biasfield,WH,1);
end

% initialize segmentation
for d = 1:D
%     Pr(d,:) = biasfieldvec(d,:) * prior(d);
    Pr(d,:) = biasfieldvec(d,:);
end
if D > 1
    tmpPr = 1 - sum(Pr);
else
    tmpPr = 1 - Pr;
end
Pr(D+1,:) = tmpPr;
% bgbiasfield = imresize(bgbias,[H,W],'bilinear');
% biasfieldvec(D+1,:) = reshape(bgbiasfield,WH,1);
% Pr(D+1,:) = biasfieldvec(D+1,:);
[maxPr ind] = max(Pr);

for iter = 1:MaxIter
%     if iter + 3 > 10
%         break;
%     end

    % M Step
    for d = 1:D+1
        objsegind{d} = ind == d;
        data{d} = Data(objsegind{d},:);
        numofdata(d) = size(data{d},1);
        if ~isempty(data{d})
            [datahist{d},dataedge{d}] = histcn(data{d},nbins{1},nbins{2},nbins{3});
            prob{d} = datahist{d} / numofdata(d);
        else
            prob{d} = zeros(length(nbins{1}-1),length(nbins{2}-1),length(nbins{3}-1));
            if d == D+1
                [datahist{d},dataedge{d}] = histcn(Data,nbins{1},nbins{2},nbins{3});
                prob{d} = datahist{d} / numofdata(d);
            end
        end
    end
    
    % E step
    Pr = ones(D+1,WH);

    sumbiasfield = zeros(1,WH);
    for d = 1:D
        if boxdetind(d) == 1
            Pr(d,:) = biasfieldvec(d,:) .* histprob(prob{d},Data,nbins{1},nbins{2},nbins{3})';
            sumbiasfield = sumbiasfield + biasfieldvec(d,:);
        else
            Pr(d,:) = zeros(1,WH);
        end
    end
    
    Pr(D+1,:) = histprob(prob{D+1},Data,nbins{1},nbins{2},nbins{3})' .* (1 - sumbiasfield);
%     Pr(D+1,:) = histprob(prob{D+1},Data,nbins{1},nbins{2},nbins{3})' .* biasfieldvec(D+1,:);
    
%     if iter > 1
%         Pr(D+1,:) = histprob(prob{D+1},Data,nbins{1},nbins{2},nbins{3})' .* (1 - sumbiasfield);
%     end
    
    % make sure in Pr, in negative number
    Pr = Pr.*(Pr>=0);
    logPr = log(Pr + eps);

    ind_old = ind;

    for m = 1:M
        indm = (imsuper == m);
        indm = reshape(indm,1,WH);
        [maxsumlogPr indsuper(m)] = max(sum(logPr(:,indm),2));
%         [probmax,ind] = max(Pr);
        ind(indm) = indsuper(m);
    end

    diffnum = sum(ind_old~=ind);
    fprintf('%d ',diffnum);
    
    % reestimate detection correctness
    for d = 1:D
        objsegind{d} = ind == d;
        if sum(objsegind{d}) == 0
            boxdetind(d) = 0;
            continue;
        else
            boxdetind(d) = 1;
            continue;
        end
%         Prdety(d) = objsegind{d} * log(biasfieldvec(d,:))' +
%         log(prior(d));
%         Prdetn(d) = sum(objsegind{d} * log(eps)) + log(1-prior(d));
%         boxdetind(d) = Prdety(d) > Prdetn(d);
    end
    
%     subplot(2,5,iter+3);
%     showboundingbox(im,bbox,bboxind,boxdetind,clscolor,VOCopts);
%     imagesc(reshape(ind,H,W)); axis image; axis off; drawnow;
%     title([num2str(diffnum) ' pixels']);
    
    if diffnum == 0
        break;
    end
end
fprintf('\n');

% figure(2);
% subplot(121);
% indshow = reshape(ind,H,W);
% imagesc(indshow); axis image; axis off;
% subplot(122);
% tmpind = zeros(H,W);
for d = 1:D
    indd = ind == d;
    tmpind(indd) = bboxind(d);
end
indd = ind == D+1;
tmpind(indd) = 0;
indshow = reshape(tmpind,H,W);
% imagesc(indshow); axis image; axis off;

segresult = uint8(indshow);   
% resdir = sprintf(VOCopts.seg.clsresdir, id, 'trainval');
resdir = sprintf(VOCopts.seg.clsresdir, id, 'bboxset');
if ~exist(resdir, 'dir'), mkdir(resdir); end
% respath = sprintf(VOCopts.seg.clsrespath, id, 'trainval', ids{n});
respath = sprintf(VOCopts.seg.clsrespath, id, 'bboxset', ids{n});
cmap = VOClabelclscolorormap(256);
imwrite(segresult, cmap, respath);

% figure(1);
% saveas(gcf,['r' num2str(n)],'jpg');

% figure(2);
% saveas(gcf,['s' num2str(n)],'jpg');

% figure(3);
% saveas(gcf,['t' num2str(n)],'jpg');