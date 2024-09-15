function Rec=kernel_filter(C,R,L,ratio)

% Filter noise on the restored kernel

% C ==== the data to be reconstructed, which are in cells in C{i,j} with
% C{1,1} being a cell.
% R ==== is the reconstruction filter in 1D. In 2D, it is generated by tensor
% product. The filter D must be symmetric or anti-symmetric, which
% are indicated by 's' and 'a' respectively in the last cell of R.
% L ==== is the level of the decomposition.
% Rec ==== is the reconstructed data.

% ratio: the 1-ratio of parameters are filtered
% Written by Yuanchao Bai.

for k=L:-1:2
    C=sort_filter(C,k,length(R)-1,ratio);
    C{k-1}{1,1}=FraRec2D(C{k},R,k);
end
C=sort_filter(C,1,length(R)-1,ratio);
Rec=FraRec2D(C{1},R,1);

