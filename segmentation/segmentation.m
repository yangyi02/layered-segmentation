% use multi class segmentation with all bounding box and detection
% score at the same time;
function segresult = segmentation(n,fgbias,pfgbias,bbox,bboxind,ids,prob_nodet,VOCopts,Para)

fprintf('image %d ',n);

%% get parameters
im = imread(sprintf(VOCopts.imgpath,ids));

load([ids Para.supername '.mat']); % load superpixels
imsuper = labels; clear labels;

[H W c] = size(im); % get image size
WH = H*W;

M = max(imsuper(:)); % get number of superpixels

D = length(bboxind); % get number of detections

if D == 0
    segresult = zeros(H,W);
    return;
end

cform = makecform('srgb2lab'); % transfer image data from RGB to Lab
Ilab = applycform(im,cform);
Ilab = double(Ilab);
imData = reshape(Ilab,WH,3);

% set initial solution for iteration
boxdetind = ones(1,D); % initial solution for all detections

% get biasfield for each detection

% sort biasfield by ascending, this method is called compositing
[segscoresort, sortind] = sort(bbox(:,30),'descend');

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

    % first set bias field to be no detection field
    bf = ones(H,W) * prob_nodet(bboxind(sortind(d)));
    
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
    
    % get the bias field vector
    biasfieldvec(sortind(d),:) = reshape(biasfield,WH,1);
end
biasfieldvec(D+1,:) = reshape(leftprob,WH,1); % background bias field

% initialize segmentation simply from bias field
[maxPr, ind] = max(biasfieldvec);

% start iteration
for iter = 1:Para.MaxIter
    % recalculating color model
    for d = 1:D+1
        objsegind{d} = ind == d;
        data{d} = imData(objsegind{d},:);
        numofdata(d) = size(data{d},1);
        if ~isempty(data{d})
            [datahist{d},dataedge{d}] = histcn(data{d},Para.nbins{1},Para.nbins{2},Para.nbins{3});
            prob{d} = datahist{d} / numofdata(d);
        else
            prob{d} = zeros(length(Para.nbins{1}-1),length(Para.nbins{2}-1),length(Para.nbins{3}-1));
            if d == D+1
                [datahist{d},dataedge{d}] = histcn(imData,Para.nbins{1},Para.nbins{2},Para.nbins{3});
                prob{d} = datahist{d} / size(imData,1);
            end
        end
    end
    
    % resegmentation
    for d = 1:D
        if boxdetind(d) == 1
            Pr(d,:) = biasfieldvec(d,:) .* histprob(prob{d},imData,Para.nbins{1},Para.nbins{2},Para.nbins{3})';
        else
            Pr(d,:) = zeros(1,WH);
        end
    end
    Pr(D+1,:) = biasfieldvec(D+1,:) .* histprob(prob{D+1},imData,Para.nbins{1},Para.nbins{2},Para.nbins{3})';
    
    % make sure in Pr, in negative number
    a = Pr(:) < 0;
    if max(a)==1
        break;
    end
%     Pr = Pr.*(Pr>=0);
    logPr = log(Pr+eps);
    
    ind_old = ind;

    for m = 1:M
        indm = (imsuper == m);
        indm = reshape(indm,1,WH);
        [maxsumlogPr, ind(indm)] = max(sum(logPr(:,indm),2));
    end

    diffnum = sum(ind_old~=ind);
    fprintf('%d ',diffnum);
    
    % reestimate detection correctness
    for d = 1:D
        objsegind{d} = ind == d;
        if sum(objsegind{d}) == 0
            boxdetind(d) = 0;
        else
            boxdetind(d) = 1;
        end
    end
    
    if diffnum == 0
        break;
    end
end
fprintf('\n');

for d = 1:D
    indd = ind == d;
    tmpind(indd) = bboxind(d);
end
indd = ind == D+1;
tmpind(indd) = 0;
segresult = reshape(tmpind,H,W);