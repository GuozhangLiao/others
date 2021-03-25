#!/bin/bash
for IP in {1..254}
do
	ping -c 1  $1.$IP | grep "64 bytes" | tr -d ":" | cut -d " " -f 4 
done
