
 function o = Euclidean_distance(a,b)

for i=1:size(a,1)
    o(1,i)=sqrt((a(i)-b(i))^2);
end
