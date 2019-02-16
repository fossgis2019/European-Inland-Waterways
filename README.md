# European Inland Waterways as a Slippy Map

FOSSGIS 2019 Demo: Converting the Map of European Inland Waterways from PDF to Slippy Map

**To the [map](https://fossgis2019.github.io/European-Inland-Waterways/).**

[UNECE Inland Water Transport working party](http://www.unece.org/trans/main/sc3/sc3.html) publishes a number of [nice maps](http://www.unece.org/trans/main/sc3/maps.html) on European Inland Waterways.  
Unfortunatelly these maps are published as huge PDFs which are not quite comfortable to view.

This project demonstrates how one could easily convert a static PDF or an image into a modern [slippy map](https://wiki.openstreetmap.org/wiki/Slippy_Map) which can be easily zoomed and panned.

# Prerequisites

* We will use [Wget](https://www.gnu.org/software/wget/) to download data (optional).
* We will use [libvips](https://libvips.github.io/libvips/) for image processing.
* We will use [Leaflet](https://leafletjs.com/) as a web mapping library

# Creating the map client

## Download the data

First step is to download the data. Right-click the [link](http://www.unece.org/fileadmin/DAM/trans/main/sc3/AGN_map_2018.pdf) and save the target PDF file locally or use `wget`:

```
wget -q http://www.unece.org/fileadmin/DAM/trans/main/sc3/AGN_map_2018.pdf -O data/AGN_map_2018.pdf
```

## Generate the tiles

Now that we have the source image (as PDF), we can use the `vips` tool from [libvips](https://libvips.github.io/libvips/) to [generate the image pyramid](http://libvips.github.io/libvips/API/current/Making-image-pyramids.md.html):

```
vips dzsave data/AGN_map_2018.pdf[dpi=600] tiles --layout google --suffix .png --vips-progress
```

This produces a hierarchical structure of tiles in PNG format. The `--layout google` instructs `vips` to generate this structure in Google layout which has the `{z}/{y}/{x}.png` format.  
Both Leaflet and OpenLayers support this format out of the box.

## Configuring the web mapping client.

In this demo we will use [Leaflet](https://leafletjs.com/) as a web mapping library. [OpenLayers](https://openlayers.org/) would work just as well.

We'll start with the following setup:

```javascript
var map = L.map('map', {
	zoom: 6,
	center: [0, 0]
});

L.tileLayer('tiles/{z}/{y}/{x}.png', {
	noWrap: true,
	attribution: '<a href="http://www.unece.org/trans/main/sc3/sc3.html">UNECE - Inland Water Transport</a>'
}).addTo(map);
```

The most important part here is the URL template `'tiles/{z}/{y}/{x}.png'` of the tile layer. It points to the tiles we have just generated using `vips`.

Zoom and center in the map configuration are chosen randomly. We'll tune them on the following steps, but we need to start somewhere.

## Configuring zoom and center

At this point we should already have a working web mapping client which can be zoomed and panned.

However, if you first open the map in the web browser, it will most probably appear pretty much displaced.
This is because the center we've chosen initially does not make much sense. The initial zoom is probably also not what it should be.

To find out reasonable initial values, zoom/pan to the location and level that make sense. Then open the JavaScript console in the browser (normally `F12`) and type:

```
map.getZoom();
map.getCenter();
```

This will give us initial zoom and center values. We can now configure them in the map:

```
var map = L.map('map', {
	zoom: 5,
	center: [61, -94]
});
```

## Configuring map constraints

If you navigate around the map you will notice that not all zoom levels work well.  
If you zoom out, the map becomes too small to make sense. Zoom in too much and the map disappears. The latter is due to `vips` only generating zoom levels 0 to 7.

To limit zoom levels you can use configuration options `minZoom` and `maxZoom` of the tile layer:

```
L.tileLayer('tiles/{z}/{y}/{x}.png', {
	minZoom: 2,
	maxZoom: 7,
	noWrap: true,
	attribution: '<a href="http://www.unece.org/trans/main/sc3/sc3.html">UNECE - Inland Water Transport</a>'
}).addTo(map);
```

Same story with panning. You can easily go to far to the east or west or north or south and completely lose the map from the sight.

Leaflet provides options to configure maximum allowed bounds both for the tile layer and the map.  
But to do this we first need to figure out what the reasonable bounds are.

To do this, first alight the south-west corner of the desired map bounds with the bottom-left corner of the browser window and call `map.getBounds()` in the console. Check the value of the `_southWest` property of the logged object.  
Same procedure with the north-east corner of the map bounds, top-left corner of the window and the `_northEeast` property of `map.getBounds()`.

For the best effect, we should configure the detected bounds both in the tile layer as `bounds` as well as in the map as `maxBounds` properties.  
Tile layer `bounds` constraints tile loading - tiles will not be loaded outside the set bounds.  
Map `maxBounds` restricts the view to the given geographical bounds, bouncing the user back if the user tries to pan outside the view.
You can also play with `maxBoundsViscosity` option ranging from `0` (the user can drag outside the bounds at normal speed) to `1` (the bounds are fully solid, the user can't drag outside the bounds).

This is what our final configuration may look like:

```
var map = L.map('map', {
	zoom: 5,
	center: [61, -94],
	maxBounds: [[3.16, -180], [86, 46.03]],
	maxBoundsViscosity: 0.8
});

L.tileLayer('tiles/{z}/{y}/{x}.png', {
	minZoom: 2,
	maxZoom: 7,
	bounds: [[3.16, -180], [86, 46.03]],
	noWrap: true,
	attribution: '<a href="http://www.unece.org/trans/main/sc3/sc3.html">UNECE - Inland Water Transport</a>'
}).addTo(map);
```

# Hosting

The resulting web map client is a completely static and self-sufficient solution.
Since all the tiles are pre-generated, we don't need any special server-side software. This basically means that we can host this slippy map as a static website almost anywhere.

One of the options is [GitHub Pages](https://pages.github.com/). We'll push all the files to the GitHub repository and configure GitHub Pages in project settings.

This will give us an URL like:

**https://fossgis2019.github.io/European-Inland-Waterways/**

(You can even [configure your own domain](https://help.github.com/articles/using-a-custom-domain-with-github-pages/) if you don't like `*.github.io`.) 

The map is now online, hosted as a static website on GitHub pages.

Of course, there are [certain limits](https://help.github.com/articles/what-is-github-pages/) on site size and traffic, but it is normally more than enough for small maps and audiences.