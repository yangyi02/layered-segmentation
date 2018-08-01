function p = histprob(prob,X,varargin)
% function [count edges mid loc] = histcn(X, edge1, edge2, ..., edgeN)
%
% Purpose: compute n-dimensional histogram probability for new data X
%
% X: n * d
% prob: 1 * m
% center: m * d
% p: 1 * n
if ndims(X)>2
    error('histcn: X requires to be an (M x N) array of M points in R^N');
end
DEFAULT_NBINS = 32;

% Get the dimension
nd = size(X,2);
edges = varargin;
if nd<length(edges)
    nd = length(edges); % waisting CPU time warranty
else
    edges(end+1:nd) = {DEFAULT_NBINS};
end


% Allocation of array loc: index location of X in the bins
loc = zeros(size(X));
sz = zeros(1,nd);
% Loop in the dimension
for d=1:nd
    ed = edges{d};
    Xd = X(:,d);
    if isempty(ed)
        ed = DEFAULT_NBINS;
    end
    if isscalar(ed) % automatic linear subdivision
        ed = linspace(min(Xd),max(Xd),ed+1);
    end
    edges{d} = ed;
    % Call histc on this dimension
    [dummy loc(:,d)] = histc(Xd, ed, 1);
    sz(d) = length(ed)-1;
end % for-loop

% Clean
clear dummy

pr = prob(:);

[n1 n2 n3] = size(prob);

ind = loc(:,1) + (loc(:,2)-1)*n1 + (loc(:,3)-1)*(n1*n2);

p = pr(ind);
