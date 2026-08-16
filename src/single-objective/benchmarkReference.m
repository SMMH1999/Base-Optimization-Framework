function reference=benchmarkReference(cecName)
%BENCHMARKREFERENCE Return hard-coded optima and canonicalization tolerances.
%
% Inputs:
%   cecName - Framework CEC index or year label
%
% Outputs:
%   reference - Struct containing optimumValues and canonicalTolerance

%% Benchmark identification
cecKey=normalizeCecKey(cecName);

%% Reference data
reference=struct();
reference.name=cecKey;

switch cecKey
    case "2005"
        % This framework slot contains the established 23 classical
        % benchmark functions F1-F23, not the official 25-function CEC'05 set.
        reference.optimumValues=[ ...
            0,0,0,0,0,0,0,-12569.486618173014,0,0,0,0,0, ...
            0.998003837794450,0.000307485987806,-1.031628453489878, ...
            0.397887357729738,3,-3.862782147820755,-3.322368011415456, ...
            -10.153199679058229,-10.402940566818662,-10.536409816692045];
        % This classic 23-function set has no official CEC'05 success threshold.
        % Keep the framework reporting threshold separate from source-code EPS.
        reference.canonicalTolerance=1e-8*ones(1,23);

    case "2014"
        reference.optimumValues=100*(1:30);
        reference.canonicalTolerance=1e-8*ones(1,30);

    case "2017"
        % F2 is skipped by the framework, but original numbering is retained.
        reference.optimumValues=100*(1:30);
        reference.canonicalTolerance=1e-8*ones(1,30);

    case "2019"
        reference.optimumValues=ones(1,10);
        % CEC2019 is a 100-digit challenge. This tolerance is only the
        % framework's MATLAB-double canonicalization threshold.
        reference.canonicalTolerance=1e-14*ones(1,10);

    case "2020"
        reference.optimumValues=[100,1100,700,1900,1700,1600,2100,2200,2400,2500];
        reference.canonicalTolerance=1e-8*ones(1,10);

    case "2022"
        reference.optimumValues=[300,400,600,800,900,1800,2000,2200,2300,2400,2600,2700];
        reference.canonicalTolerance=1e-8*ones(1,12);

    otherwise
        error('benchmarkReference:UnknownBenchmark', ...
            'Unsupported benchmark identifier: %s',string(cecName));
end
end

function cecKey=normalizeCecKey(cecName)
%NORMALIZECECKEY Convert framework indices and year labels to one key.
if isnumeric(cecName) && isscalar(cecName)
    cecNames=["2005","2014","2017","2019","2020","2022"];
    if isfinite(cecName) && cecName>=1 && cecName<=numel(cecNames) && ...
            fix(cecName)==cecName
        cecKey=cecNames(cecName);
        return;
    end
end

cecKey=erase(upper(strtrim(string(cecName))),"CEC");
end
