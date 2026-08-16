function fval=FixIfBelowFmin(fval,funcNum,cecName)
%FIXIFBELOWFMIN Canonicalize values that reach the benchmark optimum.
%
% The established function name is retained for framework compatibility.
% Values within the benchmark-specific absolute tolerance are replaced by
% the exact hard-coded optimum. Values outside the tolerance are unchanged.

%% Reference data
reference=benchmarkReference(cecName);

if ~isscalar(funcNum) || ~isnumeric(funcNum) || ~isfinite(funcNum) || ...
        funcNum<1 || fix(funcNum)~=funcNum || funcNum>numel(reference.optimumValues)
    return;
end

if ~isnumeric(fval) || isempty(fval)
    return;
end

%% Canonicalization
optimum=reference.optimumValues(funcNum);
tolerance=reference.canonicalTolerance(funcNum);
finiteMask=isfinite(fval);
reachedMask=false(size(fval));
reachedMask(finiteMask)=abs(double(fval(finiteMask))-double(optimum))<=tolerance;
fval(reachedMask)=optimum;
end
