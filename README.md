# Animating ggplots feat. Portuguese Inflation

Goals:
1. Build an animated GGplot
2. Show how to obtain and process indicators from INE, the official bureau of statistics for the Portuguese governement


![animation2](https://github.com/rafabelokurows/tuga-inflation-animation/assets/55976107/04d636ed-ecd8-4475-8bd3-8f9885fc151d)

## Data
Let's be honest, INE's website is like a digital maze from 1999.
The limitations, the hideous design (see image below) and the lack of basic features make it pretty difficult to obtain useful information and I can't even imagine how tough it may be for people who doesn't speak Portuguese, that are left to deal with a poorly translated version of the website on top of all that.

![image](https://github.com/rafabelokurows/tuga-inflation-animation/assets/55976107/1d1a2c2b-b5e4-4afb-9b72-f00fcb915341)

Luckily, better days are coming for people needing Portuguese official statistics, since there is now an R package that makes it a tiny bit easier to obtain data from INE.
While still a starting point, you can definitely streamline your work if you use [ineptR](https://github.com/c-matos/ineptR):
```
#devtools::install_github("c-matos/ineptR")
library(ineptR)
```

Let's say we want to analyze the Consumer Price Index for a few different sectors of the Portuguese economy. You could access INE, find the indicator, download and clean the Excel/CSV file, but you can also do this:
```
ineptR::get_ine_data("0002383")
```
While the result is not ideal and the package is still in need of some work to make it more errorproof, it gets the job done.


## Animated plot 
Conviniently, the data we've just obtained is already in long format, ggplot's favorite. So here we're gonna use a neat trick from gganimate, a function named transition_reveal, that will *reveal* little by little the information for us on our plot.
While it works perfectly out-of-the-box, don't sleep on some important additions passed on the call to *animate*, where we render the final plot to a GIF:
* Set the duration and fps according to the length of your data and to the speed you want it to progress by
* Add a start and/or an end pause so people can digest better the information you're conveying
* Use cairo's type of device to improve resolution of the final image

Building the plot:
```
animation <- inflacao %>%
  mutate(name = case_when(str_detect(name,"Habit") ~ "Housing",
                          str_detect(name,"Saúde") ~ "Healthcare",
                          str_detect(name,"Educ") ~ "Education",
                          str_detect(name,"alim") ~ "Food")) %>%
  filter(date >= "2018-01-01") %>%
  mutate(date = as.POSIXct(date),
         value=as.numeric(value)) %>%
  arrange(date) %>%
  ungroup %>%
  ggplot(aes(as.POSIXct(date), value, group = name, color = name)) +
  geom_line(show.legend = FALSE, size = 1.5)+
  geom_segment(aes(xend = as.POSIXct("2023-04-15"), yend = value), linetype = 2, colour = 'grey', show.legend = FALSE)+ #dashed lines for each sector
  geom_point(size = 3, show.legend = FALSE) +
  geom_text(aes(x = as.POSIXct("2023-04-25"), label = name), color = "darkgray", hjust = 0, show.legend = FALSE,  size=7)+ #names of the sectors for each subplot
  scale_x_datetime(date_labels = "%Y",date_breaks = "1 year") + #adding more breaks to the X axis
  scale_color_brewer(palette = "Dark2") +
  coord_cartesian(clip = 'off') +
  theme(plot.title = element_text(size = 20)) +
  labs(title = 'Inflation in key Sectors of the Economy in Portugal',
       y = 'Inflation Index (baseline 2012)',
       x = element_blank()) +
  theme(plot.margin = margin(5, 55, 5, 5)) + #It's important to give it a larger margin at the right since we want our plot to show the names of each sector
  theme(
    plot.title = element_text(face = "bold", size = 24),
    axis.title = element_text(face = "bold", size = 17),
    axis.text = element_text(size = 17),
    axis.ticks.length=unit(.55, "cm")
  ) +
  transition_reveal(as.POSIXct(date)) #here's the magic bit: animating the plot we've been building so far
```

Rendering:
```
b_gif <- animate(animation2,
                 fps = 10,
                 duration = 15,
                 width = 1100, height = 500,
                 end_pause = 25,#adding a pause in the end so people can read the text
                 renderer = gifski_renderer("animation2.gif"),
                 device = "png",
                 type="cairo") #trust me, important using cairo to improve plot quality
```

And there you have it. You will certainly have to play around with some of these parameters when adding in your own data, but it won't take long to produce some great-looking visualizations.

Thanks for reading!

