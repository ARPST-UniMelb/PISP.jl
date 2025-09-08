# CAPACITY REDUCTIONS FOR CDP 14
Reduction2024 = [
            # PROGRESSIVE CHANGE
                # FLEXIBLE GAS CSA
            Dict("Quarantine"      => [(1,7,2044,106)]),
            # STEP CHANGE
                # FLEXIBLE GAS CSA
            Dict("Quarantine"      => [(1,7,2044,106)]),
            # GREEN ENERGY EXPORTS
                # FLEXIBLE GAS CSA
            Dict("Quarantine"      => [(1,7,2044,106)]),]

# @warn("Retirements for CDP14 - Obtained from Generation & Storage Outlook (2024 ISP)")
# GENERATION RETIREMENTS FOR CDP 14
# @warn("CHECK RETIREMENTS FOR FLEXIBLE GAS UNITS!!")
Retirements2024 = [
                    Dict(# PROGRESSIVE CHANGE ID 1
                    #BLACK COAL
                        #NQ
                        #CQ
                        "Callide B" => [(1,7,2027,0)],                  #OK PROGRESSIVE
                        "Callide C" => [(1,7,2051,0)],                  #OK PROGRESSIVE
                        "Stanwell"  => [(1,7,2029,1), (1,7,2032,0)],    #OK PROGRESSIVE
                        #SQ
                        "Tarong"        => [(1,7,2030,2),(1,7,2032,1),(1,7,2033,0)],    #OK PROGRESSIVE
                        "Tarong North"  => [(1,7,2033,0)],                              #OK PROGRESSIVE
                        "Kogan Creek"   => [(1,7,2034,0)],                              #OK PROGRESSIVE
                        "Millmerran"    => [(1,7,2051,0)],                              #OK PROGRESSIVE
                        #GG
                        "Gladstone"     => [(1,7,2027,3),(1,7,2030,1),(1,7,2031,0)], #OK PROGRESSIVE
                        #NNSW
                        #CNSW
                        "Bayswater"     => [(1,7,2028,3), (1,7,2029,0)],#x4 OK PROGRESSIVE
                        "Mt Piper"      => [(1,7,2040,0)],#x2 OK PROGRESSIVE
                        #SNSW
                        #SNW
                        "Eraring"       => [(1,7,2025,0)],#x4 OK PROGRESSIVE
                        "Vales Point B" => [(1,7,2028,0)],#x2 OK PROGRESSIVE
                    #BROWN COAL 
                        #VIC
                        "Yallourn W"    => [(1,7,2028,0)],#x4 OK PROGRESSIVE
                        "Loy Yang A Power Station"    => [(1,7,2033,0)],#x4 OK PROGRESSIVE
                        "Loy Yang B"    => [(1,7,2034,1),(1,7,2047,0)],#x2 OK PROGRESSIVE
                    #MIDMERIT GAS
                        #NQ
                        "Townsville Power Station"  => [(1,7,2046,0)], #YABULU OK PROGRESSIVE
                        #CQ
                        #SQ
                        "Condamine A"               => [(1,7,2039,0)],  #x3 OK PROGRESSIVE
                        "Darling Downs"             => [(1,7,2045,0)],  #x4 OK PROGRESSIVE
                        "Swanbank E GT"             => [(1,7,2036,0)],  #x1 OK PROGRESSIVE
                        #GG
                        "Yarwun Cogen"              => [(1,7,2050,0)], # OK PROGRESSIVE 
                        #NNSW
                        #CNSW
                        #SNSW
                        #SNW
                        "Tallawarra"                => [(1,7,2043,0)], #OK PROGRESSIVE
                        #VIC
                        "Newport"                   => [(1,7,2028,0)], #OK PROGRESSIVE 
                        #CSA
                        "Osborne"                   => [(1,7,2026,0)], #OK PROGRESSIVE
                        "Torrens Island B"          => [(1,7,2026,0)], #OK PROGRESSIVE
                        "Pelican Point"             => [(1,7,2037,0)], #OK PROGRESSIVE
                        #SESA
                        #TAS
                        "Tamar Valley Combined Cycle"              => [(1,7,2027,0)], #OK PROGRESSIVE
                    #FLEXIBLE GAS
                        #NQ
                        "Mt Stuart"                 => [(1,7,2033,1),(1,7,2044,0)], #x3 OK PROGRESSIVE
                        #CQ
                        "Barcaldine Power Station"  => [(1,7,2034,0)], #OK PROGRESSIVE
                        #SQ
                        "Roma"                      => [(1,7,2034,0)], #OK PROGRESSIVE
                        "Braemar"                   => [(1,7,2046,0)],  #x3 OK PROGRESSIVE
                        "Braemar 2 Power Station"   => [(1,7,2049,0)], #x3 OK PROGRESSIVE
                        "Oakey Power Station"       => [(1,7,2050,0)], #OK PROGRESSIVE
                        #GG
                        #NNSW
                        #CNSW
                        #SNSW
                        "Uranquinty"                  => [(1,7,2044,0)], #OK PROGRESSIVE 
                        #SNW
                        "Smithfield Energy Facility" =>[(1,7,2044,0)], #OK PROGRESSIVE
                        #VIC
                        "Somerton"                      => [(1,7,2033,0)],  #x3 OK PROGRESSIVE
                        "Jeeralang A"                   => [(1,7,2039,0)],  #x4 OK PROGRESSIVE
                        "Jeeralang B"                   => [(1,7,2039,0)],  #x3 OK PROGRESSIVE
                        "Bairnsdale"                    => [(1,7,2042,0)],  #x2 OK PROGRESSIVE
                        "Mortlake"                      => [(1,7,2047,0)],  #x2 OK PROGRESSIVE
                        #CSA
                        "Port Lincoln GT"               => [(1,7,2027,0)],  #x2 OK PROGRESSIVE
                        "Dry Creek GT"                  => [(1,7,2030,0)],  #x3 OK PROGRESSIVE
                        "Mintaro GT"                    => [(1,7,2030,0)],  #x1 OK PROGRESSIVE
                        "Hallett GT"                    => [(1,7,2032,0)],  #OK PROGRESSIVE 
                        "Barker Inlet Power Station"                  => [(1,7,2044,0)],  #OK PROGRESSIVE
                        "Bolivar Power Station"         => [(1,7,2045,0)],  #x1 OK PROGRESSIVE
                        "Snapper Point Power Station"   => [(1,7,2046,0)],  #x5 OK PROGRESSIVE
                        #SESA
                        "Snuggery" => [(1,7,2027,0)],           #x3 OK PROGRESSIVE
                        "Ladbroke Grove" => [(1,7,2035,0)],     #x2 OK PROGRESSIVE
                        #TAS
                        "Bell Bay Three" => [(1,7,2040,0)],     #x3 OK PROGRESSIVE
                        "Tamar Valley Peaking" => [(1,7,2050,0)]#x1 OK PROGRESSIVE 
                    ),

                    Dict(# STEP CHANGE ID 2
                    #BLACK COAL
                        #NQ
                        #CQ
                        "Callide B" => [(1,7,2032,0)],
                        "Callide C" => [(1,7,2033,0)],
                        "Stanwell"  => [(1,7,2027,1), (1,7,2028,0)],
                        #SQ
                        "Tarong"        => [(1,7,2030,2),(1,7,2032,1),(1,7,2033,0)],
                        "Tarong North"  => [(1,7,2033,0)],
                        "Kogan Creek"   => [(1,7,2034,0)],
                        "Millmerran"    => [(1,7,2034,0)],
                        #GG
                        "Gladstone"     => [(1,7,2027,5),(1,7,2029,3),(1,7,2030,1),(1,7,2031,0)],
                        #NNSW
                        #CNSW
                        "Bayswater"     => [(1,7,2029,2), (1,7,2030,1), (1,7,2031,0)],#x4 
                        "Mt Piper"      => [(1,7,2036,1), (1,7,2037,0)],#x2
                        #SNSW
                        #SNW
                        "Eraring"       => [(1,7,2025,0)],#x4
                        "Vales Point B" => [(1,7,2028,0)],#x2
                    #BROWN COAL 
                        #VIC
                        "Yallourn W"    => [(1,7,2028,0)],#x4
                        "Loy Yang A Power Station"    => [(1,7,2033,0)],#x4
                        "Loy Yang B"    => [(1,7,2027,1),(1,7,2031,0)],#x2
                    #MIDMERIT GAS
                        #NQ
                        "Townsville Power Station"  => [(1,7,2046,0)], #YABULU
                        #CQ
                        #SQ
                        "Condamine A"               => [(1,7,2039,0)],  #x3
                        "Darling Downs"             => [(1,7,2045,0)],  #x4
                        "Swanbank E GT"             => [(1,7,2036,0)],  #x1
                        #GG
                        "Yarwun Cogen"              => [(1,7,2050,0)],
                        #NNSW
                        #CNSW
                        #SNSW
                        #SNW
                        "Tallawarra"                => [(1,7,2043,0)],
                        #VIC
                        "Newport"                   => [(1,7,2039,0)],
                        #CSA
                        "Osborne"                   => [(1,7,2026,0)],
                        "Torrens Island B"          => [(1,7,2026,0)],
                        "Pelican Point"             => [(1,7,2037,0)],
                        #SESA
                        #TAS
                        "Tamar Valley Combined Cycle"              => [(1,7,2027,0)],
                    #FLEXIBLE GAS
                        #NQ
                        "Mt Stuart"                 => [(1,7,2033,1),(1,7,2044,0)], #x3
                        #CQ
                        "Barcaldine Power Station"  => [(1,7,2034,0)],
                        #SQ
                        "Roma"                      => [(1,7,2034,0)],
                        "Braemar"                   => [(1,7,2046,0)],#x3
                        "Braemar 2 Power Station"   => [(1,7,2049,0)], #x3
                        "Oakey Power Station"       => [(1,7,2050,0)],
                        #GG
                        #NNSW
                        #CNSW
                        #SNSW
                        "Uranquinty"                  => [(1,7,2044,0)],
                        #SNW
                        "Smithfield Energy Facility" =>[(1,7,2044,0)],
                        #VIC
                        "Somerton"                      => [(1,7,2033,0)],  #x3 
                        "Jeeralang A"                   => [(1,7,2039,0)],#x4
                        "Jeeralang B"                   => [(1,7,2039,0)],#x3
                        "Bairnsdale"                    => [(1,7,2042,0)],#x2
                        "Mortlake"                      => [(1,7,2047,0)],#x2
                        #CSA
                        "Port Lincoln GT"               => [(1,7,2027,0)], #x2
                        "Dry Creek GT"                  => [(1,7,2030,0)],#x3
                        "Mintaro GT"                    => [(1,7,2030,0)],#x1
                        "Hallett GT"                    => [(1,7,2032,0)],
                        "Barker Inlet Power Station"                  => [(1,7,2044,0)],
                        "Bolivar Power Station"         => [(1,7,2045,0)],#x1
                        "Snapper Point Power Station"   => [(1,7,2046,0)], #x5
                        #SESA
                        "Snuggery" => [(1,7,2027,0)], #x3
                        "Ladbroke Grove" => [(1,7,2035,0)],#x2
                        #TAS
                        "Bell Bay Three" => [(1,7,2040,0)],#x3
                        "Tamar Valley Peaking" => [(1,7,2050,0)]#x1
                    ),

                    Dict(# GREEN ENERGY EXPORTS ID 3
                    #BLACK COAL
                        #NQ
                        #CQ
                        "Callide B" => [(1,7,2027,0)],                              #OK GREEN
                        "Callide C" => [(1,7,2030,0)],                              #OK GREEN
                        "Stanwell"  => [(1,7,2028,3), (1,7,2029,1), (1,7,2030,0)], #x4 OK GREEN
                        #SQ
                        "Tarong"        => [(1,7,2027,0)],               #OK GREEN
                        "Tarong North"  => [(1,7,2027,0)],               #OK GREEN
                        "Kogan Creek"   => [(1,7,2028,0)],               #OK GREEN
                        "Millmerran"    => [(1,7,2030,1), (1,7,2033,0)], #OK GREEN 
                        #GG
                        "Gladstone"     => [(1,7,2029,4),(1,7,2030,0)],  #OK GREEN
                        #NNSW
                        #CNSW
                        "Bayswater"     => [(1,7,2028,3), (1,7,2029,0)],#x4 OK GREEN
                        "Mt Piper"      => [(1,7,2030,1), (1,7,2031,0)],#x2 OK GREEN
                        #SNSW
                        #SNW
                        "Eraring"       => [(1,7,2025,0)],              #x4 OK GREEN
                        "Vales Point B" => [(1,7,2027,1), (1,7,2028,0)],#x2 OK GREEN
                    #BROWN COAL 
                        #VIC
                        "Yallourn W"    => [(1,7,2028,0)],#x4 OK GREEN
                        "Loy Yang A Power Station"    => [(1,7,2027,0)],#x4 OK GREEN
                        "Loy Yang B"    => [(1,7,2031,0)],#x2 OK GREEN
                    #MIDMERIT GAS
                        #NQ
                        "Townsville Power Station"  => [(1,7,2046,0)], #YABULU OK GREEN
                        #CQ
                        #SQ
                        "Condamine A"               => [(1,7,2039,0)],  #x3 OK GREEN
                        "Darling Downs"             => [(1,7,2045,0)],  #x4 OK GREEN
                        "Swanbank E GT"             => [(1,7,2036,0)],  #x1 OK GREEN
                        #GG
                        "Yarwun Cogen"              => [(1,7,2050,0)], #OK GREEN
                        #NNSW
                        #CNSW
                        #SNSW
                        #SNW
                        "Tallawarra"                => [(1,7,2043,0)], #OK GREEN
                        #VIC
                        "Newport"                   => [(1,7,2036,0)], #OK GREEN
                        #CSA
                        "Osborne"                   => [(1,7,2026,0)], #OK GREEN
                        "Torrens Island B"          => [(1,7,2026,0)], #OK GREEN
                        "Pelican Point"             => [(1,7,2037,0)], #OK GREEN
                        #SESA
                        #TAS
                        "Tamar Valley Combined Cycle"              => [(1,7,2027,0)], #OK GREEN
                    #FLEXIBLE GAS
                        #NQ
                        "Mt Stuart"                 => [(1,7,2033,1),(1,7,2044,0)], #x3 OK GREEN
                        #CQ
                        "Barcaldine Power Station"  => [(1,7,2034,0)], #OK GREEN
                        #SQ
                        "Roma"                      => [(1,7,2034,0)],  #OK GREEN
                        "Braemar"                   => [(1,7,2046,0)],  #x3 OK GREEN
                        "Braemar 2 Power Station"   => [(1,7,2049,0)],  #x3 OK GREEN
                        "Oakey Power Station"       => [(1,7,2050,0)],  #OK GREEN
                        #GG
                        #NNSW
                        #CNSW
                        #SNSW
                        "Uranquinty"                  => [(1,7,2044,0)], #OK GREEN
                        #SNW
                        "Smithfield Energy Facility" =>[(1,7,2044,0)],#OK GREEN
                        #VIC
                        "Somerton"                      => [(1,7,2033,0)],  #x3 OK GREEN
                        "Jeeralang A"                   => [(1,7,2039,0)],  #x4 OK GREEN
                        "Jeeralang B"                   => [(1,7,2039,0)],  #x3 OK GREEN
                        "Bairnsdale"                    => [(1,7,2042,0)],  #x2 OK GREEN
                        "Mortlake"                      => [(1,7,2047,0)],  #x2 OK GREEN
                        #CSA
                        "Port Lincoln GT"               => [(1,7,2027,0)],  #x2 OK GREEN
                        "Dry Creek GT"                  => [(1,7,2030,0)],  #x3 OK GREEN
                        "Mintaro GT"                    => [(1,7,2030,0)],  #x1 OK GREEN
                        "Hallett GT"                    => [(1,7,2032,0)],  #OK GREEN
                        "Barker Inlet Power Station"                  => [(1,7,2044,0)],  #OK GREEN
                        "Bolivar Power Station"         => [(1,7,2045,0)],  #x1 OK GREEN
                        "Snapper Point Power Station"   => [(1,7,2046,0)],  #x5 OK GREEN
                        #SESA
                        "Snuggery"          => [(1,7,2027,0)],  #x3 OK GREEN
                        "Ladbroke Grove"    => [(1,7,2035,0)],  #x2 OK GREEN
                        #TAS
                        "Bell Bay Three"        => [(1,7,2040,0)],  #x3 OK GREEN
                        "Tamar Valley Peaking"  => [(1,7,2050,0)]   #x1 OK GREEN

                    ),

]