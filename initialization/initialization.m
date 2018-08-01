clear; clc; close all;

Para = setparameter;

addpath(['D:/Research/Object Detection and Image Segmentation/' ...
    'Data Set/PASCAL_TEST/VOCdevkit/VOCcode/'],'-end');
addpath(['D:/Research/Object Detection and Image Segmentation/' ...
    'Data Set/PASCAL_TEST/VOCdevkit/VOC2009/ImageSets/Segmentation/'],'-end');
addpath(['D:/Research/Object Detection and Image Segmentation/' ...
    'My Code/PASCAL 0914/Super Pixels/' Para.superfilename],'-end');
addpath(['D:/Research/Object Detection and Image Segmentation/' ...
    'My Code/PASCAL 0914/Bias Field Learning/'],'-end');
addpath(['D:/Research/Object Detection and Image Segmentation/' ... 
    'My Code/PASCAL 0914/Initialization/'],'-end');

VOCinit;

ids = textread(sprintf(VOCopts.seg.imgsetpath,Para.segname),'%s');

cmap = VOClabelcolormap(256);

N = length(ids); % number of images

K = VOCopts.nclasses; % number of classes

clscolor = {'b','g','r','c','m','y','w','b','g','r','c','m','y','w','b','g','r','c','m','y'};

box = cell(N,K);
for k = 1:K
    load([VOCopts.classes{k},Para.boxname]);
    for i = 1:N
        box{i}{k} = boxes{i};    
    end
end
clear boxes;

objboxind = cell(1,N);
objbox = cell(1,N);
for i = 1:N
    objboxind{i} = [];
    objbox{i} = [];
    for k = 1:K
        if ~isempty(box{i}{k})
            objboxind{i} = [objboxind{i} k*ones(1,size(box{i}{k},1))];
            objbox{i} = cat(1,objbox{i},box{i}{k});
        end
    end
end

% % view detection for each image
% for i = 1:N
%     D = length(objboxind{i});
%     boxdetind{i} = ones(1,D);
%     im = imread(sprintf(VOCopts.imgpath,ids{i}));
%     figure(1);
%     showboundingbox(im,objbox{i},objboxind{i},boxdetind{i},clscolor,VOCopts);
% end

save initialresult.mat K N Para VOCopts box cmap clscolor devkitroot ids objbox objboxind;