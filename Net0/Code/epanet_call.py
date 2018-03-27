import subprocess
from subprocess import call

def epanet_call():
	call(["./epanetOutput","i","j","k"])