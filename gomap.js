// When locator icon in datatable is clicked, go to that spot on the map
$(document).on("click", ".go-map", function(e) {
  e.preventDefault();
  $el = $(this);
  var lat = $el.data("lat");
  var long = $el.data("long");
  var zip = $el.data("zip");
  $($("#nav a")[0]).tab("show");
  Shiny.onInputChange("goto", {
    lat: lat,
    lng: long,
    zip: zip,
    nonce: Math.random()
  });
});


var mylong;
var mylat;
function showPosition(position) {
    mylong = position.coords.longitude;
    mylat = position.coords.latitude;
    Shiny.onInputChange("longitude", mylong);
    Shiny.onInputChange("latitude", mylat);
    Shiny.onInputChange("alive", imAlive);
}

function getLocation() {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(showPosition);
    } 
}

var imAlive = false;
function GOL(nbrs) {
  liveNbrs = 0;
    //nbrs.lat, nbrs.long, nbrs.alive (true/false)
  for (i=0; i < nbrs.alive.length; i++) {
     if (nbrs.alive[i]) liveNbrs += 1;
  }
  newAlive = (liveNbrs == 3  || (liveNbrs == 2 && imAlive));
  if (newAlive != imAlive) Shiny.onInputChange("alive", newAlive);
  imAlive = newAlive;
}

$(document).ready(function(e) {
  getLocation();
  Shiny.addCustomMessageHandler("neighbours", GOL);
})
