function Nfit=newFitness(M,I,E1,k,Siv,Pos,n);
    lambda=k;
    mu=k;
    hsi=Siv+Pos+lambda-mu;
    hsi=Siv+Pos+(I-(k*(I+E1))/n);
    Nfit=hsi;
    Nfit=M;
end