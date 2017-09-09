function [newLRsurf] = combineLRsurf(sourceL,sourceR,offset,outputname)
% COMBINELRSURF combines two gifti hemispheres into a single gifti file
% This tool is used for preparing surface files for use with the
% matlab-cifti-viewer package.
%
% Data conventions and caution:
%   Left hemisphere preceeds right hemisphere (for HCP grayordinates).
%       Your data may be organized differently. Messing this up may lead to
%       a silent error where data will incorrectly mapped. Consider
%       yourself warned.
%
% INPUTS
%   sourceL = loaded gifti object or path to the left hemisphere gifti
%   sourceR = loaded gifti object or path to the right hemisphere gifti
%
% OPTIONAL:
%   offset = amount by which to separate the two hemispheres. For gifti
%       files originating from the HCP, 40 is a good starting point.
%   outputname = path to where the combined surface should be saved
%
% OUTPUTS:
% newLRsurf is a gifti object containing the combined left and right
%   hemisphere object. Can be saved to disk using
%   save(newLRsurf,'filename') or with the option above


%% load files
if ~isa(sourceL,'gifti')
    sourceL=gifti(sourceL);
end
if ~isa(sourceR,'gifti')
    sourceR=gifti(sourceR);
end

%% combine LR surfs
verticesL = length(sourceL.vertices); %grab number of vertices in the L surface
sourceR.faces=sourceR.faces+verticesL; %scalar shift of face vertex numbers

newLRsurf = sourceL; %start by copying the L surface
newLRsurf.faces=[newLRsurf.faces ; sourceR.faces]; %combine faces
newLRsurf.vertices=[newLRsurf.vertices; sourceR.vertices]; %combine vertices


%% offset surfaces
if nargin > 2
    newLRsurf.vertices(1:verticesL,:) = newLRsurf.vertices(1:verticesL,:) + repmat([-offset 0 0],verticesL,1);
    newLRsurf.vertices(verticesL+1:end,:) = newLRsurf.vertices(verticesL+1:end,:) + repmat([offset 0 0],length(sourceR.vertices),1);
end

%% save?
if nargin > 3
    save(newLRsurf,outputname);
end

end