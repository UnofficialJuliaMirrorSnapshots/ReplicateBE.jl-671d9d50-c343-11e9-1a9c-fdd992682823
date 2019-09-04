# ReplicateBE
# Author: Vladimir Arnautov aka PharmCat
# Copyright © 2019 Vladimir Arnautov aka PharmCat <mail@pharmcat.net>
# Licence: GNU General Public License v3.0

using Test, DataFrames, CSV

include("testdata.jl")

@testset "  Basic mixed model test                        " begin
    df = CSV.read(IOBuffer(minibe)) |> DataFrame
    be = ReplicateBE.rbe(df, dvar = :var, subject = :subject, formulation = :formulation, period = :period, sequence = :sequence, g_tol = 1e-10);
    @test be.β[6]  ≈  -0.0791666 atol=1E-5
    @test be.se[6] ≈   0.09037378448083119 atol=1E-5
    @test be.reml  ≈  10.065238638105903 atol=1E-5
    ci = ReplicateBE.confint(be, 0.1, expci = false, inv = false)
    @test ci[5][1] ≈  -0.25791330363201714 atol=1E-5
    @test ci[5][2] ≈   0.09957997029868393 atol=1E-5

    io = IOBuffer();
    Base.show(io, be)
    #@test io.size == 1518
    io = IOBuffer();
    Base.show(io, ci)
    #@test io.size == 213
end

@testset "  #4 QA 1 Bioequivalence 2x2x4, UnB, NC Dataset " begin
    #REML 530.14451303
    #SE 0.04650
    #DF 208
    df = CSV.read(IOBuffer(be4)) |> DataFrame
    be = ReplicateBE.rbe(df, dvar = :var1, subject = :subject, formulation = :formulation, period = :period, sequence = :sequence, g_tol = 1e-10);
    ci = ReplicateBE.confint(be, 0.1, expci = true, inv = true)
    @test be.reml  ≈  530.1445137281626  atol=1E-5
    @test be.se[6] ≈    0.04650123700721 atol=1E-5
    @test be.f[6]  ≈    9.78552229238432 atol=1E-5
    @test be.df[6] ≈  208.08115303672898 atol=1E-5
    @test ci[5][1] ≈    1.07104135588792 atol=1E-5
    @test ci[5][2] ≈    1.24894237034602 atol=1E-5
end

#Patterson SD, Jones B. Viewpoint: observations on scaled average bioequivalence. Pharm Stat. 2012; 11(1): 1–7. doi:10.1002/pst.498
@testset "  #5 Pub Bioequivalence Dataset                 " begin
    #REML 321.44995530 - SAS STOP!
    df = CSV.read(IOBuffer(be5)) |> DataFrame
    be = ReplicateBE.rbe(df, dvar = :var1, subject = :subject, formulation = :formulation, period = :period, sequence = :sequence, g_tol = 1e-10);
    ci = ReplicateBE.confint(be, 0.1, expci = true, inv = true)
    @test be.reml  ≈  314.2217688405106 atol=1E-5
    @test ci[5][1] ≈    1.1875472284034538 atol=1E-5
    @test ci[5][2] ≈    1.5854215760408064 atol=1E-5
    #119-159%
end

#Shumaker RC, Metzler CM. The Phenytoin Trial is a Case Study of ‘Individual’ Bioequivalence. Drug Inf J. 1998; 32(4): 1063–72
@testset "  #6 Pub Bioequivalence TTRR/RRTT Dataset       " begin
    #REML 329.25749378
    #SE 0.04153
    #DF 62
    #F 2.40
    df = CSV.read(IOBuffer(be6)) |> DataFrame
    be = ReplicateBE.rbe(df, dvar = :var1, subject = :subject, formulation = :formulation, period = :period, sequence = :sequence, g_tol = 1e-10);
    ci = ReplicateBE.confint(be, 0.1, expci = true, inv = true)
    @test be.reml  ≈  329.25749377843033 atol=1E-5
    @test be.f[6]  ≈  2.399661661708039 atol=1E-5
    @test ci[5][1] ≈    0.8754960202413755 atol=1E-5
    @test ci[5][2] ≈    1.0042930817939983 atol=1E-5
end

@testset "  #  Utils test                                 " begin

    df = CSV.read(IOBuffer(be6)) |> DataFrame
    be = ReplicateBE.rbe(df, dvar = :var1, subject = :subject, formulation = :formulation, period = :period, sequence = :sequence, g_tol = 1e-10);
    @test ReplicateBE.contrast(be, [0 0 0 0 0 1]) ≈ 2.399661660365819 atol=1E-5
    lsmean = ReplicateBE.lsm(be, [0 0 0 0 0 1])
    @test lsmean[1][1] ≈ 0.0643403 atol=1E-5
    @test lsmean[2][1] ≈ 0.0415345 atol=1E-5
    lsm = ReplicateBE.emm(be, [1 1 1 1 1 0], [0 0 0 0 0 0])
    @test lsm[1][1]    ≈ 4.616254407007809     atol=1E-5
    @test lsm[2][1]    ≈ 0.08217365963420642   atol=1E-5
    @test ReplicateBE.reml2(be, [0.1, 0.2, 0.3, 0.4, 1.0]) ≈ 357.238054967491   atol=1E-5
end
