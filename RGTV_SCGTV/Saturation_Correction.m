[a,b]=size(Y_b);
W_I=zeros(a,b);
sat_thresh = 0.6;
for i=1:a
    for j=1:b
        if Y_b(i,j)<=sat_thresh
            W_I(i,j)=Y_b(i,j);
        else
            W_I(i,j)=1/Y_b(i,j);
        end
    end
end
% imshow(W_I)
surf(W_I);shading interp