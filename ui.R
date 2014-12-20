library(shiny)
library(leaflet)


shinyUI(fluidPage(
    titlePanel("Lifeworld"),
    div(class="outer",
       tags$head(
#         # Include our custom CSS
         includeCSS("styles.css"),
         includeScript("gomap.js")
       ),
      leafletMap("map", width="100%", height="100%",
        initialTileLayer = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        initialTileLayerAttribution = HTML('Maps by blah'),
        options=list(
          center = c(0, 0),
          zoom = 2
        )
      )
    )
))