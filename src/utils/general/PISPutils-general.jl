function default_data_paths(;filepath=@__DIR__)
    return (
        ispdata19   = normpath(filepath, "2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx"),
        ispdata24   = normpath(filepath, "2024-isp-inputs-and-assumptions-workbook.xlsx"),
        ispmodel    = normpath(filepath, "2024 ISP Model"),
        profiledata = normpath(filepath, "Traces/"),
        outlookdata = normpath(filepath, "Core"),
        outlookAEMO = normpath(filepath, "Auxiliary/CapacityOutlook2024_Condensed.xlsx"),
        vpp_cap     = normpath(filepath, "Auxiliary/StorageCapacityOutlook_2024_ISP.xlsx"),
        vpp_ene     = normpath(filepath, "Auxiliary/StorageEnergyOutlook_2024_ISP.xlsx"),
    )
end