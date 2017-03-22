function tarray = make_array(rmat)
%make_array Makes 2D array from 3D matrix.
%   make_array takes the lower triangle of a functional r-matrix and
%   converts the output to an array.
%
%   Usage: make_array(matrix)
%
%   kandalas 09/12/2013

% Pre-allocate array size
tarray = zeros(size(rmat,3),( 0.5*((size(rmat,1))^2 - size(rmat,1)))); %#ok<*NASGU>

% Create appropriate array size
for z = 1:size(rmat,3);
	tarray(z,:) = squareform(tril(rmat(:,:,z),-1));
end

end