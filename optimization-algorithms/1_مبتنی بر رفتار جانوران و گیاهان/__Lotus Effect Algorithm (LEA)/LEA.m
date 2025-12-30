function [Best_score,Best_pos,cg_curve]=LEA(lb, ub, dim, SearchAgents_no, Max_iteration, Cost_Function, Function_Number, costFunctionDetails)
    cg_curve=zeros(1,Max_iteration);

    if size(ub,2)==1
        ub=ones(1,dim)*ub;
        lb=ones(1,dim)*lb;
    end

    r=(ub-lb)/10;
    Delta_max=(ub-lb)/10;

    Food_fitness=inf;
    Food_pos=zeros(1, dim);

    Enemy_fitness=-inf;
    Enemy_pos=zeros(1, dim);

    X = Population_Generator(SearchAgents_no, dim, ub, lb);
    Fitness=zeros(1, SearchAgents_no);

    DeltaX = Population_Generator(SearchAgents_no, dim, ub, lb);

    for iter=1:Max_iteration

        r=(ub-lb)/4+((ub-lb)*(iter/Max_iteration)*2);

        w=0.9-iter*((0.9-0.4)/Max_iteration);

        my_c=0.1-iter*((0.1-0)/(Max_iteration/2));
        if my_c<0
            my_c=0;
        end

        s=2*rand*my_c;
        a=2*rand*my_c;
        c=2*rand*my_c;
        f=2*rand;
        e=my_c;

        for i=1:SearchAgents_no
            %% Calculate the objective function for each search agent
            if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
                % For objective function 2005
                Fitness(1,i) = Cost_Function(X(i, :));
            elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
                % For objective function Real Word Problems
                Fitness(1,i) = Cost_Function(X(i, :));
            else
                % For after objective function 2005
                Fitness(1,i) = Cost_Function(X(i, :)', Function_Number);
            end

            if Fitness(1,i)<Food_fitness
                Food_fitness=Fitness(1,i);
                Food_pos=X(i, :);
            end

            if Fitness(1,i)>Enemy_fitness
                if all(X(i, :)<ub')
                    if all(X(i, :)>lb')
                        Enemy_fitness=Fitness(1,i);
                        Enemy_pos=X(i, :);
                    end
                end
            end
        end

        for i=1:SearchAgents_no
            index=0;
            neighbours_no=0;

            clear Neighbours_DeltaX
            clear Neighbours_X
            %find the neighbouring solutions
            for j=1:SearchAgents_no
                Dist2Enemy=distance(X(i, :),X(j, :));
                if (all(Dist2Enemy<=r) && all(Dist2Enemy~=0))
                    index=index+1;
                    neighbours_no=neighbours_no+1;
                    Neighbours_DeltaX(index, :)=DeltaX(j, :);
                    Neighbours_X(index, :)=X(j, :);
                end
            end


            S=zeros(1, dim);
            if neighbours_no>1
                for k=1:neighbours_no
                    S=S+(Neighbours_X(k, :)-X(i, :));
                end
                S=-S;
            else
                S=zeros(1, dim);
            end

            if neighbours_no>1
                A=(sum(Neighbours_DeltaX))/neighbours_no;
            else
                A=DeltaX(i, :);
            end

            if neighbours_no>1
                C_temp=(sum(Neighbours_X))/neighbours_no;
            else
                C_temp=X(i, :);
            end

            C=C_temp-X(i, :);

            Dist2Food=distance(X(i, :),Food_pos(1, :));
            if all(Dist2Food<=r)
                F=Food_pos-X(i, :);
            else
                F=0;
            end

            Dist2Enemy=distance(X(i, :),Enemy_pos(1, :));
            if all(Dist2Enemy<=r)
                Enemy=Enemy_pos+X(i, :);
            else
                Enemy=zeros(1, dim);
            end

            for tt=1:dim
                if X(i, tt)>ub(tt)
                    X(i, tt)=lb(tt);
                    DeltaX(i, tt)=rand;
                end
                if X(i, tt)<lb(tt)
                    X(i, tt)=ub(tt);
                    DeltaX(i, tt)=rand;
                end
            end

            if any(Dist2Food>r)
                if neighbours_no>1
                    for j=1:dim
                        DeltaX(i, j)=w*DeltaX(i, j)+rand*A(1, j)+rand*C(1, j)+rand*S(1, j);
                        if DeltaX(i, j)>Delta_max(j)
                            DeltaX(i, j)=Delta_max(j);
                        end
                        if DeltaX(i, j)<-Delta_max(j)
                            DeltaX(i, j)=-Delta_max(j);
                        end
                        X(i, j)=X(i, j)+DeltaX(i, j);
                    end
                else
                    % Eq. (3.8)
                    X(i, :)= X(i, :) + Levy(dim) .* X(i, :);
                    DeltaX(i, :)=0;
                end
            else
                for j=1:dim
                    % Eq. (3.6)
                    DeltaX(i, j)=(a*A(1, j)+c*C(1, j)+s*S(1, j)+f*F(1, j)+e*Enemy(1, j)) + w*DeltaX(i, j);
                    if DeltaX(i, j)>Delta_max(j)
                        DeltaX(i, j)=Delta_max(j);
                    end
                    if DeltaX(i, j)<-Delta_max(j)
                        DeltaX(i, j)=-Delta_max(j);
                    end
                    X(i, j)=X(i, j)+DeltaX(i, j);
                end
            end

            Flag4ub=X(i, :)>ub;
            Flag4lb=X(i, :)<lb;
            X(i, :)=(X(i, :).*(~(Flag4ub+Flag4lb)))+ub.*Flag4ub+lb.*Flag4lb;

        end
        Best_score=Food_fitness;
        Best_pos=Food_pos;

        cg_curve(iter)=Best_score;
    end
end

