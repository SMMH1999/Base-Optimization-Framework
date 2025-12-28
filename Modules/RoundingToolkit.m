% Script: RoundingToolkit.m
% Description: Determines optimal rounding digits based on known Fmin values of benchmark functions
% Usage: digits = RoundingToolkit(Function_Number, cecName);

function digits = RoundingToolkit(Function_Number, cecName)
    % Mapping of CEC suite and Fmin values
    persistent roundingMap
    if isempty(roundingMap)
        roundingMap = containers.Map('KeyType','char','ValueType','any');

        % CEC 2005
        roundingMap('2005') = [...
            0, 0, 0, 0, 0, 0, 0, -12569.487, 0, 0, 0, 0, 0, 1, 0.0003, ...
            -1.0316, 0.398, 3, -3.86, -3.32, -10.1532, -10.4028, -10.5363];

        % CEC 2014
        roundingMap('2014') = 100 * (1:30);

        % CEC 2017
        roundingMap('2017') = 100 * (1:29);

        % CEC 2019
        roundingMap('2019') = ones(1, 10);

        % CEC 2020
        roundingMap('2020') = [100, 1100, 700, 1900, 1700, 1600, 2100, 2200, 2400, 2500];

        % CEC 2022
        roundingMap('2022') = [300, 400, 600, 800, 900, 1800, 2000, 2200, 2300, 2400, 2600, 2700];
    end

    cecKey = num2str(cecName);
    if ~isKey(roundingMap, cecKey)
        digits = 6;  % default fallback
        return;
    end
    fminValues = roundingMap(cecKey);

    if Function_Number > numel(fminValues)
        digits = 6;
        return;
    end

    fmin = abs(fminValues(Function_Number));
    if fmin == 0
        digits = 8;
    elseif fmin < 1e-3
        digits = 10;
    elseif fmin < 1
        digits = 6;
    elseif fmin < 10
        digits = 4;
    elseif fmin < 100
        digits = 3;
    else
        digits = 2;
    end
end
