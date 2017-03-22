function [figureHandle] = plotCifti(data,surface,threshold,range,figureHandle)
% PLOTCIFTI plots data within certain types of ciftis to the desired surface
%
% Generally, this will work with dlabel.nii or dscalar.nii files. Note that
% only the values and not the text labels from the dlabel.nii file will be
% loaded.
%
% Inspiration for this plotting code come's from Guillaume Flandin's gifti
% plotting code.
%
% The number of vertices should match for both the data and the surface. If
%  the data have more vertices than surface, the vertex mapping will be
%  truncated at the length of the surface. For ciftis from the HCP, this
%  generally isn't an issue as grayordinates are stored as left cortex
%  vertices, right cortex vertices, and then volumetric data.
%
% INPUTS
%   data = can be either a loaded cifti (a gifti object) or a path to the
%       desired cifti.
%   surface = can be either a loaded gifti surface or a path to the desired
%      gifti.
%   threshold = numeric value corresponding to the minimum value you'd like
%       scaled to the colormap
%   range = range to which you'd like the colormap scaled. Pass an empty
%       element to default to the maximum and minimum values in the data.
%       E.G.: []
%
% OPTIONAL
%   figureHandle = handle to an existing figure. Can be useful for
%       overlaying data.


%% load data and surface
if ischar(data)
    data=ciftiopen(data);
elseif ~isa(data,'gifti')
    error('input data not of the correct type');
end

if ischar(data)
    surface=gifti(surface);
elseif ~isa(surface,'gifti');
    error('input surface must be a gifti object or a path to a gifti');
end

%% get or create handle to figure
if nargin < 5
    figureHandle=figure();
end

%% setup the plot
figure(figureHandle);
axisHandle=gca();
patchHandle=patch('Vertices',surface.vertices,'Faces',surface.faces,'FaceColor',[.5 .5 .5],'EdgeColor','none','CreateFcn',@cameramenu);
axis(axisHandle,'equal');
axis(axisHandle,'off');
camlight;
camlight(-80,-10);
lighting gouraud;
camproj(axisHandle,'Perspective')
axisHandle.CameraViewAngleMode='manual';
material dull;

%% overlay the data
if isempty(range)
    range=[max(data.cdata(:)) min(data.cdata(:))];
end

rgbMapping=mapCiftiToColormap(data,threshold,range);
patchHandle.FaceVertexCData=rgbMapping(1:length(surface.vertices),:);
patchHandle.FaceColor='interp';


end