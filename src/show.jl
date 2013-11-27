## show.jl.  show and print methods for NamedArray
## (c) 2013 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions. 

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution

import Base.print, Base.show, Base.summary, Base.display

function summary(a::NamedArray) 
    if ndims(a)==1
        string(length(a), "-element ", typeof(a))
    else
        string(join(size(a), "x"), " ", typeof(a))
    end
end

print(a::NamedArray) = print(a.array)

## inspired by DataFrames

function show(io::IO, a::NamedArray)
    println(io, summary(a))
    if ndims(a)==2
        (nr,nc) = size(a)
        maxnrow = Base.tty_rows() - 5 # summary, header, dots, + 2 empty lines...
        show(io, a, min(maxnrow, nr))
    else                        # fallback for dim > 2
        for i in 1:length(a.dimnames)
            print(io, " ", a.dimnames[i], ": ")
            print(io, names(a,i)')
        end
        show(io, a.array)
    end
end

function display(d::TextDisplay, v::NamedVector) 
    io = d.io
    println(io, summary(v))
    maxnrow = Base.tty_rows() - 5
    show(io, v, min(maxnrow, length(v)))
end

## compute the ranges to be displayed, plus a total index comprising all ranges. 
function compute_range(maxn, n)
    if maxn < n
        hn = div(maxn,2)
        r = (1:hn, n-hn+1:n)
    else
        r = (1:n,)
    end
    totr = vcat(map(r->[r], r)...)
    r, totr
end

leftalign(s, l) = rpad(s, l, " ")
sprint_colpart(width::Int, s::Vector) = join(map(s->rpad(s, width, " "), s), " ")
function sprint_row(namewidth::Int, name, width::Int, names::Tuple; dots="…")
    s = string(leftalign(name, namewidth), " ", sprint_colpart(width, names[1]))
    if length(names)>1
        s = string(s, " ", dots, "  ", sprint_colpart(width, names[2]))
    end
    s
end

## for 2D printing
function show(io::IO, a::NamedArray, maxnrow::Int)
    @assert ndims(a)==2
    nrow, ncol = size(a)
    ## rows
    rowrange, totrowrange = compute_range(maxnrow, nrow)
    s = [sprint(showcompact, a.array[i,j]) for i=totrowrange, j=1:ncol]
    rowname, colname = names(a)
    colwidth = max(maximum(map(length, s)), maximum(map(length, colname)))
    rownamewidth = maximum(map(length, rowname))
    maxncol = div(Base.tty_cols() - rownamewidth - 1, colwidth+1) # dots, spaces between
    ## columns
    colrange, totcorange = compute_range(maxncol, ncol)
    ## header
    println(io, sprint_row(rownamewidth, " ", colwidth, map(i->colname[i], colrange)))
    ## data
    l = 1
    for i in 1:length(rowrange)
        if i>1
            vdots = map(i->["⋮" for i=1:length(i)], colrange)
            println(io, sprint_row(rownamewidth, " ", colwidth, vdots, dots="⋱"))
        end
        r = rowrange[i]
        for j in 1:length(r)
            row = s[l,:]
            println(io, sprint_row(rownamewidth, rowname[totrowrange[l]], colwidth,
                                   map(r -> row[r], colrange)))
            l += 1
        end
    end
end

function show(io::IO, v::NamedVector, maxnrow::Int) 
    nrow=size(v, 1)
    rownames = names(v)[1]
    rowrange, totrowrange = compute_range(maxnrow, nrow)
    s = [sprint(showcompact, v.array[i]) for i=totrowrange]
    colwidth = maximum(map(length,s))
    rownamewidth = maximum(map(length, rownames))
    l = 1
    for i in 1:length(rowrange)
        if i>1
            vdots = ["⋮"]
            println(io, sprint_row(rownamewidth, " ", colwidth, (vdots,)))
        end
        r = rowrange[i]
        for j in 1:length(r)
            row = s[l]
            println(io, sprint_row(rownamewidth, rownames[totrowrange[l]], colwidth, ([row],)))
            l += 1
        end
    end
end

