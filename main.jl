using GLMakie, Images, ImageFiltering, ImageQualityIndexes, ColorSchemes

# Divergent balanced normalization
function norm_div_bal(matrix)
	n = max(abs(maximum(matrix)),abs(minimum(matrix))) # most significant number
	matrix = (matrix .+ n) ./ (2n)
	return matrix
end

# sequential normalization
function norm_seq(matrix)
	matrix = (matrix .- minimum(matrix)) ./ (maximum(matrix) - minimum(matrix))
	return matrix
end

function visualize_diff(loss_diff)
	divergent = get(ColorSchemes.RdBu,Float64.(norm_div_bal(loss_diff)))
	sequential = get(ColorSchemes.Purples,Float64.(norm_seq(abs.(loss_diff))))
	return mosaicview(divergent,sequential;nrow=1)
end

iqi = SSIM()

f = Figure()



image_path_textbox  = Textbox(f[1, 1], placeholder = "Image Path")
image_path = Observable("String")

image_shown = Observable(rand(RGB,512,512))
image_obj = rand(RGB,512,512)
image(f[2, 1],image_shown,axis = (aspect=DataAspect(),))

slider_grid = SliderGrid(f[3:4, 1],
                (label="Blur",range=1:10),
                (label="Squared", range=0:0.01:1),
                (label="Absolute", range=0:0.01:1),
                (label="SSIM", range=0:0.01:1))

squared_ratio = 0.333
absolute_ratio = 0.333
ssim_ratio = 0.333

button_process = Button(f[1,2], label="Process Graph")

diff_shown = Observable(rand(RGB,512,512))
image(f[2, 2],diff_shown,axis = (aspect=DataAspect(),))

slider_diff = Slider(f[3, 2], range=1:9)
diff_graph = Observable(zeros(Float64,9))

lines(f[4,2],diff_graph)

#grid sizes
colsize!(f.layout,1,Relative(1/2))
colsize!(f.layout,2,Relative(1/2))

# make image previews bigger
rowsize!(f.layout,2,Relative(2/3))

#array_big_matrix = Matrix{Float64}(undef,99,512,512)

array_big_matrix = zeros(Float64,512*3,512,9)
mixed_loss_matrix = zeros(Float64,512,512,9)

on(button_process.clicks) do value
    (soft_sq_ratio,soft_abs_ratio,soft_ssim_ratio) = (squared_ratio,absolute_ratio,ssim_ratio).^2 ./ sum((squared_ratio,absolute_ratio,ssim_ratio).^2)
    println("Soft ratios: ", soft_sq_ratio, " ", soft_abs_ratio, " ", soft_ssim_ratio)

    for i in 1:9
        sq_loss = array_big_matrix[1:512,:,i]
        
        abs_loss = array_big_matrix[512+1:512*2,:,i]
        
        ssim_loss = array_big_matrix[512*2+1:512*3,:,i]

        mixed_loss_matrix[:,:,i] = soft_sq_ratio*sq_loss + soft_abs_ratio*abs_loss + soft_ssim_ratio*ssim_loss
    end

    diff_array_prealloc = zeros(Float64,8)
    for i in 1:8
        diff_matrix = mixed_loss_matrix[:,:,i+1] - mixed_loss_matrix[:,:,i]
        diff_num = Float64(sum(abs.(diff_matrix)))
        diff_array_prealloc[i] = diff_num
    end
    diff_graph[] = norm_seq(diff_array_prealloc)#diff_array_prealloc.^2 ./ sum(diff_array_prealloc.^2)
end

on(slider_diff.value) do value
    diff_matrix = mixed_loss_matrix[:,:,value+1] - mixed_loss_matrix[:,:,value]
    diff_shown[] = visualize_diff(diff_matrix)
end

on(image_path) do value
    global image_obj = Gray.(load(value))
    # precompute loss matricies
	#global array_big_matrix = zeros(Float64,512,512,99)
	
	for i in 1:9
		blur_val = 10 - i
		blurred_img = imfilter(image_obj,Kernel.gaussian(blur_val*10))
		
		sq_loss = (blurred_img - image_obj).^2
		abs_loss = abs.(blurred_img - image_obj)
		ssim_loss = ImageQualityIndexes._ssim_map(iqi,image_obj,blurred_img)

		big_matrix = vcat(sq_loss,abs_loss,ssim_loss)

		global array_big_matrix[:,:,i] = big_matrix
    end
    image_shown[] = image_obj
end

on(slider_grid.sliders[2].value) do squared_val
    global squared_ratio = squared_val
end

on(slider_grid.sliders[3].value) do absolute_val
    global absolute_ratio = absolute_val
end

on(slider_grid.sliders[4].value) do ssim_val
    global ssim_ratio = ssim_val
end


on(slider_grid.sliders[1].value) do blur_val
    image_shown[] = array_big_matrix[:,:,blur_val]#visualize_diff(array_big_matrix[:,:,blur_val])
end

on(image_path_textbox.stored_string) do value
    image_path[] = value
    println("Image path changed to: ", value)
end

#@profview visualize_diff(array_big_matrix[:,:,3])

f
