function [pValue, hValue] = Ttest(benchmarkResults, maxItr, maxRun, cecName)
    benchmarkResults = benchmarkResults';
    % P-Value matrix
    pValue = zeros(size(benchmarkResults, 1), size(benchmarkResults, 2) - 1);
    hValue = zeros(size(benchmarkResults, 1), size(benchmarkResults, 2) - 1);

    for functions = 1: size(benchmarkResults, 1)
        tableResult = {benchmarkResults{functions, :}};

        % Error handling for CEC 2017
        if cecName == 3
            if functions == 2
                continue;
            end
        end

        for algorithm = 1: size(benchmarkResults, 2) - 1
            results1 = tableResult{1, 1};
            results2 = tableResult{1, algorithm + 1};
            firstAlgorithm = results1(maxItr, 1 : maxRun)';
            secondAlgorithm = results2(maxItr, 1 : maxRun)';

            [h,p] = ttest2(firstAlgorithm, secondAlgorithm);

            pValue(functions, algorithm) = p;
            hValue(functions, algorithm) = h;
        end
    end
end