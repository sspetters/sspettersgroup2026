using Gtk #emloying Gtk.jl for Graphical User Interface
using InspectDR # For plotting
using Reactive # Reactive.jl package, deisgned for Functional Reactive Programming, used for signals and state management
using Colors # For color manipulation in plots
using DataFrames # library for handling tabular data
using Printf #library for formatted output using C-style format strings (Printf function)
using Dates #librrary for handling date and time
using CSV #load and save CSV files, gives access to functions designed for editing text files
using JLD2 #saves and loads Julia data structues to disk
using FileIO #framework for detecting file formats and dispatching them to the correct package for loading and saving
using LibSerialPort #way of communication with hardware via serial ports (sensors or industrial equipment)
using Interpolations #library for interpolation of data points, used for estimating values between known data points
using LinearAlgebra #library for algorithms and operations for matrices and vectors, used for linear algebra computations
using Statistics #stuff for stats
using LambertW #allows you to calculate the Lambert W function("product log" function), which is the inverse function of f(w) = w * exp(w)
using LabjackU6Library #library for controlling Labjack U6 data acquisition device, used for interfacing with hardware and collecting data
using DifferentialMobilityAnalyzers #utilizing a specialized, open-source software package designed to model, analyze, and invert data from DMAs and tandem DMA systems, provides a domain-specific language (JDL) that simplifies the complex mathematics of aerosol science into concise code, allowing for the construction of forward and inverse models to determine particle size distributions.
using Lazy #delays calculating values until is is needed, optimizes performance
using NumericIO #library for efficient reading and writing of numeric data
using Underscores #allows underscores in numeric literals for improved readability
using DataStructures #adds additional structures needed for more advanced computational needs
using RegularizationTools #help stabilize numerical solutions by finding a balance between fitting the data and keeping model parameters small
using CondensationParticleCounters #library for controlling and interfacing with condensation particle counters, used for measuring the concentration of aerosol particles in the air
using Chain #provides a macro to create a pipline of data operation

WITHPOPS = true

import NumericIO: UEXPONENT #selectively import UEXPONENT from NumericIO
(@isdefined wnd) && destroy(wnd) #macro used to check if wnd is already defined, if it is, destroy it to avoid conflicts when reloading the code
config_file = "gui/UCRElectrometer with Magic and POPS.glade"
gui = GtkBuilder(filename = pwd() * "/" * config_file)  #creates object used to build and manage GUIs from config_file, the  file contains the layout and properties of the GUI elements, and GtkBuilder reads this file to construct the GUI in Julia
wnd = gui["mainWindow"] #creates a reference (like a dictionary) to the main window of the GUI

#Include is used for combining files within a project
include("helper_functions.jl")        # Various helpers related to GTK
include("global_constants.jl")        # Reactive Signals global constants
# include("cpc_serial_io.jl")           # CPC I/O
include("hygroclip_io.jl")            # Hygroclip HC2 functions
include("hv_io.jl")                   # High voltage power supply
include("initialize_hardware.jl")     # Assign ports, get Labjack HANDLE
include("labjack_io.jl")              # Labjack channels I/O
include("set_gui_initial_state.jl")   # Initialize graphs 
include("smps_signals.jl")            # SMPS(Scanning Mobiliity Particle Sizer) Logic and Signals
include("daq_loops.jl")               # Contains DAQ loops               
(WITHPOPS == true) && include("pops_io.jl") #conditionally loads POPS I/O functions if WITHPOPS is enabled 

Gtk.showall(wnd)                      # displays all elements of GUI  

# Generate signals
const oneHz = fps(1.0 * 1.0015272)      # 1  Hz time, declared oneHz value and will NOT change, fps = fires per second, creates a timed signal
const slowLoop = fps(0.20)              # Slow loop for dew-point
const tenHz = fps(10.0 * 1.015272)      # 10 Hz time

const main_elapsed_time = foldp(+, 0.0, oneHz) #foldp is a function from Reactive.jl  creates a signal by applying a binary function (addition) cumulatively to the values emitted by the oneHz signal, starting with an initial value of 0.0. Creates a timer that increments every second, giving us the elapsed time in seconds since the program started
const smps_elapsed_time, smps_scan_state, smps_scan_number, termination, reset, V, Vs, Dp =
    smps_signals() #unpacks multiple values (reactive signals) returned by smps_signals function into separate constants

sleep(10) #suspends the execution of  current task for 10s
const signalV = map(
    v -> [getVdac(v[1], :-, true), getVdac(v[2], :-, true), v[3] / 1000.0, v[4] / 1000.0],
    Vs,
) #maps the voltage signals (Vs) to a new array, where each element is transformed using the getVdac function for the first two values and scaled for the last two values. Preparing the voltage signals for use in controlling hardware devices.

sleep(3) #suspends for 3s

const labjack_signals1 = map(v -> labjackReadWrite(HANDLE, v[1], v[2], caliInfo; gain1 = 0), signalV) #maps the signalV array to a new array where each element is transformed using the labjackReadWrite function,  interacts with the Labjack hardware to read and write values based on the provided voltage signals and calibration information

sleep(3)

const labjack_signals2 = map(v -> labjackReadWrite(HANDLE1, v[3], v[4], caliInfo1; caliInfoTdac = caliInfoTdac1, gain1 = 0), signalV) #used a SECOND labjacks devide and includes TDAC calibration information
sleep(5)
const tenHzSMPSLoop = map(_ -> tenHz_smps_loop(), tenHz)   #10 Hz SMPS, maps the tenHz signal to a new array, each element is transformed by tenHz_smps_loop (contains the logic for the SMPS loop that runs at 10 Hz) allows for real-time data acquisition and processing related to the SMPS system.


sleep(5)

const oneHzLoops = map(oneHz) do x #iterates over timer
    push!(datestr, Dates.format(now(), "yyyymmdd")) #gets currents date/time
    @async oneHz_smps_loop()         # 1 Hz SMPS Loop
    @async oneHz_generic_loop()      # Generic 1 Hz DAQ (CPC, TE), runs generic 1Hz data acquisition for other instruments
end

sleep(5)
if WITHPOPS == true #runs only if POPS instrument is enabled
    # POPS Acquisition Loops
    const daqLoop = map(_ -> acquire(), oneHz) #maps oneHZ  signal to acquire(), triggers raw data acquisition from POPS at 1 Hz
    sleep(6)
    const accLoop = map(_ -> accumulate(), oneHz) #maps oneHz signal to accumulate(),processes the acquired POPS data at 1 Hz
end

# const newDay = map(droprepeats(datestr)) do x
#     path3 = path * "Processed/"
#     read(`mkdir -p $path3`)
#     outfile = path3 * SizeDistribution_filename.value
#     @save outfile SizeDistribution_df δˢᵐᵖˢ Λˢᵐᵖˢ inversionParameters
#     try
#         deleterows!(SizeDistribution_df, collect(1:length(SizeDistribution_df[:Timestamp])))
#     catch
#     end
#     try
#         deleterows!(inversionParameters, collect(1:length(inversionParameters[:Timestamp])))
#     catch
#     end
#     push!(SizeDistribution_filename, Dates.format(now(), "yyyymmdd_HHMM") * ".jld2")
# end


# push!(smps_scan_state, "DONE")                # Termination signal to start new file

# signal_connect(selection, "changed") do widget
#     if hasselection(selection)
#         n = @_ map(listStore[_, 1], 1:length(listStore)) |> maximum
#         c = n - listStore[selected(selection), 1]
#         addseries!(
#             reverse(ninv[end].Dp),
#             reverse(ninv[end].S),
#             plot5,
#             gplot5,
#             1,
#             false,
#             true,
#         )
#         addseries!(
#             reverse(ninv[end-c].Dp),
#             reverse(ninv[end-c].S),
#             plot5,
#             gplot5,
#             2,
#             false,
#             true,
#         )
#         addseries!(
#             reverse(response[end].Dp),
#             reverse(response[end].N),
#             plot4,
#             gplot4,
#             2,
#             false,
#             true,
#         )
#         addseries!(
#             reverse(response[end-c].Dp),
#             reverse(response[end-c].N),
#             plot4,
#             gplot4,
#             3,
#             false,
#             true,
#         )
#     end
# end


# :DONE
