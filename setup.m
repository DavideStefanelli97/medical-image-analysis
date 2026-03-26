function setup()
% SETUP  Initialize paths for the Medical Image Analysis project.
%   Adds all library and script directories to the MATLAB path and
%   creates a PROJECT_ROOT variable in the caller's workspace for
%   portable file references.
%
%   Usage:
%     setup()              % from the project root
%     run('path/to/setup.m')  % from anywhere
%
%   After calling setup, use PROJECT_ROOT to reference data files:
%     load(fullfile(PROJECT_ROOT, 'data', 'patient5.mat'));

    projectRoot = fileparts(mfilename('fullpath'));

    addpath(genpath(fullfile(projectRoot, 'lib')));
    addpath(genpath(fullfile(projectRoot, 'scripts')));

    % Check for iso2mesh (required only by seg_left_atrium_3d)
    if isempty(which('binsurface'))
        warning('setup:iso2mesh', ...
            ['iso2mesh toolbox not found on path. It is required only by\n' ...
             'seg_left_atrium_3d.m. Download from: http://iso2mesh.sf.net']);
    end

    assignin('caller', 'PROJECT_ROOT', projectRoot);
    fprintf('Project root: %s\n', projectRoot);
end
