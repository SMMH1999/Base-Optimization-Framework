function [Best_score, Best_pos, cg_curve] = WEO(lb, ub, dim, SearchAgents_no, Max_iteration, Cost_Function, Function_Number, costFunctionDetails)
    % WEO (Water Evaporation Optimization) - RW-stable version
    % امضا مطابق پروژه شما:
    % [Best_score, Best_pos, cg_curve] = WEO(lb, ub, dim, N, Tmax, Cost_Function, Function_Number, costFunctionDetails)

    % ───────────── تنظیم کران‌ها ─────────────
    lb = reshape(lb, 1, []);
    ub = reshape(ub, 1, []);
    if numel(lb) == 1, lb = repmat(lb, 1, dim); end
    if numel(ub) == 1, ub = repmat(ub, 1, dim); end

    cg_curve = zeros(1, Max_iteration);

    % پارامترها
    Delta_max = (ub - lb) / 10;
    Food_fitness  = inf;
    Food_pos      = zeros(1, dim);
    Enemy_fitness = -inf;
    Enemy_pos     = zeros(1, dim);

    % جمعیت اولیه
    X       = Population_Generator(SearchAgents_no, dim, ub, lb);
    X       = clamp_to_bounds(X, lb, ub);   % FIX #0: اطمینان از درون‌بازه بودن
    Fitness = zeros(1, SearchAgents_no);
    DeltaX  = Population_Generator(SearchAgents_no, dim, ub, lb) - X;  % حرکت اولیه کوچک

    % Lotus Effect
    R0          = 2;     % شعاع اولیه جست‌وجوی محلی
    beta        = 10;    % تکرارهای جست‌وجوی محلی
    probability = 0.3;

    % یک ارزیابِ ایمن برای RW/CEC
    safeEval = @(xrow) safe_evaluate(xrow, lb, ub, Cost_Function, Function_Number, costFunctionDetails);

    % ارزیابی اولیه
    for i = 1:SearchAgents_no
        Fitness(i) = safeEval(X(i, :));     % FIX #1: ارزیابی فقط با ورودی گیره‌شده
        if Fitness(i) < Food_fitness
            Food_fitness = Fitness(i);
            Food_pos     = X(i, :);
        end
        if Fitness(i) > Enemy_fitness
            Enemy_fitness = Fitness(i);
            Enemy_pos     = X(i, :);
        end
    end

    for iter = 1:Max_iteration
        % به‌روزرسانی شعاع/وزن‌ها
        r    = (ub - lb) / (Max_iteration - iter + 1e-6);
        w    = 0.9 - iter * ((0.9 - 0.4) / Max_iteration);
        my_c = 0.1 - iter * ((0.1 - 0) / (Max_iteration / 2));
        if my_c < 0, my_c = 0; end
        f = 2 * rand;
        e = my_c;

        % --- حلقه‌ی عامل‌ها ---
        for i = 1:SearchAgents_no
            % پیدا کردن همسایه‌ها در شعاع r (محور-به-محور)
            neighbours_no = 0;
            Neighbours_DeltaX = [];
            Neighbours_X      = [];
            for j = 1:SearchAgents_no
                if j == i, continue; end
                Dist2 = compwise_abs_diff(X(i, :), X(j, :)); % بردار فاصلهٔ محور-به-محور
                if all(Dist2 <= r) && any(Dist2 ~= 0)
                    neighbours_no = neighbours_no + 1;
                    Neighbours_DeltaX(neighbours_no, :) = DeltaX(j, :); %#ok<AGROW>
                    Neighbours_X(neighbours_no, :)      = X(j, :);      %#ok<AGROW>
                end
            end

            % جاذبه به غذا و دافعه از دشمن (محور-به-محور)
            Dist2Food = compwise_abs_diff(X(i, :), Food_pos);
            F_vec     = (Dist2Food <= r) .* (Food_pos - X(i, :));
            Dist2Enemy= compwise_abs_diff(X(i, :), Enemy_pos);
            Enemy_vec = (Dist2Enemy <= r) .* (Enemy_pos + X(i, :));

            % نگهداشت درون بازه هنگام پرش‌های بزرگ
            for j = 1:dim
                if X(i, j) > ub(j)
                    X(i, j) = ub(j);      % FIX #2: برگرداندن به ub (نه lb)
                    DeltaX(i, j) = 0;
                elseif X(i, j) < lb(j)
                    X(i, j) = lb(j);      % FIX #2: برگرداندن به lb (نه ub)
                    DeltaX(i, j) = 0;
                end
            end

            if rand() <= probability
                % اکسپلوریشن/اکسپلویتیشن بر اساس حضور در شعاع غذا
                if any(Dist2Food > r)
                    if neighbours_no > 1
                        % به‌روزرسانی سرعت/موقعیت با همسایه‌ها
                        for j = 1:dim
                            DeltaX(i, j) = w * DeltaX(i, j);
                            DeltaX(i, j) = min(max(DeltaX(i, j), -Delta_max(j)), Delta_max(j));
                            X(i, j)      = X(i, j) + DeltaX(i, j);
                        end
                    else
                        % پرش لوی
                        X(i, :)   = X(i, :) + Levy(dim) .* X(i, :);
                        DeltaX(i, :) = 0;
                    end
                else
                    % حرکت به سمت Food و دوری از Enemy
                    for j = 1:dim
                        DeltaX(i, j) = (f * F_vec(j) + e * Enemy_vec(j)) + w * DeltaX(i, j);
                        DeltaX(i, j) = min(max(DeltaX(i, j), -Delta_max(j)), Delta_max(j));
                        X(i, j)      = X(i, j) + DeltaX(i, j);
                    end
                end
            else
                % ── Lotus Effect: جست‌وجوی محلی ──
                Rloc = R0; % FIX #3: هر عامل، R مستقل دارد
                for b = 1:beta
                    stepSize = Rloc * (X(i, :) - Food_pos);
                    X(i, :)  = X(i, :) - stepSize;
                    % کاهش شعاع متناسب با پیشرفت
                    Rloc = 2 * exp(-1 * (2 * iter / Max_iteration) ^ 2);
                end
            end

            % ── Drop Water in pits ──
            [~, bestAgentIndex] = min(Fitness);
            bestAgent   = X(bestAgentIndex, :);
            velocities  = DeltaX; % کپی
            % مولفه‌ی وزنی
            W = (((1 - (iter / (Max_iteration + eps))) ^ (2 * randn())) .* ...
                (rand(1, dim) .* (iter / Max_iteration)) .* rand(1, dim));

            pits        = zeros(beta, dim);
            pitFitness  = zeros(1, beta);

            for j = 1:beta
                randAgent = X(randi(SearchAgents_no), :);
                delta     = W .* (rand * randAgent - rand * X(i, :)) .* norm(bestAgent - X(i, :));
                pits(j, :) = X(i, :) + randn() * delta;

                % FIX #4: کاندید را قبل از ارزیابی، گیره کن
                cand = min(max(pits(j, :), lb), ub);
                pitFitness(j) = safeEval(cand);
            end

            % ظرفیت‌ها
            f_max = max(max(pitFitness), Fitness(i));
            f_min = min(min(pitFitness), Fitness(i));

            den = abs(f_min - f_max);
            if den == 0, den = eps; end  % FIX #5: جلوگیری از تقسیم بر صفر

            const = 2;
            dropletCapacities = const * (abs(Fitness(i) - f_max)) ./ den;
            pitCapacities     = const * (abs(pitFitness   - f_max)) ./ den;

            q_min = 0; q_max = 1;
            while true
                bi_pitCapacities = pitCapacities > dropletCapacities;
                if any(bi_pitCapacities)
                    [~, bestPitIndex] = max(pitCapacities);

                    if pitCapacities(bestPitIndex) > dropletCapacities
                        pitCapacities(bestPitIndex) = pitCapacities(bestPitIndex) - dropletCapacities;

                        movement_vector   = pits(bestPitIndex, :) - X(i, :);
                        q                 = q_min + iter * ((q_max - q_min) / Max_iteration);
                        velocities(i, :)  = q * velocities(i, :) + movement_vector;
                        X(i, :)           = X(i, :) + velocities(i, :);
                        break;
                    else
                        dropletCapacities             = dropletCapacities - pitCapacities(bestPitIndex);
                        pitCapacities(bestPitIndex)   = 0;
                        [~, bestPitIndex]             = max(pitCapacities);
                        if ~isempty(bestPitIndex) && pitCapacities(bestPitIndex) > 0
                            X(i, :)          = X(i, :) + 0.5 * (pits(bestPitIndex, :) - X(i, :));
                            velocities(i, :) = 0.5 * velocities(i, :);
                        else
                            break;
                        end
                    end
                else
                    break;
                end
            end

            % اطمینان از درون‌بازه بودن پس از به‌روزرسانی
            X(i, :) = min(max(X(i, :), lb), ub);

            % ارزیابی و به‌روزرسانی بهترین‌ها
            Fitness(i) = safeEval(X(i, :));
            if Fitness(i) < Food_fitness
                Food_fitness = Fitness(i);
                Food_pos     = X(i, :);
            end
            if Fitness(i) > Enemy_fitness
                Enemy_fitness = Fitness(i);
                Enemy_pos     = X(i, :);
            end
        end % end for each agent

        Best_score     = Food_fitness;
        Best_pos       = Food_pos;
        cg_curve(iter) = Best_score; % (در صورت تمایل می‌توانید غیر افزایشی‌اش کنید)
        % cg_curve(iter) = (iter==1) * Best_score + (iter>1)*min(cg_curve(iter-1), Best_score);
    end
end

% ───────────────────────── کمک‌تابع‌ها ─────────────────────────

function x = clamp_to_bounds(x, lb, ub)
    x = min(max(x, lb), ub);
end

function d = compwise_abs_diff(a, b)
    % فاصلهٔ محور به محور (هم‌ارز |a-b| برای هر مؤلفه)
    d = abs(a - b);
end

function val = safe_evaluate(xrow, lb, ub, Cost_Function, Function_Number, costFunctionDetails)
    % ارزیابی ایمن: همیشه قبل از فراخوانی، گیره می‌کند؛
    % و امضای درست را برای RW/CEC رعایت می‌کند.
    xrow = clamp_to_bounds(xrow, lb, ub);
    if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function')
        val = Cost_Function(xrow);
    elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
        val = Cost_Function(xrow);
    else
        val = Cost_Function(xrow', Function_Number);
    end
end

function o = Levy(d)
    beta  = 1.5;
    % فرمول دقیق سیگما
    sigma = (gamma(1 + beta) * sin(pi * beta / 2) / ...
        (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);
    u     = randn(1, d) * sigma;
    v     = randn(1, d);
    step  = u ./ abs(v).^(1 / beta);
    o     = 0.01 * step;
end
