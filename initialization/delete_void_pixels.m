clear; clc;

load initialresult.mat;

% first set void pixel to its nearest object
for i = 1:N
    im = imread(sprintf(VOCopts.imgpath,ids{i}));
    imsegcls = double(imread(sprintf(VOCopts.seg.clsimgpath,ids{i})));
    imsegobj = double(imread(sprintf(VOCopts.seg.instimgpath,ids{i})));
    
    [H W] = size(imsegcls);

    subplot(221); imagesc(imsegcls); axis image;
    subplot(222); imagesc(imsegobj); axis image;
    
    % let 255 be the nearest object class
    ind_255 = find(imsegcls == 255);
    flag = 1;
    if length(ind_255) / H / W > 0.1
        % there are too many void pixels, need to take care
        user_entry = input('Do you want delete void? Y/N [Y]: ', 's');
        if user_entry == 'n' || user_entry == 'N'
            imsegcls(ind_255) = 0;
            imsegobj(ind_255) = 0;
            flag = 0;
        end
    end
    if flag == 1
        imsegcls(ind_255) = 0;
        imsegobj(ind_255) = 0;
            
        [D,L] = bwdist(imsegcls);
        imsegcls(ind_255) = imsegcls(L(ind_255));
        
        [D,L] = bwdist(imsegobj);
        imsegobj(ind_255) = imsegobj(L(ind_255));
    end
    subplot(223); imagesc(imsegcls); axis image;
    subplot(224); imagesc(imsegobj); axis image;
    
    cmap = VOClabelcolormap(256);
    
    resdir = sprintf('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/SegmentationClass_Novoid/');
    if ~exist(resdir, 'dir'), mkdir(resdir); end
    respath = sprintf('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/SegmentationClass_Novoid/%s.png', ids{i});
    imwrite(uint8(imsegcls), cmap, respath);
    
    resdir = sprintf('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/SegmentationObject_Novoid/');
    if ~exist(resdir, 'dir'), mkdir(resdir); end
    respath = sprintf('D:/Research/Object Detection and Image Segmentation/Data Set/PASCAL/VOCdevkit/VOC2009/SegmentationObject_Novoid/%s.png', ids{i});
    imwrite(uint8(imsegobj), cmap, respath);    
    
    fprintf('finish image %d\n',i);    
end
