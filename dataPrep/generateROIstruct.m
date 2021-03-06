function [roiStruct] = generateROIstruct()
% GENERATECORRMATSTRUCT creates an empty structure-array object for 
% plotting correlation matrices as ROIs on a gifti surface.
%
%
roiStruct = struct(...
    'ParcelNumber',[],...
    'ParcelName','',...
    'Network','',...
    'R',[],...
    'G',[],...
    'B',[],...
    'Alpha',[],...
    'X',[],...,
    'Y',[],...,
    'Z',[]...
    );


end