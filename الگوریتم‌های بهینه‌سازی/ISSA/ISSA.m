function [Best_Fitness, Best_Position, Fitness_Curve, Best_Fitness_Per_Itr] = ISSA(LB, UB, Dim, PopSize, Max_iter, Cost_Function, Function_Number, costFunctionDetails)

    %% ================= Initialization =================
    pFoll = 0.4;     % Follower probability
    pPion = 0.6;     % Pioneer probability

    Fitness_Curve = zeros(1, Max_iter);
    Best_Fitness_Per_Itr = zeros(1, Max_iter);

    % Generate initial population
    positions = Population_Generator(PopSize, Dim, UB, LB);

    % Evaluate initial population
    fitness = EvaluatePopulation(positions, Cost_Function, Function_Number, costFunctionDetails);

    [Best_Fitness, idx] = min(fitness);
    Best_Position = positions(idx, :);
    Fitness_Curve(1) = Best_Fitness;
    Best_Fitness_Per_Itr(1) = Best_Fitness;

    %% ================= Main Loop =================
    for t = 2:Max_iter
        c1 = 2 * exp(-(4 * t / Max_iter) ^ 2);

        for i = 1:PopSize
            if i == 1
                % Leader update
                r1 = rand(1, Dim);
                r2 = rand(1, Dim);
                r3 = rand(1, Dim);
                if r3 < 0.5
                    positions(i,:) = Best_Position + r1 .* ((UB - LB) .* r2 + LB);
                else
                    positions(i,:) = Best_Position - r1 .* ((UB - LB) .* r2 + LB);
                end
            else
                r = rand;
                if r < pFoll
                    % Follower
                    r1 = rand(1, Dim);
                    positions(i,:) = positions(i-1,:) .* r1 + positions(i,:) .* (1 - r1);
                else
                    r = rand;
                    if r < pPion
                        % Pioneer
                        r1 = rand;
                        if r1 < 0.25
                            r2 = rand(1, Dim) - 0.5;
                            r3 = rand(1, Dim);
                            positions(i,:) = positions(randi(PopSize),:) + r2 .* r3 .* ((UB - LB) + LB);
                        elseif r1 < 0.5
                            r2 = rand(1, Dim);
                            positions(i,:) = positions(randi(PopSize),:) .* r2 + positions(randi(PopSize),:) .* (1 - r2);
                        elseif r1 < 0.7
                            r2 = rand(1, Dim);
                            positions(i,:) = r2 .* ((UB - LB) + LB);
                        else
                            positions(i,:) = UB + LB - positions(i,:);
                        end
                    else
                        % Rogue
                        r2 = rand(1, Dim) - 0.5;
                        r3 = rand(1, Dim);
                        positions(i,:) = Best_Position + r2 .* (Best_Position .* r3 - (1 - r3) .* positions(i,:));
                    end
                end
            end

            % Boundary control
            positions(i,:) = max(min(positions(i,:), UB), LB);
        end

        % Evaluate population
        fitness = EvaluatePopulation(positions, Cost_Function, Function_Number, costFunctionDetails);

        % Update best solution
        [current_best, idx] = min(fitness);
        if current_best < Best_Fitness
            Best_Fitness = current_best;
            Best_Position = positions(idx, :);
        end

        Fitness_Curve(t) = Best_Fitness;
        Best_Fitness_Per_Itr(t) = current_best;
    end

end

%% ========== Helper Function for Evaluation ==========
function fitness = EvaluatePopulation(positions, Cost_Function, Function_Number, costFunctionDetails)
    [PopSize, Dim] = size(positions);
    fitness = zeros(PopSize, 1);

    for i = 1:PopSize
        x = positions(i, :);

        if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
            % Pass as row or column depending on the function
            fitness(i) = Cost_Function(x);

        elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
            % Real-world problems (same logic)
            fitness(i) = Cost_Function(x);

        else
            % After CEC functions: pass as column vector with function number
            fitness(i) = Cost_Function(x', Function_Number);
        end
    end
end
