function [z, Data] = CostFunction(x, VioFactor, Obj)
    [f,g,h] = Obj(x);
    v = sum(VioFactor.*max(0,[g h]));
    z = f + v;

    Data.z = z;
    Data.f = f;
    Data.g = [g h];
    Data.v = v;
    Data.x = x;
end