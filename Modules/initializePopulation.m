function Population = initializePopulation(popSize, dim, varMin, varMax, varargin)
    %INITIALIZEPOPULATION Generates the initial population for optimization algorithms.
    %
    %   Population = initializePopulation(popSize, dim, varMin, varMax)
    %   creates a matrix of size (popSize x dim) with random values uniformly
    %   distributed between varMin and varMax.
    %
    %   INPUTS:
    %       popSize - Number of individuals in the population (scalar)
    %       dim     - Number of decision variables (scalar)
    %       varMin  - Lower bound for variables (scalar or vector)
    %       varMax  - Upper bound for variables (scalar or vector)
    %
    %   OPTIONAL INPUTS (Name-Value pairs, not currently used):
    %       'Distribution' - Type of random distribution:
    %                        'uniform' (default), 'normal', 'fixed', etc.
    %       'Seed'         - Random number generator seed for reproducibility
    %
    %   OUTPUT:
    %       Population - A (popSize x dim) matrix of initial solutions
    %
    %   EXAMPLE:
    %       Pop = initializePopulation(10, 5, -10, 10);
    %
    %   NOTE:
    %       This function is designed to be compatible with various optimization
    %       algorithms and problem settings. Additional random distribution
    %       options will be implemented in the future.
    %
    %   Author: [Your Name]
    %   Date:   [Date]
    %   ----------------------------------------------------------------------

    % === Parse optional inputs (future use) ===
    p = inputParser;
    addParameter(p, 'Distribution', 'uniform'); % Reserved for future
    addParameter(p, 'Seed', []);                 % Optional seed
    parse(p, varargin{:});
    opts = p.Results;

    % === Optional reproducibility seed ===
    if ~isempty(opts.Seed)
        rng(opts.Seed);
    end

    % === Ensure bounds are column vectors if needed ===
    if isscalar(varMin)
        varMin = repmat(varMin, 1, dim);
    end
    if isscalar(varMax)
        varMax = repmat(varMax, 1, dim);
    end

    % === Uniform random initialization (default) ===
    Population = rand(popSize, dim) .* (varMax - varMin) + varMin;

    % === Placeholder for future distribution types ===
    % switch lower(opts.Distribution)
    %     case 'uniform'
    %         % Already handled above
    %     case 'normal'
    %         % To be implemented
    %     case 'fixed'
    %         % To be implemented
    %     otherwise
    %         error('Unknown distribution type: %s', opts.Distribution);
    % end

end
