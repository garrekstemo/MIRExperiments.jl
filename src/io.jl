"""
    copy_files!(source, dest, date, timestamps)

Copy all tmp files associated with a sig file to a new directory.
When multiple scans are taken with the spectrometer in LabView,
the individual scans are saved as tmp_yymmdd_hhmmss.lvm in a
TEMP directory for the given date. The average of these scans are saved as
sig_yymmdd_hhmmss.lvm.

The file naming convention is the following:
yymmdd: date where yy is the year, mm is the month, and dd is the day
hhmmss: time where hh is the hour, mm is the minute, and ss is the second and hours are in 24-hour format.
"""
function copy_files!(source, dest, date, timestamps::AbstractVector)

    source = realpath(source)
    date = string(date)
    ext = ".lvm"
    prefix = "sig_"

    if !(isdir(abspath(dest)))
        mkdir(dest)
        println("$(dest) does not exist. Creating directory.")
    else
        dest = realpath(dest)
    end

    # Make all the directories
    source_dir = joinpath(source, date)
    source_temp_dir = joinpath(source_dir, "TEMP")
    dest_dir = joinpath(dest, date)
    dest_tmp_dir = joinpath(dest_dir, "TEMP")
    if !(isdir(dest_dir))
        mkdir(dest_dir)
        mkdir(dest_tmp_dir)
        println("$(dest_dir) does not exist. Creating directory.\n")
    end

    for time in timestamps
        time = string(time)
        datetime = combine_datetime(date, time)
        filename = "$(prefix)$(datetime)$(ext)"
        new_sigpath = joinpath(dest_dir, filename)
        if !(isfile(new_sigpath))
            cp(joinpath(source_dir, filename), new_sigpath) # Copy the averaged sig file
            println("Copying $(filename) to $(new_sigpath)")
        end

        sig_files = filter(x -> last(x, length(ext)) == ext, readdir(source_dir))
        all_timestamps = sort([get_time_from_name(f) for f in sig_files])

        # tmp files have timestamps between the target sig file and the previous one.
        timestamp_index = findfirst(isequal(time), all_timestamps)
        if timestamp_index == 1
            prev_time = all_timestamps[1]
        else
            prev_time = all_timestamps[timestamp_index - 1]
        end
    
        # Now copy all the tmp files
        all_tmp_files = filter(x -> last(x, length(ext)) == ext && !(contains(x, "debug")), readdir(source_temp_dir))
        for f in all_tmp_files
            tmp_time = get_time_from_name(f)

            if tmp_time > prev_time && tmp_time < time
                tmp_file_index = findfirst(contains(tmp_time), all_tmp_files)
                tmp_file = all_tmp_files[tmp_file_index]
                source_path = joinpath(source_temp_dir, tmp_file)
                dest_path = joinpath(dest_tmp_dir, tmp_file)
                if !(isfile(dest_path))
                    cp(source_path, dest_path)
                    println("Copying $(source_path) to $(dest_path)")
                end
            end
        end
    end
end

function get_time_from_name(filename; ext=".lvm")
    chop(filename, head = length("sss_yymmdd_"), tail = length(ext))
end

function combine_datetime(date, time)
    if length(string(date)) != 6
        throw(ArgumentError("Date must be in the format yymmdd"))
    end
    if length(string(time)) != 6
        throw(ArgumentError("Times must be in the format hhmmss"))
    end

    return "$(date)_$(time)"
end
