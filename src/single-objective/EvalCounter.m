classdef EvalCounter < handle
    properties
        count   (1,1) double  = 0
        maxFEs  (1,1) double  = inf
        warned  (1,1) logical = false
        warnItr (1,1) double  = NaN   % estimated iteration when exceeded
    end
    methods
        function obj = EvalCounter(maxFEs)
            if nargin > 0 && ~isempty(maxFEs)
                obj.maxFEs = maxFEs;
            end
        end
    end
end
