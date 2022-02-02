
# BIENVENIDOS!!!

# PROBABILIDADES DE CLASIFICAR AL MUNDIAL QATAR 2022 - CONMEBOL

Se crea este repertorio para poder determinar las probabilidades de cada
una de las selecciones de la CONMEBOL, para clasificar al mundial Qatar
2022. Para tal fin, primero se crea una función que permita calcular los
resultados posibles de los partidos (goles a favor, goles en contra,
diferencia de goles, puntos y puesto), desde la fecha 15 a la fecha 18.

Una vez que se obtiene la función se realiza un proceso montecarlo con
el cual se evalúa la función 10,000 veces de cada compromiso de estas
cuatro fechas. Con lo cual se obtiene 10,000 resultados posibles por
cada partido.

Al final se calcula las probabilidades en función a los resultados
posibles que se obtendrían en la fecha 18 de las clasificatorias.

USted encuentra todo el código en este repositorio, el archivo se llama
**script-probabilidades-qatar-2022.R**

## Tabla de posiciones.

Se obtendrá la tabla de posiciones dese la web de espn, actualizado a la
fecha 2022-02-02. Para esto se usa el método de web scraping.

``` r
tab_pos %>% as_tibble() %>% gt() %>%
  gt_theme_espn() %>% tab_header(title = "TABLA DE POSICIONES CONMEBOL - FECHA 14.",
             subtitle = "Clasificatorias al mundial Qatar 2022.")
```

<p align="center">
<img src="f1.png" width="500px">
</p>

Hasta la fecha 14, se tiene pendiente el partido entre Brasil y
Argentina. Para el cálculo se supondrá que la selección de Argentina
gana este partido por una diferencia de 3 a 0, como se da en los casos
de walkover. Por lo cual la tabla de posiciones quedaría:

``` r
tab_pos %>% as_tibble() %>% gt() %>%
  gt_theme_espn() %>% tab_header(title = "TABLA DE POSICIONES CONMEBOL - FECHA 14.",
             subtitle = "Clasificatorias al mundial Qatar 2022.") %>% 
  tab_source_note("En el supuesto de que Brasil pierda por 3 a 0 contra argentina (Partido pendiente).")
```

<p align="center">
<img src="f2.png" width="500px">
</p>

## Desempeño de las selecciones.

Todos los países no tienen el mismo desempeño, por lo cual se crea un
tipo de índice de desempeño en donde se consideran 3 características: el
puntaje de desempeño como visitante, el puntaje de desempeño como local
y el puntaje de desempeño dado por un especialista. Estas
características reciben puntajes desde 1 hasta 10, en donde 1 significa
que la selección tiene un desempeño paupérrimo, mientras que 10
significa que su desempeño es sobresaliente.

Los tres puntajes son arbitrarios ya que el desempeño de partidos
pasados no es indicador del desempeño futuro de una selección, por más
objetivo que se piense que es, ya que, las selecciones juegan partidos
luego de un lapso largo de tiempo lo cual influye en su desempeño. Por
lo cual, solo se podría indicar que tan buenos son de visita (primera
caracter´sitica), o que tan buenos son de locales (segunda
característica) y su momento actual (tercera característica).

En ese sentido los puntajes lo he asignado en función a mis
conocimientos deportivos. Usted puede asignar otros puntajes y obtendrá
resultados distintos, pero es importante no perder la objetividad.

A continuación muestro el puntaje para cada una de las selecciones como
el ratio de juego de visita y local. El ratio de visita es la suma del
desempeño de visita y la situación actual entre el puntaje máximo 20, de
manera similar se obtiene para el ratio de local.

``` r
pp %>% as_tibble() %>% gt() %>%
  gt_theme_espn() %>% tab_header(title = "ÍNDICE DE DESEMPEÑO DE LOCAL Y VISITANTE PARA CADA UNA DE LAS SELECCIONES", subtitle = "Visita, Local y Situación actual") %>% 
  tab_source_note("p1=Desempeño Visita.\np2=Desempeño Local.\np3=Desempeño Actual.")
```

<p align="center">
<img src="f3.png" width="500px">
</p>

## Función para el cálculo de resultados.

Se crea la función que determinará el resultado de cada partidos de las
4 fechas resltantes (de la fecha 15 a la fecha 18). Esta función
considera dos argumentos: la tabla de posiciones consolidada hasta la
fecha 14 y el desempeño de las selecciones.

La función es la siguiente:

``` r
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
```

la función es un fiel reflejo de la realidad en donde para determinar si
una seleccción ganará, empatará o perderá depende del número de goles
que se realizan en cada partido. El número de goles viene determinado
por el desemepeño de cada selección (ratio de visita y ratio de local).
El impacto se puede observar en la parte
`prob = c(1*d/10,2*d/10,3*d/10,4*d/10,(1-d))` y
`prob = c((1-d),5*d/14,4*d/14,3*d/14,2*d/14))`. En la cual existe una
mayor probabilidad de ganar siempre y cuando el ratio ya se de local o
de visita es mayor, pero como sabemos que en el fútbol nada está
escrito, esta cantidad de goles viene determinado por un proceso
aleatorio, lo cual permite que el número de goles no dependa
exclusivamente de los ratios, sino también del azar.

## Simulación a lo Montecarlo - 10,000 veces.

Se obtendrán los resultados como si se jugara cada partido 10,000 veces.
Para esto usamos el método de montecarlo.

``` r
# Para tomar menos tiempo - Código eficiente.
resul<-data.frame(SELECCION=vector("character",length = 100000),
                  PTS=vector("numeric",length = 100000),
                  PUESTO=vector("integer",length = 100000))

# 10 mil escenarios.
for (i in 1:10000) {
  resul[(10*(i-1)+1):(10*(i-1)+10),]<-clasificatorias(tab_pos,pp)[,c(1,9,10)]
}
```

Este proceso demora un par de minutos, por lo que si usted desea
aumentar el número de evaluaciones tendrá que considerar el tiempo de
ejecución. Asimismo, al ser un proceso aleatorio el resultado que se
obtiene en este proyecto, puede resultar distinto al suyo cuando corra
el código, al margen de si dejo el desempeño sin modificaciones, esto
debido a que está por detrás un proceso aleatorio. Pero los resultados
no tendrán variaciones significativas, ya que el número de veces que se
repitió el proceso es relativamente grande como para obtener resultados
radicalmente diferentes.

A continuación se muestra las 2 primeras simulaciones, en donde solo
consideramos a las selecciones, los puntos, y el puesto en el que
culminaría cada selección. Usted puede obtener, los goles, diferencia de
goles, etc si toma en consideración a todas las columnas del resultado
de la función `clasificatorias`.

``` r
resul %>% head(n=20L)
#    SELECCION PTS PUESTO
# 1     BRASIL  45      1
# 2  ARGENTINA  42      2
# 3    ECUADOR  31      3
# 4    URUGUAY  28      4
# 5   COLOMBIA  21      5
# 6       PERU  21      6
# 7      CHILE  19      7
# 8    BOLIVIA  16      8
# 9   PARAGUAY  13      9
# 10 VENEZUELA  11     10
# 11    BRASIL  45      1
# 12 ARGENTINA  41      2
# 13   ECUADOR  26      3
# 14   URUGUAY  25      4
# 15      PERU  24      5
# 16  COLOMBIA  19      6
# 17     CHILE  19      7
# 18   BOLIVIA  17      8
# 19  PARAGUAY  17      9
# 20 VENEZUELA  13     10
```

## Resultados.

### A nivel de puntos obtenidos luego de la fecha 18.

Luego de realizar el cálculo 10,000 veces se obtiene la distribución de
puntos que conseguiría cada selección.

![](README-unnamed-chunk-13-1.png)<!-- -->

### A nivel de puestos obtenidos luego de la fecha 18.

A continuación se muestra la distribución de puestos que obtendría cada
selección.

![](README-unnamed-chunk-14-1.png)<!-- -->

### Puntos necesarios para clasificar.

La mediana de los puntos para terminar en cada puesto.

![](README-unnamed-chunk-15-1.png)<!-- -->

## Probabilidades de terminar en puestos de clasificación.

A continuación se muestra las probabilidades de los puestos en los que
finalizaría cada una de las selecciones luego de terminar la fecha 18.

``` r
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
```

<p align="center">
<img src="f4444.png" width="700px">
</p>

## Probabilidades de clasificar a Qatar 2022.

``` r
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
```

<p align="center">
<img src="f5555.png" width="300px">
</p>

Para la extracción, limpieza y gráficos del repositorio se usa el
software R en su totalidad. Si tiene alguna sugerencia o comentario
puede enviarnos un correo a: <pe.cesar.huamani.n@uni.pe> o
<cesar.huamani@datametria.com>
