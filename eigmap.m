% map the reduced vectors Vs to original-graph-level
% It includes the mapping and refinement using Gaussian Jacobi

function V = eigmap(Vs, setup)
	lv = length(setup.level);
	Ve = Vs;
	i = lv;
	while i>=2
		V1 = setup.level{i}.R'*Ve;
		V = smoothVector(setup.level{i-1}.A, V1, 0.7, 20);
		Ve = V;
		i=i-1;
	end
	V = gram_schmidt(V);
end
