function [Best_Elite_Fitness, Best_Elite_Position, Convergence_Curve, history, average] = SFOOLMBES(LB, UB, Dim, Predator_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
    %% Initialize Predator_no, and Prey_no
    Prey_no = 100;
    delta = 1.5; R = 1.5;  % encircling/flight params
    delta = 1.5; alpha = 10; R = 1.5; c1 = 2; c2 = 2;
    % Predator_Percent = 30;
    % Predator_no = (Prey_no * Predator_Percent) / 100;
    Convergence_Curve = inf(1, Max_iter);
    history = inf(Max_iter, Predator_no, Dim);

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

        for i = 1:Predator_no
            SailFish_Fitness(i) = evaluate_cost(SailFish_Position(i,:), Cost_Function, Function_Number, costFunctionDetails);
        end
        for j = 1:Prey_no
            Sardine_Fitness(j)  = evaluate_cost(Sardine_Position(j,:),  Cost_Function, Function_Number, costFunctionDetails);
        end

        % Compute averages (innovation)
        avg_SailFish = mean(SailFish_Fitness);
        avg_Sardine  = mean(Sardine_Fitness);

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
        MeanSailFish = mean(SailFish_Position);
        for i = 1 : Predator_no
            % landa = 2 * rand() * (Prey_Density) - Prey_Density;
            % SailFish_Position(i, :) = Elite_Position - landa * ((rand() * (Elite_Position + Injured_Sardin_Position) / 2) - SailFish_Position(i, :));
            lambda   = 2*rand()*Prey_Density - Prey_Density;
            midpoint = (Best_Elite_Position + Injured_Sardin_Position)/2;
            Q1 = Best_Elite_Position - lambda*(rand()*midpoint - SailFish_Position(i,:));
            Q2 = Best_Elite_Position + delta*rand*(MeanSailFish - SailFish_Position(i,:));
            Q3 = Best_Elite_Position + LevyFlight(Dim).*sign(rand-0.5);
            % clamp
            Q1 = min(max(Q1, LB), UB);
            Q2 = min(max(Q2, LB), UB);
            Q3 = min(max(Q3, LB), UB);
            % evaluate
            f1 = evaluate_cost(Q1, Cost_Function, Function_Number, costFunctionDetails);
            f2 = evaluate_cost(Q2, Cost_Function, Function_Number, costFunctionDetails);
            f3 = evaluate_cost(Q3, Cost_Function, Function_Number, costFunctionDetails);
            [~, bestLocal] = min([f1,f2,f3]);
            if bestLocal==1, SailFish_Position(i,:)=Q1;
            elseif bestLocal==2, SailFish_Position(i,:)=Q2;
            else SailFish_Position(i,:)=Q3; end
        end

        %% Hunting Phase
        A = 4;
        ebsilon = 0.001;
        Attack_Power = A * (1 - (2 * Itr * ebsilon));
        MeanSardin = mean(Sardine_Position);
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
                % Sardine_Position(i, :) = rand() * (Elite_Position - Sardine_Position(i, :) + Attack_Power);
                theta    = alpha*pi*rand;
                r        = theta + R*rand;
                u        = (r*sin(theta))/max(eps,abs(r*sin(theta)));
                v        = (r*cos(theta))/max(eps,abs(r*cos(theta)));
                Q1       = rand()*(Best_Elite_Position - Sardine_Position(i,:) + Attack_Power);
                Q2       = Sardine_Position(i,:) + u*(Sardine_Position(i,:)-MeanSardin) + v*(Sardine_Position(i,:)-Sardine_Position(mod(i,Prey_no)+1,:));
                Q3       = QRBL(Sardine_Position(i,:), LB, UB);
                Q1 = min(max(Q1, LB), UB);
                Q2 = min(max(Q2, LB), UB);
                Q3 = min(max(Q3, LB), UB);
                f1 = evaluate_cost(Q1, Cost_Function, Function_Number, costFunctionDetails);
                f2 = evaluate_cost(Q2, Cost_Function, Function_Number, costFunctionDetails);
                f3 = evaluate_cost(Q3, Cost_Function, Function_Number, costFunctionDetails);
                [~, bestLocal] = min([f1,f2,f3]);
                if bestLocal==1, Sardine_Position(i,:)=Q1;
                elseif bestLocal==2, Sardine_Position(i,:)=Q2;
                else Sardine_Position(i,:)=Q3; end
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
        average(Itr)  =  mean(SailFish_Fitness);
        history(Itr, :, :) = SailFish_Position;
    end
end

%% Cost Evaluation Function
function f = evaluate_cost(x, costFunction, functionIndex, details)
    % Evaluate the cost function depending on benchmark type
    name = func2str(details);
    if strcmp(name, 'CEC_2005_Function') || strcmp(name, 'ProbInfo')
        f = costFunction(x);
    else
        f = costFunction(x', functionIndex);
    end
end

%% Levy flight step
function L = LevyFlight(D)
    beta = 1.5;
    sigma = (gamma(1+beta)*sin(pi*beta/2)/(gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
    u = randn(1,D)*sigma; v = randn(1,D);
    L = u./abs(v).^(1/beta);
end

%% Quadratic-based random boundary learning
function Q = QRBL(x, LB, UB)
    C = (LB+UB)/2;
    Q = rand(size(x)).*(C - x) + x;
end
