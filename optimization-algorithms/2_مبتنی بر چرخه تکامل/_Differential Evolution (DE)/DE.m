function [Best_Fitness, Best_Position, Convergence_Curve] = DE(LB, UB, Dim, Pop_size, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
    %% Initialization
    Convergence_Curve = inf(1, Max_iter);
    Population = Population_Generator(Pop_size, Dim, UB, LB);
    Fitness = inf(1, Pop_size);

    %% Calculate the objective function for each search agent
    if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
        % For objective function 2005
        for i = 1:Pop_size
            Fitness(i) = Cost_Function(Population(i, :));
        end
    elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
        % For objective function Real Word Problems
        for i = 1:Pop_size
            Fitness(i) = Cost_Function(Population(i, :));
        end
    else
        % For after objective function 2005
        Fitness = Cost_Function(Population', Function_Number);
    end

    %% DE Parameters
    F = 0.5; % Mutation factor
    CR = 0.9; % Crossover rate

    %% Main Loop
    for Itr = 1:Max_iter
        for i = 1:Pop_size
            % Mutation
            idxs = randperm(Pop_size, 3);
            while any(idxs == i)
                idxs = randperm(Pop_size, 3);
            end
            mutant = Population(idxs(1), :) + F * (Population(idxs(2), :) - Population(idxs(3), :));
            mutant = max(mutant, LB);
            mutant = min(mutant, UB);

            % Crossover
            trial = Population(i, :);
            j_rand = randi(Dim);
            for j = 1:Dim
                if rand <= CR || j == j_rand
                    trial(j) = mutant(j);
                end
            end

            % Selection
            if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
                % For objective function 2005
                trial_fitness = Cost_Function(trial(1, :));
            elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
                % For objective function Real Word Problems
                trial_fitness = Cost_Function(trial(1, :));
            else
                % For after objective function 2005
                trial_fitness = Cost_Function(trial', Function_Number);
            end
            if trial_fitness < Fitness(i)
                Population(i, :) = trial;
                Fitness(i) = trial_fitness;
            end
        end

        % Record Best Fitness
        [Best_Fitness, best_idx] = min(Fitness);
        Convergence_Curve(Itr) = Best_Fitness;
    end

    %% Final Outputs
    Best_Position = Population(best_idx, :);
end
