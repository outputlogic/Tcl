set filter="13:15"

foreach j ( `bjobs | grep $filter | grep -vP '(interactiv|JOBID)' | sed -r 's,^([0-9]+) .*,\1,g'` )
  bkill $j
end

