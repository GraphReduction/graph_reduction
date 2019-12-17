How to Compile:

make('compile') after you open matlab;

Two main functions are included in this package: emdreduction.m and eigmap.m

--------------------------------------------------------------------------------------------
1. graph reduction function:
-------------------------------------------------------------------------------------------

[Gs, matrix, setup] = emdreduction(A, ratio)

i.e: {Gs, matrix, setup} = graphreduction(A, 10) % 10X reduction on node
 
INPUT:
A : Laplacian matrix of input graph (n-by-n matrix);
ratio: node reduction ratio defined by user;

OUTPUT:
Gs: Laplacian matrix of reduced graph (m-by-m matrix);
matrix:cell data structure including the laplacian matrix of graph at each level and the mapping operators.  Mapping operator is a m-by-n matrix with each row representing the node idx in reduction graph, and the value of each row equal to 1 means that the node with index to be colunm index will be aggregated to that node;
setup: reduction information for futher usage.



-------------------------------------------------------------------------------------------
2. vector mapping function:
-------------------------------------------------------------------------------------------

V = eigmap(Vs, setup);

INPUT:
Vs : vectors of reduced graph (m-by-k, where k is the number of vectors);
setup: node reduction information;

OUTPUT:
V: Mapped vectors (n-by-k matrix);

REMINDER:
Since some information of graph reduction is needed for vector mapping process, you need to run the emdreduction.m function first, and then you can use setup variable for vectors mapping.
You can refer to emd_example.m for an example of using these two functions.

