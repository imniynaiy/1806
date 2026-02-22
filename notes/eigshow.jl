using GLMakie, Colors, Images, LinearAlgebra, StaticArrays
using FileIO # for loading images

# Create a window
fig = Figure(size = (1000, 600))

# Load the image
img = load("doge.jpg") # Make sure doge.png is in your current directory

# Define the transformation matrix
A = @SMatrix [1 3; 4 2] ./ 4

# Create slider
slider = Slider(fig[2, 1], range = 0:0.01:1, startvalue = 1.0)
t = slider.value

# Create the transformation matrix as a function of t
matrix_observable = map(t) do t_val
    animate(t_val, A)
end

# Animation function
animate(t, A) = t * I(2) + (1 - t) * A

# Create layout
ax_img = Axis(fig[1, 1], title = "Transformed Image")
ax_plot = Axis(fig[1, 2], title = "Eigenvectors")

# Display the transformed image
points = map(matrix_observable) do m
    # Create transformed coordinates for the image
    rect = FRect(-250, -250, 500, 500)
    [m * Point2f0(x, y) for x in range(-250, 250, length=100), y in range(-250, 250, length=100)]
end

# Display image on transformed coordinates
image!(ax_img, points, color = img, interpolate = true)

# Draw the original rectangle boundary
rect_points = [Point2f0(-250, -250), Point2f0(250, -250), 
               Point2f0(250, 250), Point2f0(-250, 250), Point2f0(-250, -250)]
rect_transformed = map(matrix_observable) do m
    [m * p for p in rect_points]
end

lines!(ax_img, rect_transformed, color = :red, linewidth = 2)

# Calculate and display eigenvectors
eig_lines = map(matrix_observable) do m
    # Calculate eigenvectors
    eigen_vals, eigen_vecs = eigen(Array(m))
    
    # Scale eigenvectors
    v1 = eigen_vecs[:, 1] * 300
    v2 = eigen_vecs[:, 2] * 300
    
    # Create line segments
    [Point2f0(0, 0), Point2f0(v1...), Point2f0(0, 0), Point2f0(v2...)]
end

# Plot eigenvectors
lines!(ax_plot, eig_lines, color = [:blue, :blue, :red, :red], linewidth = 3)

# Add a point at origin
scatter!(ax_plot, [Point2f0(0, 0)], color = :black, markersize = 10)

# Display matrix values
matrix_text = map(matrix_observable) do m
    "Matrix:\n" *
    "$(round(m[1,1], digits=4))  $(round(m[1,2], digits=4))\n" *
    "$(round(m[2,1], digits=4))  $(round(m[2,2], digits=4))\n" *
    "Determinant: $(round(det(m), digits=4))"
end

Label(fig[3, 1:2], matrix_text, fontsize = 14, tellheight = true)

# Add slider label
Label(fig[2, 1], "t = $(round(t.val[], digits=2))", tellwidth = false)

# Adjust layout
colsize!(fig.layout, 1, Relative(0.5))
colsize!(fig.layout, 2, Relative(0.5))

# Display the figure
display(fig)