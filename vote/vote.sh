#!/bin/bash
z vote
# EPSG:3310 California Albers
PROJECTION='d3.geoAlbers()'

#Census Key
CENSUS_KEY=e838894b904b5fdfa136cc2a52397edec819678

# The state FIPS code.
STATE=us

# The ACS 5-Year Estimate vintage.
YEAR=2014

# The display size.
WIDTH=960
HEIGHT=1100

# Download the census block group boundaries.
# Extract the shapefile (.shp) and dBASE (.dbf).
if [ ! -f cb_${YEAR}_${STATE}_county_500k.shp ]; then
  curl -o cb_${YEAR}_${STATE}_county_500k.zip \
    "http://www2.census.gov/geo/tiger/GENZ${YEAR}/shp/cb_${YEAR}_${STATE}_county_500k.zip"
  unzip -o \
    cb_${YEAR}_${STATE}_county_500k.zip \
    cb_${YEAR}_${STATE}_county_500k.shp \
    cb_${YEAR}_${STATE}_county_500k.dbf
fi

###Shape to Json
shp2json cb_2014_us_county_500k.shp -o us.json

###Set Projection
geoproject 'd3.geoAlbers()' < us.json > us-albers.json

###Preview in svg
geo2svg -w 960 -h 960 < us-albers.json > us-albers.svg

## make map ndjson
ndjson-split 'd.features' \
  < us-albers.json \
  > us-albers.ndjson


##
ndjson-map 'd.id = d.properties.GEOID, d'\
  < us-albers.ndjson \
  > us-albers-id.ndjson

###Convert Population Data to ndjson file
ndjson-cat edata1.json \
  |ndjson-split 'd.slice(1)'\
  |ndjson-map '{id:d["combined_fips"], percent:d["Diff_percent"]}'\
   > edata2.ndjson


##Join the Data ----------This is not working.  I think it's because the id in us-albers-id.ndjson has fewer leading zeros than edata2.ndjson which has leading zeros. 
ndjson-join 'd.id' \
  us-albers-id.ndjson\
  edata2.ndjson \
  > us-albers-join.ndjson

####Below here is just an example

# 1. Convert to GeoJSON.
# 2. Project.
# 3. Join with the census data.
# 4. Compute the population density.
# 5. Simplify.
# 6. Compute the county borders.
geo2topo -n \
  blockgroups=<(ndjson-join 'd.id' \
    <(shp2json cb_${YEAR}_${STATE}_county_500k.shp \
      | geoproject "${PROJECTION}.fitExtent([[10, 10], [${WIDTH} - 10, ${HEIGHT} - 10]], d)" \
      | ndjson-split 'd.features' \
      | ndjson-map 'd.id = d.properties.GEOID.slice(2), d') \
    <(cat edata2.ndjson \
    | ndjson-map '{id: d[2] + d[3] + d[4], B01003: +d[0]}') \
    | ndjson-map -r d3=d3-array 'd[0].properties = {pop: d3.bisect([1, 10, 20, 30, 40, 50, 60, 70, 80, 90,100], (d[1].percent)}, d[0]') \
  | topomerge -k 'd.properties.density' blockgroups=blockgroups \
  | toposimplify -p 1 -f \
  > topo.json