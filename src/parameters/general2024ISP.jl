# States
ST = ["QLD","NSW","VIC","TAS","SA"]
# States ID
STID = Dict("QLD"   =>  1, 
            "NSW"   =>  2, 
            "VIC"   =>  3, 
            "TAS"   =>  4, 
            "SA"    =>  5)

STSOL = ["QLD", "NSW", "VIC", "SA"]
# Bus names
NEMBUSNAME = OrderedDict(
                        "NQ"    => "Northern Queensland",
                        "CQ"    => "Central Queensland",
                        "GG"    =>  "Gladstone Grid", 
                        "SQ"    =>  "Southern Queensland", 
                        "NNSW"  =>  "Northern New South Wales", 
                        "CNSW"  =>  "Central New South Wales", 
                        "SNW"   =>  "Sydney, Newcastle & Wollongong", 
                        "SNSW"  =>  "Southern New South Wales", 
                        "VIC"   =>  "Victoria", 
                        "TAS"   =>  "Tasmania", 
                        "CSA"   =>  "Central South Australia",
                        "SESA"  => "South East South Australia")
# Buses locations            
NEMBUSES = OrderedDict(        "NQ"    => [-17.79385, 145.5635],       #1
                        "CQ"    =>  [-22.82420, 149.40361],     #2
                        "GG"    =>  [-23.842948, 151.248803],   #3
                        "SQ"    =>  [-27.476625,153.029934],    #4
                        "NNSW"  =>  [-30.504711, 151.652465],   #5
                        "CNSW"  =>  [-33.483300, 150.157717],   #6
                        "SNW"   =>  [-33.865,151.209444],       #7
                        "SNSW"  =>  [-35.110980,147.359907],    #8
                        "VIC"   =>  [-37.766053,144.943397],    #9 
                        "TAS"   =>  [-42.880556,147.325],       #10
                        "CSA"   =>  [-34.80268, 138.52164],     #11
                        "SESA"  =>  [-37.60470, 140.8373])      #12
# Areas (market model)
NEMAREAS = OrderedDict(        "QLD"   =>  "Queensland",
                        "NSW"   =>  "New South Wales",
                        "VIC"   =>  "Victoria",
                        "TAS"   =>  "Tasmania",
                        "SA"    =>  "South Australia")
# Relation between areas and buses
BUS2AREA = OrderedDict(        "NQ"    =>  "QLD",
                        "CQ"    =>  "QLD",
                        "GG"    =>  "QLD",
                        "SQ"    =>  "QLD",
                        "NNSW"  =>  "NSW",
                        "CNSW"  =>  "NSW",
                        "SNW"   =>  "NSW",
                        "SNSW"  =>  "NSW",
                        "VIC"   =>  "VIC",
                        "TAS"   =>  "TAS",
                        "CSA"   =>  "SA",
                        "SESA"  => "SA")

#IDs of scenarios
ID2SCE = OrderedDict(
                1 => "Progressive Change", 
                2 => "Step Change", 
                3 => "Green Energy Exports")
# Scenarios
SCE = OrderedDict(
            "Progressive Change"        => 1, 
            "Step Change"               => 2, 
            "Green Energy Exports"      => 3)

SCE2 = OrderedDict(
            "Progressive"   => 1, 
            "Step"          => 2, 
            "Green"         => 3)

ID2SCE2 = Dict(1 => "Progressive Change", 2 => "Step Change", 3 => "Hydrogen Export")

# Hydro inflow files mapping
HYDROSCE = OrderedDict(
                "Progressive Change"    => "NetZero2050",
                "Step Change"           => "StepChange",
                "Green Energy Exports"  => "HydrogenSuperpower")