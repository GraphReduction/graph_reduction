% graph reduction

%input:
% A: 		input graph Laplacian matrix
% ratio: 	graph node reduction ratio


%output:
% Gs: reduced graph Laplacian matrix
% matrix: cell data type for storing the matrix and operators
%        matrix{i}.L_G:  Laplacian matrix of graph at level i
%		 matrix{1}.L_G:  original graph
%		 matrix{lv}.L_G: coarest graph Gs
% 		 matrix{i}.H:    mapping operator between level i and 1, where H is a m-by-n matrix
% setup: data structure for storing all information of reduction
% 		 setup.level{i}.R: mapping operator between level i and i-1

function [Gs, matrix, setup] = emdreduction(A, ratio)
	n = length(A);
	A = A-spdiags(sum(A, 2), 0, n, n);

	density = nnz(A)/n;
	flow = 0;
	if(density > 80)
		flow = 1;
	end
	
	if(flow == 1)
		% do graph sparsification for dense graphs 
		writematrix(A, nnz(A), 'A.mtx');
		spar = sprintf('./grass-v1.0 -m A.mtx -c 200');
		unix(spar);

		[aa bb cc] = readmatrix('Pmat.mtx');
		P = sparse(aa, bb, cc);

		L = P;
	else
		L = A;
	end

	lamg    = Solvers.newSolver('lamg', 'randomSeed', 1,  'maxDirectSolverSize', floor(n/ratio));

   	tStart = tic;
    setup = lamg.setup('laplacian', L);
	tSetup = toc(tStart);
	disp(setup);
    
	setRandomSeed(now);

	X = setup.level{2}.R; % R is m-by-n
	lv = length(setup.level);

	matrix = cell([lv,1]);
	matrix{1}.L_G = A;
	matrix{2}.H = X; % matrix{i}.H: m-by-n mapping operatorso

	for i=2:lv
		matrix{i}.L_G = setup.level{i}.R*matrix{i-1}.L_G*setup.level{i}.R';
	end


	i = 3;
	while(lv > 2 & i <= lv)
		X = setup.level{i}.R * X;
		matrix{i}.H = X;
		i = i+1;
	end

	Gs = matrix{lv}.L_G;

	if(flow == 0)
		% do graph sparsification for dense graphs 
		writematrix(Gs, nnz(Gs), 'Gs.mtx');
		spar = sprintf('./grass-v1.0 -m Gs.mtx -c 50');
		unix(spar);

		[aa bb cc] = readmatrix('Pmat.mtx');
		Ps = sparse(aa, bb, cc);

		Gs = Ps;
	end

 end
