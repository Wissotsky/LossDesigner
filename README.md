# LossDesigner

A visualizer to help create task specific reconstruction loss functions

It will help you converge faster to the perceptually desired output

![Application window, has an image path input, two image preview boxes, sliders to control the loss mixing parameters, button to "process graph", a graph to show the difference between losses of reconstruction steps which show how much the image had to change that step](image.png)

> The software works well enough for my use case, but its pretty hacky otherwise.

## Running

1. Install the [Julia](https://julialang.org/) programming language
2. Clone the repo
3. Run `julia --project=. main.jl`