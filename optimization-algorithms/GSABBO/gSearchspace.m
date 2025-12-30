function Gss=gSearchspace(a,I,E1,k,n)
    lambda=k;
    mu=k;
    mu=(E1*k)/n;
    lambda=I*(1-(k/n));
    E1=lambda+mu;%When E1=I
    E=(a*n)*((k*lambda)+mu*(n-k)/k*(n-k));
    Gss=E;
end