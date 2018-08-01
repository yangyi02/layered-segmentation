clear; clc;

load initialresult.mat;
load biasfield_fromdevabox.mat;
load noclassjdet_prob.mat;

resdir = sprintf(VOCopts.seg.clsresdir, Para.id, Para.segname);
if ~exist(resdir, 'dir'), mkdir(resdir); end
    
for n = 1:N
    segresult = segmentation(n,fgbias,pfgbias,objbox{n},objboxind{n},ids{n},noclassjdet_probs,VOCopts,Para);
    respath = sprintf(VOCopts.seg.clsrespath, Para.id, Para.segname, ids{n});
    imwrite(uint8(segresult), cmap, respath);
end

VOCopts.testset = Para.segname;

accuracies = VOCevalseg(VOCopts, Para.id);

save(['segresult' Para.boxname '.mat'],'accuracies');