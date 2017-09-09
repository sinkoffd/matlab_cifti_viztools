function [mappedData]=mapPconnToROI(pconn,roiStruct,threshold)
% MAPPCONNTOROI creates a struct of data for generating vector plots
%
% INPUTS:
%   pconn = either a path to the datafile or a loaded object
%   roiStruct = a filled datastruct containing the ROI information
%   threshold = the minimum value for which elements will be available for
%       display. Generally, this is set to 0.
%
%   Note, this object can get large depending on the size of your
%   correlation matrix.

%% Load data
if ~isa(pconn,'gifti')
    pconn=ciftiopen(pconn);
    corrmat=pconn.cdata;
else
    corrmat=pconn.cdata;    
end

if threshold == 0
    threshold = 0 + eps;
end


%% setup storage
numVectors=(length(corrmat).^2-length(corrmat))/2; % (n^2-n)/2 = n(n-1)/2
parcelPair=zeros(numVectors,2);
dataValue=zeros(numVectors,1);

%% prep data for vectors
% iterate through parcels on the upper triangle
% this loop will iterate along the upper triangle w/o diagonal.
counter=0;
for i=1:length(corrmat)
    for j=i+1:length(corrmat)
        %check if the value exceeds the threshold
        if abs(corrmat(i,j)) >= threshold
            counter=counter+1;
            parcelPair(counter,:)=[roiStruct(i).ParcelNumber, roiStruct(j).ParcelNumber];
            dataValue(counter) = corrmat(i,j);
        else %do nada
            
        end
    end
end

%% delete unused elements
parcelPair(counter+1:end,:)=[];
dataValue(counter+1:end)=[];

%% Create and fill struct
mappedData=struct('parcelPair',parcelPair,'dataValue',dataValue,'corrmat',corrmat);

end


