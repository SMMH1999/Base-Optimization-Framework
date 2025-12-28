function [pValue, hValue, ciLower, ciUpper, tStat, df, sd] = Ttest_new(benchmarkResults, maxItr, maxRun, cecName, varargin)
    %TTEST Performs pairwise two-sample t-tests between algorithms on benchmark results.
    %
    %   [pValue, hValue, ciLower, ciUpper, tStat, df, sd] = Ttest(...)
    %   compares the first algorithm against all others for each benchmark function
    %   using MATLAB's ttest2 function, and returns detailed statistical outputs.
    %
    %   INPUTS:
    %       benchmarkResults - Cell array of size [functions x algorithms] containing
    %                          results matrices (iterations x runs)
    %       maxItr           - Iteration index to extract results from
    %       maxRun           - Number of runs to consider
    %       cecName          - Identifier for the CEC set (e.g., 3 for CEC 2017)
    %
    %   OPTIONAL NAME-VALUE PAIRS:
    %       'Alpha'          - Significance level (default 0.05)
    %       'Tail'           - 'both' (default), 'right', or 'left'
    %       'Vartype'        - 'equal' (default) or 'unequal'
    %
    %   OUTPUTS:
    %       pValue   - Matrix of p-values
    %       hValue   - Matrix of hypothesis test results (1 = reject null)
    %       ciLower  - Lower bound of confidence intervals
    %       ciUpper  - Upper bound of confidence intervals
    %       tStat    - t-statistic values
    %       df       - Degrees of freedom
    %       sd       - Estimated standard deviation(s)
    %
    %   Author: [Your Name]
    %   Date:   [Date]
    %   ----------------------------------------------------------------------

    % Parse optional parameters from varargin using inputParser
    p = inputParser;
    addParameter(p, 'Alpha', 0.05);       % Default significance level
    addParameter(p, 'Tail', 'both');      % Default is a two-tailed test
    addParameter(p, 'Vartype', 'equal');  % Default assumes equal variances
    parse(p, varargin{:});
    alphaVal = p.Results.Alpha;   % Extract parsed alpha value
    tailVal = p.Results.Tail;     % Extract parsed tail type
    vartypeVal = p.Results.Vartype; % Extract parsed variance type

    % Transpose so each row corresponds to a benchmark function
    benchmarkResults = benchmarkResults';

    % Determine number of functions and algorithms, initialize outputs with NaN
    numFunc = size(benchmarkResults, 1);
    numAlg = size(benchmarkResults, 2) - 1; % Compare all algorithms against first one
    pValue  = nan(numFunc, numAlg);
    hValue  = nan(numFunc, numAlg);
    ciLower = nan(numFunc, numAlg);
    ciUpper = nan(numFunc, numAlg);
    tStat   = nan(numFunc, numAlg);
    df      = nan(numFunc, numAlg);
    sd      = nan(numFunc, numAlg);

    % Loop over benchmark functions
    for funcIdx = 1:numFunc
        % Extract results for all algorithms in current function
        tableResult = {benchmarkResults{funcIdx, :}};

        % Special case handling: skip specific function for CEC 2017 dataset
        if cecName == 3 && funcIdx == 2
            continue;
        end

        % Loop over algorithms (excluding the first baseline algorithm)
        for algIdx = 1:numAlg
            % Retrieve result matrices for baseline and comparison algorithms
            results1 = tableResult{1, 1};
            results2 = tableResult{1, algIdx + 1};

            % Extract results from the specified iteration and runs
            firstAlgorithm = results1(maxItr, 1:maxRun)';
            secondAlgorithm = results2(maxItr, 1:maxRun)';

            % Perform two-sample t-test with specified parameters
            [h, pVal, ci, stats] = ttest2(firstAlgorithm, secondAlgorithm, ...
                'Alpha', alphaVal, ...
                'Tail', tailVal, ...
                'Vartype', vartypeVal);

            % Ensure uniqueness of p-values by adding a tiny random offset if duplicate
            if any(pVal == pValue(:))
                pVal = pVal + eps * rand();
            end

            % Store outputs in result matrices
            pValue(funcIdx, algIdx)  = pVal;          % p-value
            hValue(funcIdx, algIdx)  = h;             % Hypothesis test result
            ciLower(funcIdx, algIdx) = ci(1);         % CI lower bound
            ciUpper(funcIdx, algIdx) = ci(2);         % CI upper bound
            tStat(funcIdx, algIdx)   = stats.tstat;   % t-statistic
            df(funcIdx, algIdx)      = stats.df;      % Degrees of freedom
            sd(funcIdx, algIdx)      = stats.sd;      % Standard deviation
        end
    end
end
