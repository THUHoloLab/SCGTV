function [ M ] = saturation_correction_mask( Y_s )
[a,b]=size(Y_s);
M=zeros(a,b);
sat_thresh = 1;
for i=1:a
    for j=1:b
        if Y_s(i,j)<=sat_thresh
            M(i,j)=1;
        else
            M(i,j)=1/Y_s(i,j);
        end
    end
end
end