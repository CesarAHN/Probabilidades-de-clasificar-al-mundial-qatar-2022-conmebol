#---------------------------------------------------------------------------------
#           PROBABILIDADES DE CLASIFICAR AL MUNDIAL QATAR 2022 - CONMEBOL
#
# Autor: César Anderson Huamaní Ninahuanca.
#---------------------------------------------------------------------------------

library(dplyr)
library(rvest)
#devtools::install_github("CesarAHN/datametria")
library(datametria)
library(ggplot2)
library(tidyr)
library(gt)
#devtools::install_github("jthomasmock/gtExtras")
library(gtExtras)

#----------------------
# Tabla de posiciones. 
#----------------------
pw<-read_html("https://www.espn.com.mx/futbol/posiciones/_/liga/fifa.worldq.conmebol")

tab_pos<-cbind(pw %>% 
                 html_nodes("table.Table.Table--align-right.Table--fixed.Table--fixed-left") %>% html_table() %>% 
                 as.data.frame(),
               pw %>% 
                 html_nodes("div.Table__ScrollerWrapper.relative.overflow-hidden") %>% html_table() %>% 
                 as.data.frame())

names(tab_pos)[1]<-"SELECCION"

tab_pos$SELECCION<-limpiecito(gsub("(.*)([A-Z][a-z]+)","\\2",tab_pos$SELECCION))

tab_pos %>% as_tibble() %>% gt() %>%
  gt_theme_espn() %>% tab_header(title = paste0("TABLA DE POSICIONES CONMEBOL - FECHA ",max(tab_pos$J),"."),
                                 subtitle = "Clasificatorias al mundial Qatar 2022.")

#------------------------
# Argentina gana el partido pendiente.
# Por 3 a 0. 
tab_pos[1:2,2]<-tab_pos[1:2,2]+1
tab_pos[1:2,3]<-tab_pos[1:2,3]+c(0,1)
tab_pos[1:2,4]<-tab_pos[1:2,4]+0
tab_pos[1:2,5]<-tab_pos[1:2,5]+c(1,0)
tab_pos[1:2,6]<-tab_pos[1:2,6]+c(0,3)
tab_pos[1:2,7]<-tab_pos[1:2,7]+c(3,0)
tab_pos[1:2,8]<-tab_pos[1:2,8]+c(-3,3)
tab_pos[1:2,9]<-tab_pos[1:2,9]+c(0,3)

tab_pos %>% as_tibble() %>% gt() %>%
  gt_theme_espn() %>% tab_header(title = paste0("TABLA DE POSICIONES CONMEBOL - FECHA ",max(tab_pos$J),"."),
                                 subtitle = "Clasificatorias al mundial Qatar 2022.") %>% 
  tab_source_note("En el supuesto de que Brasil pierda por 3 a 0 contra argentina (Partido pendiente).")

#----------------------
# Puntaje de juego de visita.
# De 1 al 10, donde 1 es que le va muy mal jugando de visita y 10 que le va muy bien.
p_vist<-data.frame(SELECCION=tab_pos$SELECCION, p1=c(8,7,5,5,5,4,4,2,2,2))

# Puntaje de juego de local. 
# De 1 al 10, donde 1 es que le va muy mal jugando de local y 10 que le va muy bien.
p_loc<-data.frame(SELECCION=tab_pos$SELECCION, p2=c(10,8,6,6,6,5,5,8,4,4))

# Juicio de expertos. 
# De 1 al 10, donde 1 es que la selección según el experto no tiene un buen juego
# y 10 si considera el experto que sí tiene un buen juego.
p_exp<-data.frame(SELECCION=tab_pos$SELECCION, p3=c(9,8,6,5,5,5,4,4,3,2))

pp<-plyr::join_all(list(p_vist,p_loc,p_exp), by="SELECCION", type = "inner")
pp<-pp %>% mutate(ratio_vist=rowSums(select(., matches("p1|p3"))/20),
                  ratio_loc=rowSums(select(., matches("p2|p3"))/20))

pp %>% as_tibble() %>% gt() %>%
  gt_theme_espn() %>% tab_header(title = "ÍNDICE DE DESEMPEÑO DE LOCAL Y VISITANTE PARA CADA UNA DE LAS SELECCIONES", subtitle = "Visita, Local y Situación actual") %>% 
  tab_source_note("p1=Desempeño Visita.\np2=Desempeño Local.\np3=Desempeño Actual.")

# Creando la función para el montecarlo.

clasificatorias<-function(tab_pos,pp){
  #---------------------
  # Fecha 17.
  f17<-c("URUGUAY","PERU","COLOMBIA","BOLIVIA","BRASIL","CHILE",
         "PARAGUAY","ECUADOR","ARGENTINA","VENEZUELA")
  bd17<-data.frame()
  for (i in seq(1,9,by=2)) {
    d<-(1-(pp[pp$SELECCION==f17[i],6]-pp[pp$SELECCION==f17[i+1],5]))
    if(d<1){
      a1<-rbind(data.frame(SELECCION=f17[i], GF_=sample(0:4,1, prob = c(1*d/10,2*d/10,3*d/10,4*d/10,(1-d)))),
                data.frame(SELECCION=f17[i+1], GF_=sample(0:4,1, prob = c((1-d),5*d/14,4*d/14,3*d/14,2*d/14)))) 
    } else {
      d<-(1-(pp[pp$SELECCION==f17[i+1],6]-pp[pp$SELECCION==f17[i],5]))
      a1<-rbind(data.frame(SELECCION=f17[i+1], GF_=sample(0:4,1, prob = c(1*d/10,2*d/10,3*d/10,4*d/10,(1-d)))),
                data.frame(SELECCION=f17[i], GF_=sample(0:4,1, prob = c((1-d),5*d/14,4*d/14,3*d/14,2*d/14)))) 
    }
    a1$GC_<-rev(a1$GF_)
    a1$PTS_<-ifelse(a1$GF_>a1$GC_,3,
                    ifelse(a1$GF_==a1$GC_,1,0))
    a1$G_<-ifelse(a1$PTS_==3,1,0)
    a1$P_<-rev(a1$G_)
    a1$E_<-ifelse(a1$PTS_==1,1,0) 
    bd17<-rbind(bd17,a1)
  }
  
  tab_pos17<-left_join(tab_pos,bd17, by="SELECCION")
  
  tab_pos17<-tab_pos17 %>% mutate(J=J+1, G=G+G_, E=E+E_, P=P+P_, GF=GF+GF_, GC=GC+GC_,
                                  PTS=PTS+PTS_, DIF=GF-GC) %>% select(1:9) %>% arrange(-PTS)
  
  #---------------------
  # Fecha 18.
  f18<-c("URUGUAY","PERU","COLOMBIA","BOLIVIA","BRASIL","CHILE",
         "PARAGUAY","ECUADOR","ARGENTINA","VENEZUELA")
  bd18<-data.frame()
  for (i in seq(1,9,by=2)) {
    d<-(1-(pp[pp$SELECCION==f18[i],6]-pp[pp$SELECCION==f18[i+1],5]))
    if(d<1){
      a1<-rbind(data.frame(SELECCION=f18[i], GF_=sample(0:4,1, prob = c(1*d/10,2*d/10,3*d/10,4*d/10,(1-d)))),
                data.frame(SELECCION=f18[i+1], GF_=sample(0:4,1, prob = c((1-d),5*d/14,4*d/14,3*d/14,2*d/14)))) 
    } else {
      d<-(1-(pp[pp$SELECCION==f18[i+1],6]-pp[pp$SELECCION==f18[i],5]))
      a1<-rbind(data.frame(SELECCION=f18[i+1], GF_=sample(0:4,1, prob = c(1*d/10,2*d/10,3*d/10,4*d/10,(1-d)))),
                data.frame(SELECCION=f18[i], GF_=sample(0:4,1, prob = c((1-d),5*d/14,4*d/14,3*d/14,2*d/14)))) 
    }
    a1$GC_<-rev(a1$GF_)
    a1$PTS_<-ifelse(a1$GF_>a1$GC_,3,
                    ifelse(a1$GF_==a1$GC_,1,0))
    a1$G_<-ifelse(a1$PTS_==3,1,0)
    a1$P_<-rev(a1$G_)
    a1$E_<-ifelse(a1$PTS_==1,1,0) 
    bd18<-rbind(bd18,a1)
  }
  
  tab_pos18<-left_join(tab_pos17,bd18, by="SELECCION")
  
  tab_pos18<-tab_pos18 %>% mutate(J=J+1, G=G+G_, E=E+E_, P=P+P_, GF=GF+GF_, GC=GC+GC_,
                                  PTS=PTS+PTS_, DIF=GF-GC) %>% select(1:9) %>% arrange(-PTS,-DIF,-G) %>% 
    mutate(PUESTO=1:n())
  return(tab_pos18)
}

# Para tomar menos tiempo - Código eficiente.
resul<-data.frame(SELECCION=vector("character",length = 100000),
                  PTS=vector("numeric",length = 100000),
                  PUESTO=vector("integer",length = 100000))

# 10 mil escenarios.
for (i in 1:10000) {
  resul[(10*(i-1)+1):(10*(i-1)+10),]<-clasificatorias(tab_pos,pp)[,c(1,9,10)]
}

saveRDS(resul, "simulaciones.rds")
#---

# Puntos.
resul %>% arrange(SELECCION) %>% 
  ggplot(aes(x=PTS))+
  geom_histogram(fill="sienna2", alpha=.7)+
  facet_wrap(~SELECCION, scales = "free")+
  scale_x_continuous(breaks = seq(7,50,by=1))+
  labs(title = "DISTRIBUCIÓN DE LOS POSIBLES PUNTAJES POR SELECCIONES",
       subtitle = "Clasificatorias al mundial Qatar 2022.", x="Puntos", y="Frecuencia",
       caption = "Resultados luego de 10,000 repeticiones.\nELABORACIÓN:https://github.com/CesarAHN")+
  theme_bw()+
  theme(plot.caption = element_text(face = "bold", size = 8),
        plot.title = element_text(face = "bold"))

#----
# Puesto.
resul %>% arrange(SELECCION) %>% 
  ggplot(aes(x=PUESTO))+
  geom_histogram(fill="skyblue3", alpha=.7)+
  facet_wrap(~SELECCION, scales = "free")+
  scale_x_continuous(breaks = seq(1,10,by=1))+
  labs(title = "DISTRIBUCIÓN DE LOS POSIBLES PUESTOS POR SELECCIONES",
       subtitle = "Clasificatorias al mundial Qatar 2022.", x="Puestos", y="Frecuencia",
       caption = "Resultados luego de 10,000 repeticiones.\nELABORACIÓN:https://github.com/CesarAHN")+
  theme_bw()

#----
# Puntos necesarios para clasificar.
resul %>% group_by(PUESTO) %>% summarise(media=round(mean(PTS)), mediana=median(PTS),
                                         CV=sd(PTS)/mean(PTS)) %>% 
  ggplot(aes(x=PUESTO,y=mediana,fill=factor(PUESTO)))+
  geom_col(show.legend = F, colour="black")+
  scale_x_continuous(breaks = 1:10)+
  scale_fill_brewer(palette = "RdBu")+
  geom_label(aes(x=PUESTO,y=mediana+3, label=mediana), show.legend = F,
             bg="white", size=6)+
  labs(title = "PUNTOS NECESARIOS PARA TERMINAR EN CADA PUESTO",
       y="Puntos necesarios",x="Puestos")+
  annotate(geom = "rect", xmin = 4.5, xmax = 5.5, ymin= 0, ymax= Inf,
           fill = "gray20", alpha = 0.3)+
  theme_bw()+
  theme(plot.title = element_text(face = "bold"))

#---
# Probabilidad por puesto.
banderas<-data.frame(SELECCION=sort(unique(resul$SELECCION)),
                     PAIS=c("https://cdn-icons-png.flaticon.com/512/197/197573.png", # Argentina
                            "https://cdn-icons-png.flaticon.com/512/197/197504.png", # Bolivia.
                            "https://cdn-icons-png.flaticon.com/512/3909/3909370.png", # Brasil
                            "https://cdn-icons-png.flaticon.com/512/197/197586.png", # Chile.
                            "https://cdn-icons-png.flaticon.com/512/197/197575.png", # Colombia.
                            "https://cdn-icons-png.flaticon.com/512/197/197588.png", # Ecuador
                            "https://cdn-icons-png.flaticon.com/512/197/197376.png", # Paraguay.
                            "https://cdn-icons-png.flaticon.com/512/197/197563.png", # Peru
                            "https://cdn-icons-png.flaticon.com/512/197/197599.png", # Uruguay.
                            "https://cdn-icons-png.flaticon.com/512/197/197580.png")) # Venezuela
resul<-left_join(resul, banderas)

resul %>% group_by(PAIS) %>% count(PUESTO) %>% mutate(p=n/10000) %>% select(-n) %>% 
  mutate(PUESTO=paste0("PUESTO ",PUESTO)) %>% spread(PUESTO,p) %>% 
  select(PAIS,paste0("PUESTO ",1:10)) %>% as_tibble() %>% gt() %>% 
  fmt_percent(columns = matches("^PUES")) %>% fmt_missing(columns = matches("^PUES"), missing_text = "-") %>% 
  tab_header(title = "PROBABLIDADES POR PUESTO AL CULMINAR LAS CLASIFICATORIAS\nPOR SELECCIONES.",
             subtitle = "Clasificatorias al mundial Qatar 2022.") %>% 
  gt_theme_538() %>% gt_img_rows(columns = PAIS, height = 20) %>% 
  tab_source_note("ELABORACIÓN: https://github.com/CesarAHN") %>% 
  tab_style(style = list(cell_text(align = "center")),
            locations = list(cells_body(columns = c(paste0("PUESTO ",1:10))))) %>% 
  gt_color_rows(`PUESTO 1`:`PUESTO 10`, palette = "RColorBrewer::RdBu")

# Probabilidad de clasificar.
resul %>% mutate(clasificacion=case_when(PUESTO<=5~"SI",
                                         TRUE~"NO")) %>% group_by(PAIS) %>% 
  count(clasificacion) %>% mutate(p=n/10000) %>% select(-n) %>% 
  spread(clasificacion,p) %>% arrange(-SI) %>% as_tibble() %>% gt() %>% 
  fmt_percent(column = c(NO,SI)) %>% fmt_missing(columns = c(NO,SI), missing_text = "") %>% 
  tab_header(title = "PROBABLIDADES DE LAS SELECCIONES\nPARA CLASIFICAR AL MUNDIAL.",
             subtitle = "Clasificatorias al mundial Qatar 2022.") %>% 
  gt_theme_538() %>% gt_img_rows(columns = PAIS, height = 20) %>% 
  tab_source_note("Se considera hasta el 5° puesto para que una selección clasifique al mundial.\nELABORACIÓN: https://github.com/CesarAHN") %>% 
  tab_style(style = list(cell_text(align = "center")),
            locations = list(cells_column_labels(columns = c(NO,SI)))) %>%
  tab_style(style = list(cell_text(align = "center")),
            locations = list(cells_body(columns = c(NO,SI)))) %>% 
  gt_color_rows(NO:SI, palette = "RColorBrewer::RdBu")

