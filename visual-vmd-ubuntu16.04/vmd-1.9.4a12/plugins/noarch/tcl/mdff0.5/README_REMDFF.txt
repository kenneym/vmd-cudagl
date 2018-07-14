
This directory contains Tcl scripts that implement the beta release of MDFF resolution exchange.

*** NET, IBVERBS, AND MULTICORE BUILDS ARE NOT SUPPORTED. ***

Charm++ 6.5.0 or newer for netlrts, verbs, mpi, gni, pamilrts, or other
machine layers based on the lrts low-level runtime implementation
are required for replica functionality based on Charm++ partitions.
A patched version of Charm++ is no longer required.

Replica exchanges and energies are recorded in the .history files
written in the output directories.  These can be viewed with, e.g.,
"xmgrace output/*/*.history" and processed via awk or other tools.
There is also a script to load the output into VMD and color each
frame according to replica index.  

replica-mdff.namd - master script for replica exchange simulations
remdff.namd - main NAMD configuration file
  to run: ./resetmaps.sh
          charmrun ++local +p6 /home/ubuntu/NAMD_2.11_Linux-x86_64-netlrts/namd2 +replicas 6 remdff.namd +stdout output/%d/job0.%d.log

NOTE: The number of NAMD processes (e.g., +p6) must be a multiple of the number of replicas
(+replicas).  Be sure to increment jobX for +stdout option on command line.

NOTE: Unless you used the MDFF GUI to generate these simulation files
and selected "Automatically Generate Replica Potentials", then you will have to
create your own smoothed potentials using the following VMD command:

volutil -smooth $sigma $densityfile -o $smootheddxfile.dx

where $sigma is the gaussian blur width, $densityfile is your target density, and
$smootheddxfile.dx is the name of the output file (make sure to include .dx as the file
extension!). Then, for each density map created this way, you will have to turn
it into a potential file using the following command:

mdff griddx -i "$smootheddxfile.dx" -o "initialmaps/$i.dx"

where "$smootheddxfile.dx" is the name of the smoothed density file you created and "$i" is an integer 
beginning at 0. Each subsequent
map shound be named n+1, e.g., you should make an initial density blurred with a 0 width (i.e., not smoothed)
then once turned into a potential, it will be named 0.dx. The next map will be blurred at whatever sigma you wish, and called 1.dx.
The next map will be 2.dx, and so on. 
This will write the potential file into the "initialmaps" directory. Then, you will need to make a soft link
in your simulation directory (where this README is found) to each of the potential files located in the "initialmaps" directory
you just created. These links should use the same names as the potential files in the initialmaps directory.

show_replicas_mdff.vmd - script for loading replicas into VMD, first source
    the replica exchange conf file and then this script, repeat for
    restart conf file or for example just do vmd -e load_all.vmd

sortreplicas - found in namd2 binary directory, program to un-shuffle
  replica trajectories to place same-temperature frames in the same file.
  Usage: "sortreplicas <job_output_root> <num_replicas> <runs_per_frame> [final_step]"
  where <job_output_root> the job specific output base path, including
  %s or %d for separate directories as in output/%s/mdff-step1.job0
  Will be extended with .%d.dcd .%d.history for input files and
  .%d.sort.dcd .%d.sort.history for output files.  The optional final_step
  parameter will truncate all output files after the specified step,
  which is useful in dealing with restarts from runs that did not complete.
  Colvars trajectory files are similarly processed if they are found.

load-mdff-results.tcl - loads the replicas for the job specified in the
script by calling:

vmd -e load-mdff-results.tcl

If you want to load sorted trajectories, pass the argument ".sort":

vmd -e load-mdff-results.tcl -args .sort

resetmaps.sh - resets the smoothed maps for each replica back to their
original gaussian width. This script should only be called if you wish
to restart the simulation from scratch.
