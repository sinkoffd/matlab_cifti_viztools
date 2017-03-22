function [rgbData] = mapCiftiToColormap(cifti,threshold,varargin)
% This code takes in a filename of a cifti, a cifti object (technically a gifti object), or a
% matrix of numeric items and maps each value in the cifti to an RGB value
%
% This applies a colormap similar to HCP workbench's PSYCH colorscale. See 
% psychPOScmap() and psychNEGcmap() for further details
%
% INPUTS
%   cifti = one of the aforementioned datatypes
%   threshold = minimum value for mapping to a color. Will be applied to
%       the absolute value of the data. Items less than this will be gray.
%   varargin{1} = array of range for mapping; e.g.: [-6 6] maps our 
%     standard scale to a range of -6 to 6. If unset, will default to
%     minimum and maximum found in the data.
%
% OUTPUTS
%   rgbData is a matrix of size of the input data with an extra dimension
%   to hold the red, green, and blue values (mapped 0 to 1).
%
%% params
gray = [.5 .5 .5];
cmap_pos = psychPOScmap();
cmap_neg = psychNEGcmap();


%% load and threshold data
if (ischar(cifti))
    cifti=ciftiopen(cifti);
elseif (isnumeric(cifti)) %we're passing in a numeric matrix, make a dummy cifti
    cifti=gifti(struct('cdata',cifti)); %convert the matrix to the cdata of a gifti (cifti) object
        %this needs the struct syntax, as a matrix of all zeroes evaluates
        %to true for ishandle() -> major crashing
end %else assume it's already a loaded cifti
    
if threshold==0
    threshold=0+eps;
end

thresholdMask = abs(cifti.cdata) < threshold;


%% setup storage
rgbData=zeros(length(cifti.cdata),3);

%% map the positive colors
if (isempty(varargin))
    cmapindex_pos = linspace(0,max(cifti.cdata(:)),length(cmap_pos));
else
    scaleRange=varargin{1};
    cmapindex_pos = linspace(0,max(scaleRange),length(cmap_pos));
end

edges_pos = [ 0, mean([cmapindex_pos(2:end); cmapindex_pos(1:end-1)]), +Inf];

posMask = cifti.cdata>0;
cmapIndices_pos = discretize(cifti.cdata(posMask),edges_pos);
rgbData(posMask,:) = cmap_pos(cmapIndices_pos,:);

%% map the negative colors
if (isempty(varargin))
    cmapindex_neg = linspace(min(cifti.cdata(:)),0,length(cmap_neg));
else
    scaleRange=varargin{1};
    cmapindex_neg = linspace(min(scaleRange),0,length(cmap_neg));
end

edges_neg = [ -Inf, mean([cmapindex_neg(2:end); cmapindex_neg(1:end-1)]), 0];

negMask=cifti.cdata<0;
cmapIndices_neg = discretize(cifti.cdata(negMask),edges_neg);
rgbData(negMask,:) = cmap_neg(cmapIndices_neg,:);

%% gray-out the masked elements
rgbData(thresholdMask,:) = repmat(gray,nnz(thresholdMask),1);

end