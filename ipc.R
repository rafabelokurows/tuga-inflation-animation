#devtools::install_github("c-matos/ineptR")
library(ineptR)
library(ggplot2)
library(tidyverse)
library(ggtext)
library(gganimate)
library(lubridate)
library(gifski)
library(hrbrthemes)
library(ggplot2)
library(viridis)

#https://www.ine.pt/xportal/xmain?xpid=INE&xpgid=ine_indicadores&indOcorrCod=0002383&selTab=tab0
##If you want to load an Excel file - already edited, go ahead:
#ipc = openxlsx::read.xlsx("eZ5cT0YfyidPC_ubo_1uPhXEZWMxjSdIaud6TXam_4987.xlsx")

##If not, use ineptR:
df = ineptR::get_ine_data("0002383")

#Only data for Continente (Continental Region) and a few key sectors of the Economy
ipc = teste %>% filter(geodsg=="Continente") %>% #head() %>%
  mutate(ano = parse_number(dim_1)) %>% filter(ano > 2012 & dim_3 %in% c("06","10","011","04")) %>%
  select(dim_1,dim_3_t,valor)

theme_set(theme_minimal())
portuguese_months <- c(
  "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
  "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
)

#A definitely not efficient way of parsing dates from Portuguese to dates R can handle
ipc$date = NA
for (i in 1:(nrow(ipc))){
  print(i)
  aux = ipc[i,]$dim_1
  for (j in 1:length(portuguese_months)) {
    aux <- gsub(portuguese_months[j], sprintf("%02d", j), aux)
  }
  ipc[i,]$date= as.Date(parse_date_time(aux, "%m/%Y"))
}

inflacao = ipc %>% mutate(date=as_date(date)) %>%
   select(date,name=dim_3_t,value=valor)

animation2 <- inflacao %>%
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

animation2

#Rendering the animation as a gif
b_gif <- animate(animation2,
                 fps = 10,
                 duration = 15,
                 width = 1100, height = 500,
                 end_pause = 25,#adding a pause in the end so people can read the text
                 renderer = gifski_renderer("animation2.gif"),
                 device = "png",
                 type="cairo") #trust me, important using cairo to improve plot quality
