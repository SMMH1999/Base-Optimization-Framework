function [FoodFitness, FoodPosition, Convergence_curve] = SSA(LB, UB, Dim, Salp_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
    %% Initialize Parameters
    if size(UB, 2) == 1
        UB = ones(1, Dim) * UB;
        LB = ones(1, Dim) * LB;
    end
    Convergence_curve = inf(1, Max_iter);

    %% Initialize positions and fitness of salps
    SalpPositions = Population_Generator(Salp_no, Dim, UB, LB);
    SalpFitness = inf(1, Salp_no);
    FoodPosition = zeros(1, Dim);
    FoodFitness = inf;

    %% Calculate the objective function for each search agent
    if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
        % For objective function 2005
        for i = 1:size(SalpPositions, 1)
            SalpFitness(i) = Cost_Function(SalpPositions(i, :));
        end
    elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
        % For objective function Real Word Problems
        for i = 1:size(SalpPositions, 1)
            SalpFitness(i) = Cost_Function(SalpPositions(i, :));
        end
    else
        % For after objective function 2005
        SalpFitness = Cost_Function(SalpPositions', Function_Number);
    end

    %% Sorting the Population
    [sorted_salps_fitness, sorted_indexes] = sort(SalpFitness);
    for newindex = 1:Salp_no
        Sorted_salps(newindex, :) = SalpPositions(sorted_indexes(newindex), :);
    end
    FoodPosition = Sorted_salps(1, :);
    FoodFitness = sorted_salps_fitness(1);

    %% Main loop
    % start from the second iteration since the first iteration was dedicated to calculating the fitness of salps
    l = 2;
    while l < Max_iter + 1
        c1 = 2 * exp(-(4 * l / Max_iter) ^ 2);
        for i = 1:size(SalpPositions, 1)
            SalpPositions= SalpPositions';
            if i <= Salp_no / 2
                for j = 1:1:Dim
                    if rand() < 0.5
                        SalpPositions(j, i) = FoodPosition(j) + c1 * ((UB(j) - LB(j)) * rand() + LB(j));
                    else
                        SalpPositions(j, i) = FoodPosition(j) - c1 * ((UB(j) - LB(j)) * rand() + LB(j));
                    end
                end
            elseif i > Salp_no / 2 && i < Salp_no + 1
                point1 = SalpPositions(:, i-1);
                point2 = SalpPositions(:, i);
                SalpPositions(:, i) = (point2 + point1) / 2;
            end
            SalpPositions = SalpPositions';
        end
        %% Return back the search agents that go beyond the boundaries of the search space
        SalpPositions = min(max(SalpPositions, LB), UB);

        %% Calculate the objective function for each search agent
        if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
            % For objective function 2005
            for i = 1:size(SalpPositions, 1)
                SalpFitness(i) = Cost_Function(SalpPositions(i, :));
            end
        elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
            % For objective function Real Word Problems
            for i = 1:size(SalpPositions, 1)
                SalpFitness(i) = Cost_Function(SalpPositions(i, :));
            end
        else
            % For after objective function 2005
            SalpFitness = Cost_Function(SalpPositions', Function_Number);
        end

        for i = 1:size(SalpPositions, 1)
            if SalpFitness(i) < FoodFitness
                FoodPosition = SalpPositions(i, :);
                FoodFitness = SalpFitness(i);
            end
        end
        Convergence_curve(l) = FoodFitness;
        l = l + 1;
    end
end
