clear;clc;
fprintf('Read matrix\n');
[aa, bb, cc] = readmatrix('Gmat_airfoil.mtx');
A = sparse(aa, bb, cc);
b = rand(length(A), 1);
[Gs, H] = graphreduction(A, 10);
