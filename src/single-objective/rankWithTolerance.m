function [ranks,canonicalValues]=rankWithTolerance(values,direction,absoluteTolerance,ulpFactor)
%RANKWITHTOLERANCE Rank finite values using numerical-equivalence groups.

values=double(values(:)');
direction=lower(string(direction));

if direction~="min" && direction~="max"
    error('rankWithTolerance:InvalidDirection', ...
        'Direction must be "min" or "max".');
end

if ~isscalar(absoluteTolerance) || ~isfinite(absoluteTolerance) || absoluteTolerance<0
    error('rankWithTolerance:InvalidAbsoluteTolerance', ...
        'absoluteTolerance must be a finite nonnegative scalar.');
end

if ~isscalar(ulpFactor) || ~isfinite(ulpFactor) || ulpFactor<0
    error('rankWithTolerance:InvalidUlpFactor', ...
        'ulpFactor must be a finite nonnegative scalar.');
end

ranks=nan(size(values));
canonicalValues=values;
validIndices=find(isfinite(values));

if isempty(validIndices)
    return;
end

validValues=values(validIndices);

if direction=="max"
    [sortedValues,order]=sort(validValues,'descend');
else
    [sortedValues,order]=sort(validValues,'ascend');
end

sortedIndices=validIndices(order);
valueCount=numel(sortedValues);
position=1;

while position<=valueCount
    groupStart=position;
    groupEnd=position;
    referenceValue=sortedValues(groupStart);

    while groupEnd<valueCount
        candidateValue=sortedValues(groupEnd+1);

        if ~areNumericallyEqual( ...
                referenceValue,candidateValue,absoluteTolerance,ulpFactor)
            break;
        end

        groupEnd=groupEnd+1;
    end

    memberIndices=sortedIndices(groupStart:groupEnd);
    rankValue=mean(groupStart:groupEnd);

    ranks(memberIndices)=rankValue;
    canonicalValues(memberIndices)=referenceValue;
    position=groupEnd+1;
end
end

function isEqual=areNumericallyEqual(valueA,valueB,absoluteTolerance,ulpFactor)
scale=max([1,abs(valueA),abs(valueB)]);
tolerance=max(absoluteTolerance,ulpFactor*eps(scale));
isEqual=abs(valueA-valueB)<=tolerance;
end
