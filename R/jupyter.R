library(tidyverse)
options(jupyter.plot_mimetypes = "image/svg+xml")

# https://notebook.community/andrie/jupyter-notebook-samples/Changing%20R%20plot%20options%20in%20Jupyter

mtcars %>%
  head()

mtcars %>%
  mutate(cyl = as.factor(cyl)) %>%
  ggplot(data = ., mapping = aes(x = mpg, y = disp, color = cyl)) +
    geom_point() +
    ggthemes::theme_economist_white()