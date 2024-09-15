clear;
close all;
addpath(genpath('.\RGTV_SCGTV'));

%% Blurry Input
I=imread('.\Testing_Samples\CSS2.tif');

if numel(size(I))>2
    I_b=im2double(rgb2gray(I));
else
    I_b=im2double(I);
end

figure(1);subplot(1,3,1);
imshow(I_b);
title('Blurry Image');
Y_b=I_b;

%% Blind image deblurring
k_estimate_size=23; % set approximate kernel size
show_intermediate=false; % show intermediate output or not
border=20;% cut boundaries of the input blurry image (default border length: 20) 
[ k_estimate,Y_intermediate ] = scgtv_bid( Y_b(border+1:end-border,border+1:end-border),k_estimate_size,show_intermediate );

figure(2);imshow(k_estimate,[]);title('Estimated kernel');

k_out=k_rescale(k_estimate);
imwrite(k_out,'.\results\restored_kernel.jpg');

%% Fast Hyper Laplacian Priors non-blind deblurring
I_FHLP=I_b;
I_blur=I_b;
if numel(size(I_FHLP))>2
    for i=1:3
        [ I_FHLP(:,:,i) ]=Deconvolution_FHLP(I_blur(:,:,i),k_estimate);
    end
else
    [ I_FHLP ]=Deconvolution_FHLP(I_blur,k_estimate);   
end
figure(1);subplot(1,3,2);
imshow(I_FHLP);
title('Deconvolution results');
drawnow
imwrite(I_FHLP,'.\results\restored_image_FHLP.jpg');

%% Dark channel prior
hazy_image=I_FHLP;
[r,c,m]=size(hazy_image);
hazy_image=double(hazy_image);
J_DARK = Dark_Channel(hazy_image); %Finding Dark Channel
A = Estimating_Atmospheric_Light(hazy_image,J_DARK); %Finding Atmospheric Light
t=Transmission_Estimate(hazy_image,A); %Finding Transmission
window_size=75;
FG=Guided_Filter(t,hazy_image,window_size); %Finding Refined Transmission using Guided Filter
J_Refined=Recovering_Scene_Radiance(hazy_image,A,FG); %Finding Refined Haze-Free Image
J_Refined=J_Refined.*255;

figure(1);subplot(1,3,3)
imshow(uint8(J_Refined))
title("Refined Image")

save_path = '.\results'; file_name = 'dark_channel_result.jpg';
imwrite(uint8(J_Refined),fullfile(save_path, file_name));