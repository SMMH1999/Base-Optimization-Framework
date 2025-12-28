function [gBestScore, gBest, Convergence_Curve] = WHO(LB, UB, Dim, Hours_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
    if size(UB, 2)  ==  1
        UB = ones(1, Dim) * UB;
        LB = ones(1, Dim) * LB;
    end
    PS = 0.2;     % Stallions Percentage
    PC = 0.13;    % Crossover Percentage
    NStallion = ceil(PS * Hours_no); % number Stallion
    Nfoal = Hours_no - NStallion;
    Convergence_Curve = inf(1, Max_iter);
    gBest = zeros(1, Dim);
    gBestScore = inf;

    %% Create initial population
    empty.pos = [];
    empty.cost = [];

    group = repmat(empty,Nfoal,1);
    for i = 1:Nfoal
        group(i).pos = Population_Generator(1, Dim, UB, LB);
        % Calculate the objective function for each search agent
        if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
            % For objective function 2005
            group(i).cost = Cost_Function(group(i).pos);
        elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
            % For objective function Real Word Problems
            group(i).cost = Cost_Function(group(i).pos);
        else
            % For after objective function 2005
            group(i).cost = Cost_Function(group(i).pos', Function_Number);
        end
    end

    Stallion = repmat(empty,NStallion,1);
    for i = 1:NStallion
        Stallion(i).pos = Population_Generator(1, Dim, UB, LB);
        % Calculate the objective function for each search agent
        if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
            % For objective function 2005
            Stallion(i).cost = Cost_Function(Stallion(i).pos);
        elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
            % For objective function Real Word Problems
            Stallion(i).cost = Cost_Function(Stallion(i).pos);
        else
            % For after objective function 2005
            Stallion(i).cost = Cost_Function(Stallion(i).pos', Function_Number);
        end
    end
    ngroup = length(group);
    a = randperm(ngroup);
    group = group(a);
    i = 0;
    k = 1;
    for j = 1:ngroup
        i = i + 1;
        Stallion(i).group(k) = group(j);
        if i == NStallion
            i = 0;
            k = k + 1;
        end
    end
    Stallion = exchange(Stallion);
    [value,index] = min([Stallion.cost]);
    WH = Stallion(index); % global
    gBest = WH.pos;
    gBestScore = WH.cost;
    Convergence_Curve(1) = WH.cost;

    %% Main Loop
    l = 2; % Loop counter
    while l < Max_iter + 1
        TDR = 1-l*((1)/Max_iter);
        for i = 1:NStallion

            ngroup = length(Stallion(i).group);
            [~,index] = sort([Stallion(i).group.cost]);
            Stallion(i).group = Stallion(i).group(index);

            for j = 1:ngroup

                if rand > PC
                    z = rand(1,Dim) < TDR;
                    r1 = rand;
                    r2 = rand(1,Dim);
                    idx = (z == 0);
                    r3 = r1.*idx + r2.*~idx;
                    rr = -2 + 4*r3;
                    Stallion(i).group(j).pos =  2*r3.*cos(2*pi*rr).*(Stallion(i).pos-Stallion(i).group(j).pos) + (Stallion(i).pos);
                else
                    A = randperm(NStallion);
                    A(A == i) = [];
                    a = A(1);
                    c = A(2);
                    %     B = randperm(ngroup);
                    %     BB = randperm(ngroup);
                    %     b1 = B(1);b2 = BB(1);
                    x1 = Stallion(c).group(end).pos;
                    x2 = Stallion(a).group(end).pos;
                    y1 = (x1 + x2)/2;   % Crossover
                    Stallion(i).group(j).pos = y1;
                end

                Stallion(i).group(j).pos = max(min(Stallion(i).group(j).pos,UB),LB);

                % Calculate the objective function for each search agent
                if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
                    % For objective function 2005
                    Stallion(i).group(j).cost = Cost_Function(Stallion(i).group(j).pos);
                elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
                    % For objective function Real Word Problems
                    Stallion(i).group(j).cost = Cost_Function(Stallion(i).group(j).pos);
                else
                    % For after objective function 2005
                    Stallion(i).group(j).cost = Cost_Function(Stallion(i).group(j).pos', Function_Number);
                end


            end
            R = rand();
            if R < 0.5
                k =  2*r3.*cos(2*pi*rr).*(WH.pos-(Stallion(i).pos)) + WH.pos;
            else
                k =  2*r3.*cos(2*pi*rr).*(WH.pos-(Stallion(i).pos))-WH.pos;
            end
            k = max(min(k,UB),LB);
            % Calculate the objective function for each search agent
            if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
                % For objective function 2005
                fk = Cost_Function(k);
            elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
                % For objective function Real Word Problems
                fk = Cost_Function(k);
            else
                % For after objective function 2005
                fk = Cost_Function(k', Function_Number);
            end
            if fk < Stallion(i).cost
                Stallion(i).pos = k;
                Stallion(i).cost = fk;
            end
        end
        Stallion = exchange(Stallion);
        [value,index] = min([Stallion.cost]);
        if value < WH.cost
            WH = Stallion(index);
        end
        gBest = WH.pos;
        gBestScore = WH.cost;
        Convergence_Curve(l) = WH.cost;
        l = l  +  1;
    end
end

function Stallion = exchange(Stallion)
    nStallion=length(Stallion);
    for i=1:nStallion
        [value,index]=min([Stallion(i).group.cost]);
        if value<Stallion(i).cost
            bestgroup=Stallion(i).group(index);
            Stallion(i).group(index).pos=Stallion(i).pos;
            Stallion(i).group(index).cost=Stallion(i).cost;
            Stallion(i).pos=bestgroup.pos;
            Stallion(i).cost=bestgroup.cost;
        end
    end
end