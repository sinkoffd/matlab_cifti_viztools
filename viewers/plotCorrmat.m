function [hCorrFig,hSurfFig] = plotCorrmat(data,surface,roiStruct,threshold,range)
% PLOTCORRMAT plots a correlation matrix and allows selection of a specific
% region to plot as ROIs and vectors on a surface
%   
%

%% load data and set parameters
if isa(data,'gifti')
    data=data.cdata;
elseif ischar(data)
    data=ciftiopen(data);
    data=data.cdata;
elseif ~isnumeric(data)
    error('data need to be numeric, a loaded cifti (gifti), or a path to a cifti');
end

if ~(isa(surface,'gifti'))
    surface=gifti(surface);
end

if nargin<4
    threshold=0;
end

if nargin<5
    range=[];
end

if isempty(range)
    range=[min(data(:)) max(data(:))];
end
    

%% setup color mapping
%remove nans if present (generally on center of symmetric matrix)
data(isnan(data))=0;
dataRGB = mapCiftiToColormap(data,threshold,range); %convert data to RGB values
dataRGB=reshape(dataRGB,size(data,1),size(data,2),3); %reshape into a nXmX3 matrix

%% plot the correlation matrix
hCorrFig = figure();
hcorr = image(dataRGB);

%% label the correlation matrix by network
% this is easier in more modern versions of MATLAB using tables. Switched
% to structs for backwards compatibility.
netNames=cell(0);
endpoints=[];
counter=1;

%extract names and where names differ
for i=2:length(roiStruct)
    if strcmpi(roiStruct(i).Network,roiStruct(i-1).Network) %if current is the same as previous
        %do nothing
    else %a change happened!
        netNames{counter}=roiStruct(i-1).Network; %store the last one
        endpoints(counter)=i-1; %#ok<AGROW>
        counter=counter+1;
    end
end


%draw lines
for i=1:length(endpoints)-1
    hline_new(endpoints(i)+.5,'r',1);
    vline_new(endpoints(i)+.5,'r',1);
end

%find centerpoints of each block
pad_up=[1 endpoints];
pad_down=[endpoints length(roiStruct)];
centerPoints=pad_up + (pad_down - pad_up)/2 - 0.5;
centerPoints(end)=[];
clear pad_up pad_down;

%set params
haxes=gca;
haxes.XTick=centerPoints;
haxes.YTick=centerPoints;
haxes.XTickLabel='';
haxes.YTickLabel='';
haxes.TickDir='out';

for i=1:length(centerPoints)
    %% y-axis labels
    text(0-2,centerPoints(i),netNames{i},'HorizontalAlignment','right','FontWeight','Bold');%,'FontSize',15);
    
    %% x-axis labels
    text(centerPoints(i),length(hcorr.CData)+4,netNames{i},'HorizontalAlignment','right','Rotation',45,'FontWeight','Bold');%,'FontSize',15);
end


end







