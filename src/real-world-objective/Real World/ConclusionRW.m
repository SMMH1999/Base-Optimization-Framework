function [] = ConclusionRW(benchmarkResults, maxItr, maxRun, algorithmFileAddress, nFunction, cecName, dim)
% == Suite name (Real-World) ==
cecNames = "Real World Problems";

% == Algorithm names/handles ==
[algorithmsName, algorithms] = Get_algorithm(algorithmFileAddress);
if isstring(algorithmsName) || ischar(algorithmsName), algorithmsName = cellstr(algorithmsName); end
numAlgs = numel(algorithmsName);

% == Resolve project paths (portable, no hard-coded absolute path) ==
scriptPath = mfilename('fullpath');
moduleDir  = fileparts(fileparts(scriptPath));
projectDir = fileparts(moduleDir);
resultsDir = fullfile(projectDir, 'results', char(cecNames));
algoDir    = fullfile(resultsDir, 'Algorithms');
if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
if ~exist(algoDir,'dir'),   mkdir(algoDir);   end

% == Conclusions table (4 rows per problem + 1 header, 2 meta cols + algs) ==
tableConclusion = cell(4*nFunction + 1, numAlgs + 2);
tableConclusion(1,1:2) = {'Problem','Stat'};
for a = 1:numAlgs
    tableConclusion{1, a+2} = algorithmsName{a};
end
statNames = {'Min','Mean','Max','Std'};
for f = 1:nFunction
    baseRow = 1 + (f-1)*4;
    for s = 1:4
        tableConclusion{baseRow + s, 1} = ['Problem' num2str(f)];
        tableConclusion{baseRow + s, 2} = statNames{s};
    end
end

% == Headers for per-algorithm sheets ==
resultsHeader = cell(nFunction, 1);
for f = 1:nFunction
    resultsHeader{f, 1} = ['Problem' num2str(f)];
end

% == Common file naming ==
if isa(dim,'double'), dimStr = num2str(dim); else, dimStr = char(string(dim)); end
fileFormat = 'xlsx';
fileName   = [dimStr 'Dim'];

% == Loop over algorithms ==
for iAlgorithm = 1:numAlgs
    % Row to export per problem (kept exactly as در کد تو: row maxItr+1)
    outputResults = cell(nFunction, 1);

    % == Loop over problems ==
    for iFunction = 1:nFunction
        % Optional skip (as in your original code)
        if cecName == 3 && iFunction == 2
            continue;
        end

        M = benchmarkResults{iAlgorithm, iFunction};
        if isempty(M), continue; end

        % دفاع در برابر ابعاد ناکامل
        rFinal = min(size(M,1), maxItr);
        cMin   = maxRun + 1;
        cMean  = maxRun + 2;
        cMax   = maxRun + 3;
        cStd   = maxRun + 4;

        baseRow = 1 + (iFunction-1)*4;
        if size(M,2) >= cMin,  tableConclusion{baseRow+1, iAlgorithm+2} = M(rFinal, cMin);  end
        if size(M,2) >= cMean, tableConclusion{baseRow+2, iAlgorithm+2} = M(rFinal, cMean); end
        if size(M,2) >= cMax,  tableConclusion{baseRow+3, iAlgorithm+2} = M(rFinal, cMax);  end
        if size(M,2) >= cStd,  tableConclusion{baseRow+4, iAlgorithm+2} = M(rFinal, cStd);  end

        rExtra = maxItr + 1;
        if size(M,1) >= rExtra
            outputResults{iFunction,1} = M(rExtra, :);
        else
            outputResults{iFunction,1} = [];
        end
    end

    % ذخیره‌ی خروجی هر الگوریتم (دقیقاً مثل ساختار قبلی؛ فقط مسیر portable شده)
    sheetName = algorithmsName{iAlgorithm};
    Saving(resultsHeader, algoDir, [fileName '_' sheetName], fileFormat, sheetName, 'A1');
    Saving(outputResults, algoDir, [fileName '_' sheetName], fileFormat, sheetName, 'B1');
end

% == Save Conclusions workbook ==
% آدرس پوشه جمع‌بندی: .../results/Real World Problems/
Saving(tableConclusion, resultsDir, fileName, fileFormat, 'Conclusions', 'B2');

% پاک‌سازی حداقلی (فقط متغیرهای تعریف‌شده در همین تابع)
clear resultsHeader outputResults M;
end
