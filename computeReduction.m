function computeReduction(name, ratio)
%% This function reads the matrix in filename and reduces it by the ratio given

warning('off', 'all');

%make('compiler');
%make('compile');

warning('on', 'all');
filename = strcat(name, ".mtx");

% your old way to load file
%m = load(filename);
%L=spconvert(m);

% one possible way to load the file
fp = fopen(filename, 'r');
B = textscan(fp, '%d %d %f', 'headerlines', 1); % read data instead of first line
row = cell2mat(B(1));
col = cell2mat(B(2));
val = cell2mat(B(3));
fclose(fp);
L = sparse(double(row), double(col), double(val));
if(~issymmetric(L))
	L = L'+L-spdiags(diag(L), 0, length(L), length(L));
end

levels = 1;

graphLevels = {};

%%%% compute the reduction iteratively for multiple levels and store the setup objects
disp('start reduction');
for i = 1:levels
  start = tic;
  [Gs, H, setup]=graphreduction(L, ratio);
  end_ = toc(start);
  
  disp('end reduction time: ');
  disp(end_);
  
  fid = fopen('reduction-timings.txt', 'a+');
  fprintf(fid, '%s; %f\n', name, end_);
  fclose(fid);

  graphLevel.graph = Gs;
  graphLevel.map = H;
  graphLevel.setup = setup;

 
  graphLevels = [ graphLevels; graphLevel];
  
 L = Gs;
end

whos;
%%% from matlab docu:
%%% If A is symmetric, then eigs uses a specialized algorithm for that case. 
%%% If A is nearly symmetric, then consider using A = (A+A')/2 to make A symmetric before calling eigs. 
%%% This ensures that eigs calculates real eigenvalues instead of complex ones.
if not(issymmetric(graphLevels{end}.graph))
  graphLevels{end}.graph = (graphLevels{end}.graph + graphLevels{end}.graph')/2;
end

graphLevels{end}.graph

%%%% compute eigenvectors on sparsest level
disp('start eigenvector computation');
start = tic;
[EV, l] = eigs(graphLevels{end}.graph, 50, 'sm');
end_ = toc(start);
disp('end eigenvector computation time: ');
disp(end_);

fid = fopen('ev-timings.txt', 'a+');
fprintf(fid, '%s; %f\n', name, end_);
fclose(fid);


graphLevels{end}.ev = EV;

%%%% compute TSNE on the sparsest level
disp('start TSNE computation');
start = tic;
TVec = tsne(EV);
end_ = toc(start);
disp('end TSNE time: ');
disp(end_);

graphLevels{end}.tsneVec = TVec;

fid = fopen('tsne-timings.txt', 'a+');
fprintf(fid, '%s; %f\n', name, end_);
fclose(fid);

%%%% compute kMEANS on the sparsest level
lambdas = diag(l)

gap =-1;
gapSize = 100000;
for k = 2:length(lambdas)
    g = abs(lambdas(k) - lambdas(k-1));
    if g < gapSize
        gapSize = g;
        gap = k;
    end
end

%eva = evalclusters(EV, 'kmeans','gap', 'KList', [1:50])
disp('start kMEANS computation');
start = tic;
clusters = kmeans(EV, gap);
end_ = toc(start);
disp('end kMEANS time: ');
disp(end_);

graphLevels{end}.clusters = clusters;

fid = fopen('tsne-timings.txt', 'a+');
fprintf(fid, '%s; %f\n', name, end_);
fclose(fid);


test = eigmap(EV, setup)

%%%% map eigenvectors back to denser levels
for j = 1:levels-1
  
  idx = levels-j+1;
  setup = graphLevels{idx}.setup;
  TVec = graphLevels{idx}.tsneVec;
  EV = graphLevels{idx}.ev;
  
  map = graphLevels{idx}.map;
  clusters = graphLevels{idx}.clusters;
  [row,column] = find(map);
  
  disp('start kmeansmap computation');
  start = tic;
  for k = 1:length(row)
    cId = clusters(row(i));
    upClusters(k) = cId;
  end
  graphLevels{idx-1}.clusters = upClusters;
  end_ = toc(start);
  disp('end kmeansmap time: ');
  disp(end_);
  
  fid = fopen('kmeansmap-timings.txt', 'a+');
  fprintf(fid, '%s; %f\n', name, end_);
  fclose(fid);
  
  
  disp('start tsnemap computation');
  start = tic;
  UpVec = eigmap(TVec, setup);
  end_ = toc(start);
  disp('end tsnemap time: ');
  disp(end_);
  
  fid = fopen('tsnemap-timings.txt', 'a+');
  fprintf(fid, '%s; %f\n', name, end_);
  fclose(fid);

  graphLevels{idx-1}.tsneVec = UpVec;

  idx
  setup
  EV(1,:)

  disp('start Eigenmap computation');
  start = tic;
  UpVec = eigmap(EV, setup);
  end_ = toc(start);
  disp('end Eigenmap time: ');
  disp(end_);
  
  fid = fopen('Eigenemap-timings.txt', 'a+');
  fprintf(fid, '%s; %f\n', name, end_);
  fclose(fid);  
  graphLevels{idx-1}.ev = UpVec;
  UpVec(1,:)
  disp('loop done');

end




%%%% write everything to files

for j = 1:levels
  graphlevel = graphLevels{j};
  Gs = graphlevel.graph;
  H = graphlevel.map;
  EV = graphlevel.ev;
  TVec = graphlevel.tsneVec;
  clusters = graphlevel.clusters;
  
  reducedName = strcat(name, "_reduced");
  name = reducedName;
  reducedName = strcat(name, ".mtx");
  mappingName = strcat(name, "_map.mtx");
  disp('writing reduced matrix');
  mmwrite(reducedName, Gs);
  disp('done writing reduced matrix');
  disp('writing mapping');
  mmwrite(mappingName, H);
  disp('done writing mapping');

  disp('writing eigenvectors');
  outFile = strcat(name, '.vec');
  fid = fopen(outFile,'w');
  for i = 1:size(EV,1)
      fprintf(fid, '%0.30f, ', EV(i,1:end-1));
      fprintf(fid, '%0.30f', EV(i, end));
      fprintf(fid,'\n');
  end
  fclose(fid);
  disp('done writing eigenvectors');
  
  disp('writing TSNE Vectors');
  outFile = strcat(name, '_tsne.vec');
  fid = fopen(outFile,'w');
  for i = 1:size(TVec,1)
      fprintf(fid, '%0.30f, ', TVec(i,1:end-1));
      fprintf(fid, '%0.30f', TVec(i, end));
      fprintf(fid,'\n');
  end
  fclose(fid);
  disp('done writing TSNE vectors');
  
  disp('writing kmeans clusters');
  outFile = strcat(name, '_kmeans.txt');
  fid = fopen(outFile,'w');
  for i = 1:length(clusters)
      fprintf(fid, '%i, ', clusters(i));
      fprintf(fid,'\n');
  end
  fclose(fid);
  disp('done writing kmeans clusters');

end


%% matlab -nodisplay -r "cd('/path/to'); functionname(argument1, argument2, argumentN);exit"
