
library(shiny)
library(leaflet)
library(refset)

minDist <- 100
mapTimeout <- 1000 * 10; # in millisecs
vars <- reactiveValues()
vars$dfr <- data.frame(id=character(0), lat=numeric(0), long=numeric(0), 
      alive=logical(0), time=numeric(0))

# for testing
testing <- TRUE
if (testing) {
  nfake <- 250
  vars$dfr <- data.frame(id=sample(100000,nfake), lat=runif(nfake, -90, 90),
        long=runif(nfake, -180, 180), alive=sample(c(TRUE,FALSE), nfake, 
        replace=TRUE), time=as.numeric(Sys.time()))
}

fakeLife <- function(excludeID) {
  dfr <- vars$dfr
  dist <- as.matrix(dist(dfr[,c("lat", "long")], diag=TRUE, upper=TRUE))
  for (i in 1:nrow(dist)) {
    myID <- dfr$id[i]
    if (myID == excludeID) next
    mydist <- dist[i,]
    mynbr <- dfr
    mynbr$dist <- mydist
    mynbr <- mynbr[! is.na(mynbr$dist) & mynbr$id != myID,]
    mynbr <- mynbr[order(mynbr$dist),][1:8,]
    dfr$alive[i] <- sum(mynbr$alive)==3 || (! dfr$alive[i]) && sum(mynbr$alive)==2 
  }
  vars$dfr <- dfr
}

shinyServer(function(input, output, session) {
  map <- createLeafletMap(session, "map")
  sessionVars <- reactiveValues(id=NA) # per session
  senv <- environment()
  session$onFlushed(once=TRUE, function() {
    paintObs <- observe({
      map$clearShapes()
    })
  })
  
  session$onEnded(function() {
     # do nothing. We won't be talking to the guy any more.
  })

    # called just once, at start
  observe({
    if (is.na(sessionVars$id)) {
      sessionVars$id <- sample(1e15, 1)
      isolate({
        while(sessionVars$id %in% vars$dfr$id) sessionVars$id <- sample(1e15, 1)
        vars$dfr <- rbind(vars$dfr, data.frame(id=sessionVars$id, lat=NA, long=NA,
              alive=FALSE, time=as.numeric(Sys.time())))
      })
      refset(rsd, vars$dfr)  # hack around a bug in refset
      refset(rs, rsd[rsd$id==sessionVars$id,], assign.env=senv)
    }
  })

  
  observe({
    if (is.null(input$longitude) && is.null(input$latitude)) return()
    if (is.na(sessionVars$id)) return()

    rs$lat <<- input$latitude
    rs$long <<- input$longitude
  })
  
  observe({
    if (is.null(input$alive)) return()
    if (is.na(sessionVars$id)) return()
    alive <- as.logical(input$alive)
    warning("client is ", ifelse(alive, "live", "dead"), immediate.=TRUE)
    if (rs$alive == alive) return()
    rs$alive <<- alive
    if (testing) fakeLife(rs$id)
  })
  
  neighbours <- reactive({
    if (is.na(rs$lat) || is.na(rs$long)) return(NULL)
    mydist <- as.matrix(dist(vars$dfr[,c("lat", "long")], diag=TRUE, upper=TRUE))
    mydist <- mydist[which(vars$dfr$id==rs$id),]
    nbrs <- vars$dfr
    nbrs$dist <- mydist
    nbrs <- nbrs[!is.na(nbrs$dist) & nbrs$id != rs$id,]
    nbrs <- nbrs[order(nbrs$dist),][1:8, c("lat", "long", "alive")]
    nbrs
  })
  
  observe({
    nbrs <- neighbours() 
#    if (testing) invalidateLater(5000, session)
    if (! is.null(nbrs)) session$sendCustomMessage("neighbours", nbrs)
  })
  
  observe({
    invalidateLater(5000, session)
    isolate({
      if (testing) fakeLife(rs$id)
    })
  })
  
  observe({
    # when the database changes, update the map
    cc <- na.omit(vars$dfr)
    # also invalidated after a timeout
    invalidateLater(mapTimeout, session)
    map$addCircleMarker(cc$lat, cc$long, 6,
          options=list(fill=TRUE, color="black", fillOpacity=0.8),
          eachOptions=list(fillColor=ifelse(cc$alive, "black", "white")))
  })
  
  observe({
    if (is.null(input$goto))
      return()
    isolate({
      dist <- 0.5
      zip <- input$goto$zip
      lat <- input$goto$lat
      lng <- input$goto$lng
      map$fitBounds(lat - dist, lng - dist,
        lat + dist, lng + dist)
    })
  })
})