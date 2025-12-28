function Comparetor_RW(CEC_Index, populationNo, maxRun, maxItr, CECsDim)
    %% Benchmark Function
    % Getting the CECs detail from CEC_Benchmarks
    CECNames = "Real World Problems";
    [~, costFunctionDetails, nFunction] = CECRW_Benchmarks(CEC_Index);

    %%
    algorithmFileAddress = "C:\Users\pc\Desktop\کد نویسی و برنامه‌ها\پیش نیازها\RWP\RW_AlgorithmsName.txt";
    [algorithmsName, algorithms] = Get_algorithm(algorithmFileAddress);

    % nFunction = 1;
    for index = 1 : size(CECsDim,2)
        dim = [];
        benchmarkResults = cell(size(algorithms, 1),nFunction);        
        for functionNo = 1 : nFunction            
            functionName = ['Problem ' num2str(functionNo)];            
            % [LB, UB, Dim, g, h] = costFunctionDetails(functionNo);
            %% Problem Information
            [Dim, LB, UB, VioFactor, GloMin, Obj] = ProbInfo(functionNo);
            LB = LB .* ones(1, Dim);
            UB = UB .* ones(1, Dim);

            %% Cost Function
            costFunction = @(x) CostFunction(x, VioFactor, Obj);

            
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
                bestSolutions = zeros(maxRun,Dim);
%                 for run = 1 : maxRun
                parfor run = 1 : maxRun
                    clc;
                    disp(strcat("CEC: ", CECNames(CEC_Index), " Dim: ", num2str(Dim) , " Function: ", functionName," Algorithm: ", algorithmName," Run: ", num2str(run)));
                    [bestResults(run), bestSolutions(run, :), algoritmResults(:,run)] = algorithm(LB, UB, Dim, populationNo, maxItr, costFunction, functionNo, costFunctionDetails);
                end

                algoritmResults(maxItr,:) = bestResults;
                [algoritmResults(:,maxRun + 1), algoritmResults(:,maxRun + 2), algoritmResults(:,maxRun + 3), algoritmResults(:,maxRun + 4)] = Results_Toolkit(algoritmResults);
                algoritmResults(maxItr + 1, 1 : Dim) = bestSolutions(maxRun, :);
                benchmarkResults{algorithmNo,functionNo} = algoritmResults;
                clear [algoritmResults,bestResults,timeExecute];
            end
        end
        ConclusionRW(benchmarkResults, maxItr, maxRun, algorithmFileAddress, nFunction, CEC_Index, dim);
    end
end

