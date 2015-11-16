
# http://wiki.tcl.tk/728

# set x [o::obfuscate "hello world"]
# eval $x

namespace eval o1 {
   proc -) {k s} {
       foreach c [split $s ""] {
           scan $c %c c
           incr c $k
           append buf [format %c $c]
       }
       return $buf
   }

   proc obfuscate {s} {
       set k [expr {int(rand()*255+1)}]
       return "package require obf;o1::-) -$k [list [-) $k $s]]"
   }

   proc obfuscate_file {filename} {
     set FH [open $filename {r}]
     set content [read $FH]
     close $FH
     set secret [o1::obfuscate $content]
     set FH [open ${filename}.o1 {w}]
     puts $FH "eval \[eval $secret \]"
#      puts $FH "set x \[format {%s} {$secret}\]"
#      puts $FH "eval \[eval \$x \]"
#      puts $FH "unset x"
     close $FH   
   }

}

namespace eval o2 {
     proc -) {k s {f {}}} {
         binary s $s c* s; foreach {{
         #}}   $s {lappend f [incr {
         #}    $k]  ;^P}
         binary f c* $f
     }

     proc ^P {} {upvar k x;set x [expr {($x>0?1:-1)*(abs($x)%255+1)}]}

     proc obfuscate {s} {
         set k [expr {int(rand()*255+1)}]
         format "package r obf;o2::-) -$k %s" [list [-) $k $s]]
     }
     
     proc obfuscate_file {filename} {
      set FH [open $filename {r}]
      set content [read $FH]
      close $FH
      set secret [o2::obfuscate $content]
      set FH [open ${filename}.o2 {w}]
      puts $FH "set x \[format {%s} {$secret}\]"
      puts $FH "eval \$x"
      close $FH
     }
 }

namespace eval o3 [string map {{ } {  } ! et {"} nc # \]\} {$} { #}
 % { c} & { $} ' ex ( fo ) \}\  * -1 + {;s} , { f} - \{u . {h } / (a
 0 oc 1 { k} 2 {($} 3 ac 4 { -} 5 P\} 6 \{\{ 7 {{}} 8 { p} 9 {) }
 : 55 {;} { s} < { x} = {* } > )* ? ar @ \ \{ A bi B {c } C {[i}
 D \{\n E ^P F pp G k\] H x) I \}\} J pr K {r } L {

 } M {d } N bs O c* P pv Q re R {$f} S {s } T la U )\} V 0? W \}\n
 X {;^} Y ro Z 1: {[} {; } \\ +1 \] x> ^ {f } _ {$s} ` #\} a {
 } b { [} c ry d en e \{k f %2 g na {
 } {}} {a  J049e;@^7I@a    Agc;&SO;[(Q3.6a    `) _@TFdM^C"KD    $
 ) &G X5a    Agc,%=Ra  W  8YBE@)-P?1<+!<b'J@2]VZ*>/N2Hf:\U#L}]
 namespace eval o [string map {{ } {  } ! %s {"} \}\] # { "} {$} { $}
 % fo & s\} ' 5+ ( ob ) oc * {]
 } + { o} , us - ag . pa / {f;} 0 {) } 1 nt 2 {" } 3 an 4 bf 5 {[e}
 6 (r 7 \ \{ 8 )* 9 ca : \ \} {;} at < {[l} = {[-} > o: ? pr @ {r }
 A 1) B {k } C {

 } D is E ck F s\] G xp H d( I {e } J rm K {$k} L se M {t } N 25
 O :- P te Q {-$} R {
 } S \{i {
 } {}} {R  ?)+4,9P7&7R    LMB5G@S163H8N'A"R    %J;#.E-I@(/>O0QB!2<DM
 =0K$F*  :C}]
 eval [string map {{ } {  } ! { p} {"} ro # { 1} {$} ka % ge & {

 } ' bf ( {
 } ) ac * .0 + { o} {
 } {}} {( !)$%!"+'#*&}]
  
package pro obf 1.0
 
# source /home/dpefour/git/scripts/wip/obfuscate.tcl
# o::obfuscate_file foo.tcl
# source foo.tcl.o
# o::obfuscate_file foo2.tcl
# source foo2.tcl.o
