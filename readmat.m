clear;clc;
fprintf('Read matrix\n');

file = 'airfoil.mtx';

fp = fopen(file, 'r');
B = textscan(fp, '%d %d %f', 'headerlines', 1); % read data instead of first line
row = cell2mat(B(1));
col = cell2mat(B(2));
val = cell2mat(B(3));
fclose(fp);

A = sparse(double(row), double(col), double(val));
if(~issymmetric(A))
	A = A'+A-diag(diag(A));
end

[Gs, matrix, setup] = emdreduction(A, 20); % graph reduction 
[Vs, lambdaS] = eigs(Gs, 5, 'sm');

writematrix(A, nnz(A), 'Gs.mtx')

V = eigmap(Vs, setup); % eigenvector mapping from Vs to V
