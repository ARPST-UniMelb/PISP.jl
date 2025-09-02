function filterSortTimeseriesData(data, units::NamedTuple,
    start_dt::DateTime, end_dt::DateTime,
    scenario::Int=2,
    filter_by::String="dem_id",
    filter_values::Union{Nothing, Vector{Any}, Vector{Int}}=nothing)
    """
    Returns a DataFrame with the time-series data in the interval start_dt:units.T(units.L):end_dt with columns for the specified filter_by values.

    ---
    Inputs
    - data (DataFrame): The input DataFrame containing the time-series data (e.g. from *_pmax_sched.csv, *_n_sched.csv, *_emax_sched.csv, ...)
    - units (NamedTuple): A NamedTuple specifying the time units (T) and length (L), e.g. (T = Hour, L = 1)
    - start_dt (DateTime): The start date/time for the filtering.
    - end_dt (DateTime): The end date/time for the filtering.
    - scenario (Int): The scenario ID to filter by (default is 2)
    - filter_by (String): The column name to filter by (default is "dem_id")
    - filter_values (Union{Nothing, Vector{Any}, Vector{Int}}): The values to filter by (default is nothing)

    ---
    Example: 
    timeseries_data = filterSortTimeseriesData(data, (T = Hour, L = 1), DateTime("2022-01-01T00:00:00"), DateTime("2022-12-31T23:00:00"), 2, "dem_id", [1, 2, 3])

    """
    
    # ========================================

    if !("date" in names(data))
        error("Date column not found in data!")
    end

    # ========================================
    # Filter the data based on the provided parameters
    filtered_data = filter(row -> row[:scenario] == scenario, data)

    # Then filter by dem_ids, gen_ids, and ess_ids if provided
    if filter_by in names(filtered_data)
        if filter_values !== nothing && !isempty(filter_values)
            filtered_data = filter(row -> row[filter_by] in filter_values, filtered_data)
        end
    else
        error("$filter_by column not found in data! Did you mean $(names(data)[2])?")
    end


    # ========================================
    # Sort the data by date
    sorted_data = sort(filtered_data, :date)

    # ========================================
    # Now convert the data into the required FORMAT
    # (based on units, start_dt and end_dt)
    
    # Step 1: Remove all the timesteps after the relevant period
    filter!(row -> row[:date] .<= end_dt, sorted_data)
    
    # Get all the relevant ids for which there are any changes before or in the selected time
    unique_ids = unique(sorted_data[!,filter_by]) 

    # Step 2: Get the latest value before start_dt for each filter_by value
    until_start_data = filter(row -> row[:date] <= start_dt, sorted_data)

    if nrow(until_start_data) > 0
        # Group by filter_by column and get the latest (maximum date) for each group
        latest_until_start = combine(groupby(until_start_data, filter_by)) do group_df
            return group_df[end, :]
        end
        start_data = unstack(latest_until_start, [], filter_by, :value)
        start_data.date .= start_dt
    end
    # And add the missing columns with a missing value 
    # (in case there is a change within the time-window, but no value beforehand)
    for id in unique_ids
        if !(string(id) in names(start_data))
            start_data[!, string(id)] = Vector{Union{Missing, Int, Float64}}([missing])
        end
    end
    
    # Step 3: Create full date range
    resampled_data = DataFrame(date=start_dt:units.T(units.L):end_dt)

    # Step 4: Combine with start data
    if nrow(until_start_data) > 0
        # Add start values
        result = leftjoin(resampled_data, start_data, on=:date)
    else
        result = copy(resampled_data)
    end

   
    # Step 5: Now add the time-series data within the time-window
    filter!(row -> row[:date] >= start_dt, sorted_data)
    for row in eachrow(sorted_data)
        value_name = string(row[filter_by])  # Convert gen_id to string (column name)
        target_date = DateTime(row.date)     # Extract date for row matching

        # Find the row index where date matches
        date_idx = findfirst(==(target_date), result.date)

        # Update the value if both column and row exist
        if !isnothing(date_idx)
            result[date_idx, value_name] = row.value
        else
            error("Could not find date $target_date within the selected range of $(start_dt:units.T(units.L):end_dt). Doublecheck the data!")
        end
    end


    # Step 6: Add the time-series data within the time-window and forward fill missing values
      
    for col in names(result)
        if col != "date"
            # Simple forward fill
            col_data = result[!, col]
            for i in eachindex(col_data)[2:end] # skip the first row since it cannot be filled from earlier
                if ismissing(col_data[i]) && !ismissing(col_data[i-1])
                    col_data[i] = col_data[i-1]
                end
            end
        end
    end

    return result
end