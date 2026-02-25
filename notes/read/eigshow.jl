using GLMakie, Colors, Images, LinearAlgebra, FileIO
using GeometryTypes
# Explicitly import only what we need from Images
import Images: load

# Create a window
fig = Figure(size = (1000, 600))

# Load the image (using doge.jpg)
img = load("doge.jpg")  # Make sure doge.jpg is in your current directory

# Option 1: Keep as RGB (recommended for color images)
# No conversion needed - just use the image directly
img_matrix = img

# Option 2: If you want grayscale, uncomment this instead:
# img_matrix = Gray.(img)  # Convert to grayscale

# Define the transformation matrix
A = [1 3; 4 2] ./ 4

# Create slider
slider = Slider(fig[2, 1], range = 0:0.01:1, startvalue = 1.0)
t = slider.value

# Animation function
animate(t_val, A) = t_val * Matrix(I, 2, 2) + (1 - t_val) * A

# Create the transformation matrix as a function of t
matrix_observable = map(t) do t_val
    animate(t_val, A)
end

# Create layout - explicitly use Makie.Axis
ax_img = Makie.Axis(fig[1, 1], title = "Transformed Image")
ax_plot = Makie.Axis(fig[1, 2], title = "Eigenvectors")

const GRID_RES = 120
# Create a grid of points for the image
# Sample a limited number of points so the scatter stays snappy
img_height, img_width = size(img, 1), size(img, 2)
sample_cols = min(img_width, GRID_RES)
sample_rows = min(img_height, GRID_RES)
x_range = range(-250, 250, length=sample_cols)
y_range = range(-250, 250, length=sample_rows)
col_positions = collect(range(1, img_width, length=sample_cols))
row_positions = collect(range(1, img_height, length=sample_rows))
points_grid = [Point2f0(x, y) for y in y_range, x in x_range]
row_indices = clamp.(round.(Int, row_positions), 1, img_height)
col_indices = clamp.(round.(Int, col_positions), 1, img_width)
color_grid = [img_matrix[r, c] for r in row_indices, c in col_indices]
colors_vec = vec(color_grid)

# Transform the grid points and plot as colored scatter
grid_points_vec = vec(points_grid)
transformed_points = map(matrix_observable) do m
    [Point2f0(m * [p[1]; p[2]]) for p in grid_points_vec]
end
scatter!(ax_img, transformed_points, color = colors_vec, markersize = 4, marker = :rect, strokewidth = 0)

# Draw the original rectangle boundary
rect_points = [[-250, -250], [250, -250], [250, 250], [-250, 250], [-250, -250]]
rect_transformed = map(matrix_observable) do m
    [Point2f0(m * p) for p in rect_points]
end

lines!(ax_img, rect_transformed, color = :red, linewidth = 2)

# Calculate and display eigenvectors
eig_lines = map(matrix_observable) do m
    # Calculate eigenvectors
    eigen_vals, eigen_vecs = eigen(m)
    
    # Scale eigenvectors
    v1 = eigen_vecs[:, 1] * 300
    v2 = eigen_vecs[:, 2] * 300
    
    # Create line segments
    [Point2f0(0, 0), Point2f0(v1[1], v1[2]), 
     Point2f0(0, 0), Point2f0(v2[1], v2[2])]
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
slider_label_text = map(t) do t_val
    "t = $(round(t_val, digits=2))"
end
slider_label = Label(fig[2, 1], text = slider_label_text, tellwidth = false)

# Adjust layout
colsize!(fig.layout, 1, Relative(0.5))
colsize!(fig.layout, 2, Relative(0.5))

# Display the figure
display(fig)

# Block execution while the window is open so the GUI stays visible.
wait(fig.scene)
