function ctx = ProjectContext(action, varargin)
% ProjectContext - Single source of truth for project/run paths (no signature changes needed)
% Usage:
%   ProjectContext('init', projectRoot)
%   ctx = ProjectContext('get')
%
% Creates a versioned run folder:
%   <projectRoot>/results/result_yy-mm-dd HH-MM/
% Then snapshots templates into that folder so writes happen on copied Excel files.

persistent C

if nargin == 0
    action = 'get';
end

switch lower(action)
    case 'init'
        projectRoot = '';
        if ~isempty(varargin)
            projectRoot = varargin{1};
        end

        if isempty(projectRoot)
            % Fallback: this file is in <root>/src/single-objective/
            thisFile = mfilename('fullpath');
            here     = fileparts(thisFile);           % .../src/single-objective
            projectRoot = fileparts(fileparts(here)); % .../<root>
        end

        % Requested format:
        % <Root Dir>/results/result_yy-mm-dd HH-MM
        stamp       = datestr(now, 'yy-mm-dd HH-MM');
        resultsBase = fullfile(projectRoot, 'results');
        resultsRoot = fullfile(resultsBase, ['result_' stamp]);

        % Locate template root (support both layouts)
        t1 = fullfile(projectRoot, 'src', 'results_template');
        t2 = fullfile(projectRoot, 'src', 'results', 'results_template');

        if exist(t1, 'dir') == 7
            templateRoot = t1;
        elseif exist(t2, 'dir') == 7
            templateRoot = t2;
        else
            error('Template root not found. Expected: %s OR %s', t1, t2);
        end

        % Ensure directories exist
        if exist(resultsBase, 'dir') ~= 7
            mkdir(resultsBase);
        end
        if exist(resultsRoot, 'dir') ~= 7
            mkdir(resultsRoot);
        end

        % Snapshot templates into the versioned run folder
        % This creates: resultsRoot/CEC####/##Dim.xlsx (and other template assets)
        copyfile(templateRoot, resultsRoot);

        C.projectRoot  = projectRoot;
        C.templateRoot = templateRoot;
        C.resultsRoot  = resultsRoot;
        C.stamp        = stamp;

        ctx = C;

    case 'get'
        if isempty(C) || ~isfield(C, 'resultsRoot') || isempty(C.resultsRoot)
            % Lazy init if called before main
            ctx = ProjectContext('init', '');
            return;
        end
        ctx = C;

    otherwise
        error('Unknown action: %s', action);
end
end
