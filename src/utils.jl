#Model Frame utils
#Find by Symbol
function findterm(MF::ModelFrame, symbol::Symbol)::Int
    l = length(MF.f.rhs.terms)
    for i = 1:l
        if isa(MF.f.rhs.terms[i], InterceptTerm) continue end
        if MF.f.rhs.terms[i].sym == symbol return i end
    end
    return 0
end
#Return length by Symbol
function termmodellen(MF::ModelFrame, symbol::Symbol)::Int
    id = findterm(MF, symbol)
    return length(MF.f.rhs.terms[id].contrasts.termnames)
end
#Confidence interval
function StatsBase.confint(obj::RBE, alpha::Float64; expci::Bool = false, inv::Bool = false, df = :sat)
    ifv = 1
    if inv ifv = -1 end
    if isa(df, Array{Float64, 1})
        if length(obj.df) != length(df)
            df = obj.df
        end
    elseif isa(df, Symbol)
        if df == :df2
            df  = zeros(length(obj.df))
            df .= obj.df2
        else
            df = obj.df
        end
    end

    a = Array{Tuple{Float64, Float64},1}(undef, length(obj.β)-1)
    for i = 2:length(obj.β)
        a[i-1] = calcci(obj.β[i]*ifv, obj.se[i], df[i], alpha, expci)
    end
    return Tuple(a)
end
function calcci(x::Float64, se::Float64, df::Float64, alpha::Float64, expci::Bool)::Tuple{Float64, Float64}
    q = quantile(TDist(df), 1.0-alpha/2)
    if !expci
        return x-q*se, x+q*se
    else
        return exp(x-q*se), exp(x+q*se)
    end
end
function Base.show(io::IO, obj::Tuple{Vararg{Tuple{Float64, Float64}}})
    for i in obj
        println(io, i)
    end
end
function reml2(obj::RBE, θ::Array{Float64, 1})
    return -2*reml(obj.yv, obj.Zv, rank(ModelMatrix(obj.model).m), obj.Xv, θ, obj.β)
end
function contrast(obj::RBE, L::Matrix{T}) where T <: Real
    lcl  = L*obj.C*L'
    lclr = rank(lcl)
    return (L*obj.β)'*inv(lcl)*(L*obj.β)/lclr
end
function lsm(obj::RBE, L::Matrix{T}) where T <: Real
    lcl  = L*obj.C*L'
    return L*obj.β, sqrt.(lcl)
end
function emm(obj::RBE, fm, lm)
    La = lmean(obj::RBE)'
    L  = La .* fm'
    L  = L  .+ lm'
    return lsm(obj, Matrix(L'))
end
function lmean(obj::RBE)
    #coef  = Array{Float64, 1}(undef, length(obj.factors))
    L    = zeros(length(obj.β))
    L[1] = 1.0
    it    = 2
    for f in obj.factors
        term = findterm(obj.model, f)
        len  = length(obj.model.f.rhs.terms[term].contrasts.termnames)
        dev  = 1/length(obj.model.f.rhs.terms[term].contrasts.levels)
        for i = 1:len
            L[it] = dev
            it  += 1
        end
    end
    return Matrix(L')
end


#-------------------------------------------------------------------------------
function checkdata(X, Z, Xv, Zv, y)
    if size(Z)[2] != 2 error("Size random effect matrix != 2. Not implemented yet!") end
    if length(Xv) != length(Zv) error("Length Xv != Zv !!!") end
    for i = 1:length(Xv)
        if size(Xv[i])[1]  != size(Zv[i])[1] error("Row num of subject $i Xv != Zv !!!") end
    end
end
