#!/bin/bash

# Mastermind – a Bash implementation of the classic board game
# Copyright (C) 2026 James Gibbon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Version 1.1 - January 2026. Incoporates a "minimal mode"
# Requires Bash >= 4.3

peg() {
 local incode= k=
 local -n rslt=$1
 local prow=$2

 tput cup $prow 2

 while :; do
   read -rsn1 k

   if [[ $k == $'\0' ]]; then
      (( ${#incode} == npegs )) && break
   elif [[ $k == $'\x7f' ]]; then
      if (( ${#incode} > 0 )); then
         incode=${incode::-1}
         printf "\b\b\b🔘\b\b"
      fi
   elif [[ $k == $'\e' ]]; then
      # discard the rest of ESC [ X
      read -rsn2 _
   else
      k=${k^^}
      if [[ $k == Q ]]; then
         cleanup 0
      elif [[ "${copts[*]}" == *"$k"* ]] && (( ${#incode} < npegs )); then
         printf "${pegs[$k]} "
         incode+="$k"
      fi
   fi
 done

 rslt=$incode
}

makesecret() {
 local -n lcode=$1

 for ((i=0; i<npegs; i++)); do
    lcode+=${copts[RANDOM % ncols]}
 done
}

respond() {
 local guess=$1 lsecret=$2
 local chop
 local -i pos i
 local resp=

 for ((i=0; i<${#guess}; i++)); do
    if [[ ${guess:i:1} == ${lsecret:i:1} ]]; then
       resp+="○"
       guess="${guess:0:i}${guess:i+1}"
       lsecret="${lsecret:0:i}${lsecret:i+1}"       
       ((i--))
    fi
 done

 for ((i=0; i<${#guess}; i++)); do
    if [[ ${lsecret} == *${guess:i:1}* ]]; then
       resp+="●"

       chop="${lsecret%%${guess:i:1}*}"
       pos=${#chop}

       guess="${guess:0:i}${guess:i+1}"
       lsecret="${lsecret:0:pos}${lsecret:pos+1}"
       ((i--))
    fi
 done
 (( ${#guess} == npegs )) && resp="✘"

 printf $resp
}

cleanup () {
 # display the result
 local -i i
 local ch
 tput cup 2 2
 for ((i=0; i<npegs; i++)); do
    ch=${secret:i:1}
    printf "${pegs[$ch]} "
 done

 # restore terminal normality
 printf $'\e[?25h'
 tput cup $(($LINES - 1)) 0
 exit $1
}

#### MAIN #####

trap 'cleanup 130' INT

declare -i ngoes npegs ncols gtype=1

while getopts ":dm" opt; do
   [[ $opt = d ]] && gtype=2
   [[ $opt = m ]] && gtype=0
done

(( ngoes=8+2*gtype, npegs=3+gtype, ncols=4+2*gtype ))

declare allcolours=(R G Y B N W O P)
declare copts=( "${allcolours[@]:0:ncols}" )

curoff=$'\e[?25l'   # hide cursor

declare secret
declare -A pegs=( [R]=🔴 [G]=🟢 [Y]=🟡 [B]=🔵 [N]=⚫ [W]=⚪ [O]=🟠 [P]=🟣 )

makesecret secret
tput clear

printf "$curoff\n\n\n\n"

for ((i=0; i<ngoes; i++)); do
   printf "  "
   for ((n=0; n<npegs; n++)); do
      printf "🔘 "
   done
   printf "\n"
done

declare -i pgo=0
declare pcode=

while (( pgo < ngoes )) && [[ $pcode != $secret ]] ; do
   (( pgo ++ ))
   peg pcode $(( ngoes + 4 - pgo ))
   respond $pcode $secret   
done

cleanup 0
