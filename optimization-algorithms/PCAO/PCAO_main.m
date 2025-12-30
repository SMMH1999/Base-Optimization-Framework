function [gbestval,gbestPos,Convergence_Curve]= PCAO(LB, UB, Dim, SearchAgents_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
    %% Init Parameters
    VarMin=LB;
    VarMax=UB;
    nVar=Dim;
    me=Max_iter;
    wMax = 0.9;
    wMin = 0.4;
    % iwt = wMax - ((wMax - wMin) / MaxIter) * MaxIter;
    iwt=0.9-(1:me).*(0.5./me);
    MaxIter=me;

    empty_particle.position = [];
    empty_particle.cost = [];
    empty_particle.best_position = [];
    empty_particle.best_cost = [];

    empty_leader.position = [];
    empty_leader.velocity = [];
    empty_leader.cost = [];
    empty_leader.best_leader.position=[];
    empty_leader.best_leader.cost=[];
    empty_leader.best_position = [];
    empty_leader.best_cost = [];

    empty_cluster.cluster_size = [];
    empty_cluster.cluster_leader = [];

    convergence=[];
    Convergence_Curve = inf(1, Max_iter);
    gbest.position=[];
    gbest.cost=inf;

    %% Create Initial Population and clusters
    Numclusters = 10;
    leader = [];
    PopSize = SearchAgents_no;
    member = PopSize /Numclusters;
    clusters = [];

    pop =[];
    for k = 1:Numclusters
        clusters{end+1} = empty_cluster;
        clusters{k}.cluster_size = member;
        clusters{k}.cluster_leader = empty_particle;
        clusters{k}.cluster_leader.position=[];
        clusters{k}.cluster_leader.cost=inf;
        pop{end+1} = [];

        for i = 1:member
            pop{k}{i} = empty_particle;
            pop{k}{i}.position = Population_Generator(1, nVar, VarMax, VarMin);
            
            pop{k}{i}.cost = CostCalculator(pop{k}{i}.position, Cost_Function, Function_Number, costFunctionDetails);

            pop{k}{i}.best_position = pop{k}{i}.position;
            pop{k}{i}.best_cost = pop{k}{i}.cost;
            
            if pop{k}{i}.best_cost < clusters{k}.cluster_leader.cost
                clusters{k}.cluster_leader.position = pop{k}{i}.best_position;
                clusters{k}.cluster_leader.cost = pop{k}{i}.best_cost;
            end
        end

        if clusters{k}.cluster_leader.cost < gbest.cost
            gbest.position = clusters{k}.cluster_leader.position;
            gbest.cost = clusters{k}.cluster_leader.cost;
            gbestval=gbest.cost;
        end
    end
    pop = OBL(pop, LB, UB, Dim, Cost_Function, costFunctionDetails, Function_Number);
    convergence=[gbest.cost];

    %% Main loop
    for it = 1:MaxIter
        for m = 1:length(pop)
            if ~isempty(pop{m})
                for i = 1: ceil(0.1 * (length(pop{m}))) + 1
                    if rand() < 0.5
                        [~, sorted_indices] = sort(cellfun(@(x) x.cost, pop{m}), 'descend');
                        sorted_structures = pop{m}(sorted_indices);

                        r_m = sorted_indices(1);
                        n = randi(length(pop));

                        condition1 = length(pop{n});
                        if m ~= n && length(pop{m}) > 1 && ~isempty(pop{n}) ...
                                && pop{m}{r_m}.cost ~= clusters{m}.cluster_leader.cost

                            pop{n}{end + 1} = empty_particle;
                            % pop{n}{condition1 + 1}.position = rand(1, nVar) .* Levy(nVar);
                            pop{n}{condition1 + 1}.position = Population_Generator(1, nVar, VarMax, VarMin) .* Levy(nVar);
                            pop{n}{condition1 + 1}.position = min(max(pop{n}{condition1 + 1}.position, VarMin), VarMax);

                            pop{n}{condition1 + 1}.cost = CostCalculator(pop{n}{condition1 + 1}.position, Cost_Function, Function_Number, costFunctionDetails);

                            pop{n}{condition1 + 1}.best_position = pop{m}{r_m}.best_position;
                            pop{n}{condition1 + 1}.best_cost = pop{m}{r_m}.best_cost;

                            if pop{n}{condition1 + 1}.cost < pop{n}{condition1 + 1}.best_cost
                                pop{n}{condition1 + 1}.best_cost = pop{n}{condition1 + 1}.cost;
                                pop{n}{condition1 + 1}.best_position = pop{n}{condition1 + 1}.position;
                            end

                            if pop{n}{condition1 + 1}.cost < clusters{n}.cluster_leader.cost
                                clusters{n}.cluster_leader.position = pop{n}{condition1 + 1}.position;
                                clusters{n}.cluster_leader.cost = pop{n}{condition1 + 1}.cost;
                            end

                            if clusters{n}.cluster_leader.cost < gbest.cost
                                gbest.position = clusters{n}.cluster_leader.position;
                                gbest.cost = clusters{n}.cluster_leader.cost;
                            end

                            pop{m}(r_m) = [];

                        end
                    end
                end
            end
        end

        k = length(pop);

        for m = 1:length(pop)
            condition = length(pop{m});
            p = rand();
            if condition > 4 * member && p < 0.5
                pop{end + 1} = [];
                clusters{end + 1} = empty_cluster;
                clusters{end}.cluster_leader = struct('position', [], 'cost', inf);

                costs = zeros(1, numel(pop{m}));

                for o = 1:numel(pop{m})
                    costs(o) = pop{m}{o}.cost;
                end

                [~, sorted_indices] = sort(costs);
                sorted_pop = pop{m}(sorted_indices);

                end_idx = length(sorted_indices);
                clusters{end}.cluster_leader.position = pop{m}{sorted_indices(end_idx - 1)}.position;
                clusters{end}.cluster_leader.cost = pop{m}{sorted_indices(end_idx - 1)}.cost;

                for i = 1:int16((0.35 * (condition - 1)) + 1)
                    [~, sorted_indices] = sort(cellfun(@(x) x.cost, pop{m}));
                    costs = zeros(1, numel(pop{m}));
                    for o = 1:numel(pop{m})
                        costs(o) = pop{m}{o}.cost;
                    end

                    [~, sorted_indices] = sort(costs);

                    sorted_pop = pop{m}(sorted_indices);
                    r_m = sorted_indices(1);
                    r_m = randi(length(pop{m}));

                    % pop{m}{r_m}.position = unifrnd(VarMin, VarMax, [1, nVar]);
                    pop{m}{r_m}.position = Population_Generator(1, nVar, VarMax, VarMin);
                    pop{m}{r_m}.position = max(pop{m}{r_m}.position, VarMin);
                    pop{m}{r_m}.position = min(pop{m}{r_m}.position, VarMax);
                    
                    pop{m}{r_m}.cost = CostCalculator(pop{m}{r_m}.position, Cost_Function, Function_Number, costFunctionDetails);

                    pop{end}{end + 1} = pop{m}{r_m};
                    pop{m}(r_m) = [];
                end

                for i = 1:length(pop{end})
                    if pop{end}{i}.cost < pop{end}{i}.best_cost
                        pop{end}{i}.best_cost = pop{end}{i}.cost;
                        pop{end}{i}.best_position = pop{end}{i}.position;
                    end

                    if pop{end}{i}.cost < clusters{end}.cluster_leader.cost
                        clusters{end}.cluster_leader.position = pop{end}{i}.position;
                        clusters{end}.cluster_leader.cost = pop{end}{i}.cost;
                    end

                    if clusters{end}.cluster_leader.cost < gbest.cost
                        gbest.position = clusters{end}.cluster_leader.position;
                        gbest.cost = clusters{end}.cluster_leader.cost;
                    end
                end
            end
        end
        k = length(pop);

        for m = 1:length(pop)
            if ~isempty(pop{m})
                for n = 1:length(pop)
                    if (m ~= n && ~isempty(pop{m}) && ~isempty(pop{n}))

                        r_m = randi ([1 length(pop{m})]);
                        q_n = randi ([1 length(pop{n})]);

                        if pop{m}{r_m}.cost < pop{n}{q_n}.cost && pop{m}{r_m}.cost < pop{n}{q_n}.best_cost && ~isempty(pop{m}) && ~isempty(pop{n})
                            %% S1
                            if pop{n}{q_n}.cost == clusters{n}.cluster_leader.cost && length(pop{n}) > 1
                                [~, sortedIndex] = sort(cellfun(@(x) x.cost, pop{n}));
                                clusters{n}.cluster_leader.position = pop{n}{sortedIndex(2)}.position;
                                clusters{n}.cluster_leader.cost = pop{n}{sortedIndex(2)}.cost;
                            end

                            % c1 = 2 - (it / Max_iter) ^ 2;
                            % c2 = 1 + (it / Max_iter) ^ 2;
                            c1 = 2 * (1 - (it / Max_iter) ^ 2);
                            c2 = 2 * (it / Max_iter) ^ 2;

                            pop{n}{q_n}.position = iwt(it).*(pop{n}{q_n}.position)+...
                                c1*rand([1 nVar]).*(pop{m}{r_m}.position-pop{n}{q_n}.position)+...
                                +c2*rand([1 nVar]).*(clusters{m}.cluster_leader.position-pop{n}{q_n}.position);
                            pop{n}{q_n}.position = min(max(pop{n}{q_n}.position, VarMin), VarMax);

                            pop{n}{q_n}.cost = CostCalculator(pop{n}{q_n}.position, Cost_Function, Function_Number, costFunctionDetails);

                            if pop{n}{q_n}.cost < pop{n}{q_n}.best_cost
                                pop{n}{q_n}.best_cost = pop{n}{q_n}.cost;
                                pop{n}{q_n}.best_position = pop{n}{q_n}.position;
                            end

                            if pop{n}{q_n}.cost < clusters{m}.cluster_leader.cost
                                clusters{m}.cluster_leader.position = pop{n}{q_n}.position;
                                clusters{m}.cluster_leader.cost = pop{n}{q_n}.cost;
                            end
                            if clusters{m}.cluster_leader.cost < gbest.cost
                                gbest.position = clusters{m}.cluster_leader.position;
                                gbest.cost = clusters{m}.cluster_leader.cost;
                            end

                            pop{m}{end + 1} = pop{n}{q_n};  % Append the element
                            pop{n}(q_n) = [];               % Delete the element

                            % c1 = 2 - (it / Max_iter) ^ 2;
                            % c2 = 1 + (it / Max_iter) ^ 2;
                            c1 = 2 * (1 - (it / Max_iter) ^ 2);
                            % c2 = 2 * (it / Max_iter) ^ 2;

                            pop{m}{r_m}.position = iwt(it).*pop{m}{r_m}.position+...
                                c1*rand([1 nVar]).*(clusters{m}.cluster_leader.position-pop{m}{r_m}.position);
                            pop{m}{r_m}.position = min(max(pop{m}{r_m}.position, VarMin), VarMax);

                            pop{m}{r_m}.cost = CostCalculator(pop{m}{r_m}.position, Cost_Function, Function_Number, costFunctionDetails);

                            if pop{m}{r_m}.cost < pop{m}{r_m}.best_cost
                                pop{m}{r_m}.best_cost = pop{m}{r_m}.cost;
                                pop{m}{r_m}.best_position = pop{m}{r_m}.position;
                            end
                            if pop{m}{r_m}.cost < clusters{m}.cluster_leader.cost
                                clusters{m}.cluster_leader.position = pop{m}{r_m}.position;
                                clusters{m}.cluster_leader.cost = pop{m}{r_m}.cost;
                            end
                            if clusters{m}.cluster_leader.cost < gbest.cost
                                gbest.position = clusters{m}.cluster_leader.position;
                                gbest.cost = clusters{m}.cluster_leader.cost;
                            end

                        elseif pop{m}{r_m}.cost < pop{n}{q_n}.cost && pop{m}{r_m}.cost > pop{n}{q_n}.best_cost && ~isempty(pop{m}) && ~isempty(pop{n})
                            %% S2

                            % c1 = 2 - (it / Max_iter) ^ 2;
                            % c2 = 1 + (it / Max_iter) ^ 2;
                            c1 = 2 * (1 - (it / Max_iter) ^ 2);
                            c2 = 2 * (it / Max_iter) ^ 2;

                            pop{n}{q_n}.position = iwt(it).*(pop{n}{q_n}.position)+...
                                c1*rand([1 nVar]).*(pop{n}{q_n}.best_position-pop{n}{q_n}.position)+...
                                +c2*rand([1 nVar]).*(clusters{m}.cluster_leader.position-pop{n}{q_n}.position);
                            pop{n}{q_n}.position = min(max(pop{n}{q_n}.position, VarMin), VarMax);

                            pop{n}{q_n}.cost = CostCalculator(pop{n}{q_n}.position, Cost_Function, Function_Number, costFunctionDetails);

                            if pop{n}{q_n}.cost < pop{n}{q_n}.best_cost
                                pop{n}{q_n}.best_cost = pop{n}{q_n}.cost;
                                pop{n}{q_n}.best_position = pop{n}{q_n}.position;
                            end
                            if pop{n}{q_n}.cost < clusters{n}.cluster_leader.cost
                                clusters{n}.cluster_leader.position = pop{n}{q_n}.position;
                                clusters{n}.cluster_leader.cost = pop{n}{q_n}.cost;
                            end
                            if clusters{n}.cluster_leader.cost < gbest.cost
                                gbest.position = clusters{n}.cluster_leader.position;
                                gbest.cost = clusters{n}.cluster_leader.cost;
                            end

                            % c1 = 2 - (it / Max_iter) ^ 2;
                            % c2= 1 + (it / Max_iter) ^ 2;
                            c1 = 2 * (1 - (it / Max_iter) ^ 2);
                            c2 = 2 * (it / Max_iter) ^ 2;

                            pop{m}{r_m}.position = iwt(it).*pop{m}{r_m}.position+...
                                c1*rand([1 nVar]).*(clusters{m}.cluster_leader.position-pop{m}{r_m}.position);
                            pop{m}{r_m}.position = min(max(pop{m}{r_m}.position, VarMin), VarMax);
                            
                            pop{m}{r_m}.cost = CostCalculator(pop{m}{r_m}.position, Cost_Function, Function_Number, costFunctionDetails);

                            if pop{m}{r_m}.cost < pop{m}{r_m}.best_cost
                                pop{m}{r_m}.best_cost = pop{m}{r_m}.cost;
                                pop{m}{r_m}.best_position = pop{m}{r_m}.position;
                            end
                            if pop{m}{r_m}.cost < clusters{m}.cluster_leader.cost
                                clusters{m}.cluster_leader.position = pop{m}{r_m}.position;
                                clusters{m}.cluster_leader.cost = pop{m}{r_m}.cost;
                            end
                            if clusters{m}.cluster_leader.cost < gbest.cost
                                gbest.position = clusters{m}.cluster_leader.position;
                                gbest.cost = clusters{m}.cluster_leader.cost;
                            end

                        elseif pop{n}{q_n}.cost < pop{m}{r_m}.cost && pop{n}{q_n}.cost < pop{m}{r_m}.best_cost && ~isempty(pop{m}) && ~isempty(pop{n})
                            %% S3
                            if(pop{m}{r_m}.cost==clusters{m}.cluster_leader.cost && length(pop{m})>1)
                                [~, sortedIndex] = sort(cellfun(@(x) x.cost, pop{m}));
                                clusters{m}.cluster_leader.position = pop{m}{sortedIndex(2)}.position;
                                clusters{m}.cluster_leader.cost = pop{m}{sortedIndex(2)}.cost;
                            end

                            % c1 = 2 - (it / Max_iter) ^ 2;
                            % c2= 1 + (it / Max_iter) ^ 2;
                            c1 = 2 * (1 - (it / Max_iter) ^ 2);
                            c2 = 2 * (it / Max_iter) ^ 2;

                            pop{m}{r_m}.position = iwt(it).*(pop{m}{r_m}.position)+...
                                c1*rand([1 nVar]).*(pop{n}{q_n}.position-pop{m}{r_m}.position)+...
                                +c2*rand([1 nVar]).*(clusters{n}.cluster_leader.position-pop{m}{r_m}.position);
                            pop{m}{r_m}.position = min(max(pop{m}{r_m}.position, VarMin), VarMax);
                            
                            pop{m}{r_m}.cost = CostCalculator(pop{m}{r_m}.position, Cost_Function, Function_Number, costFunctionDetails);
                            
                            if pop{m}{r_m}.cost < pop{m}{r_m}.best_cost
                                pop{m}{r_m}.best_cost = pop{m}{r_m}.cost;
                                pop{m}{r_m}.best_position = pop{m}{r_m}.position;
                            end
                            if pop{m}{r_m}.cost < clusters{n}.cluster_leader.cost
                                clusters{n}.cluster_leader.position = pop{m}{r_m}.position;
                                clusters{n}.cluster_leader.cost = pop{m}{r_m}.cost;
                            end
                            if clusters{n}.cluster_leader.cost < gbest.cost
                                gbest.position = clusters{n}.cluster_leader.position;
                                gbest.cost = clusters{n}.cluster_leader.cost;

                            end

                            pop{n}{end + 1} = pop{m}{r_m};  % Append the element
                            pop{m}(r_m) = [];               % Delete the element

                            % c1 = 2 - (it / Max_iter) ^ 2;
                            % c2 = 1 + (it / Max_iter) ^ 2;
                            c1 = 2 * (1 - (it / Max_iter) ^ 2);
                            % c2 = 2 * (it / Max_iter) ^ 2;

                            pop{n}{q_n}.position = iwt(it).*pop{n}{q_n}.position+...
                                c1*rand([1 nVar]).*(clusters{n}.cluster_leader.position-pop{n}{q_n}.position);

                            pop{n}{q_n}.position = min(max(pop{n}{q_n}.position, VarMin), VarMax);
                            
                            pop{n}{q_n}.cost = CostCalculator(pop{n}{q_n}.position, Cost_Function, Function_Number, costFunctionDetails);

                            if pop{n}{q_n}.cost < pop{n}{q_n}.best_cost
                                pop{n}{q_n}.best_cost = pop{n}{q_n}.cost;
                                pop{n}{q_n}.best_position = pop{n}{q_n}.position;
                            end
                            if pop{n}{q_n}.cost < clusters{n}.cluster_leader.cost
                                clusters{n}.cluster_leader.position = pop{n}{q_n}.position;
                                clusters{n}.cluster_leader.cost = pop{n}{q_n}.cost;
                            end
                            if clusters{n}.cluster_leader.cost < gbest.cost
                                gbest.position = clusters{n}.cluster_leader.position;
                                gbest.cost = clusters{n}.cluster_leader.cost;
                            end

                        elseif pop{n}{q_n}.cost < pop{m}{r_m}.cost && pop{n}{q_n}.cost > pop{m}{r_m}.best_cost && length(pop{m})>0 && length(pop{n})>0

                            % c1 = 2 - (it / Max_iter) ^ 2;
                            % c2 = 1 + (it / Max_iter) ^ 2;
                            c1 = 2 * (1 - (it / Max_iter) ^ 2);
                            c2 = 2 * (it / Max_iter) ^ 2;

                            pop{m}{r_m}.position = iwt(it).*(pop{m}{r_m}.position)+...
                                c1*rand([1 nVar]).*(pop{m}{r_m}.best_position-pop{m}{r_m}.position)+...
                                +c2*rand([1 nVar]).*(clusters{n}.cluster_leader.position-pop{m}{r_m}.position);

                            pop{m}{r_m}.position = min(max(pop{m}{r_m}.position, VarMin), VarMax);

                            pop{m}{r_m}.cost = CostCalculator(pop{m}{r_m}.position, Cost_Function, Function_Number, costFunctionDetails);

                            if pop{m}{r_m}.cost < pop{m}{r_m}.best_cost
                                pop{m}{r_m}.best_cost = pop{m}{r_m}.cost;
                                pop{m}{r_m}.best_position = pop{m}{r_m}.position;
                            end
                            if pop{m}{r_m}.cost < clusters{m}.cluster_leader.cost
                                clusters{m}.cluster_leader.position = pop{m}{r_m}.position;
                                clusters{m}.cluster_leader.cost = pop{m}{r_m}.cost;
                            end
                            if clusters{m}.cluster_leader.cost < gbest.cost
                                gbest.position = clusters{m}.cluster_leader.position;
                                gbest.cost = clusters{m}.cluster_leader.cost;
                            end

                            % c1 = 2 - (it / Max_iter) ^ 2;
                            % c2= 1 + (it / Max_iter) ^ 2;
                            c1 = 2 * (1 - (it / Max_iter) ^ 2);
                            % c2 = 2 * (it / Max_iter) ^ 2;

                            pop{n}{q_n}.position = iwt(it).*pop{n}{q_n}.position+...
                                c1*rand([1 nVar]).*(clusters{n}.cluster_leader.position-pop{n}{q_n}.position);
                            pop{n}{q_n}.position = min(max(pop{n}{q_n}.position, VarMin), VarMax);
                            
                            pop{n}{q_n}.cost = CostCalculator(pop{n}{q_n}.position, Cost_Function, Function_Number, costFunctionDetails);
                            
                            if pop{n}{q_n}.cost < pop{n}{q_n}.best_cost
                                pop{n}{q_n}.best_cost = pop{n}{q_n}.cost;
                                pop{n}{q_n}.best_position = pop{n}{q_n}.position;
                            end
                            if pop{n}{q_n}.cost < clusters{n}.cluster_leader.cost
                                clusters{n}.cluster_leader.position = pop{n}{q_n}.position;
                                clusters{n}.cluster_leader.cost = pop{n}{q_n}.cost;
                            end
                            if clusters{n}.cluster_leader.cost < gbest.cost
                                gbest.position = clusters{n}.cluster_leader.position;
                                gbest.cost = clusters{n}.cluster_leader.cost;
                            end
                        end
                    end
                end
            end

            if clusters{m}.cluster_leader.cost < gbest.cost
                gbest.position = clusters{m}.cluster_leader.position;
                gbest.cost = clusters{m}.cluster_leader.cost;
            end
        end

        gbestval=gbest.cost;
        Convergence_Curve(it) = gbest.cost;
        gbestPos=gbest.position;
    end
end

function [costs] = CostCalculator(Population, CF, FN, CFD)
    popSize = size(Population, 1);
    costs = inf(1, popSize);
    for i = 1:popSize
        if strcmp(func2str(CFD), 'CEC_2005_Function')
            costs(i) = CF(Population(i, :));         % For objective function 2005
        elseif strcmp(func2str(CFD), 'ProbInfo')    
            costs(i) = CF(Population(i, :));         % For objective function Real Word Problems
        else
            costs(i) = CF(Population(i, :)', FN);    % For after objective function 2005
        end
    end
end

function o = Levy(d)
    beta = 1.5;
    sigma = (gamma(1 + beta) * sin(pi * beta / 2) / (gamma((1 + beta) / 2) * beta * 2 ^ ((beta - 1) / 2))) ^ (1 / beta);
    u = randn(1, d) * sigma;
    v = randn(1, d);
    step = u ./ abs(v) .^ (1 / beta);
    o = step;
end

function [pop] = OBL(pop, LB, UB, Dim, Cost_Function, costFunctionDetails, Function_Number)
    N = length(pop);
    oblPop = pop;

    for i = 1:N
        for j = 1:length(pop{i})
            oblPop{i}{j}.position = LB + UB - pop{i}{j}.position;
            oblPop{i}{j}.position = min(max(oblPop{i}{j}.position, LB), UB);

            oblPop{i}{j}.cost = CostCalculator(oblPop{i}{j}.position, Cost_Function, Function_Number, costFunctionDetails);

            if oblPop{i}{j}.cost < pop{i}{j}.cost
                pop{i}{j}.best_position = oblPop{i}{j}.position;
                pop{i}{j}.best_cost = oblPop{i}{j}.cost;
            else
                pop{i}{j}.best_position = pop{i}{j}.position;
                pop{i}{j}.best_cost = pop{i}{j}.cost;
            end
        end
    end
end