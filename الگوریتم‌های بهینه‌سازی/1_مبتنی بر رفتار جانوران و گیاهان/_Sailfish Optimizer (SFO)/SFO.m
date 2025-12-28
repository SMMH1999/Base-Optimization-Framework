function [Best_Elite_Fitness, Best_Elite_Position, Convergence_Curve] = SFO(LB, UB, Dim, Predator_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
    %% Initialize Predator_no, and Prey_no
    Prey_no = 100;
    % Predator_Percent = 30;
    % Predator_no = (Prey_no * Predator_Percent) / 100;
    Convergence_Curve = inf(1, Max_iter);

    %% Initialize positions and fitness of Sailfish and Sardine
    SailFish_Position = Population_Generator(Predator_no, Dim, UB, LB);
    Sardine_Position = Population_Generator(Prey_no, Dim, UB, LB);
    
    %% Main Loop
    for Itr = 1 : Max_iter
        SailFish_Fitness = inf(1, Predator_no);
        Sardine_Fitness = inf(1, Prey_no);
        
        %% Calculate prey density in each itration
        Prey_Density = 1 - (Predator_no / (Predator_no + Prey_no));

        %% Return back the search agents that go beyond the boundaries of the search space
        SailFish_Position = min(max(SailFish_Position, LB), UB);
        Sardine_Position = min(max(Sardine_Position, LB), UB);

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

        %% Find fitness and position of Elite and Injured_Sardin
        [Elite_Fitness, Elite_Index] = min(SailFish_Fitness);
        Elite_Position = SailFish_Position(Elite_Index(1, 1), :);
        [Injured_Sardin_Fitness, Injured_Sardin_Index] = min(Sardine_Fitness);
        Injured_Sardin_Position = Sardine_Position(Injured_Sardin_Index(1, 1), :);

        %% Update Convergence_Curve, fitness, and position in each itration
        Best_Elite_Fitness = Elite_Fitness;
        Best_Elite_Position = Elite_Position;
        Convergence_Curve(Itr) = Elite_Fitness;
        if Itr > 1
            if Best_Elite_Fitness > Convergence_Curve(Itr - 1)
                Best_Elite_Fitness = Convergence_Curve(Itr - 1);
                Convergence_Curve(Itr) = Convergence_Curve(Itr - 1);
            end
        end

        %% Encircling Phase
        for i = 1 : Predator_no
            landa = 2 * rand() * (Prey_Density) - Prey_Density;
            SailFish_Position(i, :) = Elite_Position - landa * ((rand() * (Elite_Position + Injured_Sardin_Position) / 2) - SailFish_Position(i, :));
        end

        %% Hunting Phase
        A = 4;
        ebsilon = 0.001;
        Attack_Power = A * (1 - (2 * Itr * ebsilon));
        if Attack_Power < 0.5
            alpha = round(Prey_no * abs(Attack_Power)); %The number of sardins that have been affected
            a = randperm(Prey_no, alpha);
            for i = a
                beta = round(Dim * abs(Attack_Power));  %The number of variable ( in Sardin Matrix)that have been affected
                b = randperm(Dim, beta);
                for j = b
                    Sardine_Position(i, j) = rand() * (Elite_Position(1, j) - Sardine_Position(i, j) + Attack_Power);
                end
            end
        else
            for i = 1:Prey_no
                Sardine_Position(i, :) = rand() * (Elite_Position - Sardine_Position(i, :) + Attack_Power);
            end
        end

        if Elite_Fitness > Injured_Sardin_Fitness
            SailFish_Position(Elite_Index(1, 1), :) = Injured_Sardin_Position;
            Sardine_Position(Injured_Sardin_Index(1, 1), :) = [];
            Sardine_Fitness(Injured_Sardin_Index(1, 1)) = [];
            Prey_no = Prey_no - 1;
            if Prey_no == 0
                disp(['In Itration = ' num2str(Itr) '  All Sardins have been eaten!!!!']);
                break
            end
        end
    end
end
