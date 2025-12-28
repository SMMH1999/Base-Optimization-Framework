function Comparetor3(CEC_Index, populationNo, maxRun, maxItr, CECsDim)
    %% Benchmark Function
    % Getting the CECs detail from CEC_Benchmarks
    CECNames = ["2005","2014","2017","2019","2020","2022"];
    [costFunction, costFunctionDetails, nFunction] = CEC_Benchmarks(CEC_Index);

    %%
    algorithmFileAddress = "\AlgorithmsName.txt";
    [algorithmsName, algorithms] = Get_algorithm(algorithmFileAddress);

    for index = 1 : size(CECsDim,2)
        dim = [];
        benchmarkResults = cell(size(algorithms, 1),nFunction);

        for functionNo = 1 : nFunction
            %% Error handling
            % Error handling for CEC 2017
            if eq(func2str(costFunctionDetails), 'CEC_2017_Function')
                if functionNo == 2
                    continue;
                end
            end

            functionName = ['F' num2str(functionNo)];
            if eq(func2str(costFunctionDetails), 'CEC_2005_Function')
                [LB, UB, Dim, costFunction] = costFunctionDetails(functionNo);
            else
                [LB, UB, Dim] = costFunctionDetails(functionNo);
            end

            if class(CECsDim(index)) == "double" || class(CECsDim{index}) == "double"
                if class(CECsDim(index)) == "double"
                    dim = CECsDim(index);
                    Dim = CECsDim(index);
                else
                    dim = CECsDim{index};
                    Dim = CECsDim{index};
                end
            else
                dim = CECsDim{index};
            end


            for algorithmNo = 1 : size(algorithms, 1)

                algorithm = algorithms{algorithmNo};
                algorithmName = algorithmsName(algorithmNo);

                algoritmResults = ones(maxItr,maxRun) * -1;
                bestResults = zeros(maxRun,1);
                timeExecute = zeros(maxRun,1);

                for run = 1 : maxRun
                % parfor run = 1 : maxRun
                    clc;
                    information = strcat("CEC: ", CECNames(CEC_Index), " Dim: ", num2str(Dim) , " Function: ", functionName," Algorithm: ", algorithmName," Run: ", num2str(run));
                    disp(information);
                    timer = cputime;
                    [bestResults(run), ~, algoritmResults(:,run)] = algorithm(LB, UB, Dim, populationNo, maxItr, costFunction, functionNo, costFunctionDetails);
                    timeExecute(run) = cputime - timer;

                end

                algoritmResults(maxItr,:) = bestResults;
                algoritmResults(maxItr + 1,:) = timeExecute;

                [~, algoritmResults(:,maxRun + 1), ~, algoritmResults(:,maxRun + 2)] = Results_Toolkit(algoritmResults);
                benchmarkResults{algorithmNo,functionNo} = algoritmResults;
                clear [algoritmResults,bestResults,timeExecute];
            end
        end

        Conclusion(benchmarkResults, maxItr, maxRun, algorithmFileAddress, nFunction, CEC_Index, dim);
        Ploting(benchmarkResults, maxItr, maxRun, algorithmFileAddress, CEC_Index, dim);

    end
end

