# Commands

## Environment
Server: Nobel
Shell: csh/tcsh
Simulator: XSim (Vivado 2019.2)

## Repo location
/home/vsudhanvi/rtl-cdc-reset-datamover

## Smoke run
python3 -m scripts.run --tool xsim --suite smoke --test async_fifo --waves

## Latest report folder in csh
set latest=`ls -td reports/run_* | head -1`
echo $latest

## List generated artifacts
find $latest -maxdepth 2 -type f | sort

## Find waveform
find $latest -name "*.wdb"

## Open waveform
xsim $latest/work.sim.wdb &

## Check simulator processes
ps -u $USER | grep xsim | grep -v grep

## Git status
git status
git log --oneline -n 3

## GUI Forwarding

xsim --gui reports/<run_log>/work.sim.wdb