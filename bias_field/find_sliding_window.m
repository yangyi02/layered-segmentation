function [Islid left top right down] = findslidingwindow(Imask)
% Edited on 5/22/2009
%
% Find the sliding window containing object part from the segment image
% Imask is assumed to be binary matrix with 1 repesenting object

[h w] = size(Imask);

% find the leftmost and rightmost
I = reshape(Imask,w*h,1);

ind = find(I == 1);

left = ind(1);
left = floor((left-1)/h) + 1;

right = ind(end);
right = floor((right-1)/h) + 1;

% find the topmost and bottommost
I = reshape(Imask',w*h,1);

ind = find(I == 1);

top = ind(1);
top = floor((top-1)/w) + 1;

down = ind(end);
down = floor((down-1)/w) + 1;

% cut the slinding window out
Islid = Imask(top:down,left:right);