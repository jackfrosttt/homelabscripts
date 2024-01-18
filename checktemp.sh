#!/bin/bash 
/usr/bin/vcgencmd measure_temp | awk -F "[=']" ' {print ($2 * 1.8)+32}'
