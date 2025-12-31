function [] = ConclusionRW(benchmarkResults, maxItr, maxRun, algorithmFileAddress, nFunction, cecName, dim)
%CONCLUSIONRW Save Real-World benchmark outputs in the same "style" as CEC Conclusion:
% - resultsRoot/Real World Problems/<DimTag>.xlsx (Conclusions sheet)
% - resultsRoot/Real World Problems/algorithms/<DimTag>_<Alg>.xlsx (per-alg raw curves)

    suiteName = "Real World Problems";

    % === Algorithms list ===
    [algorithmNames, algorithms] = Get_algorithm(algorithmFileAddress);
    if isstring(algorithmNames) || ischar(algorithmNames), algorithmNames = cellstr(algorithmNames); end
    numAlgs = numel(algorithmNames);

    % === Resolve results paths EXACTLY like CEC (via ProjectContext) ===
    ctx = ProjectContext('get');
    resultsDir = fullfile(ctx.resultsRoot, char(suiteName));
    algoDir    = fullfile(resultsDir, 'algorithms');

    if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
    if ~exist(algoDir,'dir'),    mkdir(algoDir);    end

    fileFormat = 'xlsx';
    baseName   = dimTagFromInput(dim);     % e.g. '10Dim' or 'fixDim'

    % Optional skip rule (keep if you really need it; otherwise delete)
    shouldSkip = @(cecNameVal, fIdx) (cecNameVal==3 && fIdx==2);

    %% === 1) Build Conclusions table (Min/Mean/Max/Std at final iteration) ===
    summaryTable = cell(4*nFunction + 1, numAlgs + 2);
    summaryTable(1,1:2) = {'Problem','Stat'};
    for a = 1:numAlgs
        summaryTable{1,a+2} = algorithmNames{a};
    end

    statNames = {'Min','Mean','Max','Std'};
    for f = 1:nFunction
        r0 = 1 + (f-1)*4;
        for s = 1:4
            summaryTable{r0+s,1} = sprintf('Problem %d', f);
            summaryTable{r0+s,2} = statNames{s};
        end
    end

    for a = 1:numAlgs
        for f = 1:nFunction
            if isempty(benchmarkResults{a,f}) || shouldSkip(cecName,f), continue; end

            M = benchmarkResults{a,f};

            % columns: [runs ...] + [min mean max std] at (maxRun+1 .. maxRun+4)
            cMin  = maxRun + 1;
            cMean = maxRun + 2;
            cMax  = maxRun + 3;
            cStd  = maxRun + 4;

            rFinal = min(size(M,1), maxItr);   % use last available iter row

            r0 = 1 + (f-1)*4;
            if size(M,2) >= cMin,  summaryTable{r0+1,a+2} = M(rFinal,cMin);  end
            if size(M,2) >= cMean, summaryTable{r0+2,a+2} = M(rFinal,cMean); end
            if size(M,2) >= cMax,  summaryTable{r0+3,a+2} = M(rFinal,cMax);  end
            if size(M,2) >= cStd,  summaryTable{r0+4,a+2} = M(rFinal,cStd);  end
        end
    end

    % Save conclusions workbook (same pattern as CEC)
    Saving(summaryTable, resultsDir, baseName, fileFormat, 'Conclusions', 'A2');

    %% === 2) Save raw iteration curves per algorithm (like CEC Conclusion) ===
    headers = [{'Iteration'}, arrayfun(@(x) sprintf('P%d',x), 1:nFunction, 'UniformOutput', false)];
    iterCol = (1:maxItr)';

    for a = 1:numAlgs
        rawData = nan(maxItr, nFunction);

        for f = 1:nFunction
            if isempty(benchmarkResults{a,f}) || shouldSkip(cecName,f), continue; end
            M = benchmarkResults{a,f};

            % take the "Min" curve over runs per iteration (col maxRun+1)
            colBest = maxRun + 1;
            rMax = min(maxItr, size(M,1));
            if size(M,2) >= colBest
                rawData(1:rMax, f) = M(1:rMax, colBest);
            end
        end

        fullData = [iterCol, rawData];

        sheetName = sanitizeSheetName(algorithmNames{a});
        algFile   = sprintf('%s_%s', baseName, sheetName);

        Saving(headers,   algoDir, algFile, fileFormat, sheetName, 'A1');
        Saving(fullData,  algoDir, algFile, fileFormat, sheetName, 'A2');
    end
end

%% ===== helpers (copy/paste safe) =====
function tag = dimTagFromInput(dimVal)
    if isempty(dimVal)
        tag = 'fixDim';
        return;
    end

    % If your dim comes as {'fixDim', []}
    if iscell(dimVal) && ~isempty(dimVal)
        try
            s0 = string(dimVal{1});
            if lower(strtrim(s0)) == "fixdim" || lower(strtrim(s0)) == "fix"
                tag = 'fixDim';
                return;
            end
        catch
        end
    end

    if isnumeric(dimVal)
        if dimVal == 0
            tag = 'fixDim';
        else
            tag = sprintf('%dDim', dimVal);
        end
        return;
    end

    s = lower(strtrim(string(dimVal)));

    if s == "fix" || s == "fixdim"
        tag = 'fixDim';
    elseif endsWith(s, "dim")
        tag = char(s);
    else
        tag = char(s + "Dim");
    end
end

function s = sanitizeSheetName(s)
    s = char(string(s));
    s = regexprep(s, '[:\\/?*\[\]]', '_'); % invalid in Excel sheet names
    if numel(s) > 31
        s = s(1:31);
    end
    if isempty(s)
        s = 'Sheet1';
    end
end
