function ranks=rankCompetitionValues(values,direction)
%RANKCOMPETITIONVALUES Rank values using standard competition ranking.
%
% Equal values receive the same rank. The next rank skips the occupied
% positions, e.g. [10 10 5] ranked in descending order becomes [1 1 3].

values=double(values(:)');
ranks=nan(size(values));
finiteMask=isfinite(values);
finiteValues=values(finiteMask);

if isempty(finiteValues)
    return;
end

finiteRanks=zeros(size(finiteValues));
isMax=lower(string(direction))=="max";

for valueIndex=1:numel(finiteValues)
    if isMax
        finiteRanks(valueIndex)=1+sum(finiteValues>finiteValues(valueIndex));
    else
        finiteRanks(valueIndex)=1+sum(finiteValues<finiteValues(valueIndex));
    end
end

ranks(finiteMask)=finiteRanks;
end
