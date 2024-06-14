"""
    copy_files!(source, dest, datetime)

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

    datetimes = combine_datetimes(date, timestamps)
    source = realpath(source)

    if !(isdir(abspath(dest)))
        mkdir(dest)
    else
        dest = realpath(dest)
    end

    for ts in timestamps
        filename = "sig_$(ts).lvm"

        # Make all the new directories
        dir = joinpath(source, date)
        temp_dir = joinpath(dir, "TEMP")
        new_dir = joinpath(dest, date)
        new_tmp_dir = joinpath(new_dir, "TEMP")
        if !(isdir(new_dir))
            mkdir(new_dir)
            mkdir(new_tmp_dir)
        end
        new_sigpath = joinpath(new_dir, filename)
        if !(isfile(new_sigpath))
            cp(joinpath(dir, filename), new_sigpath) # Copy the averaged file
        end

        sigfiles = filter(x -> last(x, 4) == ".lvm", readdir(dir))
        times_here = sort([get_time_from_name(f) for f in sigfiles])

        # tmp files are between the target sig file and the previous one.
        if findfirst(isequal(time), times_here) == 1
            prev_time = times_here[1]
        else
            prev_time = times_here[findfirst(isequal(time), times_here) - 1]
        end
    
        # Now copy all the tmp files
        all_tmp_files = filter(x -> last(x, 4) == ".lvm" && !(contains(x, "debug")), readdir(temp_dir))
        for f in all_tmp_files
            tmp_time = get_time_from_name(f)

            if tmp_time > prev_time && tmp_time < time
                tmp_file = all_tmp_files[findfirst(contains(tmp_time), all_tmp_files)]
                current_path = joinpath(temp_dir, tmp_file)
                new_path = joinpath(new_tmp_dir, tmp_file)
                if !(isfile(new_path))
                    cp(current_path, new_path)
                end
            end
        end
    end
end

function get_time_from_name(filename; ext=".lvm")
    chop(filename, head = length("sss_yymmdd_"), tail = length(ext))
end

function combine_datetimes(date, times)
    ["$(date)_$(time)" for time in times]
end
