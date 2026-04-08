function [I] = opc_response(Dp, lambda, n, theta)
nang = 180; 
x = pi*Dp./lambda;
I = zeros(numel(x),1);
j = theta(1):1:theta(2);

for i = 1:numel(x)
    [s1,s2,~,~,~,~] = mie(x(i), n, nang);
    I(i) = sum(abs(s1(j).*conj(s1(j)) + s2(j).*conj(s2(j))));
end

