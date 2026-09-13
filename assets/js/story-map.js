/*****************************************************
STORY MAP ENGINE

Places a historic map image on real coordinates and draws GeoJSON on top of it.
Optionally lets passages of text drive the view as the reader scrolls.

The georeferencing here is deliberately the simple kind: you give an image and
the latitude/longitude of its corners, and Leaflet stretches it to fit. That is
all `L.imageOverlay` does. It cannot correct a map whose projection differs
from the modern one — and most historic maps do differ — so expect the fit to
be approximate. For a scrollytelling essay that is usually the honest result
anyway: the point is showing how a mapmaker saw the place, not asserting that
their survey was accurate.

Loads:    via maps/story-map.html and maps/figure-map.html
Used by:  those includes; not called directly from page content
Needs:    Leaflet (the includes load it), story-map.css
Not here: the collection map (nav/map.html) — different job, different data
*****************************************************/

(function () {
  'use strict';

  var REDUCED_MOTION = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function warn(el, message) {
    console.warn('Xanthan story map: ' + message);
    if (!el) return;
    var box = document.createElement('div');
    box.className = 'xanthan-warning';
    box.textContent = 'Story map: ' + message;
    el.appendChild(box);
  }

  function readJSON(el, attr) {
    try { return JSON.parse(el.getAttribute(attr) || 'null'); }
    catch (e) { return null; }
  }

  /* Colours live in base.css as --map-* tokens so themes can restyle a map
     without touching JavaScript. They have to be resolved to real values here:
     Leaflet passes them straight through to SVG presentation attributes, and
     var() does not resolve in that position. */
  function token(el, name, fallback) {
    var value = getComputedStyle(el).getPropertyValue(name).trim();
    return value || fallback;
  }

  /* "32.4, -119.7, 37.1, -106.3" arrives from Liquid as four strings. Coerce
     here rather than in the template: Liquid cannot tell a number from a typo,
     and a silent NaN puts the overlay somewhere off the coast of Africa. */
  function toBounds(raw) {
    if (!raw || raw.length !== 4) return null;
    var n = raw.map(parseFloat);
    if (n.some(isNaN)) return null;
    return [[n[0], n[1]], [n[2], n[3]]];
  }

  function toLatLng(raw) {
    if (!raw || raw.length !== 2) return null;
    var n = raw.map(parseFloat);
    return n.some(isNaN) ? null : n;
  }

  // ---------------------------------------------------------------- features

  function featureStyle(feature, cfg, highlighted) {
    var dim = highlighted && feature.properties.name !== highlighted;
    return {
      color: cfg.routeColor,
      weight: dim ? 2 : 4,
      opacity: dim ? 0.25 : 0.95
    };
  }

  function popupHTML(props) {
    var html = '<div class="story-map-popup">';
    if (props.name) html += '<h3>' + props.name + '</h3>';
    if (props.place) html += '<p class="story-map-popup-place">' + props.place + '</p>';
    if (props.description) html += '<p class="story-map-popup-text">' + props.description + '</p>';
    if (props.url) {
      html += '<p><a href="' + props.url + '" target="_blank" rel="noopener">More information</a></p>';
    }
    return html + '</div>';
  }

  function addData(map, geo, cfg, state) {
    state.layer = L.geoJSON(geo, {
      style: function (f) { return featureStyle(f, cfg, state.highlight); },
      pointToLayer: function (f, latlng) {
        return L.circleMarker(latlng, {
          radius: 6, weight: 2, color: cfg.markerEdge,
          fillColor: cfg.placeColor, fillOpacity: 0.95
        });
      },
      onEachFeature: function (f, layer) {
        var p = f.properties || {};
        if (p.name) layer.bindTooltip(p.name, { sticky: true });
        if (p.description || p.url) layer.bindPopup(popupHTML(p), { maxWidth: 320 });
      }
    }).addTo(map);

    if (!state.hasInitialView && state.layer.getBounds().isValid()) {
      map.fitBounds(state.layer.getBounds(), { padding: [24, 24] });
    }
  }

  /* Re-styling on highlight only touches paths. Circle markers are paths too,
     so setStyle reaches both; tooltips and popups are left alone. */
  function applyHighlight(state, cfg) {
    if (!state.layer) return;
    state.layer.eachLayer(function (layer) {
      if (!layer.feature || !layer.setStyle) return;
      if (layer.feature.geometry.type === 'Point') {
        var dim = state.highlight && layer.feature.properties.name !== state.highlight;
        layer.setStyle({ opacity: dim ? 0.3 : 1, fillOpacity: dim ? 0.2 : 0.95 });
      } else {
        layer.setStyle(featureStyle(layer.feature, cfg, state.highlight));
      }
    });
  }

  // -------------------------------------------------------------------- steps

  function wireSteps(map, mapId, cfg, state) {
    var steps = Array.prototype.slice.call(
      document.querySelectorAll('.story-map-step[data-map-id="' + mapId + '"]')
    );
    if (!steps.length) return;

    var visible = [];

    function go(step) {
      var s = readJSON(step, 'data-step') || {};
      var center = toLatLng(s.center);
      var zoom = s.zoom === undefined ? map.getZoom() : parseFloat(s.zoom);

      if (center) {
        if (REDUCED_MOTION) map.setView(center, zoom, { animate: false });
        else map.flyTo(center, zoom, { duration: 1.4 });
      }
      if (s.overlay && state.overlay) {
        state.overlay.setUrl(s.overlay);
      }
      if (s.opacity !== undefined && state.overlay) {
        state.overlay.setOpacity(parseFloat(s.opacity));
      }
      var next = s.highlight || null;
      if (next !== state.highlight) {
        state.highlight = next;
        applyHighlight(state, cfg);
      }
    }

    function apply() {
      if (!visible.length) return;          // between steps: hold the last view
      visible.sort(function (a, b) { return steps.indexOf(a) - steps.indexOf(b); });
      if (visible[0] === state.current) return;
      state.current = visible[0];
      go(state.current);
    }

    /* Same trigger band as scrollybox/bg-switch.html: rootMargin collapses the
       viewport to a strip across the middle, and whichever step sits in that
       strip is the current one. Percentages survive a resize and a rotation
       without any recalculation. */
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        var i = visible.indexOf(entry.target);
        if (entry.isIntersecting && i === -1) visible.push(entry.target);
        if (!entry.isIntersecting && i !== -1) visible.splice(i, 1);
      });
      apply();
    }, { rootMargin: '-45% 0px -50% 0px', threshold: 0 });

    steps.forEach(function (el) { observer.observe(el); });
  }

  // --------------------------------------------------------------------- init

  function create(el) {
    if (el.dataset.storyMapReady === 'on') return;
    el.dataset.storyMapReady = 'on';

    var cfg = readJSON(el, 'data-story-map');
    if (!cfg) { warn(el, 'the configuration could not be read.'); return; }

    cfg.routeColor = cfg.routeColor || token(el, '--map-route', '#8c2f10');
    cfg.placeColor = cfg.placeColor || token(el, '--map-place', '#f59e0b');
    cfg.markerEdge = cfg.markerEdge || token(el, '--map-marker-edge', '#2d3e35');

    var interactive = cfg.interactive !== false;
    var map = L.map(el, {
      // The page scrolls; the map must not swallow the wheel to zoom itself.
      scrollWheelZoom: false,
      dragging: interactive,
      zoomControl: interactive,
      doubleClickZoom: interactive,
      touchZoom: interactive,
      keyboard: interactive,
      attributionControl: true
    });

    var state = { highlight: null, current: null, layer: null, overlay: null,
                  hasInitialView: false };

    /* The Leaflet map is parked on its own element so it can be reached from
       the console or from a page's own script — `document.getElementById('trail')
       ._xanthanMap.getCenter()`. Nothing in this file reads it back; it exists
       for debugging a map that is not going where you expected, and for
       authors who want to add a layer of their own. */
    el._xanthanMap = map;

    if (cfg.basemap) {
      L.tileLayer(cfg.basemap, {
        opacity: cfg.basemapOpacity === undefined ? 0.5 : cfg.basemapOpacity,
        attribution: cfg.basemapAttribution || ''
      }).addTo(map);
    }

    if (cfg.overlay) {
      var bounds = toBounds(cfg.overlayBounds);
      if (!bounds) {
        warn(el, 'overlay-bounds needs four numbers: south, west, north, east.');
      } else {
        state.overlay = L.imageOverlay(cfg.overlay, bounds, {
          opacity: cfg.overlayOpacity === undefined ? 0.9 : cfg.overlayOpacity,
          alt: cfg.overlayAlt || '',
          attribution: cfg.attribution || ''
        }).addTo(map);
        map.fitBounds(bounds);
        state.hasInitialView = true;
      }
    }

    var center = toLatLng(cfg.center);
    if (center) {
      map.setView(center, cfg.zoom === undefined ? 6 : parseFloat(cfg.zoom));
      state.hasInitialView = true;
    }
    if (!state.hasInitialView) map.setView([39.5, -105], 5);   // last resort

    if (cfg.geojson) {
      fetch(cfg.geojson)
        .then(function (r) {
          if (!r.ok) throw new Error(r.status + ' ' + r.statusText);
          return r.json();
        })
        .then(function (geo) {
          addData(map, geo, cfg, state);
          applyHighlight(state, cfg);
          wireSteps(map, el.id, cfg, state);
        })
        .catch(function (e) {
          warn(el, 'could not load ' + cfg.geojson + ' (' + e.message + ').');
          wireSteps(map, el.id, cfg, state);
        });
    } else {
      wireSteps(map, el.id, cfg, state);
    }
  }

  function init() {
    var maps = document.querySelectorAll('.story-map[data-story-map]');
    if (!maps.length) return;
    if (typeof L === 'undefined') {
      Array.prototype.forEach.call(maps, function (el) {
        warn(el, 'Leaflet did not load, so the map cannot be drawn.');
      });
      return;
    }
    Array.prototype.forEach.call(maps, create);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
}());
