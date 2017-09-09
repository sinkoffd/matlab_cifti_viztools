function [hCorrFig,hSurfFig] = plotCorrmat(mappedData,surface,roiStruct,threshold,range,numVec)
% PLOTCORRMAT plots a correlation matrix and allows selection of a specific
% region to plot as ROIs and vectors on a surface
%
% INPUTS
%   mappedData = output variable from mapPconnToROI.m
%   surface = the combined L and R gifti surface file or object from
%       combineLRsurf.m
%   roistruct = a filled structure of ROI data. A template can be generated
%       by generateROIstruct.m
%   threshold = minimum display threshold
%   range = the range to which to scale coloring. Leave empty for
%      autoscaling
%   numVec = number of initial parcel-pair vectors to draw. Plots the top N
%       from abs(data)
%
%
%
% TODO:
%   1) Add in ability to underlay data onto the cortical surface
%
%
%% load data and set parameters
if ~(isa(surface,'gifti'))
    surface=gifti(surface);
end

if nargin<4
    threshold=0+eps;
end

if nargin<5
    range=[];
end

if isempty(range)
    range=[min(mappedData.dataValue(:)) max(mappedData.dataValue(:))];
end

sphereRadius=4;
lineThickness=8;


%% setup color mapping for correlation matrix
%remove nans if present (generally on center of symmetric matrix)
mappedData.corrmat(isnan(mappedData.corrmat))=0;
corrmatRGB = mapCiftiToColormap(mappedData.corrmat,threshold,range); %convert data to RGB values
dataRGB_mat=reshape(corrmatRGB,size(mappedData.corrmat,1),size(mappedData.corrmat,2),3); %reshape into a nXmX3 matrix

%% plot the correlation matrix
hCorrFig = figure();
hCorr = image(dataRGB_mat);

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
clear pad_up pad_down endpoints;

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
    text(centerPoints(i),length(hCorr.CData)+4,netNames{i},'HorizontalAlignment','right','Rotation',45,'FontWeight','Bold');%,'FontSize',15);
end


%% Plot the glass brain and base surface
hSurfFig=figure('Color',[0 0 0]);
hCortex=plot(surface);
hCortex.FaceAlpha=0.5;
hCortex.FaceColor=[.5 .5 .5];
hold on;

%% Prepare and plot vectors and rois
%setup colors
vectorRGB=mapCiftiToColormap(mappedData.dataValue,threshold,range);

%find the top N values
[~,ids]=sort(abs(mappedData.dataValue),'descend');
vectorMask=zeros(size(mappedData.dataValue));
vectorMask(ids(1:numVec))=1;
vectorMask=logical(vectorMask);

%extract data for initial plot
initialParings=mappedData.parcelPair(vectorMask,:);
initialLineColors=vectorRGB(vectorMask,:);

%setup a generic sphere
[sphereX,sphereY,sphereZ]=sphere;

%work by pairs of parcels
for i=1:size(initialParings,1)
    %plot ROI 1
    roi1=initialParings(i,1);
    roi1Color=[roiStruct(roi1).R roiStruct(roi1).G roiStruct(roi1).B];
    h = surf(...
        sphereRadius*sphereX + roiStruct(roi1).X,...
        sphereRadius*sphereY + roiStruct(roi1).Y,...
        sphereRadius*sphereZ + roiStruct(roi1).Z,...
        'FaceLighting','gouraud',...
        'FaceColor',roi1Color,...
        'LineStyle','none'...
        );
    h.UserData='ROI';
    
    %plot ROI 2
    roi2=initialParings(i,2);
    roi2Color=[roiStruct(roi2).R roiStruct(roi2).G roiStruct(roi2).B];
    h = surf(...
        sphereRadius*sphereX + roiStruct(roi2).X,...
        sphereRadius*sphereY + roiStruct(roi2).Y,...
        sphereRadius*sphereZ + roiStruct(roi2).Z,...
        'FaceLighting','gouraud',...
        'FaceColor',roi2Color,...
        'LineStyle','none'...
        );
    h.UserData='ROI';
    
    %plot connecting vector
    h=line(...
        [roiStruct(roi1).X, roiStruct(roi2).X],...
        [roiStruct(roi1).Y, roiStruct(roi2).Y],...
        [roiStruct(roi1).Z, roiStruct(roi2).Z],...
        'LineWidth',lineThickness,...   %TODO make this scale based on range of displayed elements
        'Color',initialLineColors(i,:)...
        );
    h.UserData='Line';
    
    
    
end

%% add callback to corrmat
hCorr.ButtonDownFcn={@corrmatCallback,hSurfFig,mappedData,roiStruct,threshold,range}; %TODO DLS: adjust variables here

%% add a colorscale window
figure();
cmap = [psychNEGcmap() ; psychPOScmap()];
colormap(cmap);
image([size(cmap,1):-1:1]'); %#ok<NBRAK>
hax=gca;
hax.XTick=[];
hax.YTick=[hax.YLim(1) mean(hax.YLim) hax.YLim(2)];
hax.YTickLabel=[range(2) 0 range(1)];

end

function corrmatCallback(hobj,hevent,hSurfFig,mappedData,roiStruct,threshold,range)  %#ok<INUSL>
%% grab selected region
selectedRegion = round(getrect);

%% error-check the selection
maxsize=size(hobj.CData);
%x axis positive
if (selectedRegion(1)+selectedRegion(3)>maxsize(1))
    selectedRegion(3) = maxsize(1)-selectedRegion(1);
end
%y axis positive
if (selectedRegion(2)+selectedRegion(4)>maxsize(2))
    selectedRegion(4) = maxsize(2)-selectedRegion(2);
end
%x axis negative
if (selectedRegion(1) < 1)
    selectedRegion(3)=selectedRegion(3)+selectedRegion(1); %sr(1) is negative in this condition
    selectedRegion(1)=1;
end
%y axis negative
if (selectedRegion(2) < 1)
    selectedRegion(4)=selectedRegion(4)+selectedRegion(2); %sr(2) is negative in this condition
    selectedRegion(2)=1;
end


%% update vector plot
updateROIs(hSurfFig,mappedData,roiStruct,selectedRegion,threshold,range);


end

function updateROIs(hSurfFig,mappedData,roiStruct,selectedRegion,threshold,range)
%% basic parameters
sphereRadius=4;
lineThickness=8;

%% delete the old graph's lines and spheres
figure(hSurfFig);
delete(findobj(hSurfFig,'Type','Line'));
delete(findobj(hSurfFig,'Type','Surface'));

%% remap the datastruct to the selected region
%new storage
numVectors = selectedRegion(3)*selectedRegion(4);
parcelPair=zeros(numVectors,2);
dataValue=zeros(numVectors,1);

%grab elements
parcelNumbers=[roiStruct.ParcelNumber];
counter=0;
for i=selectedRegion(1):selectedRegion(1)+selectedRegion(3)-1
    for j=selectedRegion(2):selectedRegion(2)+selectedRegion(4)-1
        counter=counter+1;
        parcelPair(counter,:)=[roiStruct(i).ParcelNumber, roiStruct(j).ParcelNumber];
        dataValue(counter) = mappedData.corrmat(i,j);
    end
end

%remove nans if present
nanMask=isnan(dataValue);
parcelPair(nanMask,:)=[];
dataValue(nanMask)=[];

%% generate coloring
vectorRGB=mapCiftiToColormap(dataValue,threshold,range);

%% plot vectors and ROIs
hold on;

for i=1:size(parcelPair,1)
    %% find ROIs
    roi1=parcelPair(i,1);
    roi2=parcelPair(i,2);
    
    roi1=find(parcelNumbers==roi1);
    roi2=find(parcelNumbers==roi2);
    %% plot lines
    h=line(...
        [roiStruct(roi1).X, roiStruct(roi2).X],...
        [roiStruct(roi1).Y, roiStruct(roi2).Y],...
        [roiStruct(roi1).Z, roiStruct(roi2).Z],...
        'LineWidth',lineThickness,... %   %TODO make this scale based on range of displayed elements
        'Color',vectorRGB(i,:));
    
    h.UserData='Line';
    
end


%% plot unique ROIs
%generic sphere
[sphereX,sphereY,sphereZ]=sphere;
sphereX = sphereX*sphereRadius;
sphereY = sphereY*sphereRadius;
sphereZ = sphereZ*sphereRadius;

uniqueROIs = unique(parcelPair(:));
for i=1:length(uniqueROIs)
    %% find the unique ROI in the table
    roi1=uniqueROIs(i);
    ro1_rownumber=find(parcelNumbers==roi1);
    
    %% plot it
    roi1Color=[roiStruct(ro1_rownumber).R, roiStruct(ro1_rownumber).G, roiStruct(ro1_rownumber).B];
    surf(   sphereX + roiStruct(ro1_rownumber).X,...
        sphereY + roiStruct(ro1_rownumber).Y,...
        sphereZ + roiStruct(ro1_rownumber).Z,...
        'FaceColor',roi1Color,...
        'LineStyle','none'...
        );
end
hold off


end



