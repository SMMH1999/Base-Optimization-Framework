function ctx = ProjectContext(action, varargin)
    % ProjectContext - single source of truth for project paths (no signature changes needed)
    % Usage:
    %   ProjectContext('init', projectRoot)
    %   ctx = ProjectContext('get')

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

            % Version folder format requested by user:
            % <Root Dir>/results/result_yy-mm-dd HH-MM
            stamp = datestr(now,'yy-mm-dd HH-MM');
            resultsBase = fullfile(projectRoot, 'results');
            resultsRoot = fullfile(resultsBase, ['result ' stamp]);

            % Locate template root
            t1 = fullfile(projectRoot, 'src', 'results_template');

            if exist(t1,'dir') == 7
                templateRoot = t1;
            else
                error('Template root not found. Expected: %s', t1);
            end

            % Ensure base results dir and this run dir exist
            if exist(resultsBase,'dir') ~= 7
                mkdir(resultsBase);
            end
            if exist(resultsRoot,'dir') ~= 7
                mkdir(resultsRoot);
            end

            % Snapshot templates into the versioned run root
            % (copies whole tree so you get: result_.../CEC####/##Dim.xlsx ready)
            copyfile(templateRoot, resultsRoot);

            C.projectRoot  = projectRoot;
            C.templateRoot = templateRoot;
            C.resultsRoot  = resultsRoot;
            C.stamp        = stamp;

            ctx = C;

        case 'get'
            if isempty(C) || ~isfield(C,'resultsRoot') || isempty(C.resultsRoot)
                % Lazy init if someone called before main
                ctx = ProjectContext('init', '');
                return;
            end
            ctx = C;

        otherwise
            error('Unknown action: %s', action);
    end
end
