#!/bin/bash
for IP in {170..255}
do
	ping -c 1  $1.$IP | grep "64 bytes" | tr -d ":" | cut -d " " -f 4 
done
