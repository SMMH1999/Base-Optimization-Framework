function ranks=rankCanonicalValues(values,direction)
%RANKCANONICALVALUES Return Friedman-compatible midranks.
%
% Equal numerical values receive MATLAB tied midranks. Benchmark-specific
% equivalence must be resolved before this function is called. This helper is
% reserved for statistical rank analysis, not Conclusions competition ranks.

values=double(values(:)');
ranks=nan(size(values));
finiteMask=isfinite(values);

if ~any(finiteMask)
    return;
end

finiteValues=values(finiteMask);
if lower(string(direction))=="max"
    finiteValues=-finiteValues;
end

ranks(finiteMask)=tiedrank(finiteValues);
end
