function [ k_estimate, Y_r_rgtv_cg, Y_large ] = bid_rgtv_c2f_cg_sr( Y_b,k_estimate_size, show_intermediate)
% Blind image deblurring from coarse to fine

% Y_b: a blurred image
% k_estimate_size: the estimated size of kernel

% k_estimate: restored kernel
% Y_r_rgtv_cg: restored skeleton image

% Written by Yuanchao Bai

% 插值
% Y_b=TV_denoising(Y_b,[0.01,0.1],10);
% Y_b=imresize(Y_b,size(Y_b)*2,'bilinear');

scale_factor=log2(3);
level_num=ceil(log(k_estimate_size/7)/log(scale_factor))+3;
image_pyramid=cell(level_num,1);
k_size=zeros(level_num,1);
image_size=zeros(level_num,2);



image_pyramid{3}=TV_denoising(Y_b,[0.01,0.1],10);
% image_pyramid{1}=Y_b;

k_size(3)=k_estimate_size;
image_size(3,:)=size(image_pyramid{3});


image_size(2,:)=floor(image_size(3,:)*log2(3));
image_pyramid{2}=imresize(image_pyramid{3},image_size(2,:),'bilinear');
k_size(2)=floor(k_size(3)*log2(3));
k_size(2)=k_size(2)+(mod(k_size(2),2)-1);

image_size(1,:)=floor(image_size(2,:)*log2(3));
image_pyramid{1}=imresize(image_pyramid{2},image_size(1,:),'bilinear');
k_size(1)=floor(k_size(2)*log2(3));
k_size(1)=k_size(1)+(mod(k_size(1),2)-1);

Y_large=image_pyramid{1};

for i=4:level_num
    image_size(i,:)=floor(image_size(i-1,:)/log2(3));
    image_pyramid{i}=imresize(image_pyramid{i-1},image_size(i,:),'bilinear');
    k_size(i)=floor(k_size(i-1)/log2(3));
    k_size(i)=k_size(i)+(1-mod(k_size(i),2));
end

frame=1; 
Level=1; 
[D,R]=GenerateFrameletFilter(frame);
KD  = @(x) FraDecMultiLevel2D(x,D,Level); % kernel decomposition
KF = @(x,ratio) kernel_filter(x,R,Level,ratio); % kernel filter

%% RGTV Blind
for level=level_num:-1:1
    
    mu=0.01;
    lambda=0.05;
    
%     sigma=0.1;
    sigma=0.1*sqrt(2);
    
    if level >= level_num
        k_estimate=zeros(k_size(level),k_size(level));
        k_center=ceil(k_size(level)/2);
        k_estimate(k_center,k_center)=1;
    else
        k_estimate=imresize(k_estimate,[k_size(level),k_size(level)],'bilinear');
        k_estimate(k_estimate<max(k_estimate(:))*0.05)=0;
        k_estimate=k_estimate/sum(k_estimate(:));
    end
    
    [Y_b_padding,padsize] = G_padding(image_pyramid{level},k_estimate,1);
    Y_r_rgtv_cg=Y_b_padding;
    [h,w]=size(Y_r_rgtv_cg);
    
    for iter=1:3

        fprintf('level %d, Iter %d:',level,iter);
        W1=ones(h*w,4);
        W=W1;
        for i=1:3
            fprintf('%d...',i);
            for j=1:3
                Y_r_rgtv_cg=Deblur_GL_CG_4(Y_b_padding,k_estimate,W,mu,20);
                W=W1.*weights_computation( Y_r_rgtv_cg,[],4,2 ); 
            end
            W1=weights_computation( Y_r_rgtv_cg,sigma,4,1 );
            W=W1.*weights_computation( Y_r_rgtv_cg,[],4,2 );
        end
        fprintf('\n');
        
        Y_r_rgtv_cg=Y_r_rgtv_cg(padsize(1)+1:end-padsize(1),padsize(2)+1:end-padsize(2));
        
        if show_intermediate
            figure(11);
            imshow(Y_r_rgtv_cg);
            title('RGTV CG');
        end

       %% kernel estimate
        t_s=0.1;
        t_r=0.3;
        [ M ] = informative_edge_mask_adaptive_mine( Y_r_rgtv_cg,t_s,t_r,5);
        k_estimate=kernel_solver_L2(Y_r_rgtv_cg,image_pyramid{level},k_size(level),M,lambda);
        
        if level<=2
            Cf=KD(k_estimate);
            k_estimate=KF(Cf,0.05); % filter noise in restored kernel
            k_estimate(k_estimate<max(k_estimate(:))*0.05)=0; % Thresholding
            k_estimate=k_estimate/sum(k_estimate(:));
            [ k_estimate ] = kernel_centralize(k_estimate,0.1);
        end
        
% 此处可计算迭代PSF的PSNR

        if show_intermediate
            figure(12);
            imshow(k_estimate,[]);
            title('Estimated kernel');
        end
        
%         mu=mu/1.1;
        lambda=lambda/1.2;
    end
end

end



