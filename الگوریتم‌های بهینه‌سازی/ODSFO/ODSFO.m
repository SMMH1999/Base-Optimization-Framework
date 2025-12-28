function [Best_Elite_Fitness, Best_Elite_Position, Convergence_Curve] = ...
        ODSFO(LB, UB, Dim, Predator_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
    %% Initialization parameter
    Prey_no = 100;
    % Predator_Percent = 30;
    % Predator_no = (Prey_no * Predator_Percent) / 100;
    Convergence_Curve = inf(1, Max_iter);
    Hard_Level = 20;
    Fish_Scales = Hard_Level * ones(Prey_no,1);
    A = UB/2;
    % A = 50;
    ebsilon = 2;
    F = 0.5;
    CR = 0.9;

    %% Initialize positions and fitness of Sailfish and Sardine
    SailFish_Position = Population_Generator(Predator_no, Dim, UB, LB);
    SailFish_Fitness = zeros(1, Predator_no);

    Sardine_Position = Population_Generator(Prey_no, Dim, UB, LB);
    Sardine_Fitness = zeros(1, Prey_no);

    %% Main Loop
    for Itr = 1:Max_iter        
        %% Calculate prey density in each itration
        Prey_Density = 1 - (Predator_no / (Predator_no + Prey_no));

        %% Return back the search agents that go beyond the boundaries of the search space
        SailFish_Position = min(max(SailFish_Position, LB), UB);
        Sardine_Position = min(max(Sardine_Position, LB), UB);
        
        %% Oppositing Population
        % [SailFish_Position, ~] = Opposite(LB, UB, SailFish_Position, Cost_Function, Function_Number, costFunctionDetails);
        [Sardine_Position, ~] = Opposite(LB, UB, Sardine_Position, Cost_Function, Function_Number, costFunctionDetails);

        %% Calculate the objective function for each search agent
        if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function') 
            % For objective function 2005
            for i = 1 : Predator_no
                SailFish_Fitness(i) = Cost_Function(SailFish_Position(i, :));
            end
            for i = 1 : Prey_no
                Sardine_Fitness(i) = Cost_Function(Sardine_Position(i, :));
            end
        elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
            for i = 1 : Predator_no
                SailFish_Fitness(i) = Cost_Function(SailFish_Position(i, :));
            end
            for i = 1 : Prey_no
                Sardine_Fitness(i) = Cost_Function(Sardine_Position(i, :));
            end
        else
            % For after objective function 2005
            SailFish_Fitness = Cost_Function(SailFish_Position', Function_Number);
            Sardine_Fitness = Cost_Function(Sardine_Position', Function_Number);
        end

        [SailFish_Fitness, Elite_Index] = sort(SailFish_Fitness);
        [Sardine_Fitness, Injured_Sardine_Index] = sort(Sardine_Fitness);

        SailFish_Position = SailFish_Position(Elite_Index, :);
        Sardine_Position = Sardine_Position(Injured_Sardine_Index, :);

        Elite_Fitness = SailFish_Fitness(1);
        Elite_Position = SailFish_Position(1, :);

        Injured_Sardine_Fitness = Sardine_Position(1);
        Injured_Sardine_Position = Sardine_Position(1, :);

        if Itr > 1
            if Elite_Fitness < Best_Elite_Fitness
                Best_Elite_Fitness = Elite_Fitness;
                Best_Elite_Position = Elite_Position;
                Convergence_Curve(Itr) = Best_Elite_Fitness;
            else
                Convergence_Curve(Itr) = Best_Elite_Fitness;
            end
        else
            Best_Elite_Fitness = Elite_Fitness;
            Best_Elite_Position = Elite_Position;
            Convergence_Curve(Itr) = Best_Elite_Fitness;
        end


        %% Encircling
        for i = 1:Predator_no
            landa = 2 * rand() * (Prey_Density) - Prey_Density;
            SailFish_Position(i, :) = Elite_Position - landa * ((rand() * (Elite_Position + Injured_Sardine_Position)/2) - SailFish_Position(i, :));
        end

        %% Hunting
        Attack_Power = A * (1 - (Itr / Max_iter)) .^ ebsilon;
        if Attack_Power <= 1
            alpha = round(mod(Prey_no * abs(Attack_Power), 1));
            beta = round(mod(Dim * abs(Attack_Power), 1));
            a = randperm(Prey_no, max(alpha));
            for i = a
                b = randperm(Dim, max(beta));
                for j = b
                    % Sardine_Position(i, j) = rand() * (Injured_Sardine_Position(1, j) - Sardine_Position(i, j) + (Attack_Power));
                    Sardine_Position(i, j) = rand() * (Elite_Position(1, j) - Sardine_Position(i, j) + (Attack_Power(1,j)));

                end
            end
        else
            for i = 1:Prey_no
                % Mutation
                idxs = randperm(Prey_no, 3);
                while any(idxs == i)
                    idxs = randperm(Prey_no, 3);
                end

                Mutant_Sardine_Position = Sardine_Position(idxs(1), :) + F * (Sardine_Position(idxs(2), :) - Sardine_Position(idxs(3), :));
                Mutant_Sardine_Position = min(max(Mutant_Sardine_Position, LB), UB);

                % Crossover
                trial = Sardine_Position(i, :);
                j_rand = randi(Dim);
                for j = 1:Dim
                    if rand <= CR || j == j_rand
                        trial(j) = Mutant_Sardine_Position(j);
                    end
                end

                % Selection
                % trial = min(max(trial, LB), UB);
                if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
                    % For objective function 2005
                    trial_Fitness = Cost_Function(trial(1, :));
                elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
                    trial_Fitness = Cost_Function(trial);
                else
                    % For after objective function 2005
                    trial_Fitness = Cost_Function(trial', Function_Number);
                end

                if trial_Fitness < Sardine_Fitness(i)
                    Sardine_Position(i, :) = trial;
                    Sardine_Fitness(i) = trial_Fitness;
                end
            end
        end

        if Elite_Fitness > Injured_Sardine_Fitness
            SailFish_Position(Elite_Index(1, 1), :) = Injured_Sardine_Position;
            SailFish_Fitness(1, Elite_Index(1, 1)) = Injured_Sardine_Fitness;
            Elite_Fitness = Injured_Sardine_Fitness;
            if Fish_Scales(Injured_Sardine_Index(1, 1)) == 0
                Sardine_Position(Injured_Sardine_Index(1, 1), :) = [];
                Fish_Scales(Injured_Sardine_Index(1, 1)) = [];
                Sardine_Fitness(Injured_Sardine_Index(1, 1)) = [];
                Prey_no = Prey_no - 1;
            else
                Fish_Scales(Injured_Sardine_Index(1, 1)) = Fish_Scales(Injured_Sardine_Index(1, 1)) - 1;
            end

            if Prey_no == 0
                disp(['In Itration = ' num2str(Itr) '  All Sardines have been eaten!!!!']);
                break
            end
        end
    end
end

function [Population, Fitness] = Opposite(LB, UB, Population, Cost_Function, Function_Number, costFunctionDetails)
    %% Make Opposition Population Based on Opposite Number Definition
    OppositePopulation = LB + UB - Population.* rand();
    OppositePopulation = min(max(OppositePopulation, LB), UB);

    %% Calculate Fitness for Population and OppositePopulation
    Population_Size = size(Population, 1);
    Fitness = zeros(1, Population_Size);
    OppositeFitness = zeros(1, Population_Size);


    % Calculate the objective function for each search agent
    if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function') || strcmp(func2str(costFunctionDetails), 'ProbInfo')
        % For objective function 2005
        for i = 1 : Population_Size
            Fitness(i) = Cost_Function(Population(i, :));
            OppositeFitness(i) = Cost_Function(OppositePopulation(i, :));
        end
    elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
        for i = 1 : Population_Size
            Fitness(i) = Cost_Function(Population(i, :));
            OppositeFitness(i) = Cost_Function(OppositePopulation(i, :));
        end
    else
        % For after objective function 2005
        Fitness = Cost_Function(Population', Function_Number);
        OppositeFitness = Cost_Function(OppositePopulation', Function_Number);
    end

    % Change Population loop
    for i = 1:size(Population, 1)
        % Change solution i-th of Population with solution i-th of OppositePopulation
        % If OppositeFitness is better than Fitness i-th solution
        if OppositeFitness(i) < Fitness(i)
            Population(i, :) = OppositePopulation(i, :);
            Fitness(i) = OppositeFitness(i);
        end
    end
end