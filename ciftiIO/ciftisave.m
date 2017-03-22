function [ output_args ] = ciftisave(cifti,filename)

% CIFTISAVE(CIFTI,FILENAME)
%
% Save a CIFTI file as a GIFTI external binary and then convert it to CIFTI
%
% CIFTI is the cifti-formatted file in the Matlab workspace
% FILENAME is the string containing the file name to save as
% WBCOMMAND is string containing the Workbench command.  
%   (Necessary for the intermediate step of conversion to gifti.
%    Matlab must be able to find this when it executes a 'system' command).
% VERBOSE (optional; default is off): Set to 1 for more verbose output.

% Default is VERBOSE=0 (OFF)
if (nargin < 3) 
	verbose = 0;
else
    verbose = 1;
end

[found,wbcommand] = system('which wb_command');

if (~found)
    wbcommand = strcat(wbcommand);
else
    wbcommand = 'wb_command';
end

tstart=tic;

% Do work
% Note that 'save' is an "overloaded" function for objects
% of class 'gifti', and as such its behavior is defined by the
% 'gifti' class implementation
save(cifti,[filename '.gii'],'ExternalFileBinary')
system([wbcommand ' -cifti-convert -from-gifti-ext ' filename '.gii ' filename]);

if (verbose)
  fprintf(1,'%s: Elapsed time is %.2f seconds\n',filename,toc(tstart));
end

% Clean-up
delete([filename '.gii'],[filename '.dat']);
