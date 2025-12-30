function ensureAlgorithmsSubmodule(projectRoot, algDir, maxAgeDays)
    % ensureAlgorithmsSubmodule
    % Ensures the algorithms repository (as a git submodule) is present.
    % If missing/empty, runs: git submodule update --init --recursive
    % If present but last fetch is older than maxAgeDays, runs: git fetch --all --prune
    %
    % Notes:
    % - For submodules, "pull" may not be appropriate (often detached at pinned commit).
    % - "fetch" refreshes the repository metadata without changing the pinned checkout.

    if nargin < 3 || isempty(maxAgeDays)
        maxAgeDays = 14;
    end

    % If missing or effectively empty -> init submodule
    if ~isfolder(algDir) || isDirEffectivelyEmpty(algDir)
        assertGitAvailable();
        runGitAt(projectRoot, 'git submodule update --init --recursive');
        return;
    end

    % If no .git indicator exists, treat as missing
    if ~exist(fullfile(algDir, '.git'), 'file') && ~isfolder(fullfile(algDir, '.git'))
        assertGitAvailable();
        runGitAt(projectRoot, 'git submodule update --init --recursive');
        return;
    end

    % Compute "staleness" based on FETCH_HEAD timestamp (best-effort)
    ageDays = getSubmoduleFetchAgeDays(algDir);

    if isnan(ageDays) || ageDays > maxAgeDays
        assertGitAvailable();

        % Ensure submodule is properly initialized (idempotent)
        runGitAt(projectRoot, 'git submodule update --init --recursive');

        % Refresh remote metadata without changing the pinned checkout
        runGitAt(projectRoot, sprintf('git -C "%s" fetch --all --prune', algDir));
    end
end

function tf = isDirEffectivelyEmpty(p)
    % Returns true if directory has no meaningful files/folders (ignores "." and "..").

    d = dir(p);
    names = {d.name};
    names = names(~ismember(names, {'.','..'}));

    % Consider empty if nothing else exists
    tf = isempty(names);
end

function ageDays = getSubmoduleFetchAgeDays(algDir)
    % Tries to locate the real git directory for the submodule and read FETCH_HEAD age.
    % Returns NaN if it cannot determine.

    ageDays = NaN;

    gitPtr = fullfile(algDir, '.git');

    % Submodules often have ".git" as a file containing "gitdir: <path>"
    if exist(gitPtr, 'file') == 2
        try
            txt = string(strtrim(fileread(gitPtr)));
            % Expected format: "gitdir: <path>"
            if startsWith(lower(txt), "gitdir:")
                rel = strtrim(extractAfter(txt, "gitdir:"));
                gitDir = char(rel);

                % Resolve relative gitdir path against algDir
                if ~isfolder(gitDir)
                    gitDir = fullfile(algDir, gitDir);
                end

                fetchHead = fullfile(gitDir, 'FETCH_HEAD');
                if exist(fetchHead, 'file') == 2
                    ageDays = fileAgeDays(fetchHead);
                    return;
                end

                % Fallback: use HEAD log if FETCH_HEAD not present
                headLog = fullfile(gitDir, 'logs', 'HEAD');
                if exist(headLog, 'file') == 2
                    ageDays = fileAgeDays(headLog);
                    return;
                end
            end
        catch
            % Keep NaN
        end

    elseif isfolder(gitPtr)
        % Non-submodule repo case (rare for your setup, but supported)
        fetchHead = fullfile(gitPtr, 'FETCH_HEAD');
        if exist(fetchHead, 'file') == 2
            ageDays = fileAgeDays(fetchHead);
            return;
        end
        headLog = fullfile(gitPtr, 'logs', 'HEAD');
        if exist(headLog, 'file') == 2
            ageDays = fileAgeDays(headLog);
            return;
        end
    end
end

function d = fileAgeDays(filePath)
    % Returns file age in days based on filesystem timestamp.

    info = dir(filePath);
    if isempty(info)
        d = NaN;
        return;
    end
    d = (now - info.datenum); % now and datenum are in days
end

function assertGitAvailable()
    % Throws an error if git is not available on PATH.

    [status, ~] = system('git --version');
    if status ~= 0
        error('Git is not available on PATH. Please install Git and restart MATLAB.');
    end
end

function runGitAt(rootDir, command)
    % Runs a shell command at a specific directory (cross-platform best effort).

    if ispc
        cmd = sprintf('cd /d "%s" && %s', rootDir, command);
    else
        cmd = sprintf('cd "%s" && %s', rootDir, command);
    end

    status = system(cmd);
    if status ~= 0
        error('Command failed: %s', command);
    end
end
