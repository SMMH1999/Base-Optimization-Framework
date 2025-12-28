function [algorithmsName, algorithms] = Get_algorithm(algorithmFileAddress)
    % GET_ALGORITHM
    % Reads algorithm names from a text file and converts them into function handles.
    %
    % Inputs:
    %   algorithmFileAddress - Path to the file containing algorithm names (one per line)
    %
    % Outputs:
    %   algorithmsName - List of algorithm names (string array)
    %   algorithms     - Cell array of function handles corresponding to the names

    %% Read the names of algorithms from the file
    algorithmsName = readlines(algorithmFileAddress);

    %% Convert the algorithm names from string to function handles
    algorithms = cell(size(algorithmsName, 1), 1);
    for i = 1 : size(algorithmsName, 1)
        algorithms{i} = str2func(algorithmsName(i));
    end
end
