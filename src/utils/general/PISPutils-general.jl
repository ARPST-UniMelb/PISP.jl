function default_data_paths(;filepath=@__DIR__)
    datapath = filepath
    return (
        ispdata19   = normpath(datapath, "2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx"),
        ispdata24   = normpath(datapath, "2024-isp-inputs-and-assumptions-workbook.xlsx"),
        ispmodel    = normpath(datapath, "2024 ISP Model"),
        profiledata = normpath(datapath, "Traces/"),
        outlookdata = normpath(datapath, "Core"),
        outlookAEMO = normpath(datapath, "Auxiliary/CapacityOutlook2024_Condensed.xlsx"),
        vpp_cap     = normpath(datapath, "Auxiliary/StorageCapacityOutlook_2024_ISP.xlsx"),
        vpp_ene     = normpath(datapath, "Auxiliary/StorageEnergyOutlook_2024_ISP.xlsx"),
    )
end