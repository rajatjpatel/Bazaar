
//@version=4
study("Zig ", overlay = true)

//Inputs
zigperiod = input(defval = 13, title="ZigZag Period")
showprice = input(defval = true, title = "Show Price")
showperc = input(defval = true, title = "Show Percentage")
showline = input(defval = true, title = "Show Zig Lines")
upcolor = input(defval = color.green, title = "Zig Zag Up Color")
downcolor = input(defval = color.red, title = "Zig Zag Down Color")
txtcol = input(defval = color.white, title = "Text Color")
zigstyle = input(defval = "Solid", title = "Zig Zag Line Style", options = ["Solid", "Dotted"])
zigwidth = input(defval = 3, title = "Zig zag Line Width")
len = input(5, minval=1, title="EMA Length")
src = input(close, title="EMA Source")
out= ema(src, len)

// Bollinger Bands
emaSource = close
emaPeriod = 20
devMultiple = 2
baseline = sma(emaSource, emaPeriod)
plot(baseline, title = "BB Mid Line", color = color.red, transp=100)
stdDeviation = devMultiple * (stdev(emaSource, emaPeriod))
upperBand = (baseline + stdDeviation)
lowerBand = (baseline - stdDeviation)
p1 = plot(upperBand, title = "BB Top", color = #4dd0e1)
p2 = plot(lowerBand, title = "BB Bottom", color = #ce93d8)
fill(p1, p2, color = color.blue)

//Plot (invisible for colors)
plot(out, title="EMA Invis", color=color.blue, transp=100)

//Float
float highs = highestbars(high, zigperiod) == 0 ? high : na
float lows = lowestbars(low, zigperiod) == 0 ? low : na

//Variables
var dir1 = 0
dir1 := iff(highs and na(lows), 1, iff(lows and na(highs), -1, dir1))

truncate(number, decimals) =>
    factor = pow(10, decimals)
    int(number * factor) / factor
    
percent(n1, n2) =>
    ((n1 - n2) / n2) * 100
    
var max_array_size = 10
var ziggyzags = array.new_float(0)

add_to_zigzag(pointer, value, bindex)=>
    array.unshift(pointer, bindex)
    array.unshift(pointer, value)
    if array.size(pointer) > max_array_size
        array.pop(pointer)
        array.pop(pointer)
    
update_zigzag(pointer, value, bindex, dir)=>
    if array.size(pointer) == 0
        add_to_zigzag(pointer, value, bindex)
    else
        if (dir == 1 and value > array.get(pointer, 0)) or (dir == -1 and value < array.get(pointer, 0))
            array.set(pointer, 0, value)
            array.set(pointer, 1, bindex)
        0.

dir1changed = change(dir1)
if highs or lows
    if dir1changed 
        add_to_zigzag(ziggyzags, dir1 == 1 ? highs : lows, bar_index)
    else
        update_zigzag(ziggyzags, dir1 == 1 ? highs : lows, bar_index, dir1)

if array.size(ziggyzags) >= 6
    var line zzline1 = na
    var label zzlabel1 = na
    float val = array.get(ziggyzags, 0)
    int point = round(array.get(ziggyzags, 1))
    if change(val) or change(point)
        float val1 = array.get(ziggyzags, 2)
        int point1 = round(array.get(ziggyzags, 3))
        plabel = tostring(truncate(percent(val,val1), 3)) + "%"
        if change(val1) == 0 and change(point1) == 0
            line.delete(zzline1)
            label.delete(zzlabel1)
        if(showline)
            zzline1 := line.new(x1 = point, x2 = point1, y1 = val, y2 = val1, color = dir1 == 1 ? upcolor : downcolor, width = zigwidth, style = zigstyle == "Solid" ? line.style_solid : line.style_dotted)
        labelcol = dir1 == 1 ? array.get(ziggyzags, 0) > out ? upcolor : downcolor : array.get(ziggyzags, 0) < out ? downcolor : upcolor
        if showperc
            zzlabel1 := label.new(x = point, y = val, text = plabel, color = labelcol, textcolor = txtcol, style = dir1 == 1 ? label.style_label_down : label.style_label_up) 
            
//--High and Low Value--//
actualValue(src, len, isHigh, _style, _yloc, _color) =>
    pivot = nz(src[len])
    isFound = true
    for i = 0 to len - 1
        if isHigh and src[i] > pivot
            isFound := false

        if not isHigh and src[i] < pivot
            isFound := false
    
    for i = len + 1 to 2 * len
        if isHigh and src[i] >= pivot
            isFound := false

        if not isHigh and src[i] <= pivot
            isFound := false

    if isFound and showprice
        label.new(bar_index[len], pivot, tostring(pivot), style=_style, yloc=_yloc, color=_color, textcolor=txtcol)

actualValue(high, zigperiod, true, label.style_label_down, yloc.abovebar, color.green)
actualValue(low, zigperiod, false, label.style_label_up, yloc.belowbar, color.red)

// Alert Conditions (These have potential to repaint! Only use alerts with this if you want to be alerted to a high or low as visually seen, and not as an entry/exit signal)
alertcondition(highs, title='High Alert', message='High Alert')
alertcondition(lows, title='Low Alert', message='Low Alert')
