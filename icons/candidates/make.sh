#!/bin/bash
# Draws the ReaCat icon candidates: 30x30, black background, a white cat face. Drawn on a 8x canvas (240 px) and reduced, so the lines are smooth.
# Coordinates below are in the 30-unit space; s() multiplies by 8.
export LC_ALL=C
s() { awk -v a="$1" 'BEGIN{printf "%.2f", a*8}'; }
P() { s $1; printf ","; s $2; }                       # a point "x,y"
mk() { # name  drawing-args...
  local name="$1"; shift
  convert -size 240x240 xc:black -fill none "$@" -filter Lanczos -resize 30x30 -depth 8 "PNG24:$name"
}
ear() { echo "$(P $1 $2) $(P $3 $4) $(P $5 $6)"; }

# A: outline face, round eyes, nose, mouth, whiskers
mk ReaCat_A.png \
  -stroke white -strokewidth 11 -fill black \
  -draw "polygon $(ear 6 13 6.5 3.5 13.5 9)" -draw "polygon $(ear 24 13 23.5 3.5 16.5 9)" \
  -draw "ellipse $(P 15 17) $(P 10 8.6) 0,360" \
  -stroke none -fill white \
  -draw "circle $(P 11 15.5) $(P 11 17)" -draw "circle $(P 19 15.5) $(P 19 17)" \
  -draw "polygon $(ear 13.8 19 16.2 19 15 20.4)" \
  -stroke white -strokewidth 6 -fill none \
  -draw "line $(P 15 20.4) $(P 15 21.6)" -draw "path 'M $(P 15 21.6) Q $(P 14.4 23) $(P 13 22.7)'" -draw "path 'M $(P 15 21.6) Q $(P 15.6 23) $(P 17 22.7)'" \
  -draw "line $(P 8.6 19.4) $(P 3.4 18.4)" -draw "line $(P 8.6 21) $(P 3.4 22.6)" \
  -draw "line $(P 21.4 19.4) $(P 26.6 18.4)" -draw "line $(P 21.4 21) $(P 26.6 22.6)"

# B: solid white face, black eyes and nose, white whiskers outside
mk ReaCat_B.png \
  -stroke none -fill white \
  -draw "polygon $(ear 6 13 6.5 3.5 13.5 9)" -draw "polygon $(ear 24 13 23.5 3.5 16.5 9)" \
  -draw "ellipse $(P 15 17) $(P 10 8.6) 0,360" \
  -fill black \
  -draw "ellipse $(P 11 15.5) $(P 1.5 1.9) 0,360" -draw "ellipse $(P 19 15.5) $(P 1.5 1.9) 0,360" \
  -draw "polygon $(ear 13.6 19.2 16.4 19.2 15 20.7)" \
  -stroke black -strokewidth 6 -fill none \
  -draw "path 'M $(P 15 20.7) L $(P 15 21.8)'" -draw "path 'M $(P 15 21.8) Q $(P 14.4 23.2) $(P 13 22.8)'" -draw "path 'M $(P 15 21.8) Q $(P 15.6 23.2) $(P 17 22.8)'" \
  -stroke white -strokewidth 6 \
  -draw "line $(P 5 19.2) $(P 0.8 18)" -draw "line $(P 5 21) $(P 0.8 22.6)" \
  -draw "line $(P 25 19.2) $(P 29.2 18)" -draw "line $(P 25 21) $(P 29.2 22.6)"

# C: outline face, slit eyes (a white eye with a black vertical pupil), small nose
mk ReaCat_C.png \
  -stroke white -strokewidth 11 -fill black \
  -draw "polygon $(ear 6 13 6.5 3.5 13.5 9)" -draw "polygon $(ear 24 13 23.5 3.5 16.5 9)" \
  -draw "ellipse $(P 15 17) $(P 10 8.6) 0,360" \
  -stroke none -fill white \
  -draw "ellipse $(P 10.8 15) $(P 2.4 2.7) 0,360" -draw "ellipse $(P 19.2 15) $(P 2.4 2.7) 0,360" \
  -fill black \
  -draw "ellipse $(P 10.8 15) $(P 0.6 2.3) 0,360" -draw "ellipse $(P 19.2 15) $(P 0.6 2.3) 0,360" \
  -fill white \
  -draw "polygon $(ear 14.1 19.6 15.9 19.6 15 20.7)" \
  -stroke white -strokewidth 6 -fill none \
  -draw "path 'M $(P 15 20.7) L $(P 15 21.7)'" -draw "path 'M $(P 12.8 22.9) Q $(P 15 22.6) $(P 15 21.7) Q $(P 15 22.6) $(P 17.2 22.9)'"

# D: sleepy cat: solid white, closed eyes (black arcs), nose, "w" mouth
mk ReaCat_D.png \
  -stroke none -fill white \
  -draw "polygon $(ear 6 13 6.5 3.5 13.5 9)" -draw "polygon $(ear 24 13 23.5 3.5 16.5 9)" \
  -draw "ellipse $(P 15 17) $(P 10 8.6) 0,360" \
  -stroke black -strokewidth 8 -fill none \
  -draw "path 'M $(P 8.6 16.2) Q $(P 11 13.4) $(P 13.4 16.2)'" -draw "path 'M $(P 16.6 16.2) Q $(P 19 13.4) $(P 21.4 16.2)'" \
  -stroke none -fill black \
  -draw "polygon $(ear 13.7 18.9 16.3 18.9 15 20.3)" \
  -stroke black -strokewidth 6 -fill none \
  -draw "path 'M $(P 12.4 21.6) Q $(P 13.7 23.4) $(P 15 21.7) Q $(P 16.3 23.4) $(P 17.6 21.6)'"
