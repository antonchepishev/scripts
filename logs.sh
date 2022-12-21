#!/bin/bash

#BUG SHOWS LOG FILE PATH IN THE DOMAIN LIST

RED_COLOR=$'\033[31;1m'
GREEN_COLOR=$'\033[32;1m'
YELLOW_COLOR=$'\033[33;1m'
PURPLE_COLOR=$'\033[35;1m'
CYAN_COLOR=$'\033[36;1m'
DEFAULT_COLOR=$'\033[0m'

export LC_ALL=C

while (true); do

 read -e -r -p $'\e[36mTimeframe(10 seconds, 5 minutes, 3 hours 1 day, ect. or none to review all entries in the logs):\e[0m ' timeframe;

 if [ "$timeframe" != 'none' ]; then

 time_num=$( echo $timeframe | tr -dc '0-9' )
 time_unit=$( echo $timeframe | tr -dc 'a-zA-Z' )

  case $time_unit in
   
#   second | seconds)
 #   timevar="$time_num"
  #  break 2
   # ;;

   minute | minutes)
    timevar=$time_num
    break 2
    ;;

   hour | hours )
    timevar=$(( time_num * 60 ))
    break 2
    ;;

   day | days)
    timevar=$(( time_num * 1440 ))
    break 2
    ;;

  *)
    echo "incorrect timeframe. Try Again"
    ;;

  esac

 else

  break

 fi

done

declare -a arr=()

for log in $(find /home/*/access-logs/* | sed -e "s/-ssl_log//" | uniq); do 

 if [ "$timeframe" = 'none' ]; then
 
  log_entries=$(cat "$log"* | wc -l)
  
 else
   
  if [ -s "$log" ]; then
   first_log_entry=$(head -n1 "$log" | cut -d [ -f 2 | cut -d ':' -f -3)
   initial_time=$(date -d -"$timevar"minutes +'%d/%b/%Y:%H:%M')
  
   if [[ "$first_log_entry" > "$initial_time" ]]; then

    log_entries_non_ssl=$(cat "$log" | wc -l)
    line_num_non_ssl=1

   else

    minutes=$timevar
    while [ "$minutes" -gt 0 ]; do  

     line_num_non_ssl=$(grep -nm 1 "$(date -d -"$minutes"minutes +'%d/%b/%Y:%H:%M')" "$log" | cut -d ':' -f1)

     if [ -n "$line_num_non_ssl" ]; then
    
      break

     fi

     ((minutes--)); 

     if [ "$minutes" -eq 0 ]; then

      (( line_num_non_ssl= $(cat "$log" | wc -l) + 1 ));
      log_entries_non_ssl=0
      break

     fi

    done
     
   if [ $minutes -gt 0 ]; then
   
    log_entries_non_ssl=$(tail -n +"$line_num_non_ssl" "$log" | grep . | grep -v '==>' | wc -l)
   
   else

    log_entries_non_ssl=0

   fi
 fi
  else 

   line_num_non_ssl=0
   log_entries_non_ssl=0

  fi

  if [ -s "$log"-ssl_log ]; then

   first_log_entry=$(head -n1 "$log"-ssl_log | cut -d [ -f 2 | cut -d ':' -f -3)
   initial_time=$(date -d -"$timevar"minutes +'%d/%b/%Y:%H:%M')

   if [[ "$first_log_entry" > "$initial_time" ]]; then
    
    log_entries_non_ssl=$(cat "$log"-ssl_log | wc -l)
    line_num_non_ssl=1
   
   else
    
    minutes=$timevar
    while [ "$minutes" -gt 0 ]; do 

     line_num_ssl=$(grep -nm 1 "$(date -d -"$minutes"minutes +'%d/%b/%Y:%H:%M')" "$log"-ssl_log | cut -d ':' -f1)

     if [ ! -z "$line_num_ssl" ]; then

      break

     fi

     ((minutes--));

     if [ "$minutes" -eq 0 ]; then
    
      (( line_num_ssl= $(cat "$log"-ssl_log | wc -l) + 1 ));
      log_entries_ssl=0
      break

     fi
    done

   if [ $minutes -gt 0 ]; then

    log_entries_ssl=$(tail -n +"$line_num_ssl" "$log"-ssl_log | grep . | grep -v '==>' | wc -l)

   else

    log_entries_ssl=0

   fi
  fi
  else

   line_num_ssl=0
   log_entries_ssl=0

  fi

  log_entries=$((log_entries_non_ssl + log_entries_ssl))

 fi

 if [ "$log_entries" -gt 0 ]; then 
  
  domain=$(echo "$log" | rev | cut -d '/' -f 1 | rev )
  user=$(echo "$log" | cut -d '/' -f 3 )
  
  if [ "$(whoami)" = 'root' ]; then

   if [ "$(uapi --user="$user" DomainInfo list_domains | grep 'main_domain' | awk '{print$2}')" != "$domain" ]; then

    if [ ! -z $(uapi --user="$user" DomainInfo single_domain_data domain="$domain" | grep serveralias | awk '{print $2"\n"$3"\n",$4"\n",$5}' | grep -v "www\|mail") ]; then

     domain=$(uapi --user="$user" DomainInfo single_domain_data domain="$domain" | grep serveralias | awk '{print $2"\n"$3"\n",$4"\n",$5}' | grep -v "$domain\|www\|mail")

    fi
   fi

  else

   if [ "$(uapi DomainInfo list_domains | grep 'main_domain' | awk '{print$2}')" != "$domain" ]; then

    if [ ! -z $(uapi DomainInfo single_domain_data domain="$domain" | grep serveralias | awk '{print $2"\n"$3"\n",$4"\n",$5}' | grep -v "www\|mail") ]; then
  
     domain=$(uapi DomainInfo single_domain_data domain="$domain" | grep serveralias | awk '{print $2"\n"$3"\n",$4"\n",$5}' | grep -v "$domain\|www\|mail")
    
    fi
   fi
  fi

  if [ "$timeframe" = 'none' ]; then 
 
   arr+=( "$(echo "$log_entries $domain $log")" )

  else

  arr+=( "$(echo "$log_entries $domain $log $line_num_non_ssl $line_num_ssl")" )
  
  fi  
 fi
done

printf '%s\n'  "${arr[@]}" | awk '{print$1,$2}' | sort -rh

read -e -r -p $'\e[36mWold you like to review the top IPs in the logs?(y/n)\e[0m ' ip_entries;

if [ "$ip_entries" = y ]; then

printf '%s\n' "${arr[@]}" | sort -rh | while read line; do

  domain=$(echo "$line" | awk '{print$2}')
  log=$(echo "$line" | awk '{print$3}')
  line_num_non_ssl=$(echo "$line" | awk '{print$4}')
  line_num_ssl=$(echo "$line" | awk '{print$5}')
 
  printf "%sDomain: $domain%s\\n" "$RED_COLOR" "$DEFAULT_COLOR"
 
  if [ "$timeframe" = 'none' ]; then

   cat "$log"* | cut -d ' ' -f 1 | sort | uniq -c | sed 's/^ *//g' | sort -rh | head -n 10

  else
   
   if [ -f "$log" ] && [ -f "$log"-ssl_log ]; then

    ( tail -n +"$line_num_non_ssl" "$log" | grep . | grep -v '==>'; tail -n +"$line_num_ssl" "$log"-ssl_log | grep . | grep -v '==>' ) | cut -d ' ' -f 1 | sort | uniq -c | sed 's/^ *//g' | sort -rh | head -n 10 
  
   elif [ -f "$log" ] && [ ! -f "$log"-ssl_log ]; then 

    tail -n +"$line_num_non_ssl" "$log" | grep . | grep -v '==>' | cut -d ' ' -f 1 | sort | uniq -c | sed 's/^ *//g' | sort -rh | head -n 10

   elif [ ! -f "$log" ] && [ -f "$log"-ssl_log ]; then

    tail -n +"$line_num_ssl" "$log"-ssl_log | grep . | grep -v '==>' | cut -d ' ' -f 1 | sort | uniq -c | sed 's/^ *//g' | sort -rh | head -n 10

   fi
  fi
 done
fi
